{%- macro safe_numeric_cast(field) -%}
    {{ return(adapter.dispatch('safe_numeric_cast', 'klaviyo')(field)) }}
{%- endmacro -%}

{%- macro default__safe_numeric_cast(field) -%}
    {{ fivetran_utils.try_cast(field, "numeric") }}
{%- endmacro -%}

{%- macro redshift__safe_numeric_cast(field) -%}
    try_cast({{ field }} as {{ dbt.type_numeric() }})
{%- endmacro -%}

{%- macro postgres__safe_numeric_cast(field) -%}
    case
        when trim(cast({{ field }} as {{ dbt.type_string() }})) ~ '^(0|[1-9][0-9]*)(\.[0-9]+)?$'
        then trim(cast({{ field }} as {{ dbt.type_string() }}))::{{ dbt.type_numeric() }}
        else null
    end
{%- endmacro -%}
