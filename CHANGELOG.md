# dbt_klaviyo v1.3.0

[PR #58](https://github.com/fivetran/dbt_klaviyo/pull/58) includes the following updates:

## Documentation
- Updates README with standardized Fivetran formatting

## Under the Hood
- In the `.quickstart.yml` file:
  - Adds `table_variables` for relevant sources to prevent missing sources from blocking downstream Quickstart models.
  - Adds `supported_vars` for Quickstart UI customization,

# dbt_klaviyo v1.2.1

In connection with the [December 2025 Fivetran Klaviyo Connector updates](https://fivetran.com/docs/connectors/applications/klaviyo/changelog#december2025), [PR #56](https://github.com/fivetran/dbt_klaviyo/pull/56) includes the following updates:

## Schema/Data Change
**1 total change • 0 possible breaking changes**

| Data Model(s) | Change type | Old | New | Notes |
|---------------|-------------|-----|-----|-------|
| `stg_klaviyo__event` | Column normalization | Only snake_case columns recognized:<br>`property_value`<br>`property_attribution` | Accepts both snake_case and camelCase spellings:<br>`property_value` / `propertyValue`<br>`property_attribution` / `propertyAttribution` | Coalesces alternate source columns spellings into snake_case for consistency. |

# dbt_klaviyo v1.2.0

[PR #55](https://github.com/fivetran/dbt_klaviyo/pull/55) includes the following updates:

## Features
  - Increases the required dbt version upper limit to v3.0.0

# dbt_klaviyo v1.1.1
[PR #54](https://github.com/fivetran/dbt_klaviyo/pull/54) includes the following updates:

## Bug Fix
- To handle changes to the `property_attribution` field JSON structure introduced in the [September 2025 Fivetran Klaviyo release](https://fivetran.com/docs/connectors/applications/klaviyo/changelog#september2025), updates the `int_klaviyo__event_attribution` model to handle both legacy and new structures
- Ensures the `property_attribution` field is a string for parsing downstream by implementing the `json_to_string` macro to properly handle JSON columns across different warehouses

# dbt_klaviyo v1.1.0
[PR #53](https://github.com/fivetran/dbt_klaviyo/pull/53) includes the following updates:

## Schema/Data Change (--full-refresh required after upgrading)
**4 total changes • 1 possible breaking change**

| Data Model(s) | Change type | Old | New | Notes |
| ---------- | ----------- | -------- | -------- | ----- |
| `klaviyo__events`<br>`int_klaviyo__event_attribution`<br>`stg_klaviyo__event` | New column | | `event_attribution` | New field sourced from `property_attribution` in the `EVENT` source table. Contains Klaviyo's native attribution data for events, which is now used by default for attribution. |
| `EVENT` (source) | New column | | `property_attribution` | **Breaking change**: If you are already including this field through the [passthrough columns](https://github.com/fivetran/dbt_klaviyo?tab=readme-ov-file#passthrough-columns) variable `klaviyo__event_pass_through_columns`, remove it from the list to avoid duplicate column errors. |

## Breaking Changes
- **Primary Attribution Method Update**: The package now uses Klaviyo’s native `property_attribution` field (renamed `event_attribution` in staging) as the primary attribution method.
  - Ensures consistency with Klaviyo’s platform reporting and UI
  - Leverages Klaviyo’s internal attribution logic with no extra configuration required
  - The previous session-based attribution remains available as an optional fallback by setting `using_native_attribution: false` in `dbt_project.yml`
  - See the [README](https://github.com/fivetran/dbt_klaviyo/blob/main/README.md#event-attribution) for configuration details and the [DECISIONLOG](https://github.com/fivetran/dbt_klaviyo/blob/main/DECISIONLOG.md) for background on this decision

## Documentation Updates
- Added [DECISIONLOG.md](https://github.com/fivetran/dbt_klaviyo/blob/main/DECISIONLOG.md) explaining the rationale behind attribution methods and guidance on when to use each
- Updated [README.md](https://github.com/fivetran/dbt_klaviyo/blob/main/README.md#event-attribution) to clarify that `event_attribution` is now the primary attribution method
- Updated dbt documentation with newly added `property_attribution`/`event_attribution` field.

# dbt_klaviyo v1.1.0-a2
[PR #53](https://github.com/fivetran/dbt_klaviyo/pull/53) includes the following updates:

## Breaking Change
> A `--full-refresh` is required when upgrading to retroactively apply these updates.

- Updated attribution logic in `int_klaviyo__event_attribution` to use the `property_attribution` field from the `EVENT` source.  
  - This replaces the previous calculation method.  
  - If the `property_attribution` field is not available or you want a fallback for when it is null, set the variable `using_native_attribution: false` in your `dbt_project.yml` to coalesce the `last_touch_*` fields back with the previous package-calculated attribution method.
- Rolled back the updates from v1.1.0-a1.

# dbt_klaviyo v1.1.0-a1
[PR #53](https://github.com/fivetran/dbt_klaviyo/pull/53) includes the following updates:

## Breaking Change
> A `--full-refresh` is required when upgrading to ensure the updates are retroactively applied.
- Updated attribution logic for Shopify order lifecycle events. These events now inherit attribution from their associated `Placed Order` event rather than the nearest intervening event. If no `Placed Order` is found within 3 months, the default attribution behavior is applied.
  - `Cancelled Order`
  - `Confirmed Shipment`
  - `Delivered Shipment`
  - `Fulfilled Order`
  - `Fulfilled Partial Order`
  - `Marked Out for Delivery`
  - `Refunded Order`

# dbt_klaviyo v1.0.0

[PR #51](https://github.com/fivetran/dbt_klaviyo/pull/51) includes the following updates:

## Breaking Changes

### Source Package Consolidation
- Removed the dependency on the `fivetran/klaviyo_source` package.
  - All functionality from the source package has been merged into this transformation package for improved maintainability and clarity.
  - If you reference `fivetran/klaviyo_source` in your `packages.yml`, you must remove this dependency to avoid conflicts.
  - Any source overrides referencing the `fivetran/klaviyo_source` package will also need to be removed or updated to reference this package.
  - Update any klaviyo_source-scoped variables to be scoped to only under this package. See the [README](https://github.com/fivetran/dbt_klaviyo/blob/main/README.md) for how to configure the build schema of staging models.
- As part of the consolidation, vars are no longer used to reference staging models, and only sources are represented by vars. Staging models are now referenced directly with `ref()` in downstream models.

### dbt Fusion Compatibility Updates
- Updated package to maintain compatibility with dbt-core versions both before and after v1.10.6, which introduced a breaking change to multi-argument test syntax (e.g., `unique_combination_of_columns`).
- Temporarily removed unsupported tests to avoid errors and ensure smoother upgrades across different dbt-core versions. These tests will be reintroduced once a safe migration path is available.
  - Removed all `dbt_utils.unique_combination_of_columns` tests.
  - Moved `loaded_at_field: _fivetran_synced` under the `config:` block in `src_klaviyo.yml`.

## Under the Hood
- Updated conditions in `.github/workflows/auto-release.yml`.
- Added `.github/workflows/generate-docs.yml`.

# dbt_klaviyo v0.9.0

[PR #47](https://github.com/fivetran/dbt_klaviyo/pull/47) includes the following updates:

## Breaking Change for dbt Core < 1.9.6

> *Note: This is not relevant to Fivetran Quickstart users.*

Migrated `freshness` from a top-level source property to a source `config` in alignment with [recent updates](https://github.com/dbt-labs/dbt-core/issues/11506) from dbt Core ([Klaviyo Source v0.8.0](https://github.com/fivetran/dbt_klaviyo_source/releases/tag/v0.8.0)). This will resolve the following deprecation warning that users running dbt >= 1.9.6 may have received:

```
[WARNING]: Deprecated functionality
Found `freshness` as a top-level property of `klaviyo` in file
`models/src_klaviyo.yml`. The `freshness` top-level property should be moved
into the `config` of `klaviyo`.
```

**IMPORTANT:** Users running dbt Core < 1.9.6 will not be able to utilize freshness tests in this release or any subsequent releases, as older versions of dbt will not recognize freshness as a source `config` and therefore not run the tests.

If you are using dbt Core < 1.9.6 and want to continue running Klaviyo freshness tests, please elect **one** of the following options:
  1. (Recommended) Upgrade to dbt Core >= 1.9.6
  2. Do not upgrade your installed version of the `klaviyo` package. Pin your dependency on v0.8.0 in your `packages.yml` file.
  3. Utilize a dbt [override](https://docs.getdbt.com/reference/resource-properties/overrides) to overwrite the package's `klaviyo` source and apply freshness via the previous release top-level property route. This will require you to copy and paste the entirety of the previous release `src_klaviyo.yml` file and add an `overrides: klaviyo_source` property.

## Documentation
- Added Quickstart model counts to README. ([#45](https://github.com/fivetran/dbt_klaviyo/pull/45))
- Corrected references to connectors and connections in the README. ([#45](https://github.com/fivetran/dbt_klaviyo/pull/45))

## Under the Hood
- Updates to ensure integration tests use latest version of dbt.

# dbt_klaviyo v0.8.0
[PR #41](https://github.com/fivetran/dbt_klaviyo/pull/41) includes the following updates:

## Breaking Changes (Full refresh required after upgrading)
- Removed the `partition_by` logic from incremental models running on BigQuery. This change affects only BigQuery warehouses and resolves the `too many partitions` error that some users encountered. The partitioning was also deemed unnecessary for the mentioned models and their downstream references, offering no performance benefit. By removing it, we eliminate both the error risk and an unneeded configuration. This change applies to the following models:
  - `int_klaviyo__event_attribution`
  - `klaviyo__events`

## Under the Hood
- Added consistency and integrity validation tests for the `klaviyo__events` model.
- Cleaned up unnecessary variable configuration within the `integration_tests/dbt_project.yml` file.

# dbt_klaviyo v0.7.2
[PR #38](https://github.com/fivetran/dbt_klaviyo/pull/38) includes the following updates:

## Bug Fixes
- Removes `not_null` tests for `person_id` from `int_klaviyo__person_metrics` and `klaviyo__person_campaign_flow`. This is because Klaviyo can record events with deactivated profiles, resulting in null `person_id`s. Therefore models built off of tables with event-based grains may have null `person_id`s.

# dbt_klaviyo v0.7.1

## Dependency Updates
[PR #33](https://github.com/fivetran/dbt_klaviyo/pull/33) includes the following updates:
 - Corrected the package to reference the proper upstream `dbt_klaviyo_source` package dependency.

## Under the Hood:
[PR #34](https://github.com/fivetran/dbt_klaviyo/pull/34) includes the following updates:
- For Databricks compatibility, added the Catalog variable and updated the range to >=1.6.0,<2.0.0 in order to pass in integration testing.

# dbt_klaviyo v0.7.0

[PR #30](https://github.com/fivetran/dbt_klaviyo/pull/30) includes updates regarding the [September 2023](https://fivetran.com/docs/applications/klaviyo/changelog#september2023) changes to the Klaviyo connector.

## 🚨 Breaking Changes 🚨:
- We have removed and added respective fields following the new schema in the Klaviyo connector. In addition, we have removed the deprecated `integration` table and have instead passed the integration columns through `metric`. For more information, refer to the [source Klaviyo package](https://github.com/fivetran/dbt_klaviyo_source/blob/main/CHANGELOG.md), where most of these changes took place.


# dbt_klaviyo v0.6.0
## 🚨 Breaking Changes 🚨:
- We recommend running `dbt run --full-refresh` after upgrading to this version due to casting changes in the source package affecting incremental models.
## Bug Fixes
[PR #29](https://github.com/fivetran/dbt_klaviyo/pull/29) includes the following breaking changes:
- IDs in the upstream source package are now cast using `{{ dbt.type_string() }}` to prevent potential datatype conflicts. 
- Upstream `_fivetran_synced` is now cast using `{{ dbt.type_timestamp() }}` to prevent downstream datatype errors.

 ## Under the Hood:
[PR #26](https://github.com/fivetran/dbt_klaviyo/pull/26) includes the following updates:
- Incorporated the new `fivetran_utils.drop_schemas_automation` macro into the end of each Buildkite integration test job.
- Updated the pull request [templates](/.github).

# dbt_klaviyo v0.5.0

## 🚨 Breaking Changes 🚨:
[PR #23](https://github.com/fivetran/dbt_klaviyo/pull/23) includes the following breaking changes:
- Dispatch update for dbt-utils to dbt-core cross-db macros migration. Specifically `{{ dbt_utils.<macro> }}` have been updated to `{{ dbt.<macro> }}` for the below macros:
    - `any_value`
    - `bool_or`
    - `cast_bool_to_text`
    - `concat`
    - `date_trunc`
    - `dateadd`
    - `datediff`
    - `escape_single_quotes`
    - `except`
    - `hash`
    - `intersect`
    - `last_day`
    - `length`
    - `listagg`
    - `position`
    - `replace`
    - `right`
    - `safe_cast`
    - `split_part`
    - `string_literal`
    - `type_bigint`
    - `type_float`
    - `type_int`
    - `type_numeric`
    - `type_string`
    - `type_timestamp`
    - `array_append`
    - `array_concat`
    - `array_construct`
- For `current_timestamp` and `current_timestamp_in_utc` macros, the dispatch AND the macro names have been updated to the below, respectively:
    - `dbt.current_timestamp_backcompat`
    - `dbt.current_timestamp_in_utc_backcompat`
- `dbt_utils.surrogate_key` has also been updated to `dbt_utils.generate_surrogate_key`. Since the method for creating surrogate keys differ, we suggest all users do a `full-refresh` for the most accurate data. For more information, please refer to dbt-utils [release notes](https://github.com/dbt-labs/dbt-utils/releases) for this update.
- Dependencies on `fivetran/fivetran_utils` have been upgraded, previously `[">=0.3.0", "<0.4.0"]` now `[">=0.4.0", "<0.5.0"]`.

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
