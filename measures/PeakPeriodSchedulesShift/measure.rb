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
    return 'Shifts select weekday schedules out of a peak period.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Enter a weekday peak period window, a delay value, and any applicable ScheduleRuleset or ScheduleFile schedules. Shift all schedule values falling within the peak period to after the end (offset by delay) of the peak period. Optionally prevent stacking of schedule values by only allowing shifts to all-zero periods.'
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

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('schedules_peak_period_allow_stacking', false)
    arg.setDisplayName('Schedules: Peak Period Allow Stacking')
    arg.setDescription('Whether schedules can be shifted to periods that already have non-zero schedule values. Defaults to true. Note that stacking runs the risk of creating out-of-range schedule values.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_peak_period_schedule_rulesets_names', false)
    arg.setDisplayName('Schedules: Peak Period Schedule Rulesets Names')
    arg.setDescription('Comma-separated list of Schedule:Ruleset object names corresponding to schedules to shift during the specified peak period.')
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeStringArgument('schedules_peak_period_schedule_files_column_names', false)
    arg.setDisplayName('Schedules: Peak Period Schedule Files Column Names')
    arg.setDescription('Comma-separated list of column names, referenced by Schedule:File objects, corresponding to schedules to shift during the specified peak period.')
    args << arg

    return args
  end

  def get_schedule_ruleset_names(model)
    schedule_ruleset_names = []
    model.getScheduleRulesets.each do |schedule_ruleset|
      schedule_ruleset_names << schedule_ruleset.name.to_s
    end
    return schedule_ruleset_names.uniq.sort
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
    schedules_peak_period_allow_stacking = runner.getOptionalBoolArgumentValue('schedules_peak_period_allow_stacking', user_arguments)
    schedules_peak_period_allow_stacking = schedules_peak_period_allow_stacking.is_initialized ? schedules_peak_period_allow_stacking.get : true
    schedules_peak_period_schedule_rulesets_names = runner.getOptionalStringArgumentValue('schedules_peak_period_schedule_rulesets_names', user_arguments)
    schedules_peak_period_schedule_rulesets_names = schedules_peak_period_schedule_rulesets_names.is_initialized ? schedules_peak_period_schedule_rulesets_names.get.split(',').map(&:strip) : []
    schedules_peak_period_schedule_files_column_names = runner.getOptionalStringArgumentValue('schedules_peak_period_schedule_files_column_names', user_arguments)
    schedules_peak_period_schedule_files_column_names = schedules_peak_period_schedule_files_column_names.is_initialized ? schedules_peak_period_schedule_files_column_names.get.split(',').map(&:strip) : []

    schedule_ruleset_names_enabled = {}
    get_schedule_ruleset_names(model).each do |schedule_ruleset_name|
      schedule_ruleset_names_enabled[schedule_ruleset_name] = schedules_peak_period_schedule_rulesets_names.include?(schedule_ruleset_name)
    end

    schedule_file_column_names_enabled = {}
    get_schedule_file_column_names(model).each do |schedule_file_column_name|
      schedule_file_column_names_enabled[schedule_file_column_name] = schedules_peak_period_schedule_files_column_names.include?(schedule_file_column_name)
    end

    if (schedule_ruleset_names_enabled.empty? || schedule_ruleset_names_enabled.values.all? { |value| value == false }) &&
       (schedule_file_column_names_enabled.empty? || schedule_file_column_names_enabled.values.all? { |value| value == false })
      runner.registerAsNotApplicable('Did not select any ScheduleRuleset or ScheduleFile objects to shift.')
      return true
    end

    begin_hour, end_hour = Schedules.parse_time_range(schedules_peak_period)

    if begin_hour >= end_hour
      runner.registerError("Specified peak period (#{begin_hour} - #{end_hour}) must be at least one hour long.")
      return false
    end

    peak_period_length = end_hour - begin_hour
    if (peak_period_length + schedules_peak_period_delay > 12)
      runner.registerError("Specified peak period (#{begin_hour} - #{end_hour}), plus the delay (#{schedules_peak_period_delay}), must be no longer than 12 hours.")
      return false
    end

    if (peak_period_length + end_hour + schedules_peak_period_delay > 24)
      runner.registerError('Cannot shift day schedules into the next day.')
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

    # Schedule:Ruleset
    shift_summary = {}
    schedule_rulesets = model.getScheduleRulesets
    schedule_ruleset_names_enabled.each do |schedule_ruleset_name, peak_period_shift_enabled|
      next if !peak_period_shift_enabled

      shift_summary[schedule_ruleset_name] = 0

      schedule_ruleset = schedule_rulesets.find { |schedule_ruleset| schedule_ruleset.name.to_s == schedule_ruleset_name }
      schedule_ruleset.scheduleRules.reverse.each do |schedule_rule|
        next unless schedule_rule.applyMonday || schedule_rule.applyTuesday || schedule_rule.applyWednesday || schedule_rule.applyThursday || schedule_rule.applyFriday

        new_schedule_rule = schedule_rule.clone.to_ScheduleRule.get
        new_schedule_rule.setName("#{schedule_rule.name} Shifted")
        new_schedule_rule.setApplySunday(false)
        new_schedule_rule.setApplyMonday(schedule_rule.applyMonday)
        new_schedule_rule.setApplyTuesday(schedule_rule.applyTuesday)
        new_schedule_rule.setApplyWednesday(schedule_rule.applyWednesday)
        new_schedule_rule.setApplyThursday(schedule_rule.applyThursday)
        new_schedule_rule.setApplyFriday(schedule_rule.applyFriday)
        new_schedule_rule.setApplySaturday(false)
        schedule_ruleset.setScheduleRuleIndex(new_schedule_rule, 0)

        old_day_schedule = schedule_rule.daySchedule
        new_day_schedule = new_schedule_rule.daySchedule
        new_day_schedule.setName("#{old_day_schedule.name} Shifted")

        schedule = get_hourly_values(old_day_schedule)
        shifted = Schedules.day_peak_shift(schedule, 0, begin_hour, end_hour, schedules_peak_period_delay, schedules_peak_period_allow_stacking, 24)

        if shifted
          shift_day_schedule(calendar_year, shift_summary, schedule_ruleset_name, new_schedule_rule, new_day_schedule, schedule)
        else
          new_schedule_rule.remove
        end
      end

      old_default_day_schedule = schedule_ruleset.defaultDaySchedule
      new_default_schedule_rule = OpenStudio::Model::ScheduleRule.new(schedule_ruleset)
      new_default_schedule_rule.setName("#{old_default_day_schedule.name} Shifted")
      new_default_schedule_rule.setApplySunday(false)
      new_default_schedule_rule.setApplyMonday(true)
      new_default_schedule_rule.setApplyTuesday(true)
      new_default_schedule_rule.setApplyWednesday(true)
      new_default_schedule_rule.setApplyThursday(true)
      new_default_schedule_rule.setApplyFriday(true)
      new_default_schedule_rule.setApplySaturday(false)
      schedule_ruleset.setScheduleRuleIndex(new_default_schedule_rule, 0)

      new_default_day_schedule = new_default_schedule_rule.daySchedule
      new_default_day_schedule.setName("#{old_default_day_schedule.name} Shifted")

      schedule = get_hourly_values(old_default_day_schedule)
      shifted = Schedules.day_peak_shift(schedule, 0, begin_hour, end_hour, schedules_peak_period_delay, schedules_peak_period_allow_stacking, 24)

      if shifted
        shift_day_schedule(calendar_year, shift_summary, schedule_ruleset_name, new_default_schedule_rule, new_default_day_schedule, schedule)
      else
        new_default_schedule_rule.remove
      end
    end

    shift_summary.each do |schedule_ruleset_name, shifted_days|
      runner.registerInfo("Out of #{total_days_in_year} total days, #{shifted_days} weekday(s) were shifted for the '#{schedule_ruleset_name}' Schedule:Ruleset.")
      runner.registerValue("shifted_days_#{schedule_ruleset_name}", shifted_days)
    end

    # Schedule:File
    model.getExternalFiles.each do |external_file|
      external_file_path = external_file.filePath.to_s

      schedules = Schedules.new(file_path: external_file_path)
      schedules.shift_schedules(runner, schedule_file_column_names_enabled, begin_hour, end_hour, schedules_peak_period_delay, schedules_peak_period_allow_stacking, total_days_in_year, sim_start_day, steps_in_day)
      schedules.export()
    end

    return true
  end

  def shift_day_schedule(calendar_year, shift_summary, schedule_ruleset_name, schedule_rule, day_schedule, schedule)
    start_date = schedule_rule.startDate.get
    start_date_month = start_date.monthOfYear.value
    start_date_day = start_date.dayOfMonth
    end_date = schedule_rule.endDate.get
    end_date_month = end_date.monthOfYear.value
    end_date_day = end_date.dayOfMonth

    start_date = DateTime.new(calendar_year, start_date_month, start_date_day)
    end_date = DateTime.new(calendar_year, end_date_month, end_date_day)
    n_days = (end_date - start_date).to_i + 1
    shifted_days = 0
    n_days.times do |day|
      today = start_date + day
      day_of_week = today.wday
      shifted_days += 1 if day_of_week == 1 && schedule_rule.applyMonday
      shifted_days += 1 if day_of_week == 2 && schedule_rule.applyTuesday
      shifted_days += 1 if day_of_week == 3 && schedule_rule.applyWednesday
      shifted_days += 1 if day_of_week == 4 && schedule_rule.applyThursday
      shifted_days += 1 if day_of_week == 5 && schedule_rule.applyFriday
    end

    shift_summary[schedule_ruleset_name] += shifted_days
    for h in 0..23
      time = OpenStudio::Time.new(0, h + 1, 0, 0)
      day_schedule.addValue(time, schedule[h])
    end
  end

  def get_hourly_values(day_schedule)
    times = day_schedule.times
    values = day_schedule.values

    hourly_values = []
    t0 = 0
    times.each_with_index do |_time, i|
      t1 = times[i].hours
      t1 = 24 if t1 == 0
      hours = t1 - t0
      for _v in 0...hours
        hourly_values << values[i]
      end
      t0 = t1
    end
    return hourly_values
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

  def shift_schedules(runner, schedule_file_column_names_enabled, begin_hour, end_hour, delay, allow_stacking, total_days_in_year, sim_start_day, steps_in_day)
    shift_summary = {}
    schedule_file_column_names_enabled.each do |schedule_file_column_name, peak_period_shift_enabled|
      next if !@schedules.keys.include?(schedule_file_column_name)
      next if !peak_period_shift_enabled

      schedule = @schedules[schedule_file_column_name]
      shift_summary[schedule_file_column_name] = 0
      next if schedule.nil?

      total_days_in_year.times do |day|
        today = sim_start_day + day
        day_of_week = today.wday
        next if [0, 6].include?(day_of_week)

        shifted = Schedules.day_peak_shift(schedule, day, begin_hour, end_hour, delay, allow_stacking, steps_in_day)
        shift_summary[schedule_file_column_name] += 1 if shifted
      end
    end

    shift_summary.each do |schedule_file_column_name, shifted_days|
      runner.registerInfo("Out of #{total_days_in_year} total days, #{shifted_days} weekday(s) were shifted for the '#{schedule_file_column_name}' Schedule:File.")
      runner.registerValue("shifted_days_#{schedule_file_column_name}", shifted_days)
    end
  end

  def self.day_peak_shift(schedule, day, begin_hour, end_hour, delay, allow_stacking, steps_in_day)
    steps_in_hour = steps_in_day / 24
    period = (end_hour - begin_hour) * steps_in_hour # n steps

    # peak period
    peak_begin_ix = day * steps_in_day + (begin_hour * steps_in_hour)
    peak_end_ix = peak_begin_ix + period

    # new period
    new_begin_ix = peak_end_ix + (delay * steps_in_hour)
    new_end_ix = new_begin_ix + period

    shifted = false
    if !allow_stacking
      return shifted if schedule[new_begin_ix...new_end_ix].any? { |x| x > 0 } # prevent stacking
    end

    shifted = true if schedule[peak_begin_ix...peak_end_ix].any? { |x| x > 0 } # schedule was actually moved
    schedule[new_begin_ix...new_end_ix] = [schedule[new_begin_ix...new_end_ix], schedule[peak_begin_ix...peak_end_ix]].transpose.map(&:sum)
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
