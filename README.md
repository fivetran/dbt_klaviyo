[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
# Klaviyo

This package models Klaviyo data from [Fivetran's connector](https://fivetran.com/docs/applications/klaviyo). It uses data in the format described by [this ERD](https://fivetran.com/docs/applications/klaviyo#schemainformation).

This package enables you to better understand the efficacy of your email and SMS marketing efforts. It achieves this by:
- Performing last-touch attribution on events in order to properly credit campaigns and flows with conversions
- Enriching the core event table with data regarding associated users, flows, and campaigns
- Aggregating key metrics, such as associated revenue, related to each user's interactions with individual campaigns and flows (and organic actions)
- Aggregating these metrics further, to the grain of campaigns, flows, and individual users

## Models

This package contains transformation models, designed to work simultaneously with our [Klaviyo source package](https://github.com/fivetran/dbt_klaviyo_source). A dependency on the source package is declared in this package's `packages.yml` file, so it will automatically download when you run `dbt deps`. The primary outputs of this package are described below. Intermediate models are used to create these output models.

| **model**                | **description**                                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [klaviyo__events](https://github.com/fivetran/dbt_klaviyo/blob/master/models/klaviyo__events.sql)             | Each record represents a unique event in Klaviyo, enhanced with a customizable last-touch attribution model associating events with flows and campaigns. Also includes information about the user who triggered the event. Materialized incrementally by default. |
| [klaviyo__person_campaign_flow](https://github.com/fivetran/dbt_klaviyo/blob/master/models/klaviyo__person_campaign_flow.sql)             | Each record represents a unique person-campaign or person-flow combination, enriched with sums of the numeric values (i.e. revenue) associated with each kind of conversion, and counts of the number of triggered conversion events. |
| [klaviyo__campaigns](https://github.com/fivetran/dbt_klaviyo/blob/master/models/klaviyo__campaigns.sql)             | Each record represents a unique campaign, enriched with user interaction metrics, any revenue attributed to the campaign, and other conversions. |
| [klaviyo__flows](https://github.com/fivetran/dbt_klaviyo/blob/master/models/klaviyo__flows.sql)             | Each record represents a unique flow, enriched with user interaction metrics, any revenue attributed to the flow, and other conversions. |
| [klaviyo__persons](https://github.com/fivetran/dbt_klaviyo/blob/master/models/klaviyo__persons.sql)             | Each record represents a unique user, enriched with metrics around the campaigns and flows they have interacted with, any associated revenue (organic as well as attributed to flows/campaigns), and their recent activity. |

## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

Include in your `packages.yml`

```yaml
packages:
  - package: fivetran/klaviyo
    version: [">=0.4.0", "<0.5.0"]
```

## Configuration

By default, this package looks for your Klaviyo data in the `klaviyo` schema of your [target database](https://docs.getdbt.com/docs/running-a-dbt-project/using-the-command-line-interface/configure-your-profile). If this is not where your Klaviyo data is, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  klaviyo_database: your_database_name
  klaviyo_schema: your_schema_name 
```

### Unioning Multiple Klaviyo Connectors
If you have multiple Klaviyo connectors in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. The package will union all of the data together and pass the unioned table into the transformations. You will be able to see which source it came from in the `source_relation` column of each model. To use this functionality, you will need to set either (**note that you cannot use both**) the `klaviyo_union_schemas` or `klaviyo_union_databases` variables:

```yml
# dbt_project.yml
...
config-version: 2
vars:
  klaviyo_source:
    klaviyo_union_schemas: ['klaviyo_usa','klaviyo_canada'] # use this if the data is in different schemas/datasets of the same database/project
    klaviyo_union_databases: ['klaviyo_usa','klaviyo_canada'] # use this if the data is in different databases/projects but uses the same schema name
```

### Attribution Lookback Window

This package attributes events to campaigns and flows via a last-touch attribution model in line with Klaviyo's internal [attribution](https://help.klaviyo.com/hc/en-us/articles/115005248128). This is necessary to perform, as Klaviyo does not automatically send attribution data for certain metrics. Read more about how the package's attribution works [here](https://github.com/fivetran/dbt_klaviyo/blob/master/models/intermediate/int_klaviyo.yml#L4) and see the source code [here](https://github.com/fivetran/dbt_klaviyo/blob/master/models/intermediate/int_klaviyo__event_attribution.sql).

By default, the package will use a lookback window of **120 hours (5 days)** for email-events and a window of **24 hours** for SMS-events. For example, if an `'Ordered Product'` conversion is tracked on April 27th, and the customer clicked a campaign email on April 24th, their purchase order event will be attributed with the email they interacted with. If the campaign was sent and opened via SMS instead of email, the `'Ordered Product'` conversion would not be attributed to any campaign.

To change either of these lookback windows, add the following configuration to your `dbt_project.yml` file:

> If you would like to disable the package's attribution process completely, set these variables to `0`.

```yml
# dbt_project.yml

...
config-version: 2

vars:
  klaviyo:
    klaviyo__email_attribution_lookback: x_number_of_hours # default = 120 hours = 5 days. MUST BE INTEGER.
    klaviyo__sms_attribution_lookback: y_number_of_hours # default = 24 hours. MUST BE INTEGER.
```

> Note that events already associated with campaigns or flows in Klaviyo will never have their source attribution data overwritten by the package modeling.

### Attribution-Eligible Event Types

By default, this package will only credit email opens, email clicks, and SMS opens with conversions. That is, only flows and campaigns attached to these kinds of events will qualify for attribution in our package. This is aligned with Klaviyo's internal [attribution model](https://help.klaviyo.com/hc/en-us/articles/115005248128).

However, this package allows for the customization of which events can qualify for attribution. To expand or otherwise change this filter on attribution, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  klaviyo:
    klaviyo__eligible_attribution_events: ['types', 'of', 'events', 'to', 'attribute', 'conversions', 'to'] # this is case-SENSITIVE and should be in all lower-case!!
```

### Filtering Conversion Metrics to Pivot Out

The Klaviyo dbt package pivots relevant conversion events out into metric columns in the `klaviyo__person_campaign_flow`, `klaviyo__campaigns`, `klaviyo__flows`, and `klaviyo__persons` models. The package will sum up revenue attributed to each person's interactions with flows and campaigns (plus organic actions), count the instances of each kind of triggered conversion, and, at the flow and campaign grain, count the number of unique people who converted. The package splits up events to pivot out into two variables, `klaviyo__count_metrics` and `klaviyo__sum_revenue_metrics`, which will record the count of events/users and their associated revenue values, repsectively.

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

### Passthrough Columns

Additionally, the Klaviyo package includes all source columns defined in the [macros folder](https://github.com/fivetran/dbt_klaviyo_source/tree/main/macros) of the source package. We highly recommend including custom fields in this package as models now only bring in the standard fields for the `EVENT` and `PERSON` tables.

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

### Changing the Build Schema

By default, this package will build the Klaviyo final models within a schema titled (`<target_schema>` + `_klaviyo`), intermediate models in (`<target_schema>` + `_int_klaviyo`), and staging models within a schema titled (`<target_schema>` + `_stg_klaviyo`) in your target database. If this is not where you would like your modeled Klaviyo data to be written to, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
models:
  klaviyo:
    +schema: my_new_schema_name # leave blank for just the target_schema
    intermediate:
      +schema: my_new_schema_name # leave blank for just the target_schema
  klaviyo_source:
    +schema: my_new_schema_name # leave blank for just the target_schema
```

> Note that if your profile does not have permissions to create schemas in your warehouse, you can set each `+schema` to blank. The package will then write all tables to your pre-existing target schema.

## Contributions

Don't see a model or specific metric you would have liked to be included? Notice any bugs when installing and running the package? If so, we highly encourage and welcome contributions to this package!
Please create issues or open PRs against `main`. Check out [this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package.

## Database Support

This package has been tested on BigQuery, Snowflake, Redshift, Postgres, and Databricks.

### Databricks Dispatch Configuration
dbt `v0.20.0` introduced a new project-level dispatch configuration that enables an "override" setting for all dispatched macros. If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
# dbt_project.yml

dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

## Resources:

- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Have questions, feedback, or need help? Book a time during our office hours [using Calendly](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or email us at solutions@fivetran.com
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn how to orchestrate your models with [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt)
- Learn more about Fivetran overall [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
