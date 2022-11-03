# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'openstudio'
require_relative '../ApplyUpgrade/resources/constants'
require_relative '../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'

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
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('If true, retain existing and upgraded intermediate files.')
    arg.setDefaultValue(false)
    args << arg

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

    debug = runner.getBoolArgumentValue('debug', user_arguments)

    # Retrieve values from BuildExistingModel, ApplyUpgrade, ReportHPXMLOutput
    values = { 'apply_upgrade' => get_values_from_runner_past_results(runner, 'apply_upgrade'),
               'report_hpxml_output' => get_values_from_runner_past_results(runner, 'report_hpxml_output') }

    # Report cost multipliers
    existing_hpxml = nil
    upgraded_hpxml = nil
    cost_multiplier_choices.each do |cost_mult_type|
      next if cost_mult_type.empty?
      next if cost_mult_type.include?('Fixed')

      cost_mult_type_str = OpenStudio::toUnderscoreCase(cost_mult_type)
      cost_mult = get_bldg_output(cost_mult_type, values, existing_hpxml, upgraded_hpxml)
      cost_mult = cost_mult.round(2)
      register_value(runner, cost_mult_type_str, cost_mult)
    end

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
        cost_value = values['apply_upgrade']["option_%02d_cost_#{cost_num}_value_to_apply" % option_num]
        next if cost_value.nil?

        cost_mult_type = values['apply_upgrade']["option_%02d_cost_#{cost_num}_multiplier_to_apply" % option_num]
        next if cost_mult_type.nil?

        has_costs = true
        option_cost_pairs[option_num] << [cost_value.to_f, cost_mult_type]
      end
      name = values['apply_upgrade']['option_%02d_name_applied' % option_num]
      lifetime = values['apply_upgrade']['option_%02d_lifetime_to_apply' % option_num]

      option_names[option_num] = name
      option_lifetimes[option_num] = lifetime.to_f if !lifetime.nil?
    end

    if not has_costs
      remove_intermediate_files() if !debug
      register_value(runner, upgrade_cost_name, 0.0)
      runner.registerInfo("Registering 0.0 for #{upgrade_cost_name}.")
      return true
    end

    # Obtain cost multiplier values and calculate upgrade costs
    upgrade_cost = 0.0
    option_cost_pairs.keys.each do |option_num|
      next if option_cost_pairs[option_num].empty?

      option_cost = 0.0
      option_cost_pairs[option_num].each do |cost_value, cost_mult_type|
        cost_mult = get_bldg_output(cost_mult_type, values, existing_hpxml, upgraded_hpxml)
        total_cost = cost_value * cost_mult
        next if total_cost == 0

        option_cost += total_cost
        runner.registerInfo("Upgrade cost addition: $#{cost_value} x #{cost_mult} [#{cost_mult_type}] = #{total_cost}.")
      end
      upgrade_cost += option_cost

      # Save option cost/name/lifetime to results.csv
      name = option_names[option_num]
      option_name = 'option_%02d_name' % option_num
      register_value(runner, option_name, name)
      runner.registerInfo("Registering #{name} for #{option_name}.")
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

    remove_intermediate_files() if !debug

    return true
  end

  def remove_intermediate_files()
    FileUtils.rm_rf(File.expand_path('../existing.osw'))
    FileUtils.rm_rf(File.expand_path('../existing.xml'))
    FileUtils.rm_rf(File.expand_path('../upgraded.osw'))
    FileUtils.rm_rf(File.expand_path('../upgraded.xml'))
  end

  def retrieve_hpxmls(existing_hpxml, upgraded_hpxml)
    if existing_hpxml.nil? && upgraded_hpxml.nil?
      existing_path = File.expand_path('../existing.xml')
      existing_hpxml = HPXML.new(hpxml_path: existing_path) if File.exist?(existing_path)

      upgraded_path = File.expand_path('../upgraded.xml')
      upgraded_hpxml = HPXML.new(hpxml_path: upgraded_path) if File.exist?(upgraded_path)
    end

    return existing_hpxml, upgraded_hpxml
  end

  def get_bldg_output(cost_mult_type, values, existing_hpxml, upgraded_hpxml)
    hpxml = values['report_hpxml_output']

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
    elsif cost_mult_type == 'Floor Area, Conditioned * Infiltration Reduction (ft^2 * Delta ACH50)'
      existing_hpxml, upgraded_hpxml = retrieve_hpxmls(existing_hpxml, upgraded_hpxml)
      if !upgraded_hpxml.nil?
        air_leakage_value = { existing_hpxml => [], upgraded_hpxml => [] }
        [existing_hpxml, upgraded_hpxml].each do |hpxml_obj|
          hpxml_obj.air_infiltration_measurements.each do |air_infiltration_measurement|
            air_leakage_value[hpxml_obj] << air_infiltration_measurement.air_leakage unless air_infiltration_measurement.air_leakage.nil?
          end
        end
        fail 'Found multiple air infiltration measurement values.' if air_leakage_value[existing_hpxml].uniq.size > 1 || air_leakage_value[upgraded_hpxml].uniq.size > 1

        if !air_leakage_value[existing_hpxml].empty? && !air_leakage_value[upgraded_hpxml].empty?
          air_leakage_value_reduction = air_leakage_value[existing_hpxml][0] - air_leakage_value[upgraded_hpxml][0]
          cost_mult += air_leakage_value_reduction * hpxml['enclosure_floor_area_conditioned_ft_2']
        end
      end
    elsif cost_mult_type == 'Floor Area, Lighting (ft^2)'
      cost_mult += hpxml['enclosure_floor_area_lighting_ft_2']
    elsif cost_mult_type == 'Floor Area, Foundation (ft^2)'
      cost_mult += hpxml['enclosure_floor_area_foundation_ft_2']
    elsif cost_mult_type == 'Floor Area, Attic (ft^2)'
      cost_mult += hpxml['enclosure_ceiling_area_thermal_boundary_ft_2']
    elsif cost_mult_type == 'Floor Area, Attic * Insulation Increase (ft^2 * Delta R-value)'
      existing_hpxml, upgraded_hpxml = retrieve_hpxmls(existing_hpxml, upgraded_hpxml)
      if !upgraded_hpxml.nil?
        ceiling_assembly_r = { existing_hpxml => [], upgraded_hpxml => [] }
        [existing_hpxml, upgraded_hpxml].each do |hpxml_obj|
          hpxml_obj.floors.each do |floor|
            next unless floor.is_thermal_boundary
            next unless floor.is_interior
            next unless floor.is_ceiling
            next unless [HPXML::LocationAtticVented,
                         HPXML::LocationAtticUnvented].include?(floor.exterior_adjacent_to)

            ceiling_assembly_r[hpxml_obj] << floor.insulation_assembly_r_value unless floor.insulation_assembly_r_value.nil?
          end
        end
        fail 'Found multiple ceiling assembly R-values.' if ceiling_assembly_r[existing_hpxml].uniq.size > 1 || ceiling_assembly_r[upgraded_hpxml].uniq.size > 1

        if !ceiling_assembly_r[existing_hpxml].empty? && !ceiling_assembly_r[upgraded_hpxml].empty?
          ceiling_insulation_r_upgraded = upgraded_hpxml.header.extension_properties['ceiling_insulation_r'].to_f
          ceiling_insulation_r_existing = existing_hpxml.header.extension_properties['ceiling_insulation_r'].to_f
          ceiling_assembly_r_increase = ceiling_insulation_r_upgraded - ceiling_insulation_r_existing
          cost_mult += ceiling_assembly_r_increase * hpxml['enclosure_ceiling_area_thermal_boundary_ft_2']
        end
      end
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
