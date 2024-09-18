=====================
Development Changelog
=====================

.. changelog::
    :version: v3.4.0
    :released: pending

    .. change::
        :tags: workflow, infiltration, bugfix
        :pullreq: 1257

        **Date**: 2024-08-20

        Title:
        Air leakage type "unit total"

        Description:
        Update options_lookup and ResStockArguments to use "unit total" air leakage type instead of the current "unit exterior only" type w/ infiltration adjustment approach.
        Modeled infiltration for dwelling units now have an upper bound equal to the sampled ACH50 option.
        Update BuildExistingModel to register adjusted total infiltration ACH50 value.

        Assignees: Joe Robertson


    .. change::
        :tags: workflow, hot water, feature
        :pullreq: 1282

        **Date**: 2024-09-04

        Title:
        Latest OS-HPXML

        Description:
        For hot water end uses OS-HPXML now directly uses equations from https://www.fsec.ucf.edu/en/publications/pdf/fsec-pf-464-15.pdf, that are a function of number of occupants, for operational calculations.

        Assignees: Joe Robertson


    .. change::
        :tags: workflow, plug loads, feature
        :pullreq: 1298

        **Date**: 2024-09-05

        Title:
        Latest OS-HPXML

        Description:
        For TV plug loads, we are now using OS-HPXML defaults that directly use equations from RECS 2020 that are a function of number of occupants and conditioned floor area.
        For operational calculations in general, we are also updating the relationships between number of bedrooms/occupants based on RECS 2020 and disaggregated by building types.

        Assignees: Joe Robertson


    .. change::
        :tags: workflow, hvac, feature
        :pullreq: 1254

        **Date**: 2024-09-218

        Title:
        Heating and Cooling Unavailable Days

        Description:
        The purpose of this PR is to account for dwelling units whose HVAC system (heating/cooling) is unavailable for some number of days during the year (per RECS 2020).
        Specifically, this PR modifies HVAC heating/cooling seasons using number of unavailable days and BAHSP definition for heating/cooling months.

        Assignees: Joe Robertson
