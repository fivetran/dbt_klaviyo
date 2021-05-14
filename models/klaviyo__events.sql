{{
    config(
        materialized='incremental',
        unique_key='event_id',
        partition_by={
            "field": "occurred_on",
            "data_type": "date"
        }
    )
}}

with events as (

    select *
    from {{ ref('int_klaviyo__event_attribution') }}

    {% if is_incremental() %}

    -- most events (from all kinds of integrations) at least once every hour
    where _fivetran_synced >= cast(coalesce( 
            (
                select {{ dbt_utils.dateadd(datepart = 'hour', 
                                            interval = -1,
                                            from_date_or_timestamp = 'max(_fivetran_synced)' ) }}  
                from {{ this }}
            ), '2012-01-01') as {{ dbt_utils.type_timestamp() }} ) -- klaviyo was founded in 2012, so let's default the min date to then
    {% endif %}
),

event_fields as (

    -- excluding some fields to rename them and/or make them null if needed
    {% set exclude_fields = ['touch_session', 'last_touch_id', 'session_start_at', 'session_event_type', 'type'] %}
    -- snowflake has to be uppercase :)
    {% set exclude_fields = exclude_fields | upper if target.type == 'snowflake' else exclude_fields %}

    select 
        {{ dbt_utils.star(from=ref('int_klaviyo__event_attribution'), except=exclude_fields) }},

        type, -- need to pull this out because it gets removed by dbt_utils.star, due to being a substring of 'last_touch_event_type'

        -- split out campaign and flow IDs
        case 
            when last_touch_type = 'campaign' then last_touch_id 
        else null end as last_touch_campaign_id,
        case 
            when last_touch_type = 'flow' then last_touch_id 
        else null end as last_touch_flow_id,

        -- only make these non-null if the event indeed qualified for attribution
        case 
            when last_touch_id is not null then session_start_at 
        else null end as last_touch_at,
        case 
            when last_touch_id is not null then session_event_type 
        else null end as last_touch_event_type
    
    from events
),

campaign as (

    select *
    from {{ var('campaign') }}
),

flow as (

    select *
    from {{ var('flow') }}
),

person as (

    select *
    from {{ var('person') }}
),

-- just pulling this to join with INTEGRATION
metric as (

    select *
    from {{ var('metric') }}
),

integration as (

    select *
    from {{ var('integration') }}
),

join_fields as (

    select
        event_fields.*,
        campaign.campaign_name,
        campaign.campaign_type,
        campaign.subject as campaign_subject_line,
        flow.flow_name, 
        person.city as person_city,
        person.country as person_country,
        person.region as person_region,
        person.email as person_email,
        person.timezone as person_timezone,
        integration.integration_name,
        integration.category as integration_category

    from event_fields
    left join campaign on event_fields.last_touch_campaign_id = campaign.campaign_id 
    left join flow on event_fields.last_touch_flow_id = flow.flow_id
    left join person on event_fields.person_id = person.person_id
    left join metric on event_fields.metric_id = metric.metric_id 
    left join integration on metric.integration_id = integration.integration_id
)

select * from join_fields