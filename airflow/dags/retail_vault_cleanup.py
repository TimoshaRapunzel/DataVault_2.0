# dags/retail_vault_cleanup.py
import os
from datetime import datetime
from airflow.decorators import dag
from airflow.operators.bash import BashOperator

# Импортируем нашу логику и константы из utils!
from utils.callbacks import on_failure_callback, on_success_callback
from utils.constants import DEFAULT_DBT_PROJECT_DIR

DBT_PROJECT_DIR = os.environ.get("DBT_PROJECT_DIR", DEFAULT_DBT_PROJECT_DIR)

default_args = {
    "on_failure_callback": on_failure_callback
}

@dag(
    default_args=default_args,
    dag_id="retail_vault_cleanup",
    description="Maintains the environment by cleaning dbt artifacts and logs",
    schedule_interval="@weekly",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    on_success_callback=on_success_callback,
    tags=["maintenance"],
)
def retail_vault_cleanup():
    
    BashOperator(
        task_id="dbt_clean",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt clean",
    )

retail_vault_cleanup()