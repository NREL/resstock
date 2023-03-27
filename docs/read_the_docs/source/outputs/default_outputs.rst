.. _default_outputs:

Default Outputs
===============

The default set of outputs include housing characteristics, annual simulation outputs, and upgrade cost information.

Housing Characteristics
***********************

Default characteristics include sampled properties for each dwelling unit.

.. csv-table::
   :file: characteristics.csv

Simulation Output
*****************

Default annual simulation outputs include energy consumptions (total, by fuel, and by end use), hot water uses, building loads, unmet hours, and peak building electricity/loads.

See the OpenStudio-HPXML Workflow Outputs section on `Annual Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html#annual-outputs>`_ for more information about annual outputs.

.. csv-table::
   :file: simulation_outputs.csv

.. _upgrade-costs:

Upgrade Costs
*************

Upgrade cost multipliers include:

.. csv-table::
   :file: cost_multipliers.csv

Other upgrade cost information includes:

.. list-table::

   * - upgrade_costs.option_<#>_name
   * - upgrade_costs.option_<#>_cost_usd
   * - upgrade_costs.option_<#>_lifetime_yrs
   * - upgrade_costs.upgrade_cost_usd

where <#> represents any of the defined option numbers.
See :doc:`../upgrade_scenario_config` for more information.

Note that the name, cost, and lifetime information will only be populated when applicable for a given upgrade option (i.e., when the apply logic evaluates as true).
