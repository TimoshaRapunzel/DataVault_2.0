{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customer_sk',
    tags=['mart', 'dimension']
) }}

-- 1. Определяем, какие клиенты обновились
WITH changed_customers AS (
    {% if is_incremental() %}
        SELECT cc.hk_customer FROM {{ ref('sat_customer_core') }} AS cc WHERE cc.load_ts > (SELECT COALESCE(MAX(t.valid_from), '1900-01-01') FROM {{ this }} AS t)
        UNION
        SELECT ccont.hk_customer FROM {{ ref('sat_customer_contact') }} AS ccont WHERE ccont.load_ts > (SELECT COALESCE(MAX(t2.valid_from), '1900-01-01') FROM {{ this }} AS t2)
    {% else %}
        SELECT hc.hk_customer FROM {{ ref('hub_customer') }} AS hc
    {% endif %}
),

-- 2. Собираем все точки изменения времени (Spine)
all_changes AS (
    SELECT
        core.hk_customer,
        core.load_ts,
        core.customer_name,
        core.nation_key,
        core.market_segment,
        core.comment,
        NULL AS address,
        NULL AS phone,
        NULL AS account_balance
    FROM {{ ref('sat_customer_core') }} AS core
    WHERE core.hk_customer IN (SELECT cc.hk_customer FROM changed_customers AS cc)

    UNION ALL

    SELECT
        contact.hk_customer,
        contact.load_ts,
        NULL AS customer_name,
        NULL AS nation_key,
        NULL AS market_segment,
        NULL AS comment,
        contact.address,
        contact.phone,
        contact.account_balance
    FROM {{ ref('sat_customer_contact') }} AS contact
    WHERE contact.hk_customer IN (SELECT c2.hk_customer FROM changed_customers AS c2)
),

-- 3. Магия: заполняем пустоты последним известным значением
filled_changes AS (
    SELECT
        ac.hk_customer,
        ac.load_ts AS valid_from,
        LAST_VALUE(ac.customer_name) IGNORE NULLS OVER (PARTITION BY ac.hk_customer ORDER BY ac.load_ts) AS customer_name,
        LAST_VALUE(ac.nation_key) IGNORE NULLS OVER (PARTITION BY ac.hk_customer ORDER BY ac.load_ts) AS nation_key,
        LAST_VALUE(ac.market_segment) IGNORE NULLS OVER (PARTITION BY ac.hk_customer ORDER BY ac.load_ts) AS market_segment,
        LAST_VALUE(ac.comment) IGNORE NULLS OVER (PARTITION BY ac.hk_customer ORDER BY ac.load_ts) AS comment,
        LAST_VALUE(ac.address) IGNORE NULLS OVER (PARTITION BY ac.hk_customer ORDER BY ac.load_ts) AS address,
        LAST_VALUE(ac.phone) IGNORE NULLS OVER (PARTITION BY ac.hk_customer ORDER BY ac.load_ts) AS phone,
        LAST_VALUE(ac.account_balance) IGNORE NULLS OVER (PARTITION BY ac.hk_customer ORDER BY ac.load_ts) AS account_balance
    FROM all_changes AS ac
),

-- 4. Убираем дубликаты
deduped_changes AS (
    SELECT
        fc.hk_customer,
        fc.valid_from,
        fc.customer_name,
        fc.nation_key,
        fc.market_segment,
        fc.comment,
        fc.address,
        fc.phone,
        fc.account_balance,
        ROW_NUMBER() OVER (PARTITION BY fc.hk_customer, fc.valid_from ORDER BY fc.valid_from) AS rn
    FROM filled_changes AS fc
),

-- 5. Вычисляем valid_to
scd2_timeline AS (
    SELECT
        dc.hk_customer,
        dc.valid_from,
        COALESCE(LEAD(dc.valid_from) OVER (PARTITION BY dc.hk_customer ORDER BY dc.valid_from), TO_TIMESTAMP('9999-12-31 23:59:59')) AS valid_to,
        dc.customer_name,
        dc.nation_key,
        dc.market_segment,
        dc.comment,
        dc.address,
        dc.phone,
        dc.account_balance
    FROM deduped_changes AS dc
    WHERE dc.rn = 1
)

-- 6. Формируем итоговую витрину
SELECT
    {{ dbt_utils.generate_surrogate_key(['h.customer_key', 's.valid_from']) }} AS customer_sk,
    h.customer_key,
    s.customer_name,
    s.nation_key,
    s.market_segment,
    s.comment,
    s.address,
    s.phone,
    s.account_balance,
    s.valid_from,
    s.valid_to,
    CAST(COALESCE(s.valid_to = TO_TIMESTAMP('9999-12-31 23:59:59'), FALSE) AS BOOLEAN) AS is_current
FROM scd2_timeline AS s
INNER JOIN {{ ref('hub_customer') }} AS h ON s.hk_customer = h.hk_customer
