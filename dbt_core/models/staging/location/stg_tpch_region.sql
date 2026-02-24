{{ config(materialized='view', tags=['staging']) }}

WITH source AS (
    SELECT
        UPPER(TRIM(CAST(r_regionkey AS VARCHAR))) AS region_key,
        r_name AS region_name,
        r_comment AS comment
    FROM {{ source('tpch', 'REGION') }}
),
enriched AS (
    SELECT
        {{ hash_key('region_key') }} AS hk_region,
        region_key,
        region_name,
        comment,
        CURRENT_TIMESTAMP() AS load_ts,
        'SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.REGION' AS record_source
    FROM source
)
SELECT * FROM enriched