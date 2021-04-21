-- config as incremental....? will be a lil difficult
with events as (

    select
        *
        {# lag(occurred_at) over(partition by person_id order by occurred_at asc) as last_event_occurred_at #}

    from {{ var('event_table') }}

    {# {% if is_incremental() %}
    -- will probably have to grab all events related to this person
    {% endif %} #}
),

create_partitions as (
    select
        *,
        {# {{ dbt_utils.datediff('last_event_occurred_at', 'occurred_at', 'minute') }} as  #}
        sum(case when campaign_id is null then 0 else 1 end) over (partition by person_id order by occurred_at) as campaign_partition,
        sum(case when flow_id is null then 0 else 1 end) over (partition by person_id order by occurred_at) as flow_partition

    from events

),

last_touches as (

    select 
        *,
        min(occurred_at) over(partition by person_id, campaign_partition) as last_campaign_touch_at,
        min(occurred_at) over(partition by person_id, flow_partition) as last_partition_touch_at

    from create_partitions
        {# case when time_passed <= lookback_window then first_value
        else null end as last_attributed_to_campaign_id, #}
),

attribute as (

    select 
        *,
        coalesce(campaign_id,
            case 
            when {{ dbt_utils.datediff('last_campaign_touch_at', 'occurred_at', 'minute') }} <= {{ var('klaviyo__attribution_lookback_window', 180) }} 
                then first_value(campaign_id) over (partition by person_id, campaign_partition order by occurred_at asc rows between unbounded preceding and current row)
                else null end) last_touch_campaign_id,

        coalesce(flow_id,
            case 
            when {{ dbt_utils.datediff('last_campaign_touch_at', 'occurred_at', 'minute') }} <= {{ var('klaviyo__attribution_lookback_window', 180) }} 
                then first_value(flow_id) over (partition by person_id, flow_partition order by occurred_at asc rows between unbounded preceding and current row)
                else null end) as last_touch_flow_id

    from last_touches 
)

select * from attribute