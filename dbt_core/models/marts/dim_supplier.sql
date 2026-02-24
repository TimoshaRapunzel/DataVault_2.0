{{ config(materialized='table') }}

SELECT
    hub.hk_supplier,
    hub.supplier_key,
    sat.supplier_name,
    sat.address,
    sat.phone,
    sat.account_balance,
    sat.load_ts,
    sat.record_source
FROM {{ ref('hub_supplier') }} hub
INNER JOIN {{ ref('sat_supplier_details') }} sat 
    ON hub.hk_supplier = sat.hk_supplier
QUALIFY ROW_NUMBER() OVER (PARTITION BY hub.hk_supplier ORDER BY sat.load_ts DESC) = 1