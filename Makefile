# ═══════════════════════════════════════════════════════════════
# SmartEdu Telu — Makefile
# ═══════════════════════════════════════════════════════════════

# ── Variables ─────────────────────────────────────────────────
COMPOSE        = docker compose
CONTAINER_PG   = smartedutelu-postgres
CONTAINER_APP  = smartedutelu-app
DB_NAME       ?= smartedutelu
DB_USER       ?= postgres
MIGRATION_DIR  = src/main/resources/db/migration

# ═══════════════════════════════════════════════════════════════
# SETUP
# ═══════════════════════════════════════════════════════════════

.PHONY: env
env: ## Copy .env.example ke .env (skip kalau sudah ada)
	@if [ ! -f .env ]; then cp .env.example .env && echo "✅ .env created from .env.example"; else echo "⏭️  .env already exists, skipping"; fi

# ═══════════════════════════════════════════════════════════════
# DOCKER COMPOSE — INFRA (postgres + redis)
# ═══════════════════════════════════════════════════════════════

.PHONY: infra-up
infra-up: env ## Start infra only (postgres + redis)
	$(COMPOSE) up postgres redis -d
	@echo "⏳ Waiting for PostgreSQL healthy..."
	@docker inspect --format='{{.State.Health.Status}}' $(CONTAINER_PG) 2>/dev/null | grep -q healthy || \
		(for i in $$(seq 1 30); do sleep 1; docker inspect --format='{{.State.Health.Status}}' $(CONTAINER_PG) 2>/dev/null | grep -q healthy && break; done)
	@echo "✅ Infra is up"

.PHONY: infra-down
infra-down: ## Stop infra containers
	$(COMPOSE) stop postgres redis

.PHONY: infra-logs
infra-logs: ## Tail infra logs
	$(COMPOSE) logs -f postgres redis

# ═══════════════════════════════════════════════════════════════
# DOCKER COMPOSE — DEV TOOLS (pgAdmin, RedisInsight, Mailpit)
# ═══════════════════════════════════════════════════════════════

.PHONY: dev-up
dev-up: infra-up ## Start infra + all dev tools
	$(COMPOSE) --profile dev up -d
	@echo "✅ Dev environment is up"
	@echo "   pgAdmin      → http://localhost:$${PGADMIN_PORT:-5050}"
	@echo "   RedisInsight  → http://localhost:$${REDISINSIGHT_PORT:-5540}"
	@echo "   Mailpit       → http://localhost:$${MAILPIT_UI_PORT:-8025}"

.PHONY: dev-down
dev-down: ## Stop all dev tool containers
	$(COMPOSE) --profile dev down

.PHONY: dev-logs
dev-logs: ## Tail dev tools logs
	$(COMPOSE) --profile dev logs -f

# ═══════════════════════════════════════════════════════════════
# DOCKER COMPOSE — FULL STACK (app + infra)
# ═══════════════════════════════════════════════════════════════

.PHONY: up
up: env ## Start everything (app + infra)
	$(COMPOSE) up -d --build
	@echo "✅ Full stack is up → http://localhost:$${SERVER_PORT:-8080}/api/actuator/health"

.PHONY: down
down: ## Stop all containers
	$(COMPOSE) down

.PHONY: restart
restart: down up ## Restart all containers

.PHONY: logs
logs: ## Tail all container logs
	$(COMPOSE) logs -f

.PHONY: app-logs
app-logs: ## Tail only the app logs
	$(COMPOSE) logs -f app

.PHONY: ps
ps: ## Show running containers
	$(COMPOSE) ps

# ═══════════════════════════════════════════════════════════════
# DATABASE — MIGRATION
# ═══════════════════════════════════════════════════════════════

.PHONY: migrate
migrate: infra-up ## Run ALL Flyway migrations via psql (V1..V12)
	@echo "🚀 Running migrations..."
	@for f in $$(ls $(MIGRATION_DIR)/V*.sql | sort -t'V' -k2 -n); do \
		echo "── $$f"; \
		cat "$$f" | docker exec -i $(CONTAINER_PG) psql -U $(DB_USER) -d $(DB_NAME) -v ON_ERROR_STOP=1 || { echo "❌ FAILED at $$f"; exit 1; }; \
	done
	@echo "✅ All migrations applied"

.PHONY: migrate-validate
migrate-validate: ## Dry-run: validate migrations via psql in a transaction then rollback
	@echo "🔍 Validating migrations (dry-run with ROLLBACK)..."
	@{ echo "BEGIN;"; \
	   for f in $$(ls $(MIGRATION_DIR)/V*.sql | sort -t'V' -k2 -n); do cat "$$f"; echo ""; done; \
	   echo "ROLLBACK;"; \
	} | docker exec -i $(CONTAINER_PG) psql -U $(DB_USER) -d $(DB_NAME) -v ON_ERROR_STOP=1
	@echo "✅ All migrations are valid (no changes applied)"

.PHONY: migrate-status
migrate-status: ## Show all tables currently in the database
	@docker exec $(CONTAINER_PG) psql -U $(DB_USER) -d $(DB_NAME) -c \
		"SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;"

.PHONY: migrate-count
migrate-count: ## Count tables in database
	@docker exec $(CONTAINER_PG) psql -U $(DB_USER) -d $(DB_NAME) -t -c \
		"SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public';"

# ═══════════════════════════════════════════════════════════════
# DATABASE — UTILITIES
# ═══════════════════════════════════════════════════════════════

.PHONY: db-shell
db-shell: ## Open psql shell inside the Postgres container
	docker exec -it $(CONTAINER_PG) psql -U $(DB_USER) -d $(DB_NAME)

.PHONY: db-reset
db-reset: ## Drop & recreate database, then re-run migrations
	@echo "⚠️  Dropping and recreating database $(DB_NAME)..."
	docker exec $(CONTAINER_PG) psql -U $(DB_USER) -c "DROP DATABASE IF EXISTS $(DB_NAME);"
	docker exec $(CONTAINER_PG) psql -U $(DB_USER) -c "CREATE DATABASE $(DB_NAME);"
	@$(MAKE) migrate
	@echo "✅ Database reset complete"

.PHONY: db-dump
db-dump: ## Dump database schema to backups/schema.sql
	@mkdir -p backups
	docker exec $(CONTAINER_PG) pg_dump -U $(DB_USER) -d $(DB_NAME) --schema-only > backups/schema_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ Schema dumped to backups/"

.PHONY: db-nuke
db-nuke: ## Destroy database volume completely (DANGEROUS)
	@echo "💀 This will destroy ALL PostgreSQL data!"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	$(COMPOSE) down -v
	@echo "✅ All volumes destroyed"

# ═══════════════════════════════════════════════════════════════
# APP — BUILD & RUN (without Docker)
# ═══════════════════════════════════════════════════════════════

.PHONY: build
build: ## Build the app JAR (skip tests)
	./mvnw clean package -DskipTests -B

.PHONY: run
run: infra-up ## Run app locally (requires infra running)
	./mvnw spring-boot:run

.PHONY: test
test: ## Run all tests
	./mvnw test

.PHONY: clean
clean: ## Clean Maven build artifacts
	./mvnw clean

# ═══════════════════════════════════════════════════════════════
# DOCKER — CLEANUP
# ═══════════════════════════════════════════════════════════════

.PHONY: docker-clean
docker-clean: ## Remove stopped containers, dangling images, build cache
	docker system prune -f
	@echo "✅ Docker cleanup done"

.PHONY: docker-clean-all
docker-clean-all: down ## Stop everything + remove all project images & volumes
	$(COMPOSE) down -v --rmi local
	@echo "✅ All project containers, images, and volumes removed"

# ═══════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@echo ""
	@echo "SmartEdu Telu — Available Commands"
	@echo "════════════════════════════════════════════════════"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
