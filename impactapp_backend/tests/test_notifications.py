import threading
import os
import smtplib
import time
import uuid
from datetime import datetime

import pytest
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app import app
from conftest import get_support_token, get_token, register_user
from models import NOTIFICACION_EMAIL, PUNTO_RECOLECCION, db
from services import notification_service

# Se reutilizan los helpers y fixtures de los flujos ya probados.
from test_transfers import transfer_context  # noqa: F401
from test_wompi import _checkout, _donante_token, _event, wompi_config
from test_roles import _campaign_payload


class FakeSMTP:
    mensajes = []
    instancias = []
    fallar = False

    def __init__(self, host, port, timeout=None):
        self.host = host
        self.port = port
        self.timeout = timeout
        self.tls = False
        self.credenciales = None
        FakeSMTP.instancias.append(self)

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def starttls(self):
        self.tls = True

    def login(self, usuario, contrasena):
        self.credenciales = (usuario, contrasena)

    def send_message(self, mensaje):
        if FakeSMTP.fallar:
            raise smtplib.SMTPServerDisconnected("smtp no disponible")
        FakeSMTP.mensajes.append(mensaje)


@pytest.fixture()
def mail_config(monkeypatch):
    FakeSMTP.mensajes.clear()
    FakeSMTP.instancias.clear()
    FakeSMTP.fallar = False
    monkeypatch.setattr(notification_service.smtplib, "SMTP", FakeSMTP)
    monkeypatch.setattr(notification_service.smtplib, "SMTP_SSL", FakeSMTP)
    for clave, valor in {
        "MAIL_ENABLED": True,
        "MAIL_HOST": "smtp.test",
        "MAIL_PORT": 2525,
        "MAIL_USE_TLS": True,
        "MAIL_USE_SSL": False,
        "MAIL_USERNAME": "usuario-smtp",
        "MAIL_PASSWORD": "clave-secreta-smtp",
        "MAIL_FROM": "no-reply@impactapp.test",
        "MAIL_TIMEOUT": 2,
        "MAIL_MAX_ATTEMPTS": 2,
    }.items():
        monkeypatch.setitem(app.config, clave, valor)
    return FakeSMTP


def _contexto(**extra):
    datos = {
        "nombre": "Ana",
        "campania": "Campaña de prueba",
        "monto": "50000.00",
        "referencia": "IMPACTAPP-1",
    }
    datos.update(extra)
    return datos


def _notificacion(clave="evento-1", tipo="donacion_aprobada"):
    with app.app_context():
        fila = notification_service.encolar(
            tipo, "ana@test.co", _contexto(), clave
        )
        db.session.commit()
        return fila.id_notificacion


def test_registro_encola_bienvenida_una_vez_y_sin_secretos(client, mail_config):
    respuesta = register_user(client, correo="bienvenida@test.co", contrasena="Passw0rd!")
    assert respuesta.status_code == 201
    usuario = respuesta.get_json()["user"]
    with app.app_context():
        filas = NOTIFICACION_EMAIL.query.all()
        assert len(filas) == 1
        fila = filas[0]
        assert fila.clave_evento == f"usuario:{usuario['id_usuario']}:bienvenida"
        assert fila.destinatario == "bienvenida@test.co"
        assert fila.estado == "enviado"
        assert "Nombre" in fila.cuerpo_texto
        assert "Passw0rd!" not in fila.cuerpo_texto + fila.cuerpo_html
        assert "access_token" not in fila.cuerpo_texto + fila.cuerpo_html
    assert len(mail_config.mensajes) == 1
    assert mail_config.mensajes[0]["To"] == "bienvenida@test.co"
    assert register_user(client, correo="bienvenida@test.co").status_code == 400
    with app.app_context():
        assert NOTIFICACION_EMAIL.query.count() == 1


def test_registro_sin_smtp_no_se_revierte_y_se_reintenta(client, mail_config):
    mail_config.fallar = True
    respuesta = register_user(client, correo="reintento@test.co")
    assert respuesta.status_code == 201
    with app.app_context():
        fila = NOTIFICACION_EMAIL.query.one()
        assert fila.estado == "fallido"
        assert fila.intentos == 1
    mail_config.fallar = False
    with app.app_context():
        assert notification_service.enviar_pendientes()["enviadas"] == 1
        assert NOTIFICACION_EMAIL.query.one().estado == "enviado"


def test_registro_con_correo_deshabilitado_solo_encola(client, mail_config, monkeypatch):
    monkeypatch.setitem(app.config, "MAIL_ENABLED", False)
    assert register_user(client, correo="deshabilitado@test.co").status_code == 201
    with app.app_context():
        fila = NOTIFICACION_EMAIL.query.one()
        assert fila.estado == "pendiente"
        assert fila.intentos == 0
    assert not mail_config.mensajes


def test_campania_creada_notifica_al_organizador_sin_cuenta(client, mail_config):
    correo = "organizador_not@test.co"
    register_user(client, rol="organizador", correo=correo)
    token = get_token(client, correo)
    respuesta = client.post(
        "/api/campaigns", json=_campaign_payload(),
        headers={"Authorization": f"Bearer {token}"},
    )
    assert respuesta.status_code == 201
    with app.app_context():
        filas = NOTIFICACION_EMAIL.query.filter_by(tipo="campania_creada").all()
        assert len(filas) == 1
        fila = filas[0]
        assert fila.clave_evento == f"campania:{respuesta.get_json()['id_campania']}:creada"
        assert fila.destinatario == correo
        assert "Campaña de prueba" in fila.cuerpo_texto
        assert "pendiente de verificación" in fila.cuerpo_texto
        assert "1234567890" not in fila.cuerpo_texto + fila.cuerpo_html
    assert len(mail_config.mensajes) == 2


def test_donacion_en_especie_notifica_datos_de_entrega(client, mail_config):
    with app.app_context():
        punto = PUNTO_RECOLECCION(
            id_campania=1, id_ciudad=1, nombre="Centro solidario",
            direccion="Calle 12", horario="Lunes", contacto="Contacto privado",
        )
        db.session.add(punto)
        db.session.commit()
        id_punto = punto.id_punto
    correo = "donante_especie@test.co"
    register_user(client, correo=correo)
    token = get_token(client, correo)
    respuesta = client.post(
        "/api/donations",
        json={"id_campania": 1, "tipo": "alimentos", "descripcion": "Arroz y lentejas", "id_punto": id_punto},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert respuesta.status_code == 201
    with app.app_context():
        filas = NOTIFICACION_EMAIL.query.filter_by(tipo="donacion_especie").all()
        assert len(filas) == 1
        fila = filas[0]
        assert fila.clave_evento == f"donacion:{respuesta.get_json()['id_donacion']}:especie"
        assert fila.destinatario == correo
        for valor in ("Campaña", "alimentos", "Arroz y lentejas", "Centro solidario", "Calle 12"):
            assert valor in fila.cuerpo_texto
        assert "Contacto privado" not in fila.cuerpo_texto + fila.cuerpo_html
    assert len(mail_config.mensajes) == 2


def test_error_smtp_no_persiste_secretos_ni_los_registra(client, mail_config, monkeypatch, caplog):
    def fallo(_self, _mensaje):
        raise smtplib.SMTPAuthenticationError(
            535, b"clave-secreta-smtp token-privado 535 credenciales invalidas"
        )

    monkeypatch.setattr(FakeSMTP, "send_message", fallo)
    with app.app_context():
        id_notificacion = _notificacion(clave="error-secreto")
        fila = db.session.get(NOTIFICACION_EMAIL, id_notificacion)
        assert notification_service.intentar_envio(fila) is False
        db.session.refresh(fila)
        assert fila.estado == "fallido"
        assert fila.intentos == 1
        assert "clave-secreta-smtp" not in fila.ultimo_error
        assert "token-privado" not in fila.ultimo_error
    assert "clave-secreta-smtp" not in caplog.text
    assert "token-privado" not in caplog.text


def test_plantilla_escapa_html_y_conserva_texto():
    asunto, texto, cuerpo_html = notification_service.construir(
        "donacion_aprobada",
        _contexto(campania="<script>alert(1)</script>", monto=50000),
    )

    assert asunto == "¡Tu donación fue confirmada!"
    assert "Hola Ana" in texto
    assert "$50.000" in texto
    assert "<script>" not in cuerpo_html
    assert "&lt;script&gt;" in cuerpo_html


def test_plantillas_incluyen_fecha_estado_y_html_adaptable():
    fecha = datetime(2026, 11, 4, 14, 30)
    for tipo in ("bienvenida", "campania_creada", "donacion_especie", "donacion_aprobada", "transferencia_rechazada"):
        _, texto, cuerpo_html = notification_service.construir(
            tipo, _contexto(fecha=fecha, categoria="alimentos", descripcion="Arroz", punto="Centro")
        )
        assert "04/11/2026" in texto
        assert "04/11/2026" in cuerpo_html
        assert "ImpactApp" in texto and "ImpactApp" in cuerpo_html
        assert 'name="viewport"' in cuerpo_html
        assert "max-width" in cuerpo_html
    _, texto, _ = notification_service.construir("campania_creada", _contexto(fecha=fecha))
    assert "En verificación" in texto


@pytest.mark.parametrize("tipo,estado", [
    ("donacion_pendiente", "Pendiente"),
    ("donacion_aprobada", "Aprobada"),
    ("donacion_rechazada", "Rechazada"),
    ("donacion_anulada", "Anulada"),
    ("donacion_error", "Error"),
    ("transferencia_comprobante", "Registrada"),
    ("transferencia_aprobada", "Aprobada"),
    ("transferencia_rechazada", "Rechazada"),
])
def test_plantilla_financiera_identifica_estado_actual(tipo, estado):
    _, texto, cuerpo_html = notification_service.construir(tipo, _contexto())
    assert f"Estado: {estado}" in texto
    assert estado in cuerpo_html


def test_encolar_es_idempotente_por_clave(client):
    with app.app_context():
        primera = notification_service.encolar(
            "donacion_aprobada", "ana@test.co", _contexto(), "donacion:1:aprobada"
        )
        db.session.commit()
        segunda = notification_service.encolar(
            "donacion_aprobada", "ana@test.co", _contexto(), "donacion:1:aprobada"
        )
        db.session.commit()

        assert primera.id_notificacion == segunda.id_notificacion
        assert NOTIFICACION_EMAIL.query.count() == 1


def test_encolar_ignora_destinatario_invalido(client):
    with app.app_context():
        assert (
            notification_service.encolar(
                "donacion_aprobada", "sin-correo", _contexto(), "sin-correo"
            )
            is None
        )


def test_envio_exitoso_usa_smtp_configurado(client, mail_config):
    with app.app_context():
        notificacion = db.session.get(NOTIFICACION_EMAIL, _notificacion())
        assert notification_service.intentar_envio(notificacion) is True
        db.session.refresh(notificacion)
        assert notificacion.estado == "enviado"
        assert notificacion.intentos == 1
        assert notificacion.enviado_en is not None
        assert notificacion.ultimo_error is None

    assert len(mail_config.mensajes) == 1
    mensaje = mail_config.mensajes[0]
    assert mensaje["To"] == "ana@test.co"
    assert mensaje["From"] == "no-reply@impactapp.test"
    assert "confirmada" in mensaje["Subject"]
    assert mensaje.get_body(preferencelist=("html",)) is not None
    assert "¡Tu donación fue confirmada!" in mensaje.get_body(
        preferencelist=("html",)
    ).get_content()
    instancia = mail_config.instancias[0]
    assert instancia.host == "smtp.test"
    assert instancia.port == 2525
    assert instancia.tls is True
    assert instancia.credenciales == ("usuario-smtp", "clave-secreta-smtp")


def test_envio_relee_fila_por_id_aunque_objeto_este_desactualizado(client, mail_config):
    id_notificacion = _notificacion(clave="objeto-desactualizado")
    with app.app_context():
        notificacion = db.session.get(NOTIFICACION_EMAIL, id_notificacion)
        db.session.expunge(notificacion)
        notificacion.estado = "enviado"
        notificacion.intentos = 2
        assert notification_service.intentar_envio(notificacion) is True
        actual = db.session.get(NOTIFICACION_EMAIL, id_notificacion)
        assert (actual.estado, actual.intentos) == ("enviado", 1)
        assert actual.enviado_en is not None
    assert len(mail_config.mensajes) == 1


def test_lote_no_repite_fallido_y_conserva_contadores(client, mail_config, monkeypatch):
    primero = _notificacion(clave="lote-fallido")
    segundo = _notificacion(clave="lote-enviado")
    original = FakeSMTP.send_message
    llamadas = 0

    def enviar(self, mensaje):
        nonlocal llamadas
        llamadas += 1
        if llamadas == 1:
            raise smtplib.SMTPServerDisconnected("fallo de prueba")
        return original(self, mensaje)

    monkeypatch.setattr(FakeSMTP, "send_message", enviar)
    with app.app_context():
        assert notification_service.enviar_pendientes(limit=2) == {
            "procesadas": 2, "enviadas": 1, "fallidas": 1,
        }
        assert (db.session.get(NOTIFICACION_EMAIL, primero).estado,
                db.session.get(NOTIFICACION_EMAIL, primero).intentos) == ("fallido", 1)
        assert (db.session.get(NOTIFICACION_EMAIL, segundo).estado,
                db.session.get(NOTIFICACION_EMAIL, segundo).intentos) == ("enviado", 1)
    assert llamadas == 2
    assert len(mail_config.mensajes) == 1


def test_smtp_aceptado_y_commit_fallido_libera_fila_para_reintento(
    client, mail_config, monkeypatch
):
    id_notificacion = _notificacion(clave="aceptado-sin-commit")
    with app.app_context():
        notificacion = db.session.get(NOTIFICACION_EMAIL, id_notificacion)
        commit = db.session.commit

        def fallo_commit():
            raise SQLAlchemyError("fallo de prueba")

        monkeypatch.setattr(db.session, "commit", fallo_commit)
        assert notification_service.intentar_envio(notificacion) is False
        monkeypatch.setattr(db.session, "commit", commit)
        actual = db.session.get(NOTIFICACION_EMAIL, id_notificacion)
        assert (actual.estado, actual.intentos) == ("pendiente", 0)
        assert notification_service.intentar_envio(actual) is True
        db.session.refresh(actual)
        assert (actual.estado, actual.intentos) == ("enviado", 1)
    assert len(mail_config.mensajes) == 2


def test_fallo_smtp_se_registra_y_se_reintenta(client, mail_config):
    mail_config.fallar = True
    with app.app_context():
        notificacion = db.session.get(NOTIFICACION_EMAIL, _notificacion())
        assert notification_service.intentar_envio(notificacion) is False
        db.session.refresh(notificacion)
        assert notificacion.estado == "fallido"
        assert notificacion.intentos == 1
        assert "SMTPServerDisconnected" in notificacion.ultimo_error
        assert "clave-secreta-smtp" not in notificacion.ultimo_error

    mail_config.fallar = False
    with app.app_context():
        resultado = notification_service.enviar_pendientes()

    assert resultado == {"procesadas": 1, "enviadas": 1, "fallidas": 0}
    with app.app_context():
        notificacion = NOTIFICACION_EMAIL.query.one()
        assert notificacion.estado == "enviado"
        assert notificacion.intentos == 2


def test_evento_repetido_no_reintenta_correo_fallido(client, mail_config):
    mail_config.fallar = True
    with app.app_context():
        notification_service.registrar_y_enviar(
            "donacion_aprobada", "ana@test.co", _contexto(), "evento-repetido"
        )
        notificacion = NOTIFICACION_EMAIL.query.one()
        assert notificacion.estado == "fallido"
        assert notificacion.intentos == 1

        mail_config.fallar = False
        notification_service.registrar_y_enviar(
            "donacion_aprobada", "ana@test.co", _contexto(), "evento-repetido"
        )
        db.session.refresh(notificacion)
        assert NOTIFICACION_EMAIL.query.count() == 1
        assert notificacion.estado == "fallido"
        assert notificacion.intentos == 1
        assert mail_config.mensajes == []

        assert notification_service.enviar_pendientes()["enviadas"] == 1
        assert len(mail_config.mensajes) == 1


def test_reintentos_se_detienen_al_agotar_maximo(client, mail_config):
    mail_config.fallar = True
    with app.app_context():
        notificacion = db.session.get(NOTIFICACION_EMAIL, _notificacion())
        assert notification_service.intentar_envio(notificacion) is False
        db.session.refresh(notificacion)
        assert notification_service.intentar_envio(notificacion) is False
        db.session.refresh(notificacion)
        assert notificacion.intentos == 2
        assert notificacion.estado == "fallido"

        assert notification_service.enviar_pendientes() == {
            "procesadas": 0,
            "enviadas": 0,
            "fallidas": 0,
        }


def test_correo_deshabilitado_no_envia_ni_marca_error(client, mail_config, monkeypatch):
    monkeypatch.setitem(app.config, "MAIL_ENABLED", False)
    with app.app_context():
        notificacion = db.session.get(NOTIFICACION_EMAIL, _notificacion())
        assert notification_service.intentar_envio(notificacion) is False
        db.session.refresh(notificacion)
        assert notificacion.estado == "pendiente"
        assert notificacion.intentos == 0

    assert mail_config.mensajes == []


def _config_lote():
    return {
        "MAIL_ENABLED": True,
        "MAIL_HOST": "smtp.test",
        "MAIL_PORT": 2525,
        "MAIL_USE_TLS": True,
        "MAIL_USERNAME": "usuario-smtp",
        "MAIL_PASSWORD": "clave-secreta-smtp",
        "MAIL_FROM": "no-reply@impactapp.test",
        "MAIL_MAX_ATTEMPTS": 2,
    }


def test_dos_procesadores_postgresql_no_duplican_envio(client, mail_config):
    id_notificacion = _notificacion(clave="carrera-reclamacion-postgresql")
    with app.app_context():
        if db.engine.dialect.name != "postgresql":
            pytest.skip("Requiere bloqueos de fila PostgreSQL")
        smtp_original = notification_service._enviar_smtp

        def smtp_con_demora(notificacion, config):
            time.sleep(0.3)
            smtp_original(notificacion, config)

        notification_service._enviar_smtp = smtp_con_demora
        resultados = []

        def trabajador():
            with app.app_context():
                resultados.append(
                    notification_service.enviar_pendientes(config=_config_lote())
                )

        hilos = [threading.Thread(target=trabajador) for _ in range(2)]
        try:
            for hilo in hilos:
                hilo.start()
            for hilo in hilos:
                hilo.join()
        finally:
            notification_service._enviar_smtp = smtp_original

        combinado = {
            clave: sum(resultado[clave] for resultado in resultados)
            for clave in ("procesadas", "enviadas", "fallidas")
        }
        fila = db.session.get(NOTIFICACION_EMAIL, id_notificacion)
        assert combinado == {"procesadas": 1, "enviadas": 1, "fallidas": 0}
        assert (fila.estado, fila.intentos) == ("enviado", 1)
    assert len(mail_config.mensajes) == 1


def test_fila_bloqueada_omitida_y_procesada_al_liberar_postgresql(client, mail_config):
    id_notificacion = _notificacion(clave="bloqueo-exclusivo-postgresql")
    with app.app_context():
        if db.engine.dialect.name != "postgresql":
            pytest.skip("Requiere bloqueos de fila PostgreSQL")
        config = _config_lote()
        bloqueo = db.engine.connect()
        transaccion = bloqueo.begin()
        try:
            bloqueo.execute(
                text(
                    'SELECT id_notificacion FROM "NOTIFICACION_EMAIL" '
                    "WHERE id_notificacion = :id FOR UPDATE"
                ),
                {"id": id_notificacion},
            )
            assert notification_service.enviar_pendientes(config=config) == {
                "procesadas": 0,
                "enviadas": 0,
                "fallidas": 0,
            }
            assert mail_config.mensajes == []
        finally:
            transaccion.rollback()
            bloqueo.close()

        assert notification_service.enviar_pendientes(config=config) == {
            "procesadas": 1,
            "enviadas": 1,
            "fallidas": 0,
        }
        fila = db.session.get(NOTIFICACION_EMAIL, id_notificacion)
        assert (fila.estado, fila.intentos) == ("enviado", 1)
    assert len(mail_config.mensajes) == 1


def test_checkout_y_aprobacion_wompi_notifican_al_donante(
    client, wompi_config, mail_config
):
    token = _donante_token(client)
    checkout = _checkout(client, token, amount=50000)
    assert checkout.status_code == 201
    donacion = checkout.get_json()

    webhook = client.post(
        "/api/webhooks/wompi", json=_event(donacion["referencia"])
    )
    assert webhook.status_code == 200

    with app.app_context():
        filas = NOTIFICACION_EMAIL.query.filter(
            NOTIFICACION_EMAIL.tipo.in_(("donacion_pendiente", "donacion_aprobada"))
        ).order_by(NOTIFICACION_EMAIL.id_notificacion).all()
        assert [fila.tipo for fila in filas] == [
            "donacion_pendiente",
            "donacion_aprobada",
        ]
        assert all(fila.estado == "enviado" for fila in filas)
        from models import DONACION

        donante = db.session.get(DONACION, donacion["id_donacion"]).donante
        assert {fila.destinatario for fila in filas} == {donante.correo}
        assert "50000" not in filas[0].cuerpo_texto
        assert "$50.000" in filas[0].cuerpo_texto

    assert len(mail_config.mensajes) == 3

    # Reenviar el mismo evento no duplica notificaciones.
    client.post("/api/webhooks/wompi", json=_event(donacion["referencia"]))
    with app.app_context():
        assert NOTIFICACION_EMAIL.query.count() == 3


def test_fallo_de_correo_no_revierte_el_pago(client, wompi_config, mail_config):
    mail_config.fallar = True
    token = _donante_token(client)
    donacion = _checkout(client, token, amount=50000).get_json()

    webhook = client.post(
        "/api/webhooks/wompi", json=_event(donacion["referencia"])
    )

    assert webhook.status_code == 200
    with app.app_context():
        from models import DONACION

        pago = db.session.get(DONACION, donacion["id_donacion"])
        assert pago.estado_pago == "aprobada"
        fallidas = NOTIFICACION_EMAIL.query.filter(
            NOTIFICACION_EMAIL.estado == "fallido",
            NOTIFICACION_EMAIL.tipo.in_(("donacion_pendiente", "donacion_aprobada")),
        ).all()
        assert len(fallidas) == 2


def test_endpoint_de_notificaciones_es_solo_para_soporte(client):
    assert client.get("/api/support/notifications").status_code == 401

    correo = f"don_{uuid.uuid4().hex[:8]}@test.co"
    register_user(client, rol="donante", correo=correo)
    donante_token = get_token(client, correo)
    assert (
        client.get(
            "/api/support/notifications",
            headers={"Authorization": f"Bearer {donante_token}"},
        ).status_code
        == 403
    )

    _notificacion(clave="soporte-1")
    soporte_token = get_support_token(client)
    respuesta = client.get(
        "/api/support/notifications",
        headers={"Authorization": f"Bearer {soporte_token}"},
    )
    assert respuesta.status_code == 200
    cuerpo = respuesta.get_json()
    assert cuerpo["total"] == 2
    assert cuerpo["items"][0]["clave_evento"] == "soporte-1"
    assert "cuerpo_texto" not in cuerpo["items"][0]

    invalido = client.get(
        "/api/support/notifications?estado=otro",
        headers={"Authorization": f"Bearer {soporte_token}"},
    )
    assert invalido.status_code == 400


transferencias_habilitadas = pytest.mark.skipif(
    os.getenv("TRANSFERENCIAS_ENABLED", "0") != "1",
    reason="Requiere TRANSFERENCIAS_ENABLED=1",
)


@transferencias_habilitadas
def test_flujo_de_transferencia_notifica_al_donante(
    client, transfer_context, mail_config
):
    from test_transfers import (
        _approve,
        _claim,
        _create_account,
        _create_transfer,
        _upload,
    )

    cuenta = _create_account(client, transfer_context)
    transferencia = _create_transfer(client, transfer_context, cuenta)
    assert _upload(client, transfer_context, transferencia["id_transferencia"]).status_code == 201
    assert _claim(client, transfer_context, transferencia["id_transferencia"]).status_code == 200
    assert _approve(client, transfer_context, transferencia["id_transferencia"]).status_code == 200

    with app.app_context():
        filas = NOTIFICACION_EMAIL.query.filter(
            NOTIFICACION_EMAIL.tipo.in_(("transferencia_comprobante", "transferencia_aprobada"))
        ).order_by(NOTIFICACION_EMAIL.id_notificacion).all()
        assert [fila.tipo for fila in filas] == [
            "transferencia_comprobante",
            "transferencia_aprobada",
        ]
        assert all(fila.estado == "enviado" for fila in filas)
        assert all(fila.destinatario == "donor_transfer@test.co" for fila in filas)

    assert len(mail_config.mensajes) == 2
