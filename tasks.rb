def create_osws
  require 'json'

  this_dir = File.dirname(__FILE__)
  tests_dir = File.join(this_dir, 'BuildResidentialHPXML/tests')

  # Hash of OSW -> Parent OSW
  osws_files = {
    'base.osw' => nil, # single-family detached
    'base-single-family-attached.osw' => 'base.osw',
    'base-multifamily.osw' => 'base.osw',

    'base-appliances-gas.osw' => 'base.osw',
    'base-appliances-modified.osw' => 'base.osw',
    'base-appliances-none.osw' => 'base.osw',
    'base-appliances-oil.osw' => 'base.osw',
    'base-appliances-propane.osw' => 'base.osw',
    'base-appliances-wood.osw' => 'base.osw',

    # 'base-atticroof-cathedral.osw' => 'base.osw', # TODO: conditioned attic ceiling heights are greater than wall height
    # 'base-atticroof-conditioned.osw' => 'base.osw', # TODO: has both conditioned and unconditioned attics
    'base-atticroof-flat.osw' => 'base.osw',
    'base-atticroof-radiant-barrier.osw' => 'base.osw',
    'base-atticroof-unvented-insulated-roof.osw' => 'base.osw',
    'base-atticroof-vented.osw' => 'base.osw',

    'base-dhw-combi-tankless.osw' => 'base.osw',
    'base-dhw-combi-tankless-outside.osw' => 'base.osw',
    # 'base-dhw-desuperheater.osw' => 'base.osw', # Not supporting desuperheater for now
    # 'base-dhw-desuperheater-2-speed.osw' => 'base.osw', # Not supporting desuperheater for now
    # 'base-dhw-desuperheater-gshp.osw' => 'base.osw', # Not supporting desuperheater for now
    # 'base-dhw-desuperheater-tankless.osw' => 'base.osw', # Not supporting desuperheater for now
    # 'base-dhw-desuperheater-var-speed.osw' => 'base.osw', # Not supporting desuperheater for now
    'base-dhw-dwhr.osw' => 'base.osw',
    'base-dhw-indirect.osw' => 'base.osw',
    # 'base-dhw-indirect-dse.osw' => 'base.osw', # Not going to support DSE
    'base-dhw-indirect-outside.osw' => 'base.osw',
    'base-dhw-indirect-standbyloss.osw' => 'base.osw',
    'base-dhw-jacket-electric.osw' => 'base.osw',
    'base-dhw-jacket-gas.osw' => 'base.osw',
    'base-dhw-jacket-hpwh.osw' => 'base.osw',
    'base-dhw-jacket-indirect.osw' => 'base.osw',
    'base-dhw-low-flow-fixtures.osw' => 'base.osw',
    # 'base-dhw-multiple.osw' => 'base.osw',
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
    # 'base-enclosure-2stories-garage.osw' => 'base.osw',
    # 'base-enclosure-adiabatic-surfaces.osw' => 'base.osw',
    'base-enclosure-beds-1.osw' => 'base.osw',
    'base-enclosure-beds-2.osw' => 'base.osw',
    'base-enclosure-beds-4.osw' => 'base.osw',
    'base-enclosure-beds-5.osw' => 'base.osw',
    # 'base-enclosure-garage.osw' => 'base.osw', TODO: should garage attic be of type garage or attic?
    'base-enclosure-infil-cfm50.osw' => 'base.osw',
    # 'base-enclosure-no-natural-ventilation.osw' => 'base.osw',
    'base-enclosure-overhangs.osw' => 'base.osw',
    # 'base-enclosure-skylights.osw' => 'base.osw', # There are no front roof surfaces, but 15.0 ft^2 of skylights were specified.
    # 'base-enclosure-split-surfaces.osw' => 'base.osw',
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
    # 'base-foundation-conditioned-basement-wall-interior-insulation.osw' => 'base.osw',
    # 'base-foundation-multiple.osw' => 'base.osw', # 1 kiva object instead of 2
    'base-foundation-slab.osw' => 'base.osw',
    'base-foundation-unconditioned-basement.osw' => 'base.osw',
    # 'base-foundation-unconditioned-basement-above-grade.osw' => 'base.osw', # TODO: add foundation wall windows
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
    # 'base-hvac-dse.osw' => 'base.osw', # Not going to support DSE
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.osw' => 'base.osw',
    # 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.osw' => 'base.osw', # TODO: change AFUE to Percent
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
    # 'base-hvac-flowrate.osw' => 'base.osw',
    'base-hvac-furnace-elec-only.osw' => 'base.osw',
    'base-hvac-furnace-gas-central-ac-2-speed.osw' => 'base.osw',
    'base-hvac-furnace-gas-central-ac-var-speed.osw' => 'base.osw',
    'base-hvac-furnace-gas-only.osw' => 'base.osw',
    'base-hvac-furnace-gas-only-no-eae.osw' => 'base.osw',
    'base-hvac-furnace-gas-room-ac.osw' => 'base.osw',
    'base-hvac-furnace-oil-only.osw' => 'base.osw',
    'base-hvac-furnace-propane-only.osw' => 'base.osw',
    'base-hvac-furnace-wood-only.osw' => 'base.osw',
    # 'base-hvac-furnace-x3-dse.osw' => 'base.osw', # Not going to support DSE
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
    'base-mechvent-cfis-evap-cooler-only-ducted.osw' => 'base.osw',
    'base-mechvent-erv.osw' => 'base.osw',
    'base-mechvent-erv-atre-asre.osw' => 'base.osw',
    'base-mechvent-exhaust.osw' => 'base.osw',
    # 'base-mechvent-exhaust-rated-flow-rate.osw' => 'base.osw', # TODO: setting all flow rates on TestedFlowRate
    'base-mechvent-hrv.osw' => 'base.osw',
    'base-mechvent-hrv-asre.osw' => 'base.osw',
    'base-mechvent-supply.osw' => 'base.osw',

    'base-misc-ceiling-fans.osw' => 'base.osw',
    'base-misc-lighting-none.osw' => 'base.osw',
    'base-misc-loads-detailed.osw' => 'base.osw',
    'base-misc-number-of-occupants.osw' => 'base.osw',
    'base-misc-timestep-10-mins.osw' => 'base.osw',
    'base-misc-whole-house-fan.osw' => 'base.osw',

    'base-pv.osw' => 'base.osw',

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
    'hvac_partial/base-hvac-wall-furnace-propane-only-33percent.osw' => 'base-hvac-wall-furnace-propane-only.osw',

    'invalid_files/non-electric-heat-pump-water-heater.osw' => 'base.osw'
  }

  puts "Generating #{osws_files.size} OSW files..."

  osws_files.each do |derivative, parent|
    print '.'

    osw_path = File.absolute_path(File.join(tests_dir, derivative))

    begin
      osw_files = [derivative]
      unless parent.nil?
        osw_files.unshift(parent)
      end
      while not parent.nil?
        next unless osws_files.keys.include? parent

        unless osws_files[parent].nil?
          osw_files.unshift(osws_files[parent])
        end
        parent = osws_files[parent]
      end

      workflow = OpenStudio::WorkflowJSON.new
      workflow.setOswPath(osw_path)
      workflow.addMeasurePath('.')
      steps = OpenStudio::WorkflowStepVector.new
      step = OpenStudio::MeasureStep.new('BuildResidentialHPXML')

      osw_files.each do |osw_file|
        step = get_values(osw_file, step)
      end

      steps.push(step)
      workflow.setWorkflowSteps(steps)
      workflow.save

      workflow_hash = JSON.parse(File.read(osw_path))
      workflow_hash.delete('created_at')
      workflow_hash.delete('updated_at')

      File.open(osw_path, 'w') do |f|
        f.write(JSON.pretty_generate(workflow_hash))
      end
    rescue Exception => e
      puts "\n#{e}\n#{e.backtrace.join('\n')}"
      puts "\nError: Did not successfully generate #{derivative}."
      exit!
    end
  end

  puts "\n"

  # Print warnings about extra files
  abs_osw_files = []
  dirs = [nil]
  osws_files.keys.each do |osw_file|
    abs_osw_files << File.absolute_path(File.join(tests_dir, osw_file))
    next unless osw_file.include? '/'

    dirs << osw_file.split('/')[0] + '/'
  end
  dirs.uniq.each do |dir|
    Dir["#{tests_dir}/#{dir}*.osw"].each do |osw|
      next if abs_osw_files.include? File.absolute_path(osw)

      puts "Warning: Extra OSW file found at #{File.absolute_path(osw)}"
    end
  end
end

def get_values(osw_file, step)
  step.setArgument('hpxml_path', "../BuildResidentialHPXML/tests/built_residential_hpxml/#{File.basename(osw_file, '.*')}.xml")

  if ['base.osw'].include? osw_file
    step.setArgument('simulation_control_timestep', 60)
    step.setArgument('weather_station_epw_filename', 'USA_CO_Denver.Intl.AP.725650_TMY3.epw')
    step.setArgument('schedules_output_path', 'BuildResidentialHPXML/tests/run/schedules.csv')
    step.setArgument('unit_type', 'single-family detached')
    step.setArgument('unit_multiplier', 1)
    step.setArgument('cfa', 2700.0)
    step.setArgument('wall_height', 8.0)
    step.setArgument('num_units', 1)
    step.setArgument('num_floors', 1)
    step.setArgument('aspect_ratio', 1.5)
    step.setArgument('level', 'Bottom')
    step.setArgument('horizontal_location', 'Left')
    step.setArgument('corridor_position', 'Double-Loaded Interior')
    step.setArgument('corridor_width', 10.0)
    step.setArgument('inset_width', 0.0)
    step.setArgument('inset_depth', 0.0)
    step.setArgument('inset_position', 'Right')
    step.setArgument('balcony_depth', 0.0)
    step.setArgument('garage_width', 0.0)
    step.setArgument('garage_depth', 20.0)
    step.setArgument('garage_protrusion', 0.0)
    step.setArgument('garage_position', 'Right')
    step.setArgument('foundation_type', HPXML::FoundationTypeBasementConditioned)
    step.setArgument('foundation_height', 8.0)
    step.setArgument('foundation_ceiling_r', 0)
    step.setArgument('foundation_wall_r', 8.9)
    step.setArgument('foundation_wall_distance_to_top', 0.0)
    step.setArgument('foundation_wall_distance_to_bottom', 8.0)
    step.setArgument('foundation_wall_depth_below_grade', 7.0)
    step.setArgument('slab_perimeter_r', 0)
    step.setArgument('slab_perimeter_depth', 0)
    step.setArgument('slab_under_r', 0)
    step.setArgument('slab_under_width', 0)
    step.setArgument('carpet_fraction', 0.0)
    step.setArgument('carpet_r_value', 0.0)
    step.setArgument('attic_type', HPXML::AtticTypeUnvented)
    step.setArgument('attic_floor_conditioned_r', 39.3)
    step.setArgument('attic_floor_unconditioned_r', 2.1)
    step.setArgument('attic_ceiling_r', 2.3)
    step.setArgument('roof_type', 'gable')
    step.setArgument('roof_pitch', '6:12')
    step.setArgument('roof_structure', 'truss, cantilever')
    step.setArgument('roof_ceiling_r', 2.3)
    step.setArgument('roof_solar_absorptance', 0.7)
    step.setArgument('roof_emittance', 0.92)
    step.setArgument('roof_radiant_barrier', false)
    step.setArgument('eaves_depth', 0)
    step.setArgument('num_bedrooms', 3)
    step.setArgument('num_bathrooms', Constants.Auto)
    step.setArgument('num_occupants', Constants.Auto)
    step.setArgument('neighbor_front_distance', 0)
    step.setArgument('neighbor_back_distance', 0)
    step.setArgument('neighbor_left_distance', 0)
    step.setArgument('neighbor_right_distance', 0)
    step.setArgument('neighbor_front_height', 0)
    step.setArgument('neighbor_back_height', 0)
    step.setArgument('neighbor_left_height', 0)
    step.setArgument('neighbor_right_height', 0)
    step.setArgument('orientation', 180.0)
    step.setArgument('wall_type', HPXML::WallTypeWoodStud)
    step.setArgument('wall_conditioned_r', 23)
    step.setArgument('wall_unconditioned_r', 4)
    step.setArgument('wall_solar_absorptance', 0.7)
    step.setArgument('wall_emittance', 0.92)
    step.setArgument('front_wwr', 0)
    step.setArgument('back_wwr', 0)
    step.setArgument('left_wwr', 0)
    step.setArgument('right_wwr', 0)
    step.setArgument('front_window_area', 108.0)
    step.setArgument('back_window_area', 108.0)
    step.setArgument('left_window_area', 72.0)
    step.setArgument('right_window_area', 72.0)
    step.setArgument('window_aspect_ratio', 1.333)
    step.setArgument('window_fraction_of_operable_area', 0.33)
    step.setArgument('window_ufactor', 0.33)
    step.setArgument('window_shgc', 0.45)
    step.setArgument('winter_shading_coefficient_front_facade', 0)
    step.setArgument('summer_shading_coefficient_front_facade', 0)
    step.setArgument('winter_shading_coefficient_back_facade', 0)
    step.setArgument('summer_shading_coefficient_back_facade', 0)
    step.setArgument('winter_shading_coefficient_left_facade', 0)
    step.setArgument('summer_shading_coefficient_left_facade', 0)
    step.setArgument('winter_shading_coefficient_right_facade', 0)
    step.setArgument('summer_shading_coefficient_right_facade', 0)
    step.setArgument('overhangs_front_depth', 0)
    step.setArgument('overhangs_front_distance_to_top_of_window', 0)
    step.setArgument('overhangs_back_depth', 0)
    step.setArgument('overhangs_back_distance_to_top_of_window', 0)
    step.setArgument('overhangs_left_depth', 0)
    step.setArgument('overhangs_left_distance_to_top_of_window', 0)
    step.setArgument('overhangs_right_depth', 0)
    step.setArgument('overhangs_right_distance_to_top_of_window', 0)
    step.setArgument('front_skylight_area', 0)
    step.setArgument('back_skylight_area', 0)
    step.setArgument('left_skylight_area', 0)
    step.setArgument('right_skylight_area', 0)
    step.setArgument('skylight_ufactor', 0.33)
    step.setArgument('skylight_shgc', 0.45)
    step.setArgument('door_area', 40.0)
    step.setArgument('door_rvalue', 4.4)
    step.setArgument('living_air_leakage_units', HPXML::UnitsACH50)
    step.setArgument('living_air_leakage_value', 3)
    step.setArgument('vented_crawlspace_sla', 0.00667)
    step.setArgument('shelter_coefficient', Constants.Auto)
    step.setArgument('heating_system_type', HPXML::HVACTypeFurnace)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeNaturalGas)
    step.setArgument('heating_system_heating_efficiency', 0.92)
    step.setArgument('heating_system_heating_capacity', 64000.0)
    step.setArgument('heating_system_fraction_heat_load_served', 1)
    step.setArgument('heating_system_electric_auxiliary_energy', 0)
    step.setArgument('cooling_system_type', HPXML::HVACTypeCentralAirConditioner)
    step.setArgument('cooling_system_fuel', HPXML::FuelTypeElectricity)
    step.setArgument('cooling_system_cooling_efficiency', 13.0)
    step.setArgument('cooling_system_cooling_capacity', 48000.0)
    step.setArgument('cooling_system_fraction_cool_load_served', 1)
    step.setArgument('heat_pump_type', 'none')
    step.setArgument('heat_pump_fuel', HPXML::FuelTypeElectricity)
    step.setArgument('heat_pump_heating_efficiency', 7.7)
    step.setArgument('heat_pump_cooling_efficiency', 13.0)
    step.setArgument('heat_pump_heating_capacity', 64000.0)
    step.setArgument('heat_pump_cooling_capacity', 48000.0)
    step.setArgument('heat_pump_fraction_heat_load_served', 1)
    step.setArgument('heat_pump_fraction_cool_load_served', 1)
    step.setArgument('heat_pump_backup_fuel', 'none')
    step.setArgument('heat_pump_backup_heating_efficiency', 1)
    step.setArgument('heat_pump_backup_heating_capacity', 34121.0)
    step.setArgument('mini_split_is_ducted', false)
    step.setArgument('evap_cooler_is_ducted', false)
    step.setArgument('heating_setpoint_temp', 68)
    step.setArgument('heating_setback_temp', 68)
    step.setArgument('heating_setback_hours_per_week', 0)
    step.setArgument('heating_setback_start_hour', 0)
    step.setArgument('cooling_setpoint_temp', 78)
    step.setArgument('cooling_setup_temp', 78)
    step.setArgument('cooling_setup_hours_per_week', 0)
    step.setArgument('cooling_setup_start_hour', 0)
    step.setArgument('supply_duct_leakage_units', HPXML::UnitsCFM25)
    step.setArgument('return_duct_leakage_units', HPXML::UnitsCFM25)
    step.setArgument('supply_duct_leakage_value', 75.0)
    step.setArgument('return_duct_leakage_value', 25.0)
    step.setArgument('supply_duct_insulation_r_value', 4.0)
    step.setArgument('return_duct_insulation_r_value', 0.0)
    step.setArgument('supply_duct_location', Constants.Auto)
    step.setArgument('return_duct_location', Constants.Auto)
    step.setArgument('supply_duct_surface_area', 150.0)
    step.setArgument('return_duct_surface_area', 50.0)
    step.setArgument('mech_vent_fan_type', 'none')
    step.setArgument('mech_vent_flow_rate', 110)
    step.setArgument('mech_vent_hours_in_operation', 24)
    step.setArgument('mech_vent_total_recovery_efficiency_type', 'Unadjusted')
    step.setArgument('mech_vent_total_recovery_efficiency', 0.48)
    step.setArgument('mech_vent_sensible_recovery_efficiency_type', 'Unadjusted')
    step.setArgument('mech_vent_sensible_recovery_efficiency', 0.72)
    step.setArgument('mech_vent_fan_power', 30)
    step.setArgument('has_whole_house_fan', false)
    step.setArgument('whole_house_fan_flow_rate', 4500)
    step.setArgument('whole_house_fan_power', 300)
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeStorage)
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeElectricity)
    step.setArgument('water_heater_location', HPXML::LocationLivingSpace)
    step.setArgument('water_heater_tank_volume', 40)
    step.setArgument('water_heater_heating_capacity', Constants.SizingAuto)
    step.setArgument('water_heater_efficiency_type', 'EnergyFactor')
    step.setArgument('water_heater_efficiency', 0.95)
    step.setArgument('water_heater_recovery_efficiency', 0.76)
    step.setArgument('water_heater_standby_loss', 0)
    step.setArgument('water_heater_jacket_rvalue', 0)
    step.setArgument('hot_water_distribution_system_type', HPXML::DHWDistTypeStandard)
    step.setArgument('standard_piping_length', 50)
    step.setArgument('recirculation_control_type', HPXML::DHWRecirControlTypeNone)
    step.setArgument('recirculation_piping_length', 50)
    step.setArgument('recirculation_branch_piping_length', 50)
    step.setArgument('recirculation_pump_power', 50)
    step.setArgument('hot_water_distribution_pipe_r_value', 0.0)
    step.setArgument('dwhr_facilities_connected', 'none')
    step.setArgument('dwhr_equal_flow', true)
    step.setArgument('dwhr_efficiency', 0.55)
    step.setArgument('shower_low_flow', true)
    step.setArgument('sink_low_flow', false)
    step.setArgument('solar_thermal_system_type', 'none')
    step.setArgument('solar_thermal_collector_area', 40.0)
    step.setArgument('solar_thermal_collector_loop_type', HPXML::SolarThermalLoopTypeDirect)
    step.setArgument('solar_thermal_collector_type', HPXML::SolarThermalTypeEvacuatedTube)
    step.setArgument('solar_thermal_collector_azimuth', 180)
    step.setArgument('solar_thermal_collector_tilt', 20)
    step.setArgument('solar_thermal_collector_rated_optical_efficiency', 0.5)
    step.setArgument('solar_thermal_collector_rated_thermal_losses', 0.2799)
    step.setArgument('solar_thermal_storage_volume', Constants.Auto)
    step.setArgument('solar_thermal_solar_fraction', 0)
    step.setArgument('pv_system_module_type_1', 'none')
    step.setArgument('pv_system_location_1', HPXML::LocationRoof)
    step.setArgument('pv_system_tracking_1', HPXML::PVTrackingTypeFixed)
    step.setArgument('pv_system_array_azimuth_1', 180)
    step.setArgument('pv_system_array_tilt_1', 20)
    step.setArgument('pv_system_max_power_output_1', 4000)
    step.setArgument('pv_system_inverter_efficiency_1', 0.96)
    step.setArgument('pv_system_system_losses_fraction_1', 0.14)
    step.setArgument('pv_system_module_type_2', 'none')
    step.setArgument('pv_system_location_2', HPXML::LocationRoof)
    step.setArgument('pv_system_tracking_2', HPXML::PVTrackingTypeFixed)
    step.setArgument('pv_system_array_azimuth_2', 180)
    step.setArgument('pv_system_array_tilt_2', 20)
    step.setArgument('pv_system_max_power_output_2', 4000)
    step.setArgument('pv_system_inverter_efficiency_2', 0.96)
    step.setArgument('pv_system_system_losses_fraction_2', 0.14)
    step.setArgument('has_clothes_washer', true)
    step.setArgument('clothes_washer_location', HPXML::LocationLivingSpace)
    step.setArgument('clothes_washer_efficiency_type', 'ModifiedEnergyFactor')
    step.setArgument('clothes_washer_efficiency', 0.8)
    step.setArgument('clothes_washer_rated_annual_kwh', 700.0)
    step.setArgument('clothes_washer_label_electric_rate', 0.1)
    step.setArgument('clothes_washer_label_gas_rate', 0.6)
    step.setArgument('clothes_washer_label_annual_gas_cost', 25.0)
    step.setArgument('clothes_washer_capacity', 3.0)
    step.setArgument('has_clothes_dryer', true)
    step.setArgument('clothes_dryer_location', HPXML::LocationLivingSpace)
    step.setArgument('clothes_dryer_fuel_type', HPXML::FuelTypeElectricity)
    step.setArgument('clothes_dryer_efficiency_type', 'EnergyFactor')
    step.setArgument('clothes_dryer_efficiency', 2.95)
    step.setArgument('clothes_dryer_control_type', HPXML::ClothesDryerControlTypeTimer)
    step.setArgument('has_dishwasher', true)
    step.setArgument('dishwasher_efficiency_type', 'RatedAnnualkWh')
    step.setArgument('dishwasher_efficiency', 450.0)
    step.setArgument('dishwasher_place_setting_capacity', 12)
    step.setArgument('has_refrigerator', true)
    step.setArgument('refrigerator_location', Constants.Auto)
    step.setArgument('refrigerator_rated_annual_kwh', 650.0)
    step.setArgument('refrigerator_adjusted_annual_kwh', 0)
    step.setArgument('has_cooking_range', true)
    step.setArgument('cooking_range_fuel_type', HPXML::FuelTypeElectricity)
    step.setArgument('cooking_range_is_induction', false)
    step.setArgument('has_oven', true)
    step.setArgument('oven_is_convection', false)
    step.setArgument('has_lighting', true)
    step.setArgument('ceiling_fan_efficiency', 100)
    step.setArgument('ceiling_fan_quantity', 0)
    step.setArgument('ceiling_fan_cooling_setpoint_temp_offset', 0)
    step.setArgument('plug_loads_plug_load_type_1', HPXML::PlugLoadTypeOther)
    step.setArgument('plug_loads_annual_kwh_1', 0)
    step.setArgument('plug_loads_frac_sensible_1', 0)
    step.setArgument('plug_loads_frac_latent_1', 0)
    step.setArgument('plug_loads_plug_load_type_2', HPXML::PlugLoadTypeTelevision)
    step.setArgument('plug_loads_annual_kwh_2', 0)
    step.setArgument('plug_loads_frac_sensible_2', 0)
    step.setArgument('plug_loads_frac_latent_2', 0)
    step.setArgument('plug_loads_schedule_values', false)
    step.setArgument('plug_loads_weekday_fractions', '0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036')
    step.setArgument('plug_loads_weekend_fractions', '0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036')
    step.setArgument('plug_loads_monthly_multipliers', '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248')
  elsif ['base-single-family-attached.osw'].include? osw_file
    step.setArgument('unit_type', 'single-family attached')
    step.setArgument('cfa', 900.0)
    step.setArgument('front_wwr', 0.18)
    step.setArgument('back_wwr', 0.18)
    step.setArgument('left_wwr', 0.18)
    step.setArgument('right_wwr', 0.18)
    step.setArgument('front_window_area', 0)
    step.setArgument('back_window_area', 0)
    step.setArgument('left_window_area', 0)
    step.setArgument('right_window_area', 0)
  elsif ['base-multifamily.osw'].include? osw_file
    step.setArgument('unit_type', 'multifamily')
    step.setArgument('cfa', 900.0)
    step.setArgument('front_wwr', 0.18)
    step.setArgument('back_wwr', 0.18)
    step.setArgument('left_wwr', 0.18)
    step.setArgument('right_wwr', 0.18)
    step.setArgument('front_window_area', 0)
    step.setArgument('back_window_area', 0)
    step.setArgument('left_window_area', 0)
    step.setArgument('right_window_area', 0)
    step.setArgument('supply_duct_leakage_value', 0)
    step.setArgument('return_duct_leakage_value', 0)
  elsif ['base-appliances-gas.osw'].include? osw_file
    step.setArgument('clothes_dryer_fuel_type', HPXML::FuelTypeNaturalGas)
    step.setArgument('clothes_dryer_efficiency', 2.67)
    step.setArgument('clothes_dryer_control_type', HPXML::ClothesDryerControlTypeMoisture)
    step.setArgument('cooking_range_fuel_type', HPXML::FuelTypeNaturalGas)
  elsif ['base-appliances-modified.osw'].include? osw_file
    step.setArgument('clothes_washer_efficiency_type', 'IntegratedModifiedEnergyFactor')
    step.setArgument('clothes_washer_efficiency', 0.73)
    step.setArgument('clothes_dryer_efficiency_type', 'CombinedEnergyFactor')
    step.setArgument('clothes_dryer_efficiency', 2.62)
    step.setArgument('clothes_dryer_control_type', HPXML::ClothesDryerControlTypeMoisture)
    step.setArgument('dishwasher_efficiency_type', 'EnergyFactor')
    step.setArgument('dishwasher_efficiency', 0.5)
    step.setArgument('refrigerator_adjusted_annual_kwh', 600.0)
  elsif ['base-appliances-none.osw'].include? osw_file
    step.setArgument('has_clothes_washer', false)
    step.setArgument('has_clothes_dryer', false)
    step.setArgument('has_dishwasher', false)
    step.setArgument('has_refrigerator', false)
    step.setArgument('has_cooking_range', false)
    step.setArgument('has_oven', false)
  elsif ['base-appliances-oil.osw'].include? osw_file
    step.setArgument('clothes_dryer_fuel_type', HPXML::FuelTypeOil)
    step.setArgument('clothes_dryer_efficiency', 2.67)
    step.setArgument('clothes_dryer_control_type', HPXML::ClothesDryerControlTypeMoisture)
    step.setArgument('cooking_range_fuel_type', HPXML::FuelTypeOil)
  elsif ['base-appliances-propane.osw'].include? osw_file
    step.setArgument('clothes_dryer_fuel_type', HPXML::FuelTypePropane)
    step.setArgument('clothes_dryer_efficiency', 2.67)
    step.setArgument('clothes_dryer_control_type', HPXML::ClothesDryerControlTypeMoisture)
    step.setArgument('cooking_range_fuel_type', HPXML::FuelTypePropane)
  elsif ['base-appliances-wood.osw'].include? osw_file
    step.setArgument('clothes_dryer_fuel_type', HPXML::FuelTypeWood)
    step.setArgument('clothes_dryer_efficiency', 2.67)
    step.setArgument('clothes_dryer_control_type', HPXML::ClothesDryerControlTypeMoisture)
    step.setArgument('cooking_range_fuel_type', HPXML::FuelTypeWood)
  elsif ['base-atticroof-cathedral.osw'].include? osw_file
    step.setArgument('attic_type', HPXML::AtticTypeConditioned)
    step.setArgument('roof_ceiling_r', 25.8)
    step.setArgument('supply_duct_location', HPXML::LocationLivingSpace)
    step.setArgument('return_duct_location', HPXML::LocationLivingSpace)
    step.setArgument('supply_duct_leakage_value', 0.0)
    step.setArgument('return_duct_leakage_value', 0.0)
  elsif ['base-atticroof-conditioned.osw'].include? osw_file
    step.setArgument('cfa', 3600.0)
    step.setArgument('num_floors', 2)
    step.setArgument('attic_type', HPXML::AtticTypeConditioned)
    step.setArgument('roof_ceiling_r', 25.8)
    step.setArgument('supply_duct_location', HPXML::LocationLivingSpace)
    step.setArgument('return_duct_location', HPXML::LocationLivingSpace)
    step.setArgument('supply_duct_leakage_value', 0.0)
    step.setArgument('return_duct_leakage_value', 0.0)
    step.setArgument('water_heater_location', Constants.Auto)
    step.setArgument('clothes_washer_location', Constants.Auto)
    step.setArgument('clothes_dryer_location', Constants.Auto)
    step.setArgument('refrigerator_location', HPXML::LocationBasementConditioned)
  elsif ['base-atticroof-flat.osw'].include? osw_file
    step.setArgument('roof_type', 'flat')
    step.setArgument('roof_ceiling_r', 25.8)
    step.setArgument('supply_duct_leakage_value', 0.0)
    step.setArgument('return_duct_leakage_value', 0.0)
  elsif ['base-atticroof-radiant-barrier.osw'].include? osw_file
    step.setArgument('roof_radiant_barrier', true)
  elsif ['base-atticroof-unvented-insulated-roof.osw'].include? osw_file
    step.setArgument('attic_floor_conditioned_r', 2.1)
    step.setArgument('attic_ceiling_r', 25.8)
    step.setArgument('wall_unconditioned_r', 23)
  elsif ['base-atticroof-vented.osw'].include? osw_file
    step.setArgument('attic_type', HPXML::AtticTypeVented)
    step.setArgument('water_heater_location', HPXML::LocationAtticVented)
  elsif ['base-dhw-combi-tankless.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeCombiTankless)
  elsif ['base-dhw-combi-tankless-outside.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeCombiTankless)
    step.setArgument('water_heater_location', HPXML::LocationOtherExterior)
  elsif ['base-dhw-dwhr.osw'].include? osw_file
    step.setArgument('dwhr_facilities_connected', HPXML::DWHRFacilitiesConnectedAll)
  elsif ['base-dhw-indirect.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeCombiStorage)
    step.setArgument('water_heater_tank_volume', 50)
  elsif ['base-dhw-indirect-outside.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeCombiStorage)
    step.setArgument('water_heater_location', HPXML::LocationOtherExterior)
    step.setArgument('water_heater_tank_volume', 50)
  elsif ['base-dhw-indirect-standbyloss.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeCombiStorage)
    step.setArgument('water_heater_tank_volume', 50)
    step.setArgument('water_heater_standby_loss', 1.0)
  elsif ['base-dhw-jacket-electric.osw'].include? osw_file
    step.setArgument('water_heater_jacket_rvalue', 10.0)
  elsif ['base-dhw-jacket-gas.osw'].include? osw_file
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeNaturalGas)
    step.setArgument('water_heater_tank_volume', 50)
    step.setArgument('water_heater_efficiency', 0.59)
    step.setArgument('water_heater_jacket_rvalue', 10.0)
  elsif ['base-dhw-jacket-hpwh.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeHeatPump)
    step.setArgument('water_heater_tank_volume', 80)
    step.setArgument('water_heater_efficiency', 2.3)
    step.setArgument('water_heater_jacket_rvalue', 10.0)
  elsif ['base-dhw-jacket-indirect.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeCombiStorage)
    step.setArgument('water_heater_tank_volume', 50)
    step.setArgument('water_heater_jacket_rvalue', 10.0)
  elsif ['base-dhw-low-flow-fixtures.osw'].include? osw_file
    step.setArgument('sink_low_flow', true)
  elsif ['base-dhw-multiple.osw'].include? osw_file

  elsif ['base-dhw-none.osw'].include? osw_file
    step.setArgument('water_heater_type', 'none')
  elsif ['base-dhw-recirc-demand.osw'].include? osw_file
    step.setArgument('hot_water_distribution_system_type', HPXML::DHWDistTypeRecirc)
    step.setArgument('recirculation_control_type', HPXML::DHWRecirControlTypeSensor)
    step.setArgument('hot_water_distribution_pipe_r_value', 3.0)
  elsif ['base-dhw-recirc-manual.osw'].include? osw_file
    step.setArgument('hot_water_distribution_system_type', HPXML::DHWDistTypeRecirc)
    step.setArgument('recirculation_control_type', HPXML::DHWRecirControlTypeManual)
    step.setArgument('hot_water_distribution_pipe_r_value', 3.0)
  elsif ['base-dhw-recirc-nocontrol.osw'].include? osw_file
    step.setArgument('hot_water_distribution_system_type', HPXML::DHWDistTypeRecirc)
  elsif ['base-dhw-recirc-temperature.osw'].include? osw_file
    step.setArgument('hot_water_distribution_system_type', HPXML::DHWDistTypeRecirc)
    step.setArgument('recirculation_control_type', HPXML::DHWRecirControlTypeTemperature)
  elsif ['base-dhw-recirc-timer.osw'].include? osw_file
    step.setArgument('hot_water_distribution_system_type', HPXML::DHWDistTypeRecirc)
    step.setArgument('recirculation_control_type', HPXML::DHWRecirControlTypeTimer)
  elsif ['base-dhw-solar-direct-evacuated-tube.osw'].include? osw_file
    step.setArgument('solar_thermal_system_type', 'hot water')
  elsif ['base-dhw-solar-direct-flat-plate.osw'].include? osw_file
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_collector_type', HPXML::SolarThermalTypeSingleGlazing)
    step.setArgument('solar_thermal_collector_rated_optical_efficiency', 0.77)
    step.setArgument('solar_thermal_collector_rated_thermal_losses', 0.793)
  elsif ['base-dhw-solar-direct-ics.osw'].include? osw_file
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_collector_type', HPXML::SolarThermalTypeICS)
    step.setArgument('solar_thermal_collector_rated_optical_efficiency', 0.77)
    step.setArgument('solar_thermal_collector_rated_thermal_losses', 0.793)
  elsif ['base-dhw-solar-fraction.osw'].include? osw_file
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_solar_fraction', 0.65)
  elsif ['base-dhw-solar-indirect-evacuated-tube.osw'].include? osw_file
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_collector_loop_type', HPXML::SolarThermalLoopTypeIndirect)
  elsif ['base-dhw-solar-indirect-flat-plate.osw'].include? osw_file
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_collector_loop_type', HPXML::SolarThermalLoopTypeIndirect)
    step.setArgument('solar_thermal_collector_type', HPXML::SolarThermalTypeSingleGlazing)
    step.setArgument('solar_thermal_collector_rated_optical_efficiency', 0.77)
    step.setArgument('solar_thermal_collector_rated_thermal_losses', 0.793)
  elsif ['base-dhw-solar-thermosyphon-evacuated-tube.osw'].include? osw_file
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_collector_loop_type', HPXML::SolarThermalLoopTypeThermosyphon)
  elsif ['base-dhw-solar-thermosyphon-flat-plate.osw'].include? osw_file
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_collector_loop_type', HPXML::SolarThermalLoopTypeThermosyphon)
    step.setArgument('solar_thermal_collector_type', HPXML::SolarThermalTypeSingleGlazing)
    step.setArgument('solar_thermal_collector_rated_optical_efficiency', 0.77)
    step.setArgument('solar_thermal_collector_rated_thermal_losses', 0.793)
  elsif ['base-dhw-solar-thermosyphon-ics.osw'].include? osw_file
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_collector_loop_type', HPXML::SolarThermalLoopTypeThermosyphon)
    step.setArgument('solar_thermal_collector_type', HPXML::SolarThermalTypeICS)
    step.setArgument('solar_thermal_collector_rated_optical_efficiency', 0.77)
    step.setArgument('solar_thermal_collector_rated_thermal_losses', 0.793)
  elsif ['base-dhw-tank-gas.osw'].include? osw_file
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeNaturalGas)
    step.setArgument('water_heater_tank_volume', 50)
    step.setArgument('water_heater_efficiency', 0.59)
  elsif ['base-dhw-tank-gas-outside.osw'].include? osw_file
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeNaturalGas)
    step.setArgument('water_heater_location', HPXML::LocationOtherExterior)
    step.setArgument('water_heater_tank_volume', 50)
    step.setArgument('water_heater_efficiency', 0.59)
  elsif ['base-dhw-tank-heat-pump.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeHeatPump)
    step.setArgument('water_heater_tank_volume', 80)
    step.setArgument('water_heater_efficiency', 2.3)
  elsif ['base-dhw-tank-heat-pump-outside.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeHeatPump)
    step.setArgument('water_heater_location', HPXML::LocationOtherExterior)
    step.setArgument('water_heater_tank_volume', 80)
    step.setArgument('water_heater_efficiency', 2.3)
  elsif ['base-dhw-tank-heat-pump-with-solar.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeHeatPump)
    step.setArgument('water_heater_tank_volume', 80)
    step.setArgument('water_heater_efficiency', 2.3)
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_collector_loop_type', HPXML::SolarThermalLoopTypeIndirect)
    step.setArgument('solar_thermal_collector_type', HPXML::SolarThermalTypeSingleGlazing)
    step.setArgument('solar_thermal_collector_rated_optical_efficiency', 0.77)
    step.setArgument('solar_thermal_collector_rated_thermal_losses', 0.793)
  elsif ['base-dhw-tank-heat-pump-with-solar-fraction.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeHeatPump)
    step.setArgument('water_heater_tank_volume', 80)
    step.setArgument('water_heater_efficiency', 2.3)
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_solar_fraction', 0.65)
  elsif ['base-dhw-tankless-electric.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeTankless)
    step.setArgument('water_heater_efficiency', 0.99)
  elsif ['base-dhw-tankless-electric-outside.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeTankless)
    step.setArgument('water_heater_location', HPXML::LocationOtherExterior)
    step.setArgument('water_heater_efficiency', 0.99)
  elsif ['base-dhw-tankless-gas.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeTankless)
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeNaturalGas)
    step.setArgument('water_heater_efficiency', 0.82)
  elsif ['base-dhw-tankless-gas-with-solar.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeTankless)
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeNaturalGas)
    step.setArgument('water_heater_efficiency', 0.82)
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_collector_loop_type', HPXML::SolarThermalLoopTypeIndirect)
    step.setArgument('solar_thermal_collector_type', HPXML::SolarThermalTypeSingleGlazing)
    step.setArgument('solar_thermal_collector_rated_optical_efficiency', 0.77)
    step.setArgument('solar_thermal_collector_rated_thermal_losses', 0.793)
  elsif ['base-dhw-tankless-gas-with-solar-fraction.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeTankless)
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeNaturalGas)
    step.setArgument('water_heater_efficiency', 0.82)
    step.setArgument('solar_thermal_system_type', 'hot water')
    step.setArgument('solar_thermal_solar_fraction', 0.65)
  elsif ['base-dhw-tankless-oil.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeTankless)
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeOil)
    step.setArgument('water_heater_efficiency', 0.82)
  elsif ['base-dhw-tankless-propane.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeTankless)
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypePropane)
    step.setArgument('water_heater_efficiency', 0.82)
  elsif ['base-dhw-tankless-wood.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeTankless)
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeWood)
    step.setArgument('water_heater_efficiency', 0.82)
  elsif ['base-dhw-tank-oil.osw'].include? osw_file
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeOil)
    step.setArgument('water_heater_tank_volume', 50)
    step.setArgument('water_heater_efficiency', 0.59)
  elsif ['base-dhw-tank-propane.osw'].include? osw_file
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypePropane)
    step.setArgument('water_heater_tank_volume', 50)
    step.setArgument('water_heater_efficiency', 0.59)
  elsif ['base-dhw-tank-wood.osw'].include? osw_file
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeWood)
    step.setArgument('water_heater_tank_volume', 50)
    step.setArgument('water_heater_efficiency', 0.59)
  elsif ['base-dhw-uef.osw'].include? osw_file
    step.setArgument('water_heater_efficiency_type', 'UniformEnergyFactor')
    step.setArgument('water_heater_efficiency', 0.93)
  elsif ['base-enclosure-2stories.osw'].include? osw_file
    step.setArgument('cfa', 4050.0)
    step.setArgument('num_floors', 2)
    step.setArgument('front_window_area', 216.0)
    step.setArgument('back_window_area', 216.0)
    step.setArgument('left_window_area', 144.0)
    step.setArgument('right_window_area', 144.0)
  elsif ['base-enclosure-2stories-garage.osw'].include? osw_file
    step.setArgument('cfa', 4050.0)
    step.setArgument('num_floors', 2)
    step.setArgument('garage_width', 12.0)
    step.setArgument('front_window_area', 216.0)
    step.setArgument('back_window_area', 216.0)
    step.setArgument('left_window_area', 144.0)
    step.setArgument('right_window_area', 144.0)
  elsif ['base-enclosure-adiabatic-surfaces.osw'].include? osw_file
    step.setArgument('unit_type', 'multifamily')
    step.setArgument('cfa', 1350.0)
    step.setArgument('num_units', 9)
    step.setArgument('num_floors', 3)
    step.setArgument('level', 'Middle')
    step.setArgument('horizontal_location', 'Middle')
    step.setArgument('front_window_area', 37.8)
    step.setArgument('back_window_area', 37.8)
    step.setArgument('left_window_area', 25.2)
    step.setArgument('right_window_area', 25.2)
    step.setArgument('supply_duct_leakage_value', 0)
    step.setArgument('return_duct_leakage_value', 0)
    step.setArgument('supply_duct_location', HPXML::LocationLivingSpace)
    step.setArgument('return_duct_location', HPXML::LocationLivingSpace)
  elsif ['base-enclosure-beds-1.osw'].include? osw_file
    step.setArgument('num_bedrooms', 1)
    step.setArgument('water_heater_heating_capacity', 18.767)
  elsif ['base-enclosure-beds-2.osw'].include? osw_file
    step.setArgument('num_bedrooms', 2)
    step.setArgument('water_heater_heating_capacity', 18.767)
  elsif ['base-enclosure-beds-4.osw'].include? osw_file
    step.setArgument('num_bedrooms', 4)
  elsif ['base-enclosure-beds-5.osw'].include? osw_file
    step.setArgument('num_bedrooms', 5)
  elsif ['base-enclosure-garage.osw'].include? osw_file
    step.setArgument('garage_width', 30.0)
    step.setArgument('garage_protrusion', 1.0)
    step.setArgument('right_window_area', 12.0)
    step.setArgument('supply_duct_location', HPXML::LocationGarage)
    step.setArgument('return_duct_location', HPXML::LocationGarage)
    step.setArgument('water_heater_location', HPXML::LocationGarage)
    step.setArgument('clothes_washer_location', HPXML::LocationGarage)
    step.setArgument('clothes_dryer_location', HPXML::LocationGarage)
    step.setArgument('refrigerator_location', HPXML::LocationGarage)
  elsif ['base-enclosure-infil-cfm50.osw'].include? osw_file
    step.setArgument('living_air_leakage_units', HPXML::UnitsCFM50)
    step.setArgument('living_air_leakage_value', 1080)
  elsif ['base-enclosure-no-natural-ventilation.osw'].include? osw_file

  elsif ['base-enclosure-overhangs.osw'].include? osw_file
    step.setArgument('overhangs_back_depth', 2.5)
    step.setArgument('overhangs_left_depth', 1.5)
    step.setArgument('overhangs_left_distance_to_top_of_window', 2.0)
    step.setArgument('overhangs_right_depth', 1.5)
    step.setArgument('overhangs_right_distance_to_top_of_window', 2.0)
  elsif ['base-enclosure-skylights.osw'].include? osw_file
    step.setArgument('front_skylight_area', 15)
    step.setArgument('back_skylight_area', 15)
  elsif ['base-enclosure-split-surfaces.osw'].include? osw_file

  elsif ['base-enclosure-walltype-cmu.osw'].include? osw_file
    step.setArgument('wall_type', HPXML::WallTypeCMU)
    step.setArgument('wall_conditioned_r', 12)
  elsif ['base-enclosure-walltype-doublestud.osw'].include? osw_file
    step.setArgument('wall_type', HPXML::WallTypeDoubleWoodStud)
    step.setArgument('wall_conditioned_r', 28.7)
  elsif ['base-enclosure-walltype-icf.osw'].include? osw_file
    step.setArgument('wall_type', HPXML::WallTypeICF)
    step.setArgument('wall_conditioned_r', 21.0)
  elsif ['base-enclosure-walltype-log.osw'].include? osw_file
    step.setArgument('wall_type', HPXML::WallTypeLog)
    step.setArgument('wall_conditioned_r', 7.1)
  elsif ['base-enclosure-walltype-sip.osw'].include? osw_file
    step.setArgument('wall_type', HPXML::WallTypeSIP)
    step.setArgument('wall_conditioned_r', 16.1)
  elsif ['base-enclosure-walltype-solidconcrete.osw'].include? osw_file
    step.setArgument('wall_type', HPXML::WallTypeConcrete)
    step.setArgument('wall_conditioned_r', 1.35)
  elsif ['base-enclosure-walltype-steelstud.osw'].include? osw_file
    step.setArgument('wall_type', HPXML::WallTypeSteelStud)
    step.setArgument('wall_conditioned_r', 8.1)
  elsif ['base-enclosure-walltype-stone.osw'].include? osw_file
    step.setArgument('wall_type', HPXML::WallTypeStone)
    step.setArgument('wall_conditioned_r', 5.4)
  elsif ['base-enclosure-walltype-strawbale.osw'].include? osw_file
    step.setArgument('wall_type', HPXML::WallTypeStrawBale)
    step.setArgument('wall_conditioned_r', 58.8)
  elsif ['base-enclosure-walltype-structuralbrick.osw'].include? osw_file
    step.setArgument('wall_type', HPXML::WallTypeBrick)
    step.setArgument('wall_conditioned_r', 7.9)
  elsif ['base-enclosure-windows-interior-shading.osw'].include? osw_file
    step.setArgument('winter_shading_coefficient_front_facade', 0.99)
    step.setArgument('summer_shading_coefficient_front_facade', 0.01)
    step.setArgument('winter_shading_coefficient_back_facade', 0.85)
    step.setArgument('summer_shading_coefficient_back_facade', 0.7)
    step.setArgument('winter_shading_coefficient_left_facade', 1.0)
    step.setArgument('summer_shading_coefficient_left_facade', 1.0)
    step.setArgument('winter_shading_coefficient_right_facade', 0.5)
    step.setArgument('summer_shading_coefficient_right_facade', 0.0)
  elsif ['base-enclosure-windows-none.osw'].include? osw_file
    step.setArgument('front_window_area', 0)
    step.setArgument('back_window_area', 0)
    step.setArgument('left_window_area', 0)
    step.setArgument('right_window_area', 0)
  elsif ['base-foundation-ambient.osw'].include? osw_file
    step.setArgument('cfa', 1350.0)
    step.setArgument('foundation_type', HPXML::FoundationTypeAmbient)
    step.setArgument('foundation_ceiling_r', 18.7)
  elsif ['base-foundation-complex.osw'].include? osw_file

  elsif ['base-foundation-conditioned-basement-slab-insulation.osw'].include? osw_file
    step.setArgument('slab_under_r', 10)
    step.setArgument('slab_under_width', 4)
  elsif ['base-foundation-conditioned-basement-wall-interior-insulation.osw'].include? osw_file
    step.setArgument('foundation_wall_r', 18.9)
    step.setArgument('foundation_wall_distance_to_top', 1.0)
  elsif ['base-foundation-multiple.osw'].include? osw_file

  elsif ['base-foundation-slab.osw'].include? osw_file
    step.setArgument('cfa', 1350.0)
    step.setArgument('foundation_type', HPXML::FoundationTypeSlab)
    step.setArgument('foundation_wall_depth_below_grade', 0.0)
    step.setArgument('slab_under_r', 5)
    step.setArgument('slab_under_width', 999)
    step.setArgument('carpet_fraction', 1.0)
    step.setArgument('carpet_r_value', 2.5)
  elsif ['base-foundation-unconditioned-basement.osw'].include? osw_file
    step.setArgument('cfa', 1350.0)
    step.setArgument('foundation_type', HPXML::FoundationTypeBasementUnconditioned)
    step.setArgument('foundation_ceiling_r', 18.7)
    step.setArgument('foundation_wall_r', 0)
    step.setArgument('foundation_wall_distance_to_bottom', 0)
    step.setArgument('supply_duct_location', HPXML::LocationBasementUnconditioned)
    step.setArgument('return_duct_location', HPXML::LocationBasementUnconditioned)
    step.setArgument('water_heater_location', Constants.Auto)
    step.setArgument('clothes_washer_location', Constants.Auto)
    step.setArgument('clothes_dryer_location', Constants.Auto)
    step.setArgument('refrigerator_location', HPXML::LocationBasementUnconditioned)
  elsif ['base-foundation-unconditioned-basement-above-grade.osw'].include? osw_file
    step.setArgument('cfa', 1350.0)
    step.setArgument('foundation_type', HPXML::FoundationTypeBasementUnconditioned)
    step.setArgument('foundation_wall_r', 0)
    step.setArgument('foundation_wall_distance_to_bottom', 0)
    step.setArgument('foundation_wall_depth_below_grade', 4.0)
    step.setArgument('supply_duct_location', HPXML::LocationBasementUnconditioned)
    step.setArgument('return_duct_location', HPXML::LocationBasementUnconditioned)
    step.setArgument('water_heater_location', Constants.Auto)
    step.setArgument('clothes_washer_location', Constants.Auto)
    step.setArgument('clothes_dryer_location', Constants.Auto)
    step.setArgument('refrigerator_location', HPXML::LocationBasementUnconditioned)
  elsif ['base-foundation-unconditioned-basement-assembly-r.osw'].include? osw_file

  elsif ['base-foundation-unconditioned-basement-wall-insulation.osw'].include? osw_file
    step.setArgument('cfa', 1350.0)
    step.setArgument('foundation_type', HPXML::FoundationTypeBasementUnconditioned)
    step.setArgument('foundation_ceiling_r', 2.1)
    step.setArgument('foundation_wall_distance_to_bottom', 4)
    step.setArgument('supply_duct_location', HPXML::LocationBasementUnconditioned)
    step.setArgument('return_duct_location', HPXML::LocationBasementUnconditioned)
    step.setArgument('water_heater_location', Constants.Auto)
    step.setArgument('clothes_washer_location', Constants.Auto)
    step.setArgument('clothes_dryer_location', Constants.Auto)
    step.setArgument('refrigerator_location', HPXML::LocationBasementUnconditioned)
  elsif ['base-foundation-unvented-crawlspace.osw'].include? osw_file
    step.setArgument('cfa', 1350.0)
    step.setArgument('foundation_type', HPXML::FoundationTypeCrawlspaceUnvented)
    step.setArgument('foundation_height', 4.0)
    step.setArgument('foundation_ceiling_r', 18.7)
    step.setArgument('foundation_wall_distance_to_bottom', 4.0)
    step.setArgument('foundation_wall_depth_below_grade', 3.0)
    step.setArgument('carpet_r_value', 2.5)
    step.setArgument('supply_duct_location', HPXML::LocationCrawlspaceUnvented)
    step.setArgument('return_duct_location', HPXML::LocationCrawlspaceUnvented)
    step.setArgument('water_heater_location', Constants.Auto)
  elsif ['base-foundation-vented-crawlspace.osw'].include? osw_file
    step.setArgument('cfa', 1350.0)
    step.setArgument('foundation_type', HPXML::FoundationTypeCrawlspaceVented)
    step.setArgument('foundation_height', 4.0)
    step.setArgument('foundation_ceiling_r', 18.7)
    step.setArgument('foundation_wall_distance_to_bottom', 4.0)
    step.setArgument('foundation_wall_depth_below_grade', 3.0)
    step.setArgument('carpet_r_value', 2.5)
    step.setArgument('supply_duct_location', HPXML::LocationCrawlspaceVented)
    step.setArgument('return_duct_location', HPXML::LocationCrawlspaceVented)
    step.setArgument('water_heater_location', Constants.Auto)
  elsif ['base-foundation-walkout-basement.osw'].include? osw_file
    step.setArgument('foundation_wall_distance_to_bottom', 4.0)
    step.setArgument('foundation_wall_depth_below_grade', 3.0)
  elsif ['base-hvac-air-to-air-heat-pump-1-speed.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpAirToAir)
    step.setArgument('heat_pump_heating_capacity', 42000.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeElectricity)
  elsif ['base-hvac-air-to-air-heat-pump-1-speed.detailed.osw'].include? osw_file

  elsif ['base-hvac-air-to-air-heat-pump-2-speed.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpAirToAir)
    step.setArgument('heat_pump_heating_efficiency', 9.3)
    step.setArgument('heat_pump_heating_capacity', 42000.0)
    step.setArgument('heat_pump_cooling_efficiency', 18.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeElectricity)
  elsif ['base-hvac-air-to-air-heat-pump-2-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-air-to-air-heat-pump-var-speed.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpAirToAir)
    step.setArgument('heat_pump_heating_efficiency', 10.0)
    step.setArgument('heat_pump_heating_capacity', 42000.0)
    step.setArgument('heat_pump_cooling_efficiency', 22.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeElectricity)
  elsif ['base-hvac-air-to-air-heat-pump-var-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-boiler-elec-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeElectricity)
    step.setArgument('heating_system_heating_efficiency', 1.0)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
  elsif ['base-hvac-boiler-gas-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-boiler-gas-only-no-eae.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-boiler-oil-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeOil)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-boiler-propane-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_fuel', HPXML::FuelTypePropane)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-boiler-wood-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeBoiler)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeWood)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-central-ac-only-1-speed.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
  elsif ['base-hvac-central-ac-only-1-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-central-ac-only-2-speed.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_cooling_efficiency', 18.0)
  elsif ['base-hvac-central-ac-only-2-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-central-ac-only-var-speed.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_cooling_efficiency', 24.0)
  elsif ['base-hvac-central-ac-only-var-speed-detailed.osw'].include? osw_file

  elsif ['base-hvac-central-ac-plus-air-to-air-heat-pump-heating.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpAirToAir)
    step.setArgument('heat_pump_fuel', HPXML::FuelTypeElectricity)
    step.setArgument('heat_pump_heating_efficiency', 7.7)
    step.setArgument('heat_pump_heating_capacity', 42000.0)
    step.setArgument('heat_pump_fraction_cool_load_served', 0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeElectricity)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpAirToAir)
    step.setArgument('heat_pump_heating_efficiency', 7.7)
    step.setArgument('heat_pump_heating_capacity', 42000.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeNaturalGas)
    step.setArgument('heat_pump_backup_heating_efficiency', 0.95)
    step.setArgument('heat_pump_backup_heating_capacity', 36000.0)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpAirToAir)
    step.setArgument('heat_pump_heating_efficiency', 7.7)
    step.setArgument('heat_pump_heating_capacity', 42000.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeElectricity)
    step.setArgument('heat_pump_backup_heating_capacity', 36000.0)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpAirToAir)
    step.setArgument('heat_pump_heating_efficiency', 9.3)
    step.setArgument('heat_pump_heating_capacity', 42000.0)
    step.setArgument('heat_pump_cooling_efficiency', 18.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeNaturalGas)
    step.setArgument('heat_pump_backup_heating_efficiency', 0.95)
    step.setArgument('heat_pump_backup_heating_capacity', 36000.0)
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpAirToAir)
    step.setArgument('heat_pump_heating_efficiency', 10.0)
    step.setArgument('heat_pump_heating_capacity', 42000.0)
    step.setArgument('heat_pump_cooling_efficiency', 22.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeNaturalGas)
    step.setArgument('heat_pump_backup_heating_efficiency', 0.95)
    step.setArgument('heat_pump_backup_heating_capacity', 36000.0)
  elsif ['base-hvac-dual-fuel-mini-split-heat-pump-ducted.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpMiniSplit)
    step.setArgument('heat_pump_heating_efficiency', 10.0)
    step.setArgument('heat_pump_heating_capacity', 52000.0)
    step.setArgument('heat_pump_cooling_efficiency', 19.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeNaturalGas)
    step.setArgument('heat_pump_backup_heating_efficiency', 0.95)
    step.setArgument('heat_pump_backup_heating_capacity', 36000.0)
    step.setArgument('mini_split_is_ducted', true)
    step.setArgument('supply_duct_leakage_value', 15.0)
    step.setArgument('return_duct_leakage_value', 5.0)
    step.setArgument('supply_duct_insulation_r_value', 0.0)
    step.setArgument('supply_duct_surface_area', 30.0)
    step.setArgument('return_duct_surface_area', 10.0)
  elsif ['base-hvac-ducts-in-conditioned-space.osw'].include? osw_file
    step.setArgument('supply_duct_leakage_value', 1.5)
    step.setArgument('return_duct_leakage_value', 1.5)
    step.setArgument('supply_duct_location', HPXML::LocationLivingSpace)
    step.setArgument('return_duct_location', HPXML::LocationLivingSpace)
  elsif ['base-hvac-ducts-leakage-percent.osw'].include? osw_file
    step.setArgument('supply_duct_leakage_units', HPXML::UnitsPercent)
    step.setArgument('return_duct_leakage_units', HPXML::UnitsPercent)
    step.setArgument('supply_duct_leakage_value', 0.1)
    step.setArgument('return_duct_leakage_value', 0.05)
  elsif ['base-hvac-ducts-locations.osw'].include? osw_file
    step.setArgument('cfa', 1350.0)
    step.setArgument('foundation_type', HPXML::FoundationTypeCrawlspaceVented)
    step.setArgument('foundation_height', 4.0)
    step.setArgument('foundation_ceiling_r', 18.7)
    step.setArgument('foundation_wall_distance_to_bottom', 4.0)
    step.setArgument('foundation_wall_depth_below_grade', 3.0)
    step.setArgument('carpet_r_value', 2.5)
    step.setArgument('supply_duct_location', HPXML::LocationCrawlspaceVented)
    step.setArgument('return_duct_location', HPXML::LocationAtticUnvented)
    step.setArgument('water_heater_location', Constants.Auto)
  elsif ['base-hvac-ducts-multiple.osw'].include? osw_file

  elsif ['base-hvac-ducts-outside.osw'].include? osw_file
    step.setArgument('supply_duct_location', HPXML::LocationOutside)
    step.setArgument('return_duct_location', HPXML::LocationOutside)
  elsif ['base-hvac-elec-resistance-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeElectricResistance)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeElectricity)
    step.setArgument('heating_system_heating_efficiency', 1.0)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-evap-cooler-furnace-gas.osw'].include? osw_file
    step.setArgument('cooling_system_type', HPXML::HVACTypeEvaporativeCooler)
  elsif ['base-hvac-evap-cooler-only.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', HPXML::HVACTypeEvaporativeCooler)
  elsif ['base-hvac-evap-cooler-only-ducted.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', HPXML::HVACTypeEvaporativeCooler)
    step.setArgument('evap_cooler_is_ducted', true)
  elsif ['base-hvac-flowrate.osw'].include? osw_file

  elsif ['base-hvac-furnace-elec-only.osw'].include? osw_file
    step.setArgument('heating_system_fuel', HPXML::FuelTypeElectricity)
    step.setArgument('heating_system_heating_efficiency', 1.0)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-furnace-gas-central-ac-2-speed.osw'].include? osw_file
    step.setArgument('cooling_system_cooling_efficiency', 18.0)
  elsif ['base-hvac-furnace-gas-central-ac-var-speed.osw'].include? osw_file
    step.setArgument('cooling_system_cooling_efficiency', 24.0)
  elsif ['base-hvac-furnace-gas-only.osw'].include? osw_file
    step.setArgument('heating_system_electric_auxiliary_energy', 700.0)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-furnace-gas-only-no-eae.osw'].include? osw_file
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-furnace-gas-room-ac.osw'].include? osw_file
    step.setArgument('cooling_system_type', HPXML::HVACTypeRoomAirConditioner)
    step.setArgument('cooling_system_cooling_efficiency', 8.5)
  elsif ['base-hvac-furnace-oil-only.osw'].include? osw_file
    step.setArgument('heating_system_fuel', HPXML::FuelTypeOil)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-furnace-propane-only.osw'].include? osw_file
    step.setArgument('heating_system_fuel', HPXML::FuelTypePropane)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-furnace-wood-only.osw'].include? osw_file
    step.setArgument('heating_system_fuel', HPXML::FuelTypeWood)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-ground-to-air-heat-pump.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpGroundToAir)
    step.setArgument('heat_pump_heating_efficiency', 3.6)
    step.setArgument('heat_pump_cooling_efficiency', 16.6)
    step.setArgument('heat_pump_heating_capacity', 42000.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeElectricity)
  elsif ['base-hvac-ground-to-air-heat-pump-detailed.osw'].include? osw_file

  elsif ['base-hvac-ideal-air.osw'].include? osw_file

  elsif ['base-hvac-mini-split-heat-pump-ducted.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpMiniSplit)
    step.setArgument('heat_pump_heating_capacity', 52000.0)
    step.setArgument('heat_pump_heating_efficiency', 10.0)
    step.setArgument('heat_pump_cooling_efficiency', 19.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeElectricity)
    step.setArgument('mini_split_is_ducted', true)
    step.setArgument('supply_duct_leakage_value', 15.0)
    step.setArgument('return_duct_leakage_value', 5.0)
    step.setArgument('supply_duct_insulation_r_value', 0.0)
    step.setArgument('supply_duct_surface_area', 30.0)
    step.setArgument('return_duct_surface_area', 10.0)
  elsif ['base-hvac-mini-split-heat-pump-ducted-detailed.osw'].include? osw_file

  elsif ['base-hvac-mini-split-heat-pump-ductless.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpMiniSplit)
    step.setArgument('heat_pump_heating_capacity', 52000.0)
    step.setArgument('heat_pump_heating_efficiency', 10.0)
    step.setArgument('heat_pump_cooling_efficiency', 19.0)
    step.setArgument('heat_pump_backup_fuel', HPXML::FuelTypeElectricity)
  elsif ['base-hvac-mini-split-heat-pump-ductless-no-backup.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
    step.setArgument('heat_pump_type', HPXML::HVACTypeHeatPumpMiniSplit)
    step.setArgument('heat_pump_heating_efficiency', 10.0)
    step.setArgument('heat_pump_cooling_efficiency', 19.0)
    step.setArgument('heat_pump_heating_capacity', 52000.0)
  elsif ['base-hvac-multiple.osw'].include? osw_file

  elsif ['base-hvac-none.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-none-no-fuel-access.osw'].include? osw_file

  elsif ['base-hvac-portable-heater-electric-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypePortableHeater)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeElectricity)
    step.setArgument('heating_system_heating_efficiency', 1.0)
    # step.setArgument("cooling_system_type", "none")
  elsif ['base-hvac-programmable-thermostat.osw'].include? osw_file
    step.setArgument('heating_setback_temp', 66)
    step.setArgument('heating_setback_hours_per_week', 49)
    step.setArgument('heating_setback_start_hour', 23)
    step.setArgument('cooling_setup_temp', 80)
    step.setArgument('cooling_setup_hours_per_week', 42)
    step.setArgument('cooling_setup_start_hour', 9)
  elsif ['base-hvac-room-ac-only.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', HPXML::HVACTypeRoomAirConditioner)
    step.setArgument('cooling_system_cooling_efficiency', 8.5)
  elsif ['base-hvac-room-ac-only-detailed.osw'].include? osw_file

  elsif ['base-hvac-setpoints.osw'].include? osw_file
    step.setArgument('heating_setpoint_temp', 60.0)
    step.setArgument('cooling_setpoint_temp', 80.0)
  elsif ['base-hvac-stove-oil-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeStove)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeOil)
    step.setArgument('heating_system_heating_efficiency', 0.8)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-stove-oil-only-no-eae.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeStove)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeOil)
    step.setArgument('heating_system_heating_efficiency', 0.8)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-stove-wood-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeStove)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeWood)
    step.setArgument('heating_system_heating_efficiency', 0.8)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-undersized.osw'].include? osw_file
    step.setArgument('heating_system_heating_capacity', 6400.0)
    step.setArgument('cooling_system_cooling_capacity', 4800.0)
    step.setArgument('supply_duct_leakage_value', 7.5)
    step.setArgument('return_duct_leakage_value', 2.5)
  elsif ['base-hvac-wall-furnace-elec-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeWallFurnace)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeElectricity)
    step.setArgument('heating_system_heating_efficiency', 1.0)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-wall-furnace-propane-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeWallFurnace)
    step.setArgument('heating_system_fuel', HPXML::FuelTypePropane)
    step.setArgument('heating_system_heating_efficiency', 0.8)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-wall-furnace-propane-only-no-eae.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeWallFurnace)
    step.setArgument('heating_system_fuel', HPXML::FuelTypePropane)
    step.setArgument('heating_system_heating_efficiency', 0.8)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-hvac-wall-furnace-wood-only.osw'].include? osw_file
    step.setArgument('heating_system_type', HPXML::HVACTypeWallFurnace)
    step.setArgument('heating_system_fuel', HPXML::FuelTypeWood)
    step.setArgument('heating_system_heating_efficiency', 0.8)
    step.setArgument('heating_system_electric_auxiliary_energy', 200.0)
    step.setArgument('cooling_system_type', 'none')
  elsif ['base-infiltration-ach-natural.osw'].include? osw_file
    step.setArgument('living_air_leakage_units', HPXML::UnitsACHNatural)
    step.setArgument('living_air_leakage_value', 0.67)
  elsif ['base-location-baltimore-md.osw'].include? osw_file
    step.setArgument('weather_station_epw_filename', 'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw')
  elsif ['base-location-dallas-tx.osw'].include? osw_file
    step.setArgument('weather_station_epw_filename', 'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw')
  elsif ['base-location-duluth-mn.osw'].include? osw_file
    step.setArgument('weather_station_epw_filename', 'USA_MN_Duluth.Intl.AP.727450_TMY3.epw')
  elsif ['base-location-epw-filename.osw'].include? osw_file

  elsif ['base-location-miami-fl.osw'].include? osw_file
    step.setArgument('weather_station_epw_filename', 'USA_FL_Miami.Intl.AP.722020_TMY3.epw')
  elsif ['base-mechvent-balanced.osw'].include? osw_file
    step.setArgument('mech_vent_fan_type', HPXML::MechVentTypeBalanced)
    step.setArgument('mech_vent_fan_power', 60)
  elsif ['base-mechvent-cfis.osw'].include? osw_file
    step.setArgument('mech_vent_fan_type', HPXML::MechVentTypeCFIS)
    step.setArgument('mech_vent_flow_rate', 330)
    step.setArgument('mech_vent_hours_in_operation', 8)
    step.setArgument('mech_vent_fan_power', 300)
  elsif ['base-mechvent-cfis-evap-cooler-only-ducted.osw'].include? osw_file
    step.setArgument('heating_system_type', 'none')
    step.setArgument('cooling_system_type', HPXML::HVACTypeEvaporativeCooler)
    step.setArgument('evap_cooler_is_ducted', true)
    step.setArgument('mech_vent_fan_type', HPXML::MechVentTypeCFIS)
    step.setArgument('mech_vent_flow_rate', 330)
    step.setArgument('mech_vent_hours_in_operation', 8)
    step.setArgument('mech_vent_fan_power', 300)
  elsif ['base-mechvent-erv.osw'].include? osw_file
    step.setArgument('mech_vent_fan_type', HPXML::MechVentTypeERV)
    step.setArgument('mech_vent_fan_power', 60)
  elsif ['base-mechvent-erv-atre-asre.osw'].include? osw_file
    step.setArgument('mech_vent_fan_type', HPXML::MechVentTypeERV)
    step.setArgument('mech_vent_total_recovery_efficiency_type', 'Adjusted')
    step.setArgument('mech_vent_total_recovery_efficiency', 0.526)
    step.setArgument('mech_vent_sensible_recovery_efficiency_type', 'Adjusted')
    step.setArgument('mech_vent_sensible_recovery_efficiency', 0.79)
    step.setArgument('mech_vent_fan_power', 60)
  elsif ['base-mechvent-exhaust.osw'].include? osw_file
    step.setArgument('mech_vent_fan_type', HPXML::MechVentTypeExhaust)
  elsif ['base-mechvent-exhaust-rated-flow-rate.osw'].include? osw_file
    step.setArgument('mech_vent_fan_type', HPXML::MechVentTypeExhaust)
  elsif ['base-mechvent-hrv.osw'].include? osw_file
    step.setArgument('mech_vent_fan_type', HPXML::MechVentTypeHRV)
    step.setArgument('mech_vent_fan_power', 60)
  elsif ['base-mechvent-hrv-asre.osw'].include? osw_file
    step.setArgument('mech_vent_fan_type', HPXML::MechVentTypeHRV)
    step.setArgument('mech_vent_sensible_recovery_efficiency_type', 'Adjusted')
    step.setArgument('mech_vent_sensible_recovery_efficiency', 0.79)
    step.setArgument('mech_vent_fan_power', 60)
  elsif ['base-mechvent-supply.osw'].include? osw_file
    step.setArgument('mech_vent_fan_type', HPXML::MechVentTypeSupply)
  elsif ['base-misc-ceiling-fans.osw'].include? osw_file
    step.setArgument('ceiling_fan_cooling_setpoint_temp_offset', 0.5)
    step.setArgument('ceiling_fan_quantity', 2)
  elsif ['base-misc-lighting-none.osw'].include? osw_file
    step.setArgument('has_lighting', false)
  elsif ['base-misc-loads-detailed.osw'].include? osw_file
    step.setArgument('plug_loads_schedule_values', true)
    step.setArgument('plug_loads_annual_kwh_1', 7302.0)
    step.setArgument('plug_loads_frac_sensible_1', 0.82)
    step.setArgument('plug_loads_frac_latent_1', 0.18)
    step.setArgument('plug_loads_annual_kwh_2', 400.0)
    step.setArgument('plug_loads_weekday_fractions', '0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066')
    step.setArgument('plug_loads_weekend_fractions', '0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066')
    step.setArgument('plug_loads_monthly_multipliers', '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0')
  elsif ['base-misc-number-of-occupants.osw'].include? osw_file
    step.setArgument('num_occupants', 5.0)
  elsif ['base-misc-timestep-10-mins.osw'].include? osw_file
    step.setArgument('simulation_control_timestep', 10)
  elsif ['base-misc-whole-house-fan.osw'].include? osw_file
    step.setArgument('has_whole_house_fan', true)
  elsif ['base-pv.osw'].include? osw_file
    step.setArgument('pv_system_module_type_1', HPXML::PVModuleTypeStandard)
    step.setArgument('pv_system_module_type_2', HPXML::PVModuleTypePremium)
    step.setArgument('pv_system_array_azimuth_2', 90)
    step.setArgument('pv_system_max_power_output_2', 1500)
  elsif ['base-site-neighbors.osw'].include? osw_file
    step.setArgument('neighbor_back_distance', 10)
    step.setArgument('neighbor_front_distance', 15)
    step.setArgument('neighbor_front_height', 12)
  elsif ['hvac_partial/base-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-air-to-air-heat-pump-1-speed-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-air-to-air-heat-pump-2-speed-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-air-to-air-heat-pump-var-speed-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-boiler-gas-only-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-central-ac-only-1-speed-33percent.osw'].include? osw_file
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-central-ac-only-2-speed-33percent.osw'].include? osw_file
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-central-ac-only-var-speed-33percent.osw'].include? osw_file
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-elec-resistance-only-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-evap-cooler-only-33percent.osw'].include? osw_file
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-furnace-gas-central-ac-2-speed-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-furnace-gas-central-ac-var-speed-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-furnace-gas-only-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-furnace-gas-room-ac-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-ground-to-air-heat-pump-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-mini-split-heat-pump-ducted-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-room-ac-only-33percent.osw'].include? osw_file
    step.setArgument('cooling_system_fraction_cool_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-stove-oil-only-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
  elsif ['hvac_partial/base-hvac-wall-furnace-propane-only-33percent.osw'].include? osw_file
    step.setArgument('heating_system_fraction_heat_load_served', 0.33333)
  elsif ['invalid_files/non-electric-heat-pump-water-heater.osw'].include? osw_file
    step.setArgument('water_heater_type', HPXML::WaterHeaterTypeHeatPump)
    step.setArgument('water_heater_fuel_type', HPXML::FuelTypeNaturalGas)
  end
  return step
end

def create_hpxmls
  this_dir = File.dirname(__FILE__)
  sample_files_dir = File.join(this_dir, 'workflow/sample_files')

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
    'invalid_files/duplicate-id.xml' => 'base.xml',
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
    'invalid_files/invalid-timestep.xml' => 'base.xml',
    'invalid_files/invalid-window-height.xml' => 'base-enclosure-overhangs.xml',
    'invalid_files/invalid-window-interior-shading.xml' => 'base.xml',
    'invalid_files/lighting-fractions.xml' => 'base.xml',
    'invalid_files/mismatched-slab-and-foundation-wall.xml' => 'base.xml',
    'invalid_files/missing-elements.xml' => 'base.xml',
    'invalid_files/missing-surfaces.xml' => 'base.xml',
    'invalid_files/net-area-negative-roof.xml' => 'base-enclosure-skylights.xml',
    'invalid_files/net-area-negative-wall.xml' => 'base.xml',
    'invalid_files/orphaned-hvac-distribution.xml' => 'base-hvac-furnace-gas-room-ac.xml',
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
    'invalid_files/unattached-skylight.xml' => 'base-enclosure-skylights.xml',
    'invalid_files/unattached-solar-thermal-system.xml' => 'base-dhw-solar-indirect-flat-plate.xml',
    'invalid_files/unattached-window.xml' => 'base.xml',
    'invalid_files/water-heater-location.xml' => 'base.xml',
    'invalid_files/water-heater-location-other.xml' => 'base.xml',
    'invalid_files/slab-zero-exposed-perimeter.xml' => 'base.xml',

    'base-appliances-gas.xml' => 'base.xml',
    'base-appliances-wood.xml' => 'base.xml',
    'base-appliances-modified.xml' => 'base.xml',
    'base-appliances-none.xml' => 'base.xml',
    'base-appliances-oil.xml' => 'base.xml',
    'base-appliances-propane.xml' => 'base.xml',
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
    'base-dhw-temperature.xml' => 'base.xml',
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
    'base-enclosure-windows-inoperable.xml' => 'base.xml',
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
    'base-hvac-stove-wood-pellets-only.xml' => 'base-hvac-stove-wood-only.xml',
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
    'base-mechvent-cfis-evap-cooler-only-ducted.xml' => 'base-hvac-evap-cooler-only-ducted.xml',
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
    'base-misc-timestep-10-mins.xml' => 'base.xml',
    'base-misc-timestep-60-mins.xml' => 'base.xml',
    'base-misc-whole-house-fan.xml' => 'base.xml',
    'base-pv.xml' => 'base.xml',
    'base-site-neighbors.xml' => 'base.xml',
    'base-version-2014.xml' => 'base.xml',
    'base-version-2014A.xml' => 'base.xml',
    'base-version-2014AE.xml' => 'base.xml',
    'base-version-2014AEG.xml' => 'base.xml',
    'base-version-2019.xml' => 'base.xml',
    'base-version-2019A.xml' => 'base.xml',
    'base-version-latest.xml' => 'base.xml',

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
  }

  puts "Generating #{hpxmls_files.size} HPXML files..."

  hpxmls_files.each do |derivative, parent|
    print '.'

    begin
      hpxml_files = [derivative]
      unless parent.nil?
        hpxml_files.unshift(parent)
      end
      while not parent.nil?
        next unless hpxmls_files.keys.include? parent

        unless hpxmls_files[parent].nil?
          hpxml_files.unshift(hpxmls_files[parent])
        end
        parent = hpxmls_files[parent]
      end

      hpxml = HPXML.new
      hpxml_files.each do |hpxml_file|
        set_hpxml_header(hpxml_file, hpxml)
        set_hpxml_site(hpxml_file, hpxml)
        set_hpxml_neighbor_buildings(hpxml_file, hpxml)
        set_hpxml_building_occupancy(hpxml_file, hpxml)
        set_hpxml_building_construction(hpxml_file, hpxml)
        set_hpxml_climate_and_risk_zones(hpxml_file, hpxml)
        set_hpxml_air_infiltration_measurements(hpxml_file, hpxml)
        set_hpxml_attics(hpxml_file, hpxml)
        set_hpxml_foundations(hpxml_file, hpxml)
        set_hpxml_roofs(hpxml_file, hpxml)
        set_hpxml_rim_joists(hpxml_file, hpxml)
        set_hpxml_walls(hpxml_file, hpxml)
        set_hpxml_foundation_walls(hpxml_file, hpxml)
        set_hpxml_frame_floors(hpxml_file, hpxml)
        set_hpxml_slabs(hpxml_file, hpxml)
        set_hpxml_windows(hpxml_file, hpxml)
        set_hpxml_skylights(hpxml_file, hpxml)
        set_hpxml_doors(hpxml_file, hpxml)
        set_hpxml_heating_systems(hpxml_file, hpxml)
        set_hpxml_cooling_systems(hpxml_file, hpxml)
        set_hpxml_heat_pumps(hpxml_file, hpxml)
        set_hpxml_hvac_control(hpxml_file, hpxml)
        set_hpxml_hvac_distributions(hpxml_file, hpxml)
        set_hpxml_ventilation_fans(hpxml_file, hpxml)
        set_hpxml_water_heating_systems(hpxml_file, hpxml)
        set_hpxml_hot_water_distribution(hpxml_file, hpxml)
        set_hpxml_water_fixtures(hpxml_file, hpxml)
        set_hpxml_solar_thermal_system(hpxml_file, hpxml)
        set_hpxml_pv_systems(hpxml_file, hpxml)
        set_hpxml_clothes_washer(hpxml_file, hpxml)
        set_hpxml_clothes_dryer(hpxml_file, hpxml)
        set_hpxml_dishwasher(hpxml_file, hpxml)
        set_hpxml_refrigerator(hpxml_file, hpxml)
        set_hpxml_cooking_range(hpxml_file, hpxml)
        set_hpxml_oven(hpxml_file, hpxml)
        set_hpxml_lighting(hpxml_file, hpxml)
        set_hpxml_ceiling_fans(hpxml_file, hpxml)
        set_hpxml_plug_loads(hpxml_file, hpxml)
        set_hpxml_misc_load_schedule(hpxml_file, hpxml)
      end

      hpxml_doc = hpxml.to_rexml()

      if ['invalid_files/missing-elements.xml'].include? derivative
        hpxml_doc.elements['/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction'].elements.delete('NumberofConditionedFloors')
        hpxml_doc.elements['/HPXML/Building/BuildingDetails/BuildingSummary/BuildingConstruction'].elements.delete('ConditionedFloorArea')
      end

      hpxml_path = File.join(sample_files_dir, derivative)

      # Validate file against HPXML schema
      schemas_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'HPXMLtoOpenStudio/resources'))
      errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, 'HPXML.xsd'), nil)
      if errors.size > 0
        fail errors.to_s
      end

      # Check for additional errors
      if not hpxml_path.include? 'invalid_files'
        errors = hpxml.check_for_errors()
        if errors.size > 0
          fail errors.to_s
        end
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
    abs_hpxml_files << File.absolute_path(File.join(sample_files_dir, hpxml_file))
    next unless hpxml_file.include? '/'

    dirs << hpxml_file.split('/')[0] + '/'
  end
  dirs.uniq.each do |dir|
    Dir["#{sample_files_dir}/#{dir}*.xml"].each do |xml|
      next if abs_hpxml_files.include? File.absolute_path(xml)

      puts "Warning: Extra HPXML file found at #{File.absolute_path(xml)}"
    end
  end
end

def set_hpxml_header(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.set_header(xml_type: 'HPXML',
                     xml_generated_by: 'Rakefile',
                     transaction: 'create',
                     building_id: 'MyBuilding',
                     event_type: 'proposed workscope',
                     created_date_and_time: Time.new(2000, 1, 1).strftime('%Y-%m-%dT%H:%M:%S%:z')) # Hard-code to prevent diffs
  elsif ['base-version-2014.xml'].include? hpxml_file
    hpxml.header.eri_calculation_version = '2014'
  elsif ['base-version-2014A.xml'].include? hpxml_file
    hpxml.header.eri_calculation_version = '2014A'
  elsif ['base-version-2014AE.xml'].include? hpxml_file
    hpxml.header.eri_calculation_version = '2014AE'
  elsif ['base-version-2014AEG.xml'].include? hpxml_file
    hpxml.header.eri_calculation_version = '2014AEG'
  elsif ['base-version-2019.xml'].include? hpxml_file
    hpxml.header.eri_calculation_version = '2019'
  elsif ['base-version-2019A.xml'].include? hpxml_file
    hpxml.header.eri_calculation_version = '2019A'
  elsif ['base-version-latest.xml'].include? hpxml_file
    hpxml.header.eri_calculation_version = 'latest'
  elsif ['base-misc-timestep-10-mins.xml'].include? hpxml_file
    hpxml.header.timestep = 10
  elsif ['base-misc-timestep-60-mins.xml'].include? hpxml_file
    hpxml.header.timestep = 60
  elsif ['invalid_files/invalid-timestep.xml'].include? hpxml_file
    hpxml.header.timestep = 45
  end
end

def set_hpxml_site(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.set_site(fuels: [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas])
  elsif ['base-hvac-none-no-fuel-access.xml'].include? hpxml_file
    hpxml.site.fuels = [HPXML::FuelTypeElectricity]
  end
end

def set_hpxml_neighbor_buildings(hpxml_file, hpxml)
  if ['base-site-neighbors.xml'].include? hpxml_file
    hpxml.neighbor_buildings.add(azimuth: 0,
                                 distance: 10)
    hpxml.neighbor_buildings.add(azimuth: 180,
                                 distance: 15,
                                 height: 12)
  elsif ['invalid_files/bad-site-neighbor-azimuth.xml'].include? hpxml_file
    hpxml.neighbor_buildings[0].azimuth = 145
  end
end

def set_hpxml_building_occupancy(hpxml_file, hpxml)
  if ['base-misc-number-of-occupants.xml'].include? hpxml_file
    hpxml.set_building_occupancy(number_of_residents: 5)
  end
end

def set_hpxml_building_construction(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.set_building_construction(number_of_conditioned_floors: 2,
                                    number_of_conditioned_floors_above_grade: 1,
                                    number_of_bedrooms: 3,
                                    conditioned_floor_area: 2700,
                                    conditioned_building_volume: 2700 * 8,
                                    fraction_of_operable_window_area: 0.33)
  elsif ['base-enclosure-beds-1.xml'].include? hpxml_file
    hpxml.building_construction.number_of_bedrooms = 1
  elsif ['base-enclosure-beds-2.xml'].include? hpxml_file
    hpxml.building_construction.number_of_bedrooms = 2
  elsif ['base-enclosure-beds-4.xml'].include? hpxml_file
    hpxml.building_construction.number_of_bedrooms = 4
  elsif ['base-enclosure-beds-5.xml'].include? hpxml_file
    hpxml.building_construction.number_of_bedrooms = 5
  elsif ['base-foundation-ambient.xml',
         'base-foundation-slab.xml',
         'base-foundation-unconditioned-basement.xml',
         'base-foundation-unvented-crawlspace.xml',
         'base-foundation-vented-crawlspace.xml'].include? hpxml_file
    hpxml.building_construction.number_of_conditioned_floors -= 1
    hpxml.building_construction.conditioned_floor_area -= 1350
    hpxml.building_construction.conditioned_building_volume -= 1350 * 8
  elsif ['base-hvac-ideal-air.xml'].include? hpxml_file
    hpxml.building_construction.use_only_ideal_air_system = true
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.building_construction.number_of_conditioned_floors += 1
    hpxml.building_construction.number_of_conditioned_floors_above_grade += 1
    hpxml.building_construction.conditioned_floor_area += 900
    hpxml.building_construction.conditioned_building_volume += 2250
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    hpxml.building_construction.conditioned_building_volume += 10800
  elsif ['base-enclosure-2stories.xml'].include? hpxml_file
    hpxml.building_construction.number_of_conditioned_floors += 1
    hpxml.building_construction.number_of_conditioned_floors_above_grade += 1
    hpxml.building_construction.conditioned_floor_area += 1350
    hpxml.building_construction.conditioned_building_volume += 1350 * 8
  elsif ['base-enclosure-windows-inoperable.xml'].include? hpxml_file
    hpxml.building_construction.fraction_of_operable_window_area = 0.0
  end
end

def set_hpxml_climate_and_risk_zones(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.set_climate_and_risk_zones(iecc2006: '5B',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Denver, CO',
                                     weather_station_wmo: '725650')
  elsif ['base-location-baltimore-md.xml'].include? hpxml_file
    hpxml.set_climate_and_risk_zones(iecc2006: '4A',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Baltimore, MD',
                                     weather_station_wmo: '724060')
  elsif ['base-location-dallas-tx.xml'].include? hpxml_file
    hpxml.set_climate_and_risk_zones(iecc2006: '3A',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Dallas, TX',
                                     weather_station_wmo: '722590')
  elsif ['base-location-duluth-mn.xml'].include? hpxml_file
    hpxml.set_climate_and_risk_zones(iecc2006: '7',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Duluth, MN',
                                     weather_station_wmo: '727450')
  elsif ['base-location-miami-fl.xml'].include? hpxml_file
    hpxml.set_climate_and_risk_zones(iecc2006: '1A',
                                     weather_station_id: 'WeatherStation',
                                     weather_station_name: 'Miami, FL',
                                     weather_station_wmo: '722020')
  elsif ['base-location-epw-filename.xml'].include? hpxml_file
    hpxml.climate_and_risk_zones.weather_station_wmo = nil
    hpxml.climate_and_risk_zones.weather_station_epw_filename = 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'
  elsif ['invalid_files/bad-wmo.xml'].include? hpxml_file
    hpxml.climate_and_risk_zones.weather_station_wmo = '999999'
  end
end

def set_hpxml_air_infiltration_measurements(hpxml_file, hpxml)
  infil_volume = hpxml.building_construction.conditioned_building_volume
  if ['base.xml'].include? hpxml_file
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            house_pressure: 50,
                                            unit_of_measure: HPXML::UnitsACH,
                                            air_leakage: 3.0)
  elsif ['base-infiltration-ach-natural.xml'].include? hpxml_file
    hpxml.air_infiltration_measurements.clear()
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            constant_ach_natural: 0.67)
  elsif ['base-enclosure-infil-cfm50.xml'].include? hpxml_file
    hpxml.air_infiltration_measurements.clear()
    hpxml.air_infiltration_measurements.add(id: 'InfiltrationMeasurement',
                                            house_pressure: 50,
                                            unit_of_measure: HPXML::UnitsCFM,
                                            air_leakage: 3.0 / 60.0 * infil_volume)
  end
  hpxml.air_infiltration_measurements[0].infiltration_volume = infil_volume
end

def set_hpxml_attics(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.attics.add(id: 'UnventedAttic',
                     attic_type: HPXML::AtticTypeUnvented,
                     within_infiltration_volume: false)
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    hpxml.attics.clear
    hpxml.attics.add(id: 'CathedralCeiling',
                     attic_type: HPXML::AtticTypeCathedral)
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.attics.add(id: 'ConditionedAttic',
                     attic_type: HPXML::AtticTypeConditioned)
  elsif ['base-atticroof-flat.xml'].include? hpxml_file
    hpxml.attics.clear
    hpxml.attics.add(id: 'FlatRoof',
                     attic_type: HPXML::AtticTypeFlatRoof)
  elsif ['base-enclosure-adiabatic-surfaces.xml'].include? hpxml_file
    hpxml.attics.clear
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    hpxml.attics.clear
    hpxml.attics.add(id: 'VentedAttic',
                     attic_type: HPXML::AtticTypeVented,
                     vented_attic_sla: 0.003)
  end
end

def set_hpxml_foundations(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.foundations.add(id: 'ConditionedBasement',
                          foundation_type: HPXML::FoundationTypeBasementConditioned)
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    hpxml.foundations.clear
    hpxml.foundations.add(id: 'VentedCrawlspace',
                          foundation_type: HPXML::FoundationTypeCrawlspaceVented,
                          vented_crawlspace_sla: 0.00667)
  elsif ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
    hpxml.foundations.clear
    hpxml.foundations.add(id: 'UnventedCrawlspace',
                          foundation_type: HPXML::FoundationTypeCrawlspaceUnvented,
                          within_infiltration_volume: false)
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    hpxml.foundations.clear
    hpxml.foundations.add(id: 'UnconditionedBasement',
                          foundation_type: HPXML::FoundationTypeBasementUnconditioned,
                          unconditioned_basement_thermal_boundary: HPXML::FoundationThermalBoundaryFloor,
                          within_infiltration_volume: false)
  elsif ['base-foundation-unconditioned-basement-wall-insulation.xml'].include? hpxml_file
    hpxml.foundations[0].unconditioned_basement_thermal_boundary = HPXML::FoundationThermalBoundaryWall
  elsif ['base-foundation-multiple.xml'].include? hpxml_file
    hpxml.foundations.add(id: 'UnventedCrawlspace',
                          foundation_type: HPXML::FoundationTypeCrawlspaceUnvented,
                          within_infiltration_volume: false)
  elsif ['base-foundation-ambient.xml'].include? hpxml_file
    hpxml.foundations.clear
    hpxml.foundations.add(id: 'AmbientFoundation',
                          foundation_type: HPXML::FoundationTypeAmbient)
  elsif ['base-foundation-slab.xml'].include? hpxml_file
    hpxml.foundations.clear
    hpxml.foundations.add(id: 'SlabFoundation',
                          foundation_type: HPXML::FoundationTypeSlab)
  end
end

def set_hpxml_roofs(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.roofs.add(id: 'Roof',
                    interior_adjacent_to: HPXML::LocationAtticUnvented,
                    area: 1510,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    pitch: 6,
                    radiant_barrier: false,
                    insulation_assembly_r_value: 2.3)
  elsif ['base-atticroof-flat.xml'].include? hpxml_file
    hpxml.roofs.clear()
    hpxml.roofs.add(id: 'Roof',
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    area: 1350,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    pitch: 0,
                    radiant_barrier: false,
                    insulation_assembly_r_value: 25.8)
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.roofs.clear()
    hpxml.roofs.add(id: 'RoofCond',
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    area: 1006,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    pitch: 6,
                    radiant_barrier: false,
                    insulation_assembly_r_value: 25.8)
    hpxml.roofs.add(id: 'RoofUncond',
                    interior_adjacent_to: HPXML::LocationAtticUnvented,
                    area: 504,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    pitch: 6,
                    radiant_barrier: false,
                    insulation_assembly_r_value: 2.3)
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    hpxml.roofs[0].interior_adjacent_to = HPXML::LocationAtticVented
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    hpxml.roofs[0].interior_adjacent_to = HPXML::LocationLivingSpace
    hpxml.roofs[0].insulation_assembly_r_value = 25.8
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    hpxml.roofs.add(id: 'RoofGarage',
                    interior_adjacent_to: HPXML::LocationGarage,
                    area: 670,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    pitch: 6,
                    radiant_barrier: false,
                    insulation_assembly_r_value: 2.3)
  elsif ['base-atticroof-unvented-insulated-roof.xml'].include? hpxml_file
    hpxml.roofs[0].insulation_assembly_r_value = 25.8
  elsif ['base-enclosure-adiabatic-surfaces.xml'].include? hpxml_file
    hpxml.roofs.clear()
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..hpxml.roofs.size
      hpxml.roofs[n - 1].area /= 10.0
      for i in 2..10
        hpxml.roofs << hpxml.roofs[n - 1].dup
        hpxml.roofs[-1].id += i.to_s
      end
    end
  elsif ['base-atticroof-radiant-barrier.xml'].include? hpxml_file
    hpxml.roofs[0].radiant_barrier = true
  end
end

def set_hpxml_rim_joists(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    # TODO: Other geometry values (e.g., building volume) assume
    # no rim joists.
    hpxml.rim_joists.add(id: 'RimJoistFoundation',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationBasementConditioned,
                         area: 116,
                         solar_absorptance: 0.7,
                         emittance: 0.92,
                         insulation_assembly_r_value: 23.0)
  elsif ['base-foundation-ambient.xml',
         'base-foundation-slab.xml'].include? hpxml_file
    hpxml.rim_joists.clear()
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    for i in 0..hpxml.rim_joists.size - 1
      hpxml.rim_joists[i].interior_adjacent_to = HPXML::LocationBasementUnconditioned
      hpxml.rim_joists[i].insulation_assembly_r_value = 2.3
    end
  elsif ['base-foundation-unconditioned-basement-wall-insulation.xml'].include? hpxml_file
    for i in 0..hpxml.rim_joists.size - 1
      hpxml.rim_joists[i].insulation_assembly_r_value = 23.0
    end
  elsif ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
    for i in 0..hpxml.rim_joists.size - 1
      hpxml.rim_joists[i].interior_adjacent_to = HPXML::LocationCrawlspaceUnvented
    end
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    for i in 0..hpxml.rim_joists.size - 1
      hpxml.rim_joists[i].interior_adjacent_to = HPXML::LocationCrawlspaceVented
    end
  elsif ['base-foundation-multiple.xml'].include? hpxml_file
    hpxml.rim_joists[0].exterior_adjacent_to = HPXML::LocationCrawlspaceUnvented
    hpxml.rim_joists.add(id: 'RimJoistCrawlspace',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                         area: 81,
                         solar_absorptance: 0.7,
                         emittance: 0.92,
                         insulation_assembly_r_value: 2.3)
  elsif ['base-enclosure-2stories.xml'].include? hpxml_file
    hpxml.rim_joists.add(id: 'RimJoist2ndStory',
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationLivingSpace,
                         area: 116,
                         solar_absorptance: 0.7,
                         emittance: 0.92,
                         insulation_assembly_r_value: 23.0)
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..hpxml.rim_joists.size
      hpxml.rim_joists[n - 1].area /= 10.0
      for i in 2..10
        hpxml.rim_joists << hpxml.rim_joists[n - 1].dup
        hpxml.rim_joists[-1].id += i.to_s
      end
    end
  end
end

def set_hpxml_walls(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.walls.add(id: 'Wall',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 1200,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 23)
    hpxml.walls.add(id: 'WallAtticGable',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationAtticUnvented,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 290,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 4.0)
  elsif ['base-atticroof-flat.xml'].include? hpxml_file
    hpxml.walls.delete_at(1)
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    hpxml.walls[1].interior_adjacent_to = HPXML::LocationAtticVented
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    hpxml.walls[1].interior_adjacent_to = HPXML::LocationLivingSpace
    hpxml.walls[1].insulation_assembly_r_value = 23.0
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.walls.delete_at(1)
    hpxml.walls.add(id: 'WallAtticKneeWall',
                    exterior_adjacent_to: HPXML::LocationAtticUnvented,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 316,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 23.0)
    hpxml.walls.add(id: 'WallAtticGableCond',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 240,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 22.3)
    hpxml.walls.add(id: 'WallAtticGableUncond',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationAtticUnvented,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 50,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 4.0)
  elsif ['base-enclosure-walltype-cmu.xml'].include? hpxml_file
    hpxml.walls[0].wall_type = HPXML::WallTypeCMU
    hpxml.walls[0].insulation_assembly_r_value = 12
  elsif ['base-enclosure-walltype-doublestud.xml'].include? hpxml_file
    hpxml.walls[0].wall_type = HPXML::WallTypeDoubleWoodStud
    hpxml.walls[0].insulation_assembly_r_value = 28.7
  elsif ['base-enclosure-walltype-icf.xml'].include? hpxml_file
    hpxml.walls[0].wall_type = HPXML::WallTypeICF
    hpxml.walls[0].insulation_assembly_r_value = 21
  elsif ['base-enclosure-walltype-log.xml'].include? hpxml_file
    hpxml.walls[0].wall_type = HPXML::WallTypeLog
    hpxml.walls[0].insulation_assembly_r_value = 7.1
  elsif ['base-enclosure-walltype-sip.xml'].include? hpxml_file
    hpxml.walls[0].wall_type = HPXML::WallTypeSIP
    hpxml.walls[0].insulation_assembly_r_value = 16.1
  elsif ['base-enclosure-walltype-solidconcrete.xml'].include? hpxml_file
    hpxml.walls[0].wall_type = HPXML::WallTypeConcrete
    hpxml.walls[0].insulation_assembly_r_value = 1.35
  elsif ['base-enclosure-walltype-steelstud.xml'].include? hpxml_file
    hpxml.walls[0].wall_type = HPXML::WallTypeSteelStud
    hpxml.walls[0].insulation_assembly_r_value = 8.1
  elsif ['base-enclosure-walltype-stone.xml'].include? hpxml_file
    hpxml.walls[0].wall_type = HPXML::WallTypeStone
    hpxml.walls[0].insulation_assembly_r_value = 5.4
  elsif ['base-enclosure-walltype-strawbale.xml'].include? hpxml_file
    hpxml.walls[0].wall_type = HPXML::WallTypeStrawBale
    hpxml.walls[0].insulation_assembly_r_value = 58.8
  elsif ['base-enclosure-walltype-structuralbrick.xml'].include? hpxml_file
    hpxml.walls[0].wall_type = HPXML::WallTypeBrick
    hpxml.walls[0].insulation_assembly_r_value = 7.9
  elsif ['invalid_files/missing-surfaces.xml'].include? hpxml_file
    hpxml.walls.add(id: 'WallGarage',
                    exterior_adjacent_to: HPXML::LocationGarage,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 100,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 4)
  elsif ['base-enclosure-2stories.xml'].include? hpxml_file
    hpxml.walls[0].area *= 2.0
  elsif ['base-enclosure-2stories-garage.xml'].include? hpxml_file
    hpxml.walls.clear()
    hpxml.walls.add(id: 'Wall',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 880,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 23)
    hpxml.walls.add(id: 'WallGarageInterior',
                    exterior_adjacent_to: HPXML::LocationGarage,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 320,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 23)
    hpxml.walls.add(id: 'WallGarageExterior',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationGarage,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 800,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 4)
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    hpxml.walls.clear()
    hpxml.walls.add(id: 'Wall',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 960,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 23)
    hpxml.walls.add(id: 'WallGarageInterior',
                    exterior_adjacent_to: HPXML::LocationGarage,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 240,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 23)
    hpxml.walls.add(id: 'WallGarageExterior',
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationGarage,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 560,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 4)
  elsif ['base-atticroof-unvented-insulated-roof.xml'].include? hpxml_file
    hpxml.walls[1].insulation_assembly_r_value = 23
  elsif ['base-enclosure-adiabatic-surfaces.xml'].include? hpxml_file
    hpxml.walls.delete_at(1)
    hpxml.walls << hpxml.walls[0].dup
    hpxml.walls[0].area *= 0.35
    hpxml.walls[-1].area *= 0.65
    hpxml.walls[-1].id += 'Adiabatic'
    hpxml.walls[-1].exterior_adjacent_to = HPXML::LocationOtherHousingUnit
    hpxml.walls[-1].insulation_assembly_r_value = 4
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..hpxml.walls.size
      hpxml.walls[n - 1].area /= 10.0
      for i in 2..10
        hpxml.walls << hpxml.walls[n - 1].dup
        hpxml.walls[-1].id += i.to_s
      end
    end
  elsif ['invalid_files/duplicate-id.xml'].include? hpxml_file
    hpxml.walls[-1].id = hpxml.walls[0].id
  end
end

def set_hpxml_foundation_walls(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml. foundation_walls.add(id: 'FoundationWall',
                                exterior_adjacent_to: HPXML::LocationGround,
                                interior_adjacent_to: HPXML::LocationBasementConditioned,
                                height: 8,
                                area: 1200,
                                thickness: 8,
                                depth_below_grade: 7,
                                insulation_interior_r_value: 0,
                                insulation_interior_distance_to_top: 0,
                                insulation_interior_distance_to_bottom: 0,
                                insulation_exterior_distance_to_top: 0,
                                insulation_exterior_distance_to_bottom: 8,
                                insulation_exterior_r_value: 8.9)
  elsif ['base-foundation-conditioned-basement-wall-interior-insulation.xml'].include? hpxml_file
    hpxml.foundation_walls[0].insulation_interior_distance_to_top = 0
    hpxml.foundation_walls[0].insulation_interior_distance_to_bottom = 8
    hpxml.foundation_walls[0].insulation_interior_r_value = 10
    hpxml.foundation_walls[0].insulation_exterior_distance_to_top = 1
    hpxml.foundation_walls[0].insulation_exterior_distance_to_bottom = 8
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    hpxml.foundation_walls[0].interior_adjacent_to = HPXML::LocationBasementUnconditioned
    hpxml.foundation_walls[0].insulation_exterior_distance_to_bottom = 0
    hpxml.foundation_walls[0].insulation_exterior_r_value = 0
  elsif ['base-foundation-unconditioned-basement-wall-insulation.xml'].include? hpxml_file
    hpxml.foundation_walls[0].insulation_exterior_distance_to_bottom = 4
    hpxml.foundation_walls[0].insulation_exterior_r_value = 8.9
  elsif ['base-foundation-unconditioned-basement-assembly-r.xml'].include? hpxml_file
    hpxml.foundation_walls[0].insulation_exterior_distance_to_top = nil
    hpxml.foundation_walls[0].insulation_exterior_distance_to_bottom = nil
    hpxml.foundation_walls[0].insulation_exterior_r_value = nil
    hpxml.foundation_walls[0].insulation_interior_distance_to_top = nil
    hpxml.foundation_walls[0].insulation_interior_distance_to_bottom = nil
    hpxml.foundation_walls[0].insulation_interior_r_value = nil
    hpxml.foundation_walls[0].insulation_assembly_r_value = 10.69
  elsif ['base-foundation-unconditioned-basement-above-grade.xml'].include? hpxml_file
    hpxml.foundation_walls[0].depth_below_grade = 4
  elsif ['base-foundation-unvented-crawlspace.xml',
         'base-foundation-vented-crawlspace.xml'].include? hpxml_file
    if ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
      hpxml.foundation_walls[0].interior_adjacent_to = HPXML::LocationCrawlspaceUnvented
    else
      hpxml.foundation_walls[0].interior_adjacent_to = HPXML::LocationCrawlspaceVented
    end
    hpxml.foundation_walls[0].height -= 4
    hpxml.foundation_walls[0].area /= 2.0
    hpxml.foundation_walls[0].depth_below_grade -= 4
    hpxml.foundation_walls[0].insulation_exterior_distance_to_bottom -= 4
  elsif ['base-foundation-multiple.xml'].include? hpxml_file
    hpxml.foundation_walls[0].area = 600
    hpxml.foundation_walls.add(id: 'FoundationWallInterior',
                               exterior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                               interior_adjacent_to: HPXML::LocationBasementUnconditioned,
                               height: 8,
                               area: 360,
                               thickness: 8,
                               depth_below_grade: 4,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0)
    hpxml.foundation_walls.add(id: 'FoundationWallCrawlspace',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                               height: 4,
                               area: 600,
                               thickness: 8,
                               depth_below_grade: 3,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0)
  elsif ['base-foundation-ambient.xml',
         'base-foundation-slab.xml'].include? hpxml_file
    hpxml.foundation_walls.clear()
  elsif ['base-foundation-walkout-basement.xml'].include? hpxml_file
    hpxml.foundation_walls.clear()
    hpxml.foundation_walls.add(id: 'FoundationWall1',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 8,
                               area: 480,
                               thickness: 8,
                               depth_below_grade: 7,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 8,
                               insulation_exterior_r_value: 8.9)
    hpxml.foundation_walls.add(id: 'FoundationWall2',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 4,
                               area: 120,
                               thickness: 8,
                               depth_below_grade: 3,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 4,
                               insulation_exterior_r_value: 8.9)
    hpxml.foundation_walls.add(id: 'FoundationWall3',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 2,
                               area: 60,
                               thickness: 8,
                               depth_below_grade: 1,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 2,
                               insulation_exterior_r_value: 8.9)
  elsif ['base-foundation-complex.xml'].include? hpxml_file
    hpxml.foundation_walls.clear()
    hpxml.foundation_walls.add(id: 'FoundationWall1',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 8,
                               area: 160,
                               thickness: 8,
                               depth_below_grade: 7,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0.0)
    hpxml.foundation_walls.add(id: 'FoundationWall2',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 8,
                               area: 240,
                               thickness: 8,
                               depth_below_grade: 7,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 8,
                               insulation_exterior_r_value: 8.9)
    hpxml.foundation_walls.add(id: 'FoundationWall3',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 4,
                               area: 160,
                               thickness: 8,
                               depth_below_grade: 3,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 0,
                               insulation_exterior_r_value: 0.0)
    hpxml.foundation_walls.add(id: 'FoundationWall4',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 4,
                               area: 120,
                               thickness: 8,
                               depth_below_grade: 3,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 4,
                               insulation_exterior_r_value: 8.9)
    hpxml.foundation_walls.add(id: 'FoundationWall5',
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 4,
                               area: 80,
                               thickness: 8,
                               depth_below_grade: 3,
                               insulation_interior_r_value: 0,
                               insulation_interior_distance_to_top: 0,
                               insulation_interior_distance_to_bottom: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 4,
                               insulation_exterior_r_value: 8.9)
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..hpxml.foundation_walls.size
      hpxml.foundation_walls[n - 1].area /= 10.0
      for i in 2..10
        hpxml.foundation_walls << hpxml.foundation_walls[n - 1].dup
        hpxml.foundation_walls[-1].id += i.to_s
      end
    end
  elsif ['invalid_files/mismatched-slab-and-foundation-wall.xml'].include? hpxml_file
    hpxml.foundation_walls << hpxml.foundation_walls[0].dup
    hpxml.foundation_walls[1].id = 'FoundationWall2'
    hpxml.foundation_walls[1].interior_adjacent_to = HPXML::LocationGarage
  end
end

def set_hpxml_frame_floors(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.frame_floors.add(id: 'FloorBelowAttic',
                           exterior_adjacent_to: HPXML::LocationAtticUnvented,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1350,
                           insulation_assembly_r_value: 39.3)
  elsif ['base-atticroof-flat.xml',
         'base-atticroof-cathedral.xml'].include? hpxml_file
    hpxml.frame_floors.delete_at(0)
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    hpxml.frame_floors[0].exterior_adjacent_to = HPXML::LocationAtticVented
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.frame_floors[0].area = 450
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    hpxml.frame_floors.add(id: 'FloorBetweenAtticGarage',
                           exterior_adjacent_to: HPXML::LocationAtticUnvented,
                           interior_adjacent_to: HPXML::LocationGarage,
                           area: 600,
                           insulation_assembly_r_value: 2.1)
  elsif ['base-foundation-ambient.xml'].include? hpxml_file
    hpxml.frame_floors.add(id: 'FloorAboveAmbient',
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1350,
                           insulation_assembly_r_value: 18.7)
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    hpxml.frame_floors.add(id: 'FloorAboveUncondBasement',
                           exterior_adjacent_to: HPXML::LocationBasementUnconditioned,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1350,
                           insulation_assembly_r_value: 18.7)
  elsif ['base-foundation-unconditioned-basement-wall-insulation.xml'].include? hpxml_file
    hpxml.frame_floors[1].insulation_assembly_r_value = 2.1
  elsif ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
    hpxml.frame_floors.add(id: 'FloorAboveUnventedCrawl',
                           exterior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1350,
                           insulation_assembly_r_value: 18.7)
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    hpxml.frame_floors.add(id: 'FloorAboveVentedCrawl',
                           exterior_adjacent_to: HPXML::LocationCrawlspaceVented,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1350,
                           insulation_assembly_r_value: 18.7)
  elsif ['base-foundation-multiple.xml'].include? hpxml_file
    hpxml.frame_floors[1].area = 675
    hpxml.frame_floors.add(id: 'FloorAboveUnventedCrawlspace',
                           exterior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 675,
                           insulation_assembly_r_value: 18.7)
  elsif ['base-enclosure-2stories-garage.xml'].include? hpxml_file
    hpxml.frame_floors.add(id: 'FloorAboveGarage',
                           exterior_adjacent_to: HPXML::LocationGarage,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 400,
                           insulation_assembly_r_value: 18.7)
  elsif ['base-atticroof-unvented-insulated-roof.xml'].include? hpxml_file
    hpxml.frame_floors[0].insulation_assembly_r_value = 2.1
  elsif ['base-enclosure-adiabatic-surfaces.xml'].include? hpxml_file
    hpxml.frame_floors.clear()
    hpxml.frame_floors.add(id: 'FloorAboveAdiabatic',
                           exterior_adjacent_to: HPXML::LocationOtherHousingUnitBelow,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1350,
                           insulation_assembly_r_value: 2.1)
    hpxml.frame_floors.add(id: 'FloorBelowAdiabatic',
                           exterior_adjacent_to: HPXML::LocationOtherHousingUnitAbove,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 1350,
                           insulation_assembly_r_value: 2.1)
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..hpxml.frame_floors.size
      hpxml.frame_floors[n - 1].area /= 10.0
      for i in 2..10
        hpxml.frame_floors << hpxml.frame_floors[n - 1].dup
        hpxml.frame_floors[-1].id += i.to_s
      end
    end
  end
end

def set_hpxml_slabs(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.slabs.add(id: 'Slab',
                    interior_adjacent_to: HPXML::LocationBasementConditioned,
                    area: 1350,
                    thickness: 4,
                    exposed_perimeter: 150,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    hpxml.slabs[0].interior_adjacent_to = HPXML::LocationBasementUnconditioned
  elsif ['base-foundation-conditioned-basement-slab-insulation.xml'].include? hpxml_file
    hpxml.slabs[0].under_slab_insulation_width = 4
    hpxml.slabs[0].under_slab_insulation_r_value = 10
  elsif ['base-foundation-slab.xml'].include? hpxml_file
    hpxml.slabs[0].interior_adjacent_to = HPXML::LocationLivingSpace
    hpxml.slabs[0].under_slab_insulation_width = nil
    hpxml.slabs[0].under_slab_insulation_spans_entire_slab = true
    hpxml.slabs[0].depth_below_grade = 0
    hpxml.slabs[0].under_slab_insulation_r_value = 5
    hpxml.slabs[0].carpet_fraction = 1
    hpxml.slabs[0].carpet_r_value = 2.5
  elsif ['base-foundation-unvented-crawlspace.xml',
         'base-foundation-vented-crawlspace.xml'].include? hpxml_file
    if ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
      hpxml.slabs[0].interior_adjacent_to = HPXML::LocationCrawlspaceUnvented
    else
      hpxml.slabs[0].interior_adjacent_to = HPXML::LocationCrawlspaceVented
    end
    hpxml.slabs[0].thickness = 0
    hpxml.slabs[0].carpet_r_value = 2.5
  elsif ['base-foundation-multiple.xml'].include? hpxml_file
    hpxml.slabs[0].area = 675
    hpxml.slabs[0].exposed_perimeter = 75
    hpxml.slabs.add(id: 'SlabUnderCrawlspace',
                    interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                    area: 675,
                    thickness: 0,
                    exposed_perimeter: 75,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
  elsif ['base-foundation-ambient.xml'].include? hpxml_file
    hpxml.slabs.clear()
  elsif ['base-enclosure-2stories-garage.xml'].include? hpxml_file
    hpxml.slabs[0].area -= 400
    hpxml.slabs[0].exposed_perimeter -= 40
    hpxml.slabs.add(id: 'SlabUnderGarage',
                    interior_adjacent_to: HPXML::LocationGarage,
                    area: 400,
                    thickness: 4,
                    exposed_perimeter: 40,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    depth_below_grade: 0,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    hpxml.slabs[0].exposed_perimeter -= 30
    hpxml.slabs.add(id: 'SlabUnderGarage',
                    interior_adjacent_to: HPXML::LocationGarage,
                    area: 600,
                    thickness: 4,
                    exposed_perimeter: 70,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    depth_below_grade: 0,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
  elsif ['base-foundation-complex.xml'].include? hpxml_file
    hpxml.slabs.clear()
    hpxml.slabs.add(id: 'Slab1',
                    interior_adjacent_to: HPXML::LocationBasementConditioned,
                    area: 675,
                    thickness: 4,
                    exposed_perimeter: 75,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
    hpxml.slabs.add(id: 'Slab2',
                    interior_adjacent_to: HPXML::LocationBasementConditioned,
                    area: 405,
                    thickness: 4,
                    exposed_perimeter: 45,
                    perimeter_insulation_depth: 1,
                    under_slab_insulation_width: 0,
                    perimeter_insulation_r_value: 5,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
    hpxml.slabs.add(id: 'Slab3',
                    interior_adjacent_to: HPXML::LocationBasementConditioned,
                    area: 270,
                    thickness: 4,
                    exposed_perimeter: 30,
                    perimeter_insulation_depth: 1,
                    under_slab_insulation_width: 0,
                    perimeter_insulation_r_value: 5,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..hpxml.slabs.size
      hpxml.slabs[n - 1].area /= 10.0
      hpxml.slabs[n - 1].exposed_perimeter /= 10.0
      for i in 2..10
        hpxml.slabs << hpxml.slabs[n - 1].dup
        hpxml.slabs[-1].id += i.to_s
      end
    end
  elsif ['invalid_files/mismatched-slab-and-foundation-wall.xml'].include? hpxml_file
    hpxml.slabs[0].interior_adjacent_to = HPXML::LocationBasementUnconditioned
    hpxml.slabs[0].depth_below_grade = 7.0
  elsif ['invalid_files/slab-zero-exposed-perimeter.xml'].include? hpxml_file
    hpxml.slabs[0].exposed_perimeter = 0
  end
end

def set_hpxml_windows(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.windows.add(id: 'WindowNorth',
                      area: 108,
                      azimuth: 0,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'Wall')
    hpxml.windows.add(id: 'WindowSouth',
                      area: 108,
                      azimuth: 180,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'Wall')
    hpxml.windows.add(id: 'WindowEast',
                      area: 72,
                      azimuth: 90,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'Wall')
    hpxml.windows.add(id: 'WindowWest',
                      area: 72,
                      azimuth: 270,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'Wall')
  elsif ['base-enclosure-overhangs.xml'].include? hpxml_file
    hpxml.windows[0].overhangs_depth = 2.5
    hpxml.windows[0].overhangs_distance_to_top_of_window = 0
    hpxml.windows[0].overhangs_distance_to_bottom_of_window = 4
    hpxml.windows[2].overhangs_depth = 1.5
    hpxml.windows[2].overhangs_distance_to_top_of_window = 2
    hpxml.windows[2].overhangs_distance_to_bottom_of_window = 6
    hpxml.windows[3].overhangs_depth = 1.5
    hpxml.windows[3].overhangs_distance_to_top_of_window = 2
    hpxml.windows[3].overhangs_distance_to_bottom_of_window = 7
  elsif ['base-enclosure-windows-interior-shading.xml'].include? hpxml_file
    hpxml.windows[0].interior_shading_factor_summer = 0.7
    hpxml.windows[0].interior_shading_factor_winter = 0.85
    hpxml.windows[1].interior_shading_factor_summer = 0.01
    hpxml.windows[1].interior_shading_factor_winter = 0.99
    hpxml.windows[2].interior_shading_factor_summer = 0.0
    hpxml.windows[2].interior_shading_factor_winter = 0.5
    hpxml.windows[3].interior_shading_factor_summer = 1.0
    hpxml.windows[3].interior_shading_factor_winter = 1.0
  elsif ['invalid_files/invalid-window-interior-shading.xml'].include? hpxml_file
    hpxml.windows[0].interior_shading_factor_summer = 0.85
    hpxml.windows[0].interior_shading_factor_winter = 0.7
  elsif ['base-enclosure-windows-none.xml'].include? hpxml_file
    hpxml.windows.clear()
  elsif ['invalid_files/net-area-negative-wall.xml'].include? hpxml_file
    hpxml.windows[0].area = 1000
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.windows[0].area = 108
    hpxml.windows[1].area = 108
    hpxml.windows[2].area = 108
    hpxml.windows[3].area = 108
    hpxml.windows.add(id: 'AtticGableWindowEast',
                      area: 12,
                      azimuth: 90,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'WallAtticGableCond')
    hpxml.windows.add(id: 'AtticGableWindowWest',
                      area: 62,
                      azimuth: 270,
                      ufactor: 0.3,
                      shgc: 0.45,
                      wall_idref: 'WallAtticGableCond')
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    hpxml.windows[0].area = 108
    hpxml.windows[1].area = 108
    hpxml.windows[2].area = 108
    hpxml.windows[3].area = 108
    hpxml.windows.add(id: 'AtticGableWindowEast',
                      area: 12,
                      azimuth: 90,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'WallAtticGable')
    hpxml.windows.add(id: 'AtticGableWindowWest',
                      area: 12,
                      azimuth: 270,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'WallAtticGable')
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    hpxml.windows.delete_at(2)
    hpxml.windows.add(id: 'GarageWindowEast',
                      area: 12,
                      azimuth: 90,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'WallGarageExterior')
  elsif ['base-enclosure-2stories.xml'].include? hpxml_file
    hpxml.windows[0].area = 216
    hpxml.windows[1].area = 216
    hpxml.windows[2].area = 144
    hpxml.windows[3].area = 144
  elsif ['base-enclosure-2stories-garage'].include? hpxml_file
    hpxml.windows[0].area = 168
    hpxml.windows[1].area = 216
    hpxml.windows[2].area = 144
    hpxml.windows[3].area = 96
  elsif ['base-foundation-unconditioned-basement-above-grade.xml'].include? hpxml_file
    hpxml.windows.add(id: 'FoundationWindowNorth',
                      area: 20,
                      azimuth: 0,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'FoundationWall')
    hpxml.windows.add(id: 'FoundationWindowSouth',
                      area: 20,
                      azimuth: 180,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'FoundationWall')
    hpxml.windows.add(id: 'FoundationWindowEast',
                      area: 10,
                      azimuth: 90,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'FoundationWall')
    hpxml.windows.add(id: 'FoundationWindowWest',
                      area: 10,
                      azimuth: 270,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'FoundationWall')
  elsif ['base-enclosure-adiabatic-surfaces.xml'].include? hpxml_file
    for n in 1..hpxml.windows.size
      hpxml.windows[n - 1].area *= 0.35
    end
  elsif ['invalid_files/unattached-window.xml'].include? hpxml_file
    hpxml.windows[0].wall_idref = 'foobar'
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    area_adjustments = []
    for n in 1..hpxml.windows.size
      hpxml.windows[n - 1].area /= 10.0
      for i in 2..10
        hpxml.windows << hpxml.windows[n - 1].dup
        hpxml.windows[-1].id += i.to_s
        hpxml.windows[-1].wall_idref += i.to_s
      end
    end
  elsif ['base-foundation-walkout-basement.xml'].include? hpxml_file
    hpxml.windows.add(id: 'FoundationWindow',
                      area: 20,
                      azimuth: 0,
                      ufactor: 0.33,
                      shgc: 0.45,
                      wall_idref: 'FoundationWall3')
  elsif ['invalid_files/invalid-window-height.xml'].include? hpxml_file
    hpxml.windows[2].overhangs_distance_to_bottom_of_window = hpxml.windows[2].overhangs_distance_to_top_of_window
  end
end

def set_hpxml_skylights(hpxml_file, hpxml)
  if ['base-enclosure-skylights.xml'].include? hpxml_file
    hpxml.skylights.add(id: 'SkylightNorth',
                        area: 45,
                        azimuth: 0,
                        ufactor: 0.33,
                        shgc: 0.45,
                        roof_idref: 'Roof')
    hpxml.skylights.add(id: 'SkylightSouth',
                        area: 45,
                        azimuth: 180,
                        ufactor: 0.35,
                        shgc: 0.47,
                        roof_idref: 'Roof')
  elsif ['invalid_files/net-area-negative-roof.xml'].include? hpxml_file
    hpxml.skylights[0].area = 4000
  elsif ['invalid_files/unattached-skylight.xml'].include? hpxml_file
    hpxml.skylights[0].roof_idref = 'foobar'
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    for n in 1..hpxml.skylights.size
      hpxml.skylights[n - 1].area /= 10.0
      for i in 2..10
        hpxml.skylights << hpxml.skylights[n - 1].dup
        hpxml.skylights[-1].id += i.to_s
        hpxml.skylights[-1].roof_idref += i.to_s if i % 2 == 0
      end
    end
  end
end

def set_hpxml_doors(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.doors.add(id: 'DoorNorth',
                    wall_idref: 'Wall',
                    area: 40,
                    azimuth: 0,
                    r_value: 4.4)
    hpxml.doors.add(id: 'DoorSouth',
                    wall_idref: 'Wall',
                    area: 40,
                    azimuth: 180,
                    r_value: 4.4)
  elsif ['base-enclosure-garage.xml',
         'base-enclosure-2stories-garage.xml'].include? hpxml_file
    hpxml.doors.add(id: 'GarageDoorSouth',
                    wall_idref: 'WallGarageExterior',
                    area: 70,
                    azimuth: 180,
                    r_value: 4.4)
  elsif ['invalid_files/unattached-door.xml'].include? hpxml_file
    hpxml.doors[0].wall_idref = 'foobar'
  elsif ['base-enclosure-split-surfaces.xml'].include? hpxml_file
    area_adjustments = []
    for n in 1..hpxml.doors.size
      hpxml.doors[n - 1].area /= 10.0
      for i in 2..10
        hpxml.doors << hpxml.doors[n - 1].dup
        hpxml.doors[-1].id += i.to_s
        hpxml.doors[-1].wall_idref += i.to_s
      end
    end
  end
end

def set_hpxml_heating_systems(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.heating_systems.add(id: 'HeatingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 64000,
                              heating_efficiency_afue: 0.92,
                              fraction_heat_load_served: 1)
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
    hpxml.heating_systems.clear()
  elsif ['base-hvac-boiler-elec-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeBoiler
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
    hpxml.heating_systems[0].heating_efficiency_afue = 1
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.xml',
         'base-hvac-boiler-gas-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeBoiler
    hpxml.heating_systems[0].electric_auxiliary_energy = 200
  elsif ['base-hvac-boiler-oil-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeBoiler
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeOil
  elsif ['base-hvac-boiler-propane-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeBoiler
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypePropane
  elsif ['base-hvac-boiler-wood-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeBoiler
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeWood
  elsif ['base-hvac-elec-resistance-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].distribution_system_idref = nil
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeElectricResistance
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
    hpxml.heating_systems[0].heating_efficiency_afue = nil
    hpxml.heating_systems[0].heating_efficiency_percent = 1
  elsif ['base-hvac-furnace-elec-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
    hpxml.heating_systems[0].heating_efficiency_afue = 1
  elsif ['base-hvac-furnace-gas-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].electric_auxiliary_energy = 700
  elsif ['base-hvac-furnace-gas-only-no-eae.xml',
         'base-hvac-boiler-gas-only-no-eae.xml',
         'base-hvac-stove-oil-only-no-eae.xml',
         'base-hvac-wall-furnace-propane-only-no-eae.xml'].include? hpxml_file
    hpxml.heating_systems[0].electric_auxiliary_energy = nil
  elsif ['base-hvac-furnace-oil-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeOil
  elsif ['base-hvac-furnace-propane-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypePropane
  elsif ['base-hvac-furnace-wood-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeWood
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeBoiler
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
    hpxml.heating_systems[0].heating_efficiency_afue = 1
    hpxml.heating_systems[0].fraction_heat_load_served = 0.1
    hpxml.heating_systems[0].heating_capacity *= 0.1
    hpxml.heating_systems.add(id: 'HeatingSystem2',
                              distribution_system_idref: 'HVACDistribution2',
                              heating_system_type: HPXML::HVACTypeBoiler,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 6400,
                              heating_efficiency_afue: 0.92,
                              fraction_heat_load_served: 0.1,
                              electric_auxiliary_energy: 200)
    hpxml.heating_systems.add(id: 'HeatingSystem3',
                              heating_system_type: HPXML::HVACTypeElectricResistance,
                              heating_system_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: 6400,
                              heating_efficiency_percent: 1,
                              fraction_heat_load_served: 0.1)
    hpxml.heating_systems.add(id: 'HeatingSystem4',
                              distribution_system_idref: 'HVACDistribution3',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: 6400,
                              heating_efficiency_afue: 1,
                              fraction_heat_load_served: 0.1)
    hpxml.heating_systems.add(id: 'HeatingSystem5',
                              distribution_system_idref: 'HVACDistribution4',
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 6400,
                              heating_efficiency_afue: 0.92,
                              fraction_heat_load_served: 0.1,
                              electric_auxiliary_energy: 700)
    hpxml.heating_systems.add(id: 'HeatingSystem6',
                              heating_system_type: HPXML::HVACTypeStove,
                              heating_system_fuel: HPXML::FuelTypeOil,
                              heating_capacity: 6400,
                              heating_efficiency_percent: 0.8,
                              fraction_heat_load_served: 0.1,
                              electric_auxiliary_energy: 200)
    hpxml.heating_systems.add(id: 'HeatingSystem7',
                              heating_system_type: HPXML::HVACTypeWallFurnace,
                              heating_system_fuel: HPXML::FuelTypePropane,
                              heating_capacity: 6400,
                              heating_efficiency_afue: 0.8,
                              fraction_heat_load_served: 0.1,
                              electric_auxiliary_energy: 200)
  elsif ['invalid_files/hvac-frac-load-served.xml'].include? hpxml_file
    hpxml.heating_systems[0].fraction_heat_load_served += 0.1
  elsif ['base-hvac-portable-heater-electric-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].distribution_system_idref = nil
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypePortableHeater
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
    hpxml.heating_systems[0].heating_efficiency_afue = nil
    hpxml.heating_systems[0].heating_efficiency_percent = 1.0
  elsif ['base-hvac-stove-oil-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].distribution_system_idref = nil
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeStove
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeOil
    hpxml.heating_systems[0].heating_efficiency_afue = nil
    hpxml.heating_systems[0].heating_efficiency_percent = 0.8
    hpxml.heating_systems[0].electric_auxiliary_energy = 200
  elsif ['base-hvac-stove-wood-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].distribution_system_idref = nil
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeStove
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeWood
    hpxml.heating_systems[0].heating_efficiency_afue = nil
    hpxml.heating_systems[0].heating_efficiency_percent = 0.8
    hpxml.heating_systems[0].electric_auxiliary_energy = 200
  elsif ['base-hvac-stove-wood-pellets-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeWoodPellets
  elsif ['base-hvac-wall-furnace-elec-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].distribution_system_idref = nil
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeWallFurnace
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeElectricity
    hpxml.heating_systems[0].heating_efficiency_afue = 1.0
    hpxml.heating_systems[0].electric_auxiliary_energy = 200
  elsif ['base-hvac-wall-furnace-propane-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].distribution_system_idref = nil
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeWallFurnace
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypePropane
    hpxml.heating_systems[0].heating_efficiency_afue = 0.8
    hpxml.heating_systems[0].electric_auxiliary_energy = 200
  elsif ['base-hvac-wall-furnace-wood-only.xml'].include? hpxml_file
    hpxml.heating_systems[0].distribution_system_idref = nil
    hpxml.heating_systems[0].heating_system_type = HPXML::HVACTypeWallFurnace
    hpxml.heating_systems[0].heating_system_fuel = HPXML::FuelTypeWood
    hpxml.heating_systems[0].heating_efficiency_afue = 0.8
    hpxml.heating_systems[0].electric_auxiliary_energy = 200
  elsif ['base-hvac-furnace-x3-dse.xml'].include? hpxml_file
    hpxml.heating_systems << hpxml.heating_systems[0].dup
    hpxml.heating_systems << hpxml.heating_systems[1].dup
    hpxml.heating_systems[1].id = 'HeatingSystem2'
    hpxml.heating_systems[1].distribution_system_idref = 'HVACDistribution2'
    hpxml.heating_systems[2].id = 'HeatingSystem3'
    hpxml.heating_systems[2].distribution_system_idref = 'HVACDistribution3'
    for i in 0..2
      hpxml.heating_systems[i].heating_capacity /= 3.0
      hpxml.heating_systems[i].fraction_heat_load_served = 0.333
    end
  elsif ['invalid_files/unattached-hvac-distribution.xml'].include? hpxml_file
    hpxml.heating_systems[0].distribution_system_idref = 'foobar'
  elsif ['invalid_files/hvac-invalid-distribution-system-type.xml'].include? hpxml_file
    hpxml.heating_systems[0].distribution_system_idref = 'HVACDistribution2'
  elsif ['invalid_files/hvac-dse-multiple-attached-heating.xml'].include? hpxml_file
    hpxml.heating_systems[0].fraction_heat_load_served = 0.5
    hpxml.heating_systems << hpxml.heating_systems[0].dup
    hpxml.heating_systems[1].id += '2'
  elsif ['base-hvac-undersized.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_capacity /= 10.0
  elsif ['base-hvac-flowrate.xml'].include? hpxml_file
    hpxml.heating_systems[0].heating_cfm = hpxml.heating_systems[0].heating_capacity * 360.0 / 12000.0
  elsif hpxml_file.include?('hvac_autosizing') && (not hpxml.heating_systems.nil?) && (hpxml.heating_systems.size > 0)
    hpxml.heating_systems[0].heating_capacity = -1
  elsif hpxml_file.include?('-zero-heat.xml') && (not hpxml.heating_systems.nil?) && (hpxml.heating_systems.size > 0)
    hpxml.heating_systems[0].fraction_heat_load_served = 0
    hpxml.heating_systems[0].heating_capacity = 0
  elsif hpxml_file.include?('hvac_multiple') && (not hpxml.heating_systems.nil?) && (hpxml.heating_systems.size > 0)
    hpxml.heating_systems[0].heating_capacity /= 3.0
    hpxml.heating_systems[0].fraction_heat_load_served = 0.333
    hpxml.heating_systems[0].electric_auxiliary_energy /= 3.0 unless hpxml.heating_systems[0].electric_auxiliary_energy.nil?
    hpxml.heating_systems << hpxml.heating_systems[0].dup
    hpxml.heating_systems[1].id = 'HeatingSystem2'
    hpxml.heating_systems[1].distribution_system_idref = 'HVACDistribution2' unless hpxml.heating_systems[1].distribution_system_idref.nil?
    hpxml.heating_systems << hpxml.heating_systems[0].dup
    hpxml.heating_systems[2].id = 'HeatingSystem3'
    hpxml.heating_systems[2].distribution_system_idref = 'HVACDistribution3' unless hpxml.heating_systems[2].distribution_system_idref.nil?
    if ['hvac_multiple/base-hvac-boiler-gas-only-x3.xml'].include? hpxml_file
      # Test a file where sum is slightly greater than 1
      hpxml.heating_systems[0].fraction_heat_load_served = 0.33
      hpxml.heating_systems[1].fraction_heat_load_served = 0.33
      hpxml.heating_systems[2].fraction_heat_load_served = 0.35
    end
  elsif hpxml_file.include?('hvac_partial') && (not hpxml.heating_systems.nil?) && (hpxml.heating_systems.size > 0)
    hpxml.heating_systems[0].heating_capacity /= 3.0
    hpxml.heating_systems[0].fraction_heat_load_served = 0.333
    hpxml.heating_systems[0].electric_auxiliary_energy /= 3.0 unless hpxml.heating_systems[0].electric_auxiliary_energy.nil?
  end
end

def set_hpxml_cooling_systems(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.cooling_systems.add(id: 'CoolingSystem',
                              distribution_system_idref: 'HVACDistribution',
                              cooling_system_type: HPXML::HVACTypeCentralAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: 48000,
                              fraction_cool_load_served: 1,
                              cooling_efficiency_seer: 13)
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
    hpxml.cooling_systems.clear()
  elsif ['base-hvac-central-ac-only-1-speed-detailed.xml'].include? hpxml_file
    hpxml.cooling_systems[0].cooling_shr = 0.7
    hpxml.cooling_systems[0].compressor_type = HPXML::HVACCompressorTypeSingleStage
  elsif ['base-hvac-central-ac-only-2-speed-detailed.xml'].include? hpxml_file
    hpxml.cooling_systems[0].cooling_shr = 0.7
    hpxml.cooling_systems[0].compressor_type = HPXML::HVACCompressorTypeTwoStage
  elsif ['base-hvac-central-ac-only-var-speed-detailed.xml'].include? hpxml_file
    hpxml.cooling_systems[0].cooling_shr = 0.7
    hpxml.cooling_systems[0].compressor_type = HPXML::HVACCompressorTypeVariableSpeed
  elsif ['base-hvac-room-ac-only-detailed.xml'].include? hpxml_file
    hpxml.cooling_systems[0].cooling_shr = 0.7
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.xml'].include? hpxml_file
    hpxml.cooling_systems[0].distribution_system_idref = 'HVACDistribution2'
  elsif ['base-hvac-furnace-gas-central-ac-2-speed.xml',
         'base-hvac-central-ac-only-2-speed.xml'].include? hpxml_file
    hpxml.cooling_systems[0].cooling_efficiency_seer = 18
  elsif ['base-hvac-furnace-gas-central-ac-var-speed.xml',
         'base-hvac-central-ac-only-var-speed.xml'].include? hpxml_file
    hpxml.cooling_systems[0].cooling_efficiency_seer = 24
  elsif ['base-hvac-furnace-gas-room-ac.xml',
         'base-hvac-room-ac-only.xml'].include? hpxml_file
    hpxml.cooling_systems[0].distribution_system_idref = nil
    hpxml.cooling_systems[0].cooling_system_type = HPXML::HVACTypeRoomAirConditioner
    hpxml.cooling_systems[0].cooling_efficiency_seer = nil
    hpxml.cooling_systems[0].cooling_efficiency_eer = 8.5
  elsif ['base-hvac-evap-cooler-only-ducted.xml',
         'base-hvac-evap-cooler-furnace-gas.xml',
         'base-hvac-evap-cooler-only.xml',
         'hvac_autosizing/base-hvac-evap-cooler-furnace-gas-autosize.xml'].include? hpxml_file
    hpxml.cooling_systems[0].cooling_system_type = HPXML::HVACTypeEvaporativeCooler
    hpxml.cooling_systems[0].cooling_efficiency_seer = nil
    hpxml.cooling_systems[0].cooling_efficiency_eer = nil
    hpxml.cooling_systems[0].cooling_capacity = nil
    if ['base-hvac-evap-cooler-furnace-gas.xml',
        'hvac_autosizing/base-hvac-evap-cooler-furnace-gas-autosize.xml',
        'base-hvac-evap-cooler-only.xml'].include? hpxml_file
      hpxml.cooling_systems[0].distribution_system_idref = nil
    end
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    hpxml.cooling_systems[0].distribution_system_idref = 'HVACDistribution4'
    hpxml.cooling_systems[0].fraction_cool_load_served = 0.2
    hpxml.cooling_systems[0].cooling_capacity *= 0.2
    hpxml.cooling_systems.add(id: 'CoolingSystem2',
                              cooling_system_type: HPXML::HVACTypeRoomAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: 9600,
                              fraction_cool_load_served: 0.2,
                              cooling_efficiency_eer: 8.5)
  elsif ['invalid_files/hvac-frac-load-served.xml'].include? hpxml_file
    hpxml.cooling_systems[0].fraction_cool_load_served += 0.2
  elsif ['invalid_files/hvac-dse-multiple-attached-cooling.xml'].include? hpxml_file
    hpxml.cooling_systems[0].fraction_cool_load_served = 0.5
    hpxml.cooling_systems << hpxml.cooling_systems[0].dup
    hpxml.cooling_systems[1].id += '2'
  elsif ['base-hvac-undersized.xml'].include? hpxml_file
    hpxml.cooling_systems[0].cooling_capacity /= 10.0
  elsif ['base-hvac-flowrate.xml'].include? hpxml_file
    hpxml.cooling_systems[0].cooling_cfm = hpxml.cooling_systems[0].cooling_capacity * 360.0 / 12000.0
  elsif hpxml_file.include?('hvac_autosizing') && (not hpxml.cooling_systems.nil?) && (hpxml.cooling_systems.size > 0)
    hpxml.cooling_systems[0].cooling_capacity = -1
  elsif hpxml_file.include?('-zero-cool.xml') && (not hpxml.cooling_systems.nil?) && (hpxml.cooling_systems.size > 0)
    hpxml.cooling_systems[0].fraction_cool_load_served = 0
    hpxml.cooling_systems[0].cooling_capacity = 0
  elsif hpxml_file.include?('hvac_multiple') && (not hpxml.cooling_systems.nil?) && (hpxml.cooling_systems.size > 0)
    hpxml.cooling_systems[0].cooling_capacity /= 3.0 unless hpxml.cooling_systems[0].cooling_capacity.nil?
    hpxml.cooling_systems[0].fraction_cool_load_served = 0.333
    hpxml.cooling_systems << hpxml.cooling_systems[0].dup
    hpxml.cooling_systems[1].id = 'CoolingSystem2'
    hpxml.cooling_systems[1].distribution_system_idref = 'HVACDistribution2' unless hpxml.cooling_systems[1].distribution_system_idref.nil?
    hpxml.cooling_systems << hpxml.cooling_systems[0].dup
    hpxml.cooling_systems[2].id = 'CoolingSystem3'
    hpxml.cooling_systems[2].distribution_system_idref = 'HVACDistribution3' unless hpxml.cooling_systems[2].distribution_system_idref.nil?
  elsif hpxml_file.include?('hvac_partial') && (not hpxml.cooling_systems.nil?) && (hpxml.cooling_systems.size > 0)
    hpxml.cooling_systems[0].cooling_capacity /= 3.0 unless hpxml.cooling_systems[0].cooling_capacity.nil?
    hpxml.cooling_systems[0].fraction_cool_load_served = 0.333
  end
end

def set_hpxml_heat_pumps(hpxml_file, hpxml)
  if ['base-hvac-air-to-air-heat-pump-1-speed.xml',
      'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml'].include? hpxml_file
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 42000,
                         cooling_capacity: 48000,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 34121,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: 7.7,
                         cooling_efficiency_seer: 13)
    if hpxml_file == 'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml'
      hpxml.heat_pumps[0].fraction_cool_load_served = 0
    end
  elsif ['base-hvac-air-to-air-heat-pump-2-speed.xml'].include? hpxml_file
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 42000,
                         cooling_capacity: 48000,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 34121,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: 9.3,
                         cooling_efficiency_seer: 18)
  elsif ['base-hvac-air-to-air-heat-pump-var-speed.xml'].include? hpxml_file
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 42000,
                         cooling_capacity: 48000,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 34121,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: 10,
                         cooling_efficiency_seer: 22)
  elsif ['base-hvac-ground-to-air-heat-pump.xml'].include? hpxml_file
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution',
                         heat_pump_type: HPXML::HVACTypeHeatPumpGroundToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 42000,
                         cooling_capacity: 48000,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 34121,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_cop: 3.6,
                         cooling_efficiency_eer: 16.6)
  elsif ['base-hvac-mini-split-heat-pump-ducted.xml'].include? hpxml_file
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution',
                         heat_pump_type: HPXML::HVACTypeHeatPumpMiniSplit,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 52000,
                         cooling_capacity: 48000,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 34121,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_hspf: 10,
                         cooling_efficiency_seer: 19)
  elsif ['base-hvac-mini-split-heat-pump-ductless.xml'].include? hpxml_file
    hpxml.heat_pumps[0].distribution_system_idref = nil
  elsif ['base-hvac-mini-split-heat-pump-ductless-no-backup.xml'].include? hpxml_file
    hpxml.heat_pumps[0].backup_heating_fuel = nil
  elsif ['invalid_files/heat-pump-mixed-fixed-and-autosize-capacities.xml'].include? hpxml_file
    hpxml.heat_pumps[0].heating_capacity = -1
  elsif ['invalid_files/heat-pump-mixed-fixed-and-autosize-capacities2.xml'].include? hpxml_file
    hpxml.heat_pumps[0].cooling_capacity = -1
  elsif ['invalid_files/heat-pump-mixed-fixed-and-autosize-capacities3.xml'].include? hpxml_file
    hpxml.heat_pumps[0].cooling_capacity = -1
    hpxml.heat_pumps[0].heating_capacity = -1
    hpxml.heat_pumps[0].heating_capacity_17F = 25000
  elsif ['invalid_files/heat-pump-mixed-fixed-and-autosize-capacities4.xml'].include? hpxml_file
    hpxml.heat_pumps[0].backup_heating_capacity = -1
  elsif ['base-hvac-air-to-air-heat-pump-1-speed-detailed.xml'].include? hpxml_file
    hpxml.heat_pumps[0].heating_capacity_17F = hpxml.heat_pumps[0].heating_capacity * 0.630 # Based on OAT slope of default curves
    hpxml.heat_pumps[0].cooling_shr = 0.7
    hpxml.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeSingleStage
  elsif ['base-hvac-air-to-air-heat-pump-2-speed-detailed.xml'].include? hpxml_file
    hpxml.heat_pumps[0].heating_capacity_17F = hpxml.heat_pumps[0].heating_capacity * 0.590 # Based on OAT slope of default curves
    hpxml.heat_pumps[0].cooling_shr = 0.7
    hpxml.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeTwoStage
  elsif ['base-hvac-air-to-air-heat-pump-var-speed-detailed.xml'].include? hpxml_file
    hpxml.heat_pumps[0].heating_capacity_17F = hpxml.heat_pumps[0].heating_capacity * 0.640 # Based on OAT slope of default curves
    hpxml.heat_pumps[0].cooling_shr = 0.7
    hpxml.heat_pumps[0].compressor_type = HPXML::HVACCompressorTypeVariableSpeed
  elsif ['base-hvac-mini-split-heat-pump-ducted-detailed.xml'].include? hpxml_file
    f = 1.0 - (1.0 - 0.25) / (47.0 + 5.0) * (47.0 - 17.0)
    hpxml.heat_pumps[0].heating_capacity_17F = hpxml.heat_pumps[0].heating_capacity * f
    hpxml.heat_pumps[0].cooling_shr = 0.7
  elsif ['base-hvac-ground-to-air-heat-pump-detailed.xml'].include? hpxml_file
    hpxml.heat_pumps[0].cooling_shr = 0.7
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    hpxml.heat_pumps.add(id: 'HeatPump',
                         distribution_system_idref: 'HVACDistribution5',
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 4800,
                         cooling_capacity: 4800,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 3412,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 0.1,
                         fraction_cool_load_served: 0.2,
                         heating_efficiency_hspf: 7.7,
                         cooling_efficiency_seer: 13)
    hpxml.heat_pumps.add(id: 'HeatPump2',
                         distribution_system_idref: 'HVACDistribution6',
                         heat_pump_type: HPXML::HVACTypeHeatPumpGroundToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 4800,
                         cooling_capacity: 4800,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 3412,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 0.1,
                         fraction_cool_load_served: 0.2,
                         heating_efficiency_cop: 3.6,
                         cooling_efficiency_eer: 16.6)
    hpxml.heat_pumps.add(id: 'HeatPump3',
                         heat_pump_type: HPXML::HVACTypeHeatPumpMiniSplit,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 4800,
                         cooling_capacity: 4800,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 3412,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 0.1,
                         fraction_cool_load_served: 0.2,
                         heating_efficiency_hspf: 10,
                         cooling_efficiency_seer: 19)
  elsif ['invalid_files/hvac-distribution-multiple-attached-heating.xml'].include? hpxml_file
    hpxml.heat_pumps[0].distribution_system_idref = 'HVACDistribution3'
  elsif ['invalid_files/hvac-distribution-multiple-attached-cooling.xml'].include? hpxml_file
    hpxml.heat_pumps[0].distribution_system_idref = 'HVACDistribution4'
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
         'base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.xml',
         'base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.xml',
         'base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml'].include? hpxml_file
    hpxml.heat_pumps[0].backup_heating_fuel = HPXML::FuelTypeNaturalGas
    hpxml.heat_pumps[0].backup_heating_capacity = 36000
    hpxml.heat_pumps[0].backup_heating_efficiency_percent = nil
    hpxml.heat_pumps[0].backup_heating_efficiency_afue = 0.95
    hpxml.heat_pumps[0].backup_heating_switchover_temp = 25
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml'].include? hpxml_file
    hpxml.heat_pumps[0].backup_heating_fuel = HPXML::FuelTypeElectricity
    hpxml.heat_pumps[0].backup_heating_efficiency_afue = 1.0
  elsif hpxml_file.include?('hvac_autosizing') && (not hpxml.heat_pumps.nil?) && (hpxml.heat_pumps.size > 0)
    hpxml.heat_pumps[0].cooling_capacity = -1
    hpxml.heat_pumps[0].heating_capacity = -1
    hpxml.heat_pumps[0].backup_heating_capacity = -1
  elsif hpxml_file.include?('-zero-heat.xml') && (not hpxml.heat_pumps.nil?) && (hpxml.heat_pumps.size > 0)
    hpxml.heat_pumps[0].fraction_heat_load_served = 0
    hpxml.heat_pumps[0].heating_capacity = 0
    hpxml.heat_pumps[0].backup_heating_capacity = 0
  elsif hpxml_file.include?('-zero-cool.xml') && (not hpxml.heat_pumps.nil?) && (hpxml.heat_pumps.size > 0)
    hpxml.heat_pumps[0].fraction_cool_load_served = 0
    hpxml.heat_pumps[0].cooling_capacity = 0
  elsif hpxml_file.include?('hvac_multiple') && (not hpxml.heat_pumps.nil?) && (hpxml.heat_pumps.size > 0)
    hpxml.heat_pumps[0].cooling_capacity /= 3.0
    hpxml.heat_pumps[0].heating_capacity /= 3.0
    hpxml.heat_pumps[0].backup_heating_capacity /= 3.0
    hpxml.heat_pumps[0].fraction_heat_load_served = 0.333
    hpxml.heat_pumps[0].fraction_cool_load_served = 0.333
    hpxml.heat_pumps << hpxml.heat_pumps[0].dup
    hpxml.heat_pumps[1].id = 'HeatPump2'
    hpxml.heat_pumps[1].distribution_system_idref = 'HVACDistribution2' unless hpxml.heat_pumps[1].distribution_system_idref.nil?
    hpxml.heat_pumps << hpxml.heat_pumps[0].dup
    hpxml.heat_pumps[2].id = 'HeatPump3'
    hpxml.heat_pumps[2].distribution_system_idref = 'HVACDistribution3' unless hpxml.heat_pumps[2].distribution_system_idref.nil?
  elsif hpxml_file.include?('hvac_partial') && (not hpxml.heat_pumps.nil?) && (hpxml.heat_pumps.size > 0)
    hpxml.heat_pumps[0].cooling_capacity /= 3.0
    hpxml.heat_pumps[0].heating_capacity /= 3.0
    hpxml.heat_pumps[0].backup_heating_capacity /= 3.0
    hpxml.heat_pumps[0].fraction_heat_load_served = 0.333
    hpxml.heat_pumps[0].fraction_cool_load_served = 0.333
  end
end

def set_hpxml_hvac_control(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.hvac_controls.add(id: 'HVACControl',
                            control_type: HPXML::HVACControlTypeManual,
                            heating_setpoint_temp: 68,
                            cooling_setpoint_temp: 78)
  elsif ['base-hvac-none.xml'].include? hpxml_file
    hpxml.hvac_controls.clear()
  elsif ['base-hvac-programmable-thermostat.xml'].include? hpxml_file
    hpxml.hvac_controls[0].control_type = HPXML::HVACControlTypeProgrammable
    hpxml.hvac_controls[0].heating_setback_temp = 66
    hpxml.hvac_controls[0].heating_setback_hours_per_week = 7 * 7
    hpxml.hvac_controls[0].heating_setback_start_hour = 23 # 11pm
    hpxml.hvac_controls[0].cooling_setup_temp = 80
    hpxml.hvac_controls[0].cooling_setup_hours_per_week = 6 * 7
    hpxml.hvac_controls[0].cooling_setup_start_hour = 9 # 9am
  elsif ['base-hvac-setpoints.xml'].include? hpxml_file
    hpxml.hvac_controls[0].heating_setpoint_temp = 60
    hpxml.hvac_controls[0].cooling_setpoint_temp = 80
  elsif ['base-misc-ceiling-fans.xml'].include? hpxml_file
    hpxml.hvac_controls[0].ceiling_fan_cooling_setpoint_temp_offset = 0.5
  end
end

def set_hpxml_hvac_distributions(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.hvac_distributions.add(id: 'HVACDistribution',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir)
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                              duct_leakage_units: HPXML::UnitsCFM25,
                                                              duct_leakage_value: 75)
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                              duct_leakage_units: HPXML::UnitsCFM25,
                                                              duct_leakage_value: 25)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: 4,
                                          duct_location: HPXML::LocationAtticUnvented,
                                          duct_surface_area: 150)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: 0,
                                          duct_location: HPXML::LocationAtticUnvented,
                                          duct_surface_area: 50)
  elsif ['base-hvac-boiler-elec-only.xml',
         'base-hvac-boiler-gas-only.xml',
         'base-hvac-boiler-oil-only.xml',
         'base-hvac-boiler-propane-only.xml',
         'base-hvac-boiler-wood-only.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].distribution_system_type = HPXML::HVACDistributionTypeHydronic
    hpxml.hvac_distributions[0].duct_leakage_measurements.clear()
    hpxml.hvac_distributions[0].ducts.clear()
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].distribution_system_type = HPXML::HVACDistributionTypeHydronic
    hpxml.hvac_distributions[0].duct_leakage_measurements.clear()
    hpxml.hvac_distributions[0].ducts.clear()
    hpxml.hvac_distributions.add(id: 'HVACDistribution2',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 75)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 25)
    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                           duct_insulation_r_value: 4,
                                           duct_location: HPXML::LocationAtticUnvented,
                                           duct_surface_area: 150)
    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                           duct_insulation_r_value: 0,
                                           duct_location: HPXML::LocationAtticUnvented,
                                           duct_surface_area: 50)
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
    hpxml.hvac_distributions.clear()
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].distribution_system_type = HPXML::HVACDistributionTypeHydronic
    hpxml.hvac_distributions[0].duct_leakage_measurements.clear()
    hpxml.hvac_distributions[0].ducts.clear()
    hpxml.hvac_distributions.add(id: 'HVACDistribution2',
                                 distribution_system_type: HPXML::HVACDistributionTypeHydronic)
    hpxml.hvac_distributions.add(id: 'HVACDistribution3',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 75)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 25)
    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                           duct_insulation_r_value: 4,
                                           duct_location: HPXML::LocationAtticUnvented,
                                           duct_surface_area: 150)
    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                           duct_insulation_r_value: 0,
                                           duct_location: HPXML::LocationAtticUnvented,
                                           duct_surface_area: 50)
    hpxml.hvac_distributions.add(id: 'HVACDistribution4',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 75)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 25)
    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                           duct_insulation_r_value: 4,
                                           duct_location: HPXML::LocationAtticUnvented,
                                           duct_surface_area: 150)
    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                           duct_insulation_r_value: 0,
                                           duct_location: HPXML::LocationAtticUnvented,
                                           duct_surface_area: 50)
    hpxml.hvac_distributions.add(id: 'HVACDistribution5',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 75)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 25)
    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                           duct_insulation_r_value: 4,
                                           duct_location: HPXML::LocationAtticUnvented,
                                           duct_surface_area: 150)
    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                           duct_insulation_r_value: 0,
                                           duct_location: HPXML::LocationAtticUnvented,
                                           duct_surface_area: 50)
    hpxml.hvac_distributions.add(id: 'HVACDistribution6',
                                 distribution_system_type: HPXML::HVACDistributionTypeAir)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 75)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 25)
    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                           duct_insulation_r_value: 4,
                                           duct_location: HPXML::LocationAtticUnvented,
                                           duct_surface_area: 150)
    hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                           duct_insulation_r_value: 0,
                                           duct_location: HPXML::LocationAtticUnvented,
                                           duct_surface_area: 50)
  elsif ['base-hvac-dse.xml',
         'base-dhw-indirect-dse.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].distribution_system_type = HPXML::HVACDistributionTypeDSE
    hpxml.hvac_distributions[0].annual_heating_dse = 0.8
    hpxml.hvac_distributions[0].annual_cooling_dse = 0.7
  elsif ['base-hvac-furnace-x3-dse.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].distribution_system_type = HPXML::HVACDistributionTypeDSE
    hpxml.hvac_distributions[0].annual_heating_dse = 0.8
    hpxml.hvac_distributions[0].annual_cooling_dse = 0.7
    hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
    hpxml.hvac_distributions[1].id = 'HVACDistribution2'
    hpxml.hvac_distributions[1].annual_cooling_dse = nil
    hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
    hpxml.hvac_distributions[2].id = 'HVACDistribution3'
    hpxml.hvac_distributions[2].annual_cooling_dse = nil
  elsif ['base-hvac-mini-split-heat-pump-ducted.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value = 15
    hpxml.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = 5
    hpxml.hvac_distributions[0].ducts[0].duct_insulation_r_value = 0
    hpxml.hvac_distributions[0].ducts[0].duct_surface_area = 30
    hpxml.hvac_distributions[0].ducts[1].duct_surface_area = 10
  elsif ['base-hvac-evap-cooler-only-ducted.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].duct_leakage_measurements.pop
    hpxml.hvac_distributions[0].ducts.pop
  elsif ['base-hvac-ducts-leakage-percent.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].duct_leakage_measurements.clear()
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                              duct_leakage_units: HPXML::UnitsPercent,
                                                              duct_leakage_value: 0.1)
    hpxml.hvac_distributions[0].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                              duct_leakage_units: HPXML::UnitsPercent,
                                                              duct_leakage_value: 0.05)
  elsif ['base-hvac-undersized.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value /= 10.0
    hpxml.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value /= 10.0
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationBasementUnconditioned
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationBasementUnconditioned
  elsif ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationCrawlspaceUnvented
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationCrawlspaceUnvented
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationCrawlspaceVented
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationCrawlspaceVented
  elsif ['base-atticroof-flat.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value = 0.0
    hpxml.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = 0.0
    hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationBasementConditioned
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationBasementConditioned
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationAtticVented
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationAtticVented
  elsif ['base-enclosure-garage.xml',
         'invalid_files/duct-location.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationGarage
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationGarage
  elsif ['invalid_files/duct-location-other.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[0].duct_location = 'unconditioned space'
    hpxml.hvac_distributions[0].ducts[1].duct_location = 'unconditioned space'
  elsif ['base-hvac-ducts-outside.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationOutside
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationOutside
  elsif ['base-hvac-ducts-locations.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationAtticUnvented
  elsif ['base-hvac-ducts-multiple.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: 8,
                                          duct_location: HPXML::LocationAtticUnvented,
                                          duct_surface_area: 300)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: 8,
                                          duct_location: HPXML::LocationOutside,
                                          duct_surface_area: 300)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: 4,
                                          duct_location: HPXML::LocationAtticUnvented,
                                          duct_surface_area: 100)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: 4,
                                          duct_location: HPXML::LocationOutside,
                                          duct_surface_area: 100)
  elsif ['base-atticroof-conditioned.xml',
         'base-enclosure-adiabatic-surfaces.xml',
         'base-atticroof-cathedral.xml',
         'base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationLivingSpace
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationLivingSpace
    hpxml.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value = 0.0
    hpxml.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = 0.0

  elsif ['base-hvac-ducts-in-conditioned-space.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[0].duct_location = HPXML::LocationLivingSpace
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationLivingSpace
    # Test leakage to outside when all ducts in conditioned space
    # (e.g., ducts may be in floor cavities which have leaky rims)
    hpxml.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value = 1.5
    hpxml.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = 1.5
  elsif (hpxml_file.include?('hvac_partial') || hpxml_file.include?('hvac_base')) && (not hpxml.hvac_distributions.empty?)
    if not hpxml.hvac_distributions[0].duct_leakage_measurements.empty?
      hpxml.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value = 0.0
      hpxml.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = 0.0
    end
    hpxml.hvac_distributions[0].ducts.clear()
  elsif hpxml_file.include?('hvac_multiple') && (not hpxml.hvac_distributions.empty?)
    hpxml.hvac_distributions[0].ducts.clear()
    if not hpxml.hvac_distributions[0].duct_leakage_measurements.empty?
      hpxml.hvac_distributions[0].duct_leakage_measurements[0].duct_leakage_value = 0.0
      hpxml.hvac_distributions[0].duct_leakage_measurements[1].duct_leakage_value = 0.0
    end
    hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
    hpxml.hvac_distributions[1].id = 'HVACDistribution2'
    hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
    hpxml.hvac_distributions[2].id = 'HVACDistribution3'
  elsif ['invalid_files/hvac-invalid-distribution-system-type.xml'].include? hpxml_file
    hpxml.hvac_distributions.add(id: 'HVACDistribution2',
                                 distribution_system_type: HPXML::HVACDistributionTypeHydronic)
  elsif ['invalid_files/hvac-distribution-return-duct-leakage-missing.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: 0,
                                          duct_location: HPXML::LocationAtticUnvented,
                                          duct_surface_area: 50)
  end
end

def set_hpxml_ventilation_fans(hpxml_file, hpxml)
  if ['base-mechvent-balanced.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeBalanced,
                               tested_flow_rate: 110,
                               hours_in_operation: 24,
                               fan_power: 60,
                               used_for_whole_building_ventilation: true)
  elsif ['invalid_files/unattached-cfis.xml',
         'invalid_files/cfis-with-hydronic-distribution.xml',
         'base-mechvent-cfis.xml',
         'base-mechvent-cfis-evap-cooler-only-ducted.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeCFIS,
                               tested_flow_rate: 330,
                               hours_in_operation: 8,
                               fan_power: 300,
                               used_for_whole_building_ventilation: true,
                               distribution_system_idref: 'HVACDistribution')
    if ['invalid_files/unattached-cfis.xml'].include? hpxml_file
      hpxml.ventilation_fans[0].distribution_system_idref = 'foobar'
    end
  elsif ['base-mechvent-erv.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeERV,
                               tested_flow_rate: 110,
                               hours_in_operation: 24,
                               total_recovery_efficiency: 0.48,
                               sensible_recovery_efficiency: 0.72,
                               fan_power: 60,
                               used_for_whole_building_ventilation: true)
  elsif ['base-mechvent-erv-atre-asre.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeERV,
                               tested_flow_rate: 110,
                               hours_in_operation: 24,
                               total_recovery_efficiency_adjusted: 0.526,
                               sensible_recovery_efficiency_adjusted: 0.79,
                               fan_power: 60,
                               used_for_whole_building_ventilation: true)
  elsif ['base-mechvent-exhaust.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 110,
                               hours_in_operation: 24,
                               fan_power: 30,
                               used_for_whole_building_ventilation: true)
  elsif ['base-mechvent-exhaust-rated-flow-rate.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeExhaust,
                               rated_flow_rate: 110,
                               hours_in_operation: 24,
                               fan_power: 30,
                               used_for_whole_building_ventilation: true)
  elsif ['base-mechvent-hrv.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeHRV,
                               tested_flow_rate: 110,
                               hours_in_operation: 24,
                               sensible_recovery_efficiency: 0.72,
                               fan_power: 60,
                               used_for_whole_building_ventilation: true)
  elsif ['base-mechvent-hrv-asre.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeHRV,
                               tested_flow_rate: 110,
                               hours_in_operation: 24,
                               sensible_recovery_efficiency_adjusted: 0.790,
                               fan_power: 60,
                               used_for_whole_building_ventilation: true)
  elsif ['base-mechvent-supply.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: 'MechanicalVentilation',
                               fan_type: HPXML::MechVentTypeSupply,
                               tested_flow_rate: 110,
                               hours_in_operation: 24,
                               fan_power: 30,
                               used_for_whole_building_ventilation: true)
  elsif ['base-misc-whole-house-fan.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: 'WholeHouseFan',
                               rated_flow_rate: 4500,
                               fan_power: 300,
                               used_for_seasonal_cooling_load_reduction: true)
  end
end

def set_hpxml_water_heating_systems(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.water_heating_systems.add(id: 'WaterHeater',
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 40,
                                    fraction_dhw_load_served: 1,
                                    heating_capacity: 18767,
                                    energy_factor: 0.95)
  elsif ['base-dhw-multiple.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fraction_dhw_load_served = 0.2
    hpxml.water_heating_systems.add(id: 'WaterHeater2',
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 50,
                                    fraction_dhw_load_served: 0.2,
                                    heating_capacity: 40000,
                                    energy_factor: 0.59,
                                    recovery_efficiency: 0.76)
    hpxml.water_heating_systems.add(id: 'WaterHeater3',
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeHeatPump,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 80,
                                    fraction_dhw_load_served: 0.2,
                                    energy_factor: 2.3)
    hpxml.water_heating_systems.add(id: 'WaterHeater4',
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeTankless,
                                    location: HPXML::LocationLivingSpace,
                                    fraction_dhw_load_served: 0.2,
                                    energy_factor: 0.99)
    hpxml.water_heating_systems.add(id: 'WaterHeater5',
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeTankless,
                                    location: HPXML::LocationLivingSpace,
                                    fraction_dhw_load_served: 0.1,
                                    energy_factor: 0.82)
    hpxml.water_heating_systems.add(id: 'WaterHeater6',
                                    water_heater_type: HPXML::WaterHeaterTypeCombiStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 50,
                                    fraction_dhw_load_served: 0.1,
                                    related_hvac_idref: 'HeatingSystem')
  elsif ['invalid_files/dhw-frac-load-served.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fraction_dhw_load_served += 0.15
  elsif ['base-dhw-tank-gas.xml',
         'base-dhw-tank-gas-outside.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fuel_type = HPXML::FuelTypeNaturalGas
    hpxml.water_heating_systems[0].tank_volume = 50
    hpxml.water_heating_systems[0].heating_capacity = 40000
    hpxml.water_heating_systems[0].energy_factor = 0.59
    hpxml.water_heating_systems[0].recovery_efficiency = 0.76
    if hpxml_file == 'base-dhw-tank-gas-outside.xml'
      hpxml.water_heating_systems[0].location = HPXML::LocationOtherExterior
    end
  elsif ['base-dhw-tank-wood.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fuel_type = HPXML::FuelTypeWood
    hpxml.water_heating_systems[0].tank_volume = 50
    hpxml.water_heating_systems[0].heating_capacity = 40000
    hpxml.water_heating_systems[0].energy_factor = 0.59
    hpxml.water_heating_systems[0].recovery_efficiency = 0.76
  elsif ['base-dhw-tank-heat-pump.xml',
         'base-dhw-tank-heat-pump-outside.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].water_heater_type = HPXML::WaterHeaterTypeHeatPump
    hpxml.water_heating_systems[0].tank_volume = 80
    hpxml.water_heating_systems[0].heating_capacity = nil
    hpxml.water_heating_systems[0].energy_factor = 2.3
    if hpxml_file == 'base-dhw-tank-heat-pump-outside.xml'
      hpxml.water_heating_systems[0].location = HPXML::LocationOtherExterior
    end
  elsif ['base-dhw-tankless-electric.xml',
         'base-dhw-tankless-electric-outside.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].water_heater_type = HPXML::WaterHeaterTypeTankless
    hpxml.water_heating_systems[0].tank_volume = nil
    hpxml.water_heating_systems[0].heating_capacity = nil
    hpxml.water_heating_systems[0].energy_factor = 0.99
    if hpxml_file == 'base-dhw-tankless-electric-outside.xml'
      hpxml.water_heating_systems[0].location = HPXML::LocationOtherExterior
    end
  elsif ['base-dhw-tankless-gas.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fuel_type = HPXML::FuelTypeNaturalGas
    hpxml.water_heating_systems[0].water_heater_type = HPXML::WaterHeaterTypeTankless
    hpxml.water_heating_systems[0].tank_volume = nil
    hpxml.water_heating_systems[0].heating_capacity = nil
    hpxml.water_heating_systems[0].energy_factor = 0.82
  elsif ['base-dhw-tankless-oil.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fuel_type = HPXML::FuelTypeOil
    hpxml.water_heating_systems[0].water_heater_type = HPXML::WaterHeaterTypeTankless
    hpxml.water_heating_systems[0].tank_volume = nil
    hpxml.water_heating_systems[0].heating_capacity = nil
    hpxml.water_heating_systems[0].energy_factor = 0.82
  elsif ['base-dhw-tankless-propane.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fuel_type = HPXML::FuelTypePropane
    hpxml.water_heating_systems[0].water_heater_type = HPXML::WaterHeaterTypeTankless
    hpxml.water_heating_systems[0].tank_volume = nil
    hpxml.water_heating_systems[0].heating_capacity = nil
    hpxml.water_heating_systems[0].energy_factor = 0.82
  elsif ['base-dhw-tankless-wood.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fuel_type = HPXML::FuelTypeWood
    hpxml.water_heating_systems[0].water_heater_type = HPXML::WaterHeaterTypeTankless
    hpxml.water_heating_systems[0].tank_volume = nil
    hpxml.water_heating_systems[0].heating_capacity = nil
    hpxml.water_heating_systems[0].energy_factor = 0.82
  elsif ['base-dhw-tank-oil.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fuel_type = HPXML::FuelTypeOil
    hpxml.water_heating_systems[0].tank_volume = 50
    hpxml.water_heating_systems[0].heating_capacity = 40000
    hpxml.water_heating_systems[0].energy_factor = 0.59
    hpxml.water_heating_systems[0].recovery_efficiency = 0.76
  elsif ['base-dhw-tank-propane.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fuel_type = HPXML::FuelTypePropane
    hpxml.water_heating_systems[0].tank_volume = 50
    hpxml.water_heating_systems[0].heating_capacity = 40000
    hpxml.water_heating_systems[0].energy_factor = 0.59
    hpxml.water_heating_systems[0].recovery_efficiency = 0.76
  elsif ['base-dhw-uef.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].energy_factor = nil
    hpxml.water_heating_systems[0].uniform_energy_factor = 0.93
  elsif ['base-dhw-desuperheater.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].uses_desuperheater = true
    hpxml.water_heating_systems[0].related_hvac_idref = 'CoolingSystem'
  elsif ['base-dhw-desuperheater-tankless.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].water_heater_type = HPXML::WaterHeaterTypeTankless
    hpxml.water_heating_systems[0].tank_volume = nil
    hpxml.water_heating_systems[0].heating_capacity = nil
    hpxml.water_heating_systems[0].energy_factor = 0.99
    hpxml.water_heating_systems[0].uses_desuperheater = true
    hpxml.water_heating_systems[0].related_hvac_idref = 'CoolingSystem'
  elsif ['base-dhw-desuperheater-2-speed.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].uses_desuperheater = true
    hpxml.water_heating_systems[0].related_hvac_idref = 'CoolingSystem'
  elsif ['base-dhw-desuperheater-var-speed.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].uses_desuperheater = true
    hpxml.water_heating_systems[0].related_hvac_idref = 'CoolingSystem'
  elsif ['base-dhw-desuperheater-gshp.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].uses_desuperheater = true
    hpxml.water_heating_systems[0].related_hvac_idref = 'HeatPump'
  elsif ['base-dhw-jacket-electric.xml',
         'base-dhw-jacket-indirect.xml',
         'base-dhw-jacket-gas.xml',
         'base-dhw-jacket-hpwh.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].jacket_r_value = 10.0
  elsif ['base-dhw-indirect.xml',
         'base-dhw-indirect-outside.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].water_heater_type = HPXML::WaterHeaterTypeCombiStorage
    hpxml.water_heating_systems[0].tank_volume = 50
    hpxml.water_heating_systems[0].heating_capacity = nil
    hpxml.water_heating_systems[0].energy_factor = nil
    hpxml.water_heating_systems[0].fuel_type = nil
    hpxml.water_heating_systems[0].related_hvac_idref = 'HeatingSystem'
    if hpxml_file == 'base-dhw-indirect-outside.xml'
      hpxml.water_heating_systems[0].location = HPXML::LocationOtherExterior
    end
  elsif ['base-dhw-indirect-standbyloss.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].standby_loss = 1.0
  elsif ['base-dhw-combi-tankless.xml',
         'base-dhw-combi-tankless-outside.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].water_heater_type = HPXML::WaterHeaterTypeCombiTankless
    hpxml.water_heating_systems[0].tank_volume = nil
    if hpxml_file == 'base-dhw-combi-tankless-outside.xml'
      hpxml.water_heating_systems[0].location = HPXML::LocationOtherExterior
    end
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].location = HPXML::LocationBasementUnconditioned
  elsif ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].location = HPXML::LocationCrawlspaceUnvented
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].location = HPXML::LocationCrawlspaceVented
  elsif ['base-foundation-slab.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].location = HPXML::LocationLivingSpace
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].location = HPXML::LocationAtticVented
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].location = HPXML::LocationBasementConditioned
  elsif ['invalid_files/water-heater-location.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].location = HPXML::LocationCrawlspaceVented
  elsif ['invalid_files/water-heater-location-other.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].location = 'unconditioned space'
  elsif ['invalid_files/invalid-relatedhvac-desuperheater.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].uses_desuperheater = true
    hpxml.water_heating_systems[0].related_hvac_idref = 'CoolingSystem_bad'
  elsif ['invalid_files/repeated-relatedhvac-desuperheater.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fraction_dhw_load_served = 0.5
    hpxml.water_heating_systems[0].uses_desuperheater = true
    hpxml.water_heating_systems[0].related_hvac_idref = 'CoolingSystem'
    hpxml.water_heating_systems << hpxml.water_heating_systems[0].dup
    hpxml.water_heating_systems[1].id = 'WaterHeater2'
  elsif ['invalid_files/invalid-relatedhvac-dhw-indirect.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].related_hvac_idref = 'HeatingSystem_bad'
  elsif ['invalid_files/repeated-relatedhvac-dhw-indirect.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fraction_dhw_load_served = 0.5
    hpxml.water_heating_systems << hpxml.water_heating_systems[0].dup
    hpxml.water_heating_systems[1].id = 'WaterHeater2'
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].location = HPXML::LocationGarage
  elsif ['base-dhw-temperature.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].temperature = 130.0
  elsif ['base-dhw-none.xml'].include? hpxml_file
    hpxml.water_heating_systems.clear()
  end
end

def set_hpxml_hot_water_distribution(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.hot_water_distributions.add(id: 'HotWaterDstribution',
                                      system_type: HPXML::DHWDistTypeStandard,
                                      standard_piping_length: 50, # Chosen to test a negative EC_adj
                                      pipe_r_value: 0.0)
  elsif ['base-dhw-dwhr.xml'].include? hpxml_file
    hpxml.hot_water_distributions[0].dwhr_facilities_connected = HPXML::DWHRFacilitiesConnectedAll
    hpxml.hot_water_distributions[0].dwhr_equal_flow = true
    hpxml.hot_water_distributions[0].dwhr_efficiency = 0.55
  elsif ['base-dhw-recirc-demand.xml'].include? hpxml_file
    hpxml.hot_water_distributions[0].system_type = HPXML::DHWDistTypeRecirc
    hpxml.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecirControlTypeSensor
    hpxml.hot_water_distributions[0].recirculation_piping_length = 50
    hpxml.hot_water_distributions[0].recirculation_branch_piping_length = 50
    hpxml.hot_water_distributions[0].recirculation_pump_power = 50
    hpxml.hot_water_distributions[0].pipe_r_value = 3
  elsif ['base-dhw-recirc-manual.xml'].include? hpxml_file
    hpxml.hot_water_distributions[0].system_type = HPXML::DHWDistTypeRecirc
    hpxml.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecirControlTypeManual
    hpxml.hot_water_distributions[0].recirculation_piping_length = 50
    hpxml.hot_water_distributions[0].recirculation_branch_piping_length = 50
    hpxml.hot_water_distributions[0].recirculation_pump_power = 50
    hpxml.hot_water_distributions[0].pipe_r_value = 3
  elsif ['base-dhw-recirc-nocontrol.xml'].include? hpxml_file
    hpxml.hot_water_distributions[0].system_type = HPXML::DHWDistTypeRecirc
    hpxml.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecirControlTypeNone
    hpxml.hot_water_distributions[0].recirculation_piping_length = 50
    hpxml.hot_water_distributions[0].recirculation_branch_piping_length = 50
    hpxml.hot_water_distributions[0].recirculation_pump_power = 50
  elsif ['base-dhw-recirc-temperature.xml'].include? hpxml_file
    hpxml.hot_water_distributions[0].system_type = HPXML::DHWDistTypeRecirc
    hpxml.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecirControlTypeTemperature
    hpxml.hot_water_distributions[0].recirculation_piping_length = 50
    hpxml.hot_water_distributions[0].recirculation_branch_piping_length = 50
    hpxml.hot_water_distributions[0].recirculation_pump_power = 50
  elsif ['base-dhw-recirc-timer.xml'].include? hpxml_file
    hpxml.hot_water_distributions[0].system_type = HPXML::DHWDistTypeRecirc
    hpxml.hot_water_distributions[0].recirculation_control_type = HPXML::DHWRecirControlTypeTimer
    hpxml.hot_water_distributions[0].recirculation_piping_length = 50
    hpxml.hot_water_distributions[0].recirculation_branch_piping_length = 50
    hpxml.hot_water_distributions[0].recirculation_pump_power = 50
  elsif ['base-dhw-none.xml'].include? hpxml_file
    hpxml.hot_water_distributions.clear()
  end
end

def set_hpxml_water_fixtures(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.water_fixtures.add(id: 'WaterFixture',
                             water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                             low_flow: true)
    hpxml.water_fixtures.add(id: 'WaterFixture2',
                             water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                             low_flow: false)
  elsif ['base-dhw-low-flow-fixtures.xml'].include? hpxml_file
    hpxml.water_fixtures[1].low_flow = true
  elsif ['base-dhw-none.xml'].include? hpxml_file
    hpxml.water_fixtures.clear()
  end
end

def set_hpxml_solar_thermal_system(hpxml_file, hpxml)
  if ['base-dhw-solar-fraction.xml',
      'base-dhw-multiple.xml',
      'base-dhw-tank-heat-pump-with-solar-fraction.xml',
      'base-dhw-tankless-gas-with-solar-fraction.xml',
      'invalid_files/solar-thermal-system-with-combi-tankless.xml',
      'invalid_files/solar-thermal-system-with-desuperheater.xml',
      'invalid_files/solar-thermal-system-with-dhw-indirect.xml'].include? hpxml_file
    hpxml.solar_thermal_systems.add(id: 'SolarThermalSystem',
                                    system_type: 'hot water',
                                    water_heating_system_idref: 'WaterHeater',
                                    solar_fraction: 0.65)
  elsif ['base-dhw-solar-direct-flat-plate.xml',
         'base-dhw-solar-indirect-flat-plate.xml',
         'base-dhw-solar-thermosyphon-flat-plate.xml',
         'base-dhw-tank-heat-pump-with-solar.xml',
         'base-dhw-tankless-gas-with-solar.xml'].include? hpxml_file
    hpxml.solar_thermal_systems.add(id: 'SolarThermalSystem',
                                    system_type: 'hot water',
                                    collector_area: 40,
                                    collector_type: HPXML::SolarThermalTypeSingleGlazing,
                                    collector_azimuth: 180,
                                    collector_tilt: 20,
                                    collector_frta: 0.77,
                                    collector_frul: 0.793,
                                    storage_volume: 60,
                                    water_heating_system_idref: 'WaterHeater')
    if hpxml_file == 'base-dhw-solar-direct-flat-plate.xml'
      hpxml.solar_thermal_systems[0].collector_loop_type = HPXML::SolarThermalLoopTypeDirect
    elsif hpxml_file == 'base-dhw-solar-thermosyphon-flat-plate.xml'
      hpxml.solar_thermal_systems[0].collector_loop_type = HPXML::SolarThermalLoopTypeThermosyphon
    else
      hpxml.solar_thermal_systems[0].collector_loop_type = HPXML::SolarThermalLoopTypeIndirect
    end
  elsif ['base-dhw-solar-indirect-evacuated-tube.xml',
         'base-dhw-solar-direct-evacuated-tube.xml',
         'base-dhw-solar-thermosyphon-evacuated-tube.xml'].include? hpxml_file
    hpxml.solar_thermal_systems.add(id: 'SolarThermalSystem',
                                    system_type: 'hot water',
                                    collector_area: 40,
                                    collector_type: HPXML::SolarThermalTypeEvacuatedTube,
                                    collector_azimuth: 180,
                                    collector_tilt: 20,
                                    collector_frta: 0.50,
                                    collector_frul: 0.2799,
                                    storage_volume: 60,
                                    water_heating_system_idref: 'WaterHeater')
    if hpxml_file == 'base-dhw-solar-direct-evacuated-tube.xml'
      hpxml.solar_thermal_systems[0].collector_loop_type = HPXML::SolarThermalLoopTypeDirect
    elsif hpxml_file == 'base-dhw-solar-thermosyphon-evacuated-tube.xml'
      hpxml.solar_thermal_systems[0].collector_loop_type = HPXML::SolarThermalLoopTypeThermosyphon
    else
      hpxml.solar_thermal_systems[0].collector_loop_type = HPXML::SolarThermalLoopTypeIndirect
    end
  elsif ['base-dhw-solar-direct-ics.xml',
         'base-dhw-solar-thermosyphon-ics.xml'].include? hpxml_file
    hpxml.solar_thermal_systems.add(id: 'SolarThermalSystem',
                                    system_type: 'hot water',
                                    collector_area: 40,
                                    collector_type: HPXML::SolarThermalTypeICS,
                                    collector_azimuth: 180,
                                    collector_tilt: 20,
                                    collector_frta: 0.77,
                                    collector_frul: 0.793,
                                    storage_volume: 60,
                                    water_heating_system_idref: 'WaterHeater')
    if hpxml_file == 'base-dhw-solar-direct-ics.xml'
      hpxml.solar_thermal_systems[0].collector_loop_type = HPXML::SolarThermalLoopTypeDirect
    elsif hpxml_file == 'base-dhw-solar-thermosyphon-ics.xml'
      hpxml.solar_thermal_systems[0].collector_loop_type = HPXML::SolarThermalLoopTypeThermosyphon
    end
  elsif ['invalid_files/unattached-solar-thermal-system.xml'].include? hpxml_file
    hpxml.solar_thermal_systems[0].water_heating_system_idref = 'foobar'
  end
end

def set_hpxml_pv_systems(hpxml_file, hpxml)
  if ['base-pv.xml'].include? hpxml_file
    hpxml.pv_systems.add(id: 'PVSystem',
                         module_type: HPXML::PVModuleTypeStandard,
                         location: HPXML::LocationRoof,
                         tracking: HPXML::PVTrackingTypeFixed,
                         array_azimuth: 180,
                         array_tilt: 20,
                         max_power_output: 4000,
                         inverter_efficiency: 0.96,
                         system_losses_fraction: 0.14)
    hpxml.pv_systems.add(id: 'PVSystem2',
                         module_type: HPXML::PVModuleTypePremium,
                         location: HPXML::LocationRoof,
                         tracking: HPXML::PVTrackingTypeFixed,
                         array_azimuth: 90,
                         array_tilt: 20,
                         max_power_output: 1500,
                         inverter_efficiency: 0.96,
                         system_losses_fraction: 0.14)
  end
end

def set_hpxml_clothes_washer(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.clothes_washers.add(id: 'ClothesWasher',
                              location: HPXML::LocationLivingSpace,
                              modified_energy_factor: 0.8,
                              rated_annual_kwh: 700.0,
                              label_electric_rate: 0.10,
                              label_gas_rate: 0.60,
                              label_annual_gas_cost: 25.0,
                              capacity: 3.0)
  elsif ['base-appliances-none.xml'].include? hpxml_file
    hpxml.clothes_washers.clear()
  elsif ['base-appliances-modified.xml'].include? hpxml_file
    hpxml.clothes_washers[0].modified_energy_factor = nil
    hpxml.clothes_washers[0].integrated_modified_energy_factor = 0.73
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    hpxml.clothes_washers[0].location = HPXML::LocationBasementUnconditioned
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.clothes_washers[0].location = HPXML::LocationBasementConditioned
  elsif ['base-enclosure-garage.xml',
         'invalid_files/clothes-washer-location.xml'].include? hpxml_file
    hpxml.clothes_washers[0].location = HPXML::LocationGarage
  elsif ['invalid_files/clothes-washer-location-other.xml'].include? hpxml_file
    hpxml.clothes_washers[0].location = 'other'
  end
end

def set_hpxml_clothes_dryer(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.clothes_dryers.add(id: 'ClothesDryer',
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeElectricity,
                             energy_factor: 2.95,
                             control_type: HPXML::ClothesDryerControlTypeTimer)
  elsif ['base-appliances-none.xml'].include? hpxml_file
    hpxml.clothes_dryers.clear()
  elsif ['base-appliances-modified.xml'].include? hpxml_file
    hpxml.clothes_dryers.clear()
    hpxml.clothes_dryers.add(id: 'ClothesDryer',
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeElectricity,
                             combined_energy_factor: 2.62,
                             control_type: HPXML::ClothesDryerControlTypeMoisture)
  elsif ['base-appliances-gas.xml',
         'base-appliances-propane.xml',
         'base-appliances-oil.xml'].include? hpxml_file
    hpxml.clothes_dryers.clear()
    hpxml.clothes_dryers.add(id: 'ClothesDryer',
                             location: HPXML::LocationLivingSpace,
                             energy_factor: 2.67,
                             control_type: HPXML::ClothesDryerControlTypeMoisture)
    if hpxml_file == 'base-appliances-gas.xml'
      hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeNaturalGas
    elsif hpxml_file == 'base-appliances-propane.xml'
      hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypePropane
    elsif hpxml_file == 'base-appliances-oil.xml'
      hpxml.clothes_dryers[0].fuel_type = HPXML::FuelTypeOil
    end
  elsif ['base-appliances-wood.xml'].include? hpxml_file
    hpxml.clothes_dryers.clear()
    hpxml.clothes_dryers.add(id: 'ClothesDryer',
                             location: HPXML::LocationLivingSpace,
                             fuel_type: HPXML::FuelTypeWood,
                             energy_factor: 2.67,
                             control_type: HPXML::ClothesDryerControlTypeMoisture)
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    hpxml.clothes_dryers[0].location = HPXML::LocationBasementUnconditioned
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.clothes_dryers[0].location = HPXML::LocationBasementConditioned
  elsif ['base-enclosure-garage.xml',
         'invalid_files/clothes-dryer-location.xml'].include? hpxml_file
    hpxml.clothes_dryers[0].location = HPXML::LocationGarage
  elsif ['invalid_files/clothes-dryer-location-other.xml'].include? hpxml_file
    hpxml.clothes_dryers[0].location = 'other'
  end
end

def set_hpxml_dishwasher(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.dishwashers.add(id: 'Dishwasher',
                          rated_annual_kwh: 450,
                          place_setting_capacity: 12)
  elsif ['base-appliances-none.xml'].include? hpxml_file
    hpxml.dishwashers.clear()
  elsif ['base-appliances-modified.xml'].include? hpxml_file
    hpxml.dishwashers.clear()
    hpxml.dishwashers.add(id: 'Dishwasher',
                          energy_factor: 0.5,
                          place_setting_capacity: 12)
  end
end

def set_hpxml_refrigerator(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.refrigerators.add(id: 'Refrigerator',
                            location: HPXML::LocationLivingSpace,
                            rated_annual_kwh: 650)
  elsif ['base-appliances-modified.xml'].include? hpxml_file
    hpxml.refrigerators[0].adjusted_annual_kwh = 600
  elsif ['base-appliances-none.xml'].include? hpxml_file
    hpxml.refrigerators.clear()
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    hpxml.refrigerators[0].location = HPXML::LocationBasementUnconditioned
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.refrigerators[0].location = HPXML::LocationBasementConditioned
  elsif ['base-enclosure-garage.xml',
         'invalid_files/refrigerator-location.xml'].include? hpxml_file
    hpxml.refrigerators[0].location = HPXML::LocationGarage
  elsif ['invalid_files/refrigerator-location-other.xml'].include? hpxml_file
    hpxml.refrigerators[0].location = 'other'
  end
end

def set_hpxml_cooking_range(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.cooking_ranges.add(id: 'Range',
                             fuel_type: HPXML::FuelTypeElectricity,
                             is_induction: false)
  elsif ['base-appliances-none.xml'].include? hpxml_file
    hpxml.cooking_ranges.clear()
  elsif ['base-appliances-gas.xml'].include? hpxml_file
    hpxml.cooking_ranges[0].fuel_type = HPXML::FuelTypeNaturalGas
    hpxml.cooking_ranges[0].is_induction = false
  elsif ['base-appliances-propane.xml'].include? hpxml_file
    hpxml.cooking_ranges[0].fuel_type = HPXML::FuelTypePropane
    hpxml.cooking_ranges[0].is_induction = false
  elsif ['base-appliances-oil.xml'].include? hpxml_file
    hpxml.cooking_ranges[0].fuel_type = HPXML::FuelTypeOil
  elsif ['base-appliances-wood.xml'].include? hpxml_file
    hpxml.cooking_ranges[0].fuel_type = HPXML::FuelTypeWood
    hpxml.cooking_ranges[0].is_induction = false
  end
end

def set_hpxml_oven(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.ovens.add(id: 'Oven',
                    is_convection: false)
  elsif ['base-appliances-none.xml'].include? hpxml_file
    hpxml.ovens.clear()
  end
end

def set_hpxml_lighting(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Interior',
                              location: HPXML::LocationInterior,
                              fration_of_units_in_location: 0.5,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Exterior',
                              location: HPXML::LocationExterior,
                              fration_of_units_in_location: 0.5,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierI_Garage',
                              location: HPXML::LocationGarage,
                              fration_of_units_in_location: 0.5,
                              third_party_certification: HPXML::LightingTypeTierI)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Interior',
                              location: HPXML::LocationInterior,
                              fration_of_units_in_location: 0.25,
                              third_party_certification: HPXML::LightingTypeTierII)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Exterior',
                              location: HPXML::LocationExterior,
                              fration_of_units_in_location: 0.25,
                              third_party_certification: HPXML::LightingTypeTierII)
    hpxml.lighting_groups.add(id: 'Lighting_TierII_Garage',
                              location: HPXML::LocationGarage,
                              fration_of_units_in_location: 0.25,
                              third_party_certification: HPXML::LightingTypeTierII)
  elsif ['base-misc-lighting-none.xml'].include? hpxml_file
    hpxml.lighting_groups.clear()
  elsif ['invalid_files/lighting-fractions.xml'].include? hpxml_file
    hpxml.lighting_groups[0].fration_of_units_in_location = 0.8
  end
end

def set_hpxml_ceiling_fans(hpxml_file, hpxml)
  if ['base-misc-ceiling-fans.xml'].include? hpxml_file
    hpxml.ceiling_fans.add(id: 'CeilingFan',
                           efficiency: 100,
                           quantity: 2)
  end
end

def set_hpxml_plug_loads(hpxml_file, hpxml)
  if ['base.xml'].include? hpxml_file
    hpxml.plug_loads.add(id: 'PlugLoadMisc',
                         plug_load_type: HPXML::PlugLoadTypeOther)
    hpxml.plug_loads.add(id: 'PlugLoadMisc2',
                         plug_load_type: HPXML::PlugLoadTypeTelevision)
  elsif ['base-misc-loads-detailed.xml'].include? hpxml_file
    hpxml.plug_loads.clear()
    hpxml.plug_loads.add(id: 'PlugLoadMisc',
                         plug_load_type: HPXML::PlugLoadTypeOther,
                         kWh_per_year: 7302,
                         frac_sensible: 0.82,
                         frac_latent: 0.18)
    hpxml.plug_loads.add(id: 'PlugLoadMisc2',
                         plug_load_type: HPXML::PlugLoadTypeTelevision,
                         kWh_per_year: 400)
  end
end

def set_hpxml_misc_load_schedule(hpxml_file, hpxml)
  if ['base-misc-loads-detailed.xml'].include? hpxml_file
    hpxml.set_misc_loads_schedule(weekday_fractions: '0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066',
                                  weekend_fractions: '0.020, 0.020, 0.020, 0.020, 0.020, 0.034, 0.043, 0.085, 0.050, 0.030, 0.030, 0.041, 0.030, 0.025, 0.026, 0.026, 0.039, 0.042, 0.045, 0.070, 0.070, 0.073, 0.073, 0.066',
                                  monthly_multipliers: '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0')
  end
end

def download_epws
  weather_dir = File.join(File.dirname(__FILE__), 'weather')

  require 'net/http'
  require 'tempfile'

  tmpfile = Tempfile.new('epw')

  url = URI.parse('https://data.nrel.gov/files/128/tmy3s-cache-csv.zip')
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  params = { 'User-Agent' => 'curl/7.43.0', 'Accept-Encoding' => 'identity' }
  request = Net::HTTP::Get.new(url.path, params)
  request.content_type = 'application/zip, application/octet-stream'

  http.request request do |response|
    total = response.header['Content-Length'].to_i
    if total == 0
      fail 'Did not successfully download zip file.'
    end

    size = 0
    progress = 0
    open tmpfile, 'wb' do |io|
      response.read_body do |chunk|
        io.write chunk
        size += chunk.size
        new_progress = (size * 100) / total
        unless new_progress == progress
          puts 'Downloading %s (%3d%%) ' % [url.path, new_progress]
        end
        progress = new_progress
      end
    end
  end

  puts 'Extracting weather files...'
  unzip_file = OpenStudio::UnzipFile.new(tmpfile.path.to_s)
  unzip_file.extractAllFiles(OpenStudio::toPath(weather_dir))

  num_epws_actual = Dir[File.join(weather_dir, '*.epw')].count
  puts "#{num_epws_actual} weather files are available in the weather directory."
  puts 'Completed.'
  exit!
end

command_list = [:update_measures, :cache_weather, :create_release_zips, :update_version, :download_weather]

def display_usage(command_list)
  puts "Usage: openstudio #{File.basename(__FILE__)} [COMMAND]\nCommands:\n  " + command_list.join("\n  ")
end

if ARGV.size == 0
  puts 'ERROR: Missing command.'
  display_usage(command_list)
  exit!
elsif ARGV.size > 1
  puts 'ERROR: Too many commands.'
  display_usage(command_list)
  exit!
elsif not command_list.include? ARGV[0].to_sym
  puts "ERROR: Invalid command '#{ARGV[0]}'."
  display_usage(command_list)
  exit!
end

if ARGV[0].to_sym == :update_measures
  require 'openstudio'
  require_relative 'HPXMLtoOpenStudio/resources/hpxml'
  require_relative 'HPXMLtoOpenStudio/resources/constants'

  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? && ENV['HOME'].start_with?('U:')
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? && ENV['HOMEDRIVE'].start_with?('U:')

  # Apply rubocop
  cops = ['Layout',
          'Lint/DeprecatedClassMethods',
          'Lint/StringConversionInInterpolation',
          'Style/AndOr',
          'Style/HashSyntax',
          'Style/Next',
          'Style/NilComparison',
          'Style/RedundantParentheses',
          'Style/RedundantSelf',
          'Style/ReturnNil',
          'Style/SelfAssignment',
          'Style/StringLiterals',
          'Style/StringLiteralsInInterpolation']
  commands = ["\"require 'rubocop/rake_task'\"",
              "\"RuboCop::RakeTask.new(:rubocop) do |t| t.options = ['--auto-correct', '--format', 'simple', '--only', '#{cops.join(',')}'] end\"",
              '"Rake.application[:rubocop].invoke"']
  command = "openstudio -e #{commands.join(' -e ')}"
  puts 'Applying rubocop auto-correct to measures...'
  system(command)

  # Update measures XMLs
  command = "#{OpenStudio.getOpenStudioCLI} measure -t '#{File.dirname(__FILE__)}'"
  puts 'Updating measure.xmls...'
  system(command, [:out, :err] => File::NULL)

  create_osws
  create_hpxmls

  puts 'Done.'
end

if ARGV[0].to_sym == :cache_weather
  require 'openstudio'
  require_relative 'HPXMLtoOpenStudio/resources/weather'

  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  puts 'Creating cache *.csv for weather files...'

  Dir['weather/*.epw'].each do |epw|
    next if File.exist? epw.gsub('.epw', '.cache')

    puts "Processing #{epw}..."
    model = OpenStudio::Model::Model.new
    epw_file = OpenStudio::EpwFile.new(epw)
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    weather = WeatherProcess.new(model, runner)
    File.open(epw.gsub('.epw', '-cache.csv'), 'wb') do |file|
      weather.dump_to_csv(file)
    end
  end
end

if ARGV[0].to_sym == :download_weather
  download_epws
end

if ARGV[0].to_sym == :update_version
  version_change = { from: '0.7.0',
                     to: '0.8.0' }

  file_names = ['workflow/run_simulation.rb']

  file_names.each do |file_name|
    text = File.read(file_name)
    new_contents = text.gsub(version_change[:from], version_change[:to])

    # To write changes to the file, use:
    File.open(file_name, 'w') { |file| file.puts new_contents }
  end

  puts 'Done. Now check all changed files before committing.'
end

if ARGV[0].to_sym == :create_release_zips
  require 'openstudio'

  # Generate documentation
  puts 'Generating documentation...'
  command = 'sphinx-build -b singlehtml docs/source documentation'
  begin
    `#{command}`
    if not File.exist? File.join(File.dirname(__FILE__), 'documentation', 'index.html')
      puts 'Documentation was not successfully generated. Aborting...'
      exit!
    end
  rescue
    puts "Command failed: '#{command}'. Perhaps sphinx needs to be installed?"
    exit!
  end

  files = ['HPXMLtoOpenStudio/measure.*',
           'HPXMLtoOpenStudio/resources/*.*',
           'SimulationOutputReport/measure.*',
           'SimulationOutputReport/resources/*.*',
           'weather/*.*',
           'workflow/*.*',
           'workflow/sample_files/*.xml',
           'documentation/index.html',
           'documentation/_static/**/*.*']

  # Only include files under git version control
  command = 'git ls-files'
  begin
    git_files = `#{command}`
  rescue
    puts "Command failed: '#{command}'. Perhaps git needs to be installed?"
    exit!
  end

  release_map = { File.join(File.dirname(__FILE__), 'release-minimal.zip') => false,
                  File.join(File.dirname(__FILE__), 'release-full.zip') => true }

  release_map.keys.each do |zip_path|
    File.delete(zip_path) if File.exist? zip_path
  end

  # Check if we need to download weather files for the full release zip
  num_epws_expected = File.readlines(File.join('weather', 'data.csv')).size - 1
  num_epws_local = 0
  files.each do |f|
    Dir[f].each do |file|
      next unless file.end_with? '.epw'

      num_epws_local += 1
    end
  end

  # Make sure we have the full set of weather files
  if num_epws_local < num_epws_expected
    puts 'Fetching all weather files...'
    command = "#{OpenStudio.getOpenStudioCLI} #{__FILE__} download_weather"
    log = `#{command}`
  end

  # Create zip files
  release_map.each do |zip_path, include_all_epws|
    puts "Creating #{zip_path}..."
    zip = OpenStudio::ZipFile.new(zip_path, false)
    files.each do |f|
      Dir[f].each do |file|
        if file.start_with? 'documentation'
          # always include
        elsif include_all_epws
          if (not git_files.include? file) && (not file.start_with? 'weather')
            next
          end
        else
          if not git_files.include? file
            next
          end
        end

        zip.addFile(file, File.join('OpenStudio-HPXML', file))
      end
    end
    puts "Wrote file at #{zip_path}."
  end

  # Cleanup
  FileUtils.rm_r(File.join(File.dirname(__FILE__), 'documentation'))

  puts 'Done.'
end
