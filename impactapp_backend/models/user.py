from datetime import datetime

from . import db


class USUARIO(db.Model):
    __tablename__ = "USUARIO"

    id_usuario = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    apellido = db.Column(db.String(100), nullable=False)
    correo = db.Column(db.String(150), unique=True, nullable=False)
    contraseña_hash = db.Column(db.String(255), nullable=False)
    telefono = db.Column(db.String(30), nullable=True)
    id_ciudad = db.Column(db.Integer, db.ForeignKey("CIUDAD.id_ciudad"), nullable=True)
    ciudad = db.relationship("CIUDAD")
    biografia = db.Column(db.String(500), nullable=True)
    instagram_url = db.Column(db.String(255), nullable=True)
    facebook_url = db.Column(db.String(255), nullable=True)
    tiktok_url = db.Column(db.String(255), nullable=True)
    redes_sociales = db.Column(db.JSON, nullable=True, default=dict)
    rol = db.Column(
        db.Enum(
            "donante",
            "organizador",
            "soporte",
            name="usuario_rol",
            native_enum=False,
        ),
        default="donante",
        nullable=False,
    )
    foto_perfil = db.Column(db.String(255), nullable=True)
    mostrar_foto_top = db.Column(
        db.Boolean, default=True, server_default="true", nullable=False
    )
    fecha_registro = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    acepta_tratamiento = db.Column(db.Boolean, default=False, nullable=False)
    fecha_aceptacion = db.Column(db.DateTime, nullable=True)
    estado = db.Column(
        db.Enum("activo", "bloqueado", name="usuario_estado", native_enum=False),
        default="activo",
        nullable=False,
    )
    token_version = db.Column(
        db.Integer, default=0, server_default="0", nullable=False
    )

    campañas = db.relationship(
        "CAMPAÑA",
        backref="creador",
        lazy=True,
        foreign_keys="CAMPAÑA.id_creador",
    )

    def to_dict(self):
        socials = dict(self.redes_sociales or {})
        if self.instagram_url and "instagram" not in socials:
            socials["instagram"] = self.instagram_url
        if self.facebook_url and "facebook" not in socials:
            socials["facebook"] = self.facebook_url
        if self.tiktok_url and "tiktok" not in socials:
            socials["tiktok"] = self.tiktok_url
        return {
            "id_usuario": self.id_usuario,
            "nombre": self.nombre,
            "apellido": self.apellido,
            "correo": self.correo,
            "telefono": self.telefono,
            "id_ciudad": self.id_ciudad,
            "ciudad": self.ciudad.to_dict() if self.ciudad else None,
            "biografia": self.biografia,
            "foto_perfil": self.foto_perfil,
            "instagram_url": self.instagram_url,
            "facebook_url": self.facebook_url,
            "tiktok_url": self.tiktok_url,
            "redes_sociales": socials,
            "mostrar_foto_top": self.mostrar_foto_top,
            "rol": self.rol,
            "fecha_registro": self.fecha_registro.isoformat(),
            "estado": self.estado,
        }

    def to_public_dict(self):
        socials = dict(self.redes_sociales or {})
        if self.instagram_url and "instagram" not in socials:
            socials["instagram"] = self.instagram_url
        if self.facebook_url and "facebook" not in socials:
            socials["facebook"] = self.facebook_url
        if self.tiktok_url and "tiktok" not in socials:
            socials["tiktok"] = self.tiktok_url
        return {
            "id_usuario": self.id_usuario,
            "nombre": self.nombre,
            "apellido": self.apellido,
            "foto_perfil": self.foto_perfil,
            "instagram_url": self.instagram_url,
            "facebook_url": self.facebook_url,
            "tiktok_url": self.tiktok_url,
            "redes_sociales": socials,
        }
