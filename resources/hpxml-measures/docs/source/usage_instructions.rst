.. _usage_instructions:

Usage Instructions
==================

Setup
-----

To get started:

#. Download `OpenStudio 3.7.0 <https://github.com/NREL/OpenStudio/releases/tag/v3.7.0>`_ and install the Command Line Interface/EnergyPlus/C++ API components, or use the `nrel/openstudio docker image <https://hub.docker.com/r/nrel/openstudio>`_.
#. Download the `latest release <https://github.com/NREL/OpenStudio-HPXML/releases>`_.

Running
-------

To programatically run simulations, it's recommended to use the OpenStudio `Command Line Interface <http://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/>`_.
Two general approaches (basic and advanced) for running via the CLI are described below.
The OpenStudio measures can also be run from user interfaces (e.g., the OpenStudio Application or OpenStudio Parametric Analysis Tool (PAT)).

.. note::

  If the ``openstudio`` command is not found, it's because the executable is not in your PATH. Either add the executable to your PATH or point directly to the executable found in the openstudio-X.X.X/bin directory.

Basic Run
~~~~~~~~~

| The simplest and fastest method is to call the OpenStudio CLI with the provided ``workflow/run_simulation.rb`` script. For example:
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml``
| This will create a "run" directory with all input/output files. By default it will be found at the same location as the input HPXML file.

You can also request generation of timeseries output CSV/JSON/MessagePack files as part of the calculation by providing one or more timeseries flags (``--hourly``, ``--daily``, ``--monthly``, or ``--timestep``).

| For example, to request all possible hourly outputs in CSV format:
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml --hourly ALL``
| Or to request one or more specific monthly output types in JSON format:
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml --monthly fuels --monthly temperatures --output-format json``

| You can also add a detailed schedule as part of the simulation by using:
| ``openstudio workflow/run_simulation.rb -x workflow/sample_files/base.xml --add-stochastic-schedules``
| This run includes the automatic generation of a CSV file with stochastic occupancy schedules that are used in the EnergyPlus simulation.

Run ``openstudio workflow/run_simulation.rb -h`` to see all available commands/arguments.

Advanced Run
~~~~~~~~~~~~
 
If additional flexibility is desired (e.g., specifying individual measure arguments, including additional OpenStudio measures to run alongside this measure in a workflow, etc.), create an `OpenStudio Workflow (OSW) <https://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/#osw-structure>`_ file.
The OSW is a JSON file that will specify all the OpenStudio measures (and their arguments) to be run sequentially.
A template OSW that simply runs the HPXMLtoOpenStudio, ReportSimulationOutput, and ReportUtilityBills measures on the ``workflow/sample_files/base.xml`` file can be found at ``workflow/template-run-hpxml.osw``.

| For example:
| ``openstudio run -w workflow/template-run-hpxml.osw``
| This will create a "run" directory with all input/output files. By default it will be found at the same location as the OSW file.

| Another example:
| ``openstudio run -w workflow/template-run-hpxml-with-stochastic-occupancy.osw``
| ``openstudio run -w workflow/template-run-hpxml-with-stochastic-occupancy-subset.osw``
| This workflow automatically generates and uses a CSV file with stochastic occupancy schedules (either with all possible columns or a user-specified subset of columns) before running the EnergyPlus simulation.

| And another example:
| ``openstudio run -w workflow/template-build-and-run-hpxml-with-stochastic-occupancy.osw``
| This workflow builds an HPXML file on the fly from building description inputs in the OSW, then automatically generates and uses a CSV file with stochastic occupancy schedules, and finally runs the EnergyPlus simulation.

Outputs
~~~~~~~

A variety of high-level annual outputs are conveniently reported in the resulting ``run/results_annual.csv`` (or ``run/results_annual.json`` or ``run/results_annual.msgpack``) file.

When timeseries outputs are requested, they will be found in the ``run/results_timeseries.csv`` (or ``run/results_timeseries.json`` or ``run/results_timeseries.msgpack``) file.

See :ref:`workflow_outputs` for a description of all available outputs available.
