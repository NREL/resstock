# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

# start the measure
class CreateResidentialEaves < OpenStudio::Ruleset::ModelUserScript
  
  # human readable name
  def name
    return "Set Residential Eaves"
  end

  # human readable description
  def description
    return "Sets the eaves for the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Performs a series of affine transformations on the roof decks into shading surfaces."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make a choice argument for model objects
    roof_structure_display_names = OpenStudio::StringVector.new
    roof_structure_display_names << Constants.RoofStructureTrussCantilever
    roof_structure_display_names << Constants.RoofStructureRafter
	
    #make a choice argument for roof type
    roof_structure = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("roof_structure", roof_structure_display_names, true)
    roof_structure.setDisplayName("Roof Structure")
    roof_structure.setDescription("The roof structure of the building.")
    roof_structure.setDefaultValue(Constants.RoofStructureTrussCantilever)
    args << roof_structure	
	
    #make a choice argument for eaves depth
    eaves_depth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("eaves_depth", true)
    eaves_depth.setDisplayName("Eaves Depth")
    eaves_depth.setUnits("ft")
    eaves_depth.setDescription("The eaves depth of the roof.")
    eaves_depth.setDefaultValue(2.0)
    args << eaves_depth 
  
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    roof_structure = runner.getStringArgumentValue("roof_structure",user_arguments)
    eaves_depth = OpenStudio.convert(runner.getDoubleArgumentValue("eaves_depth",user_arguments),"ft","m").get

    # remove existing eaves
    existing_eaves_depth = nil
    model.getShadingSurfaceGroups.each do |shading_surface_group|
      shading_surface_group.shadingSurfaces.each do |shading_surface|
        next unless shading_surface.name.to_s.downcase.include? "eaves"
        next unless existing_eaves_depth.nil?
        existing_eaves_depth = get_existing_eaves_depth(shading_surface)
      end
      shading_surface_group.remove
    end
    if existing_eaves_depth.nil?
      existing_eaves_depth = 0
    else
      runner.registerInfo("Removed existing eaves.")
    end
    
    roof_type = determine_roof_type(model.getSurfaces)
    
    surfaces_modified = false
    
    case roof_type
    when Constants.RoofTypeGable

      attic_increase_existing = Geometry.get_roof_pitch(model.getSurfaces) * existing_eaves_depth
      attic_increase_new = Geometry.get_roof_pitch(model.getSurfaces) * eaves_depth      
      attic_increase_delta = attic_increase_new - attic_increase_existing
      
      model.getSurfaces.each do |surface|
        if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors" # roof decks
        elsif surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors" and surface.vertices.length == 3 # attic walls
        elsif surface.surfaceType.downcase == "roofceiling" and surface.vertices.length == 3 # wall between living and garage attics
        elsif surface.surfaceType.downcase == "wall" and surface.adjacentSurface.is_initialized and surface.vertices.length == 3 # wall between living and garage attics
        else
          next
        end
        surfaces_modified = true
        
        # Truss, Cantilever
        if roof_structure == Constants.RoofStructureTrussCantilever
        
          # Roof Decks
          if surface.surfaceType.downcase == "roofceiling" or ( surface.surfaceType.downcase == "wall" and surface.adjacentSurface.is_initialized and surface.vertices.length == 3 ) # roof decks and wall between living and garage attics
            # raise the roof decks
            m = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
            m[2,3] = attic_increase_delta
            transformation = OpenStudio::Transformation.new(m)
            vertices = surface.vertices
            new_vertices = transformation * vertices
            surface.setVertices(new_vertices)

          # Attic Walls
          elsif surface.surfaceType.downcase == "wall" and not surface.adjacentSurface.is_initialized # attic walls
            # raise the attic walls
            x_s = []
            y_s = []
            z_s = []
            vertices = surface.vertices
            vertices.each do |vertex|
              x_s << vertex.x
              y_s << vertex.y
              z_s << vertex.z
            end
            max_z = z_s.each_with_index.max
            top_pt = OpenStudio::Point3d.new(x_s[max_z[1]], y_s[max_z[1]], z_s[max_z[1]] + attic_increase_delta)
            if x_s.uniq.size == 1 # orientation of this wall is along y-axis
              if top_pt.x == 0
                min_y = y_s.each_with_index.min
                max_y = y_s.each_with_index.max
                max_pt = OpenStudio::Point3d.new(x_s[min_y[1]], y_s[min_y[1]] - eaves_depth + existing_eaves_depth, z_s[min_y[1]])
                min_pt = OpenStudio::Point3d.new(x_s[max_y[1]], y_s[max_y[1]] + eaves_depth - existing_eaves_depth, z_s[max_y[1]])
              else
                min_y = y_s.each_with_index.min
                max_y = y_s.each_with_index.max
                min_pt = OpenStudio::Point3d.new(x_s[min_y[1]], y_s[min_y[1]] - eaves_depth + existing_eaves_depth, z_s[min_y[1]])
                max_pt = OpenStudio::Point3d.new(x_s[max_y[1]], y_s[max_y[1]] + eaves_depth - existing_eaves_depth, z_s[max_y[1]])              
              end
            else # orientation of this wall is along the x-axis
              if top_pt.y == 0
                min_x = x_s.each_with_index.min
                max_x = x_s.each_with_index.max
                min_pt = OpenStudio::Point3d.new(x_s[min_x[1]] - eaves_depth + existing_eaves_depth, y_s[min_x[1]], z_s[min_x[1]])
                max_pt = OpenStudio::Point3d.new(x_s[max_x[1]] + eaves_depth - existing_eaves_depth, y_s[max_x[1]], z_s[max_x[1]])						
              else
                min_x = x_s.each_with_index.min
                max_x = x_s.each_with_index.max
                min_pt = OpenStudio::Point3d.new(x_s[min_x[1]] - eaves_depth + existing_eaves_depth, y_s[min_x[1]], z_s[min_x[1]])
                max_pt = OpenStudio::Point3d.new(x_s[max_x[1]] + eaves_depth - existing_eaves_depth, y_s[max_x[1]], z_s[max_x[1]])
              end
            end
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << top_pt
            new_vertices << min_pt
            new_vertices << max_pt
            surface.setVertices(new_vertices)
       
          end
          
        end
                
        # Eaves
        if surface.surfaceType.downcase == "roofceiling" and surface.vertices.length > 3
          new_surface = surface.clone.to_Surface.get
          z_offset = surface.space.get.zOrigin # shift the z coordinates of the vertices up by the z origin of the space
          m_left_lower_out = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_mid_out = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_mid_in = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_upper_out = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_upper_in = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_lower_out = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_mid_out = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_mid_in = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_upper_out = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_upper_in = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          slope_dir, lower_pts, upper_pts = get_slope_direction_and_lower_points(surface)

          if slope_dir == "neg_y"
            if lower_pts[0].x < lower_pts[1].x
              left_lower = lower_pts[0]
              right_lower = lower_pts[1]
            else
              left_lower = lower_pts[1]
              right_lower = lower_pts[0]
            end
            if upper_pts[0].x < upper_pts[1].x
              left_upper = upper_pts[0]
              right_upper = upper_pts[1]
            else
              left_upper = upper_pts[1]
              right_upper = upper_pts[0]
            end            

            m_left_lower_out[0,3] = -eaves_depth
            m_left_lower_out[1,3] = -eaves_depth
            m_left_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_left_mid_out[0,3] = -eaves_depth
            m_left_mid_out[1,3] = 0
            m_left_mid_out[2,3] = z_offset            
            
            m_left_mid_in[0,3] = 0
            m_left_mid_in[1,3] = 0
            m_left_mid_in[2,3] = z_offset
            
            m_left_upper_out[0,3] = -eaves_depth
            m_left_upper_out[1,3] = 0
            m_left_upper_out[2,3] = z_offset
            
            m_left_upper_in[0,3] = 0
            m_left_upper_in[1,3] = 0
            m_left_upper_in[2,3] = z_offset            

            m_right_lower_out[0,3] = eaves_depth
            m_right_lower_out[1,3] = -eaves_depth
            m_right_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_right_mid_out[0,3] = eaves_depth
            m_right_mid_out[1,3] = 0
            m_right_mid_out[2,3] = z_offset            
            
            m_right_mid_in[0,3] = 0
            m_right_mid_in[1,3] = 0
            m_right_mid_in[2,3] = z_offset             
            
            m_right_upper_out[0,3] = eaves_depth
            m_right_upper_out[1,3] = 0
            m_right_upper_out[2,3] = z_offset
            
            m_right_upper_in[0,3] = 0
            m_right_upper_in[1,3] = 0
            m_right_upper_in[2,3] = z_offset            
                        
            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
                        
            # lower eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_lower_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_left_lower_out) * left_lower
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            # left eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_upper_out) * left_upper
            new_vertices << OpenStudio::Transformation.new(m_left_upper_in) * left_upper
            new_vertices << OpenStudio::Transformation.new(m_left_mid_in) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
            # right eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_right_upper_out) * right_upper
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_in) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_upper_in) * right_upper
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)            

            new_surface.remove
          elsif slope_dir == "pos_y"
            if lower_pts[0].x < lower_pts[1].x
              left_lower = lower_pts[0]
              right_lower = lower_pts[1]
            else
              left_lower = lower_pts[1]
              right_lower = lower_pts[0]
            end
            if upper_pts[0].x < upper_pts[1].x
              left_upper = upper_pts[0]
              right_upper = upper_pts[1]
            else
              left_upper = upper_pts[1]
              right_upper = upper_pts[0]
            end            

            m_left_lower_out[0,3] = -eaves_depth
            m_left_lower_out[1,3] = eaves_depth
            m_left_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_left_mid_out[0,3] = -eaves_depth
            m_left_mid_out[1,3] = 0
            m_left_mid_out[2,3] = z_offset            
            
            m_left_mid_in[0,3] = 0
            m_left_mid_in[1,3] = 0
            m_left_mid_in[2,3] = z_offset              
            
            m_left_upper_out[0,3] = -eaves_depth
            m_left_upper_out[1,3] = 0
            m_left_upper_out[2,3] = z_offset
            
            m_left_upper_in[0,3] = 0
            m_left_upper_in[1,3] = 0
            m_left_upper_in[2,3] = z_offset            

            m_right_lower_out[0,3] = eaves_depth
            m_right_lower_out[1,3] = eaves_depth
            m_right_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_right_mid_out[0,3] = eaves_depth
            m_right_mid_out[1,3] = 0
            m_right_mid_out[2,3] = z_offset            
            
            m_right_mid_in[0,3] = 0
            m_right_mid_in[1,3] = 0
            m_right_mid_in[2,3] = z_offset             
            
            m_right_upper_out[0,3] = eaves_depth
            m_right_upper_out[1,3] = 0
            m_right_upper_out[2,3] = z_offset
            
            m_right_upper_in[0,3] = 0
            m_right_upper_in[1,3] = 0
            m_right_upper_in[2,3] = z_offset
                        
            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
                        
            # lower eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_lower_out) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_right_lower_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            # left eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_left_mid_in) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_left_upper_in) * left_upper
            new_vertices << OpenStudio::Transformation.new(m_left_upper_out) * left_upper
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
            # right eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_right_upper_in) * right_upper
            new_vertices << OpenStudio::Transformation.new(m_right_mid_in) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_upper_out) * right_upper
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)            

            new_surface.remove
          elsif slope_dir == "neg_x"
            if lower_pts[0].y > lower_pts[1].y
              left_lower = lower_pts[0]
              right_lower = lower_pts[1]
            else
              left_lower = lower_pts[1]
              right_lower = lower_pts[0]
            end
            if upper_pts[0].y > upper_pts[1].y
              left_upper = upper_pts[0]
              right_upper = upper_pts[1]
            else
              left_upper = upper_pts[1]
              right_upper = upper_pts[0]
            end            

            m_left_lower_out[0,3] = -eaves_depth
            m_left_lower_out[1,3] = eaves_depth
            m_left_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_left_mid_out[0,3] = 0
            m_left_mid_out[1,3] = eaves_depth
            m_left_mid_out[2,3] = z_offset            
            
            m_left_mid_in[0,3] = 0
            m_left_mid_in[1,3] = 0
            m_left_mid_in[2,3] = z_offset              
            
            m_left_upper_out[0,3] = 0
            m_left_upper_out[1,3] = eaves_depth
            m_left_upper_out[2,3] = z_offset
            
            m_left_upper_in[0,3] = 0
            m_left_upper_in[1,3] = 0
            m_left_upper_in[2,3] = z_offset            

            m_right_lower_out[0,3] = -eaves_depth
            m_right_lower_out[1,3] = -eaves_depth
            m_right_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_right_mid_out[0,3] = 0
            m_right_mid_out[1,3] = -eaves_depth
            m_right_mid_out[2,3] = z_offset            
            
            m_right_mid_in[0,3] = 0
            m_right_mid_in[1,3] = 0
            m_right_mid_in[2,3] = z_offset             
            
            m_right_upper_out[0,3] = 0
            m_right_upper_out[1,3] = -eaves_depth
            m_right_upper_out[2,3] = z_offset
            
            m_right_upper_in[0,3] = 0
            m_right_upper_in[1,3] = 0
            m_right_upper_in[2,3] = z_offset            
                      
            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
                      
            # lower eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_lower_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_left_lower_out) * left_lower
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            # left eave
            unless surface.space.get.name.to_s.downcase.include? "garage"
              new_vertices = OpenStudio::Point3dVector.new
              new_vertices << OpenStudio::Transformation.new(m_left_upper_out) * left_upper
              new_vertices << OpenStudio::Transformation.new(m_left_upper_in) * left_upper
              new_vertices << OpenStudio::Transformation.new(m_left_mid_in) * left_lower
              new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
              new_surface.setVertices(new_vertices)		
              shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
              shading_surface.setName("eaves")
              shading_surface.setShadingSurfaceGroup(shading_surface_group)
            end
            
            # right eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_right_upper_out) * right_upper
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_in) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_upper_in) * right_upper
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)            

            new_surface.remove           
          elsif slope_dir == "pos_x"
            if lower_pts[0].y > lower_pts[1].y
              left_lower = lower_pts[0]
              right_lower = lower_pts[1]
            else
              left_lower = lower_pts[1]
              right_lower = lower_pts[0]
            end
            if upper_pts[0].y > upper_pts[1].y
              left_upper = upper_pts[0]
              right_upper = upper_pts[1]
            else
              left_upper = upper_pts[1]
              right_upper = upper_pts[0]
            end            

            m_left_lower_out[0,3] = eaves_depth
            m_left_lower_out[1,3] = eaves_depth
            m_left_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_left_mid_out[0,3] = 0
            m_left_mid_out[1,3] = eaves_depth
            m_left_mid_out[2,3] = z_offset            
            
            m_left_mid_in[0,3] = 0
            m_left_mid_in[1,3] = 0
            m_left_mid_in[2,3] = z_offset              
            
            m_left_upper_out[0,3] = 0
            m_left_upper_out[1,3] = eaves_depth
            m_left_upper_out[2,3] = z_offset
            
            m_left_upper_in[0,3] = 0
            m_left_upper_in[1,3] = 0
            m_left_upper_in[2,3] = z_offset            

            m_right_lower_out[0,3] = eaves_depth
            m_right_lower_out[1,3] = -eaves_depth
            m_right_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_right_mid_out[0,3] = 0
            m_right_mid_out[1,3] = -eaves_depth
            m_right_mid_out[2,3] = z_offset            
            
            m_right_mid_in[0,3] = 0
            m_right_mid_in[1,3] = 0
            m_right_mid_in[2,3] = z_offset             
            
            m_right_upper_out[0,3] = 0
            m_right_upper_out[1,3] = -eaves_depth
            m_right_upper_out[2,3] = z_offset
            
            m_right_upper_in[0,3] = 0
            m_right_upper_in[1,3] = 0
            m_right_upper_in[2,3] = z_offset            
                        
            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
                        
            # lower eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_lower_out) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_right_lower_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            # left eave
            unless surface.space.get.name.to_s.downcase.include? "garage"
              new_vertices = OpenStudio::Point3dVector.new
              new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
              new_vertices << OpenStudio::Transformation.new(m_left_mid_in) * left_lower
              new_vertices << OpenStudio::Transformation.new(m_left_upper_in) * left_upper
              new_vertices << OpenStudio::Transformation.new(m_left_upper_out) * left_upper
              new_surface.setVertices(new_vertices)		
              shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
              shading_surface.setName("eaves")
              shading_surface.setShadingSurfaceGroup(shading_surface_group)
            end
            
            # right eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_right_upper_in) * right_upper
            new_vertices << OpenStudio::Transformation.new(m_right_mid_in) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_upper_out) * right_upper
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            new_surface.remove
          end
          
        end
        
      end
     
    when Constants.RoofTypeFlat
    
      model.getSurfaces.each do |surface|
        next unless surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
        surfaces_modified = true
        if surface.vertices.length == 4
      
          attic_length, attic_width, attic_height = Geometry.get_surface_dimensions(surface)
        
          new_surface_left = surface.clone.to_Surface.get
          new_surface_right = surface.clone.to_Surface.get
          new_surface_bottom = surface.clone.to_Surface.get
          new_surface_top = surface.clone.to_Surface.get
          vertices = new_surface_left.vertices
          z_offset = surface.space.get.zOrigin # shift the z coordinates of the vertices up by the z origin of the space
          
          m_left_far = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_close = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_far[0,3] = -attic_length
          m_left_far[2,3] = z_offset
          m_left_close[0,3] = -eaves_depth
          m_left_close[2,3] = z_offset
          
          m_right_far = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_close = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_far[0,3] = attic_length
          m_right_far[2,3] = z_offset
          m_right_close[0,3] = eaves_depth
          m_right_close[2,3] = z_offset          
          
          m_bottom_far_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_bottom_far_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_bottom_close_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_bottom_close_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_bottom_far_left[0,3] = -eaves_depth
          m_bottom_far_left[1,3] = -attic_width
          m_bottom_far_left[2,3] = z_offset
          m_bottom_far_right[0,3] = eaves_depth
          m_bottom_far_right[1,3] = -attic_width
          m_bottom_far_right[2,3] = z_offset          
          m_bottom_close_left[0,3] = -eaves_depth
          m_bottom_close_left[1,3] = -eaves_depth
          m_bottom_close_left[2,3] = z_offset
          m_bottom_close_right[0,3] = eaves_depth
          m_bottom_close_right[1,3] = -eaves_depth
          m_bottom_close_right[2,3] = z_offset          
          
          m_top_far_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_top_far_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_top_close_left = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_top_close_right = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_top_far_left[0,3] = -eaves_depth
          m_top_far_left[1,3] = attic_width
          m_top_far_left[2,3] = z_offset
          m_top_far_right[0,3] = eaves_depth
          m_top_far_right[1,3] = attic_width
          m_top_far_right[2,3] = z_offset
          m_top_close_left[0,3] = -eaves_depth          
          m_top_close_left[1,3] = eaves_depth
          m_top_close_left[2,3] = z_offset
          m_top_close_right[0,3] = eaves_depth          
          m_top_close_right[1,3] = eaves_depth
          m_top_close_right[2,3] = z_offset          
          
          transformation_left_far = OpenStudio::Transformation.new(m_left_far)
          transformation_left_close = OpenStudio::Transformation.new(m_left_close)
          
          transformation_right_far = OpenStudio::Transformation.new(m_right_far)
          transformation_right_close = OpenStudio::Transformation.new(m_right_close)          
          
          transformation_bottom_far_left = OpenStudio::Transformation.new(m_bottom_far_left)
          transformation_bottom_far_right = OpenStudio::Transformation.new(m_bottom_far_right)
          transformation_bottom_close_left = OpenStudio::Transformation.new(m_bottom_close_left)
          transformation_bottom_close_right = OpenStudio::Transformation.new(m_bottom_close_right)
          
          transformation_top_far_left = OpenStudio::Transformation.new(m_top_far_left)
          transformation_top_far_right = OpenStudio::Transformation.new(m_top_far_right)
          transformation_top_close_left = OpenStudio::Transformation.new(m_top_close_left)
          transformation_top_close_right = OpenStudio::Transformation.new(m_top_close_right)

          if vertices[0].x < vertices[1].x
            top_left = vertices[3]
            top_right = vertices[2]
            bottom_right = vertices[1]
            bottom_left = vertices[0]
          elsif vertices[1].x < vertices[0].x
            top_left = vertices[1]
            top_right = vertices[0]
            bottom_right = vertices[3]
            bottom_left = vertices[2]            
          elsif vertices[0].x < vertices[3].x
            top_left = vertices[0]
            top_right = vertices[3]
            bottom_right = vertices[2]
            bottom_left = vertices[1]
          elsif vertices[3].x < vertices[0].x
            top_left = vertices[2]
            top_right = vertices[1]
            bottom_right = vertices[0]
            bottom_left = vertices[3]            
          end
          
          new_vertices_left = OpenStudio::Point3dVector.new
          new_vertices_left << transformation_left_far * top_right
          new_vertices_left << transformation_left_far * bottom_right
          new_vertices_left << transformation_left_close * bottom_left
          new_vertices_left << transformation_left_close * top_left               
          
          shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
          
          new_surface_left.setVertices(new_vertices_left)
          shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_left.vertices, model)
          shading_surface.setName("eaves")
          shading_surface.setShadingSurfaceGroup(shading_surface_group)								
          new_surface_left.remove

          new_vertices_right = OpenStudio::Point3dVector.new
          new_vertices_right << transformation_right_far * top_left
          new_vertices_right << transformation_right_close * top_right
          new_vertices_right << transformation_right_close * bottom_right          
          new_vertices_right << transformation_right_far * bottom_left
          
          new_surface_right.setVertices(new_vertices_right)		
          shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_right.vertices, model)
          shading_surface.setName("eaves")
          shading_surface.setShadingSurfaceGroup(shading_surface_group)								
          new_surface_right.remove

          new_vertices_bottom = OpenStudio::Point3dVector.new
          new_vertices_bottom << transformation_bottom_far_left * top_left
          new_vertices_bottom << transformation_bottom_far_right * top_right
          new_vertices_bottom << transformation_bottom_close_right * bottom_right
          new_vertices_bottom << transformation_bottom_close_left * bottom_left
          
          new_surface_bottom.setVertices(new_vertices_bottom)		
          shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_bottom.vertices, model)
          shading_surface.setName("eaves")
          shading_surface.setShadingSurfaceGroup(shading_surface_group)								
          new_surface_bottom.remove
          
          new_vertices_top = OpenStudio::Point3dVector.new
          new_vertices_top << transformation_top_far_left * bottom_left
          new_vertices_top << transformation_top_close_left * top_left
          new_vertices_top << transformation_top_close_right * top_right
          new_vertices_top << transformation_top_far_right * bottom_right
          
          new_surface_top.setVertices(new_vertices_top)		
          shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_top.vertices, model)
          shading_surface.setName("eaves")
          shading_surface.setShadingSurfaceGroup(shading_surface_group)								
          new_surface_top.remove
        
        else # has garage
          # TODO: one-story flat roof with garage
        end
        
      end
    
    when Constants.RoofTypeHip
    
      attic_increase_existing = Geometry.get_roof_pitch(model.getSurfaces) * existing_eaves_depth
      attic_increase_new = Geometry.get_roof_pitch(model.getSurfaces) * eaves_depth
      attic_increase_delta = attic_increase_new - attic_increase_existing    
      
      model.getSurfaces.each do |surface|
        next unless surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"      
        surfaces_modified = true
        
        # Truss, Cantilever
        if roof_structure == Constants.RoofStructureTrussCantilever
        
          # Roof Decks
          
          # raise the roof decks
          m = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m[2,3] = attic_increase_delta
          transformation = OpenStudio::Transformation.new(m)
          vertices = surface.vertices
          new_vertices = transformation * vertices
          surface.setVertices(new_vertices)
                    
        end  
        
        # Eaves
        if surface.surfaceType.downcase == "roofceiling"
          new_surface = surface.clone.to_Surface.get
          z_offset = surface.space.get.zOrigin # shift the z coordinates of the vertices up by the z origin of the space
          m_left_lower = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_upper = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_lower = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_upper = initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          slope_dir, lower_pts = get_slope_direction_and_lower_points(surface)
          
          if slope_dir == "neg_y"
            if lower_pts[0].x < lower_pts[1].x
              left = lower_pts[0]
              right = lower_pts[1]
            else
              left = lower_pts[1]
              right = lower_pts[0]
            end
            
            m_left_lower[0,3] = -eaves_depth 
            m_left_lower[1,3] = -eaves_depth
            m_left_lower[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_left_upper[0,3] = 0
            m_left_upper[1,3] = 0
            m_left_upper[2,3] = z_offset

            m_right_lower[0,3] = eaves_depth
            m_right_lower[1,3] = -eaves_depth
            m_right_lower[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_right_upper[0,3] = 0
            m_right_upper[1,3] = 0
            m_right_upper[2,3] = z_offset     
                        
            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
                        
            transformation_left_lower = OpenStudio::Transformation.new(m_left_lower)
            transformation_left_upper = OpenStudio::Transformation.new(m_left_upper)
            transformation_right_lower = OpenStudio::Transformation.new(m_right_lower)
            transformation_right_upper = OpenStudio::Transformation.new(m_right_upper)
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << transformation_left_lower * left
            new_vertices << transformation_left_upper * left
            new_vertices << transformation_right_upper * right
            new_vertices << transformation_right_lower * right
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)								
            new_surface.remove
            
          elsif slope_dir == "pos_y"
            if lower_pts[0].x < lower_pts[1].x
              left = lower_pts[1]
              right = lower_pts[0]
            else
              left = lower_pts[0]
              right = lower_pts[1]
            end
            
            m_left_lower[0,3] = eaves_depth 
            m_left_lower[1,3] = eaves_depth
            m_left_lower[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_left_upper[0,3] = 0
            m_left_upper[1,3] = 0
            m_left_upper[2,3] = z_offset

            m_right_lower[0,3] = -eaves_depth
            m_right_lower[1,3] = eaves_depth
            m_right_lower[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_right_upper[0,3] = 0
            m_right_upper[1,3] = 0
            m_right_upper[2,3] = z_offset     
                        
            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
                        
            transformation_left_lower = OpenStudio::Transformation.new(m_left_lower)
            transformation_left_upper = OpenStudio::Transformation.new(m_left_upper)
            transformation_right_lower = OpenStudio::Transformation.new(m_right_lower)
            transformation_right_upper = OpenStudio::Transformation.new(m_right_upper)
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << transformation_left_lower * left
            new_vertices << transformation_left_upper * left
            new_vertices << transformation_right_upper * right
            new_vertices << transformation_right_lower * right
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)								
            new_surface.remove
            
          elsif slope_dir == "neg_x"
            if lower_pts[0].y < lower_pts[1].y
              left = lower_pts[1]
              right = lower_pts[0]
            else
              left = lower_pts[0]
              right = lower_pts[1]
            end
            
            m_left_lower[0,3] = -eaves_depth
            m_left_lower[1,3] = eaves_depth
            m_left_lower[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_left_upper[0,3] = 0
            m_left_upper[1,3] = 0
            m_left_upper[2,3] = z_offset

            m_right_lower[0,3] = -eaves_depth
            m_right_lower[1,3] = -eaves_depth
            m_right_lower[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_right_upper[0,3] = 0
            m_right_upper[1,3] = 0
            m_right_upper[2,3] = z_offset     
                        
            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
                        
            transformation_left_lower = OpenStudio::Transformation.new(m_left_lower)
            transformation_left_upper = OpenStudio::Transformation.new(m_left_upper)
            transformation_right_lower = OpenStudio::Transformation.new(m_right_lower)
            transformation_right_upper = OpenStudio::Transformation.new(m_right_upper)
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << transformation_left_lower * left
            new_vertices << transformation_left_upper * left
            new_vertices << transformation_right_upper * right
            new_vertices << transformation_right_lower * right
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)								
            new_surface.remove
            
          elsif slope_dir == "pos_x"
            if lower_pts[0].y < lower_pts[1].y
              left = lower_pts[0]
              right = lower_pts[1]
            else
              left = lower_pts[1]
              right = lower_pts[0]
            end
            
            m_left_lower[0,3] = eaves_depth
            m_left_lower[1,3] = -eaves_depth
            m_left_lower[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_left_upper[0,3] = 0
            m_left_upper[1,3] = 0
            m_left_upper[2,3] = z_offset

            m_right_lower[0,3] = eaves_depth
            m_right_lower[1,3] = eaves_depth
            m_right_lower[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

            m_right_upper[0,3] = 0
            m_right_upper[1,3] = 0
            m_right_upper[2,3] = z_offset     
                        
            shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
                        
            transformation_left_lower = OpenStudio::Transformation.new(m_left_lower)
            transformation_left_upper = OpenStudio::Transformation.new(m_left_upper)
            transformation_right_lower = OpenStudio::Transformation.new(m_right_lower)
            transformation_right_upper = OpenStudio::Transformation.new(m_right_upper)
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << transformation_left_lower * left
            new_vertices << transformation_left_upper * left
            new_vertices << transformation_right_upper * right
            new_vertices << transformation_right_lower * right
            new_surface.setVertices(new_vertices)		
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName("eaves")
            shading_surface.setShadingSurfaceGroup(shading_surface_group)								
            new_surface.remove
            
          end
          
        end
        
      end
    
    end   
    
    unless surfaces_modified
      runner.registerAsNotApplicable("No surfaces found for adding eaves.")
      return true
    end
   
    return true

  end
  
  def initialize_transformation_matrix(m)
    m[0,0] = 1
    m[1,1] = 1
    m[2,2] = 1
    m[3,3] = 1
    return m
  end

  def determine_roof_type(surfaces)
    roof_decks = []
    gable_walls = []
    surfaces.each do |surface|
      next if surface.space.get.name.to_s.downcase.include? "garage" # don't determine the roof type based on the garage (gable) roof
      if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
        roof_decks << surface
      elsif surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors" and surface.vertices.length == 3
        gable_walls << surface
      end
    end
    if roof_decks.length == 1
      return Constants.RoofTypeFlat
    elsif gable_walls.length > 0
      return Constants.RoofTypeGable
    else
      return Constants.RoofTypeHip
    end
  end
  
  def get_slope_direction_and_lower_points(surface)
    z_s = []
    surface.vertices.each do |vertex|
      z_s << vertex.z
    end
    bot_z = z_s.min
    top_z = z_s.max
    lower_pts = []
    upper_pts = []
    surface.vertices.each do |vertex|
      if (vertex.z - bot_z).abs < 0.0001
        lower_pts << OpenStudio::Point3d.new(vertex.x, vertex.y, vertex.z)
      elsif (vertex.z - top_z).abs < 0.0001
        upper_pts << OpenStudio::Point3d.new(vertex.x, vertex.y, vertex.z)
      end        
    end  
    if lower_pts.length == 3
      lower_pts.delete_at(1)
    end
    slope_dir = nil
    if (lower_pts[0].x - lower_pts[1].x).abs < 0.001 and lower_pts[0].x > upper_pts[0].x
      slope_dir = "pos_x"
    elsif (lower_pts[0].x - lower_pts[1].x).abs < 0.001 and lower_pts[0].x < upper_pts[0].x
      slope_dir = "neg_x"
    elsif (lower_pts[0].y - lower_pts[1].y).abs < 0.001 and lower_pts[0].y > upper_pts[0].y
      slope_dir = "pos_y"
    elsif (lower_pts[0].y - lower_pts[1].y).abs < 0.001 and lower_pts[0].y < upper_pts[0].y
      slope_dir = "neg_y"
    end
    return slope_dir, lower_pts, upper_pts
  end
  
  def get_existing_eaves_depth(shading_surface)
    existing_eaves_depth = 0
    min_xs = []
    (0..3).to_a.each do |i|
      if (shading_surface.vertices[0].x - shading_surface.vertices[i].x).abs > existing_eaves_depth
        min_xs << (shading_surface.vertices[0].x - shading_surface.vertices[i].x).abs
      end
    end
    unless min_xs.empty?
      return min_xs.min
    end
    return 0
  end  
  
end

# register the measure to be used by the application
CreateResidentialEaves.new.registerWithApplication
