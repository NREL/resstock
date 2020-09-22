Introduction
============

The OpenStudio-HPXML repository consists of residential `OpenStudio measures <http://nrel.github.io/OpenStudio-user-documentation/getting_started/about_measures/>`_ that handle `HPXML files <https://hpxml.nrel.gov>`_.

Measures
--------

This repository contains three OpenStudio measures:

#. ``BuildResidentialHPXML``: A measure that translates a set of building unit argument values to an HPXML file.
#. ``HPXMLtoOpenStudio``: A measure that translates an HPXML file to an OpenStudio model.
#. ``SimulationOutputReport``: A reporting measure that generates a variety of annual/timeseries outputs for a residential HPXML-based model.

Modeling Capabilities
---------------------
The OpenStudio-HPXML workflow can accommodate the following building features/technologies:

- Enclosure

  - Attics
  
    - Vented
    - Unvented
    - Conditioned
    - Radiant Barriers
    
  - Foundations
  
    - Slab
    - Unconditioned Basement
    - Conditioned Basement
    - Vented Crawlspace
    - Unvented Crawlspace
    - Ambient
    
  - Garages
  - Windows & Overhangs
  - Skylights
  - Doors
  
- HVAC

  - Heating Systems
  
    - Electric Resistance
    - Central/Wall/Floor Furnaces
    - Stoves, Portable/Fixed Heaters
    - Boilers
    - Fireplaces
    
  - Cooling Systems
  
    - Central/Room Air Conditioners
    - Evaporative Coolers
    - Mini Split Air Conditioners
    - Chillers
    - Cooling Towers
    
  - Heat Pumps
  
    - Air Source Heat Pumps
    - Mini Split Heat Pumps
    - Ground Source Heat Pumps
    - Dual-Fuel Heat Pumps
    - Water Loop Heat Pumps
    
  - Thermostat Setpoints
  - Ducts
  
- Water Heating

  - Water Heaters
  
    - Storage Tank
    - Instantaneous Tankless
    - Heat Pump Water Heater
    - Indirect Water Heater (Combination Boiler)
    - Tankless Coil (Combination Boiler)

  - Solar Hot Water
  - Desuperheaters
  - Hot Water Distribution
  
    - Recirculation
    
  - Drain Water Heat Recovery
  - Hot Water Fixtures
  
- Mechanical Ventilation

  - Exhaust Only
  - Supply Only
  - Balanced
  - Energy Recovery Ventilator
  - Heat Recovery Ventilator
  - Central Fan Integrated Supply
  - Shared Systems w/ Recirculation and/or Preconditioning

- Kitchen/Bath Fans
- Whole House Fan
- Photovoltaics
- Appliances

  - Clothes Washer
  - Clothes Dryer
  - Dishwasher
  - Refrigerator
  - Cooking Range/Oven

- Dehumidifiers
- Lighting
- Ceiling Fans
- Pool/Hot Tub
- Plug/Fuel Loads

Scope (Dwelling Units)
----------------------

The OpenStudio-HPXML workflow is intended to be used to model individual residential dwelling units -- either a single-family detached (SFD) building, or a single unit of a single-family attached (SFA) or multifamily (MF) building.
This approach was taken because:

- It is required/desired for certain projects.
- It improves runtime speed by being able to simulate individual units in parallel (as opposed to simulating the entire building).
- It doesn't necessarily preclude the possibility of running a single integrated EnergyPlus simulation.

To model units of SFA/MF buildings, current capabilities include:

- Defining surfaces adjacent to generic SFA/MF spaces (e.g., "other housing unit" or "other multifamily buffer space").
- Locating various building components (e.g., ducts, water heaters, appliances) in these SFA/MF spaces.
- Defining shared systems (HVAC, water heating, mechanical ventilation, etc.) by approximating the energy use attributed to the unit.

Note that only the energy use attributed to each dwelling unit is calculated.
Other OpenStudio capabilities should be used to supplement this workflow if the energy use of non-residential dwelling spaces (e.g., gyms, elevators, corridors, etc.) are of interest.

For situations where more complex, integrated modeling is required, it is possible to merge multiple OpenStudio models together into a single model, such that one could merge all residential OSMs together and potentially combine it with a commercial OSM.
That capability is outside the scope of this project.

Accuracy vs Speed
-----------------

The EnergyPlus simulation engine is like a Swiss army knife.
There are often multiple models available for the same building technology with varying trade-offs between accuracy and speed.
This workflow standardizes the use of EnergyPlus (e.g., the choice of models appropriate for residential buildings) to provide a fast and easy to use solution.

The workflow is continuously being evaluated for ways to reduce runtime without significant impact on accuracy.
End-to-end simulations typically run in 3-10 seconds, depending on complexity, computer platform and speed, etc.

There are additional ways that software developers using this workflow can reduce runtime:

- Run on Linux/Mac platform, which is significantly faster by taking advantage of the POSIX fork call.
- Do not use the ``--hourly`` flag unless hourly output is required. If required, limit requests to hourly variables of interest.
- Run on computing environments with 1) fast CPUs, 2) sufficient memory, and 3) enough processors to allow all simulations to run in parallel.

License
-------

This project is available under a BSD-3-like license, which is a free, open-source, and permissive license. For more information, check out the `license file <https://github.com/NREL/OpenStudio-HPXML/blob/master/LICENSE.md>`_.
