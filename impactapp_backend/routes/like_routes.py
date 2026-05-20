from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, REACCION, db

like_bp = Blueprint("like_bp", __name__, url_prefix="/api/likes")


@like_bp.post("/toggle")
@jwt_required()
def toggle_like():
    data = request.get_json() or {}
    campaign_id = data.get("id_campania")
    if not campaign_id:
        return jsonify({"error": "id_campania es requerido"}), 400

    campaign = CAMPAÑA.query.get_or_404(int(campaign_id))
    user_id = int(get_jwt_identity())
    existing = REACCION.query.filter_by(
        id_campania=campaign.id_campania, id_usuario=user_id
    ).first()

    if existing:
        db.session.delete(existing)
        db.session.commit()
        liked = False
    else:
        reaction = REACCION(
            id_campania=campaign.id_campania,
            id_usuario=user_id,
        )
        db.session.add(reaction)
        db.session.commit()
        liked = True

    likes_count = REACCION.query.filter_by(id_campania=campaign.id_campania).count()
    return (
        jsonify(
            {
                "id_campania": campaign.id_campania,
                "liked": liked,
                "likes_count": likes_count,
            }
        ),
        200,
    )
