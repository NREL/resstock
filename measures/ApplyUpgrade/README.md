
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

**Option 26**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_26``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 26 Apply Logic**

Logic that specifies if the Option 26 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_26_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 26 Cost 1 Value**

Total option 26 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_26_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 26 Cost 1 Multiplier**

Total option 26 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_26_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 26 Cost 2 Value**

Total option 26 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_26_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 26 Cost 2 Multiplier**

Total option 26 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_26_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 26 Lifetime**

The option lifetime.

- **Name:** ``option_26_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 27**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_27``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 27 Apply Logic**

Logic that specifies if the Option 27 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_27_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 27 Cost 1 Value**

Total option 27 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_27_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 27 Cost 1 Multiplier**

Total option 27 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_27_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 27 Cost 2 Value**

Total option 27 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_27_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 27 Cost 2 Multiplier**

Total option 27 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_27_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 27 Lifetime**

The option lifetime.

- **Name:** ``option_27_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 28**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_28``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 28 Apply Logic**

Logic that specifies if the Option 28 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_28_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 28 Cost 1 Value**

Total option 28 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_28_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 28 Cost 1 Multiplier**

Total option 28 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_28_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 28 Cost 2 Value**

Total option 28 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_28_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 28 Cost 2 Multiplier**

Total option 28 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_28_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 28 Lifetime**

The option lifetime.

- **Name:** ``option_28_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 29**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_29``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 29 Apply Logic**

Logic that specifies if the Option 29 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_29_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 29 Cost 1 Value**

Total option 29 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_29_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 29 Cost 1 Multiplier**

Total option 29 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_29_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 29 Cost 2 Value**

Total option 29 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_29_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 29 Cost 2 Multiplier**

Total option 29 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_29_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 29 Lifetime**

The option lifetime.

- **Name:** ``option_29_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 30**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_30``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 30 Apply Logic**

Logic that specifies if the Option 30 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_30_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 30 Cost 1 Value**

Total option 30 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_30_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 30 Cost 1 Multiplier**

Total option 30 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_30_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 30 Cost 2 Value**

Total option 30 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_30_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 30 Cost 2 Multiplier**

Total option 30 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_30_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 30 Lifetime**

The option lifetime.

- **Name:** ``option_30_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 31**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_31``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 31 Apply Logic**

Logic that specifies if the Option 31 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_31_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 31 Cost 1 Value**

Total option 31 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_31_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 31 Cost 1 Multiplier**

Total option 31 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_31_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 31 Cost 2 Value**

Total option 31 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_31_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 31 Cost 2 Multiplier**

Total option 31 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_31_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 31 Lifetime**

The option lifetime.

- **Name:** ``option_31_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 32**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_32``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 32 Apply Logic**

Logic that specifies if the Option 32 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_32_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 32 Cost 1 Value**

Total option 32 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_32_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 32 Cost 1 Multiplier**

Total option 32 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_32_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 32 Cost 2 Value**

Total option 32 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_32_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 32 Cost 2 Multiplier**

Total option 32 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_32_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 32 Lifetime**

The option lifetime.

- **Name:** ``option_32_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 33**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_33``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 33 Apply Logic**

Logic that specifies if the Option 33 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_33_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 33 Cost 1 Value**

Total option 33 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_33_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 33 Cost 1 Multiplier**

Total option 33 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_33_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 33 Cost 2 Value**

Total option 33 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_33_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 33 Cost 2 Multiplier**

Total option 33 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_33_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 33 Lifetime**

The option lifetime.

- **Name:** ``option_33_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 34**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_34``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 34 Apply Logic**

Logic that specifies if the Option 34 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_34_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 34 Cost 1 Value**

Total option 34 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_34_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 34 Cost 1 Multiplier**

Total option 34 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_34_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 34 Cost 2 Value**

Total option 34 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_34_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 34 Cost 2 Multiplier**

Total option 34 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_34_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 34 Lifetime**

The option lifetime.

- **Name:** ``option_34_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 35**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_35``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 35 Apply Logic**

Logic that specifies if the Option 35 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_35_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 35 Cost 1 Value**

Total option 35 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_35_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 35 Cost 1 Multiplier**

Total option 35 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_35_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 35 Cost 2 Value**

Total option 35 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_35_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 35 Cost 2 Multiplier**

Total option 35 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_35_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 35 Lifetime**

The option lifetime.

- **Name:** ``option_35_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 36**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_36``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 36 Apply Logic**

Logic that specifies if the Option 36 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_36_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 36 Cost 1 Value**

Total option 36 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_36_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 36 Cost 1 Multiplier**

Total option 36 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_36_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 36 Cost 2 Value**

Total option 36 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_36_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 36 Cost 2 Multiplier**

Total option 36 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_36_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 36 Lifetime**

The option lifetime.

- **Name:** ``option_36_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 37**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_37``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 37 Apply Logic**

Logic that specifies if the Option 37 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_37_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 37 Cost 1 Value**

Total option 37 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_37_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 37 Cost 1 Multiplier**

Total option 37 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_37_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 37 Cost 2 Value**

Total option 37 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_37_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 37 Cost 2 Multiplier**

Total option 37 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_37_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 37 Lifetime**

The option lifetime.

- **Name:** ``option_37_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 38**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_38``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 38 Apply Logic**

Logic that specifies if the Option 38 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_38_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 38 Cost 1 Value**

Total option 38 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_38_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 38 Cost 1 Multiplier**

Total option 38 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_38_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 38 Cost 2 Value**

Total option 38 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_38_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 38 Cost 2 Multiplier**

Total option 38 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_38_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 38 Lifetime**

The option lifetime.

- **Name:** ``option_38_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 39**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_39``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 39 Apply Logic**

Logic that specifies if the Option 39 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_39_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 39 Cost 1 Value**

Total option 39 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_39_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 39 Cost 1 Multiplier**

Total option 39 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_39_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 39 Cost 2 Value**

Total option 39 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_39_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 39 Cost 2 Multiplier**

Total option 39 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_39_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 39 Lifetime**

The option lifetime.

- **Name:** ``option_39_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 40**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_40``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 40 Apply Logic**

Logic that specifies if the Option 40 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_40_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 40 Cost 1 Value**

Total option 40 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_40_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 40 Cost 1 Multiplier**

Total option 40 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_40_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 40 Cost 2 Value**

Total option 40 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_40_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 40 Cost 2 Multiplier**

Total option 40 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_40_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 40 Lifetime**

The option lifetime.

- **Name:** ``option_40_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 41**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_41``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 41 Apply Logic**

Logic that specifies if the Option 41 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_41_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 41 Cost 1 Value**

Total option 41 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_41_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 41 Cost 1 Multiplier**

Total option 41 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_41_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 41 Cost 2 Value**

Total option 41 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_41_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 41 Cost 2 Multiplier**

Total option 41 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_41_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 41 Lifetime**

The option lifetime.

- **Name:** ``option_41_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 42**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_42``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 42 Apply Logic**

Logic that specifies if the Option 42 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_42_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 42 Cost 1 Value**

Total option 42 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_42_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 42 Cost 1 Multiplier**

Total option 42 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_42_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 42 Cost 2 Value**

Total option 42 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_42_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 42 Cost 2 Multiplier**

Total option 42 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_42_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 42 Lifetime**

The option lifetime.

- **Name:** ``option_42_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 43**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_43``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 43 Apply Logic**

Logic that specifies if the Option 43 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_43_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 43 Cost 1 Value**

Total option 43 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_43_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 43 Cost 1 Multiplier**

Total option 43 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_43_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 43 Cost 2 Value**

Total option 43 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_43_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 43 Cost 2 Multiplier**

Total option 43 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_43_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 43 Lifetime**

The option lifetime.

- **Name:** ``option_43_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 44**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_44``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 44 Apply Logic**

Logic that specifies if the Option 44 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_44_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 44 Cost 1 Value**

Total option 44 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_44_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 44 Cost 1 Multiplier**

Total option 44 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_44_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 44 Cost 2 Value**

Total option 44 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_44_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 44 Cost 2 Multiplier**

Total option 44 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_44_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 44 Lifetime**

The option lifetime.

- **Name:** ``option_44_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 45**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_45``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 45 Apply Logic**

Logic that specifies if the Option 45 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_45_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 45 Cost 1 Value**

Total option 45 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_45_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 45 Cost 1 Multiplier**

Total option 45 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_45_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 45 Cost 2 Value**

Total option 45 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_45_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 45 Cost 2 Multiplier**

Total option 45 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_45_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 45 Lifetime**

The option lifetime.

- **Name:** ``option_45_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 46**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_46``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 46 Apply Logic**

Logic that specifies if the Option 46 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_46_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 46 Cost 1 Value**

Total option 46 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_46_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 46 Cost 1 Multiplier**

Total option 46 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_46_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 46 Cost 2 Value**

Total option 46 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_46_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 46 Cost 2 Multiplier**

Total option 46 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_46_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 46 Lifetime**

The option lifetime.

- **Name:** ``option_46_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 47**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_47``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 47 Apply Logic**

Logic that specifies if the Option 47 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_47_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 47 Cost 1 Value**

Total option 47 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_47_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 47 Cost 1 Multiplier**

Total option 47 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_47_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 47 Cost 2 Value**

Total option 47 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_47_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 47 Cost 2 Multiplier**

Total option 47 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_47_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 47 Lifetime**

The option lifetime.

- **Name:** ``option_47_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 48**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_48``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 48 Apply Logic**

Logic that specifies if the Option 48 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_48_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 48 Cost 1 Value**

Total option 48 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_48_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 48 Cost 1 Multiplier**

Total option 48 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_48_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 48 Cost 2 Value**

Total option 48 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_48_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 48 Cost 2 Multiplier**

Total option 48 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_48_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 48 Lifetime**

The option lifetime.

- **Name:** ``option_48_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 49**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_49``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 49 Apply Logic**

Logic that specifies if the Option 49 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_49_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 49 Cost 1 Value**

Total option 49 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_49_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 49 Cost 1 Multiplier**

Total option 49 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_49_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 49 Cost 2 Value**

Total option 49 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_49_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 49 Cost 2 Multiplier**

Total option 49 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_49_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 49 Lifetime**

The option lifetime.

- **Name:** ``option_49_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 50**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_50``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 50 Apply Logic**

Logic that specifies if the Option 50 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_50_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 50 Cost 1 Value**

Total option 50 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_50_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 50 Cost 1 Multiplier**

Total option 50 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_50_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 50 Cost 2 Value**

Total option 50 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_50_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 50 Cost 2 Multiplier**

Total option 50 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_50_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 50 Lifetime**

The option lifetime.

- **Name:** ``option_50_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 51**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_51``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 51 Apply Logic**

Logic that specifies if the Option 51 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_51_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 51 Cost 1 Value**

Total option 51 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_51_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 51 Cost 1 Multiplier**

Total option 51 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_51_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 51 Cost 2 Value**

Total option 51 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_51_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 51 Cost 2 Multiplier**

Total option 51 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_51_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 51 Lifetime**

The option lifetime.

- **Name:** ``option_51_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 52**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_52``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 52 Apply Logic**

Logic that specifies if the Option 52 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_52_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 52 Cost 1 Value**

Total option 52 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_52_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 52 Cost 1 Multiplier**

Total option 52 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_52_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 52 Cost 2 Value**

Total option 52 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_52_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 52 Cost 2 Multiplier**

Total option 52 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_52_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 52 Lifetime**

The option lifetime.

- **Name:** ``option_52_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 53**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_53``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 53 Apply Logic**

Logic that specifies if the Option 53 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_53_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 53 Cost 1 Value**

Total option 53 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_53_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 53 Cost 1 Multiplier**

Total option 53 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_53_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 53 Cost 2 Value**

Total option 53 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_53_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 53 Cost 2 Multiplier**

Total option 53 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_53_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 53 Lifetime**

The option lifetime.

- **Name:** ``option_53_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 54**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_54``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 54 Apply Logic**

Logic that specifies if the Option 54 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_54_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 54 Cost 1 Value**

Total option 54 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_54_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 54 Cost 1 Multiplier**

Total option 54 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_54_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 54 Cost 2 Value**

Total option 54 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_54_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 54 Cost 2 Multiplier**

Total option 54 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_54_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 54 Lifetime**

The option lifetime.

- **Name:** ``option_54_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 55**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_55``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 55 Apply Logic**

Logic that specifies if the Option 55 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_55_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 55 Cost 1 Value**

Total option 55 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_55_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 55 Cost 1 Multiplier**

Total option 55 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_55_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 55 Cost 2 Value**

Total option 55 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_55_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 55 Cost 2 Multiplier**

Total option 55 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_55_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 55 Lifetime**

The option lifetime.

- **Name:** ``option_55_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 56**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_56``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 56 Apply Logic**

Logic that specifies if the Option 56 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_56_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 56 Cost 1 Value**

Total option 56 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_56_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 56 Cost 1 Multiplier**

Total option 56 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_56_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 56 Cost 2 Value**

Total option 56 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_56_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 56 Cost 2 Multiplier**

Total option 56 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_56_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 56 Lifetime**

The option lifetime.

- **Name:** ``option_56_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 57**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_57``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 57 Apply Logic**

Logic that specifies if the Option 57 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_57_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 57 Cost 1 Value**

Total option 57 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_57_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 57 Cost 1 Multiplier**

Total option 57 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_57_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 57 Cost 2 Value**

Total option 57 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_57_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 57 Cost 2 Multiplier**

Total option 57 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_57_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 57 Lifetime**

The option lifetime.

- **Name:** ``option_57_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 58**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_58``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 58 Apply Logic**

Logic that specifies if the Option 58 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_58_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 58 Cost 1 Value**

Total option 58 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_58_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 58 Cost 1 Multiplier**

Total option 58 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_58_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 58 Cost 2 Value**

Total option 58 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_58_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 58 Cost 2 Multiplier**

Total option 58 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_58_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 58 Lifetime**

The option lifetime.

- **Name:** ``option_58_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 59**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_59``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 59 Apply Logic**

Logic that specifies if the Option 59 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_59_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 59 Cost 1 Value**

Total option 59 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_59_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 59 Cost 1 Multiplier**

Total option 59 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_59_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 59 Cost 2 Value**

Total option 59 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_59_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 59 Cost 2 Multiplier**

Total option 59 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_59_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 59 Lifetime**

The option lifetime.

- **Name:** ``option_59_lifetime``
- **Type:** ``Double``

- **Units:** ``years``

- **Required:** ``false``

<br/>

**Option 60**

Specify the parameter|option as found in resources\options_lookup.tsv.

- **Name:** ``option_60``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 60 Apply Logic**

Logic that specifies if the Option 60 upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.

- **Name:** ``option_60_apply_logic``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Option 60 Cost 1 Value**

Total option 60 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_60_cost_1_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 60 Cost 1 Multiplier**

Total option 60 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_60_cost_1_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 60 Cost 2 Value**

Total option 60 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_60_cost_2_value``
- **Type:** ``Double``

- **Units:** ``$``

- **Required:** ``false``

<br/>

**Option 60 Cost 2 Multiplier**

Total option 60 cost is the sum of all: (Cost N Value) x (Cost N Multiplier).

- **Name:** ``option_60_cost_2_multiplier``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** ``, `Fixed (1)`, `Wall Area, Above-Grade, Conditioned (ft^2)`, `Wall Area, Above-Grade, Exterior (ft^2)`, `Wall Area, Below-Grade (ft^2)`, `Floor Area, Conditioned (ft^2)`, `Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)`, `Floor Area, Lighting (ft^2)`, `Floor Area, Foundation (ft^2)`, `Floor Area, Attic (ft^2)`, `Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)`, `Roof Area (ft^2)`, `Window Area (ft^2)`, `Door Area (ft^2)`, `Duct Unconditioned Surface Area (ft^2)`, `Rim Joist Area, Above-Grade, Exterior (ft^2)`, `Slab Perimeter, Exposed, Conditioned (ft)`, `Size, Heating System Primary (kBtu/h)`, `Size, Heating System Secondary (kBtu/h)`, `Size, Cooling System Primary (kBtu/h)`, `Size, Heat Pump Backup Primary (kBtu/h)`, `Size, Water Heater (gal)`, `Flow Rate, Mechanical Ventilation (cfm)`

<br/>

**Option 60 Lifetime**

The option lifetime.

- **Name:** ``option_60_lifetime``
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





