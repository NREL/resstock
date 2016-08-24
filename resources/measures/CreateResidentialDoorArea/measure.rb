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
    return "Sets the opaque door area for the building. Doors with glazing should be set as window area. For multifamily buildings, applies to each unit."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets the opaque door area for the lowest above-grade front surface of the building attached to living space. Any existing doors are removed. For multifamily buildings, applies to each unit."
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
            next if not surface.surfaceType.downcase == "wall"
            surface.subSurfaces.each do |sub_surface|
                next if sub_surface.subSurfaceType.downcase != "door"
                sub_surface.remove
                runner.registerInfo("Removed door(s) from #{surface.name}.")
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
    door_width = door_area / door_height
    door_offset = 0.5

    # get building orientation
    building_orientation = model.getBuilding.northAxis.round
	
    num_units = Geometry.get_num_units(model, runner)
    if num_units.nil?
        return false
    end  
  
    (1..num_units).to_a.each do |unit_num|
      _nbeds, _nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)  
  
      # get all exterior front walls on the lowest story
      front_walls = []
      Geometry.get_finished_spaces(model, unit_spaces).each do |space|
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

      first_story_most_front_walls = []
      first_story_front_wall_miny = 99999
      first_story_front_walls.each do |front_wall|
          yvalues = Geometry.getSurfaceYValues([front_wall])
          miny = yvalues.min + front_wall.space.get.yOrigin
          if miny < first_story_front_wall_miny
              first_story_most_front_walls.clear
              first_story_most_front_walls << front_wall
              first_story_front_wall_miny = miny
          elsif miny == first_story_front_wall_miny
              first_story_most_front_walls << front_wall
          end
      end

      corridor_walls = []
      Geometry.get_finished_spaces(model, unit_spaces).each do |space|
          space.surfaces.each do |surface|
              next unless surface.surfaceType.downcase == "wall"
              next unless surface.adjacentSurface.is_initialized
              model.getSpaces.each do |potential_corridor_space|
                  next unless potential_corridor_space.name.to_s.include? Constants.CorridorSpace
                  potential_corridor_space.surfaces.each do |potential_corridor_surface|
                      next unless potential_corridor_surface.handle.to_s == surface.adjacentSurface.get.handle.to_s
                      corridor_walls << potential_corridor_surface
                  end
              end
          end 
      end

      unless corridor_walls.size == 0
        first_story_most_front_walls = corridor_walls
      end
      
      unit_has_door = true
      if first_story_most_front_walls.size == 0
          runner.registerWarning("For unit #{unit_num} could not find appropriate surface for the door. No door was added.")
          unit_has_door = false
      end

      door_sub_surface = nil
      first_story_most_front_walls.each do |first_story_front_wall|
      
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
        
        if (door_offset + door_width) * door_height > first_story_front_wall.grossArea
          # Reduce door offset to fit door on surface
          door_offset = 0
        end
        
        num_existing_doors_on_this_surface = 0
        first_story_front_wall.subSurfaces.each do |sub_surface|
          if sub_surface.subSurfaceType == "Door"
            num_existing_doors_on_this_surface += 1
          end
        end
        new_door_offset = door_offset + (door_offset + door_width) * num_existing_doors_on_this_surface

        door_sw_point = OpenStudio::Point3d.new(sw_point.x + new_door_offset, sw_point.y, sw_point.z)
        door_nw_point = OpenStudio::Point3d.new(sw_point.x + new_door_offset, sw_point.y, sw_point.z + door_height)
        door_ne_point = OpenStudio::Point3d.new(sw_point.x + new_door_offset + door_width, sw_point.y, sw_point.z + door_height)
        door_se_point = OpenStudio::Point3d.new(sw_point.x + new_door_offset + door_width, sw_point.y, sw_point.z)	
        
        if OpenStudio::getOutwardNormal(first_story_front_wall.vertices).get.y == 1 # doors facing in positive y direction
          door_polygon = Geometry.make_polygon(door_nw_point, door_ne_point, door_se_point, door_sw_point)
        else # doors facing in negative y direction
          door_polygon = Geometry.make_polygon(door_sw_point, door_se_point, door_ne_point, door_nw_point)
        end
        door_sub_surface = OpenStudio::Model::SubSurface.new(door_polygon, model)
        door_sub_surface.setName("Unit #{unit_num} - #{first_story_front_wall.name} - Front Door")
        door_sub_surface.setSubSurfaceType("Door")
        door_sub_surface.setSurface(first_story_front_wall)
        
        if first_story_front_wall.adjacentSurface.is_initialized
          adjacent_surface = first_story_front_wall.adjacentSurface.get
          adjacent_door_sub_surface = OpenStudio::Model::SubSurface.new(door_sub_surface.vertices.reverse, model)
          adjacent_door_sub_surface.setName("Unit #{unit_num} - #{first_story_front_wall.name} - Front Door Adjacent")
          adjacent_door_sub_surface.setSubSurfaceType("Door")
          adjacent_door_sub_surface.setSurface(adjacent_surface)
          door_sub_surface.setAdjacentSubSurface(adjacent_door_sub_surface)
        end
        
        added_door = true
      end

      if door_sub_surface.nil? and unit_has_door
          runner.registerWarning("For unit #{unit_num} could not find appropriate surface for the door. No door was added.")
      elsif not door_sub_surface.nil?
          runner.registerInfo("For unit #{unit_num} added #{OpenStudio::convert(door_area,"m^2","ft^2").get.round(1)} ft^2 door with name '#{door_sub_surface.name}'.")
      end
    
    end 
    
    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialDoorArea.new.registerWithApplication
