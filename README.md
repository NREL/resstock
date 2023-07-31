# OpenStudio-HPXML

[![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/NREL/OpenStudio-HPXML?include_prereleases)](https://github.com/NREL/OpenStudio-HPXML/releases)
[![ci](https://github.com/NREL/OpenStudio-HPXML/workflows/ci/badge.svg)](https://github.com/NREL/OpenStudio-HPXML/actions)
[![Documentation Status](https://readthedocs.org/projects/openstudio-hpxml/badge/?version=latest)](https://openstudio-hpxml.readthedocs.io/en/latest/?badge=latest)

OpenStudio-HPXML allows running residential EnergyPlus simulations using an [HPXML file](https://hpxml.nrel.gov/) for the building description.
It is intended to be used by user interfaces or other automated software workflows that automatically produce the HPXML file. A [Schematron](http://schematron.com/) document for the EnergyPlus use case is used to validate that the appropriate HPXML inputs are provided to run EnergyPlus.

OpenStudio-HPXML can accommodate a wide range of different building technologies and geometries.
End-to-end simulations typically run in 3-10 seconds, depending on complexity, computer platform and speed, etc.

For more information on running simulations, generating HPXML files, etc., please visit the [documentation](https://openstudio-hpxml.readthedocs.io/en/latest).

## Workflows

A simple `run_simulation.rb` script is provided to run a residential EnergyPlus simulation from an HPXML file.
See the [Usage Instructions](https://openstudio-hpxml.readthedocs.io/en/latest/usage_instructions.html) for documentation on running the workflow.

Since [OpenStudio measures](http://nrel.github.io/OpenStudio-user-documentation/getting_started/about_measures/) are used for model generation, additional OpenStudio-based workflows and interfaces can instead be used if desired.

## Measures

This repository contains several OpenStudio measures:
- `BuildResidentialHPXML`: A measure that generates an HPXML file from a set of building description inputs (including, e.g., simplified geometry inputs).
- `BuildResidentialScheduleFile`: A measure that generates a CSV of detailed schedules (e.g., stochastic occupancy) for use in the simulation.
- `HPXMLtoOpenStudio`: A measure that translates an HPXML file to an OpenStudio model.
- `ReportSimulationOutput`: A reporting measure that generates a variety of simulation-based annual/timeseries outputs in CSV/JSON/MessagePack format.
- `ReportUtilityBills`: A reporting measure that generates utility bill outputs in CSV/JSON/MessagePack format.

## Projects

The OpenStudio-HPXML workflow is used by a number of other residential projects, including:
- [BEopt](https://beopt.nrel.gov)
- [Energy Rating Index (ERI)](https://github.com/NREL/OpenStudio-ERI)
- [Home Energy Score](https://betterbuildingssolutioncenter.energy.gov/home-energy-score)
- [ResStock](https://resstock.nrel.gov/)
- [URBANopt](https://www.nrel.gov/buildings/urbanopt.html)
- [Weatherization Assistant](https://weatherization.ornl.gov/softwaredescription/) (pending)

It is also used by several private-sector software tools.

## License

This project is available under a BSD-3-like license, which is a free, open-source, and permissive license. For more information, check out the [license file](https://github.com/NREL/OpenStudio-HPXML/blob/master/LICENSE.md).
