from datetime import date

from . import db


class CAMPAÑA(db.Model):
    __tablename__ = "CAMPAÑA"

    id_campania = db.Column(db.Integer, primary_key=True)
    titulo = db.Column(db.String(200), nullable=False)
    descripcion = db.Column(db.Text, nullable=False)
    id_ciudad = db.Column(db.Integer, db.ForeignKey("CIUDAD.id_ciudad"), nullable=False)
    id_categoria = db.Column(
        db.Integer, db.ForeignKey("CATEGORIA.id_categoria"), nullable=False
    )
    id_creador = db.Column(db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=False)
    tipo_ayuda_requerida = db.Column(
        db.Enum(
            "economica",
            "alimentos",
            "ropa",
            "medicamentos",
            "mixta",
            name="campania_tipo_ayuda",
            native_enum=False,
        ),
        nullable=False,
    )
    meta_monetaria = db.Column(db.Numeric(12, 2), default=0, nullable=False)
    fecha_inicio = db.Column(db.Date, default=date.today, nullable=False)
    fecha_fin = db.Column(db.Date, nullable=False)
    estado = db.Column(
        db.Enum(
            "activa",
            "finalizada",
            "pausada",
            "en_verificacion",
            name="campania_estado",
            native_enum=False,
        ),
        default="en_verificacion",
        nullable=False,
    )
    #cuenta_recaudo = db.Column(db.String(100), nullable=True)
    nota_revision = db.Column(db.Text, nullable=True)
    fecha_revision = db.Column(db.DateTime, nullable=True)
    id_auditor = db.Column(db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=True)
    porcentaje_avance = db.Column(db.Numeric(5, 2), default=0, nullable=False)

    ciudad = db.relationship("CIUDAD", backref="campañas")
    categoria = db.relationship("CATEGORIA", backref="campañas")
    donaciones = db.relationship("DONACION", backref="campania", lazy=True)
    valoraciones = db.relationship("VALORACION", backref="campania", lazy=True)
    soportes = db.relationship("SOPORTE", backref="campania", lazy=True)
    seguimientos = db.relationship("SEGUIMIENTO", backref="campania", lazy=True)
    puntos_recoleccion = db.relationship("PUNTO_RECOLECCION", backref="campania", lazy=True)
    reacciones = db.relationship("REACCION", backref="campania", lazy=True)
    auditor = db.relationship("USUARIO", foreign_keys=[id_auditor], lazy=True)

    def to_dict(self, include_relations=False):
        data = {
            "id_campania": self.id_campania,
            "titulo": self.titulo,
            "descripcion": self.descripcion,
            "id_ciudad": self.id_ciudad,
            "id_categoria": self.id_categoria,
            "id_creador": self.id_creador,
            "tipo_ayuda_requerida": self.tipo_ayuda_requerida,
            "meta_monetaria": float(self.meta_monetaria or 0),
            "fecha_inicio": self.fecha_inicio.isoformat(),
            "fecha_fin": self.fecha_fin.isoformat(),
            "estado": self.estado,
         #   "cuenta_recaudo": self.cuenta_recaudo,
            "nota_revision": self.nota_revision,
            "fecha_revision": self.fecha_revision.isoformat() if self.fecha_revision else None,
            "porcentaje_avance": float(self.porcentaje_avance or 0),
        }
        if include_relations:
            data["ciudad"] = self.ciudad.to_dict() if self.ciudad else None
            data["categoria"] = self.categoria.to_dict() if self.categoria else None
            data["creador"] = self.creador.to_dict() if self.creador else None
            data["auditor"] = self.auditor.to_dict() if self.auditor else None
        return data
