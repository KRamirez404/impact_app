import uuid

from conftest import get_token, register_user


def _new_email(prefix):
    return f"{prefix}_{uuid.uuid4().hex[:8]}@test.co"


def _campaign_payload(tipo="economica"):
    return {
        "titulo": "Campaña de prueba",
        "descripcion": "Descripción de la campaña",
        "id_ciudad": 1,
        "id_categoria": 1,
        "tipo_ayuda_requerida": tipo,
        "meta_monetaria": 1000000,
        "cuenta_recaudo": "1234567890",
        "fecha_fin": "2030-01-01",
    }


def test_donante_cannot_create_campaign(client):
    correo = _new_email("don")
    register_user(client, rol="donante", correo=correo)
    token = get_token(client, correo)
    resp = client.post(
        "/api/campaigns", json=_campaign_payload(),
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 403


def test_organizador_can_create_campaign(client):
    correo = _new_email("org")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)
    resp = client.post(
        "/api/campaigns", json=_campaign_payload(),
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 201
    assert resp.get_json()["estado"] == "en_verificacion"
    assert resp.get_json()["cuenta_recaudo"] == "1234567890"


def test_campaign_requires_future_end_date(client):
    correo = _new_email("org")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)
    payload = _campaign_payload()
    payload["fecha_fin"] = "2020-01-01"
    resp = client.post(
        "/api/campaigns", json=payload, headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 400


def test_organizador_cannot_donate(client):
    correo = _new_email("org")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)
    resp = client.post(
        "/api/donations",
        json={"id_campania": 1, "tipo": "economica", "monto_estimado": 1000},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 403


def test_donante_can_donate_in_kind(client):
    correo = _new_email("don")
    register_user(client, rol="donante", correo=correo)
    token = get_token(client, correo)
    resp = client.post(
        "/api/donations",
        json={"id_campania": 1, "tipo": "alimentos", "monto_estimado": 1000},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 201
    assert resp.get_json()["estado_pago"] == "aprobada"


def test_economic_donation_requires_checkout(client):
    correo = _new_email("don")
    register_user(client, rol="donante", correo=correo)
    token = get_token(client, correo)
    resp = client.post(
        "/api/donations",
        json={"id_campania": 1, "tipo": "economica", "monto_estimado": 1000},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 400


def test_anonymous_cannot_create_campaign(client):
    resp = client.post("/api/campaigns", json=_campaign_payload())
    assert resp.status_code == 401


def test_anonymous_cannot_donate(client):
    resp = client.post(
        "/api/donations",
        json={"id_campania": 1, "tipo": "economica", "monto_estimado": 1000},
    )
    assert resp.status_code == 401
