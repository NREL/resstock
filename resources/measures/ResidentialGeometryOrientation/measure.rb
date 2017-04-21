# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class CreateResidentialOrientation < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Orientation"
  end

  # human readable description
  def description
    return "Sets the fixed orientation of the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Modifies the North axis of the building."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
	
    #make a choice argument for foundation type
    orientation = OpenStudio::Measure::OSArgument::makeDoubleArgument("orientation", true)
    orientation.setDisplayName("Azimuth")
    orientation.setUnits("degrees")
    orientation.setDescription("The house's azimuth is measured clockwise from due south when viewed from above (e.g., South=0, West=90, North=180, East=270).")
    orientation.setDefaultValue(180.0)
    args << orientation
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    orientation = runner.getDoubleArgumentValue("orientation",user_arguments)
	
    if orientation > 360 or orientation < 0
      runner.registerError("Invalid orientation entered.")
      return false
    end

    building = model.getBuilding
    unless building.northAxis == orientation
      runner.registerInfo("The orientation of the building has changed.")
    end
    runner.registerInitialCondition("The building's initial orientation was #{building.northAxis} azimuth.")
    building.setNorthAxis(orientation) # the shading surfaces representing neighbors have ShadingSurfaceType=Building, and so are oriented along with the building
    runner.registerFinalCondition("The building's final orientation was #{building.northAxis} azimuth.")
	
    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialOrientation.new.registerWithApplication
