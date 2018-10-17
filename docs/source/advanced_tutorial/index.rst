Advanced Tutorial
#################

This advanced tutorial describes the process for developing residential measures on a branch of the `OpenStudio-BEopt <https://github.com/NREL/OpenStudio-BEopt>`_ repository, and subsequently pulling them into the ResStock workflow for creating and testing residential building models. Reasons for wanting to develop residential measures include: customizing any of the existing residential modeling algorithms or adding new technology models.

At this point in the tutorial, it is assumed that you have checked out a new branch that is up-to-date with the **master branch** of the `OpenStudio-BuildStock <https://github.com/NREL/OpenStudio-BuildStock>`_ repository. Optionally, you may have created a new PAT project folder (i.e., copied an existing project folder) and modified the set of tsv files in its ``housing_characteristics`` folder.

If your changes are intended to be merged into the master branch of the `OpenStudio-BuildStock <https://github.com/NREL/OpenStudio-BuildStock>`_ repository, a pull request review is required.

.. toctree::

   modifying_probability_distributions
   installer_setup
   rake_tasks
   options_lookup
   updating_projects
   debugging
