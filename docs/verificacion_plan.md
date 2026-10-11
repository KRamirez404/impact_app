# Verificación del plan histórico — ImpactApp

Fecha: 11 de octubre de 2026.

## Alcance de esta intervención

Se contrastaron tareas de `Plan.txt` con el código y las brechas identificadas
en la revisión previa. Se implementó la corrección de la tarea 0.7, que aparecía
como completada pero no inspeccionaba el contenido de los archivos.

Los estados históricos no acreditan automáticamente los requisitos de
`requerimientos.pdf`. El desarrollo pendiente se organiza en `Plan_Cierre.txt`.

## Brechas identificadas

| Tarea histórica | Resultado de la revisión | Seguimiento |
|---|---|---|
| F0, 0.7: MIME real | Incumplida al inicio: extensión y MIME declarado por el cliente, sin detección del contenido. | Corregida en esta intervención. |
| F0, 0.5: evitar errores 500 | Parcial: hay validaciones puntuales, pero faltan controles homogéneos de tipos. | Etapas 2 y 8. |
| F1: autorización | Roles presentes; `require_role` no rechaza usuarios bloqueados por su estado. | Etapas 6 y 8. |
| F2: cuenta bancaria | Bloqueo condicionado al estado actual `activa`, no a haber sido verificada. | Etapa 6. |
| F3: supresión y privacidad | Anonimización presente; faltan invalidación de sesiones y protección de documentos privados. | Etapa 8. |
| F4: integridad | Una donación sin checksum se considera íntegra; la auditoría no garantiza inmutabilidad. | Etapa 7. |
| F5: trazabilidad | Historial e indicador de avances implementados; publicación desde Flutter pendiente. | Etapa 4. |
| F6: móvil | Carpetas nativas presentes; funcionamiento Android y APK no acreditados. | Etapa 5. |
| F7: evidencia académica | Conteo histórico desactualizado; la procedencia de SUS debe acreditarse. | Etapa 1 y evaluación final. |

## Corrección ejecutada: validación de archivos

- `services/file_service.py` detecta el MIME a partir de bytes con `python-magic`
  y exige correspondencia con una extensión permitida.
- El Content-Type del cliente no se usa como prueba de la naturaleza del archivo.
- Para DOCX se comprueba el paquete ZIP, la presencia de `word/document.xml`
  y la declaración del tipo de documento en `[Content_Types].xml`.
- Los archivos vacíos, disfrazados, con extensión incompatible o DOCX corruptos
  se rechazan antes de guardarse.
- La lectura para validar restaura la posición del stream; el guardado escribe
  desde el principio para conservar todos los bytes.
- `/api/upload` y `/api/supports` comparten `save_upload` y responden HTTP 400
  con `{"error": "..."}` ante contenido no permitido.
- Las imágenes Docker incluyen `libmagic1`; `requirements.txt` incluye
  `python-magic==0.4.27`.

Esta corrección detecta tipos de archivo; no constituye análisis antivirus,
sanitización de documentos ni protección de su acceso público. Esos aspectos
no se declaran cerrados por estas pruebas.

## Evidencia de ejecución

Archivo nuevo: `impactapp_backend/tests/test_uploads.py`.

Se verifican archivos reales PNG/PDF/DOCX, MIME declarado genérico, scripts
renombrados, extensiones incompatibles, archivos vacíos, ZIP que no es Word,
DOCX comprimido corrupto, preservación del contenido y rechazo sin persistencia
en disco o creación de soportes para ambos endpoints.

Entorno: Python 3.12.15, dependencias de `requirements.txt`, libmagic del sistema,
base SQLite de pruebas y cargas aisladas bajo `/tmp/opencode`.

Ejecución final desde `impactapp_backend/`:

```bash
PYTHONDONTWRITEBYTECODE=1 \
TEST_DATABASE_URL=sqlite:////tmp/opencode/impactapp-upload-tests.db \
UPLOAD_FOLDER=/tmp/opencode/impactapp-test-uploads \
/tmp/opencode/impactapp-py312/bin/python -m pytest tests -q -p no:cacheprovider --disable-warnings
```

Resultado: **95 passed**, incluyendo **31 casos nuevos de archivos**. Se emitieron
865 avisos, principalmente por APIs existentes de fecha y SQLAlchemy obsoletas.
El entorno virtual y los archivos temporales son locales a esta verificación;
el comando habitual del proyecto sigue siendo `make test`.

En esta primera ejecución Docker no estaba activo. No se realizaron pruebas
Flutter o Android en esta intervención.

## Verificación posterior con Docker y PostgreSQL

El 11 de octubre de 2026 se activó Docker y se ejecutó desde la raíz:

```bash
docker compose up --build -d --wait
make test-postgres
docker compose ps
curl --fail --silent --show-error http://localhost:5000/api/health
```

- La imagen de desarrollo del backend se construyó con libmagic y python-magic.
- PostgreSQL reportó versión **16.15**.
- La suite se ejecutó en `impactapp_test`, separada de `impactapp`, utilizada
  por el backend de la aplicación.
- Resultado: **95 passed, 865 warnings in 116.63s**, incluyendo los 31 casos
  de archivos. Los avisos corresponden principalmente a APIs obsoletas existentes.
- Tras las pruebas, `impactapp_db` y `impactapp_backend` permanecieron saludables.
- `/api/health` respondió `{"service":"ImpactApp Backend","status":"ok"}`.
- El stack quedó levantado en segundo plano; el backend escucha en el puerto 5000.
- No se construyó la imagen de producción ni se ejecutaron pruebas móviles.

## Continuación

La documentación de etapa 1 se unificó en `docs/trazabilidad_requisitos.md` y
`docs/decisiones_cierre.md`; decisiones D-01/D-02/D-03 siguen pendientes.

## Continuación: registro y perfil con servicios detenidos

Por solicitud del usuario se ejecutó `docker compose down` sin eliminar volúmenes,
y se detuvieron `docker.service` y `docker.socket`. No quedaron contenedores en
ejecución. Las pruebas posteriores se ejecutaron localmente con servicios apagados.

Implementación de etapa 2:
- Ciudad opcional del usuario, catálogo y persistencia en API/Flutter/sesión.
- Migración idempotente para el esquema existente con datos conservados.
- Validación de objetos JSON, tipos y longitudes, correo, contraseña y aceptación
  estricta del consentimiento; contraseñas limitadas a 72 bytes para bcrypt.
- Validación completa antes de aplicar cambios de perfil, evitando cambios parciales.
- Campos separados de nombres/apellidos, avatar seguro con espacios y reintento
  de carga de ciudades. Correcciones de desbordamiento detectadas por tests.

Ejecuciones:

```bash
PYTHONDONTWRITEBYTECODE=1 \
TEST_DATABASE_URL=sqlite:////tmp/opencode/impactapp-profile-tests.db \
UPLOAD_FOLDER=/tmp/opencode/impactapp-test-uploads \
/tmp/opencode/impactapp-py312/bin/python -m pytest tests -q -p no:cacheprovider --disable-warnings
```

Resultado: **140 passed, 1145 warnings in 116.97s**, con 45 casos nuevos en
`tests/test_profile.py`. Los avisos corresponden a APIs obsoletas existentes.

Desde `impactapp_flutter/`:

```bash
flutter test
flutter analyze --no-fatal-infos
```

Resultado: **45 pruebas Flutter aprobadas**; análisis sin errores ni advertencias,
con **40 observaciones informativas** existentes. Flutter 3.47.2 / Dart 3.13.2.

Los nuevos cambios de perfil y migración aún no se ejecutaron contra PostgreSQL
ni en dispositivos Android. El resultado PostgreSQL de 95 casos corresponde a
la versión anterior a esta etapa. Resolver el modelo financiero antes de cambios
que dependan de él y continuar con etapa 3 del plan.
