import hashlib
import uuid

import pytest

from app import app
from models import AUDITORIA, CAMPAÑA, DONACION, db
from conftest import get_token, register_user
from services import wompi_service

EVENTS_SECRET = "test_events_secret"
INTEGRITY_SECRET = "test_integrity_secret"
PUBLIC_KEY = "pub_test_000000000000000000000000000000"
ADMIN = {"correo": "admin@impactapp.co", "contrasena": "Admin123*"}


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


def _email(prefix):
    return f"{prefix}_{uuid.uuid4().hex[:8]}@test.co"


def _token(client, rol="donante"):
    correo = _email(rol)
    register_user(client, rol=rol, correo=correo)
    return correo, get_token(client, correo)


def _checkout(client, token, amount=50000, campaign_id=1, **extra):
    payload = {"id_campania": campaign_id, "monto_estimado": amount}
    payload.update(extra)
    return client.post(
        "/api/donations/checkout",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )


def _event(reference, *, tx_id="1234-1610641025-49201", status="APPROVED",
           amount_in_cents=5000000, environment="test", timestamp=1530291411):
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
    concat = tx_id + status + str(amount_in_cents) + str(timestamp) + EVENTS_SECRET
    checksum = hashlib.sha256(concat.encode("utf-8")).hexdigest()
    return {
        "event": "transaction.updated",
        "data": data,
        "environment": environment,
        "signature": {"properties": properties, "checksum": checksum},
        "timestamp": timestamp,
    }


def _campaign_payload():
    return {
        "titulo": "Campaña de prueba",
        "descripcion": "Descripción",
        "id_ciudad": 1,
        "id_categoria": 1,
        "tipo_ayuda_requerida": "economica",
        "meta_monetaria": 1000000,
        "cuenta_recaudo": "1234567890",
        "fecha_fin": "2030-01-01",
    }


def _progress():
    with app.app_context():
        return float(CAMPAÑA.query.get(1).porcentaje_avance)


def test_amount_to_cents_rounds():
    assert wompi_service.amount_to_cents(50000) == 5000000
    assert wompi_service.amount_to_cents(1234.5) == 123450
    assert wompi_service.amount_to_cents("50000") == 5000000


def test_integrity_signature_with_expiration():
    signature = wompi_service.integrity_signature(
        reference="REF-9",
        amount_in_cents=1000000,
        currency="COP",
        integrity_secret=INTEGRITY_SECRET,
        expiration_time="2026-01-01T00:00:00.000Z",
    )
    expected = hashlib.sha256(
        f"REF-91000000COP2026-01-01T00:00:00.000Z{INTEGRITY_SECRET}".encode("utf-8")
    ).hexdigest()
    assert signature == expected


def test_checkout_anonymous_returns_401(client, wompi_config):
    resp = client.post("/api/donations/checkout", json={"id_campania": 1, "monto_estimado": 50000})
    assert resp.status_code == 401


def test_checkout_requires_donante_role(client, wompi_config):
    _, token = _token(client, "organizador")
    resp = _checkout(client, token)
    assert resp.status_code == 403


def test_checkout_unknown_campaign_returns_404(client, wompi_config):
    _, token = _token(client)
    resp = _checkout(client, token, campaign_id=99999)
    assert resp.status_code == 404


def test_checkout_inactive_campaign_returns_400(client, wompi_config):
    _, org_token = _token(client, "organizador")
    created = client.post(
        "/api/campaigns",
        json=_campaign_payload(),
        headers={"Authorization": f"Bearer {org_token}"},
    )
    campaign_id = created.get_json()["id_campania"]
    _, token = _token(client)
    resp = _checkout(client, token, campaign_id=campaign_id)
    assert resp.status_code == 400
    assert "activa" in resp.get_json()["error"].lower()


def test_checkout_missing_campaign_field(client, wompi_config):
    _, token = _token(client)
    resp = client.post(
        "/api/donations/checkout",
        json={"monto_estimado": 50000},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 400


def test_checkout_invalid_amount_type(client, wompi_config):
    _, token = _token(client)
    resp = _checkout(client, token, amount="no-numero")
    assert resp.status_code == 400


def test_checkout_url_contains_email_and_redirect(client, wompi_config):
    correo, token = _token(client)
    body = _checkout(client, token).get_json()
    url = body["checkout_url"]
    assert "customer-data:email=" in url
    assert correo.replace("@", "%40") in url
    assert "redirect-url=" in url


def test_checkout_creates_audit_entry(client, wompi_config):
    _, token = _token(client)
    _checkout(client, token)
    with app.app_context():
        acciones = {row.accion for row in AUDITORIA.query.all()}
    assert "DONACION_CHECKOUT" in acciones


def test_checkout_donation_is_intact(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    listing = client.get("/api/donations/campaign/1").get_json()
    item = next(d for d in listing if d["id_donacion"] == donation["id_donacion"])
    assert item["integridad"] is True
    assert item["estado_pago"] == "pendiente"


def test_pending_donation_does_not_change_progress(client, wompi_config):
    _, token = _token(client)
    _checkout(client, token, amount=50000)
    assert _progress() == 15.0


def test_physical_donation_does_not_change_monetary_progress(client, wompi_config):
    _, token = _token(client)
    client.post(
        "/api/donations",
        json={"id_campania": 1, "tipo": "alimentos", "monto_estimado": 1000},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert _progress() == 15.0


def test_pending_donation_excluded_from_top_donors(client, wompi_config):
    _, token = _token(client)
    _checkout(client, token, amount=50000)
    top = client.get("/api/donations/top").get_json()
    assert top == []


def test_progress_capped_at_100(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token, amount=6000000).get_json()
    client.post(
        "/api/webhooks/wompi",
        json=_event(donation["referencia"], amount_in_cents=600000000),
    )
    assert _progress() == 100.0


def test_webhook_wrong_event_ignored(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    payload = _event(donation["referencia"])
    payload["event"] = "otro.evento"
    resp = client.post("/api/webhooks/wompi", json=payload)
    assert resp.status_code == 200
    with app.app_context():
        assert DONACION.query.get(donation["id_donacion"]).estado_pago == "pendiente"


def test_webhook_environment_mismatch_rejected(client, wompi_config):
    app.config["WOMPI_ENV"] = "prod"
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    resp = client.post("/api/webhooks/wompi", json=_event(donation["referencia"]))
    assert resp.status_code == 401


@pytest.mark.parametrize(
    "wompi_status,expected",
    [("VOIDED", "anulada"), ("ERROR", "error"), ("DECLINED", "rechazada")],
)
def test_webhook_maps_terminal_statuses(client, wompi_config, wompi_status, expected):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    resp = client.post(
        "/api/webhooks/wompi", json=_event(donation["referencia"], status=wompi_status)
    )
    assert resp.status_code == 200
    with app.app_context():
        assert DONACION.query.get(donation["id_donacion"]).estado_pago == expected


def test_webhook_idempotent_does_not_duplicate_audit(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    event = _event(donation["referencia"])
    client.post("/api/webhooks/wompi", json=event)
    client.post("/api/webhooks/wompi", json=event)
    with app.app_context():
        count = AUDITORIA.query.filter_by(accion="DONACION_PAGO").count()
    assert count == 1


def test_status_forbidden_for_other_donante(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    _, other_token = _token(client)
    resp = client.get(
        f"/api/donations/{donation['id_donacion']}/status",
        headers={"Authorization": f"Bearer {other_token}"},
    )
    assert resp.status_code == 403


def test_status_allowed_for_support(client, wompi_config):
    _, token = _token(client)
    donation = _checkout(client, token).get_json()
    admin_token = get_token(client, ADMIN["correo"], ADMIN["contrasena"])
    resp = client.get(
        f"/api/donations/{donation['id_donacion']}/status",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    assert resp.get_json()["estado_pago"] == "pendiente"


def test_status_unknown_donation_returns_404(client, wompi_config):
    _, token = _token(client)
    resp = client.get(
        "/api/donations/99999/status",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 404


def test_webhook_missing_reference_is_ignored(client, wompi_config):
    payload = _event("X")
    payload["data"]["transaction"].pop("reference")
    resp = client.post("/api/webhooks/wompi", json=payload)
    assert resp.status_code == 200
