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
        {{ dbt_utils.star(from=ref('int_klaviyo__person_metrics'), except=['person_id', "source_relation"]) }}

    from person
    left join person_metrics using(person_id, source_relation)

)

select *
from person_join