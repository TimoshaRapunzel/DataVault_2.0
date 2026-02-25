{{ config(materialized='incremental', tags=['raw_vault', 'link']) }}
{{ datavault4dbt.link(
    link_hashkey='hk_customer_order',
    foreign_hashkeys=['hk_customer', 'hk_order'],
    source_models='stg_tpch_orders'
) }}
