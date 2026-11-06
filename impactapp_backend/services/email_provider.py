"""Adaptador de envío por API HTTPS con proveedores externos de correo."""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from email.utils import parseaddr

PROVEEDORES_API = ("brevo",)

URLS_POR_DEFECTO = {
    "brevo": "https://api.brevo.com/v3/smtp/email",
}


class ErrorProveedor(Exception):
    """Error saneado del proveedor; no contiene datos personales ni secretos."""

    def __init__(self, codigo, reintentable=True):
        super().__init__(codigo)
        self.codigo = codigo
        self.reintentable = reintentable


def _texto(valor, limite=255):
    if valor is None:
        return ""
    return str(valor).strip()[:limite]


def _remitente(config):
    nombre_config, correo = parseaddr(_texto(config.get("MAIL_FROM"), 150))
    if not correo or "@" not in correo:
        raise ErrorProveedor("ConfiguracionProveedorIncompleta", reintentable=False)
    nombre = (
        _texto(config.get("MAIL_FROM_NAME"), 70)
        or _texto(nombre_config, 70)
        or "ImpactApp"
    )
    return correo, nombre


def _payload_brevo(notificacion, config):
    correo, nombre = _remitente(config)
    payload = {
        "sender": {"email": correo, "name": nombre},
        "to": [{"email": notificacion.destinatario}],
        "subject": notificacion.asunto,
        "textContent": notificacion.cuerpo_texto,
    }
    if notificacion.cuerpo_html:
        payload["htmlContent"] = notificacion.cuerpo_html
    return payload


def _payload(proveedor, notificacion, config):
    if proveedor == "brevo":
        return _payload_brevo(notificacion, config)
    raise ErrorProveedor("ProveedorNoSoportado", reintentable=False)


def _cabeceras(proveedor, config):
    if proveedor == "brevo":
        return {
            "accept": "application/json",
            "content-type": "application/json",
            "api-key": config.get("MAIL_API_KEY") or "",
        }
    raise ErrorProveedor("ProveedorNoSoportado", reintentable=False)


def _post_json(url, payload, headers, timeout):
    datos = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    solicitud = urllib.request.Request(
        url, data=datos, headers=headers, method="POST"
    )
    try:
        with urllib.request.urlopen(solicitud, timeout=timeout) as respuesta:
            return respuesta.getcode(), respuesta.read(4096)
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read(4096)


def enviar(notificacion, config):
    """Envía una notificación por API HTTPS y lanza ``ErrorProveedor`` si falla."""
    proveedor = _texto(config.get("MAIL_PROVIDER"), 20).lower()
    if proveedor not in PROVEEDORES_API:
        raise ErrorProveedor("ProveedorNoSoportado", reintentable=False)

    api_key = _texto(config.get("MAIL_API_KEY"), 255)
    if not api_key:
        raise ErrorProveedor("ConfiguracionProveedorIncompleta", reintentable=False)

    url = _texto(config.get("MAIL_API_URL"), 500) or URLS_POR_DEFECTO[proveedor]
    try:
        timeout = max(1, int(config.get("MAIL_API_TIMEOUT", 10)))
    except (TypeError, ValueError):
        timeout = 10

    payload = _payload(proveedor, notificacion, config)
    headers = _cabeceras(proveedor, config)

    try:
        estado, _cuerpo = _post_json(url, payload, headers, timeout)
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        raise ErrorProveedor("ConexionProveedorFallida", reintentable=True) from exc

    if 200 <= estado < 300:
        return
    if estado in (401, 403):
        raise ErrorProveedor("ProveedorAutenticacionFallida", reintentable=False)
    if estado == 429:
        raise ErrorProveedor("ProveedorLimiteAlcanzado", reintentable=True)
    if estado >= 500:
        raise ErrorProveedor("ProveedorNoDisponible", reintentable=True)
    raise ErrorProveedor("ProveedorRechazoSolicitud", reintentable=False)
