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
    -- Ссылаемся на исправленную модель витрины
    SELECT * FROM {{ ref('dim_customer') }}
    -- Фильтруем, чтобы видеть только текущие актуальные версии записей (SCD2)
    WHERE CURRENT_TIMESTAMP() BETWEEN valid_from AND valid_to
)

SELECT
    hk_customer,
    customer_name,
    address,
    nation_key,
    phone,
    market_segment,
    account_balance,
    -- Поля loyalty_tier и is_active должны присутствовать в dim_customer
    -- Если dbt ругается на их отсутствие, проверь их наличие в сателлитах
    loyalty_tier,
    is_active
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
