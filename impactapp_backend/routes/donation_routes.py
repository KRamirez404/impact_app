from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, DONACION, PUNTO_RECOLECCION, db
from services.campaign_service import recalculate_campaign_progress

donation_bp = Blueprint("donation_bp", __name__, url_prefix="/api/donations")


@donation_bp.post("")
@jwt_required()
def create_donation():
    data = request.get_json() or {}
    required = ["id_campania", "tipo"]
    missing = [field for field in required if not data.get(field)]
    if missing:
        return jsonify({"error": f"Campos faltantes: {', '.join(missing)}"}), 400

    campaign = CAMPAÑA.query.get_or_404(data["id_campania"])
    point_id = data.get("id_punto")
    if point_id:
        point = PUNTO_RECOLECCION.query.get(point_id)
        if not point or point.id_campania != campaign.id_campania:
            return jsonify({"error": "Punto de recolección inválido para esta campaña"}), 400

    donation = DONACION(
        id_campania=campaign.id_campania,
        id_donante=int(get_jwt_identity()),
        id_punto=point_id,
        tipo=data["tipo"],
        monto_estimado=data.get("monto_estimado", 0),
        descripcion=data.get("descripcion"),
    )
    db.session.add(donation)
    db.session.commit()

    if donation.tipo == "economica":
        recalculate_campaign_progress(campaign)

    return jsonify(donation.to_dict()), 201


@donation_bp.get("/campaign/<int:campaign_id>")
def get_campaign_donations(campaign_id: int):
    donations = DONACION.query.filter_by(id_campania=campaign_id).all()
    return jsonify([donation.to_dict() for donation in donations]), 200


@donation_bp.get("/mine")
@jwt_required()
def get_my_donations():
    current_user_id = int(get_jwt_identity())
    donations = (
        DONACION.query.filter_by(id_donante=current_user_id)
        .order_by(DONACION.fecha_donacion.desc())
        .all()
    )
    payload = []
    for donation in donations:
        data = donation.to_dict()
        campaign = donation.campania
        data["campania"] = {
            "id_campania": donation.id_campania,
            "titulo": campaign.titulo if campaign else "",
            "estado": campaign.estado if campaign else "",
            "fecha_fin": campaign.fecha_fin.isoformat() if campaign else "",
        }
        payload.append(data)
    return jsonify(payload), 200
