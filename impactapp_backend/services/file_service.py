import os
from uuid import uuid4

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


def is_allowed_file(filename: str, content_type: str | None = None) -> bool:
    ext = os.path.splitext(filename)[1].lower() or (".jpg" if content_type == "image/jpeg" else "")
    if ext not in ALLOWED_EXTENSIONS:
        return False
    if content_type and content_type in ALLOWED_MIME:
        mime_ext = ALLOWED_MIME[content_type]
        if ext in {".jpg", ".jpeg"} and mime_ext == ".jpg":
            return True
        return ext == mime_ext
    return True


def save_upload(file_storage, upload_dir: str) -> str:
    os.makedirs(upload_dir, exist_ok=True)
    original_name = secure_filename(file_storage.filename or "")
    extension = os.path.splitext(original_name)[1].lower() or ".bin"
    if extension == ".jpeg":
        extension = ".jpg"
    if extension not in ALLOWED_EXTENSIONS:
        raise ValueError(f"Tipo de archivo no permitido: {extension}")
    filename = f"{uuid4()}{extension}"
    destination = os.path.join(upload_dir, filename)
    file_storage.save(destination)
    return f"/uploads/{filename}"