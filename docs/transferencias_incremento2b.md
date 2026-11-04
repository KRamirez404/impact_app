# Transferencias bancarias — Incremento 2B

## Incremento de cierre RF-09 (4/11/2026)

La aprobación ahora exige `id_cuenta_recaudo`, `id_movimiento_bancario`,
`monto_abono` y `fecha_abono` consultados por soporte en la cuenta bancaria
receptora. El monto y la cuenta deben coincidir con la transferencia declarada;
la fecha del abono no puede preceder la fecha declarada. El identificador
bancario se normaliza y no puede acreditarse dos veces para la misma cuenta.
El comprobante del donante sigue siendo obligatorio y no reemplaza la consulta
bancaria. Los metadatos del abono solo se devuelven al soporte asignado, no al
donante. La aplicación **no consulta automáticamente el banco**: el aprobador
es responsable del contraste manual; introducir un identificador no prueba por
sí mismo que el dinero llegó.

La migración `impactapp_backend/migrations/20261104_03_bank_movement.sql` es
posterior a las dos migraciones originales. El 4/11/2026 se aplicaron las tres
en orden en la base PostgreSQL nueva `impactapp_rf09_20261104_test`; se verificaron
las tres columnas añadidas y la restricción de unicidad. No se aplica
automáticamente ni se ha aplicado a la base activa. La aprobación no debe
habilitarse sin una fuente bancaria comprobable. La interfaz Flutter
para consulta, descarga de comprobantes y revisión financiera de soporte se
añadió en este incremento, pero aún no se ha comprobado en un dispositivo.
La administración de cuentas y asignaciones financieras sigue disponible por
API restringida; no dispone de pantallas Flutter en este incremento.

Las pruebas dirigidas `test_transfers.py` y `test_notifications.py` terminaron
con **42 aprobadas y 0 omitidas** en esa base PostgreSQL aislada. La suite
PostgreSQL completa requiere una verificación independiente.

Fecha: 22/10/2026. Estado: backend implementado, módulo deshabilitado por defecto y
migraciones no aplicadas a la base activa. No incluye Flutter, correos, verificación
bancaria automática ni habilitación en producción.

## Alcance implementado

- Cuentas de recaudo por campaña con número cifrado, HMAC independiente para
  duplicados, últimos cuatro dígitos y estado `pendiente_verificacion`,
  `verificada` o `revocada`.
- Transferencias manuales asociadas uno a uno con una donación económica pendiente.
- Comprobantes privados versionados en PDF, JPEG o PNG de hasta 8 MiB.
- Revisión, rechazo y aprobación con asignaciones financieras y doble control.
- Historial del donante, consulta individual y descarga autenticada.
- Reenvío de una transferencia rechazada con un comprobante nuevo, sin alterar
  monto, cuenta, referencia bancaria ni fecha originales.
- Idempotencia por actor, operación y solicitud.

## Variables y habilitación

El módulo permanece deshabilitado con `TRANSFERENCIAS_ENABLED=0`. Si faltan tablas,
claves o una raíz privada válida, el arranque registra un blueprint de error seguro
que responde `503` con `code=transfer_feature_disabled`; no crea tablas.

Variables principales:

- `BANK_ACCOUNT_ENCRYPTION_KEY`: clave Fernet externa al repositorio.
- `BANK_ACCOUNT_ENCRYPTION_KEY_OLD`: opcional, solo para rotación de cifrado.
- `BANK_ACCOUNT_HASH_KEY`: clave HMAC independiente, mínimo 32 bytes.
- `PRIVATE_STORAGE_ROOT`: raíz absoluta fuera de `uploads`.
- `TRANSFER_RECEIPT_MAX_BYTES`: máximo por archivo; el código nunca acepta más de
  8 MiB.
- `TRANSFER_MIN_AMOUNT`: monto mínimo, por defecto 1000 COP.
- `FINANCIAL_ASSIGNMENTS_ENABLED`: obligatorio para administración, revisión y
  aprobación.
- `FINANCIAL_ADMIN_USER_ID`: usuario de soporte designado para gestionar cuentas.

La generación de claves, el orden de migraciones, el procedimiento de aplicación y
la rotación están en `impactapp_backend/migrations/README.md`.

## Endpoints

### Donante

| Método | Ruta | Función |
|---|---|---|
| GET | `/api/campaigns/:id/bank-account` | Cuenta verificada y número completo para pagar; respuesta privada. |
| POST | `/api/transfers` | Crea donación pendiente y transferencia; requiere `Idempotency-Key`. |
| GET | `/api/transfers/mine` | Historial propio paginado. |
| GET | `/api/transfers/:id` | Detalle propio. |
| POST | `/api/transfers/:id/receipt` | Carga inicial o nueva versión de comprobante. |
| POST | `/api/transfers/:id/resubmit` | Reenvío de una transferencia rechazada con comprobante nuevo. |
| GET | `/api/transfers/:id/receipt` | Descarga autenticada del último comprobante. |

### Soporte financiero

| Método | Ruta | Función |
|---|---|---|
| GET | `/api/support/transfers` | Cola limitada a campañas con asignación vigente. |
| GET | `/api/support/transfers/:id` | Detalle con autorización por campaña. |
| POST | `/api/support/transfers/:id/claim` | Reclamo para revisión; requiere `Idempotency-Key`. |
| POST | `/api/support/transfers/:id/reject` | Rechazo con motivo; requiere `Idempotency-Key`. |
| POST | `/api/support/transfers/:id/approve` | Aprobación; requiere asignación de contabilización y revisor distinto. |
| GET | `/api/support/transfers/:id/receipt` | Descarga autorizada para revisión. |

### Administración financiera

| Método | Ruta | Función |
|---|---|---|
| POST | `/api/financial/bank-accounts` | Crea cuenta pendiente; requiere `Idempotency-Key`. |
| GET | `/api/financial/bank-accounts` | Listado enmascarado. |
| GET | `/api/financial/bank-accounts/:id` | Detalle con número completo solo para el administrador designado. |
| POST | `/api/financial/bank-accounts/:id/verify` | Verifica una cuenta pendiente. |
| POST | `/api/financial/bank-accounts/:id/revoke` | Revoca con motivo; conserva historial. |

Respuestas de error: `{"error": "...", "code": "..."}`. Los códigos principales son
`transfer_validation`, `idempotency_required`, `idempotency_conflict`,
`transfer_duplicate`, `account_not_verified`, `account_revoked`, `receipt_required`,
`receipt_invalid_type`, `receipt_too_large`, `double_control_required`,
`transfer_state_conflict`, `financial_forbidden` y
`transfer_persistence_unavailable`.

## Reglas financieras y de seguridad

- El cliente no puede enviar `estado`; los campos se validan con lista permitida.
- La creación de transferencia y donación ocurre en una sola transacción SQL; la
  donación nace `pendiente` y no modifica totales.
- La aprobación bloquea campaña, donación y transferencia en ese orden, valida
  cuenta, importe, moneda, comprobante y estados, registra evento y auditoría,
  cambia la donación a aprobada y recalcula el progreso con `confirmar=False` antes
  de un único commit.
- Una segunda aprobación con la misma clave y contenido recupera el resultado; con
  otra clave devuelve conflicto y no acredita de nuevo.
- Revisor y aprobador deben ser personas distintas y tener asignaciones vigentes
  para la campaña. Tener rol `soporte` no concede permisos por sí solo.
- Solo el administrador financiero designado y activo gestiona cuentas.
- Una cuenta revocada no se usa para nuevas transferencias y bloquea la aprobación
  de transferencias aún no procesadas.
- Los comprobantes se guardan en una raíz privada, con nombre aleatorio, permisos
  `0600`, validación de extensión, MIME detectado y estructura básica. No se
  publican por `/uploads` ni se incluyen rutas internas en JSON.
- La descarga solo está disponible para el propietario o soporte con asignación
  vigente; responde con `Cache-Control: private, no-store` y
  `X-Content-Type-Options: nosniff`.
- Un comprobante técnicamente válido no demuestra por sí solo que el dinero fue
  recibido. La aprobación exige verificación bancaria manual independiente.

## Migración

Archivos:

- `impactapp_backend/migrations/20261022_01_financial_assignments.sql`
- `impactapp_backend/migrations/20261022_02_transfers.sql`

No se ejecutaron contra la base de desarrollo ni la activa. La segunda migración
depende de las tablas de asignaciones financieras de la primera y crea índices
parciales para una sola cuenta verificada por campaña y una sola transferencia
aprobada por donación. No se modifican `CAMPAÑA.cuenta_recaudo`, `DONACION` ni filas
existentes. No se usó `create_all()` para crear estas tablas en una base existente.

## Pruebas ejecutadas

SQLite temporal aislada:

```bash
TRANSFERENCIAS_ENABLED=1 FINANCIAL_ASSIGNMENTS_ENABLED=1 \
DATABASE_URL=sqlite:////tmp/.../transfer-test.db \
TEST_DATABASE_URL=sqlite:////tmp/.../transfer-test.db \
pytest impactapp_backend/tests/test_transfers.py
```

Resultado: `22 passed, 2 skipped` (las dos pruebas de concurrencia se omiten porque
SQLite no certifica bloqueos de fila).

PostgreSQL 16 desechable, volumen nuevo, `--network none`, sin puertos publicados,
contenedor de pruebas compartiendo su namespace de red y repositorio montado en
solo lectura:

Resultado: `24 passed`, incluidas aprobación concurrente y referencia bancaria
duplicada concurrente. La base se identificó como `impactapp_transfer_test` antes de
ejecutar. También se aplicaron ambas migraciones en otra instancia desechable con
tablas padre mínimas; se verificaron tablas, índices parciales y rechazo de
duplicados.

Regresión adicional: con bandera activa, `310 passed, 6 skipped` en la suite
completa; con bandera apagada, `288 passed, 4 skipped` fuera del módulo de
transferencias y `24 skipped` en ese módulo. La comprobación de arranque con
bandera activa y sin tablas/claves respondió `503` y no creó tablas de
transferencias; con bandera apagada no se crearon tablas ni rutas.

## Riesgos y pendientes

- No existe integración bancaria automática; la aprobación sigue siendo manual. La
  organización debe conservar evidencia independiente del ingreso.
- No hay envío de correos ni notificaciones en este incremento.
- No se implementó integración Flutter.
- La validación de PDF/JPEG/PNG es estructural, no un análisis antimalware ni un
  parser completo de PDF. Falta definir análisis de malware y límites de recursos.
- La rotación de la clave HMAC requiere re-hashear cuentas en mantenimiento; no se
  incluye script automático.
- Un fallo del proceso entre el guardado del archivo y el commit SQL puede dejar un
  archivo huérfano. Los fallos capturados se limpian; falta una reconciliación
  periódica de objetos huérfanos y registros sin archivo.
- No se implementó reasignación automática de donaciones anuladas.
- No se habilitaron transferencias reales en producción ni se aplicaron migraciones
  a la base activa.
