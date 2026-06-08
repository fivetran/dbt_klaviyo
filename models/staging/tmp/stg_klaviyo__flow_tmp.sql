{% if var('klaviyo_union_schemas', []) | length > 0 or var('klaviyo_union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='flow', 
        database_variable='klaviyo_database', 
        schema_variable='klaviyo_schema', 
        default_database=target.database,
        default_schema='klaviyo',
        default_variable='flow',
        union_schema_variable='klaviyo_union_schemas',
        union_database_variable='klaviyo_union_databases'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='klaviyo_sources',
        single_source_name='klaviyo',
        single_table_name='flow'
    )
}}

{% endif %}