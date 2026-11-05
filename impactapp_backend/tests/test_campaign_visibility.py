import uuid

import pytest

from app import app
from conftest import get_support_token, get_token, register_user
from models import CAMPAÑA, DONACION, SOPORTE, USUARIO, db


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


def _agregar_soportes(campaign_id):
    rutas = {
        "documento": f"/uploads/{uuid.uuid4().hex}.pdf",
        "certificado": f"/uploads/{uuid.uuid4().hex}.pdf",
        "foto_validada": f"/uploads/{uuid.uuid4().hex}.jpg",
        "foto_pendiente": f"/uploads/{uuid.uuid4().hex}.jpg",
    }
    with app.app_context():
        db.session.add_all([
            SOPORTE(id_campania=campaign_id, tipo="documento_oficial",
                    url_o_ruta=rutas["documento"], validado=True),
            SOPORTE(id_campania=campaign_id, tipo="certificado_institucional",
                    url_o_ruta=rutas["certificado"], validado=False),
            SOPORTE(id_campania=campaign_id, tipo="foto",
                    url_o_ruta=rutas["foto_validada"], validado=True),
            SOPORTE(id_campania=campaign_id, tipo="foto",
                    url_o_ruta=rutas["foto_pendiente"], validado=False),
        ])
        db.session.commit()
    return rutas


def _donar_en_especie(client, campaign_id, token):
    response = client.post(
        "/api/donations",
        json={"id_campania": campaign_id, "tipo": "alimentos", "descripcion": "Mercado"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    return response.get_json()["id_donacion"]


def test_mis_donaciones_no_expone_soportes_privados(client):
    _, _, campaign_id = _create_campaign(client, estado="activa")
    rutas = _agregar_soportes(campaign_id)
    _, donor_token = _donor_token(client)
    _donar_en_especie(client, campaign_id, donor_token)

    response = client.get(
        "/api/donations/mine", headers={"Authorization": f"Bearer {donor_token}"}
    )

    assert response.status_code == 200
    cuerpo = response.get_data(as_text=True)
    for clave in ("documento", "certificado", "foto_pendiente"):
        assert rutas[clave] not in cuerpo
    soportes = response.get_json()[0]["campania"]["soportes"]
    assert all("id_soporte" not in s and "id_campania" not in s for s in soportes)
    assert all(s["validado"] for s in soportes)
    assert [s.get("url_o_ruta") for s in soportes if s.get("url_o_ruta")] == [
        rutas["foto_validada"]
    ]
    documento = next(s for s in soportes if s["tipo"] == "documento_oficial")
    assert "url_o_ruta" not in documento


def test_donante_no_accede_a_documentos_privados_manipulando_identificadores(client):
    _, owner_token, campaign_id = _create_campaign(client, estado="activa")
    rutas = _agregar_soportes(campaign_id)
    _, donor_token = _donor_token(client)
    _, other_token = _donor_token(client, "otro")
    _donar_en_especie(client, campaign_id, donor_token)
    donor_headers = {"Authorization": f"Bearer {donor_token}"}

    assert client.get(
        f"/api/supports/campaign/{campaign_id}", headers=donor_headers
    ).status_code == 403
    for clave in ("documento", "certificado"):
        assert client.get(rutas[clave]).status_code == 401
        assert client.get(rutas[clave], headers=donor_headers).status_code == 404
    owner = client.get(
        f"/api/supports/campaign/{campaign_id}",
        headers={"Authorization": f"Bearer {owner_token}"},
    )
    assert owner.status_code == 200
    assert rutas["documento"] in owner.get_data(as_text=True)
    ajenas = client.get(
        "/api/donations/mine",
        headers={"Authorization": f"Bearer {other_token}"},
        query_string={"id_donante": 1, "id_campania": campaign_id},
    )
    assert ajenas.status_code == 200
    assert ajenas.get_json() == []


def _registrar_donacion(campaign_id, correo_donante, estado_pago):
    with app.app_context():
        donante = USUARIO.query.filter_by(correo=correo_donante).one()
        db.session.add(DONACION(
            id_campania=campaign_id, id_donante=donante.id_usuario,
            tipo="economica", monto_estimado=10000, estado_pago=estado_pago,
        ))
        db.session.commit()


def _eliminar(client, campaign_id, token):
    return client.delete(
        f"/api/campaigns/{campaign_id}",
        json={"motivo": "Prueba"},
        headers={"Authorization": f"Bearer {token}"},
    )


def _esta_eliminada(campaign_id):
    with app.app_context():
        return db.session.get(CAMPAÑA, campaign_id).eliminada


def test_organizador_elimina_campania_sin_donaciones(client):
    _, owner_token, campaign_id = _create_campaign(client, estado="activa")

    response = _eliminar(client, campaign_id, owner_token)

    assert response.status_code == 200
    assert _esta_eliminada(campaign_id) is True


@pytest.mark.parametrize("estado_pago", ["rechazada", "anulada", "error"])
def test_organizador_elimina_campania_con_donaciones_no_procesadas(client, estado_pago):
    _, owner_token, campaign_id = _create_campaign(client, estado="activa")
    correo, _ = _donor_token(client)
    _registrar_donacion(campaign_id, correo, estado_pago)

    response = _eliminar(client, campaign_id, owner_token)

    assert response.status_code == 200
    assert _esta_eliminada(campaign_id) is True


def test_organizador_no_elimina_campania_con_donacion_pendiente(client):
    _, owner_token, campaign_id = _create_campaign(client, estado="activa")
    correo, _ = _donor_token(client)
    _registrar_donacion(campaign_id, correo, "pendiente")

    response = _eliminar(client, campaign_id, owner_token)

    assert response.status_code == 409
    assert "en proceso" in response.get_json()["error"]
    assert _esta_eliminada(campaign_id) is False


@pytest.mark.parametrize("via", ["especie", "economica_aprobada"])
def test_organizador_no_elimina_campania_con_donacion_procesada(client, via):
    _, owner_token, campaign_id = _create_campaign(client, estado="activa")
    correo, donor_token = _donor_token(client)
    if via == "especie":
        _donar_en_especie(client, campaign_id, donor_token)
    else:
        _registrar_donacion(campaign_id, correo, "aprobada")

    response = _eliminar(client, campaign_id, owner_token)

    assert response.status_code == 409
    assert "procesadas" in response.get_json()["error"]
    assert _esta_eliminada(campaign_id) is False


def test_eliminacion_mantiene_reglas_de_propiedad_y_rol(client):
    _, _, campaign_id = _create_campaign(client, estado="activa")
    correo, donor_token = _donor_token(client)
    _registrar_donacion(campaign_id, correo, "aprobada")
    otro_correo = _email("org_ajeno")
    register_user(client, rol="organizador", correo=otro_correo)
    otro_token = get_token(client, otro_correo)

    assert _eliminar(client, campaign_id, otro_token).status_code == 403
    assert _eliminar(client, campaign_id, donor_token).status_code == 403
    assert client.delete(f"/api/campaigns/{campaign_id}").status_code == 401
    assert _esta_eliminada(campaign_id) is False
