from datetime import datetime

from . import db


class NOTIFICACION_EMAIL(db.Model):
    __tablename__ = "NOTIFICACION_EMAIL"
    __table_args__ = (
        db.UniqueConstraint("clave_evento", name="uq_notificacion_clave_evento"),
        db.CheckConstraint(
            "estado IN ('pendiente', 'enviado', 'fallido')",
            name="ck_notificacion_estado",
        ),
        db.Index("ix_notificacion_estado_fecha", "estado", "creado_en"),
    )

    id_notificacion = db.Column(db.Integer, primary_key=True)
    clave_evento = db.Column(db.String(160), nullable=False)
    destinatario = db.Column(db.String(150), nullable=False)
    tipo = db.Column(db.String(40), nullable=False)
    asunto = db.Column(db.String(200), nullable=False)
    cuerpo_texto = db.Column(db.Text, nullable=False)
    cuerpo_html = db.Column(db.Text, nullable=True)
    estado = db.Column(db.String(20), default="pendiente", nullable=False)
    intentos = db.Column(db.Integer, default=0, nullable=False)
    ultimo_error = db.Column(db.String(255), nullable=True)
    creado_en = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    actualizado_en = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )
    enviado_en = db.Column(db.DateTime, nullable=True)

    def to_dict(self):
        return {
            "id_notificacion": self.id_notificacion,
            "clave_evento": self.clave_evento,
            "destinatario": self.destinatario,
            "tipo": self.tipo,
            "asunto": self.asunto,
            "estado": self.estado,
            "intentos": self.intentos,
            "ultimo_error": self.ultimo_error,
            "creado_en": self.creado_en.isoformat(),
            "actualizado_en": self.actualizado_en.isoformat()
            if self.actualizado_en
            else None,
            "enviado_en": self.enviado_en.isoformat() if self.enviado_en else None,
        }
