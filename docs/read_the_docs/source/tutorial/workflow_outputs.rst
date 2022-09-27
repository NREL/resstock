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

Includes energy use (total, by end use, by fuel type), emissions, hot water, loads, peak loads, unmet hours, component loads.

.. csv-table::
   :file: ../../../../test/base_results/baseline/annual/report_simulation_output.csv

Utility Bills
*************

Fixed and marginal costs (total, by fuel type), and PV credits.

.. csv-table::
   :file: ../../../../test/base_results/baseline/annual/report_utility_bills.csv

Other Outputs
-------------

Additionally you can find other outputs, including characteristics, sample weights, upgrade costs, and quantities of interest.

Characteristics
***************

.. csv-table::
   :file: ../../../../test/base_results/baseline/annual/build_existing_model.csv

.. _upgrade-costs-columns:

Upgrade Costs
*************

.. csv-table::
   :file: ../../../../test/base_results/upgrades/annual/upgrade_costs.csv

Quantities of Interests
***********************

.. csv-table::
   :file: ../../../../test/base_results/baseline/annual/qoi_report.csv
