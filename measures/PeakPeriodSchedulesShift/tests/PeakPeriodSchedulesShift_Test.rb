# frozen_string_literal: true

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class PeakPeriodSchedulesShiftTest < Minitest::Test
  def test_PeakPeriodSchedulesShift
    # create an instance of the measure
    measure = PeakPeriodSchedulesShift.new

    # create an instance of a runner
    workflow_json = OpenStudio::WorkflowJSON.new
    workflow_json.addFilePath(File.join(File.dirname(__FILE__), 'files'))
    runner = OpenStudio::Measure::OSRunner.new(workflow_json)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/base-schedules-detailed-occupancy-stochastic.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get
    model.setWorkflowJSON(workflow_json)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)

    count = -1

    assert_equal('schedules_peak_period', arguments[count += 1].name)
    assert_equal('schedules_peak_period_delay', arguments[count += 1].name)
    assert_equal('schedules_peak_period_column_names', arguments[count + 1].name)

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    schedules_peak_period = arguments[count += 1].clone
    assert(schedules_peak_period.setValue('17 - 19'))
    argument_map['schedules_peak_period'] = schedules_peak_period

    schedules_peak_period_delay = arguments[count += 1].clone
    assert(schedules_peak_period_delay.setValue(1))
    argument_map['schedules_peak_period_delay'] = schedules_peak_period_delay

    schedules_peak_period_column_names = arguments[count + 1].clone
    assert(schedules_peak_period_column_names.setValue('dishwasher, clothes_washer, clothes_dryer, cooking_range'))
    argument_map['schedules_peak_period_column_names'] = schedules_peak_period_column_names

    # before
    schedules_before = {}
    model.getExternalFiles.each do |external_file|
      external_file_path = external_file.filePath.to_s

      schedules = Schedules.new(file_path: external_file_path)
      schedules_before = schedules.schedules
    end

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 4)

    # after
    schedules_after = {}
    model.getExternalFiles.each do |external_file|
      external_file_path = external_file.filePath.to_s

      schedules = Schedules.new(file_path: external_file_path)
      schedules_after = schedules.schedules
    end

    assert(!schedules_before.empty?)
    assert(!schedules_after.empty?)
    assert(schedules_before['ceiling_fan'][0] == schedules_after['ceiling_fan'][0])
    assert(schedules_before['clothes_dryer'][0] == schedules_after['clothes_dryer'][0])
    assert(schedules_before['clothes_washer'][0] == schedules_after['clothes_washer'][0])
    assert(schedules_before['cooking_range'][0] == schedules_after['cooking_range'][0])
    assert(schedules_before['dishwasher'][0] == schedules_after['dishwasher'][0])
    assert(schedules_before['hot_water_clothes_washer'][0] == schedules_after['hot_water_clothes_washer'][0])
    assert(schedules_before['hot_water_dishwasher'][0] == schedules_after['hot_water_dishwasher'][0])
    assert(schedules_before['hot_water_fixtures'][0] == schedules_after['hot_water_fixtures'][0])
    assert(schedules_before['lighting_garage'][0] == schedules_after['lighting_garage'][0])
    assert(schedules_before['lighting_interior'][0] == schedules_after['lighting_interior'][0])
    assert(schedules_before['occupants'][0] == schedules_after['occupants'][0])
    assert(schedules_before['plug_loads_other'][0] == schedules_after['plug_loads_other'][0])
    assert(schedules_before['plug_loads_tv'][0] == schedules_after['plug_loads_tv'][0])

    # save the model
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/test_PeakPeriodSchedulesShift.osm')
    model.save(output_file_path, true)
  end
end
