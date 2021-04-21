with events as (

    select 
        {{ dbt_utils.star(from=ref('int_klaviyo__event_attribution'), except=["campaign_partition", "flow_partition"]) }}
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

{# person as (

    select *
    from {{ var('person') }}
), #}

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
        integration.integration_name,
        integration.category as integration_category

    from events
    left join campaign on events.last_touch_campaign_id = campaign.campaign_id 
    left join flow on events.last_touch_flow_id = flow.flow_id
    {# left join person on events.person_id = person.person_id  #} -- what stuff to bring in?
    left join metric on events.metric_id = metric.metric_id 
    left join integration on metric.integration_id = integration.integration_id
)

select * from join_fields