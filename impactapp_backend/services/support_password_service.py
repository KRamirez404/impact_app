from sqlalchemy import select

from models import AUDITORIA, USUARIO
from services.auth_service import hash_password, validate_password


class RotationError(ValueError):
    pass


def active_support_user(session, email: str) -> USUARIO:
    normalized = (email or "").strip().lower()
    if not normalized:
        raise RotationError("El correo es obligatorio")
    users = (
        session.execute(
            select(USUARIO).where(
                USUARIO.correo == normalized,
                USUARIO.rol == "soporte",
                USUARIO.estado == "activo",
            )
        )
        .scalars()
        .all()
    )
    if len(users) != 1:
        raise RotationError(
            "No existe una única cuenta soporte activa con ese correo"
        )
    return users[0]


def rotate_support_password(session, user: USUARIO, new_password: str) -> USUARIO:
    if user.rol != "soporte" or user.estado != "activo":
        raise RotationError("La cuenta no es un usuario soporte activo")
    if not validate_password(new_password):
        raise RotationError(
            "La contraseña debe tener al menos 8 caracteres, una mayúscula, "
            "un número y no superar 72 bytes"
        )
    user.contraseña_hash = hash_password(new_password)
    user.token_version = int(user.token_version or 0) + 1
    session.add(
        AUDITORIA(
            id_usuario=user.id_usuario,
            accion="ROTACION_CONTRASENA_SOPORTE",
            descripcion="Rotación de contraseña de soporte desde script local",
            entidad="USUARIO",
            id_entidad=user.id_usuario,
            direccion_ip=None,
        )
    )
    try:
        session.commit()
    except Exception:
        session.rollback()
        raise
    return user
