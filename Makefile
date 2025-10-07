.PHONY: help build push run-mysql run-postgres run-mongodb run-redis clean

# Configurazione
IMAGE_NAME ?= db-backup-sidecar
IMAGE_TAG ?= latest
FULL_IMAGE = $(IMAGE_NAME):$(IMAGE_TAG)

help: ## Mostra questo messaggio di aiuto
	@echo "Comandi disponibili:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build dell'immagine Docker
	@echo "🔨 Building Docker image $(FULL_IMAGE)..."
	docker build -t $(FULL_IMAGE) .
	@echo "✅ Build completato!"

push: build ## Push dell'immagine su Docker registry
	@echo "📤 Pushing $(FULL_IMAGE) to registry..."
	docker push $(FULL_IMAGE)
	@echo "✅ Push completato!"

test-mysql: build ## Test backup MySQL (richiede MySQL in esecuzione)
	@echo "🧪 Testing MySQL backup..."
	@mkdir -p ./test-backups/mysql
	docker run --rm --network host \
		-e DB_TYPE=mysql \
		-e DB_HOST=localhost \
		-e DB_USER=root \
		-e DB_PASSWORD=password \
		-e DB_NAME=all \
		-v ./test-backups/mysql:/backups \
		$(FULL_IMAGE) run
	@echo "✅ Test completato! Controlla ./test-backups/mysql"

test-postgres: build ## Test backup PostgreSQL (richiede PostgreSQL in esecuzione)
	@echo "🧪 Testing PostgreSQL backup..."
	@mkdir -p ./test-backups/postgres
	docker run --rm --network host \
		-e DB_TYPE=postgres \
		-e DB_HOST=localhost \
		-e DB_USER=postgres \
		-e DB_PASSWORD=password \
		-e DB_NAME=all \
		-v ./test-backups/postgres:/backups \
		$(FULL_IMAGE) run
	@echo "✅ Test completato! Controlla ./test-backups/postgres"

test-mongodb: build ## Test backup MongoDB (richiede MongoDB in esecuzione)
	@echo "🧪 Testing MongoDB backup..."
	@mkdir -p ./test-backups/mongodb
	docker run --rm --network host \
		-e DB_TYPE=mongodb \
		-e DB_HOST=localhost \
		-e DB_USER=admin \
		-e DB_PASSWORD=password \
		-e DB_AUTH_DB=admin \
		-e DB_NAME=all \
		-v ./test-backups/mongodb:/backups \
		$(FULL_IMAGE) run
	@echo "✅ Test completato! Controlla ./test-backups/mongodb"

test-redis: build ## Test backup Redis (richiede Redis in esecuzione)
	@echo "🧪 Testing Redis backup..."
	@mkdir -p ./test-backups/redis
	docker run --rm --network host \
		-e DB_TYPE=redis \
		-e DB_HOST=localhost \
		-e DB_PASSWORD= \
		-v ./test-backups/redis:/backups \
		$(FULL_IMAGE) run
	@echo "✅ Test completato! Controlla ./test-backups/redis"

example-up: build ## Avvia l'esempio docker-compose
	@echo "🚀 Avvio stack di esempio..."
	docker compose -f docker-compose.example.yml up -d
	@echo "✅ Stack avviato! Usa 'make example-logs' per vedere i log"

example-down: ## Ferma l'esempio docker-compose
	@echo "🛑 Arresto stack di esempio..."
	docker compose -f docker-compose.example.yml down
	@echo "✅ Stack arrestato!"

example-logs: ## Mostra i log dell'esempio
	docker compose -f docker-compose.example.yml logs -f

clean: ## Rimuove backup di test e immagini Docker
	@echo "🧹 Pulizia..."
	rm -rf ./test-backups
	docker rmi $(FULL_IMAGE) 2>/dev/null || true
	@echo "✅ Pulizia completata!"

clean-all: clean ## Rimuove tutti i backup e volumi Docker
	@echo "🧹 Pulizia completa..."
	rm -rf ./backups
	docker compose -f docker-compose.example.yml down -v 2>/dev/null || true
	@echo "✅ Pulizia completa!"

shell: build ## Apri una shell nel container
	docker run --rm -it $(FULL_IMAGE) /bin/bash

lint: ## Verifica la sintassi degli script bash
	@echo "🔍 Controllo sintassi script..."
	@for script in scripts/*.sh; do \
		echo "Checking $$script..."; \
		bash -n $$script || exit 1; \
	done
	@echo "✅ Tutti gli script sono corretti!"
