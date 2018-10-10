Rake Tasks
##########

Once you have completed instructions found in :doc:`installer_setup`, you can then :ref:`use the Rakefile <using-the-rakefile>` contained at the top level of this repository (`Rakefile <https://github.com/NREL/OpenStudio-BuildStock/blob/master/Rakefile>`_). First you will run a rake task for :ref:`copying measures and resource files <copy-residential-files>` from the `OpenStudio-BEopt <https://github.com/NREL/OpenStudio-BEopt>`_) repository into the top-level ``resources/measures`` folder. Then you will run rake task(s) for :ref:`performing integrity checks on project inputs <integrity-checks>`.

.. _using-the-rakefile:

Using the Rakefile
==================

Run ``bundle exec rake -T`` to see the list of possible rake tasks. The ``-T`` is replaced with the chosen task.

.. code:: ruby

  $ bundle exec rake -T
  rake copy_beopt_files                   # Copy files from Openstudio-BEopt ...
  rake download_and_copy_beopt_files      # Download and copy files from Open...
  rake integrity_check_all                # Perform integrity check on inputs...
  rake integrity_check_resstock_comed     # Perform integrity check on inputs...
  rake integrity_check_resstock_efs       # Perform integrity check on inputs...
  rake integrity_check_resstock_national  # Perform integrity check on inputs...
  rake integrity_check_resstock_pnw       # Perform integrity check on inputs...
  rake integrity_check_resstock_testing   # Perform integrity check on inputs...
  rake test:all                           # Run tests for all
  rake test:regenerate_osms               # regenerate SimulationOutputReport...

.. _copy-residential-files:

Copying Residential Files
=========================

To copy a set of residential measures and resource files to this repository's ``resources/measures`` folder, run ``bundle exec rake download_and_copy_beopt_files``. You will be prompted to supply the branch name containing the set of residential measures of interest.

.. code:: ruby

  $ bundle exec rake download_and_copy_beopt_files
  Enter branch of repo(<ENTER> for master):
  <branch_name>

If you get any SSL or otherwise -related errors preventing your branch download, use an Internet browser to manually download the desired branch zip file (``https://codeload.github.com/NREL/OpenStudio-BEopt/zip/<branch_name>``). Move the downloaded zip file into the top level of this repository. Then run ``bundle exec rake copy_beopt_files``. You will not be prompted to supply a branch name.

Be sure to delete the zip file once all files have been extracted and copied.

.. _integrity-checks:

Integrity Checks
================

Run ``bundle exec rake integrity_check_resstock_<project_name>``, where ``<project_name>`` matches the project you are working with. If no rake task exists for the project you are working with, extend the list of integrity check rake tasks to accommodate your project by copying-pasting and renaming, e.g., `the integrity_check_resstock_national rake task <https://github.com/NREL/OpenStudio-BuildStock/blob/master/Rakefile#L272-L276>`_. An example for running a project's integrity checks is given below:

.. code:: ruby

  $ bundle exec rake integrity_check_resstock_national
  Checking for issues with project_resstock_national/Location Region...
  Checking for issues with project_resstock_national/Location EPW...
  Checking for issues with project_resstock_national/Vintage...
  Checking for issues with project_resstock_national/Heating Fuel...
  Checking for issues with project_resstock_national/Usage Level...

If the integrity check for a given project fails, you will need to update either your tsv files and/or the ``resources/options_lookup.tsv`` file. See :doc:`options_lookup` for information about the ``options_lookup.tsv`` file.