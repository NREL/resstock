.. _optional_outputs:

Optional Outputs
================

Optional outputs include annual component loads, emissions, utility bills, and quantities of interest.
Additionally, timeseries outputs can be requested.

To be generated, some optional outputs need only a single switch enabled (e.g., component loads).
Others need additional input arguments specified (e.g., emissions, utility bills).

Component Loads
***************

Component loads represent the estimated contribution of different building components to the annual heating/cooling building loads.

.. csv-table::
   :file: ../../../../test/base_results/outputs/component_loads.csv

These outputs require that only a single switch is enabled.
See the `Residential HPXML Workflow Generator <https://buildstockbatch.readthedocs.io/en/latest/workflow_generators/residential_hpxml.html>`_ documentation page (i.e., ``build_existing_model`` section) for more information.

See the OpenStudio-HPXML Workflow Outputs section on `Annual Component Building Loads <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html#annual-component-building-loads>`_ for more information about component loads.

Emissions
*********

Optional emissions outputs include annual total, by fuel, and by end use, for each emissions scenario requested.
See the `Residential HPXML Workflow Generator <https://buildstockbatch.readthedocs.io/en/latest/workflow_generators/residential_hpxml.html>`_ documentation page (i.e., ``emissions`` section) for more information on how to request emissions outputs by scenario.

See the OpenStudio-HPXML Workflow Outputs section on `Annual Emissions <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html#annual-emissions>`_ for more information about annual emissions.

For the example below, the "LRMER_MidCase_15" emissions scenario was requested.
See the list of available emissions scenario choices at https://github.com/NREL/resstock/tree/develop/resources/data/cambium.

.. csv-table::
   :file: ../../../../test/base_results/outputs/emissions.csv

Utility Bills
*************

Optional utility bill outputs include annual fixed and marginal costs (total, by fuel type), and PV credits for electricity, for each utility bill scenario requested.
See the `Residential HPXML Workflow Generator <https://buildstockbatch.readthedocs.io/en/latest/workflow_generators/residential_hpxml.html>`_ documentation page (i.e., ``utility_bills`` section) for more information on how to request utility bill outputs by scenario.

See the OpenStudio-HPXML Workflow Outputs section on `Utility Bill Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html#utility-bill-outputs>`_ for more information about utility bill outputs.

.. csv-table::
   :file: ../../../../test/base_results/outputs/utility_bills.csv

Quantities of Interest
**********************

These outputs require that only a single switch is enabled.
See the `Residential HPXML Workflow Generator <https://buildstockbatch.readthedocs.io/en/latest/workflow_generators/residential_hpxml.html>`_ documentation page (i.e., ``reporting_measures`` section) for more information on how to request quantities of interest outputs.

.. csv-table::
   :file: ../../../../test/base_results/outputs/qoi_report.csv

Timeseries
**********

Specifying any timeseries frequency other than "none" results in, by default, end use consumptions and total loads timeseries output requests.
See the `Residential HPXML Workflow Generator <https://buildstockbatch.readthedocs.io/en/latest/workflow_generators/residential_hpxml.html>`_ documentation page (i.e., ``simulation_output_report`` section) for more information on how to request various timeseries outputs (or override default requests).

See the OpenStudio-HPXML Workflow Outputs section on `Timeseries Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html#timeseries-outputs>`_ for more information on timeseries outputs.
