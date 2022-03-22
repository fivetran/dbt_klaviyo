{% macro try_cast(field, type) %}
    {{ return(adapter.dispatch('try_cast') (field, type)) }}
{% endmacro %}

{% macro default__try_cast(field, type) %}
    cast({{field}} as {{type}})
{% endmacro %}

{% macro postgres__try_cast(field, type) %}
    CREATE OR REPLACE FUNCTION try_cast(_in text, INOUT _out ANYELEMENT)
        LANGUAGE plpgsql AS
    $func$
BEGIN
   EXECUTE format('SELECT %L::%s', $1, pg_typeof(_out))
   INTO  _out;
EXCEPTION WHEN others THEN
   -- do nothing: _out already carries default
END
$func$
{% endmacro %}


{% macro bigquery__try_cast(field, type) %}
    safe_cast({{field}} as {{type}})
{% endmacro %}


{% macro redshift__try_cast(field, type) %}
{%- if type == 'bigint' or type == 'int' or type == 'numeric' -%}

    case
        when trim({{field}}) ~ '^(0|[1-9][0-9]*)$' then trim({{field}})
        else null
    end::{{type}}

{% else %}

    {{ exceptions.raise_compiler_error(
            "non-integer datatypes are not currently supported") }}

{% endif %}
{% endmacro %}


{% macro snowflake__try_cast(field, type) %}
    try_cast({{field}} as {{type}})
{% endmacro %}


{% macro spark__try_cast(field, type) %}
    try_cast({{field}} as {{type}})
{% endmacro %}