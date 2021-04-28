with person_campaign_flow as (

    select *
    from {{ ref('int_klaviyo__person_campaign_flow') }}
),

{%- set pcf_columns = adapter.get_columns_in_relation(ref('int_klaviyo__person_campaign_flow')) %}

agg_metrics as (

    select
        last_touch_campaign_id,
        last_touch_flow_id,
        variation_id,
        count(distinct person_id) as total_count_unique_people,
        min(first_touch_at) as first_touch_at,
        max(last_touch_at) as last_touch_at
        
        {% for col in pcf_columns if col.name|lower not in ['last_touch_campaign_id', 'person_id', 'last_touch_flow_id', 
                                                            'campaign_name', 'flow_name','variation_id', 'first_touch_at', 'last_touch_at'] %}
        -- add up all instances of these events
        , sum( {{ col.name }} ) as {{ col.name }}
        {% if 'sum_revenue' not in col.name|lower %}
        -- get unique users
        , sum(case when {{ col.name }} = 0 then 1 else 0 end) as {{ 'unique_' ~ col.name }}

        {% endif %}
        {% endfor -%}

    from person_campaign_flow
    group by 1,2,3
)

select * from agg_metrics