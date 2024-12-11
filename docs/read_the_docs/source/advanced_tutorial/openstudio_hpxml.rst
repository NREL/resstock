OpenStudio-HPXML
================

ResStock contains a `git subtree <https://www.atlassian.com/git/tutorials/git-subtree>`_ to the `OpenStudio-HPXML <https://github.com/NREL/OpenStudio-HPXML>`_ repository.
The subtree is located at ``resources/hpxml-measures``, and is basically a direct copy of all the files contained in OpenStudio-HPXML.
As OpenStudio-HPXML is updated, ResStock's ``develop`` branch is periodically updated to point to the ``master`` branch of OpenStudio-HPXML, helping to ensure that ResStock stays up-to-date with OpenStudio-HPXML's development.
It may also be helpful to test an OpenStudio-HPXML branch using a branch of ResStock.
In either case, the subtree at ``resources/hpxml-measures`` can be updated using a set of simple commands.

.. _latest-os-hpxml:

Syncing OpenStudio-HPXML
------------------------

For updating ResStock's ``develop`` branch to point to OpenStudio-HPXML's ``master`` branch, branch off of ``develop`` (e.g., with branch name ``latest-os-hpxml``), and then enter the following command:

.. code:: bash

  $ openstudio tasks.rb update_resources

See :doc:`running_tasks` for more information and context about running tasks.

.. _branch-os-hpxml:

Testing OpenStudio-HPXML
------------------------

For pulling in and testing a specific OpenStudio-HPXML branch, first create a test branch in ResStock. Then enter the following command:

.. code:: bash

  $ git subtree pull --prefix resources/hpxml-measures https://github.com/NREL/OpenStudio-HPXML.git <branch_name> --squash

.. _other-updates:

Other Updates
-------------

After pulling a branch of OpenStudio-HPXML into ResStock, a few additional steps are involved:
- manually edit measures/ResStockArguments/measure.rb and run ``openstudio tasks.rb update_measures`` to force the measure.xml to be regenerated
- update options lookup with any new ResStockArguments arguments
- address any input/output data dictionary updates at ``resources/data/dictionary``
- TODO
