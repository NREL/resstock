# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require 'openstudio'

require_relative 'resources/constants'

# in addition to the above requires, this measure is expected to run in an
# environment with resstock/resources/buildstock.rb loaded

# start the measure
class ApplyUpgrade < OpenStudio::Ruleset::ModelUserScript
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
    return Constants.NumApplyUpgradeOptions # Synced with SimulationOutputReport measure
  end

  def num_costs_per_option
    return Constants.NumApplyUpgradesCostsPerOption # Synced with SimulationOutputReport measure
  end

  # define the arguments that the user will input
  def arguments(model)
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
        choices = [
          '',
          'Fixed (1)',
          'Wall Area, Above-Grade, Conditioned (ft^2)',
          'Wall Area, Above-Grade, Exterior (ft^2)',
          'Wall Area, Below-Grade (ft^2)',
          'Floor Area, Conditioned (ft^2)',
          'Floor Area, Attic (ft^2)',
          'Floor Area, Lighting (ft^2)',
          'Roof Area (ft^2)',
          'Window Area (ft^2)',
          'Door Area (ft^2)',
          'Duct Unconditioned Surface Area (ft^2)',
          'Size, Heating System (kBtu/h)',
          'Size, Heating Supplemental System (kBtu/h)',
          'Size, Cooling System (kBtu/h)',
          'Size, Water Heater (gal)',
        ]
        cost_multiplier = OpenStudio::Ruleset::OSArgument.makeChoiceArgument("option_#{option_num}_cost_#{cost_num}_multiplier", choices, false)
        cost_multiplier.setDisplayName("Option #{option_num} Cost #{cost_num} Multiplier")
        cost_multiplier.setDescription("Total option #{option_num} cost is the sum of all: (Cost N Value) x (Cost N Multiplier).")
        cost_multiplier.setDefaultValue(choices[0])
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
    check_dir_exists(characteristics_dir, runner)

    # Retrieve workflow_json from BuildExistingModel measure if provided
    workflow_json = get_value_from_runner_past_results(runner, 'workflow_json', 'build_existing_model', false)
    if not workflow_json.nil?
      workflow_json = File.join(resources_dir, workflow_json)
    end

    # Process package apply logic if provided
    apply_package_upgrade = true
    if not package_apply_logic.nil?
      # Apply this package?
      apply_package_upgrade = evaluate_logic(package_apply_logic, runner)
      if apply_package_upgrade.nil?
        return false
      end
    end

    upgrade_heating_system = false
    upgrade_supp_heating_system = false
    upgrade_cooling_system = false
    upgrade_heat_pump = false

    measures = {}
    if apply_package_upgrade

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

        # Register cost values/multipliers/lifetime for applied options; used by the SimulationOutputReport measure
        for cost_num in 1..num_costs_per_option
          cost_value = runner.getOptionalDoubleArgumentValue("option_#{option_num}_cost_#{cost_num}_value", user_arguments)
          if cost_value.nil?
            cost_value = 0.0
          end
          cost_mult = runner.getStringArgumentValue("option_#{option_num}_cost_#{cost_num}_multiplier", user_arguments)
          register_value(runner, "option_%02d_cost_#{cost_num}_value_to_apply" % option_num, cost_value.to_s)
          register_value(runner, "option_%02d_cost_#{cost_num}_multiplier_to_apply" % option_num, cost_mult)
        end
        lifetime = runner.getOptionalDoubleArgumentValue("option_#{option_num}_lifetime", user_arguments)
        if lifetime.nil?
          lifetime = 0.0
        end
        register_value(runner, 'option_%02d_lifetime_to_apply' % option_num, lifetime.to_s)

        # Check file/dir paths exist
        check_file_exists(lookup_file, runner)

        # Get measure name and arguments associated with the option
        options_measure_args = get_measure_args_from_option_names(lookup_file, [option_name], parameter_name, runner)
        options_measure_args[option_name].each do |measure_subdir, args_hash|
          # Detect whether we are upgrading the heating system
          args_hash.each do |arg, value|
            if arg.include?('heating_system_type') || arg.include?('heating_system_fuel') || arg.include?('heating_system_heating_efficiency') || arg.include?('heating_system_fraction_heat_load_served')
              upgrade_heating_system = true
            end
          end

          # Detect whether we are upgrading the supplemental heating system
          args_hash.each do |arg, value|
            if arg.include?('heating_system_type_2') || arg.include?('heating_system_fuel_2') || arg.include?('heating_system_heating_efficiency_2') || arg.include?('heating_system_fraction_heat_load_served_2')
              upgrade_supp_heating_system = true
            end
          end

          # Detect whether we are upgrading the cooling system
          args_hash.each do |arg, value|
            if arg.include?('cooling_system_type') || arg.include?('cooling_system_cooling_efficiency') || arg.include?('cooling_system_fraction_cool_load_served')
              upgrade_cooling_system = true
            end
          end

          # Detect whether we are upgrading the heat pump
          args_hash.each do |arg, value|
            if arg.include?('heat_pump_type') || arg.include?('heat_pump_heating_efficiency_hspf') || arg.include?('heat_pump_heating_efficiency_cop') || arg.include?('heat_pump_cooling_efficiency_seer') || arg.include?('heat_pump_cooling_efficiency_eer') || arg.include?('heat_pump_fraction_heat_load_served') || arg.include?('heat_pump_fraction_cool_load_served')
              upgrade_heat_pump = true
            end
          end

          update_args_hash(measures, measure_subdir, args_hash, add_new = false)
        end
      end

      # Add measure arguments from existing building if needed
      parameters = get_parameters_ordered_from_options_lookup_tsv(lookup_file, characteristics_dir)
      measures.keys.each do |measure_subdir|
        parameters.each do |parameter_name|
          existing_option_name = get_value_from_runner_past_results(runner, parameter_name, 'build_existing_model')

          options_measure_args = get_measure_args_from_option_names(lookup_file, [existing_option_name], parameter_name, runner)
          options_measure_args[existing_option_name].each do |measure_subdir2, args_hash|
            next if measure_subdir != measure_subdir2

            # Append any new arguments
            new_args_hash = {}
            args_hash.each do |k, v|
              next if measures[measure_subdir][0].has_key?(k)

              new_args_hash[k] = v
            end
            update_args_hash(measures, measure_subdir, new_args_hash, add_new = false)
          end
        end
      end

      # Get the absolute paths relative to this meta measure in the run directory
      new_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
      if not apply_child_measures(measures_dir, { 'ResStockArguments' => measures['ResStockArguments'] }, new_runner, model, workflow_json, 'measures-upgrade.osw', true)
        return false
      end

      measures['BuildResidentialHPXML'] = [{ 'hpxml_path' => File.expand_path('../upgraded.xml') }]

      new_runner.result.stepValues.each do |step_value|
        value = get_value_from_workflow_step_value(step_value)
        next if value == ''

        measures['BuildResidentialHPXML'][0][step_value.name] = value
      end

      measures['HPXMLtoOpenStudio'] = [{ 'hpxml_path' => File.expand_path('../upgraded.xml') }]

      # Use generated schedules from the base building
      schedules_type = measures['BuildResidentialHPXML'][0]['schedules_type']
      if schedules_type == 'stochastic' # avoid re-running the stochastic schedule generator
        measures['BuildResidentialHPXML'][0]['schedules_type'] = 'user-specified'
        measures['BuildResidentialHPXML'][0]['schedules_path'] = File.expand_path('../schedules.csv')
      end

      # Retain HVAC capacities
      if (not upgrade_heating_system) || (not upgrade_supp_heating_system) || (not upgrade_cooling_system) || (not upgrade_heat_pump)
        hpxml_path = File.expand_path('../in.xml') # this is the defaulted hpxml
        hpxml = HPXML.new(hpxml_path: hpxml_path)
      end

      unless upgrade_heating_system
        hpxml.heating_systems.each do |heating_system|
          next if heating_system.heating_system_type != measures['BuildResidentialHPXML'][0]['heating_system_type']
          next if heating_system.heating_system_fuel != measures['BuildResidentialHPXML'][0]['heating_system_fuel']
          next if heating_system.fraction_heat_load_served != measures['BuildResidentialHPXML'][0]['heating_system_fraction_heat_load_served']

          # if we made it this far, this is the correct heating_system
          measures['BuildResidentialHPXML'][0]['heating_system_heating_capacity'] = heating_system.heating_capacity
        end
      end

      unless upgrade_supp_heating_system
        hpxml.heating_systems.each do |heating_system|
          next if heating_system.heating_system_type != measures['BuildResidentialHPXML'][0]['heating_system_type_2']
          next if heating_system.heating_system_fuel != measures['BuildResidentialHPXML'][0]['heating_system_fuel_2']
          next if heating_system.fraction_heat_load_served != measures['BuildResidentialHPXML'][0]['heating_system_fraction_heat_load_served_2']

          # if we made it this far, this is the correct supplemental heating_system
          measures['BuildResidentialHPXML'][0]['heating_system_heating_capacity_2'] = heating_system.heating_capacity
        end
      end

      unless upgrade_cooling_system
        hpxml.cooling_systems.each do |cooling_system|
          next if cooling_system.cooling_system_type != measures['BuildResidentialHPXML'][0]['cooling_system_type']
          next if cooling_system.fraction_cool_load_served != measures['BuildResidentialHPXML'][0]['cooling_system_fraction_cool_load_served']

          # if we made it this far, this is the correct cooling_system
          measures['BuildResidentialHPXML'][0]['cooling_system_cooling_capacity'] = cooling_system.cooling_capacity
        end
      end

      unless upgrade_heat_pump
        hpxml.heat_pumps.each do |heat_pump|
          next if heat_pump.heat_pump_type != measures['BuildResidentialHPXML'][0]['heat_pump_type']
          next if heat_pump.fraction_heat_load_served != measures['BuildResidentialHPXML'][0]['heat_pump_fraction_heat_load_served']
          next if heat_pump.fraction_cool_load_served != measures['BuildResidentialHPXML'][0]['heat_pump_fraction_cool_load_served']

          # if we made it this far, this is the correct heat_pump
          unless heat_pump.heating_capacity.nil? # heat pump provides heating
            measures['BuildResidentialHPXML'][0]['heat_pump_heating_capacity'] = heat_pump.heating_capacity
          end
          unless heat_pump.cooling_capacity.nil? # heat pump provides cooling
            measures['BuildResidentialHPXML'][0]['heat_pump_cooling_capacity'] = heat_pump.cooling_capacity
          end
          unless heat_pump.backup_heating_capacity.nil? # heat pump provides backup heating
            measures['BuildResidentialHPXML'][0]['heat_pump_backup_heating_capacity'] = heat_pump.backup_heating_capacity
          end
        end
      end

      # Get software program used and version
      measures['BuildResidentialHPXML'][0]['software_program_used'] = software_program_used
      measures['BuildResidentialHPXML'][0]['software_program_version'] = software_program_version

      # Get registered values from ResidentialSimulationControls and pass them to BuildResidentialHPXML
      simulation_control_timestep = get_value_from_runner_past_results(runner, 'simulation_control_timestep', 'build_existing_model', false)
      simulation_control_run_period_begin_month = get_value_from_runner_past_results(runner, 'simulation_control_run_period_begin_month', 'build_existing_model', false)
      simulation_control_run_period_begin_day_of_month = get_value_from_runner_past_results(runner, 'simulation_control_run_period_begin_day_of_month', 'build_existing_model', false)
      simulation_control_run_period_end_month = get_value_from_runner_past_results(runner, 'simulation_control_run_period_end_month', 'build_existing_model', false)
      simulation_control_run_period_end_day_of_month = get_value_from_runner_past_results(runner, 'simulation_control_run_period_end_day_of_month', 'build_existing_model', false)
      simulation_control_run_period_calendar_year = get_value_from_runner_past_results(runner, 'simulation_control_run_period_calendar_year', 'build_existing_model', false)
      measures['BuildResidentialHPXML'][0]['simulation_control_timestep'] = simulation_control_timestep
      measures['BuildResidentialHPXML'][0]['simulation_control_run_period_begin_month'] = simulation_control_run_period_begin_month
      measures['BuildResidentialHPXML'][0]['simulation_control_run_period_begin_day_of_month'] = simulation_control_run_period_begin_day_of_month
      measures['BuildResidentialHPXML'][0]['simulation_control_run_period_end_month'] = simulation_control_run_period_end_month
      measures['BuildResidentialHPXML'][0]['simulation_control_run_period_end_day_of_month'] = simulation_control_run_period_end_day_of_month
      measures['BuildResidentialHPXML'][0]['simulation_control_run_period_calendar_year'] = simulation_control_run_period_calendar_year

      # Remove the existing generated_files folder alongside the run folder; if not, getExternalFile returns false for some reason
      FileUtils.rm_rf(File.expand_path('../../generated_files')) if File.exist?(File.expand_path('../../generated_files'))

      if not apply_child_measures(hpxml_measures_dir, { 'BuildResidentialHPXML' => measures['BuildResidentialHPXML'], 'HPXMLtoOpenStudio' => measures['HPXMLtoOpenStudio'] }, new_runner, model, workflow_json, nil, true)
        return false
      end

    end # apply_package_upgrade

    # Register the upgrade name
    register_value(runner, 'upgrade_name', upgrade_name)

    if measures.size == 0
      # Upgrade not applied; don't re-run existing home simulation
      runner.haltWorkflow('Invalid')
      return false
    end

    return true
  end
end

# register the measure to be used by the application
ApplyUpgrade.new.registerWithApplication
