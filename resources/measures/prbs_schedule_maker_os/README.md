

###### (Automatically generated documentation)

# PrbsScheduleMakerOS

## Description
OS version of measure that makes a PRBS DR event schedule

## Modeler Description
OS version of measure that makes a PRBS DR event schedule

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

### Minimum Value for PRBS Signal
The minimum value to use. Typically -1 or 0.
**Name:** minimum_value,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Maximum Value for PRBS Signal
The maximum value to use. Typically 0 or 1.
**Name:** maximum_value,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Timestep (min)
By default, the measure pulls the simulation timestep from the OpenStudio model. This argument provides the option to override that value.
**Name:** timestep,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Minimum Hold Duration of DR State (min)
Specifies the minimum hold duration of the DR state.  Cannot be shorter than ((1 / Nyquist frequency) = 2 * timestep); otherwise, input will be overridden.
**Name:** minimum_hold_duration,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Maximum Hold Duration of DR State (min)
Specifies the maximum hold duration of the DR state.  Cannot be longer than 3 hrs (180 min); otherwise, input will be overridden.
**Name:** maximum_hold_duration,
**Type:** Double,
**Units:** ,
**Required:** false,
**Model Dependent:** false




