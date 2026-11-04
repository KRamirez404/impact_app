from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy.exc import SQLAlchemyError

from models import USUARIO, db
from models.asignacion_financiera import ASIGNACION_FINANCIERA, EVENTO_ASIGNACION_FINANCIERA
from services import asignacion_financiera_service as servicio
from services.audit_service import registrar
from services.autorizacion_financiera import ErrorFinanciero, administrador_financiero, usuario_financiero


financial_assignment_bp = Blueprint("financial_assignment_bp", __name__, url_prefix="/api/financial-assignments")


@financial_assignment_bp.after_request
def respuesta_privada(respuesta):
    respuesta.headers["Cache-Control"] = "private, no-store"
    respuesta.headers["X-Content-Type-Options"] = "nosniff"
    return respuesta


def _datos(campos):
    datos = request.get_json(silent=True)
    if not isinstance(datos, dict) or set(datos) - set(campos):
        raise ErrorFinanciero("Objeto JSON inválido o campos no permitidos", 400)
    return datos


@financial_assignment_bp.errorhandler(ErrorFinanciero)
def error_financiero(error):
    db.session.rollback()
    if error.estado in (401, 403, 404):
        identidad = get_jwt_identity()
        try:
            usuario = db.session.get(USUARIO, int(identidad))
        except (ValueError, TypeError):
            usuario = None
        try:
            registrar(
                id_usuario=usuario.id_usuario if usuario else None,
                accion="ACCESO_FINANCIERO_DENEGADO", entidad="ASIGNACION_FINANCIERA",
                descripcion=f"{request.method} {request.url_rule.rule if request.url_rule else ''}; denegado",
                direccion_ip=request.remote_addr, confirmar=False,
            )
            db.session.commit()
        except SQLAlchemyError:
            db.session.rollback()
            return jsonify({"error": "No fue posible registrar la operación"}), 503
    return jsonify({"error": str(error)}), error.estado


@financial_assignment_bp.errorhandler(SQLAlchemyError)
def error_persistencia(error):
    db.session.rollback()
    return jsonify({"error": "No fue posible registrar la operación. Reintenta con la misma clave."}), 503


@financial_assignment_bp.post("")
@jwt_required()
def conceder_asignacion():
    administrador_financiero()
    datos = _datos({"id_usuario", "id_campania", "capacidad", "motivo", "fecha_expiracion"})
    evento, creado = servicio.conceder(datos, request.headers.get("Idempotency-Key"), request.remote_addr)
    respuesta = evento.to_dict()
    db.session.commit()
    return jsonify(respuesta), 201 if creado else 200


@financial_assignment_bp.post("/<int:id_asignacion>/revoke")
@jwt_required()
def revocar_asignacion(id_asignacion):
    administrador_financiero()
    evento, _ = servicio.revocar(
        id_asignacion, _datos({"motivo"}), request.headers.get("Idempotency-Key"), request.remote_addr,
    )
    respuesta = evento.to_dict()
    db.session.commit()
    return jsonify(respuesta), 200


@financial_assignment_bp.get("")
@jwt_required()
def listar_asignaciones():
    administrador_financiero()
    return _listado(ASIGNACION_FINANCIERA.query)


def _listado(consulta):
    pagina = max(1, request.args.get("page", 1, type=int))
    filas = consulta.order_by(ASIGNACION_FINANCIERA.id_asignacion).limit(50).offset((pagina - 1) * 50).all()
    return jsonify({"asignaciones": [fila.to_dict() for fila in filas], "pagina": pagina}), 200


@financial_assignment_bp.get("/mine")
@jwt_required()
def mis_asignaciones():
    usuario = usuario_financiero()
    if usuario.rol != "soporte":
        raise ErrorFinanciero("Acceso financiero denegado")
    return _listado(ASIGNACION_FINANCIERA.query.filter_by(id_usuario=usuario.id_usuario))


@financial_assignment_bp.get("/<int:id_asignacion>/events")
@jwt_required()
def historial_asignacion(id_asignacion):
    administrador_financiero()
    if db.session.get(ASIGNACION_FINANCIERA, id_asignacion) is None:
        raise ErrorFinanciero("Asignación no encontrada", 404)
    pagina = max(1, request.args.get("page", 1, type=int))
    eventos = EVENTO_ASIGNACION_FINANCIERA.query.filter_by(id_asignacion=id_asignacion).order_by(
        EVENTO_ASIGNACION_FINANCIERA.id_evento,
    ).limit(50).offset((pagina - 1) * 50).all()
    return jsonify({"eventos": [evento.to_dict() for evento in eventos], "pagina": pagina}), 200


@financial_assignment_bp.get("/availability")
@jwt_required()
def disponibilidad():
    usuario_financiero()
    return jsonify({
        "asignaciones_habilitadas": bool(current_app.config.get("FINANCIAL_ASSIGNMENTS_ENABLED")),
        "fuente_bancaria_disponible": False,
        "contabilizacion_disponible": False,
        "motivo": "Fuente bancaria independiente pendiente; no existe contabilización bancaria habilitada",
    }), 200
