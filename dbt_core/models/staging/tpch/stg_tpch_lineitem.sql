{{ config(materialized='view', tags=['staging']) }}

WITH source AS (
    SELECT
        UPPER(TRIM(CAST(l_orderkey AS VARCHAR)))   AS order_key,
        UPPER(TRIM(CAST(l_partkey AS VARCHAR)))    AS part_key,
        UPPER(TRIM(CAST(l_suppkey AS VARCHAR)))    AS supplier_key,
        l_linenumber                               AS line_number,
        l_quantity                                 AS quantity,
        l_extendedprice                            AS extended_price,
        l_discount                                 AS discount,
        l_tax                                      AS tax,
        l_returnflag                               AS return_flag,
        l_linestatus                               AS line_status,
        l_shipdate                                 AS ship_date,
        l_commitdate                               AS commit_date,
        l_receiptdate                              AS receipt_date,
        l_shipinstruct                             AS ship_instruct,
        l_shipmode                                 AS ship_mode,
        l_comment                                  AS comment
    FROM {{ source('tpch', 'LINEITEM') }}
),
enriched AS (
    SELECT
        {{ hash_key('order_key') }} AS hk_order,
        {{ hash_key('part_key') }} AS hk_part,
        {{ hash_key('supplier_key') }} AS hk_supplier,
        {{ multi_hash_key(['order_key', 'part_key', 'supplier_key', 'line_number']) }} AS hk_order_lineitem,
        {{ hash_diff(['quantity', 'extended_price', 'discount', 'tax', 'return_flag', 'line_status', 'ship_date', 'commit_date', 'receipt_date', 'ship_instruct', 'ship_mode']) }} AS hashdiff,
        order_key,
        part_key,
        supplier_key,
        line_number,
        quantity,
        extended_price,
        discount,
        tax,
        return_flag,
        line_status,
        ship_date,
        commit_date,
        receipt_date,
        ship_instruct,
        ship_mode,
        comment,
        CURRENT_TIMESTAMP() AS load_ts,
        'SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM' AS record_source
    FROM source
)
SELECT * FROM enriched