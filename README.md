OpenStudio-BuildStock
===================

BuildStock, built on the [OpenStudio platform](http://openstudio.net), is a project geared at modeling the existing building stock for, e.g., national, regional, or local analysis, using the [EnergyPlus simulation engine](http://energyplus.net). It consists of ResStock and ComStock, sister tools for modeling the residential and commercial building stock, respectively. 

This project is a <b>work-in-progress</b>.

Unit Test Status: [![CircleCI](https://circleci.com/gh/NREL/OpenStudio-BuildStock/tree/master.svg?style=svg)](https://circleci.com/gh/NREL/OpenStudio-BuildStock/tree/master)

Code Coverage: [![codecov](https://codecov.io/gh/NREL/OpenStudio-BuildStock/branch/master/graph/badge.svg)](https://codecov.io/gh/NREL/OpenStudio-BuildStock)

For more information, please visit the [documentation](http://resstock.readthedocs.io/en/latest/).

![BuildStock workflow](https://user-images.githubusercontent.com/5861765/32569254-da2895c8-c47d-11e7-93cb-05fb4c8806d7.png)

## ResStock for Multifamily Low-Rise

A [release](https://github.com/NREL/OpenStudio-BuildStock/releases/tag/v2.0.0) of ResStock with Multifamily Low-Rise capabilities is now available!

This dependency graph illustrates the relationship between the conditional probability distributions used to describe the U.S. residential building stock. Blue color indicates the parameters and dependencies added to represent for the low-rise multifamily sector.
![image](https://user-images.githubusercontent.com/1276021/40512741-fa539b58-5f60-11e8-8423-36efd677b81d.png)

## Running the Measures

The measures can be run via the standard OpenStudio approaches: the user interfaces ([OpenStudio Application](http://nrel.github.io/OpenStudio-user-documentation/reference/openstudio_application_interface/) and [Parametric Analysis Tool](http://nrel.github.io/OpenStudio-user-documentation/reference/parametric_analysis_tool_2/)), the [Command Line Interface](http://nrel.github.io/OpenStudio-user-documentation/reference/command_line_interface/), or via the [OpenStudio SDK](https://openstudio-sdk-documentation.s3.amazonaws.com/index.html).

If interested in programatically driving the simulations, you will likely find it easiest to use the Command Line Interface approach. The Command Line Interface is a self-contained executable that can run an OpenStudio Workflow file, which defines a series of OpenStudio measures to apply.

An example OpenStudio Workflow [(example_single_family_detached.osw)](https://github.com/NREL/OpenStudio-BuildStock/blob/master/workflows/example_single_family_detached.osw) is provided with a pre-populated selection of residential measures and arguments. It can be modified as needed and then run like so:

`openstudio.exe run -w example_single_family_detached.osw`

This will apply the measures, run the EnergyPlus simulation, and produce output. 

### Measure Order

The order in which these measures are called is important. For example, the Window Constructions measure must be called after windows have been added to the building. The table below documents the intended order of using these measures, and was automatically generated from a [JSON file](https://github.com/NREL/OpenStudio-BuildStock/blob/master/workflows/measure-info.json).

<nowiki>*</nowiki> Note: Nearly every measure is dependent on having the geometry defined first so this is not included in the table for readability purposes.

<!--- The below table is automated via a rake task -->
<!--- MEASURE_WORKFLOW_START -->
|Group|Measure|Dependencies*|
|:---|:---|:---|
|1. Simulation Controls|1. Simulation Controls||
|2. Location|1. Location||
|3. Geometry|1. Geometry - Create Single-Family Detached (or Single-Family Attached or Multifamily)||
||2. Door Area||
||3. Window/Skylight Area||
|4. Envelope Constructions|1. Unfinished Attic (or Finished Roof)||
||2. Wood Stud Walls (or Double Stud, CMU, SIP, etc.)||
||3. Slab (or Finished Basement, Unfinished Basement, Crawlspace, Pier & Beam)||
||4. Floors||
||5. Windows/Skylights|Window/Skylight Area, Location|
||6. Doors|Door Area|
||7. Shared Building Facades||
|5. Domestic Hot Water|1. Water Heater - Tank (or Tankless, Heat Pump, etc.)||
||2. Hot Water Fixtures|Water Heater|
||3. Hot Water Distribution|Hot Water Fixtures, Location|
||4. Solar Hot Water|Water Heater, Location|
|6. HVAC|1. Central Air Source Heat Pump (or AC/Furnace, Boiler, MSHP, etc.)||
||2. Heating Setpoint|HVAC Equipment, Location|
||3. Cooling Setpoint|HVAC Equipment, Location|
||4. Ceiling Fan|Cooling Setpoint|
||5. Dehumidifier|HVAC Equipment|
|7. Major Appliances|1. Refrigerator||
||2. Clothes Washer|Water Heater, Location|
||3. Clothes Dryer|Clothes Washer|
||4. Dishwasher|Water Heater, Location|
||5. Cooking Range||
|8. Lighting|1. Lighting|Location|
|9. Misc Loads|1. Plug Loads||
||2. Large, Uncommon Loads||
|10. Airflow|1. Airflow|Location, HVAC Equipment, Clothes Dryer|
|11. Sizing|1. HVAC Sizing|(lots of measures...)|
|12. Photovoltaics|1. Photovoltaics||
<!--- MEASURE_WORKFLOW_END -->