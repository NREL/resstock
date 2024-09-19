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
