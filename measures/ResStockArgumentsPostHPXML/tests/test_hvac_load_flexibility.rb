require 'csv'
require 'parallel'
require 'openstudio'
require_relative '../../../resources/buildstock'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../resources/hvac_flexibility/setpoint_modifier.rb'
require_relative '../measure.rb'
require 'pathname'


class ResStockArgumentsPostHPXMLTest < Minitest::Test
  def setup
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    parent_path = File.expand_path("../../../../", __FILE__)
    epw_path = File.join(parent_path, "resources/hpxml-measures/weather/USA_CO_Denver.Intl.AP.725650_TMY3.epw")
    weather = WeatherFile.new(epw_path: epw_path, runner: nil)
    @schedule_modifier_15 = HVACScheduleModifier.new(state:'CO',
                                                 sim_year:2024,
                                                 weather: weather,
                                                 epw_path: epw_path,
                                                 minutes_per_step:15,
                                                 runner:@runner)

    @schedule_modifier_60 = HVACScheduleModifier.new(state:'CO',
                                                 sim_year:2024,
                                                 weather: weather,
                                                 epw_path: epw_path,
                                                 minutes_per_step:60,
                                                 runner:@runner)
    @non_leap_modifier = HVACScheduleModifier.new(state:'CO',
                                                 sim_year:2023,
                                                 weather: weather,
                                                 epw_path: epw_path,
                                                 minutes_per_step:15,
                                                 runner:@runner)    
  end

  def test_get_peak_hour
    assert_equal([18, 22], @schedule_modifier_15._get_peak_hour(0, month: 6)) #shed summer
    assert_equal([18, 22], @schedule_modifier_15._get_peak_hour(0, month: 1)) #shed winter
    assert_equal([16, 20], @schedule_modifier_15._get_peak_hour(0, month: 5)) #shed intermediate
    assert_equal([16, 20], @schedule_modifier_15._get_peak_hour(4, month: 6)) #shift summer
    assert_equal([17, 21], @schedule_modifier_15._get_peak_hour(4, month: 1)) #shift winter
    assert_equal([16, 20], @schedule_modifier_15._get_peak_hour(4, month: 5)) #shift intermediate
  end

  def test_get_month
    assert_equal(2, @schedule_modifier_15._get_month(index: 31 * 24 * 4 + 28 * 24 * 4 + 1))  # First 15 minutes of Feb 29
    assert_equal(2, @schedule_modifier_60._get_month(index: 31 * 24 + 28 * 24 + 1))  # First 1 hour of Feb 29
    assert_equal(3, @non_leap_modifier._get_month(index: 31 * 24 *4 + 28 * 24 * 4 + 1))  # First 15 minutes of March 1

    assert_equal(12, @schedule_modifier_15._get_month(index: 366 * 24 * 4 - 1))
    assert_equal(12, @non_leap_modifier._get_month(index: 365 * 24 * 4 - 1))

    assert_equal(1, @schedule_modifier_15._get_month(index: 0))
    assert_equal(1, @non_leap_modifier._get_month(index: 0))
  end

  def test_modify_setpoints

    setpoints = {
        heating_setpoint: [71] * 365 * 24 * 4,
        cooling_setpoint: [78] * 365 * 24 * 4
      }
    flexibility_inputs = FlexibilityInputs.new(
        random_shift_steps: 0,
        pre_peak_duration_steps: 4 * 4,
        pre_peak_offset:  3,
        peak_offset: 4
    )

    modified_setpoints_15 = @schedule_modifier_15.modify_setpoints(setpoints, flexibility_inputs)

    winter_peak = 4 * @schedule_modifier_15._get_peak_hour(flexibility_inputs.pre_peak_duration_steps, month: 1)[0]
    summer_peak = 4 * @schedule_modifier_15._get_peak_hour(flexibility_inputs.pre_peak_duration_steps, month: 7)[0]

    summer_midnight = 3 * 31 * 24 * 4 + 29 * 24 * 4 + 3 * 30 * 24 * 4 # index from Jan to Jun

    assert_equal(71, modified_setpoints_15[:heating_setpoint][0])
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][0])
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][winter_peak])  # peak offset
    assert_equal(71 - 4 , modified_setpoints_15[:heating_setpoint][winter_peak])  # peak offset
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][winter_peak - 1])  # pre-peak offset
    assert_equal(71 + 3, modified_setpoints_15[:heating_setpoint][winter_peak - 1])  # pre-peak offset

    assert_equal(71, modified_setpoints_15[:heating_setpoint][summer_midnight])
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][summer_midnight])
    assert_equal(80, modified_setpoints_15[:cooling_setpoint][summer_midnight + summer_peak])  # peak offset
    assert_equal(71, modified_setpoints_15[:heating_setpoint][summer_midnight + summer_peak])  # peak offset
    assert_equal(78 - 3, modified_setpoints_15[:cooling_setpoint][summer_midnight + summer_peak - 1])  # pre-peak offset
    assert_equal(71, modified_setpoints_15[:heating_setpoint][summer_midnight + summer_peak - 1])  # pre-peak offset

    flexibility_inputs = FlexibilityInputs.new(
        random_shift_steps: 2,
        pre_peak_duration_steps: 4 * 4,
        pre_peak_offset: 3,
        peak_offset: 4
    )
    modified_setpoints_15 = @schedule_modifier_15.modify_setpoints(setpoints, flexibility_inputs)
    assert_equal(71, modified_setpoints_15[:heating_setpoint][0])
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][0])
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][winter_peak + 2])  # peak offset
    assert_equal(71 - 4, modified_setpoints_15[:heating_setpoint][winter_peak + 2])  # peak offset
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][winter_peak + 2 - 4 * 4])  # start of pre-peak offset
    assert_equal(71 + 3, modified_setpoints_15[:heating_setpoint][winter_peak + 2 - 1])  # end of pre-peak offset

    assert_equal(71, modified_setpoints_15[:heating_setpoint][summer_midnight])
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][summer_midnight])
    assert_equal(80, modified_setpoints_15[:cooling_setpoint][summer_midnight + summer_peak + 2])   # start of peak period
    assert_equal(71, modified_setpoints_15[:heating_setpoint][summer_midnight + summer_peak + 2 + 2 * 4 - 1])  # end of peak period
    assert_equal(78 - 0, modified_setpoints_15[:cooling_setpoint][summer_midnight + summer_peak + 2 - 4 * 4 - 1])  # before pre-peak period
    assert_equal(71, modified_setpoints_15[:heating_setpoint][summer_midnight + summer_peak + 2 + 2 * 4])  # after peak period

    flexibility_inputs = FlexibilityInputs.new(
        random_shift_steps: -2,
        pre_peak_duration_steps: 0,
        pre_peak_offset: 3,  # unused since pre_peak_duration_steps is 0
        peak_offset: 2
    )

    winter_peak = 4 * @schedule_modifier_15._get_peak_hour(flexibility_inputs.pre_peak_duration_steps, month: 1)[0]
    summer_peak = 4 * @schedule_modifier_15._get_peak_hour(flexibility_inputs.pre_peak_duration_steps, month: 7)[0]

    modified_setpoints_15 = @schedule_modifier_15.modify_setpoints(setpoints, flexibility_inputs)
    assert_equal(71, modified_setpoints_15[:heating_setpoint][0])
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][0])
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][winter_peak - 2])  # peak offset
    assert_equal(71 - 2, modified_setpoints_15[:heating_setpoint][winter_peak - 2])  # peak offset
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][winter_peak - 2 - 1])  # end of pre-peak period
    assert_equal(71 + 0, modified_setpoints_15[:heating_setpoint][winter_peak - 2 - 1])  # end of pre-peak period

    assert_equal(71, modified_setpoints_15[:heating_setpoint][summer_midnight])
    assert_equal(78, modified_setpoints_15[:cooling_setpoint][summer_midnight])
    assert_equal(78 + 2, modified_setpoints_15[:cooling_setpoint][summer_midnight + summer_peak - 2])  # peak offset
    assert_equal(71, modified_setpoints_15[:heating_setpoint][summer_midnight + summer_peak - 2])  # peak offset
    assert_equal(78 - 0, modified_setpoints_15[:cooling_setpoint][summer_midnight + summer_peak - 2 - 1])  # before peak period
    assert_equal(71, modified_setpoints_15[:heating_setpoint][summer_midnight + summer_peak - 2 - 1])  # before peak period
  end

  def test_clip_setpoints
    assert_equal(80, @schedule_modifier_15._clip_setpoints('heating', 88))
    assert_equal(55, @schedule_modifier_15._clip_setpoints('heating', 45))
    assert_equal(65, @schedule_modifier_15._clip_setpoints('heating', 65))
    assert_equal(80, @schedule_modifier_15._clip_setpoints('cooling', 88))
    assert_equal(60, @schedule_modifier_15._clip_setpoints('cooling', 45))
    assert_equal(65, @schedule_modifier_15._clip_setpoints('heating', 65))
  end

  def test_get_peak_times
    flexibility_inputs = FlexibilityInputs.new(
        random_shift_steps: 0,
        pre_peak_duration_steps: 4 * 4,
        pre_peak_offset:  3,
        peak_offset: 4
    )

    peak_times = @schedule_modifier_15._get_peak_times(1, flexibility_inputs) # peak time in Jan
    assert_equal(17 * 4, peak_times.peak_start_index)
    assert_equal(21 * 4, peak_times.peak_end_index)
    assert_equal(13 * 4, peak_times.pre_peak_start_index)

    peak_times = @schedule_modifier_15._get_peak_times((30 * 4 + 15 ) * 24 *4, flexibility_inputs) # peak time in May
    assert_equal(16 * 4, peak_times.peak_start_index)
    assert_equal(20 * 4, peak_times.peak_end_index)
    assert_equal(12 * 4, peak_times.pre_peak_start_index)

  end

end
