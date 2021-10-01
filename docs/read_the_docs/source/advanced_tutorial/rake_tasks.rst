Rake Tasks
##########

Once you have completed instructions found in :doc:`installer_setup`, you can then :ref:`use the Rakefile <using-the-rakefile>` contained at the top level of this repository (`Rakefile <https://github.com/NREL/resstock/blob/develop/Rakefile>`_). You will run rake task(s) for :ref:`performing integrity checks on project inputs <integrity-checks>`.

.. _using-the-rakefile:

Using the Rakefile
==================

Run ``rake -T`` to see the list of possible rake tasks. The ``-T`` is replaced with the chosen task.

.. code:: ruby

  $ rake -T
  rake unit_tests:integrity_check_tests     # Run tests for integrity_check_t...
  rake unit_tests:measure_tests             # Run tests for measure_tests
  rake unit_tests:project_integrity_checks  # Run tests for project_integrity...
  rake workflow:analysis_tests              # Run tests for analysis_tests

.. _integrity-checks:

Integrity Checks
================

Run ``rake integrity_check_<project_name>``, where ``<project_name>`` matches the project you are working with. If no rake task exists for the project you are working with, extend the list of integrity check rake tasks to accommodate your project by copy-pasting and renaming the ``integrity_check_national`` rake task found in the `Rakefile <https://github.com/NREL/resstock/blob/develop/Rakefile>`_. An example for running a project's integrity checks is given below:

.. code:: ruby

  $ rake integrity_check_national
  Checking for issues with project_national/Location Region...
  Checking for issues with project_national/Location EPW...
  Checking for issues with project_national/Vintage...
  Checking for issues with project_national/Heating Fuel...
  Checking for issues with project_national/Usage Level...
  ...

If the integrity check for a given project fails, you will need to update either your tsv files and/or the ``resources/options_lookup.tsv`` file. See :doc:`options_lookup` for information about the ``options_lookup.tsv`` file.