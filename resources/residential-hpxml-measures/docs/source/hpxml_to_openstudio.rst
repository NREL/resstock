HPXMLtoOpenStudio Measure
=========================

The HPXMLtoOpenStudio measure requires a building description in an `HPXML file <https://hpxml.nrel.gov/>`_ format.
HPXML is an open data standard for collecting and transferring home energy data. 
Using HPXML files reduces the complexity and effort for software developers to leverage the EnergyPlus simulation engine.

Capabilities
------------

The following building features/technologies are available for modeling via the HPXMLtoOpenStudio measure:

- Enclosure

  - Attics
  
    - Vented
    - Unvented
    - Conditioned
    - Radiant Barriers
    
  - Foundations
  
    - Slab
    - Unconditioned Basement
    - Conditioned Basement
    - Vented Crawlspace
    - Unvented Crawlspace
    - Ambient
    
  - Garages
  - Windows & Overhangs
  - Skylights
  - Doors
  
- HVAC

  - Heating Systems
  
    - Electric Resistance
    - Furnaces
    - Wall Furnaces & Stoves
    - Boilers
    - Portable Heaters
    
  - Cooling Systems
  
    - Central Air Conditioners
    - Room Air Conditioners
    - Evaporative Coolers
    
  - Heat Pumps
  
    - Air Source Heat Pumps
    - Mini Split Heat Pumps
    - Ground Source Heat Pumps
    - Dual-Fuel Heat Pumps
    
  - Setpoints
  - Ducts
  
- Water Heating

  - Water Heaters
  
    - Storage Tank
    - Instantaneous Tankless
    - Heat Pump Water Heater
    - Indirect Water Heater (Combination Boiler)
    - Tankless Coil (Combination Boiler)

  - Solar Hot Water
  - Desuperheaters
  - Hot Water Distribution
  
    - Recirculation
    
  - Drain Water Heat Recovery
  - Low-Flow Fixtures
  
- Mechanical Ventilation

  - Exhaust Only
  - Supply Only
  - Balanced
  - Energy Recovery Ventilator
  - Heat Recovery Ventilator
  - Central Fan Integrated Supply
  
- Whole House Fan
- Photovoltaics
- Appliances

  - Clothes Washer
  - Clothes Dryer
  - Dishwasher
  - Refrigerator
  - Cooking Range/Oven
  
- Lighting
- Ceiling Fans
- Plug Loads

EnergyPlus Use Case for HPXML
-----------------------------

HPXML is an flexible and extensible format, where nearly all elements in the schema are optional and custom elements can be included.
Because of this, an EnergyPlus Use Case for HPXML has been developed that specifies the HPXML elements or enumeration choices required to run the measure.

Software developers should use the EnergyPlus Use Case (found at ``HPXMLtoOpenStudio/resources/EPvalidator.rb``, which defines sets of conditional XPath expressions) as well as the HPXML schema (HPXML.xsd) to construct valid HPXML files for EnergyPlus simulations.

The `HPXML Toolbox website <https://hpxml.nrel.gov/>`_ also provides several resources for software developers, including:

#. An interactive schema validator
#. A data dictionary
#. An implementation guide

Building Details
~~~~~~~~~~~~~~~~

The building description is entered in HPXML's ``/HPXML/Building/BuildingDetails``.

Building Summary
~~~~~~~~~~~~~~~~

This section describes elements specified in HPXML's ``BuildingSummary``. 
It is used for high-level building information including conditioned floor area, number of bedrooms, number of residents, number of conditioned floors, etc.
Most occupancy assumptions are based on the number of bedrooms, while the number of residents is solely used to determine heat gains from the occupants themselves.

Shading due to neighboring buildings can be defined inside an ``Site/extension/Neighbors`` element.
Each ``Neighbors/NeighborBuilding`` element is required to have an ``Azimuth`` and ``Distance`` from the house.
A ``Height`` is also optionally allowed; if not provided, the neighbor is assumed to be the same height as the house.

The local shelter coefficient can be entered as ``Site/extension/ShelterCoefficient``.
The shelter coefficient is defined by the AIM-2 infiltration model to account for nearby buildings, trees and obstructions.
If not provided, the value of 0.5 will be assumed.

===================  =========================================================================
Shelter Coefficient  Description
===================  =========================================================================
1.0                  No obstructions or local shielding
0.9                  Light local shielding with few obstructions within two building heights
0.7                  Local shielding with many large obstructions within two building heights
0.5                  Heavily shielded, many large obstructions within one building height
0.3                  Complete shielding with large buildings immediately adjacent
===================  =========================================================================

The terrain surrounding the building is assumed to be suburban.

Finally, natural ventilation can be disabled by setting true for ``Site/extension/DisableNaturalVentilation``.
If not specified, natural ventilation is assumed to be available year-round to reduce space cooling, with airflow influenced by the amount of window area.

Weather File
~~~~~~~~~~~~

The ``ClimateandRiskZones/WeatherStation`` element specifies the EnergyPlus weather file (EPW) to be used in the simulation.
The weather file can be entered in one of two ways:

#. Using the ``WeatherStation/WMO``, which must be one of the acceptable TMY3 WMO station numbers found in the ``weather/data.csv`` file.
   The full set of U.S. TMY3 weather files can be `downloaded here <http://s3.amazonaws.com/epwweatherfiles/tmy3s-cache-csv.zip>`_.
#. Using the ``WeatherStation/extension/EPWFileName``.

Enclosure
~~~~~~~~~

This section describes elements specified in HPXML's ``Enclosure``.

All surfaces that bound different space types in the building (i.e., not just thermal boundary surfaces) must be specified in the HPXML file.
For example, an attached garage would generally be defined by walls adjacent to conditioned space, walls adjacent to outdoors, a slab, and a roof or ceiling.

The space types used in the HPXML building description are:

============================  ===================================
Space Type                    Notes
============================  ===================================
living space                  Above-grade conditioned floor area.
attic - vented            
attic - unvented          
basement - conditioned        Below-grade conditioned floor area.
basement - unconditioned  
crawlspace - vented       
crawlspace - unvented     
garage                    
other housing unit            Used to specify adiabatic surfaces.
============================  ===================================

.. warning::

  It is the software tool's responsibility to provide the appropriate building surfaces. 
  While some error-checking is in place, it is not possible to know whether some surfaces are incorrectly missing.

Also note that wall and roof surfaces do not require an azimuth to be specified. 
Rather, only the windows/skylights themselves require an azimuth. 
Thus, software tools can choose to use a single wall (or roof) surface to represent multiple wall (or roof) surfaces for the entire building if all their other properties (construction type, interior/exterior adjacency, etc.) are identical.

Air Leakage
***********

Building air leakage characterized by air changes per hour or cfm at 50 pascals pressure difference (ACH50 or CFM50) is entered at ``Enclosure/AirInfiltration/AirInfiltrationMeasurement/BuildingAirLeakage/AirLeakage``.
The ``Enclosure/AirInfiltration/AirInfiltrationMeasurement`` should be specified with ``HousePressure='50'`` and ``BuildingAirLeakage/UnitofMeasure='ACH'`` or ``BuildingAirLeakage/UnitofMeasure='CFM'``.

In addition, the building's volume associated with the air leakage measurement can be provided in HPXML's ``AirInfiltrationMeasurement/InfiltrationVolume``.
If not provided, the infiltration volume is assumed to be equal to the conditioned building volume.

Vented Attics/Crawlspaces
*************************

The ventilation rate for vented attics (or crawlspaces) can be specified using an ``Attic`` (or ``Foundation``) element.
First, define the ``AtticType`` as ``Attic[Vented='true']`` (or ``FoundationType`` as ``Crawlspace[Vented='true']``).
Then use the ``VentilationRate[UnitofMeasure='SLA']/Value`` element to specify a specific leakage area (SLA).
If these elements are not provided, default values will be used.

Roofs
*****

Pitched or flat roof surfaces that are exposed to ambient conditions should be specified as an ``Enclosure/Roofs/Roof``. 
For a multifamily building where the dwelling unit has another dwelling unit above it, the surface between the two dwelling units should be considered a ``FrameFloor`` and not a ``Roof``.

Beyond the specification of typical heat transfer properties (insulation R-value, solar absorptance, emittance, etc.), note that roofs can be defined as having a radiant barrier.

Walls
*****

Any wall that has no contact with the ground and bounds a space type should be specified as an ``Enclosure/Walls/Wall``. 
Interior walls (for example, walls solely within the conditioned space of the building) are not required.

Walls are primarily defined by their ``Insulation/AssemblyEffectiveRValue``.
The choice of ``WallType`` has a secondary effect on heat transfer in that it informs the assumption of wall thermal mass.

Rim Joists
**********

Rim joists, the perimeter of floor joists typically found between stories of a building or on top of a foundation wall, are specified as an ``Enclosure//RimJoists/RimJoist``.

The ``InteriorAdjacentTo`` element should typically be "living space" for rim joists between stories of a building and "basement - conditioned", "basement - unconditioned", "crawlspace - vented", or "crawlspace - unvented" for rim joists on top of a foundation wall.

Foundation Walls
****************

Any wall that is in contact with the ground should be specified as an ``Enclosure/FoundationWalls/FoundationWall``.
Other walls (e.g., wood framed walls) that are connected to a below-grade space but have no contact with the ground should be specified as ``Walls`` and not ``FoundationWalls``.

*Exterior* foundation walls (i.e., those that fall along the perimeter of the building's footprint) should use "ground" for ``ExteriorAdjacentTo`` and the appropriate space type (e.g., "basement - unconditioned") for ``InteriorAdjacentTo``.

*Interior* foundation walls should be specified with two appropriate space types (e.g., "crawlspace - vented" and "garage", or "basement - unconditioned" and "crawlspace - unvented") for ``InteriorAdjacentTo`` and ``ExteriorAdjacentTo``.
Interior foundation walls should never use "ground" for ``ExteriorAdjacentTo`` even if the foundation wall has some contact with the ground due to the difference in below-grade depths of the two adjacent space types.

Foundations must include a ``Height`` as well as a ``DepthBelowGrade``. 
For exterior foundation walls, the depth below grade is relative to the ground plane.
For interior foundation walls, the depth below grade **should not** be thought of as relative to the ground plane, but rather as the depth of foundation wall in contact with the ground.
For example, an interior foundation wall between an 8 ft conditioned basement and a 3 ft crawlspace has a height of 8 ft and a depth below grade of 5 ft.
Alternatively, an interior foundation wall between an 8 ft conditioned basement and an 8 ft unconditioned basement has a height of 8 ft and a depth below grade of 0 ft.

Foundation wall insulation can be described in two ways: 

Option 1. Both interior and exterior continuous insulation layers with ``NominalRValue``, ``extension/DistanceToTopOfInsulation``, and ``extension/DistanceToBottomOfInsulation``. 
Insulation layers are particularly useful for describing foundation wall insulation that doesn't span the entire height (e.g., 4 ft of insulation for an 8 ft conditioned basement). 
If there is not insulation on the interior and/or exterior of the foundation wall, the continuous insulation layer must still be provided -- with the nominal R-value, etc., set to zero.
When insulation is specified with option 1, it is modeled with a concrete wall (whose ``Thickness`` is provided) as well as air film resistances as appropriate.

Option 2. An ``AssemblyEffectiveRValue``. 
The assembly effective R-value should include the concrete wall and an interior air film resistance. 
The exterior air film resistance (for any above-grade exposure) or any soil thermal resistance should **not** be included.

Frame Floors
************

Any horizontal floor/ceiling surface that is not in contact with the ground (Slab) nor adjacent to ambient conditions above (Roof) should be specified as an ``Enclosure/FrameFloors/FrameFloor``.

Frame floors are primarily defined by their ``Insulation/AssemblyEffectiveRValue``.

Slabs
*****

Any space type that borders the ground should include an ``Enclosure/Slabs/Slab`` surface with the appropriate ``InteriorAdjacentTo``. 
This includes basements, crawlspaces (even when there are dirt floors -- use zero for the ``Thickness``), garages, and slab-on-grade foundations.

A primary input for a slab is its ``ExposedPerimeter``. 
The exposed perimeter should include any slab length that falls along the perimeter of the building's footprint (i.e., is exposed to ambient conditions).
So, a basement slab edge adjacent to a garage or crawlspace, for example, should not be included.

Vertical insulation adjacent to the slab can be described by a ``PerimeterInsulation/Layer/NominalRValue`` and a ``PerimeterInsulationDepth``.

Horizontal insulation under the slab can be described by a ``UnderSlabInsulation/Layer/NominalRValue``. 
The insulation can either have a fixed width (``UnderSlabInsulationWidth``) or can span the entire slab (``UnderSlabInsulationSpansEntireSlab``).

For foundation types without walls, the ``DepthBelowGrade`` element must be provided.
For foundation types with walls, the ``DepthBelowGrade`` element is not used; instead the slab's position relative to grade is determined by the ``FoundationWall/DepthBelowGrade`` values.

Windows
*******

Any window or glass door area should be specified as an ``Enclosure/Windows/Window``.

Windows are defined by *full-assembly* NFRC ``UFactor`` and ``SHGC``, as well as ``Area``.
Windows must reference a HPXML ``Enclosures/Walls/Wall`` element via the ``AttachedToWall``.
Windows must also have an ``Azimuth`` specified, even if the attached wall does not.

In addition, the summer/winter interior shading coefficients can be optionally entered as ``InteriorShading/SummerShadingCoefficient`` and ``InteriorShading/WinterShadingCoefficient``.
The summer interior shading coefficient must be less than or equal to the winter interior shading coefficient.
Note that a value of 0.7 indicates a 30% reduction in solar gains (i.e., 30% shading).
If not provided, default values will be assumed.

Overhangs (e.g., a roof eave) can optionally be defined for a window by specifying a ``Window/Overhangs`` element.
Overhangs are defined by the vertical distance between the overhang and the top of the window (``DistanceToTopOfWindow``), and the vertical distance between the overhang and the bottom of the window (``DistanceToBottomOfWindow``).
The difference between these two values equals the height of the window.

Skylights
*********

Any skylight should be specified as an ``Enclosure/Skylights/Skylight``.

Skylights are defined by *full-assembly* NFRC ``UFactor`` and ``SHGC``, as well as ``Area``.
Skylights must reference a HPXML ``Enclosures/Roofs/Roof`` element via the ``AttachedToRoof``.
Skylights must also have an ``Azimuth`` specified, even if the attached roof does not.

Doors
*****

Any opaque doors should be specified as an ``Enclosure/Doors/Door``.

Doors are defined by ``RValue`` and ``Area``.
Doors must reference a HPXML ``Enclosures/Walls/Wall`` element via the ``AttachedToWall``.
Doors must also have an ``Azimuth`` specified, even if the attached wall does not.

Systems
~~~~~~~

This section describes elements specified in HPXML's ``Systems``.

If any HVAC systems are entered that provide heating (or cooling), the sum of all their ``FractionHeatLoadServed`` (or ``FractionCoolLoadServed``) values must be less than or equal to 1.
For example, a room air conditioner might be specified with ``FractionCoolLoadServed`` equal to 0.3 if it serves 30% of the home's conditioned floor area.

If any water heating systems are entered, the sum of all their ``FractionDHWLoadServed`` values must be equal to 1.

.. note:: 

  HVAC systems (Heating Systems, Cooling Systems, and Heat Pumps) can be autosized via ACCA Manual J/S by using -1 as the capacity.
  For a given system, all capacities must either be autosized or user-specified.
  For example, an air-to-air heat pump must have its heating capacity, cooling capacity, and backup heating capacity all autosized or user-specified.

Heating Systems
***************

Each heating system (other than heat pumps) should be entered as a ``Systems/HVAC/HVACPlant/HeatingSystem``.
Inputs including ``HeatingSystemType``, ``HeatingCapacity``, and ``FractionHeatLoadServed`` must be provided.

Depending on the type of heating system specified, additional elements are required:

==================  ===========================  =================  =======================
HeatingSystemType   DistributionSystem           HeatingSystemFuel  AnnualHeatingEfficiency
==================  ===========================  =================  =======================
ElectricResistance                               electricity        Percent
Furnace             AirDistribution or DSE       <any>              AFUE
WallFurnace                                      <any>              AFUE
Boiler              HydronicDistribution or DSE  <any>              AFUE
Stove                                            <any>              Percent
PortableHeater                                   <any>              Percent
==================  ===========================  =================  =======================

If a non-electric heating system is specified, the ``ElectricAuxiliaryEnergy`` element may be provided if available. 

Cooling Systems
***************

Each cooling system (other than heat pumps) should be entered as a ``Systems/HVAC/HVACPlant/CoolingSystem``.
Inputs including ``CoolingSystemType`` and ``FractionCoolLoadServed`` must be provided.
``CoolingCapacity`` must also be provided for all systems other than evaporative coolers.

Depending on the type of cooling system specified, additional elements are required/available:

=======================  =================================  =================  =======================  ====================
CoolingSystemType        DistributionSystem                 CoolingSystemFuel  AnnualCoolingEfficiency  SensibleHeatFraction
=======================  =================================  =================  =======================  ====================
central air conditioner  AirDistribution or DSE             electricity        SEER                     (optional)
room air conditioner                                        electricity        EER                      (optional)
evaporative cooler       AirDistribution or DSE (optional)  electricity
=======================  =================================  =================  =======================  ====================

Heat Pumps
**********

Each heat pump should be entered as a ``Systems/HVAC/HVACPlant/HeatPump``.
Inputs including ``HeatPumpType``, ``CoolingCapacity``, ``HeatingCapacity``, ``FractionHeatLoadServed``, and ``FractionCoolLoadServed`` must be provided.
Note that heat pumps are allowed to provide only heating (``FractionCoolLoadServed`` = 0) or cooling (``FractionHeatLoadServed`` = 0) if appropriate.

Depending on the type of heat pump specified, additional elements are required/available:

=============  =================================  ============  =======================  =======================  ===========================  ==================
HeatPumpType   DistributionSystem                 HeatPumpFuel  AnnualCoolingEfficiency  AnnualHeatingEfficiency  CoolingSensibleHeatFraction  HeatingCapacity17F
=============  =================================  ============  =======================  =======================  ===========================  ==================
air-to-air     AirDistribution or DSE             electricity   SEER                     HSPF                     (optional)                   (optional)
mini-split     AirDistribution or DSE (optional)  electricity   SEER                     HSPF                     (optional)                   (optional)
ground-to-air  AirDistribution or DSE             electricity   EER                      COP                      (optional)
=============  =================================  ============  =======================  =======================  ===========================  ==================

If the heat pump has backup heating, it can be specified with ``BackupSystemFuel``, ``BackupAnnualHeatingEfficiency``, and ``BackupHeatingCapacity``.
If the heat pump has a switchover temperature (e.g., dual-fuel heat pump) where the heat pump stops operating and the backup heating system starts running, it can be specified with ``BackupHeatingSwitchoverTemperature``.
If the ``BackupHeatingSwitchoverTemperature`` is not provided, the backup heating system will operate as needed when the heat pump has insufficient capacity.

Thermostat
**********

A ``Systems/HVAC/HVACControl`` must be provided if any HVAC systems are specified.
The heating setpoint (``SetpointTempHeatingSeason``) and cooling setpoint (``SetpointTempCoolingSeason``) are required elements.

If there is a heating setback, it is defined with:

- Temperature during heating setback (``SetbackTempHeatingSeason``)
- The start hour of the heating setback where 0=midnight and 12=noon (``extension/SetbackStartHourHeating``)
- The number of hours of heating setback per week (``TotalSetbackHoursperWeekHeating``)

If there is a cooling setup, it is defined with:

- Temperature during cooling setup (``SetupTempCoolingSeason``)
- The start hour of the cooling setup where 0=midnight and 12=noon (``extension/SetupStartHourCooling``)
- The number of hours of cooling setup per week (``TotalSetupHoursperWeekCooling``)

Finally, if there are sufficient ceiling fans present that result in a reduced cooling setpoint, this offset can be specified with ``extension/CeilingFanSetpointTempCoolingSeasonOffset``.

HVAC Distribution
*****************

Each separate HVAC distribution system should be specified as a ``Systems/HVAC/HVACDistribution``.
There should be at most one heating system and one cooling system attached to a distribution system.
See the sections on Heating Systems, Cooling Systems, and Heat Pumps for information on which ``DistributionSystemType`` is allowed for which HVAC system.
Also, note that some HVAC systems (e.g., room air conditioners) are not allowed to be attached to a distribution system.

``AirDistribution`` systems are defined by:

- Supply leakage to the outside in CFM25 or percent of airflow (``DuctLeakageMeasurement[DuctType='supply']/DuctLeakage/Value``)
- Optional return leakage to the outside in CFM25 or percent of airflow (``DuctLeakageMeasurement[DuctType='return']/DuctLeakage/Value``)
- Optional supply ducts (``Ducts[DuctType='supply']``)
- Optional return ducts (``Ducts[DuctType='return']``)

For each duct, ``DuctInsulationRValue``, ``DuctLocation``, and ``DuctSurfaceArea`` must be provided.

``HydronicDistribution`` systems do not require any additional inputs.

``DSE`` systems are defined by a ``AnnualHeatingDistributionSystemEfficiency`` and ``AnnualCoolingDistributionSystemEfficiency`` elements.

.. warning::

  Specifying a DSE for the HVAC distribution system will NOT be reflected in the EnergyPlus simulation outputs.

Mechanical Ventilation
**********************

A single whole-house mechanical ventilation system may be specified as a ``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` with ``UsedForWholeBuildingVentilation='true'``.
Inputs including ``FanType``, ``TestedFlowRate`` (or ``RatedFlowRate``), ``HoursInOperation``, and ``FanPower`` must be provided.

Depending on the type of mechanical ventilation specified, additional elements are required:

====================================  ==========================  =======================  ================================
FanType                               SensibleRecoveryEfficiency  TotalRecoveryEfficiency  AttachedToHVACDistributionSystem
====================================  ==========================  =======================  ================================
energy recovery ventilator            required                    required
heat recovery ventilator              required
exhaust only
supply only
balanced
central fan integrated supply (CFIS)                                                       required
====================================  ==========================  =======================  ================================

Note that AdjustedSensibleRecoveryEfficiency and AdjustedTotalRecoveryEfficiency can be provided instead.

In many situations, the rated flow rate should be the value derived from actual testing of the system.
For a CFIS system, the rated flow rate should equal the amount of outdoor air provided to the distribution system.

Whole House Fan
***************

A single whole house fan may be specified as a ``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` with ``UsedForSeasonalCoolingLoadReduction='true'``.
Required elements include ``RatedFlowRate`` and ``FanPower``.

The whole house fan is assumed to operate during hours of favorable outdoor conditions.
If available, it will take priority over natural ventilation.

Water Heaters
*************

Each water heater should be entered as a ``Systems/WaterHeating/WaterHeatingSystem``.
Inputs including ``WaterHeaterType``, ``Location``, and ``FractionDHWLoadServed`` must be provided.

Depending on the type of water heater specified, additional elements are required/available:

========================================  ===================================  ===========  ==========  ===============  ========================  =================  =================  =========================================
WaterHeaterType                           UniformEnergyFactor or EnergyFactor  FuelType     TankVolume  HeatingCapacity  RecoveryEfficiency        RelatedHVACSystem  UsesDesuperheater  WaterHeaterInsulation/Jacket/JacketRValue
========================================  ===================================  ===========  ==========  ===============  ========================  =================  =================  =========================================
storage water heater                      required                             <any>        required    <optional>       required if non-electric                     <optional>         <optional>
instantaneous water heater                required                             <any>                                                                                  <optional>
heat pump water heater                    required                             electricity  required                                                                                     <optional>
space-heating boiler with storage tank                                                      required                                               required                              <optional>
space-heating boiler with tankless coil                                                                                                            required           
========================================  ===================================  ===========  ==========  ===============  ========================  =================  =================  =========================================

For tankless water heaters, an annual energy derate due to cycling inefficiencies can be provided.
If not provided, a value of 0.08 (8%) will be assumed.

For combi boiler systems, the ``RelatedHVACSystem`` must point to a ``HeatingSystem`` of type "Boiler".
For combi boiler systems with a storage tank, the storage tank losses (deg-F/hr) can be entered as ``extension/StandbyLoss``; if not provided, an average value will be used.

For water heaters that are connected to a desuperheater, the ``RelatedHVACSystem`` must either point to a ``HeatPump`` or a ``CoolingSystem``.

Hot Water Distribution
**********************

A ``Systems/WaterHeating/HotWaterDistribution`` must be provided if any water heating systems are specified.
Inputs including ``SystemType`` and ``PipeInsulation/PipeRValue`` must be provided.

For a ``SystemType/Standard`` (non-recirculating) system, the following element is required:

- ``PipingLength``: Measured length of hot water piping from the hot water heater to the farthest hot water fixture, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 10 feet of piping for each floor level, plus 5 feet of piping for unconditioned basements (if any)

For a ``SystemType/Recirculation`` system, the following elements are required:

- ``ControlType``
- ``RecirculationPipingLoopLength``: Measured recirculation loop length including both supply and return sides, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 20 feet of piping for each floor level greater than one plus 10 feet of piping for unconditioned basements
- ``BranchPipingLoopLength``: Measured length of the branch hot water piping from the recirculation loop to the farthest hot water fixture from the recirculation loop, measured longitudinally from plans, assuming the branch hot water piping does not run diagonally
- ``PumpPower``

In addition, a ``HotWaterDistribution/DrainWaterHeatRecovery`` (DWHR) may be specified.
The DWHR system is defined by:

- ``FacilitiesConnected``: 'one' if there are multiple showers and only one of them is connected to a DWHR; 'all' if there is one shower and it's connected to a DWHR or there are two or more showers connected to a DWHR
- ``EqualFlow``: 'true' if the DWHR supplies pre-heated water to both the fixture cold water piping and the hot water heater potable supply piping
- ``Efficiency``: As rated and labeled in accordance with CSA 55.1

Water Fixtures
**************

Water fixtures should be entered as ``Systems/WaterHeating/WaterFixture`` elements.
Each fixture must have ``WaterFixtureType`` and ``LowFlow`` elements provided.
Fixtures should be specified as low flow if they are <= 2.0 gpm.

Solar Thermal
*************

A solar hot water system can be entered as a ``Systems/SolarThermal/SolarThermalSystem``.
The ``SystemType`` element must be 'hot water' and the ``ConnectedTo`` element is required and must point to a ``WaterHeatingSystem``.
Note that the connected water heater cannot be of type space-heating boiler or attached to a desuperheater.

Solar hot water systems can be described with either simple or detailed inputs.

If using simple inputs, the following element is required:

- ``SolarFraction``

If using detailed inputs, the following elements are required:

- ``CollectorLoopType``: 'liquid indirect' or 'liquid direct' or 'passive thermosyphon'
- ``CollectorType``: 'single glazing black' or 'double glazing black' or 'evacuated tube' or 'integrated collector storage'
- ``CollectorAzimuth``
- ``CollectorTilt``
- ``CollectorRatedOpticalEfficiency``: FRTA (y-intercept); see Directory of SRCC Certified Solar Collector Ratings
- ``CollectorRatedThermalLosses``: FRUL (slope, in units of Btu/hr-ft^2-R); see Directory of SRCC Certified Solar Collector Ratings
- ``StorageVolume``

Photovoltaics
*************

Each solar electric (photovoltaic) system should be entered as a ``Systems/Photovoltaics/PVSystem``.
The following elements, some adopted from the `PVWatts model <https://pvwatts.nrel.gov>`_, are required for each PV system:

- ``Location``: 'ground' or 'roof' mounted
- ``ModuleType``: 'standard', 'premium', or 'thin film'
- ``Tracking``: 'fixed' or '1-axis' or '1-axis backtracked' or '2-axis'
- ``ArrayAzimuth``
- ``ArrayTilt``
- ``MaxPowerOutput``
- ``InverterEfficiency``: Default is 0.96.
- ``SystemLossesFraction``: Default is 0.14. System losses include soiling, shading, snow, mismatch, wiring, degradation, etc.

Appliances
~~~~~~~~~~

This section describes elements specified in HPXML's ``Appliances``.
Many of the appliances' inputs are derived from EnergyGuide labels.

The ``Location`` for clothes washers, clothes dryers, and refrigerators can be provided, while dishwashers and cooking ranges are assumed to be in the living space.

Clothes Washer
**************

An ``Appliances/ClothesWasher`` element can be specified; if not provided, a clothes washer will not be modeled.
The efficiency of the clothes washer can either be entered as a ``ModifiedEnergyFactor`` or an ``IntegratedModifiedEnergyFactor``.
Several other inputs from the EnergyGuide label must be provided as well.

Clothes Dryer
*************

An ``Appliances/ClothesDryer`` element can be specified; if not provided, a clothes dryer will not be modeled.
The dryer's ``FuelType`` and ``ControlType`` ("timer" or "moisture") must be provided.
The efficiency of the clothes dryer can either be entered as an ``EnergyFactor`` or ``CombinedEnergyFactor``.


Dishwasher
**********

An ``Appliances/Dishwasher`` element can be specified; if not provided, a dishwasher will not be modeled.
The dishwasher's ``PlaceSettingCapacity`` must be provided.
The efficiency of the dishwasher can either be entered as an ``EnergyFactor`` or ``RatedAnnualkWh``.

Refrigerator
************

An ``Appliances/Refrigerator`` element can be specified; if not provided, a refrigerator will not be modeled.
The efficiency of the refrigerator must be entered as ``RatedAnnualkWh``.

Cooking Range/Oven
******************

``Appliances/CookingRange`` and ``Appliances/Oven`` elements can be specified; if not provided, a range/oven will not be modeled.
The ``FuelType`` of the range and whether it ``IsInduction``, as well as whether the oven ``IsConvection``, must be provided.

Lighting
~~~~~~~~

The building's lighting is described by six ``Lighting/LightingGroup`` elements, each of which is the combination of:

- ``LightingGroup/ThirdPartyCertification``: 'ERI Tier I' (fluorescent) and 'ERI Tier II' (LEDs, outdoor lamps controlled by photocells, or indoor lamps controlled by motion sensor)
- ``LightingGroup/Location``: 'interior', 'garage', and 'exterior'

The fraction of lamps of the given type in the given location are provided as the ``LightingGroup/FractionofUnitsInLocation``.
The fractions for a given location cannot sum to greater than 1.
If the fractions sum to less than 1, the remainder is assumed to be incandescent lighting.
Garage lighting values are ignored if the building has no garage.

To model a building without any lighting, all six ``Lighting/LightingGroup`` elements must be excluded.

Ceiling Fans
~~~~~~~~~~~~

Each ceiling fan (or set of identical ceiling fans) should be entered as a ``Lighting/CeilingFan``.
The ``Airflow/Efficiency`` (at medium speed) and ``Quantity`` can be provided, otherwise default assumptions are used.

In addition, a reduced cooling setpoint can be specified for summer months when ceiling fans are operating.
See the Thermostat section for more information.

Plug Loads
~~~~~~~~~~

Plug loads can be provided by entering ``MiscLoads/PlugLoad`` elements; if not provided, plug loads will not be modeled.
Currently only plug loads specified with ``PlugLoadType='other'`` and ``PlugLoadType='TV other'`` are recognized.
The annual energy consumption (``Load[Units='kWh/year']/Value``) can be provided, otherwise default assumptions based on the plug load type are used.

Validating & Debugging Errors
-----------------------------

When running HPXML files, errors may occur because:

#. An HPXML file provided is invalid (either relative to the HPXML schema or the EnergyPlus Use Case).
#. An unexpected EnergyPlus simulation error occurred.

If an error occurs, first look in the run.log for details.
If there are no errors in that log file, then the error may be in the EnergyPlus simulation -- see eplusout.err.

Contact us if you can't figure out the cause of an error.

Sample Files
------------

Dozens of sample HPXML files are included in the tests directory.
The sample files help to illustrate how different building components are described in HPXML.

Each sample file generally makes one isolated change relative to the base HPXML (base.xml) building.
For example, the base-dhw-dwhr.xml file adds a ``DrainWaterHeatRecovery`` element to the building.

You may find it useful to search through the files for certain HPXML elements or compare (diff) a sample file to the base.xml file.
