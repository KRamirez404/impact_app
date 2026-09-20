import hashlib
import hmac
import json
import secrets
import urllib.error
import urllib.request
from urllib.parse import urlencode

from flask import current_app


STATUS_MAP = {
    "PENDING": "pendiente",
    "APPROVED": "aprobada",
    "DECLINED": "rechazada",
    "VOIDED": "anulada",
    "ERROR": "error",
}

ENVIRONMENT_MAP = {"sandbox": "test", "prod": "prod", "production": "prod"}


def is_configured() -> bool:
    config = current_app.config
    return bool(config.get("WOMPI_PUBLIC_KEY") and config.get("WOMPI_INTEGRITY_SECRET"))


def amount_to_cents(amount) -> int:
    return int(round(float(amount) * 100))


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
    if not status:
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


def verify_event_checksum(payload: dict) -> bool:
    config = current_app.config
    secret = config.get("WOMPI_EVENTS_SECRET")
    signature = payload.get("signature") or {}
    checksum = signature.get("checksum") or payload.get("X-Event-Checksum")
    properties = signature.get("properties") or []
    if not secret or not checksum:
        return False

    data = payload.get("data") or {}
    parts = []
    for prop in properties:
        value = _extract_value(data, prop)
        parts.append("" if value is None else str(value))
    parts.append(str(payload.get("timestamp", "")))
    parts.append(secret)
    expected = hashlib.sha256("".join(parts).encode("utf-8")).hexdigest()
    return hmac.compare_digest(expected.lower(), str(checksum).lower())


def environment_matches(payload: dict) -> bool:
    configured = ENVIRONMENT_MAP.get(str(current_app.config.get("WOMPI_ENV", "sandbox")).lower())
    received = payload.get("environment")
    if not configured or not received:
        return True
    return configured == received


def fetch_transaction(transaction_id: str) -> dict | None:
    config = current_app.config
    private_key = config.get("WOMPI_PRIVATE_KEY")
    if not private_key or not transaction_id:
        return None
    url = f"{config['WOMPI_API_URL']}/transactions/{transaction_id}"
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
            return body.get("data")
    except (urllib.error.URLError, urllib.error.HTTPError, ValueError, TimeoutError):
        return None
