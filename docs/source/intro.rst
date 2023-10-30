Introduction
============

The OpenStudio-HPXML repository consists of a simple residential EnergyPlus-based workflow build on top of `OpenStudio measures <http://nrel.github.io/OpenStudio-user-documentation/getting_started/about_measures/>`_.
The workflow operates using `HPXML building description files <https://hpxml.nrel.gov>`_.

The OpenStudio measures used by the workflow are:

#. ``BuildResidentialHPXML``: A measure that generates an HPXML file from a set of building description inputs (including, e.g., simplified geometry inputs).
#. ``BuildResidentialScheduleFile``: A measure that generates a CSV of detailed schedules (e.g., stochastic occupancy) for use in the simulation.
#. ``HPXMLtoOpenStudio``: A measure that translates an HPXML file to an OpenStudio model.
#. ``ReportSimulationOutput``: A reporting measure that generates a variety of simulation-based annual/timeseries outputs in CSV/JSON/MessagePack format.
#. ``ReportUtilityBills``: A reporting measure that generates utility bill outputs in CSV/JSON/MessagePack format.


Building Type Scope
-------------------

Dwelling Units
~~~~~~~~~~~~~~

The OpenStudio-HPXML workflow was originally developed to model individual residential dwelling units -- either a single-family detached (SFD) building, or a single unit of a single-family attached (SFA) or multifamily (MF) building.
This approach:

- Is required/desired for certain applications (e.g., a Home Energy Score or an Energy Rating Index calculation).
- Improves runtime speed by being able to simulate individual units in parallel (as opposed to simulating the entire building).

When modeling individual units of SFA/MF buildings, current capabilities include:

- Defining surfaces adjacent to generic SFA/MF spaces (e.g., "other housing unit" or "other multifamily buffer space"), in which temperature profiles are assumed.
- Locating various building components (e.g., ducts, water heaters, appliances) in these SFA/MF spaces.
- Defining shared systems (HVAC, water heating, mechanical ventilation, etc.) by approximating their energy use attributed to the unit.

Note that only the energy use attributed to each dwelling unit is calculated.
Other OpenStudio capabilities should be used to supplement this workflow if the energy use of non-residential dwelling spaces (e.g., gyms, elevators, corridors, etc.) are of interest.

Whole Buildings
~~~~~~~~~~~~~~~

As of OpenStudio-HPXML v1.7.0, a new capability was added for modeling whole SFA/MF buildings.
For these simulations:

- The HPXML file must include multiple ``Building`` elements, each of which describes an individual dwelling unit.
- FIXME: Say something about unconditioned common spaces, basements, attics.
- Unit multipliers (using the ``NumberofUnits`` element) can be specified to model *unique* dwelling units, rather than *all* dwelling units, reducing simulation runtime.

Some notes/caveats about this approach:

- Some inputs (e.g., EPW location or ground conductivity) cannot vary across ``Building`` elements.
- Some building features are not currently supported:

  - Batteries
  - Dehumidifiers (not supported only if the unit multiplier > 1)
  - Ground source heat pumps (not supported only if the unit multiplier > 1)

- FIXME: Say something about shared systems.

Accuracy vs Speed
-----------------

The EnergyPlus simulation engine is like a Swiss army knife.
There are often multiple models available for the same building technology with varying trade-offs between accuracy and speed.
This workflow standardizes the use of EnergyPlus (e.g., the choice of models appropriate for residential buildings) to provide a fast and easy to use solution.

The workflow is continuously being evaluated for ways to reduce runtime without significant impact on accuracy.
End-to-end simulations typically run in 3-10 seconds, depending on complexity, computer platform and speed, etc.

There are additional ways that software developers using this workflow can reduce runtime:

- Run on Linux/Mac platform, which is significantly faster than Windows.
- Run on computing environments with 1) fast CPUs, 2) sufficient memory, and 3) enough processors to allow all simulations to run in parallel.
- Limit requests for timeseries output (e.g., ``--hourly``, ``--daily``, ``--timestep`` arguments) and limit the number of output variables requested.
- Avoid using the ``--add-component-loads`` argument if heating/cooling component loads are not of interest.
- Use the ``--skip-validation`` argument if the HPXML input file has already been validated against the Schema & Schematron documents.

License
-------

This project is available under a BSD-3-like license, which is a free, open-source, and permissive license. For more information, check out the `license file <https://github.com/NREL/OpenStudio-HPXML/blob/master/LICENSE.md>`_.
