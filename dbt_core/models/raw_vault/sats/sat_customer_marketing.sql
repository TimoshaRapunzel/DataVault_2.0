{{ config(materialized='incremental', tags=['raw_vault', 'satellite']) }}

{%- set source_model = "stg_customer_marketing" -%}
{%- set parent_hashkey = "hk_customer" -%}
{%- set src_hashdiff = "hashdiff" -%}
{%- set src_payload = ["marketing_segment", "loyalty_tier", "email_opt_in", "preferred_channel", "campaign_code", "registration_date", "monthly_spend_usd", "is_active"] -%}
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