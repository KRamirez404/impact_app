import os

from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy.exc import SQLAlchemyError

from models import ARCHIVO, CAMPAÑA, DONACION, INFORME_FINANCIERO, USUARIO, db
from services.audit_service import registrar
from services.authorization import current_user, puede_ver_campania
from services.file_service import save_upload
from services.notification_service import registrar_y_enviar
from services.rate_limit import enforce, too_many_requests

financial_report_bp = Blueprint("financial_report", __name__, url_prefix="/api/campaigns")
REPORT_EXTENSIONS = {
    ".pdf": "application/pdf",
    ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
}


@financial_report_bp.post("/<int:campaign_id>/financial-report")
@jwt_required()
def upload_financial_report(campaign_id):
    user_id = int(get_jwt_identity())
    user = USUARIO.query.get(user_id)
    if user is None or user.estado != "activo":
        return jsonify({"error": "Usuario bloqueado o no encontrado"}), 403

    retry_after = enforce(f"upload:{user_id}", "RATE_LIMIT_UPLOAD_ATTEMPTS", "RATE_LIMIT_UPLOAD_WINDOW")
    if retry_after:
        return too_many_requests(retry_after)

    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if campaign.eliminada:
        return jsonify({"error": "La campaña no está disponible"}), 404
    if campaign.id_creador != user_id:
        return jsonify({"error": "Solo el organizador puede cargar el informe financiero"}), 403

    file = request.files.get("file")
    if file is None or not file.filename:
        return jsonify({"error": "Debe adjuntar un informe financiero"}), 400

    extension = os.path.splitext(file.filename or "")[1].lower()
    expected_mime = REPORT_EXTENSIONS.get(extension)
    if expected_mime is None:
        return jsonify({"error": "El informe debe estar en formato PDF o DOCX"}), 400
    if file.content_type not in (expected_mime, "application/octet-stream"):
        return jsonify({"error": "El MIME del informe no corresponde con su formato"}), 400

    upload_folder = os.path.join(current_app.root_path, current_app.config["UPLOAD_FOLDER"])
    try:
        ruta = save_upload(file, upload_folder)
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400

    informe = INFORME_FINANCIERO.query.filter_by(id_campania=campaign_id).first()
    anterior = informe.ruta if informe else None
    if informe:
        informe.ruta = ruta
        informe.nombre_archivo = file.filename
        informe.mime_type = expected_mime
    else:
        informe = INFORME_FINANCIERO(
            id_campania=campaign_id,
            ruta=ruta,
            nombre_archivo=file.filename,
            mime_type=expected_mime,
        )
        db.session.add(informe)

    if not ARCHIVO.query.filter_by(ruta=ruta).first():
        db.session.add(ARCHIVO(ruta=ruta, id_usuario=user_id))

    try:
        db.session.commit()
    except SQLAlchemyError:
        db.session.rollback()
        try:
            os.remove(os.path.join(upload_folder, ruta.rsplit("/", 1)[-1]))
        except OSError:
            pass
        return jsonify({"error": "No fue posible registrar el informe financiero"}), 503

    if anterior and anterior != ruta:
        try:
            os.remove(os.path.join(upload_folder, anterior.rsplit("/", 1)[-1]))
        except OSError:
            pass

    registrar(
        id_usuario=user_id,
        accion="INFORME_FINANCIERO_CARGADO",
        descripcion=f"Informe financiero cargado para campaña {campaign.titulo}",
        entidad="INFORME_FINANCIERO",
        id_entidad=informe.id_informe,
        direccion_ip=request.remote_addr,
    )

    donantes = (
        db.session.query(DONACION.id_donante)
        .filter_by(id_campania=campaign_id, estado_pago="aprobada")
        .distinct()
        .all()
    )
    for (id_donante,) in donantes:
        donante = db.session.get(USUARIO, id_donante)
        if donante and donante.correo and donante.estado == "activo":
            registrar_y_enviar(
                "informe_financiero",
                donante.correo,
                {"nombre": donante.nombre, "campania": campaign.titulo},
                f"informe_financiero:{campaign_id}:{informe.id_informe}:{id_donante}",
                id_usuario=id_donante,
            )

    return jsonify(informe.to_dict()), 201


@financial_report_bp.get("/<int:campaign_id>/financial-report")
@jwt_required(optional=True)
def get_financial_report(campaign_id):
    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    user = current_user()
    if campaign.eliminada or not puede_ver_campania(campaign, user):
        return jsonify({"error": "Campaña no encontrada"}), 404

    if user is None:
        return jsonify({"error": "Autenticación requerida"}), 401

    if user.rol != "soporte" and campaign.id_creador != user.id_usuario:
        has_donated = (
            DONACION.query.filter_by(
                id_campania=campaign_id,
                id_donante=user.id_usuario,
                estado_pago="aprobada",
            ).first()
            is not None
        )
        if not has_donated:
            return (
                jsonify(
                    {
                        "error": "Solo los donantes aportantes, el organizador o soporte pueden consultar el informe financiero"
                    }
                ),
                403,
            )

    informe = INFORME_FINANCIERO.query.filter_by(id_campania=campaign_id).first()
    if informe is None:
        return jsonify({"error": "Informe financiero no disponible"}), 404
    return jsonify(informe.to_dict()), 200
