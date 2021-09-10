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

    # Retrieve values from HPXMLOutputReport
    hpxml = get_values_from_runner_past_results(runner, 'hpxml_output_report')

    # Retrieve values from ApplyUpgrade
    values = get_values_from_runner_past_results(runner, 'apply_upgrade')

    # UPGRADE NAME
    upgrade_name = values['upgrade_name']
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
        cost_value = values["option_%02d_cost_#{cost_num}_value_to_apply" % option_num]
        next if cost_value.nil?

        cost_mult_type = values["option_%02d_cost_#{cost_num}_multiplier_to_apply" % option_num]
        next if cost_mult_type.nil?

        has_costs = true
        option_cost_pairs[option_num] << [cost_value.to_f, cost_mult_type]
      end
      lifetime = values['option_%02d_lifetime_to_apply' % option_num]
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
        next if cost_mult_type.empty?

        cost_mult_type_str = OpenStudio::toUnderscoreCase(cost_mult_type)
        cost_mult_type_str = cost_mult_type_str[0..-2]
        cost_mult = hpxml[cost_mult_type_str]
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
end

# register the measure to be used by the application
UpgradeCosts.new.registerWithApplication
