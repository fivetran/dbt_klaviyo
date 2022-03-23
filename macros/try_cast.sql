{% macro try_cast(field, type) %}
    {{ return(adapter.dispatch('try_cast') (field, type)) }}
{% endmacro %}

{% macro default__try_cast(field, type) %}
    cast({{field}} as {{type}})
{% endmacro %}

{% macro bigquery__try_cast(field, type) %}
{%- if lower(type) = 'bigint' or lower(type) == 'int' or lower(type) == 'int64' -%}
    bigquery_type = 'dbt_utils.type_int()' 

{%- if lower(type) = 'numeric' -%}
    bigquery_type = 'dbt_utils.type_numeric()'

{%- if lower(type) = 'float64' or lower(type) = 'float' -%}
    bigquery_type = 'dbt_utils.type_float()'

{% else %}
    bigquery_type = type
{% endif %}

    safe_cast({{field}} as {{bigquery_type}})

{% endmacro %}



{% macro postgres__try_cast(field, type) %}
-- {%- if type == 'bigint' or type == 'int' or type == 'numeric' -%}
    ifnull(cast( {{field}} as {{'type'}} ), 0)
{% endif %}

{% endmacro %}


{% macro redshift__try_cast(field, type) %}
-- {%- if type == 'bigint' or type == 'int' or type == 'numeric' -%}
    -- redshift_type = 'float'
    try_cast({{field}} as {{redshift_type}})
{% else %}

{% endif %}

{% endmacro %}


{% macro snowflake__try_cast(field, type) %}
-- {%- if type == 'bigint' or type == 'int' or type == 'numeric' -%}
    try_cast({{field}} as {{type}})
{% endif %}

{% endmacro %}


{% macro spark__try_cast(field, type) %}
-- {%- if type == 'bigint' or type == 'int' or type == 'numeric' -%}
    try_cast({{field}} as {{type}})
{% endif %}

{% endmacro %}


{% macro snowflake__safe_cast(field, type) %}
    try_cast({{field}} as {{type}})
{% endmacro %}


{% macro bigquery__safe_cast(field, type) %}
    safe_cast({{field}} as {{type}})
{% endmacro %}