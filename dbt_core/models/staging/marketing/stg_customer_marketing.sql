{{ config(materialized='view', tags=['staging']) }}

WITH source AS (
    SELECT
        UPPER(TRIM(CAST(customer_key AS VARCHAR))) AS customer_key,
        marketing_segment,
        loyalty_tier,
        email_opt_in,
        preferred_channel,
        campaign_code,
        registration_date,
        monthly_spend_usd,
        is_active
    FROM {{ ref('customer_marketing') }}
),
enriched AS (
    SELECT
        {{ hash_key('customer_key') }} AS hk_customer,
        {{ hash_diff(['marketing_segment', 'loyalty_tier', 'email_opt_in', 'preferred_channel', 'campaign_code', 'monthly_spend_usd', 'is_active']) }} AS hashdiff,
        customer_key,
        marketing_segment,
        loyalty_tier,
        email_opt_in,
        preferred_channel,
        campaign_code,
        registration_date,
        monthly_spend_usd,
        is_active,
        CURRENT_TIMESTAMP() AS load_ts,
        'SEED.CUSTOMER_MARKETING' AS record_source
    FROM source
)
SELECT * FROM enriched