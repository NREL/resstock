
###### (Automatically generated documentation)

# HPXML to OpenStudio Translator

## Description
Translates HPXML file to OpenStudio Model



## Arguments


**HPXML File Path**

Absolute/relative path of the HPXML file.

- **Name:** ``hpxml_path``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Directory for Output Files**

Absolute/relative path for the output files directory.

- **Name:** ``output_dir``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Debug Mode?**

If true: 1) Writes in.osm file, 2) Generates additional log output, and 3) Creates all EnergyPlus output files.

- **Name:** ``debug``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Add component loads?**

If true, adds the calculation of heating/cooling component loads (not enabled by default for faster performance).

- **Name:** ``add_component_loads``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Skip Validation?**

If true, bypasses HPXML input validation for faster performance. WARNING: This should only be used if the supplied HPXML file has already been validated against the Schema & Schematron documents.

- **Name:** ``skip_validation``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**BuildingID**

The ID of the HPXML Building. Only required if the HPXML has multiple Building elements and WholeSFAorMFBuildingSimulation is not true.

- **Name:** ``building_id``
- **Type:** ``String``

- **Required:** ``false``

<br/>





