from datetime import datetime

from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, CATEGORIA, CIUDAD, DONACION, REACCION, db
from services.audit_service import registrar
from services.authorization import is_support, require_role

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
    query = CAMPAÑA.query.filter(CAMPAÑA.eliminada.is_(False))
    ciudad = request.args.get("ciudad")
    categoria = request.args.get("categoria")
    tipo_ayuda = request.args.get("tipo_ayuda")
    estado = request.args.get("estado")

    if ciudad:
        try:
            query = query.filter(CAMPAÑA.id_ciudad == int(ciudad))
        except ValueError:
            return jsonify({"error": "Parámetro 'ciudad' inválido"}), 400
    if categoria:
        try:
            query = query.filter(CAMPAÑA.id_categoria == int(categoria))
        except ValueError:
            return jsonify({"error": "Parámetro 'categoria' inválido"}), 400
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
        data["soportes"] = [s.to_dict() for s in campaign.soportes]
        payload.append(data)
    return jsonify(payload), 200


@campaign_bp.get("/campaigns/mine")
@jwt_required()
def list_my_campaigns():
    current_user_id = int(get_jwt_identity())
    campaigns = (
        CAMPAÑA.query.filter(CAMPAÑA.id_creador == current_user_id)
        .filter(CAMPAÑA.eliminada.is_(False))
        .order_by(CAMPAÑA.id_campania.desc())
        .all()
    )
    payload = []
    for campaign in campaigns:
        data = campaign.to_dict(include_relations=True)
        data["soportes"] = [s.to_dict() for s in campaign.soportes]
        payload.append(data)
    return jsonify(payload), 200


@campaign_bp.post("/campaigns")
@jwt_required()
@require_role("organizador")
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

    try:
        fecha_fin = datetime.strptime(data["fecha_fin"], "%Y-%m-%d").date()
    except (ValueError, TypeError):
        return jsonify({"error": "fecha_fin debe tener el formato YYYY-MM-DD"}), 400

    if fecha_fin <= datetime.utcnow().date():
        return jsonify({"error": "La fecha fin debe ser futura"}), 400

    try:
        id_ciudad = int(data["id_ciudad"])
        id_categoria = int(data["id_categoria"])
    except (ValueError, TypeError):
        return jsonify({"error": "id_ciudad e id_categoria deben ser numéricos"}), 400

    campaign = CAMPAÑA(
        titulo=data["titulo"],
        descripcion=data["descripcion"],
        id_ciudad=id_ciudad,
        id_categoria=id_categoria,
        id_creador=int(get_jwt_identity()),
        tipo_ayuda_requerida=data["tipo_ayuda_requerida"],
        meta_monetaria=data.get("meta_monetaria", 0),
        fecha_inicio=datetime.utcnow().date(),
        fecha_fin=fecha_fin,
        cuenta_recaudo=data.get("cuenta_recaudo"),
        estado="en_verificacion",
        porcentaje_avance=0,
    )
    db.session.add(campaign)
    db.session.commit()
    registrar(
        id_usuario=int(get_jwt_identity()),
        accion="CAMPAÑA_CREADA",
        descripcion=f"Campaña '{campaign.titulo}' creada",
        entidad="CAMPAÑA",
        id_entidad=campaign.id_campania,
        direccion_ip=request.remote_addr,
    )
    return jsonify(campaign.to_dict(include_relations=True)), 201


@campaign_bp.get("/campaigns/<int:campaign_id>")
@jwt_required(optional=True)
def get_campaign(campaign_id: int):
    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if campaign.eliminada and not is_support():
        return jsonify({"error": "Campaña no encontrada"}), 404
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


@campaign_bp.get("/campaigns/<int:campaign_id>/donors")
@jwt_required()
def get_campaign_donors(campaign_id: int):
    current_user_id = int(get_jwt_identity())
    campaign = CAMPAÑA.query.get_or_404(campaign_id)

    if campaign.eliminada:
        return jsonify({"error": "La campaña no está disponible"}), 404

    if campaign.estado in ("pausada", "rechazada"):
        return jsonify({"error": "La campaña está rechazada"}), 403

    if campaign.id_creador != current_user_id:
        return jsonify({"error": "Solo el creador de la campaña puede ver los donadores"}), 403

    donations = (
        DONACION.query.filter(DONACION.id_campania == campaign_id)
        .order_by(DONACION.fecha_donacion.desc())
        .all()
    )

    result = []
    for donation in donations:
        d = donation.to_dict()
        d["donante"] = donation.donante.to_dict() if donation.donante else {}
        d["es_anonimo"] = False
        result.append(d)

    return jsonify(result), 200


@campaign_bp.put("/campaigns/<int:campaign_id>")
@jwt_required()
@require_role("organizador")
def update_campaign(campaign_id: int):
    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if campaign.eliminada:
        return jsonify({"error": "La campaña no está disponible"}), 404
    if campaign.id_creador != int(get_jwt_identity()):
        return jsonify({"error": "Solo el creador puede editar la campaña"}), 403

    data = request.get_json() or {}
    user_id = int(get_jwt_identity())

    if "cuenta_recaudo" in data:
        if campaign.estado == "activa":
            return jsonify({"error": "No se puede cambiar la cuenta de recaudo de una campaña aprobada"}), 400
        new_account = str(data["cuenta_recaudo"] or "").strip() or None
        if new_account != campaign.cuenta_recaudo:
            registrar(
                id_usuario=user_id,
                accion="CAMBIO_CUENTA_RECAUDO",
                descripcion=f"Cuenta de recaudo actualizada de '{campaign.cuenta_recaudo or ''}' a '{new_account or ''}'",
                entidad="CAMPAÑA",
                id_entidad=campaign.id_campania,
                direccion_ip=request.remote_addr,
            )
            campaign.cuenta_recaudo = new_account

    for field in [
        "titulo",
        "descripcion",
        "id_ciudad",
        "id_categoria",
        "tipo_ayuda_requerida",
        "meta_monetaria",
    ]:
        if field in data:
            setattr(campaign, field, data[field])
    if "fecha_fin" in data:
        try:
            campaign.fecha_fin = datetime.strptime(data["fecha_fin"], "%Y-%m-%d").date()
        except (ValueError, TypeError):
            return jsonify({"error": "fecha_fin debe tener el formato YYYY-MM-DD"}), 400

    db.session.commit()
    return jsonify(campaign.to_dict(include_relations=True)), 200


@campaign_bp.delete("/campaigns/<int:campaign_id>")
@jwt_required()
@require_role("organizador")
def delete_campaign(campaign_id: int):
    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    user_id = int(get_jwt_identity())
    if campaign.id_creador != user_id:
        return jsonify({"error": "Solo el creador puede eliminar la campaña"}), 403

    data = request.get_json(silent=True) or {}
    motivo = (data.get("motivo") or data.get("motivo_eliminacion") or "").strip() or None

    campaign.eliminada = True
    campaign.motivo_eliminacion = motivo
    campaign.fecha_eliminacion = datetime.utcnow()
    campaign.id_eliminador = user_id
    db.session.commit()
    registrar(
        id_usuario=user_id,
        accion="CAMPAÑA_ELIMINADA",
        descripcion=f"Campaña '{campaign.titulo}' eliminada (borrado lógico)",
        entidad="CAMPAÑA",
        id_entidad=campaign.id_campania,
        direccion_ip=request.remote_addr,
    )
    return jsonify({"message": "Campaña eliminada"}), 200
