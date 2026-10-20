from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
import socket
import subprocess
import sys

import pytest
from flask import Flask
from flask_jwt_extended import JWTManager, create_access_token
from sqlalchemy import event, text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from models import AUDITORIA, CAMPAÑA, CATEGORIA, CIUDAD, DONACION, USUARIO, db
from models.asignacion_financiera import ASIGNACION_FINANCIERA, EVENTO_ASIGNACION_FINANCIERA
from routes.financial_assignment_routes import financial_assignment_bp
from services import asignacion_financiera_service as servicio
from services.autorizacion_financiera import ErrorFinanciero, exigir_asignacion, exigir_doble_control


@pytest.fixture(autouse=True)
def sin_red(monkeypatch):
    def denegar(*args, **kwargs):
        raise AssertionError("La prueba aislada no puede utilizar la red")
    monkeypatch.setattr(socket.socket, "connect", denegar)
    monkeypatch.setattr(socket, "create_connection", denegar)


@pytest.fixture()
def entorno():
    app = Flask("asignaciones_aisladas")
    app.config.update(
        TESTING=True, SQLALCHEMY_DATABASE_URI="sqlite:///:memory:",
        JWT_SECRET_KEY="clave-ficticia-exclusiva-pruebas-financieras",
        FINANCIAL_ASSIGNMENTS_ENABLED=True, FINANCIAL_ADMIN_USER_ID="1",
    )
    db.init_app(app)
    JWTManager(app)
    app.register_blueprint(financial_assignment_bp)
    with app.app_context():
        def activar_fk(conexion, registro):
            conexion.execute("PRAGMA foreign_keys=ON")
        event.listen(db.engine, "connect", activar_fk)
        db.create_all()
        db.create_all()
        db.session.add_all([
            USUARIO(id_usuario=identificador, nombre="Prueba", apellido="Financiera",
                    correo=f"persona{identificador}@example.invalid", contraseña_hash="no-utilizada",
                    rol=rol, estado="activo")
            for identificador, rol in [(1, "soporte"), (2, "soporte"), (3, "organizador"), (4, "donante"), (5, "soporte")]
        ])
        db.session.add(CIUDAD(id_ciudad=1, nombre="Prueba", departamento="Prueba"))
        db.session.add(CATEGORIA(id_categoria=1, nombre="Prueba", descripcion="Prueba"))
        db.session.commit()
        for identificador in (1, 2):
            db.session.add(CAMPAÑA(
                id_campania=identificador, titulo="Prueba", descripcion="Sintética",
                id_ciudad=1, id_categoria=1, id_creador=3, tipo_ayuda_requerida="economica",
                meta_monetaria=Decimal("100000"), porcentaje_avance=Decimal("12.00"),
                fecha_fin=date(2030, 1, 1), estado="activa",
            ))
        db.session.commit()
        tokens = {i: create_access_token(identity=str(i)) for i in range(1, 6)}
    yield app, app.test_client(), tokens
    with app.app_context():
        db.session.remove()
        db.engine.dispose()


def cabeceras(tokens, usuario=1, clave="concesion-1"):
    return {"Authorization": f"Bearer {tokens[usuario]}", "Idempotency-Key": clave}


def conceder(entorno, **cambios):
    _, cliente, tokens = entorno
    datos = {"id_usuario": 2, "id_campania": 1, "capacidad": "revision", "motivo": "Revisión asignada"}
    datos.update(cambios)
    return cliente.post("/api/financial-assignments", json=datos, headers=cabeceras(tokens))


@pytest.mark.parametrize("designado", [None, "", "admin", True, "0", "999", "1" * 5000])
def test_sin_designacion_valida_no_hay_escalada(entorno, designado):
    app, _, _ = entorno
    app.config["FINANCIAL_ADMIN_USER_ID"] = designado
    assert conceder(entorno).status_code == 403
    with app.app_context():
        assert ASIGNACION_FINANCIERA.query.count() == 0
        assert AUDITORIA.query.filter_by(accion="ACCESO_FINANCIERO_DENEGADO").count() == 1


def test_solo_administrador_designado_y_activo(entorno):
    app, cliente, tokens = entorno
    assert cliente.get("/api/financial-assignments").status_code == 401
    for usuario in (2, 3, 4, 5):
        assert cliente.get("/api/financial-assignments", headers=cabeceras(tokens, usuario)).status_code == 403
    with app.app_context():
        db.session.get(USUARIO, 1).estado = "bloqueado"
        db.session.commit()
    assert conceder(entorno).status_code == 403


def test_concesion_idempotente_revocacion_historial_y_reactivacion(entorno):
    app, cliente, tokens = entorno
    primera = conceder(entorno)
    assert primera.status_code == 201
    assert conceder(entorno).get_json() == primera.get_json()
    assert conceder(entorno, motivo="Otros datos").status_code == 409
    identificador = primera.get_json()["id_asignacion"]
    ruta = f"/api/financial-assignments/{identificador}/revoke"
    headers = cabeceras(tokens, clave="revocacion-1")
    revocada = cliente.post(ruta, json={"motivo": "Cambio de responsable"}, headers=headers)
    assert revocada.status_code == 200
    assert cliente.post(ruta, json={"motivo": "Cambio de responsable"}, headers=headers).get_json() == revocada.get_json()
    assert conceder(entorno).get_json() == primera.get_json()
    datos = {"id_usuario": 2, "id_campania": 1, "capacidad": "revision", "motivo": "Nuevo ciclo"}
    nueva = cliente.post("/api/financial-assignments", json=datos, headers=cabeceras(tokens, clave="concesion-2"))
    assert nueva.status_code == 201
    assert nueva.get_json()["id_asignacion"] == identificador
    historial = cliente.get(f"/api/financial-assignments/{identificador}/events", headers=cabeceras(tokens)).get_json()["eventos"]
    assert [e["accion"] for e in historial] == ["concedida", "revocada", "concedida"]
    assert [e["motivo"] for e in historial] == ["Revisión asignada", "Cambio de responsable", "Nuevo ciclo"]
    with app.app_context():
        assert ASIGNACION_FINANCIERA.query.count() == 1
        assert EVENTO_ASIGNACION_FINANCIERA.query.count() == 3
        assert AUDITORIA.query.count() == 3
        assert DONACION.query.count() == 0
        assert db.session.get(CAMPAÑA, 1).porcentaje_avance == Decimal("12.00")


def test_revocado_bloqueado_y_rol_cambiado_no_conservan_acceso(entorno):
    app, cliente, tokens = entorno
    identificador = conceder(entorno).get_json()["id_asignacion"]
    def exigir():
        with app.test_request_context(headers=cabeceras(tokens, 2)):
            from flask_jwt_extended import verify_jwt_in_request
            verify_jwt_in_request()
            return exigir_asignacion(1, "revision")
    assert exigir().id_usuario == 2
    with app.app_context():
        db.session.get(USUARIO, 2).estado = "bloqueado"
        db.session.commit()
    with pytest.raises(ErrorFinanciero):
        exigir()
    assert cliente.get("/api/financial-assignments/mine", headers=cabeceras(tokens, 2)).status_code == 403
    with app.app_context():
        usuario = db.session.get(USUARIO, 2)
        usuario.estado = "activo"
        usuario.rol = "donante"
        db.session.commit()
    with pytest.raises(ErrorFinanciero):
        exigir()
    with app.app_context():
        db.session.get(USUARIO, 2).rol = "soporte"
        db.session.commit()
    assert cliente.post(f"/api/financial-assignments/{identificador}/revoke", json={"motivo": "Fin"}, headers=cabeceras(tokens, clave="revocar")).status_code == 200
    with pytest.raises(ErrorFinanciero):
        exigir()


def test_alcance_y_doble_control_no_equivalen_a_contabilizacion(entorno):
    app, cliente, tokens = entorno
    assert conceder(entorno, capacidad="contabilizacion").status_code == 201
    from flask_jwt_extended import verify_jwt_in_request
    with app.test_request_context(headers=cabeceras(tokens, 2)):
        verify_jwt_in_request()
        assert exigir_doble_control(1, 3).id_usuario == 2
        for campania, confirmador in [(1, 2), (1, 4), (2, 3)]:
            with pytest.raises(ErrorFinanciero):
                exigir_doble_control(campania, confirmador)
    with app.app_context():
        db.session.get(USUARIO, 3).estado = "bloqueado"
        db.session.commit()
    with app.test_request_context(headers=cabeceras(tokens, 2)):
        verify_jwt_in_request()
        with pytest.raises(ErrorFinanciero):
            exigir_doble_control(1, 3)
    estado = cliente.get("/api/financial-assignments/availability", headers=cabeceras(tokens, 2)).get_json()
    assert estado["contabilizacion_disponible"] is False
    assert estado["fuente_bancaria_disponible"] is False


@pytest.mark.parametrize("cambios", [
    {"id_usuario": True}, {"id_campania": "1"}, {"capacidad": []},
    {"capacidad": "administrador"}, {"motivo": ""}, {"motivo": "x" * 501},
    {"id_usuario": 1}, {"id_usuario": 3}, {"id_usuario": 4},
    {"fecha_expiracion": "2030-01-01"}, {"fecha_expiracion": "2000-01-01T00:00:00Z"},
    {"campo_desconocido": "no"},
])
def test_validaciones_sin_concesion(entorno, cambios):
    assert conceder(entorno, **cambios).status_code in (400, 403)
    app, _, _ = entorno
    with app.app_context():
        assert ASIGNACION_FINANCIERA.query.count() == 0


def test_idempotencia_obligatoria_y_expiracion(entorno):
    app, cliente, tokens = entorno
    datos = {"id_usuario": 2, "id_campania": 1, "capacidad": "revision", "motivo": "Temporal"}
    assert cliente.post("/api/financial-assignments", json=datos, headers={"Authorization": f"Bearer {tokens[1]}"}).status_code == 400
    assert conceder(entorno, fecha_expiracion="2030-01-01T00:00:00-05:00").status_code == 201
    with app.app_context():
        asignacion = ASIGNACION_FINANCIERA.query.one()
        assert asignacion.fecha_expiracion == datetime(2030, 1, 1, 5)
        assert not asignacion.vigente(datetime(2030, 1, 1, 5))


@pytest.mark.parametrize("etapa", ["auditoria", "evento", "commit"])
def test_fallo_atomico_no_deja_asignacion_ni_evento(entorno, monkeypatch, etapa):
    app, _, _ = entorno
    def fallar(*args, **kwargs):
        raise SQLAlchemyError("fallo sintético")
    with app.app_context():
        clase = db.session.session_factory.class_
    with monkeypatch.context() as parche:
        if etapa == "auditoria":
            parche.setattr(servicio, "registrar", fallar)
        elif etapa == "evento":
            event.listen(EVENTO_ASIGNACION_FINANCIERA, "before_insert", fallar)
        else:
            event.listen(clase, "before_commit", fallar)
        try:
            assert conceder(entorno).status_code == 503
        finally:
            if etapa == "evento":
                event.remove(EVENTO_ASIGNACION_FINANCIERA, "before_insert", fallar)
            elif etapa == "commit":
                event.remove(clase, "before_commit", fallar)
    with app.app_context():
        assert ASIGNACION_FINANCIERA.query.count() == 0
        assert EVENTO_ASIGNACION_FINANCIERA.query.count() == 0
        assert AUDITORIA.query.count() == 0
    assert conceder(entorno).status_code == 201


def test_historial_restringido_y_listado_propio(entorno):
    _, cliente, tokens = entorno
    identificador = conceder(entorno).get_json()["id_asignacion"]
    assert cliente.get(f"/api/financial-assignments/{identificador}/events", headers=cabeceras(tokens, 2)).status_code == 403
    assert len(cliente.get("/api/financial-assignments/mine", headers=cabeceras(tokens, 2)).get_json()["asignaciones"]) == 1
    assert cliente.get("/api/financial-assignments/mine", headers=cabeceras(tokens, 5)).get_json()["asignaciones"] == []


def test_restricciones_db_y_sqlite_no_habilitado_fuera_de_pruebas(entorno):
    app, _, _ = entorno
    assert conceder(entorno).status_code == 201
    with app.app_context():
        assert db.session.execute(text("PRAGMA foreign_keys")).scalar() == 1
        db.session.add(ASIGNACION_FINANCIERA(
            id_usuario=999, id_campania=1, capacidad="revision", id_concedente=1,
        ))
        with pytest.raises(IntegrityError):
            db.session.commit()
        db.session.rollback()
    app.config["TESTING"] = False
    assert conceder(entorno).status_code == 503


def test_modulo_desactivado_deniega_incluso_token_administrativo(entorno):
    app, cliente, tokens = entorno
    app.config["FINANCIAL_ASSIGNMENTS_ENABLED"] = False
    assert conceder(entorno).status_code == 403
    assert cliente.get("/api/financial-assignments/availability", headers=cabeceras(tokens)).status_code == 403


def test_unicidad_ambito_y_capacidad_en_base_de_datos(entorno):
    app, _, _ = entorno
    assert conceder(entorno).status_code == 201
    with app.app_context():
        for capacidad in ("revision", "administrador"):
            db.session.add(ASIGNACION_FINANCIERA(
                id_usuario=2, id_campania=1, capacidad=capacidad, id_concedente=1,
            ))
            with pytest.raises(IntegrityError):
                db.session.commit()
            db.session.rollback()
        assert ASIGNACION_FINANCIERA.query.count() == 1


def test_revocacion_fallida_conserva_permiso_e_historial(entorno, monkeypatch):
    app, cliente, tokens = entorno
    identificador = conceder(entorno).get_json()["id_asignacion"]
    def fallar(*args, **kwargs):
        raise SQLAlchemyError("auditoría no disponible")
    with monkeypatch.context() as parche:
        parche.setattr(servicio, "registrar", fallar)
        respuesta = cliente.post(
            f"/api/financial-assignments/{identificador}/revoke",
            json={"motivo": "Fin de asignación"}, headers=cabeceras(tokens, clave="revocacion"),
        )
        assert respuesta.status_code == 503
    with app.app_context():
        assert db.session.get(ASIGNACION_FINANCIERA, identificador).vigente()
        assert EVENTO_ASIGNACION_FINANCIERA.query.count() == 1
        assert AUDITORIA.query.count() == 1


def test_asignacion_expirada_no_autoriza(entorno):
    app, _, tokens = entorno
    assert conceder(entorno).status_code == 201
    with app.app_context():
        asignacion = ASIGNACION_FINANCIERA.query.one()
        asignacion.fecha_concesion = datetime(2000, 1, 1)
        asignacion.fecha_expiracion = datetime(2001, 1, 1)
        db.session.commit()
    from flask_jwt_extended import verify_jwt_in_request
    with app.test_request_context(headers=cabeceras(tokens, 2)):
        verify_jwt_in_request()
        with pytest.raises(ErrorFinanciero):
            exigir_asignacion(1, "revision")


def test_registro_condicional_no_importa_modelos_ni_inicializa_aplicacion():
    codigo = """
import sys
from flask import Flask
from models import db
from routes import register_blueprints
app = Flask('registro_sin_arranque')
register_blueprints(app)
assert 'ASIGNACION_FINANCIERA' not in db.metadata.tables
assert not any(r.rule.startswith('/api/financial-assignments') for r in app.url_map.iter_rules())
assert 'app' not in sys.modules
app_habilitada = Flask('registro_habilitado_sin_arranque')
app_habilitada.config['FINANCIAL_ASSIGNMENTS_ENABLED'] = True
register_blueprints(app_habilitada)
assert 'ASIGNACION_FINANCIERA' in db.metadata.tables
assert any(r.rule == '/api/financial-assignments' for r in app_habilitada.url_map.iter_rules())
assert 'app' not in sys.modules
"""
    backend = Path(__file__).resolve().parents[1]
    resultado = subprocess.run([sys.executable, "-B", "-c", codigo], cwd=backend, capture_output=True, text=True)
    assert resultado.returncode == 0, resultado.stderr


def test_respuestas_privadas_sin_cache_compartida(entorno):
    _, cliente, tokens = entorno
    for usuario in (1, 4):
        respuesta = cliente.get("/api/financial-assignments", headers=cabeceras(tokens, usuario))
        assert respuesta.headers["Cache-Control"] == "private, no-store"
        assert respuesta.headers["X-Content-Type-Options"] == "nosniff"


@pytest.mark.parametrize("clave", [" ", "x" * 129, " " * 128 + "x"])
def test_clave_idempotente_no_admite_blancos_ni_exceso_real(entorno, clave):
    app, cliente, tokens = entorno
    respuesta = cliente.post(
        "/api/financial-assignments",
        json={"id_usuario": 2, "id_campania": 1, "capacidad": "revision", "motivo": "Prueba"},
        headers=cabeceras(tokens, clave=clave),
    )
    assert respuesta.status_code == 400
    with app.app_context():
        assert ASIGNACION_FINANCIERA.query.count() == 0
