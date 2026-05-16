from datetime import datetime

from . import db


class SEGUIMIENTO(db.Model):
    __tablename__ = "SEGUIMIENTO"

    id_seguimiento = db.Column(db.Integer, primary_key=True)
    id_campania = db.Column(
        db.Integer, db.ForeignKey("CAMPAÑA.id_campania"), nullable=False
    )
    fecha_registro = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    descripcion = db.Column(db.Text, nullable=False)
    porcentaje_avance = db.Column(db.Numeric(5, 2), default=0, nullable=False)
    evidencia_url = db.Column(db.String(255), nullable=True)

    def to_dict(self):
        return {
            "id_seguimiento": self.id_seguimiento,
            "id_campania": self.id_campania,
            "fecha_registro": self.fecha_registro.isoformat(),
            "descripcion": self.descripcion,
            "porcentaje_avance": float(self.porcentaje_avance or 0),
            "evidencia_url": self.evidencia_url,
        }

