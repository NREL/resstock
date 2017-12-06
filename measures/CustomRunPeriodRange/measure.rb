# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/weather"

# start the measure
class CustomRunPeriodRange < OpenStudio::Measure::EnergyPlusMeasure

  # human readable name
  def name
    return "CustomRunPeriodRange"
  end

  # human readable description
  def description
    return "Update the workspace with a custom run period range."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Remove the RunPeriod object which defaults to 1/1 to 12/31, and replace with RunPeriod:CustomRange object which allows a custom range, e.g. 12/31/2011 to 12/31/2012."
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    arg = OpenStudio::Measure::OSArgument.makeStringArgument("run_start_date", true)
    arg.setDisplayName("Simulation Start Date")
    arg.setDefaultValue("January 1 2012")
    args << arg
    
    arg = OpenStudio::Measure::OSArgument.makeStringArgument("run_end_date", true)
    arg.setDisplayName("Simulation End Date")
    arg.setDefaultValue("December 31 2012")
    args << arg

    return args
  end 

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking 
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    run_start_date = runner.getStringArgumentValue("run_start_date", user_arguments)
    run_end_date = runner.getStringArgumentValue("run_end_date", user_arguments)
      
    # get integers from date arguments
    run_start_month, run_start_day, run_start_year = run_start_date.split
    run_start_month = OpenStudio::monthOfYear(run_start_month).value
    run_end_month, run_end_day, run_end_year = run_end_date.split
    run_end_month = OpenStudio::monthOfYear(run_end_month).value
      
    # get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get
      
    # get timestamps from the weather file
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end
    epw_timestamps = weather.epw_timestamps.sort
    ts_start_year, ts_start_month, ts_start_day, = epw_timestamps[0].split("/")
    ts_end_year, ts_end_month, ts_end_day, = epw_timestamps[-1].split("/")

    # error checking
    run_start = Time.new(run_start_year, run_start_month, run_start_day).to_i
    run_end = Time.new(run_end_year, run_end_month, run_end_day).to_i
    epw_start = Time.new(ts_start_year, ts_start_month, ts_start_day).to_i
    epw_end = Time.new(ts_end_year, ts_end_month, ts_end_day).to_i
    if run_start < epw_start or run_start > epw_end
      runner.registerError("The run period start date is not within the epw data period.")
      return false
    end
    if run_end > epw_end or run_end < epw_start
      runner.registerError("The run period end date is not within the epw data period.")
      return false
    end

    # update epw file DATA PERIODS
    lines = File.readlines("../in.epw")
    string1, num1, num2, string2, day_of_week, header_start_date, header_end_date = lines[7].strip.split(",")
    unless header_start_date.end_with? ts_start_year
      header_start_date += "/#{ts_start_year}"
    end
    unless header_end_date.end_with? ts_end_year
      header_end_date += "/#{ts_end_year}"
    end
    lines[7] = "#{string1},#{num1},#{num2},#{string2},#{day_of_week},#{header_start_date},#{header_end_date}"
    File.open("../in.epw", "w") do |f|
      lines.each { |line| f.puts(line) }
    end

    # remove the existing RunPeriod object
    name = nil
    holidays_and_special_days = nil
    daylight_saving_period = nil
    apply_wknd_holiday_rule = nil
    use_weather_file_rain = nil
    use_weather_file_snow = nil    
    workspace.getObjectsByType("RunPeriod".to_IddObjectType).each do |object|
      name = object.getString(0).to_s
      holidays_and_special_days = object.getString(6).to_s
      daylight_saving_period = object.getString(7).to_s
      apply_wknd_holiday_rule = object.getString(8).to_s
      use_weather_file_rain = object.getString(9).to_s
      use_weather_file_snow = object.getString(10).to_s
      object.remove
    end
      
    # get day of week for start day
    yd = model.getYearDescription
    yd.setCalendarYear(run_start_year.to_i)
    yd.makeDate(ts_start_month.to_i, ts_start_day.to_i)
    day_of_week_for_start_day = yd.dayofWeekforStartDay
      
    # create the new RunPeriod:CustomRange object
    run_period_custom_range = "
    RunPeriod:CustomRange,
       #{name},                                   !- Name
       #{run_start_month},                        !- Begin Month
       #{run_start_day},                          !- Begin Day of Month
       #{run_start_year},                         !- Begin Year
       #{run_end_month},                          !- End Month
       #{run_end_day},                            !- End Day of Month
       #{run_end_year},                           !- End Year
       #{day_of_week_for_start_day},              !- Day of Week for Start Day
       #{holidays_and_special_days},              !- Use Weather File Holidays and Special Days
       #{daylight_saving_period},                 !- Use Weather File Daylight Saving Period
       #{apply_wknd_holiday_rule},                !- Apply Weekend Holiday Rule
       #{use_weather_file_rain},                  !- Use Weather File Rain Indicators
       #{use_weather_file_snow};                  !- Use Weather File Snow Indicators
       "      
      
    # add the new RunPeriod:CustomRange object
    idfObject = OpenStudio::IdfObject::load(run_period_custom_range)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    
    return true
 
  end

end 

# register the measure to be used by the application
CustomRunPeriodRange.new.registerWithApplication