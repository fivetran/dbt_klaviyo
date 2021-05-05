with flow as (

    select *
    from {{ var('flow') }}
),

flow_metrics as (

    select *
    from {{ ref('int_klaviyo__campaign_flow_metrics') }}
    where last_touch_flow_id is not null -- only pull flows
),

flow_join as (
    
    {% set exclude_fields = [ 'last_touch_campaign_id', 'last_touch_flow_id'] %}
    {% set exclude_fields = exclude_fields | upper if target.type == 'snowflake' else exclude_fields %} -- snowflake needs uppercase :)

    select
        flow.*, -- has flow_id
        {{ dbt_utils.star(from=ref('int_klaviyo__campaign_flow_metrics'), except=exclude_fields) }}

    from flow
    left join flow_metrics on flow.flow_id = flow_metrics.last_touch_flow_id
),

final as (

    select 
        *,
        {{ dbt_utils.surrogate_key(['flow_id','variation_id']) }} as flow_variation_key

    from flow_join
)

select *
from final