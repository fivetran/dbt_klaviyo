# What goes in this folder?

The json and html files which we use to create the github pages docs site will be dropped in this folder. To create these you will:
- Navigate to the `integration_tests` directory in your terminal.
- Execute `dbt deps`
- Execute `dbt seed --full-refresh -t bigquery && dbt run --full-refresh -t bigquery && dbt test -t bigquery`
- Execute `dbt docs -t bigquery && dbt docs serve -t bigquery`
- Check to make sure there are no errors in the site that was just served.
- Drag the following files into this folder: catalog.json, index.html, manifest.json, run_results.json
- DELETE THIS FILE