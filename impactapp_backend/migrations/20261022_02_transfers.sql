-- ImpactaApp - transferencias bancarias manuales y comprobantes privados.
-- No ejecutar contra la base activa sin backup, revisión y autorización.
-- Requiere 20261022_01_financial_assignments.sql.

BEGIN;

CREATE TABLE "CUENTA_RECAUDO" (
    id_cuenta_recaudo SERIAL PRIMARY KEY,
    id_campania INTEGER NOT NULL REFERENCES "CAMPAÑA"(id_campania) ON DELETE RESTRICT,
    banco VARCHAR(100) NOT NULL,
    tipo_cuenta VARCHAR(20) NOT NULL,
    numero_cuenta_cifrado TEXT NOT NULL,
    numero_cuenta_hash CHAR(64) NOT NULL,
    ultimos4 CHAR(4) NOT NULL,
    titular VARCHAR(150) NOT NULL,
    moneda CHAR(3) NOT NULL DEFAULT 'COP',
    estado VARCHAR(30) NOT NULL DEFAULT 'pendiente_verificacion',
    id_verificador INTEGER NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    fecha_verificacion TIMESTAMP NULL,
    id_revocador INTEGER NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    fecha_revocacion TIMESTAMP NULL,
    motivo_revocacion TEXT NULL,
    clave_idempotencia CHAR(64) NOT NULL,
    huella_solicitud CHAR(64) NOT NULL,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cuenta_recaudo_numero_campania UNIQUE (id_campania, numero_cuenta_hash),
    CONSTRAINT uq_cuenta_recaudo_idempotencia UNIQUE (clave_idempotencia),
    CONSTRAINT ck_cuenta_recaudo_tipo CHECK (tipo_cuenta IN ('ahorros', 'corriente')),
    CONSTRAINT ck_cuenta_recaudo_moneda CHECK (moneda = 'COP'),
    CONSTRAINT ck_cuenta_recaudo_estado CHECK (
        estado IN ('pendiente_verificacion', 'verificada', 'revocada')
    )
);

CREATE INDEX ix_cuenta_recaudo_campania_estado
    ON "CUENTA_RECAUDO" (id_campania, estado);

CREATE UNIQUE INDEX uq_cuenta_verificada_por_campania
    ON "CUENTA_RECAUDO" (id_campania)
    WHERE estado = 'verificada';

CREATE TABLE "TRANSFERENCIA_BANCARIA" (
    id_transferencia SERIAL PRIMARY KEY,
    id_donacion INTEGER NOT NULL REFERENCES "DONACION"(id_donacion) ON DELETE RESTRICT,
    id_donante INTEGER NOT NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    id_campania INTEGER NOT NULL REFERENCES "CAMPAÑA"(id_campania) ON DELETE RESTRICT,
    id_cuenta_recaudo INTEGER NOT NULL
        REFERENCES "CUENTA_RECAUDO"(id_cuenta_recaudo) ON DELETE RESTRICT,
    monto_declarado NUMERIC(12, 2) NOT NULL,
    moneda CHAR(3) NOT NULL DEFAULT 'COP',
    referencia_bancaria VARCHAR(100) NOT NULL,
    fecha_transferencia DATE NOT NULL,
    descripcion TEXT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'registrada',
    id_revisor INTEGER NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    fecha_revision TIMESTAMP NULL,
    motivo_rechazo TEXT NULL,
    id_aprobador INTEGER NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    fecha_aprobacion TIMESTAMP NULL,
    clave_idempotencia CHAR(64) NOT NULL,
    huella_solicitud CHAR(64) NOT NULL,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_transferencia_cuenta_referencia
        UNIQUE (id_cuenta_recaudo, referencia_bancaria),
    CONSTRAINT uq_transferencia_donacion UNIQUE (id_donacion),
    CONSTRAINT uq_transferencia_idempotencia UNIQUE (clave_idempotencia),
    CONSTRAINT ck_transferencia_monto CHECK (monto_declarado > 0),
    CONSTRAINT ck_transferencia_moneda CHECK (moneda = 'COP'),
    CONSTRAINT ck_transferencia_estado CHECK (
        estado IN ('registrada', 'en_revision', 'aprobada', 'rechazada')
    ),
    CONSTRAINT ck_transferencia_motivo_rechazo CHECK (
        estado <> 'rechazada'
        OR (motivo_rechazo IS NOT NULL AND length(trim(motivo_rechazo)) > 0)
    )
);

CREATE INDEX ix_transferencia_campania_estado
    ON "TRANSFERENCIA_BANCARIA" (id_campania, estado, creado_en);

CREATE INDEX ix_transferencia_donante
    ON "TRANSFERENCIA_BANCARIA" (id_donante, creado_en);

CREATE UNIQUE INDEX uq_transferencia_aprobada_por_donacion
    ON "TRANSFERENCIA_BANCARIA" (id_donacion)
    WHERE estado = 'aprobada';

CREATE TABLE "COMPROBANTE_TRANSFERENCIA" (
    id_comprobante SERIAL PRIMARY KEY,
    id_transferencia INTEGER NOT NULL
        REFERENCES "TRANSFERENCIA_BANCARIA"(id_transferencia) ON DELETE RESTRICT,
    version INTEGER NOT NULL,
    clave_almacenamiento VARCHAR(160) NOT NULL,
    mime VARCHAR(100) NOT NULL,
    tamano_bytes BIGINT NOT NULL,
    sha256 CHAR(64) NOT NULL,
    estado_tecnico VARCHAR(20) NOT NULL DEFAULT 'validado',
    subido_por INTEGER NOT NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_comprobante_transferencia_version
        UNIQUE (id_transferencia, version),
    CONSTRAINT uq_comprobante_transferencia_sha256
        UNIQUE (id_transferencia, sha256),
    CONSTRAINT uq_comprobante_clave_almacenamiento
        UNIQUE (clave_almacenamiento),
    CONSTRAINT ck_comprobante_mime CHECK (
        mime IN ('application/pdf', 'image/jpeg', 'image/png')
    ),
    CONSTRAINT ck_comprobante_tamano CHECK (tamano_bytes > 0),
    CONSTRAINT ck_comprobante_estado_tecnico CHECK (
        estado_tecnico IN ('pendiente', 'validado', 'rechazado')
    )
);

CREATE INDEX ix_comprobante_transferencia
    ON "COMPROBANTE_TRANSFERENCIA" (id_transferencia, version);

CREATE TABLE "TRANSFERENCIA_EVENTO" (
    id_evento SERIAL PRIMARY KEY,
    id_transferencia INTEGER NOT NULL
        REFERENCES "TRANSFERENCIA_BANCARIA"(id_transferencia) ON DELETE RESTRICT,
    accion VARCHAR(30) NOT NULL,
    estado_anterior VARCHAR(20) NULL,
    estado_nuevo VARCHAR(20) NULL,
    id_actor INTEGER NOT NULL REFERENCES "USUARIO"(id_usuario) ON DELETE RESTRICT,
    motivo TEXT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    clave_idempotencia CHAR(64) NOT NULL,
    huella_solicitud CHAR(64) NOT NULL,
    CONSTRAINT uq_transferencia_evento_idempotencia UNIQUE (clave_idempotencia),
    CONSTRAINT ck_transferencia_evento_accion CHECK (
        accion IN (
            'registrada', 'en_revision', 'aprobada',
            'rechazada', 'reenviada', 'comprobante_cargado'
        )
    )
);

CREATE INDEX ix_transferencia_evento_fecha
    ON "TRANSFERENCIA_EVENTO" (id_transferencia, fecha);

COMMIT;
