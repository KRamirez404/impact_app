import hashlib
import json
from datetime import datetime, timezone

from flask import current_app

from models import CAMPAÑA, USUARIO, db
from models.asignacion_financiera import (
    ASIGNACION_FINANCIERA, CAPACIDADES_FINANCIERAS, EVENTO_ASIGNACION_FINANCIERA, ahora_utc,
)
from services.audit_service import registrar
from services.autorizacion_financiera import ErrorFinanciero, administrador_financiero


def validar_entero(valor, nombre):
    if type(valor) is not int or not 0 < valor <= 2147483647:
        raise ErrorFinanciero(f"{nombre} debe ser un entero positivo válido", 400)
    return valor


def _motivo(datos):
    motivo = datos.get("motivo")
    if not isinstance(motivo, str) or not 1 <= len(motivo.strip()) <= 500:
        raise ErrorFinanciero("motivo debe tener entre 1 y 500 caracteres", 400)
    return motivo.strip()


def _expiracion(valor):
    if valor is None:
        return None
    try:
        fecha = datetime.fromisoformat(valor.replace("Z", "+00:00"))
        if fecha.tzinfo is None:
            raise ValueError()
        return fecha.astimezone(timezone.utc).replace(tzinfo=None)
    except (AttributeError, TypeError, ValueError):
        raise ErrorFinanciero("fecha_expiracion debe incluir zona horaria", 400)


def _solicitud(actor, clave, contenido):
    if not isinstance(clave, str) or not clave.strip() or len(clave) > 128:
        raise ErrorFinanciero("Idempotency-Key es obligatoria y admite hasta 128 caracteres", 400)
    identificador = hashlib.sha256(f"{actor.id_usuario}:{clave}".encode()).hexdigest()
    huella = hashlib.sha256(json.dumps(contenido, sort_keys=True, ensure_ascii=False).encode()).hexdigest()
    anterior = EVENTO_ASIGNACION_FINANCIERA.query.filter_by(clave_idempotencia=identificador).first()
    if anterior is not None and anterior.huella_solicitud != huella:
        raise ErrorFinanciero("Idempotency-Key ya utilizada con otros datos", 409)
    return identificador, huella, anterior


def _bloquear(actor, id_usuario, id_campania):
    if db.engine.dialect.name != "postgresql" and not current_app.testing:
        raise ErrorFinanciero("La administración financiera requiere PostgreSQL", 503)
    for identificador in sorted({actor.id_usuario, id_usuario}):
        USUARIO.query.filter_by(id_usuario=identificador).populate_existing().with_for_update().first()
    administrador_financiero()
    campania = CAMPAÑA.query.filter_by(id_campania=id_campania).populate_existing().with_for_update().first()
    if campania is None:
        raise ErrorFinanciero("Campaña no encontrada", 404)
    return campania


def _evento(asignacion, actor, accion, motivo, anterior, clave, huella, direccion_ip):
    db.session.flush()
    evento = EVENTO_ASIGNACION_FINANCIERA(
        id_asignacion=asignacion.id_asignacion, id_actor=actor.id_usuario,
        accion=accion, motivo=motivo, estado_anterior=anterior,
        estado_nuevo="vigente" if accion == "concedida" else "revocada",
        fecha_expiracion=asignacion.fecha_expiracion,
        clave_idempotencia=clave, huella_solicitud=huella,
    )
    db.session.add(evento)
    registrar(
        id_usuario=actor.id_usuario, accion=f"ASIGNACION_FINANCIERA_{accion.upper()}",
        entidad="ASIGNACION_FINANCIERA", id_entidad=asignacion.id_asignacion,
        descripcion=f"{anterior} -> {evento.estado_nuevo}",
        direccion_ip=direccion_ip, confirmar=False,
    )
    db.session.flush()
    return evento


def conceder(datos, clave, direccion_ip=None):
    actor = administrador_financiero()
    id_usuario = validar_entero(datos.get("id_usuario"), "id_usuario")
    id_campania = validar_entero(datos.get("id_campania"), "id_campania")
    capacidad = datos.get("capacidad")
    if not isinstance(capacidad, str) or capacidad not in CAPACIDADES_FINANCIERAS:
        raise ErrorFinanciero("Capacidad financiera inválida", 400)
    motivo = _motivo(datos)
    expiracion = _expiracion(datos.get("fecha_expiracion"))
    campania = _bloquear(actor, id_usuario, id_campania)
    contenido = {
        "accion": "concedida", "id_usuario": id_usuario, "id_campania": id_campania,
        "capacidad": capacidad, "motivo": motivo,
        "fecha_expiracion": expiracion.isoformat() if expiracion else None,
    }
    clave, huella, anterior = _solicitud(actor, clave, contenido)
    if anterior:
        return anterior, False
    usuario = db.session.get(USUARIO, id_usuario)
    if usuario is None or usuario.estado != "activo" or usuario.rol != "soporte":
        raise ErrorFinanciero("El destinatario debe ser un usuario de soporte activo", 400)
    if actor.id_usuario == id_usuario or campania.id_creador == id_usuario:
        raise ErrorFinanciero("No se permite asignar facultades al concedente ni al creador de la campaña")
    if campania.eliminada:
        raise ErrorFinanciero("La campaña no está disponible", 409)
    ahora = ahora_utc()
    if expiracion is not None and expiracion <= ahora:
        raise ErrorFinanciero("fecha_expiracion debe ser futura", 400)
    asignacion = ASIGNACION_FINANCIERA.query.filter_by(
        id_usuario=id_usuario, id_campania=id_campania, capacidad=capacidad,
    ).populate_existing().with_for_update().first()
    estado = "inexistente"
    if asignacion is not None:
        if asignacion.vigente(ahora):
            raise ErrorFinanciero("Ya existe una asignación vigente", 409)
        estado = "revocada" if asignacion.fecha_revocacion else "expirada"
    else:
        asignacion = ASIGNACION_FINANCIERA(id_usuario=id_usuario, id_campania=id_campania, capacidad=capacidad)
        db.session.add(asignacion)
    asignacion.id_concedente = actor.id_usuario
    asignacion.fecha_concesion = ahora
    asignacion.fecha_expiracion = expiracion
    asignacion.id_revocador = None
    asignacion.fecha_revocacion = None
    return _evento(asignacion, actor, "concedida", motivo, estado, clave, huella, direccion_ip), True


def revocar(id_asignacion, datos, clave, direccion_ip=None):
    actor = administrador_financiero()
    motivo = _motivo(datos)
    asignacion = db.session.get(ASIGNACION_FINANCIERA, id_asignacion)
    if asignacion is None:
        raise ErrorFinanciero("Asignación no encontrada", 404)
    _bloquear(actor, asignacion.id_usuario, asignacion.id_campania)
    asignacion = ASIGNACION_FINANCIERA.query.filter_by(id_asignacion=id_asignacion).populate_existing().with_for_update().one()
    clave, huella, anterior = _solicitud(actor, clave, {
        "accion": "revocada", "id_asignacion": id_asignacion, "motivo": motivo,
    })
    if anterior:
        return anterior, False
    if asignacion.fecha_revocacion:
        raise ErrorFinanciero("La asignación ya está revocada", 409)
    estado = "vigente" if asignacion.vigente() else "expirada"
    asignacion.fecha_revocacion = ahora_utc()
    asignacion.id_revocador = actor.id_usuario
    return _evento(asignacion, actor, "revocada", motivo, estado, clave, huella, direccion_ip), True
