from datetime import datetime

from . import db


class VALORACION(db.Model):
    __tablename__ = "VALORACION"

    id_valoracion = db.Column(db.Integer, primary_key=True)
    id_campania = db.Column(
        db.Integer, db.ForeignKey("CAMPAÑA.id_campania"), nullable=False
    )
    id_usuario = db.Column(db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=False)
    calificacion = db.Column(db.Integer, nullable=False)
    comentario = db.Column(db.Text, nullable=True)
    fecha_valoracion = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    visible = db.Column(db.Boolean, default=True, nullable=False)

    usuario = db.relationship("USUARIO", backref="valoraciones")

    def to_dict(self):
        data = {
            "id_valoracion": self.id_valoracion,
            "id_campania": self.id_campania,
            "id_usuario": self.id_usuario,
            "calificacion": self.calificacion,
            "comentario": self.comentario,
            "fecha_valoracion": self.fecha_valoracion.isoformat(),
            "visible": self.visible,
        }
        if self.usuario:
            data["usuario"] = {
                "nombre": self.usuario.nombre,
                "apellido": self.usuario.apellido,
            }
        return data

