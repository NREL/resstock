# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'csv'

# start the measure
class PeakPeriodSchedulesShift < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'PeakPeriodSchedulesShift'
  end

  # human readable description
  def description
    return 'TODO'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'TODO'
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_peak_period', true)
    arg.setDisplayName('Schedules: Peak Period')
    arg.setDescription('Specifies the peak period. Enter a time like "15 - 18" (start hour can be 0 through 23 and end hour can be 1 through 24).')
    arg.setDefaultValue('15 - 18')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('schedules_peak_period_delay', true)
    arg.setDisplayName('Schedules: Peak Period Delay')
    arg.setUnits('hr')
    arg.setDescription('The number of hours after peak period end.')
    arg.setDefaultValue(0)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_peak_period_column_names', false)
    arg.setDisplayName('Schedules: Peak Period Schedule File Column Names')
    arg.setDescription('Comma-separated list of schedule file column names to shift during the peak period.')
    args << arg

    return args
  end

  def get_schedule_file_column_names(model)
    schedule_file_column_names = []
    model.getExternalFiles.each do |external_file|
      external_file_path = external_file.filePath.to_s
      schedule_file_column_names += CSV.foreach(external_file_path).first
    end
    return schedule_file_column_names.uniq.sort
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments) # Do **NOT** remove this line

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    schedules_peak_period = runner.getStringArgumentValue('schedules_peak_period', user_arguments)
    schedules_peak_period_delay = runner.getIntegerArgumentValue('schedules_peak_period_delay', user_arguments)
    schedules_peak_period_column_names = runner.getStringArgumentValue('schedules_peak_period_column_names', user_arguments).split(',').map(&:strip)

    schedule_file_column_names_enabled = {}
    get_schedule_file_column_names(model).each do |schedule_file_column_name|
      schedule_file_column_names_enabled[schedule_file_column_name] = schedules_peak_period_column_names.include?(schedule_file_column_name)
    end

    if schedule_file_column_names_enabled.empty? || schedule_file_column_names_enabled.values.all? { |value| value == false }
      runner.registerAsNotApplicable('Did not select any ScheduleFile objects to shift.')
      return true
    end

    begin_hour, end_hour = Schedules.parse_time_range(schedules_peak_period)

    if begin_hour >= end_hour
      runner.registerError("Specified peak period (#{begin_hour} - #{end_hour}) must be at least one hour long.")
      return false
    end

    if ((end_hour - begin_hour) + schedules_peak_period_delay > 12)
      runner.registerError("Specified peak period (#{begin_hour} - #{end_hour}), plus the delay (#{schedules_peak_period_delay}), must be no longer than 12 hours.")
      return false
    end

    # get year
    yd = model.getYearDescription
    calendar_year = yd.assumedYear
    calendar_year = yd.calendarYear.get if yd.calendarYear.is_initialized
    total_days_in_year = Schedules.NumDaysInYear(calendar_year)
    sim_start_day = DateTime.new(calendar_year, 1, 1)

    # get steps
    ts = model.getTimestep
    ts_per_hour = ts.numberOfTimestepsPerHour
    steps_in_day = ts_per_hour * 24

    model.getExternalFiles.each do |external_file|
      external_file_path = external_file.filePath.to_s

      schedules = Schedules.new(file_path: external_file_path)
      schedules.shift_schedules(runner, schedule_file_column_names_enabled, begin_hour, end_hour, schedules_peak_period_delay, total_days_in_year, sim_start_day, steps_in_day)
      schedules.export()
    end

    return true
  end
end

class Schedules
  def initialize(file_path:)
    @file_path = file_path

    import()
  end

  def import()
    @schedules = {}
    columns = CSV.read(@file_path).transpose
    columns.each do |col|
      col_name = col[0]

      values = col[1..-1].reject { |v| v.nil? }

      begin
        values = values.map { |v| Float(v) }
      rescue ArgumentError
        fail "Schedule value must be numeric for column '#{col_name}'. [context: #{schedules_path}]"
      end

      @schedules[col_name] = values
    end
  end

  def shift_schedules(runner, schedule_file_column_names_enabled, begin_hour, end_hour, delay, total_days_in_year, sim_start_day, steps_in_day)
    shift_summary = {}
    schedule_file_column_names_enabled.each do |schedule_file_column_name, peak_period_shift_enabled|
      next if !@schedules.keys.include?(schedule_file_column_name)
      next if !peak_period_shift_enabled

      schedule = @schedules[schedule_file_column_name]
      shift_summary[schedule_file_column_name] = 0

      total_days_in_year.times do |day|
        today = sim_start_day + day
        day_of_week = today.wday
        next if [0, 6].include?(day_of_week)

        shifted = day_peak_shift(schedule, day, begin_hour, end_hour, delay, steps_in_day)
        shift_summary[schedule_file_column_name] += 1 if shifted
      end
    end

    shift_summary.each do |schedule_file_column_name, shifted_days|
      runner.registerInfo("Out of #{total_days_in_year} total days, #{shifted_days} day(s) were shifted for the '#{schedule_file_column_name}' schedule.")
    end
  end

  def day_peak_shift(schedule, day, begin_hour, end_hour, delay, steps_in_day)
    steps_in_hour = steps_in_day / 24
    period = (end_hour - begin_hour) * steps_in_hour # n steps

    # peak period
    peak_begin_ix = day * steps_in_day + (begin_hour * steps_in_hour)
    peak_end_ix = peak_begin_ix + period

    # new period
    new_begin_ix = peak_end_ix + (delay * steps_in_hour)
    new_end_ix = new_begin_ix + period

    shifted = false
    return shifted if schedule[new_begin_ix...new_end_ix].any? { |x| x > 0 } # prevent stacking

    shifted = true if schedule[peak_begin_ix...peak_end_ix].any? { |x| x > 0 } # schedule was actually moved
    schedule[new_begin_ix...new_end_ix] = schedule[peak_begin_ix...peak_end_ix]
    schedule[peak_begin_ix...peak_end_ix] = [0] * period

    return shifted
  end

  def export()
    CSV.open(@file_path, 'wb') do |csv|
      csv << @schedules.keys
      rows = @schedules.values.transpose
      rows.each do |row|
        csv << row
      end
    end
  end

  def schedules
    return @schedules
  end

  def self.parse_time_range(time_range)
    begin_end_times = time_range.split('-').map { |v| v.strip }
    if begin_end_times.size != 2
      fail "Invalid time format specified for '#{time_range}'."
    end

    begin_hour = begin_end_times[0].strip.to_i
    end_hour = begin_end_times[1].strip.to_i

    return begin_hour, end_hour
  end

  def self.NumDaysInYear(year)
    num_days_in_months = NumDaysInMonths(year)
    num_days_in_year = num_days_in_months.sum
    return num_days_in_year
  end

  def self.NumDaysInMonths(year)
    num_days_in_months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    num_days_in_months[1] += 1 if Date.leap?(year)
    return num_days_in_months
  end
end

# register the measure to be used by the application
PeakPeriodSchedulesShift.new.registerWithApplication
