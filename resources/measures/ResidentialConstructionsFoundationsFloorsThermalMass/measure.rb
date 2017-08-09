#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsFoundationsFloorsThermalMass < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Foundations/Floors - Floor Thermal Mass"
  end
  
  def description
    return "This measure assigns floor mass to floors of finished spaces, with the exception of foundation slabs.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Assigns material layer properties for floors of finished spaces that are not adjacent to the ground."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for floors of finished spaces
    surfaces = get_floors_thermal_mass_surfaces(model)
    surfaces_args = OpenStudio::StringVector.new
    surfaces_args << Constants.Auto
    surfaces.each do |surface|
      surfaces_args << surface.name.to_s
    end
    surface = OpenStudio::Measure::OSArgument::makeChoiceArgument("surface", surfaces_args, false)
    surface.setDisplayName("Surface(s)")
    surface.setDescription("Select the surface(s) to assign constructions.")
    surface.setDefaultValue(Constants.Auto)
    args << surface     
    
    #make a double argument for thickness
    thick_in = OpenStudio::Measure::OSArgument::makeDoubleArgument("thick_in", true)
    thick_in.setDisplayName("Thickness")
    thick_in.setUnits("in")
    thick_in.setDescription("Thickness of the floor mass.")
    thick_in.setDefaultValue(0.625)
    args << thick_in
    
    #make a double argument for conductivity
    cond = OpenStudio::Measure::OSArgument::makeDoubleArgument("cond", true)
    cond.setDisplayName("Conductivity")
    cond.setUnits("Btu-in/h-ft^2-R")
    cond.setDescription("Conductivity of the floor mass.")
    cond.setDefaultValue(0.8004)
    args << cond
    
    #make a double argument for density
    dens = OpenStudio::Measure::OSArgument::makeDoubleArgument("dens", true)
    dens.setDisplayName("Density")
    dens.setUnits("lb/ft^3")
    dens.setDescription("Density of the floor mass.")
    dens.setDefaultValue(34.0)
    args << dens
    
    #make a double argument for specific heat
    specheat = OpenStudio::Measure::OSArgument::makeDoubleArgument("specheat", true)
    specheat.setDisplayName("Specific Heat")
    specheat.setUnits("Btu/lb-R")
    specheat.setDescription("Specific heat of the floor mass.")
    specheat.setDefaultValue(0.29)
    args << specheat
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    surface_s = runner.getOptionalStringArgumentValue("surface",user_arguments)
    if not surface_s.is_initialized
      surface_s = Constants.Auto
    else
      surface_s = surface_s.get
    end
    
    surfaces = get_floors_thermal_mass_surfaces(model)
    
    unless surface_s == Constants.Auto
      surfaces.delete_if { |surface| surface.name.to_s != surface_s }
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end        
    
    # Get Inputs
    thick_in = runner.getDoubleArgumentValue("thick_in",user_arguments)
    cond = runner.getDoubleArgumentValue("cond",user_arguments)
    dens = runner.getDoubleArgumentValue("dens",user_arguments)
    specheat = runner.getDoubleArgumentValue("specheat",user_arguments)
    
    # Validate Inputs
    if thick_in <= 0.0
        runner.registerError("Thickness must be greater than 0.")
        return false
    end
    if cond <= 0.0
        runner.registerError("Conductivity must be greater than 0.")
        return false
    end
    if dens <= 0.0
        runner.registerError("Density must be greater than 0.")
        return false
    end
    if specheat <= 0.0
        runner.registerError("Specific Heat must be greater than 0.")
        return false
    end
    
    # Process the floors mass
    
    # Define Materials
    mat = Material.new(name=Constants.MaterialFloorMass, thick_in=thick_in, mat_base=nil, k_in=cond, rho=dens, cp=specheat, tAbs=0.9, sAbs=Constants.DefaultSolarAbsFloor)
    
    # Define construction
    floor = Construction.new([1])
    floor.add_layer(mat, true)
    
    # Create and assign construction to surfaces
    if not floor.create_and_assign_constructions(surfaces, runner, model, name=nil)
        return false
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end #end the run method
  
  def get_floors_thermal_mass_surfaces(model)
    # Floors of finished spaces (except foundation slabs)
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if surface.outsideBoundaryCondition.downcase == "ground"
            surfaces << surface
        end
    end
    return surfaces
  end

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsFoundationsFloorsThermalMass.new.registerWithApplication