.. _workflow_outputs:

Workflow Outputs
================

ResStock generates both a standard set of outputs as well as other outputs.
The standard set of outputs include annual energy consumption, emissions, utility bills, etc., as well as optionally requested timeseries outputs.

Other outputs include dwelling unit characteristics, upgrade cost information, and (optionally) quantities of interest.

Standard Outputs
----------------

See the `OpenStudio-HPXML Workflow Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html>`_ for documentation on workflow outputs.

Simulation Output
*****************

Includes energy use (total, by end use, by fuel type), hot water, loads, peak loads, unmet hours, component loads.

.. csv-table::
   :file: ../../../../test/base_results/outputs/simulation_outputs.csv

Emissions
*********

.. csv-table::
   :file: ../../../../test/base_results/outputs/emissions.csv

Utility Bills
*************

Includes fixed and marginal costs (total, by fuel type), and PV credits.

.. csv-table::
   :file: ../../../../test/base_results/outputs/utility_bills.csv

Other Outputs
-------------

Additionally you can find other outputs, including characteristics, sample weights, upgrade related multipliers and costs, and quantities of interest.

Characteristics
***************

.. csv-table::
   :file: ../../../../test/base_results/outputs/characteristics.csv

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

Note that option level information will only exist when applicable for a given upgrade.

Quantities of Interests
***********************

.. csv-table::
   :file: ../../../../test/base_results/baseline/annual/qoi_report.csv
