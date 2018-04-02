# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

# start the measure
class ProcessConstructionsFoundationsFloorsSheathing < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Foundations/Floors - Floor Sheathing"
  end

  # human readable description
  def description
    return "This measure assigns floor sheathing to floors of finished spaces, with the exception of foundation slabs.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Assigns material layer properties for floors of finished spaces that are not adjacent to the ground."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for floors of finished spaces
    surfaces = get_floors_sheathing_surfaces(model)
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
    
    #make a double argument for OSB/Plywood Thickness
    osb_thick_in = OpenStudio::Measure::OSArgument::makeDoubleArgument("osb_thick_in",true)
    osb_thick_in.setDisplayName("OSB/Plywood Thickness")
    osb_thick_in.setUnits("in")
    osb_thick_in.setDescription("Specifies the thickness of the floor OSB/plywood sheathing. Enter 0 for no sheathing.")
    osb_thick_in.setDefaultValue(0.75)
    args << osb_thick_in
    
    #make a double argument for Rigid Insulation R-value
    rigid_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("rigid_r",true)
    rigid_r.setDisplayName("Continuous Insulation Nominal R-value")
    rigid_r.setUnits("h-ft^2-R/Btu")
    rigid_r.setDescription("The R-value of the continuous insulation.")
    rigid_r.setDefaultValue(0.0)
    args << rigid_r

    #make a double argument for Rigid Insulation Thickness
    rigid_thick_in = OpenStudio::Measure::OSArgument::makeDoubleArgument("rigid_thick_in",true)
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

    surface_s = runner.getOptionalStringArgumentValue("surface",user_arguments)
    if not surface_s.is_initialized
      surface_s = Constants.Auto
    else
      surface_s = surface_s.get
    end
    
    surfaces = get_floors_sheathing_surfaces(model)
    
    unless surface_s == Constants.Auto
      surfaces.delete_if { |surface| surface.name.to_s != surface_s }
    end
    
    # Continue if no applicable surfaces
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
        mat_osb = Material.new(name=Constants.MaterialFloorSheathing, thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
    end
    if rigid_rvalue > 0 and rigid_thick_in > 0
        mat_rigid = Material.new(name=Constants.MaterialFloorRigidIns, thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_rvalue)
    end
    
    # Define construction
    floor_sh = Construction.new([1])
    if not mat_rigid.nil?
        floor_sh.add_layer(mat_rigid, true)
    else
        floor_sh.remove_layer(Constants.MaterialFloorRigidIns)
    end
    if not mat_osb.nil?
        floor_sh.add_layer(mat_osb, true)
    else
        floor_sh.remove_layer(Material.DefaultFloorSheathing.name)
    end
    
    # Create and assign construction to surfaces
    if not floor_sh.create_and_assign_constructions(surfaces, runner, model, name=nil)
        return false
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end
  
  def get_floors_sheathing_surfaces(model)
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
  
end

# register the measure to be used by the application
ProcessConstructionsFoundationsFloorsSheathing.new.registerWithApplication
