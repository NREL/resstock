=====================
Development Changelog
=====================

.. changelog::
    :version: v3.4.0
    :released: pending

    .. change::
        :tags: workflow, hvac, feature
        :pullreq: 1254

        **Date**: 2024-08-21

        Title:
        Heating and Cooling Unavailable Days

        Description:
        The purpose of this PR is to account for dwelling units whose HVAC system (heating/cooling) is unavailable for some number of days during the year (per RECS 2020).
        Specifically, this PR modifies HVAC heating/cooling seasons using number of unavailable days and BAHSP definition for heating/cooling months.

        Assignees: Joe Robertson
