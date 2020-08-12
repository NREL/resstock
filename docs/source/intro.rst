Introduction
============

The OpenStudio-HPXML repository consists of residential `OpenStudio measures <http://nrel.github.io/OpenStudio-user-documentation/getting_started/about_measures/>`_ that handle `HPXML files <https://hpxml.nrel.gov>`_.

Measures
--------

This repository contains three OpenStudio measures:

#. ``BuildResidentialHPXML``: A measure that translates a set of building unit argument values to an HPXML file.
#. ``HPXMLtoOpenStudio``: A measure that translates an HPXML file to an OpenStudio model.
#. ``SimulationOutputReport``: A reporting measure that generates a variety of annual/timeseries outputs for a residential HPXML-based model.

Scope (Dwelling Units)
**********************

The OpenStudio-HPXML workflow is intended to be used to model individual residential dwelling units -- either a single-family detached (SFD) building, or a single unit of a single-family attached (SFA) or multifamily (MF) building.
This approach was taken because:

- It is required/desired for certain projects.
- It improves runtime speed by being able to simulate individual units in parallel (as opposed to simulating the entire building).
- It doesn't necessarily preclude the possibility of running a single integrated EnergyPlus simulation.

To model units of SFA/MF buildings, current capabilities include:

- Defining surfaces adjacent to generic SFA/MF space types (e.g., "other housing unit" or "other multifamily buffer space").
- Locating various building components (e.g., ducts, water heaters, appliances) in these spaces.

Note that only the energy use attributed to each dwelling unit is calculated.
Other OpenStudio capabilities should be used to supplement this workflow if the energy use of non-residential dwelling spaces (e.g., gyms, elevators, corridors, etc.) are of interest.
In the near future, the OpenStudio-HPXML workflow will also begin supporting shared systems (HVAC, water heating, mechanical ventilation, etc.) by approximating the energy use attributed to the unit.

For situations where more complex, integrated modeling is required, it is possible to merge multiple OpenStudio models together into a single model, such that one could merge all residential OSMs together and potentially combine it with a commercial OSM.
That capability is outside the scope of this project.

License
-------

This project is available under a BSD-3-like license, which is a free, open-source, and permissive license. For more information, check out the `license file <https://github.com/NREL/OpenStudio-HPXML/blob/master/LICENSE.md>`_.
