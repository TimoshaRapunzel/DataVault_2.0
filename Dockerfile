FROM apache/airflow:2.10.3-python3.11

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/dbt_core && chown -R airflow:root /opt/dbt_core

USER airflow

COPY --chown=airflow:root pyproject.toml /opt/airflow/pyproject.toml

RUN pip install --no-cache-dir uv==0.4.20

RUN uv pip install --no-cache-dir \
    "dbt-core==1.7.10" \
    "dbt-snowflake==1.7.0" \
    "astronomer-cosmos[dbt-snowflake]==1.11.2" \
    "apache-airflow-providers-snowflake>=5.3.0" \
    "apache-airflow-providers-common-sql>=1.14.0" \
    "loguru==0.7.2" \
    "apache-airflow-providers-telegram==4.3.1"

COPY --chown=airflow:root dbt_core /opt/dbt_core
COPY --chown=airflow:root airflow/dags /opt/airflow/dags
COPY --chown=airflow:root airflow/plugins /opt/airflow/plugins

ENV DBT_PROJECT_DIR=/opt/dbt_core \
    DBT_PROFILES_DIR=/opt/dbt_core

WORKDIR /opt/airflow
