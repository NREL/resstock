# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require_relative "resources/geometry"
require_relative "resources/schedules"
require_relative "resources/waterheater"
require_relative "resources/constants"
require_relative "resources/location"

# start the measure
class BuildResidentialHPXML < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "HPXML Exporter"
  end

  # human readable description
  def description
    return "Exports residential modeling arguments to HPXML file"
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_path", true)
    arg.setDisplayName("HPXML File Path")
    arg.setDescription("Absolute/relative path of the HPXML file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("schedules_output_path", true)
    arg.setDisplayName("Schedules Output File Path")
    arg.setDescription("Absolute (or relative) path of the output schedules file.")
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("weather_station_epw_filename", true)
    arg.setDisplayName("EnergyPlus Weather (EPW) Filename")
    arg.setDescription("Name of the EPW file.")
    arg.setDefaultValue("USA_CO_Denver.Intl.AP.725650_TMY3.epw")
    args << arg

    unit_type_choices = OpenStudio::StringVector.new
    unit_type_choices << "single-family detached"
    unit_type_choices << "single-family attached"
    unit_type_choices << "multifamily"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("unit_type", unit_type_choices, true)
    arg.setDisplayName("Geometry: Unit Type")
    arg.setDescription("The type of unit.")
    arg.setDefaultValue("single-family detached")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("unit_multiplier", true)
    arg.setDisplayName("Geometry: Unit Multiplier")
    arg.setUnits("#")
    arg.setDescription("The number of actual units this single unit represents.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("cfa", true)
    arg.setDisplayName("Geometry: Conditioned Floor Area")
    arg.setUnits("ft^2")
    arg.setDescription("The total floor area of the conditioned space (including any conditioned basement floor area).")
    arg.setDefaultValue(2000.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_height", true)
    arg.setDisplayName("Geometry: Wall Height (Per Floor)")
    arg.setUnits("ft")
    arg.setDescription("The height of the living space (and garage) walls.")
    arg.setDefaultValue(8.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("num_floors", true)
    arg.setDisplayName("Geometry: Number of Floors")
    arg.setUnits("#")
    arg.setDescription("The number of floors above grade.")
    arg.setDefaultValue(2)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("aspect_ratio", true)
    arg.setDisplayName("Geometry: Aspect Ratio")
    arg.setUnits("FB/LR")
    arg.setDescription("The ratio of the front/back wall length to the left/right wall length, excluding any protruding garage wall area.")
    arg.setDefaultValue(2.0)
    args << arg

    level_choices = OpenStudio::StringVector.new
    level_choices << "Bottom"
    level_choices << "Middle"
    level_choices << "Top"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("level", level_choices, true)
    arg.setDisplayName("Geometry: Level")
    arg.setDescription("The level of the unit.")
    arg.setDefaultValue("Bottom")
    args << arg

    horizontal_location_choices = OpenStudio::StringVector.new
    horizontal_location_choices << "Left"
    horizontal_location_choices << "Middle"
    horizontal_location_choices << "Right"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("horizontal_location", horizontal_location_choices, true)
    arg.setDisplayName("Geometry: Horizontal Location")
    arg.setDescription("The horizontal location of the unit when viewing the front of the building.")
    arg.setDefaultValue("Left")
    args << arg

    corridor_position_choices = OpenStudio::StringVector.new
    corridor_position_choices << "Double-Loaded Interior"
    corridor_position_choices << "Single Exterior (Front)"
    corridor_position_choices << "Double Exterior"
    corridor_position_choices << "None"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("corridor_position", corridor_position_choices, true)
    arg.setDisplayName("Geometry: Corridor Position")
    arg.setDescription("The position of the corridor.")
    arg.setDefaultValue("Double-Loaded Interior")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("corridor_width", true)
    arg.setDisplayName("Geometry: Corridor Width")
    arg.setUnits("ft")
    arg.setDescription("The width of the corridor.")
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("inset_width", true)
    arg.setDisplayName("Geometry: Inset Width")
    arg.setUnits("ft")
    arg.setDescription("The width of the inset.")
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("inset_depth", true)
    arg.setDisplayName("Geometry: Inset Depth")
    arg.setUnits("ft")
    arg.setDescription("The depth of the inset.")
    arg.setDefaultValue(0.0)
    args << arg

    inset_position_choices = OpenStudio::StringVector.new
    inset_position_choices << "Right"
    inset_position_choices << "Left"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("inset_position", inset_position_choices, true)
    arg.setDisplayName("Geometry: Inset Position")
    arg.setDescription("The position of the inset.")
    arg.setDefaultValue("Right")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("balcony_depth", true)
    arg.setDisplayName("Geometry: Balcony Depth")
    arg.setUnits("ft")
    arg.setDescription("The depth of the balcony.")
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("garage_width", true)
    arg.setDisplayName("Geometry: Garage Width")
    arg.setUnits("ft")
    arg.setDescription("The width of the garage.")
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("garage_depth", true)
    arg.setDisplayName("Geometry: Garage Depth")
    arg.setUnits("ft")
    arg.setDescription("The depth of the garage.")
    arg.setDefaultValue(20.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("garage_protrusion", true)
    arg.setDisplayName("Geometry: Garage Protrusion")
    arg.setUnits("frac")
    arg.setDescription("The fraction of the garage that is protruding from the living space.")
    arg.setDefaultValue(0.0)
    args << arg

    garage_position_choices = OpenStudio::StringVector.new
    garage_position_choices << "Right"
    garage_position_choices << "Left"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("garage_position", garage_position_choices, true)
    arg.setDisplayName("Geometry: Garage Position")
    arg.setDescription("The position of the garage.")
    arg.setDefaultValue("Right")
    args << arg

    foundation_type_choices = OpenStudio::StringVector.new
    foundation_type_choices << "slab"
    foundation_type_choices << "crawlspace - vented"
    foundation_type_choices << "crawlspace - unvented"
    foundation_type_choices << "basement - unconditioned"
    foundation_type_choices << "basement - conditioned"
    foundation_type_choices << "ambient"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("foundation_type", foundation_type_choices, true)
    arg.setDisplayName("Geometry: Foundation Type")
    arg.setDescription("The foundation type of the building.")
    arg.setDefaultValue("slab")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("foundation_height", true)
    arg.setDisplayName("Geometry: Foundation Height")
    arg.setUnits("ft")
    arg.setDescription("The height of the foundation (e.g., 3ft for crawlspace, 8ft for basement).")
    arg.setDefaultValue(3.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("foundation_ceiling_r", true)
    arg.setDisplayName("Foundation: Ceiling Insulation Assembly R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the overall R-value of the assembly.")
    arg.setDefaultValue(30)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("foundation_wall_r", true)
    arg.setDisplayName("Foundation: Wall Insulation R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the overall R-value of the assembly.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("foundation_wall_distance_to_top", true)
    arg.setDisplayName("Foundation: Wall Insulation Distance To Top")
    arg.setUnits("ft")
    arg.setDescription("The distance to the top of the foundation wall insulation.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("foundation_wall_distance_to_bottom", true)
    arg.setDisplayName("Foundation: Wall Insulation Distance To Bottom")
    arg.setUnits("ft")
    arg.setDescription("The distance to the bottom of the foundation wall insulation.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("foundation_wall_depth_below_grade", true)
    arg.setDisplayName("Foundation: Wall Depth Below Grade")
    arg.setUnits("ft")
    arg.setDescription("The depth below grade of the foundation wall.")
    arg.setDefaultValue(3.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("slab_perimeter_r", true)
    arg.setDisplayName("Slab: Perimeter Insulation Nominal R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the nominal R-value of the perimeter insulation.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("slab_perimeter_depth", true)
    arg.setDisplayName("Slab: Perimeter Insulation Depth")
    arg.setUnits("ft")
    arg.setDescription("Refers to the depth of the perimeter insulation.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("slab_under_r", true)
    arg.setDisplayName("Slab: Under Slab Insulation Nominal R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the nominal R-value of the under slab insulation.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("slab_under_width", true)
    arg.setDisplayName("Slab: Under Slab Insulation Width")
    arg.setUnits("ft")
    arg.setDescription("Refers to the width of the under slab insulation. Enter 999 to specify that the under slab insulation spans the entire slab.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("carpet_fraction", true)
    arg.setDisplayName("Carpet: Fraction")
    arg.setUnits("Frac")
    arg.setDescription("Fraction of the carpet.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("carpet_r_value", true)
    arg.setDisplayName("Carpet: R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("R-value of the carpet.")
    arg.setDefaultValue(0)
    args << arg

    attic_type_choices = OpenStudio::StringVector.new
    attic_type_choices << "attic - vented"
    attic_type_choices << "attic - unvented"
    attic_type_choices << "attic - conditioned"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("attic_type", attic_type_choices, true)
    arg.setDisplayName("Geometry: Attic Type")
    arg.setDescription("The attic type of the building. Ignored if the building has a flat roof.")
    arg.setDefaultValue("attic - vented")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("attic_floor_conditioned_r", true)
    arg.setDisplayName("Attic: Floor (Adjacent To Conditioned) Insulation Assembly R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the overall R-value of the assembly.")
    arg.setDefaultValue(30)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("attic_floor_unconditioned_r", true)
    arg.setDisplayName("Attic: Floor (Adjacent To Unconditioned) Insulation Assembly R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the overall R-value of the assembly.")
    arg.setDefaultValue(2.1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("attic_ceiling_r", true)
    arg.setDisplayName("Attic: Ceiling Insulation Assembly R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the overall R-value of the assembly.")
    arg.setDefaultValue(2.3)
    args << arg

    roof_type_choices = OpenStudio::StringVector.new
    roof_type_choices << "gable"
    roof_type_choices << "hip"
    roof_type_choices << "flat"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("roof_type", roof_type_choices, true)
    arg.setDisplayName("Geometry: Roof Type")
    arg.setDescription("The roof type of the building.")
    arg.setDefaultValue("gable")
    args << arg

    roof_pitch_choices = OpenStudio::StringVector.new
    roof_pitch_choices << "1:12"
    roof_pitch_choices << "2:12"
    roof_pitch_choices << "3:12"
    roof_pitch_choices << "4:12"
    roof_pitch_choices << "5:12"
    roof_pitch_choices << "6:12"
    roof_pitch_choices << "7:12"
    roof_pitch_choices << "8:12"
    roof_pitch_choices << "9:12"
    roof_pitch_choices << "10:12"
    roof_pitch_choices << "11:12"
    roof_pitch_choices << "12:12"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("roof_pitch", roof_pitch_choices, true)
    arg.setDisplayName("Geometry: Roof Pitch")
    arg.setDescription("The roof pitch of the attic. Ignored if the building has a flat roof.")
    arg.setDefaultValue("6:12")
    args << arg

    roof_structure_choices = OpenStudio::StringVector.new
    roof_structure_choices << "truss, cantilever"
    roof_structure_choices << "rafter"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("roof_structure", roof_structure_choices, true)
    arg.setDisplayName("Geometry: Roof Structure")
    arg.setDescription("The roof structure of the building.")
    arg.setDefaultValue("truss, cantilever")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("roof_ceiling_r", true)
    arg.setDisplayName("Roof: Ceiling Insulation Assembly R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the overall R-value of the assembly.")
    arg.setDefaultValue(2.3)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("roof_solar_absorptance", true)
    arg.setDisplayName("Roof: Solar Absorptance")
    arg.setDescription("The solar absorptance of the roof.")
    arg.setDefaultValue(0.7)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("roof_emittance", true)
    arg.setDisplayName("Roof: Emittance")
    arg.setDescription("The emittance of the roof.")
    arg.setDefaultValue(0.92)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("roof_radiant_barrier", true)
    arg.setDisplayName("Roof: Has Radiant Barrier")
    arg.setDescription("Specifies whether the attic has a radiant barrier.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("eaves_depth", true)
    arg.setDisplayName("Geometry: Eaves Depth")
    arg.setUnits("ft")
    arg.setDescription("The eaves depth of the roof.")
    arg.setDefaultValue(2.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("num_bedrooms", true)
    arg.setDisplayName("Geometry: Number of Bedrooms")
    arg.setDescription("Specify the number of bedrooms. Used to determine the energy usage of appliances and plug loads, hot water usage, mechanical ventilation rate, etc.")
    arg.setDefaultValue(3)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("num_bathrooms", true)
    arg.setDisplayName("Geometry: Number of Bathrooms")
    arg.setDescription("Specify the number of bathrooms.")
    arg.setDefaultValue(2)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("num_occupants", true)
    arg.setDisplayName("Geometry: Number of Occupants")
    arg.setDescription("Specify the number of occupants. A value of '#{Constants.Auto}' will calculate the average number of occupants from the number of bedrooms. Used to specify the internal gains from people only.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_front_distance", true)
    arg.setDisplayName("Neighbor: Front Distance")
    arg.setUnits("ft")
    arg.setDescription("The minimum distance between the simulated house and the neighboring house to the front (not including eaves). A value of zero indicates no neighbors.")
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_back_distance", true)
    arg.setDisplayName("Neighbor: Back Distance")
    arg.setUnits("ft")
    arg.setDescription("The minimum distance between the simulated house and the neighboring house to the back (not including eaves). A value of zero indicates no neighbors.")
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_left_distance", true)
    arg.setDisplayName("Neighbor: Left Distance")
    arg.setUnits("ft")
    arg.setDescription("The minimum distance between the simulated house and the neighboring house to the left (not including eaves). A value of zero indicates no neighbors.")
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_right_distance", true)
    arg.setDisplayName("Neighbor: Right Distance")
    arg.setUnits("ft")
    arg.setDescription("The minimum distance between the simulated house and the neighboring house to the right (not including eaves). A value of zero indicates no neighbors.")
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_front_height", true)
    arg.setDisplayName("Neighbor: Front Height")
    arg.setUnits("ft")
    arg.setDescription("The height of the front neighbor.")
    arg.setDefaultValue(12.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_back_height", true)
    arg.setDisplayName("Neighbor: Back Height")
    arg.setUnits("ft")
    arg.setDescription("The height of the back neighbor.")
    arg.setDefaultValue(12.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_left_height", true)
    arg.setDisplayName("Neighbor: Left Height")
    arg.setUnits("ft")
    arg.setDescription("The height of the left neighbor.")
    arg.setDefaultValue(12.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_right_height", true)
    arg.setDisplayName("Neighbor: Right Height")
    arg.setUnits("ft")
    arg.setDescription("The height of the right neighbor.")
    arg.setDefaultValue(12.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("orientation", true)
    arg.setDisplayName("Geometry: Azimuth")
    arg.setUnits("degrees")
    arg.setDescription("The house's azimuth is measured clockwise from due south when viewed from above (e.g., South=0, West=90, North=180, East=270).")
    arg.setDefaultValue(180.0)
    args << arg

    wall_type_choices = OpenStudio::StringVector.new
    wall_type_choices << "WoodStud"
    wall_type_choices << "ConcreteMasonryUnit"
    wall_type_choices << "DoubleWoodStud"
    wall_type_choices << "InsulatedConcreteForms"
    wall_type_choices << "LogWall"
    wall_type_choices << "StructurallyInsulatedPanel"
    wall_type_choices << "SolidConcrete"
    wall_type_choices << "SteelFrame"
    wall_type_choices << "Stone"
    wall_type_choices << "StrawBale"
    wall_type_choices << "StructuralBrick"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("wall_type", wall_type_choices, true)
    arg.setDisplayName("Walls: Type")
    arg.setDescription("The type of the exterior walls.")
    arg.setDefaultValue("WoodStud")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_conditioned_r", true)
    arg.setDisplayName("Walls: Cavity (Adjacent To Conditioned) Insulation Assembly R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the overall R-value of the assembly.")
    arg.setDefaultValue(13)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_unconditioned_r", true)
    arg.setDisplayName("Walls: Cavity (Adjacent To Unconditioned) Insulation Assembly R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the overall R-value of the assembly.")
    arg.setDefaultValue(4)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_solar_absorptance", true)
    arg.setDisplayName("Wall: Solar Absorptance")
    arg.setDescription("The solar absorptance of the exterior walls.")
    arg.setDefaultValue(0.7)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_emittance", true)
    arg.setDisplayName("Wall: Emittance")
    arg.setDescription("The emittance of the exterior walls.")
    arg.setDefaultValue(0.92)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("front_wwr", true)
    arg.setDisplayName("Windows: Front Window-to-Wall Ratio")
    arg.setDescription("The ratio of window area to wall area for the building's front facade. Enter 0 if specifying Front Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("back_wwr", true)
    arg.setDisplayName("Windows: Back Window-to-Wall Ratio")
    arg.setDescription("The ratio of window area to wall area for the building's back facade. Enter 0 if specifying Back Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("left_wwr", true)
    arg.setDisplayName("Windows: Left Window-to-Wall Ratio")
    arg.setDescription("The ratio of window area to wall area for the building's left facade. Enter 0 if specifying Left Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("right_wwr", true)
    arg.setDisplayName("Windows: Right Window-to-Wall Ratio")
    arg.setDescription("The ratio of window area to wall area for the building's right facade. Enter 0 if specifying Right Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("front_window_area", true)
    arg.setDisplayName("Windows: Front Window Area")
    arg.setDescription("The amount of window area on the building's front facade. Enter 0 if specifying Front Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("back_window_area", true)
    arg.setDisplayName("Windows: Back Window Area")
    arg.setDescription("The amount of window area on the building's back facade. Enter 0 if specifying Back Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("left_window_area", true)
    arg.setDisplayName("Windows: Left Window Area")
    arg.setDescription("The amount of window area on the building's left facade. Enter 0 if specifying Left Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("right_window_area", true)
    arg.setDisplayName("Windows: Right Window Area")
    arg.setDescription("The amount of window area on the building's right facade. Enter 0 if specifying Right Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("window_aspect_ratio", true)
    arg.setDisplayName("Windows: Aspect Ratio")
    arg.setDescription("Ratio of window height to width.")
    arg.setDefaultValue(1.333)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("window_ufactor", true)
    arg.setDisplayName("Windows: U-Factor")
    arg.setUnits("Btu/hr-ft^2-R")
    arg.setDescription("The heat transfer coefficient of the windows.")
    arg.setDefaultValue(0.37)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("window_shgc", true)
    arg.setDisplayName("Windows: SHGC")
    arg.setDescription("The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening, for windows.")
    arg.setDefaultValue(0.3)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("winter_shading_coefficient_front_facade", true)
    arg.setDisplayName("Interior Shading: Front Facade Winter Shading Coefficient")
    arg.setDescription("Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("summer_shading_coefficient_front_facade", true)
    arg.setDisplayName("Interior Shading: Front Facade Summer Shading Coefficient")
    arg.setDescription("Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("winter_shading_coefficient_back_facade", true)
    arg.setDisplayName("Interior Shading: Back Facade Winter Shading Coefficient")
    arg.setDescription("Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("summer_shading_coefficient_back_facade", true)
    arg.setDisplayName("Interior Shading: Back Facade Summer Shading Coefficient")
    arg.setDescription("Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("winter_shading_coefficient_left_facade", true)
    arg.setDisplayName("Interior Shading: Left Facade Winter Shading Coefficient")
    arg.setDescription("Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("summer_shading_coefficient_left_facade", true)
    arg.setDisplayName("Interior Shading: Left Facade Summer Shading Coefficient")
    arg.setDescription("Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("winter_shading_coefficient_right_facade", true)
    arg.setDisplayName("Interior Shading: Right Facade Winter Shading Coefficient")
    arg.setDescription("Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("summer_shading_coefficient_right_facade", true)
    arg.setDisplayName("Interior Shading: Right Facade Summer Shading Coefficient")
    arg.setDescription("Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("overhangs_front_facade", true)
    arg.setDisplayName("Overhang: Front Facade")
    arg.setDescription("Overhangs: Specifies the presence of overhangs for windows on the front facade.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("overhangs_back_facade", true)
    arg.setDisplayName("Overhang: Back Facade")
    arg.setDescription("Overhangs: Specifies the presence of overhangs for windows on the back facade.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("overhangs_left_facade", true)
    arg.setDisplayName("Overhang: Left Facade")
    arg.setDescription("Overhangs: Specifies the presence of overhangs for windows on the left facade.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("overhangs_right_facade", true)
    arg.setDisplayName("Overhang: Right Facade")
    arg.setDescription("Overhangs: Specifies the presence of overhangs for windows on the right facade.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("overhangs_depth", true)
    arg.setDisplayName("Overhangs: Depth")
    arg.setUnits("ft")
    arg.setDescription("Depth of the overhang. The distance from the wall surface in the direction normal to the wall surface.")
    arg.setDefaultValue(2.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("front_skylight_area", true)
    arg.setDisplayName("Skylights: Front Roof Area")
    arg.setDescription("The amount of skylight area on the building's front conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("back_skylight_area", true)
    arg.setDisplayName("Skylights: Back Roof Area")
    arg.setDescription("The amount of skylight area on the building's back conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("left_skylight_area", true)
    arg.setDisplayName("Skylights: Left Roof Area")
    arg.setDescription("The amount of skylight area on the building's left conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("right_skylight_area", true)
    arg.setDisplayName("Skylights: Right Roof Area")
    arg.setDescription("The amount of skylight area on the building's right conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("skylight_ufactor", true)
    arg.setDisplayName("Skylights: U-Factor")
    arg.setUnits("Btu/hr-ft^2-R")
    arg.setDescription("The heat transfer coefficient of the skylights.")
    arg.setDefaultValue(0.33)
    args << arg

    skylight_shgc = OpenStudio::Measure::OSArgument::makeDoubleArgument("skylight_shgc", true)
    skylight_shgc.setDisplayName("Skylights: SHGC")
    skylight_shgc.setDescription("The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening, for skylights.")
    skylight_shgc.setDefaultValue(0.45)
    args << skylight_shgc

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("door_area", true)
    arg.setDisplayName("Doors: Area")
    arg.setUnits("ft^2")
    arg.setDescription("The area of the opaque door(s).")
    arg.setDefaultValue(20.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("door_rvalue", true)
    arg.setDisplayName("Doors: R-value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Refers to the R-value of the doors adjacent to conditioned space.")
    arg.setDefaultValue(5.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("living_ach_50", true)
    arg.setDisplayName("Air Leakage: Above-Grade Living ACH50")
    arg.setUnits("1/hr")
    arg.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for above-grade living space (including conditioned attic).")
    arg.setDefaultValue(3)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("living_constant_ach_natural", true)
    arg.setDisplayName("Air Leakage: Above-Grade Living Constant ACH Natural")
    arg.setDescription("Air exchange rate, in constant natural Air Changes per Hour, for above-grade living space (including conditioned attic).")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("vented_crawlspace_sla", true)
    arg.setDisplayName("Air Leakage: Vented Crawlspace")
    arg.setDescription("Air exchange rate, in specific leakage area (SLA), for vented crawlspace.")
    arg.setDefaultValue(0.00677)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("shelter_coefficient", true)
    arg.setDisplayName("Air Leakage: Shelter Coefficient")
    arg.setUnits("Frac")
    arg.setDescription("The local shelter coefficient (AIM-2 infiltration model) accounts for nearby buildings, trees, and obstructions.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    heating_system_type_choices = OpenStudio::StringVector.new
    heating_system_type_choices << "none"
    heating_system_type_choices << "Furnace"
    heating_system_type_choices << "WallFurnace"
    heating_system_type_choices << "Boiler"
    heating_system_type_choices << "ElectricResistance"
    heating_system_type_choices << "Stove"
    heating_system_type_choices << "PortableHeater"
    heating_system_type_choices << "air-to-air"
    heating_system_type_choices << "mini-split"
    heating_system_type_choices << "ground-to-air"

    heating_system_fuel_choices = OpenStudio::StringVector.new
    heating_system_fuel_choices << "electricity"
    heating_system_fuel_choices << "natural gas"
    heating_system_fuel_choices << "fuel oil"
    heating_system_fuel_choices << "propane"
    heating_system_fuel_choices << "wood"

    cooling_system_type_choices = OpenStudio::StringVector.new
    cooling_system_type_choices << "none"
    cooling_system_type_choices << "central air conditioner"
    cooling_system_type_choices << "room air conditioner"
    cooling_system_type_choices << "evaporative cooler"
    cooling_system_type_choices << "air-to-air"
    cooling_system_type_choices << "mini-split"
    cooling_system_type_choices << "ground-to-air"

    cooling_system_fuel_choices = OpenStudio::StringVector.new
    cooling_system_fuel_choices << "electricity"

    heat_pump_backup_fuel_choices = OpenStudio::StringVector.new
    heat_pump_backup_fuel_choices << "none"
    heat_pump_backup_fuel_choices << "electricity"
    heat_pump_backup_fuel_choices << "natural gas"
    heat_pump_backup_fuel_choices << "fuel oil"
    heat_pump_backup_fuel_choices << "propane"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("heating_system_type", heating_system_type_choices, true)
    arg.setDisplayName("Heating System: Type")
    arg.setDescription("The type of the heating system.")
    arg.setDefaultValue("Furnace")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("heating_system_fuel", heating_system_fuel_choices, true)
    arg.setDisplayName("Heating System: Fuel Type")
    arg.setDescription("The fuel type of the heating system.")
    arg.setDefaultValue("natural gas")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("heating_system_heating_efficiency", true)
    arg.setDisplayName("Heating System: Rated Efficiency")
    arg.setDescription("The rated efficiency value of the heating system. AFUE for Furnace/WallFurnace/Boiler. Percent for ElectricResistance/Stove/PortableHeater. HSPF for air-to-air/mini-split. COP for ground-to-air.")
    arg.setDefaultValue(0.78)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("heating_system_heating_capacity", true)
    arg.setDisplayName("Heating System: Heating Capacity")
    arg.setDescription("The output heating capacity of the heating system. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits("Btu/hr")
    arg.setDefaultValue(Constants.SizingAuto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("heating_system_fraction_heat_load_served", true)
    arg.setDisplayName("Heating System: Fraction Heat Load Served")
    arg.setDescription("The heat load served fraction of the heating system.")
    arg.setUnits("Frac")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("heating_system_electric_auxiliary_energy", true)
    arg.setDisplayName("Heating System: Electric Auxiliary Energy")
    arg.setDescription("The electric auxiliary energy of the heating system.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("cooling_system_type", cooling_system_type_choices, true)
    arg.setDisplayName("Cooling System: Type")
    arg.setDescription("The type of the cooling system.")
    arg.setDefaultValue("central air conditioner")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("cooling_system_fuel", cooling_system_fuel_choices, true)
    arg.setDisplayName("Cooling System: Fuel Type")
    arg.setDescription("The fuel type of the cooling system.")
    arg.setDefaultValue("electricity")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("cooling_system_cooling_efficiency", true)
    arg.setDisplayName("Cooling System: Rated Efficiency")
    arg.setDescription("The rated efficiency value of the cooling system. SEER for central air conditioner/air-to-air/mini-split. EER for room air conditioner/ground-to-air. Ignored for evaporative cooler.")
    arg.setDefaultValue(13.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("cooling_system_cooling_capacity", true)
    arg.setDisplayName("Cooling System: Cooling Capacity")
    arg.setDescription("The output cooling capacity of the cooling system. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits("tons")
    arg.setDefaultValue(Constants.SizingAuto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("cooling_system_fraction_cool_load_served", true)
    arg.setDisplayName("Cooling System: Fraction Cool Load Served")
    arg.setDescription("The cool load served fraction of the cooling system.")
    arg.setUnits("Frac")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("heat_pump_backup_fuel", heat_pump_backup_fuel_choices, true)
    arg.setDisplayName("Heat Pump: Backup Fuel Type")
    arg.setDescription("The backup fuel type of the heat pump.")
    arg.setDefaultValue("none")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("heat_pump_backup_heating_efficiency", true)
    arg.setDisplayName("Heat Pump: Backup Rated Efficiency")
    arg.setDescription("The backup rated efficiency value of the heat pump. Percent for electricity fuel type. AFUE otherwise.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("heat_pump_backup_heating_capacity", true)
    arg.setDisplayName("Heat Pump: Backup Heating Capacity")
    arg.setDescription("The backup output heating capacity of the heat pump. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits("Btu/hr")
    arg.setDefaultValue(Constants.SizingAuto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("mini_split_is_ducted", true)
    arg.setDisplayName("Mini-Split: Is Ducted")
    arg.setDescription("Whether the mini-split heat pump is ducted or not.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("evap_cooler_is_ducted", true)
    arg.setDisplayName("Evaporative Cooler: Is Ducted")
    arg.setDescription("Whether the evaporative cooler is ducted or not.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("heating_system_flow_rate", true)
    arg.setDisplayName("Heating System: Flow Rate")
    arg.setDescription("The flow rate of the heating system.")
    arg.setUnits("CFM")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("cooling_system_flow_rate", true)
    arg.setDisplayName("Cooling System: Flow Rate")
    arg.setDescription("The flow rate of the cooling system.")
    arg.setUnits("CFM")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("hvac_distribution_system_type_dse", true)
    arg.setDisplayName("HVAC Distribution: Uses Distibution System Efficiency")
    arg.setDescription("Whether the HVAC distribution system type is distribution system efficiency.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("annual_heating_dse", true)
    arg.setDisplayName("HVAC Distribution: Annual Heating Distribution System Efficiency")
    arg.setDescription("The annual heating efficiency of the distribution system.")
    arg.setDefaultValue(0.8)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("annual_cooling_dse", true)
    arg.setDisplayName("HVAC Distribution: Annual Cooling Distribution System Efficiency")
    arg.setDescription("The annual cooling efficiency of the distribution system.")
    arg.setDefaultValue(0.7)
    args << arg

    hvac_control_type_choices = OpenStudio::StringVector.new
    hvac_control_type_choices << "manual thermostat"
    hvac_control_type_choices << "programmable thermostat"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("hvac_control_type", hvac_control_type_choices, true)
    arg.setDisplayName("HVAC Control: Type")
    arg.setDescription("The control type of the HVAC system.")
    arg.setDefaultValue("manual thermostat")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("heating_setpoint_temp", true)
    arg.setDisplayName("Heating Setpoint Temperature")
    arg.setDescription("Specify the heating setpoint temperature.")
    arg.setUnits("degrees F")
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("heating_setback_temp", true)
    arg.setDisplayName("Heating Setback Temperature")
    arg.setDescription("Specify the heating setback temperature.")
    arg.setUnits("degrees F")
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("heating_setback_hours_per_week", true)
    arg.setDisplayName("Heating Setback Hours per Week")
    arg.setDescription("Specify the heating setback number of hours per week value.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("heating_setback_start_hour", true)
    arg.setDisplayName("Heating Setback Start Hour")
    arg.setDescription("Specify the heating setback start hour value. 0 = midnight, 12 = noon")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("cooling_setpoint_temp", true)
    arg.setDisplayName("Cooling Setpoint Temperature")
    arg.setDescription("Specify the cooling setpoint temperature.")
    arg.setUnits("degrees F")
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("cooling_setup_temp", true)
    arg.setDisplayName("Cooling Setup Temperature")
    arg.setDescription("Specify the cooling setup temperature.")
    arg.setUnits("degrees F")
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("cooling_setup_hours_per_week", true)
    arg.setDisplayName("Cooling Setup Hours per Week")
    arg.setDescription("Specify the cooling setup number of hours per week value.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("cooling_setup_start_hour", true)
    arg.setDisplayName("Cooling Setup Start Hour")
    arg.setDescription("Specify the cooling setup start hour value. 0 = midnight, 12 = noon")
    arg.setDefaultValue(0)
    args << arg

    duct_leakage_units_choices = OpenStudio::StringVector.new
    duct_leakage_units_choices << "CFM25"
    duct_leakage_units_choices << "Percent"

    duct_location_choices = OpenStudio::StringVector.new
    duct_location_choices << Constants.Auto
    duct_location_choices << "living space"
    duct_location_choices << "attic - vented"
    duct_location_choices << "attic - unvented"
    duct_location_choices << "crawlspace - vented"
    duct_location_choices << "outside"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("supply_duct_leakage_units", duct_leakage_units_choices, true)
    arg.setDisplayName("Supply Duct: Leakage Units")
    arg.setDescription("The leakage units of the supply duct.")
    arg.setDefaultValue("CFM25")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("return_duct_leakage_units", duct_leakage_units_choices, true)
    arg.setDisplayName("Return Duct: Leakage Units")
    arg.setDescription("The leakage units of the return duct.")
    arg.setDefaultValue("CFM25")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("supply_duct_leakage_value", true)
    arg.setDisplayName("Supply Duct: Leakage Value")
    arg.setDescription("The leakage value of the supply duct.")
    arg.setDefaultValue(75)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("return_duct_leakage_value", true)
    arg.setDisplayName("Return Duct: Leakage Value")
    arg.setDescription("The leakage value of the return duct.")
    arg.setDefaultValue(25)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("supply_duct_insulation_r_value", true)
    arg.setDisplayName("Supply Duct: Insulation R-Value")
    arg.setDescription("The insulation r-value of the supply duct.")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("return_duct_insulation_r_value", true)
    arg.setDisplayName("Return Duct: Insulation R-Value")
    arg.setDescription("The insulation r-value of the return duct.")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("supply_duct_location", duct_location_choices, true)
    arg.setDisplayName("Supply Duct: Location")
    arg.setDescription("The location of the supply duct.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("return_duct_location", duct_location_choices, true)
    arg.setDisplayName("Return Duct: Location")
    arg.setDescription("The location of the return duct.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("supply_duct_surface_area", true)
    arg.setDisplayName("Supply Duct: Surface Area")
    arg.setDescription("The surface area of the first supply duct.")
    arg.setUnits("ft^2")
    arg.setDefaultValue(150)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("return_duct_surface_area", true)
    arg.setDisplayName("Return Duct: Surface Area")
    arg.setDescription("The surface area of the return duct.")
    arg.setUnits("ft^2")
    arg.setDefaultValue(50)
    args << arg

    mech_vent_fan_type_choices = OpenStudio::StringVector.new
    mech_vent_fan_type_choices << "none"
    mech_vent_fan_type_choices << "exhaust only"
    mech_vent_fan_type_choices << "supply only"
    mech_vent_fan_type_choices << "energy recovery ventilator"
    mech_vent_fan_type_choices << "heat recovery ventilator"
    mech_vent_fan_type_choices << "balanced"
    mech_vent_fan_type_choices << "central fan integrated supply"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("mech_vent_fan_type", mech_vent_fan_type_choices, true)
    arg.setDisplayName("Mechanical Ventilation: Fan Type")
    arg.setDescription("The fan type of the mechanical ventilation.")
    arg.setDefaultValue("none")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_tested_flow_rate", true)
    arg.setDisplayName("Mechanical Ventilation: Tested Flow Rate")
    arg.setDescription("The tested flow rate of the mechanical ventilation.")
    arg.setUnits("CFM")
    arg.setDefaultValue(110)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_rated_flow_rate", true)
    arg.setDisplayName("Mechanical Ventilation: Rated Flow Rate")
    arg.setDescription("The rated flow rate of the mechanical ventilation.")
    arg.setUnits("CFM")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_hours_in_operation", true)
    arg.setDisplayName("Mechanical Ventilation: Hours In Operation")
    arg.setDescription("The hours in operation of the mechanical ventilation.")
    arg.setUnits("hrs")
    arg.setDefaultValue(24)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_total_recovery_efficiency", true)
    arg.setDisplayName("Mechanical Ventilation: Total Recovery Efficiency")
    arg.setDescription("The total recovery efficiency of the mechanical ventilation.")
    arg.setUnits("Frac")
    arg.setDefaultValue(0.48)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_adjusted_total_recovery_efficiency", true)
    arg.setDisplayName("Mechanical Ventilation: Adjusted Total Recovery Efficiency")
    arg.setDescription("The adjusted total recovery efficiency of the mechanical ventilation.")
    arg.setUnits("Frac")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_sensible_recovery_efficiency", true)
    arg.setDisplayName("Mechanical Ventilation: Sensible Recovery Efficiency")
    arg.setDescription("The sensible recovery efficiency of the mechanical ventilation.")
    arg.setUnits("Frac")
    arg.setDefaultValue(0.72)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_adjusted_sensible_recovery_efficiency", true)
    arg.setDisplayName("Mechanical Ventilation: Adjusted Sensible Recovery Efficiency")
    arg.setDescription("The adjusted sensible recovery efficiency of the mechanical ventilation.")
    arg.setUnits("Frac")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_fan_power", true)
    arg.setDisplayName("Mechanical Ventilation: Fan Power")
    arg.setDescription("The fan power of the mechanical ventilation.")
    arg.setUnits("W")
    arg.setDefaultValue(30)
    args << arg

    water_heater_type_choices = OpenStudio::StringVector.new
    water_heater_type_choices << "none"
    water_heater_type_choices << "storage water heater"
    water_heater_type_choices << "instantaneous water heater"
    water_heater_type_choices << "heat pump water heater"
    water_heater_type_choices << "space-heating boiler with storage tank"
    water_heater_type_choices << "space-heating boiler with tankless coil"

    water_heater_fuel_choices = OpenStudio::StringVector.new
    water_heater_fuel_choices << "electricity"
    water_heater_fuel_choices << "natural gas"
    water_heater_fuel_choices << "fuel oil"
    water_heater_fuel_choices << "propane"
    water_heater_fuel_choices << "wood"

    location_choices = OpenStudio::StringVector.new
    location_choices << Constants.Auto
    location_choices << "living space"
    location_choices << "basement - conditioned"
    location_choices << "basement - unconditioned"
    location_choices << "garage"
    location_choices << "attic - vented"
    location_choices << "attic - unvented"
    location_choices << "crawlspace - vented"
    location_choices << "crawlspace - unvented"
    location_choices << "other exterior"

    (1..Constants.MaxNumWaterHeaters).to_a.each do |n|
      water_heater_type = "none"
      if n == 1
        water_heater_type = "storage water heater"
      end

      arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("water_heater_type_#{n}", water_heater_type_choices, true)
      arg.setDisplayName("Water Heater #{n}: Type")
      arg.setDescription("The type of water heater #{n}.")
      arg.setDefaultValue(water_heater_type)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("water_heater_fuel_type_#{n}", water_heater_fuel_choices, true)
      arg.setDisplayName("Water Heater #{n}: Fuel Type")
      arg.setDescription("The fuel type of water heater #{n}.")
      arg.setDefaultValue("electricity")
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("water_heater_location_#{n}", location_choices, true)
      arg.setDisplayName("Water Heater #{n}: Location")
      arg.setDescription("The location of water heater #{n}.")
      arg.setDefaultValue(Constants.Auto)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeStringArgument("water_heater_tank_volume_#{n}", true)
      arg.setDisplayName("Water Heater #{n}: Tank Volume")
      arg.setDescription("Nominal volume of water heater tank #{n}. Set to #{Constants.Auto} to have volume autosized.")
      arg.setUnits("gal")
      arg.setDefaultValue(Constants.Auto)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("water_heater_fraction_dhw_load_served_#{n}", true)
      arg.setDisplayName("Water Heater #{n}: Fraction DHW Load Served")
      arg.setDescription("The dhw load served fraction of water heater #{n}.")
      arg.setUnits("Frac")
      arg.setDefaultValue(1)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeStringArgument("water_heater_heating_capacity_#{n}", true)
      arg.setDisplayName("Water Heater #{n}: Input Capacity")
      arg.setDescription("The maximum energy input rating of water heater #{n}. Set to #{Constants.SizingAuto} to have this field autosized.")
      arg.setUnits("Btu/hr")
      arg.setDefaultValue(Constants.SizingAuto)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeStringArgument("water_heater_energy_factor_#{n}", true)
      arg.setDisplayName("Water Heater #{n}: Rated Energy Factor")
      arg.setDescription("Ratio of useful energy output from water heater #{n} to the total amount of energy delivered from the water heater.")
      arg.setDefaultValue(Constants.Auto)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("water_heater_uniform_energy_factor_#{n}", true)
      arg.setDisplayName("Water Heater #{n}: Uniform Energy Factor")
      arg.setDescription("The uniform energy factor of water heater #{n}.")
      arg.setDefaultValue(0)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("water_heater_recovery_efficiency_#{n}", true)
      arg.setDisplayName("Water Heater #{n}: Recovery Efficiency")
      arg.setDescription("Ratio of energy delivered to water heater #{n} to the energy content of the fuel consumed by the water heater. Only used for non-electric water heaters.")
      arg.setUnits("Frac")
      arg.setDefaultValue(0.76)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeBoolArgument("water_heater_uses_desuperheater_#{n}", true)
      arg.setDisplayName("Water Heater #{n}: Uses Desuperheater")
      arg.setDescription("Whether water heater #{n} uses desuperheater.")
      arg.setDefaultValue(false)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("water_heater_standby_loss_#{n}", true)
      arg.setDisplayName("Water Heater #{n}: Standby Loss")
      arg.setDescription("The standby loss of water heater #{n}.")
      arg.setUnits("Frac")
      arg.setDefaultValue(0)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("water_heater_jacket_rvalue_#{n}", true)
      arg.setDisplayName("Water Heater #{n}: Jacket R-value")
      arg.setDescription("The jacket R-value of water heater #{n}.")
      arg.setUnits("h-ft^2-R/Btu")
      arg.setDefaultValue(0)
      args << arg
    end

    hot_water_distribution_system_type_choices = OpenStudio::StringVector.new
    hot_water_distribution_system_type_choices << "Standard"
    hot_water_distribution_system_type_choices << "Recirculation"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("hot_water_distribution_system_type", hot_water_distribution_system_type_choices, true)
    arg.setDisplayName("Hot Water Distribution: System Type")
    arg.setDescription("The type of the hot water distribution system.")
    arg.setDefaultValue("Standard")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("standard_piping_length", true)
    arg.setDisplayName("Hot Water Distribution: Standard Piping Length")
    arg.setUnits("ft")
    arg.setDescription("The length of the standard piping.")
    arg.setDefaultValue(50)
    args << arg

    recirculation_control_type_choices = OpenStudio::StringVector.new
    recirculation_control_type_choices << "no control"
    recirculation_control_type_choices << "timer"
    recirculation_control_type_choices << "temperature"
    recirculation_control_type_choices << "presence sensor demand control"
    recirculation_control_type_choices << "manual demand control"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("recirculation_control_type", recirculation_control_type_choices, true)
    arg.setDisplayName("Hot Water Distribution: Recirculation Control Type")
    arg.setDescription("The type of hot water recirculation control, if any.")
    arg.setDefaultValue("no control")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("recirculation_piping_length", true)
    arg.setDisplayName("Hot Water Distribution: Recirculation Piping Length")
    arg.setUnits("ft")
    arg.setDescription("The length of the recirculation piping.")
    arg.setDefaultValue(50)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("recirculation_branch_piping_length", true)
    arg.setDisplayName("Hot Water Distribution: Recirculation Branch Piping Length")
    arg.setUnits("ft")
    arg.setDescription("The length of the recirculation branch piping.")
    arg.setDefaultValue(50)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("recirculation_pump_power", true)
    arg.setDisplayName("Hot Water Distribution: Recirculation Pump Power")
    arg.setUnits("W")
    arg.setDescription("The power of the recirculation pump.")
    arg.setDefaultValue(50)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("hot_water_distribution_pipe_r_value", true)
    arg.setDisplayName("Hot Water Distribution: Insulation Nominal R-Value")
    arg.setUnits("h-ft^2-R/Btu")
    arg.setDescription("Nominal R-value of the insulation on the DHW distribution system.")
    arg.setDefaultValue(0.0)
    args << arg

    dwhr_facilities_connected_choices = OpenStudio::StringVector.new
    dwhr_facilities_connected_choices << "none"
    dwhr_facilities_connected_choices << "all"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("dwhr_facilities_connected", dwhr_facilities_connected_choices, true)
    arg.setDisplayName("Drain Water Heat Recovery: Facilities Connected")
    arg.setDescription("Which facilities are connected for the drain water heat recovery.")
    arg.setDefaultValue("none")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("dwhr_equal_flow", true)
    arg.setDisplayName("Drain Water Heat Recovery: Equal Flow")
    arg.setDescription("Whether the drain water heat recovery has equal flow.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("dwhr_efficiency", true)
    arg.setDisplayName("Drain Water Heat Recovery: Efficiency")
    arg.setUnits("Frac")
    arg.setDescription("The efficiency of the drain water heat recovery.")
    arg.setDefaultValue(0.55)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("shower_low_flow", true)
    arg.setDisplayName("Hot Water Fixtures: Is Shower Low Flow")
    arg.setDescription("Whether the shower fixture is low flow.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("sink_low_flow", true)
    arg.setDisplayName("Hot Water Fixtures: Is Sink Low Flow")
    arg.setDescription("Whether the sink fixture is low flow.")
    arg.setDefaultValue(false)
    args << arg

    solar_thermal_system_type_choices = OpenStudio::StringVector.new
    solar_thermal_system_type_choices << "none"
    solar_thermal_system_type_choices << "hot water"

    solar_thermal_collector_loop_type_choices = OpenStudio::StringVector.new
    solar_thermal_collector_loop_type_choices << "liquid direct"
    solar_thermal_collector_loop_type_choices << "liquid indirect"
    solar_thermal_collector_loop_type_choices << "passive thermosyphon"

    solar_thermal_collector_type_choices = OpenStudio::StringVector.new
    solar_thermal_collector_type_choices << "evacuated tube"
    solar_thermal_collector_type_choices << "single glazing black"
    solar_thermal_collector_type_choices << "integrated collector storage"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("solar_thermal_system_type", solar_thermal_system_type_choices, true)
    arg.setDisplayName("Solar Thermal: System Type")
    arg.setDescription("The type of the solar thermal system.")
    arg.setDefaultValue("none")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("solar_thermal_collector_area", true)
    arg.setDisplayName("Solar Thermal: Collector Area")
    arg.setUnits("ft^2")
    arg.setDescription("The collector area of the solar thermal system.")
    arg.setDefaultValue(40.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("solar_thermal_collector_loop_type", solar_thermal_collector_loop_type_choices, true)
    arg.setDisplayName("Solar Thermal: Collector Loop Type")
    arg.setDescription("The collector loop type of the solar thermal system.")
    arg.setDefaultValue("liquid direct")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("solar_thermal_collector_type", solar_thermal_collector_type_choices, true)
    arg.setDisplayName("Solar Thermal: Collector Type")
    arg.setDescription("The collector type of the solar thermal system.")
    arg.setDefaultValue("evacuated tube")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("solar_thermal_collector_azimuth", true)
    arg.setDisplayName("Solar Thermal: Collector Azimuth")
    arg.setUnits("degrees")
    arg.setDescription("The collector azimuth of the solar thermal system.")
    arg.setDefaultValue(180)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("solar_thermal_collector_tilt", true)
    arg.setDisplayName("Solar Thermal: Collector Tilt")
    arg.setUnits("degrees")
    arg.setDescription("The collector tilt of the solar thermal system.")
    arg.setDefaultValue(20)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("solar_thermal_collector_rated_optical_efficiency", true)
    arg.setDisplayName("Solar Thermal: Collector Rated Optical Efficiency")
    arg.setUnits("Frac")
    arg.setDescription("The collector rated optical efficiency of the solar thermal system.")
    arg.setDefaultValue(0.5)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("solar_thermal_collector_rated_thermal_losses", true)
    arg.setDisplayName("Solar Thermal: Collector Rated Thermal Losses")
    arg.setUnits("Frac")
    arg.setDescription("The collector rated thermal losses of the solar thermal system.")
    arg.setDefaultValue(0.2799)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("solar_thermal_storage_volume", true)
    arg.setDisplayName("Solar Thermal: Storage Volume")
    arg.setUnits("Frac")
    arg.setDescription("The storage volume of the solar thermal system.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("solar_thermal_solar_fraction", true)
    arg.setDisplayName("Solar Thermal: Solar Fraction")
    arg.setUnits("Frac")
    arg.setDescription("The solar fraction of the solar thermal system.")
    arg.setDefaultValue(0)
    args << arg

    pv_system_module_type_choices = OpenStudio::StringVector.new
    pv_system_module_type_choices << "none"
    pv_system_module_type_choices << "standard"
    pv_system_module_type_choices << "premium"
    pv_system_module_type_choices << "thin film"

    pv_system_location_choices = OpenStudio::StringVector.new
    pv_system_location_choices << "roof"
    pv_system_location_choices << "ground"

    pv_system_tracking_choices = OpenStudio::StringVector.new
    pv_system_tracking_choices << "fixed"
    pv_system_tracking_choices << "1-axis"
    pv_system_tracking_choices << "1-axis backtracked"
    pv_system_tracking_choices << "2-axis"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("pv_system_module_type", pv_system_module_type_choices, true)
    arg.setDisplayName("Photovoltaics: Module Type")
    arg.setDescription("Module type of the PV system.")
    arg.setDefaultValue("none")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("pv_system_location", pv_system_location_choices, true)
    arg.setDisplayName("Photovoltaics: Location")
    arg.setDescription("Location of the PV system.")
    arg.setDefaultValue("roof")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("pv_system_tracking", pv_system_tracking_choices, true)
    arg.setDisplayName("Photovoltaics: Tracking")
    arg.setDescription("Tracking of the PV system.")
    arg.setDefaultValue("fixed")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("pv_system_array_azimuth", true)
    arg.setDisplayName("Photovoltaics: Array Azimuth")
    arg.setUnits("degrees")
    arg.setDescription("Array azimuth of the PV system.")
    arg.setDefaultValue(180)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("pv_system_array_tilt", true)
    arg.setDisplayName("Photovoltaics: Array Tilt")
    arg.setUnits("degrees")
    arg.setDescription("Array tilt of the PV system.")
    arg.setDefaultValue(20)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("pv_system_max_power_output", true)
    arg.setDisplayName("Photovoltaics: Maximum Power Output")
    arg.setUnits("W")
    arg.setDescription("Maximum power output of the PV system.")
    arg.setDefaultValue(4000)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("pv_system_inverter_efficiency", true)
    arg.setDisplayName("Photovoltaics: Inverter Efficiency")
    arg.setUnits("Frac")
    arg.setDescription("Inverter efficiency of the PV system.")
    arg.setDefaultValue(0.96)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("pv_system_system_losses_fraction", true)
    arg.setDisplayName("Photovoltaics: System Losses Fraction")
    arg.setUnits("Frac")
    arg.setDescription("System losses fraction of the PV system.")
    arg.setDefaultValue(0.14)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("has_clothes_washer", true)
    arg.setDisplayName("Clothes Washer: Has")
    arg.setDescription("Whether there is a clothes washer.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("clothes_washer_location", location_choices, true)
    arg.setDisplayName("Clothes Washer: Location")
    arg.setDescription("The space type for the clothes washer location.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("clothes_washer_integrated_modified_energy_factor", true)
    arg.setDisplayName("Clothes Washer: Integrated Modified Energy Factor")
    arg.setUnits("ft^3/kWh-cycle")
    arg.setDescription("The Integrated Modified Energy Factor (IMEF) is the capacity of the clothes container divided by the total clothes washer energy consumption per cycle, where the energy consumption is the sum of the machine electrical energy consumption, the hot water energy consumption, the energy required for removal of the remaining moisture in the wash load, standby energy, and off-mode energy consumption. If only a Modified Energy Factor (MEF) is available, convert using the equation: IMEF = (MEF - 0.503) / 0.95.")
    arg.setDefaultValue(0.95)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("clothes_washer_rated_annual_kwh", true)
    arg.setDisplayName("Clothes Washer: Rated Annual Consumption")
    arg.setUnits("kWh")
    arg.setDescription("The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
    arg.setDefaultValue(387.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("clothes_washer_label_electric_rate", true)
    arg.setDisplayName("Clothes Washer: Label Electric Rate")
    arg.setUnits("kWh")
    arg.setDescription("The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
    arg.setDefaultValue(0.1065)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("clothes_washer_label_gas_rate", true)
    arg.setDisplayName("Clothes Washer: Label Gas Rate")
    arg.setUnits("kWh")
    arg.setDescription("The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
    arg.setDefaultValue(1.218)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("clothes_washer_label_annual_gas_cost", true)
    arg.setDisplayName("Clothes Washer: Annual Cost with Gas DHW")
    arg.setUnits("$")
    arg.setDescription("The annual cost of using the system under test conditions. Input is obtained from the EnergyGuide label.")
    arg.setDefaultValue(24.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("clothes_washer_capacity", true)
    arg.setDisplayName("Clothes Washer: Drum Volume")
    arg.setUnits("ft^3")
    arg.setDescription("Volume of the washer drum. Obtained from the EnergyStar website or the manufacturer's literature.")
    arg.setDefaultValue(3.5)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("has_clothes_dryer", true)
    arg.setDisplayName("Clothes Dryer: Has")
    arg.setDescription("Whether there is a clothes dryer.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("clothes_dryer_location", location_choices, true)
    arg.setDisplayName("Clothes Dryer: Location")
    arg.setDescription("The space type for the clothes dryer location.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    clothes_dryer_fuel_choices = OpenStudio::StringVector.new
    clothes_dryer_fuel_choices << "electricity"
    clothes_dryer_fuel_choices << "natural gas"
    clothes_dryer_fuel_choices << "fuel oil"
    clothes_dryer_fuel_choices << "propane"
    clothes_dryer_fuel_choices << "wood"

    clothes_dryer_control_type_choices = OpenStudio::StringVector.new
    clothes_dryer_control_type_choices << "timer"
    clothes_dryer_control_type_choices << "moisture"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("clothes_dryer_fuel_type", clothes_dryer_fuel_choices, true)
    arg.setDisplayName("Clothes Dryer: Fuel Type")
    arg.setDescription("Type of fuel used by the clothes dryer.")
    arg.setDefaultValue("natural gas")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("clothes_dryer_energy_factor", true)
    arg.setDisplayName("Clothes Dryer: Energy Factor")
    arg.setDescription("The energy factor of the clothes dryer.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("clothes_dryer_combined_energy_factor", true)
    arg.setDisplayName("Clothes Dryer: Combined Energy Factor")
    arg.setDescription("The Combined Energy Factor (CEF) measures the pounds of clothing that can be dried per kWh (Fuel equivalent) of electricity, including energy consumed during Stand-by and Off modes. If only an Energy Factor (EF) is available, convert using the equation: CEF = EF / 1.15.")
    arg.setDefaultValue(2.4)
    arg.setUnits("lb/kWh")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("clothes_dryer_control_type", clothes_dryer_control_type_choices, true)
    arg.setDisplayName("Clothes Dryer: Control Type")
    arg.setDescription("Type of control used by the clothes dryer.")
    arg.setDefaultValue("timer")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("has_dishwasher", true)
    arg.setDisplayName("Dishwasher: Has")
    arg.setDescription("Whether there is a dishwasher.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("dishwasher_energy_factor", true)
    arg.setDisplayName("Dishwasher: Energy Factor")
    arg.setDescription("The energy factor of the dishwasher.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("dishwasher_rated_annual_kwh", true)
    arg.setDisplayName("Dishwasher: Rated Annual Consumption")
    arg.setUnits("kWh")
    arg.setDescription("The annual energy consumed by the dishwasher, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
    arg.setDefaultValue(290)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("dishwasher_place_setting_capacity", true)
    arg.setDisplayName("Dishwasher: Number of Place Settings")
    arg.setUnits("#")
    arg.setDescription("The number of place settings for the unit. Data obtained from manufacturer's literature.")
    arg.setDefaultValue(12)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("has_refrigerator", true)
    arg.setDisplayName("Refrigerator: Has")
    arg.setDescription("Whether there is a refrigerator.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("refrigerator_location", location_choices, true)
    arg.setDisplayName("Refrigerator: Location")
    arg.setDescription("The space type for the refrigerator location.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("refrigerator_rated_annual_kwh", true)
    arg.setDisplayName("Refrigerator: Rated Annual Consumption")
    arg.setUnits("kWh/yr")
    arg.setDescription("The EnergyGuide rated annual energy consumption for a refrigerator.")
    arg.setDefaultValue(434)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("refrigerator_adjusted_annual_kwh", true)
    arg.setDisplayName("Refrigerator: Adjusted Annual Consumption")
    arg.setUnits("kWh/yr")
    arg.setDescription("The adjusted annual energy consumption for a refrigerator.")
    arg.setDefaultValue(0)
    args << arg

    cooking_range_fuel_choices = OpenStudio::StringVector.new
    cooking_range_fuel_choices << "electricity"
    cooking_range_fuel_choices << "natural gas"
    cooking_range_fuel_choices << "fuel oil"
    cooking_range_fuel_choices << "propane"
    cooking_range_fuel_choices << "wood"

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("has_cooking_range", true)
    arg.setDisplayName("Cooking Range: Has")
    arg.setDescription("Whether there is a cooking range.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("cooking_range_fuel_type", cooking_range_fuel_choices, true)
    arg.setDisplayName("Cooking Range: Fuel Type")
    arg.setDescription("Type of fuel used by the cooking range.")
    arg.setDefaultValue("natural gas")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("cooking_range_is_induction", true)
    arg.setDisplayName("Cooking Range: Is Induction")
    arg.setDescription("Whether the cooking range is induction.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("has_oven", true)
    arg.setDisplayName("Oven: Has")
    arg.setDescription("Whether there is a oven.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("oven_is_convection", true)
    arg.setDisplayName("Oven: Is Convection")
    arg.setDescription("Whether the oven is convection.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("has_lighting", true)
    arg.setDisplayName("Lighting: Has")
    arg.setDescription("Whether there is lighting.")
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceiling_fan_efficiency", true)
    arg.setDisplayName("Ceiling Fan: Efficiency")
    arg.setUnits("CFM/watt")
    arg.setDescription("The efficiency rating of the ceiling fan(s) at medium speed.")
    arg.setDefaultValue(100)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("ceiling_fan_quantity", true)
    arg.setDisplayName("Ceiling Fan: Quantity")
    arg.setUnits("#")
    arg.setDescription("Total number of ceiling fans.")
    arg.setDefaultValue(2)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("ceiling_fan_cooling_setpoint_temp_offset", true)
    arg.setDisplayName("Ceiling Fan: Cooling Setpoint Temperature Offset")
    arg.setUnits("degrees F")
    arg.setDescription("The setpoint temperature offset during cooling season for the ceiling fan(s).")
    arg.setDefaultValue(0)
    args << arg

    plug_loads_plug_load_type_choices = OpenStudio::StringVector.new
    plug_loads_plug_load_type_choices << "none"
    plug_loads_plug_load_type_choices << "other"
    plug_loads_plug_load_type_choices << "TV other"

    (1..Constants.MaxNumPlugLoads).to_a.each do |n|
      plug_load_type = "none"
      if n == 1
        plug_load_type = "other"
      end

      arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("plug_loads_plug_load_type_#{n}", plug_loads_plug_load_type_choices, true)
      arg.setDisplayName("Plug Load #{n}: Type")
      arg.setDescription("Type of plug load #{n}.")
      arg.setDefaultValue(plug_load_type)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("plug_loads_annual_kwh_#{n}", true)
      arg.setDisplayName("Plug Load #{n}: Annual kWh")
      arg.setDescription("The annual energy consumption of plug load #{n}.")
      arg.setUnits("kWh/yr")
      arg.setDefaultValue(0)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("plug_loads_frac_sensible_#{n}", true)
      arg.setDisplayName("Plug Load #{n}: Sensible Fraction")
      arg.setDescription("Fraction of internal gains that are sensible for plug load #{n}.")
      arg.setUnits("Frac")
      arg.setDefaultValue(0)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("plug_loads_frac_latent_#{n}", true)
      arg.setDisplayName("Plug Load #{n}: Latent Fraction")
      arg.setDescription("Fraction of internal gains that are latent for plug load #{n}.")
      arg.setUnits("Frac")
      arg.setDefaultValue(0)
      args << arg
    end

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("plug_loads_schedule_values", true)
    arg.setDisplayName("Plug Loads: Use Schedule Values")
    arg.setDescription("Whether to use the schedule values.")
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("plug_loads_weekday_fractions", true)
    arg.setDisplayName("Plug Loads: Weekday Schedule")
    arg.setDescription("Specify the 24-hour weekday schedule.")
    arg.setDefaultValue("0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("plug_loads_weekend_fractions", true)
    arg.setDisplayName("Plug Loads: Weekend Schedule")
    arg.setDescription("Specify the 24-hour weekend schedule.")
    arg.setDefaultValue("0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("plug_loads_monthly_multipliers", true)
    arg.setDisplayName("Plug Loads: Month Schedule")
    arg.setDescription("Specify the 12-month schedule.")
    arg.setDefaultValue("1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248")
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    require_relative "../HPXMLtoOpenStudio/measure"
    require_relative "../HPXMLtoOpenStudio/resources/EPvalidator"
    require_relative "../HPXMLtoOpenStudio/resources/constructions"
    require_relative "../HPXMLtoOpenStudio/resources/hpxml"
    require_relative "../HPXMLtoOpenStudio/resources/schedules"
    require_relative "../HPXMLtoOpenStudio/resources/waterheater"

    # Check for correct versions of OS
    os_version = "2.9.1"
    if OpenStudio.openStudioVersion != os_version
      fail "OpenStudio version #{os_version} is required."
    end

    # assign the user inputs to variables
    args = { :weather_station_epw_filename => runner.getStringArgumentValue("weather_station_epw_filename", user_arguments),
             :hpxml_path => runner.getStringArgumentValue("hpxml_path", user_arguments),
             :schedules_output_path => runner.getStringArgumentValue("schedules_output_path", user_arguments),
             :unit_type => runner.getStringArgumentValue("unit_type", user_arguments),
             :unit_multiplier => runner.getIntegerArgumentValue("unit_multiplier", user_arguments),
             :cfa => runner.getDoubleArgumentValue("cfa", user_arguments),
             :wall_height => runner.getDoubleArgumentValue("wall_height", user_arguments),
             :num_floors => runner.getIntegerArgumentValue("num_floors", user_arguments),
             :aspect_ratio => runner.getDoubleArgumentValue("aspect_ratio", user_arguments),
             :level => runner.getStringArgumentValue("level", user_arguments),
             :horizontal_location => runner.getStringArgumentValue("horizontal_location", user_arguments),
             :corridor_position => runner.getStringArgumentValue("corridor_position", user_arguments),
             :corridor_width => runner.getDoubleArgumentValue("corridor_width", user_arguments),
             :inset_width => runner.getDoubleArgumentValue("inset_width", user_arguments),
             :inset_depth => runner.getDoubleArgumentValue("inset_depth", user_arguments),
             :inset_position => runner.getStringArgumentValue("inset_position", user_arguments),
             :balcony_depth => runner.getDoubleArgumentValue("balcony_depth", user_arguments),
             :garage_width => runner.getDoubleArgumentValue("garage_width", user_arguments),
             :garage_depth => runner.getDoubleArgumentValue("garage_depth", user_arguments),
             :garage_protrusion => runner.getDoubleArgumentValue("garage_protrusion", user_arguments),
             :garage_position => runner.getStringArgumentValue("garage_position", user_arguments),
             :foundation_type => runner.getStringArgumentValue("foundation_type", user_arguments),
             :foundation_height => runner.getDoubleArgumentValue("foundation_height", user_arguments),
             :foundation_ceiling_r => runner.getDoubleArgumentValue("foundation_ceiling_r", user_arguments),
             :foundation_wall_r => runner.getDoubleArgumentValue("foundation_wall_r", user_arguments),
             :foundation_wall_distance_to_top => runner.getDoubleArgumentValue("foundation_wall_distance_to_top", user_arguments),
             :foundation_wall_distance_to_bottom => runner.getDoubleArgumentValue("foundation_wall_distance_to_bottom", user_arguments),
             :foundation_wall_depth_below_grade => runner.getDoubleArgumentValue("foundation_wall_depth_below_grade", user_arguments),
             :perimeter_insulation_r_value => runner.getDoubleArgumentValue("slab_perimeter_r", user_arguments),
             :perimeter_insulation_depth => runner.getDoubleArgumentValue("slab_perimeter_depth", user_arguments),
             :under_slab_insulation_r_value => runner.getDoubleArgumentValue("slab_under_r", user_arguments),
             :under_slab_insulation_width => runner.getDoubleArgumentValue("slab_under_width", user_arguments),
             :carpet_fraction => runner.getDoubleArgumentValue("carpet_fraction", user_arguments),
             :carpet_r_value => runner.getDoubleArgumentValue("carpet_r_value", user_arguments),
             :attic_type => runner.getStringArgumentValue("attic_type", user_arguments),
             :attic_floor_conditioned_r => runner.getDoubleArgumentValue("attic_floor_conditioned_r", user_arguments),
             :attic_floor_unconditioned_r => runner.getDoubleArgumentValue("attic_floor_unconditioned_r", user_arguments),
             :attic_ceiling_r => runner.getDoubleArgumentValue("attic_ceiling_r", user_arguments),
             :roof_type => runner.getStringArgumentValue("roof_type", user_arguments),
             :roof_pitch => { "1:12" => 1.0 / 12.0, "2:12" => 2.0 / 12.0, "3:12" => 3.0 / 12.0, "4:12" => 4.0 / 12.0, "5:12" => 5.0 / 12.0, "6:12" => 6.0 / 12.0, "7:12" => 7.0 / 12.0, "8:12" => 8.0 / 12.0, "9:12" => 9.0 / 12.0, "10:12" => 10.0 / 12.0, "11:12" => 11.0 / 12.0, "12:12" => 12.0 / 12.0 }[runner.getStringArgumentValue("roof_pitch", user_arguments)],
             :roof_structure => runner.getStringArgumentValue("roof_structure", user_arguments),
             :roof_ceiling_r => runner.getDoubleArgumentValue("roof_ceiling_r", user_arguments),
             :roof_solar_absorptance => runner.getDoubleArgumentValue("roof_solar_absorptance", user_arguments),
             :roof_emittance => runner.getDoubleArgumentValue("roof_emittance", user_arguments),
             :roof_radiant_barrier => runner.getBoolArgumentValue("roof_radiant_barrier", user_arguments),
             :eaves_depth => runner.getDoubleArgumentValue("eaves_depth", user_arguments),
             :num_bedrooms => runner.getDoubleArgumentValue("num_bedrooms", user_arguments),
             :num_bathrooms => runner.getDoubleArgumentValue("num_bathrooms", user_arguments),
             :num_occupants => runner.getStringArgumentValue("num_occupants", user_arguments),
             :neighbor_distance => [runner.getDoubleArgumentValue("neighbor_front_distance", user_arguments), runner.getDoubleArgumentValue("neighbor_back_distance", user_arguments), runner.getDoubleArgumentValue("neighbor_left_distance", user_arguments), runner.getDoubleArgumentValue("neighbor_right_distance", user_arguments)],
             :neighbor_height => [runner.getDoubleArgumentValue("neighbor_front_height", user_arguments), runner.getDoubleArgumentValue("neighbor_back_height", user_arguments), runner.getDoubleArgumentValue("neighbor_left_height", user_arguments), runner.getDoubleArgumentValue("neighbor_right_height", user_arguments)],
             :orientation => runner.getDoubleArgumentValue("orientation", user_arguments),
             :wall_type => runner.getStringArgumentValue("wall_type", user_arguments),
             :wall_conditioned_r => runner.getDoubleArgumentValue("wall_conditioned_r", user_arguments),
             :wall_unconditioned_r => runner.getDoubleArgumentValue("wall_unconditioned_r", user_arguments),
             :wall_solar_absorptance => runner.getDoubleArgumentValue("wall_solar_absorptance", user_arguments),
             :wall_emittance => runner.getDoubleArgumentValue("wall_emittance", user_arguments),
             :front_wwr => runner.getDoubleArgumentValue("front_wwr", user_arguments),
             :back_wwr => runner.getDoubleArgumentValue("back_wwr", user_arguments),
             :left_wwr => runner.getDoubleArgumentValue("left_wwr", user_arguments),
             :right_wwr => runner.getDoubleArgumentValue("right_wwr", user_arguments),
             :front_window_area => runner.getDoubleArgumentValue("front_window_area", user_arguments),
             :back_window_area => runner.getDoubleArgumentValue("back_window_area", user_arguments),
             :left_window_area => runner.getDoubleArgumentValue("left_window_area", user_arguments),
             :right_window_area => runner.getDoubleArgumentValue("right_window_area", user_arguments),
             :window_aspect_ratio => runner.getDoubleArgumentValue("window_aspect_ratio", user_arguments),
             :window_ufactor => runner.getDoubleArgumentValue("window_ufactor", user_arguments),
             :window_shgc => runner.getDoubleArgumentValue("window_shgc", user_arguments),
             :interior_shading_factor_winter => [runner.getDoubleArgumentValue("winter_shading_coefficient_front_facade", user_arguments)],
             :interior_shading_factor_summer => [runner.getDoubleArgumentValue("summer_shading_coefficient_front_facade", user_arguments)],
             :overhangs => [runner.getBoolArgumentValue("overhangs_front_facade", user_arguments), runner.getBoolArgumentValue("overhangs_back_facade", user_arguments), runner.getBoolArgumentValue("overhangs_left_facade", user_arguments), runner.getBoolArgumentValue("overhangs_right_facade", user_arguments)],
             :overhangs_depth => runner.getDoubleArgumentValue("overhangs_depth", user_arguments),
             :front_skylight_area => runner.getDoubleArgumentValue("front_skylight_area", user_arguments),
             :back_skylight_area => runner.getDoubleArgumentValue("back_skylight_area", user_arguments),
             :left_skylight_area => runner.getDoubleArgumentValue("left_skylight_area", user_arguments),
             :right_skylight_area => runner.getDoubleArgumentValue("right_skylight_area", user_arguments),
             :skylight_ufactor => runner.getDoubleArgumentValue("skylight_ufactor", user_arguments),
             :skylight_shgc => runner.getDoubleArgumentValue("skylight_shgc", user_arguments),
             :door_area => runner.getDoubleArgumentValue("door_area", user_arguments),
             :door_rvalue => runner.getDoubleArgumentValue("door_rvalue", user_arguments),
             :living_ach_50 => runner.getDoubleArgumentValue("living_ach_50", user_arguments),
             :living_constant_ach_natural => runner.getDoubleArgumentValue("living_constant_ach_natural", user_arguments),
             :vented_crawlspace_sla => runner.getDoubleArgumentValue("vented_crawlspace_sla", user_arguments),
             :shelter_coefficient => runner.getStringArgumentValue("shelter_coefficient", user_arguments),
             :heating_system_type => runner.getStringArgumentValue("heating_system_type", user_arguments),
             :heating_system_fuel => runner.getStringArgumentValue("heating_system_fuel", user_arguments),
             :heating_system_heating_efficiency => runner.getDoubleArgumentValue("heating_system_heating_efficiency", user_arguments),
             :heating_system_heating_capacity => runner.getStringArgumentValue("heating_system_heating_capacity", user_arguments),
             :heating_system_fraction_heat_load_served => runner.getDoubleArgumentValue("heating_system_fraction_heat_load_served", user_arguments),
             :heating_system_electric_auxiliary_energy => runner.getDoubleArgumentValue("heating_system_electric_auxiliary_energy", user_arguments),
             :cooling_system_type => runner.getStringArgumentValue("cooling_system_type", user_arguments),
             :cooling_system_fuel => runner.getStringArgumentValue("cooling_system_fuel", user_arguments),
             :cooling_system_cooling_efficiency => runner.getDoubleArgumentValue("cooling_system_cooling_efficiency", user_arguments),
             :cooling_system_cooling_capacity => runner.getStringArgumentValue("cooling_system_cooling_capacity", user_arguments),
             :cooling_system_fraction_cool_load_served => runner.getDoubleArgumentValue("cooling_system_fraction_cool_load_served", user_arguments),
             :heat_pump_backup_fuel => runner.getStringArgumentValue("heat_pump_backup_fuel", user_arguments),
             :heat_pump_backup_heating_efficiency => runner.getStringArgumentValue("heat_pump_backup_heating_efficiency", user_arguments),
             :heat_pump_backup_heating_capacity => runner.getStringArgumentValue("heat_pump_backup_heating_capacity", user_arguments),
             :hvac_distribution_system_type_dse => runner.getBoolArgumentValue("hvac_distribution_system_type_dse", user_arguments),
             :mini_split_is_ducted => runner.getBoolArgumentValue("mini_split_is_ducted", user_arguments),
             :evap_cooler_is_ducted => runner.getBoolArgumentValue("evap_cooler_is_ducted", user_arguments),
             :heating_system_flow_rate => runner.getDoubleArgumentValue("heating_system_flow_rate", user_arguments),
             :cooling_system_flow_rate => runner.getDoubleArgumentValue("cooling_system_flow_rate", user_arguments),
             :annual_heating_dse => runner.getDoubleArgumentValue("annual_heating_dse", user_arguments),
             :annual_cooling_dse => runner.getDoubleArgumentValue("annual_cooling_dse", user_arguments),
             :hvac_control_type => runner.getStringArgumentValue("hvac_control_type", user_arguments),
             :heating_setpoint_temp => runner.getDoubleArgumentValue("heating_setpoint_temp", user_arguments),
             :heating_setback_temp => runner.getDoubleArgumentValue("heating_setback_temp", user_arguments),
             :heating_setback_hours_per_week => runner.getDoubleArgumentValue("heating_setback_hours_per_week", user_arguments),
             :heating_setback_start_hour => runner.getDoubleArgumentValue("heating_setback_start_hour", user_arguments),
             :cooling_setpoint_temp => runner.getDoubleArgumentValue("cooling_setpoint_temp", user_arguments),
             :cooling_setup_temp => runner.getDoubleArgumentValue("cooling_setup_temp", user_arguments),
             :cooling_setup_hours_per_week => runner.getDoubleArgumentValue("cooling_setup_hours_per_week", user_arguments),
             :cooling_setup_start_hour => runner.getDoubleArgumentValue("cooling_setup_start_hour", user_arguments),
             :supply_duct_leakage_units => runner.getStringArgumentValue("supply_duct_leakage_units", user_arguments),
             :return_duct_leakage_units => runner.getStringArgumentValue("return_duct_leakage_units", user_arguments),
             :supply_duct_leakage_value => runner.getDoubleArgumentValue("supply_duct_leakage_value", user_arguments),
             :return_duct_leakage_value => runner.getDoubleArgumentValue("return_duct_leakage_value", user_arguments),
             :supply_duct_insulation_r_value => runner.getDoubleArgumentValue("supply_duct_insulation_r_value", user_arguments),
             :return_duct_insulation_r_value => runner.getDoubleArgumentValue("return_duct_insulation_r_value", user_arguments),
             :supply_duct_location => runner.getStringArgumentValue("supply_duct_location", user_arguments),
             :return_duct_location => runner.getStringArgumentValue("return_duct_location", user_arguments),
             :supply_duct_surface_area => runner.getDoubleArgumentValue("supply_duct_surface_area", user_arguments),
             :return_duct_surface_area => runner.getDoubleArgumentValue("return_duct_surface_area", user_arguments),
             :mech_vent_fan_type => runner.getStringArgumentValue("mech_vent_fan_type", user_arguments),
             :mech_vent_tested_flow_rate => runner.getDoubleArgumentValue("mech_vent_tested_flow_rate", user_arguments),
             :mech_vent_rated_flow_rate => runner.getDoubleArgumentValue("mech_vent_rated_flow_rate", user_arguments),
             :mech_vent_hours_in_operation => runner.getDoubleArgumentValue("mech_vent_hours_in_operation", user_arguments),
             :mech_vent_total_recovery_efficiency => runner.getDoubleArgumentValue("mech_vent_total_recovery_efficiency", user_arguments),
             :mech_vent_adjusted_total_recovery_efficiency => runner.getDoubleArgumentValue("mech_vent_adjusted_total_recovery_efficiency", user_arguments),
             :mech_vent_sensible_recovery_efficiency => runner.getDoubleArgumentValue("mech_vent_adjusted_sensible_recovery_efficiency", user_arguments),
             :mech_vent_adjusted_sensible_recovery_efficiency => runner.getDoubleArgumentValue("mech_vent_sensible_recovery_efficiency", user_arguments),
             :mech_vent_fan_power => runner.getDoubleArgumentValue("mech_vent_fan_power", user_arguments),
             :water_heater_type => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getStringArgumentValue("water_heater_type_#{n}", user_arguments) },
             :water_heater_fuel_type => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getStringArgumentValue("water_heater_fuel_type_#{n}", user_arguments) },
             :water_heater_location => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getStringArgumentValue("water_heater_location_#{n}", user_arguments) },
             :water_heater_tank_volume => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getStringArgumentValue("water_heater_tank_volume_#{n}", user_arguments) },
             :water_heater_fraction_dhw_load_served => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getDoubleArgumentValue("water_heater_fraction_dhw_load_served_#{n}", user_arguments) },
             :water_heater_heating_capacity => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getStringArgumentValue("water_heater_heating_capacity_#{n}", user_arguments) },
             :water_heater_energy_factor => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getStringArgumentValue("water_heater_energy_factor_#{n}", user_arguments) },
             :water_heater_uniform_energy_factor => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getDoubleArgumentValue("water_heater_uniform_energy_factor_#{n}", user_arguments) },
             :water_heater_recovery_efficiency => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getDoubleArgumentValue("water_heater_recovery_efficiency_#{n}", user_arguments) },
             :water_heater_uses_desuperheater => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getBoolArgumentValue("water_heater_uses_desuperheater_#{n}", user_arguments) },
             :water_heater_standby_loss => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getDoubleArgumentValue("water_heater_standby_loss_#{n}", user_arguments) },
             :water_heater_jacket_rvalue => (1..Constants.MaxNumWaterHeaters).to_a.map { |n| runner.getDoubleArgumentValue("water_heater_jacket_rvalue_#{n}", user_arguments) },
             :hot_water_distribution_system_type => runner.getStringArgumentValue("hot_water_distribution_system_type", user_arguments),
             :standard_piping_length => runner.getStringArgumentValue("standard_piping_length", user_arguments),
             :recirculation_control_type => runner.getStringArgumentValue("recirculation_control_type", user_arguments),
             :recirculation_piping_length => runner.getDoubleArgumentValue("recirculation_piping_length", user_arguments),
             :recirculation_branch_piping_length => runner.getDoubleArgumentValue("recirculation_branch_piping_length", user_arguments),
             :recirculation_pump_power => runner.getDoubleArgumentValue("recirculation_pump_power", user_arguments),
             :hot_water_distribution_pipe_r_value => runner.getDoubleArgumentValue("hot_water_distribution_pipe_r_value", user_arguments),
             :dwhr_facilities_connected => runner.getStringArgumentValue("dwhr_facilities_connected", user_arguments),
             :dwhr_equal_flow => runner.getBoolArgumentValue("dwhr_equal_flow", user_arguments),
             :dwhr_efficiency => runner.getDoubleArgumentValue("dwhr_efficiency", user_arguments),
             :shower_low_flow => runner.getBoolArgumentValue("shower_low_flow", user_arguments),
             :sink_low_flow => runner.getBoolArgumentValue("sink_low_flow", user_arguments),
             :solar_thermal_system_type => runner.getStringArgumentValue("solar_thermal_system_type", user_arguments),
             :solar_thermal_collector_area => runner.getDoubleArgumentValue("solar_thermal_collector_area", user_arguments),
             :solar_thermal_collector_loop_type => runner.getStringArgumentValue("solar_thermal_collector_loop_type", user_arguments),
             :solar_thermal_collector_type => runner.getStringArgumentValue("solar_thermal_collector_type", user_arguments),
             :solar_thermal_collector_azimuth => runner.getDoubleArgumentValue("solar_thermal_collector_azimuth", user_arguments),
             :solar_thermal_collector_tilt => runner.getDoubleArgumentValue("solar_thermal_collector_tilt", user_arguments),
             :solar_thermal_collector_rated_optical_efficiency => runner.getDoubleArgumentValue("solar_thermal_collector_rated_optical_efficiency", user_arguments),
             :solar_thermal_collector_rated_thermal_losses => runner.getDoubleArgumentValue("solar_thermal_collector_rated_thermal_losses", user_arguments),
             :solar_thermal_storage_volume => runner.getStringArgumentValue("solar_thermal_storage_volume", user_arguments),
             :solar_thermal_solar_fraction => runner.getDoubleArgumentValue("solar_thermal_solar_fraction", user_arguments),
             :pv_system_module_type => runner.getStringArgumentValue("pv_system_module_type", user_arguments),
             :pv_system_location => runner.getStringArgumentValue("pv_system_location", user_arguments),
             :pv_system_tracking => runner.getStringArgumentValue("pv_system_tracking", user_arguments),
             :pv_system_array_azimuth => runner.getDoubleArgumentValue("pv_system_array_azimuth", user_arguments),
             :pv_system_array_tilt => runner.getDoubleArgumentValue("pv_system_array_tilt", user_arguments),
             :pv_system_max_power_output => runner.getDoubleArgumentValue("pv_system_max_power_output", user_arguments),
             :pv_system_inverter_efficiency => runner.getDoubleArgumentValue("pv_system_inverter_efficiency", user_arguments),
             :pv_system_system_losses_fraction => runner.getDoubleArgumentValue("pv_system_system_losses_fraction", user_arguments),
             :has_clothes_washer => runner.getBoolArgumentValue("has_clothes_washer", user_arguments),
             :clothes_washer_location => runner.getStringArgumentValue("clothes_washer_location", user_arguments),
             :clothes_washer_integrated_modified_energy_factor => runner.getDoubleArgumentValue("clothes_washer_integrated_modified_energy_factor", user_arguments),
             :clothes_washer_rated_annual_kwh => runner.getDoubleArgumentValue("clothes_washer_rated_annual_kwh", user_arguments),
             :clothes_washer_label_electric_rate => runner.getDoubleArgumentValue("clothes_washer_label_electric_rate", user_arguments),
             :clothes_washer_label_gas_rate => runner.getDoubleArgumentValue("clothes_washer_label_gas_rate", user_arguments),
             :clothes_washer_label_annual_gas_cost => runner.getDoubleArgumentValue("clothes_washer_label_annual_gas_cost", user_arguments),
             :clothes_washer_capacity => runner.getDoubleArgumentValue("clothes_washer_capacity", user_arguments),
             :has_clothes_dryer => runner.getBoolArgumentValue("has_clothes_dryer", user_arguments),
             :clothes_dryer_location => runner.getStringArgumentValue("clothes_dryer_location", user_arguments),
             :clothes_dryer_fuel_type => runner.getStringArgumentValue("clothes_dryer_fuel_type", user_arguments),
             :clothes_dryer_energy_factor => runner.getDoubleArgumentValue("clothes_dryer_energy_factor", user_arguments),
             :clothes_dryer_combined_energy_factor => runner.getDoubleArgumentValue("clothes_dryer_combined_energy_factor", user_arguments),
             :clothes_dryer_control_type => runner.getStringArgumentValue("clothes_dryer_control_type", user_arguments),
             :has_dishwasher => runner.getBoolArgumentValue("has_dishwasher", user_arguments),
             :dishwasher_energy_factor => runner.getDoubleArgumentValue("dishwasher_energy_factor", user_arguments),
             :dishwasher_rated_annual_kwh => runner.getDoubleArgumentValue("dishwasher_rated_annual_kwh", user_arguments),
             :dishwasher_place_setting_capacity => runner.getIntegerArgumentValue("dishwasher_place_setting_capacity", user_arguments),
             :has_refrigerator => runner.getBoolArgumentValue("has_refrigerator", user_arguments),
             :refrigerator_location => runner.getStringArgumentValue("refrigerator_location", user_arguments),
             :refrigerator_rated_annual_kwh => runner.getDoubleArgumentValue("refrigerator_rated_annual_kwh", user_arguments),
             :refrigerator_adjusted_annual_kwh => runner.getDoubleArgumentValue("refrigerator_adjusted_annual_kwh", user_arguments),
             :has_cooking_range => runner.getBoolArgumentValue("has_cooking_range", user_arguments),
             :cooking_range_fuel_type => runner.getStringArgumentValue("cooking_range_fuel_type", user_arguments),
             :cooking_range_is_induction => runner.getStringArgumentValue("cooking_range_is_induction", user_arguments),
             :has_oven => runner.getBoolArgumentValue("has_oven", user_arguments),
             :oven_is_convection => runner.getStringArgumentValue("oven_is_convection", user_arguments),
             :has_lighting => runner.getBoolArgumentValue("has_lighting", user_arguments),
             :ceiling_fan_efficiency => runner.getDoubleArgumentValue("ceiling_fan_efficiency", user_arguments),
             :ceiling_fan_quantity => runner.getIntegerArgumentValue("ceiling_fan_quantity", user_arguments),
             :ceiling_fan_cooling_setpoint_temp_offset => runner.getDoubleArgumentValue("ceiling_fan_cooling_setpoint_temp_offset", user_arguments),
             :plug_loads_plug_load_type => (1..Constants.MaxNumPlugLoads).to_a.map { |n| runner.getStringArgumentValue("plug_loads_plug_load_type_#{n}", user_arguments) },
             :plug_loads_annual_kwh => (1..Constants.MaxNumPlugLoads).to_a.map { |n| runner.getDoubleArgumentValue("plug_loads_annual_kwh_#{n}", user_arguments) },
             :plug_loads_frac_sensible => (1..Constants.MaxNumPlugLoads).to_a.map { |n| runner.getDoubleArgumentValue("plug_loads_frac_sensible_#{n}", user_arguments) },
             :plug_loads_frac_latent => (1..Constants.MaxNumPlugLoads).to_a.map { |n| runner.getDoubleArgumentValue("plug_loads_frac_latent_#{n}", user_arguments) },
             :plug_loads_schedule_values => runner.getBoolArgumentValue("plug_loads_schedule_values", user_arguments),
             :plug_loads_weekday_fractions => runner.getStringArgumentValue("plug_loads_weekday_fractions", user_arguments),
             :plug_loads_weekend_fractions => runner.getStringArgumentValue("plug_loads_weekend_fractions", user_arguments),
             :plug_loads_monthly_multipliers => runner.getStringArgumentValue("plug_loads_monthly_multipliers", user_arguments) }

    # Create HPXML file
    hpxml_doc = HPXMLFile.create(runner, model, args)
    if not hpxml_doc
      runner.registerError("Unsuccessful creation of HPXML file.")
      return false
    end

    hpxml_path = args[:hpxml_path]
    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_path))
    end

    # Check for invalid HPXML file
    schemas_dir = File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources")
    skip_validation = false
    if not skip_validation
      if not validate_hpxml(runner, hpxml_path, hpxml_doc, schemas_dir)
        return false
      end
    end

    XMLHelper.write_file(hpxml_doc, hpxml_path)
    runner.registerInfo("Wrote file: #{hpxml_path}")
  end

  def validate_hpxml(runner, hpxml_path, hpxml_doc, schemas_dir)
    is_valid = true

    if schemas_dir
      unless (Pathname.new schemas_dir).absolute?
        schemas_dir = File.expand_path(File.join(File.dirname(__FILE__), schemas_dir))
      end
      unless Dir.exists?(schemas_dir)
        runner.registerError("'#{schemas_dir}' does not exist.")
        return false
      end
    else
      schemas_dir = nil
    end

    # Validate input HPXML against schema
    if not schemas_dir.nil?
      XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), runner).each do |error|
        puts error
        runner.registerError("#{hpxml_path}: #{error.to_s}")
        is_valid = false
      end
      runner.registerInfo("#{hpxml_path}: Validated against HPXML schema.")
    else
      runner.registerWarning("#{hpxml_path}: No schema dir provided, no HPXML validation performed.")
    end

    # Validate input HPXML against EnergyPlus Use Case
    errors = EnergyPlusValidator.run_validator(hpxml_doc)
    errors.each do |error|
      puts error
      runner.registerError("#{hpxml_path}: #{error}")
      is_valid = false
    end
    runner.registerInfo("#{hpxml_path}: Validated against HPXML EnergyPlus Use Case.")

    return is_valid
  end
end

class HPXMLFile
  def self.create(runner, model, args)
    hpxml_values = { :xml_type => "HPXML",
                     :xml_generated_by => "BuildResidentialHPXML",
                     :transaction => "create",
                     :building_id => "MyBuilding",
                     :event_type => "proposed workscope" }

    hpxml_doc = HPXML.create_hpxml(**hpxml_values)
    hpxml = hpxml_doc.elements["HPXML"]

    success = create_geometry_envelope(runner, model, args)
    return false if not success

    success = create_schedules(runner, model, args)
    return false if not success

    site_values = get_site_values(runner, args)
    site_neighbors_values = get_site_neighbors_values(runner, args)
    building_occupancy_values = get_building_occupancy_values(runner, args)
    building_construction_values = get_building_construction_values(runner, args)
    climate_and_risk_zones_values = get_climate_and_risk_zones_values(runner, args)
    air_infiltration_measurement_values = get_air_infiltration_measurement_values(runner, args)
    attic_values = get_attic_values(runner, model, args)
    foundation_values = get_foundation_values(runner, model, args)
    roofs_values = get_roofs_values(runner, model, args)
    rim_joists_values = get_rim_joists_values(runner, model, args)
    walls_values = get_walls_values(runner, model, args)
    foundation_walls_values = get_foundation_walls_values(runner, model, args)
    framefloors_values = get_framefloors_values(runner, model, args)
    slabs_values = get_slabs_values(runner, model, args)
    windows_values = get_windows_values(runner, model, args)
    skylights_values = get_skylights_values(runner, model, args)
    doors_values = get_doors_values(runner, model, args)
    hvac_distributions_values = []
    heating_systems_values, hvac_distributions_values = get_heating_systems_values(runner, args, hvac_distributions_values)
    cooling_systems_values, hvac_distributions_values = get_cooling_systems_values(runner, args, hvac_distributions_values)
    heat_pumps_values, hvac_distributions_values = get_heat_pumps_values(runner, args, hvac_distributions_values)
    hvac_control_values = get_hvac_control_values(runner, args)
    duct_leakage_measurements_values = get_duct_leakage_measurements_values(runner, args, hvac_distributions_values)
    ducts_values = get_ducts_values(runner, args, hvac_distributions_values)
    ventilation_fans_values = get_ventilation_fan_values(runner, args, hvac_distributions_values)
    water_heating_systems_values = get_water_heating_system_values(runner, args, heating_systems_values, cooling_systems_values, heat_pumps_values)
    hot_water_distribution_values = get_hot_water_distribution_values(runner, args)
    water_fixtures_values = get_water_fixtures_values(runner, args)
    solar_thermal_systems_values = get_solar_thermal_values(runner, args, water_heating_systems_values)
    pv_system_values = get_pv_system_values(runner, args)
    clothes_washer_values = get_clothes_washer_values(runner, args)
    clothes_dryer_values = get_clothes_dryer_values(runner, args)
    dishwasher_values = get_dishwasher_values(runner, args)
    refrigerator_values = get_refrigerator_values(runner, args)
    cooking_range_values = get_cooking_range_values(runner, args)
    oven_values = get_oven_values(runner, args)
    lighting_values = get_lighting_values(runner, args)
    ceiling_fans_values = get_ceiling_fan_values(runner, args)
    plug_loads_values = get_plug_loads_values(runner, args)
    misc_load_schedule_values = get_misc_load_schedule_values(runner, args)

    HPXML.add_site(hpxml: hpxml, **site_values) unless site_values.nil?
    site_neighbors_values.each do |site_neighbor_values|
      HPXML.add_site_neighbor(hpxml: hpxml, **site_neighbor_values)
    end
    HPXML.add_building_occupancy(hpxml: hpxml, **building_occupancy_values) unless building_occupancy_values.empty?
    HPXML.add_building_construction(hpxml: hpxml, **building_construction_values)
    HPXML.add_climate_and_risk_zones(hpxml: hpxml, **climate_and_risk_zones_values)
    HPXML.add_air_infiltration_measurement(hpxml: hpxml, **air_infiltration_measurement_values)
    HPXML.add_attic(hpxml: hpxml, **attic_values) unless attic_values.empty?
    HPXML.add_foundation(hpxml: hpxml, **foundation_values) unless foundation_values.empty?
    roofs_values.each do |roof_values|
      HPXML.add_roof(hpxml: hpxml, **roof_values)
    end
    rim_joists_values.each do |rim_joist_values|
      HPXML.add_rim_joist(hpxml: hpxml, **rim_joist_values)
    end
    walls_values.each do |wall_values|
      HPXML.add_wall(hpxml: hpxml, **wall_values)
    end
    foundation_walls_values.each do |foundation_wall_values|
      HPXML.add_foundation_wall(hpxml: hpxml, **foundation_wall_values)
    end
    framefloors_values.each do |framefloor_values|
      HPXML.add_framefloor(hpxml: hpxml, **framefloor_values)
    end
    slabs_values.each do |slab_values|
      HPXML.add_slab(hpxml: hpxml, **slab_values)
    end
    windows_values.each do |window_values|
      HPXML.add_window(hpxml: hpxml, **window_values)
    end
    skylights_values.each do |skylight_values|
      HPXML.add_skylight(hpxml: hpxml, **skylight_values)
    end
    doors_values.each do |door_values|
      HPXML.add_door(hpxml: hpxml, **door_values)
    end
    heating_systems_values.each do |heating_system_values|
      HPXML.add_heating_system(hpxml: hpxml, **heating_system_values)
    end
    cooling_systems_values.each do |cooling_system_values|
      HPXML.add_cooling_system(hpxml: hpxml, **cooling_system_values)
    end
    heat_pumps_values.each do |heat_pump_values|
      HPXML.add_heat_pump(hpxml: hpxml, **heat_pump_values)
    end
    HPXML.add_hvac_control(hpxml: hpxml, **hvac_control_values) unless hvac_control_values.empty?
    hvac_distributions_values.each_with_index do |hvac_distribution_values, i|
      hvac_distribution = HPXML.add_hvac_distribution(hpxml: hpxml, **hvac_distribution_values)
      air_distribution = hvac_distribution.elements["DistributionSystemType/AirDistribution"]
      next if air_distribution.nil?

      duct_leakage_measurements_values[i].each do |duct_leakage_measurement_values|
        HPXML.add_duct_leakage_measurement(air_distribution: air_distribution, **duct_leakage_measurement_values)
      end
      ducts_values[i].each do |duct_values|
        HPXML.add_ducts(air_distribution: air_distribution, **duct_values)
      end
    end
    ventilation_fans_values.each do |ventilation_fan_values|
      HPXML.add_ventilation_fan(hpxml: hpxml, **ventilation_fan_values)
    end
    water_heating_systems_values.each do |water_heating_system_values|
      HPXML.add_water_heating_system(hpxml: hpxml, **water_heating_system_values)
    end
    HPXML.add_hot_water_distribution(hpxml: hpxml, **hot_water_distribution_values) unless hot_water_distribution_values.empty?
    water_fixtures_values.each do |water_fixture_values|
      HPXML.add_water_fixture(hpxml: hpxml, **water_fixture_values)
    end
    solar_thermal_systems_values.each do |solar_thermal_system_values|
      HPXML.add_solar_thermal_system(hpxml: hpxml, **solar_thermal_system_values)
    end
    HPXML.add_pv_system(hpxml: hpxml, **pv_system_values) unless pv_system_values.empty?
    HPXML.add_clothes_washer(hpxml: hpxml, **clothes_washer_values) unless clothes_washer_values.empty?
    HPXML.add_clothes_dryer(hpxml: hpxml, **clothes_dryer_values) unless clothes_dryer_values.empty?
    HPXML.add_dishwasher(hpxml: hpxml, **dishwasher_values) unless dishwasher_values.empty?
    HPXML.add_refrigerator(hpxml: hpxml, **refrigerator_values) unless refrigerator_values.empty?
    HPXML.add_cooking_range(hpxml: hpxml, **cooking_range_values) unless cooking_range_values.empty?
    HPXML.add_oven(hpxml: hpxml, **oven_values) unless oven_values.empty?
    HPXML.add_lighting(hpxml: hpxml, **lighting_values) unless lighting_values.empty?
    ceiling_fans_values.each do |ceiling_fan_values|
      HPXML.add_ceiling_fan(hpxml: hpxml, **ceiling_fan_values)
    end
    plug_loads_values.each do |plug_load_values|
      HPXML.add_plug_load(hpxml: hpxml, **plug_load_values)
    end
    HPXML.add_misc_loads_schedule(hpxml: hpxml, **misc_load_schedule_values) unless misc_load_schedule_values.empty?

    HPXML.add_extension(parent: hpxml_doc.elements["/HPXML/Building/BuildingDetails"],
                        extensions: { "UnitMultiplier": args[:unit_multiplier] })

    success = remove_geometry_envelope(model)
    return false if not success

    return hpxml_doc
  end

  def self.create_geometry_envelope(runner, model, args)
    if args[:unit_type] == "single-family detached"
      success = Geometry.create_single_family_detached(runner: runner, model: model, **args)
    elsif args[:unit_type] == "single-family attached"
      success = Geometry.create_single_family_attached(runner: runner, model: model, **args)
    elsif args[:unit_type] == "multifamily"
      success = Geometry.create_multifamily(runner: runner, model: model, **args)
    end
    return false if not success

    success = Geometry.create_windows_and_skylights(runner: runner, model: model, **args)
    return false if not success

    success = Geometry.create_doors(runner: runner, model: model, **args)
    return false if not success

    return true
  end

  def self.remove_geometry_envelope(model)
    model.getSpaces.each do |space|
      space.surfaces.each do |surface|
        surface.remove
      end
      if space.thermalZone.is_initialized
        space.thermalZone.get.remove
      end
      if space.spaceType.is_initialized
        space.spaceType.get.remove
      end
      space.remove
    end

    return true
  end

  def self.create_schedules(runner, model, args)
    schedule_file = SchedulesFile.new(runner: runner, model: model, **args)

    success = schedule_file.create_occupant_schedule
    return false if not success

    success = schedule_file.create_refrigerator_schedule
    return false if not success

    success = schedule_file.export
    return false if not success

    return true
  end

  def self.get_site_values(runner, args)
    return {} if args[:shelter_coefficient] == Constants.Auto

    site_values = { :shelter_coefficient => args[:shelter_coefficient] }
    return site_values
  end

  def self.get_site_neighbors_values(runner, args)
    # FIXME: Need to incorporate building orientation
    neighbor_front_distance = args[:neighbor_distance][0]
    neighbor_back_distance = args[:neighbor_distance][1]
    neighbor_left_distance = args[:neighbor_distance][2]
    neighbor_right_distance = args[:neighbor_distance][3]

    site_neighbors_values = []
    args[:neighbor_distance].each_with_index do |distance, i|
      next if distance == 0

      azimuth = 0
      if i == 1
        azimuth = 180
      elsif i == 2
        azimuth = 90
      elsif i == 3
        azimuth == 270
      end

      if distance > 0
        if args[:neighbor_height][i] > 0
          height = args[:neighbor_height][i]
        end
      end

      site_neighbors_values << { :azimuth => azimuth,
                                 :distance => distance,
                                 :height => height }
    end
    return site_neighbors_values
  end

  def self.get_building_occupancy_values(runner, args)
    building_occupancy_values = {}
    unless args[:num_occupants] == Constants.Auto
      building_occupancy_values = { :number_of_residents => args[:num_occupants] }
    end
    building_occupancy_values[:schedules_output_path] = args[:schedules_output_path]
    building_occupancy_values[:schedules_column_name] = "occupants"
    return building_occupancy_values
  end

  def self.get_building_construction_values(runner, args)
    number_of_conditioned_floors_above_grade = args[:num_floors]
    number_of_conditioned_floors = number_of_conditioned_floors_above_grade
    if args[:foundation_type] == "basement - conditioned"
      number_of_conditioned_floors += 1
    end
    conditioned_building_volume = args[:cfa] * args[:wall_height]
    building_construction_values = { :number_of_conditioned_floors => number_of_conditioned_floors,
                                     :number_of_conditioned_floors_above_grade => number_of_conditioned_floors_above_grade,
                                     :number_of_bedrooms => args[:num_bedrooms],
                                     :number_of_bathrooms => args[:num_bathrooms],
                                     :conditioned_floor_area => args[:cfa],
                                     :conditioned_building_volume => conditioned_building_volume }
    return building_construction_values
  end

  def self.get_climate_and_risk_zones_values(runner, args)
    climate_and_risk_zones_values = { :weather_station_id => "WeatherStation",
                                      :weather_station_name => args[:weather_station_epw_filename].gsub(".epw", ""),
                                      :weather_station_epw_filename => args[:weather_station_epw_filename] }
    return climate_and_risk_zones_values
  end

  def self.get_attic_values(runner, model, args)
    return {} if args[:unit_type] == "multifamily"

    attic_values = {}
    if args[:attic_type] == "attic - vented"
      attic_values[:attic_type] = "VentedAttic"
    elsif args[:attic_type] == "attic - unvented"
      attic_values[:attic_type] = "UnventedAttic"
    end
    attic_values[:id] = attic_values[:attic_type] unless attic_values[:attic_type].nil?
    return attic_values
  end

  def self.get_foundation_values(runner, model, args)
    return {} if args[:unit_type] == "multifamily"

    foundation_values = {}
    if args[:foundation_type] == "slab"
      foundation_values[:foundation_type] = "SlabOnGrade"
    elsif args[:foundation_type] == "crawlspace - vented"
      foundation_values[:foundation_type] = "VentedCrawlspace"
      foundation_values[:vented_crawlspace_sla] = args[:vented_crawlspace_sla]
    elsif args[:foundation_type] == "crawlspace - unvented"
      foundation_values[:foundation_type] = "UnventedCrawlspace"
    elsif args[:foundation_type] == "basement - unconditioned"
      foundation_values[:foundation_type] = "UnconditionedBasement"
      foundation_values[:unconditioned_basement_thermal_boundary] = "frame floor" # FIXME: Calculate
    elsif args[:foundation_type] == "basement - conditioned"
      foundation_values[:foundation_type] = "ConditionedBasement"
    elsif args[:foundation_type] == "ambient"
      foundation_values[:foundation_type] = "Ambient"
    end
    foundation_values[:id] = foundation_values[:foundation_type]
    return foundation_values
  end

  def self.get_air_infiltration_measurement_values(runner, args)
    if args[:living_constant_ach_natural] > 0
      constant_ach_natural = args[:living_constant_ach_natural]
    else
      house_pressure = 50.0
      unit_of_measure = "ACH"
      air_leakage = args[:living_ach_50]
      infiltration_volume = args[:cfa] * args[:wall_height]
    end

    air_infiltration_measurement_values = { :id => "InfiltrationMeasurement",
                                            :house_pressure => house_pressure,
                                            :unit_of_measure => unit_of_measure,
                                            :air_leakage => air_leakage,
                                            :constant_ach_natural => constant_ach_natural,
                                            :infiltration_volume => infiltration_volume }
    return air_infiltration_measurement_values
  end

  def self.get_adjacent_to(model, surface)
    space = surface.space.get
    st = space.spaceType.get
    space_type = st.standardsSpaceType.get

    if ["vented crawlspace"].include? space_type
      return "crawlspace - vented"
    elsif ["unvented crawlspace"].include? space_type
      return "crawlspace - unvented"
    elsif ["garage"].include? space_type
      return "garage"
    elsif ["living space"].include? space_type
      if Geometry.space_is_below_grade(space)
        return "basement - conditioned"
      else
        return "living space"
      end
    elsif ["vented attic"].include? space_type
      return "attic - vented"
    elsif ["unvented attic"].include? space_type
      return "attic - unvented"
    elsif ["unconditioned basement"].include? space_type
      return "basement - unconditioned"
    elsif ["corridor"].include? space_type
      return "living space" # FIXME: update to handle new enum
    elsif ["ambient"].include? space_type
      return "outside"
    else
      fail "Unhandled SpaceType value (#{space_type}) for surface '#{surface.name}'."
    end
  end

  def self.get_roofs_values(runner, model, args)
    roofs_values = []
    model.getSurfaces.each do |surface|
      next unless ["Outdoors"].include? surface.outsideBoundaryCondition
      next if surface.surfaceType != "RoofCeiling"

      interior_adjacent_to = get_adjacent_to(model, surface)

      pitch = args[:roof_pitch] * 12.0

      roof_values = { :id => surface.name.to_s,
                      :interior_adjacent_to => get_adjacent_to(model, surface),
                      :area => UnitConversions.convert(surface.netArea, "m^2", "ft^2"),
                      :azimuth => nil, # FIXME: Get from model
                      :solar_absorptance => args[:roof_solar_absorptance],
                      :emittance => args[:roof_emittance],
                      :pitch => pitch,
                      :radiant_barrier => args[:roof_radiant_barrier] }

      if interior_adjacent_to.include? "attic"
        roof_values[:insulation_assembly_r_value] = args[:attic_ceiling_r] # FIXME: Calculate
      elsif interior_adjacent_to == "living space"
        roof_values[:insulation_assembly_r_value] = args[:roof_ceiling_r] # FIXME: Calculate
      elsif interior_adjacent_to == "garage"
        roof_values[:insulation_assembly_r_value] = args[:attic_ceiling_r] # FIXME: Calculate
      end

      roofs_values << roof_values
    end
    return roofs_values
  end

  def self.get_rim_joists_values(runner, model, args)
    rim_joists_values = []
    model.getSurfaces.each do |surface|
      # TODO
    end
    return rim_joists_values
  end

  def self.get_walls_values(runner, model, args)
    walls_values = []
    model.getSurfaces.each do |surface|
      next if surface.surfaceType != "Wall"
      next if ["ambient"].include? surface.space.get.spaceType.get.standardsSpaceType.get # FIXME

      interior_adjacent_to = get_adjacent_to(model, surface)
      next unless ["living space", "attic - unvented", "attic - vented", "garage"].include? interior_adjacent_to

      exterior_adjacent_to = "outside"
      if surface.adjacentSurface.is_initialized
        exterior_adjacent_to = get_adjacent_to(model, surface.adjacentSurface.get)
      elsif surface.outsideBoundaryCondition == "Adiabatic"
        exterior_adjacent_to = "other housing unit"
      end
      next if interior_adjacent_to == exterior_adjacent_to
      next if ["living space", "basement - conditioned"].include? exterior_adjacent_to

      wall_values = { :id => surface.name.to_s,
                      :exterior_adjacent_to => exterior_adjacent_to,
                      :interior_adjacent_to => interior_adjacent_to,
                      :wall_type => args[:wall_type],
                      :area => UnitConversions.convert(surface.netArea, "m^2", "ft^2"),
                      :azimuth => nil, # FIXME: Get from model
                      :solar_absorptance => args[:wall_solar_absorptance],
                      :emittance => args[:wall_emittance] }

      if interior_adjacent_to == "living space" and exterior_adjacent_to == "outside"
        wall_values[:insulation_assembly_r_value] = args[:wall_conditioned_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to == "garage"
        wall_values[:insulation_assembly_r_value] = args[:wall_conditioned_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to == "attic - unvented"
        wall_values[:insulation_assembly_r_value] = args[:wall_unconditioned_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to == "attic - vented"
        wall_values[:insulation_assembly_r_value] = args[:wall_unconditioned_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to == "other housing unit"
        wall_values[:insulation_assembly_r_value] = args[:wall_unconditioned_r]
      elsif ["attic - unvented", "attic - vented", "garage"].include? interior_adjacent_to
        wall_values[:insulation_assembly_r_value] = args[:wall_unconditioned_r]
      end

      walls_values << wall_values
    end
    return walls_values
  end

  def self.get_foundation_walls_values(runner, model, args)
    foundation_walls_values = []
    model.getSurfaces.each do |surface|
      next unless ["Foundation"].include? surface.outsideBoundaryCondition
      next if surface.surfaceType != "Wall"

      foundation_walls_values << { :id => surface.name.to_s,
                                   :exterior_adjacent_to => "ground",
                                   :interior_adjacent_to => get_adjacent_to(model, surface),
                                   :height => args[:foundation_height],
                                   :area => UnitConversions.convert(surface.netArea, "m^2", "ft^2"),
                                   :azimuth => nil, # FIXME: Get from model
                                   :thickness => 8,
                                   :depth_below_grade => args[:foundation_wall_depth_below_grade],
                                   :insulation_interior_r_value => 0,
                                   :insulation_interior_distance_to_top => 0,
                                   :insulation_interior_distance_to_bottom => 0,
                                   :insulation_exterior_r_value => args[:foundation_wall_r],
                                   :insulation_exterior_distance_to_top => args[:foundation_wall_distance_to_top],
                                   :insulation_exterior_distance_to_bottom => args[:foundation_wall_distance_to_bottom] }
    end
    return foundation_walls_values
  end

  def self.get_framefloors_values(runner, model, args)
    framefloors_values = []
    model.getSurfaces.each do |surface|
      next if surface.outsideBoundaryCondition == "Foundation"
      next unless ["Floor", "RoofCeiling"].include? surface.surfaceType
      next if ["ambient"].include? surface.space.get.spaceType.get.standardsSpaceType.get # FIXME

      interior_adjacent_to = get_adjacent_to(model, surface)
      next unless ["living space", "garage"].include? interior_adjacent_to

      exterior_adjacent_to = "outside"
      if surface.adjacentSurface.is_initialized
        exterior_adjacent_to = get_adjacent_to(model, surface.adjacentSurface.get)
      elsif surface.outsideBoundaryCondition == "Adiabatic"
        if surface.surfaceType == "Floor"
          exterior_adjacent_to = "other housing unit below"
        elsif surface.surfaceType == "RoofCeiling"
          exterior_adjacent_to = "other housing unit above"
        end
      end
      next if interior_adjacent_to == exterior_adjacent_to
      next if surface.surfaceType == "RoofCeiling" and exterior_adjacent_to == "outside"
      next if ["living space", "basement - conditioned"].include? exterior_adjacent_to

      framefloor_values = { :id => surface.name.to_s,
                            :exterior_adjacent_to => exterior_adjacent_to,
                            :interior_adjacent_to => interior_adjacent_to,
                            :area => UnitConversions.convert(surface.netArea, "m^2", "ft^2") }

      if interior_adjacent_to == "living space" and exterior_adjacent_to.include? "attic - unvented"
        framefloor_values[:insulation_assembly_r_value] = args[:attic_floor_conditioned_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to.include? "attic - vented"
        framefloor_values[:insulation_assembly_r_value] = args[:attic_floor_conditioned_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to.include? "crawlspace"
        framefloor_values[:insulation_assembly_r_value] = args[:foundation_ceiling_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to.include? "basement - unconditioned"
        framefloor_values[:insulation_assembly_r_value] = args[:foundation_ceiling_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to.include? "outside"
        framefloor_values[:insulation_assembly_r_value] = args[:foundation_ceiling_r]
      elsif interior_adjacent_to == "garage" and exterior_adjacent_to == "attic - unvented"
        framefloor_values[:insulation_assembly_r_value] = args[:attic_floor_unconditioned_r]
      elsif interior_adjacent_to == "garage" and exterior_adjacent_to == "attic - vented"
        framefloor_values[:insulation_assembly_r_value] = args[:attic_floor_unconditioned_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to == "garage"
        framefloor_values[:insulation_assembly_r_value] = args[:attic_floor_conditioned_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to == "other housing unit below"
        framefloor_values[:insulation_assembly_r_value] = args[:attic_floor_unconditioned_r]
      elsif interior_adjacent_to == "living space" and exterior_adjacent_to == "other housing unit above"
        framefloor_values[:insulation_assembly_r_value] = args[:attic_floor_unconditioned_r]
      end

      framefloors_values << framefloor_values
    end
    return framefloors_values
  end

  def self.get_slabs_values(runner, model, args)
    slabs_values = []
    model.getSurfaces.each do |surface|
      next unless ["Foundation"].include? surface.outsideBoundaryCondition
      next if surface.surfaceType != "Floor"
      next if ["ambient"].include? surface.space.get.spaceType.get.standardsSpaceType.get # FIXME

      interior_adjacent_to = get_adjacent_to(model, surface)

      has_foundation_walls = false
      if ["crawlspace - vented", "crawlspace - unvented", "basement - unconditioned", "basement - conditioned", "ambient"].include? interior_adjacent_to
        has_foundation_walls = true
      end
      exposed_perimeter = Geometry.calculate_exposed_perimeter(model, [surface], has_foundation_walls)

      if ["living space", "garage"].include? interior_adjacent_to
        depth_below_grade = 0
      end

      under_slab_insulation_width = args[:under_slab_insulation_width]
      if under_slab_insulation_width == 999
        under_slab_insulation_width = nil
        under_slab_insulation_spans_entire_slab = true
      end

      slabs_values << { :id => surface.name.to_s,
                        :interior_adjacent_to => interior_adjacent_to,
                        :area => UnitConversions.convert(surface.netArea, "m^2", "ft^2"),
                        :thickness => 4,
                        :exposed_perimeter => exposed_perimeter,
                        :perimeter_insulation_depth => args[:perimeter_insulation_depth],
                        :under_slab_insulation_width => under_slab_insulation_width,
                        :perimeter_insulation_r_value => args[:perimeter_insulation_r_value],
                        :under_slab_insulation_r_value => args[:under_slab_insulation_r_value],
                        :under_slab_insulation_spans_entire_slab => under_slab_insulation_spans_entire_slab,
                        :depth_below_grade => depth_below_grade,
                        :carpet_fraction => args[:carpet_fraction],
                        :carpet_r_value => args[:carpet_r_value] }
    end
    return slabs_values
  end

  def self.get_windows_values(runner, model, args)
    windows_values = []

    model.getSurfaces.each do |surface|
      surface.subSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType != "FixedWindow"

        sub_surface_height = Geometry.get_surface_height(sub_surface)
        sub_surface_facade = Geometry.get_facade_for_surface(sub_surface)

        if args[:overhangs_depth] > 0
          if ((sub_surface_facade == Constants.FacadeFront and args[:overhangs][0]) or
               (sub_surface_facade == Constants.FacadeBack and args[:overhangs][1]) or
               (sub_surface_facade == Constants.FacadeLeft and args[:overhangs][2]) or
               (sub_surface_facade == Constants.FacadeRight and args[:overhangs][3]))
            overhangs_depth = args[:overhangs_depth]
            overhangs_distance_to_top_of_window = 0.0
            overhangs_distance_to_bottom_of_window = sub_surface_height
          end
        elsif args[:eaves_depth] > 0
          eaves_z = args[:wall_height] * args[:num_floors]
          if args[:foundation_type] == "ambient"
            eaves_z += args[:foundation_height]
          end
          sub_surface_z = -9e99
          space = sub_surface.space.get
          z_origin = space.zOrigin
          sub_surface.vertices.each do |vertex|
            z = vertex.z + z_origin
            next if z < sub_surface_z

            sub_surface_z = z
          end
          sub_surface_z = UnitConversions.convert(sub_surface_z, "m", "ft")
          overhangs_depth = args[:eaves_depth]
          overhangs_distance_to_top_of_window = eaves_z - sub_surface_z
          overhangs_distance_to_bottom_of_window = overhangs_distance_to_top_of_window + sub_surface_height
        end

        window_values = { :id => sub_surface.name.to_s,
                          :area => UnitConversions.convert(sub_surface.netArea, "m^2", "ft^2"),
                          :azimuth => 0, # FIXME: Get from model
                          :ufactor => args[:window_ufactor],
                          :shgc => args[:window_shgc],
                          :overhangs_depth => overhangs_depth,
                          :overhangs_distance_to_top_of_window => overhangs_distance_to_top_of_window,
                          :overhangs_distance_to_bottom_of_window => overhangs_distance_to_bottom_of_window,
                          :wall_idref => surface.name }

        if args[:interior_shading_factor_winter][0] != 1
          window_values[:interior_shading_factor_winter] = args[:interior_shading_factor_winter][0]
        end
        if args[:interior_shading_factor_summer][0] != 1
          window_values[:interior_shading_factor_summer] = args[:interior_shading_factor_summer][0]
        end

        windows_values << window_values
      end
    end
    return windows_values
  end

  def self.get_skylights_values(runner, model, args)
    skylights_values = []
    model.getSurfaces.each do |surface|
      surface.subSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType != "Skylight"

        skylights_values << { :id => sub_surface.name.to_s,
                              :area => UnitConversions.convert(sub_surface.netArea, "m^2", "ft^2"),
                              :azimuth => 0, # FIXME: Get from model
                              :ufactor => args[:skylight_ufactor],
                              :shgc => args[:skylight_shgc],
                              :roof_idref => surface.name }
      end
    end
    return skylights_values
  end

  def self.get_doors_values(runner, model, args)
    doors_values = []
    model.getSurfaces.each do |surface|
      surface.subSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType != "Door"

        doors_values << { :id => sub_surface.name.to_s,
                          :wall_idref => surface.name,
                          :area => UnitConversions.convert(sub_surface.netArea, "m^2", "ft^2"),
                          :azimuth => 0, # FIXME: Get from model
                          :r_value => args[:door_rvalue] }
      end
    end
    return doors_values
  end

  def self.distribution_system_types
    return {
      "Furnace" => "AirDistribution",
      "WallFurnace" => nil,
      "Boiler" => "HydronicDistribution",
      "ElectricResistance" => nil,
      "Stove" => nil,
      "PortableHeater" => nil,
      "central air conditioner" => "AirDistribution",
      "room air conditioner" => nil,
      "evaporative cooler" => nil,
      "air-to-air" => "AirDistribution",
      "mini-split" => nil,
      "ground-to-air" => "AirDistribution"
    }
  end

  def self.get_hvac_distribution(runner, args, hvac_distributions_values, system_type)
    distribution_system_type = distribution_system_types[system_type]
    if system_type == "mini-split" and args[:mini_split_is_ducted]
      distribution_system_type = "AirDistribution"
    elsif system_type == "evaporative cooler" and args[:evap_cooler_is_ducted]
      distribution_system_type = "AirDistribution"
    end
    if args[:hvac_distribution_system_type_dse]
      distribution_system_type = "DSE"
      annual_heating_dse = args[:annual_heating_dse]
      annual_cooling_dse = args[:annual_cooling_dse]
    end
    unless distribution_system_type.nil?
      distribution_system_idref = "HVAC#{distribution_system_type}"
      unless hvac_distributions_values.any? { |hvac_distribution_values| hvac_distribution_values[:id] == distribution_system_idref }
        hvac_distributions_values << { :id => distribution_system_idref,
                                       :distribution_system_type => distribution_system_type,
                                       :annual_heating_dse => annual_heating_dse,
                                       :annual_cooling_dse => annual_cooling_dse }
      end
    end
    return hvac_distributions_values, distribution_system_idref
  end

  def self.get_heating_systems_values(runner, args, hvac_distributions_values)
    heating_systems_values = []

    heating_system_type = args[:heating_system_type]

    unless ["Furnace", "WallFurnace", "Boiler", "ElectricResistance", "Stove", "PortableHeater"].include? heating_system_type
      return heating_systems_values, hvac_distributions_values
    end

    hvac_distributions_values, distribution_system_idref = get_hvac_distribution(runner, args, hvac_distributions_values, heating_system_type)

    heating_capacity = args[:heating_system_heating_capacity]
    if heating_capacity == Constants.SizingAuto
      heating_capacity = -1
    end
    heating_capacity = Float(heating_capacity)

    fraction_heat_load_served = args[:heating_system_fraction_heat_load_served]
    if heating_capacity != -1
      heating_capacity *= fraction_heat_load_served
    end

    if args[:heating_system_electric_auxiliary_energy] > 0
      electric_auxiliary_energy = args[:heating_system_electric_auxiliary_energy]
    end

    if args[:heating_system_flow_rate] > 0
      heating_cfm = args[:heating_system_flow_rate]
    end

    heating_system_values = { :id => "HeatingSystem",
                              :heating_system_type => heating_system_type,
                              :distribution_system_idref => distribution_system_idref,
                              :heating_system_fuel => args[:heating_system_fuel],
                              :heating_capacity => heating_capacity,
                              :fraction_heat_load_served => fraction_heat_load_served,
                              :electric_auxiliary_energy => electric_auxiliary_energy,
                              :heating_cfm => heating_cfm }

    if ["Furnace", "WallFurnace", "Boiler"].include? heating_system_type
      heating_system_values[:heating_efficiency_afue] = args[:heating_system_heating_efficiency]
    elsif ["ElectricResistance", "Stove", "PortableHeater"]
      heating_system_values[:heating_efficiency_percent] = args[:heating_system_heating_efficiency]
    end

    heating_systems_values << heating_system_values

    return heating_systems_values, hvac_distributions_values
  end

  def self.get_cooling_systems_values(runner, args, hvac_distributions_values)
    cooling_systems_values = []

    cooling_system_type = args[:cooling_system_type]

    unless ["central air conditioner", "room air conditioner", "evaporative cooler"].include? cooling_system_type
      return cooling_systems_values, hvac_distributions_values
    end

    hvac_distributions_values, distribution_system_idref = get_hvac_distribution(runner, args, hvac_distributions_values, cooling_system_type)

    cooling_capacity = args[:cooling_system_cooling_capacity]
    if cooling_capacity == Constants.SizingAuto
      cooling_capacity = -1
    end
    cooling_capacity = Float(cooling_capacity)

    fraction_cool_load_served = args[:cooling_system_fraction_cool_load_served]
    if cooling_capacity != -1
      cooling_capacity *= fraction_cool_load_served
    end

    if cooling_system_type == "evaporative cooler"
      cooling_capacity = nil
    end

    if args[:cooling_system_flow_rate] > 0
      cooling_cfm = args[:cooling_system_flow_rate]
    end

    cooling_system_values = { :id => "CoolingSystem",
                              :cooling_system_type => cooling_system_type,
                              :distribution_system_idref => distribution_system_idref,
                              :cooling_system_fuel => args[:cooling_system_fuel],
                              :cooling_capacity => cooling_capacity,
                              :fraction_cool_load_served => fraction_cool_load_served,
                              :cooling_cfm => cooling_cfm }

    if ["central air conditioner"].include? cooling_system_type
      cooling_system_values[:cooling_efficiency_seer] = args[:cooling_system_cooling_efficiency]
    elsif ["room air conditioner"].include? cooling_system_type
      cooling_system_values[:cooling_efficiency_eer] = args[:cooling_system_cooling_efficiency]
    end

    cooling_systems_values << cooling_system_values

    return cooling_systems_values, hvac_distributions_values
  end

  def self.get_heat_pumps_values(runner, args, hvac_distributions_values)
    heat_pumps_values = []

    heating_system_type = args[:heating_system_type]
    cooling_system_type = args[:cooling_system_type]

    if not ["air-to-air", "mini-split", "ground-to-air"].include? heating_system_type and not ["air-to-air", "mini-split", "ground-to-air"].include? cooling_system_type
      return heat_pumps_values, hvac_distributions_values
    end

    heat_pump_type = heating_system_type

    hvac_distributions_values, distribution_system_idref = get_hvac_distribution(runner, args, hvac_distributions_values, heat_pump_type)

    heating_system_fuel = args[:heating_system_fuel]
    heating_system_fraction_heat_load_served = args[:heating_system_fraction_heat_load_served]

    heating_capacity = args[:heating_system_heating_capacity]
    if heating_capacity == Constants.SizingAuto
      heating_capacity = -1
    end
    heating_capacity = Float(heating_capacity)

    if ["Furnace", "WallFurnace", "Boiler", "ElectricResistance", "Stove", "PortableHeater"].include? heating_system_type
      heat_pump_type = cooling_system_type
      heating_system_fuel = "electricity"
      heating_system_fraction_heat_load_served = 0.0
    end

    if heating_capacity != -1
      heating_capacity *= heating_system_fraction_heat_load_served
    end

    if args[:heat_pump_backup_fuel] != "none"
      backup_heating_fuel = args[:heat_pump_backup_fuel]

      backup_heating_capacity = args[:heat_pump_backup_heating_capacity]
      if backup_heating_capacity == Constants.SizingAuto
        backup_heating_capacity = -1
      end
      backup_heating_capacity = Float(backup_heating_capacity)

      if backup_heating_capacity != -1
        backup_heating_capacity *= heating_system_fraction_heat_load_served
      end

      if backup_heating_fuel == "electricity"
        backup_heating_efficiency_percent = args[:heat_pump_backup_heating_efficiency]
      else
        backup_heating_efficiency_afue = args[:heat_pump_backup_heating_efficiency]
        backup_heating_switchover_temp = 25.0
      end
    end

    cooling_system_fraction_cool_load_served = args[:cooling_system_fraction_cool_load_served]

    if ["central air conditioner", "room air conditioner", "evaporative cooler"].include? cooling_system_type
      heat_pump_type = heating_system_type
      cooling_system_fraction_cool_load_served = 0.0
    end

    cooling_capacity = args[:cooling_system_cooling_capacity]
    if cooling_capacity == Constants.SizingAuto
      cooling_capacity = -1
    end
    cooling_capacity = Float(cooling_capacity)

    if cooling_capacity != -1
      cooling_capacity *= cooling_system_fraction_cool_load_served
    end

    heat_pump_values = { :id => "HeatPump",
                         :heat_pump_type => heat_pump_type,
                         :distribution_system_idref => distribution_system_idref,
                         :heat_pump_fuel => heating_system_fuel,
                         :heating_capacity => heating_capacity,
                         :cooling_capacity => cooling_capacity,
                         :fraction_heat_load_served => heating_system_fraction_heat_load_served,
                         :fraction_cool_load_served => cooling_system_fraction_cool_load_served,
                         :backup_heating_fuel => backup_heating_fuel,
                         :backup_heating_capacity => backup_heating_capacity,
                         :backup_heating_efficiency_afue => backup_heating_efficiency_afue,
                         :backup_heating_efficiency_percent => backup_heating_efficiency_percent,
                         :backup_heating_switchover_temp => backup_heating_switchover_temp }

    if ["air-to-air", "mini-split", "Furnace", "WallFurnace", "Boiler", "ElectricResistance", "Stove", "PortableHeater"].include? heating_system_type
      heat_pump_values[:heating_efficiency_hspf] = args[:heating_system_heating_efficiency]
    elsif ["ground-to-air"].include? heating_system_type
      heat_pump_values[:heating_efficiency_cop] = args[:heating_system_heating_efficiency]
    end

    if ["air-to-air", "mini-split", "central air conditioner", "room air conditioner", "evaporative cooler"].include? cooling_system_type
      heat_pump_values[:cooling_efficiency_seer] = args[:cooling_system_cooling_efficiency]
    elsif ["ground-to-air"].include? cooling_system_type
      heat_pump_values[:cooling_efficiency_eer] = args[:cooling_system_cooling_efficiency]
    end

    heat_pumps_values << heat_pump_values

    return heat_pumps_values, hvac_distributions_values
  end

  def self.get_hvac_control_values(runner, args)
    hvac_control_values = { :id => "HVACControl",
                            :control_type => args[:hvac_control_type],
                            :heating_setpoint_temp => args[:heating_setpoint_temp],
                            :cooling_setpoint_temp => args[:cooling_setpoint_temp] }

    if args[:heating_setpoint_temp] != args[:heating_setback_temp]
      hvac_control_values[:heating_setback_temp] = args[:heating_setback_temp]
      hvac_control_values[:heating_setback_hours_per_week] = args[:heating_setback_hours_per_week]
      hvac_control_values[:heating_setback_start_hour] = args[:heating_setback_start_hour]
    end

    if args[:cooling_setpoint_temp] != args[:cooling_setup_temp]
      hvac_control_values[:cooling_setup_temp] = args[:cooling_setup_temp]
      hvac_control_values[:cooling_setup_hours_per_week] = args[:cooling_setup_hours_per_week]
      hvac_control_values[:cooling_setup_start_hour] = args[:cooling_setup_start_hour]
    end

    if args[:ceiling_fan_cooling_setpoint_temp_offset] > 0
      hvac_control_values[:ceiling_fan_cooling_setpoint_temp_offset] = args[:ceiling_fan_cooling_setpoint_temp_offset]
    end

    return hvac_control_values
  end

  def self.get_duct_leakage_measurements_values(runner, args, hvac_distributions_values)
    duct_leakage_measurements_values = []
    hvac_distributions_values.each_with_index do |hvac_distribution_values, i|
      if hvac_distribution_values[:distribution_system_type] == "AirDistribution"
        duct_leakage_measurements_values << [{ :duct_type => "supply",
                                               :duct_leakage_units => args[:supply_duct_leakage_units],
                                               :duct_leakage_value => args[:supply_duct_leakage_value] },
                                             { :duct_type => "return",
                                               :duct_leakage_units => args[:return_duct_leakage_units],
                                               :duct_leakage_value => args[:return_duct_leakage_value] }]
      else
        duct_leakage_measurements_values << []
      end
    end
    return duct_leakage_measurements_values
  end

  def self.get_ducts_values(runner, args, hvac_distributions_values)
    ducts_values = []
    hvac_distributions_values.each_with_index do |hvac_distribution_values, i|
      if hvac_distribution_values[:distribution_system_type] == "AirDistribution"

        supply_duct_location = args[:supply_duct_location]
        if supply_duct_location == Constants.Auto
          supply_duct_location = "living space" # FIXME
        end

        return_duct_location = args[:return_duct_location]
        if return_duct_location == Constants.Auto
          return_duct_location = "living space" # FIXME
        end

        ducts_values << [{ :duct_type => "supply",
                           :duct_insulation_r_value => args[:supply_duct_insulation_r_value],
                           :duct_location => supply_duct_location,
                           :duct_surface_area => args[:supply_duct_surface_area] },
                         { :duct_type => "return",
                           :duct_insulation_r_value => args[:return_duct_insulation_r_value],
                           :duct_location => return_duct_location,
                           :duct_surface_area => args[:return_duct_surface_area] }]
      else
        ducts_values << []
      end
    end
    return ducts_values
  end

  def self.get_ventilation_fan_values(runner, args, hvac_distributions_values)
    return [] if args[:mech_vent_fan_type] == "none"

    tested_flow_rate = args[:mech_vent_tested_flow_rate]
    if args[:mech_vent_rated_flow_rate] > 0
      rated_flow_rate = args[:mech_vent_rated_flow_rate]
      tested_flow_rate = nil
    end

    if args[:mech_vent_fan_type].include? "recovery ventilator"
      if args[:mech_vent_fan_type].include? "energy"
        total_recovery_efficiency = args[:mech_vent_total_recovery_efficiency]
        if args[:mech_vent_adjusted_total_recovery_efficiency] > 0
          total_recovery_efficiency_adjusted = args[:mech_vent_adjusted_total_recovery_efficiency]
          total_recovery_efficiency = nil
        end
      end
      sensible_recovery_efficiency = args[:mech_vent_sensible_recovery_efficiency]
      if args[:mech_vent_adjusted_sensible_recovery_efficiency] > 0
        sensible_recovery_efficiency_adjusted = args[:mech_vent_adjusted_sensible_recovery_efficiency]
        sensible_recovery_efficiency = nil
      end
    end

    distribution_system_idref = nil
    if args[:mech_vent_fan_type] == "central fan integrated supply"
      hvac_distributions_values.each do |hvac_distribution_values|
        next unless hvac_distribution_values[:distribution_system_type] == "AirDistribution"

        distribution_system_idref = hvac_distribution_values[:id]
      end
    end

    ventilation_fans_values = [{ :id => "MechanicalVentilation",
                                 :fan_type => args[:mech_vent_fan_type],
                                 :tested_flow_rate => tested_flow_rate,
                                 :rated_flow_rate => rated_flow_rate,
                                 :hours_in_operation => args[:mech_vent_hours_in_operation],
                                 :total_recovery_efficiency => total_recovery_efficiency,
                                 :total_recovery_efficiency_adjusted => total_recovery_efficiency_adjusted,
                                 :sensible_recovery_efficiency => sensible_recovery_efficiency,
                                 :sensible_recovery_efficiency_adjusted => sensible_recovery_efficiency_adjusted,
                                 :fan_power => args[:mech_vent_fan_power],
                                 :distribution_system_idref => distribution_system_idref }]
    return ventilation_fans_values
  end

  def self.get_water_heating_system_values(runner, args, heating_systems_values, cooling_systems_values, heat_pumps_values)
    num_water_heaters = 0
    args[:water_heater_type].each do |water_heater_type|
      next if water_heater_type == "none"

      num_water_heaters += 1
    end

    water_heating_systems_values = []
    args[:water_heater_type].each_with_index do |water_heater_type, i|
      next if water_heater_type == "none"

      fuel_type = args[:water_heater_fuel_type][i]

      location = args[:water_heater_location][i]
      if location == Constants.Auto
        location = "living space" # FIXME
      end

      tank_volume = Waterheater.calc_nom_tankvol(args[:water_heater_tank_volume][i], fuel_type, args[:num_bedrooms], args[:num_bathrooms])

      heating_capacity = args[:water_heater_heating_capacity][i]
      if heating_capacity == Constants.SizingAuto
        heating_capacity = Waterheater.calc_water_heater_capacity(fuel_type, args[:num_bedrooms], num_water_heaters, args[:num_bathrooms])
      else
        heating_capacity = Float(heating_capacity)
      end
      heating_capacity = UnitConversions.convert(heating_capacity, "kBtu/hr", "Btu/hr")

      if water_heater_type == "heat pump water heater"
        heating_capacity = nil
      end

      energy_factor = Waterheater.calc_ef(args[:water_heater_energy_factor][i], tank_volume, fuel_type)
      if args[:water_heater_uniform_energy_factor][i] > 0
        energy_factor = nil
        uniform_energy_factor = args[:water_heater_uniform_energy_factor][i]
      end

      recovery_efficiency = args[:water_heater_recovery_efficiency][i]
      if fuel_type == "electricity"
        recovery_efficiency = nil
      end

      if args[:water_heater_uses_desuperheater][i]
        uses_desuperheater = args[:water_heater_uses_desuperheater][i]
        unless cooling_systems_values[i].nil?
          related_hvac = cooling_systems_values[i][:id]
        end
        unless heat_pumps_values[i].nil?
          related_hvac = heat_pumps_values[i][:id]
        end
      end

      if water_heater_type == "space-heating boiler with tankless coil"
        fuel_type = nil
        tank_volume = nil
        heating_capacity = nil
        energy_factor = nil
        related_hvac = heating_systems_values[i][:id]
      elsif water_heater_type == "space-heating boiler with storage tank"
        fuel_type = nil
        heating_capacity = nil
        energy_factor = nil
        related_hvac = heating_systems_values[i][:id]
      end

      standby_loss = nil
      if args[:water_heater_standby_loss][i] > 0
        standby_loss = args[:water_heater_standby_loss][i]
      end

      jacket_r_value = nil
      if args[:water_heater_jacket_rvalue][i] > 0
        jacket_r_value = args[:water_heater_jacket_rvalue][i]
      end

      water_heating_systems_values << { :id => "WaterHeater#{i + 1}",
                                        :water_heater_type => water_heater_type,
                                        :fuel_type => fuel_type,
                                        :location => location,
                                        :tank_volume => tank_volume,
                                        :fraction_dhw_load_served => args[:water_heater_fraction_dhw_load_served][i],
                                        :heating_capacity => heating_capacity,
                                        :energy_factor => energy_factor,
                                        :uniform_energy_factor => uniform_energy_factor,
                                        :recovery_efficiency => recovery_efficiency,
                                        :uses_desuperheater => uses_desuperheater,
                                        :related_hvac => related_hvac,
                                        :standby_loss => standby_loss,
                                        :jacket_r_value => jacket_r_value }
    end
    return water_heating_systems_values
  end

  def self.get_hot_water_distribution_values(runner, args)
    return {} if args[:water_heater_type][0] == "none" and args[:water_heater_type][1] == "none"

    if args[:dwhr_facilities_connected] != "none"
      dwhr_facilities_connected = args[:dwhr_facilities_connected]
      dwhr_equal_flow = args[:dwhr_equal_flow]
      dwhr_efficiency = args[:dwhr_efficiency]
    end

    hot_water_distribution_values = { :id => "HotWaterDistribution",
                                      :system_type => args[:hot_water_distribution_system_type],
                                      :standard_piping_length => args[:standard_piping_length],
                                      :recirculation_control_type => args[:recirculation_control_type],
                                      :recirculation_piping_length => args[:recirculation_piping_length],
                                      :recirculation_branch_piping_length => args[:recirculation_branch_piping_length],
                                      :recirculation_pump_power => args[:recirculation_pump_power],
                                      :pipe_r_value => args[:hot_water_distribution_pipe_r_value],
                                      :dwhr_facilities_connected => dwhr_facilities_connected,
                                      :dwhr_equal_flow => dwhr_equal_flow,
                                      :dwhr_efficiency => dwhr_efficiency }
    return hot_water_distribution_values
  end

  def self.get_water_fixtures_values(runer, args)
    return {} if args[:water_heater_type][0] == "none" and args[:water_heater_type][1] == "none"

    water_fixtures_values = [{ :id => "ShowerFixture",
                               :water_fixture_type => "shower head",
                               :low_flow => args[:shower_low_flow], },
                             { :id => "SinkFixture",
                               :water_fixture_type => "faucet",
                               :low_flow => args[:sink_low_flow] }]
    return water_fixtures_values
  end

  def self.get_solar_thermal_values(runner, args, water_heating_systems_values)
    return [] if args[:solar_thermal_system_type] == "none"

    solar_thermal_systems_values = []
    water_heating_systems_values.each do |water_heating_system_values|
      collector_area = args[:solar_thermal_collector_area]
      collector_loop_type = args[:solar_thermal_collector_loop_type]
      collector_type = args[:solar_thermal_collector_type]
      collector_azimuth = args[:solar_thermal_collector_azimuth]
      collector_tilt = args[:solar_thermal_collector_tilt]
      collector_frta = args[:solar_thermal_collector_rated_optical_efficiency]
      collector_frul = args[:solar_thermal_collector_rated_thermal_losses]

      storage_volume = args[:solar_thermal_storage_volume]
      if storage_volume == Constants.Auto
        storage_volume = 60 # FIXME
      end

      if args[:solar_thermal_solar_fraction] > 0
        collector_area = nil
        collector_loop_type = nil
        collector_type = nil
        collector_azimuth = nil
        collector_tilt = nil
        collector_frta = nil
        collector_frul = nil
        storage_volume = nil
        solar_fraction = args[:solar_thermal_solar_fraction]
      end

      solar_thermal_systems_values << { :id => "SolarThermalSystem",
                                        :system_type => args[:solar_thermal_system_type],
                                        :collector_area => collector_area,
                                        :collector_loop_type => collector_loop_type,
                                        :collector_type => collector_type,
                                        :collector_azimuth => collector_azimuth,
                                        :collector_tilt => collector_tilt,
                                        :collector_frta => collector_frta,
                                        :collector_frul => collector_frul,
                                        :storage_volume => storage_volume,
                                        :water_heating_system_idref => water_heating_system_values[:id],
                                        :solar_fraction => solar_fraction }
    end
    return solar_thermal_systems_values
  end

  def self.get_pv_system_values(runner, args)
    return {} if args[:pv_system_module_type] == "none"

    pv_system_values = { :id => "PVSystem",
                         :location => args[:pv_system_location],
                         :module_type => args[:pv_system_module_type],
                         :tracking => args[:pv_system_tracking],
                         :array_azimuth => args[:pv_system_array_azimuth],
                         :array_tilt => args[:pv_system_array_tilt],
                         :max_power_output => args[:pv_system_max_power_output],
                         :inverter_efficiency => args[:pv_system_inverter_efficiency],
                         :system_losses_fraction => args[:pv_system_system_losses_fraction] }
    return pv_system_values
  end

  def self.get_clothes_washer_values(runner, args)
    return {} unless args[:has_clothes_washer]

    location = args[:clothes_washer_location]
    if location == Constants.Auto
      location = "living space" # FIXME
    end

    clothes_washer_values = { :id => "ClothesWasher",
                              :location => location,
                              :integrated_modified_energy_factor => args[:clothes_washer_integrated_modified_energy_factor],
                              :rated_annual_kwh => args[:clothes_washer_rated_annual_kwh],
                              :label_electric_rate => args[:clothes_washer_label_electric_rate],
                              :label_gas_rate => args[:clothes_washer_label_gas_rate],
                              :label_annual_gas_cost => args[:clothes_washer_label_annual_gas_cost],
                              :capacity => args[:clothes_washer_capacity] }
    return clothes_washer_values
  end

  def self.get_clothes_dryer_values(runner, args)
    return {} unless args[:has_clothes_dryer]

    energy_factor = nil
    if args[:clothes_dryer_energy_factor] > 0
      energy_factor = args[:clothes_dryer_energy_factor]
    end

    combined_energy_factor = nil
    if args[:clothes_dryer_combined_energy_factor] > 0
      combined_energy_factor = args[:clothes_dryer_combined_energy_factor]
    end

    location = args[:clothes_dryer_location]
    if location == Constants.Auto
      location = "living space" # FIXME
    end

    clothes_dryer_values = { :id => "ClothesDryer",
                             :location => location,
                             :fuel_type => args[:clothes_dryer_fuel_type],
                             :energy_factor => energy_factor,
                             :combined_energy_factor => combined_energy_factor,
                             :control_type => args[:clothes_dryer_control_type] }
    return clothes_dryer_values
  end

  def self.get_dishwasher_values(runner, args)
    return {} unless args[:has_dishwasher]

    if args[:dishwasher_energy_factor] > 0
      energy_factor = args[:dishwasher_energy_factor]
    end

    if args[:dishwasher_rated_annual_kwh] > 0
      rated_annual_kwh = args[:dishwasher_rated_annual_kwh]
    end

    dishwasher_values = { :id => "Dishwasher",
                          :energy_factor => energy_factor,
                          :rated_annual_kwh => rated_annual_kwh,
                          :place_setting_capacity => args[:dishwasher_place_setting_capacity] }
    return dishwasher_values
  end

  def self.get_refrigerator_values(runner, args)
    return {} unless args[:has_refrigerator]

    location = args[:refrigerator_location]
    if location == Constants.Auto
      location = "living space" # FIXME
    end

    if args[:refrigerator_adjusted_annual_kwh] > 0
      adjusted_annual_kwh = args[:refrigerator_adjusted_annual_kwh]
    end

    refrigerator_values = { :id => "Refrigerator",
                            :location => location,
                            :rated_annual_kwh => args[:refrigerator_rated_annual_kwh],
                            :adjusted_annual_kwh => adjusted_annual_kwh,
                            :schedules_output_path => args[:schedules_output_path],
                            :schedules_column_name => "refrigerator" }
    return refrigerator_values
  end

  def self.get_cooking_range_values(runner, args)
    return {} unless args[:has_cooking_range]

    cooking_range_values = { :id => "CookingRange",
                             :fuel_type => args[:cooking_range_fuel_type],
                             :is_induction => args[:cooking_range_is_induction] }
    return cooking_range_values
  end

  def self.get_oven_values(runner, args)
    return {} unless args[:has_oven]

    oven_values = { :id => "Oven",
                    :is_convection => args[:oven_is_convection] }
    return oven_values
  end

  def self.get_lighting_values(runner, args)
    return {} unless args[:has_lighting]

    lighting_values = { :fraction_tier_i_interior => 0.5,
                        :fraction_tier_i_exterior => 0.5,
                        :fraction_tier_i_garage => 0.5,
                        :fraction_tier_ii_interior => 0.25,
                        :fraction_tier_ii_exterior => 0.25,
                        :fraction_tier_ii_garage => 0.25 }
    return lighting_values
  end

  def self.get_ceiling_fan_values(runner, args)
    return [] if args[:ceiling_fan_quantity] == 0

    ceiling_fans_values = [{ :id => "CeilingFan",
                             :efficiency => args[:ceiling_fan_efficiency],
                             :quantity => args[:ceiling_fan_quantity] }]
    return ceiling_fans_values
  end

  def self.get_plug_loads_values(runner, args)
    plug_loads_values = []
    args[:plug_loads_plug_load_type].each_with_index do |plug_load_type, i|
      next if plug_load_type == "none"

      if args[:plug_loads_annual_kwh][i] > 0
        kWh_per_year = args[:plug_loads_annual_kwh][i]
      end

      if args[:plug_loads_frac_sensible][i] > 0
        frac_sensible = args[:plug_loads_frac_sensible][i]
      end

      if args[:plug_loads_frac_latent][i] > 0
        frac_latent = args[:plug_loads_frac_latent][i]
      end

      plug_loads_values << { :id => "PlugLoadMisc#{i + 1}",
                             :plug_load_type => plug_load_type,
                             :kWh_per_year => kWh_per_year,
                             :frac_sensible => frac_sensible,
                             :frac_latent => frac_latent }
    end
    return plug_loads_values
  end

  def self.get_misc_load_schedule_values(runner, args)
    return {} unless args[:plug_loads_schedule_values]

    misc_load_schedule_values = { :weekday_fractions => args[:plug_loads_weekday_fractions],
                                  :weekend_fractions => args[:plug_loads_weekend_fractions],
                                  :monthly_multipliers => args[:plug_loads_monthly_multipliers] }
    return misc_load_schedule_values
  end
end

# register the measure to be used by the application
BuildResidentialHPXML.new.registerWithApplication
