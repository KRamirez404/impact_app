import os
import secrets


def _split_env(name: str, default: str = "") -> list[str]:
    return [item.strip() for item in os.getenv(name, default).split(",") if item.strip()]


def _database_uri():
    uri = os.getenv("DATABASE_URL") or "sqlite:///impactapp.db"
    if uri.startswith("postgres://"):
        uri = uri.replace("postgres://", "postgresql+psycopg2://", 1)
    elif uri.startswith("postgresql://"):
        uri = uri.replace("postgresql://", "postgresql+psycopg2://", 1)
    return uri


class Config:
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_DATABASE_URI = _database_uri()
    SQLALCHEMY_ENGINE_OPTIONS = {"pool_pre_ping": True}
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY") or secrets.token_urlsafe(32)
    UPLOAD_FOLDER = os.getenv("UPLOAD_FOLDER", "uploads")
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024

    ALLOWED_ORIGINS = _split_env(
        "ALLOWED_ORIGINS",
        "http://localhost,http://127.0.0.1,http://10.0.2.2:5000",
    )

    WOMPI_PUBLIC_KEY = os.getenv("WOMPI_PUBLIC_KEY", "")
    WOMPI_PRIVATE_KEY = os.getenv("WOMPI_PRIVATE_KEY", "")
    WOMPI_INTEGRITY_SECRET = os.getenv("WOMPI_INTEGRITY_SECRET", "")
    WOMPI_EVENTS_SECRET = os.getenv("WOMPI_EVENTS_SECRET", "")
    WOMPI_ENV = os.getenv("WOMPI_ENV", "sandbox")
    WOMPI_CURRENCY = os.getenv("WOMPI_CURRENCY", "COP")
    WOMPI_CHECKOUT_URL = os.getenv("WOMPI_CHECKOUT_URL", "https://checkout.wompi.co/p/")
    WOMPI_API_URL = os.getenv("WOMPI_API_URL", "https://sandbox.wompi.co/v1")
    WOMPI_MIN_AMOUNT = float(os.getenv("WOMPI_MIN_AMOUNT", "1000"))
    DONATION_REDIRECT_URL = os.getenv(
        "DONATION_REDIRECT_URL", "http://localhost:8080/donacion/resultado"
    )
