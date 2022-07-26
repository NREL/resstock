Set Up the Analysis Project
===========================

At the top level of the ResStock repository you just downloaded, you will see two analysis project folders:

- ``project_national``
- ``project_testing``
 
The following OpenStudio measures are used in the ResStock workflow. Their arguments can be set based on the method that is chosen for running ResStock. See :doc:`run_project` for more information.
 
OpenStudio Measures
-------------------

.. _build-existing-model:

Build Existing Model
********************

This measure creates the baseline scenario. Set the following inputs:

#. ``Building ID``: This sets the number of simulations to run in the baseline and each upgrade case.
#. ``Workflow JSON``: The name of the JSON file (in the resources dir) that dictates the order in which measures are to be run. If not provided, the order specified in ``resources/options_lookup.tsv`` will be used.
#. ``Number of Buildings Represented``: The total number of buildings this sampling is meant to represent. This sets the weighting factors. For the U.S. housing stock, excluding Alaska and Hawaii, this is 136,569,411 homes (American Community Survey 2019).
#. ``Sample Weight of Simulation``: The number of buildings each simulation represents. Total number of buildings / Number of simulations. This argument is optional (it is only needed for running simulations on NREL HPC), so you can leave it blank.
#. ``Downselect Logic``: Logic that specifies the subset of the building stock to be considered in the analysis. Specify one or more ``parameter|option`` as found in the ``resources/options_lookup.tsv``. (This uses the same syntax as the :ref:`tutorial-apply-upgrade` measure.) For example, if you wanted to only simulate California homes you could enter ``Location Region|CR11`` in this field (CR refers to "Custom Region", which is based on RECS 2009 reportable domains aggregated into groups with similar climates; see the entire `custom region map <https://github.com/NREL/resstock/wiki/Custom-Region-%28CR%29-Map>`_). Datapoints that are excluded from the downselect logic will result in "completed invalid workflow". Note that the ``Building ID`` input refers to the number of datapoints *before* downselection, not after. This means that the number of datapoints remaining after downselection would be somewhere between zero (i.e., no datapoints matched the downselect logic) and ``Building ID`` (i.e., all datapoints matched the downselect logic).
#. ``Measures to Ignore``: **INTENDED FOR ADVANCED USERS/WORKFLOW DEVELOPERS ONLY.** Measures to exclude from the OpenStudio Workflow specified by listing one or more measure directories separated by '|'. Core ResStock measures cannot be ignored (the Build Existing Model measure will fail).
#. ``Simulation Control: Timestep``: Value must be a divisor of 60.
#. ``Simulation Control: Run Period Begin Month``: This numeric field should contain the starting month number (1 = January, 2 = February, etc.) for the annual run period desired.
#. ``Simulation Control: Run Period Begin Day of Month``: This numeric field should contain the starting day of the starting month (must be valid for month) for the annual run period desired.
#. ``Simulation Control: Run Period End Month``: This numeric field should contain the end month number (1 = January, 2 = February, etc.) for the annual run period desired.
#. ``Simulation Control: Run Period End Day of Month``: This numeric field should contain the ending day of the ending month (must be valid for month) for the annual run period desired.
#. ``Simulation Control: Run Period Calendar Year``: This numeric field should contain the calendar year that determines the start day of week (e.g., 2007 sets the start day of week to Monday). If you are running simulations using AMY weather files, the value entered for calendar year will not be used; it will be overridden by the actual year found in the AMY weather file.
#. ``Emissions: Scenario Names``: Names of emissions scenarios. If multiple scenarios, use a comma-separated list.
#. ``Emissions: Types``: Types of emissions (e.g., CO2e, NOx, etc.). If multiple scenarios, use a comma-separated list.
#. ``Emissions: Electricity Folders``: Relative paths of electricity emissions factor schedule files with hourly values. Paths are relative to the resources folder (see `this example yml file <https://github.com/NREL/resstock/blob/develop/project_national/national_baseline.yml>`_). If multiple scenarios, use a comma-separated list. File names must contain GEA region names. Units are kg/MWh.
#. ``Emissions: Natural Gas Values``: Natural gas emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list. Units are lb/MBtu (million Btu).
#. ``Emissions: Propane Values``: Propane emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list. Units are lb/MBtu (million Btu).
#. ``Emissions: Fuel Oil Values``: Fuel oil emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list. Units are lb/MBtu (million Btu).
#. ``Emissions: Wood Values``: Wood emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list. Units are lb/MBtu (million Btu).

As a meta measure, the ``BuildExistingModel`` measure incrementally applies the following OpenStudio measures to create residential building models:

#. ``ResStockArguments``
#. ``BuildResidentialHPXML``
#. ``BuildResidentialScheduleFile``
#. ``HPXMLtoOpenStudio``

All of these measures, with the exception of ``ResStockArguments``, are located in the `OpenStudio-HPXML <https://github.com/NREL/OpenStudio-HPXML>`_ repository.
See the `OpenStudio-HPXML documentation <https://openstudio-hpxml.readthedocs.io/en/latest/>`_ for information on workflow inputs and outputs.
  
.. _tutorial-apply-upgrade:

Apply Upgrade
*************

Each "Apply Upgrade" measure defines an upgrade scenario. An upgrade scenario is a collection of options exercised with some logic and costs applied. In the simplest case, we apply the new option to all housing units. The available upgrade options are in ``resources/options_lookup.tsv`` in your git repository. 

For this example, we will upgrade all windows by applying the ``Windows|Triple, Low-E, Non-metal, Air, L-Gain`` option to all houses across the country. We do this by entering that in the **Option 1** box on the Apply Upgrade measure. Also, we'll give the upgrade scenario a name: "Triple-Pane Windows" and a cost of $40/ft\ :superscript:`2` of window area by entering the number in **Option 1 Cost Value** and selecting "Window Area (ft^2)" for **Option 1 Cost Multiplier**. 

Like the **downselect logic**, excluded datapoints (i.e., datapoints for which the upgrade does not apply) will result in "completed invalid workflow". Note that using no downselect logic will apply the option to all housing units. For a full explanation of how to set up the options and logic surrounding them, see :doc:`../upgrade_scenario_config`.

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
