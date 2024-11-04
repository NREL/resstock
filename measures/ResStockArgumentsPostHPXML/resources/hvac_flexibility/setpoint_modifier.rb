require 'date'
require 'csv'
require 'json'
require 'openstudio'
require_relative 'hvac_flexibility_constants'
require 'byebug'

Dir["#{File.dirname(__FILE__)}/../../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'
  require resource_file
end

FlexibilityInputs = Struct.new(:peak_duration_steps, :peak_offset, :pre_peak_duration_steps, :pre_peak_offset, :random_shift_steps, keyword_init: true)
DailyPeakIndices = Struct.new(:pre_peak_start_index, :peak_start_index, :peak_end_index)


class HVACScheduleModifier
  def initialize(state:, sim_year:, minutes_per_step:, runner:)
    @state = state
    @minutes_per_step = minutes_per_step
    @runner = runner
    @sim_year = Location.get_sim_calendar_year(sim_year, @weather)
    @total_days_in_year = Calendar.num_days_in_year(@sim_year)
    @sim_start_day = DateTime.new(@sim_year, 1, 1)
    @steps_in_day = 24 * 60 / @minutes_per_step
    @num_timesteps_per_hour = 60 / @minutes_per_step
    current_dir = File.dirname(__FILE__)
    @summer_peak_hours_dict = JSON.parse(File.read("#{current_dir}/state_summer_peak_hour_dict.json"))
    @winter_peak_hours_dict = JSON.parse(File.read("#{current_dir}/state_winter_peak_hour_dict.json"))
  end

  def modify_setpoints(setpoints, flexibility_inputs)
    log_inputs(flexibility_inputs)
    heating_setpoints = setpoints[:heating_setpoints].dup
    cooling_setpoints = setpoints[:cooling_setpoints].dup
    byebug
    raise "heating_setpoints.length != cooling_setpoints.length" unless heating_setpoints.length == cooling_setpoints.length

    total_indices = heating_setpoints.length
    total_indices.times do |index|
      offset_times = _get_peak_times(index, flexibility_inputs)
      heating_setpoints[index] += _get_setpoint_offset(index, 'heating', offset_times, flexibility_inputs)
      cooling_setpoints[index] += _get_setpoint_offset(index, 'cooling', offset_times, flexibility_inputs)
    end
    { heating_setpoints: heating_setpoints, cooling_setpoints: cooling_setpoints }
  end

  def _get_peak_times(index, flexibility_inputs)
    month = _get_month(index:)
    peak_hour = _get_peak_hour(month:)
    peak_index = peak_hour * @num_timesteps_per_hour
    peak_times = DailyPeakIndices.new
    peak_times.peak_start_index = peak_index + flexibility_inputs.random_shift_steps
    peak_times.peak_end_index = peak_times.peak_start_index + flexibility_inputs.peak_duration_steps
    peak_times.pre_peak_start_index = peak_times.peak_start_index - flexibility_inputs.pre_peak_duration_steps
    peak_times
  end

  def _get_setpoint_offset(index, setpoint_type, offset_times, flexibility_inputs)
    case setpoint_type
    when 'heating'
      pre_peak_offset = flexibility_inputs.pre_peak_offset
      peak_offset = -flexibility_inputs.peak_offset
    when 'cooling'
      pre_peak_offset = -flexibility_inputs.pre_peak_offset
      peak_offset = flexibility_inputs.peak_offset
    else
      raise "Unsupported setpoint type: #{setpoint_type}"
    end

    index_in_day = index % (24 * @num_timesteps_per_hour)
    if offset_times.pre_peak_start_index <= index_in_day && index_in_day < offset_times.peak_start_index
      pre_peak_offset
    elsif offset_times.peak_start_index <= index_in_day && index_in_day < offset_times.peak_end_index
      peak_offset
    else
      0
    end
  end

  def _get_month(index:)
    start_of_year = Date.new(@sim_year, 1, 1)
    index_date = start_of_year + (index.to_f / @num_timesteps_per_hour / 24)
    index_date.month
  end

  def _get_peak_hour(month:)
    if [6, 7, 8, 9].include?(month)
      return @summer_peak_hours_dict[@state]
    else
      return @winter_peak_hours_dict[@state]
    end
  end

  def log_inputs(inputs)
    return unless @runner
    @runner.registerInfo("Modifying setpoints ...")
    @runner.registerInfo("peak_duration_steps=#{inputs.peak_duration_steps}")
    @runner.registerInfo("pre_peak_duration_steps=#{inputs.pre_peak_duration_steps}")
    @runner.registerInfo("random_shift_steps=#{inputs.random_shift_steps}")
    @runner.registerInfo("pre_peak_offset=#{inputs.pre_peak_offset}")
    @runner.registerInfo("peak_offset=#{inputs.peak_offset}")
  end
end
