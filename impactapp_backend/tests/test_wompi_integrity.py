import hashlib
import json
import threading
import urllib.error
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from decimal import Decimal
from io import BytesIO

import pytest
from flask import Flask
from sqlalchemy import event, text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from app import app, ensure_donation_schema
from models import AUDITORIA, CAMPAÑA, DONACION, db
from routes import wompi_routes
from services import wompi_service
from test_wompi_extra import (
    EVENTS_SECRET, TRANSACTIONS, _checkout, _event, _token, wompi_config,
)

CONSULTAR_TRANSACCION = wompi_service.fetch_transaction
CONSULTAR_POR_REFERENCIA = wompi_service.fetch_transaction_by_reference


@pytest.fixture()
def pago(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    payload = _event(donation["referencia"])
    return client, token, donation, payload


def _estado(donation):
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        return row.estado_pago, row.wompi_transaction_id, AUDITORIA.query.filter_by(accion="DONACION_PAGO").count()


@pytest.mark.parametrize("valor", [None, True, [], {}, "NaN", "sNaN", "Infinity", "-Infinity", "-1", "0", "999.99", "1000.001", "10000000000", "1e1000"])
def test_checkout_rechaza_montos_invalidos(client, wompi_config, valor):
    _, token = _token(client)
    response = _checkout(client, token, amount=valor)
    assert response.status_code == 400
    with app.app_context():
        assert DONACION.query.count() == 0
        assert AUDITORIA.query.filter_by(accion="DONACION_CHECKOUT").count() == 0


@pytest.mark.parametrize("valor,centavos", [("1000", 100000), ("1000.01", 100001), ("9999999999.99", 999999999999), (Decimal("1.01"), 101), ("1e-2", 1)])
def test_conversion_decimal_exacta(valor, centavos):
    assert wompi_service.amount_to_cents(valor) == centavos


def test_checkout_preserva_limite_decimal_y_json_numerico(client, wompi_config):
    _, token = _token(client)
    for amount in ("9999999999.99", "1000.01"):
        response = client.post(
            "/api/donations/checkout",
            data=f'{{"id_campania":1,"monto_estimado":{amount}}}',
            content_type="application/json", headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 201
        assert f"amount-in-cents={wompi_service.amount_to_cents(amount)}" in response.get_json()["checkout_url"]
        with app.app_context():
            assert db.session.get(DONACION, response.get_json()["id_donacion"]).monto_estimado == Decimal(amount)


@pytest.mark.parametrize("cuerpo", [[], None, True, {"id_campania": True}, {"id_campania": "1"}, {"id_campania": 1.1}, {"id_campania": 2147483648}, {"id_campania": 1, "monto_estimado": 1000, "currency": "USD"}, {"id_campania": 1, "monto_estimado": 1000, "descripcion": []}])
def test_checkout_valida_json_y_campos(client, wompi_config, cuerpo):
    _, token = _token(client)
    response = client.post("/api/donations/checkout", data=json.dumps(cuerpo), content_type="application/json", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 400


def test_checkout_eliminado_no_recibe_pagos(client, wompi_config):
    _, token = _token(client)
    with app.app_context():
        db.session.get(CAMPAÑA, 1).eliminada = True
        db.session.commit()
    assert _checkout(client, token).status_code == 400


def test_checkout_idempotente_y_conflicto(client, wompi_config):
    _, token = _token(client)
    headers = {"Authorization": f"Bearer {token}", "Idempotency-Key": "intento-1"}
    body = {"id_campania": 1, "monto_estimado": "50000"}
    first = client.post("/api/donations/checkout", json=body, headers=headers)
    second = client.post("/api/donations/checkout", json=body, headers=headers)
    assert (first.status_code, second.status_code) == (201, 200)
    assert first.get_json() == second.get_json()
    body["monto_estimado"] = "60000"
    assert client.post("/api/donations/checkout", json=body, headers=headers).status_code == 409
    with app.app_context():
        assert DONACION.query.count() == 1
        assert AUDITORIA.query.filter_by(accion="DONACION_CHECKOUT").count() == 1


def test_firma_respeta_orden_y_header(pago):
    client, _, _, payload = pago
    properties = ["transaction.amount_in_cents", "transaction.reference", "transaction.id", "transaction.status"]
    payload["signature"]["properties"] = properties
    expected = hashlib.sha256(("5000000" + payload["data"]["transaction"]["reference"] + "1234-1610641025-49201APPROVED1530291411" + EVENTS_SECRET).encode()).hexdigest()
    payload["signature"].pop("checksum")
    response = client.post("/api/webhooks/wompi", json=payload, headers={"X-Event-Checksum": expected.upper()})
    assert response.status_code == 200


@pytest.mark.parametrize("cambio", ["orden", "vacias", "inexistente", "timestamp", "firma_lista", "data_lista"])
def test_firma_rechaza_estructura_invalida(pago, cambio):
    client, _, donation, payload = pago
    if cambio == "orden":
        payload["signature"]["properties"].reverse()
    elif cambio == "vacias":
        payload["signature"]["properties"] = []
    elif cambio == "inexistente":
        payload["signature"]["properties"] = ["transaction.no_existe"]
    elif cambio == "timestamp":
        payload["timestamp"] = "1530291411"
    elif cambio == "firma_lista":
        payload["signature"] = []
    else:
        payload["data"] = []
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 401
    assert _estado(donation) == ("pendiente", None, 0)


@pytest.mark.parametrize("ambiente", [None, "prod", "sandbox", 1])
def test_ambiente_obligatorio(pago, ambiente):
    client, _, donation, payload = pago
    payload["environment"] = ambiente
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 401
    assert _estado(donation)[0] == "pendiente"


@pytest.mark.parametrize("campo,valor", [("reference", "OTRA"), ("id", "OTRO-ID"), ("amount_in_cents", 4999999), ("currency", "USD"), ("status", "DESCONOCIDO")])
def test_conciliacion_rechaza_respuesta_proveedor_distinta(pago, campo, valor):
    client, _, donation, payload = pago
    transaction_id = payload["data"]["transaction"]["id"]
    TRANSACTIONS[transaction_id][campo] = valor
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 409
    assert _estado(donation) == ("pendiente", None, 0)


def test_referencia_no_firmada_no_puede_reasignar_pago(pago):
    client, token, first, payload = pago
    second = _checkout(client, token).get_json()
    payload["data"]["transaction"]["reference"] = second["referencia"]
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 409
    assert _estado(first)[0] == _estado(second)[0] == "pendiente"


def test_monto_distinto_local_y_moneda_distinta_en_evento(pago):
    client, _, donation, payload = pago
    transaction = payload["data"]["transaction"]
    transaction["amount_in_cents"] = 1
    payload["signature"]["checksum"] = wompi_service.compute_event_checksum(payload["signature"]["properties"], payload["data"], payload["timestamp"], EVENTS_SECRET)
    TRANSACTIONS[transaction["id"]] = deepcopy(transaction)
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 409
    transaction["currency"] = "USD"
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 409
    assert _estado(donation) == ("pendiente", None, 0)


def test_transaccion_no_puede_asociarse_dos_veces(pago):
    client, token, first, payload = pago
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    second = _checkout(client, token).get_json()
    payload = _event(second["referencia"])
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 409
    assert _estado(first)[0] == "aprobada"
    assert _estado(second)[0] == "pendiente"


def test_donacion_no_admite_otro_identificador(pago):
    client, _, donation, payload = pago
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    payload = _event(donation["referencia"], tx_id="OTRA-TRANSACCION")
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 409


@pytest.mark.parametrize("campo,valor", [("monto_estimado", -1), ("descripcion", "alterada"), ("checksum", None)])
def test_donacion_alterada_no_se_confirma(pago, campo, valor):
    client, _, donation, payload = pago
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        setattr(row, campo, valor)
        db.session.commit()
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 409
    assert _estado(donation) == ("pendiente", None, 0)


@pytest.mark.parametrize("valor", [None, [], {}, True, "PAGADA"])
def test_estado_de_evento_invalido_no_produce_error_interno(pago, valor):
    client, _, donation, payload = pago
    payload["data"]["transaction"]["status"] = valor
    if isinstance(valor, str):
        payload["signature"]["checksum"] = wompi_service.compute_event_checksum(payload["signature"]["properties"], payload["data"], payload["timestamp"], EVENTS_SECRET)
    response = client.post("/api/webhooks/wompi", json=payload)
    assert response.status_code in (401, 409)
    assert _estado(donation) == ("pendiente", None, 0)


def test_evento_antiguo_usa_estado_actual_y_no_revierte_aprobacion(pago):
    client, _, donation, approved = pago
    assert client.post("/api/webhooks/wompi", json=approved).status_code == 200
    old = _event(donation["referencia"], status="PENDING", timestamp=1)
    TRANSACTIONS[old["data"]["transaction"]["id"]] = deepcopy(approved["data"]["transaction"])
    assert client.post("/api/webhooks/wompi", json=old).status_code == 200
    assert _estado(donation)[::2] == ("aprobada", 1)
    TRANSACTIONS[old["data"]["transaction"]["id"]] = deepcopy(old["data"]["transaction"])
    assert client.post("/api/webhooks/wompi", json=old).status_code == 200
    assert _estado(donation)[::2] == ("aprobada", 1)


def test_anulacion_tarjeta_recalcula_y_conserva_historial(pago):
    client, _, donation, payload = pago
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    with app.app_context():
        date = db.session.get(DONACION, donation["id_donacion"]).fecha_pago
    voided = _event(donation["referencia"], status="VOIDED")
    assert client.post("/api/webhooks/wompi", json=voided).status_code == 200
    assert client.post("/api/webhooks/wompi", json=voided).status_code == 200
    assert _estado(donation)[::2] == ("anulada", 2)
    with app.app_context():
        assert db.session.get(CAMPAÑA, 1).porcentaje_avance == 0
        assert db.session.get(DONACION, donation["id_donacion"]).fecha_pago == date
    approved = _event(donation["referencia"])
    assert client.post("/api/webhooks/wompi", json=approved).status_code == 200
    assert _estado(donation)[0] == "anulada"


def test_anulacion_no_tarjeta_no_se_aplica(pago):
    client, _, donation, _ = pago
    payload = _event(donation["referencia"], status="VOIDED")
    payload["data"]["transaction"]["payment_method_type"] = "PSE"
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 409
    assert _estado(donation) == ("pendiente", None, 0)


@pytest.mark.parametrize("final", ["DECLINED", "ERROR"])
def test_estados_terminales_no_se_reabren(pago, final):
    client, _, donation, _ = pago
    payload = _event(donation["referencia"], status=final)
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    payload = _event(donation["referencia"])
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    assert _estado(donation)[0] == wompi_service.STATUS_MAP[final]


@pytest.mark.parametrize("etapa", ["donacion", "campania", "auditoria", "commit"])
def test_fallo_atomico_y_recuperacion(pago, monkeypatch, etapa):
    client, _, donation, payload = pago
    def fallar(*args, **kwargs):
        raise SQLAlchemyError("fallo de prueba")
    with monkeypatch.context() as scoped:
        if etapa == "campania":
            scoped.setattr(wompi_routes, "recalculate_campaign_progress", fallar)
        elif etapa == "auditoria":
            scoped.setattr(wompi_routes, "registrar", fallar)
        else:
            hook = "before_flush" if etapa == "donacion" else "before_commit"
            session_class = db.session.session_factory.class_
            event.listen(session_class, hook, fallar)
        try:
            assert client.post("/api/webhooks/wompi", json=payload).status_code == 503
        finally:
            if etapa in ("donacion", "commit"):
                event.remove(session_class, hook, fallar)
    assert _estado(donation) == ("pendiente", None, 0)
    with app.app_context():
        assert db.session.get(CAMPAÑA, 1).porcentaje_avance == 15
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    assert _estado(donation)[::2] == ("aprobada", 1)


def test_repara_aprobacion_historica_sin_avance_ni_auditoria(pago):
    client, _, donation, payload = pago
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        row.estado_pago = "aprobada"
        row.wompi_transaction_id = payload["data"]["transaction"]["id"]
        db.session.commit()
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    assert _estado(donation)[::2] == ("aprobada", 1)
    with app.app_context():
        assert db.session.get(CAMPAÑA, 1).porcentaje_avance == 1


def test_recupera_sin_primer_webhook_solo_tras_consulta_backend(pago):
    client, token, donation, payload = pago
    url = f'/api/donations/{donation["id_donacion"]}/status'
    headers = {"Authorization": f"Bearer {token}"}
    assert client.get(url, headers=headers).get_json()["conciliacion"] == "sin_identificador"
    transaction_id = payload["data"]["transaction"]["id"]
    response = client.get(url, query_string={"transaction_id": transaction_id}, headers=headers)
    assert response.status_code == 200
    assert response.get_json()["estado_pago"] == "aprobada"
    assert response.get_json()["conciliacion"] == "verificada"


def test_recuperacion_no_acepta_referencia_de_otro_pago(pago):
    client, token, donation, payload = pago
    TRANSACTIONS[payload["data"]["transaction"]["id"]]["reference"] = "OTRO-PAGO"
    response = client.get(f'/api/donations/{donation["id_donacion"]}/status', query_string={"transaction_id": payload["data"]["transaction"]["id"]}, headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 409
    assert _estado(donation) == ("pendiente", None, 0)


@pytest.mark.parametrize("error", [TimeoutError(), urllib.error.URLError("sin red"), urllib.error.HTTPError("https://prueba", 401, "no autorizado", {}, None)])
def test_consulta_api_falla_sin_confirmar_y_permite_reintento(pago, monkeypatch, error):
    client, token, donation, payload = pago
    def fallar(*args, **kwargs):
        raise error
    with monkeypatch.context() as scoped:
        scoped.setattr(wompi_service, "fetch_transaction", CONSULTAR_TRANSACCION)
        scoped.setattr(wompi_service.urllib.request, "urlopen", fallar)
        assert client.post("/api/webhooks/wompi", json=payload).status_code == 503
        response = client.get(f'/api/donations/{donation["id_donacion"]}/status', query_string={"transaction_id": payload["data"]["transaction"]["id"]}, headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 503
    assert _estado(donation) == ("pendiente", None, 0)
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200


def test_consulta_api_usa_llave_privada_y_valida_respuesta(pago, monkeypatch):
    _, _, _, payload = pago
    transaction = payload["data"]["transaction"]
    def responder(request, timeout):
        assert request.full_url.endswith("/transactions/" + transaction["id"])
        assert request.get_header("Authorization") == "Bearer " + app.config["WOMPI_PRIVATE_KEY"]
        assert timeout == 15
        return BytesIO(json.dumps({"data": transaction}).encode())
    monkeypatch.setattr(wompi_service.urllib.request, "urlopen", responder)
    with app.app_context():
        assert CONSULTAR_TRANSACCION(transaction["id"]) == transaction
    monkeypatch.setattr(wompi_service.urllib.request, "urlopen", lambda *a, **k: BytesIO(b'{"data":[]}'))
    with app.app_context(), pytest.raises(wompi_service.WompiQueryError):
        CONSULTAR_TRANSACCION(transaction["id"])


def test_migracion_rechaza_duplicados_sin_borrar_y_es_idempotente():
    isolated = Flask("migracion_wompi")
    isolated.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
    db.init_app(isolated)
    with isolated.app_context():
        db.session.execute(text('CREATE TABLE "DONACION" (id_donacion INTEGER PRIMARY KEY, wompi_transaction_id VARCHAR(120))'))
        db.session.execute(text('INSERT INTO "DONACION" VALUES (1, :tx), (2, :tx)'), {"tx": "DUPLICADA"})
        db.session.commit()
        with pytest.raises(RuntimeError, match="duplicados"):
            ensure_donation_schema()
        assert db.session.execute(text('SELECT COUNT(*) FROM "DONACION"')).scalar() == 2
        db.session.execute(text('UPDATE "DONACION" SET wompi_transaction_id = NULL WHERE id_donacion = 2'))
        db.session.commit()
        ensure_donation_schema()
        ensure_donation_schema()
        with pytest.raises(IntegrityError):
            db.session.execute(text('UPDATE "DONACION" SET wompi_transaction_id = :tx WHERE id_donacion = 2'), {"tx": "DUPLICADA"})
            db.session.commit()
        db.session.rollback()


def test_checkout_concurrente_postgresql_reutiliza_donacion(client, wompi_config):
    with app.app_context():
        if db.engine.dialect.name != "postgresql":
            pytest.skip("Requiere bloqueos de fila PostgreSQL")
    _, token = _token(client)
    barrier = threading.Barrier(2)
    def crear(_):
        barrier.wait(timeout=10)
        with app.test_client() as parallel_client:
            response = parallel_client.post(
                "/api/donations/checkout", json={"id_campania": 1, "monto_estimado": 50000},
                headers={"Authorization": f"Bearer {token}", "Idempotency-Key": "concurrente"},
            )
            return response.status_code, response.get_json()["id_donacion"]
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(crear, range(2)))
    assert sorted(code for code, _ in results) == [200, 201]
    assert len({donation_id for _, donation_id in results}) == 1
    with app.app_context():
        assert DONACION.query.count() == 1
        assert AUDITORIA.query.filter_by(accion="DONACION_CHECKOUT").count() == 1


@pytest.mark.parametrize("duplicado", [True, False])
def test_concurrencia_postgresql_serializa_campania_y_auditoria(pago, duplicado):
    _, token, donation, first = pago
    with app.app_context():
        if db.engine.dialect.name != "postgresql":
            pytest.skip("Requiere bloqueos de fila PostgreSQL; SQLite no los acredita")
    if duplicado:
        second = deepcopy(first)
    else:
        with app.test_client() as client:
            other = _checkout(client, token, amount=100000).get_json()
        second = _event(other["referencia"], tx_id="TRANSACCION-2", amount_in_cents=10000000)
    barrier = threading.Barrier(2)
    def enviar(payload):
        barrier.wait(timeout=10)
        with app.test_client() as client:
            return client.post("/api/webhooks/wompi", json=payload).status_code
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(enviar, [first, second]))
    assert results == [200, 200]
    assert _estado(donation)[2] == (1 if duplicado else 2)
    with app.app_context():
        assert db.session.get(CAMPAÑA, 1).porcentaje_avance == (1 if duplicado else 3)


def test_consulta_por_referencia_filtra_y_elige_aprobada(pago, monkeypatch):
    _, _, donation, payload = pago
    referencia = donation["referencia"]
    aprobada = {**payload["data"]["transaction"], "created_at": "2026-01-02T00:00:00"}
    rechazada = {
        **payload["data"]["transaction"],
        "id": "otra-1-1",
        "status": "DECLINED",
        "created_at": "2026-01-01T00:00:00",
    }
    ajena = {**payload["data"]["transaction"], "id": "ajena-1-1", "reference": "OTRA"}

    def responder(request, timeout):
        assert request.full_url.endswith("/transactions?reference=" + referencia)
        assert request.get_header("Authorization") == "Bearer " + app.config["WOMPI_PRIVATE_KEY"]
        assert timeout == 15
        return BytesIO(json.dumps({"data": [rechazada, aprobada, ajena]}).encode())

    monkeypatch.setattr(wompi_service, "fetch_transaction_by_reference", CONSULTAR_POR_REFERENCIA)
    monkeypatch.setattr(wompi_service.urllib.request, "urlopen", responder)
    with app.app_context():
        assert wompi_service.fetch_transaction_by_reference(referencia) == aprobada

    monkeypatch.setattr(
        wompi_service.urllib.request,
        "urlopen",
        lambda *a, **k: BytesIO(json.dumps({"data": []}).encode()),
    )
    with app.app_context():
        assert wompi_service.fetch_transaction_by_reference(referencia) is None

    monkeypatch.setattr(
        wompi_service.urllib.request,
        "urlopen",
        lambda *a, **k: BytesIO(b'{"data": {}}'),
    )
    with app.app_context(), pytest.raises(wompi_service.WompiQueryError):
        wompi_service.fetch_transaction_by_reference(referencia)
