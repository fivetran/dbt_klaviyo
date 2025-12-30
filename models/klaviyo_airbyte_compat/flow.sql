{{
    config(
        materialized='table',
        schema='klaviyo_airbyte_compat',
        database='0006_wsg',
        file_format='delta'
    )
}}

select
    id as flow_id,
    {{ json_get('attributes', '$.name') }} as flow_name,
    {{ json_get('attributes', '$.status') }} as status,
    {{ json_ts('attributes', '$.created') }} as created_at,
    {{ json_ts('attributes', '$.updated') }} as updated_at,
    _airbyte_extracted_at as _fivetran_synced,
    cast('0006_wsg.klaviyo_raw' as string) as source_relation
from {{ source('klaviyo_airbyte_raw', 'flows') }}
