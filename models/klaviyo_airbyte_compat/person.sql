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
        id as person_id,

        {{ json_get('attributes', '$.email') }} as email,
        {{ json_get('attributes', '$.phone_number') }} as phone_number,
        {{ json_get('attributes', '$.first_name') }} as first_name,
        {{ json_get('attributes', '$.last_name') }} as last_name,
        concat_ws(' ', {{ json_get('attributes', '$.first_name') }}, {{ json_get('attributes', '$.last_name') }}) as full_name,

        {{ json_get('attributes', '$.organization') }} as organization,
        {{ json_get('attributes', '$.title') }} as title,
        {{ json_get('attributes', '$.locale') }} as locale,

        {{ json_get('attributes', '$.location.address1') }} as address_1,
        {{ json_get('attributes', '$.location.address2') }} as address_2,
        {{ json_get('attributes', '$.location.city') }} as city,
        {{ json_get('attributes', '$.location.region') }} as region,
        {{ json_get('attributes', '$.location.country') }} as country,
        {{ json_get('attributes', '$.location.zip') }} as zip,
        cast({{ json_get('attributes', '$.location.latitude') }} as double) as latitude,
        cast({{ json_get('attributes', '$.location.longitude') }} as double) as longitude,
        {{ json_get('attributes', '$.location.timezone') }} as timezone,

        {{ json_ts('attributes', '$.created') }} as created_at,
        {{ json_ts('attributes', '$.updated') }} as updated_at,
        {{ json_ts('attributes', '$.last_event_date') }} as last_event_date,

        _airbyte_extracted_at as _fivetran_synced,
        cast('0006_wsg.klaviyo_raw' as string) as source_relation

    from {{ source('klaviyo_airbyte_raw', 'profiles') }}
)

select * from src
