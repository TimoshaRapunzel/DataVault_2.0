.DEFAULT_GOAL := help
SHELL         := /bin/bash

# Переменные
DBT_DIR       := dbt_core
AIRFLOW_DAG   := retail_vault_full_load
COMPOSE       := docker compose
DC_EXEC       := $(COMPOSE) exec airflow-scheduler

.PHONY: help rebuild initial-load clean-up lint format build up down logs \
        dbt-deps dbt-debug dbt-run dbt-test dbt-docs \
        run-local run-incremental clean-db pre-commit-install

help: ## Показать справку по командам
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ── Обязательные алиасы по ТЗ ─────────────────────────────────────────────────

rebuild: down ## (ТЗ) Полная пересборка: удалить контейнеры, тома и собрать заново
	$(COMPOSE) up -d --build

initial-load: dbt-deps ## (ТЗ) Первичная загрузка: установка пакетов и dbt run --full-refresh
	$(DC_EXEC) dbt run --project-dir /opt/dbt_core --profiles-dir /opt/dbt_core --full-refresh

clean-up: ## (ТЗ) Полная очистка: dbt clean + удаление всех кэшей и pycache
	$(DC_EXEC) dbt clean --project-dir /opt/dbt_core
	rm -rf .ruff_cache .pytest_cache .sqlfluff_cache
	find . -type d -name "__pycache__" -exec rm -rf {} +
	@echo "All clean."

# ── Docker ────────────────────────────────────────────────────────────────────

build: ## Собрать образы
	$(COMPOSE) build --no-cache

up: ## Запустить сервисы
	$(COMPOSE) up -d airflow-init
	sleep 10
	$(COMPOSE) up -d airflow-webserver airflow-scheduler

down: ## Остановить и удалить контейнеры и тома (чистый сброс)
	$(COMPOSE) down -v --remove-orphans

logs: ## Просмотр логов
	$(COMPOSE) logs -f

# ── Проверки (Linter/Formatter) ───────────────────────────────────────────────

lint: ## Запустить все линтеры (Ruff для Python и SQLFluff для SQL)
	ruff check . 
	sqlfluff lint $(DBT_DIR)/models/ --dialect snowflake

format: ## Авто-форматирование кода
	ruff format .
	ruff check --fix .
	sqlfluff fix $(DBT_DIR)/models/ --dialect snowflake

# ── dbt ───────────────────────────────────────────────────────────────────────

dbt-deps: ## Установка dbt пакетов
	$(DC_EXEC) dbt deps --project-dir /opt/dbt_core

dbt-debug: ## Проверка соединения со Snowflake
	$(DC_EXEC) dbt debug --project-dir /opt/dbt_core

dbt-run: ## Запуск dbt моделей (инкрементально)
	$(DC_EXEC) dbt run --project-dir /opt/dbt_core

dbt-test: ## Запуск тестов dbt
	$(DC_EXEC) dbt test --project-dir /opt/dbt_core

dbt-docs: ## Генерация и запуск документации dbt (порт 8001)
	$(DC_EXEC) dbt docs generate --project-dir /opt/dbt_core
	$(DC_EXEC) dbt docs serve --project-dir /opt/dbt_core --port 8001

# ── Snowflake ─────────────────────────────────────────────────────────────────

clean-db: ## Пересоздать схемы в Snowflake (Очистка Raw и Business слоев)
	$(DC_EXEC) bash -c " \
	  python -c \" \
	  import snowflake.connector, os; \
	  ctx = snowflake.connector.connect( \
	    account=os.environ['SNOWFLAKE_ACCOUNT'], \
	    user=os.environ['SNOWFLAKE_USER'], \
	    password=os.environ['SNOWFLAKE_PASSWORD'], \
	    role=os.environ['SNOWFLAKE_ROLE'], \
	    warehouse=os.environ['SNOWFLAKE_WAREHOUSE'], \
	    database=os.environ['SNOWFLAKE_DATABASE'] \
	  ); \
	  cur = ctx.cursor(); \
	  [cur.execute(s) for s in [ \
	    'DROP SCHEMA IF EXISTS STAGING CASCADE', \
	    'DROP SCHEMA IF EXISTS RAW_VAULT CASCADE', \
	    'DROP SCHEMA IF EXISTS BUSINESS_VAULT CASCADE', \
	    'CREATE SCHEMA STAGING', \
	    'CREATE SCHEMA RAW_VAULT', \
	    'CREATE SCHEMA BUSINESS_VAULT', \
	  ]]; \
	  print('Schemas recreated successfully.') \
	  \" \
	"