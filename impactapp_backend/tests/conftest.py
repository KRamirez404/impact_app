import os
import tempfile
from datetime import datetime
from pathlib import Path

from sqlalchemy.engine import make_url

if os.getenv("TEST_DATABASE_URL"):
    test_url = make_url(os.environ["TEST_DATABASE_URL"])
    if test_url.get_backend_name() == "sqlite":
        if test_url.database != ":memory:" and not (
            test_url.database
            and Path(test_url.database).is_absolute()
            and Path(test_url.database).resolve().is_relative_to(Path(tempfile.gettempdir()).resolve())
        ):
            raise RuntimeError("La base SQLite de pruebas debe estar aislada en el directorio temporal")
    elif test_url.get_backend_name() == "postgresql":
        if not test_url.database or not test_url.database.endswith("_test"):
            raise RuntimeError("La base PostgreSQL de pruebas debe terminar en _test")
    else:
        raise RuntimeError("Motor de pruebas no permitido")
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
from models import USUARIO, db  # noqa: E402
from services.auth_service import hash_password  # noqa: E402
from services.rate_limit import reset_rate_limits  # noqa: E402

from app import app  # noqa: E402

SUPPORT_EMAIL = "soporte@test.co"
SUPPORT_PASSWORD = "SupportPassw0rd!"


@pytest.fixture(autouse=True)
def clear_rate_limits():
    reset_rate_limits()
    yield
    reset_rate_limits()


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
        support = USUARIO(
            nombre="Soporte",
            apellido="Pruebas",
            correo=SUPPORT_EMAIL,
            contraseña_hash=hash_password(SUPPORT_PASSWORD),
            estado="activo",
            rol="soporte",
            acepta_tratamiento=True,
            fecha_aceptacion=datetime.utcnow(),
        )
        db.session.add(support)
        db.session.commit()
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


def get_support_token(client):
    return get_token(client, SUPPORT_EMAIL, SUPPORT_PASSWORD)
