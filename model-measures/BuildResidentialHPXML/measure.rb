# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require_relative "resources/constructions"
require_relative "resources/hpxml"

# start the measure
class HPXMLExporter < OpenStudio::Measure::ModelMeasure
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

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("hpxml_output_path", true)
    arg.setDisplayName("HPXML Output File Path")
    arg.setDescription("Absolute (or relative) path of the output HPXML file.")
    args << arg

    unit_type_choices = OpenStudio::StringVector.new
    unit_type_choices << "single-family detached"
    unit_type_choices << "single-family attached"
    unit_type_choices << "multifamily"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("unit_type", unit_type_choices, true)
    arg.setDisplayName("Unit Type")
    arg.setDescription("The type of unit.")
    arg.setDefaultValue("single-family detached")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("unit_multiplier", true)
    arg.setDisplayName("Unit Multiplier")
    arg.setUnits("#")
    arg.setDescription("The number of actual units this single unit represents.")
    arg.setDefaultValue(1)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("total_ffa", true)
    arg.setDisplayName("Total Finished Floor Area")
    arg.setUnits("ft^2")
    arg.setDescription("The total floor area of the finished space (including any finished basement floor area).")
    arg.setDefaultValue(2000.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("wall_height", true)
    arg.setDisplayName("Wall Height (Per Floor)")
    arg.setUnits("ft")
    arg.setDescription("The height of the living space (and garage) walls.")
    arg.setDefaultValue(8.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("num_floors", true)
    arg.setDisplayName("Number of Floors")
    arg.setUnits("#")
    arg.setDescription("The number of floors above grade.")
    arg.setDefaultValue(2)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("aspect_ratio", true)
    arg.setDisplayName("Aspect Ratio")
    arg.setUnits("FB/LR")
    arg.setDescription("The ratio of the front/back wall length to the left/right wall length, excluding any protruding garage wall area.")
    arg.setDefaultValue(2.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("garage_width", true)
    arg.setDisplayName("Garage Width")
    arg.setUnits("ft")
    arg.setDescription("The width of the garage.")
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("garage_depth", true)
    arg.setDisplayName("Garage Depth")
    arg.setUnits("ft")
    arg.setDescription("The depth of the garage.")
    arg.setDefaultValue(20.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("garage_protrusion", true)
    arg.setDisplayName("Garage Protrusion")
    arg.setUnits("frac")
    arg.setDescription("The fraction of the garage that is protruding from the living space.")
    arg.setDefaultValue(0.0)
    args << arg

    garage_position_choices = OpenStudio::StringVector.new
    garage_position_choices << "Right"
    garage_position_choices << "Left"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("garage_position", garage_position_choices, true)
    arg.setDisplayName("Garage Position")
    arg.setDescription("The position of the garage.")
    arg.setDefaultValue("Right")
    args << arg

    foundation_type_choices = OpenStudio::StringVector.new
    foundation_type_choices << "slab"
    foundation_type_choices << "crawlspace"
    foundation_type_choices << "unfinished basement"
    foundation_type_choices << "finished basement"
    foundation_type_choices << "pier and beam"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("foundation_type", foundation_type_choices, true)
    arg.setDisplayName("Foundation Type")
    arg.setDescription("The foundation type of the building.")
    arg.setDefaultValue("slab")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("foundation_height", true)
    arg.setDisplayName("Foundation Height")
    arg.setUnits("ft")
    arg.setDescription("The height of the foundation (e.g., 3ft for crawlspace, 8ft for basement).")
    arg.setDefaultValue(3.0)
    args << arg

    attic_type_choices = OpenStudio::StringVector.new
    attic_type_choices << "unfinished attic"
    attic_type_choices << "finished attic"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("attic_type", attic_type_choices, true)
    arg.setDisplayName("Attic Type")
    arg.setDescription("The attic type of the building. Ignored if the building has a flat roof.")
    arg.setDefaultValue("unfinished attic")
    args << arg

    roof_type_choices = OpenStudio::StringVector.new
    roof_type_choices << "gable"
    roof_type_choices << "hip"
    roof_type_choices << "flat"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("roof_type", roof_type_choices, true)
    arg.setDisplayName("Roof Type")
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
    arg.setDisplayName("Roof Pitch")
    arg.setDescription("The roof pitch of the attic. Ignored if the building has a flat roof.")
    arg.setDefaultValue("6:12")
    args << arg

    roof_structure_choices = OpenStudio::StringVector.new
    roof_structure_choices << "truss, cantilever"
    roof_structure_choices << "rafter"

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("roof_structure", roof_structure_choices, true)
    arg.setDisplayName("Roof Structure")
    arg.setDescription("The roof structure of the building.")
    arg.setDefaultValue("truss, cantilever")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("eaves_depth", true)
    arg.setDisplayName("Eaves Depth")
    arg.setUnits("ft")
    arg.setDescription("The eaves depth of the roof.")
    arg.setDefaultValue(2.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("num_bedrooms", true)
    arg.setDisplayName("Number of Bedrooms")
    arg.setDescription("Specify the number of bedrooms. Used to determine the energy usage of appliances and plug loads, hot water usage, mechanical ventilation rate, etc.")
    arg.setDefaultValue("3")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("num_bathrooms", true)
    arg.setDisplayName("Number of Bathrooms")
    arg.setDescription("Specify the number of bathrooms. Used to determine the hot water usage, etc.")
    arg.setDefaultValue("2")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("num_occupants", true)
    arg.setDisplayName("Number of Occupants")
    arg.setDescription("Specify the number of occupants. A value of '#{Constants.Auto}' will calculate the average number of occupants from the number of bedrooms. Used to specify the internal gains from people only.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("occupants_weekday_sch", true)
    arg.setDisplayName("Occupants Weekday schedule")
    arg.setDescription("Specify the 24-hour weekday schedule.")
    arg.setDefaultValue("1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.88, 0.41, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.29, 0.55, 0.90, 0.90, 0.90, 1.00, 1.00, 1.00")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("occupants_weekend_sch", true)
    arg.setDisplayName("Occupants Weekend schedule")
    arg.setDescription("Specify the 24-hour weekend schedule.")
    arg.setDefaultValue("1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 1.00, 0.88, 0.41, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.24, 0.29, 0.55, 0.90, 0.90, 0.90, 1.00, 1.00, 1.00")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument("occupants_monthly_sch", true)
    arg.setDisplayName("Occupants Month schedule")
    arg.setDescription("Specify the 12-month schedule.")
    arg.setDefaultValue("1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_left_offset", true)
    arg.setDisplayName("Neighbor Left Offset")
    arg.setUnits("ft")
    arg.setDescription("The minimum distance between the simulated house and the neighboring house to the left (not including eaves). A value of zero indicates no neighbors.")
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_right_offset", true)
    arg.setDisplayName("Neighbor Right Offset")
    arg.setUnits("ft")
    arg.setDescription("The minimum distance between the simulated house and the neighboring house to the right (not including eaves). A value of zero indicates no neighbors.")
    arg.setDefaultValue(10.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_back_offset", true)
    arg.setDisplayName("Neighbor Back Offset")
    arg.setUnits("ft")
    arg.setDescription("The minimum distance between the simulated house and the neighboring house to the back (not including eaves). A value of zero indicates no neighbors.")
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("neighbor_front_offset", true)
    arg.setDisplayName("Neighbor Front Offset")
    arg.setUnits("ft")
    arg.setDescription("The minimum distance between the simulated house and the neighboring house to the front (not including eaves). A value of zero indicates no neighbors.")
    arg.setDefaultValue(0.0)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument("orientation", true)
    arg.setDisplayName("Azimuth")
    arg.setUnits("degrees")
    arg.setDescription("The house's azimuth is measured clockwise from due south when viewed from above (e.g., South=0, West=90, North=180, East=270).")
    arg.setDefaultValue(180.0)
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

    # Check for correct versions of OS
    os_version = "2.9.0"
    if OpenStudio.openStudioVersion != os_version
      fail "OpenStudio version #{os_version} is required."
    end

    # assign the user inputs to variables
    args = { :hpxml_output_path => runner.getStringArgumentValue("hpxml_output_path", user_arguments),
             :unit_type => runner.getStringArgumentValue("unit_type", user_arguments),
             :unit_multiplier => runner.getIntegerArgumentValue("unit_multiplier", user_arguments),
             :total_ffa => runner.getDoubleArgumentValue("total_ffa", user_arguments),
             :wall_height => runner.getDoubleArgumentValue("wall_height", user_arguments),
             :num_floors => runner.getIntegerArgumentValue("num_floors", user_arguments),
             :aspect_ratio => runner.getDoubleArgumentValue("aspect_ratio", user_arguments),
             :garage_width => runner.getDoubleArgumentValue("garage_width", user_arguments),
             :garage_depth => runner.getDoubleArgumentValue("garage_depth", user_arguments),
             :garage_protrusion => runner.getDoubleArgumentValue("garage_protrusion", user_arguments),
             :garage_position => runner.getStringArgumentValue("garage_position", user_arguments),
             :foundation_type => runner.getStringArgumentValue("foundation_type", user_arguments),
             :foundation_height => runner.getDoubleArgumentValue("foundation_height", user_arguments),
             :attic_type => runner.getStringArgumentValue("attic_type", user_arguments),
             :roof_type => runner.getStringArgumentValue("roof_type", user_arguments),
             :roof_pitch => { "1:12" => 1.0 / 12.0, "2:12" => 2.0 / 12.0, "3:12" => 3.0 / 12.0, "4:12" => 4.0 / 12.0, "5:12" => 5.0 / 12.0, "6:12" => 6.0 / 12.0, "7:12" => 7.0 / 12.0, "8:12" => 8.0 / 12.0, "9:12" => 9.0 / 12.0, "10:12" => 10.0 / 12.0, "11:12" => 11.0 / 12.0, "12:12" => 12.0 / 12.0 }[runner.getStringArgumentValue("roof_pitch", user_arguments)],
             :roof_structure => runner.getStringArgumentValue("roof_structure", user_arguments),
             :eaves_depth => UnitConversions.convert(runner.getDoubleArgumentValue("eaves_depth", user_arguments), "ft", "m"),
             :num_bedrooms => runner.getStringArgumentValue("num_bedrooms", user_arguments).split(",").map(&:strip),
             :num_bathrooms => runner.getStringArgumentValue("num_bathrooms", user_arguments).split(",").map(&:strip),
             :num_occupants => runner.getStringArgumentValue("num_occupants", user_arguments),
             :occupants_weekday_sch => runner.getStringArgumentValue("occupants_weekday_sch", user_arguments),
             :occupants_weekend_sch => runner.getStringArgumentValue("occupants_weekend_sch", user_arguments),
             :occupants_monthly_sch => runner.getStringArgumentValue("occupants_monthly_sch", user_arguments),
             :neighbor_left_offset => UnitConversions.convert(runner.getDoubleArgumentValue("neighbor_left_offset", user_arguments), "ft", "m"),
             :neighbor_right_offset => UnitConversions.convert(runner.getDoubleArgumentValue("neighbor_right_offset", user_arguments), "ft", "m"),
             :neighbor_back_offset => UnitConversions.convert(runner.getDoubleArgumentValue("neighbor_back_offset", user_arguments), "ft", "m"),
             :neighbor_front_offset => UnitConversions.convert(runner.getDoubleArgumentValue("neighbor_front_offset", user_arguments), "ft", "m"),
             :orientation => runner.getDoubleArgumentValue("orientation", user_arguments) }

    # Create HPXML file
    hpxml_doc = HPXMLFile.create(runner, model, args)
    if not hpxml_doc
      runner.registerError("Unsuccessful creation of HPXML file.")
      return false
    end

    # Validate file against HPXML schema
    skip = true
    if not skip
      schemas_dir = File.absolute_path(File.join(File.dirname(__FILE__), "hpxml_schemas"))
      errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), nil)
      if errors.size > 0
        fail errors.to_s
      end
    end

    XMLHelper.write_file(hpxml_doc, args[:hpxml_output_path])
    runner.registerInfo("Wrote file: #{args[:hpxml_output_path]}")
  end
end

class HPXMLFile
  def self.create(runner, model, args)
    hpxml_values = { :xml_type => "HPXML",
                     :xml_generated_by => "BuildResidentialHPXML",
                     :transaction => "create",
                     :eri_calculation_version => "2014AEG",
                     :building_id => "MyBuilding",
                     :event_type => "proposed workscope" }

    success = create_geometry_envelope(runner, model, args)
    return false if not success

    roofs_values = get_roofs_values(runner, model, args)
    walls_values = get_walls_values(runner, model, args)
    slabs_values = get_slabs_values(runner, model, args)

    hpxml_doc = HPXML.create_hpxml(**hpxml_values)
    hpxml = hpxml_doc.elements["HPXML"]

    roofs_values.each do |roof_values|
      HPXML.add_roof(hpxml: hpxml, **roof_values)
    end
    walls_values.each do |wall_values|
      HPXML.add_wall(hpxml: hpxml, **wall_values)
    end
    slabs_values.each do |slab_values|
      HPXML.add_slab(hpxml: hpxml, **slab_values)
    end

    return hpxml_doc
  end

  def self.create_geometry_envelope(runner, model, args)
    if args[:unit_type] == "single-family detached"
      success = Geometry.create_single_family_detached(runner, model, args[:total_ffa], args[:wall_height], args[:num_floors], args[:aspect_ratio], args[:garage_width], args[:garage_depth], args[:garage_protrusion], args[:garage_position], args[:foundation_type], args[:foundation_height], args[:attic_type], args[:roof_type], args[:roof_pitch], args[:roof_structure])
      return false if not success
    elsif args[:unit_type] == "single-family attached"
    elsif args[:unit_type] == "multifamily"
    end
    return true
  end

  def self.get_roofs_values(runner, model, args)
    roofs_values = []
    model.getSurfaces.each do |surface|
      if not ["Outdoors"].include? surface.outsideBoundaryCondition
        next
      end

      if [Constants.SpaceTypeLiving].include? surface.space.get.spaceType.get.standardsSpaceType.to_s
        interior_adjacent_to = "living space"
      elsif [Constants.SpaceTypeVentedAttic].include? surface.space.get.spaceType.get.standardsSpaceType.to_s
        interior_adjacent_to = "attic - vented"
      elsif [Constants.SpaceTypeUnventedAttic].include? surface.space.get.spaceType.get.standardsSpaceType.to_s
        interior_adjacent_to = "attic - unvented"
      else
        next
      end

      if surface.surfaceType == "RoofCeiling"
        roofs_values << { :id => surface.name,
                          :interior_adjacent_to => interior_adjacent_to,
                          :area => surface.netArea,
                          :solar_absorptance => 0.7,
                          :emittance => 0.92,
                          :pitch => args[:roof_pitch],
                          :radiant_barrier => false,
                          :insulation_assembly_r_value => 0 }
      end
    end
    return roofs_values
  end

  def self.get_walls_values(runner, model, args)
    walls_values = []
    model.getSurfaces.each do |surface|
      if ["Outdoors"].include? surface.outsideBoundaryCondition
        exterior_adjacent_to = "outside"
      else
        next
      end
      if [Constants.SpaceTypeLiving].include? surface.space.get.spaceType.get.standardsSpaceType.to_s
        interior_adjacent_to = "living space"
      else
        next
      end

      if surface.surfaceType == "Wall"
        walls_values << { :id => surface.name,
                          :exterior_adjacent_to => exterior_adjacent_to,
                          :interior_adjacent_to => interior_adjacent_to,
                          :wall_type => "WoodStud",
                          :area => surface.netArea,
                          :azimuth => nil,
                          :solar_absorptance => 0.7,
                          :emittance => 0.92,
                          :insulation_id => nil,
                          :insulation_assembly_r_value => 13 }
      end
    end
    return walls_values
  end

  def self.get_slabs_values(runner, model, args)
    slabs_values = []
    model.getSurfaces.each do |surface|
      if not ["Foundation"].include? surface.outsideBoundaryCondition
        next
      end

      if [Constants.SpaceTypeLiving].include? surface.space.get.spaceType.get.standardsSpaceType.to_s
        interior_adjacent_to = "living space"
      else
        next
      end

      if surface.surfaceType == "Floor"
        slabs_values << { :id => surface.name,
                          :interior_adjacent_to => interior_adjacent_to,
                          :area => surface.netArea,
                          :thickness => 4,
                          :exposed_perimeter => 150,
                          :perimeter_insulation_depth => 0,
                          :perimeter_insulation_r_value => 0,
                          :under_slab_insulation_r_value => 0,
                          :carpet_fraction => 0,
                          :carpet_r_value => 0 }
      end
    end
    return slabs_values
  end
end

# register the measure to be used by the application
HPXMLExporter.new.registerWithApplication
