# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialDoorArea < OpenStudio::Ruleset::ModelUserScript

  def make_rectangle(pt1, pt2, pt3, pt4)
    p = OpenStudio::Point3dVector.new
    p << pt1
    p << pt2
	p << pt3
    p << pt4
    return p
  end

  # human readable name
  def name
    return "Set Residential Door Area"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for front door area
    userdefineddoorarea = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineddoorarea", true)
    userdefineddoorarea.setDisplayName("Door Area")
    userdefineddoorarea.setUnits("ft^2/unit")
    userdefineddoorarea.setDescription("The area of the front door.")
    userdefineddoorarea.setDefaultValue(20.0)
    args << userdefineddoorarea

    #make a choice argument for space
    spaces = model.getSpaces
    space_args = OpenStudio::StringVector.new
    spaces.each do |space|
        space_args << space.name.to_s
    end
    if not space_args.include?(Constants.LivingSpace(1))
        space_args << Constants.LivingSpace(1)
    end
    space = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space", space_args, true)
    space.setDisplayName("Location")
    space.setDescription("Select the space where the door area is located")
    space.setDefaultValue(Constants.LivingSpace(1))
    args << space

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
    space_r = runner.getStringArgumentValue("space",user_arguments)

    #Get space
    space = Geometry.get_space_from_string(model, space_r, runner)
    if space.nil?
        return false
    end

    space.surfaces.each do |surface|
      surface.subSurfaces.each do |sub_surface|
        if sub_surface.subSurfaceType == "Door"
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
      runner.registerInfo("No door added because door area was set to 0 ft^2/unit.")
      return true
    end    
    
    door_height = 2.1336 # 7 ft
    door_offset = 0.5

    # get building orientation
    building_orientation = model.getBuilding.northAxis.round
	
    # get the front wall on the first story
    first_story_front_wall = nil
    space.surfaces.each do |surface|
        next if not ( surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors" )
        # get surface azimuth to determine facade
        wall_azimuth = OpenStudio::Quantity.new(surface.azimuth, OpenStudio::createSIAngle)
        wall_orientation = (OpenStudio.convert(wall_azimuth, OpenStudio::createIPAngle).get.value + building_orientation).round			
        if wall_orientation - 180 == building_orientation
            first_story_front_wall = surface
            break
        end
    end
    
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
    
    door_polygon = make_rectangle(door_sw_point, door_se_point, door_ne_point, door_nw_point)
    
    door_sub_surface = OpenStudio::Model::SubSurface.new(door_polygon, model)
    door_sub_surface.setName("#{first_story_front_wall.name} - Front Door")
    door_sub_surface.setSubSurfaceType("Door")
    door_sub_surface.setSurface(first_story_front_wall)	

    runner.registerInfo("Added #{OpenStudio::convert(door_area,"m^2","ft^2").get.round(1)} ft^2/unit #{door_sub_surface.name}.")

    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialDoorArea.new.registerWithApplication
