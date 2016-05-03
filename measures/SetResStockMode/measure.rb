# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# Adapted from Measure Picker measure
# https://github.com/NREL/OpenStudio-measures/blob/develop/NREL%20working%20measures/measure_picker/measure.rb

# start the measure
class SetResStockMode < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Res Stock Mode"
  end

  # human readable description
  def description
    return "Specifies which mode to use (e.g., National-Scale, PNW, etc.)."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Probability distribution files found in ./resources/mode/ will be used."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    res_stock_modes = OpenStudio::StringVector.new
    res_stock_modes << "national"
    res_stock_modes << "pnw"
    
    res_stock_mode = OpenStudio::Ruleset::OSArgument.makeChoiceArgument("res_stock_mode", res_stock_modes, true)
    res_stock_mode.setDisplayName("Res Stock Mode")
    args << res_stock_mode
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    res_stock_mode = runner.getStringArgumentValue("res_stock_mode",user_arguments)
    
    # Argument already registered in runner, nothing additional to do
    
    return true

  end
  
end

# register the measure to be used by the application
SetResStockMode.new.registerWithApplication
