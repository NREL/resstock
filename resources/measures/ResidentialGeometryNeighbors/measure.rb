# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialNeighbors < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Neighbors"
  end

  # human readable description
  def description
    return "Sets the neighbors (front, back, left, and/or right) of the building for shading purposes. Neighboring buildings will have the same geometry as the model building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Creates shading surfaces by shifting the building's exterior surfaces in the specified directions (front, back, left, and/or right)."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
	
    #make a double argument for left neighbor offset
    left_neighbor_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("left_offset", false)
    left_neighbor_offset.setDisplayName("Left Neighbor Offset")
    left_neighbor_offset.setUnits("ft")
    left_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the left (not including eaves). A value of zero indicates no neighbors.")
    left_neighbor_offset.setDefaultValue(10.0)
    args << left_neighbor_offset

    #make a double argument for right neighbor offset
    right_neighbor_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("right_offset", false)
    right_neighbor_offset.setDisplayName("Right Neighbor Offset")
    right_neighbor_offset.setUnits("ft")
    right_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the right (not including eaves). A value of zero indicates no neighbors.")
    right_neighbor_offset.setDefaultValue(10.0)
    args << right_neighbor_offset
	
    #make a double argument for back neighbor offset
    back_neighbor_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("back_offset", false)
    back_neighbor_offset.setDisplayName("Back Neighbor Offset")
    back_neighbor_offset.setUnits("ft")
    back_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the back (not including eaves). A value of zero indicates no neighbors.")
    back_neighbor_offset.setDefaultValue(0.0)
    args << back_neighbor_offset

    #make a double argument for front neighbor offset
    front_neighbor_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("front_offset", false)
    front_neighbor_offset.setDisplayName("Front Neighbor Offset")
    front_neighbor_offset.setUnits("ft")
    front_neighbor_offset.setDescription("The minimum distance between the simulated house and the neighboring house to the front (not including eaves). A value of zero indicates no neighbors.")
    front_neighbor_offset.setDefaultValue(0.0)
    args << front_neighbor_offset

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    left_neighbor_offset = OpenStudio::convert(runner.getDoubleArgumentValue("left_offset",user_arguments),"ft","m").get
    right_neighbor_offset = OpenStudio::convert(runner.getDoubleArgumentValue("right_offset",user_arguments),"ft","m").get
    back_neighbor_offset = OpenStudio::convert(runner.getDoubleArgumentValue("back_offset",user_arguments),"ft","m").get
    front_neighbor_offset = OpenStudio::convert(runner.getDoubleArgumentValue("front_offset",user_arguments),"ft","m").get
	
    if left_neighbor_offset < 0 or right_neighbor_offset < 0 or back_neighbor_offset < 0 or front_neighbor_offset < 0
      runner.registerError("Neighbor offsets must be greater than or equal to 0.")
      return false
    end
    
    least_x = 1000
    greatest_x = -1000
    least_y = 1000
    greatest_y = -1000
	
    surfaces = model.getSurfaces
    if surfaces.size == 0
      runner.registerAsNotApplicable("No surfaces found to copy for neighboring buildings.")
      return true
    end
    
    # remove existing neighbors
    remove_group = false
    model.getShadingSurfaceGroups.each do |shading_surface_group|
      shading_surface_group.shadingSurfaces.each do |shading_surface|
        next unless shading_surface.name.to_s.downcase.include? "neighbor"
        remove_group = true
      end
      if remove_group
        shading_surface_group.remove
      end
    end
    if remove_group
      runner.registerInfo("Removed existing neighbors.")
    end
    
    if [left_neighbor_offset, right_neighbor_offset, back_neighbor_offset, front_neighbor_offset].all? {|offset| offset == 0}
      runner.registerAsNotApplicable("No neighbors to be added.")
      return true
    end
    
    # get x and y minima and maxima of wall surfaces
    surfaces.each do |surface|
      if surface.surfaceType.downcase == "wall"
        vertices = surface.vertices
        vertices.each do |vertex|
          if vertex.x > greatest_x
            greatest_x = vertex.x
          end
          if vertex.x < least_x
            least_x = vertex.x
          end
          if vertex.y > greatest_y
            greatest_y = vertex.y
          end
          if vertex.y < least_y
            least_y = vertex.y
          end
        end
      end
    end
	    
    # this is maximum building length or width + user specified neighbor offset
    left_offset = ((greatest_x - least_x) + left_neighbor_offset)
    right_offset = -((greatest_x - least_x) + right_neighbor_offset)
    back_offset = -((greatest_y - least_y) + back_neighbor_offset)
    front_offset = ((greatest_y - least_y) + front_neighbor_offset)
			
    directions = [[Constants.FacadeLeft, left_neighbor_offset, left_offset, 0], [Constants.FacadeRight, right_neighbor_offset, right_offset, 0], [Constants.FacadeBack, back_neighbor_offset, 0, back_offset], [Constants.FacadeFront, front_neighbor_offset, 0, front_offset]]
            
    shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
    directions.each do |dir, neighbor_offset, x_offset, y_offset|
      if neighbor_offset != 0
        model.getSpaces.each do |space|
          space.surfaces.each do |surface|
            next if surface.outsideBoundaryCondition.downcase != "outdoors" and surface.outsideBoundaryCondition.downcase != "adiabatic"
            next if surface.adjacentSurface.is_initialized
            if surface.outsideBoundaryCondition.downcase == "adiabatic" and !space.name.to_s.downcase.include? Constants.CorridorSpace
              next
            end
            m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
            m[0,3] = -x_offset
            m[1,3] = -y_offset
            m[2,3] = space.zOrigin
            transformation = OpenStudio::Transformation.new(m)
            new_vertices = transformation * surface.vertices
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_vertices, model)
            shading_surface.setName("#{dir} Neighbor")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            runner.registerInfo("Created shading surface #{shading_surface.name} from #{surface.name}.")
          end        
        end
        model.getShadingSurfaces.each do |existing_shading_surface|
          next unless existing_shading_surface.name.to_s.downcase.include? "eaves"
          m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m[0,3] = -x_offset
          m[1,3] = -y_offset
          transformation = OpenStudio::Transformation.new(m)
          new_vertices = transformation * existing_shading_surface.vertices
          shading_surface = OpenStudio::Model::ShadingSurface.new(new_vertices, model)
          shading_surface.setName("#{dir} Neighbor")
          shading_surface.setShadingSurfaceGroup(shading_surface_group)
          runner.registerInfo("Created shading surface #{shading_surface.name} from #{existing_shading_surface.name}.")	            
        end
      end
    end     

    return true

  end
  
end

# register the measure to be used by the application
CreateResidentialNeighbors.new.registerWithApplication
