{{ config(materialized='incremental', tags=['raw_vault', 'satellite', 'eff_sat']) }}

WITH source_data AS (
    SELECT
        hk_customer_order,
        hk_customer,
        hk_order,
        start_date,
        end_date,
        load_ts,
        record_source
    FROM {{ ref('stg_tpch_orders') }}
)

SELECT
    hk_customer_order,
    hk_customer,
    hk_order,
    start_date,
    end_date,
    load_ts,
    record_source
FROM source_data
