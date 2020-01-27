Getting Started
===============

Setup
-----

To get started:

#. Download `OpenStudio 2.9.1 <https://github.com/NREL/OpenStudio/releases/tag/v2.9.1>`_ and install the Command Line Interface/EnergyPlus components, or use the `nrel/openstudio docker image <https://hub.docker.com/r/nrel/openstudio>`_.
#. Download the OpenStudio-HPXML measure.

Running
-------

To programatically run simulations, it's recommended to use the OpenStudio `Command Line Interface <http://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/>`_.
Two general approaches (basic and advanced) for running via the CLI are described below.

Note that the OpenStudio measure can also be run from user interfaces (e.g., the `OpenStudio Application <http://nrel.github.io/OpenStudio-user-documentation/reference/openstudio_application_interface/>`_ or `Parametric Analysis Tool <http://nrel.github.io/OpenStudio-user-documentation/reference/parametric_analysis_tool_2/>`_).

.. note:: 

  If the ``openstudio`` command is not found, it's because the executable is not in your PATH. Either add the executable to your PATH or point directly to the executable found in the openstudio-X.X.X/bin directory.

Basic Run
~~~~~~~~~

The simplest and fastest method is to call the OpenStudio CLI with the provided `resources/run_simulation.rb <https://github.com/NREL/OpenStudio-HPXML/blob/master/resources/run_simulation.rb>`_ script.

For example:
``openstudio resources/run_simulation.rb -x tests/base.xml``

This will create a "run" directory with all input/output files.
By default it will be found at the same location as the input HPXML file, though it can be changed.
Run ``openstudio resources/run_simulation.rb -h`` to see all available commands/arguments.

Advanced Run
~~~~~~~~~~~~
 
If additional flexibility is desired (e.g., specifying individual measure arguments, including additional OpenStudio measures to run alongside this measure in a workflow, etc.), create an `OpenStudio Workflow (OSW) <https://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/#osw-structure>`_ file.
The OSW is a JSON file that will specify all the OpenStudio measures (and their arguments) to be run sequentially.
A template OSW that simply runs this measure on the tests/base.xml can be found at `resources/template.osw <https://github.com/NREL/OpenStudio-HPXML/blob/master/resources/template.osw>`_.

For example:
``openstudio run -w resources/template.osw``

This will create a "run" directory with all input/output files.
By default it will be found at the same location as the OSW file, though it can be changed in the OSW file.
