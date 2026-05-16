import os
from uuid import uuid4

from werkzeug.utils import secure_filename


def save_upload(file_storage, upload_dir: str) -> str:
    os.makedirs(upload_dir, exist_ok=True)
    original_name = secure_filename(file_storage.filename)
    extension = os.path.splitext(original_name)[1].lower()
    filename = f"{uuid4()}{extension}"
    destination = os.path.join(upload_dir, filename)
    file_storage.save(destination)
    return f"/uploads/{filename}"

