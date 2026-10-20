import hashlib
import hmac
import json
import re
import secrets
import time
import urllib.error
import urllib.request
from decimal import Decimal, InvalidOperation
from urllib.parse import quote, urlencode

from flask import current_app


STATUS_MAP = {
    "PENDING": "pendiente",
    "APPROVED": "aprobada",
    "DECLINED": "rechazada",
    "VOIDED": "anulada",
    "ERROR": "error",
}

SANDBOX_API_URL = "https://sandbox.wompi.co/v1"
PRODUCTION_API_URL = "https://production.wompi.co/v1"
OFFICIAL_CHECKOUT_URL = "https://checkout.wompi.co/p/"
ENVIRONMENT_MAP = {
    "sandbox": "test",
    "test": "test",
    "prod": "prod",
    "production": "prod",
}
ENVIRONMENT_LABELS = {"test": "sandbox", "prod": "production"}
KEY_FIELDS = (
    "WOMPI_PUBLIC_KEY",
    "WOMPI_PRIVATE_KEY",
    "WOMPI_INTEGRITY_SECRET",
    "WOMPI_EVENTS_SECRET",
)
KEY_PREFIXES = {
    "test": {
        "WOMPI_PUBLIC_KEY": "pub_test_",
        "WOMPI_PRIVATE_KEY": "prv_test_",
        "WOMPI_INTEGRITY_SECRET": "test_integrity_",
        "WOMPI_EVENTS_SECRET": "test_events_",
    },
    "prod": {
        "WOMPI_PUBLIC_KEY": "pub_prod_",
        "WOMPI_PRIVATE_KEY": "prv_prod_",
        "WOMPI_INTEGRITY_SECRET": "prod_integrity_",
        "WOMPI_EVENTS_SECRET": "prod_events_",
    },
}
MAX_AMOUNT = Decimal("9999999999.99")


class WompiQueryError(Exception):
    pass


class WompiConfigurationError(Exception):
    def __init__(self, missing=None, issues=None):
        super().__init__("configuracion_wompi_invalida")
        self.missing = list(missing or [])
        self.issues = list(issues or [])


def decimal_amount(amount) -> Decimal:
    if isinstance(amount, bool) or not isinstance(amount, (str, int, float, Decimal)):
        raise ValueError("Monto inválido")
    try:
        value = Decimal(str(amount))
        if not value.is_finite() or value <= 0 or value > MAX_AMOUNT:
            raise ValueError("Monto fuera del rango permitido")
        if value != value.quantize(Decimal("0.01")):
            raise ValueError("El monto debe tener como máximo dos decimales")
        return value
    except InvalidOperation as exc:
        raise ValueError("Monto inválido") from exc


def configuration_status() -> dict:
    config = current_app.config
    configured_keys = {
        key: str(config.get(key) or "").strip() for key in KEY_FIELDS
    }
    missing = [key for key, value in configured_keys.items() if not value]
    environment = str(config.get("WOMPI_ENV", "sandbox") or "").strip().lower()
    event_environment = ENVIRONMENT_MAP.get(environment)
    issues = []
    if event_environment is None:
        issues.append("ambiente_invalido")
    if event_environment == "prod" and not config.get("WOMPI_ALLOW_PRODUCTION", False):
        issues.append("produccion_bloqueada")
    if not missing and event_environment:
        expected_api = (
            SANDBOX_API_URL if event_environment == "test" else PRODUCTION_API_URL
        )
        for key, prefix in KEY_PREFIXES[event_environment].items():
            if not configured_keys[key].startswith(prefix):
                issues.append(f"prefijo_{key.lower()}")
        if str(config.get("WOMPI_API_URL", "")).rstrip("/") != expected_api:
            issues.append("url_api")
    if str(config.get("WOMPI_CURRENCY", "COP")).strip().upper() != "COP":
        issues.append("moneda_invalida")
    if str(config.get("WOMPI_CHECKOUT_URL", "")).rstrip("/") != OFFICIAL_CHECKOUT_URL.rstrip("/"):
        issues.append("url_checkout")
    return {
        "ok": not missing and not issues,
        "environment": ENVIRONMENT_LABELS.get(event_environment, environment or "desconocido"),
        "event_environment": event_environment,
        "missing": missing,
        "issues": issues,
    }


def is_configured() -> bool:
    return configuration_status()["ok"]


def configured_environment() -> str:
    status = configuration_status()
    return status["environment"] if status["ok"] else "sandbox"


def ensure_configured() -> None:
    status = configuration_status()
    if not status["ok"]:
        raise WompiConfigurationError(status["missing"], status["issues"])


def amount_to_cents(amount) -> int:
    return int(decimal_amount(amount) * 100)


def generate_reference(donation_id: int) -> str:
    return f"IMPACTAPP-{donation_id}-{secrets.token_hex(6)}"


def integrity_signature(
    *,
    reference: str,
    amount_in_cents: int,
    currency: str,
    integrity_secret: str,
    expiration_time: str | None = None,
) -> str:
    payload = f"{reference}{amount_in_cents}{currency}"
    if expiration_time:
        payload += expiration_time
    payload += integrity_secret
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def build_integrity_signature(
    *, reference: str, amount, expiration_time: str | None = None
) -> str:
    config = current_app.config
    return integrity_signature(
        reference=reference,
        amount_in_cents=amount_to_cents(amount),
        currency=config["WOMPI_CURRENCY"],
        integrity_secret=config["WOMPI_INTEGRITY_SECRET"],
        expiration_time=expiration_time,
    )


def build_checkout_url(
    *, reference: str, amount, customer_email: str | None = None, redirect_url: str | None = None
) -> str:
    ensure_configured()
    config = current_app.config
    params = {
        "public-key": config["WOMPI_PUBLIC_KEY"],
        "currency": config["WOMPI_CURRENCY"],
        "amount-in-cents": str(amount_to_cents(amount)),
        "reference": reference,
        "signature:integrity": build_integrity_signature(reference=reference, amount=amount),
    }
    if customer_email:
        params["customer-data:email"] = customer_email
    target_redirect = redirect_url or config.get("DONATION_REDIRECT_URL")
    if target_redirect:
        params["redirect-url"] = target_redirect
    separator = "&" if "?" in config["WOMPI_CHECKOUT_URL"] else "?"
    query = urlencode(params).replace("%3A", ":")
    return f"{config['WOMPI_CHECKOUT_URL']}{separator}{query}"


def map_status(status: str | None) -> str | None:
    if not isinstance(status, str):
        return None
    return STATUS_MAP.get(status.upper())


def _extract_value(data: dict, dotted_key: str):
    value = data
    for key in dotted_key.split("."):
        if isinstance(value, dict):
            value = value.get(key)
        else:
            return None
    return value


def compute_event_checksum(
    properties: list[str], data: dict, timestamp, secret: str
) -> str:
    parts = []
    for prop in properties:
        value = _extract_value(data, prop)
        if value is None or isinstance(value, (dict, list, bool)):
            raise ValueError("Propiedad de firma inválida")
        parts.append(str(value))
    parts.append(str(timestamp))
    parts.append(secret)
    return hashlib.sha256("".join(parts).encode("utf-8")).hexdigest()


def build_event(
    *,
    reference: str,
    status: str,
    amount_in_cents: int,
    secret: str,
    transaction_id: str | None = None,
    timestamp: int | None = None,
    environment: str = "test",
    payment_method_type: str = "CARD",
) -> dict:
    timestamp = int(timestamp if timestamp is not None else time.time())
    transaction_id = transaction_id or f"SIM-{timestamp}-{secrets.token_hex(4)}"
    properties = ["transaction.id", "transaction.status", "transaction.amount_in_cents"]
    data = {
        "transaction": {
            "id": transaction_id,
            "status": status.upper(),
            "amount_in_cents": int(amount_in_cents),
            "reference": reference,
            "currency": "COP",
            "payment_method_type": payment_method_type,
        }
    }
    checksum = compute_event_checksum(properties, data, timestamp, secret)
    return {
        "event": "transaction.updated",
        "data": data,
        "environment": environment,
        "signature": {"properties": properties, "checksum": checksum},
        "timestamp": timestamp,
    }


def verify_event_checksum(payload: dict, header_checksum: str | None = None) -> bool:
    config = current_app.config
    secret = config.get("WOMPI_EVENTS_SECRET")
    if not isinstance(payload, dict):
        return False
    signature = payload.get("signature")
    if not isinstance(signature, dict):
        return False
    checksum = signature.get("checksum") or header_checksum
    properties = signature.get("properties")
    timestamp = payload.get("timestamp")
    if (
        not secret or not isinstance(checksum, str)
        or not re.fullmatch(r"[a-fA-F0-9]{64}", checksum)
        or not isinstance(properties, list) or not properties
        or any(not isinstance(p, str) or not p for p in properties)
        or type(timestamp) is not int or timestamp < 0
        or not isinstance(payload.get("data"), dict)
    ):
        return False
    try:
        expected = compute_event_checksum(properties, payload["data"], timestamp, secret)
    except ValueError:
        return False
    return hmac.compare_digest(expected, checksum.lower())


def environment_matches(payload: dict) -> bool:
    status = configuration_status()
    return status["ok"] and status["event_environment"] == payload.get("environment")


def valid_transaction_id(transaction_id) -> bool:
    return isinstance(transaction_id, str) and bool(re.fullmatch(r"[A-Za-z0-9_-]{1,120}", transaction_id))


def fetch_transaction(transaction_id: str) -> dict:
    ensure_configured()
    config = current_app.config
    private_key = config.get("WOMPI_PRIVATE_KEY")
    if not private_key or not valid_transaction_id(transaction_id):
        raise WompiQueryError("consulta_no_configurada")
    url = f"{config['WOMPI_API_URL'].rstrip('/')}/transactions/{quote(transaction_id, safe='')}"
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {private_key}",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            body = json.loads(response.read().decode("utf-8"))
            if not isinstance(body, dict) or not isinstance(body.get("data"), dict):
                raise WompiQueryError("respuesta_invalida")
            return body["data"]
    except (urllib.error.URLError, ValueError, TimeoutError, OSError) as exc:
        raise WompiQueryError("consulta_no_disponible") from exc
