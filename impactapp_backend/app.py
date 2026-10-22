import os
from datetime import date, datetime, timedelta
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask, current_app, jsonify, send_from_directory
from flask_cors import CORS
from flask_jwt_extended import JWTManager, get_jwt_identity, jwt_required
from sqlalchemy import inspect, text
from sqlalchemy.exc import SQLAlchemyError

load_dotenv(Path(__file__).resolve().parents[1] / ".env")

from config import Config  # noqa: E402
from models import (
    ARCHIVO,
    CAMPAÑA,
    CATEGORIA,
    CIUDAD,
    PUNTO_RECOLECCION,
    SEGUIMIENTO,
    SOPORTE,
    USUARIO,
    db,
)
from routes import register_blueprints
from services import wompi_service


def seed_database():
    # Normalize legacy campaign state values to avoid enum deserialization errors.
    legacy_state_fix = db.session.execute(
        text('UPDATE "CAMPAÑA" SET estado = :new_state WHERE estado = :old_state'),
        {"new_state": "activa", "old_state": "activo"},
    )
    if legacy_state_fix.rowcount:
        db.session.commit()

    if CIUDAD.query.count() == 0:
        ciudades = [
            ("Bogotá", "Cundinamarca"),
            ("Medellín", "Antioquia"),
            ("Cali", "Valle del Cauca"),
            ("Barranquilla", "Atlántico"),
            ("Cartagena", "Bolívar"),
            ("Montería", "Córdoba"),
            ("Sincelejo", "Sucre"),
            ("Bucaramanga", "Santander"),
            ("Pereira", "Risaralda"),
            ("Manizales", "Caldas"),
        ]
        db.session.add_all(
            [CIUDAD(nombre=nombre, departamento=departamento) for nombre, departamento in ciudades]
        )
        db.session.commit()

    if CATEGORIA.query.count() == 0:
        categorias = [
            ("Desastres Naturales", "Campañas para apoyar comunidades afectadas por emergencias naturales."),
            ("Pobreza Estructural", "Iniciativas para reducir carencias básicas en poblaciones vulnerables."),
            ("Salud", "Apoyos para tratamientos médicos, medicamentos y jornadas de salud."),
            ("Educación", "Recolección de recursos para acceso y permanencia educativa."),
            ("Desplazamiento Forzado", "Acompañamiento humanitario a familias desplazadas por violencia."),
        ]
        db.session.add_all([CATEGORIA(nombre=n, descripcion=d) for n, d in categorias])
        db.session.commit()

    support_user = (
        USUARIO.query.filter_by(rol="soporte", estado="activo")
        .order_by(USUARIO.id_usuario.asc())
        .first()
    )

    if CAMPAÑA.query.count() == 0 and support_user:
        bogota = CIUDAD.query.filter_by(nombre="Bogotá").first()
        salud = CATEGORIA.query.filter_by(nombre="Salud").first()
        campaign = CAMPAÑA(
            titulo="Medicamentos para población vulnerable",
            descripcion="Campaña para comprar medicamentos esenciales para familias en situación crítica.",
            id_ciudad=bogota.id_ciudad,
            id_categoria=salud.id_categoria,
            id_creador=support_user.id_usuario,
            tipo_ayuda_requerida="economica",
            meta_monetaria=5000000,
            fecha_inicio=date.today(),
            fecha_fin=date.today() + timedelta(days=60),
            estado="activa",
            porcentaje_avance=15,
        )
        db.session.add(campaign)
        db.session.commit()

        support = SOPORTE(
            id_campania=campaign.id_campania,
            tipo="documento_oficial",
            url_o_ruta="https://example.org/acta-campania.pdf",
            descripcion="Documento oficial de respaldo",
            validado=True,
        )
        db.session.add(support)

        point = PUNTO_RECOLECCION(
            id_campania=campaign.id_campania,
            id_ciudad=bogota.id_ciudad,
            nombre="Centro Comunitario Chapinero",
            direccion="Cra. 13 #54-20",
            horario="Lunes a Sábado 8:00am - 6:00pm",
            contacto="3015557788",
        )
        db.session.add(point)

        tracking = SEGUIMIENTO(
            id_campania=campaign.id_campania,
            fecha_registro=datetime.utcnow(),
            descripcion="Se inició la compra del primer lote de medicamentos.",
            porcentaje_avance=15,
            evidencia_url="https://example.org/evidencia-inicial.jpg",
        )
        db.session.add(tracking)
        db.session.commit()
    elif CAMPAÑA.query.count() == 0:
        current_app.logger.warning(
            "No hay usuario soporte activo; no se crea la campaña de demostración"
        )


def database_available():
    with db.engine.connect() as connection:
        connection.execute(text("SELECT 1"))


def ensure_user_schema():
    inspector = inspect(db.engine)
    columns = {column["name"] for column in inspector.get_columns("USUARIO")}
    if "id_ciudad" not in columns:
        db.session.execute(
            text('ALTER TABLE "USUARIO" ADD COLUMN id_ciudad INTEGER REFERENCES "CIUDAD" (id_ciudad)')
        )
        db.session.commit()
    if "biografia" not in columns:
        db.session.execute(text('ALTER TABLE "USUARIO" ADD COLUMN biografia TEXT'))
        db.session.commit()
    if "rol" not in columns:
        db.session.execute(text('ALTER TABLE "USUARIO" ADD COLUMN rol TEXT'))
        db.session.execute(text("UPDATE \"USUARIO\" SET rol = 'usuario' WHERE rol IS NULL"))
        db.session.commit()
    if "foto_perfil" not in columns:
        db.session.execute(text('ALTER TABLE "USUARIO" ADD COLUMN foto_perfil TEXT'))
        db.session.commit()
    if "acepta_tratamiento" not in columns:
        db.session.execute(
            text('ALTER TABLE "USUARIO" ADD COLUMN acepta_tratamiento BOOLEAN NOT NULL DEFAULT false')
        )
        db.session.commit()
    if "fecha_aceptacion" not in columns:
        db.session.execute(text('ALTER TABLE "USUARIO" ADD COLUMN fecha_aceptacion TIMESTAMP'))
        db.session.commit()
    if "token_version" not in columns:
        db.session.execute(
            text('ALTER TABLE "USUARIO" ADD COLUMN token_version INTEGER NOT NULL DEFAULT 0')
        )
        db.session.commit()


def ensure_campaign_schema():
    inspector = inspect(db.engine)
    columns = {column["name"] for column in inspector.get_columns("CAMPAÑA")}
    if "nota_revision" not in columns:
        db.session.execute(text('ALTER TABLE "CAMPAÑA" ADD COLUMN nota_revision TEXT'))
    if "fecha_revision" not in columns:
        db.session.execute(text('ALTER TABLE "CAMPAÑA" ADD COLUMN fecha_revision TIMESTAMP'))
    if "id_auditor" not in columns:
        db.session.execute(text('ALTER TABLE "CAMPAÑA" ADD COLUMN id_auditor INTEGER'))
    if "cuenta_recaudo" not in columns:
        db.session.execute(text('ALTER TABLE "CAMPAÑA" ADD COLUMN cuenta_recaudo VARCHAR(100)'))
    if "eliminada" not in columns:
        db.session.execute(
            text('ALTER TABLE "CAMPAÑA" ADD COLUMN eliminada BOOLEAN NOT NULL DEFAULT false')
        )
    if "motivo_eliminacion" not in columns:
        db.session.execute(text('ALTER TABLE "CAMPAÑA" ADD COLUMN motivo_eliminacion TEXT'))
    if "fecha_eliminacion" not in columns:
        db.session.execute(text('ALTER TABLE "CAMPAÑA" ADD COLUMN fecha_eliminacion TIMESTAMP'))
    if "id_eliminador" not in columns:
        db.session.execute(text('ALTER TABLE "CAMPAÑA" ADD COLUMN id_eliminador INTEGER'))
    db.session.commit()


def ensure_donation_schema():
    inspector = inspect(db.engine)
    columns = {column["name"] for column in inspector.get_columns("DONACION")}
    if "checksum" not in columns:
        db.session.execute(text('ALTER TABLE "DONACION" ADD COLUMN checksum VARCHAR(64)'))
    if "estado_pago" not in columns:
        db.session.execute(
            text(
                'ALTER TABLE "DONACION" ADD COLUMN estado_pago VARCHAR(20) '
                "NOT NULL DEFAULT 'pendiente'"
            )
        )
        db.session.execute(
            text('UPDATE "DONACION" SET estado_pago = :estado'),
            {"estado": "aprobada"},
        )
    if "referencia_pago" not in columns:
        db.session.execute(
            text('ALTER TABLE "DONACION" ADD COLUMN referencia_pago VARCHAR(255)')
        )
        db.session.execute(
            text(
                'CREATE UNIQUE INDEX IF NOT EXISTS uq_donacion_referencia_pago '
                'ON "DONACION" (referencia_pago)'
            )
        )
    if "wompi_transaction_id" not in columns:
        db.session.execute(
            text('ALTER TABLE "DONACION" ADD COLUMN wompi_transaction_id VARCHAR(120)')
        )
    if "metodo_pago" not in columns:
        db.session.execute(
            text('ALTER TABLE "DONACION" ADD COLUMN metodo_pago VARCHAR(40)')
        )
    if "fecha_pago" not in columns:
        db.session.execute(text('ALTER TABLE "DONACION" ADD COLUMN fecha_pago TIMESTAMP'))
    if "clave_checkout" not in columns:
        db.session.execute(text('ALTER TABLE "DONACION" ADD COLUMN clave_checkout VARCHAR(64)'))
    for column in ("wompi_transaction_id", "clave_checkout"):
        duplicate = db.session.execute(text(
            f'SELECT 1 FROM "DONACION" WHERE {column} IS NOT NULL '
            f'GROUP BY {column} HAVING COUNT(*) > 1 LIMIT 1'
        )).first()
        if duplicate:
            db.session.rollback()
            raise RuntimeError(
                f"No se puede asegurar DONACION: valores duplicados en {column}. "
                "Requiere conciliación manual; no se han eliminado datos."
            )
        db.session.execute(text(
            f'CREATE UNIQUE INDEX IF NOT EXISTS uq_donacion_{column} '
            f'ON "DONACION" ({column})'
        ))
    db.session.commit()


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    jwt = JWTManager(app)

    @jwt.token_in_blocklist_loader
    def token_is_revoked(jwt_header, jwt_payload):
        try:
            user_id = int(jwt_payload.get("sub"))
        except (TypeError, ValueError):
            return True
        user = db.session.get(USUARIO, user_id)
        if user is None:
            return False
        token_version = jwt_payload.get("token_version", 0)
        if type(token_version) is not int:
            return True
        return token_version != int(user.token_version or 0)

    allowed_origins = [
        r"https?://localhost:\d+",
        r"https?://127\.0\.0\.1:\d+",
        r"http://10\.0\.2\.2:5000",
    ]
    allowed_origins.extend(app.config.get("ALLOWED_ORIGINS", []))
    CORS(app, resources={r"/api/*": {"origins": allowed_origins}})

    upload_abs_path = os.path.join(app.root_path, app.config["UPLOAD_FOLDER"])
    os.makedirs(upload_abs_path, exist_ok=True)
    os.makedirs(os.path.join(app.root_path, "data"), exist_ok=True)

    register_blueprints(app)

    @app.get("/api/health")
    def health():
        try:
            database_available()
        except SQLAlchemyError:
            current_app.logger.warning("Health: PostgreSQL no disponible")
            return (
                jsonify(
                    {
                        "status": "error",
                        "service": "ImpactApp Backend",
                        "database": "unavailable",
                    }
                ),
                503,
            )
        return (
            jsonify(
                {
                    "status": "ok",
                    "service": "ImpactApp Backend",
                    "database": "ok",
                }
            ),
            200,
        )

    def _archive_is_owned_by(file_path, user_id):
        archive = ARCHIVO.query.filter_by(ruta=file_path).first()
        return archive is None or archive.id_usuario == user_id

    def _public_upload(file_path):
        private_reference = SOPORTE.query.filter(
            SOPORTE.url_o_ruta == file_path,
            ~SOPORTE.tipo.in_(("foto", "imagen")),
        ).first()
        if private_reference:
            return False
        profile_user = USUARIO.query.filter_by(foto_perfil=file_path).first()
        if profile_user and _archive_is_owned_by(file_path, profile_user.id_usuario):
            return True
        for tracking in SEGUIMIENTO.query.filter_by(evidencia_url=file_path).all():
            if (
                tracking.campania
                and _archive_is_owned_by(
                    file_path, tracking.campania.id_creador
                )
            ):
                return True
        for support in SOPORTE.query.filter_by(url_o_ruta=file_path).all():
            if support.tipo not in ("foto", "imagen"):
                continue
            if (
                support.campania
                and _archive_is_owned_by(
                    file_path, support.campania.id_creador
                )
            ):
                return True
        return False

    def _can_access_private_upload(user, file_path):
        if user.rol == "soporte":
            return True
        upload = ARCHIVO.query.filter_by(
            ruta=file_path, id_usuario=user.id_usuario
        ).first()
        if upload:
            return True
        supports = SOPORTE.query.filter_by(url_o_ruta=file_path).all()
        return any(
            support.campania
            and support.campania.id_creador == user.id_usuario
            for support in supports
        )

    @app.get("/uploads/<path:filename>")
    @jwt_required(optional=True)
    def uploaded_file(filename):
        if (
            not filename
            or "/" in filename
            or "\\" in filename
            or filename.startswith(".")
        ):
            return jsonify({"error": "Archivo no encontrado"}), 404
        file_path = f"/uploads/{filename}"
        current_upload_path = os.path.join(
            current_app.root_path, current_app.config["UPLOAD_FOLDER"]
        )
        if _public_upload(file_path):
            response = send_from_directory(current_upload_path, filename)
            response.headers["X-Content-Type-Options"] = "nosniff"
            response.headers["Cache-Control"] = "public, max-age=3600"
            return response
        identity = get_jwt_identity()
        if identity is None:
            return jsonify({"error": "Autenticación requerida"}), 401
        user = USUARIO.query.get(int(identity))
        if (
            user is None
            or user.estado != "activo"
            or not _can_access_private_upload(user, file_path)
        ):
            return jsonify({"error": "Archivo no encontrado"}), 404
        response = send_from_directory(current_upload_path, filename)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Cache-Control"] = "private, no-store"
        return response

    with app.app_context():
        db.create_all()
        ensure_user_schema()
        ensure_campaign_schema()
        ensure_donation_schema()
        seed_database()
        wompi_status = wompi_service.configuration_status()
        if wompi_status["ok"]:
            app.logger.info("Wompi: ambiente %s configurado", wompi_status["environment"])
        else:
            app.logger.warning(
                "Wompi: configuración incompleta o inválida (faltan=%s, problemas=%s)",
                ",".join(wompi_status["missing"]) or "ninguna",
                ",".join(wompi_status["issues"]) or "ninguno",
            )

    return app


app = create_app()


if __name__ == "__main__":
    debug = os.getenv("FLASK_DEBUG", "0") == "1"
    app.run(host="0.0.0.0", port=5000, debug=debug)
