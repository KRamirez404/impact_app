from flask import Blueprint, jsonify, request, send_file
from flask_jwt_extended import jwt_required
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from models import db
from services import transfer_service
from services.authorization import current_user, is_support, require_role
from services.autorizacion_financiera import ErrorFinanciero
from services.transfer_errors import TransferError

transfer_bp = Blueprint("transfer_bp", __name__, url_prefix="/api")


@transfer_bp.after_request
def respuesta_privada(response):
    response.headers["Cache-Control"] = "private, no-store"
    response.headers["X-Content-Type-Options"] = "nosniff"
    return response


@transfer_bp.errorhandler(TransferError)
def error_transferencia(error):
    db.session.rollback()
    return jsonify({"error": error.message, "code": error.code}), error.status


@transfer_bp.errorhandler(ErrorFinanciero)
def error_financiero(error):
    db.session.rollback()
    mensaje = str(error)
    if "no habilitado" in mensaje.lower():
        return (
            jsonify(
                {
                    "error": "El módulo de transferencias no está habilitado",
                    "code": "transfer_approval_disabled",
                }
            ),
            503,
        )
    return (
        jsonify({"error": mensaje, "code": "financial_forbidden"}),
        error.estado,
    )


@transfer_bp.errorhandler(IntegrityError)
def error_integridad(_error):
    db.session.rollback()
    return (
        jsonify(
            {
                "error": "La operación entra en conflicto con un registro existente",
                "code": "transfer_conflict",
            }
        ),
        409,
    )


@transfer_bp.errorhandler(SQLAlchemyError)
def error_persistencia(_error):
    db.session.rollback()
    return (
        jsonify(
            {
                "error": "No fue posible guardar la operación",
                "code": "transfer_persistence_unavailable",
            }
        ),
        503,
    )


def _actor():
    user = current_user()
    if user is None or user.estado != "activo":
        raise TransferError("auth_required", 401, "Sesión inválida")
    return user


def _datos(campos):
    data = request.get_json(silent=True)
    if data is None:
        data = {}
    if not isinstance(data, dict) or set(data) - set(campos):
        raise TransferError(
            "transfer_validation",
            400,
            "Objeto JSON inválido o campos no permitidos",
        )
    return data


def _idempotency():
    return request.headers.get("Idempotency-Key")


def _receipt_response(metadata, transfer, created):
    return (
        jsonify(
            {
                "id_transferencia": transfer.id_transferencia,
                "estado": transfer.estado,
                "comprobante": metadata,
            }
        ),
        201 if created else 200,
    )


@transfer_bp.get("/campaigns/<int:campaign_id>/bank-account")
@jwt_required()
@require_role("donante")
def bank_account(campaign_id):
    actor = _actor()
    return jsonify(transfer_service.get_account_for_donor(actor, campaign_id)), 200


@transfer_bp.post("/transfers")
@jwt_required()
@require_role("donante")
def create_transfer():
    actor = _actor()
    data = _datos(
        {
            "id_campania",
            "id_cuenta_recaudo",
            "monto",
            "moneda",
            "referencia_bancaria",
            "fecha_transferencia",
            "descripcion",
        }
    )
    transfer, created = transfer_service.create_transfer(
        actor, data, _idempotency(), request.remote_addr
    )
    return jsonify(transfer_service._transfer_payload(transfer)), 201 if created else 200


@transfer_bp.get("/transfers/mine")
@jwt_required()
@require_role("donante")
def my_transfers():
    actor = _actor()
    items, page = transfer_service.list_my_transfers(
        actor, request.args.get("page", 1)
    )
    return jsonify({"items": items, "page": page}), 200


@transfer_bp.get("/transfers/<int:id_transferencia>")
@jwt_required()
@require_role("donante")
def transfer_detail(id_transferencia):
    actor = _actor()
    return jsonify(transfer_service.get_transfer(actor, id_transferencia)), 200


@transfer_bp.post("/transfers/<int:id_transferencia>/receipt")
@transfer_bp.post("/transfers/<int:id_transferencia>/resubmit")
@jwt_required()
@require_role("donante")
def upload_receipt(id_transferencia):
    actor = _actor()
    file = request.files.get("file")
    if file is None or not file.filename:
        raise TransferError("receipt_required", 400, "Debe adjuntar un comprobante")
    metadata, transfer, created = transfer_service.add_receipt(
        actor, id_transferencia, file, request.remote_addr
    )
    return _receipt_response(metadata, transfer, created)


@transfer_bp.get("/transfers/<int:id_transferencia>/receipt")
@jwt_required()
def download_receipt(id_transferencia):
    actor = _actor()
    path, receipt = transfer_service.receipt_path(
        actor, id_transferencia, support=is_support()
    )
    extension = {
        "application/pdf": ".pdf",
        "image/jpeg": ".jpg",
        "image/png": ".png",
    }.get(receipt.mime, "")
    return send_file(
        path,
        mimetype=receipt.mime,
        as_attachment=True,
        download_name=f"comprobante_{id_transferencia}{extension}",
        max_age=0,
    )


@transfer_bp.get("/support/transfers")
@jwt_required()
@require_role("soporte")
def support_queue():
    actor = _actor()
    items, page = transfer_service.list_queue(
        actor,
        request.args.get("estado"),
        request.args.get("page", 1),
    )
    return jsonify({"items": items, "page": page}), 200


@transfer_bp.get("/support/transfers/<int:id_transferencia>")
@jwt_required()
@require_role("soporte")
def support_transfer_detail(id_transferencia):
    actor = _actor()
    return (
        jsonify(transfer_service.get_transfer(actor, id_transferencia, support=True)),
        200,
    )


@transfer_bp.post("/support/transfers/<int:id_transferencia>/claim")
@jwt_required()
@require_role("soporte")
def claim_transfer(id_transferencia):
    actor = _actor()
    _datos(set())
    payload, _ = transfer_service.claim_transfer(
        actor, id_transferencia, _idempotency(), request.remote_addr
    )
    return jsonify(payload), 200


@transfer_bp.post("/support/transfers/<int:id_transferencia>/reject")
@jwt_required()
@require_role("soporte")
def reject_transfer(id_transferencia):
    actor = _actor()
    data = _datos({"motivo"})
    payload, _ = transfer_service.reject_transfer(
        actor,
        id_transferencia,
        data.get("motivo"),
        _idempotency(),
        request.remote_addr,
    )
    return jsonify(payload), 200


@transfer_bp.post("/support/transfers/<int:id_transferencia>/approve")
@jwt_required()
@require_role("soporte")
def approve_transfer(id_transferencia):
    actor = _actor()
    data = _datos({"nota"})
    payload, _ = transfer_service.approve_transfer(
        actor,
        id_transferencia,
        data.get("nota"),
        _idempotency(),
        request.remote_addr,
    )
    return jsonify(payload), 200


@transfer_bp.get("/support/transfers/<int:id_transferencia>/receipt")
@jwt_required()
@require_role("soporte")
def support_download_receipt(id_transferencia):
    actor = _actor()
    path, receipt = transfer_service.receipt_path(
        actor, id_transferencia, support=True
    )
    extension = {
        "application/pdf": ".pdf",
        "image/jpeg": ".jpg",
        "image/png": ".png",
    }.get(receipt.mime, "")
    return send_file(
        path,
        mimetype=receipt.mime,
        as_attachment=True,
        download_name=f"comprobante_{id_transferencia}{extension}",
        max_age=0,
    )


@transfer_bp.post("/financial/bank-accounts")
@jwt_required()
def create_bank_account():
    actor = _actor()
    data = _datos(
        {
            "id_campania",
            "banco",
            "tipo_cuenta",
            "numero_cuenta",
            "titular",
            "moneda",
        }
    )
    account, created = transfer_service.create_account(
        actor, data, _idempotency(), request.remote_addr
    )
    return jsonify(account.to_dict()), 201 if created else 200


@transfer_bp.get("/financial/bank-accounts")
@jwt_required()
def list_bank_accounts():
    actor = _actor()
    items, page = transfer_service.list_accounts(
        actor, request.args.get("page", 1)
    )
    return jsonify({"items": items, "page": page}), 200


@transfer_bp.get("/financial/bank-accounts/<int:id_cuenta>")
@jwt_required()
def bank_account_detail(id_cuenta):
    actor = _actor()
    return jsonify(transfer_service.get_account_admin(actor, id_cuenta)), 200


@transfer_bp.post("/financial/bank-accounts/<int:id_cuenta>/verify")
@jwt_required()
def verify_bank_account(id_cuenta):
    actor = _actor()
    _datos(set())
    account, changed = transfer_service.verify_account(
        actor, id_cuenta, request.remote_addr
    )
    return jsonify(account.to_dict()), 200 if changed else 200


@transfer_bp.post("/financial/bank-accounts/<int:id_cuenta>/revoke")
@jwt_required()
def revoke_bank_account(id_cuenta):
    actor = _actor()
    data = _datos({"motivo"})
    account, changed = transfer_service.revoke_account(
        actor, id_cuenta, data.get("motivo"), request.remote_addr
    )
    return jsonify(account.to_dict()), 200 if changed else 200
