{{ config(materialized='incremental', tags=['raw_vault', 'satellite']) }}

{%- set source_model = "stg_tpch_part" -%}
{%- set parent_hashkey = "hk_part" -%}
{%- set src_hashdiff = "hashdiff" -%}
{%- set src_payload = ["part_name", "manufacturer", "brand", "part_type", "size", "container", "retail_price"] -%}
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