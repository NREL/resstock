.. _workflow_outputs:

Workflow Outputs
================

OpenStudio-HPXML generates a variety of annual (and optionally, timeseries) outputs for a residential HPXML-based model.
You can request the annual/timeseries output files be generated in either CSV or JSON formats.

Annual Outputs
--------------

OpenStudio-HPXML will always generate an annual output file called results_annual.csv (or results_annual.json), co-located with the EnergyPlus output.
The file includes the following sections of output:

Annual Energy Consumption by Fuel Use
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Current fuel uses are: 

   ==================================== ===========================
   Type                                 Notes
   ==================================== ===========================
   Fuel Use: Electricity: Total (MBtu)
   Fuel Use: Electricity: Net (MBtu)    Excludes any power produced by PV or generators.
   Fuel Use: Natural Gas: Total (MBtu)
   Fuel Use: Fuel Oil: Total (MBtu)     Includes "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "kerosene", and "diesel"
   Fuel Use: Propane: Total (MBtu)
   Fuel Use: Wood: Total (MBtu)
   Fuel Use: Wood Pellets: Total (MBtu)
   Fuel Use: Coal: Total (MBtu)         Includes "coal", "anthracite coal", "bituminous coal", and "coke".
   ==================================== ===========================

Annual Energy Consumption By End Use
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Current end uses are:

   =================================================================== ====================================================
   Type                                                                Notes
   =================================================================== ====================================================
   End Use: Electricity: Heating (MBtu)
   End Use: Electricity: Heating Fans/Pumps (MBtu)
   End Use: Electricity: Cooling (MBtu)
   End Use: Electricity: Cooling Fans/Pumps (MBtu)
   End Use: Electricity: Hot Water (MBtu)
   End Use: Electricity: Hot Water Recirc Pump (MBtu)
   End Use: Electricity: Hot Water Solar Thermal Pump (MBtu)
   End Use: Electricity: Lighting Interior (MBtu)
   End Use: Electricity: Lighting Garage (MBtu)
   End Use: Electricity: Lighting Exterior (MBtu)
   End Use: Electricity: Mech Vent (MBtu)
   End Use: Electricity: Mech Vent Preheating (MBtu)
   End Use: Electricity: Mech Vent Precooling (MBtu)
   End Use: Electricity: Whole House Fan (MBtu)
   End Use: Electricity: Refrigerator (MBtu)
   End Use: Electricity: Freezer (MBtu)
   End Use: Electricity: Dehumidifier (MBtu)
   End Use: Electricity: Dishwasher (MBtu)
   End Use: Electricity: Clothes Washer (MBtu)
   End Use: Electricity: Clothes Dryer (MBtu)
   End Use: Electricity: Range/Oven (MBtu)
   End Use: Electricity: Ceiling Fan (MBtu)
   End Use: Electricity: Television (MBtu)
   End Use: Electricity: Plug Loads (MBtu)
   End Use: Electricity: Electric Vehicle Charging (MBtu)
   End Use: Electricity: Well Pump (MBtu)
   End Use: Electricity: Pool Heater (MBtu)
   End Use: Electricity: Pool Pump (MBtu)
   End Use: Electricity: Hot Tub Heater (MBtu)
   End Use: Electricity: Hot Tub Pump (MBtu)
   End Use: Electricity: PV (MBtu)                                     Negative value for any power produced
   End Use: Electricity: Generator (MBtu)                              Negative value for power produced
   End Use: Natural Gas: Heating (MBtu)
   End Use: Natural Gas: Hot Water (MBtu)
   End Use: Natural Gas: Clothes Dryer (MBtu)
   End Use: Natural Gas: Range/Oven (MBtu)
   End Use: Natural Gas: Mech Vent Preheating (MBtu)
   End Use: Natural Gas: Mech Vent Precooling (MBtu)
   End Use: Natural Gas: Pool Heater (MBtu)
   End Use: Natural Gas: Hot Tub Heater (MBtu)
   End Use: Natural Gas: Grill (MBtu)
   End Use: Natural Gas: Lighting (MBtu)
   End Use: Natural Gas: Fireplace (MBtu)
   End Use: Natural Gas: Generator (MBtu)                              Positive value for any fuel consumed
   End Use: Fuel Oil: Heating (MBtu)
   End Use: Fuel Oil: Hot Water (MBtu)
   End Use: Fuel Oil: Clothes Dryer (MBtu)
   End Use: Fuel Oil: Range/Oven (MBtu)
   End Use: Fuel Oil: Mech Vent Preheating (MBtu)
   End Use: Fuel Oil: Mech Vent Precooling (MBtu)
   End Use: Fuel Oil: Grill (MBtu)
   End Use: Fuel Oil: Lighting (MBtu)
   End Use: Fuel Oil: Fireplace (MBtu)
   End Use: Propane: Heating (MBtu)
   End Use: Propane: Hot Water (MBtu)
   End Use: Propane: Clothes Dryer (MBtu)
   End Use: Propane: Range/Oven (MBtu)
   End Use: Propane: Mech Vent Preheating (MBtu)
   End Use: Propane: Mech Vent Precooling (MBtu)
   End Use: Propane: Grill (MBtu)
   End Use: Propane: Lighting (MBtu)
   End Use: Propane: Fireplace (MBtu)
   End Use: Propane: Generator (MBtu)                                  Positive value for any fuel consumed
   End Use: Wood Cord: Heating (MBtu)
   End Use: Wood Cord: Hot Water (MBtu)
   End Use: Wood Cord: Clothes Dryer (MBtu)
   End Use: Wood Cord: Range/Oven (MBtu)
   End Use: Wood Cord: Mech Vent Preheating (MBtu)
   End Use: Wood Cord: Mech Vent Precooling (MBtu)
   End Use: Wood Cord: Grill (MBtu)
   End Use: Wood Cord: Lighting (MBtu)
   End Use: Wood Cord: Fireplace (MBtu)
   End Use: Wood Pellets: Heating (MBtu)
   End Use: Wood Pellets: Hot Water (MBtu)
   End Use: Wood Pellets: Clothes Dryer (MBtu)
   End Use: Wood Pellets: Range/Oven (MBtu)
   End Use: Wood Pellets: Mech Vent Preheating (MBtu)
   End Use: Wood Pellets: Mech Vent Precooling (MBtu)
   End Use: Wood Pellets: Grill (MBtu)
   End Use: Wood Pellets: Lighting (MBtu)
   End Use: Wood Pellets: Fireplace (MBtu)
   End Use: Coal: Heating (MBtu)
   End Use: Coal: Hot Water (MBtu)
   End Use: Coal: Clothes Dryer (MBtu)
   End Use: Coal: Range/Oven (MBtu)
   End Use: Coal: Mech Vent Preheating (MBtu)
   End Use: Coal: Mech Vent Precooling (MBtu)
   End Use: Coal: Grill (MBtu)
   End Use: Coal: Lighting (MBtu)
   End Use: Coal: Fireplace (MBtu)
   =================================================================== ====================================================

Annual Building Loads
~~~~~~~~~~~~~~~~~~~~~

Current annual building loads are:

   ===================================== ==================================================================
   Type                                  Notes
   ===================================== ==================================================================
   Load: Heating (MBtu)                  Includes HVAC distribution losses.
   Load: Cooling (MBtu)                  Includes HVAC distribution losses.
   Load: Hot Water: Delivered (MBtu)     Includes contributions by desuperheaters or solar thermal systems.
   Load: Hot Water: Tank Losses (MBtu)
   Load: Hot Water: Desuperheater (MBtu) Load served by the desuperheater.
   Load: Hot Water: Solar Thermal (MBtu) Load served by the solar thermal system.
   ===================================== ==================================================================

Annual Unmet Building Loads
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Current annual unmet building loads are:

   ========================== =====
   Type                       Notes
   ========================== =====
   Unmet Load: Heating (MBtu)
   Unmet Load: Cooling (MBtu)
   ========================== =====

These numbers reflect the amount of heating/cooling load that is not met by the HVAC system, indicating the degree to which the HVAC system is undersized.
An HVAC system with sufficient capacity to perfectly maintain the thermostat setpoints will report an unmet load of zero.

Note that if a building has partial (or no) HVAC system, the unserved load will not be included in the unmet load outputs.
For example, if a building has a room air conditioner that meets 33% of the cooling load, the remaining 67% of the load is not included in the unmet load.
Rather, the unmet load is only the amount of load that the room AC *should* be serving but is not.

Peak Building Electricity
~~~~~~~~~~~~~~~~~~~~~~~~~

Current peak building electricity outputs are:

   ================================== =========================================================
   Type                               Notes
   ================================== =========================================================
   Peak Electricity: Winter Total (W) Winter season defined by operation of the heating system.
   Peak Electricity: Summer Total (W) Summer season defined by operation of the cooling system.
   ================================== =========================================================

Peak Building Loads
~~~~~~~~~~~~~~~~~~~

Current peak building loads are:

   ========================== ==================================
   Type                       Notes
   ========================== ==================================
   Peak Load: Heating (kBtu)  Includes HVAC distribution losses.
   Peak Load: Cooling (kBtu)  Includes HVAC distribution losses.
   ========================== ==================================

Annual Component Building Loads
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Component loads represent the estimated contribution of different building components to the annual heating/cooling building loads.
The sum of component loads for heating (or cooling) will roughly equal the annual heating (or cooling) building load reported above.
Current component loads disaggregated by Heating/Cooling are:
   
   ================================================= =========================================================================================================
   Type                                              Notes
   ================================================= =========================================================================================================
   Component Load: \*: Roofs (MBtu)                  Heat gain/loss through HPXML ``Roof`` elements adjacent to conditioned space
   Component Load: \*: Ceilings (MBtu)               Heat gain/loss through HPXML ``FrameFloor`` elements (inferred to be ceilings) adjacent to conditioned space
   Component Load: \*: Walls (MBtu)                  Heat gain/loss through HPXML ``Wall`` elements adjacent to conditioned space
   Component Load: \*: Rim Joists (MBtu)             Heat gain/loss through HPXML ``RimJoist`` elements adjacent to conditioned space
   Component Load: \*: Foundation Walls (MBtu)       Heat gain/loss through HPXML ``FoundationWall`` elements adjacent to conditioned space
   Component Load: \*: Doors (MBtu)                  Heat gain/loss through HPXML ``Door`` elements adjacent to conditioned space
   Component Load: \*: Windows (MBtu)                Heat gain/loss through HPXML ``Window`` elements adjacent to conditioned space, including solar
   Component Load: \*: Skylights (MBtu)              Heat gain/loss through HPXML ``Skylight`` elements adjacent to conditioned space, including solar
   Component Load: \*: Floors (MBtu)                 Heat gain/loss through HPXML ``FrameFloor`` elements (inferred to be floors) adjacent to conditioned space
   Component Load: \*: Slabs (MBtu)                  Heat gain/loss through HPXML ``Slab`` elements adjacent to conditioned space
   Component Load: \*: Internal Mass (MBtu)          Heat gain/loss from internal mass (e.g., furniture, interior walls/floors) in conditioned space
   Component Load: \*: Infiltration (MBtu)           Heat gain/loss from airflow induced by stack and wind effects
   Component Load: \*: Natural Ventilation (MBtu)    Heat gain/loss from airflow through operable windows
   Component Load: \*: Mechanical Ventilation (MBtu) Heat gain/loss from airflow/fan energy from mechanical ventilation systems (including clothes dryer exhaust)
   Component Load: \*: Whole House Fan (MBtu)        Heat gain/loss from airflow due to a whole house fan
   Component Load: \*: Ducts (MBtu)                  Heat gain/loss from conduction and leakage losses through supply/return ducts outside conditioned space
   Component Load: \*: Internal Gains (MBtu)         Heat gain/loss from appliances, lighting, plug loads, water heater tank losses, etc. in the conditioned space
   ================================================= =========================================================================================================

Annual Hot Water Uses
~~~~~~~~~~~~~~~~~~~~~

Current annual hot water uses are:

   =================================== ====================
   Type                                Notes
   =================================== ====================
   Hot Water: Clothes Washer (gal)
   Hot Water: Dishwasher (gal)
   Hot Water: Fixtures (gal)           Showers and faucets.
   Hot Water: Distribution Waste (gal) 
   =================================== ====================


Timeseries Outputs
------------------

OpenStudio-HPXML can optionally generate a timeseries output file.
The timeseries output file is called results_timeseries.csv (or results_timeseries.json) and co-located with the EnergyPlus output.

Depending on the outputs requested, the file may include:

   =================================== ==================================================================================================================================
   Type                                Notes
   =================================== ==================================================================================================================================
   Fuel Consumptions                   Energy use for each fuel type (in kBtu for fossil fuels and kWh for electricity).
   End Use Consumptions                Energy use for each end use type (in kBtu for fossil fuels and kWh for electricity).
   Hot Water Uses                      Water use for each end use type (in gallons).
   Total Loads                         Heating, cooling, and hot water loads (in kBtu) for the building.
   Component Loads                     Heating and cooling loads (in kBtu) disaggregated by component (e.g., Walls, Windows, Infiltration, Ducts, etc.).
   Unmet Loads                         Unmet heating and cooling loads (in kBtu) for the building.
   Zone Temperatures                   Average temperatures (in deg-F) for each space modeled (e.g., living space, attic, garage, basement, crawlspace, etc.).
   Airflows                            Airflow rates (in cfm) for infiltration, mechanical ventilation (including clothes dryer exhaust), natural ventilation, whole house fans.
   Weather                             Weather file data including outdoor temperatures, relative humidity, wind speed, and solar.
   =================================== ==================================================================================================================================
