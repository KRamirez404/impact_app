from datetime import datetime

from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import CAMPAÑA, DONACION, db
from services import wompi_service
from services.audit_service import registrar
from services.authorization import current_user, is_support, require_role
from services.campaign_service import recalculate_campaign_progress
from services.donation_integrity import compute_donation_checksum

wompi_bp = Blueprint("wompi_bp", __name__, url_prefix="/api")


@wompi_bp.post("/donations/checkout")
@jwt_required()
@require_role("donante")
def create_donation_checkout():
    if not wompi_service.is_configured():
        return (
            jsonify(
                {
                    "error": "Las donaciones en línea no están disponibles en este "
                    "momento. Intenta más tarde."
                }
            ),
            503,
        )

    data = request.get_json() or {}
    campaign_id = data.get("id_campania")
    if not campaign_id:
        return jsonify({"error": "Campo faltante: id_campania"}), 400

    try:
        amount = float(data.get("monto_estimado", 0))
    except (TypeError, ValueError):
        return jsonify({"error": "Monto inválido"}), 400

    min_amount = float(current_app.config.get("WOMPI_MIN_AMOUNT", 1000))
    if amount < min_amount:
        return jsonify({"error": f"El monto mínimo de donación es {min_amount:.0f} COP"}), 400

    campaign = CAMPAÑA.query.get_or_404(campaign_id)
    if campaign.estado != "activa":
        return jsonify({"error": "La campaña no está activa para recibir donaciones"}), 400

    user = current_user()
    donation = DONACION(
        id_campania=campaign.id_campania,
        id_donante=int(get_jwt_identity()),
        id_punto=None,
        tipo="economica",
        monto_estimado=amount,
        descripcion=data.get("descripcion") or "Donación económica en línea",
        estado_pago="pendiente",
    )
    db.session.add(donation)
    db.session.flush()

    donation.referencia_pago = wompi_service.generate_reference(donation.id_donacion)
    donation.checksum = compute_donation_checksum(
        donation, current_app.config["JWT_SECRET_KEY"]
    )
    db.session.commit()

    checkout_url = wompi_service.build_checkout_url(
        reference=donation.referencia_pago,
        amount=amount,
        customer_email=user.correo if user else None,
    )

    registrar(
        id_usuario=donation.id_donante,
        accion="DONACION_CHECKOUT",
        descripcion=f"Checkout Wompi iniciado para campaña {campaign.titulo}",
        entidad="DONACION",
        id_entidad=donation.id_donacion,
        direccion_ip=request.remote_addr,
    )

    return (
        jsonify(
            {
                "id_donacion": donation.id_donacion,
                "id_campania": donation.id_campania,
                "referencia": donation.referencia_pago,
                "monto_estimado": float(donation.monto_estimado or 0),
                "estado_pago": donation.estado_pago,
                "checkout_url": checkout_url,
            }
        ),
        201,
    )


@wompi_bp.get("/donations/<int:donation_id>/status")
@jwt_required()
def get_donation_status(donation_id: int):
    donation = DONACION.query.get_or_404(donation_id)
    user_id = int(get_jwt_identity())
    if donation.id_donante != user_id and not is_support():
        return jsonify({"error": "No autorizado para consultar esta donación"}), 403

    if (
        donation.estado_pago == "pendiente"
        and donation.wompi_transaction_id
        and wompi_service.is_configured()
    ):
        transaction = wompi_service.fetch_transaction(donation.wompi_transaction_id)
        if transaction:
            _apply_transaction(donation, transaction)

    return jsonify(donation.to_dict()), 200


@wompi_bp.post("/webhooks/wompi")
def wompi_webhook():
    payload = request.get_json(silent=True) or {}
    if payload.get("event") != "transaction.updated":
        return jsonify({"received": True}), 200

    if not wompi_service.verify_event_checksum(payload):
        return jsonify({"error": "Firma de evento inválida"}), 401

    if not wompi_service.environment_matches(payload):
        return jsonify({"error": "Ambiente de evento inválido"}), 401

    transaction = (payload.get("data") or {}).get("transaction") or {}
    reference = transaction.get("reference")
    if not reference:
        return jsonify({"received": True}), 200

    donation = DONACION.query.filter_by(referencia_pago=reference).first()
    if not donation:
        return jsonify({"received": True}), 200

    _apply_transaction(donation, transaction)
    return jsonify({"received": True}), 200


def _apply_transaction(donation: DONACION, transaction: dict) -> None:
    new_status = wompi_service.map_status(transaction.get("status"))
    transaction_id = transaction.get("id")
    method = transaction.get("payment_method_type")

    already_processed = (
        donation.wompi_transaction_id == transaction_id
        and (new_status is None or donation.estado_pago == new_status)
    )
    if already_processed:
        return

    if transaction_id:
        donation.wompi_transaction_id = transaction_id
    if method:
        donation.metodo_pago = method
    if new_status:
        donation.estado_pago = new_status
        if new_status == "aprobada" and not donation.fecha_pago:
            donation.fecha_pago = datetime.utcnow()
    db.session.commit()

    if donation.estado_pago == "aprobada":
        campaign = donation.campania
        if campaign:
            recalculate_campaign_progress(campaign)

    registrar(
        id_usuario=donation.id_donante,
        accion="DONACION_PAGO",
        descripcion=f"Pago Wompi {donation.estado_pago} para donación {donation.id_donacion}",
        entidad="DONACION",
        id_entidad=donation.id_donacion,
    )
