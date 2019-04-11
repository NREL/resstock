# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

if File.exists? File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/measures/HPXMLtoOpenStudio/resources")) # Hack to run ResStock on AWS
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../../lib/resources/measures/HPXMLtoOpenStudio/resources"))
elsif File.exists? File.absolute_path(File.join(File.dirname(__FILE__), "../../resources/measures/HPXMLtoOpenStudio/resources")) # Hack to run ResStock unit tests locally
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../../resources/measures/HPXMLtoOpenStudio/resources"))
elsif File.exists? File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources") # Hack to run measures in the OS App since applied measures are copied off into a temporary directory
  resources_path = File.join(OpenStudio::BCLMeasure::userMeasuresDir.to_s, "HPXMLtoOpenStudio/resources")
else
  resources_path = File.absolute_path(File.join(File.dirname(__FILE__), "../HPXMLtoOpenStudio/resources"))
end
require File.join(resources_path, "weather")
require File.join(resources_path, "constants")
require File.join(resources_path, "geometry")

# start the measure
class ProcessPowerOutage < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Outages"
  end

  def description
    return "This measures allows building power outages to be modeled. The user specifies the start time of the outage and the duration of the outage. During an outage, all energy consumption is set to 0, although occupants are still simulated in the home."
  end

  def modeler_description
    return "This measure zeroes out the schedule for anything that consumes energy for the duration of the power outage."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a string argument for for the start date of the outage
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("otg_date", true)
    arg.setDisplayName("Outage Start Date")
    arg.setDescription("Date of the start of the outage.")
    arg.setDefaultValue("April 1")
    args << arg

    # make a double argument for hour of outage start
    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("otg_hr", true)
    arg.setDisplayName("Outage Start Hour")
    arg.setUnits("hours")
    arg.setDescription("Hour of the day when the outage starts.")
    arg.setDefaultValue(0)
    args << arg

    # make a double argument for outage duration
    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("otg_len", true)
    arg.setDisplayName("Outage Duration")
    arg.setUnits("hours")
    arg.setDescription("Duration of the power outage in hours.")
    arg.setDefaultValue(24)
    args << arg

    return args
  end # end the arguments method

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    otg_date = runner.getStringArgumentValue("otg_date", user_arguments)
    otg_hr = runner.getIntegerArgumentValue("otg_hr", user_arguments)
    otg_len = runner.getIntegerArgumentValue("otg_len", user_arguments)

    # Check for valid inputs
    if otg_hr < 0 or otg_hr > 23
      runner.registerError("Start hour must be between 0 and 23")
      return false
    end

    if otg_len == 0
      runner.registerError("Outage must last for at least one hour")
      return false
    end

    if otg_len > 8760
      runner.registerError("Outage can't run for longer than one year")
      return false
    end

    begin
      otg_start_date_month = OpenStudio::monthOfYear(otg_date.split[0])
      otg_start_date_day = otg_date.split[1].to_i
    rescue
      runner.registerError("Invalid start date specified.")
      return false
    end

    # get the RunPeriod
    months = [OpenStudio::monthOfYear("January"), OpenStudio::monthOfYear("February"), OpenStudio::monthOfYear("March"), OpenStudio::monthOfYear("April"), OpenStudio::monthOfYear("May"), OpenStudio::monthOfYear("June"), OpenStudio::monthOfYear("July"), OpenStudio::monthOfYear("August"), OpenStudio::monthOfYear("September"), OpenStudio::monthOfYear("October"), OpenStudio::monthOfYear("November"), OpenStudio::monthOfYear("December")]
    year_description = model.getYearDescription
    leap_offset = 0
    if year_description.isLeapYear
      leap_offset = 1
    end

    startday_m = [0, 31, 59 + leap_offset, 90 + leap_offset, 120 + leap_offset, 151 + leap_offset, 181 + leap_offset, 212 + leap_offset, 243 + leap_offset, 273 + leap_offset, 304 + leap_offset, 334 + leap_offset, 365 + leap_offset]

    # calculate how many days the outage goes on for, the hour it starts on the first day and the hour it ends on the last day
    otg_num_days = 0
    otg_netxday_check = otg_hr + otg_len
    if otg_netxday_check > 24
      otg_num_days = otg_num_days + 1
    end

    otg_num_days += (otg_len.to_i - 1) / 24
    otg_end_hr = (otg_hr + otg_len) % 24

    m_idx = 0
    for m in months
      if m == otg_start_date_month
        otg_start_date_day += startday_m[m_idx]
      end
      m_idx += 1
    end

    otg_end_date_day = otg_start_date_day + otg_num_days

    # Check to make sure that the outage falls within the run period
    run_period = model.getRunPeriod
    run_period_start_day = run_period.getBeginDayOfMonth + startday_m[run_period.getBeginMonth - 1]
    run_period_end_day = run_period.getEndDayOfMonth + startday_m[run_period.getEndMonth - 1]

    if otg_start_date_day < run_period_start_day
      runner.registerError("Outage start day is before the run period start")
      return false
    elsif otg_end_date_day > run_period_end_day
      runner.registerError("Outage end day is after the run period ends")
      return false
    end

    assumedYear = year_description.assumedYear # prevent excessive OS warnings about 'UseWeatherFile'
    otg_start_date = OpenStudio::Date::fromDayOfYear(otg_start_date_day, assumedYear)
    otg_end_date = OpenStudio::Date::fromDayOfYear(otg_end_date_day, assumedYear)

    # Get DST info to use to modify the schedules as appropriate
    dst = model.getRunPeriodControlDaylightSavingTime
    dst_start_day = dst.startDate.dayOfYear
    dst_end_day = dst.endDate.dayOfYear

    time = []
    for h in 0..24
      time[h] = OpenStudio::Time.new(0, h, 0, 0)
    end

    model.getScheduleRulesets.each do |schedule|
      next if schedule.name.to_s.include? "shading" or schedule.name.to_s.include? "Schedule Ruleset" or schedule.name.to_s.include? Constants.ObjectNameOccupants

      if schedule.name.to_s.include? Constants.ObjectNameHeatingSetpoint
        otg_val = UnitConversions.convert(-100, "F", "C") # FIXME: should probably revisit this; set availability schedule to off?
      elsif schedule.name.to_s.include? Constants.ObjectNameCoolingSetpoint
        otg_val = UnitConversions.convert(200, "F", "C") # FIXME: should probably revisit this; set availability schedule to off?
      else
        otg_val = 0
      end

      if otg_num_days == 0
        otg_rule = OpenStudio::Model::ScheduleRule.new(schedule)
        otg_rule.setName("#{schedule.name.to_s}" + "_outage_day_#{otg_start_date_day}")
        otg_day = otg_rule.daySchedule
        unmod_sched = schedule.getDaySchedules(otg_start_date, otg_start_date)
        if (otg_start_date_day >= dst_start_day) and otg_start_date_day <= dst_end_day
          for h in 1..24
            if h < otg_hr or h >= (otg_hr + otg_len)
              otg_day.addValue(time[h], unmod_sched[0].getValue(time[h]))
            else
              otg_day.addValue(time[h], otg_val)
            end
          end
        else
          for h in 1..24
            if h < otg_hr or h >= (otg_hr + otg_len)
              otg_day.addValue(time[h], unmod_sched[0].getValue(time[h]))
            else
              otg_day.addValue(time[h], otg_val)
            end
          end
        end
        otg_rule.setApplySunday(true)
        otg_rule.setApplyMonday(true)
        otg_rule.setApplyTuesday(true)
        otg_rule.setApplyWednesday(true)
        otg_rule.setApplyThursday(true)
        otg_rule.setApplyFriday(true)
        otg_rule.setApplySaturday(true)
        otg_rule.setStartDate(otg_start_date)
        otg_rule.setEndDate(otg_start_date)
      else
        for d in otg_start_date_day..otg_end_date_day
          day_date = OpenStudio::Date::fromDayOfYear(d, assumedYear)
          # Add a rule to the schedule for the outage
          if d == otg_start_date_day # First day of the outage
            otg_rule = OpenStudio::Model::ScheduleRule.new(schedule)
            otg_rule.setName("#{schedule.name.to_s}" + "_outage_day_#{d}")
            otg_day = otg_rule.daySchedule
            unmod_sched = schedule.getDaySchedules(day_date, day_date)
            if d >= dst_start_day and d <= dst_end_day
              for h in 1..24
                if h == 1
                  otg_day.addValue(time[h], otg_val)
                elsif h < otg_hr or h >= (otg_hr + otg_len)
                  otg_day.addValue(time[h], unmod_sched[0].getValue(time[h]))
                else
                  otg_day.addValue(time[h], otg_val)
                end
                end
            else
              for h in 1..24
                if h < otg_hr or h >= (otg_hr + otg_len)
                  otg_day.addValue(time[h], unmod_sched[0].getValue(time[h]))
                else
                  otg_day.addValue(time[h], otg_val)
                end
                end
            end
            otg_rule.setApplySunday(true)
            otg_rule.setApplyMonday(true)
            otg_rule.setApplyTuesday(true)
            otg_rule.setApplyWednesday(true)
            otg_rule.setApplyThursday(true)
            otg_rule.setApplyFriday(true)
            otg_rule.setApplySaturday(true)
            otg_rule.setStartDate(day_date)
            otg_rule.setEndDate(day_date)
          elsif d == otg_end_date_day # Last day of the outage
            otg_rule = OpenStudio::Model::ScheduleRule.new(schedule)
            otg_rule.setName("#{schedule.name.to_s}" + "_outage_day_#{d}")
            otg_day = otg_rule.daySchedule
            unmod_sched = schedule.getDaySchedules(day_date, day_date)
            if d >= dst_start_day and d <= dst_end_day
              for h in 1..24
                if h == 1
                  otg_day.addValue(time[h], unmod_sched[0].getValue(time[1]))
                elsif h < otg_end_hr
                  otg_day.addValue(time[h], otg_val)
                else
                  otg_day.addValue(time[h], unmod_sched[0].getValue(time[h]))
                end
                end
            else
              for h in 1..24
                if h < otg_end_hr
                  otg_day.addValue(time[h], otg_val)
                else
                  otg_day.addValue(time[h], unmod_sched[0].getValue(time[h]))
                end
                end
            end
            otg_rule.setApplySunday(true)
            otg_rule.setApplyMonday(true)
            otg_rule.setApplyTuesday(true)
            otg_rule.setApplyWednesday(true)
            otg_rule.setApplyThursday(true)
            otg_rule.setApplyFriday(true)
            otg_rule.setApplySaturday(true)
            otg_rule.setStartDate(day_date)
            otg_rule.setEndDate(day_date)
          else # Any middle days of the outage
            otg_rule = OpenStudio::Model::ScheduleRule.new(schedule)
            otg_rule.setName("#{schedule.name.to_s}" + "_outage_day_#{d}")
            otg_day = otg_rule.daySchedule
            unmod_sched = schedule.getDaySchedules(day_date, day_date)
            for h in 1..24
              otg_day.addValue(time[h], otg_val)
            end
            otg_rule.setApplySunday(true)
            otg_rule.setApplyMonday(true)
            otg_rule.setApplyTuesday(true)
            otg_rule.setApplyWednesday(true)
            otg_rule.setApplyThursday(true)
            otg_rule.setApplyFriday(true)
            otg_rule.setApplySaturday(true)
            otg_rule.setStartDate(day_date)
            otg_rule.setEndDate(day_date)
          end
        end
      end
    end

    # Add additional properties object with the date of the outage for use by reporting measures
    additional_properties = year_description.additionalProperties
    additional_properties.setFeature("PowerOutageStartDate", otg_date)
    additional_properties.setFeature("PowerOutageStartHour", otg_hr)
    additional_properties.setFeature("PowerOutageDuration", otg_len)

    runner.registerFinalCondition("A power outage has been added, starting on #{otg_date} at hour #{otg_hr.to_i} and lasting for #{otg_len.to_i} hours")

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ProcessPowerOutage.new.registerWithApplication
