{%- macro safe_numeric_cast(field) -%}
    {{ return(adapter.dispatch('safe_numeric_cast', 'klaviyo')(field)) }}
{%- endmacro -%}

{%- macro default__safe_numeric_cast(field) -%}
    try_cast({{ field }} as {{ dbt.type_numeric() }})
{%- endmacro -%}

{#- Kept explicit: dbt-redshift extends dbt-postgres, so dispatch would otherwise fall back to postgres__'s regex-guarded cast instead of native TRY_CAST. -#}
{%- macro redshift__safe_numeric_cast(field) -%}
    {{ default__safe_numeric_cast(field) }}
{%- endmacro -%}

{%- macro postgres__safe_numeric_cast(field) -%}
    case
        when trim(cast({{ field }} as {{ dbt.type_string() }})) ~ '^(0|[1-9][0-9]*)(\.[0-9]+)?$'
        then trim(cast({{ field }} as {{ dbt.type_string() }}))::{{ dbt.type_numeric() }}
        else null
    end
{%- endmacro -%}

{%- macro bigquery__safe_numeric_cast(field) -%}
    safe_cast({{ field }} as {{ dbt.type_numeric() }})
{%- endmacro -%}
