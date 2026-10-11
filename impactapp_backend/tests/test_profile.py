import pytest
from flask import Flask
from sqlalchemy import inspect, text

from app import app, ensure_user_schema
from conftest import get_token, register_user
from models import USUARIO, db
from services.auth_service import verify_password


def _registration(**changes):
    payload = {
        "nombre": "María Elena",
        "apellido": "Granados Meza",
        "correo": "perfil@test.co",
        "contrasena": "Passw0rd!",
        "acepta_tratamiento": True,
    }
    payload.update(changes)
    return payload


@pytest.mark.parametrize("payload", [None, [], [1], "texto", 1, False])
@pytest.mark.parametrize("endpoint", ["/api/auth/register", "/api/auth/login"])
def test_auth_rejects_non_object_json(client, payload, endpoint):
    response = client.post(endpoint, json=payload)
    assert response.status_code == 400
    assert "error" in response.get_json()


@pytest.mark.parametrize(
    "changes",
    [
        {"nombre": "   "},
        {"nombre": 123},
        {"nombre": "N" * 101},
        {"apellido": []},
        {"correo": 123},
        {"correo": "nombre con espacios@test.co"},
        {"correo": "a" * 150 + "@test.co"},
        {"contrasena": 12345678},
        {"contrasena": "A1" + "x" * 71},
        {"contrasena": "A1" + "é" * 36},
        {"telefono": {"numero": "300"}},
        {"telefono": "1" * 31},
        {"acepta_tratamiento": "false"},
        {"acepta_tratamiento": "true"},
        {"acepta_tratamiento": 1},
    ],
)
def test_register_rejects_invalid_values_without_creating_user(client, changes):
    response = client.post("/api/auth/register", json=_registration(**changes))
    assert response.status_code == 400
    assert "error" in response.get_json()
    with app.app_context():
        assert USUARIO.query.filter_by(nombre="María Elena").count() == 0
        assert USUARIO.query.filter_by(apellido="Granados Meza").count() == 0


def test_register_normalizes_fields_and_persists_only_bcrypt_hash(client):
    response = client.post(
        "/api/auth/register",
        json=_registration(nombre="  María Elena  ", correo="  PERFIL@TEST.CO  ", rol=[]),
    )
    assert response.status_code == 201
    user = response.get_json()["user"]
    assert user["nombre"] == "María Elena"
    assert user["correo"] == "perfil@test.co"
    assert user["rol"] == "donante"
    assert "contrasena" not in user
    assert "contraseña_hash" not in user
    with app.app_context():
        stored = db.session.get(USUARIO, user["id_usuario"])
        assert stored.contraseña_hash != "Passw0rd!"
        assert verify_password("Passw0rd!", stored.contraseña_hash)


@pytest.fixture()
def profile_headers(client):
    register_user(client, correo="perfil@test.co")
    return {"Authorization": f"Bearer {get_token(client, 'perfil@test.co')}"}


def test_profile_city_and_compound_names_persist_after_login(client, profile_headers):
    city = client.get("/api/cities").get_json()[0]
    response = client.put(
        "/api/auth/me",
        headers=profile_headers,
        json={
            "nombre": " María Elena ",
            "apellido": " Granados Meza ",
            "id_ciudad": city["id_ciudad"],
            "telefono": " 3001234567 ",
        },
    )
    assert response.status_code == 200
    updated = response.get_json()
    assert updated["nombre"] == "María Elena"
    assert updated["apellido"] == "Granados Meza"
    assert updated["telefono"] == "3001234567"
    assert updated["id_ciudad"] == city["id_ciudad"]
    assert updated["ciudad"]["nombre"] == city["nombre"]

    token = get_token(client, "perfil@test.co")
    current = client.get("/api/auth/me", headers={"Authorization": f"Bearer {token}"}).get_json()
    assert current["id_ciudad"] == updated["id_ciudad"]
    assert current["nombre"] == updated["nombre"]

    assert client.put("/api/auth/me", headers=profile_headers, json={"id_ciudad": None}).status_code == 200
    current = client.get("/api/auth/me", headers=profile_headers).get_json()
    assert current["id_ciudad"] is None
    assert current["ciudad"] is None


@pytest.mark.parametrize("city_id", [True, 1.5, [], "abc", -1, 999999, 2147483648])
def test_profile_rejects_invalid_city_without_partial_updates(client, profile_headers, city_id):
    response = client.put(
        "/api/auth/me", headers=profile_headers, json={"nombre": "Cambio", "id_ciudad": city_id}
    )
    assert response.status_code == 400
    current = client.get("/api/auth/me", headers=profile_headers).get_json()
    assert current["nombre"] == "Nombre"
    assert current["id_ciudad"] is None


@pytest.mark.parametrize(
    "changes",
    [
        {"nombre": " "},
        {"apellido": 123},
        {"correo": "invalido"},
        {"telefono": 123},
        {"biografia": "x" * 501},
        {"foto_perfil": []},
    ],
)
def test_profile_rejects_invalid_fields_atomically(client, profile_headers, changes):
    response = client.put(
        "/api/auth/me", headers=profile_headers, json={"nombre": "Cambio", **changes}
    )
    assert response.status_code == 400
    assert client.get("/api/auth/me", headers=profile_headers).get_json()["nombre"] == "Nombre"


def test_profile_rejects_duplicate_email(client, profile_headers):
    register_user(client, correo="otro@test.co")
    response = client.put(
        "/api/auth/me", headers=profile_headers, json={"correo": "otro@test.co"}
    )
    assert response.status_code == 400
    assert client.get("/api/auth/me", headers=profile_headers).get_json()["correo"] == "perfil@test.co"


def test_profile_rejects_non_object_json(client, profile_headers):
    response = client.put("/api/auth/me", headers=profile_headers, json=[{"nombre": "Cambio"}])
    assert response.status_code == 400


def test_user_city_schema_migration_preserves_legacy_data_and_is_idempotent(tmp_path):
    migration_app = Flask("migration_test")
    migration_app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{tmp_path / 'legacy.db'}"
    db.init_app(migration_app)
    with migration_app.app_context():
        db.session.execute(text('CREATE TABLE "CIUDAD" (id_ciudad INTEGER PRIMARY KEY)'))
        db.session.execute(text('CREATE TABLE "USUARIO" (id_usuario INTEGER PRIMARY KEY, nombre VARCHAR(100))'))
        db.session.execute(text('INSERT INTO "USUARIO" (id_usuario, nombre) VALUES (1, \'Nombre existente\')'))
        db.session.commit()

        ensure_user_schema()
        ensure_user_schema()

        columns = {column["name"] for column in inspect(db.engine).get_columns("USUARIO")}
        assert "id_ciudad" in columns
        row = db.session.execute(text('SELECT nombre, id_ciudad FROM "USUARIO"')).one()
        assert row.nombre == "Nombre existente"
        assert row.id_ciudad is None
        assert any(
            foreign_key["constrained_columns"] == ["id_ciudad"]
            for foreign_key in inspect(db.engine).get_foreign_keys("USUARIO")
        )
