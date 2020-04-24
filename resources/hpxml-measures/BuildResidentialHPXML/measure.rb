# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'

require_relative 'resources/geometry'
require_relative 'resources/schedules'
require_relative 'resources/constants'
require_relative 'resources/location'

require_relative '../HPXMLtoOpenStudio/resources/EPvalidator'
require_relative '../HPXMLtoOpenStudio/resources/constructions'
require_relative '../HPXMLtoOpenStudio/resources/hpxml'
require_relative '../HPXMLtoOpenStudio/resources/schedules'

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

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('weather_dir', true)
    arg.setDisplayName('Weather Directory')
    arg.setDescription('Absolute/relative path of the weather directory.')
    arg.setDefaultValue('weather')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_timestep', false)
    arg.setDisplayName('Simulation Control: Timestep')
    arg.setUnits('min')
    arg.setDescription('Value must be a divisor of 60.')
    arg.setDefaultValue(60)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_begin_month', false)
    arg.setDisplayName('Simulation Control: Run Period Begin Month')
    arg.setUnits('month')
    arg.setDescription('This numeric field should contain the starting month number (1 = January, 2 = February, etc.) for the annual run period desired.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_begin_day_of_month', false)
    arg.setDisplayName('Simulation Control: Run Period Begin Day of Month')
    arg.setUnits('day')
    arg.setDescription('This numeric field should contain the starting day of the starting month (must be valid for month) for the annual run period desired.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_end_month', false)
    arg.setDisplayName('Simulation Control: Run Period End Month')
    arg.setUnits('month')
    arg.setDescription('This numeric field should contain the end month number (1 = January, 2 = February, etc.) for the annual run period desired.')
    arg.setDefaultValue(12)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_end_day_of_month', false)
    arg.setDisplayName('Simulation Control: Run Period End Day of Month')
    arg.setUnits('day')
    arg.setDescription('This numeric field should contain the ending day of the ending month (must be valid for month) for the annual run period desired.')
    arg.setDefaultValue(31)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_output_path', true)
    arg.setDisplayName('Schedules Output File Path')
    arg.setDescription('Absolute (or relative) path of the output schedules file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('weather_station_epw_filepath', true)
    arg.setDisplayName('EnergyPlus Weather (EPW) Filepath')
    arg.setDescription('Name of the EPW file.')
    arg.setDefaultValue('USA_CO_Denver.Intl.AP.725650_TMY3.epw')
    args << arg

    unit_type_choices = OpenStudio::StringVector.new
    unit_type_choices << HPXML::ResidentialTypeSFD
    unit_type_choices << HPXML::ResidentialTypeSFA
    unit_type_choices << HPXML::ResidentialTypeMF2to4
    unit_type_choices << HPXML::ResidentialTypeMF5plus

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_unit_type', unit_type_choices, true)
    arg.setDisplayName('Geometry: Unit Type')
    arg.setDescription('The type of unit.')
    arg.setDefaultValue(HPXML::ResidentialTypeSFD)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('geometry_num_units', false)
    arg.setDisplayName('Geometry: Number of Units')
    arg.setUnits('#')
    arg.setDescription("The number of units in the building. This is only required for #{HPXML::ResidentialTypeSFA}, #{HPXML::ResidentialTypeMF2to4}, and #{HPXML::ResidentialTypeMF5plus} buildings.")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_cfa', true)
    arg.setDisplayName('Geometry: Conditioned Floor Area')
    arg.setUnits('ft^2')
    arg.setDescription('The total floor area of the conditioned space (including any conditioned basement floor area).')
    arg.setDefaultValue(2000.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('geometry_num_floors_above_grade', true)
    arg.setDisplayName('Geometry: Number of Floors')
    arg.setUnits('#')
    arg.setDescription('The number of floors above grade (in the unit if single-family, and in the building if multifamily).')
    arg.setDefaultValue(2)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_wall_height', true)
    arg.setDisplayName('Geometry: Average Wall Height')
    arg.setUnits('ft')
    arg.setDescription('The average height of the walls.')
    arg.setDefaultValue(8.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_orientation', true)
    arg.setDisplayName('Geometry: Orientation')
    arg.setUnits('degrees')
    arg.setDescription("The house's orientation is measured clockwise from due south when viewed from above (e.g., North=0, East=90, South=180, West=270).")
    arg.setDefaultValue(180.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_aspect_ratio', true)
    arg.setDisplayName('Geometry: Aspect Ratio')
    arg.setUnits('FB/LR')
    arg.setDescription('The ratio of the front/back wall length to the left/right wall length, excluding any protruding garage wall area.')
    arg.setDefaultValue(2.0)
    args << arg

    level_choices = OpenStudio::StringVector.new
    level_choices << 'Bottom'
    level_choices << 'Middle'
    level_choices << 'Top'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_level', level_choices, true)
    arg.setDisplayName('Geometry: Level')
    arg.setDescription('The level of the unit.')
    arg.setDefaultValue('Bottom')
    args << arg

    horizontal_location_choices = OpenStudio::StringVector.new
    horizontal_location_choices << 'Left'
    horizontal_location_choices << 'Middle'
    horizontal_location_choices << 'Right'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_horizontal_location', horizontal_location_choices, true)
    arg.setDisplayName('Geometry: Horizontal Location')
    arg.setDescription('The horizontal location of the unit when viewing the front of the building.')
    arg.setDefaultValue('Left')
    args << arg

    corridor_position_choices = OpenStudio::StringVector.new
    corridor_position_choices << 'Double-Loaded Interior'
    corridor_position_choices << 'Single Exterior (Front)'
    corridor_position_choices << 'Double Exterior'
    corridor_position_choices << 'None'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_corridor_position', corridor_position_choices, true)
    arg.setDisplayName('Geometry: Corridor Position')
    arg.setDescription('The position of the corridor.')
    arg.setDefaultValue('Double-Loaded Interior')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_corridor_width', true)
    arg.setDisplayName('Geometry: Corridor Width')
    arg.setUnits('ft')
    arg.setDescription('The width of the corridor.')
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_inset_width', true)
    arg.setDisplayName('Geometry: Inset Width')
    arg.setUnits('ft')
    arg.setDescription('The width of the inset.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_inset_depth', true)
    arg.setDisplayName('Geometry: Inset Depth')
    arg.setUnits('ft')
    arg.setDescription('The depth of the inset.')
    arg.setDefaultValue(0.0)
    args << arg

    inset_position_choices = OpenStudio::StringVector.new
    inset_position_choices << 'Right'
    inset_position_choices << 'Left'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_inset_position', inset_position_choices, true)
    arg.setDisplayName('Geometry: Inset Position')
    arg.setDescription('The position of the inset.')
    arg.setDefaultValue('Right')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_balcony_depth', true)
    arg.setDisplayName('Geometry: Balcony Depth')
    arg.setUnits('ft')
    arg.setDescription('The depth of the balcony.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_garage_width', true)
    arg.setDisplayName('Geometry: Garage Width')
    arg.setUnits('ft')
    arg.setDescription('The width of the garage. Enter zero for no garage.')
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_garage_depth', true)
    arg.setDisplayName('Geometry: Garage Depth')
    arg.setUnits('ft')
    arg.setDescription('The depth of the garage.')
    arg.setDefaultValue(20.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_garage_protrusion', true)
    arg.setDisplayName('Geometry: Garage Protrusion')
    arg.setUnits('frac')
    arg.setDescription('The fraction of the garage that is protruding from the living space.')
    arg.setDefaultValue(0.0)
    args << arg

    garage_position_choices = OpenStudio::StringVector.new
    garage_position_choices << 'Right'
    garage_position_choices << 'Left'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_garage_position', garage_position_choices, true)
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

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_foundation_type', foundation_type_choices, true)
    arg.setDisplayName('Geometry: Foundation Type')
    arg.setDescription('The foundation type of the building.')
    arg.setDefaultValue(HPXML::FoundationTypeSlab)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_foundation_height', true)
    arg.setDisplayName('Geometry: Foundation Height')
    arg.setUnits('ft')
    arg.setDescription('The height of the foundation (e.g., 3ft for crawlspace, 8ft for basement). Only applies to basements/crawlspaces.')
    arg.setDefaultValue(3.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_foundation_height_above_grade', true)
    arg.setDisplayName('Geometry: Foundation Height Above Grade')
    arg.setUnits('ft')
    arg.setDescription('The depth above grade of the foundation wall. Only applies to basements/crawlspaces.')
    arg.setDefaultValue(1.0)
    args << arg

    roof_type_choices = OpenStudio::StringVector.new
    roof_type_choices << 'gable'
    roof_type_choices << 'hip'
    roof_type_choices << 'flat'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_roof_type', roof_type_choices, true)
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

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_roof_pitch', roof_pitch_choices, true)
    arg.setDisplayName('Geometry: Roof Pitch')
    arg.setDescription('The roof pitch of the attic. Ignored if the building has a flat roof.')
    arg.setDefaultValue('6:12')
    args << arg

    roof_structure_choices = OpenStudio::StringVector.new
    roof_structure_choices << 'truss, cantilever'
    roof_structure_choices << 'rafter'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_roof_structure', roof_structure_choices, true)
    arg.setDisplayName('Geometry: Roof Structure')
    arg.setDescription('The roof structure of the building. Ignored if the building has a flat roof.')
    arg.setDefaultValue('truss, cantilever')
    args << arg

    attic_type_choices = OpenStudio::StringVector.new
    attic_type_choices << HPXML::AtticTypeVented
    attic_type_choices << HPXML::AtticTypeUnvented
    attic_type_choices << HPXML::AtticTypeConditioned

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('geometry_attic_type', attic_type_choices, true)
    arg.setDisplayName('Geometry: Attic Type')
    arg.setDescription('The attic type of the building. Ignored if the building has a flat roof.')
    arg.setDefaultValue(HPXML::AtticTypeVented)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_eaves_depth', true)
    arg.setDisplayName('Geometry: Eaves Depth')
    arg.setUnits('ft')
    arg.setDescription('The eaves depth of the roof.')
    arg.setDefaultValue(2.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('geometry_num_bedrooms', true)
    arg.setDisplayName('Geometry: Number of Bedrooms')
    arg.setDescription('Specify the number of bedrooms. Used to determine the energy usage of appliances and plug loads, hot water usage, etc.')
    arg.setDefaultValue(3)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('geometry_num_bathrooms', true)
    arg.setDisplayName('Geometry: Number of Bathrooms')
    arg.setDescription('Specify the number of bathrooms.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('geometry_num_occupants', true)
    arg.setDisplayName('Geometry: Number of Occupants')
    arg.setDescription("Specify the number of occupants. A value of '#{Constants.Auto}' will calculate the average number of occupants from the number of bedrooms. Used to specify the internal gains from people only.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('floor_assembly_r', true)
    arg.setDisplayName('Floor: Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Assembly R-value for the floor (foundation ceiling). Ignored if a slab foundation.')
    arg.setDefaultValue(30)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('foundation_wall_insulation_r', true)
    arg.setDisplayName('Foundation: Wall Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value for the foundation wall insulation. Only applies to basements/crawlspaces.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('foundation_wall_insulation_distance_to_top', true)
    arg.setDisplayName('Foundation: Wall Insulation Distance To Top')
    arg.setUnits('ft')
    arg.setDescription('The distance from the top of the foundation wall to the top of the foundation wall insulation. Only applies to basements/crawlspaces.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('foundation_wall_insulation_distance_to_bottom', true)
    arg.setDisplayName('Foundation: Wall Insulation Distance To Bottom')
    arg.setUnits('ft')
    arg.setDescription('The distance from the top of the foundation wall to the bottom of the foundation wall insulation. Only applies to basements/crawlspaces.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('foundation_wall_assembly_r', false)
    arg.setDisplayName('Foundation: Wall Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Assembly R-value for the foundation walls. Only applies to basements/crawlspaces. If provided, overrides the previous foundation wall insulation inputs.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('slab_perimeter_insulation_r', true)
    arg.setDisplayName('Slab: Perimeter Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value of the vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('slab_perimeter_depth', true)
    arg.setDisplayName('Slab: Perimeter Insulation Depth')
    arg.setUnits('ft')
    arg.setDescription('Depth from grade to bottom of vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('slab_under_insulation_r', true)
    arg.setDisplayName('Slab: Under Slab Insulation Nominal R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value of the horizontal under slab insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('slab_under_width', true)
    arg.setDisplayName('Slab: Under Slab Insulation Width')
    arg.setUnits('ft')
    arg.setDescription('Width from slab edge inward of horizontal under-slab insulation. Enter 999 to specify that the under slab insulation spans the entire slab. Applies to slab-on-grade foundations and basement/crawlspace floors.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('slab_carpet_fraction', true)
    arg.setDisplayName('Slab: Carpet Fraction')
    arg.setUnits('Frac')
    arg.setDescription('Fraction of the slab floor area that is carpeted.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('slab_carpet_r', true)
    arg.setDisplayName('Slab: Carpet R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('R-value of the slab carpet.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ceiling_assembly_r', true)
    arg.setDisplayName('Ceiling: Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Assembly R-value for the ceiling (attic floor).')
    arg.setDefaultValue(30)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('roof_assembly_r', true)
    arg.setDisplayName('Roof: Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Assembly R-value of the roof.')
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

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('neighbor_front_height', true)
    arg.setDisplayName('Neighbor: Front Height')
    arg.setUnits('ft')
    arg.setDescription("The height of the neighboring building to the front. A value of '#{Constants.Auto}' will use the same height as this building.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('neighbor_back_height', true)
    arg.setDisplayName('Neighbor: Back Height')
    arg.setUnits('ft')
    arg.setDescription("The height of the neighboring building to the back. A value of '#{Constants.Auto}' will use the same height as this building.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('neighbor_left_height', true)
    arg.setDisplayName('Neighbor: Left Height')
    arg.setUnits('ft')
    arg.setDescription("The height of the neighboring building to the left. A value of '#{Constants.Auto}' will use the same height as this building.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('neighbor_right_height', true)
    arg.setDisplayName('Neighbor: Right Height')
    arg.setUnits('ft')
    arg.setDescription("The height of the neighboring building to the right. A value of '#{Constants.Auto}' will use the same height as this building.")
    arg.setDefaultValue(Constants.Auto)
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
    arg.setDescription('The type of exterior walls.')
    arg.setDefaultValue(HPXML::WallTypeWoodStud)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('wall_assembly_r', true)
    arg.setDisplayName('Walls: Assembly R-value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Assembly R-value of the exterior walls.')
    arg.setDefaultValue(13)
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

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_front_wwr', true)
    arg.setDisplayName('Windows: Front Window-to-Wall Ratio')
    arg.setDescription("The ratio of window area to wall area for the building's front facade. Enter 0 if specifying Front Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_back_wwr', true)
    arg.setDisplayName('Windows: Back Window-to-Wall Ratio')
    arg.setDescription("The ratio of window area to wall area for the building's back facade. Enter 0 if specifying Back Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_left_wwr', true)
    arg.setDisplayName('Windows: Left Window-to-Wall Ratio')
    arg.setDescription("The ratio of window area to wall area for the building's left facade. Enter 0 if specifying Left Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_right_wwr', true)
    arg.setDisplayName('Windows: Right Window-to-Wall Ratio')
    arg.setDescription("The ratio of window area to wall area for the building's right facade. Enter 0 if specifying Right Window Area instead.")
    arg.setDefaultValue(0.18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_area_front', true)
    arg.setDisplayName('Windows: Front Window Area')
    arg.setDescription("The amount of window area on the building's front facade. Enter 0 if specifying Front Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_area_back', true)
    arg.setDisplayName('Windows: Back Window Area')
    arg.setDescription("The amount of window area on the building's back facade. Enter 0 if specifying Back Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_area_left', true)
    arg.setDisplayName('Windows: Left Window Area')
    arg.setDescription("The amount of window area on the building's left facade. Enter 0 if specifying Left Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_area_right', true)
    arg.setDisplayName('Windows: Right Window Area')
    arg.setDescription("The amount of window area on the building's right facade. Enter 0 if specifying Right Window-to-Wall Ratio instead.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_aspect_ratio', true)
    arg.setDisplayName('Windows: Aspect Ratio')
    arg.setDescription('Ratio of window height to width.')
    arg.setDefaultValue(1.333)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_fraction_operable', true)
    arg.setDisplayName('Windows: Fraction Operable')
    arg.setDescription('Fraction of windows that are operable.')
    arg.setDefaultValue(0.67)
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

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_interior_shading_winter', true)
    arg.setDisplayName('Windows: Winter Interior Shading')
    arg.setDescription('Interior shading multiplier for the heating season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('window_interior_shading_summer', true)
    arg.setDisplayName('Windows: Summer Interior Shading')
    arg.setDescription('Interior shading multiplier for the cooling season. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.')
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

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('skylight_area_front', true)
    arg.setDisplayName('Skylights: Front Roof Area')
    arg.setDescription("The amount of skylight area on the building's front conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('skylight_area_back', true)
    arg.setDisplayName('Skylights: Back Roof Area')
    arg.setDescription("The amount of skylight area on the building's back conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('skylight_area_left', true)
    arg.setDisplayName('Skylights: Left Roof Area')
    arg.setDescription("The amount of skylight area on the building's left conditioned roof facade.")
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('skylight_area_right', true)
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
    arg.setDescription('R-value of the doors.')
    arg.setDefaultValue(5.0)
    args << arg

    air_leakage_units_choices = OpenStudio::StringVector.new
    air_leakage_units_choices << HPXML::UnitsACH50
    air_leakage_units_choices << HPXML::UnitsCFM50

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('air_leakage_units', air_leakage_units_choices, true)
    arg.setDisplayName('Air Leakage: Units')
    arg.setDescription('The unit of measure for the above-grade living air leakage.')
    arg.setDefaultValue(HPXML::UnitsACH50)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('air_leakage_value', true)
    arg.setDisplayName('Air Leakage: Value')
    arg.setDescription('Air exchange rate, in ACH or CFM at 50 Pascals.')
    arg.setDefaultValue(3)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('air_leakage_shelter_coefficient', true)
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
    heating_system_fuel_choices << HPXML::FuelTypeWoodPellets

    cooling_system_type_choices = OpenStudio::StringVector.new
    cooling_system_type_choices << 'none'
    cooling_system_type_choices << HPXML::HVACTypeCentralAirConditioner
    cooling_system_type_choices << HPXML::HVACTypeRoomAirConditioner
    cooling_system_type_choices << HPXML::HVACTypeEvaporativeCooler

    compressor_type_choices = OpenStudio::StringVector.new
    compressor_type_choices << HPXML::HVACCompressorTypeSingleStage
    compressor_type_choices << HPXML::HVACCompressorTypeTwoStage
    compressor_type_choices << HPXML::HVACCompressorTypeVariableSpeed

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('heating_system_type', heating_system_type_choices, true)
    arg.setDisplayName('Heating System: Type')
    arg.setDescription('The type of the heating system.')
    arg.setDefaultValue(HPXML::HVACTypeFurnace)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('heating_system_fuel', heating_system_fuel_choices, true)
    arg.setDisplayName('Heating System: Fuel Type')
    arg.setDescription('The fuel type of the heating system. Ignored for ElectricResistance.')
    arg.setDefaultValue(HPXML::FuelTypeNaturalGas)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_heating_efficiency_afue', true)
    arg.setDisplayName('Heating System: Rated AFUE')
    arg.setUnits('AFUE')
    arg.setDescription('The rated efficiency value of the Furnace/WallFurnace/Boiler heating system.')
    arg.setDefaultValue(0.78)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_heating_efficiency_percent', true)
    arg.setDisplayName('Heating System: Rated Percent')
    arg.setUnits('Percent')
    arg.setDescription('The rated efficiency value of the ElectricResistance/Stove/PortableHeater heating system.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heating_system_heating_capacity', true)
    arg.setDisplayName('Heating System: Heating Capacity')
    arg.setDescription("The output heating capacity of the heating system. If using '#{Constants.Auto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_fraction_heat_load_served', true)
    arg.setDisplayName('Heating System: Fraction Heat Load Served')
    arg.setDescription('The heat load served fraction of the heating system.')
    arg.setUnits('Frac')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heating_system_electric_auxiliary_energy', false)
    arg.setDisplayName('Heating System: Electric Auxiliary Energy')
    arg.setDescription('The electric auxiliary energy of the heating system.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('cooling_system_type', cooling_system_type_choices, true)
    arg.setDisplayName('Cooling System: Type')
    arg.setDescription('The type of the cooling system.')
    arg.setDefaultValue(HPXML::HVACTypeCentralAirConditioner)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_cooling_efficiency_seer', true)
    arg.setDisplayName('Cooling System: Rated SEER')
    arg.setUnits('SEER')
    arg.setDescription('The rated efficiency value of the central air conditioner cooling system. Ignored for evaporative cooler.')
    arg.setDefaultValue(13.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_cooling_efficiency_eer', true)
    arg.setDisplayName('Cooling System: Rated EER')
    arg.setUnits('EER')
    arg.setDescription('The rated efficiency value of the room air conditioner cooling system. Ignored for evaporative cooler.')
    arg.setDefaultValue(13.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('cooling_system_cooling_compressor_type', compressor_type_choices, false)
    arg.setDisplayName('Cooling System: Cooling Compressor Type')
    arg.setDescription('The compressor type of the cooling system. Only applies to central air conditioner.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_cooling_sensible_heat_fraction', false)
    arg.setDisplayName('Cooling System: Cooling Sensible Heat Fraction')
    arg.setDescription('The sensible heat fraction of the cooling system. Ignored for evaporative cooler.')
    arg.setUnits('Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('cooling_system_cooling_capacity', true)
    arg.setDisplayName('Cooling System: Cooling Capacity')
    arg.setDescription("The output cooling capacity of the cooling system. If using '#{Constants.Auto}', the autosizing algorithm will use ACCA Manual S to set the capacity. Ignored for evaporative cooler.")
    arg.setUnits('tons')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooling_system_fraction_cool_load_served', true)
    arg.setDisplayName('Cooling System: Fraction Cool Load Served')
    arg.setDescription('The cool load served fraction of the cooling system.')
    arg.setUnits('Frac')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('cooling_system_evap_cooler_is_ducted', true)
    arg.setDisplayName('Cooling System: Evaporative Cooler Is Ducted')
    arg.setDescription('Whether the evaporative cooler is ducted or not.')
    arg.setDefaultValue(false)
    args << arg

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

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('heat_pump_type', heat_pump_type_choices, true)
    arg.setDisplayName('Heat Pump: Type')
    arg.setDescription('The type of the heat pump.')
    arg.setDefaultValue('none')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_heating_efficiency_hspf', true)
    arg.setDisplayName('Heat Pump: Rated Heating HSPF')
    arg.setUnits('HSPF')
    arg.setDescription('The rated heating efficiency value of the air-to-air/mini-split heat pump.')
    arg.setDefaultValue(7.7)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_heating_efficiency_cop', true)
    arg.setDisplayName('Heat Pump: Rated Heating COP')
    arg.setUnits('COP')
    arg.setDescription('The rated heating efficiency value of the ground-to-air heat pump.')
    arg.setDefaultValue(3.6)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_cooling_efficiency_seer', true)
    arg.setDisplayName('Heat Pump: Rated Cooling SEER')
    arg.setUnits('SEER')
    arg.setDescription('The rated cooling efficiency value of the air-to-air/mini-split heat pump.')
    arg.setDefaultValue(13.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_cooling_efficiency_eer', true)
    arg.setDisplayName('Heat Pump: Rated Cooling EER')
    arg.setUnits('EER')
    arg.setDescription('The rated cooling efficiency value of the ground-to-air heat pump.')
    arg.setDefaultValue(16.6)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('heat_pump_cooling_compressor_type', compressor_type_choices, false)
    arg.setDisplayName('Heat Pump: Cooling Compressor Type')
    arg.setDescription('The compressor type of the heat pump. Only applies to air-to-air and mini-split.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_cooling_sensible_heat_fraction', false)
    arg.setDisplayName('Heat Pump: Cooling Sensible Heat Fraction')
    arg.setDescription('The sensible heat fraction of the heat pump.')
    arg.setUnits('Frac')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heat_pump_heating_capacity', true)
    arg.setDisplayName('Heat Pump: Heating Capacity')
    arg.setDescription("The output heating capacity of the heat pump. If using '#{Constants.Auto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heat_pump_heating_capacity_17F', true)
    arg.setDisplayName('Heat Pump: Heating Capacity 17F')
    arg.setDescription("The output heating capacity of the heat pump at 17F. If using '#{Constants.Auto}', the autosizing algorithm will use ACCA Manual S to set the capacity. Only applies to air-to-air and mini-split.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('heat_pump_cooling_capacity', true)
    arg.setDisplayName('Heat Pump: Cooling Capacity')
    arg.setDescription("The output cooling capacity of the heat pump. If using '#{Constants.Auto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.Auto)
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
    arg.setDescription("The backup output heating capacity of the heat pump. If using '#{Constants.Auto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('heat_pump_backup_heating_switchover_temp', false)
    arg.setDisplayName('Heat Pump: Backup Heating Switchover Temperature')
    arg.setDescription('The temperature at which the heat pump stops operating and the backup heating system starts running. Only applies to air-to-air and mini-split.')
    arg.setUnits('deg-F')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('heat_pump_mini_split_is_ducted', true)
    arg.setDisplayName('Heat Pump: Mini-Split Is Ducted')
    arg.setDescription('Whether the mini-split heat pump is ducted or not.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_heating_temp', true)
    arg.setDisplayName('Setpoint: Heating Temperature')
    arg.setDescription('Specify the heating setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_heating_setback_temp', true)
    arg.setDisplayName('Setpoint: Heating Setback Temperature')
    arg.setDescription('Specify the heating setback temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(71)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_heating_setback_hours_per_week', true)
    arg.setDisplayName('Setpoint: Heating Setback Hours per Week')
    arg.setDescription('Specify the heating setback number of hours per week value.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_heating_setback_start_hour', true)
    arg.setDisplayName('Setpoint: Heating Setback Start Hour')
    arg.setDescription('Specify the heating setback start hour value. 0 = midnight, 12 = noon')
    arg.setDefaultValue(23)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_cooling_temp', true)
    arg.setDisplayName('Setpoint: Cooling Temperature')
    arg.setDescription('Specify the cooling setpoint temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_cooling_setup_temp', true)
    arg.setDisplayName('Setpoint: Cooling Setup Temperature')
    arg.setDescription('Specify the cooling setup temperature.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(76)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_cooling_setup_hours_per_week', true)
    arg.setDisplayName('Setpoint: Cooling Setup Hours per Week')
    arg.setDescription('Specify the cooling setup number of hours per week value.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('setpoint_cooling_setup_start_hour', true)
    arg.setDisplayName('Setpoint: Cooling Setup Start Hour')
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

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('ducts_supply_leakage_units', duct_leakage_units_choices, true)
    arg.setDisplayName('Ducts: Supply Leakage Units')
    arg.setDescription('The leakage units of the supply ducts.')
    arg.setDefaultValue(HPXML::UnitsCFM25)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('ducts_return_leakage_units', duct_leakage_units_choices, true)
    arg.setDisplayName('Ducts: Return Leakage Units')
    arg.setDescription('The leakage units of the return ducts.')
    arg.setDefaultValue(HPXML::UnitsCFM25)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ducts_supply_leakage_value', true)
    arg.setDisplayName('Ducts: Supply Leakage Value')
    arg.setDescription('The leakage value to outside of the supply ducts.')
    arg.setDefaultValue(75)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ducts_return_leakage_value', true)
    arg.setDisplayName('Ducts: Return Leakage Value')
    arg.setDescription('The leakage value to outside of the return ducts.')
    arg.setDefaultValue(25)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ducts_supply_insulation_r', true)
    arg.setDisplayName('Ducts: Supply Insulation R-Value')
    arg.setDescription('The insulation r-value of the supply ducts.')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ducts_return_insulation_r', true)
    arg.setDisplayName('Ducts: Return Insulation R-Value')
    arg.setDescription('The insulation r-value of the return ducts.')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('ducts_supply_location', duct_location_choices, true)
    arg.setDisplayName('Ducts: Supply Location')
    arg.setDescription('The location of the supply ducts.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('ducts_return_location', duct_location_choices, true)
    arg.setDisplayName('Ducts: Return Location')
    arg.setDescription('The location of the return ducts.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ducts_supply_surface_area', true)
    arg.setDisplayName('Ducts: Supply Surface Area')
    arg.setDescription('The surface area of the supply ducts.')
    arg.setUnits('ft^2')
    arg.setDefaultValue(150)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ducts_return_surface_area', true)
    arg.setDisplayName('Ducts: Return Surface Area')
    arg.setDescription('The surface area of the return ducts.')
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

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('kitchen_fan_present', true)
    arg.setDisplayName('Whole House Fan: Present')
    arg.setDescription('Whether there is a kitchen fan.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('kitchen_fan_flow_rate', false)
    arg.setDisplayName('Kitchen Fan: Flow Rate')
    arg.setDescription('The flow rate of the kitchen fan.')
    arg.setUnits('CFM')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('kitchen_fan_hours_in_operation', false)
    arg.setDisplayName('Kitchen Fan: Hours In Operation')
    arg.setDescription('The hours in operation of the kitchen fan.')
    arg.setUnits('hrs')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('kitchen_fan_power', false)
    arg.setDisplayName('Kitchen Fan: Fan Power')
    arg.setDescription('The fan power of the kitchen fan.')
    arg.setUnits('W')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('kitchen_fan_start_hour', true)
    arg.setDisplayName('Kitchen Fan: Start Hour')
    arg.setDescription('The start hour of the kitchen fan.')
    arg.setUnits('hr')
    arg.setDefaultValue(18)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('bathroom_fans_present', true)
    arg.setDisplayName('Bathroom Fans: Present')
    arg.setDescription('Whether there are bathroom fans.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('bathroom_fans_flow_rate', false)
    arg.setDisplayName('Bathroom Fans: Flow Rate')
    arg.setDescription('The flow rate of the bathroom fans.')
    arg.setUnits('CFM')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('bathroom_fans_hours_in_operation', false)
    arg.setDisplayName('Bathroom Fans: Hours In Operation')
    arg.setDescription('The hours in operation of the bathroom fans.')
    arg.setUnits('hrs')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('bathroom_fans_power', false)
    arg.setDisplayName('Bathroom Fans: Fan Power')
    arg.setDescription('The fan power of the bathroom fans.')
    arg.setUnits('W')
    arg.setDefaultValue(300)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('bathroom_fans_start_hour', true)
    arg.setDisplayName('Bathroom Fans: Start Hour')
    arg.setDescription('The start hour of the bathroom fans.')
    arg.setUnits('hr')
    arg.setDefaultValue(7)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('bathroom_fans_quantity', false)
    arg.setDisplayName('Bathroom Fans: Quantity')
    arg.setDescription('The quantity of the bathroom fans.')
    arg.setUnits('#')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('whole_house_fan_present', true)
    arg.setDisplayName('Whole House Fan: Present')
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

    water_heater_location_choices = OpenStudio::StringVector.new
    water_heater_location_choices << Constants.Auto
    water_heater_location_choices << HPXML::LocationLivingSpace
    water_heater_location_choices << HPXML::LocationBasementConditioned
    water_heater_location_choices << HPXML::LocationBasementUnconditioned
    water_heater_location_choices << HPXML::LocationGarage
    water_heater_location_choices << HPXML::LocationAtticVented
    water_heater_location_choices << HPXML::LocationAtticUnvented
    water_heater_location_choices << HPXML::LocationCrawlspaceVented
    water_heater_location_choices << HPXML::LocationCrawlspaceUnvented
    water_heater_location_choices << HPXML::LocationOtherExterior

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
    arg.setDescription("The fuel type of water heater. Ignored for #{HPXML::WaterHeaterTypeHeatPump}.")
    arg.setDefaultValue(HPXML::FuelTypeNaturalGas)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('water_heater_location', water_heater_location_choices, true)
    arg.setDisplayName('Water Heater: Location')
    arg.setDescription('The location of water heater.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('water_heater_tank_volume', true)
    arg.setDisplayName('Water Heater: Tank Volume')
    arg.setDescription("Nominal volume of water heater tank. Set to #{Constants.Auto} to have volume autosized. Only applies to #{HPXML::WaterHeaterTypeStorage}, #{HPXML::WaterHeaterTypeHeatPump}, and #{HPXML::WaterHeaterTypeCombiStorage}.")
    arg.setUnits('gal')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('water_heater_heating_capacity', true)
    arg.setDisplayName('Water Heater: Input Capacity')
    arg.setDescription("The maximum energy input rating of water heater. Set to #{Constants.Auto} to have this field autosized. Only applies to #{HPXML::WaterHeaterTypeStorage}.")
    arg.setUnits('Btu/hr')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('water_heater_efficiency_type', water_heater_efficiency_type_choices, true)
    arg.setDisplayName('Water Heater: Efficiency Type')
    arg.setDescription('The efficiency type of water heater. Does not apply to space-heating boilers.')
    arg.setDefaultValue('EnergyFactor')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('water_heater_efficiency_ef', true)
    arg.setDisplayName('Water Heater: Energy Factor')
    arg.setDescription('Ratio of useful energy output from water heater to the total amount of energy delivered from the water heater.')
    arg.setDefaultValue(0.67)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('water_heater_efficiency_uef', true)
    arg.setDisplayName('Water Heater: Uniform Energy Factor')
    arg.setDescription('The uniform energy factor of water heater. Does not apply to space-heating boilers.')
    arg.setDefaultValue(0.67)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('water_heater_recovery_efficiency', true)
    arg.setDisplayName('Water Heater: Recovery Efficiency')
    arg.setDescription('Ratio of energy delivered to water heater to the energy content of the fuel consumed by the water heater. Only used for non-electric storage water heaters.')
    arg.setUnits('Frac')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('water_heater_standby_loss', false)
    arg.setDisplayName('Water Heater: Standby Loss')
    arg.setDescription('The standby loss of water heater. Only applies to space-heating boilers.')
    arg.setUnits('deg-F/hr')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('water_heater_jacket_rvalue', false)
    arg.setDisplayName('Water Heater: Jacket R-value')
    arg.setDescription("The jacket R-value of water heater. Doesn't apply to #{HPXML::WaterHeaterTypeTankless} or #{HPXML::WaterHeaterTypeCombiTankless}.")
    arg.setUnits('h-ft^2-R/Btu')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('water_heater_setpoint_temperature', true)
    arg.setDisplayName('Water Heater: Setpoint Temperature')
    arg.setDescription('The setpoint temperature of water heater.')
    arg.setUnits('deg-F')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    dhw_distribution_system_type_choices = OpenStudio::StringVector.new
    dhw_distribution_system_type_choices << HPXML::DHWDistTypeStandard
    dhw_distribution_system_type_choices << HPXML::DHWDistTypeRecirc

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('dhw_distribution_system_type', dhw_distribution_system_type_choices, true)
    arg.setDisplayName('Hot Water Distribution: System Type')
    arg.setDescription('The type of the hot water distribution system.')
    arg.setDefaultValue(HPXML::DHWDistTypeStandard)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('dhw_distribution_standard_piping_length', true)
    arg.setDisplayName('Hot Water Distribution: Standard Piping Length')
    arg.setUnits('ft')
    arg.setDescription("If the distribution system is #{HPXML::DHWDistTypeStandard}, the length of the piping. A value of '#{Constants.Auto}' will use a default.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    recirculation_control_type_choices = OpenStudio::StringVector.new
    recirculation_control_type_choices << HPXML::DHWRecirControlTypeNone
    recirculation_control_type_choices << HPXML::DHWRecirControlTypeTimer
    recirculation_control_type_choices << HPXML::DHWRecirControlTypeTemperature
    recirculation_control_type_choices << HPXML::DHWRecirControlTypeSensor
    recirculation_control_type_choices << HPXML::DHWRecirControlTypeManual

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('dhw_distribution_recirc_control_type', recirculation_control_type_choices, true)
    arg.setDisplayName('Hot Water Distribution: Recirculation Control Type')
    arg.setDescription("If the distribution system is #{HPXML::DHWDistTypeRecirc}, the type of hot water recirculation control, if any.")
    arg.setDefaultValue(HPXML::DHWRecirControlTypeNone)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('dhw_distribution_recirc_piping_length', true)
    arg.setDisplayName('Hot Water Distribution: Recirculation Piping Length')
    arg.setUnits('ft')
    arg.setDescription("If the distribution system is #{HPXML::DHWDistTypeRecirc}, the length of the recirculation piping.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('dhw_distribution_recirc_branch_piping_length', true)
    arg.setDisplayName('Hot Water Distribution: Recirculation Branch Piping Length')
    arg.setUnits('ft')
    arg.setDescription("If the distribution system is #{HPXML::DHWDistTypeRecirc}, the length of the recirculation branch piping.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('dhw_distribution_recirc_pump_power', true)
    arg.setDisplayName('Hot Water Distribution: Recirculation Pump Power')
    arg.setUnits('W')
    arg.setDescription("If the distribution system is #{HPXML::DHWDistTypeRecirc}, the recirculation pump power.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dhw_distribution_pipe_r', true)
    arg.setDisplayName('Hot Water Distribution: Pipe Insulation Nominal R-Value')
    arg.setUnits('h-ft^2-R/Btu')
    arg.setDescription('Nominal R-value of the pipe insulation.')
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

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('water_fixtures_shower_low_flow', true)
    arg.setDisplayName('Hot Water Fixtures: Is Shower Low Flow')
    arg.setDescription('Whether the shower fixture is low flow.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('water_fixtures_sink_low_flow', true)
    arg.setDisplayName('Hot Water Fixtures: Is Sink Low Flow')
    arg.setDescription('Whether the sink fixture is low flow.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('water_fixtures_usage_multiplier', true)
    arg.setDisplayName('Hot Water Fixtures: Usage Multiplier')
    arg.setDescription('Multiplier on the hot water usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
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

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('solar_thermal_collector_tilt', true)
    arg.setDisplayName('Solar Thermal: Collector Tilt')
    arg.setUnits('degrees')
    arg.setDescription('The collector tilt of the solar thermal system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.')
    arg.setDefaultValue('RoofPitch')
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
    arg.setDescription('The solar fraction of the solar thermal system. If provided, overrides all other solar thermal inputs.')
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

      arg = OpenStudio::Measure::OSArgument::makeStringArgument("pv_system_array_tilt_#{n}", true)
      arg.setDisplayName("Photovoltaics #{n}: Array Tilt")
      arg.setUnits('degrees')
      arg.setDescription("Array tilt of the PV system #{n}. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.")
      arg.setDefaultValue('RoofPitch')
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

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('lighting_usage_multiplier', true)
    arg.setDisplayName('Lighting: Usage Multiplier')
    arg.setDescription('Multiplier on the energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('dehumidifier_present', true)
    arg.setDisplayName('Dehumidifier: Present')
    arg.setDescription('Whether there is a dehumidifier.')
    arg.setDefaultValue(false)
    args << arg

    dehumidifier_efficiency_type_choices = OpenStudio::StringVector.new
    dehumidifier_efficiency_type_choices << 'EnergyFactor'
    dehumidifier_efficiency_type_choices << 'IntegratedEnergyFactor'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('dehumidifier_efficiency_type', dehumidifier_efficiency_type_choices, true)
    arg.setDisplayName('Dehumidifier: Efficiency Type')
    arg.setDescription('The efficiency type of dehumidifier.')
    arg.setDefaultValue('EnergyFactor')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dehumidifier_efficiency_ef', true)
    arg.setDisplayName('Dehumidifier: Energy Factor')
    arg.setUnits('liters/kWh')
    arg.setDescription('The Energy Factor (EF) of the dehumidifier.')
    arg.setDefaultValue(1.8)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dehumidifier_efficiency_ief', true)
    arg.setDisplayName('Dehumidifier: Integrated Energy Factor')
    arg.setUnits('liters/kWh')
    arg.setDescription('The Integrated Energy Factor (IEF) of the dehumidifier.')
    arg.setDefaultValue(1.5)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dehumidifier_capacity', true)
    arg.setDisplayName('Dehumidifier: Capacity')
    arg.setDescription('The capacity (water removal rate) of the dehumidifier.')
    arg.setUnits('pint/day')
    arg.setDefaultValue(40)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dehumidifier_rh_setpoint', true)
    arg.setDisplayName('Dehumidifier: Relative Humidity Setpoint')
    arg.setDescription('The relative humidity setpoint of the dehumidifier.')
    arg.setUnits('Frac')
    arg.setDefaultValue(0.5)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dehumidifier_fraction_dehumidification_load_served', true)
    arg.setDisplayName('Dehumidifier: Fraction Dehumidification Load Served')
    arg.setDescription('The dehumidification load served fraction of the dehumidifier.')
    arg.setUnits('Frac')
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('clothes_washer_present', true)
    arg.setDisplayName('Clothes Washer: Present')
    arg.setDescription('Whether there is a clothes washer.')
    arg.setDefaultValue(true)
    args << arg

    appliance_location_choices = OpenStudio::StringVector.new
    appliance_location_choices << Constants.Auto
    appliance_location_choices << HPXML::LocationLivingSpace
    appliance_location_choices << HPXML::LocationBasementConditioned
    appliance_location_choices << HPXML::LocationBasementUnconditioned
    appliance_location_choices << HPXML::LocationGarage

    clothes_washer_efficiency_type_choices = OpenStudio::StringVector.new
    clothes_washer_efficiency_type_choices << 'ModifiedEnergyFactor'
    clothes_washer_efficiency_type_choices << 'IntegratedModifiedEnergyFactor'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('clothes_washer_location', appliance_location_choices, true)
    arg.setDisplayName('Clothes Washer: Location')
    arg.setDescription('The space type for the clothes washer location.')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('clothes_washer_efficiency_type', clothes_washer_efficiency_type_choices, true)
    arg.setDisplayName('Clothes Washer: Efficiency Type')
    arg.setDescription('The efficiency type of clothes washer.')
    arg.setDefaultValue('IntegratedModifiedEnergyFactor')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_efficiency_mef', true)
    arg.setDisplayName('Clothes Washer: Modified Energy Factor')
    arg.setUnits('ft^3/kWh-cycle')
    arg.setDescription('The Modified Energy Factor (MEF) is the capacity of the clothes container divided by the total clothes washer energy consumption per cycle, where the energy consumption is the sum of the machine electrical energy consumption, the hot water energy consumption, the energy required for removal of the remaining moisture in the wash load, standby energy, and off-mode energy consumption.')
    arg.setDefaultValue(1.453)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_efficiency_imef', true)
    arg.setDisplayName('Clothes Washer: Integrated Modified Energy Factor')
    arg.setDescription('The energy performance metric for ENERGY STAR certified residential clothes washers as of March 7, 2015.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_rated_annual_kwh', true)
    arg.setDisplayName('Clothes Washer: Rated Annual Consumption')
    arg.setUnits('kWh')
    arg.setDescription('The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.')
    arg.setDefaultValue(400.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_label_electric_rate', true)
    arg.setDisplayName('Clothes Washer: Label Electric Rate')
    arg.setUnits('$/kWh')
    arg.setDescription('The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.')
    arg.setDefaultValue(0.12)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_label_gas_rate', true)
    arg.setDisplayName('Clothes Washer: Label Gas Rate')
    arg.setUnits('$/therm')
    arg.setDescription('The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.')
    arg.setDefaultValue(1.09)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_label_annual_gas_cost', true)
    arg.setDisplayName('Clothes Washer: Label Annual Cost with Gas DHW')
    arg.setUnits('$')
    arg.setDescription('The annual cost of using the system under test conditions. Input is obtained from the EnergyGuide label.')
    arg.setDefaultValue(27.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_label_usage', true)
    arg.setDisplayName('Clothes Washer: Label Usage')
    arg.setUnits('cyc/wk')
    arg.setDescription('The clothes washer loads per week.')
    arg.setDefaultValue(6.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_capacity', true)
    arg.setDisplayName('Clothes Washer: Drum Volume')
    arg.setUnits('ft^3')
    arg.setDescription("Volume of the washer drum. Obtained from the EnergyStar website or the manufacturer's literature.")
    arg.setDefaultValue(3.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_washer_usage_multiplier', true)
    arg.setDisplayName('Clothes Washer: Usage Multiplier')
    arg.setDescription('Multiplier on the energy and hot water usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('clothes_dryer_present', true)
    arg.setDisplayName('Clothes Dryer: Present')
    arg.setDescription('Whether there is a clothes dryer.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('clothes_dryer_location', appliance_location_choices, true)
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
    arg.setDefaultValue('CombinedEnergyFactor')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_dryer_efficiency_ef', true)
    arg.setDisplayName('Clothes Dryer: Energy Factor')
    arg.setUnits('lb/kWh')
    arg.setDescription('The energy performance metric for ENERGY STAR certified residential clothes dryers prior to September 13, 2013. The new metric is Combined Energy Factor.')
    arg.setDefaultValue(3.4615)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_dryer_efficiency_cef', true)
    arg.setDisplayName('Clothes Dryer: Combined Energy Factor')
    arg.setUnits('lb/kWh')
    arg.setDescription('The Combined Energy Factor (CEF) measures the pounds of clothing that can be dried per kWh (Fuel equivalent) of electricity, including energy consumed during Stand-by and Off modes.')
    arg.setDefaultValue(3.01)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('clothes_dryer_control_type', clothes_dryer_control_type_choices, true)
    arg.setDisplayName('Clothes Dryer: Control Type')
    arg.setDescription('Type of control used by the clothes dryer.')
    arg.setDefaultValue(HPXML::ClothesDryerControlTypeTimer)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('clothes_dryer_usage_multiplier', true)
    arg.setDisplayName('Clothes Dryer: Usage Multiplier')
    arg.setDescription('Multiplier on the energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('dishwasher_present', true)
    arg.setDisplayName('Dishwasher: Present')
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

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dishwasher_efficiency_kwh', true)
    arg.setDisplayName('Dishwasher: Rated Annual kWh')
    arg.setDescription('The rated annual kWh of the dishwasher.')
    arg.setDefaultValue(467)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dishwasher_efficiency_ef', true)
    arg.setDisplayName('Dishwasher: Energy Factor')
    arg.setDescription('The energy factor of the dishwasher.')
    arg.setDefaultValue(0.46)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dishwasher_label_electric_rate', true)
    arg.setDisplayName('Dishwasher: Label Electric Rate')
    arg.setUnits('$/kWh')
    arg.setDescription('The label electric rate of the dishwasher.')
    arg.setDefaultValue(0.12)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dishwasher_label_gas_rate', true)
    arg.setDisplayName('Dishwasher: Label Gas Rate')
    arg.setUnits('$/therm')
    arg.setDescription('The label gas rate of the dishwasher.')
    arg.setDefaultValue(1.09)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dishwasher_label_annual_gas_cost', true)
    arg.setDisplayName('Dishwasher: Label Annual Gas Cost')
    arg.setUnits('$')
    arg.setDescription('The label annual gas cost of the dishwasher.')
    arg.setDefaultValue(33.12)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dishwasher_label_usage', true)
    arg.setDisplayName('Dishwasher: Label Usage')
    arg.setUnits('cyc/wk')
    arg.setDescription('The dishwasher loads per week.')
    arg.setDefaultValue(4.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('dishwasher_place_setting_capacity', true)
    arg.setDisplayName('Dishwasher: Number of Place Settings')
    arg.setUnits('#')
    arg.setDescription("The number of place settings for the unit. Data obtained from manufacturer's literature.")
    arg.setDefaultValue(12)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('dishwasher_usage_multiplier', true)
    arg.setDisplayName('Dishwasher: Usage Multiplier')
    arg.setDescription('Multiplier on the energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('refrigerator_present', true)
    arg.setDisplayName('Refrigerator: Present')
    arg.setDescription('Whether there is a refrigerator.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('refrigerator_location', appliance_location_choices, true)
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

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('refrigerator_usage_multiplier', true)
    arg.setDisplayName('Refrigerator: Usage Multiplier')
    arg.setDescription('Multiplier on the energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
    args << arg

    cooking_range_oven_fuel_choices = OpenStudio::StringVector.new
    cooking_range_oven_fuel_choices << HPXML::FuelTypeElectricity
    cooking_range_oven_fuel_choices << HPXML::FuelTypeNaturalGas
    cooking_range_oven_fuel_choices << HPXML::FuelTypeOil
    cooking_range_oven_fuel_choices << HPXML::FuelTypePropane
    cooking_range_oven_fuel_choices << HPXML::FuelTypeWood

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('cooking_range_oven_present', true)
    arg.setDisplayName('Cooking Range/Oven: Present')
    arg.setDescription('Whether there is a cooking range/oven.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('cooking_range_oven_fuel_type', cooking_range_oven_fuel_choices, true)
    arg.setDisplayName('Cooking Range/Oven: Fuel Type')
    arg.setDescription('Type of fuel used by the cooking range/oven.')
    arg.setDefaultValue(HPXML::FuelTypeNaturalGas)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('cooking_range_oven_is_induction', true)
    arg.setDisplayName('Cooking Range/Oven: Is Induction')
    arg.setDescription('Whether the cooking range is induction.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeBoolArgument('cooking_range_oven_is_convection', true)
    arg.setDisplayName('Cooking Range/Oven: Is Convection')
    arg.setDescription('Whether the oven is convection.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('cooking_range_oven_usage_multiplier', true)
    arg.setDisplayName('Cooking Range/Oven: Usage Multiplier')
    arg.setDescription('Multiplier on the energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
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
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('ceiling_fan_cooling_setpoint_temp_offset', true)
    arg.setDisplayName('Ceiling Fan: Cooling Setpoint Temperature Offset')
    arg.setUnits('deg-F')
    arg.setDescription('The setpoint temperature offset during cooling season for the ceiling fan(s). Only applies if ceiling fan quantity is greater than zero.')
    arg.setDefaultValue(0.5)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('plug_loads_television_annual_kwh', true)
    arg.setDisplayName('Plug Loads: Television Annual kWh')
    arg.setDescription('The annual energy consumption of the television plug loads.')
    arg.setUnits('kWh/yr')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('plug_loads_other_annual_kwh', true)
    arg.setDisplayName('Plug Loads: Other Annual kWh')
    arg.setDescription('The annual energy consumption of the other residual plug loads.')
    arg.setUnits('kWh/yr')
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('plug_loads_other_frac_sensible', true)
    arg.setDisplayName('Plug Loads: Other Sensible Fraction')
    arg.setDescription("Fraction of other residual plug loads' internal gains that are sensible.")
    arg.setUnits('Frac')
    arg.setDefaultValue(0.855)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('plug_loads_other_frac_latent', true)
    arg.setDisplayName('Plug Loads: Other Latent Fraction')
    arg.setDescription("Fraction of other residual plug loads' internal gains that are latent.")
    arg.setUnits('Frac')
    arg.setDefaultValue(0.045)
    args << arg

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

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('plug_loads_usage_multiplier', true)
    arg.setDisplayName('Plug Loads: Usage Multiplier')
    arg.setDescription('Multiplier on the energy usage that can reflect, e.g., high/low usage occupants.')
    arg.setDefaultValue(1.0)
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
    args = { hpxml_path: runner.getStringArgumentValue('hpxml_path', user_arguments),
             weather_dir: runner.getStringArgumentValue('weather_dir', user_arguments),
             timestep: runner.getIntegerArgumentValue('simulation_control_timestep', user_arguments),
             begin_month: runner.getIntegerArgumentValue('simulation_control_begin_month', user_arguments),
             begin_day_of_month: runner.getIntegerArgumentValue('simulation_control_begin_day_of_month', user_arguments),
             end_month: runner.getIntegerArgumentValue('simulation_control_end_month', user_arguments),
             end_day_of_month: runner.getIntegerArgumentValue('simulation_control_end_day_of_month', user_arguments),
             schedules_output_path: runner.getStringArgumentValue('schedules_output_path', user_arguments),
             weather_station_epw_filepath: runner.getStringArgumentValue('weather_station_epw_filepath', user_arguments),
             geometry_unit_type: runner.getStringArgumentValue('geometry_unit_type', user_arguments),
             geometry_num_units: runner.getOptionalIntegerArgumentValue('geometry_num_units', user_arguments),
             geometry_cfa: runner.getDoubleArgumentValue('geometry_cfa', user_arguments),
             geometry_num_floors_above_grade: runner.getIntegerArgumentValue('geometry_num_floors_above_grade', user_arguments),
             geometry_wall_height: runner.getDoubleArgumentValue('geometry_wall_height', user_arguments),
             geometry_orientation: runner.getDoubleArgumentValue('geometry_orientation', user_arguments),
             geometry_aspect_ratio: runner.getDoubleArgumentValue('geometry_aspect_ratio', user_arguments),
             geometry_level: runner.getStringArgumentValue('geometry_level', user_arguments),
             geometry_horizontal_location: runner.getStringArgumentValue('geometry_horizontal_location', user_arguments),
             geometry_corridor_position: runner.getStringArgumentValue('geometry_corridor_position', user_arguments),
             geometry_corridor_width: runner.getDoubleArgumentValue('geometry_corridor_width', user_arguments),
             geometry_inset_width: runner.getDoubleArgumentValue('geometry_inset_width', user_arguments),
             geometry_inset_depth: runner.getDoubleArgumentValue('geometry_inset_depth', user_arguments),
             geometry_inset_position: runner.getStringArgumentValue('geometry_inset_position', user_arguments),
             geometry_balcony_depth: runner.getDoubleArgumentValue('geometry_balcony_depth', user_arguments),
             geometry_garage_width: runner.getDoubleArgumentValue('geometry_garage_width', user_arguments),
             geometry_garage_depth: runner.getDoubleArgumentValue('geometry_garage_depth', user_arguments),
             geometry_garage_protrusion: runner.getDoubleArgumentValue('geometry_garage_protrusion', user_arguments),
             geometry_garage_position: runner.getStringArgumentValue('geometry_garage_position', user_arguments),
             geometry_foundation_type: runner.getStringArgumentValue('geometry_foundation_type', user_arguments),
             geometry_foundation_height: runner.getDoubleArgumentValue('geometry_foundation_height', user_arguments),
             geometry_foundation_height_above_grade: runner.getDoubleArgumentValue('geometry_foundation_height_above_grade', user_arguments),
             geometry_roof_type: runner.getStringArgumentValue('geometry_roof_type', user_arguments),
             geometry_roof_pitch: { '1:12' => 1.0 / 12.0, '2:12' => 2.0 / 12.0, '3:12' => 3.0 / 12.0, '4:12' => 4.0 / 12.0, '5:12' => 5.0 / 12.0, '6:12' => 6.0 / 12.0, '7:12' => 7.0 / 12.0, '8:12' => 8.0 / 12.0, '9:12' => 9.0 / 12.0, '10:12' => 10.0 / 12.0, '11:12' => 11.0 / 12.0, '12:12' => 12.0 / 12.0 }[runner.getStringArgumentValue('geometry_roof_pitch', user_arguments)],
             geometry_roof_structure: runner.getStringArgumentValue('geometry_roof_structure', user_arguments),
             geometry_attic_type: runner.getStringArgumentValue('geometry_attic_type', user_arguments),
             geometry_eaves_depth: runner.getDoubleArgumentValue('geometry_eaves_depth', user_arguments),
             geometry_num_bedrooms: runner.getDoubleArgumentValue('geometry_num_bedrooms', user_arguments),
             geometry_num_bathrooms: runner.getStringArgumentValue('geometry_num_bathrooms', user_arguments),
             geometry_num_occupants: runner.getStringArgumentValue('geometry_num_occupants', user_arguments),
             floor_assembly_r: runner.getDoubleArgumentValue('floor_assembly_r', user_arguments),
             foundation_wall_insulation_r: runner.getDoubleArgumentValue('foundation_wall_insulation_r', user_arguments),
             foundation_wall_insulation_distance_to_top: runner.getDoubleArgumentValue('foundation_wall_insulation_distance_to_top', user_arguments),
             foundation_wall_insulation_distance_to_bottom: runner.getDoubleArgumentValue('foundation_wall_insulation_distance_to_bottom', user_arguments),
             foundation_wall_assembly_r: runner.getOptionalDoubleArgumentValue('foundation_wall_assembly_r', user_arguments),
             perimeter_insulation_r_value: runner.getDoubleArgumentValue('slab_perimeter_insulation_r', user_arguments),
             perimeter_insulation_depth: runner.getDoubleArgumentValue('slab_perimeter_depth', user_arguments),
             under_slab_insulation_r_value: runner.getDoubleArgumentValue('slab_under_insulation_r', user_arguments),
             under_slab_insulation_width: runner.getDoubleArgumentValue('slab_under_width', user_arguments),
             slab_carpet_fraction: runner.getDoubleArgumentValue('slab_carpet_fraction', user_arguments),
             slab_carpet_r_value: runner.getDoubleArgumentValue('slab_carpet_r', user_arguments),
             ceiling_assembly_r: runner.getDoubleArgumentValue('ceiling_assembly_r', user_arguments),
             roof_assembly_r: runner.getDoubleArgumentValue('roof_assembly_r', user_arguments),
             roof_solar_absorptance: runner.getDoubleArgumentValue('roof_solar_absorptance', user_arguments),
             roof_emittance: runner.getDoubleArgumentValue('roof_emittance', user_arguments),
             roof_radiant_barrier: runner.getBoolArgumentValue('roof_radiant_barrier', user_arguments),
             neighbor_distance: [runner.getDoubleArgumentValue('neighbor_front_distance', user_arguments), runner.getDoubleArgumentValue('neighbor_back_distance', user_arguments), runner.getDoubleArgumentValue('neighbor_left_distance', user_arguments), runner.getDoubleArgumentValue('neighbor_right_distance', user_arguments)],
             neighbor_height: [runner.getStringArgumentValue('neighbor_front_height', user_arguments), runner.getStringArgumentValue('neighbor_back_height', user_arguments), runner.getStringArgumentValue('neighbor_left_height', user_arguments), runner.getStringArgumentValue('neighbor_right_height', user_arguments)],
             wall_type: runner.getStringArgumentValue('wall_type', user_arguments),
             wall_assembly_r: runner.getDoubleArgumentValue('wall_assembly_r', user_arguments),
             wall_solar_absorptance: runner.getDoubleArgumentValue('wall_solar_absorptance', user_arguments),
             wall_emittance: runner.getDoubleArgumentValue('wall_emittance', user_arguments),
             window_front_wwr: runner.getDoubleArgumentValue('window_front_wwr', user_arguments),
             window_back_wwr: runner.getDoubleArgumentValue('window_back_wwr', user_arguments),
             window_left_wwr: runner.getDoubleArgumentValue('window_left_wwr', user_arguments),
             window_right_wwr: runner.getDoubleArgumentValue('window_right_wwr', user_arguments),
             window_area_front: runner.getDoubleArgumentValue('window_area_front', user_arguments),
             window_area_back: runner.getDoubleArgumentValue('window_area_back', user_arguments),
             window_area_left: runner.getDoubleArgumentValue('window_area_left', user_arguments),
             window_area_right: runner.getDoubleArgumentValue('window_area_right', user_arguments),
             window_aspect_ratio: runner.getDoubleArgumentValue('window_aspect_ratio', user_arguments),
             window_fraction_operable: runner.getDoubleArgumentValue('window_fraction_operable', user_arguments),
             window_ufactor: runner.getDoubleArgumentValue('window_ufactor', user_arguments),
             window_shgc: runner.getDoubleArgumentValue('window_shgc', user_arguments),
             window_interior_shading_winter: runner.getDoubleArgumentValue('window_interior_shading_winter', user_arguments),
             window_interior_shading_summer: runner.getDoubleArgumentValue('window_interior_shading_summer', user_arguments),
             overhangs_front_depth: runner.getDoubleArgumentValue('overhangs_front_depth', user_arguments),
             overhangs_front_distance_to_top_of_window: runner.getDoubleArgumentValue('overhangs_front_distance_to_top_of_window', user_arguments),
             overhangs_back_depth: runner.getDoubleArgumentValue('overhangs_back_depth', user_arguments),
             overhangs_back_distance_to_top_of_window: runner.getDoubleArgumentValue('overhangs_back_distance_to_top_of_window', user_arguments),
             overhangs_left_depth: runner.getDoubleArgumentValue('overhangs_left_depth', user_arguments),
             overhangs_left_distance_to_top_of_window: runner.getDoubleArgumentValue('overhangs_left_distance_to_top_of_window', user_arguments),
             overhangs_right_depth: runner.getDoubleArgumentValue('overhangs_right_depth', user_arguments),
             overhangs_right_distance_to_top_of_window: runner.getDoubleArgumentValue('overhangs_right_distance_to_top_of_window', user_arguments),
             skylight_area_front: runner.getDoubleArgumentValue('skylight_area_front', user_arguments),
             skylight_area_back: runner.getDoubleArgumentValue('skylight_area_back', user_arguments),
             skylight_area_left: runner.getDoubleArgumentValue('skylight_area_left', user_arguments),
             skylight_area_right: runner.getDoubleArgumentValue('skylight_area_right', user_arguments),
             skylight_ufactor: runner.getDoubleArgumentValue('skylight_ufactor', user_arguments),
             skylight_shgc: runner.getDoubleArgumentValue('skylight_shgc', user_arguments),
             door_area: runner.getDoubleArgumentValue('door_area', user_arguments),
             door_rvalue: runner.getDoubleArgumentValue('door_rvalue', user_arguments),
             air_leakage_units: runner.getStringArgumentValue('air_leakage_units', user_arguments),
             air_leakage_value: runner.getDoubleArgumentValue('air_leakage_value', user_arguments),
             air_leakage_shelter_coefficient: runner.getStringArgumentValue('air_leakage_shelter_coefficient', user_arguments),
             heating_system_type: runner.getStringArgumentValue('heating_system_type', user_arguments),
             heating_system_fuel: runner.getStringArgumentValue('heating_system_fuel', user_arguments),
             heating_system_heating_efficiency_afue: runner.getDoubleArgumentValue('heating_system_heating_efficiency_afue', user_arguments),
             heating_system_heating_efficiency_percent: runner.getDoubleArgumentValue('heating_system_heating_efficiency_percent', user_arguments),
             heating_system_heating_capacity: runner.getStringArgumentValue('heating_system_heating_capacity', user_arguments),
             heating_system_fraction_heat_load_served: runner.getDoubleArgumentValue('heating_system_fraction_heat_load_served', user_arguments),
             heating_system_electric_auxiliary_energy: runner.getOptionalDoubleArgumentValue('heating_system_electric_auxiliary_energy', user_arguments),
             cooling_system_type: runner.getStringArgumentValue('cooling_system_type', user_arguments),
             cooling_system_cooling_efficiency_seer: runner.getDoubleArgumentValue('cooling_system_cooling_efficiency_seer', user_arguments),
             cooling_system_cooling_efficiency_eer: runner.getDoubleArgumentValue('cooling_system_cooling_efficiency_eer', user_arguments),
             cooling_system_cooling_compressor_type: runner.getOptionalStringArgumentValue('cooling_system_cooling_compressor_type', user_arguments),
             cooling_system_cooling_sensible_heat_fraction: runner.getOptionalDoubleArgumentValue('cooling_system_cooling_sensible_heat_fraction', user_arguments),
             cooling_system_cooling_capacity: runner.getStringArgumentValue('cooling_system_cooling_capacity', user_arguments),
             cooling_system_fraction_cool_load_served: runner.getDoubleArgumentValue('cooling_system_fraction_cool_load_served', user_arguments),
             cooling_system_evap_cooler_is_ducted: runner.getBoolArgumentValue('cooling_system_evap_cooler_is_ducted', user_arguments),
             heat_pump_type: runner.getStringArgumentValue('heat_pump_type', user_arguments),
             heat_pump_heating_efficiency_hspf: runner.getDoubleArgumentValue('heat_pump_heating_efficiency_hspf', user_arguments),
             heat_pump_heating_efficiency_cop: runner.getDoubleArgumentValue('heat_pump_heating_efficiency_cop', user_arguments),
             heat_pump_cooling_efficiency_seer: runner.getDoubleArgumentValue('heat_pump_cooling_efficiency_seer', user_arguments),
             heat_pump_cooling_efficiency_eer: runner.getDoubleArgumentValue('heat_pump_cooling_efficiency_eer', user_arguments),
             heat_pump_cooling_compressor_type: runner.getOptionalStringArgumentValue('heat_pump_cooling_compressor_type', user_arguments),
             heat_pump_cooling_sensible_heat_fraction: runner.getOptionalDoubleArgumentValue('heat_pump_cooling_sensible_heat_fraction', user_arguments),
             heat_pump_heating_capacity: runner.getStringArgumentValue('heat_pump_heating_capacity', user_arguments),
             heat_pump_heating_capacity_17F: runner.getStringArgumentValue('heat_pump_heating_capacity_17F', user_arguments),
             heat_pump_cooling_capacity: runner.getStringArgumentValue('heat_pump_cooling_capacity', user_arguments),
             heat_pump_fraction_heat_load_served: runner.getDoubleArgumentValue('heat_pump_fraction_heat_load_served', user_arguments),
             heat_pump_fraction_cool_load_served: runner.getDoubleArgumentValue('heat_pump_fraction_cool_load_served', user_arguments),
             heat_pump_backup_fuel: runner.getStringArgumentValue('heat_pump_backup_fuel', user_arguments),
             heat_pump_backup_heating_efficiency: runner.getDoubleArgumentValue('heat_pump_backup_heating_efficiency', user_arguments),
             heat_pump_backup_heating_capacity: runner.getStringArgumentValue('heat_pump_backup_heating_capacity', user_arguments),
             heat_pump_backup_heating_switchover_temp: runner.getOptionalDoubleArgumentValue('heat_pump_backup_heating_switchover_temp', user_arguments),
             heat_pump_mini_split_is_ducted: runner.getBoolArgumentValue('heat_pump_mini_split_is_ducted', user_arguments),
             setpoint_heating_temp: runner.getDoubleArgumentValue('setpoint_heating_temp', user_arguments),
             setpoint_heating_setback_temp: runner.getDoubleArgumentValue('setpoint_heating_setback_temp', user_arguments),
             setpoint_heating_setback_hours_per_week: runner.getDoubleArgumentValue('setpoint_heating_setback_hours_per_week', user_arguments),
             setpoint_heating_setback_start_hour: runner.getDoubleArgumentValue('setpoint_heating_setback_start_hour', user_arguments),
             setpoint_cooling_temp: runner.getDoubleArgumentValue('setpoint_cooling_temp', user_arguments),
             setpoint_cooling_setup_temp: runner.getDoubleArgumentValue('setpoint_cooling_setup_temp', user_arguments),
             setpoint_cooling_setup_hours_per_week: runner.getDoubleArgumentValue('setpoint_cooling_setup_hours_per_week', user_arguments),
             setpoint_cooling_setup_start_hour: runner.getDoubleArgumentValue('setpoint_cooling_setup_start_hour', user_arguments),
             ducts_supply_leakage_units: runner.getStringArgumentValue('ducts_supply_leakage_units', user_arguments),
             ducts_return_leakage_units: runner.getStringArgumentValue('ducts_return_leakage_units', user_arguments),
             ducts_supply_leakage_value: runner.getDoubleArgumentValue('ducts_supply_leakage_value', user_arguments),
             ducts_return_leakage_value: runner.getDoubleArgumentValue('ducts_return_leakage_value', user_arguments),
             ducts_supply_insulation_r_value: runner.getDoubleArgumentValue('ducts_supply_insulation_r', user_arguments),
             ducts_return_insulation_r_value: runner.getDoubleArgumentValue('ducts_return_insulation_r', user_arguments),
             ducts_supply_location: runner.getStringArgumentValue('ducts_supply_location', user_arguments),
             ducts_return_location: runner.getStringArgumentValue('ducts_return_location', user_arguments),
             ducts_supply_surface_area: runner.getDoubleArgumentValue('ducts_supply_surface_area', user_arguments),
             ducts_return_surface_area: runner.getDoubleArgumentValue('ducts_return_surface_area', user_arguments),
             mech_vent_fan_type: runner.getStringArgumentValue('mech_vent_fan_type', user_arguments),
             mech_vent_flow_rate: runner.getDoubleArgumentValue('mech_vent_flow_rate', user_arguments),
             mech_vent_hours_in_operation: runner.getDoubleArgumentValue('mech_vent_hours_in_operation', user_arguments),
             mech_vent_total_recovery_efficiency_type: runner.getStringArgumentValue('mech_vent_total_recovery_efficiency_type', user_arguments),
             mech_vent_total_recovery_efficiency: runner.getDoubleArgumentValue('mech_vent_total_recovery_efficiency', user_arguments),
             mech_vent_sensible_recovery_efficiency_type: runner.getStringArgumentValue('mech_vent_sensible_recovery_efficiency_type', user_arguments),
             mech_vent_sensible_recovery_efficiency: runner.getDoubleArgumentValue('mech_vent_sensible_recovery_efficiency', user_arguments),
             mech_vent_fan_power: runner.getDoubleArgumentValue('mech_vent_fan_power', user_arguments),
             kitchen_fan_present: runner.getBoolArgumentValue('kitchen_fan_present', user_arguments),
             kitchen_fan_flow_rate: runner.getOptionalDoubleArgumentValue('kitchen_fan_flow_rate', user_arguments),
             kitchen_fan_hours_in_operation: runner.getOptionalDoubleArgumentValue('kitchen_fan_hours_in_operation', user_arguments),
             kitchen_fan_power: runner.getOptionalDoubleArgumentValue('kitchen_fan_power', user_arguments),
             kitchen_fan_start_hour: runner.getIntegerArgumentValue('kitchen_fan_start_hour', user_arguments),
             bathroom_fans_present: runner.getBoolArgumentValue('bathroom_fans_present', user_arguments),
             bathroom_fans_flow_rate: runner.getOptionalDoubleArgumentValue('bathroom_fans_flow_rate', user_arguments),
             bathroom_fans_hours_in_operation: runner.getOptionalDoubleArgumentValue('bathroom_fans_hours_in_operation', user_arguments),
             bathroom_fans_power: runner.getOptionalDoubleArgumentValue('bathroom_fans_power', user_arguments),
             bathroom_fans_start_hour: runner.getIntegerArgumentValue('bathroom_fans_start_hour', user_arguments),
             bathroom_fans_quantity: runner.getOptionalIntegerArgumentValue('bathroom_fans_quantity', user_arguments),
             whole_house_fan_present: runner.getBoolArgumentValue('whole_house_fan_present', user_arguments),
             whole_house_fan_flow_rate: runner.getDoubleArgumentValue('whole_house_fan_flow_rate', user_arguments),
             whole_house_fan_power: runner.getDoubleArgumentValue('whole_house_fan_power', user_arguments),
             water_heater_type: runner.getStringArgumentValue('water_heater_type', user_arguments),
             water_heater_fuel_type: runner.getStringArgumentValue('water_heater_fuel_type', user_arguments),
             water_heater_location: runner.getStringArgumentValue('water_heater_location', user_arguments),
             water_heater_tank_volume: runner.getStringArgumentValue('water_heater_tank_volume', user_arguments),
             water_heater_heating_capacity: runner.getStringArgumentValue('water_heater_heating_capacity', user_arguments),
             water_heater_efficiency_type: runner.getStringArgumentValue('water_heater_efficiency_type', user_arguments),
             water_heater_efficiency_ef: runner.getDoubleArgumentValue('water_heater_efficiency_ef', user_arguments),
             water_heater_efficiency_uef: runner.getDoubleArgumentValue('water_heater_efficiency_uef', user_arguments),
             water_heater_recovery_efficiency: runner.getStringArgumentValue('water_heater_recovery_efficiency', user_arguments),
             water_heater_standby_loss: runner.getOptionalDoubleArgumentValue('water_heater_standby_loss', user_arguments),
             water_heater_jacket_rvalue: runner.getOptionalDoubleArgumentValue('water_heater_jacket_rvalue', user_arguments),
             water_heater_setpoint_temperature: runner.getStringArgumentValue('water_heater_setpoint_temperature', user_arguments),
             dhw_distribution_system_type: runner.getStringArgumentValue('dhw_distribution_system_type', user_arguments),
             dhw_distribution_standard_piping_length: runner.getStringArgumentValue('dhw_distribution_standard_piping_length', user_arguments),
             dhw_distribution_recirc_control_type: runner.getStringArgumentValue('dhw_distribution_recirc_control_type', user_arguments),
             dhw_distribution_recirc_piping_length: runner.getStringArgumentValue('dhw_distribution_recirc_piping_length', user_arguments),
             dhw_distribution_recirc_branch_piping_length: runner.getStringArgumentValue('dhw_distribution_recirc_branch_piping_length', user_arguments),
             dhw_distribution_recirc_pump_power: runner.getStringArgumentValue('dhw_distribution_recirc_pump_power', user_arguments),
             dhw_distribution_pipe_r: runner.getDoubleArgumentValue('dhw_distribution_pipe_r', user_arguments),
             dwhr_facilities_connected: runner.getStringArgumentValue('dwhr_facilities_connected', user_arguments),
             dwhr_equal_flow: runner.getBoolArgumentValue('dwhr_equal_flow', user_arguments),
             dwhr_efficiency: runner.getDoubleArgumentValue('dwhr_efficiency', user_arguments),
             water_fixtures_shower_low_flow: runner.getBoolArgumentValue('water_fixtures_shower_low_flow', user_arguments),
             water_fixtures_sink_low_flow: runner.getBoolArgumentValue('water_fixtures_sink_low_flow', user_arguments),
             water_fixtures_usage_multiplier: runner.getDoubleArgumentValue('water_fixtures_usage_multiplier', user_arguments),
             solar_thermal_system_type: runner.getStringArgumentValue('solar_thermal_system_type', user_arguments),
             solar_thermal_collector_area: runner.getDoubleArgumentValue('solar_thermal_collector_area', user_arguments),
             solar_thermal_collector_loop_type: runner.getStringArgumentValue('solar_thermal_collector_loop_type', user_arguments),
             solar_thermal_collector_type: runner.getStringArgumentValue('solar_thermal_collector_type', user_arguments),
             solar_thermal_collector_azimuth: runner.getDoubleArgumentValue('solar_thermal_collector_azimuth', user_arguments),
             solar_thermal_collector_tilt: runner.getStringArgumentValue('solar_thermal_collector_tilt', user_arguments),
             solar_thermal_collector_rated_optical_efficiency: runner.getDoubleArgumentValue('solar_thermal_collector_rated_optical_efficiency', user_arguments),
             solar_thermal_collector_rated_thermal_losses: runner.getDoubleArgumentValue('solar_thermal_collector_rated_thermal_losses', user_arguments),
             solar_thermal_storage_volume: runner.getStringArgumentValue('solar_thermal_storage_volume', user_arguments),
             solar_thermal_solar_fraction: runner.getDoubleArgumentValue('solar_thermal_solar_fraction', user_arguments),
             pv_system_module_type: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getStringArgumentValue("pv_system_module_type_#{n}", user_arguments) },
             pv_system_location: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getStringArgumentValue("pv_system_location_#{n}", user_arguments) },
             pv_system_tracking: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getStringArgumentValue("pv_system_tracking_#{n}", user_arguments) },
             pv_system_array_azimuth: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getDoubleArgumentValue("pv_system_array_azimuth_#{n}", user_arguments) },
             pv_system_array_tilt: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getStringArgumentValue("pv_system_array_tilt_#{n}", user_arguments) },
             pv_system_max_power_output: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getDoubleArgumentValue("pv_system_max_power_output_#{n}", user_arguments) },
             pv_system_inverter_efficiency: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getDoubleArgumentValue("pv_system_inverter_efficiency_#{n}", user_arguments) },
             pv_system_system_losses_fraction: (1..Constants.MaxNumPhotovoltaics).to_a.map { |n| runner.getDoubleArgumentValue("pv_system_system_losses_fraction_#{n}", user_arguments) },
             lighting_usage_multiplier: runner.getDoubleArgumentValue('lighting_usage_multiplier', user_arguments),
             dehumidifier_present: runner.getBoolArgumentValue('dehumidifier_present', user_arguments),
             dehumidifier_efficiency_type: runner.getStringArgumentValue('dehumidifier_efficiency_type', user_arguments),
             dehumidifier_efficiency_ef: runner.getDoubleArgumentValue('dehumidifier_efficiency_ef', user_arguments),
             dehumidifier_efficiency_ief: runner.getDoubleArgumentValue('dehumidifier_efficiency_ief', user_arguments),
             dehumidifier_capacity: runner.getDoubleArgumentValue('dehumidifier_capacity', user_arguments),
             dehumidifier_rh_setpoint: runner.getDoubleArgumentValue('dehumidifier_rh_setpoint', user_arguments),
             dehumidifier_fraction_dehumidification_load_served: runner.getDoubleArgumentValue('dehumidifier_fraction_dehumidification_load_served', user_arguments),
             clothes_washer_present: runner.getBoolArgumentValue('clothes_washer_present', user_arguments),
             clothes_washer_location: runner.getStringArgumentValue('clothes_washer_location', user_arguments),
             clothes_washer_efficiency_type: runner.getStringArgumentValue('clothes_washer_efficiency_type', user_arguments),
             clothes_washer_efficiency_mef: runner.getDoubleArgumentValue('clothes_washer_efficiency_mef', user_arguments),
             clothes_washer_efficiency_imef: runner.getDoubleArgumentValue('clothes_washer_efficiency_imef', user_arguments),
             clothes_washer_rated_annual_kwh: runner.getDoubleArgumentValue('clothes_washer_rated_annual_kwh', user_arguments),
             clothes_washer_label_electric_rate: runner.getDoubleArgumentValue('clothes_washer_label_electric_rate', user_arguments),
             clothes_washer_label_gas_rate: runner.getDoubleArgumentValue('clothes_washer_label_gas_rate', user_arguments),
             clothes_washer_label_annual_gas_cost: runner.getDoubleArgumentValue('clothes_washer_label_annual_gas_cost', user_arguments),
             clothes_washer_label_usage: runner.getDoubleArgumentValue('clothes_washer_label_usage', user_arguments),
             clothes_washer_capacity: runner.getDoubleArgumentValue('clothes_washer_capacity', user_arguments),
             clothes_washer_usage_multiplier: runner.getDoubleArgumentValue('clothes_washer_usage_multiplier', user_arguments),
             clothes_dryer_present: runner.getBoolArgumentValue('clothes_dryer_present', user_arguments),
             clothes_dryer_location: runner.getStringArgumentValue('clothes_dryer_location', user_arguments),
             clothes_dryer_fuel_type: runner.getStringArgumentValue('clothes_dryer_fuel_type', user_arguments),
             clothes_dryer_efficiency_type: runner.getStringArgumentValue('clothes_dryer_efficiency_type', user_arguments),
             clothes_dryer_efficiency_ef: runner.getDoubleArgumentValue('clothes_dryer_efficiency_ef', user_arguments),
             clothes_dryer_efficiency_cef: runner.getDoubleArgumentValue('clothes_dryer_efficiency_cef', user_arguments),
             clothes_dryer_control_type: runner.getStringArgumentValue('clothes_dryer_control_type', user_arguments),
             clothes_dryer_usage_multiplier: runner.getDoubleArgumentValue('clothes_dryer_usage_multiplier', user_arguments),
             dishwasher_present: runner.getBoolArgumentValue('dishwasher_present', user_arguments),
             dishwasher_efficiency_type: runner.getStringArgumentValue('dishwasher_efficiency_type', user_arguments),
             dishwasher_efficiency_kwh: runner.getDoubleArgumentValue('dishwasher_efficiency_kwh', user_arguments),
             dishwasher_efficiency_ef: runner.getDoubleArgumentValue('dishwasher_efficiency_ef', user_arguments),
             dishwasher_label_electric_rate: runner.getDoubleArgumentValue('dishwasher_label_electric_rate', user_arguments),
             dishwasher_label_gas_rate: runner.getDoubleArgumentValue('dishwasher_label_gas_rate', user_arguments),
             dishwasher_label_annual_gas_cost: runner.getDoubleArgumentValue('dishwasher_label_annual_gas_cost', user_arguments),
             dishwasher_label_usage: runner.getDoubleArgumentValue('dishwasher_label_usage', user_arguments),
             dishwasher_place_setting_capacity: runner.getIntegerArgumentValue('dishwasher_place_setting_capacity', user_arguments),
             dishwasher_usage_multiplier: runner.getDoubleArgumentValue('dishwasher_usage_multiplier', user_arguments),
             refrigerator_present: runner.getBoolArgumentValue('refrigerator_present', user_arguments),
             refrigerator_location: runner.getStringArgumentValue('refrigerator_location', user_arguments),
             refrigerator_rated_annual_kwh: runner.getDoubleArgumentValue('refrigerator_rated_annual_kwh', user_arguments),
             refrigerator_usage_multiplier: runner.getDoubleArgumentValue('refrigerator_usage_multiplier', user_arguments),
             cooking_range_oven_present: runner.getBoolArgumentValue('cooking_range_oven_present', user_arguments),
             cooking_range_oven_fuel_type: runner.getStringArgumentValue('cooking_range_oven_fuel_type', user_arguments),
             cooking_range_oven_is_induction: runner.getStringArgumentValue('cooking_range_oven_is_induction', user_arguments),
             cooking_range_oven_is_convection: runner.getStringArgumentValue('cooking_range_oven_is_convection', user_arguments),
             cooking_range_oven_usage_multiplier: runner.getDoubleArgumentValue('cooking_range_oven_usage_multiplier', user_arguments),
             ceiling_fan_efficiency: runner.getDoubleArgumentValue('ceiling_fan_efficiency', user_arguments),
             ceiling_fan_quantity: runner.getIntegerArgumentValue('ceiling_fan_quantity', user_arguments),
             ceiling_fan_cooling_setpoint_temp_offset: runner.getDoubleArgumentValue('ceiling_fan_cooling_setpoint_temp_offset', user_arguments),
             plug_loads_television_annual_kwh: runner.getStringArgumentValue('plug_loads_television_annual_kwh', user_arguments),
             plug_loads_other_annual_kwh: runner.getStringArgumentValue('plug_loads_other_annual_kwh', user_arguments),
             plug_loads_other_frac_sensible: runner.getDoubleArgumentValue('plug_loads_other_frac_sensible', user_arguments),
             plug_loads_other_frac_latent: runner.getDoubleArgumentValue('plug_loads_other_frac_latent', user_arguments),
             plug_loads_schedule_values: runner.getBoolArgumentValue('plug_loads_schedule_values', user_arguments),
             plug_loads_weekday_fractions: runner.getStringArgumentValue('plug_loads_weekday_fractions', user_arguments),
             plug_loads_weekend_fractions: runner.getStringArgumentValue('plug_loads_weekend_fractions', user_arguments),
             plug_loads_monthly_multipliers: runner.getStringArgumentValue('plug_loads_monthly_multipliers', user_arguments),
             plug_loads_usage_multiplier: runner.getDoubleArgumentValue('plug_loads_usage_multiplier', user_arguments) }

    # Argument error checks
    warnings, errors = validate_arguments(args)
    unless warnings.empty?
      warnings.each do |warning|
        runner.registerWarning(warning)
      end
    end
    unless errors.empty?
      errors.each do |error|
        runner.registerError(error)
      end
      return false
    end

    # Get weather object
    weather_dir = args[:weather_dir]
    unless (Pathname.new weather_dir).absolute?
      weather_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', weather_dir))
    end
    epw_path = File.join(weather_dir, args[:weather_station_epw_filepath])
    if not File.exist?(epw_path)
      runner.registerError("Could not find EPW file at '#{epw_path}'.")
      return false
    end
    cache_path = epw_path.gsub('.epw', '-cache.csv')
    if not File.exist?(cache_path)
      # Process weather file to create cache .csv
      runner.registerWarning("'#{cache_path}' could not be found; regenerating it.")
      epw_file = OpenStudio::EpwFile.new(epw_path)
      OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file)
      weather = WeatherProcess.new(model, runner)
      File.open(cache_path, 'wb') do |file|
        weather.dump_to_csv(file)
      end
    else
      weather = WeatherProcess.new(nil, nil, cache_path)
    end

    # Create HPXML file
    hpxml_doc = HPXMLFile.create(runner, model, args, weather)
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

  def validate_arguments(args)
    warnings = []
    errors = []

    # heat pump water heater with natural gas fuel type
    warning = ([HPXML::WaterHeaterTypeHeatPump].include?(args[:water_heater_type]) && (args[:water_heater_fuel_type] != HPXML::FuelTypeElectricity))
    warnings << "water_heater_type=#{args[:water_heater_type]} and water_heater_fuel_type=#{args[:water_heater_fuel_type]}" if warning

    # furnace, air conditioner, and heat pump
    error = (args[:heating_system_type] != 'none') && (args[:cooling_system_type] != 'none') && (args[:heat_pump_type] != 'none')
    errors << "heating_system_type=#{args[:heating_system_type]} and cooling_system_type=#{args[:cooling_system_type]} and heat_pump_type=#{args[:heat_pump_type]}" if error

    return warnings, errors
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
  def self.create(runner, model, args, weather)
    model_geometry = OpenStudio::Model::Model.new

    success = create_geometry_envelope(runner, model_geometry, args)
    return false if not success

    # success = create_schedules(runner, model, args)
    # return false if not success

    hpxml = HPXML.new

    set_header(hpxml, runner, args)
    set_site(hpxml, runner, args)
    set_neighbor_buildings(hpxml, runner, args)
    set_building_occupancy(hpxml, runner, args)
    set_building_construction(hpxml, runner, args)
    set_climate_and_risk_zones(hpxml, runner, args, weather)
    set_air_infiltration_measurements(hpxml, runner, args)
    set_attics(hpxml, runner, model_geometry, args)
    set_foundations(hpxml, runner, model_geometry, args)
    set_roofs(hpxml, runner, model_geometry, args)
    set_rim_joists(hpxml, runner, model_geometry, args)
    set_walls(hpxml, runner, model_geometry, args)
    set_foundation_walls(hpxml, runner, model_geometry, args)
    set_frame_floors(hpxml, runner, model_geometry, args)
    set_slabs(hpxml, runner, model_geometry, args)
    set_windows(hpxml, runner, model_geometry, args)
    set_skylights(hpxml, runner, model_geometry, args)
    set_doors(hpxml, runner, model_geometry, args)
    set_heating_systems(hpxml, runner, args)
    set_cooling_systems(hpxml, runner, args)
    set_heat_pumps(hpxml, runner, args)
    set_hvac_distribution(hpxml, runner, args)
    set_hvac_control(hpxml, runner, args)
    set_ventilation_fans(hpxml, runner, args)
    set_water_heating_systems(hpxml, runner, args)
    set_hot_water_distribution(hpxml, runner, args)
    set_water_fixtures(hpxml, runner, args)
    set_solar_thermal(hpxml, runner, args, weather)
    set_pv_systems(hpxml, runner, args, weather)
    set_lighting(hpxml, runner, args)
    set_dehumidifier(hpxml, runner, args)
    set_clothes_washer(hpxml, runner, args)
    set_clothes_dryer(hpxml, runner, args)
    set_dishwasher(hpxml, runner, args)
    set_refrigerator(hpxml, runner, args)
    set_cooking_range_oven(hpxml, runner, args)
    set_ceiling_fans(hpxml, runner, args)
    set_plug_loads(hpxml, runner, args)
    set_misc_loads_schedule(hpxml, runner, args)

    # Check for errors in the HPXML object
    errors = hpxml.check_for_errors()
    if errors.size > 0
      fail "ERROR: Invalid HPXML object produced.\n#{errors}"
    end

    hpxml_doc = hpxml.to_rexml()

    return hpxml_doc
  end

  def self.create_geometry_envelope(runner, model, args)
    if ([HPXML::ResidentialTypeMF2to4, HPXML::ResidentialTypeMF5plus].include? args[:geometry_unit_type]) && (args[:geometry_level] != 'Bottom')
      args[:geometry_foundation_type] = HPXML::LocationOtherHousingUnitBelow
      args[:geometry_foundation_height] = 0.0
    end

    if args[:geometry_unit_type] == HPXML::ResidentialTypeSFD
      success = Geometry.create_single_family_detached(runner: runner, model: model, **args)
    elsif args[:geometry_unit_type] == HPXML::ResidentialTypeSFA
      success = Geometry.create_single_family_attached(runner: runner, model: model, **args)
    elsif [HPXML::ResidentialTypeMF2to4, HPXML::ResidentialTypeMF5plus].include? args[:geometry_unit_type]
      success = Geometry.create_multifamily(runner: runner, model: model, **args)
    end
    return false if not success

    success = Geometry.create_windows_and_skylights(runner: runner, model: model, **args)
    return false if not success

    success = Geometry.create_doors(runner: runner, model: model, **args)
    return false if not success

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
    hpxml.header.xml_type = 'HPXML'
    hpxml.header.xml_generated_by = 'BuildResidentialHPXML'
    hpxml.header.transaction = 'create'
    hpxml.header.timestep = args[:timestep]
    if not (args[:begin_month] == 1 && args[:begin_day_of_month] == 1)
      hpxml.header.begin_month = args[:begin_month]
      hpxml.header.begin_day_of_month = args[:begin_day_of_month]
    end
    if not (args[:end_month] == 12 && args[:end_day_of_month] == 31)
      hpxml.header.end_month = args[:end_month]
      hpxml.header.end_day_of_month = args[:end_day_of_month]
    end
    hpxml.header.building_id = 'MyBuilding'
    hpxml.header.event_type = 'proposed workscope'
  end

  def self.set_site(hpxml, runner, args)
    return if args[:air_leakage_shelter_coefficient] == Constants.Auto

    hpxml.site.shelter_coefficient = args[:air_leakage_shelter_coefficient]
  end

  def self.set_neighbor_buildings(hpxml, runner, args)
    args[:neighbor_distance].each_with_index do |distance, i|
      next if distance == 0

      if i == 0 # front
        azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 0, args[:geometry_orientation], 0)
      elsif i == 1 # back
        azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 180, args[:geometry_orientation], 0)
      elsif i == 2 # left
        azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 90, args[:geometry_orientation], 0)
      elsif i == 3 # right
        azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 270, args[:geometry_orientation], 0)
      end

      if (distance > 0) && (args[:neighbor_height][i] != Constants.Auto)
        height = Float(args[:neighbor_height][i])
      end

      hpxml.neighbor_buildings.add(azimuth: azimuth,
                                   distance: distance,
                                   height: height)
    end
  end

  def self.set_building_occupancy(hpxml, runner, args)
    if args[:geometry_num_occupants] != Constants.Auto
      hpxml.building_occupancy.number_of_residents = args[:geometry_num_occupants]
    end
    hpxml.building_occupancy.schedules_output_path = args[:schedules_output_path]
    hpxml.building_occupancy.schedules_column_name = 'occupants'
  end

  def self.set_building_construction(hpxml, runner, args)
    number_of_conditioned_floors_above_grade = args[:geometry_num_floors_above_grade]

    number_of_conditioned_floors = number_of_conditioned_floors_above_grade
    if args[:geometry_foundation_type] == HPXML::FoundationTypeBasementConditioned
      number_of_conditioned_floors += 1
    end

    if args[:geometry_num_bathrooms] != Constants.Auto
      number_of_bathrooms = args[:geometry_num_bathrooms]
    end

    conditioned_building_volume = args[:geometry_cfa] * args[:geometry_wall_height]

    hpxml.building_construction.number_of_conditioned_floors = number_of_conditioned_floors
    hpxml.building_construction.number_of_conditioned_floors_above_grade = number_of_conditioned_floors_above_grade
    hpxml.building_construction.number_of_bedrooms = args[:geometry_num_bedrooms]
    hpxml.building_construction.number_of_bathrooms = number_of_bathrooms
    hpxml.building_construction.conditioned_floor_area = args[:geometry_cfa]
    hpxml.building_construction.conditioned_building_volume = conditioned_building_volume
    hpxml.building_construction.average_ceiling_height = args[:geometry_wall_height]
    hpxml.building_construction.residential_facility_type = args[:geometry_unit_type]
  end

  def self.set_climate_and_risk_zones(hpxml, runner, args, weather)
    hpxml.climate_and_risk_zones.weather_station_id = 'WeatherStation'
    iecc_zone = Location.get_climate_zone_iecc(weather.header.Station)
    if (not iecc_zone.nil?)
      hpxml.climate_and_risk_zones.iecc_year = 2006
      hpxml.climate_and_risk_zones.iecc_zone = iecc_zone
    end
    hpxml.climate_and_risk_zones.weather_station_name = args[:weather_station_epw_filepath].gsub('.epw', '')
    hpxml.climate_and_risk_zones.weather_station_epw_filepath = args[:weather_station_epw_filepath]
  end

  def self.set_attics(hpxml, runner, model, args)
    return if [HPXML::ResidentialTypeMF2to4, HPXML::ResidentialTypeMF5plus].include? args[:geometry_unit_type]
    return if args[:geometry_unit_type] == HPXML::ResidentialTypeSFA # TODO: remove when we can model single-family attached units

    if args[:geometry_roof_type] == 'flat'
      hpxml.attics.add(id: HPXML::AtticTypeFlatRoof,
                       attic_type: HPXML::AtticTypeFlatRoof)
    else
      hpxml.attics.add(id: args[:geometry_attic_type],
                       attic_type: args[:geometry_attic_type])
    end
  end

  def self.set_foundations(hpxml, runner, model, args)
    return if [HPXML::ResidentialTypeMF2to4, HPXML::ResidentialTypeMF5plus].include? args[:geometry_unit_type]

    hpxml.foundations.add(id: args[:geometry_foundation_type],
                          foundation_type: args[:geometry_foundation_type])
  end

  def self.set_air_infiltration_measurements(hpxml, runner, args)
    if args[:air_leakage_units] == HPXML::UnitsACH50
      unit_of_measure = HPXML::UnitsACH
    elsif args[:air_leakage_units] == HPXML::UnitsCFM50
      unit_of_measure = HPXML::UnitsCFM
    end
    infiltration_volume = args[:geometry_cfa] * args[:geometry_wall_height]

    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            house_pressure: 50,
                                            unit_of_measure: unit_of_measure,
                                            air_leakage: args[:air_leakage_value],
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

      pitch = args[:geometry_roof_pitch] * 12.0
      if args[:geometry_roof_type] == 'flat'
        pitch = 0.0
      end

      hpxml.roofs.add(id: "#{surface.name}",
                      interior_adjacent_to: get_adjacent_to(model, surface),
                      area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2').round,
                      solar_absorptance: args[:roof_solar_absorptance],
                      emittance: args[:roof_emittance],
                      pitch: pitch,
                      radiant_barrier: args[:roof_radiant_barrier],
                      insulation_assembly_r_value: args[:roof_assembly_r])
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

      is_uncond_attic_roof_insulated = false
      if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include? interior_adjacent_to
        hpxml.roofs.each do |roof|
          next unless (roof.interior_adjacent_to == interior_adjacent_to) && (roof.insulation_assembly_r_value > 4.0)

          is_uncond_attic_roof_insulated = true
        end
      end

      if hpxml.walls[-1].is_thermal_boundary || is_uncond_attic_roof_insulated # Assume wall is insulated if roof is insulated
        hpxml.walls[-1].insulation_assembly_r_value = args[:wall_assembly_r]
      else
        hpxml.walls[-1].insulation_assembly_r_value = 4.0 # Uninsulated
      end
    end
  end

  def self.set_foundation_walls(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      next unless ['Foundation'].include? surface.outsideBoundaryCondition
      next if surface.surfaceType != 'Wall'

      if args[:foundation_wall_assembly_r].is_initialized && (args[:foundation_wall_assembly_r].get > 0)
        insulation_assembly_r_value = args[:foundation_wall_assembly_r]
      else
        insulation_exterior_r_value = args[:foundation_wall_insulation_r]
        insulation_exterior_distance_to_top = args[:foundation_wall_insulation_distance_to_top]
        insulation_exterior_distance_to_bottom = args[:foundation_wall_insulation_distance_to_bottom]
        insulation_interior_r_value = 0
        insulation_interior_distance_to_top = 0
        insulation_interior_distance_to_bottom = 0
      end

      hpxml.foundation_walls.add(id: "#{surface.name}",
                                 exterior_adjacent_to: HPXML::LocationGround,
                                 interior_adjacent_to: get_adjacent_to(model, surface),
                                 height: args[:geometry_foundation_height],
                                 area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2').round,
                                 thickness: 8,
                                 depth_below_grade: args[:geometry_foundation_height] - args[:geometry_foundation_height_above_grade],
                                 insulation_assembly_r_value: insulation_assembly_r_value,
                                 insulation_interior_r_value: insulation_interior_r_value,
                                 insulation_interior_distance_to_top: insulation_interior_distance_to_top,
                                 insulation_interior_distance_to_bottom: insulation_interior_distance_to_bottom,
                                 insulation_exterior_r_value: insulation_exterior_r_value,
                                 insulation_exterior_distance_to_top: insulation_exterior_distance_to_top,
                                 insulation_exterior_distance_to_bottom: insulation_exterior_distance_to_bottom)
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

      if hpxml.frame_floors[-1].is_thermal_boundary
        if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented, HPXML::LocationGarage].include? exterior_adjacent_to
          hpxml.frame_floors[-1].insulation_assembly_r_value = args[:ceiling_assembly_r]
        else
          hpxml.frame_floors[-1].insulation_assembly_r_value = args[:floor_assembly_r]
        end
      else
        hpxml.frame_floors[-1].insulation_assembly_r_value = 2.1 # Uninsulated
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

      if args[:under_slab_insulation_width] == 999
        under_slab_insulation_spans_entire_slab = true
      else
        under_slab_insulation_width = args[:under_slab_insulation_width]
      end

      thickness = 4.0
      if interior_adjacent_to.include? 'crawlspace'
        thickness = 0.0 # Assume soil
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
                      carpet_fraction: args[:slab_carpet_fraction],
                      carpet_r_value: args[:slab_carpet_r_value])
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
        elsif args[:geometry_eaves_depth] > 0
          eaves_z = args[:geometry_wall_height] * args[:geometry_num_floors_above_grade]
          if args[:geometry_foundation_type] == HPXML::FoundationTypeAmbient
            eaves_z += args[:geometry_foundation_height]
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
          overhangs_depth = args[:geometry_eaves_depth]
          overhangs_distance_to_top_of_window = eaves_z - sub_surface_z
          overhangs_distance_to_bottom_of_window = (overhangs_distance_to_top_of_window + sub_surface_height).round
        end

        if sub_surface_facade == Constants.FacadeFront
          azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 0, args[:geometry_orientation], 0)
        elsif sub_surface_facade == Constants.FacadeBack
          azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 180, args[:geometry_orientation], 0)
        elsif sub_surface_facade == Constants.FacadeLeft
          azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 90, args[:geometry_orientation], 0)
        elsif sub_surface_facade == Constants.FacadeRight
          azimuth = Geometry.get_abs_azimuth(Constants.CoordRelative, 270, args[:geometry_orientation], 0)
        end

        hpxml.windows.add(id: "#{sub_surface.name}_#{sub_surface_facade}",
                          area: UnitConversions.convert(sub_surface.grossArea, 'm^2', 'ft^2').round(1),
                          azimuth: azimuth,
                          ufactor: args[:window_ufactor],
                          shgc: args[:window_shgc],
                          overhangs_depth: overhangs_depth,
                          overhangs_distance_to_top_of_window: overhangs_distance_to_top_of_window,
                          overhangs_distance_to_bottom_of_window: overhangs_distance_to_bottom_of_window,
                          interior_shading_factor_winter: args[:window_interior_shading_winter],
                          interior_shading_factor_summer: args[:window_interior_shading_summer],
                          fraction_operable: args[:window_fraction_operable],
                          wall_idref: "#{surface.name}")
      end # sub_surfaces
    end # surfaces
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
                            roof_idref: "#{surface.name}")
      end
    end
  end

  def self.set_doors(hpxml, runner, model, args)
    model.getSurfaces.each do |surface|
      surface.subSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType != 'Door'

        sub_surface_facade = Geometry.get_facade_for_surface(sub_surface)

        hpxml.doors.add(id: "#{sub_surface.name}_#{sub_surface_facade}",
                        wall_idref: "#{surface.name}",
                        area: UnitConversions.convert(sub_surface.grossArea, 'm^2', 'ft^2').round,
                        azimuth: args[:geometry_orientation],
                        r_value: args[:door_rvalue])
      end
    end
  end

  def self.set_heating_systems(hpxml, runner, args)
    heating_system_type = args[:heating_system_type]

    return if heating_system_type == 'none'

    heating_capacity = args[:heating_system_heating_capacity]
    if heating_capacity == Constants.Auto
      heating_capacity = -1
    end
    heating_capacity = Float(heating_capacity)

    if args[:heating_system_electric_auxiliary_energy].is_initialized
      if args[:heating_system_electric_auxiliary_energy].get > 0
        electric_auxiliary_energy = args[:heating_system_electric_auxiliary_energy].get
      end
    end

    if heating_system_type == HPXML::HVACTypeElectricResistance
      heating_system_fuel = HPXML::FuelTypeElectricity
    else
      heating_system_fuel = args[:heating_system_fuel]
    end

    if [HPXML::HVACTypeFurnace, HPXML::HVACTypeWallFurnace, HPXML::HVACTypeBoiler].include? heating_system_type
      heating_efficiency_afue = args[:heating_system_heating_efficiency_afue]
    elsif [HPXML::HVACTypeElectricResistance, HPXML::HVACTypeStove, HPXML::HVACTypePortableHeater]
      heating_efficiency_percent = args[:heating_system_heating_efficiency_percent]
    end

    hpxml.heating_systems.add(id: 'HeatingSystem',
                              heating_system_type: heating_system_type,
                              heating_system_fuel: heating_system_fuel,
                              heating_capacity: heating_capacity,
                              fraction_heat_load_served: args[:heating_system_fraction_heat_load_served],
                              electric_auxiliary_energy: electric_auxiliary_energy,
                              heating_efficiency_afue: heating_efficiency_afue,
                              heating_efficiency_percent: heating_efficiency_percent)
  end

  def self.set_cooling_systems(hpxml, runner, args)
    cooling_system_type = args[:cooling_system_type]

    return if cooling_system_type == 'none'

    if cooling_system_type != HPXML::HVACTypeEvaporativeCooler
      cooling_capacity = args[:cooling_system_cooling_capacity]
      if cooling_capacity == Constants.Auto
        cooling_capacity = -1
      end
      cooling_capacity = Float(cooling_capacity)
    end

    if args[:cooling_system_cooling_compressor_type].is_initialized
      if cooling_system_type == HPXML::HVACTypeCentralAirConditioner
        compressor_type = args[:cooling_system_cooling_compressor_type].get
      end
    end

    if args[:cooling_system_cooling_sensible_heat_fraction].is_initialized
      if cooling_system_type != HPXML::HVACTypeEvaporativeCooler
        cooling_shr = args[:cooling_system_cooling_sensible_heat_fraction].get
      end
    end

    if [HPXML::HVACTypeCentralAirConditioner].include? cooling_system_type
      cooling_efficiency_seer = args[:cooling_system_cooling_efficiency_seer]
    elsif [HPXML::HVACTypeRoomAirConditioner].include? cooling_system_type
      cooling_efficiency_eer = args[:cooling_system_cooling_efficiency_eer]
    end

    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              cooling_system_type: cooling_system_type,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: cooling_capacity,
                              fraction_cool_load_served: args[:cooling_system_fraction_cool_load_served],
                              compressor_type: compressor_type,
                              cooling_shr: cooling_shr,
                              cooling_efficiency_seer: cooling_efficiency_seer,
                              cooling_efficiency_eer: cooling_efficiency_eer)
  end

  def self.set_heat_pumps(hpxml, runner, args)
    heat_pump_type = args[:heat_pump_type]

    return if heat_pump_type == 'none'

    heating_capacity = args[:heat_pump_heating_capacity]
    if heating_capacity == Constants.Auto
      heating_capacity = -1
    end
    heating_capacity = Float(heating_capacity)

    if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump_type
      heating_capacity_17F = args[:heat_pump_heating_capacity_17F]
      if heating_capacity_17F == Constants.Auto
        heating_capacity_17F = nil
      else
        heating_capacity_17F = Float(heating_capacity_17F)
      end
    end

    if args[:heat_pump_backup_fuel] != 'none'
      backup_heating_fuel = args[:heat_pump_backup_fuel]

      backup_heating_capacity = args[:heat_pump_backup_heating_capacity]
      if backup_heating_capacity == Constants.Auto
        backup_heating_capacity = -1
      end
      backup_heating_capacity = Float(backup_heating_capacity)

      if backup_heating_fuel == HPXML::FuelTypeElectricity
        backup_heating_efficiency_percent = args[:heat_pump_backup_heating_efficiency]
      else
        backup_heating_efficiency_afue = args[:heat_pump_backup_heating_efficiency]
      end
      if args[:heat_pump_backup_heating_switchover_temp].is_initialized
        if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump_type
          backup_heating_switchover_temp = args[:heat_pump_backup_heating_switchover_temp].get
        end
      end
    end

    cooling_capacity = args[:heat_pump_cooling_capacity]
    if cooling_capacity == Constants.Auto
      cooling_capacity = -1
    end
    cooling_capacity = Float(cooling_capacity)

    if args[:heat_pump_cooling_compressor_type].is_initialized
      if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump_type
        compressor_type = args[:heat_pump_cooling_compressor_type].get
      end
    end

    if args[:heat_pump_cooling_sensible_heat_fraction].is_initialized
      cooling_shr = args[:heat_pump_cooling_sensible_heat_fraction].get
    end

    if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump_type
      heating_efficiency_hspf = args[:heat_pump_heating_efficiency_hspf]
      cooling_efficiency_seer = args[:heat_pump_cooling_efficiency_seer]
    elsif [HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump_type
      heating_efficiency_cop = args[:heat_pump_heating_efficiency_cop]
      cooling_efficiency_eer = args[:heat_pump_cooling_efficiency_eer]
    end

    hpxml.heat_pumps.add(id: 'HeatPump',
                         heat_pump_type: heat_pump_type,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: heating_capacity,
                         heating_capacity_17F: heating_capacity_17F,
                         compressor_type: compressor_type,
                         cooling_shr: cooling_shr,
                         cooling_capacity: cooling_capacity,
                         fraction_heat_load_served: args[:heat_pump_fraction_heat_load_served],
                         fraction_cool_load_served: args[:heat_pump_fraction_cool_load_served],
                         backup_heating_fuel: backup_heating_fuel,
                         backup_heating_capacity: backup_heating_capacity,
                         backup_heating_efficiency_afue: backup_heating_efficiency_afue,
                         backup_heating_efficiency_percent: backup_heating_efficiency_percent,
                         backup_heating_switchover_temp: backup_heating_switchover_temp,
                         heating_efficiency_hspf: heating_efficiency_hspf,
                         cooling_efficiency_seer: cooling_efficiency_seer,
                         heating_efficiency_cop: heating_efficiency_cop,
                         cooling_efficiency_eer: cooling_efficiency_eer)
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
      elsif [HPXML::HVACTypeEvaporativeCooler].include?(cooling_system.cooling_system_type) && args[:cooling_system_evap_cooler_is_ducted]
        air_distribution_systems << cooling_system
      end
    end
    hpxml.heat_pumps.each do |heat_pump|
      if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type
        air_distribution_systems << heat_pump
      elsif [HPXML::HVACTypeHeatPumpMiniSplit].include?(heat_pump.heat_pump_type) && args[:heat_pump_mini_split_is_ducted]
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
                                                               duct_leakage_units: args[:ducts_supply_leakage_units],
                                                               duct_leakage_value: args[:ducts_supply_leakage_value],
                                                               duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)

    if not ((args[:cooling_system_type] == HPXML::HVACTypeEvaporativeCooler) && args[:cooling_system_evap_cooler_is_ducted])
      hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                                 duct_leakage_units: args[:ducts_return_leakage_units],
                                                                 duct_leakage_value: args[:ducts_return_leakage_value],
                                                                 duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
    end

    # Ducts
    ducts_supply_location = args[:ducts_supply_location]
    if ducts_supply_location == Constants.Auto
      ducts_supply_location = get_duct_location_auto(args, hpxml)
    end

    ducts_return_location = args[:ducts_return_location]
    if ducts_return_location == Constants.Auto
      ducts_return_location = get_duct_location_auto(args, hpxml)
    end

    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                           duct_insulation_r_value: args[:ducts_supply_insulation_r_value],
                                           duct_location: ducts_supply_location,
                                           duct_surface_area: args[:ducts_supply_surface_area])

    if not ((args[:cooling_system_type] == HPXML::HVACTypeEvaporativeCooler) && args[:cooling_system_evap_cooler_is_ducted])
      hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                             duct_insulation_r_value: args[:ducts_return_insulation_r_value],
                                             duct_location: ducts_return_location,
                                             duct_surface_area: args[:ducts_return_surface_area])
    end
  end

  def self.set_hvac_control(hpxml, runner, args)
    return if (args[:heating_system_type] == 'none') && (args[:cooling_system_type] == 'none') && (args[:heat_pump_type] == 'none')

    if (args[:setpoint_heating_temp] != args[:setpoint_heating_setback_temp]) && (args[:setpoint_heating_setback_hours_per_week] > 0)
      heating_setback_temp = args[:setpoint_heating_setback_temp]
      heating_setback_hours_per_week = args[:setpoint_heating_setback_hours_per_week]
      heating_setback_start_hour = args[:setpoint_heating_setback_start_hour]
    end

    if (args[:setpoint_cooling_temp] != args[:setpoint_cooling_setup_temp]) && (args[:setpoint_cooling_setup_hours_per_week] > 0)
      cooling_setup_temp = args[:setpoint_cooling_setup_temp]
      cooling_setup_hours_per_week = args[:setpoint_cooling_setup_hours_per_week]
      cooling_setup_start_hour = args[:setpoint_cooling_setup_start_hour]
    end

    if (args[:ceiling_fan_cooling_setpoint_temp_offset] > 0) && (args[:ceiling_fan_quantity] > 0)
      ceiling_fan_cooling_setpoint_temp_offset = args[:ceiling_fan_cooling_setpoint_temp_offset]
    end

    hpxml.hvac_controls.add(id: 'HVACControl',
                            heating_setpoint_temp: args[:setpoint_heating_temp],
                            cooling_setpoint_temp: args[:setpoint_cooling_temp],
                            heating_setback_temp: heating_setback_temp,
                            heating_setback_hours_per_week: heating_setback_hours_per_week,
                            heating_setback_start_hour: heating_setback_start_hour,
                            cooling_setup_temp: cooling_setup_temp,
                            cooling_setup_hours_per_week: cooling_setup_hours_per_week,
                            cooling_setup_start_hour: cooling_setup_start_hour,
                            ceiling_fan_cooling_setpoint_temp_offset: ceiling_fan_cooling_setpoint_temp_offset)
  end

  def self.get_duct_location_auto(args, hpxml) # FIXME
    if args[:geometry_roof_type] != 'flat' && hpxml.attics.size > 0 && [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented].include?(args[:geometry_attic_type])
      location = hpxml.attics[0].to_location
    elsif hpxml.foundations.size > 0 && (args[:geometry_foundation_type].downcase.include?('basement') || args[:geometry_foundation_type].downcase.include?('crawlspace'))
      location = hpxml.foundations[0].to_location
    else
      location = HPXML::LocationLivingSpace
    end
    return location
  end

  def self.set_ventilation_fans(hpxml, runner, args)
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
                                 rated_flow_rate: args[:mech_vent_flow_rate],
                                 hours_in_operation: args[:mech_vent_hours_in_operation],
                                 used_for_whole_building_ventilation: true,
                                 total_recovery_efficiency: total_recovery_efficiency,
                                 total_recovery_efficiency_adjusted: total_recovery_efficiency_adjusted,
                                 sensible_recovery_efficiency: sensible_recovery_efficiency,
                                 sensible_recovery_efficiency_adjusted: sensible_recovery_efficiency_adjusted,
                                 fan_power: args[:mech_vent_fan_power],
                                 distribution_system_idref: distribution_system_idref)
    end

    if args[:kitchen_fan_present]
      if args[:kitchen_fan_flow_rate].is_initialized
        rated_flow_rate = args[:kitchen_fan_flow_rate].get
      end

      if args[:kitchen_fan_power].is_initialized
        fan_power = args[:kitchen_fan_power].get
      end

      if args[:kitchen_fan_hours_in_operation].is_initialized
        hours_in_operation = args[:kitchen_fan_hours_in_operation].get
      end

      hpxml.ventilation_fans.add(id: 'KitchenRangeFan',
                                 rated_flow_rate: rated_flow_rate,
                                 used_for_local_ventilation: true,
                                 hours_in_operation: hours_in_operation,
                                 fan_location: 'kitchen',
                                 fan_power: fan_power,
                                 start_hour: args[:kitchen_fan_start_hour])
    end

    if args[:bathroom_fans_present]
      if args[:bathroom_fans_flow_rate].is_initialized
        rated_flow_rate = args[:bathroom_fans_flow_rate].get
      end

      if args[:bathroom_fans_power].is_initialized
        fan_power = args[:bathroom_fans_power].get
      end

      if args[:bathroom_fans_hours_in_operation].is_initialized
        hours_in_operation = args[:bathroom_fans_hours_in_operation].get
      end

      if args[:bathroom_fans_quantity].is_initialized
        quantity = args[:bathroom_fans_quantity].get
      end

      hpxml.ventilation_fans.add(id: 'BathFans',
                                 rated_flow_rate: rated_flow_rate,
                                 used_for_local_ventilation: true,
                                 hours_in_operation: hours_in_operation,
                                 fan_location: 'bath',
                                 fan_power: fan_power,
                                 start_hour: args[:bathroom_fans_start_hour],
                                 quantity: quantity)
    end

    if args[:whole_house_fan_present]
      hpxml.ventilation_fans.add(id: 'WholeHouseFan',
                                 rated_flow_rate: args[:whole_house_fan_flow_rate],
                                 used_for_seasonal_cooling_load_reduction: true,
                                 fan_power: args[:whole_house_fan_power])
    end
  end

  def self.set_water_heating_systems(hpxml, runner, args)
    water_heater_type = args[:water_heater_type]
    return if water_heater_type == 'none'

    if water_heater_type != HPXML::WaterHeaterTypeHeatPump
      fuel_type = args[:water_heater_fuel_type]
    else
      fuel_type = HPXML::FuelTypeElectricity
    end

    if args[:water_heater_location] != Constants.Auto
      location = args[:water_heater_location]
    end

    if args[:geometry_num_bathrooms] != Constants.Auto
      num_bathrooms = args[:geometry_num_bathrooms]
    end

    if args[:water_heater_tank_volume] != Constants.Auto
      tank_volume = args[:water_heater_tank_volume]
    end

    if args[:water_heater_heating_capacity] != Constants.Auto
      heating_capacity = args[:water_heater_heating_capacity]
    end

    if args[:water_heater_setpoint_temperature] != Constants.Auto
      temperature = args[:water_heater_setpoint_temperature]
    end

    if not [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? water_heater_type
      if args[:water_heater_efficiency_type] == 'EnergyFactor'
        energy_factor = args[:water_heater_efficiency_ef]
      elsif args[:water_heater_efficiency_type] == 'UniformEnergyFactor'
        uniform_energy_factor = args[:water_heater_efficiency_uef]
      end
    end

    if (fuel_type != HPXML::FuelTypeElectricity) && (water_heater_type == HPXML::WaterHeaterTypeStorage)
      recovery_efficiency = args[:water_heater_recovery_efficiency]
    end

    if [HPXML::WaterHeaterTypeTankless].include? water_heater_type
      heating_capacity = nil
      recovery_efficiency = nil
    elsif [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? water_heater_type
      fuel_type = nil
      heating_capacity = nil
      energy_factor = nil

      if hpxml.heating_systems.size == 0
        fail 'Combi boiler water heater specified but no heating system found.'
      end

      related_hvac_idref = hpxml.heating_systems[0].id
    end

    if [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? water_heater_type
      if args[:water_heater_standby_loss].is_initialized
        if args[:water_heater_standby_loss].get > 0
          standby_loss = args[:water_heater_standby_loss].get
        end
      end
    end

    if not [HPXML::WaterHeaterTypeTankless, HPXML::WaterHeaterTypeCombiTankless].include? water_heater_type
      if args[:water_heater_jacket_rvalue].is_initialized
        if args[:water_heater_jacket_rvalue].get > 0
          jacket_r_value = args[:water_heater_jacket_rvalue].get
        end
      end
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
                                    jacket_r_value: jacket_r_value,
                                    temperature: temperature)
  end

  def self.set_hot_water_distribution(hpxml, runner, args)
    return if args[:water_heater_type] == 'none'

    if args[:dwhr_facilities_connected] != 'none'
      dwhr_facilities_connected = args[:dwhr_facilities_connected]
      dwhr_equal_flow = args[:dwhr_equal_flow]
      dwhr_efficiency = args[:dwhr_efficiency]
    end

    if args[:dhw_distribution_system_type] == HPXML::DHWDistTypeStandard
      if args[:dhw_distribution_standard_piping_length] != Constants.Auto
        standard_piping_length = args[:dhw_distribution_standard_piping_length]
      end
    else
      recirculation_control_type = args[:dhw_distribution_recirc_control_type]

      if args[:dhw_distribution_recirc_piping_length] != Constants.Auto
        recirculation_piping_length = args[:dhw_distribution_recirc_piping_length]
      end

      if args[:dhw_distribution_recirc_branch_piping_length] != Constants.Auto
        recirculation_branch_piping_length = args[:dhw_distribution_recirc_branch_piping_length]
      end

      if args[:dhw_distribution_recirc_pump_power] != Constants.Auto
        recirculation_pump_power = args[:dhw_distribution_recirc_pump_power]
      end
    end

    hpxml.hot_water_distributions.add(id: 'HotWaterDistribution',
                                      system_type: args[:dhw_distribution_system_type],
                                      standard_piping_length: standard_piping_length,
                                      recirculation_control_type: recirculation_control_type,
                                      recirculation_piping_length: recirculation_piping_length,
                                      recirculation_branch_piping_length: recirculation_branch_piping_length,
                                      recirculation_pump_power: recirculation_pump_power,
                                      pipe_r_value: args[:dhw_distribution_pipe_r],
                                      dwhr_facilities_connected: dwhr_facilities_connected,
                                      dwhr_equal_flow: dwhr_equal_flow,
                                      dwhr_efficiency: dwhr_efficiency)
  end

  def self.set_water_fixtures(hpxml, runer, args)
    return if args[:water_heater_type] == 'none'

    hpxml.water_fixtures.add(id: 'ShowerFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: args[:water_fixtures_shower_low_flow])

    hpxml.water_fixtures.add(id: 'SinkFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: args[:water_fixtures_sink_low_flow])

    if args[:water_fixtures_usage_multiplier] != 1.0
      hpxml.water_heating.water_fixtures_usage_multiplier = args[:water_fixtures_usage_multiplier]
    end
  end

  def self.get_absolute_tilt(tilt_str, roof_pitch, weather)
    tilt_str = tilt_str.downcase
    if tilt_str.start_with? 'roofpitch'
      roof_angle = Math.atan(roof_pitch / 12.0) * 180.0 / Math::PI
      return Float(eval(tilt_str.gsub('roofpitch', roof_angle.to_s)))
    elsif tilt_str.start_with? 'latitude'
      return Float(eval(tilt_str.gsub('latitude', weather.header.Latitude.to_s)))
    else
      return Float(tilt_str)
    end
  end

  def self.set_solar_thermal(hpxml, runner, args, weather)
    return if args[:solar_thermal_system_type] == 'none'

    if args[:solar_thermal_solar_fraction] > 0
      solar_fraction = args[:solar_thermal_solar_fraction]
    else
      collector_area = args[:solar_thermal_collector_area]
      collector_loop_type = args[:solar_thermal_collector_loop_type]
      collector_type = args[:solar_thermal_collector_type]
      collector_azimuth = args[:solar_thermal_collector_azimuth]
      collector_tilt = get_absolute_tilt(args[:solar_thermal_collector_tilt], hpxml.roofs[-1].pitch, weather)
      collector_frta = args[:solar_thermal_collector_rated_optical_efficiency]
      collector_frul = args[:solar_thermal_collector_rated_thermal_losses]

      if args[:solar_thermal_storage_volume] != Constants.Auto
        storage_volume = args[:solar_thermal_storage_volume]
      end
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

  def self.set_pv_systems(hpxml, runner, args, weather)
    args[:pv_system_module_type].each_with_index do |module_type, i|
      next if module_type == 'none'

      hpxml.pv_systems.add(id: "PVSystem#{i + 1}",
                           location: args[:pv_system_location][i],
                           module_type: module_type,
                           tracking: args[:pv_system_tracking][i],
                           array_azimuth: args[:pv_system_array_azimuth][i],
                           array_tilt: get_absolute_tilt(args[:pv_system_array_tilt][i], hpxml.roofs[-1].pitch, weather),
                           max_power_output: args[:pv_system_max_power_output][i],
                           inverter_efficiency: args[:pv_system_inverter_efficiency][i],
                           system_losses_fraction: args[:pv_system_system_losses_fraction][i])
    end
  end

  def self.set_lighting(hpxml, runner, args)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Interior',
                              location: HPXML::LocationInterior,
                              fration_of_units_in_location: 0.5, # FIXME
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Exterior',
                              location: HPXML::LocationExterior,
                              fration_of_units_in_location: 0.5, # FIXME
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Garage',
                              location: HPXML::LocationGarage,
                              fration_of_units_in_location: 0.5, # FIXME
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Interior',
                              location: HPXML::LocationInterior,
                              fration_of_units_in_location: 0.25, # FIXME
                              third_party_certification: HPXML::LightingTypeTierII)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Exterior',
                              location: HPXML::LocationExterior,
                              fration_of_units_in_location: 0.25, # FIXME
                              third_party_certification: HPXML::LightingTypeTierII)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Garage',
                              location: HPXML::LocationGarage,
                              fration_of_units_in_location: 0.25, # FIXME
                              third_party_certification: HPXML::LightingTypeTierII)
    if args[:lighting_usage_multiplier] != 1.0
      hpxml.lighting.usage_multiplier = args[:lighting_usage_multiplier]
    end
  end

  def self.set_dehumidifier(hpxml, runner, args)
    return unless args[:dehumidifier_present]

    if args[:dehumidifier_efficiency_type] == 'EnergyFactor'
      energy_factor = args[:dehumidifier_efficiency_ef]
    elsif args[:dehumidifier_efficiency_type] == 'IntegratedEnergyFactor'
      integrated_energy_factor = args[:dehumidifier_efficiency_ief]
    end

    hpxml.dehumidifiers.add(id: 'Dehumidifier',
                            capacity: args[:dehumidifier_capacity],
                            energy_factor: energy_factor,
                            integrated_energy_factor: integrated_energy_factor,
                            rh_setpoint: args[:dehumidifier_rh_setpoint],
                            fraction_served: args[:dehumidifier_fraction_dehumidification_load_served])
  end

  def self.set_clothes_washer(hpxml, runner, args)
    return unless args[:clothes_washer_present]

    if args[:clothes_washer_location] != Constants.Auto
      location = args[:clothes_washer_location]
    end

    if args[:clothes_washer_efficiency_type] == 'ModifiedEnergyFactor'
      modified_energy_factor = args[:clothes_washer_efficiency_mef]
    elsif args[:clothes_washer_efficiency_type] == 'IntegratedModifiedEnergyFactor'
      integrated_modified_energy_factor = args[:clothes_washer_efficiency_imef]
    end

    if args[:clothes_washer_usage_multiplier] != 1.0
      usage_multiplier = args[:clothes_washer_usage_multiplier]
    end

    hpxml.clothes_washers.add(id: 'ClothesWasher',
                              location: location,
                              modified_energy_factor: modified_energy_factor,
                              integrated_modified_energy_factor: integrated_modified_energy_factor,
                              rated_annual_kwh: args[:clothes_washer_rated_annual_kwh],
                              label_electric_rate: args[:clothes_washer_label_electric_rate],
                              label_gas_rate: args[:clothes_washer_label_gas_rate],
                              label_annual_gas_cost: args[:clothes_washer_label_annual_gas_cost],
                              label_usage: args[:clothes_washer_label_usage],
                              capacity: args[:clothes_washer_capacity],
                              usage_multiplier: usage_multiplier)
  end

  def self.set_clothes_dryer(hpxml, runner, args)
    return unless args[:clothes_dryer_present]

    if args[:clothes_dryer_efficiency_type] == 'EnergyFactor'
      energy_factor = args[:clothes_dryer_efficiency_ef]
    elsif args[:clothes_dryer_efficiency_type] == 'CombinedEnergyFactor'
      combined_energy_factor = args[:clothes_dryer_efficiency_cef]
    end

    if args[:clothes_dryer_location] != Constants.Auto
      location = args[:clothes_dryer_location]
    end

    if args[:clothes_dryer_usage_multiplier] != 1.0
      usage_multiplier = args[:clothes_dryer_usage_multiplier]
    end

    hpxml.clothes_dryers.add(id: 'ClothesDryer',
                             location: location,
                             fuel_type: args[:clothes_dryer_fuel_type],
                             energy_factor: energy_factor,
                             combined_energy_factor: combined_energy_factor,
                             control_type: args[:clothes_dryer_control_type],
                             usage_multiplier: usage_multiplier)
  end

  def self.set_dishwasher(hpxml, runner, args)
    return unless args[:dishwasher_present]

    if args[:dishwasher_efficiency_type] == 'RatedAnnualkWh'
      rated_annual_kwh = args[:dishwasher_efficiency_kwh]
    elsif args[:dishwasher_efficiency_type] == 'EnergyFactor'
      energy_factor = args[:dishwasher_efficiency_ef]
    end

    if args[:dishwasher_usage_multiplier] != 1.0
      usage_multiplier = args[:dishwasher_usage_multiplier]
    end

    hpxml.dishwashers.add(id: 'Dishwasher',
                          rated_annual_kwh: rated_annual_kwh,
                          energy_factor: energy_factor,
                          label_electric_rate: args[:dishwasher_label_electric_rate],
                          label_gas_rate: args[:dishwasher_label_gas_rate],
                          label_annual_gas_cost: args[:dishwasher_label_annual_gas_cost],
                          label_usage: args[:dishwasher_label_usage],
                          place_setting_capacity: args[:dishwasher_place_setting_capacity],
                          usage_multiplier: usage_multiplier)
  end

  def self.set_refrigerator(hpxml, runner, args)
    return unless args[:refrigerator_present]

    if args[:refrigerator_location] != Constants.Auto
      location = args[:refrigerator_location]
    end

    if args[:refrigerator_usage_multiplier] != 1.0
      usage_multiplier = args[:refrigerator_usage_multiplier]
    end

    hpxml.refrigerators.add(id: 'Refrigerator',
                            location: location,
                            rated_annual_kwh: args[:refrigerator_rated_annual_kwh],
                            usage_multiplier: usage_multiplier,
                            schedules_output_path: args[:schedules_output_path],
                            schedules_column_name: 'refrigerator')
  end

  def self.set_cooking_range_oven(hpxml, runner, args)
    return unless args[:cooking_range_oven_present]

    if args[:cooking_range_oven_usage_multiplier] != 1.0
      usage_multiplier = args[:cooking_range_oven_usage_multiplier]
    end

    hpxml.cooking_ranges.add(id: 'CookingRange',
                             fuel_type: args[:cooking_range_oven_fuel_type],
                             is_induction: args[:cooking_range_oven_is_induction],
                             usage_multiplier: usage_multiplier)
    hpxml.ovens.add(id: 'Oven',
                    is_convection: args[:cooking_range_oven_is_convection])
  end

  def self.set_ceiling_fans(hpxml, runner, args)
    return if args[:ceiling_fan_quantity] == 0

    hpxml.ceiling_fans.add(id: 'CeilingFan',
                           efficiency: args[:ceiling_fan_efficiency],
                           quantity: args[:ceiling_fan_quantity])
  end

  def self.set_plug_loads(hpxml, runner, args)
    if args[:plug_loads_other_annual_kwh] != Constants.Auto
      plug_loads_other_annual_kwh = args[:plug_loads_other_annual_kwh]
    end

    if args[:plug_loads_television_annual_kwh] != Constants.Auto
      plug_loads_television_annual_kwh = args[:plug_loads_television_annual_kwh]
    end

    if args[:plug_loads_usage_multiplier] != 1.0
      usage_multiplier = args[:plug_loads_usage_multiplier]
    end

    hpxml.plug_loads.add(id: 'PlugLoadsOther',
                         plug_load_type: HPXML::PlugLoadTypeOther,
                         kWh_per_year: plug_loads_other_annual_kwh,
                         frac_sensible: args[:plug_loads_other_frac_sensible],
                         frac_latent: args[:plug_loads_other_frac_latent],
                         usage_multiplier: usage_multiplier)

    hpxml.plug_loads.add(id: 'PlugLoadsTelevision',
                         plug_load_type: HPXML::PlugLoadTypeTelevision,
                         kWh_per_year: plug_loads_television_annual_kwh,
                         frac_sensible: 1.0,
                         frac_latent: 0.0,
                         usage_multiplier: usage_multiplier)
  end

  def self.set_misc_loads_schedule(hpxml, runner, args)
    return unless args[:plug_loads_schedule_values]

    hpxml.misc_loads_schedule.weekday_fractions = args[:plug_loads_weekday_fractions]
    hpxml.misc_loads_schedule.weekend_fractions = args[:plug_loads_weekend_fractions]
    hpxml.misc_loads_schedule.monthly_multipliers = args[:plug_loads_monthly_multipliers]
  end
end

# register the measure to be used by the application
BuildResidentialHPXML.new.registerWithApplication
