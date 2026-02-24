{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='customer_sk',
    tags=['mart', 'dimension']
) }}

-- 1. Определяем, какие клиенты обновились (для инкрементальной загрузки)
WITH changed_customers AS (
    {% if is_incremental() %}
        SELECT hk_customer FROM {{ ref('sat_customer_core') }} WHERE load_ts > (SELECT COALESCE(MAX(valid_from), '1900-01-01') FROM {{ this }})
        UNION
        SELECT hk_customer FROM {{ ref('sat_customer_contact') }} WHERE load_ts > (SELECT COALESCE(MAX(valid_from), '1900-01-01') FROM {{ this }})
    {% else %}
        SELECT hk_customer FROM {{ ref('hub_customer') }}
    {% endif %}
),

-- 2. Собираем все точки изменения времени (Spine) для этих клиентов из двух сателлитов
all_changes AS (
    SELECT
        hk_customer,
        load_ts,
        customer_name,
        nation_key,
        market_segment,
        comment,
        NULL AS address,
        NULL AS phone,
        NULL AS account_balance
    FROM {{ ref('sat_customer_core') }}
    WHERE hk_customer IN (SELECT hk_customer FROM changed_customers)

    UNION ALL

    SELECT
        hk_customer,
        load_ts,
        NULL AS customer_name,
        NULL AS nation_key,
        NULL AS market_segment,
        NULL AS comment,
        address,
        phone,
        account_balance
    FROM {{ ref('sat_customer_contact') }}
    WHERE hk_customer IN (SELECT hk_customer FROM changed_customers)
),

-- 3. Магия: заполняем пустоты последним известным значением
filled_changes AS (
    SELECT
        hk_customer,
        load_ts AS valid_from,
        LAST_VALUE(customer_name) IGNORE NULLS OVER (PARTITION BY hk_customer ORDER BY load_ts) AS customer_name,
        LAST_VALUE(nation_key) IGNORE NULLS OVER (PARTITION BY hk_customer ORDER BY load_ts) AS nation_key,
        LAST_VALUE(market_segment) IGNORE NULLS OVER (PARTITION BY hk_customer ORDER BY load_ts) AS market_segment,
        LAST_VALUE(comment) IGNORE NULLS OVER (PARTITION BY hk_customer ORDER BY load_ts) AS comment,
        LAST_VALUE(address) IGNORE NULLS OVER (PARTITION BY hk_customer ORDER BY load_ts) AS address,
        LAST_VALUE(phone) IGNORE NULLS OVER (PARTITION BY hk_customer ORDER BY load_ts) AS phone,
        LAST_VALUE(account_balance) IGNORE NULLS OVER (PARTITION BY hk_customer ORDER BY load_ts) AS account_balance
    FROM all_changes
),

-- 4. Убираем дубликаты (если изменения произошли в одну миллисекунду)
deduped_changes AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY hk_customer, valid_from ORDER BY valid_from) as rn
    FROM filled_changes
),

-- 5. Вычисляем valid_to (когда запись перестала быть актуальной)
scd2_timeline AS (
    SELECT
        hk_customer,
        valid_from,
        COALESCE(LEAD(valid_from) OVER (PARTITION BY hk_customer ORDER BY valid_from), TO_TIMESTAMP('9999-12-31 23:59:59')) AS valid_to,
        customer_name,
        nation_key,
        market_segment,
        comment,
        address,
        phone,
        account_balance
    FROM deduped_changes
    WHERE rn = 1
)

-- 6. Формируем итоговую SCD2 витрину
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
    CAST(CASE WHEN s.valid_to = TO_TIMESTAMP('9999-12-31 23:59:59') THEN TRUE ELSE FALSE END AS BOOLEAN) AS is_current
FROM scd2_timeline s
JOIN {{ ref('hub_customer') }} h ON s.hk_customer = h.hk_customer