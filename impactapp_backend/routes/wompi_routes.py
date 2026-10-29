import hashlib
import json
from datetime import datetime, timedelta
from decimal import Decimal, InvalidOperation

from flask import Blueprint, current_app, has_request_context, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from models import AUDITORIA, CAMPAÑA, DONACION, PAGO_EVENTO, PAGO_INTENTO, db
from services import wompi_service
from services.audit_service import registrar
from services.authorization import current_user, is_support, require_role
from services.campaign_service import recalculate_campaign_progress
from services.donation_integrity import compute_donation_checksum, donation_is_intact
from services.rate_limit import client_ip, enforce, too_many_requests

wompi_bp = Blueprint("wompi_bp", __name__, url_prefix="/api")


class ConciliationError(ValueError):
    pass


_ERROR_MESSAGES = {
    "proveedor_no_disponible": "El proveedor de pagos no está disponible. Intenta más tarde.",
    "respuesta_proveedor_invalida": "El proveedor de pagos devolvió una respuesta inválida.",
    "wompi_no_configurado": "Las donaciones en línea no están disponibles en este momento.",
    "consulta_no_configurada": "Las donaciones en línea no están disponibles en este momento.",
    "transaccion_no_encontrada": "No se encontró la transacción indicada.",
    "transaccion_invalida": "La transacción indicada no es válida.",
    "conciliacion_conflicto": "La transacción no coincide con la donación.",
    "conciliacion_historica_pendiente": "La donación requiere revisión manual.",
    "conciliacion_aprobacion_sin_transaccion": "La donación requiere revisión manual.",
    "transaccion_ya_asociada": "La transacción ya está asociada a otra donación.",
    "persistencia_no_disponible": "No fue posible guardar el estado del pago. Intenta más tarde.",
    "conflicto_persistencia": "No fue posible guardar el estado del pago. Intenta más tarde.",
    "checkout_no_persistido": "No fue posible iniciar el pago. Intenta más tarde.",
}


def _payment_error(code, status):
    db.session.rollback()
    current_app.logger.warning("Wompi: %s", code)
    return jsonify({
        "error": _ERROR_MESSAGES.get(code, "No fue posible conciliar el pago. Intenta más tarde."),
        "code": code,
    }), status


def _wompi_error_status(exc):
    if exc.code == "transaccion_no_encontrada":
        return 404
    if exc.code == "respuesta_proveedor_invalida":
        return 502
    return 503


def _conciliation_code(exc):
    code = str(exc)
    if code in {
        "conciliacion_historica_pendiente",
        "conciliacion_aprobacion_sin_transaccion",
        "transaccion_ya_asociada",
    }:
        return code
    return "conciliacion_conflicto"


def _result_code(result):
    return {
        "verificada": "conciliacion_verificada",
        "estado_desactualizado": "estado_desactualizado",
        "doble_cobro": "doble_cobro",
    }.get(result, "conciliacion_sin_estado")


def _checkout_response(donation, user, status):
    checkout_url = None
    if donation.estado_pago == "pendiente":
        checkout_url = wompi_service.build_checkout_url(
            reference=donation.referencia_pago,
            amount=donation.monto_estimado,
            customer_email=user.correo,
        )
    return jsonify({
        "id_donacion": donation.id_donacion,
        "id_campania": donation.id_campania,
        "referencia": donation.referencia_pago,
        "monto_estimado": float(donation.monto_estimado),
        "monto_en_centavos": wompi_service.amount_to_cents(donation.monto_estimado),
        "estado_pago": donation.estado_pago,
        "ambiente": wompi_service.configured_environment(),
        "checkout_url": checkout_url,
    }), status


@wompi_bp.post("/donations/checkout")
@jwt_required()
@require_role("donante")
def create_donation_checkout():
    config_status = wompi_service.configuration_status()
    if not config_status["ok"]:
        current_app.logger.warning(
            "Wompi checkout no disponible (faltan=%s, problemas=%s)",
            ",".join(config_status["missing"]) or "ninguna",
            ",".join(config_status["issues"]) or "ninguno",
        )
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
    if (
        hint
        and donation.wompi_transaction_id
        and hint != donation.wompi_transaction_id
        and donation.estado_pago == "aprobada"
    ):
        return jsonify({"error": "La donación ya tiene otra transacción asociada"}), 409
    transaction_id = hint or donation.wompi_transaction_id
    reconciliation = None
    code = None
    if transaction_id:
        try:
            transaction = wompi_service.fetch_transaction(transaction_id)
            if transaction.get("id") != transaction_id:
                raise ConciliationError("identificador_no_coincide")
            reconciliation = _apply_transaction(
                donation, transaction, origen="status"
            )
            code = _result_code(reconciliation)
        except wompi_service.WompiConfigurationError:
            return _payment_error("wompi_no_configurado", 503)
        except wompi_service.WompiQueryError as exc:
            return _payment_error(exc.code, _wompi_error_status(exc))
        except ConciliationError as exc:
            current_app.logger.warning("Wompi: conciliación rechazada (%s)", str(exc))
            return _payment_error(_conciliation_code(exc), 409)
        except SQLAlchemyError:
            return _payment_error("persistencia_no_disponible", 503)
    elif donation.tipo == "economica" and donation.referencia_pago:
        fallback = _reconciliar_por_referencia(donation)
        if fallback.get("error"):
            error_code, status = fallback["error"]
            return _payment_error(error_code, status)
        reconciliation = fallback.get("conciliacion")
        code = fallback.get("code")
    payload = donation.to_dict()
    payload["conciliacion"] = reconciliation if reconciliation else "sin_identificador"
    payload["code"] = code or "sin_conciliacion"
    payload["ambiente"] = wompi_service.configured_environment()
    return jsonify(payload), 200


def _reconciliar_por_referencia(donation):
    try:
        transaction = wompi_service.fetch_transaction_by_reference(donation.referencia_pago)
    except wompi_service.WompiConfigurationError:
        return {"error": ("wompi_no_configurado", 503)}
    except wompi_service.WompiQueryError as exc:
        return {"error": (exc.code, _wompi_error_status(exc))}
    if not transaction:
        return {"conciliacion": None, "code": "transaccion_no_encontrada"}
    try:
        result = _apply_transaction(donation, transaction)
    except ConciliationError as exc:
        db.session.rollback()
        current_app.logger.warning(
            "Wompi: conciliación por referencia rechazada (%s)", str(exc)
        )
        return {"error": (_conciliation_code(exc), 409)}
    except SQLAlchemyError:
        db.session.rollback()
        current_app.logger.warning("Wompi: conciliación por referencia no persistida")
        return {"error": ("persistencia_no_disponible", 503)}
    return {"conciliacion": result, "code": _result_code(result)}


def reconcile_pending_donations(
    *, limit=50, min_age_minutes=10, max_age_hours=72, now=None
):
    limit = max(1, min(int(limit), 500))
    min_age_minutes = max(0, int(min_age_minutes))
    max_age_hours = max(1, int(max_age_hours))
    now = now or datetime.utcnow()
    donations = (
        DONACION.query.filter(
            DONACION.tipo == "economica",
            DONACION.estado_pago == "pendiente",
            DONACION.referencia_pago.isnot(None),
            DONACION.fecha_donacion <= now - timedelta(minutes=min_age_minutes),
            DONACION.fecha_donacion >= now - timedelta(hours=max_age_hours),
        )
        .order_by(DONACION.fecha_donacion.asc())
        .limit(limit)
        .all()
    )
    resultado = {
        "revisadas": 0,
        "verificadas": 0,
        "sin_transaccion": 0,
        "sin_cambio": 0,
        "errores": 0,
        "detenido_por": None,
    }
    for donation in donations:
        resultado["revisadas"] += 1
        fallback = _reconciliar_por_referencia(donation)
        if fallback.get("error"):
            code, _ = fallback["error"]
            resultado["errores"] += 1
            current_app.logger.warning(
                "Wompi: conciliación de donación %s falló (%s)",
                donation.id_donacion,
                code,
            )
            if code in {
                "proveedor_no_disponible",
                "respuesta_proveedor_invalida",
                "wompi_no_configurado",
                "consulta_no_configurada",
                "persistencia_no_disponible",
            }:
                resultado["detenido_por"] = code
                break
            continue
        if fallback.get("code") == "transaccion_no_encontrada":
            resultado["sin_transaccion"] += 1
        elif fallback.get("conciliacion") == "verificada":
            resultado["verificadas"] += 1
        else:
            resultado["sin_cambio"] += 1
    return resultado


@wompi_bp.post("/webhooks/wompi")
def wompi_webhook():
    config_status = wompi_service.configuration_status()
    if not config_status["ok"]:
        current_app.logger.warning(
            "Wompi webhook no disponible (faltan=%s, problemas=%s)",
            ",".join(config_status["missing"]) or "ninguna",
            ",".join(config_status["issues"]) or "ninguno",
        )
        return jsonify({"error": "No fue posible procesar el evento"}), 503
    payload = request.get_json(silent=True)
    if not isinstance(payload, dict) or not isinstance(payload.get("event"), str):
        return jsonify({"error": "Evento inválido"}), 400
    if payload["event"] != "transaction.updated":
        return jsonify({"received": True}), 200
    checksum = _event_checksum(payload)
    if not wompi_service.verify_event_checksum(payload, request.headers.get("X-Event-Checksum")):
        return jsonify({"error": "Firma de evento inválida"}), 401
    if not wompi_service.environment_matches(payload):
        return jsonify({"error": "Ambiente de evento inválido"}), 401
    retry_after = enforce(
        f"webhook:{client_ip()}",
        "RATE_LIMIT_WEBHOOK_ATTEMPTS",
        "RATE_LIMIT_WEBHOOK_WINDOW",
    )
    if retry_after:
        return too_many_requests(retry_after)
    transaction = payload["data"].get("transaction")
    fingerprint = _event_fingerprint(payload, checksum)
    try:
        _validate_transaction(transaction)
        if PAGO_EVENTO.query.filter_by(huella_evento=fingerprint).first():
            current_app.logger.info("Wompi: evento duplicado %s", fingerprint[:12])
            return jsonify({"received": True}), 200
        authoritative = wompi_service.fetch_transaction(transaction["id"])
        _validate_transaction(authoritative)
        if any(authoritative[field] != transaction[field] for field in ("id", "reference", "amount_in_cents", "currency")):
            raise ConciliationError("evento_no_coincide_con_proveedor")
        if authoritative["status"] != transaction["status"]:
            current_app.logger.info("Wompi: evento con estado desactualizado; se utiliza consulta autoritativa")
        donation = DONACION.query.filter_by(referencia_pago=authoritative["reference"]).first()
        if donation:
            evento = _build_payment_event(payload, checksum, authoritative, "aplicado")
            resultado = _apply_transaction(
                donation,
                authoritative,
                evento=evento,
                origen="webhook",
                estado_observado=transaction.get("status"),
            )
            if resultado == "doble_cobro":
                current_app.logger.warning(
                    "Wompi: posible doble cobro en el evento %s", fingerprint[:12]
                )
            elif resultado == "estado_desactualizado":
                current_app.logger.info(
                    "Wompi: evento %s ignorado por transición terminal", fingerprint[:12]
                )
        else:
            evento = _build_payment_event(payload, checksum, authoritative, "sin_donacion")
            db.session.add(evento)
            db.session.commit()
            current_app.logger.info("Wompi: referencia sin donación local; evento %s registrado", fingerprint[:12])
    except IntegrityError:
        db.session.rollback()
        if PAGO_EVENTO.query.filter_by(huella_evento=fingerprint).first():
            return jsonify({"received": True}), 200
        return _payment_error("conflicto_persistencia", 503)
    except wompi_service.WompiConfigurationError:
        return _payment_error("wompi_no_configurado", 503)
    except wompi_service.WompiQueryError as exc:
        return _payment_error(exc.code, _wompi_error_status(exc))
    except ConciliationError as exc:
        current_app.logger.warning("Wompi: conciliación rechazada (%s)", str(exc))
        return _payment_error(_conciliation_code(exc), 409)
    except SQLAlchemyError:
        return _payment_error("persistencia_no_disponible", 503)
    return jsonify({"received": True}), 200


def _event_checksum(payload):
    signature = payload.get("signature")
    checksum = signature.get("checksum") if isinstance(signature, dict) else None
    checksum = checksum or request.headers.get("X-Event-Checksum")
    return checksum.lower() if isinstance(checksum, str) else None


def _event_fingerprint(payload, checksum):
    transaction = payload.get("data", {}).get("transaction")
    if not isinstance(transaction, dict):
        transaction = {}
    canonical = json.dumps(
        {
            "event": payload.get("event"),
            "timestamp": payload.get("timestamp"),
            "checksum": checksum,
            "id": transaction.get("id"),
            "status": transaction.get("status"),
            "amount_in_cents": transaction.get("amount_in_cents"),
            "reference": transaction.get("reference"),
            "currency": transaction.get("currency"),
        },
        sort_keys=True,
        separators=(",", ":"),
        default=str,
    )
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _build_payment_event(payload, checksum, transaction, resultado):
    return PAGO_EVENTO(
        huella_evento=_event_fingerprint(payload, checksum),
        tipo_evento=payload["event"],
        id_donacion=None,
        referencia=transaction.get("reference"),
        wompi_transaction_id=transaction.get("id"),
        estado_wompi=transaction.get("status"),
        monto_en_centavos=transaction.get("amount_in_cents"),
        moneda=transaction.get("currency"),
        ambiente=payload.get("environment"),
        resultado=resultado,
    )


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


def _attempt_transition_allowed(previous, new_status, method):
    if previous is None or previous == new_status:
        return True
    if previous == "pendiente":
        return True
    if previous == "aprobada" and new_status == "anulada" and method == "CARD":
        return True
    return False


def _find_or_create_attempt(
    donation: DONACION,
    transaction: dict,
    *,
    origen: str,
    estado_observado: str | None,
) -> PAGO_INTENTO:
    transaction_id = transaction["id"]
    attempt = (
        PAGO_INTENTO.query.filter_by(wompi_transaction_id=transaction_id)
        .with_for_update()
        .first()
    )
    if attempt:
        if attempt.id_donacion != donation.id_donacion:
            raise ConciliationError("transaccion_ya_asociada")
        if (
            attempt.referencia != transaction["reference"]
            or attempt.monto_en_centavos != transaction["amount_in_cents"]
            or attempt.moneda != transaction["currency"]
        ):
            raise ConciliationError("intento_no_coincide")
        return attempt

    other = DONACION.query.filter(
        DONACION.wompi_transaction_id == transaction_id,
        DONACION.id_donacion != donation.id_donacion,
    ).first()
    if other:
        raise ConciliationError("transaccion_ya_asociada")

    if (
        donation.wompi_transaction_id
        and donation.wompi_transaction_id != transaction_id
        and donation.estado_pago != "aprobada"
    ):
        raise ConciliationError("conciliacion_historica_pendiente")

    attempt = PAGO_INTENTO(
        id_donacion=donation.id_donacion,
        wompi_transaction_id=transaction_id,
        referencia=transaction["reference"],
        estado_observado=estado_observado or transaction["status"],
        estado_autoritativo=transaction["status"],
        estado_local=wompi_service.map_status(transaction["status"]),
        resultado="pendiente",
        monto_en_centavos=transaction["amount_in_cents"],
        moneda=transaction["currency"],
        metodo_pago=transaction.get("payment_method_type"),
        origen=origen,
    )
    db.session.add(attempt)
    db.session.flush()
    return attempt


def _audit_payment(donation: DONACION, new_status: str) -> None:
    description = f"Pago Wompi {new_status} para donación {donation.id_donacion}"
    audit = AUDITORIA.query.filter_by(
        accion="DONACION_PAGO",
        entidad="DONACION",
        id_entidad=donation.id_donacion,
        descripcion=description,
    ).first()
    if not audit:
        registrar(
            id_usuario=donation.id_donante,
            accion="DONACION_PAGO",
            descripcion=description,
            entidad="DONACION",
            id_entidad=donation.id_donacion,
            direccion_ip=request.remote_addr if has_request_context() else None,
            confirmar=False,
        )


def _audit_duplicate(donation: DONACION, approved_id: str, duplicate_id: str) -> None:
    description = (
        f"Posible doble cobro en donación {donation.id_donacion}: "
        f"transacción {duplicate_id} además de {approved_id}"
    )
    audit = AUDITORIA.query.filter_by(
        accion="PAGO_DUPLICADO",
        entidad="DONACION",
        id_entidad=donation.id_donacion,
        descripcion=description,
    ).first()
    if not audit:
        registrar(
            id_usuario=donation.id_donante,
            accion="PAGO_DUPLICADO",
            descripcion=description,
            entidad="DONACION",
            id_entidad=donation.id_donacion,
            direccion_ip=request.remote_addr if has_request_context() else None,
            confirmar=False,
        )


def _apply_transaction(
    donation: DONACION,
    transaction: dict,
    *,
    evento=None,
    origen: str = "status",
    estado_observado: str | None = None,
) -> str:
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
    new_status = wompi_service.map_status(transaction["status"])
    attempt = _find_or_create_attempt(
        donation,
        transaction,
        origen=origen,
        estado_observado=estado_observado,
    )
    previous_attempt_status = attempt.estado_local
    if not _attempt_transition_allowed(
        previous_attempt_status, new_status, transaction.get("payment_method_type")
    ):
        result = "estado_desactualizado"
        if evento is not None:
            evento.id_donacion = donation.id_donacion
            evento.resultado = "ignorado"
            db.session.add(evento)
        db.session.commit()
        return result

    attempt.estado_observado = estado_observado or attempt.estado_observado
    attempt.estado_autoritativo = transaction["status"]
    attempt.estado_local = new_status
    attempt.metodo_pago = transaction.get("payment_method_type") or attempt.metodo_pago
    attempt.origen = origen

    result = "verificada"
    if new_status == "aprobada":
        if donation.estado_pago == "aprobada":
            if donation.wompi_transaction_id == transaction_id:
                attempt.resultado = "acreditado"
                recalculate_campaign_progress(campaign, confirmar=False)
                _audit_payment(donation, new_status)
            elif donation.wompi_transaction_id:
                attempt.resultado = "duplicado"
                result = "doble_cobro"
                _audit_duplicate(
                    donation, donation.wompi_transaction_id, transaction_id
                )
            else:
                raise ConciliationError("conciliacion_aprobacion_sin_transaccion")
        else:
            other_approved = PAGO_INTENTO.query.filter(
                PAGO_INTENTO.id_donacion == donation.id_donacion,
                PAGO_INTENTO.estado_local == "aprobada",
                PAGO_INTENTO.id_intento != attempt.id_intento,
            ).first()
            if other_approved:
                attempt.resultado = "duplicado"
                result = "doble_cobro"
                _audit_duplicate(
                    donation,
                    other_approved.wompi_transaction_id,
                    transaction_id,
                )
            elif donation.estado_pago == "anulada" and donation.fecha_pago:
                attempt.resultado = "duplicado"
                result = "doble_cobro"
                _audit_duplicate(
                    donation,
                    donation.wompi_transaction_id or "sin_transaccion_aprobada",
                    transaction_id,
                )
            else:
                donation.estado_pago = "aprobada"
                donation.wompi_transaction_id = transaction_id
                if transaction.get("payment_method_type"):
                    donation.metodo_pago = transaction["payment_method_type"]
                if not donation.fecha_pago:
                    donation.fecha_pago = datetime.utcnow()
                attempt.resultado = "acreditado"
                recalculate_campaign_progress(campaign, confirmar=False)
                _audit_payment(donation, new_status)
    elif new_status == "anulada":
        if (
            donation.estado_pago == "aprobada"
            and donation.wompi_transaction_id == transaction_id
        ):
            donation.estado_pago = "anulada"
            attempt.resultado = "anulado"
            recalculate_campaign_progress(campaign, confirmar=False)
            _audit_payment(donation, new_status)
        elif donation.estado_pago == "pendiente":
            donation.estado_pago = "anulada"
            attempt.resultado = "anulado"
            _audit_payment(donation, new_status)
        else:
            attempt.resultado = (
                "anulado" if previous_attempt_status == "aprobada" else "ignorado"
            )
            result = "estado_desactualizado"
    else:
        if donation.estado_pago == "aprobada":
            attempt.resultado = "ignorado"
            result = "estado_desactualizado"
        elif donation.estado_pago in ("pendiente", new_status):
            donation.estado_pago = new_status
            if transaction.get("payment_method_type"):
                donation.metodo_pago = transaction["payment_method_type"]
            attempt.resultado = (
                "pendiente" if new_status == "pendiente" else "ignorado"
            )
            _audit_payment(donation, new_status)
        else:
            attempt.resultado = "ignorado"
            result = "estado_desactualizado"

    if evento is not None:
        evento.id_donacion = donation.id_donacion
        evento.resultado = "aplicado" if result == "verificada" else "ignorado"
        db.session.add(evento)
    db.session.commit()
    return result
