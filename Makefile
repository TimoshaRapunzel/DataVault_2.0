.DEFAULT_GOAL := help
SHELL         := /bin/bash


COMPOSE       := docker compose
DC_EXEC       := $(COMPOSE) exec airflow-scheduler
DBT_DIR       := dbt_core

.PHONY: help rebuild initial-load incremental-load clean-up lint format build up down logs clean-db

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'



rebuild: down ## Full Docker rebuild from scratch
	$(COMPOSE) build --no-cache
	$(COMPOSE) up -d airflow-init
	sleep 10
	$(COMPOSE) up -d airflow-webserver airflow-scheduler

initial-load: ## Trigger full load via Airflow DAG
	$(DC_EXEC) airflow dags trigger retail_vault_full_load

incremental-load: ## Trigger incremental load via Airflow DAG
	$(DC_EXEC) airflow dags trigger retail_vault_incremental

clean-up: ## Trigger cleanup via Airflow DAG + local cache cleanup
	$(DC_EXEC) airflow dags trigger retail_vault_cleanup
	rm -rf .ruff_cache .sqlfluff_cache .pytest_cache
	find . -type d -name "__pycache__" -exec rm -rf {} +

lint: ## Run linters via pre-commit
	py -m pre_commit run --all-files



format: ## Format code via Ruff
	py -m ruff format .
	py -m ruff check --fix .

down: ## Stop containers and clean volumes
	$(COMPOSE) down -v --remove-orphans

clean-db: ## Reset Snowflake schemas (STAGING, RAW_VAULT, BUSINESS_VAULT)
	$(DC_EXEC) python3 -c "import snowflake.connector, os; \
	ctx = snowflake.connector.connect(account=os.environ['SNOWFLAKE_ACCOUNT'], user=os.environ['SNOWFLAKE_USER'], \
	password=os.environ['SNOWFLAKE_PASSWORD'], role=os.environ['SNOWFLAKE_ROLE'], \
	warehouse=os.environ['SNOWFLAKE_WAREHOUSE'], database=os.environ['SNOWFLAKE_DATABASE']); \
	cur = ctx.cursor(); [cur.execute(s) for s in ['DROP SCHEMA IF EXISTS STAGING CASCADE','DROP SCHEMA IF EXISTS RAW_VAULT CASCADE','DROP SCHEMA IF EXISTS BUSINESS_VAULT CASCADE','CREATE SCHEMA STAGING','CREATE SCHEMA RAW_VAULT','CREATE SCHEMA BUSINESS_VAULT']];"
