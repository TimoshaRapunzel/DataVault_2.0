{{ config(
    materialized='incremental',
    full_refresh=true,
    tags=['raw_vault', 'link']
) }}
{{ datavault4dbt.link(
    link_hashkey='hk_supplier_nation',
    foreign_hashkeys=['hk_supplier', 'hk_nation'],
    source_models='stg_tpch_supplier'
) }}
