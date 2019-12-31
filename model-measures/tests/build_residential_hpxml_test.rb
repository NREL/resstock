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

class HPXMLExporterTest < MiniTest::Test
  @@this_dir = File.dirname(__FILE__)

  def test_sfd_slab
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family detached"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfd_vented_attic
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family detached"
    args_hash["attic_type"] = "attic - vented"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfd_unvented_attic
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family detached"
    args_hash["attic_type"] = "attic - unvented"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfd_conditioned_attic
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family detached"
    args_hash["attic_type"] = "attic - conditioned"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfd_vented_crawl
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family detached"
    args_hash["foundation type"] = "crawlspace - vented"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfd_unvented_crawl
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family detached"
    args_hash["foundation type"] = "crawlspace - unvented"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfd_uconditioned_basement
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family detached"
    args_hash["foundation type"] = "basement - unconditioned"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfd_conditioned_basement
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family detached"
    args_hash["foundation type"] = "basement - conditioned"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfd_ambient
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family detached"
    args_hash["foundation type"] = "ambient"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfa_slab
    skip
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family attached"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfa_vented_crawl
    skip
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family attached"
    args_hash["cfa"] = 900.0
    args_hash["foundation type"] = "crawlspace - vented"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfa_unvented_crawl
    skip
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family attached"
    args_hash["cfa"] = 900.0
    args_hash["foundation type"] = "crawlspace - unvented"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfa_unconditioned_basement
    skip
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family attached"
    args_hash["cfa"] = 900.0
    args_hash["foundation type"] = "basement - unconditioned"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_sfa_conditioned_basement
    skip
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "single-family attached"
    args_hash["cfa"] = 900.0
    args_hash["foundation type"] = "basement - conditioned"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_mf_slab
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "multifamily"
    args_hash["cfa"] = 900.0
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_mf_vented_crawl
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "multifamily"
    args_hash["cfa"] = 900.0
    args_hash["foundation type"] = "crawlspace - vented"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_mf_unvented_crawl
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "multifamily"
    args_hash["cfa"] = 900.0
    args_hash["foundation type"] = "crawlspace - unvented"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_mf_unconditioned_basement
    _setup(@@this_dir)
    args_hash = {}
    args_hash["unit_type"] = "multifamily"
    args_hash["cfa"] = 900.0
    args_hash["foundation type"] = "basement - unconditioned"
    args_hash["hpxml_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "in.xml"))
    args_hash["schedules_output_path"] = File.absolute_path(File.join(@@this_dir, "run", "schedules.csv"))
    _test_measure(nil, args_hash)
  end

  def test_workflows
    require 'json'

    test_dirs = [@@this_dir]
    measures_dir = File.join(@@this_dir, "../")

    osws = []
    test_dirs.each do |test_dir|
      Dir["#{test_dir}/base*.osw"].sort.each do |osw|
        osws << File.absolute_path(osw)
      end
    end

    puts "Running #{osws.size} OSW files..."
    measures = {}
    osws.each do |osw|
      _setup(@@this_dir)
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
      end
    end
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
