from datetime import datetime

from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, USUARIO, db

support_panel_bp = Blueprint("support_panel_bp", __name__, url_prefix="/api/support")


def _require_support_user():
    user_id = int(get_jwt_identity())
    user = USUARIO.query.get_or_404(user_id)
    if user.rol != "soporte":
        return None, (jsonify({"error": "Acceso denegado"}), 403)
    return user, None


@support_panel_bp.get("/summary")
@jwt_required()
def support_summary():
    _, error = _require_support_user()
    if error:
        return error

    pending = CAMPAÑA.query.filter_by(estado="en_verificacion").count()
    approved = CAMPAÑA.query.filter_by(estado="activa").count()
    rejected = CAMPAÑA.query.filter_by(estado="pausada").count()
    return (
        jsonify(
            {
                "pendientes": pending,
                "aprobadas": approved,
                "rechazadas": rejected,
            }
        ),
        200,
    )


@support_panel_bp.get("/campaigns")
@jwt_required()
def list_support_campaigns():
    _, error = _require_support_user()
    if error:
        return error

    estado = request.args.get("estado")
    if estado == "rechazada":
        estado = "pausada"

    query = CAMPAÑA.query
    if estado:
        query = query.filter(CAMPAÑA.estado == estado)

    campaigns = query.order_by(CAMPAÑA.id_campania.desc()).all()
    payload = []
    for campaign in campaigns:
        data = campaign.to_dict(include_relations=True)
        data["soportes"] = [support.to_dict() for support in campaign.soportes]
        payload.append(data)
    return jsonify(payload), 200


@support_panel_bp.post("/campaigns/<int:campaign_id>/approve")
@jwt_required()
def approve_campaign(campaign_id: int):
    user, error = _require_support_user()
    if error:
        return error

    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    data = request.get_json() or {}
    note = (data.get("nota_revision") or data.get("nota") or "").strip()

    campaign.estado = "activa"
    campaign.nota_revision = note or None
    campaign.fecha_revision = datetime.utcnow()
    campaign.id_auditor = user.id_usuario
    for support in campaign.soportes:
        support.validado = True

    db.session.commit()
    return jsonify(campaign.to_dict(include_relations=True)), 200


@support_panel_bp.post("/campaigns/<int:campaign_id>/reject")
@jwt_required()
def reject_campaign(campaign_id: int):
    user, error = _require_support_user()
    if error:
        return error

    data = request.get_json() or {}
    note = (data.get("nota_revision") or data.get("nota") or "").strip()
    if not note:
        return jsonify({"error": "La nota de rechazo es requerida"}), 400

    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    campaign.estado = "pausada"
    campaign.nota_revision = note
    campaign.fecha_revision = datetime.utcnow()
    campaign.id_auditor = user.id_usuario
    for support in campaign.soportes:
        support.validado = False

    db.session.commit()
    return jsonify(campaign.to_dict(include_relations=True)), 200
