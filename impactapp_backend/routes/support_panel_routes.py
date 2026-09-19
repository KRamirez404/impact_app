from datetime import datetime

from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, SOPORTE, USUARIO, db
from services.audit_service import registrar

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

    pending = CAMPAÑA.query.filter_by(estado="en_verificacion", eliminada=False).count()
    approved = CAMPAÑA.query.filter_by(estado="activa", eliminada=False).count()
    rejected = CAMPAÑA.query.filter_by(estado="pausada", eliminada=False).count()
    deleted = CAMPAÑA.query.filter_by(eliminada=True).count()
    return (
        jsonify(
            {
                "pendientes": pending,
                "aprobadas": approved,
                "rechazadas": rejected,
                "eliminadas": deleted,
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
    data = request.get_json(silent=True) or {}
    note = (data.get("nota_revision") or data.get("nota") or "").strip()

    if campaign.eliminada:
        return jsonify({"error": "La campaña está eliminada"}), 400

    has_document = SOPORTE.query.filter(
        SOPORTE.id_campania == campaign.id_campania,
        SOPORTE.tipo.in_(["documento_oficial", "certificado_institucional", "rut", "cedula"]),
    ).first()
    if has_document is None:
        return jsonify(
            {"error": "La campaña requiere un soporte de identidad/documento oficial antes de aprobarse"}
        ), 400

    campaign.estado = "activa"
    campaign.nota_revision = note or None
    campaign.fecha_revision = datetime.utcnow()
    campaign.id_auditor = user.id_usuario
    for support in campaign.soportes:
        support.validado = True

    db.session.commit()
    registrar(
        id_usuario=user.id_usuario,
        accion="CAMPAÑA_APROBADA",
        descripcion=f"Campaña '{campaign.titulo}' aprobada por soporte",
        entidad="CAMPAÑA",
        id_entidad=campaign.id_campania,
        direccion_ip=request.remote_addr,
    )
    return jsonify(campaign.to_dict(include_relations=True)), 200


@support_panel_bp.post("/campaigns/<int:campaign_id>/reject")
@jwt_required()
def reject_campaign(campaign_id: int):
    user, error = _require_support_user()
    if error:
        return error

    data = request.get_json(silent=True) or {}
    note = (data.get("nota_revision") or data.get("nota") or "").strip()
    if not note:
        return jsonify({"error": "La nota de rechazo es requerida"}), 400

    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if campaign.eliminada:
        return jsonify({"error": "La campaña está eliminada"}), 400
    campaign.estado = "pausada"
    campaign.nota_revision = note
    campaign.fecha_revision = datetime.utcnow()
    campaign.id_auditor = user.id_usuario
    for support in campaign.soportes:
        support.validado = False

    db.session.commit()
    registrar(
        id_usuario=user.id_usuario,
        accion="CAMPAÑA_RECHAZADA",
        descripcion=f"Campaña '{campaign.titulo}' rechazada: {note}",
        entidad="CAMPAÑA",
        id_entidad=campaign.id_campania,
        direccion_ip=request.remote_addr,
    )
    return jsonify(campaign.to_dict(include_relations=True)), 200


@support_panel_bp.post("/campaigns/<int:campaign_id>/invalidate")
@jwt_required()
def invalidate_campaign(campaign_id: int):
    user, error = _require_support_user()
    if error:
        return error

    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if campaign.eliminada:
        return jsonify({"error": "La campaña ya está invalidada"}), 400

    data = request.get_json(silent=True) or {}
    motivo = (
        data.get("motivo") or data.get("motivo_eliminacion") or data.get("nota") or ""
    ).strip()

    campaign.eliminada = True
    campaign.motivo_eliminacion = motivo or None
    campaign.fecha_eliminacion = datetime.utcnow()
    campaign.id_eliminador = user.id_usuario
    for support in campaign.soportes:
        support.validado = False
    db.session.commit()
    registrar(
        id_usuario=user.id_usuario,
        accion="CAMPAÑA_INVALIDADA",
        descripcion=f"Campaña '{campaign.titulo}' invalidada (borrado lógico)",
        entidad="CAMPAÑA",
        id_entidad=campaign.id_campania,
        direccion_ip=request.remote_addr,
    )
    return jsonify(campaign.to_dict(include_relations=True)), 200


@support_panel_bp.post("/campaigns/<int:campaign_id>/delete")
@jwt_required()
def delete_campaign(campaign_id: int):
    user, error = _require_support_user()
    if error:
        return error

    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if campaign.eliminada:
        return jsonify({"error": "La campaña ya está eliminada"}), 400

    data = request.get_json(silent=True) or {}
    motivo = (
        data.get("motivo") or data.get("motivo_eliminacion") or data.get("nota") or ""
    ).strip()

    campaign.eliminada = True
    campaign.motivo_eliminacion = motivo or None
    campaign.fecha_eliminacion = datetime.utcnow()
    campaign.id_eliminador = user.id_usuario
    db.session.commit()
    registrar(
        id_usuario=user.id_usuario,
        accion="CAMPAÑA_ELIMINADA",
        descripcion=f"Campaña '{campaign.titulo}' eliminada (borrado lógico)",
        entidad="CAMPAÑA",
        id_entidad=campaign.id_campania,
        direccion_ip=request.remote_addr,
    )
    return jsonify(campaign.to_dict(include_relations=True)), 200


@support_panel_bp.post("/campaigns/<int:campaign_id>/restore")
@jwt_required()
def restore_campaign(campaign_id: int):
    user, error = _require_support_user()
    if error:
        return error

    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if not campaign.eliminada:
        return jsonify({"error": "La campaña no está eliminada"}), 400

    campaign.eliminada = False
    campaign.motivo_eliminacion = None
    campaign.fecha_eliminacion = None
    campaign.id_eliminador = None
    db.session.commit()
    registrar(
        id_usuario=user.id_usuario,
        accion="CAMPAÑA_RESTAURADA",
        descripcion=f"Campaña '{campaign.titulo}' restaurada",
        entidad="CAMPAÑA",
        id_entidad=campaign.id_campania,
        direccion_ip=request.remote_addr,
    )
    return jsonify(campaign.to_dict(include_relations=True)), 200
