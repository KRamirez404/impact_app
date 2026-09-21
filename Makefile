.PHONY: up dev down build logs backend-shell reset-db flutter-clean run-linux test prod-up prod-down prod-logs prod-ps simulate-webhook test-postgres

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
test:
	docker compose exec backend python -m pytest tests -q
test-postgres:
	@docker compose exec -T db psql -U impactapp -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='impactapp_test'" | grep -q 1 || docker compose exec -T db psql -U impactapp -d postgres -c "CREATE DATABASE impactapp_test"
	docker compose exec -T -e TEST_DATABASE_URL=postgresql+psycopg2://impactapp:impactapp@db:5432/impactapp_test backend python -m pytest tests -q
flutter-clean:
	cd impactapp_flutter && flutter clean && flutter pub get
run-linux:
	cd impactapp_flutter && flutter run -d linux --dart-define=API_BASE_URL=http://localhost:5000/api
prod-up:
	docker compose --env-file .env.production -f docker-compose.prod.yml up --build -d
prod-down:
	docker compose --env-file .env.production -f docker-compose.prod.yml down
prod-logs:
	docker compose --env-file .env.production -f docker-compose.prod.yml logs -f
prod-ps:
	docker compose --env-file .env.production -f docker-compose.prod.yml ps
simulate-webhook:
	docker compose exec backend python scripts/simulate_wompi_webhook.py notify --latest --status APPROVED
