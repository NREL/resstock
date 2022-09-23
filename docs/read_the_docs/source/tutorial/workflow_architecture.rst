Workflow Architecure
====================

At the top level of the ResStock repository you just downloaded, you will see two analysis project folders:

- ``project_national``
- ``project_testing``
 
The following OpenStudio measures are used in the ResStock workflow. Their arguments can be set based on the method that is chosen for running ResStock. See :doc:`run_project` for more information.

BuildExistingModel
  ResStockArguments
  BuildResidentialHPXML
  BuildResidentialScheduleFile
ApplyUpgrade (optional)
  ResStockArguments
  BuildResidentialHPXML
  BuildResidentialScheduleFile
HPXMLtoOpenStudio
**Other Measures** FIXME: need to fix both wfgs for this order change
ReportSimulationOutput
ReportHPXMLOutput
UpgradeCosts
**Other Reporting Measures**

OpenStudio Measures
-------------------

.. _build-existing-model:

Build Existing Model
********************

This measure creates the baseline scenario.

As a meta measure, the ``BuildExistingModel`` measure incrementally applies the following OpenStudio measures to create residential building models:

#. ``ResStockArguments``
#. ``BuildResidentialHPXML``
#. ``BuildResidentialScheduleFile``

All of these measures, with the exception of ``ResStockArguments``, are located in the `OpenStudio-HPXML <https://github.com/NREL/OpenStudio-HPXML>`_ repository.
See the `OpenStudio-HPXML documentation <https://openstudio-hpxml.readthedocs.io/en/latest/>`_ for information on workflow inputs.
  
.. _tutorial-apply-upgrade:

Apply Upgrade
*************

Each "Apply Upgrade" measure defines an upgrade scenario. An upgrade scenario is a collection of options exercised with some logic and costs applied. In the simplest case, we apply the new option to all housing units. The available upgrade options are in ``resources/options_lookup.tsv`` in your git repository. 

For this example, we will upgrade all windows by applying the ``Windows|Triple, Low-E, Non-metal, Air, L-Gain`` option to all houses across the country. We do this by entering that in the **Option 1** box on the Apply Upgrade measure. Also, we'll give the upgrade scenario a name: "Triple-Pane Windows" and a cost of $40/ft\ :superscript:`2` of window area by entering the number in **Option 1 Cost Value** and selecting "Window Area (ft^2)" for **Option 1 Cost Multiplier**. 

Like the **downselect logic**, excluded datapoints (i.e., datapoints for which the upgrade does not apply) will result in "completed invalid workflow". Note that using no downselect logic will apply the option to all housing units. For a full explanation of how to set up the options and logic surrounding them, see :doc:`../upgrade_scenario_config`.

HPXML to OpenStudio
*******************

Translate HPXML file to OpenStudio model. 

Reporting Measures
------------------

In general, reporting measures process data after the simulation has finished and produced results.

.. _report-simulation-output:

Report Simulation Output
************************

This measure reports simulation outputs for residential HPXML-based models, and is located in the `OpenStudio-HPXML <https://github.com/NREL/OpenStudio-HPXML>`_ repository.

.. _report-hpxml-output:

Report HPXML Output
*******************

This measure reports HPXML outputs for residential HPXML-based models, and is located in the `OpenStudio-HPXML <https://github.com/NREL/OpenStudio-HPXML>`_ repository.

.. _upgrade-costs:

Upgrade Costs
*************

This measure calculates upgrade costs by multiplying cost values by cost multipliers.

Manual Sampling
---------------
   
To run the sampling script yourself, from the command line execute, e.g. ``ruby resources/run_sampling.rb -p project_national -n 10000 -o buildstock.csv``, and a file ``buildstock.csv`` will be created in the ``resources`` directory. 
 
If a custom ``buildstock.csv`` file is located in a project's ``housing_characteristics`` directory when you run the project, it will automatically be used to generate simulations. If it’s not found, the sampling will be run automatically to create one. For each datapoint, the measure will then look up its building description from the sampled csv.
 
You can use this manual sampling process to downselect which simulations you want to run. For example, you can use the command above to generate a ``buildstock.csv`` for the entire U.S. and then open up this file in Excel and delete all of the rows that you don't want to simulate (e.g., all rows that aren't in New York). Keep in mind that if you do this, you will need to re-enumerate the "Building" column as "1" through the number of rows.
