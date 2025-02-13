{{
    config(
        materialized='incremental',
        unique_key='unique_event_id',
        incremental_strategy = 'merge' if target.type not in ('postgres', 'redshift') else 'delete+insert',
        file_format = 'delta',
        partition_by={
            "field": "occurred_at",
            "data_type": "timestamp",
            "granularity": "day"
        }
    )
}}

with events as (
    select 
        *,
        coalesce(campaign_id, flow_id) as touch_id,
        case 
            when campaign_id is not null then 'campaign' 
            when flow_id is not null then 'flow' 
        else null end as touch_type

    from {{ var('event_table') }}

    {% if is_incremental() %}
    where _fivetran_synced >= cast(coalesce( 
        (
            select {{ dbt.dateadd(datepart = 'hour', 
                                        interval = -1,
                                        from_date_or_timestamp = 'max(_fivetran_synced)' ) }}  
            from {{ this }}
        ), '2012-01-01') as {{ dbt.type_timestamp() }})
    {% endif %}
),

-- Create a date-based partition first to reduce the window function scope
date_partitioned_events as (
    select 
        *,
        date(occurred_at) as event_date
    from events
),

create_sessions as (
    select
        *,
        sum(case when touch_id is not null
        {% if var('klaviyo__eligible_attribution_events') != [] %}
            and lower(type) in {{ "('" ~ (var('klaviyo__eligible_attribution_events') | join("', '")) ~ "')" }}
        {% endif %}
            then 1 else 0 end) over (
                partition by person_id, source_relation, event_date 
                order by occurred_at asc 
                rows between unbounded preceding and current row) as touch_session 
    from date_partitioned_events
),

last_touches as (
    select 
        *,
        min(occurred_at) over(
            partition by person_id, source_relation, event_date, touch_session) as session_start_at,
        first_value(type) over(
            partition by person_id, source_relation, event_date, touch_session 
            order by occurred_at asc 
            rows between unbounded preceding and current row) as session_event_type
    from create_sessions
),

attribute as (
    select 
        *,
        coalesce(touch_id,
            case 
            when {{ dbt.datediff('session_start_at', 'occurred_at', 'hour') }} <= (
                case 
                when lower(session_event_type) like '%sms%' then {{ var('klaviyo__sms_attribution_lookback') }}
                else {{ var('klaviyo__email_attribution_lookback') }} end
            )
            then first_value(touch_id) over (
                partition by person_id, source_relation, event_date, touch_session 
                order by occurred_at asc 
                rows between unbounded preceding and current row)
            else null end) as last_touch_id
    from last_touches 
),

final as (
    select
        *,
        coalesce(touch_type, first_value(touch_type) over(
            partition by person_id, source_relation, event_date, touch_session 
            order by occurred_at asc 
            rows between unbounded preceding and current row)) as session_touch_type
    from attribute 
)

select * from final