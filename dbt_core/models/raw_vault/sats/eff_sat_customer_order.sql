{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['hk_customer_order', 'effective_from'],
    tags=['raw_vault', 'satellite', 'eff_sat']
) }}

WITH source_data AS (
    SELECT
        hk_customer_order,
        hk_customer,
        hk_order,
        start_date AS effective_from,
        end_date AS effective_to,
        load_ts,
        record_source
    FROM {{ ref('stg_tpch_orders') }}
)

SELECT
    hk_customer_order,
    hk_customer,
    hk_order,
    effective_from,
    effective_to,
    load_ts,
    record_source
FROM source_data
