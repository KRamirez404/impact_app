from models import AUDITORIA, USUARIO, db

from conftest import get_support_token, register_user


def test_support_lists_users_and_blocks_with_audit(client):
    created = register_user(client, correo="donante-lista@test.co")
    user_id = created.get_json()["user"]["id_usuario"]
    token = get_support_token(client)

    response = client.get("/api/support/users", headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert any(item["id_usuario"] == user_id for item in response.get_json())

    response = client.post(
        f"/api/support/users/{user_id}/block",
        headers={"Authorization": f"Bearer {token}"},
        json={"motivo": "Actividad sospechosa"},
    )
    assert response.status_code == 200
    assert response.get_json()["estado"] == "bloqueado"
    audit = AUDITORIA.query.filter_by(accion="USUARIO_BLOQUEADO", id_entidad=user_id).first()
    assert audit is not None
    assert audit.id_usuario is not None


def test_support_unblocks_user_and_non_support_is_forbidden(client):
    created = register_user(client, correo="donante-desbloqueo@test.co")
    user_id = created.get_json()["user"]["id_usuario"]
    support_token = get_support_token(client)
    client.post(
        f"/api/support/users/{user_id}/block",
        headers={"Authorization": f"Bearer {support_token}"},
    )

    response = client.post(
        f"/api/support/users/{user_id}/unblock",
        headers={"Authorization": f"Bearer {support_token}"},
    )
    assert response.status_code == 200
    assert response.get_json()["estado"] == "activo"
    assert AUDITORIA.query.filter_by(accion="USUARIO_DESBLOQUEADO", id_entidad=user_id).first()

    user_token = client.post(
        "/api/auth/login",
        json={"correo": "donante-desbloqueo@test.co", "contrasena": "Passw0rd!"},
    ).get_json()["access_token"]
    forbidden = client.get("/api/support/users", headers={"Authorization": f"Bearer {user_token}"})
    assert forbidden.status_code == 403


def test_support_cannot_block_support_or_self(client):
    support_token = get_support_token(client)
    support_me = client.get("/api/auth/me", headers={"Authorization": f"Bearer {support_token}"}).get_json()
    my_id = support_me["id_usuario"]

    # No puede autobloquearse
    resp = client.post(
        f"/api/support/users/{my_id}/block",
        headers={"Authorization": f"Bearer {support_token}"},
        json={"motivo": "Autobloqueo"},
    )
    assert resp.status_code == 400

    # No puede bloquear a otra cuenta soporte
    other_support = register_user(client, correo="otro-soporte@test.co")
    other_id = other_support.get_json()["user"]["id_usuario"]
    with client.application.app_context():
        u = USUARIO.query.get(other_id)
        u.rol = "soporte"
        db.session.commit()
    resp2 = client.post(
        f"/api/support/users/{other_id}/block",
        headers={"Authorization": f"Bearer {support_token}"},
        json={"motivo": "Intento de bloqueo"},
    )
    assert resp2.status_code == 400


def test_blocked_user_cannot_login_or_access_protected_endpoints(client):
    created = register_user(client, rol="donante", correo="bloqueo-login@test.co")
    user_id = created.get_json()["user"]["id_usuario"]
    support_token = get_support_token(client)

    # Bloqueamos al usuario
    resp_block = client.post(
        f"/api/support/users/{user_id}/block",
        headers={"Authorization": f"Bearer {support_token}"},
        json={"motivo": "Sanción"},
    )
    assert resp_block.status_code == 200

    # Intento de login falla
    resp_login = client.post(
        "/api/auth/login",
        json={"correo": "bloqueo-login@test.co", "contrasena": "Passw0rd!"},
    )
    assert resp_login.status_code == 403 or "bloqueado" in resp_login.get_json().get("error", "").lower()

    # Intento sin token da 401
    resp_anon = client.get("/api/support/users")
    assert resp_anon.status_code == 401
