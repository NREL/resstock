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
        :tags: workflow, feature, utility bills
        :pullreq: 1197
        :tickets: 1154

        **Date**: 2024-07-25

        Title:
        HVAC Autosizing Limits

        Description:
        For ducted HVAC system upgrades, adds the ability to (1) limit the autosized capacity to the maximum of the existing duct system's heating/cooling airflow rates, and (2) adjust the blower fan efficiency to maintain the duct system curve, using only a single option from the lookup.

        Assignees: Joe Robertson
