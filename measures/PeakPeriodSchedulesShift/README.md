

###### (Automatically generated documentation)

# PeakPeriodSchedulesShift

## Description
Shifts select weekday (or weekday/weekend) schedules out of a peak period.

## Modeler Description
Enter a peak period window, a delay value, and any applicable ScheduleRuleset or ScheduleFile schedules. Shift all schedule values falling within the peak period to after the end (offset by delay) of the peak period. Optionally prevent stacking of schedule values by only allowing shifts to all-zero periods. Optionally apply schedule shifts to weekend days.

## Measure Type
ModelMeasure

## Taxonomy
Whole Building.Whole Building Schedules

___
## Table of Contents
- [Measure Overview](#measure-overview)<br/>
- [Other Examples](#other-examples)<br/>
- [Automatically Generated Argument List](#arguments)<br/>

## Measure Overview

The intent of this measure is to give the user the ability to shift schedules, thereby giving some control over the timing of energy use.
A daily peak period is defined using a start and end hour of the day.
This represents a peak demand window for which customers, e.g., might be penalized for running home appliances.
Schedule values falling within the peak period are then shifted back in time, to start at the end of the peak period.
An optional delay value can be specified to control how many hours after the peak period final hour the load shift should begin.
By default, only schedule values occuring during weekdays can be shifted.
However, an optional argument can be supplied to additionally enable schedule shifts for weekend days.
Users also have the ability to disallow overlapping of shifted schedules onto any existing events.
By default, however, schedules are shifted to periods that already have non-zero schedule values.
In terms of specifying which schedules may be shifted, the user may provide comma-separated lists of schedule names for both ScheduleRuleset and ScheduleFile object types.
Any schedule whose name is not listed is not available to receive any schedule shifts.

The following illustrates a simple shift that has been applied to a refrigerator schedule.
The first 5 weekdays of the year show the appliance load shifted back to start at the end of the peak period.
The peak period does not apply to weekends, and so the final 2 weekend days does not show any shifted schedules.

![Overview](./docs/measures-overview.png?raw=true)

It's important to note that although this measure has been written generically to support any schedules of either the ScheduleRuleset of ScheduleFile type, it has only been tested in the context of residential workflows (i.e, ResStock).
Users applying this measure in other (untested) workflows should use caution.

## Other Examples

Below are additional examples illustrating various scenarios for changing values supplied to measure arguments.

### Shorter peak period

*Peak Period*: 5pm - 7pm |
*Delay*: None |
*Weekdays Only*: Yes

![Shorter Peak Period](./docs/other-examples1.png?raw=true)

### Non-zero delay value

*Peak Period*: 3pm - 7pm |
*Delay*: 1hr |
*Weekdays Only*: Yes

![Nonzero Delay Value](./docs/other-examples2.png?raw=true)

### Applied to weekends

*Peak Period*: 3pm - 7pm |
*Delay*: None |
*Weekdays Only*: No

![Applied To Weekends](./docs/other-examples3.png?raw=true)

___

*(Automatically generated argument information follows)*

## Arguments


### Schedules: Peak Period
Specifies the peak period. Enter a time like "15 - 18" (start hour can be 0 through 23 and end hour can be 1 through 24).
**Name:** schedules_peak_period,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Schedules: Peak Period Delay
The number of hours after peak period end.
**Name:** schedules_peak_period_delay,
**Type:** Integer,
**Units:** hr,
**Required:** true,
**Model Dependent:** false


### Schedules: Peak Period Allow Stacking
Whether schedules can be shifted to periods that already have non-zero schedule values. Defaults to true. Note that the schedule type limits upper value is increased to 2.0 when allowing stacked schedule values.
**Name:** schedules_peak_period_allow_stacking,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Schedules: Peak Period Weekdays Only
Whether schedules can be shifted for weekdays only, or weekends as well. Defaults to true.
**Name:** schedules_peak_period_weekdays_only,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Schedules: Peak Period Schedule Rulesets Names
Comma-separated list of Schedule:Ruleset object names corresponding to schedules to shift during the specified peak period.
**Name:** schedules_peak_period_schedule_rulesets_names,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false


### Schedules: Peak Period Schedule Files Column Names
Comma-separated list of column names, referenced by Schedule:File objects, corresponding to schedules to shift during the specified peak period.
**Name:** schedules_peak_period_schedule_files_column_names,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false






