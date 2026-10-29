from datetime import datetime

from . import db


class CUENTA_RECAUDO(db.Model):
    __tablename__ = "CUENTA_RECAUDO"
    __table_args__ = (
        db.UniqueConstraint(
            "id_campania",
            "numero_cuenta_hash",
            name="uq_cuenta_recaudo_numero_campania",
        ),
        db.UniqueConstraint(
            "clave_idempotencia",
            name="uq_cuenta_recaudo_idempotencia",
        ),
        db.CheckConstraint(
            "tipo_cuenta IN ('ahorros', 'corriente')",
            name="ck_cuenta_recaudo_tipo",
        ),
        db.CheckConstraint(
            "moneda = 'COP'",
            name="ck_cuenta_recaudo_moneda",
        ),
        db.CheckConstraint(
            "estado IN ('pendiente_verificacion', 'verificada', 'revocada')",
            name="ck_cuenta_recaudo_estado",
        ),
        db.Index("ix_cuenta_recaudo_campania_estado", "id_campania", "estado"),
    )

    id_cuenta_recaudo = db.Column(db.Integer, primary_key=True)
    id_campania = db.Column(
        db.Integer,
        db.ForeignKey("CAMPAÑA.id_campania"),
        nullable=False,
    )
    banco = db.Column(db.String(100), nullable=False)
    tipo_cuenta = db.Column(db.String(20), nullable=False)
    numero_cuenta_cifrado = db.Column(db.Text, nullable=False)
    numero_cuenta_hash = db.Column(db.String(64), nullable=False)
    ultimos4 = db.Column(db.String(4), nullable=False)
    titular = db.Column(db.String(150), nullable=False)
    moneda = db.Column(db.String(3), nullable=False, default="COP")
    estado = db.Column(
        db.String(30), nullable=False, default="pendiente_verificacion"
    )
    id_verificador = db.Column(
        db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=True
    )
    fecha_verificacion = db.Column(db.DateTime, nullable=True)
    id_revocador = db.Column(
        db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=True
    )
    fecha_revocacion = db.Column(db.DateTime, nullable=True)
    motivo_revocacion = db.Column(db.Text, nullable=True)
    clave_idempotencia = db.Column(db.String(64), nullable=False)
    huella_solicitud = db.Column(db.String(64), nullable=False)
    creado_en = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    actualizado_en = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    campania = db.relationship("CAMPAÑA")
    verificador = db.relationship("USUARIO", foreign_keys=[id_verificador])
    revocador = db.relationship("USUARIO", foreign_keys=[id_revocador])

    def to_dict(self):
        return {
            "id_cuenta_recaudo": self.id_cuenta_recaudo,
            "id_campania": self.id_campania,
            "banco": self.banco,
            "tipo_cuenta": self.tipo_cuenta,
            "numero_cuenta": f"****{self.ultimos4}",
            "ultimos4": self.ultimos4,
            "titular": self.titular,
            "moneda": self.moneda,
            "estado": self.estado,
            "id_verificador": self.id_verificador,
            "fecha_verificacion": self.fecha_verificacion.isoformat() if self.fecha_verificacion else None,
            "id_revocador": self.id_revocador,
            "fecha_revocacion": self.fecha_revocacion.isoformat() if self.fecha_revocacion else None,
            "motivo_revocacion": self.motivo_revocacion,
            "creado_en": self.creado_en.isoformat(),
            "actualizado_en": self.actualizado_en.isoformat(),
        }


class TRANSFERENCIA_BANCARIA(db.Model):
    __tablename__ = "TRANSFERENCIA_BANCARIA"
    __table_args__ = (
        db.UniqueConstraint(
            "id_cuenta_recaudo",
            "referencia_bancaria",
            name="uq_transferencia_cuenta_referencia",
        ),
        db.UniqueConstraint(
            "id_donacion",
            name="uq_transferencia_donacion",
        ),
        db.UniqueConstraint(
            "clave_idempotencia",
            name="uq_transferencia_idempotencia",
        ),
        db.CheckConstraint(
            "monto_declarado > 0",
            name="ck_transferencia_monto",
        ),
        db.CheckConstraint(
            "moneda = 'COP'",
            name="ck_transferencia_moneda",
        ),
        db.CheckConstraint(
            "estado IN ('registrada', 'en_revision', 'aprobada', 'rechazada')",
            name="ck_transferencia_estado",
        ),
        db.CheckConstraint(
            "estado <> 'rechazada' OR (motivo_rechazo IS NOT NULL AND length(trim(motivo_rechazo)) > 0)",
            name="ck_transferencia_motivo_rechazo",
        ),
        db.Index(
            "ix_transferencia_campania_estado",
            "id_campania",
            "estado",
            "creado_en",
        ),
        db.Index("ix_transferencia_donante", "id_donante", "creado_en"),
    )

    id_transferencia = db.Column(db.Integer, primary_key=True)
    id_donacion = db.Column(
        db.Integer,
        db.ForeignKey("DONACION.id_donacion"),
        nullable=False,
    )
    id_donante = db.Column(
        db.Integer,
        db.ForeignKey("USUARIO.id_usuario"),
        nullable=False,
    )
    id_campania = db.Column(
        db.Integer,
        db.ForeignKey("CAMPAÑA.id_campania"),
        nullable=False,
    )
    id_cuenta_recaudo = db.Column(
        db.Integer,
        db.ForeignKey("CUENTA_RECAUDO.id_cuenta_recaudo"),
        nullable=False,
    )
    monto_declarado = db.Column(db.Numeric(12, 2), nullable=False)
    moneda = db.Column(db.String(3), nullable=False, default="COP")
    referencia_bancaria = db.Column(db.String(100), nullable=False)
    fecha_transferencia = db.Column(db.Date, nullable=False)
    descripcion = db.Column(db.Text, nullable=True)
    estado = db.Column(db.String(20), nullable=False, default="registrada")
    id_revisor = db.Column(
        db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=True
    )
    fecha_revision = db.Column(db.DateTime, nullable=True)
    motivo_rechazo = db.Column(db.Text, nullable=True)
    id_aprobador = db.Column(
        db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=True
    )
    fecha_aprobacion = db.Column(db.DateTime, nullable=True)
    clave_idempotencia = db.Column(db.String(64), nullable=False)
    huella_solicitud = db.Column(db.String(64), nullable=False)
    creado_en = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    actualizado_en = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    donacion = db.relationship("DONACION")
    donante = db.relationship("USUARIO", foreign_keys=[id_donante])
    campania = db.relationship("CAMPAÑA")
    cuenta = db.relationship("CUENTA_RECAUDO")
    revisor = db.relationship("USUARIO", foreign_keys=[id_revisor])
    aprobador = db.relationship("USUARIO", foreign_keys=[id_aprobador])

    def to_dict(self):
        return {
            "id_transferencia": self.id_transferencia,
            "id_donacion": self.id_donacion,
            "id_donante": self.id_donante,
            "id_campania": self.id_campania,
            "id_cuenta_recaudo": self.id_cuenta_recaudo,
            "monto": str(self.monto_declarado),
            "moneda": self.moneda,
            "referencia_bancaria": self.referencia_bancaria,
            "fecha_transferencia": self.fecha_transferencia.isoformat(),
            "descripcion": self.descripcion,
            "estado": self.estado,
            "id_revisor": self.id_revisor,
            "fecha_revision": self.fecha_revision.isoformat() if self.fecha_revision else None,
            "motivo_rechazo": self.motivo_rechazo,
            "id_aprobador": self.id_aprobador,
            "fecha_aprobacion": self.fecha_aprobacion.isoformat() if self.fecha_aprobacion else None,
            "creado_en": self.creado_en.isoformat(),
            "actualizado_en": self.actualizado_en.isoformat(),
        }


class COMPROBANTE_TRANSFERENCIA(db.Model):
    __tablename__ = "COMPROBANTE_TRANSFERENCIA"
    __table_args__ = (
        db.UniqueConstraint(
            "id_transferencia",
            "version",
            name="uq_comprobante_transferencia_version",
        ),
        db.UniqueConstraint(
            "id_transferencia",
            "sha256",
            name="uq_comprobante_transferencia_sha256",
        ),
        db.UniqueConstraint(
            "clave_almacenamiento",
            name="uq_comprobante_clave_almacenamiento",
        ),
        db.CheckConstraint(
            "mime IN ('application/pdf', 'image/jpeg', 'image/png')",
            name="ck_comprobante_mime",
        ),
        db.CheckConstraint(
            "tamano_bytes > 0",
            name="ck_comprobante_tamano",
        ),
        db.CheckConstraint(
            "estado_tecnico IN ('pendiente', 'validado', 'rechazado')",
            name="ck_comprobante_estado_tecnico",
        ),
        db.Index("ix_comprobante_transferencia", "id_transferencia", "version"),
    )

    id_comprobante = db.Column(db.Integer, primary_key=True)
    id_transferencia = db.Column(
        db.Integer,
        db.ForeignKey("TRANSFERENCIA_BANCARIA.id_transferencia"),
        nullable=False,
    )
    version = db.Column(db.Integer, nullable=False)
    clave_almacenamiento = db.Column(db.String(160), nullable=False)
    mime = db.Column(db.String(100), nullable=False)
    tamano_bytes = db.Column(db.BigInteger, nullable=False)
    sha256 = db.Column(db.String(64), nullable=False)
    estado_tecnico = db.Column(db.String(20), nullable=False, default="validado")
    subido_por = db.Column(
        db.Integer,
        db.ForeignKey("USUARIO.id_usuario"),
        nullable=False,
    )
    creado_en = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    transferencia = db.relationship("TRANSFERENCIA_BANCARIA", backref="comprobantes")
    usuario = db.relationship("USUARIO")

    def to_dict(self):
        return {
            "id_comprobante": self.id_comprobante,
            "id_transferencia": self.id_transferencia,
            "version": self.version,
            "mime": self.mime,
            "tamano_bytes": self.tamano_bytes,
            "sha256": self.sha256,
            "estado_tecnico": self.estado_tecnico,
            "subido_por": self.subido_por,
            "creado_en": self.creado_en.isoformat(),
        }


class TRANSFERENCIA_EVENTO(db.Model):
    __tablename__ = "TRANSFERENCIA_EVENTO"
    __table_args__ = (
        db.UniqueConstraint(
            "clave_idempotencia",
            name="uq_transferencia_evento_idempotencia",
        ),
        db.CheckConstraint(
            "accion IN ('registrada', 'en_revision', 'aprobada', 'rechazada', 'reenviada', 'comprobante_cargado')",
            name="ck_transferencia_evento_accion",
        ),
        db.Index("ix_transferencia_evento_fecha", "id_transferencia", "fecha"),
    )

    id_evento = db.Column(db.Integer, primary_key=True)
    id_transferencia = db.Column(
        db.Integer,
        db.ForeignKey("TRANSFERENCIA_BANCARIA.id_transferencia"),
        nullable=False,
    )
    accion = db.Column(db.String(30), nullable=False)
    estado_anterior = db.Column(db.String(20), nullable=True)
    estado_nuevo = db.Column(db.String(20), nullable=True)
    id_actor = db.Column(
        db.Integer,
        db.ForeignKey("USUARIO.id_usuario"),
        nullable=False,
    )
    motivo = db.Column(db.Text, nullable=True)
    fecha = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    clave_idempotencia = db.Column(db.String(64), nullable=False)
    huella_solicitud = db.Column(db.String(64), nullable=False)

    transferencia = db.relationship("TRANSFERENCIA_BANCARIA", backref="eventos")
    actor = db.relationship("USUARIO")

    def to_dict(self):
        return {
            "id_evento": self.id_evento,
            "id_transferencia": self.id_transferencia,
            "accion": self.accion,
            "estado_anterior": self.estado_anterior,
            "estado_nuevo": self.estado_nuevo,
            "id_actor": self.id_actor,
            "motivo": self.motivo,
            "fecha": self.fecha.isoformat(),
        }
