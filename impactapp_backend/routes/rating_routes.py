from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, VALORACION, db

rating_bp = Blueprint("rating_bp", __name__, url_prefix="/api/ratings")


@rating_bp.post("")
@jwt_required()
def create_rating():
    data = request.get_json() or {}
    required = ["id_campania", "calificacion"]
    missing = [field for field in required if data.get(field) is None]
    if missing:
        return jsonify({"error": f"Campos faltantes: {', '.join(missing)}"}), 400

    campaign = CAMPAÑA.query.get_or_404(data["id_campania"])
    current_user_id = int(get_jwt_identity())
    if campaign.id_creador == current_user_id:
        return jsonify({"error": "No puedes valorar tu propia campaña"}), 400

    rating = VALORACION.query.filter_by(
        id_campania=campaign.id_campania, id_usuario=current_user_id
    ).first()
    if rating:
        rating.calificacion = int(data["calificacion"])
        rating.comentario = data.get("comentario")
        rating.visible = data.get("visible", True)
    else:
        rating = VALORACION(
            id_campania=campaign.id_campania,
            id_usuario=current_user_id,
            calificacion=int(data["calificacion"]),
            comentario=data.get("comentario"),
            visible=data.get("visible", True),
        )
        db.session.add(rating)
    db.session.commit()
    return jsonify(rating.to_dict()), 201


@rating_bp.get("/campaign/<int:campaign_id>")
def list_ratings(campaign_id: int):
    ratings = VALORACION.query.filter_by(id_campania=campaign_id, visible=True).all()
    return jsonify([rating.to_dict() for rating in ratings]), 200

