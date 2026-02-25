{{ config(materialized='view', tags=['staging']) }}

WITH source AS (
    SELECT
        UPPER(TRIM(CAST(ps_partkey AS VARCHAR))) AS part_key,
        UPPER(TRIM(CAST(ps_suppkey AS VARCHAR))) AS supplier_key,
        ps_availqty AS available_qty,
        ps_supplycost AS supply_cost,
        ps_comment AS comment
    FROM {{ source('tpch', 'PARTSUPP') }}
),

enriched AS (
    SELECT
        {{ hash_key('part_key') }} AS hk_part,
        {{ hash_key('supplier_key') }} AS hk_supplier,
        {{ multi_hash_key(['part_key', 'supplier_key']) }} AS hk_part_supplier,
        {{ hash_diff(['available_qty', 'supply_cost', 'comment']) }} AS hashdiff,
        part_key,
        supplier_key,
        available_qty,
        supply_cost,
        comment,
        CURRENT_TIMESTAMP() AS load_ts,
        'SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.PARTSUPP' AS record_source
    FROM source
)

SELECT * FROM enriched
