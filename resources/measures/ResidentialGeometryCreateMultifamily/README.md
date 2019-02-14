

###### (Automatically generated documentation)

# ResidentialGeometryCreateSingleUnit

## Description
Sets the geometry for a single unit in a multifamily building based on the user-specified location of the unit. Sets the number of bedrooms, bathrooms, and occupants in the unit. See https://github.com/NREL/OpenStudio-BEopt#workflows for supported workflows using this measure.

## Modeler Description
Creates multifamily geometry for a single unit. Also, sets (or replaces) BuildingUnit objects that store the number of bedrooms and bathrooms associated with the model. Sets (or replaces) the People object for each finished space in the model.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Unit Finished Floor Area
Unit floor area of the finished space (including any finished basement floor area).
**Name:** unit_ffa,
**Type:** Double,
**Units:** ft^2,
**Required:** true,
**Model Dependent:** false

### Wall Height (Per Floor)
The height of the living space walls.
**Name:** wall_height,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Building Number of Floors
The number of floors above grade.
**Name:** num_floors,
**Type:** Integer,
**Units:** #,
**Required:** true,
**Model Dependent:** false

### Num Units
The number of units. This must be divisible by the number of floors.
**Name:** num_units,
**Type:** Integer,
**Units:** #,
**Required:** true,
**Model Dependent:** false

### Unit Aspect Ratio
The ratio of the front/back wall length to the left/right wall length.
**Name:** unit_aspect_ratio,
**Type:** Double,
**Units:** FB/LR,
**Required:** true,
**Model Dependent:** false

### Corridor Position
The position of the corridor.
**Name:** corridor_position,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Corridor Width
The width of the corridor.
**Name:** corridor_width,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Inset Width
The width of the inset.
**Name:** inset_width,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Inset Depth
The depth of the inset.
**Name:** inset_depth,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Inset Position
The position of the inset.
**Name:** inset_position,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Balcony Depth
The depth of the balcony.
**Name:** balcony_depth,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Foundation Type
The foundation type of the building.
**Name:** foundation_type,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Foundation Height
The height of the foundation (e.g., 3ft for crawlspace, 8ft for basement).
**Name:** foundation_height,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Eaves Depth
The eaves depth of the roof.
**Name:** eaves_depth,
**Type:** Double,
**Units:** ft,
**Required:** true,
**Model Dependent:** false

### Number of Bedrooms
Specify the number of bedrooms. Used to determine the energy usage of appliances and plug loads, hot water usage, mechanical ventilation rate, etc.
**Name:** num_bedrooms,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Number of Bathrooms
Specify the number of bathrooms. Used to determine the hot water usage, etc.
**Name:** num_bathrooms,
**Type:** String,
**Units:** ,
**Required:** false,
**Model Dependent:** false

### Number of Occupants
Specify the number of occupants. A value of 'auto' will calculate the average number of occupants from the number of bedrooms. Used to specify the internal gains from people only.
**Name:** num_occupants,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Occupants Weekday schedule
Specify the 24-hour weekday schedule.
**Name:** occupants_weekday_sch,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Occupants Weekend schedule
Specify the 24-hour weekend schedule.
**Name:** occupants_weekend_sch,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Occupants Month schedule
Specify the 12-month schedule.
**Name:** occupants_monthly_sch,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Neighbor Left Offset
The minimum distance between the simulated house and the neighboring house to the left (not including eaves). A value of zero indicates no neighbors.
**Name:** neighbor_left_offset,
**Type:** Double,
**Units:** ft,
**Required:** false,
**Model Dependent:** false

### Neighbor Right Offset
The minimum distance between the simulated house and the neighboring house to the right (not including eaves). A value of zero indicates no neighbors.
**Name:** neighbor_right_offset,
**Type:** Double,
**Units:** ft,
**Required:** false,
**Model Dependent:** false

### Neighbor Back Offset
The minimum distance between the simulated house and the neighboring house to the back (not including eaves). A value of zero indicates no neighbors.
**Name:** neighbor_back_offset,
**Type:** Double,
**Units:** ft,
**Required:** false,
**Model Dependent:** false

### Neighbor Front Offset
The minimum distance between the simulated house and the neighboring house to the front (not including eaves). A value of zero indicates no neighbors.
**Name:** neighbor_front_offset,
**Type:** Double,
**Units:** ft,
**Required:** false,
**Model Dependent:** false

### Azimuth
The house's azimuth is measured clockwise from due south when viewed from above (e.g., South=0, West=90, North=180, East=270).
**Name:** orientation,
**Type:** Double,
**Units:** degrees,
**Required:** true,
**Model Dependent:** false

### Unit Level
The level of the unit (top, middle, bottom)
**Name:** level,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Horizontal Location of the Unit
The horizontal location of the unit when viewwing the front of the building (left, middle, right)
**Name:** horz_location,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Multi story boolean
Indicates if the building has more than one story
**Name:** multi_story,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false

### Rear units boolean
Indicates if the unit has another unit behind it
**Name:** has_rear_units,
**Type:** Boolean,
**Units:** ,
**Required:** true,
**Model Dependent:** false




