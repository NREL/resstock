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

        OpenStudio-HPXML: `pull request 1761 <https://github.com/NREL/OpenStudio-HPXML/pull/1761>`_

        Assignees: Joe Robertson


    .. change::
        :tags: workflow, plug loads, feature
        :pullreq: 1298

        **Date**: 2024-09-19

        Title:
        Latest OS-HPXML

        Description:
        For TV plug loads, we are now using OS-HPXML defaults that directly use equations from RECS 2020 that are a function of number of occupants and conditioned floor area.
        For operational calculations in general, we are also updating the relationships between number of bedrooms/occupants based on RECS 2020 and disaggregated by building types.

        OpenStudio-HPXML: `pull request 1690 <https://github.com/NREL/OpenStudio-HPXML/pull/1690>`_, `pull request 1775 <https://github.com/NREL/OpenStudio-HPXML/pull/1775>`_

        Assignees: Joe Robertson
