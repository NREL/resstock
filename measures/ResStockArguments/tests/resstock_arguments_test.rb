# frozen_string_literal: true

require 'csv'
require 'parallel'
require 'openstudio'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../measure.rb'

class ResStockArgumentsTest < Minitest::Test
  def setup
    @resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../resources'))
    lookup_file = File.join(@resources_dir, 'options_lookup.tsv')
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

  def test_create_geometry
    @lib_dir = File.join(File.dirname(__FILE__), '../../../lib')
    housing_characteristics_dir = File.join(File.dirname(__FILE__), '../../../project_national/housing_characteristics')

    FileUtils.rm_rf(@lib_dir)
    Dir.mkdir(@lib_dir)
    FileUtils.cp_r(@resources_dir, @lib_dir)
    FileUtils.cp_r(housing_characteristics_dir, @lib_dir)

    resources_dir = File.join(@lib_dir, 'resources')
    characteristics_dir = File.join(@lib_dir, 'housing_characteristics')
    buildstock_file = File.join(resources_dir, 'buildstock.rb')
    @measures_dir = File.join(File.dirname(__FILE__), '../../../measures')
    require File.join(File.dirname(buildstock_file), File.basename(buildstock_file, File.extname(buildstock_file)))
    @parameters_ordered = get_parameters_ordered_from_options_lookup_tsv(@lookup_csv_data, characteristics_dir)

    buildstock_csv_path = File.join(File.dirname(__FILE__), '../../../test/base_results/baseline/annual/buildstock.csv')
    arg_name_prefix = 'geometry'

    start_time = Time.now

    building_ids = (1..(CSV.read(buildstock_csv_path).size - 1)).to_a
    completed = []
    in_threads = Parallel.processor_count
    Parallel.map(building_ids, in_threads: in_threads) do |building_id|
      _test_measure(buildstock_csv_path, building_id, arg_name_prefix)
      completed << building_id

      info = "[Parallel(n_jobs=#{in_threads})]: "
      max_size = "#{building_ids.size}".size
      info += "%#{max_size}s" % "#{completed.size}"
      info += " / #{building_ids.size}"
      info += ' | elapsed: '
      info += '%8s' % "#{_get_elapsed_time(Time.now, start_time)}"
      puts info
    end

    FileUtils.rm_rf(@lib_dir)
  end

  private

  def _test_measure(buildstock_csv_path, building_id, arg_name_prefix)
    model = OpenStudio::Model::Model.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    bldg_data = get_data_for_sample(buildstock_csv_path, building_id, runner)

    measures = {}
    @parameters_ordered.each do |parameter_name|
      option_name = bldg_data[parameter_name]
      print_option_assignment(parameter_name, option_name, runner)
      options_measure_args, _errors = get_measure_args_from_option_names(@lookup_csv_data, [option_name], parameter_name, @lookup_file, runner)
      options_measure_args[option_name].each do |measure_subdir, args_hash|
        update_args_hash(measures, measure_subdir, args_hash, false)
      end
    end

    resstock_arguments_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    apply_measures(@measures_dir, { 'ResStockArguments' => measures['ResStockArguments'] }, resstock_arguments_runner, model, true, 'OpenStudio::Measure::ModelMeasure')

    args = {}
    resstock_arguments_runner.result.stepValues.each do |step_value|
      value = get_value_from_workflow_step_value(step_value)
      next unless step_value.name.start_with?(arg_name_prefix)

      args[step_value.name.to_sym] = _to_float(value)
    end

    args[:geometry_roof_pitch] = { '1:12' => 1.0 / 12.0,
                                   '2:12' => 2.0 / 12.0,
                                   '3:12' => 3.0 / 12.0,
                                   '4:12' => 4.0 / 12.0,
                                   '5:12' => 5.0 / 12.0,
                                   '6:12' => 6.0 / 12.0,
                                   '7:12' => 7.0 / 12.0,
                                   '8:12' => 8.0 / 12.0,
                                   '9:12' => 9.0 / 12.0,
                                   '10:12' => 10.0 / 12.0,
                                   '11:12' => 11.0 / 12.0,
                                   '12:12' => 12.0 / 12.0 }[args[:geometry_roof_pitch]]

    args[:geometry_rim_joist_height] = args[:geometry_rim_joist_height].to_f / 12.0

    if args[:geometry_unit_type] == HPXML::ResidentialTypeSFD
      success = Geometry.create_single_family_detached(runner: runner, model: model, **args)
    elsif args[:geometry_unit_type] == HPXML::ResidentialTypeSFA
      success = Geometry.create_single_family_attached(model: model, **args)
    elsif args[:geometry_unit_type] == HPXML::ResidentialTypeApartment
      args[:geometry_unit_num_floors_above_grade] = 1
      success = Geometry.create_apartment(model: model, **args)
    elsif args[:geometry_unit_type] == HPXML::ResidentialTypeManufactured
      success = Geometry.create_single_family_detached(runner: runner, model: model, **args)
    end

    assert(success)
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
