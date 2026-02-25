.DEFAULT_GOAL := help
SHELL         := /bin/bash

# Переменные
COMPOSE       := docker compose
DC_EXEC       := $(COMPOSE) exec airflow-scheduler
DBT_DIR       := dbt_core

.PHONY: help rebuild initial-load clean-up lint format build up down logs clean-db

help: ## Показать справку
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ── Обязательные алиасы (Airflow CLI + pre-commit) ────────────────────────────

rebuild: down ## (ТЗ) Полная пересборка Docker с нуля
	$(COMPOSE) build --no-cache
	$(COMPOSE) up -d airflow-init
	sleep 10
	$(COMPOSE) up -d airflow-webserver airflow-scheduler

initial-load: ## (ТЗ) Запуск полной загрузки через Airflow DAG
	$(DC_EXEC) airflow dags trigger retail_vault_full_load

clean-up: ## (ТЗ) Запуск очистки через Airflow DAG + локальная очистка кэша
	$(DC_EXEC) airflow dags trigger retail_vault_cleanup
	rm -rf .ruff_cache .sqlfluff_cache .pytest_cache
	find . -type d -name "__pycache__" -exec rm -rf {} +

lint: ## (ТЗ) Проверка линтерами через pre-commit (Windows-safe)
	py -m pre_commit run --all-files

# ── Остальные команды ─────────────────────────────────────────────────────────

format: ## Форматирование кода через Ruff (Windows-safe)
	py -m ruff format .
	py -m ruff check --fix .

down: ## Остановить контейнеры и очистить тома
	$(COMPOSE) down -v --remove-orphans

clean-db: ## Сброс схем Snowflake (STAGING, RAW_VAULT, BUSINESS_VAULT)
	$(DC_EXEC) python3 -c "import snowflake.connector, os; \
	ctx = snowflake.connector.connect(account=os.environ['SNOWFLAKE_ACCOUNT'], user=os.environ['SNOWFLAKE_USER'], \
	password=os.environ['SNOWFLAKE_PASSWORD'], role=os.environ['SNOWFLAKE_ROLE'], \
	warehouse=os.environ['SNOWFLAKE_WAREHOUSE'], database=os.environ['SNOWFLAKE_DATABASE']); \
	cur = ctx.cursor(); [cur.execute(s) for s in ['DROP SCHEMA IF EXISTS STAGING CASCADE','DROP SCHEMA IF EXISTS RAW_VAULT CASCADE','DROP SCHEMA IF EXISTS BUSINESS_VAULT CASCADE','CREATE SCHEMA STAGING','CREATE SCHEMA RAW_VAULT','CREATE SCHEMA BUSINESS_VAULT']];"
