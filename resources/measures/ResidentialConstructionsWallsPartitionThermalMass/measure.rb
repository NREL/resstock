#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsWallsPartitionThermalMass < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Walls - Partition Thermal Mass"
  end
  
  def description
    return "This measure assigns partition wall mass to finished spaces.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "This measure creates constructions representing the internal mass of partition walls for finished spaces. The constructions are set to define the internal mass objects of their respective spaces."
  end    
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for fraction of floor area
    frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("frac", true)
    frac.setDisplayName("Fraction of Floor Area")
    frac.setDescription("Ratio of exposed partition wall area to total finished floor area and accounts for the area of both sides of partition walls.")
    frac.setDefaultValue(1.0)
    args << frac

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
    
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            # Adiabatic wall adjacent to finished space
            if surface.outsideBoundaryCondition.downcase == "adiabatic"
                surfaces << surface
                next
            end
            next if not surface.adjacentSurface.is_initialized
            next if not surface.adjacentSurface.get.space.is_initialized
            adjacent_space = surface.adjacentSurface.get.space.get
            next if Geometry.space_is_unfinished(adjacent_space)
            # Wall between two finished spaces
            surfaces << surface
        end
    end

    # Get Inputs
    fractionOfFloorArea = runner.getDoubleArgumentValue("frac",user_arguments)
    thick_in1 = runner.getDoubleArgumentValue("thick_in1",user_arguments)
    thick_in2 = runner.getOptionalDoubleArgumentValue("thick_in2",user_arguments)
    cond1 = runner.getDoubleArgumentValue("cond1",user_arguments)
    cond2 = runner.getOptionalDoubleArgumentValue("cond2",user_arguments)
    dens1 = runner.getDoubleArgumentValue("dens1",user_arguments)
    dens2 = runner.getOptionalDoubleArgumentValue("dens2",user_arguments)
    specheat1 = runner.getDoubleArgumentValue("specheat1",user_arguments)
    specheat2 = runner.getOptionalDoubleArgumentValue("specheat2",user_arguments)
    
    # Validate Inputs
    if fractionOfFloorArea < 0
        runner.registerError("Fraction of Floor Area must be greater than or equal to 0.")
        return false
    end
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
    
    # Constants
    mat_wood = BaseMaterial.Wood
 
    spaces = Geometry.get_finished_spaces(model.getSpaces)
    
    if spaces.size == 0
        runner.registerAsNotApplicable("Measure not applied because no applicable spaces were found.")
        return true
    end

    # Define materials
    mat1 = nil
    if thick_in1 > 0 and cond1 > 0
        mat1 = Material.new(name=Constants.MaterialWallMass, thick_in=thick_in1, mat_base=nil, k_in=cond1, rho=dens1, cp=specheat1, tAbs=0.9, sAbs=Constants.DefaultSolarAbsWall, vAbs=0.1)
    end
    mat2 = nil
    if not thick_in2.empty? and thick_in2.get > 0 and not cond2.empty? and cond2.get > 0
        mat2 = Material.new(name=Constants.MaterialWallMass2, thick_in=thick_in2.get, mat_base=nil, k_in=cond2.get, rho=dens2.get, cp=specheat2.get, tAbs=0.9, sAbs=Constants.DefaultSolarAbsWall, vAbs=0.1)
    end

    
    # -------------------------------
    # Process the existing partition walls
    # -------------------------------

    if not surfaces.empty?
        # Define construction
        wall = Construction.new([1])
        if not mat2.nil?
            wall.add_layer(mat2, true, Constants.MaterialWallMassOtherSide2)
        else
            wall.remove_layer(Constants.MaterialWallMassOtherSide2)
        end
        if not mat1.nil?
            wall.add_layer(mat1, true, Constants.MaterialWallMassOtherSide)
        else
            wall.remove_layer(Constants.MaterialWallMassOtherSide)
        end
        if not mat1.nil?
            wall.add_layer(mat1, true)
        else
            wall.remove_layer(Constants.MaterialWallMass)
        end
        if not mat2.nil?
            wall.add_layer(mat2, true)
        else
            wall.remove_layer(Constants.MaterialWallMass2)
        end
        
        if not wall.create_and_assign_constructions(surfaces, runner, model, name=nil)
            return false
        end
    end

    # -------------------------------
    # Process the additional partition walls
    # -------------------------------
    
    imdefs = []
    spaces.each do |space|
        # Determine existing partition wall mass in space
        existing_surface_area = 0
        surfaces.each do |surface|
            existing_surface_area += surface.grossArea
        end
    
        # Determine additional partition wall mass required
        addtl_surface_area = fractionOfFloorArea * space.floorArea - existing_surface_area * 2 / spaces.size.to_f
        
        # Remove any existing internal mass
        space.internalMass.each do |im|
            runner.registerInfo("Removing internal mass object '#{im.name.to_s}' from space '#{space.name.to_s}'")
            imdef = im.internalMassDefinition
            im.remove
            imdef.resetConstruction
            imdef.remove
        end
        
        if addtl_surface_area > 0
            # Add remaining partition walls within spaces (those without geometric representation)
            # as internal mass object.
            imdef = OpenStudio::Model::InternalMassDefinition.new(model)
            imdef.setName("#{space.name.to_s} Partition")
            imdef.setSurfaceArea(addtl_surface_area)
            imdefs << imdef
            im = OpenStudio::Model::InternalMass.new(imdef)
            im.setName("#{space.name.to_s} Partition")
            im.setSpace(space)
            runner.registerInfo("Added internal mass object '#{im.name.to_s}' to space '#{space.name.to_s}'")
        end
    end
    
    # Define materials
    mat_cavity = Material.AirCavityClosed(Material.Stud2x4.thick_in)
    mat_framing = Material.new(name=nil, thick_in=Material.Stud2x4.thick_in, mat_base=BaseMaterial.Wood)

    # Set paths
    path_fracs = [Constants.DefaultFramingFactorInterior, 1 - Constants.DefaultFramingFactorInterior]
    
    # Define construction
    int_mass = Construction.new(path_fracs)
    if not mat2.nil?
        int_mass.add_layer(mat2, true, Constants.MaterialWallMassOtherSide2)
    else
        int_mass.remove_layer(Constants.MaterialWallMassOtherSide2)
    end
    if not mat1.nil?
        int_mass.add_layer(mat1, true, Constants.MaterialWallMassOtherSide)
    else
        int_mass.remove_layer(Constants.MaterialWallMassOtherSide)
    end
    int_mass.add_layer([mat_framing, mat_cavity], true, "IntMassStudAndAirWall")
    if not mat1.nil?
        int_mass.add_layer(mat1, true)
    else
        int_mass.remove_layer(Constants.MaterialWallMass)
    end
    if not mat2.nil?
        int_mass.add_layer(mat2, true)
    else
        int_mass.remove_layer(Constants.MaterialWallMass2)
    end

    if not int_mass.create_and_assign_constructions(imdefs, runner, model, name="FinUninsFinWall")
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true

  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWallsPartitionThermalMass.new.registerWithApplication