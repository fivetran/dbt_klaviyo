{{
    config(
        materialized='incremental',
        unique_key='unique_event_id',
        incremental_strategy = 'merge' if target.type not in ('postgres', 'redshift') else 'delete+insert',
        file_format = 'delta'
    )
}}

-- Use var('using_native_attribution') if it exists, otherwise determine if we can use native attribution.
{% if execute and flags.WHICH in ('run', 'build') and var('using_native_attribution', none) is none %}
    {% set event_columns = adapter.get_columns_in_relation(source('klaviyo', 'event')) %}
    {% set event_column_names = event_columns | map(attribute='name') | map('lower') | list %}
    {% set using_native_attribution = 'property_attribution' in event_column_names %}
{% else %}
    {% set using_native_attribution = var('using_native_attribution', true) %}
{% endif %}

-- For debugging. Remove before merge.
{{ print('***************** using_native_attribution: ' ~using_native_attribution) }}

with events as (

    select 
        *,
        -- no event will be attributed to both a campaign and flow
        coalesce(campaign_id, flow_id) as touch_id,
        case
            when campaign_id is not null then 'campaign' 
            when flow_id is not null then 'flow' 
        else null end as touch_type -- definition: touch = interaction with campaign/flow

    from {{ ref('stg_klaviyo__event') }}

    {% if is_incremental() %}
    -- grab **ALL** events for users who have any events in this new increment
    where person_id in (

        select distinct person_id
        from {{ ref('stg_klaviyo__event') }}

        -- most events (from all kinds of integrations) at least once every hour
        -- https://help.klaviyo.com/hc/en-us/articles/115005253208
        where _fivetran_synced >= cast(coalesce( 
            (
                select {{ dbt.dateadd(datepart = 'hour', 
                                            interval = -1,
                                            from_date_or_timestamp = 'max(_fivetran_synced)' ) }}  
                from {{ this }}
            ), '2012-01-01') as {{ dbt.type_timestamp() }} ) -- klaviyo was founded in 2012, so let's default the min date to then
    )
    {% endif %}
),

{% if using_native_attribution %}
children as (

    select
        *,
        replace(event_attribution, '$', '') as cleaned_event_attribution -- bigquery doesn't allow the '$'
    from events
    where event_attribution is not null
        and touch_id is null
),

parse_children as (

    select
        *,
        {{ fivetran_utils.json_parse('cleaned_event_attribution', ['attributed_event_id']) }} as extracted_id_raw

    from children
),

normalized_children as (

    select
        *,
        nullif(replace(extracted_id_raw, '"', ''), '') as extracted_event_id
    from parse_children
),

extracted_touch as (

    select
        event_id as extracted_event_id,
        touch_id as extracted_touch_id,
        touch_type as extracted_touch_type,
        type as extracted_event_type,
        source_relation
    from events
),

inherited as (

    select
        normalized_children.unique_event_id,
        normalized_children.occurred_at,
        normalized_children.type as event_type,
        extracted_touch.extracted_touch_id,
        extracted_touch.extracted_touch_type,
        extracted_touch.extracted_event_type
    from normalized_children
    left join extracted_touch
        on normalized_children.extracted_event_id = extracted_touch.extracted_event_id
        and normalized_children.source_relation = extracted_touch.source_relation
    where normalized_children.extracted_event_id is not null 
),

{% else %} -- using_native_attribution = false
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
                partition by person_id, source_relation order by occurred_at asc rows between unbounded preceding and current row) as touch_session 

    from events
),

-- "session start" refers to the event in a "touch session" that is already attributed with a campaign or flow by Klaviyo
-- a new event that is attributed with a campaign/flow will trigger a new session, so there will only be one already-attributed event per each session 
-- events that are missing attributions will borrow data from the event that triggered the session, if they are in the lookback window (see `attribute` CTE)
session_boundaries as (

    select 
        *,
        -- when did the touch session begin?
        min(occurred_at) over(partition by person_id, source_relation, touch_session) as session_start_at,

        -- get the kind of metric/event that triggered the attribution session, in order to decide 
        -- to use the sms or email lookback value. 
        first_value(type) over(
            partition by person_id, source_relation, touch_session order by occurred_at asc rows between unbounded preceding and current row) as session_event_type

    from create_sessions
),

session_calculated as (

    select
        *,
        -- klaviyo uses different lookback windows for email and sms events
        -- default email lookback = 5 days (120 hours) -> https://help.klaviyo.com/hc/en-us/articles/115005248128#conversion-tracking1
        -- default sms lookback: 1 day (24 hours -> https://help.klaviyo.com/hc/en-us/articles/115005248128#sms-conversion-tracking7

        coalesce(touch_id, -- use pre-attributed flow/campaign if provided
            case 
            when {{ dbt.datediff('session_start_at', 'occurred_at', 'hour') }} <= (
                case 
                when lower(session_event_type) like '%sms%' then {{ var('klaviyo__sms_attribution_lookback') }}
                else {{ var('klaviyo__email_attribution_lookback') }} end
            ) -- if the events fall within the lookback window, attribute
            then first_value(touch_id) over (
                partition by person_id, source_relation, touch_session order by occurred_at asc rows between unbounded preceding and current row)
            else null end) as calculated_last_touch_id -- session qualified for attribution -> we will call this "last touch"

    from session_boundaries
),
{% endif %}

final as (
    select
        events.*,

        {% if using_native_attribution %}
        coalesce(inherited.occurred_at, events.occurred_at) as session_start_at,
        coalesce(inherited.event_type, events.type) as session_event_type,
        coalesce(inherited.extracted_touch_id, events.touch_id) as last_touch_id,
        coalesce(inherited.extracted_touch_type, events.touch_type) as session_touch_type
        {% else %}
        session_calculated.session_start_at as session_start_at,
        session_calculated.session_event_type as session_event_type,
        session_calculated.calculated_last_touch_id as last_touch_id,
        -- get whether the event is attributed to a flow or campaign
        coalesce(session_calculated.touch_type, first_value(session_calculated.touch_type) over(
            partition by session_calculated.person_id, session_calculated.source_relation, session_calculated.touch_session
            order by session_calculated.occurred_at asc rows between unbounded preceding and current row)) 
            as session_touch_type
        {% endif %}

    from events

    {% if using_native_attribution %}
    left join inherited
        on events.unique_event_id = inherited.unique_event_id
    {% else %}
    left join session_calculated
        on events.unique_event_id = session_calculated.unique_event_id
    {% endif %}
)

select *
from final