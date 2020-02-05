def create_osws
  this_dir = File.dirname(__FILE__)
  tests_dir = File.join(this_dir, "BuildResidentialHPXML/tests")

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
    'base-dhw-tank-heat-pump-outside.osw' => 'base.osw',
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
    'base-enclosure-adiabatic-surfaces.osw' => 'base.osw',
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
    # 'base-foundation-unconditioned-basement-assembly-r.osw' => 'base.osw',
    'base-foundation-unconditioned-basement-wall-insulation.osw' => 'base.osw',
    'base-foundation-unvented-crawlspace.osw' => 'base.osw',
    'base-foundation-vented-crawlspace.osw' => 'base.osw',
    # 'base-foundation-walkout-basement.osw' => 'base.osw', # 1 kiva object instead of 4

    'base-hvac-air-to-air-heat-pump-1-speed.osw' => 'base.osw',
    # 'base-hvac-air-to-air-heat-pump-1-speed.detailed.osw' => 'base.osw', # TODO: add HeatingCapacity17F, CoolingSensibleHeatFraction
    'base-hvac-air-to-air-heat-pump-2-speed.osw' => 'base.osw',
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

    'base-misc-ceiling-fans.osw' => 'base.osw',
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

    'base-site-neighbors.osw' => 'base.osw',

    'hvac_partial/base-33percent.osw' => 'base.osw',
    'hvac_partial/base-hvac-air-to-air-heat-pump-1-speed-33percent.osw' => 'base-hvac-air-to-air-heat-pump-1-speed.osw',
    'hvac_partial/base-hvac-air-to-air-heat-pump-2-speed-33percent.osw' => 'base-hvac-air-to-air-heat-pump-2-speed.osw',
    'hvac_partial/base-hvac-air-to-air-heat-pump-var-speed-33percent.osw' => 'base-hvac-air-to-air-heat-pump-var-speed.osw',
    'hvac_partial/base-hvac-boiler-gas-only-33percent.osw' => 'base-hvac-boiler-gas-only.osw',
    'hvac_partial/base-hvac-central-ac-only-1-speed-33percent.osw' => 'base-hvac-central-ac-only-1-speed.osw',
    'hvac_partial/base-hvac-central-ac-only-2-speed-33percent.osw' => 'base-hvac-central-ac-only-2-speed.osw',
    'hvac_partial/base-hvac-central-ac-only-var-speed-33percent.osw' => 'base-hvac-central-ac-only-var-speed.osw',
    'hvac_partial/base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-33percent.osw' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.osw',
    'hvac_partial/base-hvac-elec-resistance-only-33percent.osw' => 'base-hvac-elec-resistance-only.osw',
    'hvac_partial/base-hvac-evap-cooler-only-33percent.osw' => 'base-hvac-evap-cooler-only.osw',
    'hvac_partial/base-hvac-furnace-gas-central-ac-2-speed-33percent.osw' => 'base-hvac-furnace-gas-central-ac-2-speed.osw',
    'hvac_partial/base-hvac-furnace-gas-central-ac-var-speed-33percent.osw' => 'base-hvac-furnace-gas-central-ac-var-speed.osw',
    'hvac_partial/base-hvac-furnace-gas-only-33percent.osw' => 'base-hvac-furnace-gas-only.osw',
    'hvac_partial/base-hvac-furnace-gas-room-ac-33percent.osw' => 'base-hvac-furnace-gas-room-ac.osw',
    'hvac_partial/base-hvac-ground-to-air-heat-pump-33percent.osw' => 'base-hvac-ground-to-air-heat-pump.osw',
    'hvac_partial/base-hvac-mini-split-heat-pump-ducted-33percent.osw' => 'base-hvac-mini-split-heat-pump-ducted.osw',
    'hvac_partial/base-hvac-room-ac-only-33percent.osw' => 'base-hvac-room-ac-only.osw',
    'hvac_partial/base-hvac-stove-oil-only-33percent.osw' => 'base-hvac-stove-oil-only.osw',
    'hvac_partial/base-hvac-wall-furnace-propane-only-33percent.osw' => 'base-hvac-wall-furnace-propane-only.osw'
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

  puts "\n"
end

def get_values(osw_file, step)
  step.setArgument("hpxml_path", "../HPXMLtoOpenStudio/tests/built_residential_hpxml/#{File.basename(osw_file, ".*")}.xml")

  if ['base.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "USA_CO_Denver.Intl.AP.725650_TMY3.epw")
    step.setArgument("schedules_output_path", "HPXMLtoOpenStudio/tests/run/schedules.csv")
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
    step.setArgument("foundation_ceiling_r", 0)
    step.setArgument("foundation_wall_r", 8.9)
    step.setArgument("foundation_wall_distance_to_top", 0.0)
    step.setArgument("foundation_wall_distance_to_bottom", 8.0)
    step.setArgument("foundation_wall_depth_below_grade", 8.0)
    step.setArgument("slab_perimeter_r", 0)
    step.setArgument("slab_perimeter_depth", 0)
    step.setArgument("slab_under_r", 0)
    step.setArgument("slab_under_width", 0)
    step.setArgument("carpet_fraction", 0.0)
    step.setArgument("carpet_r_value", 0.0)
    step.setArgument("attic_type", "attic - unvented")
    step.setArgument("attic_floor_conditioned_r", 39.3)
    step.setArgument("attic_floor_unconditioned_r", 2.1)
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
    step.setArgument("wall_conditioned_r", 23)
    step.setArgument("wall_unconditioned_r", 4)
    step.setArgument("wall_solar_absorptance", 0.7)
    step.setArgument("wall_emittance", 0.92)
    step.setArgument("front_wwr", 0.18)
    step.setArgument("back_wwr", 0.18)
    step.setArgument("left_wwr", 0.18)
    step.setArgument("right_wwr", 0.18)
    step.setArgument("front_window_area", 0)
    step.setArgument("back_window_area", 0)
    step.setArgument("left_window_area", 0)
    step.setArgument("right_window_area", 0)
    step.setArgument("window_aspect_ratio", 1.333)
    step.setArgument("window_ufactor", 0.33)
    step.setArgument("window_shgc", 0.45)
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
    step.setArgument("overhangs_depth", 0.0)
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
    step.setArgument("shelter_coefficient", Constants.Auto)
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
    step.setArgument("return_duct_insulation_r_value", 0.0)
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
    step.setArgument("solar_thermal_storage_volume", Constants.Auto)
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
    step.setArgument("clothes_washer_location", Constants.Auto)
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
    step.setArgument("refrigerator_location", Constants.Auto)
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
    step.setArgument("ceiling_fan_cooling_setpoint_temp_offset", 0)
    step.setArgument("plug_loads_plug_load_type_1", "other")
    step.setArgument("plug_loads_annual_kwh_1", 0)
    step.setArgument("plug_loads_frac_sensible_1", 0)
    step.setArgument("plug_loads_frac_latent_1", 0)
    step.setArgument("plug_loads_plug_load_type_2", "TV other")
    step.setArgument("plug_loads_annual_kwh_2", 0)
    step.setArgument("plug_loads_frac_sensible_2", 0)
    step.setArgument("plug_loads_frac_latent_2", 0)
    step.setArgument("plug_loads_schedule_values", false)
    step.setArgument("plug_loads_weekday_fractions", "0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036")
    step.setArgument("plug_loads_weekend_fractions", "0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036")
    step.setArgument("plug_loads_monthly_multipliers", "1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248")
  elsif ['base-single-family-attached.osw'].include? osw_file
    step.setArgument("unit_type", "single-family attached")
    step.setArgument("cfa", 900.0)
  elsif ['base-multifamily.osw'].include? osw_file
    step.setArgument("unit_type", "multifamily")
    step.setArgument("cfa", 900.0)
    step.setArgument("supply_duct_leakage_value", 0)
    step.setArgument("return_duct_leakage_value", 0)
    step.setArgument("supply_duct_location", Constants.Auto)
    step.setArgument("return_duct_location", Constants.Auto)
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
    step.setArgument("supply_duct_location", Constants.Auto)
    step.setArgument("return_duct_location", Constants.Auto)
  elsif ['base-atticroof-conditioned.osw'].include? osw_file
    step.setArgument("cfa", 3600.0)
    step.setArgument("num_floors", 2)
    step.setArgument("attic_type", "attic - conditioned")
    step.setArgument("roof_ceiling_r", 25.8)
    step.setArgument("supply_duct_location", Constants.Auto)
    step.setArgument("return_duct_location", Constants.Auto)
  elsif ['base-atticroof-flat.osw'].include? osw_file
    step.setArgument("roof_type", "flat")
    step.setArgument("roof_ceiling_r", 25.8)
    step.setArgument("supply_duct_location", Constants.Auto)
    step.setArgument("return_duct_location", Constants.Auto)
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
    step.setArgument("water_heater_tank_volume_1", 80.0)
    step.setArgument("water_heater_energy_factor_1", 2.3)
  elsif ['base-dhw-tank-heat-pump-outside.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "heat pump water heater")
    step.setArgument("water_heater_location_1", "other exterior")
    step.setArgument("water_heater_tank_volume_1", 80.0)
    step.setArgument("water_heater_energy_factor_1", 2.3)
  elsif ['base-dhw-tank-heat-pump-with-solar.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "heat pump water heater")
    step.setArgument("water_heater_tank_volume_1", 80.0)
    step.setArgument("water_heater_energy_factor_1", 2.3)
    step.setArgument("solar_thermal_system_type", "hot water")
    step.setArgument("solar_thermal_collector_loop_type", "liquid indirect")
    step.setArgument("solar_thermal_collector_rated_optical_efficiency", 0.77)
    step.setArgument("solar_thermal_collector_rated_thermal_losses", 0.793)
  elsif ['base-dhw-tank-heat-pump-with-solar-fraction.osw'].include? osw_file
    step.setArgument("water_heater_type_1", "heat pump water heater")
    step.setArgument("water_heater_tank_volume_1", 80.0)
    step.setArgument("water_heater_energy_factor_1", 2.3)
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
    step.setArgument("unit_type", "multifamily")
    step.setArgument("cfa", 1350.0)
    step.setArgument("level", "Middle")
    step.setArgument("horizontal_location", "Middle")
    step.setArgument("supply_duct_leakage_value", 0)
    step.setArgument("return_duct_leakage_value", 0)
    step.setArgument("supply_duct_location", Constants.Auto)
    step.setArgument("return_duct_location", Constants.Auto)
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
    step.setArgument("overhangs_depth", 2.0)
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
    step.setArgument("foundation_ceiling_r", 18.7)
  elsif ['base-foundation-complex.osw'].include? osw_file

  elsif ['base-foundation-conditioned-basement-slab-insulation.osw'].include? osw_file
    step.setArgument("slab_under_r", 10)
    step.setArgument("slab_under_width", 4)
  elsif ['base-foundation-conditioned-basement-wall-interior-insulation.osw'].include? osw_file
    step.setArgument("foundation_wall_r", 18.9)
  elsif ['base-foundation-multiple.osw'].include? osw_file

  elsif ['base-foundation-slab.osw'].include? osw_file
    step.setArgument("foundation_type", "slab")
    step.setArgument("foundation_wall_depth_below_grade", 0.0)
    step.setArgument("slab_under_r", 5)
    step.setArgument("slab_under_width", 999)
    step.setArgument("carpet_fraction", 1.0)
    step.setArgument("carpet_r_value", 2.5)
  elsif ['base-foundation-unconditioned-basement.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
    step.setArgument("foundation_wall_r", 0)
    step.setArgument("foundation_wall_distance_to_bottom", 0)
  elsif ['base-foundation-unconditioned-basement-above-grade.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
    step.setArgument("foundation_wall_r", 0)
    step.setArgument("foundation_wall_distance_to_bottom", 0)
    step.setArgument("foundation_wall_depth_below_grade", 4)
  elsif ['base-foundation-unconditioned-basement-assembly-r.osw'].include? osw_file

  elsif ['base-foundation-unconditioned-basement-wall-insulation.osw'].include? osw_file
    step.setArgument("foundation_type", "basement - unconditioned")
    step.setArgument("foundation_ceiling_r", 2.1)
    step.setArgument("foundation_wall_distance_to_bottom", 4)
  elsif ['base-foundation-unvented-crawlspace.osw'].include? osw_file
    step.setArgument("foundation_type", "crawlspace - unvented")
    step.setArgument("foundation_height", 3.0)
    step.setArgument("foundation_ceiling_r", 18.7)
    step.setArgument("foundation_wall_distance_to_bottom", 4.0)
    step.setArgument("foundation_wall_depth_below_grade", 3.0)
    step.setArgument("carpet_r_value", 2.5)
  elsif ['base-foundation-vented-crawlspace.osw'].include? osw_file
    step.setArgument("foundation_type", "crawlspace - vented")
    step.setArgument("foundation_height", 3.0)
    step.setArgument("foundation_ceiling_r", 18.7)
    step.setArgument("foundation_wall_distance_to_bottom", 4.0)
    step.setArgument("foundation_wall_depth_below_grade", 3.0)
    step.setArgument("carpet_r_value", 2.5)
  elsif ['base-foundation-walkout-basement.osw'].include? osw_file
    step.setArgument("foundation_wall_distance_to_bottom", 4.0)
    step.setArgument("foundation_wall_depth_below_grade", 3.0)
  elsif ['base-hvac-air-to-air-heat-pump-1-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 7.7)
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("heat_pump_backup_fuel", "electricity")
  elsif ['base-hvac-air-to-air-heat-pump-1-speed.detailed.osw'].include? osw_file

  elsif ['base-hvac-air-to-air-heat-pump-2-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 9.3)
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("cooling_system_cooling_efficiency", 18.0)
    step.setArgument("heat_pump_backup_fuel", "electricity")
  elsif ['base-hvac-air-to-air-heat-pump-2-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-air-to-air-heat-pump-var-speed.osw'].include? osw_file
    step.setArgument("heating_system_type", "air-to-air")
    step.setArgument("heating_system_fuel", "electricity")
    step.setArgument("heating_system_heating_efficiency", 10.0)
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("cooling_system_type", "air-to-air")
    step.setArgument("cooling_system_cooling_efficiency", 22.0)
    step.setArgument("heat_pump_backup_fuel", "electricity")
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
    step.setArgument("heating_system_heating_capacity", 42000.0)
    step.setArgument("heat_pump_backup_fuel", "electricity")
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
    step.setArgument("supply_duct_location", Constants.Auto)
    step.setArgument("return_duct_location", Constants.Auto)
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
    step.setArgument("weather_station_epw_filename", "USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw")
  elsif ['base-location-dallas-tx.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw")
  elsif ['base-location-duluth-mn.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "USA_MN_Duluth.Intl.AP.727450_TMY3.epw")
  elsif ['base-location-epw-filename.osw'].include? osw_file

  elsif ['base-location-miami-fl.osw'].include? osw_file
    step.setArgument("weather_station_epw_filename", "USA_FL_Miami.Intl.AP.722020_TMY3.epw")
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
    step.setArgument("ceiling_fan_cooling_setpoint_temp_offset", 0.5)
  elsif ['base-misc-lighting-none.osw'].include? osw_file
    step.setArgument("has_lighting", false)
  elsif ['base-misc-loads-detailed.osw'].include? osw_file
    step.setArgument("plug_loads_schedule_values", true)
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
  elsif ['base-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-air-to-air-heat-pump-1-speed-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-air-to-air-heat-pump-2-speed-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-air-to-air-heat-pump-var-speed-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-boiler-gas-only-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
  elsif ['base-hvac-central-ac-only-1-speed-33percent.osw'].include? osw_file
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-central-ac-only-2-speed-33percent.osw'].include? osw_file
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-central-ac-only-var-speed-33percent.osw'].include? osw_file
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-elec-resistance-only-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
  elsif ['base-hvac-evap-cooler-only-33percent.osw'].include? osw_file
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-furnace-gas-central-ac-2-speed-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-furnace-gas-central-ac-var-speed-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-furnace-gas-only-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
  elsif ['base-hvac-furnace-gas-room-ac-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-ground-to-air-heat-pump-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-mini-split-heat-pump-ducted-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-room-ac-only-33percent.osw'].include? osw_file
    step.setArgument("cooling_system_fraction_cool_load_served", 0.33333)
  elsif ['base-hvac-stove-oil-only-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
  elsif ['base-hvac-wall-furnace-propane-only-33percent.osw'].include? osw_file
    step.setArgument("heating_system_fraction_heat_load_served", 0.33333)
  end
  return step
end

def create_hpxmls
  this_dir = File.dirname(__FILE__)
  tests_dir = File.join(this_dir, "HPXMLtoOpenStudio/tests")

  # Hash of HPXML -> Parent HPXML
  hpxmls_files = {
    'base.xml' => nil,

    'invalid_files/bad-wmo.xml' => 'base.xml',
    'invalid_files/bad-site-neighbor-azimuth.xml' => 'base-site-neighbors.xml',
    'invalid_files/cfis-with-hydronic-distribution.xml' => 'base-hvac-boiler-gas-only.xml',
    'invalid_files/clothes-washer-location.xml' => 'base.xml',
    'invalid_files/clothes-washer-location-other.xml' => 'base.xml',
    'invalid_files/clothes-dryer-location.xml' => 'base.xml',
    'invalid_files/clothes-dryer-location-other.xml' => 'base.xml',
    'invalid_files/dhw-frac-load-served.xml' => 'base-dhw-multiple.xml',
    'invalid_files/duct-location.xml' => 'base.xml',
    'invalid_files/duct-location-other.xml' => 'base.xml',
    'invalid_files/heat-pump-mixed-fixed-and-autosize-capacities.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'invalid_files/heat-pump-mixed-fixed-and-autosize-capacities2.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'invalid_files/heat-pump-mixed-fixed-and-autosize-capacities3.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'invalid_files/heat-pump-mixed-fixed-and-autosize-capacities4.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'invalid_files/hvac-invalid-distribution-system-type.xml' => 'base.xml',
    'invalid_files/hvac-distribution-multiple-attached-cooling.xml' => 'base-hvac-multiple.xml',
    'invalid_files/hvac-distribution-multiple-attached-heating.xml' => 'base-hvac-multiple.xml',
    'invalid_files/hvac-distribution-return-duct-leakage-missing.xml' => 'base-hvac-evap-cooler-only-ducted.xml',
    'invalid_files/hvac-dse-multiple-attached-cooling.xml' => 'base-hvac-dse.xml',
    'invalid_files/hvac-dse-multiple-attached-heating.xml' => 'base-hvac-dse.xml',
    'invalid_files/hvac-frac-load-served.xml' => 'base-hvac-multiple.xml',
    'invalid_files/invalid-relatedhvac-dhw-indirect.xml' => 'base-dhw-indirect.xml',
    'invalid_files/invalid-relatedhvac-desuperheater.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'invalid_files/invalid-window-interior-shading.xml' => 'base.xml',
    'invalid_files/missing-elements.xml' => 'base.xml',
    'invalid_files/missing-surfaces.xml' => 'base.xml',
    'invalid_files/net-area-negative-roof.xml' => 'base-enclosure-skylights.xml',
    'invalid_files/net-area-negative-wall.xml' => 'base.xml',
    'invalid_files/refrigerator-location.xml' => 'base.xml',
    'invalid_files/refrigerator-location-other.xml' => 'base.xml',
    'invalid_files/repeated-relatedhvac-dhw-indirect.xml' => 'base-dhw-indirect.xml',
    'invalid_files/repeated-relatedhvac-desuperheater.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'invalid_files/solar-thermal-system-with-combi-tankless.xml' => 'base-dhw-combi-tankless.xml',
    'invalid_files/solar-thermal-system-with-desuperheater.xml' => 'base-dhw-desuperheater.xml',
    'invalid_files/solar-thermal-system-with-dhw-indirect.xml' => 'base-dhw-combi-tankless.xml',
    'invalid_files/unattached-cfis.xml' => 'base.xml',
    'invalid_files/unattached-door.xml' => 'base.xml',
    'invalid_files/unattached-hvac-distribution.xml' => 'base.xml',
    'invalid_files/orphaned-hvac-distribution.xml' => 'base-hvac-furnace-gas-room-ac.xml',
    'invalid_files/unattached-skylight.xml' => 'base-enclosure-skylights.xml',
    'invalid_files/unattached-solar-thermal-system.xml' => 'base-dhw-solar-indirect-flat-plate.xml',
    'invalid_files/unattached-window.xml' => 'base.xml',
    'invalid_files/water-heater-location.xml' => 'base.xml',
    'invalid_files/water-heater-location-other.xml' => 'base.xml',

    'base-appliances-dishwasher-ef.xml' => 'base.xml',
    'base-appliances-dryer-cef.xml' => 'base.xml',
    'base-appliances-gas.xml' => 'base.xml',
    'base-appliances-wood.xml' => 'base.xml',
    'base-appliances-none.xml' => 'base.xml',
    'base-appliances-oil.xml' => 'base.xml',
    'base-appliances-propane.xml' => 'base.xml',
    'base-appliances-refrigerator-adjusted.xml' => 'base.xml',
    'base-appliances-washer-imef.xml' => 'base.xml',
    'base-atticroof-cathedral.xml' => 'base.xml',
    'base-atticroof-conditioned.xml' => 'base.xml',
    'base-atticroof-flat.xml' => 'base.xml',
    'base-atticroof-radiant-barrier.xml' => 'base-location-dallas-tx.xml',
    'base-atticroof-vented.xml' => 'base.xml',
    'base-atticroof-unvented-insulated-roof.xml' => 'base.xml',
    'base-dhw-combi-tankless.xml' => 'base-dhw-indirect.xml',
    'base-dhw-combi-tankless-outside.xml' => 'base-dhw-combi-tankless.xml',
    'base-dhw-desuperheater.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'base-dhw-desuperheater-tankless.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'base-dhw-desuperheater-2-speed.xml' => 'base-hvac-central-ac-only-2-speed.xml',
    'base-dhw-desuperheater-var-speed.xml' => 'base-hvac-central-ac-only-var-speed.xml',
    'base-dhw-desuperheater-gshp.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'base-dhw-dwhr.xml' => 'base.xml',
    'base-dhw-indirect.xml' => 'base-hvac-boiler-gas-only.xml',
    'base-dhw-indirect-dse.xml' => 'base-dhw-indirect.xml',
    'base-dhw-indirect-outside.xml' => 'base-dhw-indirect.xml',
    'base-dhw-indirect-standbyloss.xml' => 'base-dhw-indirect.xml',
    'base-dhw-low-flow-fixtures.xml' => 'base.xml',
    'base-dhw-multiple.xml' => 'base-hvac-boiler-gas-only.xml',
    'base-dhw-none.xml' => 'base.xml',
    'base-dhw-recirc-demand.xml' => 'base.xml',
    'base-dhw-recirc-manual.xml' => 'base.xml',
    'base-dhw-recirc-nocontrol.xml' => 'base.xml',
    'base-dhw-recirc-temperature.xml' => 'base.xml',
    'base-dhw-recirc-timer.xml' => 'base.xml',
    'base-dhw-solar-direct-evacuated-tube.xml' => 'base.xml',
    'base-dhw-solar-direct-flat-plate.xml' => 'base.xml',
    'base-dhw-solar-direct-ics.xml' => 'base.xml',
    'base-dhw-solar-fraction.xml' => 'base.xml',
    'base-dhw-solar-indirect-evacuated-tube.xml' => 'base.xml',
    'base-dhw-solar-indirect-flat-plate.xml' => 'base.xml',
    'base-dhw-solar-thermosyphon-evacuated-tube.xml' => 'base.xml',
    'base-dhw-solar-thermosyphon-flat-plate.xml' => 'base.xml',
    'base-dhw-solar-thermosyphon-ics.xml' => 'base.xml',
    'base-dhw-tank-gas.xml' => 'base.xml',
    'base-dhw-tank-gas-outside.xml' => 'base-dhw-tank-gas.xml',
    'base-dhw-tank-heat-pump.xml' => 'base.xml',
    'base-dhw-tank-heat-pump-outside.xml' => 'base-dhw-tank-heat-pump.xml',
    'base-dhw-tank-heat-pump-with-solar.xml' => 'base-dhw-tank-heat-pump.xml',
    'base-dhw-tank-heat-pump-with-solar-fraction.xml' => 'base-dhw-tank-heat-pump.xml',
    'base-dhw-tank-oil.xml' => 'base.xml',
    'base-dhw-tank-propane.xml' => 'base.xml',
    'base-dhw-tank-wood.xml' => 'base.xml',
    'base-dhw-tankless-electric.xml' => 'base.xml',
    'base-dhw-tankless-electric-outside.xml' => 'base-dhw-tankless-electric.xml',
    'base-dhw-tankless-gas.xml' => 'base.xml',
    'base-dhw-tankless-gas-with-solar.xml' => 'base-dhw-tankless-gas.xml',
    'base-dhw-tankless-gas-with-solar-fraction.xml' => 'base-dhw-tankless-gas.xml',
    'base-dhw-tankless-oil.xml' => 'base.xml',
    'base-dhw-tankless-propane.xml' => 'base.xml',
    'base-dhw-tankless-wood.xml' => 'base.xml',
    'base-dhw-uef.xml' => 'base.xml',
    'base-dhw-jacket-electric.xml' => 'base.xml',
    'base-dhw-jacket-gas.xml' => 'base-dhw-tank-gas.xml',
    'base-dhw-jacket-indirect.xml' => 'base-dhw-indirect.xml',
    'base-dhw-jacket-hpwh.xml' => 'base-dhw-tank-heat-pump.xml',
    'base-enclosure-2stories.xml' => 'base.xml',
    'base-enclosure-2stories-garage.xml' => 'base-enclosure-2stories.xml',
    'base-enclosure-adiabatic-surfaces.xml' => 'base-foundation-ambient.xml',
    'base-enclosure-beds-1.xml' => 'base.xml',
    'base-enclosure-beds-2.xml' => 'base.xml',
    'base-enclosure-beds-4.xml' => 'base.xml',
    'base-enclosure-beds-5.xml' => 'base.xml',
    'base-enclosure-garage.xml' => 'base.xml',
    'base-enclosure-infil-cfm50.xml' => 'base.xml',
    'base-enclosure-no-natural-ventilation.xml' => 'base.xml',
    'base-enclosure-overhangs.xml' => 'base.xml',
    'base-enclosure-skylights.xml' => 'base.xml',
    'base-enclosure-split-surfaces.xml' => 'base-enclosure-skylights.xml',
    'base-enclosure-walltype-cmu.xml' => 'base.xml',
    'base-enclosure-walltype-doublestud.xml' => 'base.xml',
    'base-enclosure-walltype-icf.xml' => 'base.xml',
    'base-enclosure-walltype-log.xml' => 'base.xml',
    'base-enclosure-walltype-sip.xml' => 'base.xml',
    'base-enclosure-walltype-solidconcrete.xml' => 'base.xml',
    'base-enclosure-walltype-steelstud.xml' => 'base.xml',
    'base-enclosure-walltype-stone.xml' => 'base.xml',
    'base-enclosure-walltype-strawbale.xml' => 'base.xml',
    'base-enclosure-walltype-structuralbrick.xml' => 'base.xml',
    'base-enclosure-windows-interior-shading.xml' => 'base.xml',
    'base-enclosure-windows-none.xml' => 'base.xml',
    'base-foundation-multiple.xml' => 'base-foundation-unconditioned-basement.xml',
    'base-foundation-ambient.xml' => 'base.xml',
    'base-foundation-conditioned-basement-slab-insulation.xml' => 'base.xml',
    'base-foundation-conditioned-basement-wall-interior-insulation.xml' => 'base.xml',
    'base-foundation-slab.xml' => 'base.xml',
    'base-foundation-unconditioned-basement.xml' => 'base.xml',
    'base-foundation-unconditioned-basement-assembly-r.xml' => 'base-foundation-unconditioned-basement.xml',
    'base-foundation-unconditioned-basement-above-grade.xml' => 'base-foundation-unconditioned-basement.xml',
    'base-foundation-unconditioned-basement-wall-insulation.xml' => 'base-foundation-unconditioned-basement.xml',
    'base-foundation-unvented-crawlspace.xml' => 'base.xml',
    'base-foundation-vented-crawlspace.xml' => 'base.xml',
    'base-foundation-walkout-basement.xml' => 'base.xml',
    'base-foundation-complex.xml' => 'base.xml',
    'base-hvac-air-to-air-heat-pump-1-speed.xml' => 'base.xml',
    'base-hvac-air-to-air-heat-pump-1-speed-detailed.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-air-to-air-heat-pump-2-speed.xml' => 'base.xml',
    'base-hvac-air-to-air-heat-pump-2-speed-detailed.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'base-hvac-air-to-air-heat-pump-var-speed.xml' => 'base.xml',
    'base-hvac-air-to-air-heat-pump-var-speed-detailed.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'base-hvac-boiler-elec-only.xml' => 'base.xml',
    'base-hvac-boiler-gas-central-ac-1-speed.xml' => 'base.xml',
    'base-hvac-boiler-gas-only.xml' => 'base.xml',
    'base-hvac-boiler-gas-only-no-eae.xml' => 'base-hvac-boiler-gas-only.xml',
    'base-hvac-boiler-oil-only.xml' => 'base.xml',
    'base-hvac-boiler-propane-only.xml' => 'base.xml',
    'base-hvac-boiler-wood-only.xml' => 'base.xml',
    'base-hvac-central-ac-only-1-speed.xml' => 'base.xml',
    'base-hvac-central-ac-only-1-speed-detailed.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'base-hvac-central-ac-only-2-speed.xml' => 'base.xml',
    'base-hvac-central-ac-only-2-speed-detailed.xml' => 'base-hvac-central-ac-only-2-speed.xml',
    'base-hvac-central-ac-only-var-speed.xml' => 'base.xml',
    'base-hvac-central-ac-only-var-speed-detailed.xml' => 'base-hvac-central-ac-only-var-speed.xml',
    'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'base-hvac-dse.xml' => 'base.xml',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-oil.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-propane.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'base-hvac-ducts-in-conditioned-space.xml' => 'base.xml',
    'base-hvac-ducts-leakage-percent.xml' => 'base.xml',
    'base-hvac-ducts-locations.xml' => 'base-foundation-vented-crawlspace.xml',
    'base-hvac-ducts-multiple.xml' => 'base.xml',
    'base-hvac-ducts-outside.xml' => 'base.xml',
    'base-hvac-elec-resistance-only.xml' => 'base.xml',
    'base-hvac-evap-cooler-furnace-gas.xml' => 'base.xml',
    'base-hvac-evap-cooler-only.xml' => 'base.xml',
    'base-hvac-evap-cooler-only-ducted.xml' => 'base.xml',
    'base-hvac-flowrate.xml' => 'base.xml',
    'base-hvac-furnace-elec-only.xml' => 'base.xml',
    'base-hvac-furnace-gas-central-ac-2-speed.xml' => 'base.xml',
    'base-hvac-furnace-gas-central-ac-var-speed.xml' => 'base.xml',
    'base-hvac-furnace-gas-only.xml' => 'base.xml',
    'base-hvac-furnace-gas-only-no-eae.xml' => 'base-hvac-furnace-gas-only.xml',
    'base-hvac-furnace-gas-room-ac.xml' => 'base.xml',
    'base-hvac-furnace-oil-only.xml' => 'base.xml',
    'base-hvac-furnace-propane-only.xml' => 'base.xml',
    'base-hvac-furnace-wood-only.xml' => 'base.xml',
    'base-hvac-furnace-x3-dse.xml' => 'base.xml',
    'base-hvac-ground-to-air-heat-pump.xml' => 'base.xml',
    'base-hvac-ground-to-air-heat-pump-detailed.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'base-hvac-ideal-air.xml' => 'base.xml',
    'base-hvac-mini-split-heat-pump-ducted.xml' => 'base.xml',
    'base-hvac-mini-split-heat-pump-ducted-detailed.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'base-hvac-mini-split-heat-pump-ductless.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'base-hvac-mini-split-heat-pump-ductless-no-backup.xml' => 'base-hvac-mini-split-heat-pump-ductless.xml',
    'base-hvac-multiple.xml' => 'base.xml',
    'base-hvac-none.xml' => 'base.xml',
    'base-hvac-none-no-fuel-access.xml' => 'base-hvac-none.xml',
    'base-hvac-portable-heater-electric-only.xml' => 'base.xml',
    'base-hvac-programmable-thermostat.xml' => 'base.xml',
    'base-hvac-room-ac-only.xml' => 'base.xml',
    'base-hvac-room-ac-only-detailed.xml' => 'base-hvac-room-ac-only.xml',
    'base-hvac-setpoints.xml' => 'base.xml',
    'base-hvac-stove-oil-only.xml' => 'base.xml',
    'base-hvac-stove-oil-only-no-eae.xml' => 'base-hvac-stove-oil-only.xml',
    'base-hvac-stove-wood-only.xml' => 'base.xml',
    'base-hvac-undersized.xml' => 'base.xml',
    'base-hvac-wall-furnace-elec-only.xml' => 'base.xml',
    'base-hvac-wall-furnace-propane-only.xml' => 'base.xml',
    'base-hvac-wall-furnace-propane-only-no-eae.xml' => 'base-hvac-wall-furnace-propane-only.xml',
    'base-hvac-wall-furnace-wood-only.xml' => 'base.xml',
    'base-infiltration-ach-natural.xml' => 'base.xml',
    'base-location-baltimore-md.xml' => 'base.xml',
    'base-location-dallas-tx.xml' => 'base.xml',
    'base-location-duluth-mn.xml' => 'base.xml',
    'base-location-miami-fl.xml' => 'base.xml',
    'base-location-epw-filename.xml' => 'base.xml',
    'base-mechvent-balanced.xml' => 'base.xml',
    'base-mechvent-cfis.xml' => 'base.xml',
    'base-mechvent-cfis-24hrs.xml' => 'base-mechvent-cfis.xml',
    'base-mechvent-erv.xml' => 'base.xml',
    'base-mechvent-erv-atre-asre.xml' => 'base.xml',
    'base-mechvent-exhaust.xml' => 'base.xml',
    'base-mechvent-exhaust-rated-flow-rate.xml' => 'base.xml',
    'base-mechvent-hrv.xml' => 'base.xml',
    'base-mechvent-hrv-asre.xml' => 'base.xml',
    'base-mechvent-supply.xml' => 'base.xml',
    'base-misc-ceiling-fans.xml' => 'base.xml',
    'base-misc-lighting-none.xml' => 'base.xml',
    'base-misc-loads-detailed.xml' => 'base.xml',
    'base-misc-number-of-occupants.xml' => 'base.xml',
    'base-misc-whole-house-fan.xml' => 'base.xml',
    'base-pv.xml' => 'base.xml',
    'base-site-neighbors.xml' => 'base.xml',
    'base-version-2014.xml' => 'base.xml',
    'base-version-2014A.xml' => 'base.xml',
    'base-version-2014AE.xml' => 'base.xml',
    'base-version-2014AEG.xml' => 'base.xml',
    'base-version-latest.xml' => 'base.xml',

    'cfis/base-cfis.xml' => 'base.xml',
    'cfis/base-hvac-air-to-air-heat-pump-1-speed-cfis.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'cfis/base-hvac-air-to-air-heat-pump-2-speed-cfis.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'cfis/base-hvac-air-to-air-heat-pump-var-speed-cfis.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'cfis/base-hvac-boiler-gas-central-ac-1-speed-cfis.xml' => 'base-hvac-boiler-gas-central-ac-1-speed.xml',
    'cfis/base-hvac-central-ac-only-1-speed-cfis.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'cfis/base-hvac-central-ac-only-2-speed-cfis.xml' => 'base-hvac-central-ac-only-2-speed.xml',
    'cfis/base-hvac-central-ac-only-var-speed-cfis.xml' => 'base-hvac-central-ac-only-var-speed.xml',
    'cfis/base-hvac-dse-cfis.xml' => 'base-hvac-dse.xml',
    'cfis/base-hvac-ducts-in-conditioned-space-cfis.xml' => 'base-hvac-ducts-in-conditioned-space.xml',
    'cfis/base-hvac-evap-cooler-only-ducted-cfis.xml' => 'base-hvac-evap-cooler-only-ducted.xml',
    'cfis/base-hvac-furnace-gas-central-ac-2-speed-cfis.xml' => 'base-hvac-furnace-gas-central-ac-2-speed.xml',
    'cfis/base-hvac-furnace-gas-central-ac-var-speed-cfis.xml' => 'base-hvac-furnace-gas-central-ac-var-speed.xml',
    'cfis/base-hvac-furnace-gas-only-cfis.xml' => 'base-hvac-furnace-gas-only.xml',
    'cfis/base-hvac-furnace-gas-room-ac-cfis.xml' => 'base-hvac-furnace-gas-room-ac.xml',
    'cfis/base-hvac-ground-to-air-heat-pump-cfis.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'cfis/base-hvac-mini-split-heat-pump-ducted-cfis.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',

    'hvac_autosizing/base-autosize.xml' => 'base.xml',
    'hvac_autosizing/base-hvac-air-to-air-heat-pump-1-speed-autosize.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'hvac_autosizing/base-hvac-air-to-air-heat-pump-2-speed-autosize.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'hvac_autosizing/base-hvac-air-to-air-heat-pump-var-speed-autosize.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'hvac_autosizing/base-hvac-boiler-elec-only-autosize.xml' => 'base-hvac-boiler-elec-only.xml',
    'hvac_autosizing/base-hvac-boiler-gas-central-ac-1-speed-autosize.xml' => 'base-hvac-boiler-gas-central-ac-1-speed.xml',
    'hvac_autosizing/base-hvac-boiler-gas-only-autosize.xml' => 'base-hvac-boiler-gas-only.xml',
    'hvac_autosizing/base-hvac-central-ac-only-1-speed-autosize.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'hvac_autosizing/base-hvac-central-ac-only-2-speed-autosize.xml' => 'base-hvac-central-ac-only-2-speed.xml',
    'hvac_autosizing/base-hvac-central-ac-only-var-speed-autosize.xml' => 'base-hvac-central-ac-only-var-speed.xml',
    'hvac_autosizing/base-hvac-central-ac-plus-air-to-air-heat-pump-heating-autosize.xml' => 'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml',
    'hvac_autosizing/base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-autosize.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
    'hvac_autosizing/base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric-autosize.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml',
    'hvac_autosizing/base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-oil-autosize.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-oil.xml',
    'hvac_autosizing/base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-propane-autosize.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-propane.xml',
    'hvac_autosizing/base-hvac-dual-fuel-air-to-air-heat-pump-2-speed-autosize.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.xml',
    'hvac_autosizing/base-hvac-dual-fuel-air-to-air-heat-pump-var-speed-autosize.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.xml',
    'hvac_autosizing/base-hvac-dual-fuel-mini-split-heat-pump-ducted-autosize.xml' => 'base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml',
    'hvac_autosizing/base-hvac-elec-resistance-only-autosize.xml' => 'base-hvac-elec-resistance-only.xml',
    'hvac_autosizing/base-hvac-evap-cooler-furnace-gas-autosize.xml' => 'base-hvac-evap-cooler-furnace-gas.xml',
    'hvac_autosizing/base-hvac-furnace-elec-only-autosize.xml' => 'base-hvac-furnace-elec-only.xml',
    'hvac_autosizing/base-hvac-furnace-gas-central-ac-2-speed-autosize.xml' => 'base-hvac-furnace-gas-central-ac-2-speed.xml',
    'hvac_autosizing/base-hvac-furnace-gas-central-ac-var-speed-autosize.xml' => 'base-hvac-furnace-gas-central-ac-var-speed.xml',
    'hvac_autosizing/base-hvac-furnace-gas-only-autosize.xml' => 'base-hvac-furnace-gas-only.xml',
    'hvac_autosizing/base-hvac-furnace-gas-room-ac-autosize.xml' => 'base-hvac-furnace-gas-room-ac.xml',
    'hvac_autosizing/base-hvac-ground-to-air-heat-pump-autosize.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'hvac_autosizing/base-hvac-mini-split-heat-pump-ducted-autosize.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'hvac_autosizing/base-hvac-room-ac-only-autosize.xml' => 'base-hvac-room-ac-only.xml',
    'hvac_autosizing/base-hvac-stove-oil-only-autosize.xml' => 'base-hvac-stove-oil-only.xml',
    'hvac_autosizing/base-hvac-wall-furnace-elec-only-autosize.xml' => 'base-hvac-wall-furnace-elec-only.xml',
    'hvac_autosizing/base-hvac-wall-furnace-propane-only-autosize.xml' => 'base-hvac-wall-furnace-propane-only.xml',

    'hvac_base/base-base.xml' => 'base.xml',
    'hvac_base/base-hvac-air-to-air-heat-pump-1-speed-base.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'hvac_base/base-hvac-air-to-air-heat-pump-2-speed-base.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'hvac_base/base-hvac-air-to-air-heat-pump-var-speed-base.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'hvac_base/base-hvac-boiler-gas-only-base.xml' => 'base-hvac-boiler-gas-only.xml',
    'hvac_base/base-hvac-central-ac-only-1-speed-base.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'hvac_base/base-hvac-central-ac-only-2-speed-base.xml' => 'base-hvac-central-ac-only-2-speed.xml',
    'hvac_base/base-hvac-central-ac-only-var-speed-base.xml' => 'base-hvac-central-ac-only-var-speed.xml',
    'hvac_base/base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-base.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
    'hvac_base/base-hvac-elec-resistance-only-base.xml' => 'base-hvac-elec-resistance-only.xml',
    'hvac_base/base-hvac-evap-cooler-only-base.xml' => 'base-hvac-evap-cooler-only.xml',
    'hvac_base/base-hvac-furnace-gas-central-ac-2-speed-base.xml' => 'base-hvac-furnace-gas-central-ac-2-speed.xml',
    'hvac_base/base-hvac-furnace-gas-central-ac-var-speed-base.xml' => 'base-hvac-furnace-gas-central-ac-var-speed.xml',
    'hvac_base/base-hvac-furnace-gas-only-base.xml' => 'base-hvac-furnace-gas-only.xml',
    'hvac_base/base-hvac-furnace-gas-room-ac-base.xml' => 'base-hvac-furnace-gas-room-ac.xml',
    'hvac_base/base-hvac-ground-to-air-heat-pump-base.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'hvac_base/base-hvac-ideal-air-base.xml' => 'base-hvac-ideal-air.xml',
    'hvac_base/base-hvac-mini-split-heat-pump-ducted-base.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'hvac_base/base-hvac-room-ac-only-base.xml' => 'base-hvac-room-ac-only.xml',
    'hvac_base/base-hvac-stove-oil-only-base.xml' => 'base-hvac-stove-oil-only.xml',
    'hvac_base/base-hvac-wall-furnace-propane-only-base.xml' => 'base-hvac-wall-furnace-propane-only.xml',

    'hvac_load_fracs/base-hvac-air-to-air-heat-pump-1-speed-zero-cool.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'hvac_load_fracs/base-hvac-air-to-air-heat-pump-1-speed-zero-heat.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'hvac_load_fracs/base-hvac-air-to-air-heat-pump-2-speed-zero-cool.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'hvac_load_fracs/base-hvac-air-to-air-heat-pump-2-speed-zero-heat.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'hvac_load_fracs/base-hvac-air-to-air-heat-pump-var-speed-zero-cool.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'hvac_load_fracs/base-hvac-air-to-air-heat-pump-var-speed-zero-heat.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'hvac_load_fracs/base-hvac-ground-to-air-heat-pump-zero-cool.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'hvac_load_fracs/base-hvac-ground-to-air-heat-pump-zero-heat.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'hvac_load_fracs/base-hvac-mini-split-heat-pump-ducted-zero-cool.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'hvac_load_fracs/base-hvac-mini-split-heat-pump-ducted-zero-heat.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',

    'hvac_multiple/base-hvac-air-to-air-heat-pump-1-speed-x3.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'hvac_multiple/base-hvac-air-to-air-heat-pump-2-speed-x3.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'hvac_multiple/base-hvac-air-to-air-heat-pump-var-speed-x3.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'hvac_multiple/base-hvac-boiler-gas-only-x3.xml' => 'base-hvac-boiler-gas-only.xml',
    'hvac_multiple/base-hvac-central-ac-only-1-speed-x3.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'hvac_multiple/base-hvac-central-ac-only-2-speed-x3.xml' => 'base-hvac-central-ac-only-2-speed.xml',
    'hvac_multiple/base-hvac-central-ac-only-var-speed-x3.xml' => 'base-hvac-central-ac-only-var-speed.xml',
    'hvac_multiple/base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-x3.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
    'hvac_multiple/base-hvac-elec-resistance-only-x3.xml' => 'base-hvac-elec-resistance-only.xml',
    'hvac_multiple/base-hvac-evap-cooler-only-x3.xml' => 'base-hvac-evap-cooler-only.xml',
    'hvac_multiple/base-hvac-furnace-gas-only-x3.xml' => 'base-hvac-furnace-gas-only.xml',
    'hvac_multiple/base-hvac-ground-to-air-heat-pump-x3.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'hvac_multiple/base-hvac-mini-split-heat-pump-ducted-x3.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'hvac_multiple/base-hvac-room-ac-only-x3.xml' => 'base-hvac-room-ac-only.xml',
    'hvac_multiple/base-hvac-stove-oil-only-x3.xml' => 'base-hvac-stove-oil-only.xml',
    'hvac_multiple/base-hvac-wall-furnace-propane-only-x3.xml' => 'base-hvac-wall-furnace-propane-only.xml',

    'hvac_partial/base-33percent.xml' => 'base.xml',
    'hvac_partial/base-hvac-air-to-air-heat-pump-1-speed-33percent.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'hvac_partial/base-hvac-air-to-air-heat-pump-2-speed-33percent.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'hvac_partial/base-hvac-air-to-air-heat-pump-var-speed-33percent.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'hvac_partial/base-hvac-boiler-gas-only-33percent.xml' => 'base-hvac-boiler-gas-only.xml',
    'hvac_partial/base-hvac-central-ac-only-1-speed-33percent.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'hvac_partial/base-hvac-central-ac-only-2-speed-33percent.xml' => 'base-hvac-central-ac-only-2-speed.xml',
    'hvac_partial/base-hvac-central-ac-only-var-speed-33percent.xml' => 'base-hvac-central-ac-only-var-speed.xml',
    'hvac_partial/base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-33percent.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
    'hvac_partial/base-hvac-elec-resistance-only-33percent.xml' => 'base-hvac-elec-resistance-only.xml',
    'hvac_partial/base-hvac-evap-cooler-only-33percent.xml' => 'base-hvac-evap-cooler-only.xml',
    'hvac_partial/base-hvac-furnace-gas-central-ac-2-speed-33percent.xml' => 'base-hvac-furnace-gas-central-ac-2-speed.xml',
    'hvac_partial/base-hvac-furnace-gas-central-ac-var-speed-33percent.xml' => 'base-hvac-furnace-gas-central-ac-var-speed.xml',
    'hvac_partial/base-hvac-furnace-gas-only-33percent.xml' => 'base-hvac-furnace-gas-only.xml',
    'hvac_partial/base-hvac-furnace-gas-room-ac-33percent.xml' => 'base-hvac-furnace-gas-room-ac.xml',
    'hvac_partial/base-hvac-ground-to-air-heat-pump-33percent.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'hvac_partial/base-hvac-mini-split-heat-pump-ducted-33percent.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'hvac_partial/base-hvac-room-ac-only-33percent.xml' => 'base-hvac-room-ac-only.xml',
    'hvac_partial/base-hvac-stove-oil-only-33percent.xml' => 'base-hvac-stove-oil-only.xml',
    'hvac_partial/base-hvac-wall-furnace-propane-only-33percent.xml' => 'base-hvac-wall-furnace-propane-only.xml',

    'water_heating_multiple/base-dhw-tankless-electric-x3.xml' => 'base-dhw-tankless-electric.xml',
    'water_heating_multiple/base-dhw-tankless-gas-x3.xml' => 'base-dhw-tankless-gas.xml',
    'water_heating_multiple/base-dhw-tankless-oil-x3.xml' => 'base-dhw-tankless-oil.xml',
    'water_heating_multiple/base-dhw-tankless-propane-x3.xml' => 'base-dhw-tankless-propane.xml',
    'water_heating_multiple/base-dhw-combi-tankless-x3.xml' => 'hvac_multiple/base-hvac-boiler-gas-only-x3.xml'
  }

  puts "Generating #{hpxmls_files.size} HPXML files..."

  hpxmls_files.each do |derivative, parent|
    print "."

    begin
      hpxml_files = [derivative]
      unless parent.nil?
        hpxml_files.unshift(parent)
      end
      while not parent.nil?
        if hpxmls_files.keys.include? parent
          unless hpxmls_files[parent].nil?
            hpxml_files.unshift(hpxmls_files[parent])
          end
          parent = hpxmls_files[parent]
        end
      end

      hpxml_values = {}
      site_values = {}
      site_neighbors_values = []
      building_occupancy_values = {}
      building_construction_values = {}
      climate_and_risk_zones_values = {}
      air_infiltration_measurement_values = {}
      attic_values = {}
      foundation_values = {}
      roofs_values = []
      rim_joists_values = []
      walls_values = []
      foundation_walls_values = []
      framefloors_values = []
      slabs_values = []
      windows_values = []
      skylights_values = []
      doors_values = []
      heating_systems_values = []
      cooling_systems_values = []
      heat_pumps_values = []
      hvac_control_values = {}
      hvac_distributions_values = []
      duct_leakage_measurements_values = []
      ducts_values = []
      ventilation_fans_values = []
      water_heating_systems_values = []
      hot_water_distribution_values = {}
      water_fixtures_values = []
      solar_thermal_system_values = {}
      pv_systems_values = []
      clothes_washer_values = {}
      clothes_dryer_values = {}
      dishwasher_values = {}
      refrigerator_values = {}
      cooking_range_values = {}
      oven_values = {}
      lighting_values = {}
      ceiling_fans_values = []
      plug_loads_values = []
      misc_load_schedule_values = {}
      hpxml_files.each do |hpxml_file|
        hpxml_values = get_hpxml_file_hpxml_values(hpxml_file, hpxml_values)
        site_values = get_hpxml_file_site_values(hpxml_file, site_values)
        site_neighbors_values = get_hpxml_file_site_neighbor_values(hpxml_file, site_neighbors_values)
        building_occupancy_values = get_hpxml_file_building_occupancy_values(hpxml_file, building_occupancy_values)
        building_construction_values = get_hpxml_file_building_construction_values(hpxml_file, building_construction_values)
        climate_and_risk_zones_values = get_hpxml_file_climate_and_risk_zones_values(hpxml_file, climate_and_risk_zones_values)
        attic_values = get_hpxml_file_attic_values(hpxml_file, attic_values)
        foundation_values = get_hpxml_file_foundation_values(hpxml_file, foundation_values)
        air_infiltration_measurement_values = get_hpxml_file_air_infiltration_measurement_values(hpxml_file, air_infiltration_measurement_values, building_construction_values)
        roofs_values = get_hpxml_file_roofs_values(hpxml_file, roofs_values)
        rim_joists_values = get_hpxml_file_rim_joists_values(hpxml_file, rim_joists_values)
        walls_values = get_hpxml_file_walls_values(hpxml_file, walls_values)
        foundation_walls_values = get_hpxml_file_foundation_walls_values(hpxml_file, foundation_walls_values)
        framefloors_values = get_hpxml_file_framefloors_values(hpxml_file, framefloors_values)
        slabs_values = get_hpxml_file_slabs_values(hpxml_file, slabs_values)
        windows_values = get_hpxml_file_windows_values(hpxml_file, windows_values)
        skylights_values = get_hpxml_file_skylights_values(hpxml_file, skylights_values)
        doors_values = get_hpxml_file_doors_values(hpxml_file, doors_values)
        heating_systems_values = get_hpxml_file_heating_systems_values(hpxml_file, heating_systems_values)
        cooling_systems_values = get_hpxml_file_cooling_systems_values(hpxml_file, cooling_systems_values)
        heat_pumps_values = get_hpxml_file_heat_pumps_values(hpxml_file, heat_pumps_values)
        hvac_control_values = get_hpxml_file_hvac_control_values(hpxml_file, hvac_control_values)
        hvac_distributions_values = get_hpxml_file_hvac_distributions_values(hpxml_file, hvac_distributions_values)
        duct_leakage_measurements_values = get_hpxml_file_duct_leakage_measurements_values(hpxml_file, duct_leakage_measurements_values)
        ducts_values = get_hpxml_file_ducts_values(hpxml_file, ducts_values)
        ventilation_fans_values = get_hpxml_file_ventilation_fan_values(hpxml_file, ventilation_fans_values)
        water_heating_systems_values = get_hpxml_file_water_heating_system_values(hpxml_file, water_heating_systems_values)
        hot_water_distribution_values = get_hpxml_file_hot_water_distribution_values(hpxml_file, hot_water_distribution_values)
        water_fixtures_values = get_hpxml_file_water_fixtures_values(hpxml_file, water_fixtures_values)
        solar_thermal_system_values = get_hpxml_file_solar_thermal_system_values(hpxml_file, solar_thermal_system_values)
        pv_systems_values = get_hpxml_file_pv_system_values(hpxml_file, pv_systems_values)
        clothes_washer_values = get_hpxml_file_clothes_washer_values(hpxml_file, clothes_washer_values)
        clothes_dryer_values = get_hpxml_file_clothes_dryer_values(hpxml_file, clothes_dryer_values)
        dishwasher_values = get_hpxml_file_dishwasher_values(hpxml_file, dishwasher_values)
        refrigerator_values = get_hpxml_file_refrigerator_values(hpxml_file, refrigerator_values)
        cooking_range_values = get_hpxml_file_cooking_range_values(hpxml_file, cooking_range_values)
        oven_values = get_hpxml_file_oven_values(hpxml_file, oven_values)
        lighting_values = get_hpxml_file_lighting_values(hpxml_file, lighting_values)
        ceiling_fans_values = get_hpxml_file_ceiling_fan_values(hpxml_file, ceiling_fans_values)
        plug_loads_values = get_hpxml_file_plug_loads_values(hpxml_file, plug_loads_values)
        misc_load_schedule_values = get_hpxml_file_misc_load_schedule_values(hpxml_file, misc_load_schedule_values)
      end

      hpxml_doc = HPXML.create_hpxml(**hpxml_values)
      hpxml = hpxml_doc.elements["HPXML"]
      hpxml.elements["XMLTransactionHeaderInformation/CreatedDateAndTime"].text = Time.new(2000, 1, 1).strftime("%Y-%m-%dT%H:%M:%S%:z") # Hard-code to prevent diffs
      HPXML.add_site(hpxml: hpxml, **site_values) unless site_values.nil?
      site_neighbors_values.each do |site_neighbor_values|
        HPXML.add_site_neighbor(hpxml: hpxml, **site_neighbor_values)
      end
      HPXML.add_building_occupancy(hpxml: hpxml, **building_occupancy_values) unless building_occupancy_values.empty?
      HPXML.add_building_construction(hpxml: hpxml, **building_construction_values)
      HPXML.add_climate_and_risk_zones(hpxml: hpxml, **climate_and_risk_zones_values)
      HPXML.add_air_infiltration_measurement(hpxml: hpxml, **air_infiltration_measurement_values)
      HPXML.add_attic(hpxml: hpxml, **attic_values) unless attic_values.empty?
      HPXML.add_foundation(hpxml: hpxml, **foundation_values) unless foundation_values.empty?
      roofs_values.each do |roof_values|
        HPXML.add_roof(hpxml: hpxml, **roof_values)
      end
      rim_joists_values.each do |rim_joist_values|
        HPXML.add_rim_joist(hpxml: hpxml, **rim_joist_values)
      end
      walls_values.each do |wall_values|
        HPXML.add_wall(hpxml: hpxml, **wall_values)
      end
      foundation_walls_values.each do |foundation_wall_values|
        HPXML.add_foundation_wall(hpxml: hpxml, **foundation_wall_values)
      end
      framefloors_values.each do |framefloor_values|
        HPXML.add_framefloor(hpxml: hpxml, **framefloor_values)
      end
      slabs_values.each do |slab_values|
        HPXML.add_slab(hpxml: hpxml, **slab_values)
      end
      windows_values.each do |window_values|
        HPXML.add_window(hpxml: hpxml, **window_values)
      end
      skylights_values.each do |skylight_values|
        HPXML.add_skylight(hpxml: hpxml, **skylight_values)
      end
      doors_values.each do |door_values|
        HPXML.add_door(hpxml: hpxml, **door_values)
      end
      heating_systems_values.each do |heating_system_values|
        HPXML.add_heating_system(hpxml: hpxml, **heating_system_values)
      end
      cooling_systems_values.each do |cooling_system_values|
        HPXML.add_cooling_system(hpxml: hpxml, **cooling_system_values)
      end
      heat_pumps_values.each do |heat_pump_values|
        HPXML.add_heat_pump(hpxml: hpxml, **heat_pump_values)
      end
      HPXML.add_hvac_control(hpxml: hpxml, **hvac_control_values) unless hvac_control_values.empty?
      hvac_distributions_values.each_with_index do |hvac_distribution_values, i|
        hvac_distribution = HPXML.add_hvac_distribution(hpxml: hpxml, **hvac_distribution_values)
        air_distribution = hvac_distribution.elements["DistributionSystemType/AirDistribution"]
        next if air_distribution.nil?

        duct_leakage_measurements_values[i].each do |duct_leakage_measurement_values|
          HPXML.add_duct_leakage_measurement(air_distribution: air_distribution, **duct_leakage_measurement_values)
        end
        ducts_values[i].each do |duct_values|
          HPXML.add_ducts(air_distribution: air_distribution, **duct_values)
        end
      end
      ventilation_fans_values.each do |ventilation_fan_values|
        HPXML.add_ventilation_fan(hpxml: hpxml, **ventilation_fan_values)
      end
      water_heating_systems_values.each do |water_heating_system_values|
        HPXML.add_water_heating_system(hpxml: hpxml, **water_heating_system_values)
      end
      HPXML.add_hot_water_distribution(hpxml: hpxml, **hot_water_distribution_values) unless hot_water_distribution_values.empty?
      water_fixtures_values.each do |water_fixture_values|
        HPXML.add_water_fixture(hpxml: hpxml, **water_fixture_values)
      end
      HPXML.add_solar_thermal_system(hpxml: hpxml, **solar_thermal_system_values) unless solar_thermal_system_values.empty?
      pv_systems_values.each do |pv_system_values|
        HPXML.add_pv_system(hpxml: hpxml, **pv_system_values)
      end
      HPXML.add_clothes_washer(hpxml: hpxml, **clothes_washer_values) unless clothes_washer_values.empty?
      HPXML.add_clothes_dryer(hpxml: hpxml, **clothes_dryer_values) unless clothes_dryer_values.empty?
      HPXML.add_dishwasher(hpxml: hpxml, **dishwasher_values) unless dishwasher_values.empty?
      HPXML.add_refrigerator(hpxml: hpxml, **refrigerator_values) unless refrigerator_values.empty?
      HPXML.add_cooking_range(hpxml: hpxml, **cooking_range_values) unless cooking_range_values.empty?
      HPXML.add_oven(hpxml: hpxml, **oven_values) unless oven_values.empty?
      HPXML.add_lighting(hpxml: hpxml, **lighting_values) unless lighting_values.empty?
      ceiling_fans_values.each do |ceiling_fan_values|
        HPXML.add_ceiling_fan(hpxml: hpxml, **ceiling_fan_values)
      end
      plug_loads_values.each do |plug_load_values|
        HPXML.add_plug_load(hpxml: hpxml, **plug_load_values)
      end
      HPXML.add_misc_loads_schedule(hpxml: hpxml, **misc_load_schedule_values) unless misc_load_schedule_values.empty?

      if ['invalid_files/missing-elements.xml'].include? derivative
        hpxml.elements["Building/BuildingDetails/BuildingSummary/BuildingConstruction"].elements.delete("NumberofConditionedFloors")
        hpxml.elements["Building/BuildingDetails/BuildingSummary/BuildingConstruction"].elements.delete("ConditionedFloorArea")
      end

      hpxml_path = File.join(tests_dir, derivative)

      # Validate file against HPXML schema
      schemas_dir = File.absolute_path(File.join(File.dirname(__FILE__), "HPXMLtoOpenStudio/resources"))
      errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, "HPXML.xsd"), nil)
      if errors.size > 0
        fail errors.to_s
      end

      XMLHelper.write_file(hpxml_doc, hpxml_path)
    rescue Exception => e
      puts "\n#{e}\n#{e.backtrace.join('\n')}"
      puts "\nError: Did not successfully generate #{derivative}."
      exit!
    end
  end

  puts "\n"

  # Print warnings about extra files
  abs_hpxml_files = []
  dirs = [nil]
  hpxmls_files.keys.each do |hpxml_file|
    abs_hpxml_files << File.absolute_path(File.join(tests_dir, hpxml_file))
    next unless hpxml_file.include? '/'

    dirs << hpxml_file.split('/')[0] + '/'
  end
  dirs.uniq.each do |dir|
    Dir["#{tests_dir}/#{dir}*.xml"].each do |xml|
      next if abs_hpxml_files.include? File.absolute_path(xml)

      puts "Warning: Extra HPXML file found at #{File.absolute_path(xml)}"
    end
  end
end

def get_hpxml_file_hpxml_values(hpxml_file, hpxml_values)
  if ['base.xml'].include? hpxml_file
    hpxml_values = { :xml_type => "HPXML",
                     :xml_generated_by => "Rakefile",
                     :transaction => "create",
                     :software_program_used => nil,
                     :software_program_version => nil,
                     :eri_calculation_version => nil,
                     :building_id => "MyBuilding",
                     :event_type => "proposed workscope" }
  elsif ['base-version-2014.xml'].include? hpxml_file
    hpxml_values[:eri_calculation_version] = "2014"
  elsif ['base-version-2014A.xml'].include? hpxml_file
    hpxml_values[:eri_calculation_version] = "2014A"
  elsif ['base-version-2014AE.xml'].include? hpxml_file
    hpxml_values[:eri_calculation_version] = "2014AE"
  elsif ['base-version-2014AEG.xml'].include? hpxml_file
    hpxml_values[:eri_calculation_version] = "2014AEG"
  elsif ['base-version-latest.xml'].include? hpxml_file
    hpxml_values[:eri_calculation_version] = 'latest'
  end
  return hpxml_values
end

def get_hpxml_file_site_values(hpxml_file, site_values)
  if ['base.xml'].include? hpxml_file
    site_values = { :fuels => ["electricity", "natural gas"] }
  elsif ['base-hvac-none-no-fuel-access.xml'].include? hpxml_file
    site_values[:fuels] = ["electricity"]
  elsif ['base-enclosure-no-natural-ventilation.xml'].include? hpxml_file
    site_values[:disable_natural_ventilation] = true
  end
  return site_values
end

def get_hpxml_file_site_neighbor_values(hpxml_file, site_neighbors_values)
  if ['base-site-neighbors.xml'].include? hpxml_file
    site_neighbors_values << { :azimuth => 0,
                               :distance => 10 }
    site_neighbors_values << { :azimuth => 180,
                               :distance => 15,
                               :height => 12 }
  elsif ['invalid_files/bad-site-neighbor-azimuth.xml'].include? hpxml_file
    site_neighbors_values[0][:azimuth] = 145
  end
  return site_neighbors_values
end

def get_hpxml_file_building_occupancy_values(hpxml_file, building_occupancy_values)
  if ['base-misc-number-of-occupants.xml'].include? hpxml_file
    building_occupancy_values = { :number_of_residents => 5 }
  end
  return building_occupancy_values
end

def get_hpxml_file_building_construction_values(hpxml_file, building_construction_values)
  if ['base.xml'].include? hpxml_file
    building_construction_values = { :number_of_conditioned_floors => 2,
                                     :number_of_conditioned_floors_above_grade => 1,
                                     :number_of_bedrooms => 3,
                                     :conditioned_floor_area => 2700,
                                     :conditioned_building_volume => 2700 * 8 }
  elsif ['base-enclosure-beds-1.xml'].include? hpxml_file
    building_construction_values[:number_of_bedrooms] = 1
  elsif ['base-enclosure-beds-2.xml'].include? hpxml_file
    building_construction_values[:number_of_bedrooms] = 2
  elsif ['base-enclosure-beds-4.xml'].include? hpxml_file
    building_construction_values[:number_of_bedrooms] = 4
  elsif ['base-enclosure-beds-5.xml'].include? hpxml_file
    building_construction_values[:number_of_bedrooms] = 5
  elsif ['base-foundation-ambient.xml',
         'base-foundation-slab.xml',
         'base-foundation-unconditioned-basement.xml',
         'base-foundation-unvented-crawlspace.xml',
         'base-foundation-vented-crawlspace.xml'].include? hpxml_file
    building_construction_values[:number_of_conditioned_floors] -= 1
    building_construction_values[:conditioned_floor_area] -= 1350
    building_construction_values[:conditioned_building_volume] -= 1350 * 8
  elsif ['base-hvac-ideal-air.xml'].include? hpxml_file
    building_construction_values[:use_only_ideal_air_system] = true
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    building_construction_values[:number_of_conditioned_floors] += 1
    building_construction_values[:number_of_conditioned_floors_above_grade] += 1
    building_construction_values[:conditioned_floor_area] += 900
    building_construction_values[:conditioned_building_volume] += 2250
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    building_construction_values[:conditioned_building_volume] += 10800
  elsif ['base-enclosure-2stories.xml'].include? hpxml_file
    building_construction_values[:number_of_conditioned_floors] += 1
    building_construction_values[:number_of_conditioned_floors_above_grade] += 1
    building_construction_values[:conditioned_floor_area] += 1350
    building_construction_values[:conditioned_building_volume] += 1350 * 8
  end
  return building_construction_values
end

def get_hpxml_file_climate_and_risk_zones_values(hpxml_file, climate_and_risk_zones_values)
  if ['base.xml'].include? hpxml_file
    climate_and_risk_zones_values = { :iecc2006 => "5B",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Denver, CO",
                                      :weather_station_wmo => "725650" }
  elsif ['base-location-baltimore-md.xml'].include? hpxml_file
    climate_and_risk_zones_values = { :iecc2006 => "4A",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Baltimore, MD",
                                      :weather_station_wmo => "724060" }
  elsif ['base-location-dallas-tx.xml'].include? hpxml_file
    climate_and_risk_zones_values = { :iecc2006 => "3A",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Dallas, TX",
                                      :weather_station_wmo => "722590" }
  elsif ['base-location-duluth-mn.xml'].include? hpxml_file
    climate_and_risk_zones_values = { :iecc2006 => "7",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Duluth, MN",
                                      :weather_station_wmo => "727450" }
  elsif ['base-location-miami-fl.xml'].include? hpxml_file
    climate_and_risk_zones_values = { :iecc2006 => "1A",
                                      :weather_station_id => "WeatherStation",
                                      :weather_station_name => "Miami, FL",
                                      :weather_station_wmo => "722020" }
  elsif ['base-location-epw-filename.xml'].include? hpxml_file
    climate_and_risk_zones_values[:weather_station_wmo] = nil
    climate_and_risk_zones_values[:weather_station_epw_filename] = "USA_CO_Denver.Intl.AP.725650_TMY3.epw"
  elsif ['invalid_files/bad-wmo.xml'].include? hpxml_file
    climate_and_risk_zones_values[:weather_station_wmo] = "999999"
  end
  return climate_and_risk_zones_values
end

def get_hpxml_file_air_infiltration_measurement_values(hpxml_file, air_infiltration_measurement_values, building_construction_values)
  infil_volume = building_construction_values[:conditioned_building_volume]
  if ['base.xml'].include? hpxml_file
    air_infiltration_measurement_values = { :id => "InfiltrationMeasurement",
                                            :house_pressure => 50,
                                            :unit_of_measure => "ACH",
                                            :air_leakage => 3.0 }
  elsif ['base-infiltration-ach-natural.xml'].include? hpxml_file
    air_infiltration_measurement_values = { :id => "InfiltrationMeasurement",
                                            :constant_ach_natural => 0.67 }
  elsif ['base-enclosure-infil-cfm50.xml'].include? hpxml_file
    air_infiltration_measurement_values = { :id => "InfiltrationMeasurement",
                                            :house_pressure => 50,
                                            :unit_of_measure => "CFM",
                                            :air_leakage => 3.0 / 60.0 * infil_volume }
  end
  air_infiltration_measurement_values[:infiltration_volume] = infil_volume
  return air_infiltration_measurement_values
end

def get_hpxml_file_attic_values(hpxml_file, attic_values)
  if ['base.xml'].include? hpxml_file
    attic_values = {}
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    attic_values = { :id => "VentedAttic",
                     :attic_type => "VentedAttic",
                     :vented_attic_sla => 0.003 }
  end
  return attic_values
end

def get_hpxml_file_foundation_values(hpxml_file, foundation_values)
  if ['base.xml'].include? hpxml_file
    foundation_values = {}
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    foundation_values = { :id => "VentedCrawlspace",
                          :foundation_type => "VentedCrawlspace",
                          :vented_crawlspace_sla => 0.00667 }
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    foundation_values = { :id => "UnconditionedBasement",
                          :foundation_type => "UnconditionedBasement",
                          :unconditioned_basement_thermal_boundary => "frame floor" }
  elsif ['base-foundation-unconditioned-basement-wall-insulation.xml'].include? hpxml_file
    foundation_values = { :id => "UnconditionedBasement",
                          :foundation_type => "UnconditionedBasement",
                          :unconditioned_basement_thermal_boundary => "foundation wall" }
  end
  return foundation_values
end

def get_hpxml_file_roofs_values(hpxml_file, roofs_values)
  if ['base.xml'].include? hpxml_file
    roofs_values = [{ :id => "Roof",
                      :interior_adjacent_to => "attic - unvented",
                      :area => 1510,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :pitch => 6,
                      :radiant_barrier => false,
                      :insulation_assembly_r_value => 2.3 }]
  elsif ['base-atticroof-flat.xml'].include? hpxml_file
    roofs_values = [{ :id => "Roof",
                      :interior_adjacent_to => "living space",
                      :area => 1350,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :pitch => 0,
                      :radiant_barrier => false,
                      :insulation_assembly_r_value => 25.8 }]
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    roofs_values = [{ :id => "RoofCond",
                      :interior_adjacent_to => "living space",
                      :area => 1006,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :pitch => 6,
                      :radiant_barrier => false,
                      :insulation_assembly_r_value => 25.8 },
                    { :id => "RoofUncond",
                      :interior_adjacent_to => "attic - unvented",
                      :area => 504,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :pitch => 6,
                      :radiant_barrier => false,
                      :insulation_assembly_r_value => 2.3 }]
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    roofs_values[0][:interior_adjacent_to] = "attic - vented"
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    roofs_values[0][:interior_adjacent_to] = "living space"
    roofs_values[0][:insulation_assembly_r_value] = 25.8
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    roofs_values << { :id => "RoofGarage",
                      :interior_adjacent_to => "garage",
                      :area => 670,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :pitch => 6,
                      :radiant_barrier => false,
                      :insulation_assembly_r_value => 2.3 }
  elsif ['base-atticroof-unvented-insulated-roof.xml'].include? hpxml_file
    roofs_values[0][:insulation_assembly_r_value] = 25.8
  elsif ['base-enclosure-adiabatic-surfaces.xml'].include? hpxml_file
    roofs_values = []
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..roofs_values.size
      roofs_values[n - 1][:area] /= 10.0
      for i in 2..10
        roofs_values << roofs_values[n - 1].dup
        roofs_values[-1][:id] += i.to_s
      end
    end
  elsif ['base-atticroof-radiant-barrier.xml'].include? hpxml_file
    roofs_values[0][:radiant_barrier] = true
  end
  return roofs_values
end

def get_hpxml_file_rim_joists_values(hpxml_file, rim_joists_values)
  if ['base.xml'].include? hpxml_file
    # TODO: Other geometry values (e.g., building volume) assume
    # no rim joists.
    rim_joists_values = [{ :id => "RimJoistFoundation",
                           :exterior_adjacent_to => "outside",
                           :interior_adjacent_to => "basement - conditioned",
                           :area => 116,
                           :solar_absorptance => 0.7,
                           :emittance => 0.92,
                           :insulation_assembly_r_value => 23.0 }]
  elsif ['base-foundation-ambient.xml',
         'base-foundation-slab.xml'].include? hpxml_file
    rim_joists_values = []
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    for i in 0..rim_joists_values.size - 1
      rim_joists_values[i][:interior_adjacent_to] = "basement - unconditioned"
      rim_joists_values[i][:insulation_assembly_r_value] = 2.3
    end
  elsif ['base-foundation-unconditioned-basement-wall-insulation.xml'].include? hpxml_file
    for i in 0..rim_joists_values.size - 1
      rim_joists_values[i][:insulation_assembly_r_value] = 23.0
    end
  elsif ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
    for i in 0..rim_joists_values.size - 1
      rim_joists_values[i][:interior_adjacent_to] = "crawlspace - unvented"
    end
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    for i in 0..rim_joists_values.size - 1
      rim_joists_values[i][:interior_adjacent_to] = "crawlspace - vented"
    end
  elsif ['base-foundation-multiple.xml'].include? hpxml_file
    rim_joists_values[0][:exterior_adjacent_to] = "crawlspace - unvented"
    rim_joists_values << { :id => "RimJoistCrawlspace",
                           :exterior_adjacent_to => "outside",
                           :interior_adjacent_to => "crawlspace - unvented",
                           :area => 81,
                           :solar_absorptance => 0.7,
                           :emittance => 0.92,
                           :insulation_assembly_r_value => 2.3 }
  elsif ['base-enclosure-2stories.xml'].include? hpxml_file
    rim_joists_values << { :id => "RimJoist2ndStory",
                           :exterior_adjacent_to => "outside",
                           :interior_adjacent_to => "living space",
                           :area => 116,
                           :solar_absorptance => 0.7,
                           :emittance => 0.92,
                           :insulation_assembly_r_value => 23.0 }
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..rim_joists_values.size
      rim_joists_values[n - 1][:area] /= 10.0
      for i in 2..10
        rim_joists_values << rim_joists_values[n - 1].dup
        rim_joists_values[-1][:id] += i.to_s
      end
    end
  end
  return rim_joists_values
end

def get_hpxml_file_walls_values(hpxml_file, walls_values)
  if ['base.xml'].include? hpxml_file
    walls_values = [{ :id => "Wall",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 1200,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 23 },
                    { :id => "WallAtticGable",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "attic - unvented",
                      :wall_type => "WoodStud",
                      :area => 290,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 4.0 }]
  elsif ['base-atticroof-flat.xml'].include? hpxml_file
    walls_values.delete_at(1)
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    walls_values[1][:interior_adjacent_to] = "attic - vented"
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    walls_values[1][:interior_adjacent_to] = "living space"
    walls_values[1][:insulation_assembly_r_value] = 23.0
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    walls_values.delete_at(1)
    walls_values << { :id => "WallAtticKneeWall",
                      :exterior_adjacent_to => "attic - unvented",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 316,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 23.0 }
    walls_values << { :id => "WallAtticGableCond",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 240,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 22.3 }
    walls_values << { :id => "WallAtticGableUncond",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "attic - unvented",
                      :wall_type => "WoodStud",
                      :area => 50,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 4.0 }
  elsif ['base-enclosure-walltype-cmu.xml'].include? hpxml_file
    walls_values[0][:wall_type] = "ConcreteMasonryUnit"
    walls_values[0][:insulation_assembly_r_value] = 12
  elsif ['base-enclosure-walltype-doublestud.xml'].include? hpxml_file
    walls_values[0][:wall_type] = "DoubleWoodStud"
    walls_values[0][:insulation_assembly_r_value] = 28.7
  elsif ['base-enclosure-walltype-icf.xml'].include? hpxml_file
    walls_values[0][:wall_type] = "InsulatedConcreteForms"
    walls_values[0][:insulation_assembly_r_value] = 21
  elsif ['base-enclosure-walltype-log.xml'].include? hpxml_file
    walls_values[0][:wall_type] = "LogWall"
    walls_values[0][:insulation_assembly_r_value] = 7.1
  elsif ['base-enclosure-walltype-sip.xml'].include? hpxml_file
    walls_values[0][:wall_type] = "StructurallyInsulatedPanel"
    walls_values[0][:insulation_assembly_r_value] = 16.1
  elsif ['base-enclosure-walltype-solidconcrete.xml'].include? hpxml_file
    walls_values[0][:wall_type] = "SolidConcrete"
    walls_values[0][:insulation_assembly_r_value] = 1.35
  elsif ['base-enclosure-walltype-steelstud.xml'].include? hpxml_file
    walls_values[0][:wall_type] = "SteelFrame"
    walls_values[0][:insulation_assembly_r_value] = 8.1
  elsif ['base-enclosure-walltype-stone.xml'].include? hpxml_file
    walls_values[0][:wall_type] = "Stone"
    walls_values[0][:insulation_assembly_r_value] = 5.4
  elsif ['base-enclosure-walltype-strawbale.xml'].include? hpxml_file
    walls_values[0][:wall_type] = "StrawBale"
    walls_values[0][:insulation_assembly_r_value] = 58.8
  elsif ['base-enclosure-walltype-structuralbrick.xml'].include? hpxml_file
    walls_values[0][:wall_type] = "StructuralBrick"
    walls_values[0][:insulation_assembly_r_value] = 7.9
  elsif ['invalid_files/missing-surfaces.xml'].include? hpxml_file
    walls_values << { :id => "WallGarage",
                      :exterior_adjacent_to => "garage",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 100,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 4 }
  elsif ['base-enclosure-2stories.xml'].include? hpxml_file
    walls_values[0][:area] *= 2.0
  elsif ['base-enclosure-2stories-garage.xml'].include? hpxml_file
    walls_values = [{ :id => "Wall",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 880,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 23 },
                    { :id => "WallGarageInterior",
                      :exterior_adjacent_to => "garage",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 320,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 23 },
                    { :id => "WallGarageExterior",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "garage",
                      :wall_type => "WoodStud",
                      :area => 800,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 4 }]
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    walls_values = [{ :id => "Wall",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 960,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 23 },
                    { :id => "WallGarageInterior",
                      :exterior_adjacent_to => "garage",
                      :interior_adjacent_to => "living space",
                      :wall_type => "WoodStud",
                      :area => 240,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 23 },
                    { :id => "WallGarageExterior",
                      :exterior_adjacent_to => "outside",
                      :interior_adjacent_to => "garage",
                      :wall_type => "WoodStud",
                      :area => 560,
                      :solar_absorptance => 0.7,
                      :emittance => 0.92,
                      :insulation_assembly_r_value => 4 }]
  elsif ['base-atticroof-unvented-insulated-roof.xml'].include? hpxml_file
    walls_values[1][:insulation_assembly_r_value] = 23
  elsif ['base-enclosure-adiabatic-surfaces.xml'].include? hpxml_file
    walls_values.delete_at(1)
    walls_values << walls_values[0].dup
    walls_values[0][:area] *= 0.35
    walls_values[-1][:area] *= 0.65
    walls_values[-1][:id] += "Adiabatic"
    walls_values[-1][:exterior_adjacent_to] = "other housing unit"
    walls_values[-1][:insulation_assembly_r_value] = 4
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..walls_values.size
      walls_values[n - 1][:area] /= 10.0
      for i in 2..10
        walls_values << walls_values[n - 1].dup
        walls_values[-1][:id] += i.to_s
      end
    end
  end
  return walls_values
end

def get_hpxml_file_foundation_walls_values(hpxml_file, foundation_walls_values)
  if ['base.xml'].include? hpxml_file
    foundation_walls_values = [{ :id => "FoundationWall",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "basement - conditioned",
                                 :height => 8,
                                 :area => 1200,
                                 :thickness => 8,
                                 :depth_below_grade => 7,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 8,
                                 :insulation_exterior_r_value => 8.9 }]
  elsif ['base-foundation-conditioned-basement-wall-interior-insulation.xml'].include? hpxml_file
    foundation_walls_values[0][:insulation_interior_distance_to_top] = 0
    foundation_walls_values[0][:insulation_interior_distance_to_bottom] = 8
    foundation_walls_values[0][:insulation_interior_r_value] = 10
    foundation_walls_values[0][:insulation_exterior_distance_to_top] = 1
    foundation_walls_values[0][:insulation_exterior_distance_to_bottom] = 8
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    foundation_walls_values[0][:interior_adjacent_to] = "basement - unconditioned"
    foundation_walls_values[0][:insulation_exterior_distance_to_bottom] = 0
    foundation_walls_values[0][:insulation_exterior_r_value] = 0
  elsif ['base-foundation-unconditioned-basement-wall-insulation.xml'].include? hpxml_file
    foundation_walls_values[0][:insulation_exterior_distance_to_bottom] = 4
    foundation_walls_values[0][:insulation_exterior_r_value] = 8.9
  elsif ['base-foundation-unconditioned-basement-assembly-r.xml'].include? hpxml_file
    foundation_walls_values[0][:insulation_exterior_distance_to_top] = nil
    foundation_walls_values[0][:insulation_exterior_distance_to_bottom] = nil
    foundation_walls_values[0][:insulation_exterior_r_value] = nil
    foundation_walls_values[0][:insulation_interior_distance_to_top] = nil
    foundation_walls_values[0][:insulation_interior_distance_to_bottom] = nil
    foundation_walls_values[0][:insulation_interior_r_value] = nil
    foundation_walls_values[0][:insulation_assembly_r_value] = 10.69
  elsif ['base-foundation-unconditioned-basement-above-grade.xml'].include? hpxml_file
    foundation_walls_values[0][:depth_below_grade] = 4
  elsif ['base-foundation-unvented-crawlspace.xml',
         'base-foundation-vented-crawlspace.xml'].include? hpxml_file
    if ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
      foundation_walls_values[0][:interior_adjacent_to] = "crawlspace - unvented"
    else
      foundation_walls_values[0][:interior_adjacent_to] = "crawlspace - vented"
    end
    foundation_walls_values[0][:height] -= 4
    foundation_walls_values[0][:area] /= 2.0
    foundation_walls_values[0][:depth_below_grade] -= 4
    foundation_walls_values[0][:insulation_exterior_distance_to_bottom] -= 4
  elsif ['base-foundation-multiple.xml'].include? hpxml_file
    foundation_walls_values[0][:area] = 600
    foundation_walls_values << { :id => "FoundationWallInterior",
                                 :exterior_adjacent_to => "crawlspace - unvented",
                                 :interior_adjacent_to => "basement - unconditioned",
                                 :height => 8,
                                 :area => 360,
                                 :thickness => 8,
                                 :depth_below_grade => 4,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 0,
                                 :insulation_exterior_r_value => 0 }
    foundation_walls_values << { :id => "FoundationWallCrawlspace",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "crawlspace - unvented",
                                 :height => 4,
                                 :area => 600,
                                 :thickness => 8,
                                 :depth_below_grade => 3,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 0,
                                 :insulation_exterior_r_value => 0 }
  elsif ['base-foundation-ambient.xml',
         'base-foundation-slab.xml'].include? hpxml_file
    foundation_walls_values = []
  elsif ['base-foundation-walkout-basement.xml'].include? hpxml_file
    foundation_walls_values = [{ :id => "FoundationWall1",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "basement - conditioned",
                                 :height => 8,
                                 :area => 480,
                                 :thickness => 8,
                                 :depth_below_grade => 7,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 8,
                                 :insulation_exterior_r_value => 8.9 },
                               { :id => "FoundationWall2",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "basement - conditioned",
                                 :height => 4,
                                 :area => 120,
                                 :thickness => 8,
                                 :depth_below_grade => 3,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 4,
                                 :insulation_exterior_r_value => 8.9 },
                               { :id => "FoundationWall3",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "basement - conditioned",
                                 :height => 2,
                                 :area => 60,
                                 :thickness => 8,
                                 :depth_below_grade => 1,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 2,
                                 :insulation_exterior_r_value => 8.9 }]
  elsif ['base-foundation-complex.xml'].include? hpxml_file
    foundation_walls_values = [{ :id => "FoundationWall1",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "basement - conditioned",
                                 :height => 8,
                                 :area => 160,
                                 :thickness => 8,
                                 :depth_below_grade => 7,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 0,
                                 :insulation_exterior_r_value => 0.0 },
                               { :id => "FoundationWall2",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "basement - conditioned",
                                 :height => 8,
                                 :area => 240,
                                 :thickness => 8,
                                 :depth_below_grade => 7,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 8,
                                 :insulation_exterior_r_value => 8.9 },
                               { :id => "FoundationWall3",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "basement - conditioned",
                                 :height => 4,
                                 :area => 160,
                                 :thickness => 8,
                                 :depth_below_grade => 3,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 0,
                                 :insulation_exterior_r_value => 0.0 },
                               { :id => "FoundationWall4",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "basement - conditioned",
                                 :height => 4,
                                 :area => 120,
                                 :thickness => 8,
                                 :depth_below_grade => 3,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 4,
                                 :insulation_exterior_r_value => 8.9 },
                               { :id => "FoundationWall5",
                                 :exterior_adjacent_to => "ground",
                                 :interior_adjacent_to => "basement - conditioned",
                                 :height => 4,
                                 :area => 80,
                                 :thickness => 8,
                                 :depth_below_grade => 3,
                                 :insulation_interior_r_value => 0,
                                 :insulation_interior_distance_to_top => 0,
                                 :insulation_interior_distance_to_bottom => 0,
                                 :insulation_exterior_distance_to_top => 0,
                                 :insulation_exterior_distance_to_bottom => 4,
                                 :insulation_exterior_r_value => 8.9 }]
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..foundation_walls_values.size
      foundation_walls_values[n - 1][:area] /= 10.0
      for i in 2..10
        foundation_walls_values << foundation_walls_values[n - 1].dup
        foundation_walls_values[-1][:id] += i.to_s
      end
    end
  end
  return foundation_walls_values
end

def get_hpxml_file_framefloors_values(hpxml_file, framefloors_values)
  if ['base.xml'].include? hpxml_file
    framefloors_values = [{ :id => "FloorBelowAttic",
                            :exterior_adjacent_to => "attic - unvented",
                            :interior_adjacent_to => "living space",
                            :area => 1350,
                            :insulation_assembly_r_value => 39.3 }]
  elsif ['base-atticroof-flat.xml',
         'base-atticroof-cathedral.xml'].include? hpxml_file
    framefloors_values.delete_at(0)
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    framefloors_values[0][:exterior_adjacent_to] = "attic - vented"
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    framefloors_values[0][:area] = 450
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    framefloors_values << { :id => "FloorBetweenAtticGarage",
                            :exterior_adjacent_to => "attic - unvented",
                            :interior_adjacent_to => "garage",
                            :area => 600,
                            :insulation_assembly_r_value => 2.1 }
  elsif ['base-foundation-ambient.xml'].include? hpxml_file
    framefloors_values << { :id => "FloorAboveAmbient",
                            :exterior_adjacent_to => "outside",
                            :interior_adjacent_to => "living space",
                            :area => 1350,
                            :insulation_assembly_r_value => 18.7 }
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    framefloors_values << { :id => "FloorAboveUncondBasement",
                            :exterior_adjacent_to => "basement - unconditioned",
                            :interior_adjacent_to => "living space",
                            :area => 1350,
                            :insulation_assembly_r_value => 18.7 }
  elsif ['base-foundation-unconditioned-basement-wall-insulation.xml'].include? hpxml_file
    framefloors_values[1][:insulation_assembly_r_value] = 2.1
  elsif ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
    framefloors_values << { :id => "FloorAboveUnventedCrawl",
                            :exterior_adjacent_to => "crawlspace - unvented",
                            :interior_adjacent_to => "living space",
                            :area => 1350,
                            :insulation_assembly_r_value => 18.7 }
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    framefloors_values << { :id => "FloorAboveVentedCrawl",
                            :exterior_adjacent_to => "crawlspace - vented",
                            :interior_adjacent_to => "living space",
                            :area => 1350,
                            :insulation_assembly_r_value => 18.7 }
  elsif ['base-foundation-multiple.xml'].include? hpxml_file
    framefloors_values[1][:area] = 675
    framefloors_values << { :id => "FloorAboveUnventedCrawlspace",
                            :exterior_adjacent_to => "crawlspace - unvented",
                            :interior_adjacent_to => "living space",
                            :area => 675,
                            :insulation_assembly_r_value => 18.7 }
  elsif ['base-enclosure-2stories-garage.xml'].include? hpxml_file
    framefloors_values << { :id => "FloorAboveGarage",
                            :exterior_adjacent_to => "garage",
                            :interior_adjacent_to => "living space",
                            :area => 400,
                            :insulation_assembly_r_value => 18.7 }
  elsif ['base-atticroof-unvented-insulated-roof.xml'].include? hpxml_file
    framefloors_values[0][:insulation_assembly_r_value] = 2.1
  elsif ['base-enclosure-adiabatic-surfaces.xml'].include? hpxml_file
    framefloors_values = [{ :id => "FloorAboveAdiabatic",
                            :exterior_adjacent_to => "other housing unit below",
                            :interior_adjacent_to => "living space",
                            :area => 1350,
                            :insulation_assembly_r_value => 2.1 },
                          { :id => "FloorBelowAdiabatic",
                            :exterior_adjacent_to => "other housing unit above",
                            :interior_adjacent_to => "living space",
                            :area => 1350,
                            :insulation_assembly_r_value => 2.1 }]
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..framefloors_values.size
      framefloors_values[n - 1][:area] /= 10.0
      for i in 2..10
        framefloors_values << framefloors_values[n - 1].dup
        framefloors_values[-1][:id] += i.to_s
      end
    end
  end
  return framefloors_values
end

def get_hpxml_file_slabs_values(hpxml_file, slabs_values)
  if ['base.xml'].include? hpxml_file
    slabs_values = [{ :id => "Slab",
                      :interior_adjacent_to => "basement - conditioned",
                      :area => 1350,
                      :thickness => 4,
                      :exposed_perimeter => 150,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 0,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 0,
                      :carpet_r_value => 0 }]
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    slabs_values[0][:interior_adjacent_to] = "basement - unconditioned"
  elsif ['base-foundation-conditioned-basement-slab-insulation.xml'].include? hpxml_file
    slabs_values[0][:under_slab_insulation_width] = 4
    slabs_values[0][:under_slab_insulation_r_value] = 10
  elsif ['base-foundation-slab.xml'].include? hpxml_file
    slabs_values[0][:interior_adjacent_to] = "living space"
    slabs_values[0][:under_slab_insulation_width] = nil
    slabs_values[0][:under_slab_insulation_spans_entire_slab] = true
    slabs_values[0][:depth_below_grade] = 0
    slabs_values[0][:under_slab_insulation_r_value] = 5
    slabs_values[0][:carpet_fraction] = 1
    slabs_values[0][:carpet_r_value] = 2.5
  elsif ['base-foundation-unvented-crawlspace.xml',
         'base-foundation-vented-crawlspace.xml'].include? hpxml_file
    if ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
      slabs_values[0][:interior_adjacent_to] = "crawlspace - unvented"
    else
      slabs_values[0][:interior_adjacent_to] = "crawlspace - vented"
    end
    slabs_values[0][:thickness] = 0
    slabs_values[0][:carpet_r_value] = 2.5
  elsif ['base-foundation-multiple.xml'].include? hpxml_file
    slabs_values[0][:area] = 675
    slabs_values[0][:exposed_perimeter] = 75
    slabs_values << { :id => "SlabUnderCrawlspace",
                      :interior_adjacent_to => "crawlspace - unvented",
                      :area => 675,
                      :thickness => 0,
                      :exposed_perimeter => 75,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 0,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 0,
                      :carpet_r_value => 0 }
  elsif ['base-foundation-ambient.xml'].include? hpxml_file
    slabs_values = []
  elsif ['base-enclosure-2stories-garage.xml'].include? hpxml_file
    slabs_values[0][:area] -= 400
    slabs_values[0][:exposed_perimeter] -= 40
    slabs_values << { :id => "SlabUnderGarage",
                      :interior_adjacent_to => "garage",
                      :area => 400,
                      :thickness => 4,
                      :exposed_perimeter => 40,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 0,
                      :depth_below_grade => 0,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 0,
                      :carpet_r_value => 0 }
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    slabs_values[0][:exposed_perimeter] -= 30
    slabs_values << { :id => "SlabUnderGarage",
                      :interior_adjacent_to => "garage",
                      :area => 600,
                      :thickness => 4,
                      :exposed_perimeter => 70,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 0,
                      :depth_below_grade => 0,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 0,
                      :carpet_r_value => 0 }
  elsif ['base-foundation-complex.xml'].include? hpxml_file
    slabs_values = [{ :id => "Slab1",
                      :interior_adjacent_to => "basement - conditioned",
                      :area => 675,
                      :thickness => 4,
                      :exposed_perimeter => 75,
                      :perimeter_insulation_depth => 0,
                      :under_slab_insulation_width => 0,
                      :perimeter_insulation_r_value => 0,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 0,
                      :carpet_r_value => 0 },
                    { :id => "Slab2",
                      :interior_adjacent_to => "basement - conditioned",
                      :area => 405,
                      :thickness => 4,
                      :exposed_perimeter => 45,
                      :perimeter_insulation_depth => 1,
                      :under_slab_insulation_width => 0,
                      :perimeter_insulation_r_value => 5,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 0,
                      :carpet_r_value => 0 },
                    { :id => "Slab3",
                      :interior_adjacent_to => "basement - conditioned",
                      :area => 270,
                      :thickness => 4,
                      :exposed_perimeter => 30,
                      :perimeter_insulation_depth => 1,
                      :under_slab_insulation_width => 0,
                      :perimeter_insulation_r_value => 5,
                      :under_slab_insulation_r_value => 0,
                      :carpet_fraction => 0,
                      :carpet_r_value => 0 }]
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..slabs_values.size
      slabs_values[n - 1][:area] /= 10.0
      slabs_values[n - 1][:exposed_perimeter] /= 10.0
      for i in 2..10
        slabs_values << slabs_values[n - 1].dup
        slabs_values[-1][:id] += i.to_s
      end
    end
  end
  return slabs_values
end

def get_hpxml_file_windows_values(hpxml_file, windows_values)
  if ['base.xml'].include? hpxml_file
    windows_values = [{ :id => "WindowNorth",
                        :area => 54,
                        :azimuth => 0,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "Wall" },
                      { :id => "WindowSouth",
                        :area => 54,
                        :azimuth => 180,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "Wall" },
                      { :id => "WindowEast",
                        :area => 36,
                        :azimuth => 90,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "Wall" },
                      { :id => "WindowWest",
                        :area => 36,
                        :azimuth => 270,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "Wall" }]
  elsif ['base-enclosure-overhangs.xml'].include? hpxml_file
    windows_values[0][:overhangs_depth] = 2.5
    windows_values[0][:overhangs_distance_to_top_of_window] = 0
    windows_values[0][:overhangs_distance_to_bottom_of_window] = 4
    windows_values[2][:overhangs_depth] = 1.5
    windows_values[2][:overhangs_distance_to_top_of_window] = 2
    windows_values[2][:overhangs_distance_to_bottom_of_window] = 6
    windows_values[3][:overhangs_depth] = 1.5
    windows_values[3][:overhangs_distance_to_top_of_window] = 2
    windows_values[3][:overhangs_distance_to_bottom_of_window] = 7
  elsif ['base-enclosure-windows-interior-shading.xml'].include? hpxml_file
    windows_values[0][:interior_shading_factor_summer] = 0.7
    windows_values[0][:interior_shading_factor_winter] = 0.85
    windows_values[1][:interior_shading_factor_summer] = 0.01
    windows_values[1][:interior_shading_factor_winter] = 0.99
    windows_values[2][:interior_shading_factor_summer] = 0.0
    windows_values[2][:interior_shading_factor_winter] = 0.5
    windows_values[3][:interior_shading_factor_summer] = 1.0
    windows_values[3][:interior_shading_factor_winter] = 1.0
  elsif ['invalid_files/invalid-window-interior-shading.xml'].include? hpxml_file
    windows_values[0][:interior_shading_factor_summer] = 0.85
    windows_values[0][:interior_shading_factor_winter] = 0.7
  elsif ['base-enclosure-windows-none.xml'].include? hpxml_file
    windows_values = []
  elsif ['invalid_files/net-area-negative-wall.xml'].include? hpxml_file
    windows_values[0][:area] = 1000
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    windows_values[0][:area] = 54
    windows_values[1][:area] = 54
    windows_values[2][:area] = 54
    windows_values[3][:area] = 54
    windows_values << { :id => "AtticGableWindowEast",
                        :area => 12,
                        :azimuth => 90,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "WallAtticGableCond" }
    windows_values << { :id => "AtticGableWindowWest",
                        :area => 62,
                        :azimuth => 270,
                        :ufactor => 0.3,
                        :shgc => 0.45,
                        :wall_idref => "WallAtticGableCond" }
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    windows_values[0][:area] = 54
    windows_values[1][:area] = 54
    windows_values[2][:area] = 54
    windows_values[3][:area] = 54
    windows_values << { :id => "AtticGableWindowEast",
                        :area => 12,
                        :azimuth => 90,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "WallAtticGable" }
    windows_values << { :id => "AtticGableWindowWest",
                        :area => 12,
                        :azimuth => 270,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "WallAtticGable" }
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    windows_values.delete_at(2)
    windows_values << { :id => "GarageWindowEast",
                        :area => 12,
                        :azimuth => 90,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "WallGarageExterior" }
  elsif ['base-enclosure-2stories.xml'].include? hpxml_file
    windows_values[0][:area] = 108
    windows_values[1][:area] = 108
    windows_values[2][:area] = 72
    windows_values[3][:area] = 72
  elsif ['base-enclosure-2stories-garage'].include? hpxml_file
    windows_values[0][:area] = 84
    windows_values[1][:area] = 108
    windows_values[2][:area] = 72
    windows_values[3][:area] = 48
  elsif ['base-foundation-unconditioned-basement-above-grade.xml'].include? hpxml_file
    windows_values << { :id => "FoundationWindowNorth",
                        :area => 20,
                        :azimuth => 0,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "FoundationWall" }
    windows_values << { :id => "FoundationWindowSouth",
                        :area => 20,
                        :azimuth => 180,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "FoundationWall" }
    windows_values << { :id => "FoundationWindowEast",
                        :area => 10,
                        :azimuth => 90,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "FoundationWall" }
    windows_values << { :id => "FoundationWindowWest",
                        :area => 10,
                        :azimuth => 270,
                        :ufactor => 0.33,
                        :shgc => 0.45,
                        :wall_idref => "FoundationWall" }
  elsif ['invalid_files/unattached-window.xml'].include? hpxml_file
    windows_values[0][:wall_idref] = "foobar"
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    area_adjustments = []
    for n in 1..windows_values.size
      windows_values[n - 1][:area] /= 10.0
      for i in 2..10
        windows_values << windows_values[n - 1].dup
        windows_values[-1][:id] += i.to_s
        windows_values[-1][:wall_idref] += i.to_s
      end
    end
  end
  return windows_values
end

def get_hpxml_file_skylights_values(hpxml_file, skylights_values)
  if ['base-enclosure-skylights.xml'].include? hpxml_file
    skylights_values << { :id => "SkylightNorth",
                          :area => 15,
                          :azimuth => 0,
                          :ufactor => 0.33,
                          :shgc => 0.45,
                          :roof_idref => "Roof" }
    skylights_values << { :id => "SkylightSouth",
                          :area => 15,
                          :azimuth => 180,
                          :ufactor => 0.35,
                          :shgc => 0.47,
                          :roof_idref => "Roof" }
  elsif ['invalid_files/net-area-negative-roof.xml'].include? hpxml_file
    skylights_values[0][:area] = 4000
  elsif ['invalid_files/unattached-skylight.xml'].include? hpxml_file
    skylights_values[0][:roof_idref] = "foobar"
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..skylights_values.size
      skylights_values[n - 1][:area] /= 10.0
      for i in 2..10
        skylights_values << skylights_values[n - 1].dup
        skylights_values[-1][:id] += i.to_s
        skylights_values[-1][:roof_idref] += i.to_s if i % 2 == 0
      end
    end
  end
  return skylights_values
end

def get_hpxml_file_doors_values(hpxml_file, doors_values)
  if ['base.xml'].include? hpxml_file
    doors_values = [{ :id => "DoorNorth",
                      :wall_idref => "Wall",
                      :area => 40,
                      :azimuth => 0,
                      :r_value => 4.4 },
                    { :id => "DoorSouth",
                      :wall_idref => "Wall",
                      :area => 40,
                      :azimuth => 180,
                      :r_value => 4.4 }]
  elsif ['base-enclosure-garage.xml',
         'base-enclosure-2stories-garage.xml'].include? hpxml_file
    doors_values << { :id => "GarageDoorSouth",
                      :wall_idref => "WallGarageExterior",
                      :area => 70,
                      :azimuth => 180,
                      :r_value => 4.4 }
  elsif ['invalid_files/unattached-door.xml'].include? hpxml_file
    doors_values[0][:wall_idref] = "foobar"
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    area_adjustments = []
    for n in 1..doors_values.size
      doors_values[n - 1][:area] /= 10.0
      for i in 2..10
        doors_values << doors_values[n - 1].dup
        doors_values[-1][:id] += i.to_s
        doors_values[-1][:wall_idref] += i.to_s
      end
    end
  end
  return doors_values
end

def get_hpxml_file_heating_systems_values(hpxml_file, heating_systems_values)
  if ['base.xml'].include? hpxml_file
    heating_systems_values = [{ :id => "HeatingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 64000,
                                :heating_efficiency_afue => 0.92,
                                :fraction_heat_load_served => 1 }]
  elsif ['base-hvac-air-to-air-heat-pump-1-speed.xml',
         'base-hvac-air-to-air-heat-pump-2-speed.xml',
         'base-hvac-air-to-air-heat-pump-var-speed.xml',
         'base-hvac-central-ac-only-1-speed.xml',
         'base-hvac-central-ac-only-2-speed.xml',
         'base-hvac-central-ac-only-var-speed.xml',
         'base-hvac-evap-cooler-only.xml',
         'base-hvac-evap-cooler-only-ducted.xml',
         'base-hvac-ground-to-air-heat-pump.xml',
         'base-hvac-mini-split-heat-pump-ducted.xml',
         'base-hvac-mini-split-heat-pump-ductless-no-backup.xml',
         'base-hvac-ideal-air.xml',
         'base-hvac-none.xml',
         'base-hvac-room-ac-only.xml',
         'invalid_files/orphaned-hvac-distribution.xml'].include? hpxml_file
    heating_systems_values = []
  elsif ['base-hvac-boiler-elec-only.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_type] = "Boiler"
    heating_systems_values[0][:heating_system_fuel] = "electricity"
    heating_systems_values[0][:heating_efficiency_afue] = 1
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.xml',
         'base-hvac-boiler-gas-only.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_type] = "Boiler"
    heating_systems_values[0][:electric_auxiliary_energy] = 200
  elsif ['base-hvac-boiler-oil-only.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_type] = "Boiler"
    heating_systems_values[0][:heating_system_fuel] = "fuel oil"
  elsif ['base-hvac-boiler-propane-only.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_type] = "Boiler"
    heating_systems_values[0][:heating_system_fuel] = "propane"
  elsif ['base-hvac-boiler-wood-only.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_type] = "Boiler"
    heating_systems_values[0][:heating_system_fuel] = "wood"
  elsif ['base-hvac-elec-resistance-only.xml'].include? hpxml_file
    heating_systems_values[0][:distribution_system_idref] = nil
    heating_systems_values[0][:heating_system_type] = "ElectricResistance"
    heating_systems_values[0][:heating_system_fuel] = "electricity"
    heating_systems_values[0][:heating_efficiency_afue] = nil
    heating_systems_values[0][:heating_efficiency_percent] = 1
  elsif ['base-hvac-furnace-elec-only.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_fuel] = "electricity"
    heating_systems_values[0][:heating_efficiency_afue] = 1
  elsif ['base-hvac-furnace-gas-only.xml'].include? hpxml_file
    heating_systems_values[0][:electric_auxiliary_energy] = 700
  elsif ['base-hvac-furnace-gas-only-no-eae.xml',
         'base-hvac-boiler-gas-only-no-eae.xml',
         'base-hvac-stove-oil-only-no-eae.xml',
         'base-hvac-wall-furnace-propane-only-no-eae.xml'].include? hpxml_file
    heating_systems_values[0][:electric_auxiliary_energy] = nil
  elsif ['base-hvac-furnace-oil-only.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_fuel] = "fuel oil"
  elsif ['base-hvac-furnace-propane-only.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_fuel] = "propane"
  elsif ['base-hvac-furnace-wood-only.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_fuel] = "wood"
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    heating_systems_values[0][:heating_system_type] = "Boiler"
    heating_systems_values[0][:heating_system_fuel] = "electricity"
    heating_systems_values[0][:heating_efficiency_afue] = 1
    heating_systems_values[0][:fraction_heat_load_served] = 0.1
    heating_systems_values[0][:heating_capacity] *= 0.1
    heating_systems_values << { :id => "HeatingSystem2",
                                :distribution_system_idref => "HVACDistribution2",
                                :heating_system_type => "Boiler",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 6400,
                                :heating_efficiency_afue => 0.92,
                                :fraction_heat_load_served => 0.1,
                                :electric_auxiliary_energy => 200 }
    heating_systems_values << { :id => "HeatingSystem3",
                                :heating_system_type => "ElectricResistance",
                                :heating_system_fuel => "electricity",
                                :heating_capacity => 6400,
                                :heating_efficiency_percent => 1,
                                :fraction_heat_load_served => 0.1 }
    heating_systems_values << { :id => "HeatingSystem4",
                                :distribution_system_idref => "HVACDistribution3",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "electricity",
                                :heating_capacity => 6400,
                                :heating_efficiency_afue => 1,
                                :fraction_heat_load_served => 0.1 }
    heating_systems_values << { :id => "HeatingSystem5",
                                :distribution_system_idref => "HVACDistribution4",
                                :heating_system_type => "Furnace",
                                :heating_system_fuel => "natural gas",
                                :heating_capacity => 6400,
                                :heating_efficiency_afue => 0.92,
                                :fraction_heat_load_served => 0.1,
                                :electric_auxiliary_energy => 700 }
    heating_systems_values << { :id => "HeatingSystem6",
                                :heating_system_type => "Stove",
                                :heating_system_fuel => "fuel oil",
                                :heating_capacity => 6400,
                                :heating_efficiency_percent => 0.8,
                                :fraction_heat_load_served => 0.1,
                                :electric_auxiliary_energy => 200 }
    heating_systems_values << { :id => "HeatingSystem7",
                                :heating_system_type => "WallFurnace",
                                :heating_system_fuel => "propane",
                                :heating_capacity => 6400,
                                :heating_efficiency_afue => 0.8,
                                :fraction_heat_load_served => 0.1,
                                :electric_auxiliary_energy => 200 }
  elsif ['invalid_files/hvac-frac-load-served.xml'].include? hpxml_file
    heating_systems_values[0][:fraction_heat_load_served] += 0.1
  elsif ['base-hvac-portable-heater-electric-only.xml'].include? hpxml_file
    heating_systems_values[0][:distribution_system_idref] = nil
    heating_systems_values[0][:heating_system_type] = "PortableHeater"
    heating_systems_values[0][:heating_system_fuel] = "electricity"
    heating_systems_values[0][:heating_efficiency_afue] = nil
    heating_systems_values[0][:heating_efficiency_percent] = 1.0
  elsif ['base-hvac-stove-oil-only.xml'].include? hpxml_file
    heating_systems_values[0][:distribution_system_idref] = nil
    heating_systems_values[0][:heating_system_type] = "Stove"
    heating_systems_values[0][:heating_system_fuel] = "fuel oil"
    heating_systems_values[0][:heating_efficiency_afue] = nil
    heating_systems_values[0][:heating_efficiency_percent] = 0.8
    heating_systems_values[0][:electric_auxiliary_energy] = 200
  elsif ['base-hvac-stove-wood-only.xml'].include? hpxml_file
    heating_systems_values[0][:distribution_system_idref] = nil
    heating_systems_values[0][:heating_system_type] = "Stove"
    heating_systems_values[0][:heating_system_fuel] = "wood"
    heating_systems_values[0][:heating_efficiency_afue] = nil
    heating_systems_values[0][:heating_efficiency_percent] = 0.8
    heating_systems_values[0][:electric_auxiliary_energy] = 200
  elsif ['base-hvac-wall-furnace-elec-only.xml'].include? hpxml_file
    heating_systems_values[0][:distribution_system_idref] = nil
    heating_systems_values[0][:heating_system_type] = "WallFurnace"
    heating_systems_values[0][:heating_system_fuel] = "electricity"
    heating_systems_values[0][:heating_efficiency_afue] = 1.0
    heating_systems_values[0][:electric_auxiliary_energy] = 200
  elsif ['base-hvac-wall-furnace-propane-only.xml'].include? hpxml_file
    heating_systems_values[0][:distribution_system_idref] = nil
    heating_systems_values[0][:heating_system_type] = "WallFurnace"
    heating_systems_values[0][:heating_system_fuel] = "propane"
    heating_systems_values[0][:heating_efficiency_afue] = 0.8
    heating_systems_values[0][:electric_auxiliary_energy] = 200
  elsif ['base-hvac-wall-furnace-wood-only.xml'].include? hpxml_file
    heating_systems_values[0][:distribution_system_idref] = nil
    heating_systems_values[0][:heating_system_type] = "WallFurnace"
    heating_systems_values[0][:heating_system_fuel] = "wood"
    heating_systems_values[0][:heating_efficiency_afue] = 0.8
    heating_systems_values[0][:electric_auxiliary_energy] = 200
  elsif ['base-hvac-furnace-x3-dse.xml'].include? hpxml_file
    heating_systems_values << heating_systems_values[0].dup
    heating_systems_values << heating_systems_values[1].dup
    heating_systems_values[1][:id] = "HeatingSystem2"
    heating_systems_values[1][:distribution_system_idref] = "HVACDistribution2"
    heating_systems_values[2][:id] = "HeatingSystem3"
    heating_systems_values[2][:distribution_system_idref] = "HVACDistribution3"
    for i in 0..2
      heating_systems_values[i][:heating_capacity] /= 3.0
      heating_systems_values[i][:fraction_heat_load_served] = 0.333
    end
  elsif ['invalid_files/unattached-hvac-distribution.xml'].include? hpxml_file
    heating_systems_values[0][:distribution_system_idref] = "foobar"
  elsif ['invalid_files/hvac-invalid-distribution-system-type.xml'].include? hpxml_file
    heating_systems_values[0][:distribution_system_idref] = "HVACDistribution2"
  elsif ['invalid_files/hvac-dse-multiple-attached-heating.xml'].include? hpxml_file
    heating_systems_values[0][:fraction_heat_load_served] = 0.5
    heating_systems_values << heating_systems_values[0].dup
    heating_systems_values[1][:id] += "2"
  elsif ['base-hvac-undersized.xml'].include? hpxml_file
    heating_systems_values[0][:heating_capacity] /= 10.0
  elsif ['base-hvac-flowrate.xml'].include? hpxml_file
    heating_systems_values[0][:heating_cfm] = heating_systems_values[0][:heating_capacity] * 360.0 / 12000.0
  elsif hpxml_file.include? 'hvac_autosizing' and not heating_systems_values.nil? and heating_systems_values.size > 0
    heating_systems_values[0][:heating_capacity] = -1
  elsif hpxml_file.include? '-zero-heat.xml' and not heating_systems_values.nil? and heating_systems_values.size > 0
    heating_systems_values[0][:fraction_heat_load_served] = 0
    heating_systems_values[0][:heating_capacity] = 0
  elsif hpxml_file.include? 'hvac_multiple' and not heating_systems_values.nil? and heating_systems_values.size > 0
    heating_systems_values[0][:heating_capacity] /= 3.0
    heating_systems_values[0][:fraction_heat_load_served] = 0.333
    heating_systems_values[0][:electric_auxiliary_energy] /= 3.0 unless heating_systems_values[0][:electric_auxiliary_energy].nil?
    heating_systems_values << heating_systems_values[0].dup
    heating_systems_values[1][:id] = "SpaceHeat_ID2"
    heating_systems_values[1][:distribution_system_idref] = "HVACDistribution2" unless heating_systems_values[1][:distribution_system_idref].nil?
    heating_systems_values << heating_systems_values[0].dup
    heating_systems_values[2][:id] = "SpaceHeat_ID3"
    heating_systems_values[2][:distribution_system_idref] = "HVACDistribution3" unless heating_systems_values[2][:distribution_system_idref].nil?
  elsif hpxml_file.include? 'hvac_partial' and not heating_systems_values.nil? and heating_systems_values.size > 0
    heating_systems_values[0][:heating_capacity] /= 3.0
    heating_systems_values[0][:fraction_heat_load_served] = 0.333
    heating_systems_values[0][:electric_auxiliary_energy] /= 3.0 unless heating_systems_values[0][:electric_auxiliary_energy].nil?
  end
  return heating_systems_values
end

def get_hpxml_file_cooling_systems_values(hpxml_file, cooling_systems_values)
  if ['base.xml'].include? hpxml_file
    cooling_systems_values = [{ :id => "CoolingSystem",
                                :distribution_system_idref => "HVACDistribution",
                                :cooling_system_type => "central air conditioner",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 48000,
                                :fraction_cool_load_served => 1,
                                :cooling_efficiency_seer => 13 }]
  elsif ['base-hvac-air-to-air-heat-pump-1-speed.xml',
         'base-hvac-air-to-air-heat-pump-2-speed.xml',
         'base-hvac-air-to-air-heat-pump-var-speed.xml',
         'base-hvac-boiler-elec-only.xml',
         'base-hvac-boiler-gas-only.xml',
         'base-hvac-boiler-oil-only.xml',
         'base-hvac-boiler-propane-only.xml',
         'base-hvac-boiler-wood-only.xml',
         'base-hvac-elec-resistance-only.xml',
         'base-hvac-furnace-elec-only.xml',
         'base-hvac-furnace-gas-only.xml',
         'base-hvac-furnace-oil-only.xml',
         'base-hvac-furnace-propane-only.xml',
         'base-hvac-furnace-wood-only.xml',
         'base-hvac-ground-to-air-heat-pump.xml',
         'base-hvac-mini-split-heat-pump-ducted.xml',
         'base-hvac-mini-split-heat-pump-ductless-no-backup.xml',
         'base-hvac-ideal-air.xml',
         'base-hvac-none.xml',
         'base-hvac-stove-oil-only.xml',
         'base-hvac-stove-wood-only.xml',
         'base-hvac-wall-furnace-elec-only.xml',
         'base-hvac-wall-furnace-propane-only.xml',
         'base-hvac-wall-furnace-wood-only.xml'].include? hpxml_file
    cooling_systems_values = []
  elsif ['base-hvac-central-ac-only-1-speed-detailed.xml',
         'base-hvac-central-ac-only-2-speed-detailed.xml',
         'base-hvac-central-ac-only-var-speed-detailed.xml',
         'base-hvac-room-ac-only-detailed.xml'].include? hpxml_file
    cooling_systems_values[0][:cooling_shr] = 0.7
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.xml'].include? hpxml_file
    cooling_systems_values[0][:distribution_system_idref] = "HVACDistribution2"
  elsif ['base-hvac-furnace-gas-central-ac-2-speed.xml',
         'base-hvac-central-ac-only-2-speed.xml'].include? hpxml_file
    cooling_systems_values[0][:cooling_efficiency_seer] = 18
  elsif ['base-hvac-furnace-gas-central-ac-var-speed.xml',
         'base-hvac-central-ac-only-var-speed.xml'].include? hpxml_file
    cooling_systems_values[0][:cooling_efficiency_seer] = 24
  elsif ['base-hvac-furnace-gas-room-ac.xml',
         'base-hvac-room-ac-only.xml'].include? hpxml_file
    cooling_systems_values[0][:distribution_system_idref] = nil
    cooling_systems_values[0][:cooling_system_type] = "room air conditioner"
    cooling_systems_values[0][:cooling_efficiency_seer] = nil
    cooling_systems_values[0][:cooling_efficiency_eer] = 8.5
  elsif ['base-hvac-evap-cooler-only-ducted.xml',
         'base-hvac-evap-cooler-furnace-gas.xml',
         'base-hvac-evap-cooler-only.xml',
         'hvac_autosizing/base-hvac-evap-cooler-furnace-gas-autosize.xml'].include? hpxml_file
    cooling_systems_values[0][:cooling_system_type] = "evaporative cooler"
    cooling_systems_values[0][:cooling_efficiency_seer] = nil
    cooling_systems_values[0][:cooling_efficiency_eer] = nil
    cooling_systems_values[0][:cooling_capacity] = nil
    if ['base-hvac-evap-cooler-furnace-gas.xml',
        'hvac_autosizing/base-hvac-evap-cooler-furnace-gas-autosize.xml',
        'base-hvac-evap-cooler-only.xml'].include? hpxml_file
      cooling_systems_values[0][:distribution_system_idref] = nil
    end
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    cooling_systems_values[0][:distribution_system_idref] = "HVACDistribution4"
    cooling_systems_values[0][:fraction_cool_load_served] = 0.2
    cooling_systems_values[0][:cooling_capacity] *= 0.2
    cooling_systems_values << { :id => "CoolingSystem2",
                                :cooling_system_type => "room air conditioner",
                                :cooling_system_fuel => "electricity",
                                :cooling_capacity => 9600,
                                :fraction_cool_load_served => 0.2,
                                :cooling_efficiency_eer => 8.5 }
  elsif ['invalid_files/hvac-frac-load-served.xml'].include? hpxml_file
    cooling_systems_values[0][:fraction_cool_load_served] += 0.2
  elsif ['invalid_files/hvac-dse-multiple-attached-cooling.xml'].include? hpxml_file
    cooling_systems_values[0][:fraction_cool_load_served] = 0.5
    cooling_systems_values << cooling_systems_values[0].dup
    cooling_systems_values[1][:id] += "2"
  elsif ['base-hvac-undersized.xml'].include? hpxml_file
    cooling_systems_values[0][:cooling_capacity] /= 10.0
  elsif ['base-hvac-flowrate.xml'].include? hpxml_file
    cooling_systems_values[0][:cooling_cfm] = cooling_systems_values[0][:cooling_capacity] * 360.0 / 12000.0
  elsif hpxml_file.include? 'hvac_autosizing' and not cooling_systems_values.nil? and cooling_systems_values.size > 0
    cooling_systems_values[0][:cooling_capacity] = -1
  elsif hpxml_file.include? '-zero-cool.xml' and not cooling_systems_values.nil? and cooling_systems_values.size > 0
    cooling_systems_values[0][:fraction_cool_load_served] = 0
    cooling_systems_values[0][:cooling_capacity] = 0
  elsif hpxml_file.include? 'hvac_multiple' and not cooling_systems_values.nil? and cooling_systems_values.size > 0
    cooling_systems_values[0][:cooling_capacity] /= 3.0 unless cooling_systems_values[0][:cooling_capacity].nil?
    cooling_systems_values[0][:fraction_cool_load_served] = 0.333
    cooling_systems_values << cooling_systems_values[0].dup
    cooling_systems_values[1][:id] = "SpaceCool_ID2"
    cooling_systems_values[1][:distribution_system_idref] = "HVACDistribution2" unless cooling_systems_values[1][:distribution_system_idref].nil?
    cooling_systems_values << cooling_systems_values[0].dup
    cooling_systems_values[2][:id] = "SpaceCool_ID3"
    cooling_systems_values[2][:distribution_system_idref] = "HVACDistribution3" unless cooling_systems_values[2][:distribution_system_idref].nil?
  elsif hpxml_file.include? 'hvac_partial' and not cooling_systems_values.nil? and cooling_systems_values.size > 0
    cooling_systems_values[0][:cooling_capacity] /= 3.0 unless cooling_systems_values[0][:cooling_capacity].nil?
    cooling_systems_values[0][:fraction_cool_load_served] = 0.333
  end
  return cooling_systems_values
end

def get_hpxml_file_heat_pumps_values(hpxml_file, heat_pumps_values)
  if ['base-hvac-air-to-air-heat-pump-1-speed.xml',
      'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml'].include? hpxml_file
    heat_pumps_values << { :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :heating_capacity => 42000,
                           :cooling_capacity => 48000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 34121,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 7.7,
                           :cooling_efficiency_seer => 13 }
    if hpxml_file == 'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml'
      heat_pumps_values[0][:fraction_cool_load_served] = 0
    end
  elsif ['base-hvac-air-to-air-heat-pump-2-speed.xml'].include? hpxml_file
    heat_pumps_values << { :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :heating_capacity => 42000,
                           :cooling_capacity => 48000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 34121,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 9.3,
                           :cooling_efficiency_seer => 18 }
  elsif ['base-hvac-air-to-air-heat-pump-var-speed.xml'].include? hpxml_file
    heat_pumps_values << { :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :heating_capacity => 42000,
                           :cooling_capacity => 48000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 34121,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 10,
                           :cooling_efficiency_seer => 22 }
  elsif ['base-hvac-ground-to-air-heat-pump.xml'].include? hpxml_file
    heat_pumps_values << { :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "ground-to-air",
                           :heat_pump_fuel => "electricity",
                           :heating_capacity => 42000,
                           :cooling_capacity => 48000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 34121,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_cop => 3.6,
                           :cooling_efficiency_eer => 16.6 }
  elsif ['base-hvac-mini-split-heat-pump-ducted.xml'].include? hpxml_file
    heat_pumps_values << { :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution",
                           :heat_pump_type => "mini-split",
                           :heat_pump_fuel => "electricity",
                           :heating_capacity => 52000,
                           :cooling_capacity => 48000,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 34121,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 1,
                           :fraction_cool_load_served => 1,
                           :heating_efficiency_hspf => 10,
                           :cooling_efficiency_seer => 19 }
  elsif ['base-hvac-mini-split-heat-pump-ductless.xml'].include? hpxml_file
    heat_pumps_values[0][:distribution_system_idref] = nil
  elsif ['base-hvac-mini-split-heat-pump-ductless-no-backup.xml'].include? hpxml_file
    heat_pumps_values[0][:backup_heating_fuel] = nil
  elsif ['invalid_files/heat-pump-mixed-fixed-and-autosize-capacities.xml'].include? hpxml_file
    heat_pumps_values[0][:heating_capacity] = -1
  elsif ['invalid_files/heat-pump-mixed-fixed-and-autosize-capacities2.xml'].include? hpxml_file
    heat_pumps_values[0][:cooling_capacity] = -1
  elsif ['invalid_files/heat-pump-mixed-fixed-and-autosize-capacities3.xml'].include? hpxml_file
    heat_pumps_values[0][:cooling_capacity] = -1
    heat_pumps_values[0][:heating_capacity] = -1
    heat_pumps_values[0][:heating_capacity_17F] = 25000
  elsif ['invalid_files/heat-pump-mixed-fixed-and-autosize-capacities4.xml'].include? hpxml_file
    heat_pumps_values[0][:backup_heating_capacity] = -1
  elsif ['base-hvac-air-to-air-heat-pump-1-speed-detailed.xml'].include? hpxml_file
    heat_pumps_values[0][:heating_capacity_17F] = heat_pumps_values[0][:heating_capacity] * 0.630 # Based on OAT slope of default curves
    heat_pumps_values[0][:cooling_shr] = 0.7
  elsif ['base-hvac-air-to-air-heat-pump-2-speed-detailed.xml'].include? hpxml_file
    heat_pumps_values[0][:heating_capacity_17F] = heat_pumps_values[0][:heating_capacity] * 0.590 # Based on OAT slope of default curves
    heat_pumps_values[0][:cooling_shr] = 0.7
  elsif ['base-hvac-air-to-air-heat-pump-var-speed-detailed.xml'].include? hpxml_file
    heat_pumps_values[0][:heating_capacity_17F] = heat_pumps_values[0][:heating_capacity] * 0.640 # Based on OAT slope of default curves
    heat_pumps_values[0][:cooling_shr] = 0.7
  elsif ['base-hvac-mini-split-heat-pump-ducted-detailed.xml'].include? hpxml_file
    f = 1.0 - (1.0 - 0.25) / (47.0 + 5.0) * (47.0 - 17.0)
    heat_pumps_values[0][:heating_capacity_17F] = heat_pumps_values[0][:heating_capacity] * f
    heat_pumps_values[0][:cooling_shr] = 0.7
  elsif ['base-hvac-ground-to-air-heat-pump-detailed.xml'].include? hpxml_file
    heat_pumps_values[0][:cooling_shr] = 0.7
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    heat_pumps_values << { :id => "HeatPump",
                           :distribution_system_idref => "HVACDistribution5",
                           :heat_pump_type => "air-to-air",
                           :heat_pump_fuel => "electricity",
                           :heating_capacity => 4800,
                           :cooling_capacity => 4800,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 3412,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 0.1,
                           :fraction_cool_load_served => 0.2,
                           :heating_efficiency_hspf => 7.7,
                           :cooling_efficiency_seer => 13 }
    heat_pumps_values << { :id => "HeatPump2",
                           :distribution_system_idref => "HVACDistribution6",
                           :heat_pump_type => "ground-to-air",
                           :heat_pump_fuel => "electricity",
                           :heating_capacity => 4800,
                           :cooling_capacity => 4800,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 3412,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 0.1,
                           :fraction_cool_load_served => 0.2,
                           :heating_efficiency_cop => 3.6,
                           :cooling_efficiency_eer => 16.6 }
    heat_pumps_values << { :id => "HeatPump3",
                           :heat_pump_type => "mini-split",
                           :heat_pump_fuel => "electricity",
                           :heating_capacity => 4800,
                           :cooling_capacity => 4800,
                           :backup_heating_fuel => "electricity",
                           :backup_heating_capacity => 3412,
                           :backup_heating_efficiency_percent => 1.0,
                           :fraction_heat_load_served => 0.1,
                           :fraction_cool_load_served => 0.2,
                           :heating_efficiency_hspf => 10,
                           :cooling_efficiency_seer => 19 }
  elsif ['invalid_files/hvac-distribution-multiple-attached-heating.xml'].include? hpxml_file
    heat_pumps_values[0][:distribution_system_idref] = "HVACDistribution3"
  elsif ['invalid_files/hvac-distribution-multiple-attached-cooling.xml'].include? hpxml_file
    heat_pumps_values[0][:distribution_system_idref] = "HVACDistribution4"
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
         'base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.xml',
         'base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.xml',
         'base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml'].include? hpxml_file
    heat_pumps_values[0][:backup_heating_fuel] = "natural gas"
    heat_pumps_values[0][:backup_heating_capacity] = 36000
    heat_pumps_values[0][:backup_heating_efficiency_percent] = nil
    heat_pumps_values[0][:backup_heating_efficiency_afue] = 0.95
    heat_pumps_values[0][:backup_heating_switchover_temp] = 25
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-oil.xml'].include? hpxml_file
    heat_pumps_values[0][:backup_heating_fuel] = "fuel oil"
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml'].include? hpxml_file
    heat_pumps_values[0][:backup_heating_fuel] = "electricity"
    heat_pumps_values[0][:backup_heating_efficiency_afue] = 1.0
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-propane.xml'].include? hpxml_file
    heat_pumps_values[0][:backup_heating_fuel] = "propane"
  elsif hpxml_file.include? 'hvac_autosizing' and not heat_pumps_values.nil? and heat_pumps_values.size > 0
    heat_pumps_values[0][:cooling_capacity] = -1
    heat_pumps_values[0][:heating_capacity] = -1
    heat_pumps_values[0][:backup_heating_capacity] = -1
  elsif hpxml_file.include? '-zero-heat.xml' and not heat_pumps_values.nil? and heat_pumps_values.size > 0
    heat_pumps_values[0][:fraction_heat_load_served] = 0
    heat_pumps_values[0][:heating_capacity] = 0
    heat_pumps_values[0][:backup_heating_capacity] = 0
  elsif hpxml_file.include? '-zero-cool.xml' and not heat_pumps_values.nil? and heat_pumps_values.size > 0
    heat_pumps_values[0][:fraction_cool_load_served] = 0
    heat_pumps_values[0][:cooling_capacity] = 0
  elsif hpxml_file.include? 'hvac_multiple' and not heat_pumps_values.nil? and heat_pumps_values.size > 0
    heat_pumps_values[0][:cooling_capacity] /= 3.0
    heat_pumps_values[0][:heating_capacity] /= 3.0
    heat_pumps_values[0][:backup_heating_capacity] /= 3.0
    heat_pumps_values[0][:fraction_heat_load_served] = 0.333
    heat_pumps_values[0][:fraction_cool_load_served] = 0.333
    heat_pumps_values << heat_pumps_values[0].dup
    heat_pumps_values[1][:id] = "SpaceHeatPump_ID2"
    heat_pumps_values[1][:distribution_system_idref] = "HVACDistribution2" unless heat_pumps_values[1][:distribution_system_idref].nil?
    heat_pumps_values << heat_pumps_values[0].dup
    heat_pumps_values[2][:id] = "SpaceHeatPump_ID3"
    heat_pumps_values[2][:distribution_system_idref] = "HVACDistribution3" unless heat_pumps_values[2][:distribution_system_idref].nil?
  elsif hpxml_file.include? 'hvac_partial' and not heat_pumps_values.nil? and heat_pumps_values.size > 0
    heat_pumps_values[0][:cooling_capacity] /= 3.0
    heat_pumps_values[0][:heating_capacity] /= 3.0
    heat_pumps_values[0][:backup_heating_capacity] /= 3.0
    heat_pumps_values[0][:fraction_heat_load_served] = 0.333
    heat_pumps_values[0][:fraction_cool_load_served] = 0.333
  end

  return heat_pumps_values
end

def get_hpxml_file_hvac_control_values(hpxml_file, hvac_control_values)
  if ['base.xml'].include? hpxml_file
    hvac_control_values = { :id => "HVACControl",
                            :control_type => "manual thermostat",
                            :heating_setpoint_temp => 68,
                            :cooling_setpoint_temp => 78 }
  elsif ['base-hvac-none.xml'].include? hpxml_file
    hvac_control_values = {}
  elsif ['base-hvac-programmable-thermostat.xml'].include? hpxml_file
    hvac_control_values[:control_type] = "programmable thermostat"
    hvac_control_values[:heating_setback_temp] = 66
    hvac_control_values[:heating_setback_hours_per_week] = 7 * 7
    hvac_control_values[:heating_setback_start_hour] = 23 # 11pm
    hvac_control_values[:cooling_setup_temp] = 80
    hvac_control_values[:cooling_setup_hours_per_week] = 6 * 7
    hvac_control_values[:cooling_setup_start_hour] = 9 # 9am
  elsif ['base-hvac-setpoints.xml'].include? hpxml_file
    hvac_control_values[:heating_setpoint_temp] = 60
    hvac_control_values[:cooling_setpoint_temp] = 80
  elsif ['base-misc-ceiling-fans.xml'].include? hpxml_file
    hvac_control_values[:ceiling_fan_cooling_setpoint_temp_offset] = 0.5
  end
  return hvac_control_values
end

def get_hpxml_file_hvac_distributions_values(hpxml_file, hvac_distributions_values)
  if ['base.xml'].include? hpxml_file
    hvac_distributions_values = [{ :id => "HVACDistribution",
                                   :distribution_system_type => "AirDistribution" }]
  elsif ['base-hvac-boiler-elec-only.xml',
         'base-hvac-boiler-gas-only.xml',
         'base-hvac-boiler-oil-only.xml',
         'base-hvac-boiler-propane-only.xml',
         'base-hvac-boiler-wood-only.xml'].include? hpxml_file
    hvac_distributions_values[0][:distribution_system_type] = "HydronicDistribution"
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.xml'].include? hpxml_file
    hvac_distributions_values[0][:distribution_system_type] = "HydronicDistribution"
    hvac_distributions_values << { :id => "HVACDistribution2",
                                   :distribution_system_type => "AirDistribution" }
  elsif ['invalid_files/hvac-invalid-distribution-system-type.xml'].include? hpxml_file
    hvac_distributions_values << { :id => "HVACDistribution2",
                                   :distribution_system_type => "HydronicDistribution" }
  elsif ['base-hvac-none.xml',
         'base-hvac-elec-resistance-only.xml',
         'base-hvac-evap-cooler-only.xml',
         'base-hvac-ideal-air.xml',
         'base-hvac-mini-split-heat-pump-ductless.xml',
         'base-hvac-room-ac-only.xml',
         'base-hvac-stove-oil-only.xml',
         'base-hvac-stove-wood-only.xml',
         'base-hvac-wall-furnace-elec-only.xml',
         'base-hvac-wall-furnace-propane-only.xml',
         'base-hvac-wall-furnace-wood-only.xml'].include? hpxml_file
    hvac_distributions_values = []
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    hvac_distributions_values[0][:distribution_system_type] = "HydronicDistribution"
    hvac_distributions_values << { :id => "HVACDistribution2",
                                   :distribution_system_type => "HydronicDistribution" }
    hvac_distributions_values << { :id => "HVACDistribution3",
                                   :distribution_system_type => "AirDistribution" }
    hvac_distributions_values << { :id => "HVACDistribution4",
                                   :distribution_system_type => "AirDistribution" }
    hvac_distributions_values << { :id => "HVACDistribution5",
                                   :distribution_system_type => "AirDistribution" }
    hvac_distributions_values << { :id => "HVACDistribution6",
                                   :distribution_system_type => "AirDistribution" }
  elsif ['base-hvac-dse.xml',
         'base-dhw-indirect-dse.xml'].include? hpxml_file
    hvac_distributions_values[0][:distribution_system_type] = "DSE"
    hvac_distributions_values[0][:annual_heating_dse] = 0.8
    hvac_distributions_values[0][:annual_cooling_dse] = 0.7
  elsif ['base-hvac-furnace-x3-dse.xml'].include? hpxml_file
    hvac_distributions_values[0][:distribution_system_type] = "DSE"
    hvac_distributions_values[0][:annual_heating_dse] = 0.8
    hvac_distributions_values[0][:annual_cooling_dse] = 0.7
    hvac_distributions_values << hvac_distributions_values[0].dup
    hvac_distributions_values[1][:id] = "HVACDistribution2"
    hvac_distributions_values[1][:annual_cooling_dse] = nil
    hvac_distributions_values << hvac_distributions_values[0].dup
    hvac_distributions_values[2][:id] = "HVACDistribution3"
    hvac_distributions_values[2][:annual_cooling_dse] = nil
  elsif hpxml_file.include? 'hvac_multiple' and not hvac_distributions_values.empty?
    hvac_distributions_values << hvac_distributions_values[0].dup
    hvac_distributions_values[1][:id] = "HVACDistribution2"
    hvac_distributions_values << hvac_distributions_values[0].dup
    hvac_distributions_values[2][:id] = "HVACDistribution3"
  end
  return hvac_distributions_values
end

def get_hpxml_file_duct_leakage_measurements_values(hpxml_file, duct_leakage_measurements_values)
  if ['base.xml'].include? hpxml_file
    duct_leakage_measurements_values = [[{ :duct_type => "supply",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 75 },
                                         { :duct_type => "return",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 25 }]]
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.xml'].include? hpxml_file
    duct_leakage_measurements_values[0] = []
    duct_leakage_measurements_values << [{ :duct_type => "supply",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 75 },
                                         { :duct_type => "return",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 25 }]
  elsif ['base-hvac-mini-split-heat-pump-ducted.xml'].include? hpxml_file
    duct_leakage_measurements_values[0][0][:duct_leakage_value] = 15
    duct_leakage_measurements_values[0][1][:duct_leakage_value] = 5
  elsif ['base-hvac-evap-cooler-only-ducted.xml'].include? hpxml_file
    duct_leakage_measurements_values[0].pop
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    duct_leakage_measurements_values[0] = []
    duct_leakage_measurements_values[1] = []
    duct_leakage_measurements_values << [{ :duct_type => "supply",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 75 },
                                         { :duct_type => "return",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 25 }]
    duct_leakage_measurements_values << [{ :duct_type => "supply",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 75 },
                                         { :duct_type => "return",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 25 }]
    duct_leakage_measurements_values << [{ :duct_type => "supply",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 75 },
                                         { :duct_type => "return",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 25 }]
    duct_leakage_measurements_values << [{ :duct_type => "supply",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 75 },
                                         { :duct_type => "return",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => 25 }]
  elsif ['hvac_multiple/base-hvac-air-to-air-heat-pump-1-speed-x3.xml',
         'hvac_multiple/base-hvac-air-to-air-heat-pump-2-speed-x3.xml',
         'hvac_multiple/base-hvac-air-to-air-heat-pump-var-speed-x3.xml',
         'hvac_multiple/base-hvac-central-ac-only-1-speed-x3.xml',
         'hvac_multiple/base-hvac-central-ac-only-2-speed-x3.xml',
         'hvac_multiple/base-hvac-central-ac-only-var-speed-x3.xml',
         'hvac_multiple/base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-x3.xml',
         'hvac_multiple/base-hvac-furnace-gas-only-x3.xml',
         'hvac_multiple/base-hvac-ground-to-air-heat-pump-x3.xml',
         'hvac_multiple/base-hvac-mini-split-heat-pump-ducted-x3.xml'].include? hpxml_file
    duct_leakage_measurements_values[0][0][:duct_leakage_value] = 0.0
    duct_leakage_measurements_values[0][1][:duct_leakage_value] = 0.0
    duct_leakage_measurements_values << [{ :duct_type => "supply",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => duct_leakage_measurements_values[0][0][:duct_leakage_value] },
                                         { :duct_type => "return",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => duct_leakage_measurements_values[0][1][:duct_leakage_value] }]
    duct_leakage_measurements_values << [{ :duct_type => "supply",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => duct_leakage_measurements_values[0][0][:duct_leakage_value] },
                                         { :duct_type => "return",
                                           :duct_leakage_units => "CFM25",
                                           :duct_leakage_value => duct_leakage_measurements_values[0][1][:duct_leakage_value] }]
  elsif (hpxml_file.include? 'hvac_partial' and not duct_leakage_measurements_values.empty?) or
        (hpxml_file.include? 'hvac_base' and not duct_leakage_measurements_values.empty?) or
        ['base-atticroof-conditioned.xml',
         'base-enclosure-adiabatic-surfaces.xml',
         'base-atticroof-cathedral.xml',
         'base-atticroof-conditioned.xml',
         'base-atticroof-flat.xml'].include? hpxml_file
    duct_leakage_measurements_values[0][0][:duct_leakage_value] = 0.0
    duct_leakage_measurements_values[0][1][:duct_leakage_value] = 0.0
  elsif ['base-hvac-ducts-in-conditioned-space.xml'].include? hpxml_file
    # Test leakage to outside when all ducts in conditioned space
    # (e.g., ducts may be in floor cavities which have leaky rims)
    duct_leakage_measurements_values[0][0][:duct_leakage_value] = 1.5
    duct_leakage_measurements_values[0][1][:duct_leakage_value] = 1.5
  elsif ['base-hvac-ducts-leakage-percent.xml'].include? hpxml_file
    duct_leakage_measurements_values = [[{ :duct_type => "supply",
                                           :duct_leakage_units => "Percent",
                                           :duct_leakage_value => 0.1 },
                                         { :duct_type => "return",
                                           :duct_leakage_units => "Percent",
                                           :duct_leakage_value => 0.05 }]]
  elsif ['base-hvac-undersized.xml'].include? hpxml_file
    duct_leakage_measurements_values[0][0][:duct_leakage_value] /= 10.0
    duct_leakage_measurements_values[0][1][:duct_leakage_value] /= 10.0
  end
  return duct_leakage_measurements_values
end

def get_hpxml_file_ducts_values(hpxml_file, ducts_values)
  if ['base.xml'].include? hpxml_file
    ducts_values = [[{ :duct_type => "supply",
                       :duct_insulation_r_value => 4,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 150 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 0,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 50 }]]
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "basement - unconditioned"
    ducts_values[0][1][:duct_location] = "basement - unconditioned"
  elsif ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "crawlspace - unvented"
    ducts_values[0][1][:duct_location] = "crawlspace - unvented"
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "crawlspace - vented"
    ducts_values[0][1][:duct_location] = "crawlspace - vented"
  elsif ['base-atticroof-flat.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "basement - conditioned"
    ducts_values[0][1][:duct_location] = "basement - conditioned"
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "attic - vented"
    ducts_values[0][1][:duct_location] = "attic - vented"
  elsif ['base-atticroof-conditioned.xml',
         'base-enclosure-adiabatic-surfaces.xml',
         'base-hvac-ducts-in-conditioned-space.xml',
         'base-atticroof-cathedral.xml',
         'base-atticroof-conditioned.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "living space"
    ducts_values[0][1][:duct_location] = "living space"
  elsif ['base-enclosure-garage.xml',
         'invalid_files/duct-location.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "garage"
    ducts_values[0][1][:duct_location] = "garage"
  elsif ['invalid_files/duct-location-other.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "unconditioned space"
    ducts_values[0][1][:duct_location] = "unconditioned space"
  elsif ['base-hvac-ducts-outside.xml'].include? hpxml_file
    ducts_values[0][0][:duct_location] = "outside"
    ducts_values[0][1][:duct_location] = "outside"
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.xml'].include? hpxml_file
    ducts_values[0] = []
    ducts_values << [{ :duct_type => "supply",
                       :duct_insulation_r_value => 4,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 150 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 0,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 50 }]
  elsif ['base-hvac-mini-split-heat-pump-ducted.xml'].include? hpxml_file
    ducts_values[0][0][:duct_insulation_r_value] = 0
    ducts_values[0][0][:duct_surface_area] = 30
    ducts_values[0][1][:duct_surface_area] = 10
  elsif ['base-hvac-evap-cooler-only-ducted.xml'].include? hpxml_file
    ducts_values[0].pop
  elsif ['invalid_files/hvac-distribution-return-duct-leakage-missing.xml'].include? hpxml_file
    ducts_values[0] << { :duct_type => "return",
                         :duct_insulation_r_value => 0,
                         :duct_location => "attic - unvented",
                         :duct_surface_area => 50 }
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    ducts_values[0] = []
    ducts_values[1] = []
    ducts_values << [{ :duct_type => "supply",
                       :duct_insulation_r_value => 4,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 150 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 0,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 50 }]
    ducts_values << [{ :duct_type => "supply",
                       :duct_insulation_r_value => 4,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 150 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 0,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 50 }]
    ducts_values << [{ :duct_type => "supply",
                       :duct_insulation_r_value => 4,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 150 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 0,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 50 }]
    ducts_values << [{ :duct_type => "supply",
                       :duct_insulation_r_value => 4,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 150 },
                     { :duct_type => "return",
                       :duct_insulation_r_value => 0,
                       :duct_location => "attic - unvented",
                       :duct_surface_area => 50 }]
  elsif ['base-hvac-ducts-locations.xml'].include? hpxml_file
    ducts_values[0][1][:duct_location] = "attic - unvented"
  elsif ['base-hvac-ducts-multiple.xml'].include? hpxml_file
    ducts_values[0] << { :duct_type => "supply",
                         :duct_insulation_r_value => 8,
                         :duct_location => "attic - unvented",
                         :duct_surface_area => 300 }
    ducts_values[0] << { :duct_type => "supply",
                         :duct_insulation_r_value => 8,
                         :duct_location => "outside",
                         :duct_surface_area => 300 }
    ducts_values[0] << { :duct_type => "return",
                         :duct_insulation_r_value => 4,
                         :duct_location => "attic - unvented",
                         :duct_surface_area => 100 }
    ducts_values[0] << { :duct_type => "return",
                         :duct_insulation_r_value => 4,
                         :duct_location => "outside",
                         :duct_surface_area => 100 }
  elsif (hpxml_file.include? 'hvac_multiple' and not ducts_values.empty?)
    ducts_values = [[], [], []]
  elsif (hpxml_file.include? 'hvac_partial' and not ducts_values.empty?) or
        (hpxml_file.include? 'hvac_base' and not ducts_values.empty?)
    ducts_values = [[]]
  end
  return ducts_values
end

def get_hpxml_file_ventilation_fan_values(hpxml_file, ventilation_fans_values)
  if ['base-mechvent-balanced.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "MechanicalVentilation",
                                 :fan_type => "balanced",
                                 :tested_flow_rate => 110,
                                 :hours_in_operation => 24,
                                 :fan_power => 60,
                                 :used_for_whole_building_ventilation => true }
  elsif ['invalid_files/unattached-cfis.xml',
         'invalid_files/cfis-with-hydronic-distribution.xml',
         'base-mechvent-cfis.xml',
         'cfis/base-cfis.xml',
         'cfis/base-hvac-air-to-air-heat-pump-1-speed-cfis.xml',
         'cfis/base-hvac-air-to-air-heat-pump-2-speed-cfis.xml',
         'cfis/base-hvac-air-to-air-heat-pump-var-speed-cfis.xml',
         'cfis/base-hvac-central-ac-only-1-speed-cfis.xml',
         'cfis/base-hvac-central-ac-only-2-speed-cfis.xml',
         'cfis/base-hvac-central-ac-only-var-speed-cfis.xml',
         'cfis/base-hvac-dse-cfis.xml',
         'cfis/base-hvac-ducts-in-conditioned-space-cfis.xml',
         'cfis/base-hvac-evap-cooler-only-ducted-cfis.xml',
         'cfis/base-hvac-furnace-gas-central-ac-2-speed-cfis.xml',
         'cfis/base-hvac-furnace-gas-central-ac-var-speed-cfis.xml',
         'cfis/base-hvac-furnace-gas-only-cfis.xml',
         'cfis/base-hvac-furnace-gas-room-ac-cfis.xml',
         'cfis/base-hvac-ground-to-air-heat-pump-cfis.xml',
         'cfis/base-hvac-mini-split-heat-pump-ducted-cfis.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "MechanicalVentilation",
                                 :fan_type => "central fan integrated supply",
                                 :tested_flow_rate => 330,
                                 :hours_in_operation => 8,
                                 :fan_power => 300,
                                 :used_for_whole_building_ventilation => true,
                                 :distribution_system_idref => "HVACDistribution" }
    if ['invalid_files/unattached-cfis.xml'].include? hpxml_file
      ventilation_fans_values[0][:distribution_system_idref] = "foobar"
    end
  elsif ['base-mechvent-cfis-24hrs.xml'].include? hpxml_file
    ventilation_fans_values[0][:hours_in_operation] = 24
  elsif ['base-mechvent-erv.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "MechanicalVentilation",
                                 :fan_type => "energy recovery ventilator",
                                 :tested_flow_rate => 110,
                                 :hours_in_operation => 24,
                                 :total_recovery_efficiency => 0.48,
                                 :sensible_recovery_efficiency => 0.72,
                                 :fan_power => 60,
                                 :used_for_whole_building_ventilation => true }
  elsif ['base-mechvent-erv-atre-asre.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "MechanicalVentilation",
                                 :fan_type => "energy recovery ventilator",
                                 :tested_flow_rate => 110,
                                 :hours_in_operation => 24,
                                 :total_recovery_efficiency_adjusted => 0.526,
                                 :sensible_recovery_efficiency_adjusted => 0.79,
                                 :fan_power => 60,
                                 :used_for_whole_building_ventilation => true }
  elsif ['base-mechvent-exhaust.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "MechanicalVentilation",
                                 :fan_type => "exhaust only",
                                 :tested_flow_rate => 110,
                                 :hours_in_operation => 24,
                                 :fan_power => 30,
                                 :used_for_whole_building_ventilation => true }
  elsif ['base-mechvent-exhaust-rated-flow-rate.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "MechanicalVentilation",
                                 :fan_type => "exhaust only",
                                 :rated_flow_rate => 110,
                                 :hours_in_operation => 24,
                                 :fan_power => 30,
                                 :used_for_whole_building_ventilation => true }
  elsif ['base-mechvent-hrv.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "MechanicalVentilation",
                                 :fan_type => "heat recovery ventilator",
                                 :tested_flow_rate => 110,
                                 :hours_in_operation => 24,
                                 :sensible_recovery_efficiency => 0.72,
                                 :fan_power => 60,
                                 :used_for_whole_building_ventilation => true }
  elsif ['base-mechvent-hrv-asre.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "MechanicalVentilation",
                                 :fan_type => "heat recovery ventilator",
                                 :tested_flow_rate => 110,
                                 :hours_in_operation => 24,
                                 :sensible_recovery_efficiency_adjusted => 0.790,
                                 :fan_power => 60,
                                 :used_for_whole_building_ventilation => true }
  elsif ['base-mechvent-supply.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "MechanicalVentilation",
                                 :fan_type => "supply only",
                                 :tested_flow_rate => 110,
                                 :hours_in_operation => 24,
                                 :fan_power => 30,
                                 :used_for_whole_building_ventilation => true }
  elsif ['cfis/base-hvac-boiler-gas-central-ac-1-speed-cfis.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "MechanicalVentilation",
                                 :fan_type => "central fan integrated supply",
                                 :tested_flow_rate => 330,
                                 :hours_in_operation => 8,
                                 :fan_power => 300,
                                 :used_for_whole_building_ventilation => true,
                                 :distribution_system_idref => "HVACDistribution2" }
  elsif ['base-misc-whole-house-fan.xml'].include? hpxml_file
    ventilation_fans_values << { :id => "WholeHouseFan",
                                 :rated_flow_rate => 4500,
                                 :fan_power => 300,
                                 :used_for_seasonal_cooling_load_reduction => true }
  end
  return ventilation_fans_values
end

def get_hpxml_file_water_heating_system_values(hpxml_file, water_heating_systems_values)
  if ['base.xml'].include? hpxml_file
    water_heating_systems_values = [{ :id => "WaterHeater",
                                      :fuel_type => "electricity",
                                      :water_heater_type => "storage water heater",
                                      :location => "living space",
                                      :tank_volume => 40,
                                      :fraction_dhw_load_served => 1,
                                      :heating_capacity => 18767,
                                      :energy_factor => 0.95 }]
  elsif ['base-dhw-multiple.xml'].include? hpxml_file
    water_heating_systems_values[0][:fraction_dhw_load_served] = 0.2
    water_heating_systems_values << { :id => "WaterHeater2",
                                      :fuel_type => "natural gas",
                                      :water_heater_type => "storage water heater",
                                      :location => "living space",
                                      :tank_volume => 50,
                                      :fraction_dhw_load_served => 0.2,
                                      :heating_capacity => 40000,
                                      :energy_factor => 0.59,
                                      :recovery_efficiency => 0.76 }
    water_heating_systems_values << { :id => "WaterHeater3",
                                      :fuel_type => "electricity",
                                      :water_heater_type => "heat pump water heater",
                                      :location => "living space",
                                      :tank_volume => 80,
                                      :fraction_dhw_load_served => 0.2,
                                      :energy_factor => 2.3 }
    water_heating_systems_values << { :id => "WaterHeater4",
                                      :fuel_type => "electricity",
                                      :water_heater_type => "instantaneous water heater",
                                      :location => "living space",
                                      :fraction_dhw_load_served => 0.2,
                                      :energy_factor => 0.99 }
    water_heating_systems_values << { :id => "WaterHeater5",
                                      :fuel_type => "natural gas",
                                      :water_heater_type => "instantaneous water heater",
                                      :location => "living space",
                                      :fraction_dhw_load_served => 0.1,
                                      :energy_factor => 0.82 }
    water_heating_systems_values << { :id => "WaterHeater6",
                                      :water_heater_type => "space-heating boiler with storage tank",
                                      :location => "living space",
                                      :tank_volume => 50,
                                      :fraction_dhw_load_served => 0.1,
                                      :related_hvac => "HeatingSystem" }
  elsif ['invalid_files/dhw-frac-load-served.xml'].include? hpxml_file
    water_heating_systems_values[0][:fraction_dhw_load_served] += 0.15
  elsif ['base-dhw-tank-gas.xml',
         'base-dhw-tank-gas-outside.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "natural gas"
    water_heating_systems_values[0][:tank_volume] = 50
    water_heating_systems_values[0][:heating_capacity] = 40000
    water_heating_systems_values[0][:energy_factor] = 0.59
    water_heating_systems_values[0][:recovery_efficiency] = 0.76
    if hpxml_file == 'base-dhw-tank-gas-outside.xml'
      water_heating_systems_values[0][:location] = "other exterior"
    end
  elsif ['base-dhw-tank-wood.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "wood"
    water_heating_systems_values[0][:tank_volume] = 50
    water_heating_systems_values[0][:heating_capacity] = 40000
    water_heating_systems_values[0][:energy_factor] = 0.59
    water_heating_systems_values[0][:recovery_efficiency] = 0.76
  elsif ['base-dhw-tank-heat-pump.xml',
         'base-dhw-tank-heat-pump-outside.xml'].include? hpxml_file
    water_heating_systems_values[0][:water_heater_type] = "heat pump water heater"
    water_heating_systems_values[0][:tank_volume] = 80
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = 2.3
    if hpxml_file == 'base-dhw-tank-heat-pump-outside.xml'
      water_heating_systems_values[0][:location] = "other exterior"
    end
  elsif ['base-dhw-tankless-electric.xml',
         'base-dhw-tankless-electric-outside.xml'].include? hpxml_file
    water_heating_systems_values[0][:water_heater_type] = "instantaneous water heater"
    water_heating_systems_values[0][:tank_volume] = nil
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = 0.99
    if hpxml_file == 'base-dhw-tankless-electric-outside.xml'
      water_heating_systems_values[0][:location] = "other exterior"
    end
  elsif ['base-dhw-tankless-gas.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "natural gas"
    water_heating_systems_values[0][:water_heater_type] = "instantaneous water heater"
    water_heating_systems_values[0][:tank_volume] = nil
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = 0.82
  elsif ['base-dhw-tankless-oil.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "fuel oil"
    water_heating_systems_values[0][:water_heater_type] = "instantaneous water heater"
    water_heating_systems_values[0][:tank_volume] = nil
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = 0.82
  elsif ['base-dhw-tankless-propane.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "propane"
    water_heating_systems_values[0][:water_heater_type] = "instantaneous water heater"
    water_heating_systems_values[0][:tank_volume] = nil
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = 0.82
  elsif ['base-dhw-tankless-wood.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "wood"
    water_heating_systems_values[0][:water_heater_type] = "instantaneous water heater"
    water_heating_systems_values[0][:tank_volume] = nil
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = 0.82
  elsif ['base-dhw-tank-oil.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "fuel oil"
    water_heating_systems_values[0][:tank_volume] = 50
    water_heating_systems_values[0][:heating_capacity] = 40000
    water_heating_systems_values[0][:energy_factor] = 0.59
    water_heating_systems_values[0][:recovery_efficiency] = 0.76
  elsif ['base-dhw-tank-propane.xml'].include? hpxml_file
    water_heating_systems_values[0][:fuel_type] = "propane"
    water_heating_systems_values[0][:tank_volume] = 50
    water_heating_systems_values[0][:heating_capacity] = 40000
    water_heating_systems_values[0][:energy_factor] = 0.59
    water_heating_systems_values[0][:recovery_efficiency] = 0.76
  elsif ['base-dhw-uef.xml'].include? hpxml_file
    water_heating_systems_values[0][:energy_factor] = nil
    water_heating_systems_values[0][:uniform_energy_factor] = 0.93
  elsif ['base-dhw-desuperheater.xml'].include? hpxml_file
    water_heating_systems_values[0][:uses_desuperheater] = true
    water_heating_systems_values[0][:related_hvac] = "CoolingSystem"
  elsif ['base-dhw-desuperheater-tankless.xml'].include? hpxml_file
    water_heating_systems_values[0][:water_heater_type] = "instantaneous water heater"
    water_heating_systems_values[0][:tank_volume] = nil
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = 0.99
    water_heating_systems_values[0][:uses_desuperheater] = true
    water_heating_systems_values[0][:related_hvac] = "CoolingSystem"
  elsif ['base-dhw-desuperheater-2-speed.xml'].include? hpxml_file
    water_heating_systems_values[0][:uses_desuperheater] = true
    water_heating_systems_values[0][:related_hvac] = "CoolingSystem"
  elsif ['base-dhw-desuperheater-var-speed.xml'].include? hpxml_file
    water_heating_systems_values[0][:uses_desuperheater] = true
    water_heating_systems_values[0][:related_hvac] = "CoolingSystem"
  elsif ['base-dhw-desuperheater-gshp.xml'].include? hpxml_file
    water_heating_systems_values[0][:uses_desuperheater] = true
    water_heating_systems_values[0][:related_hvac] = "HeatPump"
  elsif ['base-dhw-jacket-electric.xml',
         'base-dhw-jacket-indirect.xml',
         'base-dhw-jacket-gas.xml',
         'base-dhw-jacket-hpwh.xml'].include? hpxml_file
    water_heating_systems_values[0][:jacket_r_value] = 10.0
  elsif ['base-dhw-indirect.xml',
         'base-dhw-indirect-outside.xml'].include? hpxml_file
    water_heating_systems_values[0][:water_heater_type] = "space-heating boiler with storage tank"
    water_heating_systems_values[0][:tank_volume] = 50
    water_heating_systems_values[0][:heating_capacity] = nil
    water_heating_systems_values[0][:energy_factor] = nil
    water_heating_systems_values[0][:fuel_type] = nil
    water_heating_systems_values[0][:related_hvac] = "HeatingSystem"
    if hpxml_file == 'base-dhw-indirect-outside.xml'
      water_heating_systems_values[0][:location] = "other exterior"
    end
  elsif ['base-dhw-indirect-standbyloss.xml'].include? hpxml_file
    water_heating_systems_values[0][:standby_loss] = 1.0
  elsif ['base-dhw-combi-tankless.xml',
         'base-dhw-combi-tankless-outside.xml'].include? hpxml_file
    water_heating_systems_values[0][:water_heater_type] = "space-heating boiler with tankless coil"
    water_heating_systems_values[0][:tank_volume] = nil
    if hpxml_file == 'base-dhw-combi-tankless-outside.xml'
      water_heating_systems_values[0][:location] = "other exterior"
    end
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    water_heating_systems_values[0][:location] = "basement - unconditioned"
  elsif ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
    water_heating_systems_values[0][:location] = "crawlspace - unvented"
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    water_heating_systems_values[0][:location] = "crawlspace - vented"
  elsif ['base-foundation-slab.xml'].include? hpxml_file
    water_heating_systems_values[0][:location] = "living space"
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    water_heating_systems_values[0][:location] = "attic - vented"
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    water_heating_systems_values[0][:location] = "basement - conditioned"
  elsif ['invalid_files/water-heater-location.xml'].include? hpxml_file
    water_heating_systems_values[0][:location] = "crawlspace - vented"
  elsif ['invalid_files/water-heater-location-other.xml'].include? hpxml_file
    water_heating_systems_values[0][:location] = "unconditioned space"
  elsif ['invalid_files/invalid-relatedhvac-desuperheater.xml'].include? hpxml_file
    water_heating_systems_values[0][:uses_desuperheater] = true
    water_heating_systems_values[0][:related_hvac] = "CoolingSystem_bad"
  elsif ['invalid_files/repeated-relatedhvac-desuperheater.xml'].include? hpxml_file
    water_heating_systems_values[0][:fraction_dhw_load_served] = 0.5
    water_heating_systems_values[0][:uses_desuperheater] = true
    water_heating_systems_values[0][:related_hvac] = "CoolingSystem"
    water_heating_systems_values << water_heating_systems_values[0].dup
    water_heating_systems_values[1][:id] = "WaterHeater2"
  elsif ['invalid_files/invalid-relatedhvac-dhw-indirect.xml'].include? hpxml_file
    water_heating_systems_values[0][:related_hvac] = "HeatingSystem_bad"
  elsif ['invalid_files/repeated-relatedhvac-dhw-indirect.xml'].include? hpxml_file
    water_heating_systems_values[0][:fraction_dhw_load_served] = 0.5
    water_heating_systems_values << water_heating_systems_values[0].dup
    water_heating_systems_values[1][:id] = "WaterHeater2"
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    water_heating_systems_values[0][:location] = "garage"
  elsif ['base-dhw-none.xml'].include? hpxml_file
    water_heating_systems_values = []
  elsif hpxml_file.include? 'water_heating_multiple' and not water_heating_systems_values.nil? and water_heating_systems_values.size > 0
    if hpxml_file.include? 'combi'
      water_heating_systems_values[0][:water_heater_type] = "space-heating boiler with tankless coil"
      water_heating_systems_values[0][:tank_volume] = nil
      water_heating_systems_values[0][:heating_capacity] = nil
      water_heating_systems_values[0][:energy_factor] = nil
      water_heating_systems_values[0][:fuel_type] = nil
      water_heating_systems_values[0][:related_hvac] = "HeatingSystem"
    end
    water_heating_systems_values[0][:fraction_dhw_load_served] = 0.333
    water_heating_systems_values << water_heating_systems_values[0].dup
    water_heating_systems_values[1][:id] = "WaterHeater2"
    water_heating_systems_values << water_heating_systems_values[0].dup
    water_heating_systems_values[2][:id] = "WaterHeater3"
    if hpxml_file.include? 'combi'
      water_heating_systems_values[1][:related_hvac] = "SpaceHeat_ID2"
      water_heating_systems_values[2][:related_hvac] = "SpaceHeat_ID3"
    end
  end
  return water_heating_systems_values
end

def get_hpxml_file_hot_water_distribution_values(hpxml_file, hot_water_distribution_values)
  if ['base.xml'].include? hpxml_file
    hot_water_distribution_values = { :id => "HotWaterDstribution",
                                      :system_type => "Standard",
                                      :standard_piping_length => 50, # Chosen to test a negative EC_adj
                                      :pipe_r_value => 0.0 }
  elsif ['base-dhw-dwhr.xml'].include? hpxml_file
    hot_water_distribution_values[:dwhr_facilities_connected] = "all"
    hot_water_distribution_values[:dwhr_equal_flow] = true
    hot_water_distribution_values[:dwhr_efficiency] = 0.55
  elsif ['base-dhw-recirc-demand.xml'].include? hpxml_file
    hot_water_distribution_values[:system_type] = "Recirculation"
    hot_water_distribution_values[:recirculation_control_type] = "presence sensor demand control"
    hot_water_distribution_values[:recirculation_piping_length] = 50
    hot_water_distribution_values[:recirculation_branch_piping_length] = 50
    hot_water_distribution_values[:recirculation_pump_power] = 50
    hot_water_distribution_values[:pipe_r_value] = 3
  elsif ['base-dhw-recirc-manual.xml'].include? hpxml_file
    hot_water_distribution_values[:system_type] = "Recirculation"
    hot_water_distribution_values[:recirculation_control_type] = "manual demand control"
    hot_water_distribution_values[:recirculation_piping_length] = 50
    hot_water_distribution_values[:recirculation_branch_piping_length] = 50
    hot_water_distribution_values[:recirculation_pump_power] = 50
    hot_water_distribution_values[:pipe_r_value] = 3
  elsif ['base-dhw-recirc-nocontrol.xml'].include? hpxml_file
    hot_water_distribution_values[:system_type] = "Recirculation"
    hot_water_distribution_values[:recirculation_control_type] = "no control"
    hot_water_distribution_values[:recirculation_piping_length] = 50
    hot_water_distribution_values[:recirculation_branch_piping_length] = 50
    hot_water_distribution_values[:recirculation_pump_power] = 50
  elsif ['base-dhw-recirc-temperature.xml'].include? hpxml_file
    hot_water_distribution_values[:system_type] = "Recirculation"
    hot_water_distribution_values[:recirculation_control_type] = "temperature"
    hot_water_distribution_values[:recirculation_piping_length] = 50
    hot_water_distribution_values[:recirculation_branch_piping_length] = 50
    hot_water_distribution_values[:recirculation_pump_power] = 50
  elsif ['base-dhw-recirc-timer.xml'].include? hpxml_file
    hot_water_distribution_values[:system_type] = "Recirculation"
    hot_water_distribution_values[:recirculation_control_type] = "timer"
    hot_water_distribution_values[:recirculation_piping_length] = 50
    hot_water_distribution_values[:recirculation_branch_piping_length] = 50
    hot_water_distribution_values[:recirculation_pump_power] = 50
  elsif ['base-dhw-none.xml'].include? hpxml_file
    hot_water_distribution_values = {}
  end
  return hot_water_distribution_values
end

def get_hpxml_file_water_fixtures_values(hpxml_file, water_fixtures_values)
  if ['base.xml'].include? hpxml_file
    water_fixtures_values = [{ :id => "WaterFixture",
                               :water_fixture_type => "shower head",
                               :low_flow => true },
                             { :id => "WaterFixture2",
                               :water_fixture_type => "faucet",
                               :low_flow => false }]
  elsif ['base-dhw-low-flow-fixtures.xml'].include? hpxml_file
    water_fixtures_values[1][:low_flow] = true
  elsif ['base-dhw-none.xml'].include? hpxml_file
    water_fixtures_values = []
  end
  return water_fixtures_values
end

def get_hpxml_file_solar_thermal_system_values(hpxml_file, solar_thermal_system_values)
  if ['base-dhw-solar-fraction.xml',
      'base-dhw-multiple.xml',
      'base-dhw-tank-heat-pump-with-solar-fraction.xml',
      'base-dhw-tankless-gas-with-solar-fraction.xml',
      'invalid_files/solar-thermal-system-with-combi-tankless.xml',
      'invalid_files/solar-thermal-system-with-desuperheater.xml',
      'invalid_files/solar-thermal-system-with-dhw-indirect.xml'].include? hpxml_file
    solar_thermal_system_values = { :id => "SolarThermalSystem",
                                    :system_type => "hot water",
                                    :water_heating_system_idref => "WaterHeater",
                                    :solar_fraction => 0.65 }
  elsif ['base-dhw-solar-direct-flat-plate.xml',
         'base-dhw-solar-indirect-flat-plate.xml',
         'base-dhw-solar-thermosyphon-flat-plate.xml',
         'base-dhw-tank-heat-pump-with-solar.xml',
         'base-dhw-tankless-gas-with-solar.xml'].include? hpxml_file
    solar_thermal_system_values = { :id => "SolarThermalSystem",
                                    :system_type => "hot water",
                                    :collector_area => 40,
                                    :collector_type => "single glazing black",
                                    :collector_azimuth => 180,
                                    :collector_tilt => 20,
                                    :collector_frta => 0.77,
                                    :collector_frul => 0.793,
                                    :storage_volume => 60,
                                    :water_heating_system_idref => "WaterHeater" }
    if hpxml_file == 'base-dhw-solar-direct-flat-plate.xml'
      solar_thermal_system_values[:collector_loop_type] = "liquid direct"
    elsif hpxml_file == 'base-dhw-solar-thermosyphon-flat-plate.xml'
      solar_thermal_system_values[:collector_loop_type] = "passive thermosyphon"
    else
      solar_thermal_system_values[:collector_loop_type] = "liquid indirect"
    end
  elsif ['base-dhw-solar-indirect-evacuated-tube.xml',
         'base-dhw-solar-direct-evacuated-tube.xml',
         'base-dhw-solar-thermosyphon-evacuated-tube.xml'].include? hpxml_file
    solar_thermal_system_values = { :id => "SolarThermalSystem",
                                    :system_type => "hot water",
                                    :collector_area => 40,
                                    :collector_type => "evacuated tube",
                                    :collector_azimuth => 180,
                                    :collector_tilt => 20,
                                    :collector_frta => 0.50,
                                    :collector_frul => 0.2799,
                                    :storage_volume => 60,
                                    :water_heating_system_idref => "WaterHeater" }
    if hpxml_file == 'base-dhw-solar-direct-evacuated-tube.xml'
      solar_thermal_system_values[:collector_loop_type] = "liquid direct"
    elsif hpxml_file == 'base-dhw-solar-thermosyphon-evacuated-tube.xml'
      solar_thermal_system_values[:collector_loop_type] = "passive thermosyphon"
    else
      solar_thermal_system_values[:collector_loop_type] = "liquid indirect"
    end
  elsif ['base-dhw-solar-direct-ics.xml',
         'base-dhw-solar-thermosyphon-ics.xml'].include? hpxml_file
    solar_thermal_system_values = { :id => "SolarThermalSystem",
                                    :system_type => "hot water",
                                    :collector_area => 40,
                                    :collector_type => "integrated collector storage",
                                    :collector_azimuth => 180,
                                    :collector_tilt => 20,
                                    :collector_frta => 0.77,
                                    :collector_frul => 0.793,
                                    :storage_volume => 60,
                                    :water_heating_system_idref => "WaterHeater" }
    if hpxml_file == 'base-dhw-solar-direct-ics.xml'
      solar_thermal_system_values[:collector_loop_type] = "liquid direct"
    elsif hpxml_file == 'base-dhw-solar-thermosyphon-ics.xml'
      solar_thermal_system_values[:collector_loop_type] = "passive thermosyphon"
    end
  elsif ['invalid_files/unattached-solar-thermal-system.xml'].include? hpxml_file
    solar_thermal_system_values[:water_heating_system_idref] = "foobar"
  end
  return solar_thermal_system_values
end

def get_hpxml_file_pv_system_values(hpxml_file, pv_systems_values)
  if ['base-pv.xml'].include? hpxml_file
    pv_systems_values << { :id => "PVSystem",
                           :module_type => "standard",
                           :location => "roof",
                           :tracking => "fixed",
                           :array_azimuth => 180,
                           :array_tilt => 20,
                           :max_power_output => 4000,
                           :inverter_efficiency => 0.96,
                           :system_losses_fraction => 0.14 }
    pv_systems_values << { :id => "PVSystem2",
                           :module_type => "premium",
                           :location => "roof",
                           :tracking => "fixed",
                           :array_azimuth => 90,
                           :array_tilt => 20,
                           :max_power_output => 1500,
                           :inverter_efficiency => 0.96,
                           :system_losses_fraction => 0.14 }
  end
  return pv_systems_values
end

def get_hpxml_file_clothes_washer_values(hpxml_file, clothes_washer_values)
  if ['base.xml'].include? hpxml_file
    clothes_washer_values = { :id => "ClothesWasher",
                              :location => "living space",
                              :modified_energy_factor => 0.8,
                              :rated_annual_kwh => 700.0,
                              :label_electric_rate => 0.10,
                              :label_gas_rate => 0.60,
                              :label_annual_gas_cost => 25.0,
                              :capacity => 3.0 }
  elsif ['base-appliances-none.xml'].include? hpxml_file
    clothes_washer_values = {}
  elsif ['base-appliances-washer-imef.xml'].include? hpxml_file
    clothes_washer_values[:modified_energy_factor] = nil
    clothes_washer_values[:integrated_modified_energy_factor] = 0.73
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    clothes_washer_values[:location] = "basement - unconditioned"
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    clothes_washer_values[:location] = "basement - conditioned"
  elsif ['base-enclosure-garage.xml',
         'invalid_files/clothes-washer-location.xml'].include? hpxml_file
    clothes_washer_values[:location] = "garage"
  elsif ['invalid_files/clothes-washer-location-other.xml'].include? hpxml_file
    clothes_washer_values[:location] = "other"
  end
  return clothes_washer_values
end

def get_hpxml_file_clothes_dryer_values(hpxml_file, clothes_dryer_values)
  if ['base.xml'].include? hpxml_file
    clothes_dryer_values = { :id => "ClothesDryer",
                             :location => "living space",
                             :fuel_type => "electricity",
                             :energy_factor => 2.95,
                             :control_type => "timer" }
  elsif ['base-appliances-none.xml'].include? hpxml_file
    clothes_dryer_values = {}
  elsif ['base-appliances-dryer-cef.xml'].include? hpxml_file
    clothes_dryer_values = { :id => "ClothesDryer",
                             :location => "living space",
                             :fuel_type => "electricity",
                             :combined_energy_factor => 2.62,
                             :control_type => "moisture" }
  elsif ['base-appliances-gas.xml',
         'base-appliances-propane.xml',
         'base-appliances-oil.xml'].include? hpxml_file
    clothes_dryer_values = { :id => "ClothesDryer",
                             :location => "living space",
                             :energy_factor => 2.67,
                             :control_type => "moisture" }
    if hpxml_file == 'base-appliances-gas.xml'
      clothes_dryer_values[:fuel_type] = "natural gas"
    elsif hpxml_file == 'base-appliances-propane.xml'
      clothes_dryer_values[:fuel_type] = "propane"
    elsif hpxml_file == 'base-appliances-oil.xml'
      clothes_dryer_values[:fuel_type] = "fuel oil"
    end
  elsif ['base-appliances-wood.xml'].include? hpxml_file
    clothes_dryer_values = { :id => "ClothesDryer",
                             :location => "living space",
                             :fuel_type => "wood",
                             :energy_factor => 2.67,
                             :control_type => "moisture" }
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    clothes_dryer_values[:location] = "basement - unconditioned"
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    clothes_dryer_values[:location] = "basement - conditioned"
  elsif ['base-enclosure-garage.xml',
         'invalid_files/clothes-dryer-location.xml'].include? hpxml_file
    clothes_dryer_values[:location] = "garage"
  elsif ['invalid_files/clothes-dryer-location-other.xml'].include? hpxml_file
    clothes_dryer_values[:location] = "other"
  end
  return clothes_dryer_values
end

def get_hpxml_file_dishwasher_values(hpxml_file, dishwasher_values)
  if ['base.xml'].include? hpxml_file
    dishwasher_values = { :id => "Dishwasher",
                          :rated_annual_kwh => 450,
                          :place_setting_capacity => 12 }
  elsif ['base-appliances-none.xml'].include? hpxml_file
    dishwasher_values = {}
  elsif ['base-appliances-dishwasher-ef.xml'].include? hpxml_file
    dishwasher_values = { :id => "Dishwasher",
                          :energy_factor => 0.5,
                          :place_setting_capacity => 12 }
  end
  return dishwasher_values
end

def get_hpxml_file_refrigerator_values(hpxml_file, refrigerator_values)
  if ['base.xml'].include? hpxml_file
    refrigerator_values = { :id => "Refrigerator",
                            :location => "living space",
                            :rated_annual_kwh => 650 }
  elsif ['base-appliances-refrigerator-adjusted.xml'].include? hpxml_file
    refrigerator_values[:adjusted_annual_kwh] = 600
  elsif ['base-appliances-none.xml'].include? hpxml_file
    refrigerator_values = {}
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    refrigerator_values[:location] = "basement - unconditioned"
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    refrigerator_values[:location] = "basement - conditioned"
  elsif ['base-enclosure-garage.xml',
         'invalid_files/refrigerator-location.xml'].include? hpxml_file
    refrigerator_values[:location] = "garage"
  elsif ['invalid_files/refrigerator-location-other.xml'].include? hpxml_file
    refrigerator_values[:location] = "other"
  end
  return refrigerator_values
end

def get_hpxml_file_cooking_range_values(hpxml_file, cooking_range_values)
  if ['base.xml'].include? hpxml_file
    cooking_range_values = { :id => "Range",
                             :fuel_type => "electricity",
                             :is_induction => false }
  elsif ['base-appliances-none.xml'].include? hpxml_file
    cooking_range_values = {}
  elsif ['base-appliances-gas.xml'].include? hpxml_file
    cooking_range_values[:fuel_type] = "natural gas"
    cooking_range_values[:is_induction] = false
  elsif ['base-appliances-propane.xml'].include? hpxml_file
    cooking_range_values[:fuel_type] = "propane"
    cooking_range_values[:is_induction] = false
  elsif ['base-appliances-oil.xml'].include? hpxml_file
    cooking_range_values[:fuel_type] = "fuel oil"
  elsif ['base-appliances-wood.xml'].include? hpxml_file
    cooking_range_values[:fuel_type] = "wood"
    cooking_range_values[:is_induction] = false
  end
  return cooking_range_values
end

def get_hpxml_file_oven_values(hpxml_file, oven_values)
  if ['base.xml'].include? hpxml_file
    oven_values = { :id => "Oven",
                    :is_convection => false }
  elsif ['base-appliances-none.xml'].include? hpxml_file
    oven_values = {}
  end
  return oven_values
end

def get_hpxml_file_lighting_values(hpxml_file, lighting_values)
  if ['base.xml'].include? hpxml_file
    lighting_values = { :fraction_tier_i_interior => 0.5,
                        :fraction_tier_i_exterior => 0.5,
                        :fraction_tier_i_garage => 0.5,
                        :fraction_tier_ii_interior => 0.25,
                        :fraction_tier_ii_exterior => 0.25,
                        :fraction_tier_ii_garage => 0.25 }
  elsif ['base-misc-lighting-none.xml'].include? hpxml_file
    lighting_values = {}
  end
  return lighting_values
end

def get_hpxml_file_ceiling_fan_values(hpxml_file, ceiling_fans_values)
  if ['base-misc-ceiling-fans.xml'].include? hpxml_file
    ceiling_fans_values << { :id => "CeilingFan",
                             :efficiency => 100,
                             :quantity => 2 }
  end
  return ceiling_fans_values
end

def get_hpxml_file_plug_loads_values(hpxml_file, plug_loads_values)
  if ['base-misc-loads-detailed.xml'].include? hpxml_file
    plug_loads_values = [{ :id => "PlugLoadMisc",
                           :plug_load_type => "other",
                           :kWh_per_year => 7302,
                           :frac_sensible => 0.82,
                           :frac_latent => 0.18 },
                         { :id => "PlugLoadMisc2",
                           :plug_load_type => "TV other",
                           :kWh_per_year => 400 }]
  else
    plug_loads_values = [{ :id => "PlugLoadMisc",
                           :plug_load_type => "other" },
                         { :id => "PlugLoadMisc2",
                           :plug_load_type => "TV other" }]
  end
  return plug_loads_values
end

def get_hpxml_file_misc_load_schedule_values(hpxml_file, misc_load_schedule_values)
  if ['base-misc-loads-detailed.xml'].include? hpxml_file
    misc_load_schedule_values = { :weekday_fractions => "0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066",
                                  :weekend_fractions => "0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066",
                                  :monthly_multipliers => "1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0" }
  end
  return misc_load_schedule_values
end

def download_epws
  weather_dir = File.join(File.dirname(__FILE__), "weather")

  require 'net/http'
  require 'tempfile'

  tmpfile = Tempfile.new("epw")

  url = URI.parse("http://s3.amazonaws.com/epwweatherfiles/tmy3s-cache-csv.zip")
  http = Net::HTTP.new(url.host, url.port)

  params = { 'User-Agent' => 'curl/7.43.0', 'Accept-Encoding' => 'identity' }
  request = Net::HTTP::Get.new(url.path, params)
  request.content_type = 'application/zip, application/octet-stream'

  http.request request do |response|
    total = response.header["Content-Length"].to_i
    if total == 0
      fail "Did not successfully download zip file."
    end

    size = 0
    progress = 0
    open tmpfile, 'wb' do |io|
      response.read_body do |chunk|
        io.write chunk
        size += chunk.size
        new_progress = (size * 100) / total
        unless new_progress == progress
          puts "Downloading %s (%3d%%) " % [url.path, new_progress]
        end
        progress = new_progress
      end
    end
  end

  puts "Extracting weather files..."
  unzip_file = OpenStudio::UnzipFile.new(tmpfile.path.to_s)
  unzip_file.extractAllFiles(OpenStudio::toPath(weather_dir))

  num_epws_actual = Dir[File.join(weather_dir, "*.epw")].count
  puts "#{num_epws_actual} weather files are available in the weather directory."
  puts "Completed."
  exit!
end

command_list = [:update_measures, :cache_weather, :create_release_zips, :download_weather]

def display_usage(command_list)
  puts "Usage: openstudio #{File.basename(__FILE__)} [COMMAND]\nCommands:\n  " + command_list.join("\n  ")
end

if ARGV.size == 0
  puts "ERROR: Missing command."
  display_usage(command_list)
  exit!
elsif ARGV.size > 1
  puts "ERROR: Too many commands."
  display_usage(command_list)
  exit!
elsif not command_list.include? ARGV[0].to_sym
  puts "ERROR: Invalid command '#{ARGV[0]}'."
  display_usage(command_list)
  exit!
end

if ARGV[0].to_sym == :update_measures
  require 'openstudio'
  require_relative "HPXMLtoOpenStudio/resources/hpxml"
  require_relative "HPXMLtoOpenStudio/resources/constants"
  require 'json'

  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? and ENV['HOME'].start_with? 'U:'
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? and ENV['HOMEDRIVE'].start_with? 'U:'

  # Apply rubocop
  command = "rubocop --auto-correct --format simple --only Layout"
  puts "Applying rubocop style to measures..."
  system(command)

  # Update measures XMLs
  command = "#{OpenStudio.getOpenStudioCLI} measure -t '#{File.dirname(__FILE__)}'"
  puts "Updating measure.xmls..."
  system(command, [:out, :err] => File::NULL)

  create_osws
  create_hpxmls

  puts "Done."
end

if ARGV[0].to_sym == :cache_weather
  require 'openstudio'
  require_relative 'HPXMLtoOpenStudio/resources/weather'

  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  puts "Creating cache *.csv for weather files..."

  Dir["weather/*.epw"].each do |epw|
    next if File.exists? epw.gsub(".epw", ".cache")

    puts "Processing #{epw}..."
    model = OpenStudio::Model::Model.new
    epw_file = OpenStudio::EpwFile.new(epw)
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    weather = WeatherProcess.new(model, runner)
    File.open(epw.gsub(".epw", "-cache.csv"), "wb") do |file|
      weather.dump_to_csv(file)
    end
  end
end

if ARGV[0].to_sym == :download_weather
  download_epws
end

if ARGV[0].to_sym == :create_release_zips
  require 'openstudio'

  files = ["HPXMLtoOpenStudio/measure.*",
           "HPXMLtoOpenStudio/resources/*.*",
           "SimulationOutputReport/measure.*",
           "SimulationOutputReport/resources/*.*",
           "weather/*.*",
           "workflow/*.*"]

  # Only include files under git version control
  command = "git ls-files"
  begin
    git_files = `#{command}`
  rescue
    puts "Command failed: '#{command}'. Perhaps git needs to be installed?"
    exit!
  end

  release_map = { File.join(File.dirname(__FILE__), "release-minimal.zip") => false,
                  File.join(File.dirname(__FILE__), "release-full.zip") => true }

  release_map.keys.each do |zip_path|
    File.delete(zip_path) if File.exists? zip_path
  end

  # Check if we need to download weather files for the full release zip
  num_epws_expected = File.readlines(File.join("weather", "data.csv")).size - 1
  num_epws_local = 0
  files.each do |f|
    Dir[f].each do |file|
      next unless file.end_with? ".epw"

      num_epws_local += 1
    end
  end

  # Make sure we have the full set of weather files
  if num_epws_local < num_epws_expected
    puts "Fetching all weather files..."
    command = "#{OpenStudio.getOpenStudioCLI} #{__FILE__} download_weather"
    log = `#{command}`
  end

  # Create zip files
  release_map.each do |zip_path, include_all_epws|
    puts "Creating #{zip_path}..."
    zip = OpenStudio::ZipFile.new(zip_path, false)
    files.each do |f|
      Dir[f].each do |file|
        if include_all_epws
          if not git_files.include? file and not file.start_with? "weather"
            next
          end
        else
          if not git_files.include? file
            next
          end
        end

        zip.addFile(file, File.join("OpenStudio-HPXML", file))
      end
    end
    puts "Wrote file at #{zip_path}."
  end

  puts "Done."
end
