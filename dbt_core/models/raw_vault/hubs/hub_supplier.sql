{{ config(materialized='incremental', tags=['raw_vault', 'hub']) }}
{{ datavault4dbt.hub(
    hashkey='hk_supplier',
    business_keys='supplier_key',
    source_models='stg_tpch_supplier'
) }}
