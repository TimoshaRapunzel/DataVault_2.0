{{ config(
    materialized='view',
    secure=true,
    tags=['presentation', 'secure', 'rls']
) }}


WITH customer_data AS (
    SELECT * FROM {{ ref('dim_customer') }}
    WHERE is_current = TRUE
)

SELECT
    customer_sk,
    customer_key,

    customer_name,
    address,
    nation_key,
    phone,
    market_segment,
    account_balance,
    comment

FROM customer_data
WHERE
    CURRENT_ROLE() IN ('SYSADMIN', 'ACCOUNTADMIN', 'DATA_OWNER')

    OR (
        CURRENT_ROLE() = 'ANALYST_EUROPE'
        AND nation_key IN (7, 14, 19, 21)
    )

    OR (
        CURRENT_ROLE() = 'ANALYST_AMERICA'
        AND nation_key IN (1, 2, 3, 17, 24)
    )
