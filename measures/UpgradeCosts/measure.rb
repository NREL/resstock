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
else
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), '../HPXMLtoOpenStudio/resources'))
end
require File.join(resources_path, 'meta_measure')
require File.join(resources_path, 'hpxml')

require_relative 'resources/constants'

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
    return Constants.NumApplyUpgradeOptions # Synced with SimulationOutputReport measure
  end

  def num_costs_per_option
    return Constants.NumApplyUpgradesCostsPerOption # Synced with SimulationOutputReport measure
  end

  def cost_mult_types
    return {
      'Wall Area, Above-Grade, Conditioned (ft^2)' => 'wall_area_above_grade_conditioned_ft_2',
      'Wall Area, Above-Grade, Exterior (ft^2)' => 'wall_area_above_grade_exterior_ft_2',
      'Wall Area, Below-Grade (ft^2)' => 'wall_area_below_grade_ft_2',
      'Floor Area, Conditioned (ft^2)' => 'floor_area_conditioned_ft_2',
      'Floor Area, Attic (ft^2)' => 'floor_area_attic_ft_2',
      'Floor Area, Lighting (ft^2)' => 'floor_area_lighting_ft_2',
      'Roof Area (ft^2)' => 'roof_area_ft_2',
      'Window Area (ft^2)' => 'window_area_ft_2',
      'Door Area (ft^2)' => 'door_area_ft_2',
      'Duct Surface Area (ft^2)' => 'duct_surface_area_ft_2',
      'Size, Heating System (kBtu/h)' => 'size_heating_system_kbtu_h',
      'Size, Cooling System (kBtu/h)' => 'size_cooling_system_kbtu_h',
      'Size, Water Heater (gal)' => 'size_water_heater_gal'
    }
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    # use the built-in error checking (need model)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    hpxml_path = File.expand_path('../existing.xml')
    hpxml = HPXML.new(hpxml_path: hpxml_path)

    # Report cost multipliers
    cost_mult_types.each do |cost_mult_type, cost_mult_type_str|
      cost_mult = get_cost_multiplier(cost_mult_type, hpxml, runner)
      cost_mult = cost_mult.round(2)
      register_value(runner, cost_mult_type_str, cost_mult)
    end

    # UPGRADE NAME
    upgrade_name = get_value_from_runner_past_results(runner, 'upgrade_name', 'apply_upgrade', false)
    if upgrade_name.nil?
      register_value(runner, 'upgrade_name', '')
      runner.registerInfo('Registering (blank) for upgrade_name.')
    else
      register_value(runner, 'upgrade_name', upgrade_name)
      runner.registerInfo("Registering #{upgrade_name} for upgrade_name.")
    end

    # UPGRADE COSTS

    upgrade_cost_name = 'upgrade_cost_usd'

    # Get upgrade cost value/multiplier pairs and lifetimes from the upgrade measure
    has_costs = false
    option_cost_pairs = {}
    option_lifetimes = {}
    for option_num in 1..num_options # Sync with ApplyUpgrade measure
      option_cost_pairs[option_num] = []
      option_lifetimes[option_num] = nil
      for cost_num in 1..num_costs_per_option # Sync with ApplyUpgrade measure
        cost_value = get_value_from_runner_past_results(runner, "option_%02d_cost_#{cost_num}_value_to_apply" % option_num, 'apply_upgrade', false)
        next if cost_value.nil?

        cost_mult_type = get_value_from_runner_past_results(runner, "option_%02d_cost_#{cost_num}_multiplier_to_apply" % option_num, 'apply_upgrade', false)
        next if cost_mult_type.nil?

        has_costs = true
        option_cost_pairs[option_num] << [cost_value.to_f, cost_mult_type]
      end
      lifetime = get_value_from_runner_past_results(runner, 'option_%02d_lifetime_to_apply' % option_num, 'apply_upgrade', false)
      next if lifetime.nil?

      option_lifetimes[option_num] = lifetime.to_f
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
        cost_mult = get_cost_multiplier(cost_mult_type, hpxml, runner)
        total_cost = cost_value * cost_mult
        next if total_cost == 0

        option_cost += total_cost
        runner.registerInfo("Upgrade cost addition: $#{cost_value} x #{cost_mult} [#{cost_mult_type}] = #{total_cost}.")
      end
      upgrade_cost += option_cost

      # Save option cost/lifetime to results.csv
      next unless option_cost != 0
      option_cost = option_cost.round(2)
      option_cost_name = 'option_%02d_cost_usd' % option_num
      register_value(runner, option_cost_name, option_cost)
      runner.registerInfo("Registering #{option_cost} for #{option_cost_name}.")
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

  def get_cost_multiplier(cost_mult_type, hpxml, runner)
    cost_mult = 0.0
    if cost_mult_type == 'Wall Area, Above-Grade, Conditioned (ft^2)'

    elsif cost_mult_type == 'Wall Area, Above-Grade, Exterior (ft^2)'

    elsif cost_mult_type == 'Wall Area, Below-Grade (ft^2)'

    elsif cost_mult_type == 'Floor Area, Conditioned (ft^2)'
      cost_mult += hpxml.building_construction.conditioned_floor_area
    elsif cost_mult_type == 'Floor Area, Attic (ft^2)'

    elsif cost_mult_type == 'Floor Area, Lighting (ft^2)'

    elsif cost_mult_type == 'Roof Area (ft^2)'

    elsif cost_mult_type == 'Window Area (ft^2)'

    elsif cost_mult_type == 'Door Area (ft^2)'

    elsif cost_mult_type == 'Duct Surface Area (ft^2)'

    elsif cost_mult_type == 'Size, Heating System (kBtu/h)'

    elsif cost_mult_type == 'Size, Cooling System (kBtu/h)'

    elsif cost_mult_type == 'Size, Water Heater (gal)'

    end
    return cost_mult
  end # end get_cost_multiplier
end

# register the measure to be used by the application
UpgradeCosts.new.registerWithApplication
