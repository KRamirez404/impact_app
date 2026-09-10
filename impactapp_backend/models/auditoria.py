from datetime import datetime

from . import db


class AUDITORIA(db.Model):
    __tablename__ = "AUDITORIA"

    id_auditoria = db.Column(db.Integer, primary_key=True)
    id_usuario = db.Column(db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=True)
    accion = db.Column(db.String(80), nullable=False)
    descripcion = db.Column(db.Text, nullable=True)
    entidad = db.Column(db.String(50), nullable=True)
    id_entidad = db.Column(db.Integer, nullable=True)
    direccion_ip = db.Column(db.String(45), nullable=True)
    fecha = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    usuario = db.relationship("USUARIO", backref="auditorias")

    def to_dict(self):
        return {
            "id_auditoria": self.id_auditoria,
            "id_usuario": self.id_usuario,
            "accion": self.accion,
            "descripcion": self.descripcion,
            "entidad": self.entidad,
            "id_entidad": self.id_entidad,
            "direccion_ip": self.direccion_ip,
            "fecha": self.fecha.isoformat(),
        }
