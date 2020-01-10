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
    'base.osw' => nil, # single-family detached
    'base-single-family-attached.osw' => 'base.osw',
    'base-multifamily.osw' => 'base.osw',

    'base-appliances-dishwasher-ef.osw' => 'base.osw',
    'base-appliances-dryer-cef.osw' => 'base.osw',
    'base-appliances-gas.osw' => 'base.osw',
    'base-appliances-none.osw' => 'base.osw',
    'base-appliances-oil.osw' => 'base.osw',
    'base-appliances-propane.osw' => 'base.osw',
    'base-appliances-refrigerator-adjusted.osw' => 'base.osw',
    'base-appliances-washer-imef.osw' => 'base.osw',
    'base-appliances-wood.osw' => 'base.osw',

    'base-atticroof-cathedral.osw' => 'base.osw',
    'base-atticroof-conditioned.osw' => 'base.osw',
    'base-atticroof-flat.osw' => 'base.osw',
    'base-atticroof-radiant-barrier.osw' => 'base.osw',
    'base-atticroof-unvented-insulated-roof.osw' => 'base.osw',
    'base-atticroof-vented.osw' => 'base.osw',

    'base-dhw-combi-tankless.osw' => 'base.osw',
    'base-dhw-combi-tankless-outside.osw' => 'base.osw',
    'base-dhw-desuperheater.osw' => 'base.osw',
    'base-dhw-desuperheater-2-speed.osw' => 'base.osw',
    'base-dhw-desuperheater-gshp.osw' => 'base.osw',
    'base-dhw-desuperheater-tankless.osw' => 'base.osw',
    'base-dhw-desuperheater-var-speed.osw' => 'base.osw',
    'base-dhw-dwhr.osw' => 'base.osw',
    'base-dhw-indirect.osw' => 'base.osw',
    'base-dhw-indirect-dse.osw' => 'base.osw',
    'base-dhw-indirect-outside.osw' => 'base.osw',
    'base-dhw-indirect-standbyloss.osw' => 'base.osw',
    'base-dhw-jacket-electric.osw' => 'base.osw',
    'base-dhw-jacket-gas.osw' => 'base.osw',
    'base-dhw-jacket-hpwh.osw' => 'base.osw',
    'base-dhw-jacket-indirect.osw' => 'base.osw',
    'base-dhw-low-flow-fixtures.osw' => 'base.osw',
    'base-dhw-multiple.osw' => 'base.osw',
    'base-dhw-none.osw' => 'base.osw',
    'base-dhw-recirc-demand.osw' => 'base.osw',
    'base-dhw-recirc-manual.osw' => 'base.osw',
    'base-dhw-recirc-nocontrol.osw' => 'base.osw',
    'base-dhw-recirc-temperature.osw' => 'base.osw',
    'base-dhw-recirc-timer.osw' => 'base.osw',
    'base-dhw-solar-direct-evacuated-tube.osw' => 'base.osw',
    'base-dhw-solar-direct-flat-plate.osw' => 'base.osw',
    'base-dhw-solar-direct-ics.osw' => 'base.osw',
    'base-dhw-solar-fraction.osw' => 'base.osw',
    'base-dhw-solar-indirect-evacuated-tube.osw' => 'base.osw',
    'base-dhw-solar-indirect-flat-plate.osw' => 'base.osw',
    'base-dhw-solar-thermosyphon-evacuated-tube.osw' => 'base.osw',
    'base-dhw-solar-thermosyphon-flat-plate.osw' => 'base.osw',
    'base-dhw-solar-thermosyphon-ics.osw' => 'base.osw',
    'base-dhw-tank-gas.osw' => 'base.osw',
    'base-dhw-tank-gas-outside.osw' => 'base.osw',
    'base-dhw-tank-heat-pump.osw' => 'base.osw',
    # 'base-dhw-tank-heat-pump-outside.osw' => 'base.osw', # C:/OpenStudio/OpenStudio-residential/HPXMLtoOpenStudio/tests/hpxml_translator_test.rb:370:in `get'
    'base-dhw-tank-heat-pump-with-solar.osw' => 'base.osw',
    'base-dhw-tank-heat-pump-with-solar-fraction.osw' => 'base.osw',
    'base-dhw-tankless-electric.osw' => 'base.osw',
    'base-dhw-tankless-electric-outside.osw' => 'base.osw',
    'base-dhw-tankless-gas.osw' => 'base.osw',
    'base-dhw-tankless-gas-with-solar.osw' => 'base.osw',
    'base-dhw-tankless-gas-with-solar-fraction.osw' => 'base.osw',
    'base-dhw-tankless-oil.osw' => 'base.osw',
    'base-dhw-tankless-propane.osw' => 'base.osw',
    'base-dhw-tankless-wood.osw' => 'base.osw',
    'base-dhw-tank-oil.osw' => 'base.osw',
    'base-dhw-tank-propane.osw' => 'base.osw',
    'base-dhw-tank-wood.osw' => 'base.osw',
    'base-dhw-uef.osw' => 'base.osw',

    'base-enclosure-2stories.osw' => 'base.osw',
    'base-enclosure-2stories-garage.osw' => 'base.osw',
    # 'base-enclosure-adiabatic-surfaces.osw' => 'base.osw', # 1 kiva object instead of 0
    'base-enclosure-beds-1.osw' => 'base.osw',
    'base-enclosure-beds-2.osw' => 'base.osw',
    'base-enclosure-beds-4.osw' => 'base.osw',
    'base-enclosure-beds-5.osw' => 'base.osw',
    'base-enclosure-garage.osw' => 'base.osw',
    'base-enclosure-infil-cfm50.osw' => 'base.osw',
    'base-enclosure-no-natural-ventilation.osw' => 'base.osw',
    'base-enclosure-overhangs.osw' => 'base.osw',
    # 'base-enclosure-skylights.osw' => 'base.osw', # There are no front roof surfaces, but 15.0 ft^2 of skylights were specified.
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

    'base-foundation-ambient.osw' => 'base.osw',
    # 'base-foundation-complex.osw' => 'base.osw', # 1 kiva object instead of 10
    'base-foundation-conditioned-basement-slab-insulation.osw' => 'base.osw',
    'base-foundation-conditioned-basement-wall-interior-insulation.osw' => 'base.osw',
    # 'base-foundation-multiple.osw' => 'base.osw', # 1 kiva object instead of 2
    'base-foundation-slab.osw' => 'base.osw',
    'base-foundation-unconditioned-basement.osw' => 'base.osw',
    'base-foundation-unconditioned-basement-above-grade.osw' => 'base.osw',
    'base-foundation-unconditioned-basement-assembly-r.osw' => 'base.osw',
    'base-foundation-unconditioned-basement-wall-insulation.osw' => 'base.osw',
    'base-foundation-unvented-crawlspace.osw' => 'base.osw',
    'base-foundation-vented-crawlspace.osw' => 'base.osw',
    # 'base-foundation-walkout-basement.osw' => 'base.osw', # 1 kiva object instead of 4

    'base-hvac-air-to-air-heat-pump-1-speed.osw' => 'base.osw',
    # 'base-hvac-air-to-air-heat-pump-1-speed.detailed.osw' => 'base.osw', # TODO: add HeatingCapacity17F, CoolingSensibleHeatFraction
    'base-hvac-ait-to-air-heat-pump-2-speed.osw' => 'base.osw',
    # 'base-hvac-air-to-air-heat-pump-2-speed-detailed.osw' => 'base.osw', # TODO: add HeatingCapacity17F, CoolingSensibleHeatFraction
    'base-hvac-air-to-air-heat-pump-var-speed.osw' => 'base.osw',
    # 'base-hvac-air-to-air-heat-pump-var-speed-detailed.osw' => 'base.osw', # TODO: add HeatingCapacity17F, CoolingSensibleHeatFraction
    'base-hvac-boiler-elec-only.osw' => 'base.osw',
    'base-hvac-boiler-gas-central-ac-1-speed.osw' => 'base.osw',
    'base-hvac-boiler-gas-only.osw' => 'base.osw',
    'base-hvac-boiler-gas-only-no-eae.osw' => 'base.osw',
    'base-hvac-boiler-oil-only.osw' => 'base.osw',
    'base-hvac-boiler-propane-only.osw' => 'base.osw',
    'base-hvac-boiler-wood-only.osw' => 'base.osw',
    'base-hvac-central-ac-only-1-speed.osw' => 'base.osw',
    # 'base-hvac-central-ac-only-1-speed-detailed.osw' => 'base.osw', # TODO: add SensibleHeatFraction
    'base-hvac-central-ac-only-2-speed.osw' => 'base.osw',
    # 'base-hvac-central-ac-only-2-speed-detailed.osw' => 'base.osw', # TODO: add SensibleHeatFraction
    'base-hvac-central-ac-only-var-speed.osw' => 'base.osw',
    # 'base-hvac-central-ac-only-var-speed-detailed.osw' => 'base.osw', # TODO: add SensibleHeatFraction
    'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.osw' => 'base.osw',
    'base-hvac-dse.osw' => 'base.osw',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.osw' => 'base.osw',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.osw' => 'base.osw',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-oil.osw' => 'base.osw',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-propane.osw' => 'base.osw',
    'base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.osw' => 'base.osw',
    'base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.osw' => 'base.osw',
    'base-hvac-dual-fuel-mini-split-heat-pump-ducted.osw' => 'base.osw',
    'base-hvac-ducts-in-conditioned-space.osw' => 'base.osw',
    'base-hvac-ducts-leakage-percent.osw' => 'base.osw',
    'base-hvac-ducts-locations.osw' => 'base.osw',
    # 'base-hvac-ducts-multiple.osw' => 'base.osw', TODO: not sure how to do multiple ducts
    'base-hvac-ducts-outside.osw' => 'base.osw',
    'base-hvac-elec-resistance-only.osw' => 'base.osw',
    'base-hvac-evap-cooler-furnace-gas.osw' => 'base.osw',
    'base-hvac-evap-cooler-only.osw' => 'base.osw',
    'base-hvac-evap-cooler-only-ducted.osw' => 'base.osw',
    'base-hvac-flowrate.osw' => 'base.osw',
    'base-hvac-furnace-elec-only.osw' => 'base.osw',
    'base-hvac-furnace-gas-central-ac-2-speed.osw' => 'base.osw',
    'base-hvac-furnace-gas-central-ac-var-speed.osw' => 'base.osw',
    'base-hvac-furnace-gas-only.osw' => 'base.osw',
    'base-hvac-furnace-gas-only-no-eae.osw' => 'base.osw',
    'base-hvac-furnace-gas-room-ac.osw' => 'base.osw',
    'base-hvac-furnace-oil-only.osw' => 'base.osw',
    'base-hvac-furnace-propane-only.osw' => 'base.osw',
    'base-hvac-furnace-wood-only.osw' => 'base.osw',
    # 'base-hvac-furnace-x3-dse.osw' => 'base.osw',
    'base-hvac-ground-to-air-heat-pump.osw' => 'base.osw',
    # 'base-hvac-ground-to-air-heat-pump-detailed.osw' => 'base.osw', # TODO: add CoolingSensibleHeatFraction
    # 'base-hvac-ideal-air.osw' => 'base.osw',
    'base-hvac-mini-split-heat-pump-ducted.osw' => 'base.osw',
    # 'base-hvac-mini-split-heat-pump-ducted-detailed.osw' => 'base.osw', # TODO: add HeatingCapacity17F, CoolingSensibleHeatFraction
    'base-hvac-mini-split-heat-pump-ductless.osw' => 'base.osw',
    'base-hvac-mini-split-heat-pump-ductless-no-backup.osw' => 'base.osw',
    # 'base-hvac-multiple.osw' => 'base.osw',
    'base-hvac-none.osw' => 'base.osw',
    # 'base-hvac-none-no-fuel-access.osw' => 'base.osw',
    'base-hvac-portable-heater-electric-only.osw' => 'base.osw',
    'base-hvac-programmable-thermostat.osw' => 'base.osw',
    'base-hvac-room-ac-only.osw' => 'base.osw',
    # 'base-hvac-room-ac-only-detailed.osw' => 'base.osw', # TODO: add SensibleHeatFraction
    'base-hvac-setpoints.osw' => 'base.osw',
    'base-hvac-stove-oil-only.osw' => 'base.osw',
    'base-hvac-stove-oil-only-no-eae.osw' => 'base.osw',
    'base-hvac-stove-wood-only.osw' => 'base.osw',
    'base-hvac-undersized.osw' => 'base.osw',
    'base-hvac-wall-furnace-elec-only.osw' => 'base.osw',
    'base-hvac-wall-furnace-propane-only.osw' => 'base.osw',
    'base-hvac-wall-furnace-propane-only-no-eae.osw' => 'base.osw',
    'base-hvac-wall-furnace-wood-only.osw' => 'base.osw',

    'base-infiltration-ach-natural.osw' => 'base.osw',

    'base-location-baltimore-md.osw' => 'base.osw',
    'base-location-dallas-tx.osw' => 'base.osw',
    'base-location-duluth-mn.osw' => 'base.osw',
    # 'base-location-epw-filename.osw' => 'base.osw',
    'base-location-miami-fl.osw' => 'base.osw',

    'base-mechvent-balanced.osw' => 'base.osw',
    'base-mechvent-cfis.osw' => 'base.osw',
    'base-mechvent-cfis-24hrs.osw' => 'base.osw',
    'base-mechvent-erv.osw' => 'base.osw',
    'base-mechvent-erv-atre-asre.osw' => 'base.osw',
    'base-mechvent-exhaust.osw' => 'base.osw',
    'base-mechvent-exhaust-rated-flow-rate.osw' => 'base.osw',
    'base-mechvent-hrv.osw' => 'base.osw',
    'base-mechvent-hrv-asre.osw' => 'base.osw',
    'base-mechvent-supply.osw' => 'base.osw',

    # 'base-misc-ceiling-fans.osw' => 'base.osw', # TODO: add another argument?
    'base-misc-lighting-none.osw' => 'base.osw',
    'base-misc-loads-detailed.osw' => 'base.osw',
    'base-misc-number-of-occupants.osw' => 'base.osw',

    'base-pv-array-1axis.osw' => 'base.osw',
    'base-pv-array-1axis-backtracked.osw' => 'base.osw',
    'base-pv-array-2axis.osw' => 'base.osw',
    'base-pv-array-fixed-open-rack.osw' => 'base.osw',
    'base-pv-array-module-premium.osw' => 'base.osw',
    'base-pv-array-module-standard.osw' => 'base.osw',
    'base-pv-array-module-thinfilm.osw' => 'base.osw',
    # 'base-pv-multiple.osw' => 'base.osw',

    'base-site-neighbors.osw' => 'base.osw'
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
  step.setArgument("hpxml_output_path", "HPXMLtoOpenStudio/tests/build_res_hpxml/#{File.basename(osw_file, ".*")}.xml")

  if ['base.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "../weather/USA_CO_Denver.Intl.AP.725650_TMY3.epw")
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
    step.setArgument("foundation_wall_interior_r", 0)
    step.setArgument("foundation_wall_exterior_r", 8.9)
    step.setArgument("slab_perimeter_r", 0)
    step.setArgument("slab_under_r", 0)
    step.setArgument("attic_type", "attic - unvented")
    step.setArgument("attic_floor_r", 39.3)
    step.setArgument("attic_ceiling_r", 2.3)
    step.setArgument("roof_type", "gable")
    step.setArgument("roof_pitch", "6:12")
    step.setArgument("roof_structure", "truss, cantilever")
    step.setArgument("roof_ceiling_r", 2.3)
    step.setArgument("roof_solar_absorptance", 0.7)
    step.setArgument("roof_emittance", 0.92)
    step.setArgument("roof_radiant_barrier", false)
    step.setArgument("eaves_depth", 2.0)
    step.setArgument("num_bedrooms", 3)
    step.setArgument("num_bathrooms", 2)
    step.setArgument("num_occupants", Constants.Auto)
    step.setArgument("neighbor_front_distance", 0)
    step.setArgument("neighbor_back_distance", 0)
    step.setArgument("neighbor_left_distance", 0)
    step.setArgument("neighbor_right_distance", 0)
    step.setArgument("neighbor_front_height", 0)
    step.setArgument("neighbor_back_height", 0)
    step.setArgument("neighbor_left_height", 0)
    step.setArgument("neighbor_right_height", 0)
    step.setArgument("orientation", 180.0)
    step.setArgument("wall_type", "WoodStud")
    step.setArgument("wall_r", 13)
    step.setArgument("front_wwr", 0.18)
    step.setArgument("back_wwr", 0.18)
    step.setArgument("left_wwr", 0.18)
    step.setArgument("right_wwr", 0.18)
    step.setArgument("front_window_area", 0)
    step.setArgument("back_window_area", 0)
    step.setArgument("left_window_area", 0)
    step.setArgument("right_window_area", 0)
    step.setArgument("window_aspect_ratio", 1.333)
    step.setArgument("window_ufactor", 0.37)
    step.setArgument("window_shgc", 0.3)
    step.setArgument("winter_shading_coefficient_front_facade", 1)
    step.setArgument("summer_shading_coefficient_front_facade", 1)
    step.setArgument("winter_shading_coefficient_back_facade", 1)
    step.setArgument("summer_shading_coefficient_back_facade", 1)
    step.setArgument("winter_shading_coefficient_left_facade", 1)
    step.setArgument("summer_shading_coefficient_left_facade", 1)
    step.setArgument("winter_shading_coefficient_right_facade", 1)
    step.setArgument("summer_shading_coefficient_right_facade", 1)
    step.setArgument("overhangs_front_facade", false)
    step.setArgument("overhangs_back_facade", false)
    step.setArgument("overhangs_left_facade", false)
    step.setArgument("overhangs_right_facade", false)
    step.setArgument("overhangs_depth", 2.0)
    step.setArgument("front_skylight_area", 0)
    step.setArgument("back_skylight_area", 0)
    step.setArgument("left_skylight_area", 0)
    step.setArgument("right_skylight_area", 0)
    step.setArgument("skylight_ufactor", 0.33)
    step.setArgument("skylight_shgc", 0.45)
    step.setArgument("door_area", 40.0)
    step.setArgument("door_rvalue", 4.4)
    step.setArgument("living_ach_50", 3)
    step.setArgument("living_constant_ach_natural", 0)
    step.setArgument("vented_crawlspace_sla", 0.00667)
    step.setArgument("heating_system_type", "Furnace")
    step.setArgument("heating_system_fuel", "natural gas")
    step.setArgument("heating_system_heating_efficiency", 0.92)
    step.setArgument("heating_system_heating_capacity", 64000.0)
    step.setArgument("heating_system_fraction_heat_load_served", 1)
    step.setArgument("heating_system_electric_auxiliary_energy", 0)
    step.setArgument("cooling_system_type", "central air conditioner")
    step.setArgument("cooling_system_fuel", "electricity")
    step.setArgument("cooling_system_cooling_efficiency", 13.0)
    step.setArgument("cooling_system_cooling_capacity", 48000.0)
    step.setArgument("cooling_system_fraction_cool_load_served", 1)
    step.setArgument("heat_pump_backup_fuel", "none")
    step.setArgument("heat_pump_backup_heating_efficiency", 1)
    step.setArgument("heat_pump_backup_heating_capacity", 34121.0)
    step.setArgument("mini_split_is_ducted", false)
    step.setArgument("evap_cooler_is_ducted", false)
    step.setArgument("heating_system_flow_rate", 0)
    step.setArgument("cooling_system_flow_rate", 0)
    step.setArgument("hvac_distribution_system_type_dse", false)
    step.setArgument("annual_heating_dse", 0.8)
    step.setArgument("annual_cooling_dse", 0.7)
    step.setArgument("hvac_control_type", "manual thermostat")
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
    step.setArgument("mech_vent_fan_type", "none")
    step.setArgument("mech_vent_tested_flow_rate", 110)
    step.setArgument("mech_vent_rated_flow_rate", 0)
    step.setArgument("mech_vent_hours_in_operation", 24)
    step.setArgument("mech_vent_total_recovery_efficiency", 0.48)
    step.setArgument("mech_vent_adjusted_total_recovery_efficiency", 0)
    step.setArgument("mech_vent_sensible_recovery_efficiency", 0.72)
    step.setArgument("mech_vent_adjusted_sensible_recovery_efficiency", 0)
    step.setArgument("mech_vent_fan_power", 30)
    step.setArgument("water_heater_type_1", "storage water heater")
    step.setArgument("water_heater_fuel_type_1", "electricity")
    step.setArgument("water_heater_location_1", "living space")
    step.setArgument("water_heater_tank_volume_1", "40")
    step.setArgument("water_heater_fraction_dhw_load_served_1", 1)
    step.setArgument("water_heater_heating_capacity_1", Constants.SizingAuto)
    step.setArgument("water_heater_energy_factor_1", Constants.Auto)
    step.setArgument("water_heater_uniform_energy_factor_1", 0)
    step.setArgument("water_heater_recovery_efficiency_1", 0.76)
    step.setArgument("water_heater_uses_desuperheater_1", false)
    step.setArgument("water_heater_standby_loss_1", 0)
    step.setArgument("water_heater_jacket_rvalue_1", 0)
    step.setArgument("water_heater_type_2", "none")
    step.setArgument("water_heater_fuel_type_2", "electricity")
    step.setArgument("water_heater_location_2", Constants.Auto)
    step.setArgument("water_heater_tank_volume_2", Constants.Auto)
    step.setArgument("water_heater_fraction_dhw_load_served_2", 1)
    step.setArgument("water_heater_heating_capacity_2", Constants.SizingAuto)
    step.setArgument("water_heater_energy_factor_2", Constants.Auto)
    step.setArgument("water_heater_uniform_energy_factor_2", 0)
    step.setArgument("water_heater_recovery_efficiency_2", 0.76)
    step.setArgument("water_heater_uses_desuperheater_2", false)
    step.setArgument("water_heater_standby_loss_2", 0)
    step.setArgument("water_heater_jacket_rvalue_2", 0)
    step.setArgument("hot_water_distribution_system_type", "Standard")
    step.setArgument("standard_piping_length", 50)
    step.setArgument("recirculation_control_type", "no control")
    step.setArgument("recirculation_piping_length", 50)
    step.setArgument("recirculation_branch_piping_length", 50)
    step.setArgument("recirculation_pump_power", 50)
    step.setArgument("hot_water_distribution_pipe_r_value", 0.0)
    step.setArgument("dwhr_facilities_connected", "none")
    step.setArgument("dwhr_equal_flow", true)
    step.setArgument("dwhr_efficiency", 0.55)
    step.setArgument("shower_low_flow", true)
    step.setArgument("sink_low_flow", false)
    step.setArgument("solar_thermal_system_type", "none")
    step.setArgument("solar_thermal_collector_area", 40.0)
    step.setArgument("solar_thermal_collector_loop_type", "liquid direct")
    step.setArgument("solar_thermal_collector_type", "evacuated tube")
    step.setArgument("solar_thermal_collector_azimuth", 180)
    step.setArgument("solar_thermal_collector_tilt", 20)
    step.setArgument("solar_thermal_collector_rated_optical_efficiency", 0.5)
    step.setArgument("solar_thermal_collector_rated_thermal_losses", 0.2799)
    step.setArgument("solar_thermal_storage_volume", 60)
    step.setArgument("solar_thermal_solar_fraction", 0)
    step.setArgument("pv_system_module_type", "none")
    step.setArgument("pv_system_location", "roof")
    step.setArgument("pv_system_tracking", "fixed")
    step.setArgument("pv_system_array_azimuth", 180)
    step.setArgument("pv_system_array_tilt", 20)
    step.setArgument("pv_system_max_power_output", 4000)
    step.setArgument("pv_system_inverter_efficiency", 0.96)
    step.setArgument("pv_system_system_losses_fraction", 0.14)
    step.setArgument("has_clothes_washer", true)
    step.setArgument("clothes_washer_location", "living space")
    step.setArgument("clothes_washer_integrated_modified_energy_factor", 0.8)
    step.setArgument("clothes_washer_rated_annual_kwh", 700.0)
    step.setArgument("clothes_washer_label_electric_rate", 0.1)
    step.setArgument("clothes_washer_label_gas_rate", 0.6)
    step.setArgument("clothes_washer_label_annual_gas_cost", 25.0)
    step.setArgument("clothes_washer_capacity", 3.0)
    step.setArgument("has_clothes_dryer", true)
    step.setArgument("clothes_dryer_location", "living space")
    step.setArgument("clothes_dryer_fuel_type", "electricity")
    step.setArgument("clothes_dryer_energy_factor", 2.95)
    step.setArgument("clothes_dryer_combined_energy_factor", 0)
    step.setArgument("clothes_dryer_control_type", "timer")
    step.setArgument("has_dishwasher", true)
    step.setArgument("dishwasher_energy_factor", 0)
    step.setArgument("dishwasher_rated_annual_kwh", 450.0)
    step.setArgument("dishwasher_place_setting_capacity", 12)
    step.setArgument("has_refrigerator", true)
    step.setArgument("refrigerator_location", "living space")
    step.setArgument("refrigerator_rated_annual_kwh", 650.0)
    step.setArgument("refrigerator_adjusted_annual_kwh", 0)
    step.setArgument("has_cooking_range", true)
    step.setArgument("cooking_range_fuel_type", "electricity")
    step.setArgument("cooking_range_is_induction", false)
    step.setArgument("has_oven", true)
    step.setArgument("oven_is_convection", false)
    step.setArgument("has_lighting", true)
    step.setArgument("ceiling_fan_efficiency", 100)
    step.setArgument("ceiling_fan_quantity", 0)
    step.setArgument("plug_loads_plug_load_type_1", "other")
    step.setArgument("plug_loads_annual_kwh_1", 0)
    step.setArgument("plug_loads_frac_sensible_1", 0)
    step.setArgument("plug_loads_frac_latent_1", 0)
    step.setArgument("plug_loads_plug_load_type_2", "TV other")
    step.setArgument("plug_loads_annual_kwh_2", 0)
    step.setArgument("plug_loads_frac_sensible_2", 0)
    step.setArgument("plug_loads_frac_latent_2", 0)
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
  elsif ['base-appliances-dishwasher-ef.osw'].include? osw_file
    step.setArgument("dishwasher_energy_factor", 0.5)
    step.setArgument("dishwasher_rated_annual_kwh", 0)
  elsif ['base-appliances-dryer-cef.osw'].include? osw_file
    step.setArgument("clothes_dryer_energy_factor", 0)
    step.setArgument("clothes_dryer_combined_energy_factor", 2.62)
    step.setArgument("clothes_dryer_control_type", "moisture")
  elsif ['base-appliances-gas.osw'].include? osw_file
    step.setArgument("clothes_dryer_fuel_type", "natural gas")
    step.setArgument("clothes_dryer_energy_factor", 2.67)
    step.setArgument("clothes_dryer_control_type", "moisture")
  elsif ['base-appliances-none.osw'].include? osw_file
    step.setArgument("has_clothes_washer", false)
    step.setArgument("has_clothes_dryer", false)
    step.setArgument("has_dishwasher", false)
    step.setArgument("has_refrigerator", false)
    step.setArgument("has_cooking_range", false)
    step.setArgument("has_oven", false)
  elsif ['base-appliances-oil.osw'].include? osw_file
    step.setArgument("clothes_dryer_fuel_type", "fuel oil")
    step.setArgument("clothes_dryer_energy_factor", 2.67)
    step.setArgument("clothes_dryer_control_type", "moisture")
  elsif ['base-appliances-propane.osw'].include? osw_file
    step.setArgument("clothes_dryer_fuel_type", "propane")
    step.setArgument("clothes_dryer_energy_factor", 2.67)
    step.setArgument("clothes_dryer_control_type", "moisture")
  elsif ['base-appliances-refrigerator-adjusted.osw'].include? osw_file
    step.setArgument("refrigerator_adjusted_annual_kwh", 600.0)
  elsif ['base-appliances-washer-imef.osw'].include? osw_file
    step.setArgument("clothes_washer_integrated_modified_energy_factor", 0.73)
  elsif ['base-appliances-wood.osw'].include? osw_file
    step.setArgument("clothes_dryer_fuel_type", "wood")
    step.setArgument("clothes_dryer_energy_factor", 2.67)
    step.setArgument("clothes_dryer_control_type", "moisture")
  elsif ['base-atticroof-cathedral.osw'].include? osw_file
    step.setArgument("attic_type", "attic - conditioned")
    step.setArgument("roof_ceiling_r", 25.8)
    step.setArgument("supply_duct_location", "living space")
    step.setArgument("return_duct_location", "living space")
  elsif ['base-atticroof-conditioned.osw'].include? osw_file
    step.setArgument("cfa", 3600.0)
    step.setArgument("num_floors", 2)
    step.setArgument("attic_type", "attic - conditioned")
    step.setArgument("roof_ceiling_r", 25.8)
    step.setArgument("supply_duct_location", "living space")
    step.setArgument("return_duct_location", "living space")
  elsif ['base-atticroof-flat.osw'].include? osw_file
    step.setArgument("roof_type", "flat")
    step.setArgument("roof_ceiling_r", 25.8)
    step.setArgument("supply_duct_location", "living space")
    step.setArgument("return_duct_location", "living space")
  elsif ['base-atticroof-radiant-barrier.osw'].include? osw_file
    step.setArgument("roof_radiant_barrier", true)
  elsif ['base-atticroof-unvented-insulated-roof.osw'].include? osw_file
    step.setArgument("roof_ceiling_r", 25.8)
  elsif ['base-atticroof-vented.osw'].include? osw_file
    step.setArgument("attic_type", "attic - vented")
    step.setArgument("supply_duct_location", "attic - vented")
    step.setArgument("return_duct_location", "attic - vented")
  elsif ['base-dhw-combi-tankless.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
    step.setArgument("water_heater_type_1", "space-heating boiler with tankless coil")
  elsif ['base-dhw-combi-tankless-outside.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
    step.setArgument("water_heater_type_1", "space-heating boiler with tankless coil")
    step.setArgument("water_heater_location_1", "other exterior")
  elsif ['base-dhw-desuperheater.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("water_heater_uses_desuperheater_1", true)
  elsif ['base-dhw-desuperheater-2-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("cooling_system_cooling_efficiency", 18.0)
    step.setArgument("water_heater_uses_desuperheater_1", true)
  elsif ['base-dhw-desuperheater-gshp.osw'].include? osw_file
    step.setArgument("heating_system_type", "ground-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 3.6)
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("cooling_system_type", "ground-to-air")
    step.setArgument("cooling_system_cooling_efficiency", 16.6)
    step.setArgument("heat_pump_backup_fuel", "electricity")
    step.setArgument("water_heater_uses_desuperheater_1", true)
  elsif ['base-dhw-desuperheater-tankless.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("water_heater_type_1", "instantaneous water heater")
    step.setArgument("water_heater_uses_desuperheater_1", true)
  elsif ['base-dhw-desuperheater-var-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("cooling_system_cooling_efficiency", 24.0)
    step.setArgument("water_heater_uses_desuperheater_1", true)
  elsif ['base-dhw-dwhr.osw'].include? osw_file
    step.setArgument("dwhr_facilities_connected", "all")
  elsif ['base-dhw-indirect.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
    step.setArgument("water_heater_type_1", "space-heating boiler with storage tank")
  elsif ['base-dhw-indirect-dse.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
    step.setArgument("hvac_distribution_system_type_dse", true)
  elsif ['base-dhw-indirect-outside.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
    step.setArgument("water_heater_type_1", "space-heating boiler with storage tank")
    step.setArgument("water_heater_location_1", "other exterior")
  elsif ['base-dhw-indirect-standbyloss.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
    step.setArgument("water_heater_standby_loss_1", 1.0)
  elsif ['base-dhw-jacket-electric.osw'].include? osw_file
    step.setArgument("water_heater_jacket_rvalue_1", 10.0)
  elsif ['base-dhw-jacket-gas.osw'].include? osw_file
    step.setArgument("water_heater_fuel_type_1", "natural gas")
    step.setArgument("water_heater_jacket_rvalue_1", 10.0)
  elsif ['base-dhw-jacket-hpwh.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "heat pump water heater")
    step.setArgument("water_heater_jacket_rvalue_1", 10.0)
  elsif ['base-dhw-jacket-indirect.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
    step.setArgument("water_heater_type_1", "space-heating boiler with storage tank")
    step.setArgument("water_heater_jacket_rvalue_1", 10.0)
  elsif ['base-dhw-low-flow-fixtures.osw'].include? osw_file
    step.setArgument("sink_low_flow", true)
  elsif ['base-dhw-multiple.osw'].include? osw_file
    step.setArgument("water_heater_type_2", "storage water heater")
    step.setArgument("water_heater_fuel_type_2", "natural gas")
    step.setArgument("water_heater_fraction_dhw_load_served_1", 0.5)
    step.setArgument("water_heater_fraction_dhw_load_served_2", 0.5)
  elsif ['base-dhw-none.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "none")
  elsif ['base-dhw-recirc-demand.osw'].include? osw_file
    step.setArgument("hot_water_distribution_system_type", "Recirculation")
    step.setArgument("recirculation_control_type", "presence sensor demand control")
    step.setArgument("hot_water_distribution_pipe_r_value", 3.0)
  elsif ['base-dhw-recirc-manual.osw'].include? osw_file
    step.setArgument("hot_water_distribution_system_type", "Recirculation")
    step.setArgument("recirculation_control_type", "manual demand control")
    step.setArgument("hot_water_distribution_pipe_r_value", 3.0)
  elsif ['base-dhw-recirc-nocontrol.osw'].include? osw_file
    step.setArgument("hot_water_distribution_system_type", "Recirculation")
  elsif ['base-dhw-recirc-temperature.osw'].include? osw_file
    step.setArgument("hot_water_distribution_system_type", "Recirculation")
    step.setArgument("recirculation_control_type", "temperature")
  elsif ['base-dhw-recirc-timer.osw'].include? osw_file
    step.setArgument("hot_water_distribution_system_type", "Recirculation")
    step.setArgument("recirculation_control_type", "timer")
  elsif ['base-dhw-solar-direct-evacuated-tube.osw'].include? osw_file
    step.setArgument("solar_thermal_system_type", "hot water")
  elsif ['base-dhw-solar-direct-flat-plate.osw'].include? osw_file
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_collector_type", "single glazing black")
    step.setArgument("solar_thermal_collector_rated_optical_efficiency", 0.77)
    step.setArgument("solar_thermal_collector_rated_thermal_losses", 0.793)
  elsif ['base-dhw-solar-direct-ics.osw'].include? osw_file
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_collector_type", "integrated collector storage")
    step.setArgument("solar_thermal_collector_rated_optical_efficiency", 0.77)
    step.setArgument("solar_thermal_collector_rated_thermal_losses", 0.793)
  elsif ['base-dhw-solar-fraction.osw'].include? osw_file
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_solar_fraction", 0.65)
  elsif ['base-dhw-solar-indirect-evacuated-tube.osw'].include? osw_file
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_collector_loop_type", "liquid indirect")
  elsif ['base-dhw-solar-indirect-flat-plate.osw'].include? osw_file
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_collector_loop_type", "liquid indirect")
    step.setArgument("solar_thermal_collector_type", "single glazing black")
    step.setArgument("solar_thermal_collector_rated_optical_efficiency", 0.77)
    step.setArgument("solar_thermal_collector_rated_thermal_losses", 0.793)
  elsif ['base-dhw-solar-thermosyphon-evacuated-tube.osw'].include? osw_file
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_collector_loop_type", "passive thermosyphon")
  elsif ['base-dhw-solar-thermosyphon-flat-plate.osw'].include? osw_file
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_collector_loop_type", "passive thermosyphon")
    step.setArgument("solar_thermal_collector_type", "single glazing black")
    step.setArgument("solar_thermal_collector_rated_optical_efficiency", 0.77)
    step.setArgument("solar_thermal_collector_rated_thermal_losses", 0.793)
  elsif ['base-dhw-solar-thermosyphon-ics.osw'].include? osw_file
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_collector_loop_type", "passive thermosyphon")
    step.setArgument("solar_thermal_collector_type", "integrated collector storage")
    step.setArgument("solar_thermal_collector_rated_optical_efficiency", 0.77)
    step.setArgument("solar_thermal_collector_rated_thermal_losses", 0.793)
  elsif ['base-dhw-tank-gas.osw'].include? osw_file
    step.setArgument("water_heater_fuel_type_1", "natural gas")
  elsif ['base-dhw-tank-gas-outside.osw'].include? osw_file
    step.setArgument("water_heater_fuel_type_1", "natural gas")
    step.setArgument("water_heater_location_1", "other exterior")
  elsif ['base-dhw-tank-heat-pump.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "heat pump water heater")
  elsif ['base-dhw-tank-heat-pump-outside.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "heat pump water heater")
    step.setArgument("water_heater_location_1", "other exterior")
  elsif ['base-dhw-tank-heat-pump-with-solar.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "heat pump water heater")
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_collector_loop_type", "liquid indirect")
    step.setArgument("solar_thermal_collector_rated_optical_efficiency", 0.77)
    step.setArgument("solar_thermal_collector_rated_thermal_losses", 0.793)
  elsif ['base-dhw-tank-heat-pump-with-solar-fraction.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "heat pump water heater")
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_solar_fraction", 0.65)
  elsif ['base-dhw-tankless-electric.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "instantaneous water heater")
  elsif ['base-dhw-tankless-electric-outside.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "instantaneous water heater")
    step.setArgument("water_heater_location_1", "other exterior")
  elsif ['base-dhw-tankless-gas.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "instantaneous water heater")
    step.setArgument("water_heater_fuel_type_1", "natural gas")
  elsif ['base-dhw-tankless-gas-with-solar.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "instantaneous water heater")
    step.setArgument("water_heater_fuel_type_1", "natural gas")
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_collector_loop_type", "liquid indirect")
  elsif ['base-dhw-tankless-gas-with-solar-fraction.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "instantaneous water heater")
    step.setArgument("water_heater_fuel_type_1", "natural gas")
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_solar_fraction", 0.65)
  elsif ['base-dhw-tankless-oil.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "instantaneous water heater")
    step.setArgument("water_heater_fuel_type_1", "fuel oil")
  elsif ['base-dhw-tankless-propane.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "instantaneous water heater")
    step.setArgument("water_heater_fuel_type_1", "propane")
  elsif ['base-dhw-tankless-wood.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "instantaneous water heater")
    step.setArgument("water_heater_fuel_type_1", "wood")
  elsif ['base-dhw-tank-oil.osw'].include? osw_file
    step.setArgument("water_heater_fuel_type_1", "fuel oil")
  elsif ['base-dhw-tank-propane.osw'].include? osw_file
    step.setArgument("water_heater_fuel_type_1", "propane")
  elsif ['base-dhw-tank-wood.osw'].include? osw_file
    step.setArgument("water_heater_fuel_type_1", "wood")
  elsif ['base-dhw-uef.osw'].include? osw_file
    step.setArgument("water_heater_uniform_energy_factor_1", 0.93)
  elsif ['base-enclosure-2stories.osw'].include? osw_file
    step.setArgument("cfa", 4050.0)
    step.setArgument("num_floors", 2)
  elsif ['base-enclosure-2stories-garage.osw'].include? osw_file
    step.setArgument("cfa", 4050.0)
    step.setArgument("num_floors", 2)
    step.setArgument("garage_width", 12.0)
  elsif ['base-enclosure-adiabatic-surfaces.osw'].include? osw_file

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
    step.setArgument("front_skylight_area", 15)
    step.setArgument("back_skylight_area", 15)
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
  elsif ['base-foundation-ambient.osw'].include? osw_file
    step.setArgument("foundation_type", "ambient")
  elsif ['base-foundation-complex.osw'].include? osw_file

  elsif ['base-foundation-conditioned-basement-slab-insulation.osw'].include? osw_file
    step.setArgument("slab_under_r", 10)
  elsif ['base-foundation-conditioned-basement-wall-interior-insulation.osw'].include? osw_file
    step.setArgument("foundation_ceiling_r", 0)
    step.setArgument("foundation_wall_interior_r", 10.0)
  elsif ['base-foundation-multiple.osw'].include? osw_file

  elsif ['base-foundation-slab.osw'].include? osw_file
    step.setArgument("foundation_type", "slab")
    step.setArgument("slab_perimeter_r", 5)
  elsif ['base-foundation-unconditioned-basement.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
  elsif ['base-foundation-unconditioned-basement-above-grade.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
  elsif ['base-foundation-unconditioned-basement-assembly-r.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
  elsif ['base-foundation-unconditioned-basement-wall-insulation.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
    step.setArgument("foundation_ceiling_r", 0)
  elsif ['base-foundation-unvented-crawlspace.osw'].include? osw_file
    step.setArgument("foundation_type", "crawlspace - unvented")
    step.setArgument("foundation_height", 3.0)
  elsif ['base-foundation-vented-crawlspace.osw'].include? osw_file
    step.setArgument("foundation_type", "crawlspace - vented")
    step.setArgument("foundation_height", 3.0)
    step.setArgument("vented_crawlspace_sla", 0.00667)
  elsif ['base-foundation-walkout-basement.osw'].include? osw_file

  elsif ['base-hvac-air-to-air-heat-pump-1-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 7.7)
    step.setArgument("cooling_system_type", "air-to-air")
  elsif ['base-hvac-air-to-air-heat-pump-1-speed.detailed.osw'].include? osw_file

  elsif ['base-hvac-ait-to-air-heat-pump-2-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 9.3)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("cooling_system_cooling_efficiency", 18.0)
  elsif ['base-hvac-air-to-air-heat-pump-2-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-air-to-air-heat-pump-var-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 10.0)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("cooling_system_cooling_efficiency", 22.0)
  elsif ['base-hvac-air-to-air-heat-pump-var-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-boiler-elec-only.osw'].include? osw_file # HERE
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 1.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
  elsif ['base-hvac-boiler-gas-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-boiler-gas-only-no-eae.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-boiler-oil-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_fuel", "fuel oil")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-boiler-propane-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_fuel", "propane")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-boiler-wood-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "Boiler")
    step.setArgument("heating_system_fuel", "wood")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-central-ac-only-1-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
  elsif ['base-hvac-central-ac-only-1-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-central-ac-only-2-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("cooling_system_cooling_efficiency", 18.0)
  elsif ['base-hvac-central-ac-only-2-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-central-ac-only-var-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("cooling_system_cooling_efficiency", 24.0)
  elsif ['base-hvac-central-ac-only-var-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-central-ac-plus-air-to-air-heat-pump-heating.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 7.7)
  elsif ['base-hvac-dse.osw'].include? osw_file
    step.setArgument("hvac_distribution_system_type_dse", true)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 7.7)
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("heat_pump_backup_fuel", "natural gas")
    step.setArgument("heat_pump_backup_heating_efficiency", 0.95)
    step.setArgument("heat_pump_backup_heating_capacity", 36000.0)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 7.7)
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("heat_pump_backup_fuel", "electricity")
    step.setArgument("heat_pump_backup_heating_capacity", 36000.0)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-oil.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 7.7)
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("heat_pump_backup_fuel", "fuel oil")
    step.setArgument("heat_pump_backup_heating_efficiency", 0.95)
    step.setArgument("heat_pump_backup_heating_capacity", 36000.0)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-propane.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 7.7)
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("heat_pump_backup_fuel", "propane")
    step.setArgument("heat_pump_backup_heating_efficiency", 0.95)
    step.setArgument("heat_pump_backup_heating_capacity", 36000.0)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 9.3)
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("cooling_system_cooling_efficiency", 18.0)
    step.setArgument("heat_pump_backup_fuel", "natural gas")
    step.setArgument("heat_pump_backup_heating_efficiency", 0.95)
    step.setArgument("heat_pump_backup_heating_capacity", 36000.0)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 10.0)
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("cooling_system_cooling_efficiency", 22.0)
    step.setArgument("heat_pump_backup_fuel", "natural gas")
    step.setArgument("heat_pump_backup_heating_efficiency", 0.95)
    step.setArgument("heat_pump_backup_heating_capacity", 36000.0)
  elsif ['base-hvac-dual-fuel-mini-split-heat-pump-ducted.osw'].include? osw_file
    step.setArgument("heating_system_type", "mini-split")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 10.0)
    step.setArgument("heating_system_heating_capacity", 52000.0)
    step.setArgument("cooling_system_type", "mini-split")
    step.setArgument("cooling_system_cooling_efficiency", 19.0)
    step.setArgument("heat_pump_backup_fuel", "natural gas")
    step.setArgument("heat_pump_backup_heating_efficiency", 0.95)
    step.setArgument("heat_pump_backup_heating_capacity", 36000.0)
    step.setArgument("mini_split_is_ducted", true)
    step.setArgument("supply_duct_leakage_value", 15.0)
    step.setArgument("return_duct_leakage_value", 5.0)
    step.setArgument("supply_duct_insulation_r_value", 0.0)
    step.setArgument("supply_duct_surface_area", 30.0)
    step.setArgument("return_duct_surface_area", 10.0)
  elsif ['base-hvac-ducts-in-conditioned-space.osw'].include? osw_file
    step.setArgument("supply_duct_leakage_value", 1.5)
    step.setArgument("return_duct_leakage_value", 1.5)
    step.setArgument("supply_duct_location", "living space")
    step.setArgument("return_duct_location", "living space")
  elsif ['base-hvac-ducts-leakage-percent.osw'].include? osw_file
    step.setArgument("supply_duct_leakage_units", "Percent")
    step.setArgument("return_duct_leakage_units", "Percent")
    step.setArgument("supply_duct_leakage_value", 0.1)
    step.setArgument("return_duct_leakage_value", 0.05)
  elsif ['base-hvac-ducts-locations.osw'].include? osw_file
    step.setArgument("cfa", 1350.0)
    step.setArgument("foundation_type", "crawlspace - vented")
    step.setArgument("supply_duct_location", "crawlspace - vented")
    step.setArgument("water_heater_location_1", "crawlspace - vented")
  elsif ['base-hvac-ducts-multiple.osw'].include? osw_file

  elsif ['base-hvac-ducts-outside.osw'].include? osw_file
    step.setArgument("supply_duct_location", "outside")
    step.setArgument("return_duct_location", "outside")
  elsif ['base-hvac-elec-resistance-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "ElectricResistance")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 1.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-evap-cooler-furnace-gas.osw'].include? osw_file
    step.setArgument("cooling_system_type", "evaporative cooler")
  elsif ['base-hvac-evap-cooler-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("cooling_system_type", "evaporative cooler")
  elsif ['base-hvac-evap-cooler-only-ducted.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("cooling_system_type", "evaporative cooler")
    step.setArgument("evap_cooler_is_ducted", true)
  elsif ['base-hvac-flowrate.osw'].include? osw_file
    step.setArgument("heating_system_flow_rate", 1920.0)
    step.setArgument("cooling_system_flow_rate", 1440.0)
  elsif ['base-hvac-furnace-elec-only.osw'].include? osw_file
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 1.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-furnace-gas-central-ac-2-speed.osw'].include? osw_file
    step.setArgument("cooling_system_cooling_efficiency", 18.0)
  elsif ['base-hvac-furnace-gas-central-ac-var-speed.osw'].include? osw_file
    step.setArgument("cooling_system_cooling_efficiency", 24.0)
  elsif ['base-hvac-furnace-gas-only.osw'].include? osw_file
    step.setArgument("heating_system_electric_auxiliary_energy", 700.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-furnace-gas-only-no-eae.osw'].include? osw_file
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-furnace-gas-room-ac.osw'].include? osw_file
    step.setArgument("cooling_system_type", "room air conditioner")
    step.setArgument("cooling_system_cooling_efficiency", 8.5)
  elsif ['base-hvac-furnace-oil-only.osw'].include? osw_file
    step.setArgument("heating_system_fuel", "fuel oil")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-furnace-propane-only.osw'].include? osw_file
    step.setArgument("heating_system_fuel", "propane")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-furnace-wood-only.osw'].include? osw_file
    step.setArgument("heating_system_fuel", "wood")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-furnace-x3-dse.osw'].include? osw_file

  elsif ['base-hvac-ground-to-air-heat-pump.osw'].include? osw_file
    step.setArgument("heating_system_type", "ground-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 3.6)
    step.setArgument("cooling_system_type", "ground-to-air")
    step.setArgument("cooling_system_cooling_efficiency", 16.6)
  elsif ['base-hvac-ground-to-air-heat-pump-detailed.osw'].include? osw_file

  elsif ['base-hvac-ideal-air.osw'].include? osw_file

  elsif ['base-hvac-mini-split-heat-pump-ducted.osw'].include? osw_file
    step.setArgument("heating_system_type", "mini-split")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 10.0)
    step.setArgument("cooling_system_type", "mini-split")
    step.setArgument("cooling_system_cooling_efficiency", 19.0)
    step.setArgument("mini_split_is_ducted", true)
  elsif ['base-hvac-mini-split-heat-pump-ducted-detailed.osw'].include? osw_file

  elsif ['base-hvac-mini-split-heat-pump-ductless.osw'].include? osw_file
    step.setArgument("heating_system_type", "mini-split")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 10.0)
    step.setArgument("cooling_system_type", "mini-split")
    step.setArgument("cooling_system_cooling_efficiency", 19.0)
  elsif ['base-hvac-mini-split-heat-pump-ductless-no-backup.osw'].include? osw_file
    step.setArgument("heating_system_type", "mini-split")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 10.0)
    step.setArgument("cooling_system_type", "mini-split")
    step.setArgument("cooling_system_cooling_efficiency", 19.0)
    step.setArgument("heat_pump_backup_fuel", "none")
  elsif ['base-hvac-multiple.osw'].include? osw_file

  elsif ['base-hvac-none.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-none-no-fuel-access.osw'].include? osw_file

  elsif ['base-hvac-portable-heater-electric-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "PortableHeater")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 1.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-programmable-thermostat.osw'].include? osw_file
    step.setArgument("hvac_control_type", "programmable thermostat")
    step.setArgument("heating_setback_temp", 66)
    step.setArgument("heating_setback_hours_per_week", 49)
    step.setArgument("heating_setback_start_hour", 23)
    step.setArgument("cooling_setup_temp", 80)
    step.setArgument("cooling_setup_hours_per_week", 42)
    step.setArgument("cooling_setup_start_hour", 9)
  elsif ['base-hvac-room-ac-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "none")
    step.setArgument("cooling_system_type", "room air conditioner")
    step.setArgument("cooling_system_cooling_efficiency", 8.5)
  elsif ['base-hvac-room-ac-only-detailed.osw'].include? osw_file

  elsif ['base-hvac-setpoints.osw'].include? osw_file
    step.setArgument("heating_setpoint_temp", 60.0)
    step.setArgument("cooling_setpoint_temp", 80.0)
  elsif ['base-hvac-stove-oil-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "Stove")
    step.setArgument("heating_system_fuel", "fuel oil")
    step.setArgument("heating_system_heating_efficiency", 0.8)
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-stove-oil-only-no-eae.osw'].include? osw_file
    step.setArgument("heating_system_type", "Stove")
    step.setArgument("heating_system_fuel", "fuel oil")
    step.setArgument("heating_system_heating_efficiency", 0.8)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-stove-wood-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "Stove")
    step.setArgument("heating_system_fuel", "wood")
    step.setArgument("heating_system_heating_efficiency", 0.8)
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-undersized.osw'].include? osw_file
    step.setArgument("heating_system_heating_capacity", 6400.0)
    step.setArgument("cooling_system_cooling_capacity", 4800.0)
  elsif ['base-hvac-wall-furnace-elec-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "WallFurnace")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 1.0)
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-wall-furnace-propane-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "WallFurnace")
    step.setArgument("heating_system_fuel", "propane")
    step.setArgument("heating_system_heating_efficiency", 0.8)
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-wall-furnace-propane-only-no-eae.osw'].include? osw_file
    step.setArgument("heating_system_type", "WallFurnace")
    step.setArgument("heating_system_fuel", "propane")
    step.setArgument("heating_system_heating_efficiency", 0.8)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-wall-furnace-wood-only.osw'].include? osw_file
    step.setArgument("heating_system_type", "WallFurnace")
    step.setArgument("heating_system_fuel", "wood")
    step.setArgument("heating_system_heating_efficiency", 0.8)
    step.setArgument("heating_system_electric_auxiliary_energy", 200.0)
    step.setArgument("cooling_system_type", "none")
  elsif ['base-infiltration-ach-natural.osw'].include? osw_file
    step.setArgument("living_constant_ach_natural", 0.67)
  elsif ['base-location-baltimore-md.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "../weather/USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw")
  elsif ['base-location-dallas-tx.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "../weather/USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw")
  elsif ['base-location-duluth-mn.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "../weather/USA_MN_Duluth.Intl.AP.727450_TMY3.epw")
  elsif ['base-location-epw-filename.osw'].include? osw_file

  elsif ['base-location-miami-fl.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "../weather/USA_FL_Miami.Intl.AP.722020_TMY3.epw")
  elsif ['base-mechvent-balanced.osw'].include? osw_file
    step.setArgument("mech_vent_fan_type", "balanced")
    step.setArgument("mech_vent_fan_power", 60)
  elsif ['base-mechvent-cfis.osw'].include? osw_file
    step.setArgument("mech_vent_fan_type", "central fan integrated supply")
    step.setArgument("mech_vent_tested_flow_rate", 330)
    step.setArgument("mech_vent_hours_in_operation", 8)
    step.setArgument("mech_vent_fan_power", 300)
  elsif ['base-mechvent-cfis-24hrs.osw'].include? osw_file
    step.setArgument("mech_vent_fan_type", "central fan integrated supply")
    step.setArgument("mech_vent_tested_flow_rate", 330)
    step.setArgument("mech_vent_fan_power", 300)
  elsif ['base-mechvent-erv.osw'].include? osw_file
    step.setArgument("mech_vent_fan_type", "energy recovery ventilator")
    step.setArgument("mech_vent_fan_power", 60)
  elsif ['base-mechvent-erv-atre-asre.osw'].include? osw_file
    step.setArgument("mech_vent_fan_type", "energy recovery ventilator")
    step.setArgument("mech_vent_adjusted_total_recovery_efficiency", 0.526)
    step.setArgument("mech_vent_adjusted_sensible_recovery_efficiency", 0.79)
    step.setArgument("mech_vent_fan_power", 60)
  elsif ['base-mechvent-exhaust.osw'].include? osw_file
    step.setArgument("mech_vent_fan_type", "exhaust only")
  elsif ['base-mechvent-exhaust-rated-flow-rate.osw'].include? osw_file
    step.setArgument("mech_vent_fan_type", "exhaust only")
    step.setArgument("mech_vent_rated_flow_rate", 110)
  elsif ['base-mechvent-hrv.osw'].include? osw_file
    step.setArgument("mech_vent_fan_type", "heat recovery ventilator")
    step.setArgument("mech_vent_fan_power", 60)
  elsif ['base-mechvent-hrv-asre.osw'].include? osw_file
    step.setArgument("mech_vent_fan_type", "heat recovery ventilator")
    step.setArgument("mech_vent_adjusted_sensible_recovery_efficiency", 0.79)
    step.setArgument("mech_vent_fan_power", 60)
  elsif ['base-mechvent-supply.osw'].include? osw_file
    step.setArgument("mech_vent_fan_type", "supply only")
  elsif ['base-misc-ceiling-fans.osw'].include? osw_file

  elsif ['base-misc-lighting-none.osw'].include? osw_file
    step.setArgument("has_lighting", false)
  elsif ['base-misc-loads-detailed.osw'].include? osw_file
    step.setArgument("plug_loads_annual_kwh_1", 7302.0)
    step.setArgument("plug_loads_frac_sensible_1", 0.82)
    step.setArgument("plug_loads_frac_latent_1", 0.18)
    step.setArgument("plug_loads_annual_kwh_2", 400.0)
  elsif ['base-misc-number-of-occupants.osw'].include? osw_file
    step.setArgument("num_occupants", 5.0)
  elsif ['base-pv-array-1axis.osw'].include? osw_file
    step.setArgument("pv_system_module_type", "standard")
    step.setArgument("pv_system_location", "ground")
    step.setArgument("pv_system_tracking", "1-axis")
  elsif ['base-pv-array-1axis-backtracked.osw'].include? osw_file
    step.setArgument("pv_system_module_type", "standard")
    step.setArgument("pv_system_location", "ground")
    step.setArgument("pv_system_tracking", "1-axis backtracked")
  elsif ['base-pv-array-2axis.osw'].include? osw_file
    step.setArgument("pv_system_module_type", "standard")
    step.setArgument("pv_system_location", "ground")
    step.setArgument("pv_system_tracking", "2-axis")
  elsif ['base-pv-array-fixed-open-rack.osw'].include? osw_file
    step.setArgument("pv_system_module_type", "standard")
    step.setArgument("pv_system_location", "ground")
  elsif ['base-pv-array-module-premium.osw'].include? osw_file
    step.setArgument("pv_system_module_type", "standard")
  elsif ['base-pv-array-module-standard.osw'].include? osw_file
    step.setArgument("pv_system_module_type", "standard")
  elsif ['base-pv-array-module-thinfilm.osw'].include? osw_file
    step.setArgument("pv_system_module_type", "thin film")
  elsif ['base-pv-multiple.osw'].include? osw_file

  elsif ['base-site-neighbors.osw'].include? osw_file
    step.setArgument("neighbor_left_distance", 10)
    step.setArgument("neighbor_right_distance", 15)
    step.setArgument("neighbor_right_height", 12)
  end
  return step
end
