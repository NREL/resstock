#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsDoors < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Door Construction"
  end
  
  def description
    return "This measure assigns a construction to exterior doors adjacent to finished or unfinished space."
  end
  
  def modeler_description
    return "Calculates material layer properties of constructions for door sub-surfaces between 1) finished space and outside or 2) unfinished space and outside."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a choice argument for model objects
    doors_display_names = OpenStudio::StringVector.new
    doors_display_names << "Wood"
    doors_display_names << "Steel"
    doors_display_names << "Fiberglass"
    
    #make a string argument for wood stud size of wall cavity
    selected_door = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selecteddoor", doors_display_names, true)
    selected_door.setDisplayName("Door Type")
    selected_door.setDescription("The front door type.")
    selected_door.setDefaultValue("Fiberglass")
    args << selected_door   

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Sub-surface between finished space and outdoors
    finished_sub_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall" or surface.outsideBoundaryCondition.downcase != "outdoors"
            surface.subSurfaces.each do |sub_surface|
                next if not sub_surface.subSurfaceType.downcase.include? "door"
                finished_sub_surfaces << sub_surface
            end
        end
    end

    # Sub-surface between unfinished space and outdoors
    unfinished_sub_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_finished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall" or surface.outsideBoundaryCondition.downcase != "outdoors"
            surface.subSurfaces.each do |sub_surface|
                next if not sub_surface.subSurfaceType.downcase.include? "door"
                unfinished_sub_surfaces << sub_surface
            end
        end
    end
    
    # Continue if no applicable sub surfaces
    if finished_sub_surfaces.empty? and unfinished_sub_surfaces.empty?
      return true
    end   
    
    if not finished_sub_surfaces.empty?
        # Define materials
        selected_door = runner.getStringArgumentValue("selecteddoor",user_arguments)
        doorUvalue = {"Wood"=>0.48, "Steel"=>0.2, "Fiberglass"=>0.2}[selected_door]
        door_Uvalue_air_to_air = doorUvalue
        door_Rvalue_air_to_air = 1.0 / door_Uvalue_air_to_air
        door_Rvalue = door_Rvalue_air_to_air - Material.AirFilmOutside.rvalue - Material.AirFilmVertical.rvalue
        door_Uvalue = 1.0 / door_Rvalue
        door_thickness = 1.75 # in
        fin_door_mat = Material.new(name="DoorMaterial", thick_in=door_thickness, mat_base=BaseMaterial.Wood, k_in=door_Uvalue * door_thickness)
        
        # Set paths
        path_fracs = [1]
        
        # Define construction
        fin_door = Construction.new(path_fracs)
        fin_door.add_layer(fin_door_mat, true)
        
        # Create and assign construction to surfaces
        if not fin_door.create_and_assign_constructions(finished_sub_surfaces, runner, model, name="LivingDoors")
            return false
        end
    end

    if not unfinished_sub_surfaces.empty?
        # Define materials
        garage_door_Uvalue_air_to_air = 0.2 # Btu/hr*ft^2*F, R-values typically vary from R5 to R10, from the Home Depot website
        garage_door_Rvalue_air_to_air = 1.0 / garage_door_Uvalue_air_to_air
        garage_door_Rvalue = garage_door_Rvalue_air_to_air - Material.AirFilmOutside.rvalue - Material.AirFilmVertical.rvalue
        garage_door_Uvalue = 1.0 / garage_door_Rvalue
        garage_door_thickness = 2.5 # in
        unfin_door_mat = Material.new(name="GarageDoorMaterial", thick_in=garage_door_thickness, mat_base=BaseMaterial.Wood, k_in=garage_door_Uvalue * garage_door_thickness)
        
        # Set paths
        path_fracs = [1]
        
        # Define construction
        unfin_door = Construction.new(path_fracs)
        unfin_door.add_layer(unfin_door_mat, true)
        
        # Create and assign construction to surfaces
        if not unfin_door.create_and_assign_constructions(unfinished_sub_surfaces, runner, model, name="UnfinDoors")
            return false
        end
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsDoors.new.registerWithApplication