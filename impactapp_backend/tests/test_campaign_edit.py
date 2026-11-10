import uuid

from app import app
from conftest import get_token, register_user
from models import CAMPAÑA, db


def _email(prefix):
    return f"{prefix}_{uuid.uuid4().hex[:8]}@test.co"


def _campaign_payload():
    return {
        "titulo": "Campaña editable",
        "descripcion": "Descripción original",
        "id_ciudad": 1,
        "id_categoria": 1,
        "tipo_ayuda_requerida": "economica",
        "meta_monetaria": 500000,
        "fecha_fin": "2030-01-01",
        "cuenta_recaudo": "1234567890",
    }


def _create_campaign(client, estado="en_verificacion"):
    correo = _email("org")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)
    response = client.post(
        "/api/campaigns",
        json=_campaign_payload(),
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    campaign = response.get_json()
    campaign_id = campaign["id_campania"]
    if estado != "en_verificacion":
        with app.app_context():
            row = db.session.get(CAMPAÑA, campaign_id)
            row.estado = estado
            db.session.commit()
    return correo, token, campaign_id


def test_creador_actualiza_campos_descriptivos(client):
    _, token, campaign_id = _create_campaign(client, estado="en_verificacion")

    response = client.put(
        f"/api/campaigns/{campaign_id}",
        json={
            "titulo": "Título actualizado",
            "descripcion": "Descripción actualizada",
            "id_ciudad": 1,
            "id_categoria": 1,
            "tipo_ayuda_requerida": "alimentos",
            "meta_monetaria": 750000,
            "fecha_fin": "2031-05-10",
        },
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    body = response.get_json()
    assert body["titulo"] == "Título actualizado"
    assert body["descripcion"] == "Descripción actualizada"
    assert body["tipo_ayuda_requerida"] == "alimentos"
    assert body["meta_monetaria"] == 750000.0
    assert body["fecha_fin"] == "2031-05-10"


def test_cuenta_recaudo_rechazada_si_campana_activa(client):
    _, token, campaign_id = _create_campaign(client, estado="activa")

    response = client.put(
        f"/api/campaigns/{campaign_id}",
        json={"cuenta_recaudo": "999888777"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 400
    assert "cuenta de recaudo" in response.get_json()["error"].lower()


def test_cuenta_recaudo_permitida_si_campana_no_activa(client):
    _, token, campaign_id = _create_campaign(client, estado="en_verificacion")

    response = client.put(
        f"/api/campaigns/{campaign_id}",
        json={"cuenta_recaudo": "999888777"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.get_json()["cuenta_recaudo"] == "999888777"


def test_otro_organizador_recibe_403(client):
    _, _, campaign_id = _create_campaign(client)
    otro_correo = _email("org_ajeno")
    register_user(client, rol="organizador", correo=otro_correo)
    otro_token = get_token(client, otro_correo)

    response = client.put(
        f"/api/campaigns/{campaign_id}",
        json={"titulo": "Cambio no autorizado"},
        headers={"Authorization": f"Bearer {otro_token}"},
    )

    assert response.status_code == 403


def test_campana_inexistente_recibe_404(client):
    correo = _email("org")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)

    response = client.put(
        "/api/campaigns/999999",
        json={"titulo": "No existe"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 404


def test_campana_eliminada_recibe_404(client):
    _, token, campaign_id = _create_campaign(client)
    with app.app_context():
        row = db.session.get(CAMPAÑA, campaign_id)
        row.eliminada = True
        db.session.commit()

    response = client.put(
        f"/api/campaigns/{campaign_id}",
        json={"titulo": "Eliminada"},
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 404
