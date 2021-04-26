-- config as incremental....? will need to grab all events related to a person (like mixpanel__sessions)
with events as (

    select *
    from {{ var('event_table') }}

    {# {% if is_incremental() %}
    -- will probably have to grab all events related to this person but ONLY if campaign_id and flow_id are null?
    {% endif %} #}
),

create_partitions as (
    select
        *,

        -- default klaviyo__event_attribution_filter limits to email opens, email clicks, and sms opens
        sum(case when campaign_id is not null and {{ var('klaviyo__event_attribution_filter') }} then 1 else 0 end) 
            over (partition by person_id order by occurred_at) as campaign_partition,
        sum(case when flow_id is not null and {{ var('klaviyo__event_attribution_filter') }} then 1 else 0 end) 
            over (partition by person_id order by occurred_at) as flow_partition

    from events

),

last_touches as (

    select 
        *,
        -- the first event of each partition is the one with the non-null campaign/flow
        min(occurred_at) over(partition by person_id, campaign_partition) as last_campaign_touch_at,
        min(occurred_at) over(partition by person_id, flow_partition) as last_flow_touch_at,

        first_value(type) over(
            partition by person_id, campaign_partition order by occurred_at asc rows between unbounded preceding and current row) as last_campaign_touch_event_type,

        first_value(type) over(
            partition by person_id, flow_partition order by occurred_at asc rows between unbounded preceding and current row) as last_flow_touch_event_type

    from create_partitions
),

attribute as (

    select 
        *,

        -- making default lookback = 5 days (120 hours) for email and 1 day (24 hours) for sms
        coalesce(campaign_id,
            case 
            when {{ dbt_utils.datediff('last_campaign_touch_at', 'occurred_at', 'hour') }} <= (
                case when lower(last_campaign_touch_event_type) like '%sms%' then {{ var('klaviyo__sms_attribution_lookback') }}
                    else {{ var('klaviyo__email_attribution_lookback') }} end)
                then first_value(campaign_id) over (
                    partition by person_id, campaign_partition order by occurred_at asc rows between unbounded preceding and current row)
            else null end) last_touch_campaign_id,

        coalesce(flow_id,
            case 
            when {{ dbt_utils.datediff('last_flow_touch_at', 'occurred_at', 'hour') }} <= (
                case when lower(last_flow_touch_event_type) like '%sms%' then {{ var('klaviyo__sms_attribution_lookback') }}
                    else {{ var('klaviyo__email_attribution_lookback') }} end
            )
                then first_value(flow_id) over (
                    partition by person_id, flow_partition order by occurred_at asc rows between unbounded preceding and current row)
            else null end) as last_touch_flow_id

    from last_touches 
)

select * from attribute