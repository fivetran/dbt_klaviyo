with person_flow as (
    
    select *
    from {{ ref('int_klaviyo__person_campaign_flow') }}

    where last_touch_message_type = 'flow' 
),

fields as (

    {% set exclude_fields = ['campaign_name', 'last_touch_campaign_or_flow_id', 'last_touch_message_type'] %}
    {% set exclude_fields = exclude_fields | upper if target.type == 'snowflake' else exclude_fields %}

    select
        last_touch_campaign_or_flow_id as flow_id,
        {{ dbt_utils.star(from=ref('int_klaviyo__person_campaign_flow'), except=exclude_fields) }}

    from person_flow
)

select *
from fields