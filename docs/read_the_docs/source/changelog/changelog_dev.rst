=====================
Development Changelog
=====================

.. changelog::
    :version: development
    :released: It has not been

    .. change::
        :tags: general, feature
        :pullreq: 101
        :tickets: 101

        This is an example change. Please copy and paste it - for valid tags please refer to ``conf.py`` in the docs
        directory. ``pullreq`` should be set to the appropriate pull request number and ``tickets`` to any related
        github issues. These will be automatically linked in the documentation.

    .. change::
        :tags: general
        :pullreq: 421

        Refactor docker_base to use inversion of control so that it can more strongly and easily ensure consistency
        between various implementations (GCP implementation to come). This also includes teasing apart the several batch
        prep steps (weather, assets, and jobs) into their own methods so they can each be more easily understood,
        shared, and maintained.

    .. change::
        :tags: general
        :pullreq: 422

        Refactor AWS code so it can be shared by the upcoming GCP implementation.

    .. change::
        :tags: general, bugfix
        :pullreq: 426

        A bugfix for gracefully handling empty data_point_out.json files.
