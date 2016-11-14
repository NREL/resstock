# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsWallsExteriorICF < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Walls - ICF Construction"
  end

  # human readable description
  def description
    return "This measure assigns an ICF construction to above-grade exterior walls adjacent to finished space."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculates and assigns material layer properties of ICF constructions for above-grade walls between finished space and outside. If the walls have an existing construction, the layers (other than exterior finish, wall sheathing, and wall mass) are replaced. This measure is intended to be used in conjunction with Exterior Finish, Wall Sheathing, and Exterior Wall Mass measures."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for nominal R-value of the icf insulation
    icf_r = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("icf_r", true)
    icf_r.setDisplayName("Nominal Insulation R-value")
    icf_r.setUnits("hr-ft^2-R/Btu")
    icf_r.setDescription("R-value of each insulating layer of the form.")
    icf_r.setDefaultValue(10.0)
    args << icf_r

    #make a double argument for thickness of the icf insulation
    ins_thick_in = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ins_thick_in", true)
    ins_thick_in.setDisplayName("Insulation Thickness")
    ins_thick_in.setUnits("in")
    ins_thick_in.setDescription("Thickness of each insulating layer of the form.")
    ins_thick_in.setDefaultValue(2.0)
    args << ins_thick_in 

    #make a double argument for thickness of the concrete
    concrete_thick_in = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("concrete_thick_in", true)
    concrete_thick_in.setDisplayName("Concrete Thickness")
    concrete_thick_in.setUnits("in")
    concrete_thick_in.setDescription("The thickness of the concrete core of the ICF.")
    concrete_thick_in.setDefaultValue(4.0)
    args << concrete_thick_in

    #make a double argument for framing factor
    framing_factor = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("framing_factor", true)
    framing_factor.setDisplayName("Framing Factor")
    framing_factor.setUnits("frac")
    framing_factor.setDescription("Total fraction of the wall that is framing for windows or doors.")
    framing_factor.setDefaultValue(0.076)
    args << framing_factor 
        
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
    icfInsRvalue = runner.getDoubleArgumentValue("icf_r",user_arguments)
    icfInsThickness = runner.getDoubleArgumentValue("ins_thick_in",user_arguments)
    icfConcreteThickness = runner.getDoubleArgumentValue("concrete_thick_in",user_arguments)
    icfFramingFactor = runner.getDoubleArgumentValue("framing_factor",user_arguments)

    # Validate inputs
    if icfInsRvalue <= 0.0
        runner.registerError("Nominal Insulation R-value must be greater than 0.")
        return false
    end
    if icfInsThickness <= 0.0
        runner.registerError("Insulation Thickness must be greater than 0.")
        return false
    end
    if icfConcreteThickness <= 0.0
        runner.registerError("Concrete Thickness must be greater than 0.")
        return false
    end
    if icfFramingFactor < 0.0 or icfFramingFactor >= 1.0
        runner.registerError("Framing Factor must be greater than or equal to 0 and less than 1.")
        return false
    end

    # Process the ICF walls
    
    # Define materials
    mat_ins = Material.new(name=nil, thick_in=icfInsThickness, mat_base=BaseMaterial.InsulationRigid, k_in=icfInsThickness / icfInsRvalue)
    mat_conc = Material.new(name=nil, thick_in=icfConcreteThickness, mat_base=BaseMaterial.Concrete)
    mat_framing_inner_outer = Material.new(name=nil, thick_in=icfInsThickness, mat_base=BaseMaterial.Wood)
    mat_framing_middle = Material.new(name=nil, thick_in=icfConcreteThickness, mat_base=BaseMaterial.Wood)
    
    # Set paths
    path_fracs = [icfFramingFactor, 1.0 - icfFramingFactor]
    
    # Define construction
    icf_wall = Construction.new(path_fracs)
    icf_wall.add_layer(Material.AirFilmVertical, false)
    icf_wall.add_layer(Material.DefaultWallMass, false) # thermal mass added in separate measure
    icf_wall.add_layer([mat_framing_inner_outer, mat_ins], true, "ICFInsFormInner")
    icf_wall.add_layer([mat_framing_middle, mat_conc], true, "ICFConcrete")
    icf_wall.add_layer([mat_framing_inner_outer, mat_ins], true, "ICFInsFormOuter")
    icf_wall.add_layer(Material.DefaultWallSheathing, false) # OSB added in separate measure
    icf_wall.add_layer(Material.DefaultExteriorFinish, false) # exterior finish added in separate measure
    icf_wall.add_layer(Material.AirFilmOutside, false)
    
    # Create and assign construction to surfaces
    if not icf_wall.create_and_assign_constructions(surfaces, runner, model, name="ExtInsFinWall")
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)

    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsWallsExteriorICF.new.registerWithApplication
