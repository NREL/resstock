Run the Project
===============

See the `buildstockbatch documentation <https://nrel.github.io/buildstockbatch>`_ for information on running projects (large-scale).

You also have the option of testing (small-scale) the ResStock workflow using an integration test file. For example:

.. code:: ruby

  $ /c/openstudio-3-2-1/bin/openstudio.exe test/test_samples.rb

The previous command samples from both the ``project_national`` and ``project_testing`` projects and runs simulations using baseline and upgrade `workflows <https://github.com/NREL/resstock/tree/develop/test/test_samples_osw>`_.