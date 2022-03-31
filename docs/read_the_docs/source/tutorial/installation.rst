Installation
============

.. note::
  Most people who use ResStock for analysis do so by using the datasets published to the `ResStock Data Viewer <https://resstock.nrel.gov>`_. These datasets are often the best choice because they are a verified run that can be referenced. Datasets with upgrade scenario results will be made available over time. For more complicated analyses including custom upgrade scenarios, the source code of ResStock and this documentation page is available to run your own simulations. However, running ResStock can be a complicated affair and can require a lot of computing resources. Running on Amazon Web Services requires some technical knowledge of cloud computing to deploy. Unfortunately, we don’t have the resources to provide technical support if you choose this route.

Download ResStock
-----------------

There are two options for downloading `ResStock <https://github.com/NREL/resstock>`_:

1. download a released version
2. clone the repository

For the first option, go to the `releases page <https://github.com/NREL/resstock/releases>`_ on GitHub and select a release. Note the OpenStudio version requirements associated with each version of ResStock. For example, ResStock v2.4.0 requires that you have OpenStudio v2.9.0 installed.

For the second option, you will need to have `Git <https://git-scm.com>`_ or some other Git-based tool installed. Cloning the ResStock repository gives you access to the ``develop`` branch of ResStock. The ``develop`` branch is under active development.

.. note::

  If you are planning to perform large-scale runs on ResStock (greater than 1000 simulations) or analyze timeseries data, you will need to use :ref:`buildstockbatch` to run and manage batch simulations of ResStock.
  Buildstockbatch can be run locally via Docker, on AWS, or on an HPC like NREL’s Eagle.
  Installation instructions can be found in buildstockbatch’s `installation documentation <https://buildstockbatch.readthedocs.io/en/latest/installation.html>`_.

  If you are planning to perform small-scale runs of ResStock (1000 simulations or fewer), you can use the lighter-weight option of running locally via :ref:`run_analysis`.

Install OpenStudio
------------------

Download the version of OpenStudio software (corresponding to the ResStock version that has been selected) from the `OpenStudio developer website <https://www.openstudio.net/developers>`_.

Developer instructions
----------------------

If you will be developing residential measures and testing residential building models, see the :ref:`advanced_tutorial`. If you are a developer, make sure that you have checked out the ``develop`` branch of the repository.
