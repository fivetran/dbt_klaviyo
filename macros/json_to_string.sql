{%- macro json_to_string(column, column_list) -%}
    {{ return(adapter.dispatch('json_to_string', 'klaviyo')(column, column_list)) }}
{%- endmacro -%}

{%- macro get_column_type(column, column_list) -%}
    {%- set ns = namespace(column_type='string') -%}
    {%- for col in column_list if col.name|lower == column|lower -%}
        {%- set ns.column_type = col.dtype|lower -%}
    {%- endfor -%}
    {{ return(ns.column_type) }}
{%- endmacro -%}

{%- macro default__json_to_string(column, column_list) -%}
    cast({{ column }} as {{ dbt.type_string() }})
{%- endmacro -%}

{%- macro bigquery__json_to_string(column, column_list) -%}
    {%- set column_type = klaviyo.get_column_type(column, column_list) -%}

    {%- if column_type == 'json' -%}
        to_json_string({{ column }})
    {%- else -%}
        {{ column }}
    {%- endif -%}
{%- endmacro -%}

{%- macro snowflake__json_to_string(column, column_list) -%}
    {%- set column_type = klaviyo.get_column_type(column, column_list) -%}

    {%- if column_type == 'variant' -%}
        to_json({{ column }})
    {%- else -%}
        {{ column }}
    {%- endif -%}
{%- endmacro -%}