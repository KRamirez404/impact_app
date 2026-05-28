# ImpactApp

Aplicación full-stack de donaciones solidarias para Colombia. Conecta donantes con campañas sociales verificadas, permitiendo crear, explorar y apoyar iniciativas con donaciones económicas o en especie.

---

## Stack

| Capa | Tecnología |
|---|---|
| **Backend** | Flask + SQLAlchemy + SQLite + JWT + bcrypt + Flask-CORS |
| **Frontend** | Flutter 3.41 + GetX (state, routes) + Dio (HTTP) + GetStorage (local) |
| **Infra** | Docker Compose, Python 3.12, Linux Desktop |

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
- Flutter 3.41+ (`flutter --version`)
- `lld` linker (`sudo apt install lld-18`)
- Python 3.12+ (solo para backend local)

---

## Ejecución rápida

```bash
# 1. Variables de entorno
cp .env.example .env

# 2. Backend (Docker)
docker compose up --build -d

# 3. Verificar
curl http://localhost:5000/api/health

# 4. Frontend Flutter
cd impactapp_flutter
mkdir -p build/native_assets/linux
flutter run -d linux --dart-define=API_BASE_URL=http://localhost:5000/api
```

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
| `POST` | `/api/auth/register` | — | Registrar usuario |
| `POST` | `/api/auth/login` | — | Iniciar sesión |
| `GET` | `/api/auth/profile` | JWT | Perfil del usuario |
| `GET` | `/api/campaigns` | — | Listar campañas (filtros: ciudad, categoria, tipo_ayuda, estado) |
| `POST` | `/api/campaigns` | JWT | Crear campaña |
| `GET` | `/api/campaigns/:id` | — | Detalle de campaña |
| `PUT` | `/api/campaigns/:id` | JWT | Actualizar campaña |
| `DELETE` | `/api/campaigns/:id` | JWT | Eliminar campaña |
| `GET` | `/api/cities` | — | Listar ciudades |
| `GET` | `/api/categories` | — | Listar categorías |
| `GET` | `/api/donations` | — | Listar donaciones |
| `POST` | `/api/donations` | JWT | Crear donación |
| `GET` | `/api/donations/top` | — | Top donadores |
| `GET` | `/api/tracking/:campaign_id` | — | Seguimiento de campaña |
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
- **Backend:** Flask + SQLAlchemy + SQLite corriendo en `localhost:5000`

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
