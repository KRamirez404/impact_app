from flask import current_app
from flask_jwt_extended import get_jwt_identity

from models import CAMPAÑA, USUARIO
from models.asignacion_financiera import ASIGNACION_FINANCIERA, CAPACIDADES_FINANCIERAS


class ErrorFinanciero(Exception):
    def __init__(self, mensaje, estado=403):
        super().__init__(mensaje)
        self.estado = estado


def usuario_financiero():
    if not current_app.config.get("FINANCIAL_ASSIGNMENTS_ENABLED", False):
        raise ErrorFinanciero("Módulo financiero no habilitado")
    identidad = get_jwt_identity()
    try:
        identificador = int(identidad)
    except (TypeError, ValueError):
        raise ErrorFinanciero("Sesión inválida", 401)
    usuario = USUARIO.query.filter_by(id_usuario=identificador).populate_existing().first()
    if usuario is None or usuario.estado != "activo":
        raise ErrorFinanciero("Acceso financiero denegado")
    return usuario


def administrador_financiero():
    usuario = usuario_financiero()
    designado = current_app.config.get("FINANCIAL_ADMIN_USER_ID")
    texto = str(designado or "")
    if isinstance(designado, bool) or not 1 <= len(texto) <= 10 or not texto.isascii() or not texto.isdigit():
        raise ErrorFinanciero("Administración financiera no habilitada")
    if usuario.rol != "soporte" or usuario.id_usuario != int(designado):
        raise ErrorFinanciero("Acceso financiero denegado")
    return usuario


def exigir_asignacion(id_campania, capacidad):
    usuario = usuario_financiero()
    if capacidad not in CAPACIDADES_FINANCIERAS or usuario.rol != "soporte":
        raise ErrorFinanciero("Acceso financiero denegado")
    asignacion = ASIGNACION_FINANCIERA.query.filter_by(
        id_usuario=usuario.id_usuario, id_campania=id_campania, capacidad=capacidad,
    ).populate_existing().first()
    if asignacion is None or not asignacion.vigente():
        raise ErrorFinanciero("Asignación financiera no vigente")
    return usuario


def exigir_doble_control(id_campania, id_confirmador):
    autorizador = exigir_asignacion(id_campania, "contabilizacion")
    campania = CAMPAÑA.query.filter_by(id_campania=id_campania).populate_existing().first()
    confirmador = USUARIO.query.filter_by(id_usuario=id_confirmador).populate_existing().first()
    if (
        autorizador.id_usuario == id_confirmador
        or confirmador is None or confirmador.estado != "activo"
        or confirmador.rol != "organizador"
        or campania is None or campania.id_creador != id_confirmador
    ):
        raise ErrorFinanciero("Se requiere confirmación independiente del organizador de la campaña")
    return autorizador
