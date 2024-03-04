.. _dwelling-unit-counts:

Dwelling unit counts of the U.S. residential building stock
===========================================================
ResStock uses data from the U.S. Census American Community Survery (ACS) to specify the number of dwelling units in the U.S. 
These estimates include both occupied and vacant dwellings. 
The data comes from the ACS `Table B25001 <https://data.census.gov/table/ACSDT5Y2022.B25001?q=B25001>`_.

These data can be used in project files 
(like the `national_baseline.yml <https://github.com/NREL/resstock/blob/develop/project_national/national_baseline.yml>`_)
to specify the ``n_buildings_represented`` variable.

.. note::

 If you want to use state level unit counts, the proper downselect logic must be used in the ``sampler`` block of the project file.

.. literalinclude:: .gemrc

.. _dwelling_unit_count_table:

.. csv-table:: Dwelling unit counts from ACS Table B25001.
   :file: CensusTableB25001-dwelling_unit_counts.csv
   :widths: 30, 15, 15, 15, 15, 15
   :header-rows: 1
