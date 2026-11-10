import uuid
from conftest import get_support_token, get_token, register_user


def _new_email(prefix):
    return f"{prefix}_{uuid.uuid4().hex[:8]}@test.co"


def test_organizador_can_update_social_links(client):
    correo = _new_email("org_social")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)

    payload = {
        "redes_sociales": {
            "instagram": "https://instagram.com/organizacion_social",
            "facebook": "https://facebook.com/orgsocial",
            "sitio_web": "http://mi-organizacion.org",
        }
    }
    resp = client.put(
        "/api/auth/me",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["redes_sociales"]["instagram"] == "https://instagram.com/organizacion_social"
    assert data["redes_sociales"]["facebook"] == "https://facebook.com/orgsocial"
    assert data["redes_sociales"]["sitio_web"] == "http://mi-organizacion.org"


def test_social_links_reject_invalid_schemes(client):
    correo = _new_email("org_social_bad")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)

    # Insecure / invalid scheme
    resp = client.put(
        "/api/auth/me",
        json={"redes_sociales": {"insecure": "javascript:alert(1)"}},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 400
    assert "Los enlaces sociales deben usar http o https" in resp.get_json()["error"]


def test_campaign_detail_exposes_creator_social_links(client):
    correo = _new_email("org_campaign_social")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)

    # Set social links
    client.put(
        "/api/auth/me",
        json={
            "redes_sociales": {
                "instagram": "https://instagram.com/campania_org",
            }
        },
        headers={"Authorization": f"Bearer {token}"},
    )

    # Create campaign
    camp_payload = {
        "titulo": "Campaña con redes",
        "descripcion": "Descripción detallada",
        "id_ciudad": 1,
        "id_categoria": 1,
        "tipo_ayuda_requerida": "economica",
        "meta_monetaria": 500000,
        "cuenta_recaudo": "9876543210",
        "fecha_fin": "2030-12-31",
    }
    create_resp = client.post(
        "/api/campaigns",
        json=camp_payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert create_resp.status_code == 201
    camp_id = create_resp.get_json()["id_campania"]

    # Get campaign detail as creator
    detail_resp = client.get(
        f"/api/campaigns/{camp_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert detail_resp.status_code == 200
    detail = detail_resp.get_json()
    assert "creador" in detail
    assert "redes_sociales" in detail["creador"]
    assert detail["creador"]["redes_sociales"].get("instagram") == "https://instagram.com/campania_org"


def test_direct_social_fields_validation_and_merge(client):
    correo = _new_email("org_direct_fields")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)

    # Rejection of invalid scheme in direct fields
    resp_bad = client.put(
        "/api/auth/me",
        json={"instagram_url": "ftp://bad.scheme/link"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp_bad.status_code == 400
    assert "Los enlaces sociales deben usar http o https" in resp_bad.get_json()["error"]

    # Valid direct fields
    resp_ok = client.put(
        "/api/auth/me",
        json={
            "instagram_url": "https://instagram.com/direct_org",
            "facebook_url": "https://facebook.com/direct_org",
            "tiktok_url": "https://tiktok.com/@direct_org",
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp_ok.status_code == 200
    data = resp_ok.get_json()
    assert data["instagram_url"] == "https://instagram.com/direct_org"
    assert data["redes_sociales"]["instagram"] == "https://instagram.com/direct_org"
    assert data["redes_sociales"]["facebook"] == "https://facebook.com/direct_org"
    assert data["redes_sociales"]["tiktok"] == "https://tiktok.com/@direct_org"


def test_campaign_detail_without_social_links(client):
    correo = _new_email("org_no_social")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)

    camp_payload = {
        "titulo": "Campaña sin redes",
        "descripcion": "Descripción sin redes",
        "id_ciudad": 1,
        "id_categoria": 1,
        "tipo_ayuda_requerida": "economica",
        "meta_monetaria": 200000,
        "cuenta_recaudo": "1122334455",
        "fecha_fin": "2030-12-31",
    }
    create_resp = client.post(
        "/api/campaigns",
        json=camp_payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert create_resp.status_code == 201
    camp_id = create_resp.get_json()["id_campania"]

    detail_resp = client.get(
        f"/api/campaigns/{camp_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert detail_resp.status_code == 200
    detail = detail_resp.get_json()
    assert detail["creador"]["redes_sociales"] == {}
