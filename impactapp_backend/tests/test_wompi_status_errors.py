import urllib.error
from copy import deepcopy
from io import BytesIO

import pytest

from app import app
from conftest import SUPPORT_EMAIL, get_support_token
from models import AUDITORIA, CAMPAÑA, DONACION, PAGO_EVENTO, PAGO_INTENTO, USUARIO, db
from routes import wompi_routes
from services import wompi_service
from services.auth_service import anonymize_user
from test_wompi_extra import _checkout, _token, wompi_config

FETCH_BY_REFERENCE = wompi_service.fetch_transaction_by_reference
FETCH_TRANSACTION = wompi_service.fetch_transaction


@pytest.fixture()
def pago(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    return client, token, donation


def _headers(token):
    return {"Authorization": f"Bearer {token}"}


def _snapshot(donation_id):
    with app.app_context():
        row = db.session.get(DONACION, donation_id)
        return {
            "estado": row.estado_pago,
            "tx": row.wompi_transaction_id,
            "intentos": PAGO_INTENTO.query.filter_by(id_donacion=donation_id).count(),
            "eventos": PAGO_EVENTO.query.filter_by(id_donacion=donation_id).count(),
            "auditorias": AUDITORIA.query.filter_by(
                accion="DONACION_PAGO", id_entidad=donation_id
            ).count(),
        }


def _progress():
    with app.app_context():
        return float(db.session.get(CAMPAÑA, 1).porcentaje_avance)


def _transaction(donation, **overrides):
    transaction = {
        "id": "STATUS-TX",
        "status": "APPROVED",
        "amount_in_cents": 5000000,
        "reference": donation["referencia"],
        "currency": "COP",
        "payment_method_type": "CARD",
    }
    transaction.update(overrides)
    return transaction


def _status(client, token, donation, query=None):
    return client.get(
        f'/api/donations/{donation["id_donacion"]}/status',
        query_string=query or {},
        headers=_headers(token),
    )


def test_status_reference_timeout_returns_503_without_changing_donation(pago, monkeypatch):
    client, token, donation = pago
    before = _snapshot(donation["id_donacion"])

    def fallar(_reference):
        raise wompi_service.WompiQueryError("proveedor_no_disponible")

    monkeypatch.setattr(
        wompi_routes.wompi_service,
        "fetch_transaction_by_reference",
        fallar,
    )
    response = _status(client, token, donation)
    assert response.status_code == 503
    assert response.get_json()["code"] == "proveedor_no_disponible"
    assert _snapshot(donation["id_donacion"]) == before


def test_status_reference_invalid_response_returns_502(pago, monkeypatch):
    client, token, donation = pago
    before = _snapshot(donation["id_donacion"])

    def fallar(_reference):
        raise wompi_service.WompiQueryError(
            "respuesta_proveedor_invalida", retryable=False
        )

    monkeypatch.setattr(
        wompi_routes.wompi_service,
        "fetch_transaction_by_reference",
        fallar,
    )
    response = _status(client, token, donation)
    assert response.status_code == 502
    assert response.get_json()["code"] == "respuesta_proveedor_invalida"
    assert _snapshot(donation["id_donacion"]) == before


def test_status_reference_without_transaction_returns_existing_contract(pago, monkeypatch):
    client, token, donation = pago
    before = _snapshot(donation["id_donacion"])
    monkeypatch.setattr(
        wompi_routes.wompi_service,
        "fetch_transaction_by_reference",
        lambda _reference: None,
    )
    response = _status(client, token, donation)
    assert response.status_code == 200
    body = response.get_json()
    assert body["estado_pago"] == "pendiente"
    assert body["conciliacion"] == "sin_identificador"
    assert body["code"] == "transaccion_no_encontrada"
    assert _snapshot(donation["id_donacion"]) == before


@pytest.mark.parametrize(
    "override",
    [
        {"amount_in_cents": 1},
        {"currency": "USD"},
        {"reference": "OTRA-REFERENCIA"},
    ],
)
def test_status_reference_conflict_returns_409_without_credit(
    pago, monkeypatch, override
):
    client, token, donation = pago
    before = _snapshot(donation["id_donacion"])
    transaction = _transaction(donation, **override)
    monkeypatch.setattr(
        wompi_routes.wompi_service,
        "fetch_transaction_by_reference",
        lambda _reference: deepcopy(transaction),
    )
    response = _status(client, token, donation)
    assert response.status_code == 409
    assert response.get_json()["code"] == "conciliacion_conflicto"
    assert _snapshot(donation["id_donacion"]) == before
    assert _progress() == 15.0


def test_status_hint_with_invalid_wompi_config_returns_503(pago, monkeypatch):
    client, token, donation = pago
    before = _snapshot(donation["id_donacion"])

    def fallar(_transaction_id):
        raise wompi_service.WompiConfigurationError()

    monkeypatch.setattr(wompi_routes.wompi_service, "fetch_transaction", fallar)
    response = _status(client, token, donation, {"transaction_id": "TX-VALID"})
    assert response.status_code == 503
    assert response.get_json()["code"] == "wompi_no_configurado"
    assert _snapshot(donation["id_donacion"]) == before


def test_status_historical_conflict_does_not_overwrite_old_identifier(pago, monkeypatch):
    client, token, donation = pago
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        row.estado_pago = "rechazada"
        row.wompi_transaction_id = "OLD-TX"
        db.session.commit()
    before = _snapshot(donation["id_donacion"])
    transaction = _transaction(donation, id="NEW-TX")
    monkeypatch.setattr(
        wompi_routes.wompi_service,
        "fetch_transaction",
        lambda _transaction_id: deepcopy(transaction),
    )
    response = _status(client, token, donation, {"transaction_id": "NEW-TX"})
    assert response.status_code == 409
    assert response.get_json()["code"] == "conciliacion_historica_pendiente"
    assert _snapshot(donation["id_donacion"]) == before
    assert before["tx"] == "OLD-TX"
    assert before["estado"] == "rechazada"
    assert _progress() == 15.0


def test_status_approved_without_identifier_returns_409_without_repair(pago, monkeypatch):
    client, token, donation = pago
    with app.app_context():
        row = db.session.get(DONACION, donation["id_donacion"])
        row.estado_pago = "aprobada"
        row.wompi_transaction_id = None
        db.session.commit()
    before = _snapshot(donation["id_donacion"])
    transaction = _transaction(donation)
    monkeypatch.setattr(
        wompi_routes.wompi_service,
        "fetch_transaction",
        lambda _transaction_id: deepcopy(transaction),
    )
    response = _status(client, token, donation, {"transaction_id": "STATUS-TX"})
    assert response.status_code == 409
    assert response.get_json()["code"] == "conciliacion_aprobacion_sin_transaccion"
    assert _snapshot(donation["id_donacion"]) == before
    assert before["estado"] == "aprobada"
    assert before["tx"] is None
    assert before["intentos"] == 0


def test_status_verified_includes_stable_code(pago, monkeypatch):
    client, token, donation = pago
    transaction = _transaction(donation, id="VERIFIED-TX")
    monkeypatch.setattr(
        wompi_routes.wompi_service,
        "fetch_transaction",
        lambda _transaction_id: deepcopy(transaction),
    )
    response = _status(client, token, donation, {"transaction_id": "VERIFIED-TX"})
    assert response.status_code == 200
    body = response.get_json()
    assert body["estado_pago"] == "aprobada"
    assert body["conciliacion"] == "verificada"
    assert body["code"] == "conciliacion_verificada"


def test_status_active_support_can_query(pago):
    client, _, donation = pago
    support_token = get_support_token(client)
    response = _status(client, support_token, donation)
    assert response.status_code == 200


def test_status_blocked_support_with_old_token_is_rejected(pago):
    client, _, donation = pago
    support_token = get_support_token(client)
    with app.app_context():
        support = USUARIO.query.filter_by(correo=SUPPORT_EMAIL).one()
        support.estado = "bloqueado"
        db.session.commit()
    response = _status(client, support_token, donation)
    assert response.status_code == 401


def test_status_anonymized_support_token_is_revoked(client):
    support_token = get_support_token(client)
    with app.app_context():
        support = USUARIO.query.filter_by(correo=SUPPORT_EMAIL).one()
        anonymize_user(support)
    response = client.get("/api/auth/me", headers=_headers(support_token))
    assert response.status_code == 401


def test_status_owner_can_query_and_other_donor_cannot(pago):
    client, token, donation = pago
    other_token = _token(client)[1]
    assert _status(client, token, donation).status_code == 200
    before = _snapshot(donation["id_donacion"])
    response = _status(client, other_token, donation)
    assert response.status_code == 403
    assert _snapshot(donation["id_donacion"]) == before


def test_fetch_by_reference_timeout_is_typed(wompi_config, monkeypatch):
    monkeypatch.setattr(
        wompi_service, "fetch_transaction_by_reference", FETCH_BY_REFERENCE
    )

    def fallar(*_args, **_kwargs):
        raise TimeoutError()

    monkeypatch.setattr(wompi_service.urllib.request, "urlopen", fallar)
    with app.app_context(), pytest.raises(wompi_service.WompiQueryError) as info:
        FETCH_BY_REFERENCE("REFERENCIA")
    assert info.value.code == "proveedor_no_disponible"


def test_fetch_by_reference_invalid_json_is_typed(wompi_config, monkeypatch):
    monkeypatch.setattr(
        wompi_service, "fetch_transaction_by_reference", FETCH_BY_REFERENCE
    )
    monkeypatch.setattr(
        wompi_service.urllib.request,
        "urlopen",
        lambda *_args, **_kwargs: BytesIO(b"{invalido"),
    )
    with app.app_context(), pytest.raises(wompi_service.WompiQueryError) as info:
        FETCH_BY_REFERENCE("REFERENCIA")
    assert info.value.code == "respuesta_proveedor_invalida"


def test_fetch_by_reference_empty_list_is_not_a_failure(wompi_config, monkeypatch):
    monkeypatch.setattr(
        wompi_service, "fetch_transaction_by_reference", FETCH_BY_REFERENCE
    )
    monkeypatch.setattr(
        wompi_service.urllib.request,
        "urlopen",
        lambda *_args, **_kwargs: BytesIO(b'{"data": []}'),
    )
    with app.app_context():
        assert FETCH_BY_REFERENCE("REFERENCIA") is None


def test_fetch_transaction_404_is_typed(wompi_config, monkeypatch):
    monkeypatch.setattr(wompi_service, "fetch_transaction", FETCH_TRANSACTION)

    def fallar(*_args, **_kwargs):
        raise urllib.error.HTTPError(
            "https://provider.invalid/transactions/TX", 404, "not found", {}, None
        )

    monkeypatch.setattr(wompi_service.urllib.request, "urlopen", fallar)
    with app.app_context(), pytest.raises(wompi_service.WompiQueryError) as info:
        FETCH_TRANSACTION("TX")
    assert info.value.code == "transaccion_no_encontrada"
