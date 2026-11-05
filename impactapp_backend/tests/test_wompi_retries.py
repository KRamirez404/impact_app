import threading
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy

import pytest
from flask import Flask
from sqlalchemy import inspect
from sqlalchemy.exc import SQLAlchemyError

from app import app, ensure_payment_attempt_schema
from models import AUDITORIA, CAMPAÑA, DONACION, PAGO_EVENTO, PAGO_INTENTO, db
from routes import wompi_routes
from test_wompi_extra import (
    TRANSACTIONS,
    _checkout,
    _event,
    _token,
    wompi_config,
)
from models import NOTIFICACION_EMAIL


@pytest.fixture()
def pago(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    payload = _event(donation["referencia"])
    return client, token, donation, payload


def _avisos(id_donacion, estado):
    with app.app_context():
        return sorted(
            fila.clave_evento for fila in NOTIFICACION_EMAIL.query.filter_by(
                tipo=f"donacion_{estado}"
            ).all() if fila.clave_evento.startswith(f"donacion:{id_donacion}:")
        )


def test_dos_intentos_rechazados_generan_dos_avisos(pago):
    client, _, donation, _ = pago
    for tx in ("rechazo-1", "rechazo-2"):
        assert client.post("/api/webhooks/wompi", json=_event(
            donation["referencia"], tx_id=tx, status="DECLINED"
        )).status_code == 200
    assert _avisos(donation["id_donacion"], "rechazada") == [
        f"donacion:{donation['id_donacion']}:rechazada:rechazo-1",
        f"donacion:{donation['id_donacion']}:rechazada:rechazo-2",
    ]


def test_repetir_webhook_no_repite_aviso(pago):
    client, _, donation, _ = pago
    payload = _event(donation["referencia"], tx_id="repetido-1", status="DECLINED")
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    assert _avisos(donation["id_donacion"], "rechazada") == [
        f"donacion:{donation['id_donacion']}:rechazada:repetido-1"
    ]


def test_webhook_y_consulta_mismo_intento_comparten_aviso(pago):
    client, token, donation, _ = pago
    assert client.post("/api/webhooks/wompi", json=_event(
        donation["referencia"], tx_id="consulta-1", status="DECLINED"
    )).status_code == 200
    respuesta = client.get(
        f"/api/donations/{donation['id_donacion']}/status?transaction_id=consulta-1",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert respuesta.status_code == 200
    assert _avisos(donation["id_donacion"], "rechazada") == [
        f"donacion:{donation['id_donacion']}:rechazada:consulta-1"
    ]


def test_rechazo_seguido_de_aprobacion_conserva_ambos_avisos(pago):
    client, _, donation, _ = pago
    for tx, estado in (("previo-1", "DECLINED"), ("aprobado-1", "APPROVED")):
        assert client.post("/api/webhooks/wompi", json=_event(
            donation["referencia"], tx_id=tx, status=estado
        )).status_code == 200
    assert _avisos(donation["id_donacion"], "rechazada") == [
        f"donacion:{donation['id_donacion']}:rechazada:previo-1"
    ]
    assert _avisos(donation["id_donacion"], "aprobada") == [
        f"donacion:{donation['id_donacion']}:aprobada:aprobado-1"
    ]
    with app.app_context():
        assert db.session.get(DONACION, donation["id_donacion"]).estado_pago == "aprobada"


def test_rechazo_antiguo_tras_aprobar_no_avisa(pago):
    client, _, donation, _ = pago
    for tx, estado in (("aprobado-2", "APPROVED"), ("antiguo-2", "DECLINED")):
        assert client.post("/api/webhooks/wompi", json=_event(
            donation["referencia"], tx_id=tx, status=estado
        )).status_code == 200
    assert _avisos(donation["id_donacion"], "rechazada") == []
    assert _avisos(donation["id_donacion"], "aprobada") == [
        f"donacion:{donation['id_donacion']}:aprobada:aprobado-2"
    ]


def test_dos_intentos_en_error_generan_dos_avisos(pago):
    client, _, donation, _ = pago
    for tx in ("error-1", "error-2"):
        assert client.post("/api/webhooks/wompi", json=_event(
            donation["referencia"], tx_id=tx, status="ERROR"
        )).status_code == 200
    assert _avisos(donation["id_donacion"], "error") == [
        f"donacion:{donation['id_donacion']}:error:error-1",
        f"donacion:{donation['id_donacion']}:error:error-2",
    ]


def test_anulacion_desde_pendiente_y_tras_aprobacion(pago):
    client, token, donation, _ = pago
    assert client.post("/api/webhooks/wompi", json=_event(
        donation["referencia"], tx_id="anulada-pendiente", status="VOIDED"
    )).status_code == 200
    assert _avisos(donation["id_donacion"], "anulada") == [
        f"donacion:{donation['id_donacion']}:anulada:anulada-pendiente"
    ]
    otra = _checkout(client, token).get_json()
    for estado in ("APPROVED", "VOIDED"):
        assert client.post("/api/webhooks/wompi", json=_event(
            otra["referencia"], tx_id="anulada-aprobada", status=estado
        )).status_code == 200
    assert _avisos(otra["id_donacion"], "aprobada") == [
        f"donacion:{otra['id_donacion']}:aprobada:anulada-aprobada"
    ]
    assert _avisos(otra["id_donacion"], "anulada") == [
        f"donacion:{otra['id_donacion']}:anulada:anulada-aprobada"
    ]


def test_historico_sin_transaccion_no_se_reasigna_ni_reenvia(pago):
    client, _, donation, _ = pago
    evento = _event(donation["referencia"], tx_id="historico-1", status="DECLINED")
    assert client.post("/api/webhooks/wompi", json=evento).status_code == 200
    with app.app_context():
        fila = NOTIFICACION_EMAIL.query.filter_by(tipo="donacion_rechazada").one()
        fila.clave_evento = f"donacion:{donation['id_donacion']}:rechazada:sin_transaccion"
        db.session.commit()
        id_historico = fila.id_notificacion
    repetido = _event(donation["referencia"], tx_id="historico-1", status="DECLINED", timestamp=1530291412)
    assert client.post("/api/webhooks/wompi", json=repetido).status_code == 200
    assert _avisos(donation["id_donacion"], "rechazada") == [
        f"donacion:{donation['id_donacion']}:rechazada:sin_transaccion"
    ]
    with app.app_context():
        assert NOTIFICACION_EMAIL.query.filter_by(tipo="donacion_rechazada").one().id_notificacion == id_historico


def _progress():
    with app.app_context():
        return float(db.session.get(CAMPAÑA, 1).porcentaje_avance)


def _attempts(donation_id):
    with app.app_context():
        return (
            PAGO_INTENTO.query.filter_by(id_donacion=donation_id)
            .order_by(PAGO_INTENTO.id_intento.asc())
            .all()
        )


def test_reintento_rechazado_luego_aprobado_acredita_una_vez(pago):
    client, _, donation, payload = pago
    declined = _event(
        donation["referencia"], tx_id="RETRY-DECLINED", status="DECLINED"
    )
    assert client.post("/api/webhooks/wompi", json=declined).status_code == 200
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "rechazada"
        assert row.wompi_transaction_id is None
    assert _progress() == 15.0

    approved = _event(
        donation["referencia"], tx_id="RETRY-APPROVED", status="APPROVED"
    )
    assert client.post("/api/webhooks/wompi", json=approved).status_code == 200
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "aprobada"
        assert row.wompi_transaction_id == "RETRY-APPROVED"
    assert _progress() == 1.0

    intentos = _attempts(donation["id_donacion"])
    assert [(i.wompi_transaction_id, i.estado_local) for i in intentos] == [
        ("RETRY-DECLINED", "rechazada"),
        ("RETRY-APPROVED", "aprobada"),
    ]
    assert [i.resultado for i in intentos] == ["ignorado", "acreditado"]
    with app.app_context():
        assert AUDITORIA.query.filter_by(accion="DONACION_PAGO").count() == 2
        assert AUDITORIA.query.filter_by(accion="PAGO_DUPLICADO").count() == 0


def test_aprobado_y_evento_rechazado_antiguo_no_regresiona(pago):
    client, _, donation, payload = pago
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    old = _event(
        donation["referencia"],
        tx_id=payload["data"]["transaction"]["id"],
        status="DECLINED",
        timestamp=1,
    )
    assert client.post("/api/webhooks/wompi", json=old).status_code == 200
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "aprobada"
        assert row.wompi_transaction_id == payload["data"]["transaction"]["id"]
    assert _progress() == 1.0
    intentos = _attempts(donation["id_donacion"])
    assert len(intentos) == 1
    assert intentos[0].estado_local == "aprobada"
    assert intentos[0].resultado == "acreditado"


def test_mismo_id_repetido_no_duplica_intento_ni_total(pago):
    client, _, donation, payload = pago
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    assert client.post("/api/webhooks/wompi", json=deepcopy(payload)).status_code == 200
    assert client.post("/api/webhooks/wompi", json=deepcopy(payload)).status_code == 200
    assert _progress() == 1.0
    intentos = _attempts(donation["id_donacion"])
    assert len(intentos) == 1
    assert intentos[0].resultado == "acreditado"
    with app.app_context():
        assert PAGO_EVENTO.query.count() == 1
        assert AUDITORIA.query.filter_by(accion="DONACION_PAGO").count() == 1


def test_dos_aprobaciones_secuenciales_registran_doble_cobro(pago):
    client, _, donation, payload = pago
    first_id = payload["data"]["transaction"]["id"]
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    second = _event(donation["referencia"], tx_id="SEGUNDO-COBRO")
    assert client.post("/api/webhooks/wompi", json=second).status_code == 200
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "aprobada"
        assert row.wompi_transaction_id == first_id
        assert AUDITORIA.query.filter_by(accion="PAGO_DUPLICADO").count() == 1
        assert AUDITORIA.query.filter_by(accion="DONACION_PAGO").count() == 1
    assert _progress() == 1.0
    intentos = _attempts(donation["id_donacion"])
    assert [i.resultado for i in intentos] == ["acreditado", "duplicado"]
    with app.app_context():
        resultados = [
            e.resultado
            for e in PAGO_EVENTO.query.order_by(PAGO_EVENTO.id_evento.asc()).all()
        ]
        assert resultados == ["aplicado", "ignorado"]


def test_anulacion_del_segundo_cobro_conserva_intento_sin_reacreditar(pago):
    client, _, donation, payload = pago
    first_id = payload["data"]["transaction"]["id"]
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    second = _event(donation["referencia"], tx_id="SEGUNDO-COBRO")
    assert client.post("/api/webhooks/wompi", json=second).status_code == 200
    voided = _event(
        donation["referencia"], tx_id="SEGUNDO-COBRO", status="VOIDED"
    )
    assert client.post("/api/webhooks/wompi", json=voided).status_code == 200
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "aprobada"
        assert row.wompi_transaction_id == first_id
    assert _progress() == 1.0
    intentos = _attempts(donation["id_donacion"])
    assert [i.resultado for i in intentos] == ["acreditado", "anulado"]
    assert [i.estado_local for i in intentos] == ["aprobada", "anulada"]


def test_reintento_con_importe_distinto_no_acredita(pago):
    client, _, donation, payload = pago
    declined = _event(
        donation["referencia"], tx_id="RETRY-DECLINED", status="DECLINED"
    )
    assert client.post("/api/webhooks/wompi", json=declined).status_code == 200
    wrong_amount = _event(
        donation["referencia"],
        tx_id="RETRY-APPROVED",
        status="APPROVED",
        amount_in_cents=1,
    )
    assert client.post("/api/webhooks/wompi", json=wrong_amount).status_code == 409
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "rechazada"
        assert row.wompi_transaction_id is None
        assert PAGO_INTENTO.query.filter_by(
            wompi_transaction_id="RETRY-APPROVED"
        ).first() is None
    assert _progress() == 15.0


def test_fallo_de_commit_no_deja_intento_parcial(pago, monkeypatch):
    client, _, donation, payload = pago

    def fallar(*args, **kwargs):
        raise SQLAlchemyError("fallo de prueba")

    with monkeypatch.context() as scoped:
        scoped.setattr(wompi_routes, "registrar", fallar)
        assert client.post("/api/webhooks/wompi", json=payload).status_code == 503
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "pendiente"
        assert row.wompi_transaction_id is None
        assert PAGO_INTENTO.query.count() == 0
    assert _progress() == 15.0

    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    assert _progress() == 1.0
    intentos = _attempts(donation["id_donacion"])
    assert len(intentos) == 1
    assert intentos[0].resultado == "acreditado"


def test_status_concilia_reintento_aprobado_sin_webhook(pago, monkeypatch):
    client, token, donation, _ = pago
    declined = _event(
        donation["referencia"], tx_id="RETRY-DECLINED", status="DECLINED"
    )
    assert client.post("/api/webhooks/wompi", json=declined).status_code == 200
    assert _progress() == 15.0

    approved = {
        "id": "RETRY-APPROVED",
        "status": "APPROVED",
        "amount_in_cents": 5000000,
        "reference": donation["referencia"],
        "currency": "COP",
        "payment_method_type": "CARD",
    }
    monkeypatch.setattr(
        wompi_routes.wompi_service,
        "fetch_transaction_by_reference",
        lambda reference: deepcopy(approved),
    )
    response = client.get(
        f'/api/donations/{donation["id_donacion"]}/status',
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    body = response.get_json()
    assert body["estado_pago"] == "aprobada"
    assert body["conciliacion"] == "verificada"
    assert _progress() == 1.0
    intentos = _attempts(donation["id_donacion"])
    assert [i.estado_local for i in intentos] == ["rechazada", "aprobada"]


def test_metodo_asincrono_pendiente_y_aprobado_acredita_una_vez(pago):
    client, _, donation, _ = pago
    pending = _event(
        donation["referencia"], tx_id="BANCOLOMBIA-1", status="PENDING"
    )
    pending["data"]["transaction"]["payment_method_type"] = "BANCOLOMBIA_TRANSFER"
    TRANSACTIONS["BANCOLOMBIA-1"]["payment_method_type"] = "BANCOLOMBIA_TRANSFER"
    assert client.post("/api/webhooks/wompi", json=pending).status_code == 200
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "pendiente"
        assert row.wompi_transaction_id is None
    assert _progress() == 15.0
    assert [i.estado_local for i in _attempts(donation["id_donacion"])] == [
        "pendiente"
    ]

    approved = _event(
        donation["referencia"], tx_id="BANCOLOMBIA-1", status="APPROVED"
    )
    approved["data"]["transaction"]["payment_method_type"] = "BANCOLOMBIA_TRANSFER"
    TRANSACTIONS["BANCOLOMBIA-1"]["payment_method_type"] = "BANCOLOMBIA_TRANSFER"
    assert client.post("/api/webhooks/wompi", json=approved).status_code == 200
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "aprobada"
        assert row.wompi_transaction_id == "BANCOLOMBIA-1"
        assert row.metodo_pago == "BANCOLOMBIA_TRANSFER"
    assert _progress() == 1.0
    intentos = _attempts(donation["id_donacion"])
    assert len(intentos) == 1
    assert intentos[0].estado_local == "aprobada"
    assert intentos[0].resultado == "acreditado"


def test_anulacion_pendiente_no_bloquea_reintento_aprobado(pago):
    client, _, donation, _ = pago
    voided = _event(
        donation["referencia"], tx_id="VOID-PENDIENTE", status="VOIDED"
    )
    assert client.post("/api/webhooks/wompi", json=voided).status_code == 200
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "anulada"
        assert row.fecha_pago is None
        assert row.wompi_transaction_id is None
    assert _progress() == 15.0

    approved = _event(
        donation["referencia"], tx_id="RETRY-APROBADO", status="APPROVED"
    )
    assert client.post("/api/webhooks/wompi", json=approved).status_code == 200
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        assert row.estado_pago == "aprobada"
        assert row.wompi_transaction_id == "RETRY-APROBADO"
        assert AUDITORIA.query.filter_by(accion="PAGO_DUPLICADO").count() == 0
    assert _progress() == 1.0
    intentos = _attempts(donation["id_donacion"])
    assert [(i.estado_local, i.resultado) for i in intentos] == [
        ("anulada", "anulado"),
        ("aprobada", "acreditado"),
    ]


def test_migracion_pago_intento_es_idempotente():
    isolated = Flask("migracion_pago_intento")
    isolated.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
    db.init_app(isolated)
    with isolated.app_context():
        ensure_payment_attempt_schema()
        ensure_payment_attempt_schema()
        inspector = inspect(db.engine)
        assert "PAGO_INTENTO" in inspector.get_table_names()
        unique = {
            c["name"] for c in inspector.get_unique_constraints("PAGO_INTENTO")
        }
        indices = {i["name"] for i in inspector.get_indexes("PAGO_INTENTO")}
        assert "uq_pago_intento_wompi_transaction_id" in unique | indices


def test_pago_intento_serializado_no_expone_secretos(pago):
    client, _, donation, payload = pago
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    intento = _attempts(donation["id_donacion"])[0]
    serializado = str(intento.to_dict())
    assert intento.wompi_transaction_id in serializado
    assert app.config["WOMPI_PRIVATE_KEY"] not in serializado
    assert app.config["WOMPI_INTEGRITY_SECRET"] not in serializado
    assert app.config["WOMPI_EVENTS_SECRET"] not in serializado


def test_dos_aprobaciones_concurrentes_postgresql(pago):
    client, _, donation, first = pago
    with app.app_context():
        if db.engine.dialect.name != "postgresql":
            pytest.skip("Requiere bloqueos de fila PostgreSQL; SQLite no los acredita")
    second = _event(donation["referencia"], tx_id="CONCURRENTE-2")
    barrier = threading.Barrier(2)

    def enviar(payload):
        barrier.wait(timeout=10)
        with app.test_client() as parallel_client:
            return parallel_client.post("/api/webhooks/wompi", json=payload).status_code

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(enviar, [first, second]))
    assert results == [200, 200]
    assert _progress() == 1.0
    intentos = _attempts(donation["id_donacion"])
    assert sorted(i.resultado for i in intentos) == ["acreditado", "duplicado"]
    with app.app_context():
        assert AUDITORIA.query.filter_by(accion="PAGO_DUPLICADO").count() == 1
