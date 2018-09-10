# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/schedules"

# start the measure
class CreateResidentialMultifamilyGeometry < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Create Residential Multifamily Geometry"
  end

  # human readable description
  def description
    return "Sets the basic geometry for the multifamily building, where all units are 1 story and stacked if the building is multiple stories. Sets the number of bedrooms, bathrooms, and occupants in the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Creates multifamily geometry. Also, sets (or replaces) BuildingUnit objects that store the number of bedrooms and bathrooms associated with the model. Sets (or replaces) the People object for each finished space in the model."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for unit living space floor area
    unit_ffa = OpenStudio::Measure::OSArgument::makeDoubleArgument("unit_ffa",true)
    unit_ffa.setDisplayName("Unit Finished Floor Area")
    unit_ffa.setUnits("ft^2")
    unit_ffa.setDescription("Unit floor area of the finished space (including any finished basement floor area).")
    unit_ffa.setDefaultValue(900.0)
    args << unit_ffa

    #make an argument for living space height
    wall_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_height",true)
    wall_height.setDisplayName("Wall Height (Per Floor)")
    wall_height.setUnits("ft")
    wall_height.setDescription("The height of the living space walls.")
    wall_height.setDefaultValue(8.0)
    args << wall_height

    #make an argument for total number of floors
    num_floors = OpenStudio::Measure::OSArgument::makeIntegerArgument("num_floors",true)
    num_floors.setDisplayName("Building Number of Floors")
    num_floors.setUnits("#")
    num_floors.setDescription("The number of floors above grade.")
    num_floors.setDefaultValue(1)
    args << num_floors

    #make an argument for number of units per floor
    num_units_per_floor = OpenStudio::Measure::OSArgument::makeIntegerArgument("num_units_per_floor",true)
    num_units_per_floor.setDisplayName("Num Units Per Floor")
    num_units_per_floor.setUnits("#")
    num_units_per_floor.setDescription("The number of units per floor.")
    num_units_per_floor.setDefaultValue(2)
    args << num_units_per_floor

    #make an argument for unit aspect ratio
    unit_aspect_ratio = OpenStudio::Measure::OSArgument::makeDoubleArgument("unit_aspect_ratio",true)
    unit_aspect_ratio.setDisplayName("Unit Aspect Ratio")
    unit_aspect_ratio.setUnits("FB/LR")
    unit_aspect_ratio.setDescription("The ratio of the front/back wall length to the left/right wall length.")
    unit_aspect_ratio.setDefaultValue(2.0)
    args << unit_aspect_ratio

    #make an argument for corridor position
    corridor_position_display_names = OpenStudio::StringVector.new
    corridor_position_display_names << "Double-Loaded Interior"
    corridor_position_display_names << "Single Exterior (Front)"
    corridor_position_display_names << "Double Exterior"
    corridor_position_display_names << "None"

    corridor_position = OpenStudio::Measure::OSArgument::makeChoiceArgument("corridor_position", corridor_position_display_names, true)
    corridor_position.setDisplayName("Corridor Position")
    corridor_position.setDescription("The position of the corridor.")
    corridor_position.setDefaultValue("Double-Loaded Interior")
    args << corridor_position

    #make an argument for corridor width
    corridor_width = OpenStudio::Measure::OSArgument::makeDoubleArgument("corridor_width", true)
    corridor_width.setDisplayName("Corridor Width")
    corridor_width.setUnits("ft")
    corridor_width.setDescription("The width of the corridor.")
    corridor_width.setDefaultValue(10.0)
    args << corridor_width

    #make an argument for inset width
    inset_width = OpenStudio::Measure::OSArgument::makeDoubleArgument("inset_width", true)
    inset_width.setDisplayName("Inset Width")
    inset_width.setUnits("ft")
    inset_width.setDescription("The width of the inset.")
    inset_width.setDefaultValue(0.0)
    args << inset_width

    #make an argument for inset depth
    inset_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("inset_depth", true)
    inset_depth.setDisplayName("Inset Depth")
    inset_depth.setUnits("ft")
    inset_depth.setDescription("The depth of the inset.")
    inset_depth.setDefaultValue(0.0)
    args << inset_depth

    #make an argument for inset position
    inset_position_display_names = OpenStudio::StringVector.new
    inset_position_display_names << "Right"
    inset_position_display_names << "Left"

    inset_position = OpenStudio::Measure::OSArgument::makeChoiceArgument("inset_position", inset_position_display_names, true)
    inset_position.setDisplayName("Inset Position")
    inset_position.setDescription("The position of the inset.")
    inset_position.setDefaultValue("Right")
    args << inset_position

    #make an argument for balcony depth
    balcony_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("balcony_depth", true)
    balcony_depth.setDisplayName("Balcony Depth")
    balcony_depth.setUnits("ft")
    balcony_depth.setDescription("The depth of the balcony.")
    balcony_depth.setDefaultValue(0.0)
    args << balcony_depth

    #make a choice argument for model objects
    foundation_display_names = OpenStudio::StringVector.new
    foundation_display_names << "slab"
    foundation_display_names << "crawlspace"
    foundation_display_names << "unfinished basement"

    #make a choice argument for foundation type
    foundation_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("foundation_type", foundation_display_names, true)
    foundation_type.setDisplayName("Foundation Type")
    foundation_type.setDescription("The foundation type of the building.")
    foundation_type.setDefaultValue("slab")
    args << foundation_type

    #make an argument for crawlspace height
    foundation_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("foundation_height",true)
    foundation_height.setDisplayName("Foundation Height")
    foundation_height.setUnits("ft")
    foundation_height.setDescription("The height of the foundation (e.g., 3ft for crawlspace, 8ft for basement).")
    foundation_height.setDefaultValue(3.0)
    args << foundation_height

    #make a choice argument for eaves depth
    eaves_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("eaves_depth", true)
    eaves_depth.setDisplayName("Eaves Depth")
    eaves_depth.setUnits("ft")
    eaves_depth.setDescription("The eaves depth of the roof.")
    eaves_depth.setDefaultValue(2.0)
    args << eaves_depth

    #TODO: Needs more testing
    #make an argument for using zone multipliers
    #use_zone_mult = OpenStudio::Measure::OSArgument::makeBoolArgument("use_zone_mult", true)
    #use_zone_mult.setDisplayName("Use Zone Multipliers?")
    #use_zone_mult.setDescription("Model only one interior unit per floor with its thermal zone multiplier equal to the number of interior units per floor.")
    #use_zone_mult.setDefaultValue(false)
    #args << use_zone_mult

    #TODO: Needs more testing
    #make an argument for using floor multipliers
    #use_floor_mult = OpenStudio::Measure::OSArgument::makeBoolArgument("use_floor_mult", true)
    #use_floor_mult.setDisplayName("Use Floor Multipliers?")
    #use_floor_mult.setDescription("Model only one interior floor with thermal zone multipliers equal to the number of interior floors.")
    #use_floor_mult.setDefaultValue(false)
    #args << use_floor_mult

    #make a string argument for number of bedrooms
    num_br = OpenStudio::Measure::OSArgument::makeStringArgument("num_bedrooms", false)
    num_br.setDisplayName("Number of Bedrooms")
    num_br.setDescription("Specify the number of bedrooms. Used to determine the energy usage of appliances and plug loads, hot water usage, mechanical ventilation rate, etc.")
    num_br.setDefaultValue("3")
    args << num_br

    #make a string argument for number of bathrooms
    num_ba = OpenStudio::Measure::OSArgument::makeStringArgument("num_bathrooms", false)
    num_ba.setDisplayName("Number of Bathrooms")
    num_ba.setDescription("Specify the number of bathrooms. Used to determine the hot water usage, etc.")
    num_ba.setDefaultValue("2")
    args << num_ba

    #Make a string argument for occupants (auto or number)
    num_occupants = OpenStudio::Measure::OSArgument::makeStringArgument("num_occupants", true)
    num_occupants.setDisplayName("Number of Occupants")
    num_occupants.setDescription("Specify the number of occupants. A value of '#{Constants.Auto}' will calculate the average number of occupants from the number of bedrooms. Used to specify the internal gains from people only.")
    num_occupants.setDefaultValue(Constants.Auto)
    args << num_occupants

    #Make a string argument for 24 weekday schedule values
    occupants_weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("occupants_weekday_sch", true)
    occupants_weekday_sch.setDisplayName("Occupants Weekday schedule")
    occupants_weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    occupants_weekday_sch.setDefaultValue("1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.88, 0.41, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.29, 0.55, 0.90, 0.90, 0.90, 1.00, 1.00, 1.00")
    args << occupants_weekday_sch

    #Make a string argument for 24 weekend schedule values
    occupants_weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("occupants_weekend_sch", true)
    occupants_weekend_sch.setDisplayName("Occupants Weekend schedule")
    occupants_weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    occupants_weekend_sch.setDefaultValue("1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.88, 0.41, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.29, 0.55, 0.90, 0.90, 0.90, 1.00, 1.00, 1.00")
    args << occupants_weekend_sch

    #Make a string argument for 12 monthly schedule values
    occupants_monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("occupants_monthly_sch", true)
    occupants_monthly_sch.setDisplayName("Occupants Month schedule")
    occupants_monthly_sch.setDescription("Specify the 12-month schedule.")
    occupants_monthly_sch.setDefaultValue("1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0")
    args << occupants_monthly_sch

    #make a double argument for left neighbor offset
    left_neighbor_offset = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_left_offset", false)
    left_neighbor_offset.setDisplayName("Neighbor Left Offset")
    left_neighbor_offset.setUnits("ft")
    left_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the left (not including eaves). A value of zero indicates no neighbors.")
    left_neighbor_offset.setDefaultValue(10.0)
    args << left_neighbor_offset

    #make a double argument for right neighbor offset
    right_neighbor_offset = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_right_offset", false)
    right_neighbor_offset.setDisplayName("Neighbor Right Offset")
    right_neighbor_offset.setUnits("ft")
    right_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the right (not including eaves). A value of zero indicates no neighbors.")
    right_neighbor_offset.setDefaultValue(10.0)
    args << right_neighbor_offset

    #make a double argument for back neighbor offset
    back_neighbor_offset = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_back_offset", false)
    back_neighbor_offset.setDisplayName("Neighbor Back Offset")
    back_neighbor_offset.setUnits("ft")
    back_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the back (not including eaves). A value of zero indicates no neighbors.")
    back_neighbor_offset.setDefaultValue(0.0)
    args << back_neighbor_offset

    #make a double argument for front neighbor offset
    front_neighbor_offset = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_front_offset", false)
    front_neighbor_offset.setDisplayName("Neighbor Front Offset")
    front_neighbor_offset.setUnits("ft")
    front_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the front (not including eaves). A value of zero indicates no neighbors.")
    front_neighbor_offset.setDefaultValue(0.0)
    args << front_neighbor_offset

    #make a double argument for orientation
    orientation = OpenStudio::Measure::OSArgument::makeDoubleArgument("orientation", true)
    orientation.setDisplayName("Azimuth")
    orientation.setUnits("degrees")
    orientation.setDescription("The house's azimuth is measured clockwise from due south when viewed from above (e.g., South=0, West=90, North=180, East=270).")
    orientation.setDefaultValue(180.0)
    args << orientation

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    model_spaces = model.getSpaces

    unit_ffa = UnitConversions.convert(runner.getDoubleArgumentValue("unit_ffa",user_arguments),"ft^2","m^2")
    wall_height = UnitConversions.convert(runner.getDoubleArgumentValue("wall_height",user_arguments),"ft","m")
    num_floors = runner.getIntegerArgumentValue("num_floors",user_arguments)
    num_units_per_floor = runner.getIntegerArgumentValue("num_units_per_floor",user_arguments)
    unit_aspect_ratio = runner.getDoubleArgumentValue("unit_aspect_ratio",user_arguments)
    corridor_position = runner.getStringArgumentValue("corridor_position",user_arguments)
    corridor_width = UnitConversions.convert(runner.getDoubleArgumentValue("corridor_width",user_arguments),"ft","m")
    inset_width = UnitConversions.convert(runner.getDoubleArgumentValue("inset_width",user_arguments),"ft","m")
    inset_depth = UnitConversions.convert(runner.getDoubleArgumentValue("inset_depth",user_arguments),"ft","m")
    inset_position = runner.getStringArgumentValue("inset_position",user_arguments)
    balcony_depth = UnitConversions.convert(runner.getDoubleArgumentValue("balcony_depth",user_arguments),"ft","m")
    foundation_type = runner.getStringArgumentValue("foundation_type",user_arguments)
    foundation_height = runner.getDoubleArgumentValue("foundation_height",user_arguments)
    eaves_depth = UnitConversions.convert(runner.getDoubleArgumentValue("eaves_depth",user_arguments),"ft","m")
    use_zone_mult = false #runner.getBoolArgumentValue("use_zone_mult",user_arguments)
    use_floor_mult = false #runner.getBoolArgumentValue("use_floor_mult",user_arguments)
    num_br = runner.getStringArgumentValue("num_bedrooms", user_arguments).split(",").map(&:strip)
    num_ba = runner.getStringArgumentValue("num_bathrooms", user_arguments).split(",").map(&:strip)
    num_occupants = runner.getStringArgumentValue("num_occupants",user_arguments)
    occupants_weekday_sch = runner.getStringArgumentValue("occupants_weekday_sch",user_arguments)
    occupants_weekend_sch = runner.getStringArgumentValue("occupants_weekend_sch",user_arguments)
    occupants_monthly_sch = runner.getStringArgumentValue("occupants_monthly_sch",user_arguments)
    left_neighbor_offset = UnitConversions.convert(runner.getDoubleArgumentValue("neighbor_left_offset",user_arguments),"ft","m")
    right_neighbor_offset = UnitConversions.convert(runner.getDoubleArgumentValue("neighbor_right_offset",user_arguments),"ft","m")
    back_neighbor_offset = UnitConversions.convert(runner.getDoubleArgumentValue("neighbor_back_offset",user_arguments),"ft","m")
    front_neighbor_offset = UnitConversions.convert(runner.getDoubleArgumentValue("neighbor_front_offset",user_arguments),"ft","m")
    orientation = runner.getDoubleArgumentValue("orientation",user_arguments)

    if foundation_type == "slab"
      foundation_height = 0.0
    end
    num_units_per_floor_actual = num_units_per_floor

    # error checking
    if model_spaces.size > 0
      runner.registerError("Starting model is not empty.")
      return false
    end
    if num_units_per_floor == 1 and (corridor_position == "Double-Loaded Interior" or corridor_position == "Double Exterior")
      runner.registerError("Specified building as having rear units, but didn't specify enough units.")
      return false
    end
    if unit_aspect_ratio < 0
      runner.registerError("Invalid aspect ratio entered.")
      return false
    end
    if corridor_width == 0 and corridor_position != "None"
      corridor_position = "None"
    end
    if corridor_position == "None"
      corridor_width = 0
    end
    if corridor_width < 0
      runner.registerError("Invalid corridor width entered.")
      return false
    end
    if corridor_position == "Double-Loaded Interior" and num_units_per_floor % 2 != 0
      runner.registerWarning("Specified a double-loaded corridor and an odd number of units per floor. Subtracting one unit per floor.")
      num_units_per_floor -= 1
    end
    if balcony_depth > 0 and inset_width * inset_depth == 0
      runner.registerWarning("Specified a balcony, but there is no inset.")
      balcony_depth = 0
    end

    # Convert to SI
    foundation_height = UnitConversions.convert(foundation_height,"ft","m")

    space_types_hash = {}

    num_units = num_units_per_floor * num_floors

    # starting spaces
    runner.registerInitialCondition("The building started with #{model_spaces.size} spaces.")

    # calculate the dimensions of the unit
    footprint = unit_ffa + inset_width * inset_depth
    x = Math.sqrt(footprint / unit_aspect_ratio)
    y = footprint / x

    foundation_corr_polygon = nil
    foundation_front_polygon = nil
    foundation_back_polygon = nil

    # create the front prototype unit
    nw_point = OpenStudio::Point3d.new(0, 0, 0)
    ne_point = OpenStudio::Point3d.new(x, 0, 0)
    sw_point = OpenStudio::Point3d.new(0, -y, 0)
    se_point = OpenStudio::Point3d.new(x, -y, 0)
    if inset_width * inset_depth > 0
      if inset_position == "Right"
        # unit footprint
        inset_point = OpenStudio::Point3d.new(x - inset_width, inset_depth - y, 0)
        front_point = OpenStudio::Point3d.new(x - inset_width, -y, 0)
        side_point = OpenStudio::Point3d.new(x, inset_depth - y, 0)
        living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, side_point, inset_point, front_point)
        # unit balcony
        if balcony_depth > 0
          inset_point = OpenStudio::Point3d.new(x - inset_width, inset_depth - y, wall_height)
          side_point = OpenStudio::Point3d.new(x, inset_depth - y, wall_height)
          se_point = OpenStudio::Point3d.new(x, inset_depth - y - balcony_depth, wall_height)
          front_point = OpenStudio::Point3d.new(x - inset_width, inset_depth - y - balcony_depth, wall_height)
          shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([front_point, se_point, side_point, inset_point]), model)
        end
      else
        # unit footprint
        inset_point = OpenStudio::Point3d.new(inset_width, inset_depth - y, 0)
        front_point = OpenStudio::Point3d.new(inset_width, -y, 0)
        side_point = OpenStudio::Point3d.new(0, inset_depth - y, 0)
        living_polygon = Geometry.make_polygon(side_point, nw_point, ne_point, se_point, front_point, inset_point)
        # unit balcony
        if balcony_depth > 0
          inset_point = OpenStudio::Point3d.new(inset_width, inset_depth - y, wall_height)
          side_point = OpenStudio::Point3d.new(0, inset_depth - y, wall_height)
          sw_point = OpenStudio::Point3d.new(0, inset_depth - y - balcony_depth, wall_height)
          front_point = OpenStudio::Point3d.new(inset_width, inset_depth - y - balcony_depth, wall_height)
          shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([front_point, sw_point, side_point, inset_point]), model)
        end
      end
    else
      living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
    end

    # foundation
    if foundation_height > 0 and foundation_front_polygon.nil?
      foundation_front_polygon = living_polygon
    end

    # create living zone
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    living_zone.setName("living zone")

    # first floor front
    living_spaces_front = []
    living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, wall_height, model)
    living_space = living_space.get
    living_space.setName("living space")
    if space_types_hash.keys.include? Constants.SpaceTypeLiving
      living_space_type = space_types_hash[Constants.SpaceTypeLiving]
    else
      living_space_type = OpenStudio::Model::SpaceType.new(model)
      living_space_type.setStandardsSpaceType(Constants.SpaceTypeLiving)
      space_types_hash[Constants.SpaceTypeLiving] = living_space_type
    end
    living_space.setSpaceType(living_space_type)
    living_space.setThermalZone(living_zone)

    # add the balcony
    if balcony_depth > 0
      shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
      shading_surface_group.setSpace(living_space)
      shading_surface.setShadingSurfaceGroup(shading_surface_group)
    end

    living_spaces_front << living_space

    # create the unit
    unit_spaces_hash = {}
    unit_spaces_hash[1] = living_spaces_front

    has_rear_units = false

    # create back units
    if corridor_position == "Double-Loaded Interior" or corridor_position == "Double Exterior" # units in front and back

      has_rear_units = true

      if corridor_position == "Double-Loaded Interior"
        interior_corridor_width = corridor_width
      else
        interior_corridor_width = 0
      end

      # create the back prototype unit
      nw_point = OpenStudio::Point3d.new(0, y + interior_corridor_width, 0)
      ne_point = OpenStudio::Point3d.new(x, y + interior_corridor_width, 0)
      sw_point = OpenStudio::Point3d.new(0, interior_corridor_width, 0)
      se_point = OpenStudio::Point3d.new(x, interior_corridor_width, 0)
      if inset_width * inset_depth > 0
        if inset_position == "Left"
          # unit footprint
          inset_point = OpenStudio::Point3d.new(x - inset_width, y - inset_depth + interior_corridor_width, 0)
          front_point = OpenStudio::Point3d.new(x - inset_width, y + interior_corridor_width, 0)
          side_point = OpenStudio::Point3d.new(x, y - inset_depth + interior_corridor_width, 0)
          living_polygon = Geometry.make_polygon(sw_point, nw_point, front_point, inset_point, side_point, se_point)
          # unit balcony
          if balcony_depth > 0
            inset_point = OpenStudio::Point3d.new(x - inset_width, y - inset_depth + interior_corridor_width, wall_height)
            side_point = OpenStudio::Point3d.new(x, y - inset_depth + interior_corridor_width, wall_height)
            ne_point = OpenStudio::Point3d.new(x, y - inset_depth + balcony_depth + interior_corridor_width, wall_height)
            front_point = OpenStudio::Point3d.new(x - inset_width, y - inset_depth + balcony_depth + interior_corridor_width, wall_height)
            shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([side_point, ne_point, front_point, inset_point]), model)
          end
        else
          # unit footprint
          inset_point = OpenStudio::Point3d.new(inset_width, y - inset_depth + interior_corridor_width, 0)
          front_point = OpenStudio::Point3d.new(inset_width, y + interior_corridor_width, 0)
          side_point = OpenStudio::Point3d.new(0, y - inset_depth + interior_corridor_width, 0)
          living_polygon = Geometry.make_polygon(side_point, inset_point, front_point, ne_point, se_point, sw_point)
          # unit balcony
          if balcony_depth > 0
            inset_point = OpenStudio::Point3d.new(inset_width, y - inset_depth + interior_corridor_width, wall_height)
            side_point = OpenStudio::Point3d.new(0, y - inset_depth + interior_corridor_width, wall_height)
            nw_point = OpenStudio::Point3d.new(0, y - inset_depth + balcony_depth + interior_corridor_width, wall_height)
            front_point = OpenStudio::Point3d.new(inset_width, y - inset_depth + balcony_depth + interior_corridor_width, wall_height)
            shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([side_point, nw_point, front_point, inset_point]), model)
          end
        end
      else
        living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
      end

      # foundation
      if foundation_height > 0 and foundation_back_polygon.nil?
        foundation_back_polygon = living_polygon
      end

      # create living zone
      living_zone = OpenStudio::Model::ThermalZone.new(model)
      living_zone.setName("living zone|#{Constants.ObjectNameBuildingUnit(2)}")

      # first floor back
      living_spaces_back = []
      living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, wall_height, model)
      living_space = living_space.get
      living_space.setName("living space|#{Constants.ObjectNameBuildingUnit(2)}")
      if space_types_hash.keys.include? Constants.SpaceTypeLiving
        living_space_type = space_types_hash[Constants.SpaceTypeLiving]
      else
        living_space_type = OpenStudio::Model::SpaceType.new(model)
        living_space_type.setStandardsSpaceType(Constants.SpaceTypeLiving)
        space_types_hash[Constants.SpaceTypeLiving] = living_space_type
      end
      living_space.setSpaceType(living_space_type)
      living_space.setThermalZone(living_zone)

      # add the balcony
      if balcony_depth > 0
        shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
        shading_surface_group.setSpace(living_space)
        shading_surface.setShadingSurfaceGroup(shading_surface_group)
      end

      living_spaces_back << living_space

      # create the back unit
      unit_spaces_hash[2] = living_spaces_back

      floor = 0
      pos = 0
      front_unit = true
      (3..num_units).to_a.each do |unit_num|

        if not num_units_per_floor > 2 and unit_num == 3
          pos = -1
          floor = wall_height
        end

        # front or back unit
        if front_unit
          living_spaces = living_spaces_front
          pos += 1
          front_unit = false
        else
          living_spaces = living_spaces_back
          front_unit = true
        end

        living_zone = OpenStudio::Model::ThermalZone.new(model)
        living_zone.setName("living zone|#{Constants.ObjectNameBuildingUnit(unit_num)}")

        new_living_spaces = []
        living_spaces.each_with_index do |living_space, story|

          new_living_space = living_space.clone.to_Space.get
          new_living_space.setName("living space|#{Constants.ObjectNameBuildingUnit(unit_num)}|story #{story+1}")
          new_living_space.setSpaceType(living_space_type)

          m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m[0,3] = -pos * x
          m[2,3] = -floor
          new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
          new_living_space.setXOrigin(0)
          new_living_space.setYOrigin(0)
          new_living_space.setZOrigin(0)
          new_living_space.setThermalZone(living_zone)

          new_living_spaces << new_living_space

        end

        unit_spaces_hash[unit_num] = new_living_spaces

        if unit_num % num_units_per_floor == 0

          # which floor
          floor += wall_height
          pos = -1
          front_unit = true

        end

      end

      # corridors
      if corridor_width > 0

        if corridor_position == "Double-Loaded Interior"

          # create the prototype corridor
          nw_point = OpenStudio::Point3d.new(0, interior_corridor_width, 0)
          ne_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), interior_corridor_width, 0)
          sw_point = OpenStudio::Point3d.new(0, 0, 0)
          se_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), 0, 0)
          corr_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)

          if foundation_height > 0 and foundation_corr_polygon.nil?
            foundation_corr_polygon = corr_polygon
          end

          # create corridor zone
          corridor_zone = OpenStudio::Model::ThermalZone.new(model)
          corridor_zone.setName("corridor zone")

          # first floor corridor
          corridor_space = OpenStudio::Model::Space::fromFloorPrint(corr_polygon, wall_height, model)
          corridor_space = corridor_space.get
          corridor_space_name = "corridor space"
          corridor_space.setName(corridor_space_name)
          if space_types_hash.keys.include? Constants.SpaceTypeCorridor
            corridor_space_type = space_types_hash[Constants.SpaceTypeCorridor]
          else
            corridor_space_type = OpenStudio::Model::SpaceType.new(model)
            corridor_space_type.setStandardsSpaceType(Constants.SpaceTypeCorridor)
            space_types_hash[Constants.SpaceTypeCorridor] = corridor_space_type
          end
          corridor_space.setSpaceType(corridor_space_type)
          corridor_space.setThermalZone(corridor_zone)

          (1...num_floors).to_a.each do |floor|

            new_corridor_space = corridor_space.clone.to_Space.get
            m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
            m[2,3] = -floor * wall_height
            new_corridor_space.changeTransformation(OpenStudio::Transformation.new(m))
            new_corridor_space.setZOrigin(0)
            new_corridor_space.setThermalZone(corridor_zone)
            corridor_space_name = "corridor space|story #{floor+1}"
            new_corridor_space.setName(corridor_space_name)
            corridor_space.setSpaceType(corridor_space_type)

          end

        else

          # front access
          (1..num_floors).to_a.each do |floor|

            nw_point = OpenStudio::Point3d.new(0, -y, floor * wall_height)
            sw_point = OpenStudio::Point3d.new(0, -y - corridor_width, floor * wall_height)
            ne_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), -y, floor * wall_height)
            se_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), -y - corridor_width, floor * wall_height)
            if num_units_per_floor_actual % 2 != 0
              ne_point = OpenStudio::Point3d.new(x * ((num_units_per_floor + 1) / 2), -y, floor * wall_height)
              se_point = OpenStudio::Point3d.new(x * ((num_units_per_floor + 1) / 2), -y - corridor_width, floor * wall_height)
            end

            shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([sw_point, se_point, ne_point, nw_point]), model)

            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

          end

          # rear access
          (1..num_floors).to_a.each do |floor|

            nw_point = OpenStudio::Point3d.new(0, y + corridor_width, floor * wall_height)
            sw_point = OpenStudio::Point3d.new(0, y, floor * wall_height)
            ne_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), y + corridor_width, floor * wall_height)
            se_point = OpenStudio::Point3d.new(x * (num_units_per_floor / 2), y, floor * wall_height)

            shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([sw_point, se_point, ne_point, nw_point]), model)

            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

          end

        end

      end

    else # units only in front

      floor = 0
      pos = 0
      (2..num_units).to_a.each do |unit_num|

        if not num_units_per_floor > 1 and unit_num == 2
          pos = -1
          floor = wall_height
        end

        living_spaces = living_spaces_front
        pos += 1

        living_zone = OpenStudio::Model::ThermalZone.new(model)
        living_zone.setName("living zone|#{Constants.ObjectNameBuildingUnit(unit_num)}")

        new_living_spaces = []
        living_spaces.each_with_index do |living_space, story|

          new_living_space = living_space.clone.to_Space.get
          new_living_space.setName("living space|#{Constants.ObjectNameBuildingUnit(unit_num)}|story #{story+1}")
          new_living_space.setSpaceType(living_space_type)

          m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m[0,3] = -pos * x
          m[2,3] = -floor
          new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
          new_living_space.setXOrigin(0)
          new_living_space.setYOrigin(0)
          new_living_space.setZOrigin(0)
          new_living_space.setThermalZone(living_zone)

          new_living_spaces << new_living_space

        end

        unit_spaces_hash[unit_num] = new_living_spaces

        if unit_num % num_units_per_floor == 0

          # which floor
          floor += wall_height
          pos = -1

        end

      end

      if corridor_width > 0

        (1..num_floors).to_a.each do |floor|

          nw_point = OpenStudio::Point3d.new(0, -y, floor * wall_height)
          ne_point = OpenStudio::Point3d.new(x * num_units_per_floor, -y, floor * wall_height)
          sw_point = OpenStudio::Point3d.new(0, -y - corridor_width, floor * wall_height)
          se_point = OpenStudio::Point3d.new(x * num_units_per_floor, -y - corridor_width, floor * wall_height)

          shading_surface = OpenStudio::Model::ShadingSurface.new(OpenStudio::Point3dVector.new([sw_point, se_point, ne_point, nw_point]), model)

          shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
          shading_surface.setShadingSurfaceGroup(shading_surface_group)

        end

      end

    end

    # foundation
    if foundation_height > 0

      foundation_spaces = []

      # foundation corridor
      if corridor_width > 0 and corridor_position == "Double-Loaded Interior"
        corridor_space = OpenStudio::Model::Space::fromFloorPrint(foundation_corr_polygon, foundation_height, model)
        corridor_space = corridor_space.get
        m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
        m[2,3] = foundation_height
        corridor_space.changeTransformation(OpenStudio::Transformation.new(m))
        corridor_space.setXOrigin(0)
        corridor_space.setYOrigin(0)
        corridor_space.setZOrigin(0)

        foundation_spaces << corridor_space
      end

      # foundation front
      foundation_space_front = []
      foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_front_polygon, foundation_height, model)
      foundation_space = foundation_space.get
      m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
      m[2,3] = foundation_height
      foundation_space.changeTransformation(OpenStudio::Transformation.new(m))
      foundation_space.setXOrigin(0)
      foundation_space.setYOrigin(0)
      foundation_space.setZOrigin(0)

      foundation_space_front << foundation_space
      foundation_spaces << foundation_space

      if corridor_position == "Double-Loaded Interior" or corridor_position == "Double Exterior" # units in front and back

        # foundation back
        foundation_space_back = []
        foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_back_polygon, foundation_height, model)
        foundation_space = foundation_space.get
        m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
        m[2,3] = foundation_height
        foundation_space.changeTransformation(OpenStudio::Transformation.new(m))
        foundation_space.setXOrigin(0)
        foundation_space.setYOrigin(0)
        foundation_space.setZOrigin(0)

        foundation_space_back << foundation_space
        foundation_spaces << foundation_space

        pos = 0
        (3..num_units_per_floor).to_a.each do |unit_num|

          # front or back unit
          if unit_num % 2 != 0 # odd unit number
            living_spaces = foundation_space_front
            pos += 1
          else # even unit number
            living_spaces = foundation_space_back
          end

          living_spaces.each do |living_space|

            new_living_space = living_space.clone.to_Space.get

            m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
            m[0,3] = -pos * x
            new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
            new_living_space.setXOrigin(0)
            new_living_space.setYOrigin(0)
            new_living_space.setZOrigin(0)

            foundation_spaces << new_living_space

          end

        end

      else # units only in front

        pos = 0
        (2..num_units_per_floor).to_a.each do |unit_num|

          living_spaces = foundation_space_front
          pos += 1

          living_spaces.each do |living_space|

            new_living_space = living_space.clone.to_Space.get

            m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
            m[0,3] = -pos * x
            new_living_space.changeTransformation(OpenStudio::Transformation.new(m))
            new_living_space.setXOrigin(0)
            new_living_space.setYOrigin(0)
            new_living_space.setZOrigin(0)

            foundation_spaces << new_living_space

          end

        end

      end

      # put all of the spaces in the model into a vector
      spaces = OpenStudio::Model::SpaceVector.new
      model.getSpaces.each do |space|
        spaces << space
      end

      # intersect and match surfaces for each space in the vector
      OpenStudio::Model.intersectSurfaces(spaces)
      OpenStudio::Model.matchSurfaces(spaces)

      if ["crawlspace", "unfinished basement"].include? foundation_type
        foundation_space = Geometry.make_one_space_from_multiple_spaces(model, foundation_spaces)
        if foundation_type == "crawlspace"
          foundation_space.setName("crawl space")
          foundation_zone = OpenStudio::Model::ThermalZone.new(model)
          foundation_zone.setName("crawl zone")
          foundation_space.setThermalZone(foundation_zone)
          foundation_space_type_name = Constants.SpaceTypeCrawl
        elsif foundation_type == "unfinished basement"
          foundation_space.setName("unfinished basement space")
          foundation_zone = OpenStudio::Model::ThermalZone.new(model)
          foundation_zone.setName("unfinished basement zone")
          foundation_space.setThermalZone(foundation_zone)
          foundation_space_type_name = Constants.SpaceTypeUnfinishedBasement
        end
        if space_types_hash.keys.include? foundation_space_type_name
          foundation_space_type = space_types_hash[foundation_space_type_name]
        else
          foundation_space_type = OpenStudio::Model::SpaceType.new(model)
          foundation_space_type.setStandardsSpaceType(foundation_space_type_name)
          space_types_hash[foundation_space_type_name] = foundation_space_type
        end
        foundation_space.setSpaceType(foundation_space_type)
      end

      # set foundation walls to ground
      spaces = model.getSpaces
      spaces.each do |space|
        if Geometry.get_space_floor_z(space) + UnitConversions.convert(space.zOrigin,"m","ft") < 0
          surfaces = space.surfaces
          surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            surface.setOutsideBoundaryCondition("Foundation")
          end
        end
      end

    end

    unit_hash = {}
    unit_spaces_hash.each do |unit_num, spaces|
      # Store building unit information
      unit = OpenStudio::Model::BuildingUnit.new(model)
      unit.setBuildingUnitType(Constants.BuildingUnitTypeResidential)
      unit.setName(Constants.ObjectNameBuildingUnit(unit_num))
      spaces.each do |space|
        space.setBuildingUnit(unit)
      end
      unit_hash[unit_num] = unit
    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    # Apply zone multiplier
    if use_zone_mult and ((num_units_per_floor > 3 and not has_rear_units) or (num_units_per_floor > 7 and has_rear_units))

      (1..num_units_per_floor).to_a.each do |unit_num_per_floor|
        (1..num_floors).to_a.each do |building_floor|

          unit_num = unit_num_per_floor + (num_units_per_floor * (building_floor - 1))

          if not has_rear_units

            zone_names_for_multiplier_adjustment = []
            space_names_to_remove = []
            unit_spaces = unit_hash[unit_num].spaces
            if unit_num == 1 + (num_units_per_floor * (building_floor - 1)) # leftmost unit
            elsif unit_num == 2 + (num_units_per_floor * (building_floor - 1)) # leftmost interior unit
              unit_spaces.each do |space|
                thermal_zone = space.thermalZone.get
                zone_names_for_multiplier_adjustment << thermal_zone.name.to_s
              end
              model.getThermalZones.each do |thermal_zone|
                zone_names_for_multiplier_adjustment.each do |tz|
                  if thermal_zone.name.to_s == tz
                    thermal_zone.setMultiplier(num_units_per_floor - 2)
                  end
                end
              end
            elsif unit_num < building_floor * num_units_per_floor # interior units that get removed
              unit_spaces.each do |space|
                space_names_to_remove << space.name.to_s
              end
              unit_hash[unit_num].remove
              model.getSpaces.each do |space|
                space_names_to_remove.each do |s|
                  if space.name.to_s == s
                    if space.thermalZone.is_initialized
                      space.thermalZone.get.remove
                    end
                    space.remove
                  end
                end
              end
            end

          else # has rear units

            zone_names_for_multiplier_adjustment = []
            space_names_to_remove = []
            unit_spaces = unit_hash[unit_num].spaces
            if unit_num == 1 + (num_units_per_floor * (building_floor - 1)) or unit_num == 2 + (num_units_per_floor * (building_floor - 1)) # leftmost units
            elsif unit_num == 3 + (num_units_per_floor * (building_floor - 1)) or unit_num == 4 + (num_units_per_floor * (building_floor - 1)) # leftmost interior units
              unit_spaces.each do |space|
                thermal_zone = space.thermalZone.get
                zone_names_for_multiplier_adjustment << thermal_zone.name.to_s
              end
              model.getThermalZones.each do |thermal_zone|
                zone_names_for_multiplier_adjustment.each do |tz|
                  if thermal_zone.name.to_s == tz
                    thermal_zone.setMultiplier(num_units_per_floor / 2 - 2)
                  end
                end
              end
            elsif unit_num != (building_floor * num_units_per_floor) - 1 and unit_num != building_floor * num_units_per_floor # interior units that get removed
              unit_spaces.each do |space|
                space_names_to_remove << space.name.to_s
              end
              unit_hash[unit_num].remove
              model.getSpaces.each do |space|
                space_names_to_remove.each do |s|
                  if space.name.to_s == s
                    if space.thermalZone.is_initialized
                      space.thermalZone.get.remove
                    end
                    space.remove
                  end
                end
              end
            end

          end
        end # end building floor
      end # end unit per floor
    end # end zone mult

    # Apply floor multiplier
    if use_floor_mult and num_floors > 3

      floor_zs = []
      model.getSurfaces.each do |surface|
        next unless surface.surfaceType.downcase == "floor"
        floor_zs << Geometry.getSurfaceZValues([surface])[0]
      end
      floor_zs = floor_zs.uniq.sort.select{|x| x >= 0}

      floor_zs[2..-2].each do |floor_z|
        units_to_remove = []
        Geometry.get_building_units(model, runner).each do |unit|
          unit.spaces.each do |space|
            next unless floor_z == Geometry.get_space_floor_z(space)
            next if units_to_remove.include? unit
            units_to_remove << unit
          end
        end
        units_to_remove.each do |unit|
          unit.spaces.each do |space|
            if space.thermalZone.is_initialized
              space.thermalZone.get.remove
            end
            space.remove
          end
          unit.remove
        end
      end

      Geometry.get_building_units(model, runner).each do |unit|
        unit.spaces.each do |space|
          next unless floor_zs[1] == Geometry.get_space_floor_z(space)
          thermal_zone = space.thermalZone.get
          thermal_zone.setMultiplier(thermal_zone.multiplier * (num_floors - 2))
        end
      end

    end # end floor mult

    # make all surfaces adjacent to corridor spaces into adiabatic surfaces
    model.getSpaces.each do |space|
      next unless Geometry.is_corridor(space)
      space.surfaces.each do |surface|
        if surface.adjacentSurface.is_initialized # only set to adiabatic if the corridor surface is adjacent to another surface
          surface.adjacentSurface.get.setOutsideBoundaryCondition("Adiabatic")
          surface.setOutsideBoundaryCondition("Adiabatic")
        end
      end
    end

    # set foundation outside boundary condition to Kiva "foundation"
    model.getSurfaces.each do |surface|
        next if surface.outsideBoundaryCondition.downcase != "ground"
        surface.setOutsideBoundaryCondition("Foundation")
    end

    # Store number of units
    model.getBuilding.setStandardsNumberOfLivingUnits(num_units)

    # Store number of stories
    model.getBuilding.setStandardsNumberOfAboveGroundStories(num_floors)
    if foundation_type == "unfinished basement"
      num_floors += 1
    end
    model.getBuilding.setStandardsNumberOfStories(num_floors)

    # Store the building type
    model.getBuilding.setStandardsBuildingType(Constants.BuildingTypeMultifamily)

    result = Geometry.process_beds_and_baths(model, runner, num_br, num_ba)
    unless result
      return false
    end

    result = Geometry.process_occupants(model, runner, num_occupants, occ_gain=384.0, sens_frac=0.573, lat_frac=0.427, occupants_weekday_sch, occupants_weekend_sch, occupants_monthly_sch)
    unless result
      return false
    end

    result = Geometry.process_eaves(model, runner, eaves_depth, Constants.RoofStructureTrussCantilever)
    unless result
      return false
    end

    result = Geometry.process_neighbors(model, runner, left_neighbor_offset, right_neighbor_offset, back_neighbor_offset, front_neighbor_offset)
    unless result
      return false
    end

    result = Geometry.process_orientation(model, runner, orientation)
    unless result
      return false
    end

    # reporting final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSpaces.size} spaces.")

    return true

  end

end

# register the measure to be used by the application
CreateResidentialMultifamilyGeometry.new.registerWithApplication
