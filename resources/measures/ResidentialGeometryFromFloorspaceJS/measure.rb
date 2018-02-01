# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'json'

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class ResidentialGeometryFromFloorspaceJS < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Residential Geometry from FloorspaceJS"
  end

  # human readable description
  def description
    return "Imports a floorplan JSON file written by the FloorspaceJS tool."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Currently this measure deletes the existing geometry and replaces it."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # path to the floorplan JSON file to load
    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument("floorplan_path", true)
    arg.setDisplayName("Floorplan Path")
    arg.setDescription("Path to the floorplan JSON.")
    arg.setDefaultValue(File.join(File.dirname(__FILE__), "tests", "SFD_Multizone.json"))
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    floorplan_path = runner.getStringArgumentValue("floorplan_path", user_arguments)

    # check the floorplan_path for reasonableness
    if floorplan_path.empty?
      runner.registerError("Empty floorplan path was entered.")
      return false
    end
    
    path = runner.workflow.findFile(floorplan_path)
    if path.empty?
      runner.registerError("Cannot find floorplan path '#{floorplan_path}'.")
      return false
    end
    
    json = nil
    File.open(path.get.to_s, 'r') do |file|
      json = file.read
    end

    floorplan = OpenStudio::FloorplanJS::load(json)
    if floorplan.empty?
      runner.registerError("Cannot load floorplan from '#{floorplan_path}'.")
      return false
    end

    scene = floorplan.get.toThreeScene(true)
    rt = OpenStudio::Model::ThreeJSReverseTranslator.new
    new_model = rt.modelFromThreeJS(scene)
    
    unless new_model.is_initialized
      runner.registerError("Cannot convert floorplan to model.")
      return false
    end
    new_model = new_model.get

    runner.registerInitialCondition("Initial model has #{model.getPlanarSurfaceGroups.size} planar surface groups")
    
    mm = OpenStudio::Model::ModelMerger.new
    mm.mergeModels(model, new_model, rt.handleMapping)
    
    mm.warnings.each do |warnings|
      runner.registerWarning(warnings.logMessage)
    end

    runner.registerFinalCondition("Final model has #{model.getPlanarSurfaceGroups.size} planar surface groups")
    
    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end
    
    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)
    
    json = JSON.parse(json)
    
    # error checking
    unless json["space_types"].length > 0
      runner.registerError("No space types were created.")
      return false
    end

    # set the space type standards fields based on what user wrote in the editor
    json["space_types"].each do |st|
      model.getSpaceTypes.each do |space_type|
        next unless st["name"] == space_type.name.to_s
        space_type.setStandardsSpaceType(st["name"])
      end
    end

    # remove any unused space types
    model.getSpaceTypes.each do |space_type|
      if space_type.spaces.length == 0
        space_type.remove
        next
      end
    end
    
    # permit only expected space type names
    model.getSpaceTypes.each do |space_type|
      next if Constants.ExpectedSpaceTypes.include? space_type.standardsSpaceType.get
      runner.registerError("Unexpected space type '#{space_type.standardsSpaceType.get}'. Supported space types are: '#{Constants.ExpectedSpaceTypes.join("', '")}'.")
      return false
    end

    # for any spaces with no assigned zone, create (unless another space of the same space type has an assigned zone) a thermal zone based on the space type    
    model.getSpaceTypes.each do |space_type|
      space_type.spaces.each do |space|
        unless space.thermalZone.is_initialized
          thermal_zone = OpenStudio::Model::ThermalZone.new(model)
          thermal_zone.setName(space.name.to_s)
          space.setThermalZone(thermal_zone)
        end
      end
    end

    # ensure that all spaces in a zone are either all finished or all unfinished
    model.getThermalZones.each do |thermal_zone|
      if thermal_zone.spaces.length == 0
        thermal_zone.remove
        next
      end
      unless thermal_zone.spaces.map {|space| Geometry.space_is_finished(space)}.uniq.size == 1
        runner.registerError("'#{thermal_zone.name}' has a mix of finished and unfinished spaces.")
        return false
      end
    end
    
    # assume no building unit means SFD
    unless model.getBuildingUnits.length > 0
      unit = OpenStudio::Model::BuildingUnit.new(model)
      unit.setBuildingUnitType(Constants.BuildingUnitTypeResidential)
      unit.setName(Constants.ObjectNameBuildingUnit)
      model.getSpaces.each do |space|
        space.setBuildingUnit(unit)
      end
    end

    # set some required meta information
    if model.getBuildingUnits.length == 1
      model.getBuilding.setStandardsBuildingType(Constants.BuildingTypeSingleFamilyDetached)
    else # SFA or MF
      if model.getBuildingUnits.select{ |building_unit| Geometry.get_building_stories(building_unit.spaces) > 1 }.any?
        model.getBuilding.setStandardsBuildingType(Constants.BuildingTypeSingleFamilyAttached)
      else
        model.getBuilding.setStandardsBuildingType(Constants.BuildingTypeMultifamily)
      end
    end
    model.getBuilding.setStandardsNumberOfAboveGroundStories(Geometry.get_building_stories(model.getSpaces)) # FIXME: how to count finished attics as well?
    
    # make all surfaces adjacent to corridor spaces into adiabatic surfaces
    model.getSpaces.each do |space|
      next unless Geometry.is_corridor(space)
      space.surfaces.each do |surface|
        if surface.adjacentSurface.is_initialized
          surface.adjacentSurface.get.setOutsideBoundaryCondition("Adiabatic")
        end
        surface.setOutsideBoundaryCondition("Adiabatic")
      end
    end
    
    model.getSurfaces.each do |surface|
      next unless surface.outsideBoundaryCondition.downcase == "surface"
      next if surface.adjacentSurface.is_initialized
      surface.setOutsideBoundaryCondition("Adiabatic")
    end
=begin
    # FIXME: temp until i figure out why garage roof is adjacent to outdoors
    model.getSpaces.each do |space|
      next unless space.spaceType.get.standardsSpaceType.get == Constants.SpaceTypeGarage
      space.surfaces.each do |surface|
        next unless surface.surfaceType.downcase == "roofceiling"
        model.getSurfaces.each do |adjacent_surface|
          next unless surface.vertices == adjacent_surface.vertices
          surface.setAdjacentSurface(adjacent_surface)
        end
      end      
    end
=end
    return true

  end
  

  
end

# register the measure to be used by the application
ResidentialGeometryFromFloorspaceJS.new.registerWithApplication
