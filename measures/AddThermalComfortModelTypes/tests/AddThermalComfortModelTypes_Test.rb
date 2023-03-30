# frozen_string_literal: true

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class AddThermalComfortModelTypesTest < Minitest::Test
  def test_AddThermalComfortModelTypes
    # create an instance of the measure
    measure = AddThermalComfortModelTypes.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(10, arguments.size)

    count = -1

    assert_equal('thermal_comfort_model_type_fanger', arguments[count += 1].name)
    assert_equal('thermal_comfort_model_type_pierce', arguments[count += 1].name)
    assert_equal('thermal_comfort_model_type_ksu', arguments[count += 1].name)
    assert_equal('thermal_comfort_model_type_adaptiveash55', arguments[count += 1].name)
    assert_equal('thermal_comfort_model_type_adaptivecen15251', arguments[count += 1].name)
    assert_equal('thermal_comfort_model_type_coolingeffectash55', arguments[count += 1].name)
    assert_equal('thermal_comfort_model_type_ankledraftash55', arguments[count += 1].name)
    assert_equal('work_efficiency_schedule_value', arguments[count += 1].name)
    assert_equal('clothing_insulation_schedule_value', arguments[count += 1].name)
    assert_equal('air_velocity_schedule_value', arguments[count + 1].name)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/base-schedules-simple-power-outage.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    thermal_comfort_model_type_fanger = arguments[count += 1].clone
    assert(thermal_comfort_model_type_fanger.setValue(true))
    argument_map['thermal_comfort_model_type_fanger'] = thermal_comfort_model_type_fanger

    thermal_comfort_model_type_pierce = arguments[count + 1].clone
    assert(thermal_comfort_model_type_pierce.setValue(true))
    argument_map['thermal_comfort_model_type_pierce'] = thermal_comfort_model_type_pierce

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 0)

    # save the model
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/test_AddThermalComfortModelTypes.osm')
    model.save(output_file_path, true)
  end
end
