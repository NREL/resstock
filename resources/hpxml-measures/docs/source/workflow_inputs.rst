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

HPXML files submitted to OpenStudio-HPXML undergo a two step validation process:

1. Validation against the HPXML Schema

  The HPXML XSD Schema can be found at ``HPXMLtoOpenStudio/resources/hpxml_schema/HPXML.xsd``.
  XSD Schemas are used to validate what elements/attributes/enumerations are available, data types for elements/attributes, the number/order of children elements, etc.

2. Validation using `Schematron <http://schematron.com/>`_

  The Schematron document for the EnergyPlus use case can be found at ``HPXMLtoOpenStudio/resources/hpxml_schematron/EPvalidator.xml``.
  Schematron is a rule-based validation language, expressed in XML using XPath expressions, for validating the presence or absence of inputs in XML files. 
  As opposed to an XSD Schema, a Schematron document validates constraints and requirements based on conditionals and other logical statements.
  For example, if an element is specified with a particular value, the applicable enumerations of another element may change.

OpenStudio-HPXML **automatically validates** the HPXML file against both the XSD and Schematron documents and reports any validation errors, but software developers may find it beneficial to also integrate validation into their software.

.. _bldg_type_scope:

Building Type Scope
*******************

OpenStudio-HPXML can be used to model either individual residential dwelling units or whole residential buildings.

.. _bldg_type_units:

Dwelling Units
~~~~~~~~~~~~~~

The OpenStudio-HPXML workflow was originally developed to model individual residential dwelling units -- either a single-family detached (SFD) building, or a single unit of a single-family attached (SFA) or multifamily (MF) building.
This approach:

- Is required/desired for certain applications (e.g., a Home Energy Score or an Energy Rating Index calculation).
- Improves runtime speed by being able to simulate individual units in parallel (as opposed to simulating the entire building).

When modeling individual units of SFA/MF buildings, current capabilities include:

- Defining surfaces adjacent to generic SFA/MF spaces (e.g., "other housing unit" or "other multifamily buffer space"), in which temperature profiles will be assumed (see :ref:`hpxmllocations`).
- Locating various building components (e.g., ducts, water heaters, appliances) in these SFA/MF spaces.
- Defining shared systems (HVAC, water heating, mechanical ventilation, etc.), in which individual systems are modeled with adjustments to approximate their energy use attributed to the unit.

Note that only the energy use attributed to each dwelling unit is calculated.

.. _bldg_type_bldgs:

Whole SFA/MF Buildings
~~~~~~~~~~~~~~~~~~~~~~

As of OpenStudio-HPXML v1.7.0, a new capability was added for modeling whole SFA/MF buildings in a single combined simulation.

For these simulations:

- Each dwelling unit is described by a separate ``Building`` element in the HPXML file.
- To run the single combined simulation, specify the Building ID as 'ALL' in the run_simulation.rb script or OpenStudio workflow.
- Unit multipliers (using the ``NumberofUnits`` element) can be specified to model *unique* dwelling units, rather than *all* dwelling units, reducing simulation runtime.
- Adjacent SFA/MF common spaces are still modeled using assumed temperature profiles, not as separate thermal zones.
- Shared systems are still modeled as individual systems, not shared systems connected to multiple dwelling unit.

Notes/caveats about this approach:

- Some inputs (e.g., EPW location or ground conductivity) cannot vary across ``Building`` elements.
- Batteries are not currently supported. Dehumidifiers and ground-source heat pumps are only supported if ``NumberofUnits`` is 1.
- Utility bill calculations using detailed rates are not supported.

Note that only the energy use for the entire building is calculated.

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
    <Location dataSource='software'>conditioned space</Location>
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
  For example, if there is no ``Refrigerator`` element defined, the simulation will proceed without refrigerator energy use.
  On the other hand, if there is a ``Refrigerator`` element but with no values defined (i.e., no ``Location`` or ``RatedAnnualkWh``), it is assumed that a refrigerator exists but its properties are unknown, so they will be defaulted in the model.

See :ref:`hpxml_defaults` for information on how default values can be inspected.

HPXML Software Info
-------------------

High-level simulation inputs are entered in ``/HPXML/SoftwareInfo``.

HPXML Simulation Control
************************

EnergyPlus simulation controls are entered in ``/HPXML/SoftwareInfo/extension/SimulationControl``.

  ====================================  ========  =======  =============  ========  ===========================  =====================================
  Element                               Type      Units    Constraints    Required  Default                      Description
  ====================================  ========  =======  =============  ========  ===========================  =====================================
  ``Timestep``                          integer   minutes  Divisor of 60  No        60 (1 hour)                  Timestep
  ``BeginMonth``                        integer            1 - 12 [#]_    No        1 (January)                  Run period start date
  ``BeginDayOfMonth``                   integer            1 - 31         No        1                            Run period start date
  ``EndMonth``                          integer            1 - 12         No        12 (December)                Run period end date
  ``EndDayOfMonth``                     integer            1 - 31         No        31                           Run period end date
  ``CalendarYear``                      integer            > 1600 [#]_    No        2007 (for TMY weather) [#]_  Calendar year (for start day of week)
  ``TemperatureCapacitanceMultiplier``  double             > 0            No        1.0                          Multiplier on air heat capacitance [#]_
  ====================================  ========  =======  =============  ========  ===========================  =====================================

  .. [#] BeginMonth/BeginDayOfMonth date must occur before EndMonth/EndDayOfMonth date (e.g., a run period from 10/1 to 3/31 is invalid).
  .. [#] If a leap year is specified (e.g., 2008), the EPW weather file must contain 8784 hours.
  .. [#] CalendarYear only applies to TMY (Typical Meteorological Year) weather. For AMY (Actual Meteorological Year) weather, the AMY year will be used regardless of what is specified.
  .. [#] TemperatureCapacitanceMultiplier affects the transient calculation of indoor air temperatures.
         Values greater than 1.0 have the effect of smoothing or damping the rate of change in the indoor air temperature from timestep to timestep.
         This heat capacitance effect is modeled on top of any other individual mass inputs (e.g., furniture mass, partition wall mass, interior drywall, etc.) in the HPXML.

HPXML Emissions Scenarios
*************************

One or more emissions scenarios can be entered as an ``/HPXML/SoftwareInfo/extension/EmissionsScenarios/EmissionsScenario``.
If not entered, emissions will not be calculated.

  ================================  ========  =====  ===========  ========  ========  ========================================================
  Element                           Type      Units  Constraints  Required  Default   Notes
  ================================  ========  =====  ===========  ========  ========  ========================================================
  ``Name``                          string                        Yes                 Name of the scenario (which shows up in the output file)
  ``EmissionsType``                 string           See [#]_     Yes                 Type of emissions (e.g., CO2e)
  ``EmissionsFactor``               element          >= 1         See [#]_            Emissions factor(s) for a given fuel type
  ================================  ========  =====  ===========  ========  ========  ========================================================

  .. [#] EmissionsType can be anything. But if certain values are provided (e.g., "CO2e"), then some emissions factors can be defaulted as described further below.
  .. [#] EmissionsFactor is required for electricity and optional for all non-electric fuel types.

See :ref:`annual_outputs` and :ref:`timeseries_outputs` for descriptions of how the calculated emissions appear in the output files.

Electricity Emissions
~~~~~~~~~~~~~~~~~~~~~

For each scenario, electricity emissions factors must be entered as an ``/HPXML/SoftwareInfo/extension/EmissionsScenarios/EmissionsScenario/EmissionsFactor``.

  =================================  ================  =====  ===========  ========  ========  ============================================================
  Element                            Type              Units  Constraints  Required  Default   Notes
  =================================  ================  =====  ===========  ========  ========  ============================================================
  ``FuelType``                       string                   electricity  Yes                 Emissions factor fuel type
  ``Units``                          string                   See [#]_     Yes                 Emissions factor units
  ``Value`` or ``ScheduleFilePath``  double or string         See [#]_     Yes                 Emissions factor annual value or schedule file with hourly values
  =================================  ================  =====  ===========  ========  ========  ============================================================

  .. [#] Units choices are "lb/MWh" and "kg/MWh".
  .. [#] ScheduleFilePath must point to a CSV file with 8760 numeric hourly values.
         Sources of electricity emissions data include `NREL's Cambium database <https://www.nrel.gov/analysis/cambium.html>`_ and `EPA's eGRID <https://www.epa.gov/egrid>`_.

If an electricity schedule file is used, additional information can be entered in the ``/HPXML/SoftwareInfo/extension/EmissionsScenarios/EmissionsScenario/EmissionsFactor``.

  =================================  ================  =====  ===========  ========  ========  ==============================================
  Element                            Type              Units  Constraints  Required  Default   Notes
  =================================  ================  =====  ===========  ========  ========  ==============================================
  ``NumberofHeaderRows``             integer           #      >= 0         No        0         Number of header rows in the schedule file
  ``ColumnNumber``                   integer           #      >= 1         No        1         Column number of the data in the schedule file
  =================================  ================  =====  ===========  ========  ========  ==============================================

Fuel Emissions
~~~~~~~~~~~~~~

For each scenario, fuel emissions factors can be optionally entered as an ``/HPXML/SoftwareInfo/extension/EmissionsScenarios/EmissionsScenario/EmissionsFactor``.

  ================================  ========  =====  ===========  ========  ========  =============================
  Element                           Type      Units  Constraints  Required  Default   Notes
  ================================  ========  =====  ===========  ========  ========  =============================
  ``FuelType``                      string           See [#]_     Yes                 Emissions factor fuel type
  ``Units``                         string           See [#]_     Yes                 Emissions factor units
  ``Value``                         double                        Yes                 Emissions factor annual value
  ================================  ========  =====  ===========  ========  ========  =============================

  .. [#] FuelType choices are "natural gas", "propane", "fuel oil", "coal", "wood", and "wood pellets".
  .. [#] Units choices are "lb/MBtu" and "kg/MBtu" (million Btu).

Default Values
~~~~~~~~~~~~~~

If EmissionsType is "CO2e", "NOx" or "SO2" and a given fuel's emissions factor is not entered, they will be defaulted as follows.

  ============  ==============  =============  =============
  Fuel Type     CO2e [lb/MBtu]  NOx [lb/MBtu]  SO2 [lb/MBtu]
  ============  ==============  =============  =============
  natural gas   147.3           0.0922         0.0006
  propane       177.8           0.1421         0.0002
  fuel oil      195.9           0.1300         0.0015
  coal          --              --             --
  wood          --              --             --
  wood pellets  --              --             --
  ============  ==============  =============  =============

Default values in lb/MBtu (million Btu) are from *Table 5.1.2(1) National Average Emission Factors for Household Fuels* from *ANSI/RESNET/ICC 301 Standard for the Calculation and Labeling of the Energy Performance of Dwelling and Sleeping Units using an Energy Rating Index* and include both combustion and pre-combustion (e.g., methane leakage for natural gas) emissions.

If no default value is available, a warning will be issued.

HPXML Utility Bill Scenarios
****************************

One or more utility bill scenarios can be entered as an ``/HPXML/SoftwareInfo/extension/UtilityBillScenarios/UtilityBillScenario``.
If not entered, utility bills will not be calculated.

  ================================  ========  =====  ===========  ========  ========  ========================================================
  Element                           Type      Units  Constraints  Required  Default   Notes
  ================================  ========  =====  ===========  ========  ========  ========================================================
  ``Name``                          string                        Yes                 Name of the scenario (which shows up in the output file)
  ``UtilityRate``                   element          >= 0                             Utility rate(s) for a given fuel type
  ``PVCompensation``                element          <= 1                             PV compensation information
  ================================  ========  =====  ===========  ========  ========  ========================================================

See :ref:`bill_outputs` for a description of how the calculated utility bills appear in the output files.

Electricity Rates
~~~~~~~~~~~~~~~~~

For each scenario, electricity rates can be optionally entered as an ``/HPXML/SoftwareInfo/extension/UtilityBillScenarios/UtilityBillScenario/UtilityRate``.
Electricity rates can be entered using Simple inputs or Detailed inputs.

**Simple**

For simple utility rate structures, inputs can be entered using a fixed charge and a marginal rate.

  ================================  ========  =======  ===========  ========  ========  ====================
  Element                           Type      Units    Constraints  Required  Default   Notes
  ================================  ========  =======  ===========  ========  ========  ====================
  ``FuelType``                      string             electricity  Yes                 Fuel type
  ``FixedCharge``                   double    $/month               No        12.0      Monthly fixed charge [#]_
  ``MarginalRate``                  double    $/kWh                 No        See [#]_  Marginal flat rate
  ================================  ========  =======  ===========  ========  ========  ====================

  .. [#] If running :ref:`bldg_type_bldgs`, the fixed charge will apply to every dwelling unit in the building.
  .. [#] If MarginalRate not provided, defaults to state, regional, or national average based on 2022 EIA data that can be found at ``ReportUtilityBills/resources/Data/UtilityRates/Average_retail_price_of_electricity.csv``.

**Detailed**

For detailed utility rate structures, inputs can be entered using a tariff JSON file.

  ================================  ========  =======  ===========  ========  ========  =============================
  Element                           Type      Units    Constraints  Required  Default   Notes
  ================================  ========  =======  ===========  ========  ========  =============================
  ``FuelType``                      string             electricity  Yes                 Fuel type
  ``TariffFilePath``                string                          Yes                 Path to tariff JSON file [#]_
  ================================  ========  =======  ===========  ========  ========  =============================

  .. [#] TariffFilePath must point to a JSON file with utility rate structure information.
         Tariff files can describe flat, tiered, time-of-use, tiered time-of-use, or real-time pricing rates.
         Sources of tariff files include `OpenEI's U.S. Utility Rate Database (URDB) <https://openei.org/wiki/Utility_Rate_Database>`_;
         a large set of residential OpenEI URDB rates for U.S. utilities are included at ``ReportUtilityBills/resources/detailed_rates/openei_rates.zip``.
         Additional sample tariff files can be found in ``ReportUtilityBills/resources/detailed_rates``.
         Tariff files are formatted based on `OpenEI API version 7 <https://openei.org/services/doc/rest/util_rates/?version=7#response-fields>`_.

Fuel Rates
~~~~~~~~~~

For each scenario, fuel rates can be optionally entered as an ``/HPXML/SoftwareInfo/extension/UtilityBillScenarios/UtilityBillScenario/UtilityRate``.

  ================================  ========  ========  ===========  ========  ========  ====================
  Element                           Type      Units     Constraints  Required  Default   Notes
  ================================  ========  ========  ===========  ========  ========  ====================
  ``FuelType``                      string              See [#]_     Yes                 Fuel type
  ``FixedCharge``                   double    $/month                No        See [#]_  Monthly fixed charge
  ``MarginalRate``                  double    See [#]_               No        See [#]_  Marginal flat rate
  ================================  ========  ========  ===========  ========  ========  ====================

  .. [#] FuelType choices are "natural gas", "propane", "fuel oil", "coal", "wood", and "wood pellets".
  .. [#] FixedCharge defaults to $12/month for natural gas and $0/month for other fuels.
  .. [#] MarginalRate units are $/therm for natural gas, $/gallon for propane and fuel oil, and $/kBtu for other fuels.
  .. [#] | If MarginalRate not provided, defaults to state, regional, or national average based on 2022 EIA data that can be found at:
         | - **natural gas**: ``ReportUtilityBills/resources/Data/UtilityRates/NG_PRI_SUM_A_EPG0_PRS_DMCF_A.csv``
         | - **propane**: ``ReportUtilityBills/resources/Data/UtilityRates/PET_PRI_WFR_A_EPLLPA_PRS_DPGAL_W.csv``
         | - **fuel oil**: ``ReportUtilityBills/resources/Data/UtilityRates/PET_PRI_WFR_A_EPD2F_PRS_DPGAL_W.csv``
         | or defaults to $0.015/kBtu for other fuels.

PV Compensation
~~~~~~~~~~~~~~~

For each scenario, PV compensation information can be optionally entered in ``/HPXML/SoftwareInfo/extension/UtilityBillScenarios/UtilityBillScenario/PVCompensation``.

  =============================================================  ========  =======  ===========  ========  ==============  ==============================
  Element                                                        Type      Units    Constraints  Required  Default         Notes
  =============================================================  ========  =======  ===========  ========  ==============  ==============================
  ``CompensationType[NetMetering | FeedInTariff]``               element                         No        NetMetering     PV compensation type
  ``MonthlyGridConnectionFee[Units="$/kW" or Units="$"]/Value``  double                          No        0               PV monthly grid connection fee
  =============================================================  ========  =======  ===========  ========  ==============  ==============================

**Net-Metering**

If the PV compensation type is net-metering, additional information can be entered in ``/HPXML/SoftwareInfo/extension/UtilityBillScenarios/UtilityBillScenario/PVCompensation/CompensationType/NetMetering``.

  ================================  ========  =======  ===========  ========  ==============  =============================================================
  Element                           Type      Units    Constraints  Required  Default         Notes
  ================================  ========  =======  ===========  ========  ==============  =============================================================
  ``AnnualExcessSellbackRateType``  string             See [#]_     No        User-Specified  Net metering annual excess sellback rate type [#]_
  ``AnnualExcessSellbackRate``      double    $/kWh                 No [#]_   0.03            User-specified net metering annual excess sellback rate [#]_
  ================================  ========  =======  ===========  ========  ==============  =============================================================
  
  .. [#] AnnualExcessSellbackRateType choices are "User-Specified" and "Retail Electricity Cost".
  .. [#] When annual PV production exceeds the annual building electricity consumption, this rate, which is often significantly below the retail rate, determines the value of the excess electricity sold back to the utility.
         This may happen to offset gas consumption, for example.
  .. [#] AnnualExcessSellbackRate is only used when AnnualExcessSellbackRateType="User-Specified".
  .. [#] Since modeled electricity consumption will not change from one year to the next, "indefinite rollover" of annual excess generation credit is best approximated by setting "User-Specified" and entering a rate of zero.

**Feed-in Tariff**

If the PV compensation type is feed-in tariff, additional information can be entered in ``/HPXML/SoftwareInfo/extension/UtilityBillScenarios/UtilityBillScenario/PVCompensation/CompensationType/FeedInTariff``.

  ============================  ========  =======  ===========  ========  ==============  ========================
  Element                       Type      Units    Constraints  Required  Default         Notes
  ============================  ========  =======  ===========  ========  ==============  ========================
  ``FeedInTariffRate``          double    $/kWh                 No        0.12            Feed-in tariff rate [#]_
  ============================  ========  =======  ===========  ========  ==============  ========================

  .. [#] FeedInTariffRate applies to full (not excess) PV production.
         Some utilities/regions may have a feed-in tariff policy where compensation occurs for excess PV production (i.e., PV-generated electricity sent to the grid that is not immediately consumed by the building), rather than full PV production.
         OpenStudio-HPXML is currently unable to calculate utility bills for such a feed-in tariff policy.

HPXML Unavailable Periods
*************************

One or more unavailable periods (e.g., vacancies, power outages) can be entered as an ``/HPXML/SoftwareInfo/extension/UnavailablePeriods/UnavailablePeriod``.
If not entered, the simulation will not include unavailable periods.

  ====================================  ========  =======  =============  ========  ================  ===========
  Element                               Type      Units    Constraints    Required  Default           Description
  ====================================  ========  =======  =============  ========  ================  ===========
  ``ColumnName``                        string                            Yes                         Column name associated with unavailable_periods.csv below
  ``BeginMonth``                        integer            1 - 12         Yes                         Begin month
  ``BeginDayOfMonth``                   integer            1 - 31         Yes                         Begin day
  ``BeginHourOfDay``                    integer            0 - 23         No        0                 Begin hour
  ``EndMonth``                          integer            1 - 12         Yes                         End month
  ``EndDayOfMonth``                     integer            1 - 31         Yes                         End day
  ``EndHourOfDay``                      integer            1 - 24         No        24                End hour
  ``NaturalVentilation``                string             See [#]_       No        regular schedule  Natural ventilation availability
  ====================================  ========  =======  =============  ========  ================  ===========

  .. [#] NaturalVentilation choices are "regular schedule", "always available", or "always unavailable".

See the table below to understand which components are affected by an unavailable period with a given ``ColumnName``.
You can create an additional column in the CSV file to define another unavailable period type.

.. csv-table::
   :file: ../../HPXMLtoOpenStudio/resources/data/unavailable_periods.csv
   :header-rows: 1

.. warning::

  It is not possible to eliminate all HVAC/DHW energy use (e.g. crankcase/defrost energy, water heater parasitics) in EnergyPlus during an unavailable period.

.. _buildingsite:

HPXML Building Site
-------------------

Building site information can be entered in ``/HPXML/Building/Site``.

  =======================================  ========  =====  ===========  ========  ========  ===============
  Element                                  Type      Units  Constraints  Required  Default   Description
  =======================================  ========  =====  ===========  ========  ========  ===============
  ``SiteID``                               id                            Yes                 Unique identifier
  ``Address/StateCode``                    string                        No        See [#]_  State/territory where the home is located
  ``Address/ZipCode``                      string           See [#]_     No                  ZIP Code where the home is located
  ``TimeZone/UTCOffset``                   double           See [#]_     No        See [#]_  Difference in decimal hours between the home's time zone and UTC
  ``TimeZone/DSTObserved``                 boolean                       No        true      Daylight saving time observed?
  =======================================  ========  =====  ===========  ========  ========  ===============

  .. [#] If StateCode not provided, defaults according to the EPW weather file header.
  .. [#] ZipCode can be defined as the standard 5 number postal code, or it can have the additional 4 number code separated by a hyphen.
  .. [#] UTCOffset ranges from -12 to 14.
  .. [#] If UTCOffset not provided, defaults according to the EPW weather file header.

If daylight saving time is observed, additional information can be specified in ``/HPXML/Building/Site/TimeZone/extension``.

  ============================================  ========  =====  =================  ========  =============================  ===========
  Element                                       Type      Units  Constraints        Required  Default                        Description
  ============================================  ========  =====  =================  ========  =============================  ===========
  ``DSTBeginMonth`` and ``DSTBeginDayOfMonth``  integer          1 - 12 and 1 - 31  No        EPW else 3/12 (March 12) [#]_  Start date
  ``DSTEndMonth`` and ``DSTEndDayOfMonth``      integer          1 - 12 and 1 - 31  No        EPW else 11/5 (November 5)     End date
  ============================================  ========  =====  =================  ========  =============================  ===========

  .. [#] Daylight saving dates will be defined according to the EPW weather file header; if not available, fallback default values listed above will be used.

HPXML Building Summary
----------------------

High-level building summary information is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary``. 

HPXML Site
**********

Site information is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/Site``.

  ================================  ========  ===========  ===========  ========  ========  ============================================================
  Element                           Type      Units        Constraints  Required  Default   Notes
  ================================  ========  ===========  ===========  ========  ========  ============================================================
  ``SiteType``                      string                 See [#]_     No        suburban  Terrain type for infiltration model
  ``ShieldingofHome``               string                 See [#]_     No        normal    Presence of nearby buildings, trees, obstructions for infiltration model
  ``extension/GroundConductivity``  double    Btu/hr-ft-F  > 0          No        1.0       Thermal conductivity of the ground soil [#]_
  ``extension/Neighbors``           element                >= 0         No        <none>    Presence of neighboring buildings for solar shading
  ================================  ========  ===========  ===========  ========  ========  ============================================================

  .. [#] SiteType choices are "rural", "suburban", or "urban".
  .. [#] ShieldingofHome choices are "normal", "exposed", or "well-shielded".
  .. [#] GroundConductivity used for foundation heat transfer and ground source heat pumps.

For each neighboring building defined, additional information is entered in a ``extension/Neighbors/NeighborBuilding``.

  ==============================  =================  ================  ===================  ========  ========  =============================================
  Element                         Type               Units             Constraints          Required  Default   Notes
  ==============================  =================  ================  ===================  ========  ========  =============================================
  ``Azimuth`` or ``Orientation``  integer or string  deg or direction  0 - 359 or See [#]_  Yes                 Direction of neighbors (clockwise from North)
  ``Distance``                    double             ft                > 0                  Yes                 Distance of neighbor from the dwelling unit
  ``Height``                      double             ft                > 0                  No        See [#]_  Height of neighbor
  ==============================  =================  ================  ===================  ========  ========  =============================================
  
  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
         The azimuth/orientation of the neighboring building must match the azimuth/orientation of at least one wall in the home, otherwise an error will be thrown.
  .. [#] If Height not provided, assumed to be same height as the dwelling unit.

.. _buildingoccupancy:

HPXML Building Occupancy
************************

Building occupancy is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy``.

  ========================================  ========  =====  ===========  ========  ========  ========================
  Element                                   Type      Units  Constraints  Required  Default   Notes
  ========================================  ========  =====  ===========  ========  ========  ========================
  ``NumberofResidents``                     double           >= 0         No        See [#]_  Number of occupants
  ``extension/WeekdayScheduleFractions``    array                         No        See [#]_  24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``    array                         No                  24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``  array                         No        See [#]_  12 comma-separated monthly multipliers
  ========================================  ========  =====  ===========  ========  ========  ========================

  .. [#] | If NumberofResidents not provided, an *asset* calculation is performed assuming standard occupancy, in which various end use defaults (e.g., plug loads, appliances, and hot water usage) are calculated based on NumberofBedrooms and ConditionedFloorArea per `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.
         | If NumberofResidents is provided, an *operational* calculation is instead performed in which the end use defaults are adjusted using the relationship between NumberofBedrooms and NumberofResidents from `RECS 2015 <https://www.eia.gov/consumption/residential/reports/2015/overview/>`_:
         | - **single-family detached or manufactured home**: NumberofBedrooms = -1.47 + 1.69 * NumberofResidents
         | - **single-family attached or apartment unit**: NumberofBedrooms = -0.68 + 1.09 * NumberofResidents
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figures 25 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.053, 0.025, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.018, 0.033, 0.054, 0.054, 0.054, 0.061, 0.061, 0.061".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values are used: "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0".

HPXML Building Construction
***************************

Building construction is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction``.

  =========================================================  ========  =========  =================================  ========  ========  =======================================================================
  Element                                                    Type      Units      Constraints                        Required  Default   Notes
  =========================================================  ========  =========  =================================  ========  ========  =======================================================================
  ``ResidentialFacilityType``                                string               See [#]_                           Yes                 Type of dwelling unit
  ``NumberofUnits``                                          integer              >= 1                               No        1         Unit multiplier [#]_
  ``NumberofConditionedFloors``                              double               > 0                                Yes                 Number of conditioned floors (including a conditioned basement; excluding a conditioned crawlspace)
  ``NumberofConditionedFloorsAboveGrade``                    double               > 0, <= NumberofConditionedFloors  Yes                 Number of conditioned floors above grade (including a walkout basement)
  ``NumberofBedrooms``                                       integer              >= 0                               Yes                 Number of bedrooms
  ``NumberofBathrooms``                                      integer              > 0                                No        See [#]_  Number of bathrooms
  ``ConditionedFloorArea``                                   double    ft2        > 0                                Yes                 Floor area within conditioned space boundary (excluding conditioned crawlspace floor area)
  ``ConditionedBuildingVolume`` or ``AverageCeilingHeight``  double    ft3 or ft  > 0                                No        See [#]_  Volume/ceiling height within conditioned space boundary (including a conditioned basement/crawlspace)
  =========================================================  ========  =========  =================================  ========  ========  =======================================================================

  .. [#] ResidentialFacilityType choices are "single-family detached", "single-family attached", "apartment unit", or "manufactured home".
  .. [#] NumberofUnits defines the number of similar dwelling units represented by the HPXML ``Building`` element.
         EnergyPlus simulation results will be multiplied by this value.
         For example, when modeling :ref:`bldg_type_bldgs`, this allows modeling *unique* dwelling units, rather than *all* dwelling units, to reduce simulation runtime.
  .. [#] If NumberofBathrooms not provided, calculated as NumberofBedrooms/2 + 0.5 based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If neither ConditionedBuildingVolume nor AverageCeilingHeight provided, AverageCeilingHeight defaults to the lesser of 8.0 and InfiltrationVolume / ConditionedFloorArea.
         If needed, additional defaulting is performed using the following relationship: ConditionedBuildingVolume = ConditionedFloorArea * AverageCeilingHeight + ConditionedCrawlspaceVolume.

HPXML Schedules
***************

Schedules for a variety of building features can be 1) specified via simple inputs, 2) specified via detailed inputs, or 3) defaulted.
It is allowed to use simple, detailed, and defaulted values in the same HPXML run.

Simple Schedule Inputs
~~~~~~~~~~~~~~~~~~~~~~

Simple schedule inputs are available as weekday/weekend fractions and monthly multipliers for a variety of building characteristics.
For example, see the ``WeekdayScheduleFractions``, ``WeekendScheduleFractions``, and ``MonthlyScheduleMultipliers`` inputs for :ref:`buildingoccupancy`.

.. _detailedschedules:

Detailed Schedule Inputs
~~~~~~~~~~~~~~~~~~~~~~~~

Detailed schedule inputs allow schedule values for every hour or timestep of the simulation.
They can be used to reflect real-world or stochastic occupancy.

Detailed schedule inputs are provided via one or more CSV file that should be referenced in the HPXML file as ``/HPXML/Building/BuildingDetails/BuildingSummary/extension/SchedulesFilePath`` elements.
The column names available in the schedule CSV files are:

  ===============================  =====  =================================================================================  ===============================
  Column Name                      Units  Description                                                                        Can Be Stochastically Generated
  ===============================  =====  =================================================================================  ===============================
  ``occupants``                    frac   Occupant heat gain schedule.                                                       Yes
  ``lighting_interior``            frac   Interior lighting energy use schedule.                                             Yes
  ``lighting_exterior``            frac   Exterior lighting energy use schedule.                                             No
  ``lighting_garage``              frac   Garage lighting energy use schedule.                                               Yes
  ``lighting_exterior_holiday``    frac   Exterior holiday lighting energy use schedule.                                     No
  ``cooking_range``                frac   Cooking range & oven energy use schedule.                                          Yes
  ``refrigerator``                 frac   Primary refrigerator energy use schedule.                                          No
  ``extra_refrigerator``           frac   Non-primary refrigerator energy use schedule.                                      No
  ``freezer``                      frac   Freezer energy use schedule.                                                       No
  ``dishwasher``                   frac   Dishwasher energy use schedule.                                                    Yes
  ``clothes_washer``               frac   Clothes washer energy use schedule.                                                Yes
  ``clothes_dryer``                frac   Clothes dryer energy use schedule.                                                 Yes
  ``ceiling_fan``                  frac   Ceiling fan energy use schedule.                                                   Yes
  ``plug_loads_other``             frac   Other plug load energy use schedule.                                               Yes
  ``plug_loads_tv``                frac   Television plug load energy use schedule.                                          Yes
  ``plug_loads_vehicle``           frac   Electric vehicle plug load energy use schedule.                                    No
  ``plug_loads_well_pump``         frac   Well pump plug load energy use schedule.                                           No
  ``fuel_loads_grill``             frac   Grill fuel load energy use schedule.                                               No
  ``fuel_loads_lighting``          frac   Lighting fuel load energy use schedule.                                            No
  ``fuel_loads_fireplace``         frac   Fireplace fuel load energy use schedule.                                           No
  ``pool_pump``                    frac   Pool pump energy use schedule.                                                     No
  ``pool_heater``                  frac   Pool heater energy use schedule.                                                   No
  ``permanent_spa_pump``           frac   Permanent spa pump energy use schedule.                                            No
  ``permanent_spa_heater``         frac   Permanent spa heater energy use schedule.                                          No
  ``hot_water_dishwasher``         frac   Dishwasher hot water use schedule.                                                 Yes
  ``hot_water_clothes_washer``     frac   Clothes washer hot water use schedule.                                             Yes
  ``hot_water_fixtures``           frac   Fixtures (sinks, showers, baths) hot water use schedule.                           Yes
  ``heating_setpoint``             F      Thermostat heating setpoint schedule.                                              No
  ``cooling_setpoint``             F      Thermostat cooling setpoint schedule.                                              No
  ``water_heater_setpoint``        F      Water heater setpoint schedule.                                                    No
  ``water_heater_operating_mode``  0/1    Heat pump water heater operating mode schedule. 0=hyrbid/auto, 1=heat pump only.   No
  ``battery``                      frac   Battery schedule. Positive for charging, negative for discharging.                 No
  ``vacancy``                      0/1    Vacancy schedule. 0=occupied, 1=vacant. Automatically overrides other columns.     N/A
  ``outage``                       0/1    Power outage schedule. 0=power. 1=nopower. Automatically overrides other columns.  N/A
  ===============================  =====  =================================================================================  ===============================

Columns with units of `frac` must be normalized to MAX=1; that is, these schedules only define *when* energy is used, not *how much* energy is used.
In other words, the amount of energy or hot water used in each simulation timestep is essentially the schedule value divided by the sum of all schedule values in the column, multiplied by the annual energy or hot water use.
Example schedule CSV files are provided in the ``HPXMLtoOpenStudio/resources/schedule_files`` directory.

The schedule file must have a full year of data even if the simulation is not an entire year.
Frequency of schedule values do not need to match the simulation timestep.
For example, hourly schedules can be used with a 10-minute simulation timestep, or 10-minute schedules can be used with an hourly simulation timestep.

A detailed stochastic occupancy schedule CSV file can also be automatically generated for you (see "Can Be Stochastically Generated" above for applicable columns); see the :ref:`usage_instructions` for the commands.
Inputs for the stochastic schedule generator are entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy/NumberofResidents`` and ``/HPXML/Building/Site/Address/StateCode``.
See :ref:`buildingoccupancy` and :ref:`buildingsite` for more information.

.. warning::

  For simulations with daylight saving enabled (which is the default), EnergyPlus will skip forward an hour in the CSV on the "spring forward" day and repeat an hour on the "fall back" day.

Default Schedules
~~~~~~~~~~~~~~~~~

If neither simple nor detailed inputs are provided, then schedules are defaulted.
Default schedules are typically smooth, averaged schedules.
These default schedules are described elsewhere in the documentation (e.g., see :ref:`buildingoccupancy` for the default occupant heat gain schedule).

.. _hvac_sizing_control:

HPXML HVAC Sizing Control
*************************

HVAC equipment sizing controls are entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/extension/HVACSizingControl``.

  =================================  ========  =====  ===========  ========  ========  ============================================
  Element                            Type      Units  Constraints  Required  Default   Description
  =================================  ========  =====  ===========  ========  ========  ============================================
  ``AllowIncreasedFixedCapacities``  boolean                       No        false     Logic for fixed capacity HVAC equipment [#]_
  ``HeatPumpSizingMethodology``      string           See [#]_     No        HERS      Logic for autosized heat pumps [#]_
  =================================  ========  =====  ===========  ========  ========  ============================================

  .. [#] If AllowIncreasedFixedCapacities is true, the larger of user-specified fixed capacity and design load will be used (to reduce potential for unmet loads); otherwise user-specified fixed capacity is used.
  .. [#] HeatPumpSizingMethodology choices are 'ACCA', 'HERS', or 'MaxLoad'.
  .. [#] If HeatPumpSizingMethodology is 'ACCA', autosized heat pumps have their nominal capacity sized per ACCA Manual J/S based on cooling design loads, with some oversizing allowances for larger heating design loads.
         If HeatPumpSizingMethodology is 'HERS', autosized heat pumps have their nominal capacity sized equal to the larger of heating/cooling design loads.
         If HeatPumpSizingMethodology is 'MaxLoad', autosized heat pumps have their nominal capacity sized based on the larger of heating/cooling design loads, while taking into account the heat pump's reduced capacity at the design temperature.

If any HVAC equipment is being autosized (i.e., capacities are not provided), additional inputs for ACCA Manual J can be entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/extension/HVACSizingControl/ManualJInputs``.

  =================================  ========  ======  ===========  ========  ============  ============================================
  Element                            Type      Units   Constraints  Required  Default       Description
  =================================  ========  ======  ===========  ========  ============  ============================================
  ``HeatingDesignTemperature``       double    F                    No        See [#]_      Heating design temperature
  ``CoolingDesignTemperature``       double    F                    No        See [#]_      Cooling design temperature
  ``HeatingSetpoint``                double    F                    No        70            Conditioned space heating setpoint [#]_
  ``CoolingSetpoint``                double    F                    No        75            Conditioned space cooling setpoint [#]_
  ``HumiditySetpoint``               double    frac    0 - 1        No        See [#]_      Conditioned space relative humidity
  ``InternalLoadsSensible``          double    Btu/hr               No        See [#]_      Sensible internal loads for cooling design load
  ``InternalLoadsLatent``            double    Btu/hr               No        0             Latent internal loads for cooling design load
  ``NumberofOccupants``              integer                        No        #Beds+1 [#]_  Number of occupants for cooling design load
  =================================  ========  ======  ===========  ========  ============  ============================================

  .. [#] If HeatingDesignTemperature not provided, the 99% heating design temperature is obtained from the DESIGN CONDITIONS header section inside the EPW weather file.
         If not available in the EPW header, it is calculated from the 8760 hourly temperatures in the EPW.
  .. [#] If CoolingDesignTemperature not provided, the 1% cooling design temperature is obtained from the DESIGN CONDITIONS header section inside the EPW weather file.
         If not available in the EPW header, it is calculated from the 8760 hourly temperatures in the EPW.
  .. [#] Any heating setpoint other than 70F is not in compliance with Manual J.
  .. [#] Any cooling setpoint other than 75F is not in compliance with Manual J.
  .. [#] If HumiditySetpoint not provided, defaults to 0.5 unless there is a dehumidifier with a lower setpoint, in which case that value is used.
  .. [#] If InternalLoadsSensible not provided, defaults to 2400 Btu/hr if there is one refrigerator and no freezer, or 3600 Btu/hr if two refrigerators or a freezer.
         This default represents loads that normally occur during the early evening in mid-summer.
         Additional adjustments or custom internal loads can instead be specified here.
  .. [#] If NumberofOccupants not provided, defaults to the number of bedrooms plus one per Manual J.
         Each occupant produces an additional 230 Btu/hr sensible load and 200 Btu/hr latent load.

.. _shadingcontrol:

HPXML Shading Control
*********************

Shading controls for window and skylight summer/winter shading coefficients are entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/extension/ShadingControl``.
If not provided, summer will be default based on the cooling season defined in the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_, using monthly average temperatures.
The remainder of the year is winter.

  ====================================  ========  =======  =============  ========  =======  =====================================
  Element                               Type      Units    Constraints    Required  Default  Description
  ====================================  ========  =======  =============  ========  =======  =====================================
  ``SummerBeginMonth``                  integer            1 - 12         Yes                Summer shading start date
  ``SummerBeginDayOfMonth``             integer            1 - 31         Yes                Summer shading start date
  ``SummerEndMonth``                    integer            1 - 12         Yes                Summer shading end date
  ``SummerEndDayOfMonth``               integer            1 - 31         Yes                Summer shading end date
  ====================================  ========  =======  =============  ========  =======  =====================================

HPXML Climate Zones
-------------------

HPXML Climate Zone IECC
***********************

Climate zone information can be optionally entered as an ``/HPXML/Building/BuildingDetails/ClimateandRiskZones/ClimateZoneIECC``.

  =================================  ========  =====  ===========  ========  ========  ===============
  Element                            Type      Units  Constraints  Required  Default   Description
  =================================  ========  =====  ===========  ========  ========  ===============
  ``Year``                           integer          See [#]_     Yes                 IECC year
  ``ClimateZone``                    string           See [#]_     Yes                 IECC zone
  =================================  ========  =====  ===========  ========  ========  ===============

  .. [#] Year choices are 2003, 2006, 2009, 2012, 2015, 2018, or 2021.
  .. [#] ClimateZone choices are "1A", "1B", "1C", "2A", "2B", "2C", "3A", "3B", "3C", "4A", "4B", "4C", "5A", "5B", "5C", "6A", "6B", "6C", "7", or "8".

If Climate zone information not provided, defaults according to the EPW weather file header.

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

.. _air_infiltration:

HPXML Air Infiltration
**********************

Building air leakage is entered in ``/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement``.

  =====================================  ======  =====  ===========  =========  =========================  ===============================================
  Element                                Type    Units  Constraints  Required   Default                    Notes
  =====================================  ======  =====  ===========  =========  =========================  ===============================================
  ``SystemIdentifier``                   id                          Yes                                   Unique identifier
  ``TypeOfInfiltrationLeakage``          string         See [#]_     See [#]_                              Type of infiltration leakage
  ``InfiltrationVolume``                 double  ft3    > 0          No         ConditionedBuildingVolume  Volume associated with infiltration measurement
  ``InfiltrationHeight``                 double  ft     > 0          No         See [#]_                   Height associated with infiltration measurement [#]_
  ``extension/Aext``                     double  frac   > 0          No         See [#]_                   Exterior area ratio for SFA/MF dwelling units
  =====================================  ======  =====  ===========  =========  =========================  ===============================================

  .. [#] TypeOfInfiltrationLeakage choices are "unit total" or "unit exterior only".
  .. [#] TypeOfInfiltrationLeakage required if single-family attached or apartment unit.
         Use "unit total" if the provided infiltration value represents the total infiltration to the dwelling unit, as measured by a compartmentalization test, in which case it will be adjusted by ``extension/Aext``.
         Use "unit exterior only" if the provided infiltration value represents the infiltration to the dwelling unit from outside only, as measured by a guarded test.
  .. [#] If InfiltrationHeight not provided, it is inferred from other inputs (e.g., conditioned floor area, number of conditioned floors above-grade, above-grade foundation wall height, etc.).
  .. [#] InfiltrationHeight is defined as the vertical distance between the lowest and highest above-grade points within the pressure boundary, per ASHRAE 62.2.
  .. [#] If Aext not provided and TypeOfInfiltrationLeakage is "unit total", defaults for single-family attached and apartment units to the ratio of exterior (adjacent to outside) envelope surface area to total (adjacent to outside, other dwelling units, or other MF spaces) envelope surface area, as defined by `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_ and `ASHRAE 62.2-2019 <https://www.techstreet.com/ashrae/standards/ashrae-62-2-2019?product_id=2087691>`_.
         Note that all attached surfaces, even adiabatic surfaces, must be defined in the HPXML file.
         If single-family detached or TypeOfInfiltrationLeakage is "unit exterior only", Aext is 1.

In addition, one of the following air leakage types must also be defined:

- :ref:`infil_ach_cfm`
- :ref:`infil_natural_ach_cfm`
- :ref:`infil_ela`

.. note::

  Infiltration airflow rates are calculated using the `Alberta Air Infiltration Model (AIM-2) <https://www.aivc.org/sites/default/files/airbase_3705.pdf>`_ (also known as the ASHRAE Enhanced model).
  When there is a flue or chimney present (see :ref:`flueorchimney`) with combustion air from conditioned space, higher infiltration airflow rates are modeled because the flue leakage is at a different height for stack effect.

.. _infil_ach_cfm:

ACH or CFM
~~~~~~~~~~

If entering air leakage as ACH or CFM at a user-specific pressure, additional information is entered in ``/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement``.
For example, ACH50 (ACH at 50 Pascals) is a commonly obtained value from a blower door measurement.

  ====================================  ======  =====  ===========  =========  =======  ===============================================
  Element                               Type    Units  Constraints  Required   Default  Notes
  ====================================  ======  =====  ===========  =========  =======  ===============================================
  ``BuildingAirLeakage/UnitofMeasure``  string         See [#]_     Yes                 Units for air leakage
  ``HousePressure``                     double  Pa     > 0          Yes                 House pressure with respect to outside [#]_
  ``BuildingAirLeakage/AirLeakage``     double         > 0          Yes                 Value for air leakage
  ====================================  ======  =====  ===========  =========  =======  ===============================================

  .. [#] UnitofMeasure choices are "ACH" or "CFM".
  .. [#] HousePressure typical value is 50 Pa.

.. _infil_natural_ach_cfm:

Natural ACH or CFM
~~~~~~~~~~~~~~~~~~

If entering air leakage as natural ACH or CFM, additional information is entered in ``/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement``.
Natural ACH or CFM represents the annual average infiltration that a building will see.

  ====================================  ======  =====  ===========  =========  =======  =================================
  Element                               Type    Units  Constraints  Required   Default  Notes
  ====================================  ======  =====  ===========  =========  =======  =================================
  ``BuildingAirLeakage/UnitofMeasure``  string         See [#]_     Yes                 Units for air leakage
  ``BuildingAirLeakage/AirLeakage``     double         > 0          Yes                 Value for air leakage
  ====================================  ======  =====  ===========  =========  =======  =================================

  .. [#] UnitofMeasure choices are "ACHnatural" or "CFMnatural".

.. _infil_ela:

Effective Leakage Area
~~~~~~~~~~~~~~~~~~~~~~

If entering air leakage as Effective Leakage Area (ELA), additional information is entered in ``/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration/AirInfiltrationMeasurement``.
Effective Leakage Area is defined as the area of a special nozzle-shaped hole (similar to the inlet of a blower door fan) that would leak the same amount of air as the building does at a pressure difference of 4 Pascals.
Note that ELA is different than Equivalent Leakage Area (EqLA), which involves a sharp-edged hole at a pressure difference of 10 Pascals.

  ====================================  ======  =======  ===========  =========  =========================  ===============================================
  Element                               Type    Units    Constraints  Required   Default                    Notes
  ====================================  ======  =======  ===========  =========  =========================  ===============================================
  ``EffectiveLeakageArea``              double  sq. in.  >= 0         Yes                                   Effective leakage area value
  ====================================  ======  =======  ===========  =========  =========================  ===============================================

.. _flueorchimney:

Flue or Chimney
~~~~~~~~~~~~~~~

The presence of a flue or chimney with combustion air from conditioned space can be entered in ``/HPXML/Building/BuildingDetails/Enclosure/AirInfiltration``.

  ================================================  =======  =====  ===========  =========  ========  ===============================================
  Element                                           Type     Units  Constraints  Required   Default   Notes
  ================================================  =======  =====  ===========  =========  ========  ===============================================
  ``extension/HasFlueOrChimneyInConditionedSpace``  boolean                      No         See [#]_  Flue or chimney with combustion air from conditioned space
  ================================================  =======  =====  ===========  =========  ========  ===============================================

  .. [#] | If HasFlueOrChimneyInConditionedSpace not provided, defaults to true if any of the following conditions are met, otherwise false:
         | - heating system is non-electric Furnace, Boiler, WallFurnace, FloorFurnace, Stove, or SpaceHeater located in conditioned space and AFUE/Percent is less than 0.89,
         | - heating system is non-electric Fireplace located in conditioned space, or
         | - water heater is non-electric with energy factor (or equivalent calculated from uniform energy factor) less than 0.63 and located in conditioned space.
  
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

If the dwelling has a manufactured home belly-and-wing foundation, whether a
skirt is present can be optionally entered in
``/HPXML/Building/BuildingDetails/Enclosure/Foundations/Foundation/FoundationType/BellyAndWing/SkirtPresent``.
The default, if that value is missing, is to assume there is a skirt present and
the floors above that foundation do not have exposure to the wind. 

HPXML Roofs
***********

Each pitched or flat roof surface that is exposed to ambient conditions is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Roofs/Roof``.

For a multifamily building where the dwelling unit has another dwelling unit above it, the surface between the two dwelling units should be considered a ``Floor`` and not a ``Roof``.

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

  .. [#] InteriorAdjacentTo choices are "attic - vented", "attic - unvented", "conditioned space", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] If neither Azimuth nor Orientation provided, and it's a *pitched* roof, modeled as four surfaces of equal area facing every direction.
         Azimuth/Orientation is irrelevant for *flat* roofs.
  .. [#] RoofType choices are "asphalt or fiberglass shingles", "wood shingles or shakes", "shingles", "slate or tile shingles", "metal surfacing", "plastic/rubber/synthetic sheeting", "expanded polystyrene sheathing", "concrete", or "cool roof".
  .. [#] RoofColor choices are "light", "medium", "medium dark", "dark", or "reflective".
  .. [#] | If SolarAbsorptance not provided, defaults based on RoofType and RoofColor:
         | - **asphalt or fiberglass shingles**: dark=0.92, medium dark=0.89, medium=0.85, light=0.75, reflective=0.50
         | - **wood shingles or shakes**: dark=0.92, medium dark=0.89, medium=0.85, light=0.75, reflective=0.50
         | - **shingles**: dark=0.92, medium dark=0.89, medium=0.85, light=0.75, reflective=0.50
         | - **slate or tile shingles**: dark=0.90, medium dark=0.83, medium=0.75, light=0.60, reflective=0.30
         | - **metal surfacing**: dark=0.90, medium dark=0.83, medium=0.75, light=0.60, reflective=0.30
         | - **plastic/rubber/synthetic sheeting**: dark=0.90, medium dark=0.83, medium=0.75, light=0.60, reflective=0.30
         | - **expanded polystyrene sheathing**: dark=0.92, medium dark=0.89, medium=0.85, light=0.75, reflective=0.50
         | - **concrete**: dark=0.90, medium dark=0.83, medium=0.75, light=0.65, reflective=0.50
         | - **cool roof**: 0.30
  .. [#] InteriorFinish/Type choices are "gypsum board", "gypsum composite board", "plaster", "wood", "other", or "none".
  .. [#] InteriorFinish/Type defaults to "gypsum board" if InteriorAdjacentTo is conditioned space, otherwise "none".
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
  .. [#] InteriorAdjacentTo choices are "conditioned space", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] If neither Azimuth nor Orientation provided, and it's an *exterior* rim joist, modeled as four surfaces of equal area facing every direction.
         Azimuth/Orientation is irrelevant for *interior* rim joists.
  .. [#] Siding choices are "wood siding", "vinyl siding", "stucco", "fiber cement siding", "brick veneer", "aluminum siding", "masonite siding", "composite shingle siding", "asbestos siding", "synthetic stucco", or "none".
  .. [#] Color choices are "light", "medium", "medium dark", "dark", or "reflective".
  .. [#] | If SolarAbsorptance not provided, defaults based on Color:
         | - **dark**: 0.95
         | - **medium dark**: 0.85
         | - **medium**: 0.70
         | - **light**: 0.50
         | - **reflective**: 0.30
  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior air films, and insulation installation grade.

HPXML Walls
***********

Each wall surface not attached to a foundation space is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Walls/Wall``.

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
  .. [#] InteriorAdjacentTo choices are "conditioned space", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] WallType child element choices are ``WoodStud``, ``DoubleWoodStud``, ``ConcreteMasonryUnit``, ``StructuralInsulatedPanel``, ``InsulatedConcreteForms``, ``SteelFrame``, ``SolidConcrete``, ``StructuralBrick``, ``StrawBale``, ``Stone``, ``LogWall``, or ``Adobe``.
  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] If neither Azimuth nor Orientation provided, and it's an *exterior* wall, modeled as four surfaces of equal area facing every direction.
         Azimuth/Orientation is irrelevant for *interior* walls (e.g., between conditioned space and garage).
  .. [#] Siding choices are "wood siding", "vinyl siding", "stucco", "fiber cement siding", "brick veneer", "aluminum siding", "masonite siding", "composite shingle siding", "asbestos siding", "synthetic stucco", or "none".
  .. [#] Color choices are "light", "medium", "medium dark", "dark", or "reflective".
  .. [#] | If SolarAbsorptance not provided, defaults based on Color:
         | - **dark**: 0.95
         | - **medium dark**: 0.85
         | - **medium**: 0.70
         | - **light**: 0.50
         | - **reflective**: 0.30
  .. [#] InteriorFinish/Type choices are "gypsum board", "gypsum composite board", "plaster", "wood", "other", or "none".
  .. [#] InteriorFinish/Type defaults to "gypsum board" if InteriorAdjacentTo is conditioned space or basement - conditioned, otherwise "none".
  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior air films, and insulation installation grade.

HPXML Foundation Walls
**********************

Each wall surface attached to a foundation space is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall``.

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
  ``Thickness``                                                   double             in                > 0                  No         8.0             Thickness excluding interior framing
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
  .. [#] If neither Azimuth nor Orientation provided, and it's an *exterior* foundation wall, modeled as four surfaces of equal area facing every direction.
         Azimuth/Orientation is irrelevant for *interior* foundation walls (e.g., between basement and garage).
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

HPXML Floors
************

Each floor/ceiling surface that is not in contact with the ground (Slab) nor adjacent to ambient conditions above (Roof) is entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Floors/Floor``.

  ======================================  ========  ============  ===========  ========  ========  ============================
  Element                                 Type      Units         Constraints  Required  Default   Notes
  ======================================  ========  ============  ===========  ========  ========  ============================
  ``SystemIdentifier``                    id                                   Yes                 Unique identifier
  ``ExteriorAdjacentTo``                  string                  See [#]_     Yes                 Exterior adjacent space type
  ``InteriorAdjacentTo``                  string                  See [#]_     Yes                 Interior adjacent space type
  ``FloorType``                           element                 1 [#]_       Yes                 Floor type (for thermal mass)
  ``Area``                                double    ft2           > 0          Yes                 Gross area
  ``InteriorFinish/Type``                 string                  See [#]_     No        See [#]_  Interior finish material
  ``InteriorFinish/Thickness``            double    in            >= 0         No        0.5       Interior finish thickness
  ``Insulation/SystemIdentifier``         id                                   Yes                 Unique identifier
  ``Insulation/AssemblyEffectiveRValue``  double    F-ft2-hr/Btu  > 0          Yes                 Assembly R-value [#]_
  ======================================  ========  ============  ===========  ========  ========  ============================

  .. [#] ExteriorAdjacentTo choices are "outside", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space", or "manufactured home underbelly".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] InteriorAdjacentTo choices are "conditioned space", "attic - vented", "attic - unvented", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] FloorType child element choices are ``WoodFrame``, ``StructuralInsulatedPanel``, ``SteelFrame``, or ``SolidConcrete``.
  .. [#] InteriorFinish/Type choices are "gypsum board", "gypsum composite board", "plaster", "wood", "other", or "none".
  .. [#] InteriorFinish/Type defaults to "gypsum board" if InteriorAdjacentTo is conditioned space and the surface is a ceiling, otherwise "none".
  .. [#] AssemblyEffectiveRValue includes all material layers, interior/exterior
    air films, and insulation installation grade. For a manufactured home belly
    where the area of the belly wrap is different and usually greater than the
    floor area, the AssemblyEffectiveRValue should be adjusted to account for
    the surface area of the belly wrap and insulation.

For floors adjacent to "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space", additional information is entered in ``Floor``.

  ======================================  ========  =====  ==============  ========  =======  ==========================================
  Element                                 Type      Units  Constraints     Required  Default  Notes
  ======================================  ========  =====  ==============  ========  =======  ==========================================
  ``FloorOrCeiling``                      string           See [#]_        Yes                Specifies whether a floor or ceiling from the perspective of the conditioned space
  ======================================  ========  =====  ==============  ========  =======  ==========================================

  .. [#] FloorOrCeiling choices are "floor" or "ceiling".

HPXML Slabs
***********

Each space type that borders the ground (i.e., basement, crawlspace, garage, and slab-on-grade foundation) should have a slab entered as an ``/HPXML/Building/BuildingDetails/Enclosure/Slabs/Slab``.

  =======================================================  ========  ============  ===========  =========  ========  ====================================================
  Element                                                  Type      Units         Constraints  Required   Default   Notes
  =======================================================  ========  ============  ===========  =========  ========  ====================================================
  ``SystemIdentifier``                                     id                                   Yes                  Unique identifier
  ``InteriorAdjacentTo``                                   string                  See [#]_     Yes                  Interior adjacent space type
  ``Area``                                                 double    ft2           > 0          Yes                  Gross area
  ``Thickness``                                            double    in            >= 0         No         See [#]_  Thickness [#]_
  ``ExposedPerimeter``                                     double    ft            >= 0         Yes                  Perimeter exposed to ambient conditions [#]_
  ``DepthBelowGrade``                                      double    ft            >= 0         No         See [#]_  Depth from the top of the slab surface to grade
  ``PerimeterInsulation/SystemIdentifier``                 id                                   Yes                  Unique identifier
  ``PerimeterInsulation/Layer/NominalRValue``              double    F-ft2-hr/Btu  >= 0         Yes                  R-value of vertical insulation
  ``PerimeterInsulation/Layer/InsulationDepth``            double    ft            >= 0         Yes                  Depth from top of slab to bottom of vertical insulation
  ``UnderSlabInsulation/SystemIdentifier``                 id                                   Yes                  Unique identifier
  ``UnderSlabInsulation/Layer/NominalRValue``              double    F-ft2-hr/Btu  >= 0         Yes                  R-value of horizontal insulation
  ``UnderSlabInsulation/Layer/InsulationWidth``            double    ft            >= 0         See [#]_             Width from slab edge inward of horizontal insulation
  ``UnderSlabInsulation/Layer/InsulationSpansEntireSlab``  boolean                              See [#]_             Whether horizontal insulation spans entire slab
  ``extension/CarpetFraction``                             double    frac          0 - 1        No         See [#]_  Fraction of slab covered by carpet
  ``extension/CarpetRValue``                               double    F-ft2-hr/Btu  >= 0         No         See [#]_  Carpet R-value
  =======================================================  ========  ============  ===========  =========  ========  ====================================================

  .. [#] InteriorAdjacentTo choices are "conditioned space", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", or "garage".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If Thickness not provided, defaults to 0 when adjacent to crawlspace and 4 inches for all other cases.
  .. [#] For a crawlspace with a dirt floor, enter a thickness of zero.
  .. [#] ExposedPerimeter includes any slab length that falls along the perimeter of the building's footprint (i.e., is exposed to ambient conditions).
         So a basement slab edge adjacent to a garage or crawlspace, for example, should not be included.
  .. [#] If DepthBelowGrade not provided, defaults to zero for foundation types without walls.
         For foundation types with walls, DepthBelowGrade is ignored as the slab's position relative to grade is determined by the ``FoundationWall/DepthBelowGrade`` value(s).
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
  ``UFactor`` and/or ``GlassLayers``            double or string   Btu/F-ft2-hr      > 0 or See [#]_      Yes                  Full-assembly NFRC U-factor or glass layers description
  ``SHGC`` and/or ``GlassLayers``               double or string                     0 - 1                Yes                  Full-assembly NFRC solar heat gain coefficient or glass layers description
  ``ExteriorShading/SummerShadingCoefficient``  double             frac              0 - 1                No        1.00       Exterior summer shading coefficient (1=transparent, 0=opaque) [#]_
  ``ExteriorShading/WinterShadingCoefficient``  double             frac              0 - 1                No        1.00       Exterior winter shading coefficient (1=transparent, 0=opaque)
  ``InteriorShading/SummerShadingCoefficient``  double             frac              0 - 1                No        0.70 [#]_  Interior summer shading coefficient (1=transparent, 0=opaque)
  ``InteriorShading/WinterShadingCoefficient``  double             frac              0 - 1                No        0.85 [#]_  Interior winter shading coefficient (1=transparent, 0=opaque)
  ``StormWindow/GlassType``                     string                               See [#]_             No                   Type of storm window glass
  ``Overhangs``                                 element                              0 - 1                No        <none>     Presence of overhangs (including roof eaves)
  ``FractionOperable``                          double             frac              0 - 1                No        0.67       Operable fraction [#]_
  ``AttachedToWall``                            idref                                See [#]_             Yes                  ID of attached wall
  ============================================  =================  ================  ===================  ========  =========  =============================================================

  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north".
  .. [#] GlassLayers choices are "single-pane", "double-pane", "triple-pane", or "glass block".
  .. [#] Summer vs winter shading seasons are determined per :ref:`shadingcontrol`.
  .. [#] InteriorShading/SummerShadingCoefficient default value indicates 30% reduction in solar heat gain, based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.
  .. [#] InteriorShading/WinterShadingCoefficient default value indicates 15% reduction in solar heat gain, based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.
  .. [#] | GlassType choices are "clear" or "low-e". The ``UFactor`` and ``SHGC`` of the window will be adjusted depending on the ``GlassType``, based on correlations derived using `data reported by PNNL <https://labhomes.pnnl.gov/documents/PNNL_24444_Thermal_and_Optical_Properties_Low-E_Storm_Windows_Panels.pdf>`_. 
         | - **clear storm windows**: U-factor = U-factor of base window - (0.6435 * U-factor of base window - 0.1533); SHGC = 0.9 * SHGC of base window
         | - **low-e storm windows**: U-factor = U-factor of base window - (0.766 * U-factor of base window - 0.1532); SHGC = 0.8 * SHGC of base window
         | Note that a storm window is not allowed for a window with U-factor lower than 0.45.
  .. [#] FractionOperable reflects whether the windows are operable (can be opened), not how they are used by the occupants.
         If a ``Window`` represents a single window, the value should be 0 or 1.
         If a ``Window`` represents multiple windows (e.g., 4), the value should be between 0 and 1 (e.g., 0, 0.25, 0.5, 0.75, or 1).
         The total open window area for natural ventilation is calculated using A) the operable fraction, B) the assumption that 50% of the area of operable windows can be open, and C) the assumption that 20% of that openable area is actually opened by occupants whenever outdoor conditions are favorable for cooling.
  .. [#] AttachedToWall must reference a ``Wall`` or ``FoundationWall``.

If operable windows are defined, the availability of natural ventilation is entered in ``/HPXML/Building/BuildingDetails/BuildingSummary/extension``.

  =============================================  ========  =========  ===========  ========  ========  ========================================================
  Element                                        Type      Units      Constraints  Required  Default   Notes
  =============================================  ========  =========  ===========  ========  ========  ========================================================
  ``NaturalVentilationAvailabilityDaysperWeek``  integer   days/week  0 - 7        No        3 [#]_    How often windows can be opened by occupants for natural ventilation
  =============================================  ========  =========  ===========  ========  ========  ========================================================

  .. [#] Default of 3 days per week (Monday/Wednesday/Friday) is based on `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

If UFactor and SHGC are not provided and GlassLayers is not "glass block", additional information is entered in ``Window``.

  ============================  ========  ======  =======================  ========  ========  ========================================================
  Element                       Type      Units   Constraints              Required  Default   Notes
  ============================  ========  ======  =======================  ========  ========  ========================================================
  ``FrameType``                 element           See [#]_                 Yes                 Type of frame
  ``FrameType/*/ThermalBreak``  boolean           See [#]_                 No        false     Whether the Aluminum or Metal frame has a thermal break
  ``GlassType``                 string            See [#]_                 No        clear     Type of glass
  ``GasFill``                   string            See [#]_                 No        See [#]_  Type of gas inside double/triple-pane windows
  ============================  ========  ======  =======================  ========  ========  ========================================================
  
  .. [#] FrameType child element choices are ``Aluminum``, ``Fiberglass``, ``Metal``, ``Vinyl``, or ``Wood``.
  .. [#] ThermalBreak is only valid if FrameType is ``Aluminum`` or ``Metal``.
  .. [#] GlassType choices are "clear", "low-e", "tinted", "tinted/reflective", or "reflective".
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
  ``Depth``                     double    ft      >= 0         Yes                Depth of overhang
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
  ``ExteriorShading/SummerShadingCoefficient``  double             frac              0 - 1                No        1.00       Exterior summer shading coefficient (1=transparent, 0=opaque) [#]_
  ``ExteriorShading/WinterShadingCoefficient``  double             frac              0 - 1                No        1.00       Exterior winter shading coefficient (1=transparent, 0=opaque)
  ``InteriorShading/SummerShadingCoefficient``  double             frac              0 - 1                No        1.00       Interior summer shading coefficient (1=transparent, 0=opaque)
  ``InteriorShading/WinterShadingCoefficient``  double             frac              0 - 1                No        1.00       Interior winter shading coefficient (1=transparent, 0=opaque)
  ``StormWindow/GlassType``                     string                               See [#]_             No                   Type of storm window glass
  ``AttachedToRoof``                            idref                                See [#]_             Yes                  ID of attached roof
  ============================================  =================  ================  ===================  ========  =========  =============================================================

  .. [#] Orientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] GlassLayers choices are "single-pane", "double-pane", or "triple-pane".
  .. [#] Summer vs winter shading seasons are determined per :ref:`shadingcontrol`.
  .. [#] | GlassType choices are "clear" or "low-e". The ``UFactor`` and ``SHGC`` of the skylight will be adjusted depending on the ``GlassType``, based on correlations derived using `data reported by PNNL <https://labhomes.pnnl.gov/documents/PNNL_24444_Thermal_and_Optical_Properties_Low-E_Storm_Windows_Panels.pdf>`_. 
         | - **clear storm windows**: U-factor = U-factor of base window - (0.6435 * U-factor of base window - 0.1533); SHGC = 0.9 * SHGC of base window
         | - **low-e storm windows**: U-factor = U-factor of base window - (0.766 * U-factor of base window - 0.1532); SHGC = 0.8 * SHGC of base window
         | Note that a storm window is not allowed for a skylight with U-factor lower than 0.45.
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

  =================================  ========  ======  ===========  ========  ==============  ===============================
  Element                            Type      Units   Constraints  Required  Default         Notes
  =================================  ========  ======  ===========  ========  ==============  ===============================
  ``SystemIdentifier``               id                             Yes                       Unique identifier
  ``UnitLocation``                   string            See [#]_     No        See [#]_        Location of heating system (e.g., air handler)
  ``HeatingSystemType``              element           1 [#]_       Yes                       Type of heating system
  ``HeatingSystemFuel``              string            See [#]_     Yes                       Fuel type
  ``HeatingCapacity``                double    Btu/hr  >= 0         No        autosized [#]_  Heating output capacity
  ``FractionHeatLoadServed``         double    frac    0 - 1 [#]_   See [#]_                  Fraction of heating load served
  =================================  ========  ======  ===========  ========  ==============  ===============================

  .. [#] UnitLocation choices are "conditioned space", "basement - unconditioned", "basement - conditioned", "attic - unvented", "attic - vented", "garage", "crawlspace - unvented", "crawlspace - vented", "crawlspace - conditioned", "other exterior", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space", "roof deck", "manufactured home belly", or "unconditioned space".
  .. [#] | If UnitLocation not provided, defaults based on the distribution system:
         | - **none**: "conditioned space"
         | - **air**: supply duct location with the largest area, otherwise "conditioned space"
         | - **hydronic**: same default logic as :ref:`waterheatingsystems`
         | - **dse**: "conditioned space" if ``FractionHeatLoadServed`` is 1, otherwise "unconditioned space"
  .. [#] HeatingSystemType child element choices are ``ElectricResistance``, ``Furnace``, ``WallFurnace``, ``FloorFurnace``, ``Boiler``, ``Stove``, ``SpaceHeater``, or ``Fireplace``.
  .. [#] HeatingSystemFuel choices are "electricity", "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "wood", or "wood pellets".
         For ``ElectricResistance``, "electricity" is required.
  .. [#] Heating capacity autosized per ACCA Manual J/S based on heating design load.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across all HVAC systems) must be less than or equal to 1.
  .. [#] FractionHeatLoadServed is required unless the heating system is a heat pump backup system (i.e., referenced by a ``HeatPump[BackupType="separate"]/BackupSystem``; see :ref:`hvac_heatpump`), in which case FractionHeatLoadServed is not allowed.
         Heat pump backup will only operate during colder temperatures when the heat pump runs out of heating capacity or is disabled due to a switchover/lockout temperature.

Electric Resistance
~~~~~~~~~~~~~~~~~~~

If electric resistance heating is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =====  ===========  ========  =======  ==========
  Element                                             Type    Units  Constraints  Required  Default  Notes
  ==================================================  ======  =====  ===========  ========  =======  ==========
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac   0 - 1        Yes                Efficiency
  ==================================================  ======  =====  ===========  ========  =======  ==========

Furnace
~~~~~~~

If a furnace is specified, additional information is entered in ``HeatingSystem``.

  ======================================================  =======  =========  ===========  ========  ========  ================================================
  Element                                                 Type     Units      Constraints  Required  Default   Notes
  ======================================================  =======  =========  ===========  ========  ========  ================================================
  ``DistributionSystem``                                  idref    See [#]_                Yes                 ID of attached distribution system
  ``HeatingSystemType/Furnace/PilotLight``                boolean                          No        false     Presence of standing pilot light (older systems)
  ``HeatingSystemType/Furnace/extension/PilotLightBtuh``  double   Btu/hr     >= 0         No        500       Pilot light burn rate
  ``AnnualHeatingEfficiency[Units="AFUE"]/Value``         double   frac       0 - 1        Yes                 Rated efficiency
  ``extension/FanPowerWattsPerCFM``                       double   W/cfm      >= 0         No        See [#]_  Blower fan efficiency at maximum fan speed [#]_
  ``extension/AirflowDefectRatio``                        double   frac       -0.9 - 9     No        0.0       Deviation between design/installed airflows [#]_
  ======================================================  =======  =========  ===========  ========  ========  ================================================

  .. [#] HVACDistribution type must be AirDistribution (type: "regular velocity" or "gravity") or DSE.
  .. [#] If FanPowerWattsPerCFM not provided, defaulted to 0 W/cfm if gravity distribution system, else 0.5 W/cfm if AFUE <= 0.9, else 0.375 W/cfm.
  .. [#] If there is a cooling system attached to the DistributionSystem, the heating and cooling systems cannot have different values for FanPowerWattsPerCFM.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

Wall Furnace
~~~~~~~~~~~~

If a wall furnace is specified, additional information is entered in ``HeatingSystem``.

  ==========================================================  =======  ======  ===========  ========  ========  ================
  Element                                                     Type     Units   Constraints  Required  Default   Notes
  ==========================================================  =======  ======  ===========  ========  ========  ================
  ``HeatingSystemType/WallFurnace/PilotLight``                boolean                       No        false     Presence of standing pilot light (older systems)
  ``HeatingSystemType/WallFurnace/extension/PilotLightBtuh``  double   Btu/hr  >= 0         No        500       Pilot light burn rate
  ``AnnualHeatingEfficiency[Units="AFUE"]/Value``             double   frac    0 - 1        Yes                 Rated efficiency
  ``extension/FanPowerWatts``                                 double   W       >= 0         No        0         Fan power
  ==========================================================  =======  ======  ===========  ========  ========  ================

Floor Furnace
~~~~~~~~~~~~~

If a floor furnace is specified, additional information is entered in ``HeatingSystem``.

  ===========================================================  =======  ======  ===========  ========  ========  ================
  Element                                                      Type     Units   Constraints  Required  Default   Notes
  ===========================================================  =======  ======  ===========  ========  ========  ================
  ``HeatingSystemType/FloorFurnace/PilotLight``                boolean                       No        false     Presence of standing pilot light (older systems)
  ``HeatingSystemType/FloorFurnace/extension/PilotLightBtuh``  double   Btu/hr  >= 0         No        500       Pilot light burn rate
  ``AnnualHeatingEfficiency[Units="AFUE"]/Value``              double   frac    0 - 1        Yes                 Rated efficiency
  ``extension/FanPowerWatts``                                  double   W       >= 0         No        0         Fan power
  ===========================================================  =======  ======  ===========  ========  ========  ================

.. _hvac_heating_boiler:

Boiler
~~~~~~

If a boiler is specified, additional information is entered in ``HeatingSystem``.

  =====================================================  =======  =========  ===========  ========  ========  =========================================
  Element                                                Type     Units      Constraints  Required  Default   Notes
  =====================================================  =======  =========  ===========  ========  ========  =========================================
  ``IsSharedSystem``                                     boolean             No           false               Whether it serves multiple dwelling units
  ``HeatingSystemType/Boiler/PilotLight``                boolean                          No        false     Presence of standing pilot light (older systems)
  ``HeatingSystemType/Boiler/extension/PilotLightBtuh``  double   Btu/hr     >= 0         No        500       Pilot light burn rate
  ``DistributionSystem``                                 idref    See [#]_   Yes                              ID of attached distribution system
  ``AnnualHeatingEfficiency[Units="AFUE"]/Value``        double   frac       0 - 1        Yes                 Rated efficiency
  =====================================================  =======  =========  ===========  ========  ========  =========================================

  .. [#] For in-unit boilers, HVACDistribution type must be HydronicDistribution (type: "radiator", "baseboard", "radiant floor", or "radiant ceiling") or DSE.
         For shared boilers, HVACDistribution type must be HydronicDistribution (type: "radiator", "baseboard", "radiant floor", "radiant ceiling", or "water loop") or AirDistribution (type: "fan coil").
         If the shared boiler has "water loop" distribution, a :ref:`hvac_heatpump_wlhp` must also be specified.

  .. note::

    The choice of hydronic distribution type (radiator vs baseboard vs radiant panels) does not affect simulation results;
    it is currently only used to know if there's an attached water loop heat pump or not.

If an in-unit boiler if specified, additional information is entered in ``HeatingSystem``.

  ===========================  ========  ======  ===========  ========  ========  =========================
  Element                      Type      Units   Constraints  Required  Default   Notes
  ===========================  ========  ======  ===========  ========  ========  =========================
  ``ElectricAuxiliaryEnergy``  double    kWh/yr  >= 0         No        See [#]_  Electric auxiliary energy
  ===========================  ========  ======  ===========  ========  ========  =========================

  .. [#] | If ElectricAuxiliaryEnergy not provided, defaults as follows:
         | - **Oil boiler**: 330 kWh/yr
         | - **Gas boiler**: 170 kWh/yr

If instead a shared boiler is specified, additional information is entered in ``HeatingSystem``.

  ============================================================  ========  ===========  ===========  ========  ========  =========================
  Element                                                       Type      Units        Constraints  Required  Default   Notes
  ============================================================  ========  ===========  ===========  ========  ========  =========================
  ``NumberofUnitsServed``                                       integer                > 1          Yes                 Number of dwelling units served
  ``ElectricAuxiliaryEnergy`` or ``extension/SharedLoopWatts``  double    kWh/yr or W  >= 0         No        See [#]_  Electric auxiliary energy or shared loop power
  ``ElectricAuxiliaryEnergy`` or ``extension/FanCoilWatts``     double    kWh/yr or W  >= 0         No [#]_             Electric auxiliary energy or fan coil power
  ============================================================  ========  ===========  ===========  ========  ========  =========================

  .. [#] | If ElectricAuxiliaryEnergy nor SharedLoopWatts provided, defaults as follows:
         | - **Shared boiler w/ baseboard**: 220 kWh/yr
         | - **Shared boiler w/ water loop heat pump**: 265 kWh/yr
         | - **Shared boiler w/ fan coil**: 438 kWh/yr
  .. [#] FanCoilWatts only used if boiler connected to fan coil and SharedLoopWatts provided.

Stove
~~~~~

If a stove is specified, additional information is entered in ``HeatingSystem``.

  ====================================================  =======  ======  ===========  ========  =========  ===================
  Element                                               Type     Units   Constraints  Required  Default    Notes
  ====================================================  =======  ======  ===========  ========  =========  ===================
  ``HeatingSystemType/Stove/PilotLight``                boolean                       No        false      Presence of standing pilot light (older systems)
  ``HeatingSystemType/Stove/extension/PilotLightBtuh``  double   Btu/hr  >= 0         No        500        Pilot light burn rate
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``    double   frac    0 - 1        Yes                  Efficiency
  ``extension/FanPowerWatts``                           double   W       >= 0         No        40         Fan power
  ====================================================  =======  ======  ===========  ========  =========  ===================

Space Heater
~~~~~~~~~~~~

If a space heater (portable or fixed) is specified, additional information is entered in ``HeatingSystem``.

  ==================================================  ======  =====  ===========  ========  =========  ===================
  Element                                             Type    Units  Constraints  Required  Default    Notes
  ==================================================  ======  =====  ===========  ========  =========  ===================
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``  double  frac   0 - 1        Yes                  Efficiency
  ``extension/FanPowerWatts``                         double  W      >= 0         No        0          Fan power
  ==================================================  ======  =====  ===========  ========  =========  ===================

Fireplace
~~~~~~~~~

If a fireplace is specified, additional information is entered in ``HeatingSystem``.

  ========================================================  =======  ======  ===========  ========  =========  ===================
  Element                                                   Type     Units   Constraints  Required  Default    Notes
  ========================================================  =======  ======  ===========  ========  =========  ===================
  ``HeatingSystemType/Fireplace/PilotLight``                boolean                       No        false      Presence of standing pilot light (older systems)
  ``HeatingSystemType/Fireplace/extension/PilotLightBtuh``  double   Btu/hr  >= 0         No        500        Pilot light burn rate
  ``AnnualHeatingEfficiency[Units="Percent"]/Value``        double   frac    0 - 1        Yes                  Efficiency
  ``extension/FanPowerWatts``                               double   W       >= 0         No        0          Fan power
  ========================================================  =======  ======  ===========  ========  =========  ===================

.. _hvac_cooling:

HPXML Cooling Systems
*********************

Each cooling system (other than a heat pump) is entered as an ``/HPXML/Building/BuildingDetails/Systems/HVAC/HVACPlant/CoolingSystem``.

  ==========================  ========  ======  ===========  ========  ========  ===============================
  Element                     Type      Units   Constraints  Required  Default   Notes
  ==========================  ========  ======  ===========  ========  ========  ===============================
  ``SystemIdentifier``        id                             Yes                 Unique identifier
  ``UnitLocation``            string            See [#]_     No        See [#]_  Location of cooling system (e.g., air handler)
  ``CoolingSystemType``       string            See [#]_     Yes                 Type of cooling system
  ``CoolingSystemFuel``       string            See [#]_     Yes                 Fuel type
  ``FractionCoolLoadServed``  double    frac    0 - 1 [#]_   Yes                 Fraction of cooling load served
  ==========================  ========  ======  ===========  ========  ========  ===============================

  .. [#] UnitLocation choices are "conditioned space", "basement - unconditioned", "basement - conditioned", "attic - unvented", "attic - vented", "garage", "crawlspace - unvented", "crawlspace - vented", "crawlspace - conditioned", "other exterior", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space", "roof deck", "manufactured home belly", or "unconditioned space".
  .. [#] | If UnitLocation not provided, defaults based on the distribution system:
         | - **none**: "conditioned space"
         | - **air**: supply duct location with the largest area, otherwise "conditioned space"
         | - **dse**: "conditioned space" if ``FractionCoolLoadServed`` is 1, otherwise "unconditioned space"
  .. [#] CoolingSystemType choices are "central air conditioner", "room air conditioner", "evaporative cooler", "mini-split", "chiller", "cooling tower", or "packaged terminal air conditioner".
  .. [#] CoolingSystemFuel only choice is "electricity".
  .. [#] The sum of all ``FractionCoolLoadServed`` (across all HVAC systems) must be less than or equal to 1.

Central Air Conditioner
~~~~~~~~~~~~~~~~~~~~~~~

If a central air conditioner is specified, additional information is entered in ``CoolingSystem``.

  ================================================================  =======  ===========  ===========  ========  ==============  ===========================================================
  Element                                                           Type     Units        Constraints  Required  Default         Notes
  ================================================================  =======  ===========  ===========  ========  ==============  ===========================================================
  ``DistributionSystem``                                            idref    See [#]_     Yes                                    ID of attached distribution system
  ``CoolingCapacity``                                               double   Btu/hr       >= 0         No        autosized [#]_  Cooling output capacity
  ``CompressorType``                                                string                See [#]_     No        See [#]_        Type of compressor
  ``AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value``  double   Btu/Wh or #  > 0          Yes                       Rated efficiency [#]_
  ``SensibleHeatFraction``                                          double   frac         0 - 1        No        See [#]_        Sensible heat fraction
  ``CoolingDetailedPerformanceData``                                element                            No        <none>          Cooling detailed performance data [#]_
  ``extension/FanPowerWattsPerCFM``                                 double   W/cfm        >= 0         No        See [#]_        Blower fan efficiency at maximum fan speed [#]_
  ``extension/AirflowDefectRatio``                                  double   frac         -0.9 - 9     No        0.0             Deviation between design/installed airflows [#]_
  ``extension/ChargeDefectRatio``                                   double   frac         -0.9 - 9     No        0.0             Deviation between design/installed refrigerant charges [#]_
  ``extension/CrankcaseHeaterPowerWatts``                           double   W                         No        50.0            Crankcase heater power
  ================================================================  =======  ===========  ===========  ========  ==============  ===========================================================

  .. [#] HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] Cooling capacity autosized per ACCA Manual J/S based on cooling design load.
  .. [#] CompressorType choices are "single stage", "two stage", or "variable speed".
  .. [#] If CompressorType not provided, defaults to "single stage" if SEER <= 15, else "two stage" if SEER <= 21, else "variable speed".
  .. [#] If SEER2 provided, converted to SEER using ANSI/RESNET/ICC 301-2022 Addendum C, where SEER = SEER2 / 0.95 (assumed to be a split system).
  .. [#] If SensibleHeatFraction not provided, defaults to 0.73 for single/two stage and 0.78 for variable speed.
  .. [#] If CoolingDetailedPerformanceData is provided, see :ref:`clg_detailed_perf_data`.
  .. [#] If FanPowerWattsPerCFM not provided, defaults to using attached furnace W/cfm if available, else 0.5 W/cfm if SEER <= 13.5, else 0.375 W/cfm.
  .. [#] If there is a heating system attached to the DistributionSystem, the heating and cooling systems cannot have different values for FanPowerWattsPerCFM.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.
  .. [#] ChargeDefectRatio is defined as (InstalledCharge - DesignCharge) / DesignCharge; a value of zero means no refrigerant charge defect.
         A non-zero charge defect should typically only be applied for systems that are charged on site, not for systems that have pre-charged line sets.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

Room Air Conditioner
~~~~~~~~~~~~~~~~~~~~

If a room air conditioner is specified, additional information is entered in ``CoolingSystem``.

  ==================================================================  ======  ======  ===========  ========  ==============  ============================================
  Element                                                             Type    Units   Constraints  Required  Default         Notes
  ==================================================================  ======  ======  ===========  ========  ==============  ============================================
  ``CoolingCapacity``                                                 double  Btu/hr  >= 0         No        autosized [#]_  Cooling output capacity
  ``AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value``      double  Btu/Wh  > 0          Yes                       Rated efficiency
  ``SensibleHeatFraction``                                            double  frac    0 - 1        No        0.65            Sensible heat fraction
  ``IntegratedHeatingSystemFuel``                                     string          See [#]_     No        <none>          Fuel type of integrated heater
  ``extension/CrankcaseHeaterPowerWatts``                             double  W                    No        0.0             Crankcase heater power
  ==================================================================  ======  ======  ===========  ========  ==============  ============================================

  .. [#] Cooling capacity autosized per ACCA Manual J/S based on cooling design load.
  .. [#] IntegratedHeatingSystemFuel choices are "electricity", "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "wood", or "wood pellets".

If the room air conditioner has integrated heating, additional information is entered in ``CoolingSystem``.
Note that a room air conditioner with reverse cycle heating should be entered as a heat pump; see :ref:`room_ac_reverse_cycle`.

  ==================================================================  ======  ======  ===========  ========  ==============  ============================================
  Element                                                             Type    Units   Constraints  Required  Default         Notes
  ==================================================================  ======  ======  ===========  ========  ==============  ============================================
  ``IntegratedHeatingSystemCapacity``                                 double  Btu/hr  >= 0         No        autosized [#]_  Heating output capacity of integrated heater
  ``IntegratedHeatingSystemAnnualEfficiency[Units="Percent"]/Value``  double  frac    0 - 1        Yes                       Efficiency of integrated heater
  ``IntegratedHeatingSystemFractionHeatLoadServed``                   double  frac    0 - 1 [#]_   Yes                       Fraction of heating load served
  ==================================================================  ======  ======  ===========  ========  ==============  ============================================

  .. [#] Heating capacity autosized per ACCA Manual J/S based on heating design load.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across all HVAC systems) must be less than or equal to 1. 

Packaged Terminal Air Conditioner
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a PTAC is specified, additional information is entered in ``CoolingSystem``.

  ==================================================================  ======  ======  ===========  ========  ==============  ==========================================
  Element                                                             Type    Units   Constraints  Required  Default         Notes
  ==================================================================  ======  ======  ===========  ========  ==============  ==========================================
  ``CoolingCapacity``                                                 double  Btu/hr  >= 0         No        autosized [#]_  Cooling output capacity
  ``AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value``      double  Btu/Wh  > 0          Yes                       Rated efficiency
  ``SensibleHeatFraction``                                            double  frac    0 - 1        No        0.65            Sensible heat fraction
  ``IntegratedHeatingSystemFuel``                                     string          See [#]_     No        <none>          Fuel type of integrated heater
  ``extension/CrankcaseHeaterPowerWatts``                             double  W                    No        0.0             Crankcase heater power
  ==================================================================  ======  ======  ===========  ========  ==============  ==========================================

  .. [#] Cooling capacity autosized per ACCA Manual J/S based on cooling design load.
  .. [#] IntegratedHeatingSystemFuel choices are "electricity", "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "wood", or "wood pellets".

If the PTAC has integrated heating, additional information is entered in ``CoolingSystem``.
Note that a packaged terminal heat pump should be entered as a heat pump; see :ref:`pthp`.

  ==================================================================  ======  ======  ===========  ========  ==============  ============================================
  Element                                                             Type    Units   Constraints  Required  Default         Notes
  ==================================================================  ======  ======  ===========  ========  ==============  ============================================
  ``IntegratedHeatingSystemCapacity``                                 double  Btu/hr  >= 0         No        autosized [#]_  Heating output capacity of integrated heater
  ``IntegratedHeatingSystemAnnualEfficiency[Units="Percent"]/Value``  double  frac    0 - 1        Yes                       Efficiency of integrated heater
  ``IntegratedHeatingSystemFractionHeatLoadServed``                   double  frac    0 - 1 [#]_   Yes                       Fraction of heating load served
  ==================================================================  ======  ======  ===========  ========  ==============  ============================================

  .. [#] Heating capacity autosized per ACCA Manual J/S based on heating design load.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across all HVAC systems) must be less than or equal to 1. 

Evaporative Cooler
~~~~~~~~~~~~~~~~~~

If an evaporative cooler is specified, additional information is entered in ``CoolingSystem``.

  =================================  ========  ======  ===========  ========  ==============  ==================================
  Element                            Type      Units   Constraints  Required  Default         Notes
  =================================  ========  ======  ===========  ========  ==============  ==================================
  ``DistributionSystem``             idref             See [#]_     No                        ID of attached distribution system
  ``CoolingCapacity``                double    Btu/hr  >= 0         No        autosized [#]_  Cooling output capacity
  =================================  ========  ======  ===========  ========  ==============  ==================================

  .. [#] If DistributionSystem provided, HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] Cooling capacity autosized per ACCA Manual J/S based on cooling design load.

Mini-Split Air Conditioner
~~~~~~~~~~~~~~~~~~~~~~~~~~

If a mini-split air conditioner is specified, additional information is entered in ``CoolingSystem``. Each ``CoolingSystem`` is expected to represent a single outdoor unit, whether connected to one indoor head or multiple indoor heads.

  ================================================================  ========  ======  ===========  ========  ==============  ===========================================================
  Element                                                           Type      Units   Constraints  Required  Default         Notes
  ================================================================  ========  ======  ===========  ========  ==============  ===========================================================
  ``DistributionSystem``                                            idref             See [#]_     No                        ID of attached distribution system
  ``CoolingCapacity``                                               double    Btu/hr  >= 0         No        autosized [#]_  Cooling output capacity
  ``CompressorType``                                                string            See [#]_     No        variable speed  Type of compressor
  ``AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value``  double    Btu/Wh  > 0          Yes                       Rated cooling efficiency [#]_
  ``SensibleHeatFraction``                                          double    frac    0 - 1        No        0.73            Sensible heat fraction
  ``CoolingDetailedPerformanceData``                                element                        No        <none>          Cooling detailed performance data [#]_
  ``extension/FanPowerWattsPerCFM``                                 double    W/cfm   >= 0         No        See [#]_        Blower fan efficiency at maximum fan speed
  ``extension/AirflowDefectRatio``                                  double    frac    -0.9 - 9     No        0.0             Deviation between design/installed airflows [#]_
  ``extension/ChargeDefectRatio``                                   double    frac    -0.9 - 9     No        0.0             Deviation between design/installed refrigerant charges [#]_
  ``extension/CrankcaseHeaterPowerWatts``                           double    W                    No        50.0            Crankcase heater power
  ================================================================  ========  ======  ===========  ========  ==============  ===========================================================

  .. [#] If DistributionSystem provided, HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] Cooling capacity autosized per ACCA Manual J/S based on cooling design load.
  .. [#] CompressorType only choices is "variable speed" (i.e., they are assumed to be inverter driven).
  .. [#] If SEER2 provided, converted to SEER using ANSI/RESNET/ICC 301-2022 Addendum C, where SEER = SEER2 / 0.95 if ducted and SEER = SEER2 if ductless.
  .. [#] If CoolingDetailedPerformanceData is provided, see :ref:`clg_detailed_perf_data`.
  .. [#] FanPowerWattsPerCFM defaults to 0.07 W/cfm for ductless systems and 0.18 W/cfm for ducted systems.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         A non-zero airflow defect can only be applied for systems attached to a distribution system.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.
  .. [#] ChargeDefectRatio is defined as (InstalledCharge - DesignCharge) / DesignCharge; a value of zero means no refrigerant charge defect.
         A non-zero charge defect should typically only be applied for systems that are charged on site, not for systems that have pre-charged line sets.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.
 
.. _hvac_cooling_chiller:

Chiller
~~~~~~~

If a chiller is specified, additional information is entered in ``CoolingSystem``.

  ==========================================================================  ========  ======  ===========  ========  =========  =========================================
  Element                                                                     Type      Units   Constraints  Required  Default    Notes
  ==========================================================================  ========  ======  ===========  ========  =========  =========================================
  ``DistributionSystem``                                                      idref             See [#]_     Yes                  ID of attached distribution system
  ``IsSharedSystem``                                                          boolean           true         Yes                  Whether it serves multiple dwelling units
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
  ``DistributionSystem``                                                      idref             See [#]_     Yes                  ID of attached distribution system
  ``IsSharedSystem``                                                          boolean           true         Yes                  Whether it serves multiple dwelling units
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
  ``UnitLocation``                   string            See [#]_     No        See [#]_   Location of heat pump (e.g., air handler)
  ``HeatPumpType``                   string            See [#]_     Yes                  Type of heat pump
  ``HeatPumpFuel``                   string            See [#]_     Yes                  Fuel type
  ``BackupType``                     string            See [#]_     No        <none>     Type of backup heating
  =================================  ========  ======  ===========  ========  =========  ===============================================

  .. [#] UnitLocation choices are "conditioned space", "basement - unconditioned", "basement - conditioned", "attic - unvented", "attic - vented", "garage", "crawlspace - unvented", "crawlspace - vented", "crawlspace - conditioned", "other exterior", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space", "roof deck", "manufactured home belly", or "unconditioned space".
  .. [#] | If UnitLocation not provided, defaults based on the distribution system:
         | - **none**: "conditioned space"
         | - **air**: supply duct location with the largest area, otherwise "conditioned space"
         | - **hydronic**: same default logic as :ref:`waterheatingsystems`
         | - **dse**: "conditioned space" if ``FractionHeatLoadServed``/``FractionCoolLoadServed`` are 1, otherwise "unconditioned space"
  .. [#] HeatPumpType choices are "air-to-air", "mini-split", "ground-to-air", "water-loop-to-air", "packaged terminal heat pump", or "room air conditioner with reverse cycle".
  .. [#] HeatPumpFuel only choice is "electricity".
  .. [#] BackupType choices are "integrated" or "separate".
         Heat pump backup will only operate during colder temperatures when the heat pump runs out of heating capacity or is disabled due to a switchover/lockout temperature.
         Use "integrated" if the heat pump's distribution system and blower fan power applies to the backup heating (e.g., built-in electric strip heat or an integrated backup furnace, i.e., a dual-fuel heat pump).
         Use "separate" if the backup system has its own distribution system (e.g., electric baseboard or a boiler).

Air-to-Air Heat Pump
~~~~~~~~~~~~~~~~~~~~

If an air-to-air heat pump is specified, additional information is entered in ``HeatPump``.

  ================================================================  =======  ========  ========================  ========  ==============  =================================================
  Element                                                           Type     Units     Constraints               Required  Default         Notes
  ================================================================  =======  ========  ========================  ========  ==============  =================================================
  ``DistributionSystem``                                            idref              See [#]_                  Yes                       ID of attached distribution system
  ``HeatingCapacity``                                               double   Btu/hr    >= 0                      No        autosized [#]_  Heating output capacity (excluding any backup heating)
  ``HeatingCapacity17F``                                            double   Btu/hr    >= 0, <= HeatingCapacity  No                        Heating output capacity at 17F, if available
  ``CoolingCapacity``                                               double   Btu/hr    >= 0                      No        autosized [#]_  Cooling output capacity
  ``CompressorType``                                                string             See [#]_                  No        See [#]_        Type of compressor
  ``CompressorLockoutTemperature``                                  double   F                                   No        See [#]_        Minimum outdoor temperature for compressor operation
  ``CoolingSensibleHeatFraction``                                   double   frac      0 - 1                     No        See [#]_        Sensible heat fraction
  ``FractionHeatLoadServed``                                        double   frac      0 - 1 [#]_                Yes                       Fraction of heating load served
  ``FractionCoolLoadServed``                                        double   frac      0 - 1 [#]_                Yes                       Fraction of cooling load served
  ``AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value``  double   Btu/Wh    > 0                       Yes                       Rated cooling efficiency [#]_
  ``AnnualHeatingEfficiency[Units="HSPF" or Units="HSPF2"]/Value``  double   Btu/Wh    > 0                       Yes                       Rated heating efficiency [#]_
  ``CoolingDetailedPerformanceData``                                element                                      No        <none>          Cooling detailed performance data [#]_
  ``HeatingDetailedPerformanceData``                                element                                      No        <none>          Heating detailed performance data [#]_
  ``extension/HeatingCapacityRetention[Fraction | Temperature]``    double   frac | F  >= 0, < 1 | <= 17         No        See [#]_        Heating output capacity retention at cold temperature [#]_
  ``extension/FanPowerWattsPerCFM``                                 double   W/cfm     >= 0                      No        See [#]_        Blower fan efficiency at maximum fan speed
  ``extension/AirflowDefectRatio``                                  double   frac      -0.9 - 9                  No        0.0             Deviation between design/installed airflows [#]_
  ``extension/ChargeDefectRatio``                                   double   frac      -0.9 - 9                  No        0.0             Deviation between design/installed refrigerant charges [#]_
  ``extension/CrankcaseHeaterPowerWatts``                           double   W                                   No        50.0            Crankcase heater power
  ================================================================  =======  ========  ========================  ========  ==============  =================================================

  .. [#] HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] Heating capacity autosized per ACCA Manual J/S based on heating design load (unless a different HeatPumpSizingMethodology was selected in :ref:`hvac_sizing_control`).
  .. [#] Cooling capacity autosized per ACCA Manual J/S based on cooling design load (unless a different HeatPumpSizingMethodology was selected in :ref:`hvac_sizing_control`).
  .. [#] CompressorType choices are "single stage", "two stage", or "variable speed".
  .. [#] If CompressorType not provided, defaults to "single stage" if SEER <= 15, else "two stage" if SEER <= 21, else "variable speed".
  .. [#] If neither CompressorLockoutTemperature nor BackupHeatingSwitchoverTemperature provided, CompressorLockoutTemperature defaults to 25F if fossil fuel backup otherwise 0F.
  .. [#] If SensibleHeatFraction not provided, defaults to 0.73 for single/two stage and 0.78 for variable speed.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across all HVAC systems) must be less than or equal to 1.
  .. [#] The sum of all ``FractionCoolLoadServed`` (across all HVAC systems) must be less than or equal to 1.
  .. [#] If SEER2 provided, converted to SEER using ANSI/RESNET/ICC 301-2022 Addendum C, where SEER = SEER2 / 0.95 (assumed to be a split system).
  .. [#] If HSPF2 provided, converted to HSPF using ANSI/RESNET/ICC 301-2022 Addendum C, where HSPF = HSPF2 / 0.85 (assumed to be a split system).
  .. [#] If CoolingDetailedPerformanceData is provided, see :ref:`clg_detailed_perf_data`.
         HeatingDetailedPerformanceData must also be provided.
  .. [#] If HeatingDetailedPerformanceData is provided, see :ref:`htg_detailed_perf_data`.
         CoolingDetailedPerformanceData must also be provided.
  .. [#] | If neither extension/HeatingCapacityRetention nor HeatingCapacity17F nor HeatingDetailedPerformanceData provided, heating capacity retention defaults based on CompressorType:
         | - **single/two stage**: 0.425 (at 5F)
         | - **variable speed**: 0.0461 * HSPF + 0.1594 (at 5F)
  .. [#] The extension/HeatingCapacityRetention input is a more flexible alternative to HeatingCapacity17F, as it can apply to autosized systems and allows the heating capacity retention to be defined at a user-specified temperature (instead of 17F).
         Either input approach can be used, but not both.
  .. [#] If FanPowerWattsPerCFM not provided, defaulted to 0.5 W/cfm if HSPF <= 8.75, else 0.375 W/cfm.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.
  .. [#] ChargeDefectRatio is defined as (InstalledCharge - DesignCharge) / DesignCharge; a value of zero means no refrigerant charge defect.
         A non-zero charge defect should typically only be applied for systems that are charged on site, not for systems that have pre-charged line sets.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

Mini-Split Heat Pump
~~~~~~~~~~~~~~~~~~~~

If a mini-split heat pump is specified, additional information is entered in ``HeatPump``. Each ``HeatPump`` is expected to represent a single outdoor unit, whether connected to one indoor head or multiple indoor heads.

  ================================================================  ========  ========  ========================  ========  ==============  ==============================================
  Element                                                           Type      Units     Constraints               Required  Default         Notes
  ================================================================  ========  ========  ========================  ========  ==============  ==============================================
  ``DistributionSystem``                                            idref               See [#]_                  No                        ID of attached distribution system, if present
  ``HeatingCapacity``                                               double    Btu/hr    >= 0                      No        autosized [#]_  Heating output capacity (excluding any backup heating)
  ``HeatingCapacity17F``                                            double    Btu/hr    >= 0, <= HeatingCapacity  No                        Heating output capacity at 17F, if available
  ``CoolingCapacity``                                               double    Btu/hr    >= 0                      No        autosized [#]_  Cooling output capacity
  ``CompressorType``                                                string              See [#]_                  No        variable speed  Type of compressor
  ``CompressorLockoutTemperature``                                  double    F                                   No        See [#]_        Minimum outdoor temperature for compressor operation
  ``CoolingSensibleHeatFraction``                                   double    frac      0 - 1                     No        0.73            Sensible heat fraction
  ``FractionHeatLoadServed``                                        double    frac      0 - 1 [#]_                Yes                       Fraction of heating load served
  ``FractionCoolLoadServed``                                        double    frac      0 - 1 [#]_                Yes                       Fraction of cooling load served
  ``AnnualCoolingEfficiency[Units="SEER" or Units="SEER2"]/Value``  double    Btu/Wh    > 0                       Yes                       Rated cooling efficiency [#]_
  ``AnnualHeatingEfficiency[Units="HSPF" or Units="HSPF2"]/Value``  double    Btu/Wh    > 0                       Yes                       Rated heating efficiency [#]_
  ``CoolingDetailedPerformanceData``                                element                                       No        <none>          Cooling detailed performance data [#]_
  ``HeatingDetailedPerformanceData``                                element                                       No        <none>          Heating detailed performance data [#]_
  ``extension/HeatingCapacityRetention[Fraction | Temperature]``    double    frac | F  >= 0, < 1 | <= 17         No        See [#]_        Heating output capacity retention at cold temperature [#]_
  ``extension/FanPowerWattsPerCFM``                                 double    W/cfm     >= 0                      No        See [#]_        Blower fan efficiency at maximum fan speed
  ``extension/AirflowDefectRatio``                                  double    frac      -0.9 - 9                  No        0.0             Deviation between design/installed airflows [#]_
  ``extension/ChargeDefectRatio``                                   double    frac      -0.9 - 9                  No        0.0             Deviation between design/installed refrigerant charges [#]_
  ``extension/CrankcaseHeaterPowerWatts``                           double    W                                   No        50.0            Crankcase heater power
  ================================================================  ========  ========  ========================  ========  ==============  ==============================================

  .. [#] If DistributionSystem provided, HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] Heating capacity autosized per ACCA Manual J/S based on heating design load (unless a different HeatPumpSizingMethodology was selected in :ref:`hvac_sizing_control`).
  .. [#] Cooling capacity autosized per ACCA Manual J/S based on cooling design load (unless a different HeatPumpSizingMethodology was selected in :ref:`hvac_sizing_control`).
  .. [#] CompressorType only choice is "variable speed" (i.e., they are assumed to be inverter driven).
  .. [#] If neither CompressorLockoutTemperature nor BackupHeatingSwitchoverTemperature provided, CompressorLockoutTemperature defaults to 25F if fossil fuel backup otherwise -20F.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across all HVAC systems) must be less than or equal to 1.
  .. [#] The sum of all ``FractionCoolLoadServed`` (across all HVAC systems) must be less than or equal to 1.
  .. [#] If SEER2 provided, converted to SEER using ANSI/RESNET/ICC 301-2022 Addendum C, where SEER = SEER2 / 0.95 if ducted and SEER = SEER2 if ductless.
  .. [#] If HSPF2 provided, converted to HSPF using ANSI/RESNET/ICC 301-2022 Addendum C, where HSPF = HSPF2 / 0.85 if ducted and HSPF = HSPF2 / 0.90 if ductless.
  .. [#] If CoolingDetailedPerformanceData is provided, see :ref:`clg_detailed_perf_data`.
         HeatingDetailedPerformanceData must also be provided.
  .. [#] If HeatingDetailedPerformanceData is provided, see :ref:`htg_detailed_perf_data`.
         CoolingDetailedPerformanceData must also be provided.
  .. [#] | If neither extension/HeatingCapacityRetention nor HeatingCapacity17F nor HeatingDetailedPerformanceData provided, heating capacity retention defaults based on CompressorType:
         | - **single/two stage**: 0.425 (at 5F)
         | - **variable speed**: 0.0461 * HSPF + 0.1594 (at 5F)
  .. [#] The extension/HeatingCapacityRetention input is a more flexible alternative to HeatingCapacity17F, as it can apply to autosized systems and allows the heating capacity retention to be defined at a user-specified temperature (instead of 17F).
         Either input approach can be used, but not both.
  .. [#] FanPowerWattsPerCFM defaults to 0.07 W/cfm for ductless systems and 0.18 W/cfm for ducted systems.
  .. [#] AirflowDefectRatio is defined as (InstalledAirflow - DesignAirflow) / DesignAirflow; a value of zero means no airflow defect.
         A non-zero airflow defect can only be applied for systems attached to a distribution system.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.
  .. [#] ChargeDefectRatio is defined as (InstalledCharge - DesignCharge) / DesignCharge; a value of zero means no refrigerant charge defect.
         A non-zero charge defect should typically only be applied for systems that are charged on site, not for systems that have pre-charged line sets.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

.. _pthp:

Packaged Terminal Heat Pump
~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a packaged terminal heat pump is specified, additional information is entered in ``HeatPump``.

  ===============================================================  ========  ========  ========================  ========  ==============  ==============================================
  Element                                                          Type      Units     Constraints               Required  Default         Notes
  ===============================================================  ========  ========  ========================  ========  ==============  ==============================================
  ``HeatingCapacity``                                              double    Btu/hr    >= 0                      No        autosized [#]_  Heating output capacity (excluding any backup heating)
  ``HeatingCapacity17F``                                           double    Btu/hr    >= 0, <= HeatingCapacity  No                        Heating output capacity at 17F, if available
  ``CoolingCapacity``                                              double    Btu/hr    >= 0                      No        autosized [#]_  Cooling output capacity
  ``CompressorLockoutTemperature``                                 double    F                                   No        See [#]_        Minimum outdoor temperature for compressor operation
  ``CoolingSensibleHeatFraction``                                  double    frac      0 - 1                     No        0.65            Sensible heat fraction
  ``FractionHeatLoadServed``                                       double    frac      0 - 1 [#]_                Yes                       Fraction of heating load served
  ``FractionCoolLoadServed``                                       double    frac      0 - 1 [#]_                Yes                       Fraction of cooling load served
  ``AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value``   double    Btu/Wh    > 0                       Yes                       Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="COP"]/Value``                   double    W/W       > 0                       Yes                       Rated heating efficiency
  ``extension/HeatingCapacityRetention[Fraction | Temperature]``   double    frac | F  >= 0, < 1 | <= 17         No        0.425 | 5       Heating output capacity retention at cold temperature [#]_
  ``extension/CrankcaseHeaterPowerWatts``                          double    W                                   No        0.0             Crankcase heater power
  ===============================================================  ========  ========  ========================  ========  ==============  ==============================================

  .. [#] Heating capacity autosized per ACCA Manual J/S based on heating design load (unless a different HeatPumpSizingMethodology was selected in :ref:`hvac_sizing_control`).
  .. [#] Cooling capacity autosized per ACCA Manual J/S based on cooling design load (unless a different HeatPumpSizingMethodology was selected in :ref:`hvac_sizing_control`).
  .. [#] If neither CompressorLockoutTemperature nor BackupHeatingSwitchoverTemperature provided, CompressorLockoutTemperature defaults to 25F if fossil fuel backup otherwise 0F.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across all HVAC systems) must be less than or equal to 1.
  .. [#] The sum of all ``FractionCoolLoadServed`` (across all HVAC systems) must be less than or equal to 1.
  .. [#] The extension/HeatingCapacityRetention input is a more flexible alternative to HeatingCapacity17F, as it can apply to autosized systems and allows the heating capacity retention to be defined at a user-specified temperature (instead of 17F).
         Either input approach can be used, but not both.

.. _room_ac_reverse_cycle:
  
Room Air Conditioner w/ Reverse Cycle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a room air conditioner with reverse cycle is specified, additional information is entered in ``HeatPump``.

  ===============================================================  ========  ========  ========================  ========  ==============  ==============================================
  Element                                                          Type      Units     Constraints               Required  Default         Notes
  ===============================================================  ========  ========  ========================  ========  ==============  ==============================================
  ``HeatingCapacity``                                              double    Btu/hr    >= 0                      No        autosized [#]_  Heating output capacity (excluding any backup heating)
  ``HeatingCapacity17F``                                           double    Btu/hr    >= 0, <= HeatingCapacity  No                        Heating output capacity at 17F, if available
  ``CoolingCapacity``                                              double    Btu/hr    >= 0                      No        autosized [#]_  Cooling output capacity
  ``CompressorLockoutTemperature``                                 double    F                                   No        See [#]_        Minimum outdoor temperature for compressor operation
  ``CoolingSensibleHeatFraction``                                  double    frac      0 - 1                     No        0.65            Sensible heat fraction
  ``FractionHeatLoadServed``                                       double    frac      0 - 1 [#]_                Yes                       Fraction of heating load served
  ``FractionCoolLoadServed``                                       double    frac      0 - 1 [#]_                Yes                       Fraction of cooling load served
  ``AnnualCoolingEfficiency[Units="EER" or Units="CEER"]/Value``   double    Btu/Wh    > 0                       Yes                       Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="COP"]/Value``                   double    W/W       > 0                       Yes                       Rated heating efficiency
  ``extension/HeatingCapacityRetention[Fraction | Temperature]``   double    frac | F  >= 0, < 1 | <= 17         No        0.425 | 5       Heating output capacity retention at cold temperature [#]_
  ``extension/CrankcaseHeaterPowerWatts``                          double    W                                   No        0.0             Crankcase heater power
  ===============================================================  ========  ========  ========================  ========  ==============  ==============================================

  .. [#] Heating capacity autosized per ACCA Manual J/S based on heating design load (unless a different HeatPumpSizingMethodology was selected in :ref:`hvac_sizing_control`).
  .. [#] Cooling capacity autosized per ACCA Manual J/S based on cooling design load (unless a different HeatPumpSizingMethodology was selected in :ref:`hvac_sizing_control`).
  .. [#] If neither CompressorLockoutTemperature nor BackupHeatingSwitchoverTemperature provided, CompressorLockoutTemperature defaults to 25F if fossil fuel backup otherwise 0F.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across all HVAC systems) must be less than or equal to 1.
  .. [#] The sum of all ``FractionCoolLoadServed`` (across all HVAC systems) must be less than or equal to 1.
  .. [#] The extension/HeatingCapacityRetention input is a more flexible alternative to HeatingCapacity17F, as it can apply to autosized systems and allows the heating capacity retention to be defined at a user-specified temperature (instead of 17F).
         Either input approach can be used, but not both.

Ground-to-Air Heat Pump
~~~~~~~~~~~~~~~~~~~~~~~

If a ground-to-air heat pump is specified, additional information is entered in ``HeatPump``.

  ===============================================  ========  ======  ===========  ========  ==============  ==============================================
  Element                                          Type      Units   Constraints  Required  Default         Notes
  ===============================================  ========  ======  ===========  ========  ==============  ==============================================
  ``IsSharedSystem``                               boolean                        No        false           Whether it has a shared hydronic circulation loop [#]_
  ``DistributionSystem``                           idref             See [#]_     Yes                       ID of attached distribution system
  ``HeatingCapacity``                              double    Btu/hr  >= 0         No        autosized [#]_  Heating output capacity (excluding any backup heating)
  ``CoolingCapacity``                              double    Btu/hr  >= 0         No        autosized [#]_  Cooling output capacity
  ``CoolingSensibleHeatFraction``                  double    frac    0 - 1        No        0.73            Sensible heat fraction
  ``FractionHeatLoadServed``                       double    frac    0 - 1 [#]_   Yes                       Fraction of heating load served
  ``FractionCoolLoadServed``                       double    frac    0 - 1 [#]_   Yes                       Fraction of cooling load served
  ``AnnualCoolingEfficiency[Units="EER"]/Value``   double    Btu/Wh  > 0          Yes                       Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="COP"]/Value``   double    W/W     > 0          Yes                       Rated heating efficiency
  ``NumberofUnitsServed``                          integer           > 0          See [#]_                  Number of dwelling units served
  ``extension/PumpPowerWattsPerTon``               double    W/ton   >= 0         No        See [#]_        Pump power [#]_
  ``extension/SharedLoopWatts``                    double    W       >= 0         See [#]_                  Shared pump power [#]_
  ``extension/FanPowerWattsPerCFM``                double    W/cfm   >= 0         No        See [#]_        Blower fan efficiency at maximum fan speed
  ``extension/AirflowDefectRatio``                 double    frac    -0.9 - 9     No        0.0             Deviation between design/installed airflows [#]_
  ``extension/ChargeDefectRatio``                  double    frac    -0.9 - 9     No        0.0             Deviation between design/installed refrigerant charges [#]_
  ===============================================  ========  ======  ===========  ========  ==============  ==============================================

  .. [#] IsSharedSystem should be true if the SFA/MF building has multiple ground source heat pumps connected to a shared hydronic circulation loop.
  .. [#] HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] Heating capacity autosized per ACCA Manual J/S based on heating design load.
  .. [#] Cooling capacity autosized per ACCA Manual J/S based on cooling design load.
  .. [#] The sum of all ``FractionHeatLoadServed`` (across all HVAC systems) must be less than or equal to 1.
  .. [#] The sum of all ``FractionCoolLoadServed`` (across all HVAC systems) must be less than or equal to 1.
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
         A non-zero charge defect should typically only be applied for systems that are charged on site, not for systems that have pre-charged line sets.
         See ANSI/RESNET/ACCA 310-2020 Standard for Grading the Installation of HVAC Systems for more information.

.. _hvac_heatpump_wlhp:

Water-Loop-to-Air Heat Pump
~~~~~~~~~~~~~~~~~~~~~~~~~~~

If a water-loop-to-air heat pump is specified, additional information is entered in ``HeatPump``.

  ===============================================  ========  ======  ===========  ========  ==============  ==============================================
  Element                                          Type      Units   Constraints  Required  Default         Notes
  ===============================================  ========  ======  ===========  ========  ==============  ==============================================
  ``DistributionSystem``                           idref             See [#]_     Yes                       ID of attached distribution system
  ``HeatingCapacity``                              double    Btu/hr  > 0          No        autosized [#]_  Heating output capacity
  ``CoolingCapacity``                              double    Btu/hr  > 0          See [#]_                  Cooling output capacity
  ``AnnualCoolingEfficiency[Units="EER"]/Value``   double    Btu/Wh  > 0          See [#]_                  Rated cooling efficiency
  ``AnnualHeatingEfficiency[Units="COP"]/Value``   double    W/W     > 0          See [#]_                  Rated heating efficiency
  ===============================================  ========  ======  ===========  ========  ==============  ==============================================

  .. [#] HVACDistribution type must be AirDistribution (type: "regular velocity") or DSE.
  .. [#] Heating capacity autosized per ACCA Manual J/S based on heating design load.
  .. [#] CoolingCapacity required if there is a shared chiller or cooling tower with water loop distribution.
  .. [#] AnnualCoolingEfficiency required if there is a shared chiller or cooling tower with water loop distribution.
  .. [#] AnnualHeatingEfficiency required if there is a shared boiler with water loop distribution.

.. note::

  If a water loop heat pump is specified, there must be at least one shared heating system (i.e., :ref:`hvac_heating_boiler`) and/or one shared cooling system (i.e., :ref:`hvac_cooling_chiller` or :ref:`hvac_cooling_tower`) specified with water loop distribution.

Backup
~~~~~~

If a backup type ("integrated" or "separate") is provided, additional information  is entered in ``HeatPump``.

  =============================================================================  ========  ======  ===========  ========  =========  ==========================================
  Element                                                                        Type      Units   Constraints  Required  Default    Notes
  =============================================================================  ========  ======  ===========  ========  =========  ==========================================
  ``BackupHeatingSwitchoverTemperature`` or ``CompressorLockoutTemperature``     double    F                    No        See [#]_   Minimum outdoor temperature for compressor operation
  ``BackupHeatingSwitchoverTemperature`` or ``BackupHeatingLockoutTemperature``  double    F       See [#]_     No        See [#]_   Maximum outdoor temperature for backup operation
  =============================================================================  ========  ======  ===========  ========  =========  ==========================================

  .. [#] If neither BackupHeatingSwitchoverTemperature nor CompressorLockoutTemperature provided, CompressorLockoutTemperature defaults as described above for individual heat pump types.
  .. [#] If both BackupHeatingLockoutTemperature and CompressorLockoutTemperature provided, BackupHeatingLockoutTemperature must be greater than or equal to CompressorLockoutTemperature.
  .. [#] If neither BackupHeatingSwitchoverTemperature nor BackupHeatingLockoutTemperature provided, BackupHeatingLockoutTemperature defaults to 40F for electric backup and 50F for fossil fuel backup.

  .. note::

    Provide ``BackupHeatingSwitchoverTemperature`` for a situation where there is a discrete outdoor temperature below which the heat pump stops operating and above which the backup heating system stops operating.

    Alternatively, provide A) ``CompressorLockoutTemperature`` to specify the outdoor temperature below which the heat pump stops operating and/or B) ``BackupHeatingLockoutTemperature`` to specify the outdoor temperature above which the heat pump backup system stops operating.
    If both are provided, the compressor and backup system can both operate between the two temperatures (e.g., simultaneous operation or cycling).
    If both are provided using the same temperature, it is equivalent to using ``BackupHeatingSwitchoverTemperature``.

If a backup type of "integrated" is provided, additional information is entered in ``HeatPump``.

  =============================================================================  ========  ======  ===========  ========  ==============  ==========================================
  Element                                                                        Type      Units   Constraints  Required  Default         Notes
  =============================================================================  ========  ======  ===========  ========  ==============  ==========================================
  ``BackupSystemFuel``                                                           string            See [#]_     Yes                       Integrated backup heating fuel type
  ``BackupAnnualHeatingEfficiency[Units="Percent" or Units="AFUE"]/Value``       double    frac    0 - 1        Yes                       Integrated backup heating efficiency
  ``BackupHeatingCapacity``                                                      double    Btu/hr  >= 0         No        autosized [#]_  Integrated backup heating output capacity
  =============================================================================  ========  ======  ===========  ========  ==============  ==========================================

  .. [#] BackupSystemFuel choices are "electricity", "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "wood", or "wood pellets".
  .. [#] Heating capacity autosized per ACCA Manual J/S based on heating design load.
         (The autosized capacity is not affected by the HeatPumpSizingMethodology selected in :ref:`hvac_sizing_control`.)

If a backup type of "separate" is provided, additional information is entered in ``HeatPump``.

  =============================================================================  ========  ======  ===========  ========  =========  ==========================================
  Element                                                                        Type      Units   Constraints  Required  Default    Notes
  =============================================================================  ========  ======  ===========  ========  =========  ==========================================
  ``BackupSystem``                                                               idref             See [#]_     Yes                  ID of separate backup heating system 
  =============================================================================  ========  ======  ===========  ========  =========  ==========================================
  
  .. [#] BackupSystem must reference a ``HeatingSystem``.

  .. note::

    Due to how the separate backup heating system is modeled in EnergyPlus, there are a few restrictions:

    - The conditioned space cannot be partially heated (i.e., the sum of all ``FractionHeatLoadServed`` must be 1).
    - There cannot be multiple backup heating systems.

HPXML HVAC Detailed Perf. Data
******************************

Some air-source HVAC system types allow detailed heating/cooling performance data to be provided using the ``CoolingDetailedPerformanceData`` and ``HeatingDetailedPerformanceData`` elements, as described above.
One source of detailed performance data is `NEEP's Cold Climate Air Source Heat Pump List <https://ashp.neep.org>`_.

Currently detailed performance data can only be provided for variable-speed HVAC systems.

.. _clg_detailed_perf_data:

Detailed Cooling Performance Data
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For air-source HVAC systems with detailed cooling performance data, two or more pairs of minimum/maximum capacity data are entered in ``CoolingDetailedPerformanceData/PerformanceDataPoint``.

  =================================  ========  ======  ===========  ========  =========  ==========================================
  Element                            Type      Units   Constraints  Required  Default    Notes
  =================================  ========  ======  ===========  ========  =========  ==========================================
  ``OutdoorTemperature``             double    F       See [#]_     Yes                  Outdoor drybulb temperature
  ``Capacity``                       double    Btu/hr               Yes                  Cooling capacity at the specified outdoor temperature
  ``CapacityDescription``            string            See [#]_     Yes                  Whether the datapoint corresponds to minimum or maximum capacity
  ``Efficiency[Units="COP"]/Value``  double    W/W                  Yes                  Cooling efficiency at the specified outdoor temperature
  =================================  ========  ======  ===========  ========  =========  ==========================================

  .. [#] One of the minimum/maximum datapoint pairs must occur at the 95F rated outdoor temperature condition.
         The other datapoint pairs can be at any temperature.
  .. [#] CapacityDescription choices are "minimum" and "maximum".

In addition, the parent object must provide the ``CoolingCapacity`` and the ``CompressorType`` must be set to "variable speed".
For heat pumps, :ref:`htg_detailed_perf_data` must also be provided.
Note that when detailed cooling performance data is provided, some other inputs (like SEER) are ignored.

.. _htg_detailed_perf_data:

Detailed Heating Performance Data
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For air-source HVAC systems with detailed heating performance data, two or more pairs of minimum/maximum capacity data are entered in ``HeatingDetailedPerformanceData/PerformanceDataPoint``.

  =================================  ========  ======  ===========  ========  =========  ==========================================
  Element                            Type      Units   Constraints  Required  Default    Notes
  =================================  ========  ======  ===========  ========  =========  ==========================================
  ``OutdoorTemperature``             double    F       See [#]_     Yes                  Outdoor drybulb temperature
  ``Capacity``                       double    Btu/hr               Yes                  Heating capacity at the specified outdoor temperature
  ``CapacityDescription``            string            See [#]_     Yes                  Whether the datapoint corresponds to minimum or maximum capacity
  ``Efficiency[Units="COP"]/Value``  double    W/W                  Yes                  Heating efficiency at the specified outdoor temperature
  =================================  ========  ======  ===========  ========  =========  ==========================================

  .. [#] One of the minimum/maximum datapoint pairs must occur at the 47F rated outdoor temperature condition.
         The other datapoint pairs can be at any temperature.
  .. [#] CapacityDescription choices are "minimum" and "maximum".

In addition, the parent object must provide the ``HeatingCapacity`` and the ``CompressorType`` must be set to "variable speed".
For heat pumps, :ref:`clg_detailed_perf_data` must also be provided.
Note that when detailed cooling performance data is provided, some other inputs (like HSPF and HeatingCapacityRetention) are ignored.

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

Thermostat setpoints are additionally entered using either simple inputs or hourly inputs.
Alternatively, setpoints can be defined using :ref:`detailedschedules`.

Simple Inputs
~~~~~~~~~~~~~

To define simple thermostat setpoints, additional information is entered in ``HVACControl``.

  =============================  ========  =======  ===========  ========  =========  ============================
  Element                        Type      Units    Constraints  Required  Default    Notes
  =============================  ========  =======  ===========  ========  =========  ============================
  ``SetpointTempHeatingSeason``  double    F                     No [#]_   68         Heating setpoint temperature
  ``SetpointTempCoolingSeason``  double    F                     No [#]_   78         Cooling setpoint temperature
  =============================  ========  =======  ===========  ========  =========  ============================

  .. [#] SetpointTempHeatingSeason only used if there is heating equipment.
  .. [#] SetpointTempCoolingSeason only used if there is cooling equipment.

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

Hourly Inputs
~~~~~~~~~~~~~~~

To define hourly thermostat setpoints, additional information is entered in ``HVACControl``.

  ===============================================  =====  =======  ===========  ========  =========  ============================================
  Element                                          Type   Units    Constraints  Required  Default    Notes
  ===============================================  =====  =======  ===========  ========  =========  ============================================
  ``extension/WeekdaySetpointTempsHeatingSeason``  array  F                     No [#]_              24 comma-separated weekday heating setpoints
  ``extension/WeekendSetpointTempsHeatingSeason``  array  F                     No                   24 comma-separated weekend heating setpoints
  ``extension/WeekdaySetpointTempsCoolingSeason``  array  F                     No [#]_              24 comma-separated weekday cooling setpoints
  ``extension/WeekendSetpointTempsCoolingSeason``  array  F                     No                   24 comma-separated weekend cooling setpoints
  ===============================================  =====  =======  ===========  ========  =========  ============================================

  .. [#] WeekdaySetpointTempsHeatingSeason and WeekendSetpointTempsHeatingSeason only used if there is heating equipment.
  .. [#] WeekdaySetpointTempsCoolingSeason and WeekendSetpointTempsCoolingSeason only used if there is cooling equipment.

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
  .. [#] ConditionedFloorAreaServed required only when DistributionSystemType is AirDistribution and duct surface area is defaulted (i.e., ``AirDistribution/Ducts`` are present without ``DuctSurfaceArea`` child elements).

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
  .. [#] If NumberofReturnRegisters not provided and return ducts are present, defaults to one return register per conditioned floor per `ASHRAE Standard 152 <https://www.energy.gov/eere/buildings/downloads/ashrae-standard-152-spreadsheet>`_, rounded up to the nearest integer if needed.

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

  =======================================================  =======  ============  ================  ========  ==========  ======================================
  Element                                                  Type     Units         Constraints       Required  Default     Notes
  =======================================================  =======  ============  ================  ========  ==========  ======================================
  ``SystemIdentifier``                                     id                                       Yes                   Unique identifier
  ``DuctInsulationRValue`` and/or ``DuctEffectiveRValue``  double   F-ft2-hr/Btu  >= 0              Yes                   Duct R-value [#]_
  ``DuctBuriedInsulationLevel``                            string                 See [#]_          No        not buried  Duct buried insulation level [#]_
  ``DuctLocation``                                         string                 See [#]_          No        See [#]_    Duct location
  ``FractionDuctArea`` and/or ``DuctSurfaceArea``          double   frac or ft2   0-1 [#]_ or >= 0  See [#]_  See [#]_    Duct fraction/surface area in location
  ``extension/DuctSurfaceAreaMultiplier``                  double                 >= 0              No        1.0         Duct surface area multiplier
  =======================================================  =======  ============  ================  ========  ==========  ======================================

  .. [#] | It is recommended to provide DuctInsulationRValue and not DuctEffectiveRValue. DuctInsulationRValue should not include the exterior air film (i.e., use 0 for an uninsulated duct). For ducts buried in insulation (using DuctBuriedInsulationLevel), DuctInsulationRValue should only represent any surrounding insulation duct wrap and not the entire attic insulation R-value. On the other hand, DuctEffectiveRValue should include the exterior air film as well as other effects such as adjustments for insulation wrapped around round ducts, or effective heat transfer for ducts buried in attic insulation. DuctEffectiveRValue is used for the actual model heat transfer, and when not provided is calculated as follows:
         | - **Uninsulated**: 1.7                                     
         | - **Supply, Insulated**: 2.2438 + 0.5619 * DuctInsulationRValue  
         | - **Supply, Partially Buried**: 5.83 + 2.0 * DuctInsulationRValue
         | - **Supply, Fully Buried**: 9.4 + 1.9 * DuctInsulationRValue
         | - **Supply, Deeply Buried**: 16.67 + 1.45 * DuctInsulationRValue
         | - **Return, Insulated**: 2.0388 + 0.7053 * DuctInsulationRValue
         | - **Return, Partially Buried**: 7.6 + 2.5 * DuctInsulationRValue
         | - **Return, Fully Buried**: 11.83 + 2.45 * DuctInsulationRValue
         | - **Return, Deeply Buried**: 20.9 + 1.9 * DuctInsulationRValue       
         | The uninsulated effective R-value is from ASHRAE Handbook of Fundamentals. The insulated effective R-values are from `True R-Values of Round Residential Ductwork <https://www.aceee.org/files/proceedings/2006/data/papers/SS06_Panel1_Paper18.pdf>`_. The buried effective R-values are from Table 13 of `Reducing Thermal Losses and Gains With Buried and Encapsulated Ducts <https://www.nrel.gov/docs/fy13osti/55876.pdf>`_. The equations assume that the average supply duct has an 8-inch diameter and the average return duct has a 14-in diameter
  .. [#] DuctBuriedInsulationLevel choices are "not buried", "partially buried", "fully buried", or "deeply buried".
  .. [#] Whether the ducts are buried in, e.g., attic loose-fill insulation.
         Partially buried ducts have insulation that does not cover the top of the ducts.
         Fully buried ducts have insulation that just covers the top of the ducts.
         Deeply buried ducts have insulation that continues above the top of the ducts.
         See the `Building America Solution Center <https://basc.pnnl.gov/resource-guides/ducts-buried-attic-insulation>`_ for more information.
  .. [#] DuctLocation choices are "conditioned space", "basement - conditioned", "basement - unconditioned", "crawlspace - unvented", "crawlspace - vented", "crawlspace - conditioned", "attic - unvented", "attic - vented", "garage", "outside", "exterior wall", "under slab", "roof deck", "other housing unit", "other heated space", "other multifamily buffer space", "other non-freezing space", or "manufactured home belly".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If DuctLocation not provided, defaults to the first present space type: "basement - conditioned", "basement - unconditioned", "crawlspace - conditioned", "crawlspace - vented", "crawlspace - unvented", "attic - vented", "attic - unvented", "garage", or "conditioned space".
         If NumberofConditionedFloorsAboveGrade > 1, secondary ducts will be located in "conditioned space".
  .. [#] The sum of all ``FractionDuctArea`` must each equal to 1, both for the supply side and return side.
  .. [#] FractionDuctArea or DuctSurfaceArea are required if DuctLocation is provided.
         If both are provided, DuctSurfaceArea will be used in the model.
  .. [#] | If neither DuctSurfaceArea nor FractionDuctArea provided, duct surface areas will be calculated based on `ASHRAE Standard 152 <https://www.energy.gov/eere/buildings/downloads/ashrae-standard-152-spreadsheet>`_:
         | - **Primary supply duct area**: 0.27 * F_out * ConditionedFloorAreaServed
         | - **Secondary supply duct area**: 0.27 * (1 - F_out) * ConditionedFloorAreaServed
         | - **Primary return duct area**: b_r * F_out * ConditionedFloorAreaServed
         | - **Secondary return duct area**: b_r * (1 - F_out) * ConditionedFloorAreaServed
         | where F_out is 1.0 when NumberofConditionedFloorsAboveGrade <= 1 and 0.75 when NumberofConditionedFloorsAboveGrade > 1, and b_r is 0.05 * NumberofReturnRegisters with a maximum value of 0.25.
         | If FractionDuctArea is provided, each duct surface area will be FractionDuctArea times total duct area, which is calculated using the sum of primary and secondary duct areas from the equations above.

Hydronic Distribution
~~~~~~~~~~~~~~~~~~~~~

To define a hydronic distribution system, additional information is entered in ``HVACDistribution/DistributionSystemType/HydronicDistribution``.

  ============================  =======  =======  ===========  ========  =========  ====================================
  Element                       Type     Units    Constraints  Required  Default    Notes
  ============================  =======  =======  ===========  ========  =========  ====================================
  ``HydronicDistributionType``  string            See [#]_     Yes                  Type of hydronic distribution system
  ============================  =======  =======  ===========  ========  =========  ====================================

  .. [#] HydronicDistributionType choices are "radiator", "baseboard", "radiant floor", "radiant ceiling", or "water loop".

Distribution System Efficiency (DSE)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. warning::

  A simplified DSE model is provided for flexibility, but it is **strongly** recommended to use one of the other detailed distribution system types for better accuracy.
  The DSE input is simply applied to heating/cooling energy use for every hour of the year.
  Note that when specifying a DSE, its effect is reflected in the :ref:`workflow_outputs` but is **not** reflected in the raw EnergyPlus simulation outputs.

To define a DSE, additional information is entered in ``HVACDistribution``.

  =============================================  =======  =======  ===========  ========  =========  ===================================================
  Element                                        Type     Units    Constraints  Required  Default    Notes
  =============================================  =======  =======  ===========  ========  =========  ===================================================
  ``AnnualHeatingDistributionSystemEfficiency``  double   frac     0 - 1        Yes                  Seasonal distribution system efficiency for heating
  ``AnnualCoolingDistributionSystemEfficiency``  double   frac     0 - 1        Yes                  Seasonal distribution system efficiency for cooling
  =============================================  =======  =======  ===========  ========  =========  ===================================================

  DSE values can be calculated using, e.g., `ASHRAE Standard 152 <https://www.energy.gov/eere/buildings/downloads/ashrae-standard-152-spreadsheet>`_.

HPXML Ventilation Fan
*********************

Each ventilation fan system is entered as a ``/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan``.

  =============================================================================================================================================  ========  =======  ===========  ========  =========  ========================
  Element                                                                                                                                        Type      Units    Constraints  Required  Default    Notes
  =============================================================================================================================================  ========  =======  ===========  ========  =========  ========================
  ``SystemIdentifier``                                                                                                                           id                              Yes                  Unique identifier
  ``UsedForWholeBuildingVentilation`` or ``UsedForLocalVentilation`` or ``UsedForSeasonalCoolingLoadReduction`` or ``UsedForGarageVentilation``  boolean            See [#]_     See [#]_             Ventilation fan use case
  =============================================================================================================================================  ========  =======  ===========  ========  =========  ========================
  
  .. [#] One (and only one) of the ``UsedFor...`` elements must have a value of true.
         If UsedForWholeBuildingVentilation is true, see :ref:`wholeventilation`.
         If UsedForLocalVentilation is true, see :ref:`localventilation`.
         If UsedForSeasonalCoolingLoadReduction is true, see :ref:`wholehousefan`.
         If UsedForGarageVentilation is true, garage ventilation is currently ignored.
  .. [#] Only the ``UsedFor...`` element that is true is required.

.. _wholeventilation:

Whole Ventilation Fan
~~~~~~~~~~~~~~~~~~~~~

Each mechanical ventilation system that provides ventilation to the whole dwelling unit is entered as a ``/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForWholeBuildingVentilation=true]``.
If not entered, the simulation will not include mechanical ventilation.

  =============================================================================================  ========  =======  ===========  ========  =========  =========================================
  Element                                                                                        Type      Units    Constraints  Required  Default    Notes
  =============================================================================================  ========  =======  ===========  ========  =========  =========================================
  ``IsSharedSystem``                                                                             boolean            See [#]_     No        false      Whether it serves multiple dwelling units
  ``FanType``                                                                                    string             See [#]_     Yes                  Type of ventilation system
  ``RatedFlowRate`` or ``TestedFlowRate`` or ``CalculatedFlowRate`` or ``DeliveredVentilation``  double    cfm      >= 0         No        See [#]_   Flow rate [#]_
  ``HoursInOperation``                                                                           double    hrs/day  0 - 24       See [#]_  See [#]_   Hours per day of operation
  ``FanPower``                                                                                   double    W        >= 0         No        See [#]_   Fan power
  =============================================================================================  ========  =======  ===========  ========  =========  =========================================

  .. [#] For central fan integrated supply systems, IsSharedSystem must be false.
  .. [#] FanType choices are "energy recovery ventilator", "heat recovery ventilator", "exhaust only", "supply only", "balanced", or "central fan integrated supply".
  .. [#] | If flow rate not provided, defaults to the required mechanical ventilation rate per `ASHRAE 62.2-2019 <https://www.techstreet.com/ashrae/standards/ashrae-62-2-2019?product_id=2087691>`_:
         | Qfan = Qtot - Φ*(Qinf * Aext)
         | where
         | Qfan = required mechanical ventilation rate (cfm)
         | Qtot = total required ventilation rate (cfm) = 0.03 * ConditionedFloorArea + 7.5*(NumberofBedrooms + 1)
         | Qinf = infiltration rate (cfm)
         | Aext = 1 if single-family detached or TypeOfInfiltrationLeakage is "unit exterior only", otherwise ratio of SFA/MF exterior envelope surface area to total envelope surface area as described in :ref:`air_infiltration`
         | Φ = 1 for balanced ventilation systems, and Qinf/Qtot otherwise
  .. [#] For a central fan integrated supply system, the flow rate should equal the amount of outdoor air provided to the distribution system, not the total airflow through the distribution system.
  .. [#] HoursInOperation is optional unless the VentilationFan refers to the supplemental fan of a CFIS system, in which case it is not allowed.
  .. [#] If HoursInOperation not provided, defaults to 24 (i.e., running continuously) for all system types other than central fan integrated supply (CFIS), and 8.0 (i.e., running intermittently) for CFIS systems.
         For a CFIS system, the HoursInOperation and the flow rate are combined to form the hourly target ventilation rate (e.g., inputs of 90 cfm and 8 hrs/day produce an hourly target ventilation rate of 30 cfm).
         For a CFIS system with a supplemental fan, the supplemental fan's runtime is automatically calculated for each hour (based on the air handler runtime) to maintain the hourly target ventilation rate.
  .. [#] | If FanPower not provided, defaults based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_:
         | - **energy recovery ventilator, heat recovery ventilator, or shared system**: 1.0 W/cfm
         | - **balanced**: 0.7 W/cfm
         | - **central fan integrated supply**: 0.5 W/cfm
         | - **exhaust only" or "supply only**: 0.35 W/cfm

**Exhaust/Supply Only**

If a supply only or exhaust only system is specified, no additional information is entered.

**Balanced**

If a balanced system is specified, no additional information is entered.

**Heat Recovery Ventilator**

If a heat recovery ventilator system is specified, additional information is entered in ``VentilationFan``.

  ========================================================================  ======  =====  ===========  ========  =======  =======================================
  Element                                                                   Type    Units  Constraints  Required  Default  Notes
  ========================================================================  ======  =====  ===========  ========  =======  =======================================
  ``AdjustedSensibleRecoveryEfficiency`` or ``SensibleRecoveryEfficiency``  double  frac   0 - 1        Yes                (Adjusted) Sensible recovery efficiency [#]_
  ========================================================================  ======  =====  ===========  ========  =======  =======================================

  .. [#] Providing AdjustedSensibleRecoveryEfficiency (ASRE) is preferable to SensibleRecoveryEfficiency (SRE).

**Energy Recovery Ventilator**

If an energy recovery ventilator system is specified, additional information is entered in ``VentilationFan``.

  ========================================================================  ======  =====  ===========  ========  =======  =======================================
  Element                                                                   Type    Units  Constraints  Required  Default  Notes
  ========================================================================  ======  =====  ===========  ========  =======  =======================================
  ``AdjustedTotalRecoveryEfficiency`` or ``TotalRecoveryEfficiency``        double  frac   0 - 1        Yes                (Adjusted) Total recovery efficiency [#]_
  ``AdjustedSensibleRecoveryEfficiency`` or ``SensibleRecoveryEfficiency``  double  frac   0 - 1        Yes                (Adjusted) Sensible recovery efficiency [#]_
  ========================================================================  ======  =====  ===========  ========  =======  =======================================

  .. [#] Providing AdjustedTotalRecoveryEfficiency (ATRE) is preferable to TotalRecoveryEfficiency (TRE).
  .. [#] Providing AdjustedSensibleRecoveryEfficiency (ASRE) is preferable to SensibleRecoveryEfficiency (SRE).

**Central Fan Integrated Supply**

If a central fan integrated supply (CFIS) system is specified, additional information is entered in ``VentilationFan``.

  ================================================  ======  =====  ===========  ========  ===============  ==================================
  Element                                           Type    Units  Constraints  Required  Default          Notes
  ================================================  ======  =====  ===========  ========  ===============  ==================================
  ``CFISControls/AdditionalRuntimeOperatingMode``   string         See [#]_     No        air handler fan  How additional ventilation is provided (beyond when the HVAC system is running)
  ``CFISControls/SupplementalFan``                  idref          See [#]_     See [#]_                   The supplemental fan providing additional ventilation
  ``AttachedToHVACDistributionSystem``              idref          See [#]_     Yes                        ID of attached distribution system
  ``extension/VentilationOnlyModeAirflowFraction``  double         0 - 1        No        1.0              Blower airflow rate fraction during ventilation only mode [#]_
  ================================================  ======  =====  ===========  ========  ===============  ==================================

  .. [#] AdditionalRuntimeOperatingMode choices are "air handler fan" or "supplemental fan".
  .. [#] SupplementalFan must reference another ``VentilationFan`` where UsedForWholeBuildingVentilation=true, IsSharedSystem=false, and FanType="exhaust only" or "supply only".
  .. [#] SupplementalFan only required if AdditionalRuntimeOperatingMode is "supplemental fan".
  .. [#] HVACDistribution type cannot be HydronicDistribution.
  .. [#] Blower airflow rate when operating in ventilation only mode (i.e., not heating or cooling mode), as a fraction of the maximum blower airflow rate.
         This value will depend on whether the blower fan can operate at reduced airflow rates during ventilation only operation.
         It is used to determine how much conditioned air is recirculated through ducts during ventilation only operation, resulting in additional duct losses.
         A value of zero will result in no conditioned air recirculation, and thus no additional duct losses.

.. note::

  CFIS systems are automated controllers that use the HVAC system's air handler fan to draw in outdoor air to meet an hourly ventilation target.
  CFIS systems are modeled as assuming they A) maximize the use of normal heating/cooling runtime operation to meet the hourly ventilation target, B) block the flow of outdoor air when the hourly ventilation target has been met, and C) provide additional runtime operation (via air handler fan or supplemental fan) to meet the remainder of the hourly ventilation target when space heating/cooling runtime alone is not sufficient.

**Shared System**

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

.. _localventilation:

Local Ventilation Fan
~~~~~~~~~~~~~~~~~~~~~

Each kitchen range fan or bathroom fan that provides local ventilation is entered as a ``/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForLocalVentilation=true]``.
If not entered, the simulation will not include kitchen/bathroom fans.

  =============================================================================================  =======  =======  ===========  ========  ========  =============================
  Element                                                                                        Type     Units    Constraints  Required  Default   Notes
  =============================================================================================  =======  =======  ===========  ========  ========  =============================
  ``Count``                                                                                      integer           >= 0         No        See [#]_  Number of identical fans
  ``RatedFlowRate`` or ``TestedFlowRate`` or ``CalculatedFlowRate`` or ``DeliveredVentilation``  double   cfm      >= 0         No        See [#]_  Flow rate to outside [#]_
  ``HoursInOperation``                                                                           double   hrs/day  0 - 24       No        See [#]_  Hours per day of operation
  ``FanLocation``                                                                                string            See [#]_     Yes                 Location of the fan
  ``FanPower``                                                                                   double   W        >= 0         No        See [#]_  Fan power
  ``extension/StartHour``                                                                        integer           0 - 23       No        See [#]_  Daily start hour of operation
  =============================================================================================  =======  =======  ===========  ========  ========  =============================

  .. [#] If Count not provided, defaults to 1 for kitchen fans and NumberofBathrooms for bath fans based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If flow rate not provided, defaults to 100 cfm for kitchen fans and 50 cfm for bath fans based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If the kitchen range fan is a recirculating fan, the flow rate should be described as zero.
  .. [#] If HoursInOperation not provided, defaults to 1 based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] FanLocation choices are "kitchen" or "bath".
  .. [#] If FanPower not provided, defaults to 0.3 W/cfm based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If StartHour not provided, defaults to 18 (6pm) for kitchen fans and 7 (7am) for bath fans  based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.

.. _wholehousefan:

Whole House Fan
~~~~~~~~~~~~~~~

Each whole house fan that provides cooling load reduction is entered as a ``/HPXML/Building/BuildingDetails/Systems/MechanicalVentilation/VentilationFans/VentilationFan[UsedForSeasonalCoolingLoadReduction=true]``.
If not entered, the simulation will not include whole house fans.

  =============================================================================================  =======  =======  ===========  ========  ======================  ==========================
  Element                                                                                        Type     Units    Constraints  Required  Default                 Notes
  =============================================================================================  =======  =======  ===========  ========  ======================  ==========================
  ``RatedFlowRate`` or ``TestedFlowRate`` or ``CalculatedFlowRate`` or ``DeliveredVentilation``  double   cfm      >= 0         No        ConditionedFloorArea*2  Flow rate
  ``FanPower``                                                                                   double   W        >= 0         No        See [#]_                Fan power
  =============================================================================================  =======  =======  ===========  ========  ======================  ==========================

  .. [#] If FanPower not provided, defaults to 0.1 W/cfm.

.. note::

  The whole house fan is assumed to operate during hours of favorable outdoor conditions and will take priority over operable windows (natural ventilation).

.. _waterheatingsystems:

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
  ``HotWaterTemperature``    double   F        > 0          No        125       Water heater setpoint [#]_
  ``UsesDesuperheater``      boolean                        No        false     Presence of desuperheater?
  ``NumberofUnitsServed``    integer           > 0          See [#]_            Number of dwelling units served directly or indirectly
  =========================  =======  =======  ===========  ========  ========  ================================================================

  .. [#] WaterHeaterType choices are "storage water heater", "instantaneous water heater", "heat pump water heater", "space-heating boiler with storage tank", or "space-heating boiler with tankless coil".
  .. [#] Location choices are "conditioned space", "basement - unconditioned", "basement - conditioned", "attic - unvented", "attic - vented", "garage", "crawlspace - unvented", "crawlspace - vented", "crawlspace - conditioned", "other exterior", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] | If Location not provided, defaults to the first present space type:
         | - **IECC zones 1-3, excluding 3A**: "garage", "conditioned space"
         | - **IECC zones 3A, 4-8, unknown**: "basement - conditioned", "basement - unconditioned", "conditioned space"
  .. [#] The sum of all ``FractionDHWLoadServed`` (across all WaterHeatingSystems) must equal to 1.
  .. [#] FractionDHWLoadServed represents only the fraction of the hot water load associated with the hot water **fixtures**.
         Additional hot water load from clothes washers/dishwashers will be automatically assigned to the appropriate water heater(s).
  .. [#] The water heater setpoint can alternatively be defined using :ref:`detailedschedules`.
  .. [#] NumberofUnitsServed only required if IsSharedSystem is true, in which case it must be > 1.

Conventional Storage
~~~~~~~~~~~~~~~~~~~~

If a conventional storage water heater is specified, additional information is entered in ``WaterHeatingSystem``.

  =============================================  =================  =============  ===============  ========  ========  =============================================
  Element                                        Type               Units          Constraints      Required  Default   Notes
  =============================================  =================  =============  ===============  ========  ========  =============================================
  ``FuelType``                                   string                            See [#]_         Yes                 Fuel type
  ``TankVolume``                                 double             gal            > 0              No        See [#]_  Nominal tank volume
  ``HeatingCapacity``                            double             Btu/hr         > 0              No        See [#]_  Heating capacity
  ``UniformEnergyFactor`` or ``EnergyFactor``    double             frac           < 1              Yes                 EnergyGuide label rated efficiency
  ``UsageBin`` or ``FirstHourRating``            string or double   str or gal/hr  See [#]_ or > 0  No        See [#]_  EnergyGuide label usage bin/first hour rating
  ``RecoveryEfficiency``                         double             frac           0 - 1 [#]_       No        See [#]_  Recovery efficiency
  ``WaterHeaterInsulation/Jacket/JacketRValue``  double             F-ft2-hr/Btu   >= 0             No        0         R-value of additional tank insulation wrap
  ``extension/TankModelType``                    string                            See [#]_         No        mixed     Tank model type
  =============================================  =================  =============  ===============  ========  ========  =============================================
  
  .. [#] FuelType choices are "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "anthracite coal", "electricity", "wood", or "wood pellets".
  .. [#] If TankVolume not provided, defaults based on Table 8 in the `2014 BAHSP <https://www.energy.gov/sites/prod/files/2014/03/f13/house_simulation_protocols_2014.pdf>`_.
  .. [#] If HeatingCapacity not provided, defaults based on Table 8 in the `2014 BAHSP <https://www.energy.gov/sites/prod/files/2014/03/f13/house_simulation_protocols_2014.pdf>`_.
  .. [#] UsageBin choices are "very small", "low", "medium", or "high".
  .. [#] UsageBin/FirstHourRating are only used for water heaters that use UniformEnergyFactor.
         If neither UsageBin nor FirstHourRating provided, UsageBin defaults to "medium".
         If FirstHourRating provided and UsageBin not provided, UsageBin is determined based on the FirstHourRating value.
  .. [#] RecoveryEfficiency must also be greater than the EnergyFactor (or UniformEnergyFactor).
  .. [#] | If RecoveryEfficiency not provided, defaults as follows based on a regression analysis of `AHRI certified water heaters <https://www.ahridirectory.org/NewSearch?programId=24&searchTypeId=3>`_:
         | - **Electric**: 0.98
         | - **Non-electric, EnergyFactor < 0.75**: 0.252 * EnergyFactor + 0.608
         | - **Non-electric, EnergyFactor >= 0.75**: 0.561 * EnergyFactor + 0.439
  .. [#] TankModelType choices are "mixed" or "stratified".

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

  =============================================  ================  =============  ===============  ========  ===========  =============================================
  Element                                        Type              Units          Constraints      Required  Default      Notes
  =============================================  ================  =============  ===============  ========  ===========  =============================================
  ``FuelType``                                   string                           See [#]_         Yes                    Fuel type
  ``TankVolume``                                 double            gal            > 0              Yes                    Nominal tank volume
  ``UniformEnergyFactor`` or ``EnergyFactor``    double            frac           > 1, <= 5        Yes                    EnergyGuide label rated efficiency
  ``HPWHOperatingMode``                          string                           See [#]_         No        hyrbid/auto  Operating mode [#]_
  ``UsageBin`` or ``FirstHourRating``            string or double  str or gal/hr  See [#]_ or > 0  No        See [#]_     EnergyGuide label usage bin/first hour rating
  ``WaterHeaterInsulation/Jacket/JacketRValue``  double            F-ft2-hr/Btu   >= 0             No        0            R-value of additional tank insulation wrap
  =============================================  ================  =============  ===============  ========  ===========  =============================================

  .. [#] FuelType only choice is "electricity".
  .. [#] HPWHOperatingMode choices are "hybrid/auto" or "heat pump only".
  .. [#] The heat pump water heater operating mode can alternatively be defined using :ref:`detailedschedules`.
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
  ``TankVolume``                                 double   gal           > 0          Yes                     Nominal volume of the storage tank
  ``WaterHeaterInsulation/Jacket/JacketRValue``  double   F-ft2-hr/Btu  >= 0         No            0         R-value of additional storage tank insulation wrap
  ``StandbyLoss[Units="F/hr"]/Value``            double   F/hr          > 0          No            See [#]_  Storage tank standby losses
  =============================================  =======  ============  ===========  ============  ========  ==================================================

  .. [#] RelatedHVACSystem must reference a ``HeatingSystem`` (Boiler).
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

  .. warning::
    
    A desuperheater is currently not allow if detailed water heater setpoint schedules are used.

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

Hot water distribution systems are modeled according to the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

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
  ``BranchPipingLength``             double   ft     > 0          No        10        Branch piping length [#]_
  ``PumpPower``                      double   W      >= 0         No        50 [#]_   Recirculation pump power
  =================================  =======  =====  ===========  ========  ========  =====================================

  .. [#] | ControlType choices are "manual demand control", "presence sensor demand control", "temperature", "timer", or "no control".
         | - manual demand control: The pump only runs when a user presses a button indicating they are about to use hot water.
         | - presence sensor demand control: The pump only runs when a sensor detects someone is present at the faucet.
         | - temperature: The pump runs based on monitoring temperature at some point in the system.
         | - timer: The pump is controlled by a timer.
         | - no control: The pump runs continuously.
  .. [#] | If RecirculationPipingLoopLength not provided, calculated using the following equation from `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_:
         | RecircPipeL = 2.0 * (2.0 * (CFA / NCfl)^0.5 + 10.0 * NCfl + 5.0 * Bsmnt) - 20.0
         | where
         | CFA = conditioned floor area [ft2],
         | NCfl = number of conditioned floor levels number of conditioned floor levels in the residence including conditioned basements,
         | Bsmnt = presence (1.0) or absence (0.0) of an unconditioned basement in the residence.
  .. [#] RecirculationPipingLoopLength is the recirculation loop length including both supply and return sides, measured longitudinally from plans, assuming the hot water piping does not run diagonally, plus 20 feet of piping for each floor level greater than one plus 10 feet of piping for unconditioned basements.
  .. [#] BranchPipingLength is the length of the branch hot water piping from the recirculation loop to the farthest hot water fixture from the recirculation loop, measured longitudinally from plans, assuming the branch hot water piping does not run diagonally.
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
  .. [#] ControlType choices are "manual demand control", "presence sensor demand control", "temperature", "timer", or "no control".

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

Drain water heat recovery is modeled according to the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

HPXML Water Fixtures
********************

Each water fixture is entered as a ``/HPXML/Building/BuildingDetails/Systems/WaterHeating/WaterFixture``.

  ===============================  =================  =====  ===========  ========  ========  ===============================================
  Element                          Type               Units  Constraints  Required  Default   Notes
  ===============================  =================  =====  ===========  ========  ========  ===============================================
  ``SystemIdentifier``             id                                     Yes                 Unique identifier
  ``WaterFixtureType``             string                    See [#]_     Yes                 Bathroom faucet or shower
  ``Count``                        integer                   > 0          No        See [#]_  Number of similar water fixtures
  ``LowFlow`` and/or ``FlowRate``  boolean or double  gpm    > 0          Yes                 Whether the fixture is considered low-flow and/or the flow rate [#]_
  ===============================  =================  =====  ===========  ========  ========  ===============================================

  .. [#] WaterFixtureType choices are "shower head" or "faucet".
         If the shower stall has multiple shower heads that operate simultaneously, combine them as a single entry.
  .. [#] A WaterFixture is considered low-flow if the fixture's flow rate (gpm) is <= 2.0.
         Where a shower stall has multiple shower heads that operate simultaneously, use the sum of their flows.
  .. [#] If Count not provided for any water fixture, assumes that 60% of all fixtures are faucets and 40% are shower heads.

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

Water fixture hot water use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

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
It is recommended to use detailed inputs and allow EnergyPlus to calculate the solar contribution to the hot water load;
the simple inputs are provided if equivalent calculations are performed in another software tool.

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

.. warning::

  The solar fraction will reduce the hot water load equally for every EnergyPlus timestep (even during nights and cloudy events).

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

  =======================================================  =================  ================  ===================  ========  =========  ============================================
  Element                                                  Type               Units             Constraints          Required  Default    Notes
  =======================================================  =================  ================  ===================  ========  =========  ============================================
  ``SystemIdentifier``                                     id                                                        Yes                  Unique identifier
  ``IsSharedSystem``                                       boolean                                                   No        false      Whether it serves multiple dwelling units
  ``Location``                                             string                               See [#]_             No        roof       Mounting location
  ``ModuleType``                                           string                               See [#]_             No        standard   Type of module
  ``Tracking``                                             string                               See [#]_             No        fixed      Type of tracking
  ``ArrayAzimuth`` or ``ArrayOrientation``                 integer or string  deg or direction  0 - 359 or See [#]_  Yes                  Direction panels face (clockwise from North)
  ``ArrayTilt``                                            double             deg               0 - 90               Yes                  Tilt relative to horizontal
  ``MaxPowerOutput``                                       double             W                 >= 0                 Yes                  Peak power
  ``SystemLossesFraction`` or ``YearModulesManufactured``  double or integer  frac or #         0 - 1 or > 1600      No        0.14 [#]_  System losses [#]_
  ``AttachedToInverter``                                   idref                                See [#]_             Yes                  ID of attached inverter
  ``extension/NumberofBedroomsServed``                     integer                              > 1                  See [#]_             Number of bedrooms served
  =======================================================  =================  ================  ===================  ========  =========  ============================================
  
  .. [#] Location choices are "ground" or "roof" mounted.
  .. [#] ModuleType choices are "standard", "premium", or "thin film".
  .. [#] Tracking choices are "fixed", "1-axis", "1-axis backtracked", or "2-axis".
  .. [#] ArrayOrientation choices are "northeast", "east", "southeast", "south", "southwest", "west", "northwest", or "north"
  .. [#] | SystemLossesFraction default is derived from the `PVWatts documentation <https://www.nrel.gov/docs/fy14osti/62641.pdf>`_, which breaks down the losses as follows.
         | Note that the total loss (14%) is not the sum of the individual losses but is calculated by multiplying the reduction due to each loss.
         | - **Soiling**: 2%
         | - **Shading**: 3%
         | - **Snow**: 0%
         | - **Mismatch**: 2%
         | - **Wiring**: 2%
         | - **Connections**: 0.5%
         | - **Light-induced degradation**: 1.5%
         | - **Nameplate rating**: 1%
         | - **Age**: 0%
         | - **Availability**: 3%
         | If YearModulesManufactured provided but not SystemLossesFraction, calculated as:
         | SystemLossesFraction = 1.0 - (1.0 - 0.14) * (1.0 - (1.0 - 0.995^(CurrentYear - YearModulesManufactured))).
  .. [#] System losses due to soiling, shading, snow, mismatch, wiring, degradation, etc.
  .. [#] AttachedToInverter must reference an ``Inverter``.
  .. [#] NumberofBedroomsServed only required if IsSharedSystem is true, in which case it must be > NumberofBedrooms.
         PV generation will be apportioned to the dwelling unit using its number of bedrooms divided by the total number of bedrooms served by the PV system.

In addition, an inverter must be entered as a ``/HPXML/Building/BuildingDetails/Systems/Photovoltaics/Inverter``.

  =======================================================  =================  ================  ===================  ========  ========  ============================================
  Element                                                  Type               Units             Constraints          Required  Default   Notes
  =======================================================  =================  ================  ===================  ========  ========  ============================================
  ``SystemIdentifier``                                     id                                                        Yes                 Unique identifier
  ``InverterEfficiency``                                   double             frac              0 - 1 [#]_           No        0.96      Inverter efficiency
  =======================================================  =================  ================  ===================  ========  ========  ============================================

  .. [#] For homes with multiple inverters, all InverterEfficiency elements must have the same value.

HPXML Batteries
***************

A single battery can be entered as a ``/HPXML/Building/BuildingDetails/Systems/Batteries/Battery``.
If not entered, the simulation will not include batteries.

  ====================================================  =======  =========  =======================  ========  ========  ============================================
  Element                                               Type     Units      Constraints              Required  Default   Notes
  ====================================================  =======  =========  =======================  ========  ========  ============================================
  ``SystemIdentifier``                                  id                                           Yes                 Unique identifier
  ``Location``                                          string              See [#]_                 No        See [#]_  Location
  ``BatteryType``                                       string              See [#]_                 Yes                 Battery type
  ``NominalCapacity[Units="kWh" or Units="Ah"]/Value``  double   kWh or Ah  >= 0                     No        See [#]_  Nominal (total) capacity
  ``UsableCapacity[Units="kWh" or Units="Ah"]/Value``   double   kWh or Ah  >= 0, < NominalCapacity  No        See [#]_  Usable capacity
  ``RatedPowerOutput``                                  double   W          >= 0                     No        See [#]_  Power output under non-peak conditions
  ``NominalVoltage``                                    double   V          >= 0                     No        50        Nominal voltage
  ``RoundTripEfficiency``                               double   frac       0 - 1                    No        0.925     Round trip efficiency
  ====================================================  =======  =========  =======================  ========  ========  ============================================

  .. [#] Location choices are "conditioned space", "basement - conditioned", "basement - unconditioned", "crawlspace - vented", "crawlspace - unvented", "crawlspace - conditioned", "attic - vented", "attic - unvented", "garage", or "outside".
  .. [#] If Location not provided, defaults to "garage" if a garage is present, otherwise "outside".
  .. [#] BatteryType only choice is "Li-ion".
  .. [#] If NominalCapacity not provided, defaults to UsableCapacity / 0.9 if UsableCapacity provided, else (RatedPowerOutput / 1000) / 0.5 if RatedPowerOutput provided, else 10 kWh.
  .. [#] If UsableCapacity not provided, defaults to 0.9 * NominalCapacity.
  .. [#] If RatedPowerOutput not provided, defaults to 0.5 * NominalCapacity * 1000.

 .. note::

  An unscheduled battery in a home with photovoltaics (PV) will be controlled using a simple control strategy designed to maximize on site consumption of energy. The battery will charge if PV production is greater than the building load and the battery is below its maximum capacity, while the battery will discharge if the building load is greater than PV production and the battery is above its minimum capacity.

  A battery can alternatively be controlled using :ref:`detailedschedules`, where charging and discharging schedules are defined. Positive schedule values control timing and magnitude of charging storage. Negative schedule values control timing and magnitude of discharging storage. Simultaneous charging and discharging of the battery is not allowed. The round trip efficiency affects charging and discharging; the reported charging and discharging rates will be larger than the schedule value by an amount equal to the losses due to the round trip efficiency.

  A battery in a home without PV or charging/discharging schedules is assumed to operate as backup and is not modeled.

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

  ======================================================================  =======  ===========  ===========  ========  =================  ==============================================
  Element                                                                 Type     Units        Constraints  Required  Default            Notes
  ======================================================================  =======  ===========  ===========  ========  =================  ==============================================
  ``SystemIdentifier``                                                    id                                 Yes                          Unique identifier
  ``IsSharedAppliance``                                                   boolean                            No        false              Whether it serves multiple dwelling units [#]_
  ``Location``                                                            string                See [#]_     No        conditioned space  Location
  ``IntegratedModifiedEnergyFactor`` or ``ModifiedEnergyFactor``          double   ft3/kWh/cyc  > 0          No        See [#]_           Efficiency [#]_
  ``AttachedToWaterHeatingSystem`` or ``AttachedToHotWaterDistribution``  idref                 See [#]_     See [#]_                     ID of attached water heater or distribution system
  ``extension/UsageMultiplier``                                           double                >= 0         No        1.0                Multiplier on energy & hot water usage
  ``extension/WeekdayScheduleFractions``                                  array                              No        See [#]_           24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``                                  array                              No                           24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``                                array                              No        See [#]_           12 comma-separated monthly multipliers
  ======================================================================  =======  ===========  ===========  ========  =================  ==============================================

  .. [#] For example, a clothes washer in a shared laundry room of a MF building.
  .. [#] Location choices are "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
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
         IMEF may be found using the manufacturer’s data sheet, the `California Energy Commission Appliance Database <https://cacertappliances.energy.ca.gov/Pages/ApplianceSearch.aspx>`_, the `EPA ENERGY STAR website <https://www.energystar.gov/productfinder/>`_, or another reputable source.
  .. [#] AttachedToWaterHeatingSystem must reference a ``WaterHeatingSystem``; AttachedToHotWaterDistribution must reference a ``HotWaterDistribution``.
  .. [#] AttachedToWaterHeatingSystem (or AttachedToHotWaterDistribution) only required if IsSharedAppliance is true.
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
  ``Capacity``                      double   ft3      > 0          Yes                    Clothes washer volume
  ================================  =======  =======  ===========  ============  =======  ====================================

Clothes washer energy use and hot water use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 Addendum A <https://www.resnet.us/wp-content/uploads/ANSI_RESNET_ICC-301-2019-Addendum-A-2019_7.16.20-1.pdf>`_.

HPXML Clothes Dryer
*******************

A single clothes dryer can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/ClothesDryer``.
If not entered, the simulation will not include a clothes dryer.

  ============================================  =======  ======  ===========  ========  =================  ==============================================
  Element                                       Type     Units   Constraints  Required  Default            Notes
  ============================================  =======  ======  ===========  ========  =================  ==============================================
  ``SystemIdentifier``                          id                            Yes                          Unique identifier
  ``IsSharedAppliance``                         boolean                       No        false              Whether it serves multiple dwelling units [#]_
  ``Location``                                  string           See [#]_     No        conditioned space  Location
  ``FuelType``                                  string           See [#]_     Yes                          Fuel type
  ``CombinedEnergyFactor`` or ``EnergyFactor``  double   lb/kWh  > 0          No        See [#]_           Efficiency [#]_
  ``Vented``                                    boolean                       No        true               Whether dryer is vented
  ``VentedFlowRate``                            double   cfm     >= 0         No        100 [#]_           Exhaust flow rate during operation
  ``extension/UsageMultiplier``                 double           >= 0         No        1.0                Multiplier on energy use
  ``extension/WeekdayScheduleFractions``        array                         No        See [#]_           24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``        array                         No                           24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``      array                         No        See [#]_           12 comma-separated monthly multipliers
  ============================================  =======  ======  ===========  ========  =================  ==============================================

  .. [#] For example, a clothes dryer in a shared laundry room of a MF building.
  .. [#] Location choices are "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] FuelType choices are "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "anthracite coal", "electricity", "wood", or "wood pellets".
  .. [#] If neither CombinedEnergyFactor nor EnergyFactor provided, the following default values representing a standard clothes dryer from 2006 will be used:
         CombinedEnergyFactor = 3.01.
  .. [#] If EnergyFactor (EF) provided instead of CombinedEnergyFactor (CEF), it will be converted using the following equation based on the `Interpretation on ANSI/RESNET/ICC 301-2014 Clothes Dryer CEF <https://www.resnet.us/wp-content/uploads/No.-301-2014-10-Section-4.2.2.5.2.8-Clothes-Dryer-CEF-Rating.pdf>`_:
         CEF = EF / 1.15.
         CEF may be found using the manufacturer’s data sheet, the `California Energy Commission Appliance Database <https://cacertappliances.energy.ca.gov/Pages/ApplianceSearch.aspx>`_, the `EPA ENERGY STAR website <https://www.energystar.gov/productfinder/>`_, or another reputable source.
  .. [#] VentedFlowRate default based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 18 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values are used: "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0".

Clothes dryer energy use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 Addendum A <https://www.resnet.us/wp-content/uploads/ANSI_RESNET_ICC-301-2019-Addendum-A-2019_7.16.20-1.pdf>`_.

HPXML Dishwasher
****************

A single dishwasher can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/Dishwasher``.
If not entered, the simulation will not include a dishwasher.

  ======================================================================  =======  ===========  ===========  ========  =================  ==============================================
  Element                                                                 Type     Units        Constraints  Required  Default            Notes
  ======================================================================  =======  ===========  ===========  ========  =================  ==============================================
  ``SystemIdentifier``                                                    id                                 Yes                          Unique identifier
  ``IsSharedAppliance``                                                   boolean                            No        false              Whether it serves multiple dwelling units [#]_
  ``Location``                                                            string                See [#]_     No        conditioned space  Location
  ``RatedAnnualkWh`` or ``EnergyFactor``                                  double   kWh/yr or #  > 0          No        See [#]_           EnergyGuide label consumption/efficiency [#]_
  ``AttachedToWaterHeatingSystem`` or ``AttachedToHotWaterDistribution``  idref                 See [#]_     See [#]_                     ID of attached water heater or distribution system
  ``extension/UsageMultiplier``                                           double                >= 0         No        1.0                Multiplier on energy & hot water usage
  ``extension/WeekdayScheduleFractions``                                  array                              No        See [#]_           24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``                                  array                              No                           24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``                                array                              No        See [#]_           12 comma-separated monthly multipliers
  ======================================================================  =======  ===========  ===========  ========  =================  ==============================================

  .. [#] For example, a dishwasher in a shared mechanical room of a MF building.
  .. [#] Location choices are "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
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
  .. [#] AttachedToWaterHeatingSystem must reference a ``WaterHeatingSystem``; AttachedToHotWaterDistribution must reference a ``HotWaterDistribution``.
  .. [#] AttachedToWaterHeatingSystem (or AttachedToHotWaterDistribution) only required if IsSharedAppliance is true.
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

  .. [#] Location choices are "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If Location not provided and is the *primary* refrigerator, defaults to "conditioned space".
         If Location not provided and is a *secondary* refrigerator, defaults to the first present space type: "garage", "basement - unconditioned", "basement - conditioned", or "conditioned space".
  .. [#] If RatedAnnualkWh not provided, it will be defaulted to represent a standard refrigerator from 2006 using the following equation based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_:
         RatedAnnualkWh = 637.0 + 18.0 * NumberofBedrooms.
  .. [#] If multiple refrigerators are specified, there must be exactly one refrigerator described with PrimaryIndicator=true.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 16 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837".

.. note::

  Refrigerator energy use is not currently affected by the ambient temperature where it is located.

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

  .. [#] Location choices are "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
         See :ref:`hpxmllocations` for descriptions.
  .. [#] If Location not provided, defaults to "garage" if present, otherwise "basement - unconditioned" if present, otherwise "basement - conditioned" if present, otherwise "conditioned space".
  .. [#] RatedAnnualkWh default based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 16 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837".

.. note::

  Freezer energy use is not currently affected by the ambient temperature where it is located.

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
  .. [#] Location only choice is "conditioned space".
  .. [#] If multiple dehumidifiers are entered, they must all have the same setpoint or an error will be generated.
  .. [#] The sum of all ``FractionDehumidificationLoadServed`` (across all Dehumidifiers) must be less than or equal to 1.

.. note::

  Dehumidifiers are currently modeled as located within conditioned space; the model is not suited for a dehumidifier in, e.g., a wet unconditioned basement or crawlspace.
  Therefore the dehumidifier Location is currently restricted to "conditioned space".

HPXML Cooking Range/Oven
************************

A single cooking range can be entered as a ``/HPXML/Building/BuildingDetails/Appliances/CookingRange``.
If not entered, the simulation will not include a cooking range/oven.

  ========================================  =======  ======  ===========  ========  =================  ======================================
  Element                                   Type     Units   Constraints  Required  Default            Notes
  ========================================  =======  ======  ===========  ========  =================  ======================================
  ``SystemIdentifier``                      id                            Yes                          Unique identifier
  ``Location``                              string           See [#]_     No        conditioned space  Location
  ``FuelType``                              string           See [#]_     Yes                          Fuel type
  ``IsInduction``                           boolean                       No        false              Induction range?
  ``extension/UsageMultiplier``             double           >= 0         No        1.0                Multiplier on energy use
  ``extension/WeekdayScheduleFractions``    array                         No        See [#]_           24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``    array                         No                           24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``  array                         No        See [#]_           12 comma-separated monthly multipliers
  ========================================  =======  ======  ===========  ========  =================  ======================================

  .. [#] Location choices are "conditioned space", "basement - conditioned", "basement - unconditioned", "garage", "other housing unit", "other heated space", "other multifamily buffer space", or "other non-freezing space".
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

Lighting can be specified in one of two ways: using 1) lighting type fractions or 2) annual energy consumption values.
Lighting is described using multiple ``LightingGroup`` elements for each location (interior, exterior, or garage).
If no LightingGroup elements are provided for a given location (e.g., exterior), the simulation will not include that lighting use.

If specifying **lighting type fractions**, three ``/HPXML/Building/BuildingDetails/Lighting/LightingGroup`` elements (one for each possible ``LightingType``) are entered for each lighting location:

  =============================  =======  ======  ===========  ========  =======  ===========================================================================
  Element                        Type     Units   Constraints  Required  Default  Notes
  =============================  =======  ======  ===========  ========  =======  ===========================================================================
  ``SystemIdentifier``           id                            Yes                Unique identifier
  ``LightingType``               element          1 [#]_       Yes                Lighting type
  ``Location``                   string           See [#]_     Yes                Lighting location [#]_
  ``FractionofUnitsInLocation``  double   frac    0 - 1 [#]_   Yes                Fraction of light fixtures in the location with the specified lighting type
  =============================  =======  ======  ===========  ========  =======  ===========================================================================

  .. [#] LightingType child element choices are ``LightEmittingDiode``, ``CompactFluorescent``, or ``FluorescentTube``.
  .. [#] Location choices are "interior", "garage", or "exterior".
  .. [#] Garage lighting is ignored if the building has no garage specified elsewhere.
  .. [#] The sum of FractionofUnitsInLocation for a given Location (e.g., interior) must be less than or equal to 1.
         If the fractions sum to less than 1, the remainder is assumed to be incandescent lighting.

  Interior, exterior, and garage lighting energy use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

If specifying **annual energy consumption** instead, a single ``/HPXML/Building/BuildingDetails/Lighting/LightingGroup`` element is entered for each lighting location:

  ================================  =======  ======  ===========  ========  ========  ===========================================================================
  Element                           Type     Units   Constraints  Required  Default   Notes
  ================================  =======  ======  ===========  ========  ========  ===========================================================================
  ``SystemIdentifier``              id                            Yes                 Unique identifier
  ``Location``                      string           See [#]_     Yes                 Lighting location [#]_
  ``Load[Units="kWh/year"]/Value``  double   kWh/yr  >= 0         Yes                 Lighting energy use
  ================================  =======  ======  ===========  ========  ========  ===========================================================================

  .. [#] Location choices are "interior", "garage", or "exterior".
  .. [#] Garage lighting is ignored if the building has no garage specified elsewhere.

With either lighting specification, additional information can be entered in ``/HPXML/Building/BuildingDetails/Lighting``.

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
  ================================================  =======  ======  ===========  ========  ========  ===============================================

  .. [#] If *interior* schedule values not provided (and :ref:`detailedschedules` not used), they will be calculated using Lighting Calculation Option 2 (location-dependent lighting profile) of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_.
  .. [#] If *garage* schedule values not provided (and :ref:`detailedschedules` not used), they will be defaulted using Appendix C Table 8 of the `Title 24 2016 Res. ACM Manual <https://ww2.energy.ca.gov/2015publications/CEC-400-2015-024/CEC-400-2015-024-CMF-REV2.pdf>`_.
  .. [#] If *exterior* schedule values not provided (and :ref:`detailedschedules` not used), they will be defaulted using Appendix C Table 8 of the `Title 24 2016 Res. ACM Manual <https://ww2.energy.ca.gov/2015publications/CEC-400-2015-024/CEC-400-2015-024-CMF-REV2.pdf>`_.

If exterior holiday lighting is specified, additional information is entered in ``/HPXML/Building/BuildingDetails/Lighting/extension/ExteriorHolidayLighting``.

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
  .. [#] If WeekdayScheduleFractions not provided (and :ref:`detailedschedules` not used), defaults to: 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.008, 0.098, 0.168, 0.194, 0.284, 0.192, 0.037, 0.019.

HPXML Ceiling Fans
******************

Each ceiling fan is entered as a ``/HPXML/Building/BuildingDetails/Lighting/CeilingFan``.
If not entered, the simulation will not include a ceiling fan.

  =========================================  =======  =======  ===========  ========  ========  ==============================
  Element                                    Type     Units    Constraints  Required  Default   Notes
  =========================================  =======  =======  ===========  ========  ========  ==============================
  ``SystemIdentifier``                       id                             Yes                 Unique identifier
  ``Airflow[FanSpeed="medium"]/Efficiency``  double   cfm/W    > 0          No        See [#]_  Efficiency at medium speed
  ``Count``                                  integer           > 0          No        See [#]_  Number of similar ceiling fans
  ``extension/WeekdayScheduleFractions``     array                          No        See [#]_  24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``     array                          No                  24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``   array                          No        See [#]_  12 comma-separated monthly multipliers
  =========================================  =======  =======  ===========  ========  ========  ==============================

  .. [#] If Efficiency not provided, defaults to 3000 / 42.6 based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.
  .. [#] If Count not provided, defaults to NumberofBedrooms + 1 based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), defaults based on monthly average outdoor temperatures per `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_

Ceiling fan energy use is calculated per the Energy Rating Rated Home in `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_.

.. note::

  A reduced cooling setpoint can be specified for months when ceiling fans are operating.
  See :ref:`hvac_control` for more information.

HPXML Pools & Permanent Spas
----------------------------

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

If a pool is specified, a single pool pump can be entered as a ``Pool/Pumps/Pump``.
If not entered, the simulation will not include a pool pump.

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
  .. [#] If Value not provided, defaults based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_: 158.5 / 0.070 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.25 * ConditionedFloorArea / 1920).
         If NumberofResidents provided, this value will be adjusted using the :ref:`buildingoccupancy`.
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
  .. [#] | If Value not provided, defaults as follows:
         | - **gas fired [therm/year]**: 3.0 / 0.014 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.25 * ConditionedFloorArea / 1920) (based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **electric resistance [kWh/year]**: 8.3 / 0.004 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.25 * ConditionedFloorArea / 1920) (based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **heat pump [kWh/year]**: (electric resistance) / 5.0 (based on an average COP of 5 from `Energy Saver <https://www.energy.gov/energysaver/heat-pump-swimming-pool-heaters>`_)
         | If NumberofResidents provided, this value will be adjusted using the :ref:`buildingoccupancy`.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154".

HPXML Permanent Spas
********************

A single permanent spa can be entered as a ``/HPXML/Building/BuildingDetails/Spas/PermanentSpa``.
If not entered, the simulation will not include a permanent spa.

  ====================  =======  ======  ===========  ========  ============  =================
  Element               Type     Units   Constraints  Required  Default       Notes
  ====================  =======  ======  ===========  ========  ============  =================
  ``SystemIdentifier``  id                            Yes                     Unique identifier
  ``Type``              string           See [#]_     Yes                     Permanent spa type
  ====================  =======  ======  ===========  ========  ============  =================

  .. [#] Type choices are "in ground", "on ground", "above ground", "other", "unknown", or "none".
         If "none" is entered, the simulation will not include a permanent spa.

Permanent Spa Pump
~~~~~~~~~~~~~~~~~~

If a permanent spa is specified, a single permanent spa pump can be entered as a ``PermanentSpa/Pumps/Pump``.
If not entered, the simulation will not include a permanent spa pump.

  ========================================  =======  ======  ===========  ========  ============  ======================================
  Element                                   Type     Units   Constraints  Required  Default       Notes
  ========================================  =======  ======  ===========  ========  ============  ======================================
  ``SystemIdentifier``                      id                            Yes                     Unique identifier
  ``Type``                                  string           See [#]_     Yes                     Permanent spa pump type
  ``Load[Units="kWh/year"]/Value``          double   kWh/yr  >= 0         No        See [#]_      Permanent spa pump energy use
  ``extension/UsageMultiplier``             double           >= 0         No        1.0           Multiplier on permanent spa pump energy use
  ``extension/WeekdayScheduleFractions``    array                         No        See [#]_      24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``    array                         No                      24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``  array                         No        See [#]_      12 comma-separated monthly multipliers
  ========================================  =======  ======  ===========  ========  ============  ======================================

  .. [#] Type choices are "single speed", "multi speed", "variable speed", "variable flow", "other", "unknown", or "none".
         If "none" is entered, the simulation will not include a permanent spa pump.
  .. [#] If Value not provided, defaults based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_: 59.5 / 0.059 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.25 * ConditionedFloorArea / 1920).
         If NumberofResidents provided, this value will be adjusted using the :ref:`buildingoccupancy`.
  .. [#] If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024".
  .. [#] If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used: "0.921, 0.928, 0.921, 0.915, 0.921, 1.160, 1.158, 1.158, 1.160, 0.921, 0.915, 0.921".

Permanent Spa Heater
~~~~~~~~~~~~~~~~~~~~

If a permanent spa is specified, a permanent spa heater can be entered as a ``PermanentSpa/Heater``.
If not entered, the simulation will not include a permanent spa heater.

  ======================================================  =======  ==================  ===========  ========  ========  =======================================
  Element                                                 Type     Units               Constraints  Required  Default   Notes
  ======================================================  =======  ==================  ===========  ========  ========  =======================================
  ``SystemIdentifier``                                    id                                        Yes                 Unique identifier
  ``Type``                                                string                       See [#]_     Yes                 Permanent spa heater type
  ``Load[Units="kWh/year" or Units="therm/year"]/Value``  double   kWh/yr or therm/yr  >= 0         No        See [#]_  Permanent spa heater energy use
  ``extension/UsageMultiplier``                           double                       >= 0         No        1.0       Multiplier on permanent spa heater energy use
  ``extension/WeekdayScheduleFractions``                  array                                     No        See [#]_  24 comma-separated weekday fractions
  ``extension/WeekendScheduleFractions``                  array                                     No                  24 comma-separated weekend fractions
  ``extension/MonthlyScheduleMultipliers``                array                                     No        See [#]_  12 comma-separated monthly multipliers
  ======================================================  =======  ==================  ===========  ========  ========  =======================================

  .. [#] Type choices are "none, "gas fired", "electric resistance", or "heat pump".
         If "none" is entered, the simulation will not include a permanent spa heater.
  .. [#] | If Value not provided, defaults as follows:
         | - **gas fired [therm/year]**: 0.87 / 0.011 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.25 * ConditionedFloorArea / 1920) (based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **electric resistance [kWh/year]**: 49.0 / 0.048 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.25 * ConditionedFloorArea / 1920) (based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **heat pump [kWh/year]** = (electric resistance) / 5.0 (based on an average COP of 5 from `Energy Saver <https://www.energy.gov/energysaver/heat-pump-swimming-pool-heaters>`_)
         | If NumberofResidents provided, this value will be adjusted using the :ref:`buildingoccupancy`.
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
  .. [#] | If Value not provided, defaults as:
         | - **other**: 0.91 * ConditionedFloorArea (based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_)
         | - **TV other**: 413.0 + 69.0 * NumberofBedrooms (based on `ANSI/RESNET/ICC 301-2019 <https://codes.iccsafe.org/content/RESNETICC3012019>`_)
         | - **well pump**: 50.8 / 0.127 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.25 * ConditionedFloorArea / 1920) (based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **electric vehicle charging**: 1666.67 (calculated using AnnualMiles * kWhPerMile / (ChargerEfficiency * BatteryEfficiency) where AnnualMiles=4500, kWhPerMile=0.3, ChargerEfficiency=0.9, and BatteryEfficiency=0.9)
         | If NumberofResidents provided, this value will be adjusted using the :ref:`buildingoccupancy`.
  .. [#] | If FracSensible not provided, defaults as:
         | - **other**: 0.855
         | - **TV other**: 1.0
         | - **well pump**: 0.0
         | - **electric vehicle charging**: 0.0
  .. [#] The remaining fraction (i.e., 1.0 - FracSensible - FracLatent) must be > 0 and is assumed to be heat gain outside conditioned space and thus lost.
  .. [#] | If FracLatent not provided, defaults as:
         | - **other**: 0.045
         | - **TV other**: 0.0
         | - **well pump**: 0.0
         | - **electric vehicle charging**: 0.0
  .. [#] | If WeekdayScheduleFractions not provided (and :ref:`detailedschedules` not used), defaults as:
         | - **other**: "0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036" (based on Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **TV other**: "0.037, 0.018, 0.009, 0.007, 0.011, 0.018, 0.029, 0.040, 0.049, 0.058, 0.065, 0.072, 0.076, 0.086, 0.091, 0.102, 0.127, 0.156, 0.210, 0.294, 0.363, 0.344, 0.208, 0.090" (based on the `American Time Use Survey <https://www.bls.gov/tus>`_)
         | - **well pump**: "0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065" (based on Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **electric vehicle charging**: "0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042"
  .. [#] | If WeekdendScheduleFractions not provided (and :ref:`detailedschedules` not used), defaults as:
         | - **other**: "0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036" (based on Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **TV other**: "0.044, 0.022, 0.012, 0.008, 0.011, 0.014, 0.024, 0.043, 0.071, 0.094, 0.112, 0.123, 0.132, 0.156, 0.178, 0.196, 0.206, 0.213, 0.251, 0.330, 0.388, 0.358, 0.226, 0.103" (based on the `American Time Use Survey <https://www.bls.gov/tus>`_)
         | - **well pump**: "0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065" (based on Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **electric vehicle charging**: "0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042"
  .. [#] | If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), defaults as:
         | - **other**: "1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248" (based on Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **TV other**: "1.137, 1.129, 0.961, 0.969, 0.961, 0.993, 0.996, 0.96, 0.993, 0.867, 0.86, 1.137" (based on the `American Time Use Survey <https://www.bls.gov/tus>`_)
         | - **well pump**: "1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154" (based on Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_)
         | - **electric vehicle charging**: "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0"

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
  .. [#] | If Value not provided, calculated as based on the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_:
         | - **grill**: 0.87 / 0.029 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.25 * ConditionedFloorArea / 1920)
         | - **fireplace**: 1.95 / 0.032 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.25 * ConditionedFloorArea / 1920)
         | - **lighting**: 0.22 / 0.012 * (0.5 + 0.25 * NumberofBedrooms / 3 + 0.25 * ConditionedFloorArea / 1920)
         | If NumberofResidents provided, this value will be adjusted using the :ref:`buildingoccupancy`.
  .. [#] FuelType choices are "natural gas", "fuel oil", "fuel oil 1", "fuel oil 2", "fuel oil 4", "fuel oil 5/6", "diesel", "propane", "kerosene", "coal", "coke", "bituminous coal", "anthracite coal", "wood", or "wood pellets".
  .. [#] If FracSensible not provided, defaults to 0.5 for fireplace and 0.0 for all other types.
  .. [#] The remaining fraction (i.e., 1.0 - FracSensible - FracLatent) must be > 0 and is assumed to be heat gain outside conditioned space and thus lost.
  .. [#] If FracLatent not provided, defaults to 0.1 for fireplace and 0.0 for all other types.
  .. [#] | If WeekdayScheduleFractions or WeekendScheduleFractions not provided (and :ref:`detailedschedules` not used), default values from Figure 23 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used:
         | - **grill**: "0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007";
         | - **fireplace**: "0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065";
         | - **lighting**: "0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065".
  .. [#] | If MonthlyScheduleMultipliers not provided (and :ref:`detailedschedules` not used), default values from Figure 24 of the `2010 BAHSP <https://www1.eere.energy.gov/buildings/publications/pdfs/building_america/house_simulation.pdf>`_ are used:
         | - **grill**: "1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097";
         | - **fireplace**: "1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154";
         | - **lighting**: "1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154".

.. _hpxmllocations:

HPXML Locations
---------------

The various locations used in an HPXML file are defined as follows:

  ==============================  =======================================================  ============================================  =================
  Value                           Description                                              Temperature                                   Building Type
  ==============================  =======================================================  ============================================  =================
  outside                         Ambient environment                                      Weather data                                  Any
  ground                                                                                   EnergyPlus calculation                        Any
  conditioned space               Above-grade conditioned space maintained at setpoint     EnergyPlus calculation                        Any
  attic - vented                                                                           EnergyPlus calculation                        Any
  attic - unvented                                                                         EnergyPlus calculation                        Any
  basement - conditioned          Below-grade conditioned space maintained at setpoint     EnergyPlus calculation                        Any
  basement - unconditioned                                                                 EnergyPlus calculation                        Any
  crawlspace - vented                                                                      EnergyPlus calculation                        Any
  crawlspace - unvented                                                                    EnergyPlus calculation                        Any
  crawlspace - conditioned        Below-grade conditioned space maintained at setpoint     EnergyPlus calculation                        Any
  garage                          Single-family garage (not shared parking)                EnergyPlus calculation                        Any
  manufactured home underbelly    Underneath the belly, ambient environment                Weather data                                  Manufactured only
  manufactured home belly         Within the belly                                         Same as conditioned space                     Manufactured only              
  other housing unit              E.g., conditioned adjacent unit or conditioned corridor  Same as conditioned space                     SFA/MF only
  other heated space              E.g., shared laundry/equipment space                     Avg of conditioned space/outside; min of 68F  SFA/MF only
  other multifamily buffer space  E.g., enclosed unconditioned stairwell                   Avg of conditioned space/outside; min of 50F  SFA/MF only
  other non-freezing space        E.g., shared parking garage ceiling                      Floats with outside; minimum of 40F           SFA/MF only
  other exterior                  Water heater outside                                     Weather data                                  Any
  exterior wall                   Ducts in exterior wall                                   Avg of conditioned space/outside              Any
  under slab                      Ducts under slab (ground)                                EnergyPlus calculation                        Any
  roof deck                       Ducts on roof deck (outside)                             Weather data                                  Any
  ==============================  =======================================================  ============================================  =================

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
