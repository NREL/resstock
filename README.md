# OpenStudio-HPXML

[![CircleCI](https://circleci.com/gh/NREL/OpenStudio-HPXML.svg?style=shield)](https://circleci.com/gh/NREL/OpenStudio-HPXML)
[![Documentation Status](https://readthedocs.org/projects/openstudio-hpxml/badge/?version=latest)](https://openstudio-hpxml.readthedocs.io/en/latest/?badge=latest)
[![codecov](https://codecov.io/gh/NREL/OpenStudio-HPXML/branch/master/graph/badge.svg)](https://codecov.io/gh/NREL/OpenStudio-HPXML)


This repository contains residential [OpenStudio measures](http://nrel.github.io/OpenStudio-user-documentation/getting_started/about_measures/) that handle [HPXML files](https://hpxml.nrel.gov/).

For more information, please visit the [documentation](https://openstudio-hpxml.readthedocs.io/en/latest).

## Measures

This repository contains three OpenStudio measures:
- `BuildResidentialHPXML`: A measure that translates a set of building unit argument values to an HPXML file.
- `HPXMLtoOpenStudio`: A measure that translates an HPXML file to an OpenStudio model.
- `SimulationOutputReport`: A reporting measure that generates a variety of annual/timeseries outputs for a residential HPXML-based model.

## Projects

These core OpenStudio measures are used by a number of other residential projects, including:
- [Energy Rating Index (ERI)](https://github.com/NREL/OpenStudio-ERI)
- Home Energy Score (private repository)
- Weatherization Assistant (private repository)
- ResStock (pending)

## License

This project is available under a BSD-3-like license, which is a free, open-source, and permissive license. For more information, check out the [license file](https://github.com/NREL/OpenStudio-HPXML/blob/master/LICENSE.md).
