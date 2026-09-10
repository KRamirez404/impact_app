from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy import func

from models import CAMPAÑA, DONACION, PUNTO_RECOLECCION, USUARIO, db
from services.audit_service import registrar
from services.authorization import require_role
from services.campaign_service import recalculate_campaign_progress
from services.donation_integrity import compute_donation_checksum, donation_is_intact

donation_bp = Blueprint("donation_bp", __name__, url_prefix="/api/donations")


@donation_bp.post("")
@jwt_required()
@require_role("donante")
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
    db.session.flush()
    donation.checksum = compute_donation_checksum(
        donation, current_app.config["JWT_SECRET_KEY"]
    )
    db.session.commit()

    if donation.tipo == "economica":
        recalculate_campaign_progress(campaign)

    registrar(
        id_usuario=donation.id_donante,
        accion="DONACION",
        descripcion=f"Donación {donation.tipo} registrada en campaña {campaign.titulo}",
        entidad="DONACION",
        id_entidad=donation.id_donacion,
        direccion_ip=request.remote_addr,
    )

    return jsonify(donation.to_dict()), 201


@donation_bp.get("/campaign/<int:campaign_id>")
def get_campaign_donations(campaign_id: int):
    secret = current_app.config["JWT_SECRET_KEY"]
    donations = DONACION.query.filter_by(id_campania=campaign_id).all()
    payload = []
    for donation in donations:
        data = donation.to_dict()
        data["integridad"] = donation_is_intact(donation, secret)
        payload.append(data)
    return jsonify(payload), 200


@donation_bp.get("/mine")
@jwt_required()
def get_my_donations():
    current_user_id = int(get_jwt_identity())
    secret = current_app.config["JWT_SECRET_KEY"]
    donations = (
        DONACION.query.filter_by(id_donante=current_user_id)
        .order_by(DONACION.fecha_donacion.desc())
        .all()
    )
    payload = []
    for donation in donations:
        data = donation.to_dict()
        data["integridad"] = donation_is_intact(donation, secret)
        campaign = donation.campania
        seguimientos = campaign.seguimientos or []
        nuevos_avances = 0
        if donation.fecha_donacion:
            nuevos_avances = sum(
                1
                for s in seguimientos
                if s.fecha_registro and s.fecha_registro > donation.fecha_donacion
            )
        data["campania"] = {
            "id_campania": donation.id_campania,
            "titulo": campaign.titulo if campaign else "",
            "estado": campaign.estado if campaign else "",
            "fecha_fin": campaign.fecha_fin.isoformat() if campaign else "",
            "soportes": [s.to_dict() for s in campaign.soportes] if campaign else [],
            "total_avances": len(seguimientos),
            "nuevos_avances": nuevos_avances,
        }
        payload.append(data)
    return jsonify(payload), 200


@donation_bp.get("/top")
def get_top_donors():
    limit = request.args.get("limit", 5, type=int)
    limit = max(1, min(limit, 20))
    donors = (
        db.session.query(
            DONACION.id_donante,
            USUARIO.nombre,
            USUARIO.apellido,
            USUARIO.foto_perfil,
            func.sum(DONACION.monto_estimado).label("total_donado"),
            func.count(DONACION.id_donacion).label("donaciones_count"),
        )
        .join(USUARIO, DONACION.id_donante == USUARIO.id_usuario)
        .group_by(DONACION.id_donante, USUARIO.nombre, USUARIO.apellido, USUARIO.foto_perfil)
        .order_by(func.sum(DONACION.monto_estimado).desc())
        .limit(limit)
        .all()
    )
    payload = [
        {
            "id_usuario": donor.id_donante,
            "nombre": donor.nombre,
            "apellido": donor.apellido,
            "foto_perfil": donor.foto_perfil,
            "total_donado": float(donor.total_donado or 0),
            "donaciones_count": int(donor.donaciones_count or 0),
        }
        for donor in donors
    ]
    return jsonify(payload), 200
