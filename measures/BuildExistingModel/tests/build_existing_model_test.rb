# frozen_string_literal: true

require 'parallel'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../measure.rb'

$start_time = Time.now

class BuildExistingModelTest < Minitest::Test
  def setup
    @lib_dir = File.join(File.dirname(__FILE__), '../../../lib')
    resources_dir = File.join(File.dirname(__FILE__), '../../../resources')
    housing_characteristics_dir = File.join(File.dirname(__FILE__), '../../../project_national/housing_characteristics')

    FileUtils.rm_rf(@lib_dir)
    Dir.mkdir(@lib_dir)
    FileUtils.cp_r(resources_dir, @lib_dir)
    FileUtils.cp_r(housing_characteristics_dir, @lib_dir)

    @results_dir = File.join(File.dirname(__FILE__), 'results')
    FileUtils.rm_rf(@results_dir)
    Dir.mkdir(@results_dir)
  end

  def teardown
    FileUtils.rm_rf(@lib_dir)
    FileUtils.rm_rf(@results_dir)
  end

  def test_building
    args_hash = {}
    args_hash['buildstock_csv_path'] = File.join(File.dirname(__FILE__), '../../../test/base_results/baseline/annual/buildstock.csv')

    building_ids = (1..10000).to_a
    in_threads = Parallel.processor_count
    completed = []
    Parallel.map(building_ids, in_threads: in_threads) do |building_id|
      worker_dir = File.join(@results_dir, "#{Parallel.worker_number + 1}")
      FileUtils.rm_rf(worker_dir)
      Dir.mkdir(worker_dir)

      args_hash['building_id'] = building_id
      args_hash['hpxml_path'] = File.join(worker_dir, 'existing.xml')
      _test_measure(args_hash)
      completed << building_id

      info = "[Parallel(n_jobs=#{in_threads})]: "
      max_size = "#{building_ids.size}".size
      info += "%#{max_size}s" % "#{completed.size}"
      info += " / #{building_ids.size}"
      info += ' | elapsed: '
      info += '%8s' % "#{_get_elapsed_time(Time.now, $start_time)}"
      puts info
    end
  end

  private

  def _test_measure(args_hash)
    # create an instance of the measure
    measure = BuildExistingModel.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    args_hash['output_dir'] = File.dirname(__FILE__)
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

  def _get_elapsed_time(t1, t0)
    s = t1 - t0
    if s > 60 # min
      t = "#{(s / 60).round(1)}min"
    elsif s > 3600 # hr
      t = "#{(s / 3600).round(1)}hr"
    else # sec
      t = "#{s.round(1)}s"
    end
    return t
  end
end
