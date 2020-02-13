require_relative 'minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require 'rexml/document'
require 'rexml/xpath'
require 'compare-xml'
require_relative '../../HPXMLtoOpenStudio/resources/meta_measure'

class BuildResidentialHPXMLTest < MiniTest::Test
  def test_workflows
    require 'json'

    this_dir = File.dirname(__FILE__)

    hvac_partial_dir = File.absolute_path(File.join(this_dir, "hvac_partial"))
    test_dirs = [
      this_dir,
      # hvac_partial_dir
    ]

    measures_dir = File.join(this_dir, "../..")

    osws = []
    test_dirs.each do |test_dir|
      Dir["#{test_dir}/base*.osw"].sort.each do |osw|
        osws << File.absolute_path(osw)
      end
    end

    workflow_dir = File.expand_path(File.join(File.dirname(__FILE__), "../../workflow/tests"))
    tests_dir = File.expand_path(File.join(File.dirname(__FILE__), "../../BuildResidentialHPXML/tests"))
    built_dir = File.join(tests_dir, "built_residential_hpxml")
    unless Dir.exists?(built_dir)
      Dir.mkdir(built_dir)
    end

    puts "Running #{osws.size} OSW files..."
    measures = {}
    fail = false
    osws.each do |osw|
      puts "\nTesting #{File.basename(osw)}..."

      _setup(tests_dir)
      osw_hash = JSON.parse(File.read(osw))
      osw_hash["steps"].each do |step|
        measures[step["measure_dir_name"]] = [step["arguments"]]
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

        if ["base-single-family-attached.osw", "base-multifamily.osw"].include? File.basename(osw)
          next # FIXME: should this be temporary?
        end

        # Compare the hpxml to the manually created one
        test_dir = File.basename(File.dirname(osw))
        hpxml_path = step["arguments"]["hpxml_path"]
        begin
          _check_hpxmls(workflow_dir, built_dir, test_dir, hpxml_path)
        rescue Exception => e
          puts e
          fail = true
        end
      end
    end

    assert false if fail
  end

  private

  def _check_hpxmls(workflow_dir, built_dir, test_dir, hpxml_path)
    if test_dir == "tests"
      test_dir = ""
    end

    hpxml_path = {
      "Rakefile" => File.join(workflow_dir, test_dir, File.basename(hpxml_path)),
      "BuildResidentialHPXML" => File.join(built_dir, File.basename(hpxml_path))
    }

    hpxml_docs = {
      "Rakefile" => XMLHelper.parse_file(hpxml_path["Rakefile"]),
      "BuildResidentialHPXML" => XMLHelper.parse_file(hpxml_path["BuildResidentialHPXML"])
    }

    # Sort elements so we can diff them
    _sort_wall_elements(hpxml_docs)
    _sort_fwall_elements(hpxml_docs)
    _sort_floor_elements(hpxml_docs)
    _sort_window_elements(hpxml_docs)

    # Delete elements that we aren't going to diff
    _delete_elements(hpxml_docs, "HPXML/XMLTransactionHeaderInformation")
    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/BuildingSummary/Site")
    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/BuildingSummary/BuildingOccupancy")
    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/ClimateandRiskZones")
    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/Enclosure/Attics")
    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/Enclosure/Foundations")
    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/Enclosure/RimJoists")
    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/Enclosure/Doors")
    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/Appliances/Refrigerator/extension")
    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/extension")

    hpxml_docs = {
      "Rakefile" => Nokogiri::XML(hpxml_docs["Rakefile"].to_s).remove_namespaces!,
      "BuildResidentialHPXML" => Nokogiri::XML(hpxml_docs["BuildResidentialHPXML"].to_s).remove_namespaces!
    }

    opts = { verbose: true }
    compare_xml = CompareXML.equivalent?(hpxml_docs["Rakefile"], hpxml_docs["BuildResidentialHPXML"], opts)
    discrepancies = ""
    compare_xml.each do |discrepancy|
      unless discrepancy[:node1].nil?
        next if discrepancy[:node1].attributes.keys.include? "id"
        next if discrepancy[:node1].attributes.keys.include? "idref"
      end

      parent_id = "nil"
      parent_element = "nil"
      if not discrepancy[:node1].nil?
        parent_element = discrepancy[:node1].name
        parent = discrepancy[:node1].parent
        parent_sysid = parent.xpath("SystemIdentifier")
        if not parent_sysid.empty?
          parent_id = parent_sysid.attribute("id").to_s
        end
      end
      parent_text = discrepancy[:diff1]

      next if parent_id == "WallAtticGable" and parent_element == "Area" # FIXME

      child_id = "nil"
      child_element = "nil"
      if not discrepancy[:node2].nil?
        child_element = discrepancy[:node2].name
        child = discrepancy[:node2].parent
        child_sysid = child.xpath("SystemIdentifier")
        if not child_sysid.empty?
          child_id = child_sysid.attribute("id").to_s
        end
      end
      child_text = discrepancy[:diff2]

      discrepancies << "(#{parent_id}: #{parent_element}: #{parent_text}) : (#{child_id}: #{child_element}: #{child_text}}\n"
    end

    unless discrepancies.empty?
      raise discrepancies
    end
  end

  def _delete_elements(hpxml_docs, element)
    hpxml_docs.each do |key, hpxml_doc|
      XMLHelper.delete_element(hpxml_doc, element)
    end
  end

  def _sort_wall_elements(hpxml_docs)
    sorted_elements = {}
    ["Rakefile", "BuildResidentialHPXML"].each do |version|
      elements = {}
      hpxml_docs[version].elements.each("HPXML/Building/BuildingDetails/Enclosure/Walls/Wall") do |wall|
        wall_values = HPXML.get_wall_values(wall: wall)
        elements[wall_values[:area]] = wall_values
      end
      sorted_elements[version] = elements.sort_by { |area, wall| area }
    end

    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/Enclosure/Walls")

    sorted_elements.each do |version, elements|
      elements.each do |wall|
        wall_values = wall[1]
        wall_values.each do |key, value|
          next unless value.nil?

          wall_values.delete(key)
        end
        HPXML.add_wall(hpxml: hpxml_docs[version].elements["HPXML"], **wall_values)
      end
    end
  end

  def _sort_fwall_elements(hpxml_docs)
    sorted_elements = {}
    ["Rakefile", "BuildResidentialHPXML"].each do |version|
      elements = {}
      hpxml_docs[version].elements.each("HPXML/Building/BuildingDetails/Enclosure/FoundationWalls/FoundationWall") do |foundation_wall|
        fwall_values = HPXML.get_foundation_wall_values(foundation_wall: foundation_wall)
        elements[fwall_values[:area]] = fwall_values
      end
      sorted_elements[version] = elements.sort_by { |area, fwall| area }
    end

    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/Enclosure/FoundationWalls")

    sorted_elements.each do |version, elements|
      elements.each do |wall|
        fwall_values = wall[1]
        fwall_values.each do |key, value|
          next unless value.nil?

          fwall_values.delete(key)
        end
        HPXML.add_foundation_wall(hpxml: hpxml_docs[version].elements["HPXML"], **fwall_values)
      end
    end
  end

  def _sort_floor_elements(hpxml_docs)
    sorted_elements = {}
    ["Rakefile", "BuildResidentialHPXML"].each do |version|
      elements = {}
      hpxml_docs[version].elements.each("HPXML/Building/BuildingDetails/Enclosure/FrameFloors/FrameFloor") do |framefloor|
        framefloor_values = HPXML.get_framefloor_values(framefloor: framefloor)
        elements[framefloor_values[:exterior_adjacent_to]] = framefloor_values
      end
      sorted_elements[version] = elements.sort_by { |exterior_adjacent_to, floor| exterior_adjacent_to }
    end

    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/Enclosure/FrameFloors")

    sorted_elements.each do |version, elements|
      elements.each do |floor|
        framefloor_values = floor[1]
        framefloor_values.each do |key, value|
          next unless value.nil?

          framefloor_values.delete(key)
        end
        HPXML.add_framefloor(hpxml: hpxml_docs[version].elements["HPXML"], **framefloor_values)
      end
    end
  end

  def _sort_window_elements(hpxml_docs)
    sorted_elements = {}
    ["Rakefile", "BuildResidentialHPXML"].each do |version|
      elements = {}
      hpxml_docs[version].elements.each("HPXML/Building/BuildingDetails/Enclosure/Windows/Window") do |window|
        window_values = HPXML.get_window_values(window: window)
        elements[window_values[:azimuth]] = window_values
      end
      sorted_elements[version] = elements.sort_by { |azimuth, window| azimuth }
    end

    _delete_elements(hpxml_docs, "HPXML/Building/BuildingDetails/Enclosure/Windows")

    sorted_elements.each do |version, elements|
      elements.each do |window|
        window_values = window[1]
        window_values.each do |key, value|
          next unless value.nil?

          window_values.delete(key)
        end
        HPXML.add_window(hpxml: hpxml_docs[version].elements["HPXML"], **window_values)
      end
    end
  end

  def _setup(this_dir)
    rundir = File.join(this_dir, "run")
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
    show_output(result) unless result.value.valueName == "Success"

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
  end

  def _rm_path(path)
    if Dir.exists?(path)
      FileUtils.rm_r(path)
    end
    while true
      break if not Dir.exists?(path)

      sleep(0.01)
    end
  end
end
