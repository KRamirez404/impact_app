# Wompi en producción: requisitos y activación

Estado: **producción no habilitada**. La integración permanece en Sandbox y
`WOMPI_ALLOW_PRODUCTION=0`. Este documento no contiene credenciales reales ni
autoriza cobros. Su objetivo es enumerar lo que falta fuera del código y el
procedimiento exacto para activar producción después de una validación humana.

## 1. Alcance implementado

El backend ya implementa:

- creación de una donación económica `pendiente` y de una referencia interna
  única antes de abrir Wompi Checkout Web;
- firma de integridad con el secreto de integridad;
- webhook `transaction.updated` con validación del checksum enviado por Wompi;
- validación del ambiente del evento (`test`/`prod`);
- consulta autoritativa `GET /v1/transactions/{id}` con llave privada;
- comparación de identificador, referencia, importe y moneda contra la respuesta
  autoritativa y contra la donación local;
- registro de cada transacción en `PAGO_INTENTO` y de cada evento válido en
  `PAGO_EVENTO`, con huellas únicas;
- transiciones idempotentes para `PENDING`, `APPROVED`, `DECLINED`, `VOIDED` y
  `ERROR`;
- conciliación por referencia al consultar `GET /api/donations/<id>/status`;
- barrido server-side de donaciones pendientes para ejecutar desde cron.

La redirección del navegador **nunca** acredita un pago. El único camino de
acreditación es la consulta autoritativa a Wompi y la posterior validación local.

No forma parte de este alcance: dispersión automática a organizadores,
devoluciones/reembolsos automáticos, creación directa de transacciones por API,
tokenización de tarjetas, conciliación contable de liquidaciones Wompi y
activación de producción.

## 2. Requisitos externos antes de producción

| Requisito | Qué debe existir | Evidencia esperada |
|---|---|---|
| Cuenta de comercio Wompi | Comercio aprobado para producción, con datos legales y representante verificados | Correo o acta de aprobación de Wompi |
| Cuenta de desembolso | Cuenta bancaria del comercio verificada por Wompi para recibir la liquidación | Confirmación en el Dashboard de Comercios |
| Credenciales productivas | `pub_prod_*`, `prv_prod_*`, `prod_integrity_*`, `prod_events_*` | Gestor de secretos, nunca el repositorio |
| Dominio y HTTPS | Dominio público con DNS, certificado TLS válido y redirección 80→443 | `curl` y verificación de certificado |
| URL de eventos | `https://<dominio>/api/webhooks/wompi` registrada en el ambiente productivo de Wompi | Captura del Dashboard sin secretos |
| Métodos de pago | Lista de métodos autorizados para el comercio | Configuración del Dashboard |
| Contacto Wompi | Canal para rotación de llaves, incidentes y conciliación | Registro operativo |
| Legal y privacidad | Términos, autorización de tratamiento de datos y comprobantes | Documentos aprobados |
| Infraestructura | PostgreSQL con respaldo verificable, logs, monitoreo y cron | Runbook y prueba de restauración |
| Autorización humana | Responsable, fecha y alcance del cambio a producción | Ticket o acta |

### Cuenta de desembolso

Wompi liquida los pagos en la cuenta bancaria verificada del comercio. ImpactaApp
no dispersa automáticamente esos fondos a los organizadores. Si se decide usar
“Pagos a terceros” de Wompi, se requiere una activación y un contrato distintos,
cuentas de terceros verificadas y un módulo que hoy no está implementado. No se
debe prometer dispersión automática con la integración actual.

### Métodos de pago y Bancolombia

La aplicación usa Wompi Checkout Web y no envía un parámetro que fuerce un método
de pago. El comercio ve únicamente los métodos que Wompi tenga autorizados en su
cuenta.

El método `BANCOLOMBIA_TRANSFER` de Wompi (botón de transferencia Bancolombia)
**no está implementado de forma específica** en este repositorio:

- no se crean transacciones directas por `POST /v1/transactions`;
- no se construye el objeto `payment_method` de `BANCOLOMBIA_TRANSFER`;
- no se procesa `async_payment_url` ni la tokenización de Bancolombia;
- el evento `bancolombia_transfer_token.updated` se ignora porque no participa en
  el flujo de Checkout Web.

Sin embargo, si el comercio habilita ese método en Checkout Web, Wompi genera una
transacción normal y notifica `transaction.updated`. El backend procesa sus
estados `PENDING`, `APPROVED`, `DECLINED` y `ERROR` de forma genérica, sin asumir
que el método esté habilitado. `VOIDED` se rechaza para métodos distintos de
tarjeta porque Wompi documenta esa anulación solo para tarjetas. Habilitar
Bancolombia requiere autorización del comercio, verificación en Sandbox y pruebas
de aceptación; no se debe activar por código ni por suposición.

## 3. Variables de producción

Usar placeholders y un gestor de secretos. No copiar valores reales a Git, logs,
capturas ni documentación.

```dotenv
WOMPI_ENV=production
WOMPI_ALLOW_PRODUCTION=0          # cambiar a 1 solo en el paso autorizado
WOMPI_PUBLIC_KEY=pub_prod_...
WOMPI_PRIVATE_KEY=prv_prod_...
WOMPI_INTEGRITY_SECRET=prod_integrity_...
WOMPI_EVENTS_SECRET=prod_events_...
WOMPI_CHECKOUT_URL=https://checkout.wompi.co/p/
WOMPI_API_URL=https://production.wompi.co/v1
WOMPI_MIN_AMOUNT=1000
DONATION_REDIRECT_URL=https://transaction-redirect.wompi.co/check
JWT_SECRET_KEY=<secreto-largo-y-estable>
```

Reglas:

- `WOMPI_ALLOW_PRODUCTION=0` bloquea el arranque del checkout/webhook productivo
  aunque las llaves sean productivas.
- Las cuatro llaves deben pertenecer al mismo ambiente. El backend rechaza
  prefijos mezclados y URLs distintas de las oficiales.
- `WOMPI_CURRENCY` debe ser `COP`.
- `JWT_SECRET_KEY` debe ser estable. Se usa también para el checksum de
  integridad de la donación; rotarlo invalida la verificación de donaciones
  existentes y exige un procedimiento de migración/reparación.
- Mantener `TRANSFERENCIAS_ENABLED=0` y `FINANCIAL_ASSIGNMENTS_ENABLED=0` salvo
  una autorización separada para transferencias bancarias.
- `ALLOWED_ORIGINS` debe incluir únicamente el dominio público real.

## 4. Comportamiento de estados

| Estado Wompi | Estado local | Efecto |
|---|---|---|
| `PENDING` | `pendiente` | Registra el intento; no suma a la meta |
| `APPROVED` | `aprobada` | Acredita una sola vez, fija `wompi_transaction_id` y recalcula la campaña |
| `DECLINED` | `rechazada` | No suma; permite un reintento con otra transacción |
| `VOIDED` | `anulada` | Solo para tarjeta; si había acreditado, recalcula la meta y conserva historial |
| `ERROR` | `error` | No suma; permite un reintento con otra transacción |
| Segundo `APPROVED` | sin cambio | Registra `PAGO_INTENTO.resultado="duplicado"` y `AUDITORIA` `PAGO_DUPLICADO`; no suma dos veces |

Un evento duplicado responde `200` y no repite efectos. Una transición terminal
no se reabre. Un `VOIDED` de una transacción que nunca acreditó no bloquea un
reintento aprobado posterior de la misma referencia.

## 5. Conciliación automática

Hay tres mecanismos complementarios:

1. **Webhook**: camino principal; Wompi reintenta hasta tres veces durante 24
   horas si no recibe `200`.
2. **Consulta de estado**: `GET /api/donations/<id>/status` consulta Wompi por el
   identificador guardado o por referencia y aplica el mismo filtro autoritativo.
3. **Barrido server-side**: revisa donaciones económicas `pendiente` con
   referencia, dentro de una ventana, y consulta Wompi por referencia.

Ejecución manual:

```bash
make wompi-reconcile
# alternativa:
docker compose exec backend python scripts/reconcile_wompi.py \
  --limit 50 --min-age-minutes 10 --max-age-hours 72
```

Ejemplo de cron cada cinco minutos:

```cron
*/5 * * * * cd /ruta/a/impact_app && docker compose exec -T backend \
  python scripts/reconcile_wompi.py >> /var/log/impactapp-wompi.log 2>&1
```

El barrido:

- solo revisa donaciones económicas pendientes con referencia;
- omite las creadas hace menos de `--min-age-minutes` para no competir con el
  checkout en curso;
- ignora las más antiguas que `--max-age-hours`;
- se detiene ante errores de configuración o indisponibilidad del proveedor y
  devuelve código de salida distinto de cero;
- no acredita por redirección ni por estado local; usa la consulta autoritativa.

Monitorear al menos: errores del barrido, eventos con firma inválida, eventos
`sin_donacion`, `PAGO_DUPLICADO`, donaciones pendientes acumuladas y latencia de
la API de Wompi. No registrar payloads completos ni secretos.

## 6. Procedimiento exacto de activación

1. **Autorización humana.** Registrar responsable, fecha, alcance y ventana de
   cambio. Sin esta autorización no se cambia ninguna bandera.
2. **Respaldo.** Tomar un respaldo verificable de PostgreSQL y probar la
   restauración en un entorno aislado.
3. **Preflight de esquema.** Confirmar que existen las columnas e índices de
   Wompi y las tablas `PAGO_INTENTO`/`PAGO_EVENTO`. Verificar que no haya
   `wompi_transaction_id` duplicados. No ejecutar migraciones de transferencias.
4. **Secretos.** Cargar las cuatro llaves productivas y `JWT_SECRET_KEY` estable
   en el gestor de secretos del servidor. No usar `.env` versionado.
5. **Dashboard.** Registrar en Wompi producción la URL de eventos
   `https://<dominio>/api/webhooks/wompi`. No reutilizar la URL de Sandbox.
6. **Despliegue.** Mantener `WOMPI_ALLOW_PRODUCTION=0` durante el despliegue;
   verificar TLS, salud y conectividad. Después, en la ventana autorizada,
   cambiar a `WOMPI_ALLOW_PRODUCTION=1` y reiniciar el backend.
7. **Diagnóstico.** Ejecutar `make wompi-check`. Debe reportar
   `ambiente=production` y `configurado=si`. Revisar que no imprima secretos.
8. **Prueba real controlada.** Con un importe mínimo autorizado, completar un pago
   aprobado y uno declinado. Verificar `DONACION`, `PAGO_INTENTO`, `PAGO_EVENTO`,
   `AUDITORIA` y el avance de la campaña. Confirmar que el retorno del navegador
   por sí solo no acredita.
9. **Pruebas de aceptación.** Completar la lista de la sección 7 y conservar
   evidencia sin datos sensibles.
10. **Operación.** Activar el cron de conciliación y monitorear al menos 24 horas
    antes de declarar la activación terminada.

### Reversión

Si falla la activación:

1. Volver a `WOMPI_ALLOW_PRODUCTION=0` y reiniciar; el checkout y el webhook
   productivo quedan bloqueados.
2. Retirar o rotar las llaves productivas si hay sospecha de exposición.
3. No borrar donaciones, intentos, eventos ni auditoría. Reconciliar manualmente
   los pagos pendientes con Wompi.
4. Restaurar el respaldo solo si hay corrupción de datos y con autorización.

## 7. Pruebas de aceptación

Automatizadas, sin servicios externos:

```bash
cd impactapp_backend
.venv/bin/python -m pytest tests/test_wompi.py tests/test_wompi_extra.py \
  tests/test_wompi_config.py tests/test_wompi_integrity.py \
  tests/test_wompi_retries.py tests/test_wompi_status_errors.py \
  tests/test_pago_evento.py tests/test_wompi_reconcile.py -q
```

Cubren firma, ambiente, importes, moneda, referencias, duplicados, estados,
reintentos, doble cobro, atomicidad, errores temporales y barrido. No acreditan
una transacción real.

Pruebas reales mínimas antes de declarar producción:

- pago aprobado con tarjeta de prueba productiva autorizada;
- pago declinado y posterior reintento aprobado;
- redirección del navegador sin webhook: el estado debe seguir pendiente hasta la
  consulta autoritativa o el barrido;
- evento duplicado: no duplica importe, avance ni auditoría;
- evento con firma inválida: `401`, sin cambios;
- evento con importe, moneda o referencia alterados: rechazo sin acreditar;
- anulación de una transacción aprobada: descuenta del avance una sola vez;
- barrido de una donación pendiente sin webhook: acredita una sola vez;
- verificación de logs sin secretos ni payloads completos;
- verificación de respaldo y restauración.

Si el comercio habilita Bancolombia, repetir el pago aprobado, declinado y el
reintento con ese método. No se debe considerar habilitado por una prueba en
Sandbox de otro comercio.

## 8. Bloqueos pendientes

- Aprobación de la cuenta de comercio y de la cuenta de desembolso.
- Credenciales productivas y URL HTTPS pública.
- Autorización humana del cambio y ventana de mantenimiento.
- Definición de dispersión a organizadores (manual o Pagos a terceros).
- Habilitación y prueba real de cada método de pago, incluido Bancolombia si se
  autoriza.
- Rotación y custodia de `JWT_SECRET_KEY` y de los cuatro secretos Wompi.
- Pruebas de aceptación con dinero real y evidencia operativa.

## 9. Referencias consultadas

- Eventos: https://docs.wompi.co/docs/colombia/eventos/
- Transacciones y estados: https://docs.wompi.co/docs/colombia/transacciones/
- Seguimiento de transacciones: https://docs.wompi.co/docs/colombia/seguimiento-de-transacciones/
- Reintentos: https://docs.wompi.co/docs/colombia/reintento-de-pago/
- Métodos de pago: https://docs.wompi.co/docs/colombia/metodos-de-pago/
- Checkout Web: https://docs.wompi.co/docs/colombia/widget-checkout-web/
