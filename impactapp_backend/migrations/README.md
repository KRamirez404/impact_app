# Migraciones de transferencias bancarias

Estas migraciones son explícitas y **no se aplican automáticamente**. No se han
ejecutado contra la base de desarrollo ni contra la base activa.

## Orden

1. `20261022_01_financial_assignments.sql`
2. `20261022_02_transfers.sql`

La primera crea las tablas de asignaciones financieras que el backend ya modela y
que son prerrequisito para el doble control. La segunda crea las cuatro tablas de
transferencias y comprobantes privados. Ambas usan `BEGIN`/`COMMIT` y fallan de
forma explícita si una tabla o índice ya existe con el mismo nombre. No hay
migración automática ni `create_all()` para estas tablas.

## Procedimiento de aplicación

1. Detener escrituras o poner el backend en mantenimiento. Mantener
   `TRANSFERENCIAS_ENABLED=0` y `FINANCIAL_ASSIGNMENTS_ENABLED=0` para que el
   arranque no cree tablas de asignaciones mediante `create_all()`.
2. Tomar un backup verificable de la base y probar la restauración.
3. Revisar el SQL contra el esquema real. En particular, confirmar que no existan
   tablas de asignaciones con un esquema distinto.
4. Aplicar `20261022_01_financial_assignments.sql` y después
   `20261022_02_transfers.sql` con un usuario que pueda crear tablas e índices.
5. Verificar tablas, claves foráneas, `CHECK` e índices parciales:
   - `uq_cuenta_verificada_por_campania`
   - `uq_transferencia_aprobada_por_donacion`
6. Configurar las claves, la raíz privada y las variables de entorno descritas
   abajo. No activar todavía.
7. Solo después de revisar y autorizar, poner `FINANCIAL_ASSIGNMENTS_ENABLED=1` y
   `TRANSFERENCIAS_ENABLED=1`, reiniciar y verificar que el módulo responde.

Si faltan tablas, claves o una raíz privada válida, el arranque deja el módulo
deshabilitado y las rutas de transferencias responden `503` con
`code=transfer_feature_disabled`. No se crean tablas de respaldo ni se habilitan
permisos por rol.

## Variables

```dotenv
TRANSFERENCIAS_ENABLED=0
FINANCIAL_ASSIGNMENTS_ENABLED=0
FINANCIAL_ADMIN_USER_ID=
PRIVATE_STORAGE_ROOT=/app/private_uploads
TRANSFER_RECEIPT_MAX_BYTES=8388608
TRANSFER_MIN_AMOUNT=1000
BANK_ACCOUNT_ENCRYPTION_KEY=
BANK_ACCOUNT_ENCRYPTION_KEY_OLD=
BANK_ACCOUNT_HASH_KEY=
```

Generar claves fuera del repositorio y no versionarlas:

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
python -c "import secrets; print(secrets.token_hex(32))"
```

`BANK_ACCOUNT_ENCRYPTION_KEY` cifra el número de cuenta con Fernet
(AES-CBC + HMAC de `cryptography`). `BANK_ACCOUNT_HASH_KEY` es una clave HMAC
independiente para detectar duplicados; no se deriva de la primera. La raíz privada
debe ser absoluta, estar fuera de `uploads` y ser un volumen privado; el servicio
crea directorios con permisos `0700`.

## Rotación

- Cifrado: configurar la clave anterior en `BANK_ACCOUNT_ENCRYPTION_KEY_OLD`, poner
  la nueva en `BANK_ACCOUNT_ENCRYPTION_KEY`, mantener el módulo en mantenimiento y
  re-cifrar las cuentas existentes mediante un procedimiento revisado. La lectura
  acepta ambas claves; la escritura usa la nueva. Retirar la anterior al terminar.
- HMAC: los hashes no se pueden re-cifrar. Para rotar, mantener el módulo en
  mantenimiento, descifrar cada cuenta con la clave de cifrado, recalcular el hash
  con la nueva clave y actualizar la fila. La unicidad por campaña debe revisarse
  antes de confirmar. No se incluye un script automático en este incremento.

## Rollback

Las migraciones son aditivas y no modifican `CAMPAÑA.cuenta_recaudo`, `DONACION` ni
datos existentes. El rollback previsto es restaurar el backup verificado; no se
incluye un `DROP` automático. Cualquier eliminación de tablas o datos requiere una
decisión explícita y un backup restaurado.
