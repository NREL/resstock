================
v2.3.0 Changelog
================

.. changelog::
    :version: v2.3.0
    :released: 2020-06-24

    .. change::
        :tags: todo, todo, feature
        :pullreq: 402

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Remove the single-family detached project, and remove PAT from the testing and multifamily projects
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 401

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Relocate the data folder, along with tsv makers, to a separate private repository
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 392

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Update the single-family detached and multifamily projects with more up-to-date lighting stock distributions
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 395

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Update Insulation Finished Attic tsv with more options for insulation levels
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 408

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Add ability to ignore comment lines with the "#" symbol
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 324

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Update occupant and plug loads equations based on RECS 2015 data; replace floor area with occupants as independent variable in plug loads equation; allow modeling of zero-bedroom units (e.g., studios)
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 416

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        New geospatial characteristics have been added or updated. New geospatial characteristics are as follows: ASHRAE IECC Climate Zone 2004, State, County, PUMA, Census Division, Census Region, Building America Climate Zone, and ISO/RTO Region. The top level housing characteristic is now ASHRAE IECC Climate Zone 2004. Now using data from the American Community Survey Public Use Microdata Sample (ACS PUMS) for Building Type, Vintage, and Heating Fuel
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 418

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Update HVAC System Cooling tsv with air-conditioning saturations ("None", "Room AC", or "Central AC") from American Housing Survey for Custom Region 04. Efficiency probabilities remain based on RECS 2009
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 414

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Diversify the timing heating and cooling setpoint setbacks
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 420

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Reduce the number of appliances in multifamily units. Adding RECS building type as a dependencies to clothes washers, clothes dryers, dishwashers, refrigerators, extra refrigerators, and stand-alone freezers. Update refrigeration levels based on RECS 2009 age and shipment-weighted efficiency by year. Now using the American Housing Survey (AHS) for clothes washer and clothes dryer saturations. New geographic field, AHS Region, which uses the top 15 largest Core Based Statistical Areas (CBSAs) and Non-CBSA Census Divisions
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 419

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Exterior lighting schedule changed from using interior lighting sunrise/sunset algorithm to T24 2016 Residential ACM Appendix C Table 8 Exterior Lighting Hourly Multiplier for weekdays and weekends
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 425

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Increase the diversity of the floor areas that are simulated. Geometry House Size has been replaced by Geometry Floor Area Bin and Geometry Floor Area. Now using AHS for specifying the floor area. Floor areas differ by non-Core Based Statistical Areas (CBSAs) Census Divisions and the top 15 largest CBSAs
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 427

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Increase the diversity of the infiltration simulated. Now using the Residential Diagnostics Database for the Infiltration housing characteristic
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, feature
        :pullreq: 438

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Allow a key value to be specified when outputting timeseries variables
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 459

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Rename "project_multifamily_beta" to "project_national"
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 454

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Add mini-split heat pump pan heater to custom meter for heating electricity
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 453

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Assign daylight saving start/end dates based on county and not epw region
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 445

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Update ceiling fan tsv to remove the "National Average" option, and instead sample 28% "None" and 72% "Standard Efficiency"
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 432

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Remove Location Weather Filename and Location Weather Year tsvs, and update options lookup to reflect updated weather file changes; weather filenames are now required to match what is in the options lookup
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 433

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Fix bug in QOI reporting measure where absence of any heating/cooling/overlap seasons would cause errors
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 426

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Restructure unfinished attic and finished roof -related tsv files (i.e., insulation, roof material, and radiant barrier) and options
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 405

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Exclude net site energy consumption from annual and timeseries simulation output ("total" now reflects net of pv); change `include_enduse_subcategories` argument default to "true"; report either total interior equipment OR each of its components
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 392

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Refactor the tsv maker classes to accommodate more data sources
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 375

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Allow a building to be simulated with no water heater; map the "Other Fuel" option from the Water Heater tsv to no water heater
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 355

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Revert plug load schedule to RBSA for the National Average option
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 416

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Removed the "Geometry Unit Stories SF" and "Geometry Unit Stories MF" housing characteristics. Unit stories are instead represented by the "Geometry Stories" housing characteristic
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 412

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Diversify window to wall ratio variation using the Residential Building Stock Assessment (RBSA) II data
        TODO

        Assignees: TODO


    .. change::
        :tags: todo, todo, bugfix
        :pullreq: 452

        **Date**: 2020-06-24

        Title:
        TODO

        Description:
        Fix bug in assigning small window areas to surfaces
        TODO

        Assignees: TODO


