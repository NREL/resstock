Run the Project
===============

Run using buildstockbatch
-------------------------

See the `buildstockbatch documentation <https://nrel.github.io/buildstockbatch>`_ for information on running projects (large-scale).

Run locally
-----------

You also have the option of running (small-scale) projects using the OpenStudio `Command Line Interface <http://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/>`_ (CLI).

.. note:: 

  If the ``openstudio`` command is not found, it's because the executable is not in your PATH. Either add the executable to your PATH or point directly to the executable found in the openstudio-X.X.X/bin directory.

Call the OpenStudio CLI with the provided ``workflow/run_analysis.rb`` script.
For example:
``openstudio workflow/run_analysis.rb -y project_testing/testing_baseline.yml``
The previous command samples from ``project_testing`` and runs simulations using baseline workflows generated from the specified yml file.
An "output directory" (as specified in the yml file) is created with all ``measures.osw`` files, optional ``measures-upgrade.osw`` files, and simulation results.

You can also request that only measures are applied (i.e., no simulations are run) using the ``--measures_only`` flag.
For example:
``openstudio workflow/run_analysis.rb -y project_testing/testing_baseline.yml -m``

Run ``openstudio workflow/run_analysis.rb -h`` to see all available commands/arguments.

.. note::
  At this time the ``residential_quota_downselect`` sampler with ``resample`` is not supported.