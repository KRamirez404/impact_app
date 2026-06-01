from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import USUARIO, db
from services.auth_service import login_user, register_user

auth_bp = Blueprint("auth_bp", __name__, url_prefix="/api/auth")


@auth_bp.post("/register")
def register():
    data = request.get_json() or {}
    required = ["nombre", "apellido", "correo", "contrasena"]
    missing = [field for field in required if not data.get(field)]
    if missing:
        return jsonify({"error": f"Campos faltantes: {', '.join(missing)}"}), 400

    try:
        user = register_user(data)
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

    db.session.commit()
    return jsonify(user.to_dict()), 200
