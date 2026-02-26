import os
from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator

# Импорты
from utils.callbacks import on_failure_callback, on_success_callback
from utils.constants import DEFAULT_DBT_PROJECT_DIR

DBT_PROJECT_DIR = os.environ.get("DBT_PROJECT_DIR", DEFAULT_DBT_PROJECT_DIR)

# Перенесли успех сюда для лучшего логирования
default_args = {
    "on_failure_callback": on_failure_callback,
    "on_success_callback": on_success_callback,
}

with DAG(
    dag_id="retail_vault_cleanup",
    default_args=default_args,
    description="Maintains the environment by cleaning dbt artifacts and logs",
    schedule_interval="@weekly",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["maintenance"],
) as dag:
    dbt_clean = BashOperator(
        task_id="dbt_clean",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt clean",
    )
