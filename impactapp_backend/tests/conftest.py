import os
import tempfile

if os.getenv("TEST_DATABASE_URL"):
    os.environ["DATABASE_URL"] = os.environ["TEST_DATABASE_URL"]
else:
    _test_db = os.path.join(tempfile.gettempdir(), "impactapp_pytest.db")
    if os.path.exists(_test_db):
        os.remove(_test_db)
    os.environ["DATABASE_URL"] = f"sqlite:///{_test_db}"

import pytest  # noqa: E402

from app import (  # noqa: E402
    ensure_campaign_schema,
    ensure_donation_schema,
    ensure_user_schema,
    seed_database,
)
from models import db  # noqa: E402

from app import app  # noqa: E402


@pytest.fixture()
def client():
    app.config["TESTING"] = True
    with app.app_context():
        db.drop_all()
        db.create_all()
        ensure_user_schema()
        ensure_campaign_schema()
        ensure_donation_schema()
        seed_database()
    with app.test_client() as test_client:
        yield test_client


def register_user(client, *, rol="donante", acepta=True, correo=None, contrasena="Passw0rd!"):
    payload = {
        "nombre": "Nombre",
        "apellido": "Apellido",
        "correo": correo or f"{rol}_{os.urandom(4).hex()}@test.co",
        "contrasena": contrasena,
        "telefono": "3001234567",
        "rol": rol,
        "acepta_tratamiento": acepta,
    }
    return client.post("/api/auth/register", json=payload)


def login(client, correo, contrasena="Passw0rd!"):
    resp = client.post("/api/auth/login", json={"correo": correo, "contrasena": contrasena})
    return resp


def get_token(client, correo, contrasena="Passw0rd!"):
    return login(client, correo, contrasena).get_json()["access_token"]
