{{
    config(
        materialized='table',
        schema='klaviyo_airbyte_compat',
        database='0006_wsg',
        file_format='delta'
    )
}}

with src as (
    select
        id as campaign_id,
        type as campaign_resource_type,
        {{ json_get('attributes', '$.name') }} as campaign_name,
        {{ json_get('attributes', '$.status') }} as status,
        {{ json_bool('attributes', '$.archived') }} as is_archived,
        {{ json_ts('attributes', '$.created_at') }} as created_at,
        {{ json_ts('attributes', '$.updated_at') }} as updated_at,
        {{ json_ts('attributes', '$.scheduled_at') }} as scheduled_at,
        {{ json_ts('attributes', '$.send_time') }} as sent_at,
        {{ json_get('attributes', '$.channel') }} as channel,

        _airbyte_extracted_at as _fivetran_synced,
        cast('0006_wsg.klaviyo_raw' as string) as source_relation

    from {{ source('klaviyo_airbyte_raw', 'campaigns') }}
)

select * from src
