

###### (Automatically generated documentation)

# AddThermalComfortModelTypes

## Description
Adds to the model (A) any of the available thermal comfort model types, and (B) work efficiency, clothing insulation, and air velocity constant schedules.

## Modeler Description
Specify any of the thermal comfort model types to add to People:Definition objects in the model. Specify constant values corresponding to the work efficiency, clothing insulation, and air velocity schedules.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Thermal Comfort Model Type: Fanger
Whether to add the Fanger thermal comfort model type.
**Name:** thermal_comfort_model_type_fanger,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Thermal Comfort Model Type: Pierce
Whether to add the Pierce thermal comfort model type.
**Name:** thermal_comfort_model_type_pierce,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Thermal Comfort Model Type: KSU
Whether to add the KSU thermal comfort model type.
**Name:** thermal_comfort_model_type_ksu,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Thermal Comfort Model Type: AdaptiveASH55
Whether to add the AdaptiveASH55 thermal comfort model type.
**Name:** thermal_comfort_model_type_adaptiveash55,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Thermal Comfort Model Type: AdaptiveCEN15251
Whether to add the AdaptiveCEN15251 thermal comfort model type.
**Name:** thermal_comfort_model_type_adaptivecen15251,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Thermal Comfort Model Type: CoolingEffectASH55
Whether to add the CoolingEffectASH55 thermal comfort model type.
**Name:** thermal_comfort_model_type_coolingeffectash55,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Thermal Comfort Model Type: AnkleDraftASH55
Whether to add the AnkleDraftASH55 thermal comfort model type.
**Name:** thermal_comfort_model_type_ankledraftash55,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Work Efficiency Schedule Value
Specify the constant work efficiency schedule value.
**Name:** work_efficiency_schedule_value,
**Type:** Double,
**Units:** Frac,
**Required:** true,
**Model Dependent:** false


### Clothing Insulation Schedule Value
Specify the constant clothing insulation schedule value.
**Name:** clothing_insulation_schedule_value,
**Type:** Double,
**Units:** Frac,
**Required:** true,
**Model Dependent:** false


### Air Velocity Schedule Value
Specify the constant air velocity schedule value.
**Name:** air_velocity_schedule_value,
**Type:** Double,
**Units:** Frac,
**Required:** true,
**Model Dependent:** false






