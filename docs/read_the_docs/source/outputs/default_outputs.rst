.. _default_outputs:

Default Outputs
===============

The default set of outputs include dwelling unit characteristics, annual simulation outputs, and upgrade costs information.

Characteristics
***************

Default characteristics nclude sampled properties for each dwelling unit.

.. csv-table::
   :file: ../../../../test/base_results/outputs/characteristics.csv

Simulation Output
*****************

Default annual simulation outputs include energy consumption (total, by fuel, and by end use), hot water uses, building loads, unmet hours, and peak building electricity/loads.

See the OpenStudio-HPXML Workflow Outputs section on `Annual Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html#annual-outputs>`_ for documentation on annual outputs.

.. csv-table::
   :file: ../../../../test/base_results/outputs/simulation_outputs.csv

.. _upgrade-costs:

Upgrade Costs
*************

Upgrade cost multipliers include:

.. csv-table::
   :file: ../../../../test/base_results/outputs/cost_multipliers.csv

Other upgrade cost information includes:

.. list-table::

   * - upgrade_costs.option_<#>_name
   * - upgrade_costs.option_<#>_cost_usd
   * - upgrade_costs.option_<#>_lifetime_yrs
   * - upgrade_costs.upgrade_cost_usd

where <#> represents any of the defined option numbers.
See :doc:`../upgrade_scenario_config` for more information.

Note that option level information will only exist when applicable for a given upgrade.
