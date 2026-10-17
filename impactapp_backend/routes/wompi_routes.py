import hashlib
import json
from datetime import datetime
from decimal import Decimal, InvalidOperation

from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy.exc import SQLAlchemyError

from models import AUDITORIA, CAMPAÑA, DONACION, db
from services import wompi_service
from services.audit_service import registrar
from services.authorization import current_user, is_support, require_role
from services.campaign_service import recalculate_campaign_progress
from services.donation_integrity import compute_donation_checksum, donation_is_intact

wompi_bp = Blueprint("wompi_bp", __name__, url_prefix="/api")


class ConciliationError(ValueError):
    pass


def _payment_error(error, status):
    db.session.rollback()
    current_app.logger.warning("Wompi: %s", error)
    return jsonify({"error": "No fue posible conciliar el pago. Intenta más tarde."}), status


def _checkout_response(donation, user, status):
    return jsonify({
        "id_donacion": donation.id_donacion,
        "id_campania": donation.id_campania,
        "referencia": donation.referencia_pago,
        "monto_estimado": float(donation.monto_estimado),
        "estado_pago": donation.estado_pago,
        "checkout_url": wompi_service.build_checkout_url(
            reference=donation.referencia_pago,
            amount=donation.monto_estimado,
            customer_email=user.correo,
        ),
    }), status


@wompi_bp.post("/donations/checkout")
@jwt_required()
@require_role("donante")
def create_donation_checkout():
    if not wompi_service.is_configured() or current_app.config["WOMPI_CURRENCY"] != "COP":
        return jsonify({"error": "Las donaciones en línea no están disponibles en este momento."}), 503
    try:
        data = json.loads(request.get_data(), parse_float=Decimal) if request.is_json else None
    except (ValueError, InvalidOperation):
        data = None
    if not isinstance(data, dict):
        return jsonify({"error": "El cuerpo debe ser un objeto JSON válido"}), 400
    campaign_id = data.get("id_campania")
    if type(campaign_id) is not int or not 0 < campaign_id <= 2147483647:
        return jsonify({"error": "id_campania debe ser un entero positivo válido"}), 400
    if data.get("currency", "COP") != "COP":
        return jsonify({"error": "La moneda debe ser COP"}), 400
    description = data.get("descripcion")
    if description is not None and not isinstance(description, str):
        return jsonify({"error": "descripcion debe ser texto"}), 400
    description = description or "Donación económica en línea"
    try:
        amount = wompi_service.decimal_amount(data.get("monto_estimado"))
        minimum = wompi_service.decimal_amount(current_app.config.get("WOMPI_MIN_AMOUNT", 1000))
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400
    if amount < minimum:
        return jsonify({"error": f"El monto mínimo de donación es {minimum} COP"}), 400
    key = request.headers.get("Idempotency-Key")
    if key is not None and (not key.strip() or len(key) > 128):
        return jsonify({"error": "Idempotency-Key debe tener entre 1 y 128 caracteres"}), 400
    user = current_user()
    checkout_key = hashlib.sha256(f"{user.id_usuario}:{key}".encode()).hexdigest() if key else None
    try:
        campaign = CAMPAÑA.query.filter_by(id_campania=campaign_id).with_for_update().first_or_404()
        if campaign.eliminada or campaign.estado != "activa":
            return jsonify({"error": "La campaña no está activa para recibir donaciones"}), 400
        if checkout_key:
            existing = DONACION.query.filter_by(clave_checkout=checkout_key).first()
            if existing:
                if (existing.id_campania, existing.monto_estimado, existing.descripcion) != (campaign_id, amount, description):
                    return jsonify({"error": "Idempotency-Key ya utilizada con otros datos"}), 409
                return _checkout_response(existing, user, 200)
        donation = DONACION(
            id_campania=campaign.id_campania, id_donante=user.id_usuario,
            tipo="economica", monto_estimado=amount, descripcion=description,
            estado_pago="pendiente", clave_checkout=checkout_key,
        )
        db.session.add(donation)
        db.session.flush()
        donation.referencia_pago = wompi_service.generate_reference(donation.id_donacion)
        donation.checksum = compute_donation_checksum(donation, current_app.config["JWT_SECRET_KEY"])
        response = _checkout_response(donation, user, 201)
        registrar(
            id_usuario=user.id_usuario, accion="DONACION_CHECKOUT",
            descripcion=f"Checkout Wompi iniciado para donación {donation.id_donacion}",
            entidad="DONACION", id_entidad=donation.id_donacion,
            direccion_ip=request.remote_addr, confirmar=False,
        )
        db.session.commit()
        return response
    except SQLAlchemyError:
        return _payment_error("checkout_no_persistido", 503)


@wompi_bp.get("/donations/<int:donation_id>/status")
@jwt_required()
def get_donation_status(donation_id: int):
    donation = DONACION.query.get_or_404(donation_id)
    if donation.id_donante != int(get_jwt_identity()) and not is_support():
        return jsonify({"error": "No autorizado para consultar esta donación"}), 403
    hint = request.args.get("transaction_id")
    if hint is not None and not wompi_service.valid_transaction_id(hint):
        return jsonify({"error": "Identificador de transacción inválido"}), 400
    if hint and donation.wompi_transaction_id and hint != donation.wompi_transaction_id:
        return jsonify({"error": "La donación ya tiene otra transacción asociada"}), 409
    transaction_id = donation.wompi_transaction_id or hint
    if transaction_id:
        try:
            transaction = wompi_service.fetch_transaction(transaction_id)
            if transaction.get("id") != transaction_id:
                raise ConciliationError("identificador_no_coincide")
            reconciliation = _apply_transaction(donation, transaction)
        except wompi_service.WompiQueryError:
            return _payment_error("consulta_no_disponible", 503)
        except ConciliationError as exc:
            return _payment_error(str(exc), 409)
        except SQLAlchemyError:
            return _payment_error("pago_no_persistido", 503)
    payload = donation.to_dict()
    payload["conciliacion"] = reconciliation if transaction_id else "sin_identificador"
    return jsonify(payload), 200


@wompi_bp.post("/webhooks/wompi")
def wompi_webhook():
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict) or not isinstance(payload.get("event"), str):
        return jsonify({"error": "Evento inválido"}), 400
    if payload["event"] != "transaction.updated":
        return jsonify({"received": True}), 200
    if not wompi_service.verify_event_checksum(payload, request.headers.get("X-Event-Checksum")):
        return jsonify({"error": "Firma de evento inválida"}), 401
    if not wompi_service.environment_matches(payload):
        return jsonify({"error": "Ambiente de evento inválido"}), 401
    transaction = payload["data"].get("transaction")
    try:
        _validate_transaction(transaction)
        authoritative = wompi_service.fetch_transaction(transaction["id"])
        _validate_transaction(authoritative)
        if any(authoritative[field] != transaction[field] for field in ("id", "reference", "amount_in_cents", "currency")):
            raise ConciliationError("evento_no_coincide_con_proveedor")
        if authoritative["status"] != transaction["status"]:
            current_app.logger.info("Wompi: evento con estado desactualizado; se utiliza consulta autoritativa")
        donation = DONACION.query.filter_by(referencia_pago=authoritative["reference"]).first()
        if donation:
            _apply_transaction(donation, authoritative)
        else:
            current_app.logger.info("Wompi: referencia sin donación local; evento ignorado")
    except wompi_service.WompiQueryError:
        return _payment_error("consulta_no_disponible", 503)
    except ConciliationError as exc:
        return _payment_error(str(exc), 409)
    except SQLAlchemyError:
        return _payment_error("pago_no_persistido", 503)
    return jsonify({"received": True}), 200


def _validate_transaction(transaction):
    if not isinstance(transaction, dict):
        raise ConciliationError("transaccion_invalida")
    if not wompi_service.valid_transaction_id(transaction.get("id")):
        raise ConciliationError("identificador_invalido")
    reference = transaction.get("reference")
    if not isinstance(reference, str) or not reference or len(reference) > 255:
        raise ConciliationError("referencia_invalida")
    amount = transaction.get("amount_in_cents")
    if type(amount) is not int or not 0 < amount <= int(wompi_service.MAX_AMOUNT * 100):
        raise ConciliationError("monto_invalido")
    if transaction.get("currency") != "COP":
        raise ConciliationError("moneda_invalida")
    if not isinstance(transaction.get("status"), str) or transaction["status"] not in wompi_service.STATUS_MAP:
        raise ConciliationError("estado_invalido")
    method = transaction.get("payment_method_type")
    if method is not None and (not isinstance(method, str) or not method or len(method) > 40):
        raise ConciliationError("metodo_invalido")
    if transaction["status"] == "VOIDED" and method != "CARD":
        raise ConciliationError("anulacion_sin_tarjeta")


def _apply_transaction(donation: DONACION, transaction: dict) -> str:
    _validate_transaction(transaction)
    campaign = CAMPAÑA.query.filter_by(id_campania=donation.id_campania).populate_existing().with_for_update().one()
    donation = DONACION.query.filter_by(id_donacion=donation.id_donacion).populate_existing().with_for_update().one()
    try:
        local_amount = wompi_service.amount_to_cents(donation.monto_estimado)
    except ValueError as exc:
        raise ConciliationError("monto_local_invalido") from exc
    if (
        donation.tipo != "economica"
        or donation.referencia_pago != transaction["reference"]
        or local_amount != transaction["amount_in_cents"]
        or not donation.checksum
        or not donation_is_intact(donation, current_app.config["JWT_SECRET_KEY"])
    ):
        raise ConciliationError("donacion_no_coincide")
    transaction_id = transaction["id"]
    if donation.wompi_transaction_id and donation.wompi_transaction_id != transaction_id:
        raise ConciliationError("donacion_con_otra_transaccion")
    other = DONACION.query.filter(
        DONACION.wompi_transaction_id == transaction_id,
        DONACION.id_donacion != donation.id_donacion,
    ).first()
    if other:
        raise ConciliationError("transaccion_ya_asociada")
    new_status = wompi_service.map_status(transaction["status"])
    old_status = donation.estado_pago
    allowed = (
        old_status == new_status
        or old_status == "pendiente"
        or (old_status == "aprobada" and new_status == "anulada" and transaction.get("payment_method_type") == "CARD")
    )
    if not allowed:
        current_app.logger.warning("Wompi: transición terminal ignorada")
        db.session.rollback()
        return "estado_desactualizado"
    donation.wompi_transaction_id = transaction_id
    if transaction.get("payment_method_type"):
        donation.metodo_pago = transaction["payment_method_type"]
    donation.estado_pago = new_status
    if new_status == "aprobada" and not donation.fecha_pago:
        donation.fecha_pago = datetime.utcnow()
    db.session.flush()
    if old_status == "aprobada" or new_status == "aprobada" or (old_status != new_status and new_status == "anulada"):
        recalculate_campaign_progress(campaign, confirmar=False)
    description = f"Pago Wompi {new_status} para donación {donation.id_donacion}"
    audit = AUDITORIA.query.filter_by(
        accion="DONACION_PAGO", entidad="DONACION",
        id_entidad=donation.id_donacion, descripcion=description,
    ).first()
    if not audit:
        registrar(
            id_usuario=donation.id_donante, accion="DONACION_PAGO",
            descripcion=description, entidad="DONACION", id_entidad=donation.id_donacion,
            direccion_ip=request.remote_addr, confirmar=False,
        )
    db.session.commit()
    return "verificada"
