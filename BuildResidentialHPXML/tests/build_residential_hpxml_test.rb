require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require_relative '../../HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../HPXMLtoOpenStudio/resources/hpxml'

class BuildResidentialHPXMLTest < MiniTest::Test
  def test_workflows
    require 'json'

    this_dir = File.dirname(__FILE__)

    hvac_partial_dir = File.absolute_path(File.join(this_dir, 'hvac_partial'))
    test_dirs = [
      this_dir,
    ]

    osws = []
    test_dirs.each do |test_dir|
      Dir["#{test_dir}/base*.osw"].sort.each do |osw|
        osws << File.absolute_path(osw)
      end
      Dir["#{test_dir}/extra*.osw"].sort.each do |osw|
        osws << File.absolute_path(osw)
      end
    end

    workflow_dir = File.expand_path(File.join(File.dirname(__FILE__), '../../workflow/sample_files'))
    tests_dir = File.expand_path(File.join(File.dirname(__FILE__), '../../BuildResidentialHPXML/tests'))
    built_dir = File.join(tests_dir, 'built_residential_hpxml')
    unless Dir.exist?(built_dir)
      Dir.mkdir(built_dir)
    end

    puts "Running #{osws.size} OSW files..."
    measures = {}
    fail = false
    osws.each do |osw|
      puts "\nTesting #{File.basename(osw)}..."

      _setup(tests_dir)
      osw_hash = JSON.parse(File.read(osw))
      measures_dir = File.join(File.dirname(__FILE__), osw_hash['measure_paths'][0])
      osw_hash['steps'].each do |step|
        measures[step['measure_dir_name']] = [step['arguments']]
        model = OpenStudio::Model::Model.new
        runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

        # Apply measure
        success = apply_measures(measures_dir, measures, runner, model)

        # Report warnings/errors
        runner.result.stepWarnings.each do |s|
          puts "Warning: #{s}"
        end
        runner.result.stepErrors.each do |s|
          puts "Error: #{s}"
        end

        assert(success)

        if ['base-single-family-attached.osw', 'base-multifamily.osw'].include? File.basename(osw)
          next # FIXME: should this be temporary?
        end

        if File.basename(osw).start_with? 'extra-'
          next # No corresponding sample file
        end

        # Compare the hpxml to the manually created one
        test_dir = File.basename(File.dirname(osw))
        hpxml_path = step['arguments']['hpxml_path']
        begin
          _check_hpxmls(workflow_dir, built_dir, test_dir, hpxml_path)
        rescue Exception => e
          puts "#{e}\n#{e.backtrace.join('\n')}"
          fail = true
        end
      end
      break if fail # FIXME: Temporary
    end

    assert false if fail
  end

  def test_invalid_workflows
    require 'json'

    this_dir = File.dirname(__FILE__)

    tests_dir = File.expand_path(File.join(File.dirname(__FILE__), '../../BuildResidentialHPXML/tests'))
    built_dir = File.join(tests_dir, 'built_residential_hpxml')
    unless Dir.exist?(built_dir)
      Dir.mkdir(built_dir)
    end

    expected_warning_msgs = {
      'non-electric-heat-pump-water-heater.osw' => 'water_heater_type=heat pump water heater and water_heater_fuel_type=natural gas',
      'single-family-detached-slab-non-zero-foundation-height.osw' => 'geometry_unit_type=single-family detached and geometry_foundation_type=SlabOnGrade and geometry_foundation_height=8.0',
      'multifamily-bottom-slab-non-zero-foundation-height.osw' => 'geometry_unit_type=apartment unit and geometry_level=Bottom and geometry_foundation_type=SlabOnGrade and geometry_foundation_height=8.0',
      'slab-non-zero-foundation-height-above-grade.osw' => 'geometry_foundation_type=SlabOnGrade and geometry_foundation_height_above_grade=1.0',
      'second-heating-system-serves-majority-heat.osw' => 'heating_system_type_2=Fireplace and heating_system_fraction_heat_load_served_2=0.6',
      'vented-crawlspace-with-wall-and-ceiling-insulation.osw' => 'geometry_foundation_type=VentedCrawlspace and foundation_wall_insulation_r=8.9 and foundation_wall_assembly_r=false and floor_assembly_r=10.0',
      'unvented-crawlspace-with-wall-and-ceiling-insulation.osw' => 'geometry_foundation_type=VentedCrawlspace and foundation_wall_insulation_r=8.9 and foundation_wall_assembly_r=false and floor_assembly_r=10.0',
      'unconditioned-basement-with-wall-and-ceiling-insulation.osw' => 'geometry_foundation_type=UnconditionedBasement and foundation_wall_insulation_r=8.9 and foundation_wall_assembly_r=false and floor_assembly_r=10.0',
      'vented-attic-with-floor-and-roof-insulation.osw' => 'geometry_attic_type=VentedAttic and ceiling_assembly_r=39.3 and roof_assembly_r=10.0',
      'unvented-attic-with-floor-and-roof-insulation.osw' => 'geometry_attic_type=UnventedAttic and ceiling_assembly_r=39.3 and roof_assembly_r=10.0',
      'conditioned-basement-with-ceiling-insulation.osw' => 'geometry_foundation_type=ConditionedBasement and floor_assembly_r=10.0',
      'conditioned-attic-with-floor-insulation.osw' => 'geometry_attic_type=ConditionedAttic and ceiling_assembly_r=39.3'
    }

    expected_error_msgs = {
      'heating-system-and-heat-pump.osw' => 'heating_system_type=Furnace and heat_pump_type=air-to-air',
      'cooling-system-and-heat-pump.osw' => 'cooling_system_type=central air conditioner and heat_pump_type=air-to-air',
      'non-integer-geometry-num-bathrooms.osw' => 'geometry_num_bathrooms=1.5',
      'non-integer-ceiling-fan-quantity.osw' => 'ceiling_fan_quantity=0.5',
      'single-family-detached-finished-basement-zero-foundation-height.osw' => 'geometry_unit_type=single-family detached and geometry_foundation_type=ConditionedBasement and geometry_foundation_height=0.0',
      'single-family-attached-ambient.osw' => 'geometry_unit_type=single-family attached and geometry_foundation_type=Ambient',
      'multifamily-bottom-crawlspace-zero-foundation-height.osw' => 'geometry_unit_type=apartment unit and geometry_level=Bottom and geometry_foundation_type=UnventedCrawlspace and geometry_foundation_height=0.0',
      'ducts-location-and-areas-not-same-type.osw' => 'ducts_supply_location=auto and ducts_supply_surface_area=150.0 and ducts_return_location=attic - unvented and ducts_return_surface_area=50.0',
      'single-family-attached-no-building-orientation.osw' => 'geometry_unit_type=single-family attached and geometry_building_num_units=false and geometry_horizontal_location=false',
      'multifamily-no-building-orientation.osw' => 'geometry_unit_type=apartment unit and geometry_building_num_units=false and geometry_level=false and geometry_horizontal_location=false'
    }

    measures = {}
    Dir["#{this_dir}/invalid_files/*.osw"].sort.each do |osw|
      puts "\nTesting #{File.basename(osw)}..."

      _setup(this_dir)
      osw_hash = JSON.parse(File.read(osw))
      measures_dir = File.join(File.dirname(__FILE__), osw_hash['measure_paths'][0])
      osw_hash['steps'].each do |step|
        measures[step['measure_dir_name']] = [step['arguments']]
        model = OpenStudio::Model::Model.new
        runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

        # Apply measure
        success = apply_measures(measures_dir, measures, runner, model)

        # Report warnings/errors
        runner.result.stepWarnings.each do |s|
          next if s.include? 'nokogiri'

          puts "Warning: #{s}"
          assert_equal(s, expected_warning_msgs[File.basename(osw)])
        end
        runner.result.stepErrors.each do |s|
          puts "Error: #{s}"
          assert_equal(s, expected_error_msgs[File.basename(osw)])
        end

        if expected_error_msgs.include? File.basename(osw)
          assert(!success)
        else
          assert(success)
        end
      end
    end
  end

  private

  def _check_hpxmls(workflow_dir, built_dir, test_dir, hpxml_path)
    if test_dir == 'tests'
      test_dir = ''
    end

    hpxml_path = {
      'Rakefile' => File.join(workflow_dir, test_dir, File.basename(hpxml_path)),
      'BuildResidentialHPXML' => File.join(built_dir, File.basename(hpxml_path))
    }

    hpxml_objs = {
      'Rakefile' => HPXML.new(hpxml_path: hpxml_path['Rakefile']),
      'BuildResidentialHPXML' => HPXML.new(hpxml_path: hpxml_path['BuildResidentialHPXML'])
    }

    hpxml_objs.each do |version, hpxml|
      # Sort elements so we can diff them
      hpxml.neighbor_buildings.sort_by! { |neighbor_building| neighbor_building.azimuth }
      hpxml.roofs.sort_by! { |roof| roof.area }
      hpxml.walls.sort_by! { |wall| [wall.insulation_assembly_r_value, wall.area] }
      hpxml.foundation_walls.sort_by! { |foundation_wall| foundation_wall.area }
      hpxml.frame_floors.sort_by! { |frame_floor| [frame_floor.insulation_assembly_r_value, frame_floor.area] }
      hpxml.slabs.sort_by! { |slab| slab.area }
      hpxml.windows.sort_by! { |window| [window.azimuth, window.area] }
      hpxml.plug_loads.sort_by! { |plug_load| [plug_load.plug_load_type, plug_load.kWh_per_year] }

      # Ignore elements that we aren't going to diff
      hpxml.header.xml_type = nil
      hpxml.header.xml_generated_by = nil
      hpxml.header.created_date_and_time = Time.new(2000, 1, 1).strftime('%Y-%m-%dT%H:%M:%S%:z')
      hpxml.site.fuels = [] # Not used by model
      hpxml.climate_and_risk_zones.weather_station_name = nil
      hpxml.climate_and_risk_zones.weather_station_wmo = nil
      hpxml.climate_and_risk_zones.weather_station_epw_filepath = nil
      hpxml.header.state_code = nil
      hpxml.building_construction.conditioned_building_volume = nil
      hpxml.building_construction.average_ceiling_height = nil # Comparing conditioned volume instead
      hpxml.air_infiltration_measurements[0].infiltration_volume = nil
      hpxml.attics.clear()
      hpxml.foundations.clear()
      hpxml.rim_joists.clear() # TODO
      hpxml.refrigerators.each do |refrigerator|
        refrigerator.adjusted_annual_kwh = nil
      end
      hpxml.foundation_walls.each do |foundation_wall|
        next if foundation_wall.insulation_assembly_r_value.nil?
        foundation_wall.insulation_assembly_r_value = foundation_wall.insulation_assembly_r_value.round(2)
      end
      hpxml.walls.each do |wall|
        next unless wall.exterior_adjacent_to == HPXML::LocationOutside
        next unless [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include? wall.interior_adjacent_to

        wall.area = nil # TODO: Attic gable wall areas
      end
      hpxml.windows.each do |window|
        window.area = window.area.round
        window.overhangs_distance_to_bottom_of_window = nil # TODO: Height of windows
      end
      hpxml.doors.each do |door|
        door.azimuth = nil # Not important
        if door.id.include?('Garage')
          door.delete
        end
      end
      hpxml.heat_pumps.each do |heat_pump|
        next if heat_pump.backup_heating_efficiency_afue.nil?

        # These are treated the same in the model, so allow AFUE/percent comparison
        heat_pump.backup_heating_efficiency_percent = heat_pump.backup_heating_efficiency_afue
        heat_pump.backup_heating_efficiency_afue = nil
      end
      hpxml.ventilation_fans.each do |ventilation_fan|
        next unless ventilation_fan.used_for_whole_building_ventilation
        next if ventilation_fan.tested_flow_rate.nil?

        # These are treated the same in the model, so allow tested/rated comparison
        ventilation_fan.rated_flow_rate = ventilation_fan.tested_flow_rate
        ventilation_fan.tested_flow_rate = nil
      end
      hpxml.hvac_controls.each do |hvac_control|
        hvac_control.control_type = nil # Not used by model
      end
      if hpxml.hvac_distributions.length > 0
        (2..hpxml.hvac_distributions[0].ducts.length).to_a.reverse.each do |i|
          hpxml.hvac_distributions[0].ducts.delete_at(i) # Only compare first two ducts
        end
      end
      if hpxml.refrigerators.length > 0
        (2..hpxml.refrigerators.length).to_a.reverse.each do |i|
          hpxml.refrigerators.delete_at(i) # Only compare first two refrigerators
        end
      end
      hpxml.refrigerators.each do |refrigerator|
        refrigerator.primary_indicator = nil
      end
      if hpxml.freezers.length > 0
        (1..hpxml.freezers.length).to_a.reverse.each do |i|
          hpxml.freezers.delete_at(i) # Only compare first freezer
        end
      end
      hpxml.pv_systems.each do |pv_system|
        pv_system.year_modules_manufactured = nil
      end
      hpxml.collapse_enclosure_surfaces()

      # Replace IDs/IDREFs with blank strings
      HPXML::HPXML_ATTRS.each do |attr|
        hpxml_obj = hpxml.send(attr)
        next unless hpxml_obj.is_a? HPXML::BaseArrayElement

        hpxml_obj.each do |obj|
          obj.class::ATTRS.each do |obj_attr|
            next unless obj_attr.to_s.end_with?('id') || obj_attr.to_s.end_with?('_idref')

            obj.send(obj_attr.to_s + '=', '')
          end
        end
      end
    end

    rakefile_doc = hpxml_objs['Rakefile'].to_oga()
    measure_doc = hpxml_objs['BuildResidentialHPXML'].to_oga()

    # Write files for inspection?
    if rakefile_doc.to_xml != measure_doc.to_xml
      rakefile_path = File.join(File.dirname(__FILE__), 'test_rakefile.xml')
      XMLHelper.write_file(rakefile_doc, rakefile_path)
      measure_path = File.join(File.dirname(__FILE__), 'test_measure.xml')
      XMLHelper.write_file(measure_doc, measure_path)
      flunk "ERROR: HPXML files don't match. Wrote #{rakefile_path} and #{measure_path} for inspection."
    else
      pass
    end
  end

  def _setup(this_dir)
    rundir = File.join(this_dir, 'run')
    _rm_path(rundir)
    Dir.mkdir(rundir)
  end

  def _test_measure(osm_file_or_model, args_hash)
    # create an instance of the measure
    measure = HPXMLExporter.new

    # check for standard methods
    assert(!measure.name.empty?)
    assert(!measure.description.empty?)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    model = get_model(File.dirname(__FILE__), osm_file_or_model)

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
  end

  def _rm_path(path)
    if Dir.exist?(path)
      FileUtils.rm_r(path)
    end
    while true
      break if not Dir.exist?(path)

      sleep(0.01)
    end
  end
end
