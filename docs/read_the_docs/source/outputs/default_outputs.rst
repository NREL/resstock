.. _default_outputs:

Default Outputs
===============

The default set of outputs include housing characteristics, annual simulation outputs, and upgrade cost information.

Specifying any timeseries frequency other than "none" results in, by default, end use consumptions and total loads timeseries output requests.
See the `Residential HPXML Workflow Generator <https://buildstockbatch.readthedocs.io/en/latest/workflow_generators/residential_hpxml.html>`_ documentation page (i.e., ``simulation_output_report`` section) for more information on how to request various timeseries outputs (or override default requests).

Housing Characteristics
***********************

Default characteristics include sampled properties for each dwelling unit.

.. csv-table::
   :file: csv_tables/characteristics.csv

Simulation Output
*****************

Default annual simulation outputs include energy consumptions (total, by fuel, and by end use), hot water uses, building loads, unmet hours, peak building electricity/loads, HVAC capacities, and HVAC design temperatures/loads.

See the OpenStudio-HPXML Workflow Outputs sections on `Annual Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html#annual-outputs>`_ and `Timeseries Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html#timeseries-outputs>`_ for more information about annual outputs.

.. csv-table::
   :file: csv_tables/simulation_outputs.csv

.. _upgrade-costs:

Upgrade Costs
*************

Upgrade cost multipliers include:

.. csv-table::
   :file: csv_tables/cost_multipliers.csv

Other upgrade cost information includes:

.. list-table::

   * - upgrade_costs.option_<#>_name
   * - upgrade_costs.option_<#>_cost_usd
   * - upgrade_costs.option_<#>_lifetime_yrs
   * - upgrade_costs.upgrade_cost_usd

where <#> represents any of the defined option numbers.
See :doc:`../upgrade_scenario_config` for more information.

Note that the name, cost, and lifetime information will only be populated when applicable for a given upgrade option (i.e., when the apply logic evaluates as true).
