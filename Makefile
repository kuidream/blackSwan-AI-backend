.PHONY: help up down restart logs ps db-init db-reset db-backup tools clean

help:
	@echo "blackSwan Backend - Development Commands"
	@echo ""
	@echo "Docker Services:"
	@echo "  make up         - Start all services (PostgreSQL, Redis)"
	@echo "  make down       - Stop all services"
	@echo "  make restart    - Restart all services"
	@echo "  make logs       - View service logs"
	@echo "  make ps         - Show service status"
	@echo ""
	@echo "Database:"
	@echo "  make db-init    - Initialize database schema"
	@echo "  make db-reset   - Reset database (WARNING: deletes all data)"
	@echo "  make db-backup  - Backup database to file"
	@echo "  make db-connect - Connect to PostgreSQL"
	@echo ""
	@echo "Development:"
	@echo "  make run        - Start Go backend server"
	@echo "  make test       - Run tests"
	@echo "  make lint       - Run linter"
	@echo ""
	@echo "Tools:"
	@echo "  make tools      - Start management tools (pgAdmin, Redis Commander)"
	@echo "  make clean      - Clean up containers and volumes"

up:
	docker-compose up -d
	@echo "Waiting for services to be healthy..."
	@timeout /t 5 /nobreak > nul
	@docker-compose ps

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

ps:
	docker-compose ps

db-init:
	@powershell -ExecutionPolicy Bypass -File scripts\init-db.ps1

db-reset:
	@powershell -ExecutionPolicy Bypass -File scripts\reset-db.ps1

db-backup:
	@powershell -Command "docker exec blackswan-postgres pg_dump -U postgres blackswan > backup_$$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
	@echo "Backup completed"

db-connect:
	docker exec -it blackswan-postgres psql -U postgres -d blackswan

redis-connect:
	docker exec -it blackswan-redis redis-cli

run:
	go run cmd/api/main.go

test:
	go test -v ./...

lint:
	golangci-lint run

tools:
	docker-compose --profile tools up -d
	@echo ""
	@echo "Management tools started:"
	@echo "  pgAdmin:         http://localhost:5050"
	@echo "  Redis Commander: http://localhost:8081"

clean:
	docker-compose down -v
	@echo "All containers and volumes removed"
