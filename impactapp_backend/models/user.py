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
    fecha_registro = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    estado = db.Column(
        db.Enum("activo", "bloqueado", name="usuario_estado", native_enum=False),
        default="activo",
        nullable=False,
    )

    campañas = db.relationship("CAMPAÑA", backref="creador", lazy=True)

    def to_dict(self):
        return {
            "id_usuario": self.id_usuario,
            "nombre": self.nombre,
            "apellido": self.apellido,
            "correo": self.correo,
            "telefono": self.telefono,
            "fecha_registro": self.fecha_registro.isoformat(),
            "estado": self.estado,
        }

