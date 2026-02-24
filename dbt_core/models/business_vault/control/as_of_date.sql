
{{ config(materialized='table') }}



WITH date_spine AS (

    {{ dbt_utils.date_spine(

        datepart="day",

        start_date="cast('2023-01-01' as date)", 

        end_date="dateadd(day, 1, current_date())"

    ) }}

)



SELECT

    CAST(date_day AS TIMESTAMP) AS sdts,

    TRUE AS is_active

FROM date_spine

