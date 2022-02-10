# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
if File.exist? File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources/hpxml-measures/HPXMLtoOpenStudio/resources')) # Hack to run ResStock on AWS
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../lib/resources/hpxml-measures/HPXMLtoOpenStudio/resources'))
elsif File.exist? File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources')) # Hack to run ResStock unit tests locally
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources'))
elsif File.exist? File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, 'HPXMLtoOpenStudio/resources') # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, 'HPXMLtoOpenStudio/resources')
end
require File.join(resources_path, 'meta_measure')
require File.join(resources_path, 'unit_conversions')

require_relative '../ApplyUpgrade/resources/constants'

# start the measure
class UpgradeCosts < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Upgrade Costs'
  end

  # human readable description
  def description
    return 'Measure that calculates upgrade costs.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Multiplies cost value by cost multiplier.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  def num_options
    return Constants.NumApplyUpgradeOptions # Synced with ApplyUpgrade measure
  end

  def num_costs_per_option
    return Constants.NumApplyUpgradesCostsPerOption # Synced with ApplyUpgrade measure
  end

  def cost_multiplier_choices
    return Constants.CostMultiplierChoices # Synced with ApplyUpgrade measure
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find OpenStudio model.')
      return false
    end
    model = model.get

    # use the built-in error checking (need model)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Retrieve values from ReportHPXMLOutput
    hpxml = get_values_from_runner_past_results(runner, 'report_hpxml_output')

    # Report cost multipliers
    cost_multiplier_choices.each do |cost_mult_type|
      next if cost_mult_type.empty?
      next if cost_mult_type.include?('Fixed')

      cost_mult_type_str = OpenStudio::toUnderscoreCase(cost_mult_type)
      cost_mult = get_cost_multiplier(cost_mult_type, hpxml)
      cost_mult = cost_mult.round(2)
      register_value(runner, cost_mult_type_str, cost_mult)
    end

    # Retrieve values from ApplyUpgrade
    values = get_values_from_runner_past_results(runner, 'apply_upgrade')

    # UPGRADE COSTS
    upgrade_cost_name = 'upgrade_cost_usd'

    # Get upgrade cost value/multiplier pairs and lifetimes from the upgrade measure
    has_costs = false
    option_cost_pairs = {}
    option_names = {}
    option_lifetimes = {}
    for option_num in 1..num_options # Sync with ApplyUpgrade measure
      option_cost_pairs[option_num] = []
      option_names[option_num] = nil
      option_lifetimes[option_num] = nil
      for cost_num in 1..num_costs_per_option # Sync with ApplyUpgrade measure
        cost_value = values["option_%02d_cost_#{cost_num}_value_to_apply" % option_num]
        next if cost_value.nil?

        cost_mult_type = values["option_%02d_cost_#{cost_num}_multiplier_to_apply" % option_num]
        next if cost_mult_type.nil?

        has_costs = true
        option_cost_pairs[option_num] << [cost_value.to_f, cost_mult_type]
      end
      name = values['option_%02d_name_applied' % option_num]
      lifetime = values['option_%02d_lifetime_to_apply' % option_num]

      option_names[option_num] = name
      option_lifetimes[option_num] = lifetime.to_f if !lifetime.nil?
    end

    if not has_costs
      register_value(runner, upgrade_cost_name, '')
      runner.registerInfo("Registering (blank) for #{upgrade_cost_name}.")
      return true
    end

    # Obtain cost multiplier values and calculate upgrade costs
    upgrade_cost = 0.0
    option_cost_pairs.keys.each do |option_num|
      option_cost = 0.0
      option_cost_pairs[option_num].each do |cost_value, cost_mult_type|
        cost_mult = get_cost_multiplier(cost_mult_type, hpxml)
        total_cost = cost_value * cost_mult
        next if total_cost == 0

        option_cost += total_cost
        runner.registerInfo("Upgrade cost addition: $#{cost_value} x #{cost_mult} [#{cost_mult_type}] = #{total_cost}.")
      end
      upgrade_cost += option_cost

      # Save option cost/name/lifetime to results.csv
      next unless option_cost != 0

      option_cost = option_cost.round(2)
      option_cost_name = 'option_%02d_cost_usd' % option_num
      register_value(runner, option_cost_name, option_cost)
      runner.registerInfo("Registering #{option_cost} for #{option_cost_name}.")

      name = option_names[option_num]
      option_name_name = 'option_%02d_name' % option_num
      register_value(runner, option_name_name, name)
      runner.registerInfo("Registering #{name} for #{option_name_name}.")
      next unless (not option_lifetimes[option_num].nil?) && (option_lifetimes[option_num] != 0)

      lifetime = option_lifetimes[option_num].round(2)
      option_lifetime_name = 'option_%02d_lifetime_yrs' % option_num
      register_value(runner, option_lifetime_name, lifetime)
      runner.registerInfo("Registering #{lifetime} for #{option_lifetime_name}.")
    end
    upgrade_cost = upgrade_cost.round(2)
    register_value(runner, upgrade_cost_name, upgrade_cost)
    runner.registerInfo("Registering #{upgrade_cost} for #{upgrade_cost_name}.")

    return true
  end

  def get_cost_multiplier(cost_mult_type, hpxml)
    cost_mult = 0.0
    if cost_mult_type == 'Fixed (1)'
      cost_mult += 1.0
    elsif cost_mult_type == 'Wall Area, Above-Grade, Conditioned (ft^2)'
      cost_mult += hpxml['enclosure_wall_area_thermal_boundary_ft_2']
    elsif cost_mult_type == 'Wall Area, Above-Grade, Exterior (ft^2)'
      cost_mult += hpxml['enclosure_wall_area_exterior_ft_2']
    elsif cost_mult_type == 'Wall Area, Below-Grade (ft^2)'
      cost_mult += hpxml['enclosure_foundation_wall_area_exterior_ft_2']
    elsif cost_mult_type == 'Floor Area, Conditioned (ft^2)'
      cost_mult += hpxml['enclosure_floor_area_conditioned_ft_2']
    elsif cost_mult_type == 'Floor Area, Lighting (ft^2)'
      cost_mult += hpxml['enclosure_floor_area_lighting_ft_2']
    elsif cost_mult_type == 'Floor Area, Attic (ft^2)'
      cost_mult += hpxml['enclosure_ceiling_area_thermal_boundary_ft_2']
    elsif cost_mult_type == 'Roof Area (ft^2)'
      cost_mult += hpxml['enclosure_roof_area_ft_2']
    elsif cost_mult_type == 'Window Area (ft^2)'
      cost_mult += hpxml['enclosure_window_area_ft_2']
    elsif cost_mult_type == 'Door Area (ft^2)'
      cost_mult += hpxml['enclosure_door_area_ft_2']
    elsif cost_mult_type == 'Duct Unconditioned Surface Area (ft^2)'
      cost_mult += hpxml['enclosure_duct_area_unconditioned_ft_2']
    elsif cost_mult_type == 'Rim Joist Area, Above-Grade, Exterior (ft^2)'
      cost_mult += hpxml['enclosure_rim_joist_area_ft_2']
    elsif cost_mult_type == 'Slab Perimeter, Exposed, Conditioned (ft)'
      cost_mult += hpxml['enclosure_slab_exposed_perimeter_thermal_boundary_ft']
    elsif cost_mult_type == 'Size, Heating System Primary (kBtu/h)'
      if hpxml.keys.include?('primary_systems_heating_capacity_btu_h')
        cost_mult += UnitConversions.convert(hpxml['primary_systems_heating_capacity_btu_h'], 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Size, Heating System Secondary (kBtu/h)'
      if hpxml.keys.include?('secondary_systems_heating_capacity_btu_h')
        cost_mult += UnitConversions.convert(hpxml['secondary_systems_heating_capacity_btu_h'], 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Size, Cooling System Primary (kBtu/h)'
      if hpxml.keys.include?('primary_systems_cooling_capacity_btu_h')
        cost_mult += UnitConversions.convert(hpxml['primary_systems_cooling_capacity_btu_h'], 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Size, Heat Pump Backup Primary (kBtu/h)'
      if hpxml.keys.include?('primary_systems_heat_pump_backup_capacity_btu_h')
        cost_mult += UnitConversions.convert(hpxml['primary_systems_heat_pump_backup_capacity_btu_h'], 'btu/hr', 'kbtu/hr')
      end
    elsif cost_mult_type == 'Size, Water Heater (gal)'
      cost_mult += hpxml['systems_water_heater_tank_volume_gal']
    elsif cost_mult_type == 'Flow Rate, Mechanical Ventilation (cfm)'
      cost_mult += hpxml['systems_mechanical_ventilation_flow_rate_cfm']
    end
    return cost_mult
  end # end get_cost_multiplier
end

# register the measure to be used by the application
UpgradeCosts.new.registerWithApplication
