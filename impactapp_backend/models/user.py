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
    biografia = db.Column(db.String(500), nullable=True)
    rol = db.Column(
        db.Enum("usuario", "soporte", name="usuario_rol", native_enum=False),
        default="usuario",
        nullable=False,
    )
    fecha_registro = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    estado = db.Column(
        db.Enum("activo", "bloqueado", name="usuario_estado", native_enum=False),
        default="activo",
        nullable=False,
    )

    campañas = db.relationship(
        "CAMPAÑA",
        backref="creador",
        lazy=True,
        foreign_keys="CAMPAÑA.id_creador",
    )

    def to_dict(self):
        return {
            "id_usuario": self.id_usuario,
            "nombre": self.nombre,
            "apellido": self.apellido,
            "correo": self.correo,
            "telefono": self.telefono,
            "biografia": self.biografia,
            "rol": self.rol,
            "fecha_registro": self.fecha_registro.isoformat(),
            "estado": self.estado,
        }
