with events as (
    select *
    from {{ ref('klaviyo__events') }}
),

pivot_out_events as (
    
    select 
        person_id,
        last_touch_campaign_id,
        last_touch_flow_id,
        campaign_name,
        flow_name,
        variation_id,
        min(occurred_at) as first_touch_at,
        max(occurred_at) as last_touch_at

    -- sum up the numeric value associated with events (most likely will mean revenue)
    {% for rm in var('klaviyo__sum_revenue_metrics') %}
    , sum(case when lower(type) = '{{ rm | lower }}' then numeric_value else 0 end) 
        as {{ 'sum_revenue_' ~ rm | replace(' ', '_') | replace('(', '') | replace(')', '') | lower }} -- removing special characters that I have seen in different integration events
    {% endfor %}

    -- count up the number of instances of each metric
    {% for cm in var('klaviyo__count_metrics') %}
    , sum(case when lower(type) = '{{ cm | lower }}' then 1 else 0 end) 
        as {{ 'count_' ~ cm | replace(' ', '_') | replace('(', '') | replace(')', '') | lower }} -- removing special characters that I have seen in different integration events
    {% endfor %}

    from events
    group by 1,2,3,4,5,6
)

select *
from pivot_out_events