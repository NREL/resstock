Rake Tasks
##########

Once you have completed instructions found in :doc:`installer_setup`, you can then :ref:`use the Rakefile <using-the-rakefile>` contained at the top level of this repository (`Rakefile <https://github.com/NREL/OpenStudio-BuildStock/blob/master/Rakefile>`_). You will run rake task(s) for :ref:`performing integrity checks on project inputs <integrity-checks>`.

.. _using-the-rakefile:

Using the Rakefile
==================

Run ``rake -T`` to see the list of possible rake tasks. The ``-T`` is replaced with the chosen task.

.. code:: ruby

  $ rake -T
  rake integrity_check_all                   # Run tests for integrity_check_all
  rake integrity_check_multifamily_beta      # Run tests for integrity_check_...
  rake integrity_check_testing               # Run tests for integrity_check_...
  rake integrity_check_unit_tests            # Run tests for integrity_check_...
  rake test:measures_osw                     # Run tests for measures_osw
  rake test:regenerate_osms                  # Run tests for regenerate_osms
  rake test:regression_tests                 # Run tests for regression_tests
  rake test:unit_tests                       # Run tests for unit_tests
  rake update_measures                       # Run tests for update_measures

.. _integrity-checks:

Integrity Checks
================

Run ``rake integrity_check_<project_name>``, where ``<project_name>`` matches the project you are working with. If no rake task exists for the project you are working with, extend the list of integrity check rake tasks to accommodate your project by copy-pasting and renaming the ``integrity_check_multifamily_beta`` rake task found in the `Rakefile <https://github.com/NREL/OpenStudio-BuildStock/blob/master/Rakefile>`_. An example for running a project's integrity checks is given below:

.. code:: ruby

  $ rake integrity_check_multifamily_beta
  Checking for issues with project_multifamily_beta/Location Region...
  Checking for issues with project_multifamily_beta/Location EPW...
  Checking for issues with project_multifamily_beta/Vintage...
  Checking for issues with project_multifamily_beta/Heating Fuel...
  Checking for issues with project_multifamily_beta/Usage Level...
  ...

If the integrity check for a given project fails, you will need to update either your tsv files and/or the ``resources/options_lookup.tsv`` file. See :doc:`options_lookup` for information about the ``options_lookup.tsv`` file.