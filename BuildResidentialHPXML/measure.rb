# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'

require_relative 'resources/geometry'
require_relative 'resources/schedules'
require_relative 'resources/waterheater'
require_relative 'resources/constants'
require_relative 'resources/location'

require_relative '../HPXMLtoOpenStudio/resources/EPvalidator'
require_relative '../HPXMLtoOpenStudio/resources/constructions'
require_relative '../HPXMLtoOpenStudio/resources/hpxml'
require_relative '../HPXMLtoOpenStudio/resources/schedules'
require_relative '../HPXMLtoOpenStudio/resources/waterheater'

# start the measure
class BuildResidentialHPXML < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'HPXML Builder'
  end

  # human readable description
  def description
    return 'Builds a residential HPXML file.'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', true)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_timestep', false)
    arg.setDisplayName('Simulation Control: Timestep')
    arg.setUnits('min')
    arg.setDescription('Value must be a divisor of 60.')
    arg.setDefaultValue(60)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_output_path', true)
    arg.setDisplayName('Schedules Output File Path')
    arg.setDescription('Absolute (or relative) path of the output schedules file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('weather_station_epw_filename', true)
    arg.setDisplayName('EnergyPlus Weather (EPW) Filename')
    arg.setDescription('Name of the EPW file.')
    arg.setDefaultValue('USA_CO_Denver.Intl.AP.725650_TMY3.epw')
    args << arg

    unit_type_choices = OpenStudio::StringVector.new
    unit_type_choices << 'single-family detached'
    unit_type_choices << 'single-family attached'
    unit_type_choices << 'multifamily'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('unit_type', unit_type_choices, true)
    arg.setDisplayName('Geometry: Unit Type')
    arg.setDescription('The type of unit.')
    arg.setDefaultValue('single-family detached')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('unit_multiplier', true)
    arg.setDisplayName('Geometry: Unit Multiplier')
    arg.setUnits('#')
    arg.setDescription('The number of actual units this single unit represents.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cfa', true)
    arg.setDisplayName('Geometry: Conditioned Floor Area')
    arg.setUnits('ft^2')
    arg.setDescription('The total floor area of the conditioned space (including any conditioned basement floor area).')
    arg.setDefaultValue(2000.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('wall_height', true)
    arg.setDisplayName('Geometry: Wall Height (Per Floor)')
    arg.setUnits('ft')
    arg.setDescription('The height of the living space (and garage) walls.')
    arg.setDefaultValue(8.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('num_units', true)
    arg.setDisplayName('Geometry: Number of Units')
    arg.setUnits('#')
    arg.setDescription('The number of units in the building. This is not used for single-family detached buildings.')
    arg.setDefaultValue(2)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('num_floors', true)
    arg.setDisplayName('Geometry: Number of Floors')
    arg.setUnits('#')
    arg.setDescription('The number of floors above grade (in the unit if single-family, and in the building if multifamily).')
    arg.setDefaultValue(2)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('aspect_ratio', true)
    arg.setDisplayName('Geometry: Aspect Ratio')
    arg.setUnits('FB/LR')
    arg.setDescription('The ratio of the front/back wall length to the left/right wall length, excluding any protruding garage wall area.')
    arg.setDefaultValue(2.0)
    args << arg

    level_choices = OpenStudio::StringVector.new
    level_choices << 'Bottom'
    level_choices << 'Middle'
    level_choices << 'Top'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('level', level_choices, true)
    arg.setDisplayName('Geometry: Level')
    arg.setDescription('The level of the unit.')
    arg.setDefaultValue('Bottom')
    args << arg

    horizontal_location_choices = OpenStudio::StringVector.new
    horizontal_location_choices << 'Left'
    horizontal_location_choices << 'Middle'
    horizontal_location_choices << 'Right'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('horizontal_location', horizontal_location_choices, true)
    arg.setDisplayName('Geometry: Horizontal Location')
    arg.setDescription('The horizontal location of the unit when viewing the front of the building.')
    arg.setDefaultValue('Left')
    args << arg

    corridor_position_choices = OpenStudio::StringVector.new
    corridor_position_choices << 'Double-Loaded Interior'
    corridor_position_choices << 'Single Exterior (Front)'
    corridor_position_choices << 'Double Exterior'
    corridor_position_choices << 'None'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('corridor_position', corridor_position_choices, true)
    arg.setDisplayName('Geometry: Corridor Position')
    arg.setDescription('The position of the corridor.')
    arg.setDefaultValue('Double-Loaded Interior')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('corridor_width', true)
    arg.setDisplayName('Geometry: Corridor Width')
    arg.setUnits('ft')
    arg.setDescription('The width of the corridor.')
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('inset_width', true)
    arg.setDisplayName('Geometry: Inset Width')
    arg.setUnits('ft')
    arg.setDescription('The width of the inset.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('inset_depth', true)
    arg.setDisplayName('Geometry: Inset Depth')
    arg.setUnits('ft')
    arg.setDescription('The depth of the inset.')
    arg.setDefaultValue(0.0)
    args << arg

    inset_position_choices = OpenStudio::StringVector.new
    inset_position_choices << 'Right'
    inset_position_choices << 'Left'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('inset_position', inset_position_choices, true)
    arg.setDisplayName('Geometry: Inset Position')
    arg.setDescription('The position of the inset.')
    arg.setDefaultValue('Right')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('balcony_depth', true)
    arg.setDisplayName('Geometry: Balcony Depth')
    arg.setUnits('ft')
    arg.setDescription('The depth of the balcony.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('garage_width', true)
    arg.setDisplayName('Geometry: Garage Width')
    arg.setUnits('ft')
    arg.setDescription('The width of the garage.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('garage_depth', true)
    arg.setDisplayName('Geometry: Garage Depth')
    arg.setUnits('ft')
    arg.setDescription('The depth of the garage.')
    arg.setDefaultValue(20.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('garage_protrusion', true)
    arg.setDisplayName('Geometry: Garage Protrusion')
    arg.setUnits('frac')
    arg.setDescription('The fraction of the garage that is protruding from the living space.')
    arg.setDefaultValue(0.0)
    args << arg

    garage_position_choices = OpenStudio::StringVector.new
    garage_position_choices << 'Right'
    garage_position_choices << 'Left'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('garage_position', garage_position_choices, true)
    arg.setDisplayName('Geometry: Garage Position')
    arg.setDescription('The position of the garage.')
    arg.setDefaultValue('Right')
    args << arg

    foundation_type_choices = OpenStudio::StringVector.new
    foundation_type_choices << HPXML::FoundationTypeSlab
    foundation_type_choices << HPXML::FoundationTypeCrawlspaceVented
    foundation_type_choices << HPXML::FoundationTypeCrawlspaceUnvented
    foundation_type_choices << HPXML::FoundationTypeBasementUnconditioned
    foundation_type_choices << HPXML::FoundationTypeBasementConditioned
    foundation_type_choices << HPXML::FoundationTypeAmbient

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('foundation_type', foundation_type_choices, true)
    arg.setDisplayName('Geometry: Foundation Type')
    arg.setDescription('The foundation type of the building.')
    arg.setDefaultValue(HPXML::FoundationTypeSlab)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('foundation_height', true)
    arg.setDisplayName('Geometry: Foundation Height')
    arg.setUnits('ft')
    arg.setDescription('The height of the foundation (e.g., 3ft for crawlspace, 8ft for basement).')
    arg.setDefaultValue(3.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('foundation_ceiling_r', true)
    arg.setDisplayName('Foundation: Ceiling Insulation Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the overall R-value of the assembly.')
    arg.setDefaultValue(30)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('foundation_wall_r', true)
    arg.setDisplayName('Foundation: Wall Insulation R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the overall R-value of the assembly.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('foundation_wall_distance_to_top', true)
    arg.setDisplayName('Foundation: Wall Insulation Distance To Top')
    arg.setUnits('ft')
    arg.setDescription('The distance to the top of the foundation wall insulation.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('foundation_wall_distance_to_bottom', true)
    arg.setDisplayName('Foundation: Wall Insulation Distance To Bottom')
    arg.setUnits('ft')
    arg.setDescription('The distance to the bottom of the foundation wall insulation.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('foundation_wall_depth_below_grade', true)
    arg.setDisplayName('Foundation: Wall Depth Below Grade')
    arg.setUnits('ft')
    arg.setDescription('The depth below grade of the foundation wall.')
    arg.setDefaultValue(3.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('slab_perimeter_r', true)
    arg.setDisplayName('Slab: Perimeter Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the nominal R-value of the perimeter insulation.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('slab_perimeter_depth', true)
    arg.setDisplayName('Slab: Perimeter Insulation Depth')
    arg.setUnits('ft')
    arg.setDescription('Refers to the depth of the perimeter insulation.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('slab_under_r', true)
    arg.setDisplayName('Slab: Under Slab Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the nominal R-value of the under slab insulation.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('slab_under_width', true)
    arg.setDisplayName('Slab: Under Slab Insulation Width')
    arg.setUnits('ft')
    arg.setDescription('Refers to the width of the under slab insulation. Enter 999 to specify that the under slab insulation spans the entire slab.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('carpet_fraction', true)
    arg.setDisplayName('Carpet: Fraction')
    arg.setUnits('Frac')
    arg.setDescription('Fraction of the carpet.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('carpet_r_value', true)
    arg.setDisplayName('Carpet: R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('R-value of the carpet.')
    arg.setDefaultValue(0)
    args << arg

    attic_type_choices = OpenStudio::StringVector.new
    attic_type_choices << HPXML::AtticTypeVented
    attic_type_choices << HPXML::AtticTypeUnvented
    attic_type_choices << HPXML::AtticTypeConditioned

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('attic_type', attic_type_choices, true)
    arg.setDisplayName('Geometry: Attic Type')
    arg.setDescription('The attic type of the building. Ignored if the building has a flat roof.')
    arg.setDefaultValue(HPXML::AtticTypeVented)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('attic_floor_conditioned_r', true)
    arg.setDisplayName('Attic: Floor (Adjacent To Conditioned) Insulation Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the overall R-value of the assembly.')
    arg.setDefaultValue(30)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('attic_floor_unconditioned_r', true)
    arg.setDisplayName('Attic: Floor (Adjacent To Unconditioned) Insulation Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the overall R-value of the assembly.')
    arg.setDefaultValue(2.1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('attic_ceiling_r', true)
    arg.setDisplayName('Attic: Ceiling Insulation Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the overall R-value of the assembly.')
    arg.setDefaultValue(2.3)
    args << arg

    roof_type_choices = OpenStudio::StringVector.new
    roof_type_choices << 'gable'
    roof_type_choices << 'hip'
    roof_type_choices << 'flat'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('roof_type', roof_type_choices, true)
    arg.setDisplayName('Geometry: Roof Type')
    arg.setDescription('The roof type of the building.')
    arg.setDefaultValue('gable')
    args << arg

    roof_pitch_choices = OpenStudio::StringVector.new
    roof_pitch_choices << '1:12'
    roof_pitch_choices << '2:12'
    roof_pitch_choices << '3:12'
    roof_pitch_choices << '4:12'
    roof_pitch_choices << '5:12'
    roof_pitch_choices << '6:12'
    roof_pitch_choices << '7:12'
    roof_pitch_choices << '8:12'
    roof_pitch_choices << '9:12'
    roof_pitch_choices << '10:12'
    roof_pitch_choices << '11:12'
    roof_pitch_choices << '12:12'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('roof_pitch', roof_pitch_choices, true)
    arg.setDisplayName('Geometry: Roof Pitch')
    arg.setDescription('The roof pitch of the attic. Ignored if the building has a flat roof.')
    arg.setDefaultValue('6:12')
    args << arg

    roof_structure_choices = OpenStudio::StringVector.new
    roof_structure_choices << 'truss, cantilever'
    roof_structure_choices << 'rafter'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('roof_structure', roof_structure_choices, true)
    arg.setDisplayName('Geometry: Roof Structure')
    arg.setDescription('The roof structure of the building.')
    arg.setDefaultValue('truss, cantilever')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('roof_ceiling_r', true)
    arg.setDisplayName('Roof: Ceiling Insulation Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the overall R-value of the assembly.')
    arg.setDefaultValue(2.3)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('roof_solar_absorptance', true)
    arg.setDisplayName('Roof: Solar Absorptance')
    arg.setDescription('The solar absorptance of the roof.')
    arg.setDefaultValue(0.7)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('roof_emittance', true)
    arg.setDisplayName('Roof: Emittance')
    arg.setDescription('The emittance of the roof.')
    arg.setDefaultValue(0.92)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('roof_radiant_barrier', true)
    arg.setDisplayName('Roof: Has Radiant Barrier')
    arg.setDescription('Specifies whether the attic has a radiant barrier.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('eaves_depth', true)
    arg.setDisplayName('Geometry: Eaves Depth')
    arg.setUnits('ft')
    arg.setDescription('The eaves depth of the roof.')
    arg.setDefaultValue(2.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('num_bedrooms', true)
    arg.setDisplayName('Geometry: Number of Bedrooms')
    arg.setDescription('Specify the number of bedrooms. Used to determine the energy usage of appliances and plug loads, hot water usage, mechanical ventilation rate, etc.')
    arg.setDefaultValue(3)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('num_bathrooms', true)
    arg.setDisplayName('Geometry: Number of Bathrooms')
    arg.setDescription('Specify the number of bathrooms.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('num_occupants', true)
    arg.setDisplayName('Geometry: Number of Occupants')
    arg.setDescription("Specify the number of occupants. A value of '#{Constants.Auto}' will calculate the average number of occupants from the number of bedrooms. Used to specify the internal gains from people only.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('neighbor_front_distance', true)
    arg.setDisplayName('Neighbor: Front Distance')
    arg.setUnits('ft')
    arg.setDescription('The minimum distance between the simulated house and the neighboring house to the front (not including eaves). A value of zero indicates no neighbors.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('neighbor_back_distance', true)
    arg.setDisplayName('Neighbor: Back Distance')
    arg.setUnits('ft')
    arg.setDescription('The minimum distance between the simulated house and the neighboring house to the back (not including eaves). A value of zero indicates no neighbors.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('neighbor_left_distance', true)
    arg.setDisplayName('Neighbor: Left Distance')
    arg.setUnits('ft')
    arg.setDescription('The minimum distance between the simulated house and the neighboring house to the left (not including eaves). A value of zero indicates no neighbors.')
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('neighbor_right_distance', true)
    arg.setDisplayName('Neighbor: Right Distance')
    arg.setUnits('ft')
    arg.setDescription('The minimum distance between the simulated house and the neighboring house to the right (not including eaves). A value of zero indicates no neighbors.')
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('neighbor_front_height', true)
    arg.setDisplayName('Neighbor: Front Height')
    arg.setUnits('ft')
    arg.setDescription('The height of the front neighbor.')
    arg.setDefaultValue(12.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('neighbor_back_height', true)
    arg.setDisplayName('Neighbor: Back Height')
    arg.setUnits('ft')
    arg.setDescription('The height of the back neighbor.')
    arg.setDefaultValue(12.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('neighbor_left_height', true)
    arg.setDisplayName('Neighbor: Left Height')
    arg.setUnits('ft')
    arg.setDescription('The height of the left neighbor.')
    arg.setDefaultValue(12.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('neighbor_right_height', true)
    arg.setDisplayName('Neighbor: Right Height')
    arg.setUnits('ft')
    arg.setDescription('The height of the right neighbor.')
    arg.setDefaultValue(12.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('orientation', true)
    arg.setDisplayName('Geometry: Azimuth')
    arg.setUnits('degrees')
    arg.setDescription("The house's azimuth is measured clockwise from due south when viewed from above (e.g., North=0, East=90, South=180, West=270).")
    arg.setDefaultValue(180.0)
    args << arg

    wall_type_choices = OpenStudio::StringVector.new
    wall_type_choices << HPXML::WallTypeWoodStud
    wall_type_choices << HPXML::WallTypeCMU
    wall_type_choices << HPXML::WallTypeDoubleWoodStud
    wall_type_choices << HPXML::WallTypeICF
    wall_type_choices << HPXML::WallTypeLog
    wall_type_choices << HPXML::WallTypeSIP
    wall_type_choices << HPXML::WallTypeConcrete
    wall_type_choices << HPXML::WallTypeSteelStud
    wall_type_choices << HPXML::WallTypeStone
    wall_type_choices << HPXML::WallTypeStrawBale
    wall_type_choices << HPXML::WallTypeBrick

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('wall_type', wall_type_choices, true)
    arg.setDisplayName('Walls: Type')
    arg.setDescription('The type of the exterior walls.')
    arg.setDefaultValue(HPXML::WallTypeWoodStud)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('wall_conditioned_r', true)
    arg.setDisplayName('Walls: Cavity (Adjacent To Conditioned) Insulation Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the overall R-value of the assembly.')
    arg.setDefaultValue(13)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('wall_unconditioned_r', true)
    arg.setDisplayName('Walls: Cavity (Adjacent To Unconditioned) Insulation Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the overall R-value of the assembly.')
    arg.setDefaultValue(4)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('wall_solar_absorptance', true)
    arg.setDisplayName('Wall: Solar Absorptance')
    arg.setDescription('The solar absorptance of the exterior walls.')
    arg.setDefaultValue(0.7)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('wall_emittance', true)
    arg.setDisplayName('Wall: Emittance')
    arg.setDescription('The emittance of the exterior walls.')
    arg.setDefaultValue(0.92)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('front_wwr', true)
    arg.setDisplayName('Windows: Front Window-to-Wall Ratio')
    arg.setDescription("The ratio of window area to wall area for the building's front facade. Enter 0 if specifying Front Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('back_wwr', true)
    arg.setDisplayName('Windows: Back Window-to-Wall Ratio')
    arg.setDescription("The ratio of window area to wall area for the building's back facade. Enter 0 if specifying Back Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('left_wwr', true)
    arg.setDisplayName('Windows: Left Window-to-Wall Ratio')
    arg.setDescription("The ratio of window area to wall area for the building's left facade. Enter 0 if specifying Left Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('right_wwr', true)
    arg.setDisplayName('Windows: Right Window-to-Wall Ratio')
    arg.setDescription("The ratio of window area to wall area for the building's right facade. Enter 0 if specifying Right Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('front_window_area', true)
    arg.setDisplayName('Windows: Front Window Area')
    arg.setDescription("The amount of window area on the building's front facade. Enter 0 if specifying Front Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('back_window_area', true)
    arg.setDisplayName('Windows: Back Window Area')
    arg.setDescription("The amount of window area on the building's back facade. Enter 0 if specifying Back Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('left_window_area', true)
    arg.setDisplayName('Windows: Left Window Area')
    arg.setDescription("The amount of window area on the building's left facade. Enter 0 if specifying Left Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('right_window_area', true)
    arg.setDisplayName('Windows: Right Window Area')
    arg.setDescription("The amount of window area on the building's right facade. Enter 0 if specifying Right Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_aspect_ratio', true)
    arg.setDisplayName('Windows: Aspect Ratio')
    arg.setDescription('Ratio of window height to width.')
    arg.setDefaultValue(1.333)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_fraction_of_operable_area', true)
    arg.setDisplayName('Windows: Fraction of Operable Area')
    arg.setDescription('Fraction of operable window area.')
    arg.setDefaultValue(0.33)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_ufactor', true)
    arg.setDisplayName('Windows: U-Factor')
    arg.setUnits('Btu/hr-ft^2-R')
    arg.setDescription('The heat transfer coefficient of the windows.')
    arg.setDefaultValue(0.37)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_shgc', true)
    arg.setDisplayName('Windows: SHGC')
    arg.setDescription('The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening, for windows.')
    arg.setDefaultValue(0.3)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('winter_shading_coefficient_front_facade', true)
    arg.setDisplayName('Interior Shading: Front Facade Winter Shading Coefficient')
    arg.setDescription('Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('summer_shading_coefficient_front_facade', true)
    arg.setDisplayName('Interior Shading: Front Facade Summer Shading Coefficient')
    arg.setDescription('Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('winter_shading_coefficient_back_facade', true)
    arg.setDisplayName('Interior Shading: Back Facade Winter Shading Coefficient')
    arg.setDescription('Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('summer_shading_coefficient_back_facade', true)
    arg.setDisplayName('Interior Shading: Back Facade Summer Shading Coefficient')
    arg.setDescription('Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('winter_shading_coefficient_left_facade', true)
    arg.setDisplayName('Interior Shading: Left Facade Winter Shading Coefficient')
    arg.setDescription('Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('summer_shading_coefficient_left_facade', true)
    arg.setDisplayName('Interior Shading: Left Facade Summer Shading Coefficient')
    arg.setDescription('Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('winter_shading_coefficient_right_facade', true)
    arg.setDisplayName('Interior Shading: Right Facade Winter Shading Coefficient')
    arg.setDescription('Interior shading multiplier for heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('summer_shading_coefficient_right_facade', true)
    arg.setDisplayName('Interior Shading: Right Facade Summer Shading Coefficient')
    arg.setDescription('Interior shading multiplier for cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('overhangs_front_depth', true)
    arg.setDisplayName('Overhangs: Front Facade Depth')
    arg.setDescription('Specifies the depth of overhangs for windows on the front facade.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('overhangs_front_distance_to_top_of_window', true)
    arg.setDisplayName('Overhangs: Front Facade Distance to Top of Window')
    arg.setDescription('Specifies the distance to the top of window of overhangs for windows on the front facade.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('overhangs_back_depth', true)
    arg.setDisplayName('Overhangs: Back Facade Depth')
    arg.setDescription('Specifies the depth of overhangs for windows on the back facade.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('overhangs_back_distance_to_top_of_window', true)
    arg.setDisplayName('Overhangs: Back Facade Distance to Top of Window')
    arg.setDescription('Specifies the distance to the top of window of overhangs for windows on the back facade.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('overhangs_left_depth', true)
    arg.setDisplayName('Overhangs: Left Facade Depth')
    arg.setDescription('Specifies the depth of overhangs for windows on the left facade.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('overhangs_left_distance_to_top_of_window', true)
    arg.setDisplayName('Overhangs: Left Facade Distance to Top of Window')
    arg.setDescription('Specifies the distance to the top of window of overhangs for windows on the left facade.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('overhangs_right_depth', true)
    arg.setDisplayName('Overhangs: Right Facade Depth')
    arg.setDescription('Specifies the depth of overhangs for windows on the right facade.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('overhangs_right_distance_to_top_of_window', true)
    arg.setDisplayName('Overhangs: Right Facade Distance to Top of Window')
    arg.setDescription('Specifies the distance to the top of window of overhangs for windows on the right facade.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('front_skylight_area', true)
    arg.setDisplayName('Skylights: Front Roof Area')
    arg.setDescription("The amount of skylight area on the building's front conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('back_skylight_area', true)
    arg.setDisplayName('Skylights: Back Roof Area')
    arg.setDescription("The amount of skylight area on the building's back conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('left_skylight_area', true)
    arg.setDisplayName('Skylights: Left Roof Area')
    arg.setDescription("The amount of skylight area on the building's left conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('right_skylight_area', true)
    arg.setDisplayName('Skylights: Right Roof Area')
    arg.setDescription("The amount of skylight area on the building's right conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('skylight_ufactor', true)
    arg.setDisplayName('Skylights: U-Factor')
    arg.setUnits('Btu/hr-ft^2-R')
    arg.setDescription('The heat transfer coefficient of the skylights.')
    arg.setDefaultValue(0.33)
    args << arg

    skylight_shgc = OpenStudio::Measure::OSArgument::makeDoubleArgument('skylight_shgc', true)
    skylight_shgc.setDisplayName('Skylights: SHGC')
    skylight_shgc.setDescription('The ratio of solar heat gain through a glazing system compared to that of an unobstructed opening, for skylights.')
    skylight_shgc.setDefaultValue(0.45)
    args << skylight_shgc

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('door_area', true)
    arg.setDisplayName('Doors: Area')
    arg.setUnits('ft^2')
    arg.setDescription('The area of the opaque door(s).')
    arg.setDefaultValue(20.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('door_rvalue', true)
    arg.setDisplayName('Doors: R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Refers to the R-value of the doors adjacent to conditioned space.')
    arg.setDefaultValue(5.0)
    args << arg

    living_air_leakage_units_choices = OpenStudio::StringVector.new
    living_air_leakage_units_choices << HPXML::UnitsACH50
    living_air_leakage_units_choices << HPXML::UnitsCFM50
    living_air_leakage_units_choices << HPXML::UnitsACHNatural

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('living_air_leakage_units', living_air_leakage_units_choices, true)
    arg.setDisplayName('Air Leakage: Above-Grade Living Unit of Measure')
    arg.setDescription('The unit of measure for the above-grade living air leakage.')
    arg.setDefaultValue(HPXML::UnitsACH50)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('living_air_leakage_value', true)
    arg.setDisplayName('Air Leakage: Above-Grade Living Value')
    arg.setDescription("#{HPXML::UnitsACH50}=Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for above-grade living space (including conditioned attic). #{HPXML::UnitsCFM50}= Air exchange rate, in CFM at 50 Pascals (CFM50), for above-grade living space (including conditioned attic). #{HPXML::UnitsACHNatural}=Air exchange rate, in constant natural Air Changes per Hour, for above-grade living space (including conditioned attic).")
    arg.setDefaultValue(3)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('vented_crawlspace_sla', true)
    arg.setDisplayName('Air Leakage: Vented Crawlspace')
    arg.setDescription('Air exchange rate, in specific leakage area (SLA), for vented crawlspace.')
    arg.setDefaultValue(0.00677)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('shelter_coefficient', true)
    arg.setDisplayName('Air Leakage: Shelter Coefficient')
    arg.setUnits('Frac')
    arg.setDescription('The local shelter coefficient (AIM-2 infiltration model) accounts for nearby buildings, trees, and obstructions.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    heating_system_type_choices = OpenStudio::StringVector.new
    heating_system_type_choices << 'none'
    heating_system_type_choices << HPXML::HVACTypeFurnace
    heating_system_type_choices << HPXML::HVACTypeWallFurnace
    heating_system_type_choices << HPXML::HVACTypeBoiler
    heating_system_type_choices << HPXML::HVACTypeElectricResistance
    heating_system_type_choices << HPXML::HVACTypeStove
    heating_system_type_choices << HPXML::HVACTypePortableHeater

    heating_system_fuel_choices = OpenStudio::StringVector.new
    heating_system_fuel_choices << HPXML::FuelTypeElectricity
    heating_system_fuel_choices << HPXML::FuelTypeNaturalGas
    heating_system_fuel_choices << HPXML::FuelTypeOil
    heating_system_fuel_choices << HPXML::FuelTypePropane
    heating_system_fuel_choices << HPXML::FuelTypeWood

    cooling_system_type_choices = OpenStudio::StringVector.new
    cooling_system_type_choices << 'none'
    cooling_system_type_choices << HPXML::HVACTypeCentralAirConditioner
    cooling_system_type_choices << HPXML::HVACTypeRoomAirConditioner
    cooling_system_type_choices << HPXML::HVACTypeEvaporativeCooler

    cooling_system_fuel_choices = OpenStudio::StringVector.new
    cooling_system_fuel_choices << HPXML::FuelTypeElectricity

    heat_pump_type_choices = OpenStudio::StringVector.new
    heat_pump_type_choices << 'none'
    heat_pump_type_choices << HPXML::HVACTypeHeatPumpAirToAir
    heat_pump_type_choices << HPXML::HVACTypeHeatPumpMiniSplit
    heat_pump_type_choices << HPXML::HVACTypeHeatPumpGroundToAir

    heat_pump_fuel_choices = OpenStudio::StringVector.new
    heat_pump_fuel_choices << HPXML::FuelTypeElectricity

    heat_pump_backup_fuel_choices = OpenStudio::StringVector.new
    heat_pump_backup_fuel_choices << 'none'
    heat_pump_backup_fuel_choices << HPXML::FuelTypeElectricity
    heat_pump_backup_fuel_choices << HPXML::FuelTypeNaturalGas
    heat_pump_backup_fuel_choices << HPXML::FuelTypeOil
    heat_pump_backup_fuel_choices << HPXML::FuelTypePropane

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('heating_system_type', heating_system_type_choices, true)
    arg.setDisplayName('Heating System: Type')
    arg.setDescription('The type of the heating system.')
    arg.setDefaultValue(HPXML::HVACTypeFurnace)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('heating_system_fuel', heating_system_fuel_choices, true)
    arg.setDisplayName('Heating System: Fuel Type')
    arg.setDescription('The fuel type of the heating system.')
    arg.setDefaultValue(HPXML::FuelTypeNaturalGas)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_heating_efficiency', true)
    arg.setDisplayName('Heating System: Rated Efficiency')
    arg.setDescription('The rated efficiency value of the heating system. AFUE for Furnace/WallFurnace/Boiler. Percent for ElectricResistance/Stove/PortableHeater.')
    arg.setDefaultValue(0.78)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heating_system_heating_capacity', true)
    arg.setDisplayName('Heating System: Heating Capacity')
    arg.setDescription("The output heating capacity of the heating system. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.SizingAuto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_fraction_heat_load_served', true)
    arg.setDisplayName('Heating System: Fraction Heat Load Served')
    arg.setDescription('The heat load served fraction of the heating system.')
    arg.setUnits('Frac')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_electric_auxiliary_energy', true)
    arg.setDisplayName('Heating System: Electric Auxiliary Energy')
    arg.setDescription('The electric auxiliary energy of the heating system.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('cooling_system_type', cooling_system_type_choices, true)
    arg.setDisplayName('Cooling System: Type')
    arg.setDescription('The type of the cooling system.')
    arg.setDefaultValue(HPXML::HVACTypeCentralAirConditioner)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('cooling_system_fuel', cooling_system_fuel_choices, true)
    arg.setDisplayName('Cooling System: Fuel Type')
    arg.setDescription('The fuel type of the cooling system.')
    arg.setDefaultValue(HPXML::FuelTypeElectricity)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_cooling_efficiency', true)
    arg.setDisplayName('Cooling System: Rated Efficiency')
    arg.setDescription('The rated efficiency value of the cooling system. SEER for central air conditioner. EER for room air conditioner. Ignored for evaporative cooler.')
    arg.setDefaultValue(13.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('cooling_system_cooling_capacity', true)
    arg.setDisplayName('Cooling System: Cooling Capacity')
    arg.setDescription("The output cooling capacity of the cooling system. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits('tons')
    arg.setDefaultValue(Constants.SizingAuto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_fraction_cool_load_served', true)
    arg.setDisplayName('Cooling System: Fraction Cool Load Served')
    arg.setDescription('The cool load served fraction of the cooling system.')
    arg.setUnits('Frac')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('heat_pump_type', heat_pump_type_choices, true)
    arg.setDisplayName('Heat Pump: Type')
    arg.setDescription('The type of the heat pump.')
    arg.setDefaultValue('none')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('heat_pump_fuel', heat_pump_fuel_choices, true)
    arg.setDisplayName('Heat Pump: Fuel Type')
    arg.setDescription('The fuel type of the heat pump.')
    arg.setDefaultValue(HPXML::FuelTypeElectricity)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_heating_efficiency', true)
    arg.setDisplayName('Heat Pump: Rated Heating Efficiency')
    arg.setDescription('The rated heating efficiency value of the heat pump. HSPF for air-to-air/mini-split. COP for ground-to-air.')
    arg.setDefaultValue(7.7)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_cooling_efficiency', true)
    arg.setDisplayName('Heat Pump: Rated Cooling Efficiency')
    arg.setDescription('The rated cooling efficiency value of the heat pump. SEER for air-to-air/mini-split. EER for ground-to-air.')
    arg.setDefaultValue(13.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heat_pump_heating_capacity', true)
    arg.setDisplayName('Heat Pump: Heating Capacity')
    arg.setDescription("The output heating capacity of the heat pump. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.SizingAuto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heat_pump_cooling_capacity', true)
    arg.setDisplayName('Heat Pump: Cooling Capacity')
    arg.setDescription("The output cooling capacity of the heat pump. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.SizingAuto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_fraction_heat_load_served', true)
    arg.setDisplayName('Heat Pump: Fraction Heat Load Served')
    arg.setDescription('The heat load served fraction of the heat pump.')
    arg.setUnits('Frac')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_fraction_cool_load_served', true)
    arg.setDisplayName('Heat Pump: Fraction Cool Load Served')
    arg.setDescription('The cool load served fraction of the heat pump.')
    arg.setUnits('Frac')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('heat_pump_backup_fuel', heat_pump_backup_fuel_choices, true)
    arg.setDisplayName('Heat Pump: Backup Fuel Type')
    arg.setDescription('The backup fuel type of the heat pump.')
    arg.setDefaultValue('none')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_backup_heating_efficiency', true)
    arg.setDisplayName('Heat Pump: Backup Rated Efficiency')
    arg.setDescription('The backup rated efficiency value of the heat pump. Percent for electricity fuel type. AFUE otherwise.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heat_pump_backup_heating_capacity', true)
    arg.setDisplayName('Heat Pump: Backup Heating Capacity')
    arg.setDescription("The backup output heating capacity of the heat pump. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.SizingAuto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('mini_split_is_ducted', true)
    arg.setDisplayName('Mini-Split: Is Ducted')
    arg.setDescription('Whether the mini-split heat pump is ducted or not.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('evap_cooler_is_ducted', true)
    arg.setDisplayName('Evaporative Cooler: Is Ducted')
    arg.setDescription('Whether the evaporative cooler is ducted or not.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_setpoint_temp', true)
    arg.setDisplayName('Heating Setpoint Temperature')
    arg.setDescription('Specify the heating setpoint temperature.')
    arg.setUnits('degrees F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_setback_temp', true)
    arg.setDisplayName('Heating Setback Temperature')
    arg.setDescription('Specify the heating setback temperature.')
    arg.setUnits('degrees F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_setback_hours_per_week', true)
    arg.setDisplayName('Heating Setback Hours per Week')
    arg.setDescription('Specify the heating setback number of hours per week value.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_setback_start_hour', true)
    arg.setDisplayName('Heating Setback Start Hour')
    arg.setDescription('Specify the heating setback start hour value. 0 = midnight, 12 = noon')
    arg.setDefaultValue(23)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_setpoint_temp', true)
    arg.setDisplayName('Cooling Setpoint Temperature')
    arg.setDescription('Specify the cooling setpoint temperature.')
    arg.setUnits('degrees F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_setup_temp', true)
    arg.setDisplayName('Cooling Setup Temperature')
    arg.setDescription('Specify the cooling setup temperature.')
    arg.setUnits('degrees F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_setup_hours_per_week', true)
    arg.setDisplayName('Cooling Setup Hours per Week')
    arg.setDescription('Specify the cooling setup number of hours per week value.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_setup_start_hour', true)
    arg.setDisplayName('Cooling Setup Start Hour')
    arg.setDescription('Specify the cooling setup start hour value. 0 = midnight, 12 = noon')
    arg.setDefaultValue(9)
    args << arg

    duct_leakage_units_choices = OpenStudio::StringVector.new
    duct_leakage_units_choices << HPXML::UnitsCFM25
    duct_leakage_units_choices << HPXML::UnitsPercent

    duct_location_choices = OpenStudio::StringVector.new
    duct_location_choices << Constants.Auto
    duct_location_choices << HPXML::LocationLivingSpace
    duct_location_choices << HPXML::LocationBasementConditioned
    duct_location_choices << HPXML::LocationBasementUnconditioned
    duct_location_choices << HPXML::LocationCrawlspaceVented
    duct_location_choices << HPXML::LocationCrawlspaceUnvented
    duct_location_choices << HPXML::LocationAtticVented
    duct_location_choices << HPXML::LocationAtticUnvented
    duct_location_choices << HPXML::LocationGarage
    duct_location_choices << HPXML::LocationOutside

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('supply_duct_leakage_units', duct_leakage_units_choices, true)
    arg.setDisplayName('Supply Duct: Leakage Units')
    arg.setDescription('The leakage units of the supply duct.')
    arg.setDefaultValue(HPXML::UnitsCFM25)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('return_duct_leakage_units', duct_leakage_units_choices, true)
    arg.setDisplayName('Return Duct: Leakage Units')
    arg.setDescription('The leakage units of the return duct.')
    arg.setDefaultValue(HPXML::UnitsCFM25)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('supply_duct_leakage_value', true)
    arg.setDisplayName('Supply Duct: Leakage Value')
    arg.setDescription('The leakage value of the supply duct.')
    arg.setDefaultValue(75)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('return_duct_leakage_value', true)
    arg.setDisplayName('Return Duct: Leakage Value')
    arg.setDescription('The leakage value of the return duct.')
    arg.setDefaultValue(25)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('supply_duct_insulation_r_value', true)
    arg.setDisplayName('Supply Duct: Insulation R-Value')
    arg.setDescription('The insulation r-value of the supply duct.')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('return_duct_insulation_r_value', true)
    arg.setDisplayName('Return Duct: Insulation R-Value')
    arg.setDescription('The insulation r-value of the return duct.')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('supply_duct_location', duct_location_choices, true)
    arg.setDisplayName('Supply Duct: Location')
    arg.setDescription('The location of the supply duct.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('return_duct_location', duct_location_choices, true)
    arg.setDisplayName('Return Duct: Location')
    arg.setDescription('The location of the return duct.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('supply_duct_surface_area', true)
    arg.setDisplayName('Supply Duct: Surface Area')
    arg.setDescription('The surface area of the supply duct.')
    arg.setUnits('ft^2')
    arg.setDefaultValue(150)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('return_duct_surface_area', true)
    arg.setDisplayName('Return Duct: Surface Area')
    arg.setDescription('The surface area of the return duct.')
    arg.setUnits('ft^2')
    arg.setDefaultValue(50)
    args << arg

    mech_vent_fan_type_choices = OpenStudio::StringVector.new
    mech_vent_fan_type_choices << 'none'
    mech_vent_fan_type_choices << HPXML::MechVentTypeExhaust
    mech_vent_fan_type_choices << HPXML::MechVentTypeSupply
    mech_vent_fan_type_choices << HPXML::MechVentTypeERV
    mech_vent_fan_type_choices << HPXML::MechVentTypeHRV
    mech_vent_fan_type_choices << HPXML::MechVentTypeBalanced
    mech_vent_fan_type_choices << HPXML::MechVentTypeCFIS

    mech_vent_recovery_efficiency_type_choices = OpenStudio::StringVector.new
    mech_vent_recovery_efficiency_type_choices << 'Unadjusted'
    mech_vent_recovery_efficiency_type_choices << 'Adjusted'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('mech_vent_fan_type', mech_vent_fan_type_choices, true)
    arg.setDisplayName('Mechanical Ventilation: Fan Type')
    arg.setDescription('The fan type of the mechanical ventilation.')
    arg.setDefaultValue('none')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('mech_vent_flow_rate', true)
    arg.setDisplayName('Mechanical Ventilation: Flow Rate')
    arg.setDescription('The flow rate of the mechanical ventilation.')
    arg.setUnits('CFM')
    arg.setDefaultValue(110)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('mech_vent_hours_in_operation', true)
    arg.setDisplayName('Mechanical Ventilation: Hours In Operation')
    arg.setDescription('The hours in operation of the mechanical ventilation.')
    arg.setUnits('hrs')
    arg.setDefaultValue(24)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('mech_vent_total_recovery_efficiency_type', mech_vent_recovery_efficiency_type_choices, true)
    arg.setDisplayName('Mechanical Ventilation: Total Recovery Efficiency Type')
    arg.setDescription('The total recovery efficiency type of the mechanical ventilation.')
    arg.setDefaultValue('Unadjusted')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('mech_vent_total_recovery_efficiency', true)
    arg.setDisplayName('Mechanical Ventilation: Total Recovery Efficiency')
    arg.setDescription('The Unadjusted or Adjusted total recovery efficiency of the mechanical ventilation.')
    arg.setUnits('Frac')
    arg.setDefaultValue(0.48)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('mech_vent_sensible_recovery_efficiency_type', mech_vent_recovery_efficiency_type_choices, true)
    arg.setDisplayName('Mechanical Ventilation: Sensible Recovery Efficiency Type')
    arg.setDescription('The sensible recovery efficiency type of the mechanical ventilation.')
    arg.setDefaultValue('Unadjusted')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('mech_vent_sensible_recovery_efficiency', true)
    arg.setDisplayName('Mechanical Ventilation: Sensible Recovery Efficiency')
    arg.setDescription('The Unadjusted or Adjusted sensible recovery efficiency of the mechanical ventilation.')
    arg.setUnits('Frac')
    arg.setDefaultValue(0.72)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('mech_vent_fan_power', true)
    arg.setDisplayName('Mechanical Ventilation: Fan Power')
    arg.setDescription('The fan power of the mechanical ventilation.')
    arg.setUnits('W')
    arg.setDefaultValue(30)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('has_whole_house_fan', true)
    arg.setDisplayName('Whole House Fan: Has')
    arg.setDescription('Whether there is a whole house fan.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('whole_house_fan_flow_rate', true)
    arg.setDisplayName('Whole House Fan: Flow Rate')
    arg.setDescription('The flow rate of the whole house fan.')
    arg.setUnits('CFM')
    arg.setDefaultValue(4500)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('whole_house_fan_power', true)
    arg.setDisplayName('Whole House Fan: Fan Power')
    arg.setDescription('The fan power of the whole house fan.')
    arg.setUnits('W')
    arg.setDefaultValue(300)
    args << arg

    water_heater_type_choices = OpenStudio::StringVector.new
    water_heater_type_choices << 'none'
    water_heater_type_choices << HPXML::WaterHeaterTypeStorage
    water_heater_type_choices << HPXML::WaterHeaterTypeTankless
    water_heater_type_choices << HPXML::WaterHeaterTypeHeatPump
    water_heater_type_choices << HPXML::WaterHeaterTypeCombiStorage
    water_heater_type_choices << HPXML::WaterHeaterTypeCombiTankless

    water_heater_fuel_choices = OpenStudio::StringVector.new
    water_heater_fuel_choices << HPXML::FuelTypeElectricity
    water_heater_fuel_choices << HPXML::FuelTypeNaturalGas
    water_heater_fuel_choices << HPXML::FuelTypeOil
    water_heater_fuel_choices << HPXML::FuelTypePropane
    water_heater_fuel_choices << HPXML::FuelTypeWood

    location_choices = OpenStudio::StringVector.new
    location_choices << Constants.Auto
    location_choices << HPXML::LocationLivingSpace
    location_choices << HPXML::LocationBasementConditioned
    location_choices << HPXML::LocationBasementUnconditioned
    location_choices << HPXML::LocationGarage
    location_choices << HPXML::LocationAtticVented
    location_choices << HPXML::LocationAtticUnvented
    location_choices << HPXML::LocationCrawlspaceVented
    location_choices << HPXML::LocationCrawlspaceUnvented
    location_choices << HPXML::LocationOtherExterior

    water_heater_efficiency_type_choices = OpenStudio::StringVector.new
    water_heater_efficiency_type_choices << 'EnergyFactor'
    water_heater_efficiency_type_choices << 'UniformEnergyFactor'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('water_heater_type', water_heater_type_choices, true)
    arg.setDisplayName('Water Heater: Type')
    arg.setDescription('The type of water heater.')
    arg.setDefaultValue(HPXML::WaterHeaterTypeStorage)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('water_heater_fuel_type', water_heater_fuel_choices, true)
    arg.setDisplayName('Water Heater: Fuel Type')
    arg.setDescription('The fuel type of water heater.')
    arg.setDefaultValue(HPXML::FuelTypeElectricity)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('water_heater_location', location_choices, true)
    arg.setDisplayName('Water Heater: Location')
    arg.setDescription('The location of water heater.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('water_heater_tank_volume', true)
    arg.setDisplayName('Water Heater: Tank Volume')
    arg.setDescription("Nominal volume of water heater tank. Set to #{Constants.Auto} to have volume autosized.")
    arg.setUnits('gal')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('water_heater_heating_capacity', true)
    arg.setDisplayName('Water Heater: Input Capacity')
    arg.setDescription("The maximum energy input rating of water heater. Set to #{Constants.SizingAuto} to have this field autosized.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.SizingAuto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('water_heater_efficiency_type', water_heater_efficiency_type_choices, true)
    arg.setDisplayName('Water Heater: Efficiency Type')
    arg.setDescription('The efficiency type of water heater.')
    arg.setDefaultValue('EnergyFactor')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('water_heater_efficiency', true)
    arg.setDisplayName('Water Heater: Efficiency')
    arg.setDescription('EnergyFactor=Ratio of useful energy output from water heater to the total amount of energy delivered from the water heater. UniformEnergyFactor=The uniform energy factor of water heater.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('water_heater_recovery_efficiency', true)
    arg.setDisplayName('Water Heater: Recovery Efficiency')
    arg.setDescription('Ratio of energy delivered to water heater to the energy content of the fuel consumed by the water heater. Only used for non-electric water heaters.')
    arg.setUnits('Frac')
    arg.setDefaultValue(0.76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('water_heater_standby_loss', true)
    arg.setDisplayName('Water Heater: Standby Loss')
    arg.setDescription('The standby loss of water heater.')
    arg.setUnits('Frac')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('water_heater_jacket_rvalue', true)
    arg.setDisplayName('Water Heater: Jacket R-value')
    arg.setDescription('The jacket R-value of water heater.')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDefaultValue(0)
    args << arg

    hot_water_distribution_system_type_choices = OpenStudio::StringVector.new
    hot_water_distribution_system_type_choices << HPXML::DHWDistTypeStandard
    hot_water_distribution_system_type_choices << HPXML::DHWDistTypeRecirc

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('hot_water_distribution_system_type', hot_water_distribution_system_type_choices, true)
    arg.setDisplayName('Hot Water Distribution: System Type')
    arg.setDescription('The type of the hot water distribution system.')
    arg.setDefaultValue(HPXML::DHWDistTypeStandard)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('standard_piping_length', true)
    arg.setDisplayName('Hot Water Distribution: Standard Piping Length')
    arg.setUnits('ft')
    arg.setDescription('The length of the standard piping.')
    arg.setDefaultValue(50)
    args << arg

    recirculation_control_type_choices = OpenStudio::StringVector.new
    recirculation_control_type_choices << HPXML::DHWRecirControlTypeNone
    recirculation_control_type_choices << HPXML::DHWRecirControlTypeTimer
    recirculation_control_type_choices << HPXML::DHWRecirControlTypeTemperature
    recirculation_control_type_choices << HPXML::DHWRecirControlTypeSensor
    recirculation_control_type_choices << HPXML::DHWRecirControlTypeManual

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('recirculation_control_type', recirculation_control_type_choices, true)
    arg.setDisplayName('Hot Water Distribution: Recirculation Control Type')
    arg.setDescription('The type of hot water recirculation control, if any.')
    arg.setDefaultValue(HPXML::DHWRecirControlTypeNone)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('recirculation_piping_length', true)
    arg.setDisplayName('Hot Water Distribution: Recirculation Piping Length')
    arg.setUnits('ft')
    arg.setDescription('The length of the recirculation piping.')
    arg.setDefaultValue(50)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('recirculation_branch_piping_length', true)
    arg.setDisplayName('Hot Water Distribution: Recirculation Branch Piping Length')
    arg.setUnits('ft')
    arg.setDescription('The length of the recirculation branch piping.')
    arg.setDefaultValue(50)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('recirculation_pump_power', true)
    arg.setDisplayName('Hot Water Distribution: Recirculation Pump Power')
    arg.setUnits('W')
    arg.setDescription('The power of the recirculation pump.')
    arg.setDefaultValue(50)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('hot_water_distribution_pipe_r_value', true)
    arg.setDisplayName('Hot Water Distribution: Insulation Nominal R-Value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value of the insulation on the DHW distribution system.')
    arg.setDefaultValue(0.0)
    args << arg

    dwhr_facilities_connected_choices = OpenStudio::StringVector.new
    dwhr_facilities_connected_choices << 'none'
    dwhr_facilities_connected_choices << HPXML::DWHRFacilitiesConnectedOne
    dwhr_facilities_connected_choices << HPXML::DWHRFacilitiesConnectedAll

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('dwhr_facilities_connected', dwhr_facilities_connected_choices, true)
    arg.setDisplayName('Drain Water Heat Recovery: Facilities Connected')
    arg.setDescription('Which facilities are connected for the drain water heat recovery.')
    arg.setDefaultValue('none')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('dwhr_equal_flow', true)
    arg.setDisplayName('Drain Water Heat Recovery: Equal Flow')
    arg.setDescription('Whether the drain water heat recovery has equal flow.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dwhr_efficiency', true)
    arg.setDisplayName('Drain Water Heat Recovery: Efficiency')
    arg.setUnits('Frac')
    arg.setDescription('The efficiency of the drain water heat recovery.')
    arg.setDefaultValue(0.55)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('shower_low_flow', true)
    arg.setDisplayName('Hot Water Fixtures: Is Shower Low Flow')
    arg.setDescription('Whether the shower fixture is low flow.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('sink_low_flow', true)
    arg.setDisplayName('Hot Water Fixtures: Is Sink Low Flow')
    arg.setDescription('Whether the sink fixture is low flow.')
    arg.setDefaultValue(false)
    args << arg

    solar_thermal_system_type_choices = OpenStudio::StringVector.new
    solar_thermal_system_type_choices << 'none'
    solar_thermal_system_type_choices << 'hot water'

    solar_thermal_collector_loop_type_choices = OpenStudio::StringVector.new
    solar_thermal_collector_loop_type_choices << HPXML::SolarThermalLoopTypeDirect
    solar_thermal_collector_loop_type_choices << HPXML::SolarThermalLoopTypeIndirect
    solar_thermal_collector_loop_type_choices << HPXML::SolarThermalLoopTypeThermosyphon

    solar_thermal_collector_type_choices = OpenStudio::StringVector.new
    solar_thermal_collector_type_choices << HPXML::SolarThermalTypeEvacuatedTube
    solar_thermal_collector_type_choices << HPXML::SolarThermalTypeSingleGlazing
    solar_thermal_collector_type_choices << HPXML::SolarThermalTypeDoubleGlazing
    solar_thermal_collector_type_choices << HPXML::SolarThermalTypeICS

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('solar_thermal_system_type', solar_thermal_system_type_choices, true)
    arg.setDisplayName('Solar Thermal: System Type')
    arg.setDescription('The type of the solar thermal system.')
    arg.setDefaultValue('none')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('solar_thermal_collector_area', true)
    arg.setDisplayName('Solar Thermal: Collector Area')
    arg.setUnits('ft^2')
    arg.setDescription('The collector area of the solar thermal system.')
    arg.setDefaultValue(40.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('solar_thermal_collector_loop_type', solar_thermal_collector_loop_type_choices, true)
    arg.setDisplayName('Solar Thermal: Collector Loop Type')
    arg.setDescription('The collector loop type of the solar thermal system.')
    arg.setDefaultValue(HPXML::SolarThermalLoopTypeDirect)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('solar_thermal_collector_type', solar_thermal_collector_type_choices, true)
    arg.setDisplayName('Solar Thermal: Collector Type')
    arg.setDescription('The collector type of the solar thermal system.')
    arg.setDefaultValue(HPXML::SolarThermalTypeEvacuatedTube)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('solar_thermal_collector_azimuth', true)
    arg.setDisplayName('Solar Thermal: Collector Azimuth')
    arg.setUnits('degrees')
    arg.setDescription('The collector azimuth of the solar thermal system.')
    arg.setDefaultValue(180)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('solar_thermal_collector_tilt', true)
    arg.setDisplayName('Solar Thermal: Collector Tilt')
    arg.setUnits('degrees')
    arg.setDescription('The collector tilt of the solar thermal system.')
    arg.setDefaultValue(20)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('solar_thermal_collector_rated_optical_efficiency', true)
    arg.setDisplayName('Solar Thermal: Collector Rated Optical Efficiency')
    arg.setUnits('Frac')
    arg.setDescription('The collector rated optical efficiency of the solar thermal system.')
    arg.setDefaultValue(0.5)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('solar_thermal_collector_rated_thermal_losses', true)
    arg.setDisplayName('Solar Thermal: Collector Rated Thermal Losses')
    arg.setUnits('Frac')
    arg.setDescription('The collector rated thermal losses of the solar thermal system.')
    arg.setDefaultValue(0.2799)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('solar_thermal_storage_volume', true)
    arg.setDisplayName('Solar Thermal: Storage Volume')
    arg.setUnits('Frac')
    arg.setDescription('The storage volume of the solar thermal system.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('solar_thermal_solar_fraction', true)
    arg.setDisplayName('Solar Thermal: Solar Fraction')
    arg.setUnits('Frac')
    arg.setDescription('The solar fraction of the solar thermal system.')
    arg.setDefaultValue(0)
    args << arg

    pv_system_module_type_choices = OpenStudio::StringVector.new
    pv_system_module_type_choices << 'none'
    pv_system_module_type_choices << HPXML::PVModuleTypeStandard
    pv_system_module_type_choices << HPXML::PVModuleTypePremium
    pv_system_module_type_choices << HPXML::PVModuleTypeThinFilm

    pv_system_location_choices = OpenStudio::StringVector.new
    pv_system_location_choices << HPXML::LocationRoof
    pv_system_location_choices << HPXML::LocationGround

    pv_system_tracking_choices = OpenStudio::StringVector.new
    pv_system_tracking_choices << HPXML::PVTrackingTypeFixed
    pv_system_tracking_choices << HPXML::PVTrackingType1Axis
    pv_system_tracking_choices << HPXML::PVTrackingType1AxisBacktracked
    pv_system_tracking_choices << HPXML::PVTrackingType2Axis

    (1..Constants.MaxNumPhotovoltaics).to_a.each do |n|
      arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("pv_system_module_type_#{n}", pv_system_module_type_choices, true)
      arg.setDisplayName("Photovoltaics #{n}: Module Type")
      arg.setDescription("Module type of the PV system #{n}.")
      arg.setDefaultValue('none')
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("pv_system_location_#{n}", pv_system_location_choices, true)
      arg.setDisplayName("Photovoltaics #{n}: Location")
      arg.setDescription("Location of the PV system #{n}.")
      arg.setDefaultValue(HPXML::LocationRoof)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("pv_system_tracking_#{n}", pv_system_tracking_choices, true)
      arg.setDisplayName("Photovoltaics #{n}: Tracking")
      arg.setDescription("Tracking of the PV system #{n}.")
      arg.setDefaultValue(HPXML::PVTrackingTypeFixed)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("pv_system_array_azimuth_#{n}", true)
      arg.setDisplayName("Photovoltaics #{n}: Array Azimuth")
      arg.setUnits('degrees')
      arg.setDescription("Array azimuth of the PV system #{n}.")
      arg.setDefaultValue(180)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("pv_system_array_tilt_#{n}", true)
      arg.setDisplayName("Photovoltaics #{n}: Array Tilt")
      arg.setUnits('degrees')
      arg.setDescription("Array tilt of the PV system #{n}.")
      arg.setDefaultValue(20)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("pv_system_max_power_output_#{n}", true)
      arg.setDisplayName("Photovoltaics #{n}: Maximum Power Output")
      arg.setUnits('W')
      arg.setDescription("Maximum power output of the PV system #{n}.")
      arg.setDefaultValue(4000)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("pv_system_inverter_efficiency_#{n}", true)
      arg.setDisplayName("Photovoltaics #{n}: Inverter Efficiency")
      arg.setUnits('Frac')
      arg.setDescription("Inverter efficiency of the PV system #{n}.")
      arg.setDefaultValue(0.96)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("pv_system_system_losses_fraction_#{n}", true)
      arg.setDisplayName("Photovoltaics #{n}: System Losses Fraction")
      arg.setUnits('Frac')
      arg.setDescription("System losses fraction of the PV system #{n}.")
      arg.setDefaultValue(0.14)
      args << arg
    end

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('has_clothes_washer', true)
    arg.setDisplayName('Clothes Washer: Has')
    arg.setDescription('Whether there is a clothes washer.')
    arg.setDefaultValue(true)
    args << arg

    clothes_washer_efficiency_type_choices = OpenStudio::StringVector.new
    clothes_washer_efficiency_type_choices << 'ModifiedEnergyFactor'
    clothes_washer_efficiency_type_choices << 'IntegratedModifiedEnergyFactor'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('clothes_washer_location', location_choices, true)
    arg.setDisplayName('Clothes Washer: Location')
    arg.setDescription('The space type for the clothes washer location.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('clothes_washer_efficiency_type', clothes_washer_efficiency_type_choices, true)
    arg.setDisplayName('Clothes Washer: Efficiency Type')
    arg.setDescription('The efficiency type of clothes washer.')
    arg.setDefaultValue('ModifiedEnergyFactor')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_efficiency', true)
    arg.setDisplayName('Clothes Washer: Efficiency')
    arg.setUnits('ft^3/kWh-cycle')
    arg.setDescription('The Modified Energy Factor (MEF) is the capacity of the clothes container divided by the total clothes washer energy consumption per cycle, where the energy consumption is the sum of the machine electrical energy consumption, the hot water energy consumption, the energy required for removal of the remaining moisture in the wash load, standby energy, and off-mode energy consumption. If only a Modified Energy Factor (MEF) is available, convert using the equation: IMEF = (MEF - 0.503) / 0.95.')
    arg.setDefaultValue(0.8)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_rated_annual_kwh', true)
    arg.setDisplayName('Clothes Washer: Rated Annual Consumption')
    arg.setUnits('kWh')
    arg.setDescription('The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.')
    arg.setDefaultValue(387.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_label_electric_rate', true)
    arg.setDisplayName('Clothes Washer: Label Electric Rate')
    arg.setUnits('kWh')
    arg.setDescription('The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.')
    arg.setDefaultValue(0.1065)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_label_gas_rate', true)
    arg.setDisplayName('Clothes Washer: Label Gas Rate')
    arg.setUnits('kWh')
    arg.setDescription('The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.')
    arg.setDefaultValue(1.218)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_label_annual_gas_cost', true)
    arg.setDisplayName('Clothes Washer: Annual Cost with Gas DHW')
    arg.setUnits('$')
    arg.setDescription('The annual cost of using the system under test conditions. Input is obtained from the EnergyGuide label.')
    arg.setDefaultValue(24.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_capacity', true)
    arg.setDisplayName('Clothes Washer: Drum Volume')
    arg.setUnits('ft^3')
    arg.setDescription("Volume of the washer drum. Obtained from the EnergyStar website or the manufacturer's literature.")
    arg.setDefaultValue(3.5)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('has_clothes_dryer', true)
    arg.setDisplayName('Clothes Dryer: Has')
    arg.setDescription('Whether there is a clothes dryer.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('clothes_dryer_location', location_choices, true)
    arg.setDisplayName('Clothes Dryer: Location')
    arg.setDescription('The space type for the clothes dryer location.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    clothes_dryer_fuel_choices = OpenStudio::StringVector.new
    clothes_dryer_fuel_choices << HPXML::FuelTypeElectricity
    clothes_dryer_fuel_choices << HPXML::FuelTypeNaturalGas
    clothes_dryer_fuel_choices << HPXML::FuelTypeOil
    clothes_dryer_fuel_choices << HPXML::FuelTypePropane
    clothes_dryer_fuel_choices << HPXML::FuelTypeWood

    clothes_dryer_control_type_choices = OpenStudio::StringVector.new
    clothes_dryer_control_type_choices << HPXML::ClothesDryerControlTypeTimer
    clothes_dryer_control_type_choices << HPXML::ClothesDryerControlTypeMoisture

    clothes_dryer_efficiency_type_choices = OpenStudio::StringVector.new
    clothes_dryer_efficiency_type_choices << 'EnergyFactor'
    clothes_dryer_efficiency_type_choices << 'CombinedEnergyFactor'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('clothes_dryer_fuel_type', clothes_dryer_fuel_choices, true)
    arg.setDisplayName('Clothes Dryer: Fuel Type')
    arg.setDescription('Type of fuel used by the clothes dryer.')
    arg.setDefaultValue(HPXML::FuelTypeNaturalGas)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('clothes_dryer_efficiency_type', clothes_dryer_efficiency_type_choices, true)
    arg.setDisplayName('Clothes Dryer: Efficiency Type')
    arg.setDescription('The efficiency type of clothes dryer.')
    arg.setDefaultValue('EnergyFactor')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_dryer_efficiency', true)
    arg.setDisplayName('Clothes Dryer: Efficiency')
    arg.setUnits('lb/kWh')
    arg.setDescription('The Combined Energy Factor (CEF) measures the pounds of clothing that can be dried per kWh (Fuel equivalent) of electricity, including energy consumed during Stand-by and Off modes. If only an Energy Factor (EF) is available, convert using the equation: CEF = EF / 1.15.')
    arg.setDefaultValue(2.95)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('clothes_dryer_control_type', clothes_dryer_control_type_choices, true)
    arg.setDisplayName('Clothes Dryer: Control Type')
    arg.setDescription('Type of control used by the clothes dryer.')
    arg.setDefaultValue(HPXML::ClothesDryerControlTypeTimer)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('has_dishwasher', true)
    arg.setDisplayName('Dishwasher: Has')
    arg.setDescription('Whether there is a dishwasher.')
    arg.setDefaultValue(true)
    args << arg

    dishwasher_efficiency_type_choices = OpenStudio::StringVector.new
    dishwasher_efficiency_type_choices << 'RatedAnnualkWh'
    dishwasher_efficiency_type_choices << 'EnergyFactor'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('dishwasher_efficiency_type', dishwasher_efficiency_type_choices, true)
    arg.setDisplayName('Dishwasher: Efficiency Type')
    arg.setDescription('The efficiency type of dishwasher.')
    arg.setDefaultValue('RatedAnnualkWh')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dishwasher_efficiency', true)
    arg.setDisplayName('Dishwasher: Efficiency')
    arg.setDescription('The efficiency of the dishwasher.')
    arg.setDefaultValue(290)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('dishwasher_place_setting_capacity', true)
    arg.setDisplayName('Dishwasher: Number of Place Settings')
    arg.setUnits('#')
    arg.setDescription("The number of place settings for the unit. Data obtained from manufacturer's literature.")
    arg.setDefaultValue(12)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('has_refrigerator', true)
    arg.setDisplayName('Refrigerator: Has')
    arg.setDescription('Whether there is a refrigerator.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('refrigerator_location', location_choices, true)
    arg.setDisplayName('Refrigerator: Location')
    arg.setDescription('The space type for the refrigerator location.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('refrigerator_rated_annual_kwh', true)
    arg.setDisplayName('Refrigerator: Rated Annual Consumption')
    arg.setUnits('kWh/yr')
    arg.setDescription('The EnergyGuide rated annual energy consumption for a refrigerator.')
    arg.setDefaultValue(434)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('refrigerator_adjusted_annual_kwh', true)
    arg.setDisplayName('Refrigerator: Adjusted Annual Consumption')
    arg.setUnits('kWh/yr')
    arg.setDescription('The adjusted annual energy consumption for a refrigerator.')
    arg.setDefaultValue(0)
    args << arg

    cooking_range_fuel_choices = OpenStudio::StringVector.new
    cooking_range_fuel_choices << HPXML::FuelTypeElectricity
    cooking_range_fuel_choices << HPXML::FuelTypeNaturalGas
    cooking_range_fuel_choices << HPXML::FuelTypeOil
    cooking_range_fuel_choices << HPXML::FuelTypePropane
    cooking_range_fuel_choices << HPXML::FuelTypeWood

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('has_cooking_range', true)
    arg.setDisplayName('Cooking Range: Has')
    arg.setDescription('Whether there is a cooking range.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('cooking_range_fuel_type', cooking_range_fuel_choices, true)
    arg.setDisplayName('Cooking Range: Fuel Type')
    arg.setDescription('Type of fuel used by the cooking range.')
    arg.setDefaultValue(HPXML::FuelTypeNaturalGas)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('cooking_range_is_induction', true)
    arg.setDisplayName('Cooking Range: Is Induction')
    arg.setDescription('Whether the cooking range is induction.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('has_oven', true)
    arg.setDisplayName('Oven: Has')
    arg.setDescription('Whether there is a oven.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('oven_is_convection', true)
    arg.setDisplayName('Oven: Is Convection')
    arg.setDescription('Whether the oven is convection.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('has_lighting', true)
    arg.setDisplayName('Lighting: Has')
    arg.setDescription('Whether there is lighting.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ceiling_fan_efficiency', true)
    arg.setDisplayName('Ceiling Fan: Efficiency')
    arg.setUnits('CFM/watt')
    arg.setDescription('The efficiency rating of the ceiling fan(s) at medium speed.')
    arg.setDefaultValue(100)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('ceiling_fan_quantity', true)
    arg.setDisplayName('Ceiling Fan: Quantity')
    arg.setUnits('#')
    arg.setDescription('Total number of ceiling fans.')
    arg.setDefaultValue(2)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ceiling_fan_cooling_setpoint_temp_offset', true)
    arg.setDisplayName('Ceiling Fan: Cooling Setpoint Temperature Offset')
    arg.setUnits('degrees F')
    arg.setDescription('The setpoint temperature offset during cooling season for the ceiling fan(s).')
    arg.setDefaultValue(0)
    args << arg

    plug_loads_plug_load_type_choices = OpenStudio::StringVector.new
    plug_loads_plug_load_type_choices << 'none'
    plug_loads_plug_load_type_choices << HPXML::PlugLoadTypeOther
    plug_loads_plug_load_type_choices << HPXML::PlugLoadTypeTelevision

    (1..Constants.MaxNumPlugLoads).to_a.each do |n|
      plug_load_type = 'none'
      if n == 1
        plug_load_type = HPXML::PlugLoadTypeOther
      end

      arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("plug_loads_plug_load_type_#{n}", plug_loads_plug_load_type_choices, true)
      arg.setDisplayName("Plug Load #{n}: Type")
      arg.setDescription("Type of plug load #{n}.")
      arg.setDefaultValue(plug_load_type)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("plug_loads_annual_kwh_#{n}", true)
      arg.setDisplayName("Plug Load #{n}: Annual kWh")
      arg.setDescription("The annual energy consumption of plug load #{n}.")
      arg.setUnits('kWh/yr')
      arg.setDefaultValue(0)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("plug_loads_frac_sensible_#{n}", true)
      arg.setDisplayName("Plug Load #{n}: Sensible Fraction")
      arg.setDescription("Fraction of internal gains that are sensible for plug load #{n}.")
      arg.setUnits('Frac')
      arg.setDefaultValue(0)
      args << arg

      arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("plug_loads_frac_latent_#{n}", true)
      arg.setDisplayName("Plug Load #{n}: Latent Fraction")
      arg.setDescription("Fraction of internal gains that are latent for plug load #{n}.")
      arg.setUnits('Frac')
      arg.setDefaultValue(0)
      args << arg
    end

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('plug_loads_schedule_values', true)
    arg.setDisplayName('Plug Loads: Use Schedule Values')
    arg.setDescription('Whether to use the schedule values.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('plug_loads_weekday_fractions', true)
    arg.setDisplayName('Plug Loads: Weekday Schedule')
    arg.setDescription('Specify the 24-hour weekday schedule.')
    arg.setDefaultValue('0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('plug_loads_weekend_fractions', true)
    arg.setDisplayName('Plug Loads: Weekend Schedule')
    arg.setDescription('Specify the 24-hour weekend schedule.')
    arg.setDefaultValue('0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('plug_loads_monthly_multipliers', true)
    arg.setDisplayName('Plug Loads: Month Schedule')
    arg.setDescription('Specify the 12-month schedule.')
    arg.setDefaultValue('1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248')
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

    require_relative '../HPXMLtoOpenStudio/measure'

    # Check for correct versions of OS
    os_version = '2.9.1'
    if OpenStudio.openStudioVersion != os_version
      fail "OpenStudio version #{os_version} is required."
    end

    # assign the user inputs to variables
    args = { weather_station_epw_filename: runner.getStringArgumentValue('weather_station_epw_filename', user_arguments),
             hpxml_path: runner.getStringArgumentValue('hpxml_path', user_arguments),
             timestep: runner.getIntegerArgumentValue('simulation_control_timestep', user_arguments),
             schedules_output_path: runner.getStringArgumentValue('schedules_output_path', user_arguments),
             unit_type: runner.getStringArgumentValue('unit_type', user_arguments),
             unit_multiplier: runner.getIntegerArgumentValue('unit_multiplier', user_arguments),
             cfa: runner.getDoubleArgumentValue('cfa', user_arguments),
             wall_height: runner.getDoubleArgumentValue('wall_height', user_arguments),
             num_units: runner.getIntegerArgumentValue('num_units', user_arguments),
             num_floors: runner.getIntegerArgumentValue('num_floors', user_arguments),
             aspect_ratio: runner.getDoubleArgumentValue('aspect_ratio', user_arguments),
             level: runner.getStringArgumentValue('level', user_arguments),
             horizontal_location: runner.getStringArgumentValue('horizontal_location', user_arguments),
             corridor_position: runner.getStringArgumentValue('corridor_position', user_arguments),
             corridor_width: runner.getDoubleArgumentValue('corridor_width', user_arguments),
             inset_width: runner.getDoubleArgumentValue('inset_width', user_arguments),
             inset_depth: runner.getDoubleArgumentValue('inset_depth', user_arguments),
             inset_position: runner.getStringArgumentValue('inset_position', user_arguments),
             balcony_depth: runner.getDoubleArgumentValue('balcony_depth', user_arguments),
             garage_width: runner.getDoubleArgumentValue('garage_width', user_arguments),
             garage_depth: runner.getDoubleArgumentValue('garage_depth', user_arguments),
             garage_protrusion: runner.getDoubleArgumentValue('garage_protrusion', user_arguments),
             garage_position: runner.getStringArgumentValue('garage_position', user_arguments),
             foundation_type: runner.getStringArgumentValue('foundation_type', user_arguments),
             foundation_height: runner.getDoubleArgumentValue('foundation_height', user_arguments),
             foundation_ceiling_r: runner.getDoubleArgumentValue('foundation_ceiling_r', user_arguments),
             foundation_wall_r: runner.getDoubleArgumentValue('foundation_wall_r', user_arguments),
             foundation_wall_distance_to_top: runner.getDoubleArgumentValue('foundation_wall_distance_to_top', user_arguments),
             foundation_wall_distance_to_bottom: runner.getDoubleArgumentValue('foundation_wall_distance_to_bottom', user_arguments),
             foundation_wall_depth_below_grade: runner.getDoubleArgumentValue('foundation_wall_depth_below_grade', user_arguments),
             perimeter_insulation_r_value: runner.getDoubleArgumentValue('slab_perimeter_r', user_arguments),
             perimeter_insulation_depth: runner.getDoubleArgumentValue('slab_perimeter_depth', user_arguments),
             under_slab_insulation_r_value: runner.getDoubleArgumentValue('slab_under_r', user_arguments),
             under_slab_insulation_width: runner.getDoubleArgumentValue('slab_under_width', user_arguments),
             carpet_fraction: runner.getDoubleArgumentValue('carpet_fraction', user_arguments),
             carpet_r_value: runner.getDoubleArgumentValue('carpet_r_value', user_arguments),
             attic_type: runner.getStringArgumentValue('attic_type', user_arguments),
             attic_floor_conditioned_r: runner.getDoubleArgumentValue('attic_floor_conditioned_r', user_arguments),
             attic_floor_unconditioned_r: runner.getDoubleArgumentValue('attic_floor_unconditioned_r', user_arguments),
             attic_ceiling_r: runner.getDoubleArgumentValue('attic_ceiling_r', user_arguments),
             roof_type: runner.getStringArgumentValue('roof_type', user_arguments),
             roof_pitch: { '1:12' => 1.0 / 12.0, '2:12' => 2.0 / 12.0, '3:12' => 3.0 / 12.0, '4:12' => 4.0 / 12.0, '5:12' => 5.0 / 12.0, '6:12' => 6.0 / 12.0, '7:12' => 7.0 / 12.0, '8:12' => 8.0 / 12.0, '9:12' => 9.0 / 12.0, '10:12' => 10.0 / 12.0, '11:12' => 11.0 / 12.0, '12:12' => 12.0 / 12.0 }[runner.getStringArgumentValue('roof_pitch', user_arguments)],
             roof_structure: runner.getStringArgumentValue('roof_structure', user_arguments),
             roof_ceiling_r: runner.getDoubleArgumentValue('roof_ceiling_r', user_arguments),
             roof_solar_absorptance: runner.getDoubleArgumentValue('roof_solar_absorptance', user_arguments),
             roof_emittance: runner.getDoubleArgumentValue('roof_emittance', user_arguments),
             roof_radiant_barrier: runner.getBoolArgumentValue('roof_radiant_barrier', user_arguments),
             eaves_depth: runner.getDoubleArgumentValue('eaves_depth', user_arguments),
             num_bedrooms: runner.getDoubleArgumentValue('num_bedrooms', user_arguments),
             num_bathrooms: runner.getStringArgumentValue('num_bathrooms', user_arguments),
             num_occupants: runner.getStringArgumentValue('num_occupants', user_arguments),
             neighbor_distance: [runner.getDoubleArgumentValue('neighbor_front_distance', user_arguments), runner.getDoubleArgumentValue('neighbor_back_distance', user_arguments), runner.getDoubleArgumentValue('neighbor_left_distance', user_arguments), runner.getDoubleArgumentValue('neighbor_right_distance', user_arguments)],
             neighbor_height: [runner.getDoubleArgumentValue('neighbor_front_height', user_arguments), runner.getDoubleArgumentValue('neighbor_back_height', user_arguments), runner.getDoubleArgumentValue('neighbor_left_height', user_arguments), runner.getDoubleArgumentValue('neighbor_right_height', user_arguments)],
             orientation: runner.getDoubleArgumentValue('orientation', user_arguments),
             wall_type: runner.getStringArgumentValue('wall_type', user_arguments),
             wall_conditioned_r: runner.getDoubleArgumentValue('wall_conditioned_r', user_arguments),
             wall_unconditioned_r: runner.getDoubleArgumentValue('wall_unconditioned_r', user_arguments),
             wall_solar_absorptance: runner.getDoubleArgumentValue('wall_solar_absorptance', user_arguments),
             wall_emittance: runner.getDoubleArgumentValue('wall_emittance', user_arguments),
             front_wwr: runner.getDoubleArgumentValue('front_wwr', user_arguments),
             back_wwr: runner.getDoubleArgumentValue('back_wwr', user_arguments),
             left_wwr: runner.getDoubleArgumentValue('left_wwr', user_arguments),
             right_wwr: runner.getDoubleArgumentValue('right_wwr', user_arguments),
             front_window_area: runner.getDoubleArgumentValue('front_window_area', user_arguments),
             back_window_area: runner.getDoubleArgumentValue('back_window_area', user_arguments),
             left_window_area: runner.getDoubleArgumentValue('left_window_area', user_arguments),
             right_window_area: runner.getDoubleArgumentValue('right_window_area', user_arguments),
             window_aspect_ratio: runner.getDoubleArgumentValue('window_aspect_ratio', user_arguments),
             window_fraction_of_operable_area: runner.getDoubleArgumentValue('window_fraction_of_operable_area', user_arguments),
             window_ufactor: runner.getDoubleArgumentValue('window_ufactor', user_arguments),
             window_shgc: runner.getDoubleArgumentValue('window_shgc', user_arguments),
             interior_shading_front_factor_winter: runner.getDoubleArgumentValue('winter_shading_coefficient_front_facade', user_arguments),
             interior_shading_front_factor_summer: runner.getDoubleArgumentValue('summer_shading_coefficient_front_facade', user_arguments),
             interior_shading_back_factor_winter: runner.getDoubleArgumentValue('winter_shading_coefficient_back_facade', user_arguments),
             interior_shading_back_factor_summer: runner.getDoubleArgumentValue('summer_shading_coefficient_back_facade', user_arguments),
             interior_shading_left_factor_winter: runner.getDoubleArgumentValue('winter_shading_coefficient_left_facade', user_arguments),
             interior_shading_left_factor_summer: runner.getDoubleArgumentValue('summer_shading_coefficient_left_facade', user_arguments),
             interior_shading_right_factor_winter: runner.getDoubleArgumentValue('winter_shading_coefficient_right_facade', user_arguments),
             interior_shading_right_factor_summer: runner.getDoubleArgumentValue('summer_shading_coefficient_right_facade', user_arguments),
             overhangs_front_depth: runner.getDoubleArgumentValue('overhangs_front_depth', user_arguments),
             overhangs_front_distance_to_top_of_window: runner.getDoubleArgumentValue('overhangs_front_distance_to_top_of_window', user_arguments),
             overhangs_back_depth: runner.getDoubleArgumentValue('overhangs_back_depth', user_arguments),
             overhangs_back_distance_to_top_of_window: runner.getDoubleArgumentValue('overhangs_back_distance_to_top_of_window', user_arguments),
             overhangs_left_depth: runner.getDoubleArgumentValue('overhangs_left_depth', user_arguments),
             overhangs_left_distance_to_top_of_window: runner.getDoubleArgumentValue('overhangs_left_distance_to_top_of_window', user_arguments),
             overhangs_right_depth: runner.getDoubleArgumentValue('overhangs_right_depth', user_arguments),
             overhangs_right_distance_to_top_of_window: runner.getDoubleArgumentValue('overhangs_right_distance_to_top_of_window', user_arguments),
             front_skylight_area: runner.getDoubleArgumentValue('front_skylight_area', user_arguments),
             back_skylight_area: runner.getDoubleArgumentValue('back_skylight_area', user_arguments),
             left_skylight_area: runner.getDoubleArgumentValue('left_skylight_area', user_arguments),
             right_skylight_area: runner.getDoubleArgumentValue('right_skylight_area', user_arguments),
             skylight_ufactor: runner.getDoubleArgumentValue('skylight_ufactor', user_arguments),
             skylight_shgc: runner.getDoubleArgumentValue('skylight_shgc', user_arguments),
             door_area: runner.getDoubleArgumentValue('door_area', user_arguments),
             door_rvalue: runner.getDoubleArgumentValue('door_rvalue', user_arguments),
             living_air_leakage_units: runner.getStringArgumentValue('living_air_leakage_units', user_arguments),
             living_air_leakage_value: runner.getDoubleArgumentValue('living_air_leakage_value', user_arguments),
             vented_crawlspace_sla: runner.getDoubleArgumentValue('vented_crawlspace_sla', user_arguments),
             shelter_coefficient: runner.getStringArgumentValue('shelter_coefficient', user_arguments),
             heating_system_type: runner.getStringArgumentValue('heating_system_type', user_arguments),
             heating_system_fuel: runner.getStringArgumentValue('heating_system_fuel', user_arguments),
             heating_system_heating_efficiency: runner.getDoubleArgumentValue('heating_system_heating_efficiency', user_arguments),
             heating_system_heating_capacity: runner.getStringArgumentValue('heating_system_heating_capacity', user_arguments),
             heating_system_fraction_heat_load_served: runner.getDoubleArgumentValue('heating_system_fraction_heat_load_served', user_arguments),
             heating_system_electric_auxiliary_energy: runner.getDoubleArgumentValue('heating_system_electric_auxiliary_energy', user_arguments),
             cooling_system_type: runner.getStringArgumentValue('cooling_system_type', user_arguments),
             cooling_system_fuel: runner.getStringArgumentValue('cooling_system_fuel', user_arguments),
             cooling_system_cooling_efficiency: runner.getDoubleArgumentValue('cooling_system_cooling_efficiency', user_arguments),
             cooling_system_cooling_capacity: runner.getStringArgumentValue('cooling_system_cooling_capacity', user_arguments),
             cooling_system_fraction_cool_load_served: runner.getDoubleArgumentValue('cooling_system_fraction_cool_load_served', user_arguments),
             heat_pump_type: runner.getStringArgumentValue('heat_pump_type', user_arguments),
             heat_pump_fuel: runner.getStringArgumentValue('heat_pump_fuel', user_arguments),
             heat_pump_heating_efficiency: runner.getDoubleArgumentValue('heat_pump_heating_efficiency', user_arguments),
             heat_pump_cooling_efficiency: runner.getDoubleArgumentValue('heat_pump_cooling_efficiency', user_arguments),
             heat_pump_heating_capacity: runner.getStringArgumentValue('heat_pump_heating_capacity', user_arguments),
             heat_pump_cooling_capacity: runner.getStringArgumentValue('heat_pump_cooling_capacity', user_arguments),
             heat_pump_fraction_heat_load_served: runner.getDoubleArgumentValue('heat_pump_fraction_heat_load_served', user_arguments),
             heat_pump_fraction_cool_load_served: runner.getDoubleArgumentValue('heat_pump_fraction_cool_load_served', user_arguments),
             heat_pump_backup_fuel: runner.getStringArgumentValue('heat_pump_backup_fuel', user_arguments),
             heat_pump_backup_heating_efficiency: runner.getStringArgumentValue('heat_pump_backup_heating_efficiency', user_arguments),
             heat_pump_backup_heating_capacity: runner.getStringArgumentValue('heat_pump_backup_heating_capacity', user_arguments),
             mini_split_is_ducted: runner.getBoolArgumentValue('mini_split_is_ducted', user_arguments),
             evap_cooler_is_ducted: runner.getBoolArgumentValue('evap_cooler_is_ducted', user_arguments),
             heating_setpoint_temp: runner.getDoubleArgumentValue('heating_setpoint_temp', user_arguments),
             heating_setback_temp: runner.getDoubleArgumentValue('heating_setback_temp', user_arguments),
             heating_setback_hours_per_week: runner.getDoubleArgumentValue('heating_setback_hours_per_week', user_arguments),
             heating_setback_start_hour: runner.getDoubleArgumentValue('heating_setback_start_hour', user_arguments),
             cooling_setpoint_temp: runner.getDoubleArgumentValue('cooling_setpoint_temp', user_arguments),
             cooling_setup_temp: runner.getDoubleArgumentValue('cooling_setup_temp', user_arguments),
             cooling_setup_hours_per_week: runner.getDoubleArgumentValue('cooling_setup_hours_per_week', user_arguments),
             cooling_setup_start_hour: runner.getDoubleArgumentValue('cooling_setup_start_hour', user_arguments),
             supply_duct_leakage_units: runner.getStringArgumentValue('supply_duct_leakage_units', user_arguments),
             return_duct_leakage_units: runner.getStringArgumentValue('return_duct_leakage_units', user_arguments),
             supply_duct_leakage_value: runner.getDoubleArgumentValue('supply_duct_leakage_value', user_arguments),
             return_duct_leakage_value: runner.getDoubleArgumentValue('return_duct_leakage_value', user_arguments),
             supply_duct_insulation_r_value: runner.getDoubleArgumentValue('supply_duct_insulation_r_value', user_arguments),
             return_duct_insulation_r_value: runner.getDoubleArgumentValue('return_duct_insulation_r_value', user_arguments),
             supply_duct_location: runner.getStringArgumentValue('supply_duct_location', user_arguments),
             return_duct_location: runner.getStringArgumentValue('return_duct_location', user_arguments),
             supply_duct_surface_area: runner.getDoubleArgumentValue('supply_duct_surface_area', user_arguments),
             return_duct_surface_area: runner.getDoubleArgumentValue('return_duct_surface_area', user_arguments),
             mech_vent_fan_type: runner.getStringArgumentValue('mech_vent_fan_type', user_arguments),
             mech_vent_flow_rate: runner.getDoubleArgumentValue('mech_vent_flow_rate', user_arguments),
             mech_vent_hours_in_operation: runner.getDoubleArgumentValue('mech_vent_hours_in_operation', user_arguments),
             mech_vent_total_recovery_efficiency_type: runner.getStringArgumentValue('mech_vent_total_recovery_efficiency_type', user_arguments),
             mech_vent_total_recovery_efficiency: runner.getDoubleArgumentValue('mech_vent_total_recovery_efficiency', user_arguments),
             mech_vent_sensible_recovery_efficiency_type: runner.getStringArgumentValue('mech_vent_sensible_recovery_efficiency_type', user_arguments),
             mech_vent_sensible_recovery_efficiency: runner.getDoubleArgumentValue('mech_vent_sensible_recovery_efficiency', user_arguments),
             mech_vent_fan_power: runner.getDoubleArgumentValue('mech_vent_fan_power', user_arguments),
             has_whole_house_fan: runner.getBoolArgumentValue('has_whole_house_fan', user_arguments),
             whole_house_fan_flow_rate: runner.getDoubleArgumentValue('whole_house_fan_flow_rate', user_arguments),
             whole_house_fan_power: runner.getDoubleArgumentValue('whole_house_fan_power', user_arguments),
             water_heater_type: runner.getStringArgumentValue('water_heater_type', user_arguments),
             water_heater_fuel_type: runner.getStringArgumentValue('water_heater_fuel_type', user_arguments),
             water_heater_location: runner.getStringArgumentValue('water_heater_location', user_arguments),
             water_heater_tank_volume: runner.getStringArgumentValue('water_heater_tank_volume', user_arguments),
             water_heater_heating_capacity: runner.getStringArgumentValue('water_heater_heating_capacity', user_arguments),
             water_heater_efficiency_type: runner.getStringArgumentValue('water_heater_efficiency_type', user_arguments),
             water_heater_efficiency: runner.getStringArgumentValue('water_heater_efficiency', user_arguments),
             water_heater_recovery_efficiency: runner.getDoubleArgumentValue('water_heater_recovery_efficiency', user_arguments),
             water_heater_standby_loss: runner.getDoubleArgumentValue('water_heater_standby_loss', user_arguments),
             water_heater_jacket_rvalue: runner.getDoubleArgumentValue('water_heater_jacket_rvalue', user_arguments),
             hot_water_distribution_system_type: runner.getStringArgumentValue('hot_water_distribution_system_type', user_arguments),
             standard_piping_length: runner.getStringArgumentValue('standard_piping_length', user_arguments),
             recirculation_control_type: runner.getStringArgumentValue('recirculation_control_type', user_arguments),
             recirculation_piping_length: runner.getDoubleArgumentValue('recirculation_piping_length', user_arguments),
             recirculation_branch_piping_length: runner.getDoubleArgumentValue('recirculation_branch_piping_length', user_arguments),
             recirculation_pump_power: runner.getDoubleArgumentValue('recirculation_pump_power', user_arguments),
             hot_water_distribution_pipe_r_value: runner.getDoubleArgumentValue('hot_water_distribution_pipe_r_value', user_arguments),
             dwhr_facilities_connected: runner.getStringArgumentValue('dwhr_facilities_connected', user_arguments),
             dwhr_equal_flow: runner.getBoolArgumentValue('dwhr_equal_flow', user_arguments),
             dwhr_efficiency: runner.getDoubleArgumentValue('dwhr_efficiency', user_arguments),
             shower_low_flow: runner.getBoolArgumentValue('shower_low_flow', user_arguments),
             sink_low_flow: runner.getBoolArgumentValue('sink_low_flow', user_arguments),
             solar_thermal_system_type: runner.getStringArgumentValue('solar_thermal_system_type', user_arguments),
             solar_thermal_collector_area: runner.getDoubleArgumentValue('solar_thermal_collector_area', user_arguments),
             solar_thermal_collector_loop_type: runner.getStringArgumentValue('solar_thermal_collector_loop_type', user_arguments),
             solar_thermal_collector_type: runner.getStringArgumentValue('solar_thermal_collector_type', user_arguments),
             solar_thermal_collector_azimuth: runner.getDoubleArgumentValue('solar_thermal_collector_azimuth', user_arguments),
             solar_thermal_collector_tilt: runner.getDoubleArgumentValue('solar_thermal_collector_tilt', user_arguments),
             solar_thermal_collector_rated_optical_efficiency: runner.getDoubleArgumentValue('solar_thermal_collector_rated_optical_efficiency', user_arguments),
             solar_thermal_collector_rated_thermal_losses: runner.getDoubleArgumentValue('solar_thermal_collector_rated_thermal_losses', user_arguments),
             solar_thermal_storage_volume: runner.getStringArgumentValue('solar_thermal_storage_volume', user_arguments),
             solar_thermal_solar_fraction: runner.getDoubleArgumentValue('solar_thermal_solar_fraction', user_arguments),
             pv_system_module_type: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getStringArgumentValue("pv_system_module_type_#{n}", user_arguments) },
             pv_system_location: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getStringArgumentValue("pv_system_location_#{n}", user_arguments) },
             pv_system_tracking: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getStringArgumentValue("pv_system_tracking_#{n}", user_arguments) },
             pv_system_array_azimuth: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getDoubleArgumentValue("pv_system_array_azimuth_#{n}", user_arguments) },
             pv_system_array_tilt: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getDoubleArgumentValue("pv_system_array_tilt_#{n}", user_arguments) },
             pv_system_max_power_output: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getDoubleArgumentValue("pv_system_max_power_output_#{n}", user_arguments) },
             pv_system_inverter_efficiency: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getDoubleArgumentValue("pv_system_inverter_efficiency_#{n}", user_arguments) },
             pv_system_system_losses_fraction: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getDoubleArgumentValue("pv_system_system_losses_fraction_#{n}", user_arguments) },
             has_clothes_washer: runner.getBoolArgumentValue('has_clothes_washer', user_arguments),
             clothes_washer_location: runner.getStringArgumentValue('clothes_washer_location', user_arguments),
             clothes_washer_efficiency_type: runner.getStringArgumentValue('clothes_washer_efficiency_type', user_arguments),
             clothes_washer_efficiency: runner.getDoubleArgumentValue('clothes_washer_efficiency', user_arguments),
             clothes_washer_rated_annual_kwh: runner.getDoubleArgumentValue('clothes_washer_rated_annual_kwh', user_arguments),
             clothes_washer_label_electric_rate: runner.getDoubleArgumentValue('clothes_washer_label_electric_rate', user_arguments),
             clothes_washer_label_gas_rate: runner.getDoubleArgumentValue('clothes_washer_label_gas_rate', user_arguments),
             clothes_washer_label_annual_gas_cost: runner.getDoubleArgumentValue('clothes_washer_label_annual_gas_cost', user_arguments),
             clothes_washer_capacity: runner.getDoubleArgumentValue('clothes_washer_capacity', user_arguments),
             has_clothes_dryer: runner.getBoolArgumentValue('has_clothes_dryer', user_arguments),
             clothes_dryer_location: runner.getStringArgumentValue('clothes_dryer_location', user_arguments),
             clothes_dryer_fuel_type: runner.getStringArgumentValue('clothes_dryer_fuel_type', user_arguments),
             clothes_dryer_efficiency_type: runner.getStringArgumentValue('clothes_dryer_efficiency_type', user_arguments),
             clothes_dryer_efficiency: runner.getDoubleArgumentValue('clothes_dryer_efficiency', user_arguments),
             clothes_dryer_control_type: runner.getStringArgumentValue('clothes_dryer_control_type', user_arguments),
             has_dishwasher: runner.getBoolArgumentValue('has_dishwasher', user_arguments),
             dishwasher_efficiency_type: runner.getStringArgumentValue('dishwasher_efficiency_type', user_arguments),
             dishwasher_efficiency: runner.getDoubleArgumentValue('dishwasher_efficiency', user_arguments),
             dishwasher_place_setting_capacity: runner.getIntegerArgumentValue('dishwasher_place_setting_capacity', user_arguments),
             has_refrigerator: runner.getBoolArgumentValue('has_refrigerator', user_arguments),
             refrigerator_location: runner.getStringArgumentValue('refrigerator_location', user_arguments),
             refrigerator_rated_annual_kwh: runner.getDoubleArgumentValue('refrigerator_rated_annual_kwh', user_arguments),
             refrigerator_adjusted_annual_kwh: runner.getDoubleArgumentValue('refrigerator_adjusted_annual_kwh', user_arguments),
             has_cooking_range: runner.getBoolArgumentValue('has_cooking_range', user_arguments),
             cooking_range_fuel_type: runner.getStringArgumentValue('cooking_range_fuel_type', user_arguments),
             cooking_range_is_induction: runner.getStringArgumentValue('cooking_range_is_induction', user_arguments),
             has_oven: runner.getBoolArgumentValue('has_oven', user_arguments),
             oven_is_convection: runner.getStringArgumentValue('oven_is_convection', user_arguments),
             has_lighting: runner.getBoolArgumentValue('has_lighting', user_arguments),
             ceiling_fan_efficiency: runner.getDoubleArgumentValue('ceiling_fan_efficiency', user_arguments),
             ceiling_fan_quantity: runner.getIntegerArgumentValue('ceiling_fan_quantity', user_arguments),
             ceiling_fan_cooling_setpoint_temp_offset: runner.getDoubleArgumentValue('ceiling_fan_cooling_setpoint_temp_offset', user_arguments),
             plug_loads_plug_load_type: (1..Constants.MaxNumPlugLoads).to_a.map { |n| runner.getStringArgumentValue("plug_loads_plug_load_type_#{n}", user_arguments) },
             plug_loads_annual_kwh: (1..Constants.MaxNumPlugLoads).to_a.map { |n| runner.getDoubleArgumentValue("plug_loads_annual_kwh_#{n}", user_arguments) },
             plug_loads_frac_sensible: (1..Constants.MaxNumPlugLoads).to_a.map { |n| runner.getDoubleArgumentValue("plug_loads_frac_sensible_#{n}", user_arguments) },
             plug_loads_frac_latent: (1..Constants.MaxNumPlugLoads).to_a.map { |n| runner.getDoubleArgumentValue("plug_loads_frac_latent_#{n}", user_arguments) },
             plug_loads_schedule_values: runner.getBoolArgumentValue('plug_loads_schedule_values', user_arguments),
             plug_loads_weekday_fractions: runner.getStringArgumentValue('plug_loads_weekday_fractions', user_arguments),
             plug_loads_weekend_fractions: runner.getStringArgumentValue('plug_loads_weekend_fractions', user_arguments),
             plug_loads_monthly_multipliers: runner.getStringArgumentValue('plug_loads_monthly_multipliers', user_arguments) }

    # Argument error checks
    errors = check_for_argument_errors(args)
    unless errors.empty?
      errors.each do |error|
        runner.registerError(error)
      end
      return false
    end

    # Create HPXML file
    hpxml_doc = HPXMLFile.create(runner, model, args)
    if not hpxml_doc
      runner.registerError('Unsuccessful creation of HPXML file.')
      return false
    end

    hpxml_path = args[:hpxml_path]
    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(File.join(File.dirname(__FILE__), hpxml_path))
    end

    # Check for invalid HPXML file
    schemas_dir = File.join(File.dirname(__FILE__), '../HPXMLtoOpenStudio/resources')
    skip_validation = false
    if not skip_validation
      if not validate_hpxml(runner, hpxml_path, hpxml_doc, schemas_dir)
        return false
      end
    end

    XMLHelper.write_file(hpxml_doc, hpxml_path)
    runner.registerInfo("Wrote file: #{hpxml_path}")
  end

  def check_for_argument_errors(args)
    errors = []

    error = ([HPXML::WaterHeaterTypeHeatPump].include?(args[:water_heater_type]) && (args[:water_heater_fuel_type] != HPXML::FuelTypeElectricity))
    errors << "water_heater_type=#{args[:water_heater_type]} and water_heater_fuel_type=#{args[:water_heater_fuel_type]}" if error

    return errors
  end

  def validate_hpxml(runner, hpxml_path, hpxml_doc, schemas_dir)
    is_valid = true

    if schemas_dir
      unless (Pathname.new schemas_dir).absolute?
        schemas_dir = File.expand_path(File.join(File.dirname(__FILE__), schemas_dir))
      end
      unless Dir.exist?(schemas_dir)
        runner.registerError("'#{schemas_dir}' does not exist.")
        return false
      end
    else
      schemas_dir = nil
    end

    # Validate input HPXML against schema
    if not schemas_dir.nil?
      XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, 'HPXML.xsd'), runner).each do |error|
        puts error
        runner.registerError("#{hpxml_path}: #{error}")
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
    success = create_geometry_envelope(runner, model, args)
    return false if not success

    success = create_schedules(runner, model, args)
    return false if not success

    hpxml = HPXML.new

    set_header(hpxml, runner, args)
    set_site(hpxml, runner, args)
    set_neighbor_buildings(hpxml, runner, args)
    set_building_occupancy(hpxml, runner, args)
    set_building_construction(hpxml, runner, args)
    set_climate_and_risk_zones(hpxml, runner, args)
    set_air_infiltration_measurements(hpxml, runner, args)
    set_attics(hpxml, runner, model, args)
    set_foundations(hpxml, runner, model, args)
    set_roofs(hpxml, runner, model, args)
    set_rim_joists(hpxml, runner, model, args)
    set_walls(hpxml, runner, model, args)
    set_foundation_walls(hpxml, runner, model, args)
    set_frame_floors(hpxml, runner, model, args)
    set_slabs(hpxml, runner, model, args)
    set_windows(hpxml, runner, model, args)
    set_skylights(hpxml, runner, model, args)
    set_doors(hpxml, runner, model, args)
    set_heating_systems(hpxml, runner, args)
    set_cooling_systems(hpxml, runner, args)
    set_heat_pumps(hpxml, runner, args)
    set_hvac_distribution(hpxml, runner, args)
    set_hvac_control(hpxml, runner, args)
    set_ventilation_fans(hpxml, runner, args)
    set_water_heating_systems(hpxml, runner, args)
    set_hot_water_distribution(hpxml, runner, args)
    set_water_fixtures(hpxml, runner, args)
    set_solar_thermal(hpxml, runner, args)
    set_pv_systems(hpxml, runner, args)
    set_clothes_washer(hpxml, runner, args)
    set_clothes_dryer(hpxml, runner, args)
    set_dishwasher(hpxml, runner, args)
    set_refrigerator(hpxml, runner, args)
    set_cooking_range(hpxml, runner, args)
    set_oven(hpxml, runner, args)
    set_lighting(hpxml, runner, args)
    set_ceiling_fans(hpxml, runner, args)
    set_plug_loads(hpxml, runner, args)
    set_misc_loads_schedule(hpxml, runner, args)

    success = remove_geometry_envelope(model)
    return false if not success

    hpxml_doc = hpxml.to_rexml()
    HPXML::add_extension(parent: hpxml_doc.elements['/HPXML/Building/BuildingDetails'],
                         extensions: { "UnitMultiplier": args[:unit_multiplier] })

    return hpxml_doc
  end

  def self.create_geometry_envelope(runner, model, args)
    if (args[:unit_type] == 'multifamily') && (args[:level] != 'Bottom')
      args[:foundation_type] = HPXML::LocationOtherHousingUnitBelow
      args[:foundation_height] = 0.0
    end

    if args[:unit_type] == 'single-family detached'
      success = Geometry.create_single_family_detached(runner: runner, model: model, **args)
    elsif args[:unit_type] == 'single-family attached'
      success = Geometry.create_single_family_attached(runner: runner, model: model, **args)
    elsif args[:unit_type] == 'multifamily'
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

  def self.set_header(hpxml, runner, args)
    hpxml.set_header(xml_type: 'HPXML',
                     xml_generated_by: 'BuildResidentialHPXML',
                     transaction: 'create',
                     building_id: 'MyBuilding',
                     event_type: 'proposed workscope')

    if args[:timestep] != 60
      hpxml.header.timestep = args[:timestep]
    end
  end

  def self.set_site(hpxml, runner, args)
    return if args[:shelter_coefficient] == Constants.Auto

    hpxml.site.shelter_coefficient = args[:shelter_coefficient]
  end

  def self.set_neighbor_buildings(hpxml, runner, args)
    args[:neighbor_distance].each_with_index do |distance, i|
      next if distance == 0

      if i == 0 # front
        azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 0, args[:orientation], 0)
      elsif i == 1 # back
        azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 180, args[:orientation], 0)
      elsif i == 2 # left
        azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 90, args[:orientation], 0)
      elsif i == 3 # right
        azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 270, args[:orientation], 0)
      end

      height = nil
      if distance > 0
        if args[:neighbor_height][i] > 0
          height = args[:neighbor_height][i]
        end
      end

      hpxml.neighbor_buildings.add(azimuth: azimuth,
                                   distance: distance,
                                   height: height)
    end
  end

  def self.set_building_occupancy(hpxml, runner, args)
    unless args[:num_occupants] == Constants.Auto
      hpxml.building_occupancy.number_of_residents = args[:num_occupants]
    end
    hpxml.building_occupancy.schedules_output_path = args[:schedules_output_path]
    hpxml.building_occupancy.schedules_column_name = 'occupants'
  end

  def self.set_building_construction(hpxml, runner, args)
    number_of_conditioned_floors_above_grade = args[:num_floors]

    number_of_conditioned_floors = number_of_conditioned_floors_above_grade
    if args[:foundation_type] == HPXML::FoundationTypeBasementConditioned
      number_of_conditioned_floors += 1
    end

    if args[:num_bathrooms] != Constants.Auto
      number_of_bathrooms = args[:num_bathrooms]
    end

    conditioned_building_volume = args[:cfa] * args[:wall_height]

    fraction_of_operable_window_area = args[:window_fraction_of_operable_area]

    hpxml.set_building_construction(number_of_conditioned_floors: number_of_conditioned_floors,
                                    number_of_conditioned_floors_above_grade: number_of_conditioned_floors_above_grade,
                                    number_of_bedrooms: args[:num_bedrooms],
                                    number_of_bathrooms: number_of_bathrooms,
                                    conditioned_floor_area: args[:cfa],
                                    conditioned_building_volume: conditioned_building_volume,
                                    fraction_of_operable_window_area: fraction_of_operable_window_area)
  end

  def self.set_climate_and_risk_zones(hpxml, runner, args)
    hpxml.set_climate_and_risk_zones(weather_station_id: 'WeatherStation',
                                     weather_station_name: args[:weather_station_epw_filename].gsub('.epw', ''),
                                     weather_station_epw_filename: args[:weather_station_epw_filename])
  end

  def self.set_attics(hpxml, runner, model, args)
    return if args[:unit_type] == 'multifamily'
    return if args[:unit_type] == 'single-family attached' # TODO: remove when we can model single-family attached units

    hpxml.attics.add(id: args[:attic_type],
                     attic_type: args[:attic_type])
  end

  def self.set_foundations(hpxml, runner, model, args)
    return if args[:unit_type] == 'multifamily'

    hpxml.foundations.add(id: args[:foundation_type],
                          foundation_type: args[:foundation_type])

    if args[:foundation_type] == HPXML::FoundationTypeCrawlspaceVented
      hpxml.foundations[-1].vented_crawlspace_sla = args[:vented_crawlspace_sla]
    end
  end

  def self.set_air_infiltration_measurements(hpxml, runner, args)
    if args[:living_air_leakage_units] == HPXML::UnitsACH50
      house_pressure = 50
      unit_of_measure = HPXML::UnitsACH
      air_leakage = args[:living_air_leakage_value]
    elsif args[:living_air_leakage_units] == HPXML::UnitsCFM50
      house_pressure = 50
      unit_of_measure = HPXML::UnitsCFM
      air_leakage = args[:living_air_leakage_value]
    elsif args[:living_air_leakage_units] == HPXML::UnitsACHNatural
      constant_ach_natural = args[:living_air_leakage_value]
    end
    infiltration_volume = args[:cfa] * args[:wall_height]

    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            house_pressure: house_pressure,
                                            unit_of_measure: unit_of_measure,
                                            air_leakage: air_leakage,
                                            constant_ach_natural: constant_ach_natural,
                                            infiltration_volume: infiltration_volume)
  end

  def self.get_adjacent_to(model, surface)
    space = surface.space.get
    st = space.spaceType.get
    space_type = st.standardsSpaceType.get

    if ['vented crawlspace'].include? space_type
      return HPXML::LocationCrawlspaceVented
    elsif ['unvented crawlspace'].include? space_type
      return HPXML::LocationCrawlspaceUnvented
    elsif ['garage'].include? space_type
      return HPXML::LocationGarage
    elsif ['living space'].include? space_type
      if Geometry.space_is_below_grade(space)
        return HPXML::LocationBasementConditioned
      else
        return HPXML::LocationLivingSpace
      end
    elsif ['vented attic'].include? space_type
      return HPXML::LocationAtticVented
    elsif ['unvented attic'].include? space_type
      return HPXML::LocationAtticUnvented
    elsif ['unconditioned basement'].include? space_type
      return HPXML::LocationBasementUnconditioned
    elsif ['corridor'].include? space_type
      return HPXML::LocationLivingSpace # FIXME: update to handle new enum
    elsif ['ambient'].include? space_type
      return HPXML::LocationOutside
    else
      fail "Unhandled SpaceType value (#{space_type}) for surface '#{surface.name}'."
    end
  end

  def self.set_roofs(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      next unless ['Outdoors'].include? surface.outsideBoundaryCondition
      next if surface.surfaceType != 'RoofCeiling'

      interior_adjacent_to = get_adjacent_to(model, surface)

      pitch = args[:roof_pitch] * 12.0
      if args[:roof_type] == 'flat'
        pitch = 0.0
      end

      hpxml.roofs.add(id: "#{surface.name}",
                      interior_adjacent_to: get_adjacent_to(model, surface),
                      area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2').round,
                      solar_absorptance: args[:roof_solar_absorptance],
                      emittance: args[:roof_emittance],
                      pitch: pitch,
                      radiant_barrier: args[:roof_radiant_barrier])

      if interior_adjacent_to.include? 'attic'
        hpxml.roofs[-1].insulation_assembly_r_value = args[:attic_ceiling_r] # FIXME: Calculate
      elsif interior_adjacent_to == HPXML::LocationLivingSpace
        hpxml.roofs[-1].insulation_assembly_r_value = args[:roof_ceiling_r] # FIXME: Calculate
      elsif interior_adjacent_to == HPXML::LocationGarage
        hpxml.roofs[-1].insulation_assembly_r_value = args[:attic_ceiling_r] # FIXME: Calculate
      end
    end
  end

  def self.set_rim_joists(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      # TODO
    end
  end

  def self.set_walls(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      next if surface.surfaceType != 'Wall'
      next if ['ambient'].include? surface.space.get.spaceType.get.standardsSpaceType.get # FIXME

      interior_adjacent_to = get_adjacent_to(model, surface)
      next unless [HPXML::LocationLivingSpace, HPXML::LocationAtticUnvented, HPXML::LocationAtticVented, HPXML::LocationGarage].include? interior_adjacent_to

      exterior_adjacent_to = HPXML::LocationOutside
      if surface.adjacentSurface.is_initialized
        exterior_adjacent_to = get_adjacent_to(model, surface.adjacentSurface.get)
      elsif surface.outsideBoundaryCondition == 'Adiabatic'
        exterior_adjacent_to = HPXML::LocationOtherHousingUnit
      end
      next if interior_adjacent_to == exterior_adjacent_to
      next if [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include? exterior_adjacent_to

      wall_type = args[:wall_type]
      if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include? interior_adjacent_to
        wall_type = HPXML::WallTypeWoodStud
      end

      hpxml.walls.add(id: "#{surface.name}",
                      exterior_adjacent_to: exterior_adjacent_to,
                      interior_adjacent_to: interior_adjacent_to,
                      wall_type: wall_type,
                      area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2').round,
                      solar_absorptance: args[:wall_solar_absorptance],
                      emittance: args[:wall_emittance])

      if (interior_adjacent_to == HPXML::LocationLivingSpace) && (exterior_adjacent_to == HPXML::LocationOutside)
        hpxml.walls[-1].insulation_assembly_r_value = args[:wall_conditioned_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && (exterior_adjacent_to == HPXML::LocationGarage)
        hpxml.walls[-1].insulation_assembly_r_value = args[:wall_conditioned_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && (exterior_adjacent_to == HPXML::LocationAtticUnvented)
        hpxml.walls[-1].insulation_assembly_r_value = args[:wall_unconditioned_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && (exterior_adjacent_to == HPXML::LocationAtticVented)
        hpxml.walls[-1].insulation_assembly_r_value = args[:wall_unconditioned_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && (exterior_adjacent_to == HPXML::LocationOtherHousingUnit)
        hpxml.walls[-1].insulation_assembly_r_value = args[:wall_unconditioned_r]
      elsif [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented, HPXML::LocationGarage].include? interior_adjacent_to
        hpxml.walls[-1].insulation_assembly_r_value = args[:wall_unconditioned_r]
      end
    end
  end

  def self.set_foundation_walls(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      next unless ['Foundation'].include? surface.outsideBoundaryCondition
      next if surface.surfaceType != 'Wall'

      hpxml.foundation_walls.add(id: "#{surface.name}",
                                 exterior_adjacent_to: HPXML::LocationGround,
                                 interior_adjacent_to: get_adjacent_to(model, surface),
                                 height: args[:foundation_height],
                                 area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2').round,
                                 thickness: 8,
                                 depth_below_grade: args[:foundation_wall_depth_below_grade],
                                 insulation_interior_r_value: 0,
                                 insulation_interior_distance_to_top: 0,
                                 insulation_interior_distance_to_bottom: 0,
                                 insulation_exterior_r_value: args[:foundation_wall_r],
                                 insulation_exterior_distance_to_top: args[:foundation_wall_distance_to_top],
                                 insulation_exterior_distance_to_bottom: args[:foundation_wall_distance_to_bottom])
    end
  end

  def self.set_frame_floors(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      next if surface.outsideBoundaryCondition == 'Foundation'
      next unless ['Floor', 'RoofCeiling'].include? surface.surfaceType
      next if ['ambient'].include? surface.space.get.spaceType.get.standardsSpaceType.get # FIXME

      interior_adjacent_to = get_adjacent_to(model, surface)
      next unless [HPXML::LocationLivingSpace, HPXML::LocationGarage].include? interior_adjacent_to

      exterior_adjacent_to = HPXML::LocationOutside
      if surface.adjacentSurface.is_initialized
        exterior_adjacent_to = get_adjacent_to(model, surface.adjacentSurface.get)
      elsif surface.outsideBoundaryCondition == 'Adiabatic'
        if surface.surfaceType == 'Floor'
          exterior_adjacent_to = HPXML::LocationOtherHousingUnitBelow
        elsif surface.surfaceType == 'RoofCeiling'
          exterior_adjacent_to = HPXML::LocationOtherHousingUnitAbove
        end
      end
      next if interior_adjacent_to == exterior_adjacent_to
      next if (surface.surfaceType == 'RoofCeiling') && (exterior_adjacent_to == HPXML::LocationOutside)
      next if [HPXML::LocationLivingSpace, HPXML::LocationBasementConditioned].include? exterior_adjacent_to

      hpxml.frame_floors.add(id: "#{surface.name}",
                             exterior_adjacent_to: exterior_adjacent_to,
                             interior_adjacent_to: interior_adjacent_to,
                             area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2').round)

      if (interior_adjacent_to == HPXML::LocationLivingSpace) && exterior_adjacent_to.include?(HPXML::LocationAtticUnvented)
        hpxml.frame_floors[-1].insulation_assembly_r_value = args[:attic_floor_conditioned_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && exterior_adjacent_to.include?(HPXML::LocationAtticVented)
        hpxml.frame_floors[-1].insulation_assembly_r_value = args[:attic_floor_conditioned_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && exterior_adjacent_to.include?('crawlspace')
        hpxml.frame_floors[-1].insulation_assembly_r_value = args[:foundation_ceiling_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && exterior_adjacent_to.include?(HPXML::LocationBasementUnconditioned)
        hpxml.frame_floors[-1].insulation_assembly_r_value = args[:foundation_ceiling_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && exterior_adjacent_to.include?(HPXML::LocationOutside)
        hpxml.frame_floors[-1].insulation_assembly_r_value = args[:foundation_ceiling_r]
      elsif (interior_adjacent_to == HPXML::LocationGarage) && (exterior_adjacent_to == HPXML::LocationAtticUnvented)
        hpxml.frame_floors[-1].insulation_assembly_r_value = args[:attic_floor_unconditioned_r]
      elsif (interior_adjacent_to == HPXML::LocationGarage) && (exterior_adjacent_to == HPXML::LocationAtticVented)
        hpxml.frame_floors[-1].insulation_assembly_r_value = args[:attic_floor_unconditioned_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && (exterior_adjacent_to == HPXML::LocationGarage)
        hpxml.frame_floors[-1].insulation_assembly_r_value = args[:attic_floor_conditioned_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && (exterior_adjacent_to == HPXML::LocationOtherHousingUnitBelow)
        hpxml.frame_floors[-1].insulation_assembly_r_value = args[:attic_floor_unconditioned_r]
      elsif (interior_adjacent_to == HPXML::LocationLivingSpace) && (exterior_adjacent_to == HPXML::LocationOtherHousingUnitAbove)
        hpxml.frame_floors[-1].insulation_assembly_r_value = args[:attic_floor_unconditioned_r]
      end
    end
  end

  def self.set_slabs(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      next unless ['Foundation'].include? surface.outsideBoundaryCondition
      next if surface.surfaceType != 'Floor'
      next if ['ambient'].include? surface.space.get.spaceType.get.standardsSpaceType.get # FIXME

      interior_adjacent_to = get_adjacent_to(model, surface)

      has_foundation_walls = false
      if [HPXML::LocationCrawlspaceVented, HPXML::LocationCrawlspaceUnvented, HPXML::LocationBasementUnconditioned, HPXML::LocationBasementConditioned].include? interior_adjacent_to
        has_foundation_walls = true
      end
      exposed_perimeter = Geometry.calculate_exposed_perimeter(model, [surface], has_foundation_walls).round

      if [HPXML::LocationLivingSpace, HPXML::LocationGarage].include? interior_adjacent_to
        depth_below_grade = 0
      end

      under_slab_insulation_width = args[:under_slab_insulation_width]
      if under_slab_insulation_width == 999
        under_slab_insulation_width = nil
        under_slab_insulation_spans_entire_slab = true
      end

      thickness = 4.0
      if interior_adjacent_to.include? 'crawlspace'
        thickness = 0.0
      end

      hpxml.slabs.add(id: "#{surface.name}",
                      interior_adjacent_to: interior_adjacent_to,
                      area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2').round,
                      thickness: thickness,
                      exposed_perimeter: exposed_perimeter,
                      perimeter_insulation_depth: args[:perimeter_insulation_depth],
                      under_slab_insulation_width: under_slab_insulation_width,
                      perimeter_insulation_r_value: args[:perimeter_insulation_r_value],
                      under_slab_insulation_r_value: args[:under_slab_insulation_r_value],
                      under_slab_insulation_spans_entire_slab: under_slab_insulation_spans_entire_slab,
                      depth_below_grade: depth_below_grade,
                      carpet_fraction: args[:carpet_fraction],
                      carpet_r_value: args[:carpet_r_value])
    end
  end

  def self.set_windows(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      surface.subSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType != 'FixedWindow'

        sub_surface_height = Geometry.get_surface_height(sub_surface)
        sub_surface_facade = Geometry.get_facade_for_surface(sub_surface)

        if (sub_surface_facade == Constants.FacadeFront) && (args[:overhangs_front_depth] > 0)
          overhangs_depth = args[:overhangs_front_depth]
          overhangs_distance_to_top_of_window = args[:overhangs_front_distance_to_top_of_window]
          overhangs_distance_to_bottom_of_window = (overhangs_distance_to_top_of_window + sub_surface_height).round
        elsif (sub_surface_facade == Constants.FacadeBack) && (args[:overhangs_back_depth] > 0)
          overhangs_depth = args[:overhangs_back_depth]
          overhangs_distance_to_top_of_window = args[:overhangs_back_distance_to_top_of_window]
          overhangs_distance_to_bottom_of_window = (overhangs_distance_to_top_of_window + sub_surface_height).round
        elsif (sub_surface_facade == Constants.FacadeLeft) && (args[:overhangs_left_depth] > 0)
          overhangs_depth = args[:overhangs_left_depth]
          overhangs_distance_to_top_of_window = args[:overhangs_left_distance_to_top_of_window]
          overhangs_distance_to_bottom_of_window = (overhangs_distance_to_top_of_window + sub_surface_height).round
        elsif (sub_surface_facade == Constants.FacadeRight) && (args[:overhangs_right_depth] > 0)
          overhangs_depth = args[:overhangs_right_depth]
          overhangs_distance_to_top_of_window = args[:overhangs_right_distance_to_top_of_window]
          overhangs_distance_to_bottom_of_window = (overhangs_distance_to_top_of_window + sub_surface_height).round
        elsif args[:eaves_depth] > 0
          eaves_z = args[:wall_height] * args[:num_floors]
          if args[:foundation_type] == HPXML::FoundationTypeAmbient
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
          sub_surface_z = UnitConversions.convert(sub_surface_z, 'm', 'ft')
          overhangs_depth = args[:eaves_depth]
          overhangs_distance_to_top_of_window = eaves_z - sub_surface_z
          overhangs_distance_to_bottom_of_window = (overhangs_distance_to_top_of_window + sub_surface_height).round
        end

        if (sub_surface_facade == Constants.FacadeFront) && (args[:interior_shading_front_factor_winter] > 0)
          interior_shading_factor_winter = args[:interior_shading_front_factor_winter]
        elsif (sub_surface_facade == Constants.FacadeBack) && (args[:interior_shading_back_factor_winter] > 0)
          interior_shading_factor_winter = args[:interior_shading_back_factor_winter]
        elsif (sub_surface_facade == Constants.FacadeLeft) && (args[:interior_shading_left_factor_winter] > 0)
          interior_shading_factor_winter = args[:interior_shading_left_factor_winter]
        elsif (sub_surface_facade == Constants.FacadeRight) && (args[:interior_shading_right_factor_winter] > 0)
          interior_shading_factor_winter = args[:interior_shading_right_factor_winter]
        end

        if (sub_surface_facade == Constants.FacadeFront) && (args[:interior_shading_front_factor_summer] > 0)
          interior_shading_factor_summer = args[:interior_shading_front_factor_summer]
        elsif (sub_surface_facade == Constants.FacadeBack) && (args[:interior_shading_back_factor_summer] > 0)
          interior_shading_factor_summer = args[:interior_shading_back_factor_summer]
        elsif (sub_surface_facade == Constants.FacadeLeft) && (args[:interior_shading_left_factor_summer] > 0)
          interior_shading_factor_summer = args[:interior_shading_left_factor_summer]
        elsif (sub_surface_facade == Constants.FacadeRight) && (args[:interior_shading_right_factor_summer] > 0)
          interior_shading_factor_summer = args[:interior_shading_right_factor_summer]
        end

        if (not interior_shading_factor_winter.nil?) && interior_shading_factor_summer.nil?
          interior_shading_factor_summer = 0.0
        end
        if (not interior_shading_factor_summer.nil?) && interior_shading_factor_winter.nil?
          interior_shading_factor_winter = 0.0
        end

        hpxml.windows.add(id: "#{sub_surface.name}_#{sub_surface_facade}",
                          area: UnitConversions.convert(sub_surface.grossArea, 'm^2', 'ft^2').round,
                          azimuth: UnitConversions.convert(sub_surface.azimuth, 'rad', 'deg').round,
                          ufactor: args[:window_ufactor],
                          shgc: args[:window_shgc],
                          overhangs_depth: overhangs_depth,
                          overhangs_distance_to_top_of_window: overhangs_distance_to_top_of_window,
                          overhangs_distance_to_bottom_of_window: overhangs_distance_to_bottom_of_window,
                          interior_shading_factor_winter: interior_shading_factor_winter,
                          interior_shading_factor_summer: interior_shading_factor_summer,
                          wall_idref: surface.name)
      end
    end
  end

  def self.set_skylights(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      surface.subSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType != 'Skylight'

        sub_surface_facade = Geometry.get_facade_for_surface(sub_surface)

        hpxml.skylights.add(id: "#{sub_surface.name}_#{sub_surface_facade}",
                            area: UnitConversions.convert(sub_surface.grossArea, 'm^2', 'ft^2').round,
                            azimuth: UnitConversions.convert(sub_surface.azimuth, 'rad', 'deg').round,
                            ufactor: args[:skylight_ufactor],
                            shgc: args[:skylight_shgc],
                            roof_idref: surface.name)
      end
    end
  end

  def self.set_doors(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      surface.subSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType != 'Door'

        sub_surface_facade = Geometry.get_facade_for_surface(sub_surface)

        hpxml.doors.add(id: "#{sub_surface.name}_#{sub_surface_facade}",
                        wall_idref: surface.name,
                        area: UnitConversions.convert(sub_surface.grossArea, 'm^2', 'ft^2').round,
                        azimuth: args[:orientation],
                        r_value: args[:door_rvalue])
      end
    end
  end

  def self.set_heating_systems(hpxml, runner, args)
    heating_system_type = args[:heating_system_type]

    return if heating_system_type == 'none'

    heating_capacity = args[:heating_system_heating_capacity]
    if heating_capacity == Constants.SizingAuto
      heating_capacity = -1
    end
    heating_capacity = Float(heating_capacity)

    if args[:heating_system_electric_auxiliary_energy] > 0
      electric_auxiliary_energy = args[:heating_system_electric_auxiliary_energy]
    end

    hpxml.heating_systems.add(id: 'HeatingSystem',
                              heating_system_type: heating_system_type,
                              heating_system_fuel: args[:heating_system_fuel],
                              heating_capacity: heating_capacity,
                              fraction_heat_load_served: args[:heating_system_fraction_heat_load_served],
                              electric_auxiliary_energy: electric_auxiliary_energy)

    if [HPXML::HVACTypeFurnace, HPXML::HVACTypeWallFurnace, HPXML::HVACTypeBoiler].include? heating_system_type
      hpxml.heating_systems[-1].heating_efficiency_afue = args[:heating_system_heating_efficiency]
    elsif [HPXML::HVACTypeElectricResistance, HPXML::HVACTypeStove, HPXML::HVACTypePortableHeater]
      hpxml.heating_systems[-1].heating_efficiency_percent = args[:heating_system_heating_efficiency]
    end
  end

  def self.set_cooling_systems(hpxml, runner, args)
    cooling_system_type = args[:cooling_system_type]

    return if cooling_system_type == 'none'

    cooling_capacity = args[:cooling_system_cooling_capacity]
    if cooling_capacity == Constants.SizingAuto
      cooling_capacity = -1
    end
    cooling_capacity = Float(cooling_capacity)

    if cooling_system_type == HPXML::HVACTypeEvaporativeCooler
      cooling_capacity = nil
    end

    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              cooling_system_type: cooling_system_type,
                              cooling_system_fuel: args[:cooling_system_fuel],
                              cooling_capacity: cooling_capacity,
                              fraction_cool_load_served: args[:cooling_system_fraction_cool_load_served])

    if [HPXML::HVACTypeCentralAirConditioner].include? cooling_system_type
      hpxml.cooling_systems[-1].cooling_efficiency_seer = args[:cooling_system_cooling_efficiency]
    elsif [HPXML::HVACTypeRoomAirConditioner].include? cooling_system_type
      hpxml.cooling_systems[-1].cooling_efficiency_eer = args[:cooling_system_cooling_efficiency]
    end
  end

  def self.set_heat_pumps(hpxml, runner, args)
    heat_pump_type = args[:heat_pump_type]

    return if heat_pump_type == 'none'

    heat_pump_fuel = args[:heat_pump_fuel]

    heating_capacity = args[:heat_pump_heating_capacity]
    if heating_capacity == Constants.SizingAuto
      heating_capacity = -1
    end
    heating_capacity = Float(heating_capacity)

    if args[:heat_pump_backup_fuel] != 'none'
      backup_heating_fuel = args[:heat_pump_backup_fuel]

      backup_heating_capacity = args[:heat_pump_backup_heating_capacity]
      if backup_heating_capacity == Constants.SizingAuto
        backup_heating_capacity = -1
      end
      backup_heating_capacity = Float(backup_heating_capacity)

      if backup_heating_fuel == HPXML::FuelTypeElectricity
        backup_heating_efficiency_percent = args[:heat_pump_backup_heating_efficiency]
      else
        backup_heating_efficiency_afue = args[:heat_pump_backup_heating_efficiency]
        backup_heating_switchover_temp = 25.0
      end
    end

    cooling_capacity = args[:heat_pump_cooling_capacity]
    if cooling_capacity == Constants.SizingAuto
      cooling_capacity = -1
    end
    cooling_capacity = Float(cooling_capacity)

    hpxml.heat_pumps.add(id: 'HeatPump',
                         heat_pump_type: heat_pump_type,
                         heat_pump_fuel: heat_pump_fuel,
                         heating_capacity: heating_capacity,
                         cooling_capacity: cooling_capacity,
                         fraction_heat_load_served: args[:heat_pump_fraction_heat_load_served],
                         fraction_cool_load_served: args[:heat_pump_fraction_cool_load_served],
                         backup_heating_fuel: backup_heating_fuel,
                         backup_heating_capacity: backup_heating_capacity,
                         backup_heating_efficiency_afue: backup_heating_efficiency_afue,
                         backup_heating_efficiency_percent: backup_heating_efficiency_percent,
                         backup_heating_switchover_temp: backup_heating_switchover_temp)

    if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump_type
      hpxml.heat_pumps[-1].heating_efficiency_hspf = args[:heat_pump_heating_efficiency]
      hpxml.heat_pumps[-1].cooling_efficiency_seer = args[:heat_pump_cooling_efficiency]
    elsif [HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump_type
      hpxml.heat_pumps[-1].heating_efficiency_cop = args[:heat_pump_heating_efficiency]
      hpxml.heat_pumps[-1].cooling_efficiency_eer = args[:heat_pump_cooling_efficiency]
    end
  end

  def self.set_hvac_distribution(hpxml, runner, args)
    # HydronicDistribution?
    hpxml.heating_systems.each do |heating_system|
      next unless [HPXML::HVACTypeBoiler].include? heating_system.heating_system_type

      hpxml.hvac_distributions.add(id: 'HydronicDistribution',
                                   distribution_system_type: HPXML::HVACDistributionTypeHydronic)
      heating_system.distribution_system_idref = hpxml.hvac_distributions[-1].id
      break
    end

    # AirDistribution?
    air_distribution_systems = []
    hpxml.heating_systems.each do |heating_system|
      if [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type
        air_distribution_systems << heating_system
      end
    end
    hpxml.cooling_systems.each do |cooling_system|
      if [HPXML::HVACTypeCentralAirConditioner].include? cooling_system.cooling_system_type
        air_distribution_systems << cooling_system
      elsif [HPXML::HVACTypeEvaporativeCooler].include?(cooling_system.cooling_system_type) && args[:evap_cooler_is_ducted]
        air_distribution_systems << cooling_system
      end
    end
    hpxml.heat_pumps.each do |heat_pump|
      if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type
        air_distribution_systems << heat_pump
      elsif [HPXML::HVACTypeHeatPumpMiniSplit].include?(heat_pump.heat_pump_type) && args[:mini_split_is_ducted]
        air_distribution_systems << heat_pump
      end
    end
    return unless air_distribution_systems.size > 0

    hpxml.hvac_distributions.add(id: 'AirDistribution',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir)

    air_distribution_systems.each do |hvac_system|
      hvac_system.distribution_system_idref = hpxml.hvac_distributions[-1].id
    end

    # Duct Leakage
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                               duct_leakage_units: args[:supply_duct_leakage_units],
                                                               duct_leakage_value: args[:supply_duct_leakage_value])

    if not ((args[:cooling_system_type] == HPXML::HVACTypeEvaporativeCooler) && args[:evap_cooler_is_ducted])
      hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                                 duct_leakage_units: args[:return_duct_leakage_units],
                                                                 duct_leakage_value: args[:return_duct_leakage_value])
    end

    # Ducts
    supply_duct_location = args[:supply_duct_location]
    if supply_duct_location == Constants.Auto
      supply_duct_location = get_duct_location_auto(args, hpxml)
    end

    return_duct_location = args[:return_duct_location]
    if return_duct_location == Constants.Auto
      return_duct_location = get_duct_location_auto(args, hpxml)
    end

    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                           duct_insulation_r_value: args[:supply_duct_insulation_r_value],
                                           duct_location: supply_duct_location,
                                           duct_surface_area: args[:supply_duct_surface_area])

    if not ((args[:cooling_system_type] == HPXML::HVACTypeEvaporativeCooler) && args[:evap_cooler_is_ducted])
      hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                             duct_insulation_r_value: args[:return_duct_insulation_r_value],
                                             duct_location: return_duct_location,
                                             duct_surface_area: args[:return_duct_surface_area])
    end
  end

  def self.set_hvac_control(hpxml, runner, args)
    return if (args[:heating_system_type] == 'none') && (args[:cooling_system_type] == 'none') && (args[:heat_pump_type] == 'none')

    control_type = HPXML::HVACControlTypeManual
    if ((args[:heating_setpoint_temp] != args[:heating_setback_temp]) && (args[:heating_setback_hours_per_week] > 0)) ||
       ((args[:cooling_setpoint_temp] != args[:cooling_setup_temp]) && (args[:cooling_setup_hours_per_week] > 0))
      control_type = HPXML::HVACControlTypeProgrammable
    end

    if (args[:heating_setpoint_temp] != args[:heating_setback_temp]) && (args[:heating_setback_hours_per_week] > 0)
      heating_setback_temp = args[:heating_setback_temp]
      heating_setback_hours_per_week = args[:heating_setback_hours_per_week]
      heating_setback_start_hour = args[:heating_setback_start_hour]
    end

    if (args[:cooling_setpoint_temp] != args[:cooling_setup_temp]) && (args[:cooling_setup_hours_per_week] > 0)
      cooling_setup_temp = args[:cooling_setup_temp]
      cooling_setup_hours_per_week = args[:cooling_setup_hours_per_week]
      cooling_setup_start_hour = args[:cooling_setup_start_hour]
    end

    if args[:ceiling_fan_cooling_setpoint_temp_offset] > 0
      ceiling_fan_cooling_setpoint_temp_offset = args[:ceiling_fan_cooling_setpoint_temp_offset]
    end

    hpxml.hvac_controls.add(id: 'HVACControl',
                            control_type: control_type,
                            heating_setpoint_temp: args[:heating_setpoint_temp],
                            cooling_setpoint_temp: args[:cooling_setpoint_temp],
                            heating_setback_temp: heating_setback_temp,
                            heating_setback_hours_per_week: heating_setback_hours_per_week,
                            heating_setback_start_hour: heating_setback_start_hour,
                            cooling_setup_temp: cooling_setup_temp,
                            cooling_setup_hours_per_week: cooling_setup_hours_per_week,
                            cooling_setup_start_hour: cooling_setup_start_hour,
                            ceiling_fan_cooling_setpoint_temp_offset: ceiling_fan_cooling_setpoint_temp_offset)
  end

  def self.get_duct_location_auto(args, hpxml) # FIXME
    if args[:roof_type] != 'flat' && hpxml.attics.size > 0 && [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented].include?(args[:attic_type])
      location = hpxml.attics[0].to_location
    elsif hpxml.foundations.size > 0 && (args[:foundation_type].downcase.include?('basement') || args[:foundation_type].downcase.include?('crawlspace'))
      location = hpxml.foundations[0].to_location
    else
      location = HPXML::LocationLivingSpace
    end
    return location
  end

  def self.get_kitchen_appliance_location_auto(args) # FIXME
    location = HPXML::LocationLivingSpace
    return location
  end

  def self.get_other_appliance_location_auto(args, hpxml) # FIXME
    if hpxml.foundations.size > 0 && (args[:foundation_type].downcase.include?('basement') || args[:foundation_type].downcase.include?('crawlspace'))
      location = hpxml.foundations[0].to_location
    else
      location = HPXML::LocationLivingSpace
    end
    return location
  end

  def self.set_ventilation_fans(hpxml, runner, args)
    return if (args[:mech_vent_fan_type] == 'none') && (not args[:has_whole_house_fan])

    if args[:mech_vent_fan_type] != 'none'

      if args[:mech_vent_fan_type].include? 'recovery ventilator'

        if args[:mech_vent_fan_type].include? 'energy'

          if args[:mech_vent_total_recovery_efficiency_type] == 'Unadjusted'
            total_recovery_efficiency = args[:mech_vent_total_recovery_efficiency]
          elsif args[:mech_vent_total_recovery_efficiency_type] == 'Adjusted'
            total_recovery_efficiency_adjusted = args[:mech_vent_total_recovery_efficiency]
          end

        end

        if args[:mech_vent_sensible_recovery_efficiency_type] == 'Unadjusted'
          sensible_recovery_efficiency = args[:mech_vent_sensible_recovery_efficiency]
        elsif args[:mech_vent_sensible_recovery_efficiency_type] == 'Adjusted'
          sensible_recovery_efficiency_adjusted = args[:mech_vent_sensible_recovery_efficiency]
        end

      end

      distribution_system_idref = nil
      if args[:mech_vent_fan_type] == HPXML::MechVentTypeCFIS
        hpxml.hvac_distributions.each do |hvac_distribution|
          next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

          distribution_system_idref = hvac_distribution.id
        end
      end

      hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                                 fan_type: args[:mech_vent_fan_type],
                                 tested_flow_rate: args[:mech_vent_flow_rate],
                                 hours_in_operation: args[:mech_vent_hours_in_operation],
                                 used_for_whole_building_ventilation: true,
                                 total_recovery_efficiency: total_recovery_efficiency,
                                 total_recovery_efficiency_adjusted: total_recovery_efficiency_adjusted,
                                 sensible_recovery_efficiency: sensible_recovery_efficiency,
                                 sensible_recovery_efficiency_adjusted: sensible_recovery_efficiency_adjusted,
                                 fan_power: args[:mech_vent_fan_power],
                                 distribution_system_idref: distribution_system_idref)
    end

    if args[:has_whole_house_fan]
      hpxml.ventilation_fans.add(id: 'WholeHouseFan',
                                 rated_flow_rate: args[:whole_house_fan_flow_rate],
                                 used_for_seasonal_cooling_load_reduction: true,
                                 fan_power: args[:whole_house_fan_power])
    end
  end

  def self.set_water_heating_systems(hpxml, runner, args)
    water_heater_type = args[:water_heater_type]
    return if water_heater_type == 'none'

    fuel_type = args[:water_heater_fuel_type]

    location = args[:water_heater_location]
    if location == Constants.Auto
      location = get_other_appliance_location_auto(args, hpxml)
    end

    num_bathrooms = args[:num_bathrooms]
    if num_bathrooms == Constants.Auto
      num_bathrooms = 2 # FIXME
    end
    num_bathrooms = Float(num_bathrooms)

    tank_volume = Waterheater.calc_nom_tankvol(args[:water_heater_tank_volume], fuel_type, args[:num_bedrooms], num_bathrooms).round

    heating_capacity = args[:water_heater_heating_capacity]
    if heating_capacity == Constants.SizingAuto
      heating_capacity = Waterheater.calc_water_heater_capacity(fuel_type, args[:num_bedrooms], 1, num_bathrooms)
    else
      heating_capacity = Float(heating_capacity)
    end
    heating_capacity = UnitConversions.convert(heating_capacity, 'kBtu/hr', 'Btu/hr').round

    if water_heater_type == HPXML::WaterHeaterTypeHeatPump
      heating_capacity = nil
    end

    if args[:water_heater_efficiency_type] == 'EnergyFactor'
      energy_factor = args[:water_heater_efficiency]
      energy_factor = Waterheater.calc_ef(energy_factor, tank_volume, fuel_type).round(2)
    elsif args[:water_heater_efficiency_type] == 'UniformEnergyFactor'
      uniform_energy_factor = args[:water_heater_efficiency]
    end

    recovery_efficiency = args[:water_heater_recovery_efficiency]
    if fuel_type == HPXML::FuelTypeElectricity
      recovery_efficiency = nil
    end

    if [HPXML::WaterHeaterTypeTankless].include? water_heater_type
      tank_volume = nil
      heating_capacity = nil
      recovery_efficiency = nil
    elsif [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? water_heater_type
      if water_heater_type == HPXML::WaterHeaterTypeCombiTankless
        tank_volume = nil
      end
      fuel_type = nil
      heating_capacity = nil
      energy_factor = nil

      if hpxml.heating_systems.size == 0
        fail 'Combi boiler water heater specified but no heating system found.'
      end

      related_hvac_idref = hpxml.heating_systems[0].id
    end

    standby_loss = nil
    if args[:water_heater_standby_loss] > 0
      standby_loss = args[:water_heater_standby_loss]
    end

    jacket_r_value = nil
    if args[:water_heater_jacket_rvalue] > 0
      jacket_r_value = args[:water_heater_jacket_rvalue]
    end

    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    water_heater_type: water_heater_type,
                                    fuel_type: fuel_type,
                                    location: location,
                                    tank_volume: tank_volume,
                                    fraction_dhw_load_served: 1.0,
                                    heating_capacity: heating_capacity,
                                    energy_factor: energy_factor,
                                    uniform_energy_factor: uniform_energy_factor,
                                    recovery_efficiency: recovery_efficiency,
                                    related_hvac_idref: related_hvac_idref,
                                    standby_loss: standby_loss,
                                    jacket_r_value: jacket_r_value)
  end

  def self.set_hot_water_distribution(hpxml, runner, args)
    return if args[:water_heater_type] == 'none'

    if args[:dwhr_facilities_connected] != 'none'
      dwhr_facilities_connected = args[:dwhr_facilities_connected]
      dwhr_equal_flow = args[:dwhr_equal_flow]
      dwhr_efficiency = args[:dwhr_efficiency]
    end

    hpxml.hot_water_distributions.add(id: 'HotWaterDistribution',
                                      system_type: args[:hot_water_distribution_system_type],
                                      standard_piping_length: args[:standard_piping_length],
                                      recirculation_control_type: args[:recirculation_control_type],
                                      recirculation_piping_length: args[:recirculation_piping_length],
                                      recirculation_branch_piping_length: args[:recirculation_branch_piping_length],
                                      recirculation_pump_power: args[:recirculation_pump_power],
                                      pipe_r_value: args[:hot_water_distribution_pipe_r_value],
                                      dwhr_facilities_connected: dwhr_facilities_connected,
                                      dwhr_equal_flow: dwhr_equal_flow,
                                      dwhr_efficiency: dwhr_efficiency)
  end

  def self.set_water_fixtures(hpxml, runer, args)
    return if args[:water_heater_type] == 'none'

    hpxml.water_fixtures.add(id: 'ShowerFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: args[:shower_low_flow])
    hpxml.water_fixtures.add(id: 'SinkFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: args[:sink_low_flow])
  end

  def self.set_solar_thermal(hpxml, runner, args)
    return if args[:solar_thermal_system_type] == 'none'

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

    if hpxml.water_heating_systems.size == 0
      fail 'Solar thermal system specified but no water heater found.'
    end

    hpxml.solar_thermal_systems.add(id: 'SolarThermalSystem',
                                    system_type: args[:solar_thermal_system_type],
                                    collector_area: collector_area,
                                    collector_loop_type: collector_loop_type,
                                    collector_type: collector_type,
                                    collector_azimuth: collector_azimuth,
                                    collector_tilt: collector_tilt,
                                    collector_frta: collector_frta,
                                    collector_frul: collector_frul,
                                    storage_volume: storage_volume,
                                    water_heating_system_idref: hpxml.water_heating_systems[0].id,
                                    solar_fraction: solar_fraction)
  end

  def self.set_pv_systems(hpxml, runner, args)
    args[:pv_system_module_type].each_with_index do |module_type, i|
      next if module_type == 'none'

      hpxml.pv_systems.add(id: "PVSystem#{i + 1}",
                           location: args[:pv_system_location][i],
                           module_type: module_type,
                           tracking: args[:pv_system_tracking][i],
                           array_azimuth: args[:pv_system_array_azimuth][i],
                           array_tilt: args[:pv_system_array_tilt][i],
                           max_power_output: args[:pv_system_max_power_output][i],
                           inverter_efficiency: args[:pv_system_inverter_efficiency][i],
                           system_losses_fraction: args[:pv_system_system_losses_fraction][i])
    end
  end

  def self.set_clothes_washer(hpxml, runner, args)
    return unless args[:has_clothes_washer]

    location = args[:clothes_washer_location]
    if location == Constants.Auto
      location = get_other_appliance_location_auto(args, hpxml)
    end

    if args[:clothes_washer_efficiency_type] == 'ModifiedEnergyFactor'
      modified_energy_factor = args[:clothes_washer_efficiency]
    elsif args[:clothes_washer_efficiency_type] == 'IntegratedModifiedEnergyFactor'
      integrated_modified_energy_factor = args[:clothes_washer_efficiency]
    end

    hpxml.clothes_washers.add(id: 'ClothesWasher',
                              location: location,
                              modified_energy_factor: modified_energy_factor,
                              integrated_modified_energy_factor: integrated_modified_energy_factor,
                              rated_annual_kwh: args[:clothes_washer_rated_annual_kwh],
                              label_electric_rate: args[:clothes_washer_label_electric_rate],
                              label_gas_rate: args[:clothes_washer_label_gas_rate],
                              label_annual_gas_cost: args[:clothes_washer_label_annual_gas_cost],
                              capacity: args[:clothes_washer_capacity])
  end

  def self.set_clothes_dryer(hpxml, runner, args)
    return unless args[:has_clothes_dryer]

    if args[:clothes_dryer_efficiency_type] == 'EnergyFactor'
      energy_factor = args[:clothes_dryer_efficiency]
    elsif args[:clothes_dryer_efficiency_type] == 'CombinedEnergyFactor'
      combined_energy_factor = args[:clothes_dryer_efficiency]
    end

    location = args[:clothes_dryer_location]
    if location == Constants.Auto
      location = get_other_appliance_location_auto(args, hpxml)
    end

    hpxml.clothes_dryers.add(id: 'ClothesDryer',
                             location: location,
                             fuel_type: args[:clothes_dryer_fuel_type],
                             energy_factor: energy_factor,
                             combined_energy_factor: combined_energy_factor,
                             control_type: args[:clothes_dryer_control_type])
  end

  def self.set_dishwasher(hpxml, runner, args)
    return unless args[:has_dishwasher]

    if args[:dishwasher_efficiency_type] == 'RatedAnnualkWh'
      rated_annual_kwh = args[:dishwasher_efficiency]
    elsif args[:dishwasher_efficiency_type] == 'EnergyFactor'
      energy_factor = args[:dishwasher_efficiency]
    end

    hpxml.dishwashers.add(id: 'Dishwasher',
                          rated_annual_kwh: rated_annual_kwh,
                          energy_factor: energy_factor,
                          place_setting_capacity: args[:dishwasher_place_setting_capacity])
  end

  def self.set_refrigerator(hpxml, runner, args)
    return unless args[:has_refrigerator]

    location = args[:refrigerator_location]
    if location == Constants.Auto
      location = get_kitchen_appliance_location_auto(args)
    end

    if args[:refrigerator_adjusted_annual_kwh] > 0
      adjusted_annual_kwh = args[:refrigerator_adjusted_annual_kwh]
    end

    hpxml.refrigerators.add(id: 'Refrigerator',
                            location: location,
                            rated_annual_kwh: args[:refrigerator_rated_annual_kwh],
                            adjusted_annual_kwh: adjusted_annual_kwh,
                            schedules_output_path: args[:schedules_output_path],
                            schedules_column_name: 'refrigerator')
  end

  def self.set_cooking_range(hpxml, runner, args)
    return unless args[:has_cooking_range]

    hpxml.cooking_ranges.add(id: 'CookingRange',
                             fuel_type: args[:cooking_range_fuel_type],
                             is_induction: args[:cooking_range_is_induction])
  end

  def self.set_oven(hpxml, runner, args)
    return unless args[:has_oven]

    hpxml.ovens.add(id: 'Oven',
                    is_convection: args[:oven_is_convection])
  end

  def self.set_lighting(hpxml, runner, args)
    return unless args[:has_lighting]

    hpxml.lighting_groups.add(id: 'Lighting_TierI_Interior',
                              location: HPXML::LocationInterior,
                              fration_of_units_in_location: 0.5,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Exterior',
                              location: HPXML::LocationExterior,
                              fration_of_units_in_location: 0.5,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Garage',
                              location: HPXML::LocationGarage,
                              fration_of_units_in_location: 0.5,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Interior',
                              location: HPXML::LocationInterior,
                              fration_of_units_in_location: 0.25,
                              third_party_certification: HPXML::LightingTypeTierII)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Exterior',
                              location: HPXML::LocationExterior,
                              fration_of_units_in_location: 0.25,
                              third_party_certification: HPXML::LightingTypeTierII)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Garage',
                              location: HPXML::LocationGarage,
                              fration_of_units_in_location: 0.25,
                              third_party_certification: HPXML::LightingTypeTierII)
  end

  def self.set_ceiling_fans(hpxml, runner, args)
    return if args[:ceiling_fan_quantity] == 0

    hpxml.ceiling_fans.add(id: 'CeilingFan',
                           efficiency: args[:ceiling_fan_efficiency],
                           quantity: args[:ceiling_fan_quantity])
  end

  def self.set_plug_loads(hpxml, runner, args)
    plug_loads_values = []
    args[:plug_loads_plug_load_type].each_with_index do |plug_load_type, i|
      next if plug_load_type == 'none'

      if args[:plug_loads_annual_kwh][i] > 0
        kWh_per_year = args[:plug_loads_annual_kwh][i]
      end

      if args[:plug_loads_frac_sensible][i] > 0
        frac_sensible = args[:plug_loads_frac_sensible][i]
      end

      if args[:plug_loads_frac_latent][i] > 0
        frac_latent = args[:plug_loads_frac_latent][i]
      end

      hpxml.plug_loads.add(id: "PlugLoadMisc#{i + 1}",
                           plug_load_type: plug_load_type,
                           kWh_per_year: kWh_per_year,
                           frac_sensible: frac_sensible,
                           frac_latent: frac_latent)
    end
  end

  def self.set_misc_loads_schedule(hpxml, runner, args)
    return unless args[:plug_loads_schedule_values]

    hpxml.set_misc_loads_schedule(weekday_fractions: args[:plug_loads_weekday_fractions],
                                  weekend_fractions: args[:plug_loads_weekend_fractions],
                                  monthly_multipliers: args[:plug_loads_monthly_multipliers])
  end
end

# register the measure to be used by the application
BuildResidentialHPXML.new.registerWithApplication
