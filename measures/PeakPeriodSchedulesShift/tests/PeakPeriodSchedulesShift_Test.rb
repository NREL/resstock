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
    assert_equal(4, arguments.size)

    count = -1

    assert_equal('schedules_peak_period', arguments[count += 1].name)
    assert_equal('schedules_peak_period_delay', arguments[count += 1].name)
    assert_equal('schedules_peak_period_schedule_rulesets_names', arguments[count += 1].name)
    assert_equal('schedules_peak_period_schedule_files_column_names', arguments[count + 1].name)

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

    schedules_peak_period_schedule_rulesets_names = arguments[count += 1].clone
    assert(schedules_peak_period_schedule_rulesets_names.setValue('fridge'))
    argument_map['schedules_peak_period_schedule_rulesets_names'] = schedules_peak_period_schedule_rulesets_names

    schedules_peak_period_schedule_files_column_names = arguments[count + 1].clone
    assert(schedules_peak_period_schedule_files_column_names.setValue('dishwasher, clothes_washer, clothes_dryer, cooking_range'))
    argument_map['schedules_peak_period_schedule_files_column_names'] = schedules_peak_period_schedule_files_column_names

    # before
    schedule_rulesets = {}
    model.getScheduleRulesets.each do |schedule_ruleset|
      schedule_rulesets[schedule_ruleset.name.to_s] = schedule_ruleset
    end
    assert(!schedule_rulesets.empty?)
    assert(schedule_rulesets['fridge'].scheduleRules.size == 7)
    shiftable_rule = schedule_rulesets['fridge'].scheduleRules.select { |schedule_rule| schedule_rule.name.to_s == 'fridge allday ruleset1' }[0]
    values_before = shiftable_rule.daySchedule.values.uniq
    assert(values_before.size == 11)

    schedule_files_before = {}
    model.getExternalFiles.each do |external_file|
      external_file_path = external_file.filePath.to_s

      schedules = Schedules.new(file_path: external_file_path)
      schedule_files_before = schedules.schedules
    end

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 5)

    # after
    model.getScheduleRulesets.each do |schedule_ruleset|
      schedule_rulesets[schedule_ruleset.name.to_s] = schedule_ruleset
    end
    assert(!schedule_rulesets.empty?)
    assert(schedule_rulesets['fridge'].scheduleRules.size == 8)
    shifted_rule = schedule_rulesets['fridge'].scheduleRules.select { |schedule_rule| schedule_rule.name.to_s == 'fridge allday ruleset1 Shifted' }[0]
    assert(shifted_rule.applyWeekdays)
    assert(!shifted_rule.applyWeekends)
    values_after = shifted_rule.daySchedule.values.uniq
    assert(values_after.size == 11)
    assert(values_before != values_after)
    assert(values_before.sum == values_after.sum)

    schedule_files_after = {}
    model.getExternalFiles.each do |external_file|
      external_file_path = external_file.filePath.to_s

      schedules = Schedules.new(file_path: external_file_path)
      schedule_files_after = schedules.schedules
    end

    # check schedule files
    assert(!schedule_files_before.empty?)
    assert(!schedule_files_after.empty?)

    assert(schedule_files_before['ceiling_fan'] == schedule_files_after['ceiling_fan'])
    assert(schedule_files_before['hot_water_clothes_washer'] == schedule_files_after['hot_water_clothes_washer'])
    assert(schedule_files_before['hot_water_dishwasher'] == schedule_files_after['hot_water_dishwasher'])
    assert(schedule_files_before['hot_water_fixtures'] == schedule_files_after['hot_water_fixtures'])
    assert(schedule_files_before['lighting_garage'] == schedule_files_after['lighting_garage'])
    assert(schedule_files_before['lighting_interior'] == schedule_files_after['lighting_interior'])
    assert(schedule_files_before['occupants'] == schedule_files_after['occupants'])
    assert(schedule_files_before['plug_loads_other'] == schedule_files_after['plug_loads_other'])
    assert(schedule_files_before['plug_loads_tv'] == schedule_files_after['plug_loads_tv'])

    assert(schedule_files_before['clothes_dryer'] != schedule_files_after['clothes_dryer'])
    assert(schedule_files_before['clothes_washer'] != schedule_files_after['clothes_washer'])
    assert(schedule_files_before['cooking_range'] != schedule_files_after['cooking_range'])
    assert(schedule_files_before['dishwasher'] != schedule_files_after['dishwasher'])

    assert(schedule_files_before['clothes_dryer'].sum == schedule_files_after['clothes_dryer'].sum)
    assert(schedule_files_before['clothes_washer'].sum == schedule_files_after['clothes_washer'].sum)
    assert(schedule_files_before['cooking_range'].sum == schedule_files_after['cooking_range'].sum)
    assert(schedule_files_before['dishwasher'].sum == schedule_files_after['dishwasher'].sum)

    # save the model
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/test_PeakPeriodSchedulesShift.osm')
    model.save(output_file_path, true)
  end
end
