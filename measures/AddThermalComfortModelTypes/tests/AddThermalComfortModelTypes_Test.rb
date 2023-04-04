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

    thermal_comfort_model_type_pierce = arguments[count += 1].clone
    assert(thermal_comfort_model_type_pierce.setValue(true))
    argument_map['thermal_comfort_model_type_pierce'] = thermal_comfort_model_type_pierce

    thermal_comfort_model_type_ksu = arguments[count += 1].clone
    assert(thermal_comfort_model_type_ksu.setValue(false))
    argument_map['thermal_comfort_model_type_ksu'] = thermal_comfort_model_type_ksu

    thermal_comfort_model_type_adaptiveash55 = arguments[count += 1].clone
    assert(thermal_comfort_model_type_adaptiveash55.setValue(false))
    argument_map['thermal_comfort_model_type_adaptiveash55'] = thermal_comfort_model_type_adaptiveash55

    thermal_comfort_model_type_adaptivecen15251 = arguments[count += 1].clone
    assert(thermal_comfort_model_type_adaptivecen15251.setValue(false))
    argument_map['thermal_comfort_model_type_adaptivecen15251'] = thermal_comfort_model_type_adaptivecen15251

    thermal_comfort_model_type_coolingeffectash55 = arguments[count += 1].clone
    assert(thermal_comfort_model_type_coolingeffectash55.setValue(false))
    argument_map['thermal_comfort_model_type_coolingeffectash55'] = thermal_comfort_model_type_coolingeffectash55

    thermal_comfort_model_type_ankledraftash55 = arguments[count += 1].clone
    assert(thermal_comfort_model_type_ankledraftash55.setValue(false))
    argument_map['thermal_comfort_model_type_ankledraftash55'] = thermal_comfort_model_type_ankledraftash55

    work_efficiency_schedule_value = arguments[count += 1].clone
    assert(work_efficiency_schedule_value.setValue(0.0))
    argument_map['work_efficiency_schedule_value'] = work_efficiency_schedule_value

    clothing_insulation_schedule_value = arguments[count += 1].clone
    assert(clothing_insulation_schedule_value.setValue(0.6))
    argument_map['clothing_insulation_schedule_value'] = clothing_insulation_schedule_value

    air_velocity_schedule_value = arguments[count + 1].clone
    assert(air_velocity_schedule_value.setValue(0.1))
    argument_map['air_velocity_schedule_value'] = air_velocity_schedule_value

    # before
    people_definitions = model.getPeopleDefinitions
    assert(people_definitions.size == 1)
    people_definition = people_definitions[0]
    assert(people_definition.numThermalComfortModelTypes == 0)

    peoples = model.getPeoples
    assert(peoples.size == 1)
    people = peoples[0]
    assert(!people.workEfficiencySchedule.is_initialized)
    assert(!people.clothingInsulationSchedule.is_initialized)
    assert(!people.airVelocitySchedule.is_initialized)

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 0)

    # after
    people_definitions = model.getPeopleDefinitions
    assert(people_definitions.size == 1)
    people_definition = people_definitions[0]
    assert(people_definition.numThermalComfortModelTypes == 2)
    assert(people_definition.getThermalComfortModelType(0).is_initialized)
    assert(people_definition.getThermalComfortModelType(0).get == 'Fanger')
    assert(people_definition.getThermalComfortModelType(1).is_initialized)
    assert(people_definition.getThermalComfortModelType(1).get == 'Pierce')

    peoples = model.getPeoples
    assert(peoples.size == 1)
    people = peoples[0]
    assert(people.workEfficiencySchedule.is_initialized)
    assert(people.workEfficiencySchedule.get.to_ScheduleConstant.is_initialized)
    assert(people.workEfficiencySchedule.get.to_ScheduleConstant.get.value == 0.0)
    assert(people.clothingInsulationSchedule.is_initialized)
    assert(people.clothingInsulationSchedule.get.to_ScheduleConstant.is_initialized)
    assert(people.clothingInsulationSchedule.get.to_ScheduleConstant.get.value == 0.6)
    assert(people.airVelocitySchedule.is_initialized)
    assert(people.airVelocitySchedule.get.to_ScheduleConstant.is_initialized)
    assert(people.airVelocitySchedule.get.to_ScheduleConstant.get.value == 0.1)

    # save the model
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/test_AddThermalComfortModelTypes.osm')
    model.save(output_file_path, true)
  end
end
