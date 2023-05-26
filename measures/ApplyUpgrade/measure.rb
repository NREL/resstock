# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require_relative 'resources/constants'
require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

# in addition to the above requires, this measure is expected to run in an
# environment with resstock/resources/buildstock.rb loaded

# start the measure
class ApplyUpgrade < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Apply Upgrade'
  end

  # human readable description
  def description
    return 'Measure that applies an upgrade (one or more child measures) to a building model based on the specified logic.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Determines if the upgrade should apply to a given building model. If so, calls one or more child measures with the appropriate arguments.'
  end

  def num_options
    return Constants.NumApplyUpgradeOptions # Synced with UpgradeCosts measure
  end

  def num_costs_per_option
    return Constants.NumApplyUpgradesCostsPerOption # Synced with UpgradeCosts measure
  end

  def cost_multiplier_choices
    return Constants.CostMultiplierChoices # Synced with UpgradeCosts measure
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # Make string arg for upgrade name
    upgrade_name = OpenStudio::Ruleset::OSArgument::makeStringArgument('upgrade_name', true)
    upgrade_name.setDisplayName('Upgrade Name')
    upgrade_name.setDescription('User-specificed name that describes the upgrade.')
    upgrade_name.setDefaultValue('My Upgrade')
    args << upgrade_name

    for option_num in 1..num_options

      # Option name argument
      option = OpenStudio::Ruleset::OSArgument.makeStringArgument("option_#{option_num}", (option_num == 1))
      option.setDisplayName("Option #{option_num}")
      option.setDescription('Specify the parameter|option as found in resources\\options_lookup.tsv.')
      args << option

      # Option Apply Logic argument
      option_apply_logic = OpenStudio::Ruleset::OSArgument.makeStringArgument("option_#{option_num}_apply_logic", false)
      option_apply_logic.setDisplayName("Option #{option_num} Apply Logic")
      option_apply_logic.setDescription("Logic that specifies if the Option #{option_num} upgrade will apply based on the existing building's options. Specify one or more parameter|option as found in resources\\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.")
      args << option_apply_logic

      for cost_num in 1..num_costs_per_option

        # Option Cost Value argument
        cost_value = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("option_#{option_num}_cost_#{cost_num}_value", false)
        cost_value.setDisplayName("Option #{option_num} Cost #{cost_num} Value")
        cost_value.setDescription("Total option #{option_num} cost is the sum of all: (Cost N Value) x (Cost N Multiplier).")
        cost_value.setUnits('$')
        args << cost_value

        # Option Cost Multiplier argument
        cost_multiplier = OpenStudio::Ruleset::OSArgument.makeChoiceArgument("option_#{option_num}_cost_#{cost_num}_multiplier", cost_multiplier_choices, false)
        cost_multiplier.setDisplayName("Option #{option_num} Cost #{cost_num} Multiplier")
        cost_multiplier.setDescription("Total option #{option_num} cost is the sum of all: (Cost N Value) x (Cost N Multiplier).")
        cost_multiplier.setDefaultValue(cost_multiplier_choices[0])
        args << cost_multiplier

      end

      # Option Lifetime argument
      option_lifetime = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("option_#{option_num}_lifetime", false)
      option_lifetime.setDisplayName("Option #{option_num} Lifetime")
      option_lifetime.setDescription('The option lifetime.')
      option_lifetime.setUnits('years')
      args << option_lifetime

    end

    # Package Apply Logic argument
    package_apply_logic = OpenStudio::Ruleset::OSArgument.makeStringArgument('package_apply_logic', false)
    package_apply_logic.setDisplayName('Package Apply Logic')
    package_apply_logic.setDescription("Logic that specifies if the entire package upgrade (all options) will apply based on the existing building's options. Specify one or more parameter|option as found in resources\\options_lookup.tsv. When multiple are included, they must be separated by '||' for OR and '&&' for AND, and using parentheses as appropriate. Prefix an option with '!' for not.")
    args << package_apply_logic

    # Make integer arg to run measure [1 is run, 0 is no run]
    run_measure = OpenStudio::Ruleset::OSArgument::makeIntegerArgument('run_measure', true)
    run_measure.setDisplayName('Run Measure')
    run_measure.setDescription('integer argument to run measure [1 is run, 0 is no run]')
    run_measure.setDefaultValue(1)
    args << run_measure

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Return N/A if not selected to run
    run_measure = runner.getIntegerArgumentValue('run_measure', user_arguments)
    if run_measure == 0
      runner.registerAsNotApplicable("Run Measure set to #{run_measure}.")
      return true
    end

    upgrade_name = runner.getStringArgumentValue('upgrade_name', user_arguments)

    # Retrieve Option X argument values
    options = {}
    for option_num in 1..num_options
      if option_num == 1
        arg = runner.getStringArgumentValue("option_#{option_num}", user_arguments)
      else
        arg = runner.getOptionalStringArgumentValue("option_#{option_num}", user_arguments)
        next if not arg.is_initialized

        arg = arg.get
      end
      next if arg.strip.size == 0

      if not arg.include?('|')
        runner.registerError("Option #{option_num} is missing the '|' delimiter.")
        return false
      end
      options[option_num] = arg.strip
    end

    # Retrieve Option X Apply Logic argument values
    options_apply_logic = {}
    for option_num in 1..num_options
      arg = runner.getOptionalStringArgumentValue("option_#{option_num}_apply_logic", user_arguments)
      next if not arg.is_initialized

      arg = arg.get
      next if arg.strip.size == 0

      if not arg.include?('|')
        runner.registerError("Option #{option_num} Apply Logic is missing the '|' delimiter.")
        return false
      end
      if not options.keys.include?(option_num)
        runner.registerError("Option #{option_num} Apply Logic was provided, but a corresponding Option #{option_num} was not provided.")
        return false
      end
      options_apply_logic[option_num] = arg.strip
    end

    # Retrieve Package Apply Logic argument value
    arg = runner.getOptionalStringArgumentValue('package_apply_logic', user_arguments)
    if not arg.is_initialized
      package_apply_logic = nil
    else
      arg = arg.get
      if arg.strip.size == 0
        package_apply_logic = nil
      else
        if not arg.include?('|')
          runner.registerError("Package Apply Logic is missing the '|' delimiter.")
          return false
        end
        package_apply_logic = arg.strip
      end
    end

    # Get file/dir paths
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources'))
    characteristics_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/housing_characteristics'))
    buildstock_file = File.join(resources_dir, 'buildstock.rb')
    measures_dir = File.join(File.dirname(__FILE__), '../../measures')
    hpxml_measures_dir = File.join(File.dirname(__FILE__), '../../resources/hpxml-measures')
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')

    # Load buildstock_file
    require File.join(File.dirname(buildstock_file), File.basename(buildstock_file, File.extname(buildstock_file)))

    # Check file/dir paths exist
    check_dir_exists(resources_dir, runner)
    [measures_dir, hpxml_measures_dir].each do |dir|
      check_dir_exists(dir, runner)
    end
    check_dir_exists(characteristics_dir, runner)
    check_file_exists(lookup_file, runner)

    lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a

    # Retrieve values from BuildExistingModel
    values = get_values_from_runner_past_results(runner, 'build_existing_model')

    # Process package apply logic if provided
    apply_package_upgrade = true
    if not package_apply_logic.nil?
      # Apply this package?
      apply_package_upgrade = evaluate_logic(package_apply_logic, runner)
      if apply_package_upgrade.nil?
        return false
      end
    end

    # Get defaulted hpxml
    hpxml_path = File.expand_path('../existing.xml') # this is the defaulted hpxml
    if File.exist?(hpxml_path)
      hpxml = HPXML.new(hpxml_path: hpxml_path)
    else
      runner.registerWarning("ApplyUpgrade measure could not find '#{hpxml_path}'.")
      return true
    end

    measures = {}
    new_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new) # we want only ResStockArguments registered argument values
    if apply_package_upgrade
      system_upgrades = []

      # Obtain measures and arguments to be called
      # Process options apply logic if provided
      options.each do |option_num, option|
        parameter_name, option_name = option.split('|')

        # Apply this option?
        apply_option_upgrade = true
        if options_apply_logic.include?(option_num)
          apply_option_upgrade = evaluate_logic(options_apply_logic[option_num], runner)
          if apply_option_upgrade.nil?
            return false
          end
        end

        if not apply_option_upgrade
          runner.registerInfo("Parameter #{parameter_name}, Option #{option_name} will not be applied.")
          next
        end

        # Print this option assignment
        print_option_assignment(parameter_name, option_name, runner)

        # Register cost names/values/multipliers/lifetime for applied options; used by the UpgradeCosts measure
        register_value(runner, 'option_%02d_name_applied' % option_num, option)
        for cost_num in 1..num_costs_per_option
          cost_value = runner.getOptionalDoubleArgumentValue("option_#{option_num}_cost_#{cost_num}_value", user_arguments)
          if cost_value.nil?
            cost_value = 0.0
          end
          cost_mult_type = runner.getStringArgumentValue("option_#{option_num}_cost_#{cost_num}_multiplier", user_arguments)
          register_value(runner, "option_%02d_cost_#{cost_num}_value_to_apply" % option_num, cost_value.to_s)
          register_value(runner, "option_%02d_cost_#{cost_num}_multiplier_to_apply" % option_num, cost_mult_type)
        end
        lifetime = runner.getOptionalDoubleArgumentValue("option_#{option_num}_lifetime", user_arguments)
        if lifetime.nil?
          lifetime = 0.0
        end
        register_value(runner, 'option_%02d_lifetime_to_apply' % option_num, lifetime.to_s)

        # Get measure name and arguments associated with the option
        options_measure_args, _errors = get_measure_args_from_option_names(lookup_csv_data, [option_name], parameter_name, lookup_file, runner)
        options_measure_args[option_name].each do |measure_subdir, args_hash|
          system_upgrades = get_system_upgrades(hpxml, system_upgrades, args_hash)
          update_args_hash(measures, measure_subdir, args_hash, false)
        end
      end

      if halt_workflow(runner, measures)
        return false
      end

      measures['ResStockArguments'] = [{}] if !measures.keys.include?('ResStockArguments') # upgrade is via another measure

      # Add measure arguments from existing building if needed
      parameters = get_parameters_ordered_from_options_lookup_tsv(lookup_csv_data, characteristics_dir)
      measures.keys.each do |measure_subdir|
        parameters.each do |parameter_name|
          existing_option_name = values[OpenStudio::toUnderscoreCase(parameter_name)]

          options_measure_args, _errors = get_measure_args_from_option_names(lookup_csv_data, [existing_option_name], parameter_name, lookup_file, runner)
          options_measure_args[existing_option_name].each do |measure_subdir2, args_hash|
            next if measure_subdir != measure_subdir2

            # Append any new arguments
            new_args_hash = {}
            args_hash.each do |k, v|
              next if measures[measure_subdir][0].has_key?(k)

              new_args_hash[k] = v
            end
            update_args_hash(measures, measure_subdir, new_args_hash, false)
          end
        end
      end

      # Get the absolute paths relative to this meta measure in the run directory
      if not apply_measures(measures_dir, { 'ResStockArguments' => measures['ResStockArguments'] }, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', nil)
        return false
      end
    end # apply_package_upgrade

    # Register the upgrade name
    register_value(runner, 'upgrade_name', upgrade_name)

    if halt_workflow(runner, measures)
      return false
    end

    # Initialize measure keys with hpxml_path arguments
    hpxml_path = File.expand_path('../upgraded.xml')
    measures['BuildResidentialHPXML'] = [{ 'hpxml_path' => hpxml_path }]
    measures['BuildResidentialScheduleFile'] = [{ 'hpxml_path' => hpxml_path, 'hpxml_output_path' => hpxml_path }]

    new_runner.result.stepValues.each do |step_value|
      value = get_value_from_workflow_step_value(step_value)
      next if value == ''

      measures['BuildResidentialHPXML'][0][step_value.name] = value
    end

    # Set additional properties
    additional_properties = []
    ['ceiling_insulation_r'].each do |arg_name|
      arg_value = measures['ResStockArguments'][0][arg_name]
      additional_properties << "#{arg_name}=#{arg_value}"
    end
    measures['BuildResidentialHPXML'][0]['additional_properties'] = additional_properties.join('|') unless additional_properties.empty?

    # Retain HVAC capacities

    capacities = get_system_capacities(hpxml, system_upgrades)

    unless capacities['heating_system_heating_capacity'].nil?
      measures['BuildResidentialHPXML'][0]['heating_system_heating_capacity'] = capacities['heating_system_heating_capacity']
    end

    unless capacities['heating_system_2_heating_capacity'].nil?
      measures['BuildResidentialHPXML'][0]['heating_system_2_heating_capacity'] = capacities['heating_system_2_heating_capacity']
    end

    unless capacities['cooling_system_cooling_capacity'].nil?
      measures['BuildResidentialHPXML'][0]['cooling_system_cooling_capacity'] = capacities['cooling_system_cooling_capacity']
    end

    unless capacities['heat_pump_heating_capacity'].nil?
      measures['BuildResidentialHPXML'][0]['heat_pump_heating_capacity'] = capacities['heat_pump_heating_capacity']
    end

    unless capacities['heat_pump_cooling_capacity'].nil?
      measures['BuildResidentialHPXML'][0]['heat_pump_cooling_capacity'] = capacities['heat_pump_cooling_capacity']
    end

    unless capacities['heat_pump_backup_heating_capacity'].nil?
      measures['BuildResidentialHPXML'][0]['heat_pump_backup_heating_capacity'] = capacities['heat_pump_backup_heating_capacity']
    end

    # Get software program used and version
    measures['BuildResidentialHPXML'][0]['software_info_program_used'] = 'ResStock'
    measures['BuildResidentialHPXML'][0]['software_info_program_version'] = Version::ResStock_Version

    # Get registered values and pass them to BuildResidentialHPXML
    measures['BuildResidentialHPXML'][0]['simulation_control_timestep'] = values['simulation_control_timestep']
    if !values['simulation_control_run_period_begin_month'].nil? && !values['simulation_control_run_period_begin_day_of_month'].nil? && !values['simulation_control_run_period_end_month'].nil? && !values['simulation_control_run_period_end_day_of_month'].nil?
      begin_month = "#{Date::ABBR_MONTHNAMES[values['simulation_control_run_period_begin_month']]}"
      begin_day = values['simulation_control_run_period_begin_day_of_month']
      end_month = "#{Date::ABBR_MONTHNAMES[values['simulation_control_run_period_end_month']]}"
      end_day = values['simulation_control_run_period_end_day_of_month']
      measures['BuildResidentialHPXML'][0]['simulation_control_run_period'] = "#{begin_month} #{begin_day} - #{end_month} #{end_day}"
    end
    measures['BuildResidentialHPXML'][0]['simulation_control_run_period_calendar_year'] = values['simulation_control_run_period_calendar_year']

    # Emissions
    measures['BuildResidentialHPXML'][0]['emissions_scenario_names'] = values['emissions_scenario_names']
    measures['BuildResidentialHPXML'][0]['emissions_types'] = values['emissions_types']
    measures['BuildResidentialHPXML'][0]['emissions_electricity_units'] = values['emissions_electricity_units']
    measures['BuildResidentialHPXML'][0]['emissions_electricity_values_or_filepaths'] = values['emissions_electricity_values_or_filepaths']
    measures['BuildResidentialHPXML'][0]['emissions_fossil_fuel_units'] = values['emissions_fossil_fuel_units']
    measures['BuildResidentialHPXML'][0]['emissions_natural_gas_values'] = values['emissions_natural_gas_values']
    measures['BuildResidentialHPXML'][0]['emissions_propane_values'] = values['emissions_propane_values']
    measures['BuildResidentialHPXML'][0]['emissions_fuel_oil_values'] = values['emissions_fuel_oil_values']
    measures['BuildResidentialHPXML'][0]['emissions_wood_values'] = values['emissions_wood_values']

    # Utility Bills
    measures['BuildResidentialHPXML'][0]['utility_bill_scenario_names'] = values['utility_bill_scenario_names']
    measures['BuildResidentialHPXML'][0]['utility_bill_electricity_fixed_charges'] = values['utility_bill_electricity_fixed_charges']
    measures['BuildResidentialHPXML'][0]['utility_bill_electricity_marginal_rates'] = values['utility_bill_electricity_marginal_rates']
    measures['BuildResidentialHPXML'][0]['utility_bill_natural_gas_fixed_charges'] = values['utility_bill_natural_gas_fixed_charges']
    measures['BuildResidentialHPXML'][0]['utility_bill_natural_gas_marginal_rates'] = values['utility_bill_natural_gas_marginal_rates']
    measures['BuildResidentialHPXML'][0]['utility_bill_propane_fixed_charges'] = values['utility_bill_propane_fixed_charges']
    measures['BuildResidentialHPXML'][0]['utility_bill_propane_marginal_rates'] = values['utility_bill_propane_marginal_rates']
    measures['BuildResidentialHPXML'][0]['utility_bill_fuel_oil_fixed_charges'] = values['utility_bill_fuel_oil_fixed_charges']
    measures['BuildResidentialHPXML'][0]['utility_bill_fuel_oil_marginal_rates'] = values['utility_bill_fuel_oil_marginal_rates']
    measures['BuildResidentialHPXML'][0]['utility_bill_wood_fixed_charges'] = values['utility_bill_wood_fixed_charges']
    measures['BuildResidentialHPXML'][0]['utility_bill_wood_marginal_rates'] = values['utility_bill_wood_marginal_rates']
    measures['BuildResidentialHPXML'][0]['utility_bill_pv_compensation_types'] = values['utility_bill_pv_compensation_types']
    measures['BuildResidentialHPXML'][0]['utility_bill_pv_net_metering_annual_excess_sellback_rate_types'] = values['utility_bill_pv_net_metering_annual_excess_sellback_rate_types']
    measures['BuildResidentialHPXML'][0]['utility_bill_pv_net_metering_annual_excess_sellback_rates'] = values['utility_bill_pv_net_metering_annual_excess_sellback_rates']
    measures['BuildResidentialHPXML'][0]['utility_bill_pv_feed_in_tariff_rates'] = values['utility_bill_pv_feed_in_tariff_rates']
    measures['BuildResidentialHPXML'][0]['utility_bill_pv_monthly_grid_connection_fee_units'] = values['utility_bill_pv_monthly_grid_connection_fee_units']
    measures['BuildResidentialHPXML'][0]['utility_bill_pv_monthly_grid_connection_fees'] = values['utility_bill_pv_monthly_grid_connection_fees']

    # Get registered values and pass them to BuildResidentialScheduleFile
    measures['BuildResidentialScheduleFile'][0]['schedules_random_seed'] = values['building_id']
    measures['BuildResidentialScheduleFile'][0]['output_csv_path'] = File.expand_path('../schedules.csv')

    # Specify measures to run
    measures['BuildResidentialHPXML'][0]['apply_defaults'] = true
    measures_to_apply_hash = { hpxml_measures_dir => { 'BuildResidentialHPXML' => measures['BuildResidentialHPXML'], 'BuildResidentialScheduleFile' => measures['BuildResidentialScheduleFile'] },
                               measures_dir => {} }

    upgrade_measures = measures.keys - ['ResStockArguments', 'BuildResidentialHPXML', 'BuildResidentialScheduleFile']
    upgrade_measures.each do |upgrade_measure|
      measures_to_apply_hash[measures_dir][upgrade_measure] = measures[upgrade_measure]
    end
    measures_to_apply_hash.each_with_index do |(dir, measures_to_apply), i|
      next if measures_to_apply.empty?

      osw_out = 'upgraded.osw'
      osw_out = "upgraded#{i + 1}.osw" if i > 0
      next unless not apply_measures(dir, measures_to_apply, new_runner, model, true, 'OpenStudio::Measure::ModelMeasure', osw_out)

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

    # Copy upgraded.xml to home.xml for downstream HPXMLtoOpenStudio
    # This will overwrite home.xml from BuildExistingModel
    # We need upgraded.xml (and not just home.xml) for UpgradeCosts
    in_path = File.expand_path('../home.xml')
    FileUtils.cp(hpxml_path, in_path)

    return true
  end

  def halt_workflow(runner, measures)
    if measures.size == 0
      # Upgrade not applied; don't re-run existing home simulation
      runner.haltWorkflow('Invalid')
      return true
    end

    return false
  end

  def get_system_upgrades(hpxml, system_upgrades, args_hash)
    args_hash.keys.each do |arg|
      # Detect whether we are upgrading the heating system
      if arg.start_with?('heating_system_') && (not arg.start_with?('heating_system_2_'))
        hpxml.heating_systems.each do |heating_system|
          next unless heating_system.primary_system

          system_upgrades << heating_system.id
        end
      end

      # Detect whether we are upgrading the secondary heating system
      if arg.start_with?('heating_system_2_')
        hpxml.heating_systems.each do |heating_system|
          next if heating_system.primary_system

          system_upgrades << heating_system.id
        end
      end

      # Detect whether we are upgrading the cooling system
      if arg.start_with?('cooling_system_')
        hpxml.cooling_systems.each do |cooling_system|
          system_upgrades << cooling_system.id
        end
      end

      # Detect whether we are upgrading the heat pump
      next unless arg.start_with?('heat_pump_')

      hpxml.heat_pumps.each do |heat_pump|
        system_upgrades << heat_pump.id
      end
    end

    return system_upgrades
  end

  def get_system_capacities(hpxml, system_upgrades)
    capacities = {}

    hpxml.heating_systems.each do |heating_system|
      next unless heating_system.primary_system
      next if system_upgrades.include?(heating_system.id)

      capacities['heating_system_heating_capacity'] = heating_system.heating_capacity
    end

    hpxml.heating_systems.each do |heating_system|
      next if heating_system.primary_system
      next if system_upgrades.include?(heating_system.id)

      capacities['heating_system_2_heating_capacity'] = heating_system.heating_capacity
    end

    hpxml.cooling_systems.each do |cooling_system|
      next if system_upgrades.include?(cooling_system.id)

      capacities['cooling_system_cooling_capacity'] = cooling_system.cooling_capacity
    end

    hpxml.heat_pumps.each do |heat_pump|
      next if system_upgrades.include?(heat_pump.id)

      capacities['heat_pump_heating_capacity'] = heat_pump.heating_capacity
      capacities['heat_pump_cooling_capacity'] = heat_pump.cooling_capacity
      capacities['heat_pump_backup_heating_capacity'] = heat_pump.backup_heating_capacity
    end

    return capacities
  end
end

# register the measure to be used by the application
ApplyUpgrade.new.registerWithApplication
