# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ProcessConstructionsCeilingsRoofsSheathing < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Ceilings/Roofs - Roof Sheathing"
  end

  # human readable description
  def description
    return "This measure assigns roof sheathing to all attic roofs."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Assigns material layer properties for all attic roofs."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for OSB/Plywood Thickness
	osb_thick_in = OpenStudio::Measure::OSArgument::makeDoubleArgument("osb_thick_in",true)
	osb_thick_in.setDisplayName("OSB/Plywood Thickness")
    osb_thick_in.setUnits("in")
	osb_thick_in.setDescription("Specifies the thickness of the roof OSB/plywood sheathing. Enter 0 for no sheathing.")
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
    
    # Roofs adjacent to outdoors
    surfaces = []
    model.getSpaces.each do |space|
        space.surfaces.each do |surface|
            if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
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
        mat_osb = Material.new(name=Constants.MaterialRoofSheathing, thick_in=osb_thick_in, mat_base=BaseMaterial.Wood)
    end
    if rigid_rvalue > 0 and rigid_thick_in > 0
        mat_rigid = Material.new(name=Constants.MaterialRoofRigidIns, thick_in=rigid_thick_in, mat_base=BaseMaterial.InsulationRigid, k_in=rigid_thick_in/rigid_rvalue)
    end
    
    # Define construction
    roof_sh = Construction.new([1])
    if not mat_rigid.nil?
        roof_sh.add_layer(mat_rigid, true)
    else
        roof_sh.remove_layer(Constants.MaterialRoofRigidIns)
    end
    if not mat_osb.nil?
        roof_sh.add_layer(mat_osb, true)
    else
        roof_sh.remove_layer(Material.DefaultRoofSheathing.name)
    end
    
    # Create and assign construction to surfaces
    if not roof_sh.create_and_assign_constructions(surfaces, runner, model, name=nil)
        return false
    end
    
    # Store info for HVAC Sizing measure
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    surfaces.each do |surface|
        units.each do |unit|
            next if not unit.spaces.include?(surface.space.get)
            unit.setFeature(Constants.SizingInfoRoofRigidInsRvalue(surface), rigid_rvalue)
        end
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessConstructionsCeilingsRoofsSheathing.new.registerWithApplication
