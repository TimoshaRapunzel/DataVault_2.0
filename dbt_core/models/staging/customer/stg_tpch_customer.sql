{{ config(materialized='view', tags=['staging']) }}

WITH source AS (
    SELECT
        UPPER(TRIM(CAST(c_custkey AS VARCHAR))) AS customer_key,
        c_name AS customer_name,
        c_address AS address,
        c_nationkey AS nation_key,
        c_phone AS phone,
        c_acctbal AS account_balance,
        c_mktsegment AS market_segment,
        c_comment AS comment
    FROM {{ source('tpch', 'CUSTOMER') }}
),

enriched AS (
    SELECT
        {{ hash_key('customer_key') }} AS hk_customer,
        {{ hash_diff(['customer_name', 'nation_key', 'market_segment', 'comment']) }} AS hd_customer_core,

        {{ hash_diff(['address', 'phone', 'account_balance']) }} AS hd_customer_contact,

        customer_key,
        customer_name,
        address,
        nation_key,
        phone,
        account_balance,
        market_segment,
        comment,
        CURRENT_TIMESTAMP() AS load_ts,
        'SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER' AS record_source
    FROM source
)

SELECT * FROM enriched
