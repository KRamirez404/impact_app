# Wompi: integridad financiera, incremento 1

Fecha de implementación y pruebas locales: 16/10/2026.

## Contrato contrastado

Documentación oficial consultada durante la implementación:

- https://docs.wompi.co/docs/colombia/eventos/
- https://docs.wompi.co/docs/colombia/transacciones/
- https://docs.wompi.co/docs/colombia/widget-checkout-web/

El checksum es SHA-256 de los valores indicados por `signature.properties`, en
su orden original, seguido del timestamp entero y del secreto de eventos. La
comparación utiliza `hmac.compare_digest`. Se admite el checksum del JSON o del
header HTTP real `X-Event-Checksum`. No se fija una lista de propiedades.

La consulta oficial es `GET /v1/transactions/{id}`, desde backend con llave
privada Bearer. La referencia y la moneda no necesariamente están entre las
propiedades firmadas: no se consideran auténticas por el solo checksum.

## Conciliación y errores

Cada webhook financiero válido consulta primero la API de Wompi. Se comparan
identificador, referencia, monto y moneda entre evento y respuesta autoritativa;
después se comprueban referencia, monto, tipo, checksum local y asociación externa
de la donación. Solo se admite COP. Los identificadores externos no pueden
compartirse entre donaciones ni sustituirse dentro de una donación.

Si el estado del evento difiere del actual de la API, se utiliza el de la API:
el evento puede ser antiguo y el timestamp firmado no demuestra que su estado
siga vigente. No se impone una caducidad arbitraria que descarte reintentos
legítimos de Wompi. Una respuesta de API también puede haberse obtenido antes de
otra operación concurrente: las transiciones locales impiden regresiones.

- JSON inválido: 400; firma o ambiente inválidos: 401.
- Inconsistencias financieras: 409, sin aplicación parcial.
- Consulta indisponible, timeout o fallo SQL: 503, con rollback y posibilidad de
  reintento. No se devuelve un falso pago pendiente como sustituto de un error.
- Tipos de evento ajenos y referencias autoritativas sin donación local: 200,
  sin cambios financieros.
- Los logs contienen códigos de causa, sin payloads, credenciales ni datos
  bancarios. Wompi documenta tres reintentos de notificación en 24 horas ante una
  respuesta distinta de 200; no se ha añadido un planificador local.

Para crear checkouts se requieren las cuatro configuraciones: llave pública,
llave privada, secreto de integridad y secreto de eventos. Se conserva Sandbox
por defecto y no se activan pagos de producción.

## Montos

El JSON del checkout se interpreta con decimales exactos, y los centavos se
convierten sin redondeo binario. Se rechazan valores no finitos, booleanos,
estructuras, valores no positivos y fracciones inferiores al centavo.

Se conserva `WOMPI_MIN_AMOUNT` (1000 COP por defecto). El máximo técnico es
9.999.999.999,99 COP, derivado de `Numeric(12, 2)`, no un nuevo límite comercial
atribuido a Wompi. Pueden existir límites adicionales del comercio o medio de
pago. La API conserva el formato numérico anterior de `monto_estimado` al
serializar; ni firmas ni cálculos financieros utilizan esa conversión de salida.

La representación canónica del checksum usa Decimal con dos decimales y mantiene
su formato anterior para importes válidos de la columna. No se modifican el
algoritmo ni los campos firmados históricos. En el flujo Wompi se exige checksum
presente y válido; donaciones históricas sin él necesitan conciliación explícita,
no una aprobación automática. `JWT_SECRET_KEY` debe permanecer estable.

## Transiciones

| Estado local | Estado autoritativo permitido | Efecto |
|---|---|---|
| pendiente | pendiente, aprobada, rechazada, error, anulada | Asociación y estado; aprobación/anulación actualizan avance. |
| aprobada | aprobada | Reintento idempotente; permite reparar avance/auditoría históricos incompletos. |
| aprobada | anulada, únicamente CARD | Resta del cálculo mediante recálculo; conserva fecha de aprobación y auditoría previa. |
| rechazada, error, anulada | el mismo estado | Reintento idempotente. |
| cualquier terminal | otro estado no autorizado | Se ignora la transición, se registra advertencia y no se reabre el pago. |

VOIDED solo se admite para CARD, según el contrato consultado. No se ejecuta el
endpoint de anulación ni se implementan reembolsos. Una discrepancia terminal
persistente requiere revisión operativa: no se cambia por intuición.

## Atomicidad, idempotencia y concurrencia

Se bloquea primero la campaña y después la donación con `SELECT FOR UPDATE` en
PostgreSQL. Serializar por campaña evita perder el total al confirmar dos
donaciones distintas simultáneamente. El identificador externo tiene un índice
único como última defensa entre campañas diferentes.

La donación, su avance y la auditoría se confirman en un único commit. Los helpers
existentes de avance y auditoría aceptan `confirmar=False`; el valor predeterminado
mantiene el comportamiento de sus otros consumidores. Un fallo anterior al
commit revierte la operación completa. Un reintento del mismo estado comprueba
la auditoría correspondiente y recalcula aprobaciones, en vez de salir antes de
reparar una operación histórica incompleta.

No se añade tabla de eventos: la asociación única, las transiciones monotónicas,
los bloqueos y la auditoría transaccional bastan para deduplicar los efectos
financieros actuales. No se pretende conservar cada notificación recibida ni
certificar la inmutabilidad general de AUDITORIA.

`POST /api/donations/checkout` admite opcionalmente `Idempotency-Key` (1–128
caracteres). Se persiste su hash asociado al donante. Repetir clave y datos devuelve
la misma donación con 200; reutilizar la clave con datos distintos devuelve 409.
El primer checkout devuelve 201. La restricción única también protege carreras;
un conflicto SQL devuelve 503 y el cliente puede reintentar con la misma clave.
Sin esa cabecera se conserva la semántica de crear un nuevo intento por POST.
Flutter no se modifica y todavía no envía esta cabecera.

## Recuperación sin primer webhook

Wompi documenta que la URL de retorno incluye `?id=<transaction_id>`. No se ha
inventado una búsqueda por referencia.

El propietario o soporte puede transmitir ese identificador como pista a:

```
GET /api/donations/<id_donacion>/status?transaction_id=<id_wompi>
Authorization: Bearer <jwt>
```

El identificador no confirma nada por sí mismo: el backend consulta Wompi y exige
todas las coincidencias antes de asociarlo. No acepta un identificador distinto
del ya asociado. La respuesta añade `conciliacion`: `verificada`,
`estado_desactualizado` o `sin_identificador`. Los errores externos retornan 503.
Las consultas posteriores usan el identificador guardado y también permiten
observar una anulación de tarjeta.

Si no llega el webhook y tampoco se dispone del identificador del retorno, no hay
recuperación automática por referencia. La captura del retorno en Flutter/web y
una conciliación operativa más amplia quedan pendientes. Los simuladores con IDs
fabricados no pueden aprobar pagos mediante la API autoritativa real; los tests
usan un proveedor simulado explícito. No se ejecutó el script simulador.

## Migración compatible con el proyecto

Se amplía `ensure_donation_schema()`; no se introduce Alembic ni una nueva tabla:

- Columna nullable `clave_checkout VARCHAR(64)`.
- Índice único `uq_donacion_wompi_transaction_id`.
- Índice único `uq_donacion_clave_checkout`.

Antes de crear cada índice se buscan duplicados no nulos. Si existen se cancela
la inicialización con un error explícito, sin deduplicar ni eliminar registros.
Se requiere conciliarlos manualmente antes del despliegue. Los valores NULL
históricos siguen admitidos. La migración es idempotente y se probó el rechazo
de duplicados y la conservación de registros con un esquema SQLite histórico.
La inicialización e índices se ejecutaron también en PostgreSQL de pruebas.

No se inspeccionaron ni migraron bases reales. Al desplegar, la inicialización
habitual de la aplicación ejecutará este preflight y la migración; debe hacerse
con la coordinación normal de cambios de esquema y copia de seguridad.

## Pruebas realmente ejecutadas

Entorno: Python 3.12 de la imagen backend existente; código montado en solo lectura,
archivos temporales internos al contenedor, JWT exclusivo de pruebas y caché pytest
desactivada. La suite rechaza URLs explícitas SQLite fuera del directorio temporal
y nombres PostgreSQL que no terminen en `_test` antes de importar la aplicación.

1. Wompi existente, SQLite aislado y contenedor sin red:
   `pytest tests/test_wompi.py tests/test_wompi_extra.py -q -p no:cacheprovider --disable-warnings`.
   Resultado inicial: **38 passed**, 404 warnings, 45,44 s.
2. Verificación final de pruebas nuevas en SQLite aislado, sin red:
   `pytest tests/test_wompi_integrity.py -q -p no:cacheprovider --disable-warnings`.
   **76 passed, 3 skipped**, 858 warnings, 124,30 s. Las tres omitidas requieren
   bloqueos de fila PostgreSQL.
3. Suite backend completa final en PostgreSQL 16 desechable:
   `pytest tests -q -p no:cacheprovider --disable-warnings`.
   **219 passed**, 1998 warnings, 228,52 s, sin omisiones. Incluye carreras de
   webhook duplicado, dos donaciones de la misma campaña y checkout con igual clave.
4. `python -m compileall -q app.py config.py models routes services tests`, con
   pycache en `/tmp` del contenedor: correcto.
5. `git diff --check`: correcto. `graphify update .` completó la actualización
   estructural sin LLM: 2389 nodos, 3659 relaciones y 162 comunidades. Se verificó
   después `_apply_transaction` con `graphify explain`. La actualización AST no
   incorpora semánticamente este nuevo documento. Graphify mantiene avisos de
   extracción preexistentes del encabezado Linux y archivos sin símbolos.

La base `impactapp_wompi_test` se creó en un contenedor independiente, con datos
en tmpfs, red Docker interna exclusiva y sin puertos publicados. No se usaron
los contenedores ni las bases de la aplicación. Las consultas Wompi fueron
simuladas, incluidos errores HTTP, timeout y respuestas inválidas. Las pruebas
inyectan fallos de donación, campaña, auditoría y commit y verifican rollback y
recuperación por reintento. Los warnings corresponden a usos existentes de APIs
de SQLAlchemy y fechas obsoletas, no a fallos de las pruebas.
El contenedor PostgreSQL y su red exclusivos se eliminaron al finalizar.

Estos resultados no acreditan transacciones reales ni Wompi Sandbox de extremo
a extremo. Quedan pendientes credenciales válidas, webhook público HTTPS,
integración del retorno, y pruebas autorizadas con el proveedor. Transferencias,
comprobantes, correos, Flutter y APK están fuera de este incremento.
