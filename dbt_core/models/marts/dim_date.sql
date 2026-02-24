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
    date_day                                            AS date_actual,
    EXTRACT(day FROM date_day)                          AS day_of_month,
    EXTRACT(month FROM date_day)                        AS month_actual,
    EXTRACT(year FROM date_day)                         AS year_actual,
    EXTRACT(quarter FROM date_day)                      AS quarter_actual,
    EXTRACT(dayofweek FROM date_day)                    AS day_of_week,
    TO_CHAR(date_day, 'Month')                          AS month_name,
    TO_CHAR(date_day, 'Day')                            AS day_name,
    CASE WHEN EXTRACT(dayofweek FROM date_day) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend
FROM date_spine
