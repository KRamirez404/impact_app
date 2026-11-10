from datetime import date
import uuid
from conftest import get_token, register_user
from models import CAMPAÑA, PUNTO_RECOLECCION, db


def _new_email(prefix):
    return f"{prefix}_{uuid.uuid4().hex[:8]}@test.co"


def test_donacion_en_especie_con_punto_y_monto(client):
    correo_donante = _new_email("don_rf10")
    register_user(client, rol="donante", correo=correo_donante)
    token_donante = get_token(client, correo_donante)

    correo_org = _new_email("org_rf10")
    register_user(client, rol="organizador", correo=correo_org)
    token_org = get_token(client, correo_org)
    from models import USUARIO
    org = USUARIO.query.filter_by(correo=correo_org).first()

    # Crear campaña activa directamente en DB
    camp = CAMPAÑA(
        titulo="Campaña Donación Especie",
        descripcion="Recolección de víveres",
        id_ciudad=1,
        id_categoria=1,
        id_creador=org.id_usuario,
        tipo_ayuda_requerida="alimentos",
        meta_monetaria=0,
        fecha_fin=date(2030, 12, 31),
        estado="activa",
    )
    db.session.add(camp)
    db.session.commit()

    # Crear punto de recolección
    punto = PUNTO_RECOLECCION(
        id_campania=camp.id_campania,
        nombre="Sede Central de Acopio",
        direccion="Calle 10 # 20-30",
        id_ciudad=1,
        horario="8am a 5pm",
        contacto="3001234567",
    )
    db.session.add(punto)
    db.session.commit()

    # Donante registra donación en especie con monto estimado y punto
    payload = {
        "id_campania": camp.id_campania,
        "id_punto": punto.id_punto,
        "tipo": "alimentos",
        "monto_estimado": 45000.0,
        "descripcion": "Caja con 10kg de arroz y granos",
    }
    resp = client.post(
        "/api/donations",
        json=payload,
        headers={"Authorization": f"Bearer {token_donante}"},
    )
    assert resp.status_code == 201
    data = resp.get_json()
    assert data["id_punto"] == punto.id_punto
    assert data["tipo"] == "alimentos"
    assert data["monto_estimado"] == 45000.0
    assert data["descripcion"] == "Caja con 10kg de arroz y granos"
    assert data["estado_pago"] == "aprobada"
    assert data["checksum"] is not None
