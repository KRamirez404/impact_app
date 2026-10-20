# Etapa 2 — Contrato de transferencias bancarias

Fecha: 16/10/2026. Estado: Fase A documental y base de autorización de Fase B.
La implementación parcial se detalla al final. Fuente de decisiones: solicitudes del
responsable del proyecto de planificación y Build de Etapa 2.

## 1. Decisiones y alcance

**Aprobado:** COP; documentos PDF, JPEG y PNG; comprobante opcional; declaraciones
y cargas sin recaudo; doble control; identificador bancario verificable obligatorio;
privacidad; historial; bloqueo de discrepancias y fechas no verificables.

**Aprobado:** conservar Wompi y los datos históricos. No aprobar cuentas a partir
del texto legado `cuenta_recaudo`. No habilitar contabilización real sin fuente
bancaria independiente. No crear administradores ni conceder facultades por
inferirlas del seed o del rol de soporte.

**Por definir:** banco/fuente, identidad de movimientos, responsable administrativo,
habilitación de actores, cierre financiero, límites de archivos y políticas de
discrepancias, conservación y revocación. Devoluciones, reclamaciones y cancelación
financiera quedan fuera del alcance inicial.

## 2. Dependencias reales y límites del primer incremento

| Archivo existente | Hecho relevante |
|---|---|
| `impactapp_backend/app.py` | Importar ejecuta `create_app()`, crea carpetas/tablas, ajustes de esquema y seed. |
| `impactapp_backend/models/donation.py` | Registro financiero compartido, importe decimal e índices únicos de Wompi/checkout. |
| `impactapp_backend/services/campaign_service.py` | Suma donaciones económicas aprobadas; permite `confirmar=False`. |
| `impactapp_backend/services/audit_service.py` | Permite registrar sin commit propio mediante `confirmar=False`. |
| `impactapp_backend/routes/wompi_routes.py` | Confirma con consulta autoritativa y transacción campaña → donación; no reutilizar su coordinador para transferencias. |
| `impactapp_backend/services/authorization.py` | No comprueba usuarios bloqueados ni asignaciones financieras. |
| `impactapp_backend/models/campaign.py` | `fecha_fin` es fecha sin hora; `cuenta_recaudo` es texto y se serializa. |
| `impactapp_backend/services/file_service.py` | Cargas generales y MIME real, pero devuelve URLs públicas y permite otros formatos. |
| `impactapp_backend/tests/conftest.py` | Importa aplicación y recrea tablas en fixtures. |

El primer incremento solo modifica documentación. No introduce modelos que el
`create_all()` actual pudiera crear al siguiente arranque, ni cambia endpoints,
permisos existentes o el esquema de una base de datos.

## 3. Fuente bancaria pendiente

No se ha identificado una fuente bancaria disponible. La consulta de transacciones
Wompi no equivale a consultar los abonos de una cuenta de recaudo. No se han
ejecutado solicitudes bancarias ni operaciones de pasarela durante esta fase.

| Alternativa | Autenticidad, disponibilidad y permisos | Identidad, fechas y duplicados | Limitaciones y esfuerzo |
|---|---|---|---|
| Extracto/reporte de banca empresarial | Requiere banco, ejemplo anonimizado, obtención por actor autorizado y procedimiento verificable de procedencia e integridad. No basta un archivo aportado por el donante. | Confirmar ID nativo estable entre exportaciones, cuenta, moneda, abono efectivo y precisión/zona de fecha. No usar posición de fila o hash del archivo como identidad del ingreso. | Puede carecer de ID o de hora suficiente. Esfuerzo condicionado al formato y prueba de autenticidad; importación y conciliación aún no diseñadas para un banco concreto. |
| API oficial bancaria | Requiere producto disponible, documentación oficial, acceso contractual y credenciales autorizadas de consulta. Nada de ello está acreditado. | Documentar ámbito y estabilidad del ID, paginación, estados efectivos, correcciones, timestamps y zona. Restricción única sobre identidad canónica. | Depende del acceso, límites y semántica real del banco. Esfuerzo de adaptador, autenticación, recuperación y pruebas pendiente de documentación. |
| Otra fuente verificable | Debe demostrar autenticidad, procedencia, integridad y facultad de consulta; su aceptación requiere aprobación. | Debe identificar abono, cuenta, importe, moneda y fecha con precisión suficiente; resolver equivalencia con otras fuentes. | No se acepta por defecto correo, captura o referencia libre. Viabilidad y esfuerzo no estimables sin especificación. |

Contrato mínimo previo a implementar el adaptador: banco y cuenta real, namespace
de ID, estabilidad y alcance de unicidad, estado que acredita recepción, importe
bruto/neto, moneda, fecha efectiva, precisión, zona, correcciones y evidencia
conservada. Una misma cuenta mantiene identidad estable entre versiones; cambiar
fuente o versión no puede habilitar duplicación. Separar abonos directos de
liquidaciones de Wompi para no reconocer dos veces el mismo ingreso.

## 4. Modelo propuesto, todavía sin tablas nuevas

- Cuenta bancaria estable y versiones de datos de destino inmutables tras verificar.
- Autorización de versión de cuenta para campaña, con vigencia e historial.
- Asignación financiera por usuario, campaña y capacidad; concesión/revocación
  con actor, fecha y motivo. No autoconcesión ni escalada implícita.
- Transferencia: donante desde JWT, campaña y destino autorizado, importe declarado
  decimal, COP, estado y ciclo de revisión. El importe verificado es independiente.
- Comprobante: clave privada aleatoria, hash, MIME, tamaño y estado técnico.
- Movimiento: identidad canónica definida por la fuente, cuenta, importe decimal,
  COP, fecha efectiva, precisión y evidencia independiente.
- Eventos append-only y cierre financiero trazable, sin inferir horas de `fecha_fin`.

Se evaluará separar tablas solo cuando sea necesario. Se requieren FK, unicidad de
movimiento y donación por transferencia, idempotencia por actor/operación y controles
de correspondencia entre campaña, cuenta y autorización. Sin backfills aprobatorios.

**Propuesta técnica pendiente:** un movimiento completo por declaración y una
donación creada únicamente al contabilizar. Identidad bancaria y datos privados
no se añadirán a serializadores públicos de donación. El checksum no sustituye la
evidencia bancaria ni las restricciones.

## 5. Permisos y estados propuestos

| Operación | Condición necesaria |
|---|---|
| Conceder/revocar asignaciones y consultar su historial | Responsable administrativo designado de forma fiable; sin designación, denegar. |
| Declarar/cargar/ver historial propio | Donante activo y propietario; destino autorizado y campaña elegible. |
| Revisar/confirmar recepción | Organizador activo habilitado para esa campaña. |
| Revisión financiera y acceso documental | Soporte activo con asignación explícita vigente por campaña y finalidad. |
| Autorizar contabilización | Actor distinto del confirmador, asignación vigente y todas las validaciones; deshabilitado sin fuente. |

Consultar el usuario y las asignaciones actuales en cada operación, incluidas
descargas. Un JWT previo no preserva un permiso revocado. Registrar denegaciones
relevantes sin datos bancarios o secretos. La identidad interna separa cuentas,
pero falta aprobar el procedimiento que acredita personas diferentes.

| Transición propuesta | Actor/precondición |
|---|---|
| Creación → `registrada` | Donante; no crea recaudo. |
| `registrada` → `en_revision` | Revisor habilitado. |
| `en_revision` → `recepcion_verificada` | Organizador; confirmación separada de contabilización y no basada solo en el comprobante. |
| Revisión/recepción verificada → `bloqueada_por_identificacion` | Revisor competente; falta de fuente o identidad fiable. |
| Revisión/recepción verificada → `con_discrepancia` | Diferencia documentada sin alterar lo declarado. |
| Revisión/recepción verificada → `rechazada` | Revisor competente según etapa; motivo obligatorio. |
| `recepcion_verificada` → `contabilizada` | Soporte asignado distinto; fuente y políticas aprobadas, validaciones y transacción atómica. Actualmente no habilitable. |

Reapertura: propuesta de volver a `en_revision` con nueva evidencia, evento y ciclo,
sin borrar decisiones y exigiendo nueva confirmación. No se habilitará si depende
de una política pendiente; en especial, no resuelve automáticamente discrepancias.
Ningún rechazo, bloqueo o discrepancia pasa directamente a contabilización.

Campañas cerradas: revisión posterior solo con recepción anterior acreditada contra
un cierre fiable. No inventar hora para fechas bancarias o `fecha_fin`. Si no puede
demostrarse precedencia, bloquear. Pausa, eliminación y revocación posterior de
cuentas requieren política; mientras falte, no habilitar esos casos financieros.

## 6. Comprobantes privados: propuesta de implementación

Raíz persistente fuera de uploads y de cualquier directorio servido públicamente;
staging privado; claves aleatorias; creación exclusiva sin sobrescribir; apertura
con protección contra traversal y enlaces simbólicos. No aceptar URLs remotas como
atajo de carga ni usar el nombre del cliente como ruta interna.

Validar extensión, MIME detectado y estructura completa. `python-magic` existente
no decodifica imágenes ni inspecciona completamente PDF. Justificar y aprobar
dependencias de decodificación y parser, límites de recursos y tratamiento de
contenido activo, PDF cifrado y análisis antimalware antes de habilitar cargas.
Ningún parser garantiza por sí solo ausencia de malware.

Valores recomendados **no aprobados**: 8 MiB por archivo, 20 páginas PDF, 10 000
píxeles por lado y 25 megapíxeles. El límite global actual de petición es 16 MiB;
no sustituye límites de archivo, memoria, tiempo, tasa y almacenamiento acumulado.
Falta medir capacidad con validadores seleccionados. Sin configuración aprobada,
mantener las cargas restringidas, no admitir archivos ilimitados.

Descarga autenticada y autorizada por propiedad/campaña/finalidad, respuesta
uniforme para documentos ajenos, `Cache-Control: private, no-store`,
`X-Content-Type-Options: nosniff` y `Content-Disposition: attachment`. Sin rutas
internas, nombres de almacenamiento ni enlaces públicos permanentes en JSON.

Filesystem y SQL no comparten transacción: preparar en staging, validar, mover
atómicamente en el mismo volumen y confirmar disponibilidad/asociación en SQL.
Un estado técnico intermedio nunca es descargable. Definir reconciliación
idempotente de objetos huérfanos y registros sin archivo; no borrar archivos ya
confirmados ni introducir plazos de eliminación automática sin política.

## 7. Contabilización futura y evolución del esquema

La contabilización real sigue bloqueada. Cuando se apruebe la fuente, el coordinador
propio de transferencias debe validar permisos, ciclo, cuenta, movimiento único,
importe, COP y tiempo; crear/vincular donación, evento y auditoría y recalcular con
`confirmar=False` antes de un único commit. Fallo en cualquier paso: rollback total.
No llamar al coordinador específico de Wompi ni crear otro cálculo de progreso.

Propuesta de bloqueos: estabilizar actores/asignaciones en orden determinista,
campaña → transferencia → autorización de cuenta → movimiento → donación. Toda
operación relacionada debe respetar ese orden; nunca adquirir campaña reteniendo
movimiento. Varias campañas se ordenan por ID. Sin llamadas externas bajo bloqueo.
Restricciones únicas resuelven también carreras de inserción de filas inexistentes.
SQLite no demuestra bloqueos de fila PostgreSQL: acreditar estrategia propia o
mantener contabilización deshabilitada en SQLite.

Antes de registrar modelos: documentar tablas/índices/FK aditivos, inicialización
idempotente y comportamiento por motor. `create_all()` no migra tablas existentes.
No aplicar DDL ni reiniciar la aplicación contra datos reales en esta fase.
Despliegue posterior: respaldo autorizado, volumen privado, configuración explícita,
ventana de esquema y activación gradual. Los nombres de flags y endpoints siguen
siendo propuestas; este documento no describe una API implementada.

## 8. Próximas fases y aceptación

1. Fase A: decisiones, contrato y [pruebas aisladas](pruebas_transferencias.md).
2. Fase B: modelos y autorización suficientemente definidos; sin responsable
   acreditado, gestión financiera denegada, incluso para soporte.
3. Fase C: comprobantes, tras aprobar validadores, límites y raíz privada.
4. Fase D: declaraciones/revisión sin contabilización; sin cuenta autorizada,
   no ofrecer instrucciones ni crear destinos ficticios para hacer utilizable el flujo.
5. Fase E: solo después de fuente y políticas aprobadas, integrar contabilización.
6. Fase F: interfaz con estados reales, regresión y documentación; comprobar si
   existe servicio de correo antes de proponer reutilizarlo. No enviar correos reales
   en pruebas ni comunicar recepción por una mera carga de comprobante.

Aceptación de este incremento: solo documentación coherente, decisiones aprobadas
separadas de propuestas, bloqueos explícitos, ninguna inicialización ni prueba con
efectos secundarios. No acredita las fases B–F ni la integración bancaria.

## 9. Incremento de Fase B

Implementadas únicamente asignaciones financieras, eventos y controles previos de
autorización, con registro condicional desactivado por defecto. No hay fuente,
cuentas verificadas, declaraciones, comprobantes ni contabilización. El resto del
modelo y las transiciones anteriores siguen siendo propuestas para fases futuras.

Contrato operativo y evolución aditiva: [esquema de Fase B](esquema_financiero_fase_b.md).
La designación administrativa sigue pendiente; ningún usuario semilla recibió
facultades. No se aplicaron cambios de esquema a bases existentes. La regresión
se ejecutó únicamente en una copia temporal desechable.
