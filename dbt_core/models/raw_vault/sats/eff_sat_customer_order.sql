{{ config(materialized='incremental', tags=['raw_vault', 'satellite', 'eff_sat']) }}

{%- set source_model = "stg_tpch_orders" -%}
{%- set link_hashkey = "hk_customer_order" -%}
{%- set foreign_hashkeys = ["hk_customer", "hk_order"] -%}

{%- set dfk = ["hk_customer"] -%} 

{%- set src_start_date = "start_date" -%}
{%- set src_end_date = "end_date" -%}
{%- set src_ldts = "load_ts" -%}
{%- set src_rsrc = "record_source" -%}

{{ datavault4dbt.eff_sat(
    source_model=source_model,
    link_hashkey=link_hashkey,
    foreign_hashkeys=foreign_hashkeys,
    src_dfk=dfk,
    src_start_date=src_start_date,
    src_end_date=src_end_date,
    src_ldts=src_ldts,
    src_rsrc=src_rsrc
) }}