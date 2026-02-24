{{ config(
    materialized='incremental',
    full_refresh=true,
    tags=['raw_vault', 'hub']
) }}
{{ datavault4dbt.hub(
    hashkey='hk_part',
    business_keys='part_key',
    source_models='stg_tpch_part'
) }}