from copy import deepcopy

from app import app
from models import AUDITORIA, CAMPAÑA, DONACION, PAGO_INTENTO, db
from routes.wompi_routes import reconcile_pending_donations
from services import wompi_service
from test_wompi_extra import _checkout, _token, wompi_config


def _transaction(donation):
    return {
        "id": "RECONCILE-1",
        "status": "APPROVED",
        "amount_in_cents": 5000000,
        "reference": donation["referencia"],
        "currency": "COP",
        "payment_method_type": "CARD",
    }


def _snapshot(donation_id):
    with app.app_context():
        row = db.session.get(DONACION, donation_id)
        return row.estado_pago, row.wompi_transaction_id, float(
            db.session.get(CAMPAÑA, 1).porcentaje_avance
        )


def test_barrido_acredita_pendiente_sin_webhook(client, wompi_config, monkeypatch):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    monkeypatch.setattr(
        wompi_service,
        "fetch_transaction_by_reference",
        lambda _reference: deepcopy(_transaction(donation)),
    )

    with app.app_context():
        resultado = reconcile_pending_donations(
            limit=10, min_age_minutes=0, max_age_hours=24
        )

    assert resultado == {
        "revisadas": 1,
        "verificadas": 1,
        "sin_transaccion": 0,
        "sin_cambio": 0,
        "errores": 0,
        "detenido_por": None,
    }
    assert _snapshot(donation["id_donacion"]) == ("aprobada", "RECONCILE-1", 1.0)
    with app.app_context():
        intento = PAGO_INTENTO.query.filter_by(
            id_donacion=donation["id_donacion"]
        ).one()
        assert intento.resultado == "acreditado"
        assert AUDITORIA.query.filter_by(accion="DONACION_PAGO").count() == 1


def test_barrido_omite_donaciones_recientes(client, wompi_config, monkeypatch):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()

    def no_consultar(_reference):
        raise AssertionError("no debe consultar")

    monkeypatch.setattr(
        wompi_service, "fetch_transaction_by_reference", no_consultar
    )

    with app.app_context():
        resultado = reconcile_pending_donations(
            limit=10, min_age_minutes=10, max_age_hours=24
        )

    assert resultado["revisadas"] == 0
    assert resultado["errores"] == 0
    assert _snapshot(donation["id_donacion"])[0] == "pendiente"


def test_barrido_se_detiene_ante_fallo_temporal(client, wompi_config, monkeypatch):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()

    def fallar(_reference):
        raise wompi_service.WompiQueryError("proveedor_no_disponible")

    monkeypatch.setattr(wompi_service, "fetch_transaction_by_reference", fallar)

    with app.app_context():
        resultado = reconcile_pending_donations(
            limit=10, min_age_minutes=0, max_age_hours=24
        )

    assert resultado["revisadas"] == 1
    assert resultado["errores"] == 1
    assert resultado["detenido_por"] == "proveedor_no_disponible"
    assert _snapshot(donation["id_donacion"]) == ("pendiente", None, 15.0)
    with app.app_context():
        assert PAGO_INTENTO.query.count() == 0
