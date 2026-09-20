import hashlib
import uuid

import pytest

from app import app
from models import DONACION, CAMPAÑA
from conftest import get_token, register_user
from services import wompi_service

EVENTS_SECRET = "test_events_secret"
INTEGRITY_SECRET = "test_integrity_secret"
PUBLIC_KEY = "pub_test_000000000000000000000000000000"


@pytest.fixture()
def wompi_config():
    original = dict(app.config)
    app.config.update(
        WOMPI_PUBLIC_KEY=PUBLIC_KEY,
        WOMPI_PRIVATE_KEY="prv_test_000000000000000000000000000000",
        WOMPI_INTEGRITY_SECRET=INTEGRITY_SECRET,
        WOMPI_EVENTS_SECRET=EVENTS_SECRET,
        WOMPI_ENV="sandbox",
        WOMPI_CURRENCY="COP",
        WOMPI_MIN_AMOUNT=1000,
    )
    yield app.config
    app.config.clear()
    app.config.update(original)


def _donante_token(client):
    correo = f"don_{uuid.uuid4().hex[:8]}@test.co"
    register_user(client, rol="donante", correo=correo)
    return get_token(client, correo)


def _checkout(client, token, amount=50000, campaign_id=1):
    return client.post(
        "/api/donations/checkout",
        json={"id_campania": campaign_id, "monto_estimado": amount},
        headers={"Authorization": f"Bearer {token}"},
    )


def _event(reference, *, tx_id="1234-1610641025-49201", status="APPROVED", amount_in_cents=5000000):
    properties = ["transaction.id", "transaction.status", "transaction.amount_in_cents"]
    data = {
        "transaction": {
            "id": tx_id,
            "status": status,
            "amount_in_cents": amount_in_cents,
            "reference": reference,
            "payment_method_type": "CARD",
        }
    }
    timestamp = 1530291411
    concat = tx_id + status + str(amount_in_cents) + str(timestamp) + EVENTS_SECRET
    checksum = hashlib.sha256(concat.encode("utf-8")).hexdigest()
    return {
        "event": "transaction.updated",
        "data": data,
        "environment": "test",
        "signature": {"properties": properties, "checksum": checksum},
        "timestamp": timestamp,
    }


def test_integrity_signature_matches_manual_hash():
    signature = wompi_service.integrity_signature(
        reference="REF-1",
        amount_in_cents=5000000,
        currency="COP",
        integrity_secret=INTEGRITY_SECRET,
    )
    expected = hashlib.sha256(
        f"REF-15000000COP{INTEGRITY_SECRET}".encode("utf-8")
    ).hexdigest()
    assert signature == expected


def test_checkout_fails_without_configuration(client):
    original = dict(app.config)
    app.config.update(WOMPI_PUBLIC_KEY="", WOMPI_INTEGRITY_SECRET="")
    try:
        token = _donante_token(client)
        resp = _checkout(client, token)
        assert resp.status_code == 503
    finally:
        app.config.clear()
        app.config.update(original)


def test_checkout_creates_pending_donation(client, wompi_config):
    token = _donante_token(client)
    resp = _checkout(client, token, amount=50000)
    assert resp.status_code == 201
    body = resp.get_json()
    assert body["estado_pago"] == "pendiente"
    assert body["referencia"].startswith("IMPACTAPP-")
    assert "signature:integrity=" in body["checkout_url"]
    assert "amount-in-cents=5000000" in body["checkout_url"]

    with app.app_context():
        donation = DONACION.query.get(body["id_donacion"])
        assert donation.estado_pago == "pendiente"
        assert donation.tipo == "economica"


def test_checkout_rejects_amount_below_minimum(client, wompi_config):
    token = _donante_token(client)
    resp = _checkout(client, token, amount=100)
    assert resp.status_code == 400


def test_webhook_rejects_invalid_signature(client, wompi_config):
    token = _donante_token(client)
    donation = _checkout(client, token).get_json()
    payload = _event(donation["referencia"])
    payload["signature"]["checksum"] = "deadbeef"
    resp = client.post("/api/webhooks/wompi", json=payload)
    assert resp.status_code == 401


def test_webhook_approves_donation_and_updates_progress(client, wompi_config):
    token = _donante_token(client)
    donation = _checkout(client, token, amount=50000).get_json()

    resp = client.post(
        "/api/webhooks/wompi", json=_event(donation["referencia"])
    )
    assert resp.status_code == 200

    with app.app_context():
        stored = DONACION.query.get(donation["id_donacion"])
        assert stored.estado_pago == "aprobada"
        assert stored.wompi_transaction_id == "1234-1610641025-49201"
        assert stored.fecha_pago is not None
        campaign = CAMPAÑA.query.get(1)
        assert float(campaign.porcentaje_avance) == 1.0


def test_webhook_declined_marks_donation_rejected(client, wompi_config):
    token = _donante_token(client)
    donation = _checkout(client, token).get_json()
    payload = _event(donation["referencia"], status="DECLINED")
    resp = client.post("/api/webhooks/wompi", json=payload)
    assert resp.status_code == 200

    with app.app_context():
        stored = DONACION.query.get(donation["id_donacion"])
        assert stored.estado_pago == "rechazada"
        campaign = CAMPAÑA.query.get(1)
        assert float(campaign.porcentaje_avance) == 15.0


def test_webhook_is_idempotent(client, wompi_config):
    token = _donante_token(client)
    donation = _checkout(client, token, amount=50000).get_json()
    event = _event(donation["referencia"])

    client.post("/api/webhooks/wompi", json=event)
    client.post("/api/webhooks/wompi", json=event)

    with app.app_context():
        campaign = CAMPAÑA.query.get(1)
        assert float(campaign.porcentaje_avance) == 1.0


def test_webhook_ignores_unknown_reference(client, wompi_config):
    resp = client.post(
        "/api/webhooks/wompi", json=_event("REF-DESCONOCIDA")
    )
    assert resp.status_code == 200


def test_status_endpoint_returns_donation(client, wompi_config):
    token = _donante_token(client)
    donation = _checkout(client, token).get_json()
    resp = client.get(
        f"/api/donations/{donation['id_donacion']}/status",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert resp.get_json()["estado_pago"] == "pendiente"
