{{
    config(
        materialized='incremental',
        unique_key='event_id',
        partition_by={
            "field": "occurred_on",
            "data_type": "date"
        } if target.type != 'spark' else ['occurred_on']
    )
}}

with events as (

    select 
        *,
        -- no event will be attributed to both a campaign and flow
        coalesce(campaign_id, flow_id) as touch_id,
        case 
            when campaign_id is not null then 'campaign' 
            when flow_id is not null then 'flow' 
        else null end as touch_type -- defintion: touch = interaction with campaign/flow

    from {{ var('event_table') }}

    {% if is_incremental() %}
    -- grab **ALL** events for users who have any events in this new increment
    where person_id in (

        select distinct person_id
        from {{ var('event_table') }}

        -- most events (from all kinds of integrations) at least once every hour
        -- https://help.klaviyo.com/hc/en-us/articles/115005253208
        where _fivetran_synced >= cast(coalesce( 
            (
                select {{ dbt_utils.dateadd(datepart = 'hour', 
                                            interval = -1,
                                            from_date_or_timestamp = 'max(_fivetran_synced)' ) }}  
                from {{ this }}
            ), '2010-01-01') as {{ dbt_utils.type_timestamp() }} )
    )
    {% endif %}
),

-- sessionize events based on attribution eligibility -- is it the right kind of event, and does it have a campaign or flow?
create_sessions as (
    select
        *,
        -- default klaviyo__event_attribution_filter limits attribution-eligible events to to email opens, email clicks, and sms opens
        -- https://help.klaviyo.com/hc/en-us/articles/115005248128

        -- events that come with flow/campaign attributions (and are eligible event types) will create new sessions.
        -- non-attributed events that come in afterward will be batched into the same attribution-session
        sum(case when touch_id is not null
        {% if var('klaviyo__eligible_attribution_events') != [] %}
            and lower(type) in {{ "('" ~ (var('klaviyo__eligible_attribution_events') | join("', '")) ~ "')" }}
        {% endif %}
            then 1 else 0 end) over (
                partition by person_id order by occurred_at asc rows between unbounded preceding and current row) as touch_session 

    from events

),

-- "last touch" refers to the event in a "session" that is already attributed with a campaign or flow by Klaviyo
-- there will be only one recorded "touch" per attribution session
-- events that are missing attributions will borrow from their "last touch"
last_touches as (

    select 
        *,
        -- in each attribution session, when did the eligible-to-attribute (ie the first) event happen? 
        -- we'll make this null in klaviyo__events for events that don't end up with an attributed flow/campaign
        min(occurred_at) over(partition by person_id, touch_session) as last_touch_at,

        -- get the kind of metric/event that triggered the attribution session, in order to decide 
        -- to use the sms or email lookback value. we'll make this null in klaviyo__events for events that don't end up with an attributed flow/campaign
        first_value(type) over(
            partition by person_id, touch_session order by occurred_at asc rows between unbounded preceding and current row) as last_touch_event_type

    from create_sessions
),

attribute as (

    select 
        *,
        -- klaviyo uses different lookback windows for email and sms events
        -- default email lookback = 5 days (120 hours) -> https://help.klaviyo.com/hc/en-us/articles/115005248128#conversion-tracking1
        -- default sms lookback: 1 day (24 hours -> https://help.klaviyo.com/hc/en-us/articles/115005248128#sms-conversion-tracking7

        coalesce(touch_id, -- use pre-attributed flow/campaign if provided
            case 
            when {{ dbt_utils.datediff('last_touch_at', 'occurred_at', 'hour') }} <= (
                case 
                when lower(last_touch_event_type) like '%sms%' then {{ var('klaviyo__sms_attribution_lookback') }}
                else {{ var('klaviyo__email_attribution_lookback') }} end
            ) -- if the events fall within the lookback window, attribute
            then first_value(touch_id) over (
                partition by person_id, touch_session order by occurred_at asc rows between unbounded preceding and current row)
            else null end) as last_touch_id

    from last_touches 
),

final as (

    select
        *,

        -- get whether the event is attributed to a flow or campaign
        case when last_touch_id is not null then 
            coalesce(touch_type, first_value(touch_type) over(
                partition by person_id, touch_session order by occurred_at asc rows between unbounded preceding and current row)) 

        else null end as last_touch_type

    from attribute 
)

select * from final