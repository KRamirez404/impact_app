# ImpactaApp — Estado de despliegue y APK

Fecha: 21/10/2026. Rama: `feat/etapa-2-transferencias-comprobantes`.
HEAD: `47ed2f756384b13eb956a610e063777b7f7c6f49`.

Este informe registra la recuperación del backend, la verificación de datos, las pruebas ejecutadas, la compilación del APK y el plan de despliegue. No contiene secretos, tokens ni valores de `.env`.

## 1. Estado inicial

- Repositorio sin cambios versionados; solo artefactos no versionados preservados:
  `PROMPT_IMPLEMENTACIÓN.txt` y `graphify-out/`.
- `impactapp_backend` detenido con código `255`, `OOM=false`, sin mensaje en `State.Error`.
- `impactapp_db` saludable, PostgreSQL 16.15.
- Backend arrancado el 16/10 y terminado el 21/10 a las `18:34:29Z`.
- El contenedor viejo tenía las claves públicas/privadas de Wompi vacías y un redirect local distinto del `.env` actual.
- No existían Java, Android SDK, ADB ni Gradle en el entorno Linux.
- `TEST_DATABASE_URL` no estaba definida.

## 2. Diagnóstico del backend

El cierre coincide exactamente con el reinicio del daemon Docker del 21/10 a las `13:34:29 -05`
(`18:34:29Z`). El journal registra:

- `error unmounting container ... error="layer not mounted"`
- `Removing stale sandbox`

No hay traceback de Flask ni error de aplicación en los logs. La política era `restart: no`, por lo que el contenedor quedó detenido tras el evento de infraestructura. El diagnóstico es reinicio/restauración de Docker, no una excepción del backend; no se puede demostrar al 100 % la causa interna del `255`.

Corrección aplicada:

- `docker-compose.yml`: `restart: unless-stopped` únicamente en `backend`.
- Recreación exclusiva del backend con `docker compose up -d --force-recreate --no-deps backend`.
- PostgreSQL no se recreó: `StartedAt` permaneció sin cambios.

El backend quedó `Up`, healthcheck `healthy` y `GET /api/health` responde `200`.

## 3. Respaldo PostgreSQL

- Ruta: `~/impactapp_db_pre_recuperacion_20261021_143214.dump`
- Tamaño: `52.206` bytes
- SHA-256: `07a81f62b1ffe2d92917507997f8566148f657093f1c7e56b8c08cfeb53c355c`
- `pg_dump` salida: `0`
- `pg_restore --list`: salida `0`, 135 entradas TOC.
- No se sobrescribió el respaldo previo.
- No se restauró ningún respaldo sobre la base actual.

## 4. Esquema y datos

Conteos antes y después del arranque:

| Entidad | Antes | Después |
|---|---:|---:|
| USUARIO | 9 | 9 |
| CAMPAÑA | 8 | 8 |
| CIUDAD | 10 | 10 |
| CATEGORIA | 5 | 5 |
| DONACION | 3 | 3 |

Cambios de esquema aplicados por el arranque, de forma aditiva:

- Columna `DONACION.clave_checkout` (`varchar(64)`, nullable).
- Índice único `uq_donacion_wompi_transaction_id`.
- Índice único `uq_donacion_clave_checkout`.
- Duplicados de `wompi_transaction_id`: `0`.

Columnas legadas de transferencias/comprobantes (`comprobante_ruta`, `comprobante_hash`,
`referencia_transferencia`, `cuenta_destino`, `nota_validacion`, `id_validador`, etc.)
permanecen en la tabla, sin datos y sin cambios. No se eliminaron.

## 5. Verificación funcional y Wompi Sandbox

- `GET /api/health`: `200`.
- `GET /api/campaigns`: `200`, 6 campañas devueltas.
- `GET /api/donations/top?limit=5`: `200`.
- Login administrativo: `200`; no se guardó ni imprimió el token.
- `scripts/check_wompi_config.py`: `ambiente=sandbox`, `configurado=si`.
- Prefijos comprobados sin revelar valores: `pub_test_`, `prv_test_`, `test_integrity_`, `test_events_`.
- URL de checkout construida en memoria: host `checkout.wompi.co`, `https`, moneda `COP`, firma y redirect presentes. No se creó ninguna donación.
- Webhook con firma inválida: `401 {"error":"Firma de evento inválida"}`.
- Tras el webhook inválido: `PAGO_EVENTO=0` y `DONACION=3`, sin inserciones.
- No se realizaron pagos ni cobros reales.

## 6. Etapa 2 (transferencias y comprobantes)

Estado real: **no implementada funcionalmente**.

- No existen endpoints de transferencias, comprobantes o descargas privadas.
- No existen tablas ni modelos de transferencia/comprobante.
- Solo existen documentación de contrato y las asignaciones financieras de Fase B.
- `GET /api/donations/campaign/<id>` no expone comprobantes.
- Los totales de campaña solo suman donaciones económicas con `estado_pago="aprobada"`.

Por tanto no se puede auditar la seguridad de un flujo que no existe. Las columnas legadas están vacías.

## 7. Pruebas ejecutadas

| Prueba | Comando | Resultado |
|---|---|---|
| Configuración Wompi | `pytest tests/test_wompi_config.py` con SQLite temporal | 13 aprobadas, 0 fallidas |
| Regresión aislada SQLite | `python -B scripts/verificar_regresion_aislada.py` | 240 aprobadas, 3 omitidas |
| Financieras aisladas | `pytest --noconftest pruebas_aisladas/test_asignaciones_financieras.py` | 38 aprobadas |
| Suite completa PostgreSQL | `pytest tests` con base `impactapp_recovery_20261021_test` | 243 aprobadas |
| Flutter | `flutter test` | 50 aprobadas |
| Flutter analyze | `flutter analyze` | 41 avisos informativos, 0 errores/warnings |

Las 3 pruebas omitidas en SQLite requieren PostgreSQL y se ejecutaron en la base de pruebas aislada.
No se usó la base `impactapp` para pruebas destructivas.

## 8. Toolchain Android instalado

Instalación en espacio de usuario, sin `sudo`:

| Herramienta | Versión / ruta |
|---|---|
| Flutter | 3.47.2 (`~/fvm/versions/stable`) |
| Dart | 3.13.2 |
| JDK | Temurin 21.0.12.1+1 (`~/.local/opt/jdk-21`) |
| Android SDK | `~/Android/Sdk` |
| Platform | android-36 |
| Build-tools | 36.0.0 |
| NDK | 28.2.13676358 |
| Platform-tools / ADB | 37.0.1 |
| Gradle wrapper | 9.3.1 |
| AGP / Kotlin | 9.1.0 / 2.4.0 |

Checksums verificados:

- JDK SHA-256: `ce79869e1307ed8ee1e2baa86a412b1eb5b75d10a01006d788a6f968bcfaee94`.
- Command-line tools SHA-1: `e025545c62a8e64c7559119566a569fb1dec5f60`.

Gradle instaló automáticamente platforms 34/35 y CMake 3.22.1 requeridos por dependencias.
`flutter doctor` mantiene un aviso de licencias porque el nuevo Android CLI declara obsoleto
`sdkmanager --licenses`; la compilación funcionó y las licencias fueron aceptadas durante el build.

## 9. APK debug

- Ruta absoluta: `~/WorkSpace/impact_app/impactapp_flutter/build/app/outputs/apk/debug/app-debug.apk`
- Tamaño: `162.592.155` bytes (156 MB)
- SHA-256: `cee60d62ebcd56189f00be6ba1a588e7220f2977a8dad5d969b6dd9870f03983`
- ZIP íntegro: `unzip -t` sin errores.
- Paquete: `co.impactapp.impactapp_flutter`, versión `1.0.0` (`versionCode=1`).
- `minSdk=24`, `targetSdk=36`, `compileSdk=36`.
- Actividad lanzable: `co.impactapp.impactapp_flutter.MainActivity`.
- Arquitecturas: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- URL embebida: `http://10.0.2.2:5000/api` (emulador Android).
- `usesCleartextTraffic=true` solo en manifiesto debug.
- Firmado con clave debug; no es un APK de producción.

Instalación/prueba en dispositivo: **BLOQUEADA**. `adb devices -l` no detectó dispositivos.
No se creó ni arrancó un emulador por falta de autorización y por memoria limitada.

## 10. Cambios realizados

Archivos versionados:

1. `docker-compose.yml`: `restart: unless-stopped` en backend.
2. `impactapp_flutter/android/app/src/debug/AndroidManifest.xml`: cleartext HTTP solo en debug.
3. `impactapp_flutter/android/gradle.properties`: memoria de Gradle reducida de `-Xmx8G` a `-Xmx2G`
   para un equipo con 5,7 GB de RAM.

Fuera de Git:

- `impactapp_flutter/android/local.properties`: `sdk.dir` local (ignorado por Git).
- Toolchain en `~/.local/opt/jdk-21` y `~/Android/Sdk`.
- Evidencias en `/tmp/impactapp_deploy/`.

No se hicieron commits, push, merge ni cambios de rama.

## 11. Plan de despliegue en la nube (sin ejecutar)

No se publicaron servicios, túneles ni recursos de pago.

### Opción A — VPS pequeño (recomendada para demo persistente)

- 2 vCPU / 4 GB RAM / 40-80 GB SSD (Hetzner CX22 o similar).
- Docker Compose de producción con `backend` (Gunicorn), `db` (PostgreSQL sin puerto público),
  Nginx y Certbot; omitir `web` si solo se necesita la API del APK.
- Dominio con DNS al VPS; firewall solo 22/80/443; acceso SSH por clave.
- HTTPS con Certbot o Caddy.
- Respaldo diario `pg_dump` a almacenamiento externo (S3/R2/B2) con retención y restauración probada.
- Coste estimado: US$5-7/mes VPS + US$10-15/año dominio + US$0-2/mes respaldos.

### Opción B — PaaS (menos administración)

- Render/Fly/Railway con `Dockerfile.prod` y PostgreSQL gestionado.
- HTTPS automático; no requiere Nginx/Certbot.
- Coste estimado: US$0 en niveles gratuitos con suspensión/límites; US$7-15/mes para disponibilidad estable.
- Adaptar el compose y usar almacenamiento persistente para uploads.

### Configuración obligatoria antes de publicar

- Secretos en el gestor del proveedor o `.env.production` con permisos restringidos; nunca en Git.
- `ALLOWED_ORIGINS` al dominio público; la app nativa no depende de CORS.
- `API_BASE_URL=https://api.DOMINIO/api` al compilar Flutter.
- Webhook Wompi: `https://api.DOMINIO/api/webhooks/wompi` (cambio manual en el dashboard, requiere autorización).
- Gunicorn con 1 worker mientras el arranque ejecute DDL/seed; evaluar workers tras separar migraciones.
- Healthcheck: `/api/health` no consulta la BD. Añadir readiness con `SELECT 1` o usar el chequeo de la BD del proveedor.
- Backups cifrados, prueba de restauración y procedimiento de recuperación documentado.
- No exponer PostgreSQL a Internet.

### Bloqueo de comprobantes privados

`/uploads` es público y no existe almacenamiento privado de comprobantes. Antes de implementar
transferencias se requiere un volumen/bucket privado, claves aleatorias, descarga autenticada,
`Cache-Control: private, no-store`, `X-Content-Type-Options: nosniff` y validación de propiedad.
No se debe afirmar privacidad documental con la implementación actual.

## 12. Riesgos y pendientes

- El APK no se instaló ni se probó en un dispositivo real.
- El APK usa HTTP local y solo funciona con el backend accesible en `10.0.2.2:5000` desde un emulador.
- La app no tiene firma de release ni keystore institucional.
- El backend local sigue usando el servidor de desarrollo Flask; producción usa Gunicorn.
- La etiqueta de la app es `impactapp_flutter`; no se cambió.
- El aviso de licencias de `flutter doctor` es cosmético en este entorno, pero conviene revisarlo en CI.
- La etapa 2 de transferencias/comprobantes sigue sin implementación funcional.
- Wompi permanece en Sandbox; no se probó una transacción real ni un webhook público.
- El `restart` se aplicó solo al backend; PostgreSQL local no tiene política de reinicio.

## 13. Comandos manuales útiles

Fish:

```fish
set -gx JAVA_HOME $HOME/.local/opt/jdk-21
set -gx ANDROID_HOME $HOME/Android/Sdk
set -gx ANDROID_SDK_ROOT $ANDROID_HOME
fish_add_path $JAVA_HOME/bin $ANDROID_HOME/platform-tools
```

Instalar el APK cuando haya un dispositivo autorizado:

```bash
adb devices -l
adb install -r ~/WorkSpace/impact_app/impactapp_flutter/build/app/outputs/apk/debug/app-debug.apk
adb shell monkey -p co.impactapp.impactapp_flutter -c android.intent.category.LAUNCHER 1
```

Recompilar para un backend HTTPS:

```bash
cd ~/WorkSpace/impact_app/impactapp_flutter
flutter build apk --debug --dart-define=API_BASE_URL=https://api.TU_DOMINIO/api
```

## 14. Estado final

| Objetivo | Estado | Evidencia |
|---|---|---|
| Respaldo PostgreSQL | COMPLETADO | `~/impactapp_db_pre_recuperacion_20261021_143214.dump`, 52.206 bytes, SHA-256 `07a81f…355c`, `pg_restore --list` OK |
| Backend | COMPLETADO | `Up (healthy)`, `/api/health` 200, restart `unless-stopped` |
| Integridad de datos | COMPLETADO | Conteos 9/8/10/5/3 sin cambios; `clave_checkout` e índices únicos creados; 0 duplicados |
| Pruebas backend | COMPLETADO | 13 Wompi, 240+3 SQLite, 38 financieras, 243 PostgreSQL |
| APK debug | COMPLETADO | Ruta y SHA-256 en la sección 9 |
| Instalación Android | BLOQUEADO | Sin dispositivos en `adb devices`; no se autorizó emulador |
| Nube y HTTPS | PREPARADO | Plan y bloqueos documentados; nada publicado |
| Informe | COMPLETADO | `docs/despliegue_apk_estado.md` |
