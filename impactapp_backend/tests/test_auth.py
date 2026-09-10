import uuid

from conftest import get_token, login, register_user


def test_register_success_defaults_to_donante(client):
    correo = f"ok_{uuid.uuid4().hex[:8]}@test.co"
    resp = register_user(client, rol="organizador", correo=correo)
    assert resp.status_code == 201
    body = resp.get_json()
    assert body["user"]["correo"] == correo
    assert body["user"]["rol"] == "organizador"


def test_register_forces_donante_when_soporte_autoselected(client):
    correo = f"sp_{uuid.uuid4().hex[:8]}@test.co"
    resp = register_user(client, rol="soporte", correo=correo)
    assert resp.status_code == 201
    assert resp.get_json()["user"]["rol"] == "donante"


def test_register_rejects_invalid_email(client):
    resp = register_user(client, correo="correo-invalido")
    assert resp.status_code == 400
    assert "correo" in resp.get_json()["error"].lower()


def test_register_rejects_weak_password(client):
    resp = register_user(client, contrasena="corta1")
    assert resp.status_code == 400


def test_register_requires_data_acceptance(client):
    correo = f"na_{uuid.uuid4().hex[:8]}@test.co"
    resp = register_user(client, acepta=False, correo=correo)
    assert resp.status_code == 400
    assert "tratamiento" in resp.get_json()["error"].lower()


def test_register_rejects_duplicate_email(client):
    correo = f"dup_{uuid.uuid4().hex[:8]}@test.co"
    assert register_user(client, correo=correo).status_code == 201
    resp = register_user(client, correo=correo)
    assert resp.status_code == 400
    assert "registrado" in resp.get_json()["error"]


def test_login_success_and_wrong_password(client):
    correo = f"lg_{uuid.uuid4().hex[:8]}@test.co"
    register_user(client, correo=correo)
    assert login(client, correo).status_code == 200

    wrong = login(client, correo, contrasena="WrongPass1")
    assert wrong.status_code == 401


def test_login_inactive_user_rejected(client):
    correo = f"bl_{uuid.uuid4().hex[:8]}@test.co"
    token = get_token(client, "admin@impactapp.co", "Admin123*")
    client.delete("/api/auth/me", headers={"Authorization": f"Bearer {token}"})
    resp = login(client, "admin@impactapp.co", "Admin123*")
    assert resp.status_code == 401
