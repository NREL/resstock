# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/simulation"
require "#{File.dirname(__FILE__)}/resources/constants"

# start the measure
class ResidentialSimulationControls < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Set Residential Simulation Controls'
  end

  # human readable description
  def description
    return 'Set the simulation timesteps per hour and the run period begin/end month/day.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Set the simulation timesteps per hour on the Timestep object, and the run period begin/end month/day on the RunPeriod object.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for the simulation timesteps per hour
    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("timesteps_per_hr", true)
    arg.setDisplayName("Simulation Timesteps Per Hour")
    arg.setDefaultValue(6)
    args << arg

    #make an argument for the run period begin month
    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("begin_month", true)
    arg.setDisplayName("Run Period Begin Month")
    arg.setDefaultValue(1)
    args << arg

    #make an argument for the run period begin day of month
    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("begin_day_of_month", true)
    arg.setDisplayName("Run Period Begin Day of Month")
    arg.setDefaultValue(1)
    args << arg

    #make an argument for the run period end month
    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("end_month", true)
    arg.setDisplayName("Run Period End Month")
    arg.setDefaultValue(12)
    args << arg

    #make an argument for the run period end day of month
    arg = OpenStudio::Measure::OSArgument::makeIntegerArgument("end_day_of_month", true)
    arg.setDisplayName("Run Period End Day of Month")
    arg.setDefaultValue(31)
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    timesteps_per_hr = runner.getIntegerArgumentValue("timesteps_per_hr",user_arguments)
    begin_month = runner.getIntegerArgumentValue("begin_month",user_arguments)
    begin_day_of_month = runner.getIntegerArgumentValue("begin_day_of_month",user_arguments)
    end_month = runner.getIntegerArgumentValue("end_month",user_arguments)
    end_day_of_month = runner.getIntegerArgumentValue("end_day_of_month",user_arguments)

    # Error checking
    if timesteps_per_hr < 1 or timesteps_per_hr > 60
      runner.registerError("User-entered #{timesteps_per_hr} timesteps per hour must be between 1 and 60.")
      return false
    end

    if 60 % timesteps_per_hr != 0
      runner.registerError("User-entered #{timesteps_per_hr} timesteps per hour does not divide evenly into 60.")
      return false
    end

    if not (1..12).to_a.include? begin_month or not (1..12).to_a.include? end_month
      runner.registerError("Invalid begin month (#{begin_month}) and/or end month (#{end_month}) entered.")
      return false
    end

    {begin_month=>begin_day_of_month, end_month=>end_day_of_month}.each_with_index do |(month, day), i|
      leap_day = 0
      if month == 2 # february
        leap_day = 1
      end
      day_of_month_valid = (1..Constants.MonthNumDays[month-1]+leap_day).to_a.include? day # accommodate leap day
      unless day_of_month_valid
        if i == 0
          runner.registerError("Invalid begin day of month (#{begin_day_of_month}) entered.")
        elsif i == 1
          runner.registerError("Invalid end day of month (#{end_day_of_month}) entered.")
        end
        return false
      end
    end

    success = Simulation.apply(model, runner, timesteps_per_hr, min_system_timestep_mins=nil, begin_month, begin_day_of_month, end_month, end_day_of_month)
    return false if not success

    runner.registerInfo("Set the simulation timesteps per hour to #{timesteps_per_hr}.")
    runner.registerInfo("Set the run period begin and end month/day to #{begin_month}/#{begin_day_of_month} and #{end_month}/#{end_day_of_month}, respectively.")

    return true
  end
end

# register the measure to be used by the application
ResidentialSimulationControls.new.registerWithApplication
