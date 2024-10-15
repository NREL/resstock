# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require 'pathname'
require 'oga'
Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |resource_file|
  require resource_file
end
Dir["#{File.dirname(__FILE__)}/../HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

# start the measure
class BuildElectricalPanel < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Residential Electrical Panel Builder'
  end

  # human readable description
  def description
    return 'Assigns electrical panel rating based on input housing characteristics.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Assigns electrical panel rating by mapping input housing characteristics to the output of two decision-tree models, one for electrically heated homes and one for everything else. Developed by LBNL (SMurphy@lbl.gov), the models are derived from mostly retrofit program/survey data from the Pacific Northwest. The result confidence is low for all building types except for Single-Family Detached due to small sample size for those building types and that the models do not distinguish shared systems.'
  end

  # Define the arguments that the user will input.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [OpenStudio::Measure::OSArgumentVector] an OpenStudio::Measure::OSArgumentVector object
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('electrical_panel_rated_capacity _bin', true)
    arg.setDisplayName('Electrical Panel: Rated Capacity Bin')
    arg.setDescription("E.g., '100', '101-124'.")
    arg.setDefaultValue('200')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('electrical_panel_rated_capacity', true)
    arg.setDisplayName('Electrical Panel: Rated Capacity')
    arg.setDescription("E.g., '100', '120'.")
    arg.setDefaultValue('200')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_path', true)
    arg.setDisplayName('HPXML File Path')
    arg.setDescription('Absolute/relative path of the HPXML file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('panels_random_seed', false)
    arg.setDisplayName('Panels: Random Seed')
    arg.setUnits('#')
    arg.setDescription('This numeric field is the seed for the random number generator.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('hpxml_output_path', true)
    arg.setDisplayName('HPXML Output File Path')
    arg.setDescription('Absolute/relative output path of the HPXML file. This HPXML file will include the output CSV path.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('If true, writes extra column(s) for informational purposes.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('building_id', false)
    arg.setDisplayName('BuildingID')
    arg.setDescription("The ID of the HPXML Building. Only required if there are multiple Building elements in the HPXML file. Use 'ALL' to apply panel assignment to all the HPXML Buildings (dwelling units) of a multifamily building.")
    args << arg

    return args
  end

  # Define what happens when the measure is run.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param user_arguments [OpenStudio::Measure::OSArgumentMap] OpenStudio measure arguments
  # @return [Boolean] true if successful
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    args = runner.getArgumentValues(arguments(model), user_arguments)

    hpxml_path = args[:hpxml_path]
    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(hpxml_path)
    end
    unless File.exist?(hpxml_path) && hpxml_path.downcase.end_with?('.xml')
      fail "'#{hpxml_path}' does not exist or is not an .xml file."
    end

    hpxml_output_path = args[:hpxml_output_path]
    unless (Pathname.new hpxml_output_path).absolute?
      hpxml_output_path = File.expand_path(hpxml_output_path)
    end
    args[:hpxml_output_path] = hpxml_output_path

    # random seed
    if not args[:panels_random_seed].nil?
      args[:random_seed] = args[:panels_random_seed]
      runner.registerInfo("Retrieved the panels random seed; setting it to #{args[:random_seed]}.")
    else
      args[:random_seed] = 1
      runner.registerInfo('Unable to retrieve the panels random seed; setting it to 1.')
    end

    doc = XMLHelper.parse_file(hpxml_path)
    hpxml_doc = XMLHelper.get_element(doc, '/HPXML')
    doc_buildings = XMLHelper.get_elements(hpxml_doc, 'Building')
    doc_buildings.each_with_index do |building, i|
      doc_building_id = XMLHelper.get_attribute_value(XMLHelper.get_element(building, 'BuildingID'), 'id')

      next if doc_buildings.size > 1 && args[:building_id] != 'ALL' && args[:building_id] != doc_building_id

      hpxml = HPXML.new(hpxml_path: hpxml_path, building_id: doc_building_id)
      hpxml_bldg = hpxml.buildings[0]


      # deterministically vary panels across building units
      args[:random_seed] *= (i + 1)


      # create the panels' characteristics
      success = assign_electrical_panel_characteristics(runner, hpxml_bldg, args)
      return false if not success


      # modify the hpxml with the schedules path
      extension = XMLHelper.create_elements_as_needed(building, ['BuildingDetails', 'BuildingSummary', 'extension'])
      schedules_filepaths = XMLHelper.get_values(extension, 'SchedulesFilePath', :string)
      if !schedules_filepaths.include?(args[:output_csv_path])
        XMLHelper.add_element(extension, 'SchedulesFilePath', args[:output_csv_path], :string)
      end
      write_modified_hpxml(runner, doc, hpxml_path, hpxml_output_path, schedules_filepaths, args)
    end

    return true
  end

  # Write out the HPXML file with the output CSV path containing occupancy schedules.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param doc [Oga::XML::Document] Oga XML Document object
  # @param hpxml_path [String] Path to the HPXML file
  # @param hpxml_output_path [String] Path to the output HPXML file
  # @param schedules_filepaths [Array<String>] array of SchedulesFilePath strings in the input HPXML file
  # @param args [Hash] Map of :argument_name => value
  def write_modified_hpxml(runner, doc, hpxml_path, hpxml_output_path, schedules_filepaths, args)
    # write out the modified hpxml
    if (hpxml_path != hpxml_output_path) || !schedules_filepaths.include?(args[:output_csv_path])
      XMLHelper.write_file(doc, hpxml_output_path)
      runner.registerInfo("Wrote file: #{hpxml_output_path}")
    end
  end

  # Assign panel rated capacity and available breaker space.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml [HPXML] HPXML object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [Boolean] true if successful
  def assign_electrical_panel_characteristics(runner, hpxml_bldg, args)
    info_msgs = []

    get_generator_inputs(hpxml_bldg, args)

    args[:resources_path] = File.join(File.dirname(__FILE__), 'resources')
    capacity_generator = RatedCapacityGenerator.new(runner: runner, **args)
    breaker_space_generator = BreakerSpaceGenerator.new(runner: runner, **args)

    args = capacity_generator.create(args: args)
    args = breaker_space_generator.create(args: args)

    info_msgs << "SimYear=#{args[:sim_year]}"
    info_msgs << "MinutesPerStep=#{args[:minutes_per_step]}"
    info_msgs << "State=#{args[:state]}"
    info_msgs << "RandomSeed=#{args[:random_seed]}" if !args[:panels_random_seed].nil?
    info_msgs << "GeometryNumOccupants=#{args[:geometry_num_occupants]}"
    info_msgs << "TimeZoneUTCOffset=#{args[:time_zone_utc_offset]}"
    info_msgs << "Latitude=#{args[:latitude]}"
    info_msgs << "Longitude=#{args[:longitude]}"

    runner.registerInfo("Assigned electrical panel characteristics with #{info_msgs.join(', ')}")

    return args
  end

  # Get generator inputs that are required for the stochastic panel characteristics assignment.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param weather [WeatherFile] Weather object containing EPW information
  # @param args [Hash] Map of :argument_name => value
  def get_generator_inputs(hpxml_bldg, args)
    state_code = HPXMLDefaults.get_default_state_code(hpxml_bldg.state_code, weather)
    if Constants::StateCodesMap.keys.include?(state_code)
      args[:state] = state_code
    else
      # Unhandled state code, fallback to CO
      args[:state] = 'CO'
    end
    args[:column_names] = args[:schedules_column_names].split(',').map(&:strip) if !args[:schedules_column_names].nil?

    if hpxml_bldg.building_occupancy.number_of_residents.nil?
      args[:geometry_num_occupants] = Geometry.get_occupancy_default_num(nbeds: hpxml_bldg.building_construction.number_of_bedrooms)
    else
      args[:geometry_num_occupants] = hpxml_bldg.building_occupancy.number_of_residents
    end
    args[:geometry_num_occupants] = Float(Integer(args[:geometry_num_occupants]))

    args[:time_zone_utc_offset] = HPXMLDefaults.get_default_time_zone(hpxml_bldg.time_zone_utc_offset, weather)
    args[:latitude] = HPXMLDefaults.get_default_latitude(hpxml_bldg.latitude, weather)
    args[:longitude] = HPXMLDefaults.get_default_longitude(hpxml_bldg.longitude, weather)
  end
end

# register the measure to be used by the application
BuildResidentialElectricalPanel.new.registerWithApplication
