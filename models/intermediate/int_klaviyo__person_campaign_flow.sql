with events as (

    select *
    from {{ ref('klaviyo__events') }}
),

-- this might belong in the dbt_project.yml in case people don't want some of these??? 
{% set conversions  = [
        'Active on Site',
        'Viewed Product',
        'Received Email' ,
        'Clicked Email',
        'Opened Email',
        'Bounced Email',
        'Marked Email as Spam',
        'Dropped Email',
        'Subscribed to List',
        'Unsubscribed to List',
        'Unsubscribed',
        'Updated Email Preferences',
        'Subscribed to Back in Stock',
        'Merged Profile'
    ] 
%}

{% if var('klaviyo__use_sms', true) %}
    {% set conversions = conversions +
        [
            'Received SMS',
            'Clicked SMS',
            'Consented to Receive SMS',
            'Sent SMS',
            'Unsubscribed from SMS',
            'Failed to Deliver SMS'
        ] 
    %}
{% endif %}

-- ordered product gets triggered for every item, so COUNT for that for sure
{% if var('klaviyo__use_shopify', true) %}
    {% set conversions = conversions + [
            'Checkout Started',
            'Placed Order',
            'Ordered Product',
            'Fulfilled Order',
            'Cancelled Order',
            'Refunded Order',
            'Abandoned Checkout']
        
    %}
{% endif %}

pivot_out_events as (
    
)


select 0