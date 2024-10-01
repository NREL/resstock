=====================
Development Changelog
=====================

.. changelog::
    :version: v3.4.0
    :released: pending

    .. change::

        :tags: bugfix, characteristics
        :pullreq: 1265
        :tickets: 1236

        **Date**: 2024-08-06

        Title:
        Fix Hot Water Fixtures multipliers

        Description:
        Mean-shift hot water usage multipliers distribution by increasing weighted average from 0.8 to 1.0 in Hot Water Fixtures.tsv.

        Assignees: Lixi Liu

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
        :tags: characteristics, floor area, bugfix
        :pullreq: 1301

        **Date**: 2024-09-18

        Title:
        Fix RECS floor area bins

        Description:
        RECS have been using incorrect floor area bins when assigning some characteristics due to a bug on how floor area bin is calculated. This PR fixes the issue.

        Assignees: Rajendra Adhikari, Anthony Fontanini

    .. change::
        :tags: workflow, hot water, feature
        :pullreq: 1282

        **Date**: 2024-09-04

        Title:
        Latest OS-HPXML

        Description:
        For hot water end uses OS-HPXML now directly uses equations from https://www.fsec.ucf.edu/en/publications/pdf/fsec-pf-464-15.pdf, that are a function of number of occupants, for operational calculations.

        OpenStudio-HPXML: `pull request 1761 <https://github.com/NREL/OpenStudio-HPXML/pull/1761>`_

        Assignees: Joe Robertson


    .. change::
        :tags: workflow, plug loads, feature
        :pullreq: 1298

        **Date**: 2024-09-24

        Title:
        Latest OS-HPXML

        Description:
        For TV plug loads, we are now using OS-HPXML defaults that directly use equations from RECS 2020 that are a function of number of occupants and conditioned floor area.
        For operational calculations in general, we are also updating the relationships between number of bedrooms/occupants based on RECS 2020 and disaggregated by building types.

        OpenStudio-HPXML: `pull request 1690 <https://github.com/NREL/OpenStudio-HPXML/pull/1690>`_, `pull request 1775 <https://github.com/NREL/OpenStudio-HPXML/pull/1775>`_

        Assignees: Joe Robertson


    .. change::
        :tags: workflow, hvac, feature
        :pullreq: 1254

        **Date**: 2024-09-27

        Title:
        Heating and Cooling Unavailable Days

        Description:
        The purpose of this PR is to account for dwelling units whose HVAC system (heating/cooling) is unavailable for some number of days during the year (per RECS 2020).
        Specifically, this PR modifies HVAC heating/cooling seasons using number of unavailable days and BAHSP definition for heating/cooling months.

        Assignees: Joe Robertson


    .. change::
        :tags: buxfix, floor area
        :pullreq: 1284

        **Date**: 2024-10-01

        Title:
        Update Avg Conditioned Floor Area

        Description:
        Reconcile differences between the AHS floor area definition and the OpenStudio-HPXML conditioned floor area. The change updates ResStockArguments to include
        Different floor area values for homes with and without heated basements. AHS includes unheated basements in the floor area definition. So sometimes when the
        unit has an unheated basement, then the modeled conditioned floor area is smaller than the lower bound of the floor area bin range. This fix also assigns
        floor areas for manufactured homes, where previously they were the same as single-family detached units.

        Assignees: Rajendra Adhikari, Anthony Fontanini
