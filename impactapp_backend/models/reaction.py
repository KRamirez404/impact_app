from datetime import datetime

from . import db


class REACCION(db.Model):
    __tablename__ = "REACCION"

    id_reaccion = db.Column(db.Integer, primary_key=True)
    id_campania = db.Column(
        db.Integer, db.ForeignKey("CAMPAÑA.id_campania"), nullable=False
    )
    id_usuario = db.Column(
        db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=False
    )
    fecha_reaccion = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    __table_args__ = (
        db.UniqueConstraint(
            "id_campania",
            "id_usuario",
            name="uq_reaccion_campania_usuario",
        ),
    )

    def to_dict(self):
        return {
            "id_reaccion": self.id_reaccion,
            "id_campania": self.id_campania,
            "id_usuario": self.id_usuario,
            "fecha_reaccion": self.fecha_reaccion.isoformat(),
        }
