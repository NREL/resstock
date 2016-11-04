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
    return "Sets the opaque door area for the building. Doors with glazing should be set as window area. For multifamily buildings, door area can be set for all units of the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets the opaque door area for the lowest above-grade front surface attached to living space. Any existing doors are removed. For multifamily buildings, doors are placed on corridor walls if available."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for door area
    door_area = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("door_area", true)
    door_area.setDisplayName("Door Area")
    door_area.setUnits("ft^2")
    door_area.setDescription("The area of the opaque door(s). For multifamily buildings, applies to each unit.")
    door_area.setDefaultValue(20.0)
    args << door_area

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    door_area = runner.getDoubleArgumentValue("door_area",user_arguments)
    
    model.getSubSurfaces.each do |sub_surface|
        next if sub_surface.subSurfaceType.downcase != "door"
        runner.registerInfo("Removed door(s) from #{sub_surface.surface.get.name}.")
        sub_surface.remove
    end
    
    # error checking
    if door_area < 0
      runner.registerError("Invalid door area.")
      return false
    elsif door_area == 0
      runner.registerFinalCondition("No doors added because door area was set to 0.")
      return true
    end    
    
    door_height = 7 # ft
    door_width = door_area / door_height
    door_offset = 0.5 # ft

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
  
    tot_door_area = 0
    units.each do |unit|
  
      # Get all exterior walls prioritized by front, then back, then left, then right
      facades = [Constants.FacadeFront, Constants.FacadeBack]
      avail_walls = []
      facades.each do |facade|
          Geometry.get_finished_spaces(unit.spaces).each do |space|
              next if Geometry.space_is_below_grade(space)
              space.surfaces.each do |surface|
                  next if Geometry.get_facade_for_surface(surface) != facade
                  next if surface.outsideBoundaryCondition.downcase != "outdoors"
                  avail_walls << surface
              end
          end
          break if avail_walls.size > 0
      end

      # Get subset of exterior walls on lowest story
      min_story_avail_walls = []
      min_story_avail_wall_minz = 99999
      avail_walls.each do |avail_wall|
          zvalues = Geometry.getSurfaceZValues([avail_wall])
          minz = zvalues.min + avail_wall.space.get.zOrigin
          if minz < min_story_avail_wall_minz
              min_story_avail_walls.clear
              min_story_avail_walls << avail_wall
              min_story_avail_wall_minz = minz
          elsif (minz - min_story_avail_wall_minz).abs < 0.001
              min_story_avail_walls << avail_wall
          end
      end

      # Get all corridor walls
      corridor_walls = []
      Geometry.get_finished_spaces(unit.spaces).each do |space|
          space.surfaces.each do |surface|
              next unless surface.surfaceType.downcase == "wall"
              next unless surface.outsideBoundaryCondition.downcase == "adiabatic"
              model.getSpaces.each do |potential_corridor_space|
                  next unless potential_corridor_space.name.to_s.include? Constants.CorridorSpace
                  potential_corridor_space.surfaces.each do |potential_corridor_surface|
                      next unless surface.reverseEqualVertices(potential_corridor_surface)
                      corridor_walls << potential_corridor_surface
                  end
              end
          end 
      end

      # Get subset of corridor walls on lowest story
      min_story_corridor_walls = []
      min_story_corridor_wall_minz = 99999
      corridor_walls.each do |corridor_wall|
          zvalues = Geometry.getSurfaceZValues([corridor_wall])
          minz = zvalues.min + corridor_wall.space.get.zOrigin
          if minz < min_story_corridor_wall_minz
              min_story_corridor_walls.clear
              min_story_corridor_walls << corridor_wall
              min_story_corridor_wall_minz = minz
          elsif (minz - min_story_corridor_wall_minz).abs < 0.001
              min_story_corridor_walls << corridor_wall
          end
      end      
      
      # Prioritize corridor surfaces if available
      unless min_story_corridor_walls.size == 0
        min_story_avail_walls = min_story_corridor_walls
      end
      
      unit_has_door = true
      if min_story_avail_walls.size == 0
          runner.registerWarning("For #{unit.name.to_s}, could not find appropriate surface for the door. No door was added.")
          unit_has_door = false
      end

      door_sub_surface = nil
      min_story_avail_walls.each do |min_story_avail_wall|
      
        wall_gross_area = OpenStudio.convert(min_story_avail_wall.grossArea, "m^2", "ft^2").get
        
        # Try to place door on any surface with enough area
        next if door_area >= wall_gross_area
        
        facade = Geometry.get_facade_for_surface(min_story_avail_wall)

        if (door_offset + door_width) * door_height > wall_gross_area
          # Reduce door offset to fit door on surface
          door_offset = 0
        end
        
        num_existing_doors_on_this_surface = 0
        min_story_avail_wall.subSurfaces.each do |sub_surface|
          if sub_surface.subSurfaceType.downcase == "door"
            num_existing_doors_on_this_surface += 1
          end
        end
        new_door_offset = door_offset + (door_offset + door_width) * num_existing_doors_on_this_surface
        
        # Create door vertices in relative coordinates
        gap = 0.001 # Prevents E+ warning "Base Surface does not surround subsurface errors occuring"
        upperleft = [new_door_offset, door_height]
        upperright = [new_door_offset + door_width, door_height]
        lowerright = [new_door_offset + door_width, gap]
        lowerleft = [new_door_offset, gap]
        
        # Convert to 3D geometry; assign to surface
        door_polygon = OpenStudio::Point3dVector.new
        if facade == Constants.FacadeFront
            multx = 1
            multy = 0
        elsif facade == Constants.FacadeBack
            multx = -1
            multy = 0
        elsif facade == Constants.FacadeLeft
            multx = 0
            multy = -1
        elsif facade == Constants.FacadeRight
            multx = 0
            multy = 1
        end
        if facade == Constants.FacadeBack or facade == Constants.FacadeLeft
            leftx = Geometry.getSurfaceXValues([min_story_avail_wall]).max
            lefty = Geometry.getSurfaceYValues([min_story_avail_wall]).max
        else
            leftx = Geometry.getSurfaceXValues([min_story_avail_wall]).min
            lefty = Geometry.getSurfaceYValues([min_story_avail_wall]).min
        end
        bottomz = Geometry.getSurfaceZValues([min_story_avail_wall]).min
        
        [upperleft, lowerleft, lowerright, upperright ].each do |coord|
            newx = OpenStudio.convert(leftx + multx * coord[0], "ft", "m").get
            newy = OpenStudio.convert(lefty + multy * coord[0], "ft", "m").get
            newz = OpenStudio.convert(bottomz + coord[1], "ft", "m").get
            door_vertex = OpenStudio::Point3d.new(newx, newy, newz)
            door_polygon << door_vertex
        end

        door_sub_surface = OpenStudio::Model::SubSurface.new(door_polygon, model)
        door_sub_surface.setName("#{unit.name.to_s} - #{min_story_avail_wall.name} - Door")
        door_sub_surface.setSubSurfaceType("Door")
        door_sub_surface.setSurface(min_story_avail_wall)
        
        tot_door_area += door_area
        break
      end

      if door_sub_surface.nil? and unit_has_door
          runner.registerWarning("For #{unit.name.to_s} could not find appropriate surface for the door. No door was added.")
      elsif not door_sub_surface.nil?
          runner.registerInfo("For #{unit.name.to_s} added #{door_area.round(1)} ft^2 door.")
      end
    
    end 
    
    runner.registerFinalCondition("The building has been assigned #{tot_door_area.round(1)} ft^2 total door area.")
    
    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialDoorArea.new.registerWithApplication
