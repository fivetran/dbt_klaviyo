-- note that the macro only takes numeric-type data casts

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
{%- if lower(type) = 'bigint' or lower(type) == 'int' or lower(type) == 'int64' -%}
    postgres_type = 'dbt_utils.type_int()' 

{%- if lower(type) = 'numeric' -%}
    postgres_type = 'dbt_utils.type_numeric()'

{%- if lower(type) = 'float64' or lower(type) = 'float' -%}
    postgres_type = 'dbt_utils.type_float()'

{% else %}
    postgres_type = type
{% endif %}

    ifnull(cast( {{field}} as {{postgres_type}} ), 0)

{% endif %}

{% endmacro %}


{% macro redshift__try_cast(field, type) %}
{%- if lower(type) = 'bigint' or lower(type) == 'int' or lower(type) == 'int64' -%}
    redshift_type = 'dbt_utils.type_int()' 

{%- if lower(type) = 'numeric' -%}
    redshift_type = 'dbt_utils.type_numeric()'

{%- if lower(type) = 'float64' or lower(type) = 'float' -%}
    redshift_type = 'dbt_utils.type_float()'

{% else %}
    redshift_type = type
{% endif %}

    try_cast({{field}} as {{redshift_type}})

{% else %}

{% endif %}

{% endmacro %}


{% macro snowflake__try_cast(field, type) %}
{%- if lower(type) = 'bigint' or lower(type) == 'int' or lower(type) == 'int64' -%}
    snowflake_type = 'dbt_utils.type_int()' 

{%- if lower(type) = 'numeric' -%}
    snowflake_type = 'dbt_utils.type_numeric()'

{%- if lower(type) = 'float64' or lower(type) = 'float' -%}
    snowflake_type = 'dbt_utils.type_float()'

{% else %}

    snowflake_type = type

{% endif %}

    try_cast({{field}} as {{snowflake_type}})

{% endif %}

{% endmacro %}


{% macro spark__try_cast(field, type) %}
{%- if lower(type) = 'bigint' or lower(type) == 'int' or lower(type) == 'int64' -%}
    spark_type = 'dbt_utils.type_int()' 

{%- if lower(type) = 'numeric' -%}
    spark_type = 'dbt_utils.type_numeric()'

{%- if lower(type) = 'float64' or lower(type) = 'float' -%}
    spark_type = 'dbt_utils.type_float()'

{% else %}

    spark_type = type

{% endif %}

    try_cast({{field}} as {{spark_type}})

{% endif %}

{% endmacro %}


{% macro snowflake__safe_cast(field, type) %}
{%- if lower(type) = 'bigint' or lower(type) == 'int' or lower(type) == 'int64' -%}
    snowflake_type = 'dbt_utils.type_int()' 

{%- if lower(type) = 'numeric' -%}
    snowflake_type = 'dbt_utils.type_numeric()'

{%- if lower(type) = 'float64' or lower(type) = 'float' -%}
    snowflake_type = 'dbt_utils.type_float()'

{% else %}

    snowflake_type = type

{% endif %}

    try_cast({{field}} as {{snowflake_type}})

{% endmacro %}
