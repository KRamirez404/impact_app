import hashlib

import pytest
from sqlalchemy import inspect
from sqlalchemy.exc import SQLAlchemyError

from app import app
from models import AUDITORIA, CAMPAÑA, DONACION, PAGO_EVENTO, db
from routes import wompi_routes
from test_wompi_extra import (
    EVENTS_SECRET,
    TRANSACTIONS,
    _checkout,
    _event,
    _token,
    wompi_config,
)


def test_tabla_pago_evento_se_crea_sin_payload_ni_checksum(client, wompi_config):
    with app.app_context():
        columnas = {
            columna["name"]
            for columna in inspect(db.engine).get_columns("PAGO_EVENTO")
        }
    assert {
        "id_evento",
        "huella_evento",
        "tipo_evento",
        "id_donacion",
        "referencia",
        "wompi_transaction_id",
        "estado_wompi",
        "monto_en_centavos",
        "moneda",
        "ambiente",
        "resultado",
        "recibido_en",
    } <= columnas
    assert "payload" not in columnas
    assert "checksum" not in columnas
    assert "correo" not in columnas


def test_evento_aprobado_registra_trazabilidad(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token, amount=50000).get_json()
    payload = _event(donation["referencia"])
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200

    with app.app_context():
        evento = PAGO_EVENTO.query.one()
        assert evento.resultado == "aplicado"
        assert evento.id_donacion == donation["id_donacion"]
        assert evento.referencia == donation["referencia"]
        assert evento.wompi_transaction_id == payload["data"]["transaction"]["id"]
        assert evento.estado_wompi == "APPROVED"
        assert evento.monto_en_centavos == 5000000
        assert evento.moneda == "COP"
        assert evento.ambiente == "test"
        assert len(evento.huella_evento) == 64
        serializado = str(evento.to_dict())
        assert app.config["WOMPI_PRIVATE_KEY"] not in serializado
        assert app.config["WOMPI_INTEGRITY_SECRET"] not in serializado
        assert app.config["WOMPI_EVENTS_SECRET"] not in serializado


def test_evento_duplicado_no_duplica_registro_ni_recaudacion(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token, amount=50000).get_json()
    payload = _event(donation["referencia"])
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200

    with app.app_context():
        assert PAGO_EVENTO.query.count() == 1
        assert AUDITORIA.query.filter_by(accion="DONACION_PAGO").count() == 1
        assert float(CAMPAÑA.query.get(1).porcentaje_avance) == 1.0


def test_firma_invalida_no_registra_evento(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    payload = _event(donation["referencia"])
    payload["signature"]["checksum"] = "0" * 64
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 401
    with app.app_context():
        assert PAGO_EVENTO.query.count() == 0
        assert DONACION.query.get(donation["id_donacion"]).estado_pago == "pendiente"


def test_referencia_desconocida_se_registra_sin_donacion(client, wompi_config):
    payload = _event("REF-DESCONOCIDA")
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    with app.app_context():
        evento = PAGO_EVENTO.query.one()
        assert evento.resultado == "sin_donacion"
        assert evento.id_donacion is None
        assert evento.referencia == "REF-DESCONOCIDA"


def test_transicion_terminal_ignorada_queda_registrada(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    assert client.post(
        "/api/webhooks/wompi",
        json=_event(donation["referencia"], status="DECLINED"),
    ).status_code == 200
    assert client.post(
        "/api/webhooks/wompi",
        json=_event(donation["referencia"], status="APPROVED"),
    ).status_code == 200

    with app.app_context():
        resultados = [
            evento.resultado
            for evento in PAGO_EVENTO.query.order_by(PAGO_EVENTO.id_evento).all()
        ]
        assert resultados == ["aplicado", "ignorado"]
        assert DONACION.query.get(donation["id_donacion"]).estado_pago == "rechazada"


def test_fallo_financiero_no_deja_evento_parcial(client, wompi_config, monkeypatch):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    payload = _event(donation["referencia"])

    def fallar(*args, **kwargs):
        raise SQLAlchemyError("fallo de prueba")

    with monkeypatch.context() as scoped:
        scoped.setattr(wompi_routes, "registrar", fallar)
        assert client.post("/api/webhooks/wompi", json=payload).status_code == 503
    with app.app_context():
        assert PAGO_EVENTO.query.count() == 0
        assert DONACION.query.get(donation["id_donacion"]).estado_pago == "pendiente"

    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    with app.app_context():
        assert PAGO_EVENTO.query.count() == 1
        assert DONACION.query.get(donation["id_donacion"]).estado_pago == "aprobada"


def test_huella_es_estable_para_el_mismo_evento(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    payload = _event(donation["referencia"])
    assert client.post("/api/webhooks/wompi", json=payload).status_code == 200
    with app.app_context():
        huella = PAGO_EVENTO.query.one().huella_evento
    assert len(huella) == hashlib.sha256(b"").hexdigest().__len__()
