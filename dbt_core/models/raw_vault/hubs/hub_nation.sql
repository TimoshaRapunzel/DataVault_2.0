{{ config(
    materialized='incremental',
    full_refresh=true,
    tags=['raw_vault', 'hub']
) }}
{{ datavault4dbt.hub(
    hashkey='hk_nation',
    business_keys='nation_key',
    source_models='stg_tpch_nation'
) }}
