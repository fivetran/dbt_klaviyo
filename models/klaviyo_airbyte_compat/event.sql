{{
    config(
        materialized='incremental',
        schema='klaviyo_airbyte_compat',
        database='0006_wsg',
        file_format='delta',
        unique_key='event_id',
        incremental_strategy='merge'
    )
}}

with src as (
    select
        id as event_id,
        datetime as occurred_at,

        coalesce(
            {{ json_get('attributes', '$.event_name') }},
            {{ json_get('attributes', '$.name') }},
            type
        ) as type,

        {{ json_get('relationships', '$.metric.data.id') }} as metric_id,
        {{ json_get('relationships', '$.profile.data.id') }} as person_id,

        cast({{ json_get('attributes', '$.numeric_value') }} as decimal(28, 6)) as numeric_value,
        {{ json_get('attributes', '$.uuid') }} as uuid,

        md5(concat_ws('||',
          coalesce(id, ''),
          coalesce({{ json_get('relationships', '$.metric.data.id') }}, ''),
          coalesce({{ json_get('relationships', '$.profile.data.id') }}, ''),
          coalesce(cast(datetime as string), '')
        )) as unique_event_id,

        cast(date(datetime) as date) as occurred_on,

        _airbyte_extracted_at as _fivetran_synced,
        cast('0006_wsg.klaviyo_raw' as string) as source_relation,

        attributes as attributes_json,
        relationships as relationships_json

    from {{ source('klaviyo_airbyte_raw', 'events') }}
)

select *
from src
{% if is_incremental() %}
where _airbyte_extracted_at > (select coalesce(max(_fivetran_synced), cast('1900-01-01' as timestamp)) from {{ this }})
{% endif %}
