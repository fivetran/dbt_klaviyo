<!--section="klaviyo_transformation_model"-->
# Klaviyo dbt Package

<p align="left">
    <a alt="License"
        href="https://github.com/fivetran/dbt_klaviyo/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0,_<3.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
    <a alt="Fivetran Quickstart Compatible"
        href="https://fivetran.com/docs/transformations/dbt/quickstart">
        <img src="https://img.shields.io/badge/Fivetran_Quickstart_Compatible%3F-yes-green.svg" /></a>
</p>

This dbt package transforms data from Fivetran's Klaviyo connector into analytics-ready tables.

## Resources

- Number of materialized models¹: 18
- Connector documentation
  - [Klaviyo connector documentation](https://fivetran.com/docs/connectors/applications/klaviyo)
  - [Klaviyo ERD](https://fivetran.com/docs/connectors/applications/klaviyo#schemainformation)
- dbt package documentation
  - [GitHub repository](https://github.com/fivetran/dbt_klaviyo)
  - [dbt Docs](https://fivetran.github.io/dbt_klaviyo/#!/overview)
  - [DAG](https://fivetran.github.io/dbt_klaviyo/#!/overview?g_v=1)
  - [Changelog](https://github.com/fivetran/dbt_klaviyo/blob/main/CHANGELOG.md)

## What does this dbt package do?
This package enables you to better understand the efficacy of your email and SMS marketing efforts. It creates enriched models with metrics focused on last-touch attribution, user interactions, and revenue attribution.

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<connector/schema_name>_klaviyo
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| [klaviyo__events](https://github.com/fivetran/dbt_klaviyo/blob/main/models/klaviyo__events.sql) | Tracks all customer events with customizable last-touch attribution connecting events to email campaigns and flows, plus user information to analyze engagement and conversion paths. <br></br>**Example Analytics Questions:**<ul><li>Which events are most frequently triggered and lead to conversions?</li><li>How do events attributed to campaigns compare to those attributed to flows in terms of revenue?</li><li>What is the time between campaign/flow interactions and conversion events?</li></ul>|
| [klaviyo__person_campaign_flow](https://github.com/fivetran/dbt_klaviyo/blob/main/models/klaviyo__person_campaign_flow.sql) | Aggregates person-level engagement with specific campaigns or flows including total attributed revenue and conversion event counts to measure marketing effectiveness at the individual level. <br></br>**Example Analytics Questions:**<ul><li>Which person-campaign or person-flow combinations generate the highest revenue?</li><li>How many conversion events are triggered per person by campaign or flow?</li><li>What is the average revenue per person by campaign or flow type?</li></ul>|
| [klaviyo__campaigns](https://github.com/fivetran/dbt_klaviyo/blob/main/models/klaviyo__campaigns.sql) | Summarizes campaign performance with user interaction metrics including opens, clicks, bounces, and attributed revenue to evaluate email campaign effectiveness. <br></br>**Example Analytics Questions:**<ul><li>Which campaigns have the highest open rates, click rates, and attributed revenue?</li><li>How do campaign engagement metrics correlate with conversion and revenue outcomes?</li><li>What is the ROI of each campaign based on attributed revenue versus send volume?</li></ul>|
| [klaviyo__flows](https://github.com/fivetran/dbt_klaviyo/blob/main/models/klaviyo__flows.sql) | Tracks automated flow performance with user interaction metrics and attributed revenue to understand how email automation drives engagement and conversions. <br></br>**Example Analytics Questions:**<ul><li>Which flows generate the most revenue and have the highest engagement rates?</li><li>How do welcome flows compare to abandonment flows in terms of performance?</li><li>What is the average revenue per recipient for each flow?</li></ul>|
| [klaviyo__persons](https://github.com/fivetran/dbt_klaviyo/blob/main/models/klaviyo__persons.sql) | Provides a complete view of each customer with lifetime engagement metrics across campaigns and flows, attributed and organic revenue, and recent activity patterns. <br></br>**Example Analytics Questions:**<ul><li>Which customers have the highest lifetime value and email engagement?</li><li>How does attributed revenue compare to organic revenue by customer segment?</li><li>What is the average number of campaign and flow interactions per active customer?</li></ul>|

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.

---

## Prerequisites
To use this dbt package, you must have the following:

- At least one Fivetran Klaviyo connection syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **PostgreSQL**, or **Databricks** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/dbt).
- To add the package to your dbt project, follow the setup instructions in the dbt package's [README file](https://github.com/fivetran/dbt_klaviyo/blob/main/README.md#how-do-i-use-the-dbt-package) to use this package.

<!--section-end-->

### Install the package
Include the following klaviyo package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/klaviyo
    version: [">=1.3.0", "<1.4.0"]
```

> All required sources and staging models are now bundled into this transformation package. Do not include `fivetran/klaviyo_source` in your `packages.yml` since this package has been deprecated.

#### Databricks Dispatch Configuration
If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

### Define database and schema variables
By default, this package runs using your destination and the `klaviyo` schema. If this is not where your Klaviyo data is (for example, if your Klaviyo schema is named `klaviyo_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
  klaviyo_database: your_database_name
  klaviyo_schema: your_schema_name
```

### (Optional) Additional configurations
<details open><summary>Expand/Collapse details</summary>

#### Unioning Multiple Klaviyo Connections
If you have multiple Klaviyo connections in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. The package will union all of the data together and pass the unioned table into the transformations. You will be able to see which source it came from in the `source_relation` column of each model. To use this functionality, you will need to set either (**note that you cannot use both**) the `klaviyo_union_schemas` or `klaviyo_union_databases` variables:

```yml
# dbt_project.yml
...
config-version: 2
vars:
  klaviyo:
    klaviyo_union_schemas: ['klaviyo_usa','klaviyo_canada'] # use this if the data is in different schemas/datasets of the same database/project
    klaviyo_union_databases: ['klaviyo_usa','klaviyo_canada'] # use this if the data is in different databases/projects but uses the same schema name
```

#### Event Attribution

If available, the package uses Klaviyo's native `property_attribution` field from the EVENT source for attributing events to campaigns and flows. This approach ensures consistency with Klaviyo's platform and provides the most accurate attribution data.

**Primary Attribution Method:**
- Uses Klaviyo's built-in `property_attribution` field when available
- Events inherit attribution from parent events via `attributed_event_id` references
- Aligns with Klaviyo's internal [attribution model](https://help.klaviyo.com/hc/en-us/articles/115005248128)
- No additional configuration required

**Session-Based Attribution Fallback:**
For users who need custom attribution logic or are migrating from older package versions, an optional session-based attribution method is available. This method is disabled by default if your EVENT source contains the `property_attribution` field but can be enabled by setting `using_native_attribution: false`. **If you do not have the `property_attribution` field, this method will be used by default.**

When enabled, this method uses configurable lookback windows:
- **120 hours (5 days)** for email events  
- **24 hours** for SMS events

```yml
# dbt_project.yml
vars:
  klaviyo:
    using_native_attribution: false # Disable native attribution to use session-based fallback
    klaviyo__email_attribution_lookback: 120 # Hours for email attribution
    klaviyo__sms_attribution_lookback: 24 # Hours for SMS attribution
```

> **Note:** For detailed information about attribution methods and when to use each approach, see the [DECISIONLOG.md](https://github.com/fivetran/dbt_klaviyo/blob/main/DECISIONLOG.md).

> Events already associated with campaigns or flows in Klaviyo will never have their source attribution data overwritten by the package modeling.

##### Attribution-Eligible Event Types (Session-Based Fallback Only)

> **Note:** This configuration only applies when session-based attribution is used. The primary attribution method uses Klaviyo's native attribution without additional filtering.

When using the session-based attribution fallback, the package will only credit email opens, email clicks, and SMS opens with conversions by default. This filter determines which event types can trigger new attribution sessions and is aligned with Klaviyo's internal [attribution model](https://help.klaviyo.com/hc/en-us/articles/115005248128).

To customize which events can qualify for attribution in the session-based method, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  klaviyo:
    klaviyo__eligible_attribution_events: ['types', 'of', 'events', 'to', 'attribute', 'conversions', 'to'] # this is case-SENSITIVE and should be in all lower-case!!
```

#### Filtering Conversion Metrics to Pivot Out

The Klaviyo dbt package pivots relevant conversion events out into metric columns in the `klaviyo__person_campaign_flow`, `klaviyo__campaigns`, `klaviyo__flows`, and `klaviyo__persons` models. The package will sum up revenue attributed to each person's interactions with flows and campaigns (plus organic actions), count the instances of each kind of triggered conversion, and, at the flow and campaign grain, count the number of unique people who converted. The package splits up events to pivot out into two variables, `klaviyo__count_metrics` and `klaviyo__sum_revenue_metrics`, which will record the count of events/users and their associated revenue values, respectively.

By default, the package is configured to pivot out the below metrics. To change the conversion events that are pivoted out, tailor the following configuration to your desired metrics in your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  klaviyo: # case insensitive 
    klaviyo__count_metrics: 
      - 'Active on Site'
      - 'Viewed Product'
      - 'Ordered Product'
      - 'Placed Order'
      - 'Refunded Order'
      - 'Received Email'
      - 'Clicked Email'
      - 'Opened Email'
      - 'Marked Email as Spam'
      - 'Unsubscribed'
      - 'Received SMS'
      - 'Clicked SMS'
      - 'Sent SMS'
      - 'Unsubscribed from SMS'

    klaviyo__sum_revenue_metrics:
      - 'Refunded Order'
      - 'Placed Order'
      - 'Ordered Product'
      - 'checkout started'
      - 'cancelled order'
```

#### Passthrough Columns

Additionally, the Klaviyo package includes all source columns defined in the [macros folder](https://github.com/fivetran/dbt_klaviyo/tree/main/macros) of the source package. We highly recommend including custom fields in this package as models now only bring in the standard fields for the `EVENT` and `PERSON` tables.

You can add more columns using our passthrough column variables. These variables allow for the passthrough fields to be aliased (`alias`) and casted (`transform_sql`) if desired, although it is not required. Datatype casting is configured via a SQL snippet within the `transform_sql` key. You may add the desired SQL snippet while omitting the `as field_name` part of the casting statement - this will be dealt with by the alias attribute - and your custom passthrough fields will be casted accordingly.

Use the following format for declaring the respective passthrough variables:

```yml
# dbt_project.yml

...
vars:
  klaviyo__event_pass_through_columns: 
    - name:           "property_field_id"
      alias:          "new_name_for_this_field_id"
      transform_sql:  "cast(new_name_for_this_field as int64)"
    - name:           "this_other_field"
      transform_sql:  "cast(this_other_field as string)"
  klaviyo__person_pass_through_columns:
    - name:           "custom_crazy_field_name"
      alias:          "normal_field_name"
```

#### Changing the Build Schema

By default, this package will build the Klaviyo final models within a schema titled (`<target_schema>` + `_klaviyo`), intermediate models in (`<target_schema>` + `_int_klaviyo`), and staging models within a schema titled (`<target_schema>` + `_stg_klaviyo`) in your target database. If this is not where you would like your modeled Klaviyo data to be written to, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
models:
    klaviyo:
      +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
      staging:
        +schema: my_new_schema_name # Leave +schema: blank to use the default target_schema.
```

> Note that if your profile does not have permissions to create schemas in your warehouse, you can set each `+schema` to blank. The package will then write all tables to your pre-existing target schema.

#### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:

> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_klaviyo/blob/main/dbt_project.yml) variable declarations to see the expected names.

```yml
vars:
    klaviyo_<default_source_table_name>_identifier: your_table_name 
```

</details>

### (Optional) Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for more details</summary>

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt#setupguide).

</details>

## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.

```yml
packages:
    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]

    - package: dbt-labs/spark_utils
      version: [">=0.3.0", "<0.4.0"]
```

<!--section="klaviyo_maintenance"-->
## How is this package maintained and can I contribute?

### Package Maintenance
The Fivetran team maintaining this package only maintains the [latest version](https://hub.getdbt.com/fivetran/klaviyo/latest/) of the package. We highly recommend you stay consistent with the latest version of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_klaviyo/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Learn how to contribute to a package in dbt's [Contributing to an external dbt package article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657).

<!--section-end-->

## Are there any resources available?
- If you have questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_klaviyo/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran or would like to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).