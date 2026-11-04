# Wompi: reintentos y doble cobro (Incremento 1)

Fecha: 22/10/2026. Estado: implementado y probado en SQLite aislado y PostgreSQL
desechable. No se activaron pagos reales ni producción.

## Motivo

Wompi permite que un pagador reintente un pago fallido. Según la documentación
oficial de [Reintento de pagos](https://docs.wompi.co/docs/colombia/reintento-de-pago/),
el reintento genera una segunda transacción con la misma `reference`, pero con
otro `id` y, posiblemente, otro medio de pago. Una transacción puede quedar
`DECLINED` y otra `APPROVED` con la misma referencia.

El flujo anterior asociaba la donación al primer `wompi_transaction_id`, incluso
si estaba declinado, y rechazaba cualquier identificador distinto. Eso podía
impedir que un pago aprobado en el reintento se acreditara.

## Modelo `PAGO_INTENTO`

Cada transacción observada de Wompi se conserva como un intento independiente:

| Campo | Contenido |
|---|---|
| `id_intento` | Identificador interno |
| `id_donacion` | FK a `DONACION`; una donación puede tener varios intentos |
| `wompi_transaction_id` | Identificador de Wompi, UNIQUE |
| `referencia` | Referencia de pago, conservada para auditoría |
| `estado_observado` | Estado recibido en el evento, si existe |
| `estado_autoritativo` | Estado devuelto por `GET /v1/transactions/{id}` |
| `estado_local` | `pendiente`, `aprobada`, `rechazada`, `anulada` o `error` |
| `resultado` | `pendiente`, `acreditado`, `duplicado`, `ignorado` o `anulado` |
| `monto_en_centavos` | Importe autoritativo en centavos COP |
| `moneda` | Moneda autoritativa |
| `metodo_pago` | Medio de pago, cuando Wompi lo informa |
| `origen` | `webhook` o `status` |
| `creado_en`, `actualizado_en` | Fechas internas de auditoría |

`resultado` describe el efecto sobre la acreditación: `ignorado` significa que
el intento no acreditó la donación (rechazo, error o evento sin efecto), no que
el intento se haya descartado; el intento y sus estados se conservan.

Restricciones:

- `UNIQUE(wompi_transaction_id)`.
- FK `id_donacion` a `DONACION`.
- Índices por donación y referencia.
- `CHECK` sobre estados y resultados.

La tabla se crea con `db.create_all()` y con
`ensure_payment_attempt_schema()`; esta última usa `checkfirst=True`, por lo que
puede ejecutarse repetidamente. No se elimina ni se recrea `DONACION`.

`DONACION.wompi_transaction_id` conserva un significado distinto: es el
identificador de la transacción que **acreditó** la donación. Solo se asigna al
aprobar. Los intentos rechazados, pendientes o duplicados viven en `PAGO_INTENTO`.

## Flujo de un intento

1. Llega un evento o una consulta de estado con una transacción.
2. Se conservan las validaciones existentes: firma, ambiente, consulta
   autoritativa, referencia, importe, moneda, tipo de donación y checksum local.
3. Se bloquea primero la campaña y después la donación. El orden es siempre
   `CAMPAÑA -> DONACION -> PAGO_INTENTO` para reducir interbloqueos.
4. Se busca el intento por `wompi_transaction_id`.
   - Si ya existe y pertenece a otra donación, se rechaza.
   - Si ya existe y sus datos no coinciden, se rechaza.
   - Si no existe, se inserta. La restricción UNIQUE resuelve carreras.
5. Se aplica la transición del intento:
   - `pendiente -> cualquiera`.
   - Mismo estado: idempotente.
   - `aprobada -> anulada` solo para `CARD`.
   - Cualquier otro cambio desde un estado terminal de la misma transacción se
     ignora y se registra el evento como `ignorado`.
6. Se aplica el efecto sobre la donación:
   - Un intento aprobado acredita la donación solo si no hay otro intento
     aprobado que ya la haya acreditado.
   - Un intento rechazado o con error puede marcar la donación como rechazada o
     con error si aún no estaba aprobada.
   - Un intento aprobado posterior a un rechazo o error puede acreditar la
     donación, porque es una transacción distinta.
   - Una donación anulada no se reabre: un nuevo cobro aprobado se registra como
     posible doble cobro.
7. Se actualiza el avance de campaña solo cuando cambia la acreditación.
8. Se registra auditoría, se adjunta el `PAGO_EVENTO` y se confirma todo en un
   único commit.

## Rechazado y luego aprobado

Ejemplo:

1. `RETRY-1` con `DECLINED`: se crea el intento `rechazada`, la donación queda
   `rechazada`, no se suma al total.
2. `RETRY-2` con `APPROVED` y la misma referencia: se crea otro intento, se
   valida importe y moneda, no existe otro intento aprobado y la donación se
   acredita una sola vez. El total de campaña se recalcula una vez.

La donación guarda `RETRY-2`; `RETRY-1` permanece en `PAGO_INTENTO`.

## Doble cobro

Si llega un segundo `APPROVED` distinto para una donación ya aprobada:

- no se cambia `DONACION.wompi_transaction_id`;
- no se vuelve a sumar el importe;
- el intento se guarda con `resultado="duplicado"`;
- se registra `AUDITORIA` con acción `PAGO_DUPLICADO`;
- el `PAGO_EVENTO` se registra como `ignorado`;
- el webhook responde `200` para que Wompi no reintente indefinidamente;
- el caso queda para conciliación y eventual reembolso manual.

## Concurrencia

Dos eventos de la misma donación se serializan con el bloqueo de la campaña y de
la donación. El primero acredita; el segundo, al obtener el bloqueo, observa la
donación ya aprobada y registra el intento como duplicado. No hay doble suma.

Dos eventos simultáneos con el mismo `wompi_transaction_id` compiten por la
restricción UNIQUE. Uno inserta; el otro recibe un conflicto, revierte su
transacción completa y responde `503`, por lo que Wompi puede reintentar. En el
reintento encuentra el intento existente y aplica la transición idempotente. No
se deja un intento parcial.

## Datos históricos

No se ejecutó ningún backfill. Las filas existentes de `DONACION` no se borraron
ni modificaron.

- Donaciones históricas aprobadas con `wompi_transaction_id`: siguen contando. Si
  se recibe otro pago aprobado, se detecta como doble cobro. La tabla de intentos
  se completa de forma perezosa cuando vuelve a observarse la misma transacción.
- Donaciones históricas rechazadas o con error que tengan un
  `wompi_transaction_id` distinto del nuevo intento: se bloquean con
  `conciliacion_historica_pendiente` (HTTP 409). No se inventa un estado ni se
  acredita sin evidencia autoritativa. Requieren conciliación manual consultando
  la transacción histórica en Wompi.
- Donaciones históricas sin `wompi_transaction_id`: no requieren backfill; el
  primer evento o consulta crea su intento con evidencia autoritativa.

Un backfill futuro debe consultar cada transacción histórica con la llave privada,
guardar la respuesta autoritativa y ejecutarse con modo de solo lectura por
defecto. No debe marcar aprobaciones a partir del estado local.

## Pruebas

Archivo nuevo: `impactapp_backend/tests/test_wompi_retries.py`.

Cubre:

- rechazado y luego aprobado con otra transacción;
- aprobado y evento rechazado antiguo;
- mismo identificador repetido;
- dos aprobaciones secuenciales con doble cobro;
- dos aprobaciones concurrentes en PostgreSQL;
- importe incorrecto en el reintento;
- fallo de commit sin intento parcial;
- conciliación por referencia de un reintento sin webhook;
- migración idempotente y restricción UNIQUE;
- serialización sin secretos.

Resultados reales:

```text
tests/test_wompi_retries.py
12 passed, 1 skipped

Suite completa tests/
270 passed, 4 skipped

PostgreSQL desechable (concurrencia)
4 passed
```

Las omisiones de SQLite corresponden a pruebas que requieren bloqueos de fila
PostgreSQL. Las pruebas PostgreSQL se ejecutaron en un contenedor temporal con
`tmpfs`, sin usar la base de desarrollo, y el contenedor se eliminó al terminar.

## Códigos de la consulta de estado

La respuesta de `GET /api/donations/<id>/status` conserva los campos anteriores y
añade `code` para que el cliente distinga el resultado sin interpretar el texto.

| Situación | HTTP | `code` | `conciliacion` |
|---|---:|---|---|
| Pago verificado y aplicado | 200 | `conciliacion_verificada` | `verificada` |
| Evento fuera de orden o terminal ignorado | 200 | `estado_desactualizado` | `estado_desactualizado` |
| Segundo cobro aprobado | 200 | `doble_cobro` | `doble_cobro` |
| No existe transacción para la referencia | 200 | `transaccion_no_encontrada` | `sin_identificador` |
| El `transaction_id` indicado no existe | 404 | `transaccion_no_encontrada` | — |
| Proveedor temporalmente no disponible | 503 | `proveedor_no_disponible` | — |
| Respuesta inválida del proveedor | 502 | `respuesta_proveedor_invalida` | — |
| Configuración Wompi inválida | 503 | `wompi_no_configurado` | — |
| Credenciales o consulta Wompi no configuradas | 503 | `consulta_no_configurada` | — |
| Identificador de transacción inválido en el proveedor | 503 | `transaccion_invalida` | — |
| Conflicto de referencia, monto o moneda | 409 | `conciliacion_conflicto` | — |
| Conflicto histórico | 409 | `conciliacion_historica_pendiente` | — |
| Donación aprobada sin transacción | 409 | `conciliacion_aprobacion_sin_transaccion` | — |
| Error de persistencia | 503 | `persistencia_no_disponible` | — |

Los mensajes `error` son genéricos y no incluyen identificadores, montos ajenos
ni detalles técnicos. Los códigos internos de conciliación se registran solo en
los logs del backend. Los campos `estado_pago`, `conciliacion` y `ambiente`
anteriores se mantienen para compatibilidad con Flutter.

## Ajustes del 27/10/2026

- Un `VOIDED` sobre una transacción que estaba `PENDING` deja la donación
  `anulada` sin `fecha_pago`; un `APPROVED` posterior con otra transacción sí
  puede acreditarla. Antes se clasificaba como doble cobro y el dinero quedaba
  sin reconocer.
- Un replay idempotente del checkout de una donación ya aprobada o anulada
  devuelve el estado, pero **no** reemite una `checkout_url` pagable.
- Se añadió el barrido `scripts/reconcile_wompi.py` y la prueba
  `tests/test_wompi_reconcile.py` para conciliar pendientes sin webhook, con
  corte ante fallos temporales del proveedor.
- Se cubrió el flujo asíncrono `PENDING -> APPROVED` con
  `payment_method_type="BANCOLOMBIA_TRANSFER"` como evento genérico; esto no
  habilita el método en el comercio ni implementa su tokenización.

## Límites de este incremento

- No se implementaron correos, recibos, cola de notificaciones, transparencia ni
  activación de producción.
- No se modificó Flutter.
- No se hizo backfill ni se tocó la base de producción.
- Un doble cobro se detecta y se registra; el reembolso sigue siendo un
  procedimiento manual de soporte.
- La dispersión a organizadores y los requisitos de producción se documentan en
  [`wompi_produccion.md`](wompi_produccion.md).
