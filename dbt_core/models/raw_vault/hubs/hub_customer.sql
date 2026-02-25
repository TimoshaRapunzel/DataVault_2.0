{{ config(
    materialized='incremental',
    full_refresh=true,
    tags=['raw_vault', 'hub']
) }}
{{ datavault4dbt.hub(
    hashkey='hk_customer',
    business_keys='customer_key',
    source_models='stg_tpch_customer'
) }}
