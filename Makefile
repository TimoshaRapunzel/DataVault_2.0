.DEFAULT_GOAL := help
SHELL         := /bin/bash

DBT_DIR       := dbt_core
AIRFLOW_DAG   := retail_vault_dag
COMPOSE       := docker compose
DC_EXEC       := $(COMPOSE) exec airflow-scheduler

.PHONY: help build up down logs lint lint-python lint-sql format \
        dbt-deps dbt-debug dbt-run dbt-test dbt-docs \
        run-local run-incremental clean-db pre-commit-install

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ── Docker ────────────────────────────────────────────────────────────────────
build: ## Build Docker images
	$(COMPOSE) build --no-cache

up: ## Start all services (detached)
	$(COMPOSE) up -d airflow-init
	sleep 10
	$(COMPOSE) up -d airflow-webserver airflow-scheduler

down: ## Stop all services and remove containers
	$(COMPOSE) down --remove-orphans

logs: ## Tail logs for all services
	$(COMPOSE) logs -f

# ── Linting ───────────────────────────────────────────────────────────────────
lint: lint-python lint-sql ## Run all linters

lint-python: ## Run ruff linter on Python files
	ruff check airflow/ --output-format=github

lint-sql: ## Run sqlfluff on dbt models
	sqlfluff lint $(DBT_DIR)/models/ --dialect snowflake

format: ## Auto-format Python (ruff) and SQL (sqlfluff)
	ruff format airflow/
	sqlfluff fix $(DBT_DIR)/models/ --dialect snowflake

# ── dbt ───────────────────────────────────────────────────────────────────────
dbt-deps: ## Install dbt packages inside container
	$(DC_EXEC) dbt deps --project-dir /opt/dbt_core --profiles-dir /opt/dbt_core

dbt-debug: ## Verify dbt connection to Snowflake
	$(DC_EXEC) dbt debug --project-dir /opt/dbt_core --profiles-dir /opt/dbt_core

dbt-run: ## Run all dbt models (full refresh)
	$(DC_EXEC) dbt run --project-dir /opt/dbt_core --profiles-dir /opt/dbt_core --full-refresh

dbt-test: ## Run dbt tests
	$(DC_EXEC) dbt test --project-dir /opt/dbt_core --profiles-dir /opt/dbt_core

dbt-docs: ## Generate and serve dbt docs on :8001
	$(DC_EXEC) dbt docs generate --project-dir /opt/dbt_core --profiles-dir /opt/dbt_core
	$(DC_EXEC) dbt docs serve --project-dir /opt/dbt_core --port 8001

# ── Airflow triggers ──────────────────────────────────────────────────────────
run-local: ## Trigger full load DAG run via Airflow CLI
	$(DC_EXEC) airflow variables set run_type full
	$(DC_EXEC) airflow dags trigger $(AIRFLOW_DAG) --conf '{"run_type": "full"}'

run-incremental: ## Trigger incremental load DAG run via Airflow CLI
	$(DC_EXEC) airflow variables set run_type incremental
	$(DC_EXEC) airflow dags trigger $(AIRFLOW_DAG) --conf '{"run_type": "incremental"}'

# ── Snowflake DB management ───────────────────────────────────────────────────
clean-db: ## Drop and recreate Snowflake target schemas (RAW_VAULT, BUSINESS_VAULT, STAGING)
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

# ── Pre-commit ────────────────────────────────────────────────────────────────
pre-commit-install: ## Install pre-commit hooks
	pre-commit install
	pre-commit install --hook-type commit-msg
