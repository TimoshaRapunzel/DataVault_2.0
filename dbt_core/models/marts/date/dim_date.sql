{{ config(
    materialized='table',
    tags=['mart', 'dimension']
) }}

WITH date_spine AS (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('1990-01-01' as date)",
        end_date="cast('2030-01-01' as date)"
    ) }}
)

SELECT
    date_day AS date_actual,
    EXTRACT(DAY FROM date_day) AS day_of_month,
    EXTRACT(MONTH FROM date_day) AS month_actual,
    EXTRACT(YEAR FROM date_day) AS year_actual,
    EXTRACT(QUARTER FROM date_day) AS quarter_actual,
    EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week,
    TO_CHAR(date_day, 'Month') AS month_name,
    TO_CHAR(date_day, 'Day') AS day_name,
    COALESCE(EXTRACT(DAYOFWEEK FROM date_day) IN (0, 6), FALSE) AS is_weekend
FROM date_spine
