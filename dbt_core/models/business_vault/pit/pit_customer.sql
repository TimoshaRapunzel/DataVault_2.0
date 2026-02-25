{{ config(
    materialized='table',
    tags=['business_vault', 'pit']
) }}

{%- set source_model = "hub_customer" -%}
-- Заменены на корректные имена из твоего проекта
{%- set sat_names = ["sat_customer_core", "sat_customer_contact", "sat_customer_marketing"] -%}
{%- set snapshot_relation = "as_of_date" -%}

{{ datavault4dbt.pit(
    tracked_entity=source_model,
    hashkey='hk_customer',
    sat_names=sat_names,
    snapshot_relation=snapshot_relation,
    snapshot_trigger_column='is_active',
    dimension_key='hk_customer_d'
) }}
