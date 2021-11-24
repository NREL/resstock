.. _workflow_inputs:

Workflow Inputs
===============

OpenStudio-HPXML requires a building description in an `HPXML file <https://hpxml.nrel.gov/>`_ format.
HPXML is an open data standard for collecting and transferring home energy data. 
Using HPXML files reduces the complexity and effort for software developers to leverage the EnergyPlus simulation engine.

Using HPXML
-----------

HPXML is an flexible and extensible format, where nearly all elements in the schema are optional and custom elements can be included.
Because of this, a stricter set of requirements for the HPXML file have been developed for purposes of running EnergyPlus simulations.

HPXML files submitted to OpenStudio-HPXML should undergo a two step validation process:

1. Validation against the HPXML Schema

  The HPXML XSD Schema can be found at ``HPXMLtoOpenStudio/resources/HPXML.xsd``.
  It should be used by the software developer to validate their HPXML file prior to running the simulation.
  XSD Schemas are used to validate what elements/attributes/enumerations are available, data types for elements/attributes, the number/order of children elements, etc.

  OpenStudio-HPXML **does not** validate the HPXML file against the XSD Schema and assumes the file submitted is valid.
  However, OpenStudio-HPXML does automatically check for valid data types (e.g., integer vs string), enumeration choices, and numeric values within min/max.

2. Validation using `Schematron <http://schematron.com/>`_

  The Schematron document for the EnergyPlus use case can be found at ``HPXMLtoOpenStudio/resources/EPvalidator.xml``.
  Schematron is a rule-based validation language, expressed in XML using XPath expressions, for validating the presence or absence of inputs in XML files. 
  As opposed to an XSD Schema, a Schematron document validates constraints and requirements based on conditionals and other logical statements.
  For example, if an element is specified with a particular value, the applicable enumerations of another element may change.
  
  OpenStudio-HPXML **automatically validates** the HPXML file against the Schematron document and reports any validation errors, but software developers may find it beneficial to also integrate Schematron validation into their software.

.. important::

  Usage of both validation approaches (XSD and Schematron) is recommended for developers actively working on creating HPXML files for EnergyPlus simulations:

  - Validation against XSD for general correctness and usage of HPXML
  - Validation against Schematron for understanding XML document requirements specific to running EnergyPlus

Input Defaults
**************

A large number of elements in the HPXML file are optional and can be defaulted.
Default values, equations, and logic are described throughout this documentation.

For example, suppose a HPXML file has a refrigerator defined as follows:

.. code-block:: XML

  <Refrigerator>
    <SystemIdentifier id='Refrigerator1'/>
  </Refrigerator>

Default values would be used for the refrigerator energy use, location, and schedule:

.. code-block:: XML

  <Refrigerator>
    <SystemIdentifier id='Refrigerator1'/>
    <Location dataSource='software'>living space</Location>
    <RatedAnnualkWh dataSource='software'>691.0</RatedAnnualkWh>
    <PrimaryIndicator dataSource='software'>true</PrimaryIndicator>
    <extension>
      <UsageMultiplier dataSource='software'>1.0</UsageMultiplier>
      <WeekdayScheduleFractions dataSource='software'>0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041</WeekdayScheduleFractions>
      <WeekendScheduleFractions dataSource='software'>0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041</WeekendScheduleFractions>
      <MonthlyScheduleMultipliers dataSource='software'>0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837</MonthlyScheduleMultipliers>
    </extension>
  </Refrigerator>

These defaults will be reflected in the EnergyPlus simulation results.

 .. note::

  The OpenStudio-HPXML workflow generally treats missing *elements* differently than missing *values*.
  For example, if there is no ``Refrigerator`` element defined, the model will proceed without refrigerator energy use.
  On the other hand, if there is a ``Refrigerator`` element but with no values defined (i.e., no ``Location`` or ``RatedAnnualkWh``), it is assumed that a refrigerator exists but its properties are unknown, so they will be defaulted in the model.

See :ref:`hpxml_defaults` for information on how default values can be inspected.

HPXML Software Info
-------------------

High-level simulation inputs are entered in ``/HPXML/SoftwareInfo``.

HPXML Simulation Control
************************

EnergyPlus simulation controls are entered in ``/HPXML/SoftwareInfo/extension/SimulationControl``.

  ==================================  ========  =======  =============  ========  ===========================  =====================================
  Element                             Type      Units    Constraints    Required  Default                      Description
  ==================================  ========  =======  =============  ========  ===========================  =====================================
  ``Timestep``                        integer   minutes  Divisor of 60  No        60 (1 hour)                  Timestep
  ``BeginMonth``                      integer            1 - 12 [#]_    No        1 (January)                  Run period start date
  ``BeginDayOfMonth``                 integer            1 - 31         No        1                            Run period start date
  ``EndMonth``                        integer            1 - 12         No        12 (December)                Run period end date
  ``EndDayOfMonth``                   integer            1 - 31         No                                     Run period end date
  ``CalendarYear``                    integer            > 1600         No        2007 (for TMY weather) [#]_  Calendar year (for start day of week)
  ``DaylightSaving/Enabled``          boolean                           No        true                         Daylight savings enabled?
  ==================================  ========  =======  =============  ========  ===========================  =====================================

  .. [#] BeginMonth/BeginDayOfMonth date must occur before EndMonth/EndDayOfMonth date (e.g., a run period from 10/1 to 3/31 is invalid).
  .. [#] CalendarYear only applies to TMY (Typical Meteorological Year) weather. For AMY (Actual Meteorological Year) weather, the AMY year will be used regardless of what is specified.

If daylight saving is enabled, additional information is specified in ``DaylightSaving``.

  ======================================  ========  =====  =================  ========  =============================  ===========
  Element                                 Type      Units  Constraints        Required  Default                        Description
  ======================================  ========  =====  =================  ========  =============================  ===========
  ``BeginMonth`` and ``BeginDayOfMonth``  integer          1 - 12 and 1 - 31  No        EPW else 3/12 (March 12) [#]_  Start date
  ``EndMonth`` and ``EndDayOfMonth``      integer          1 - 12 and 1 - 31  No        EPW else 11/5 (November 5)     End date
  ======================================  ========  =====  =================  ========  =============================  ===========

  .. [#] Daylight savings dates will be defined according to the EPW weather file header; if not available, fallback default values listed above will be used.

HPXML HVAC Sizing Control
*************************

HVAC equipment sizing controls are entered in ``/HPXML/SoftwareInfo/extension/HVACSizingControl``.

  =================================  ========  =====  ===========  ========  =======  ============================================
  Element                            Type      Units  Constraints  Required  Default  Description
  =================================  ========  =====  ===========  ========  =======  ============================================
  ``AllowIncreasedFixedCapacities``  boolean                       No        false    Logic for fixed capacity HVAC equipment [#]_
  ``UseMaxLoadForHeatPumps``         boolean                       No        true     Logic for autosized heat pumps [#]_
  =================================  ========  =====  ===========  ========  =======  ============================================

  .. [#] If AllowIncreasedFixedCapacities is true, the larger of user-specified fixed capacity and design load will be used (to reduce potential for unmet loads); otherwise user-specified fixed capacity is used.
  .. [#] If UseMaxLoadForHeatPumps is true, autosized heat pumps are sized based on the maximum of heating/cooling design loads; otherwise sized per ACCA Manual J/S based on cooling design loads with some oversizing allowances for heating design loads.

HPXML Schedules
***************

Schedules for a variety of building features can be 1) specified via simple inputs, 2) specified via detailed inputs, or 3) defaulted.

Simple Schedule Inputs
~~~~~~~~~~~~~~~~~~~~~~

Simple schedule inputs are available as weekday/weekend fractions and monthly multipliers.
For example, see the ``WeekdayScheduleFractions``, ``WeekendScheduleFractions``, and ``MonthlyScheduleMultipliers`` inputs for :ref:`buildingoccupancy`.

.. _detailedschedules:

Detailed Schedule Inputs
~~~~~~~~~~~~~~~~~~~~~~~~

Detailed schedule inputs allow schedule values for every hour or timestep of the simulation.
They can be smooth schedules, or they can reflect real-world or stochastic occupancy.
Note that if detailed schedule inputs are used, they must be used for *all* building features; you cannot use detailed schedules for some features and simple/default schedules for other features.

Detailed schedule inputs are provided via a CSV file that should be referenced in the HPXML file at ``/HPXML/SoftwareInfo/extension/SchedulesFilePath``.
Each column must be normalized to MAX=1; that is, the schedules only define *when* energy is used, not *how much* energy is used.
The columns in the schedule CSV are:

  =============================  ========  ========================================================  ===================
  Column Name                    Required  Description                                               Affected by Vacancy
  =============================  ========  ========================================================  ===================
  ``occupants``                  Yes       Occupant heat gain schedule.                              Yes
  ``lighting_interior``          Yes       Interior lighting energy use schedule.                    Yes
  ``lighting_exterior``          Yes       Exterior lighting energy use schedule.                    Yes
  ``lighting_garage``            Yes       Garage lighting energy use schedule.                      Yes
  ``lighting_exterior_holiday``  Yes       Exterior holiday lighting energy use schedule.            Yes
  ``cooking_range``              Yes       Cooking range & oven energy use schedule.                 Yes
  ``refrigerator``               Yes       Primary refrigerator energy use schedule.                 No
  ``extra_refrigerator``         Yes       Non-primary refrigerator energy use schedule.             No
  ``freezer``                    Yes       Freezer energy use schedule.                              No
  ``dishwasher``                 Yes       Dishwasher energy use schedule.                           Yes
  ``clothes_washer``             Yes       Clothes washer energy use schedule.                       Yes
  ``clothes_dryer``              Yes       Clothes dryer energy use schedule.                        Yes
  ``ceiling_fan``                Yes       Ceiling fan energy use schedule.                          Yes
  ``plug_loads_other``           Yes       Other plug load energy use schedule.                      Yes
  ``plug_loads_tv``              Yes       Television plug load energy use schedule.                 Yes
  ``plug_loads_vehicle``         Yes       Electric vehicle plug load energy use schedule.           Yes
  ``plug_loads_well_pump``       Yes       Well pump plug load energy use schedule.                  Yes
  ``fuel_loads_grill``           Yes       Grill fuel load energy use schedule.                      Yes
  ``fuel_loads_lighting``        Yes       Lighting fuel load energy use schedule.                   Yes
  ``fuel_loads_fireplace``       Yes       Fireplace fuel load energy use schedule.                  Yes
  ``pool_pump``                  Yes       Pool pump energy use schedule.                            No
  ``pool_heater``                Yes       Pool heater energy use schedule.                          No
  ``hot_tub_pump``               Yes       Hot tub pump energy use schedule.                         No
  ``hot_tub_heater``             Yes       Hot tub heater energy use schedule.                       No
  ``hot_water_dishwasher``       Yes       Dishwasher hot water use schedule.                        Yes
  ``hot_water_clothes_washer``   Yes       Clothes washer hot water use schedule.                    Yes
  ``hot_water_fixtures``         Yes       Fixtures (sinks, showers, baths) hot water use schedule.  Yes
  ``vacancy``                    No        1=Home is vacant. Automatically overrides other columns.  N/A
  =============================  ========  ========================================================  ===================

A couple schedule CSV file examples are provided in the ``HPXMLtoOpenStudio/resources/schedule_files`` directory.

A detailed stochastic or smooth schedule CSV file can also be automatically generated for you; see the :ref:`usage_instructions` for the commands.

Default Schedules
~~~~~~~~~~~~~~~~~

If neither simple nor detailed inputs are provided, then schedules are defaulted.
Default schedules are typically smooth, averaged schedules.
These default schedules are described elsewhere in the documentation (e.g., see :ref:`buildingoccupancy`).

HPXML Building Summary
----------------------

High-level building summary information is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary``. 

HPXML Site
**********

Building site information is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/Site``.

  ================================  ========  =====  ===========  ========  ========  ============================================================
  Element                           Type      Units  Constraints  Required  Default   Notes
  ================================  ========  =====  ===========  ========  ========  ============================================================
  ``SiteType``                      string           See [#]_     No        suburban  Terrain type for infiltration model
  ``ShieldingofHome``               string           See [#]_     No        normal    Presence of nearby buildings, trees, obstructions for infiltration model
  ``extension/Neighbors``           element          >= 0         No        <none>    Presence of neighboring buildings for solar shading
  ================================  ========  =====  ===========  ========  ========  ============================================================

  .. [#] SiteType choices are "rural", "suburban", or "urban".
  .. [#] ShieldingofHome choices are "normal", "exposed", or "well-shielded".

For each neighboring building defined, additional information is entered in a ``extension/Neighbors/NeighborBuilding``.

  ==============================  =================  ================  ===================  ========  ========  =============================================
  Element                         Type               Units             Constraints          Required  Default   Notes
  ==============================  =================  ================  ===================  ========  ========  =============================================
  ``Azimuth`` or ``Orientation``  integer or string  deg or direction  0 - 359 or See [#]_  Yes                 Direction of neighbors (clockwise from North)
  ``Distance``                    double             ft                > 0                  Yes                 Distance of neighbor from the dwelling unit
  ``Height``                      double             ft                > 0                  No        See [#]_  Height of neighbor
  ==============================  =================  ================  ===================  ========  ========  =============================================
  
  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] If Height not provided, assumed to be same height as the dwelling unit.

.. _buildingoccupancy:

HPXML Building Occupancy
************************

Building occupancy is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy``.

  ========================================  ========  =====  ===========  ========  ====================  ========================
  Element                                   Type      Units  Constraints  Required  Default               Notes
  ========================================  ========  =====  ===========  ========  ====================  ========================
  ``NumberofResidents``                     integer          >= 0         No        <number of bedrooms>  Number of occupants
  ``extension/WeekdayScheduleFractions``    array                         No        See [#]_              24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``    array                         No                              24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``  array                         No        See [#]_              12 comma-separated monthly multipliers
  ========================================  ========  =====  ===========  ========  ====================  ========================

  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figures 25 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.053, 0.025, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.018, 0.033, 0.054, 0.054, 0.054, 0.061, 0.061, 0.061".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values are used: "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0".

.. note::

  The above inputs are only used to define heat gain from occupants.
  Usages of plug loads, appliances, hot water, etc. are driven by number of bedrooms, not number of occupants.

HPXML Building Construction
***************************

Building construction is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction``.

  =========================================================  ========  =========  =================================  ========  ========  =======================================================================
  Element                                                    Type      Units      Constraints                        Required  Default   Notes
  =========================================================  ========  =========  =================================  ========  ========  =======================================================================
  ``ResidentialFacilityType``                                string               See [#]_                           Yes                 Type of dwelling unit
  ``NumberofConditionedFloors``                              double               > 0                                Yes                 Number of conditioned floors (including a conditioned basement; excluding a conditioned crawlspace)
  ``NumberofConditionedFloorsAboveGrade``                    double               > 0, <= NumberofConditionedFloors  Yes                 Number of conditioned floors above grade (including a walkout basement)
  ``NumberofBedrooms``                                       integer              > 0                                Yes                 Number of bedrooms
  ``NumberofBathrooms``                                      integer              > 0                                No        See [#]_  Number of bathrooms
  ``ConditionedFloorArea``                                   double    ft2        > 0                                Yes                 Floor area within conditioned space boundary (excluding conditioned crawlspace floor area)
  ``ConditionedBuildingVolume`` or ``AverageCeilingHeight``  double    ft3 or ft  > 0                                No        See [#]_  Volume/ceiling height within conditioned space boundary (including a conditioned basement/crawlspace)
  ``extension/HasFlueOrChimney``                             boolean                                                 No        See [#]_  Presence of flue or chimney for infiltration model
  =========================================================  ========  =========  =================================  ========  ========  =======================================================================

  .. [#] ResidentialFacilityType choices are "single-family detached", "single-family attached", "apartment unit", or "manufactured home".
  .. [#] If NumberofBathrooms not provided, calculated as NumberofBedrooms/2 + 0.5 based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If neither ConditionedBuildingVolume nor AverageCeilingHeight provided, AverageCeilingHeight defaults to the lesser of 8.0 and InfiltrationVolume / ConditionedFloorArea.
         If needed, additional defaulting is performed using the following relationship: ConditionedBuildingVolume = ConditionedFloorArea * AverageCeilingHeight + ConditionedCrawlspaceVolume.
  .. [#] If HasFlueOrChimney not provided, assumed to be true if any of the following conditions are met: 
         
         - heating system is non-electric Furnace, Boiler, WallFurnace, FloorFurnace, Stove, PortableHeater, or FixedHeater and AFUE/Percent is less than 0.89,
         - heating system is non-electric Fireplace, or
         - water heater is non-electric with energy factor (or equivalent calculated from uniform energy factor) less than 0.63.

HPXML Weather Station
---------------------

Weather information is entered in ``/HPXML/Building/BuildingDetails/ClimateandRiskZones/WeatherStation``.

  =========================  ======  =======  ===========  ========  =======  ==============================================
  Element                    Type    Units    Constraints  Required  Default  Notes
  =========================  ======  =======  ===========  ========  =======  ==============================================
  ``SystemIdentifier``       id                            Yes                Unique identifier
  ``Name``                   string                        Yes                Name of weather station
  ``extension/EPWFilePath``  string                        Yes                Path to the EnergyPlus weather file (EPW) [#]_
  =========================  ======  =======  ===========  ========  =======  ==============================================

  .. [#] A full set of U.S. TMY3 weather files can be `downloaded here <https://data.nrel.gov/system/files/128/tmy3s-cache-csv.zip>`_.

HPXML Enclosure
---------------

The dwelling unit's enclosure is entered in ``/HPXML/Building/BuildingDetails/Enclosure``.

All surfaces that bound different space types of the dwelling unit (i.e., not just thermal boundary surfaces) must be specified in the HPXML file.
For example, an attached garage would generally be defined by walls adjacent to conditioned space, walls adjacent to outdoors, a slab, and a roof or ceiling.
For software tools that do not collect sufficient inputs for every required surface, the software developers will need to make assumptions about these surfaces or collect additional input.

Interior partition surfaces (e.g., walls between rooms inside conditioned space, or the floor between two conditioned stories) can be excluded.

For single-family attached (SFA) or multifamily (MF) buildings, surfaces between unconditioned space and the neighboring unit's same unconditioned space should set ``InteriorAdjacentTo`` and ``ExteriorAdjacentTo`` to the same value.
For example, a foundation wall between the unit's vented crawlspace and the neighboring unit's vented crawlspace would use ``InteriorAdjacentTo="crawlspace - vented"`` and ``ExteriorAdjacentTo="crawlspace - vented"``.

.. warning::

  It is the software tool's responsibility to provide the appropriate building surfaces. 
  While some error-checking is in place, it is not possible to know whether some surfaces are incorrectly missing.

Also note that wall and roof surfaces do not require an azimuth/orientation to be specified. 
Rather, only the windows/skylights themselves require an azimuth/orientation. 
Thus, software tools can choose to use a single wall (or roof) surface to represent multiple wall (or roof) surfaces for the entire building if all their other properties (construction type, interior/exterior adjacency, etc.) are identical.

HPXML Air Infiltration
**********************

Building air leakage is entered in ``/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement``.

  ====================================  ======  =====  =================================  =========  =========================  ===============================================
  Element                               Type    Units  Constraints                        Required   Default                    Notes
  ====================================  ======  =====  =================================  =========  =========================  ===============================================
  ``SystemIdentifier``                  id                                                Yes                                   Unique identifier
  ``BuildingAirLeakage/UnitofMeasure``  string         See [#]_                           Yes                                   Units for air leakage
  ``HousePressure``                     double  Pa     > 0                                See [#]_                              House pressure with respect to outside [#]_
  ``BuildingAirLeakage/AirLeakage``     double         > 0                                Yes                                   Value for air leakage
  ``InfiltrationVolume``                double  ft3    > 0, >= ConditionedBuildingVolume  No         ConditionedBuildingVolume  Volume associated with infiltration measurement
  ====================================  ======  =====  =================================  =========  =========================  ===============================================

  .. [#] UnitofMeasure choices are "ACH" (air changes per hour at user-specified pressure), "CFM" (cubic feet per minute at user-specified pressure), or "ACHnatural" (natural air changes per hour).
  .. [#] HousePressure only required if BuildingAirLeakage/UnitofMeasure is not "ACHnatural".
  .. [#] HousePressure typical value is 50 Pa.

HPXML Attics
************

If the dwelling unit has a vented attic, attic ventilation information can be optionally entered in ``/HPXML/Building/BuildingDetails/Enclosure/Attics/Attic[AtticType/Attic[Vented="true"]]/VentilationRate``.

  =================  ======  =====  ===========  ========  ==========  ==========================
  Element            Type    Units  Constraints  Required  Default     Notes
  =================  ======  =====  ===========  ========  ==========  ==========================
  ``UnitofMeasure``  string         See [#]_     No        SLA         Units for ventilation rate
  ``Value``          double         > 0          No        1/300 [#]_  Value for ventilation rate
  =================  ======  =====  ===========  ========  ==========  ==========================

  .. [#] UnitofMeasure choices are "SLA" (specific leakage area) or "ACHnatural" (natural air changes per hour).
  .. [#] Value default based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

HPXML Foundations
*****************

If the dwelling unit has a vented crawlspace, crawlspace ventilation information can be optionally entered in ``/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation[FoundationType/Crawlspace[Vented="true"]]/VentilationRate``.

  =================  ======  =====  ===========  ========  ==========  ==========================
  Element            Type    Units  Constraints  Required  Default     Notes
  =================  ======  =====  ===========  ========  ==========  ==========================
  ``UnitofMeasure``  string         See [#]_     No        SLA         Units for ventilation rate
  ``Value``          double         > 0          No        1/150 [#]_  Value for ventilation rate
  =================  ======  =====  ===========  ========  ==========  ==========================

  .. [#] UnitofMeasure only choice is "SLA" (specific leakage area).
  .. [#] Value default based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

HPXML Roofs
***********

Each pitched or flat roof surface that is exposed to ambient conditions is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof``.

For a multifamily building where the dwelling unit has another dwelling unit above it, the surface between the two dwelling units should be considered a ``FrameFloor`` and not a ``Roof``.

  ======================================  =================  ================  =====================  =========  ==============================  ==================================
  Element                                 Type               Units             Constraints            Required   Default                         Notes
  ======================================  =================  ================  =====================  =========  ==============================  ==================================
  ``SystemIdentifier``                    id                                                          Yes                                        Unique identifier
  ``InteriorAdjacentTo``                  string                               See [#]_               Yes                                        Interior adjacent space type
  ``Area``                                double             ft2               > 0                    Yes                                        Gross area (including skylights)
  ``Azimuth`` or ``Orientation``          integer or string  deg or direction  0 - 359 or See [#]_    No         See [#]_                        Direction (clockwise from North)
  ``RoofType``                            string                               See [#]_               No         asphalt or fiberglass shingles  Roof type
  ``RoofColor`` or ``SolarAbsorptance``   string or double                     See [#]_ or 0 - 1      No         medium                          Roof color or solar absorptance [#]_
  ``Emittance``                           double                               0 - 1                  No         0.90                            Emittance
  ``InteriorFinish/Type``                 string                               See [#]_               No         See [#]_                        Interior finish material
  ``InteriorFinish/Thickness``            double             in                >= 0                   No         0.5                             Interior finish thickness
  ``Pitch``                               integer            ?:12              >= 0                   Yes                                        Pitch
  ``RadiantBarrier``                      boolean                                                     No         false                           Presence of radiant barrier
  ``RadiantBarrierGrade``                 integer                              1 - 3                  No         1                               Radiant barrier installation grade
  ``Insulation/SystemIdentifier``         id                                                          Yes                                        Unique identifier
  ``Insulation/AssemblyEffectiveRValue``  double             F-ft2-hr/Btu      > 0                    Yes                                        Assembly R-value [#]_
  ======================================  =================  ================  =====================  =========  ==============================  ==================================

  .. [#] InteriorAdjacentTo choices are "attic - vented", "attic - unvented", "living space", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] If neither Azimuth nor Orientation provided, modeled as four surfaces of equal area facing every direction.
  .. [#] RoofType choices are "asphalt or fiberglass shingles", "wood shingles or shakes", "shingles", "slate or tile shingles", "metal surfacing", "plastic/rubber/synthetic sheeting", "expanded polystyrene sheathing", "concrete", or "cool roof".
  .. [#] RoofColor choices are "light", "medium", "medium dark", "dark", or "reflective".
  .. [#] If SolarAbsorptance not provided, defaults based on RoofType and RoofColor:
         
         - **asphalt or fiberglass shingles**: dark=0.92, medium dark=0.89, medium=0.85, light=0.75, reflective=0.50
         - **wood shingles or shakes**: dark=0.92, medium dark=0.89, medium=0.85, light=0.75, reflective=0.50
         - **shingles**: dark=0.92, medium dark=0.89, medium=0.85, light=0.75, reflective=0.50
         - **slate or tile shingles**: dark=0.90, medium dark=0.83, medium=0.75, light=0.60, reflective=0.30
         - **metal surfacing**: dark=0.90, medium dark=0.83, medium=0.75, light=0.60, reflective=0.30
         - **plastic/rubber/synthetic sheeting**: dark=0.90, medium dark=0.83, medium=0.75, light=0.60, reflective=0.30
         - **expanded polystyrene sheathing**: dark=0.92, medium dark=0.89, medium=0.85, light=0.75, reflective=0.50
         - **concrete**: dark=0.90, medium dark=0.83, medium=0.75, light=0.65, reflective=0.50
         - **cool roof**: 0.30

  .. [#] InteriorFinish/Type choices are "gypsum board", "gypsum composite board", "plaster", "wood", "other", or "none".
  .. [#] InteriorFinish/Type defaults to "gypsum board" if InteriorAdjacentTo is living space, otherwise "none".
  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior air films, and insulation installation grade.

HPXML Rim Joists
****************

Each rim joist surface (i.e., the perimeter of floor joists typically found between stories of a building or on top of a foundation wall) is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/RimJoists/RimJoist``.

  ======================================  =================  ================  =====================  ========  ===========  ==============================
  Element                                 Type               Units             Constraints            Required  Default      Notes
  ======================================  =================  ================  =====================  ========  ===========  ==============================
  ``SystemIdentifier``                    id                                                          Yes                    Unique identifier
  ``ExteriorAdjacentTo``                  string                               See [#]_               Yes                    Exterior adjacent space type
  ``InteriorAdjacentTo``                  string                               See [#]_               Yes                    Interior adjacent space type
  ``Area``                                double             ft2               > 0                    Yes                    Gross area
  ``Azimuth`` or ``Orientation``          integer or string  deg or direction  0 - 359 or See [#]_    No        See [#]_     Direction (clockwise from North)
  ``Siding``                              string                               See [#]_               No        wood siding  Siding material
  ``Color`` or ``SolarAbsorptance``       string or double                     See [#]_ or 0 - 1      No        medium       Color or solar absorptance [#]_
  ``Emittance``                           double                               0 - 1                  No        0.90         Emittance
  ``Insulation/SystemIdentifier``         id                                                          Yes                    Unique identifier
  ``Insulation/AssemblyEffectiveRValue``  double             F-ft2-hr/Btu      > 0                    Yes                    Assembly R-value [#]_
  ======================================  =================  ================  =====================  ========  ===========  ==============================

  .. [#] ExteriorAdjacentTo choices are "outside", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] InteriorAdjacentTo choices are "living space", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] If neither Azimuth nor Orientation provided, modeled as four surfaces of equal area facing every direction.
  .. [#] Siding choices are "wood siding", "vinyl siding", "stucco", "fiber cement siding", "brick veneer", "aluminum siding", "masonite siding", "composite shingle siding", "asbestos siding", "synthetic stucco", or "none".
  .. [#] Color choices are "light", "medium", "medium dark", "dark", or "reflective".
  .. [#] If SolarAbsorptance not provided, defaults based on Color:

         - **dark**: 0.95
         - **medium dark**: 0.85
         - **medium**: 0.70
         - **light**: 0.50
         - **reflective**: 0.30

  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior air films, and insulation installation grade.

HPXML Walls
***********

Each wall that has no contact with the ground and bounds a space type is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall``.

  ======================================  =================  ================  =====================  =============  ===========  ====================================
  Element                                 Type               Units             Constraints            Required       Default      Notes
  ======================================  =================  ================  =====================  =============  ===========  ====================================
  ``SystemIdentifier``                    id                                                          Yes                         Unique identifier
  ``ExteriorAdjacentTo``                  string                               See [#]_               Yes                         Exterior adjacent space type
  ``InteriorAdjacentTo``                  string                               See [#]_               Yes                         Interior adjacent space type
  ``WallType``                            element                              1 [#]_                 Yes                         Wall type (for thermal mass)
  ``Area``                                double             ft2               > 0                    Yes                         Gross area (including doors/windows)
  ``Azimuth`` or ``Orientation``          integer or string  deg or direction  0 - 359 or See [#]_    No             See [#]_     Direction (clockwise from North)
  ``Siding``                              string                               See [#]_               No             wood siding  Siding material
  ``Color`` or ``SolarAbsorptance``       string or double                     See [#]_ or 0 - 1      No             medium       Color or solar absorptance [#]_
  ``Emittance``                           double                               0 - 1                  No             0.90         Emittance
  ``InteriorFinish/Type``                 string                               See [#]_               No             See [#]_     Interior finish material
  ``InteriorFinish/Thickness``            double             in                >= 0                   No             0.5          Interior finish thickness
  ``Insulation/SystemIdentifier``         id                                                          Yes                         Unique identifier
  ``Insulation/AssemblyEffectiveRValue``  double             F-ft2-hr/Btu      > 0                    Yes                         Assembly R-value [#]_
  ======================================  =================  ================  =====================  =============  ===========  ====================================

  .. [#] ExteriorAdjacentTo choices are "outside", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] InteriorAdjacentTo choices are "living space", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] WallType child element choices are ``WoodStud``, ``DoubleWoodStud``, ``ConcreteMasonryUnit``, ``StructurallyInsulatedPanel``, ``InsulatedConcreteForms``, ``SteelFrame``, ``SolidConcrete``, ``StructuralBrick``, ``StrawBale``, ``Stone``, ``LogWall``, or ``Adobe``.
  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] If neither Azimuth nor Orientation provided, modeled as four surfaces of equal area facing every direction.
  .. [#] Siding choices are "wood siding", "vinyl siding", "stucco", "fiber cement siding", "brick veneer", "aluminum siding", "masonite siding", "composite shingle siding", "asbestos siding", "synthetic stucco", or "none".
  .. [#] Color choices are "light", "medium", "medium dark", "dark", or "reflective".
  .. [#] If SolarAbsorptance not provided, defaults based on Color:

         - **dark**: 0.95
         - **medium dark**: 0.85
         - **medium**: 0.70
         - **light**: 0.50
         - **reflective**: 0.30

  .. [#] InteriorFinish/Type choices are "gypsum board", "gypsum composite board", "plaster", "wood", "other", or "none".
  .. [#] InteriorFinish/Type defaults to "gypsum board" if InteriorAdjacentTo is living space or basement - conditioned, otherwise "none".
  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior air films, and insulation installation grade.

HPXML Foundation Walls
**********************

Each wall that is in contact with the ground should be specified as an ``/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall``.

Other walls (e.g., wood framed walls) that are connected to a below-grade space but have no contact with the ground should be specified as a ``Wall`` and not a ``FoundationWall``.

  ==============================================================  =================  ================  ===================  =========  ==============  ====================================
  Element                                                         Type               Units             Constraints          Required   Default         Notes
  ==============================================================  =================  ================  ===================  =========  ==============  ====================================
  ``SystemIdentifier``                                            id                                                        Yes                        Unique identifier
  ``ExteriorAdjacentTo``                                          string                               See [#]_             Yes                        Exterior adjacent space type [#]_
  ``InteriorAdjacentTo``                                          string                               See [#]_             Yes                        Interior adjacent space type
  ``Type``                                                        string                               See [#]_             No         solid concrete  Type of material
  ``Height``                                                      double             ft                > 0                  Yes                        Total height
  ``Area`` or ``Length``                                          double             ft2 or ft         > 0                  Yes                        Gross area (including doors/windows) or length
  ``Azimuth`` or ``Orientation``                                  integer or string  deg or direction  0 - 359 or See [#]_  No         See [#]_        Direction (clockwise from North)
  ``Thickness``                                                   double             inches            > 0                  No         8.0             Thickness excluding interior framing
  ``DepthBelowGrade``                                             double             ft                0 - Height           Yes                        Depth below grade [#]_
  ``InteriorFinish/Type``                                         string                               See [#]_             No         See [#]_        Interior finish material
  ``InteriorFinish/Thickness``                                    double             in                >= 0                 No         0.5             Interior finish thickness
  ``Insulation/SystemIdentifier``                                 id                                                        Yes                        Unique identifier
  ``Insulation/Layer[InstallationType="continuous - interior"]``  element                              0 - 1                See [#]_                   Interior insulation layer
  ``Insulation/Layer[InstallationType="continuous - exterior"]``  element                              0 - 1                See [#]_                   Exterior insulation layer
  ``Insulation/AssemblyEffectiveRValue``                          double             F-ft2-hr/Btu      > 0                  See [#]_                   Assembly R-value [#]_
  ==============================================================  =================  ================  ===================  =========  ==============  ====================================

  .. [#] ExteriorAdjacentTo choices are "ground", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] InteriorAdjacentTo choices are "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] Interior foundation walls (e.g., between basement and crawlspace) should **not** use "ground" even if the foundation wall has some contact with the ground due to the difference in below-grade depths of the two adjacent spaces.
  .. [#] Type choices are "solid concrete", "concrete block", "concrete block foam core", "concrete block vermiculite core", "concrete block perlite core", "concrete block solid core", "double brick", or "wood".
  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] If neither Azimuth nor Orientation provided, modeled as four surfaces of equal area facing every direction.
  .. [#] For exterior foundation walls, depth below grade is relative to the ground plane.
         For interior foundation walls, depth below grade is the vertical span of foundation wall in contact with the ground.
         For example, an interior foundation wall between an 8 ft conditioned basement and a 3 ft crawlspace has a height of 8 ft and a depth below grade of 5 ft.
         Alternatively, an interior foundation wall between an 8 ft conditioned basement and an 8 ft unconditioned basement has a height of 8 ft and a depth below grade of 0 ft.
  .. [#] InteriorFinish/Type choices are "gypsum board", "gypsum composite board", "plaster", "wood", "other", or "none".
  .. [#] InteriorFinish/Type defaults to "gypsum board" if InteriorAdjacentTo is basement - conditioned, otherwise "none".
  .. [#] Layer[InstallationType="continuous - interior"] only required if AssemblyEffectiveRValue is not provided.
  .. [#] Layer[InstallationType="continuous - exterior"] only required if AssemblyEffectiveRValue is not provided.
  .. [#] AssemblyEffectiveRValue only required if Layer elements are not provided.
  .. [#] AssemblyEffectiveRValue includes all material layers, interior air film, and insulation installation grade.
         R-value should **not** include exterior air film (for any above-grade exposure) or any soil thermal resistance.

If insulation layers are provided, additional information is entered in each ``FoundationWall/Insulation/Layer``.

  ==========================================  ========  ============  ===========  ========  =======  =====================================================================
  Element                                     Type      Units         Constraints  Required  Default  Notes
  ==========================================  ========  ============  ===========  ========  =======  =====================================================================
  ``NominalRValue``                           double    F-ft2-hr/Btu  >= 0         Yes                R-value of the foundation wall insulation; use zero if no insulation
  ``DistanceToTopOfInsulation``               double    ft            >= 0         No        0        Vertical distance from top of foundation wall to top of insulation
  ``DistanceToBottomOfInsulation``            double    ft            See [#]_     No        Height   Vertical distance from top of foundation wall to bottom of insulation
  ==========================================  ========  ============  ===========  ========  =======  =====================================================================

  .. [#] When NominalRValue is non-zero, DistanceToBottomOfInsulation must be greater than DistanceToTopOfInsulation and less than or equal to FoundationWall/Height.

HPXML Frame Floors
******************

Each floor/ceiling surface that is not in contact with the ground (Slab) nor adjacent to ambient conditions above (Roof) is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor``.

  ======================================  ========  ============  ===========  ========  ========  ============================
  Element                                 Type      Units         Constraints  Required  Default   Notes
  ======================================  ========  ============  ===========  ========  ========  ============================
  ``SystemIdentifier``                    id                                   Yes                 Unique identifier
  ``ExteriorAdjacentTo``                  string                  See [#]_     Yes                 Exterior adjacent space type
  ``InteriorAdjacentTo``                  string                  See [#]_     Yes                 Interior adjacent space type
  ``Area``                                double    ft2           > 0          Yes                 Gross area
  ``InteriorFinish/Type``                 string                  See [#]_     No        See [#]_  Interior finish material
  ``InteriorFinish/Thickness``            double    in            >= 0         No        0.5       Interior finish thickness
  ``Insulation/SystemIdentifier``         id                                   Yes                 Unique identifier
  ``Insulation/AssemblyEffectiveRValue``  double    F-ft2-hr/Btu  > 0          Yes                 Assembly R-value [#]_
  ======================================  ========  ============  ===========  ========  ========  ============================

  .. [#] ExteriorAdjacentTo choices are "outside", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] InteriorAdjacentTo choices are "living space", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] InteriorFinish/Type choices are "gypsum board", "gypsum composite board", "plaster", "wood", "other", or "none".
  .. [#] InteriorFinish/Type defaults to "gypsum board" if InteriorAdjacentTo is living space and the surface is a ceiling, otherwise "none".
  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior air films, and insulation installation grade.

For frame floors adjacent to "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space", additional information is entered in ``FrameFloor``.

  ======================================  ========  =====  ==============  ========  =======  ==========================================
  Element                                 Type      Units  Constraints     Required  Default  Notes
  ======================================  ========  =====  ==============  ========  =======  ==========================================
  ``extension/OtherSpaceAboveOrBelow``    string           See [#]_        Yes                Specifies if above/below the MF space type
  ======================================  ========  =====  ==============  ========  =======  ==========================================

  .. [#] OtherSpaceAboveOrBelow choices are "above" or "below".

HPXML Slabs
***********

Each space type that borders the ground (i.e., basements, crawlspaces, garages, and slab-on-grade foundations) should have a slab entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab``.

  =======================================================  ========  ============  ===========  =========  ========  ====================================================
  Element                                                  Type      Units         Constraints  Required   Default   Notes
  =======================================================  ========  ============  ===========  =========  ========  ====================================================
  ``SystemIdentifier``                                     id                                   Yes                  Unique identifier
  ``InteriorAdjacentTo``                                   string                  See [#]_     Yes                  Interior adjacent space type
  ``Area``                                                 double    ft2           > 0          Yes                  Gross area
  ``Thickness``                                            double    inches        >= 0         No         See [#]_  Thickness [#]_
  ``ExposedPerimeter``                                     double    ft            >= 0         Yes                  Perimeter exposed to ambient conditions [#]_
  ``DepthBelowGrade``                                      double    ft            >= 0         See [#]_             Depth from the top of the slab surface to grade
  ``PerimeterInsulation/SystemIdentifier``                 id                                   Yes                  Unique identifier
  ``PerimeterInsulation/Layer/NominalRValue``              double    F-ft2-hr/Btu  >= 0         Yes                  R-value of vertical insulation
  ``PerimeterInsulation/Layer/InsulationDepth``            double    ft            >= 0         Yes                  Depth from grade to bottom of vertical insulation
  ``UnderSlabInsulation/SystemIdentifier``                 id                                   Yes                  Unique identifier
  ``UnderSlabInsulation/Layer/NominalRValue``              double    F-ft2-hr/Btu  >= 0         Yes                  R-value of horizontal insulation
  ``UnderSlabInsulation/Layer/InsulationWidth``            double    ft            >= 0         See [#]_             Width from slab edge inward of horizontal insulation
  ``UnderSlabInsulation/Layer/InsulationSpansEntireSlab``  boolean                              See [#]_             Whether horizontal insulation spans entire slab
  ``extension/CarpetFraction``                             double    frac          0 - 1        No         See [#]_  Fraction of slab covered by carpet
  ``extension/CarpetRValue``                               double    F-ft2-hr/Btu  >= 0         No         See [#]_  Carpet R-value
  =======================================================  ========  ============  ===========  =========  ========  ====================================================

  .. [#] InteriorAdjacentTo choices are "living space", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If Thickness not provided, defaults to 0 when adjacent to crawlspace and 4 inches for all other cases.
  .. [#] For a crawlspace with a dirt floor, enter a thickness of zero.
  .. [#] ExposedPerimeter includes any slab length that falls along the perimeter of the building's footprint (i.e., is exposed to ambient conditions).
         So a basement slab edge adjacent to a garage or crawlspace, for example, should not be included.
  .. [#] DepthBelowGrade only required if the attached foundation has no ``FoundationWalls``.
         For foundation types with walls, the the slab's position relative to grade is determined by the ``FoundationWall/DepthBelowGrade`` value.
  .. [#] InsulationWidth only required if InsulationSpansEntireSlab=true is not provided.
  .. [#] InsulationSpansEntireSlab=true only required if InsulationWidth is not provided.
  .. [#] If CarpetFraction not provided, defaults to 0.8 when adjacent to conditioned space, otherwise 0.0.
  .. [#] If CarpetRValue not provided, defaults to 2.0 when adjacent to conditioned space, otherwise 0.0.
  
.. _windowinputs:

HPXML Windows
*************

Each window or glass door area is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Windows/Window``.

  ============================================  =================  ================  ===================  ========  =========  =============================================================
  Element                                       Type               Units             Constraints          Required  Default    Notes
  ============================================  =================  ================  ===================  ========  =========  =============================================================
  ``SystemIdentifier``                          id                                                        Yes                  Unique identifier
  ``Area``                                      double             ft2               > 0                  Yes                  Total area
  ``Azimuth`` or ``Orientation``                integer or string  deg or direction  0 - 359 or See [#]_  Yes                  Direction (clockwise from North)
  ``UFactor`` and/or ``GlassLayers``            double or string   Btu/F-ft2-hr      > 0 or See [#]_      Yes                  Full-assembly NFRC U-factor (including any storm window) or glass layers description
  ``SHGC`` and/or ``GlassLayers``               double or string                     0 - 1                Yes                  Full-assembly NFRC solar heat gain coefficient (including any storm window) or glass layers description
  ``ExteriorShading/SummerShadingCoefficient``  double             frac              0 - 1                No        1.00       Exterior summer shading coefficient (1=transparent, 0=opaque)
  ``ExteriorShading/WinterShadingCoefficient``  double             frac              0 - 1                No        1.00       Exterior winter shading coefficient (1=transparent, 0=opaque)
  ``InteriorShading/SummerShadingCoefficient``  double             frac              0 - 1                No        0.70 [#]_  Interior summer shading coefficient (1=transparent, 0=opaque)
  ``InteriorShading/WinterShadingCoefficient``  double             frac              0 - 1                No        0.85 [#]_  Interior winter shading coefficient (1=transparent, 0=opaque)
  ``Overhangs``                                 element                              0 - 1                No        <none>     Presence of overhangs (including roof eaves)
  ``FractionOperable``                          double             frac              0 - 1                No        0.67       Operable fraction [#]_
  ``AttachedToWall``                            idref                                See [#]_             Yes                  ID of attached wall
  ============================================  =================  ================  ===================  ========  =========  =============================================================

  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north".
  .. [#] GlassLayers choices are "single-pane", "double-pane", "triple-pane", or "glass block".
  .. [#] InteriorShading/SummerShadingCoefficient default value indicates 30% reduction in solar heat gain, based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.
  .. [#] InteriorShading/WinterShadingCoefficient default value indicates 15% reduction in solar heat gain, based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.
  .. [#] FractionOperable reflects whether the windows are operable (can be opened), not how they are used by the occupants.
         If a ``Window`` represents a single window, the value should be 0 or 1.
         If a ``Window`` represents multiple windows (e.g., 4), the value should be between 0 and 1 (e.g., 0, 0.25, 0.5, 0.75, or 1).
         The total open window area for natural ventilation is calculated using A) the operable fraction, B) the assumption that 50% of the area of operable windows can be open, and C) the assumption that 20% of that openable area is actually opened by occupants whenever outdoor conditions are favorable for cooling.
  .. [#] AttachedToWall must reference a ``Wall`` or ``FoundationWall``.

If UFactor and SHGC are not provided and GlassLayers is not "glass block", additional information is entered in ``Window``.

  ============================  ========  ======  =======================  ========  ========  ========================================================
  Element                       Type      Units   Constraints              Required  Default   Notes
  ============================  ========  ======  =======================  ========  ========  ========================================================
  ``FrameType``                 element           See [#]_                 Yes                 Type of frame
  ``FrameType/*/ThermalBreak``  boolean           See [#]_                 No        false     Whether the Aluminum or Metal frame has a thermal break
  ``GlassType``                 string            See [#]_                 No        <none>    Type of glass
  ``GasFill``                   string            See [#]_                 No        See [#]_  Type of gas inside double/triple-pane windows
  ============================  ========  ======  =======================  ========  ========  ========================================================
  
  .. [#] FrameType child element choices are ``Aluminum``, ``Fiberglass``, ``Metal``, ``Vinyl``, or ``Wood``.
  .. [#] ThermalBreak is only valid if FrameType is ``Aluminum`` or ``Metal``.
  .. [#] GlassType choices are "clear", "low-e", "tinted", "tinted/reflective", or "reflective".
         Do not specify this element if the window has clear glass.
  .. [#] GasFill choices are "air", "argon", "krypton", "xenon", "nitrogen", or "other".
  .. [#] If GasFill not provided, defaults to "air" for double-pane windows and "argon" for triple-pane windows.

If UFactor and SHGC are not provided, they are defaulted as follows:
  
  ===========  =======================  ============  =========================  =============  =======  ====
  GlassLayers  FrameType                ThermalBreak  GlassType                  GasFill        UFactor  SHGC
  ===========  =======================  ============  =========================  =============  =======  ====
  single-pane  Aluminum, Metal          false         clear                      --             1.27     0.75
  single-pane  Fiberglass, Vinyl, Wood  --            clear                      --             0.89     0.64
  single-pane  Aluminum, Metal          false         tinted, tinted/reflective  --             1.27     0.64
  single-pane  Fiberglass, Vinyl, Wood  --            tinted, tinted/reflective  --             0.89     0.54
  double-pane  Aluminum, Metal          false         clear                      air            0.81     0.67
  double-pane  Aluminum, Metal          true          clear                      air            0.60     0.67
  double-pane  Fiberglass, Vinyl, Wood  --            clear                      air            0.51     0.56
  double-pane  Aluminum, Metal          false         tinted, tinted/reflective  air            0.81     0.55
  double-pane  Aluminum, Metal          true          tinted, tinted/reflective  air            0.60     0.55
  double-pane  Fiberglass, Vinyl, Wood  --            tinted, tinted/reflective  air            0.51     0.46
  double-pane  Fiberglass, Vinyl, Wood  --            low-e                      air            0.42     0.52
  double-pane  Aluminum, Metal          true          low-e                      <any but air>  0.47     0.62
  double-pane  Fiberglass, Vinyl, Wood  --            low-e                      <any but air>  0.39     0.52
  double-pane  Aluminum, Metal          false         reflective                 air            0.67     0.37
  double-pane  Aluminum, Metal          true          reflective                 air            0.47     0.37
  double-pane  Fiberglass, Vinyl, Wood  --            reflective                 air            0.39     0.31
  double-pane  Fiberglass, Vinyl, Wood  --            reflective                 <any but air>  0.36     0.31
  triple-pane  Fiberglass, Vinyl, Wood  --            low-e                      <any but air>  0.27     0.31
  glass block  --                       --            --                         --             0.60     0.60
  ===========  =======================  ============  =========================  =============  =======  ====

.. warning::

  OpenStudio-HPXML will return an error if the combination of window properties is not in the above table.

If overhangs are specified, additional information is entered in ``Overhangs``.

  ============================  ========  ======  ===========  ========  =======  ========================================================
  Element                       Type      Units   Constraints  Required  Default  Notes
  ============================  ========  ======  ===========  ========  =======  ========================================================
  ``Depth``                     double    inches  >= 0         Yes                Depth of overhang
  ``DistanceToTopOfWindow``     double    ft      >= 0         Yes                Vertical distance from overhang to top of window
  ``DistanceToBottomOfWindow``  double    ft      See [#]_     Yes                Vertical distance from overhang to bottom of window [#]_
  ============================  ========  ======  ===========  ========  =======  ========================================================

  .. [#] The difference between DistanceToBottomOfWindow and DistanceToTopOfWindow defines the height of the window.
  .. [#] When Depth is non-zero, DistanceToBottomOfWindow must be greater than DistanceToTopOfWindow.

HPXML Skylights
***************

Each skylight is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Skylights/Skylight``.

  ============================================  =================  ================  ===================  ========  =========  =============================================================
  Element                                       Type               Units             Constraints          Required  Default    Notes
  ============================================  =================  ================  ===================  ========  =========  =============================================================
  ``SystemIdentifier``                          id                                                        Yes                  Unique identifier
  ``Area``                                      double             ft2               > 0                  Yes                  Total area
  ``Azimuth`` or ``Orientation``                integer or string  deg or direction  0 - 359 or See [#]_  Yes                  Direction (clockwise from North)
  ``UFactor`` and/or ``GlassLayers``            double or string   Btu/F-ft2-hr      > 0 or See [#]_      Yes                  Full-assembly NFRC U-factor or glass layers description
  ``SHGC`` and/or ``GlassLayers``               double or string                     0 - 1                Yes                  Full-assembly NFRC solar heat gain coefficient or glass layers description
  ``ExteriorShading/SummerShadingCoefficient``  double             frac              0 - 1                No        1.00       Exterior summer shading coefficient (1=transparent, 0=opaque)
  ``ExteriorShading/WinterShadingCoefficient``  double             frac              0 - 1                No        1.00       Exterior winter shading coefficient (1=transparent, 0=opaque)
  ``InteriorShading/SummerShadingCoefficient``  double             frac              0 - 1                No        1.00       Interior summer shading coefficient (1=transparent, 0=opaque)
  ``InteriorShading/WinterShadingCoefficient``  double             frac              0 - 1                No        1.00       Interior winter shading coefficient (1=transparent, 0=opaque)
  ``AttachedToRoof``                            idref                                See [#]_             Yes                  ID of attached roof
  ============================================  =================  ================  ===================  ========  =========  =============================================================

  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] GlassLayers choices are "single-pane", "double-pane", or "triple-pane".
  .. [#] AttachedToRoof must reference a ``Roof``.

If UFactor and SHGC are not provided and GlassLayers is not "glass block", additional information is entered in ``Skylight``.

  ============================  ========  ======  =======================  ========  ========  ========================================================
  Element                       Type      Units   Constraints              Required  Default   Notes
  ============================  ========  ======  =======================  ========  ========  ========================================================
  ``FrameType``                 element           See [#]_                 Yes                 Type of frame
  ``FrameType/*/ThermalBreak``  boolean           See [#]_                 No        false     Whether the Aluminum or Metal frame has a thermal break
  ``GlassType``                 string            See [#]_                 No        <none>    Type of glass
  ``GasFill``                   string            See [#]_                 No        See [#]_  Type of gas inside double/triple-pane skylights
  ============================  ========  ======  =======================  ========  ========  ========================================================
  
  .. [#] FrameType child element choices are ``Aluminum``, ``Fiberglass``, ``Metal``, ``Vinyl``, or ``Wood``.
  .. [#] ThermalBreak is only valid if FrameType is ``Aluminum`` or ``Metal``.
  .. [#] GlassType choices are "clear", "low-e", "tinted", "tinted/reflective", or "reflective".
         Do not specify this element if the skylight has clear glass.
  .. [#] GasFill choices are "air", "argon", "krypton", "xenon", "nitrogen", or "other".
  .. [#] If GasFill not provided, defaults to "air" for double-pane skylights and "argon" for triple-pane skylights.

If UFactor and SHGC are not provided, they are defaulted as follows:
  
  ===========  =======================  ============  =========================  =============  =======  ====
  GlassLayers  FrameType                ThermalBreak  GlassType                  GasFill        UFactor  SHGC
  ===========  =======================  ============  =========================  =============  =======  ====
  single-pane  Aluminum, Metal          false         clear                      --             1.98     0.75
  single-pane  Fiberglass, Vinyl, Wood  --            clear                      --             1.47     0.64
  single-pane  Aluminum, Metal          false         tinted, tinted/reflective  --             1.98     0.64
  single-pane  Fiberglass, Vinyl, Wood  --            tinted, tinted/reflective  --             1.47     0.54
  double-pane  Aluminum, Metal          false         clear                      air            1.30     0.67
  double-pane  Aluminum, Metal          true          clear                      air            1.10     0.67
  double-pane  Fiberglass, Vinyl, Wood  --            clear                      air            0.84     0.56
  double-pane  Aluminum, Metal          false         tinted, tinted/reflective  air            1.30     0.55
  double-pane  Aluminum, Metal          true          tinted, tinted/reflective  air            1.10     0.55
  double-pane  Fiberglass, Vinyl, Wood  --            tinted, tinted/reflective  air            0.84     0.46
  double-pane  Fiberglass, Vinyl, Wood  --            low-e                      air            0.74     0.52
  double-pane  Aluminum, Metal          true          low-e                      <any but air>  0.95     0.62
  double-pane  Fiberglass, Vinyl, Wood  --            low-e                      <any but air>  0.68     0.52
  double-pane  Aluminum, Metal          false         reflective                 air            1.17     0.37
  double-pane  Aluminum, Metal          true          reflective                 air            0.98     0.37
  double-pane  Fiberglass, Vinyl, Wood  --            reflective                 air            0.71     0.31
  double-pane  Fiberglass, Vinyl, Wood  --            reflective                 <any but air>  0.65     0.31
  triple-pane  Fiberglass, Vinyl, Wood  --            low-e                      <any but air>  0.47     0.31
  glass block  --                       --            --                         --             0.60     0.60
  ===========  =======================  ============  =========================  =============  =======  ====

.. warning::

  OpenStudio-HPXML will return an error if the combination of skylight properties is not in the above table.

HPXML Doors
***********

Each opaque door is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Doors/Door``.

  ============================================  =================  ============  ===================  ========  =========  ==============================
  Element                                       Type               Units         Constraints          Required  Default    Notes
  ============================================  =================  ============  ===================  ========  =========  ==============================
  ``SystemIdentifier``                          id                                                    Yes                  Unique identifier
  ``AttachedToWall``                            idref                            See [#]_             Yes                  ID of attached wall
  ``Area``                                      double             ft2           > 0                  Yes                  Total area
  ``Azimuth`` or ``Orientation``                integer or string  deg           0 - 359 or See [#]_  No        See [#]_   Direction (clockwise from North)
  ``RValue``                                    double             F-ft2-hr/Btu  > 0                  Yes                  R-value (including any storm door)
  ============================================  =================  ============  ===================  ========  =========  ==============================

  .. [#] AttachedToWall must reference a ``Wall`` or ``FoundationWall``.
  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] If neither Azimuth nor Orientation nor AttachedToWall azimuth provided, defaults to the azimuth with the largest surface area defined in the HPXML file.

HPXML Partition Wall Mass
*************************

Partition wall mass in the conditioned space is entered as ``/HPXML/Building/BuildingDetails/Enclosure/extension/PartitionWallMass``.

  ============================================  ======  ============  ===========  ========  ============  =================================================
  Element                                       Type    Units         Constraints  Required  Default       Notes
  ============================================  ======  ============  ===========  ========  ============  =================================================
  ``AreaFraction``                              double  frac          >= 0         No        1.0           Fraction of both sides of wall area to conditioned floor area
  ``InteriorFinish/Type``                       string                See [#]_     No        gypsum board  Interior finish material
  ``InteriorFinish/Thickness``                  double  in            >= 0         No        0.5           Interior finish thickness
  ============================================  ======  ============  ===========  ========  ============  =================================================

  .. [#] InteriorFinish/Type choices are "gypsum board", "gypsum composite board", "plaster", "wood", "other", or "none".

HPXML Furniture Mass
********************

Furniture mass in the conditioned space is entered as ``/HPXML/Building/BuildingDetails/Enclosure/extension/FurnitureMass``.

  ============================================  ======  ============  ===========  ========  ============  =================================================
  Element                                       Type    Units         Constraints  Required  Default       Notes
  ============================================  ======  ============  ===========  ========  ============  =================================================
  ``AreaFraction``                              double  frac          >= 0         No        0.4           Fraction of conditioned floor area covered by furniture
  ``Type``                                      string                See [#]_     No        light-weight  Type of furniture
  ============================================  ======  ============  ===========  ========  ============  =================================================

  .. [#] Type choices are "light-weight" and "heavy-weight". 

.. note::

  Light-weight furniture is modeled with a weight of 8 lb/ft2 of floor area and a density of 40 lb/ft3 while heavy-weight furniture is modeled with a weight of 16 lb/ft2 of floor area and a density of 80 lb/ft3.

HPXML Systems
-------------

The dwelling unit's systems are entered in ``/HPXML/Building/BuildingDetails/Systems``.

.. _hvac_heating:

HPXML Heating Systems
*********************

Each heating system (other than a heat pump) is entered as an ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatingSystem``.

  =================================  ========  ======  ===========  ========  =========  ===============================
  Element                            Type      Units   Constraints  Required  Default    Notes
  =================================  ========  ======  ===========  ========  =========  ===============================
  ``SystemIdentifier``               id                             Yes                  Unique identifier
  ``HeatingSystemType``              element           1 [#]_       Yes                  Type of heating system
  ``HeatingSystemFuel``              string            See [#]_     Yes                  Fuel type
  ``HeatingCapacity``                double    Btu/hr  >= 0         No        autosized  Heating output capacity
  ``FractionHeatLoadServed``         double    frac    0 - 1 [#]_   See [#]_             Fraction of heating load served
  =================================  ========  ======  ===========  ========  =========  ===============================

  .. [#] HeatingSystemType child element choices are ``ElectricResistance``, ``Furnace``, ``WallFurnace``, ``FloorFurnace``, ``Boiler``, ``Stove``, ``PortableHeater``, ``FixedHeater``, ``Fireplace``, or ``PackagedTerminalAirConditionerHeating``.
  .. [#] HeatingSystemFuel choices are  "electricity", "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "wood", or "wood pellets".
         For ``ElectricResistance``, "electricity" is required.
         For ``PackagedTerminalAirConditionerHeating``, "electricity" is currently the only choice.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across both HeatingSystems and HeatPumps) must be less than or equal to 1.
  .. [#] FractionHeatLoadServed is required unless the heating system is a heat pump backup system (i.e., referenced by a ``HeatPump[BackupType="separate"]/BackupSystem``; see :ref:`hvac_heatpump`), in which case FractionHeatLoadServed is not allowed.

Electric Resistance
~~~~~~~~~~~~~~~~~~~

If electric resistance heating is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =====  ===========  ========  =======  ==========
  Element                                             Type    Units  Constraints  Required  Default  Notes
  ==================================================  ======  =====  ===========  ========  =======  ==========
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac   0 - 1        No        1.0      Efficiency
  ==================================================  ======  =====  ===========  ========  =======  ==========

PTAC Heating
~~~~~~~~~~~~

If a PTAC with non-heat pump (e.g., electric resistance) heating is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =========  ===========  ========  =======  ==================================
  Element                                             Type    Units      Constraints  Required  Default  Notes
  ==================================================  ======  =========  ===========  ========  =======  ==================================
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac       0 - 1        No        1.0      Efficiency
  ==================================================  ======  =========  ===========  ========  =======  ==================================

.. note::

  A cooling system of type "packaged terminal air conditioner" must be specified in ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem``.

Furnace
~~~~~~~

If a furnace is specified, additional information is entered in ``HeatingSystem``.

  ====================================================================  =================  =========  ===============  ========  ========  ================================================
  Element                                                               Type               Units      Constraints      Required  Default   Notes
  ====================================================================  =================  =========  ===============  ========  ========  ================================================
  ``DistributionSystem``                                                idref              See [#]_                    Yes                 ID of attached distribution system
  ``AnnualHeatingEfficiency[Units="AFUE"]/Value`` or ``YearInstalled``  double or integer  frac or #  0 - 1 or > 1600  Yes       See [#]_  Rated efficiency or Year installed
  ``extension/FanPowerWattsPerCFM``                                     double             W/cfm      >= 0             No        See [#]_  Fan efficiency at maximum airflow rate [#]_
  ``extension/AirflowDefectRatio``                                      double             frac       > -1             No        0.0       Deviation between design/installed airflows [#]_
  ====================================================================  =================  =========  ===============  ========  ========  ================================================

  .. [#] HVACDistribution type must be AirDistribution (type: "regular velocity" or "gravity") or DSE.
  .. [#] If AnnualHeatingEfficiency[Units="AFUE"]/Value not provided, defaults to 0.98 if FuelType is "electricity", else AFUE from the lookup table that can be found at ``HPXMLtoOpenStudio\resources\lu_hvac_equipment_efficiency.csv`` based on YearInstalled.
  .. [#] If FanPowerWattsPerCFM not provided, defaulted to 0 W/cfm if gravity distribution system, else 0.5 W/cfm if AFUE <= 0.9, else 0.375 W/cfm.
  .. [#] If there is a cooling system attached to the DistributionSystem, the heating and cooling systems cannot have different values for FanPowerWattsPerCFM.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

Wall/Floor Furnace
~~~~~~~~~~~~~~~~~~

If a wall furnace or floor furnace is specified, additional information is entered in ``HeatingSystem``.

  ====================================================================  =================  =========  ===============  ========  ========  ==================================
  Element                                                               Type               Units      Constraints      Required  Default   Notes
  ====================================================================  =================  =========  ===============  ========  ========  ==================================
  ``AnnualHeatingEfficiency[Units="AFUE"]/Value`` or ``YearInstalled``  double or integer  frac or #  0 - 1 or > 1600  Yes       See [#]_  Rated efficiency or Year installed
  ``extension/FanPowerWatts``                                           double             W          >= 0             No        0         Fan power
  ====================================================================  =================  =========  ===============  ========  ========  ==================================

  .. [#] If AnnualHeatingEfficiency[Units="AFUE"]/Value not provided, defaults to 0.98 if FuelType is "electricity", else AFUE from the lookup table that can be found at ``HPXMLtoOpenStudio\resources\lu_hvac_equipment_efficiency.csv`` based on YearInstalled.

.. _hvac_heating_boiler:

Boiler
~~~~~~

If a boiler is specified, additional information is entered in ``HeatingSystem``.

  ====================================================================  =================  =========  ===============  ========  ========  =========================================
  Element                                                               Type               Units      Constraints      Required  Default   Notes
  ====================================================================  =================  =========  ===============  ========  ========  =========================================
  ``IsSharedSystem``                                                    boolean                       No               false               Whether it serves multiple dwelling units
  ``DistributionSystem``                                                idref              See [#]_   Yes                                  ID of attached distribution system
  ``AnnualHeatingEfficiency[Units="AFUE"]/Value`` or ``YearInstalled``  double or integer  frac or #  0 - 1 or > 1600  Yes       See [#]_  Rated efficiency or Year installed
  ====================================================================  =================  =========  ===============  ========  ========  =========================================

  .. [#] For in-unit boilers, HVACDistribution type must be HydronicDistribution (type: "radiator", "baseboard", "radiant floor", or "radiant ceiling") or DSE.
         For shared boilers, HVACDistribution type must be HydronicDistribution (type: "radiator", "baseboard", "radiant floor", "radiant ceiling", or "water loop") or AirDistribution (type: "fan coil").
         If the shared boiler has "water loop" distribution, a :ref:`hvac_heatpump_wlhp` must also be specified.
  .. [#] If AnnualHeatingEfficiency[Units="AFUE"]/Value not provided, defaults to 0.98 if FuelType is "electricity", else AFUE from the lookup table that can be found at ``HPXMLtoOpenStudio\resources\lu_hvac_equipment_efficiency.csv`` based on YearInstalled.
         

If an in-unit boiler if specified, additional information is entered in ``HeatingSystem``.

  ===========================  ========  ======  ===========  ========  ========  =========================
  Element                      Type      Units   Constraints  Required  Default   Notes
  ===========================  ========  ======  ===========  ========  ========  =========================
  ``ElectricAuxiliaryEnergy``  double    kWh/yr  >= 0         No        See [#]_  Electric auxiliary energy
  ===========================  ========  ======  ===========  ========  ========  =========================

  .. [#] If ElectricAuxiliaryEnergy not provided, defaults as follows:

         - **Oil boiler**: 330 kWh/yr
         - **Gas boiler**: 170 kWh/yr

If instead a shared boiler is specified, additional information is entered in ``HeatingSystem``.

  ============================================================  ========  ===========  ===========  ========  ========  =========================
  Element                                                       Type      Units        Constraints  Required  Default   Notes
  ============================================================  ========  ===========  ===========  ========  ========  =========================
  ``NumberofUnitsServed``                                       integer                > 1          Yes                 Number of dwelling units served
  ``ElectricAuxiliaryEnergy`` or ``extension/SharedLoopWatts``  double    kWh/yr or W  >= 0         No        See [#]_  Electric auxiliary energy or shared loop power
  ``ElectricAuxiliaryEnergy`` or ``extension/FanCoilWatts``     double    kWh/yr or W  >= 0         No [#]_             Electric auxiliary energy or fan coil power
  ============================================================  ========  ===========  ===========  ========  ========  =========================

  .. [#] If ElectricAuxiliaryEnergy nor SharedLoopWatts provided, defaults as follows:
  
         - **Shared boiler w/ baseboard**: 220 kWh/yr
         - **Shared boiler w/ water loop heat pump**: 265 kWh/yr
         - **Shared boiler w/ fan coil**: 438 kWh/yr

  .. [#] FanCoilWatts only used if boiler connected to fan coil and SharedLoopWatts provided.

Stove
~~~~~

If a stove is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =====  ===========  ========  =========  ===================
  Element                                             Type    Units  Constraints  Required  Default    Notes
  ==================================================  ======  =====  ===========  ========  =========  ===================
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac   0 - 1        No        See [#]_   Efficiency
  ``extension/FanPowerWatts``                         double  W      >= 0         No        40         Fan power
  ==================================================  ======  =====  ===========  ========  =========  ===================

  .. [#] Defaulted to 1.0 if FuelType is "electricity", 0.60 if FuelType is "wood", 0.78 if FuelType is "wood pellets", otherwise 0.81.

Portable/Fixed Heater
~~~~~~~~~~~~~~~~~~~~~

If a portable heater or fixed heater is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =====  ===========  ========  =========  ===================
  Element                                             Type    Units  Constraints  Required  Default    Notes
  ==================================================  ======  =====  ===========  ========  =========  ===================
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac   0 - 1        No        See [#]_   Efficiency
  ``extension/FanPowerWatts``                         double  W      >= 0         No        0          Fan power
  ==================================================  ======  =====  ===========  ========  =========  ===================

  .. [#] Defaulted to 1.0 if FuelType is "electricity", 0.60 if FuelType is "wood", 0.78 if FuelType is "wood pellets", otherwise 0.81.

Fireplace
~~~~~~~~~

If a fireplace is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =====  ===========  ========  =========  ===================
  Element                                             Type    Units  Constraints  Required  Default    Notes
  ==================================================  ======  =====  ===========  ========  =========  ===================
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac   0 - 1        No        See [#]_   Efficiency
  ``extension/FanPowerWatts``                         double  W      >= 0         No        0          Fan power
  ==================================================  ======  =====  ===========  ========  =========  ===================

  .. [#] Defaulted to 1.0 if FuelType is "electricity", 0.60 if FuelType is "wood", 0.78 if FuelType is "wood pellets", otherwise 0.81.

.. _hvac_cooling:

HPXML Cooling Systems
*********************

Each cooling system (other than a heat pump) is entered as an ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem``.

  ==========================  ========  ======  ===========  ========  =======  ===============================
  Element                     Type      Units   Constraints  Required  Default  Notes
  ==========================  ========  ======  ===========  ========  =======  ===============================
  ``SystemIdentifier``        id                             Yes                Unique identifier
  ``CoolingSystemType``       string            See [#]_     Yes                Type of cooling system
  ``CoolingSystemFuel``       string            See [#]_     Yes                Fuel type
  ``FractionCoolLoadServed``  double    frac    0 - 1 [#]_   Yes                Fraction of cooling load served
  ==========================  ========  ======  ===========  ========  =======  ===============================

  .. [#] CoolingSystemType choices are "central air conditioner", "room air conditioner", "evaporative cooler", "mini-split", "chiller", "cooling tower", or "packaged terminal air conditioner".
  .. [#] CoolingSystemFuel only choice is "electricity".
  .. [#] The sum of all ``FractionCoolLoadServed`` (across both CoolingSystems and HeatPumps) must be less than or equal to 1.

Central Air Conditioner
~~~~~~~~~~~~~~~~~~~~~~~

If a central air conditioner is specified, additional information is entered in ``CoolingSystem``.

  ====================================================================  =================  ===========  ===============  ========  =========  ================================================
  Element                                                               Type               Units        Constraints      Required  Default    Notes
  ====================================================================  =================  ===========  ===============  ========  =========  ================================================
  ``DistributionSystem``                                                idref              See [#]_     Yes                                   ID of attached distribution system
  ``AnnualCoolingEfficiency[Units="SEER"]/Value`` or ``YearInstalled``  double or integer  Btu/Wh or #  > 0 or > 1600    Yes       See [#]_   Rated efficiency or Year installed
  ``CoolingCapacity``                                                   double             Btu/hr       >= 0             No        autosized  Cooling output capacity
  ``SensibleHeatFraction``                                              double             frac         0 - 1            No                   Sensible heat fraction
  ``CompressorType``                                                    string                          See [#]_         No        See [#]_   Type of compressor
  ``extension/FanPowerWattsPerCFM``                                     double             W/cfm        >= 0             No        See [#]_   Fan efficiency at maximum airflow rate [#]_
  ``extension/AirflowDefectRatio``                                      double             frac         > -1             No        0.0        Deviation between design/installed airflows [#]_
  ``extension/ChargeDefectRatio``                                       double             frac         > -1             No        0.0        Deviation between design/installed charges [#]_
  ====================================================================  =================  ===========  ===============  ========  =========  ================================================

  .. [#] HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] If AnnualCoolingEfficiency[Units="SEER"]/Value not provided, defaults to SEER from the lookup table that can be found at ``HPXMLtoOpenStudio\resources\lu_hvac_equipment_efficiency.csv`` based on YearInstalled.
  .. [#] CompressorType choices are "single stage", "two stage", or "variable speed".
  .. [#] If CompressorType not provided, defaults to "single stage" if SEER <= 15, else "two stage" if SEER <= 21, else "variable speed".
  .. [#] If FanPowerWattsPerCFM not provided, defaults to using attached furnace W/cfm if available, else 0.5 W/cfm if SEER <= 13.5, else 0.375 W/cfm.
  .. [#] If there is a heating system attached to the DistributionSystem, the heating and cooling systems cannot have different values for FanPowerWattsPerCFM.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.
  .. [#] ChargeDefectRatio is defined as (InstalledCharge - DesignCharge) / DesignCharge; a value of zero means no refrigerant charge defect.
         A non-zero charge defect should typically only be applied for systems that are pre-charged on site.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

Room Air Conditioner
~~~~~~~~~~~~~~~~~~~~

If a room air conditioner is specified, additional information is entered in ``CoolingSystem``.

  ===================================================================================  =================  ===========  ===============  ========  =========  ==================================
  Element                                                                              Type               Units        Constraints      Required  Default    Notes
  ===================================================================================  =================  ===========  ===============  ========  =========  ==================================
  ``AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value`` or ``YearInstalled``  double or integer  Btu/Wh or #  > 0 or > 1600    Yes       See [#]_   Rated efficiency or Year installed
  ``CoolingCapacity``                                                                  double             Btu/hr       >= 0             No        autosized  Cooling output capacity
  ``SensibleHeatFraction``                                                             double             frac         0 - 1            No                   Sensible heat fraction
  ===================================================================================  =================  ===========  ===============  ========  =========  ==================================

  .. [#] If AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value not provided, defaults to EER from the lookup table that can be found at ``HPXMLtoOpenStudio\resources\lu_hvac_equipment_efficiency.csv`` based on YearInstalled.

Packaged Terminal Air Conditioner
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a PTAC is specified, additional information is entered in ``CoolingSystem``.

  ===================================================================  =================  ===========  ===============  ========  =========  ==================================
  Element                                                              Type               Units        Constraints      Required  Default    Notes
  ===================================================================  =================  ===========  ===============  ========  =========  ==================================
  ``AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value``       integer or double  # or Btu/Wh  > 1600 or > 0    Yes                  Rated efficiency
  ``CoolingCapacity``                                                  double             Btu/hr       >= 0             No        autosized  Cooling output capacity
  ``SensibleHeatFraction``                                             double             frac         0 - 1            No                   Sensible heat fraction
  ===================================================================  =================  ===========  ===============  ========  =========  ==================================

Evaporative Cooler
~~~~~~~~~~~~~~~~~~

If an evaporative cooler is specified, additional information is entered in ``CoolingSystem``.

  =================================  ========  ======  ===========  ========  =========  ==================================
  Element                            Type      Units   Constraints  Required  Default    Notes
  =================================  ========  ======  ===========  ========  =========  ==================================
  ``DistributionSystem``             idref             See [#]_     No                   ID of attached distribution system
  ``CoolingCapacity``                double    Btu/hr  >= 0         No        autosized  Cooling output capacity
  =================================  ========  ======  ===========  ========  =========  ==================================

  .. [#] If provided, HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.

Mini-Split
~~~~~~~~~~

If a mini-split is specified, additional information is entered in ``CoolingSystem``.

  ===============================================  ========  ======  ===========  ========  =========  ===============================================
  Element                                          Type      Units   Constraints  Required  Default    Notes
  ===============================================  ========  ======  ===========  ========  =========  ===============================================
  ``DistributionSystem``                           idref             See [#]_     No                   ID of attached distribution system
  ``AnnualCoolingEfficiency[Units="SEER"]/Value``  double    Btu/Wh  > 0          Yes                  Rated cooling efficiency
  ``CoolingCapacity``                              double    Btu/hr  >= 0         No        autosized  Cooling output capacity
  ``SensibleHeatFraction``                         double    frac    0 - 1        No                   Sensible heat fraction
  ``extension/FanPowerWattsPerCFM``                double    W/cfm   >= 0         No        See [#]_   Fan efficiency at maximum airflow rate
  ``extension/AirflowDefectRatio``                 double    frac    > -1         No        0.0        Deviation between design/installed airflows [#]_
  ``extension/ChargeDefectRatio``                  double    frac    > -1         No        0.0        Deviation between design/installed charges [#]_
  ===============================================  ========  ======  ===========  ========  =========  ===============================================

  .. [#] If provided, HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] FanPowerWattsPerCFM defaults to 0.07 W/cfm for ductless systems and 0.18 W/cfm for ducted systems.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         A non-zero airflow defect should typically only be applied for systems attached to ducts.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.
  .. [#] ChargeDefectRatio is defined as (InstalledCharge - DesignCharge) / DesignCharge; a value of zero means no refrigerant charge defect.
         A non-zero charge defect should typically only be applied for systems that are pre-charged on site.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

.. _hvac_cooling_chiller:

Chiller
~~~~~~~

If a chiller is specified, additional information is entered in ``CoolingSystem``.

  ==========================================================================  ========  ======  ===========  ========  =========  =========================================
  Element                                                                     Type      Units   Constraints  Required  Default    Notes
  ==========================================================================  ========  ======  ===========  ========  =========  =========================================
  ``IsSharedSystem``                                                          boolean           true         Yes                  Whether it serves multiple dwelling units
  ``DistributionSystem``                                                      idref             See [#]_     Yes                  ID of attached distribution system
  ``NumberofUnitsServed``                                                     integer           > 1          Yes                  Number of dwelling units served
  ``CoolingCapacity``                                                         double    Btu/hr  >= 0         Yes                  Total cooling output capacity
  ``AnnualCoolingEfficiency[Units="kW/ton"]/Value``                           double    kW/ton  > 0          Yes                  Rated efficiency
  ``extension/SharedLoopWatts``                                               double    W       >= 0         Yes                  Pumping and fan power serving the system
  ``extension/FanCoilWatts``                                                  double    W       >= 0         See [#]_             Fan coil power
  ==========================================================================  ========  ======  ===========  ========  =========  =========================================

  .. [#] HVACDistribution type must be HydronicDistribution (type: "radiator", "baseboard", "radiant floor", "radiant ceiling", or "water loop") or AirDistribution (type: "fan coil").
         If the chiller has "water loop" distribution, a :ref:`hvac_heatpump_wlhp` must also be specified.
  .. [#] FanCoilWatts only required if chiller connected to fan coil.
  
.. note::

  Chillers are modeled as central air conditioners with a SEER equivalent using the equation from `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

.. _hvac_cooling_tower:

Cooling Tower
~~~~~~~~~~~~~

If a cooling tower is specified, additional information is entered in ``CoolingSystem``.

  ==========================================================================  ========  ======  ===========  ========  =========  =========================================
  Element                                                                     Type      Units   Constraints  Required  Default    Notes
  ==========================================================================  ========  ======  ===========  ========  =========  =========================================
  ``IsSharedSystem``                                                          boolean           true         Yes                  Whether it serves multiple dwelling units
  ``DistributionSystem``                                                      idref             See [#]_     Yes                  ID of attached distribution system
  ``NumberofUnitsServed``                                                     integer           > 1          Yes                  Number of dwelling units served
  ``extension/SharedLoopWatts``                                               double    W       >= 0         Yes                  Pumping and fan power serving the system
  ==========================================================================  ========  ======  ===========  ========  =========  =========================================

  .. [#] HVACDistribution type must be HydronicDistribution (type: "water loop").
         A :ref:`hvac_heatpump_wlhp` must also be specified.
  
.. note::

  Cooling towers w/ water loop heat pumps are modeled as central air conditioners with a SEER equivalent using the equation from `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

.. _hvac_heatpump:

HPXML Heat Pumps
****************

Each heat pump is entered as an ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/HeatPump``.

  =================================  ========  ======  ===========  ========  =========  ===============================================
  Element                            Type      Units   Constraints  Required  Default    Notes
  =================================  ========  ======  ===========  ========  =========  ===============================================
  ``SystemIdentifier``               id                             Yes                  Unique identifier
  ``HeatPumpType``                   string            See [#]_     Yes                  Type of heat pump
  ``HeatPumpFuel``                   string            See [#]_     Yes                  Fuel type
  ``BackupType``                     string            See [#]_     No        <none>     Type of backup heating
  =================================  ========  ======  ===========  ========  =========  ===============================================

  .. [#] HeatPumpType choices are "air-to-air", "mini-split", "ground-to-air", "water-loop-to-air", or "packaged terminal heat pump".
  .. [#] HeatPumpFuel only choice is "electricity".
  .. [#] BackupType choices are "integrated" or "separate".
         Use "integrated" if the heat pump's distribution system and blower fan power applies to the backup heating (e.g., built-in electric strip heat or an integrated backup furnace, i.e., a dual-fuel heat pump).
         Use "separate" if the backup system has its own distribution system (e.g., electric baseboard or a boiler).

If a backup type of "integrated" is provided, additional information is entered in ``HeatPump``.

  ========================================================================  ========  ======  ===========  ========  =========  ==========================================
  Element                                                                   Type      Units   Constraints  Required  Default    Notes
  ========================================================================  ========  ======  ===========  ========  =========  ==========================================
  ``BackupSystemFuel``                                                      string            See [#]_     Yes                  Integrated backup heating fuel type
  ``BackupAnnualHeatingEfficiency[Units="Percent" or Units="AFUE"]/Value``  double    frac    0 - 1        Yes                  Integrated backup heating efficiency
  ``BackupHeatingCapacity``                                                 double    Btu/hr  >= 0         No        autosized  Integrated backup heating output capacity
  ``BackupHeatingSwitchoverTemperature``                                    double    F                    No        <none>     Integrated backup heating switchover temperature [#]_
  ========================================================================  ========  ======  ===========  ========  =========  ==========================================

  .. [#] BackupSystemFuel choices are "electricity", "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "wood", or "wood pellets".
  .. [#] Provide BackupHeatingSwitchoverTemperature for a situation in which there is a discrete outdoor temperature when the heat pump stops operating and the backup heating system starts operating.
         If not provided, the backup heating system will operate as needed for hours when the heat pump has insufficient capacity.

If a backup type of "separate" is provided, additional information is entered in ``HeatPump``.

  ======================================  ========  ======  ===========  ========  =========  ==========================================
  Element                                 Type      Units   Constraints  Required  Default    Notes
  ======================================  ========  ======  ===========  ========  =========  ==========================================
  ``BackupSystem``                        idref             See [#]_     Yes                  ID of separate backup heating system 
  ``BackupHeatingSwitchoverTemperature``  double    F                    No        <none>     Separate backup heating system switchover temperature [#]_
  ======================================  ========  ======  ===========  ========  =========  ==========================================
  
  .. [#] HeatingSystem must be of type ``ElectricResistance``, ``WallFurnace``, ``FloorFurnace``, ``Boiler``, ``Stove``, ``PortableHeater``, ``FixedHeater``, or ``Fireplace``.
  .. [#] Provide BackupHeatingSwitchoverTemperature for a situation in which there is a discrete outdoor temperature when the heat pump stops operating and the backup heating system starts operating.
         If not provided, the backup heating system will operate as needed for hours when the heat pump has insufficient capacity.

  .. note::

    Due to how the separate backup heating system is modeled in EnergyPlus, there are a few restrictions:

    - The conditioned space cannot be partially heated (i.e., the sum of all ``FractionHeatLoadServed`` must be 1).
    - There cannot be multiple backup heating systems.

Air-to-Air Heat Pump
~~~~~~~~~~~~~~~~~~~~

If an air-to-air heat pump is specified, additional information is entered in ``HeatPump``.

  ====================================================================  =================  ===========  ========================  ========  =========  =================================================
  Element                                                               Type               Units        Constraints               Required  Default    Notes
  ====================================================================  =================  ===========  ========================  ========  =========  =================================================
  ``DistributionSystem``                                                idref                           See [#]_                  Yes                  ID of attached distribution system
  ``CompressorType``                                                    string                          See [#]_                  No        See [#]_   Type of compressor
  ``HeatingCapacity``                                                   double             Btu/hr       >= 0                      No        autosized  Heating output capacity (excluding any backup heating)
  ``HeatingCapacity17F``                                                double             Btu/hr       >= 0, <= HeatingCapacity  No                   Heating output capacity at 17F, if available
  ``CoolingCapacity``                                                   double             Btu/hr       >= 0                      No        autosized  Cooling output capacity
  ``CoolingSensibleHeatFraction``                                       double             frac         0 - 1                     No                   Sensible heat fraction
  ``FractionHeatLoadServed``                                            double             frac         0 - 1 [#]_                Yes                  Fraction of heating load served
  ``FractionCoolLoadServed``                                            double             frac         0 - 1 [#]_                Yes                  Fraction of cooling load served
  ``AnnualCoolingEfficiency[Units="SEER"]/Value`` or ``YearInstalled``  double or integer  Btu/Wh or #  > 0 or > 1600             Yes       See [#]_   Rated cooling efficiency or Year installed
  ``AnnualHeatingEfficiency[Units="HSPF"]/Value`` or ``YearInstalled``  double or integer  Btu/Wh or #  > 0 or > 1600             Yes       See [#]_   Rated heating efficiency or Year installed
  ``extension/FanPowerWattsPerCFM``                                     double             W/cfm        >= 0                      No        See [#]_   Fan efficiency at maximum airflow rate
  ``extension/AirflowDefectRatio``                                      double             frac         > -1                      No        0.0        Deviation between design/installed airflows [#]_
  ``extension/ChargeDefectRatio``                                       double             frac         > -1                      No        0.0        Deviation between design/installed charges [#]_
  ====================================================================  =================  ===========  ========================  ========  =========  =================================================

  .. [#] HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] CompressorType choices are "single stage", "two stage", or "variable speed".
  .. [#] If CompressorType not provided, defaults to "single stage" if SEER <= 15, else "two stage" if SEER <= 21, else "variable speed".
  .. [#] The sum of all ``FractionHeatLoadServed`` (across both HeatingSystems and HeatPumps) must be less than or equal to 1.
  .. [#] The sum of all ``FractionCoolLoadServed`` (across both CoolingSystems and HeatPumps) must be less than or equal to 1.
  .. [#] If AnnualCoolingEfficiency[Units="SEER"]/Value not provided, defaults to SEER from the lookup table that can be found at ``HPXMLtoOpenStudio\resources\lu_hvac_equipment_efficiency.csv`` based on YearInstalled.
  .. [#] If AnnualHeatingEfficiency[Units="HSPF"]/Value not provided, defaults to HSPF from the lookup table that can be found at ``HPXMLtoOpenStudio\resources\lu_hvac_equipment_efficiency.csv`` based on YearInstalled.
  .. [#] If FanPowerWattsPerCFM not provided, defaulted to 0.5 W/cfm if HSPF <= 8.75, else 0.375 W/cfm.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.
  .. [#] ChargeDefectRatio is defined as (InstalledCharge - DesignCharge) / DesignCharge; a value of zero means no refrigerant charge defect.
         A non-zero charge defect should typically only be applied for systems that are pre-charged on site.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

Mini-Split Heat Pump
~~~~~~~~~~~~~~~~~~~~

If a mini-split heat pump is specified, additional information is entered in ``HeatPump``.

  ===============================================  ========  ======  ========================  ========  =========  ==============================================
  Element                                          Type      Units   Constraints               Required  Default    Notes
  ===============================================  ========  ======  ========================  ========  =========  ==============================================
  ``DistributionSystem``                           idref             See [#]_                  No                   ID of attached distribution system, if present
  ``HeatingCapacity``                              double    Btu/hr  >= 0                      No        autosized  Heating output capacity (excluding any backup heating)
  ``HeatingCapacity17F``                           double    Btu/hr  >= 0, <= HeatingCapacity  No                   Heating output capacity at 17F, if available
  ``CoolingCapacity``                              double    Btu/hr  >= 0                      No        autosized  Cooling output capacity
  ``CoolingSensibleHeatFraction``                  double    frac    0 - 1                     No                   Sensible heat fraction
  ``FractionHeatLoadServed``                       double    frac    0 - 1 [#]_                Yes                  Fraction of heating load served
  ``FractionCoolLoadServed``                       double    frac    0 - 1 [#]_                Yes                  Fraction of cooling load served
  ``AnnualCoolingEfficiency[Units="SEER"]/Value``  double    Btu/Wh  > 0                       Yes                  Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="HSPF"]/Value``  double    Btu/Wh  > 0                       Yes                  Rated heating efficiency
  ``extension/FanPowerWattsPerCFM``                double    W/cfm   >= 0                      No        See [#]_   Fan efficiency at maximum airflow rate
  ``extension/AirflowDefectRatio``                 double    frac    > -1                      No        0.0        Deviation between design/installed airflows [#]_
  ``extension/ChargeDefectRatio``                  double    frac    > -1                      No        0.0        Deviation between design/installed charges [#]_
  ===============================================  ========  ======  ========================  ========  =========  ==============================================

  .. [#] If provided, HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across both HeatingSystems and HeatPumps) must be less than or equal to 1.
  .. [#] The sum of all ``FractionCoolLoadServed`` (across both CoolingSystems and HeatPumps) must be less than or equal to 1.
  .. [#] FanPowerWattsPerCFM defaults to 0.07 W/cfm for ductless systems and 0.18 W/cfm for ducted systems.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         A non-zero airflow defect should typically only be applied for systems attached to ducts.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.
  .. [#] ChargeDefectRatio is defined as (InstalledCharge - DesignCharge) / DesignCharge; a value of zero means no refrigerant charge defect.
         A non-zero charge defect should typically only be applied for systems that are pre-charged on site.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

Packaged Terminal Heat Pump
~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a packaged terminal heat pump is specified, additional information is entered in ``HeatPump``.

  ===============================================================  ========  ======  ===========  ========  =========  ==============================================
  Element                                                          Type      Units   Constraints  Required  Default    Notes
  ===============================================================  ========  ======  ===========  ========  =========  ==============================================
  ``HeatingCapacity``                                              double    Btu/hr  >= 0         No        autosized  Heating output capacity (excluding any backup heating)
  ``CoolingCapacity``                                              double    Btu/hr  >= 0         No        autosized  Cooling output capacity
  ``CoolingSensibleHeatFraction``                                  double    frac    0 - 1        No                   Sensible heat fraction
  ``FractionHeatLoadServed``                                       double    frac    0 - 1 [#]_   Yes                  Fraction of heating load served
  ``FractionCoolLoadServed``                                       double    frac    0 - 1 [#]_   Yes                  Fraction of cooling load served
  ``AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value``   double    Btu/Wh  > 0          Yes                  Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="COP"]/Value``                   double    Btu/Wh  > 0          Yes                  Rated heating efficiency
  ===============================================================  ========  ======  ===========  ========  =========  ==============================================

  .. [#] The sum of all ``FractionHeatLoadServed`` (across both HeatingSystems and HeatPumps) must be less than or equal to 1.
  .. [#] The sum of all ``FractionCoolLoadServed`` (across both CoolingSystems and HeatPumps) must be less than or equal to 1.

Ground-to-Air Heat Pump
~~~~~~~~~~~~~~~~~~~~~~~

If a ground-to-air heat pump is specified, additional information is entered in ``HeatPump``.

  ===============================================  ========  ======  ===========  ========  =========  ==============================================
  Element                                          Type      Units   Constraints  Required  Default    Notes
  ===============================================  ========  ======  ===========  ========  =========  ==============================================
  ``IsSharedSystem``                               boolean                        No        false      Whether it has a shared hydronic circulation loop [#]_
  ``DistributionSystem``                           idref             See [#]_     Yes                  ID of attached distribution system
  ``HeatingCapacity``                              double    Btu/hr  >= 0         No        autosized  Heating output capacity (excluding any backup heating)
  ``CoolingCapacity``                              double    Btu/hr  >= 0         No        autosized  Cooling output capacity
  ``CoolingSensibleHeatFraction``                  double    frac    0 - 1        No                   Sensible heat fraction
  ``FractionHeatLoadServed``                       double    frac    0 - 1 [#]_   Yes                  Fraction of heating load served
  ``FractionCoolLoadServed``                       double    frac    0 - 1 [#]_   Yes                  Fraction of cooling load served
  ``AnnualCoolingEfficiency[Units="EER"]/Value``   double    Btu/Wh  > 0          Yes                  Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="COP"]/Value``   double    W/W     > 0          Yes                  Rated heating efficiency
  ``NumberofUnitsServed``                          integer           > 0          See [#]_             Number of dwelling units served
  ``extension/PumpPowerWattsPerTon``               double    W/ton   >= 0         No        See [#]_   Pump power [#]_
  ``extension/SharedLoopWatts``                    double    W       >= 0         See [#]_             Shared pump power [#]_
  ``extension/FanPowerWattsPerCFM``                double    W/cfm   >= 0         No        See [#]_   Fan efficiency at maximum airflow rate
  ``extension/AirflowDefectRatio``                 double    frac    > -1         No        0.0        Deviation between design/installed airflows [#]_
  ``extension/ChargeDefectRatio``                  double    frac    > -1         No        0.0        Deviation between design/installed charges [#]_
  ===============================================  ========  ======  ===========  ========  =========  ==============================================

  .. [#] IsSharedSystem should be true if the SFA/MF building has multiple ground source heat pumps connected to a shared hydronic circulation loop.
  .. [#] HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across both HeatingSystems and HeatPumps) must be less than or equal to 1.
  .. [#] The sum of all ``FractionCoolLoadServed`` (across both CoolingSystems and HeatPumps) must be less than or equal to 1.
  .. [#] NumberofUnitsServed only required if IsSharedSystem is true, in which case it must be > 1.
  .. [#] If PumpPowerWattsPerTon not provided, defaults to 30 W/ton per `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_ for a closed loop system.
  .. [#] Pump power is calculated using PumpPowerWattsPerTon and the cooling capacity in tons, unless the system only provides heating, in which case the heating capacity in tons is used instead.
         Any pump power that is shared by multiple dwelling units should be included in SharedLoopWatts, *not* PumpPowerWattsPerTon, so that shared loop pump power attributed to the dwelling unit is calculated.
  .. [#] SharedLoopWatts only required if IsSharedSystem is true.
  .. [#] Shared loop pump power attributed to the dwelling unit is calculated as SharedLoopWatts / NumberofUnitsServed.
  .. [#] If FanPowerWattsPerCFM not provided, defaulted to 0.5 W/cfm if COP <= 8.75/3.2, else 0.375 W/cfm.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.
  .. [#] ChargeDefectRatio is defined as (InstalledCharge - DesignCharge) / DesignCharge; a value of zero means no refrigerant charge defect.
         A non-zero charge defect should typically only be applied for systems that are pre-charged on site.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

.. _hvac_heatpump_wlhp:

Water-Loop-to-Air Heat Pump
~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a water-loop-to-air heat pump is specified, additional information is entered in ``HeatPump``.

  ===============================================  ========  ======  ===========  ========  =========  ==============================================
  Element                                          Type      Units   Constraints  Required  Default    Notes
  ===============================================  ========  ======  ===========  ========  =========  ==============================================
  ``DistributionSystem``                           idref             See [#]_     Yes                  ID of attached distribution system
  ``HeatingCapacity``                              double    Btu/hr  > 0          No        autosized  Heating output capacity
  ``CoolingCapacity``                              double    Btu/hr  > 0          See [#]_             Cooling output capacity
  ``AnnualCoolingEfficiency[Units="EER"]/Value``   double    Btu/Wh  > 0          See [#]_             Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="COP"]/Value``   double    W/W     > 0          See [#]_             Rated heating efficiency
  ===============================================  ========  ======  ===========  ========  =========  ==============================================

  .. [#] HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] CoolingCapacity required if there is a shared chiller or cooling tower with water loop distribution.
  .. [#] AnnualCoolingEfficiency required if there is a shared chiller or cooling tower with water loop distribution.
  .. [#] AnnualHeatingEfficiency required if there is a shared boiler with water loop distribution.

.. note::

  If a water loop heat pump is specified, there must be at least one shared heating system (i.e., :ref:`hvac_heating_boiler`) and/or one shared cooling system (i.e., :ref:`hvac_cooling_chiller` or :ref:`hvac_cooling_tower`) specified with water loop distribution.

.. _hvac_control:

HPXML HVAC Control
******************

If any HVAC systems are specified, a single thermostat is entered as a ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACControl``.

  =======================================================  ========  =====  ===========  ========  =========  ========================================
  Element                                                  Type      Units  Constraints  Required  Default    Notes
  =======================================================  ========  =====  ===========  ========  =========  ========================================
  ``SystemIdentifier``                                     id                            Yes                  Unique identifier
  ``HeatingSeason``                                        element                       No        See [#]_   Heating season        
  ``CoolingSeason``                                        element                       No        See [#]_   Cooling season
  ``extension/CeilingFanSetpointTempCoolingSeasonOffset``  double    F      >= 0         No        0          Cooling setpoint temperature offset [#]_
  =======================================================  ========  =====  ===========  ========  =========  ========================================

  .. [#] If HeatingSeason not provided, defaults to year-round.
  .. [#] If CoolingSeason not provided, defaults to year-round.
  .. [#] CeilingFanSetpointTempCoolingSeasonOffset should only be used if there are sufficient ceiling fans present to warrant a reduced cooling setpoint.

If a heating and/or cooling season is defined, additional information is entered in ``HVACControl/HeatingSeason`` and/or ``HVACControl/CoolingSeason``.

  ===================  ========  =====  ===========  ========  =======  ===========
  Element              Type      Units  Constraints  Required  Default  Description
  ===================  ========  =====  ===========  ========  =======  ===========
  ``BeginMonth``       integer          1 - 12       Yes                Begin month
  ``BeginDayOfMonth``  integer          1 - 31       Yes                Begin day
  ``EndMonth``         integer          1 - 12       Yes                End month
  ``EndDayOfMonth``    integer          1 - 31       Yes                End day
  ===================  ========  =====  ===========  ========  =======  ===========

Heating and cooling seasons, when combined, must span the entire year.

Thermostat setpoints are additionally entered using either simple inputs or detailed inputs.

Simple Inputs
~~~~~~~~~~~~~

To define simple thermostat setpoints, additional information is entered in ``HVACControl``.

  =============================  ========  =======  ===========  ========  =========  ============================
  Element                        Type      Units    Constraints  Required  Default    Notes
  =============================  ========  =======  ===========  ========  =========  ============================
  ``SetpointTempHeatingSeason``  double    F                     See [#]_             Heating setpoint temperature
  ``SetpointTempCoolingSeason``  double    F                     See [#]_             Cooling setpoint temperature
  =============================  ========  =======  ===========  ========  =========  ============================

  .. [#] SetpointTempHeatingSeason only required if there is heating equipment (i.e., sum of all ``FractionHeatLoadServed`` is greater than 0).
  .. [#] SetpointTempCoolingSeason only required if there is cooling equipment (i.e., sum of all ``FractionCoolLoadServed`` is greater than 0).

If there is a heating temperature setback, additional information is entered in ``HVACControl``.

  =====================================  ========  ========  ===========  ========  =========  =========================================
  Element                                Type      Units     Constraints  Required  Default    Notes
  =====================================  ========  ========  ===========  ========  =========  =========================================
  ``SetbackTempHeatingSeason``           double    F                      Yes                  Heating setback temperature
  ``TotalSetbackHoursperWeekHeating``    integer   hrs/week  > 0          Yes                  Hours/week of heating temperature setback [#]_
  ``extension/SetbackStartHourHeating``  integer             0 - 23       No        23 (11pm)  Daily setback start hour
  =====================================  ========  ========  ===========  ========  =========  =========================================

  .. [#] TotalSetbackHoursperWeekHeating is converted to hrs/day and modeled as a temperature setback every day starting at SetbackStartHourHeating.

If there is a cooling temperature setup, additional information is entered in ``HVACControl``.

  =====================================  ========  ========  ===========  ========  =========  =========================================
  Element                                Type      Units     Constraints  Required  Default    Notes
  =====================================  ========  ========  ===========  ========  =========  =========================================
  ``SetupTempCoolingSeason``             double    F                      Yes                  Cooling setup temperature
  ``TotalSetupHoursperWeekCooling``      integer   hrs/week  > 0          Yes                  Hours/week of cooling temperature setup [#]_
  ``extension/SetupStartHourCooling``    integer             0 - 23       No        9 (9am)    Daily setup start hour
  =====================================  ========  ========  ===========  ========  =========  =========================================

  .. [#] TotalSetupHoursperWeekCooling is converted to hrs/day and modeled as a temperature setup every day starting at SetupStartHourCooling.

Detailed Inputs
~~~~~~~~~~~~~~~

To define detailed thermostat setpoints, additional information is entered in ``HVACControl``.

  ===============================================  =====  =======  ===========  ========  =========  ============================================
  Element                                          Type   Units    Constraints  Required  Default    Notes
  ===============================================  =====  =======  ===========  ========  =========  ============================================
  ``extension/WeekdaySetpointTempsHeatingSeason``  array  F                     See [#]_             24 comma-separated weekday heating setpoints
  ``extension/WeekendSetpointTempsHeatingSeason``  array  F                     See [#]_             24 comma-separated weekend heating setpoints
  ``extension/WeekdaySetpointTempsCoolingSeason``  array  F                     See [#]_             24 comma-separated weekday cooling setpoints
  ``extension/WeekendSetpointTempsCoolingSeason``  array  F                     See [#]_             24 comma-separated weekend cooling setpoints
  ===============================================  =====  =======  ===========  ========  =========  ============================================

  .. [#] WeekdaySetpointTempsHeatingSeason only required if there is heating equipment (i.e., sum of all ``FractionHeatLoadServed`` is greater than 0).
  .. [#] WeekendSetpointTempsHeatingSeason only required if there is heating equipment (i.e., sum of all ``FractionHeatLoadServed`` is greater than 0).
  .. [#] WeekdaySetpointTempsCoolingSeason only required if there is cooling equipment (i.e., sum of all ``FractionCoolLoadServed`` is greater than 0).
  .. [#] WeekendSetpointTempsCoolingSeason only required if there is cooling equipment (i.e., sum of all ``FractionCoolLoadServed`` is greater than 0).

HPXML HVAC Distribution
***********************

Each separate HVAC distribution system is entered as a ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACDistribution``.

  ==============================  =======  =======  ===========  ========  =========  =============================
  Element                         Type     Units    Constraints  Required  Default    Notes
  ==============================  =======  =======  ===========  ========  =========  =============================
  ``SystemIdentifier``            id                             Yes                  Unique identifier
  ``DistributionSystemType``      element           1 [#]_       Yes                  Type of distribution system
  ``ConditionedFloorAreaServed``  double   ft2      > 0          See [#]_             Conditioned floor area served
  ==============================  =======  =======  ===========  ========  =========  =============================

  .. [#] DistributionSystemType child element choices are ``AirDistribution``, ``HydronicDistribution``, or ``Other=DSE``.
  .. [#] ConditionedFloorAreaServed required only when DistributionSystemType is AirDistribution and ``AirDistribution/Ducts`` are present.

.. note::
  
  There should be at most one heating system and one cooling system attached to a distribution system.
  See :ref:`hvac_heating`, :ref:`hvac_cooling`, and :ref:`hvac_heatpump` for information on which DistributionSystemType is allowed for which HVAC system.
  Also note that some HVAC systems (e.g., room air conditioners) are not allowed to be attached to a distribution system.

.. _air_distribution:

Air Distribution
~~~~~~~~~~~~~~~~

To define an air distribution system, additional information is entered in ``HVACDistribution/DistributionSystemType/AirDistribution``.

  =============================================  =======  =======  ===========  ========  =========  ==========================
  Element                                        Type     Units    Constraints  Required  Default    Notes
  =============================================  =======  =======  ===========  ========  =========  ==========================
  ``AirDistributionType``                        string            See [#]_     Yes                  Type of air distribution
  ``DuctLeakageMeasurement[DuctType="supply"]``  element           1            See [#]_             Supply duct leakage value
  ``DuctLeakageMeasurement[DuctType="return"]``  element           1            See [#]_             Return duct leakage value
  ``Ducts``                                      element           >= 0         No                   Supply/return ducts [#]_
  ``NumberofReturnRegisters``                    integer           >= 0         No        See [#]_   Number of return registers
  =============================================  =======  =======  ===========  ========  =========  ==========================
  
  .. [#] AirDistributionType choices are "regular velocity", "gravity", or "fan coil" and are further restricted based on attached HVAC system type (e.g., only "regular velocity" or "gravity" for a furnace, only "fan coil" for a shared boiler, etc.).
  .. [#] Supply duct leakage required if AirDistributionType is "regular velocity" or "gravity" and optional if AirDistributionType is "fan coil".
  .. [#] Return duct leakage required if AirDistributionType is "regular velocity" or "gravity" and optional if AirDistributionType is "fan coil".
  .. [#] Provide a Ducts element for each supply duct and each return duct.
  .. [#] If NumberofReturnRegisters not provided and ``AirDistribution/Ducts`` are present, defaults to one return register per conditioned floor per `ASHRAE Standard 152 <https://www.energy.gov/eere/buildings/downloads/ashrae-standard-152-spreadsheet>`_, rounded up to the nearest integer if needed.

Additional information is entered in each ``DuctLeakageMeasurement``.

  ================================  =======  =======  ===========  ========  =========  =========================================================
  Element                           Type     Units    Constraints  Required  Default    Notes
  ================================  =======  =======  ===========  ========  =========  =========================================================
  ``DuctLeakage/Units``             string            See [#]_     Yes                  Duct leakage units
  ``DuctLeakage/Value``             double            >= 0 [#]_    Yes                  Duct leakage value [#]_
  ``DuctLeakage/TotalOrToOutside``  string            See [#]_     Yes                  Type of duct leakage (outside conditioned space vs total)
  ================================  =======  =======  ===========  ========  =========  =========================================================
  
  .. [#] Units choices are "CFM25", "CFM50", or "Percent".
  .. [#] Value also must be < 1 if Units is Percent.
  .. [#] If the HVAC system has no return ducts (e.g., a ducted evaporative cooler), use zero for the Value.
  .. [#] TotalOrToOutside only choice is "to outside".

Additional information is entered in each ``Ducts``.

  ===============================================  =======  ============  ================  ========  =========  ======================================
  Element                                          Type     Units         Constraints       Required  Default    Notes
  ===============================================  =======  ============  ================  ========  =========  ======================================
  ``DuctInsulationRValue``                         double   F-ft2-hr/Btu  >= 0              Yes                  R-value of duct insulation [#]_
  ``DuctLocation``                                 string                 See [#]_          No        See [#]_   Duct location
  ``FractionDuctArea`` and/or ``DuctSurfaceArea``  double   frac or ft2   0-1 [#]_ or >= 0  See [#]_  See [#]_   Duct fraction/surface area in location
  ===============================================  =======  ============  ================  ========  =========  ======================================

  .. [#] DuctInsulationRValue should not include air films (i.e., use 0 for an uninsulated duct).
  .. [#] DuctLocation choices are "living space", "basement - conditioned", "basement - unconditioned", "crawlspace - unvented", "crawlspace - vented", "crawlspace - conditioned", "attic - unvented", "attic - vented", "garage", "outside", "exterior wall", "under slab", "roof deck", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If DuctLocation not provided, defaults to the first present space type: "basement - conditioned", "basement - unconditioned", "crawlspace - conditioned", "crawlspace - vented", "crawlspace - unvented", "attic - vented", "attic - unvented", "garage", or "living space".
         If NumberofConditionedFloorsAboveGrade > 1, secondary ducts will be located in "living space".
  .. [#] The sum of all ``[DuctType="supply"]/FractionDuctArea`` and ``[DuctType="return"]/FractionDuctArea`` must each equal to 1.
  .. [#] Either FractionDuctArea or DuctSurfaceArea (or both) are required if DuctLocation is provided.
  .. [#] If DuctSurfaceArea not provided, duct surface areas will be calculated based on FractionDuctArea if provided.
         If FractionDuctArea also not provided, duct surface areas will be calculated based on `ASHRAE Standard 152 <https://www.energy.gov/eere/buildings/downloads/ashrae-standard-152-spreadsheet>`_:

         - **Primary supply ducts**: 0.27 * F_out * ConditionedFloorAreaServed
         - **Secondary supply ducts**: 0.27 * (1 - F_out) * ConditionedFloorAreaServed
         - **Primary return ducts**: b_r * F_out * ConditionedFloorAreaServed
         - **Secondary return ducts**: b_r * (1 - F_out) * ConditionedFloorAreaServed

         where F_out is 1.0 when NumberofConditionedFloorsAboveGrade <= 1 and 0.75 when NumberofConditionedFloorsAboveGrade > 1, and b_r is 0.05 * NumberofReturnRegisters with a maximum value of 0.25.

Hydronic Distribution
~~~~~~~~~~~~~~~~~~~~~

To define a hydronic distribution system, additional information is entered in ``HVACDistribution/DistributionSystemType/HydronicDistribution``.

  ============================  =======  =======  ===========  ========  =========  ====================================
  Element                       Type     Units    Constraints  Required  Default    Notes
  ============================  =======  =======  ===========  ========  =========  ====================================
  ``HydronicDistributionType``  string            See [#]_     Yes                  Type of hydronic distribution system
  ============================  =======  =======  ===========  ========  =========  ====================================

  .. [#] HydronicDistributionType choices are "radiator", "baseboard", "radiant floor", or "radiant ceiling".

Distribution System Efficiency (DSE)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. warning::

  A simplified DSE model is provided for flexibility, but it is **strongly** recommended to use one of the other detailed distribution system types for better accuracy.
  Also note that when specifying a DSE system, its effect is reflected in the :ref:`workflow_outputs` but is **not** reflected in the raw EnergyPlus simulation outputs.

To define a DSE system, additional information is entered in ``HVACDistribution``.

  =============================================  =======  =======  ===========  ========  =========  ===================================================
  Element                                        Type     Units    Constraints  Required  Default    Notes
  =============================================  =======  =======  ===========  ========  =========  ===================================================
  ``AnnualHeatingDistributionSystemEfficiency``  double   frac     0 - 1        Yes                  Seasonal distribution system efficiency for heating
  ``AnnualCoolingDistributionSystemEfficiency``  double   frac     0 - 1        Yes                  Seasonal distribution system efficiency for cooling
  =============================================  =======  =======  ===========  ========  =========  ===================================================

  DSE values can be calculated from `ASHRAE Standard 152 <https://www.energy.gov/eere/buildings/downloads/ashrae-standard-152-spreadsheet>`_.

HPXML Whole Ventilation Fan
***************************

Each mechanical ventilation system that provides ventilation to the whole dwelling unit is entered as a ``/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan``.
If not entered, the simulation will not include mechanical ventilation.

  =============================================================================================  ========  =======  ===========  ========  =========  =========================================
  Element                                                                                        Type      Units    Constraints  Required  Default    Notes
  =============================================================================================  ========  =======  ===========  ========  =========  =========================================
  ``SystemIdentifier``                                                                           id                              Yes                  Unique identifier
  ``UsedForWholeBuildingVentilation``                                                            boolean            true         Yes                  Must be set to true
  ``IsSharedSystem``                                                                             boolean            See [#]_     No        false      Whether it serves multiple dwelling units
  ``FanType``                                                                                    string             See [#]_     Yes                  Type of ventilation system
  ``RatedFlowRate`` or ``TestedFlowRate`` or ``CalculatedFlowRate`` or ``DeliveredVentilation``  double    cfm      >= 0         No        See [#]_   Flow rate [#]_
  ``HoursInOperation``                                                                           double    hrs/day  0 - 24       No        See [#]_   Hours per day of operation
  ``FanPower``                                                                                   double    W        >= 0         No        See [#]_   Fan power
  =============================================================================================  ========  =======  ===========  ========  =========  =========================================

  .. [#] For central fan integrated supply systems, IsSharedSystem must be false.
  .. [#] FanType choices are "energy recovery ventilator", "heat recovery ventilator", "exhaust only", "supply only", "balanced", or "central fan integrated supply".
  .. [#] If flow rate not provided, defaults to the required mechanical ventilation rate per `ASHRAE 62.2-2019 <https://www.techstreet.com/ashrae/standards/ashrae-62-2-2019?product_id=2087691>`_, including adjustments for A) infiltration credit, B) balanced vs imbalanced systems, and C) adiabatic surfaces for SFA/MF buildings.
  .. [#] For a central fan integrated supply system, the flow rate should equal the amount of outdoor air provided to the distribution system.
  .. [#] If HoursInOperation not provided, defaults to 24 (i.e., running continuously) for all system types other than central fan integrated supply (CFIS), and 8.0 (i.e., running intermittently) for CFIS systems.
  .. [#] If FanPower not provided, defaults based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_:
         
         - "energy recovery ventilator", "heat recovery ventilator", or shared system: 1.0 W/cfm
         - "balanced": 0.7 W/cfm
         - "central fan integrated supply": 0.5 W/cfm
         - "exhaust only" or "supply only": 0.35 W/cfm

Exhaust/Supply Only
~~~~~~~~~~~~~~~~~~~

If a supply only or exhaust only system is specified, no additional information is entered.

Balanced
~~~~~~~~

If a balanced system is specified, no additional information is entered.

Heat Recovery Ventilator
~~~~~~~~~~~~~~~~~~~~~~~~

If a heat recovery ventilator system is specified, additional information is entered in ``VentilationFan``.

  ========================================================================  ======  =====  ===========  ========  =======  =======================================
  Element                                                                   Type    Units  Constraints  Required  Default  Notes
  ========================================================================  ======  =====  ===========  ========  =======  =======================================
  ``SensibleRecoveryEfficiency`` or ``AdjustedSensibleRecoveryEfficiency``  double  frac   0 - 1        Yes                (Adjusted) Sensible recovery efficiency
  ========================================================================  ======  =====  ===========  ========  =======  =======================================

Energy Recovery Ventilator
~~~~~~~~~~~~~~~~~~~~~~~~~~

If an energy recovery ventilator system is specified, additional information is entered in ``VentilationFan``.

  ========================================================================  ======  =====  ===========  ========  =======  =======================================
  Element                                                                   Type    Units  Constraints  Required  Default  Notes
  ========================================================================  ======  =====  ===========  ========  =======  =======================================
  ``TotalRecoveryEfficiency`` or ``AdjustedTotalRecoveryEfficiency``        double  frac   0 - 1        Yes                (Adjusted) Total recovery efficiency
  ``SensibleRecoveryEfficiency`` or ``AdjustedSensibleRecoveryEfficiency``  double  frac   0 - 1        Yes                (Adjusted) Sensible recovery efficiency
  ========================================================================  ======  =====  ===========  ========  =======  =======================================

Central Fan Integrated Supply
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a central fan integrated supply system is specified, additional information is entered in ``VentilationFan``.

  ====================================  ======  =====  ===========  ========  =======  ==================================
  Element                               Type    Units  Constraints  Required  Default  Notes
  ====================================  ======  =====  ===========  ========  =======  ==================================
  ``AttachedToHVACDistributionSystem``  idref          See [#]_     Yes                ID of attached distribution system
  ====================================  ======  =====  ===========  ========  =======  ==================================

  .. [#] HVACDistribution type cannot be HydronicDistribution.

Shared System
~~~~~~~~~~~~~

If the specified system is a shared system (i.e., serving multiple dwelling units), additional information is entered in ``VentilationFan``.

  ============================  =======  =====  ===========  ========  =======  ====================================================
  Element                       Type     Units  Constraints  Required  Default  Notes
  ============================  =======  =====  ===========  ========  =======  ====================================================
  ``FractionRecirculation``     double   frac   0 - 1        Yes                Fraction of supply air that is recirculated [#]_
  ``extension/InUnitFlowRate``  double   cfm    >= 0 [#]_    Yes                Flow rate delivered to the dwelling unit
  ``extension/PreHeating``      element         0 - 1        No        <none>   Supply air preconditioned by heating equipment? [#]_
  ``extension/PreCooling``      element         0 - 1        No        <none>   Supply air preconditioned by cooling equipment? [#]_
  ============================  =======  =====  ===========  ========  =======  ====================================================

  .. [#] 1-FractionRecirculation is assumed to be the fraction of supply air that is provided from outside.
         The value must be 0 for exhaust only systems.
  .. [#] InUnitFlowRate must also be < (RatedFlowRate or TestedFlowRate or CalculatedFlowRate or DeliveredVentilation).
  .. [#] PreHeating not allowed for exhaust only systems.
  .. [#] PreCooling not allowed for exhaust only systems.

If pre-heating is specified, additional information is entered in ``extension/PreHeating``.

  ==============================================  =======  =====  ===========  ========  =======  ====================================================================
  Element                                         Type     Units  Constraints  Required  Default  Notes
  ==============================================  =======  =====  ===========  ========  =======  ====================================================================
  ``Fuel``                                        string          See [#]_     Yes                Pre-heating equipment fuel type
  ``AnnualHeatingEfficiency[Units="COP"]/Value``  double   W/W    > 0          Yes                Pre-heating equipment annual COP
  ``FractionVentilationHeatLoadServed``           double   frac   0 - 1        Yes                Fraction of ventilation heating load served by pre-heating equipment
  ==============================================  =======  =====  ===========  ========  =======  ====================================================================

  .. [#] Fuel choices are "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "anthracite coal", "electricity", "wood", or "wood pellets".

If pre-cooling is specified, additional information is entered in ``extension/PreCooling``.

  ==============================================  =======  =====  ===========  ========  =======  ====================================================================
  Element                                         Type     Units  Constraints  Required  Default  Notes
  ==============================================  =======  =====  ===========  ========  =======  ====================================================================
  ``Fuel``                                        string          See [#]_     Yes                Pre-cooling equipment fuel type
  ``AnnualCoolingEfficiency[Units="COP"]/Value``  double   W/W    > 0          Yes                Pre-cooling equipment annual COP
  ``FractionVentilationCoolLoadServed``           double   frac   0 - 1        Yes                Fraction of ventilation cooling load served by pre-cooling equipment
  ==============================================  =======  =====  ===========  ========  =======  ====================================================================

  .. [#] Fuel only choice is "electricity".

HPXML Local Ventilation Fan
***************************

Each kitchen range fan or bathroom fan that provides local ventilation is entered as a ``/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan``.
If not entered, the simulation will not include kitchen/bathroom fans.

  =============================================================================================  =======  =======  ===========  ========  ========  =============================
  Element                                                                                        Type     Units    Constraints  Required  Default   Notes
  =============================================================================================  =======  =======  ===========  ========  ========  =============================
  ``SystemIdentifier``                                                                           id                             Yes                 Unique identifier
  ``UsedForLocalVentilation``                                                                    boolean           true         Yes                 Must be set to true
  ``Quantity``                                                                                   integer           >= 0         No        See [#]_  Number of identical fans
  ``RatedFlowRate`` or ``TestedFlowRate`` or ``CalculatedFlowRate`` or ``DeliveredVentilation``  double   cfm      >= 0         No        See [#]_  Flow rate
  ``HoursInOperation``                                                                           double   hrs/day  0 - 24       No        See [#]_  Hours per day of operation
  ``FanLocation``                                                                                string            See [#]_     Yes                 Location of the fan
  ``FanPower``                                                                                   double   W        >= 0         No        See [#]_  Fan power
  ``extension/StartHour``                                                                        integer           0 - 23       No        See [#]_  Daily start hour of operation
  =============================================================================================  =======  =======  ===========  ========  ========  =============================

  .. [#] If Quantity not provided, defaults to 1 for kitchen fans and NumberofBathrooms for bath fans based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If flow rate not provided, defaults to 100 cfm for kitchen fans and 50 cfm for bath fans based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If HoursInOperation not provided, defaults to 1 based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] FanLocation choices are "kitchen" or "bath".
  .. [#] If FanPower not provided, defaults to 0.3 W/cfm based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If StartHour not provided, defaults to 18 for kitchen fans and 7 for bath fans  based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

HPXML Whole House Fan
*********************

Each whole house fan that provides cooling load reduction is entered as a ``/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan``.
If not entered, the simulation will not include whole house fans.

  =============================================================================================  =======  =======  ===========  ========  ======================  ==========================
  Element                                                                                        Type     Units    Constraints  Required  Default                 Notes
  =============================================================================================  =======  =======  ===========  ========  ======================  ==========================
  ``SystemIdentifier``                                                                           id                             Yes                               Unique identifier
  ``UsedForSeasonalCoolingLoadReduction``                                                        boolean           true         Yes                               Must be set to true
  ``RatedFlowRate`` or ``TestedFlowRate`` or ``CalculatedFlowRate`` or ``DeliveredVentilation``  double   cfm      >= 0         No        ConditionedFloorArea*2  Flow rate
  ``FanPower``                                                                                   double   W        >= 0         No        See [#]_                Fan power
  =============================================================================================  =======  =======  ===========  ========  ======================  ==========================

  .. [#] If FanPower not provided, defaults to 0.1 W/cfm.

.. note::

  The whole house fan is assumed to operate during hours of favorable outdoor conditions and will take priority over operable windows (natural ventilation).

HPXML Water Heating Systems
***************************

Each water heater is entered as a ``/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterHeatingSystem``.
If not entered, the simulation will not include water heating.

  =========================  =======  =======  ===========  ========  ========  ================================================================
  Element                    Type     Units    Constraints  Required  Default   Notes
  =========================  =======  =======  ===========  ========  ========  ================================================================
  ``SystemIdentifier``       id                             Yes                 Unique identifier
  ``IsSharedSystem``         boolean                        No        false     Whether it serves multiple dwelling units or shared laundry room
  ``WaterHeaterType``        string            See [#]_     Yes                 Type of water heater
  ``Location``               string            See [#]_     No        See [#]_  Water heater location
  ``FractionDHWLoadServed``  double   frac     0 - 1 [#]_   Yes                 Fraction of hot water load served [#]_
  ``HotWaterTemperature``    double   F        > 0          No        125       Water heater setpoint
  ``UsesDesuperheater``      boolean                        No        false     Presence of desuperheater?
  ``NumberofUnitsServed``    integer           > 0          See [#]_            Number of dwelling units served directly or indirectly
  =========================  =======  =======  ===========  ========  ========  ================================================================

  .. [#] WaterHeaterType choices are "storage water heater", "instantaneous water heater", "heat pump water heater", "space-heating boiler with storage tank", or "space-heating boiler with tankless coil".
  .. [#] Location choices are "living space", "basement - unconditioned", "basement - conditioned", "attic - unvented", "attic - vented", "garage", "crawlspace - unvented", "crawlspace - vented", "crawlspace - conditioned", "other exterior", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If Location not provided, defaults to the first present space type:
  
         - **IECC zones 1-3, excluding 3A**: "garage", "living space"
         - **IECC zones 3A, 4-8, unknown**: "basement - conditioned", "basement - unconditioned", "living space"

  .. [#] The sum of all ``FractionDHWLoadServed`` (across all WaterHeatingSystems) must equal to 1.
  .. [#] FractionDHWLoadServed represents only the fraction of the hot water load associated with the hot water **fixtures**.
         Additional hot water load from clothes washers/dishwashers will be automatically assigned to the appropriate water heater(s).
  .. [#] NumberofUnitsServed only required if IsSharedSystem is true, in which case it must be > 1.

Conventional Storage
~~~~~~~~~~~~~~~~~~~~

If a conventional storage water heater is specified, additional information is entered in ``WaterHeatingSystem``.

  ================================================================  =================  =============  ===============  ========  ========  ====================================================
  Element                                                           Type               Units          Constraints      Required  Default   Notes
  ================================================================  =================  =============  ===============  ========  ========  ====================================================
  ``FuelType``                                                      string                            See [#]_         Yes                 Fuel type
  ``TankVolume``                                                    double             gal            > 0              No        See [#]_  Tank volume
  ``HeatingCapacity``                                               double             Btuh           > 0              No        See [#]_  Heating capacity
  ``UniformEnergyFactor`` or ``EnergyFactor`` or ``YearInstalled``  double or integer  frac or #      < 1 or > 1600    Yes       See [#]_  EnergyGuide label rated efficiency or Year installed
  ``UsageBin`` or ``FirstHourRating``                               string or double   str or gal/hr  See [#]_ or > 0  No        See [#]_  EnergyGuide label usage bin/first hour rating
  ``RecoveryEfficiency``                                            double             frac           0 - 1 [#]_       No        See [#]_  Recovery efficiency
  ``WaterHeaterInsulation/Jacket/JacketRValue``                     double             F-ft2-hr/Btu   >= 0             No        0         R-value of additional tank insulation wrap
  ================================================================  =================  =============  ===============  ========  ========  ====================================================
  
  .. [#] FuelType choices are "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "anthracite coal", "electricity", "wood", or "wood pellets".
  .. [#] If TankVolume not provided, defaults based on Table 8 in the `2014 BAHSP <https://www.energy.gov/sites/prod/files/2014/03/f13/house_simulation_protocols_2014.pdf>`_.
  .. [#] If HeatingCapacity not provided, defaults based on Table 8 in the `2014 BAHSP <https://www.energy.gov/sites/prod/files/2014/03/f13/house_simulation_protocols_2014.pdf>`_.
  .. [#] If UniformEnergyFactor and EnergyFactor not provided, defaults to EnergyFactor from the lookup table that can be found at ``HPXMLtoOpenStudio\resources\lu_water_heater_efficiency.csv`` based on YearInstalled.
  .. [#] UsageBin choices are "very small", "low", "medium", or "high".
  .. [#] UsageBin/FirstHourRating are only used for water heaters that use UniformEnergyFactor.
         If neither UsageBin nor FirstHourRating provided, UsageBin defaults to "medium".
         If FirstHourRating provided and UsageBin not provided, UsageBin is determined based on the FirstHourRating value.
  .. [#] RecoveryEfficiency must also be greater than the EnergyFactor (or UniformEnergyFactor).
  .. [#] If RecoveryEfficiency not provided, defaults as follows based on a regression analysis of `AHRI certified water heaters <https://www.ahridirectory.org/NewSearch?programId=24&searchTypeId=3>`_:
  
         - **Electric**: 0.98
         - **Non-electric, EnergyFactor < 0.75**: 0.252 * EnergyFactor + 0.608
         - **Non-electric, EnergyFactor >= 0.75**: 0.561 * EnergyFactor + 0.439

Tankless
~~~~~~~~

If an instantaneous tankless water heater is specified, additional information is entered in ``WaterHeatingSystem``.

  ===========================================  =======  ============  ===========  ============  ========  ==========================================================
  Element                                      Type     Units         Constraints  Required      Default   Notes
  ===========================================  =======  ============  ===========  ============  ========  ==========================================================
  ``FuelType``                                 string                 See [#]_     Yes                     Fuel type
  ``PerformanceAdjustment``                    double   frac                       No            See [#]_  Multiplier on efficiency, typically to account for cycling
  ``UniformEnergyFactor`` or ``EnergyFactor``  double   frac          < 1          Yes                     EnergyGuide label rated efficiency
  ===========================================  =======  ============  ===========  ============  ========  ==========================================================
  
  .. [#] FuelType choices are "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "anthracite coal", "electricity", "wood", or "wood pellets".
  .. [#] If PerformanceAdjustment not provided, defaults to 0.94 (UEF) or 0.92 (EF) based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

Heat Pump
~~~~~~~~~

If a heat pump water heater is specified, additional information is entered in ``WaterHeatingSystem``.

  =============================================  ================  =============  ===============  ========  ========  =============================================
  Element                                        Type              Units          Constraints      Required  Default   Notes
  =============================================  ================  =============  ===============  ========  ========  =============================================
  ``FuelType``                                   string                           See [#]_         Yes                 Fuel type
  ``TankVolume``                                 double            gal            > 0              Yes                 Tank volume
  ``UniformEnergyFactor`` or ``EnergyFactor``    double            frac           > 1              Yes                 EnergyGuide label rated efficiency
  ``UsageBin`` or ``FirstHourRating``            string or double  str or gal/hr  See [#]_ or > 0  No        See [#]_  EnergyGuide label usage bin/first hour rating
  ``WaterHeaterInsulation/Jacket/JacketRValue``  double            F-ft2-hr/Btu   >= 0             No        0         R-value of additional tank insulation wrap
  =============================================  ================  =============  ===============  ========  ========  =============================================

  .. [#] FuelType only choice is "electricity".
  .. [#] UsageBin choices are "very small", "low", "medium", or "high".
  .. [#] UsageBin/FirstHourRating are only used for water heaters that use UniformEnergyFactor.
         If neither UsageBin nor FirstHourRating provided, UsageBin defaults to "medium".
         If FirstHourRating provided and UsageBin not provided, UsageBin is determined based on the FirstHourRating value.

Combi Boiler w/ Storage
~~~~~~~~~~~~~~~~~~~~~~~

If a combination boiler w/ storage tank (sometimes referred to as an indirect water heater) is specified, additional information is entered in ``WaterHeatingSystem``.

  =============================================  =======  ============  ===========  ============  ========  ==================================================
  Element                                        Type     Units         Constraints  Required      Default   Notes
  =============================================  =======  ============  ===========  ============  ========  ==================================================
  ``RelatedHVACSystem``                          idref                  See [#]_     Yes                     ID of boiler
  ``TankVolume``                                 double   gal           > 0          Yes                     Volume of the storage tank
  ``WaterHeaterInsulation/Jacket/JacketRValue``  double   F-ft2-hr/Btu  >= 0         No            0         R-value of additional storage tank insulation wrap
  ``StandbyLoss``                                double   F/hr          > 0          No            See [#]_  Storage tank standby losses
  =============================================  =======  ============  ===========  ============  ========  ==================================================

  .. [#] RelatedHVACSystem must reference a ``HeatingSystem`` of type Boiler.
  .. [#] If StandbyLoss not provided, defaults based on a regression analysis of `AHRI Directory of Certified Product Performance <https://www.ahridirectory.org>`_.

Combi Boiler w/ Tankless Coil
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a combination boiler w/ tankless coil is specified, additional information is entered in ``WaterHeatingSystem``.

  =====================  =======  ============  ===========  ============  ========  ==================================================
  Element                Type     Units         Constraints  Required      Default   Notes
  =====================  =======  ============  ===========  ============  ========  ==================================================
  ``RelatedHVACSystem``  idref                  See [#]_     Yes                     ID of boiler
  =====================  =======  ============  ===========  ============  ========  ==================================================

  .. [#] RelatedHVACSystem must reference a ``HeatingSystem`` (Boiler).

Desuperheater
~~~~~~~~~~~~~

If the water heater uses a desuperheater, additional information is entered in ``WaterHeatingSystem``.

  =====================  =======  ============  ===========  ============  ========  ==================================
  Element                Type     Units         Constraints  Required      Default   Notes
  =====================  =======  ============  ===========  ============  ========  ==================================
  ``RelatedHVACSystem``  idref                  See [#]_     Yes                     ID of heat pump or air conditioner
  =====================  =======  ============  ===========  ============  ========  ==================================

  .. [#] RelatedHVACSystem must reference a ``HeatPump`` (air-to-air, mini-split, or ground-to-air) or ``CoolingSystem`` (central air conditioner or mini-split).

HPXML Hot Water Distribution
****************************

If any water heating systems are provided, a single hot water distribution system is entered as a ``/HPXML/Building/BuildingDetails/Systems/WaterHeating/HotWaterDistribution``.

  =================================  =======  ============  ===========  ========  ========  =======================================================================
  Element                            Type     Units         Constraints  Required  Default   Notes
  =================================  =======  ============  ===========  ========  ========  =======================================================================
  ``SystemIdentifier``               id                                  Yes                 Unique identifier
  ``SystemType``                     element                1 [#]_       Yes                 Type of in-unit distribution system serving the dwelling unit
  ``PipeInsulation/PipeRValue``      double   F-ft2-hr/Btu  >= 0         No        0.0       Pipe insulation R-value
  ``DrainWaterHeatRecovery``         element                0 - 1        No        <none>    Presence of drain water heat recovery device
  ``extension/SharedRecirculation``  element                0 - 1 [#]_   No        <none>    Presence of shared recirculation system serving multiple dwelling units
  =================================  =======  ============  ===========  ========  ========  =======================================================================

  .. [#] SystemType child element choices are ``Standard`` and ``Recirculation``.
  .. [#] If SharedRecirculation is provided, SystemType must be ``Standard``.
         This is because a stacked recirculation system (i.e., shared recirculation loop plus an additional in-unit recirculation system) is more likely to indicate input errors than reflect an actual real-world scenario.

.. note::

  In attached/multifamily buildings, only the hot water distribution system serving the dwelling unit should be defined.
  The hot water distribution associated with, e.g., a shared laundry room should not be defined.

Standard
~~~~~~~~

If the in-unit distribution system is specified as standard, additional information is entered in ``SystemType/Standard``.

  ================  =======  =====  ===========  ========  ========  =====================
  Element           Type     Units  Constraints  Required  Default   Notes
  ================  =======  =====  ===========  ========  ========  =====================
  ``PipingLength``  double   ft     > 0          No        See [#]_  Length of piping [#]_
  ================  =======  =====  ===========  ========  ========  =====================

  .. [#] | If PipingLength not provided, calculated using the following equation from `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_:
         | PipeL = 2.0 * (CFA / NCfl)^0.5 + 10.0 * NCfl + 5.0 * Bsmnt
         | where
         | CFA = conditioned floor area [ft2],
         | NCfl = number of conditioned floor levels number of conditioned floor levels in the residence including conditioned basements,
         | Bsmnt = presence (1.0) or absence (0.0) of an unconditioned basement in the residence.
  .. [#] PipingLength is the length of hot water piping from the hot water heater (or from a shared recirculation loop serving multiple dwelling units) to the farthest hot water fixture, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 10 feet of piping for each floor level, plus 5 feet of piping for unconditioned basements (if any).

Recirculation
~~~~~~~~~~~~~

If the in-unit distribution system is specified as recirculation, additional information is entered in ``SystemType/Recirculation``.

  =================================  =======  =====  ===========  ========  ========  =====================================
  Element                            Type     Units  Constraints  Required  Default   Notes
  =================================  =======  =====  ===========  ========  ========  =====================================
  ``ControlType``                    string          See [#]_     Yes                 Recirculation control type
  ``RecirculationPipingLoopLength``  double   ft     > 0          No        See [#]_  Recirculation piping loop length [#]_
  ``BranchPipingLoopLength``         double   ft     > 0          No        10        Branch piping loop length [#]_
  ``PumpPower``                      double   W      >= 0         No        50 [#]_   Recirculation pump power
  =================================  =======  =====  ===========  ========  ========  =====================================

  .. [#] ControlType choices are "manual demand control", "presence sensor demand control", "temperature", "timer", or "no control".
  .. [#] | If RecirculationPipingLoopLength not provided, calculated using the following equation from `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_:
         | RecircPipeL = 2.0 * (2.0 * (CFA / NCfl)^0.5 + 10.0 * NCfl + 5.0 * Bsmnt) - 20.0
         | where
         | CFA = conditioned floor area [ft2],
         | NCfl = number of conditioned floor levels number of conditioned floor levels in the residence including conditioned basements,
         | Bsmnt = presence (1.0) or absence (0.0) of an unconditioned basement in the residence.
  .. [#] RecirculationPipingLoopLength is the recirculation loop length including both supply and return sides, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 20 feet of piping for each floor level greater than one plus 10 feet of piping for unconditioned basements.
  .. [#] BranchPipingLoopLength is the length of the branch hot water piping from the recirculation loop to the farthest hot water fixture from the recirculation loop, measured longitudinally from plans, assuming the branch hot water piping does not run diagonally.
  .. [#] PumpPower default based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

Shared Recirculation
~~~~~~~~~~~~~~~~~~~~

If a shared recirculation system is specified, additional information is entered in ``extension/SharedRecirculation``.

  =======================  =======  =====  ===========  ========  ========  =================================
  Element                  Type     Units  Constraints  Required  Default   Notes
  =======================  =======  =====  ===========  ========  ========  =================================
  ``NumberofUnitsServed``  integer         > 1          Yes                 Number of dwelling units served
  ``PumpPower``            double   W      >= 0         No        220 [#]_  Shared recirculation pump power
  ``ControlType``          string          See [#]_     Yes                 Shared recirculation control type
  =======================  =======  =====  ===========  ========  ========  =================================

  .. [#] PumpPower default based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.
  .. [#] ControlType choices are "manual demand control", "presence sensor demand control", "timer", or "no control".

Drain Water Heat Recovery
~~~~~~~~~~~~~~~~~~~~~~~~~

If a drain water heat recovery (DWHR) device is specified, additional information is entered in ``DrainWaterHeatRecovery``.

  =======================  =======  =====  ===========  ========  ========  =========================================
  Element                  Type     Units  Constraints  Required  Default   Notes
  =======================  =======  =====  ===========  ========  ========  =========================================
  ``FacilitiesConnected``  string          See [#]_     Yes                 Specifies which facilities are connected
  ``EqualFlow``            boolean                      Yes                 Specifies how the DHWR is configured [#]_
  ``Efficiency``           double   frac   0 - 1        Yes                 Efficiency according to CSA 55.1
  =======================  =======  =====  ===========  ========  ========  =========================================

  .. [#] FacilitiesConnected choices are "one" or "all".
         Use "one" if there are multiple showers and only one of them is connected to the DWHR.
         Use "all" if there is one shower and it's connected to the DWHR or there are two or more showers connected to the DWHR.
  .. [#] EqualFlow should be true if the DWHR supplies pre-heated water to both the fixture cold water piping *and* the hot water heater potable supply piping.

HPXML Water Fixtures
********************

Each water fixture is entered as a ``/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture``.

  ====================  =======  =====  ===========  ========  ========  ===============================================
  Element               Type     Units  Constraints  Required  Default   Notes
  ====================  =======  =====  ===========  ========  ========  ===============================================
  ``SystemIdentifier``  id                           Yes                 Unique identifier
  ``WaterFixtureType``  string          See [#]_     Yes                 Type of water fixture
  ``LowFlow``           boolean                      Yes                 Whether the fixture is considered low-flow [#]_
  ====================  =======  =====  ===========  ========  ========  ===============================================

  .. [#] WaterFixtureType choices are "shower head" or "faucet".
  .. [#] LowFlow should be true if the fixture's flow rate (gpm) is <= 2.0.

Additional information can be entered in ``/HPXML/Building/BuildingDetails/Systems/WaterHeating/``.

  =====================================================  =======  =====  ===========  ========  ========  ===============================================
  Element                                                Type     Units  Constraints  Required  Default   Notes
  =====================================================  =======  =====  ===========  ========  ========  ===============================================
  ``extension/WaterFixturesUsageMultiplier``             double          >= 0         No        1.0       Multiplier on hot water usage
  ``extension/WaterFixturesWeekdayScheduleFractions``    array                        No        See [#]_  24 comma-separated weekday fractions
  ``extension/WaterFixturesWeekendScheduleFractions``    array                        No                  24 comma-separated weekend fractions
  ``extension/WaterFixturesMonthlyScheduleMultipliers``  array                        No        See [#]_  12 comma-separated monthly multipliers
  =====================================================  =======  =====  ===========  ========  ========  ===============================================

  .. [#] If WaterFixturesWeekdayScheduleFractions or WaterFixturesWeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figures 9-11 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.087, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.039, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026".
  .. [#] If WaterFixturesMonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values are used: "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0".

HPXML Solar Thermal
*******************

A single solar hot water system can be entered as a ``/HPXML/Building/BuildingDetails/Systems/SolarThermal/SolarThermalSystem``.
If not entered, the simulation will not include solar hot water.

  ====================  =======  =====  ===========  ========  ========  ============================
  Element               Type     Units  Constraints  Required  Default   Notes
  ====================  =======  =====  ===========  ========  ========  ============================
  ``SystemIdentifier``  id                           Yes                 Unique identifier
  ``SystemType``        string          See [#]_     Yes                 Type of solar thermal system
  ====================  =======  =====  ===========  ========  ========  ============================

  .. [#] SystemType only choice is "hot water".

Solar hot water systems can be described with either simple or detailed inputs.

Simple Inputs
~~~~~~~~~~~~~

To define a simple solar hot water system, additional information is entered in ``SolarThermalSystem``.

  =================  =======  =====  ===========  ========  ========  ======================
  Element            Type     Units  Constraints  Required  Default   Notes
  =================  =======  =====  ===========  ========  ========  ======================
  ``SolarFraction``  double   frac   0 - 1        Yes                 Solar fraction [#]_
  ``ConnectedTo``    idref           See [#]_     No [#]_   <none>    Connected water heater
  =================  =======  =====  ===========  ========  ========  ======================
  
  .. [#] Portion of total conventional hot water heating load (delivered energy plus tank standby losses).
         Can be obtained from `Directory of SRCC OG-300 Solar Water Heating System Ratings <https://solar-rating.org/programs/og-300-program/>`_ or NREL's `System Advisor Model <https://sam.nrel.gov/>`_ or equivalent.
  .. [#] ConnectedTo must reference a ``WaterHeatingSystem``.
         The referenced water heater cannot be a space-heating boiler nor attached to a desuperheater.
  .. [#] If ConnectedTo not provided, solar fraction will apply to all water heaters in the building.

Detailed Inputs
~~~~~~~~~~~~~~~

To define a detailed solar hot water system, additional information is entered in ``SolarThermalSystem``.

  ================================================  =================  ================  ===================  ========  ========  ==============================
  Element                                           Type               Units             Constraints          Required  Default   Notes
  ================================================  =================  ================  ===================  ========  ========  ==============================
  ``CollectorArea``                                 double             ft2               > 0                  Yes                 Area
  ``CollectorLoopType``                             string                               See [#]_             Yes                 Loop type
  ``CollectorType``                                 string                               See [#]_             Yes                 System type
  ``CollectorAzimuth`` or ``CollectorOrientation``  integer or string  deg or direction  0 - 359 or See [#]_  Yes                 Direction panels face (clockwise from North)
  ``CollectorTilt``                                 double             deg               0 - 90               Yes                 Tilt relative to horizontal
  ``CollectorRatedOpticalEfficiency``               double             frac              0 - 1                Yes                 Rated optical efficiency [#]_
  ``CollectorRatedThermalLosses``                   double             Btu/hr-ft2-R      > 0                  Yes                 Rated thermal losses [#]_
  ``StorageVolume``                                 double             gal               > 0                  No        See [#]_  Hot water storage volume
  ``ConnectedTo``                                   idref                                See [#]_             Yes                 Connected water heater
  ================================================  =================  ================  ===================  ========  ========  ==============================
  
  .. [#] CollectorLoopType choices are "liquid indirect", "liquid direct", or "passive thermosyphon".
  .. [#] CollectorType choices are "single glazing black", "double glazing black", "evacuated tube", or "integrated collector storage".
  .. [#] CollectorOrientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] CollectorRatedOpticalEfficiency is FRTA (y-intercept) from the `Directory of SRCC OG-100 Certified Solar Collector Ratings <https://solar-rating.org/programs/og-100-program/>`_.
  .. [#] CollectorRatedThermalLosses is FRUL (slope) from the `Directory of SRCC OG-100 Certified Solar Collector Ratings <https://solar-rating.org/programs/og-100-program/>`_.
  .. [#] If StorageVolume not provided, calculated as 1.5 gal/ft2 * CollectorArea.
  .. [#] ConnectedTo must reference a ``WaterHeatingSystem`` that is not of type space-heating boiler nor connected to a desuperheater.

HPXML Photovoltaics
*******************

Each solar electric photovoltaic (PV) system is entered as a ``/HPXML/Building/BuildingDetails/Systems/Photovoltaics/PVSystem``.
If not entered, the simulation will not include photovoltaics.

Many of the inputs are adopted from the `PVWatts model <https://pvwatts.nrel.gov>`_.

  =======================================================  =================  ================  ===================  ========  ========  ============================================
  Element                                                  Type               Units             Constraints          Required  Default   Notes
  =======================================================  =================  ================  ===================  ========  ========  ============================================
  ``SystemIdentifier``                                     id                                                        Yes                 Unique identifier
  ``IsSharedSystem``                                       boolean                                                   No        false     Whether it serves multiple dwelling units
  ``Location``                                             string                               See [#]_             No        roof      Mounting location
  ``ModuleType``                                           string                               See [#]_             No        standard  Type of module
  ``Tracking``                                             string                               See [#]_             No        fixed     Type of tracking
  ``ArrayAzimuth`` or ``ArrayOrientation``                 integer or string  deg or direction  0 - 359 or See [#]_  Yes                 Direction panels face (clockwise from North)
  ``ArrayTilt``                                            double             deg               0 - 90               Yes                 Tilt relative to horizontal
  ``MaxPowerOutput``                                       double             W                 >= 0                 Yes                 Peak power
  ``InverterEfficiency``                                   double             frac              0 - 1 [#]_           No        0.96      Inverter efficiency
  ``SystemLossesFraction`` or ``YearModulesManufactured``  double or integer  frac or #         0 - 1 or > 1600      No        0.14      System losses [#]_
  ``extension/NumberofBedroomsServed``                     integer                              > 1                  See [#]_            Number of bedrooms served
  =======================================================  =================  ================  ===================  ========  ========  ============================================
  
  .. [#] Location choices are "ground" or "roof" mounted.
  .. [#] ModuleType choices are "standard", "premium", or "thin film".
  .. [#] Tracking choices are "fixed", "1-axis", "1-axis backtracked", or "2-axis".
  .. [#] ArrayOrientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] For homes with multiple PV arrays, all InverterEfficiency elements must have the same value.
  .. [#] System losses due to soiling, shading, snow, mismatch, wiring, degradation, etc.
         If YearModulesManufactured provided but not SystemLossesFraction, system losses calculated as:
         SystemLossesFraction = 1.0 - (1.0 - 0.14) * (1.0 - (1.0 - 0.995^(CurrentYear - YearModulesManufactured))).
  .. [#] NumberofBedroomsServed only required if IsSharedSystem is true, in which case it must be > NumberofBedrooms.
         PV generation will be apportioned to the dwelling unit using its number of bedrooms divided by the total number of bedrooms served by the PV system.

HPXML Batteries
***************

A single battery can be entered as a ``/HPXML/Building/BuildingDetails/Systems/Batteries/Battery``.
If not entered, the simulation will not include batteries.

  ====================================================  =======  =========  ===========  ========  ========  ============================================
  Element                                               Type     Units      Constraints  Required  Default   Notes
  ====================================================  =======  =========  ===========  ========  ========  ============================================
  ``SystemIdentifier``                                  id                               Yes                 Unique identifier
  ``Location``                                          string              See [#]_     No        outside   Location
  ``BatteryType``                                       string              See [#]_     Yes                 Battery type
  ``NominalCapacity[Units="kWh" or Units="Ah"]/Value``  double   kWh or Ah  >= 0         No        See [#]_  Nominal (not usable) capacity
  ``RatedPowerOutput``                                  double   W          >= 0         No        See [#]_  Rated power output
  ``NominalVoltage``                                    double   V          >= 0         No        50        Nominal voltage
  ``extension/LifetimeModel``                           string              See [#]_     No        None      Lifetime model [#]_
  ====================================================  =======  =========  ===========  ========  ========  ============================================

  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "attic - vented", "attic - unvented", "garage", or "outside".
  .. [#] BatteryType choices are "Li-ion".
  .. [#] NominalCapacity is defaulted to 10 kWh if RatedPowerOutput is not specified; otherwise it is calculated as (RatedPowerOutput / 1000) / 0.5.
  .. [#] RatedPowerOutput is defaulted to 5000 W if NominalCapacity is not specified; otherwise it is calculated as NominalCapacity * 1000 * 0.5.
  .. [#] LifetimeModel choices are "None" or "KandlerSmith".
  .. [#] See the "Lifetime Model" `EnergyPlus documentation <https://bigladdersoftware.com/epx/docs/9-6/input-output-reference/group-electric-load-center-generator.html#liion-lifetime-model>`_ for more information.

HPXML Generators
****************

Each generator that provides on-site power is entered as a ``/HPXML/Building/BuildingDetails/Systems/extension/Generators/Generator``.
If not entered, the simulation will not include generators.

  ==========================  =======  =======  ===========  ========  =======  ============================================
  Element                     Type     Units    Constraints  Required  Default  Notes
  ==========================  =======  =======  ===========  ========  =======  ============================================
  ``SystemIdentifier``        id                             Yes                Unique identifier
  ``IsSharedSystem``          boolean                        No        false    Whether it serves multiple dwelling units
  ``FuelType``                string            See [#]_     Yes                Fuel type
  ``AnnualConsumptionkBtu``   double   kBtu/yr  > 0          Yes                Annual fuel consumed
  ``AnnualOutputkWh``         double   kWh/yr   > 0 [#]_     Yes                Annual electricity produced
  ``NumberofBedroomsServed``  integer           > 1          See [#]_           Number of bedrooms served
  ==========================  =======  =======  ===========  ========  =======  ============================================

  .. [#] FuelType choices are "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "anthracite coal", "wood", or "wood pellets".
  .. [#] AnnualOutputkWh must also be < AnnualConsumptionkBtu*3.412 (i.e., the generator must consume more energy than it produces).
  .. [#] NumberofBedroomsServed only required if IsSharedSystem is true, in which case it must be > NumberofBedrooms.
         Annual consumption and annual production will be apportioned to the dwelling unit using its number of bedrooms divided by the total number of bedrooms served by the generator.

.. note::

  Generators will be modeled as operating continuously (24/7).

HPXML Appliances
----------------

Appliances entered in ``/HPXML/Building/BuildingDetails/Appliances``.

HPXML Clothes Washer
********************

A single clothes washer can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/ClothesWasher``.
If not entered, the simulation will not include a clothes washer.

  ==============================================================  =======  ===========  ===========  ========  ============  ==============================================
  Element                                                         Type     Units        Constraints  Required  Default       Notes
  ==============================================================  =======  ===========  ===========  ========  ============  ==============================================
  ``SystemIdentifier``                                            id                                 Yes                     Unique identifier
  ``IsSharedAppliance``                                           boolean                            No        false         Whether it serves multiple dwelling units [#]_
  ``Location``                                                    string                See [#]_     No        living space  Location
  ``IntegratedModifiedEnergyFactor`` or ``ModifiedEnergyFactor``  double   ft3/kWh/cyc  > 0          No        See [#]_      EnergyGuide label efficiency [#]_
  ``AttachedToWaterHeatingSystem``                                idref                 See [#]_     See [#]_                ID of attached water heater
  ``extension/UsageMultiplier``                                   double                >= 0         No        1.0           Multiplier on energy & hot water usage
  ``extension/WeekdayScheduleFractions``                          array                              No        See [#]_      24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``                          array                              No                      24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``                        array                              No        See [#]_      12 comma-separated monthly multipliers
  ==============================================================  =======  ===========  ===========  ========  ============  ==============================================

  .. [#] For example, a clothes washer in a shared laundry room of a MF building.
  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If neither IntegratedModifiedEnergyFactor nor ModifiedEnergyFactor provided, the following default values representing a standard clothes washer from 2006 will be used:
         IntegratedModifiedEnergyFactor = 1.0,
         RatedAnnualkWh = 400,
         LabelElectricRate = 0.12,
         LabelGasRate = 1.09,
         LabelAnnualGasCost = 27.0,
         LabelUsage = 6,
         Capacity = 3.0.
  .. [#] If ModifiedEnergyFactor (MEF) provided instead of IntegratedModifiedEnergyFactor (IMEF), it will be converted using the `Interpretation on ANSI/RESNET 301-2014 Clothes Washer IMEF <https://www.resnet.us/wp-content/uploads/No.-301-2014-08-sECTION-4.2.2.5.2.8-Clothes-Washers-Eq-4.2-6.pdf>`_:
         IMEF = (MEF - 0.503) / 0.95.
  .. [#] AttachedToWaterHeatingSystem must reference a ``WaterHeatingSystem``.
  .. [#] AttachedToWaterHeatingSystem only required if IsSharedAppliance is true.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 17 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.009, 0.007, 0.004, 0.004, 0.007, 0.011, 0.022, 0.049, 0.073, 0.086, 0.084, 0.075, 0.067, 0.060, 0.049, 0.052, 0.050, 0.049, 0.049, 0.049, 0.049, 0.047, 0.032, 0.017".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "1.011, 1.002, 1.022, 1.020, 1.022, 0.996, 0.999, 0.999, 0.996, 0.964, 0.959, 1.011".

If IntegratedModifiedEnergyFactor or ModifiedEnergyFactor is provided, a complete set of EnergyGuide label information is entered in ``ClothesWasher``.

  ================================  =======  =======  ===========  ============  =======  ====================================
  Element                           Type     Units    Constraints  Required      Default  Notes
  ================================  =======  =======  ===========  ============  =======  ====================================
  ``RatedAnnualkWh``                double   kWh/yr   > 0          Yes                    EnergyGuide label annual consumption
  ``LabelElectricRate``             double   $/kWh    > 0          Yes                    EnergyGuide label electricity rate
  ``LabelGasRate``                  double   $/therm  > 0          Yes                    EnergyGuide label natural gas rate
  ``LabelAnnualGasCost``            double   $        > 0          Yes                    EnergyGuide label annual gas cost
  ``LabelUsage``                    double   cyc/wk   > 0          Yes                    EnergyGuide label number of cycles
  ``Capacity``                      double   ft3      > 0          Yes                    Clothes dryer volume
  ================================  =======  =======  ===========  ============  =======  ====================================

Clothes washer energy use and hot water use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 Addendum A <https://www.resnet.us/wp-content/uploads/ANSI_RESNET_ICC-301-2019-Addendum-A-2019_7.16.20-1.pdf>`_.

HPXML Clothes Dryer
*******************

A single clothes dryer can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/ClothesDryer``.
If not entered, the simulation will not include a clothes dryer.

  ============================================  =======  ======  ===========  ========  ============  ==============================================
  Element                                       Type     Units   Constraints  Required  Default       Notes
  ============================================  =======  ======  ===========  ========  ============  ==============================================
  ``SystemIdentifier``                          id                            Yes                     Unique identifier
  ``IsSharedAppliance``                         boolean                       No        false         Whether it serves multiple dwelling units [#]_
  ``Location``                                  string           See [#]_     No        living space  Location
  ``FuelType``                                  string           See [#]_     Yes                     Fuel type
  ``CombinedEnergyFactor`` or ``EnergyFactor``  double   lb/kWh  > 0          No        See [#]_      EnergyGuide label efficiency [#]_
  ``Vented``                                    boolean                       No        true          Whether dryer is vented
  ``VentedFlowRate``                            double   cfm     >= 0         No        100 [#]_      Exhaust flow rate during operation
  ``extension/UsageMultiplier``                 double           >= 0         No        1.0           Multiplier on energy use
  ``extension/WeekdayScheduleFractions``        array                         No        See [#]_      24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``        array                         No                      24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``      array                         No        See [#]_      12 comma-separated monthly multipliers
  ============================================  =======  ======  ===========  ========  ============  ==============================================

  .. [#] For example, a clothes dryer in a shared laundry room of a MF building.
  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] FuelType choices are "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "anthracite coal", "electricity", "wood", or "wood pellets".
  .. [#] If neither CombinedEnergyFactor nor EnergyFactor provided, the following default values representing a standard clothes dryer from 2006 will be used:
         CombinedEnergyFactor = 3.01.
  .. [#] If EnergyFactor (EF) provided instead of CombinedEnergyFactor (CEF), it will be converted using the following equation based on the `Interpretation on ANSI/RESNET/ICC 301-2014 Clothes Dryer CEF <https://www.resnet.us/wp-content/uploads/No.-301-2014-10-Section-4.2.2.5.2.8-Clothes-Dryer-CEF-Rating.pdf>`_:
         CEF = EF / 1.15.
  .. [#] VentedFlowRate default based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 18 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values are used: "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0".

Clothes dryer energy use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 Addendum A <https://www.resnet.us/wp-content/uploads/ANSI_RESNET_ICC-301-2019-Addendum-A-2019_7.16.20-1.pdf>`_.

HPXML Dishwasher
****************

A single dishwasher can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/Dishwasher``.
If not entered, the simulation will not include a dishwasher.

  ============================================  =======  ===========  ===========  ========  ============  ==============================================
  Element                                       Type     Units        Constraints  Required  Default       Notes
  ============================================  =======  ===========  ===========  ========  ============  ==============================================
  ``SystemIdentifier``                          id                                 Yes                     Unique identifier
  ``IsSharedAppliance``                         boolean                            No        false         Whether it serves multiple dwelling units [#]_
  ``Location``                                  string                See [#]_     No        living space  Location
  ``RatedAnnualkWh`` or ``EnergyFactor``        double   kWh/yr or #  > 0          No        See [#]_      EnergyGuide label consumption/efficiency [#]_
  ``AttachedToWaterHeatingSystem``              idref                 See [#]_     See [#]_                ID of attached water heater
  ``extension/UsageMultiplier``                 double                >= 0         No        1.0           Multiplier on energy & hot water usage
  ``extension/WeekdayScheduleFractions``        array                              No        See [#]_      24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``        array                              No                      24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``      array                              No        See [#]_      12 comma-separated monthly multipliers
  ============================================  =======  ===========  ===========  ========  ============  ==============================================

  .. [#] For example, a dishwasher in a shared mechanical room of a MF building.
  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If neither RatedAnnualkWh nor EnergyFactor provided, the following default values representing a standard dishwasher from 2006 will be used:
         RatedAnnualkWh = 467,
         LabelElectricRate = 0.12,
         LabelGasRate = 1.09,
         LabelAnnualGasCost = 33.12,
         LabelUsage = 4,
         PlaceSettingCapacity = 12.
  .. [#] If EnergyFactor (EF) provided instead of RatedAnnualkWh, it will be converted using the following equation based on `ANSI/RESNET/ICC 301-2014 <https://codes.iccsafe.org/content/document/843>`_:
         RatedAnnualkWh = 215.0 / EF.
  .. [#] AttachedToWaterHeatingSystem must reference a ``WaterHeatingSystem``.
  .. [#] AttachedToWaterHeatingSystem only required if IsSharedAppliance is true.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 21 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.015, 0.007, 0.005, 0.003, 0.003, 0.010, 0.020, 0.031, 0.058, 0.065, 0.056, 0.048, 0.041, 0.046, 0.036, 0.038, 0.038, 0.049, 0.087, 0.111, 0.090, 0.067, 0.044, 0.031".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097".

If the RatedAnnualkWh or EnergyFactor is provided, a complete set of EnergyGuide label information is entered in ``Dishwasher``.

  ========================  =======  =======  ===========  ========  =======  ==================================
  Element                   Type     Units    Constraints  Required  Default  Notes
  ========================  =======  =======  ===========  ========  =======  ==================================
  ``LabelElectricRate``     double   $/kWh    > 0          Yes                EnergyGuide label electricity rate
  ``LabelGasRate``          double   $/therm  > 0          Yes                EnergyGuide label natural gas rate
  ``LabelAnnualGasCost``    double   $        > 0          Yes                EnergyGuide label annual gas cost
  ``LabelUsage``            double   cyc/wk   > 0          Yes                EnergyGuide label number of cycles
  ``PlaceSettingCapacity``  integer  #        > 0          Yes                Number of place settings
  ========================  =======  =======  ===========  ========  =======  ==================================

Dishwasher energy use and hot water use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 Addendum A <https://www.resnet.us/wp-content/uploads/ANSI_RESNET_ICC-301-2019-Addendum-A-2019_7.16.20-1.pdf>`_.

HPXML Refrigerators
*******************

Each refrigerator can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/Refrigerator``.
If not entered, the simulation will not include a refrigerator.

  =====================================================  =======  ======  ===========  ========  ========  ======================================
  Element                                                Type     Units   Constraints  Required  Default   Notes
  =====================================================  =======  ======  ===========  ========  ========  ======================================
  ``SystemIdentifier``                                   id                            Yes                 Unique identifier
  ``Location``                                           string           See [#]_     No        See [#]_  Location
  ``RatedAnnualkWh``                                     double   kWh/yr  > 0          No        See [#]_  Annual consumption
  ``PrimaryIndicator``                                   boolean                       See [#]_            Primary refrigerator?
  ``extension/UsageMultiplier``                          double           >= 0         No        1.0       Multiplier on energy use
  ``extension/WeekdayScheduleFractions``                 array                         No        See [#]_  24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``                 array                         No                  24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``               array                         No        See [#]_  12 comma-separated monthly multipliers
  =====================================================  =======  ======  ===========  ========  ========  ======================================

  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If Location not provided and is the *primary* refrigerator, defaults to "living space".
         If Location not provided and is a *secondary* refrigerator, defaults to the first present space type: "garage", "basement - unconditioned", "basement - conditioned", or "living space".
  .. [#] If RatedAnnualkWh not provided, it will be defaulted to represent a standard refrigerator from 2006 using the following equation based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_:
         RatedAnnualkWh = 637.0 + 18.0 * NumberofBedrooms.
  .. [#] If multiple refrigerators are specified, there must be exactly one refrigerator described with PrimaryIndicator=true.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 16 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837".

HPXML Freezers
**************

Each standalone freezer can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/Freezer``.
If not entered, the simulation will not include a standalone freezer.

  =====================================================  ======  ======  ===========  ========  ==========  ======================================
  Element                                                Type    Units   Constraints  Required  Default     Notes
  =====================================================  ======  ======  ===========  ========  ==========  ======================================
  ``SystemIdentifier``                                   id                           Yes                   Unique identifier
  ``Location``                                           string          See [#]_     No        See [#]_    Location
  ``RatedAnnualkWh``                                     double  kWh/yr  > 0          No        319.8 [#]_  Annual consumption
  ``extension/UsageMultiplier``                          double          >= 0         No        1.0         Multiplier on energy use
  ``extension/WeekdayScheduleFractions``                 array                        No        See [#]_    24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``                 array                        No                    24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``               array                        No        See [#]_    12 comma-separated monthly multipliers
  =====================================================  ======  ======  ===========  ========  ==========  ======================================

  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If Location not provided, defaults to "garage" if present, otherwise "basement - unconditioned" if present, otherwise "basement - conditioned" if present, otherwise "living space".
  .. [#] RatedAnnualkWh default based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 16 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837".

HPXML Dehumidifier
******************

Each dehumidifier can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/Dehumidifier``.
If not entered, the simulation will not include a dehumidifier.

  ==============================================  ==========  ==========  ===========  ========  =======  ========================================
  Element                                         Type        Units       Constraints  Required  Default  Notes
  ==============================================  ==========  ==========  ===========  ========  =======  ========================================
  ``SystemIdentifier``                            id                                   Yes                Unique identifier
  ``Type``                                        string                  See [#]_     Yes                Type of dehumidifier
  ``Location``                                    string                  See [#]_     Yes                Location of dehumidifier
  ``Capacity``                                    double      pints/day   > 0          Yes                Dehumidification capacity
  ``IntegratedEnergyFactor`` or ``EnergyFactor``  double      liters/kWh  > 0          Yes                Rated efficiency
  ``DehumidistatSetpoint``                        double      frac        0 - 1 [#]_   Yes                Relative humidity setpoint
  ``FractionDehumidificationLoadServed``          double      frac        0 - 1 [#]_   Yes                Fraction of dehumidification load served
  ==============================================  ==========  ==========  ===========  ========  =======  ========================================
  
  .. [#] Type choices are "portable" or "whole-home".
  .. [#] Location only choice is "living space".
  .. [#] If multiple dehumidifiers are entered, they must all have the same setpoint or an error will be generated.
  .. [#] The sum of all ``FractionDehumidificationLoadServed`` (across all Dehumidifiers) must be less than or equal to 1.

.. note::

  Dehumidifiers are currently modeled as located within conditioned space; the model is not suited for a dehumidifier in, e.g., a wet unconditioned basement or crawlspace.
  Therefore the dehumidifier Location is currently restricted to "living space".

HPXML Cooking Range/Oven
************************

A single cooking range can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/CookingRange``.
If not entered, the simulation will not include a cooking range/oven.

  ========================================  =======  ======  ===========  ========  ============  ======================================
  Element                                   Type     Units   Constraints  Required  Default       Notes
  ========================================  =======  ======  ===========  ========  ============  ======================================
  ``SystemIdentifier``                      id                            Yes                     Unique identifier
  ``Location``                              string           See [#]_     No        living space  Location
  ``FuelType``                              string           See [#]_     Yes                     Fuel type
  ``IsInduction``                           boolean                       No        false         Induction range?
  ``extension/UsageMultiplier``             double           >= 0         No        1.0           Multiplier on energy use
  ``extension/WeekdayScheduleFractions``    array                         No        See [#]_      24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``    array                         No                      24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``  array                         No        See [#]_      12 comma-separated monthly multipliers
  ========================================  =======  ======  ===========  ========  ============  ======================================

  .. [#] Location choices are "living space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] FuelType choices are "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "anthracite coal", "electricity", "wood", or "wood pellets".
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 22 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097".

If a cooking range is specified, a single oven is also entered as a ``/HPXML/Building/BuildingDetails/Appliances/Oven``.

  ====================  =======  ======  ===========  ========  =======  ================
  Element               Type     Units   Constraints  Required  Default  Notes
  ====================  =======  ======  ===========  ========  =======  ================
  ``SystemIdentifier``  id                            Yes                Unique identifier
  ``IsConvection``      boolean                       No        false    Convection oven?
  ====================  =======  ======  ===========  ========  =======  ================

Cooking range/oven energy use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

HPXML Lighting & Ceiling Fans
-----------------------------

Lighting and ceiling fans are entered in ``/HPXML/Building/BuildingDetails/Lighting``.

HPXML Lighting
**************

Nine ``/HPXML/Building/BuildingDetails/Lighting/LightingGroup`` elements must be provided, each of which is the combination of:

- ``LightingType``: 'LightEmittingDiode', 'CompactFluorescent', and 'FluorescentTube'
- ``Location``: 'interior', 'garage', and 'exterior'

Information is entered in each ``LightingGroup``.

  =============================  =======  ======  ===========  ========  =======  ===========================================================================
  Element                        Type     Units   Constraints  Required  Default  Notes
  =============================  =======  ======  ===========  ========  =======  ===========================================================================
  ``SystemIdentifier``           id                            Yes                Unique identifier
  ``LightingType``               element          1 [#]_       Yes                Lighting type
  ``Location``                   string           See [#]_     Yes                See [#]_
  ``FractionofUnitsInLocation``  double   frac    0 - 1 [#]_   Yes                Fraction of light fixtures in the location with the specified lighting type
  =============================  =======  ======  ===========  ========  =======  ===========================================================================

  .. [#] LightingType child element choices are ``LightEmittingDiode``, ``CompactFluorescent``, or ``FluorescentTube``.
  .. [#] Location choices are "interior", "garage", or "exterior".
  .. [#] Garage lighting is ignored if the building has no garage specified elsewhere.
  .. [#] The sum of FractionofUnitsInLocation for a given Location (e.g., interior) must be less than or equal to 1.
         If the fractions sum to less than 1, the remainder is assumed to be incandescent lighting.

Additional information is entered in ``Lighting``.

  ================================================  =======  ======  ===========  ========  ========  ===============================================
  Element                                           Type     Units   Constraints  Required  Default   Notes
  ================================================  =======  ======  ===========  ========  ========  ===============================================
  ``extension/InteriorUsageMultiplier``             double           >= 0         No        1.0       Multiplier on interior lighting use
  ``extension/GarageUsageMultiplier``               double           >= 0         No        1.0       Multiplier on garage lighting use
  ``extension/ExteriorUsageMultiplier``             double           >= 0         No        1.0       Multiplier on exterior lighting use
  ``extension/InteriorWeekdayScheduleFractions``    array                         No        See [#]_  24 comma-separated interior weekday fractions
  ``extension/InteriorWeekendScheduleFractions``    array                         No                  24 comma-separated interior weekend fractions
  ``extension/InteriorMonthlyScheduleMultipliers``  array                         No                  12 comma-separated interior monthly multipliers
  ``extension/GarageWeekdayScheduleFractions``      array                         No        See [#]_  24 comma-separated garage weekday fractions
  ``extension/GarageWeekendScheduleFractions``      array                         No                  24 comma-separated garage weekend fractions
  ``extension/GarageMonthlyScheduleMultipliers``    array                         No                  12 comma-separated garage monthly multipliers
  ``extension/ExteriorWeekdayScheduleFractions``    array                         No        See [#]_  24 comma-separated exterior weekday fractions
  ``extension/ExteriorWeekendScheduleFractions``    array                         No                  24 comma-separated exterior weekend fractions
  ``extension/ExteriorMonthlyScheduleMultipliers``  array                         No                  12 comma-separated exterior monthly multipliers
  ``extension/ExteriorHolidayLighting``             element          0 - 1        No        <none>    Presence of additional holiday lighting?
  ================================================  =======  ======  ===========  ========  ========  ===============================================

  .. [#] If *interior* schedule values not provided (and :ref:`detailedschedules` not used), they will be calculated using Lighting Calculation Option 2 (location-dependent lighting profile) of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If *garage* schedule values not provided (and :ref:`detailedschedules` not used), they will be defaulted using Appendix C Table 8 of the `Title 24 2016 Res. ACM Manual <https://ww2.energy.ca.gov/2015publications/CEC-400-2015-024/CEC-400-2015-024-CMF-REV2.pdf>`_.
  .. [#] If *exterior* schedule values not provided (and :ref:`detailedschedules` not used), they will be defaulted using Appendix C Table 8 of the `Title 24 2016 Res. ACM Manual <https://ww2.energy.ca.gov/2015publications/CEC-400-2015-024/CEC-400-2015-024-CMF-REV2.pdf>`_.

If exterior holiday lighting is specified, additional information is entered in ``extension/ExteriorHolidayLighting``.

  ===============================  =======  =======  ===========  ========  =============  ============================================
  Element                          Type     Units    Constraints  Required  Default        Notes
  ===============================  =======  =======  ===========  ========  =============  ============================================
  ``Load[Units="kWh/day"]/Value``  double   kWh/day  >= 0         No        See [#]_       Holiday lighting energy use per day
  ``PeriodBeginMonth``             integer           1 - 12       No        11 (November)  Holiday lighting start date
  ``PeriodBeginDayOfMonth``        integer           1 - 31       No        24             Holiday lighting start date
  ``PeriodEndMonth``               integer           1 - 12       No        1 (January)    Holiday lighting end date
  ``PeriodEndDayOfMonth``          integer           1 - 31       No        6              Holiday lighting end date
  ``WeekdayScheduleFractions``     array                          No        See [#]_       24 comma-separated holiday weekday fractions
  ``WeekendScheduleFractions``     array                          No                       24 comma-separated holiday weekend fractions
  ===============================  =======  =======  ===========  ========  =============  ============================================

  .. [#] If Value not provided, defaults to 1.1 for single-family detached and 0.55 for others.
  .. [#] If WeekdayScheduleFractions not provided (and :ref:`detailedschedules` not used), defaults to "0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.008, 0.098, 0.168, 0.194, 0.284, 0.192, 0.037, 0.019".

Interior, exterior, and garage lighting energy use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

HPXML Ceiling Fans
******************

Each ceiling fan is entered as a ``/HPXML/Building/BuildingDetails/Lighting/CeilingFan``.
If not entered, the simulation will not include a ceiling fan.

  =========================================  =======  =======  ===========  ========  ========  ==============================
  Element                                    Type     Units    Constraints  Required  Default   Notes
  =========================================  =======  =======  ===========  ========  ========  ==============================
  ``SystemIdentifier``                       id                             Yes                 Unique identifier
  ``Airflow[FanSpeed="medium"]/Efficiency``  double   cfm/W    > 0          No        See [#]_  Efficiency at medium speed
  ``Quantity``                               integer           > 0          No        See [#]_  Number of similar ceiling fans
  ``extension/WeekdayScheduleFractions``     array                          No        See [#]_  24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``     array                          No                  24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``   array                          No        See [#]_  12 comma-separated monthly multipliers
  =========================================  =======  =======  ===========  ========  ========  ==============================

  .. [#] If Efficiency not provided, defaults to 3000 / 42.6 based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.
  .. [#] If Quantity not provided, defaults to NumberofBedrooms + 1 based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), defaults based on monthly average outdoor temperatures per `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_

Ceiling fan energy use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

.. note::

  A reduced cooling setpoint can be specified for summer months when ceiling fans are operating.
  See :ref:`hvac_control` for more information.

HPXML Pools & Hot Tubs
----------------------

HPXML Pools
***********

A single pool can be entered as a ``/HPXML/Building/BuildingDetails/Pools/Pool``.
If not entered, the simulation will not include a pool.

  ====================  =======  ======  ===========  ========  ============  =================
  Element               Type     Units   Constraints  Required  Default       Notes
  ====================  =======  ======  ===========  ========  ============  =================
  ``SystemIdentifier``  id                            Yes                     Unique identifier
  ``Type``              string           See [#]_     Yes                     Pool type
  ====================  =======  ======  ===========  ========  ============  =================

  .. [#] Type choices are "in ground", "on ground", "above ground", "other", "unknown", or "none".
         If "none" is entered, the simulation will not include a pool.

Pool Pump
~~~~~~~~~

If a pool is specified, a single pool pump can be entered as a ``Pool/PoolPumps/PoolPump``.
If not entered, the simulation will not include a pool heater.

  ========================================  =======  ======  ===========  ========  ============  ======================================
  Element                                   Type     Units   Constraints  Required  Default       Notes
  ========================================  =======  ======  ===========  ========  ============  ======================================
  ``SystemIdentifier``                      id                            Yes                     Unique identifier
  ``Type``                                  string           See [#]_     Yes                     Pool pump type
  ``Load[Units="kWh/year"]/Value``          double   kWh/yr  >= 0         No        See [#]_      Pool pump energy use
  ``extension/UsageMultiplier``             double           >= 0         No        1.0           Multiplier on pool pump energy use
  ``extension/WeekdayScheduleFractions``    array                         No        See [#]_      24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``    array                         No                      24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``  array                         No        See [#]_      12 comma-separated monthly multipliers
  ========================================  =======  ======  ===========  ========  ============  ======================================

  .. [#] Type choices are "single speed", "multi speed", "variable speed", "variable flow", "other", "unknown", or "none".
         If "none" is entered, the simulation will not include a pool pump.
  .. [#] If Value not provided, defaults based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_: 158.5 / 0.070 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.35 * ConditionedFloorArea / 1920).
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154".

Pool Heater
~~~~~~~~~~~

If a pool is specified, a pool heater can be entered as a ``Pool/Heater``.
If not entered, the simulation will not include a pool heater.

  ======================================================  =======  ==================  ===========  ========  ========  ======================================
  Element                                                 Type     Units               Constraints  Required  Default   Notes
  ======================================================  =======  ==================  ===========  ========  ========  ======================================
  ``SystemIdentifier``                                    id                                        Yes                 Unique identifier
  ``Type``                                                string                       See [#]_     Yes                 Pool heater type
  ``Load[Units="kWh/year" or Units="therm/year"]/Value``  double   kWh/yr or therm/yr  >= 0         No        See [#]_  Pool heater energy use
  ``extension/UsageMultiplier``                           double                       >= 0         No        1.0       Multiplier on pool heater energy use
  ``extension/WeekdayScheduleFractions``                  array                                     No        See [#]_  24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``                  array                                     No                  24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``                array                                     No        See [#]_  12 comma-separated monthly multipliers
  ======================================================  =======  ==================  ===========  ========  ========  ======================================

  .. [#] Type choices are "none, "gas fired", "electric resistance", or "heat pump".
         If "none" is entered, the simulation will not include a pool heater.
  .. [#] If Value not provided, defaults as follows:
         
         - **gas fired**: 3.0 / 0.014 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.35 * ConditionedFloorArea / 1920) (based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **electric resistance**: 8.3 / 0.004 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.35 * ConditionedFloorArea / 1920) (based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **heat pump**: (electric resistance) / 5.0 (based on an average COP of 5 from `Energy Saver <https://www.energy.gov/energysaver/heat-pump-swimming-pool-heaters>`_)

  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154".

HPXML Hot Tubs
**************

A single hot tub can be entered as a ``/HPXML/Building/BuildingDetails/HotTubs/HotTub``.
If not entered, the simulation will not include a hot tub.

  ====================  =======  ======  ===========  ========  ============  =================
  Element               Type     Units   Constraints  Required  Default       Notes
  ====================  =======  ======  ===========  ========  ============  =================
  ``SystemIdentifier``  id                            Yes                     Unique identifier
  ``Type``              string           See [#]_     Yes                     Hot tub type
  ====================  =======  ======  ===========  ========  ============  =================

  .. [#] Type choices are "in ground", "on ground", "above ground", "other", "unknown", or "none".
         If "none" is entered, the simulation will not include a hot tub.

Hot Tub Pump
~~~~~~~~~~~~

If a hot tub is specified, a single hot tub pump can be entered as a ``HotTub/HotTubPumps/HotTubPump``.
If not entered, the simulation will not include a hot tub pump.

  ========================================  =======  ======  ===========  ========  ============  ======================================
  Element                                   Type     Units   Constraints  Required  Default       Notes
  ========================================  =======  ======  ===========  ========  ============  ======================================
  ``SystemIdentifier``                      id                            Yes                     Unique identifier
  ``Type``                                  string           See [#]_     Yes                     Hot tub pump type
  ``Load[Units="kWh/year"]/Value``          double   kWh/yr  >= 0         No        See [#]_      Hot tub pump energy use
  ``extension/UsageMultiplier``             double           >= 0         No        1.0           Multiplier on hot tub pump energy use
  ``extension/WeekdayScheduleFractions``    array                         No        See [#]_      24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``    array                         No                      24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``  array                         No        See [#]_      12 comma-separated monthly multipliers
  ========================================  =======  ======  ===========  ========  ============  ======================================

  .. [#] Type choices are "single speed", "multi speed", "variable speed", "variable flow", "other", "unknown", or "none".
         If "none" is entered, the simulation will not include a hot tub pump.
  .. [#] If Value not provided, defaults based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_: 59.5 / 0.059 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.35 * ConditionedFloorArea / 1920).
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.921, 0.928, 0.921, 0.915, 0.921, 1.160, 1.158, 1.158, 1.160, 0.921, 0.915, 0.921".

Hot Tub Heater
~~~~~~~~~~~~~~

If a hot tub is specified, a hot tub heater can be entered as a ``HotTub/Heater``.
If not entered, the simulation will not include a hot tub heater.

  ======================================================  =======  ==================  ===========  ========  ========  =======================================
  Element                                                 Type     Units               Constraints  Required  Default   Notes
  ======================================================  =======  ==================  ===========  ========  ========  =======================================
  ``SystemIdentifier``                                    id                                        Yes                 Unique identifier
  ``Type``                                                string                       See [#]_     Yes                 Hot tub heater type
  ``Load[Units="kWh/year" or Units="therm/year"]/Value``  double   kWh/yr or therm/yr  >= 0         No        See [#]_  Hot tub heater energy use
  ``extension/UsageMultiplier``                           double                       >= 0         No        1.0       Multiplier on hot tub heater energy use
  ``extension/WeekdayScheduleFractions``                  array                                     No        See [#]_  24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``                  array                                     No                  24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``                array                                     No        See [#]_  12 comma-separated monthly multipliers
  ======================================================  =======  ==================  ===========  ========  ========  =======================================

  .. [#] Type choices are "none, "gas fired", "electric resistance", or "heat pump".
         If "none" is entered, the simulation will not include a hot tub heater.
  .. [#] If Value not provided, defaults as follows:
         
         - **gas fired [therm/year]**: 0.87 / 0.011 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.35 * ConditionedFloorArea / 1920) (based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **electric resistance [kWh/year]**: 49.0 / 0.048 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.35 * ConditionedFloorArea / 1920) (based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **heat pump [kWh/year]** = (electric resistance) / 5.0 (based on an average COP of 5 from `Energy Saver <https://www.energy.gov/energysaver/heat-pump-swimming-pool-heaters>`_)

  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837".

HPXML Misc Loads
----------------

Miscellaneous loads are entered in ``/HPXML/Building/BuildingDetails/MiscLoads``.

HPXML Plug Loads
****************

Each type of plug load can be entered as a ``/HPXML/Building/BuildingDetails/MiscLoads/PlugLoad``.

It is required to include miscellaneous plug loads (PlugLoadType="other"), which represents all residual plug loads not explicitly captured elsewhere.
It is common to include television plug loads (PlugLoadType="TV other"), which represents all television energy use in the home.
It is less common to include the other plug load types, as they are less frequently found in homes.
If not entered, the simulation will not include that type of plug load.

  ========================================  =======  ======  ===========  ========  ========  =============================================================
  Element                                   Type     Units   Constraints  Required  Default   Notes
  ========================================  =======  ======  ===========  ========  ========  =============================================================
  ``SystemIdentifier``                      id                            Yes                 Unique identifier
  ``PlugLoadType``                          string           See [#]_     Yes                 Type of plug load
  ``Load[Units="kWh/year"]/Value``          double   kWh/yr  >= 0         No        See [#]_  Annual electricity consumption
  ``extension/FracSensible``                double           0 - 1        No        See [#]_  Fraction that is sensible heat gain to conditioned space [#]_
  ``extension/FracLatent``                  double           0 - 1        No        See [#]_  Fraction that is latent heat gain to conditioned space
  ``extension/UsageMultiplier``             double           >= 0         No        1.0       Multiplier on electricity use
  ``extension/WeekdayScheduleFractions``    array                         No        See [#]_  24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``    array                         No        See [#]_  24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``  array                         No        See [#]_  12 comma-separated monthly multipliers
  ========================================  =======  ======  ===========  ========  ========  =============================================================

  .. [#] PlugLoadType choices are "other", "TV other", "well pump", or "electric vehicle charging".
  .. [#] If Value not provided, defaults as:
         
         - **other**: 0.91 * ConditionedFloorArea (based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_)
         - **TV other**: 413.0 + 69.0 * NumberofBedrooms (based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_)
         - **well pump**: 50.8 / 0.127 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.35 * ConditionedFloorArea / 1920) (based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **electric vehicle charging**: 1666.67 (calculated using AnnualMiles * kWhPerMile / (ChargerEfficiency * BatteryEfficiency) where AnnualMiles=4500, kWhPerMile=0.3, ChargerEfficiency=0.9, and BatteryEfficiency=0.9)
         
  .. [#] If FracSensible not provided, defaults as:
  
         - **other**: 0.855
         - **TV other**: 1.0
         - **well pump**: 0.0
         - **electric vehicle charging**: 0.0

  .. [#] The remaining fraction (i.e., 1.0 - FracSensible - FracLatent) must be > 0 and is assumed to be heat gain outside conditioned space and thus lost.
  .. [#] If FracLatent not provided, defaults as:

         - **other**: 0.045
         - **TV other**: 0.0
         - **well pump**: 0.0
         - **electric vehicle charging**: 0.0

  .. [#] If WeekdayScheduleFractions not provided (and :ref:`detailedschedules` not used), defaults as:
         
         - **other**: "0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036" (based on Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **TV other**: "0.037, 0.018, 0.009, 0.007, 0.011, 0.018, 0.029, 0.040, 0.049, 0.058, 0.065, 0.072, 0.076, 0.086, 0.091, 0.102, 0.127, 0.156, 0.210, 0.294, 0.363, 0.344, 0.208, 0.090" (based on the `American Time Use Survey <https://www.bls.gov/tus>`_)
         - **well pump**: "0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065" (based on Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **electric vehicle charging**: "0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042"

  .. [#] If WeekdendScheduleFractions not provided (and :ref:`detailedschedules` not used), defaults as:

         - **other**: "0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036" (based on Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **TV other**: "0.044, 0.022, 0.012, 0.008, 0.011, 0.014, 0.024, 0.043, 0.071, 0.094, 0.112, 0.123, 0.132, 0.156, 0.178, 0.196, 0.206, 0.213, 0.251, 0.330, 0.388, 0.358, 0.226, 0.103" (based on the `American Time Use Survey <https://www.bls.gov/tus>`_)
         - **well pump**: "0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065" (based on Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **electric vehicle charging**: "0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042"

  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), defaults as:

         - **other**: "1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248" (based on Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **TV other**: "1.137, 1.129, 0.961, 0.969, 0.961, 0.993, 0.996, 0.96, 0.993, 0.867, 0.86, 1.137" (based on the `American Time Use Survey <https://www.bls.gov/tus>`_)
         - **well pump**: "1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154" (based on Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         - **electric vehicle charging**: "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0"

HPXML Fuel Loads
****************

Each fuel load can be entered as a ``/HPXML/Building/BuildingDetails/MiscLoads/FuelLoad``.

It is less common to include fuel load types, as they are less frequently found in homes.
If not entered, the simulation will not include that type of fuel load.

  ========================================  =======  ========  ===========  ========  ========  =============================================================
  Element                                   Type     Units     Constraints  Required  Default   Notes
  ========================================  =======  ========  ===========  ========  ========  =============================================================
  ``SystemIdentifier``                      id                              Yes                 Unique identifier
  ``FuelLoadType``                          string             See [#]_     Yes                 Type of fuel load
  ``Load[Units="therm/year"]/Value``        double   therm/yr  >= 0         No        See [#]_  Annual fuel consumption
  ``FuelType``                              string             See [#]_     Yes                 Fuel type
  ``extension/FracSensible``                double             0 - 1        No        See [#]_  Fraction that is sensible heat gain to conditioned space [#]_
  ``extension/FracLatent``                  double             0 - 1        No        See [#]_  Fraction that is latent heat gain to conditioned space
  ``extension/UsageMultiplier``             double             >= 0         No        1.0       Multiplier on fuel use
  ``extension/WeekdayScheduleFractions``    array                           No        See [#]_  24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``    array                           No                  24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``  array                           No        See [#]_  12 comma-separated monthly multipliers
  ========================================  =======  ========  ===========  ========  ========  =============================================================

  .. [#] FuelLoadType choices are "grill", "fireplace", or "lighting".
  .. [#] If Value not provided, calculated as based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_:

         - **grill**: 0.87 / 0.029 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.35 * ConditionedFloorArea / 1920)
         - **fireplace**: 1.95 / 0.032 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.35 * ConditionedFloorArea / 1920)
         - **lighting**: 0.22 / 0.012 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.35 * ConditionedFloorArea / 1920)

  .. [#] FuelType choices are "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "anthracite coal", "wood", or "wood pellets".
  .. [#] If FracSensible not provided, defaults to 0.5 for fireplace and 0.0 for all other types.
  .. [#] The remaining fraction (i.e., 1.0 - FracSensible - FracLatent) must be > 0 and is assumed to be heat gain outside conditioned space and thus lost.
  .. [#] If FracLatent not provided, defaults to 0.1 for fireplace and 0.0 for all other types.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used:

         - **grill**: "0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007";
         - **fireplace**: "0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065";
         - **lighting**: "0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065".

  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used:

         - **grill**: "1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097";
         - **fireplace**: "1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154";
         - **lighting**: "1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154".

.. _hpxmllocations:

HPXML Locations
---------------

The various locations used in an HPXML file are defined as follows:

  ==============================  =======================================================  =======================================  =============
  Value                           Description                                              Temperature                              Building Type
  ==============================  =======================================================  =======================================  =============
  outside                         Ambient environment                                      Weather data                             Any
  ground                                                                                   EnergyPlus calculation                   Any
  living space                    Above-grade conditioned space maintained at setpoint     EnergyPlus calculation                   Any
  attic - vented                                                                           EnergyPlus calculation                   Any
  attic - unvented                                                                         EnergyPlus calculation                   Any
  basement - conditioned          Below-grade conditioned space maintained at setpoint     EnergyPlus calculation                   Any
  basement - unconditioned                                                                 EnergyPlus calculation                   Any
  crawlspace - vented                                                                      EnergyPlus calculation                   Any
  crawlspace - unvented                                                                    EnergyPlus calculation                   Any
  crawlspace - conditioned        Below-grade conditioned space maintained at setpoint     EnergyPlus calculation                   Any
  garage                          Single-family garage (not shared parking)                EnergyPlus calculation                   Any
  other housing unit              E.g., conditioned adjacent unit or conditioned corridor  Same as living space                     SFA/MF only
  other heated space              E.g., shared laundry/equipment space                     Avg of living space/outside; min of 68F  SFA/MF only
  other multifamily buffer space  E.g., enclosed unconditioned stairwell                   Avg of living space/outside; min of 50F  SFA/MF only
  other non-freezing space        E.g., shared parking garage ceiling                      Floats with outside; minimum of 40F      SFA/MF only
  other exterior                  Water heater outside                                     Weather data                             Any
  exterior wall                   Ducts in exterior wall                                   Avg of living space/outside              Any
  under slab                      Ducts under slab (ground)                                EnergyPlus calculation                   Any
  roof deck                       Ducts on roof deck (outside)                             Weather data                             Any
  ==============================  =======================================================  =======================================  =============

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
