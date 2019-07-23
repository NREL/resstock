

###### (Automatically generated documentation)

# DrScheduleMakerOS

## Description
Create a DR Event schedule using an OS measure

## Modeler Description
Create a DR Event schedule using an OS measure

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Name of DR Schedule
The name of the Schedule used by DR setpoint measures for EMS code.
**Name:** schedule_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### DR Event Start Time
The hour of the day that the daily DR event begins at; fractional numbers are allowed.
**Name:** event_start_time,
**Type:** Double,
**Units:** hr,
**Required:** true,
**Model Dependent:** false

### DR Event Duration
The duration of the daily DR event in hours.
**Name:** event_duration,
**Type:** Double,
**Units:** hr,
**Required:** true,
**Model Dependent:** false




