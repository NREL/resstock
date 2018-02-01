require "#{File.dirname(__FILE__)}/constants"
require "#{File.dirname(__FILE__)}/unit_conversions"

class Geometry

    def self.get_abs_azimuth(azimuth_type, relative_azimuth, building_orientation, offset=180.0)

      azimuth = nil
      if azimuth_type == Constants.CoordRelative
        azimuth = relative_azimuth + building_orientation + offset
      elsif azimuth_type == Constants.CoordAbsolute
        azimuth = relative_azimuth + offset
      end    
      
      # Ensure azimuth is >=0 and <=360
      while azimuth < 0.0
        azimuth += 360.0
      end

      while azimuth >= 360.0
        azimuth -= 360.0
      end

      return azimuth

    end

    def self.get_abs_tilt(tilt_type, relative_tilt, roof_tilt, latitude)
    
      if tilt_type == Constants.TiltPitch
        return relative_tilt + roof_tilt
      elsif tilt_type == Constants.TiltLatitude
        return relative_tilt + latitude
      elsif tilt_type == Constants.CoordAbsolute
        return relative_tilt
      end

    end

    def self.initialize_transformation_matrix(m)
      m[0,0] = 1
      m[1,1] = 1
      m[2,2] = 1
      m[3,3] = 1
      return m
    end

    def self.get_surface_dimensions(surface)
      least_x = 9e99
      greatest_x = -9e99
      least_y = 9e99
      greatest_y = -9e99
      least_z = 9e99
      greatest_z = -9e99
      surface.vertices.each do |vertex|
        least_x = [vertex.x, least_x].min
        greatest_x = [vertex.x, greatest_x].max
        least_y = [vertex.y, least_y].min
        greatest_y = [vertex.y, greatest_y].max
        least_z = [vertex.z, least_z].min
        greatest_z = [vertex.z, greatest_z].max
      end
      l = greatest_x - least_x
      w = greatest_y - least_y
      h = greatest_z - least_z  
      return l, w, h
    end

    def self.get_building_stories(spaces)
      space_min_zs = []
      spaces.each do |space|
        next if not self.space_is_finished(space)
        surfaces_min_zs = []
        space.surfaces.each do |surface|
          zvalues = self.getSurfaceZValues([surface])
          surfaces_min_zs << zvalues.min + UnitConversions.convert(space.zOrigin,"m","ft")
        end
        space_min_zs << surfaces_min_zs.min
      end
      return space_min_zs.uniq.length
    end

    def self.get_above_grade_building_stories(spaces)
      space_min_zs = []
      spaces.each do |space|
        next if not self.space_is_finished(space)
        next if not self.space_is_above_grade(space)
        surfaces_min_zs = []
        space.surfaces.each do |surface|
          zvalues = self.getSurfaceZValues([surface])
          surfaces_min_zs << zvalues.min + UnitConversions.convert(space.zOrigin,"m","ft")
        end
        space_min_zs << surfaces_min_zs.min
      end
      return space_min_zs.uniq.length   
    end
    
    def self.make_one_space_from_multiple_spaces(model, spaces)
      new_space = OpenStudio::Model::Space.new(model)
      spaces.each do |space|
        space.surfaces.each do |surface|
          if surface.adjacentSurface.is_initialized and surface.surfaceType.downcase == "wall"
            surface.adjacentSurface.get.remove
            surface.remove
          else
            surface.setSpace(new_space)
          end
        end
        space.remove
      end      
      return new_space
    end   

    def self.make_polygon(*pts)
        p = OpenStudio::Point3dVector.new
        pts.each do |pt|
            p << pt
        end
        return p
    end
    
    def self.get_building_units(model, runner=nil)
        if model.getSpaces.size == 0
            if !runner.nil?
                runner.registerError("No building geometry has been defined.")
            end
            return nil
        end
        
        return_units = []
        model.getBuildingUnits.each do |unit|
            # Remove any units from list that have no associated spaces or are not residential
            next if not (unit.spaces.size > 0 and unit.buildingUnitType == Constants.BuildingUnitTypeResidential)
            return_units << unit
        end
        
        if return_units.size == 0
            # Assume SFD; create single building unit for entire model
            if !runner.nil?
                runner.registerWarning("No building units defined; assuming single-family detached building.")
            end
            unit = OpenStudio::Model::BuildingUnit.new(model)
            unit.setBuildingUnitType("Residential")
            unit.setName(Constants.ObjectNameBuildingUnit)
            model.getSpaces.each do |space|
                space.setBuildingUnit(unit)
            end
            model.getBuildingUnits.each do |unit|
              return_units << unit
            end
        end
        
        return return_units
    end
    
    def self.get_unit_beds_baths(model, unit, runner=nil)
        # Returns a list with #beds, #baths, a list of spaces, and the unit name
        nbeds = unit.getFeatureAsInteger(Constants.BuildingUnitFeatureNumBedrooms)
        nbaths = unit.getFeatureAsDouble(Constants.BuildingUnitFeatureNumBathrooms)
        if not (nbeds.is_initialized or nbaths.is_initialized)
            if !runner.nil?
                runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
            end
            return [nil, nil]
        else
            nbeds = nbeds.get.to_f
            nbaths = nbaths.get
        end
        return [nbeds, nbaths]
    end
    
    def self.get_unit_dhw_sched_index(model, unit, runner=nil)
        dhw_sched_index = unit.getFeatureAsInteger(Constants.BuildingUnitFeatureDHWSchedIndex)
        if not dhw_sched_index.is_initialized
            # Assign DHW schedule index values for every building unit.
            dhw_sched_index_hash = {}
            num_bed_options = (1..5)
            num_bed_options.each do |num_bed_option|
                dhw_sched_index_hash[num_bed_option.to_f] = -1 # initialize
            end
            units = self.get_building_units(model, runner)
            units.each do |unit|
                nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
                dhw_sched_index_hash[nbeds] = (dhw_sched_index_hash[nbeds]+1) % 365
                unit.setFeature(Constants.BuildingUnitFeatureDHWSchedIndex, dhw_sched_index_hash[nbeds])
            end
            dhw_sched_index = unit.getFeatureAsInteger(Constants.BuildingUnitFeatureDHWSchedIndex).get
        else
            # Value already assigned.
            dhw_sched_index = dhw_sched_index.get
        end
        return dhw_sched_index
    end
    
    def self.get_unit_adjacent_common_spaces(unit)
      # Returns a list of spaces adjacent to the unit that are not assigned
      # to a building unit.
      spaces = []
      
      unit.spaces.each do |space|
        space.surfaces.each do |surface|
          next if not surface.adjacentSurface.is_initialized
          adjacent_surface = surface.adjacentSurface.get
          next if not adjacent_surface.space.is_initialized
          adjacent_space = adjacent_surface.space.get
          next if adjacent_space.buildingUnit.is_initialized
          spaces << adjacent_space
        end
      end
      
      return spaces.uniq
    end
    
    def self.get_common_spaces(model)
      spaces = []
      model.getSpaces.each do |space|
        next if space.buildingUnit.is_initialized
        spaces << space
      end
      return spaces
    end
    
    def self.get_floor_area_from_spaces(spaces, apply_multipliers=false, runner=nil)
        floor_area = 0
        spaces.each do |space|
            mult = 1.0
            if apply_multipliers
                mult = space.multiplier.to_f
            end
            floor_area += UnitConversions.convert(space.floorArea * mult, "m^2", "ft^2")
        end
        if floor_area == 0 and not runner.nil?
            runner.registerError("Could not find any floor area.")
            return nil
        end
        return floor_area
    end
    
    def self.get_volume_from_spaces(spaces, apply_multipliers=false, runner=nil)
      volume = 0
      spaces.each do |space|
        mult = 1.0
        if apply_multipliers
            mult = space.multiplier.to_f
        end
        volume += UnitConversions.convert(space.volume * mult,"m^3","ft^3")
      end
      if volume <= 0 # FIXME: until we figure out how to deal with volumes
        return 0.001
      end
      if volume == 0 and not runner.nil?
        runner.registerError("Could not find any volume.")
        return nil
      end
      return volume    
    end

    def self.get_finished_floor_area_from_spaces(spaces, apply_multipliers=false, runner=nil)
        floor_area = 0
        spaces.each do |space|
            next if not self.space_is_finished(space)
            mult = 1.0
            if apply_multipliers
                mult = space.multiplier.to_f
            end
            floor_area += UnitConversions.convert(space.floorArea * mult,"m^2","ft^2")
        end
        if floor_area == 0 and not runner.nil?
            runner.registerError("Could not find any finished floor area.")
            return nil
        end
        return floor_area
    end
    
    def self.get_above_grade_finished_floor_area_from_spaces(spaces, apply_multipliers=false, runner=nil)
      floor_area = 0
      spaces.each do |space|
        next if not (self.space_is_finished(space) and self.space_is_above_grade(space))
        mult = 1.0
        if apply_multipliers
            mult = space.multiplier.to_f
        end
        floor_area += UnitConversions.convert(space.floorArea * mult,"m^2","ft^2")
      end
      if floor_area == 0 and not runner.nil?
          runner.registerError("Could not find any above-grade finished floor area.")
          return nil
      end
      return floor_area      
    end    
    
    def self.get_finished_volume_from_spaces(spaces, apply_multipliers=false, runner=nil)
      volume = 0
      spaces.each do |space|
        next if not self.space_is_finished(space)
        mult = 1.0
        if apply_multipliers
            mult = space.multiplier.to_f
        end
        volume += UnitConversions.convert(space.volume * mult,"m^3","ft^3")
      end
      if volume <= 0 # FIXME: until we figure out how to deal with volumes
        return 0.001
      end      
      if volume == 0 and not runner.nil?
          runner.registerError("Could not find any finished volume.")
          return nil
      end
      return volume    
    end    
    
    def self.get_above_grade_finished_volume_from_spaces(spaces, apply_multipliers=false, runner=nil)
      volume = 0
      spaces.each do |space|
        next if not (self.space_is_finished(space) and self.space_is_above_grade(space))
        mult = 1.0
        if apply_multipliers
            mult = space.multiplier.to_f
        end
        volume += UnitConversions.convert(space.volume * mult,"m^3","ft^3")
      end
      if volume <= 0 # FIXME: until we figure out how to deal with volumes
        return 0.001
      end      
      if volume == 0 and not runner.nil?
          runner.registerError("Could not find any above-grade finished volume.")
          return nil
      end
      return volume    
    end
    
    def self.get_window_area_from_spaces(spaces, apply_multipliers=false)
      window_area = 0
      spaces.each do |space|
        mult = 1.0
        if apply_multipliers
            mult = space.multiplier.to_f
        end
        space.surfaces.each do |surface|
          surface.subSurfaces.each do |subsurface|
            next if subsurface.subSurfaceType.downcase != "fixedwindow"
            window_area += UnitConversions.convert(subsurface.grossArea * mult,"m^2","ft^2")
          end
        end
      end
      return window_area
    end
    
    def self.space_height(space)
        return Geometry.get_height_of_spaces([space])
    end
    
    # Calculates space heights as the max z coordinate minus the min z coordinate
    def self.get_height_of_spaces(spaces)
      minzs = []
      maxzs = []
      spaces.each do |space|
        zvalues = self.getSurfaceZValues(space.surfaces)
        minzs << zvalues.min + UnitConversions.convert(space.zOrigin,"m","ft")
        maxzs << zvalues.max + UnitConversions.convert(space.zOrigin,"m","ft")
      end
      return maxzs.max - minzs.min
    end
    
    # Calculates the surface height as the max z coordinate minus the min z coordinate
    def self.surface_height(surface)
        zvalues = self.getSurfaceZValues([surface])
        minz = zvalues.min
        maxz = zvalues.max
        return maxz - minz
    end
    
    def self.zone_is_finished(zone)
        zone.spaces.each do |space|
          unless self.space_is_finished(space)
            return false
          end
        end
    end
    
    # Returns true if all spaces in zone are fully above grade
    def self.zone_is_above_grade(zone)
      spaces_are_above_grade = []
      zone.spaces.each do |space|
        spaces_are_above_grade << self.space_is_above_grade(space)
      end
      if spaces_are_above_grade.all?
        return true
      end
      return false
    end

    # Returns true if all spaces in zone are either fully or partially below grade
    def self.zone_is_below_grade(zone)
      return !self.zone_is_above_grade(zone)
    end       
    
    def self.get_finished_above_and_below_grade_zones(thermal_zones)
      finished_living_zones = []
      finished_basement_zones = []
      thermal_zones.each do |thermal_zone|
        next unless self.zone_is_finished(thermal_zone)
        if self.zone_is_above_grade(thermal_zone)
          finished_living_zones << thermal_zone
        elsif self.zone_is_below_grade(thermal_zone)
          finished_basement_zones << thermal_zone
        end
      end
      return finished_living_zones, finished_basement_zones
    end
    
    def self.get_thermal_zones_from_spaces(spaces)
      thermal_zones = []
      spaces.each do |space|
        next unless space.thermalZone.is_initialized
        unless thermal_zones.include? space.thermalZone.get
          thermal_zones << space.thermalZone.get
        end
      end
      return thermal_zones
    end
    
    def self.get_building_type(model)
      building_type = nil
      unless model.getBuilding.standardsBuildingType.empty?
        building_type = model.getBuilding.standardsBuildingType.get.downcase
      end
      return building_type
   end
    
    def self.space_is_unfinished(space)
        return !self.space_is_finished(space)
    end
    
    def self.space_is_finished(space)
        unless space.isPlenum
          if space.spaceType.is_initialized
            if space.spaceType.get.standardsSpaceType.is_initialized
              return self.is_living_space_type(space.spaceType.get.standardsSpaceType.get)
            end
          end
        end
        return false
    end
    
    def self.is_living_space_type(space_type)
      if [Constants.SpaceTypeLiving, Constants.SpaceTypeFinishedBasement, Constants.SpaceTypeKitchen, 
          Constants.SpaceTypeBedroom, Constants.SpaceTypeBathroom, Constants.SpaceTypeLaundryRoom].include? space_type
        return true
      end
      return false
    end
    
    # Returns true if space is fully above grade
    def self.space_is_above_grade(space)
        return !self.space_is_below_grade(space)
    end
    
    # Returns true if space is either fully or partially below grade
    def self.space_is_below_grade(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"
            if surface.isGroundSurface
                return true
            end
        end
        return false
    end 
    
    def self.space_has_roof(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling"
            next if surface.outsideBoundaryCondition.downcase != "outdoors"
            next if surface.tilt == 0
            return true
        end
        return false
    end
    
    def self.space_below_is_finished(space)
        space.surfaces.each do |surface|
            next if surface.surfaceType.downcase != "floor"
            next if not surface.adjacentSurface.is_initialized
            next if not surface.adjacentSurface.get.space.is_initialized
            adjacent_space = surface.adjacentSurface.get.space.get
            next if not self.space_is_finished(adjacent_space)
            return true
        end
        return false
    end
    
    def self.get_model_locations(model)
        locations = []
        model.getSpaceTypes.each do |spaceType|
            next if not spaceType.standardsSpaceType.is_initialized
            locations << spaceType.standardsSpaceType.get
        end
        return locations
    end
    
    def self.get_space_from_location(unit, location, location_hierarchy)
        spaces = unit.spaces + self.get_unit_adjacent_common_spaces(unit)
        if location == Constants.Auto
            location_hierarchy.each do |space_type|
                spaces.each do |space|
                    next if not self.space_is_of_type(space, space_type)
                    return space
                end
            end
        else
            spaces.each do |space|
                next if not space.spaceType.is_initialized
                next if not space.spaceType.get.standardsSpaceType.is_initialized
                next if space.spaceType.get.standardsSpaceType.get != location
                return space
            end
        end
        return nil
    end

    # Return an array of x values for surfaces passed in. The values will be relative to the parent origin. This was intended for spaces.
    def self.getSurfaceXValues(surfaceArray)
        xValueArray = []
        surfaceArray.each do |surface|
            surface.vertices.each do |vertex|
                xValueArray << UnitConversions.convert(vertex.x, "m", "ft")
            end
        end
        return xValueArray
    end

    # Return an array of y values for surfaces passed in. The values will be relative to the parent origin. This was intended for spaces.
    def self.getSurfaceYValues(surfaceArray)
        yValueArray = []
        surfaceArray.each do |surface|
            surface.vertices.each do |vertex|
                yValueArray << UnitConversions.convert(vertex.y, "m", "ft")
            end
        end
        return yValueArray
    end
    
    # Return an array of z values for surfaces passed in. The values will be relative to the parent origin. This was intended for spaces.
    def self.getSurfaceZValues(surfaceArray)
        zValueArray = []
        surfaceArray.each do |surface|
            surface.vertices.each do |vertex|
                zValueArray << UnitConversions.convert(vertex.z, "m", "ft")
            end
        end
        return zValueArray
    end

    def self.get_space_floor_z(space)
      space.surfaces.each do |surface|
        next unless surface.surfaceType.downcase == "floor"
        return self.getSurfaceZValues([surface])[0]
      end
    end
    
    def self.get_z_origin_for_zone(zone)
      z_origins = []
      zone.spaces.each do |space|
        z_origins << UnitConversions.convert(space.zOrigin,"m","ft")
      end
      return z_origins.min
    end
    
    # Takes in a list of spaces and returns the average space height
    def self.spaces_avg_height(spaces)
        sum_height = 0
        spaces.each do |space|
            sum_height += self.space_height(space)
        end
        return sum_height/spaces.size
    end
    
    # Takes in a list of surfaces and returns the total gross area
    def self.calculate_total_area_from_surfaces(surfaces)
        total_area = 0
        surfaces.each do |surface|
            total_area += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
        end
        return total_area
    end
    
    # Takes in a list of spaces and returns the total above grade wall area
    def self.calculate_above_grade_wall_area(spaces, apply_multipliers=false)
        wall_area = 0
        spaces.each do |space|
            mult = 1.0
            if apply_multipliers
                mult = space.multiplier.to_f
            end
            space.surfaces.each do |surface|
                next if surface.surfaceType.downcase != "wall"
                next if surface.isGroundSurface
                wall_area += UnitConversions.convert(surface.grossArea * mult, "m^2", "ft^2")
            end
        end
        return wall_area
    end
    
    def self.calculate_above_grade_exterior_wall_area(spaces, apply_multipliers=false)
        wall_area = 0
        spaces.each do |space|
            mult = 1.0
            if apply_multipliers
                mult = space.multiplier.to_f
            end
            space.surfaces.each do |surface|
                next if surface.surfaceType.downcase != "wall"
                next if surface.outsideBoundaryCondition.downcase != "outdoors"
                next if surface.isGroundSurface
                next unless self.space_is_finished(surface.space.get)
                wall_area += UnitConversions.convert(surface.grossArea * mult, "m^2", "ft^2")
            end
        end
        return wall_area
    end
    
    def self.get_roof_pitch(surfaces)
        tilts = []
        surfaces.each do |surface|
            next if surface.surfaceType.downcase != "roofceiling"
            next if surface.outsideBoundaryCondition.downcase != "outdoors" and surface.outsideBoundaryCondition.downcase != "adiabatic"
            tilts << surface.tilt
        end
        return UnitConversions.convert(tilts.max, "rad", "deg")
    end
    
    # Checks if the surface is between finished space and outside
    def self.is_exterior_surface(surface)
        if surface.outsideBoundaryCondition.downcase != "outdoors" or not surface.space.is_initialized
            return false
        end
        if not self.space_is_finished(surface.space.get)
            return false
        end
        return true
    end
    
    # Checks if the surface is between finished and unfinished space
    def self.is_interzonal_surface(surface)
        if surface.outsideBoundaryCondition.downcase != "surface" or not surface.space.is_initialized or not surface.adjacentSurface.is_initialized
            return false
        end
        adjacent_surface = surface.adjacentSurface.get
        if not adjacent_surface.space.is_initialized
            return false
        end
        if self.space_is_finished(surface.space.get) == self.space_is_finished(adjacent_surface.space.get)
            return false
        end
        return true
    end
    
    # Takes in a list of ground exposed floor surfaces for which to calculate the perimeter; 
    # checks for edges shared by a ground exposed floor and 1) exterior exposed or 2) interzonal wall.
    # TODO: Has not been tested on buildings with multiple foundations 
    #        (aside from basements/crawls with attached garages over slabs)
    # TODO: Update code to work for non-rectangular buildings.
    def self.calculate_exposed_perimeter(model, ground_floor_surfaces, has_foundation_walls=false)

        perimeter = 0

        # Get ground edges
        if not has_foundation_walls
            # Use edges from floor surface
            ground_edges = self.get_edges_for_surfaces(ground_floor_surfaces, false)
        else
            # Use top edges from foundation walls instead
            surfaces = []
            ground_floor_surfaces.each do |ground_floor_surface|
                next if not ground_floor_surface.space.is_initialized
                foundation_space = ground_floor_surface.space.get
                foundation_space.surfaces.each do |surface|
                    next if not surface.surfaceType.downcase == "wall"
                    next if surfaces.include? surface
                    surfaces << surface
                end
            end
            ground_edges = self.get_edges_for_surfaces(surfaces, true)
        end
        
        # Get bottom edges of exterior exposed walls or interzonal walls
        surfaces = []
        model.getSurfaces.each do |surface|
            next if not surface.surfaceType.downcase == "wall"
            next if not (self.is_exterior_surface(surface) or self.is_interzonal_surface(surface))
            surfaces << surface
        end
        model_edges = self.get_edges_for_surfaces(surfaces, false, true)
        
        # check edges for matches
        ground_edges.each do |e1|
            model_edges.each do |e2|
                # see if edges have same geometry
                next if not ((e1[0] == e2[1] and e1[1] == e2[0]) or (e1[0] == e2[0] and e1[1] == e2[1]))
                point_one = OpenStudio::Point3d.new(e1[0][0],e1[0][1],e1[0][2])
                point_two = OpenStudio::Point3d.new(e1[1][0],e1[1][1],e1[1][2])
                length = OpenStudio::Vector3d.new(point_one - point_two).length
                perimeter += length
                break
            end
        end
    
        return UnitConversions.convert(perimeter, "m", "ft")
    end
    
    def self.get_edges_for_surfaces(surfaces, use_top_edge, combine_adjacent=false)
        edges = []
        edge_counter = 0
        surfaces.each do |surface|
            # ensure we only process bottom or top edge of wall surfaces
            if use_top_edge
                matchz = self.getSurfaceZValues([surface]).max
            else
                matchz = self.getSurfaceZValues([surface]).min
            end
            # get vertices
            vertex_hash = {}
            vertex_counter = 0
            surface.vertices.each do |vertex|
                next if (UnitConversions.convert(vertex.z, "m", "ft") - matchz).abs > 0.0001
                vertex_counter += 1
                vertex_hash[vertex_counter] = [vertex.x + surface.space.get.xOrigin,
                                               vertex.y + surface.space.get.yOrigin,
                                               vertex.z + surface.space.get.zOrigin]
            end
            # make edges
            counter = 0
            vertex_hash.each do |k,v|
                edge_counter += 1
                counter += 1
                if vertex_hash.size != counter
                    edges << [v, vertex_hash[counter+1], self.get_facade_for_surface(surface)]
                elsif vertex_hash.size > 2 # different code for wrap around vertex (if > 2 vertices)
                    edges << [v, vertex_hash[1], self.get_facade_for_surface(surface)]
                end
            end
        end
        
        if combine_adjacent
            # Create combinations of adjacent edges (e.g., front wall surface split into multiple surfaces because of the door)
            loop do
                new_combi_edges = []
                edges.each_with_index do |e1, i1|
                    edges.each_with_index do |e2, i2|
                        next if i2 <= i1
                        next if e1[2] != e2[2] # different facades
                        # Check if shared vertex and not overlapping
                        new_combi_edge = nil
                        if e1[0] == e2[1]
                            next if not self.vertices_straddle_base_vertex?(e1[0], e1[1], e2[0], e1[2])
                            new_combi_edge = [e1[1], e2[0], e1[2]]
                        elsif e1[1] == e2[0]
                            next if not self.vertices_straddle_base_vertex?(e1[1], e1[0], e2[1], e1[2])
                            new_combi_edge = [e1[0], e2[1], e1[2]]
                        elsif e1[1] == e2[1]
                            next if not self.vertices_straddle_base_vertex?(e1[1], e1[0], e2[0], e1[2])
                            new_combi_edge = [e1[0], e2[0], e1[2]]
                        elsif e1[0] == e2[0]
                            next if not self.vertices_straddle_base_vertex?(e1[0], e1[1], e2[1], e1[2])
                            new_combi_edge = [e1[1], e2[1], e1[2]]
                        end
                        next if new_combi_edge.nil?
                        next if edges.include?(new_combi_edge)
                        new_combi_edges << new_combi_edge
                    end
                end
                
                # Add new_combi_edges to edges
                new_combi_edges.each do |new_combi_edge|
                    edges << new_combi_edge
                end
                
                break if new_combi_edges.size == 0 # no new combinations found
            end
        end
        
        return edges
    end
    
    def self.vertices_straddle_base_vertex?(b, v1, v2, facade)
        # Checks if v1 and v2 are on opposite sides of b
        if [Constants.FacadeFront, Constants.FacadeBack].include?(facade)
            if (v1[0] < b[0] and v2[0] > b[0]) or (v2[0] < b[0] and v1[0] > b[0])
                return true
            end
        elsif [Constants.FacadeLeft, Constants.FacadeRight].include?(facade)
            if (v1[1] < b[1] and v2[1] > b[1]) or (v2[1] < b[1] and v1[1] > b[1])
                return true
            end
        else
            abort("Unhandled situation.")
        end
        return false
    end
    
    def self.is_living(space_or_zone)
        return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeLiving)
    end
    
    def self.is_pier_beam(space_or_zone)
        return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypePierBeam)
    end
    
    def self.is_crawl(space_or_zone)
        return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeCrawl)
    end
    
    def self.is_finished_basement(space_or_zone)
        return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeFinishedBasement)
    end
    
    def self.is_unfinished_basement(space_or_zone)
        return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeUnfinishedBasement)
    end
    
    def self.is_unfinished_attic(space_or_zone)
        return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeUnfinishedAttic)
    end
    
    def self.is_garage(space_or_zone)
        return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeGarage)
    end
    
    def self.is_corridor(space_or_zone)
        return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeCorridor)
    end
    
    def self.is_bedroom(space_or_zone)
        return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeBedroom)
    end
    
    def self.space_or_zone_is_of_type(space_or_zone, space_type)
        if space_or_zone.is_a? OpenStudio::Model::Space
          return self.space_is_of_type(space_or_zone, space_type)
        elsif space_or_zone.is_a? OpenStudio::Model::ThermalZone
          return self.zone_is_of_type(space_or_zone, space_type)
        end
    end
    
    def self.space_is_of_type(space, space_type)
      unless space.isPlenum
        if space.spaceType.is_initialized
          if space.spaceType.get.standardsSpaceType.is_initialized          
            return true if space.spaceType.get.standardsSpaceType.get == space_type
          end
        end
      end
      return false
    end
    
    def self.zone_is_of_type(zone, space_type)
      zone.spaces.each do |space|
        return self.space_is_of_type(space, space_type)
      end
    end
    
    def self.is_basement(space_or_zone)
      if space_or_zone.is_a? OpenStudio::Model::Space
        return self.space_is_below_grade(space_or_zone)
      elsif space_or_zone.is_a? OpenStudio::Model::ThermalZone
        return self.zone_is_below_grade(space_or_zone)
      end
    end
    
    def self.is_attic(space_or_zone)
      if space_or_zone.is_a? OpenStudio::Model::Space
        space_or_zone.surfaces.each do |surface|
          next unless surface.surfaceType.downcase.to_s == "roofceiling"
          unless surface.outsideBoundaryCondition.downcase.to_s == "outdoors" 
            return false
          end
        end
        space_or_zone.surfaces.each do |surface|
          next unless surface.surfaceType.downcase.to_s == "floor"
          surface.vertices.each do |vertex|
            unless vertex.z + space_or_zone.zOrigin > 0 # not an attic if it isn't above grade
              return false
            end
          end
        end
      elsif space_or_zone.is_a? OpenStudio::Model::ThermalZone
        space_or_zone.spaces.each do |space|
          space.surfaces.each do |surface|
            next unless surface.surfaceType.downcase.to_s == "roofceiling"
            if not surface.outsideBoundaryCondition.downcase.to_s == "outdoors"
              return false
            end
          end
          space.surfaces.each do |surface|
            next unless surface.surfaceType.downcase.to_s == "floor"
            surface.vertices.each do |vertex|
              unless vertex.z + space.zOrigin > 0 # not an attic if it isn't above grade
                return false
              end
            end
          end
        end
      end
    end
    
    def self.is_foundation(space_or_zone)
      return true if self.is_pier_beam(space_or_zone) or self.is_crawl(space_or_zone) or self.is_finished_basement(space_or_zone) or self.is_unfinished_basement(space_or_zone)
    end
    
    def self.get_crawl_spaces(spaces)
        crawl_spaces = []
        spaces.each do |space|
            next if not self.is_crawl(space)
            crawl_spaces << space
        end
        return crawl_spaces
    end
        
    def self.get_pier_beam_spaces(spaces)
        pb_spaces = []
        spaces.each do |space|
            next if not self.is_pier_beam(space)
            pb_spaces << space
        end
        return pb_spaces
    end
    
    def self.get_finished_spaces(spaces)
        finished_spaces = []
        spaces.each do |space|
            next if self.space_is_unfinished(space)
            finished_spaces << space
        end
        return finished_spaces
    end
    
    def self.get_bedroom_spaces(spaces)
        bedroom_spaces = []
        spaces.each do |space|
            next if not self.is_bedroom(space)
        end
        return bedroom_spaces
    end
    
    def self.get_finished_basement_spaces(spaces)
        finished_basement_spaces = []
        spaces.each do |space|
            next if not self.is_finished_basement(space)
            finished_basement_spaces << space
        end
        return finished_basement_spaces
    end
    
    def self.get_unfinished_basement_spaces(spaces)
        unfinished_basement_spaces = []
        spaces.each do |space|
            next if not self.is_unfinished_basement(space)
            unfinished_basement_spaces << space
        end
        return unfinished_basement_spaces
    end
    
    def self.get_unfinished_attic_spaces(spaces)
        unfinished_attic_spaces = []
        spaces.each do |space|
            next if not self.is_unfinished_attic(space)
            unfinished_attic_spaces << space
        end
        return unfinished_attic_spaces
    end
        
    def self.get_garage_spaces(spaces)
        garage_spaces = []
        spaces.each do |space|
            next if not self.is_garage(space)
            garage_spaces << space
        end
        return garage_spaces
    end
        
    def self.get_facade_for_surface(surface)
        tol = 0.001
        n = surface.outwardNormal
        facade = nil
        if (n.z).abs < tol
            if (n.x).abs < tol and (n.y + 1).abs < tol
                facade = Constants.FacadeFront
            elsif (n.x - 1).abs < tol and (n.y).abs < tol
                facade = Constants.FacadeRight
            elsif (n.x).abs < tol and (n.y - 1).abs < tol
                facade = Constants.FacadeBack
            elsif (n.x + 1).abs < tol and (n.y).abs < tol
                facade = Constants.FacadeLeft
            end
        elsif
            if (n.x).abs < tol and n.y < 0
                facade = Constants.FacadeFront
            elsif n.x > 0 and (n.y).abs < tol
                facade = Constants.FacadeRight
            elsif (n.x).abs < tol and n.y > 0
                facade = Constants.FacadeBack
            elsif n.x < 0 and (n.y).abs < tol
                facade = Constants.FacadeLeft
            end
        end
        return facade
    end
    
    def self.get_surface_length(surface)
        xvalues = self.getSurfaceXValues([surface])
        yvalues = self.getSurfaceYValues([surface])
        xrange = xvalues.max - xvalues.min
        yrange = yvalues.max - yvalues.min
        if xrange > yrange
            return xrange
        end
        return yrange
    end
   
    def self.get_surface_height(surface) 
        zvalues = self.getSurfaceZValues([surface])
        zrange = zvalues.max - zvalues.min
        return zrange
    end
   
    def self.is_gable_wall(surface)
        if (surface.surfaceType.downcase != "wall" or surface.outsideBoundaryCondition.downcase != "outdoors")
            return false
        end
        if surface.vertices.size != 3
            return false
        end
        if not surface.space.is_initialized
            return false
        end
        space = surface.space.get
        if not self.space_has_roof(space)
            return false
        end
        return true
    end
   
    def self.is_rectangular_wall(surface)
        if (surface.surfaceType.downcase != "wall" or surface.outsideBoundaryCondition.downcase != "outdoors")
            return false
        end
        if surface.vertices.size != 4
            return false
        end        
        xvalues = self.getSurfaceXValues([surface])
        yvalues = self.getSurfaceYValues([surface])
        zvalues = self.getSurfaceZValues([surface])
        if not ((xvalues.uniq.size == 1 and yvalues.uniq.size == 2) or
                (xvalues.uniq.size == 2 and yvalues.uniq.size == 1))
            return false
        end
        if not zvalues.uniq.size == 2
            return false
        end
        return true
    end
   
    def self.get_closest_neighbor_distance(model)
        house_points = []
        neighbor_points = []
        model.getSurfaces.each do |surface|
          next unless surface.surfaceType.downcase == "wall"
          surface.vertices.each do |vertex|
            house_points << OpenStudio::Point3d.new(vertex)
          end
        end
        model.getShadingSurfaces.each do |shading_surface|
          next unless shading_surface.name.to_s.downcase.include? "neighbor"
          shading_surface.vertices.each do |vertex|
            neighbor_points << OpenStudio::Point3d.new(vertex)
          end
        end
        neighbor_offsets = []
        house_points.each do |house_point|
          neighbor_points.each do |neighbor_point|
            neighbor_offsets << OpenStudio::getDistance(house_point, neighbor_point)
          end
        end
        if neighbor_offsets.empty?
          return 0
        end    
        return UnitConversions.convert(neighbor_offsets.min,"m","ft")
    end
    
    def self.get_spaces_above_grade_exterior_walls(spaces)
        above_grade_exterior_walls = []
        spaces.each do |space|
            next if not Geometry.space_is_finished(space)
            next if not Geometry.space_is_above_grade(space)
            space.surfaces.each do |surface|
                next if above_grade_exterior_walls.include?(surface)
                next if surface.surfaceType.downcase != "wall"
                next if surface.outsideBoundaryCondition.downcase != "outdoors"
                above_grade_exterior_walls << surface
            end
        end
        return above_grade_exterior_walls
    end
    
    def self.get_spaces_above_grade_exterior_floors(spaces)
        above_grade_exterior_floors = []
        spaces.each do |space|
            next if not Geometry.space_is_finished(space)
            next if not Geometry.space_is_above_grade(space)
            space.surfaces.each do |surface|
                next if above_grade_exterior_floors.include?(surface)
                next if surface.surfaceType.downcase != "floor"
                next if surface.outsideBoundaryCondition.downcase != "outdoors"
                above_grade_exterior_floors << surface
            end
        end
        return above_grade_exterior_floors
    end
    
    def self.get_spaces_above_grade_ground_floors(spaces)
        above_grade_ground_floors = []
        spaces.each do |space|
            next if not Geometry.space_is_finished(space)
            next if not Geometry.space_is_above_grade(space)
            space.surfaces.each do |surface|
                next if above_grade_ground_floors.include?(surface)
                next if surface.surfaceType.downcase != "floor"
                next if surface.outsideBoundaryCondition.downcase != "ground"
                above_grade_ground_floors << surface
            end
        end
        return above_grade_ground_floors
    end
    
    def self.get_spaces_above_grade_exterior_roofs(spaces)
        above_grade_exterior_roofs = []
        spaces.each do |space|
            next if not Geometry.space_is_finished(space)
            next if not Geometry.space_is_above_grade(space)
            space.surfaces.each do |surface|
                next if above_grade_exterior_roofs.include?(surface)
                next if surface.surfaceType.downcase != "roofceiling"
                next if surface.outsideBoundaryCondition.downcase != "outdoors"
                above_grade_exterior_roofs << surface
            end
        end
        return above_grade_exterior_roofs
    end
    
    def self.get_spaces_interzonal_walls(spaces)
        interzonal_walls = []
        spaces.each do |space|
            space.surfaces.each do |surface|
                next if interzonal_walls.include?(surface)
                next if surface.surfaceType.downcase != "wall"
                next if not self.is_interzonal_surface(surface)
                interzonal_walls << surface
            end
        end
        return interzonal_walls
    end
    
    def self.get_spaces_interzonal_floors_and_ceilings(spaces)
        interzonal_floors = []
        spaces.each do |space|
            space.surfaces.each do |surface|
                next if interzonal_floors.include?(surface)
                next if surface.surfaceType.downcase != "floor" and surface.surfaceType.downcase != "roofceiling"
                next if not self.is_interzonal_surface(surface)
                interzonal_floors << surface
            end
        end
        return interzonal_floors
    end

    def self.get_spaces_below_grade_exterior_walls(spaces)
        below_grade_exterior_walls = []
        spaces.each do |space|
            next if not Geometry.space_is_finished(space)
            next if not Geometry.space_is_below_grade(space)
            space.surfaces.each do |surface|
                next if below_grade_exterior_walls.include?(surface)
                next if surface.surfaceType.downcase != "wall"
                next if surface.outsideBoundaryCondition.downcase != "ground"
                below_grade_exterior_walls << surface
            end
        end
        return below_grade_exterior_walls
    end
    
    def self.get_spaces_below_grade_exterior_floors(spaces)
        below_grade_exterior_floors = []
        spaces.each do |space|
            next if not Geometry.space_is_finished(space)
            next if not Geometry.space_is_below_grade(space)
            space.surfaces.each do |surface|
                next if below_grade_exterior_floors.include?(surface)
                next if surface.surfaceType.downcase != "floor"
                next if surface.outsideBoundaryCondition.downcase != "ground"
                below_grade_exterior_floors << surface
            end
        end
        return below_grade_exterior_floors
    end

end