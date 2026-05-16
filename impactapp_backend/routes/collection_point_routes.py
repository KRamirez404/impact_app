from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required

from models import PUNTO_RECOLECCION, db

collection_point_bp = Blueprint(
    "collection_point_bp", __name__, url_prefix="/api/collection-points"
)


@collection_point_bp.get("/campaign/<int:campaign_id>")
def list_collection_points(campaign_id: int):
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

