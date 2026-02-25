{{ config(materialized='incremental', tags=['raw_vault', 'satellite']) }}

{%- set source_model = "stg_tpch_orders" -%}
{%- set parent_hashkey = "hk_order" -%}
{%- set src_hashdiff = "hashdiff" -%}
{%- set src_payload = ["order_status", "total_price", "order_priority", "clerk", "ship_priority", "order_date"] -%}
{%- set src_ldts = "load_ts" -%}
{%- set src_rsrc = "record_source" -%}

{{ datavault4dbt.sat_v0(
    parent_hashkey=parent_hashkey,
    src_hashdiff=src_hashdiff,
    src_payload=src_payload,
    source_model=source_model,
    src_ldts=src_ldts,
    src_rsrc=src_rsrc
) }}
