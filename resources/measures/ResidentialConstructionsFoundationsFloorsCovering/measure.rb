#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsFoundationsFloorsCovering < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Foundations/Floors - Floor Covering"
  end
  
  def description
    return "This measure assigns a covering to floors of above-grade finished spaces."
  end
  
  def modeler_description
    return "Assigns material layer properties for floors of above-grade finished spaces."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for floor covering fraction
    covering_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("covering_frac", true)
    covering_frac.setDisplayName("Floor Covering Fraction")
    covering_frac.setDescription("Fraction of floors that are covered.")
    covering_frac.setDefaultValue(0.8)
    args << covering_frac
    
    #make a double argument for floor covering r-value
    covering_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("covering_r", true)
    covering_r.setDisplayName("Covering R-value")
    covering_r.setUnits("h-ft^2-R/Btu")
    covering_r.setDescription("The total R-value of the covering.")
    covering_r.setDefaultValue(2.08)
    args << covering_r
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Floors of above-grade finished spaces
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            surfaces << surface
        end
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end        
    
    # Get Inputs
    covering_frac = runner.getDoubleArgumentValue("covering_frac",user_arguments)
    covering_r = runner.getDoubleArgumentValue("covering_r",user_arguments)
    
    # Validate Inputs
    if covering_frac < 0.0 or covering_frac > 1.0
        runner.registerError("Floor Covering Fraction must be greater than or equal to 0 and less than or equal to 1.")
        return false
    end
    if covering_r < 0.0
        runner.registerError("Covering R-value must be greater than or equal to 0.")
        return false
    end
    
    # Process the floors mass
    
    # Define Materials
    mat = nil
    if covering_frac > 0 and covering_r > 0
        mat = Material.CoveringBare(covering_frac, covering_r)
    end
    
    # Define construction
    floor = Construction.new([1])
    if not mat.nil?
        floor.add_layer(mat, true)
    else
        floor.remove_layer(Constants.MaterialFloorCovering)
    end
    
    # Create and assign construction to surfaces
    if not floor.create_and_assign_constructions(surfaces, runner, model, name=nil)
        return false
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsFoundationsFloorsCovering.new.registerWithApplication