 #see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsCeilingsRoofsThermalMass < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Ceilings/Roofs - Ceiling Thermal Mass"
  end
  
  def description
    return "This measure assigns thermal mass to ceilings adjacent to finished space.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Assigns material layer properties for ceilings adjacent to finished space."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for ceilings of finished space
    surfaces = get_roof_thermal_mass_surfaces(model)
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
    
    #make a double argument for layer 1: thickness
    thick_in1 = OpenStudio::Measure::OSArgument::makeDoubleArgument("thick_in1", true)
    thick_in1.setDisplayName("Thickness 1")
    thick_in1.setUnits("in")
    thick_in1.setDescription("Thickness of the layer.")
    thick_in1.setDefaultValue(0.5)
    args << thick_in1
    
    #make a double argument for layer 2: thickness
    thick_in2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("thick_in2", false)
    thick_in2.setDisplayName("Thickness 2")
    thick_in2.setUnits("in")
    thick_in2.setDescription("Thickness of the second layer. Leave blank if no second layer.")
    args << thick_in2
    
    #make a double argument for layer 1: conductivity
    cond1 = OpenStudio::Measure::OSArgument::makeDoubleArgument("cond1", true)
    cond1.setDisplayName("Conductivity 1")
    cond1.setUnits("Btu-in/h-ft^2-R")
    cond1.setDescription("Conductivity of the layer.")
    cond1.setDefaultValue(1.1112)
    args << cond1
    
    #make a double argument for layer 2: conductivity
    cond2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("cond2", false)
    cond2.setDisplayName("Conductivity 2")
    cond2.setUnits("Btu-in/h-ft^2-R")
    cond2.setDescription("Conductivity of the second layer. Leave blank if no second layer.")
    args << cond2

    #make a double argument for layer 1: density
    dens1 = OpenStudio::Measure::OSArgument::makeDoubleArgument("dens1", true)
    dens1.setDisplayName("Density 1")
    dens1.setUnits("lb/ft^3")
    dens1.setDescription("Density of the layer.")
    dens1.setDefaultValue(50.0)
    args << dens1
    
    #make a double argument for layer 2: density
    dens2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("dens2", false)
    dens2.setDisplayName("Density 2")
    dens2.setUnits("lb/ft^3")
    dens2.setDescription("Density of the second layer. Leave blank if no second layer.")
    args << dens2
    
    #make a double argument for layer 1: specific heat
    specheat1 = OpenStudio::Measure::OSArgument::makeDoubleArgument("specheat1", true)
    specheat1.setDisplayName("Specific Heat 1")
    specheat1.setUnits("Btu/lb-R")
    specheat1.setDescription("Specific heat of the layer.")
    specheat1.setDefaultValue(0.2)
    args << specheat1
    
    #make a double argument for layer 2: specific heat
    specheat2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("specheat2", false)
    specheat2.setDisplayName("Specific Heat 2")
    specheat2.setUnits("Btu/lb-R")
    specheat2.setDescription("Specific heat of the second layer. Leave blank if no second layer.")
    args << specheat2
    
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
    
    surfaces = get_roof_thermal_mass_surfaces(model)
    
    unless surface_s == Constants.Auto
      surfaces.delete_if { |surface| surface.name.to_s != surface_s }
    end
    
    # Continue if no applicable surfaces
    if surfaces.empty?
      runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
      return true
    end 

    # Get inputs
    thick_in1 = runner.getDoubleArgumentValue("thick_in1",user_arguments)
    thick_in2 = runner.getOptionalDoubleArgumentValue("thick_in2",user_arguments)
    cond1 = runner.getDoubleArgumentValue("cond1",user_arguments)
    cond2 = runner.getOptionalDoubleArgumentValue("cond2",user_arguments)
    dens1 = runner.getDoubleArgumentValue("dens1",user_arguments)
    dens2 = runner.getOptionalDoubleArgumentValue("dens2",user_arguments)
    specheat1 = runner.getDoubleArgumentValue("specheat1",user_arguments)
    specheat2 = runner.getOptionalDoubleArgumentValue("specheat2",user_arguments)

    # Validate inputs
    if thick_in2.empty? != cond2.empty? or thick_in2.empty? != dens2.empty? or thick_in2.empty? != specheat2.empty?
        runner.registerError("Layer 2 does not have all four properties (thickness, conductivity, density, specific heat) entered.")
        return false
    end
    if thick_in1 <= 0.0
        runner.registerError("Thickness 1 must be greater than 0.")
        return false
    end
    if not thick_in2.empty? and thick_in2.get <= 0.0
        runner.registerError("Thickness 2 must be greater than 0.")
        return false
    end
    if cond1 <= 0.0
        runner.registerError("Conductivity 1 must be greater than 0.")
        return false
    end
    if not cond2.empty? and cond2.get <= 0.0
        runner.registerError("Conductivity 2 must be greater than 0.")
        return false
    end
    if dens1 <= 0.0
        runner.registerError("Density 1 must be greater than 0.")
        return false
    end
    if not dens2.empty? and dens2.get <= 0.0
        runner.registerError("Density 2 must be greater than 0.")
        return false
    end
    if specheat1 <= 0.0
        runner.registerError("Specific Heat 1 must be greater than 0.")
        return false
    end
    if not specheat2.empty? and specheat2.get <= 0.0
        runner.registerError("Specific Heat 2 must be greater than 0.")
        return false
    end

    # Process the ceiling thermal mass
    
    # Define materials
    mat1 = Material.new(name=Constants.MaterialCeilingMass, thick_in=thick_in1, mat_base=nil, k_in=cond1, rho=dens1, cp=specheat1, tAbs=0.9, sAbs=Constants.DefaultSolarAbsCeiling, vAbs=0.1)
    mat2 = nil
    if not thick_in2.empty?
        mat2 = Material.new(name=Constants.MaterialCeilingMass2, thick_in=thick_in2.get, mat_base=nil, k_in=cond2.get, rho=dens2.get, cp=specheat2.get, tAbs=0.9, sAbs=Constants.DefaultSolarAbsCeiling, vAbs=0.1)
    end

    # Define construction
    ceiling = Construction.new([1])
    ceiling.add_layer(mat1, true)
    if not mat2.nil?
        ceiling.add_layer(mat2, true)
    else
        ceiling.remove_layer(Constants.MaterialCeilingMass2)
    end
    
    # Create and assign construction to surfaces
    if not ceiling.create_and_assign_constructions(surfaces, runner, model, name=nil)
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true

  end #end the run method
  
  def get_roof_thermal_mass_surfaces(model)
    # Ceilings of finished space
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        space.surfaces.each do |surface|
            if surface.surfaceType.downcase == "roofceiling"
                surfaces << surface
            end
        end
    end
    return surfaces
  end

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsCeilingsRoofsThermalMass.new.registerWithApplication