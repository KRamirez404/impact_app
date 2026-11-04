import uuid

import pytest

from app import app
from conftest import get_support_token, get_token, register_user
from models import CAMPAÑA, USUARIO, db


def _email(prefix):
    return f"{prefix}_{uuid.uuid4().hex[:8]}@test.co"


def _campaign_payload():
    return {
        "titulo": "Campaña de visibilidad",
        "descripcion": "Descripción pública",
        "id_ciudad": 1,
        "id_categoria": 1,
        "tipo_ayuda_requerida": "economica",
        "meta_monetaria": 500000,
        "fecha_fin": "2030-01-01",
    }


def _create_campaign(client, estado="activa", eliminada=False):
    correo = _email("org")
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)
    response = client.post(
        "/api/campaigns",
        json=_campaign_payload(),
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    campaign_id = response.get_json()["id_campania"]
    with app.app_context():
        campaign = db.session.get(CAMPAÑA, campaign_id)
        campaign.estado = estado
        campaign.eliminada = eliminada
        db.session.commit()
    return correo, token, campaign_id


def _donor_token(client, prefix="don"):
    correo = _email(prefix)
    register_user(client, rol="donante", correo=correo)
    return correo, get_token(client, correo)


@pytest.mark.parametrize(
    "estado,visible",
    [
        ("activa", True),
        ("finalizada", True),
        ("en_verificacion", False),
        ("pausada", False),
    ],
)
def test_listado_publico_solo_expone_estados_publicos(client, estado, visible):
    _, _, campaign_id = _create_campaign(client, estado=estado)

    response = client.get("/api/campaigns")

    assert response.status_code == 200
    ids = [item["id_campania"] for item in response.get_json()]
    assert (campaign_id in ids) is visible


def test_listado_rechaza_filtro_por_estado_privado(client):
    _create_campaign(client, estado="activa")

    response = client.get("/api/campaigns?estado=en_verificacion")

    assert response.status_code == 400


def test_listado_permite_filtro_por_estado_publico(client):
    _, _, active_id = _create_campaign(client, estado="activa")
    _, _, paused_id = _create_campaign(client, estado="pausada")

    response = client.get("/api/campaigns?estado=activa")

    assert response.status_code == 200
    ids = [item["id_campania"] for item in response.get_json()]
    assert active_id in ids
    assert paused_id not in ids


@pytest.mark.parametrize(
    "estado,esperado",
    [
        ("activa", 200),
        ("finalizada", 200),
        ("en_verificacion", 404),
        ("pausada", 404),
    ],
)
def test_detalle_anonimo_respeta_estado(client, estado, esperado):
    _, _, campaign_id = _create_campaign(client, estado=estado)

    response = client.get(f"/api/campaigns/{campaign_id}")

    assert response.status_code == esperado


def test_detalle_privado_accesible_para_creador_y_soporte(client):
    _, owner_token, campaign_id = _create_campaign(client, estado="en_verificacion")
    _, other_token = _donor_token(client, "otro")
    support_token = get_support_token(client)

    owner = client.get(
        f"/api/campaigns/{campaign_id}",
        headers={"Authorization": f"Bearer {owner_token}"},
    )
    other = client.get(
        f"/api/campaigns/{campaign_id}",
        headers={"Authorization": f"Bearer {other_token}"},
    )
    support = client.get(
        f"/api/campaigns/{campaign_id}",
        headers={"Authorization": f"Bearer {support_token}"},
    )

    assert owner.status_code == 200
    assert other.status_code == 404
    assert support.status_code == 200


def test_campana_eliminada_solo_es_visible_para_soporte(client):
    _, owner_token, campaign_id = _create_campaign(
        client, estado="activa", eliminada=True
    )
    support_token = get_support_token(client)

    assert client.get(f"/api/campaigns/{campaign_id}").status_code == 404
    assert (
        client.get(
            f"/api/campaigns/{campaign_id}",
            headers={"Authorization": f"Bearer {owner_token}"},
        ).status_code
        == 404
    )
    assert (
        client.get(
            f"/api/campaigns/{campaign_id}",
            headers={"Authorization": f"Bearer {support_token}"},
        ).status_code
        == 200
    )
    assert campaign_id not in [
        item["id_campania"] for item in client.get("/api/campaigns").get_json()
    ]


@pytest.mark.parametrize(
    "path",
    [
        "/api/donations/campaign/{id}",
        "/api/tracking/campaign/{id}",
        "/api/collection-points/campaign/{id}",
        "/api/ratings/campaign/{id}",
    ],
)
def test_subrecursos_publicos_respetan_visibilidad(client, path):
    _, owner_token, private_id = _create_campaign(client, estado="en_verificacion")
    _, _, active_id = _create_campaign(client, estado="activa")
    _, other_token = _donor_token(client, "otro")

    private_path = path.format(id=private_id)
    active_path = path.format(id=active_id)

    assert client.get(private_path).status_code == 404
    assert (
        client.get(
            private_path, headers={"Authorization": f"Bearer {other_token}"}
        ).status_code
        == 404
    )
    assert (
        client.get(
            private_path, headers={"Authorization": f"Bearer {owner_token}"}
        ).status_code
        == 200
    )
    assert client.get(active_path).status_code == 200


@pytest.mark.parametrize(
    "estado,esperado",
    [
        ("activa", 201),
        ("finalizada", 404),
        ("en_verificacion", 404),
        ("pausada", 404),
    ],
)
def test_donacion_en_especie_solo_en_campana_activa(client, estado, esperado):
    _, _, campaign_id = _create_campaign(client, estado=estado)
    _, donor_token = _donor_token(client)

    response = client.post(
        "/api/donations",
        json={
            "id_campania": campaign_id,
            "tipo": "alimentos",
            "monto_estimado": 0,
            "descripcion": "Aporte de prueba",
        },
        headers={"Authorization": f"Bearer {donor_token}"},
    )

    assert response.status_code == esperado


def test_token_de_usuario_bloqueado_no_opera(client):
    correo = _email("bloqueado")
    register_user(client, rol="donante", correo=correo)
    token = get_token(client, correo)
    with app.app_context():
        user = USUARIO.query.filter_by(correo=correo).one()
        user.estado = "bloqueado"
        db.session.commit()

    response = client.get(
        "/api/donations/mine", headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 401


def test_token_tras_supresion_de_cuenta_no_opera(client):
    correo = _email("eliminado")
    register_user(client, rol="donante", correo=correo)
    token = get_token(client, correo)

    assert (
        client.delete(
            "/api/auth/me", headers={"Authorization": f"Bearer {token}"}
        ).status_code
        == 200
    )
    response = client.get(
        "/api/donations/mine", headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 401


def test_soportes_de_campana_privada_solo_para_creador_o_soporte(client):
    _, owner_token, campaign_id = _create_campaign(client, estado="en_verificacion")
    _, donor_token = _donor_token(client)

    assert (
        client.get(f"/api/supports/campaign/{campaign_id}").status_code == 401
    )
    assert (
        client.get(
            f"/api/supports/campaign/{campaign_id}",
            headers={"Authorization": f"Bearer {donor_token}"},
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
