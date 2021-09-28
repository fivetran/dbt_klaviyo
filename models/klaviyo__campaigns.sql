with campaign as (

    select *
    from {{ var('campaign') }}
),

campaign_metrics as (

    select *
    from {{ ref('int_klaviyo__campaign_flow_metrics') }}
),

campaign_join as (
    
    {% set exclude_fields = [ 'last_touch_campaign_id', 'last_touch_flow_id'] %}
    {% set exclude_fields = exclude_fields %} 

    select
        campaign.*, -- has campaign_id
        {{ dbt_utils.star(from=ref('int_klaviyo__campaign_flow_metrics'), except=exclude_fields) }}

    from campaign
    left join campaign_metrics on campaign.campaign_id = campaign_metrics.last_touch_campaign_id
),

final as (

    select 
        *,
        {{ dbt_utils.surrogate_key(['campaign_id','variation_id']) }} as campaign_variation_key

    from campaign_join
)

select *
from final