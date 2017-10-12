# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class CustomRunPeriodRange < OpenStudio::Ruleset::WorkspaceUserScript

  # human readable name
  def name
    return "CustomRunPeriodRange"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

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
      
    # update epw file DATA PERIODS
    lines = File.readlines("../in.epw")
    string1, num1, num2, string2, day_of_week, epw_start_date, epw_end_date = lines[7].strip.split(",")
    unless epw_start_date.end_with? run_start_year
      epw_start_date += "/#{run_start_year}"
    end
    unless epw_end_date.end_with? run_end_year
      epw_end_date += "/#{run_end_year}"
    end
    lines[7] = "#{string1},#{num1},#{num2},#{string2},#{day_of_week},#{epw_start_date},#{epw_end_date}"
    File.open("../in.epw", "w") do |f|
      lines.each { |line| f.puts(line) }
    end
      
    name = nil
    holidays_and_special_days = nil
    daylight_saving_period = nil
    apply_wknd_holiday_rule = nil
    use_weather_file_rain = nil
    use_weather_file_snow = nil
    times_runperiod_repeated = nil
      
    # remove the existing RunPeriod object
    workspace.getObjectsByType("RunPeriod".to_IddObjectType).each do |object|
      name = object.getString(0).to_s
      holidays_and_special_days = object.getString(6).to_s
      daylight_saving_period = object.getString(7).to_s
      apply_wknd_holiday_rule = object.getString(8).to_s
      use_weather_file_rain = object.getString(9).to_s
      use_weather_file_snow = object.getString(10).to_s
      times_runperiod_repeated = object.getString(11).to_s
      object.remove
    end
      
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
       UseWeatherFile,                            !- Day of Week for Start Day
       #{holidays_and_special_days},               !- Use Weather File Holidays and Special Days
       #{daylight_saving_period},                 !- Use Weather File Daylight Saving Period
       #{apply_wknd_holiday_rule},                !- Apply Weekend Holiday Rule
       #{use_weather_file_rain},                  !- Use Weather File Rain Indicators
       #{use_weather_file_snow};                  !- Use Weather File Snow Indicators
       #{times_runperiod_repeated}                !- Number of Time Runperiod to be Repeated
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