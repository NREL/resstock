#see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessConstructionsWallsExteriorGeneric < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Walls - Generic Construction"
  end
  
  def description
    return "This measure assigns a generic layered construction to above-grade exterior walls adjacent to finished space."
  end
  
  def modeler_description
    return "Calculates and assigns material layer properties of generic constructions for above-grade walls between finished space and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end  
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for layer 1: thickness
    thick_in1 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("thick_in_1", true)
    thick_in1.setDisplayName("Thickness 1")
    thick_in1.setUnits("in")
    thick_in1.setDescription("Thickness of the outside layer.")
    thick_in1.setDefaultValue(2.5)
    args << thick_in1
    
    #make a double argument for layer 2: thickness
    thick_in2 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("thick_in_2", false)
    thick_in2.setDisplayName("Thickness 2")
    thick_in2.setUnits("in")
    thick_in2.setDescription("Thickness of the second layer. Leave blank if no second layer.")
    args << thick_in2

    #make a double argument for layer 3: thickness
    thick_in3 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("thick_in_3", false)
    thick_in3.setDisplayName("Thickness 3")
    thick_in3.setUnits("in")
    thick_in3.setDescription("Thickness of the third layer. Leave blank if no third layer.")
    args << thick_in3

    #make a double argument for layer 4: thickness
    thick_in4 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("thick_in_4", false)
    thick_in4.setDisplayName("Thickness 4")
    thick_in4.setUnits("in")
    thick_in4.setDescription("Thickness of the fourth layer. Leave blank if no fourth layer.")
    args << thick_in4

    #make a double argument for layer 5: thickness
    thick_in5 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("thick_in_5", false)
    thick_in5.setDisplayName("Thickness 5")
    thick_in5.setUnits("in")
    thick_in5.setDescription("Thickness of the fifth layer. Leave blank if no fifth layer.")
    args << thick_in5
    
    #make a double argument for layer 1: conductivity
    cond1 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("conductivity_1", true)
    cond1.setDisplayName("Conductivity 1")
    cond1.setUnits("Btu-in/h-ft^2-R")
    cond1.setDescription("Conductivity of the outside layer.")
    cond1.setDefaultValue(9.211)
    args << cond1
    
    #make a double argument for layer 2: conductivity
    cond2 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("conductivity_2", false)
    cond2.setDisplayName("Conductivity 2")
    cond2.setUnits("Btu-in/h-ft^2-R")
    cond2.setDescription("Conductivity of the second layer. Leave blank if no second layer.")
    args << cond2

    #make a double argument for layer 3: conductivity
    cond3 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("conductivity_3", false)
    cond3.setDisplayName("Conductivity 3")
    cond3.setUnits("Btu-in/h-ft^2-R")
    cond3.setDescription("Conductivity of the third layer. Leave blank if no third layer.")
    args << cond3

    #make a double argument for layer 4: conductivity
    cond4 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("conductivity_4", false)
    cond4.setDisplayName("Conductivity 4")
    cond4.setUnits("Btu-in/h-ft^2-R")
    cond4.setDescription("Conductivity of the fourth layer. Leave blank if no fourth layer.")
    args << cond4

    #make a double argument for layer 5: conductivity
    cond5 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("conductivity_5", false)
    cond5.setDisplayName("Conductivity 5")
    cond5.setUnits("Btu-in/h-ft^2-R")
    cond5.setDescription("Conductivity of the fifth layer. Leave blank if no fifth layer.")
    args << cond5

    #make a double argument for layer 1: density
    dens1 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("density_1", true)
    dens1.setDisplayName("Density 1")
    dens1.setUnits("lb/ft^3")
    dens1.setDescription("Density of the outside layer.")
    dens1.setDefaultValue(138.33)
    args << dens1
    
    #make a double argument for layer 2: density
    dens2 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("density_2", false)
    dens2.setDisplayName("Density 2")
    dens2.setUnits("lb/ft^3")
    dens2.setDescription("Density of the second layer. Leave blank if no second layer.")
    args << dens2

    #make a double argument for layer 3: density
    dens3 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("density_3", false)
    dens3.setDisplayName("Density 3")
    dens3.setUnits("lb/ft^3")
    dens3.setDescription("Density of the third layer. Leave blank if no third layer.")
    args << dens3

    #make a double argument for layer 4: density
    dens4 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("density_4", false)
    dens4.setDisplayName("Density 4")
    dens4.setUnits("lb/ft^3")
    dens4.setDescription("Density of the fourth layer. Leave blank if no fourth layer.")
    args << dens4

    #make a double argument for layer 5: density
    dens5 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("density_5", false)
    dens5.setDisplayName("Density 5")
    dens5.setUnits("lb/ft^3")
    dens5.setDescription("Density of the fifth layer. Leave blank if no fifth layer.")
    args << dens5

    #make a double argument for layer 1: specific heat
    specheat1 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("specific_heat_1", true)
    specheat1.setDisplayName("Specific Heat 1")
    specheat1.setUnits("Btu/lb-R")
    specheat1.setDescription("Specific heat of the outside layer.")
    specheat1.setDefaultValue(0.23)
    args << specheat1
    
    #make a double argument for layer 2: specific heat
    specheat2 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("specific_heat_2", false)
    specheat2.setDisplayName("Specific Heat 2")
    specheat2.setUnits("Btu/lb-R")
    specheat2.setDescription("Specific heat of the second layer. Leave blank if no second layer.")
    args << specheat2

    #make a double argument for layer 3: specific heat
    specheat3 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("specific_heat_3", false)
    specheat3.setDisplayName("Specific Heat 3")
    specheat3.setUnits("Btu/lb-R")
    specheat3.setDescription("Specific heat of the third layer. Leave blank if no third layer.")
    args << specheat3

    #make a double argument for layer 4: specific heat
    specheat4 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("specific_heat_4", false)
    specheat4.setDisplayName("Specific Heat 4")
    specheat4.setUnits("Btu/lb-R")
    specheat4.setDescription("Specific heat of the fourth layer. Leave blank if no fourth layer.")
    args << specheat4

    #make a double argument for layer 5: specific heat
    specheat5 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("specific_heat_5", false)
    specheat5.setDisplayName("Specific Heat 5")
    specheat5.setUnits("Btu/lb-R")
    specheat5.setDescription("Specific heat of the fifth layer. Leave blank if no fifth layer.")
    args << specheat5
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Above-grade wall between finished space and outdoors
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
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
    
    # Get inputs
    thick_in1 = runner.getDoubleArgumentValue("thick_in_1",user_arguments)
    thick_in2 = runner.getOptionalDoubleArgumentValue("thick_in_2",user_arguments)
    thick_in3 = runner.getOptionalDoubleArgumentValue("thick_in_3",user_arguments)
    thick_in4 = runner.getOptionalDoubleArgumentValue("thick_in_4",user_arguments)
    thick_in5 = runner.getOptionalDoubleArgumentValue("thick_in_5",user_arguments)
    cond1 = runner.getDoubleArgumentValue("conductivity_1",user_arguments)
    cond2 = runner.getOptionalDoubleArgumentValue("conductivity_2",user_arguments)
    cond3 = runner.getOptionalDoubleArgumentValue("conductivity_3",user_arguments)
    cond4 = runner.getOptionalDoubleArgumentValue("conductivity_4",user_arguments)
    cond5 = runner.getOptionalDoubleArgumentValue("conductivity_5",user_arguments)
    dens1 = runner.getDoubleArgumentValue("density_1",user_arguments)
    dens2 = runner.getOptionalDoubleArgumentValue("density_2",user_arguments)
    dens3 = runner.getOptionalDoubleArgumentValue("density_3",user_arguments)
    dens4 = runner.getOptionalDoubleArgumentValue("density_4",user_arguments)
    dens5 = runner.getOptionalDoubleArgumentValue("density_5",user_arguments)
    specheat1 = runner.getDoubleArgumentValue("specific_heat_1",user_arguments)
    specheat2 = runner.getOptionalDoubleArgumentValue("specific_heat_2",user_arguments)
    specheat3 = runner.getOptionalDoubleArgumentValue("specific_heat_3",user_arguments)
    specheat4 = runner.getOptionalDoubleArgumentValue("specific_heat_4",user_arguments)
    specheat5 = runner.getOptionalDoubleArgumentValue("specific_heat_5",user_arguments)
    
    # Validate inputs
    if thick_in2.empty? != cond2.empty? or thick_in2.empty? != dens2.empty? or thick_in2.empty? != specheat2.empty?
        runner.registerError("Layer 2 does not have all four properties (thickness, conductivity, density, specific heat) entered.")
        return false
    end
    if thick_in3.empty? != cond3.empty? or thick_in3.empty? != dens3.empty? or thick_in3.empty? != specheat3.empty?
        runner.registerError("Layer 3 does not have all four properties (thickness, conductivity, density, specific heat) entered.")
        return false
    end
    if thick_in4.empty? != cond4.empty? or thick_in4.empty? != dens4.empty? or thick_in4.empty? != specheat4.empty?
        runner.registerError("Layer 4 does not have all four properties (thickness, conductivity, density, specific heat) entered.")
        return false
    end
    if thick_in5.empty? != cond5.empty? or thick_in5.empty? != dens5.empty? or thick_in5.empty? != specheat5.empty?
        runner.registerError("Layer 5 does not have all four properties (thickness, conductivity, density, specific heat) entered.")
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
    if not thick_in3.empty? and thick_in3.get <= 0.0
        runner.registerError("Thickness 3 must be greater than 0.")
        return false
    end
    if not thick_in4.empty? and thick_in4.get <= 0.0
        runner.registerError("Thickness 4 must be greater than 0.")
        return false
    end
    if not thick_in5.empty? and thick_in5.get <= 0.0
        runner.registerError("Thickness 5 must be greater than 0.")
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
    if not cond3.empty? and cond3.get <= 0.0
        runner.registerError("Conductivity 3 must be greater than 0.")
        return false
    end
    if not cond4.empty? and cond4.get <= 0.0
        runner.registerError("Conductivity 4 must be greater than 0.")
        return false
    end
    if not cond5.empty? and cond5.get <= 0.0
        runner.registerError("Conductivity 5 must be greater than 0.")
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
    if not dens3.empty? and dens3.get <= 0.0
        runner.registerError("Density 3 must be greater than 0.")
        return false
    end
    if not dens4.empty? and dens4.get <= 0.0
        runner.registerError("Density 4 must be greater than 0.")
        return false
    end
    if not dens5.empty? and dens5.get <= 0.0
        runner.registerError("Density 5 must be greater than 0.")
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
    if not specheat3.empty? and specheat3.get <= 0.0
        runner.registerError("Specific Heat 3 must be greater than 0.")
        return false
    end
    if not specheat4.empty? and specheat4.get <= 0.0
        runner.registerError("Specific Heat 4 must be greater than 0.")
        return false
    end
    if not specheat5.empty? and specheat5.get <= 0.0
        runner.registerError("Specific Heat 5 must be greater than 0.")
        return false
    end
    
    # Process the generic walls

    # Define materials
    mat1 = Material.new(name="Layer1", thick_in=thick_in1, mat_base=nil, k_in=cond1, rho=dens1, cp=specheat1)
    mat2 = nil
    if not thick_in2.empty?
        mat2 = Material.new(name="Layer2", thick_in=thick_in2.get, mat_base=nil, k_in=cond2.get, rho=dens2.get, cp=specheat2.get)
    end
    mat3 = nil
    if not thick_in3.empty?
        mat3 = Material.new(name="Layer3", thick_in=thick_in3.get, mat_base=nil, k_in=cond3.get, rho=dens3.get, cp=specheat3.get)
    end
    mat4 = nil
    if not thick_in4.empty?
        mat4 = Material.new(name="Layer4", thick_in=thick_in4.get, mat_base=nil, k_in=cond4.get, rho=dens4.get, cp=specheat4.get)
    end
    mat5 = nil
    if not thick_in5.empty?
        mat5 = Material.new(name="Layer5", thick_in=thick_in5.get, mat_base=nil, k_in=cond5.get, rho=dens5.get, cp=specheat5.get)
    end

    # Define construction
    wall = Construction.new([1])
    wall.add_layer(Material.AirFilmVertical, false)
    wall.add_layer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    wall.add_layer(mat1, true)
    if not mat2.nil?
        wall.add_layer(mat2, true)
    end
    if not mat3.nil?
        wall.add_layer(mat3, true)
    end
    if not mat4.nil?
        wall.add_layer(mat4, true)
    end
    if not mat5.nil?
        wall.add_layer(mat5, true)
    end
    wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    wall.add_layer(Material.AirFilmOutside, false)

    # Create and assign construction to surfaces
    if not wall.create_and_assign_constructions(surfaces, runner, model, name="ExtInsFinWall")
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ProcessConstructionsWallsExteriorGeneric.new.registerWithApplication