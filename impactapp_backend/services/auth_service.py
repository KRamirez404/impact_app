import re
from datetime import datetime, timedelta

import bcrypt
from flask_jwt_extended import create_access_token

from models import CIUDAD, USUARIO, db

EMAIL_REGEX = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
ALLOWED_CLIENT_ROLES = {"donante", "organizador"}

PRIVACY_POLICY = {
    "titulo": "Política de Tratamiento de Datos Personales",
    "norma": "Ley 1581 de 2012 y Decreto 1377 de 2013",
    "responsable": "ImpactApp",
    "finalidades": [
        "Gestionar el registro, autenticación y operación de la cuenta del usuario.",
        "Permitir la creación, administración y participación en campañas solidarias.",
        "Facilitar el registro de donaciones y el seguimiento de los recursos aportados.",
        "Enviar notificaciones relacionadas con el estado de las campañas apoyadas o creadas.",
    ],
    "derechos": [
        "Conocer, actualizar y rectificar los datos personales suministrados.",
        "Solicitar prueba de la autorización otorgada para el tratamiento.",
        "Solicitar la supresión de los datos cuando no sean necesarios para la finalidad.",
        "Revocar la autorización y/o solicitar la eliminación de los datos.",
    ],
    "canal": "A través de la opción 'Eliminar mi cuenta' en la aplicación o escribiendo al correo de soporte de ImpactApp.",
    "vigencia": "Los datos se conservarán mientras se mantenga la relación con la plataforma y, después, por el término legal aplicable.",
}


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))


def validate_password(password: str) -> bool:
    if not isinstance(password, str) or len(password) < 8:
        return False
    if len(password.encode("utf-8")) > 72:
        return False
    if not re.search(r"[A-Z]", password):
        return False
    if not re.search(r"[0-9]", password):
        return False
    return True


def validate_text(value, label: str, max_length: int, *, required=False):
    if value is None and not required:
        return None
    if not isinstance(value, str):
        raise ValueError(f"{label} debe ser texto")
    value = value.strip()
    if not value:
        if required:
            raise ValueError(f"{label} es requerido")
        return None
    if len(value) > max_length:
        raise ValueError(f"{label} no puede superar {max_length} caracteres")
    return value


def validate_email(value) -> str:
    correo = validate_text(value, "Correo", 150, required=True).lower()
    if not EMAIL_REGEX.fullmatch(correo):
        raise ValueError("El correo tiene un formato inválido")
    return correo


def validate_city_id(value):
    if value is None:
        return None
    if type(value) is int:
        city_id = value
    elif isinstance(value, str) and value.strip().isdigit() and len(value.strip()) <= 10:
        city_id = int(value.strip())
    else:
        raise ValueError("id_ciudad debe ser un número entero")
    if not 0 < city_id <= 2147483647 or db.session.get(CIUDAD, city_id) is None:
        raise ValueError("La ciudad seleccionada no existe")
    return city_id


def update_user_profile(user: USUARIO, data: dict) -> USUARIO:
    fields = {}
    for field, label, length, required in (
        ("nombre", "Nombre", 100, True),
        ("apellido", "Apellido", 100, True),
        ("telefono", "Teléfono", 30, False),
        ("biografia", "Biografía", 500, False),
        ("foto_perfil", "Foto de perfil", 255, False),
    ):
        if field in data:
            fields[field] = validate_text(data[field], label, length, required=required)
    if "correo" in data:
        correo = validate_email(data["correo"])
        if correo != user.correo and USUARIO.query.filter_by(correo=correo).first():
            raise ValueError("El correo ya está registrado")
        fields["correo"] = correo
    if "id_ciudad" in data:
        fields["id_ciudad"] = validate_city_id(data["id_ciudad"])
    for field, value in fields.items():
        setattr(user, field, value)
    db.session.commit()
    return user


def register_user(data: dict) -> USUARIO:
    nombre = validate_text(data.get("nombre"), "Nombre", 100, required=True)
    apellido = validate_text(data.get("apellido"), "Apellido", 100, required=True)
    correo = validate_email(data.get("correo"))
    contrasena = data.get("contrasena")
    if not validate_password(contrasena):
        raise ValueError("La contraseña debe tener al menos 8 caracteres, una mayúscula y un número, y no superar 72 bytes")
    if data.get("acepta_tratamiento") is not True:
        raise ValueError("Debe aceptar la política de tratamiento de datos personales")
    telefono = validate_text(data.get("telefono"), "Teléfono", 30)
    id_ciudad = validate_city_id(data.get("id_ciudad"))

    existing = USUARIO.query.filter_by(correo=correo).first()
    if existing:
        raise ValueError("El correo ya está registrado")

    role = data.get("rol")
    if not isinstance(role, str) or role not in ALLOWED_CLIENT_ROLES:
        role = "donante"

    user = USUARIO(
        nombre=nombre,
        apellido=apellido,
        correo=correo,
        contraseña_hash=hash_password(contrasena),
        telefono=telefono,
        id_ciudad=id_ciudad,
        estado="activo",
        rol=role,
        acepta_tratamiento=bool(data.get("acepta_tratamiento")),
        fecha_aceptacion=datetime.utcnow(),
    )
    db.session.add(user)
    db.session.commit()
    return user


def anonymize_user(user: USUARIO) -> USUARIO:
    user.nombre = "Usuario"
    user.apellido = "Eliminado"
    user.correo = f"eliminado_{user.id_usuario}@impactapp.co"
    user.telefono = None
    user.id_ciudad = None
    user.biografia = None
    user.foto_perfil = None
    user.estado = "bloqueado"
    db.session.commit()
    return user


def login_user(correo: str, contrasena: str):
    user = USUARIO.query.filter_by(correo=correo.strip().lower()).first()
    if not user or not verify_password(contrasena, user.contraseña_hash):
        raise ValueError("Credenciales inválidas")
    if user.estado != "activo":
        raise ValueError("Usuario bloqueado")

    token = create_access_token(
        identity=str(user.id_usuario),
        expires_delta=timedelta(hours=24),
    )
    return token, user
