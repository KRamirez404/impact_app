import os

from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, SOPORTE, db
from services.campaign_service import update_campaign_status_based_on_support
from services.file_service import save_upload

support_bp = Blueprint("support_bp", __name__, url_prefix="/api/supports")


@support_bp.post("")
@jwt_required()
def create_support():
    form = request.form
    id_campania = form.get("id_campania")
    tipo = form.get("tipo")
    descripcion = form.get("descripcion")
    validado = form.get("validado", "false").lower() == "true"

    if not id_campania or not tipo:
        return jsonify({"error": "id_campania y tipo son requeridos"}), 400

    campaign = CAMPAÑA.query.get_or_404(int(id_campania))
    if campaign.id_creador != int(get_jwt_identity()):
        return jsonify({"error": "Solo el creador puede cargar soportes"}), 403

    file = request.files.get("file")
    url_o_ruta = form.get("url_o_ruta")

    if file:
        upload_path = os.path.join(current_app.root_path, current_app.config["UPLOAD_FOLDER"])
        url_o_ruta = save_upload(file, upload_path)
    elif not url_o_ruta:
        return jsonify({"error": "Debe adjuntar archivo o url_o_ruta"}), 400

    support = SOPORTE(
        id_campania=campaign.id_campania,
        tipo=tipo,
        url_o_ruta=url_o_ruta,
        descripcion=descripcion,
        validado=validado,
    )
    db.session.add(support)
    db.session.commit()

    update_campaign_status_based_on_support(campaign)
    return jsonify(support.to_dict()), 201


@support_bp.get("/campaign/<int:campaign_id>")
def get_supports(campaign_id: int):
    supports = SOPORTE.query.filter_by(id_campania=campaign_id).all()
    return jsonify([support.to_dict() for support in supports]), 200

