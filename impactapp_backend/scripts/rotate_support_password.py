#!/usr/bin/env python3
import getpass
import os
import sys
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from config import Config  # noqa: E402
from services.auth_service import validate_password  # noqa: E402
from services.support_password_service import (  # noqa: E402
    RotationError,
    active_support_user,
    rotate_support_password,
)


def tty_available():
    return sys.stdin.isatty() and sys.stdout.isatty()


def main():
    if not tty_available():
        print("Se requiere una terminal interactiva (TTY). Usa docker exec -it.")
        return 1
    if not os.getenv("DATABASE_URL"):
        print("DATABASE_URL no está configurada; no se puede rotar la contraseña.")
        return 1
    email = input("Correo del usuario soporte: ").strip().lower()
    if not email:
        print("El correo es obligatorio")
        return 1
    engine = create_engine(Config.SQLALCHEMY_DATABASE_URI, pool_pre_ping=True)
    try:
        with Session(engine) as session:
            try:
                user = active_support_user(session, email)
            except RotationError as exc:
                print(str(exc))
                return 1
            except Exception:
                print("No fue posible consultar la cuenta soporte.")
                return 1
            try:
                password = getpass.getpass("Nueva contraseña: ")
                if not validate_password(password):
                    print(
                        "La contraseña debe tener al menos 8 caracteres, una mayúscula, "
                        "un número y no superar 72 bytes"
                    )
                    return 1
                confirmation = getpass.getpass("Confirma la nueva contraseña: ")
            except (KeyboardInterrupt, EOFError):
                print("\nRotación cancelada")
                return 1
            if password != confirmation:
                print("Las contraseñas no coinciden")
                return 1
            try:
                rotate_support_password(session, user, password)
            except RotationError as exc:
                print(str(exc))
                return 1
            except Exception:
                print("No fue posible completar la rotación; no se guardó ningún cambio.")
                return 1
    finally:
        engine.dispose()
    print("Contraseña actualizada. No se mostró ni almacenó en texto plano.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
