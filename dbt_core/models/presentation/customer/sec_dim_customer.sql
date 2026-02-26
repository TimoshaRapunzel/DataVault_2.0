{{ config(
    materialized='view',
    secure=true,
    tags=['presentation', 'secure', 'rls']
) }}

/*
    Модель безопасности для данных клиентов.
    Ограничивает доступ аналитиков по регионам (RLS) и
    скрывает технические детали SCD2, оставляя только актуальные данные.
*/

WITH customer_data AS (
    -- Ссылаемся на витрину
    SELECT * FROM {{ ref('dim_customer') }}
    -- Фильтруем, чтобы видеть только текущие актуальные версии записей (SCD2)
    -- Используем is_current, так как ты заботливо добавил его в dim_customer
    WHERE is_current = TRUE
)

SELECT
    -- Ключи
    customer_sk,
    customer_key,

    -- Бизнес-атрибуты
    customer_name,
    address,
    nation_key,
    phone,
    market_segment,
    account_balance,
    comment

FROM customer_data
WHERE
    -- 1. Администраторы и системные роли видят все данные
    CURRENT_ROLE() IN ('SYSADMIN', 'ACCOUNTADMIN', 'DATA_OWNER')

    -- 2. Политика RLS: Аналитики Европы (ANALYST_EUROPE) видят только свои страны (Nation Keys)
    OR (
        CURRENT_ROLE() = 'ANALYST_EUROPE'
        AND nation_key IN (7, 14, 19, 21) -- Nation keys для европейского региона
    )

    -- 3. Политика RLS: Аналитики Америки (ANALYST_AMERICA)
    OR (
        CURRENT_ROLE() = 'ANALYST_AMERICA'
        AND nation_key IN (1, 2, 3, 17, 24)
    )
