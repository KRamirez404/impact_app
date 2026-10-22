# ImpactApp

Aplicación full-stack de donaciones solidarias para Colombia. Conecta donantes con campañas sociales verificadas, permitiendo crear, explorar y apoyar iniciativas con donaciones económicas o en especie.

---

## Stack

| Capa | Tecnología |
|---|---|
| **Backend** | Flask + SQLAlchemy + PostgreSQL + JWT + bcrypt + Flask-CORS + Gunicorn |
| **Pagos** | Wompi Checkout Web (Sandbox; métodos según disponibilidad) |
| **Frontend** | Flutter 3.47+ (Android/iOS/Web/Linux) + GetX (state, routes) + Dio (HTTP) + GetStorage (local) |
| **Infra** | Docker Compose, PostgreSQL 16, Nginx + Certbot, Python 3.12 |
| **Pruebas** | pytest (backend) |

> Roles de usuario: `donante`, `organizador` y `soporte`. `donante` apoya campañas; `organizador` crea campañas; `soporte` (asignado centralmente) verifica y aprueba campañas en el panel de soporte.

---

## Diseño (Figma)

Interfaz inspirada en diseño mobile-first (412×917px) con los siguientes screens implementados:

### Login
- Gradiente de fondo azul/verde suave (`#EFF6FF` → `#F0FDF4`)
- Logo ImpactApp + eslogan "Donaciones con propósito"
- Card blanca con sombra y borde sutil (radius 16px)
- Campos: Correo electrónico + Contraseña (con toggle de visibilidad)
- Botón azul `#1976D2` "Iniciar Sesión"
- Link "¿No tienes cuenta? Regístrate aquí"

### Registro
- Mismo estilo que Login
- Campos: Nombre, Apellido, Correo, Teléfono, Contraseña
- Selector de rol: **Donante** / **Organizador**
- Checkbox obligatorio de aceptación de la Política de Tratamiento de Datos (Ley 1581)
- Navegación por teclado con `TextInputAction.next`

### Home
- **Top bar** azul `#1976D2` con logo ImpactApp y notificaciones
- **Hero** con saludo personalizado y gradiente
- **Stats cards** (3 columnas): Activas (azul), Verificadas (verde), Urgentes (naranja)
- **Top Donadores**: carrusel horizontal con tarjetas de donantes destacados
- **Por alcanzar la meta**: carrusel horizontal de campañas cerca del objetivo (>50%)
- **Campañas Recientes**: lista vertical con tarjetas expandidas
- **Bottom nav**: Inicio, Explorar, Crear, Perfil (con indicador azul en activo)

### Campaign Card
- Imagen con gradiente según categoría (colores únicos por tipo)
- Badge "Verificada" + badge de categoría
- Título, descripción, ubicación (📍), donantes (👥)
- Monto recaudado vs meta, barra de progreso azul
- Días restantes, puntos de recolección, visualizaciones
- Overlay "Meta Alcanzada" para campañas completadas

---

## Requisitos

- Docker y Docker Compose
- Flutter 3.47+ (`flutter --version`)
- `lld` linker (`sudo apt install lld-18`)
- Python 3.12+ (solo para backend local)
- Android SDK + Java 17+ (solo para compilar el APK)
- libmagic para detectar el contenido de archivos (instalado en las imágenes
  Docker; para backend local en Debian/Ubuntu: `sudo apt install libmagic1`)

---

## Ejecución rápida

```bash
# 1. Variables de entorno
cp .env.example .env

# 2. Backend (Docker)
docker compose up --build -d

# 3. Verificar
curl http://localhost:5000/api/health

# 4. Frontend Flutter (escritorio Linux)
cd impactapp_flutter
mkdir -p build/native_assets/linux
flutter run -d linux --dart-define=API_BASE_URL=http://localhost:5000/api

# 5. Frontend Flutter (Android - emulador)
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

> **Importante:** el emulador Android accede al backend de tu máquina por `10.0.2.2`; en un dispositivo físico usa la IP LAN del equipo.

---

## Pruebas (backend)

La suite `pytest` valida registro, autenticación, perfil/ciudad, asignación de roles,
control de acceso, verificación documental, cuenta de recaudo, anonimización,
archivos y auditoría/checksum. No sustituye la evaluación integral de privacidad.

```bash
make test                        # dentro del contenedor
docker compose exec backend python -m pytest tests -q   # alternativa
```

Anexos: [`docs/trazabilidad_requisitos.md`](docs/trazabilidad_requisitos.md) y [`docs/informe_seguridad_usabilidad.md`](docs/informe_seguridad_usabilidad.md).

Verificación del plan y correcciones de cierre:
[`docs/verificacion_plan.md`](docs/verificacion_plan.md). El 11/10/2026 se
ejecutaron **95 casos backend aprobados** con Python 3.12 y SQLite aislado,
incluyendo **31 casos de validación de archivos**. Posteriormente se construyó
y levantó Docker Compose y `make test-postgres` aprobó los **95 casos** en
PostgreSQL 16.15, usando la base aislada `impactapp_test`. Ambos servicios
quedaron saludables. La imagen de producción no se construyó en esta verificación.

Después de detener los servicios se completaron registro/perfil: **140 casos
backend aprobados en SQLite** y **45 pruebas Flutter aprobadas**. Estos cambios
nuevos todavía requieren prueba de integración PostgreSQL/Android. La matriz
vigente usa los códigos del PDF: [`docs/trazabilidad_requisitos.md`](docs/trazabilidad_requisitos.md).
Decisiones de pagos pendientes: [`docs/decisiones_cierre.md`](docs/decisiones_cierre.md).

---

## Generación del APK (Android)

Requisito: Android SDK y Java configurados (`flutter doctor` sin errores en la sección Android).

```bash
cd impactapp_flutter

# APK debug para emulador (10.0.2.2 = host visto desde el emulador)
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
# Salida: build/app/outputs/flutter-apk/app-debug.apk

# APK debug para móvil físico en la misma red Wi-Fi (usa la IP local del equipo)
flutter build apk --debug --split-per-abi \
  --dart-define=API_BASE_URL=http://192.168.1.10:5000/api
# Salida: build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk (la mayoría de móviles)

# APK release (firma con keystore propio)
flutter build apk --release --dart-define=API_BASE_URL=https://TU_BACKEND/api
```

> La URL compilada es solo el valor por defecto. En la pantalla de login, la opción **Configurar servidor** permite cambiarla en tiempo de ejecución y probar la conexión (`/api/health`) sin recompilar el APK.
>
> El APK debug permite HTTP plano. Un APK release bloquea tráfico HTTP en Android; para pruebas locales usa debug o publica el backend con HTTPS.

---

### Usuario soporte

El código de inicialización no crea cuentas administrativas ni contraseñas conocidas. Para crear o rotar una cuenta con rol `soporte`, usa una contraseña única y ejecuta dentro del contenedor:

```bash
docker exec -it impactapp_backend python scripts/rotate_support_password.py
```

El script solicita correo y contraseña de forma interactiva, valida la política de contraseñas y no imprime el valor ingresado.

---

## Backend

### Docker (recomendado)

```bash
docker compose up --build -d          # Iniciar
docker compose logs -f backend        # Logs
docker compose exec backend bash      # Shell
docker compose down                   # Detener
docker compose down -v && make up     # Reset DB
```

### Local (sin Docker)

```bash
cd impactapp_backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

---

## Frontend

```bash
cd impactapp_flutter
flutter pub get
mkdir -p build/native_assets/linux
flutter run -d linux --dart-define=API_BASE_URL=http://localhost:5000/api

# Build release
flutter build linux --dart-define=API_BASE_URL=http://localhost:5000/api
./build/linux/x64/release/bundle/impactapp_flutter
```

---

## Solución de problemas

| Error | Solución |
|---|---|
| `ld.lld` not found in `/usr/lib/llvm-18/bin` | `sudo apt install lld-18` |
| `kernel_blob.bin` permission denied | `docker run --rm -v "$PWD/impactapp_flutter/build:/build" alpine sh -c "rm -rf /build/*"` && `flutter clean` |
| `native_assets/linux` not found | `mkdir -p build/native_assets/linux` |
| Conexión al backend | `curl http://localhost:5000/api/health` |

---

## Comandos (Makefile)

| Comando | Descripción |
|---|---|
| `make up` | Build + inicio backend |
| `make dev` | Inicio backend (sin rebuild) |
| `make down` | Detener backend |
| `make logs` | Logs todos los servicios |
| `make backend-shell` | Shell interactiva contenedor |
| `make reset-db` | Reset completo de BD |
| `make run-linux` | Ejecutar Flutter Linux |
| `make flutter-clean` | Limpiar y reinstalar deps Flutter |

---

## API endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| `GET` | `/api/health` | — | Health check |
| `GET` | `/api/auth/privacy-policy` | — | Política de tratamiento de datos (Ley 1581) |
| `POST` | `/api/auth/register` | — | Registrar usuario (rol `donante`/`organizador`, acepta `acepta_tratamiento`) |
| `POST` | `/api/auth/login` | — | Iniciar sesión |
| `GET` | `/api/auth/me` | JWT | Perfil del usuario, incluida ciudad |
| `PUT` | `/api/auth/me` | JWT | Actualizar perfil |
| `DELETE` | `/api/auth/me` | JWT | Suprimir/anonimizar datos personales |
| `GET` | `/api/campaigns` | — | Listar campañas (filtros: ciudad, categoria, tipo_ayuda, estado) |
| `POST` | `/api/campaigns` | JWT* | Crear campaña (*rol `organizador`) |
| `GET` | `/api/campaigns/:id` | — | Detalle de campaña |
| `PUT` | `/api/campaigns/:id` | JWT* | Actualizar campaña (*rol `organizador`) |
| `DELETE` | `/api/campaigns/:id` | JWT* | Eliminar campaña (*rol `organizador`) |
| `GET` | `/api/cities` | — | Listar ciudades |
| `GET` | `/api/categories` | — | Listar categorías |
| `GET` | `/api/donations` | — | Listar donaciones |
| `POST` | `/api/donations` | JWT* | Crear donación en especie (*rol `donante`) |
| `POST` | `/api/donations/checkout` | JWT* | Iniciar donación económica con Wompi (*rol `donante`) |
| `GET` | `/api/donations/:id/status` | JWT | Estado de pago de una donación |
| `POST` | `/api/webhooks/wompi` | — | Webhook de eventos de Wompi (valida firma) |
| `GET` | `/api/donations/mine` | JWT | Mis donaciones (con avances/nuevos avances de cada campaña) |
| `GET` | `/api/donations/top` | — | Top donadores |
| `GET` | `/api/supports/campaign/:id` | — | Soportes de campaña |
| `POST` | `/api/supports` | JWT | Subir soporte (solo creador de la campaña) |
| `GET` | `/api/support/summary` | JWT* | Resumen panel soporte (*rol `soporte`) |
| `POST` | `/api/support/campaigns/:id/approve` | JWT* | Aprobar campaña (*rol `soporte`) |
| `POST` | `/api/support/campaigns/:id/reject` | JWT* | Rechazar campaña (*rol `soporte`) |
| `GET` | `/api/tracking/:campaign_id` | — | Seguimiento de campaña |
| `POST` | `/api/tracking` | JWT | Publicar avance (solo creador) |
| `GET` | `/api/ratings/:campaign_id` | — | Valoraciones |
| `POST` | `/api/ratings` | JWT | Crear valoración |
| `GET` | `/api/collection-points/:campaign_id` | — | Puntos de recolección |
| `POST` | `/api/collection-points` | JWT | Crear punto de recolección |
| `POST` | `/api/likes/toggle` | JWT | Dar o quitar like |

El perfil admite `id_ciudad` opcional, obtenido de `GET /api/cities`; `null`
elimina la selección. Las respuestas de registro, login y perfil incluyen
`id_ciudad` y el objeto `ciudad`. La migración añade el campo a bases existentes.
Nombres y apellidos se editan por separado para conservar nombres compuestos.

---

## Estructura del proyecto

```
impact_app/
├── impactapp_backend/              # API Flask
│   ├── app.py                      # Entry point + seed data
│   ├── config.py                   # Configuración
│   ├── models/                     # SQLAlchemy models
│   │   ├── user.py                 #   USUARIO
│   │   ├── campaign.py             #   CAMPAÑA (con relaciones)
│   │   ├── category.py             #   CATEGORIA
│   │   ├── city.py                 #   CIUDAD
│   │   ├── donation.py             #   DONACION
│   │   ├── collection_point.py     #   PUNTO_RECOLECCION
│   │   ├── tracking.py             #   SEGUIMIENTO
│   │   ├── support.py              #   SOPORTE
│   │   └── rating.py               #   VALORACION
│   ├── routes/                     # Blueprints
│   │   ├── auth_routes.py
│   │   ├── campaign_routes.py
│   │   ├── donation_routes.py
│   │   ├── collection_point_routes.py
│   │   ├── tracking_routes.py
│   │   ├── support_routes.py
│   │   └── rating_routes.py
│   ├── services/                   # Lógica de negocio
│   ├── Dockerfile
│   └── requirements.txt
├── impactapp_flutter/              # App Flutter
│   ├── lib/
│   │   ├── main.dart               # Entry point
│   │   ├── app/
│   │   │   ├── app.dart            # GetMaterialApp + tema
│   │   │   └── routes/             # app_pages.dart, app_routes.dart
│   │   ├── core/
│   │   │   ├── constants/          # API constants, storage keys
│   │   │   ├── error/              # Manejo de errores
│   │   │   ├── network/            # Dio client
│   │   │   └── utils/              # Validators
│   │   ├── features/
│   │   │   ├── auth/               # Login, registro, perfil
│   │   │   ├── campaigns/          # Home, listado, detalle, donación
│   │   │   ├── collection_points/  # Puntos de recolección
│   │   │   ├── home/               # Home page principal
│   │   │   ├── ratings/            # Valoraciones
│   │   │   └── verification/       # Soportes
│   │   └── shared/
│   │       ├── theme/              # AppTheme, AppColors
│   │       └── widgets/            # CustomTextField, CustomButton,
│   │                                # CampaignCard, BottomNavBar, ProgressBar
│   └── pubspec.yaml
├── docker-compose.yml
├── Makefile
└── .env
```

---

## Arquitectura Frontend

```
features/{modulo}/
├── domain/
│   ├── entities/              # Modelos de dominio
│   └── usecases/              # Casos de uso
├── infrastructure/
│   ├── datasources/           # Llamadas HTTP
│   ├── models/                # DTOs con fromJson
│   └── repositories/          # Implementación repositorio
└── presentation/
    ├── bindings/              # GetX bindings (DI)
    ├── controllers/           # GetX controllers (estado)
    └── pages/                 # Widgets de pantalla
```

Patrón **Clean Architecture** con GetX para inyección de dependencias y estado reactivo.

---

---

## Análisis de Arquitectura y Plataforma

### Patrón Hexagonal ✅

Cumple con Clean Architecture / Puertos y Adaptadores:

| Capa | Rol | Ejemplo (`features/auth/`) |
|---|---|---|
| `domain/` | Núcleo de negocio | `entities/user_entity.dart`, `repositories/auth_repository.dart` (abstracto), `usecases/` |
| `infrastructure/` | Adaptadores técnicos | `datasources/auth_remote_datasource.dart`, `repositories/auth_repository_impl.dart`, `models/user_model.dart` |
| `presentation/` | Interfaz de usuario | `pages/login_page.dart`, `controllers/auth_controller.dart`, `bindings/auth_binding.dart` |

La inyección de dependencias respeta el principio de inversión: `domain` nunca importa `infrastructure`.

### GetX State Management ✅

| Aspecto | Implementación |
|---|---|
| App raíz | `GetMaterialApp` en `app.dart` |
| Controladores | `GetxController` con variables `.obs` y `Rxn<>` |
| DI | `Bindings` con `Get.lazyPut<>()` y `Get.find<>()` |
| Navegación | `Get.offAllNamed()`, `Get.toNamed()` |
| Notificaciones | `Get.snackbar()` |

### Conexión a Base de Datos ✅

- **Cliente HTTP:** `Dio` con singleton `DioClient` (`lib/core/network/dio_client.dart`)
- **Interceptor:** Agrega `Bearer token` automáticamente desde `GetStorage`
- **Error handling:** Redirige a login en 401
- **Backend:** Flask + SQLAlchemy + PostgreSQL corriendo en `localhost:5000`

### Almacenamiento Local (GetStorage) ✅

Usa `get_storage` en lugar de `shared_preferences` (equivalente funcional, más rápido):

- Inicializado en `main()` con `await GetStorage.init()`
- Almacena `token` y `user` (JSON) vía `StorageKeys`
- Usado en: `AuthRepositoryImpl` (persistir sesión), `DioClient` (leer token)

### Estado de compatibilidad móvil

El proyecto tiene bases nativas Android/iOS y adaptación parcial; la entrega
requiere configuración, compilación e instalación verificadas:

| Aspecto | Estado |
|---|---|
| Carpetas `android/` e `ios/` | ✅ Existen |
| Diseño responsivo | ⚠️ Parcial; persisten dimensiones fijas y falta prueba en dispositivos |
| Medidas relativas / restricciones de ancho | ⚠️ Presentes en parte de la interfaz |
| Adaptación por plataforma | ❌ Sin `Platform` ni `TargetPlatform` |
| `SafeArea` / ScrollViews | ✅ Correcto |
| Touch gestures | ⚠️ Parcial |

> **Nota:** La presencia de proyectos nativos no acredita un APK funcional.
> Las pruebas Flutter locales no sustituyen la ejecución Android. Ver etapa 5 de `Plan_Cierre.txt`.

---

## Plan de migración a Móvil (Android/iOS)

### 1. Verificar herramientas y plataformas existentes

```bash
cd impactapp_flutter
flutter doctor
```

### 2. Refactorizar a diseño responsivo

Reemplazar tamaños fijos por valores relativos:

| Archivo | Cambio |
|---|---|
| `login_page.dart:96` | `width: 378.4` → `MediaQuery.of(context).size.width * 0.9` |
| `campaign_card.dart:106` | `height: 192` → `MediaQuery.of(context).size.height * 0.24` |
| `custom_button.dart:15-16` | `width: double.infinity` (ya OK), `height: 36` → `50` (estándar touch) |
| `home_page.dart:369` | `width: 340` → `MediaQuery.of(context).size.width * 0.85` |
| `home_page.dart:297` | `width: 124` → `(MediaQuery.of(context).size.width - 48) / 3` |
| `bottom_nav_bar.dart:48` | `width: 24` → mantener, es decorativo |

### 3. Agregar adaptaciones por plataforma

- Usar `Theme.of(context).platform` o `defaultTargetPlatform` para switchear entre Material (Android) y Cupertino (iOS)
- Ajustar `AppTheme.lightTheme` con valores específicos por SO

### 4. Touch targets

- Botones: mínimo `48px` de altura (actual `36px` en `CustomButton`)
- Iconos táctiles: `splashRadius` mínimo `20`

### 5. Safe areas y notch

Ya se usa `SafeArea` correctamente en la mayoría de pantallas. Verificar en todas las pages.

### 6. Probar en dispositivos reales

```bash
flutter run -d android     # Android físico/emulador
flutter run -d ios         # iOS (requiere macOS + Xcode)
```

---

## Nota

No ejecutar `flutter run` desde la raíz del repositorio. Siempre hacer `cd impactapp_flutter` primero.

---

## Donaciones con Wompi

Las donaciones económicas se procesan con **Wompi Checkout Web**. El flujo es:

1. El donante elige el monto; `POST /api/donations/checkout` valida campaña, rol, moneda e importe, crea la donación en `pendiente` y devuelve una `checkout_url` firmada con el secreto de integridad.
2. Flutter envía una `Idempotency-Key` estable por intento y abre la pasarela oficial (`https://checkout.wompi.co/p/`) en el navegador.
3. Wompi notifica `transaction.updated` a `POST /api/webhooks/wompi`. El backend verifica el checksum, el ambiente, consulta la transacción autoritativa con la llave privada, compara id/referencia/monto/moneda y solo entonces actualiza la donación.
4. La app consulta `GET /api/donations/:id/status`. La redirección o la pantalla de retorno **no** confirman el pago.
5. Cada evento válido se registra en `PAGO_EVENTO` con una huella única y el resultado (`aplicado`, `ignorado`, `sin_donacion`). No se guardan payloads completos, correos, secretos ni checksums completos.

Solo las donaciones económicas con `estado_pago = "aprobada"` cuentan para la meta y el top de donadores. Las donaciones en especie siguen usando `POST /api/donations`. Las transferencias bancarias directas son un flujo separado y no se validan con credenciales Wompi.

### Configuración Sandbox

```bash
WOMPI_ENV=sandbox
WOMPI_ALLOW_PRODUCTION=0
WOMPI_PUBLIC_KEY=pub_test_...
WOMPI_PRIVATE_KEY=prv_test_...
WOMPI_INTEGRITY_SECRET=test_integrity_...
WOMPI_EVENTS_SECRET=test_events_...
WOMPI_CHECKOUT_URL=https://checkout.wompi.co/p/
WOMPI_API_URL=https://sandbox.wompi.co/v1
```

El backend rechaza configuraciones incompletas, llaves de producción en Sandbox, URLs distintas de las oficiales, monedas distintas de COP y producción salvo que `WOMPI_ALLOW_PRODUCTION=1`. El diagnóstico seguro se ejecuta con:

```bash
make wompi-check
# o, sin Docker:
cd impactapp_backend && .venv/bin/python scripts/check_wompi_config.py
```

No se imprimen valores de credenciales. Si faltan llaves, el checkout y el webhook responden 503 sin modificar donaciones.

> Con llaves de Sandbox **no se cobra dinero real**. Producción está bloqueada por defecto y no forma parte de esta entrega.

### Webhook en Sandbox

Wompi exige una URL HTTPS pública. Para desarrollo local:

```bash
# Opción con cloudflared (instalar aparte; no se guarda el token en el repo)
cloudflared tunnel --url http://localhost:5000
```

Registra en el Dashboard de Wompi, ambiente Sandbox, la URL:

```text
https://<URL-DEL-TUNEL>/api/webhooks/wompi
```

Cierra el túnel al terminar. No publiques otros endpoints. Si no hay túnel ni URL pública, el webhook real no puede llegar: las pruebas automatizadas usan un proveedor simulado explícito y no acreditan una transacción Sandbox real.

### Prueba manual en Sandbox

1. Completa las cuatro credenciales `test_` en `.env` y ejecuta `make up`.
2. Ejecuta `make wompi-check` y confirma `configurado=si`.
3. Levanta Flutter con `API_BASE_URL=http://localhost:5000/api` y abre una campaña activa.
4. Inicia una donación y paga en el checkout Sandbox con los datos oficiales:
   - Tarjeta `4242 4242 4242 4242`: aprobada.
   - Tarjeta `4111 1111 1111 1111`: declinada.
   - Nequi `3991111111`: aprobada; `3992222222`: declinada.
   - PSE: usa el banco de prueba que aprueba o rechaza, si está disponible para el comercio.
5. Verifica en la app y en `GET /api/donations/:id/status`. La donación permanece `pendiente` hasta que el backend procese el webhook o consulte la transacción con el identificador autoritativo.

No se debe usar un webhook falso para aprobar pagos: el backend exige la consulta autoritativa a Wompi. El script `scripts/simulate_wompi_webhook.py` solo conserva el comando `create` para crear una donación pendiente local; `run`/`notify` están bloqueados.

---

## Despliegue en producción (VPS)

1. Copia `.env.production.example` a `.env.production` y completa dominio, base de datos, JWT y llaves Wompi.
2. Apunta el DNS del dominio al VPS y asegura los puertos 80/443.
3. Levanta el stack:

```bash
make prod-up        # docker compose --env-file .env.production -f docker-compose.prod.yml up --build -d
make prod-ps        # estado de los servicios
make prod-logs      # logs
```

Servicios: `db` (PostgreSQL), `backend` (Gunicorn), `web` (Nginx + Flutter Web) y `certbot`.

Para HTTPS, solicita el certificado con Certbot y habilita el bloque TLS:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml run --rm --entrypoint certbot certbot \
  certonly --webroot -w /var/www/certbot -d TU_DOMINIO --email TU_CORREO --agree-tos --no-eff-email
mv deploy/nginx/templates/app.conf.template deploy/nginx/templates/app.conf.template.bak
cp deploy/nginx/ssl/app.ssl.conf.template.disabled deploy/nginx/templates/app.conf.template
docker compose --env-file .env.production -f docker-compose.prod.yml restart web
```

El APK Android se compila apuntando al backend público:

```bash
cd impactapp_flutter
flutter build apk --release --dart-define=API_BASE_URL=https://TU_DOMINIO/api
```

---

## Trabajo futuro

Limitaciones asumidas para la entrega del prototipo y su justificación académica:

| Pendiente | Justificación |
|---|---|
| **Dispersión automática a organizadores** | Wompi recauda en la cuenta del comercio; la transferencia al organizador (Wompi "Pagos a terceros" o dispersión manual) queda pendiente de definir. |
| **Llaves de producción Wompi** | La integración corre en Sandbox (`pub_test_`); activar la cuenta de comercio y cambiar variables `WOMPI_*` habilita cobros reales. |
| **Cifrado en reposo de la base de datos** | Requiere administración de claves (KMS) y no afecta el funcionamiento del prototipo. |
| **TLS / HTTPS en producción** | Ya contemplado con Nginx + Certbot en `docker-compose.prod.yml`; requiere dominio apuntando al VPS. |
| **Auditoría de dependencias** (`pip-audit`, Dependabot) | Los `requirements.txt` y `pubspec.lock` están fijados; la revisión continua se hará al publicar. |
| **Notificaciones push** (FCM) | Requiere proyecto Firebase y certificados de aplicación móvil firmada. |
| **Verificación documental automática** | La validación de identidad hoy es lógica/por soporte; integrar validación con entidades estatales queda fuera de alcance. |
| **Firma del APK release** | El APK de demostración se compila en modo debug; la firma de producción necesita un keystore institucional. |
