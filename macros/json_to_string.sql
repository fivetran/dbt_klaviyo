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
    {{ column }}
{%- endmacro -%}

{%- macro bigquery__json_to_string(column, column_list) -%}
    {%- set column_type = klaviyo.get_column_type(column, column_list) -%}

    {%- if column_type == 'json' -%}
        to_json_string({{ column }})
    {%- else -%}
        {{ column }}
    {%- endif -%}
{%- endmacro -%}

{%- macro postgres__json_to_string(column, column_list) -%}
    {%- set column_type = klaviyo.get_column_type(column, column_list) -%}

    {%- if column_type in ('json', 'jsonb') -%}
        {{ column }}::text
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

{%- macro redshift__json_to_string(column, column_list) -%}
    {%- set column_type = klaviyo.get_column_type(column, column_list) -%}

    {%- if column_type == 'super' -%}
        json_serialize({{ column }})
    {%- else -%}
        {{ column }}
    {%- endif -%}
{%- endmacro -%}