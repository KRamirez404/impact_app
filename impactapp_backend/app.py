import os
from datetime import date, datetime, timedelta

from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from sqlalchemy import inspect, text

from config import Config
from models import (
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
from services.auth_service import hash_password


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

    admin = USUARIO.query.filter_by(correo="admin@impactapp.co").first()
    if not admin:
        admin = USUARIO(
            nombre="Admin",
            apellido="ImpactApp",
            correo="admin@impactapp.co",
            contraseña_hash=hash_password("Admin123*"),
            telefono="3000000000",
            estado="activo",
            rol="soporte",
        )
        db.session.add(admin)
        db.session.commit()
    else:
        admin.rol = "soporte"
        db.session.commit()

    if CAMPAÑA.query.count() == 0:
        bogota = CIUDAD.query.filter_by(nombre="Bogotá").first()
        salud = CATEGORIA.query.filter_by(nombre="Salud").first()
        campaign = CAMPAÑA(
            titulo="Medicamentos para población vulnerable",
            descripcion="Campaña para comprar medicamentos esenciales para familias en situación crítica.",
            id_ciudad=bogota.id_ciudad,
            id_categoria=salud.id_categoria,
            id_creador=admin.id_usuario,
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


def ensure_user_schema():
    inspector = inspect(db.engine)
    columns = {column["name"] for column in inspector.get_columns("USUARIO")}
    if "biografia" not in columns:
        db.session.execute(text('ALTER TABLE "USUARIO" ADD COLUMN biografia TEXT'))
        db.session.commit()
    if "rol" not in columns:
        db.session.execute(text('ALTER TABLE "USUARIO" ADD COLUMN rol TEXT'))
        db.session.execute(text('UPDATE "USUARIO" SET rol = "usuario" WHERE rol IS NULL'))
        db.session.commit()
    if "foto_perfil" not in columns:
        db.session.execute(text('ALTER TABLE "USUARIO" ADD COLUMN foto_perfil TEXT'))
        db.session.commit()


def ensure_campaign_schema():
    inspector = inspect(db.engine)
    columns = {column["name"] for column in inspector.get_columns("CAMPAÑA")}
    if "nota_revision" not in columns:
        db.session.execute(text('ALTER TABLE "CAMPAÑA" ADD COLUMN nota_revision TEXT'))
    if "fecha_revision" not in columns:
        db.session.execute(text('ALTER TABLE "CAMPAÑA" ADD COLUMN fecha_revision DATETIME'))
    if "id_auditor" not in columns:
        db.session.execute(text('ALTER TABLE "CAMPAÑA" ADD COLUMN id_auditor INTEGER'))
    db.session.commit()


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    JWTManager(app)
    CORS(app, origins=["http://localhost:8080", "http://localhost:3000"])

    upload_abs_path = os.path.join(app.root_path, app.config["UPLOAD_FOLDER"])
    os.makedirs(upload_abs_path, exist_ok=True)
    os.makedirs(os.path.join(app.root_path, "data"), exist_ok=True)

    register_blueprints(app)

    @app.get("/api/health")
    def health():
        return jsonify({"status": "ok", "service": "ImpactApp Backend"}), 200

    @app.get("/uploads/<path:filename>")
    def uploaded_file(filename):
        return send_from_directory(upload_abs_path, filename)

    with app.app_context():
        db.create_all()
        ensure_user_schema()
        ensure_campaign_schema()
        seed_database()

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
