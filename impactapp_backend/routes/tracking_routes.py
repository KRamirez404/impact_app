from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, SEGUIMIENTO, db

tracking_bp = Blueprint("tracking_bp", __name__, url_prefix="/api/tracking")


@tracking_bp.post("")
@jwt_required()
def create_tracking():
    data = request.get_json() or {}
    required = ["id_campania", "descripcion", "porcentaje_avance"]
    missing = [field for field in required if data.get(field) is None]
    if missing:
        return jsonify({"error": f"Campos faltantes: {', '.join(missing)}"}), 400

    campaign = CAMPAÑA.query.get_or_404(data["id_campania"])
    if campaign.id_creador != int(get_jwt_identity()):
        return jsonify({"error": "Solo el creador puede agregar seguimientos"}), 403

    tracking = SEGUIMIENTO(
        id_campania=campaign.id_campania,
        descripcion=data["descripcion"],
        porcentaje_avance=data["porcentaje_avance"],
        evidencia_url=data.get("evidencia_url"),
    )
    db.session.add(tracking)
    db.session.commit()
    return jsonify(tracking.to_dict()), 201


@tracking_bp.get("/campaign/<int:campaign_id>")
def list_tracking(campaign_id: int):
    records = SEGUIMIENTO.query.filter_by(id_campania=campaign_id).all()
    return jsonify([record.to_dict() for record in records]), 200

