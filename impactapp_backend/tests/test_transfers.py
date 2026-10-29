import os
import threading
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime
from io import BytesIO
from pathlib import Path

import pytest

from app import app
from conftest import SUPPORT_EMAIL, get_support_token, get_token
from models import CAMPAÑA, DONACION, USUARIO, db
from models.asignacion_financiera import ASIGNACION_FINANCIERA
from models.auditoria import AUDITORIA
from models.transfer import (
    COMPROBANTE_TRANSFERENCIA,
    CUENTA_RECAUDO,
    TRANSFERENCIA_BANCARIA,
)
from sqlalchemy.exc import SQLAlchemyError

from services.auth_service import hash_password
from services.private_storage import resolve_receipt
from services.transfer_config import configuration_status
from services.transfer_errors import TransferError
from test_uploads import PDF, PNG

pytestmark = pytest.mark.skipif(
    os.getenv("TRANSFERENCIAS_ENABLED", "0") != "1",
    reason="Las pruebas de transferencias requieren TRANSFERENCIAS_ENABLED=1",
)


def _support(correo):
    with app.app_context():
        user = USUARIO(
            nombre="Soporte",
            apellido="Transferencias",
            correo=correo,
            contraseña_hash=hash_password("Passw0rd!"),
            rol="soporte",
            estado="activo",
            acepta_tratamiento=True,
            fecha_aceptacion=datetime.utcnow(),
        )
        db.session.add(user)
        db.session.commit()
        return user.id_usuario


@pytest.fixture()
def transfer_context(client, tmp_path, monkeypatch):
    monkeypatch.setitem(app.config, "PRIVATE_STORAGE_ROOT", str(tmp_path / "private"))
    monkeypatch.setitem(app.config, "FINANCIAL_ASSIGNMENTS_ENABLED", True)
    assert app.config["TRANSFERENCIAS_ENABLED"] is True
    with app.app_context():
        admin = USUARIO.query.filter_by(correo=SUPPORT_EMAIL).one()
        admin_id = admin.id_usuario
        app.config["FINANCIAL_ADMIN_USER_ID"] = str(admin_id)
        reviewer_id = _support("reviewer_transfer@test.co")
        approver_id = _support("approver_transfer@test.co")
        db.session.add_all(
            [
                ASIGNACION_FINANCIERA(
                    id_usuario=reviewer_id,
                    id_campania=1,
                    capacidad="revision",
                    id_concedente=admin.id_usuario,
                ),
                ASIGNACION_FINANCIERA(
                    id_usuario=reviewer_id,
                    id_campania=1,
                    capacidad="contabilizacion",
                    id_concedente=admin.id_usuario,
                ),
                ASIGNACION_FINANCIERA(
                    id_usuario=approver_id,
                    id_campania=1,
                    capacidad="contabilizacion",
                    id_concedente=admin.id_usuario,
                ),
            ]
        )
        db.session.commit()
    admin_token = get_support_token(client)
    reviewer_token = get_token(client, "reviewer_transfer@test.co")
    approver_token = get_token(client, "approver_transfer@test.co")
    donor_email = "donor_transfer@test.co"
    donor_token = _create_donor(client, donor_email)
    return {
        "admin_token": admin_token,
        "reviewer_token": reviewer_token,
        "approver_token": approver_token,
        "donor_token": donor_token,
        "reviewer_id": reviewer_id,
        "approver_id": approver_id,
        "admin_id": admin_id,
    }


def _create_donor(client, correo):
    from conftest import register_user

    register_user(client, rol="donante", correo=correo)
    return get_token(client, correo)


def _headers(token, key=None):
    headers = {"Authorization": f"Bearer {token}"}
    if key:
        headers["Idempotency-Key"] = key
    return headers


def _create_account(client, ctx, number="123456789012", reference="ACC-1"):
    response = client.post(
        "/api/financial/bank-accounts",
        json={
            "id_campania": 1,
            "banco": "Banco de prueba",
            "tipo_cuenta": "ahorros",
            "numero_cuenta": number,
            "titular": "ImpactApp",
            "moneda": "COP",
        },
        headers=_headers(ctx["admin_token"], reference),
    )
    assert response.status_code == 201, response.get_json()
    account_id = response.get_json()["id_cuenta_recaudo"]
    verify = client.post(
        f"/api/financial/bank-accounts/{account_id}/verify",
        headers=_headers(ctx["admin_token"]),
    )
    assert verify.status_code == 200, verify.get_json()
    return account_id


def _transfer_payload(account_id, reference="BANK-REF-1"):
    return {
        "id_campania": 1,
        "id_cuenta_recaudo": account_id,
        "monto": "50000.00",
        "moneda": "COP",
        "referencia_bancaria": reference,
        "fecha_transferencia": date.today().isoformat(),
        "descripcion": "Aporte por transferencia",
    }


def _create_transfer(client, ctx, account_id, reference="BANK-REF-1", key="transfer-1"):
    response = client.post(
        "/api/transfers",
        json=_transfer_payload(account_id, reference),
        headers=_headers(ctx["donor_token"], key),
    )
    assert response.status_code == 201, response.get_json()
    return response.get_json()


def _upload(client, ctx, transfer_id, content=PDF, filename="receipt.pdf"):
    response = client.post(
        f"/api/transfers/{transfer_id}/receipt",
        data={"file": (BytesIO(content), filename)},
        headers=_headers(ctx["donor_token"]),
    )
    return response


def _claim(client, ctx, transfer_id, key="claim-1"):
    return client.post(
        f"/api/support/transfers/{transfer_id}/claim",
        headers=_headers(ctx["reviewer_token"], key),
    )


def _approve(client, ctx, transfer_id, key="approve-1"):
    return client.post(
        f"/api/support/transfers/{transfer_id}/approve",
        json={"nota": "Verificado en el banco"},
        headers=_headers(ctx["approver_token"], key),
    )


def _state(transfer_id):
    with app.app_context():
        transfer = db.session.get(TRANSFERENCIA_BANCARIA, transfer_id)
        donation = db.session.get(DONACION, transfer.id_donacion)
        campaign = db.session.get(CAMPAÑA, 1)
        return transfer.estado, donation.estado_pago, float(campaign.porcentaje_avance)


def test_configuration_requires_flag_keys_and_tables():
    with app.app_context():
        status = configuration_status()
    assert status["ok"] is True
    assert app.config["TRANSFERENCIAS_ENABLED"] is True


def test_configuration_disables_module_when_key_is_missing(monkeypatch):
    with app.app_context():
        monkeypatch.setitem(app.config, "BANK_ACCOUNT_ENCRYPTION_KEY", "")
        status = configuration_status()
    assert status["ok"] is False
    assert "BANK_ACCOUNT_ENCRYPTION_KEY" in status["missing"]


def test_admin_can_create_verify_and_mask_account(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    donor_view = client.get(
        "/api/campaigns/1/bank-account",
        headers=_headers(ctx["donor_token"]),
    )
    assert donor_view.status_code == 200
    body = donor_view.get_json()
    assert body["numero_cuenta"] == "123456789012"
    assert donor_view.headers["Cache-Control"] == "private, no-store"
    with app.app_context():
        account = db.session.get(CUENTA_RECAUDO, account_id)
        assert account.numero_cuenta_cifrado != "123456789012"
        assert account.estado == "verificada"
    admin_detail = client.get(
        f"/api/financial/bank-accounts/{account_id}",
        headers=_headers(ctx["admin_token"]),
    )
    assert admin_detail.status_code == 200
    assert admin_detail.get_json()["numero_cuenta"] == "123456789012"


def test_only_designated_admin_manages_accounts(client, transfer_context):
    ctx = transfer_context
    account_payload = {
        "id_campania": 1,
        "banco": "X",
        "tipo_cuenta": "ahorros",
        "numero_cuenta": "111122223333",
        "titular": "X",
        "moneda": "COP",
    }
    donor = client.post(
        "/api/financial/bank-accounts",
        json=account_payload,
        headers=_headers(ctx["donor_token"], "admin-donor"),
    )
    assert donor.status_code == 403
    reviewer = client.post(
        "/api/financial/bank-accounts",
        json=account_payload,
        headers=_headers(ctx["reviewer_token"], "admin-reviewer"),
    )
    assert reviewer.status_code == 403


def test_pending_transfer_does_not_increase_total_and_approval_credits_once(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    assert _state(transfer["id_transferencia"]) == ("registrada", "pendiente", 15.0)
    assert _upload(client, ctx, transfer["id_transferencia"]).status_code == 201
    claim = _claim(client, ctx, transfer["id_transferencia"])
    assert claim.status_code == 200, claim.get_json()
    assert _state(transfer["id_transferencia"])[0] == "en_revision"
    approve = _approve(client, ctx, transfer["id_transferencia"])
    assert approve.status_code == 200, approve.get_json()
    assert _state(transfer["id_transferencia"]) == ("aprobada", "aprobada", 1.0)
    repeat = _approve(client, ctx, transfer["id_transferencia"], key="approve-1")
    assert repeat.status_code == 200
    assert _state(transfer["id_transferencia"]) == ("aprobada", "aprobada", 1.0)
    with app.app_context():
        assert (
            AUDITORIA.query.filter_by(
                accion="TRANSFERENCIA_APROBADA",
                id_entidad=transfer["id_transferencia"],
            ).count()
            == 1
        )
        assert (
            DONACION.query.filter_by(
                id_campania=1, estado_pago="aprobada"
            ).count()
            == 1
        )


def test_reviewer_cannot_approve_and_unassigned_cannot_claim(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    _upload(client, ctx, transfer["id_transferencia"])
    _claim(client, ctx, transfer["id_transferencia"])
    approval = client.post(
        f"/api/support/transfers/{transfer['id_transferencia']}/approve",
        json={"nota": "intento"},
        headers=_headers(ctx["reviewer_token"], "reviewer-approve"),
    )
    assert approval.status_code == 409
    assert _state(transfer["id_transferencia"]) == ("en_revision", "pendiente", 15.0)
    other = _create_support_only(client, "no_assignment_transfer@test.co")
    response = client.post(
        f"/api/support/transfers/{transfer['id_transferencia']}/claim",
        headers=_headers(other, "no-assignment"),
    )
    assert response.status_code == 403


def _create_support_only(client, correo):
    _support(correo)
    return get_token(client, correo)


def test_insufficient_and_revoked_assignments_are_rejected(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    _upload(client, ctx, transfer["id_transferencia"])
    insufficient = client.post(
        f"/api/support/transfers/{transfer['id_transferencia']}/claim",
        headers=_headers(ctx["approver_token"], "insufficient-claim"),
    )
    assert insufficient.status_code == 403

    revoked_id = _support("revoked_assignment@test.co")
    with app.app_context():
        assignment = ASIGNACION_FINANCIERA(
            id_usuario=revoked_id,
            id_campania=1,
            capacidad="revision",
            id_concedente=ctx["admin_id"],
        )
        db.session.add(assignment)
        db.session.commit()
        assignment.fecha_revocacion = datetime.utcnow()
        assignment.id_revocador = ctx["admin_id"]
        db.session.commit()
    revoked_token = get_token(client, "revoked_assignment@test.co")
    revoked = client.post(
        f"/api/support/transfers/{transfer['id_transferencia']}/claim",
        headers=_headers(revoked_token, "revoked-claim"),
    )
    assert revoked.status_code == 403


def test_client_cannot_send_state_and_organizer_cannot_approve(client, transfer_context):
    from conftest import register_user

    ctx = transfer_context
    account_id = _create_account(client, ctx)
    payload = _transfer_payload(account_id, "STATE-REF")
    payload["estado"] = "aprobada"
    response = client.post(
        "/api/transfers",
        json=payload,
        headers=_headers(ctx["donor_token"], "state-key"),
    )
    assert response.status_code == 400
    assert response.get_json()["code"] == "transfer_validation"

    register_user(client, rol="organizador", correo="organizer_transfer@test.co")
    organizer_token = get_token(client, "organizer_transfer@test.co")
    transfer = _create_transfer(client, ctx, account_id, "ORG-REF", "org-transfer")
    organizer = client.post(
        f"/api/support/transfers/{transfer['id_transferencia']}/claim",
        headers=_headers(organizer_token, "org-claim"),
    )
    assert organizer.status_code == 403


def test_admin_list_masks_account_and_audit_has_no_number(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx, number="987654321098")
    listing = client.get(
        "/api/financial/bank-accounts",
        headers=_headers(ctx["admin_token"]),
    )
    assert listing.status_code == 200
    item = next(
        item
        for item in listing.get_json()["items"]
        if item["id_cuenta_recaudo"] == account_id
    )
    assert item["numero_cuenta"] == "****1098"
    assert "987654321098" not in str(listing.get_json())
    with app.app_context():
        descriptions = [
            row.descripcion
            for row in AUDITORIA.query.filter_by(
                accion="CUENTA_RECAUDO_CREADA"
            ).all()
        ]
    assert descriptions
    assert all("987654321098" not in item for item in descriptions)


def test_sql_failure_removes_orphan_receipt_file(client, transfer_context, monkeypatch):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)

    def fail(*_args, **_kwargs):
        raise SQLAlchemyError("fallo simulado")

    monkeypatch.setattr("services.transfer_service._event", fail)
    response = _upload(client, ctx, transfer["id_transferencia"], PDF, "receipt.pdf")
    assert response.status_code == 503
    with app.app_context():
        assert (
            COMPROBANTE_TRANSFERENCIA.query.filter_by(
                id_transferencia=transfer["id_transferencia"]
            ).count()
            == 0
        )
    root = Path(app.config["PRIVATE_STORAGE_ROOT"])
    assert [p for p in root.rglob("*") if p.is_file()] == []


def test_blocked_support_cannot_review_with_old_token(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    _upload(client, ctx, transfer["id_transferencia"])
    with app.app_context():
        user = db.session.get(USUARIO, ctx["reviewer_id"])
        user.estado = "bloqueado"
        db.session.commit()
    response = _claim(client, ctx, transfer["id_transferencia"])
    assert response.status_code == 401


def test_other_donor_cannot_read_or_download(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    _upload(client, ctx, transfer["id_transferencia"])
    other = _create_donor(client, "other_transfer@test.co")
    detail = client.get(
        f"/api/transfers/{transfer['id_transferencia']}",
        headers=_headers(other),
    )
    assert detail.status_code == 404
    receipt = client.get(
        f"/api/transfers/{transfer['id_transferencia']}/receipt",
        headers=_headers(other),
    )
    assert receipt.status_code == 404
    owner = client.get(
        f"/api/transfers/{transfer['id_transferencia']}/receipt",
        headers=_headers(ctx["donor_token"]),
    )
    assert owner.status_code == 200
    assert owner.headers["Cache-Control"] == "private, no-store"
    assert owner.headers["X-Content-Type-Options"] == "nosniff"


def test_receipt_validation_and_private_storage(client, transfer_context, tmp_path):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    bad = _upload(client, ctx, transfer["id_transferencia"], b"<script>", "receipt.pdf")
    assert bad.status_code == 415
    wrong_ext = _upload(client, ctx, transfer["id_transferencia"], PDF, "receipt.exe")
    assert wrong_ext.status_code == 415
    original_max = app.config["TRANSFER_RECEIPT_MAX_BYTES"]
    app.config["TRANSFER_RECEIPT_MAX_BYTES"] = 100
    try:
        too_large = _upload(client, ctx, transfer["id_transferencia"], PDF, "receipt.pdf")
        assert too_large.status_code == 413
    finally:
        app.config["TRANSFER_RECEIPT_MAX_BYTES"] = original_max
    valid = _upload(client, ctx, transfer["id_transferencia"], PNG, "receipt.png")
    assert valid.status_code == 201, valid.get_json()
    body = valid.get_json()
    assert "clave_almacenamiento" not in str(body)
    assert "/uploads/" not in str(body)
    files = [p for p in Path(app.config["PRIVATE_STORAGE_ROOT"]).rglob("*") if p.is_file()]
    assert len(files) == 1


def test_receipt_filename_is_not_used_as_internal_path(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    response = _upload(
        client, ctx, transfer["id_transferencia"], PDF, "../../evil.pdf"
    )
    assert response.status_code == 201
    root = Path(app.config["PRIVATE_STORAGE_ROOT"])
    files = [p for p in root.rglob("*") if p.is_file()]
    assert len(files) == 1
    assert "evil" not in files[0].name
    assert str(files[0]).startswith(str(root))


def test_receipt_resolution_rejects_traversal_and_symlinks(
    client, transfer_context, tmp_path
):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    assert _upload(client, ctx, transfer["id_transferencia"]).status_code == 201
    root = Path(app.config["PRIVATE_STORAGE_ROOT"])
    outside = tmp_path / "outside.txt"
    outside.write_text("no es un comprobante")
    with app.app_context():
        with pytest.raises(TransferError) as traversal:
            resolve_receipt("../outside.txt")
        assert traversal.value.status == 404
        link = root / "symlink.pdf"
        try:
            link.symlink_to(outside)
        except OSError:
            pytest.skip("El sistema no permite crear enlaces simbólicos")
        with pytest.raises(TransferError) as symbolic:
            resolve_receipt("symlink.pdf")
        assert symbolic.value.status == 404


def test_rejected_transfer_can_be_resubmitted_with_new_receipt(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    _upload(client, ctx, transfer["id_transferencia"], PDF, "receipt.pdf")
    _claim(client, ctx, transfer["id_transferencia"])
    reject = client.post(
        f"/api/support/transfers/{transfer['id_transferencia']}/reject",
        json={"motivo": "Comprobante ilegible"},
        headers=_headers(ctx["reviewer_token"], "reject-1"),
    )
    assert reject.status_code == 200, reject.get_json()
    assert _state(transfer["id_transferencia"]) == ("rechazada", "rechazada", 15.0)
    same = _upload(client, ctx, transfer["id_transferencia"], PDF, "receipt.pdf")
    assert same.status_code == 409
    resubmit = _upload(client, ctx, transfer["id_transferencia"], PNG, "receipt.png")
    assert resubmit.status_code == 201
    assert _state(transfer["id_transferencia"]) == ("registrada", "pendiente", 15.0)
    _claim(client, ctx, transfer["id_transferencia"], key="claim-2")
    approved = _approve(client, ctx, transfer["id_transferencia"], key="approve-2")
    assert approved.status_code == 200
    assert _state(transfer["id_transferencia"]) == ("aprobada", "aprobada", 1.0)


def test_tampered_donation_is_not_approved(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    _upload(client, ctx, transfer["id_transferencia"])
    _claim(client, ctx, transfer["id_transferencia"])
    with app.app_context():
        donation = DONACION.query.filter_by(
            id_donacion=transfer["id_donacion"]
        ).one()
        donation.monto_estimado = 999999
        db.session.commit()
    approval = _approve(client, ctx, transfer["id_transferencia"], key="tamper-key")
    assert approval.status_code == 409
    assert approval.get_json()["code"] == "donation_integrity_conflict"
    assert _state(transfer["id_transferencia"]) == ("en_revision", "pendiente", 15.0)


def test_only_one_verified_account_per_campaign(client, transfer_context):
    ctx = transfer_context
    payload = {
        "id_campania": 1,
        "banco": "Banco de prueba",
        "tipo_cuenta": "ahorros",
        "numero_cuenta": "111122223333",
        "titular": "ImpactApp",
        "moneda": "COP",
    }
    first = client.post(
        "/api/financial/bank-accounts",
        json=payload,
        headers=_headers(ctx["admin_token"], "account-first"),
    )
    assert first.status_code == 201, first.get_json()
    second_payload = payload | {"numero_cuenta": "444455556666"}
    second = client.post(
        "/api/financial/bank-accounts",
        json=second_payload,
        headers=_headers(ctx["admin_token"], "account-second"),
    )
    assert second.status_code == 201, second.get_json()
    first_id = first.get_json()["id_cuenta_recaudo"]
    second_id = second.get_json()["id_cuenta_recaudo"]
    assert (
        client.post(
            f"/api/financial/bank-accounts/{first_id}/verify",
            headers=_headers(ctx["admin_token"]),
        ).status_code
        == 200
    )
    conflict = client.post(
        f"/api/financial/bank-accounts/{second_id}/verify",
        headers=_headers(ctx["admin_token"]),
    )
    assert conflict.status_code == 409
    assert conflict.get_json()["code"] == "account_already_verified"


def test_idempotency_and_duplicate_reference(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    first = _create_transfer(client, ctx, account_id, key="same-key")
    second = client.post(
        "/api/transfers",
        json=_transfer_payload(account_id),
        headers=_headers(ctx["donor_token"], "same-key"),
    )
    assert second.status_code == 200
    assert second.get_json()["id_transferencia"] == first["id_transferencia"]
    changed = _transfer_payload(account_id)
    changed["monto"] = "60000.00"
    conflict = client.post(
        "/api/transfers",
        json=changed,
        headers=_headers(ctx["donor_token"], "same-key"),
    )
    assert conflict.status_code == 409
    duplicate = client.post(
        "/api/transfers",
        json=_transfer_payload(account_id),
        headers=_headers(ctx["donor_token"], "other-key"),
    )
    assert duplicate.status_code == 409


def test_revoked_account_blocks_new_transfer(client, transfer_context):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    revoke = client.post(
        f"/api/financial/bank-accounts/{account_id}/revoke",
        json={"motivo": "Cambio de cuenta"},
        headers=_headers(ctx["admin_token"]),
    )
    assert revoke.status_code == 200
    missing = client.get(
        "/api/campaigns/1/bank-account",
        headers=_headers(ctx["donor_token"]),
    )
    assert missing.status_code == 404
    transfer = client.post(
        "/api/transfers",
        json=_transfer_payload(account_id),
        headers=_headers(ctx["donor_token"], "revoked-transfer"),
    )
    assert transfer.status_code == 409
    assert transfer.get_json()["code"] == "account_not_verified"


def test_storage_failure_does_not_create_receipt(client, transfer_context, monkeypatch):
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)

    def fail(*_args, **_kwargs):
        from services.transfer_errors import TransferError

        raise TransferError("receipt_storage_unavailable", 503, "sin almacenamiento")

    monkeypatch.setattr("services.transfer_service.store_receipt", fail)
    response = _upload(client, ctx, transfer["id_transferencia"], PDF, "receipt.pdf")
    assert response.status_code == 503
    with app.app_context():
        assert COMPROBANTE_TRANSFERENCIA.query.filter_by(
            id_transferencia=transfer["id_transferencia"]
        ).count() == 0


def _postgres_only():
    with app.app_context():
        return db.engine.dialect.name == "postgresql"


def test_concurrent_approval_credits_once(client, transfer_context):
    if not _postgres_only():
        pytest.skip("La concurrencia de bloqueos requiere PostgreSQL")
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    transfer = _create_transfer(client, ctx, account_id)
    _upload(client, ctx, transfer["id_transferencia"])
    assert _claim(client, ctx, transfer["id_transferencia"]).status_code == 200
    barrier = threading.Barrier(2)

    def approve(index):
        with app.test_client() as threaded_client:
            barrier.wait(timeout=10)
            response = threaded_client.post(
                f"/api/support/transfers/{transfer['id_transferencia']}/approve",
                json={"nota": "concurrente"},
                headers=_headers(ctx["approver_token"], f"concurrent-approve-{index}"),
            )
            return response.status_code

    with ThreadPoolExecutor(max_workers=2) as pool:
        statuses = sorted(pool.map(approve, (1, 2)))
    assert statuses[0] == 200
    assert statuses[1] in (200, 409)
    assert _state(transfer["id_transferencia"]) == ("aprobada", "aprobada", 1.0)
    with app.app_context():
        assert (
            DONACION.query.filter_by(
                id_campania=1, estado_pago="aprobada"
            ).count()
            == 1
        )
        assert (
            AUDITORIA.query.filter_by(
                accion="TRANSFERENCIA_APROBADA",
                id_entidad=transfer["id_transferencia"],
            ).count()
            == 1
        )


def test_concurrent_duplicate_reference_creates_one_transfer(client, transfer_context):
    if not _postgres_only():
        pytest.skip("La concurrencia de bloqueos requiere PostgreSQL")
    ctx = transfer_context
    account_id = _create_account(client, ctx)
    barrier = threading.Barrier(2)

    def create(index):
        with app.test_client() as threaded_client:
            barrier.wait(timeout=10)
            response = threaded_client.post(
                "/api/transfers",
                json=_transfer_payload(account_id, "CONCURRENT-REF"),
                headers=_headers(ctx["donor_token"], f"concurrent-create-{index}"),
            )
            return response.status_code

    with ThreadPoolExecutor(max_workers=2) as pool:
        statuses = sorted(pool.map(create, (1, 2)))
    assert statuses == [201, 409]
    with app.app_context():
        assert (
            TRANSFERENCIA_BANCARIA.query.filter_by(
                id_campania=1, referencia_bancaria="CONCURRENT-REF"
            ).count()
            == 1
        )


def test_migration_sql_covers_all_new_tables():
    root = Path(__file__).resolve().parents[1]
    sql = (
        root / "migrations" / "20261022_02_transfers.sql"
    ).read_text()
    for table in (
        "CUENTA_RECAUDO",
        "TRANSFERENCIA_BANCARIA",
        "COMPROBANTE_TRANSFERENCIA",
        "TRANSFERENCIA_EVENTO",
    ):
        assert f'CREATE TABLE "{table}"' in sql
    assert 'CREATE UNIQUE INDEX uq_transferencia_aprobada_por_donacion' in sql
    assert 'CREATE UNIQUE INDEX uq_cuenta_verificada_por_campania' in sql
