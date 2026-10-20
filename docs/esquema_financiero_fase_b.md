# Fase B — Esquema y activación de asignaciones financieras

## Estrategia previa al registro de modelos

La aplicación utiliza `create_all()` y ajustes ad-hoc al arrancar; no hay Alembic.
Este incremento incorpora solo `ASIGNACION_FINANCIERA` y
`EVENTO_ASIGNACION_FINANCIERA`, sin modificar tablas existentes, sembrar permisos ni
crear transferencias. Las FK apuntan a USUARIO y CAMPAÑA; eventos conservan las
concesiones/revocaciones y las claves idempotentes. No se borra historial al
reactivar una asignación. La unicidad de usuario/campaña/capacidad serializa su ciclo.

Los modelos y rutas se importan condicionalmente al registrar blueprints, solo con
`FINANCIAL_ASSIGNMENTS_ENABLED=1`. Valor por defecto: desactivado. Un proceso que
importe manualmente estos modelos registra sus tablas en los metadatos SQLAlchemy;
no debe utilizarse ese proceso para inicializar bases reales sin autorización.

Activar el flag y arrancar la aplicación permite al `create_all()` existente crear
las tablas nuevas. Eso constituye una operación de esquema que requiere respaldo,
revisión del destino de DATABASE_URL y autorización específica de despliegue. No se
ejecuta aquí. Repetir `create_all()` no modifica las tablas existentes: futuras
evoluciones de estas tablas requerirán inspección y ajustes aditivos explícitos.

El esquema utiliza INTEGER, VARCHAR, DATETIME, FK, UNIQUE y CHECK compatibles con
SQLite/PostgreSQL. SQLite debe habilitar FK por conexión; sus pruebas no acreditan
los bloqueos de fila de PostgreSQL. La administración de asignaciones se limita a
PostgreSQL fuera de pruebas aisladas hasta verificar concurrencia en ese motor.

## Designación administrativa

`FINANCIAL_ADMIN_USER_ID` debe ser el ID positivo de una persona ya existente,
activa y con rol soporte, designada por el responsable del proyecto mediante
configuración de despliegue. Vacío, inválido o usuario bloqueado: acceso denegado.
No hay valor por defecto, creación de usuario, inferencia del seed, autoconcesión
ni endpoint para cambiar la designación. Configurar el ID no sustituye la
acreditación humana de esa persona. El flag por sí solo no concede permisos.

No se incorpora un adaptador bancario ni una opción de activar contabilización.
Las capacidades `revision` y `contabilizacion` son permisos preparatorios: la
segunda no significa que exista una operación financiera disponible.

## Pruebas

Las pruebas nuevas residen en `impactapp_backend/pruebas_aisladas/`, fuera del árbol
de fixtures heredados. Construyen Flask directamente, utilizan SQLite en memoria,
habilitan FK y crean únicamente datos sintéticos. No importan `app`, no ejecutan
seed, no contactan servicios externos y no utilizan DATABASE_URL del entorno.
Las pruebas PostgreSQL y la regresión heredada requieren el entorno desechable
descrito en `pruebas_transferencias.md`; no se ejecutan contra servicios existentes.

## API implementada, desactivada por defecto

Todas las rutas exigen JWT y usuario actual activo. Prefijo:
`/api/financial-assignments`. Sin flag, no se registran estas rutas.

| Método y ruta relativa | Permiso y contrato |
|---|---|
| `POST /` (sin barra final) | Administrador designado. JSON: `id_usuario`, `id_campania`, `capacidad`, `motivo` y opcional `fecha_expiracion` ISO con zona. Destinatario soporte activo, distinto del administrador y del creador de campaña. |
| `POST /<id>/revoke` | Administrador designado. JSON: `motivo`. Revoca nuevas facultades, sin borrar eventos. |
| `GET /` (sin barra final) | Administrador designado; listado paginado. |
| `GET /mine` | Soporte activo; solo asignaciones propias, incluidas las ya no vigentes. |
| `GET /<id>/events` | Administrador designado; historial paginado de decisiones. |
| `GET /availability` | Usuario activo; siempre informa fuente y contabilización no disponibles en esta fase. |

Los listados admiten `page` y un máximo fijo de 50 filas por página. Las escrituras
requieren `Idempotency-Key` de 1–128 caracteres y motivo de 1–500 caracteres.
La clave es única por actor en la gestión de asignaciones: misma clave y datos
equivalentes devuelve el evento original; datos u operación diferentes: 409.
Una repetición devuelve un evento histórico, no afirma vigencia actual; consultar
el listado para esa vigencia. No se guarda el valor original de la clave, solo hash.
Las respuestas llevan `Cache-Control: private, no-store` y
`X-Content-Type-Options: nosniff`.

Concesión/reactivación y revocación actualizan asignación, evento y AUDITORIA en
una sola transacción. Un fallo revierte los tres. Las denegaciones relevantes se
auditan por separado, sin incluir cuerpo, tokens ni motivos en el log general.
El historial específico guarda el motivo y solo es consultable por el designado.
Los endpoints no ofrecen edición/borrado de eventos; no se promete protección
contra un administrador con acceso directo a SQL.

Las capacidades no implican acceso a documentos ni a movimientos todavía
inexistentes. `exigir_asignacion()` y `exigir_doble_control()` son precondiciones
para futuros servicios; no registran confirmaciones, no acreditan recepción ni
constituyen una operación de contabilización. El coordinador futuro deberá repetir
las comprobaciones bajo bloqueos dentro de su propia transacción.

Las escrituras bloquean usuarios por ID ascendente, campaña y asignación, y
revalidan al administrador tras bloquear. La restricción única protege el ámbito
usuario/campaña/capacidad. Concurrencia PostgreSQL sigue pendiente de prueba, por
lo que no se ha autorizado activación ni despliegue de esta API.
