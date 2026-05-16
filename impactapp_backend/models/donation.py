from datetime import datetime

from . import db


class DONACION(db.Model):
    __tablename__ = "DONACION"

    id_donacion = db.Column(db.Integer, primary_key=True)
    id_campania = db.Column(
        db.Integer, db.ForeignKey("CAMPAÑA.id_campania"), nullable=False
    )
    id_donante = db.Column(db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=False)
    id_punto = db.Column(
        db.Integer, db.ForeignKey("PUNTO_RECOLECCION.id_punto"), nullable=True
    )
    tipo = db.Column(
        db.Enum(
            "economica",
            "alimentos",
            "ropa",
            "medicamentos",
            "otros",
            name="donacion_tipo",
            native_enum=False,
        ),
        nullable=False,
    )
    monto_estimado = db.Column(db.Numeric(12, 2), default=0, nullable=False)
    descripcion = db.Column(db.Text, nullable=True)
    fecha_donacion = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    donante = db.relationship("USUARIO", backref="donaciones")
    punto = db.relationship("PUNTO_RECOLECCION", backref="donaciones")

    def to_dict(self):
        return {
            "id_donacion": self.id_donacion,
            "id_campania": self.id_campania,
            "id_donante": self.id_donante,
            "id_punto": self.id_punto,
            "tipo": self.tipo,
            "monto_estimado": float(self.monto_estimado or 0),
            "descripcion": self.descripcion,
            "fecha_donacion": self.fecha_donacion.isoformat(),
        }

