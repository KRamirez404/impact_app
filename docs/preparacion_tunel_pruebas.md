# Preparación de seguridad y APK para pruebas móviles

Fecha: 2026-10-21  
Rama: `feat/etapa-2-transferencias-comprobantes`  
HEAD: `47ed2f756384b13eb956a610e063777b7f7c6f49`

## 1. Estado inicial preservado

Estado de Git antes de trabajar:

```text
 M docker-compose.yml
 M impactapp_flutter/android/app/src/debug/AndroidManifest.xml
 M impactapp_flutter/android/gradle.properties
?? PROMPT_IMPLEMENTACIÓN.txt
?? docs/despliegue_apk_estado.md
?? graphify-out/
```

No se cambió de rama, no se hicieron commits, push ni merge. Los cambios y archivos no rastreados existentes se conservaron.

## 2. Respaldo de PostgreSQL

Se creó un respaldo nuevo antes de modificar el código:

- Archivo: `/tmp/opencode/impactapp_20261021_155242.dump`
- Formato: `pg_dump --format=custom`
- Tamaño: 56 986 bytes
- SHA-256: `5c4d92eb9b8c3b2d5a8c23bf737a71d49c1a00e81707ca137dc956a5bc3365af`
- Verificación: `pg_restore --list` listó 158 entradas correctamente.

No se restauró el respaldo ni se eliminaron volúmenes.

## 3. Conteos de la base real

Consultas de solo lectura antes y después:

| Entidad | Antes | Después |
|---|---:|---:|
| Usuarios | 9 | 9 |
| Campañas | 8 | 8 |
| Donaciones | 3 | 3 |
| Soportes | 3 | 3 |

Los conteos permanecieron iguales.

## 4. Vulnerabilidades encontradas y correcciones

### Crítica: datos privados en campañas públicas

Los endpoints públicos de campañas devolvían correo, teléfono, biografía, cuenta de recaudo, soportes y donaciones con identificadores del donante, checksum, referencias y transacciones Wompi.

Correcciones:

- `models/campaign.py`: nuevo `to_public_dict()` sin cuenta de recaudo, notas de revisión, auditor, eliminador ni campos internos.
- `models/user.py`: nuevo `to_public_dict()` limitado a identificador, nombre, apellido y foto.
- `models/donation.py`: nuevo `to_public_dict()` sin donante, checksum, referencia, transacción ni método de pago.
- `models/support.py`: nuevo `to_public_dict()`; solo expone URL para imágenes públicas y nunca para documentos privados.
- `routes/campaign_routes.py`: lista y detalle públicos usan los serializadores seguros; los donantes vistos por el organizador usan datos públicos del donante.
- `routes/campaign_routes.py`: el detalle público solo incluye soportes validados.

### Crítica: archivos y soportes accesibles sin autenticación

`/uploads/<archivo>` y `GET /api/supports/campaign/<id>` eran públicos.

Correcciones:

- `models/file.py`: modelo `ARCHIVO` sobre la tabla existente, con propietario de cada carga.
- `routes/upload_routes.py` y `routes/support_routes.py`: registran cada archivo subido y su usuario.
- `app.py`: `/uploads/<archivo>` ahora exige autenticación para archivos privados y autoriza por propietario o rol `soporte`.
- `routes/support_routes.py`: `GET /api/supports/campaign/<id>` exige JWT y permite solo al creador de la campaña o a `soporte`.
- Se conservaron las imágenes públicas legítimas: fotos de perfil, evidencias de seguimiento y soportes de tipo `foto`/`imagen`.
- Una referencia privada tiene prioridad: un documento no se vuelve público por asignarlo como foto de perfil o evidencia.
- Se añadieron `X-Content-Type-Options: nosniff` y caché privada para archivos protegidos.

### Crítica: administrador con contraseña conocida

`seed_database()` creaba `admin@impactapp.co` con una contraseña documentada. La cuenta existente en la base real todavía conserva esa contraseña.

Correcciones:

- `app.py`: se eliminó la creación automática de credenciales administrativas y no se modifica la contraseña de cuentas existentes.
- `scripts/rotate_support_password.py`: rotación interactiva, sin imprimir la contraseña ni el hash.
- `README.md` y `AGENTS.md`: se eliminaron las credenciales por defecto y se documentó la rotación.

La cuenta existente debe rotarse antes de abrir cualquier túnel público.

### Alta: ausencia de límites de solicitudes

Correcciones:

- `services/rate_limit.py`: limitador en memoria por clave y ventana temporal.
- `config.py`: límites configurables mediante variables de entorno.
- Login: 10 intentos por correo/IP y 50 por IP cada 15 minutos.
- Registro: 5 solicitudes por IP por hora.
- Cargas: 30 por usuario por hora, tanto en `/api/upload` como en `/api/supports`.
- Webhook: 600 solicitudes por IP por minuto; no se modificó la validación HMAC ni la idempotencia.

Limitación: es un limitador por proceso. Se reinicia con el backend y no se comparte entre múltiples workers. Para esta prueba temporal con un solo proceso es suficiente.

### Media: health check no verificaba PostgreSQL

`/api/health` devolvía 200 con una respuesta estática.

Corrección:

- `app.py`: ejecuta `SELECT 1` con SQLAlchemy.
- Devuelve 503 con `database: unavailable` si PostgreSQL falla.
- Respuesta correcta: `database: ok`.

### Configuración

- `FLASK_DEBUG` no está definido y `FLASK_ENV=production`.
- No se activó el modo debug.
- Wompi permanece en sandbox y producción sigue bloqueada.
- No se encontraron claves privadas de Wompi en Flutter ni en el APK.
- No se abrió ningún túnel ni se publicó el puerto de PostgreSQL.

## 5. Archivos modificados o añadidos

Backend:

- `app.py`
- `config.py`
- `models/__init__.py`
- `models/campaign.py`
- `models/donation.py`
- `models/support.py`
- `models/user.py`
- `models/file.py` (nuevo)
- `routes/auth_routes.py`
- `routes/campaign_routes.py`
- `routes/support_routes.py`
- `routes/upload_routes.py`
- `routes/wompi_routes.py`
- `services/rate_limit.py` (nuevo)
- `scripts/rotate_support_password.py` (nuevo)
- `tests/conftest.py`
- `tests/test_auth.py`
- `tests/test_f2_f3.py`
- `tests/test_wompi_extra.py`
- `tests/test_security.py` (nuevo)

Frontend y documentación:

- `impactapp_flutter/lib/features/campaigns/presentation/widgets/tabs/info_tab.dart`
- `README.md`
- `AGENTS.md`
- `docs/preparacion_tunel_pruebas.md`

## 6. Pruebas ejecutadas

### Backend

No se definió `TEST_DATABASE_URL`; la suite usó SQLite aislado en `/tmp/impactapp_pytest.db` dentro del contenedor. No apuntó a PostgreSQL real.

Resultado completo (suite backend + pruebas aisladas):

```text
288 passed, 3 skipped
```

Las 3 omisiones corresponden a pruebas PostgreSQL opcionales. Se ejecutaron también las pruebas aisladas financieras: 38 aprobadas.

Cobertura nueva comprobada:

- Campañas públicas sin correo, teléfono, biografía, cuenta de recaudo, checksums, referencias ni transacciones.
- Acceso anónimo a documentos privados rechazado con 401.
- Acceso de otro usuario rechazado con 404.
- Acceso del propietario y de `soporte` permitido.
- Intento de publicar un documento privado mediante foto de perfil rechazado.
- Imagen pública de campaña continúa accesible.
- Límites de login, registro y carga devuelven 429.
- Health con base disponible devuelve 200 y con fallo controlado devuelve 503.
- Webhook con firma inválida devuelve 401 sin crear eventos ni alterar donaciones.
- El seed ya no crea el administrador predeterminado.

### Verificación en vivo

- Backend y PostgreSQL: `healthy`.
- `/api/health`: 200 con `database: ok`.
- Campañas públicas: sin campos privados.
- `GET /api/supports/campaign/1`: 401 sin autenticación.
- Imágenes públicas existentes: 200.
- Conteos de datos sin cambios.
- Wompi: sandbox, producción bloqueada.

### Flutter

- `flutter analyze`: 41 avisos informativos preexistentes, sin errores.
- `flutter test`: 50 pruebas aprobadas.

## 7. Estado del APK

APK original conservado y copiado como referencia:

- Original: `impactapp_flutter/build/app/outputs/apk/debug/app-debug.apk`
- Copia: `impactapp_flutter/build/app/outputs/apk/debug/app-debug-10.0.2.2.apk`
- SHA-256: `cee60d62ebcd56189f00be6ba1a588e7220f2977a8dad5d969b6dd9870f03983`

El APK actual sigue apuntando a `http://10.0.2.2:5000/api`. No se reconstruyó ni se sobrescribió.

Flutter lee la URL desde:

```dart
String.fromEnvironment('API_BASE_URL')
```

Comando pendiente, cuando exista una URL HTTPS real y se autorice:

```bash
cd impactapp_flutter
flutter build apk --debug \
  --dart-define=API_BASE_URL=<URL_HTTPS_DEL_TUNEL>/api
```

No se debe usar un dominio inventado ni incluir secretos en el APK.

## 8. Riesgos pendientes

1. La cuenta `soporte` existente todavía acepta la contraseña predeterminada. Es obligatorio rotarla antes de exponer el backend.
2. El limitador es en memoria y por proceso; no protege contra múltiples instancias.
3. Flask se ejecuta con el servidor de desarrollo de Werkzeug. Es aceptable solo para una ventana temporal y controlada.
4. Los archivos de tipo `foto` o `imagen` se consideran públicos por diseño. Los documentos de identidad deben usar tipos documentales.
5. Archivos locales antiguos sin registro en `ARCHIVO` se mantienen compatibles si están referenciados como imágenes públicas. No se recomienda mantener ese caso para archivos nuevos.
6. El túnel expondría todas las rutas del backend. No existe autenticación adicional en la capa de túnel.
7. CORS no incluye el dominio del túnel; el APK no depende de CORS, pero una prueba desde navegador sí requeriría configurarlo.

## 9. Rotación de contraseña de soporte

Procedimiento interactivo:

```bash
docker exec -it impactapp_backend python scripts/rotate_support_password.py
```

El script solicita el correo del usuario `soporte`, pide la nueva contraseña dos veces, valida la política y no imprime ni registra el valor. No se ejecutó durante esta preparación porque modificaría una cuenta existente.

## 10. Criterios antes de abrir el túnel

1. Rotar la contraseña del usuario `soporte` y verificar el acceso con la nueva credencial.
2. Confirmar una ventana de exposición corta y monitorear los logs.
3. Abrir el túnel solo hacia `127.0.0.1:5000`, nunca hacia PostgreSQL.
4. Obtener la URL HTTPS real asignada.
5. Reconstruir el APK con esa URL.
6. Detener el túnel al finalizar las pruebas.

Comando previsto, no ejecutado:

```bash
cloudflared tunnel --url http://127.0.0.1:5000 --no-autoupdate
```

No se conoce ni se inventó una URL pública. El túnel permanece cerrado.

## 11. Actualización: rotación de soporte endurecida

Se realizó una segunda revisión del procedimiento de rotación antes de ejecutarlo. No se rotó ninguna credencial real.

### Respaldo previo

- Archivo: `/tmp/opencode/impactapp_20261021_163641.dump`
- Formato: `pg_dump --format=custom`
- Tamaño: 56 986 bytes
- SHA-256: `ea5baae07d8be26ff139603965096b78d67112a276a35693d71069e49e9df90d`
- Verificación: `pg_restore --list` listó 158 entradas.

### Cambios aplicados

- El script ya no importa `app` ni ejecuta `create_app()`, `db.create_all()`, migraciones o `seed_database()`.
- Usa una conexión SQLAlchemy directa y una sesión independiente.
- Exige TTY antes de leer el correo o cualquier secreto; sin TTY aborta.
- Exige `DATABASE_URL` configurada y no usa el fallback SQLite.
- Busca exactamente una cuenta con correo normalizado, rol `soporte` y estado `activo`.
- Mantiene `getpass`, la validación existente y el hash bcrypt.
- Actualiza la contraseña, incrementa `token_version` y crea la auditoría en una sola transacción.
- Si falla la inserción de auditoría o el commit, se hace rollback completo: no queda contraseña nueva ni auditoría parcial.
- La auditoría usa una acción genérica, el identificador del usuario y una descripción sin correo, contraseña, hash ni token.

### Revocación de JWT

Se añadió `USUARIO.token_version` y el claim `token_version` en los tokens nuevos. Un verificador de JWT compara el claim con la versión actual del usuario:

- Tokens antiguos sin claim se interpretan como versión `0`.
- Al rotar una cuenta, su versión aumenta y solo sus tokens anteriores quedan revocados.
- Los tokens de otros usuarios sin claim siguen siendo válidos porque su versión permanece en `0`.
- Los tokens nuevos de la cuenta rotada incluyen la versión actual y siguen funcionando.

La migración `ensure_user_schema()` añadió la columna en la base real durante el reinicio del backend. Todos los usuarios existentes quedaron en versión `0`.

La revocación se comprobó con pruebas aisladas: token anterior de soporte rechazado; token antiguo sin claim de soporte rechazado; tokens de organizador y donante siguen válidos; login con contraseña anterior rechazado; login con contraseña nueva y token nuevo aceptados.

### Pruebas

Suite backend completa:

```text
293 passed, 3 skipped
```

Incluye pruebas nuevas de:

- Rotación de solo la cuenta objetivo.
- Incremento de versión y revocación de tokens anteriores.
- Invariabilidad de contraseñas de otros usuarios.
- Invariabilidad de conteos de usuarios, campañas, donaciones y soportes.
- Rechazo de cuenta inactiva o inexistente.
- Rechazo de contraseña débil sin cambios ni auditoría.
- Rollback cuando la auditoría no puede guardarse.
- Aborto del script cuando no hay TTY.

### Verificación en la base real

- Columna `token_version`: integer, `NOT NULL`, valor por defecto `0`.
- Usuarios: 9, todos con versión `0`.
- Conteos: usuarios 9, campañas 8, donaciones 3, soportes 3.
- Backend y PostgreSQL: `healthy`.
- `/api/health`: 200 con `database: ok`.

### Efectos secundarios y riesgos restantes

- La verificación de tokens realiza una consulta adicional a `USUARIO` por solicitud autenticada.
- El script no identifica al operador humano en la auditoría; solo registra la cuenta afectada y la acción.
- La rotación sigue dependiendo de acceso al contenedor y de una TTY segura.
- Los tokens de otros usuarios no se invalidan, por diseño.
- Si el proceso se interrumpe antes del commit, no se aplica ningún cambio.
- La cuenta `soporte` existente aún no ha sido rotada; la contraseña predeterminada debe cambiarse antes de exponer el backend.

### Comando exacto para la rotación posterior

```bash
docker exec -it -w /app impactapp_backend python scripts/rotate_support_password.py
```

El script pedirá el correo, la nueva contraseña y su confirmación. No se debe ejecutar sin TTY ni pasar contraseñas por argumentos o variables de entorno.

## 12. Corrección del modo de ejecución del script de rotación

El comando real `python scripts/rotate_support_password.py` fallaba porque Python agregaba `/app/scripts` al inicio de `sys.path`, pero no `/app`, y el script importaba `config` como módulo raíz.

Corrección aplicada:

- El script calcula la raíz del backend con `Path(__file__).resolve().parents[1]`.
- Inserta esa ruta explícitamente en `sys.path` antes de importar `config` y `services`.
- No depende del directorio de trabajo ni de `PYTHONPATH`.
- No importa `app.py` ni ejecuta inicialización, migraciones o seed.

Pruebas nuevas:

- Ejecución real del script con `cwd=/app`, sin `PYTHONPATH`, abortando únicamente por falta de TTY.
- Ejecución desde un directorio temporal con la ruta absoluta del script.
- Importación del módulo en un subproceso verificando que `app` no entra en `sys.modules`.
- Suite completa: `296 passed, 3 skipped`.

El script no fue ejecutado para una rotación real. La auditoría de rotación y los cambios de contraseña reales siguen en cero.

## 13. Servidor WSGI temporal y exposición

Gunicorn 22.0.0 ya estaba instalado en la imagen. Para evitar exponer Werkzeug se añadió temporalmente al servicio `backend`:

```yaml
command: ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "1", "--threads", "4", "--timeout", "60", "app:app"]
```

No se reconstruyó la imagen ni se reinició PostgreSQL. El contenedor backend se recreó con `docker compose up -d --no-deps --no-build backend`.

Reversión, una vez terminadas las pruebas:

1. Eliminar la línea `command:` del servicio `backend` en `docker-compose.yml`.
2. Ejecutar `docker compose up -d --no-deps --no-build backend`.
3. Confirmar el regreso al comando original `flask run --host=0.0.0.0 --port=5000`.

La URL temporal del túnel no se registra en este documento ni en Git.

Comprobaciones de rotación de soporte:

- La contraseña por defecto ya no coincide con el hash almacenado.
- `token_version` de la cuenta soporte es `1`.
- Existe una auditoría `ROTACION_CONTRASENA_SOPORTE`.
- Un token legacy sin claim de soporte responde `401`.
- No hay un evento `LOGIN` posterior a la rotación en la auditoría; la nueva contraseña no se verificó directamente por no disponer de ella.
