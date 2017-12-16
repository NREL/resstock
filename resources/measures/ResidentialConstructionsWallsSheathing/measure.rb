# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

# start the measure
class ProcessConstructionsWallsSheathing < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Walls - Wall Sheathing"
  end

  # human readable description
  def description
    return "This measure assigns wall sheathing to all above-grade walls adjacent to finished space.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Assigns material layer properties for all above-grade walls between finished space and outside or between finished space and unfinished space."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for finished, unfinished surfaces
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    finished_surfaces, unfinished_surfaces = get_sheathing_wall_surfaces(model, runner)
    surfaces_args = OpenStudio::StringVector.new
    surfaces_args << Constants.Auto
    (finished_surfaces + unfinished_surfaces).each do |surface|
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
    osb_thick_in.setDescription("Specifies the thickness of the walls' OSB/plywood sheathing. Enter 0 for no sheathing (if the wall has other means to handle the shear load on the wall such as cross-bracing).")
    osb_thick_in.setDefaultValue(0.5)
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
    
    finished_surfaces, unfinished_surfaces = get_sheathing_wall_surfaces(model, runner)
    
    unless surface_s == Constants.Auto
      finished_surfaces.delete_if { |surface| surface.name.to_s != surface_s }
      unfinished_surfaces.delete_if { |surface| surface.name.to_s != surface_s }
    end
    
    if finished_surfaces.empty? and unfinished_surfaces.empty?
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
    
    if not finished_surfaces.empty?
        # Define construction
        fin_wall_sh = Construction.new([1])
        if not mat_rigid.nil?
            fin_wall_sh.add_layer(mat_rigid, true)
        else
            fin_wall_sh.remove_layer(Constants.MaterialWallRigidIns)
        end
        if not mat_osb.nil?
            fin_wall_sh.add_layer(mat_osb, true)
        else
            fin_wall_sh.remove_layer(Constants.MaterialWallSheathing)
        end
        
        # Create and assign construction to surfaces
        if not fin_wall_sh.create_and_assign_constructions(finished_surfaces, runner, model, name=nil)
            return false
        end
    end
    
    if not unfinished_surfaces.empty?
        # Define construction
        unfin_wall_sh = Construction.new([1])
        if not mat_rigid.nil?
            unfin_wall_sh.add_layer(mat_rigid, true)
        else
            unfin_wall_sh.remove_layer(Constants.MaterialWallRigidIns)
        end
        if not mat_osb.nil?
            unfin_wall_sh.add_layer(mat_osb, true)
        else
            unfin_wall_sh.remove_layer(Constants.MaterialWallSheathing)
        end
        
        # Create and assign construction to surfaces
        if not unfin_wall_sh.create_and_assign_constructions(unfinished_surfaces, runner, model, name=nil)
            return false
        end
    end
    
    # Store info for HVAC Sizing measure
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    (finished_surfaces + unfinished_surfaces).each do |surface|
        units.each do |unit|
            next if not unit.spaces.include?(surface.space.get)
            unit.setFeature(Constants.SizingInfoWallRigidInsRvalue(surface), rigid_rvalue)
            unit.setFeature(Constants.SizingInfoWallRigidInsThickness(surface), rigid_thick_in)
        end
    end

    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end
  
  def get_sheathing_wall_surfaces(model, runner)
    finished_surfaces = []
    unfinished_surfaces = []
    model.getSpaces.each do |space|
        # Walls adjacent to finished space
        if Geometry.space_is_finished(space) and Geometry.space_is_above_grade(space)
            space.surfaces.each do |surface|
                next if surface.surfaceType.downcase != "wall"
                if surface.outsideBoundaryCondition.downcase == "outdoors"
                    # Above-grade wall between finished space and outside    
                    finished_surfaces << surface
                elsif surface.adjacentSurface.is_initialized and surface.adjacentSurface.get.space.is_initialized
                    adjacent_space = surface.adjacentSurface.get.space.get
                    next if Geometry.space_is_finished(adjacent_space)
                    # Above-grade wall between finished space and unfinished space
                    finished_surfaces << surface
                end
            end
        # Attic wall under an insulated roof
        elsif Geometry.is_unfinished_attic(space)
            attic_roof_r = Construction.get_space_r_value(runner, space, "roofceiling")
            next if attic_roof_r.nil? or attic_roof_r <= 5 # assume uninsulated if <= R-5 assembly
            space.surfaces.each do |surface|
                next if surface.surfaceType.downcase != "wall" or surface.outsideBoundaryCondition.downcase != "outdoors"
                unfinished_surfaces << surface
            end
        end
    end
    return finished_surfaces, unfinished_surfaces
  end
  
end

# register the measure to be used by the application
ProcessConstructionsWallsSheathing.new.registerWithApplication
