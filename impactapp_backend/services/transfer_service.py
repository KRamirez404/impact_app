import hashlib
import json
import re
import secrets
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

from flask import current_app
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from models import CAMPAÑA, DONACION, db
from models.asignacion_financiera import ASIGNACION_FINANCIERA
from models.transfer import (
    COMPROBANTE_TRANSFERENCIA,
    CUENTA_RECAUDO,
    TRANSFERENCIA_BANCARIA,
    TRANSFERENCIA_EVENTO,
)
from services.audit_service import registrar
from services.autorizacion_financiera import (
    administrador_financiero,
    usuario_financiero,
)
from services.campaign_service import recalculate_campaign_progress
from services.donation_integrity import (
    compute_donation_checksum,
    donation_is_intact,
)
from services.private_storage import delete_receipt, read_receipt, resolve_receipt, store_receipt
from services.transfer_crypto import (
    decrypt_account_number,
    encrypt_account_number,
    hash_account_number,
    last_four,
    normalize_account_number,
)
from services.transfer_errors import TransferError

MAX_AMOUNT = Decimal("9999999999.99")
TRANSFER_STATES = {"registrada", "en_revision", "aprobada", "rechazada"}


def _int(value, name):
    if type(value) is not int or not 0 < value <= 2147483647:
        raise TransferError("transfer_validation", 400, f"{name} inválido")
    return value


def _page(value):
    try:
        page = int(value or 1)
    except (TypeError, ValueError):
        return 1
    return max(1, page)


def _text(value, name, minimum=1, maximum=500, required=True):
    if value is None and not required:
        return None
    if not isinstance(value, str):
        raise TransferError("transfer_validation", 400, f"{name} inválido")
    value = value.strip()
    if not minimum <= len(value) <= maximum:
        raise TransferError("transfer_validation", 400, f"{name} inválido")
    return value


def _decimal(value):
    if isinstance(value, bool):
        raise TransferError("transfer_validation", 400, "Monto inválido")
    try:
        number = Decimal(str(value))
    except (InvalidOperation, ValueError, TypeError):
        raise TransferError("transfer_validation", 400, "Monto inválido")
    if not number.is_finite() or number <= 0 or number > MAX_AMOUNT:
        raise TransferError("transfer_validation", 400, "Monto inválido")
    if number != number.quantize(Decimal("0.01")):
        raise TransferError("transfer_validation", 400, "Monto inválido")
    return number


def _date(value):
    if not isinstance(value, str):
        raise TransferError("transfer_validation", 400, "Fecha inválida")
    try:
        parsed = date.fromisoformat(value)
    except ValueError:
        raise TransferError("transfer_validation", 400, "Fecha inválida")
    if parsed > date.today():
        raise TransferError("transfer_validation", 400, "La fecha no puede ser futura")
    return parsed


def _reference(value):
    if not isinstance(value, str):
        raise TransferError("transfer_validation", 400, "Referencia bancaria inválida")
    normalized = re.sub(r"\s+", " ", value.strip())
    if not 1 <= len(normalized) <= 100:
        raise TransferError("transfer_validation", 400, "Referencia bancaria inválida")
    return normalized


def _key(actor, operation, value, extra=""):
    if not isinstance(value, str) or not value.strip() or len(value) > 128:
        raise TransferError(
            "idempotency_required",
            400,
            "Idempotency-Key es obligatoria y admite hasta 128 caracteres",
        )
    scope = f"{actor.id_usuario}:{operation}:{extra}:{value.strip()}"
    return hashlib.sha256(scope.encode("utf-8")).hexdigest()


def _fingerprint(payload):
    canonical = json.dumps(payload, sort_keys=True, separators=(",", ":"), default=str)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def _audit(actor, action, description, entity, entity_id, ip, confirmar=False):
    registrar(
        id_usuario=actor.id_usuario,
        accion=action,
        descripcion=description,
        entidad=entity,
        id_entidad=entity_id,
        direccion_ip=ip,
        confirmar=confirmar,
    )


def _event(transfer, actor, action, previous, new, reason, key, fingerprint, ip):
    existing = TRANSFERENCIA_EVENTO.query.filter_by(clave_idempotencia=key).first()
    if existing:
        if (
            existing.id_transferencia != transfer.id_transferencia
            or existing.accion != action
            or existing.huella_solicitud != fingerprint
        ):
            raise TransferError(
                "idempotency_conflict",
                409,
                "Idempotency-Key ya utilizada con otros datos",
            )
        return existing, False
    event = TRANSFERENCIA_EVENTO(
        id_transferencia=transfer.id_transferencia,
        accion=action,
        estado_anterior=previous,
        estado_nuevo=new,
        id_actor=actor.id_usuario,
        motivo=reason,
        clave_idempotencia=key,
        huella_solicitud=fingerprint,
    )
    db.session.add(event)
    _audit(
        actor,
        f"TRANSFERENCIA_{action.upper()}",
        f"Transferencia {transfer.id_transferencia}: {previous or 'nueva'} -> {new}",
        "TRANSFERENCIA_BANCARIA",
        transfer.id_transferencia,
        ip,
    )
    return event, True


def _latest_receipt(transfer):
    return (
        COMPROBANTE_TRANSFERENCIA.query.filter_by(
            id_transferencia=transfer.id_transferencia,
            estado_tecnico="validado",
        )
        .order_by(COMPROBANTE_TRANSFERENCIA.version.desc())
        .first()
    )


def _account_summary(account):
    return {
        "id_cuenta_recaudo": account.id_cuenta_recaudo,
        "banco": account.banco,
        "tipo_cuenta": account.tipo_cuenta,
        "numero_cuenta": f"****{account.ultimos4}",
        "titular": account.titular,
        "moneda": account.moneda,
        "estado": account.estado,
    }


def _account_for_donor(account):
    data = _account_summary(account)
    data["numero_cuenta"] = decrypt_account_number(account.numero_cuenta_cifrado)
    return data


def _transfer_payload(transfer, include_donor=False):
    data = transfer.to_dict()
    data["cuenta"] = _account_summary(transfer.cuenta)
    receipt = _latest_receipt(transfer)
    data["comprobante"] = receipt.to_dict() if receipt else None
    data["campania"] = {
        "id_campania": transfer.campania.id_campania,
        "titulo": transfer.campania.titulo,
        "estado": transfer.campania.estado,
        "eliminada": bool(transfer.campania.eliminada),
    }
    if include_donor and transfer.donante:
        data["donante"] = {
            "id_usuario": transfer.donante.id_usuario,
            "nombre": transfer.donante.nombre,
            "apellido": transfer.donante.apellido,
        }
    return data


def _lock_campaign(id_campania):
    campaign = (
        CAMPAÑA.query.filter_by(id_campania=id_campania)
        .populate_existing()
        .with_for_update()
        .first()
    )
    if campaign is None:
        raise TransferError("campaign_not_found", 404, "Campaña no encontrada")
    return campaign


def _lock_transfer(id_transferencia):
    transfer = (
        TRANSFERENCIA_BANCARIA.query.filter_by(id_transferencia=id_transferencia)
        .populate_existing()
        .with_for_update()
        .first()
    )
    if transfer is None:
        raise TransferError("transfer_not_found", 404, "Transferencia no encontrada")
    return transfer


def _lock_donation(id_donacion):
    donation = (
        DONACION.query.filter_by(id_donacion=id_donacion)
        .populate_existing()
        .with_for_update()
        .first()
    )
    if donation is None:
        raise TransferError("donation_not_found", 404, "Donación no encontrada")
    return donation


def configuration_status():
    from services.transfer_config import configuration_status as status

    return status()


def create_account(actor, data, key, ip):
    administrador_financiero()
    id_campania = _int(data.get("id_campania"), "id_campania")
    banco = _text(data.get("banco"), "banco", 2, 100)
    tipo = data.get("tipo_cuenta")
    if tipo not in ("ahorros", "corriente"):
        raise TransferError("transfer_validation", 400, "tipo_cuenta inválido")
    titular = _text(data.get("titular"), "titular", 2, 150)
    if data.get("moneda", "COP") != "COP":
        raise TransferError("transfer_validation", 400, "La moneda debe ser COP")
    number = normalize_account_number(data.get("numero_cuenta"))
    fingerprint = _fingerprint(
        {
            "id_campania": id_campania,
            "banco": banco,
            "tipo_cuenta": tipo,
            "titular": titular,
            "numero_cuenta": number,
            "moneda": "COP",
        }
    )
    request_key = _key(actor, "crear_cuenta", key)
    previous = CUENTA_RECAUDO.query.filter_by(clave_idempotencia=request_key).first()
    if previous:
        if previous.huella_solicitud != fingerprint:
            raise TransferError(
                "idempotency_conflict",
                409,
                "Idempotency-Key ya utilizada con otros datos",
            )
        return previous, False
    campaign = _lock_campaign(id_campania)
    previous = CUENTA_RECAUDO.query.filter_by(clave_idempotencia=request_key).first()
    if previous:
        if previous.huella_solicitud != fingerprint:
            raise TransferError(
                "idempotency_conflict",
                409,
                "Idempotency-Key ya utilizada con otros datos",
            )
        return previous, False
    if campaign.eliminada:
        raise TransferError("campaign_not_found", 404, "Campaña no encontrada")
    account_hash = hash_account_number(number)
    duplicate = CUENTA_RECAUDO.query.filter_by(
        id_campania=id_campania, numero_cuenta_hash=account_hash
    ).first()
    if duplicate:
        raise TransferError("account_duplicate", 409, "La cuenta ya está registrada")
    verified = CUENTA_RECAUDO.query.filter_by(
        id_campania=id_campania, estado="verificada"
    ).first()
    if verified:
        raise TransferError(
            "account_already_verified",
            409,
            "La campaña ya tiene una cuenta verificada vigente",
        )
    account = CUENTA_RECAUDO(
        id_campania=id_campania,
        banco=banco,
        tipo_cuenta=tipo,
        numero_cuenta_cifrado=encrypt_account_number(number),
        numero_cuenta_hash=account_hash,
        ultimos4=last_four(number),
        titular=titular,
        moneda="COP",
        estado="pendiente_verificacion",
        clave_idempotencia=request_key,
        huella_solicitud=fingerprint,
    )
    db.session.add(account)
    db.session.flush()
    _audit(
        actor,
        "CUENTA_RECAUDO_CREADA",
        f"Cuenta de recaudo {account.id_cuenta_recaudo} creada para campaña {id_campania}",
        "CUENTA_RECAUDO",
        account.id_cuenta_recaudo,
        ip,
    )
    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        previous = CUENTA_RECAUDO.query.filter_by(clave_idempotencia=request_key).first()
        if previous and previous.huella_solicitud == fingerprint:
            return previous, False
        raise TransferError("account_duplicate", 409, "La cuenta ya está registrada")
    return account, True


def verify_account(actor, id_cuenta, ip):
    administrador_financiero()
    account = CUENTA_RECAUDO.query.filter_by(
        id_cuenta_recaudo=id_cuenta
    ).first()
    if account is None:
        raise TransferError("account_not_found", 404, "Cuenta no encontrada")
    campaign = _lock_campaign(account.id_campania)
    account = (
        CUENTA_RECAUDO.query.filter_by(id_cuenta_recaudo=id_cuenta)
        .populate_existing()
        .with_for_update()
        .first()
    )
    if account is None:
        raise TransferError("account_not_found", 404, "Cuenta no encontrada")
    if campaign.eliminada:
        raise TransferError("campaign_not_found", 404, "Campaña no encontrada")
    if account.estado == "verificada":
        return account, False
    if account.estado == "revocada":
        raise TransferError("account_revoked", 409, "La cuenta está revocada")
    verified = CUENTA_RECAUDO.query.filter(
        CUENTA_RECAUDO.id_campania == account.id_campania,
        CUENTA_RECAUDO.estado == "verificada",
        CUENTA_RECAUDO.id_cuenta_recaudo != account.id_cuenta_recaudo,
    ).first()
    if verified:
        raise TransferError(
            "account_already_verified",
            409,
            "La campaña ya tiene una cuenta verificada vigente",
        )
    account.estado = "verificada"
    account.id_verificador = actor.id_usuario
    account.fecha_verificacion = datetime.utcnow()
    _audit(
        actor,
        "CUENTA_RECAUDO_VERIFICADA",
        f"Cuenta de recaudo {account.id_cuenta_recaudo} verificada",
        "CUENTA_RECAUDO",
        account.id_cuenta_recaudo,
        ip,
    )
    db.session.commit()
    return account, True


def revoke_account(actor, id_cuenta, motivo, ip):
    administrador_financiero()
    reason = _text(motivo, "motivo", 1, 500)
    account = (
        CUENTA_RECAUDO.query.filter_by(id_cuenta_recaudo=id_cuenta)
        .populate_existing()
        .with_for_update()
        .first()
    )
    if account is None:
        raise TransferError("account_not_found", 404, "Cuenta no encontrada")
    if account.estado == "revocada":
        return account, False
    account.estado = "revocada"
    account.id_revocador = actor.id_usuario
    account.fecha_revocacion = datetime.utcnow()
    account.motivo_revocacion = reason
    _audit(
        actor,
        "CUENTA_RECAUDO_REVOCADA",
        f"Cuenta de recaudo {account.id_cuenta_recaudo} revocada",
        "CUENTA_RECAUDO",
        account.id_cuenta_recaudo,
        ip,
    )
    db.session.commit()
    return account, True


def list_accounts(actor, page=1):
    administrador_financiero()
    page = _page(page)
    rows = (
        CUENTA_RECAUDO.query.order_by(CUENTA_RECAUDO.id_cuenta_recaudo)
        .limit(50)
        .offset((page - 1) * 50)
        .all()
    )
    return [_account_summary(account) for account in rows], page


def get_account_admin(actor, id_cuenta):
    administrador_financiero()
    account = CUENTA_RECAUDO.query.filter_by(id_cuenta_recaudo=id_cuenta).first()
    if account is None:
        raise TransferError("account_not_found", 404, "Cuenta no encontrada")
    data = account.to_dict()
    data["numero_cuenta"] = decrypt_account_number(account.numero_cuenta_cifrado)
    return data


def get_account_for_donor(actor, id_campania):
    campaign = CAMPAÑA.query.filter_by(id_campania=id_campania).first()
    if campaign is None or campaign.eliminada or campaign.estado != "activa":
        raise TransferError("campaign_not_found", 404, "Campaña no disponible")
    account = CUENTA_RECAUDO.query.filter_by(
        id_campania=id_campania, estado="verificada"
    ).first()
    if account is None:
        raise TransferError("account_not_found", 404, "La campaña no tiene cuenta verificada")
    return _account_for_donor(account)


def _validate_transfer_data(data):
    id_campania = _int(data.get("id_campania"), "id_campania")
    id_cuenta = _int(data.get("id_cuenta_recaudo"), "id_cuenta_recaudo")
    amount = _decimal(data.get("monto"))
    if amount < Decimal(str(current_app.config.get("TRANSFER_MIN_AMOUNT", 1000))):
        raise TransferError("transfer_validation", 400, "Monto inferior al mínimo")
    if data.get("moneda", "COP") != "COP":
        raise TransferError("transfer_validation", 400, "La moneda debe ser COP")
    reference = _reference(data.get("referencia_bancaria"))
    transfer_date = _date(data.get("fecha_transferencia"))
    description = data.get("descripcion")
    if description is not None:
        description = _text(description, "descripcion", 0, 500, required=False)
    return id_campania, id_cuenta, amount, reference, transfer_date, description


def create_transfer(actor, data, key, ip):
    id_campania, id_cuenta, amount, reference, transfer_date, description = (
        _validate_transfer_data(data)
    )
    fingerprint = _fingerprint(
        {
            "id_campania": id_campania,
            "id_cuenta_recaudo": id_cuenta,
            "monto": str(amount),
            "moneda": "COP",
            "referencia_bancaria": reference,
            "fecha_transferencia": transfer_date.isoformat(),
            "descripcion": description,
        }
    )
    request_key = _key(actor, "crear_transferencia", key)
    previous = TRANSFERENCIA_BANCARIA.query.filter_by(
        clave_idempotencia=request_key
    ).first()
    if previous:
        if previous.huella_solicitud != fingerprint:
            raise TransferError(
                "idempotency_conflict",
                409,
                "Idempotency-Key ya utilizada con otros datos",
            )
        return previous, False
    campaign = _lock_campaign(id_campania)
    previous = TRANSFERENCIA_BANCARIA.query.filter_by(
        clave_idempotencia=request_key
    ).first()
    if previous:
        if previous.huella_solicitud != fingerprint:
            raise TransferError(
                "idempotency_conflict",
                409,
                "Idempotency-Key ya utilizada con otros datos",
            )
        return previous, False
    if campaign.eliminada or campaign.estado != "activa":
        raise TransferError("campaign_not_found", 404, "Campaña no disponible")
    account = (
        CUENTA_RECAUDO.query.filter_by(
            id_cuenta_recaudo=id_cuenta,
            id_campania=id_campania,
            estado="verificada",
        )
        .with_for_update()
        .first()
    )
    if account is None:
        raise TransferError(
            "account_not_verified", 409, "La cuenta de recaudo no está verificada"
        )
    duplicate = TRANSFERENCIA_BANCARIA.query.filter_by(
        id_cuenta_recaudo=id_cuenta,
        referencia_bancaria=reference,
    ).first()
    if duplicate:
        raise TransferError(
            "transfer_duplicate", 409, "La referencia bancaria ya está registrada"
        )
    donation = DONACION(
        id_campania=id_campania,
        id_donante=actor.id_usuario,
        tipo="economica",
        monto_estimado=amount,
        descripcion=description,
        estado_pago="pendiente",
        metodo_pago="transferencia",
    )
    db.session.add(donation)
    db.session.flush()
    donation.referencia_pago = f"TRF-{donation.id_donacion}-{secrets.token_hex(4)}"
    donation.checksum = compute_donation_checksum(
        donation, current_app.config["JWT_SECRET_KEY"]
    )
    transfer = TRANSFERENCIA_BANCARIA(
        id_donacion=donation.id_donacion,
        id_donante=actor.id_usuario,
        id_campania=id_campania,
        id_cuenta_recaudo=id_cuenta,
        monto_declarado=amount,
        moneda="COP",
        referencia_bancaria=reference,
        fecha_transferencia=transfer_date,
        descripcion=description,
        estado="registrada",
        clave_idempotencia=request_key,
        huella_solicitud=fingerprint,
    )
    db.session.add(transfer)
    db.session.flush()
    _event(
        transfer,
        actor,
        "registrada",
        None,
        "registrada",
        None,
        _key(actor, "registrar_transferencia", key, transfer.id_transferencia),
        fingerprint,
        ip,
    )
    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        previous = TRANSFERENCIA_BANCARIA.query.filter_by(
            clave_idempotencia=request_key
        ).first()
        if previous and previous.huella_solicitud == fingerprint:
            return previous, False
        raise TransferError(
            "transfer_duplicate", 409, "La referencia bancaria ya está registrada"
        )
    return transfer, True


def list_my_transfers(actor, page=1):
    page = _page(page)
    rows = (
        TRANSFERENCIA_BANCARIA.query.filter_by(id_donante=actor.id_usuario)
        .order_by(TRANSFERENCIA_BANCARIA.creado_en.desc())
        .limit(50)
        .offset((page - 1) * 50)
        .all()
    )
    return [_transfer_payload(row) for row in rows], page


def get_transfer(actor, id_transferencia, support=False):
    transfer = TRANSFERENCIA_BANCARIA.query.filter_by(
        id_transferencia=id_transferencia
    ).first()
    if transfer is None:
        raise TransferError("transfer_not_found", 404, "Transferencia no encontrada")
    if support:
        _support_capacity(actor, transfer.id_campania, ("revision", "contabilizacion"))
        return _transfer_payload(transfer, include_donor=True)
    if transfer.id_donante != actor.id_usuario:
        raise TransferError("transfer_not_found", 404, "Transferencia no encontrada")
    return _transfer_payload(transfer)


def _support_capacity(actor, id_campania, capacities):
    user = usuario_financiero()
    if user.id_usuario != actor.id_usuario or user.rol != "soporte":
        raise TransferError("transfer_forbidden", 403, "Acceso denegado")
    assignment = ASIGNACION_FINANCIERA.query.filter_by(
        id_usuario=actor.id_usuario,
        id_campania=id_campania,
    ).all()
    for item in assignment:
        if item.capacidad in capacities and item.vigente():
            return user
    raise TransferError("transfer_forbidden", 403, "Asignación financiera no vigente")


def list_queue(actor, estado=None, page=1):
    user = usuario_financiero()
    if user.rol != "soporte":
        raise TransferError("transfer_forbidden", 403, "Acceso denegado")
    assignments = ASIGNACION_FINANCIERA.query.filter_by(
        id_usuario=actor.id_usuario
    ).all()
    campaign_ids = {
        item.id_campania
        for item in assignments
        if item.capacidad in ("revision", "contabilizacion") and item.vigente()
    }
    if not campaign_ids:
        return [], 1
    query = TRANSFERENCIA_BANCARIA.query.filter(
        TRANSFERENCIA_BANCARIA.id_campania.in_(campaign_ids)
    )
    if estado:
        if estado not in TRANSFER_STATES:
            raise TransferError("transfer_validation", 400, "Estado inválido")
        query = query.filter(TRANSFERENCIA_BANCARIA.estado == estado)
    page = _page(page)
    rows = (
        query.order_by(TRANSFERENCIA_BANCARIA.creado_en.desc())
        .limit(50)
        .offset((page - 1) * 50)
        .all()
    )
    return [_transfer_payload(row, include_donor=True) for row in rows], page


def claim_transfer(actor, id_transferencia, key, ip):
    transfer = TRANSFERENCIA_BANCARIA.query.filter_by(
        id_transferencia=id_transferencia
    ).first()
    if transfer is None:
        raise TransferError("transfer_not_found", 404, "Transferencia no encontrada")
    _support_capacity(actor, transfer.id_campania, ("revision",))
    previous = transfer.estado
    request_key = _key(actor, "reclamar_transferencia", key, id_transferencia)
    fingerprint = _fingerprint({"accion": "en_revision", "id": id_transferencia})
    existing_event = TRANSFERENCIA_EVENTO.query.filter_by(
        clave_idempotencia=request_key
    ).first()
    if existing_event:
        if existing_event.huella_solicitud != fingerprint:
            raise TransferError("idempotency_conflict", 409, "Clave ya utilizada")
        return _transfer_payload(transfer, include_donor=True), False
    _lock_campaign(transfer.id_campania)
    transfer = _lock_transfer(id_transferencia)
    if transfer.estado == "en_revision":
        if transfer.id_revisor == actor.id_usuario:
            return _transfer_payload(transfer, include_donor=True), False
        raise TransferError("transfer_already_reviewed", 409, "Ya está en revisión")
    if transfer.estado != "registrada":
        raise TransferError("transfer_state_conflict", 409, "Estado incompatible")
    if _latest_receipt(transfer) is None:
        raise TransferError("receipt_required", 409, "Falta el comprobante")
    transfer.estado = "en_revision"
    transfer.id_revisor = actor.id_usuario
    transfer.fecha_revision = datetime.utcnow()
    _event(
        transfer,
        actor,
        "en_revision",
        previous,
        "en_revision",
        None,
        request_key,
        fingerprint,
        ip,
    )
    db.session.commit()
    return _transfer_payload(transfer, include_donor=True), True


def reject_transfer(actor, id_transferencia, motivo, key, ip):
    reason = _text(motivo, "motivo", 1, 500)
    transfer = TRANSFERENCIA_BANCARIA.query.filter_by(
        id_transferencia=id_transferencia
    ).first()
    if transfer is None:
        raise TransferError("transfer_not_found", 404, "Transferencia no encontrada")
    _support_capacity(actor, transfer.id_campania, ("revision",))
    request_key = _key(actor, "rechazar_transferencia", key, id_transferencia)
    fingerprint = _fingerprint({"accion": "rechazada", "id": id_transferencia, "motivo": reason})
    existing_event = TRANSFERENCIA_EVENTO.query.filter_by(
        clave_idempotencia=request_key
    ).first()
    if existing_event:
        if existing_event.huella_solicitud != fingerprint:
            raise TransferError("idempotency_conflict", 409, "Clave ya utilizada")
        return _transfer_payload(transfer, include_donor=True), False
    _lock_campaign(transfer.id_campania)
    donation = _lock_donation(transfer.id_donacion)
    transfer = _lock_transfer(id_transferencia)
    if donation.estado_pago != "pendiente":
        raise TransferError("donation_state_conflict", 409, "Donación no pendiente")
    if transfer.estado == "aprobada":
        raise TransferError("transfer_state_conflict", 409, "La transferencia está aprobada")
    if transfer.estado == "rechazada":
        raise TransferError("transfer_state_conflict", 409, "La transferencia ya está rechazada")
    if transfer.estado == "en_revision" and transfer.id_revisor not in (None, actor.id_usuario):
        raise TransferError("transfer_already_reviewed", 409, "Otro revisor la tiene")
    previous = transfer.estado
    transfer.estado = "rechazada"
    transfer.id_revisor = transfer.id_revisor or actor.id_usuario
    transfer.fecha_revision = datetime.utcnow()
    transfer.motivo_rechazo = reason
    donation.estado_pago = "rechazada"
    _event(
        transfer,
        actor,
        "rechazada",
        previous,
        "rechazada",
        reason,
        request_key,
        fingerprint,
        ip,
    )
    db.session.commit()
    return _transfer_payload(transfer, include_donor=True), True


def approve_transfer(actor, id_transferencia, nota, key, ip):
    transfer = TRANSFERENCIA_BANCARIA.query.filter_by(
        id_transferencia=id_transferencia
    ).first()
    if transfer is None:
        raise TransferError("transfer_not_found", 404, "Transferencia no encontrada")
    _support_capacity(actor, transfer.id_campania, ("contabilizacion",))
    request_key = _key(actor, "aprobar_transferencia", key, id_transferencia)
    fingerprint = _fingerprint(
        {"accion": "aprobada", "id": id_transferencia, "nota": nota or ""}
    )
    existing_event = TRANSFERENCIA_EVENTO.query.filter_by(
        clave_idempotencia=request_key
    ).first()
    if existing_event:
        if existing_event.huella_solicitud != fingerprint:
            raise TransferError("idempotency_conflict", 409, "Clave ya utilizada")
        return _transfer_payload(transfer, include_donor=True), False
    campaign = _lock_campaign(transfer.id_campania)
    donation = _lock_donation(transfer.id_donacion)
    transfer = _lock_transfer(id_transferencia)
    if transfer.estado == "aprobada":
        raise TransferError("transfer_state_conflict", 409, "Ya está aprobada")
    if transfer.estado != "en_revision":
        raise TransferError("transfer_state_conflict", 409, "Estado incompatible")
    if not transfer.id_revisor or transfer.id_revisor == actor.id_usuario:
        raise TransferError("double_control_required", 409, "Se requiere un revisor distinto")
    if campaign.eliminada:
        raise TransferError("campaign_not_found", 404, "Campaña no disponible")
    account = transfer.cuenta
    if account is None or account.estado != "verificada":
        raise TransferError("account_not_verified", 409, "Cuenta no vigente")
    receipt = _latest_receipt(transfer)
    if receipt is None:
        raise TransferError("receipt_required", 409, "Falta el comprobante")
    try:
        resolve_receipt(receipt.clave_almacenamiento)
    except TransferError as exc:
        if exc.code != "receipt_not_found":
            raise
        raise TransferError(
            "receipt_not_found",
            409,
            "El comprobante no está disponible para verificación",
        )
    if donation.estado_pago != "pendiente":
        raise TransferError("donation_state_conflict", 409, "Donación no pendiente")
    if not donation_is_intact(
        donation, current_app.config["JWT_SECRET_KEY"]
    ):
        raise TransferError(
            "donation_integrity_conflict",
            409,
            "La donación no supera la verificación de integridad",
        )
    if (
        donation.tipo != "economica"
        or transfer.id_donante != donation.id_donante
        or transfer.id_campania != donation.id_campania
        or account.id_campania != transfer.id_campania
        or transfer.monto_declarado != donation.monto_estimado
        or transfer.moneda != "COP"
    ):
        raise TransferError("transfer_conflict", 409, "Datos financieros inconsistentes")
    if nota is not None:
        nota = _text(nota, "nota", 0, 500, required=False)
    transfer.estado = "aprobada"
    transfer.id_aprobador = actor.id_usuario
    transfer.fecha_aprobacion = datetime.utcnow()
    donation.estado_pago = "aprobada"
    donation.fecha_pago = datetime.utcnow()
    recalculate_campaign_progress(campaign, confirmar=False)
    _event(
        transfer,
        actor,
        "aprobada",
        "en_revision",
        "aprobada",
        nota,
        request_key,
        fingerprint,
        ip,
    )
    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        event = TRANSFERENCIA_EVENTO.query.filter_by(
            clave_idempotencia=request_key
        ).first()
        if event and event.huella_solicitud == fingerprint:
            current = TRANSFERENCIA_BANCARIA.query.filter_by(
                id_transferencia=id_transferencia
            ).first()
            if current is not None:
                return _transfer_payload(current, include_donor=True), False
        raise TransferError(
            "transfer_state_conflict",
            409,
            "La transferencia ya fue procesada por otro actor",
        )
    except SQLAlchemyError:
        db.session.rollback()
        raise TransferError(
            "transfer_persistence_unavailable",
            503,
            "No fue posible guardar la aprobación",
        )
    return _transfer_payload(transfer, include_donor=True), True


def add_receipt(actor, id_transferencia, file_storage, ip):
    transfer = TRANSFERENCIA_BANCARIA.query.filter_by(
        id_transferencia=id_transferencia
    ).first()
    if transfer is None or transfer.id_donante != actor.id_usuario:
        raise TransferError("transfer_not_found", 404, "Transferencia no encontrada")
    _lock_campaign(transfer.id_campania)
    donation = _lock_donation(transfer.id_donacion)
    transfer = _lock_transfer(id_transferencia)
    if donation.estado_pago == "aprobada":
        raise TransferError("donation_state_conflict", 409, "Donación ya aprobada")
    if transfer.estado == "aprobada":
        raise TransferError("transfer_state_conflict", 409, "La transferencia está aprobada")
    if transfer.estado not in ("registrada", "rechazada"):
        raise TransferError("transfer_state_conflict", 409, "Estado incompatible")
    receipt_data = read_receipt(file_storage)
    duplicate = COMPROBANTE_TRANSFERENCIA.query.filter_by(
        id_transferencia=id_transferencia,
        sha256=receipt_data.sha256,
    ).first()
    if duplicate:
        if transfer.estado == "rechazada":
            raise TransferError(
                "receipt_duplicate",
                409,
                "Debe adjuntar un comprobante distinto",
            )
        return duplicate.to_dict(), transfer, False
    version = (
        db.session.query(db.func.max(COMPROBANTE_TRANSFERENCIA.version))
        .filter_by(id_transferencia=id_transferencia)
        .scalar()
        or 0
    ) + 1
    storage_key = store_receipt(receipt_data, id_transferencia)
    previous = transfer.estado
    try:
        receipt = COMPROBANTE_TRANSFERENCIA(
            id_transferencia=id_transferencia,
            version=version,
            clave_almacenamiento=storage_key,
            mime=receipt_data.mime,
            tamano_bytes=receipt_data.size,
            sha256=receipt_data.sha256,
            estado_tecnico="validado",
            subido_por=actor.id_usuario,
        )
        db.session.add(receipt)
        transfer.motivo_rechazo = None
        transfer.id_revisor = None
        transfer.fecha_revision = None
        transfer.id_aprobador = None
        transfer.fecha_aprobacion = None
        transfer.estado = "registrada"
        if donation.estado_pago == "rechazada":
            donation.estado_pago = "pendiente"
        _event(
            transfer,
            actor,
            "reenviada" if previous == "rechazada" else "comprobante_cargado",
            previous,
            "registrada",
            None,
            _key(actor, "cargar_comprobante", receipt_data.sha256, id_transferencia),
            _fingerprint(
                {
                    "accion": "comprobante",
                    "id": id_transferencia,
                    "sha256": receipt_data.sha256,
                    "version": version,
                }
            ),
            ip,
        )
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        delete_receipt(storage_key)
        duplicate = COMPROBANTE_TRANSFERENCIA.query.filter_by(
            id_transferencia=id_transferencia,
            sha256=receipt_data.sha256,
        ).first()
        if duplicate:
            return duplicate.to_dict(), transfer, False
        raise TransferError("receipt_duplicate", 409, "Conflicto de comprobante")
    except SQLAlchemyError:
        db.session.rollback()
        delete_receipt(storage_key)
        raise TransferError(
            "receipt_storage_unavailable",
            503,
            "No fue posible guardar el comprobante",
        )
    return receipt.to_dict(), transfer, True


def receipt_path(actor, id_transferencia, support=False):
    transfer = TRANSFERENCIA_BANCARIA.query.filter_by(
        id_transferencia=id_transferencia
    ).first()
    if transfer is None:
        raise TransferError("transfer_not_found", 404, "Transferencia no encontrada")
    if support:
        _support_capacity(actor, transfer.id_campania, ("revision", "contabilizacion"))
    elif transfer.id_donante != actor.id_usuario:
        raise TransferError("transfer_not_found", 404, "Transferencia no encontrada")
    receipt = _latest_receipt(transfer)
    if receipt is None:
        raise TransferError("receipt_not_found", 404, "Comprobante no encontrado")
    return resolve_receipt(receipt.clave_almacenamiento), receipt


def latest_receipt_metadata(transfer):
    receipt = _latest_receipt(transfer)
    return receipt.to_dict() if receipt else None
