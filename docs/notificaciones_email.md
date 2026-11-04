# Notificaciones por correo

Implementación de la etapa de cierre de notificaciones. El envío está
**deshabilitado por defecto** (`MAIL_ENABLED=0`): el sistema registra el evento en
la base, pero no abre conexiones SMTP ni envía correos hasta que se configure y
active explícitamente.

## Diseño

Se usa un patrón *outbox*:

1. La operación financiera (pago Wompi, comprobante o revisión de transferencia)
   confirma su transacción.
2. Después del commit se registra una fila en `NOTIFICACION_EMAIL` con una
   `clave_evento` única.
3. Si el correo está habilitado, se intenta enviar de inmediato con `smtplib`.
4. Un fallo de SMTP solo deja la fila en estado `fallido`; nunca revierte el pago.
5. El script de reintentos procesa las filas pendientes o fallidas.

La clave única garantiza idempotencia: un webhook repetido o una nueva consulta
de estado no generan correos duplicados.

## Eventos

| Tipo | Cuándo se crea | Destinatario |
|---|---|---|
| `donacion_pendiente` | Checkout Wompi creado | Donante |
| `donacion_aprobada` | Pago confirmado por Wompi | Donante |
| `donacion_rechazada` | Pago rechazado por Wompi | Donante |
| `donacion_anulada` | Transacción anulada | Donante |
| `donacion_error` | Transacción en error | Donante |
| `transferencia_comprobante` | Comprobante cargado o reenviado | Donante |
| `transferencia_aprobada` | Transferencia aprobada | Donante |
| `transferencia_rechazada` | Transferencia rechazada, con motivo | Donante |

Las plantillas están en español, incluyen versión texto y HTML, y escapan el
contenido dinámico para evitar inyección de HTML.

## Variables de entorno

```dotenv
MAIL_ENABLED=0
MAIL_HOST=
MAIL_PORT=587
MAIL_USE_TLS=1
MAIL_USE_SSL=0
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_FROM=
MAIL_TIMEOUT=10
MAIL_MAX_ATTEMPTS=3
```

- `MAIL_ENABLED=1` habilita el envío; sin host y remitente válidos el intento se
  registra como fallido con `configuracion_smtp_incompleta`.
- `MAIL_USE_SSL=1` usa `SMTP_SSL`; en ese caso `MAIL_USE_TLS` se ignora.
- `MAIL_MAX_ATTEMPTS` limita los reintentos por notificación.
- La contraseña nunca se escribe en logs ni en el campo `ultimo_error`.

Procedimiento recomendado:

1. Configurar las variables fuera del repositorio.
2. Mantener `MAIL_ENABLED=0` mientras se valida el resto del sistema.
3. Ejecutar las pruebas con un servidor SMTP simulado.
4. Activar `MAIL_ENABLED=1`, reiniciar el backend y verificar un envío controlado.
5. Revisar `GET /api/support/notifications` y los logs.

## Reintentos

```bash
docker compose exec -T backend python scripts/send_pending_emails.py --limit 50
```

El script imprime `procesadas`, `enviadas` y `fallidas`, y devuelve código de
salida distinto de cero si alguna notificación falla. Puede programarse con cron
o un temporizador del orquestador. No se ejecuta automáticamente.

## Consulta para soporte

```http
GET /api/support/notifications?estado=fallido&limit=50
Authorization: Bearer <token-de-soporte>
```

Devuelve `total` e `items` con metadatos de la notificación (clave, tipo,
destinatario, asunto, estado, intentos y error saneado). No expone el cuerpo del
correo ni credenciales. Requiere rol `soporte` activo.

## Migración

`ensure_notification_schema()` crea la tabla con `checkfirst=True` al arrancar la
aplicación, por lo que es idempotente tanto en SQLite como en PostgreSQL. El
modelo define:

- clave única `clave_evento`;
- `CHECK estado IN ('pendiente', 'enviado', 'fallido')`;
- índice por `(estado, creado_en)`.

## Verificación ejecutada

- `tests/test_notifications.py`: **11 casos aprobados** en SQLite con
  transferencias habilitadas y **11 casos aprobados** en PostgreSQL aislado con
  transferencias habilitadas.
- Cubre: plantillas y escape HTML, idempotencia, correo deshabilitado, envío
  exitoso, fallo SMTP sin propagación, reintento, límite de intentos, permisos del
  endpoint, integración Wompi (pendiente/aprobada) y flujo de transferencia
  (comprobante/aprobada).
- Suite completa SQLite: **333 passed, 29 skipped**.
- Suite completa PostgreSQL aislado: **337 passed, 25 skipped**.

## Límites conocidos

- No se verificó un envío real contra un proveedor SMTP; las pruebas usan un
  cliente simulado.
- El envío es síncrono después del commit y usa `MAIL_TIMEOUT`; con el correo
  deshabilitado no agrega latencia.
- No hay gestión de rebotes, quejas ni plantillas editables por base de datos.
- Si el correo permanece deshabilitado, la cola conserva registros pendientes;
  debe revisarse o purgarse según la política operativa.
