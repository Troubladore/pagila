# Pagila Test Database - Makefile
# ================================
# Simple commands for managing pagila PostgreSQL

.PHONY: help start stop restart status clean reset

help: ## Show this help message
	@echo "Pagila Test Database"
	@echo "===================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick start:"
	@echo "  make start      # Start pagila"
	@echo "  make status     # Check if running"
	@echo "  make stop       # Stop pagila"

start: ## Start pagila PostgreSQL database
	@echo "Starting pagila..."
	@docker compose up -d
	@echo ""
	@echo "✓ Pagila started"
	@echo ""
	@echo "Connection details:"
	@echo "  From platform:  pagila-postgres:5432"
	@echo "  From host:      localhost:5432"
	@echo "  Database:       pagila"
	@echo "  Username:       postgres"
	@echo "  Password:       (see postgres_sa_password.txt)"
	@echo ""
	@echo "Quick test:"
	@echo "  docker exec pagila-postgres psql -U postgres -d pagila -c '\\dt'"

stop: ## Stop pagila
	@echo "Stopping pagila..."
	@docker compose down
	@echo "✓ Pagila stopped"

restart: ## Restart pagila
	@echo "Restarting pagila..."
	@docker compose restart
	@echo "✓ Pagila restarted"

status: ## Check pagila status
	@echo "Pagila Status:"
	@echo "=============="
	@docker compose ps
	@echo ""
	@echo -n "Health: "
	@docker exec pagila-postgres pg_isready -U postgres 2>/dev/null && \
		echo "✓ Ready" || echo "✗ Not ready"
	@echo -n "Tables: "
	@docker exec pagila-postgres psql -U postgres -d pagila -t -c \
		"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'" 2>/dev/null | \
		tr -d ' ' || echo "?"

logs: ## Show pagila logs
	@docker compose logs -f

clean: ## Stop and remove pagila (keeps data volume)
	@echo "Cleaning pagila containers..."
	@docker compose down
	@echo "✓ Containers removed (data volume preserved)"

reset: ## DANGER: Remove pagila completely (including data!)
	@echo "⚠️  WARNING: This will delete ALL pagila data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "✓ Pagila data deleted"; \
	else \
		echo "Cancelled"; \
	fi

test: ## Test pagila database connectivity
	@echo "Testing pagila connectivity..."
	@echo ""
	@echo "1. Container running?"
	@docker ps --format '{{.Names}}' | grep -q "pagila-postgres" && \
		echo "   ✓ Container running" || \
		(echo "   ✗ Container not running" && exit 1)
	@echo ""
	@echo "2. PostgreSQL ready?"
	@docker exec pagila-postgres pg_isready -U postgres >/dev/null 2>&1 && \
		echo "   ✓ PostgreSQL ready" || \
		(echo "   ✗ PostgreSQL not ready" && exit 1)
	@echo ""
	@echo "3. Database exists?"
	@docker exec pagila-postgres psql -U postgres -lqt 2>/dev/null | grep -q "pagila" && \
		echo "   ✓ Database 'pagila' exists" || \
		(echo "   ✗ Database not found" && exit 1)
	@echo ""
	@echo "4. Tables loaded?"
	@TABLE_COUNT=$$(docker exec pagila-postgres psql -U postgres -d pagila -t -c \
		"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'" 2>/dev/null | tr -d ' '); \
	echo "   ✓ Found $$TABLE_COUNT tables"
	@echo ""
	@echo "5. Platform network?"
	@docker network inspect platform_network --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null | \
		grep -q "pagila-postgres" && \
		echo "   ✓ Connected to platform_network" || \
		echo "   ⚠️  Not on platform_network (run: docker network connect platform_network pagila-postgres)"
	@echo ""
	@echo "✅ All tests passed!"
