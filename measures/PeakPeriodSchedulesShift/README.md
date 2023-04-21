

###### (Automatically generated documentation)

# PeakPeriodSchedulesShift

## Description
Shifts select schedules out of a peak period.

## Modeler Description
Enter a weekday peak period, a delay value, and any applicable ScheduleRuleset or ScheduleFile schedules. Shift all schedule values falling within the peak period to after the end (offset by delay) of the peak period. Prevent stacking of schedule values by only allowing shifts to all-zero periods.

## Measure Type
ModelMeasure

## Taxonomy


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
Whether schedules can be shifted to periods that already have non-zero schedule values. Defaults to true. Note that stacking runs the risk of creating out-of-range schedule values.
**Name:** schedules_peak_period_allow_stacking,
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






