{{ config(
    materialized='table',
    tags=['business_vault', 'bridge']
) }}

WITH link AS (
    SELECT
        hk_customer_order,
        hk_customer,
        hk_order
    FROM {{ ref('lnk_customer_order') }}
),

hub_cust AS (
    SELECT
        hk_customer,
        customer_key
    FROM {{ ref('hub_customer') }}
),

hub_ord AS (
    SELECT
        hk_order,
        order_key
    FROM {{ ref('hub_order') }}
)

SELECT
    l.hk_customer_order,
    l.hk_customer,
    l.hk_order,
    hc.customer_key,
    ho.order_key
FROM link AS l
INNER JOIN hub_cust AS hc
    ON l.hk_customer = hc.hk_customer
INNER JOIN hub_ord AS ho
    ON l.hk_order = ho.hk_order
