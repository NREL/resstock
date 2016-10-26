# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsWallsSheathing < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Walls - Wall Sheathing"
  end

  # human readable description
  def description
    return "This measure assigns wall sheathing to all above-grade walls adjacent to finished space."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Assigns material layer properties for all above-grade walls between finished space and outside or between finished space and unfinished space."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for OSB/Plywood Thickness
	osb_thick_in = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("osb_thick_in",true)
	osb_thick_in.setDisplayName("OSB/Plywood Thickness")
    osb_thick_in.setUnits("in")
	osb_thick_in.setDescription("Specifies the thickness of the walls' OSB/plywood sheathing. Enter 0 for no sheathing (if the wall has other means to handle the shear load on the wall such as cross-bracing).")
	osb_thick_in.setDefaultValue(0.5)
	args << osb_thick_in
    
	#make a double argument for Rigid Insulation R-value
	rigid_r = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("rigid_r",true)
	rigid_r.setDisplayName("Continuous Insulation Nominal R-value")
    rigid_r.setUnits("h-ft^2-R/Btu")
    rigid_r.setDescription("The R-value of the continuous insulation.")
	rigid_r.setDefaultValue(0.0)
	args << rigid_r

	#make a double argument for Rigid Insulation Thickness
	rigid_thick_in = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("rigid_thick_in",true)
	rigid_thick_in.setDisplayName("Continuous Insulation Thickness")
    rigid_thick_in.setUnits("in")
    rigid_thick_in.setDescription("The thickness of the continuous insulation.")
	rigid_thick_in.setDefaultValue(0.0)
	args << rigid_thick_in

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    surfaces = []
    model.getSpaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            if surface.outsideBoundaryCondition.downcase == "outdoors"
                # Above-grade wall between finished space and outside    
                surfaces << surface
            elsif surface.adjacentSurface.is_initialized and surface.adjacentSurface.get.space.is_initialized
                adjacent_space = surface.adjacentSurface.get.space.get
                next if Geometry.space_is_finished(adjacent_space)
                # Above-grade wall between finished space and unfinished space
                surfaces << surface
            end
        end
    end
    if surfaces.empty?
        runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
        return true
    end

    # Get inputs
    osb_thick_in = runner.getDoubleArgumentValue("osb_thick_in",user_arguments)
    rigid_rvalue = runner.getDoubleArgumentValue("rigid_r",user_arguments)
    rigid_thick_in = runner.getDoubleArgumentValue("rigid_thick_in",user_arguments)

    # Validate inputs
    if osb_thick_in < 0.0
        runner.registerError("OSB/Plywood Thickness must be greater than or equal to 0.")
        return false
    end
    if rigid_rvalue < 0.0
        runner.registerError("Continuous Insulation Nominal R-value must be greater than or equal to 0.")
        return false
    end
    if rigid_thick_in < 0.0
        runner.registerError("Continuous Insulation Thickness must be greater than or equal to 0.")
        return false
    end
    
    # Define materials
    mat_osb = nil
    mat_rigid = nil
    if osb_thick_in > 0
        mat_osb = Material.new(name=Constants.MaterialWallSheathing, thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
    end
    if rigid_rvalue > 0 and rigid_thick_in > 0
        mat_rigid = Material.new(name=Constants.MaterialWallRigidIns, thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_rvalue)
    end
    
    # Define construction
    wall_sh = Construction.new([1])
    if not mat_rigid.nil?
        wall_sh.add_layer(mat_rigid, true)
    else
        wall_sh.remove_layer(Constants.MaterialWallRigidIns)
    end
    if not mat_osb.nil?
        wall_sh.add_layer(mat_osb, true)
    else
        wall_sh.remove_layer(Constants.MaterialWallSheathing)
    end
    
    # Create and assign construction to surfaces
    if not wall_sh.create_and_assign_constructions(surfaces, runner, model, name=nil)
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsWallsSheathing.new.registerWithApplication
