{{ config(materialized='view', tags=['staging']) }}

WITH source AS (
    SELECT
        UPPER(TRIM(CAST(o_orderkey AS VARCHAR))) AS order_key,
        UPPER(TRIM(CAST(o_custkey AS VARCHAR))) AS customer_key,
        o_orderstatus AS order_status,
        o_totalprice AS total_price,
        o_orderdate AS order_date,
        o_orderpriority AS order_priority,
        o_clerk AS clerk,
        o_shippriority AS ship_priority,
        o_comment AS comment
    FROM {{ source('tpch', 'ORDERS') }}
),

enriched AS (
    SELECT
        {{ hash_key('order_key') }} AS hk_order,
        {{ hash_key('customer_key') }} AS hk_customer,
        {{ multi_hash_key(['customer_key', 'order_key']) }} AS hk_customer_order,
        {{ hash_diff(['order_status', 'total_price', 'order_priority', 'clerk', 'ship_priority', 'order_date', 'comment']) }} AS hashdiff,
        order_key,
        customer_key,
        order_status,
        total_price,
        order_date,
        order_priority,
        clerk,
        ship_priority,
        comment,
        CURRENT_TIMESTAMP() AS load_ts,
        'SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.ORDERS' AS record_source,

        CURRENT_TIMESTAMP() AS start_date,
        TO_TIMESTAMP('9999-12-31 23:59:59') AS end_date
    FROM source
)

SELECT * FROM enriched
