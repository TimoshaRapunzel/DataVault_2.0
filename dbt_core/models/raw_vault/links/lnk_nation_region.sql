{{ config(materialized='incremental', tags=['raw_vault', 'link']) }}
{{ datavault4dbt.link(
    link_hashkey='hk_nation_region',
    foreign_hashkeys=['hk_nation', 'hk_region'],
    source_models='stg_tpch_nation'
) }}
