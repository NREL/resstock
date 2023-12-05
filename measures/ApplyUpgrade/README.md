
###### (Automatically generated documentation)

# Apply Upgrade

## Description
Measure that applies an upgrade (one or more child measures) to a building model based on the specified logic.

Determines if the upgrade should apply to a given building model. If so, calls one or more child measures with the appropriate arguments.

## Arguments


**Upgrade Name**

User-specificed name that describes the upgrade.

- **Name:** ``upgrade_name``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Option 1**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_1``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Option 1 Apply Logic**

Logic that specifies if the Option 1 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_1_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 1 Cost 1 Value**

Total option 1 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_1_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 1 Cost 1 Multiplier**

Total option 1 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_1_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 1 Cost 2 Value**

Total option 1 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_1_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 1 Cost 2 Multiplier**

Total option 1 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_1_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 1 Lifetime**

The option lifetime.

- **Name:** ``option_1_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 2**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_2``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 2 Apply Logic**

Logic that specifies if the Option 2 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_2_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 2 Cost 1 Value**

Total option 2 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_2_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 2 Cost 1 Multiplier**

Total option 2 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_2_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 2 Cost 2 Value**

Total option 2 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_2_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 2 Cost 2 Multiplier**

Total option 2 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_2_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 2 Lifetime**

The option lifetime.

- **Name:** ``option_2_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 3**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_3``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 3 Apply Logic**

Logic that specifies if the Option 3 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_3_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 3 Cost 1 Value**

Total option 3 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_3_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 3 Cost 1 Multiplier**

Total option 3 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_3_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 3 Cost 2 Value**

Total option 3 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_3_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 3 Cost 2 Multiplier**

Total option 3 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_3_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 3 Lifetime**

The option lifetime.

- **Name:** ``option_3_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 4**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_4``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 4 Apply Logic**

Logic that specifies if the Option 4 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_4_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 4 Cost 1 Value**

Total option 4 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_4_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 4 Cost 1 Multiplier**

Total option 4 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_4_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 4 Cost 2 Value**

Total option 4 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_4_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 4 Cost 2 Multiplier**

Total option 4 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_4_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 4 Lifetime**

The option lifetime.

- **Name:** ``option_4_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 5**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_5``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 5 Apply Logic**

Logic that specifies if the Option 5 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_5_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 5 Cost 1 Value**

Total option 5 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_5_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 5 Cost 1 Multiplier**

Total option 5 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_5_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 5 Cost 2 Value**

Total option 5 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_5_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 5 Cost 2 Multiplier**

Total option 5 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_5_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 5 Lifetime**

The option lifetime.

- **Name:** ``option_5_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 6**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_6``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 6 Apply Logic**

Logic that specifies if the Option 6 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_6_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 6 Cost 1 Value**

Total option 6 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_6_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 6 Cost 1 Multiplier**

Total option 6 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_6_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 6 Cost 2 Value**

Total option 6 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_6_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 6 Cost 2 Multiplier**

Total option 6 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_6_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 6 Lifetime**

The option lifetime.

- **Name:** ``option_6_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 7**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_7``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 7 Apply Logic**

Logic that specifies if the Option 7 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_7_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 7 Cost 1 Value**

Total option 7 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_7_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 7 Cost 1 Multiplier**

Total option 7 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_7_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 7 Cost 2 Value**

Total option 7 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_7_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 7 Cost 2 Multiplier**

Total option 7 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_7_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 7 Lifetime**

The option lifetime.

- **Name:** ``option_7_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 8**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_8``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 8 Apply Logic**

Logic that specifies if the Option 8 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_8_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 8 Cost 1 Value**

Total option 8 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_8_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 8 Cost 1 Multiplier**

Total option 8 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_8_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 8 Cost 2 Value**

Total option 8 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_8_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 8 Cost 2 Multiplier**

Total option 8 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_8_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 8 Lifetime**

The option lifetime.

- **Name:** ``option_8_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 9**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_9``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 9 Apply Logic**

Logic that specifies if the Option 9 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_9_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 9 Cost 1 Value**

Total option 9 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_9_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 9 Cost 1 Multiplier**

Total option 9 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_9_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 9 Cost 2 Value**

Total option 9 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_9_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 9 Cost 2 Multiplier**

Total option 9 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_9_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 9 Lifetime**

The option lifetime.

- **Name:** ``option_9_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 10**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_10``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 10 Apply Logic**

Logic that specifies if the Option 10 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_10_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 10 Cost 1 Value**

Total option 10 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_10_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 10 Cost 1 Multiplier**

Total option 10 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_10_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 10 Cost 2 Value**

Total option 10 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_10_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 10 Cost 2 Multiplier**

Total option 10 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_10_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 10 Lifetime**

The option lifetime.

- **Name:** ``option_10_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 11**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_11``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 11 Apply Logic**

Logic that specifies if the Option 11 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_11_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 11 Cost 1 Value**

Total option 11 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_11_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 11 Cost 1 Multiplier**

Total option 11 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_11_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 11 Cost 2 Value**

Total option 11 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_11_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 11 Cost 2 Multiplier**

Total option 11 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_11_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 11 Lifetime**

The option lifetime.

- **Name:** ``option_11_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 12**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_12``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 12 Apply Logic**

Logic that specifies if the Option 12 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_12_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 12 Cost 1 Value**

Total option 12 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_12_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 12 Cost 1 Multiplier**

Total option 12 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_12_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 12 Cost 2 Value**

Total option 12 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_12_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 12 Cost 2 Multiplier**

Total option 12 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_12_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 12 Lifetime**

The option lifetime.

- **Name:** ``option_12_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 13**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_13``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 13 Apply Logic**

Logic that specifies if the Option 13 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_13_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 13 Cost 1 Value**

Total option 13 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_13_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 13 Cost 1 Multiplier**

Total option 13 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_13_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 13 Cost 2 Value**

Total option 13 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_13_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 13 Cost 2 Multiplier**

Total option 13 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_13_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 13 Lifetime**

The option lifetime.

- **Name:** ``option_13_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 14**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_14``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 14 Apply Logic**

Logic that specifies if the Option 14 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_14_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 14 Cost 1 Value**

Total option 14 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_14_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 14 Cost 1 Multiplier**

Total option 14 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_14_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 14 Cost 2 Value**

Total option 14 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_14_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 14 Cost 2 Multiplier**

Total option 14 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_14_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 14 Lifetime**

The option lifetime.

- **Name:** ``option_14_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 15**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_15``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 15 Apply Logic**

Logic that specifies if the Option 15 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_15_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 15 Cost 1 Value**

Total option 15 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_15_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 15 Cost 1 Multiplier**

Total option 15 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_15_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 15 Cost 2 Value**

Total option 15 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_15_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 15 Cost 2 Multiplier**

Total option 15 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_15_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 15 Lifetime**

The option lifetime.

- **Name:** ``option_15_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 16**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_16``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 16 Apply Logic**

Logic that specifies if the Option 16 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_16_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 16 Cost 1 Value**

Total option 16 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_16_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 16 Cost 1 Multiplier**

Total option 16 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_16_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 16 Cost 2 Value**

Total option 16 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_16_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 16 Cost 2 Multiplier**

Total option 16 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_16_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 16 Lifetime**

The option lifetime.

- **Name:** ``option_16_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 17**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_17``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 17 Apply Logic**

Logic that specifies if the Option 17 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_17_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 17 Cost 1 Value**

Total option 17 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_17_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 17 Cost 1 Multiplier**

Total option 17 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_17_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 17 Cost 2 Value**

Total option 17 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_17_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 17 Cost 2 Multiplier**

Total option 17 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_17_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 17 Lifetime**

The option lifetime.

- **Name:** ``option_17_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 18**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_18``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 18 Apply Logic**

Logic that specifies if the Option 18 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_18_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 18 Cost 1 Value**

Total option 18 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_18_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 18 Cost 1 Multiplier**

Total option 18 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_18_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 18 Cost 2 Value**

Total option 18 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_18_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 18 Cost 2 Multiplier**

Total option 18 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_18_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 18 Lifetime**

The option lifetime.

- **Name:** ``option_18_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 19**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_19``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 19 Apply Logic**

Logic that specifies if the Option 19 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_19_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 19 Cost 1 Value**

Total option 19 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_19_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 19 Cost 1 Multiplier**

Total option 19 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_19_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 19 Cost 2 Value**

Total option 19 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_19_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 19 Cost 2 Multiplier**

Total option 19 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_19_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 19 Lifetime**

The option lifetime.

- **Name:** ``option_19_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 20**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_20``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 20 Apply Logic**

Logic that specifies if the Option 20 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_20_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 20 Cost 1 Value**

Total option 20 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_20_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 20 Cost 1 Multiplier**

Total option 20 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_20_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 20 Cost 2 Value**

Total option 20 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_20_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 20 Cost 2 Multiplier**

Total option 20 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_20_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 20 Lifetime**

The option lifetime.

- **Name:** ``option_20_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 21**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_21``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 21 Apply Logic**

Logic that specifies if the Option 21 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_21_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 21 Cost 1 Value**

Total option 21 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_21_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 21 Cost 1 Multiplier**

Total option 21 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_21_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 21 Cost 2 Value**

Total option 21 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_21_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 21 Cost 2 Multiplier**

Total option 21 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_21_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 21 Lifetime**

The option lifetime.

- **Name:** ``option_21_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 22**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_22``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 22 Apply Logic**

Logic that specifies if the Option 22 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_22_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 22 Cost 1 Value**

Total option 22 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_22_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 22 Cost 1 Multiplier**

Total option 22 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_22_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 22 Cost 2 Value**

Total option 22 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_22_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 22 Cost 2 Multiplier**

Total option 22 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_22_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 22 Lifetime**

The option lifetime.

- **Name:** ``option_22_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 23**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_23``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 23 Apply Logic**

Logic that specifies if the Option 23 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_23_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 23 Cost 1 Value**

Total option 23 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_23_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 23 Cost 1 Multiplier**

Total option 23 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_23_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 23 Cost 2 Value**

Total option 23 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_23_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 23 Cost 2 Multiplier**

Total option 23 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_23_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 23 Lifetime**

The option lifetime.

- **Name:** ``option_23_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 24**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_24``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 24 Apply Logic**

Logic that specifies if the Option 24 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_24_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 24 Cost 1 Value**

Total option 24 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_24_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 24 Cost 1 Multiplier**

Total option 24 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_24_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 24 Cost 2 Value**

Total option 24 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_24_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 24 Cost 2 Multiplier**

Total option 24 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_24_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 24 Lifetime**

The option lifetime.

- **Name:** ``option_24_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 25**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_25``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 25 Apply Logic**

Logic that specifies if the Option 25 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_25_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 25 Cost 1 Value**

Total option 25 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_25_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 25 Cost 1 Multiplier**

Total option 25 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_25_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 25 Cost 2 Value**

Total option 25 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_25_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 25 Cost 2 Multiplier**

Total option 25 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_25_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 25 Lifetime**

The option lifetime.

- **Name:** ``option_25_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Package Apply Logic**

Logic that specifies if the entire package upgrade (all options) will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``package_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Run Measure**

integer argument to run measure [1 is run, 0 is no run]

- **Name:** ``run_measure``
- **Type:** ``Integer``

- **Required:** ``true``

<br/>





