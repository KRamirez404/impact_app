from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import USUARIO, db
from services.audit_service import registrar
from services.auth_service import (
    PRIVACY_POLICY,
    anonymize_user,
    login_user,
    register_user,
)

auth_bp = Blueprint("auth_bp", __name__, url_prefix="/api/auth")


@auth_bp.get("/privacy-policy")
def privacy_policy():
    return jsonify(PRIVACY_POLICY), 200


@auth_bp.post("/register")
def register():
    data = request.get_json() or {}
    required = ["nombre", "apellido", "correo", "contrasena"]
    missing = [field for field in required if not data.get(field)]
    if missing:
        return jsonify({"error": f"Campos faltantes: {', '.join(missing)}"}), 400

    try:
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


@auth_bp.post("/login")
def login():
    data = request.get_json() or {}
    correo = data.get("correo")
    contrasena = data.get("contrasena")
    if not correo or not contrasena:
        return jsonify({"error": "Correo y contraseña son requeridos"}), 400

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
    data = request.get_json() or {}

    if "nombre" in data:
        nombre = (data.get("nombre") or "").strip()
        if not nombre:
            return jsonify({"error": "Nombre es requerido"}), 400
        user.nombre = nombre

    if "apellido" in data:
        user.apellido = (data.get("apellido") or "").strip()

    if "correo" in data:
        correo = (data.get("correo") or "").strip().lower()
        if not correo:
            return jsonify({"error": "Correo es requerido"}), 400
        if correo != user.correo and USUARIO.query.filter_by(correo=correo).first():
            return jsonify({"error": "El correo ya está registrado"}), 400
        user.correo = correo

    if "telefono" in data:
        telefono = data.get("telefono")
        if isinstance(telefono, str):
            telefono = telefono.strip() or None
        user.telefono = telefono

    if "biografia" in data:
        biografia = data.get("biografia")
        if isinstance(biografia, str):
            biografia = biografia.strip()
            if len(biografia) > 500:
                return jsonify({"error": "La biografía no puede superar 500 caracteres"}), 400
            biografia = biografia or None
        user.biografia = biografia

    if "foto_perfil" in data:
        foto_perfil = data.get("foto_perfil")
        if isinstance(foto_perfil, str):
            foto_perfil = foto_perfil.strip() or None
        user.foto_perfil = foto_perfil

    db.session.commit()
    return jsonify(user.to_dict()), 200


@auth_bp.delete("/me")
@jwt_required()
def delete_me():
    user_id = int(get_jwt_identity())
    user = USUARIO.query.get_or_404(user_id)

    anonymize_user(user)

    return jsonify({"message": "Tus datos personales fueron suprimidos/anonimizados"}), 200
