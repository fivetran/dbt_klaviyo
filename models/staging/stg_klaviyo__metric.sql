with base as (

    select * 
    from {{ ref('stg_klaviyo__metric_tmp') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_klaviyo__metric_tmp')),
                staging_columns=get_metric_columns()
            )
        }}
        {{ fivetran_utils.apply_source_relation(package_name='klaviyo') }}
    from base
),

final as (
    
    select 
        created as created_at,
        cast(id as {{ dbt.type_string() }} ) as metric_id,
        cast(integration_id as {{ dbt.type_string() }} ) as integration_id,
        integration_name,
        integration_category,
        name as metric_name,
        updated as updated_at,
        source_relation

    from fields

    where not coalesce(_fivetran_deleted, false)
)

select * from final