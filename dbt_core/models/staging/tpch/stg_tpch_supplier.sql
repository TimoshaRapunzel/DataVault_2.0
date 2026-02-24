{{ config(materialized='view', tags=['staging']) }}

WITH source AS (
    SELECT
        UPPER(TRIM(CAST(s_suppkey AS VARCHAR)))   AS supplier_key,
        s_name                                     AS supplier_name,
        s_address                                  AS address,
        UPPER(TRIM(CAST(s_nationkey AS VARCHAR))) AS nation_key,
        s_phone                                    AS phone,
        s_acctbal                                  AS account_balance,
        s_comment                                  AS comment
    FROM {{ source('tpch', 'SUPPLIER') }}
),
enriched AS (
    SELECT
        {{ hash_key('supplier_key') }} AS hk_supplier,
        {{ hash_key('nation_key') }} AS hk_nation,
        {{ multi_hash_key(['supplier_key', 'nation_key']) }} AS hk_supplier_nation,
        {{ hash_diff(['supplier_name', 'address', 'phone', 'account_balance']) }} AS hashdiff,
        supplier_key,
        supplier_name,
        address,
        nation_key,
        phone,
        account_balance,
        comment,
        CURRENT_TIMESTAMP() AS load_ts,
        'SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.SUPPLIER' AS record_source
    FROM source
)
SELECT * FROM enriched