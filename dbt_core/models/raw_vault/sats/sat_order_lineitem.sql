{{ config(materialized='incremental', tags=['raw_vault', 'satellite']) }}

{%- set source_model = "stg_tpch_lineitem" -%}
{%- set parent_hashkey = "hk_order_lineitem" -%}
{%- set src_hashdiff = "hashdiff" -%}
{%- set src_payload = ["quantity", "extended_price", "discount", "tax", "return_flag", "line_status", "ship_date", "commit_date", "receipt_date", "ship_instruct", "ship_mode"] -%}
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