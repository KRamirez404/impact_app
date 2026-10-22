from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy.exc import IntegrityError

from models import USUARIO, db
from services.audit_service import registrar
from services.rate_limit import client_ip, enforce, too_many_requests
from services.auth_service import (
    PRIVACY_POLICY,
    anonymize_user,
    login_user,
    register_user,
    update_user_profile,
)

auth_bp = Blueprint("auth_bp", __name__, url_prefix="/api/auth")


def _json_object():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        raise ValueError("Debe enviar un objeto JSON válido")
    return data


@auth_bp.get("/privacy-policy")
def privacy_policy():
    return jsonify(PRIVACY_POLICY), 200


@auth_bp.post("/register")
def register():
    retry_after = enforce(
        f"register:{client_ip()}",
        "RATE_LIMIT_REGISTER_ATTEMPTS",
        "RATE_LIMIT_REGISTER_WINDOW",
    )
    if retry_after:
        return too_many_requests(retry_after)
    try:
        data = _json_object()
        user = register_user(data)
        registrar(
            id_usuario=user.id_usuario,
            accion="REGISTRO",
            descripcion=f"Nuevo usuario registrado con rol '{user.rol}'",
            entidad="USUARIO",
            id_entidad=user.id_usuario,
            direccion_ip=request.remote_addr,
        )
        return jsonify({"message": "Usuario registrado", "user": user.to_dict()}), 201
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400
    except IntegrityError:
        db.session.rollback()
        return jsonify({"error": "No se pudo registrar el usuario con estos datos"}), 400


@auth_bp.post("/login")
def login():
    try:
        data = _json_object()
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400
    correo = data.get("correo")
    contrasena = data.get("contrasena")
    if not isinstance(correo, str) or not isinstance(contrasena, str) or not correo.strip() or not contrasena:
        return jsonify({"error": "Correo y contraseña son requeridos"}), 400
    if len(correo) > 150 or len(contrasena.encode("utf-8")) > 72:
        return jsonify({"error": "Las credenciales superan la longitud permitida"}), 400

    normalized_email = correo.strip().lower()
    retry_after = enforce(
        f"login:{client_ip()}:{normalized_email}",
        "RATE_LIMIT_LOGIN_ATTEMPTS",
        "RATE_LIMIT_LOGIN_WINDOW",
    )
    if not retry_after:
        retry_after = enforce(
            f"login-ip:{client_ip()}",
            "RATE_LIMIT_LOGIN_IP_ATTEMPTS",
            "RATE_LIMIT_LOGIN_WINDOW",
        )
    if retry_after:
        return too_many_requests(retry_after)

    try:
        token, user = login_user(correo, contrasena)
        registrar(
            id_usuario=user.id_usuario,
            accion="LOGIN",
            descripcion="Inicio de sesión exitoso",
            entidad="USUARIO",
            id_entidad=user.id_usuario,
            direccion_ip=request.remote_addr,
        )
        return jsonify({"access_token": token, "user": user.to_dict()}), 200
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 401


@auth_bp.get("/me")
@jwt_required()
def me():
    user_id = int(get_jwt_identity())
    user = USUARIO.query.get_or_404(user_id)
    return jsonify(user.to_dict()), 200


@auth_bp.put("/me")
@jwt_required()
def update_me():
    user_id = int(get_jwt_identity())
    user = USUARIO.query.get_or_404(user_id)
    try:
        data = _json_object()
        update_user_profile(user, data)
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400
    except IntegrityError:
        db.session.rollback()
        return jsonify({"error": "No se pudo actualizar el perfil con estos datos"}), 400
    return jsonify(user.to_dict()), 200


@auth_bp.delete("/me")
@jwt_required()
def delete_me():
    user_id = int(get_jwt_identity())
    user = USUARIO.query.get_or_404(user_id)

    anonymize_user(user)

    return jsonify({"message": "Tus datos personales fueron suprimidos/anonimizados"}), 200
