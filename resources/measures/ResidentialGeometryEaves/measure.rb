# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

# start the measure
class CreateResidentialEaves < OpenStudio::Measure::ModelMeasure
  
  # human readable name
  def name
    return "Set Residential Eaves"
  end

  # human readable description
  def description
    return "Sets the eaves for the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Performs a series of affine transformations on the roof decks into shading surfaces."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a choice argument for model objects
    roof_structure_display_names = OpenStudio::StringVector.new
    roof_structure_display_names << Constants.RoofStructureTrussCantilever
    roof_structure_display_names << Constants.RoofStructureRafter
    
    #make a choice argument for roof type
    roof_structure = OpenStudio::Measure::OSArgument::makeChoiceArgument("roof_structure", roof_structure_display_names, true)
    roof_structure.setDisplayName("Roof Structure")
    roof_structure.setDescription("The roof structure of the building.")
    roof_structure.setDefaultValue(Constants.RoofStructureTrussCantilever)
    args << roof_structure    
    
    #make a choice argument for eaves depth
    eaves_depth = OpenStudio::Measure::OSArgument::makeDoubleArgument("eaves_depth", true)
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
    eaves_depth = UnitConversions.convert(runner.getDoubleArgumentValue("eaves_depth",user_arguments),"ft","m")

    # remove existing eaves
    num_removed = 0
    existing_eaves_depth = nil
    model.getShadingSurfaceGroups.each do |shading_surface_group|
      next unless shading_surface_group.name.to_s == Constants.ObjectNameEaves
      shading_surface_group.shadingSurfaces.each do |shading_surface|
        num_removed += 1
        next unless existing_eaves_depth.nil?
        existing_eaves_depth = get_existing_eaves_depth(shading_surface)
      end
      shading_surface_group.remove
      runner.registerInfo("Removed existing #{Constants.ObjectNameEaves}.")
    end
    if num_removed > 0
      runner.registerInfo("#{num_removed} eaves shading surfaces removed.")
    end
    
    # No eaves to add? Exit here.
    if eaves_depth == 0 and num_removed == 0
      runner.registerAsNotApplicable("No eaves were added or removed.")
      return true
    end    
    if existing_eaves_depth.nil?
      existing_eaves_depth = 0
    end    
    
    units = Geometry.get_building_units(model, runner)
    return false if units.nil?
    
    model_spaces = model.getSpaces
    model_surfaces = model.getSurfaces
    
    building_type = Geometry.get_building_type(model)
    roof_type = determine_roof_type(model_surfaces, units.length, building_type)
    garage_pos, garage_width, garage_depth, garage_protrusion = get_garage_dimensions(model_surfaces)
    inset_position = determine_inset_position(model_surfaces)
    top_floor_z = determine_top_floor_z(model_spaces)
    num_floors = Geometry.get_building_stories(model_spaces)    
    
    surfaces_modified = false
    
    shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
    shading_surface_group.setName(Constants.ObjectNameEaves)
    roof_pitch = Geometry.get_roof_pitch(model_surfaces)

    case roof_type
    when Constants.RoofTypeGable

      attic_increase_existing = roof_pitch * existing_eaves_depth
      attic_increase_new = roof_pitch * eaves_depth      
      attic_increase_delta = attic_increase_new - attic_increase_existing
      
      model_surfaces.each do |surface|
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
            m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
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
          
          y_s = []
          surface.vertices.each do |vertex|
            y_s << vertex.y
          end
          gable_garage_roof = false
          if y_s.uniq.length == 3
            gable_garage_roof = true
          end
          
          new_surface = surface.clone.to_Surface.get
          z_offset = surface.space.get.zOrigin # shift the z coordinates of the vertices up by the z origin of the space
          m_left_lower_out = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_mid_out = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_mid_out_left = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_mid_in = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_upper_out = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_upper_in = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_lower_out = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_mid_out = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_mid_out_right = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_mid_in = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_upper_out = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_upper_in = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
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
            
            if garage_pos == "Left"
            
              m_left_lower_out[0,3] = -eaves_depth
              m_left_lower_out[1,3] = -eaves_depth
              m_left_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

              m_left_mid_out[0,3] = garage_width
              m_left_mid_out[1,3] = -eaves_depth
              m_left_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
              
              m_left_mid_out_left[0,3] = 0
              m_left_mid_out_left[1,3] = -eaves_depth
              m_left_mid_out_left[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
              
              m_left_mid_in[0,3] = garage_width
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

              m_right_mid_out[0,3] = 0
              m_right_mid_out[1,3] = -eaves_depth
              m_right_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
              
              m_right_mid_out_right[0,3] = 0
              m_right_mid_out_right[1,3] = -eaves_depth
              m_right_mid_out_right[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
              
              m_right_mid_in[0,3] = 0
              m_right_mid_in[1,3] = 0
              m_right_mid_in[2,3] = z_offset             
              
              m_right_upper_out[0,3] = eaves_depth
              m_right_upper_out[1,3] = 0
              m_right_upper_out[2,3] = z_offset
              
              m_right_upper_in[0,3] = 0
              m_right_upper_in[1,3] = 0
              m_right_upper_in[2,3] = z_offset
              
            elsif garage_pos == "Right"
              
              m_left_lower_out[0,3] = -eaves_depth
              m_left_lower_out[1,3] = -eaves_depth
              m_left_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

              m_left_mid_out[0,3] = 0
              m_left_mid_out[1,3] = -eaves_depth
              m_left_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
              
              m_left_mid_out_left[0,3] = 0
              m_left_mid_out_left[1,3] = -eaves_depth
              m_left_mid_out_left[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
              
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

              m_right_mid_out[0,3] = -garage_width
              m_right_mid_out[1,3] = -eaves_depth
              m_right_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
              
              m_right_mid_out_right[0,3] = 0
              m_right_mid_out_right[1,3] = -eaves_depth
              m_right_mid_out_right[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
              
              m_right_mid_in[0,3] = -garage_width
              m_right_mid_in[1,3] = 0
              m_right_mid_in[2,3] = z_offset             
              
              m_right_upper_out[0,3] = eaves_depth
              m_right_upper_out[1,3] = 0
              m_right_upper_out[2,3] = z_offset
              
              m_right_upper_in[0,3] = 0
              m_right_upper_in[1,3] = 0
              m_right_upper_in[2,3] = z_offset              
              
            else

              m_left_lower_out[0,3] = -eaves_depth
              m_left_lower_out[1,3] = -eaves_depth
              m_left_lower_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta

              m_left_mid_out[0,3] = 0
              m_left_mid_out[1,3] = -eaves_depth
              m_left_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
              
              m_left_mid_out_left[0,3] = 0
              m_left_mid_out_left[1,3] = -eaves_depth
              m_left_mid_out_left[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
              
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

              m_right_mid_out[0,3] = 0
              m_right_mid_out[1,3] = -eaves_depth
              m_right_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
              
              m_right_mid_out_right[0,3] = 0
              m_right_mid_out_right[1,3] = -eaves_depth
              m_right_mid_out_right[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
              
              m_right_mid_in[0,3] = 0
              m_right_mid_in[1,3] = 0
              m_right_mid_in[2,3] = z_offset             
              
              m_right_upper_out[0,3] = eaves_depth
              m_right_upper_out[1,3] = 0
              m_right_upper_out[2,3] = z_offset
              
              m_right_upper_in[0,3] = 0
              m_right_upper_in[1,3] = 0
              m_right_upper_in[2,3] = z_offset
            
            end
                        
            # lower eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_left_mid_in) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_in) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_surface.setVertices(new_vertices)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            # left eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_upper_out) * left_upper
            new_vertices << OpenStudio::Transformation.new(m_left_upper_in) * left_upper
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out_left) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_left_lower_out) * left_lower
            new_surface.setVertices(new_vertices)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
            # right eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_right_upper_out) * right_upper
            new_vertices << OpenStudio::Transformation.new(m_right_lower_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out_right) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_upper_in) * right_upper
            new_surface.setVertices(new_vertices)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
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

            m_left_mid_out[0,3] = 0
            m_left_mid_out[1,3] = eaves_depth
            m_left_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
            
            m_left_mid_out_left[0,3] = 0
            m_left_mid_out_left[1,3] = eaves_depth
            m_left_mid_out_left[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
            
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

            m_right_mid_out[0,3] = 0
            m_right_mid_out[1,3] = eaves_depth
            m_right_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
            
            m_right_mid_out_right[0,3] = 0
            m_right_mid_out_right[1,3] = eaves_depth
            m_right_mid_out_right[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
            
            m_right_mid_in[0,3] = 0
            m_right_mid_in[1,3] = 0
            m_right_mid_in[2,3] = z_offset             
            
            m_right_upper_out[0,3] = eaves_depth
            m_right_upper_out[1,3] = 0
            m_right_upper_out[2,3] = z_offset
            
            m_right_upper_in[0,3] = 0
            m_right_upper_in[1,3] = 0
            m_right_upper_in[2,3] = z_offset
                        
            # lower eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_in) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_left_mid_in) * left_lower
            new_surface.setVertices(new_vertices)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            # left eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_upper_out) * left_upper
            new_vertices << OpenStudio::Transformation.new(m_left_lower_out) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out_left) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_left_upper_in) * left_upper
            new_surface.setVertices(new_vertices)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
            # right eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_right_upper_out) * right_upper
            new_vertices << OpenStudio::Transformation.new(m_right_upper_in) * right_upper
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out_right) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_lower_out) * right_lower
            new_surface.setVertices(new_vertices)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
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

            m_left_mid_out[0,3] = -eaves_depth
            m_left_mid_out[1,3] = 0
            m_left_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
            
            m_left_mid_out_left[0,3] = -eaves_depth
            m_left_mid_out_left[1,3] = 0
            m_left_mid_out_left[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
            
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

            m_right_mid_out[0,3] = -eaves_depth
            m_right_mid_out[1,3] = 0
            m_right_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
            
            m_right_mid_out_right[0,3] = -eaves_depth
            m_right_mid_out_right[1,3] = 0
            m_right_mid_out_right[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
            
            m_right_mid_in[0,3] = 0
            m_right_mid_in[1,3] = 0
            m_right_mid_in[2,3] = z_offset             
            
            m_right_upper_out[0,3] = 0
            m_right_upper_out[1,3] = -eaves_depth
            m_right_upper_out[2,3] = z_offset
            
            m_right_upper_in[0,3] = 0
            m_right_upper_in[1,3] = 0
            m_right_upper_in[2,3] = z_offset
                                                
            # lower eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_left_mid_in) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_in) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_surface.setVertices(new_vertices)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            # left eave
            unless gable_garage_roof
              new_vertices = OpenStudio::Point3dVector.new
              new_vertices << OpenStudio::Transformation.new(m_left_upper_out) * left_upper
              new_vertices << OpenStudio::Transformation.new(m_left_upper_in) * left_upper
              new_vertices << OpenStudio::Transformation.new(m_left_mid_out_left) * left_lower
              new_vertices << OpenStudio::Transformation.new(m_left_lower_out) * left_lower
              new_surface.setVertices(new_vertices)        
              shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
              shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
              shading_surface.setShadingSurfaceGroup(shading_surface_group)
            end
            
            # right eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_right_upper_out) * right_upper
            new_vertices << OpenStudio::Transformation.new(m_right_lower_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out_right) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_upper_in) * right_upper
            new_surface.setVertices(new_vertices)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
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

            m_left_mid_out[0,3] = eaves_depth
            m_left_mid_out[1,3] = 0
            m_left_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
            
            m_left_mid_out_left[0,3] = eaves_depth
            m_left_mid_out_left[1,3] = 0
            m_left_mid_out_left[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
            
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

            m_right_mid_out[0,3] = eaves_depth
            m_right_mid_out[1,3] = 0
            m_right_mid_out[2,3] = -attic_increase_existing + z_offset - attic_increase_delta
            
            m_right_mid_out_right[0,3] = eaves_depth
            m_right_mid_out_right[1,3] = 0
            m_right_mid_out_right[2,3] = -attic_increase_existing + z_offset - attic_increase_delta              
            
            m_right_mid_in[0,3] = 0
            m_right_mid_in[1,3] = 0
            m_right_mid_in[2,3] = z_offset             
            
            m_right_upper_out[0,3] = 0
            m_right_upper_out[1,3] = -eaves_depth
            m_right_upper_out[2,3] = z_offset
            
            m_right_upper_in[0,3] = 0
            m_right_upper_in[1,3] = 0
            m_right_upper_in[2,3] = z_offset
                                                
            # lower eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_left_mid_out) * left_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_mid_in) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_left_mid_in) * left_lower
            new_surface.setVertices(new_vertices)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            # left eave
            unless gable_garage_roof
              new_vertices = OpenStudio::Point3dVector.new
              new_vertices << OpenStudio::Transformation.new(m_left_upper_out) * left_upper
              new_vertices << OpenStudio::Transformation.new(m_left_lower_out) * left_lower
              new_vertices << OpenStudio::Transformation.new(m_left_mid_out_left) * left_lower
              new_vertices << OpenStudio::Transformation.new(m_left_upper_in) * left_upper
              new_surface.setVertices(new_vertices)        
              shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
              shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
              shading_surface.setShadingSurfaceGroup(shading_surface_group)
            end
            
            # right eave
            new_vertices = OpenStudio::Point3dVector.new
            new_vertices << OpenStudio::Transformation.new(m_right_upper_out) * right_upper
            new_vertices << OpenStudio::Transformation.new(m_right_upper_in) * right_upper
            new_vertices << OpenStudio::Transformation.new(m_right_mid_out_right) * right_lower
            new_vertices << OpenStudio::Transformation.new(m_right_lower_out) * right_lower
            new_surface.setVertices(new_vertices)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
          end
          
          new_surface.remove
          
        end
        
      end
     
    when Constants.RoofTypeFlat
    
      model_surfaces.each do |surface|
        if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
        elsif surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "adiabatic" and surface.vertices.length == 4 # corridor roof deck
        else
          next
        end
        
        surfaces_modified = true
                
        if surface.vertices.length == 4
        
          garage_roof = false
          if Geometry.is_garage(surface.space.get)
            garage_roof = true
          end        

          next unless surface.vertices.all? {|vertex| (vertex.z + surface.space.get.zOrigin - top_floor_z).abs < 0.01}
      
          attic_length, attic_width, attic_height = Geometry.get_surface_dimensions(surface)
        
          new_surface_left = surface.clone.to_Surface.get
          new_surface_right = surface.clone.to_Surface.get
          new_surface_bottom = surface.clone.to_Surface.get
          new_surface_top = surface.clone.to_Surface.get
          vertices = surface.vertices
          z_offset = surface.space.get.zOrigin # shift the z coordinates of the vertices up by the z origin of the space
          
          m_left_far = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_close = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_far[0,3] = -attic_length
          m_left_far[2,3] = z_offset
          m_left_close[0,3] = -eaves_depth
          m_left_close[2,3] = z_offset
          
          m_right_far = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_close = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_far[0,3] = attic_length
          m_right_far[2,3] = z_offset
          m_right_close[0,3] = eaves_depth
          m_right_close[2,3] = z_offset          
          
          m_bottom_far_left = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_bottom_far_right = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_bottom_close_left = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_bottom_close_right = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
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
          
          m_top_far_left = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_top_far_right = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_top_close_left = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_top_close_right = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
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
          
          new_vertices_right = OpenStudio::Point3dVector.new
          new_vertices_right << transformation_right_far * top_left
          new_vertices_right << transformation_right_close * top_right
          new_vertices_right << transformation_right_close * bottom_right          
          new_vertices_right << transformation_right_far * bottom_left          
          
          new_vertices_bottom = OpenStudio::Point3dVector.new
          new_vertices_bottom << transformation_bottom_far_left * top_left
          new_vertices_bottom << transformation_bottom_far_right * top_right
          new_vertices_bottom << transformation_bottom_close_right * bottom_right
          new_vertices_bottom << transformation_bottom_close_left * bottom_left          
          
          new_vertices_top = OpenStudio::Point3dVector.new
          new_vertices_top << transformation_top_far_left * bottom_left
          new_vertices_top << transformation_top_close_left * top_left
          new_vertices_top << transformation_top_close_right * top_right
          new_vertices_top << transformation_top_far_right * bottom_right          
          
          if garage_roof and garage_pos == "Left"
          
            new_surface_left.setVertices(new_vertices_left)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_left.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface_left)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
            if garage_protrusion > eaves_depth
              garage_protrusion_sw_point = OpenStudio::Point3d.new(bottom_right.x, bottom_right.y, bottom_right.z+z_offset)
              garage_protrusion_nw_point = OpenStudio::Point3d.new(top_right.x, top_right.y-eaves_depth-(garage_depth-garage_protrusion), top_right.z+z_offset)
              garage_protrusion_ne_point = OpenStudio::Point3d.new(top_right.x+eaves_depth, top_right.y-eaves_depth-(garage_depth-garage_protrusion), top_right.z+z_offset)
              garage_protrusion_se_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth, bottom_right.y, bottom_right.z+z_offset)
              new_vertices_garage_protrusion = Geometry.make_polygon(garage_protrusion_sw_point, garage_protrusion_nw_point, garage_protrusion_ne_point, garage_protrusion_se_point)
            end
          
          elsif garage_roof and garage_pos == "Right"
          
            new_surface_right.setVertices(new_vertices_right)        
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_right.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface_right)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
            if garage_protrusion > eaves_depth
              garage_protrusion_sw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth, bottom_left.y, bottom_left.z+z_offset)
              garage_protrusion_nw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth, top_left.y-eaves_depth-(garage_depth-garage_protrusion), top_left.z+z_offset)
              garage_protrusion_ne_point = OpenStudio::Point3d.new(top_left.x, top_left.y-eaves_depth-(garage_depth-garage_protrusion), top_left.z+z_offset)
              garage_protrusion_se_point = OpenStudio::Point3d.new(bottom_left.x, bottom_left.y, bottom_left.z+z_offset)
              new_vertices_garage_protrusion = Geometry.make_polygon(garage_protrusion_sw_point, garage_protrusion_nw_point, garage_protrusion_ne_point, garage_protrusion_se_point)
            end
          
          else
          
            new_surface_top.setVertices(new_vertices_top)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_top.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface_top)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
          
            new_surface_left.setVertices(new_vertices_left)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_left.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface_left)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
            new_surface_right.setVertices(new_vertices_right)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_right.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface_right)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
          
          end

          new_surface_bottom.setVertices(new_vertices_bottom)
          shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface_bottom.vertices, model)
          shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface_bottom)))
          shading_surface.setShadingSurfaceGroup(shading_surface_group)
          
          if garage_protrusion > eaves_depth
            new_surface = OpenStudio::Model::Surface.new(new_vertices_garage_protrusion, model)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            new_surface.remove
          end
          
          new_surface_top.remove
          new_surface_left.remove
          new_surface_right.remove
          new_surface_bottom.remove
        
        elsif surface.vertices.length == 6 # has garage
          
          vertices = surface.vertices
          z_offset = surface.space.get.zOrigin
          rear_unit = surface.vertices.all? {|vertex| vertex.y >= 0 }
          if building_type == Constants.BuildingTypeSingleFamilyDetached
            rear_unit = false
          end
                    
          if inset_position == "Left"
          
            if not rear_unit
            
              if vertices[0].x < vertices[1].x and vertices[2].x < vertices[3].x
                top_left = vertices[5]
                top_right = vertices[4]
                bottom_right = vertices[3]
                top_mid = vertices[1]
                bottom_mid = vertices[2]               
                bottom_left = vertices[0]
              elsif vertices[5].x < vertices[0].x and vertices[1].x < vertices[2].x
                top_left = vertices[4]
                top_right = vertices[3]
                bottom_right = vertices[2]
                top_mid = vertices[0]
                bottom_mid = vertices[1]
                bottom_left = vertices[5]
              elsif vertices[4].x < vertices[5].x and vertices[0].x < vertices[1].x
                top_left = vertices[3]
                top_right = vertices[2]
                bottom_right = vertices[1]
                top_mid = vertices[5]
                bottom_mid = vertices[0]
                bottom_left = vertices[4]            
              elsif vertices[3].x < vertices[4].x and vertices[5].x < vertices[0].x
                top_left = vertices[2]
                top_right = vertices[1]
                bottom_right = vertices[0]
                top_mid = vertices[4]
                bottom_mid = vertices[5]
                bottom_left = vertices[3]
              elsif vertices[2].x < vertices[3].x and vertices[4].x < vertices[5].x
                top_left = vertices[1]
                top_right = vertices[0]
                bottom_right = vertices[5]
                top_mid = vertices[3]
                bottom_mid = vertices[4]
                bottom_left = vertices[2]
              elsif vertices[1].x < vertices[2].x and vertices[3].x < vertices[4].x
                top_left = vertices[0]
                top_right = vertices[5]
                bottom_right = vertices[4]
                top_mid = vertices[2]
                bottom_mid = vertices[3]
                bottom_left = vertices[1]
              end
            
              sw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y-eaves_depth,bottom_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y,bottom_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_mid.x,top_mid.y,top_mid.z+z_offset)
              se_point = OpenStudio::Point3d.new(top_mid.x,top_mid.y-eaves_depth,top_mid.z+z_offset)
              new_vertices_bottom = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y,top_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y+eaves_depth,top_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y+eaves_depth,top_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y,top_right.z+z_offset)
              new_vertices_top = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
              
              sw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y,bottom_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y,top_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_left.x,top_left.y,top_left.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_left.x,bottom_left.y,bottom_left.z+z_offset)
              new_vertices_left = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(bottom_right.x,bottom_right.y,bottom_right.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_right.x,top_right.y,top_right.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y,top_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y,bottom_right.z+z_offset)
              new_vertices_right = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              if num_floors > 1 or garage_pos == "None"
                sw_point = OpenStudio::Point3d.new(bottom_mid.x-eaves_depth,bottom_mid.y-eaves_depth,bottom_mid.z+z_offset)
                nw_point = OpenStudio::Point3d.new(bottom_mid.x-eaves_depth,bottom_mid.y,bottom_mid.z+z_offset)
              else
                sw_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y-eaves_depth,bottom_mid.z+z_offset)
                nw_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y,bottom_mid.z+z_offset)              
              end
              ne_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y,bottom_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y-eaves_depth,bottom_right.z+z_offset)
              new_vertices_inset_one = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(bottom_mid.x-eaves_depth,bottom_mid.y,bottom_mid.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_mid.x-eaves_depth,top_mid.y-eaves_depth,top_mid.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_mid.x,top_mid.y-eaves_depth,top_mid.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y,bottom_mid.z+z_offset)
              new_vertices_inset_two = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
            
            else
            
              if vertices[0].x < vertices[5].x and vertices[4].x < vertices[3].x
                top_left = vertices[0]
                top_right = vertices[3]
                bottom_right = vertices[2]
                top_mid = vertices[5]
                bottom_mid = vertices[4]               
                bottom_left = vertices[1]
              elsif vertices[1].x < vertices[0].x and vertices[5].x < vertices[4].x
                top_left = vertices[1]
                top_right = vertices[4]
                bottom_right = vertices[3]
                top_mid = vertices[0]
                bottom_mid = vertices[5]
                bottom_left = vertices[2]
              elsif vertices[2].x < vertices[1].x and vertices[0].x < vertices[5].x
                top_left = vertices[2]
                top_right = vertices[5]
                bottom_right = vertices[4]
                top_mid = vertices[1]
                bottom_mid = vertices[0]
                bottom_left = vertices[3]            
              elsif vertices[3].x < vertices[2].x and vertices[1].x < vertices[0].x
                top_left = vertices[3]
                top_right = vertices[0]
                bottom_right = vertices[5]
                top_mid = vertices[2]
                bottom_mid = vertices[1]
                bottom_left = vertices[4]
              elsif vertices[4].x < vertices[3].x and vertices[2].x < vertices[1].x
                top_left = vertices[4]
                top_right = vertices[1]
                bottom_right = vertices[0]
                top_mid = vertices[3]
                bottom_mid = vertices[2]
                bottom_left = vertices[5]
              elsif vertices[5].x < vertices[4].x and vertices[3].x < vertices[2].x
                top_left = vertices[5]
                top_right = vertices[2]
                bottom_right = vertices[1]
                top_mid = vertices[4]
                bottom_mid = vertices[3]
                bottom_left = vertices[0]
              end
                
              sw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y-eaves_depth,bottom_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y,bottom_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y,bottom_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y-eaves_depth,bottom_right.z+z_offset)
              new_vertices_bottom = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y,bottom_mid.z+z_offset)
              nw_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y+eaves_depth,bottom_mid.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y+eaves_depth,top_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y,top_right.z+z_offset)
              new_vertices_top = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
              
              sw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y,bottom_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y,top_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_left.x,top_left.y,top_left.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_left.x,bottom_left.y,bottom_left.z+z_offset)
              new_vertices_left = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(bottom_right.x,bottom_right.y,bottom_right.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_right.x,top_right.y,top_right.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y,top_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y,bottom_right.z+z_offset)
              new_vertices_right = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y,top_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y+eaves_depth,top_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_mid.x+eaves_depth,top_mid.y+eaves_depth,top_mid.z+z_offset)
              se_point = OpenStudio::Point3d.new(top_mid.x+eaves_depth,top_mid.y,top_mid.z+z_offset)
              new_vertices_inset_one = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)

              sw_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y+eaves_depth,bottom_mid.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_mid.x,top_mid.y,top_mid.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_mid.x+eaves_depth,top_mid.y,top_mid.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_mid.x+eaves_depth,bottom_mid.y+eaves_depth,bottom_mid.z+z_offset)
              new_vertices_inset_two = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
            
            end
            
          elsif inset_position == "Right"
          
            if not rear_unit

              if vertices[0].x < vertices[1].x and vertices[2].x < vertices[3].x
                top_left = vertices[5]
                top_right = vertices[4]
                bottom_right = vertices[3]
                top_mid = vertices[2]
                bottom_mid = vertices[1]               
                bottom_left = vertices[0]
              elsif vertices[5].x < vertices[0].x and vertices[1].x < vertices[2].x
                top_left = vertices[4]
                top_right = vertices[3]
                bottom_right = vertices[2]
                top_mid = vertices[1]
                bottom_mid = vertices[0]
                bottom_left = vertices[5]
              elsif vertices[4].x < vertices[5].x and vertices[0].x < vertices[1].x
                top_left = vertices[3]
                top_right = vertices[2]
                bottom_right = vertices[1]
                top_mid = vertices[0]
                bottom_mid = vertices[5]
                bottom_left = vertices[4]            
              elsif vertices[3].x < vertices[4].x and vertices[5].x < vertices[0].x
                top_left = vertices[2]
                top_right = vertices[1]
                bottom_right = vertices[0]
                top_mid = vertices[5]
                bottom_mid = vertices[4]
                bottom_left = vertices[3]
              elsif vertices[2].x < vertices[3].x and vertices[4].x < vertices[5].x
                top_left = vertices[1]
                top_right = vertices[0]
                bottom_right = vertices[5]
                top_mid = vertices[4]
                bottom_mid = vertices[3]
                bottom_left = vertices[2]
              elsif vertices[1].x < vertices[2].x and vertices[3].x < vertices[4].x
                top_left = vertices[0]
                top_right = vertices[5]
                bottom_right = vertices[4]
                top_mid = vertices[3]
                bottom_mid = vertices[2]
                bottom_left = vertices[1]
              end
                
              sw_point = OpenStudio::Point3d.new(top_mid.x,top_mid.y-eaves_depth,top_mid.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_mid.x,top_mid.y,top_mid.z+z_offset)
              ne_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y,bottom_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y-eaves_depth,bottom_right.z+z_offset)
              new_vertices_bottom = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y,top_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y+eaves_depth,top_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y+eaves_depth,top_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y,top_right.z+z_offset)
              new_vertices_top = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
              
              sw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y,bottom_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y,top_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_left.x,top_left.y,top_left.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_left.x,bottom_left.y,bottom_left.z+z_offset)
              new_vertices_left = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(bottom_right.x,bottom_right.y,bottom_right.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_right.x,top_right.y,top_right.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y,top_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y,bottom_right.z+z_offset)
              new_vertices_right = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y-eaves_depth,bottom_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y,bottom_left.z+z_offset)
              if num_floors > 1 or garage_pos == "None"
                ne_point = OpenStudio::Point3d.new(bottom_mid.x+eaves_depth,bottom_mid.y,bottom_mid.z+z_offset)
                se_point = OpenStudio::Point3d.new(bottom_mid.x+eaves_depth,bottom_mid.y-eaves_depth,bottom_mid.z+z_offset)
              else
                ne_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y,bottom_mid.z+z_offset)
                se_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y-eaves_depth,bottom_mid.z+z_offset)              
              end
              new_vertices_inset_one = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y,bottom_mid.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_mid.x,top_mid.y-eaves_depth,top_mid.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_mid.x+eaves_depth,top_mid.y-eaves_depth,top_mid.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_mid.x+eaves_depth,bottom_mid.y,bottom_mid.z+z_offset)
              new_vertices_inset_two = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
            
            else
            
              if vertices[0].x < vertices[5].x and vertices[4].x < vertices[3].x
                top_left = vertices[0]
                top_right = vertices[3]
                bottom_right = vertices[2]
                top_mid = vertices[4]
                bottom_mid = vertices[5]               
                bottom_left = vertices[1]
              elsif vertices[1].x < vertices[0].x and vertices[5].x < vertices[4].x
                top_left = vertices[1]
                top_right = vertices[4]
                bottom_right = vertices[3]
                top_mid = vertices[5]
                bottom_mid = vertices[0]
                bottom_left = vertices[2]
              elsif vertices[2].x < vertices[1].x and vertices[0].x < vertices[5].x
                top_left = vertices[2]
                top_right = vertices[5]
                bottom_right = vertices[4]
                top_mid = vertices[0]
                bottom_mid = vertices[1]
                bottom_left = vertices[3]            
              elsif vertices[3].x < vertices[2].x and vertices[1].x < vertices[0].x
                top_left = vertices[3]
                top_right = vertices[0]
                bottom_right = vertices[5]
                top_mid = vertices[1]
                bottom_mid = vertices[2]
                bottom_left = vertices[4]
              elsif vertices[4].x < vertices[3].x and vertices[2].x < vertices[1].x
                top_left = vertices[4]
                top_right = vertices[1]
                bottom_right = vertices[0]
                top_mid = vertices[2]
                bottom_mid = vertices[3]
                bottom_left = vertices[5]
              elsif vertices[5].x < vertices[4].x and vertices[3].x < vertices[2].x
                top_left = vertices[5]
                top_right = vertices[2]
                bottom_right = vertices[1]
                top_mid = vertices[3]
                bottom_mid = vertices[4]
                bottom_left = vertices[0]
              end
                
              sw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y-eaves_depth,bottom_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y,bottom_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y,bottom_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y-eaves_depth,bottom_right.z+z_offset)
              new_vertices_bottom = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y,top_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y+eaves_depth,top_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y+eaves_depth,bottom_mid.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y,bottom_mid.z+z_offset)
              new_vertices_top = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
              
              sw_point = OpenStudio::Point3d.new(bottom_left.x-eaves_depth,bottom_left.y,bottom_left.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_left.x-eaves_depth,top_left.y,top_left.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_left.x,top_left.y,top_left.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_left.x,bottom_left.y,bottom_left.z+z_offset)
              new_vertices_left = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(bottom_right.x,bottom_right.y,bottom_right.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_right.x,top_right.y,top_right.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y,top_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_right.x+eaves_depth,bottom_right.y,bottom_right.z+z_offset)
              new_vertices_right = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(top_mid.x-eaves_depth,top_mid.y,top_mid.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_mid.x-eaves_depth,top_mid.y+eaves_depth,top_mid.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y+eaves_depth,top_right.z+z_offset)
              se_point = OpenStudio::Point3d.new(top_right.x+eaves_depth,top_right.y,top_right.z+z_offset)
              new_vertices_inset_one = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)    

              sw_point = OpenStudio::Point3d.new(bottom_mid.x-eaves_depth,bottom_mid.y+eaves_depth,bottom_mid.z+z_offset)
              nw_point = OpenStudio::Point3d.new(top_mid.x-eaves_depth,top_mid.y,top_mid.z+z_offset)
              ne_point = OpenStudio::Point3d.new(top_mid.x,top_mid.y,top_mid.z+z_offset)
              se_point = OpenStudio::Point3d.new(bottom_mid.x,bottom_mid.y+eaves_depth,bottom_mid.z+z_offset)
              new_vertices_inset_two = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)                
            
            end
            
          end          
          
          if num_floors > 1 or garage_pos == "None"
            
            new_surface = OpenStudio::Model::Surface.new(new_vertices_bottom, model)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
            new_surface.setVertices(new_vertices_top)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            new_surface.setVertices(new_vertices_left)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            new_surface.setVertices(new_vertices_right)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            new_surface.setVertices(new_vertices_inset_one)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            new_surface.setVertices(new_vertices_inset_two)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
            new_surface.remove
          
          else
            
            new_surface = OpenStudio::Model::Surface.new(new_vertices_top, model)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            new_surface.setVertices(new_vertices_left)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)

            new_surface.setVertices(new_vertices_right)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
            new_surface.setVertices(new_vertices_inset_one)
            shading_surface = OpenStudio::Model::ShadingSurface.new(new_surface.vertices, model)
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)            
          
            new_surface.remove
          
          end
                    
        end
        
      end
    
    when Constants.RoofTypeHip
    
      attic_increase_existing = roof_pitch * existing_eaves_depth
      attic_increase_new = roof_pitch * eaves_depth
      attic_increase_delta = attic_increase_new - attic_increase_existing    
      
      model_surfaces.each do |surface|
        next unless surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"      
        surfaces_modified = true
        
        # Truss, Cantilever
        if roof_structure == Constants.RoofStructureTrussCantilever
        
          # Roof Decks
          
          # raise the roof decks
          m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
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
          m_left_lower = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_left_upper = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_lower = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
          m_right_upper = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4,4,0))
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
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)                                
            
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
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)
            
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
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)                                
            
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
            shading_surface.setName(Constants.ObjectNameEaves(Geometry.get_facade_for_surface(new_surface)))
            shading_surface.setShadingSurfaceGroup(shading_surface_group)                                
            
          end
          
          new_surface.remove
          
        end
        
      end
    
    end   
    
    unless surfaces_modified
      runner.registerAsNotApplicable("No surfaces found for adding eaves.")
      return true
    end
    
    shading_surface_group.shadingSurfaces.each do |shading_surface|
      runner.registerInfo("Added #{shading_surface.name}")
    end
   
    return true

  end

  def determine_roof_type(surfaces, num_units, building_type)
    roof_decks = []
    gable_walls = []
    surfaces.each do |surface|
      next if Geometry.is_garage(surface.space.get) or Geometry.is_corridor(surface.space.get)
      if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
        roof_decks << surface
      elsif surface.surfaceType.downcase == "wall" and surface.outsideBoundaryCondition.downcase == "outdoors" and surface.vertices.length == 3
        gable_walls << surface
      end
    end
    if roof_decks.length == num_units or building_type == Constants.BuildingTypeMultifamily
      return Constants.RoofTypeFlat
    elsif gable_walls.length > 0
      return Constants.RoofTypeGable
    else
      return Constants.RoofTypeHip
    end
  end
  
  def determine_inset_position(surfaces)
    surfaces.each do |surface|
      next unless surface.vertices.length == 6
      next unless surface.surfaceType.downcase == "roofceiling"
      next unless surface.outsideBoundaryCondition.downcase == "outdoors"
      sorted_vertices = surface.vertices.sort_by { |vertex| [vertex.y, vertex.x] }
      next unless sorted_vertices[0].y <= 0 # determine only from the front units
      if sorted_vertices[0].x < sorted_vertices[2].x
        return "Right"
      else
        return "Left"
      end
    end
    return nil
  end
  
  def get_garage_dimensions(surfaces)
    surfaces.each do |surface|
      next unless Geometry.is_garage(surface.space.get)
      next unless surface.surfaceType.downcase == "floor"
      pos = "Right"
      if surface.vertices.any? {|vertex| vertex.x.abs < 0.001}
        pos = "Left"
      end
      l, w, h = Geometry.get_surface_dimensions(surface)
      garage_front = surface.vertices.sort_by { |vertex| vertex.y }[0]
      if garage_front.y.abs > 0
        return pos, l, w, garage_front.y.abs
      end
    end
    return "None", 0, 0, 0
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
  
  def determine_top_floor_z(spaces)
    space_max_zs = []
    spaces.each do |space|
      surfaces_max_zs = []
      space.surfaces.each do |surface|
        zvalues = Geometry.getSurfaceZValues([surface])
        space_max_zs << zvalues.max + UnitConversions.convert(space.zOrigin,"m","ft")
      end
      space_max_zs << space_max_zs.max
    end
    unless space_max_zs.empty?
      return UnitConversions.convert(space_max_zs.max,"ft","m")
    end
    return nil
  end
  
end

# register the measure to be used by the application
CreateResidentialEaves.new.registerWithApplication
