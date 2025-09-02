{{
    config(
        materialized='incremental',
        unique_key='unique_event_id',
        incremental_strategy = 'merge' if target.type not in ('postgres', 'redshift') else 'delete+insert',
        file_format = 'delta'
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

children as (

    select *
    from events
    where event_attribution is not null
        and touch_id is null
),

parse_children as (

    select
        *,
        {{ fivetran_utils.json_extract('event_attribution', 'attributed_event_id') }} as extracted_id_raw
    from children
),

normalized_children as (

    select
        *,
        nullif(replace(replace(extracted_id_raw, '"', ''), "''", ''), '') as extracted_event_id
    from parse_children
),

extracted_touch as (

    select
        event_id as extracted_event_id,
        coalesce(campaign_id, flow_id) as extracted_touch_id,
        case 
            when campaign_id is not null then 'campaign'
            when flow_id is not null then 'flow'
            else null
        end as extracted_touch_type,
        type as extracted_event_type
    from events
),

inherited as (

    select
        normalized_children.unique_event_id,
        extracted_touch.extracted_touch_id,
        extracted_touch.extracted_touch_type,
        extracted_touch.extracted_event_type
    from normalized_children
    left join extracted_touch
        on normalized_children.extracted_event_id = extracted_touch.extracted_event_id
),

eligible_tagged as (

    select
        *,
        sum(
            case 
                when touch_id is not null
                {% if var('klaviyo__eligible_attribution_events') != [] %}
                    and lower(type) in {{ "('" ~ (var('klaviyo__eligible_attribution_events') | join("', '")) ~ "')" }}
                {% endif %}
                then 1 else 0
            end
        ) over (
            partition by person_id, source_relation
            order by occurred_at asc
            rows between unbounded preceding and current row
        ) as touch_session
    from events
),

session_boundaries as (

    select
        *,
        min(occurred_at) over(
            partition by person_id, source_relation, touch_session
        ) as session_start_at,
        first_value(type) over(
            partition by person_id, source_relation, touch_session
            order by occurred_at asc
            rows between unbounded preceding and current row
        ) as session_event_type
    from eligible_tagged
),

session_calculated as (

    select
        *,
        coalesce(
            touch_id,
            case 
                when {{ dbt.datediff('session_start_at', 'occurred_at', 'hour') }} <= (
                    case
                        when lower(session_event_type) like '%sms%' then {{ var('klaviyo__sms_attribution_lookback', 24) }}
                        else {{ var('klaviyo__email_attribution_lookback', 120) }}
                    end
                )
                then first_value(touch_id) over (
                    partition by person_id, source_relation, touch_session
                    order by occurred_at asc
                    rows between unbounded preceding and current row
                )
                else null
            end
        ) as calculated_touch_id,
        coalesce(
            touch_type,
            case 
                when {{ dbt.datediff('session_start_at', 'occurred_at', 'hour') }} <= (
                    case
                        when lower(session_event_type) like '%sms%' then {{ var('klaviyo__sms_attribution_lookback', 24) }}
                        else {{ var('klaviyo__email_attribution_lookback', 120) }}
                    end
                )
                then first_value(touch_type) over (
                    partition by person_id, source_relation, touch_session
                    order by occurred_at asc
                    rows between unbounded preceding and current row
                )
                else null
            end
        ) as calculated_touch_type
    from session_boundaries
),

final as (
    select
        events.*,
        session_calculated.session_start_at,
        session_calculated.session_event_type,

        nullif(coalesce(
            inherited.extracted_touch_id,
            session_calculated.calculated_touch_id
        ), '') as last_touch_id,
        nullif(coalesce(
            inherited.extracted_touch_type,
            session_calculated.calculated_touch_type
        ), '') as session_touch_type
    from events

    left join inherited
        on events.unique_event_id = inherited.unique_event_id

    left join session_calculated
        on events.unique_event_id = session_calculated.unique_event_id
)

select *
from final