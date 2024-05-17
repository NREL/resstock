================
v2.4.0 Changelog
================

.. changelog::
    :version: v2.4.0
    :released: 2021-01-27

    .. change::
        :tags: todo, todo, feature
        :pullreq: 458

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Report the annual peak use and timing using the quantities of interest measure
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 348

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Major change to most occupant-related schedules. Occupant activities are now generated on-the-fly and saved to .csv files used by Schedule:File objects. Schedules are generated using time-inhomogenous Markov chains derived from American Time Use Survey data, supplemented with sampling duration and power level from NEEA RBSA data, as well as DHW draw duration and flow rate data from Aquacraft/AWWA data [(see pre-print for details)](https://arxiv.org/abs/2111.01881)
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 468

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Update the dependencies for heating and cooling setpoint tsvs (Setpoint, Has Offset, Offset Magnitude, and Offset Period) to IECC climate zone
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 473

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Distinguish between vacant and occupied dwelling units using PUMS data
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 474

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Update heating fuel distributions to be by Public Use Microdata Area (PUMA) rather than State
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 478

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Restructure HVAC housing characteristics to 1) simplify the structure, 2) allow for integrating more local data sources, 3) update reference years for HVAC and refrigerator ages and efficiencies from 2009 to 2018, 4) add assumption comments to all HVAC-related housing characteristics, 5) improve Room AC efficiency distributions using ENERGY STAR saturation data, and 6) fix some incorrect assignment of Option=None heating systems
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 485

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Increase roofing material options; update roofing material tsv files to include these new options
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 492

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Update foundation type from the [Building Foundation Design Handbook](https://www.osti.gov/biblio/6980439-building-foundation-design-handbook) published in 1988 to RECS 2009
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 507

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Synchronize weather between ResStock and ComStock which increases the number of weather stations from 215 to 941
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 509

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Update Occupants per unit from RECS 2015 to PUMS 5-yr 2017
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 471

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Based on RECS 2015, separate the plug load equations for single-family detached, single-family attached, and multifamily buildings
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 511

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Allow for plug load energy consumption to vary by Census Division and include additional "diversity" multiplier in plug load equations
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 510

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Lighting saturations based on RECS 2015 with new building type and spatial dependencies
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 513

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Introduce premium water heaters and heat pump water heaters into building stock, differentiate between central and in-unit water heating, and split water heater fuel and efficiency into different housing characteristics
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 512

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Separate heat pump electric supplemental heating from total electric heating in output reporting
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 532

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Update the duct leakage "total" to "to outside" conversion to be based on ASHRAE Standard 152
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 525

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Allow for flexible weather regions based on weather data available and introduce TMY3 weather files for the new weather format
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 477

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Fix for pseudo-random number generator that was generating non-deterministic occupancy schedules
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 480

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Iterate all spaces in a thermal zone when checking for zone type; fixes missing infiltration for protruding garages in 1-story homes
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 486

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Update spatial distribution of units based on total dwelling unit counts rather than occupied unit counts
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 496

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Exclude existing shared walls when calculating the partition wall area of MF and SFA buildings
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 501

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        For the purpose of calculating cooling and dehumidification loads for HVAC sizing, use simple internal gains equation from ANSI/RESNET/ICC 301 (consistent with HPXML workflow); this fixes a bug introduced in [#348](https://github.com/NREL/resstock/pull/348) that caused cooling capacities to be ~3x larger than they should be
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 497

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Reintroduce IECC climate zone dependency to HVAC Cooling Type and some heat pump fixes
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 504

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Reintroduce monthly multipliers with stochastic load model for dishwasher, clothes washer and clothes dryer and cooking
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 518

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Account for collapsed units when determining geometry variables (building floor/wall area and volume) in infiltration calculations; add airflow unit tests
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 523

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Fix for calculating door and below-grade wall area of multifamily and single-family attached buildings with collapsed geometries
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 522

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        In the Corridor.tsv, assign single-family attached, single-family detached, and mobile homes with a "Not Applicable" option
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 527

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Remove ceiling fan energy for vacant units
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 528

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Fix bug related to incorrect timestamps when using AMY weather file
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 530

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Fix DST start hour error and end date error
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 537

        **Date**: 2021-01-27

        Title:
        TODO

        Description:
        Calculate slab surface effective R values used in HVAC sizing with unit-level variables
        TODO

        Assignees: TODO


