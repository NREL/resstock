# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsCeilingsRoofsRadiantBarrier < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Ceilings/Roofs - Radiant Barrier"
  end

  # human readable description
  def description
    return "This measure assigns the radiant barrier material to all roof surfaces attached to unfinished space."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Assigns material layer properties for all roofceiling surfaces adjacent to outside that are not attached to unfinished space."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a boolean argument for Has Radiant Barrier
	has_rb = OpenStudio::Ruleset::OSArgument::makeBoolArgument("has_rb",true)
	has_rb.setDisplayName("Has Radiant Barrier")
	has_rb.setDefaultValue(false)
	args << has_rb
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Unfinished roofs adjacent to outdoors
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_finished(space)
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
    has_rb = runner.getBoolArgumentValue("has_rb",user_arguments)
    
    # Define materials
    mat = nil
    if has_rb
        mat = Material.RadiantBarrier
    end
    
    # Define construction
    rb = Construction.new([1])
    if not mat.nil?
        rb.add_layer(mat, true)
    else
        rb.remove_layer(Material.RadiantBarrier.name)
    end
    
    # Create and assign construction to surfaces
    if not rb.create_and_assign_constructions(surfaces, runner, model, name=nil)
        return false
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsCeilingsRoofsRadiantBarrier.new.registerWithApplication
