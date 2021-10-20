Set Up the Analysis Project
===========================

At the top level of the ResStock repository you just downloaded, you will see two analysis project folders:

 - project_national
 - project_testing
 
OpenStudio Measures
-------------------

.. _build-existing-model:

Build Existing Model
^^^^^^^^^^^^^^^^^^^^

Using this measure you can set the simulation timesteps per hour, the run period begin month/day and end month/day, and the calendar year (for start day of week). By default the simulations use a 10-min timestep (i.e., the number of timesteps per hour is 6), start on January 1, end on December 31, and run with a calendar year of 2007 (start day of week is Monday). If you are running simulations using AMY weather files, the value entered for calendar year will not be used; it will be overridden by the actual year found in the AMY weather file.

This measure creates the baseline scenario. It incrementally applies OpenStudio measures (located in the ``resources`` directory, which should be at the same level as your project directory) to create residential building models. Set the following inputs:

**Building ID -- Max**
  This sets the number of simulations to run in the baseline and each upgrade case. For this tutorial I am going to set this to 1000. Most analyses will require more, but we're going to keep the total number small for simulation time and cost.

**Number of Buildings Represented**
  The total number of buildings this sampling is meant to represent. This sets the weighting factors. For the U.S. single-family detached housing stock, this is 80 million homes. 
  
**Sample Weight of Simulation**
  The number of buildings each simulation represents. Total number of buildings / Number of simulations. This argument is optional (it is only needed for running simulations on NREL HPC), so you can leave it blank.
  
**Downselect Logic**
  Logic that specifies the subset of the building stock to be considered in the analysis. Specify one or more ``parameter|option`` as found in the ``resources/options_lookup.tsv``. (This uses the same syntax as the :ref:`tutorial-apply-upgrade` measure.) For example, if you wanted to only simulate California homes you could enter ``Location Region|CR11`` in this field (CR refers to "Custom Region", which is based on RECS 2009 reportable domains aggregated into groups with similar climates; see the entire `custom region map`_). Datapoints that are excluded from the downselect logic will result in "completed invalid workflow". Note that the **Building ID - Max** input refers to the number of datapoints *before* downselection, not after. This means that the number of datapoints remaining after downselection would be somewhere between zero (i.e., no datapoints matched the downselect logic) and **Building ID - Max** (i.e., all datapoints matched the downselect logic).

**Measures to Ignore**
  **INTENDED FOR ADVANCED USERS/WORKFLOW DEVELOPERS ONLY.** Measures to exclude from the OpenStudio Workflow specified by listing one or more measure directories separated by '|'. Core ResStock measures cannot be ignored (the Build Existing Model measure will fail).

.. _custom region map: https://github.com/NREL/resstock/wiki/Custom-Region-(CR)-Map

.. note::
   
   **Manual Sampling**: To run the sampling script yourself, from the command line execute, e.g. ``ruby resources/run_sampling.rb -p project_national -n 10000 -o buildstock.csv``, and a file ``buildstock.csv`` will be created in the ``resources`` directory. 
   
   If a custom ``buildstock.csv`` file is located in a project's ``housing_characteristics`` directory when you run the project, it will automatically be used to generate simulations. If it’s not found, the ``run_sampling.rb`` script will be run automatically on OpenStudio-Server to create one. You’ll also want to make sure that the number of buildings in the sampling csv file matches the max value for the Building ID argument in the Build Existing Model, as that tells OpenStudio how many datapoints to run. (For each datapoint, the measure will then look up its building description from the sampling csv.) 
   
   You can use this manual sampling process to downselect which simulations you want to run. For example, you can use the command above to generate a ``buildstock.csv`` for the entire U.S. and then open up this file in Excel and delete all of the rows that you don't want to simulate (e.g., all rows that aren't in New York). Keep in mind that if you do this, you will need to re-enumerate the "Building" column as "1" through the number of rows.
  
.. _tutorial-apply-upgrade:

Apply Upgrade
^^^^^^^^^^^^^

Each "Apply Upgrade" measure defines an upgrade scenario. An upgrade scenario is a collection of options exercised with some logic and costs applied. In the simplest case, we apply the new option to all houses. The available upgrade options are in ``resources/options_lookup.tsv`` in your git repository. 

For this example, we will upgrade all windows by applying the ``Windows|Triple, Low-E, Non-metal, Air, L-Gain`` option to all houses across the country. We do this by entering that in the **Option 1** box on the Apply Upgrade measure. Also, we'll give the upgrade scenario a name: "Triple-Pane Windows" and a cost of $40/ft\ :superscript:`2` of window area by entering the number in **Option 1 Cost Value** and selecting "Window Area (ft^2)" for **Option 1 Cost Multiplier**. 

Like the **downselect logic**, excluded datapoints (i.e., datapoints for which the upgrade does not apply) will result in "completed invalid workflow". For a full explanation of how to set up the options and logic surrounding them, see :doc:`../upgrade_scenario_config`.
