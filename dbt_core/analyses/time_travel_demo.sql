-- === Snowflake Time Travel Demonstration ===

-- 1. DDL: Увеличение периода удержания данных для таблицы (Time Travel)
ALTER TABLE RETAIL_VAULT.RAW_VAULT.SAT_CUSTOMER_LF SET DATA_RETENTION_TIME_IN_DAYS = 7;

-- 2. DDL: Создание клона таблицы на определенный момент времени (Zero-copy cloning)
CREATE TABLE RETAIL_VAULT.RAW_VAULT.SAT_CUSTOMER_LF_BACKUP
CLONE RETAIL_VAULT.RAW_VAULT.SAT_CUSTOMER_LF
BEFORE (TIMESTAMP => DATEADD(minute, -5, CURRENT_TIMESTAMP()));

-- 3. DML: Восстановление случайно удаленной записи (Undrop via Time Travel)
-- (Пример логики восстановления через вставку из прошлого состояния)
INSERT INTO RETAIL_VAULT.RAW_VAULT.SAT_CUSTOMER_LF
SELECT * FROM RETAIL_VAULT.RAW_VAULT.SAT_CUSTOMER_LF AT(OFFSET => -3600); -- Состояние час назад

-- 4. DML: Просмотр состояния данных "как это было" вчера
SELECT *
FROM RETAIL_VAULT.STAGING.STG_TPCH_CUSTOMER
BEFORE (TIMESTAMP => DATEADD(day, -1, CURRENT_TIMESTAMP()));
