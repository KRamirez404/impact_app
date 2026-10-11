import os
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required

from services.file_service import save_upload

upload_bp = Blueprint("upload", __name__, url_prefix="/api/upload")

@upload_bp.route("", methods=["POST"])
@jwt_required()
def upload_file():
    if "file" not in request.files:
        return jsonify({"error": "Debe adjuntar un archivo"}), 400
    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "Debe seleccionar un archivo"}), 400
    upload_folder = os.path.join(current_app.root_path, current_app.config["UPLOAD_FOLDER"])
    try:
        file_url = save_upload(file, upload_folder)
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400
    return jsonify({"url": file_url}), 201
