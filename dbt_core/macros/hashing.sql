{#
    hashing.sql — Centralised SHA-256 hashing macros for Data Vault 2.0.
    All business keys are UPPER-trimmed before hashing to ensure
    case-insensitive, whitespace-safe hash key consistency.
#}

{% macro hash_key(column) -%}
    SHA2(UPPER(TRIM(CAST({{ column }} AS VARCHAR))), 256)
{%- endmacro %}


{% macro multi_hash_key(columns) -%}
    SHA2(
        {%- for col in columns %}
        UPPER(TRIM(CAST({{ col }} AS VARCHAR)))
        {%- if not loop.last %} || '||' || {% endif %}
        {%- endfor %}
    , 256)
{%- endmacro %}


{% macro hash_diff(columns) -%}
    SHA2(
        {%- for col in columns %}
        COALESCE(UPPER(TRIM(CAST({{ col }} AS VARCHAR))), '^^')
        {%- if not loop.last %} || '|~|' || {% endif %}
        {%- endfor %}
    , 256)
{%- endmacro %}
