{{ config(materialized='table') }}

SELECT
    hub.hk_part,
    hub.part_key,
    sat.part_name,
    sat.manufacturer,
    sat.brand,
    sat.part_type,
    sat.size,
    sat.container,
    sat.retail_price,
    sat.load_ts,
    sat.record_source
FROM {{ ref('hub_part') }} AS hub
INNER JOIN {{ ref('sat_part_details') }} AS sat
    ON hub.hk_part = sat.hk_part
QUALIFY ROW_NUMBER() OVER (PARTITION BY hub.hk_part ORDER BY sat.load_ts DESC) = 1
