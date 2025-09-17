{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with source_count as (
    select
        1 as join_key,
        count(*) as row_count
    from {{ ref('stg_klaviyo__flow') }}
),

end_count as (
    select
        1 as join_key,
        count(*) as row_count
    from {{ ref('klaviyo__flows') }}
),

final as (
    select
        end_count.join_key,
        end_count.row_count as ending_row_count,
        source_count.row_count as source_row_count
    from end_count
    full outer join source_count
        on source_count.join_key = end_count.join_key
)

select *
from final
where ending_row_count != source_row_count

