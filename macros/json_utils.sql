{% macro json_get(json_col, json_path) -%}
  -- Extract a scalar value from a JSON string column using the provided path.
  -- Example json_path values: '$.name', '$.location.city', '$.profile.data.id'
  get_json_object({{ json_col }}, '{{ json_path }}')
{%- endmacro %}

{% macro json_bool(json_col, json_path) -%}
  cast({{ json_get(json_col, json_path) }} as boolean)
{%- endmacro %}

{% macro json_ts(json_col, json_path) -%}
  -- Cast a JSON string timestamp to a timestamp type. Databricks can parse most ISO-8601 formats directly.
  cast({{ json_get(json_col, json_path) }} as timestamp)
{%- endmacro %}
