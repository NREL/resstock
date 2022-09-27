Workflow Outputs
================

ResStock generates both a standard set of outputs as well as other outputs.
The standard set of outputs include annual energy consumption (e.g., by end use and fuel type), emissions, utility bills, etc., as well as optionally requested timeseries outputs.
Other outputs include building characteristics, upgrade cost multipliers, and quantities of interest.

TODO: something about results.csv (bsb vs run_analysis)

Standard Outputs
----------------

See the `OpenStudio-HPXML Workflow Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html>`_ for documentation on workflow outputs.

Simulation Output
*****************

Includes energy use (total, by end use, by fuel type), emissions, hot water, loads, peak loads, unmet hours, component loads.

.. csv-table::
   :file: ../../../../test/base_results/baseline/annual/report_simulation_output.csv

Utility Bills
*************

Fixed and marginal costs (total, by fuel type), PV credit.

.. csv-table::
   :file: ../../../../test/base_results/baseline/annual/report_utility_bills.csv

Other Outputs
-------------

Additionally you can find other outputs, including building IDs and characteristics, weights, upgrade cost multipliers, and quantities of interest.

Characteristics
***************

.. csv-table::
   :file: ../../../../test/base_results/baseline/annual/build_existing_model.csv

.. _upgrade-costs-columns:

Upgrade Costs
*************

Multipliers

.. csv-table::
   :file: ../../../../test/base_results/baseline/annual/upgrade_costs.csv

Options applied, option costs, upgrade cost.

QOIs
****

.. csv-table::
   :file: ../../../../test/base_results/baseline/annual/qoi_report.csv
   
Additional Outputs
******************

- building_id

  This is the unique identifier assigned to the ResStock sample.
  Upgrades correspond to baseline models based on the building ID.

- weight