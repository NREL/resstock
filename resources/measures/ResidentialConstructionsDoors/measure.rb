#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class ProcessConstructionsDoors < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Door Construction"
  end
  
  def description
    return "This measure assigns a construction to exterior doors adjacent to finished or unfinished space.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Calculates material layer properties of constructions for exterior door sub-surfaces adjacent to 1) finished space or 2) unfinished space."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for door sub surfaces
    finished_sub_surfaces, unfinished_sub_surfaces = get_door_sub_surfaces(model)
    sub_surfaces_args = OpenStudio::StringVector.new
    sub_surfaces_args << Constants.Auto
    (finished_sub_surfaces + unfinished_sub_surfaces).each do |sub_surface|
      sub_surfaces_args << sub_surface.name.to_s
    end        
    sub_surface = OpenStudio::Measure::OSArgument::makeChoiceArgument("sub_surface", sub_surfaces_args, false)
    sub_surface.setDisplayName("Subsurface(s)")
    sub_surface.setDescription("Select the sub surface(s) to assign constructions.")
    sub_surface.setDefaultValue(Constants.Auto)
    args << sub_surface     
    
    #make a string argument for door u-factor
    door_ufactor = OpenStudio::Measure::OSArgument::makeDoubleArgument("door_ufactor", true)
    door_ufactor.setDisplayName("U-Factor")
    door_ufactor.setUnits("Btu/hr-ft^2-R")
    door_ufactor.setDescription("The heat transfer coefficient of the doors adjacent to finished space.")
    door_ufactor.setDefaultValue(0.2)
    args << door_ufactor   

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    sub_surface_s = runner.getOptionalStringArgumentValue("sub_surface",user_arguments)
    if not sub_surface_s.is_initialized
      sub_surface_s = Constants.Auto
    else
      sub_surface_s = sub_surface_s.get
    end
    
    doorUfactor = runner.getDoubleArgumentValue("door_ufactor",user_arguments)
    if doorUfactor <= 0.0
        runner.registerError("U-Factor must be greater than 0.")
        return false
    end

    finished_sub_surfaces, unfinished_sub_surfaces = get_door_sub_surfaces(model)
    
    unless sub_surface_s == Constants.Auto
      finished_sub_surfaces.delete_if { |sub_surface| sub_surface.name.to_s != sub_surface_s }
      unfinished_sub_surfaces.delete_if { |sub_surface| sub_surface.name.to_s != sub_surface_s }
    end

    # Continue if no applicable sub surfaces
    if finished_sub_surfaces.empty? and unfinished_sub_surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no doors were found.")
      return true
    end   
    
    if not finished_sub_surfaces.empty?
        # Define materials
        door_Ufactor_air_to_air = doorUfactor
        door_Rvalue_air_to_air = 1.0 / door_Ufactor_air_to_air
        door_Rvalue = door_Rvalue_air_to_air - Material.AirFilmOutside.rvalue - Material.AirFilmVertical.rvalue
        door_thickness = 1.75 # in
        fin_door_mat = Material.new(name="DoorMaterial", thick_in=door_thickness, mat_base=BaseMaterial.Wood, k_in=1.0 / door_Rvalue * door_thickness)
        
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
        garage_door_Ufactor_air_to_air = 0.2 # Btu/hr*ft^2*F, R-values typically vary from R5 to R10, from the Home Depot website
        garage_door_Rvalue_air_to_air = 1.0 / garage_door_Ufactor_air_to_air
        garage_door_Rvalue = garage_door_Rvalue_air_to_air - Material.AirFilmOutside.rvalue - Material.AirFilmVertical.rvalue
        garage_door_thickness = 2.5 # in
        unfin_door_mat = Material.new(name="GarageDoorMaterial", thick_in=garage_door_thickness, mat_base=BaseMaterial.Wood, k_in=1.0 / garage_door_Rvalue * garage_door_thickness)
        
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
  
  def get_door_sub_surfaces(model)
  
    # Sub-surface between finished space and outdoors
    finished_sub_surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall" or ( surface.outsideBoundaryCondition.downcase != "outdoors" and surface.outsideBoundaryCondition.downcase != "adiabatic" )
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
            next if surface.surfaceType.downcase != "wall" or ( surface.outsideBoundaryCondition.downcase != "outdoors" and surface.outsideBoundaryCondition.downcase != "adiabatic" )
            surface.subSurfaces.each do |sub_surface|
                next if not sub_surface.subSurfaceType.downcase.include? "door"
                unfinished_sub_surfaces << sub_surface
            end
        end
    end

    return finished_sub_surfaces, unfinished_sub_surfaces
  
  end

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsDoors.new.registerWithApplication