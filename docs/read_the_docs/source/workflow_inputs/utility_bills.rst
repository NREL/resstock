.. _utility-bill-calculations:

Utility Bill Calculations
=========================
This section discusses the methods available in ResStock to calculate utility bills and data sources available for various fuels.

.. _utility-bill-calculation-methods:


Utility bill calculation methods
*********************************
Details about the data structures can be seen in the ``resources/data/utility_bills`` `directory <https://github.com/NREL/resstock/tree/develop/resources/data/utility_bills>`_ in the repository.


.. _simple-utility-rate-calcuations:

Simple utility rate calculations
________________________________

In the YML file's "simple_filepath" field for utility bill scenario definitions, enter a relative file path to a TSV lookup file (e.g., "resources/data/utility_bills/simple_rates/State.tsv") containing user-defined values corresponding to arguments for fixed costs, marginal rates, and PV.
The first column of the TSV lookup file contains the name of a chosen parameter for which sets of argument values are assigned according to its options.
Any blank fields, or missing options for a parameter not specified in the TSV lookup file, will be defaulted.

See the Simple section of OpenStudio-HPXML's documentation for `Electricity Rates <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#electricity-rates>`_, and `Fuel Rates <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#fuel-rates>`_, for more information about arguments for fixed charges, marginal rates, and PV.


.. _detailed-utility-rate-calcuations:

Detailed utility rate calculations
__________________________________

In the YML file's "detailed_filepath" field for utility bill scenario definitions, enter a relative file path to a TSV lookup file (e.g., "data/utility_bills/detailed_rates/County.tsv") containing user-defined values corresponding to arguments for electricity tariff file paths, fixed costs and marginal rates for fuels, and PV.
The first column of the TSV lookup file contains the name of a chosen parameter for which sets of argument values are assigned according to its options.
The TSV lookup file's electricity tariff file paths are relative to the parent folder of the "detailed_filepath" (e.g., "Flat/Sample Flat Rate.json").
Any blank fields, or missing options for a parameter not specified in the TSV lookup file, will be defaulted.

See the Detailed section of OpenStudio-HPXML's documentation for `Electricity Rates <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#electricity-rates>`_, and `Fuel Rates <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#fuel-rates>`_, for more information about arguments for electricity tariff file paths, fixed charges, marginal rates, and PV.

For both Simple and Detailed utility rate structures, refer to BuildStockBatch's documentation for `Residential HPXML Workflow Generator <https://buildstockbatch.readthedocs.io/en/stable/workflow_generators/residential_hpxml.html>`_ for more information about YML file utility bills -related arguments.


.. _utility-bill-data-sources:

Data sources for utility bill calcuations
*****************************************
Here is a list of data sources typically used in utility bill calculations in ResStock:


.. _electricity-rate-data-sources:

Electricity bill data sources
_____________________________

- EIA Form 861
- URDB


.. _natural-gas-bill-data-sources:

Natural gas bill data sources
_____________________________

- American Gas Association
- EIA Form 176


.. fuel-oil-and-propane-bill-data-sources:

Fuel oil and propane bill data sources
______________________________________

EIA Weekly Heating Oil and Propane Prices - Fuel Oil
EIA Weekly Heating Oil and Propane Prices - Propane