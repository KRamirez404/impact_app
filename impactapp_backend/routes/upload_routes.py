import os

from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy.exc import SQLAlchemyError

from models import ARCHIVO, db
from services.file_service import save_upload
from services.rate_limit import enforce, too_many_requests

upload_bp = Blueprint("upload", __name__, url_prefix="/api/upload")


@upload_bp.route("", methods=["POST"])
@jwt_required()
def upload_file():
    user_id = int(get_jwt_identity())
    retry_after = enforce(
        f"upload:{user_id}",
        "RATE_LIMIT_UPLOAD_ATTEMPTS",
        "RATE_LIMIT_UPLOAD_WINDOW",
    )
    if retry_after:
        return too_many_requests(retry_after)
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
    try:
        db.session.add(ARCHIVO(ruta=file_url, id_usuario=user_id))
        db.session.commit()
    except SQLAlchemyError:
        db.session.rollback()
        try:
            os.remove(os.path.join(upload_folder, file_url.rsplit("/", 1)[-1]))
        except OSError:
            pass
        return jsonify({"error": "No fue posible registrar el archivo"}), 503
    return jsonify({"url": file_url}), 201
