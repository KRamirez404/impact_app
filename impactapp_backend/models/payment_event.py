from datetime import datetime

from . import db


class PAGO_EVENTO(db.Model):
    __tablename__ = "PAGO_EVENTO"
    __table_args__ = (
        db.UniqueConstraint("huella_evento", name="uq_pago_evento_huella"),
        db.CheckConstraint(
            "resultado IN ('aplicado', 'ignorado', 'sin_donacion')",
            name="ck_pago_evento_resultado",
        ),
        db.CheckConstraint(
            "ambiente IN ('test', 'prod')",
            name="ck_pago_evento_ambiente",
        ),
    )

    id_evento = db.Column(db.Integer, primary_key=True)
    huella_evento = db.Column(db.String(64), nullable=False)
    tipo_evento = db.Column(db.String(40), nullable=False)
    id_donacion = db.Column(
        db.Integer, db.ForeignKey("DONACION.id_donacion"), nullable=True
    )
    referencia = db.Column(db.String(255), nullable=True)
    wompi_transaction_id = db.Column(db.String(120), nullable=True, index=True)
    estado_wompi = db.Column(db.String(20), nullable=True)
    monto_en_centavos = db.Column(db.BigInteger, nullable=True)
    moneda = db.Column(db.String(3), nullable=True)
    ambiente = db.Column(db.String(10), nullable=False)
    resultado = db.Column(db.String(20), nullable=False)
    recibido_en = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    donacion = db.relationship("DONACION", backref="eventos_pago")

    def to_dict(self):
        return {
            "id_evento": self.id_evento,
            "huella_evento": self.huella_evento,
            "tipo_evento": self.tipo_evento,
            "id_donacion": self.id_donacion,
            "referencia": self.referencia,
            "wompi_transaction_id": self.wompi_transaction_id,
            "estado_wompi": self.estado_wompi,
            "monto_en_centavos": self.monto_en_centavos,
            "moneda": self.moneda,
            "ambiente": self.ambiente,
            "resultado": self.resultado,
            "recibido_en": self.recibido_en.isoformat(),
        }
