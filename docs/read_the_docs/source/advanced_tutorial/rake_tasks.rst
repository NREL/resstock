Rake Tasks
##########

Once you have completed instructions found in :doc:`installer_setup`, you can then :ref:`use the Rakefile <using-the-rakefile>` contained at the top level of this repository (`Rakefile <https://github.com/NREL/OpenStudio-BuildStock/blob/master/Rakefile>`_). First you will run a rake task for :ref:`copying measures and resource files <copy-residential-files>` from the `OpenStudio-BEopt <https://github.com/NREL/OpenStudio-BEopt>`_) repository into the top-level ``resources/measures`` folder. Then you will run rake task(s) for :ref:`performing integrity checks on project inputs <integrity-checks>`.

.. _using-the-rakefile:

Using the Rakefile
==================

Run ``rake -T`` to see the list of possible rake tasks. The ``-T`` is replaced with the chosen task.

.. code:: ruby

  $ rake -T
  rake integrity_check_all                  # Perform integrity check on inputs...
  rake integrity_check_singlefamilydetached # Perform integrity check on inputs...
  rake integrity_check_multifamily_beta     # Perform integrity check on inputs...
  rake integrity_check_testing              # Perform integrity check on inputs...
  rake test:all                             # Run tests for all
  rake test:regenerate_osms                 # Run tests for regenerate_osms
  rake update_measures                      # update all measures
  rake update_tariffs                       # update urdb tariffs

.. _integrity-checks:

Integrity Checks
================

Run ``rake integrity_check_<project_name>``, where ``<project_name>`` matches the project you are working with. If no rake task exists for the project you are working with, extend the list of integrity check rake tasks to accommodate your project by copy-pasting and renaming the ``integrity_check_singlefamilydetached`` rake task found in the `Rakefile <https://github.com/NREL/OpenStudio-BuildStock/blob/master/Rakefile>`_. An example for running a project's integrity checks is given below:

.. code:: ruby

  $ rake integrity_check_singlefamilydetached
  Checking for issues with project_singlefamilydetached/Location Region...
  Checking for issues with project_singlefamilydetached/Location EPW...
  Checking for issues with project_singlefamilydetached/Vintage...
  Checking for issues with project_singlefamilydetached/Heating Fuel...
  Checking for issues with project_singlefamilydetached/Usage Level...
  ...

If the integrity check for a given project fails, you will need to update either your tsv files and/or the ``resources/options_lookup.tsv`` file. See :doc:`options_lookup` for information about the ``options_lookup.tsv`` file.