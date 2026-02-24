{{ config(materialized='incremental', tags=['raw_vault', 'hub']) }}
{{ datavault4dbt.hub(
    hashkey='hk_region',
    business_keys='region_key',
    source_models='stg_tpch_region'
) }}