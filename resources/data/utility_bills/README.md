**Simple utility rate structures**

In the YML file's "simple_filepath" field for utility bill scenario definitions, enter a relative file path to a TSV lookup file (e.g., "data/utility_bills/simple_rates/State.tsv") containing user-defined values corresponding to arguments for fixed costs, marginal rates, and PV.
The first column of the TSV lookup file contains the name of a chosen parameter for which sets of argument values are assigned according to its options.
Any blank fields, or missing options for a parameter not specified in the TSV lookup file, will be defaulted.

See the Simple section of OpenStudio-HPXML's documentation for [Electricity Rates](https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#electricity-rates), and [Fuel Rates](https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#fuel-rates), for more information about arguments for fixed charges, marginal rates, and PV.

**Detailed utility rate structures**

In the YML file's "detailed_filepath" field for utility bill scenario definitions, enter a relative file path to a TSV lookup file (e.g., "data/utility_bills/detailed_rates/County.tsv") containing user-defined values corresponding to arguments for electricity tariff file paths, fixed costs and marginal rates for fuels, and PV.
The first column of the TSV lookup file contains the name of a chosen parameter for which sets of argument values are assigned according to its options.
The TSV lookup file's electricity tariff file paths are relative to the parent folder of the "detailed_filepath" (e.g., "Flat/Sample Flat Rate.json").
Any blank fields, or missing options for a parameter not specified in the TSV lookup file, will be defaulted.

See the Detailed section of OpenStudio-HPXML's documentation for [Electricity Rates](https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#electricity-rates), and [Fuel Rates](https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#fuel-rates), for more information about arguments for electricity tariff file paths, fixed charges, marginal rates, and PV.

For both Simple and Detailed utility rate structures, refer to BuildStockBatch's documentation for [Residential HPXML Workflow Generator](https://buildstockbatch.readthedocs.io/en/stable/workflow_generators/residential_hpxml.html) for more information about YML file utility bills -related arguments.