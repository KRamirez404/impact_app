import uuid

from conftest import get_token, register_user

ADMIN = {"correo": "admin@impactapp.co", "contrasena": "Admin123*"}


def _new_email(prefix):
    return f"{prefix}_{uuid.uuid4().hex[:8]}@test.co"


def _campaign_payload(tipo="economica"):
    return {
        "titulo": "Campaña verificación",
        "descripcion": "Descripción",
        "id_ciudad": 1,
        "id_categoria": 1,
        "tipo_ayuda_requerida": tipo,
        "meta_monetaria": 500000,
        "cuenta_recaudo": "AAA000",
        "fecha_fin": "2030-01-01",
    }


def _create_economic_campaign(client):
    correo = _new_email("org")
    register_user(client, rol="organizador", correo=correo)
    org_token = get_token(client, correo)
    resp = client.post(
        "/api/campaigns", json=_campaign_payload(),
        headers={"Authorization": f"Bearer {org_token}"},
    )
    campaign_id = resp.get_json()["id_campania"]
    return correo, org_token, campaign_id


def test_privacy_policy_endpoint(client):
    resp = client.get("/api/auth/privacy-policy")
    assert resp.status_code == 200
    body = resp.get_json()
    assert "titulo" in body
    assert "Ley 1581" in body["norma"]


def test_delete_me_anonymizes_account(client):
    correo = _new_email("del")
    register_user(client, rol="donante", correo=correo)
    token = get_token(client, correo)

    resp = client.delete("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200

    me = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    body = me.get_json()
    assert body["estado"] == "bloqueado"
    assert "eliminado_" in body["correo"]

    login = client.post("/api/auth/login", json={"correo": correo, "contrasena": "Passw0rd!"})
    assert login.status_code == 401


def test_approve_economic_campaign_requires_document(client):
    _, org_token, campaign_id = _create_economic_campaign(client)
    admin_token = get_token(client, ADMIN["correo"], ADMIN["contrasena"])

    resp = client.post(
        f"/api/support/campaigns/{campaign_id}/approve",
        json={"nota": "aprobada"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 400
    assert "documento" in resp.get_json()["error"].lower()

    support = client.post(
        "/api/supports",
        data={
            "id_campania": campaign_id,
            "tipo": "documento_oficial",
            "descripcion": "RUT del organizador",
            "url_o_ruta": "https://ejemplo.org/rut.pdf",
        },
        headers={"Authorization": f"Bearer {org_token}"},
    )
    assert support.status_code == 201

    resp = client.post(
        f"/api/support/campaigns/{campaign_id}/approve",
        json={"nota": "aprobada"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    assert resp.get_json()["estado"] == "activa"


def test_bank_account_locked_after_approval(client):
    correo, org_token, campaign_id = _create_economic_campaign(client)
    admin_token = get_token(client, ADMIN["correo"], ADMIN["contrasena"])
    client.post(
        "/api/supports",
        data={
            "id_campania": campaign_id,
            "tipo": "documento_oficial",
            "url_o_ruta": "https://ejemplo.org/rut.pdf",
        },
        headers={"Authorization": f"Bearer {org_token}"},
    )
    client.post(
        f"/api/support/campaigns/{campaign_id}/approve",
        json={"nota": "ok"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )

    resp = client.put(
        f"/api/campaigns/{campaign_id}",
        json={"cuenta_recaudo": "NEW999"},
        headers={"Authorization": f"Bearer {org_token}"},
    )
    assert resp.status_code == 400

    me = client.get("/api/auth/me", headers={"Authorization": f"Bearer {get_token(client, correo)}"})
    assert me.status_code == 200


def test_audit_log_created_on_register_login_donation(client):
    from app import app
    from models import AUDITORIA, db

    correo = _new_email("aud")
    register_user(client, rol="donante", correo=correo)
    token = get_token(client, correo)

    client.post(
        "/api/donations",
        json={"id_campania": 1, "tipo": "economica", "monto_estimado": 100},
        headers={"Authorization": f"Bearer {token}"},
    )

    with app.app_context():
        acciones = {row.accion for row in AUDITORIA.query.all()}
    assert "REGISTRO" in acciones
    assert "LOGIN" in acciones
    assert "DONACION" in acciones


def test_donation_checksum_detects_tampering(client):
    correo = _new_email("chk")
    register_user(client, rol="donante", correo=correo)
    token = get_token(client, correo)

    resp = client.post(
        "/api/donations",
        json={"id_campania": 1, "tipo": "economica", "monto_estimado": 500},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 201
    donation_id = resp.get_json()["id_donacion"]
    assert resp.get_json()["checksum"] is not None

    from app import app
    from models import DONACION, db

    with app.app_context():
        row = DONACION.query.get(donation_id)
        row.monto_estimado = row.monto_estimado + 1
        db.session.commit()

    listing = client.get("/api/donations/campaign/1").get_json()
    item = next(d for d in listing if d["id_donacion"] == donation_id)
    assert item["integridad"] is False
