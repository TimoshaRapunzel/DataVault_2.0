SELECT COUNT(*) FROM retail_vault.staging.dim_part;
SET current_ts = CURRENT_TIMESTAMP();
DELETE FROM retail_vault.staging.dim_part WHERE manufacturer = 'Manufacturer#1';
SELECT COUNT(*) FROM retail_vault.staging.dim_part WHERE manufacturer = 'Manufacturer#1';
SELECT COUNT(*)
FROM retail_vault.staging.dim_part AT(TIMESTAMP => $current_ts)
WHERE manufacturer = 'Manufacturer#1';
DROP TABLE retail_vault.staging.dim_part;
UNDROP TABLE retail_vault.staging.dim_part;
