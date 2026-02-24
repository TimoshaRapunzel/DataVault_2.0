{{ config(
    materialized='table',
    tags=['business_vault']
) }}

{{ datavault4dbt.pit(
    tracked_entity='hub_customer',
    hashkey='hk_customer',
    sat_names=['sat_customer_details', 'sat_customer_marketing'],
    snapshot_relation='as_of_date',
    snapshot_trigger_column='is_active',
    dimension_key='hk_customer_d'
) }}