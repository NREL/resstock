# frozen_string_literal: true

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class GEBAppliancesPeakPeriodShiftTest < Minitest::Test
  def test_GEBAppliancesPeakPeriodShift
    # create an instance of the measure
    measure = GEBAppliancesPeakPeriodShift.new

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
    assert_equal(2 + 15, arguments.size)

    count = -1

    assert_equal('schedules_peak_period', arguments[count += 1].name)
    assert_equal('schedules_peak_period_delay', arguments[count += 1].name)
    assert_equal('schedules_peak_period_ceiling_fan', arguments[count += 1].name)
    assert_equal('schedules_peak_period_clothes_dryer', arguments[count += 1].name)
    assert_equal('schedules_peak_period_clothes_washer', arguments[count += 1].name)
    assert_equal('schedules_peak_period_cooking_range', arguments[count += 1].name)
    assert_equal('schedules_peak_period_dishwasher', arguments[count += 1].name)
    assert_equal('schedules_peak_period_hot_water_clothes_washer', arguments[count += 1].name)
    assert_equal('schedules_peak_period_hot_water_dishwasher', arguments[count += 1].name)
    assert_equal('schedules_peak_period_hot_water_fixtures', arguments[count += 1].name)
    assert_equal('schedules_peak_period_lighting_garage', arguments[count += 1].name)
    assert_equal('schedules_peak_period_lighting_interior', arguments[count += 1].name)
    assert_equal('schedules_peak_period_occupants', arguments[count += 1].name)
    assert_equal('schedules_peak_period_outage', arguments[count += 1].name)
    assert_equal('schedules_peak_period_plug_loads_other', arguments[count += 1].name)
    assert_equal('schedules_peak_period_plug_loads_tv', arguments[count += 1].name)
    assert_equal('schedules_peak_period_vacancy', arguments[count + 1].name)

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

    schedules_peak_period_ceiling_fan = arguments[count += 1].clone
    assert(schedules_peak_period_ceiling_fan.setValue(false))
    argument_map['schedules_peak_period_ceiling_fan'] = schedules_peak_period_ceiling_fan

    schedules_peak_period_clothes_dryer = arguments[count += 1].clone
    assert(schedules_peak_period_clothes_dryer.setValue(true))
    argument_map['schedules_peak_period_clothes_dryer'] = schedules_peak_period_clothes_dryer

    schedules_peak_period_clothes_washer = arguments[count += 1].clone
    assert(schedules_peak_period_clothes_washer.setValue(true))
    argument_map['schedules_peak_period_clothes_washer'] = schedules_peak_period_clothes_washer

    schedules_peak_period_cooking_range = arguments[count += 1].clone
    assert(schedules_peak_period_cooking_range.setValue(true))
    argument_map['schedules_peak_period_cooking_range'] = schedules_peak_period_cooking_range

    schedules_peak_period_dishwasher = arguments[count += 1].clone
    assert(schedules_peak_period_dishwasher.setValue(true))
    argument_map['schedules_peak_period_dishwasher'] = schedules_peak_period_dishwasher

    schedules_peak_period_hot_water_clothes_washer = arguments[count += 1].clone
    assert(schedules_peak_period_hot_water_clothes_washer.setValue(false))
    argument_map['schedules_peak_period_hot_water_clothes_washer'] = schedules_peak_period_hot_water_clothes_washer

    schedules_peak_period_hot_water_dishwasher = arguments[count += 1].clone
    assert(schedules_peak_period_hot_water_dishwasher.setValue(false))
    argument_map['schedules_peak_period_hot_water_dishwasher'] = schedules_peak_period_hot_water_dishwasher

    schedules_peak_period_hot_water_fixtures = arguments[count += 1].clone
    assert(schedules_peak_period_hot_water_fixtures.setValue(false))
    argument_map['schedules_peak_period_hot_water_fixtures'] = schedules_peak_period_hot_water_fixtures

    schedules_peak_period_lighting_garage = arguments[count += 1].clone
    assert(schedules_peak_period_lighting_garage.setValue(false))
    argument_map['schedules_peak_period_lighting_garage'] = schedules_peak_period_lighting_garage

    schedules_peak_period_lighting_interior = arguments[count += 1].clone
    assert(schedules_peak_period_lighting_interior.setValue(false))
    argument_map['schedules_peak_period_lighting_interior'] = schedules_peak_period_lighting_interior

    schedules_peak_period_occupants = arguments[count += 1].clone
    assert(schedules_peak_period_occupants.setValue(false))
    argument_map['schedules_peak_period_occupants'] = schedules_peak_period_occupants

    schedules_peak_period_outage = arguments[count += 1].clone
    assert(schedules_peak_period_outage.setValue(false))
    argument_map['schedules_peak_period_outage'] = schedules_peak_period_outage

    schedules_peak_period_plug_loads_other = arguments[count += 1].clone
    assert(schedules_peak_period_plug_loads_other.setValue(false))
    argument_map['schedules_peak_period_plug_loads_other'] = schedules_peak_period_plug_loads_other

    schedules_peak_period_plug_loads_tv = arguments[count += 1].clone
    assert(schedules_peak_period_plug_loads_tv.setValue(false))
    argument_map['schedules_peak_period_plug_loads_tv'] = schedules_peak_period_plug_loads_tv

    schedules_peak_period_vacancy = arguments[count + 1].clone
    assert(schedules_peak_period_vacancy.setValue(false))
    argument_map['schedules_peak_period_vacancy'] = schedules_peak_period_vacancy

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
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/test_GEBAppliancesPeakPeriodShift.osm')
    model.save(output_file_path, true)
  end
end
