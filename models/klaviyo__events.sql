with events as (

    select 
    {% if target.type == 'snowflake' %}
        {{ dbt_utils.star(from=ref('int_klaviyo__event_attribution'), except=["CAMPAIGN_PARTITION", "FLOW_PARTITION"]) }}
    {% else %}
        {{ dbt_utils.star(from=ref('int_klaviyo__event_attribution'), except=["campaign_partition", "flow_partition"]) }}
    {% endif %}

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
        -- any other fields? they can join with stuff later... 
        flow.flow_name, 
        person.city as person_city,
        person.country as person_country,
        person.region as person_region,
        person.email as person_email, -- idk how people will feel about PII issues here
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