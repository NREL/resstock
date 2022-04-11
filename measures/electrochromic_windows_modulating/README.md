

###### (Automatically generated documentation)

# Electrochromic Windows Modulating

## Description
Adds electrochromic windows. SHGC and VLT will modulate linearly between specified clear and tinted properties.

## Modeler Description
Adds electrochromic windows. SHGC and VLT will modulate linearly between specified clear and tinted properties.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### SHGC Clear
Sets SHGC for clear state. Value of 0 will use current glazing property.
**Name:** shgc_clear,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### VT Clear
Sets VT for clear state. Value of 0 will use current glazing property.
**Name:** vt_clear,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### SHGC Tinted
Sets SHGC for tinted state.
**Name:** shgc_tinted,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### VT Tinted
Sets VT for tinted state.
**Name:** vt_tinted,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### U-value (Btu/h·ft2·°F)
Replaces u-value of existing applicable windows with this value. Use IP units.
**Name:** u_value,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Maximum Allowable Radiation (W/m^2)
Windows will switch to a darker state if threshold is exceeded.
**Name:** max_rad_w_per_m2,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Maximum Allowable Glare Index
Sets maximum glare index allowance for EC windows.
**Name:** gi,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Minimum Temperature for EC Tinting
Sets minimum temperature to allow for EC tinting. A low value will mitigate heating penalties.
**Name:** min_temp,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Prioritize Glare Over Temperature?

**Name:** ec_priority_logic,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Apply electrochromic glazing to North facade windows.

**Name:** North,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Apply electrochromic glazing to East facade windows.

**Name:** East,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Apply electrochromic glazing to South facade windows.

**Name:** South,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Apply electrochromic glazing to West facade windows.

**Name:** West,
**Type:** Boolean,
**Units:** ,
**Required:** false,
**Model Dependent:** false




