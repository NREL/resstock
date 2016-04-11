require 'openstudio'

class ResStockReporting < OpenStudio::Ruleset::ReportingUserScript

  def name
    "Res Stock Reporting"
  end

  #define the arguments that the user will input
  def arguments
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking
    unless runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    runner.registerInfo("past_results: #{runner.past_results.to_s}")
    runner.registerValue("test_value", "foo")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResStockReporting.new.registerWithApplication