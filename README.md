# Klaviyo

This package models Klaviyo data from [Fivetran's connector](https://fivetran.com/docs/applications/klaviyo). It uses data in the format described by [this ERD](https://fivetran.com/docs/applications/klaviyo#schemainformation).

This package enables you to better understand the efficacy of your email and SMS marketing efforts. It achieves this by:
- Performing last-touch attribution on events in order to properly credit campaigns and flows with conversions
- Enriching the core event table with data regarding associated users, flows, and campaigns
- Aggregating key metrics, such as associated revenue, related to each users' interactions with individual campaigns and flows
- Aggregating these metrics further, to the grain of campaigns, flows, and individual users

## Models

This package contains transformation models, designed to work simultaneously with our [Klaviyo source package](https://github.com/fivetran/dbt_klaviyo_source). A dependency on the source package is declared in this package's `packages.yml` file, so it will automatically download when you run `dbt deps`. The primary outputs of this package are described below. Intermediate models are used to create these output models.

| **model**                | **description**                                                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| [klaviyo__events](models/klaviyo__events.sql)             | Each record represents a unique event in Klaviyo, enhanced with a customizable last-touch attribution model associating events with flows and campaigns. Also includes information about the user who triggered the event. |
| [klaviyo__person_campaign](models/klaviyo__person_campaign.sql)             | Each record represents a unique person-campaign combination, enriched with sums of the numeric values (ie revenue) associated with each kind of conversion, and counts of the number of triggered conversion events. |
| [klaviyo__person_flow](models/klaviyo__person_flow.sql)             | Each record represents a unique person-flow combination, enriched with sums of the numeric values (ie revenue) associated with each kind of conversion, and counts of the number of triggered conversion events. |
| [klaviyo__campaigns](models/klaviyo__campaigns.sql)             | Each record represents a unique campaign, enriched with metrics regarding users interacted with, revenue associated with the campaign, and other conversions. |
| [klaviyo__flows](models/klaviyo__flows.sql)             | Each record represents a unique flow, enriched with metrics regarding users interacted with, revenue associated with the flow, and other conversions. |
| [klaviyo__person](models/klaviyo__person.sql)             | Each record represents a unique user, enriched with metrics around the campaigns and flows they have interacted with, any associated revenue, and their recent activity. |

## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

```yml
# packages.yml
packages:
  - package: fivetran/klaviyo
    version: [">=0.1.0", "<0.2.0"]
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

### Attribution Lookback Window
This package attributes events to campaigns and flows via a last-touch attribution model in line with Klaviyo's internal [attribution](https://help.klaviyo.com/hc/en-us/articles/115005248128). This is necessary to perform, as Klaviyo does not automatically send attribution data for certain metrics. 

By default, the package will use a lookback window of **5 days** for email-events and a window of **1 day** for sms-events. For example, if an `'Ordered Product'` conversion is tracked on April 27th, and the customer clicked a campaign email on April 24th, their purchase order event will be attributed with the email they interacted with. If the campaign was sent and opened via SMS instead of email, the `'Ordered Product'` conversion would not be attributed to any campaign.

To change either of these lookback windows, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  klaviyo:
    klaviyo__email_attribution_lookback: x_number_of_hours # default = 120 hours = 5 days
    klaviyo__sms_attribution_lookback: y_number_of_hours # default = 24 hours
```

> Note that events already associated with campaigns or flows in Klaviyo will not have their source attribution data overwritten by the package modeling. 

### Attribution Event Filter
By default, this package will only credit email opens, email clicks, and SMS opens with conversions. This event-type filter is applied when selecting from the staging `EVENT` table, whose column names can be found [here](https://github.com/fivetran/dbt_klaviyo_source/blob/main/models/stg_klaviyo__event.sql#L22).

To expand or otherwise change this filter on attribution, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  klaviyo:
    klaviyo__event_attribution_filter: "sql clause returning a boolean" # default = "lower(type) in ('opened email', 'clicked email', 'clicked sms')"
```

### Filtering Conversion Metrics to Pivot Out
By default, this package will select all distinct conversion metrics tracked in the `EVENT` table, and pivot these out in the `klaviyo__person_campaign` and `klaviyo__person_flow` final models. The package will then sum up revenue attributed to each person's interactions with flows and campaigns, and count the instances of each kind of triggered conversion. This could possibly produce cluttered final models with unnecessary columns, particularly if you have platforms integrated in Klaviyo. To limit the conversion metrics that are pivoted out, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  klaviyo:
    klaviyo__pivot_conversion_filter: "sql clause returning a boolean" # default = 'true'
```

### Passthrough Columns
Additionally, the Klaviyo package includes all source columns defined in the [macros folder](https://github.com/fivetran/dbt_klaviyo_source/tree/main/macros) of the source package. We highly recommend including custom fields in this package as models now only bring in the standard fields for the `EVENT` and `PERSON` tables. 

You can add more columns using our pass-through column variables. These variables allow for the pass-through fields to be aliased (`alias`) and casted (`transform_sql`) if desired, but not required. Datatype casting is configured via a sql snippet within the `transform_sql` key. You may add the desired sql while omitting the `as field_name` at the end and your custom pass-though fields will be casted accordingly. Use the below format for declaring the respective pass-through variables.

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
By default this package will build the Iterable staging models within a schema titled (<target_schema> + `_stg_klaviyo`) in your target database. If this is not where you would like you Klaviyo staging data to be written to, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
models:
    klaviyo_source:
        +schema: my_new_schema_name # leave blank for just the target_schema
```

## Contributions
Don't see a model or specific metric you would have liked to be included? Notice any bugs when installing 
and running the package? If so, we highly encourage and welcome contributions to this package! 
Please create issues or open PRs against `master`. Check out [this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package.

## Database Support
This package has been tested on BigQuery, Snowflake, Redshift, and Postgres.

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Have questions, feedback, or need help? Book a time during our office hours [using Calendly](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or email us at solutions@fivetran.com
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn how to orchestrate [dbt transformations with Fivetran](https://fivetran.com/docs/transformations/dbt)
- Learn more about Fivetran overall [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices