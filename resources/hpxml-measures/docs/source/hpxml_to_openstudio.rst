HPXMLtoOpenStudio Measure
=========================

Introduction
------------

The HPXMLtoOpenStudio measure requires a building description in an `HPXML file <https://hpxml.nrel.gov/>`_ format.
HPXML is an open data standard for collecting and transferring home energy data. 
Using HPXML files reduces the complexity and effort for software developers to leverage the EnergyPlus simulation engine.

Capabilities
************

The following building features/technologies are available for modeling via the HPXMLtoOpenStudio measure:

- Enclosure

  - Attics (Vented, Unvented, Conditioned)
  - Foundations (Slab, Unconditioned Basement, Conditioned Basement, Vented Crawlspace, Unvented Crawlspace, Ambient)
  - Garages
  - Windows & Overhangs
  - Skylights
  - Doors
  
- HVAC

  - Heating Systems (Electric Resistance, Central/Wall/Floor Furnaces, Stoves, Boilers, Portable/Fixed Heaters, Fireplaces)
  - Cooling Systems (Central Air Conditioners, Room Air Conditioners, Evaporative Coolers, Mini Split Air Conditioners)
  - Heat Pumps (Air Source, Mini Split, Ground Source, Dual-Fuel)
  - Setpoints
  - Ducts
  
- Water Heating

  - Water Heaters (Storage, Tankless, Heat Pump, Indirect, Tankless Coil)
  - Solar Hot Water
  - Desuperheater
  - Hot Water Distribution (Standard, Recirculation)
  - Drain Water Heat Recovery
  - Hot Water Fixtures
  
- Ventilation

  - Mechanical Ventilation (Exhaust, Supply, Balanced, ERV, HRV, CFIS)
  - Kitchen/Bathroom Fans
  - Whole House Fan

- Photovoltaics
- Appliances (Clothes Washer/Dryer, Dishwasher, Refrigerators, Freezers, Cooking Range/Oven)
- Dehumidifier
- Lighting
- Ceiling Fans
- Pool
- Hot Tub
- Plug Loads
- Fuel Loads

EnergyPlus Use Case for HPXML
*****************************

HPXML is an flexible and extensible format, where nearly all elements in the schema are optional and custom elements can be included.
Because of this, an EnergyPlus Use Case for HPXML has been developed that specifies the HPXML elements or enumeration choices required to run the measure.

Software developers should use the EnergyPlus Use Case (found at ``HPXMLtoOpenStudio/resources/EPvalidator.rb``, which defines sets of conditional XPath expressions) as well as the HPXML schema (HPXML.xsd) to construct valid HPXML files for EnergyPlus simulations.

The `HPXML Toolbox website <https://hpxml.nrel.gov/>`_ also provides several resources for software developers, including:

#. An interactive schema validator
#. A data dictionary
#. An implementation guide

Input Defaults
**************

An increasing number of elements in the HPXML file are being made optional with "smart" defaults.
Default values, equations, and logic are described throughout this documentation.

Most defaults can also be seen by using the ``debug`` argument/flag when running the workflow on an actual HPXML file.
This will create a new HPXML file (``in.xml`` in the run directory) where additional fields are populated for inspection.

For example, suppose a HPXML file has a window defined as follows:

.. code-block:: XML

  <Window>
    <SystemIdentifier id='Window'/>
    <Area>108.0</Area>
    <Azimuth>0</Azimuth>
    <UFactor>0.33</UFactor>
    <SHGC>0.45</SHGC>
    <AttachedToWall idref='Wall'/>
  </Window>

In the ``in.xml`` file, the window would have additional elements like so:

.. code-block:: XML

  <Window>
    <SystemIdentifier id='Window'/>
    <Area>108.0</Area>
    <Azimuth>0</Azimuth>
    <UFactor>0.33</UFactor>
    <SHGC>0.45</SHGC>
    <InteriorShading>
      <SystemIdentifier id='WindowInteriorShading'/>
      <SummerShadingCoefficient>0.7</SummerShadingCoefficient>
      <WinterShadingCoefficient>0.85</WinterShadingCoefficient>
    </InteriorShading>
    <FractionOperable>0.67</FractionOperable>
    <AttachedToWall idref='Wall'/>
  </Window>

.. warning::

  The OpenStudio-HPXML workflow generally treats missing HPXML elements differently than elements provided but without additional detail.
  For example, if an HPXML file has no ``Refrigerator`` element defined, it will be interpreted as a building that has no refrigerator and modeled this way.
  On the other hand, if there is a ``Refrigerator`` element defined but no elements within, it is interpreted as a building that has a refrigerator, but no information about the refrigerator is known.
  In this case, its details (e.g., location, energy use) will be defaulted in the model.

HPXML Software Info
-------------------

EnergyPlus simulation controls can be entered in ``/HPXML/SoftwareInfo/extension/SimulationControl``.

The simulation timestep can be optionally provided as ``Timestep``, where the value is in minutes and must be a divisor of 60.
If not provided, the default value of 60 (i.e., 1 hour) is used.

The simulation run period can be optionally specified with ``BeginMonth``/``BeginDayOfMonth`` and/or ``EndMonth``/``EndDayOfMonth``.
The ``BeginMonth``/``BeginDayOfMonth`` provided must occur before ``EndMonth``/``EndDayOfMonth`` provided (e.g., a run period from 10/1 to 3/31 is invalid).
If not provided, default values of January 1st and December 31st will be used.

Whether to apply daylight saving time can be optionally denoted with ``DaylightSaving/Enabled``.
If either ``DaylightSaving`` or ``DaylightSaving/Enabled`` is not provided, ``DaylightSaving/Enabled`` will default to true.
If daylight saving is enabled, the daylight saving period can be optionally specified with ``DaylightSaving/BeginMonth``, ``DaylightSaving/BeginDayOfMonth``, ``DaylightSaving/EndMonth``, and ``DaylightSaving/EndDayOfMonth``.
If not specified, dates will be defined according to the EPW weather file header; if not available there, default values of March 12 and November 5 will be used.

HPXML Building Details
----------------------

The building description is entered in HPXML's ``/HPXML/Building/BuildingDetails``.

HPXML Building Summary
----------------------

This section describes elements specified in HPXML's ``BuildingSummary``. 
It is used for high-level building information including conditioned floor area, number of bedrooms, number of residents, number of conditioned floors, presence of flue or chimney, etc.
Most occupancy assumptions are based on the number of bedrooms, while the number of residents is solely used to determine heat gains from the occupants themselves.
Note that a walkout basement should be included in ``NumberofConditionedFloorsAboveGrade``.

If ``NumberofBathrooms`` is not provided, it is calculated using the following equation based on the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

.. math:: NumberofBathrooms = \frac{NumberofBedrooms}{2} + 0.5

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

The terrain surrounding the building can be entered as ``Site/SiteType``; if not provided, it is assumed to be suburban.

Whether there is a flue or chimney (associated with the heating system or water heater) can be optionally specified with ``extension/HasFlueOrChimney``.
If not provided, it is assumed that there is a flue or chimney if any of the following conditions are met:

- heating system type is non-electric ``Furnace``, ``Boiler``, ``WallFurnace``, ``FloorFurnace``, ``Stove``, or ``FixedHeater`` and AFUE/Percent is less than 89%
- heating system type is non-electric ``Fireplace`` 
- water heater is non-electric with energy factor (or equivalent uniform energy factor) less than 0.63

HPXML Weather Station
---------------------

The ``ClimateandRiskZones/WeatherStation`` element specifies the EnergyPlus weather file (EPW) to be used in the simulation.
The weather file can be entered in one of two ways:

#. Using ``WeatherStation/WMO``, which must be one of the acceptable TMY3 WMO station numbers found in the ``weather/data.csv`` file.
   The full set of U.S. TMY3 weather files can be `downloaded here <https://data.nrel.gov/system/files/128/tmy3s-cache-csv.zip>`_.
#. Using ``WeatherStation/extension/EPWFilePath``.

HPXML Enclosure
---------------

This section describes elements specified in HPXML's ``Enclosure``.

All surfaces that bound different space types in the building (i.e., not just thermal boundary surfaces) must be specified in the HPXML file.
For example, an attached garage would generally be defined by walls adjacent to conditioned space, walls adjacent to outdoors, a slab, and a roof or ceiling.
For software tools that do not collect sufficient inputs for every required surface, the software developers will need to make assumptions about these surfaces or collect additional input.

The space types used in the HPXML building description are:

==============================  =============================================  ========================================================  =========================
Space Type                      Description                                    Temperature                                               Building Type
==============================  =============================================  ========================================================  =========================
living space                    Above-grade conditioned floor area             EnergyPlus calculation                                    Any
attic - vented                                                                 EnergyPlus calculation                                    Any
attic - unvented                                                               EnergyPlus calculation                                    Any
basement - conditioned          Below-grade conditioned floor area             EnergyPlus calculation                                    Any
basement - unconditioned                                                       EnergyPlus calculation                                    Any
crawlspace - vented                                                            EnergyPlus calculation                                    Any
crawlspace - unvented                                                          EnergyPlus calculation                                    Any
garage                                                                         EnergyPlus calculation                                    Any
other housing unit              E.g., adjacent unit or conditioned corridor    Same as conditioned space                                 Attached/Multifamily only
other heated space              E.g., shared laundry/equipment space           Average of conditioned space and outside; minimum of 68F  Attached/Multifamily only
other multifamily buffer space  E.g., enclosed unconditioned stairwell         Average of conditioned space and outside; minimum of 50F  Attached/Multifamily only
other non-freezing space        E.g., parking garage ceiling                   Floats with outside; minimum of 40F                       Attached/Multifamily only
==============================  =============================================  ========================================================  =========================

.. warning::

  It is the software tool's responsibility to provide the appropriate building surfaces. 
  While some error-checking is in place, it is not possible to know whether some surfaces are incorrectly missing.

Also note that wall and roof surfaces do not require an azimuth to be specified. 
Rather, only the windows/skylights themselves require an azimuth. 
Thus, software tools can choose to use a single wall (or roof) surface to represent multiple wall (or roof) surfaces for the entire building if all their other properties (construction type, interior/exterior adjacency, etc.) are identical.

HPXML Air Infiltration
**********************

Building air leakage is entered using ``Enclosure/AirInfiltration/AirInfiltrationMeasurement``.
Air leakage can be provided in one of three ways:

#. nACH (natural air changes per hour): Use ``BuildingAirLeakage/UnitofMeasure='ACHnatural'``
#. ACH50 (air changes per hour at 50Pa): Use ``BuildingAirLeakage/UnitofMeasure='ACH'`` and ``HousePressure='50'``
#. CFM50 (cubic feet per minute at 50Pa): Use ``BuildingAirLeakage/UnitofMeasure='CFM'`` and ``HousePressure='50'``

In addition, the building's volume associated with the air leakage measurement can be provided in HPXML's ``AirInfiltrationMeasurement/InfiltrationVolume``.
If not provided, the infiltration volume is assumed to be equal to the conditioned building volume.

HPXML Attics/Foundations
*************************

The ventilation rate for vented attics (or vented crawlspaces) can be specified using an ``Attic`` (or ``Foundation``) element.
First, define the ``AtticType`` as ``Attic[Vented='true']`` (or ``FoundationType`` as ``Crawlspace[Vented='true']``).
Then specify the specific leakage area (SLA) using the ``VentilationRate[UnitofMeasure='SLA']/Value`` element.
For vented attics, the natural air changes per hour (nACH) can instead be specified using ``UnitofMeasure='ACHnatural'``.
If the ventilation rate is not provided, default values of SLA=1/300 for vented attics and SLA=1/150 for vented crawlspaces will be used based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

HPXML Roofs
***********

Pitched or flat roof surfaces that are exposed to ambient conditions should be specified as an ``Enclosure/Roofs/Roof``. 
For a multifamily building where the dwelling unit has another dwelling unit above it, the surface between the two dwelling units should be considered a ``FrameFloor`` and not a ``Roof``.

Roofs are defined by their ``Area``, ``Pitch``, ``Insulation/AssemblyEffectiveRValue``, ``SolarAbsorptance``, and ``Emittance``.

Roofs must have either ``RoofColor`` and/or ``SolarAbsorptance`` defined.
If ``RoofColor`` or ``SolarAbsorptance`` is not provided, it is defaulted based on the mapping below:

=========== ======================================================= ================
RoofColor   RoofMaterial                                            SolarAbsorptance
=========== ======================================================= ================
dark        asphalt or fiberglass shingles, wood shingles or shakes 0.92
medium dark asphalt or fiberglass shingles, wood shingles or shakes 0.89
medium      asphalt or fiberglass shingles, wood shingles or shakes 0.85
light       asphalt or fiberglass shingles, wood shingles or shakes 0.75
reflective  asphalt or fiberglass shingles, wood shingles or shakes 0.50
dark        slate or tile shingles, metal surfacing                 0.90
medium dark slate or tile shingles, metal surfacing                 0.83
medium      slate or tile shingles, metal surfacing                 0.75
light       slate or tile shingles, metal surfacing                 0.60
reflective  slate or tile shingles, metal surfacing                 0.30
=========== ======================================================= ================

Roofs can also have optional elements provided for ``RadiantBarrier and ``RoofType``.
If ``RadiantBarrier`` is not provided, it is defaulted to not present; if it is provided, ``RadiantBarrierGrade`` must also be provided.
If ``RoofType`` is not provided, it is defaulted to "asphalt or fiberglass shingles".

HPXML Rim Joists
****************

Rim joists, the perimeter of floor joists typically found between stories of a building or on top of a foundation wall, are specified as an ``Enclosure/RimJoists/RimJoist``.
The ``InteriorAdjacentTo`` element should typically be "living space" for rim joists between stories of a building and "basement - conditioned", "basement - unconditioned", "crawlspace - vented", or "crawlspace - unvented" for rim joists on top of a foundation wall.

Rim joists are defined by their ``Area`` and ``Insulation/AssemblyEffectiveRValue``.

Rim joists must have either ``Color`` and/or ``SolarAbsorptance`` defined.
If ``Color`` or ``SolarAbsorptance`` is not provided, it is defaulted based on the mapping below:

=========== ================
Color       SolarAbsorptance
=========== ================
dark        0.95
medium dark 0.85
medium      0.70
light       0.50
reflective  0.30
=========== ================

Rim joists can have an optional element provided for ``Siding``; if not provided, it defaults to "wood siding".

HPXML Walls
***********

Any wall that has no contact with the ground and bounds a space type should be specified as an ``Enclosure/Walls/Wall``. 
Interior walls (for example, walls solely within the conditioned space of the building) are not required.

Walls are defined by their ``Area`` and ``Insulation/AssemblyEffectiveRValue``.
The choice of ``WallType`` has a secondary effect on heat transfer in that it informs the assumption of wall thermal mass.

Walls must have either ``Color`` and/or ``SolarAbsorptance`` defined.
If ``Color`` or ``SolarAbsorptance`` is not provided, it is defaulted based on the mapping below:

=========== ================
Color       SolarAbsorptance
=========== ================
dark        0.95
medium dark 0.85
medium      0.70
light       0.50
reflective  0.30
=========== ================

Walls can have an optional element provided for ``Siding``; if not provided, it defaults to "wood siding".

HPXML Foundation Walls
**********************

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

HPXML Frame Floors
******************

Any horizontal floor/ceiling surface that is not in contact with the ground (Slab) nor adjacent to ambient conditions above (Roof) should be specified as an ``Enclosure/FrameFloors/FrameFloor``.
Frame floors in an attached/multifamily building that are adjacent to "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space" must have the ``extension/OtherSpaceAboveOrBelow`` property set to signify whether the other space is "above" or "below".

Frame floors are primarily defined by their ``Insulation/AssemblyEffectiveRValue``.

HPXML Slabs
***********

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

HPXML Windows
*************

Any window or glass door area should be specified as an ``Enclosure/Windows/Window``.

Windows are defined by *full-assembly* NFRC ``UFactor`` and ``SHGC``, as well as ``Area``.
Windows must reference a HPXML ``Enclosures/Walls/Wall`` element via the ``AttachedToWall``.
Windows must also have an ``Azimuth`` specified, even if the attached wall does not.

In addition, the summer/winter interior shading coefficients can be optionally entered as ``InteriorShading/SummerShadingCoefficient`` and ``InteriorShading/WinterShadingCoefficient``.
The summer interior shading coefficient must be less than or equal to the winter interior shading coefficient.
Note that a value of 0.7 indicates a 30% reduction in solar gains (i.e., 30% shading).
If not provided, default values of 0.70 for summer and 0.85 for winter will be used based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

Overhangs (e.g., a roof eave) can optionally be defined for a window by specifying a ``Window/Overhangs`` element.
Overhangs are defined by the vertical distance between the overhang and the top of the window (``DistanceToTopOfWindow``), and the vertical distance between the overhang and the bottom of the window (``DistanceToBottomOfWindow``).
The difference between these two values equals the height of the window.

Finally, windows can be optionally described with ``FractionOperable``.
The input should solely reflect whether the windows are operable (can be opened), not how they are used by the occupants.
If a ``Window`` represents a single window, the value should be 0 or 1.
If a ``Window`` represents multiple windows (e.g., 4), the value should be between 0 and 1 (e.g., 0, 0.25, 0.5, 0.75, or 1).
If not provided, it is assumed that 67% of the windows are operable.
The total open window area for natural ventilation is thus calculated using A) the fraction of windows that are operable, B) the assumption that 50% of the area of operable windows can be open, and C) the assumption that 20% of that openable area is actually opened by occupants whenever outdoor conditions are favorable for cooling.

HPXML Skylights
***************

Any skylight should be specified as an ``Enclosure/Skylights/Skylight``.

Skylights are defined by *full-assembly* NFRC ``UFactor`` and ``SHGC``, as well as ``Area``.
Skylights must reference a HPXML ``Enclosures/Roofs/Roof`` element via the ``AttachedToRoof``.
Skylights must also have an ``Azimuth`` specified, even if the attached roof does not.

In addition, the summer/winter interior shading coefficients can be optionally entered as ``InteriorShading/SummerShadingCoefficient`` and ``InteriorShading/WinterShadingCoefficient``.
The summer interior shading coefficient must be less than or equal to the winter interior shading coefficient.
Note that a value of 0.7 indicates a 30% reduction in solar gains (i.e., 30% shading).
If not provided, default values of 1.0 for summer and 1.0 for winter will be used.

HPXML Doors
***********

Any opaque doors should be specified as an ``Enclosure/Doors/Door``.

Doors are defined by ``RValue`` and ``Area``.
Doors must reference a HPXML ``Enclosures/Walls/Wall`` element via the ``AttachedToWall``.
Doors must also have an ``Azimuth`` specified, even if the attached wall does not.

HPXML Systems
-------------

This section describes elements specified in HPXML's ``Systems``.

If any HVAC systems are entered that provide heating (or cooling), the sum of all their ``FractionHeatLoadServed`` (or ``FractionCoolLoadServed``) values must be less than or equal to 1.
For example, a room air conditioner might be specified with ``FractionCoolLoadServed`` equal to 0.3 if it serves 30% of the home's conditioned floor area.

If any water heating systems are entered, the sum of all their ``FractionDHWLoadServed`` values must be equal to 1.

HPXML Heating Systems
*********************

Each heating system (other than heat pumps) should be entered as a ``Systems/HVAC/HVACPlant/HeatingSystem``.
Inputs including ``HeatingSystemType``, and ``FractionHeatLoadServed`` must be provided.
``HeatingCapacity`` may be provided; if not, the system will be auto-sized via ACCA Manual J/S.

Depending on the type of heating system specified, additional elements are used:

==================  ===========================  =================  =======================
HeatingSystemType   DistributionSystem           HeatingSystemFuel  AnnualHeatingEfficiency 
==================  ===========================  =================  =======================
ElectricResistance                               electricity        Percent
Furnace             AirDistribution or DSE       <any>              AFUE
WallFurnace                                      <any>              AFUE
FloorFurnace                                     <any>              AFUE
Boiler              HydronicDistribution or DSE  <any>              AFUE
Stove                                            <any>              Percent
PortableHeater                                   <any>              Percent
Fireplace                                        <any>              Percent
==================  ===========================  =================  =======================

If a non-electric heating system is specified, the ``ElectricAuxiliaryEnergy`` element may be provided if available. 

HPXML Cooling Systems
*********************

Each cooling system (other than heat pumps) should be entered as a ``Systems/HVAC/HVACPlant/CoolingSystem``.
Inputs including ``CoolingSystemType`` and ``FractionCoolLoadServed`` must be provided.
For all systems other than evaporative coolers, ``CoolingCapacity`` may be provided; if not, the system will be auto-sized via ACCA Manual J/S.

Depending on the type of cooling system specified, additional elements are used:

=======================  =================================  =================  =======================  ====================
CoolingSystemType        DistributionSystem                 CoolingSystemFuel  AnnualCoolingEfficiency  SensibleHeatFraction
=======================  =================================  =================  =======================  ====================
central air conditioner  AirDistribution or DSE             electricity        SEER                     (optional)
room air conditioner                                        electricity        EER                      (optional)
evaporative cooler       AirDistribution or DSE (optional)  electricity
mini-split               AirDistribution or DSE (optional)  electricity        SEER                     (optional)
=======================  =================================  =================  =======================  ====================

Central air conditioners can also have the ``CompressorType`` specified; if not provided, it is assumed as follows:

- "single stage": SEER <= 15
- "two stage": 15 < SEER <= 21
- "variable speed": SEER > 21

HPXML Heat Pumps
****************

Each heat pump should be entered as a ``Systems/HVAC/HVACPlant/HeatPump``.
Inputs including ``HeatPumpType``, ``FractionHeatLoadServed``, and ``FractionCoolLoadServed`` must be provided.
Note that heat pumps are allowed to provide only heating (``FractionCoolLoadServed`` = 0) or cooling (``FractionHeatLoadServed`` = 0) if appropriate.
``HeatingCapacity`` and ``CoolingCapacity`` may be provided; if not, the system will be auto-sized via ACCA Manual J/S.

Depending on the type of heat pump specified, additional elements are used:

=============  =================================  ============  =======================  =======================  ===========================  ==================
HeatPumpType   DistributionSystem                 HeatPumpFuel  AnnualCoolingEfficiency  AnnualHeatingEfficiency  CoolingSensibleHeatFraction  HeatingCapacity17F
=============  =================================  ============  =======================  =======================  ===========================  ==================
air-to-air     AirDistribution or DSE             electricity   SEER                     HSPF                     (optional)                   (optional)
mini-split     AirDistribution or DSE (optional)  electricity   SEER                     HSPF                     (optional)                   (optional)
ground-to-air  AirDistribution or DSE             electricity   EER                      COP                      (optional)
=============  =================================  ============  =======================  =======================  ===========================  ==================

Air-to-air heat pumps can also have the ``CompressorType`` specified; if not provided, it is assumed as follows:

- "single stage": SEER <= 15
- "two stage": 15 < SEER <= 21
- "variable speed": SEER > 21

If the heat pump has backup heating, it can be specified with ``BackupSystemFuel``, ``BackupAnnualHeatingEfficiency``, and (optionally) ``BackupHeatingCapacity``.
If the heat pump has a switchover temperature (e.g., dual-fuel heat pump) where the heat pump stops operating and the backup heating system starts running, it can be specified with ``BackupHeatingSwitchoverTemperature``.
If the ``BackupHeatingSwitchoverTemperature`` is not provided, the backup heating system will operate as needed when the heat pump has insufficient capacity.

HPXML HVAC Control
******************

A ``Systems/HVAC/HVACControl`` must be provided if any HVAC systems are specified.
The heating setpoint (``SetpointTempHeatingSeason``) and cooling setpoint (``SetpointTempCoolingSeason``) are required elements.

If there is a heating setback, it is defined with:

- ``SetbackTempHeatingSeason``: Temperature during heating setback
- ``extension/SetbackStartHourHeating``: The start hour of the heating setback where 0=midnight and 12=noon
- ``TotalSetbackHoursperWeekHeating``: The number of hours of heating setback per week

If there is a cooling setup, it is defined with:

- ``SetupTempCoolingSeason``: Temperature during cooling setup
- ``extension/SetupStartHourCooling``: The start hour of the cooling setup where 0=midnight and 12=noon
- ``TotalSetupHoursperWeekCooling``: The number of hours of cooling setup per week

Finally, if there are sufficient ceiling fans present that result in a reduced cooling setpoint, this offset can be specified with ``extension/CeilingFanSetpointTempCoolingSeasonOffset``.

HPXML HVAC Distribution
***********************

Each separate HVAC distribution system should be specified as a ``Systems/HVAC/HVACDistribution``.
There should be at most one heating system and one cooling system attached to a distribution system.
See the sections on Heating Systems, Cooling Systems, and Heat Pumps for information on which ``DistributionSystemType`` is allowed for which HVAC system.
Also note that some HVAC systems (e.g., room air conditioners) are not allowed to be attached to a distribution system.

Air Distribution
~~~~~~~~~~~~~~~~

``AirDistribution`` systems are defined by:

- ``ConditionedFloorAreaServed``
- Optional ``NumberofReturnRegisters``. If not provided, one return register per conditioned floor will be assumed.
- Supply leakage to the outside in CFM25 or percent of airflow (``DuctLeakageMeasurement[DuctType='supply']/DuctLeakage/Value``)
- Optional return leakage to the outside in CFM25 or percent of airflow (``DuctLeakageMeasurement[DuctType='return']/DuctLeakage/Value``)
- Optional supply ducts (``Ducts[DuctType='supply']``)
- Optional return ducts (``Ducts[DuctType='return']``)

For each duct, ``DuctInsulationRValue`` must be provided.
``DuctLocation`` and ``DuctSurfaceArea`` can be optionally provided.
The provided ``DuctLocation`` can be one of the following:

==============================  =============================================  =========================================================  =========================  ================
Location                        Description                                    Temperature                                                Building Type              Default Priority
==============================  =============================================  =========================================================  =========================  ================
living space                    Above-grade conditioned floor area             EnergyPlus calculation                                     Any                        8
basement - conditioned          Below-grade conditioned floor area             EnergyPlus calculation                                     Any                        1
basement - unconditioned                                                       EnergyPlus calculation                                     Any                        2
crawlspace - unvented                                                          EnergyPlus calculation                                     Any                        4
crawlspace - vented                                                            EnergyPlus calculation                                     Any                        3
attic - unvented                                                               EnergyPlus calculation                                     Any                        6
attic - vented                                                                 EnergyPlus calculation                                     Any                        5
garage                                                                         EnergyPlus calculation                                     Any                        7
outside                                                                        Outside                                                    Any
exterior wall                                                                  Average of conditioned space and outside                   Any
under slab                                                                     Ground                                                     Any
roof deck                                                                      Outside                                                    Any
other housing unit              E.g., adjacent unit or conditioned corridor    Same as conditioned space                                  Attached/Multifamily only
other heated space              E.g., shared laundry/equipment space           Average of conditioned space and outside; minimum of 68F   Attached/Multifamily only
other multifamily buffer space  E.g., enclosed unconditioned stairwell         Average of conditioned space and outside; minimum of 50F   Attached/Multifamily only
other non-freezing space        E.g., parking garage ceiling                   Floats with outside; minimum of 40F                        Attached/Multifamily only
==============================  =============================================  =========================================================  =========================  ================

If ``DuctLocation`` is not provided, the primary duct location will be chosen based on the presence of spaces and the "Default Priority" indicated above.
For a 2+ story home, secondary ducts will also be located in the living space.

If ``DuctSurfaceArea`` is not provided, the total duct area will be calculated based on ANSI/ASHRAE Standard 152-2004:

========================================  ====================================================================
Element Name                              Default Value
========================================  ====================================================================
DuctSurfaceArea (primary supply ducts)    :math:`0.27 \cdot F_{out} \cdot CFA_{ServedByAirDistribution}`
DuctSurfaceArea (secondary supply ducts)  :math:`0.27 \cdot (1 - F_{out}) \cdot CFA_{ServedByAirDistribution}`
DuctSurfaceArea (primary return ducts)    :math:`b_r \cdot F_{out} \cdot CFA_{ServedByAirDistribution}`
DuctSurfaceArea (secondary return ducts)  :math:`b_r \cdot (1 - F_{out}) \cdot CFA_{ServedByAirDistribution}`
========================================  ====================================================================

where F\ :sub:`out` is 1.0 for 1-story homes and 0.75 for 2+ story homes and b\ :sub:`r` is 0.05 * ``NumberofReturnRegisters`` with a maximum value of 0.25.

Hydronic Distribution
~~~~~~~~~~~~~~~~~~~~~

``HydronicDistribution`` systems do not require any additional inputs.

Distribution System Efficiency
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``DSE`` systems are defined by a ``AnnualHeatingDistributionSystemEfficiency`` and ``AnnualCoolingDistributionSystemEfficiency`` elements.

.. warning::

  Specifying a DSE for the HVAC distribution system is reflected in the SimulationOutputReport reporting measure outputs, but is not reflected in the raw EnergyPlus simulation outputs.

HPXML Mechanical Ventilation
****************************

This section describes elements specified in HPXML's ``Systems/MechanicalVentilation``.
``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` elements can be used to specify whole building ventilation, local ventilation, and/or cooling load reduction.

Whole Building Ventilation
~~~~~~~~~~~~~~~~~~~~~~~~~~

Mechanical ventilation systems that provide whole building ventilation may each be specified as a ``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` with ``UsedForWholeBuildingVentilation='true'``.
Inputs including ``FanType``, ``TestedFlowRate`` (or ``RatedFlowRate``), ``HoursInOperation``, and ``FanPower`` must be provided.
For a CFIS system, the flow rate should equal the amount of outdoor air provided to the distribution system.

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

Note that ``AdjustedSensibleRecoveryEfficiency`` and ``AdjustedTotalRecoveryEfficiency`` can be provided instead of ``SensibleRecoveryEfficiency`` and ``TotalRecoveryEfficiency``.

Local Ventilation
~~~~~~~~~~~~~~~~~

Kitchen range fans that provide local ventilation may each be specified as a ``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` with ``FanLocation='kitchen'`` and ``UsedForLocalVentilation='true'``.

Additional fields may be provided per the table below. If not provided, default values will be assumed based on the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

=========================== ========================
Element Name                Default Value
=========================== ========================
Quantity [#]                1
RatedFlowRate [cfm]         100
HoursInOperation [hrs/day]  1
FanPower [W]                0.3 * RatedFlowRate
extension/StartHour [0-23]  18
=========================== ========================

Bathroom fans that provide local ventilation may each be specified as a ``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` with ``FanLocation='bath'`` and ``UsedForLocalVentilation='true'``.

Additional fields may be provided per the table below. If not provided, default values will be assumed based on the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

=========================== ========================
Element Name                Default Value
=========================== ========================
Quantity [#]                NumberofBathrooms
RatedFlowRate [cfm]         50
HoursInOperation [hrs/day]  1
FanPower [W]                0.3 * RatedFlowRate
extension/StartHour [0-23]  7
=========================== ========================

Cooling Load Reduction
~~~~~~~~~~~~~~~~~~~~~~

Whole house fans that provide cooling load reduction may each be specified as a ``Systems/MechanicalVentilation/VentilationFans/VentilationFan`` with ``UsedForSeasonalCoolingLoadReduction='true'``.
Required elements include ``RatedFlowRate`` and ``FanPower``.

The whole house fan is assumed to operate during hours of favorable outdoor conditions and will take priority over operable windows (natural ventilation).

HPXML Water Heating Systems
***************************

Each water heater should be entered as a ``Systems/WaterHeating/WaterHeatingSystem``.
Inputs including ``WaterHeaterType`` and ``FractionDHWLoadServed`` must be provided.

.. warning::

  ``FractionDHWLoadServed`` represents only the fraction of the hot water load associated with the hot water **fixtures**. Additional hot water load from the clothes washer/dishwasher will be automatically assigned to the appropriate water heater(s).

Depending on the type of water heater specified, additional elements are required/available:

========================================  ===================================  ===========  ==========  ===============  ==================  ===================== =================  =========================================  ==============================
WaterHeaterType                           UniformEnergyFactor or EnergyFactor  FuelType     TankVolume  HeatingCapacity  RecoveryEfficiency  PerformanceAdjustment UsesDesuperheater  WaterHeaterInsulation/Jacket/JacketRValue  RelatedHVACSystem
========================================  ===================================  ===========  ==========  ===============  ==================  ===================== =================  =========================================  ==============================
storage water heater                      required                             <any>        <optional>  <optional>       <optional>                                <optional>         <optional>                                 required if uses desuperheater
instantaneous water heater                required                             <any>                                                         <optional>            <optional>                                                    required if uses desuperheater
heat pump water heater                    required                             electricity  required                                                               <optional>         <optional>                                 required if uses desuperheater
space-heating boiler with storage tank                                                      required                                                                                  <optional>                                 required
space-heating boiler with tankless coil                                                                                                                                                                                          required
========================================  ===================================  ===========  ==========  ===============  ==================  ===================== =================  =========================================  ==============================

For storage water heaters, the tank volume in gallons, heating capacity in Btuh, and recovery efficiency can be optionally provided.
If not provided, default values for the tank volume and heating capacity will be assumed based on Table 8 in the `2014 Building America House Simulation Protocols <https://www.energy.gov/sites/prod/files/2014/03/f13/house_simulation_protocols_2014.pdf#page=22&zoom=100,93,333>`_ 
and a default recovery efficiency shown in the table below will be assumed based on regression analysis of `AHRI certified water heaters <https://www.ahridirectory.org/NewSearch?programId=24&searchTypeId=3>`_.

============  ======================================
EnergyFactor  RecoveryEfficiency (default)
============  ======================================
>= 0.75       0.778114 * EF + 0.276679
< 0.75        0.252117 * EF + 0.607997
============  ======================================

For tankless water heaters, a performance adjustment due to cycling inefficiencies can be provided.
If not provided, a default value of 0.92 (92%) will apply to the Energy Factor.

For combi boiler systems, the ``RelatedHVACSystem`` must point to a ``HeatingSystem`` of type "Boiler".
For combi boiler systems with a storage tank, the storage tank losses (deg-F/hr) can be entered as ``StandbyLoss``; if not provided, a default value based on the `AHRI Directory of Certified Product Performance <https://www.ahridirectory.org>`_ will be calculated.

For water heaters that are connected to a desuperheater, the ``RelatedHVACSystem`` must either point to a ``HeatPump`` or a ``CoolingSystem``.

The water heater ``Location`` can be optionally entered as one of the following:

==============================  =============================================  =========================================================  =========================
Location                        Description                                    Temperature                                                Building Type
==============================  =============================================  =========================================================  =========================
living space                    Above-grade conditioned floor area             EnergyPlus calculation                                     Any
basement - conditioned          Below-grade conditioned floor area             EnergyPlus calculation                                     Any
basement - unconditioned                                                       EnergyPlus calculation                                     Any
attic - unvented                                                               EnergyPlus calculation                                     Any
attic - vented                                                                 EnergyPlus calculation                                     Any
garage                                                                         EnergyPlus calculation                                     Any
crawlspace - unvented                                                          EnergyPlus calculation                                     Any
crawlspace - vented                                                            EnergyPlus calculation                                     Any
other exterior                  Outside                                        EnergyPlus calculation                                     Any
other housing unit              E.g., adjacent unit or conditioned corridor    Same as conditioned space                                  Attached/Multifamily only
other heated space              E.g., shared laundry/equipment space           Average of conditioned space and outside; minimum of 68F   Attached/Multifamily only
other multifamily buffer space  E.g., enclosed unconditioned stairwell         Average of conditioned space and outside; minimum of 50F   Attached/Multifamily only
other non-freezing space        E.g., parking garage ceiling                   Floats with outside; minimum of 40F                        Attached/Multifamily only
==============================  =============================================  =========================================================  =========================

If the location is not provided, a default water heater location will be assumed based on IECC climate zone:

=================  ============================================================================================
IECC Climate Zone  Location (default)
=================  ============================================================================================
1-3, excluding 3A  garage if present, otherwise living space                                                   
3A, 4-8, unknown   conditioned basement if present, otherwise unconditioned basement if present, otherwise living space
=================  ============================================================================================

The setpoint temperature may be provided as ``HotWaterTemperature``; if not provided, 125F is assumed.

The water heater may be optionally described as a shared system (i.e., serving multiple dwelling units or a shared laundry room) using ``IsSharedSystem``.
If not provided, it is assumed to be false.
If provided and true, ``NumberofUnitsServed`` must also be specified, where the value is the number of dwelling units served either indirectly (e.g., via shared laundry room) or directly.

HPXML Hot Water Distribution
****************************

A single ``Systems/WaterHeating/HotWaterDistribution`` must be provided if any water heating systems are specified.
Inputs including ``SystemType`` and ``PipeInsulation/PipeRValue`` must be provided.
Note: Any hot water distribution associated with a shared laundry room in attached/multifamily buildings should not be defined.

Standard
~~~~~~~~

For a ``SystemType/Standard`` (non-recirculating) system within the dwelling unit, the following element are used:

- ``PipingLength``: Optional. Measured length of hot water piping from the hot water heater (or from a shared recirculation loop serving multiple dwelling units) to the farthest hot water fixture, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 10 feet of piping for each floor level, plus 5 feet of piping for unconditioned basements (if any)
  If not provided, a default ``PipingLength`` will be calculated using the following equation from `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

  .. math:: PipeL = 2.0 \cdot (\frac{CFA}{NCfl})^{0.5} + 10.0 \cdot NCfl + 5.0 \cdot bsmnt

  Where, 
  PipeL = piping length [ft], 
  CFA = conditioned floor area [ft²],
  NCfl = number of conditioned floor levels number of conditioned floor levels in the residence including conditioned basements, 
  bsmnt = presence = 1.0 or absence = 0.0 of an unconditioned basement in the residence.

Recirculation
~~~~~~~~~~~~~

For a ``SystemType/Recirculation`` system within the dwelling unit, the following elements are used:

- ``ControlType``: One of "manual demand control", "presence sensor demand control", "temperature", "timer", or "no control".
- ``RecirculationPipingLoopLength``: Optional. If not provided, the default value will be calculated by using the equation shown in the table below. Measured recirculation loop length including both supply and return sides, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 20 feet of piping for each floor level greater than one plus 10 feet of piping for unconditioned basements.
- ``BranchPipingLoopLength``: Optional. If not provided, the default value will be assumed as shown in the table below. Measured length of the branch hot water piping from the recirculation loop to the farthest hot water fixture from the recirculation loop, measured longitudinally from plans, assuming the branch hot water piping does not run diagonally.
- ``PumpPower``: Optional. If not provided, the default value will be assumed as shown in the table below. Pump Power in Watts.

  ==================================  ====================================================================================================
  Element Name                        Default Value
  ==================================  ====================================================================================================
  RecirculationPipingLoopLength [ft]  :math:`2.0 \cdot (2.0 \cdot (\frac{CFA}{NCfl})^{0.5} + 10.0 \cdot NCfl + 5.0 \cdot bsmnt) - 20.0`
  BranchPipingLoopLength [ft]         10 
  Pump Power [W]                      50 
  ==================================  ====================================================================================================

Shared Recirculation
~~~~~~~~~~~~~~~~~~~~

In addition to the hot water distribution systems within the dwelling unit, the pump energy use of a shared recirculation system can also be described using the following elements:

- `extension/SharedRecirculation/NumberofUnitsServed`: Number of dwelling units served by the shared pump.
- `extension/SharedRecirculation/PumpPower`: Optional. If not provided, the default value will be assumed as shown in the table below. Shared pump power in Watts.
- `extension/SharedRecirculation/ControlType`: One of "manual demand control", "presence sensor demand control", "timer", or "no control".

  ==================================  ==========================================
  Element Name                        Default Value
  ==================================  ==========================================
  Pump Power [W]                      220 (0.25 HP pump w/ 85% motor efficiency)
  ==================================  ==========================================

Drain Water Heat Recovery
~~~~~~~~~~~~~~~~~~~~~~~~~

In addition, a ``HotWaterDistribution/DrainWaterHeatRecovery`` (DWHR) may be specified.
The DWHR system is defined by:

- ``FacilitiesConnected``: 'one' if there are multiple showers and only one of them is connected to a DWHR; 'all' if there is one shower and it's connected to a DWHR or there are two or more showers connected to a DWHR
- ``EqualFlow``: 'true' if the DWHR supplies pre-heated water to both the fixture cold water piping and the hot water heater potable supply piping
- ``Efficiency``: As rated and labeled in accordance with CSA 55.1

HPXML Water Fixtures
********************

Water fixtures should be entered as ``Systems/WaterHeating/WaterFixture`` elements.
Each fixture must have ``WaterFixtureType`` and ``LowFlow`` elements provided.
Fixtures should be specified as low flow if they are <= 2.0 gpm.

A ``WaterHeating/extension/WaterFixturesUsageMultiplier`` can also be optionally provided that scales hot water usage; if not provided, it is assumed to be 1.0.

HPXML Solar Thermal
*******************

A solar hot water system can be entered as a ``Systems/SolarThermal/SolarThermalSystem``.
The ``SystemType`` element must be 'hot water'.

Solar hot water systems can be described with either simple or detailed inputs.

Simple Model
~~~~~~~~~~~~

If using simple inputs, the following elements are used:

- ``SolarFraction``: Portion of total conventional hot water heating load (delivered energy and tank standby losses). Can be obtained from Directory of SRCC OG-300 Solar Water Heating System Ratings or NREL's `System Advisor Model <https://sam.nrel.gov/>`_ or equivalent.
- ``ConnectedTo``: Optional. If not specified, applies to all water heaters in the building. If specified, must point to a ``WaterHeatingSystem``.

Detailed Model
~~~~~~~~~~~~~~

If using detailed inputs, the following elements are used:

- ``CollectorArea``: in units of ft²
- ``CollectorLoopType``: 'liquid indirect' or 'liquid direct' or 'passive thermosyphon'
- ``CollectorType``: 'single glazing black' or 'double glazing black' or 'evacuated tube' or 'integrated collector storage'
- ``CollectorAzimuth``
- ``CollectorTilt``
- ``CollectorRatedOpticalEfficiency``: FRTA (y-intercept); see Directory of SRCC OG-100 Certified Solar Collector Ratings
- ``CollectorRatedThermalLosses``: FRUL (slope, in units of Btu/hr-ft²-R); see Directory of SRCC OG-100 Certified Solar Collector Ratings
- ``StorageVolume``: Optional. If not provided, the default value in gallons will be calculated as 1.5 * CollectorArea

- ``ConnectedTo``: Must point to a ``WaterHeatingSystem``. The connected water heater cannot be of type space-heating boiler or attached to a desuperheater.

HPXML Photovoltaics
*******************

Each solar electric (photovoltaic) system should be entered as a ``Systems/Photovoltaics/PVSystem``.
The following elements, some adopted from the `PVWatts model <https://pvwatts.nrel.gov>`_, are required for each PV system:

- ``Location``: 'ground' or 'roof' mounted
- ``ModuleType``: 'standard', 'premium', or 'thin film'
- ``Tracking``: 'fixed' or '1-axis' or '1-axis backtracked' or '2-axis'
- ``ArrayAzimuth``
- ``ArrayTilt``
- ``MaxPowerOutput``

Inputs including ``InverterEfficiency``, ``SystemLossesFraction``, and ``YearModulesManufactured`` can be optionally entered.
If ``InverterEfficiency`` is not provided, the default value of 0.96 is assumed.

``SystemLossesFraction`` includes the effects of soiling, shading, snow, mismatch, wiring, degradation, etc.
If neither ``SystemLossesFraction`` or ``YearModulesManufactured`` are provided, a default value of 0.14 will be used.
If ``SystemLossesFraction`` is not provided but ``YearModulesManufactured`` is provided, ``SystemLossesFraction`` will be calculated using the following equation.

.. math:: System Losses Fraction = 1.0 - (1.0 - 0.14) \cdot (1.0 - (1.0 - 0.995^{(CurrentYear - YearModulesManufactured)}))

HPXML Appliances
----------------

This section describes elements specified in HPXML's ``Appliances``.

The ``Location`` for each appliance can be optionally provided as one of the following:

==============================  ===========================================  =========================
Location                        Description                                  Building Type
==============================  ===========================================  =========================
living space                    Above-grade conditioned floor area           Any
basement - conditioned          Below-grade conditioned floor area           Any
basement - unconditioned                                                     Any
garage                                                                       Any
other housing unit              E.g., adjacent unit or conditioned corridor  Attached/Multifamily only
other heated space              E.g., shared laundry/equipment space         Attached/Multifamily only
other multifamily buffer space  E.g., enclosed unconditioned stairwell       Attached/Multifamily only
other non-freezing space        E.g., parking garage ceiling                 Attached/Multifamily only
==============================  ===========================================  =========================

If the location is not specified, the appliance is assumed to be in the living space.

HPXML Clothes Washer
********************

An ``Appliances/ClothesWasher`` element can be specified; if not provided, a clothes washer will not be modeled.

Several EnergyGuide label inputs describing the efficiency of the appliance can be provided.
If the complete set of efficiency inputs is not provided, the following default values representing a standard clothes washer from 2006 will be used.

=============================================  ==============
Element Name                                   Default Value
=============================================  ==============
IntegratedModifiedEnergyFactor [ft³/kWh-cyc]   1.0  
RatedAnnualkWh [kWh/yr]                        400  
LabelElectricRate [$/kWh]                      0.12  
LabelGasRate [$/therm]                         1.09  
LabelAnnualGasCost [$]                         27.0  
Capacity [ft³]                                 3.0  
LabelUsage [cyc/week]                          6  
=============================================  ==============

If ``ModifiedEnergyFactor`` is provided instead of ``IntegratedModifiedEnergyFactor``, it will be converted using the following equation based on the `Interpretation on ANSI/RESNET 301-2014 Clothes Washer IMEF <https://www.resnet.us/wp-content/uploads/No.-301-2014-08-sECTION-4.2.2.5.2.8-Clothes-Washers-Eq-4.2-6.pdf>`_.

.. math:: IntegratedModifiedEnergyFactor = \frac{ModifiedEnergyFactor - 0.503}{0.95}

An ``extension/UsageMultiplier`` can also be optionally provided that scales energy and hot water usage; if not provided, it is assumed to be 1.0.

The clothes washer may be optionally described as a shared appliance (i.e., in a shared laundry room) using ``IsSharedAppliance``.
If not provided, it is assumed to be false.
If provided and true, ``AttachedToWaterHeatingSystem`` must also be specified and must reference a shared water heater.

HPXML Clothes Dryer
*******************

An ``Appliances/ClothesDryer`` element can be specified; if not provided, a clothes dryer will not be modeled.
The dryer's ``FuelType`` must be provided.

Several EnergyGuide label inputs describing the efficiency of the appliance can be provided.
If the complete set of efficiency inputs is not provided, the following default values representing a standard clothes dryer from 2006 will be used.

==============================  ==============
Element Name                    Default Value
==============================  ==============
CombinedEnergyFactor [lb/kWh]   3.01  
ControlType                     timer
==============================  ==============

If ``EnergyFactor`` is provided instead of ``CombinedEnergyFactor``, it will be converted into ``CombinedEnergyFactor`` using the following equation based on the `Interpretation on ANSI/RESNET/ICC 301-2014 Clothes Dryer CEF <https://www.resnet.us/wp-content/uploads/No.-301-2014-10-Section-4.2.2.5.2.8-Clothes-Dryer-CEF-Rating.pdf>`_.

.. math:: CombinedEnergyFactor = \frac{EnergyFactor}{1.15}

An ``extension/UsageMultiplier`` can also be optionally provided that scales energy usage; if not provided, it is assumed to be 1.0.

HPXML Dishwasher
****************

An ``Appliances/Dishwasher`` element can be specified; if not provided, a dishwasher will not be modeled.

Several EnergyGuide label inputs describing the efficiency of the appliance can be provided.
If the complete set of efficiency inputs is not provided, the following default values representing a standard dishwasher from 2006 will be used.

===============================  =================
Element Name                     Default Value
===============================  =================
RatedAnnualkWh [kwh/yr]          467  
LabelElectricRate [$/kWh]        0.12  
LabelGasRate [$/therm]           1.09  
LabelAnnualGasCost [$]           33.12  
PlaceSettingCapacity [#]         12  
LabelUsage [cyc/week]            4  
===============================  =================

If ``EnergyFactor`` is provided instead of ``RatedAnnualkWh``, it will be converted into ``RatedAnnualkWh`` using the following equation based on `ANSI/RESNET/ICC 301-2014 <https://codes.iccsafe.org/content/document/843>`_.

.. math:: RatedAnnualkWh = \frac{215.0}{EnergyFactor}

An ``extension/UsageMultiplier`` can also be optionally provided that scales energy and hot water usage; if not provided, it is assumed to be 1.0.

The dishwasher may be optionally described as a shared appliance (i.e., in a shared laundry room) using ``IsSharedAppliance``.
If not provided, it is assumed to be false.
If provided and true, ``AttachedToWaterHeatingSystem`` must also be specified and must reference a shared water heater.

HPXML Refrigerators
*******************

Multiple ``Appliances/Refrigerator`` elements can be specified; if none are provided, refrigerators will not be modeled.

The efficiency of the refrigerator can be optionally entered as ``RatedAnnualkWh`` or ``extension/AdjustedAnnualkWh``.
If neither are provided, ``RatedAnnualkWh`` will be defaulted to represent a standard refrigerator from 2006 using the following equation based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

.. math:: RatedAnnualkWh = 637.0 + 18.0 \cdot NumberofBedrooms

Optional ``extension/WeekdayScheduleFractions``, ``extension/WeekendScheduleFractions``, and ``extension/MonthlyScheduleMultipliers`` can be provided; if not provided, values from Figures 16 & 24 of the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used.
An ``extension/UsageMultiplier`` can also be optionally provided that scales energy usage; if not provided, it is assumed to be 1.0.

If multiple refrigerators are specified, there must be exactly one refrigerator described with ``PrimaryIndicator='true'``.

The ``Location`` of a primary refrigerator is described in the Appliances section.
If ``Location`` is not provided for a non-primary refrigerator, its location will be chosen based on the presence of spaces and the "Default Priority" indicated below.

========================  ================
Location                  Default Priority
========================  ================
garage                    1
basement - unconditioned  2
basement - conditioned    3
living space              4
========================  ================

HPXML Freezers
**************

Multiple ``Appliances/Freezer`` elements can be provided; if none provided, standalone freezers will not be modeled.

The efficiency of the freezer can be optionally entered as RatedAnnualkWh or extension/AdjustedAnnualkWh. If neither are provided, RatedAnnualkWh will be defaulted to represent a benchmark freezer according to the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ (319.8 kWh/year).

Optional ``extension/WeekdayScheduleFractions``, ``extension/WeekendScheduleFractions``, and ``extension/MonthlyScheduleMultipliers`` can be provided; if not provided, values from Figures 16 & 24 of the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used.
An extension/UsageMultiplier can also be optionally provided that scales energy usage; if not provided, it is assumed to be 1.0.

HPXML Cooking Range/Oven
************************

``Appliances/CookingRange`` and ``Appliances/Oven`` elements can be specified; if not provided, a range/oven will not be modeled.
The ``FuelType`` of the range must be provided.

Inputs including ``CookingRange/IsInduction`` and ``Oven/IsConvection`` can be optionally provided.
The following default values will be assumed unless a complete set of the optional variables is provided.

=============  ==============
Element Name   Default Value
=============  ==============
IsInduction    false
IsConvection   false
=============  ==============

Optional ``CookingRange/extension/WeekdayScheduleFractions``, ``CookingRange/extension/WeekendScheduleFractions``, and ``CookingRange/extension/MonthlyScheduleMultipliers`` can be provided; if not provided, values from Figures 22 & 24 of the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used.
An ``CookingRange/extension/UsageMultiplier`` can also be optionally provided that scales energy usage; if not provided, it is assumed to be 1.0.

HPXML Dehumidifier
******************

An ``Appliance/Dehumidifier`` element can be specified; if not provided, a dehumidifier will not be modeled.
The ``Capacity``, ``DehumidistatSetpoint`` (relative humidity as a fraction, 0-1), and ``FractionDehumidificationLoadServed`` (0-1) must be provided.
The efficiency of the dehumidifier can either be entered as an ``IntegratedEnergyFactor`` or ``EnergyFactor``.

HPXML Lighting
--------------

This section describes elements specified in HPXML's ``Lighting``.

HPXML Lighting Groups
*********************

The building's lighting is described by nine ``LightingGroup`` elements, each of which is the combination of:

- ``LightingType``: 'LightEmittingDiode', 'CompactFluorescent', and 'FluorescentTube'
- ``Location``: 'interior', 'garage', and 'exterior'

The fraction of lamps of the given type in the given location are provided as the ``LightingGroup/FractionofUnitsInLocation``.
The fractions for a given location cannot sum to greater than 1.
If the fractions sum to less than 1, the remainder is assumed to be incandescent lighting.
Garage lighting values are ignored if the building has no garage.

Optional ``extension/InteriorUsageMultiplier``, ``extension/ExteriorUsageMultiplier``, and ``extension/GarageUsageMultiplier`` can be provided that scales energy usage; if not provided, they are assumed to be 1.0.

An optional ``extension/ExteriorHolidayLighting`` can also be provided to define additional exterior holiday lighting; if not provided, none will be modeled. 
If provided, child elements ``Load[Units='kWh/day']/Value``, ``PeriodBeginMonth``/``PeriodBeginDayOfMonth``, ``PeriodEndMonth``/``PeriodEndDayOfMonth``, ``WeekdayScheduleFractions``, and ``WeekendScheduleFractions`` can be optionally provided. 
For the child elements not provided, the following default values will be used.

=============================================  ======================================================================================================
Element Name                                   Default Value
=============================================  ======================================================================================================
Load[Units='kWh/day']/Value                    1.1 for single-family detached and 0.55 for others
PeriodBeginMonth/PeriodBeginDayOfMonth         11/24 (November 24) 
PeriodEndMonth/PeriodEndDayOfMonth             1/6 (January 6) 
WeekdayScheduleFractions                       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.008, 0.098, 0.168, 0.194, 0.284, 0.192, 0.037, 0.019
WeekendScheduleFractions                       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.008, 0.098, 0.168, 0.194, 0.284, 0.192, 0.037, 0.019
=============================================  ======================================================================================================

Finally, optional schedules can be defined:

- **Interior**: Optional ``extension/InteriorWeekdayScheduleFractions``, ``extension/InteriorWeekendScheduleFractions``, and ``extension/InteriorMonthlyScheduleMultipliers`` can be provided; if not provided, values will be calculated using Lighting Calculation Option 2 (location-dependent lighting profile) of the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
- **Garage**: Optional ``extension/GarageWeekdayScheduleFractions``, ``extension/GarageWeekendScheduleFractions``, and ``extension/GarageMonthlyScheduleMultipliers`` can be provided; if not provided, values from Appendix C Table 8 of the `Title 24 2016 Residential Alternative Calculation Method Reference Manual <https://ww2.energy.ca.gov/2015publications/CEC-400-2015-024/CEC-400-2015-024-CMF-REV2.pdf>`_ are used.
- **Exterior**: Optional ``extension/ExteriorWeekdayScheduleFractions``, ``extension/ExteriorWeekendScheduleFractions``, and ``extension/ExteriorMonthlyScheduleMultipliers`` can be provided; if not provided, values from Appendix C Table 8 of the `Title 24 2016 Residential Alternative Calculation Method Reference Manual <https://ww2.energy.ca.gov/2015publications/CEC-400-2015-024/CEC-400-2015-024-CMF-REV2.pdf>`_ are used.


HPXML Ceiling Fans
******************

Each ceiling fan (or set of identical ceiling fans) should be entered as a ``CeilingFan``.
The ``Airflow/Efficiency`` (at medium speed) and ``Quantity`` can be provided, otherwise the following default assumptions are used from `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

==========================  ==================
Element Name                Default Value
==========================  ==================
Airflow/Efficiency [cfm/W]  3000/42.6
Quantity [#]                NumberofBedrooms+1
==========================  ==================

In addition, a reduced cooling setpoint can be specified for summer months when ceiling fans are operating.
See the Thermostat section for more information.

HPXML Pool
----------

A ``Pools/Pool`` element can be specified; if not provided, a pool will not be modeled.

A ``PoolPumps/PoolPump`` element is required.
The annual energy consumption of the pool pump (``Load[Units='kWh/year']/Value``) can be provided, otherwise they will be calculated using the following equation based on the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

.. math:: PoolPumpkWhs = 158.5 / 0.070 \cdot (0.5 + 0.25 \cdot NumberofBedrooms / 3 + 0.35 \cdot ConditionedFloorArea / 1920)

A ``Heater`` element can be specified; if not provided, a pool heater will not be modeled.
Currently only pool heaters specified with ``Heater[Type='gas fired' or Type='electric resistance' or Type='heat pump']`` are recognized.
The annual energy consumption (``Load[Units='kWh/year' or Units='therm/year']/Value``) can be provided, otherwise they will be calculated using the following equations from the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

.. math:: GasFiredTherms = 3.0 / 0.014 \cdot (0.5 + 0.25 \cdot NumberofBedrooms / 3 + 0.35 \cdot ConditionedFloorArea / 1920)
.. math:: ElectricResistancekWhs = 8.3 / 0.004 \cdot (0.5 + 0.25 \cdot NumberofBedrooms / 3 + 0.35 \cdot ConditionedFloorArea / 1920)
.. math:: HeatPumpkWhs = ElectricResistancekWhs / 5.0

A ``PoolPump/extension/UsageMultiplier`` can also be optionally provided that scales pool pump energy usage; if not provided, it is assumed to be 1.0.
A ``Heater/extension/UsageMultiplier`` can also be optionally provided that scales pool heater energy usage; if not provided, it is assumed to be 1.0.
Optional ``extension/WeekdayScheduleFractions``, ``extension/WeekendScheduleFractions``, and ``extension/MonthlyScheduleMultipliers`` can be provided for ``HotTubPump`` and ``Heater``; if not provided, values from Figures 23 & 24 of the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used.

HPXML Hot Tub
-------------

A ``HotTubs/HotTub`` element can be specified; if not provided, a hot tub will not be modeled.

A ``HotTubPumps/HotTubPump`` element is required.
The annual energy consumption of the hot tub pump (``Load[Units='kWh/year']/Value``) can be provided, otherwise they will be calculated using the following equation based on the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

.. math:: HotTubPumpkWhs = 59.5 / 0.059 \cdot (0.5 + 0.25 \cdot NumberofBedrooms / 3 + 0.35 \cdot ConditionedFloorArea / 1920)

A ``Heater`` element can be specified; if not provided, a hot tub heater will not be modeled.
Currently only hot tub heaters specified with ``Heater[Type='gas fired' or Type='electric resistance' or Type='heat pump']`` are recognized.
The annual energy consumption (``Load[Units='kWh/year' or Units='therm/year']/Value``) can be provided, otherwise they will be calculated using the following equations from the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

.. math:: GasFiredTherms = 0.87 / 0.011 \cdot (0.5 + 0.25 \cdot NumberofBedrooms / 3 + 0.35 \cdot ConditionedFloorArea / 1920)
.. math:: ElectricResistancekWhs = 49.0 / 0.048 \cdot (0.5 + 0.25 \cdot NumberofBedrooms / 3 + 0.35 \cdot ConditionedFloorArea / 1920)
.. math:: HeatPumpkWhs = ElectricResistancekWhs / 5.0

A ``HotTubPump/extension/UsageMultiplier`` can also be optionally provided that scales hot tub pump energy usage; if not provided, it is assumed to be 1.0.
A ``Heater/extension/UsageMultiplier`` can also be optionally provided that scales hot tub heater energy usage; if not provided, it is assumed to be 1.0.
Optional ``extension/WeekdayScheduleFractions``, ``extension/WeekendScheduleFractions``, and ``extension/MonthlyScheduleMultipliers`` can be provided for ``PoolPump`` and ``Heater``; if not provided, values from Figures 23 & 24 of the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used.

HPXML Misc Loads
----------------

This section describes elements specified in HPXML's ``MiscLoads``.

HPXML Plug Loads
****************

Misc electric plug loads can be provided by entering ``PlugLoad`` elements; if not provided, plug loads will not be modeled.
Currently only plug loads specified with ``PlugLoadType='other'``, ``PlugLoadType='TV other'``, ``PlugLoadType='electric vehicle charging'``, or ``PlugLoadType='well pump'`` are recognized.
It is generally recommended to at least include the 'other' (miscellaneous) and 'TV other' plug load types for the typical home.

The annual energy consumption (``Load[Units='kWh/year']/Value``), ``Location``, ``extension/FracSensible``, and ``extension/FracLatent`` elements are optional.
If not provided, they will be defaulted as follows.
Annual energy consumption equations are based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_ or the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

==========================  =============================================  ========  ============  ==========
Plug Load Type              kWh/year                                       Location  FracSensible  FracLatent
==========================  =============================================  ========  ============  ==========
other                       0.91*CFA                                       interior  0.855         0.045
TV other                    413.0 + 69.0*NBr                               interior  1.0           0.0
electric vehicle charging   1666.67                                        exterior  0.0           0.0
well pump                   50.8/0.127*(0.5 + 0.25*NBr/3 + 0.35*CFA/1920)  exterior  0.0           0.0
==========================  =============================================  ========  ============  ==========

where CFA is the conditioned floor area and NBr is the number of bedrooms.

The electric vehicle charging default kWh/year is calculated using:

.. math:: VehiclekWhs = AnnualMiles * kWhPerMile / (EVChargerEfficiency * EVBatteryEfficiency)

where AnnualMiles=4500, kWhPerMile=0.3, EVChargerEfficiency=0.9, and EVBatteryEfficiency=0.9.

An ``extension/UsageMultiplier`` can also be optionally provided that scales energy usage; if not provided, it is assumed to be 1.0.
Optional ``extension/WeekdayScheduleFractions``, ``extension/WeekendScheduleFractions``, and ``extension/MonthlyScheduleMultipliers`` can be provided.
If not provided, values from Figures 23 & 24 of the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used for ``PlugLoadType='other'``, ``PlugLoadType='electric vehicle charging'``, and ``PlugLoadType='well pump'``; values from the `American Time Use Survey <https://www.bls.gov/tus>`_ are used for ``PlugLoadType='TV other'``.

HPXML Fuel Loads
****************

Misc fuel loads can be provided by entering ``FuelLoad`` elements; if not provided, fuel loads will not be modeled.
Currently only fuel loads specified with ``FuelLoadType='grill'``, ``FuelLoadType='lighting'``, or ``FuelLoadType='fireplace'`` are recognized.

The annual energy consumption (``Load[Units='therm/year']/Value``), ``Location``, ``extension/FracSensible``, and ``extension/FracLatent`` elements are also optional.
If not provided, they will be defaulted as follows.
Annual energy consumption equations are based on the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

==========================  =============================================  ========  ============ ==========
Plug Load Type              therm/year                                     Location  FracSensible FracLatent
==========================  =============================================  ========  ============ ==========
grill                       0.87/0.029*(0.5 + 0.25*NBr/3 + 0.35*CFA/1920)  exterior  0.0          0.0
lighting                    0.22/0.012*(0.5 + 0.25*NBr/3 + 0.35*CFA/1920)  exterior  0.0          0.0
fireplace                   1.95/0.032*(0.5 + 0.25*NBr/3 + 0.35*CFA/1920)  interior  0.5          0.1
==========================  =============================================  ========  ============ ==========

where CFA is the conditioned floor area and NBr is the number of bedrooms.

An ``extension/UsageMultiplier`` can also be optionally provided that scales energy usage; if not provided, it is assumed to be 1.0.
Optional ``extension/WeekdayScheduleFractions``, ``extension/WeekendScheduleFractions``, and ``extension/MonthlyScheduleMultipliers`` can be provided; if not provided, values from Figures 23 & 24 of the `Building America House Simulation Protocols <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used.

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

Dozens of sample HPXML files are included in the workflow/sample_files directory.
The sample files help to illustrate how different building components are described in HPXML.

Each sample file generally makes one isolated change relative to the base HPXML (base.xml) building.
For example, the base-dhw-dwhr.xml file adds a ``DrainWaterHeatRecovery`` element to the building.

You may find it useful to search through the files for certain HPXML elements or compare (diff) a sample file to the base.xml file.
