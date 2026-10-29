from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, PUNTO_RECOLECCION, db
from services.authorization import current_user, puede_ver_campania

collection_point_bp = Blueprint(
    "collection_point_bp", __name__, url_prefix="/api/collection-points"
)


@collection_point_bp.get("/campaign/<int:campaign_id>")
@jwt_required(optional=True)
def list_collection_points(campaign_id: int):
    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if not puede_ver_campania(campaign, current_user()):
        return jsonify({"error": "Campaña no encontrada"}), 404
    points = PUNTO_RECOLECCION.query.filter_by(id_campania=campaign_id).all()
    return jsonify([point.to_dict() for point in points]), 200


@collection_point_bp.post("")
@jwt_required()
def create_collection_point():
    data = request.get_json() or {}
    required = ["id_campania", "id_ciudad", "nombre", "direccion", "horario", "contacto"]
    missing = [field for field in required if not data.get(field)]
    if missing:
        return jsonify({"error": f"Campos faltantes: {', '.join(missing)}"}), 400

    campaign = CAMPAÑA.query.get_or_404(int(data["id_campania"]))
    if campaign.id_creador != int(get_jwt_identity()):
        return jsonify({"error": "Solo el creador de la campaña puede crear puntos de recolección"}), 403

    point = PUNTO_RECOLECCION(
        id_campania=data["id_campania"],
        id_ciudad=data["id_ciudad"],
        nombre=data["nombre"],
        direccion=data["direccion"],
        horario=data["horario"],
        contacto=data["contacto"],
    )
    db.session.add(point)
    db.session.commit()
    return jsonify(point.to_dict()), 201

