{{ config(materialized='table') }}

SELECT
    lnk.hk_customer_order,
    lnk.hk_customer,
    lnk.hk_order,
    hub_o.order_key,
    hub_c.customer_key,
    sat.order_status,
    sat.total_price,
    sat.order_date,
    sat.order_priority,
    sat.clerk,
    sat.ship_priority,
    sat.load_ts,
    sat.record_source
FROM {{ ref('lnk_customer_order') }} AS lnk
INNER JOIN {{ ref('hub_order') }} AS hub_o
    ON lnk.hk_order = hub_o.hk_order
INNER JOIN {{ ref('hub_customer') }} AS hub_c
    ON lnk.hk_customer = hub_c.hk_customer
INNER JOIN {{ ref('sat_order_details') }} AS sat
    ON lnk.hk_order = sat.hk_order
QUALIFY ROW_NUMBER() OVER (PARTITION BY lnk.hk_order ORDER BY sat.load_ts DESC) = 1
