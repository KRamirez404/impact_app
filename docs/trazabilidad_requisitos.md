# Matriz de trazabilidad de cierre — ImpactApp

Referencia canónica: `academico/requerimientos.pdf` versión 2, páginas 3–6.
Actualización: 29/10/2026.
El alcance adicional procede de `anteproyecto.txt`; no modifica silenciosamente el PDF.

## Cómo leer la matriz

- **Implementación** describe el contraste estático con código, no una certificación.
- **CP-RF / CP-RNF** son escenarios de aceptación de cierre; no necesariamente tests ya escritos.
- **Pendiente** significa que falta ejecutar y registrar el escenario completo.
- La suite backend de referencia aprobó **95 casos** en SQLite y PostgreSQL el 11/10/2026.
  Eso no significa que cada requisito esté satisfecho: hay cobertura parcial y flujos sin pruebas.
- Toda ejecución nueva debe indicar fecha, versión/estado del código, entorno y resultado.

### Avance RF-09 — 4/11/2026 (árbol de trabajo sin confirmar)

- La aprobación de transferencias requiere cuenta, monto, fecha e identificador
  del movimiento contrastados por soporte en una fuente bancaria independiente.
  El identificador se reserva de forma única por cuenta, sin exponerlo al donante;
  el comprobante del donante permanece obligatorio. La comprobación en el banco
  es manual, no una integración bancaria automática.
- Se añadió interfaz Flutter de consulta y revisión para soporte. La administración
  de cuentas y asignaciones financieras sigue disponible solo por API restringida.
- Verificación local: suite backend SQLite con transferencias habilitadas:
  **363 aprobadas, 6 omitidas**; prueba dirigida final de transferencias y correo:
  **40 aprobadas, 2 omitidas**. Flutter: **69 pruebas aprobadas**; análisis sin
  errores ni avisos de severidad warning, con 40 mensajes informativos existentes.
- PostgreSQL aislado (`impactapp_rf09_20261104_test`): pruebas dirigidas de
  transferencias y notificaciones **42 aprobadas, 0 omitidas**. La suite completa
  PostgreSQL se ejecuta por separado; no se extrapola este resultado a ella.
- **RF-09 permanece parcial**: después de activar Docker se aplicaron las tres
  migraciones en orden en la base PostgreSQL nueva `impactapp_rf09_20261104_test`
  y se verificaron las columnas y la restricción única del abono. No se aplicaron
  a la base activa ni se comprobó el flujo en un dispositivo. La contabilización
  de transferencias reales no se habilitó.

### Avance de cierre — 29/10/2026

- **Etapa 8, privacidad y acceso:** el listado público solo expone campañas
  `activa` y `finalizada`; el detalle, las donaciones, los seguimientos, los puntos
  de recolección y las valoraciones responden `404` cuando el usuario no puede ver
  la campaña. El creador y soporte conservan acceso; solo soporte ve campañas
  eliminadas. Las donaciones en especie exigen campaña `activa`.
- **Verificación Etapa 8:** 44 pruebas dirigidas aprobadas
  (`test_security.py`, `test_roles.py`, `test_campaign_visibility.py`), suite
  completa **333 passed / 29 skipped** en SQLite y **337 passed / 25 skipped** en
  PostgreSQL aislado.
- **Notificaciones por correo:** patrón outbox en `NOTIFICACION_EMAIL`, envío por
  SMTP o API HTTPS (Brevo), reintentos con worker programable, bandeja por usuario
  con lectura y consulta para soporte. Un fallo de correo no revierte pagos.
  Pruebas: 44 casos en SQLite (4 omitidos); 45 en PostgreSQL aislado (2 omitidos)
  antes de añadir la última prueba de remitente, independiente del motor. Incluyen
  Wompi, transferencias, concurrencia y aislamiento entre usuarios; detalle en
  `docs/notificaciones_email.md`.
- **Flutter:** 72 pruebas aprobadas; `flutter analyze` sin errores.
- **Sigue pendiente:** APK release, pruebas en dispositivos, SUS con participantes,
  envío real contra un proveedor de correo configurado y pagos reales. No se
  modificaron los indicadores de Wompi ni de transferencias.

## Requisitos del PDF y escenarios de aceptación

| Requisito | Criterio verificable / escenario de cierre | Caso | Implementación al inicio del cierre | Resultado del escenario completo | Etapa |
|---|---|---|---|---|---|
| RF-01 Registro de usuarios | Registrar datos válidos; rechazar tipos, nombres, correo, contraseña y consentimiento inválidos; impedir correo duplicado; almacenar hash y mostrar éxito/error. | CP-RF-01 | Parcial: validaciones incompletas. | Pendiente | 2 |
| RF-02 Autenticación (Login) | Credenciales válidas generan JWT temporal; incorrectas no generan sesión y muestran error. | CP-RF-02 | Presente; tests backend existentes. | Pendiente ejecución frontend/backend | 2 / cierre |
| RF-03 Perfil de usuario (Consulta y edición) | Editar nombre, teléfono y ciudad; guardar, consultar y recuperar los datos tras una nueva sesión. | CP-RF-03 | Parcial: ciudad ausente. | Pendiente | 2 |
| RF-04 Autorización y control de acceso por roles | Donante aporta/consulta; organizador administra sus campañas y avances; soporte revisa campañas/gestiona usuarios; peticiones autenticadas sin permiso reciben 403. | CP-RF-04 | Parcial: gestión de usuarios y control de bloqueados pendientes. | Pendiente | 6 / 8 |
| RF-05 Creación de campañas | Crear con datos/meta/fecha válidos; estado pendiente; visitante y donante no consultan una campaña pendiente; creador y soporte sí. | CP-RF-05 | Parcial: pendiente visible por API pública. | Pendiente | 6 / 8 |
| RF-06 Edición y administración de campañas | Creador edita datos permitidos; cuenta verificada protegida; eliminación rechazada con donaciones procesadas; otro organizador recibe 403. | CP-RF-06 | Implementado: formulario de edición, actualización descriptiva en tiempo real, bloqueo de cuenta verificada y validación de autoría. | Completado y probado; tareas `task_302c5fed6c2c` (RF-06) y suites backend/Flutter | 6 |
| RF-07 Búsqueda y filtrado de campañas | Buscar y filtrar campañas por ciudad, categoría o tipo de ayuda solicitada; el listado se actualiza de acuerdo con los filtros aplicados. | CP-RF-07 | Implementado: filtros de ciudad, categoría y tipo de ayuda. | Completado y probado; tarea de Orca `task_58bd9bebcc1a` | 4 |
| RF-08 Validación de identidad y estado de verificación | Soporte revisa pendientes/documentos; económica sin documento no se aprueba; aprobación habilita publicación/aportes; rechazo no los habilita. | CP-RF-08 | Parcial: panel presente; revisión documental/acceso pendientes. | Pendiente | 6 / 8 |
| RF-09 Registro de aportes monetarios | Mostrar cuenta solo tras aprobación; registrar transferencia y comprobante; validar; sumar una sola vez y asociar al historial. | CP-RF-09 | No implementa el flujo del PDF: actualmente Wompi. | Pendiente decisión D-01/D-02 | 9 |
| RF-10 Registro de donaciones en especie | Seleccionar categoría (alimentos, ropa o medicamentos), monto estimado, descripción y punto de recolección asociado a la campaña; la donación queda documentada con categoría y punto de entrega. | CP-RF-10 | Implementado: categoría, monto estimado, punto de recolección y descripción en diálogo físico y backend. | Completado y probado; tarea de Orca `task_02e6c702640b` | 3 |
| RF-11 Informe financiero y notificación | El organizador carga el informe financiero, se valida el formato MIME, queda disponible en la app y se envía correo a los donantes aportantes. | CP-RF-11 | Parcial: existe infraestructura de notificaciones y validación MIME; falta acreditar el flujo completo del informe y su correo a aportantes. | Pendiente | 4 / 8 |
| RF-12 Enlaces externos de verificación y trazabilidad | Mostrar en el detalle de la campaña aportada enlaces directos a las redes sociales del organizador para verificar externamente avances y gestión; no exige seguimiento interno continuo. | CP-RF-12 | Implementado: enlaces sociales en perfil de organizador y visualización interactiva en detalle de campaña (InfoTab). | Completado y probado; tarea de Orca `task_016360b06e4a` | 4 / cierre |
| RNF-01 Seguridad de credenciales (Ley 1273/2009) | Registro persiste hash bcrypt, nunca contraseña original; respuesta API no expone hash ni contraseña. | CP-RNF-01 | Presente; verificar explícitamente persistencia/exposición. | Pendiente | 2 |
| RNF-02 Trazabilidad y Auditoría | Creación, aprobación y cambio bancario registran fecha/usuario/IP; eventos no se alteran silenciosamente; operación fallida no deja cambio confirmado ficticio. | CP-RNF-02 | Parcial: auditoría persistente, no inmutable. | Pendiente estrategia de etapa 7 | 7 |
| RNF-03 Privacidad y Tratamiento de Datos (Ley 1581/2012) | Perfil editable; supresión anonimiza datos; token anterior deja de operar; identidad y comprobantes no son públicos. | CP-RNF-03 | Parcial: anonimización presente, acceso/sesiones pendientes. | Pendiente | 2 / 8 |
| RNF-04 Arquitectura y Compatibilidad | API Flask intercambia JSON con Flutter; APK instalado en Android ejecuta flujos críticos contra backend. | CP-RNF-04 | API/capas/proyecto Android presentes; APK y dispositivos no acreditados. | Pendiente | 5 / cierre |

### Avance de etapa 2 — 11/10/2026

RF-01/RF-03 y CP-RNF-01 tienen implementación y pruebas locales adicionales:

- `impactapp_backend/tests/test_profile.py`: **45 casos aprobados**. Validación de
  JSON/tipos/longitudes/consentimiento, hash sin exposición, ciudad/nombres
  compuestos persistentes tras login, duplicados y rechazo atómico de cambios.
- Migración idempotente verificada con esquema SQLite histórico y datos conservados.
- `impactapp_flutter/test/edit_profile_test.dart`: **3 casos aprobados**, que
  verifican ciudad/nombres compuestos, avatar con espacios y reintento de catálogo.
- `models_test.dart` verifica persistencia de ciudad al serializar la sesión;
  `validators_test.dart` cubre límites y contraseña por bytes.
- Suite actual: **140 casos backend aprobados en SQLite** y **45 pruebas Flutter**.
- Las filas superiores conservan el diagnóstico inicial para distinguirlo del
  avance. Pruebas integrales contra PostgreSQL y dispositivos de estos cambios
  siguen pendientes; la ejecución PostgreSQL de 95 casos precede a la etapa 2.

## Ubicación de implementaciones y cobertura existente

Rutas desde la raíz del proyecto:

| Área | Backend | Flutter | Pruebas existentes |
|---|---|---|---|
| Registro, login, perfil | `impactapp_backend/routes/auth_routes.py`, `services/auth_service.py`, `models/user.py`, migración en `app.py` | `impactapp_flutter/lib/features/auth/` | `impactapp_backend/tests/test_auth.py`, `test_profile.py`, parcialmente `test_f2_f3.py`; Flutter: `edit_profile_test.dart`, `models_test.dart`, `validators_test.dart` |
| Roles/campañas/verificación | `impactapp_backend/routes/campaign_routes.py`, `support_panel_routes.py`, `services/authorization.py` | `impactapp_flutter/lib/features/campaigns/`, `features/support/` | `test_roles.py`, `test_f2_f3.py` |
| Donaciones/trazabilidad | `impactapp_backend/routes/donation_routes.py`, `wompi_routes.py` | `impactapp_flutter/lib/features/campaigns/`, `features/auth/presentation/widgets/profile/` | `test_wompi.py`, `test_wompi_extra.py`; Flutter: `money_donation_flow_test.dart`, `payment_status_dialog_test.dart`, `activity_card_test.dart` |
| Archivos/avances | `impactapp_backend/services/file_service.py`, `routes/upload_routes.py`, `support_routes.py`, `tracking_routes.py` | `impactapp_flutter/lib/features/verification/`, `features/campaigns/presentation/widgets/tabs/` | `impactapp_backend/tests/test_uploads.py` (31 casos); no acredita publicación integral |
| Auditoría/integridad | `impactapp_backend/models/auditoria.py`, `services/audit_service.py`, `donation_integrity.py` | Estados e historial de aportes | `test_f2_f3.py`; inmutabilidad pendiente |
| Notificaciones | `impactapp_backend/models/notification.py`, `services/notification_service.py`, `services/email_provider.py`, `routes/notification_routes.py`, `routes/support_panel_routes.py`, `scripts/send_pending_emails.py` | `impactapp_flutter/lib/features/notifications/` | `test_notifications.py` (44 SQLite / 45 PostgreSQL antes de la última prueba); proveedor simulado; Flutter: `notification_flow_test.dart` |
| Android | `docker-compose.yml`, API Flask | `impactapp_flutter/android/` | Pendiente instalación y ejecución en dispositivo/emulador |

## Alcance adicional del anteproyecto

Los códigos AC son propios de esta matriz, no requisitos numerados por el PDF.

| Código | Fuente en anteproyecto.txt | Criterio verificable | Caso | Resultado / etapa |
|---|---|---|---|---|
| AC-01 Necesidades y cantidades | Líneas 305 y 429 | Campaña define artículo/unidad/cantidad; aportes actualizan comprometido/recibido sin duplicación. | CP-AC-01 | Pendiente / 3 |
| AC-02 Estado y entrega | Líneas 305 y 429 | Recepción/entrega/cancelación con responsable y fecha; información visible según rol. | CP-AC-02 | Pendiente / 3 |
| AC-03 Comunicación básica | Línea 311 | Comentario o actualización utilizable; comentar no asigna una valoración no elegida. Push no obligatorio. | CP-AC-03 | Parcial / 4 |
| AC-04 Seguridad e integridad | Líneas 481–493 y 613 | Pruebas negativas de entradas/accesos/pagos; registros protegidos; sin hallazgos críticos abiertos al cierre. | CP-AC-04 | Pendiente / 7–9 |
| AC-05 Multiplataforma | Líneas 409 y 437 | Configuración y evidencia de compatibilidad por plataforma; PDF exige Android, anteproyecto contempla Android/iOS. | CP-AC-05 | Pendiente / 5 |
| AC-06 Usabilidad SUS | Líneas 583, 595, 649 y 677 | Evaluación voluntaria con 10 participantes, perfiles definidos, respuestas anonimizadas, cálculo y observaciones. | CP-AC-06 | No acreditado / cierre |
| AC-07 Proceso y cambios | Líneas 559–567 y 695–705 | Backlog, revisiones, incrementos y cambios de alcance/versiones registrados. Git solo no acredita Scrum. | CP-AC-07 | Parcial / 1 y cierre |
| AC-08 Evaluación integral | Líneas 605–617 y 663–679 | 100 % del MVP con casos/resultados; umbral propuesto de 90 % de casos aprobados; flujos críticos completos; repetir pruebas afectadas. | CP-AC-08 | Pendiente / cierre |

## Correspondencia con códigos históricos

Los códigos anteriores de esta matriz quedan retirados; `Plan.txt` se conserva
como historial y no debe utilizar sus códigos para identificar requisitos actuales.

- RF-01 anterior (registro/login) → RF-01 y RF-02 del PDF.
- RF-02 anterior (roles) → RF-04.
- RF-03 anterior (crear/verificar campañas) → RF-05 y RF-08.
- RF-04 anterior (donaciones) → RF-09 y RF-10.
- RF-05 anterior (cuenta bancaria) → RF-06 y RNF-02.
- RF-06 anterior (trazabilidad) → RF-12.
- RF-07 anterior (avances) → RF-11.
- RNF-01 anterior (Android) → RNF-04.
- RNF-05 anterior (auditoría) → RNF-02.
- RNF-06 anterior (datos personales) → RNF-03 y RF-01/RF-03.
- RNF-07 anterior (checksum) → AC-04.
- RQ-01..05 anteriores → AC-06 y AC-08; el anteproyecto no asigna esos códigos.

## Evidencia y comandos

La ejecución de referencia de **95 passed** en PostgreSQL aislado se registra en
`docs/verificacion_plan.md`. Los antiguos resultados de 20/21 pruebas y “PASÓ”
no se reutilizan para certificar esta matriz con criterios nuevos.

```bash
make test-postgres
```

Pruebas Flutter desde `impactapp_flutter/`:

```bash
flutter test
flutter analyze
```

Decisiones pendientes y diseño de acceso: `docs/decisiones_cierre.md`.
