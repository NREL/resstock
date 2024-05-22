=====================
Development Changelog
=====================

.. changelog::
    :version: v3.3.0
    :released: pending

    .. change::
        :tags: software, openstudio, feature
        :pullreq: 1225

        **Date**: 2024-05-09

        Title:
        OpenStudio 3.8/EnergyPlus 24.1

        Description:
        Update to OpenStudio v3.8.0
        OpenStudio 3.8/EnergyPlus 24.1

        Assignees: Joe, Scott


    .. change::
        :tags: characteristics, ducts, feature
        :pullreq: 1233

        **Date**: 2024-05-07

        Title:
        Updates duct effective R-values; allows duct shape inputs

        Description:
        Update to new OS-HPXML defaults for duct insulation; 25% rectangular supply ducts and 100% rectangular return ducts (previously 100% round supply/return ducts)
        Adds optional inputs (Ducts/DuctShape and Ducts/DuctFractionRectangular); defaults to 25% rectangular supply ducts and 100% rectangular return ducts (previously 100% round supply/return ducts).

        OpenStudio-HPXML: `pull request 1691 <https://github.com/NREL/OpenStudio-HPXML/pull/1691>`_

        Assignees: Scott


    .. change::
        :tags: workflow, hvac, feature
        :pullreq: 1233

        **Date**: 2024-05-07

        Title:
        HVAC Autosizing Limits

        Description:
        HVAC
        The PR aims to allow specifying upper limits for autosized capacities.

        OpenStudio-HPXML: `pull request 1584 <https://github.com/NREL/OpenStudio-HPXML/pull/1584>`_

        Assignees: Joe


    .. change::
        :tags: workflow, hvac, bugfix
        :pullreq: 1218

        **Date**: 2024-04-09

        Title:
        HVAC Autosizing Factors

        Description:
        Enable HVAC airflow and capacity scaling factors to oversize or undersize the equipment
        Manually create new tsv files for assigning autosizing factor arguments introduced by NREL/OpenStudio-HPXML#1611

        resstock-estimation: `pull request 406 <https://github.com/NREL/resstock-estimation/pull/406>`_

        Assignees: Joe


    .. change::
        :tags: characteristics, plug loads, ceiling fan, feature
        :pullreq: 1220

        **Date**: 2024-04-02

        Title:
        Update Other, TV, and Ceiling Fan stochastic schedules

        Description:
        Update the stochastic schedule generator to produce updated other/TV plug load and ceiling fan schedules
        generate TV schedules that follow the ATUS TV schedule fractions (distinct weekday/weekend) and multipliers (and not Other schedule fractions and multipliers).
        generate Other schedules that follow the new Other schedule fractions (still uses non-constant 2010 BAHSP monthly multipliers).
        generate Ceiling Fan schedules that follow the new Ceiling Fan schedule fractions (also update multipliers to not follow Other multipliers, but rather Ceiling Fan multipliers that are a function of weather)

        OpenStudio-HPXML: `pull request 1634 <https://github.com/NREL/OpenStudio-HPXML/pull/1634>`_

        Assignees: Joe


    .. change::
        :tags: characteristics, alaska, bugfix
        :pullreq: 1214

        **Date**: 2024-03-18

        Title:
        Integrate ARIS data

        Description:
        Update the Alaska residential stock characterization using the Alaska Retrofit Information System data
        Update housing characteristics for Alaska using ARIS dataset. Explicitly model wood heating for the national.

        resstock-estimation: `pull request 381 <https://github.com/NREL/resstock-estimation/pull/381>`_

        Assignees: Rajendra, Tony


    .. change::
        :tags: workflow, hvac, feature
        :pullreq: 1215

        **Date**: 2024-03-11

        Title:
        HVAC Autosizing Factors

        Description:
        Add ability to specify HVAC system autosizing factors for baseline buildings; autosizing factors are retained for upgrade buildings following the same approach for HVAC system capacities
        Allows optional HeatingAutosizingFactor, CoolingAutosizingFactor, BackupHeatingAutosizingFactor inputs to scale HVAC equipment autosizing results.

        OpenStudio-HPXML: `pull request 1611 <https://github.com/NREL/OpenStudio-HPXML/pull/1611>`_

        Assignees: Joe, Yueyue


    .. change::
        :tags: workflow, weather, feature
        :pullreq: 1215

        **Date**: 2024-03-11

        Title:
        Allow building site inputs

        Description:
        nan
        Allow building site inputs; this is particularly useful when the building is located far from, or at a very different elevation than, the EPW weather station. When not provided, defaults to using EPW header values (as before).

        OpenStudio-HPXML: `pull request 1636 <https://github.com/NREL/OpenStudio-HPXML/pull/1636>`_

        Assignees: Scott


    .. change::
        :tags: characteristics, socio-demographics, feature
        :pullreq: 1212

        **Date**: 2024-02-29

        Title:
        Add SMI, MSA, Metro Status

        Description:
        Add Metropolitan and Micropolitan Statistical Area tsv, County Metro Status tsv, and State Metro Median Income tsv
        Added 3 new tsvs to support @SinounPhoung's socio-demographically differentiated Stochastic Occupant Schedule integration into ResStock

        resstock-estimation: `pull request 400 <https://github.com/NREL/resstock-estimation/pull/400>`_

        Assignees: Lixi


    .. change::
        :tags: characteristics, water heater, bugfix
        :pullreq: 1201

        **Date**: 2024-02-28

        Title:
        Update water heater location

        Description:
        Move location of out-of-unit (shared) water heaters to conditioned mechanical room
        Move out-of-unit water heaters (i.e., Water Heater In Unit=No from Location=None to Location=Conditioned Mechanical Room (corresponds to OS-HPXML location: "other heated space").

        Assignees: Lixi, Jeff, Tony


    .. change::
        :tags: workflow, unavailable periods, feature
        :pullreq: 1209

        **Date**: 2024-02-23

        Title:
        BuildResidentialHPXML: multiple vacancy/outage periods

        Description:
        Allow definition of multiple unavailable periods (i.e., vacancy, power outage)
        Update schedules_vacancy_period and schedules_power_outage_period arguments to support multiple periods (comma-separated?). Argument schedules_power_outage_window_natvent_availability would then need to also be comma-separated?

        OpenStudio-HPXML: `pull request 1622 <https://github.com/NREL/OpenStudio-HPXML/pull/1622>`_

        Assignees: Joe


    .. change::
        :tags: workflow, heat pump backup, feature
        :pullreq: 1209

        **Date**: 2024-02-23

        Title:
        HP backup sizing methodology

        Description:
        Add ability to set either an "emergency" or "supplemental" heat pump backup sizing methodology
        Adds a HeatPumpBackupSizingMethodology element with choices of 'emergency' and 'supplemental'. Defaults to 'emergency', so results do not change by default.

        OpenStudio-HPXML: `pull request 1597 <https://github.com/NREL/OpenStudio-HPXML/pull/1597>`_

        Assignees: Scott


    .. change::
        :tags: characteristics, refrigerator, feature
        :pullreq: 1209

        **Date**: 2024-02-23

        Title:
        ANSI 301-2022: load profile schedules

        Description:
        Refrigerator energy use is now affected by its ambient temperature using hourly constant and temperature coefficients from ANSI/RESNET/ICC 301-2022 Addendum C
        Default fridge schedule is now an actuated EMS program. Daily schedule is a function of hour and space temperature.

        OpenStudio-HPXML: `pull request 1572 <https://github.com/NREL/OpenStudio-HPXML/pull/1572>`_

        Assignees: Joe


    .. change::
        :tags: workflow, general water use, feature
        :pullreq: 1209

        **Date**: 2024-02-23

        Title:
        ANSI 301-2022: load profile schedules

        Description:
        nan
        Various schedule fractions/multipliers updates (e.g., appliances, lighting, fixtures, occupancy, ceiling fan).

        OpenStudio-HPXML: `pull request 1572 <https://github.com/NREL/OpenStudio-HPXML/pull/1572>`_

        Assignees: Joe


    .. change::
        :tags: workflow, ceiling fan, feature
        :pullreq: 1209

        **Date**: 2024-02-23

        Title:
        ANSI 301-2022: load profile schedules

        Description:
        nan
        For ceiling fans, add a LabelEnergyUse (W) input as an alternative to Efficiency (cfm/W).

        OpenStudio-HPXML: `pull request 1609 <https://github.com/NREL/OpenStudio-HPXML/pull/1609>`_

        Assignees: Joe


    .. change::
        :tags: characteristics, hot water fixtures, feature
        :pullreq: 1210

        **Date**: 2024-02-21

        Title:
        Updating hot water fixtures multipliers based on field data.

        Description:
        Update hot water usage multipliers based on field data rather than engineering judgement
        Update hot water usage multipliers. Using field data from 1700 water heaters in New England to come up with the distribution. Based on data collected as part of PERFORM with Michael Blonsky, who shared the distribution with us.

        resstock-estimation: `pull request 361 <https://github.com/NREL/resstock-estimation/pull/361>`_

        Assignees: Jeff, Tony


    .. change::
        :tags: workflow, whole building, feature
        :pullreq: 1200

        **Date**: 2024-01-30

        Title:
        Whole MF building models: Replace building_id=ALL argument with an HPXML element

        Description:
        Add optional switch to BuildExistingModel (defaulted to false) for modeling whole SFA/MF buildings
        Replaces building_id=ALL argument with an element in the HPXML file, which allows us to perform validation specific to whole MF building simulations

        Assignees: Joe, Scott


    .. change::
        :tags: characteristics, data sources, bugfix
        :pullreq: 1199

        **Date**: 2024-01-26

        Title:
        Update characteristics using 2020 RECS v7 data

        Description:
        Update to RECS 2020 V7 data files
        Updates RECS 2020 data from v5 to v7. There are some new EV variables to be leveraged by the ResStock/TEMPO project. I am not sure what V6 was as there is no documentation.

        resstock-estimation: `pull request 394 <https://github.com/NREL/resstock-estimation/pull/394>`_

        Assignees: Tony


    .. change::
        :tags: workflow, mechanics, bugfix
        :pullreq: 1195

        **Date**: 2024-01-22

        Title:
        Reorganize emissions and utility bills data folders

        Description:
        Reorganize the emissions and utility rates data folders such that their sources and functions are more clear
        Previously, it wasn't clear that the provided utility rate data was for demonstration purposes only.

        Assignees: Joe


    .. change::
        :tags: workflow, emissions, feature
        :pullreq: 1194

        **Date**: 2024-01-19

        Title:
        2022 Cambium: add 25 year levelization scenarios

        Description:
        Include additional 2022 Cambium 25-year LRMER emissions data
        Add 10 new "LRMER_xxx_25" data folders to resources/data/cambium/2022.

        Assignees: Joe


    .. change::
        :tags: workflow, radiant barrier, feature
        :pullreq: 1188

        **Date**: 2024-01-17

        Title:
        Adding flexibility to specify location of the radiant barrier

        Description:
        Add flexibility to specify location of the radiant barrier
        Allowing Radiant Barrier for Attic Floor

        OpenStudio-HPXML: `pull request 1473 <https://github.com/NREL/OpenStudio-HPXML/pull/1473>`_

        Assignees: Prateek


    .. change::
        :tags: workflow, hvac, feature
        :pullreq: 1188, 1200

        **Date**: 2024-01-17

        Title:
        Allow autosizing with detailed performance data inputs for var speed systems
        BuildResidentialHPXML: detailed performance data arguments

        Description:
        Add ability to describe detailed performance data for variable-speed air-source HVAC systems
        Updated assumptions for variable-speed air conditioners, heat pumps, and mini-splits.
        Also allows detailed heating and cooling performance data (min/max COPs and capacities at different outdoor temperatures) as an optional set of inputs. 
        Data can be sourced from e.g. NEEP's Cold Climate Air Source Heat Pump List.
        Add detailed performance data arguments for air-source, variable-speed HVAC systems.

        OpenStudio-HPXML: `pull request 1583 <https://github.com/NREL/OpenStudio-HPXML/pull/1583>`_, `pull request 1317 <https://github.com/NREL/OpenStudio-HPXML/pull/1317>`_, `pull request 1558 <https://github.com/NREL/OpenStudio-HPXML/pull/1558>`_

        Assignees: Yueyue, Scott, Joe


    .. change::
        :tags: workflow, water heater, bugfix
        :pullreq: 1190

        **Date**: 2024-01-12

        Title:
        Remove old HPWH options from options_lookup

        Description:
        Remove old HPWH options from options_lookup
        Removing the old HPWH options from options_lookup.tsv

        Assignees: Jeff


    .. change::
        :tags: workflow, mechanics, feature
        :pullreq: 1230

        **Date**: 2024-05-16

        Title:
        Run run_analysis in parallel

        Description:
        Introduce a new optional `buildstock_csv_path` argument that supports parallel resstock runs using `run_analysis.rb`
        I know this is an odd workflow, but I'd like to call resstock in parallel, to run multiple models (baseline only) built each with a precomputed buildstock.csv

        Assignees: Julien


    .. change::
        :tags: workflow, reporting, feature
        :pullreq: 1240

        **Date**: 2024-05-16

        Title:
        Latest OS-HPXML

        Description:
        Improves heating/cooling component loads; for timesteps where there is no heating/cooling load, assigns heat transfer to heating or cooling by comparing indoor temperature to the average of heating/cooling setpoints
        Improves heating/cooling component loads; for timesteps where there is no heating/cooling load, assigns heat transfer to heating or cooling by comparing indoor temperature to the average of heating/cooling setpoints.

        Assignees: Andrew


    .. change::
        :tags: workflow, reporting, feature
        :pullreq: 1240

        **Date**: 2024-05-16

        Title:
        Latest OS-HPXML

        Description:
        Additional geothermal loop default simulation outputs (number/length of boreholes)
        Adds geothermal loop outputs (number/length of boreholes) to annual results output file.

        Assignees: Scott


    .. change::
        :tags: workflow, infiltration, feature
        :pullreq: 1240

        **Date**: 2024-05-16

        Title:
        Latest OS-HPXML

        Description:
        Updates default `ShieldingofHome` to be "well-shielded" (from "normal") for single-family attached and multifamily dwelling units
        Updates default ShieldingofHome to be "well-shielded" for single-family attached and multifamily dwelling units.

        Assignees: Scott


    .. change::
        :tags: workflow, plug loads, feature
        :pullreq: 1213

        **Date**: 2024-05-21

        Title:
        Split out Other and TV plug loads

        Description:
        Split out TV plug loads (calculated using an equation based on ANSI/RESNET/ICC 301) from other plug loads (calculated using updated regression equations based on RECS2020)
        For TV, we are now using OS-HPXML defaults (i.e., TV = 413.0 + 69.0 * NumberofBedrooms based on ANSI/RESNET/ICC 301-2019, where NumberofBedrooms is adjusted based on NumberofResidents).
        Create a new sources/recs/recs2020/plug_loads/mel_ann.py script.

        resstock-estimation: `pull request 401 <https://github.com/NREL/resstock-estimation/pull/401>`_

        Assignees: Joe, Tony


