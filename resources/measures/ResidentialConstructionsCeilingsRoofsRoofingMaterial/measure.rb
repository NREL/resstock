# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

# start the measure
class ProcessConstructionsCeilingsRoofsRoofingMaterial < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Ceilings/Roofs - Roofing Material"
  end

  # human readable description
  def description
    return "This measure assigns the roofing material to all roof surfaces.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Assigns material layer properties for all roofceiling surfaces adjacent to outside."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a choice argument for roofs adjacent to outdoors
    surfaces = get_roofing_material_surfaces(model)
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
    
    #make a double argument for solar absorptivity
    solar_abs = OpenStudio::Measure::OSArgument::makeDoubleArgument("solar_abs", true)
    solar_abs.setDisplayName("Solar Absorptivity")
    solar_abs.setDescription("Fraction of the incident radiation that is absorbed.")
    solar_abs.setDefaultValue(0.85)
    args << solar_abs

    #make a double argument for emissivity
    emiss = OpenStudio::Measure::OSArgument::makeDoubleArgument("emissivity", true)
    emiss.setDisplayName("Emissivity")
    emiss.setDescription("Measure of the material's ability to emit infrared energy.")
    emiss.setDefaultValue(0.91)
    args << emiss
    
    #make a choice argument for material
    choices = OpenStudio::StringVector.new
    choices << Constants.RoofMaterialAsphaltShingles
    choices << Constants.RoofMaterialMembrane
    choices << Constants.RoofMaterialMetal
    choices << Constants.RoofMaterialTarGravel
    choices << Constants.RoofMaterialTile
    choices << Constants.RoofMaterialWoodShakes
    material = OpenStudio::Measure::OSArgument::makeChoiceArgument("material", choices, true)
    material.setDisplayName("Material")
    material.setDescription("Material description used only for Manual J sizing calculations.")
    material.setDefaultValue(Constants.RoofMaterialAsphaltShingles)
    args << material
    
    #make a choice argument for color
    choices = OpenStudio::StringVector.new
    choices << Constants.ColorWhite
    choices << Constants.ColorLight
    choices << Constants.ColorMedium
    choices << Constants.ColorDark
    color = OpenStudio::Measure::OSArgument::makeChoiceArgument("color", choices, true)
    color.setDisplayName("Color")
    color.setDescription("Color description used only for Manual J sizing calculations.")
    color.setDefaultValue(Constants.ColorMedium)
    args << color
    
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
    
    surfaces = get_roofing_material_surfaces(model)
    
    unless surface_s == Constants.Auto
      surfaces.delete_if { |surface| surface.name.to_s != surface_s }
    end
    
    if surfaces.empty?
        runner.registerAsNotApplicable("Measure not applied because no applicable surfaces were found.")
        return true
    end
    
    # Get inputs
    solar_abs = runner.getDoubleArgumentValue("solar_abs",user_arguments)
    emiss = runner.getDoubleArgumentValue("emissivity",user_arguments)
    manual_j_color = runner.getStringArgumentValue("color",user_arguments)
    manual_j_material = runner.getStringArgumentValue("material",user_arguments)
    
    # Validate inputs
    if solar_abs < 0.0 or solar_abs > 1.0
        runner.registerError("Solar Absorptivity must be greater than or equal to 0 and less than or equal to 1.")
        return false
    end
    if emiss < 0.0 or emiss > 1.0
        runner.registerError("Emissivity must be greater than or equal to 0 and less than or equal to 1.")
        return false
    end

    # Define materials
    mat = Material.RoofMaterial(emiss, solar_abs)
    
    # Define construction
    roof_mat = Construction.new([1])
    roof_mat.add_layer(mat, true)
    
    # Create and assign construction to surfaces
    if not roof_mat.create_and_assign_constructions(surfaces, runner, model, name=nil)
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
            unit.setFeature(Constants.SizingInfoRoofColor(surface), manual_j_color)
            unit.setFeature(Constants.SizingInfoRoofMaterial(surface), manual_j_material)
        end
    end
    
    # Remove any constructions/materials that aren't used
    HelperMethods.remove_unused_constructions_and_materials(model, runner)
    
    return true

  end
  
  def get_roofing_material_surfaces(model)
    # Roofs adjacent to outdoors
    surfaces = []
    model.getSpaces.each do |space|
        space.surfaces.each do |surface|
            if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
                surfaces << surface
            end
        end
    end
    return surfaces
  end
  
end

# register the measure to be used by the application
ProcessConstructionsCeilingsRoofsRoofingMaterial.new.registerWithApplication
