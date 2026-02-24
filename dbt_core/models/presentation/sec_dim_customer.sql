{{ config(
    materialized='view',
    secure=true,
    tags=['presentation', 'secure', 'rls']
) }}

WITH customer_data AS (
    SELECT * FROM {{ ref('dim_customer_flat') }}
)

SELECT
    hk_customer,
    customer_name,
    address,
    nation_key,
    phone,
    market_segment,
    account_balance,
    loyalty_tier,
    is_active
FROM customer_data
WHERE 
    -- 1. Администраторы видят всё
    CURRENT_ROLE() IN ('SYSADMIN', 'ACCOUNTADMIN')
    
    -- 2. RLS Политика: Аналитики Европы видят только свои регионы
    OR (
        CURRENT_ROLE() = 'ANALYST_EUROPE' 
        AND nation_key IN (7, 14, 19)
    )