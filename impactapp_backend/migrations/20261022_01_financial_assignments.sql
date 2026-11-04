-- ImpactaApp - migración previa para autorización financiera.
-- No ejecutar contra la base activa sin backup, revisión y autorización.
-- Prerrequisito de 20261022_02_transfers.sql.

BEGIN;

CREATE TABLE "ASIGNACION_FINANCIERA" (
    id_asignacion SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    id_campania INTEGER NOT NULL REFERENCES "CAMPAÑA"(id_campania) ON DELETE RESTRICT,
    capacidad VARCHAR(30) NOT NULL,
    id_concedente INTEGER NOT NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    fecha_concesion TIMESTAMP NOT NULL,
    fecha_expiracion TIMESTAMP NULL,
    id_revocador INTEGER NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    fecha_revocacion TIMESTAMP NULL,
    CONSTRAINT uq_asignacion_financiera_ambito UNIQUE (id_usuario, id_campania, capacidad),
    CONSTRAINT ck_asignacion_capacidad CHECK (capacidad IN ('revision', 'contabilizacion')),
    CONSTRAINT ck_asignacion_fechas CHECK (
        fecha_expiracion IS NULL OR fecha_expiracion > fecha_concesion
    ),
    CONSTRAINT ck_asignacion_revocacion CHECK (
        fecha_revocacion IS NULL OR fecha_revocacion >= fecha_concesion
    )
);

CREATE INDEX ix_asignacion_financiera_usuario
    ON "ASIGNACION_FINANCIERA" (id_usuario, id_campania, capacidad);

CREATE TABLE "EVENTO_ASIGNACION_FINANCIERA" (
    id_evento SERIAL PRIMARY KEY,
    id_asignacion INTEGER NOT NULL
        REFERENCES "ASIGNACION_FINANCIERA"(id_asignacion) ON DELETE RESTRICT,
    id_actor INTEGER NOT NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    accion VARCHAR(20) NOT NULL,
    fecha TIMESTAMP NOT NULL,
    motivo VARCHAR(500) NOT NULL,
    estado_anterior VARCHAR(20) NOT NULL,
    estado_nuevo VARCHAR(20) NOT NULL,
    fecha_expiracion TIMESTAMP NULL,
    clave_idempotencia VARCHAR(64) NOT NULL,
    huella_solicitud VARCHAR(64) NOT NULL,
    CONSTRAINT uq_evento_asignacion_idempotencia UNIQUE (clave_idempotencia),
    CONSTRAINT ck_evento_asignacion_accion CHECK (accion IN ('concedida', 'revocada'))
);

CREATE INDEX ix_evento_asignacion
    ON "EVENTO_ASIGNACION_FINANCIERA" (id_asignacion, fecha);

COMMIT;
