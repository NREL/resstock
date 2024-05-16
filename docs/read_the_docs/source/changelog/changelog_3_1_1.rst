================
v3.1.1 Changelog
================

.. changelog::
    :version: v2023.11.0
    :released: 2023-11-27

    .. change::
        :tags: eagle, bugfix
        :pullreq: 406
        :tickets: 404

        Cleans out the ``/tmp/scratch`` folder on Eagle at the end of each array job.

    .. change::
        :tags: documentation
        :pullreq: 410
        :tickets: 408

        Update cost multiplier link in upgrade scenarios documentation.

    .. change::
        :tags: bugfix
        :pullreq: 418
        :tickets: 411

        Fixing ``started_at`` and ``completed_at`` timestamps in parquet files
        to that when read by AWS Glue/Athena they show up as dates rather than
        bigints.

    .. change::
        :tags: general, feature, kestrel
        :pullreq: 405
        :tickets: 313

        Add support for NREL's Kestrel supercomputer.

    .. change::
        :tags: general, postprocessing
        :pullreq: 414
        :tickets: 412

        Add support for an AWS service account on Kestrel/Eagle so the user
        doesn't have to manage AWS keys.

    .. change::
        :tags: documentation
        :pullreq: 419

        Update weather file location argument name in custom weather files documentation.
