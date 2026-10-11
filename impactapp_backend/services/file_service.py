import os
from uuid import uuid4
from xml.etree import ElementTree
from zipfile import BadZipFile, ZipFile
from zlib import error as ZlibError

import magic

from werkzeug.utils import secure_filename

ALLOWED_MIME = {
    "image/png": ".png",
    "image/jpeg": ".jpg",
    "image/gif": ".gif",
    "image/webp": ".webp",
    "image/heic": ".heic",
    "application/pdf": ".pdf",
    "application/msword": ".doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": ".docx",
}

ALLOWED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".heic", ".pdf", ".doc", ".docx"}


def _is_word_document(stream) -> bool:
    with ZipFile(stream) as archive:
        if "word/document.xml" not in archive.namelist():
            return False
        content_types = archive.getinfo("[Content_Types].xml")
        if content_types.file_size > 64 * 1024:
            return False
        root = ElementTree.fromstring(archive.read(content_types))
        namespace = "{http://schemas.openxmlformats.org/package/2006/content-types}"
        return root.tag == f"{namespace}Types" and any(
            entry.tag == f"{namespace}Override"
            and entry.get("PartName") == "/word/document.xml"
            and entry.get("ContentType")
            == "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"
            for entry in root
        )


def is_allowed_file(file_storage) -> bool:
    ext = os.path.splitext(file_storage.filename or "")[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        return False
    if ext == ".jpeg":
        ext = ".jpg"
    stream = file_storage.stream
    position = stream.tell()
    try:
        stream.seek(0)
        header = stream.read(64 * 1024)
        if not header:
            return False
        detected_mime = magic.from_buffer(header, mime=True)
        if ext == ".docx":
            if detected_mime not in {
                "application/zip",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            }:
                return False
            stream.seek(0)
            return _is_word_document(stream)
        return ALLOWED_MIME.get(detected_mime) == ext
    except (
        magic.MagicException,
        OSError,
        ValueError,
        BadZipFile,
        KeyError,
        RuntimeError,
        NotImplementedError,
        ElementTree.ParseError,
        EOFError,
        ZlibError,
    ):
        return False
    finally:
        stream.seek(position)


def save_upload(file_storage, upload_dir: str) -> str:
    if not is_allowed_file(file_storage):
        raise ValueError("El contenido del archivo no corresponde a un tipo permitido o a su extensión")
    original_name = secure_filename(file_storage.filename or "")
    extension = os.path.splitext(original_name)[1].lower() or ".bin"
    if extension == ".jpeg":
        extension = ".jpg"
    if extension not in ALLOWED_EXTENSIONS:
        raise ValueError(f"Tipo de archivo no permitido: {extension}")
    os.makedirs(upload_dir, exist_ok=True)
    filename = f"{uuid4()}{extension}"
    destination = os.path.join(upload_dir, filename)
    file_storage.stream.seek(0)
    file_storage.save(destination)
    return f"/uploads/{filename}"
