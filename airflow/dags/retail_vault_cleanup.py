import os
from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from utils.callbacks import on_failure_callback, on_success_callback
from utils.constants import DEFAULT_DBT_PROJECT_DIR

DBT_PROJECT_DIR = os.environ.get("DBT_PROJECT_DIR", DEFAULT_DBT_PROJECT_DIR)


CLEANUP_SQL = """
    DROP SCHEMA IF EXISTS STAGING CASCADE;
    DROP SCHEMA IF EXISTS RAW_VAULT CASCADE;
    DROP SCHEMA IF EXISTS BUSINESS_VAULT CASCADE;

    CREATE SCHEMA STAGING;
    CREATE SCHEMA RAW_VAULT;
    CREATE SCHEMA BUSINESS_VAULT;
"""


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
    snowflake_cleanup = SQLExecuteQueryOperator(
        task_id="snowflake_cleanup",
        conn_id="snowflake_default",
        sql=CLEANUP_SQL,
        split_statements=True,
    )

    dbt_clean = BashOperator(
        task_id="dbt_clean",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt clean",
    )

    snowflake_cleanup >> dbt_clean
