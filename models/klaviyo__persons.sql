with person as (

    select *
    from {{ var('person') }}
),

person_metrics as (

    select *
    from {{ ref('int_klaviyo__person_metrics') }}
),

person_join as (

    select
        person.*,
        {{ dbt_utils.star(from=ref('int_klaviyo__person_metrics'), except=['person_id'] if target.type != 'snowflake' else ['PERSON_ID'] ) }}

    from person
    left join person_metrics using(person_id)

)

select *
from person_join