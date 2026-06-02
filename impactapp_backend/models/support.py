from datetime import datetime

from . import db


class SOPORTE(db.Model):
    __tablename__ = "SOPORTE"

    id_soporte = db.Column(db.Integer, primary_key=True)
    id_campania = db.Column(
        db.Integer, db.ForeignKey("CAMPAÑA.id_campania"), nullable=False
    )
    tipo = db.Column(
        db.Enum(
            "documento_oficial",
            "imagen",
            "enlace_medio",
            "certificado_institucional",
            "foto",
            name="soporte_tipo",
            native_enum=False,
        ),
        nullable=False,
    )
    url_o_ruta = db.Column(db.String(255), nullable=False)
    descripcion = db.Column(db.Text, nullable=True)
    fecha_carga = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    validado = db.Column(db.Boolean, default=False, nullable=False)

    def to_dict(self):
        return {
            "id_soporte": self.id_soporte,
            "id_campania": self.id_campania,
            "tipo": self.tipo,
            "url_o_ruta": self.url_o_ruta,
            "descripcion": self.descripcion,
            "fecha_carga": self.fecha_carga.isoformat(),
            "validado": self.validado,
        }

