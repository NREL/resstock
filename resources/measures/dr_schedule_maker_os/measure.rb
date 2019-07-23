# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/os_lib_schedules"

# start the measure
class DrScheduleMakerOS < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return "DrScheduleMakerOS"
  end

  # human readable description
  def description
    return "Create a DR Event schedule using an OS measure"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Create a DR Event schedule using an OS measure"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Name of the DR Schedule
    schedule_name = OpenStudio::Measure::OSArgument.makeStringArgument("schedule_name", true)
    schedule_name.setDisplayName("Name of DR Schedule")
    schedule_name.setDescription("The name of the Schedule used by DR setpoint measures for EMS code.")
    schedule_name.setDefaultValue("dr_event_hvac")
    args << schedule_name
	
    # the start time of the daily DR event
    event_start_time = OpenStudio::Measure::OSArgument.makeDoubleArgument("event_start_time", true)
    event_start_time.setDisplayName("DR Event Start Time")
    event_start_time.setDescription("The hour of the day that the daily DR event begins at; fractional numbers are allowed.")
    event_start_time.setUnits("hr")
    #event_start_time.setMinValue(0.0)
    #event_start_time.setMaxValue(24.0)
    args << event_start_time
	
    # the duration of the daily DR event
    event_duration = OpenStudio::Measure::OSArgument.makeDoubleArgument("event_duration", true)
    event_duration.setDisplayName("DR Event Duration")
    event_duration.setDescription("The duration of the daily DR event in hours.")
    event_duration.setUnits("hr")
    #event_duration.setMinValue(0.0)
    #event_duration.setMaxValue(24.0)
    args << event_duration

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    schedule_name = runner.getStringArgumentValue("schedule_name", user_arguments)
    event_start_time = runner.getDoubleArgumentValue("event_start_time", user_arguments)
    event_duration = runner.getDoubleArgumentValue("event_duration", user_arguments)
    event_end_time = (event_start_time + event_duration) % 24.0

    if event_start_time < event_end_time
      # add "DR Event" schedule
	  ruleset_name = schedule_name
      winter_design_day = [[24,0]]
      summer_design_day = [[24,0]]
      default_day = ["AllDays",[event_start_time,0],[event_end_time,1],[24,0]]
      options = {"name" => ruleset_name,
                      "winter_design_day" => winter_design_day,
                      "summer_design_day" => summer_design_day,
                      "default_day" => default_day}
      dr_event_schedule = OsLib_Schedules.createComplexSchedule(model, options)
    else
      # add "DR Event" schedule
	  ruleset_name = schedule_name
      winter_design_day = [[24,0]]
      summer_design_day = [[24,0]]
      default_day = ["AllDays",[event_end_time,1],[event_start_time,0],[24,1]]
      options = {"name" => ruleset_name,
                      "winter_design_day" => winter_design_day,
                      "summer_design_day" => summer_design_day,
                      "default_day" => default_day}
      dr_event_schedule = OsLib_Schedules.createComplexSchedule(model, options)
    end

    runner.registerInfo("Added schedule #{dr_event_schedule.name}")

    return true
  end
end

# register the measure to be used by the application
DrScheduleMakerOS.new.registerWithApplication
