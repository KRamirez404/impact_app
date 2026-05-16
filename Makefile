.PHONY: up dev down build logs backend-shell reset-db flutter-clean run-linux

up:
	docker compose up --build
dev:
	docker compose up
down:
	docker compose down
build:
	docker compose build --no-cache
logs:
	docker compose logs -f
backend-logs:
	docker compose logs -f backend
frontend-logs:
	docker compose logs -f frontend
backend-shell:
	docker compose exec backend bash
reset-db:
	docker compose down -v
	docker compose up --build
flutter-clean:
	cd impactapp_flutter && flutter clean && flutter pub get
run-linux:
	cd impactapp_flutter && flutter run -d linux --dart-define=API_BASE_URL=http://localhost:5000/api
