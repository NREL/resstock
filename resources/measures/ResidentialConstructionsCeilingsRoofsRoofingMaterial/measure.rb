# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsCeilingsRoofsRoofingMaterial < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Ceilings/Roofs - Roofing Material"
  end

  # human readable description
  def description
    return "This measure assigns the roofing material to all roof surfaces."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Assigns material layer properties for all roofceiling surfaces adjacent to outside."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

	#make a double argument for solar absorptivity
	solar_abs = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("solar_abs", true)
	solar_abs.setDisplayName("Solar Absorptivity")
	solar_abs.setDescription("Fraction of the incident radiation that is absorbed.")
	solar_abs.setDefaultValue(0.85)
	args << solar_abs

    #make a double argument for emissivity
	emiss = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("emiss", true)
	emiss.setDisplayName("Emissivity")
	emiss.setDescription("Measure of the exterior finish's ability to emit infrared energy.")
	emiss.setDefaultValue(0.91)
	args << emiss
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Roofs adjacent to outdoors
    surfaces = []
    model.getSpaces.each do |space|
        space.surfaces.each do |surface|
            if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
                surfaces << surface
            end
        end
    end
    if surfaces.empty?
        runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
        return true
    end
    
    # Get inputs
    solar_abs = runner.getDoubleArgumentValue("solar_abs",user_arguments)
    emiss = runner.getDoubleArgumentValue("emiss",user_arguments)
    
    # Validate inputs
    if solar_abs < 0.0 or solar_abs > 1.0
        runner.registerError("Solar Absorptivity must be greater than or equal to 0 and less than or equal to 1.")
        return false
    end
    if emiss < 0.0 or emiss > 1.0
        runner.registerError("Emissivity must be greater than 0.")
        return false
    end

    # Define materials
    mat = Material.RoofMaterial(emiss, solar_abs)
    
    # Define construction
    roof_mat = Construction.new([1])
    roof_mat.add_layer(mat, true)
    
    # Create and assign construction to surfaces
    if not roof_mat.create_and_assign_constructions(surfaces, runner, model, name=nil)
        return false
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsCeilingsRoofsRoofingMaterial.new.registerWithApplication
