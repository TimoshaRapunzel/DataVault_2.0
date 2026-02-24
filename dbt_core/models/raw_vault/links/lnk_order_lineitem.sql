{{ config(materialized='incremental', tags=['raw_vault', 'link']) }}
{{ datavault4dbt.link(
    link_hashkey='hk_order_lineitem',
    foreign_hashkeys=['hk_order', 'hk_part', 'hk_supplier'],
    source_models='stg_tpch_lineitem'
) }}