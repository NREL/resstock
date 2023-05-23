.. _housing_characteristics:

Housing Characteristics
=======================

.. _ahs_region:

AHS Region
----------

Description
***********

The American Housing Survey region that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.; Core Based Statistical Area (CBSA) data based on the Feb 2013 CBSA delineation file.

Assumption
**********


.. _aiannh_area:

AIANNH Area
-----------

Description
***********

American Indian/Alaska Native/Native Hawaiian Area that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

2010 Census Tract to American Indian Area (AIA) Relationship File provides percent housing unit in tract that belongs to AIA.Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.

Assumption
**********

(2010) Tract is mapped to (2015) County and PUMA by adjusting for known geographic changes (e.g., renaming of Shannon County to Oglala Lakota County, SD) However, Tract=G3600530940103 (Oneida city, Madison County, NY) could not be mapped to County and PUMA and was removed. The tract contains only 11 units for AIA.

.. _ashrae_iecc_climate_zone_2004:

ASHRAE IECC Climate Zone 2004
-----------------------------

Description
***********

Climate zone according to ASHRAE 169 in 2004 and IECC in 2012 that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.; Climate zone data are from ASHRAE 169 2006, IECC 2012, and M.C. Baechler 2015.

Assumption
**********


.. _ashrae_iecc_climate_zone_2004___2_a_split:

ASHRAE IECC Climate Zone 2004 - 2A Split
----------------------------------------

Description
***********

Climate zone according to ASHRAE 169 in 2004 and IECC in 2012 that the sample is located. Climate zone where climate zone 2A is split between counties in TX, LA and FL, GA, AL, and MS

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.; Climate zone data are from ASHRAE 169 2006, IECC 2012, and M.C. Baechler 2015.

Assumption
**********

This characteristic is used to better represent HVAC types in the 2A climate zone.

.. _area_median_income:

Area Median Income
------------------

Description
***********

Area median income of the household occupying the dwelling unit.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

% Area Median Income is calculated using annual household income in 2019USD (continuous, not binned) from 2019-5yrs PUMS data and 2019 Income Limits from HUD. These limits adjust for household size AND local housing costs (AKA Fair Market Rents). Income Limits reported at county subdivisions are consolidated to County using a crosswalk generated from Missouri Census Data Center's geocorr (2014), which has 2010 ACS housing unit count. For the 478 counties available in PUMS (60%), the county-level Income Limits are used. For all others (40%), PUMA-level Income Limits are used, which are converted from county-level using the spatial_tract_lookup file containing 2010 ACS housing unit count.

Assumption
**********


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

Same as occupancy schedule from Wilson et al. 'Building America House Simulation Protocols' 2014

Assumption
**********


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

n/a

Assumption
**********


.. _bedrooms:

Bedrooms
--------

Description
***********

The number of bedrooms in the dwelling unit.

Created by
**********

sources/ahs/ahs2017_2019/tsv_maker.py

Source
******

2017 and 2019 American Housing Survey (AHS) microdata.; Building type categorization based on U.S. EIA 2009 Residential Energy Consumption Survey (RECS).

Assumption
**********

More than 5 bedrooms are labeled as 5 bedrooms and 0 bedrooms are labeled as 1 bedroom; Limit 0-499 sqft dwelling units to only 1 or 2 bedrooms. The geometry measure has a limit of (ffa-120)/70 >= bedrooms.

.. _building_america_climate_zone:

Building America Climate Zone
-----------------------------

Description
***********

The Building America Climate Zone that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Unit counts are from the American Community Survey 5-yr 2016.; Spatial definitions are from U.S. Census 2010.; Climate zone data are from ASHRAE 169 2006, IECC 2012, and M.C. Baechler 2015.

Assumption
**********


.. _cec_climate_zone:

CEC Climate Zone
----------------

Description
***********

The California Energy Commission Climate Zone that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Zip code definitions are from the end of Q2 2020; The climate zone to zip codes in California is from the California Energy Commission Website.

Assumption
**********

CEC Climate zones are defined by Zip Codes.; The dependency selected is County and PUMA as zip codes are not modeled in ResStock.; The mapping between Census Tracts and Zip Codes are approximate and some discrepancies may exist.; If the sample is outside California, the option is set to None.

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

Wilson et al. 'Building America House Simulation Protocols' 2014, national average used as saturation

Assumption
**********

If the unit is vacant there is no ceiling fan energy

.. _census_division:

Census Division
---------------

Description
***********

The U.S. Census Division that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.

Assumption
**********


.. _census_division_recs:

Census Division RECS
--------------------

Description
***********

Census Division as used in RECS 2015 that the sample is located. RECS 2015 splits the Mountain Census Division into north (CO, ID, MT, UT, WY) and south (AZ, NM, NV).

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.; U.S. EIA 2015 Residential Energy Consumption Survey (RECS) codebook.

Assumption
**********


.. _census_region:

Census Region
-------------

Description
***********

The U.S. Census Region that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.

Assumption
**********


.. _city:

City
----

Description
***********

The City that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Cities are defined by Census blocks by their Census Place in the 2010 Census.; Unit counts are from the American Community Survey 5-yr 2016.

Assumption
**********

2020 Deccenial Redistricting data was used to map tract level unit counts to census blocks.; 1,099 cities are tagged in ResStock, but there are over 29,000 Places in the Census data.; The threshold for including a Census Place in the City.tsv is 15,000 dwelling units.; The value 'In another census Place' designates the fraction of dwelling units in a Census Place with fewer total dwelling units than the threshold.; The value 'Not in a census Place' designates the fraction of dwelling units not in a Census Place according to the 2010 Census.

.. _clothes_dryer:

Clothes Dryer
-------------

Description
***********

The presence, rated efficiency, and fuel type of the clothes dryer in a dwelling unit.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Clothes dryer option is None if clothes washer not presentDue to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:; Dwelling unit sub-tsv :deps=['Geometry Building Type RECS', 'State', 'Heating Fuel', 'Clothes Washer Presence'] with the following fallback coarsening order; [1] State coarsened to Census Division RECS without AK, HI; [2] Heating Fuel coarsened to Other Fuel and Propane combined; [3] Heating Fuel coarsened to Fuel Oil, Other Fuel, and Propane combined; [4] Geometry Building Type RECS coarsened to SF/MF/MH; [5] Geometry Building Type RECS coarsened to SF and MH/MF; [6] State coarsened to Census Division RECS; [7] State coarsened to Census Region; [8] State coarsened to National; Household sub-tsv : deps=['Geometry Building Type RECS', 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order; [1] State coarsened to Census Division RECS without AK, HI; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Federal Poverty Level coarsened every 100 percent; [5] Federal Poverty Level coarsened every 200 percent; [6] State coarsened to Census Division RECS; [7] State coarsened to Census Region; [8] State coarsened to National; In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Heating Fuel','Clothers Washer Presence'], ['Tenure', 'Federal Poverty Level']).

.. _clothes_dryer_usage_level:

Clothes Dryer Usage Level
-------------------------

Description
***********

Clothes dryer energy usage level multiplier.

Created by
**********

sources/other/tsv_maker.py

Source
******

n/a

Assumption
**********

Engineering judgement

.. _clothes_washer:

Clothes Washer
--------------

Description
***********

Presence and rated efficiency of the clothes washer.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

The 2020 recs survey does not contain EnergyStar rating of clothes washers.Energystar efficiency distributions with [Geometry Building Type,Federal Poverty Level, Tenure] as dependencies are imported from RECS 2009Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:; Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State','Clothes Washer Presence', 'Vintage'] with the following fallback coarsening order; [1] Geometry Building Type RECS coarsened to SF/MF/MH; [2] Geometry Building Type RECS coarsened to SF and MH/MF; [3] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently; [4] Vintage homes built before 1960 coarsened to pre1960; [5] Vintage homes built after 2000 coarsened to 2000-20; Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order; [1] Geometry Building Type RECS coarsened to SF/MF/MH; [2] Geometry Building Type RECS coarsened to SF and MH/MF; [3] Federal Poverty Level coarsened every 100 percent; [4] Federal Poverty Level coarsened every 200 percent; In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Clothes Washer Presence', 'Vintage'], ['Tenure', 'Federal Poverty Level']).

.. _clothes_washer_presence:

Clothes Washer Presence
-----------------------

Description
***********

The presence of a clothes washer in the dwelling unit.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:; Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Heating Fuel', 'Vintage'] with the following fallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently; [5] Vintage homes built before 1960 coarsened to pre1960; [6] Vintage homes built after 2000 coarsened to 2000-20; [7] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [8] Census Division RECS to Census Region; [9] Census Region to National; Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Federal Poverty Level coarsened every 100 percent; [5] Federal Poverty Level coarsened every 200 percent; [6] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [7] Census Division RECS to Census Region; [8] Census Region to National; In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Geometry Building Type RECS', 'Vintage'], ['Tenure', 'Federal Poverty Level']).

.. _clothes_washer_usage_level:

Clothes Washer Usage Level
--------------------------

Description
***********

Clothes washer energy usage level multiplier.

Created by
**********

sources/other/tsv_maker.py

Source
******

n/a

Assumption
**********

Engineering judgement

.. _cooking_range:

Cooking Range
-------------

Description
***********

Presence and fuel type of the cooking range.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

For Dual Fuel Range the distribution is split equally between Electric and Natural GasDue to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:; Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Heating Fuel', 'Vintage'] with the following fallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Heating Fuel coarsened to Other Fuel and Propane combined; [3] Heating Fuel coarsened to Fuel Oil, Other Fuel, and Propane combined; [4] Geometry Building Type RECS coarsened to SF/MF/MH; [5] Geometry Building Type RECS coarsened to SF and MH/MF; [6] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently; [7] Vintage homes built before 1960 coarsened to pre1960; [8] Vintage homes built after 2000 coarsened to 2000-20; [9] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [10] Census Division RECS to Census Region; [11] Census Region to National; Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Federal Poverty Level coarsened every 100 percent; [5] Federal Poverty Level coarsened every 200 percent; [6] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [7] Census Division RECS to Census Region; [8] Census Region to National; In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across (['Heating Fuel', 'Vintage'], ['Tenure', 'Federal Poverty Level']).

.. _cooking_range_usage_level:

Cooking Range Usage Level
-------------------------

Description
***********

Cooling range energy usage level multiplier.

Created by
**********

sources/other/tsv_maker.py

Source
******

n/a

Assumption
**********

Engineering judgement

.. _cooling_setpoint:

Cooling Setpoint
----------------

Description
***********

Baseline cooling setpoint with no offset applied.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only, 2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK, 4) Owner and Renter are is lumped together which at this point only modifies AK distributions.Vacant units (for which Tenure = 'Not Available') are assumed to follow the same distribution as occupied  units; Cooling setpoint arguments need to be assigned. A cooling setpoint of None corresponds to 95 F, but is not used by OpenStudio-HPXML. No cooling energy is expected.

.. _cooling_setpoint_has_offset:

Cooling Setpoint Has Offset
---------------------------

Description
***********

Presence of a cooling setpoint offset.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK

.. _cooling_setpoint_offset_magnitude:

Cooling Setpoint Offset Magnitude
---------------------------------

Description
***********

The magnitude of cooling setpoint offset.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B and separately 7AK and 8AK regions

.. _cooling_setpoint_offset_period:

Cooling Setpoint Offset Period
------------------------------

Description
***********

The period and offset for the dwelling unit's cooling setpoint. Default for the day is from 9am to 5pm and for the night is 10pm to 7am.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK

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

Engineering Judgment

Assumption
**********


.. _county:

County
------

Description
***********

The U.S. County that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.

Assumption
**********


.. _county_and_puma:

County and PUMA
---------------

Description
***********

The GISJOIN identifier for the County and the Public Use Microdata Area that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.

Assumption
**********


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

Not applicable (dehumidifiers are not explicitly modeled separate from plug loads)

Assumption
**********


.. _dishwasher:

Dishwasher
----------

Description
***********

The presence and rated efficiency of the dishwasher.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

The 2020 recs survey does not contain EnergyStar rating of dishwashers.Energystar efficiency distributions with [Geometry Building Type,Census Division RECS,Federal Poverty Level, Tenure] as dependencies are imported from RECS 2009Due to low sample count, the tsv is constructed with the followingfallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Federal Poverty Level coarsened every 100 percent; [5] Federal Poverty Level coarsened every 200 percent; [6] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently; [7] Vintage homes built before 1960 coarsened to pre1960; [8] Vintage homes built after 2000 coarsened to 2000-20; [9] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [10] Census Division RECS to Census Region

.. _dishwasher_usage_level:

Dishwasher Usage Level
----------------------

Description
***********

Dishwasher energy usage level multiplier.

Created by
**********

sources/other/tsv_maker.py

Source
******

n/a

Assumption
**********

Engineering judgement

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

Engineering Judgement

Assumption
**********


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

Engineering Judgement

Assumption
**********


.. _ducts:

Ducts
-----

Description
***********

Duct insulation and leakage levels.

Created by
**********

manually created

Source
******

IECC 2009; Lucas and Cole, 'Impacts of the 2009 IECC for Residential Buildings at State Level', 2009; Wilson et al., 'Building America House Simulation Protocols', 2014

Assumption
**********


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

Wilson et al. 'Building America House Simulation Protocols' 2014

Assumption
**********


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

Not applicable (electric vehicle charging is not currently modeled separate from plug loads)

Assumption
**********


.. _federal_poverty_level:

Federal Poverty Level
---------------------

Description
***********

Federal poverty level of the household occupying the dwelling unit.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

% Federal Poverty Level is calculated using annual household income in 2019USD (continuous, not binned) from 2019-5yrs PUMS data and 2019 Federal Poverty Lines for contiguous US, where the FPL threshold for 1-occupant household is $12490 and $4420 for every additional person in the household.

.. _generation_and_emissions_assessment_region:

Generation And Emissions Assessment Region
------------------------------------------

Description
***********

The generation and carbon emissions assessment region that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Pieter Gagnon, Will Frazier, Wesley Cole, and Elaine Hale. 2021. Cambium Documentation: Version 2021. Golden, CO.: National Renewable Energy Laboratory. NREL/TP-6A40-81611. https://www.nrel.gov/docs/fy22osti/81611.pdf

Assumption
**********


.. _geometry_attic_type:

Geometry Attic Type
-------------------

Description
***********

The dwelling unit attic type.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Multi-Family building types have Flat Roof (None) only.; 1-story Single-Family building types cannot have Finished Attic/Cathedral Ceiling because that attic type is modeled as a new story and 1-story does not a second story. 4+story Single-Family and mobile homes are an impossible combination.

.. _geometry_building_horizontal_location_mf:

Geometry Building Horizontal Location MF
----------------------------------------

Description
***********

Location of the single-family attached unit horizontally within the building (left, middle, right).

Created by
**********

sources/recs/recs2009/tsv_maker.py

Source
******

Calculated directly from other distributions

Assumption
**********

All values are calculated assuming the building has double-loaded corridors (with some exceptions like 3 units in single-story building).

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

Calculated directly from other distributions

Assumption
**********


.. _geometry_building_level_mf:

Geometry Building Level MF
--------------------------

Description
***********

Location of the multi-family unit vertically within the building (bottom, middle, top).

Created by
**********

sources/recs/recs2009/tsv_maker.py

Source
******

Calculated directly from other distributions

Assumption
**********

Calculated using the number of stories, where buildings >=2 stories have Top and Bottom probabilities = 1/Geometry Stories, and Middle probabilities = 1 - 2/Geometry stories

.. _geometry_building_number_units_mf:

Geometry Building Number Units MF
---------------------------------

Description
***********

The number of dwelling units in the multi-family building.

Created by
**********

sources/recs/recs2009/tsv_maker.py

Source
******

U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Uses NUMAPTS field in RECS; RECS does not report NUMAPTS for Multifamily 2-4 units, so assumptions are made based on the number of stories; Data was sampled from the following bins of Geometry Stories: 1, 2, 3, 4-7, 8+

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

U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********


.. _geometry_building_type_acs:

Geometry Building Type ACS
--------------------------

Description
***********

The building type classification according to the U.S. Census American Communicy Survey.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********


.. _geometry_building_type_height:

Geometry Building Type Height
-----------------------------

Description
***********

The 2009 U.S. Energy Information Administration Residential Energy Consumption Survey  building type with multi-family buildings split out by low-rise, mid-rise, and high-rise.

Created by
**********

sources/recs/recs2009/tsv_maker.py

Source
******

Calculated directly from other distributions

Assumption
**********


.. _geometry_building_type_recs:

Geometry Building Type RECS
---------------------------

Description
***********

The building type classification according to the U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********


.. _geometry_floor_area:

Geometry Floor Area
-------------------

Description
***********

The finished floor area of the dwelling unit using bins from 2017-2019 AHS.

Created by
**********

sources/ahs/ahs2017_2019/tsv_maker.py

Source
******

2017 and 2019 American Housing Survey (AHS) microdata.

Assumption
**********

Due to low sample count, the tsv is constructed by downscaling a core sub-tsv with 3 sub-tsvs of different dependencies. The sub-tsvs have the following dependencies: tsv1 : 'Census Division', 'PUMA Metro Status', 'Geometry Building Type RECS', 'Income RECS2020'; tsv2 : 'Census Division', 'PUMA Metro Status', 'Geometry Building Type RECS', 'Tenure'; tsv3 : 'Census Division', 'PUMA Metro Status', 'Geometry Building Type RECS', 'Vintage ACS'; tsv4 : 'Census Division', 'PUMA Metro Status', 'Income RECS2020', 'Tenure'. For each sub-tsv, rows with <10 samples are replaced with coarsening dependency Census Region, followed by National.

.. _geometry_floor_area_bin:

Geometry Floor Area Bin
-----------------------

Description
***********

The finished floor area of the dwelling unit using bins from the U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

sources/recs/recs2009/tsv_maker.py

Source
******

The sample counts and sample weights are constructed using U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.; Geometry Floor Area bins are from the UNITSIZE field of the 2017 American Housing Survey (AHS).

Assumption
**********


.. _geometry_foundation_type:

Geometry Foundation Type
------------------------

Description
***********

The type of foundation.

Created by
**********

sources/recs/recs2009/tsv_maker.py

Source
******

The sample counts and sample weights are constructed using U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

All mobile homes have Ambient foundations.; Multi-family buildings cannot have Ambient and Heated Basements; Single-family attached buildings cannot have Ambient foundations; Foundation types are the same for each building type except mobile homes and the applicable options.; Because we need to assume a foundation type for ground-floor MF units, we use the lumped SFD+SFA distributions for MF2-4 and MF5+ building foundations. (RECS data for households in MF2-4 unit buildings are not useful since we do not know which floor the unitis on. RECS does not include foundation responses for households in MF5+ unit buildings.); For SFD and SFA, if no foundation type specified, then sample has Ambient foundation.

.. _geometry_garage:

Geometry Garage
---------------

Description
***********

The size of an attached garage.

Created by
**********

sources/recs/2009/tsv_maker.py (manually modified by Joe Robertson)

Source
******

U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

All mobile homes and multi-family units do not have an attached garage.; All units with Ambient foundations do not have an attached garage.; Vented Crawlspace, Unvented Crawlspace, Heated basement, Slab, and Unheated basement foundation type samples are lumped together due to low sample counts.

.. _geometry_stories:

Geometry Stories
----------------

Description
***********

The number of building stories.

Created by
**********

sources/recs/recs2009/tsv_maker.py

Source
******

U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

All mobile homes are 1 story.; Single-Family Detached and Single-Family Attached use the STORIES field in RECS, whereas Multifamily with 5+ units uses the NUMFLRS field.; Building types 2 Unit and 3 or 4 Unit use the stories distribution of Multifamily 5 to 9 Unit (capped at 4 stories) because RECS does not report stories or floors for multifamily with 2-4 units.; The dependency on floor area bins is removed for multifamily with 5+ units.; Vintage ACS rows for the 2010s are copied from the 2000-09 rows.

.. _geometry_stories_low_rise:

Geometry Stories Low Rise
-------------------------

Description
***********

Number of building stories for low-rise buildings.

Created by
**********

sources/recs/recs2009/tsv_maker.py

Source
******

Calculated directly from other distributions

Assumption
**********


.. _geometry_story_bin:

Geometry Story Bin
------------------

Description
***********

The building has more than 8 or less than 8 stories.

Created by
**********

sources/recs/recs2009/tsv_maker.py

Source
******

U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********


.. _geometry_wall_exterior_finish:

Geometry Wall Exterior Finish
-----------------------------

Description
***********

Wall siding material and color.

Created by
**********

sources/lightbox/residential/tsv_maker.py

Source
******

HIFLD Parcel data.

Assumption
**********

Rows where sample size < 10 are replaced with aggregated values down-scaled from dep='State' to dep='Census Division RECS'; Brick wall types are assumed to not have an aditional brick exterior finish; Steel and wood frame walls must have an exterior finish

.. _geometry_wall_type:

Geometry Wall Type
------------------

Description
***********

The wall material used for thermal mass calculations of exterior walls.

Created by
**********

sources/lightbox/residential/tsv_maker.py

Source
******

HIFLD Parcel data.

Assumption
**********

Rows where sample size < 10 are replaced with aggregated values down-scaled from dep='State' to dep='Census Division RECS'

.. _hvac_cooling_efficiency:

HVAC Cooling Efficiency
-----------------------

Description
***********

The presence and efficiency of primary cooling system in the dwelling unit.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.; Efficiency data based on CAC-ASHP-shipments-table.tsv, room_AC_efficiency_vs_age.tsv and expanded_HESC_HVAC_efficiencies.tsv combined with age of equipment data from RECS

Assumption
**********

Check the assumptions on the source tsv files.

.. _hvac_cooling_partial_space_conditioning:

HVAC Cooling Partial Space Conditioning
---------------------------------------

Description
***********

The fraction of the finished floor area that the cooling system provides cooling.

Created by
**********

sources/recs/recs2009/tsv_maker.py

Source
******

U.S. EIA 2009 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Central AC systems need to serve at least 60 percent of the floor area.; Heat pumps serve 100 percent of the floor area because the system serves 100 percent of the heated floor area.; Due to low sample count, the tsv is constructed by downscaling a core sub-tsv with 3 sub-tsvs of different dependencies. The sub-tsvs have the following dependencies: tsv1 : 'HVAC Cooling Type', 'ASHRAE IECC Climate Zone 2004'; tsv2 : 'HVAC Cooling Type', 'Geometry Floor Area Bin'; tsv3 : 'HVAC Cooling Type', 'Geometry Building Type RECS';

.. _hvac_cooling_type:

HVAC Cooling Type
-----------------

Description
***********

The presence and type of primary cooling system in the dwelling unit.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Due to low sample sizes, fallback rules applied with lumping of; 1) HVAC Heating type: Non-ducted heating and None2) Geometry building SF: Mobile, Single family attached, Single family detached3) Geometry building MF: Multi-Family with 2 - 4 Units, Multi-Family with 5+ Units4) Vintage Lump: 20yrs binsHomes having ducted heat pump for heating and electricity fuel is assumed to haveducted heat pump for cooling (seperating from central AC category); Homes having non-ducted heat pump for heating is assumed to have non-ducted heat pumpfor cooling

.. _hvac_has_ducts:

HVAC Has Ducts
--------------

Description
***********

The presence of ducts in the dwelling unit.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Ducted Heat Pump HVAC type assumed to have ducts; Non-Ducted Heat Pump HVAC type assumed to have no ducts; There are likely homes with non-ducted heat pump having ducts (Central AC with non-ducted HP) But due to structure of ResStock we are not accounting those homes; Evaporative or swamp cooler assigned Void option

.. _hvac_has_shared_system:

HVAC Has Shared System
----------------------

Description
***********

The presence of an HVAC system shared between multiple dwelling units.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Due to low sample sizes, the fallback rules are applied in following order; [1] Vintage: Vintage ACS 20 year bin[2] HVAC Cooling Type: Lump 1) Central AC and Ducted Heat Pump and 2) Non-Ducted Heat Pump and None[3] HVAC Heating Type: Lump 1) Ducted Heating and Ducted Heat Pump and 2) Non-Ducted Heat Pump and None[4] HVAC Cooling Type: Lump 1) Central AC and Ducted Heat Pump and 2) Non-Ducted Heat Pump, Non-Ducted Heating, and None[5] HVAC Heating Type: Lump 1) Ducted Heating and Ducted Heat Pump and 2) Non-Ducted Heat Pump, None, and Room AC[6] Vintage: Vintage pre 1960s and post 2000[7] Vintage: All vintages; Evaporative or swamp cooler Cooling Type assigned Void option; Ducted Heat Pump assigned for both heating and cooling, other combinations assigned Void option; Non-Ducted Heat Pump assigned for both heating and cooling, other combinations assigned Void option

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

n/a

Assumption
**********


.. _hvac_heating_efficiency:

HVAC Heating Efficiency
-----------------------

Description
***********

The presence and efficiency of the primary heating system in the dwelling unit.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.; Shipment data based on CAC-ASHP-shipments-table.tsv and furnace-shipments-table.tsv; Efficiency data based on expanded_HESC_HVAC_efficiencies.tsv combined with age of equipment data from RECS

Assumption
**********

Check the assumptions on the source tsv files.; If a house has a wall furnace with fuel other than natural_gas, efficiency level based on natural_gas from expanded_HESC_HVAC_efficiencies.tsv is assigned.; If a house has a heat pump with fuel other than electricity (presumed dual-fuel heat pump), the heating type is assumed to be furnace and not heat pump.; The shipment volume for boiler was not available, so shipment volume for furnace in furnace-shipments-table.tsv was used instead.; Due to low sample size for some categories, the HVAC Has Shared System categories 'Cooling Only' and 'None' are combined for the purpose of querying Heating Efficiency distributions.; For 'other' heating system types, we assign them to Electric Baseboard if fuel is Electric, and assign them to Wall/Floor Furnace if fuel is natural_gas, fuel_oil or propane.

.. _hvac_heating_type:

HVAC Heating Type
-----------------

Description
***********

The presence and type of the primary heating system in the dwelling unit.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Due to low sample sizes, fallback rules applied with lumping of; 1) Heating fuel lump: Fuel oil, Propane, and Other Fuel2) Geometry building SF: Mobile, Single family attached, Single family detached3) Geometry building MF: Multi-Family with 2 - 4 Units, Multi-Family with 5+ Units4) Vintage Lump: 20yrs bins

.. _hvac_heating_type_and_fuel:

HVAC Heating Type And Fuel
--------------------------

Description
***********

The presence, type, and fuel of primary heating system.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

Calculated directly from other distributions

Assumption
**********


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

n/a

Assumption
**********


.. _hvac_secondary_heating_type_and_fuel:

HVAC Secondary Heating Type And Fuel
------------------------------------

Description
***********

Secondary HVAC system heating type and fuel (not used in project_national).

Created by
**********

manually created

Source
******

n/a

Assumption
**********


.. _hvac_shared_efficiencies:

HVAC Shared Efficiencies
------------------------

Description
***********

The presence and efficiency of the shared HVAC system.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

The sample counts and sample weights are constructed using U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Assume that all Heating and Cooling shared systems are fan coils in each dwelling unit served by a central chiller and boiler.; Assume all Heating Only shared systems are hot water baseboards in each dwelling unit served by a central boiler.; Assume all Cooling Only shared systems are fan coils in each dwelling unit served by a central chiller.

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

Assuming no faults until we have data necessary to characterize all types of ACs and heat pumps (https://github.com/NREL/resstock/issues/733).

Assumption
**********


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

Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020

Assumption
**********


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

Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020

Assumption
**********


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

Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020

Assumption
**********


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

Winkler et al. 'Impact of installation faults in air conditioners and heat pumps in single-family homes on US energy usage' 2020

Assumption
**********


.. _has_pv:

Has PV
------

Description
***********

The dwelling unit has a rooftop photovoltaic system.

Created by
**********

sources/dpv/tsv_maker.py

Source
******

ACS population and RiDER data on PV installation that combines LBNL's 2020 Tracking the Sun and Wood Mackenzie's 2020 Q4 PV report (prepared by Nicholas.Willems@nrel.gov on Jun 22, 2021)

Assumption
**********

Imposed an upperbound of 14 kWDC, which contains 95pct of all installations. Counties with source_count<10 are backfilled with aggregates at the State level. Distribution based on all installations is applied only to occupied SFD, actual distribution for SFD may be higher.; PV is not modeled in AK and HI. No data has been identified.

.. _heating_fuel:

Heating Fuel
------------

Description
***********

The primary fuel used for heating the dwelling unit.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

In ACS, Heating Fuel is reported for occupied units only. By excluding Vacancy Status as adependency, we assume vacant units share the same Heating Fuel distribution as occupied units. Where sample counts are less than 10, the State average distribution has been inserted. Prior to insertion, the following adjustments have been made to the state distribution so all rows have sample count > 10: 1. Where sample counts < 10 (which consists of Mobile Home and Single-Family Attached only), the Vintage ACS distribution is used instead of Vintage: [CT, DE, ID, MD, ME, MT, ND, NE, NH, NV, RI, SD, UT, VT, WY]; 2. Remaining Mobile Homes < 10 are replaced by Single-Family Detached + Mobile Homes combined: [DE, RI, SD, VT, WY, and all DC].

.. _heating_setpoint:

Heating Setpoint
----------------

Description
***********

Baseline heating setpoint with no offset applied.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK; Heating type dependency is always lumped into Heat pump / Non-heat pumps; For vacant units (for which Tenure = 'Not Available'), the heating setpoint is set to 55F

.. _heating_setpoint_has_offset:

Heating Setpoint Has Offset
---------------------------

Description
***********

Presence of a heating setpoint offset.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only, 2) lumping all building types together

.. _heating_setpoint_offset_magnitude:

Heating Setpoint Offset Magnitude
---------------------------------

Description
***********

Magnitude of the heating setpoint offset.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK

.. _heating_setpoint_offset_period:

Heating Setpoint Offset Period
------------------------------

Description
***********

The period and offset for the dwelling unit's heating setpoint. Default for the day is from 9am to 5pm and for the night is 10pm to 7am.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

For dependency conditions with low samples, the following lumpings are used in progressive order until there are enough samples: 1) lumping buildings into Single-Family and Multi-Family only,  2) lumping buildings into Single-Family and Multi-Family only and lumping nearby climate zones within  A/B regions and separately 7AK and 8AK 3) lumping all building types together and lumping climate zones within A/B regions and separately 7AK and 8AK

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

Not applicable (holiday lighting is not currently modeled separate from other exterior lighting)

Assumption
**********


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

Engineering Judgement

Assumption
**********


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

Engineering Judgement

Assumption
**********


.. _household_has_tribal_persons:

Household Has Tribal Persons
----------------------------

Description
***********

The houshold occupying the dwelling unit has at least one tribal person in the household.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

2188 / 2336 PUMA has <10 samples and are falling back to state level aggregated values.DC Mobile Homes do not exist and are replaced with Single-Family Detached.

.. _iso_rto_region:

ISO RTO Region
--------------

Description
***********

The independent system operator or regional transmission organization region that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.; ISO and RTO regions are from EIA Form 861.

Assumption
**********


.. _income:

Income
------

Description
***********

Income of the household occupying the dwelling unit.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

In ACS, Income and Tenure are reported for occupied units only. Because we assume vacant units share the same Tenure distribution as occupied units, by extension, we assume this Income distribution applies to all units regardless of Vacancy Status. For reference, 57445 / 140160 rows have sampling_probability >= 1/550000. Of those rows, 2961 (5%) were replaced due to low samples in the following process: Where sample counts are less than 10 (79145 / 140160 relevant rows), the Census Division by PUMA Metro Status average distribution has been inserted first (76864), followed by Census Division by 'Metro'/'Non-metro' average distribution (1187), followed by Census Region by PUMA Metro Status average distribution (282), followed by Census Region by 'Metro'/'Non-metro' average distribution (112).

.. _income_recs2015:

Income RECS2015
---------------

Description
***********

Income of the household occupying the dwelling unit that are aligned with the 2015 U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

Income bins aligned with RECS 2015

.. _income_recs2020:

Income RECS2020
---------------

Description
***********

Income of the household occupying the dwelling unit that are aligned with the 2020 U.S. Energy Information Administration Residential Energy Consumption Survey.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

Consolidated income bins aligned with RECS 2020

.. _infiltration:

Infiltration
------------

Description
***********

Air leakage rates for the living and garage spaces

Created by
**********

sources/resdb/tsv_maker.py

Source
******

Distributions are based on the cumulative distribution functions from the Residential Diagnostics Database (ResDB), http://resdb.lbl.gov/.

Assumption
**********

All ACH50 are based on Single-Family Detached blower door tests.; Climate zones that are copied: 2A to 1A, 6A to 7A, and 6B to 7B.; Vintage bins that are copied: 2000s to 2010s, 1950s to 1940s, 1950s to <1940s.; Homes are assumed to not be Weatherization Assistance Program (WAP) qualified and not ENERGY STAR certified.; Climate zones 7AK and 8AK are averages of 6A and 6B.

.. _insulation_ceiling:

Insulation Ceiling
------------------

Description
***********


Created by
**********


Source
******

NEEA Residential Building Stock Assessment, 2012; Nettleton, G.; Edwards, J. (2012). Data Collection-Data Characterization Summary, NorthernSTAR Building America Partnership, Building Technologies Program. Washington, D.C.: U.S. Department of Energy, as described in Roberts et al., 'Assessment of the U.S. Department of Energy's Home Energy Score Tool', 2012, and Merket 'Building America Field Data Repository', Webinar, 2014; Derived from Home Innovation Research Labs 1982-2007 Data

Assumption
**********

Vented Attic has the same distribution as Unvented Attic; CRHI is a copy of CR09; CRAK is a copy of CR02

.. _insulation_floor:

Insulation Floor
----------------

Description
***********


Created by
**********


Source
******

Derived from Home Innovation Research Labs 1982-2007 Data; (pre-1980) Engineering judgment

Assumption
**********

CRHI is a copy of CR09; CRAK is a copy of CR02

.. _insulation_foundation_wall:

Insulation Foundation Wall
--------------------------

Description
***********


Created by
**********


Source
******

Derived from Home Innovation Research Labs 1982-2007 Data; (pre-1980) Engineering judgment

Assumption
**********

CRHI is a copy of CR09; CRAK is a copy of CR02

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

Engineering Judgement

Assumption
**********

Rim joist insulation is the same value as the foundation wall insulation.

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

Derived from Home Innovation Research Labs 1982-2007 Data; NEEA Residential Building Stock Assessment, 2012

Assumption
**********


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

Derived from Home Innovation Research Labs 1982-2007 Data; (pre-1980) Engineering judgment

Assumption
**********

CRHI is a copy of CR09; CRAK is a copy of CR02

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

Ritschard et al. Single-Family Heating and Cooling Requirements: Assumptions, Methods, and Summary Results 1992; Nettleton, G.; Edwards, J. (2012). Data Collection-Data Characterization Summary, NorthernSTAR Building America Partnership, Building Technologies Program. Washington, D.C.: U.S. Department of Energy, as described in Roberts et al., 'Assessment of the U.S. Department of Energy's Home Energy Score Tool', 2012, and Merket Building America Field Data Repository, Webinar, 2014

Assumption
**********

Updated per new wall type from Lightbox, all wall type-specific distributions follow that of `Wood Frame` (`WoodStud`)

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

ANSI/RESNET/ICC 301 Standard

Assumption
**********


.. _lighting:

Lighting
--------

Description
***********


Created by
**********

sources/recs/2015/tsv_maker.py

Source
******

U.S. EIA 2015 Residential Energy Consumption Survey (RECS) microdata.; 2019 Energy Savings Forecast of Solid-State Lighting in General Illumination Applications. https://www.energy.gov/sites/prod/files/2019/12/f69/2019_ssl-energy-savings-forecast.pdf

Assumption
**********

Qualitative lamp type fractions in each household surveyed are distributed to three options representing 100% incandescent, 100% CFl, and 100% LED lamp type options.; Due to low sample sizes for some Building Types, Building Type data are grouped into: 1) Single-Family Detached and Mobile Homes, and 2) Multifamily 2-4 units and Multifamily 5+ units, and 3) Single-Family Attached.; Single-Family Attached units in the West South Central census division has the same LED saturation as Multi-Family; LED saturation is adjusted to match the U.S. projected saturation in the 2019 Energy Savings Forecast of Solid-State Lighting in General Illumination Applications.

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

Not applicable; this parameter for adding diversity to lighting usage patterns is not currently used.

Assumption
**********


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

Not applicable; this parameter for adding diversity to lighting usage patterns is not currently used.

Assumption
**********


.. _location_region:

Location Region
---------------

Description
***********

A custom ResStock region constructed of RECS 2009 reportable domains that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.; Custom region map located https://github.com/NREL/resstock/wiki/Custom-Region-(CR)-Map

Assumption
**********


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

Engineering Judgement

Assumption
**********


.. _misc_extra_refrigerator:

Misc Extra Refrigerator
-----------------------

Description
***********

The presence and rated efficiency of the secondary refrigerator.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.; Age of refrigerator converted to efficiency levels using ENERGYSTAR shipment-weighted efficiencies by year data from Home Energy Score: http://hes-documentation.lbl.gov/. Check the comments in: HES-Refrigerator_Age_vs_Efficiency.tsv

Assumption
**********

The current year is assumed to be 2022; Previously, for each year, the EF values were rounded to the nearest EF level, and then the distribution of EF levels were calculated for the age bins. Currently, each year has its own distribution and then we average out the distributions to get the distribution for the age bins. EF for all years are weighted equally when calculating the average distribution for the age bins.; EnergyStar distributions from 2009 dependent on [Geometry Building Type RECS,Federal Poverty Level,Tenure] is used to calculate efficiency distribution in RECS2020.EnergyStar Refrigerators assumed to be 10% more efficient than standard.Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:; Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Vintage'] with the following fallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Vintage with Vintage ACS; [5] Vintage with combined 1960s; [6] Vintage with combined 1960s and post 200ss; [7] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [8] Census Division RECS to Census Region; [9] Census Region to National; Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Federal Poverty Level coarsened every 100 percent; [5] Federal Poverty Level coarsened every 200 percent; [6] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [7] Census Division RECS to Census Region; [8] Census Region to National; In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across ('Heating Fuel', ['Tenure', 'Federal Poverty Level']).

.. _misc_freezer:

Misc Freezer
------------

Description
***********

The presence and rated efficiency of a standalone freezer.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

The national average EF is 12 based on the 2014 BA house simulation protocols; Due to low sample count, the tsv is constructed with the following fallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Federal Poverty Level coarsened every 100 percent; [5] Federal Poverty Level coarsened every 200 percent; [6] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [7] Census Division RECS to Census Region; [8] Census Region to National

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

Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation

Assumption
**********


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

Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation

Assumption
**********


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

Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation

Assumption
**********


.. _misc_hot_tub_spa:

Misc Hot Tub Spa
----------------

Description
***********

The presence and heating fuel of a hot tub/spa at the dwelling unit.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Due to low sample count, the tsv is constructed by downscaling a dwelling unit sub-tsv with a household sub-tsv. The sub-tsvs have the following dependencies:; Dwelling unit sub-tsv : deps=['Geometry Building Type RECS', 'State', 'Heating Fuel'] with the following fallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Heating Fuel coarsened to Other Fuel and Propane combined; [3] Heating Fuel coarsened to Fuel Oil, Other Fuel, and Propane combined; [4] Geometry Building Type RECS coarsened to SF/MF/MH; [5] Geometry Building Type RECS coarsened to SF and MH/MF; [6] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [7] Census Division RECS to Census Region; [8] Census Region to National; Household sub-tsv : deps=['Geometry Building Type RECS', 'State' 'Tenure', 'Federal Poverty Level'] with the following fallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Federal Poverty Level coarsened every 100 percent; [5] Federal Poverty Level coarsened every 200 percent; [6] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [7] Census Division RECS to Census Region; [8] Census Region to National; In combining the dwelling unit sub-tsv and household sub-tsv, the conditional relationships are ignored across ('Heating Fuel', ['Tenure', 'Federal Poverty Level']).

.. _misc_pool:

Misc Pool
---------

Description
***********

The presence of a pool at the dwelling unit.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

The only valid option for multi-family homes is Nonesince the pool is most likely to be jointly ownedDue to low sample count, the tsv is constructed with the followingfallback coarsening order; [1] State coarsened to Census Division RECS with AK/HI separate; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Federal Poverty Level coarsened every 100 percent; [5] Federal Poverty Level coarsened every 200 percent; [6] Vintage coarsened to every 20 years before 2000 and every 10 years subsequently; [7] Vintage homes built before 1960 coarsened to pre1960; [8] Vintage homes built after 2000 coarsened to 2000-20; [9] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [10] Census Division RECS to Census Region; [11] Census Region to National

.. _misc_pool_heater:

Misc Pool Heater
----------------

Description
***********

The heating fuel of the pool heater if there is a pool.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********


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

Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation

Assumption
**********


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

Wilson et al. 'Building America House Simulation Protocols' 2014, national average fraction used for saturation

Assumption
**********


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

Wilson et al. 'Building America House Simulation Protocols' 2014

Assumption
**********


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

OpenStreetMap data queried by Radiant Labs for Multi-Family and Single-Family Attached; Engineering Judgement for others

Assumption
**********


.. _occupants:

Occupants
---------

Description
***********

The number of occupants living in the dwelling unit.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

Option=10+ has a (weighted) representative value of 11. In ACS, Income, Tenure, and Occupants are reported for occupied units only. Because we assume vacant units share the same Income and Tenure distributions as occupied units, by extension, we assume this Occupants distribution applies to all units regardless of Vacancy Status. Where sample counts are less than 10 (6243 / 18000 rows), the Census Region average distribution has been inserted first (2593), followed by national average distribution (2678), followed by national + 'MF'/'SF' average distribution (252), followed by national + 'MF'/'SF' + 'Metro'/'Non-metro' average distribution (315)followed by national + 'MF'/'SF' + 'Metro'/'Non-metro' + Vacancy Status average distribution (657).

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

OpenStreetMap data queried by Radiant Labs.

Assumption
**********


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

Not applicable; all homes are assumed to not have window overhangs other than eaves.

Assumption
**********


.. _puma:

PUMA
----

Description
***********

The Public Use Microdata Area from 2010 U.S. Census that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.

Assumption
**********


.. _puma_metro_status:

PUMA Metro Status
-----------------

Description
***********

The public use microdata area metropolitan status that the dwelling unit is located.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

'PUMA Metro Status', derived from ACS IPUMS METRO codes, indicates whether the household resided within a metropolitan area and, for households in metropolitan areas, whether the household resided within or outside of a central/principal city. Each PUMA has a unique METRO status in ACS and therefore has a unique PUMA Metro Status. IPUMS derives METRO codes for samples not directly identified based on available geographic information and whether the associated county group or PUMA lies wholly or only partially within metropolitan areas or principal cities.

.. _pv_orientation:

PV Orientation
--------------

Description
***********

The orientation of the photovoltaic system.

Created by
**********

sources/dpv/tsv_maker.py

Source
******

LBNL's 2020 Tracking the Sun (TTS).

Assumption
**********

PV orientation mapped based on azimuth angle of primary array (180 deg is South-facing).

.. _pv_system_size:

PV System Size
--------------

Description
***********

The size of the photovoltaic system.

Created by
**********

sources/dpv/tsv_maker.py

Source
******

LBNL's 2020 Tracking the Sun (TTS).

Assumption
**********

Installations of unknown mount type are assumed rooftop. States without data are backfilled with aggregates at the Census Region. 'East South Central' assumed the same distribution as 'West South Central'.; PV is not modeled in AK and HI. The Option=None is set so that an error is thrown if PV is modeled as an argument will be missing.

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

Engineering Judgement, Calibration

Assumption
**********


.. _plug_loads:

Plug Loads
----------

Description
***********

Plug load usage level which is varied by Census Division RECS and Building Type RECS.

Created by
**********

sources/recs/recs2015/tsv_maker.py

Source
******

U.S. EIA 2015 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Multipliers are based on ratio of the ResStock MELS regression equations and the MELS modeled in RECS.

.. _reeds_balancing_area:

REEDS Balancing Area
--------------------

Description
***********

The Regional Energy Deployment System Model (ReEDS) balancing area that the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.; Brown, Maxwell, Wesley Cole, Kelly Eurek, Jon Becker, David Bielen, Ilya Chernyakhovskiy, Stuart Cohen et al. 2020. Regional Energy Deployment System (ReEDS) Model Documentation: Version 2019. Golden, CO: National Renewable Energy Laboratory. NREL/TP-6A20-74111. https://www.nrel.gov/docs/fy20osti/74111.pdf.

Assumption
**********


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

Not applicable; all homes are assumed to not have attic radiant barriers installed.

Assumption
**********


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

derived from national average cooking range schedule in Wilson et al. 'Building America House Simulation Protocols' 2014

Assumption
**********


.. _refrigerator:

Refrigerator
------------

Description
***********

The presence and rated efficiency of the primary refrigerator.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.; Age of refrigerator converted to efficiency levels using ENERGYSTAR shipment-weighted efficiencies by year data from Home Energy Score: http://hes-documentation.lbl.gov/. Check the comments in: HES-Refrigerator_Age_vs_Efficiency.tsv

Assumption
**********

The current year is assumed to be 2022 (previously, it was 2016); Previously, for each year, the EF values were rounded to the nearest EF level, and then the distribution of EF levels were calculated for the age bins. Currently, each year has its own distribution and then we average out the distributions to get the distribution for the age bins. EF for all years are weighted equally when calculating the average distribution for the age bins.; EnergyStar distributions from 2009 dependent on [Geometry Building Type RECS,Federal Poverty Level,Tenure] is used to calculate efficiency distribution in RECS2020.EnergyStar Refrigerators assumed to be 10% more efficient than standard.Due to low sampling count, the following coarsening rules are incorporated[1] State coarsened to Census Division RECS with AK/HI separate; [2] Geometry Building Type RECS coarsened to SF/MF/MH; [3] Geometry Building Type RECS coarsened to SF and MH/MF; [4] Vintage with Vintage ACS; [5] Vintage with combined 1960s; [6] Vintage with combined 1960s and post 200ss; [7] Federal Poverty Level coarsened every 100 percent; [8] Federal Poverty Level coarsened every 200 percent; [9] Census Division RECS with AK/HI separate coarsened to Census Division RECS; [10] Census Division RECS to Census Region; [11] Census Region to National

.. _refrigerator_usage_level:

Refrigerator Usage Level
------------------------

Description
***********

Refrigerator energy usage level multiplier.

Created by
**********

sources/other/tsv_maker.py

Source
******

n/a

Assumption
**********

Engineering judgement

.. _roof_material:

Roof Material
-------------

Description
***********

Roof material and color.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Multi-Family with 5+ Units is assigned 'Asphalt Shingles, Medium' only.; Due to low samples, Vintage ACS is progressively grouped into: pre-1960, 1960-1999, and 2000+.; Geometry Building Type RECS is progressively grouped into: Single-Family (including Mobile Home), and Multi-Family.; Census Division RECS is coarsened to Census Region.

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

Not applicable; all homes are assumed to not have solar water heating.

Assumption
**********


.. _state:

State
-----

Description
***********

The U.S. State the sample is located.

Created by
**********

sources/spatial/tsv_maker.py

Source
******

Spatial definitions are from the U.S. Census Bureau as of July 1, 2015.; Unit counts are from the American Community Survey 5-yr 2016.

Assumption
**********


.. _tenure:

Tenure
------

Description
***********

The tenancy (owner or renter) of the household occupying the dwelling unit.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

In ACS, Tenure is reported for occupied units only. By excluding Vacancy Status as a dependency, we assume vacant units share the same Tenure distribution as occupied units. Where sample counts are less than 10 (464 / 11680 rows), the Census Division by PUMA Metro Status average distribution has been inserted. 'Mobile Home' does not exist in DC and is replaced by 'Single-Family Detached'.

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

Engineering Judgement, Calibration

Assumption
**********


.. _vacancy_status:

Vacancy Status
--------------

Description
***********

The vacancy status (occupied or vacant) of the dwelling unit.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

Where sample counts are less than 10 (434 / 11680 rows), the State average distribution has been inserted. 'Mobile Home' does not exist in DC and is replaced by 'Single-Family Detached'.

.. _vintage:

Vintage
-------

Description
***********

Time period in which the building was constructed.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********

Where sample counts are less than 10 (812 / 21024 rows), the State average distribution has been inserted. 'Mobile Home' does not exist in DC and is replaced by 'Single-Family Detached'.

.. _vintage_acs:

Vintage ACS
-----------

Description
***********

Time period in which the dwelling unit was constructed as defined by the U.S. Census American Community Survey.

Created by
**********

sources/pums/pums2019_5yrs/tsv_maker.py

Source
******

2019-5yrs Public Use Microdata Samples (PUMS). IPUMS USA, University of Minnesota, www.ipums.org.

Assumption
**********


.. _water_heater_efficiency:

Water Heater Efficiency
-----------------------

Description
***********

The efficiency, type, and heating fuel of water heater.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.; (Heat pump water heaters) 2016-17 RBSA II for WA and OR and Butzbaugh et al. 2017 US HPWH Market Transformation - Where We've Been and Where to Go Next for remainder of regions; Penetration of HPWH for Maine (6.71%) calculated based on total number of HPWH units (AWHI Stakeholder Meeting 12/08/2022) and total housing units https://www.census.gov/quickfacts/ME

Assumption
**********

Water heater blanket is used as a proxy for premium storage tank water heaters.; Heat Pump Water Heaters are added in manually as they are not in the survey.; Default efficiency of HPWH: Electric Heat Pump, 50 gal, 3.45 UEF.; Due to low sample sizes, fallback rules applied with lumping of:; [1] State: Census Division RECS; [2] State: Census Region[3] State: National

.. _water_heater_fuel:

Water Heater Fuel
-----------------

Description
***********

The water heater fuel type.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Due to low sample sizes, fallback rules applied with lumping of:; [1] State: Census Division RECS; [2] Geometry building SF: Mobile, Single family attached, Single family detached; [3] Geometry building MF: Multi-Family with 2 - 4 Units, Multi-Family with 5+ Units; [4] State: Census Region[5] State: National

.. _water_heater_in_unit:

Water Heater In Unit
--------------------

Description
***********

Individual water heater present or not present in the dwelling unit that solely serves the specific dwelling unit.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Single-Family Detached and Mobile Homes have in unit water heaters.; As Not Applicable option for Single-Family Attached option is 100%; Assuming Single-Family Attached in-unit water heater distribution from RECS 2009; Due to low sample sizes, fallback rules applied with lumping of:; [1] State: Census Division RECS; [2] Vintage ACS: Combining Vintage pre 1960s and post 2000; [3] State: Census Region

.. _window_areas:

Window Areas
------------

Description
***********

Window to wall ratios of the front, back, left, and right walls.

Created by
**********

sources/rbsa_II/tsv_maker.py

Source
******

2016-17 Residential Building Stock Assessment (RBSA) II microdata.

Assumption
**********

The window to wall ratios (WWR) are exponential weibull distributed.; Multi-Family with 2-4 Units distributions are independent of Geometry Stories; Multi-Family with 5+ Units distributions are grouped by 1-3 stories, 4-7 stories, and 8+ stories; High-rise Multi-family buildings (8+ stories) have a 30% window to wall ratio (WWR); SFD, SFA, and Mobile Homes are represented by the SFD window area distribution

.. _windows:

Windows
-------

Description
***********

Construction type and efficiency levels of windows.

Created by
**********

sources/recs/recs2020/tsv_maker.py

Source
******

U.S. EIA 2020 Residential Energy Consumption Survey (RECS) microdata.

Assumption
**********

Wood and Vinyl are considered same material; Triple Pane assumed to be 100% low-e; Only breaking out clear and low-e windows for the Double, Non-Metal frame type; Source of low-e distribution is based on engineering judgement, informed by high-levelsales trends observed in Ducker Worldwide studies of the U.S. Market for Windows, Doors and Skylights.; Due to low sample sizes, the following adjustments are made:; [1] Vintage data are grouped into: 1) <1960, 2) 1960-79, 3) 1980-99, 4) 2000s, 5) 2010s.; [2] Building Type data are grouped into: 1) Single-Family Detached, Single-Family Attached, and Mobile homes and 2) Multi-Family 2-4 units and Multi-Family 5+ units.; [3] Climate zones are grouped into: 1) 1A, 2A, 2B; 2) 3A, 3B, 3C, 4B; 3) 4A, 4C; 4) 5A, 5B; 5) 6A, 6B; and 6) 7A, 7B 7AK, 8AK.; [4] Federal Poverty Levels are progressively grouped together until all bins are combined.; [5] Tenure options are progressively grouped together until all bins are combined.; Storm window saturations are based on D&R International, Ltd. 'Residential Windows and Window Coverings: A Detailed View of the Installed Base and User Behavior' 2013. https://www.energy.gov/sites/prod/files/2013/11/f5/residential_windows_coverings.pdf. Cut the % storm windows by factor of 55% because only 55% of storms are installed year round; Due to lack of performance data storm windows with triple-pane are modeled without the storm windows; Due to lack of performance data Double-pane, Low-E, Non-Metal, Air, M-gain, Exterior Clear Storm windows are modeled as Double-pane, Clear, Non-Metal, Air, Exterior Clear Storm windows

