# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'csv'
require 'openstudio'
if File.exist? File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources/hpxml-measures/HPXMLtoOpenStudio/resources')) # Hack to run ResStock on AWS
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources/hpxml-measures/HPXMLtoOpenStudio/resources'))
elsif File.exist? File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources')) # Hack to run ResStock unit tests locally
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources'))
elsif File.exist? File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, 'HPXMLtoOpenStudio/resources') # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, 'HPXMLtoOpenStudio/resources')
end
require File.join(resources_path, 'meta_measure')

# in addition to the above requires, this measure is expected to run in an
# environment with resstock/resources/buildstock.rb loaded

# start the measure
class BuildExistingModel < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Build Existing Model'
  end

  # human readable description
  def description
    return 'Builds the OpenStudio Model for an existing building.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Builds the OpenStudio Model using the sampling csv file, which contains the specified parameters for each existing building. Based on the supplied building number, those parameters are used to run the OpenStudio measures with appropriate arguments and build up the OpenStudio model.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    arg = OpenStudio::Ruleset::OSArgument.makeIntegerArgument('building_id', true)
    arg.setDisplayName('Building Unit ID')
    arg.setDescription('The building unit number (between 1 and the number of samples).')
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeIntegerArgument('number_of_buildings_represented', false)
    arg.setDisplayName('Number of Buildings Represented')
    arg.setDescription('The total number of buildings represented by the existing building models.')
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeDoubleArgument('sample_weight', false)
    arg.setDisplayName('Sample Weight of Simulation')
    arg.setDescription('Number of buildings this simulation represents.')
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('downselect_logic', false)
    arg.setDisplayName('Downselect Logic')
    arg.setDescription("Logic that specifies the subset of the building stock to be considered in the analysis. Specify one or more parameter|option as found in resources\\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.")
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('measures_to_ignore', false)
    arg.setDisplayName('Measures to Ignore')
    arg.setDescription("Measures to exclude from the OpenStudio Workflow specified by listing one or more measure directories separated by '|'. Core ResStock measures cannot be ignored (this measure will fail). INTENDED FOR ADVANCED USERS/WORKFLOW DEVELOPERS.")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_timestep', false)
    arg.setDisplayName('Simulation Control: Timestep')
    arg.setUnits('min')
    arg.setDescription('Value must be a divisor of 60.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_begin_month', false)
    arg.setDisplayName('Simulation Control: Run Period Begin Month')
    arg.setUnits('month')
    arg.setDescription('This numeric field should contain the starting month number (1 = January, 2 = February, etc.) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_begin_day_of_month', false)
    arg.setDisplayName('Simulation Control: Run Period Begin Day of Month')
    arg.setUnits('day')
    arg.setDescription('This numeric field should contain the starting day of the starting month (must be valid for month) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_end_month', false)
    arg.setDisplayName('Simulation Control: Run Period End Month')
    arg.setUnits('month')
    arg.setDescription('This numeric field should contain the end month number (1 = January, 2 = February, etc.) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_end_day_of_month', false)
    arg.setDisplayName('Simulation Control: Run Period End Day of Month')
    arg.setUnits('day')
    arg.setDescription('This numeric field should contain the ending day of the ending month (must be valid for month) for the annual run period desired.')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument('simulation_control_run_period_calendar_year', false)
    arg.setDisplayName('Simulation Control: Run Period Calendar Year')
    arg.setUnits('year')
    arg.setDescription('This numeric field should contain the calendar year that determines the start day of week. If you are running simulations using AMY weather files, the value entered for calendar year will not be used; it will be overridden by the actual year found in the AMY weather file.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('If true: 1) Writes in.osm file, 2) Generates additional log output, and 3) Creates all EnergyPlus output files.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('add_component_loads', false)
    arg.setDisplayName('Annual Component Loads?')
    arg.setDescription('If true, output the annual component loads.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_scenario_names', false)
    arg.setDisplayName('Emissions: Scenario Names')
    arg.setDescription('Names of emissions scenarios. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_types', false)
    arg.setDisplayName('Emissions: Types')
    arg.setDescription('Types of emissions (e.g., CO2, NOx, etc.). If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_electricity_folders', false)
    arg.setDisplayName('Emissions: Electricity Folders')
    arg.setDescription('Relative paths of electricity emissions factor schedule files with hourly values. Paths are relative to the resources folder. If multiple scenarios, use a comma-separated list. File names must contain GEA region names.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_natural_gas_values', false)
    arg.setDisplayName('Emissions: Natural Gas Values')
    arg.setDescription('Natural gas emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_propane_values', false)
    arg.setDisplayName('Emissions: Propane Values')
    arg.setDescription('Propane emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_fuel_oil_values', false)
    arg.setDisplayName('Emissions: Fuel Oil Values')
    arg.setDescription('Fuel oil emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('emissions_wood_values', false)
    arg.setDisplayName('Emissions: Wood Values')
    arg.setDescription('Wood emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list.')
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

    # assign the user inputs to variables
    args = get_argument_values(runner, arguments(model), user_arguments)

    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources'))
    characteristics_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/housing_characteristics'))
    buildstock_file = File.join(resources_dir, 'buildstock.rb')
    measures_dir = File.join(File.dirname(__FILE__), '../../measures')
    hpxml_measures_dir = File.join(File.dirname(__FILE__), '../../resources/hpxml-measures')
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')
    buildstock_csv_path = File.absolute_path(File.join(characteristics_dir, 'buildstock.csv')) # Should have been generated by the Worker Initialization Script (run_sampling.rb) or provided by the project

    # Load buildstock_file
    require File.join(File.dirname(buildstock_file), File.basename(buildstock_file, File.extname(buildstock_file)))

    # Check file/dir paths exist
    [measures_dir, hpxml_measures_dir].each do |dir|
      check_dir_exists(dir, runner)
    end
    check_dir_exists(characteristics_dir, runner)
    check_file_exists(lookup_file, runner)
    check_file_exists(buildstock_csv_path, runner)

    lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a

    # Retrieve all data associated with sample number
    bldg_data = get_data_for_sample(buildstock_csv_path, args['building_id'], runner)

    # Retrieve order of parameters to run
    parameters_ordered = get_parameters_ordered_from_options_lookup_tsv(lookup_csv_data, characteristics_dir)

    # Retrieve options that have been selected for this building_id
    parameters_ordered.each do |parameter_name|
      # Register the option chosen for parameter_name with the runner
      option_name = bldg_data[parameter_name]
      register_value(runner, parameter_name, option_name)
    end

    # Determine whether this building_id has been downselected based on the
    # {parameter_name: option_name} pairs
    if args['downselect_logic'].is_initialized

      downselect_logic = args['downselect_logic'].get
      downselect_logic = downselect_logic.strip
      downselected = evaluate_logic(downselect_logic, runner, past_results = false)

      if downselected.nil?
        # unable to evaluate logic
        return false
      end

      unless downselected
        # Not in downselection; don't run existing home simulation
        runner.registerInfo('Sample is not in downselected parameters; will be registered as invalid.')
        runner.haltWorkflow('Invalid')
        return false
      end

    end

    # Obtain measures and arguments to be called
    measures = {}
    parameters_ordered.each do |parameter_name|
      option_name = bldg_data[parameter_name]
      print_option_assignment(parameter_name, option_name, runner)
      options_measure_args = get_measure_args_from_option_names(lookup_csv_data, [option_name], parameter_name, lookup_file, runner)
      options_measure_args[option_name].each do |measure_subdir, args_hash|
        update_args_hash(measures, measure_subdir, args_hash, add_new = false)
      end
    end

    # Remove any measures_to_ignore from the list of measures to run
    if args['measures_to_ignore'].is_initialized
      measures_to_ignore = args['measures_to_ignore'].get
      # core ResStock measures are those specified below
      # those should not be ignored ...
      core_measures = ['ResStockArguments', 'BuildResidentialHPXML', 'BuildResidentialScheduleFile', 'HPXMLtoOpenStudio']
      measures_to_ignore.split('|').each do |measure_dir|
        if core_measures.include? measure_dir
          # fail if core ResStock measure is ignored
          msg = "Core ResStock measure #{measure_dir} cannot be ignored"
          runner.registerError(msg)
          fail msg
        end
        runner.registerInfo("Ignoring/not running measure #{measure_dir}")
        measures.delete(measure_dir)
      end
    end

    # Get the absolute paths relative to this meta measure in the run directory
    new_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new) # we want only ResStockArguments registered argument values
    if not apply_measures(measures_dir, { 'ResStockArguments' => measures['ResStockArguments'] }, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', nil)
      new_runner.result.warnings.each do |warning|
        runner.registerWarning(warning.logMessage)
      end
      new_runner.result.info.each do |info|
        runner.registerInfo(info.logMessage)
      end
      new_runner.result.errors.each do |error|
        runner.registerError(error.logMessage)
      end
      return false
    end

    # Initialize measure keys with hpxml_path arguments
    hpxml_path = File.expand_path('../existing.xml')
    measures['BuildResidentialHPXML'] = [{ 'hpxml_path' => hpxml_path }]
    measures['BuildResidentialScheduleFile'] = [{ 'hpxml_path' => hpxml_path, 'hpxml_output_path' => hpxml_path }]
    measures['HPXMLtoOpenStudio'] = [{ 'hpxml_path' => hpxml_path }]

    new_runner.result.stepValues.each do |step_value|
      value = get_value_from_workflow_step_value(step_value)
      next if value == ''

      if ['schedules_type', 'schedules_vacancy_period'].include?(step_value.name)
        measures['BuildResidentialScheduleFile'][0][step_value.name] = value
      else
        measures['BuildResidentialHPXML'][0][step_value.name] = value
      end
    end

    # Get software program used and version
    measures['BuildResidentialHPXML'][0]['software_info_program_used'] = Version.software_program_used
    measures['BuildResidentialHPXML'][0]['software_info_program_version'] = Version.software_program_version

    # Get registered values and pass them to BuildResidentialHPXML
    measures['BuildResidentialHPXML'][0]['simulation_control_timestep'] = args['simulation_control_timestep'].get if args['simulation_control_timestep'].is_initialized
    if args['simulation_control_run_period_begin_month'].is_initialized && args['simulation_control_run_period_begin_day_of_month'].is_initialized && args['simulation_control_run_period_end_month'].is_initialized && args['simulation_control_run_period_end_day_of_month'].is_initialized
      begin_month = "#{Date::ABBR_MONTHNAMES[args['simulation_control_run_period_begin_month'].get]}"
      begin_day = args['simulation_control_run_period_begin_day_of_month'].get
      end_month = "#{Date::ABBR_MONTHNAMES[args['simulation_control_run_period_end_month'].get]}"
      end_day = args['simulation_control_run_period_end_day_of_month'].get
      measures['BuildResidentialHPXML'][0]['simulation_control_run_period'] = "#{begin_month} #{begin_day} - #{end_month} #{end_day}"
    end
    measures['BuildResidentialHPXML'][0]['simulation_control_run_period_calendar_year'] = args['simulation_control_run_period_calendar_year'].get if args['simulation_control_run_period_calendar_year'].is_initialized

    # Emissions
    if args['emissions_scenario_names'].is_initialized
      if !bldg_data.keys.include?('Generation And Emissions Assessment Region')
        runner.registerError('Emissions scenario(s) were specified, but could not find the Generation and Emissions Assessment (GEA) region.')
        return false
      end

      emissions_electricity_filepaths = []
      scenarios = args['emissions_electricity_folders'].get.split(',')
      scenarios.each do |scenario|
        scenario = File.join(resources_dir, scenario)
        if !File.exist?(scenario)
          runner.registerError("Emissions scenario electricity folder '#{scenario}' does not exist.")
          return false
        end

        Dir["#{scenario}/*.csv"].each do |filepath|
          emissions_electricity_filepaths << filepath if filepath.include?(bldg_data['Generation And Emissions Assessment Region'])
        end
      end

      emissions_scenario_names = args['emissions_scenario_names'].get
      emissions_types = args['emissions_types'].get
      emissions_electricity_filepaths = emissions_electricity_filepaths.join(',')
      emissions_electricity_units = ([HPXML::EmissionsScenario::UnitsKgPerMWh] * scenarios.size).join(',')

      measures['BuildResidentialHPXML'][0]['emissions_scenario_names'] = emissions_scenario_names
      measures['BuildResidentialHPXML'][0]['emissions_types'] = emissions_types
      measures['BuildResidentialHPXML'][0]['emissions_electricity_units'] = emissions_electricity_units
      measures['BuildResidentialHPXML'][0]['emissions_electricity_values_or_filepaths'] = emissions_electricity_filepaths
      register_value(runner, 'emissions_scenario_names', emissions_scenario_names)
      register_value(runner, 'emissions_types', emissions_types)
      register_value(runner, 'emissions_electricity_units', emissions_electricity_units)
      register_value(runner, 'emissions_electricity_values_or_filepaths', emissions_electricity_filepaths)

      if args['emissions_natural_gas_values'].is_initialized || args['emissions_propane_values'].is_initialized || args['emissions_fuel_oil_values'].is_initialized || args['emissions_wood_values'].is_initialized
        emissions_fossil_fuel_units = ([HPXML::EmissionsScenario::UnitsLbPerMBtu] * scenarios.size).join(',')
        measures['BuildResidentialHPXML'][0]['emissions_fossil_fuel_units'] = emissions_fossil_fuel_units
        register_value(runner, 'emissions_fossil_fuel_units', emissions_fossil_fuel_units)

        if args['emissions_natural_gas_values'].is_initialized
          emissions_natural_gas_values = args['emissions_natural_gas_values'].get
          measures['BuildResidentialHPXML'][0]['emissions_natural_gas_values'] = emissions_natural_gas_values
          register_value(runner, 'emissions_natural_gas_values', emissions_natural_gas_values)
        end

        if args['emissions_propane_values'].is_initialized
          emissions_propane_values = args['emissions_propane_values'].get
          measures['BuildResidentialHPXML'][0]['emissions_propane_values'] = emissions_propane_values
          register_value(runner, 'emissions_propane_values', emissions_propane_values)
        end

        if args['emissions_fuel_oil_values'].is_initialized
          emissions_fuel_oil_values = args['emissions_fuel_oil_values'].get
          measures['BuildResidentialHPXML'][0]['emissions_fuel_oil_values'] = emissions_fuel_oil_values
          register_value(runner, 'emissions_fuel_oil_values', emissions_fuel_oil_values)
        end

        if args['emissions_wood_values'].is_initialized
          emissions_wood_values = args['emissions_wood_values'].get
          measures['BuildResidentialHPXML'][0]['emissions_wood_values'] = emissions_wood_values
          register_value(runner, 'emissions_wood_values', emissions_wood_values)
        end
      end
    end

    # Get registered values and pass them to BuildResidentialScheduleFile
    measures['BuildResidentialScheduleFile'][0]['schedules_random_seed'] = args['building_id']
    measures['BuildResidentialScheduleFile'][0]['output_csv_path'] = File.expand_path('../schedules.csv')

    # Get registered values and pass them to HPXMLtoOpenStudio
    measures['HPXMLtoOpenStudio'][0]['output_dir'] = File.expand_path('..')
    measures['HPXMLtoOpenStudio'][0]['debug'] = args['debug'].get if args['debug'].is_initialized
    measures['HPXMLtoOpenStudio'][0]['add_component_loads'] = args['add_component_loads'].get if args['add_component_loads'].is_initialized

    if not apply_measures(hpxml_measures_dir, { 'BuildResidentialHPXML' => measures['BuildResidentialHPXML'], 'BuildResidentialScheduleFile' => measures['BuildResidentialScheduleFile'], 'HPXMLtoOpenStudio' => measures['HPXMLtoOpenStudio'] }, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', 'existing.osw')
      new_runner.result.warnings.each do |warning|
        runner.registerWarning(warning.logMessage)
      end
      new_runner.result.info.each do |info|
        runner.registerInfo(info.logMessage)
      end
      new_runner.result.errors.each do |error|
        runner.registerError(error.logMessage)
      end
      return false
    end

    # Report some additional location and model characteristics
    weather = WeatherProcess.new(model, runner)
    register_value(runner, 'weather_file_city', weather.header.City)
    register_value(runner, 'weather_file_latitude', "#{weather.header.Latitude}")
    register_value(runner, 'weather_file_longitude', "#{weather.header.Longitude}")

    # Determine weight
    if args['number_of_buildings_represented'].is_initialized
      total_samples = nil
      runner.analysis[:analysis][:problem][:workflow].each do |wf|
        next if wf[:name] != 'build_existing_model'

        wf[:variables].each do |v|
          next if v[:argument][:name] != 'building_id'

          total_samples = v[:maximum].to_f
        end
      end
      if total_samples.nil?
        runner.registerError('Could not retrieve value for number_of_buildings_represented.')
        return false
      end
      weight = args['number_of_buildings_represented'].get / total_samples
      register_value(runner, 'weight', weight.to_s)
    end

    if args['sample_weight'].is_initialized
      register_value(runner, 'weight', args['sample_weight'].get.to_s)
    end

    return true
  end
end

# register the measure to be used by the application
BuildExistingModel.new.registerWithApplication
