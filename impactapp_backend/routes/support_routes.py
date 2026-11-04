import os

from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy.exc import SQLAlchemyError

from models import ARCHIVO, CAMPAÑA, SOPORTE, USUARIO, db
from services.campaign_service import update_campaign_status_based_on_support
from services.file_service import save_upload
from services.rate_limit import enforce, too_many_requests

support_bp = Blueprint("support_bp", __name__, url_prefix="/api/supports")


@support_bp.post("")
@jwt_required()
def create_support():
    user_id = int(get_jwt_identity())
    retry_after = enforce(
        f"upload:{user_id}",
        "RATE_LIMIT_UPLOAD_ATTEMPTS",
        "RATE_LIMIT_UPLOAD_WINDOW",
    )
    if retry_after:
        return too_many_requests(retry_after)
    form = request.form
    id_campania = form.get("id_campania")
    tipo = form.get("tipo")
    descripcion = form.get("descripcion")
    validado = False

    if not id_campania or not tipo:
        return jsonify({"error": "id_campania y tipo son requeridos"}), 400

    campaign = CAMPAÑA.query.get_or_404(int(id_campania))
    if campaign.eliminada:
        return jsonify({"error": "La campaña no está disponible"}), 404
    if campaign.id_creador != user_id:
        return jsonify({"error": "Solo el creador puede cargar soportes"}), 403

    file = request.files.get("file")
    url_o_ruta = form.get("url_o_ruta")
    uploaded_name = None
    upload_path = os.path.join(
        current_app.root_path, current_app.config["UPLOAD_FOLDER"]
    )

    if file:
        try:
            url_o_ruta = save_upload(file, upload_path)
            uploaded_name = url_o_ruta.rsplit("/", 1)[-1]
        except ValueError as exc:
            return jsonify({"error": str(exc)}), 400
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
    if uploaded_name:
        db.session.add(ARCHIVO(ruta=url_o_ruta, id_usuario=user_id))
    try:
        db.session.commit()
    except SQLAlchemyError:
        db.session.rollback()
        if uploaded_name:
            try:
                os.remove(os.path.join(upload_path, uploaded_name))
            except OSError:
                pass
        return jsonify({"error": "No fue posible registrar el soporte"}), 503

    update_campaign_status_based_on_support(campaign)
    return jsonify(support.to_dict()), 201


@support_bp.get("/campaign/<int:campaign_id>")
@jwt_required()
def get_supports(campaign_id: int):
    user_id = int(get_jwt_identity())
    user = USUARIO.query.get(user_id)
    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if user is None or user.estado != "activo":
        return jsonify({"error": "Usuario no encontrado"}), 404
    if user.rol != "soporte" and campaign.id_creador != user_id:
        return jsonify({"error": "No autorizado para ver estos soportes"}), 403
    supports = SOPORTE.query.filter_by(id_campania=campaign_id).all()
    return jsonify([support.to_dict() for support in supports]), 200
