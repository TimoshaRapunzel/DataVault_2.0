{{ config(materialized='incremental', tags=['raw_vault', 'link']) }}
{{ datavault4dbt.link(
    link_hashkey='hk_part_supplier',
    foreign_hashkeys=['hk_part', 'hk_supplier'],
    source_models='stg_tpch_partsupp'
) }}