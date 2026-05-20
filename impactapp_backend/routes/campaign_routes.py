from datetime import datetime

from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, CATEGORIA, CIUDAD, DONACION, REACCION, db

campaign_bp = Blueprint("campaign_bp", __name__, url_prefix="/api")


@campaign_bp.get("/cities")
def list_cities():
    cities = CIUDAD.query.order_by(CIUDAD.nombre.asc()).all()
    return jsonify([city.to_dict() for city in cities]), 200


@campaign_bp.get("/categories")
def list_categories():
    categories = CATEGORIA.query.order_by(CATEGORIA.nombre.asc()).all()
    return jsonify([category.to_dict() for category in categories]), 200


@campaign_bp.get("/campaigns")
def list_campaigns():
    query = CAMPAÑA.query
    ciudad = request.args.get("ciudad")
    categoria = request.args.get("categoria")
    tipo_ayuda = request.args.get("tipo_ayuda")
    estado = request.args.get("estado")

    if ciudad:
        query = query.filter(CAMPAÑA.id_ciudad == int(ciudad))
    if categoria:
        query = query.filter(CAMPAÑA.id_categoria == int(categoria))
    if tipo_ayuda:
        query = query.filter(CAMPAÑA.tipo_ayuda_requerida == tipo_ayuda)
    if estado:
        query = query.filter(CAMPAÑA.estado == estado)

    campaigns = query.order_by(CAMPAÑA.id_campania.desc()).all()
    payload = []
    for campaign in campaigns:
        data = campaign.to_dict(include_relations=True)
        data["donantes_count"] = (
            db.session.query(db.func.count(db.distinct(DONACION.id_donante)))
            .filter(DONACION.id_campania == campaign.id_campania)
            .scalar()
            or 0
        )
        payload.append(data)
    return jsonify(payload), 200


@campaign_bp.get("/campaigns/mine")
@jwt_required()
def list_my_campaigns():
    current_user_id = int(get_jwt_identity())
    campaigns = (
        CAMPAÑA.query.filter(CAMPAÑA.id_creador == current_user_id)
        .order_by(CAMPAÑA.id_campania.desc())
        .all()
    )
    return jsonify([campaign.to_dict(include_relations=True) for campaign in campaigns]), 200


@campaign_bp.post("/campaigns")
@jwt_required()
def create_campaign():
    data = request.get_json() or {}
    required = [
        "titulo",
        "descripcion",
        "id_ciudad",
        "id_categoria",
        "tipo_ayuda_requerida",
        "fecha_fin",
    ]
    missing = [field for field in required if not data.get(field)]
    if missing:
        return jsonify({"error": f"Campos faltantes: {', '.join(missing)}"}), 400

    campaign = CAMPAÑA(
        titulo=data["titulo"],
        descripcion=data["descripcion"],
        id_ciudad=data["id_ciudad"],
        id_categoria=data["id_categoria"],
        id_creador=int(get_jwt_identity()),
        tipo_ayuda_requerida=data["tipo_ayuda_requerida"],
        meta_monetaria=data.get("meta_monetaria", 0),
        fecha_inicio=datetime.utcnow().date(),
        fecha_fin=datetime.strptime(data["fecha_fin"], "%Y-%m-%d").date(),
        estado="en_verificacion",
        porcentaje_avance=0,
    )
    db.session.add(campaign)
    db.session.commit()
    return jsonify(campaign.to_dict(include_relations=True)), 201


@campaign_bp.get("/campaigns/<int:campaign_id>")
@jwt_required(optional=True)
def get_campaign(campaign_id: int):
    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    current_user_id = get_jwt_identity()
    payload = campaign.to_dict(include_relations=True)
    payload["valoraciones"] = [r.to_dict() for r in campaign.valoraciones if r.visible]
    payload["soportes"] = [s.to_dict() for s in campaign.soportes]
    payload["seguimientos"] = [s.to_dict() for s in campaign.seguimientos]
    payload["puntos_recoleccion"] = [p.to_dict() for p in campaign.puntos_recoleccion]
    payload["donaciones"] = [d.to_dict() for d in campaign.donaciones]
    payload["donantes_count"] = (
        db.session.query(db.func.count(db.distinct(DONACION.id_donante)))
        .filter(DONACION.id_campania == campaign.id_campania)
        .scalar()
        or 0
    )
    payload["likes_count"] = REACCION.query.filter_by(
        id_campania=campaign.id_campania
    ).count()
    payload["liked_by_me"] = (
        REACCION.query.filter_by(
            id_campania=campaign.id_campania,
            id_usuario=int(current_user_id),
        ).first()
        is not None
        if current_user_id
        else False
    )
    return jsonify(payload), 200


@campaign_bp.put("/campaigns/<int:campaign_id>")
@jwt_required()
def update_campaign(campaign_id: int):
    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if campaign.id_creador != int(get_jwt_identity()):
        return jsonify({"error": "Solo el creador puede editar la campaña"}), 403

    data = request.get_json() or {}
    for field in [
        "titulo",
        "descripcion",
        "id_ciudad",
        "id_categoria",
        "tipo_ayuda_requerida",
        "meta_monetaria",
        "estado",
    ]:
        if field in data:
            setattr(campaign, field, data[field])
    if "fecha_fin" in data:
        campaign.fecha_fin = datetime.strptime(data["fecha_fin"], "%Y-%m-%d").date()

    db.session.commit()
    return jsonify(campaign.to_dict(include_relations=True)), 200


@campaign_bp.delete("/campaigns/<int:campaign_id>")
@jwt_required()
def delete_campaign(campaign_id: int):
    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if campaign.id_creador != int(get_jwt_identity()):
        return jsonify({"error": "Solo el creador puede eliminar la campaña"}), 403

    db.session.delete(campaign)
    db.session.commit()
    return jsonify({"message": "Campaña eliminada"}), 200
