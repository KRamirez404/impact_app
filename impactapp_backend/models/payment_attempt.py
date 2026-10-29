from datetime import datetime

from . import db


class PAGO_INTENTO(db.Model):
    __tablename__ = "PAGO_INTENTO"
    __table_args__ = (
        db.UniqueConstraint(
            "wompi_transaction_id",
            name="uq_pago_intento_wompi_transaction_id",
        ),
        db.CheckConstraint(
            "estado_autoritativo IN ('PENDING', 'APPROVED', 'DECLINED', 'VOIDED', 'ERROR')",
            name="ck_pago_intento_estado_autoritativo",
        ),
        db.CheckConstraint(
            "estado_local IN ('pendiente', 'aprobada', 'rechazada', 'anulada', 'error')",
            name="ck_pago_intento_estado_local",
        ),
        db.CheckConstraint(
            "resultado IN ('pendiente', 'acreditado', 'duplicado', 'ignorado', 'anulado')",
            name="ck_pago_intento_resultado",
        ),
        db.Index("ix_pago_intento_donacion", "id_donacion"),
        db.Index("ix_pago_intento_referencia", "referencia"),
    )

    id_intento = db.Column(db.Integer, primary_key=True)
    id_donacion = db.Column(
        db.Integer,
        db.ForeignKey("DONACION.id_donacion"),
        nullable=False,
    )
    wompi_transaction_id = db.Column(db.String(120), nullable=False)
    referencia = db.Column(db.String(255), nullable=False)
    estado_observado = db.Column(db.String(20), nullable=True)
    estado_autoritativo = db.Column(db.String(20), nullable=False)
    estado_local = db.Column(db.String(20), nullable=False)
    resultado = db.Column(db.String(20), nullable=False, default="pendiente")
    monto_en_centavos = db.Column(db.BigInteger, nullable=False)
    moneda = db.Column(db.String(3), nullable=False)
    metodo_pago = db.Column(db.String(40), nullable=True)
    origen = db.Column(db.String(20), nullable=False, default="webhook")
    creado_en = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    actualizado_en = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    donacion = db.relationship("DONACION", backref="intentos_pago")

    def to_dict(self):
        return {
            "id_intento": self.id_intento,
            "id_donacion": self.id_donacion,
            "wompi_transaction_id": self.wompi_transaction_id,
            "referencia": self.referencia,
            "estado_observado": self.estado_observado,
            "estado_autoritativo": self.estado_autoritativo,
            "estado_local": self.estado_local,
            "resultado": self.resultado,
            "monto_en_centavos": self.monto_en_centavos,
            "moneda": self.moneda,
            "metodo_pago": self.metodo_pago,
            "origen": self.origen,
            "creado_en": self.creado_en.isoformat(),
            "actualizado_en": self.actualizado_en.isoformat(),
        }
