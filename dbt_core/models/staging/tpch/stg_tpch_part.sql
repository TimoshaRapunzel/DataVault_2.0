{{ config(materialized='view', tags=['staging']) }}

WITH source AS (
    SELECT
        UPPER(TRIM(CAST(p_partkey AS VARCHAR))) AS part_key,
        p_name                                  AS part_name,
        p_mfgr                                  AS manufacturer,
        p_brand                                 AS brand,
        p_type                                  AS part_type,
        p_size                                  AS size,
        p_container                             AS container,
        p_retailprice                           AS retail_price,
        p_comment                               AS comment
    FROM {{ source('tpch', 'PART') }}
),
enriched AS (
    SELECT
        {{ hash_key('part_key') }} AS hk_part,
        {{ hash_diff(['part_name', 'manufacturer', 'brand', 'part_type', 'size', 'container', 'retail_price']) }} AS hashdiff,
        part_key,
        part_name,
        manufacturer,
        brand,
        part_type,
        size,
        container,
        retail_price,
        comment,
        CURRENT_TIMESTAMP() AS load_ts,
        'SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PART' AS record_source
    FROM source
)
SELECT * FROM enriched