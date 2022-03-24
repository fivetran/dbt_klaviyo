{% macro try_cast(field, type) %}
    {{ return(adapter.dispatch('try_cast') (field, type)) }}
{% endmacro %}

{% macro default__safe_cast(field, type) %}
    {# most databases don't support this function yet
    so we just need to use cast #}
    cast({{field}} as {{type}})
{% endmacro %}

{% macro redshift__try_cast(field, type) %}
{%- if type == 'numeric' -%}

    case
        when trim({{field}}) ~ '^(0|[1-9][0-9]*)$' then trim({{field}})
        else null
    end::{{type}}

{% else %}
    {{ exceptions.raise_compiler_error(
            "non-numeric datatypes are not currently supported") }}

{% endif %}
{% endmacro %}

{% macro postgres__try_cast(field, type) %}
{%- if type == 'numeric' -%}

    case
        when replace(cast({{field}} as varchar),cast(' ' as varchar),cast('' as varchar)) ~ '^(0|[1-9][0-9]*)$' 
        then replace(cast({{field}} as varchar),cast(' ' as varchar),cast('' as varchar))
        else null
    end::{{type}}

{% else %}
    {{ exceptions.raise_compiler_error(
            "non-numeric datatypes are not currently supported") }}

{% endif %}
{% endmacro %}

{% macro snowflake__try_cast(field, type) %}
    try_cast({{field}} as {{type}})
{% endmacro %}

{% macro bigquery__try_cast(field, type) %}
    safe_cast({{field}} as {{type}})
{% endmacro %}

{% macro spark__try_cast(field, type) %}
    try_cast({{field}} as {{type}})
{% endmacro %}