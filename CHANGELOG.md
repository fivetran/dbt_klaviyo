# dbt_klaviyo v0.4.2

## Under the Hood
- Ensures that the incremental strategy used by Postgres and Redshift adapters in the `klaviyo__events` and `int_klaviyo__event_attribution` models is `delete+insert` ([#9](https://github.com/fivetran/dbt_klaviyo/pull/22)). Newer versions of dbt introduced an error message if the provided incremental strategy is not `append` or `delete+insert` for these adapters.

# dbt_klaviyo v0.4.1
## Bug Fixes
- Incorporate the `try_cast` macro from [fivetran_utils](https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.3.latest) to ensure that the `numeric_value` field in `klaviyo__person_campaign_flow` is the same data type as '0'. [Issue #17](https://github.com/fivetran/dbt_klaviyo/issues/17)

# dbt_klaviyo v0.4.0
🎉 dbt v1.0.0 Compatibility 🎉
## 🚨 Breaking Changes 🚨
- Adjusts the `require-dbt-version` to now be within the range [">=1.0.0", "<2.0.0"]. Additionally, the package has been updated for dbt v1.0.0 compatibility. If you are using a dbt version <1.0.0, you will need to upgrade in order to leverage the latest version of the package.
  - For help upgrading your package, I recommend reviewing this GitHub repo's Release Notes on what changes have been implemented since your last upgrade.
  - For help upgrading your dbt project to dbt v1.0.0, I recommend reviewing dbt-labs [upgrading to 1.0.0 docs](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-1-0-0) for more details on what changes must be made.
- Upgrades the package dependency to refer to the latest `dbt_klaviyo_source`. Additionally, the latest `dbt_klaviyo_source` package has a dependency on the latest `dbt_fivetran_utils`. Further, the latest `dbt_fivetran_utils` package also has a dependency on `dbt_utils` [">=0.8.0", "<0.9.0"].
  - Please note, if you are installing a version of `dbt_utils` in your `packages.yml` that is not in the range above then you will encounter a package dependency error.
- The updates highlighted within the Bug Fixes section are changes to the incremental logic of the `klaviyo__events` table. As such, a `dbt run --full-refresh` will be needed after installing this version of the dbt_klaviyo package as a dependency within your `packages.yml`
- Accommodating the breaking change within the dbt_klaviyo_source package for the name change of the `union_schemas/datbases` variables to be `klaviyo_union_schemas/databases`.

## Bug Fixes
- Leverage the `unique_event_id` surrogate key from the `stg_klaviyo__events` model within the incremental logic of `int_klaviyo__event_attribution` and `klaviyo__events` to better account for the uniqueness of events across different connectors.

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
