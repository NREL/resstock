Heat Pump Upgrades
==================

Types of Backup
---------------

See https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#hpxml-heat-pumps.

Integrated
**********

The heat pump’s distribution system and blower fan power applies to the backup heating (e.g., built-in electric strip heat or an integrated backup furnace, i.e., a dual-fuel heat pump).

Separate
********

The backup system has its own distribution system (e.g., electric baseboard or a boiler).

Lockout Temperatures
--------------------

See https://openstudio-hpxml.readthedocs.io/en/latest/workflow_inputs.html#backup.

Compressor
**********

``heat_pump_compressor_lockout_temp=5``

Backup Heating
**************

``heat_pump_backup_heating_lockout_temp=40``

Replacement Scenarios
---------------------

Replace Primary System with New Heat Pump
*****************************************

.. code-block:: yaml

  - upgrade_name: ASHP
    options:
      - option: HVAC Heating Efficiency|ASHP, SEER 22, 10 HSPF
        apply_logic:
          - HVAC Has Ducts|Yes
        costs:
          - value: 50.0
            multiplier: Size, Heating System Primary (kBtu/h)
        lifetime: 30
      - option: HVAC Cooling Efficiency|Ducted Heat Pump

Primary System becomes Backup to New Heat Pump
**********************************************

Use the ``Heat Pump Backup|Use Existing System`` option from the lookup.
Here is generally what happens / gets retained:

- fuel type
- efficiency
- capacity

.. code-block:: yaml

  - upgrade_name: ASHP
    options:
      - option: HVAC Heating Efficiency|ASHP, SEER 22, 10 HSPF
        apply_logic:
          - HVAC Has Ducts|Yes
        costs:
          - value: 50.0
            multiplier: Size, Heating System Primary (kBtu/h)
        lifetime: 30
      - option: HVAC Cooling Efficiency|Ducted Heat Pump
      - option: Heat Pump Backup|Use Existing System

The type of the backup is determined based on the table below:

  ============= ============= =========== =============================
  New Heat Pump Backup System Backup Type Example
  ============= ============= =========== =============================
  ducted        ducted        integrated  ASHP w/Furnace [#]_
  ducted        ductless      separate    ASHP w/Boiler
  ductless      ducted        separate    Ductless MSHP w/Furnace
  ductless      ductless      separate    Ductless MSHP w/Boiler
  ============= ============= =========== =============================

 .. [#] When furnace is fuel-fired (i.e., non-electric).
        When furnace is electric, it likely wouldn't be used as integrated backup.

Other situations:

- Primary system does not become backup to the heat pump:

  - Primary system is a heat pump
  - Primary system is a shared system

- Secondary system exists:

  - Remains secondary if heat pump upgrade is integrated backup
  - Removed if heat pump upgrade is separate backup?