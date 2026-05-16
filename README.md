# ImpactApp

Aplicación full-stack de donaciones solidarias para Colombia.

## Estructura

- `impactapp_backend/`: API Flask + SQLite + JWT
- `impactapp_flutter/`: Frontend Flutter Desktop Linux con GetX y arquitectura hexagonal
- `docker-compose.yml`: Orquestación del backend

## Ejecución rápida

```bash
cp .env.example .env
docker compose up --build -d
cd impactapp_flutter && flutter pub get && flutter run -d linux --dart-define=API_BASE_URL=http://localhost:5000/api
```

## Desarrollo local

Backend:

```bash
cd impactapp_backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Frontend:

```bash
cd impactapp_flutter && flutter pub get && flutter run -d linux --dart-define=API_BASE_URL=http://localhost:5000/api
```

## Nota importante

Si ejecutas `flutter run` desde la raíz del repositorio, abrirás el proyecto Flutter de prueba (`impact_app`) y no `impactapp_flutter`.
