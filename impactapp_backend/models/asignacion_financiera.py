from datetime import datetime, timezone

from . import db


CAPACIDADES_FINANCIERAS = {"revision", "contabilizacion"}


def ahora_utc():
    return datetime.now(timezone.utc).replace(tzinfo=None)


class ASIGNACION_FINANCIERA(db.Model):
    __tablename__ = "ASIGNACION_FINANCIERA"
    __table_args__ = (
        db.UniqueConstraint("id_usuario", "id_campania", "capacidad", name="uq_asignacion_financiera_ambito"),
        db.CheckConstraint("capacidad IN ('revision', 'contabilizacion')", name="ck_asignacion_capacidad"),
        db.CheckConstraint("fecha_expiracion IS NULL OR fecha_expiracion > fecha_concesion", name="ck_asignacion_fechas"),
        db.CheckConstraint("fecha_revocacion IS NULL OR fecha_revocacion >= fecha_concesion", name="ck_asignacion_revocacion"),
    )

    id_asignacion = db.Column(db.Integer, primary_key=True)
    id_usuario = db.Column(db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=False)
    id_campania = db.Column(db.Integer, db.ForeignKey("CAMPAÑA.id_campania"), nullable=False)
    capacidad = db.Column(db.String(30), nullable=False)
    id_concedente = db.Column(db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=False)
    fecha_concesion = db.Column(db.DateTime, nullable=False, default=ahora_utc)
    fecha_expiracion = db.Column(db.DateTime, nullable=True)
    id_revocador = db.Column(db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=True)
    fecha_revocacion = db.Column(db.DateTime, nullable=True)

    def vigente(self, ahora=None):
        ahora = ahora or ahora_utc()
        return (
            self.fecha_concesion <= ahora
            and self.fecha_revocacion is None
            and (self.fecha_expiracion is None or ahora < self.fecha_expiracion)
        )

    def to_dict(self):
        return {
            "id_asignacion": self.id_asignacion,
            "id_usuario": self.id_usuario,
            "id_campania": self.id_campania,
            "capacidad": self.capacidad,
            "id_concedente": self.id_concedente,
            "fecha_concesion": self.fecha_concesion.isoformat() + "Z",
            "fecha_expiracion": self.fecha_expiracion.isoformat() + "Z" if self.fecha_expiracion else None,
            "id_revocador": self.id_revocador,
            "fecha_revocacion": self.fecha_revocacion.isoformat() + "Z" if self.fecha_revocacion else None,
            "vigente": self.vigente(),
        }


class EVENTO_ASIGNACION_FINANCIERA(db.Model):
    __tablename__ = "EVENTO_ASIGNACION_FINANCIERA"
    __table_args__ = (
        db.CheckConstraint("accion IN ('concedida', 'revocada')", name="ck_evento_asignacion_accion"),
    )

    id_evento = db.Column(db.Integer, primary_key=True)
    id_asignacion = db.Column(db.Integer, db.ForeignKey("ASIGNACION_FINANCIERA.id_asignacion"), nullable=False, index=True)
    id_actor = db.Column(db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=False)
    accion = db.Column(db.String(20), nullable=False)
    fecha = db.Column(db.DateTime, nullable=False, default=ahora_utc)
    motivo = db.Column(db.String(500), nullable=False)
    estado_anterior = db.Column(db.String(20), nullable=False)
    estado_nuevo = db.Column(db.String(20), nullable=False)
    fecha_expiracion = db.Column(db.DateTime, nullable=True)
    clave_idempotencia = db.Column(db.String(64), nullable=False, unique=True)
    huella_solicitud = db.Column(db.String(64), nullable=False)

    def to_dict(self):
        return {
            "id_evento": self.id_evento,
            "id_asignacion": self.id_asignacion,
            "id_actor": self.id_actor,
            "accion": self.accion,
            "fecha": self.fecha.isoformat() + "Z",
            "motivo": self.motivo,
            "estado_anterior": self.estado_anterior,
            "estado_nuevo": self.estado_nuevo,
            "fecha_expiracion": self.fecha_expiracion.isoformat() + "Z" if self.fecha_expiracion else None,
            "resultado": "registrada",
        }
