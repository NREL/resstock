# frozen_string_literal: true

require 'csv'
require 'parallel'
require 'openstudio'
require_relative '../../../resources/buildstock'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../measure.rb'

class ResStockArgumentsTest < Minitest::Test
  def setup
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../resources'))
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')
    @lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a
  end

  def test_options_lookup_assignment
    lookup_arguments = []
    @lookup_csv_data.each do |lookup_row|
      next if lookup_row[2] != 'ResStockArguments'

      lookup_row[3..-1].each do |argument_value|
        argument, _value = argument_value.split('=')
        lookup_arguments << argument if !lookup_arguments.include?(argument)
      end
    end

    measure = ResStockArguments.new
    model = OpenStudio::Model::Model.new
    resstock_arguments = []
    measure.arguments(model).each do |arg|
      next if Constants.other_excludes.include? arg.name

      resstock_arguments << arg.name
    end

    resstock_arguments_extras = resstock_arguments - lookup_arguments
    puts "resstock_arguments - lookup_arguments: #{resstock_arguments_extras.sort}" if !resstock_arguments_extras.empty?
    assert_equal(0, resstock_arguments_extras.size)
  end

  def test_create_geometry_envelope
    characteristics_dir = File.join(File.dirname(__FILE__), '../../../project_national/housing_characteristics')
    parameters_ordered = get_parameters_ordered_from_options_lookup_tsv(@lookup_csv_data, characteristics_dir)
    measures_dir = File.join(File.dirname(__FILE__), '../../../measures')
    parameter_options_measure_args = _get_parameter_options_measure_args(@lookup_csv_data)
    arg_name_prefixes = ['geometry', 'door', 'window', 'skylight']
    buildstock_csv_path = File.join(File.dirname(__FILE__), '../../../test/base_results/baseline/annual/buildstock.csv')
    building_ids = (1..(CSV.read(buildstock_csv_path).size - 1)).to_a
    building_ids = building_ids.sample(0.8 * building_ids.size, random: Random.new(12345)) # 80% for runtime reduction

    failures = []
    completed = []
    in_threads = Parallel.processor_count
    start_time = Time.now
    Parallel.map(building_ids, in_threads: in_threads) do |building_id|
      success = _test_measure(parameters_ordered, measures_dir, parameter_options_measure_args, arg_name_prefixes, buildstock_csv_path, building_id)

      failures << building_id unless success
      completed << building_id

      info = "[Parallel(n_jobs=#{in_threads})]: "
      max_size = "#{building_ids.size}".size
      info += "%#{max_size}s" % "#{completed.size}"
      info += " / #{building_ids.size}"
      info += ' | elapsed: '
      info += '%8s' % "#{_get_elapsed_time(Time.now, start_time)}"
      puts info
    end

    if not failures.empty?
      puts "\nFailures detected for: #{failures.join(', ')}."
      assert(false)
    end
  end

  private

  def _get_parameter_options_measure_args(lookup_csv_data)
    # {'Parameter 1' => {'Option 1' => {'ResStockArguments' => {'argument_1' => 1, 'argument_2' => 2, ...}}, {'Option 2' => {...}}}}

    parameter_options_measure_args = {}
    lookup_csv_data.each do |row|
      next if row.size < 2

      parameter = row[0]
      option_name = row[1]
      measure_dir = row[2]
      args = {}
      for col in 3..(row.size - 1)
        next unless row[col].include?('=')

        data = row[col].split('=')
        arg_name = data[0]
        arg_val = data[1]
        args[arg_name] = arg_val
      end
      next if args.empty?

      if !parameter_options_measure_args.key?(parameter)
        parameter_options_measure_args[parameter] = {}
      end
      parameter_options_measure_args[parameter][option_name] = { measure_dir => args }
    end

    return parameter_options_measure_args
  end

  def _test_measure(parameters_ordered, measures_dir, parameter_options_measure_args, arg_name_prefixes, buildstock_csv_path, building_id)
    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    bldg_data = get_data_for_sample(buildstock_csv_path, building_id, runner)

    measures = {}
    parameters_ordered.each do |parameter_name|
      option_name = bldg_data[parameter_name]
      options_measure_args = Marshal.load(Marshal.dump(parameter_options_measure_args[parameter_name]))
      next if options_measure_args.nil?

      options_measure_args = options_measure_args[option_name]
      next if options_measure_args.nil?

      options_measure_args.each do |measure_subdir, args_hash|
        update_args_hash(measures, measure_subdir, args_hash, false)
      end
    end

    resstock_arguments_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    apply_measures(measures_dir, { 'ResStockArguments' => measures['ResStockArguments'] }, resstock_arguments_runner, model)

    args = {}
    resstock_arguments_runner.result.stepValues.each do |step_value|
      value = get_value_from_workflow_step_value(step_value)
      next unless step_value.name.start_with?(*arg_name_prefixes)

      args[step_value.name.to_sym] = _to_float(value)
    end

    success = HPXMLFile.create_geometry_envelope(runner, model, args)
    return success
  end

  def _to_float(value)
    begin
      return Float(value)
    rescue
      return value
    end
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
