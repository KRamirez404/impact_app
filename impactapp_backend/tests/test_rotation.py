import importlib.util
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest
from flask_jwt_extended import create_access_token
from sqlalchemy import event

from app import app
from conftest import (
    SUPPORT_EMAIL,
    SUPPORT_PASSWORD,
    get_support_token,
    get_token,
    register_user,
)
from models import AUDITORIA, CAMPAÑA, DONACION, SOPORTE, USUARIO, db
from services.support_password_service import (
    RotationError,
    active_support_user,
    rotate_support_password,
)

NEW_PASSWORD = "NuevaSoporte2026!"


def _email(prefix):
    return f"{prefix}@test.co"


def _campaign_payload():
    return {
        "titulo": "Campaña rotación",
        "descripcion": "Verificación de aislamiento",
        "id_ciudad": 1,
        "id_categoria": 1,
        "tipo_ayuda_requerida": "economica",
        "meta_monetaria": 500000,
        "fecha_fin": "2030-01-01",
    }


def _create_activity(client):
    organizer_email = _email("org_rotacion")
    donor_email = _email("don_rotacion")
    register_user(client, rol="organizador", correo=organizer_email)
    register_user(client, rol="donante", correo=donor_email)
    organizer_token = get_token(client, organizer_email)
    donor_token = get_token(client, donor_email)
    campaign = client.post(
        "/api/campaigns",
        json=_campaign_payload(),
        headers={"Authorization": f"Bearer {organizer_token}"},
    )
    assert campaign.status_code == 201
    campaign_id = campaign.get_json()["id_campania"]
    donation = client.post(
        "/api/donations",
        json={"id_campania": campaign_id, "tipo": "alimentos", "monto_estimado": 1000},
        headers={"Authorization": f"Bearer {donor_token}"},
    )
    assert donation.status_code == 201
    support = client.post(
        "/api/supports",
        data={
            "id_campania": campaign_id,
            "tipo": "documento_oficial",
            "url_o_ruta": "https://documentos.example/rotacion.pdf",
        },
        headers={"Authorization": f"Bearer {organizer_token}"},
    )
    assert support.status_code == 201
    return organizer_email, donor_email, organizer_token, donor_token


def test_rotation_updates_only_target_and_revokes_old_tokens(client):
    support_token = get_support_token(client)
    _, _, organizer_token, donor_token = _create_activity(client)

    with app.app_context():
        support = USUARIO.query.filter_by(correo=SUPPORT_EMAIL).one()
        legacy_support_token = create_access_token(identity=str(support.id_usuario))
        other_hashes = {
            user.id_usuario: user.contraseña_hash
            for user in USUARIO.query.filter(USUARIO.id_usuario != support.id_usuario).all()
        }
        counts_before = (
            USUARIO.query.count(),
            CAMPAÑA.query.count(),
            DONACION.query.count(),
            SOPORTE.query.count(),
        )
        old_hash = support.contraseña_hash
        old_version = support.token_version
        rotate_support_password(db.session, support, NEW_PASSWORD)
        db.session.expire_all()
        support = USUARIO.query.filter_by(correo=SUPPORT_EMAIL).one()
        password_changed = support.contraseña_hash != old_hash
        version_incremented = support.token_version == old_version + 1
        other_users_unchanged = all(
            USUARIO.query.get(user_id).contraseña_hash == stored_hash
            for user_id, stored_hash in other_hashes.items()
        )
        counts_after = (
            USUARIO.query.count(),
            CAMPAÑA.query.count(),
            DONACION.query.count(),
            SOPORTE.query.count(),
        )
        audit = AUDITORIA.query.filter_by(
            accion="ROTACION_CONTRASENA_SOPORTE",
            id_entidad=support.id_usuario,
        ).one()
        audit_without_secret = NEW_PASSWORD not in (audit.descripcion or "")

    assert password_changed
    assert version_incremented
    assert other_users_unchanged
    assert counts_after == counts_before
    assert audit_without_secret

    assert (
        client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {support_token}"},
        ).status_code
        == 401
    )
    assert (
        client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {legacy_support_token}"},
        ).status_code
        == 401
    )
    assert (
        client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {organizer_token}"},
        ).status_code
        == 200
    )
    assert (
        client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {donor_token}"},
        ).status_code
        == 200
    )

    assert client.post(
        "/api/auth/login",
        json={"correo": SUPPORT_EMAIL, "contrasena": SUPPORT_PASSWORD},
    ).status_code == 401
    login = client.post(
        "/api/auth/login",
        json={"correo": SUPPORT_EMAIL, "contrasena": NEW_PASSWORD},
    )
    assert login.status_code == 200
    new_token = login.get_json()["access_token"]
    assert (
        client.get(
            "/api/auth/me",
            headers={"Authorization": f"Bearer {new_token}"},
        ).status_code
        == 200
    )


def test_rotation_requires_active_support_account(client):
    with app.app_context():
        support = USUARIO.query.filter_by(correo=SUPPORT_EMAIL).one()
        support.estado = "bloqueado"
        db.session.commit()
        with pytest.raises(RotationError):
            active_support_user(db.session, SUPPORT_EMAIL)
        with pytest.raises(RotationError):
            active_support_user(db.session, "otro@test.co")


def test_rotation_rejects_weak_password_without_changes(client):
    with app.app_context():
        support = USUARIO.query.filter_by(correo=SUPPORT_EMAIL).one()
        old_hash = support.contraseña_hash
        old_version = support.token_version
        with pytest.raises(RotationError):
            rotate_support_password(db.session, support, "debil")
        db.session.expire_all()
        support = USUARIO.query.filter_by(correo=SUPPORT_EMAIL).one()
        unchanged = (
            support.contraseña_hash == old_hash
            and support.token_version == old_version
        )
        audit_count = AUDITORIA.query.filter_by(
            accion="ROTACION_CONTRASENA_SOPORTE"
        ).count()
    assert unchanged
    assert audit_count == 0


def test_rotation_rolls_back_if_audit_cannot_be_saved(client):
    def fail_audit(mapper, connection, target):
        raise RuntimeError("auditoría no disponible")

    with app.app_context():
        support = USUARIO.query.filter_by(correo=SUPPORT_EMAIL).one()
        old_hash = support.contraseña_hash
        old_version = support.token_version
        event.listen(AUDITORIA, "before_insert", fail_audit)
        try:
            with pytest.raises(RuntimeError):
                rotate_support_password(db.session, support, NEW_PASSWORD)
        finally:
            event.remove(AUDITORIA, "before_insert", fail_audit)
        db.session.expire_all()
        support = USUARIO.query.filter_by(correo=SUPPORT_EMAIL).one()
        unchanged = (
            support.contraseña_hash == old_hash
            and support.token_version == old_version
        )
        audit_count = AUDITORIA.query.filter_by(
            accion="ROTACION_CONTRASENA_SOPORTE"
        ).count()
    assert unchanged
    assert audit_count == 0


def test_rotation_script_aborts_without_tty(monkeypatch):
    path = Path(__file__).resolve().parents[1] / "scripts" / "rotate_support_password.py"
    spec = importlib.util.spec_from_file_location("rotate_support_password", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    monkeypatch.setattr(module.sys.stdin, "isatty", lambda: False)
    assert module.main() == 1


@pytest.mark.parametrize("working_directory", ["backend_root", "temporary"])
def test_rotation_script_imports_without_pythonpath_or_lucky_cwd(working_directory):
    root = Path(__file__).resolve().parents[1]
    cwd = root if working_directory == "backend_root" else Path(tempfile.gettempdir())
    env = os.environ.copy()
    env.pop("PYTHONPATH", None)
    script = (
        "scripts/rotate_support_password.py"
        if working_directory == "backend_root"
        else str(root / "scripts" / "rotate_support_password.py")
    )
    result = subprocess.run(
        [sys.executable, script],
        cwd=str(cwd),
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=20,
    )
    assert result.returncode == 1
    assert "TTY" in result.stdout
    assert "ModuleNotFoundError" not in result.stderr
    assert "No module named" not in result.stderr


def test_rotation_imports_do_not_load_flask_app():
    root = Path(__file__).resolve().parents[1]
    env = os.environ.copy()
    env.pop("PYTHONPATH", None)
    code = (
        "import runpy, sys; "
        "runpy.run_path('scripts/rotate_support_password.py', run_name='rotation_import_check'); "
        "print('APP_IMPORTED' if 'app' in sys.modules else 'APP_NOT_IMPORTED')"
    )
    result = subprocess.run(
        [sys.executable, "-c", code],
        cwd=str(root),
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        timeout=20,
    )
    assert result.returncode == 0
    assert "APP_NOT_IMPORTED" in result.stdout
    assert "ModuleNotFoundError" not in result.stderr
