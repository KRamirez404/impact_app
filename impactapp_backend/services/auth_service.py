from datetime import timedelta

import bcrypt
from flask_jwt_extended import create_access_token

from models import USUARIO, db


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))


def register_user(data: dict) -> USUARIO:
    existing = USUARIO.query.filter_by(correo=data["correo"]).first()
    if existing:
        raise ValueError("El correo ya está registrado")

    user = USUARIO(
        nombre=data["nombre"].strip(),
        apellido=data["apellido"].strip(),
        correo=data["correo"].strip().lower(),
        contraseña_hash=hash_password(data["contrasena"]),
        telefono=data.get("telefono"),
        estado="activo",
    )
    db.session.add(user)
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

