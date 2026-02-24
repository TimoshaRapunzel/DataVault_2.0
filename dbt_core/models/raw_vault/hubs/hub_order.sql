{{ config(materialized='incremental', tags=['raw_vault', 'hub']) }}
{{ datavault4dbt.hub(
    hashkey='hk_order',
    business_keys='order_key',
    source_models='stg_tpch_orders'
) }}