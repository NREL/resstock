require_relative 'minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../BuildResidentialHPXML/measure.rb'
require 'fileutils'
require 'rexml/document'
require 'rexml/xpath'
require_relative '../HPXMLtoOpenStudio/resources/constants'
require_relative '../HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../HPXMLtoOpenStudio/tests/hpxml_translator_test'

class HPXMLExporterTest < MiniTest::Test
  def test_workflows
    require 'json'

    this_dir = File.dirname(__FILE__)

    hvac_partial_dir = File.absolute_path(File.join(this_dir, "hvac_partial"))
    test_dirs = [this_dir,
                 hvac_partial_dir]

    measures_dir = File.join(this_dir, "../")

    osws = []
    test_dirs.each do |test_dir|
      Dir["#{test_dir}/base*.osw"].sort.each do |osw|
        osws << File.absolute_path(osw)
      end
    end

    tests_dir = File.expand_path(File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/tests"))
    results_dir = File.join(tests_dir, "results")
    _rm_path(results_dir)
    built_dir = File.join(tests_dir, "build_res_hpxml")
    unless Dir.exists?(built_dir)
      Dir.mkdir(built_dir)
    end

    puts "Running #{osws.size} OSW files..."
    all_results = {}
    all_compload_results = {}
    all_sizing_results = {}
    hpxml_translator_test = HPXMLTranslatorTest.new(nil)
    measures = {}
    osws.each do |osw|
      puts "\nTesting #{File.basename(osw)}..."

      _setup(this_dir)
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

        # Translate the hpxml to osm
        xml = "#{File.join(built_dir, File.basename(osw, ".*"))}.xml"
        all_results[xml], all_compload_results[xml], all_sizing_results[xml] = hpxml_translator_test._run_xml(xml, tests_dir)
      end
    end

    Dir.mkdir(results_dir)
    hpxml_translator_test._write_summary_results(results_dir, all_results)
    hpxml_translator_test._write_component_load_results(results_dir, all_compload_results)
    hpxml_translator_test._write_hvac_sizing_results(results_dir, all_sizing_results)
  end

  private

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

    # TODO: get the hpxml and check its elements
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
