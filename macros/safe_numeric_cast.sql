{%- macro safe_numeric_cast(field) -%}
    {{ return(adapter.dispatch('safe_numeric_cast', 'klaviyo')(field)) }}
{%- endmacro -%}

{%- macro default__safe_numeric_cast(field) -%}
    try_cast({{ field }} as {{ dbt.type_numeric() }})
{%- endmacro -%}

{#- Redshift's adapter dispatch falls back to postgres__ before default__ since dbt-redshift
    extends dbt-postgres, so this needs to stay explicit to keep using native TRY_CAST instead
    of postgres__safe_numeric_cast's regex-guarded cast. -#}
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

{%- macro bigquery__safe_numeric_cast(field) -%}
    safe_cast({{ field }} as {{ dbt.type_numeric() }})
{%- endmacro -%}
