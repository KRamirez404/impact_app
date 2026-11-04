import os
from pathlib import Path

from flask import current_app
from sqlalchemy import inspect

from models import db

TRANSFER_TABLES = {
    "CUENTA_RECAUDO": {
        "id_cuenta_recaudo",
        "id_campania",
        "banco",
        "tipo_cuenta",
        "numero_cuenta_cifrado",
        "numero_cuenta_hash",
        "ultimos4",
        "titular",
        "moneda",
        "estado",
        "clave_idempotencia",
        "huella_solicitud",
    },
    "TRANSFERENCIA_BANCARIA": {
        "id_transferencia",
        "id_donacion",
        "id_donante",
        "id_campania",
        "id_cuenta_recaudo",
        "monto_declarado",
        "moneda",
        "referencia_bancaria",
        "fecha_transferencia",
        "estado",
        "id_movimiento_bancario",
        "monto_abono",
        "fecha_abono",
        "clave_idempotencia",
        "huella_solicitud",
    },
    "COMPROBANTE_TRANSFERENCIA": {
        "id_comprobante",
        "id_transferencia",
        "version",
        "clave_almacenamiento",
        "mime",
        "tamano_bytes",
        "sha256",
        "estado_tecnico",
        "subido_por",
    },
    "TRANSFERENCIA_EVENTO": {
        "id_evento",
        "id_transferencia",
        "accion",
        "id_actor",
        "clave_idempotencia",
        "huella_solicitud",
    },
}
FINANCIAL_TABLES = {
    "ASIGNACION_FINANCIERA": {
        "id_asignacion",
        "id_usuario",
        "id_campania",
        "capacidad",
        "id_concedente",
        "fecha_concesion",
    },
    "EVENTO_ASIGNACION_FINANCIERA": {
        "id_evento",
        "id_asignacion",
        "id_actor",
        "accion",
        "clave_idempotencia",
        "huella_solicitud",
    },
}
MAX_RECEIPT_BYTES = 8 * 1024 * 1024


def _fernet_valid(value):
    if not isinstance(value, str) or not value.strip():
        return False
    try:
        from cryptography.fernet import Fernet

        Fernet(value.encode())
        return True
    except (ImportError, ValueError, TypeError):
        return False


def _path_is_private(root, upload_folder):
    root_path = Path(root).expanduser().resolve()
    upload_path = Path(upload_folder).expanduser()
    if not upload_path.is_absolute():
        upload_path = Path(current_app.root_path) / upload_path
    upload_path = upload_path.resolve()
    return (
        root_path != upload_path
        and upload_path not in root_path.parents
        and root_path not in upload_path.parents
    )


def configuration_status():
    config = current_app.config
    missing = []
    issues = []
    if not config.get("TRANSFERENCIAS_ENABLED", False):
        issues.append("transferencias_deshabilitadas")
    encryption_key = str(config.get("BANK_ACCOUNT_ENCRYPTION_KEY") or "").strip()
    old_key = str(config.get("BANK_ACCOUNT_ENCRYPTION_KEY_OLD") or "").strip()
    hash_key = str(config.get("BANK_ACCOUNT_HASH_KEY") or "").strip()
    if not encryption_key:
        missing.append("BANK_ACCOUNT_ENCRYPTION_KEY")
    elif not _fernet_valid(encryption_key):
        issues.append("clave_cifrado_invalida")
    if old_key and not _fernet_valid(old_key):
        issues.append("clave_cifrado_anterior_invalida")
    if not hash_key:
        missing.append("BANK_ACCOUNT_HASH_KEY")
    elif len(hash_key.encode("utf-8")) < 32:
        issues.append("clave_hash_debil")
    root = str(config.get("PRIVATE_STORAGE_ROOT") or "").strip()
    if not root:
        missing.append("PRIVATE_STORAGE_ROOT")
    elif not os.path.isabs(root):
        issues.append("raiz_privada_no_absoluta")
    elif not _path_is_private(root, config.get("UPLOAD_FOLDER", "uploads")):
        issues.append("raiz_privada_dentro_de_uploads")
    max_bytes = MAX_RECEIPT_BYTES
    try:
        configured_max = int(
            config.get("TRANSFER_RECEIPT_MAX_BYTES", MAX_RECEIPT_BYTES)
        )
        if configured_max <= 0:
            issues.append("limite_comprobante_invalido")
        else:
            max_bytes = min(configured_max, MAX_RECEIPT_BYTES)
    except (TypeError, ValueError):
        issues.append("limite_comprobante_invalido")
    try:
        from decimal import Decimal

        if Decimal(str(config.get("TRANSFER_MIN_AMOUNT", 1000))) <= 0:
            issues.append("monto_minimo_invalido")
    except Exception:
        issues.append("monto_minimo_invalido")

    inspector = inspect(db.engine)
    tables = set(inspector.get_table_names())
    required = dict(TRANSFER_TABLES)
    if config.get("FINANCIAL_ASSIGNMENTS_ENABLED", False):
        required.update(FINANCIAL_TABLES)
    for table, columns in required.items():
        if table not in tables:
            missing.append(table)
            continue
        existing = {column["name"] for column in inspector.get_columns(table)}
        for column in sorted(columns - existing):
            missing.append(f"{table}.{column}")

    return {
        "ok": not missing and not issues,
        "issues": issues,
        "missing": missing,
        "approval_enabled": bool(
            config.get("FINANCIAL_ASSIGNMENTS_ENABLED", False)
        ),
        "max_receipt_bytes": max_bytes,
    }
