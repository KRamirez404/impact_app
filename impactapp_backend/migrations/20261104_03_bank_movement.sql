BEGIN;

ALTER TABLE "TRANSFERENCIA_BANCARIA"
    ADD COLUMN id_movimiento_bancario VARCHAR(100) NULL,
    ADD COLUMN monto_abono NUMERIC(12, 2) NULL,
    ADD COLUMN fecha_abono DATE NULL;

ALTER TABLE "TRANSFERENCIA_BANCARIA"
    ADD CONSTRAINT uq_transferencia_movimiento_bancario
    UNIQUE (id_cuenta_recaudo, id_movimiento_bancario);

COMMIT;
