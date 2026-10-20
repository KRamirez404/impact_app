# AGENTS.md — ImpactApp

Contexto permanente para agentes de IA. Leer antes de tocar código.

## Qué es

Aplicación full-stack de donaciones solidarias para Colombia. Los donantes apoyan campañas sociales verificadas; los organizadores crean campañas; el rol `soporte` (asignado centralmente) las verifica/aprueba. Proyecto académico (anteproyecto), no producción.

## Stack

| Capa | Tecnología |
|---|---|
| Backend | Flask 3 + SQLAlchemy + PostgreSQL 16 + flask-jwt-extended + bcrypt + Flask-CORS |
| Frontend | Flutter 3.x + GetX (estado/rutas/DI) + Dio (HTTP) + GetStorage (local) |
| Infra | Docker Compose (servicios `db` y `backend`) |
| Pruebas | pytest (backend) |

## Comandos

```bash
cp .env.example .env          # requerido antes de levantar
make up                       # build + arranque backend (docker compose up --build)
make dev                      # arranque sin rebuild
make down                     # detener
make logs                     # logs de todos los servicios
make backend-logs             # logs solo backend
make backend-shell            # shell dentro del contenedor
make reset-db                 # borra volumen y recrea BD
make test                     # pytest dentro del contenedor
make test-postgres            # pytest contra BD de test aislada
make run-linux                # Flutter en Linux desktop
make flutter-clean            # flutter clean + pub get
```

Frontend manual (SIEMPRE desde `impactapp_flutter/`, nunca desde la raíz):

```bash
cd impactapp_flutter
mkdir -p build/native_assets/linux
flutter run -d linux --dart-define=API_BASE_URL=http://localhost:5000/api
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:5000/api   # emulador
flutter analyze               # lint Dart
```

Backend sin Docker:

```bash
cd impactapp_backend && python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt && python app.py
```

Verificación rápida: `curl http://localhost:5000/api/health`.

## Credenciales seed

- Admin soporte: `admin@impactapp.co` / `Admin123*` (se crea en `seed_database()`).

## Arquitectura

### Backend (`impactapp_backend/`)

- `app.py` — factory `create_app()`, registra blueprints, `db.create_all()`, migraciones ad-hoc (`ensure_*_schema()`), seed. Entry point expone `app`.
- `config.py` — `Config`, normaliza `postgres://` → `postgresql+psycopg2://`; fallback SQLite `instance/impactapp.db` si no hay `DATABASE_URL`.
- `models/` — un archivo por entidad SQLAlchemy, exportados en `models/__init__.py`. Nombres de tabla y campos en MAYÚSCULAS/español (`USUARIO`, `CAMPAÑA`, `DONACION`, etc.). Cada modelo tiene `to_dict()`.
- `routes/` — blueprints por dominio, registrados en `routes/__init__.py`. Prefijo `/api/...`.
- `services/` — lógica de negocio: `auth_service`, `campaign_service`, `authorization`, `audit_service`, `donation_integrity` (checksum), `file_service`.
- `tests/` — pytest; `conftest.py` configura app y BD.

Control de acceso: decorador `require_role("organizador"|"donante"|"soporte")` en `services/authorization.py`; `current_user()`/`is_support()` como helpers.

No hay Alembic. Los cambios de esquema se hacen con `ALTER TABLE` idempotente dentro de `ensure_user_schema()`, `ensure_campaign_schema()`, `ensure_donation_schema()` en `app.py`.

### Frontend (`impactapp_flutter/lib/`)

Clean Architecture + GetX, por feature:

```
features/{modulo}/
├── domain/          entities/ · repositories (abstracto) · usecases/
├── infrastructure/  datasources/ · models/ (fromJson) · repositories/ (impl)
└── presentation/    bindings/ (DI) · controllers/ · pages/ · widgets/
```

- `domain` NO importa `infrastructure`.
- `app/routes/app_routes.dart` — constantes de rutas; `app_pages.dart` — mapa GetPage.
- `core/network/dio_client.dart` — singleton `DioClient.instance`, inyecta `Bearer token` desde GetStorage y redirige a login en 401.
- `core/constants/api_constants.dart` — URLs; `baseUrl` viene de `--dart-define=API_BASE_URL`.
- `shared/` — tema (`app_theme.dart`, `AppColors`) y widgets reutilizables.
- Features: `auth`, `campaigns`, `collection_points`, `home`, `ratings`, `support` (panel soporte), `verification` (soportes/evidencias).

## Convenciones

- Idioma: identificadores, mensajes de error y comentarios de código en español. Nombres de dominio en español.
- Backend: snake_case en JSON y columnas; entidades SQLAlchemy en MAYÚSCULAS.
- **No agregar comentarios** salvo que se pidan.
- Errores de API: `{"error": "..."}` con status HTTP adecuado.
- Frontend: seguir el flujo entity → model → datasource → repository → usecase → controller → page al agregar features.
- Tema/colores: usar `AppColors`/`AppTheme`; no hardcodear colores nuevos sin necesidad.
- Rutas nuevas: registrar en `app_routes.dart` y `app_pages.dart` con su binding.

## API (resumen)

Prefijo `/api`. Públicas: `GET /health`, `/auth/privacy-policy`, `GET /campaigns`, `/cities`, `/categories`, `/donations`, `/donations/top`, `/ratings/:id`, `/tracking/:id`, `/collection-points/:id`, `/supports/campaign/:id`. Con JWT: `/auth/me` (GET/PUT/DELETE), crear campaña/donación/punto/valoración/avance, `/donations/mine`. Solo `soporte`: `/support/summary`, `/support/campaigns/:id/{approve,reject,invalidate,delete,restore}`. Detalle completo en `README.md`.

## Gotchas

- No ejecutar `flutter run` desde la raíz; siempre `cd impactapp_flutter`.
- El emulador Android usa `10.0.2.2`, no `localhost`.
- `uploads/` e `instance/` están en `.gitignore`; no commitear evidencias ni la BD.
- Donaciones económicas usan Wompi Checkout Web: `POST /api/donations/checkout` + webhook `POST /api/webhooks/wompi`. Solo `estado_pago="aprobada"` cuenta para la meta. Las donaciones en especie siguen por `POST /api/donations`.
- Wompi corre en Sandbox por defecto (`WOMPI_*` en `.env`); producción está bloqueada con `WOMPI_ALLOW_PRODUCTION=0`. Sandbox no cobra dinero real. Ver `docs/wompi_sandbox.md` y `README.md`.
- Existen proyectos `android/` e `ios/`; la adaptación es parcial y la entrega móvil requiere configuración y verificación en dispositivos. Ver `Plan_Cierre.txt` y `README.md`.
- `JWT_SECRET_KEY` se autogenera si falta, pero `.env` debe definirla para sesiones estables.

## Documentación

- `README.md` — stack, endpoints, estructura, troubleshooting, trabajo futuro.
- `docs/trazabilidad_requisitos.md` — mapeo requisitos → implementación.
- `requerimientos.pdf` — especificación RF-01..12 y RNF-01..04; los códigos históricos de Plan.txt son distintos.
- `Plan_Cierre.txt` — avance de cierre; `docs/decisiones_cierre.md` — decisiones financieras pendientes.
- `docs/informe_seguridad_usabilidad.md` — seguridad y usabilidad.

## Reglas de desarrollo de Impactaap

### Uso de Graphify
- Antes de una modificación que afecte varias partes del proyecto, consulta Graphify para localizar las relaciones relevantes.
- Utiliza `graphify query`, `graphify explain` y `graphify path` cuando la versión instalada admita esas operaciones.
- Comprueba las conclusiones del grafo directamente en el código fuente. Las relaciones inferidas no se deben tratar como hechos confirmados.
- Evita explorar indiscriminadamente todo el repositorio si una consulta específica permite localizar los componentes necesarios.
- Después de cambios estructurales, actualiza el grafo utilizando el comando compatible con la versión instalada.

### Seguridad y calidad
- No modifiques funcionalidades ajenas a la tarea sin una justificación clara.
- No sobrescribas configuraciones, variables de entorno, datos ni migraciones existentes sin revisar sus consecuencias.
- Mantén las reglas de negocio y validaciones críticas en el backend.
- Para los pagos, no confíes en montos, estados o confirmaciones enviados únicamente por el frontend.
- No expongas credenciales, tokens ni secretos en el código o los registros.
- Antes de modificar archivos, identifica los componentes afectados y presenta un plan breve.
- Después de los cambios, ejecuta las pruebas pertinentes y revisa los errores y las diferencias de Git.
- No declares una funcionalidad terminada si no has verificado las pruebas correspondientes.
- Separa claramente las funciones implementadas, las que dependen de servicios externos y las que todavía no se han probado.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
