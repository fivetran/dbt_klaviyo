with events as (

    -- excluding some fields to rename them and/or make them null if needed
    {% set exclude_fields = ['touch_session', 'last_touch_id', 'last_touch_at', 'last_touch_event_type', 'type'] %}
    -- snowflake has to be uppercase :)
    {% set exclude_fields = exclude_fields | upper if target.type == 'snowflake' else exclude_fields %}

    select 
        {{ dbt_utils.star(from=ref('int_klaviyo__event_attribution'), except=exclude_fields) }},

        type, -- need to pull this out because it gets removed, due to being a substring of last_touch_event_type

        -- split out campaign and flow IDs
        case 
            when last_touch_type = 'campaign' then last_touch_id 
        else null end as last_touch_campaign_id,
        case 
            when last_touch_type = 'flow' then last_touch_id 
        else null end as last_touch_flow_id,

        -- make sure that last_touch_* columns are null if the event was not attributed to any campaign or flow
        case 
            when last_touch_id is not null then last_touch_at 
        else null end as last_touch_at,
        case 
            when last_touch_id is not null then last_touch_event_type 
        else null end as last_touch_event_type

    from {{ ref('int_klaviyo__event_attribution') }}
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
        events.*,
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

    from events
    left join campaign on events.last_touch_campaign_id = campaign.campaign_id 
    left join flow on events.last_touch_flow_id = flow.flow_id
    left join person on events.person_id = person.person_id
    left join metric on events.metric_id = metric.metric_id 
    left join integration on metric.integration_id = integration.integration_id
)

select * from join_fields