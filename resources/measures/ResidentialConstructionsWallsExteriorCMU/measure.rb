# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsWallsExteriorCMU < OpenStudio::Ruleset::ModelUserScript
    
  # human readable name
  def name
    return "Set Residential Walls - CMU Construction"
  end

  # human readable description
  def description
    return "This measure assigns a CMU construction to above-grade exterior walls adjacent to finished space."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates and assigns material layer properties of CMU constructions for above-grade walls between finished space and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
        
    #make a double argument for thickness of the cmu block
    thickness = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("thickness", true)
    thickness.setDisplayName("CMU Block Thickness")
    thickness.setUnits("in")
    thickness.setDescription("Thickness of the CMU portion of the wall.")
    thickness.setDefaultValue(6.0)
    args << thickness
    
    #make a double argument for conductivity of the cmu block
    conductivity = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("conductivity", true)
    conductivity.setDisplayName("CMU Conductivity")
    conductivity.setUnits("Btu-in/hr-ft^2-R")
    conductivity.setDescription("Overall conductivity of the finished CMU block.")
    conductivity.setDefaultValue(5.33)
    args << conductivity 
    
    #make a double argument for density of the cmu block
    density = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("density", true)
    density.setDisplayName("CMU Density")
    density.setUnits("lb/ft^3")
    density.setDescription("The density of the finished CMU block.")
    density.setDefaultValue(119.0)
    args << density      
    
    #make a double argument for framing factor
    framing_factor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("framing_factor", true)
    framing_factor.setDisplayName("Framing Factor")
    framing_factor.setUnits("frac")
    framing_factor.setDescription("Total fraction of the wall that is framing for windows or doors.")
    framing_factor.setDefaultValue(0.076)
    args << framing_factor
    
    #make a double argument for furring insulation R-value
    furring_r = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("furring_r", true)
    furring_r.setDisplayName("Furring Insulation R-value")
    furring_r.setUnits("hr-ft^2-R/Btu")
    furring_r.setDescription("R-value of the insulation filling the furring cavity. Enter zero for no furring strips.")
    furring_r.setDefaultValue(0.0)
    args << furring_r
    
    #make a double argument for furring cavity depth
    furring_cavity_depth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("furring_cavity_depth", true)
    furring_cavity_depth.setDisplayName("Furring Cavity Depth")
    furring_cavity_depth.setUnits("in")
    furring_cavity_depth.setDescription("The depth of the interior furring cavity. Enter zero for no furring strips.")
    furring_cavity_depth.setDefaultValue(1.0)
    args << furring_cavity_depth 
    
    #make a double argument for furring stud spacing
    furring_spacing = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("furring_spacing", true)
    furring_spacing.setDisplayName("Furring Stud Spacing")
    furring_spacing.setUnits("in")
    furring_spacing.setDescription("Spacing of studs in the furring. Enter zero for no furring strips.")
    furring_spacing.setDefaultValue(24.0)
    args << furring_spacing  
        
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Wall between finished space and outdoors
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
    cmuThickness = runner.getDoubleArgumentValue("thickness",user_arguments)
    cmuConductivity = runner.getDoubleArgumentValue("conductivity",user_arguments)
    cmuDensity = runner.getDoubleArgumentValue("density",user_arguments)
    cmuFramingFactor = runner.getDoubleArgumentValue("framing_factor",user_arguments)
    cmuFurringInsRvalue = runner.getDoubleArgumentValue("furring_r",user_arguments)
    cmuFurringCavityDepth = runner.getDoubleArgumentValue("furring_cavity_depth",user_arguments)
    cmuFurringStudSpacing = runner.getDoubleArgumentValue("furring_spacing",user_arguments)

    # Validate inputs
    if cmuThickness <= 0.0
        runner.registerError("CMU Block Thickness must be greater than 0.")
        return false
    end
    if cmuConductivity <= 0.0
        runner.registerError("CMU Conductivity must be greater than 0.")
        return false
    end
    if cmuDensity <= 0.0
        runner.registerError("CMU Density must be greater than 0.")
        return false
    end
    if cmuFramingFactor < 0.0 or cmuFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end
    if cmuFurringInsRvalue < 0.0
        runner.registerError("Furring Insulation R-value must be greater than or equal to 0.")
        return false
    end
    if cmuFurringCavityDepth < 0.0
        runner.registerError("Furring Cavity Depth must be greater than or equal to 0.")
        return false
    end
    if cmuFurringStudSpacing < 0.0
        runner.registerError("Furring Stud Spacing must be greater than or equal to 0.")
        return false
    end

    # Process the CMU walls
    
    # Define materials
    mat_cmu = Material.new(name=nil, thick_in=cmuThickness, mat_base=BaseMaterial.Concrete, k_in=cmuConductivity, rho=cmuDensity)
    mat_framing = Material.new(name=nil, thick_in=cmuThickness, mat_base=BaseMaterial.Wood)
    mat_furring = nil
    mat_furring_cavity = nil
    if cmuFurringCavityDepth != 0
        mat_furring = Material.new(name=nil, thick_in=cmuFurringCavityDepth, mat_base=BaseMaterial.Wood)
        if cmuFurringInsRvalue == 0
            mat_furring_cavity = Material.AirCavityClosed(cmuFurringCavityDepth)
        else
            mat_furring_cavity = Material.new(name=nil, thick_in=cmuFurringCavityDepth, mat_base=BaseMaterial.InsulationGenericDensepack, k_in=cmuFurringCavityDepth / cmuFurringInsRvalue)
        end
    end
    
    # Set paths
    if not mat_furring.nil?
        stud_frac = 1.5 / cmuFurringStudSpacing
        cavity_frac = 1.0 - (stud_frac + cmuFramingFactor)
        path_fracs = [cmuFramingFactor, stud_frac, cavity_frac]
    else # No furring:
        path_fracs = [cmuFramingFactor, 1.0 - cmuFramingFactor]
    end
    
    # Define construction
    cmu_wall = Construction.new(path_fracs)
    cmu_wall.add_layer(Material.AirFilmVertical, false)
    cmu_wall.add_layer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    if not mat_furring.nil?
        cmu_wall.add_layer([mat_furring, mat_furring, mat_furring_cavity], true, "Furring")
        cmu_wall.add_layer([mat_framing, mat_cmu, mat_cmu], true, "CMU")
    else
        cmu_wall.add_layer([mat_framing, mat_cmu], true, "CMU")
    end
    cmu_wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    cmu_wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    cmu_wall.add_layer(Material.AirFilmOutside, false)
        
    # Create and assign construction to surfaces
    if not cmu_wall.create_and_assign_constructions(surfaces, runner, model, name="ExtInsFinWall")
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
        
    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsWallsExteriorCMU.new.registerWithApplication
