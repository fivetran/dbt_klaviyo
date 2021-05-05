with person_campaign_flow as (

    select *
    from {{ ref('klaviyo__person_campaign_flow') }}
),

{%- set pcf_columns = adapter.get_columns_in_relation(ref('klaviyo__person_campaign_flow')) %}

agg_metrics as (

    select
        person_id,
        count(distinct last_touch_campaign_id) as count_total_campaigns,
        count(distinct last_touch_flow_id) as count_total_flows,
        min(first_touch_at) as first_touch_at, -- first ever event occurred at
        max(last_touch_at) as last_touch_at, -- last ever event occurred at
        min(distinct case when last_touch_campaign_id is not null then first_touch_at end) as first_campaign_touch_at,
        max(distinct case when last_touch_campaign_id is not null then last_touch_at end) as last_campaign_touch_at,
        min(distinct case when last_touch_flow_id is not null then first_touch_at end) as first_flow_touch_at,
        max(distinct case when last_touch_flow_id is not null then last_touch_at end) as last_flow_touch_at

        {% for col in pcf_columns if col.name|lower not in ['last_touch_campaign_id', 'person_id', 'last_touch_flow_id', 
                                                            'campaign_name', 'flow_name','variation_id', 'first_touch_at', 'last_touch_at'] %}
        -- sum up any count/sum_revenue metrics -> prefix with `total` since we're pulling out organic sums as well
        , sum( {{ col.name }} ) as {{ 'total_' ~ col.name }}

        -- let's pull out the organic revenue sums
        {% if 'sum_revenue' in col.name|lower %}
        , sum( case when coalesce(last_touch_campaign_id, last_touch_flow_id) is null then {{ col.name }} else 0 end ) as {{ 'organic_' ~ col.name }}
        {% endif %}

        {% endfor -%}

    from person_campaign_flow
    group by 1

)

select * from agg_metrics