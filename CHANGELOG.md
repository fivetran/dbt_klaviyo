# dbt_klaviyo v0.3.0

## Features
- Allow for multiple sources by unioning source tables across multiple Klaviyo connectors.
([#11](https://github.com/fivetran/dbt_klaviyo/pull/11) & [#12](https://github.com/fivetran/dbt_klaviyo/pull/12))
  - Refer to the [README](https://github.com/fivetran/dbt_klaviyo#unioning-multiple-klaviyo-connectors) for more details.

## Bug Fixes
- Correct [README](https://github.com/fivetran/dbt_klaviyo#attribution-eligible-event-types) in pointing out that the `klaviyo__eligible_attribution_events` variable is case-SENSITIVE and must be in **all lowercase**.

## Under the Hood
- Unioning: The unioning occurs in the staging tmp models using the `fivetran_utils.union_data` macro. ([#8](https://github.com/fivetran/dbt_klaviyo_source/pull/8))
- Unique tests: Because columns that were previously used for unique tests may now have duplicate fields across multiple sources, these columns are combined with the new `source_relation` column for unique tests and tested using the `dbt_utils.unique_combination_of_columns` macro. ([#8](https://github.com/fivetran/dbt_klaviyo/pull/11))
- Source Relation column: To distinguish which source each record comes from, we added a new `source_relation` column in each staging and final model and applied the `fivetran_utils.source_relation` macro. ([#8](https://github.com/fivetran/dbt_klaviyo_source/pull/8))
    - The `source_relation` column is included in all joins and window function partition clauses in the transform package. Note that an event from one Klaviyo source will _never_ be attributed to an event from a different Klaviyo connector.

## Contributors
- [@pawelngei](https://github.com/pawelngei) [#11](https://github.com/fivetran/dbt_klaviyo/pull/11) and [#8](https://github.com/fivetran/dbt_klaviyo_source/pull/8)

# dbt_klaviyo v0.1.0 -> v0.3.0
Refer to the relevant release notes on the Github repository for specific details for the previous releases. Thank you!