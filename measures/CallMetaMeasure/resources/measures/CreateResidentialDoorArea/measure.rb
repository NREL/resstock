# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialDoorArea < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Door Area"
  end

  # human readable description
  def description
    return "Sets the opaque door area for the building. Doors with glazing should be set as window area."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets the opaque door area for the lowest above-grade front surface of the building attached to living space. Any existing doors are removed."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for front door area
    userdefineddoorarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineddoorarea", true)
    userdefineddoorarea.setDisplayName("Door Area")
    userdefineddoorarea.setUnits("ft^2")
    userdefineddoorarea.setDescription("The area of the front door.")
    userdefineddoorarea.setDefaultValue(20.0)
    args << userdefineddoorarea

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    door_area = OpenStudio::convert(runner.getDoubleArgumentValue("userdefineddoorarea",user_arguments),"ft^2","m^2").get

    model.getSpaces.each do |space|
        space.surfaces.each do |surface|
            next if not (surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors")
            surface.subSurfaces.each do |sub_surface|
                next if sub_surface.subSurfaceType != "Door"
                sub_surface.remove
                runner.registerInfo("Removed #{sub_surface.name}.")
            end    
        end
    end
    
    # error checking
    if door_area < 0
      runner.registerError("Invalid door area.")
      return false
    elsif door_area == 0
      runner.registerInfo("No door added because door area was set to 0 ft^2.")
      return true
    end    
    
    door_height = 2.1336 # 7 ft
    door_offset = 0.5

    # get building orientation
    building_orientation = model.getBuilding.northAxis.round
	
    # get all exterior front walls on the lowest story
    front_walls = []
    Geometry.get_finished_spaces(model).each do |space|
        next if Geometry.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if not (surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors")
            wall_azimuth = OpenStudio::Quantity.new(surface.azimuth, OpenStudio::createSIAngle)
            wall_orientation = (OpenStudio.convert(wall_azimuth, OpenStudio::createIPAngle).get.value + building_orientation).round			
            next if wall_orientation - 180 != building_orientation
            front_walls << surface
        end
    end
    
    first_story_front_walls = []
    first_story_front_wall_minz = 99999
    front_walls.each do |front_wall|
        zvalues = Geometry.getSurfaceZValues([front_wall])
        minz = zvalues.min + front_wall.space.get.zOrigin
        if minz < first_story_front_wall_minz
            first_story_front_walls.clear
            first_story_front_walls << front_wall
            first_story_front_wall_minz = minz
        elsif minz == first_story_front_wall_minz
            first_story_front_walls << front_wall
        end
    end
    
    if first_story_front_walls.size == 0
        runner.registerError("Could not find appropriate surface for the door. No door was added.")
        return false
    end
    
    door_sub_surface = nil
    first_story_front_walls.each do |first_story_front_wall|
      # Try to place door on any surface with enough area
      next if door_area >= first_story_front_wall.grossArea
      
      front_wall_least_x = 10000
      front_wall_least_z = 10000	
      sw_point = nil
      vertices = first_story_front_wall.vertices
      vertices.each do |vertex|
        if vertex.x < front_wall_least_x
          front_wall_least_x = vertex.x
        end
        if vertex.z < front_wall_least_z
          front_wall_least_z = vertex.z
        end	
      end
      vertices.each do |vertex|
        if vertex.x == front_wall_least_x and vertex.z == front_wall_least_z
          sw_point = vertex
        end
      end

      door_sw_point = OpenStudio::Point3d.new(sw_point.x + door_offset, sw_point.y, sw_point.z)
      door_nw_point = OpenStudio::Point3d.new(sw_point.x + door_offset, sw_point.y, sw_point.z + door_height)
      door_ne_point = OpenStudio::Point3d.new(sw_point.x + door_offset + (door_area / door_height), sw_point.y, sw_point.z + door_height)
      door_se_point = OpenStudio::Point3d.new(sw_point.x + door_offset + (door_area / door_height), sw_point.y, sw_point.z)	
      
      door_polygon = Geometry.make_polygon(door_sw_point, door_se_point, door_ne_point, door_nw_point)
      door_sub_surface = OpenStudio::Model::SubSurface.new(door_polygon, model)
      door_sub_surface.setName("#{first_story_front_wall.name} - Front Door")
      door_sub_surface.setSubSurfaceType("Door")
      door_sub_surface.setSurface(first_story_front_wall)	
      added_door = true
    end
    
    if door_sub_surface.nil? then
        runner.registerError("Could not find appropriate surface for the door. No door was added.")
        return false
    end

    runner.registerInfo("Added #{OpenStudio::convert(door_area,"m^2","ft^2").get.round(1)} ft^2 door with name '#{door_sub_surface.name}'.")
    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialDoorArea.new.registerWithApplication
