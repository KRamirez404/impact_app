# ImpactApp

Aplicación full-stack de donaciones solidarias para Colombia. Conecta donantes con campañas sociales verificadas, permitiendo crear, explorar y apoyar iniciativas con donaciones económicas o en especie.

---

## Stack

| Capa | Tecnología |
|---|---|
| **Backend** | Flask + SQLAlchemy + PostgreSQL + JWT + bcrypt + Flask-CORS + Gunicorn |
| **Pagos** | Wompi (Checkout Web: tarjetas, PSE y Nequi) |
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

La suite `pytest` valida registro, autenticación, asignación de roles, control de acceso, verificación de identidad, cuenta de recaudo, privacidad (Ley 1581) y auditoría/checksum.

```bash
make test                        # dentro del contenedor
docker compose exec backend python -m pytest tests -q   # alternativa
```

Anexos: [`docs/trazabilidad_requisitos.md`](docs/trazabilidad_requisitos.md) y [`docs/informe_seguridad_usabilidad.md`](docs/informe_seguridad_usabilidad.md).

---

## Generación del APK (Android)

Requisito: Android SDK y Java configurados (`flutter doctor` sin errores en la sección Android).

```bash
cd impactapp_flutter

# APK debug (demostración / instalación directa)
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
# Salida: build/app/outputs/flutter-apk/app-debug.apk

# APK release (firma con keystore propio)
flutter build apk --release --dart-define=API_BASE_URL=https://TU_BACKEND/api
```

> Para conectar un dispositivo físico al backend durante la demo, reemplaza `10.0.2.2` por la IP local del equipo (p. ej. `http://192.168.1.10:5000/api`).

---

### Usuario admin precargado

| Campo | Valor |
|---|---|
| Correo | `admin@impactapp.co` |
| Contraseña | `Admin123*` |

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
| `GET` | `/api/auth/profile` | JWT | Perfil del usuario |
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

### Optimización para Móvil ❌

El proyecto **no está optimizado para Android/iOS**:

| Aspecto | Estado |
|---|---|
| Carpetas `android/` e `ios/` | ❌ No existen |
| Diseño responsivo | ❌ Tamaños fijos (`width: 378.4`, `width: 340`, `height: 36`) |
| `MediaQuery` / `LayoutBuilder` | ❌ No se usan |
| Adaptación por plataforma | ❌ Sin `Platform` ni `TargetPlatform` |
| `SafeArea` / ScrollViews | ✅ Correcto |
| Touch gestures | ⚠️ Parcial |

> **Nota:** El Dockerfile compila para `web` y la ejecución principal es `linux desktop`. No hay soporte nativo para dispositivos móviles.

---

## Plan de migración a Móvil (Android/iOS)

### 1. Agregar plataformas

```bash
cd impactapp_flutter
flutter create --platforms=android,ios .
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

1. El donante elige el monto en la app; `POST /api/donations/checkout` crea la donación en estado `pendiente` y devuelve una `checkout_url` firmada con el secreto de integridad.
2. La app abre la pasarela (`https://checkout.wompi.co/p/`) en el navegador.
3. Wompi notifica el resultado vía webhook a `POST /api/webhooks/wompi`; el backend valida el checksum del evento (`WOMPI_EVENTS_SECRET`), actualiza `estado_pago` y recalcula el avance de la campaña solo si el pago fue `APPROVED`.
4. La app consulta `GET /api/donations/:id/status` para mostrar el resultado.

Solo las donaciones económicas con `estado_pago = "aprobada"` cuentan para la meta y el top de donadores. Las donaciones en especie siguen usando `POST /api/donations`.

Variables de entorno (Sandbox):

```bash
WOMPI_ENV=sandbox
WOMPI_PUBLIC_KEY=pub_test_...
WOMPI_PRIVATE_KEY=prv_test_...
WOMPI_INTEGRITY_SECRET=test_integrity_...
WOMPI_EVENTS_SECRET=test_events_...
WOMPI_CHECKOUT_URL=https://checkout.wompi.co/p/
WOMPI_API_URL=https://sandbox.wompi.co/v1
```

> Con llaves de Sandbox **no se cobra dinero real**. Para cobros reales se requiere la cuenta de comercio Wompi aprobada y cambiar a llaves `pub_prod_`/`prv_prod_`, `WOMPI_ENV=prod` y `WOMPI_API_URL=https://production.wompi.co/v1`. Registra la URL de eventos de producción en el Dashboard de Wompi.

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
