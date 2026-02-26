{{ config(
    materialized='view',
    tags=['business_vault', 'master_data']
) }}

SELECT
    h.hk_customer,
    s.marketing_segment,
    s.loyalty_tier,
    s.monthly_spend_usd,
    s.is_active,
    s.load_ts,
    s.record_source
FROM {{ ref('hub_customer') }} AS h
INNER JOIN {{ ref('sat_customer_marketing') }} AS s
    ON h.hk_customer = s.hk_customer
QUALIFY ROW_NUMBER() OVER (PARTITION BY h.hk_customer ORDER BY s.load_ts DESC) = 1
