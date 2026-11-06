# Notificaciones por correo

Implementación del sistema general de notificaciones. El envío está
**deshabilitado por defecto** (`MAIL_ENABLED=0`): el sistema registra el evento en
la base, pero no abre conexiones SMTP ni llama a un proveedor externo hasta que se
configure y active explícitamente.

## Diseño

Se usa un patrón *outbox*:

1. La operación (registro, campaña, donación en especie, pago Wompi o revisión de
   transferencia) confirma su transacción.
2. Después del commit se registra una fila en `NOTIFICACION_EMAIL` con una
   `clave_evento` única y, cuando se identifica al usuario, su `id_usuario`.
3. Si el correo está habilitado, se intenta enviar de inmediato.
4. Un fallo del proveedor solo deja la fila en estado `fallido`; nunca revierte la
   operación de negocio.
5. El script de reintentos procesa las filas pendientes o fallidas.

La clave única garantiza idempotencia: un webhook repetido o una nueva consulta
de estado no generan correos duplicados. Al enviar se resuelve el correo **actual**
del usuario desde `USUARIO`, por lo que un cambio de correo posterior al evento se
respeta.

## Eventos

| Tipo | Cuándo se crea | Destinatario |
|---|---|---|
| `bienvenida` | Registro completado | Usuario |
| `campania_creada` | Campaña creada, pendiente de verificación | Organizador |
| `donacion_especie` | Donación en especie registrada | Donante |
| `donacion_pendiente` | Checkout Wompi creado | Donante |
| `donacion_aprobada` | Pago confirmado por Wompi | Donante |
| `donacion_rechazada` | Pago rechazado por Wompi | Donante |
| `donacion_anulada` | Transacción anulada | Donante |
| `donacion_error` | Transacción en error | Donante |
| `transferencia_comprobante` | Comprobante cargado o reenviado | Donante |
| `transferencia_aprobada` | Transferencia aprobada | Donante |
| `transferencia_rechazada` | Transferencia rechazada, con motivo | Donante |

Las plantillas están en español, incluyen fecha UTC, versión texto y HTML adaptable,
y escapan el contenido dinámico para evitar inyección de HTML.

## Proveedores

### API HTTPS (recomendado)

`MAIL_PROVIDER=brevo` usa `POST https://api.brevo.com/v3/smtp/email` con
autenticación por header `api-key`. La implementación usa `urllib` de la librería
estándar, no agrega dependencias y está aislada en
`services/email_provider.py`.

```dotenv
MAIL_ENABLED=1
MAIL_PROVIDER=brevo
MAIL_API_KEY=xkeysib-...
MAIL_API_URL=https://api.brevo.com/v3/smtp/email
MAIL_API_TIMEOUT=10
MAIL_FROM=correo-verificado@tudominio.com
MAIL_FROM_NAME=ImpactApp
MAIL_MAX_ATTEMPTS=3
```

Brevo permite verificar un remitente sin dominio propio y su plan gratuito incluye
300 correos diarios. El remitente debe estar verificado en la cuenta del proveedor.

Errores clasificados sin exponer secretos ni destinatarios:

| Situación | Código saneado | ¿Reintenta? |
|---|---|---|
| 401/403 | `ProveedorAutenticacionFallida` | No |
| 429 | `ProveedorLimiteAlcanzado` | Sí |
| 5xx | `ProveedorNoDisponible` | Sí |
| Otros 4xx | `ProveedorRechazoSolicitud` | No |
| Timeout/sin conexión | `ConexionProveedorFallida` | Sí |
| Falta API key o remitente | `ConfiguracionProveedorIncompleta` | No |
| Proveedor desconocido | `ProveedorNoSoportado` | No |

Un 2xx se interpreta como **aceptado por el proveedor** y se guarda como
`estado="enviado"`. No se crean estados nuevos.

### SMTP (compatibilidad)

```dotenv
MAIL_ENABLED=1
MAIL_PROVIDER=smtp
MAIL_HOST=smtp.ejemplo.com
MAIL_PORT=587
MAIL_USE_TLS=1
MAIL_USE_SSL=0
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_FROM=no-reply@ejemplo.com
MAIL_TIMEOUT=10
MAIL_MAX_ATTEMPTS=3
```

- `MAIL_USE_SSL=1` usa `SMTP_SSL`; en ese caso `MAIL_USE_TLS` se ignora.
- `MAIL_MAX_ATTEMPTS` limita los reintentos por notificación.
- La contraseña y la API key nunca se escriben en logs ni en `ultimo_error`.
- `enviado` indica aceptación por el proveedor, no recepción en el buzón.

## Reintentos y worker

```bash
# Una pasada (cron, Render Cron Job, Fly Machines o docker compose exec)
docker compose exec -T backend python scripts/send_pending_emails.py --limit 50

# Worker externo opcional con intervalo
docker compose exec -T backend python scripts/send_pending_emails.py \
  --loop --interval 60 --limit 50
```

El script imprime `procesadas`, `enviadas` y `fallidas`. En modo una pasada
devuelve código de salida distinto de cero si alguna notificación falla. Para
validaciones controladas se puede omitir una fila concreta:

```bash
docker compose exec -T backend python scripts/send_pending_emails.py \
  --limit 50 --exclude-id 1
```

No se ejecuta automáticamente ni se añadió un servicio permanente al compose. Un
error individual no impide procesar las demás filas; los errores permanentes
agotan los intentos para evitar ciclos infinitos.

## Bandeja del usuario

```http
GET /api/notifications?limit=50&offset=0
Authorization: Bearer <token>
```

Devuelve `total`, `no_leidas` e `items` con `id_notificacion`, `tipo`, `asunto`,
`estado`, `leida`, `creado_en` y `enviado_en`. Solo incluye las notificaciones del
usuario autenticado. Las filas históricas sin `id_usuario` se asocian por correo.

```http
POST /api/notifications/<id>/read
POST /api/notifications/read-all
Authorization: Bearer <token>
```

`read` es idempotente y devuelve la notificación actualizada. `read-all` devuelve
`{"marcadas": n}`. Marcar una notificación ajena responde `404`.

La app Flutter incluye la pantalla `Notificaciones`, accesible desde la campana de
la barra superior del inicio. Distingue leídas y no leídas, permite actualizar con
pull-to-refresh y marcar todas como leídas.

## Consulta para soporte

```http
GET /api/support/notifications?estado=fallido&limit=50
Authorization: Bearer <token-de-soporte>
```

Devuelve `total` e `items` con metadatos de la notificación (clave, tipo,
destinatario, asunto, estado, intentos y error saneado). No expone el cuerpo del
correo ni credenciales. Requiere rol `soporte` activo.

## Migración

`ensure_notification_schema()` crea la tabla con `checkfirst=True` y agrega de forma
idempotente las columnas `id_usuario` y `leida_en`, además del índice
`(id_usuario, creado_en)`. No elimina ni reescribe registros existentes. El modelo
define:

- clave única `clave_evento`;
- `CHECK estado IN ('pendiente', 'enviado', 'fallido')`;
- índice por `(estado, creado_en)` y `(id_usuario, creado_en)`.

## Verificación

- `tests/test_notifications.py`: 44 casos aprobados en SQLite (4 omitidos) y
  45 aprobados en PostgreSQL aislado (2 omitidos) antes de añadir la última prueba
  de formato del remitente, que no depende del motor. Incluyen concurrencia con
  bloqueos de fila, errores del proveedor simulado, aislamiento entre usuarios y
  bandeja/lectura.
- Suite completa SQLite: 385 aprobadas, 38 omitidas.
- Flutter: 72 pruebas aprobadas; `flutter analyze` sin errores.
- El proveedor externo se simula en las pruebas automatizadas.

## Límites conocidos

- No se verificó un envío real contra Brevo ni contra un servidor SMTP; las pruebas
  usan un cliente simulado.
- El envío es síncrono después del commit y usa `MAIL_TIMEOUT`/`MAIL_API_TIMEOUT`;
  con el correo deshabilitado no agrega latencia.
- No hay gestión de rebotes, quejas ni plantillas editables por base de datos.
- Si el correo permanece deshabilitado, la cola conserva registros pendientes;
  debe revisarse o purgarse según la política operativa.
- La notificación pendiente ID 1 del diagnóstico no fue procesada, modificada ni
  eliminada durante esta implementación.
