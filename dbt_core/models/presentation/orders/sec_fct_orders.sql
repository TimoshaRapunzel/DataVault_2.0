{{ config(
    materialized='view',
    secure=true,
    tags=['presentation', 'secure', 'rls']
) }}

WITH orders AS (
    SELECT * FROM {{ ref('fct_orders') }}
),

secure_customers AS (
    -- Берем ключи клиентов, которые доступны текущему пользователю
    SELECT customer_key
    FROM {{ ref('sec_dim_customer') }}
)

SELECT
    o.order_key,
    o.customer_key,
    o.order_date,
    o.order_status,
    o.total_price,
    o.order_priority,
    o.clerk,
    o.ship_priority
FROM orders AS o
-- Джойнимся по бизнес-ключу customer_key
INNER JOIN secure_customers AS sc
    ON o.customer_key = sc.customer_key
