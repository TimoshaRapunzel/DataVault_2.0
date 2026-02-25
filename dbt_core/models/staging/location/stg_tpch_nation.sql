{{ config(materialized='view', tags=['staging']) }}

WITH source AS (
    SELECT
        UPPER(TRIM(CAST(n_nationkey AS VARCHAR))) AS nation_key,
        n_name AS nation_name,
        UPPER(TRIM(CAST(n_regionkey AS VARCHAR))) AS region_key,
        n_comment AS comment
    FROM {{ source('tpch', 'NATION') }}
),

enriched AS (
    SELECT
        {{ hash_key('nation_key') }} AS hk_nation,
        {{ hash_key('region_key') }} AS hk_region,
        {{ multi_hash_key(['nation_key', 'region_key']) }} AS hk_nation_region,
        nation_key,
        nation_name,
        region_key,
        comment,
        CURRENT_TIMESTAMP() AS load_ts,
        'SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.NATION' AS record_source
    FROM source
)

SELECT * FROM enriched
