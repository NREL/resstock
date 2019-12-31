require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'
require_relative "HPXMLtoOpenStudio/resources/constants"

desc 'update all measures'
task :update_measures do
  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? and ENV['HOME'].start_with? 'U:'
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? and ENV['HOMEDRIVE'].start_with? 'U:'

  # Apply rubocop
  command = "rubocop --auto-correct --format simple --only Layout"
  puts "Applying rubocop style to measures..."
  system(command)

  create_osws

  puts "Done."
end

def create_osws
  require 'openstudio'

  this_dir = File.dirname(__FILE__)
  tests_dir = File.join(this_dir, "tests")

  # Hash of OSW -> Parent OSW
  osws_files = {
    'base-single-family-detached.osw' => nil,
    # 'base-single-family-attached.osw' => 'base-single-family-detached.osw',
    'base-multifamily.osw' => 'base-single-family-detached.osw',
    'base-enclosure-skylights.osw' => 'base-single-family-detached.osw',
    'base-hvac-air-to-air-heat-pump-1-speed.osw' => 'base-single-family-detached.osw',
    'base-hvac-furnace-gas-only-x2.osw' => 'base-single-family-detached.osw',
    'base-hvac-programmable-thermostat.osw' => 'base-single-family-detached.osw',
    'base-dhw-storage-gas-x2.osw' => 'base-single-family-detached.osw'
  }

  puts "Generating #{osws_files.size} OSW files..."

  osws_files.each do |derivative, parent|
    print "."

    begin
      osw_files = [derivative]
      unless parent.nil?
        osw_files.unshift(parent)
      end
      while not parent.nil?
        if osws_files.keys.include? parent
          unless osws_files[parent].nil?
            osw_files.unshift(osws_files[parent])
          end
          parent = osws_files[parent]
        end
      end

      workflow = OpenStudio::WorkflowJSON.new
      workflow.setOswPath(File.absolute_path(File.join(tests_dir, derivative)))
      workflow.addMeasurePath(".")
      steps = OpenStudio::WorkflowStepVector.new
      step = OpenStudio::MeasureStep.new("BuildResidentialHPXML")

      osw_files.each do |osw_file|
        step = get_example_single_family_detached_values(osw_file, step)
      end

      steps.push(step)
      workflow.setWorkflowSteps(steps)
      workflow.save
    rescue Exception => e
      puts "\n#{e}\n#{e.backtrace.join('\n')}"
      puts "\nError: Did not successfully generate #{derivative}."
      exit!
    end
  end
end

def get_example_single_family_detached_values(osw_file, step)
  if ['base-single-family-detached.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "../HPXMLtoOpenStudio/weather/USA_CO_Denver.Intl.AP.725650_TMY3.epw")
    step.setArgument("hpxml_output_path", "tests/run/in.xml")
    step.setArgument("schedules_output_path", "tests/run/schedules.csv")
    step.setArgument("unit_type", "single-family detached")
    step.setArgument("unit_multiplier", 1)
    step.setArgument("cfa", 2000.0)
    step.setArgument("wall_height", 8.0)
    step.setArgument("num_floors", 2)
    step.setArgument("aspect_ratio", 2.0)
    step.setArgument("level", "Bottom")
    step.setArgument("horizontal_location", "Left")
    step.setArgument("corridor_position", "Double-Loaded Interior")
    step.setArgument("corridor_width", 10.0)
    step.setArgument("inset_width", 0.0)
    step.setArgument("inset_depth", 0.0)
    step.setArgument("inset_position", "Right")
    step.setArgument("balcony_depth", 0.0)
    step.setArgument("garage_width", 0.0)
    step.setArgument("garage_depth", 20.0)
    step.setArgument("garage_protrusion", 0.0)
    step.setArgument("garage_position", "Right")
    step.setArgument("foundation_type", "slab")
    step.setArgument("foundation_height", 3.0)
    step.setArgument("attic_type", "attic - vented")
    step.setArgument("unconditioned_attic_ceiling_r", 30)
    step.setArgument("roof_type", "gable")
    step.setArgument("roof_pitch", "6:12")
    step.setArgument("roof_structure", "truss, cantilever")
    step.setArgument("eaves_depth", 2.0)
    step.setArgument("num_bedrooms", 3)
    step.setArgument("num_bathrooms", 2)
    step.setArgument("num_occupants", Constants.Auto)
    step.setArgument("neighbor_left_offset", 10.0)
    step.setArgument("neighbor_right_offset", 10.0)
    step.setArgument("neighbor_back_offset", 10.0)
    step.setArgument("neighbor_front_offset", 10.0)
    step.setArgument("orientation", 180.0)
    step.setArgument("front_wwr", 0.18)
    step.setArgument("back_wwr", 0.18)
    step.setArgument("left_wwr", 0.18)
    step.setArgument("right_wwr", 0.18)
    step.setArgument("front_window_area", 0)
    step.setArgument("back_window_area", 0)
    step.setArgument("left_window_area", 0)
    step.setArgument("right_window_area", 0)
    step.setArgument("window_ufactor", 0.37)
    step.setArgument("window_shgc", 0.3)
    step.setArgument("window_aspect_ratio", 1.333)
    step.setArgument("overhangs_depth", 2.0)
    step.setArgument("overhangs_front_facade", true)
    step.setArgument("overhangs_back_facade", true)
    step.setArgument("overhangs_left_facade", true)
    step.setArgument("overhangs_right_facade", true)
    step.setArgument("front_skylight_area", 0)
    step.setArgument("back_skylight_area", 0)
    step.setArgument("left_skylight_area", 0)
    step.setArgument("right_skylight_area", 0)
    step.setArgument("skylight_ufactor", 0.33)
    step.setArgument("skylight_shgc", 0.45)
    step.setArgument("door_area", 20.0)
    step.setArgument("door_ufactor", 0.2)
    step.setArgument("living_ach50", 7)
    step.setArgument("heating_system_type_1", "Furnace")
    step.setArgument("heating_system_fuel_1", "natural gas")
    step.setArgument("heating_system_heating_efficiency_1", 0.78)
    step.setArgument("heating_system_heating_capacity_1", Constants.SizingAuto)
    step.setArgument("heating_system_fraction_heat_load_served_1", 1)
    step.setArgument("heating_system_type_2", "none")
    step.setArgument("heating_system_fuel_2", "natural gas")
    step.setArgument("heating_system_heating_efficiency_2", 0.78)
    step.setArgument("heating_system_heating_capacity_2", Constants.SizingAuto)
    step.setArgument("heating_system_fraction_heat_load_served_2", 1)
    step.setArgument("cooling_system_type_1", "central air conditioner")
    step.setArgument("cooling_system_fuel_1", "electricity")
    step.setArgument("cooling_system_cooling_efficiency_1", 13.0)
    step.setArgument("cooling_system_cooling_capacity_1", Constants.SizingAuto)
    step.setArgument("cooling_system_fraction_cool_load_served_1", 1)
    step.setArgument("cooling_system_type_2", "none")
    step.setArgument("cooling_system_fuel_2", "electricity")
    step.setArgument("cooling_system_cooling_efficiency_2", 13.0)
    step.setArgument("cooling_system_cooling_capacity_2", Constants.SizingAuto)
    step.setArgument("cooling_system_fraction_cool_load_served_2", 1)
    step.setArgument("heat_pump_type_1", "none")
    step.setArgument("heat_pump_fuel_1", "electricity")
    step.setArgument("heat_pump_heating_efficiency_1", 13.0)
    step.setArgument("heat_pump_cooling_efficiency_1", 7.7)
    step.setArgument("heat_pump_heating_capacity_1", Constants.SizingAuto)
    step.setArgument("heat_pump_cooling_capacity_1", Constants.SizingAuto)
    step.setArgument("heat_pump_fraction_heat_load_served_1", 1)
    step.setArgument("heat_pump_fraction_cool_load_served_1", 1)
    step.setArgument("heat_pump_backup_fuel_1", "electricity")
    step.setArgument("heat_pump_backup_heating_efficiency_percent_1", 1)
    step.setArgument("heat_pump_backup_heating_capacity_1", Constants.SizingAuto)
    step.setArgument("heat_pump_type_2", "none")
    step.setArgument("heat_pump_fuel_2", "electricity")
    step.setArgument("heat_pump_heating_efficiency_2", 13.0)
    step.setArgument("heat_pump_cooling_efficiency_2", 7.7)
    step.setArgument("heat_pump_heating_capacity_2", Constants.SizingAuto)
    step.setArgument("heat_pump_cooling_capacity_2", Constants.SizingAuto)
    step.setArgument("heat_pump_fraction_heat_load_served_2", 1)
    step.setArgument("heat_pump_fraction_cool_load_served_2", 1)
    step.setArgument("heat_pump_backup_fuel_2", "electricity")
    step.setArgument("heat_pump_backup_heating_efficiency_percent_2", 1)
    step.setArgument("heat_pump_backup_heating_capacity_2", Constants.SizingAuto)
    step.setArgument("heating_setpoint_temp", 71)
    step.setArgument("heating_setback_temp", 71)
    step.setArgument("heating_setback_hours_per_week", 0)
    step.setArgument("heating_setback_start_hour", 0)
    step.setArgument("cooling_setpoint_temp", 76)
    step.setArgument("cooling_setup_temp", 76)
    step.setArgument("cooling_setup_hours_per_week", 0)
    step.setArgument("cooling_setup_start_hour", 0)
    step.setArgument("distribution_system_type_1", "AirDistribution")
    step.setArgument("distribution_system_type_2", "none")
    step.setArgument("supply_duct_leakage_units_1", "CFM25")
    step.setArgument("return_duct_leakage_units_1", "CFM25")
    step.setArgument("supply_duct_leakage_value_1", 75)
    step.setArgument("return_duct_leakage_value_1", 25)
    step.setArgument("supply_duct_insulation_r_value_1", 0)
    step.setArgument("return_duct_insulation_r_value_1", 0)
    step.setArgument("supply_duct_location_1", "living space")
    step.setArgument("return_duct_location_1", "living space")
    step.setArgument("supply_duct_surface_area_1", 150)
    step.setArgument("return_duct_surface_area_1", 50)
    step.setArgument("supply_duct_leakage_units_2", "CFM25")
    step.setArgument("return_duct_leakage_units_2", "CFM25")
    step.setArgument("supply_duct_leakage_value_2", 75)
    step.setArgument("return_duct_leakage_value_2", 25)
    step.setArgument("supply_duct_insulation_r_value_2", 0)
    step.setArgument("return_duct_insulation_r_value_2", 0)
    step.setArgument("supply_duct_location_2", "living space")
    step.setArgument("return_duct_location_2", "living space")
    step.setArgument("supply_duct_surface_area_2", 150)
    step.setArgument("return_duct_surface_area_2", 50)
    step.setArgument("water_heater_type_1", "storage water heater")
    step.setArgument("water_heater_fuel_type_1", "natural gas")
    step.setArgument("water_heater_location_1", "living space")
    step.setArgument("water_heater_tank_volume_1", Constants.Auto)
    step.setArgument("water_heater_fraction_dhw_load_served_1", 1)
    step.setArgument("water_heater_heating_capacity_1", Constants.SizingAuto)
    step.setArgument("water_heater_energy_factor_1", 0.59)
    step.setArgument("water_heater_recovery_efficiency_1", 0.76)
    step.setArgument("water_heater_type_2", "none")
    step.setArgument("water_heater_fuel_type_2", "natural gas")
    step.setArgument("water_heater_location_2", "living space")
    step.setArgument("water_heater_tank_volume_2", Constants.Auto)
    step.setArgument("water_heater_fraction_dhw_load_served_2", 1)
    step.setArgument("water_heater_heating_capacity_2", Constants.SizingAuto)
    step.setArgument("water_heater_energy_factor_2", 0.59)
    step.setArgument("water_heater_recovery_efficiency_2", 0.76)
    step.setArgument("hot_water_distribution_system_type", "Standard")
    step.setArgument("standard_piping_length", 50)
    step.setArgument("recirculation_control_type", "no control")
    step.setArgument("recirculation_piping_length", 50)
    step.setArgument("recirculation_branch_piping_length", 50)
    step.setArgument("recirculation_pump_power", 50)
    step.setArgument("hot_water_distribution_pipe_r_value", 0.0)
    step.setArgument("shower_low_flow", false)
    step.setArgument("sink_low_flow", false)
    step.setArgument("clothes_washer_location", "living space")
    step.setArgument("clothes_washer_integrated_modified_energy_factor", 0.95)
    step.setArgument("clothes_washer_rated_annual_kwh", 387.0)
    step.setArgument("clothes_washer_label_electric_rate", 0.1065)
    step.setArgument("clothes_washer_label_gas_rate", 1.218)
    step.setArgument("clothes_washer_label_annual_gas_cost", 24.0)
    step.setArgument("clothes_washer_capacity", 3.5)
    step.setArgument("clothes_dryer_location", "living space")
    step.setArgument("clothes_dryer_fuel_type", "natural gas")
    step.setArgument("clothes_dryer_combined_energy_factor", 2.4)
    step.setArgument("dishwasher_rated_annual_kwh", 290)
    step.setArgument("dishwasher_place_setting_capacity", 12)
    step.setArgument("refrigerator_location", "living space")
    step.setArgument("refrigerator_rated_annual_kwh", 434)
    step.setArgument("cooking_range_fuel_type", "natural gas")
    step.setArgument("cooking_range_is_induction", false)
    step.setArgument("oven_is_convection", false)
    step.setArgument("ceiling_fan_efficiency", 100)
    step.setArgument("ceiling_fan_quantity", 1)
    step.setArgument("plug_loads_frac_sensible", 0.93)
    step.setArgument("plug_loads_frac_latent", 0.021)
    step.setArgument("plug_loads_weekday_fractions", "0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036")
    step.setArgument("plug_loads_weekend_fractions", "0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036")
    step.setArgument("plug_loads_monthly_multipliers", "1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248")
  elsif ['base-enclosure-skylights.osw'].include? osw_file
    step.setArgument("attic_type", "attic - conditioned")
    step.setArgument("front_skylight_area", 10)
    step.setArgument("back_skylight_area", 10)
  elsif ['base-hvac-air-to-air-heat-pump-1-speed.osw'].include? osw_file
    step.setArgument("heating_system_type_1", "none")
    step.setArgument("cooling_system_type_1", "none")
    step.setArgument("heat_pump_type_1", "air-to-air")
  elsif ['base-hvac-furnace-gas-only-x2.osw'].include? osw_file
    step.setArgument("heating_system_type_2", "Furnace")
    step.setArgument("heating_system_fraction_heat_load_served_1", 0.5)
    step.setArgument("heating_system_fraction_heat_load_served_2", 0.5)
    step.setArgument("distribution_system_type_2", "AirDistribution")
  elsif ['base-hvac-programmable-thermostat.osw'].include? osw_file
    step.setArgument("heating_setback_temp", 66)
    step.setArgument("heating_setback_hours_per_week", 49)
    step.setArgument("heating_setback_start_hour", 23)
    step.setArgument("cooling_setup_temp", 80)
    step.setArgument("cooling_setup_hours_per_week", 42)
    step.setArgument("cooling_setup_start_hour", 9)
  elsif ['base-dhw-storage-gas-x2.osw'].include? osw_file
    step.setArgument("water_heater_type_2", "storage water heater")
    step.setArgument("water_heater_fraction_dhw_load_served_1", 0.5)
    step.setArgument("water_heater_fraction_dhw_load_served_2", 0.5)
  elsif ['base-single-family-attached.osw'].include? osw_file
  elsif ['base-multifamily.osw'].include? osw_file
    step.setArgument("unit_type", "multifamily")
    step.setArgument("cfa", 900.0)
  end
  return step
end
