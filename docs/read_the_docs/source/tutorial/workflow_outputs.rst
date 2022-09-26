Workflow Outputs
================

ResStock generates both a standard set of outputs as well as other outputs.
The standard set of outputs include annual energy consumption (e.g., by end use and fuel type), emissions, utility bills, etc., as well as optionally requested timeseries outputs.
Other outputs include building characteristics, upgrade cost multipliers, and quantities of interest.

Standard Outputs
----------------

See the `OpenStudio-HPXML Workflow Outputs <https://openstudio-hpxml.readthedocs.io/en/latest/workflow_outputs.html>`_ for documentation on workflow outputs.

Other Outputs
-------------

Additionally you can find other outputs, including building IDs and characteristics, weights, upgrade cost multipliers, and quantities of interest.

Building ID
***********

This is the unique identifier assigned to the ResStock sample.
Upgrades correspond to baseline models based on the building ID.

Characteristics
***************

These are sampled options for each parameter.

Weights
*******

.. _upgrade-costs-columns:

Upgrade Costs
*************

Note about finding them in snakecase?

   - Fixed (1)
   - Wall Area, Above-Grade, Conditioned (ft^2)
   - Wall Area, Above-Grade, Exterior (ft^2)
   - Wall Area, Below-Grade (ft^2)
   - Floor Area, Conditioned (ft^2)
   - Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)
   - Floor Area, Lighting (ft^2)
   - Floor Area, Foundation (ft^2)
   - Floor Area, Attic (ft^2)
   - Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)
   - Roof Area (ft^2)
   - Window Area (ft^2)
   - Door Area (ft^2)
   - Duct Unconditioned Surface Area (ft^2)
   - Rim Joist Area, Above-Grade, Exterior (ft^2)
   - Slab Perimeter, Exposed, Conditioned (ft)
   - Size, Heating System Primary (kBtu/h)
   - Size, Heating System Secondary (kBtu/h)
   - Size, Cooling System Primary (kBtu/h)
   - Size, Heat Pump Backup Primary (kBtu/h)
   - Size, Water Heater (gal)
   - Flow Rate, Mechanical Ventilation (cfm)

QOIs
****

?
*