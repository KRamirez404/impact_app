from datetime import datetime

from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required
from sqlalchemy import and_, or_

from models import NOTIFICACION_EMAIL, db
from services.authorization import current_user

notification_bp = Blueprint(
    "notification_bp", __name__, url_prefix="/api/notifications"
)


def _notificaciones_del_usuario(usuario):
    return NOTIFICACION_EMAIL.query.filter(
        or_(
            NOTIFICACION_EMAIL.id_usuario == usuario.id_usuario,
            and_(
                NOTIFICACION_EMAIL.id_usuario.is_(None),
                NOTIFICACION_EMAIL.destinatario == usuario.correo,
            ),
        )
    )


@notification_bp.get("")
@jwt_required()
def listar_notificaciones():
    usuario = current_user()
    if usuario is None:
        return jsonify({"error": "Usuario no encontrado"}), 404

    try:
        limit = int(request.args.get("limit", 50))
        offset = int(request.args.get("offset", 0))
    except (TypeError, ValueError):
        return jsonify({"error": "limit y offset deben ser enteros"}), 400
    if limit < 1 or offset < 0:
        return jsonify({"error": "limit y offset fuera de rango"}), 400
    limit = min(limit, 100)

    query = _notificaciones_del_usuario(usuario)
    total = query.count()
    no_leidas = query.filter(NOTIFICACION_EMAIL.leida_en.is_(None)).count()
    items = (
        query.order_by(NOTIFICACION_EMAIL.creado_en.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return (
        jsonify(
            {
                "total": total,
                "no_leidas": no_leidas,
                "items": [item.to_user_dict() for item in items],
            }
        ),
        200,
    )


@notification_bp.post("/<int:id_notificacion>/read")
@jwt_required()
def marcar_leida(id_notificacion: int):
    usuario = current_user()
    if usuario is None:
        return jsonify({"error": "Usuario no encontrado"}), 404

    notificacion = _notificaciones_del_usuario(usuario).filter_by(
        id_notificacion=id_notificacion
    ).first()
    if notificacion is None:
        return jsonify({"error": "Notificación no encontrada"}), 404
    if notificacion.leida_en is None:
        notificacion.leida_en = datetime.utcnow()
        db.session.commit()
    return jsonify(notificacion.to_user_dict()), 200


@notification_bp.post("/read-all")
@jwt_required()
def marcar_todas_leidas():
    usuario = current_user()
    if usuario is None:
        return jsonify({"error": "Usuario no encontrado"}), 404

    marcadas = _notificaciones_del_usuario(usuario).filter(
        NOTIFICACION_EMAIL.leida_en.is_(None)
    ).update(
        {NOTIFICACION_EMAIL.leida_en: datetime.utcnow()},
        synchronize_session=False,
    )
    db.session.commit()
    return jsonify({"marcadas": marcadas}), 200
