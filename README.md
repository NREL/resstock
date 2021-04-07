<img src="https://user-images.githubusercontent.com/1276021/85608250-1ff46b80-b612-11ea-903e-4ced367e5940.jpg" width="280">

The `develop` branch is under active development. Find the latest release [here](https://github.com/NREL/resstock/releases).

[![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/NREL/resstock?include_prereleases)](https://github.com/NREL/resstock/releases)
[![ci](https://github.com/NREL/resstock/workflows/ci/badge.svg)](https://github.com/NREL/resstock/actions)
[![Documentation Status](https://readthedocs.org/projects/resstock/badge/?version=latest)](https://resstock.readthedocs.io/en/latest/?badge=latest)

[ResStock™](https://www.nrel.gov/buildings/resstock.html), built on the [OpenStudio platform](http://openstudio.net), is a project geared at modeling existing residential building stocks at national, regional, or local scales with a high-degree of granularity (e.g., one physics-based simulation model for every 200 dwelling units), using the [EnergyPlus simulation engine](http://energyplus.net). Information about ComStock™, a sister tool for modeling the commercial building stock, can be found [here](https://www.nrel.gov/buildings/comstock.html). 

This repository contains:

- [Housing characteristics of the U.S. residential building stock](https://github.com/NREL/resstock/tree/master/project_national/housing_characteristics), in the form of conditional probability distributions stored as tab-separated value (.tsv) files. A visualization of the dependency structure can be found [here](https://htmlpreview.github.io/?https://github.com/NREL/resstock/blob/master/project_national/util/dependency_wheel/dep_wheel.html).
- [A library of housing characteristic "options"](https://github.com/NREL/resstock/blob/master/resources/options_lookup.tsv) that translate high-level characteristic parameters into arguments for [OpenStudio Measures](https://github.com/NREL/resstock/tree/master/resources/measures), and which are referenced by the housing characteristic .tsv files and building energy upgrades defined in project definition files
- Project definition files:
  - v2.3.0 and later: [buildstockbatch YML files openable in any text editor](https://github.com/NREL/resstock/blob/master/project_national/national.yml)
  - v2.2.5 and prior: [Project folder openable in PAT](https://github.com/NREL/resstock/tree/v2.2.5/project_singlefamilydetached)
- [Building-level OpenStudio Measures](https://github.com/NREL/resstock/tree/master/resources/measures) for automatically constructing OpenStudio Models of each representative building model
- [Higher-level OpenStudio Measures](https://github.com/NREL/resstock/tree/master/measures) for controlling simulation inputs and outputs

This repository does not contain software for running ResStock simulations, which can be found as follows:

 - [Versions 2.3.0](https://github.com/NREL/resstock/releases/tag/untagged-af060c990f21d5ca539f) and later only support the use of [buildstockbatch](https://github.com/NREL/buildstockbatch) for deploying simulations on high-performance or cloud computing. Version 2.3.0 also removed separate projects for single-family detached and multifamily buildings, in lieu of a combined `project_national` representing the U.S. residential building stock. See the [changelog](https://github.com/NREL/resstock/blob/master/CHANGELOG.md) for more details. 
 - [Versions 2.2.5](https://github.com/NREL/resstock/releases/tag/v2.2.5) and prior support the use of the publicly available [OpenStudio-PAT](https://github.com/NREL/OpenStudio-PAT) software as an interface for deploying simulations on cloud computing. Read the [documentation for v2.2.5](https://resstock.readthedocs.io/en/v2.2.5/).

Note that calibration/validation of the multifamily sector, as well as timeseries output, is still ongoing, under the [End-Use Load Profile for the U.S. Building Stock project](https://www.nrel.gov/buildings/end-use-load-profiles.html).
