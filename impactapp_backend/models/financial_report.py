from datetime import datetime

from . import db


class INFORME_FINANCIERO(db.Model):
    __tablename__ = "INFORME_FINANCIERO"
    id_informe = db.Column(db.Integer, primary_key=True)
    id_campania = db.Column(db.Integer, db.ForeignKey("CAMPAÑA.id_campania"), nullable=False, unique=True)
    ruta = db.Column(db.String(255), nullable=False, unique=True)
    nombre_archivo = db.Column(db.String(255), nullable=False)
    mime_type = db.Column(db.String(120), nullable=False)
    creado_en = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    campania = db.relationship("CAMPAÑA", backref=db.backref("informe_financiero", uselist=False))

    def to_dict(self):
        return {"id_informe": self.id_informe, "id_campania": self.id_campania, "ruta": self.ruta,
                "nombre_archivo": self.nombre_archivo, "mime_type": self.mime_type,
                "creado_en": self.creado_en.isoformat()}
