{{
    config(
        materialized='table',
        schema='klaviyo_airbyte_compat',
        database='0006_wsg',
        file_format='delta'
    )
}}

select
    id as metric_id,
    {{ json_get('attributes', '$.name') }} as metric_name,
    {{ json_get('attributes', '$.integration.name') }} as integration_name,
    {{ json_get('attributes', '$.integration.category') }} as integration_category,
    _airbyte_extracted_at as _fivetran_synced,
    cast('0006_wsg.klaviyo_raw' as string) as source_relation
from {{ source('klaviyo_airbyte_raw', 'metrics') }}
