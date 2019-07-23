

###### (Automatically generated documentation)

# DrSetpointModificationOS

## Description
Modify the cooling setpoint of the HVAC system during a DR event

## Modeler Description
Modify the cooling setpoint of the HVAC system during a DR event

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### DR Event Schedule Name
Name of the schedule to use for setting the EMS code.
**Name:** dr_event_schedule,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Event Delta T
Amount to raise cooling setpoint by during DR Event.  Use negative number to decrease cooling setpoint during event.
**Name:** event_delta_t,
**Type:** Double,
**Units:** degC,
**Required:** true,
**Model Dependent:** false

### Cooling Setpoint Schedule Name
Name of the cooling setpoint schedule to modify.
**Name:** cooling_setpoint_schedule,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Heating Setpoint Schedule Name
Name of the heating setpoint schedule. Will not be changed, but needed for EMS script.
**Name:** heating_setpoint_schedule,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false




