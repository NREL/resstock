#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsUninsulatedWalls < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Uninsulated Wall Constructions"
  end
  
  def description
    return "This measure assigns an uninsulated wood stud construction to above-grade exterior walls adjacent to unfinished space."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of uninsulated wood stud constructions for above-grade walls between unfinished space and outside."
  end   
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Above-grade wall between unfinished space and outdoors
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_finished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            if surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors"
                surfaces << surface
            end
        end
    end

    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end    

    # Process the walls
    
    # Define materials
    mat_cavity = Material.AirCavityClosed(Material.Stud2x4.thick_in)
    mat_framing = Material.new(name=nil, thick_in=Material.Stud2x4.thick_in, mat_base=BaseMaterial.Wood)
    
    # Set paths
    path_fracs = [Constants.DefaultFramingFactorInterior, 1 - Constants.DefaultFramingFactorInterior]
    
    # Define construction
    wall = Construction.new(path_fracs)
    wall.add_layer(Material.AirFilmVertical, false)
    wall.add_layer([mat_framing, mat_cavity], true, "ExtStudAndAirWall")
    wall.add_layer(Material.DefaultWallSheathing, true)
    wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    wall.add_layer(Material.AirFilmOutside, false)

    # Create and assign construction to surfaces
    if not wall.create_and_assign_constructions(surfaces, runner, model, name="ExtUninsUnfinWall")
        return false
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsUninsulatedWalls.new.registerWithApplication