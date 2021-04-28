with events as (
    select *
    from {{ ref('klaviyo__events') }}
),

-- query that selects all distinct event types and we can allow customers to suppress at the individual event and intehgration level 
{% set conversion_metrics_query %}
    select distinct type from {{ ref('klaviyo__events') }} where {{ var('klaviyo__pivot_conversion_filter') }} -- default: true
{% endset %}
{% set conversion_metric_results = run_query(conversion_metrics_query) %}

-- selects all distinct event types with some sort of revenue value attached
{% set revenue_metrics_query %}
    select distinct type from {{ ref('klaviyo__events') }} 
    where {{ var('klaviyo__pivot_conversion_filter') }} and numeric_value is not null
{% endset %}
{% set revenue_metric_results = run_query(revenue_metrics_query) %}

{% if execute %}
    {% set conversion_metrics = conversion_metric_results.columns[0].values() %}
    {% set revenue_metrics = revenue_metric_results.columns[0].values() %}
{% else %} -- use default klaviyo + API events
    {% set conversion_metrics = [
            'Active on Site',
            'Viewed Product',
            'Received Email' ,
            'Clicked Email',
            'Opened Email',
            'Bounced Email',
            'Marked Email as Spam',
            'Dropped Email',
            'Subscribed to List',
            'Unsubscribed to List',
            'Unsubscribed',
            'Updated Email Preferences',
            'Subscribed to Back in Stock',
            'Merged Profile',
            'Received SMS',
            'Clicked SMS',
            'Consented to Receive SMS',
            'Sent SMS',
            'Unsubscribed from SMS',
            'Failed to Deliver SMS'
        ] %}

    {% set revenue_metrics = ['Placed Order', 'Refunded Order'] %}
{% endif %}

pivot_out_events as (
    
    select 
        person_id,
        last_touch_campaign_or_flow_id,
        last_touch_message_type,
        campaign_name,
        flow_name,
        variation_id
        
    -- look at revenue
    {% for rm in revenue_metrics %}
    , sum(case when lower(type) = '{{ rm | lower }}' then numeric_value else 0 end) as {{ 'sum_revenue_' ~ rm | replace(' ', '_') | lower }}
    {% endfor %}

    -- look at revenue associated stuff
    {% for cm in conversion_metrics %}
    , sum(case when lower(type) = '{{ cm | lower }}' then 1 else 0 end) as {{ 'count_' ~ cm | replace(' ', '_') | replace('(', '') | replace(')', '') | lower }}
    -- can perhaps create a variable to add up any other columns...
    {% endfor %}

    from events
    group by 1,2,3,4,5,6
)

select *
from pivot_out_events