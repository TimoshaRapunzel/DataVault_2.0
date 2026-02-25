import os
from datetime import datetime

from airflow.decorators import dag
from cosmos import DbtTaskGroup, ExecutionConfig, ProfileConfig, ProjectConfig, RenderConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping

# Import logic and constants
from utils.callbacks import on_failure_callback, on_success_callback
from utils.constants import (
    DEFAULT_DBT_PROJECT_DIR,
    DEFAULT_SNOWFLAKE_DB,
    DEFAULT_SNOWFLAKE_ROLE,
    DEFAULT_SNOWFLAKE_WH,
    SNOWFLAKE_CONN_ID,
)

DBT_PROJECT_DIR = os.environ.get("DBT_PROJECT_DIR", DEFAULT_DBT_PROJECT_DIR)

# Cosmos Configuration
_profile_config = ProfileConfig(
    profile_name="retail_vault",
    target_name="dev",
    profile_mapping=SnowflakeUserPasswordProfileMapping(
        conn_id=SNOWFLAKE_CONN_ID,
        profile_args={
            "account": os.environ.get("SNOWFLAKE_ACCOUNT"),
            "database": os.environ.get("SNOWFLAKE_DATABASE", DEFAULT_SNOWFLAKE_DB),
            "schema": "STAGING",
            "warehouse": os.environ.get("SNOWFLAKE_WAREHOUSE", DEFAULT_SNOWFLAKE_WH),
            "role": os.environ.get("SNOWFLAKE_ROLE", DEFAULT_SNOWFLAKE_ROLE),
        },
    ),
)

_project_config = ProjectConfig(dbt_project_path=DBT_PROJECT_DIR)
_execution_config = ExecutionConfig(dbt_executable_path="dbt")

default_args = {"on_failure_callback": on_failure_callback}


@dag(
    default_args=default_args,
    dag_id="retail_vault_full_load",
    schedule_interval=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    on_success_callback=on_success_callback,
    tags=["retail_vault", "full_load"],
)
def retail_vault_full_load():
    """DAG for full historical data load (Data Vault 2.0)."""
    DbtTaskGroup(
        group_id="full_load_vault",
        project_config=_project_config,
        profile_config=_profile_config,
        execution_config=_execution_config,
        render_config=RenderConfig(
            select=[
                "path:models/staging",
                "path:models/raw_vault",
                "path:models/business_vault",
                "path:models/marts",
                "path:models/presentation",
            ],
        ),
        operator_args={"full_refresh": True},
    )


retail_vault_full_load()
