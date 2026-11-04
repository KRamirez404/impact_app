"""Notificaciones por correo con patrón outbox.

Los eventos financieros se registran en la tabla ``NOTIFICACION_EMAIL`` y se
envían después del commit del pago. Un fallo de SMTP nunca revierte la
operación financiera: solo deja la notificación en estado ``fallido`` para que
el script de reintentos la procese más tarde.
"""

from __future__ import annotations

import html
import smtplib
from datetime import datetime
from decimal import Decimal, InvalidOperation
from email.message import EmailMessage

from flask import current_app
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

from models import NOTIFICACION_EMAIL, db

ESTADOS = ("pendiente", "enviado", "fallido")

TIPOS = (
    "donacion_pendiente",
    "donacion_aprobada",
    "donacion_rechazada",
    "donacion_anulada",
    "donacion_error",
    "transferencia_comprobante",
    "transferencia_aprobada",
    "transferencia_rechazada",
)

_PIE_TEXTO = (
    "\n\nEste es un mensaje automático de ImpactApp. "
    "No respondas a este correo."
)
_PIE_HTML = (
    '<p style="color:#6b7280;font-size:12px;margin-top:24px">'
    "Este es un mensaje automático de ImpactApp. No respondas a este correo."
    "</p>"
)


def _texto(valor, limite=200):
    if valor is None:
        return ""
    return str(valor).strip()[:limite]


def _monto(valor):
    try:
        numero = Decimal(str(valor))
    except (InvalidOperation, TypeError, ValueError):
        return _texto(valor, 40)
    return "$" + format(numero, ",.0f").replace(",", ".")


def _cuerpo(titulo, parrafos, detalle=None):
    lineas = [titulo, ""]
    lineas.extend(parrafos)
    if detalle:
        lineas.append("")
        lineas.extend(f"{clave}: {valor}" for clave, valor in detalle if valor)
    texto = "\n".join(lineas) + _PIE_TEXTO

    bloques = "".join(
        f'<p style="margin:0 0 12px">{html.escape(parrafo)}</p>' for parrafo in parrafos
    )
    filas = ""
    if detalle:
        filas = "".join(
            "<tr>"
            f'<td style="padding:4px 12px 4px 0;color:#374151"><strong>{html.escape(clave)}</strong></td>'
            f'<td style="padding:4px 0;color:#111827">{html.escape(str(valor))}</td>'
            "</tr>"
            for clave, valor in detalle
            if valor
        )
        filas = f'<table style="margin:0 0 12px;border-collapse:collapse">{filas}</table>'
    cuerpo = (
        '<div style="font-family:Arial,Helvetica,sans-serif;font-size:14px;color:#111827">'
        f'<h2 style="font-size:18px;margin:0 0 16px">{html.escape(titulo)}</h2>'
        f"{bloques}{filas}{_PIE_HTML}</div>"
    )
    return texto, cuerpo


def _saludo(contexto):
    nombre = _texto(contexto.get("nombre"), 80)
    return f"Hola {nombre}," if nombre else "Hola,"


def construir(tipo, contexto):
    """Devuelve (asunto, texto, html) para un tipo de notificación."""
    if tipo not in TIPOS:
        raise ValueError("tipo_notificacion_desconocido")

    nombre_campania = _texto(contexto.get("campania"), 160)
    monto = _monto(contexto.get("monto")) if contexto.get("monto") is not None else ""
    referencia = _texto(contexto.get("referencia"), 120)
    motivo = _texto(contexto.get("motivo"), 300)
    detalle = [
        ("Campaña", nombre_campania),
        ("Monto", monto),
        ("Referencia", referencia),
    ]

    if tipo == "donacion_pendiente":
        asunto = "Recibimos tu intención de donación"
        parrafos = [
            _saludo(contexto),
            "Registramos tu donación y quedó pendiente de confirmación del pago.",
            "Cuando el proveedor confirme la transacción te avisaremos por este medio.",
        ]
    elif tipo == "donacion_aprobada":
        asunto = "¡Tu donación fue confirmada!"
        parrafos = [
            _saludo(contexto),
            "Confirmamos el pago de tu donación. Gracias por apoyar esta causa.",
        ]
    elif tipo == "donacion_rechazada":
        asunto = "Tu donación no pudo completarse"
        parrafos = [
            _saludo(contexto),
            "El pago de tu donación fue rechazado por el proveedor.",
            "Puedes intentarlo nuevamente desde la campaña.",
        ]
        detalle.append(("Motivo", motivo))
    elif tipo == "donacion_anulada":
        asunto = "Tu donación fue anulada"
        parrafos = [
            _saludo(contexto),
            "La transacción asociada a tu donación fue anulada.",
            "Si no reconoces esta operación, contacta al equipo de soporte.",
        ]
        detalle.append(("Motivo", motivo))
    elif tipo == "donacion_error":
        asunto = "No pudimos confirmar tu donación"
        parrafos = [
            _saludo(contexto),
            "El proveedor reportó un error al procesar el pago de tu donación.",
            "Si el cargo aparece en tu extracto, contacta al equipo de soporte con la referencia.",
        ]
        detalle.append(("Detalle", motivo))
    elif tipo == "transferencia_comprobante":
        asunto = "Recibimos el comprobante de tu transferencia"
        parrafos = [
            _saludo(contexto),
            "Tu comprobante quedó registrado y será revisado por el equipo de soporte.",
            "Te avisaremos cuando la transferencia sea aprobada o rechazada.",
        ]
    elif tipo == "transferencia_aprobada":
        asunto = "¡Tu transferencia fue aprobada!"
        parrafos = [
            _saludo(contexto),
            "Validamos tu transferencia bancaria y la donación quedó confirmada.",
            "Gracias por apoyar esta causa.",
        ]
    else:  # transferencia_rechazada
        asunto = "Tu transferencia fue rechazada"
        parrafos = [
            _saludo(contexto),
            "Revisamos tu transferencia y no fue posible aprobarla.",
            "Puedes corregir la información y adjuntar un nuevo comprobante.",
        ]
        detalle.append(("Motivo", motivo))

    texto, cuerpo_html = _cuerpo(asunto, parrafos, detalle)
    return asunto, texto, cuerpo_html


def encolar(tipo, destinatario, contexto, clave_evento):
    """Registra una notificación idempotente por ``clave_evento``.

    No confirma la transacción; el llamador decide cuándo hacer commit.
    """
    correo = _texto(destinatario, 150)
    clave = _texto(clave_evento, 160)
    if not correo or "@" not in correo or not clave:
        return None
    existente = NOTIFICACION_EMAIL.query.filter_by(clave_evento=clave).first()
    if existente is not None:
        return existente

    asunto, texto, cuerpo_html = construir(tipo, contexto or {})
    notificacion = NOTIFICACION_EMAIL(
        clave_evento=clave,
        destinatario=correo,
        tipo=tipo,
        asunto=asunto[:200],
        cuerpo_texto=texto,
        cuerpo_html=cuerpo_html,
        estado="pendiente",
    )
    try:
        with db.session.begin_nested():
            db.session.add(notificacion)
            db.session.flush()
    except IntegrityError:
        return NOTIFICACION_EMAIL.query.filter_by(clave_evento=clave).first()
    return notificacion


def _config(config):
    return config if config is not None else current_app.config


def _enviar_smtp(notificacion, config):
    host = _texto(config.get("MAIL_HOST"), 255)
    remitente = _texto(config.get("MAIL_FROM"), 150)
    if not host or not remitente:
        raise ValueError("configuracion_smtp_incompleta")

    mensaje = EmailMessage()
    mensaje["Subject"] = notificacion.asunto
    mensaje["From"] = remitente
    mensaje["To"] = notificacion.destinatario
    mensaje.set_content(notificacion.cuerpo_texto)
    if notificacion.cuerpo_html:
        mensaje.add_alternative(notificacion.cuerpo_html, subtype="html")

    puerto = int(config.get("MAIL_PORT", 587))
    timeout = int(config.get("MAIL_TIMEOUT", 10))
    usar_ssl = bool(config.get("MAIL_USE_SSL", False))
    usar_tls = bool(config.get("MAIL_USE_TLS", True)) and not usar_ssl
    usuario = _texto(config.get("MAIL_USERNAME"), 255)

    smtp_class = smtplib.SMTP_SSL if usar_ssl else smtplib.SMTP
    with smtp_class(host, puerto, timeout=timeout) as cliente:
        if usar_tls:
            cliente.starttls()
        if usuario:
            cliente.login(usuario, config.get("MAIL_PASSWORD") or "")
        cliente.send_message(mensaje)


def _error_saneado(exc):
    nombre = exc.__class__.__name__
    detalle = _texto(str(exc), 180)
    return _texto(f"{nombre}: {detalle}" if detalle else nombre, 255)


def intentar_envio(notificacion, config=None):
    """Intenta enviar una notificación. Nunca propaga errores de SMTP."""
    config = _config(config)
    if notificacion is None or notificacion.estado == "enviado":
        return notificacion is not None and notificacion.estado == "enviado"
    if not config.get("MAIL_ENABLED", False):
        return False
    max_intentos = int(config.get("MAIL_MAX_ATTEMPTS", 3))
    if notificacion.intentos >= max_intentos:
        return False

    notificacion.intentos += 1
    notificacion.actualizado_en = datetime.utcnow()
    try:
        _enviar_smtp(notificacion, config)
    except (smtplib.SMTPException, OSError, ValueError) as exc:
        notificacion.estado = "fallido"
        notificacion.ultimo_error = _error_saneado(exc)
        current_app.logger.warning(
            "Notificación %s falló (intento %s): %s",
            notificacion.id_notificacion,
            notificacion.intentos,
            notificacion.ultimo_error,
        )
        enviado = False
    except Exception as exc:  # defensa: el correo no debe romper el request
        notificacion.estado = "fallido"
        notificacion.ultimo_error = _error_saneado(exc)
        current_app.logger.warning(
            "Notificación %s falló de forma inesperada", notificacion.id_notificacion
        )
        enviado = False
    else:
        notificacion.estado = "enviado"
        notificacion.enviado_en = datetime.utcnow()
        notificacion.ultimo_error = None
        enviado = True

    try:
        db.session.commit()
    except SQLAlchemyError:
        db.session.rollback()
        current_app.logger.warning(
            "No fue posible actualizar la notificación %s",
            notificacion.id_notificacion,
        )
        return False
    return enviado


def enviar_pendientes(limit=50, config=None):
    """Procesa notificaciones no enviadas que aún tienen intentos disponibles."""
    config = _config(config)
    limite = max(1, min(int(limit), 500))
    max_intentos = int(config.get("MAIL_MAX_ATTEMPTS", 3))
    pendientes = (
        NOTIFICACION_EMAIL.query.filter(
            NOTIFICACION_EMAIL.estado != "enviado",
            NOTIFICACION_EMAIL.intentos < max_intentos,
        )
        .order_by(NOTIFICACION_EMAIL.creado_en.asc())
        .limit(limite)
        .all()
    )
    resultado = {"procesadas": 0, "enviadas": 0, "fallidas": 0}
    for notificacion in pendientes:
        resultado["procesadas"] += 1
        if intentar_envio(notificacion, config):
            resultado["enviadas"] += 1
        else:
            resultado["fallidas"] += 1
    return resultado


def registrar_y_enviar(tipo, destinatario, contexto, clave_evento, config=None):
    """Registra y, si está habilitado, envía sin afectar la transacción de negocio.

    Debe invocarse después del commit financiero.
    """
    notificacion = None
    try:
        existente = NOTIFICACION_EMAIL.query.filter_by(
            clave_evento=_texto(clave_evento, 160)
        ).first()
        if existente is not None:
            return existente
        notificacion = encolar(tipo, destinatario, contexto, clave_evento)
        if notificacion is None:
            return None
        db.session.commit()
    except SQLAlchemyError:
        db.session.rollback()
        current_app.logger.warning(
            "No fue posible registrar la notificación %s", clave_evento
        )
        return None
    except Exception:
        db.session.rollback()
        current_app.logger.warning(
            "Error inesperado al registrar la notificación %s", clave_evento
        )
        return None
    try:
        intentar_envio(notificacion, config)
    except Exception:  # el envío jamás debe romper la respuesta al usuario
        db.session.rollback()
        current_app.logger.warning(
            "Error inesperado al enviar la notificación %s", clave_evento
        )
    return notificacion
