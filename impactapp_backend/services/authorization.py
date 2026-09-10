from functools import wraps

from flask import jsonify
from flask_jwt_extended import get_jwt_identity

from models import USUARIO


def require_role(*allowed_roles: str):
    allowed = set(allowed_roles)

    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            user_id = int(get_jwt_identity())
            user = USUARIO.query.get(user_id)
            if user is None:
                return jsonify({"error": "Usuario no encontrado"}), 404
            if user.rol not in allowed:
                roles_str = ", ".join(sorted(allowed))
                return jsonify({"error": f"Requiere rol: {roles_str}"}), 403
            return fn(*args, **kwargs)

        return wrapper

    return decorator