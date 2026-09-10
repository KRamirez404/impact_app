import re
from datetime import datetime, timedelta

import bcrypt
from flask_jwt_extended import create_access_token

from models import USUARIO, db

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
    if len(password) < 8:
        return False
    if not re.search(r"[A-Z]", password):
        return False
    if not re.search(r"[0-9]", password):
        return False
    return True


def register_user(data: dict) -> USUARIO:
    nombre = (data.get("nombre") or "").strip()
    apellido = (data.get("apellido") or "").strip()
    correo = (data.get("correo") or "").strip().lower()
    contrasena = data.get("contrasena") or ""

    if not EMAIL_REGEX.match(correo):
        raise ValueError("El correo tiene un formato inválido")
    if not validate_password(contrasena):
        raise ValueError("La contraseña debe tener al menos 8 caracteres, una mayúscula y un número")
    if not data.get("acepta_tratamiento"):
        raise ValueError("Debe aceptar la política de tratamiento de datos personales")

    existing = USUARIO.query.filter_by(correo=correo).first()
    if existing:
        raise ValueError("El correo ya está registrado")

    role = data.get("rol")
    if role not in ALLOWED_CLIENT_ROLES:
        role = "donante"

    user = USUARIO(
        nombre=nombre,
        apellido=apellido,
        correo=correo,
        contraseña_hash=hash_password(contrasena),
        telefono=data.get("telefono"),
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
