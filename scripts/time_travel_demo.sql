-- ==========================================
-- Демонстрация Snowflake Time Travel
-- ==========================================

-- 1. Смотрим текущее количество строк в витрине
SELECT COUNT(*) FROM retail_vault.staging.dim_part;

-- 2. Запоминаем текущее время (в реальной жизни мы бы сохранили timestamp)
SET current_ts = CURRENT_TIMESTAMP();

-- 3. Эмулируем случайное удаление данных (ОЙ!)
DELETE FROM retail_vault.staging.dim_part WHERE manufacturer = 'Manufacturer#1';

-- Проверяем, что строки пропали
SELECT COUNT(*) FROM retail_vault.staging.dim_part WHERE manufacturer = 'Manufacturer#1';

-- 4. МАГИЯ TIME TRAVEL: Запрашиваем данные на момент ДО удаления
-- Используем сохраненный timestamp (или конкретное время, например: AT(OFFSET => -60*5) для 5 минут назад)
SELECT COUNT(*) 
FROM retail_vault.staging.dim_part AT(TIMESTAMP => $current_ts)
WHERE manufacturer = 'Manufacturer#1';

-- 5. Восстановление таблицы после случайного DROP (UNDROP)
DROP TABLE retail_vault.staging.dim_part;
-- Ошибка, таблицы нет!
-- SELECT * FROM retail_vault.staging.dim_part; 

-- Восстанавливаем таблицу со всеми данными и метаданными
UNDROP TABLE retail_vault.staging.dim_part;