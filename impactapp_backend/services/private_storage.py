import hashlib
import os
import secrets
from dataclasses import dataclass
from pathlib import Path

import magic
from flask import current_app

from services.transfer_config import MAX_RECEIPT_BYTES
from services.transfer_errors import TransferError

ALLOWED = {
    ".pdf": "application/pdf",
    ".jpg": "image/jpeg",
    ".png": "image/png",
}


@dataclass(frozen=True)
class ReceiptData:
    data: bytes
    extension: str
    mime: str
    sha256: str
    size: int


def _max_bytes():
    configured = current_app.config.get("TRANSFER_RECEIPT_MAX_BYTES", MAX_RECEIPT_BYTES)
    try:
        value = int(configured)
    except (TypeError, ValueError):
        value = MAX_RECEIPT_BYTES
    return min(max(value, 1), MAX_RECEIPT_BYTES)


def _extension(filename):
    extension = os.path.splitext(filename or "")[1].lower()
    if extension == ".jpeg":
        extension = ".jpg"
    if extension not in ALLOWED:
        raise TransferError(
            "receipt_invalid_type",
            415,
            "El comprobante debe ser PDF, JPEG o PNG",
        )
    return extension


def _structural_check(extension, data):
    if extension == ".pdf":
        return data.startswith(b"%PDF-") and b"%%EOF" in data[-2048:]
    if extension == ".jpg":
        return data.startswith(b"\xff\xd8\xff") and data.rstrip().endswith(b"\xff\xd9")
    if extension == ".png":
        return data.startswith(b"\x89PNG\r\n\x1a\n") and b"IEND" in data[-64:]
    return False


def read_receipt(file_storage) -> ReceiptData:
    extension = _extension(file_storage.filename)
    limit = _max_bytes()
    try:
        data = file_storage.read(limit + 1)
    except (OSError, ValueError) as exc:
        raise TransferError(
            "receipt_invalid_content",
            400,
            "No fue posible leer el comprobante",
        ) from exc
    if not data:
        raise TransferError(
            "receipt_invalid_content",
            400,
            "El comprobante está vacío",
        )
    if len(data) > limit:
        raise TransferError(
            "receipt_too_large",
            413,
            "El comprobante supera el tamaño permitido",
        )
    try:
        detected = magic.from_buffer(data[:65536], mime=True)
    except magic.MagicException as exc:
        raise TransferError(
            "receipt_invalid_content",
            400,
            "No fue posible validar el comprobante",
        ) from exc
    expected = ALLOWED[extension]
    if detected != expected or not _structural_check(extension, data):
        raise TransferError(
            "receipt_invalid_type",
            415,
            "El contenido del comprobante no corresponde al tipo permitido",
        )
    return ReceiptData(
        data=data,
        extension=extension,
        mime=expected,
        sha256=hashlib.sha256(data).hexdigest(),
        size=len(data),
    )


def _root():
    configured = str(current_app.config.get("PRIVATE_STORAGE_ROOT") or "").strip()
    if not configured or not os.path.isabs(configured):
        raise TransferError(
            "receipt_storage_unavailable",
            503,
            "El almacenamiento privado no está disponible",
        )
    root = Path(configured).resolve()
    try:
        root.mkdir(mode=0o700, parents=True, exist_ok=True)
        os.chmod(root, 0o700)
    except OSError as exc:
        raise TransferError(
            "receipt_storage_unavailable",
            503,
            "El almacenamiento privado no está disponible",
        ) from exc
    return root


def store_receipt(receipt: ReceiptData, id_transferencia: int) -> str:
    root = _root()
    directory = root / f"transfer_{int(id_transferencia)}"
    try:
        if directory.is_symlink():
            raise OSError("directorio simbólico")
        directory.mkdir(mode=0o700, exist_ok=True)
        os.chmod(directory, 0o700)
        if (
            directory.is_symlink()
            or not directory.resolve().is_relative_to(root)
            or not directory.is_dir()
        ):
            raise OSError("directorio no seguro")
    except OSError as exc:
        raise TransferError(
            "receipt_storage_unavailable",
            503,
            "El almacenamiento privado no está disponible",
        ) from exc
    filename = f"{secrets.token_hex(24)}{receipt.extension}"
    temporary = directory / f".{filename}.tmp"
    final = directory / filename
    descriptor = None
    try:
        descriptor = os.open(
            temporary,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL,
            0o600,
        )
        with os.fdopen(descriptor, "wb") as handle:
            descriptor = None
            handle.write(receipt.data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, final)
        os.chmod(final, 0o600)
    except OSError as exc:
        for path in (temporary, final):
            try:
                path.unlink()
            except OSError:
                pass
        raise TransferError(
            "receipt_storage_unavailable",
            503,
            "El almacenamiento privado no está disponible",
        ) from exc
    finally:
        if descriptor is not None:
            os.close(descriptor)
    return f"transfer_{int(id_transferencia)}/{filename}"


def resolve_receipt(key):
    if not isinstance(key, str) or not key or "\x00" in key:
        raise TransferError("receipt_not_found", 404, "Comprobante no encontrado")
    root = _root()
    candidate = (root / key).resolve()
    if (
        not candidate.is_relative_to(root)
        or candidate.is_symlink()
        or not candidate.is_file()
    ):
        raise TransferError("receipt_not_found", 404, "Comprobante no encontrado")
    return candidate


def delete_receipt(key):
    try:
        path = resolve_receipt(key)
    except TransferError:
        return
    try:
        path.unlink()
    except OSError:
        pass
