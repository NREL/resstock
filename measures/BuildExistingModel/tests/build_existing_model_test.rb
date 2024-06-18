# frozen_string_literal: true

require 'parallel'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require_relative '../../../resources/hpxml-measures/BuildResidentialHPXML/resources/geometry'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/meta_measure'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/unit_conversions'

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

    resources_dir = File.join(@lib_dir, 'resources')
    characteristics_dir = File.join(@lib_dir, 'housing_characteristics')
    buildstock_file = File.join(resources_dir, 'buildstock.rb')
    @measures_dir = File.join(File.dirname(__FILE__), '../../../measures')
    @lookup_file = File.join(resources_dir, 'options_lookup.tsv')
    require File.join(File.dirname(buildstock_file), File.basename(buildstock_file, File.extname(buildstock_file)))
    @lookup_csv_data = CSV.open(@lookup_file, col_sep: "\t").each.to_a
    @parameters_ordered = get_parameters_ordered_from_options_lookup_tsv(@lookup_csv_data, characteristics_dir)
  end

  def teardown
    FileUtils.rm_rf(@lib_dir)
  end

  def test_create_geometry
    buildstock_csv_path = File.join(File.dirname(__FILE__), '../../../test/base_results/baseline/annual/buildstock.csv')
    arg_names = ['geometry_unit_type',
                 'geometry_unit_cfa',
                 'geometry_average_ceiling_height',
                 'geometry_unit_num_floors_above_grade',
                 'geometry_unit_aspect_ratio',
                 'geometry_garage_width',
                 'geometry_garage_depth',
                 'geometry_garage_protrusion',
                 'geometry_garage_position',
                 'geometry_foundation_type',
                 'geometry_foundation_height',
                 'geometry_rim_joist_height',
                 'geometry_attic_type',
                 'geometry_roof_type',
                 'geometry_roof_pitch',
                 'geometry_unit_left_wall_is_adiabatic',
                 'geometry_unit_right_wall_is_adiabatic',
                 'geometry_unit_front_wall_is_adiabatic',
                 'geometry_unit_back_wall_is_adiabatic']

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    building_ids = (1..10000).to_a
    in_threads = Parallel.processor_count
    completed = []
    Parallel.map(building_ids, in_threads: in_threads) do |building_id|
      bldg_data = get_data_for_sample(buildstock_csv_path, building_id, runner)
      _test_measure(runner, model, arg_names, bldg_data)
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

  def _to_float(value)
    begin
      return Float(value)
    rescue
      return value
    end
  end

  def _test_measure(runner, model, arg_names, bldg_data)
    measures = {}
    @parameters_ordered.each do |parameter_name|
      option_name = bldg_data[parameter_name]
      print_option_assignment(parameter_name, option_name, runner)
      options_measure_args, _errors = get_measure_args_from_option_names(@lookup_csv_data, [option_name], parameter_name, @lookup_file, runner)
      options_measure_args[option_name].each do |measure_subdir, args_hash|
        update_args_hash(measures, measure_subdir, args_hash, false)
      end
    end

    resstock_arguments_runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new) # we want only ResStockArguments registered argument values
    apply_measures(@measures_dir, { 'ResStockArguments' => measures['ResStockArguments'] }, resstock_arguments_runner, model, true, 'OpenStudio::Measure::ModelMeasure')

    args = {}
    resstock_arguments_runner.result.stepValues.each do |step_value|
      value = get_value_from_workflow_step_value(step_value)
      next unless arg_names.include?(step_value.name)

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
