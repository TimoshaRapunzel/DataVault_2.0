{{ config(materialized='view') }}

WITH pit AS (
    SELECT * FROM {{ ref('pit_customer') }}
),

sat_details AS (
    SELECT * FROM {{ ref('sat_customer_details') }}
),

sat_mkt AS (
    SELECT * FROM {{ ref('sat_customer_marketing') }}
)

SELECT
    pit.hk_customer,
    pit.sdts AS as_of_date,
    
    -- Данные из сателлита Details (вместо старых LF/HF)
    sat_details.customer_name,
    sat_details.address,
    sat_details.nation_key,
    sat_details.phone,
    sat_details.account_balance,
    sat_details.market_segment,
    
    -- Данные из сателлита Marketing
    sat_mkt.loyalty_tier,
    sat_mkt.monthly_spend_usd,
    sat_mkt.is_active

FROM pit

LEFT JOIN sat_details 
    ON pit.hk_customer = sat_details.hk_customer 
    AND pit.load_ts_sat_customer_details = sat_details.load_ts

LEFT JOIN sat_mkt 
    ON pit.hk_customer = sat_mkt.hk_customer 
    AND pit.load_ts_sat_customer_marketing = sat_mkt.load_ts

WHERE DATE(pit.sdts) = CAST('{{ var("load_date") }}' AS DATE)