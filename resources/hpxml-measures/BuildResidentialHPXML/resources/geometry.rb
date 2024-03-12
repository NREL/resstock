# frozen_string_literal: true

class Geometry
  def self.get_abs_azimuth(relative_azimuth, building_orientation)
    azimuth = relative_azimuth + building_orientation

    # Ensure azimuth is >=0 and <=360
    while azimuth < 0.0
      azimuth += 360.0
    end

    while azimuth >= 360.0
      azimuth -= 360.0
    end

    return azimuth
  end

  def self.get_absolute_tilt(tilt_str, roof_pitch, latitude)
    tilt_str = tilt_str.downcase
    if tilt_str.start_with? 'roofpitch'
      roof_angle = Math.atan(roof_pitch / 12.0) * 180.0 / Math::PI
      return Float(eval(tilt_str.gsub('roofpitch', roof_angle.to_s)))
    elsif tilt_str.start_with? 'latitude'
      return Float(eval(tilt_str.gsub('latitude', latitude.to_s)))
    else
      return Float(tilt_str)
    end
  end

  def self.get_surface_azimuth(surface:,
                               orientation:)
    facade = get_facade_for_surface(surface)
    return get_azimuth_from_facade(facade: facade, orientation: orientation)
  end

  def self.get_azimuth_from_facade(facade:,
                                   orientation:)
    if facade == Constants.FacadeFront
      return get_abs_azimuth(0, orientation)
    elsif facade == Constants.FacadeBack
      return get_abs_azimuth(180, orientation)
    elsif facade == Constants.FacadeLeft
      return get_abs_azimuth(90, orientation)
    elsif facade == Constants.FacadeRight
      return get_abs_azimuth(270, orientation)
    else
      fail 'Unexpected facade.'
    end
  end

  def self.get_unexposed_garage_perimeter(geometry_garage_protrusion:,
                                          geometry_garage_width:,
                                          geometry_garage_depth:,
                                          **)
    protrusion = geometry_garage_protrusion
    width = geometry_garage_width
    depth = geometry_garage_depth
    # this is perimeter adjacent to a 100% protruding garage that is not exposed
    # we need this because it's difficult to set this surface to Adiabatic using our geometry methods
    if (protrusion == 1.0) && (width * depth > 0)
      return width
    end

    return 0
  end

  def self.get_adiabatic_adjacent_surface(model:,
                                          surface:)
    return if surface.outsideBoundaryCondition != 'Adiabatic'

    adjacentSurfaceType = 'Wall'
    if surface.surfaceType == 'RoofCeiling'
      adjacentSurfaceType = 'Floor'
    elsif surface.surfaceType == 'Floor'
      adjacentSurfaceType = 'RoofCeiling'
    end

    model.getSurfaces.sort.each do |adjacent_surface|
      next if surface == adjacent_surface
      next if adjacent_surface.surfaceType != adjacentSurfaceType
      next if adjacent_surface.outsideBoundaryCondition != 'Adiabatic'
      next unless has_same_vertices(surface, adjacent_surface)

      return adjacent_surface
    end
    return
  end

  def self.get_adjacent_to(surface:)
    space = surface.space.get
    st = space.spaceType.get
    space_type = st.standardsSpaceType.get

    return space_type
  end

  def self.add_rim_joist(model, polygon, space, rim_joist_height, z)
    if rim_joist_height > 0
      # make polygons
      p = OpenStudio::Point3dVector.new
      polygon.each do |point|
        p << OpenStudio::Point3d.new(point.x, point.y, z)
      end
      rim_joist_polygon = p

      # make space
      rim_joist_space = OpenStudio::Model::Space::fromFloorPrint(rim_joist_polygon, rim_joist_height, model)
      rim_joist_space = rim_joist_space.get
      assign_indexes(model, rim_joist_polygon, rim_joist_space)

      space.surfaces.each do |surface|
        next if surface.surfaceType.downcase != 'roofceiling'

        surface.remove
      end

      rim_joist_space.surfaces.each do |surface|
        next if surface.surfaceType.downcase != 'floor'

        surface.remove
      end

      rim_joist_space.surfaces.each do |surface|
        surface.setSpace(space)
      end

      rim_joist_space.remove
    end
  end

  def self.assign_indexes(model, footprint_polygon, space)
    space.additionalProperties.setFeature('Index', indexer(model))

    space.surfaces.each do |surface|
      next if surface.surfaceType != 'Floor'

      surface.additionalProperties.setFeature('Index', indexer(model))
    end

    num_points = footprint_polygon.size
    for i in 1..num_points
      pt1 = footprint_polygon[(i + 1) % num_points]
      pt2 = footprint_polygon[i % num_points]
      polygon_points = [pt1, pt2]

      space.surfaces.each do |surface|
        next if surface.surfaceType != 'Wall'

        num_points_matched = 0
        polygon_points.each do |polygon_point|
          surface.vertices.each do |surface_point|
            x = polygon_point.x - surface_point.x
            y = polygon_point.y - surface_point.y
            z = polygon_point.z - surface_point.z
            num_points_matched += 1 if x.abs < Constants.small && y.abs < Constants.small && z.abs < Constants.small
          end
        end
        next if num_points_matched < 2 # match at least 2 points of the footprint_polygon and you've found the correct wall surface

        surface.additionalProperties.setFeature('Index', indexer(model))
      end
    end

    space.surfaces.each do |surface|
      next if surface.surfaceType != 'RoofCeiling'

      surface.additionalProperties.setFeature('Index', indexer(model))
    end
  end

  def self.assign_remaining_surface_indexes(model)
    # Index any remaining surfaces created from intersecting/matching
    # We can't deterministically assign indexes to these surfaces
    model.getSurfaces.each do |surface|
      next if surface.additionalProperties.getFeatureAsInteger('Index').is_initialized

      surface.additionalProperties.setFeature('Index', indexer(model))
    end
  end

  def self.create_space(model)
    space = OpenStudio::Model::Space.new(model)
    space.additionalProperties.setFeature('Index', indexer(model))
    return space
  end

  def self.create_surface(polygon, model)
    surface = OpenStudio::Model::Surface.new(polygon, model)
    surface.additionalProperties.setFeature('Index', indexer(model))
    return surface
  end

  def self.create_sub_surface(polygon, model)
    sub_surface = OpenStudio::Model::SubSurface.new(polygon, model)
    sub_surface.additionalProperties.setFeature('Index', indexer(model))
    return sub_surface
  end

  def self.indexer(model)
    indexes = [0]
    (model.getSpaces + model.getSurfaces + model.getSubSurfaces).each do |s|
      next if !s.additionalProperties.getFeatureAsInteger('Index').is_initialized

      indexes << s.additionalProperties.getFeatureAsInteger('Index').get
    end
    return indexes.max + 1
  end

  def self.create_single_family_detached(runner:,
                                         model:,
                                         geometry_unit_cfa:,
                                         geometry_average_ceiling_height:,
                                         geometry_unit_num_floors_above_grade:,
                                         geometry_unit_aspect_ratio:,
                                         geometry_garage_width:,
                                         geometry_garage_depth:,
                                         geometry_garage_protrusion:,
                                         geometry_garage_position:,
                                         geometry_foundation_type:,
                                         geometry_foundation_height:,
                                         geometry_rim_joist_height:,
                                         geometry_attic_type:,
                                         geometry_roof_type:,
                                         geometry_roof_pitch:,
                                         **)
    cfa = geometry_unit_cfa
    average_ceiling_height = geometry_average_ceiling_height
    num_floors = geometry_unit_num_floors_above_grade
    aspect_ratio = geometry_unit_aspect_ratio
    garage_width = geometry_garage_width
    garage_depth = geometry_garage_depth
    garage_protrusion = geometry_garage_protrusion
    garage_position = geometry_garage_position
    foundation_type = geometry_foundation_type
    foundation_height = geometry_foundation_height
    rim_joist_height = geometry_rim_joist_height
    attic_type = geometry_attic_type
    if attic_type == HPXML::AtticTypeConditioned
      num_floors -= 1
    end
    roof_type = geometry_roof_type
    roof_pitch = geometry_roof_pitch

    # Convert to SI
    cfa = UnitConversions.convert(cfa, 'ft^2', 'm^2')
    average_ceiling_height = UnitConversions.convert(average_ceiling_height, 'ft', 'm')
    garage_width = UnitConversions.convert(garage_width, 'ft', 'm')
    garage_depth = UnitConversions.convert(garage_depth, 'ft', 'm')
    foundation_height = UnitConversions.convert(foundation_height, 'ft', 'm')
    rim_joist_height = UnitConversions.convert(rim_joist_height, 'ft', 'm')

    garage_area = garage_width * garage_depth
    has_garage = false
    if garage_area > 0
      has_garage = true
    end

    # calculate the footprint of the building
    garage_area_inside_footprint = 0
    if has_garage
      garage_area_inside_footprint = garage_area * (1.0 - garage_protrusion)
    end
    bonus_area_above_garage = garage_area * garage_protrusion
    if (foundation_type == HPXML::FoundationTypeBasementConditioned) && (attic_type == HPXML::AtticTypeConditioned)
      footprint = (cfa + 2 * garage_area_inside_footprint - num_floors * bonus_area_above_garage) / (num_floors + 2)
    elsif foundation_type == HPXML::FoundationTypeBasementConditioned
      footprint = (cfa + 2 * garage_area_inside_footprint - (num_floors - 1) * bonus_area_above_garage) / (num_floors + 1)
    elsif attic_type == HPXML::AtticTypeConditioned
      footprint = (cfa + garage_area_inside_footprint - num_floors * bonus_area_above_garage) / (num_floors + 1)
    else
      footprint = (cfa + garage_area_inside_footprint - (num_floors - 1) * bonus_area_above_garage) / num_floors
    end

    # calculate the dimensions of the building
    # we have: (1) aspect_ratio = fb / lr, and (2) footprint = fb * lr
    fb = Math.sqrt(footprint * aspect_ratio)
    lr = footprint / fb
    length = fb
    width = lr

    # error checking
    if ((garage_width >= length) && (garage_depth > 0))
      runner.registerError('Garage is as wide as the single-family detached unit.')
      return false
    end
    if ((((1.0 - garage_protrusion) * garage_depth) >= width) && (garage_width > 0))
      runner.registerError('Garage is as deep as the single-family detached unit.')
      return false
    end

    # create conditioned zone
    conditioned_zone = OpenStudio::Model::ThermalZone.new(model)
    conditioned_zone.setName(HPXML::LocationConditionedSpace)

    # loop through the number of floors
    foundation_polygon_with_wrong_zs = nil
    for floor in (0..num_floors - 1)
      z = average_ceiling_height * floor + rim_joist_height

      if has_garage && (z == rim_joist_height) # first floor and has garage

        # create garage zone
        garage_space_name = HPXML::LocationGarage
        garage_zone = OpenStudio::Model::ThermalZone.new(model)
        garage_zone.setName(garage_space_name)

        # make points and polygons
        if garage_position == 'Right'
          garage_sw_point = OpenStudio::Point3d.new(length - garage_width, -garage_protrusion * garage_depth, z)
          garage_nw_point = OpenStudio::Point3d.new(length - garage_width, garage_depth - garage_protrusion * garage_depth, z)
          garage_ne_point = OpenStudio::Point3d.new(length, garage_depth - garage_protrusion * garage_depth, z)
          garage_se_point = OpenStudio::Point3d.new(length, -garage_protrusion * garage_depth, z)
          garage_polygon = make_polygon(garage_sw_point, garage_nw_point, garage_ne_point, garage_se_point)
        elsif garage_position == 'Left'
          garage_sw_point = OpenStudio::Point3d.new(0, -garage_protrusion * garage_depth, z)
          garage_nw_point = OpenStudio::Point3d.new(0, garage_depth - garage_protrusion * garage_depth, z)
          garage_ne_point = OpenStudio::Point3d.new(garage_width, garage_depth - garage_protrusion * garage_depth, z)
          garage_se_point = OpenStudio::Point3d.new(garage_width, -garage_protrusion * garage_depth, z)
          garage_polygon = make_polygon(garage_sw_point, garage_nw_point, garage_ne_point, garage_se_point)
        end

        # make space
        garage_space = OpenStudio::Model::Space::fromFloorPrint(garage_polygon, average_ceiling_height, model)
        garage_space = garage_space.get
        assign_indexes(model, garage_polygon, garage_space)
        garage_space.setName(garage_space_name)
        garage_space_type = OpenStudio::Model::SpaceType.new(model)
        garage_space_type.setStandardsSpaceType(garage_space_name)
        garage_space.setSpaceType(garage_space_type)

        # set this to the garage zone
        garage_space.setThermalZone(garage_zone)

        m = initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
        m[2, 3] = z
        garage_space.changeTransformation(OpenStudio::Transformation.new(m))

        if garage_position == 'Right'
          sw_point = OpenStudio::Point3d.new(0, 0, z)
          nw_point = OpenStudio::Point3d.new(0, width, z)
          ne_point = OpenStudio::Point3d.new(length, width, z)
          se_point = OpenStudio::Point3d.new(length, 0, z)
          l_se_point = OpenStudio::Point3d.new(length - garage_width, 0, z)
          if ((garage_depth < width) || (garage_protrusion > 0)) && (garage_protrusion < 1) # garage protrudes but not fully
            conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, garage_ne_point, garage_nw_point, l_se_point)
          elsif garage_protrusion < 1 # garage fits perfectly within conditioned space
            conditioned_polygon = make_polygon(sw_point, nw_point, garage_nw_point, garage_sw_point)
          else # garage fully protrudes
            conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)
          end
        elsif garage_position == 'Left'
          sw_point = OpenStudio::Point3d.new(0, 0, z)
          nw_point = OpenStudio::Point3d.new(0, width, z)
          ne_point = OpenStudio::Point3d.new(length, width, z)
          se_point = OpenStudio::Point3d.new(length, 0, z)
          l_sw_point = OpenStudio::Point3d.new(garage_width, 0, z)
          if ((garage_depth < width) || (garage_protrusion > 0)) && (garage_protrusion < 1) # garage protrudes but not fully
            conditioned_polygon = make_polygon(garage_nw_point, nw_point, ne_point, se_point, l_sw_point, garage_ne_point)
          elsif garage_protrusion < 1 # garage fits perfectly within conditioned space
            conditioned_polygon = make_polygon(garage_se_point, garage_ne_point, ne_point, se_point)
          else # garage fully protrudes
            conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)
          end
        end
        foundation_polygon_with_wrong_zs = conditioned_polygon
      else # first floor without garage or above first floor

        if has_garage
          garage_se_point = OpenStudio::Point3d.new(garage_se_point.x, garage_se_point.y, z)
          garage_sw_point = OpenStudio::Point3d.new(garage_sw_point.x, garage_sw_point.y, z)
          garage_nw_point = OpenStudio::Point3d.new(garage_nw_point.x, garage_nw_point.y, z)
          garage_ne_point = OpenStudio::Point3d.new(garage_ne_point.x, garage_ne_point.y, z)
          if garage_position == 'Right'
            sw_point = OpenStudio::Point3d.new(0, 0, z)
            nw_point = OpenStudio::Point3d.new(0, width, z)
            ne_point = OpenStudio::Point3d.new(length, width, z)
            se_point = OpenStudio::Point3d.new(length, 0, z)
            l_se_point = OpenStudio::Point3d.new(length - garage_width, 0, z)
            if garage_protrusion > 0 # garage protrudes
              conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, garage_se_point, garage_sw_point, l_se_point)
            else # garage does not protrude
              conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)
            end
          elsif garage_position == 'Left'
            sw_point = OpenStudio::Point3d.new(0, 0, z)
            nw_point = OpenStudio::Point3d.new(0, width, z)
            ne_point = OpenStudio::Point3d.new(length, width, z)
            se_point = OpenStudio::Point3d.new(length, 0, z)
            l_sw_point = OpenStudio::Point3d.new(garage_width, 0, z)
            if garage_protrusion > 0 # garage protrudes
              conditioned_polygon = make_polygon(garage_sw_point, nw_point, ne_point, se_point, l_sw_point, garage_se_point)
            else # garage does not protrude
              conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)
            end
          end

        else

          sw_point = OpenStudio::Point3d.new(0, 0, z)
          nw_point = OpenStudio::Point3d.new(0, width, z)
          ne_point = OpenStudio::Point3d.new(length, width, z)
          se_point = OpenStudio::Point3d.new(length, 0, z)
          conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)
          if z == rim_joist_height
            foundation_polygon_with_wrong_zs = conditioned_polygon
          end

        end

      end

      # make space
      conditioned_space = OpenStudio::Model::Space::fromFloorPrint(conditioned_polygon, average_ceiling_height, model)
      conditioned_space = conditioned_space.get
      assign_indexes(model, conditioned_polygon, conditioned_space)

      if floor > 0
        conditioned_space_name = "#{HPXML::LocationConditionedSpace}|story #{floor + 1}"
      else
        conditioned_space_name = HPXML::LocationConditionedSpace
      end
      conditioned_space.setName(conditioned_space_name)
      conditioned_space_type = OpenStudio::Model::SpaceType.new(model)
      conditioned_space_type.setStandardsSpaceType(HPXML::LocationConditionedSpace)
      conditioned_space.setSpaceType(conditioned_space_type)

      # set these to the conditioned zone
      conditioned_space.setThermalZone(conditioned_zone)

      m = initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
      m[2, 3] = z
      conditioned_space.changeTransformation(OpenStudio::Transformation.new(m))
    end

    # Attic
    if attic_type != HPXML::AtticTypeFlatRoof

      z += average_ceiling_height

      # calculate the dimensions of the attic
      if length >= width
        attic_height = (width / 2.0) * roof_pitch
      else
        attic_height = (length / 2.0) * roof_pitch
      end

      # make points
      roof_nw_point = OpenStudio::Point3d.new(0, width, z)
      roof_ne_point = OpenStudio::Point3d.new(length, width, z)
      roof_se_point = OpenStudio::Point3d.new(length, 0, z)
      roof_sw_point = OpenStudio::Point3d.new(0, 0, z)

      # make polygons
      polygon_floor = make_polygon(roof_nw_point, roof_ne_point, roof_se_point, roof_sw_point)
      side_type = nil
      if roof_type == 'gable'
        if length >= width
          roof_w_point = OpenStudio::Point3d.new(0, width / 2.0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length, width / 2.0, z + attic_height)
          polygon_s_roof = make_polygon(roof_e_point, roof_w_point, roof_sw_point, roof_se_point)
          polygon_n_roof = make_polygon(roof_w_point, roof_e_point, roof_ne_point, roof_nw_point)
          polygon_w_wall = make_polygon(roof_w_point, roof_nw_point, roof_sw_point)
          polygon_e_wall = make_polygon(roof_e_point, roof_se_point, roof_ne_point)
        else
          roof_w_point = OpenStudio::Point3d.new(length / 2.0, 0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length / 2.0, width, z + attic_height)
          polygon_s_roof = make_polygon(roof_e_point, roof_w_point, roof_se_point, roof_ne_point)
          polygon_n_roof = make_polygon(roof_w_point, roof_e_point, roof_nw_point, roof_sw_point)
          polygon_w_wall = make_polygon(roof_w_point, roof_sw_point, roof_se_point)
          polygon_e_wall = make_polygon(roof_e_point, roof_ne_point, roof_nw_point)
        end
        side_type = 'Wall'
      elsif roof_type == 'hip'
        if length >= width
          roof_w_point = OpenStudio::Point3d.new(width / 2.0, width / 2.0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length - width / 2.0, width / 2.0, z + attic_height)
          polygon_s_roof = make_polygon(roof_e_point, roof_w_point, roof_sw_point, roof_se_point)
          polygon_n_roof = make_polygon(roof_w_point, roof_e_point, roof_ne_point, roof_nw_point)
          polygon_w_wall = make_polygon(roof_w_point, roof_nw_point, roof_sw_point)
          polygon_e_wall = make_polygon(roof_e_point, roof_se_point, roof_ne_point)
        else
          roof_w_point = OpenStudio::Point3d.new(length / 2.0, length / 2.0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length / 2.0, width - length / 2.0, z + attic_height)
          polygon_s_roof = make_polygon(roof_e_point, roof_w_point, roof_se_point, roof_ne_point)
          polygon_n_roof = make_polygon(roof_w_point, roof_e_point, roof_nw_point, roof_sw_point)
          polygon_w_wall = make_polygon(roof_w_point, roof_sw_point, roof_se_point)
          polygon_e_wall = make_polygon(roof_e_point, roof_ne_point, roof_nw_point)
        end
        side_type = 'RoofCeiling'
      end

      # make surfaces
      surface_floor = create_surface(polygon_floor, model)
      surface_floor.setSurfaceType('Floor')
      surface_floor.setOutsideBoundaryCondition('Surface')
      surface_n_roof = create_surface(polygon_n_roof, model)
      surface_n_roof.setSurfaceType('RoofCeiling')
      surface_n_roof.setOutsideBoundaryCondition('Outdoors')
      surface_e_wall = create_surface(polygon_e_wall, model)
      surface_e_wall.setSurfaceType(side_type)
      surface_e_wall.setOutsideBoundaryCondition('Outdoors')
      surface_s_roof = create_surface(polygon_s_roof, model)
      surface_s_roof.setSurfaceType('RoofCeiling')
      surface_s_roof.setOutsideBoundaryCondition('Outdoors')
      surface_w_wall = create_surface(polygon_w_wall, model)
      surface_w_wall.setSurfaceType(side_type)
      surface_w_wall.setOutsideBoundaryCondition('Outdoors')

      # assign surfaces to the space
      attic_space = create_space(model)
      surface_floor.setSpace(attic_space)
      surface_s_roof.setSpace(attic_space)
      surface_n_roof.setSpace(attic_space)
      surface_w_wall.setSpace(attic_space)
      surface_e_wall.setSpace(attic_space)

      # set these to the attic zone
      if (attic_type == HPXML::AtticTypeVented) || (attic_type == HPXML::AtticTypeUnvented)
        # create attic zone
        attic_zone = OpenStudio::Model::ThermalZone.new(model)
        attic_space.setThermalZone(attic_zone)
        if attic_type == HPXML::AtticTypeVented
          attic_space_name = HPXML::LocationAtticVented
        elsif attic_type == HPXML::AtticTypeUnvented
          attic_space_name = HPXML::LocationAtticUnvented
        end
        attic_zone.setName(attic_space_name)
      elsif attic_type == HPXML::AtticTypeConditioned
        attic_space.setThermalZone(conditioned_zone)
        attic_space_name = HPXML::LocationConditionedSpace
      end
      attic_space.setName(attic_space_name)
      attic_space_type = OpenStudio::Model::SpaceType.new(model)
      attic_space_type.setStandardsSpaceType(attic_space_name)
      attic_space.setSpaceType(attic_space_type)

      m = initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
      m[2, 3] = z
      attic_space.changeTransformation(OpenStudio::Transformation.new(m))

    end

    # Foundation
    if [HPXML::FoundationTypeCrawlspaceVented,
        HPXML::FoundationTypeCrawlspaceUnvented,
        HPXML::FoundationTypeCrawlspaceConditioned,
        HPXML::FoundationTypeBasementUnconditioned,
        HPXML::FoundationTypeBasementConditioned,
        HPXML::FoundationTypeAmbient].include?(foundation_type) || foundation_type.start_with?(HPXML::FoundationTypeBellyAndWing)

      z = -foundation_height

      # create foundation zone
      foundation_zone = OpenStudio::Model::ThermalZone.new(model)

      # make polygons
      p = OpenStudio::Point3dVector.new
      foundation_polygon_with_wrong_zs.each do |point|
        p << OpenStudio::Point3d.new(point.x, point.y, z)
      end
      foundation_polygon = p

      # make space
      foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_polygon, foundation_height, model)
      foundation_space = foundation_space.get
      assign_indexes(model, foundation_polygon, foundation_space)
      if foundation_type == HPXML::FoundationTypeCrawlspaceVented
        foundation_space_name = HPXML::LocationCrawlspaceVented
      elsif foundation_type == HPXML::FoundationTypeCrawlspaceUnvented
        foundation_space_name = HPXML::LocationCrawlspaceUnvented
      elsif foundation_type == HPXML::FoundationTypeCrawlspaceConditioned
        foundation_space_name = HPXML::LocationCrawlspaceConditioned
      elsif foundation_type == HPXML::FoundationTypeBasementUnconditioned
        foundation_space_name = HPXML::LocationBasementUnconditioned
      elsif foundation_type == HPXML::FoundationTypeBasementConditioned
        foundation_space_name = HPXML::LocationBasementConditioned
      elsif foundation_type == HPXML::FoundationTypeAmbient
        foundation_space_name = HPXML::LocationOutside
      elsif foundation_type.start_with?(HPXML::FoundationTypeBellyAndWing)
        foundation_space_name = HPXML::LocationManufacturedHomeUnderBelly
      end
      foundation_zone.setName(foundation_space_name)
      foundation_space.setName(foundation_space_name)
      foundation_space_type = OpenStudio::Model::SpaceType.new(model)
      foundation_space_type.setStandardsSpaceType(foundation_space_name)
      foundation_space.setSpaceType(foundation_space_type)

      # set these to the foundation zone
      foundation_space.setThermalZone(foundation_zone)

      # set foundation walls outside boundary condition
      spaces = model.getSpaces
      spaces.each do |space|
        next unless get_space_floor_z(space) + UnitConversions.convert(space.zOrigin, 'm', 'ft') < 0

        surfaces = space.surfaces
        surfaces.each do |surface|
          next if surface.surfaceType.downcase != 'wall'

          surface.setOutsideBoundaryCondition('Ground')
        end
      end

      m = initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
      m[2, 3] = z
      foundation_space.changeTransformation(OpenStudio::Transformation.new(m))

      # Rim Joist
      add_rim_joist(model, foundation_polygon_with_wrong_zs, foundation_space, rim_joist_height, foundation_height)
    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    if has_garage && attic_type != HPXML::AtticTypeFlatRoof
      if num_floors > 1
        space_with_roof_over_garage = conditioned_space
      else
        space_with_roof_over_garage = garage_space
      end
      space_with_roof_over_garage.surfaces.each do |surface|
        next unless (surface.surfaceType.downcase == 'roofceiling') && (surface.outsideBoundaryCondition.downcase == 'outdoors')

        n_points = []
        s_points = []
        surface.vertices.each do |vertex|
          if vertex.y.abs < 0.00001
            n_points << vertex
          elsif vertex.y < 0
            s_points << vertex
          end
        end
        if n_points[0].x > n_points[1].x
          nw_point = n_points[1]
          ne_point = n_points[0]
        else
          nw_point = n_points[0]
          ne_point = n_points[1]
        end
        if s_points[0].x > s_points[1].x
          sw_point = s_points[1]
          se_point = s_points[0]
        else
          sw_point = s_points[0]
          se_point = s_points[1]
        end

        if num_floors == 1
          nw_point = OpenStudio::Point3d.new(nw_point.x, nw_point.y, conditioned_space.zOrigin + nw_point.z)
          ne_point = OpenStudio::Point3d.new(ne_point.x, ne_point.y, conditioned_space.zOrigin + ne_point.z)
          sw_point = OpenStudio::Point3d.new(sw_point.x, sw_point.y, conditioned_space.zOrigin + sw_point.z)
          se_point = OpenStudio::Point3d.new(se_point.x, se_point.y, conditioned_space.zOrigin + se_point.z)
        else
          nw_point = OpenStudio::Point3d.new(nw_point.x, nw_point.y, num_floors * nw_point.z + rim_joist_height)
          ne_point = OpenStudio::Point3d.new(ne_point.x, ne_point.y, num_floors * ne_point.z + rim_joist_height)
          sw_point = OpenStudio::Point3d.new(sw_point.x, sw_point.y, num_floors * sw_point.z + rim_joist_height)
          se_point = OpenStudio::Point3d.new(se_point.x, se_point.y, num_floors * se_point.z + rim_joist_height)
        end

        garage_attic_height = (ne_point.x - nw_point.x) / 2 * roof_pitch

        if garage_attic_height >= attic_height
          garage_attic_height = attic_height - 0.01 # garage attic height slightly below attic height so that we don't get any roof decks with only three vertices
          garage_roof_pitch = garage_attic_height / (garage_width / 2)
          runner.registerWarning("The garage pitch was changed to accommodate garage ridge >= house ridge (from #{roof_pitch.round(3)} to #{garage_roof_pitch.round(3)}).")
        end

        if num_floors == 1
          if not attic_type == HPXML::AtticTypeConditioned
            roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x) / 2, nw_point.y + garage_attic_height / roof_pitch, conditioned_space.zOrigin + average_ceiling_height + garage_attic_height)
            roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x) / 2, sw_point.y, conditioned_space.zOrigin + average_ceiling_height + garage_attic_height)
          else
            roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x) / 2, nw_point.y + garage_attic_height / roof_pitch, garage_attic_height + average_ceiling_height)
            roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x) / 2, sw_point.y, garage_attic_height + average_ceiling_height)
          end
        else
          roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x) / 2, nw_point.y + garage_attic_height / roof_pitch, num_floors * average_ceiling_height + garage_attic_height + rim_joist_height)
          roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x) / 2, sw_point.y, num_floors * average_ceiling_height + garage_attic_height + rim_joist_height)
        end

        polygon_w_roof = make_polygon(nw_point, sw_point, roof_s_point, roof_n_point)
        polygon_e_roof = make_polygon(ne_point, roof_n_point, roof_s_point, se_point)
        polygon_n_wall = make_polygon(nw_point, roof_n_point, ne_point)
        polygon_s_wall = make_polygon(sw_point, se_point, roof_s_point)

        wall_n = create_surface(polygon_n_wall, model)
        wall_n.setSurfaceType('Wall')
        deck_e = create_surface(polygon_e_roof, model)
        deck_e.setSurfaceType('RoofCeiling')
        deck_e.setOutsideBoundaryCondition('Outdoors')
        wall_s = create_surface(polygon_s_wall, model)
        wall_s.setSurfaceType('Wall')
        wall_s.setOutsideBoundaryCondition('Outdoors')
        deck_w = create_surface(polygon_w_roof, model)
        deck_w.setSurfaceType('RoofCeiling')
        deck_w.setOutsideBoundaryCondition('Outdoors')

        garage_attic_space = create_space(model)
        deck_w.setSpace(garage_attic_space)
        deck_e.setSpace(garage_attic_space)
        wall_n.setSpace(garage_attic_space)
        wall_s.setSpace(garage_attic_space)

        if attic_type == HPXML::AtticTypeConditioned
          garage_attic_space_name = attic_space_name
          garage_attic_space.setThermalZone(conditioned_zone)
        else
          if num_floors > 1
            garage_attic_space_name = attic_space_name
            garage_attic_space.setThermalZone(attic_zone)
          else
            garage_attic_space_name = garage_space_name
            garage_attic_space.setThermalZone(garage_zone)
          end
        end

        surface.createAdjacentSurface(garage_attic_space) # garage attic floor
        surface.adjacentSurface.get.additionalProperties.setFeature('Index', indexer(model))
        garage_attic_space.setName(garage_attic_space_name)
        garage_attic_space_type = OpenStudio::Model::SpaceType.new(model)
        garage_attic_space_type.setStandardsSpaceType(garage_attic_space_name)
        garage_attic_space.setSpaceType(garage_attic_space_type)

        # put all of the spaces in the model into a vector
        spaces = OpenStudio::Model::SpaceVector.new
        model.getSpaces.each do |space|
          spaces << space
        end

        # intersect and match surfaces for each space in the vector
        OpenStudio::Model.intersectSurfaces(spaces)
        OpenStudio::Model.matchSurfaces(spaces)

        # remove triangular surface between unconditioned attic and garage attic
        unless attic_space.nil?
          attic_space.surfaces.each do |surface|
            next if roof_type == 'hip'
            next unless surface.vertices.length == 3
            next unless (90 - surface.tilt * 180 / Math::PI).abs > 0.01 # don't remove the vertical attic walls
            next unless surface.adjacentSurface.is_initialized

            surface.adjacentSurface.get.remove
            surface.remove
          end
        end

        garage_attic_space.surfaces.each do |surface|
          m = initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
          m[2, 3] = -attic_space.zOrigin
          transformation = OpenStudio::Transformation.new(m)
          new_vertices = transformation * surface.vertices
          surface.setVertices(new_vertices)
          surface.setSpace(attic_space)
        end

        garage_attic_space.remove

        # remove other unused surfaces
        # TODO: remove this once geometry methods are fixed in openstudio 3.x
        attic_space.surfaces.each do |surface1|
          next if surface1.surfaceType != 'RoofCeiling'

          attic_space.surfaces.each do |surface2|
            next if surface2.surfaceType != 'RoofCeiling'
            next if surface1 == surface2

            if has_same_vertices(surface1, surface2)
              surface1.remove
              surface2.remove
            end
          end
        end

        break
      end
    end

    garage_spaces = get_garage_spaces(model.getSpaces)

    # set foundation outside boundary condition to Kiva "foundation"
    model.getSurfaces.each do |surface|
      if surface.outsideBoundaryCondition.downcase == 'ground'
        surface.setOutsideBoundaryCondition('Foundation') if foundation_type != HPXML::FoundationTypeAmbient
        surface.setOutsideBoundaryCondition('Outdoors') if foundation_type == HPXML::FoundationTypeAmbient
      elsif (UnitConversions.convert(rim_joist_height, 'm', 'ft') - get_surface_height(surface)).abs < 0.001
        next if surface.surfaceType.downcase != 'wall'

        garage_spaces.each do |garage_space|
          garage_space.surfaces.each do |garage_surface|
            next if garage_surface.surfaceType.downcase != 'floor'

            if get_walls_connected_to_floor([surface], garage_surface, false).include? surface
              surface.setOutsideBoundaryCondition('Foundation') if foundation_type != HPXML::FoundationTypeAmbient
              surface.setOutsideBoundaryCondition('Outdoors') if foundation_type == HPXML::FoundationTypeAmbient
            end
          end
        end
      end
    end

    # set foundation walls adjacent to garage to adiabatic
    foundation_walls = []
    model.getSurfaces.each do |surface|
      next if surface.surfaceType.downcase != 'wall'
      next if surface.outsideBoundaryCondition.downcase != 'foundation'

      foundation_walls << surface
    end

    garage_spaces.each do |garage_space|
      garage_space.surfaces.each do |surface|
        next if surface.surfaceType.downcase != 'floor'

        adjacent_wall_surfaces = get_walls_connected_to_floor(foundation_walls, surface, false)
        adjacent_wall_surfaces.each do |adjacent_wall_surface|
          adjacent_wall_surface.setOutsideBoundaryCondition('Adiabatic')
        end
      end
    end

    assign_remaining_surface_indexes(model)

    apply_ambient_foundation_shift(model, foundation_type, foundation_height)

    return true
  end

  def self.has_same_vertices(surface1, surface2)
    if get_surface_x_values([surface1]).sort == get_surface_x_values([surface2]).sort &&
       get_surface_y_values([surface1]).sort == get_surface_y_values([surface2]).sort &&
       get_surface_z_values([surface1]).sort == get_surface_z_values([surface2]).sort &&
       surface1.space.get.zOrigin.round(5) == surface2.space.get.zOrigin.round(5)
      return true
    end

    return false
  end

  def self.make_polygon(*pts)
    p = OpenStudio::Point3dVector.new
    pts.each do |pt|
      p << pt
    end
    return p
  end

  def self.initialize_transformation_matrix(m)
    m[0, 0] = 1
    m[1, 1] = 1
    m[2, 2] = 1
    m[3, 3] = 1
    return m
  end

  def self.get_space_floor_z(space)
    space.surfaces.each do |surface|
      next unless surface.surfaceType.downcase == 'floor'

      return get_surface_z_values([surface])[0]
    end
  end

  def self.create_windows_and_skylights(runner:,
                                        model:,
                                        window_front_wwr:,
                                        window_back_wwr:,
                                        window_left_wwr:,
                                        window_right_wwr:,
                                        window_area_front:,
                                        window_area_back:,
                                        window_area_left:,
                                        window_area_right:,
                                        window_aspect_ratio:,
                                        skylight_area_front:,
                                        skylight_area_back:,
                                        skylight_area_left:,
                                        skylight_area_right:,
                                        **)
    facades = [Constants.FacadeBack, Constants.FacadeRight, Constants.FacadeFront, Constants.FacadeLeft]

    wwrs = {}
    wwrs[Constants.FacadeBack] = window_back_wwr
    wwrs[Constants.FacadeRight] = window_right_wwr
    wwrs[Constants.FacadeFront] = window_front_wwr
    wwrs[Constants.FacadeLeft] = window_left_wwr
    window_areas = {}
    window_areas[Constants.FacadeBack] = window_area_back
    window_areas[Constants.FacadeRight] = window_area_right
    window_areas[Constants.FacadeFront] = window_area_front
    window_areas[Constants.FacadeLeft] = window_area_left

    skylight_areas = {}
    skylight_areas[Constants.FacadeBack] = skylight_area_back
    skylight_areas[Constants.FacadeRight] = skylight_area_right
    skylight_areas[Constants.FacadeFront] = skylight_area_front
    skylight_areas[Constants.FacadeLeft] = skylight_area_left
    skylight_areas['none'] = 0

    # Store surfaces that should get windows by facade
    wall_surfaces = { Constants.FacadeFront => [], Constants.FacadeBack => [],
                      Constants.FacadeLeft => [], Constants.FacadeRight => [] }
    roof_surfaces = { Constants.FacadeFront => [], Constants.FacadeBack => [],
                      Constants.FacadeLeft => [], Constants.FacadeRight => [],
                      'none' => [] }

    sorted_spaces = model.getSpaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
    get_conditioned_spaces(sorted_spaces).each do |space|
      sorted_surfaces = space.surfaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
      sorted_surfaces.each do |surface|
        next unless (surface.surfaceType.downcase == 'wall') && (surface.outsideBoundaryCondition.downcase == 'outdoors')
        next if (90 - surface.tilt * 180 / Math::PI).abs > 0.01 # Not a vertical wall

        facade = get_facade_for_surface(surface)
        next if facade.nil?

        wall_surfaces[facade] << surface
      end
    end
    sorted_spaces.each do |space|
      sorted_surfaces = space.surfaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
      sorted_surfaces.each do |surface|
        next unless (surface.surfaceType.downcase == 'roofceiling') && (surface.outsideBoundaryCondition.downcase == 'outdoors')

        facade = get_facade_for_surface(surface)
        if facade.nil?
          if surface.tilt == 0 # flat roof
            roof_surfaces['none'] << surface
          end
          next
        end
        roof_surfaces[facade] << surface
      end
    end

    # error checking
    facades.each do |facade|
      if (wwrs[facade] > 0) && (window_areas[facade] > 0)
        runner.registerError("Both #{facade} window-to-wall ratio and #{facade} window area are specified.")
        return false
      elsif (wwrs[facade] < 0) || (wwrs[facade] >= 1)
        runner.registerError("#{facade.capitalize} window-to-wall ratio must be greater than or equal to 0 and less than 1.")
        return false
      elsif window_areas[facade] < 0
        runner.registerError("#{facade.capitalize} window area must be greater than or equal to 0.")
        return false
      elsif skylight_areas[facade] < 0
        runner.registerError("#{facade.capitalize} skylight area must be greater than or equal to 0.")
        return false
      end
    end

    # Split any surfaces that have doors so that we can ignore them when adding windows
    facades.each do |facade|
      wall_surfaces[facade].each do |surface|
        next if surface.subSurfaces.size == 0

        new_surfaces = surface.splitSurfaceForSubSurfaces
        new_surfaces.each do |new_surface|
          wall_surfaces[facade] << new_surface
        end
      end
    end

    # Windows

    # Default assumptions
    min_single_window_area = 5.333 # sqft
    max_single_window_area = 12.0 # sqft
    window_gap_y = 1.0 # ft; distance from top of wall
    window_gap_x = 0.2 # ft; distance between windows in a two-window group
    min_average_ceiling_height_for_window = Math.sqrt(max_single_window_area * window_aspect_ratio) + window_gap_y * 1.05 # allow some wall area above/below
    min_window_width = Math.sqrt(min_single_window_area / window_aspect_ratio) * 1.05 # allow some wall area to the left/right

    # Calculate available area for each wall, facade
    surface_avail_area = {}
    facade_avail_area = {}
    facades.each do |facade|
      facade_avail_area[facade] = 0
      wall_surfaces[facade].each do |surface|
        if not surface_avail_area.include? surface
          surface_avail_area[surface] = 0
        end

        area = get_wall_area_for_windows(surface, min_average_ceiling_height_for_window, min_window_width)
        surface_avail_area[surface] += area
        facade_avail_area[facade] += area
      end
    end

    # Initialize
    surface_window_area = {}
    target_facade_areas = {}
    facades.each do |facade|
      target_facade_areas[facade] = 0.0
      wall_surfaces[facade].each do |surface|
        surface_window_area[surface] = 0
      end
    end

    facades.each do |facade|
      # Calculate target window area for this facade
      if wwrs[facade] > 0
        wall_area = 0
        wall_surfaces[facade].each do |surface|
          wall_area += UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2')
        end
        target_facade_areas[facade] += wall_area * wwrs[facade]
      else
        target_facade_areas[facade] += window_areas[facade]
      end
    end

    facades.each do |facade|
      # Initial guess for wall of this facade
      next if facade_avail_area[facade] == 0

      wall_surfaces[facade].each do |surface|
        surface_window_area[surface] += surface_avail_area[surface] / facade_avail_area[facade] * target_facade_areas[facade]
      end

      # If window area for a surface is less than the minimum window area,
      # set the window area to zero and proportionally redistribute to the
      # other surfaces on that facade and unit.

      # Check wall surface areas (by unit/space)
      model.getBuildingUnits.each do |unit|
        wall_surfaces[facade].each_with_index do |surface, surface_num|
          next if surface_window_area[surface] == 0
          next unless unit.spaces.include? surface.space.get # surface belongs to this unit
          next unless surface_window_area[surface] < min_single_window_area

          # Future surfaces are those that have not yet been compared to min_single_window_area
          future_surfaces_area = 0
          wall_surfaces[facade].each_with_index do |future_surface, future_surface_num|
            next if future_surface_num <= surface_num
            next unless unit.spaces.include? future_surface.space.get

            future_surfaces_area += surface_avail_area[future_surface]
          end
          next if future_surfaces_area == 0

          removed_window_area = surface_window_area[surface]
          surface_window_area[surface] = 0

          wall_surfaces[facade].each_with_index do |future_surface, future_surface_num|
            next if future_surface_num <= surface_num
            next unless unit.spaces.include? future_surface.space.get

            surface_window_area[future_surface] += removed_window_area * surface_avail_area[future_surface] / future_surfaces_area
          end
        end
      end
    end

    # Calculate facade areas for each unit
    unit_facade_areas = {}
    unit_wall_surfaces = {}
    model.getBuildingUnits.each do |unit|
      unit_facade_areas[unit] = {}
      unit_wall_surfaces[unit] = {}
      facades.each do |facade|
        unit_facade_areas[unit][facade] = 0
        unit_wall_surfaces[unit][facade] = []
        wall_surfaces[facade].each do |surface|
          next unless unit.spaces.include? surface.space.get

          unit_facade_areas[unit][facade] += surface_window_area[surface]
          unit_wall_surfaces[unit][facade] << surface
        end
      end
    end

    # if the sum of the window areas on the facade are < minimum, move to different facade
    facades.each do |facade|
      model.getBuildingUnits.each do |unit|
        next if unit_facade_areas[unit][facade] == 0
        next unless unit_facade_areas[unit][facade] < min_single_window_area

        new_facade = unit_facade_areas[unit].max_by { |_k, v| v }[0] # move to facade with largest window area
        next if new_facade == facade # can't move to same facade
        next if unit_facade_areas[unit][new_facade] <= unit_facade_areas[unit][facade] # only move to facade with >= window area

        area_moved = unit_facade_areas[unit][facade]
        unit_facade_areas[unit][facade] = 0
        wall_surfaces[facade].each do |surface|
          next unless unit.spaces.include? surface.space.get # surface is in this unit

          surface_window_area[surface] = 0
        end

        unit_facade_areas[unit][new_facade] += area_moved
        sum_window_area = 0
        wall_surfaces[new_facade].each do |surface|
          next unless unit.spaces.include? surface.space.get # surface is in this unit

          sum_window_area += UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2')
        end

        wall_surfaces[new_facade].each do |surface|
          next unless unit.spaces.include? surface.space.get # surface is in this unit

          split_window_area = area_moved * UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2') / sum_window_area
          surface_window_area[surface] += split_window_area
        end

        runner.registerWarning("The #{facade} facade window area (#{area_moved.round(2)} ft2) is less than the minimum window area allowed (#{min_single_window_area.round(2)} ft2), and has been added to the #{new_facade} facade.")
      end
    end

    facades.each do |facade|
      model.getBuildingUnits.each do |unit|
        # Because the above process is calculated based on the order of surfaces, it's possible
        # that we have less area for this facade than we should. If so, redistribute proportionally
        # to all surfaces that have window area.
        sum_window_area = 0
        wall_surfaces[facade].each do |surface|
          next unless unit.spaces.include? surface.space.get

          sum_window_area += surface_window_area[surface]
        end
        next if sum_window_area == 0
        next if unit_facade_areas[unit][facade] < sum_window_area # for cases where window area was added from different facade

        wall_surfaces[facade].each do |surface|
          next unless unit.spaces.include? surface.space.get

          surface_window_area[surface] += surface_window_area[surface] / sum_window_area * (unit_facade_areas[unit][facade] - sum_window_area)
        end
      end
    end

    tot_win_area = 0
    facades.each do |facade|
      facade_win_area = 0
      wall_surfaces[facade].each do |surface|
        next if surface_window_area[surface] == 0
        if not add_windows_to_wall(surface, surface_window_area[surface], window_gap_y, window_gap_x, window_aspect_ratio, max_single_window_area, facade, model, runner)
          return false
        end

        tot_win_area += surface_window_area[surface]
        facade_win_area += surface_window_area[surface]
      end
      if (facade_win_area - target_facade_areas[facade]).abs > 0.1
        runner.registerWarning("Unable to assign appropriate window area for #{facade} facade.")
      end
    end

    # Skylights
    unless roof_surfaces['none'].empty?
      tot_sky_area = 0
      skylight_areas.each do |facade, skylight_area|
        next if facade == 'none'

        skylight_area /= roof_surfaces['none'].length
        skylight_areas['none'] += skylight_area
        skylight_areas[facade] = 0
      end
    end

    tot_sky_area = 0
    skylight_areas.each do |facade, skylight_area|
      next if skylight_area == 0

      surfaces = roof_surfaces[facade]

      if surfaces.empty? && (not facade == 'none')
        runner.registerError("There are no #{facade} roof surfaces, but #{skylight_area} ft^2 of skylights were specified.")
        return false
      end

      surfaces.each do |surface|
        if (UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2') / get_surface_length(surface)) > get_surface_length(surface)
          skylight_aspect_ratio = get_surface_length(surface) / (UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2') / get_surface_length(surface)) # aspect ratio of the roof surface
        else
          skylight_aspect_ratio = (UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2') / get_surface_length(surface)) / get_surface_length(surface) # aspect ratio of the roof surface
        end

        skylight_width = Math.sqrt(UnitConversions.convert(skylight_area, 'ft^2', 'm^2') / skylight_aspect_ratio)
        skylight_length = UnitConversions.convert(skylight_area, 'ft^2', 'm^2') / skylight_width

        skylight_bottom_left = OpenStudio::getCentroid(surface.vertices).get
        leftx = skylight_bottom_left.x
        lefty = skylight_bottom_left.y
        bottomz = skylight_bottom_left.z
        if (facade == Constants.FacadeFront) || (facade == 'none')
          skylight_top_left = OpenStudio::Point3d.new(leftx, lefty + Math.cos(surface.tilt) * skylight_length, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_top_right = OpenStudio::Point3d.new(leftx + skylight_width, lefty + Math.cos(surface.tilt) * skylight_length, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_bottom_right = OpenStudio::Point3d.new(leftx + skylight_width, lefty, bottomz)
        elsif facade == Constants.FacadeBack
          skylight_top_left = OpenStudio::Point3d.new(leftx, lefty - Math.cos(surface.tilt) * skylight_length, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_top_right = OpenStudio::Point3d.new(leftx - skylight_width, lefty - Math.cos(surface.tilt) * skylight_length, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_bottom_right = OpenStudio::Point3d.new(leftx - skylight_width, lefty, bottomz)
        elsif facade == Constants.FacadeLeft
          skylight_top_left = OpenStudio::Point3d.new(leftx + Math.cos(surface.tilt) * skylight_length, lefty, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_top_right = OpenStudio::Point3d.new(leftx + Math.cos(surface.tilt) * skylight_length, lefty - skylight_width, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_bottom_right = OpenStudio::Point3d.new(leftx, lefty - skylight_width, bottomz)
        elsif facade == Constants.FacadeRight
          skylight_top_left = OpenStudio::Point3d.new(leftx - Math.cos(surface.tilt) * skylight_length, lefty, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_top_right = OpenStudio::Point3d.new(leftx - Math.cos(surface.tilt) * skylight_length, lefty + skylight_width, bottomz + Math.sin(surface.tilt) * skylight_length)
          skylight_bottom_right = OpenStudio::Point3d.new(leftx, lefty + skylight_width, bottomz)
        end

        skylight_polygon = OpenStudio::Point3dVector.new
        [skylight_bottom_left, skylight_bottom_right, skylight_top_right, skylight_top_left].each do |skylight_vertex|
          skylight_polygon << skylight_vertex
        end

        sub_surface = create_sub_surface(skylight_polygon, model)
        sub_surface.setName("#{surface.name} - Skylight")
        sub_surface.setSurface(surface)

        tot_sky_area += skylight_area
      end
    end

    if (tot_win_area == 0) && (tot_sky_area == 0)
      runner.registerFinalCondition('No windows or skylights added.')
    end

    return true
  end

  def self.get_wall_area_for_windows(surface, min_average_ceiling_height_for_window, min_window_width)
    # Skip surfaces with doors
    if surface.subSurfaces.size > 0
      return 0.0
    end

    # Only allow on gable and rectangular walls
    if not (is_rectangular_wall(surface) || is_gable_wall(surface))
      return 0.0
    end

    # Can't fit the smallest window?
    if get_surface_length(surface) < min_window_width
      return 0.0
    end

    # Wall too short?
    if min_average_ceiling_height_for_window > get_surface_height(surface)
      return 0.0
    end

    # Gable too short?
    # TODO: super crude safety factor of 1.5
    if is_gable_wall(surface) && (min_average_ceiling_height_for_window > get_surface_height(surface) / 1.5)
      return 0.0
    end

    return UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2')
  end

  def self.add_windows_to_wall(surface, window_area, window_gap_y, window_gap_x, window_aspect_ratio, max_single_window_area, facade, model, runner)
    wall_width = get_surface_length(surface) # ft
    average_ceiling_height = get_surface_height(surface) # ft

    # Calculate number of windows needed
    num_windows = (window_area / max_single_window_area).ceil
    num_window_groups = (num_windows / 2.0).ceil
    num_window_gaps = num_window_groups
    if num_windows % 2 == 1
      num_window_gaps -= 1
    end
    window_width = Math.sqrt((window_area / num_windows.to_f) / window_aspect_ratio)
    window_height = (window_area / num_windows.to_f) / window_width
    width_for_windows = window_width * num_windows.to_f + window_gap_x * num_window_gaps.to_f

    if width_for_windows > wall_width
      surface_area = UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2')
      wwr = window_area / surface_area
      if wwr > 0.90
        runner.registerWarning("Could not fit windows on #{surface.name}; reducing window area to 90% WWR.")
        wwr = 0.90
      end

      # Instead of using this
      # ss_ = surface.setWindowToWallRatio(wwr, offset, true)
      # We offset the vertices towards the centroid to maximize the likelihood of fitting the window area on the surface
      window_vertices = []
      g = surface.centroid
      scale_factor = wwr**0.5

      surface.vertices.each do |vertex|
        # A vertex is a Point3d.
        # A diff from 2 Point3d creates a Vector3d

        # Vector from centroid to vertex (GA, GB, GC, etc)
        centroid_vector = vertex - g

        # Resize the vector (done in place) according to scale_factor
        centroid_vector.setLength(centroid_vector.length * scale_factor)

        # Change the vertex
        vertex = g + centroid_vector

        window_vertices << vertex
      end

      sub_surface = create_sub_surface(window_vertices, model)
      sub_surface.setName("#{surface.name} - Window 1")
      sub_surface.setSurface(surface)
      sub_surface.setSubSurfaceType('FixedWindow')
      return true
    end

    # Position window from top of surface
    win_top = average_ceiling_height - window_gap_y
    if is_gable_wall(surface)
      # For gable surfaces, position windows from bottom of surface so they fit
      win_top = window_height + window_gap_y
    end

    # Groups of two windows
    win_num = 0
    for i in (1..num_window_groups)

      # Center vertex for group
      group_cx = wall_width * i / (num_window_groups + 1).to_f
      group_cy = win_top - window_height / 2.0

      if not ((i == num_window_groups) && (num_windows % 2 == 1))
        # Two windows in group
        win_num += 1
        add_window_to_wall(surface, window_width, window_height, group_cx - window_width / 2.0 - window_gap_x / 2.0, group_cy, win_num, facade, model)
        win_num += 1
        add_window_to_wall(surface, window_width, window_height, group_cx + window_width / 2.0 + window_gap_x / 2.0, group_cy, win_num, facade, model)
      else
        # One window in group
        win_num += 1
        add_window_to_wall(surface, window_width, window_height, group_cx, group_cy, win_num, facade, model)
      end
    end

    return true
  end

  def self.add_window_to_wall(surface, win_width, win_height, win_center_x, win_center_y, win_num, facade, model)
    # Create window vertices in relative coordinates, ft
    upperleft = [win_center_x - win_width / 2.0, win_center_y + win_height / 2.0]
    upperright = [win_center_x + win_width / 2.0, win_center_y + win_height / 2.0]
    lowerright = [win_center_x + win_width / 2.0, win_center_y - win_height / 2.0]
    lowerleft = [win_center_x - win_width / 2.0, win_center_y - win_height / 2.0]

    # Convert to 3D geometry; assign to surface
    window_polygon = OpenStudio::Point3dVector.new
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
    if (facade == Constants.FacadeBack) || (facade == Constants.FacadeLeft)
      leftx = get_surface_x_values([surface]).max
      lefty = get_surface_y_values([surface]).max
    else
      leftx = get_surface_x_values([surface]).min
      lefty = get_surface_y_values([surface]).min
    end
    bottomz = get_surface_z_values([surface]).min
    [upperleft, lowerleft, lowerright, upperright].each do |coord|
      newx = UnitConversions.convert(leftx + multx * coord[0], 'ft', 'm')
      newy = UnitConversions.convert(lefty + multy * coord[0], 'ft', 'm')
      newz = UnitConversions.convert(bottomz + coord[1], 'ft', 'm')
      window_vertex = OpenStudio::Point3d.new(newx, newy, newz)
      window_polygon << window_vertex
    end
    sub_surface = create_sub_surface(window_polygon, model)
    sub_surface.setName("#{surface.name} - Window #{win_num}")
    sub_surface.setSurface(surface)
    sub_surface.setSubSurfaceType('FixedWindow')
  end

  def self.get_conditioned_spaces(spaces)
    conditioned_spaces = []
    spaces.each do |space|
      next unless space.spaceType.get.standardsSpaceType.get == HPXML::LocationConditionedSpace

      conditioned_spaces << space
    end
    return conditioned_spaces
  end

  def self.get_garage_spaces(spaces)
    garage_spaces = []
    spaces.each do |space|
      next unless space.spaceType.get.standardsSpaceType.get == HPXML::LocationGarage

      garage_spaces << space
    end
    return garage_spaces
  end

  def self.is_rectangular_wall(surface)
    if ((surface.surfaceType.downcase != 'wall') || (surface.outsideBoundaryCondition.downcase != 'outdoors'))
      return false
    end
    if surface.vertices.size != 4
      return false
    end

    xvalues = get_surface_x_values([surface])
    yvalues = get_surface_y_values([surface])
    zvalues = get_surface_z_values([surface])
    if not (((xvalues.uniq.size == 1) && (yvalues.uniq.size == 2)) ||
            ((xvalues.uniq.size == 2) && (yvalues.uniq.size == 1)))
      return false
    end
    if not zvalues.uniq.size == 2
      return false
    end

    return true
  end

  def self.is_gable_wall(surface)
    if ((surface.surfaceType.downcase != 'wall') || (surface.outsideBoundaryCondition.downcase != 'outdoors'))
      return false
    end
    if surface.vertices.size != 3
      return false
    end
    if not surface.space.is_initialized
      return false
    end

    space = surface.space.get
    if not space_has_roof(space)
      return false
    end

    return true
  end

  def self.create_doors(runner:,
                        model:,
                        door_area:,
                        **)
    # error checking
    if door_area == 0
      runner.registerFinalCondition('No doors added because door area was set to 0.')
      return true
    end

    door_height = 7 # ft
    door_width = door_area / door_height
    door_offset = 0.5 # ft

    # Get all exterior walls prioritized by front, then back, then left, then right
    facades = [Constants.FacadeFront, Constants.FacadeBack]
    avail_walls = []
    facades.each do |_facade|
      sorted_spaces = model.getSpaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
      get_conditioned_spaces(sorted_spaces).each do |space|
        next if space_is_below_grade(space)

        sorted_surfaces = space.surfaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
        sorted_surfaces.each do |surface|
          next unless get_facade_for_surface(surface) == Constants.FacadeFront
          next unless (surface.outsideBoundaryCondition.downcase == 'outdoors') || (surface.outsideBoundaryCondition.downcase == 'adiabatic')
          next if (90 - surface.tilt * 180 / Math::PI).abs > 0.01 # Not a vertical wall

          avail_walls << surface
        end
      end
      break if avail_walls.size > 0
    end

    # Get subset of exterior walls on lowest story
    min_story_avail_walls = []
    min_story_avail_wall_minz = 99999
    avail_walls.each do |avail_wall|
      zvalues = get_surface_z_values([avail_wall])
      minz = zvalues.min + avail_wall.space.get.zOrigin
      if minz < min_story_avail_wall_minz
        min_story_avail_walls.clear
        min_story_avail_walls << avail_wall
        min_story_avail_wall_minz = minz
      elsif (minz - min_story_avail_wall_minz).abs < 0.001
        min_story_avail_walls << avail_wall
      end
    end

    unit_has_door = true
    if min_story_avail_walls.size == 0
      runner.registerWarning('Could not find appropriate surface for the door. No door was added.')
      unit_has_door = false
    end

    door_sub_surface = nil
    min_story_avail_walls.each do |min_story_avail_wall|
      wall_gross_area = UnitConversions.convert(min_story_avail_wall.grossArea, 'm^2', 'ft^2')

      # Try to place door on any surface with enough area
      next if door_area >= wall_gross_area

      facade = get_facade_for_surface(min_story_avail_wall)

      if (door_offset + door_width) * door_height > wall_gross_area
        # Reduce door offset to fit door on surface
        door_offset = 0
      end

      num_existing_doors_on_this_surface = 0
      min_story_avail_wall.subSurfaces.each do |sub_surface|
        if sub_surface.subSurfaceType.downcase == 'door'
          num_existing_doors_on_this_surface += 1
        end
      end
      new_door_offset = door_offset + (door_offset + door_width) * num_existing_doors_on_this_surface

      # Create door vertices in relative coordinates
      upperleft = [new_door_offset, door_height]
      upperright = [new_door_offset + door_width, door_height]
      lowerright = [new_door_offset + door_width, 0]
      lowerleft = [new_door_offset, 0]

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
      if (facade == Constants.FacadeBack) || (facade == Constants.FacadeLeft)
        leftx = get_surface_x_values([min_story_avail_wall]).max
        lefty = get_surface_y_values([min_story_avail_wall]).max
      else
        leftx = get_surface_x_values([min_story_avail_wall]).min
        lefty = get_surface_y_values([min_story_avail_wall]).min
      end
      bottomz = get_surface_z_values([min_story_avail_wall]).min

      [upperleft, lowerleft, lowerright, upperright].each do |coord|
        newx = UnitConversions.convert(leftx + multx * coord[0], 'ft', 'm')
        newy = UnitConversions.convert(lefty + multy * coord[0], 'ft', 'm')
        newz = UnitConversions.convert(bottomz + coord[1], 'ft', 'm')
        door_vertex = OpenStudio::Point3d.new(newx, newy, newz)
        door_polygon << door_vertex
      end

      door_sub_surface = create_sub_surface(door_polygon, model)
      door_sub_surface.setName("#{min_story_avail_wall.name} - Door")
      door_sub_surface.setSurface(min_story_avail_wall)
      door_sub_surface.setSubSurfaceType('Door')

      break
    end

    if door_sub_surface.nil? && unit_has_door
      runner.registerWarning('Could not find appropriate surface for the door. No door was added.')
    end

    return true
  end

  def self.space_has_roof(space)
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'roofceiling'
      next if surface.outsideBoundaryCondition.downcase != 'outdoors'
      next if surface.tilt == 0

      return true
    end
    return false
  end

  def self.create_single_family_attached(model:,
                                         geometry_unit_cfa:,
                                         geometry_average_ceiling_height:,
                                         geometry_unit_num_floors_above_grade:,
                                         geometry_unit_aspect_ratio:,
                                         geometry_foundation_type:,
                                         geometry_foundation_height:,
                                         geometry_rim_joist_height:,
                                         geometry_attic_type:,
                                         geometry_roof_type:,
                                         geometry_roof_pitch:,
                                         geometry_unit_left_wall_is_adiabatic:,
                                         geometry_unit_right_wall_is_adiabatic:,
                                         geometry_unit_front_wall_is_adiabatic:,
                                         geometry_unit_back_wall_is_adiabatic:,
                                         **)

    cfa = geometry_unit_cfa
    average_ceiling_height = geometry_average_ceiling_height
    num_floors = geometry_unit_num_floors_above_grade
    aspect_ratio = geometry_unit_aspect_ratio
    foundation_type = geometry_foundation_type
    foundation_height = geometry_foundation_height
    rim_joist_height = geometry_rim_joist_height
    attic_type = geometry_attic_type
    if attic_type == HPXML::AtticTypeConditioned
      num_floors -= 1
    end
    roof_type = geometry_roof_type
    roof_pitch = geometry_roof_pitch
    adiabatic_left_wall = geometry_unit_left_wall_is_adiabatic
    adiabatic_right_wall = geometry_unit_right_wall_is_adiabatic
    adiabatic_front_wall = geometry_unit_front_wall_is_adiabatic
    adiabatic_back_wall = geometry_unit_back_wall_is_adiabatic

    # Convert to SI
    cfa = UnitConversions.convert(cfa, 'ft^2', 'm^2')
    average_ceiling_height = UnitConversions.convert(average_ceiling_height, 'ft', 'm')
    foundation_height = UnitConversions.convert(foundation_height, 'ft', 'm')
    rim_joist_height = UnitConversions.convert(rim_joist_height, 'ft', 'm')

    if (foundation_type == HPXML::FoundationTypeBasementConditioned) && (attic_type == HPXML::AtticTypeConditioned)
      footprint = cfa / (num_floors + 2)
    elsif (foundation_type == HPXML::FoundationTypeBasementConditioned) || (attic_type == HPXML::AtticTypeConditioned)
      footprint = cfa / (num_floors + 1)
    else
      footprint = cfa / num_floors
    end

    # calculate the dimensions of the unit
    # we have: (1) aspect_ratio = fb / lr, and (2) footprint = fb * lr
    fb = Math.sqrt(footprint * aspect_ratio)
    lr = footprint / fb
    x = fb
    y = lr

    # create the prototype unit footprint
    nw_point = OpenStudio::Point3d.new(0, 0, rim_joist_height)
    ne_point = OpenStudio::Point3d.new(x, 0, rim_joist_height)
    sw_point = OpenStudio::Point3d.new(0, -y, rim_joist_height)
    se_point = OpenStudio::Point3d.new(x, -y, rim_joist_height)
    conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)

    # foundation
    foundation_polygon = nil
    if (foundation_height > 0) && foundation_polygon.nil?
      foundation_polygon = conditioned_polygon
    end

    # create conditioned zone
    conditioned_zone = OpenStudio::Model::ThermalZone.new(model)
    conditioned_zone.setName(HPXML::LocationConditionedSpace)

    # first floor
    conditioned_space = OpenStudio::Model::Space::fromFloorPrint(conditioned_polygon, average_ceiling_height, model)
    conditioned_space = conditioned_space.get
    assign_indexes(model, conditioned_polygon, conditioned_space)
    conditioned_space.setName(HPXML::LocationConditionedSpace)
    conditioned_space_type = OpenStudio::Model::SpaceType.new(model)
    conditioned_space_type.setStandardsSpaceType(HPXML::LocationConditionedSpace)
    conditioned_space.setSpaceType(conditioned_space_type)
    conditioned_space.setThermalZone(conditioned_zone)

    # Adiabatic surfaces for walls
    adb_facade_hash = { 'left' => adiabatic_left_wall, 'right' => adiabatic_right_wall, 'front' => adiabatic_front_wall, 'back' => adiabatic_back_wall }
    adb_facades = adb_facade_hash.select { |_, v| v == true }.keys

    # Make surfaces adiabatic
    model.getSpaces.each do |space|
      space.surfaces.each do |surface|
        os_facade = get_facade_for_surface(surface)
        next unless surface.surfaceType == 'Wall'
        next unless adb_facades.include? os_facade

        x_ft = UnitConversions.convert(x, 'm', 'ft')
        max_x = get_surface_x_values([surface]).max
        min_x = get_surface_x_values([surface]).min
        next if ((max_x - x_ft).abs >= 0.01) && (min_x > 0)

        surface.setOutsideBoundaryCondition('Adiabatic')
      end
    end

    # additional floors
    for story in 2..num_floors
      new_conditioned_space = conditioned_space.clone.to_Space.get
      assign_indexes(model, conditioned_polygon, new_conditioned_space)
      new_conditioned_space.setName("conditioned space|story #{story}")
      new_conditioned_space.setSpaceType(conditioned_space_type)

      m = initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
      m[2, 3] = average_ceiling_height * (story - 1)
      new_conditioned_space.setTransformation(OpenStudio::Transformation.new(m))
      new_conditioned_space.setThermalZone(conditioned_zone)
    end

    # attic
    attic_spaces = []
    if attic_type != HPXML::AtticTypeFlatRoof
      attic_space = get_attic_space(model, x, y, average_ceiling_height, num_floors, roof_pitch, roof_type, rim_joist_height)
      if attic_type == HPXML::AtticTypeConditioned
        attic_space_name = HPXML::LocationConditionedSpace
        attic_space.setName(attic_space_name)
        attic_space.setThermalZone(conditioned_zone)
        attic_space.setSpaceType(conditioned_space_type)
        attic_space_type = OpenStudio::Model::SpaceType.new(model)
        attic_space_type.setStandardsSpaceType(attic_space_name)
      else
        attic_spaces << attic_space
      end
    end

    # foundation
    if foundation_height > 0

      # foundation front
      foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_polygon, foundation_height, model)
      foundation_space = foundation_space.get
      assign_indexes(model, foundation_polygon, foundation_space)
      m = initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
      m[2, 3] = foundation_height
      foundation_space.changeTransformation(OpenStudio::Transformation.new(m))
      foundation_space.setXOrigin(0)
      foundation_space.setYOrigin(0)
      foundation_space.setZOrigin(0)

      # create foundation zone
      foundation_zone = OpenStudio::Model::ThermalZone.new(model)

      if foundation_type == HPXML::FoundationTypeCrawlspaceVented
        foundation_space_name = HPXML::LocationCrawlspaceVented
      elsif foundation_type == HPXML::FoundationTypeCrawlspaceUnvented
        foundation_space_name = HPXML::LocationCrawlspaceUnvented
      elsif foundation_type == HPXML::FoundationTypeCrawlspaceConditioned
        foundation_space_name = HPXML::LocationCrawlspaceConditioned
      elsif foundation_type == HPXML::FoundationTypeBasementUnconditioned
        foundation_space_name = HPXML::LocationBasementUnconditioned
      elsif foundation_type == HPXML::FoundationTypeBasementConditioned
        foundation_space_name = HPXML::LocationBasementConditioned
      elsif foundation_type == HPXML::FoundationTypeAmbient
        foundation_space_name = HPXML::LocationOutside
      end
      foundation_zone.setName(foundation_space_name)
      foundation_space.setName(foundation_space_name)
      foundation_space_type = OpenStudio::Model::SpaceType.new(model)
      foundation_space_type.setStandardsSpaceType(foundation_space_name)
      foundation_space.setSpaceType(foundation_space_type)

      # set these to the foundation zone
      foundation_space.setThermalZone(foundation_zone)

      # Rim Joist
      add_rim_joist(model, foundation_polygon, foundation_space, rim_joist_height, 0)

      # put all of the spaces in the model into a vector
      spaces = OpenStudio::Model::SpaceVector.new
      model.getSpaces.each do |space|
        spaces << space
      end

      # intersect and match surfaces for each space in the vector
      OpenStudio::Model.intersectSurfaces(spaces)
      OpenStudio::Model.matchSurfaces(spaces)

      # Foundation space boundary conditions
      spaces = model.getSpaces
      spaces.each do |space|
        next unless get_space_floor_z(space) + UnitConversions.convert(space.zOrigin, 'm', 'ft') < 0

        surfaces = space.surfaces
        surfaces.each do |surface|
          next if surface.surfaceType.downcase != 'wall'

          os_facade = get_facade_for_surface(surface)
          if adb_facades.include? os_facade
            surface.setOutsideBoundaryCondition('Adiabatic')
          elsif get_surface_z_values([surface]).min < 0
            surface.setOutsideBoundaryCondition('Foundation') if foundation_type != HPXML::FoundationTypeAmbient
            surface.setOutsideBoundaryCondition('Outdoors') if foundation_type == HPXML::FoundationTypeAmbient
          else
            surface.setOutsideBoundaryCondition('Outdoors')
          end
        end
      end

    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    if [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented].include?(attic_type)
      attic_spaces.each do |attic_space|
        attic_space.remove
      end
      attic_space = get_attic_space(model, x, y, average_ceiling_height, num_floors, roof_pitch, roof_type, rim_joist_height)

      # set these to the attic zone
      if (attic_type == HPXML::AtticTypeVented) || (attic_type == HPXML::AtticTypeUnvented)
        # create attic zone
        attic_zone = OpenStudio::Model::ThermalZone.new(model)
        attic_space.setThermalZone(attic_zone)
        if attic_type == HPXML::AtticTypeVented
          attic_space_name = HPXML::LocationAtticVented
        elsif attic_type == HPXML::AtticTypeUnvented
          attic_space_name = HPXML::LocationAtticUnvented
        end
        attic_zone.setName(attic_space_name)
      end
      attic_space.setName(attic_space_name)
      attic_space_type = OpenStudio::Model::SpaceType.new(model)
      attic_space_type.setStandardsSpaceType(attic_space_name)
      attic_space.setSpaceType(attic_space_type)
    end

    # Adiabatic gable walls
    if [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented, HPXML::AtticTypeConditioned].include? attic_type
      attic_space.surfaces.each do |surface|
        os_facade = get_facade_for_surface(surface)
        next unless surface.surfaceType == 'Wall'
        next unless adb_facades.include? os_facade

        x_ft = UnitConversions.convert(x, 'm', 'ft')
        max_x = get_surface_x_values([surface]).max
        min_x = get_surface_x_values([surface]).min
        next if ((max_x - x_ft).abs >= 0.01) && (min_x > 0)

        surface.setOutsideBoundaryCondition('Adiabatic')
      end
    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    # set foundation outside boundary condition to Kiva "foundation"
    model.getSurfaces.each do |surface|
      next if surface.outsideBoundaryCondition.downcase != 'ground'

      surface.setOutsideBoundaryCondition('Foundation') if foundation_type != HPXML::FoundationTypeAmbient
      surface.setOutsideBoundaryCondition('Outdoors') if foundation_type == HPXML::FoundationTypeAmbient
    end

    assign_remaining_surface_indexes(model)

    apply_ambient_foundation_shift(model, foundation_type, foundation_height)

    return true
  end

  def self.get_attic_space(model, x, y, average_ceiling_height, num_floors, roof_pitch, roof_type, rim_joist_height)
    y_rear = 0
    y_peak = -y / 2
    y_tot = y

    nw_point = OpenStudio::Point3d.new(0, 0, average_ceiling_height * num_floors + rim_joist_height)
    ne_point = OpenStudio::Point3d.new(x, 0, average_ceiling_height * num_floors + rim_joist_height)
    sw_point = OpenStudio::Point3d.new(0, -y, average_ceiling_height * num_floors + rim_joist_height)
    se_point = OpenStudio::Point3d.new(x, -y, average_ceiling_height * num_floors + rim_joist_height)
    attic_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)

    attic_height = (y_tot / 2.0) * roof_pitch + rim_joist_height # Roof always has same orientation

    side_type = nil
    if roof_type == 'gable'
      roof_w_point = OpenStudio::Point3d.new(0, y_peak, average_ceiling_height * num_floors + attic_height)
      roof_e_point = OpenStudio::Point3d.new(x, y_peak, average_ceiling_height * num_floors + attic_height)
      polygon_w_roof = make_polygon(roof_w_point, roof_e_point, ne_point, nw_point)
      polygon_e_roof = make_polygon(roof_e_point, roof_w_point, sw_point, se_point)
      polygon_s_wall = make_polygon(roof_w_point, nw_point, sw_point)
      polygon_n_wall = make_polygon(roof_e_point, se_point, ne_point)
      side_type = 'Wall'
    elsif roof_type == 'hip'
      if y > 0
        if x <= (y + y_rear)
          roof_n_point = OpenStudio::Point3d.new(x / 2.0, y_rear - x / 2.0, average_ceiling_height * num_floors + attic_height)
          roof_s_point = OpenStudio::Point3d.new(x / 2.0, -y + x / 2.0, average_ceiling_height * num_floors + attic_height)
          polygon_w_roof = make_polygon(roof_n_point, nw_point, sw_point, roof_s_point)
          polygon_e_roof = make_polygon(roof_s_point, se_point, ne_point, roof_n_point)
          polygon_s_wall = make_polygon(roof_s_point, sw_point, se_point)
          polygon_n_wall = make_polygon(roof_n_point, ne_point, nw_point)
        else
          roof_w_point = OpenStudio::Point3d.new((y + y_rear) / 2.0, (y_rear - y) / 2.0, average_ceiling_height * num_floors + attic_height)
          roof_e_point = OpenStudio::Point3d.new(x - (y + y_rear) / 2.0, (y_rear - y) / 2.0, average_ceiling_height * num_floors + attic_height)
          polygon_w_roof = make_polygon(roof_w_point, sw_point, se_point, roof_e_point)
          polygon_e_roof = make_polygon(roof_e_point, ne_point, nw_point, roof_w_point)
          polygon_s_wall = make_polygon(roof_e_point, se_point, ne_point)
          polygon_n_wall = make_polygon(roof_w_point, nw_point, sw_point)
        end
      else
        if x <= y.abs
          roof_n_point = OpenStudio::Point3d.new(x / 2.0, -y - x / 2.0, average_ceiling_height * num_floors + attic_height)
          roof_s_point = OpenStudio::Point3d.new(x / 2.0, x / 2.0, average_ceiling_height * num_floors + attic_height)
          polygon_w_roof = make_polygon(roof_n_point, nw_point, sw_point, roof_s_point)
          polygon_e_roof = make_polygon(roof_s_point, se_point, ne_point, roof_n_point)
          polygon_s_wall = make_polygon(roof_s_point, sw_point, se_point)
          polygon_n_wall = make_polygon(roof_n_point, ne_point, nw_point)
        else
          roof_w_point = OpenStudio::Point3d.new(-y / 2.0, -y / 2.0, average_ceiling_height * num_floors + attic_height)
          roof_e_point = OpenStudio::Point3d.new(x + y / 2.0, -y / 2.0, average_ceiling_height * num_floors + attic_height)
          polygon_w_roof = make_polygon(roof_w_point, sw_point, se_point, roof_e_point)
          polygon_e_roof = make_polygon(roof_e_point, ne_point, nw_point, roof_w_point)
          polygon_s_wall = make_polygon(roof_e_point, se_point, ne_point)
          polygon_n_wall = make_polygon(roof_w_point, nw_point, sw_point)
        end
      end
      side_type = 'RoofCeiling'
    end

    surface_floor = create_surface(attic_polygon, model)
    surface_floor.setSurfaceType('Floor')
    surface_floor.setOutsideBoundaryCondition('Surface')
    surface_w_roof = create_surface(polygon_w_roof, model)
    surface_w_roof.setSurfaceType('RoofCeiling')
    surface_w_roof.setOutsideBoundaryCondition('Outdoors')
    surface_e_roof = create_surface(polygon_e_roof, model)
    surface_e_roof.setSurfaceType('RoofCeiling')
    surface_e_roof.setOutsideBoundaryCondition('Outdoors')
    surface_s_wall = create_surface(polygon_s_wall, model)
    surface_s_wall.setSurfaceType(side_type)
    surface_s_wall.setOutsideBoundaryCondition('Outdoors')
    surface_n_wall = create_surface(polygon_n_wall, model)
    surface_n_wall.setSurfaceType(side_type)
    surface_n_wall.setOutsideBoundaryCondition('Outdoors')

    attic_space = create_space(model)

    surface_floor.setSpace(attic_space)
    surface_w_roof.setSpace(attic_space)
    surface_e_roof.setSpace(attic_space)
    surface_s_wall.setSpace(attic_space)
    surface_n_wall.setSpace(attic_space)

    return attic_space
  end

  def self.create_apartment(model:,
                            geometry_unit_cfa:,
                            geometry_average_ceiling_height:,
                            geometry_unit_num_floors_above_grade:,
                            geometry_unit_aspect_ratio:,
                            geometry_foundation_type:,
                            geometry_foundation_height:,
                            geometry_rim_joist_height:,
                            geometry_attic_type:,
                            geometry_roof_type:,
                            geometry_roof_pitch:,
                            geometry_unit_left_wall_is_adiabatic:,
                            geometry_unit_right_wall_is_adiabatic:,
                            geometry_unit_front_wall_is_adiabatic:,
                            geometry_unit_back_wall_is_adiabatic:,
                            **)

    cfa = geometry_unit_cfa
    average_ceiling_height = geometry_average_ceiling_height
    num_floors = geometry_unit_num_floors_above_grade
    aspect_ratio = geometry_unit_aspect_ratio
    foundation_type = geometry_foundation_type
    foundation_height = geometry_foundation_height
    rim_joist_height = geometry_rim_joist_height
    attic_type = geometry_attic_type
    roof_type = geometry_roof_type
    roof_pitch = geometry_roof_pitch
    adiabatic_left_wall = geometry_unit_left_wall_is_adiabatic
    adiabatic_right_wall = geometry_unit_right_wall_is_adiabatic
    adiabatic_front_wall = geometry_unit_front_wall_is_adiabatic
    adiabatic_back_wall = geometry_unit_back_wall_is_adiabatic

    if foundation_type == HPXML::FoundationTypeAboveApartment
      foundation_type = HPXML::LocationOtherHousingUnit
      foundation_height = 0.0
      rim_joist_height = 0.0
    end
    if attic_type == HPXML::AtticTypeBelowApartment
      attic_type = HPXML::LocationOtherHousingUnit
    end

    # Convert to SI
    cfa = UnitConversions.convert(cfa, 'ft^2', 'm^2')
    average_ceiling_height = UnitConversions.convert(average_ceiling_height, 'ft', 'm')
    foundation_height = UnitConversions.convert(foundation_height, 'ft', 'm')
    rim_joist_height = UnitConversions.convert(rim_joist_height, 'ft', 'm')

    # calculate the dimensions of the unit
    # we have: (1) aspect_ratio = fb / lr, and (2) footprint = fb * lr
    footprint = cfa
    fb = Math.sqrt(footprint * aspect_ratio)
    lr = footprint / fb
    x = fb
    y = lr

    foundation_polygon = nil

    # create the prototype unit footprint
    nw_point = OpenStudio::Point3d.new(0, 0, rim_joist_height)
    ne_point = OpenStudio::Point3d.new(x, 0, rim_joist_height)
    sw_point = OpenStudio::Point3d.new(0, -y, rim_joist_height)
    se_point = OpenStudio::Point3d.new(x, -y, rim_joist_height)
    conditioned_polygon = make_polygon(sw_point, nw_point, ne_point, se_point)

    # foundation
    if (foundation_height > 0) && foundation_polygon.nil?
      foundation_polygon = conditioned_polygon
    end

    # create conditioned zone
    conditioned_zone = OpenStudio::Model::ThermalZone.new(model)
    conditioned_zone.setName(HPXML::LocationConditionedSpace)

    # first floor
    conditioned_space = OpenStudio::Model::Space::fromFloorPrint(conditioned_polygon, average_ceiling_height, model)
    conditioned_space = conditioned_space.get
    assign_indexes(model, conditioned_polygon, conditioned_space)
    conditioned_space.setName(HPXML::LocationConditionedSpace)
    conditioned_space_type = OpenStudio::Model::SpaceType.new(model)
    conditioned_space_type.setStandardsSpaceType(HPXML::LocationConditionedSpace)
    conditioned_space.setSpaceType(conditioned_space_type)
    conditioned_space.setThermalZone(conditioned_zone)

    # Map surface facades to adiabatic walls
    adb_facade_hash = { 'left' => adiabatic_left_wall, 'right' => adiabatic_right_wall, 'front' => adiabatic_front_wall, 'back' => adiabatic_back_wall }
    adb_facades = adb_facade_hash.select { |_, v| v == true }.keys

    # Adiabatic floor/ceiling
    adb_levels = []
    if attic_type == HPXML::LocationOtherHousingUnit
      adb_levels += ['RoofCeiling']
    end
    if foundation_type == HPXML::LocationOtherHousingUnit
      adb_levels += ['Floor']
    end

    # Make conditioned space surfaces adiabatic
    model.getSpaces.each do |space|
      space.surfaces.each do |surface|
        os_facade = get_facade_for_surface(surface)
        if surface.surfaceType == 'Wall'
          if adb_facades.include? os_facade
            x_ft = UnitConversions.convert(x, 'm', 'ft')
            max_x = get_surface_x_values([surface]).max
            min_x = get_surface_x_values([surface]).min
            next if ((max_x - x_ft).abs >= 0.01) && (min_x > 0)

            surface.setOutsideBoundaryCondition('Adiabatic')
          end
        else
          if (adb_levels.include? surface.surfaceType)
            surface.setOutsideBoundaryCondition('Adiabatic')
          end
        end
      end
    end

    # attic
    attic_spaces = []
    if [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented].include? attic_type
      attic_space = get_attic_space(model, x, y, average_ceiling_height, num_floors, roof_pitch, roof_type, rim_joist_height)
      attic_spaces << attic_space
    end

    # foundation
    if foundation_height > 0

      # foundation front
      foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_polygon, foundation_height, model)
      foundation_space = foundation_space.get
      assign_indexes(model, foundation_polygon, foundation_space)
      m = initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
      m[2, 3] = foundation_height + rim_joist_height
      foundation_space.changeTransformation(OpenStudio::Transformation.new(m))
      foundation_space.setXOrigin(0)
      foundation_space.setYOrigin(0)
      foundation_space.setZOrigin(0)

      # create foundation zone
      foundation_zone = OpenStudio::Model::ThermalZone.new(model)

      if foundation_type == HPXML::FoundationTypeCrawlspaceVented
        foundation_space_name = HPXML::LocationCrawlspaceVented
      elsif foundation_type == HPXML::FoundationTypeCrawlspaceUnvented
        foundation_space_name = HPXML::LocationCrawlspaceUnvented
      elsif foundation_type == HPXML::FoundationTypeCrawlspaceConditioned
        foundation_space_name = HPXML::LocationCrawlspaceConditioned
      elsif foundation_type == HPXML::FoundationTypeBasementUnconditioned
        foundation_space_name = HPXML::LocationBasementUnconditioned
      elsif foundation_type == HPXML::FoundationTypeBasementConditioned
        foundation_space_name = HPXML::LocationBasementConditioned
      elsif foundation_type == HPXML::FoundationTypeAmbient
        foundation_space_name = HPXML::LocationOutside
      end
      foundation_zone.setName(foundation_space_name)
      foundation_space.setName(foundation_space_name)
      foundation_space_type = OpenStudio::Model::SpaceType.new(model)
      foundation_space_type.setStandardsSpaceType(foundation_space_name)
      foundation_space.setSpaceType(foundation_space_type)

      # set these to the foundation zone
      foundation_space.setThermalZone(foundation_zone)

      # Rim Joist
      add_rim_joist(model, foundation_polygon, foundation_space, rim_joist_height, 0)

      # put all of the spaces in the model into a vector
      spaces = OpenStudio::Model::SpaceVector.new
      model.getSpaces.each do |space|
        spaces << space
      end

      # intersect and match surfaces for each space in the vector
      OpenStudio::Model.intersectSurfaces(spaces)
      OpenStudio::Model.matchSurfaces(spaces)

      # Foundation space boundary conditions
      model.getSpaces.each do |space|
        next unless get_space_floor_z(space) + UnitConversions.convert(space.zOrigin, 'm', 'ft') < 0 # Foundation

        surfaces = space.surfaces
        surfaces.each do |surface|
          next unless surface.surfaceType.downcase == 'wall'

          os_facade = get_facade_for_surface(surface)
          if adb_facades.include?(os_facade) && (os_facade != 'RoofCeiling') && (os_facade != 'Floor')
            surface.setOutsideBoundaryCondition('Adiabatic')
          elsif get_surface_z_values([surface]).min < 0
            surface.setOutsideBoundaryCondition('Foundation') if foundation_type != HPXML::FoundationTypeAmbient
            surface.setOutsideBoundaryCondition('Outdoors') if foundation_type == HPXML::FoundationTypeAmbient
          else
            surface.setOutsideBoundaryCondition('Outdoors')
          end
        end
      end
    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    if [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented].include?(attic_type)
      attic_spaces.each do |attic_space|
        attic_space.remove
      end
      attic_space = get_attic_space(model, x, y, average_ceiling_height, num_floors, roof_pitch, roof_type, rim_joist_height)

      # set these to the attic zone
      if (attic_type == HPXML::AtticTypeVented) || (attic_type == HPXML::AtticTypeUnvented)
        # create attic zone
        attic_zone = OpenStudio::Model::ThermalZone.new(model)
        attic_space.setThermalZone(attic_zone)
        if attic_type == HPXML::AtticTypeVented
          attic_space_name = HPXML::LocationAtticVented
        elsif attic_type == HPXML::AtticTypeUnvented
          attic_space_name = HPXML::LocationAtticUnvented
        end
        attic_zone.setName(attic_space_name)
      end
      attic_space.setName(attic_space_name)
      attic_space_type = OpenStudio::Model::SpaceType.new(model)
      attic_space_type.setStandardsSpaceType(attic_space_name)
      attic_space.setSpaceType(attic_space_type)

      # Adiabatic surfaces for attic walls
      attic_space.surfaces.each do |surface|
        os_facade = get_facade_for_surface(surface)
        next unless surface.surfaceType == 'Wall'
        next unless adb_facades.include? os_facade

        x_ft = UnitConversions.convert(x, 'm', 'ft')
        max_x = get_surface_x_values([surface]).max
        min_x = get_surface_x_values([surface]).min
        next if ((max_x - x_ft).abs >= 0.01) && (min_x > 0)

        surface.setOutsideBoundaryCondition('Adiabatic')
      end
    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    # set foundation outside boundary condition to Kiva "foundation"
    model.getSurfaces.each do |surface|
      next if surface.outsideBoundaryCondition.downcase != 'ground'

      surface.setOutsideBoundaryCondition('Foundation') if foundation_type != HPXML::FoundationTypeAmbient
      surface.setOutsideBoundaryCondition('Outdoors') if foundation_type == HPXML::FoundationTypeAmbient
    end

    assign_remaining_surface_indexes(model)

    apply_ambient_foundation_shift(model, foundation_type, foundation_height)

    return true
  end

  # Shift all spaces up by foundation height for ambient foundation
  def self.apply_ambient_foundation_shift(model, foundation_type, foundation_height)
    if [HPXML::FoundationTypeAmbient, HPXML::FoundationTypeBellyAndWing].include?(foundation_type)
      m = initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
      m[2, 3] = -foundation_height
      model.getSpaces.each do |space|
        space.changeTransformation(OpenStudio::Transformation.new(m))
        space.setXOrigin(0)
        space.setYOrigin(0)
        space.setZOrigin(0)
      end
    end
  end

  # Returns true if space is either fully or partially below grade
  def self.space_is_below_grade(space)
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'wall'
      if surface.outsideBoundaryCondition.downcase == 'foundation'
        return true
      end
    end
    return false
  end

  def self.is_point_between(p, v1, v2)
    # Checks if point p is between points v1 and v2
    is_between = false
    tol = 0.001
    if ((p[2] - v1[2]).abs <= tol) && ((p[2] - v2[2]).abs <= tol) # equal z
      if ((p[0] - v1[0]).abs <= tol) && ((p[0] - v2[0]).abs <= tol) # equal x; vertical
        if (p[1] >= v1[1] - tol) && (p[1] <= v2[1] + tol)
          is_between = true
        elsif (p[1] <= v1[1] + tol) && (p[1] >= v2[1] - tol)
          is_between = true
        end
      elsif ((p[1] - v1[1]).abs <= tol) && ((p[1] - v2[1]).abs <= tol) # equal y; horizontal
        if (p[0] >= v1[0] - tol) && (p[0] <= v2[0] + tol)
          is_between = true
        elsif (p[0] <= v1[0] + tol) && (p[0] >= v2[0] - tol)
          is_between = true
        end
      end
    end
    return is_between
  end

  def self.get_walls_connected_to_floor(wall_surfaces, floor_surface, same_space = true)
    adjacent_wall_surfaces = []

    wall_surfaces.each do |wall_surface|
      if same_space
        next if wall_surface.space.get != floor_surface.space.get
      else
        next if wall_surface.space.get == floor_surface.space.get
      end

      wall_vertices = wall_surface.vertices
      wall_vertices.each_with_index do |wv1, widx|
        wv2 = wall_vertices[widx - 1]
        floor_vertices = floor_surface.vertices
        floor_vertices.each_with_index do |fv1, fidx|
          fv2 = floor_vertices[fidx - 1]
          # Wall within floor edge?
          next unless (is_point_between([wv1.x, wv1.y, wv1.z + wall_surface.space.get.zOrigin],
                                        [fv1.x, fv1.y, fv1.z + floor_surface.space.get.zOrigin],
                                        [fv2.x, fv2.y, fv2.z + floor_surface.space.get.zOrigin]) \
                    && is_point_between([wv2.x, wv2.y, wv2.z + wall_surface.space.get.zOrigin],
                                        [fv1.x, fv1.y, fv1.z + floor_surface.space.get.zOrigin],
                                        [fv2.x, fv2.y, fv2.z + floor_surface.space.get.zOrigin]))

          if not adjacent_wall_surfaces.include? wall_surface
            adjacent_wall_surfaces << wall_surface
          end
        end
      end
    end

    return adjacent_wall_surfaces
  end

  # Takes in a list of floor surfaces for which to calculate the exposed perimeter.
  # Returns the total exposed perimeter.
  # NOTE: Does not work for buildings with non-orthogonal walls.
  def self.calculate_exposed_perimeter(model, ground_floor_surfaces, has_foundation_walls = false)
    perimeter = 0

    # Get ground edges
    if not has_foundation_walls
      # Use edges from floor surface
      ground_edges = get_edges_for_surfaces(ground_floor_surfaces, false)
    else
      # Use top edges from foundation walls instead
      surfaces = []
      ground_floor_surfaces.each do |ground_floor_surface|
        next if not ground_floor_surface.space.is_initialized

        foundation_space = ground_floor_surface.space.get
        wall_surfaces = []
        foundation_space.surfaces.each do |surface|
          next if not surface.surfaceType.downcase == 'wall'
          next if surface.adjacentSurface.is_initialized

          wall_surfaces << surface
        end
        get_walls_connected_to_floor(wall_surfaces, ground_floor_surface).each do |surface|
          next if surfaces.include? surface

          surfaces << surface
        end
      end
      ground_edges = get_edges_for_surfaces(surfaces, true)
    end
    # Get bottom edges of exterior walls (building footprint)
    surfaces = []
    model.getSurfaces.each do |surface|
      next if not surface.surfaceType.downcase == 'wall'
      next if surface.outsideBoundaryCondition.downcase != 'outdoors'

      surfaces << surface
    end
    model_edges = get_edges_for_surfaces(surfaces, false)

    # compare edges for overlap
    ground_edges.each do |e1|
      model_edges.each do |e2|
        next if not is_point_between(e2[0], e1[0], e1[1])
        next if not is_point_between(e2[1], e1[0], e1[1])

        point_one = OpenStudio::Point3d.new(e2[0][0], e2[0][1], e2[0][2])
        point_two = OpenStudio::Point3d.new(e2[1][0], e2[1][1], e2[1][2])
        length = OpenStudio::Vector3d.new(point_one - point_two).length
        perimeter += length
      end
    end

    return UnitConversions.convert(perimeter, 'm', 'ft')
  end

  def self.get_edges_for_surfaces(surfaces, use_top_edge)
    edges = []
    edge_counter = 0
    surfaces.each do |surface|
      if use_top_edge
        matchz = get_surface_z_values([surface]).max
      else
        matchz = get_surface_z_values([surface]).min
      end

      # get vertices
      vertex_hash = {}
      vertex_counter = 0
      surface.vertices.each do |vertex|
        next if (UnitConversions.convert(vertex.z, 'm', 'ft') - matchz).abs > 0.0001 # ensure we only process bottom/top edge of wall surfaces

        vertex_counter += 1
        vertex_hash[vertex_counter] = [vertex.x + surface.space.get.xOrigin,
                                       vertex.y + surface.space.get.yOrigin,
                                       vertex.z + surface.space.get.zOrigin]
      end
      # make edges
      counter = 0
      vertex_hash.values.each do |v|
        edge_counter += 1
        counter += 1
        if vertex_hash.size != counter
          edges << [v, vertex_hash[counter + 1], get_facade_for_surface(surface)]
        elsif vertex_hash.size > 2 # different code for wrap around vertex (if > 2 vertices)
          edges << [v, vertex_hash[1], get_facade_for_surface(surface)]
        end
      end
    end

    return edges
  end

  def self.get_facade_for_surface(surface)
    tol = 0.001
    n = surface.outwardNormal
    facade = nil
    if n.z.abs < tol
      if (n.x.abs < tol) && ((n.y + 1).abs < tol)
        facade = Constants.FacadeFront
      elsif ((n.x - 1).abs < tol) && (n.y.abs < tol)
        facade = Constants.FacadeRight
      elsif (n.x.abs < tol) && ((n.y - 1).abs < tol)
        facade = Constants.FacadeBack
      elsif ((n.x + 1).abs < tol) && (n.y.abs < tol)
        facade = Constants.FacadeLeft
      end
    else
      if (n.x.abs < tol) && (n.y < 0)
        facade = Constants.FacadeFront
      elsif (n.x > 0) && (n.y.abs < tol)
        facade = Constants.FacadeRight
      elsif (n.x.abs < tol) && (n.y > 0)
        facade = Constants.FacadeBack
      elsif (n.x < 0) && (n.y.abs < tol)
        facade = Constants.FacadeLeft
      end
    end
    return facade
  end

  def self.get_conditioned_attic_height(spaces)
    # gable roof type
    get_conditioned_spaces(spaces).each do |space|
      space.surfaces.each do |surface|
        next if surface.vertices.size != 3
        next if surface.outsideBoundaryCondition != 'Outdoors'
        next if surface.surfaceType != 'Wall'

        return get_height_of_spaces([space])
      end
    end

    # hip roof type
    get_conditioned_spaces(spaces).each do |space|
      space.surfaces.each do |surface|
        next if surface.outsideBoundaryCondition != 'Outdoors'
        next if surface.surfaceType != 'RoofCeiling'

        return get_height_of_spaces([space])
      end
    end

    return false
  end

  def self.surface_is_rim_joist(surface, height)
    return false unless (height - get_surface_height(surface)).abs < 0.00001
    return false unless get_surface_z_values([surface]).max > 0

    return true
  end
end
