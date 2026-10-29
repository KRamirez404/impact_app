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


@pytest.fixture()
def pago(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    payload = _event(donation["referencia"])
    return client, token, donation, payload


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
