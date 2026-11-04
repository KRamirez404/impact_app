import base64
import uuid
from io import BytesIO

from sqlalchemy.exc import OperationalError

import app as app_module
from app import app
from conftest import get_support_token, get_token, register_user
from models import DONACION, PAGO_EVENTO, SOPORTE, USUARIO, db

PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII="
)


def _email(prefix):
    return f"{prefix}_{uuid.uuid4().hex[:8]}@test.co"


def _campaign_payload():
    return {
        "titulo": "Campaña privacidad",
        "descripcion": "Descripción pública",
        "id_ciudad": 1,
        "id_categoria": 1,
        "tipo_ayuda_requerida": "economica",
        "meta_monetaria": 500000,
        "cuenta_recaudo": "CUENTA-PRIVADA-123",
        "fecha_fin": "2030-01-01",
    }


def _create_campaign(client):
    correo = _email("org")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)
    response = client.post(
        "/api/campaigns",
        json=_campaign_payload(),
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    return correo, token, response.get_json()["id_campania"]


def test_public_campaigns_do_not_expose_private_data(client):
    _, owner_token, campaign_id = _create_campaign(client)
    support_token = get_support_token(client)
    support = client.post(
        "/api/supports",
        data={
            "id_campania": campaign_id,
            "tipo": "documento_oficial",
            "url_o_ruta": "https://documentos.example/privado.pdf",
        },
        headers={"Authorization": f"Bearer {owner_token}"},
    )
    assert support.status_code == 201
    approve = client.post(
        f"/api/support/campaigns/{campaign_id}/approve",
        headers={"Authorization": f"Bearer {support_token}"},
    )
    assert approve.status_code == 200

    donor_email = _email("don")
    register_user(client, rol="donante", correo=donor_email)
    donor_token = get_token(client, donor_email)
    donation = client.post(
        "/api/donations",
        json={"id_campania": campaign_id, "tipo": "alimentos", "monto_estimado": 1000},
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert donation.status_code == 201

    listing = client.get("/api/campaigns")
    assert listing.status_code == 200
    item = next(c for c in listing.get_json() if c["id_campania"] == campaign_id)
    assert "cuenta_recaudo" not in item
    assert "correo" not in item["creador"]
    assert "telefono" not in item["creador"]
    assert "biografia" not in item["creador"]

    detail = client.get(f"/api/campaigns/{campaign_id}")
    assert detail.status_code == 200
    body = detail.get_json()
    assert "cuenta_recaudo" not in body
    assert "nota_revision" not in body
    assert "auditor" not in body
    assert "correo" not in body["creador"]
    assert "telefono" not in body["creador"]
    assert "biografia" not in body["creador"]
    assert body["soportes"]
    assert "url_o_ruta" not in body["soportes"][0]
    assert body["donaciones"]
    for field in (
        "id_donante",
        "checksum",
        "referencia_pago",
        "wompi_transaction_id",
        "metodo_pago",
    ):
        assert field not in body["donaciones"][0]


def test_private_support_files_require_authentication_and_owner_or_support(
    client, monkeypatch, tmp_path
):
    monkeypatch.setitem(app.config, "UPLOAD_FOLDER", str(tmp_path))
    _, owner_token, campaign_id = _create_campaign(client)
    upload = client.post(
        "/api/supports",
        data={
            "id_campania": campaign_id,
            "tipo": "documento_oficial",
            "file": (BytesIO(PNG), "documento.png", "image/png"),
        },
        headers={"Authorization": f"Bearer {owner_token}"},
    )
    assert upload.status_code == 201
    url = upload.get_json()["url_o_ruta"]

    assert client.get(url).status_code == 401

    other_email = _email("otro")
    register_user(client, rol="donante", correo=other_email)
    other_token = get_token(client, other_email)
    assert client.get(url, headers={"Authorization": f"Bearer {other_token}"}).status_code == 404

    assert client.get(url, headers={"Authorization": f"Bearer {owner_token}"}).status_code == 200
    support_token = get_support_token(client)
    assert client.get(url, headers={"Authorization": f"Bearer {support_token}"}).status_code == 200

    assert client.get(f"/api/supports/campaign/{campaign_id}").status_code == 401
    assert (
        client.get(
            f"/api/supports/campaign/{campaign_id}",
            headers={"Authorization": f"Bearer {other_token}"},
        ).status_code
        == 403
    )
    assert (
        client.get(
            f"/api/supports/campaign/{campaign_id}",
            headers={"Authorization": f"Bearer {owner_token}"},
        ).status_code
        == 200
    )
    assert (
        client.get(
            f"/api/supports/campaign/{campaign_id}",
            headers={"Authorization": f"Bearer {support_token}"},
        ).status_code
        == 200
    )


def test_private_document_cannot_be_published_by_reference(
    client, monkeypatch, tmp_path
):
    monkeypatch.setitem(app.config, "UPLOAD_FOLDER", str(tmp_path))
    _, owner_token, campaign_id = _create_campaign(client)
    upload = client.post(
        "/api/supports",
        data={
            "id_campania": campaign_id,
            "tipo": "documento_oficial",
            "file": (BytesIO(PNG), "documento.png", "image/png"),
        },
        headers={"Authorization": f"Bearer {owner_token}"},
    )
    assert upload.status_code == 201
    url = upload.get_json()["url_o_ruta"]

    other_email = _email("ref")
    register_user(client, correo=other_email)
    other_token = get_token(client, other_email)
    update = client.put(
        "/api/auth/me",
        json={"foto_perfil": url},
        headers={"Authorization": f"Bearer {other_token}"},
    )
    assert update.status_code == 200
    assert client.get(url).status_code == 401


def test_public_campaign_image_remains_accessible(client, monkeypatch, tmp_path):
    monkeypatch.setitem(app.config, "UPLOAD_FOLDER", str(tmp_path))
    _, owner_token, campaign_id = _create_campaign(client)
    upload = client.post(
        "/api/supports",
        data={
            "id_campania": campaign_id,
            "tipo": "foto",
            "file": (BytesIO(PNG), "portada.png", "image/png"),
        },
        headers={"Authorization": f"Bearer {owner_token}"},
    )
    assert upload.status_code == 201
    assert client.get(upload.get_json()["url_o_ruta"]).status_code == 200


def test_login_rate_limit(client, monkeypatch):
    monkeypatch.setitem(app.config, "RATE_LIMIT_LOGIN_ATTEMPTS", 2)
    monkeypatch.setitem(app.config, "RATE_LIMIT_LOGIN_IP_ATTEMPTS", 50)
    correo = _email("lim")
    register_user(client, correo=correo)
    assert client.post(
        "/api/auth/login", json={"correo": correo, "contrasena": "WrongPass1"}
    ).status_code == 401
    assert client.post(
        "/api/auth/login", json={"correo": correo, "contrasena": "WrongPass1"}
    ).status_code == 401
    blocked = client.post(
        "/api/auth/login", json={"correo": correo, "contrasena": "WrongPass1"}
    )
    assert blocked.status_code == 429
    assert "Retry-After" in blocked.headers


def test_register_rate_limit(client, monkeypatch):
    monkeypatch.setitem(app.config, "RATE_LIMIT_REGISTER_ATTEMPTS", 2)
    assert register_user(client, correo=_email("reg")).status_code == 201
    assert register_user(client, correo=_email("reg")).status_code == 201
    blocked = register_user(client, correo=_email("reg"))
    assert blocked.status_code == 429


def test_upload_rate_limit(client, monkeypatch, tmp_path):
    monkeypatch.setitem(app.config, "UPLOAD_FOLDER", str(tmp_path))
    monkeypatch.setitem(app.config, "RATE_LIMIT_UPLOAD_ATTEMPTS", 2)
    correo = _email("up")
    register_user(client, correo=correo)
    token = get_token(client, correo)
    headers = {"Authorization": f"Bearer {token}"}
    for _ in range(2):
        response = client.post(
            "/api/upload",
            data={"file": (BytesIO(PNG), "foto.png", "image/png")},
            headers=headers,
        )
        assert response.status_code == 201
    blocked = client.post(
        "/api/upload",
        data={"file": (BytesIO(PNG), "foto.png", "image/png")},
        headers=headers,
    )
    assert blocked.status_code == 429


def test_health_checks_database(client, monkeypatch):
    assert client.get("/api/health").status_code == 200
    assert client.get("/api/health").get_json()["database"] == "ok"

    def unavailable():
        raise OperationalError("SELECT 1", {}, Exception("database down"))

    monkeypatch.setattr(app_module, "database_available", unavailable)
    response = client.get("/api/health")
    assert response.status_code == 503
    assert response.get_json()["database"] == "unavailable"


def test_invalid_webhook_signature_does_not_create_records(client, monkeypatch):
    for key, value in {
        "WOMPI_PUBLIC_KEY": "pub_test_000000000000000000000000000000",
        "WOMPI_PRIVATE_KEY": "prv_test_000000000000000000000000000000",
        "WOMPI_INTEGRITY_SECRET": "test_integrity_secret",
        "WOMPI_EVENTS_SECRET": "test_events_secret",
        "WOMPI_ENV": "sandbox",
        "WOMPI_ALLOW_PRODUCTION": False,
        "WOMPI_API_URL": "https://sandbox.wompi.co/v1",
        "WOMPI_CHECKOUT_URL": "https://checkout.wompi.co/p/",
        "WOMPI_CURRENCY": "COP",
    }.items():
        monkeypatch.setitem(app.config, key, value)
    payload = {
        "event": "transaction.updated",
        "environment": "test",
        "timestamp": 1530291411,
        "signature": {
            "properties": ["transaction.id"],
            "checksum": "0" * 64,
        },
        "data": {"transaction": {"id": "tx-invalida"}},
    }
    response = client.post("/api/webhooks/wompi", json=payload)
    assert response.status_code == 401
    with app.app_context():
        assert PAGO_EVENTO.query.count() == 0
        assert DONACION.query.count() == 0


def test_seed_does_not_create_default_support_admin(client):
    with app.app_context():
        assert USUARIO.query.filter_by(correo="admin@impactapp.co").first() is None
        assert SOPORTE.query.count() >= 1
