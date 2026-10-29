import hashlib
import hmac
import re

from flask import current_app

from services.transfer_errors import TransferError

try:
    from cryptography.fernet import Fernet, InvalidToken
except ImportError:  # pragma: no cover - configuration guard
    Fernet = None
    InvalidToken = Exception


def normalize_account_number(value):
    if not isinstance(value, str):
        raise TransferError("cuenta_invalida", 400, "Número de cuenta inválido")
    normalized = re.sub(r"[\s-]", "", value.strip())
    if not re.fullmatch(r"[0-9]{4,32}", normalized):
        raise TransferError("cuenta_invalida", 400, "Número de cuenta inválido")
    return normalized


def _fernet_keys():
    if Fernet is None:
        raise TransferError(
            "transfer_feature_disabled",
            503,
            "El módulo de transferencias no está disponible",
        )
    config = current_app.config
    keys = []
    for name in ("BANK_ACCOUNT_ENCRYPTION_KEY", "BANK_ACCOUNT_ENCRYPTION_KEY_OLD"):
        value = str(config.get(name) or "").strip()
        if not value:
            continue
        try:
            keys.append(Fernet(value.encode("utf-8")))
        except (ValueError, TypeError) as exc:
            raise TransferError(
                "clave_cifrado_invalida",
                503,
                "La configuración de transferencias no es válida",
            ) from exc
    if not keys:
        raise TransferError(
            "clave_cifrado_invalida",
            503,
            "La configuración de transferencias no es válida",
        )
    return keys


def encrypt_account_number(value):
    normalized = normalize_account_number(value)
    token = _fernet_keys()[0].encrypt(normalized.encode("utf-8"))
    return token.decode("ascii")


def decrypt_account_number(token):
    if not isinstance(token, str) or not token:
        raise TransferError(
            "cuenta_ilegible",
            503,
            "No fue posible leer la cuenta de recaudo",
        )
    for fernet in _fernet_keys():
        try:
            return fernet.decrypt(token.encode("ascii")).decode("utf-8")
        except (InvalidToken, ValueError, UnicodeError):
            continue
    raise TransferError(
        "cuenta_ilegible",
        503,
        "No fue posible leer la cuenta de recaudo",
    )


def hash_account_number(value):
    normalized = normalize_account_number(value)
    secret = str(current_app.config.get("BANK_ACCOUNT_HASH_KEY") or "")
    if len(secret.encode("utf-8")) < 32:
        raise TransferError(
            "clave_hash_invalida",
            503,
            "La configuración de transferencias no es válida",
        )
    return hmac.new(
        secret.encode("utf-8"),
        normalized.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def last_four(value):
    return normalize_account_number(value)[-4:]
