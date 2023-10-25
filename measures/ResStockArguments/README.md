
###### (Automatically generated documentation)

# ResStock Arguments

## Description
Measure that pre-processes the arguments passed to the BuildResidentialHPXML and BuildResidentialScheduleFile measures.

Passes in all arguments from the options lookup, processes them, and then registers values to the runner to be used by other measures.

## Arguments


**schedules_filepaths**



- **Name:** ``schedules_filepaths``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**schedules_vacancy_period**



- **Name:** ``schedules_vacancy_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**schedules_power_outage_period**



- **Name:** ``schedules_power_outage_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**schedules_power_outage_window_natvent_availability**



- **Name:** ``schedules_power_outage_window_natvent_availability``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**simulation_control_timestep**



- **Name:** ``simulation_control_timestep``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**simulation_control_run_period**



- **Name:** ``simulation_control_run_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**simulation_control_run_period_calendar_year**



- **Name:** ``simulation_control_run_period_calendar_year``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**simulation_control_daylight_saving_enabled**



- **Name:** ``simulation_control_daylight_saving_enabled``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**simulation_control_daylight_saving_period**



- **Name:** ``simulation_control_daylight_saving_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**simulation_control_temperature_capacitance_multiplier**



- **Name:** ``simulation_control_temperature_capacitance_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**site_type**



- **Name:** ``site_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**site_shielding_of_home**



- **Name:** ``site_shielding_of_home``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**site_ground_conductivity**



- **Name:** ``site_ground_conductivity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**site_zip_code**



- **Name:** ``site_zip_code``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**site_iecc_zone**



- **Name:** ``site_iecc_zone``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**site_state_code**



- **Name:** ``site_state_code``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**site_time_zone_utc_offset**



- **Name:** ``site_time_zone_utc_offset``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Weather Station: EnergyPlus Weather (EPW) Filepath**

Path of the EPW file.

- **Name:** ``weather_station_epw_filepath``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**year_built**



- **Name:** ``year_built``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Geometry: Unit Type**

The type of dwelling unit. Use single-family attached for a dwelling unit with 1 or more stories, attached units to one or both sides, and no units above/below. Use apartment unit for a dwelling unit with 1 story, attached units to one, two, or three sides, and units above and/or below.

- **Name:** ``geometry_unit_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `single-family detached`, `single-family attached`, `apartment unit`, `manufactured home`

<br/>

**Geometry: Unit Aspect Ratio**

The ratio of front/back wall length to left/right wall length for the unit, excluding any protruding garage wall area.

- **Name:** ``geometry_unit_aspect_ratio``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Geometry: Unit Orientation**

The unit's orientation is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).

- **Name:** ``geometry_unit_orientation``
- **Type:** ``Double``

- **Units:** ``degrees``

- **Required:** ``true``

<br/>

**Geometry: Unit Number of Bedrooms**

The number of bedrooms in the unit.

- **Name:** ``geometry_unit_num_bedrooms``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``true``

<br/>

**geometry_unit_num_bathrooms**



- **Name:** ``geometry_unit_num_bathrooms``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**geometry_unit_num_occupants**



- **Name:** ``geometry_unit_num_occupants``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**geometry_building_num_units**



- **Name:** ``geometry_building_num_units``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Geometry: Average Ceiling Height**

Average distance from the floor to the ceiling.

- **Name:** ``geometry_average_ceiling_height``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Geometry: Garage Width**

The width of the garage. Enter zero for no garage. Only applies to single-family detached units.

- **Name:** ``geometry_garage_width``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Geometry: Garage Depth**

The depth of the garage. Only applies to single-family detached units.

- **Name:** ``geometry_garage_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Geometry: Garage Protrusion**

The fraction of the garage that is protruding from the conditioned space. Only applies to single-family detached units.

- **Name:** ``geometry_garage_protrusion``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Geometry: Garage Position**

The position of the garage. Only applies to single-family detached units.

- **Name:** ``geometry_garage_position``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Right`, `Left`

<br/>

**Geometry: Foundation Type**

The foundation type of the building. Foundation types ConditionedBasement and ConditionedCrawlspace are not allowed for apartment units.

- **Name:** ``geometry_foundation_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `SlabOnGrade`, `VentedCrawlspace`, `UnventedCrawlspace`, `ConditionedCrawlspace`, `UnconditionedBasement`, `ConditionedBasement`, `Ambient`, `AboveApartment`, `BellyAndWingWithSkirt`, `BellyAndWingNoSkirt`

<br/>

**Geometry: Foundation Height**

The height of the foundation (e.g., 3ft for crawlspace, 8ft for basement). Only applies to basements/crawlspaces.

- **Name:** ``geometry_foundation_height``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Geometry: Foundation Height Above Grade**

The depth above grade of the foundation wall. Only applies to basements/crawlspaces.

- **Name:** ``geometry_foundation_height_above_grade``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**geometry_rim_joist_height**



- **Name:** ``geometry_rim_joist_height``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Geometry: Attic Type**

The attic type of the building. Attic type ConditionedAttic is not allowed for apartment units.

- **Name:** ``geometry_attic_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `FlatRoof`, `VentedAttic`, `UnventedAttic`, `ConditionedAttic`, `BelowApartment`

<br/>

**Geometry: Roof Type**

The roof type of the building. Ignored if the building has a flat roof.

- **Name:** ``geometry_roof_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `gable`, `hip`

<br/>

**Geometry: Roof Pitch**

The roof pitch of the attic. Ignored if the building has a flat roof.

- **Name:** ``geometry_roof_pitch``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `1:12`, `2:12`, `3:12`, `4:12`, `5:12`, `6:12`, `7:12`, `8:12`, `9:12`, `10:12`, `11:12`, `12:12`

<br/>

**Geometry: Eaves Depth**

The eaves depth of the roof.

- **Name:** ``geometry_eaves_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Neighbor: Front Distance**

The distance between the unit and the neighboring building to the front (not including eaves). A value of zero indicates no neighbors. Used for shading.

- **Name:** ``neighbor_front_distance``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Neighbor: Back Distance**

The distance between the unit and the neighboring building to the back (not including eaves). A value of zero indicates no neighbors. Used for shading.

- **Name:** ``neighbor_back_distance``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Neighbor: Left Distance**

The distance between the unit and the neighboring building to the left (not including eaves). A value of zero indicates no neighbors. Used for shading.

- **Name:** ``neighbor_left_distance``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Neighbor: Right Distance**

The distance between the unit and the neighboring building to the right (not including eaves). A value of zero indicates no neighbors. Used for shading.

- **Name:** ``neighbor_right_distance``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**neighbor_front_height**



- **Name:** ``neighbor_front_height``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**neighbor_back_height**



- **Name:** ``neighbor_back_height``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**neighbor_left_height**



- **Name:** ``neighbor_left_height``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**neighbor_right_height**



- **Name:** ``neighbor_right_height``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Floor: Over Foundation Assembly R-value**

Assembly R-value for the floor over the foundation. Ignored if the building has a slab-on-grade foundation.

- **Name:** ``floor_over_foundation_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Floor: Over Garage Assembly R-value**

Assembly R-value for the floor over the garage. Ignored unless the building has a garage under conditioned space.

- **Name:** ``floor_over_garage_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Floor: Type**

The type of floors.

- **Name:** ``floor_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `WoodFrame`, `StructuralInsulatedPanel`, `SolidConcrete`, `SteelFrame`

<br/>

**foundation_wall_type**



- **Name:** ``foundation_wall_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**foundation_wall_thickness**



- **Name:** ``foundation_wall_thickness``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Foundation Wall: Insulation Nominal R-value**

Nominal R-value for the foundation wall insulation. Only applies to basements/crawlspaces.

- **Name:** ``foundation_wall_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**foundation_wall_insulation_location**



- **Name:** ``foundation_wall_insulation_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**foundation_wall_insulation_distance_to_top**



- **Name:** ``foundation_wall_insulation_distance_to_top``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**foundation_wall_insulation_distance_to_bottom**



- **Name:** ``foundation_wall_insulation_distance_to_bottom``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**foundation_wall_assembly_r**



- **Name:** ``foundation_wall_assembly_r``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**rim_joist_assembly_r**



- **Name:** ``rim_joist_assembly_r``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Slab: Perimeter Insulation Nominal R-value**

Nominal R-value of the vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_perimeter_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Slab: Perimeter Insulation Depth**

Depth from grade to bottom of vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_perimeter_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Slab: Under Slab Insulation Nominal R-value**

Nominal R-value of the horizontal under slab insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_under_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Slab: Under Slab Insulation Width**

Width from slab edge inward of horizontal under-slab insulation. Enter 999 to specify that the under slab insulation spans the entire slab. Applies to slab-on-grade foundations and basement/crawlspace floors.

- **Name:** ``slab_under_width``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**slab_thickness**



- **Name:** ``slab_thickness``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**slab_carpet_fraction**



- **Name:** ``slab_carpet_fraction``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**slab_carpet_r**



- **Name:** ``slab_carpet_r``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Ceiling: Assembly R-value**

Assembly R-value for the ceiling (attic floor).

- **Name:** ``ceiling_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**roof_material_type**



- **Name:** ``roof_material_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**roof_color**



- **Name:** ``roof_color``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Roof: Assembly R-value**

Assembly R-value of the roof.

- **Name:** ``roof_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Roof: Has Radiant Barrier**

Presence of a radiant barrier in the attic.

- **Name:** ``roof_radiant_barrier``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**roof_radiant_barrier_grade**



- **Name:** ``roof_radiant_barrier_grade``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Wall: Type**

The type of walls.

- **Name:** ``wall_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `WoodStud`, `ConcreteMasonryUnit`, `DoubleWoodStud`, `InsulatedConcreteForms`, `LogWall`, `StructuralInsulatedPanel`, `SolidConcrete`, `SteelFrame`, `Stone`, `StrawBale`, `StructuralBrick`

<br/>

**wall_siding_type**



- **Name:** ``wall_siding_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**wall_color**



- **Name:** ``wall_color``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Wall: Assembly R-value**

Assembly R-value of the walls.

- **Name:** ``wall_assembly_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Windows: Front Window-to-Wall Ratio**

The ratio of window area to wall area for the unit's front facade. Enter 0 if specifying Front Window Area instead.

- **Name:** ``window_front_wwr``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Windows: Back Window-to-Wall Ratio**

The ratio of window area to wall area for the unit's back facade. Enter 0 if specifying Back Window Area instead.

- **Name:** ``window_back_wwr``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Windows: Left Window-to-Wall Ratio**

The ratio of window area to wall area for the unit's left facade (when viewed from the front). Enter 0 if specifying Left Window Area instead.

- **Name:** ``window_left_wwr``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Windows: Right Window-to-Wall Ratio**

The ratio of window area to wall area for the unit's right facade (when viewed from the front). Enter 0 if specifying Right Window Area instead.

- **Name:** ``window_right_wwr``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Windows: Front Window Area**

The amount of window area on the unit's front facade. Enter 0 if specifying Front Window-to-Wall Ratio instead.

- **Name:** ``window_area_front``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Windows: Back Window Area**

The amount of window area on the unit's back facade. Enter 0 if specifying Back Window-to-Wall Ratio instead.

- **Name:** ``window_area_back``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Windows: Left Window Area**

The amount of window area on the unit's left facade (when viewed from the front). Enter 0 if specifying Left Window-to-Wall Ratio instead.

- **Name:** ``window_area_left``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Windows: Right Window Area**

The amount of window area on the unit's right facade (when viewed from the front). Enter 0 if specifying Right Window-to-Wall Ratio instead.

- **Name:** ``window_area_right``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Windows: Aspect Ratio**

Ratio of window height to width.

- **Name:** ``window_aspect_ratio``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**window_fraction_operable**



- **Name:** ``window_fraction_operable``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**window_natvent_availability**



- **Name:** ``window_natvent_availability``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Windows: U-Factor**

Full-assembly NFRC U-factor.

- **Name:** ``window_ufactor``
- **Type:** ``Double``

- **Units:** ``Btu/hr-ft^2-R``

- **Required:** ``true``

<br/>

**Windows: SHGC**

Full-assembly NFRC solar heat gain coefficient.

- **Name:** ``window_shgc``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**window_interior_shading_winter**



- **Name:** ``window_interior_shading_winter``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**window_interior_shading_summer**



- **Name:** ``window_interior_shading_summer``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**window_exterior_shading_winter**



- **Name:** ``window_exterior_shading_winter``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**window_exterior_shading_summer**



- **Name:** ``window_exterior_shading_summer``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**window_shading_summer_season**



- **Name:** ``window_shading_summer_season``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**window_storm_type**



- **Name:** ``window_storm_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Overhangs: Front Depth**

The depth of overhangs for windows for the front facade.

- **Name:** ``overhangs_front_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Front Distance to Top of Window**

The overhangs distance to the top of window for the front facade.

- **Name:** ``overhangs_front_distance_to_top_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Front Distance to Bottom of Window**

The overhangs distance to the bottom of window for the front facade.

- **Name:** ``overhangs_front_distance_to_bottom_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Back Depth**

The depth of overhangs for windows for the back facade.

- **Name:** ``overhangs_back_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Back Distance to Top of Window**

The overhangs distance to the top of window for the back facade.

- **Name:** ``overhangs_back_distance_to_top_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Back Distance to Bottom of Window**

The overhangs distance to the bottom of window for the back facade.

- **Name:** ``overhangs_back_distance_to_bottom_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Left Depth**

The depth of overhangs for windows for the left facade.

- **Name:** ``overhangs_left_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Left Distance to Top of Window**

The overhangs distance to the top of window for the left facade.

- **Name:** ``overhangs_left_distance_to_top_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Left Distance to Bottom of Window**

The overhangs distance to the bottom of window for the left facade.

- **Name:** ``overhangs_left_distance_to_bottom_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Right Depth**

The depth of overhangs for windows for the right facade.

- **Name:** ``overhangs_right_depth``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Right Distance to Top of Window**

The overhangs distance to the top of window for the right facade.

- **Name:** ``overhangs_right_distance_to_top_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Overhangs: Right Distance to Bottom of Window**

The overhangs distance to the bottom of window for the right facade.

- **Name:** ``overhangs_right_distance_to_bottom_of_window``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Skylights: Front Roof Area**

The amount of skylight area on the unit's front conditioned roof facade.

- **Name:** ``skylight_area_front``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Skylights: Back Roof Area**

The amount of skylight area on the unit's back conditioned roof facade.

- **Name:** ``skylight_area_back``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Skylights: Left Roof Area**

The amount of skylight area on the unit's left conditioned roof facade (when viewed from the front).

- **Name:** ``skylight_area_left``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Skylights: Right Roof Area**

The amount of skylight area on the unit's right conditioned roof facade (when viewed from the front).

- **Name:** ``skylight_area_right``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Skylights: U-Factor**

Full-assembly NFRC U-factor.

- **Name:** ``skylight_ufactor``
- **Type:** ``Double``

- **Units:** ``Btu/hr-ft^2-R``

- **Required:** ``true``

<br/>

**Skylights: SHGC**

Full-assembly NFRC solar heat gain coefficient.

- **Name:** ``skylight_shgc``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**skylight_storm_type**



- **Name:** ``skylight_storm_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Doors: Area**

The area of the opaque door(s).

- **Name:** ``door_area``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Doors: R-value**

R-value of the opaque door(s).

- **Name:** ``door_rvalue``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Air Leakage: Units**

The unit of measure for the air leakage.

- **Name:** ``air_leakage_units``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `ACH`, `CFM`, `ACHnatural`, `CFMnatural`, `EffectiveLeakageArea`

<br/>

**Air Leakage: House Pressure**

The house pressure relative to outside. Required when units are ACH or CFM.

- **Name:** ``air_leakage_house_pressure``
- **Type:** ``Double``

- **Units:** ``Pa``

- **Required:** ``true``

<br/>

**Air Leakage: Value**

Air exchange rate value. For 'EffectiveLeakageArea', provide value in sq. in.

- **Name:** ``air_leakage_value``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**air_leakage_type**



- **Name:** ``air_leakage_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**air_leakage_has_flue_or_chimney_in_conditioned_space**



- **Name:** ``air_leakage_has_flue_or_chimney_in_conditioned_space``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Heating System: Type**

The type of heating system. Use 'none' if there is no heating system or if there is a heat pump serving a heating load.

- **Name:** ``heating_system_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `Furnace`, `WallFurnace`, `FloorFurnace`, `Boiler`, `ElectricResistance`, `Stove`, `SpaceHeater`, `Fireplace`, `Shared Boiler w/ Baseboard`, `Shared Boiler w/ Ductless Fan Coil`

<br/>

**Heating System: Fuel Type**

The fuel type of the heating system. Ignored for ElectricResistance.

- **Name:** ``heating_system_fuel``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`, `coal`

<br/>

**Heating System: Rated AFUE or Percent**

The rated heating efficiency value of the heating system.

- **Name:** ``heating_system_heating_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**heating_system_heating_capacity**



- **Name:** ``heating_system_heating_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Heating System: Fraction Heat Load Served**

The heating load served by the heating system.

- **Name:** ``heating_system_fraction_heat_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**heating_system_pilot_light**



- **Name:** ``heating_system_pilot_light``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Cooling System: Type**

The type of cooling system. Use 'none' if there is no cooling system or if there is a heat pump serving a cooling load.

- **Name:** ``cooling_system_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `central air conditioner`, `room air conditioner`, `evaporative cooler`, `mini-split`, `packaged terminal air conditioner`

<br/>

**Cooling System: Efficiency Type**

The efficiency type of the cooling system. System types central air conditioner and mini-split use SEER or SEER2. System types room air conditioner and packaged terminal air conditioner use EER or CEER. Ignored for system type evaporative cooler.

- **Name:** ``cooling_system_cooling_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `SEER`, `SEER2`, `EER`, `CEER`

<br/>

**Cooling System: Efficiency**

The rated efficiency value of the cooling system. Ignored for evaporative cooler.

- **Name:** ``cooling_system_cooling_efficiency``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**cooling_system_cooling_compressor_type**



- **Name:** ``cooling_system_cooling_compressor_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**cooling_system_cooling_sensible_heat_fraction**



- **Name:** ``cooling_system_cooling_sensible_heat_fraction``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**cooling_system_cooling_capacity**



- **Name:** ``cooling_system_cooling_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Cooling System: Fraction Cool Load Served**

The cooling load served by the cooling system.

- **Name:** ``cooling_system_fraction_cool_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**cooling_system_is_ducted**



- **Name:** ``cooling_system_is_ducted``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**cooling_system_crankcase_heater_watts**



- **Name:** ``cooling_system_crankcase_heater_watts``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**cooling_system_integrated_heating_system_fuel**



- **Name:** ``cooling_system_integrated_heating_system_fuel``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**cooling_system_integrated_heating_system_efficiency_percent**



- **Name:** ``cooling_system_integrated_heating_system_efficiency_percent``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**cooling_system_integrated_heating_system_capacity**



- **Name:** ``cooling_system_integrated_heating_system_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**cooling_system_integrated_heating_system_fraction_heat_load_served**



- **Name:** ``cooling_system_integrated_heating_system_fraction_heat_load_served``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Heat Pump: Type**

The type of heat pump. Use 'none' if there is no heat pump.

- **Name:** ``heat_pump_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `air-to-air`, `mini-split`, `ground-to-air`, `packaged terminal heat pump`, `room air conditioner with reverse cycle`

<br/>

**Heat Pump: Heating Efficiency Type**

The heating efficiency type of heat pump. System types air-to-air and mini-split use HSPF or HSPF2. System types ground-to-air, packaged terminal heat pump and room air conditioner with reverse cycle use COP.

- **Name:** ``heat_pump_heating_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `HSPF`, `HSPF2`, `COP`

<br/>

**Heat Pump: Heating Efficiency**

The rated heating efficiency value of the heat pump.

- **Name:** ``heat_pump_heating_efficiency``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Heat Pump: Cooling Efficiency Type**

The cooling efficiency type of heat pump. System types air-to-air and mini-split use SEER or SEER2. System types ground-to-air, packaged terminal heat pump and room air conditioner with reverse cycle use EER.

- **Name:** ``heat_pump_cooling_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `SEER`, `SEER2`, `EER`, `CEER`

<br/>

**Heat Pump: Cooling Efficiency**

The rated cooling efficiency value of the heat pump.

- **Name:** ``heat_pump_cooling_efficiency``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**heat_pump_cooling_compressor_type**



- **Name:** ``heat_pump_cooling_compressor_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**heat_pump_cooling_sensible_heat_fraction**



- **Name:** ``heat_pump_cooling_sensible_heat_fraction``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**heat_pump_heating_capacity**



- **Name:** ``heat_pump_heating_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**heat_pump_heating_capacity_retention_fraction**



- **Name:** ``heat_pump_heating_capacity_retention_fraction``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**heat_pump_heating_capacity_retention_temp**



- **Name:** ``heat_pump_heating_capacity_retention_temp``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**heat_pump_cooling_capacity**



- **Name:** ``heat_pump_cooling_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Heat Pump: Fraction Heat Load Served**

The heating load served by the heat pump.

- **Name:** ``heat_pump_fraction_heat_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Heat Pump: Fraction Cool Load Served**

The cooling load served by the heat pump.

- **Name:** ``heat_pump_fraction_cool_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**heat_pump_compressor_lockout_temp**



- **Name:** ``heat_pump_compressor_lockout_temp``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Heat Pump: Backup Type**

The backup type of the heat pump. If 'integrated', represents e.g. built-in electric strip heat or dual-fuel integrated furnace. If 'separate', represents e.g. electric baseboard or boiler based on the Heating System 2 specified below. Use 'none' if there is no backup heating.

- **Name:** ``heat_pump_backup_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `integrated`, `separate`

<br/>

**Heat Pump: Backup Fuel Type**

The backup fuel type of the heat pump. Only applies if Backup Type is 'integrated'.

- **Name:** ``heat_pump_backup_fuel``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`

<br/>

**Heat Pump: Backup Rated Efficiency**

The backup rated efficiency value of the heat pump. Percent for electricity fuel type. AFUE otherwise. Only applies if Backup Type is 'integrated'.

- **Name:** ``heat_pump_backup_heating_efficiency``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**heat_pump_backup_heating_capacity**



- **Name:** ``heat_pump_backup_heating_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**heat_pump_backup_heating_lockout_temp**



- **Name:** ``heat_pump_backup_heating_lockout_temp``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**heat_pump_sizing_methodology**



- **Name:** ``heat_pump_sizing_methodology``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**heat_pump_is_ducted**



- **Name:** ``heat_pump_is_ducted``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**heat_pump_crankcase_heater_watts**



- **Name:** ``heat_pump_crankcase_heater_watts``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Heating System 2: Type**

The type of the second heating system.

- **Name:** ``heating_system_2_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `Furnace`, `WallFurnace`, `FloorFurnace`, `Boiler`, `ElectricResistance`, `Stove`, `SpaceHeater`, `Fireplace`

<br/>

**Heating System 2: Fuel Type**

The fuel type of the second heating system. Ignored for ElectricResistance.

- **Name:** ``heating_system_2_fuel``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`, `coal`

<br/>

**Heating System 2: Rated AFUE or Percent**

The rated heating efficiency value of the second heating system.

- **Name:** ``heating_system_2_heating_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**heating_system_2_heating_capacity**



- **Name:** ``heating_system_2_heating_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Heating System 2: Fraction Heat Load Served**

The heat load served fraction of the second heating system. Ignored if this heating system serves as a backup system for a heat pump.

- **Name:** ``heating_system_2_fraction_heat_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**hvac_control_heating_season_period**



- **Name:** ``hvac_control_heating_season_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**hvac_control_cooling_season_period**



- **Name:** ``hvac_control_cooling_season_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Ducts: Leakage Units**

The leakage units of the ducts.

- **Name:** ``ducts_leakage_units``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `CFM25`, `CFM50`, `Percent`

<br/>

**Ducts: Supply Leakage to Outside Value**

The leakage value to outside for the supply ducts.

- **Name:** ``ducts_supply_leakage_to_outside_value``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Ducts: Return Leakage to Outside Value**

The leakage value to outside for the return ducts.

- **Name:** ``ducts_return_leakage_to_outside_value``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**ducts_supply_location**



- **Name:** ``ducts_supply_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Ducts: Supply Insulation R-Value**

The insulation r-value of the supply ducts excluding air films.

- **Name:** ``ducts_supply_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**ducts_supply_buried_insulation_level**



- **Name:** ``ducts_supply_buried_insulation_level``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**ducts_supply_surface_area**



- **Name:** ``ducts_supply_surface_area``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**ducts_supply_surface_area_fraction**



- **Name:** ``ducts_supply_surface_area_fraction``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**ducts_return_location**



- **Name:** ``ducts_return_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Ducts: Return Insulation R-Value**

The insulation r-value of the return ducts excluding air films.

- **Name:** ``ducts_return_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**ducts_return_buried_insulation_level**



- **Name:** ``ducts_return_buried_insulation_level``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**ducts_return_surface_area**



- **Name:** ``ducts_return_surface_area``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**ducts_return_surface_area_fraction**



- **Name:** ``ducts_return_surface_area_fraction``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**ducts_number_of_return_registers**



- **Name:** ``ducts_number_of_return_registers``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Mechanical Ventilation: Fan Type**

The type of the mechanical ventilation. Use 'none' if there is no mechanical ventilation system.

- **Name:** ``mech_vent_fan_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `exhaust only`, `supply only`, `energy recovery ventilator`, `heat recovery ventilator`, `balanced`, `central fan integrated supply`

<br/>

**mech_vent_flow_rate**



- **Name:** ``mech_vent_flow_rate``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**mech_vent_hours_in_operation**



- **Name:** ``mech_vent_hours_in_operation``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Mechanical Ventilation: Total Recovery Efficiency Type**

The total recovery efficiency type of the mechanical ventilation.

- **Name:** ``mech_vent_recovery_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Unadjusted`, `Adjusted`

<br/>

**Mechanical Ventilation: Total Recovery Efficiency**

The Unadjusted or Adjusted total recovery efficiency of the mechanical ventilation. Applies to energy recovery ventilator.

- **Name:** ``mech_vent_total_recovery_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Mechanical Ventilation: Sensible Recovery Efficiency**

The Unadjusted or Adjusted sensible recovery efficiency of the mechanical ventilation. Applies to energy recovery ventilator and heat recovery ventilator.

- **Name:** ``mech_vent_sensible_recovery_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**mech_vent_fan_power**



- **Name:** ``mech_vent_fan_power``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Mechanical Ventilation: Number of Units Served**

Number of dwelling units served by the mechanical ventilation system. Must be 1 if single-family detached. Used to apportion flow rate and fan power to the unit.

- **Name:** ``mech_vent_num_units_served``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``true``

<br/>

**mech_vent_shared_frac_recirculation**



- **Name:** ``mech_vent_shared_frac_recirculation``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**mech_vent_shared_preheating_fuel**



- **Name:** ``mech_vent_shared_preheating_fuel``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**mech_vent_shared_preheating_efficiency**



- **Name:** ``mech_vent_shared_preheating_efficiency``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**mech_vent_shared_preheating_fraction_heat_load_served**



- **Name:** ``mech_vent_shared_preheating_fraction_heat_load_served``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**mech_vent_shared_precooling_fuel**



- **Name:** ``mech_vent_shared_precooling_fuel``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**mech_vent_shared_precooling_efficiency**



- **Name:** ``mech_vent_shared_precooling_efficiency``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**mech_vent_shared_precooling_fraction_cool_load_served**



- **Name:** ``mech_vent_shared_precooling_fraction_cool_load_served``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Mechanical Ventilation 2: Fan Type**

The type of the second mechanical ventilation. Use 'none' if there is no second mechanical ventilation system.

- **Name:** ``mech_vent_2_fan_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `exhaust only`, `supply only`, `energy recovery ventilator`, `heat recovery ventilator`, `balanced`

<br/>

**Mechanical Ventilation 2: Flow Rate**

The flow rate of the second mechanical ventilation.

- **Name:** ``mech_vent_2_flow_rate``
- **Type:** ``Double``

- **Units:** ``CFM``

- **Required:** ``true``

<br/>

**Mechanical Ventilation 2: Hours In Operation**

The hours in operation of the second mechanical ventilation.

- **Name:** ``mech_vent_2_hours_in_operation``
- **Type:** ``Double``

- **Units:** ``hrs/day``

- **Required:** ``true``

<br/>

**Mechanical Ventilation 2: Total Recovery Efficiency Type**

The total recovery efficiency type of the second mechanical ventilation.

- **Name:** ``mech_vent_2_recovery_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Unadjusted`, `Adjusted`

<br/>

**Mechanical Ventilation 2: Total Recovery Efficiency**

The Unadjusted or Adjusted total recovery efficiency of the second mechanical ventilation. Applies to energy recovery ventilator.

- **Name:** ``mech_vent_2_total_recovery_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Mechanical Ventilation 2: Sensible Recovery Efficiency**

The Unadjusted or Adjusted sensible recovery efficiency of the second mechanical ventilation. Applies to energy recovery ventilator and heat recovery ventilator.

- **Name:** ``mech_vent_2_sensible_recovery_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Mechanical Ventilation 2: Fan Power**

The fan power of the second mechanical ventilation.

- **Name:** ``mech_vent_2_fan_power``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``true``

<br/>

**kitchen_fans_quantity**



- **Name:** ``kitchen_fans_quantity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**kitchen_fans_flow_rate**



- **Name:** ``kitchen_fans_flow_rate``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**kitchen_fans_hours_in_operation**



- **Name:** ``kitchen_fans_hours_in_operation``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**kitchen_fans_power**



- **Name:** ``kitchen_fans_power``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**kitchen_fans_start_hour**



- **Name:** ``kitchen_fans_start_hour``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**bathroom_fans_quantity**



- **Name:** ``bathroom_fans_quantity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**bathroom_fans_flow_rate**



- **Name:** ``bathroom_fans_flow_rate``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**bathroom_fans_hours_in_operation**



- **Name:** ``bathroom_fans_hours_in_operation``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**bathroom_fans_power**



- **Name:** ``bathroom_fans_power``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**bathroom_fans_start_hour**



- **Name:** ``bathroom_fans_start_hour``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Whole House Fan: Present**

Whether there is a whole house fan.

- **Name:** ``whole_house_fan_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**whole_house_fan_flow_rate**



- **Name:** ``whole_house_fan_flow_rate``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**whole_house_fan_power**



- **Name:** ``whole_house_fan_power``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Water Heater: Type**

The type of water heater. Use 'none' if there is no water heater.

- **Name:** ``water_heater_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `storage water heater`, `instantaneous water heater`, `heat pump water heater`, `space-heating boiler with storage tank`, `space-heating boiler with tankless coil`

<br/>

**Water Heater: Fuel Type**

The fuel type of water heater. Ignored for heat pump water heater.

- **Name:** ``water_heater_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `coal`

<br/>

**water_heater_location**



- **Name:** ``water_heater_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**water_heater_tank_volume**



- **Name:** ``water_heater_tank_volume``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Water Heater: Efficiency Type**

The efficiency type of water heater. Does not apply to space-heating boilers.

- **Name:** ``water_heater_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `EnergyFactor`, `UniformEnergyFactor`

<br/>

**Water Heater: Efficiency**

Rated Energy Factor or Uniform Energy Factor. Does not apply to space-heating boilers.

- **Name:** ``water_heater_efficiency``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**water_heater_usage_bin**



- **Name:** ``water_heater_usage_bin``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**water_heater_recovery_efficiency**



- **Name:** ``water_heater_recovery_efficiency``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**water_heater_heating_capacity**



- **Name:** ``water_heater_heating_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**water_heater_standby_loss**



- **Name:** ``water_heater_standby_loss``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**water_heater_jacket_rvalue**



- **Name:** ``water_heater_jacket_rvalue``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**water_heater_setpoint_temperature**



- **Name:** ``water_heater_setpoint_temperature``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Water Heater: Number of Units Served**

Number of dwelling units served (directly or indirectly) by the water heater. Must be 1 if single-family detached. Used to apportion water heater tank losses to the unit.

- **Name:** ``water_heater_num_units_served``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``true``

<br/>

**water_heater_uses_desuperheater**



- **Name:** ``water_heater_uses_desuperheater``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**water_heater_tank_model_type**



- **Name:** ``water_heater_tank_model_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**water_heater_operating_mode**



- **Name:** ``water_heater_operating_mode``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Hot Water Distribution: System Type**

The type of the hot water distribution system.

- **Name:** ``hot_water_distribution_system_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Standard`, `Recirculation`

<br/>

**hot_water_distribution_standard_piping_length**



- **Name:** ``hot_water_distribution_standard_piping_length``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**hot_water_distribution_recirc_control_type**



- **Name:** ``hot_water_distribution_recirc_control_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**hot_water_distribution_recirc_piping_length**



- **Name:** ``hot_water_distribution_recirc_piping_length``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**hot_water_distribution_recirc_branch_piping_length**



- **Name:** ``hot_water_distribution_recirc_branch_piping_length``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**hot_water_distribution_recirc_pump_power**



- **Name:** ``hot_water_distribution_recirc_pump_power``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**hot_water_distribution_pipe_r**



- **Name:** ``hot_water_distribution_pipe_r``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Drain Water Heat Recovery: Facilities Connected**

Which facilities are connected for the drain water heat recovery. Use 'none' if there is no drain water heat recovery system.

- **Name:** ``dwhr_facilities_connected``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `one`, `all`

<br/>

**dwhr_equal_flow**



- **Name:** ``dwhr_equal_flow``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**dwhr_efficiency**



- **Name:** ``dwhr_efficiency``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Hot Water Fixtures: Is Shower Low Flow**

Whether the shower fixture is low flow.

- **Name:** ``water_fixtures_shower_low_flow``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Hot Water Fixtures: Is Sink Low Flow**

Whether the sink fixture is low flow.

- **Name:** ``water_fixtures_sink_low_flow``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**water_fixtures_usage_multiplier**



- **Name:** ``water_fixtures_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Solar Thermal: System Type**

The type of solar thermal system. Use 'none' if there is no solar thermal system.

- **Name:** ``solar_thermal_system_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `hot water`

<br/>

**Solar Thermal: Collector Area**

The collector area of the solar thermal system.

- **Name:** ``solar_thermal_collector_area``
- **Type:** ``Double``

- **Units:** ``ft^2``

- **Required:** ``true``

<br/>

**Solar Thermal: Collector Loop Type**

The collector loop type of the solar thermal system.

- **Name:** ``solar_thermal_collector_loop_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `liquid direct`, `liquid indirect`, `passive thermosyphon`

<br/>

**Solar Thermal: Collector Type**

The collector type of the solar thermal system.

- **Name:** ``solar_thermal_collector_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `evacuated tube`, `single glazing black`, `double glazing black`, `integrated collector storage`

<br/>

**Solar Thermal: Collector Azimuth**

The collector azimuth of the solar thermal system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).

- **Name:** ``solar_thermal_collector_azimuth``
- **Type:** ``Double``

- **Units:** ``degrees``

- **Required:** ``true``

<br/>

**Solar Thermal: Collector Tilt**

The collector tilt of the solar thermal system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.

- **Name:** ``solar_thermal_collector_tilt``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Solar Thermal: Collector Rated Optical Efficiency**

The collector rated optical efficiency of the solar thermal system.

- **Name:** ``solar_thermal_collector_rated_optical_efficiency``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Solar Thermal: Collector Rated Thermal Losses**

The collector rated thermal losses of the solar thermal system.

- **Name:** ``solar_thermal_collector_rated_thermal_losses``
- **Type:** ``Double``

- **Units:** ``Btu/hr-ft^2-R``

- **Required:** ``true``

<br/>

**solar_thermal_storage_volume**



- **Name:** ``solar_thermal_storage_volume``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Solar Thermal: Solar Fraction**

The solar fraction of the solar thermal system. If provided, overrides all other solar thermal inputs.

- **Name:** ``solar_thermal_solar_fraction``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**PV System: Present**

Whether there is a PV system present.

- **Name:** ``pv_system_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**pv_system_module_type**



- **Name:** ``pv_system_module_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**pv_system_location**



- **Name:** ``pv_system_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**pv_system_tracking**



- **Name:** ``pv_system_tracking``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**PV System: Array Azimuth**

Array azimuth of the PV system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).

- **Name:** ``pv_system_array_azimuth``
- **Type:** ``Double``

- **Units:** ``degrees``

- **Required:** ``true``

<br/>

**PV System: Array Tilt**

Array tilt of the PV system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.

- **Name:** ``pv_system_array_tilt``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**PV System: Maximum Power Output**

Maximum power output of the PV system. For a shared system, this is the total building maximum power output.

- **Name:** ``pv_system_max_power_output``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``true``

<br/>

**pv_system_inverter_efficiency**



- **Name:** ``pv_system_inverter_efficiency``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**pv_system_system_losses_fraction**



- **Name:** ``pv_system_system_losses_fraction``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**PV System 2: Present**

Whether there is a second PV system present.

- **Name:** ``pv_system_2_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**pv_system_2_module_type**



- **Name:** ``pv_system_2_module_type``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**pv_system_2_location**



- **Name:** ``pv_system_2_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**pv_system_2_tracking**



- **Name:** ``pv_system_2_tracking``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**PV System 2: Array Azimuth**

Array azimuth of the second PV system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).

- **Name:** ``pv_system_2_array_azimuth``
- **Type:** ``Double``

- **Units:** ``degrees``

- **Required:** ``true``

<br/>

**PV System 2: Array Tilt**

Array tilt of the second PV system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.

- **Name:** ``pv_system_2_array_tilt``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**PV System 2: Maximum Power Output**

Maximum power output of the second PV system. For a shared system, this is the total building maximum power output.

- **Name:** ``pv_system_2_max_power_output``
- **Type:** ``Double``

- **Units:** ``W``

- **Required:** ``true``

<br/>

**Battery: Present**

Whether there is a lithium ion battery present.

- **Name:** ``battery_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**battery_location**



- **Name:** ``battery_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**battery_power**



- **Name:** ``battery_power``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**battery_capacity**



- **Name:** ``battery_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**battery_usable_capacity**



- **Name:** ``battery_usable_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**battery_round_trip_efficiency**



- **Name:** ``battery_round_trip_efficiency``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Lighting: Present**

Whether there is lighting energy use.

- **Name:** ``lighting_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Lighting: Interior Fraction CFL**

Fraction of all lamps (interior) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_interior_fraction_cfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Interior Fraction LFL**

Fraction of all lamps (interior) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_interior_fraction_lfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Interior Fraction LED**

Fraction of all lamps (interior) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_interior_fraction_led``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**lighting_interior_usage_multiplier**



- **Name:** ``lighting_interior_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Lighting: Exterior Fraction CFL**

Fraction of all lamps (exterior) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_exterior_fraction_cfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Exterior Fraction LFL**

Fraction of all lamps (exterior) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_exterior_fraction_lfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Exterior Fraction LED**

Fraction of all lamps (exterior) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_exterior_fraction_led``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**lighting_exterior_usage_multiplier**



- **Name:** ``lighting_exterior_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Lighting: Garage Fraction CFL**

Fraction of all lamps (garage) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_garage_fraction_cfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Garage Fraction LFL**

Fraction of all lamps (garage) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_garage_fraction_lfl``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Lighting: Garage Fraction LED**

Fraction of all lamps (garage) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.

- **Name:** ``lighting_garage_fraction_led``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**lighting_garage_usage_multiplier**



- **Name:** ``lighting_garage_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Holiday Lighting: Present**

Whether there is holiday lighting.

- **Name:** ``holiday_lighting_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**holiday_lighting_daily_kwh**



- **Name:** ``holiday_lighting_daily_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**holiday_lighting_period**



- **Name:** ``holiday_lighting_period``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Dehumidifier: Type**

The type of dehumidifier.

- **Name:** ``dehumidifier_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `portable`, `whole-home`

<br/>

**Dehumidifier: Efficiency Type**

The efficiency type of dehumidifier.

- **Name:** ``dehumidifier_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `EnergyFactor`, `IntegratedEnergyFactor`

<br/>

**Dehumidifier: Efficiency**

The efficiency of the dehumidifier.

- **Name:** ``dehumidifier_efficiency``
- **Type:** ``Double``

- **Units:** ``liters/kWh``

- **Required:** ``true``

<br/>

**Dehumidifier: Capacity**

The capacity (water removal rate) of the dehumidifier.

- **Name:** ``dehumidifier_capacity``
- **Type:** ``Double``

- **Units:** ``pint/day``

- **Required:** ``true``

<br/>

**Dehumidifier: Relative Humidity Setpoint**

The relative humidity setpoint of the dehumidifier.

- **Name:** ``dehumidifier_rh_setpoint``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Dehumidifier: Fraction Dehumidification Load Served**

The dehumidification load served fraction of the dehumidifier.

- **Name:** ``dehumidifier_fraction_dehumidification_load_served``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``true``

<br/>

**Clothes Washer: Present**

Whether there is a clothes washer present.

- **Name:** ``clothes_washer_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**clothes_washer_location**



- **Name:** ``clothes_washer_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Clothes Washer: Efficiency Type**

The efficiency type of the clothes washer.

- **Name:** ``clothes_washer_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `ModifiedEnergyFactor`, `IntegratedModifiedEnergyFactor`

<br/>

**clothes_washer_efficiency**



- **Name:** ``clothes_washer_efficiency``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**clothes_washer_rated_annual_kwh**



- **Name:** ``clothes_washer_rated_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**clothes_washer_label_electric_rate**



- **Name:** ``clothes_washer_label_electric_rate``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**clothes_washer_label_gas_rate**



- **Name:** ``clothes_washer_label_gas_rate``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**clothes_washer_label_annual_gas_cost**



- **Name:** ``clothes_washer_label_annual_gas_cost``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**clothes_washer_label_usage**



- **Name:** ``clothes_washer_label_usage``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**clothes_washer_capacity**



- **Name:** ``clothes_washer_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**clothes_washer_usage_multiplier**



- **Name:** ``clothes_washer_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Clothes Dryer: Present**

Whether there is a clothes dryer present.

- **Name:** ``clothes_dryer_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**clothes_dryer_location**



- **Name:** ``clothes_dryer_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Clothes Dryer: Fuel Type**

Type of fuel used by the clothes dryer.

- **Name:** ``clothes_dryer_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `coal`

<br/>

**Clothes Dryer: Efficiency Type**

The efficiency type of the clothes dryer.

- **Name:** ``clothes_dryer_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `EnergyFactor`, `CombinedEnergyFactor`

<br/>

**clothes_dryer_efficiency**



- **Name:** ``clothes_dryer_efficiency``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**clothes_dryer_vented_flow_rate**



- **Name:** ``clothes_dryer_vented_flow_rate``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**clothes_dryer_usage_multiplier**



- **Name:** ``clothes_dryer_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Dishwasher: Present**

Whether there is a dishwasher present.

- **Name:** ``dishwasher_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**dishwasher_location**



- **Name:** ``dishwasher_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Dishwasher: Efficiency Type**

The efficiency type of dishwasher.

- **Name:** ``dishwasher_efficiency_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `RatedAnnualkWh`, `EnergyFactor`

<br/>

**dishwasher_efficiency**



- **Name:** ``dishwasher_efficiency``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**dishwasher_label_electric_rate**



- **Name:** ``dishwasher_label_electric_rate``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**dishwasher_label_gas_rate**



- **Name:** ``dishwasher_label_gas_rate``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**dishwasher_label_annual_gas_cost**



- **Name:** ``dishwasher_label_annual_gas_cost``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**dishwasher_label_usage**



- **Name:** ``dishwasher_label_usage``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**dishwasher_place_setting_capacity**



- **Name:** ``dishwasher_place_setting_capacity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**dishwasher_usage_multiplier**



- **Name:** ``dishwasher_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Refrigerator: Present**

Whether there is a refrigerator present.

- **Name:** ``refrigerator_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**refrigerator_location**



- **Name:** ``refrigerator_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**refrigerator_rated_annual_kwh**



- **Name:** ``refrigerator_rated_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**refrigerator_usage_multiplier**



- **Name:** ``refrigerator_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Extra Refrigerator: Present**

Whether there is an extra refrigerator present.

- **Name:** ``extra_refrigerator_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**extra_refrigerator_location**



- **Name:** ``extra_refrigerator_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**extra_refrigerator_rated_annual_kwh**



- **Name:** ``extra_refrigerator_rated_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**extra_refrigerator_usage_multiplier**



- **Name:** ``extra_refrigerator_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Freezer: Present**

Whether there is a freezer present.

- **Name:** ``freezer_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**freezer_location**



- **Name:** ``freezer_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**freezer_rated_annual_kwh**



- **Name:** ``freezer_rated_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**freezer_usage_multiplier**



- **Name:** ``freezer_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Cooking Range/Oven: Present**

Whether there is a cooking range/oven present.

- **Name:** ``cooking_range_oven_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**cooking_range_oven_location**



- **Name:** ``cooking_range_oven_location``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Cooking Range/Oven: Fuel Type**

Type of fuel used by the cooking range/oven.

- **Name:** ``cooking_range_oven_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `electricity`, `natural gas`, `fuel oil`, `propane`, `wood`, `coal`

<br/>

**cooking_range_oven_is_induction**



- **Name:** ``cooking_range_oven_is_induction``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**cooking_range_oven_is_convection**



- **Name:** ``cooking_range_oven_is_convection``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**cooking_range_oven_usage_multiplier**



- **Name:** ``cooking_range_oven_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Ceiling Fan: Present**

Whether there are any ceiling fans.

- **Name:** ``ceiling_fan_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**ceiling_fan_efficiency**



- **Name:** ``ceiling_fan_efficiency``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**ceiling_fan_quantity**



- **Name:** ``ceiling_fan_quantity``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**ceiling_fan_cooling_setpoint_temp_offset**



- **Name:** ``ceiling_fan_cooling_setpoint_temp_offset``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Television Present**

Whether there are televisions.

- **Name:** ``misc_plug_loads_television_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**misc_plug_loads_other_annual_kwh**



- **Name:** ``misc_plug_loads_other_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**misc_plug_loads_other_frac_sensible**



- **Name:** ``misc_plug_loads_other_frac_sensible``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**misc_plug_loads_other_frac_latent**



- **Name:** ``misc_plug_loads_other_frac_latent``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**misc_plug_loads_other_usage_multiplier**



- **Name:** ``misc_plug_loads_other_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Well Pump Present**

Whether there is a well pump.

- **Name:** ``misc_plug_loads_well_pump_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**misc_plug_loads_well_pump_annual_kwh**



- **Name:** ``misc_plug_loads_well_pump_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**misc_plug_loads_well_pump_usage_multiplier**



- **Name:** ``misc_plug_loads_well_pump_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Misc Plug Loads: Vehicle Present**

Whether there is an electric vehicle.

- **Name:** ``misc_plug_loads_vehicle_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**misc_plug_loads_vehicle_annual_kwh**



- **Name:** ``misc_plug_loads_vehicle_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**misc_plug_loads_vehicle_usage_multiplier**



- **Name:** ``misc_plug_loads_vehicle_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Grill Present**

Whether there is a fuel loads grill.

- **Name:** ``misc_fuel_loads_grill_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Misc Fuel Loads: Grill Fuel Type**

The fuel type of the fuel loads grill.

- **Name:** ``misc_fuel_loads_grill_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`

<br/>

**misc_fuel_loads_grill_annual_therm**



- **Name:** ``misc_fuel_loads_grill_annual_therm``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**misc_fuel_loads_grill_usage_multiplier**



- **Name:** ``misc_fuel_loads_grill_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Lighting Present**

Whether there is fuel loads lighting.

- **Name:** ``misc_fuel_loads_lighting_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Misc Fuel Loads: Lighting Fuel Type**

The fuel type of the fuel loads lighting.

- **Name:** ``misc_fuel_loads_lighting_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`

<br/>

**misc_fuel_loads_lighting_annual_therm**



- **Name:** ``misc_fuel_loads_lighting_annual_therm``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**misc_fuel_loads_lighting_usage_multiplier**



- **Name:** ``misc_fuel_loads_lighting_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Misc Fuel Loads: Fireplace Present**

Whether there is fuel loads fireplace.

- **Name:** ``misc_fuel_loads_fireplace_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Misc Fuel Loads: Fireplace Fuel Type**

The fuel type of the fuel loads fireplace.

- **Name:** ``misc_fuel_loads_fireplace_fuel_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `natural gas`, `fuel oil`, `propane`, `wood`, `wood pellets`

<br/>

**misc_fuel_loads_fireplace_annual_therm**



- **Name:** ``misc_fuel_loads_fireplace_annual_therm``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**misc_fuel_loads_fireplace_frac_sensible**



- **Name:** ``misc_fuel_loads_fireplace_frac_sensible``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**misc_fuel_loads_fireplace_frac_latent**



- **Name:** ``misc_fuel_loads_fireplace_frac_latent``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**misc_fuel_loads_fireplace_usage_multiplier**



- **Name:** ``misc_fuel_loads_fireplace_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Pool: Present**

Whether there is a pool.

- **Name:** ``pool_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**pool_pump_annual_kwh**



- **Name:** ``pool_pump_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**pool_pump_usage_multiplier**



- **Name:** ``pool_pump_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Pool: Heater Type**

The type of pool heater. Use 'none' if there is no pool heater.

- **Name:** ``pool_heater_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `electric resistance`, `gas fired`, `heat pump`

<br/>

**pool_heater_annual_kwh**



- **Name:** ``pool_heater_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**pool_heater_annual_therm**



- **Name:** ``pool_heater_annual_therm``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**pool_heater_usage_multiplier**



- **Name:** ``pool_heater_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Permanent Spa: Present**

Whether there is a permanent spa.

- **Name:** ``permanent_spa_present``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**permanent_spa_pump_annual_kwh**



- **Name:** ``permanent_spa_pump_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**permanent_spa_pump_usage_multiplier**



- **Name:** ``permanent_spa_pump_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Permanent Spa: Heater Type**

The type of permanent spa heater. Use 'none' if there is no permanent spa heater.

- **Name:** ``permanent_spa_heater_type``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `none`, `electric resistance`, `gas fired`, `heat pump`

<br/>

**permanent_spa_heater_annual_kwh**



- **Name:** ``permanent_spa_heater_annual_kwh``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**permanent_spa_heater_annual_therm**



- **Name:** ``permanent_spa_heater_annual_therm``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**permanent_spa_heater_usage_multiplier**



- **Name:** ``permanent_spa_heater_usage_multiplier``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_scenario_names**



- **Name:** ``emissions_scenario_names``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_types**



- **Name:** ``emissions_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_electricity_units**



- **Name:** ``emissions_electricity_units``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_electricity_values_or_filepaths**



- **Name:** ``emissions_electricity_values_or_filepaths``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_electricity_number_of_header_rows**



- **Name:** ``emissions_electricity_number_of_header_rows``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_electricity_column_numbers**



- **Name:** ``emissions_electricity_column_numbers``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_fossil_fuel_units**



- **Name:** ``emissions_fossil_fuel_units``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_natural_gas_values**



- **Name:** ``emissions_natural_gas_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_propane_values**



- **Name:** ``emissions_propane_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_fuel_oil_values**



- **Name:** ``emissions_fuel_oil_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_coal_values**



- **Name:** ``emissions_coal_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_wood_values**



- **Name:** ``emissions_wood_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**emissions_wood_pellets_values**



- **Name:** ``emissions_wood_pellets_values``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_scenario_names**



- **Name:** ``utility_bill_scenario_names``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_electricity_filepaths**



- **Name:** ``utility_bill_electricity_filepaths``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_electricity_fixed_charges**



- **Name:** ``utility_bill_electricity_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_natural_gas_fixed_charges**



- **Name:** ``utility_bill_natural_gas_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_propane_fixed_charges**



- **Name:** ``utility_bill_propane_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_fuel_oil_fixed_charges**



- **Name:** ``utility_bill_fuel_oil_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_coal_fixed_charges**



- **Name:** ``utility_bill_coal_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_wood_fixed_charges**



- **Name:** ``utility_bill_wood_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_wood_pellets_fixed_charges**



- **Name:** ``utility_bill_wood_pellets_fixed_charges``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_electricity_marginal_rates**



- **Name:** ``utility_bill_electricity_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_natural_gas_marginal_rates**



- **Name:** ``utility_bill_natural_gas_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_propane_marginal_rates**



- **Name:** ``utility_bill_propane_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_fuel_oil_marginal_rates**



- **Name:** ``utility_bill_fuel_oil_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_coal_marginal_rates**



- **Name:** ``utility_bill_coal_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_wood_marginal_rates**



- **Name:** ``utility_bill_wood_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_wood_pellets_marginal_rates**



- **Name:** ``utility_bill_wood_pellets_marginal_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_pv_compensation_types**



- **Name:** ``utility_bill_pv_compensation_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_pv_net_metering_annual_excess_sellback_rate_types**



- **Name:** ``utility_bill_pv_net_metering_annual_excess_sellback_rate_types``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_pv_net_metering_annual_excess_sellback_rates**



- **Name:** ``utility_bill_pv_net_metering_annual_excess_sellback_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_pv_feed_in_tariff_rates**



- **Name:** ``utility_bill_pv_feed_in_tariff_rates``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_pv_monthly_grid_connection_fee_units**



- **Name:** ``utility_bill_pv_monthly_grid_connection_fee_units``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**utility_bill_pv_monthly_grid_connection_fees**



- **Name:** ``utility_bill_pv_monthly_grid_connection_fees``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**additional_properties**



- **Name:** ``additional_properties``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**combine_like_surfaces**



- **Name:** ``combine_like_surfaces``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**apply_defaults**



- **Name:** ``apply_defaults``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**apply_validation**



- **Name:** ``apply_validation``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Schedules: Column Names**

A comma-separated list of the column names to generate. If not provided, defaults to all columns. Possible column names are: occupants, lighting_interior, lighting_garage, cooking_range, dishwasher, clothes_washer, clothes_dryer, ceiling_fan, plug_loads_other, plug_loads_tv, hot_water_dishwasher, hot_water_clothes_washer, hot_water_fixtures.

- **Name:** ``schedules_column_names``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Schedules: Random Seed**

This numeric field is the seed for the random number generator. Only applies if the schedules type is 'stochastic'.

- **Name:** ``schedules_random_seed``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``false``

<br/>

**Geometry: Unit Conditioned Floor Area Bin**

E.g., '2000-2499'.

- **Name:** ``geometry_unit_cfa_bin``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Geometry: Unit Conditioned Floor Area**

E.g., '2000' or 'auto'.

- **Name:** ``geometry_unit_cfa``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Building Construction: Vintage**

The building vintage, used for informational purposes only.

- **Name:** ``vintage``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Building Construction: Exterior Finish R-Value**

R-value of the exterior finish.

- **Name:** ``exterior_finish_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Geometry: Unit Level**

The level of the unit. This is required for apartment units.

- **Name:** ``geometry_unit_level``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `Bottom`, `Middle`, `Top`

<br/>

**Geometry: Unit Horizontal Location**

The horizontal location of the unit when viewing the front of the building. This is required for single-family attached and apartment units.

- **Name:** ``geometry_unit_horizontal_location``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `None`, `Left`, `Middle`, `Right`

<br/>

**Geometry: Number of Floors Above Grade**

The number of floors above grade (in the unit if single-family detached or single-family attached, and in the building if apartment unit). Conditioned attics are included.

- **Name:** ``geometry_num_floors_above_grade``
- **Type:** ``Integer``

- **Units:** ``#``

- **Required:** ``true``

<br/>

**Geometry: Corridor Position**

The position of the corridor. Only applies to single-family attached and apartment units. Exterior corridors are shaded, but not enclosed. Interior corridors are enclosed and conditioned.

- **Name:** ``geometry_corridor_position``
- **Type:** ``Choice``

- **Required:** ``true``

- **Choices:** `Double-Loaded Interior`, `Double Exterior`, `Single Exterior (Front)`, `None`

<br/>

**Geometry: Corridor Width**

The width of the corridor. Only applies to apartment units.

- **Name:** ``geometry_corridor_width``
- **Type:** ``Double``

- **Units:** ``ft``

- **Required:** ``true``

<br/>

**Wall: Continuous Exterior Insulation Nominal R-value**

Nominal R-value for the wall continuous exterior insulation.

- **Name:** ``wall_continuous_exterior_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``false``

<br/>

**Ceiling: Insulation Nominal R-value**

Nominal R-value for the ceiling (attic floor).

- **Name:** ``ceiling_insulation_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Rim Joist: Continuous Exterior Insulation Nominal R-value**

Nominal R-value for the rim joist continuous exterior insulation. Only applies to basements/crawlspaces.

- **Name:** ``rim_joist_continuous_exterior_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Rim Joist: Continuous Interior Insulation Nominal R-value**

Nominal R-value for the rim joist continuous interior insulation that runs parallel to floor joists. Only applies to basements/crawlspaces.

- **Name:** ``rim_joist_continuous_interior_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Rim Joist: Interior Assembly R-value**

Assembly R-value for the rim joist assembly interior insulation that runs perpendicular to floor joists. Only applies to basements/crawlspaces.

- **Name:** ``rim_joist_assembly_interior_r``
- **Type:** ``Double``

- **Units:** ``h-ft^2-R/Btu``

- **Required:** ``true``

<br/>

**Air Leakage: Value Reduction**

Reduction (%) on the air exchange rate value.

- **Name:** ``air_leakage_percent_reduction``
- **Type:** ``Double``

- **Required:** ``false``

<br/>

**Plug Loads: Other Usage Multiplier 2**

Additional multiplier on the other energy usage that can reflect, e.g., high/low usage occupants.

- **Name:** ``misc_plug_loads_other_2_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Plug Loads: Well Pump Usage Multiplier 2**

Additional multiplier on the well pump energy usage that can reflect, e.g., high/low usage occupants.

- **Name:** ``misc_plug_loads_well_pump_2_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Plug Loads: Vehicle Usage Multiplier 2**

Additional multiplier on the electric vehicle energy usage that can reflect, e.g., high/low usage occupants.

- **Name:** ``misc_plug_loads_vehicle_2_usage_multiplier``
- **Type:** ``Double``

- **Required:** ``true``

<br/>

**Heating Setpoint: Weekday Temperature**

Specify the weekday heating setpoint temperature.

- **Name:** ``hvac_control_heating_weekday_setpoint_temp``
- **Type:** ``Double``

- **Units:** ``deg-F``

- **Required:** ``true``

<br/>

**Heating Setpoint: Weekend Temperature**

Specify the weekend heating setpoint temperature.

- **Name:** ``hvac_control_heating_weekend_setpoint_temp``
- **Type:** ``Double``

- **Units:** ``deg-F``

- **Required:** ``true``

<br/>

**Heating Setpoint: Weekday Offset Magnitude**

Specify the weekday heating offset magnitude.

- **Name:** ``hvac_control_heating_weekday_setpoint_offset_magnitude``
- **Type:** ``Double``

- **Units:** ``deg-F``

- **Required:** ``true``

<br/>

**Heating Setpoint: Weekend Offset Magnitude**

Specify the weekend heating offset magnitude.

- **Name:** ``hvac_control_heating_weekend_setpoint_offset_magnitude``
- **Type:** ``Double``

- **Units:** ``deg-F``

- **Required:** ``true``

<br/>

**Heating Setpoint: Weekday Schedule**

Specify the 24-hour comma-separated weekday heating schedule of 0s and 1s.

- **Name:** ``hvac_control_heating_weekday_setpoint_schedule``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Heating Setpoint: Weekend Schedule**

Specify the 24-hour comma-separated weekend heating schedule of 0s and 1s.

- **Name:** ``hvac_control_heating_weekend_setpoint_schedule``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Use Auto Heating Season**

Specifies whether to automatically define the heating season based on the weather file.

- **Name:** ``use_auto_heating_season``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Cooling Setpoint: Weekday Temperature**

Specify the weekday cooling setpoint temperature.

- **Name:** ``hvac_control_cooling_weekday_setpoint_temp``
- **Type:** ``Double``

- **Units:** ``deg-F``

- **Required:** ``true``

<br/>

**Cooling Setpoint: Weekend Temperature**

Specify the weekend cooling setpoint temperature.

- **Name:** ``hvac_control_cooling_weekend_setpoint_temp``
- **Type:** ``Double``

- **Units:** ``deg-F``

- **Required:** ``true``

<br/>

**Cooling Setpoint: Weekday Offset Magnitude**

Specify the weekday cooling offset magnitude.

- **Name:** ``hvac_control_cooling_weekday_setpoint_offset_magnitude``
- **Type:** ``Double``

- **Units:** ``deg-F``

- **Required:** ``true``

<br/>

**Cooling Setpoint: Weekend Offset Magnitude**

Specify the weekend cooling offset magnitude.

- **Name:** ``hvac_control_cooling_weekend_setpoint_offset_magnitude``
- **Type:** ``Double``

- **Units:** ``deg-F``

- **Required:** ``true``

<br/>

**Cooling Setpoint: Weekday Schedule**

Specify the 24-hour comma-separated weekday cooling schedule of 0s and 1s.

- **Name:** ``hvac_control_cooling_weekday_setpoint_schedule``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Cooling Setpoint: Weekend Schedule**

Specify the 24-hour comma-separated weekend cooling schedule of 0s and 1s.

- **Name:** ``hvac_control_cooling_weekend_setpoint_schedule``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Use Auto Cooling Season**

Specifies whether to automatically define the cooling season based on the weather file.

- **Name:** ``use_auto_cooling_season``
- **Type:** ``Boolean``

- **Required:** ``true``

<br/>

**Heating System: Has Flue or Chimney**

Whether the heating system has a flue or chimney.

- **Name:** ``heating_system_has_flue_or_chimney``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Heating System 2: Has Flue or Chimney**

Whether the second heating system has a flue or chimney.

- **Name:** ``heating_system_2_has_flue_or_chimney``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Water Heater: Has Flue or Chimney**

Whether the water heater has a flue or chimney.

- **Name:** ``water_heater_has_flue_or_chimney``
- **Type:** ``String``

- **Required:** ``true``

<br/>

**Heating System: Rated CFM Per Ton**



- **Name:** ``heating_system_rated_cfm_per_ton``
- **Type:** ``Double``

- **Units:** ``cfm/ton``

- **Required:** ``false``

<br/>

**Heating System: Actual CFM Per Ton**



- **Name:** ``heating_system_actual_cfm_per_ton``
- **Type:** ``Double``

- **Units:** ``cfm/ton``

- **Required:** ``false``

<br/>

**Cooling System: Rated CFM Per Ton**



- **Name:** ``cooling_system_rated_cfm_per_ton``
- **Type:** ``Double``

- **Units:** ``cfm/ton``

- **Required:** ``false``

<br/>

**Cooling System: Actual CFM Per Ton**



- **Name:** ``cooling_system_actual_cfm_per_ton``
- **Type:** ``Double``

- **Units:** ``cfm/ton``

- **Required:** ``false``

<br/>

**Cooling System: Fraction of Manufacturer Recommended Charge**



- **Name:** ``cooling_system_frac_manufacturer_charge``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Heat Pump: Rated CFM Per Ton**



- **Name:** ``heat_pump_rated_cfm_per_ton``
- **Type:** ``Double``

- **Units:** ``cfm/ton``

- **Required:** ``false``

<br/>

**Heat Pump: Actual CFM Per Ton**



- **Name:** ``heat_pump_actual_cfm_per_ton``
- **Type:** ``Double``

- **Units:** ``cfm/ton``

- **Required:** ``false``

<br/>

**Heat Pump: Fraction of Manufacturer Recommended Charge**



- **Name:** ``heat_pump_frac_manufacturer_charge``
- **Type:** ``Double``

- **Units:** ``Frac``

- **Required:** ``false``

<br/>

**Heat Pump: Backup Use Existing System**

Whether the heat pump uses the existing system as backup.

- **Name:** ``heat_pump_backup_use_existing_system``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>





