require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require 'rexml/document'
require 'rexml/xpath'
require_relative '../../HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../HPXMLtoOpenStudio/resources/hpxml'

class BuildResidentialHPXMLTest < MiniTest::Test
  def test_workflows
    require 'json'

    this_dir = File.dirname(__FILE__)

    hvac_partial_dir = File.absolute_path(File.join(this_dir, 'hvac_partial'))
    test_dirs = [
      this_dir,
      # hvac_partial_dir
    ]

    measures_dir = File.join(this_dir, '../..')

    osws = []
    test_dirs.each do |test_dir|
      Dir["#{test_dir}/base*.osw"].sort.each do |osw|
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
    measures_dir = File.join(this_dir, '../..')

    expected_error_msgs = {
      'non-electric-heat-pump-water-heater.osw' => 'water_heater_type=heat pump water heater and water_heater_fuel_type=natural gas'
    }

    measures = {}
    Dir["#{this_dir}/invalid_files/*.osw"].sort.each do |osw|
      puts "\nTesting #{File.basename(osw)}..."

      _setup(this_dir)
      osw_hash = JSON.parse(File.read(osw))
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
          assert_equal(s, expected_error_msgs[File.basename(osw)])
        end

        assert(!success)
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
      hpxml.walls.sort_by! { |wall| wall.area }
      hpxml.foundation_walls.sort_by! { |foundation_wall| foundation_wall.area }
      hpxml.frame_floors.sort_by! { |frame_floor| frame_floor.exterior_adjacent_to }
      hpxml.slabs.sort_by! { |slab| slab.area }
      hpxml.windows.sort_by! { |window| [window.azimuth, window.area] }

      # Delete elements that we aren't going to diff
      hpxml.header.xml_type = nil
      hpxml.header.xml_generated_by = nil
      hpxml.header.created_date_and_time = Time.new(2000, 1, 1).strftime('%Y-%m-%dT%H:%M:%S%:z')
      hpxml.set_site()
      hpxml.set_building_occupancy()
      hpxml.set_climate_and_risk_zones()
      hpxml.attics.clear()
      hpxml.foundations.clear()
      hpxml.rim_joists.clear()
      hpxml.doors.clear()
      hpxml.refrigerators.each do |refrigerator|
        refrigerator.adjusted_annual_kwh = nil
        refrigerator.schedules_output_path = nil
        refrigerator.schedules_column_name = nil
      end
      hpxml.walls.each do |wall|
        next unless wall.exterior_adjacent_to == HPXML::LocationOutside
        next unless [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include? wall.interior_adjacent_to

        wall.area = nil # Attic gable wall areas
      end
      hpxml.windows.each do |window|
        window.area = window.area.round(2)
        window.overhangs_distance_to_bottom_of_window = nil # Height of windows
      end

      # Replace IDs/IDREFs with blank strings
      HPXML::HPXML_ATTRS.each do |attr|
        hpxml_obj = hpxml.send(attr)
        next unless hpxml_obj.is_a? HPXML::BaseArrayElement

        hpxml_obj.each do |obj|
          obj.class::ATTRS.each do |obj_attr|
            next unless (obj_attr.to_s == 'id') || obj_attr.to_s.end_with?('_idref')

            obj.send(obj_attr.to_s + '=', '')
          end
        end
      end
    end

    rakefile_doc = hpxml_objs['Rakefile'].to_rexml
    measure_doc = hpxml_objs['BuildResidentialHPXML'].to_rexml

    # Write files for inspection?
    if rakefile_doc.to_s != measure_doc.to_s
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
