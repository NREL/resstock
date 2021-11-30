Increasing Upgrade Options
##########################

To allow more options per upgrade, increase the value returned by the following method defined in ``resources/measures/HPXMLtoOpenStudio/resources/constants.rb``:

.. code::

  def self.NumApplyUpgradeOptions
    return 25
  end
  
Then run the ``update_measures`` rake task. See :doc:`rake_tasks` for instructions on how to run rake tasks.

Then you will need to update the outputs section for all PAT projects. See :doc:`updating_projects` for instructions on how to update projects.