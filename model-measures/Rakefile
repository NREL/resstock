require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'
require_relative "HPXMLtoOpenStudio/resources/constants"
require 'json'

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
    'base.osw' => nil,
    'base-single-family-attached.osw' => 'base.osw',
    'base-multifamily.osw' => 'base.osw',

    'base-foundation-ambient.osw' => 'base.osw',
    'base-foundation-complex.osw' => 'base.osw',
    'base-foundation-conditioned-basement-slab-insulation.osw' => 'base.osw',
    'base-foundation-conditioned-basement-wall-interior-insulation.osw' => 'base.osw',
    'base-foundation-multiple.osw' => 'base.osw',
    'base-foundation-slab.osw' => 'base.osw',
    'base-foundation-unconditioned-basement.osw' => 'base.osw',
    'base-foundation-unconditioned-basement-above-grade.osw' => 'base.osw',
    'base-foundation-unconditioned-basement-assembly-r.osw' => 'base.osw',
    'base-foundation-unconditioned-basement-wall-insulation.osw' => 'base.osw',
    'base-foundation-unvented-crawlspace.osw' => 'base.osw',
    'base-foundation-vented-crawlspace.osw' => 'base.osw',
    'base-foundation-walkout-basement.osw' => 'base.osw',

    'base-enclosure-beds-1.osw' => 'base.osw',
    'base-enclosure-beds-2.osw' => 'base.osw',
    'base-enclosure-beds-4.osw' => 'base.osw',
    'base-enclosure-beds-5.osw' => 'base.osw',
    'base-enclosure-garage.osw' => 'base.osw',
    'base-enclosure-infil-cfm50.osw' => 'base.osw',
    'base-enclosure-no-natural-ventilation.osw' => 'base.osw',
    'base-enclosure-overhangs.osw' => 'base.osw',
    'base-enclosure-skylights.osw' => 'base.osw',
    'base-enclosure-split-surfaces.osw' => 'base.osw',
    'base-enclosure-walltype-cmu.osw' => 'base.osw',
    'base-enclosure-walltype-doublestud.osw' => 'base.osw',
    'base-enclosure-walltype-icf.osw' => 'base.osw',
    'base-enclosure-walltype-log.osw' => 'base.osw',
    'base-enclosure-walltype-sip.osw' => 'base.osw',
    'base-enclosure-walltype-solidconcrete.osw' => 'base.osw',
    'base-enclosure-walltype-steelstud.osw' => 'base.osw',
    'base-enclosure-walltype-stone.osw' => 'base.osw',
    'base-enclosure-walltype-strawbale.osw' => 'base.osw',
    'base-enclosure-walltype-structuralbrick.osw' => 'base.osw',
    'base-enclosure-windows-interior-shading.osw' => 'base.osw',
    'base-enclosure-windows-none.osw' => 'base.osw',

    'base-hvac-furnace-elec-only.osw' => 'base.osw',
    'base-hvac-boiler-elec-only.osw' => 'base.osw',
    'base-hvac-boiler-gas-only.osw' => 'base.osw',
    'base-hvac-elec-resistance-only.osw' => 'base.osw',
    'base-hvac-portable-heater-electric-only.osw' => 'base.osw',
    'base-hvac-stove-oil-only.osw' => 'base.osw',
    'base-hvac-wall-furnace-propane-only.osw' => 'base.osw',
    'base-hvac-central-ac-only-1-speed.osw' => 'base.osw',
    'base-hvac-evap-cooler-only.osw' => 'base.osw',
    'base-hvac-room-ac-only.osw' => 'base.osw',
    'base-hvac-air-to-air-heat-pump-1-speed.osw' => 'base.osw',
    'base-hvac-mini-split-heat-pump-ducted.osw' => 'base.osw',
    'base-hvac-ground-to-air-heat-pump.osw' => 'base.osw',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.osw' => 'base.osw',
    'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.osw' => 'base.osw',
    'base-hvac-furnace-gas-plus-air-to-air-heat-pump-cooling.osw' => 'base.osw',
    'base-hvac-boiler-gas-central-ac-1-speed.osw' => 'base.osw',
    'base-hvac-programmable-thermostat.osw' => 'base.osw',

    'base-dhw-tank-gas.osw' => 'base.osw',
    'base-dhw-tank-heat-pump.osw' => 'base.osw',
    'base-dhw-tankless-electric.osw' => 'base.osw',
    'base-dhw-tankless-gas.osw' => 'base.osw',
    'base-dhw-multiple.osw' => 'base.osw'
  }

  puts "Generating #{osws_files.size} OSW files..."

  osws_files.each do |derivative, parent|
    print "."

    osw_path = File.absolute_path(File.join(tests_dir, derivative))

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
      workflow.setOswPath(osw_path)
      workflow.addMeasurePath(".")
      steps = OpenStudio::WorkflowStepVector.new
      step = OpenStudio::MeasureStep.new("BuildResidentialHPXML")

      osw_files.each do |osw_file|
        step = get_values(osw_file, step)
      end

      steps.push(step)
      workflow.setWorkflowSteps(steps)
      workflow.save

      workflow_hash = JSON.parse(File.read(osw_path))
      workflow_hash.delete("created_at")
      workflow_hash.delete("updated_at")

      File.open(osw_path, "w") do |f|
        f.write(JSON.pretty_generate(workflow_hash))
      end
    rescue Exception => e
      puts "\n#{e}\n#{e.backtrace.join('\n')}"
      puts "\nError: Did not successfully generate #{derivative}."
      exit!
    end
  end
end

def get_values(osw_file, step)
  if ['base.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "../HPXMLtoOpenStudio/weather/USA_CO_Denver.Intl.AP.725650_TMY3.epw")
    step.setArgument("hpxml_output_path", "tests/run/in.xml")
    step.setArgument("schedules_output_path", "tests/run/schedules.csv")
    step.setArgument("unit_type", "single-family detached")
    step.setArgument("unit_multiplier", 1)
    step.setArgument("cfa", 2700.0)
    step.setArgument("wall_height", 8.0)
    step.setArgument("num_floors", 1)
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
    step.setArgument("foundation_type", "basement - conditioned")
    step.setArgument("foundation_height", 8.0)
    step.setArgument("foundation_ceiling_r", 30)
    step.setArgument("foundation_wall_r", 0)
    step.setArgument("perimeter_insulation_r", 0)
    step.setArgument("under_slab_insulation_r", 0)
    step.setArgument("attic_type", "attic - vented")
    step.setArgument("unconditioned_attic_ceiling_r", 30)
    step.setArgument("roof_type", "gable")
    step.setArgument("roof_pitch", "6:12")
    step.setArgument("roof_structure", "truss, cantilever")
    step.setArgument("eaves_depth", 2.0)
    step.setArgument("num_bedrooms", 3)
    step.setArgument("num_bathrooms", 2)
    step.setArgument("num_occupants", Constants.Auto)
    step.setArgument("neighbor_left_offset", 0)
    step.setArgument("neighbor_right_offset", 0)
    step.setArgument("neighbor_back_offset", 0)
    step.setArgument("neighbor_front_offset", 0)
    step.setArgument("orientation", 180.0)
    step.setArgument("wall_type", "WoodStud")
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
    step.setArgument("overhangs_front_facade", false)
    step.setArgument("overhangs_back_facade", false)
    step.setArgument("overhangs_left_facade", false)
    step.setArgument("overhangs_right_facade", false)
    step.setArgument("winter_shading_coefficient_front_facade", 1)
    step.setArgument("summer_shading_coefficient_front_facade", 1)
    step.setArgument("winter_shading_coefficient_back_facade", 1)
    step.setArgument("summer_shading_coefficient_back_facade", 1)
    step.setArgument("winter_shading_coefficient_left_facade", 1)
    step.setArgument("summer_shading_coefficient_left_facade", 1)
    step.setArgument("winter_shading_coefficient_right_facade", 1)
    step.setArgument("summer_shading_coefficient_right_facade", 1)
    step.setArgument("front_skylight_area", 0)
    step.setArgument("back_skylight_area", 0)
    step.setArgument("left_skylight_area", 0)
    step.setArgument("right_skylight_area", 0)
    step.setArgument("skylight_ufactor", 0.33)
    step.setArgument("skylight_shgc", 0.45)
    step.setArgument("door_area", 40.0)
    step.setArgument("door_rvalue", 4.4)
    step.setArgument("living_ach50", 3)
    step.setArgument("heating_system_type", "Furnace")
    step.setArgument("heating_system_fuel", "natural gas")
    step.setArgument("heating_system_heating_efficiency", 0.92)
    step.setArgument("heating_system_heating_capacity", "64000")
    step.setArgument("heating_system_fraction_heat_load_served", 1)
    step.setArgument("cooling_system_type", "central air conditioner")
    step.setArgument("cooling_system_fuel", "electricity")
    step.setArgument("cooling_system_cooling_efficiency", 13.0)
    step.setArgument("cooling_system_cooling_capacity", "48000")
    step.setArgument("cooling_system_fraction_cool_load_served", 1)
    step.setArgument("heat_pump_backup_fuel", "electricity")
    step.setArgument("heat_pump_backup_heating_efficiency_percent", 1)
    step.setArgument("heat_pump_backup_heating_capacity", Constants.SizingAuto)
    step.setArgument("heating_setpoint_temp", 68)
    step.setArgument("heating_setback_temp", 68)
    step.setArgument("heating_setback_hours_per_week", 0)
    step.setArgument("heating_setback_start_hour", 0)
    step.setArgument("cooling_setpoint_temp", 78)
    step.setArgument("cooling_setup_temp", 78)
    step.setArgument("cooling_setup_hours_per_week", 0)
    step.setArgument("cooling_setup_start_hour", 0)
    step.setArgument("supply_duct_leakage_units", "CFM25")
    step.setArgument("return_duct_leakage_units", "CFM25")
    step.setArgument("supply_duct_leakage_value", 75.0)
    step.setArgument("return_duct_leakage_value", 25.0)
    step.setArgument("supply_duct_insulation_r_value", 4.0)
    step.setArgument("return_duct_insulation_r_value", 4.0)
    step.setArgument("supply_duct_location", "attic - unvented")
    step.setArgument("return_duct_location", "attic - unvented")
    step.setArgument("supply_duct_surface_area", 150.0)
    step.setArgument("return_duct_surface_area", 50.0)
    step.setArgument("water_heater_type_1", "storage water heater")
    step.setArgument("water_heater_fuel_type_1", "electricity")
    step.setArgument("water_heater_location_1", "living space")
    step.setArgument("water_heater_tank_volume_1", "40")
    step.setArgument("water_heater_fraction_dhw_load_served_1", 1)
    step.setArgument("water_heater_heating_capacity_1", Constants.SizingAuto)
    step.setArgument("water_heater_energy_factor_1", 0.95)
    step.setArgument("water_heater_recovery_efficiency_1", 0.76)
    step.setArgument("water_heater_type_2", "none")
    step.setArgument("water_heater_fuel_type_2", "electricity")
    step.setArgument("water_heater_location_2", Constants.Auto)
    step.setArgument("water_heater_tank_volume_2", Constants.Auto)
    step.setArgument("water_heater_fraction_dhw_load_served_2", 1)
    step.setArgument("water_heater_heating_capacity_2", Constants.SizingAuto)
    step.setArgument("water_heater_energy_factor_2", 0.95)
    step.setArgument("water_heater_recovery_efficiency_2", 0.76)
    step.setArgument("hot_water_distribution_system_type", "Standard")
    step.setArgument("standard_piping_length", 50)
    step.setArgument("recirculation_control_type", "no control")
    step.setArgument("recirculation_piping_length", 50)
    step.setArgument("recirculation_branch_piping_length", 50)
    step.setArgument("recirculation_pump_power", 50)
    step.setArgument("hot_water_distribution_pipe_r_value", 0.0)
    step.setArgument("shower_low_flow", true)
    step.setArgument("sink_low_flow", false)
    step.setArgument("clothes_washer_location", "living space")
    step.setArgument("clothes_washer_integrated_modified_energy_factor", 0.8)
    step.setArgument("clothes_washer_rated_annual_kwh", 700.0)
    step.setArgument("clothes_washer_label_electric_rate", 0.1)
    step.setArgument("clothes_washer_label_gas_rate", 0.6)
    step.setArgument("clothes_washer_label_annual_gas_cost", 25.0)
    step.setArgument("clothes_washer_capacity", 3.0)
    step.setArgument("clothes_dryer_location", "living space")
    step.setArgument("clothes_dryer_fuel_type", "electricity")
    step.setArgument("clothes_dryer_combined_energy_factor", 2.95)
    step.setArgument("dishwasher_rated_annual_kwh", 450.0)
    step.setArgument("dishwasher_place_setting_capacity", 12)
    step.setArgument("refrigerator_location", "living space")
    step.setArgument("refrigerator_rated_annual_kwh", 650.0)
    step.setArgument("cooking_range_fuel_type", "electricity")
    step.setArgument("cooking_range_is_induction", false)
    step.setArgument("oven_is_convection", false)
    step.setArgument("ceiling_fan_efficiency", 100)
    step.setArgument("ceiling_fan_quantity", 0)
    step.setArgument("plug_loads_frac_sensible", 0.93)
    step.setArgument("plug_loads_frac_latent", 0.021)
    step.setArgument("plug_loads_weekday_fractions", "0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036")
    step.setArgument("plug_loads_weekend_fractions", "0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036")
    step.setArgument("plug_loads_monthly_multipliers", "1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248")
  elsif ['base-single-family-attached.osw'].include? osw_file
    step.setArgument("unit_type", "single-family attached")
    step.setArgument("foundation_type", "slab")
    step.setArgument("cfa", 900.0)
  elsif ['base-multifamily.osw'].include? osw_file
    step.setArgument("unit_type", "multifamily")
    step.setArgument("foundation_type", "slab")
    step.setArgument("cfa", 900.0)
  elsif ['base-foundation-ambient.osw'].include? osw_file
    step.setArgument("foundation_type", "ambient")
  elsif ['base-foundation-complex.osw'].include? osw_file

  elsif ['base-foundation-conditioned-basement-slab-insulation.osw'].include? osw_file
    step.setArgument("under_slab_insulation_r", 10)
  elsif ['base-foundation-conditioned-basement-wall-interior-insulation.osw'].include? osw_file
    step.setArgument("foundation_ceiling_r", 0)
    step.setArgument("foundation_wall_r", 30)
  elsif ['base-foundation-multiple.osw'].include? osw_file

  elsif ['base-foundation-slab.osw'].include? osw_file
    step.setArgument("foundation_type", "slab")
    step.setArgument("perimeter_insulation_r", 5)
  elsif ['base-foundation-unconditioned-basement.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
  elsif ['base-foundation-unconditioned-basement-above-grade.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
  elsif ['base-foundation-unconditioned-basement-assembly-r.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
  elsif ['base-foundation-unconditioned-basement-wall-insulation.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
    step.setArgument("foundation_ceiling_r", 0)
    step.setArgument("foundation_wall_r", 30)
  elsif ['base-foundation-unvented-crawlspace.osw'].include? osw_file
    step.setArgument("foundation_type", "crawlspace - unvented")
    step.setArgument("foundation_height", 3.0)
  elsif ['base-foundation-vented-crawlspace.osw'].include? osw_file
    step.setArgument("foundation_type", "crawlspace - vented")
    step.setArgument("foundation_height", 3.0)
  elsif ['base-foundation-walkout-basement.osw'].include? osw_file

  elsif ['base-enclosure-beds-1.osw'].include? osw_file
    step.setArgument("num_bedrooms", 1)
  elsif ['base-enclosure-beds-2.osw'].include? osw_file
    step.setArgument("num_bedrooms", 2)
  elsif ['base-enclosure-beds-4.osw'].include? osw_file
    step.setArgument("num_bedrooms", 4)
  elsif ['base-enclosure-beds-5.osw'].include? osw_file
    step.setArgument("num_bedrooms", 5)
  elsif ['base-enclosure-garage.osw'].include? osw_file
    step.setArgument("garage_width", 12.0)
  elsif ['base-enclosure-infil-cfm50.osw'].include? osw_file

  elsif ['base-enclosure-no-natural-ventilation.osw'].include? osw_file

  elsif ['base-enclosure-overhangs.osw'].include? osw_file
    step.setArgument("overhangs_front_facade", true)
    step.setArgument("overhangs_back_facade", true)
    step.setArgument("overhangs_left_facade", true)
    step.setArgument("overhangs_right_facade", true)
  elsif ['base-enclosure-skylights.osw'].include? osw_file
    step.setArgument("attic_type", "attic - conditioned")
    step.setArgument("front_skylight_area", 10)
    step.setArgument("back_skylight_area", 10)
  elsif ['base-enclosure-split-surfaces.osw'].include? osw_file

  elsif ['base-enclosure-walltype-cmu.osw'].include? osw_file
    step.setArgument("wall_type", "ConcreteMasonryUnit")
  elsif ['base-enclosure-walltype-doublestud.osw'].include? osw_file
    step.setArgument("wall_type", "DoubleWoodStud")
  elsif ['base-enclosure-walltype-icf.osw'].include? osw_file
    step.setArgument("wall_type", "InsulatedConcreteForms")
  elsif ['base-enclosure-walltype-log.osw'].include? osw_file
    step.setArgument("wall_type", "LogWall")
  elsif ['base-enclosure-walltype-sip.osw'].include? osw_file
    step.setArgument("wall_type", "StructurallyInsulatedPanel")
  elsif ['base-enclosure-walltype-solidconcrete.osw'].include? osw_file
    step.setArgument("wall_type", "SolidConcrete")
  elsif ['base-enclosure-walltype-steelstud.osw'].include? osw_file
    step.setArgument("wall_type", "SteelFrame")
  elsif ['base-enclosure-walltype-stone.osw'].include? osw_file
    step.setArgument("wall_type", "Stone")
  elsif ['base-enclosure-walltype-strawbale.osw'].include? osw_file
    step.setArgument("wall_type", "StrawBale")
  elsif ['base-enclosure-walltype-structuralbrick.osw'].include? osw_file
    step.setArgument("wall_type", "StructuralBrick")
  elsif ['base-enclosure-windows-interior-shading.osw'].include? osw_file
    step.setArgument("winter_shading_coefficient_front_facade", 0.85)
    step.setArgument("summer_shading_coefficient_front_facade", 0.7)
    step.setArgument("winter_shading_coefficient_back_facade", 0.85)
    step.setArgument("summer_shading_coefficient_back_facade", 0.7)
    step.setArgument("winter_shading_coefficient_left_facade", 0.85)
    step.setArgument("summer_shading_coefficient_left_facade", 0.7)
    step.setArgument("winter_shading_coefficient_right_facade", 0.85)
    step.setArgument("summer_shading_coefficient_right_facade", 0.7)
  elsif ['base-enclosure-windows-none.osw'].include? osw_file
    step.setArgument("front_wwr", 0)
    step.setArgument("back_wwr", 0)
    step.setArgument("left_wwr", 0)
    step.setArgument("right_wwr", 0)
  elsif ['base-hvac-furnace-elec-only.osw'].include? osw_file
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 1.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-boiler-elec-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-boiler-gas-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-elec-resistance-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "ElectricResistance")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-portable-heater-electric-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "PortableHeater")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-stove-oil-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "Stove")
    step.setArgument("heating_system_fuel", "fuel oil")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-wall-furnace-propane-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "WallFurnace")
    step.setArgument("heating_system_fuel", "propane")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-central-ac-only-1-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
  elsif ['base-hvac-evap-cooler-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("cooling_system_type", "evaporative cooler")
  elsif ['base-hvac-room-ac-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("cooling_system_type", "room air conditioner")
  elsif ['base-hvac-air-to-air-heat-pump-1-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("cooling_system_type", "air-to-air")
  elsif ['base-hvac-mini-split-heat-pump-ducted.osw'].include? osw_file
    step.setArgument("heating_system_type", "mini-split")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("cooling_system_type", "mini-split")
  elsif ['base-hvac-ground-to-air-heat-pump.osw'].include? osw_file
    step.setArgument("heating_system_type", "ground-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("cooling_system_type", "ground-to-air")
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("heat_pump_backup_fuel", "natural gas")
    step.setArgument("heat_pump_backup_heating_efficiency_percent", 0.95)
  elsif ['base-hvac-central-ac-plus-air-to-air-heat-pump-heating.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
  elsif ['base-hvac-furnace-gas-plus-air-to-air-heat-pump-cooling.osw'].include? osw_file
    step.setArgument("cooling_system_type", "air-to-air")
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
  elsif ['base-hvac-programmable-thermostat.osw'].include? osw_file
    step.setArgument("heating_setback_temp", 66)
    step.setArgument("heating_setback_hours_per_week", 49)
    step.setArgument("heating_setback_start_hour", 23)
    step.setArgument("cooling_setup_temp", 80)
    step.setArgument("cooling_setup_hours_per_week", 42)
    step.setArgument("cooling_setup_start_hour", 9)
  elsif ['base-dhw-tank-gas.osw'].include? osw_file
    step.setArgument("water_heater_fuel_type_1", "natural gas")
    step.setArgument("water_heater_energy_factor_1", 0.59)
  elsif ['base-dhw-tank-heat-pump.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "heat pump water heater")
    step.setArgument("water_heater_energy_factor_1", 2.3)
  elsif ['base-dhw-tankless-electric.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "instantaneous water heater")
    step.setArgument("water_heater_energy_factor_1", 0.99)
  elsif ['base-dhw-tankless-gas.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "instantaneous water heater")
    step.setArgument("water_heater_fuel_type_1", "natural gas")
    step.setArgument("water_heater_energy_factor_1", 0.82)
  elsif ['base-dhw-multiple.osw'].include? osw_file
    step.setArgument("water_heater_type_2", "storage water heater")
    step.setArgument("water_heater_fuel_type_2", "natural gas")
    step.setArgument("water_heater_fraction_dhw_load_served_1", 0.5)
    step.setArgument("water_heater_fraction_dhw_load_served_2", 0.5)
  end
  return step
end
