.. _housing_characteristics:

Housing Characteristics
=======================

Each parameter sampled by the national project is listed alphabetically as its own subsection below.
For each parameter, the following (if applicable) are reported based on the contents of the `source_report.csv <https://github.com/NREL/resstock/blob/develop/project_national/resources/source_report.csv>`_:

- **Description**
- **Created by**
- **Source**
- **Assumption**

Additionally, for each parameter an **Arguments** table is populated (if applicable) based on the contents of `ResStockArguments <https://github.com/NREL/resstock/blob/develop/measures/ResStockArguments>`_ and `BuildResidentialHPXML <https://github.com/NREL/resstock/blob/develop/resources/hpxml-measures/BuildResidentialHPXML>`_ measure.xml files.

- **Name** [#]_
- **Required** [#]_
- **Units**
- **Type** [#]_
- **Choices**
- **Description**

.. [#] Each **Name** entry is an argument that is assigned using defined options from the `options_lookup.tsv <https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv>`_.
.. [#] May be "true" or "false".
.. [#] May be "String", "Double", "Integer", "Boolean", or "Choice".

Furthermore, all *optional* Choice arguments include "auto" as one of the possible **Choices**.
Most *optional* String/Double/Integer/Boolean arguments can also be assigned a value of "auto" (e.g., ``site_ground_conductivity``).
Assigning "auto" means that downstream OS-HPXML default values (if applicable) will be used.
When applicable, the **Description** field will include link(s) to `OpenStudio-HPXML documentation <https://openstudio-hpxml.readthedocs.io/en/latest/?badge=latest>`_ describing these default values.

.. _ahs_region:

AHS Region
----------

Description
***********

The American Housing Survey region that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Core Based Statistical Area (CBSA) data based on the Feb 2013 CBSA delineation file.


.. _aiannh_area:

AIANNH Area
-----------

Description
***********

American Indian/Alaska Native/Native Hawaiian Area that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \2010 Census Tract to American Indian Area (AIA) Relationship File provides percent housing unit in tract that belongs to AIA.Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


Assumption
**********

- \(2010) Tract is mapped to (2015) County and PUMA by adjusting for known geographic changes (e.g., renaming of Shannon County to Oglala Lakota County, SD) However, Tract=G3600530940103 (Oneida city, Madison County, NY) could not be mapped to County and PUMA and was removed. The tract contains only 11 units for AIA.


.. _ashrae_iecc_climate_zone_2004:

ASHRAE IECC Climate Zone 2004
-----------------------------

Description
***********

Climate zone according to ASHRAE 169 in 2004 and IECC in 2012 that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Climate zone data are from ASHRAE 169 2006, IECC 2012, and M.C. Baechler 2015.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``site_type``
     - false
     - 
     - Choice
     - "auto", "suburban", "urban", "rural"
     - The type of site. If not provided, the OS-HPXML default (see `HPXML Site <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-site>`_) is used.
   * - ``site_ground_conductivity``
     - false
     - Btu/hr-ft-F
     - Double
     - "auto"
     - Conductivity of the ground soil. If not provided, the OS-HPXML default (see `HPXML Site <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-site>`_) is used.
   * - ``site_iecc_zone``
     - false
     - 
     - Choice
     - "auto", "1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C", "4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", "8"
     - IECC zone of the home address.

.. _ashrae_iecc_climate_zone_2004___2_a_split:

ASHRAE IECC Climate Zone 2004 - 2A Split
----------------------------------------

Description
***********

Climate zone according to ASHRAE 169 in 2004 and IECC in 2012 that the sample is located. Climate zone where climate zone 2A is split between counties in TX, LA and FL, GA, AL, and MS

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Climate zone data are from ASHRAE 169 2006, IECC 2012, and M.C. Baechler 2015.


Assumption
**********

- \This characteristic is used to better represent HVAC types in the 2A climate zone.


.. _area_median_income:

Area Median Income
------------------

Description
***********

Area median income of the household occupying the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \% Area Median Income is calculated using annual household income in 2019USD (continuous, not binned) from 2019-5yrs PUMS data and 2019 Income Limits from HUD. These limits adjust for household size AND local housing costs (AKA Fair Market Rents). Income Limits reported at county subdivisions are consolidated to County using a crosswalk generated from Missouri Census Data Center's geocorr (2014), which has 2010 ACS housing unit count. For the 478 counties available in PUMS (60%), the county-level Income Limits are used. For all others (40%), PUMA-level Income Limits are used, which are converted from county-level using the spatial_tract_lookup file containing 2010 ACS housing unit count.


.. _bathroom_spot_vent_hour:

Bathroom Spot Vent Hour
-----------------------

Description
***********

Bathroom spot ventilation daily start hour

Created by
**********

manually created

Source
******

- \Same as occupancy schedule from Wilson et al. 'Building America House Simulation Protocols' 2014


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``bathroom_fans_quantity``
     - false
     - #
     - Integer
     - "auto"
     - The quantity of the bathroom fans. If not provided, the OS-HPXML default (see `Local Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#local-ventilation-fan>`_) is used.
   * - ``bathroom_fans_flow_rate``
     - false
     - CFM
     - Double
     - "auto"
     - The flow rate of the bathroom fans. If not provided, the OS-HPXML default (see `Local Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#local-ventilation-fan>`_) is used.
   * - ``bathroom_fans_hours_in_operation``
     - false
     - hrs/day
     - Double
     - "auto"
     - The hours in operation of the bathroom fans. If not provided, the OS-HPXML default (see `Local Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#local-ventilation-fan>`_) is used.
   * - ``bathroom_fans_power``
     - false
     - W
     - Double
     - "auto"
     - The fan power of the bathroom fans. If not provided, the OS-HPXML default (see `Local Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#local-ventilation-fan>`_) is used.
   * - ``bathroom_fans_start_hour``
     - false
     - hr
     - Integer
     - "auto"
     - The start hour of the bathroom fans. If not provided, the OS-HPXML default (see `Local Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#local-ventilation-fan>`_) is used.

.. _battery:

Battery
-------

Description
***********

The presence, size, location, and efficiency of an onsite battery (not modeled in project_national).

Created by
**********

manually created

Source
******

- \n/a


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``battery_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a lithium ion battery present.
   * - ``battery_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "crawlspace", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "attic", "attic - vented", "attic - unvented", "garage", "outside"
     - The space type for the lithium ion battery location. If not provided, the OS-HPXML default (see `HPXML Batteries <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-batteries>`_) is used.
   * - ``battery_power``
     - false
     - W
     - Double
     - "auto"
     - The rated power output of the lithium ion battery. If not provided, the OS-HPXML default (see `HPXML Batteries <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-batteries>`_) is used.
   * - ``battery_capacity``
     - false
     - kWh
     - Double
     - "auto"
     - The nominal capacity of the lithium ion battery. If not provided, the OS-HPXML default (see `HPXML Batteries <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-batteries>`_) is used.
   * - ``battery_usable_capacity``
     - false
     - kWh
     - Double
     - "auto"
     - The usable capacity of the lithium ion battery. If not provided, the OS-HPXML default (see `HPXML Batteries <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-batteries>`_) is used.
   * - ``battery_round_trip_efficiency``
     - false
     - Frac
     - Double
     - "auto"
     - The round trip efficiency of the lithium ion battery. If not provided, the OS-HPXML default (see `HPXML Batteries <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-batteries>`_) is used.

.. _bedrooms:

Bedrooms
--------

Description
***********

The number of bedrooms in the dwelling unit.

Created by
**********

``sources/ahs/ahs2017_2019/tsv_maker.py``

Source
******

- \2017 and 2019 American Housing Survey (AHS) microdata.

- \Building type categorization based on U.S. EIA 2009 Residential Energy Consumption Survey (RECS).


Assumption
**********

- \More than 5 bedrooms are labeled as 5 bedrooms and 0 bedrooms are labeled as 1 bedroom

- \Limit 0-499 sqft dwelling units to only 1 or 2 bedrooms. The geometry measure has a limit of (ffa-120)/70 >= bedrooms.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_unit_num_bedrooms``
     - true
     - #
     - Integer
     -
     - The number of bedrooms in the unit.
   * - ``geometry_unit_num_bathrooms``
     - false
     - #
     - Integer
     - "auto"
     - The number of bathrooms in the unit. If not provided, the OS-HPXML default (see `HPXML Building Construction <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-building-construction>`_) is used.

.. _building_america_climate_zone:

Building America Climate Zone
-----------------------------

Description
***********

The Building America Climate Zone that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Spatial definitions are from U.S. Census 2010.

- \Climate zone data are from ASHRAE 169 2006, IECC 2012, and M.C. Baechler 2015.


.. _cec_climate_zone:

CEC Climate Zone
----------------

Description
***********

The California Energy Commission Climate Zone that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Zip code definitions are from the end of Q2 2020

- \The climate zone to zip codes in California is from the California Energy Commission Website.


Assumption
**********

- \CEC Climate zones are defined by Zip Codes.

- \The dependency selected is County and PUMA as zip codes are not modeled in ResStock.

- \The mapping between Census Tracts and Zip Codes are approximate and some discrepancies may exist.

- \If the sample is outside California, the option is set to None.


.. _ceiling_fan:

Ceiling Fan
-----------

Description
***********

Presence and energy usage of ceiling fans at medium speed

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average used as saturation


Assumption
**********

- \If the unit is vacant there is no ceiling fan energy


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``ceiling_fan_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there are any ceiling fans.
   * - ``ceiling_fan_efficiency``
     - false
     - CFM/W
     - Double
     - "auto"
     - The efficiency rating of the ceiling fan(s) at medium speed. If not provided, the OS-HPXML default (see `HPXML Ceiling Fans <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-ceiling-fans>`_) is used.
   * - ``ceiling_fan_quantity``
     - false
     - #
     - Integer
     - "auto"
     - Total number of ceiling fans. If not provided, the OS-HPXML default (see `HPXML Ceiling Fans <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-ceiling-fans>`_) is used.
   * - ``ceiling_fan_cooling_setpoint_temp_offset``
     - false
     - deg-F
     - Double
     - "auto"
     - The cooling setpoint temperature offset during months when the ceiling fans are operating. Only applies if ceiling fan quantity is greater than zero. If not provided, the OS-HPXML default (see `HPXML Ceiling Fans <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-ceiling-fans>`_) is used.

.. _census_division:

Census Division
---------------

Description
***********

The U.S. Census Division that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


.. _census_division_recs:

Census Division RECS
--------------------

Description
***********

Census Division as used in RECS 2015 that the sample is located. RECS 2015 splits the Mountain Census Division into north (CO, ID, MT, UT, WY) and south (AZ, NM, NV).

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \U.S. EIA 2015 Residential Energy Consumption Survey (RECS) codebook.


.. _census_region:

Census Region
-------------

Description
***********

The U.S. Census Region that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


.. _city:

City
----

Description
***********

The City that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Cities are defined by Census blocks by their Census Place in the 2010 Census.

- \Unit counts are from the American Community Survey 5-yr 2016.


Assumption
**********

- \2020 Deccenial Redistricting data was used to map tract level unit counts to census blocks.

- \1,099 cities are tagged in ResStock, but there are over 29,000 Places in the Census data.

- \The threshold for including a Census Place in the City.tsv is 15,000 dwelling units.

- \The value 'In another census Place' designates the fraction of dwelling units in a Census Place with fewer total dwelling units than the threshold.

- \The value 'Not in a census Place' designates the fraction of dwelling units not in a Census Place according to the 2010 Census.


.. _clothes_dryer:

Clothes Dryer
-------------

Description
***********

The presence, rated efficiency, and fuel type of the clothes dryer in a dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Clothes dryer option is None if clothes washer not presentDue to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv :deps=['Geometry Building Type RECS', 'State', 'Heating Fuel', 'Clothes Washer Presence'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS without AK, HI

  - \[2] Heating Fuel coarsened to Other Fuel and Propane combined

  - \[3] Heating Fuel coarsened to Fuel Oil, Other Fuel, and Propane combined

  - \[4] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[5] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[6] State coarsened to Census Division RECS

  - \[7] State coarsened to Census Region

  - \[8] State coarsened to National

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS without AK, HI

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] State coarsened to Census Division RECS

  - \[7] State coarsened to Census Region

  - \[8] State coarsened to National

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Heating Fuel','Clothers Washer Presence'], ['Tenure', 'Federal Poverty Level']).


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``clothes_dryer_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a clothes dryer present.
   * - ``clothes_dryer_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space"
     - The space type for the clothes dryer location. If not provided, the OS-HPXML default (see `HPXML Clothes Dryer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-dryer>`_) is used.
   * - ``clothes_dryer_fuel_type``
     - true
     - 
     - Choice
     - "electricity", "natural gas", "fuel oil", "propane", "wood", "coal"
     - Type of fuel used by the clothes dryer.
   * - ``clothes_dryer_efficiency_type``
     - true
     - 
     - Choice
     - "EnergyFactor", "CombinedEnergyFactor"
     - The efficiency type of the clothes dryer.
   * - ``clothes_dryer_efficiency``
     - false
     - lb/kWh
     - Double
     - "auto"
     - The efficiency of the clothes dryer. If not provided, the OS-HPXML default (see `HPXML Clothes Dryer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-dryer>`_) is used.
   * - ``clothes_dryer_vented_flow_rate``
     - false
     - CFM
     - Double
     - "auto"
     - The exhaust flow rate of the vented clothes dryer. If not provided, the OS-HPXML default (see `HPXML Clothes Dryer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-dryer>`_) is used.

.. _clothes_dryer_usage_level:

Clothes Dryer Usage Level
-------------------------

Description
***********

Clothes dryer energy usage level multiplier.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Assumption
**********

- \Engineering judgement


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``clothes_dryer_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the clothes dryer energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Clothes Dryer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-dryer>`_) is used.

.. _clothes_washer:

Clothes Washer
--------------

Description
***********

Presence and rated efficiency of the clothes washer.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \The 2020 recs survey does not contain EnergyStar rating of clothes washers.Energystar efficiency distributions with [Geometry Building Type,Federal Poverty Level, Tenure] as dependencies are imported from RECS 2009Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State','Clothes Washer Presence', 'Vintage'] with the following fallback coarsening order

  - \[1] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[2] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[3] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently

  - \[4] Vintage homes built before 1960 coarsened to pre1960

  - \[5] Vintage homes built after 2000 coarsened to 2000-20

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[2] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[3] Federal Poverty Level coarsened every 100 percent

  - \[4] Federal Poverty Level coarsened every 200 percent

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Clothes Washer Presence', 'Vintage'], ['Tenure', 'Federal Poverty Level']).


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``clothes_washer_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space"
     - The space type for the clothes washer location. If not provided, the OS-HPXML default (see `HPXML Clothes Washer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-washer>`_) is used.
   * - ``clothes_washer_efficiency_type``
     - true
     - 
     - Choice
     - "ModifiedEnergyFactor", "IntegratedModifiedEnergyFactor"
     - The efficiency type of the clothes washer.
   * - ``clothes_washer_efficiency``
     - false
     - ft^3/kWh-cyc
     - Double
     - "auto"
     - The efficiency of the clothes washer. If not provided, the OS-HPXML default (see `HPXML Clothes Washer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-washer>`_) is used.
   * - ``clothes_washer_rated_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating. If not provided, the OS-HPXML default (see `HPXML Clothes Washer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-washer>`_) is used.
   * - ``clothes_washer_label_electric_rate``
     - false
     - $/kWh
     - Double
     - "auto"
     - The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating. If not provided, the OS-HPXML default (see `HPXML Clothes Washer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-washer>`_) is used.
   * - ``clothes_washer_label_gas_rate``
     - false
     - $/therm
     - Double
     - "auto"
     - The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating. If not provided, the OS-HPXML default (see `HPXML Clothes Washer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-washer>`_) is used.
   * - ``clothes_washer_label_annual_gas_cost``
     - false
     - $
     - Double
     - "auto"
     - The annual cost of using the system under test conditions. Input is obtained from the EnergyGuide label. If not provided, the OS-HPXML default (see `HPXML Clothes Washer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-washer>`_) is used.
   * - ``clothes_washer_label_usage``
     - false
     - cyc/wk
     - Double
     - "auto"
     - The clothes washer loads per week. If not provided, the OS-HPXML default (see `HPXML Clothes Washer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-washer>`_) is used.
   * - ``clothes_washer_capacity``
     - false
     - ft^3
     - Double
     - "auto"
     - Volume of the washer drum. Obtained from the EnergyStar website or the manufacturer's literature. If not provided, the OS-HPXML default (see `HPXML Clothes Washer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-washer>`_) is used.

.. _clothes_washer_presence:

Clothes Washer Presence
-----------------------

Description
***********

The presence of a clothes washer in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Heating Fuel', 'Vintage'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently

  - \[5] Vintage homes built before 1960 coarsened to pre1960

  - \[6] Vintage homes built after 2000 coarsened to 2000-20

  - \[7] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[8] Census Division RECS to Census Region

  - \[9] Census Region to National

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Geometry Building Type RECS', 'Vintage'], ['Tenure', 'Federal Poverty Level']).


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``clothes_washer_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a clothes washer present.

.. _clothes_washer_usage_level:

Clothes Washer Usage Level
--------------------------

Description
***********

Clothes washer energy usage level multiplier.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Assumption
**********

- \Engineering judgement


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``clothes_washer_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the clothes washer energy and hot water usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Clothes Washer <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-clothes-washer>`_) is used.

.. _cooking_range:

Cooking Range
-------------

Description
***********

Presence and fuel type of the cooking range.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For Dual Fuel Range the distribution is split equally between Electric and Natural GasDue to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Heating Fuel', 'Vintage'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Heating Fuel coarsened to Other Fuel and Propane combined

  - \[3] Heating Fuel coarsened to Fuel Oil, Other Fuel, and Propane combined

  - \[4] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[5] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[6] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently

  - \[7] Vintage homes built before 1960 coarsened to pre1960

  - \[8] Vintage homes built after 2000 coarsened to 2000-20

  - \[9] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[10] Census Division RECS to Census Region

  - \[11] Census Region to National

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Heating Fuel', 'Vintage'], ['Tenure', 'Federal Poverty Level']).


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``cooking_range_oven_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a cooking range/oven present.
   * - ``cooking_range_oven_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space"
     - The space type for the cooking range/oven location. If not provided, the OS-HPXML default (see `HPXML Cooking Range/Oven <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-cooking-range-oven>`_) is used.
   * - ``cooking_range_oven_fuel_type``
     - true
     - 
     - Choice
     - "electricity", "natural gas", "fuel oil", "propane", "wood", "coal"
     - Type of fuel used by the cooking range/oven.
   * - ``cooking_range_oven_is_induction``
     - false
     - 
     - Boolean
     - "auto", "true", "false"
     - Whether the cooking range is induction. If not provided, the OS-HPXML default (see `HPXML Cooking Range/Oven <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-cooking-range-oven>`_) is used.
   * - ``cooking_range_oven_is_convection``
     - false
     - 
     - Boolean
     - "auto", "true", "false"
     - Whether the oven is convection. If not provided, the OS-HPXML default (see `HPXML Cooking Range/Oven <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-cooking-range-oven>`_) is used.

.. _cooking_range_usage_level:

Cooking Range Usage Level
-------------------------

Description
***********

Cooling range energy usage level multiplier.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Assumption
**********

- \Engineering judgement


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``cooking_range_oven_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the cooking range/oven energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Cooking Range/Oven <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-cooking-range-oven>`_) is used.

.. _cooling_setpoint:

Cooling Setpoint
----------------

Description
***********

Baseline cooling setpoint with no offset applied.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only, 2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK, 4) Owner and Renter are is lumped together which at this point only modifies AK distributions.Vacant units (for which Tenure = 'Not Available') are assumed to follow the same distribution as occupied  units

- \Cooling setpoint arguments need to be assigned. A cooling setpoint of None corresponds to 95 F, but is not used by OpenStudio-HPXML. No cooling energy is expected.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``hvac_control_cooling_season_period``
     - false
     - 
     - String
     - "auto"
     - Enter a date like 'Jun 1 - Oct 31'. If not provided, the OS-HPXML default (see `HPXML HVAC Control <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-hvac-control>`_) is used. Can also provide 'BuildingAmerica' to use automatic seasons from the Building America House Simulation Protocols.
   * - ``hvac_control_cooling_weekday_setpoint_temp``
     - true
     - deg-F
     - Double
     -
     - Specify the weekday cooling setpoint temperature.
   * - ``hvac_control_cooling_weekend_setpoint_temp``
     - true
     - deg-F
     - Double
     -
     - Specify the weekend cooling setpoint temperature.
   * - ``use_auto_cooling_season``
     - true
     - 
     - Boolean
     - "true", "false"
     - Specifies whether to automatically define the cooling season based on the weather file.

.. _cooling_setpoint_has_offset:

Cooling Setpoint Has Offset
---------------------------

Description
***********

Presence of a cooling setpoint offset.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK


.. _cooling_setpoint_offset_magnitude:

Cooling Setpoint Offset Magnitude
---------------------------------

Description
***********

The magnitude of cooling setpoint offset.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B and separately 7AK and 8AK regions


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``hvac_control_cooling_weekday_setpoint_offset_magnitude``
     - true
     - deg-F
     - Double
     -
     - Specify the weekday cooling offset magnitude.
   * - ``hvac_control_cooling_weekend_setpoint_offset_magnitude``
     - true
     - deg-F
     - Double
     -
     - Specify the weekend cooling offset magnitude.

.. _cooling_setpoint_offset_period:

Cooling Setpoint Offset Period
------------------------------

Description
***********

The period and offset for the dwelling unit's cooling setpoint. Default for the day is from 9am to 5pm and for the night is 10pm to 7am.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``hvac_control_cooling_weekday_setpoint_schedule``
     - true
     - 
     - String
     -
     - Specify the 24-hour comma-separated weekday cooling schedule of 0s and 1s.
   * - ``hvac_control_cooling_weekend_setpoint_schedule``
     - true
     - 
     - String
     -
     - Specify the 24-hour comma-separated weekend cooling schedule of 0s and 1s.

.. _corridor:

Corridor
--------

Description
***********

Type of corridor attached to multi-family units.

Created by
**********

manually created

Source
******

- \Engineering Judgment


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_corridor_position``
     - true
     - 
     - Choice
     - "Double-Loaded Interior", "Double Exterior", "Single Exterior (Front)", "None"
     - The position of the corridor. Only applies to single-family attached and apartment units. Exterior corridors are shaded, but not enclosed. Interior corridors are enclosed and conditioned.
   * - ``geometry_corridor_width``
     - true
     - ft
     - Double
     -
     - The width of the corridor. Only applies to apartment units.

.. _county:

County
------

Description
***********

The U.S. County that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``simulation_control_daylight_saving_enabled``
     - false
     - 
     - Boolean
     - "auto", "true", "false"
     - Whether to use daylight saving. If not provided, the OS-HPXML default (see `HPXML Building Site <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-building-site>`_) is used.
   * - ``site_zip_code``
     - false
     - 
     - String
     -
     - Zip code of the home address.
   * - ``site_time_zone_utc_offset``
     - false
     - hr
     - Double
     -
     - Time zone UTC offset of the home address. Must be between -12 and 14.
   * - ``weather_station_epw_filepath``
     - true
     - 
     - String
     -
     - Path of the EPW file.

.. _county_and_puma:

County and PUMA
---------------

Description
***********

The GISJOIN identifier for the County and the Public Use Microdata Area that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


.. _dehumidifier:

Dehumidifier
------------

Description
***********

Presence, water removal rate, and humidity setpoint of the dehumidifier.

Created by
**********

manually created

Source
******

- \Not applicable (dehumidifiers are not explicitly modeled separate from plug loads)


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``dehumidifier_type``
     - true
     - 
     - Choice
     - "none", "portable", "whole-home"
     - The type of dehumidifier.
   * - ``dehumidifier_efficiency_type``
     - true
     - 
     - Choice
     - "EnergyFactor", "IntegratedEnergyFactor"
     - The efficiency type of dehumidifier.
   * - ``dehumidifier_efficiency``
     - true
     - liters/kWh
     - Double
     -
     - The efficiency of the dehumidifier.
   * - ``dehumidifier_capacity``
     - true
     - pint/day
     - Double
     -
     - The capacity (water removal rate) of the dehumidifier.
   * - ``dehumidifier_rh_setpoint``
     - true
     - Frac
     - Double
     -
     - The relative humidity setpoint of the dehumidifier.
   * - ``dehumidifier_fraction_dehumidification_load_served``
     - true
     - Frac
     - Double
     -
     - The dehumidification load served fraction of the dehumidifier.

.. _dishwasher:

Dishwasher
----------

Description
***********

The presence and rated efficiency of the dishwasher.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \The 2020 recs survey does not contain EnergyStar rating of dishwashers.Energystar efficiency distributions with [Geometry Building Type,Census Division RECS,Federal Poverty Level, Tenure] as dependencies are imported from RECS 2009Due to low sample count, the tsv is constructed with the followingfallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently

  - \[7] Vintage homes built before 1960 coarsened to pre1960

  - \[8] Vintage homes built after 2000 coarsened to 2000-20

  - \[9] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[10] Census Division RECS to Census Region


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``dishwasher_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a dishwasher present.
   * - ``dishwasher_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space"
     - The space type for the dishwasher location. If not provided, the OS-HPXML default (see `HPXML Dishwasher <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-dishwasher>`_) is used.
   * - ``dishwasher_efficiency_type``
     - true
     - 
     - Choice
     - "RatedAnnualkWh", "EnergyFactor"
     - The efficiency type of dishwasher.
   * - ``dishwasher_efficiency``
     - false
     - RatedAnnualkWh or EnergyFactor
     - Double
     - "auto"
     - The efficiency of the dishwasher. If not provided, the OS-HPXML default (see `HPXML Dishwasher <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-dishwasher>`_) is used.
   * - ``dishwasher_label_electric_rate``
     - false
     - $/kWh
     - Double
     - "auto"
     - The label electric rate of the dishwasher. If not provided, the OS-HPXML default (see `HPXML Dishwasher <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-dishwasher>`_) is used.
   * - ``dishwasher_label_gas_rate``
     - false
     - $/therm
     - Double
     - "auto"
     - The label gas rate of the dishwasher. If not provided, the OS-HPXML default (see `HPXML Dishwasher <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-dishwasher>`_) is used.
   * - ``dishwasher_label_annual_gas_cost``
     - false
     - $
     - Double
     - "auto"
     - The label annual gas cost of the dishwasher. If not provided, the OS-HPXML default (see `HPXML Dishwasher <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-dishwasher>`_) is used.
   * - ``dishwasher_label_usage``
     - false
     - cyc/wk
     - Double
     - "auto"
     - The dishwasher loads per week. If not provided, the OS-HPXML default (see `HPXML Dishwasher <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-dishwasher>`_) is used.
   * - ``dishwasher_place_setting_capacity``
     - false
     - #
     - Integer
     - "auto"
     - The number of place settings for the unit. Data obtained from manufacturer's literature. If not provided, the OS-HPXML default (see `HPXML Dishwasher <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-dishwasher>`_) is used.

.. _dishwasher_usage_level:

Dishwasher Usage Level
----------------------

Description
***********

Dishwasher energy usage level multiplier.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Assumption
**********

- \Engineering judgement


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``dishwasher_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the dishwasher energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Dishwasher <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-dishwasher>`_) is used.

.. _door_area:

Door Area
---------

Description
***********

Area of exterior doors

Created by
**********

manually created

Source
******

- \Engineering Judgement


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``door_area``
     - true
     - ft^2
     - Double
     -
     - The area of the opaque door(s).

.. _doors:

Doors
-----

Description
***********

Exterior door material and properties.

Created by
**********

manually created

Source
******

- \Engineering Judgement


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``door_rvalue``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - R-value of the opaque door(s).

.. _duct_leakage_and_insulation:

Duct Leakage and Insulation
---------------------------

Description
***********

Duct insulation and leakage to outside from the portion of ducts in unconditioned spaces

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \Duct insulation as a function of location: IECC 2009

- \Leakage distribution: Lucas and Cole, 'Impacts of the 2009 IECC for Residential Buildings at State Level', 2009


Assumption
**********

- \Ducts entirely in conditioned spaces will not have any leakage to outside. Ducts with R-4/R-8 insulation were previously assigned to Geometry Foundation Type = Ambient or Slab. They now correspond to those with Duct Location = Garage, Unvented Attic, or Vented Attic.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``ducts_leakage_units``
     - true
     - 
     - Choice
     - "CFM25", "CFM50", "Percent"
     - The leakage units of the ducts.
   * - ``ducts_supply_leakage_to_outside_value``
     - true
     - 
     - Double
     -
     - The leakage value to outside for the supply ducts.
   * - ``ducts_return_leakage_to_outside_value``
     - true
     - 
     - Double
     -
     - The leakage value to outside for the return ducts.
   * - ``ducts_supply_insulation_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - The insulation r-value of the supply ducts excluding air films.
   * - ``ducts_supply_buried_insulation_level``
     - false
     - 
     - Choice
     - "auto", "not buried", "partially buried", "fully buried", "deeply buried"
     - Whether the supply ducts are buried in, e.g., attic loose-fill insulation. Partially buried ducts have insulation that does not cover the top of the ducts. Fully buried ducts have insulation that just covers the top of the ducts. Deeply buried ducts have insulation that continues above the top of the ducts.
   * - ``ducts_return_insulation_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - The insulation r-value of the return ducts excluding air films.
   * - ``ducts_return_buried_insulation_level``
     - false
     - 
     - Choice
     - "auto", "not buried", "partially buried", "fully buried", "deeply buried"
     - Whether the return ducts are buried in, e.g., attic loose-fill insulation. Partially buried ducts have insulation that does not cover the top of the ducts. Fully buried ducts have insulation that just covers the top of the ducts. Deeply buried ducts have insulation that continues above the top of the ducts.

.. _duct_location:

Duct Location
-------------

Description
***********

Location of Duct System

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \OpenStudio-HPXML v1.6.0 and Wilson et al., 'Building America House Simulation Protocols', 2014


Assumption
**********

- \Based on default duct location assignment in OpenStudio-HPXML: the first present space type in the order of: basement - conditioned, basement - unconditioned, crawlspace - conditioned, crawlspace - vented, crawlspace - unvented, attic - vented, attic - unvented, garage, or living space


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``ducts_supply_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "crawlspace", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "attic", "attic - vented", "attic - unvented", "garage", "exterior wall", "under slab", "roof deck", "outside", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space", "manufactured home belly"
     - The location of the supply ducts. If not provided, the OS-HPXML default (see `Air Distribution <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-distribution>`_) is used.
   * - ``ducts_supply_surface_area``
     - false
     - ft^2
     - Double
     - "auto"
     - The supply ducts surface area in the given location. If neither Surface Area nor Area Fraction provided, the OS-HPXML default (see `Air Distribution <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-distribution>`_) is used.
   * - ``ducts_supply_surface_area_fraction``
     - false
     - frac
     - Double
     - "auto"
     - The fraction of supply ducts surface area in the given location. Only used if Surface Area is not provided. If the fraction is less than 1, the remaining duct area is assumed to be in conditioned space. If neither Surface Area nor Area Fraction provided, the OS-HPXML default (see `Air Distribution <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-distribution>`_) is used.
   * - ``ducts_return_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "crawlspace", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "attic", "attic - vented", "attic - unvented", "garage", "exterior wall", "under slab", "roof deck", "outside", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space", "manufactured home belly"
     - The location of the return ducts. If not provided, the OS-HPXML default (see `Air Distribution <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-distribution>`_) is used.
   * - ``ducts_return_surface_area``
     - false
     - ft^2
     - Double
     - "auto"
     - The return ducts surface area in the given location. If neither Surface Area nor Area Fraction provided, the OS-HPXML default (see `Air Distribution <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-distribution>`_) is used.
   * - ``ducts_return_surface_area_fraction``
     - false
     - frac
     - Double
     - "auto"
     - The fraction of return ducts surface area in the given location. Only used if Surface Area is not provided. If the fraction is less than 1, the remaining duct area is assumed to be in conditioned space. If neither Surface Area nor Area Fraction provided, the OS-HPXML default (see `Air Distribution <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-distribution>`_) is used.
   * - ``ducts_number_of_return_registers``
     - false
     - #
     - Integer
     - "auto"
     - The number of return registers of the ducts. Only used to calculate default return duct surface area. If not provided, the OS-HPXML default (see `Air Distribution <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-distribution>`_) is used.

.. _eaves:

Eaves
-----

Description
***********

Depth of roof eaves.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_eaves_depth``
     - true
     - ft
     - Double
     -
     - The eaves depth of the roof.

.. _electric_vehicle:

Electric Vehicle
----------------

Description
***********

Electric vehicle usage and efficiency (not used in project_national).

Created by
**********

manually created

Source
******

- \Not applicable (electric vehicle charging is not currently modeled separate from plug loads)


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``misc_plug_loads_vehicle_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is an electric vehicle.
   * - ``misc_plug_loads_vehicle_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The annual energy consumption of the electric vehicle plug loads. If not provided, the OS-HPXML default (see `HPXML Plug Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-plug-loads>`_) is used.
   * - ``misc_plug_loads_vehicle_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the electric vehicle energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Plug Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-plug-loads>`_) is used.
   * - ``misc_plug_loads_vehicle_2_usage_multiplier``
     - true
     - 
     - Double
     -
     - Additional multiplier on the electric vehicle energy usage that can reflect, e.g., high/low usage occupants.

.. _energystar_climate_zone_2023:

Energystar Climate Zone 2023
----------------------------

Description
***********

Climate zones for windows, doors, and skylights per EnergyStar guidelines as of 2023.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Area definition approximated based on published map retrieved May 2023 from: https://www.energystar.gov/products/residential_windows_doors_and_skylights/key_product_criteria.

- \by Brian Booher of D+R International, a support contractor for the ENERGY STAR windows, doors, and skylights program.


Assumption
**********

- \EnergyStar Climate Zones assigned based on CEC Climate Zone for CA and based on County everywhere else.


.. _federal_poverty_level:

Federal Poverty Level
---------------------

Description
***********

Federal poverty level of the household occupying the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \% Federal Poverty Level is calculated using annual household income in 2019USD (continuous, not binned) from 2019-5yrs PUMS data and 2019 Federal Poverty Lines for contiguous US, where the FPL threshold for 1-occupant household is $12490 and $4420 for every additional person in the household.


.. _generation_and_emissions_assessment_region:

Generation And Emissions Assessment Region
------------------------------------------

Description
***********

The generation and carbon emissions assessment region that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Pieter Gagnon, Will Frazier, Wesley Cole, and Elaine Hale. 2021. Cambium Documentation: Version 2021. Golden, CO.: National Renewable Energy Laboratory. NREL/TP-6A40-81611. https://www.nrel.gov/docs/fy22osti/81611.pdf


.. _geometry_attic_type:

Geometry Attic Type
-------------------

Description
***********

The dwelling unit attic type.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Multi-Family building types and Mobile Homes have Flat Roof (None) only.

- \1-story Single-Family building types cannot have Finished Attic/Cathedral Ceiling because that attic type is modeled as a new story and 1-story does not a second story. 4+story Single-Family and mobile homes are an impossible combination.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_attic_type``
     - true
     - 
     - Choice
     - "FlatRoof", "VentedAttic", "UnventedAttic", "ConditionedAttic", "BelowApartment"
     - The attic type of the building. Attic type ConditionedAttic is not allowed for apartment units.
   * - ``geometry_roof_type``
     - true
     - 
     - Choice
     - "gable", "hip"
     - The roof type of the building. Ignored if the building has a flat roof.
   * - ``geometry_roof_pitch``
     - true
     - 
     - Choice
     - "1:12", "2:12", "3:12", "4:12", "5:12", "6:12", "7:12", "8:12", "9:12", "10:12", "11:12", "12:12"
     - The roof pitch of the attic. Ignored if the building has a flat roof.

.. _geometry_building_horizontal_location_mf:

Geometry Building Horizontal Location MF
----------------------------------------

Description
***********

Location of the single-family attached unit horizontally within the building (left, middle, right).

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \Calculated directly from other distributions


Assumption
**********

- \All values are calculated assuming the building has double-loaded corridors (with some exceptions like 3 units in single-story building).


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_unit_horizontal_location``
     - false
     - 
     - Choice
     - "None", "Left", "Middle", "Right"
     - The horizontal location of the unit when viewing the front of the building. This is required for single-family attached and apartment units.

.. _geometry_building_horizontal_location_sfa:

Geometry Building Horizontal Location SFA
-----------------------------------------

Description
***********

Location of the single-family attached unit horizontally within the building (left, middle, right).

Created by
**********

manually created

Source
******

- \Calculated directly from other distributions


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_unit_horizontal_location``
     - false
     - 
     - Choice
     - "None", "Left", "Middle", "Right"
     - The horizontal location of the unit when viewing the front of the building. This is required for single-family attached and apartment units.

.. _geometry_building_level_mf:

Geometry Building Level MF
--------------------------

Description
***********

Location of the multi-family unit vertically within the building (bottom, middle, top).

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \Calculated directly from other distributions


Assumption
**********

- \Calculated using the number of stories, where buildings >=2 stories have Top and Bottom probabilities = 1/Geometry Stories, and Middle probabilities = 1 - 2/Geometry stories


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_unit_level``
     - false
     - 
     - Choice
     - "Bottom", "Middle", "Top"
     - The level of the unit. This is required for apartment units.

.. _geometry_building_number_units_mf:

Geometry Building Number Units MF
---------------------------------

Description
***********

The number of dwelling units in the multi-family building.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Uses NUMAPTS field in RECS

- \RECS does not report NUMAPTS for Multifamily 2-4 units, so assumptions are made based on the number of stories

- \Data was sampled from the following bins of Geometry Stories: 1, 2, 3, 4-7, 8+


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_building_num_units``
     - false
     - #
     - Integer
     -
     - The number of units in the building. Required for single-family attached and apartment units.

.. _geometry_building_number_units_sfa:

Geometry Building Number Units SFA
----------------------------------

Description
***********

Number of units in the single-family attached building.

Created by
**********

manually created

Source
******

- \U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_building_num_units``
     - false
     - #
     - Integer
     -
     - The number of units in the building. Required for single-family attached and apartment units.

.. _geometry_building_type_acs:

Geometry Building Type ACS
--------------------------

Description
***********

The building type classification according to the U.S. Census American Communicy Survey.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


.. _geometry_building_type_height:

Geometry Building Type Height
-----------------------------

Description
***********

The 2009 U.S. Energy Information Administration Residential Energy Consumption Survey  building type with multi-family buildings split out by low-rise, mid-rise, and high-rise.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \Calculated directly from other distributions


.. _geometry_building_type_recs:

Geometry Building Type RECS
---------------------------

Description
***********

The building type classification according to the U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_unit_type``
     - true
     - 
     - Choice
     - "single-family detached", "single-family attached", "apartment unit", "manufactured home"
     - The type of dwelling unit. Use single-family attached for a dwelling unit with 1 or more stories, attached units to one or both sides, and no units above/below. Use apartment unit for a dwelling unit with 1 story, attached units to one, two, or three sides, and units above and/or below.
   * - ``geometry_unit_aspect_ratio``
     - true
     - Frac
     - Double
     -
     - The ratio of front/back wall length to left/right wall length for the unit, excluding any protruding garage wall area.
   * - ``geometry_average_ceiling_height``
     - true
     - ft
     - Double
     -
     - Average distance from the floor to the ceiling.

.. _geometry_floor_area:

Geometry Floor Area
-------------------

Description
***********

The finished floor area of the dwelling unit using bins from 2017-2019 AHS.

Created by
**********

``sources/ahs/ahs2017_2019/tsv_maker.py``

Source
******

- \2017 and 2019 American Housing Survey (AHS) microdata.


Assumption
**********

- \Due to low sample count, the tsv is constructed by downscaling a core sub-tsv with 3 sub-tsvs of different dependencies. The sub-tsvs have the following dependencies: tsv1 : 'Census Division', 'PUMA Metro Status', 'Geometry Building Type RECS', 'Income RECS2020'

- \tsv2 : 'Census Division', 'PUMA Metro Status', 'Geometry Building Type RECS', 'Tenure'

- \tsv3 : 'Census Division', 'PUMA Metro Status', 'Geometry Building Type RECS', 'Vintage ACS'

- \tsv4 : 'Census Division', 'PUMA Metro Status', 'Income RECS2020', 'Tenure'. For each sub-tsv, rows with <10 samples are replaced with coarsening dependency Census Region, followed by National.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_garage_protrusion``
     - true
     - Frac
     - Double
     -
     - The fraction of the garage that is protruding from the conditioned space. Only applies to single-family detached units.
   * - ``geometry_unit_cfa_bin``
     - true
     - 
     - String
     -
     - E.g., '2000-2499'.
   * - ``geometry_unit_cfa``
     - true
     - sqft
     - Double
     -
     - E.g., '2000' or 'auto'.

.. _geometry_floor_area_bin:

Geometry Floor Area Bin
-----------------------

Description
***********

The finished floor area of the dwelling unit using bins from the U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Geometry Floor Area bins are from the UNITSIZE field of the 2017 American Housing Survey (AHS).


.. _geometry_foundation_type:

Geometry Foundation Type
------------------------

Description
***********

The type of foundation.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \All mobile homes have Ambient foundations.

- \Multi-family buildings cannot have Ambient and Heated Basements

- \Single-family attached buildings cannot have Ambient foundations

- \Foundation types are the same for each building type except mobile homes and the applicable options.

- \Because we need to assume a foundation type for ground-floor MF units, we use the lumped SFD+SFA distributions for MF2-4 and MF5+ building foundations. (RECS data for households in MF2-4 unit buildings are not useful since we do not know which floor the unitis on. RECS does not include foundation responses for households in MF5+ unit buildings.)

- \For SFD and SFA, if no foundation type specified, then sample has Ambient foundation.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_foundation_type``
     - true
     - 
     - Choice
     - "SlabOnGrade", "VentedCrawlspace", "UnventedCrawlspace", "ConditionedCrawlspace", "UnconditionedBasement", "ConditionedBasement", "Ambient", "AboveApartment", "BellyAndWingWithSkirt", "BellyAndWingNoSkirt"
     - The foundation type of the building. Foundation types ConditionedBasement and ConditionedCrawlspace are not allowed for apartment units.
   * - ``geometry_foundation_height``
     - true
     - ft
     - Double
     -
     - The height of the foundation (e.g., 3ft for crawlspace, 8ft for basement). Only applies to basements/crawlspaces.
   * - ``geometry_foundation_height_above_grade``
     - true
     - ft
     - Double
     -
     - The depth above grade of the foundation wall. Only applies to basements/crawlspaces.
   * - ``geometry_rim_joist_height``
     - false
     - in
     - Double
     -
     - The height of the rim joists. Only applies to basements/crawlspaces.

.. _geometry_garage:

Geometry Garage
---------------

Description
***********

The size of an attached garage.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Only Single-Family Detached homes are assigned a probability for attached garage.

- \No garage for ambient (i.e., pier & beam) foundation type.

- \Due to modeling constraints restricting that garage cannot be larger or deeper than livable space: Single-family detached units that are 0-1499 square feet can only have a maximum of a 1 car garage.

- \Single-family detached units that are 0-1499 square feet and 3+ stories cannot have a garage.

- \The geometry stories distributions are all the same except for 0-1499 square feet and 3 stories.

- \Single-family detached units that are 1500-2499 square feet can not have a 3 car garage.

- \Single-family detached units that are 2500-3999 square feet and a heated basement can not have a 3 car garage. Due to low sample sizes, 1. Crawl, basements, and slab are lumped.

- \2. Story levels are lumped together.

- \2. Census Division RECS is grouped into Census Region.

- \2. Vintage ACS is progressively grouped into: pre-1960, 1960-1999, and 2000+.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_garage_width``
     - true
     - ft
     - Double
     -
     - The width of the garage. Enter zero for no garage. Only applies to single-family detached units.
   * - ``geometry_garage_depth``
     - true
     - ft
     - Double
     -
     - The depth of the garage. Only applies to single-family detached units.
   * - ``geometry_garage_position``
     - true
     - 
     - Choice
     - "Right", "Left"
     - The position of the garage. Only applies to single-family detached units.

.. _geometry_space_combination:

Geometry Space Combination
--------------------------

Description
***********

Valid combinations of building type, building level mf, attic, foundation, and garage

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For building level mf, only multi-family (MF) can have top, middle, or bottom units,

- \For foundation, mobile home (MH) has ambient only, MF cannot have ambient or heated basement, single-family attached cannot have ambient.

- \For attic, MH and MF have no attic.

- \For (attached) garage, only single-family detached without ambient foundation type can have garage.


.. _geometry_stories:

Geometry Stories
----------------

Description
***********

The number of building stories.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \All mobile homes are 1 story.

- \Single-Family Detached and Single-Family Attached use the STORIES field in RECS, whereas Multifamily with 5+ units uses the NUMFLRS field.

- \Building types 2 Unit and 3 or 4 Unit use the stories distribution of Multifamily 5 to 9 Unit (capped at 4 stories) because RECS does not report stories or floors for multifamily with 2-4 units.

- \The dependency on floor area bins is removed for multifamily with 5+ units.

- \Vintage ACS rows for the 2010s are copied from the 2000-09 rows.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_num_floors_above_grade``
     - true
     - #
     - Integer
     -
     - The number of floors above grade (in the unit if single-family detached or single-family attached, and in the building if apartment unit). Conditioned attics are included.

.. _geometry_stories_low_rise:

Geometry Stories Low Rise
-------------------------

Description
***********

Number of building stories for low-rise buildings.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \Calculated directly from other distributions


.. _geometry_story_bin:

Geometry Story Bin
------------------

Description
***********

The building has more than 8 or less than 8 stories.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


.. _geometry_wall_exterior_finish:

Geometry Wall Exterior Finish
-----------------------------

Description
***********

Wall siding material and color.

Created by
**********

``sources/lightbox/residential/tsv_maker.py``

Source
******

- \HIFLD Parcel data.


Assumption
**********

- \Rows where sample size < 10 are replaced with aggregated values down-scaled from dep='State' to dep='Census Division RECS'

- \Brick wall types are assumed to not have an aditional brick exterior finish

- \Steel and wood frame walls must have an exterior finish


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``wall_siding_type``
     - false
     - 
     - Choice
     - "auto", "aluminum siding", "asbestos siding", "brick veneer", "composite shingle siding", "fiber cement siding", "masonite siding", "none", "stucco", "synthetic stucco", "vinyl siding", "wood siding"
     - The siding type of the walls. Also applies to rim joists. If not provided, the OS-HPXML default (see `HPXML Walls <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-walls>`_) is used.
   * - ``wall_color``
     - false
     - 
     - Choice
     - "auto", "dark", "light", "medium", "medium dark", "reflective"
     - The color of the walls. Also applies to rim joists. If not provided, the OS-HPXML default (see `HPXML Walls <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-walls>`_) is used.
   * - ``exterior_finish_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - R-value of the exterior finish.

.. _geometry_wall_type:

Geometry Wall Type
------------------

Description
***********

The wall material used for thermal mass calculations of exterior walls.

Created by
**********

``sources/lightbox/residential/tsv_maker.py``

Source
******

- \HIFLD Parcel data.


Assumption
**********

- \Rows where sample size < 10 are replaced with aggregated values down-scaled from dep='State' to dep='Census Division RECS'


.. _hvac_cooling_efficiency:

HVAC Cooling Efficiency
-----------------------

Description
***********

The presence and efficiency of primary cooling system in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Efficiency data based on CAC-ASHP-shipments-table.tsv, room_AC_efficiency_vs_age.tsv and expanded_HESC_HVAC_efficiencies.tsv combined with age of equipment data from RECS


Assumption
**********

- \Check the assumptions on the source tsv files.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``cooling_system_type``
     - true
     - 
     - Choice
     - "none", "central air conditioner", "room air conditioner", "evaporative cooler", "mini-split", "packaged terminal air conditioner"
     - The type of cooling system. Use 'none' if there is no cooling system or if there is a heat pump serving a cooling load.
   * - ``cooling_system_cooling_efficiency_type``
     - true
     - 
     - Choice
     - "SEER", "SEER2", "EER", "CEER"
     - The efficiency type of the cooling system. System types central air conditioner and mini-split use SEER or SEER2. System types room air conditioner and packaged terminal air conditioner use EER or CEER. Ignored for system type evaporative cooler.
   * - ``cooling_system_cooling_efficiency``
     - true
     - 
     - Double
     -
     - The rated efficiency value of the cooling system. Ignored for evaporative cooler.
   * - ``cooling_system_cooling_compressor_type``
     - false
     - 
     - Choice
     - "auto", "single stage", "two stage", "variable speed"
     - The compressor type of the cooling system. Only applies to central air conditioner. If not provided, the OS-HPXML default (see `Central Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#central-air-conditioner>`_) is used.
   * - ``cooling_system_cooling_sensible_heat_fraction``
     - false
     - Frac
     - Double
     - "auto"
     - The sensible heat fraction of the cooling system. Ignored for evaporative cooler. If not provided, the OS-HPXML default (see `Central Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#central-air-conditioner>`_, `Room Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner>`_, `Packaged Terminal Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-air-conditioner>`_, `Mini-Split Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-air-conditioner>`_) is used.
   * - ``cooling_system_cooling_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The output cooling capacity of the cooling system. If not provided, the OS-HPXML autosized default (see `Central Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#central-air-conditioner>`_, `Room Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner>`_, `Packaged Terminal Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-air-conditioner>`_, `Evaporative Cooler <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#evaporative-cooler>`_, `Mini-Split Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-air-conditioner>`_) is used.
   * - ``cooling_system_is_ducted``
     - false
     - 
     - Boolean
     - "auto", "true", "false"
     - Whether the cooling system is ducted or not. Only used for mini-split and evaporative cooler. It's assumed that central air conditioner is ducted, and room air conditioner and packaged terminal air conditioner are not ducted.
   * - ``cooling_system_crankcase_heater_watts``
     - false
     - W
     - Double
     - "auto"
     - Cooling system crankcase heater power consumption in Watts. Applies only to central air conditioner, room air conditioner, packaged terminal air conditioner and mini-split. If not provided, the OS-HPXML default (see `Central Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#central-air-conditioner>`_, `Room Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner>`_, `Packaged Terminal Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-air-conditioner>`_, `Mini-Split Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-air-conditioner>`_) is used.
   * - ``cooling_system_integrated_heating_system_fuel``
     - false
     - 
     - Choice
     - "auto", "electricity", "natural gas", "fuel oil", "propane", "wood", "wood pellets", "coal"
     - The fuel type of the heating system integrated into cooling system. Only used for packaged terminal air conditioner and room air conditioner.
   * - ``cooling_system_integrated_heating_system_efficiency_percent``
     - false
     - Frac
     - Double
     -
     - The rated heating efficiency value of the heating system integrated into cooling system. Only used for packaged terminal air conditioner and room air conditioner.
   * - ``cooling_system_integrated_heating_system_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The output heating capacity of the heating system integrated into cooling system. If not provided, the OS-HPXML autosized default (see `Room Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner>`_, `Packaged Terminal Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-air-conditioner>`_) is used. Only used for room air conditioner and packaged terminal air conditioner.
   * - ``cooling_system_integrated_heating_system_fraction_heat_load_served``
     - false
     - Frac
     - Double
     -
     - The heating load served by the heating system integrated into cooling system. Only used for packaged terminal air conditioner and room air conditioner.

.. _hvac_cooling_partial_space_conditioning:

HVAC Cooling Partial Space Conditioning
---------------------------------------

Description
***********

The fraction of the finished floor area that the cooling system provides cooling.

Created by
**********

``sources/recs/recs2009/tsv_maker.py``

Source
******

- \U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Central AC systems need to serve at least 60 percent of the floor area.

- \Heat pumps serve 100 percent of the floor area because the system serves 100 percent of the heated floor area.

- \Due to low sample count, the tsv is constructed by downscaling a core sub-tsv with 3 sub-tsvs of different dependencies. The sub-tsvs have the following dependencies: tsv1 : 'HVAC Cooling Type', 'ASHRAE IECC Climate Zone 2004'

- \tsv2 : 'HVAC Cooling Type', 'Geometry Floor Area Bin'

- \tsv3 : 'HVAC Cooling Type', 'Geometry Building Type RECS'


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``cooling_system_fraction_cool_load_served``
     - true
     - Frac
     - Double
     -
     - The cooling load served by the cooling system.

.. _hvac_cooling_type:

HVAC Cooling Type
-----------------

Description
***********

The presence and type of primary cooling system in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample sizes, fallback rules applied with lumping of

- \1) HVAC Heating type: Non-ducted heating and None2) Geometry building SF: Mobile, Single family attached, Single family detached3) Geometry building MF: Multi-Family with 2 - 4 Units, Multi-Family with 5+ Units4) Vintage Lump: 20yrs binsHomes having ducted heat pump for heating and electricity fuel is assumed to haveducted heat pump for cooling (seperating from central AC category)

- \Homes having non-ducted heat pump for heating is assumed to have non-ducted heat pumpfor cooling


.. _hvac_has_ducts:

HVAC Has Ducts
--------------

Description
***********

The presence of ducts in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Ducted Heat Pump HVAC type assumed to have ducts

- \Non-Ducted Heat Pump HVAC type assumed to have no ducts

- \There are likely homes with non-ducted heat pump having ducts (Central AC with non-ducted HP) But due to structure of ResStock we are not accounting those homes

- \Evaporative or Swamp Cooler assigned Void option

- \None of the shared system options currently modeled (in HVAC Shared Efficiencies) are ducted, therefore where there are discrepancies between HVAC Heating Type, HVAC Cooling Type, and HVAC Has Shared System, HVAC Has Shared System takes precedence. (e.g., Central AC + Ducted Heating + Shared Heating and Cooling = No (Ducts)) (This is a temporary fix and will change when ducted shared system options are introduced.)


.. _hvac_has_shared_system:

HVAC Has Shared System
----------------------

Description
***********

The presence of an HVAC system shared between multiple dwelling units.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample sizes, the fallback rules are applied in following order

  - \[1] Vintage: Vintage ACS 20 year bin[2] HVAC Cooling Type: Lump 1) Central AC and Ducted Heat Pump and 2) Non-Ducted Heat Pump and None[3] HVAC Heating Type: Lump 1) Ducted Heating and Ducted Heat Pump and 2) Non-Ducted Heat Pump and None[4] HVAC Cooling Type: Lump 1) Central AC and Ducted Heat Pump and 2) Non-Ducted Heat Pump, Non-Ducted Heating, and None[5] HVAC Heating Type: Lump 1) Ducted Heating and Ducted Heat Pump and 2) Non-Ducted Heat Pump, None, and Room AC[6] Vintage: Vintage pre 1960s and post 2000[7] Vintage: All vintages

- \Evaporative or Swamp Cooler Cooling Type assigned Void option

- \Ducted Heat Pump assigned for both heating and cooling, other combinations assigned Void option

- \Non-Ducted Heat Pump assigned for both heating and cooling, other combinations assigned Void option


.. _hvac_has_zonal_electric_heating:

HVAC Has Zonal Electric Heating
-------------------------------

Description
***********

Presence of electric baseboard heating

Created by
**********

manually created

Source
******

- \n/a


.. _hvac_heating_efficiency:

HVAC Heating Efficiency
-----------------------

Description
***********

The presence and efficiency of the primary heating system in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Shipment data based on CAC-ASHP-shipments-table.tsv and furnace-shipments-table.tsv

- \Efficiency data based on expanded_HESC_HVAC_efficiencies.tsv combined with age of equipment data from RECS


Assumption
**********

- \Check the assumptions on the source tsv files.

- \If a house has a wall furnace with fuel other than natural_gas, efficiency level based on natural_gas from expanded_HESC_HVAC_efficiencies.tsv is assigned.

- \If a house has a heat pump with fuel other than electricity (presumed dual-fuel heat pump), the heating type is assumed to be furnace and not heat pump.

- \The shipment volume for boiler was not available, so shipment volume for furnace in furnace-shipments-table.tsv was used instead.

- \Due to low sample size for some categories, the HVAC Has Shared System categories 'Cooling Only' and 'None' are combined for the purpose of querying Heating Efficiency distributions.

- \For 'other' heating system types, we assign them to Electric Baseboard if fuel is Electric, and assign them to Wall/Floor Furnace if fuel is natural_gas, fuel_oil or propane.

- \For Other Fuel, the lowest efficiency systems are assumed.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``heating_system_type``
     - true
     - 
     - Choice
     - "none", "Furnace", "WallFurnace", "FloorFurnace", "Boiler", "ElectricResistance", "Stove", "SpaceHeater", "Fireplace", "Shared Boiler w/ Baseboard", "Shared Boiler w/ Ductless Fan Coil"
     - The type of heating system. Use 'none' if there is no heating system or if there is a heat pump serving a heating load.
   * - ``heating_system_heating_efficiency``
     - true
     - Frac
     - Double
     -
     - The rated heating efficiency value of the heating system.
   * - ``heating_system_heating_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The output heating capacity of the heating system. If not provided, the OS-HPXML autosized default (see `HPXML Heating Systems <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-heating-systems>`_) is used.
   * - ``heating_system_fraction_heat_load_served``
     - true
     - Frac
     - Double
     -
     - The heating load served by the heating system.
   * - ``heating_system_pilot_light``
     - false
     - Btuh
     - Double
     -
     - The fuel usage of the pilot light. Applies only to Furnace, WallFurnace, FloorFurnace, Stove, Boiler, and Fireplace with non-electric fuel type. If not provided, assumes no pilot light.
   * - ``heat_pump_type``
     - true
     - 
     - Choice
     - "none", "air-to-air", "mini-split", "ground-to-air", "packaged terminal heat pump", "room air conditioner with reverse cycle"
     - The type of heat pump. Use 'none' if there is no heat pump.
   * - ``heat_pump_heating_efficiency_type``
     - true
     - 
     - Choice
     - "HSPF", "HSPF2", "COP"
     - The heating efficiency type of heat pump. System types air-to-air and mini-split use HSPF or HSPF2. System types ground-to-air, packaged terminal heat pump and room air conditioner with reverse cycle use COP.
   * - ``heat_pump_heating_efficiency``
     - true
     - 
     - Double
     -
     - The rated heating efficiency value of the heat pump.
   * - ``heat_pump_cooling_efficiency_type``
     - true
     - 
     - Choice
     - "SEER", "SEER2", "EER", "CEER"
     - The cooling efficiency type of heat pump. System types air-to-air and mini-split use SEER or SEER2. System types ground-to-air, packaged terminal heat pump and room air conditioner with reverse cycle use EER.
   * - ``heat_pump_cooling_efficiency``
     - true
     - 
     - Double
     -
     - The rated cooling efficiency value of the heat pump.
   * - ``heat_pump_cooling_compressor_type``
     - false
     - 
     - Choice
     - "auto", "single stage", "two stage", "variable speed"
     - The compressor type of the heat pump. Only applies to air-to-air. If not provided, the OS-HPXML default (see `Air-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-to-air-heat-pump>`_) is used.
   * - ``heat_pump_cooling_sensible_heat_fraction``
     - false
     - Frac
     - Double
     - "auto"
     - The sensible heat fraction of the heat pump. If not provided, the OS-HPXML default (see `Air-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-to-air-heat-pump>`_, `Mini-Split Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-heat-pump>`_, `Packaged Terminal Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-heat-pump>`_, `Room Air Conditioner w/ Reverse Cycle <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle>`_, `Ground-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#ground-to-air-heat-pump>`_) is used.
   * - ``heat_pump_heating_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The output heating capacity of the heat pump. If not provided, the OS-HPXML autosized default (see `Air-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-to-air-heat-pump>`_, `Mini-Split Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-heat-pump>`_, `Packaged Terminal Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-heat-pump>`_, `Room Air Conditioner w/ Reverse Cycle <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle>`_, `Ground-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#ground-to-air-heat-pump>`_) is used.
   * - ``heat_pump_heating_capacity_retention_fraction``
     - false
     - Frac
     - Double
     - "auto"
     - The output heating capacity of the heat pump at a user-specified temperature (e.g., 17F or 5F) divided by the above nominal heating capacity. Applies to all heat pump types except ground-to-air. If not provided, the OS-HPXML default (see `Air-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-to-air-heat-pump>`_, `Mini-Split Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-heat-pump>`_, `Packaged Terminal Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-heat-pump>`_, `Room Air Conditioner w/ Reverse Cycle <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle>`_) is used.
   * - ``heat_pump_heating_capacity_retention_temp``
     - false
     - deg-F
     - Double
     -
     - The user-specified temperature (e.g., 17F or 5F) for the above heating capacity retention fraction. Applies to all heat pump types except ground-to-air. Required if the Heating Capacity Retention Fraction is provided.
   * - ``heat_pump_cooling_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The output cooling capacity of the heat pump. If not provided, the OS-HPXML autosized default (see `Air-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-to-air-heat-pump>`_, `Mini-Split Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-heat-pump>`_, `Packaged Terminal Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-heat-pump>`_, `Room Air Conditioner w/ Reverse Cycle <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle>`_, `Ground-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#ground-to-air-heat-pump>`_) is used.
   * - ``heat_pump_fraction_heat_load_served``
     - true
     - Frac
     - Double
     -
     - The heating load served by the heat pump.
   * - ``heat_pump_fraction_cool_load_served``
     - true
     - Frac
     - Double
     -
     - The cooling load served by the heat pump.
   * - ``heat_pump_compressor_lockout_temp``
     - false
     - deg-F
     - Double
     - "auto"
     - The temperature below which the heat pump compressor is disabled. If both this and Backup Heating Lockout Temperature are provided and use the same value, it essentially defines a switchover temperature (for, e.g., a dual-fuel heat pump). Applies to all heat pump types other than ground-to-air. If not provided, the OS-HPXML default (see `Air-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-to-air-heat-pump>`_, `Mini-Split Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-heat-pump>`_, `Packaged Terminal Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-heat-pump>`_, `Room Air Conditioner w/ Reverse Cycle <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle>`_) is used.
   * - ``heat_pump_backup_type``
     - true
     - 
     - Choice
     - "none", "integrated", "separate"
     - The backup type of the heat pump. If 'integrated', represents e.g. built-in electric strip heat or dual-fuel integrated furnace. If 'separate', represents e.g. electric baseboard or boiler based on the Heating System 2 specified below. Use 'none' if there is no backup heating.
   * - ``heat_pump_backup_fuel``
     - true
     - 
     - Choice
     - "electricity", "natural gas", "fuel oil", "propane"
     - The backup fuel type of the heat pump. Only applies if Backup Type is 'integrated'.
   * - ``heat_pump_backup_heating_efficiency``
     - true
     - 
     - Double
     -
     - The backup rated efficiency value of the heat pump. Percent for electricity fuel type. AFUE otherwise. Only applies if Backup Type is 'integrated'.
   * - ``heat_pump_backup_heating_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The backup output heating capacity of the heat pump. If not provided, the OS-HPXML autosized default (see `Backup <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#backup>`_) is used. Only applies if Backup Type is 'integrated'.
   * - ``heat_pump_backup_heating_lockout_temp``
     - false
     - deg-F
     - Double
     - "auto"
     - The temperature above which the heat pump backup system is disabled. If both this and Compressor Lockout Temperature are provided and use the same value, it essentially defines a switchover temperature (for, e.g., a dual-fuel heat pump). Applies for both Backup Type of 'integrated' and 'separate'. If not provided, the OS-HPXML default (see `Backup <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#backup>`_) is used.
   * - ``heat_pump_sizing_methodology``
     - false
     - 
     - Choice
     - "auto", "ACCA", "HERS", "MaxLoad"
     - The auto-sizing methodology to use when the heat pump capacity is not provided. If not provided, the OS-HPXML default (see `HPXML HVAC Sizing Control <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-hvac-sizing-control>`_) is used.
   * - ``heat_pump_is_ducted``
     - false
     - 
     - Boolean
     - "auto", "true", "false"
     - Whether the heat pump is ducted or not. Only used for mini-split. It's assumed that air-to-air and ground-to-air are ducted, and packaged terminal heat pump and room air conditioner with reverse cycle are not ducted. If not provided, assumes not ducted.
   * - ``heat_pump_crankcase_heater_watts``
     - false
     - W
     - Double
     - "auto"
     - Heat Pump crankcase heater power consumption in Watts. Applies only to air-to-air, mini-split, packaged terminal heat pump and room air conditioner with reverse cycle. If not provided, the OS-HPXML default (see `Air-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-to-air-heat-pump>`_, `Mini-Split Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-heat-pump>`_, `Packaged Terminal Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-heat-pump>`_, `Room Air Conditioner w/ Reverse Cycle <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle>`_) is used.
   * - ``heating_system_has_flue_or_chimney``
     - true
     - 
     - String
     -
     - Whether the heating system has a flue or chimney.

.. _hvac_heating_type:

HVAC Heating Type
-----------------

Description
***********

The presence and type of the primary heating system in the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample sizes, fallback rules applied with lumping of

- \1) Heating fuel lump: Fuel oil, Propane, and Other Fuel2) Geometry building SF: Mobile, Single family attached, Single family detached3) Geometry building MF: Multi-Family with 2 - 4 Units, Multi-Family with 5+ Units4) Vintage Lump: 20yrs bins


.. _hvac_heating_type_and_fuel:

HVAC Heating Type And Fuel
--------------------------

Description
***********

The presence, type, and fuel of primary heating system.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \Calculated directly from other distributions


.. _hvac_secondary_heating_efficiency:

HVAC Secondary Heating Efficiency
---------------------------------

Description
***********

Efficiency of the secondary heating system (not used in project_national).

Created by
**********

manually created

Source
******

- \n/a


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``heating_system_2_type``
     - true
     - 
     - Choice
     - "none", "Furnace", "WallFurnace", "FloorFurnace", "Boiler", "ElectricResistance", "Stove", "SpaceHeater", "Fireplace"
     - The type of the second heating system.
   * - ``heating_system_2_heating_efficiency``
     - true
     - Frac
     - Double
     -
     - The rated heating efficiency value of the second heating system.
   * - ``heating_system_2_heating_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The output heating capacity of the second heating system. If not provided, the OS-HPXML autosized default (see `HPXML Heating Systems <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-heating-systems>`_) is used.
   * - ``heating_system_2_has_flue_or_chimney``
     - true
     - 
     - String
     -
     - Whether the second heating system has a flue or chimney.

.. _hvac_secondary_heating_fuel:

HVAC Secondary Heating Fuel
---------------------------

Description
***********

Secondary HVAC system heating type and fuel (not used in project_national).

Created by
**********

manually created

Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``heating_system_2_fuel``
     - true
     - 
     - Choice
     - "electricity", "natural gas", "fuel oil", "propane", "wood", "wood pellets", "coal"
     - The fuel type of the second heating system. Ignored for ElectricResistance.

.. _hvac_secondary_heating_partial_space_conditioning:

HVAC Secondary Heating Partial Space Conditioning
-------------------------------------------------

Description
***********

Fraction of heat load served by secondary heating system (not used in project_national).

Created by
**********

manually created

Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``heating_system_2_fraction_heat_load_served``
     - true
     - Frac
     - Double
     -
     - The heat load served fraction of the second heating system. Ignored if this heating system serves as a backup system for a heat pump.

.. _hvac_shared_efficiencies:

HVAC Shared Efficiencies
------------------------

Description
***********

The presence and efficiency of the shared HVAC system.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Assume that all Heating and Cooling shared systems are fan coils in each dwelling unit served by a central chiller and boiler.

- \Assume all Heating Only shared systems are hot water baseboards in each dwelling unit served by a central boiler.

- \Assume all Cooling Only shared systems are fan coils in each dwelling unit served by a central chiller.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``heating_system_type``
     - true
     - 
     - Choice
     - "none", "Furnace", "WallFurnace", "FloorFurnace", "Boiler", "ElectricResistance", "Stove", "SpaceHeater", "Fireplace", "Shared Boiler w/ Baseboard", "Shared Boiler w/ Ductless Fan Coil"
     - The type of heating system. Use 'none' if there is no heating system or if there is a heat pump serving a heating load.
   * - ``heating_system_heating_efficiency``
     - true
     - Frac
     - Double
     -
     - The rated heating efficiency value of the heating system.
   * - ``heating_system_heating_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The output heating capacity of the heating system. If not provided, the OS-HPXML autosized default (see `HPXML Heating Systems <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-heating-systems>`_) is used.
   * - ``heating_system_fraction_heat_load_served``
     - true
     - Frac
     - Double
     -
     - The heating load served by the heating system.
   * - ``cooling_system_type``
     - true
     - 
     - Choice
     - "none", "central air conditioner", "room air conditioner", "evaporative cooler", "mini-split", "packaged terminal air conditioner"
     - The type of cooling system. Use 'none' if there is no cooling system or if there is a heat pump serving a cooling load.
   * - ``cooling_system_cooling_efficiency_type``
     - true
     - 
     - Choice
     - "SEER", "SEER2", "EER", "CEER"
     - The efficiency type of the cooling system. System types central air conditioner and mini-split use SEER or SEER2. System types room air conditioner and packaged terminal air conditioner use EER or CEER. Ignored for system type evaporative cooler.
   * - ``cooling_system_cooling_efficiency``
     - true
     - 
     - Double
     -
     - The rated efficiency value of the cooling system. Ignored for evaporative cooler.
   * - ``cooling_system_cooling_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The output cooling capacity of the cooling system. If not provided, the OS-HPXML autosized default (see `Central Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#central-air-conditioner>`_, `Room Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner>`_, `Packaged Terminal Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-air-conditioner>`_, `Evaporative Cooler <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#evaporative-cooler>`_, `Mini-Split Air Conditioner <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-air-conditioner>`_) is used.
   * - ``cooling_system_is_ducted``
     - false
     - 
     - Boolean
     - "auto", "true", "false"
     - Whether the cooling system is ducted or not. Only used for mini-split and evaporative cooler. It's assumed that central air conditioner is ducted, and room air conditioner and packaged terminal air conditioner are not ducted.
   * - ``heat_pump_type``
     - true
     - 
     - Choice
     - "none", "air-to-air", "mini-split", "ground-to-air", "packaged terminal heat pump", "room air conditioner with reverse cycle"
     - The type of heat pump. Use 'none' if there is no heat pump.
   * - ``heat_pump_heating_efficiency_type``
     - true
     - 
     - Choice
     - "HSPF", "HSPF2", "COP"
     - The heating efficiency type of heat pump. System types air-to-air and mini-split use HSPF or HSPF2. System types ground-to-air, packaged terminal heat pump and room air conditioner with reverse cycle use COP.
   * - ``heat_pump_heating_efficiency``
     - true
     - 
     - Double
     -
     - The rated heating efficiency value of the heat pump.
   * - ``heat_pump_cooling_efficiency_type``
     - true
     - 
     - Choice
     - "SEER", "SEER2", "EER", "CEER"
     - The cooling efficiency type of heat pump. System types air-to-air and mini-split use SEER or SEER2. System types ground-to-air, packaged terminal heat pump and room air conditioner with reverse cycle use EER.
   * - ``heat_pump_cooling_efficiency``
     - true
     - 
     - Double
     -
     - The rated cooling efficiency value of the heat pump.
   * - ``heat_pump_heating_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The output heating capacity of the heat pump. If not provided, the OS-HPXML autosized default (see `Air-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-to-air-heat-pump>`_, `Mini-Split Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-heat-pump>`_, `Packaged Terminal Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-heat-pump>`_, `Room Air Conditioner w/ Reverse Cycle <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle>`_, `Ground-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#ground-to-air-heat-pump>`_) is used.
   * - ``heat_pump_cooling_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The output cooling capacity of the heat pump. If not provided, the OS-HPXML autosized default (see `Air-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#air-to-air-heat-pump>`_, `Mini-Split Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#mini-split-heat-pump>`_, `Packaged Terminal Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#packaged-terminal-heat-pump>`_, `Room Air Conditioner w/ Reverse Cycle <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#room-air-conditioner-w-reverse-cycle>`_, `Ground-to-Air Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#ground-to-air-heat-pump>`_) is used.
   * - ``heat_pump_fraction_heat_load_served``
     - true
     - Frac
     - Double
     -
     - The heating load served by the heat pump.
   * - ``heat_pump_fraction_cool_load_served``
     - true
     - Frac
     - Double
     -
     - The cooling load served by the heat pump.
   * - ``heat_pump_backup_type``
     - true
     - 
     - Choice
     - "none", "integrated", "separate"
     - The backup type of the heat pump. If 'integrated', represents e.g. built-in electric strip heat or dual-fuel integrated furnace. If 'separate', represents e.g. electric baseboard or boiler based on the Heating System 2 specified below. Use 'none' if there is no backup heating.
   * - ``heat_pump_backup_fuel``
     - true
     - 
     - Choice
     - "electricity", "natural gas", "fuel oil", "propane"
     - The backup fuel type of the heat pump. Only applies if Backup Type is 'integrated'.
   * - ``heat_pump_backup_heating_efficiency``
     - true
     - 
     - Double
     -
     - The backup rated efficiency value of the heat pump. Percent for electricity fuel type. AFUE otherwise. Only applies if Backup Type is 'integrated'.
   * - ``heat_pump_backup_heating_capacity``
     - false
     - Btu/hr
     - Double
     -
     - The backup output heating capacity of the heat pump. If not provided, the OS-HPXML autosized default (see `Backup <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#backup>`_) is used. Only applies if Backup Type is 'integrated'.
   * - ``heat_pump_sizing_methodology``
     - false
     - 
     - Choice
     - "auto", "ACCA", "HERS", "MaxLoad"
     - The auto-sizing methodology to use when the heat pump capacity is not provided. If not provided, the OS-HPXML default (see `HPXML HVAC Sizing Control <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-hvac-sizing-control>`_) is used.
   * - ``heating_system_has_flue_or_chimney``
     - true
     - 
     - String
     -
     - Whether the heating system has a flue or chimney.

.. _hvac_system_is_faulted:

HVAC System Is Faulted
----------------------

Description
***********

The presence of the HVAC system having a fault (not used in project_national).

Created by
**********

manually created

Source
******

- \Assuming no faults until we have data necessary to characterize all types of ACs and heat pumps (https://github.com/NREL/resstock/issues/733).


.. _hvac_system_single_speed_ac_airflow:

HVAC System Single Speed AC Airflow
-----------------------------------

Description
***********

Single speed central and room air conditioner actual air flow rates.

Created by
**********

manually created

Source
******

- \Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``cooling_system_rated_cfm_per_ton``
     - false
     - cfm/ton
     - Double
     -
     - The rated cfm per ton of the cooling system.
   * - ``cooling_system_actual_cfm_per_ton``
     - false
     - cfm/ton
     - Double
     -
     - The actual cfm per ton of the cooling system.

.. _hvac_system_single_speed_ac_charge:

HVAC System Single Speed AC Charge
----------------------------------

Description
***********

Central and room air conditioner deviation between design/installed charge.

Created by
**********

manually created

Source
******

- \Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``cooling_system_frac_manufacturer_charge``
     - false
     - Frac
     - Double
     -
     - The fraction of manufacturer recommended charge of the cooling system.

.. _hvac_system_single_speed_ashp_airflow:

HVAC System Single Speed ASHP Airflow
-------------------------------------

Description
***********

Single speed air source heat pump actual air flow rates.

Created by
**********

manually created

Source
******

- \Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``heat_pump_rated_cfm_per_ton``
     - false
     - cfm/ton
     - Double
     -
     - The rated cfm per ton of the heat pump.
   * - ``heat_pump_actual_cfm_per_ton``
     - false
     - cfm/ton
     - Double
     -
     - The actual cfm per ton of the heat pump.

.. _hvac_system_single_speed_ashp_charge:

HVAC System Single Speed ASHP Charge
------------------------------------

Description
***********

Air source heat pump deviation between design/installed charge.

Created by
**********

manually created

Source
******

- \Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``heat_pump_frac_manufacturer_charge``
     - false
     - Frac
     - Double
     -
     - The fraction of manufacturer recommended charge of the heat pump.

.. _has_pv:

Has PV
------

Description
***********

The dwelling unit has a rooftop photovoltaic system.

Created by
**********

``sources/dpv/tsv_maker.py``

Source
******

- \ACS population and RiDER data on PV installation that combines LBNL's 2020 Tracking the Sun and Wood Mackenzie's 2020 Q4 PV report (prepared by Nicholas.Willems@nrel.gov on Jun 22, 2021)


Assumption
**********

- \Imposed an upperbound of 14 kWDC, which contains 95pct of all installations. Counties with source_count<10 are backfilled with aggregates at the State level. Distribution based on all installations is applied only to occupied SFD, actual distribution for SFD may be higher.

- \PV is not modeled in AK and HI. No data has been identified.


.. _heating_fuel:

Heating Fuel
------------

Description
***********

The primary fuel used for heating the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \In ACS, Heating Fuel is reported for occupied units only. By excluding Vacancy Status as adependency, we assume vacant units share the same Heating Fuel distribution as occupied units. Where sample counts are less than 10, the State average distribution has been inserted. Prior to insertion, the following adjustments have been made to the state distribution so all rows have sample count > 10: 1. Where sample counts < 10 (which consists of Mobile Home and Single-Family Attached only), the Vintage ACS distribution is used instead of Vintage: [CT, DE, ID, MD, ME, MT, ND, NE, NH, NV, RI, SD, UT, VT, WY]

- \2. Remaining Mobile Homes < 10 are replaced by Single-Family Detached + Mobile Homes combined: [DE, RI, SD, VT, WY, and all DC].


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``heating_system_fuel``
     - true
     - 
     - Choice
     - "electricity", "natural gas", "fuel oil", "propane", "wood", "wood pellets", "coal"
     - The fuel type of the heating system. Ignored for ElectricResistance.

.. _heating_setpoint:

Heating Setpoint
----------------

Description
***********

Baseline heating setpoint with no offset applied.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK

- \Heating type dependency is always lumped into Heat pump / Non-heat pumps

- \For vacant units (for which Tenure = 'Not Available'), the heating setpoint is set to 55F


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``hvac_control_heating_season_period``
     - false
     - 
     - String
     - "auto"
     - Enter a date like 'Nov 1 - Jun 30'. If not provided, the OS-HPXML default (see `HPXML HVAC Control <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-hvac-control>`_) is used. Can also provide 'BuildingAmerica' to use automatic seasons from the Building America House Simulation Protocols.
   * - ``hvac_control_heating_weekday_setpoint_temp``
     - true
     - deg-F
     - Double
     -
     - Specify the weekday heating setpoint temperature.
   * - ``hvac_control_heating_weekend_setpoint_temp``
     - true
     - deg-F
     - Double
     -
     - Specify the weekend heating setpoint temperature.
   * - ``use_auto_heating_season``
     - true
     - 
     - Boolean
     - "true", "false"
     - Specifies whether to automatically define the heating season based on the weather file.

.. _heating_setpoint_has_offset:

Heating Setpoint Has Offset
---------------------------

Description
***********

Presence of a heating setpoint offset.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only, 2) lumping all building types together


.. _heating_setpoint_offset_magnitude:

Heating Setpoint Offset Magnitude
---------------------------------

Description
***********

Magnitude of the heating setpoint offset.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``hvac_control_heating_weekday_setpoint_offset_magnitude``
     - true
     - deg-F
     - Double
     -
     - Specify the weekday heating offset magnitude.
   * - ``hvac_control_heating_weekend_setpoint_offset_magnitude``
     - true
     - deg-F
     - Double
     -
     - Specify the weekend heating offset magnitude.

.. _heating_setpoint_offset_period:

Heating Setpoint Offset Period
------------------------------

Description
***********

The period and offset for the dwelling unit's heating setpoint. Default for the day is from 9am to 5pm and for the night is 10pm to 7am.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``hvac_control_heating_weekday_setpoint_schedule``
     - true
     - 
     - String
     -
     - Specify the 24-hour comma-separated weekday heating schedule of 0s and 1s.
   * - ``hvac_control_heating_weekend_setpoint_schedule``
     - true
     - 
     - String
     -
     - Specify the 24-hour comma-separated weekend heating schedule of 0s and 1s.

.. _holiday_lighting:

Holiday Lighting
----------------

Description
***********

Use of holiday lighting (not used in project_national).

Created by
**********

manually created

Source
******

- \Not applicable (holiday lighting is not currently modeled separate from other exterior lighting)


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``holiday_lighting_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is holiday lighting.
   * - ``holiday_lighting_daily_kwh``
     - false
     - kWh/day
     - Double
     - "auto"
     - The daily energy consumption for holiday lighting (exterior). If not provided, the OS-HPXML default (see `HPXML Lighting <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-lighting>`_) is used.
   * - ``holiday_lighting_period``
     - false
     - 
     - String
     - "auto"
     - Enter a date like 'Nov 25 - Jan 5'. If not provided, the OS-HPXML default (see `HPXML Lighting <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-lighting>`_) is used.

.. _hot_water_distribution:

Hot Water Distribution
----------------------

Description
***********

Hot water piping material and insulation level.

Created by
**********

manually created

Source
******

- \Engineering Judgement


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``hot_water_distribution_system_type``
     - true
     - 
     - Choice
     - "Standard", "Recirculation"
     - The type of the hot water distribution system.
   * - ``hot_water_distribution_standard_piping_length``
     - false
     - ft
     - Double
     - "auto"
     - If the distribution system is Standard, the length of the piping. If not provided, the OS-HPXML default (see `Standard <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#standard>`_) is used.
   * - ``hot_water_distribution_recirc_control_type``
     - false
     - 
     - Choice
     - "auto", "no control", "timer", "temperature", "presence sensor demand control", "manual demand control"
     - If the distribution system is Recirculation, the type of hot water recirculation control, if any.
   * - ``hot_water_distribution_recirc_piping_length``
     - false
     - ft
     - Double
     - "auto"
     - If the distribution system is Recirculation, the length of the recirculation piping. If not provided, the OS-HPXML default (see `Recirculation <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#recirculation>`_) is used.
   * - ``hot_water_distribution_recirc_branch_piping_length``
     - false
     - ft
     - Double
     - "auto"
     - If the distribution system is Recirculation, the length of the recirculation branch piping. If not provided, the OS-HPXML default (see `Recirculation <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#recirculation>`_) is used.
   * - ``hot_water_distribution_recirc_pump_power``
     - false
     - W
     - Double
     - "auto"
     - If the distribution system is Recirculation, the recirculation pump power. If not provided, the OS-HPXML default (see `Recirculation <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#recirculation>`_) is used.
   * - ``hot_water_distribution_pipe_r``
     - false
     - h-ft^2-R/Btu
     - Double
     - "auto"
     - Nominal R-value of the pipe insulation. If not provided, the OS-HPXML default (see `HPXML Hot Water Distribution <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-hot-water-distribution>`_) is used.
   * - ``dwhr_facilities_connected``
     - true
     - 
     - Choice
     - "none", "one", "all"
     - Which facilities are connected for the drain water heat recovery. Use 'none' if there is no drain water heat recovery system.
   * - ``dwhr_equal_flow``
     - false
     - 
     - Boolean
     - "auto", "true", "false"
     - Whether the drain water heat recovery has equal flow.
   * - ``dwhr_efficiency``
     - false
     - Frac
     - Double
     -
     - The efficiency of the drain water heat recovery.

.. _hot_water_fixtures:

Hot Water Fixtures
------------------

Description
***********

Hot water fixture usage and flow levels.

Created by
**********

manually created

Source
******

- \Engineering Judgement


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``water_fixtures_shower_low_flow``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether the shower fixture is low flow.
   * - ``water_fixtures_sink_low_flow``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether the sink fixture is low flow.
   * - ``water_fixtures_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the hot water usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Water Fixtures <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-water-fixtures>`_) is used.

.. _household_has_tribal_persons:

Household Has Tribal Persons
----------------------------

Description
***********

The houshold occupying the dwelling unit has at least one tribal person in the household.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \2188 / 2336 PUMA has <10 samples and are falling back to state level aggregated values.DC Mobile Homes do not exist and are replaced with Single-Family Detached.


.. _iso_rto_region:

ISO RTO Region
--------------

Description
***********

The independent system operator or regional transmission organization region that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \ISO and RTO regions are from EIA Form 861.


.. _income:

Income
------

Description
***********

Income of the household occupying the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \In ACS, Income and Tenure are reported for occupied units only. Because we assume vacant units share the same Tenure distribution as occupied units, by extension, we assume this Income distribution applies to all units regardless of Vacancy Status. For reference, 57445 / 140160 rows have sampling_probability >= 1/550000. Of those rows, 2961 (5%) were replaced due to low samples in the following process: Where sample counts are less than 10 (79145 / 140160 relevant rows), the Census Division by PUMA Metro Status average distribution has been inserted first (76864), followed by Census Division by 'Metro'/'Non-metro' average distribution (1187), followed by Census Region by PUMA Metro Status average distribution (282), followed by Census Region by 'Metro'/'Non-metro' average distribution (112).


.. _income_recs2015:

Income RECS2015
---------------

Description
***********

Income of the household occupying the dwelling unit that are aligned with the 2015 U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \Income bins aligned with RECS 2015


.. _income_recs2020:

Income RECS2020
---------------

Description
***********

Income of the household occupying the dwelling unit that are aligned with the 2020 U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \Consolidated income bins aligned with RECS 2020


.. _infiltration:

Infiltration
------------

Description
***********

Air leakage rates for the living and garage spaces

Created by
**********

``sources/resdb/tsv_maker.py``

Source
******

- \Distributions are based on the cumulative distribution functions from the Residential Diagnostics Database (ResDB), http://resdb.lbl.gov/.


Assumption
**********

- \All ACH50 are based on Single-Family Detached blower door tests.

- \Climate zones that are copied: 2A to 1A, 6A to 7A, and 6B to 7B.

- \Vintage bins that are copied: 2000s to 2010s, 1950s to 1940s, 1950s to <1940s.

- \Homes are assumed to not be Weatherization Assistance Program (WAP) qualified and not ENERGY STAR certified.

- \Climate zones 7AK and 8AK are averages of 6A and 6B.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``site_shielding_of_home``
     - false
     - 
     - Choice
     - "auto", "exposed", "normal", "well-shielded"
     - Presence of nearby buildings, trees, obstructions for infiltration model. If not provided, the OS-HPXML default (see `HPXML Site <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-site>`_) is used.
   * - ``air_leakage_units``
     - true
     - 
     - Choice
     - "ACH", "CFM", "ACHnatural", "CFMnatural", "EffectiveLeakageArea"
     - The unit of measure for the air leakage.
   * - ``air_leakage_house_pressure``
     - true
     - Pa
     - Double
     -
     - The house pressure relative to outside. Required when units are ACH or CFM.
   * - ``air_leakage_value``
     - true
     - 
     - Double
     -
     - Air exchange rate value. For 'EffectiveLeakageArea', provide value in sq. in.
   * - ``air_leakage_type``
     - false
     - 
     - Choice
     - "auto", "unit total", "unit exterior only"
     - Type of air leakage. If 'unit total', represents the total infiltration to the unit as measured by a compartmentalization test, in which case the air leakage value will be adjusted by the ratio of exterior envelope surface area to total envelope surface area. Otherwise, if 'unit exterior only', represents the infiltration to the unit from outside only as measured by a guarded test. Required when unit type is single-family attached or apartment unit.

.. _insulation_ceiling:

Insulation Ceiling
------------------

Source
******

- \NEEA Residential Building Stock Assessment, 2012

- \Nettleton, G.

- \Edwards, J. (2012). Data Collection-Data Characterization Summary, NorthernSTAR Building America Partnership, Building Technologies Program. Washington, D.C.: U.S. Department of Energy, as described in Roberts et al., 'Assessment of the U.S. Department of Energy's Home Energy Score Tool', 2012, and Merket 'Building America Field Data Repository', Webinar, 2014

- \Derived from Home Innovation Research Labs 1982-2007 Data


Assumption
**********

- \Vented Attic has the same distribution as Unvented Attic

- \CRHI is a copy of CR09

- \CRAK is a copy of CR02


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``ceiling_assembly_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Assembly R-value for the ceiling (attic floor).
   * - ``ceiling_insulation_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Nominal R-value for the ceiling (attic floor).

.. _insulation_floor:

Insulation Floor
----------------

Source
******

- \Derived from Home Innovation Research Labs 1982-2007 Data

- \(pre-1980) Engineering judgment


Assumption
**********

- \CRHI is a copy of CR09

- \CRAK is a copy of CR02


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``floor_over_foundation_assembly_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Assembly R-value for the floor over the foundation. Ignored if the building has a slab-on-grade foundation.
   * - ``floor_over_garage_assembly_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Assembly R-value for the floor over the garage. Ignored unless the building has a garage under conditioned space.
   * - ``floor_type``
     - true
     - 
     - Choice
     - "WoodFrame", "StructuralInsulatedPanel", "SolidConcrete", "SteelFrame"
     - The type of floors.

.. _insulation_foundation_wall:

Insulation Foundation Wall
--------------------------

Source
******

- \Derived from Home Innovation Research Labs 1982-2007 Data

- \(pre-1980) Engineering judgment


Assumption
**********

- \CRHI is a copy of CR09

- \CRAK is a copy of CR02


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``foundation_wall_type``
     - false
     - 
     - Choice
     - "auto", "solid concrete", "concrete block", "concrete block foam core", "concrete block perlite core", "concrete block vermiculite core", "concrete block solid core", "double brick", "wood"
     - The material type of the foundation wall. If not provided, the OS-HPXML default (see `HPXML Foundation Walls <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-foundation-walls>`_) is used.
   * - ``foundation_wall_thickness``
     - false
     - in
     - Double
     - "auto"
     - The thickness of the foundation wall. If not provided, the OS-HPXML default (see `HPXML Foundation Walls <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-foundation-walls>`_) is used.
   * - ``foundation_wall_insulation_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Nominal R-value for the foundation wall insulation. Only applies to basements/crawlspaces.
   * - ``foundation_wall_insulation_location``
     - false
     - ft
     - Choice
     - "auto", "interior", "exterior"
     - Whether the insulation is on the interior or exterior of the foundation wall. Only applies to basements/crawlspaces.
   * - ``foundation_wall_insulation_distance_to_top``
     - false
     - ft
     - Double
     - "auto"
     - The distance from the top of the foundation wall to the top of the foundation wall insulation. Only applies to basements/crawlspaces. If not provided, the OS-HPXML default (see `HPXML Foundation Walls <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-foundation-walls>`_) is used.
   * - ``foundation_wall_insulation_distance_to_bottom``
     - false
     - ft
     - Double
     - "auto"
     - The distance from the top of the foundation wall to the bottom of the foundation wall insulation. Only applies to basements/crawlspaces. If not provided, the OS-HPXML default (see `HPXML Foundation Walls <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-foundation-walls>`_) is used.
   * - ``foundation_wall_assembly_r``
     - false
     - h-ft^2-R/Btu
     - Double
     -
     - Assembly R-value for the foundation walls. Only applies to basements/crawlspaces. If provided, overrides the previous foundation wall insulation inputs. If not provided, it is ignored.

.. _insulation_rim_joist:

Insulation Rim Joist
--------------------

Description
***********

Insulation level for rim joists.

Created by
**********

manually created

Source
******

- \Engineering Judgement


Assumption
**********

- \Rim joist insulation is the same value as the foundation wall insulation.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``rim_joist_assembly_r``
     - false
     - h-ft^2-R/Btu
     - Double
     -
     - Assembly R-value for the rim joists. Only applies to basements/crawlspaces. Required if a rim joist height is provided.
   * - ``rim_joist_continuous_exterior_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Nominal R-value for the rim joist continuous exterior insulation. Only applies to basements/crawlspaces.
   * - ``rim_joist_continuous_interior_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Nominal R-value for the rim joist continuous interior insulation that runs parallel to floor joists. Only applies to basements/crawlspaces.
   * - ``rim_joist_assembly_interior_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Assembly R-value for the rim joist assembly interior insulation that runs perpendicular to floor joists. Only applies to basements/crawlspaces.

.. _insulation_roof:

Insulation Roof
---------------

Description
***********

Finished roof insulation level.

Created by
**********

manually created

Source
******

- \Derived from Home Innovation Research Labs 1982-2007 Data

- \NEEA Residential Building Stock Assessment, 2012


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``roof_assembly_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Assembly R-value of the roof.

.. _insulation_slab:

Insulation Slab
---------------

Description
***********

Slab insulation level.

Created by
**********

manually created

Source
******

- \Derived from Home Innovation Research Labs 1982-2007 Data

- \(pre-1980) Engineering judgment


Assumption
**********

- \CRHI is a copy of CR09

- \CRAK is a copy of CR02


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``slab_perimeter_insulation_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Nominal R-value of the vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.
   * - ``slab_perimeter_depth``
     - true
     - ft
     - Double
     -
     - Depth from grade to bottom of vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.
   * - ``slab_under_insulation_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Nominal R-value of the horizontal under slab insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.
   * - ``slab_under_width``
     - true
     - ft
     - Double
     -
     - Width from slab edge inward of horizontal under-slab insulation. Enter 999 to specify that the under slab insulation spans the entire slab. Applies to slab-on-grade foundations and basement/crawlspace floors.
   * - ``slab_thickness``
     - false
     - in
     - Double
     - "auto"
     - The thickness of the slab. Zero can be entered if there is a dirt floor instead of a slab. If not provided, the OS-HPXML default (see `HPXML Slabs <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-slabs>`_) is used.
   * - ``slab_carpet_fraction``
     - false
     - Frac
     - Double
     - "auto"
     - Fraction of the slab floor area that is carpeted. If not provided, the OS-HPXML default (see `HPXML Slabs <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-slabs>`_) is used.
   * - ``slab_carpet_r``
     - false
     - h-ft^2-R/Btu
     - Double
     - "auto"
     - R-value of the slab carpet. If not provided, the OS-HPXML default (see `HPXML Slabs <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-slabs>`_) is used.

.. _insulation_wall:

Insulation Wall
---------------

Description
***********

Wall construction type and insulation level.

Created by
**********

manually created

Source
******

- \Ritschard et al. Single-Family Heating and Cooling Requirements: Assumptions, Methods, and Summary Results 1992

- \Nettleton, G.

- \Edwards, J. (2012). Data Collection-Data Characterization Summary, NorthernSTAR Building America Partnership, Building Technologies Program. Washington, D.C.: U.S. Department of Energy, as described in Roberts et al., 'Assessment of the U.S. Department of Energy's Home Energy Score Tool', 2012, and Merket Building America Field Data Repository, Webinar, 2014


Assumption
**********

- \Updated per new wall type from Lightbox, all wall type-specific distributions follow that of `Wood Frame` (`WoodStud`)


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``wall_type``
     - true
     - 
     - Choice
     - "WoodStud", "ConcreteMasonryUnit", "DoubleWoodStud", "InsulatedConcreteForms", "LogWall", "StructuralInsulatedPanel", "SolidConcrete", "SteelFrame", "Stone", "StrawBale", "StructuralBrick"
     - The type of walls.
   * - ``wall_assembly_r``
     - true
     - h-ft^2-R/Btu
     - Double
     -
     - Assembly R-value of the walls.

.. _interior_shading:

Interior Shading
----------------

Description
***********

Fraction of window shading in the summer and winter.

Created by
**********

manually created

Source
******

- \ANSI/RESNET/ICC 301 Standard


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``window_interior_shading_winter``
     - false
     - Frac
     - Double
     - "auto"
     - Interior shading coefficient for the winter season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc. If not provided, the OS-HPXML default (see `HPXML Windows <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-windows>`_) is used.
   * - ``window_interior_shading_summer``
     - false
     - Frac
     - Double
     - "auto"
     - Interior shading coefficient for the summer season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc. If not provided, the OS-HPXML default (see `HPXML Windows <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-windows>`_) is used.

.. _lighting:

Lighting
--------

Created by
**********

``sources/recs/2015/tsv_maker.py``

Source
******

- \U.S. EIA 2015 Residential Energy Consumption Survey (RECS) microdata.

- \2019 Energy Savings Forecast of Solid-State Lighting in General Illumination Applications. https://www.energy.gov/sites/prod/files/2019/12/f69/2019_ssl-energy-savings-forecast.pdf


Assumption
**********

- \Qualitative lamp type fractions in each household surveyed are distributed to three options representing 100% incandescent, 100% CFl, and 100% LED lamp type options.

- \Due to low sample sizes for some Building Types, Building Type data are grouped into: 1) Single-Family Detached and Mobile Homes, and 2) Multifamily 2-4 units and Multifamily 5+ units, and 3) Single-Family Attached.

- \Single-Family Attached units in the West South Central census division has the same LED saturation as Multi-Family

- \LED saturation is adjusted to match the U.S. projected saturation in the 2019 Energy Savings Forecast of Solid-State Lighting in General Illumination Applications.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``lighting_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is lighting energy use.
   * - ``lighting_interior_fraction_cfl``
     - true
     - 
     - Double
     -
     - Fraction of all lamps (interior) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_interior_fraction_lfl``
     - true
     - 
     - Double
     -
     - Fraction of all lamps (interior) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_interior_fraction_led``
     - true
     - 
     - Double
     -
     - Fraction of all lamps (interior) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_exterior_fraction_cfl``
     - true
     - 
     - Double
     -
     - Fraction of all lamps (exterior) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_exterior_fraction_lfl``
     - true
     - 
     - Double
     -
     - Fraction of all lamps (exterior) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_exterior_fraction_led``
     - true
     - 
     - Double
     -
     - Fraction of all lamps (exterior) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_garage_fraction_cfl``
     - true
     - 
     - Double
     -
     - Fraction of all lamps (garage) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_garage_fraction_lfl``
     - true
     - 
     - Double
     -
     - Fraction of all lamps (garage) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.
   * - ``lighting_garage_fraction_led``
     - true
     - 
     - Double
     -
     - Fraction of all lamps (garage) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

.. _lighting_interior_use:

Lighting Interior Use
---------------------

Description
***********

Interior lighting usage relative to the national average.

Created by
**********

manually created

Source
******

- \Not applicable

- \this parameter for adding diversity to lighting usage patterns is not currently used.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``lighting_interior_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the lighting energy usage (interior) that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Lighting <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-lighting>`_) is used.

.. _lighting_other_use:

Lighting Other Use
------------------

Description
***********

Exterior and garage lighting usage relative to the national average.

Created by
**********

manually created

Source
******

- \Not applicable

- \this parameter for adding diversity to lighting usage patterns is not currently used.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``lighting_exterior_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the lighting energy usage (exterior) that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Lighting <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-lighting>`_) is used.
   * - ``lighting_garage_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the lighting energy usage (garage) that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Lighting <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-lighting>`_) is used.

.. _location_region:

Location Region
---------------

Description
***********

A custom ResStock region constructed of RECS 2009 reportable domains that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Custom region map located https://github.com/NREL/resstock/wiki/Custom-Region-(CR)-Map


.. _mechanical_ventilation:

Mechanical Ventilation
----------------------

Description
***********

Mechanical ventilation type and efficiency.

Created by
**********

manually created

Source
******

- \Engineering Judgement


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``mech_vent_fan_type``
     - true
     - 
     - Choice
     - "none", "exhaust only", "supply only", "energy recovery ventilator", "heat recovery ventilator", "balanced", "central fan integrated supply"
     - The type of the mechanical ventilation. Use 'none' if there is no mechanical ventilation system.
   * - ``mech_vent_flow_rate``
     - false
     - CFM
     - Double
     - "auto"
     - The flow rate of the mechanical ventilation. If not provided, the OS-HPXML default (see `Whole Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#whole-ventilation-fan>`_) is used.
   * - ``mech_vent_hours_in_operation``
     - false
     - hrs/day
     - Double
     - "auto"
     - The hours in operation of the mechanical ventilation. If not provided, the OS-HPXML default (see `Whole Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#whole-ventilation-fan>`_) is used.
   * - ``mech_vent_recovery_efficiency_type``
     - true
     - 
     - Choice
     - "Unadjusted", "Adjusted"
     - The total recovery efficiency type of the mechanical ventilation.
   * - ``mech_vent_total_recovery_efficiency``
     - true
     - Frac
     - Double
     -
     - The Unadjusted or Adjusted total recovery efficiency of the mechanical ventilation. Applies to energy recovery ventilator.
   * - ``mech_vent_sensible_recovery_efficiency``
     - true
     - Frac
     - Double
     -
     - The Unadjusted or Adjusted sensible recovery efficiency of the mechanical ventilation. Applies to energy recovery ventilator and heat recovery ventilator.
   * - ``mech_vent_fan_power``
     - false
     - W
     - Double
     - "auto"
     - The fan power of the mechanical ventilation. If not provided, the OS-HPXML default (see `Whole Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#whole-ventilation-fan>`_) is used.
   * - ``mech_vent_num_units_served``
     - true
     - #
     - Integer
     -
     - Number of dwelling units served by the mechanical ventilation system. Must be 1 if single-family detached. Used to apportion flow rate and fan power to the unit.
   * - ``mech_vent_shared_frac_recirculation``
     - false
     - Frac
     - Double
     -
     - Fraction of the total supply air that is recirculated, with the remainder assumed to be outdoor air. The value must be 0 for exhaust only systems. Required for a shared mechanical ventilation system.
   * - ``mech_vent_shared_preheating_fuel``
     - false
     - 
     - Choice
     - "auto", "electricity", "natural gas", "fuel oil", "propane", "wood", "wood pellets", "coal"
     - Fuel type of the preconditioning heating equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no preheating.
   * - ``mech_vent_shared_preheating_efficiency``
     - false
     - COP
     - Double
     -
     - Efficiency of the preconditioning heating equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no preheating.
   * - ``mech_vent_shared_preheating_fraction_heat_load_served``
     - false
     - Frac
     - Double
     -
     - Fraction of heating load introduced by the shared ventilation system that is met by the preconditioning heating equipment. If not provided, assumes no preheating.
   * - ``mech_vent_shared_precooling_fuel``
     - false
     - 
     - Choice
     - "auto", "electricity"
     - Fuel type of the preconditioning cooling equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no precooling.
   * - ``mech_vent_shared_precooling_efficiency``
     - false
     - COP
     - Double
     -
     - Efficiency of the preconditioning cooling equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no precooling.
   * - ``mech_vent_shared_precooling_fraction_cool_load_served``
     - false
     - Frac
     - Double
     -
     - Fraction of cooling load introduced by the shared ventilation system that is met by the preconditioning cooling equipment. If not provided, assumes no precooling.
   * - ``mech_vent_2_fan_type``
     - true
     - 
     - Choice
     - "none", "exhaust only", "supply only", "energy recovery ventilator", "heat recovery ventilator", "balanced"
     - The type of the second mechanical ventilation. Use 'none' if there is no second mechanical ventilation system.
   * - ``mech_vent_2_flow_rate``
     - true
     - CFM
     - Double
     -
     - The flow rate of the second mechanical ventilation.
   * - ``mech_vent_2_hours_in_operation``
     - true
     - hrs/day
     - Double
     -
     - The hours in operation of the second mechanical ventilation.
   * - ``mech_vent_2_recovery_efficiency_type``
     - true
     - 
     - Choice
     - "Unadjusted", "Adjusted"
     - The total recovery efficiency type of the second mechanical ventilation.
   * - ``mech_vent_2_total_recovery_efficiency``
     - true
     - Frac
     - Double
     -
     - The Unadjusted or Adjusted total recovery efficiency of the second mechanical ventilation. Applies to energy recovery ventilator.
   * - ``mech_vent_2_sensible_recovery_efficiency``
     - true
     - Frac
     - Double
     -
     - The Unadjusted or Adjusted sensible recovery efficiency of the second mechanical ventilation. Applies to energy recovery ventilator and heat recovery ventilator.
   * - ``mech_vent_2_fan_power``
     - true
     - W
     - Double
     -
     - The fan power of the second mechanical ventilation.
   * - ``whole_house_fan_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a whole house fan.
   * - ``whole_house_fan_flow_rate``
     - false
     - CFM
     - Double
     - "auto"
     - The flow rate of the whole house fan. If not provided, the OS-HPXML default (see `Whole House Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#whole-house-fan>`_) is used.
   * - ``whole_house_fan_power``
     - false
     - W
     - Double
     - "auto"
     - The fan power of the whole house fan. If not provided, the OS-HPXML default (see `Whole House Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#whole-house-fan>`_) is used.

.. _misc_extra_refrigerator:

Misc Extra Refrigerator
-----------------------

Description
***********

The presence and rated efficiency of the secondary refrigerator.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Age of refrigerator converted to efficiency levels using ENERGYSTAR shipment-weighted efficiencies by year data from Home Energy Score: http://hes-documentation.lbl.gov/. Check the comments in: HES-Refrigerator_Age_vs_Efficiency.tsv


Assumption
**********

- \The current year is assumed to be 2022

- \Previously, for each year, the EF values were rounded to the nearest EF level, and then the distribution of EF levels were calculated for the age bins. Currently, each year has its own distribution and then we average out the distributions to get the distribution for the age bins. EF for all years are weighted equally when calculating the average distribution for the age bins.

- \EnergyStar distributions from 2009 dependent on [Geometry Building Type RECS,Federal Poverty Level,Tenure] is used to calculate efficiency distribution in RECS2020.EnergyStar Refrigerators assumed to be 10% more efficient than standard.Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Vintage'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Vintage with Vintage ACS

  - \[5] Vintage with combined 1960s

  - \[6] Vintage with combined 1960s and post 200ss

  - \[7] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[8] Census Division RECS to Census Region

  - \[9] Census Region to National

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across ('Heating Fuel', ['Tenure', 'Federal Poverty Level']).


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``extra_refrigerator_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is an extra refrigerator present.
   * - ``extra_refrigerator_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space"
     - The space type for the extra refrigerator location. If not provided, the OS-HPXML default (see `HPXML Refrigerators <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-refrigerators>`_) is used.
   * - ``extra_refrigerator_rated_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The EnergyGuide rated annual energy consumption for an extra rrefrigerator. If not provided, the OS-HPXML default (see `HPXML Refrigerators <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-refrigerators>`_) is used.
   * - ``extra_refrigerator_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the extra refrigerator energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Refrigerators <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-refrigerators>`_) is used.

.. _misc_freezer:

Misc Freezer
------------

Description
***********

The presence and rated efficiency of a standalone freezer.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \The national average EF is 12 based on the 2014 BA house simulation protocols

- \Due to low sample count, the tsv is constructed with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``freezer_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a freezer present.
   * - ``freezer_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space"
     - The space type for the freezer location. If not provided, the OS-HPXML default (see `HPXML Freezers <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-freezers>`_) is used.
   * - ``freezer_rated_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The EnergyGuide rated annual energy consumption for a freezer. If not provided, the OS-HPXML default (see `HPXML Freezers <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-freezers>`_) is used.
   * - ``freezer_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the freezer energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Freezers <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-freezers>`_) is used.

.. _misc_gas_fireplace:

Misc Gas Fireplace
------------------

Description
***********

Presence of a gas fireplace.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``misc_fuel_loads_fireplace_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is fuel loads fireplace.
   * - ``misc_fuel_loads_fireplace_fuel_type``
     - true
     - 
     - Choice
     - "natural gas", "fuel oil", "propane", "wood", "wood pellets"
     - The fuel type of the fuel loads fireplace.
   * - ``misc_fuel_loads_fireplace_annual_therm``
     - false
     - therm/yr
     - Double
     - "auto"
     - The annual energy consumption of the fuel loads fireplace. If not provided, the OS-HPXML default (see `HPXML Fuel Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-fuel-loads>`_) is used.
   * - ``misc_fuel_loads_fireplace_frac_sensible``
     - false
     - Frac
     - Double
     - "auto"
     - Fraction of fireplace residual fuel loads' internal gains that are sensible. If not provided, the OS-HPXML default (see `HPXML Fuel Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-fuel-loads>`_) is used.
   * - ``misc_fuel_loads_fireplace_frac_latent``
     - false
     - Frac
     - Double
     - "auto"
     - Fraction of fireplace residual fuel loads' internal gains that are latent. If not provided, the OS-HPXML default (see `HPXML Fuel Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-fuel-loads>`_) is used.
   * - ``misc_fuel_loads_fireplace_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the fuel loads fireplace energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Fuel Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-fuel-loads>`_) is used.

.. _misc_gas_grill:

Misc Gas Grill
--------------

Description
***********

Presence of a gas grill.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``misc_fuel_loads_grill_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a fuel loads grill.
   * - ``misc_fuel_loads_grill_fuel_type``
     - true
     - 
     - Choice
     - "natural gas", "fuel oil", "propane", "wood", "wood pellets"
     - The fuel type of the fuel loads grill.
   * - ``misc_fuel_loads_grill_annual_therm``
     - false
     - therm/yr
     - Double
     - "auto"
     - The annual energy consumption of the fuel loads grill. If not provided, the OS-HPXML default (see `HPXML Fuel Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-fuel-loads>`_) is used.
   * - ``misc_fuel_loads_grill_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the fuel loads grill energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Fuel Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-fuel-loads>`_) is used.

.. _misc_gas_lighting:

Misc Gas Lighting
-----------------

Description
***********

Presence of exterior gas lighting.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``misc_fuel_loads_lighting_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is fuel loads lighting.
   * - ``misc_fuel_loads_lighting_fuel_type``
     - true
     - 
     - Choice
     - "natural gas", "fuel oil", "propane", "wood", "wood pellets"
     - The fuel type of the fuel loads lighting.
   * - ``misc_fuel_loads_lighting_annual_therm``
     - false
     - therm/yr
     - Double
     - "auto"
     - The annual energy consumption of the fuel loads lighting. If not provided, the OS-HPXML default (see `HPXML Fuel Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-fuel-loads>`_)is used.
   * - ``misc_fuel_loads_lighting_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the fuel loads lighting energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Fuel Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-fuel-loads>`_) is used.

.. _misc_hot_tub_spa:

Misc Hot Tub Spa
----------------

Description
***********

The presence and heating fuel of a hot tub/spa at the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:

- \Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Heating Fuel'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Heating Fuel coarsened to Other Fuel and Propane combined

  - \[3] Heating Fuel coarsened to Fuel Oil, Other Fuel, and Propane combined

  - \[4] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[5] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National

- \Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[7] Census Division RECS to Census Region

  - \[8] Census Region to National

- \In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across ('Heating Fuel', ['Tenure', 'Federal Poverty Level']).


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``permanent_spa_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a permanent spa.
   * - ``permanent_spa_pump_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The annual energy consumption of the permanent spa pump. If not provided, the OS-HPXML default (see `Permanent Spa Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#permanent-spa-pump>`_) is used.
   * - ``permanent_spa_pump_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the permanent spa pump energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `Permanent Spa Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#permanent-spa-pump>`_) is used.
   * - ``permanent_spa_heater_type``
     - true
     - 
     - Choice
     - "none", "electric resistance", "gas fired", "heat pump"
     - The type of permanent spa heater. Use 'none' if there is no permanent spa heater.
   * - ``permanent_spa_heater_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The annual energy consumption of the electric resistance permanent spa heater. If not provided, the OS-HPXML default (see `Permanent Spa Heater <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#permanent-spa-heater>`_) is used.
   * - ``permanent_spa_heater_annual_therm``
     - false
     - therm/yr
     - Double
     - "auto"
     - The annual energy consumption of the gas fired permanent spa heater. If not provided, the OS-HPXML default (see `Permanent Spa Heater <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#permanent-spa-heater>`_) is used.
   * - ``permanent_spa_heater_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the permanent spa heater energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `Permanent Spa Heater <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#permanent-spa-heater>`_) is used.

.. _misc_pool:

Misc Pool
---------

Description
***********

The presence of a pool at the dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \The only valid option for multi-family homes is Nonesince the pool is most likely to be jointly ownedDue to low sample count, the tsv is constructed with the followingfallback coarsening order

  - \[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Federal Poverty Level coarsened every 100 percent

  - \[5] Federal Poverty Level coarsened every 200 percent

  - \[6] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently

  - \[7] Vintage homes built before 1960 coarsened to pre1960

  - \[8] Vintage homes built after 2000 coarsened to 2000-20

  - \[9] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[10] Census Division RECS to Census Region

  - \[11] Census Region to National


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``pool_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a pool.

.. _misc_pool_heater:

Misc Pool Heater
----------------

Description
***********

The heating fuel of the pool heater if there is a pool.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``pool_heater_type``
     - true
     - 
     - Choice
     - "none", "electric resistance", "gas fired", "heat pump"
     - The type of pool heater. Use 'none' if there is no pool heater.
   * - ``pool_heater_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The annual energy consumption of the electric resistance pool heater. If not provided, the OS-HPXML default (see `Pool Heater <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#pool-heater>`_) is used.
   * - ``pool_heater_annual_therm``
     - false
     - therm/yr
     - Double
     - "auto"
     - The annual energy consumption of the gas fired pool heater. If not provided, the OS-HPXML default (see `Pool Heater <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#pool-heater>`_) is used.
   * - ``pool_heater_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the pool heater energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `Pool Heater <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#pool-heater>`_) is used.

.. _misc_pool_pump:

Misc Pool Pump
--------------

Description
***********

Presence and size of pool pump.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``pool_pump_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The annual energy consumption of the pool pump. If not provided, the OS-HPXML default (see `Pool Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#pool-pump>`_) is used.
   * - ``pool_pump_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the pool pump energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `Pool Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#pool-pump>`_) is used.

.. _misc_well_pump:

Misc Well Pump
--------------

Description
***********

Presence and efficiency of well pump.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``misc_plug_loads_well_pump_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a well pump.
   * - ``misc_plug_loads_well_pump_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The annual energy consumption of the well pump plug loads. If not provided, the OS-HPXML default (see `HPXML Plug Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-plug-loads>`_) is used.
   * - ``misc_plug_loads_well_pump_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the well pump energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Plug Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-plug-loads>`_) is used.
   * - ``misc_plug_loads_well_pump_2_usage_multiplier``
     - true
     - 
     - Double
     -
     - Additional multiplier on the well pump energy usage that can reflect, e.g., high/low usage occupants.

.. _natural_ventilation:

Natural Ventilation
-------------------

Description
***********

Schedule of natural ventilation from windows.

Created by
**********

manually created

Source
******

- \Wilson et al. 'Building America House Simulation Protocols' 2014


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``window_fraction_operable``
     - false
     - Frac
     - Double
     - "auto"
     - Fraction of windows that are operable. If not provided, the OS-HPXML default (see `HPXML Windows <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-windows>`_) is used.

.. _neighbors:

Neighbors
---------

Description
***********

Presence and distance between the dwelling unit and the nearest neighbors to the left and right.

Created by
**********

manually created

Source
******

- \OpenStreetMap data queried by Radiant Labs for Multi-Family and Single-Family Attached

- \Engineering Judgement for others


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``neighbor_front_distance``
     - true
     - ft
     - Double
     -
     - The distance between the unit and the neighboring building to the front (not including eaves). A value of zero indicates no neighbors. Used for shading.
   * - ``neighbor_back_distance``
     - true
     - ft
     - Double
     -
     - The distance between the unit and the neighboring building to the back (not including eaves). A value of zero indicates no neighbors. Used for shading.
   * - ``neighbor_left_distance``
     - true
     - ft
     - Double
     -
     - The distance between the unit and the neighboring building to the left (not including eaves). A value of zero indicates no neighbors. Used for shading.
   * - ``neighbor_right_distance``
     - true
     - ft
     - Double
     -
     - The distance between the unit and the neighboring building to the right (not including eaves). A value of zero indicates no neighbors. Used for shading.
   * - ``neighbor_front_height``
     - false
     - ft
     - Double
     - "auto"
     - The height of the neighboring building to the front. If not provided, the OS-HPXML default (see `HPXML Site <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-site>`_) is used.
   * - ``neighbor_back_height``
     - false
     - ft
     - Double
     - "auto"
     - The height of the neighboring building to the back. If not provided, the OS-HPXML default (see `HPXML Site <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-site>`_) is used.
   * - ``neighbor_left_height``
     - false
     - ft
     - Double
     - "auto"
     - The height of the neighboring building to the left. If not provided, the OS-HPXML default (see `HPXML Site <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-site>`_) is used.
   * - ``neighbor_right_height``
     - false
     - ft
     - Double
     - "auto"
     - The height of the neighboring building to the right. If not provided, the OS-HPXML default (see `HPXML Site <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-site>`_) is used.

.. _occupants:

Occupants
---------

Description
***********

The number of occupants living in the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \Option=10+ has a (weighted) representative value of 11. In ACS, Income, Tenure, and Occupants are reported for occupied units only. Because we assume vacant units share the same Income and Tenure distributions as occupied units, by extension, we assume this Occupants distribution applies to all units regardless of Vacancy Status. Where sample counts are less than 10 (6243 / 18000 rows), the Census Region average distribution has been inserted first (2593), followed by national average distribution (2678), followed by national + 'MF'/'SF' average distribution (252), followed by national + 'MF'/'SF' + 'Metro'/'Non-metro' average distribution (315)followed by national + 'MF'/'SF' + 'Metro'/'Non-metro' + Vacancy Status average distribution (657).


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_unit_num_occupants``
     - false
     - #
     - Double
     -
     - The number of occupants in the unit. If not provided, an *asset* calculation is performed assuming standard occupancy, in which various end use defaults (e.g., plug loads, appliances, and hot water usage) are calculated based on Number of Bedrooms and Conditioned Floor Area per ANSI/RESNET/ICC 301-2019. If provided, an *operational* calculation is instead performed in which the end use defaults are adjusted using the relationship between Number of Bedrooms and Number of Occupants from RECS 2015.

.. _orientation:

Orientation
-----------

Description
***********

Orientation of the front of the dwelling unit as it faces the street.

Created by
**********

manually created

Source
******

- \OpenStreetMap data queried by Radiant Labs.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``geometry_unit_orientation``
     - true
     - degrees
     - Double
     -
     - The unit's orientation is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).

.. _overhangs:

Overhangs
---------

Description
***********

Presence, depth, and location of window overhangs (not used in project_national).

Created by
**********

manually created

Source
******

- \Not applicable

- \all homes are assumed to not have window overhangs other than eaves.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``overhangs_front_depth``
     - true
     - ft
     - Double
     -
     - The depth of overhangs for windows for the front facade.
   * - ``overhangs_front_distance_to_top_of_window``
     - true
     - ft
     - Double
     -
     - The overhangs distance to the top of window for the front facade.
   * - ``overhangs_front_distance_to_bottom_of_window``
     - true
     - ft
     - Double
     -
     - The overhangs distance to the bottom of window for the front facade.
   * - ``overhangs_back_depth``
     - true
     - ft
     - Double
     -
     - The depth of overhangs for windows for the back facade.
   * - ``overhangs_back_distance_to_top_of_window``
     - true
     - ft
     - Double
     -
     - The overhangs distance to the top of window for the back facade.
   * - ``overhangs_back_distance_to_bottom_of_window``
     - true
     - ft
     - Double
     -
     - The overhangs distance to the bottom of window for the back facade.
   * - ``overhangs_left_depth``
     - true
     - ft
     - Double
     -
     - The depth of overhangs for windows for the left facade.
   * - ``overhangs_left_distance_to_top_of_window``
     - true
     - ft
     - Double
     -
     - The overhangs distance to the top of window for the left facade.
   * - ``overhangs_left_distance_to_bottom_of_window``
     - true
     - ft
     - Double
     -
     - The overhangs distance to the bottom of window for the left facade.
   * - ``overhangs_right_depth``
     - true
     - ft
     - Double
     -
     - The depth of overhangs for windows for the right facade.
   * - ``overhangs_right_distance_to_top_of_window``
     - true
     - ft
     - Double
     -
     - The overhangs distance to the top of window for the right facade.
   * - ``overhangs_right_distance_to_bottom_of_window``
     - true
     - ft
     - Double
     -
     - The overhangs distance to the bottom of window for the right facade.

.. _puma:

PUMA
----

Description
***********

The Public Use Microdata Area from 2010 U.S. Census that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


.. _puma_metro_status:

PUMA Metro Status
-----------------

Description
***********

The public use microdata area metropolitan status that the dwelling unit is located.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \'PUMA Metro Status', derived from ACS IPUMS METRO codes, indicates whether the household resided within a metropolitan area and, for households in metropolitan areas, whether the household resided within or outside of a central/principal city. Each PUMA has a unique METRO status in ACS and therefore has a unique PUMA Metro Status. IPUMS derives METRO codes for samples not directly identified based on available geographic information and whether the associated county group or PUMA lies wholly or only partially within metropolitan areas or principal cities.


.. _pv_orientation:

PV Orientation
--------------

Description
***********

The orientation of the photovoltaic system.

Created by
**********

``sources/dpv/tsv_maker.py``

Source
******

- \LBNL's 2020 Tracking the Sun (TTS).


Assumption
**********

- \PV orientation mapped based on azimuth angle of primary array (180 deg is South-facing).


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``pv_system_array_azimuth``
     - true
     - degrees
     - Double
     -
     - Array azimuth of the PV system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).
   * - ``pv_system_2_array_azimuth``
     - true
     - degrees
     - Double
     -
     - Array azimuth of the second PV system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).

.. _pv_system_size:

PV System Size
--------------

Description
***********

The size of the photovoltaic system.

Created by
**********

``sources/dpv/tsv_maker.py``

Source
******

- \LBNL's 2020 Tracking the Sun (TTS).


Assumption
**********

- \Installations of unknown mount type are assumed rooftop. States without data are backfilled with aggregates at the Census Region. 'East South Central' assumed the same distribution as 'West South Central'.

- \PV is not modeled in AK and HI. The Option=None is set so that an error is thrown if PV is modeled as an argument will be missing.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``pv_system_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a PV system present.
   * - ``pv_system_module_type``
     - false
     - 
     - Choice
     - "auto", "standard", "premium", "thin film"
     - Module type of the PV system. If not provided, the OS-HPXML default (see `HPXML Photovoltaics <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-photovoltaics>`_) is used.
   * - ``pv_system_location``
     - false
     - 
     - Choice
     - "auto", "roof", "ground"
     - Location of the PV system. If not provided, the OS-HPXML default (see `HPXML Photovoltaics <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-photovoltaics>`_) is used.
   * - ``pv_system_tracking``
     - false
     - 
     - Choice
     - "auto", "fixed", "1-axis", "1-axis backtracked", "2-axis"
     - Type of tracking for the PV system. If not provided, the OS-HPXML default (see `HPXML Photovoltaics <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-photovoltaics>`_) is used.
   * - ``pv_system_array_tilt``
     - true
     - degrees
     - String
     -
     - Array tilt of the PV system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.
   * - ``pv_system_max_power_output``
     - true
     - W
     - Double
     -
     - Maximum power output of the PV system. For a shared system, this is the total building maximum power output.
   * - ``pv_system_inverter_efficiency``
     - false
     - Frac
     - Double
     - "auto"
     - Inverter efficiency of the PV system. If there are two PV systems, this will apply to both. If not provided, the OS-HPXML default (see `HPXML Photovoltaics <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-photovoltaics>`_) is used.
   * - ``pv_system_system_losses_fraction``
     - false
     - Frac
     - Double
     - "auto"
     - System losses fraction of the PV system. If there are two PV systems, this will apply to both. If not provided, the OS-HPXML default (see `HPXML Photovoltaics <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-photovoltaics>`_) is used.
   * - ``pv_system_2_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a second PV system present.
   * - ``pv_system_2_module_type``
     - false
     - 
     - Choice
     - "auto", "standard", "premium", "thin film"
     - Module type of the second PV system. If not provided, the OS-HPXML default (see `HPXML Photovoltaics <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-photovoltaics>`_) is used.
   * - ``pv_system_2_location``
     - false
     - 
     - Choice
     - "auto", "roof", "ground"
     - Location of the second PV system. If not provided, the OS-HPXML default (see `HPXML Photovoltaics <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-photovoltaics>`_) is used.
   * - ``pv_system_2_tracking``
     - false
     - 
     - Choice
     - "auto", "fixed", "1-axis", "1-axis backtracked", "2-axis"
     - Type of tracking for the second PV system. If not provided, the OS-HPXML default (see `HPXML Photovoltaics <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-photovoltaics>`_) is used.
   * - ``pv_system_2_array_tilt``
     - true
     - degrees
     - String
     -
     - Array tilt of the second PV system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.
   * - ``pv_system_2_max_power_output``
     - true
     - W
     - Double
     -
     - Maximum power output of the second PV system. For a shared system, this is the total building maximum power output.

.. _plug_load_diversity:

Plug Load Diversity
-------------------

Description
***********

Plug load diversity multiplier intended to add variation in plug load profiles across all simulations.

Created by
**********

manually created

Source
******

- \Engineering Judgement, Calibration


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``misc_plug_loads_other_2_usage_multiplier``
     - true
     - 
     - Double
     -
     - Additional multiplier on the other energy usage that can reflect, e.g., high/low usage occupants.

.. _plug_loads:

Plug Loads
----------

Description
***********

Plug load usage level which is varied by Census Division RECS and Building Type RECS.

Created by
**********

``sources/recs/recs2015/tsv_maker.py``

Source
******

- \U.S. EIA 2015 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Multipliers are based on ratio of the ResStock MELS regression equations and the MELS modeled in RECS.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``misc_plug_loads_television_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there are televisions.
   * - ``misc_plug_loads_other_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The annual energy consumption of the other residual plug loads. If not provided, the OS-HPXML default (see `HPXML Plug Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-plug-loads>`_) is used.
   * - ``misc_plug_loads_other_frac_sensible``
     - false
     - Frac
     - Double
     - "auto"
     - Fraction of other residual plug loads' internal gains that are sensible. If not provided, the OS-HPXML default (see `HPXML Plug Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-plug-loads>`_) is used.
   * - ``misc_plug_loads_other_frac_latent``
     - false
     - Frac
     - Double
     - "auto"
     - Fraction of other residual plug loads' internal gains that are latent. If not provided, the OS-HPXML default (see `HPXML Plug Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-plug-loads>`_) is used.
   * - ``misc_plug_loads_other_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the other energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Plug Loads <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-plug-loads>`_) is used.

.. _reeds_balancing_area:

REEDS Balancing Area
--------------------

Description
***********

The Regional Energy Deployment System Model (ReEDS) balancing area that the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.

- \Brown, Maxwell, Wesley Cole, Kelly Eurek, Jon Becker, David Bielen, Ilya Chernyakhovskiy, Stuart Cohen et al. 2020. Regional Energy Deployment System (ReEDS) Model Documentation: Version 2019. Golden, CO: National Renewable Energy Laboratory. NREL/TP-6A20-74111. https://www.nrel.gov/docs/fy20osti/74111.pdf.


.. _radiant_barrier:

Radiant Barrier
---------------

Description
***********

Presence of radiant barrier in the attic (not modeled in project_national).

Created by
**********

manually created

Source
******

- \Not applicable

- \all homes are assumed to not have attic radiant barriers installed.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``roof_radiant_barrier``
     - true
     - 
     - Boolean
     - "true", "false"
     - Presence of a radiant barrier in the attic.
   * - ``roof_radiant_barrier_grade``
     - false
     - 
     - Choice
     - "auto", "1", "2", "3"
     - The grade of the radiant barrier. If not provided, the OS-HPXML default (see `HPXML Roofs <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-roofs>`_) is used.

.. _range_spot_vent_hour:

Range Spot Vent Hour
--------------------

Description
***********

Range spot ventilation daily start hour.

Created by
**********

manually created

Source
******

- \derived from national average cooking range schedule in Wilson et al. 'Building America House Simulation Protocols' 2014


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``kitchen_fans_quantity``
     - false
     - #
     - Integer
     - "auto"
     - The quantity of the kitchen fans. If not provided, the OS-HPXML default (see `Local Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#local-ventilation-fan>`_) is used.
   * - ``kitchen_fans_flow_rate``
     - false
     - CFM
     - Double
     - "auto"
     - The flow rate of the kitchen fan. If not provided, the OS-HPXML default (see `Local Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#local-ventilation-fan>`_) is used.
   * - ``kitchen_fans_hours_in_operation``
     - false
     - hrs/day
     - Double
     - "auto"
     - The hours in operation of the kitchen fan. If not provided, the OS-HPXML default (see `Local Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#local-ventilation-fan>`_) is used.
   * - ``kitchen_fans_power``
     - false
     - W
     - Double
     - "auto"
     - The fan power of the kitchen fan. If not provided, the OS-HPXML default (see `Local Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#local-ventilation-fan>`_) is used.
   * - ``kitchen_fans_start_hour``
     - false
     - hr
     - Integer
     - "auto"
     - The start hour of the kitchen fan. If not provided, the OS-HPXML default (see `Local Ventilation Fan <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#local-ventilation-fan>`_) is used.

.. _refrigerator:

Refrigerator
------------

Description
***********

The presence and rated efficiency of the primary refrigerator.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \Age of refrigerator converted to efficiency levels using ENERGYSTAR shipment-weighted efficiencies by year data from Home Energy Score: http://hes-documentation.lbl.gov/. Check the comments in: HES-Refrigerator_Age_vs_Efficiency.tsv


Assumption
**********

- \The current year is assumed to be 2022 (previously, it was 2016)

- \Previously, for each year, the EF values were rounded to the nearest EF level, and then the distribution of EF levels were calculated for the age bins. Currently, each year has its own distribution and then we average out the distributions to get the distribution for the age bins. EF for all years are weighted equally when calculating the average distribution for the age bins.

- \EnergyStar distributions from 2009 dependent on [Geometry Building Type RECS,Federal Poverty Level,Tenure] is used to calculate efficiency distribution in RECS2020.EnergyStar Refrigerators assumed to be 10% more efficient than standard.Due to low sampling count, the following coarsening rules are incorporated[1] State coarsened to Census Division RECS with AK/HI separate

  - \[2] Geometry Building Type RECS coarsened to SF/MF/MH

  - \[3] Geometry Building Type RECS coarsened to SF and MH/MF

  - \[4] Vintage with Vintage ACS

  - \[5] Vintage with combined 1960s

  - \[6] Vintage with combined 1960s and post 200ss

  - \[7] Federal Poverty Level coarsened every 100 percent

  - \[8] Federal Poverty Level coarsened every 200 percent

  - \[9] Census Division RECS with AK/HI separate coarsened to Census Division RECS

  - \[10] Census Division RECS to Census Region

  - \[11] Census Region to National


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``refrigerator_present``
     - true
     - 
     - Boolean
     - "true", "false"
     - Whether there is a refrigerator present.
   * - ``refrigerator_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space"
     - The space type for the refrigerator location. If not provided, the OS-HPXML default (see `HPXML Refrigerators <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-refrigerators>`_) is used.
   * - ``refrigerator_rated_annual_kwh``
     - false
     - kWh/yr
     - Double
     - "auto"
     - The EnergyGuide rated annual energy consumption for a refrigerator. If not provided, the OS-HPXML default (see `HPXML Refrigerators <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-refrigerators>`_) is used.

.. _refrigerator_usage_level:

Refrigerator Usage Level
------------------------

Description
***********

Refrigerator energy usage level multiplier.

Created by
**********

``sources/other/tsv_maker.py``

Source
******

- \n/a


Assumption
**********

- \Engineering judgement


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``refrigerator_usage_multiplier``
     - false
     - 
     - Double
     - "auto"
     - Multiplier on the refrigerator energy usage that can reflect, e.g., high/low usage occupants. If not provided, the OS-HPXML default (see `HPXML Refrigerators <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-refrigerators>`_) is used.

.. _roof_material:

Roof Material
-------------

Description
***********

Roof material and color.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Multi-Family with 5+ Units is assigned 'Asphalt Shingles, Medium' only.

- \Due to low samples, Vintage ACS is progressively grouped into: pre-1960, 1960-1999, and 2000+.

- \Geometry Building Type RECS is progressively grouped into: Single-Family (including Mobile Home), and Multi-Family.

- \Census Division RECS is coarsened to Census Region.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``roof_material_type``
     - false
     - 
     - Choice
     - "auto", "asphalt or fiberglass shingles", "concrete", "cool roof", "slate or tile shingles", "expanded polystyrene sheathing", "metal surfacing", "plastic/rubber/synthetic sheeting", "shingles", "wood shingles or shakes"
     - The material type of the roof. If not provided, the OS-HPXML default (see `HPXML Roofs <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-roofs>`_) is used.
   * - ``roof_color``
     - false
     - 
     - Choice
     - "auto", "dark", "light", "medium", "medium dark", "reflective"
     - The color of the roof. If not provided, the OS-HPXML default (see `HPXML Roofs <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-roofs>`_) is used.

.. _solar_hot_water:

Solar Hot Water
---------------

Description
***********

Presence, size, and location of solar hot water system (not modeled in project_national).

Created by
**********

manually created

Source
******

- \Not applicable

- \all homes are assumed to not have solar water heating.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``solar_thermal_system_type``
     - true
     - 
     - Choice
     - "none", "hot water"
     - The type of solar thermal system. Use 'none' if there is no solar thermal system.
   * - ``solar_thermal_collector_area``
     - true
     - ft^2
     - Double
     -
     - The collector area of the solar thermal system.
   * - ``solar_thermal_collector_loop_type``
     - true
     - 
     - Choice
     - "liquid direct", "liquid indirect", "passive thermosyphon"
     - The collector loop type of the solar thermal system.
   * - ``solar_thermal_collector_type``
     - true
     - 
     - Choice
     - "evacuated tube", "single glazing black", "double glazing black", "integrated collector storage"
     - The collector type of the solar thermal system.
   * - ``solar_thermal_collector_azimuth``
     - true
     - degrees
     - Double
     -
     - The collector azimuth of the solar thermal system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).
   * - ``solar_thermal_collector_tilt``
     - true
     - degrees
     - String
     -
     - The collector tilt of the solar thermal system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.
   * - ``solar_thermal_collector_rated_optical_efficiency``
     - true
     - Frac
     - Double
     -
     - The collector rated optical efficiency of the solar thermal system.
   * - ``solar_thermal_collector_rated_thermal_losses``
     - true
     - Btu/hr-ft^2-R
     - Double
     -
     - The collector rated thermal losses of the solar thermal system.
   * - ``solar_thermal_storage_volume``
     - false
     - gal
     - Double
     - "auto"
     - The storage volume of the solar thermal system. If not provided, the OS-HPXML default (see `Detailed Inputs <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#detailed-inputs>`_) is used.
   * - ``solar_thermal_solar_fraction``
     - true
     - Frac
     - Double
     -
     - The solar fraction of the solar thermal system. If provided, overrides all other solar thermal inputs.

.. _state:

State
-----

Description
***********

The U.S. State the sample is located.

Created by
**********

``sources/spatial/tsv_maker.py``

Source
******

- \Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.

- \Unit counts are from the American Community Survey 5-yr 2016.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``site_state_code``
     - false
     - 
     - Choice
     - "auto", "AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI", "WV", "WY"
     - State code of the home address.

.. _tenure:

Tenure
------

Description
***********

The tenancy (owner or renter) of the household occupying the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \In ACS, Tenure is reported for occupied units only. By excluding Vacancy Status as a dependency, we assume vacant units share the same Tenure distribution as occupied units. Where sample counts are less than 10 (464 / 11680 rows), the Census Division by PUMA Metro Status average distribution has been inserted. 'Mobile Home' does not exist in DC and is replaced by 'Single-Family Detached'.


.. _usage_level:

Usage Level
-----------

Description
***********

Usage of major appliances relative to the national average.

Created by
**********

manually created

Source
******

- \Engineering Judgement, Calibration


.. _vacancy_status:

Vacancy Status
--------------

Description
***********

The vacancy status (occupied or vacant) of the dwelling unit.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \Where sample counts are less than 10 (434 / 11680 rows), the State average distribution has been inserted. 'Mobile Home' does not exist in DC and is replaced by 'Single-Family Detached'.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``schedules_vacancy_period``
     - false
     - 
     - String
     -
     - Specifies the vacancy period. Enter a date like "Dec 15 - Jan 15". Optionally, can enter hour of the day like "Dec 15 2 - Jan 15 20" (start hour can be 0 through 23 and end hour can be 1 through 24).

.. _vintage:

Vintage
-------

Description
***********

Time period in which the building was constructed.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


Assumption
**********

- \Where sample counts are less than 10 (812 / 21024 rows), the State average distribution has been inserted. 'Mobile Home' does not exist in DC and is replaced by 'Single-Family Detached'.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``year_built``
     - false
     - 
     - Integer
     -
     - The year the building was built.
   * - ``vintage``
     - false
     - 
     - String
     -
     - The building vintage, used for informational purposes only.

.. _vintage_acs:

Vintage ACS
-----------

Description
***********

Time period in which the dwelling unit was constructed as defined by the U.S. Census American Community Survey.

Created by
**********

``sources/pums/pums2019_5yrs/tsv_maker.py``

Source
******

- \2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.


.. _water_heater_efficiency:

Water Heater Efficiency
-----------------------

Description
***********

The efficiency, type, and heating fuel of water heater.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

- \(Heat pump water heaters) 2016-17 RBSA II for WA and OR and Butzbaugh et al. 2017 US HPWH Market Transformation - Where We've Been and Where to Go Next for remainder of regions

- \Penetration of HPWH for Maine (6.71%) calculated based on total number of HPWH units (AWHI Stakeholder Meeting 12/08/2022) and total housing units https://www.census.gov/quickfacts/ME


Assumption
**********

- \Water heater blanket is used as a proxy for premium storage tank water heaters.

- \Heat Pump Water Heaters are added in manually as they are not in the survey.

- \Default efficiency of HPWH: Electric Heat Pump, 50 gal, 3.45 UEF.

- \Due to low sample sizes, fallback rules applied with lumping of:

  - \[1] State: Census Division RECS

  - \[2] State: Census Region[3] State: National


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``water_heater_type``
     - true
     - 
     - Choice
     - "none", "storage water heater", "instantaneous water heater", "heat pump water heater", "space-heating boiler with storage tank", "space-heating boiler with tankless coil"
     - The type of water heater. Use 'none' if there is no water heater.
   * - ``water_heater_fuel_type``
     - true
     - 
     - Choice
     - "electricity", "natural gas", "fuel oil", "propane", "wood", "coal"
     - The fuel type of water heater. Ignored for heat pump water heater.
   * - ``water_heater_tank_volume``
     - false
     - gal
     - Double
     - "auto"
     - Nominal volume of water heater tank. Only applies to storage water heater, heat pump water heater, and space-heating boiler with storage tank. If not provided, the OS-HPXML default (see `Conventional Storage <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#conventional-storage>`_, `Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#heat-pump>`_, `Combi Boiler w/ Storage <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#combi-boiler-w-storage>`_) is used.
   * - ``water_heater_efficiency_type``
     - true
     - 
     - Choice
     - "EnergyFactor", "UniformEnergyFactor"
     - The efficiency type of water heater. Does not apply to space-heating boilers.
   * - ``water_heater_efficiency``
     - true
     - 
     - Double
     -
     - Rated Energy Factor or Uniform Energy Factor. Does not apply to space-heating boilers.
   * - ``water_heater_usage_bin``
     - false
     - 
     - Choice
     - "auto", "very small", "low", "medium", "high"
     - The usage of the water heater. Only applies if Efficiency Type is UniformEnergyFactor and Type is not instantaneous water heater. Does not apply to space-heating boilers. If not provided, the OS-HPXML default (see `Conventional Storage <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#conventional-storage>`_, `Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#heat-pump>`_) is used.
   * - ``water_heater_recovery_efficiency``
     - false
     - Frac
     - Double
     - "auto"
     - Ratio of energy delivered to water heater to the energy content of the fuel consumed by the water heater. Only used for non-electric storage water heaters. If not provided, the OS-HPXML default (see `Conventional Storage <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#conventional-storage>`_) is used.
   * - ``water_heater_heating_capacity``
     - false
     - Btu/hr
     - Double
     - "auto"
     - Heating capacity. Only applies to storage water heater. If not provided, the OS-HPXML default (see `Conventional Storage <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#conventional-storage>`_) is used.
   * - ``water_heater_standby_loss``
     - false
     - deg-F/hr
     - Double
     - "auto"
     - The standby loss of water heater. Only applies to space-heating boilers. If not provided, the OS-HPXML default (see `Combi Boiler w/ Storage <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#combi-boiler-w-storage>`_) is used.
   * - ``water_heater_jacket_rvalue``
     - false
     - h-ft^2-R/Btu
     - Double
     -
     - The jacket R-value of water heater. Doesn't apply to instantaneous water heater or space-heating boiler with tankless coil. If not provided, defaults to no jacket insulation.
   * - ``water_heater_setpoint_temperature``
     - false
     - deg-F
     - Double
     - "auto"
     - The setpoint temperature of water heater. If not provided, the OS-HPXML default (see `HPXML Water Heating Systems <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-water-heating-systems>`_) is used.
   * - ``water_heater_num_units_served``
     - true
     - #
     - Integer
     -
     - Number of dwelling units served (directly or indirectly) by the water heater. Must be 1 if single-family detached. Used to apportion water heater tank losses to the unit.
   * - ``water_heater_uses_desuperheater``
     - false
     - 
     - Boolean
     - "auto", "true", "false"
     - Requires that the dwelling unit has a air-to-air, mini-split, or ground-to-air heat pump or a central air conditioner or mini-split air conditioner. If not provided, assumes no desuperheater.
   * - ``water_heater_tank_model_type``
     - false
     - 
     - Choice
     - "auto", "mixed", "stratified"
     - Type of tank model to use. The 'stratified' tank generally provide more accurate results, but may significantly increase run time. Applies only to storage water heater. If not provided, the OS-HPXML default (see `Conventional Storage <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#conventional-storage>`_) is used.
   * - ``water_heater_operating_mode``
     - false
     - 
     - Choice
     - "auto", "hybrid/auto", "heat pump only"
     - The water heater operating mode. The 'heat pump only' option only uses the heat pump, while 'hybrid/auto' allows the backup electric resistance to come on in high demand situations. This is ignored if a scheduled operating mode type is selected. Applies only to heat pump water heater. If not provided, the OS-HPXML default (see `Heat Pump <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#heat-pump>`_) is used.
   * - ``water_heater_has_flue_or_chimney``
     - true
     - 
     - String
     -
     - Whether the water heater has a flue or chimney.

.. _water_heater_fuel:

Water Heater Fuel
-----------------

Description
***********

The water heater fuel type.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Due to low sample sizes, fallback rules applied with lumping of:

  - \[1] State: Census Division RECS

  - \[2] Geometry building SF: Mobile, Single family attached, Single family detached

  - \[3] Geometry building MF: Multi-Family with 2 - 4 Units, Multi-Family with 5+ Units

  - \[4] State: Census Region[5] State: National


.. _water_heater_in_unit:

Water Heater In Unit
--------------------

Description
***********

Individual water heater present or not present in the dwelling unit that solely serves the specific dwelling unit.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Single-Family Detached and Mobile Homes have in unit water heaters.

- \As Not Applicable option for Single-Family Attached option is 100%

- \Assuming Single-Family Attached in-unit water heater distribution from RECS 2009

- \Due to low sample sizes, fallback rules applied with lumping of:

  - \[1] State: Census Division RECS

  - \[2] Vintage ACS: Combining Vintage pre 1960s and post 2000

  - \[3] State: Census Region


.. _water_heater_location:

Water Heater Location
---------------------

Description
***********

location of water heater.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \H2OMAIN = other is equally distributed amongst attic and crawlspace.

- \H2OMAIN does not apply to multi-family, therefore Water heater location for multi-family with in-unit water heater is taken after the combined distribution of other builing types.

- \Per expert judgement, water heaters can not be outside or in vented spaces for IECC Climate Zones 4-8 due to pipe-freezing risk.

- \Where samples < 10, data is aggregated in the following order:

- \1. Building Type lumped into single-family, multi-family, and mobile home.

- \2. 1 + Foundation Type combined. 3. 2 + Attic Type combined

- \4. 3 + Garage combined.

- \5. Single-/Multi-Family + Foundation combined + Attic combined + Garage combined.

- \6. 5 + pre-1960 combined.

- \7. 5 + pre-1960 combined / post-2020 combined.

- \8. 7 + IECC Climate Zone lumped into: 1-2+3A, 3B-3C, 4, 5, 6, 7 except AK, 7AK-8AK.

- \9. 7 + IECC Climate Zone lumped into: 1-2-3, 4-8.


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``water_heater_location``
     - false
     - 
     - Choice
     - "auto", "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "attic", "attic - vented", "attic - unvented", "crawlspace", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "other exterior", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space"
     - The location of water heater. If not provided, the OS-HPXML default (see `HPXML Water Heating Systems <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-water-heating-systems>`_) is used.

.. _window_areas:

Window Areas
------------

Description
***********

Window to wall ratios of the front, back, left, and right walls.

Created by
**********

``sources/rbsa_II/tsv_maker.py``

Source
******

- \2016-17 Residential Building Stock Assessment (RBSA) II microdata.


Assumption
**********

- \The window to wall ratios (WWR) are exponential weibull distributed.

- \Multi-Family with 2-4 Units distributions are independent of Geometry Stories

- \Multi-Family with 5+ Units distributions are grouped by 1-3 stories, 4-7 stories, and 8+ stories

- \High-rise Multi-family buildings (8+ stories) have a 30% window to wall ratio (WWR)

- \SFD, SFA, and Mobile Homes are represented by the SFD window area distribution


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``window_front_wwr``
     - true
     - Frac
     - Double
     -
     - The ratio of window area to wall area for the unit's front facade. Enter 0 if specifying Front Window Area instead.
   * - ``window_back_wwr``
     - true
     - Frac
     - Double
     -
     - The ratio of window area to wall area for the unit's back facade. Enter 0 if specifying Back Window Area instead.
   * - ``window_left_wwr``
     - true
     - Frac
     - Double
     -
     - The ratio of window area to wall area for the unit's left facade (when viewed from the front). Enter 0 if specifying Left Window Area instead.
   * - ``window_right_wwr``
     - true
     - Frac
     - Double
     -
     - The ratio of window area to wall area for the unit's right facade (when viewed from the front). Enter 0 if specifying Right Window Area instead.
   * - ``window_area_front``
     - true
     - ft^2
     - Double
     -
     - The amount of window area on the unit's front facade. Enter 0 if specifying Front Window-to-Wall Ratio instead.
   * - ``window_area_back``
     - true
     - ft^2
     - Double
     -
     - The amount of window area on the unit's back facade. Enter 0 if specifying Back Window-to-Wall Ratio instead.
   * - ``window_area_left``
     - true
     - ft^2
     - Double
     -
     - The amount of window area on the unit's left facade (when viewed from the front). Enter 0 if specifying Left Window-to-Wall Ratio instead.
   * - ``window_area_right``
     - true
     - ft^2
     - Double
     -
     - The amount of window area on the unit's right facade (when viewed from the front). Enter 0 if specifying Right Window-to-Wall Ratio instead.
   * - ``window_aspect_ratio``
     - true
     - Frac
     - Double
     -
     - Ratio of window height to width.
   * - ``skylight_area_front``
     - true
     - ft^2
     - Double
     -
     - The amount of skylight area on the unit's front conditioned roof facade.
   * - ``skylight_area_back``
     - true
     - ft^2
     - Double
     -
     - The amount of skylight area on the unit's back conditioned roof facade.
   * - ``skylight_area_left``
     - true
     - ft^2
     - Double
     -
     - The amount of skylight area on the unit's left conditioned roof facade (when viewed from the front).
   * - ``skylight_area_right``
     - true
     - ft^2
     - Double
     -
     - The amount of skylight area on the unit's right conditioned roof facade (when viewed from the front).

.. _windows:

Windows
-------

Description
***********

Construction type and efficiency levels of windows.

Created by
**********

``sources/recs/recs2020/tsv_maker.py``

Source
******

- \U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.


Assumption
**********

- \Wood and Vinyl are considered same material

- \Triple Pane assumed to be 100% low-e

- \Only breaking out clear and low-e windows for the Double, Non-Metal frame type

- \Source of low-e distribution is based on engineering judgement, informed by high-levelsales trends observed in Ducker Worldwide studies of the U.S. Market for Windows, Doors and Skylights.

- \Due to low sample sizes, the following adjustments are made:

  - \[1] Vintage data are grouped into: 1) <1960, 2) 1960-79, 3) 1980-99, 4) 2000s, 5) 2010s.

  - \[2] Building Type data are grouped into: 1) Single-Family Detached, Single-Family Attached, and Mobile homes and 2) Multi-Family 2-4 units and Multi-Family 5+ units.

  - \[3] Climate zones are grouped into: 1) 1A, 2A, 2B

- \2) 3A, 3B, 3C, 4B

- \3) 4A, 4C

- \4) 5A, 5B

- \5) 6A, 6B

- \and 6) 7A, 7B 7AK, 8AK.

  - \[4] Federal Poverty Levels are progressively grouped together until all bins are combined.

  - \[5] Tenure options are progressively grouped together until all bins are combined.

- \Storm window saturations are based on D&R International, Ltd. 'Residential Windows and Window Coverings: A Detailed View of the Installed Base and User Behavior' 2013. https://www.energy.gov/sites/prod/files/2013/11/f5/residential_windows_coverings.pdf. Cut the % storm windows by factor of 55% because only 55% of storms are installed year round

- \Due to lack of performance data storm windows with triple-pane are modeled without the storm windows

- \Due to lack of performance data Double-pane, Low-E, Non-Metal, Air, M-gain, Exterior Clear Storm windows are modeled as Double-pane, Clear, Non-Metal, Air, Exterior Clear Storm windows


Arguments
*********

.. list-table::
   :header-rows: 1

   * - Name
     - Required
     - Units
     - Type
     - Choices
     - Description
   * - ``window_natvent_availability``
     - false
     - Days/week
     - Integer
     - "auto"
     - For operable windows, the number of days/week that windows can be opened by occupants for natural ventilation. If not provided, the OS-HPXML default (see `HPXML Windows <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-windows>`_) is used.
   * - ``window_ufactor``
     - true
     - Btu/hr-ft^2-R
     - Double
     -
     - Full-assembly NFRC U-factor.
   * - ``window_shgc``
     - true
     - 
     - Double
     -
     - Full-assembly NFRC solar heat gain coefficient.
   * - ``window_exterior_shading_winter``
     - false
     - Frac
     - Double
     - "auto"
     - Exterior shading coefficient for the winter season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc. If not provided, the OS-HPXML default (see `HPXML Windows <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-windows>`_) is used.
   * - ``window_exterior_shading_summer``
     - false
     - Frac
     - Double
     - "auto"
     - Exterior shading coefficient for the summer season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc. If not provided, the OS-HPXML default (see `HPXML Windows <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-windows>`_) is used.
   * - ``window_shading_summer_season``
     - false
     - 
     - String
     - "auto"
     - Enter a date like 'May 1 - Sep 30'. Defines the summer season for purposes of shading coefficients; the rest of the year is assumed to be winter. If not provided, the OS-HPXML default (see `HPXML Windows <https://openstudio-hpxml.readthedocs.io/en/v1.7.0/workflow_inputs.html#hpxml-windows>`_) is used.
   * - ``skylight_ufactor``
     - true
     - Btu/hr-ft^2-R
     - Double
     -
     - Full-assembly NFRC U-factor.
   * - ``skylight_shgc``
     - true
     - 
     - Double
     -
     - Full-assembly NFRC solar heat gain coefficient.
   * - ``skylight_storm_type``
     - false
     - 
     - Choice
     - "auto", "clear", "low-e"
     - The type of storm, if present. If not provided, assumes there is no storm.

