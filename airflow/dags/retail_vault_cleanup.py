import os
from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

# Импорты
from utils.callbacks import on_failure_callback, on_success_callback
from utils.constants import DEFAULT_DBT_PROJECT_DIR

DBT_PROJECT_DIR = os.environ.get("DBT_PROJECT_DIR", DEFAULT_DBT_PROJECT_DIR)

# Точный перенос логики из Makefile: clean-db
CLEANUP_SQL = """
    DROP SCHEMA IF EXISTS STAGING CASCADE;
    DROP SCHEMA IF EXISTS RAW_VAULT CASCADE;
    DROP SCHEMA IF EXISTS BUSINESS_VAULT CASCADE;

    CREATE SCHEMA STAGING;
    CREATE SCHEMA RAW_VAULT;
    CREATE SCHEMA BUSINESS_VAULT;
"""

# Перенесли успех сюда для лучшего логирования
default_args = {
    "on_failure_callback": on_failure_callback,
    "on_success_callback": on_success_callback,
}

with DAG(
    dag_id="retail_vault_cleanup",
    default_args=default_args,
    description="Maintains the environment by cleaning DB schemas and dbt artifacts/logs",
    schedule_interval="@weekly",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["maintenance", "snowflake"],
) as dag:
    # 1. Сначала сносим и пересоздаем все три схемы в Snowflake
    snowflake_cleanup = SQLExecuteQueryOperator(
        task_id="snowflake_cleanup",
        conn_id="snowflake_default",
        sql=CLEANUP_SQL,
        split_statements=True,  # Обязательно True, чтобы выполнить все 6 команд подряд
    )

    # 2. Затем чистим локальные артефакты dbt
    dbt_clean = BashOperator(
        task_id="dbt_clean",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt clean",
    )

    # Устанавливаем зависимость
    snowflake_cleanup >> dbt_clean
