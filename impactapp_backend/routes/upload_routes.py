import os
import uuid
from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
from flask_jwt_extended import jwt_required

from services.file_service import is_allowed_file

upload_bp = Blueprint("upload", __name__, url_prefix="/api/upload")

@upload_bp.route("", methods=["POST"])
@jwt_required()
def upload_file():
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400
    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400
    if file and is_allowed_file(file.filename, file.content_type):
        filename = secure_filename(file.filename)
        ext = filename.rsplit('.', 1)[1].lower() if '.' in filename else ''
        if ext == "jpeg":
            ext = "jpg"
        unique_filename = f"{uuid.uuid4().hex}.{ext}"

        upload_folder = os.path.join(current_app.root_path, current_app.config["UPLOAD_FOLDER"])
        os.makedirs(upload_folder, exist_ok=True)
        file_path = os.path.join(upload_folder, unique_filename)

        file.save(file_path)

        file_url = f"/uploads/{unique_filename}"
        return jsonify({"url": file_url}), 201

    return jsonify({"error": "File type not allowed"}), 400
