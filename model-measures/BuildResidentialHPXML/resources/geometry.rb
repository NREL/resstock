require_relative "constants"
require_relative "unit_conversions"
require_relative "util"

class Geometry
  def self.get_zone_volume(zone, runner = nil)
    if zone.isVolumeAutocalculated or not zone.volume.is_initialized
      # Calculate volume from spaces
      volume = 0
      zone.spaces.each do |space|
        volume += UnitConversions.convert(space.volume, "m^3", "ft^3")
      end
    else
      volume = UnitConversions.convert(zone.volume.get, "m^3", "ft^3")
    end
    if volume <= 0 and not runner.nil?
      runner.registerError("Could not find any volume.")
      return nil
    end
    return volume
  end

  # Calculates space heights as the max z coordinate minus the min z coordinate
  def self.get_height_of_spaces(spaces)
    minzs = []
    maxzs = []
    spaces.each do |space|
      zvalues = self.getSurfaceZValues(space.surfaces)
      minzs << zvalues.min + UnitConversions.convert(space.zOrigin, "m", "ft")
      maxzs << zvalues.max + UnitConversions.convert(space.zOrigin, "m", "ft")
    end
    return maxzs.max - minzs.min
  end

  def self.get_max_z_of_spaces(spaces)
    maxzs = []
    spaces.each do |space|
      zvalues = self.getSurfaceZValues(space.surfaces)
      maxzs << zvalues.max + UnitConversions.convert(space.zOrigin, "m", "ft")
    end
    return maxzs.max
  end

  # Calculates the surface height as the max z coordinate minus the min z coordinate
  def self.surface_height(surface)
    zvalues = self.getSurfaceZValues([surface])
    minz = zvalues.min
    maxz = zvalues.max
    return maxz - minz
  end

  def self.zone_is_conditioned(zone)
    zone.spaces.each do |space|
      unless self.space_is_conditioned(space)
        return false
      end
    end
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

  def self.space_is_unconditioned(space)
    return !self.space_is_conditioned(space)
  end

  def self.space_is_conditioned(space)
    unless space.isPlenum
      if space.spaceType.is_initialized
        if space.spaceType.get.standardsSpaceType.is_initialized
          return self.is_conditioned_space_type(space.spaceType.get.standardsSpaceType.get)
        end
      end
    end
    return false
  end

  def self.is_conditioned_space_type(space_type)
    if [Constants.SpaceTypeLiving].include? space_type
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
      if surface.outsideBoundaryCondition.downcase == "foundation"
        return true
      end
    end
    return false
  end

  def self.get_space_from_location(model, location, location_hierarchy)
    if location == Constants.Auto
      location_hierarchy.each do |space_type|
        model.getSpaces.each do |space|
          next if not self.space_is_of_type(space, space_type)

          return space
        end
      end
    else
      model.getSpaces.each do |space|
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

  def self.get_z_origin_for_zone(zone)
    z_origins = []
    zone.spaces.each do |space|
      z_origins << UnitConversions.convert(space.zOrigin, "m", "ft")
    end
    return z_origins.min
  end

  # Takes in a list of spaces and returns the total above grade wall area
  def self.calculate_above_grade_wall_area(spaces)
    wall_area = 0
    spaces.each do |space|
      space.surfaces.each do |surface|
        next if surface.surfaceType.downcase != "wall"
        next if surface.outsideBoundaryCondition.downcase == "foundation"

        wall_area += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
      end
    end
    return wall_area
  end

  def self.calculate_above_grade_exterior_wall_area(spaces)
    wall_area = 0
    spaces.each do |space|
      space.surfaces.each do |surface|
        next if surface.surfaceType.downcase != "wall"
        next if surface.outsideBoundaryCondition.downcase != "outdoors"
        next if surface.outsideBoundaryCondition.downcase == "foundation"
        next unless self.space_is_conditioned(surface.space.get)

        wall_area += UnitConversions.convert(surface.grossArea, "m^2", "ft^2")
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

  # Checks if the surface is between conditioned and unconditioned space
  def self.is_interzonal_surface(surface)
    if surface.outsideBoundaryCondition.downcase != "surface" or not surface.space.is_initialized or not surface.adjacentSurface.is_initialized
      return false
    end

    adjacent_surface = surface.adjacentSurface.get
    if not adjacent_surface.space.is_initialized
      return false
    end
    if self.space_is_conditioned(surface.space.get) == self.space_is_conditioned(adjacent_surface.space.get)
      return false
    end

    return true
  end

  def self.is_living(space_or_zone)
    return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeLiving)
  end

  def self.is_vented_crawl(space_or_zone)
    return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeVentedCrawl)
  end

  def self.is_unvented_crawl(space_or_zone)
    return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeUnventedCrawl)
  end

  def self.is_unconditioned_basement(space_or_zone)
    return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeUnconditionedBasement)
  end

  def self.is_vented_attic(space_or_zone)
    return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeVentedAttic)
  end

  def self.is_unvented_attic(space_or_zone)
    return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeUnventedAttic)
  end

  def self.is_garage(space_or_zone)
    return self.space_or_zone_is_of_type(space_or_zone, Constants.SpaceTypeGarage)
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
    else
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

  def self.get_spaces_above_grade_exterior_walls(spaces)
    above_grade_exterior_walls = []
    spaces.each do |space|
      next if not Geometry.space_is_conditioned(space)
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
      next if not Geometry.space_is_conditioned(space)
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
      next if not Geometry.space_is_conditioned(space)
      next if not Geometry.space_is_above_grade(space)

      space.surfaces.each do |surface|
        next if above_grade_ground_floors.include?(surface)
        next if surface.surfaceType.downcase != "floor"
        next if surface.outsideBoundaryCondition.downcase != "foundation"

        above_grade_ground_floors << surface
      end
    end
    return above_grade_ground_floors
  end

  def self.get_spaces_above_grade_exterior_roofs(spaces)
    above_grade_exterior_roofs = []
    spaces.each do |space|
      next if not Geometry.space_is_conditioned(space)
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
      next if not Geometry.space_is_conditioned(space)
      next if not Geometry.space_is_below_grade(space)

      space.surfaces.each do |surface|
        next if below_grade_exterior_walls.include?(surface)
        next if surface.surfaceType.downcase != "wall"
        next if surface.outsideBoundaryCondition.downcase != "foundation"

        below_grade_exterior_walls << surface
      end
    end
    return below_grade_exterior_walls
  end

  def self.get_spaces_below_grade_exterior_floors(spaces)
    below_grade_exterior_floors = []
    spaces.each do |space|
      next if not Geometry.space_is_conditioned(space)
      next if not Geometry.space_is_below_grade(space)

      space.surfaces.each do |surface|
        next if below_grade_exterior_floors.include?(surface)
        next if surface.surfaceType.downcase != "floor"
        next if surface.outsideBoundaryCondition.downcase != "foundation"

        below_grade_exterior_floors << surface
      end
    end
    return below_grade_exterior_floors
  end

  def self.process_occupants(model, runner, num_occ, occ_gain, sens_frac, lat_frac, weekday_sch, weekend_sch, monthly_sch,
                             cfa, nbeds, space)

    # Error checking
    if sens_frac < 0 or sens_frac > 1
      runner.registerError("Sensible fraction must be greater than or equal to 0 and less than or equal to 1.")
      return false
    end
    if lat_frac < 0 or lat_frac > 1
      runner.registerError("Latent fraction must be greater than or equal to 0 and less than or equal to 1.")
      return false
    end
    if lat_frac + sens_frac > 1
      runner.registerError("Sum of sensible and latent fractions must be less than or equal to 1.")
      return false
    end

    activity_per_person = UnitConversions.convert(occ_gain, "Btu/hr", "W")

    # Hard-coded convective, radiative, latent, and lost fractions
    occ_lat = lat_frac
    occ_sens = sens_frac
    occ_conv = 0.442 * occ_sens
    occ_rad = 0.558 * occ_sens
    occ_lost = 1 - occ_lat - occ_conv - occ_rad

    space_obj_name = "#{Constants.ObjectNameOccupants}"
    space_num_occ = num_occ * UnitConversions.convert(space.floorArea, "m^2", "ft^2") / cfa

    # Create schedule
    people_sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameOccupants + " schedule", weekday_sch, weekend_sch, monthly_sch, mult_weekday = 1.0, mult_weekend = 1.0, normalize_values = true, create_sch_object = true, schedule_type_limits_name = Constants.ScheduleTypeLimitsFraction)
    if not people_sch.validated?
      return false
    end

    # Create schedule
    activity_sch = OpenStudio::Model::ScheduleRuleset.new(model, activity_per_person)

    # Add people definition for the occ
    occ_def = OpenStudio::Model::PeopleDefinition.new(model)
    occ = OpenStudio::Model::People.new(occ_def)
    occ.setName(space_obj_name)
    occ.setSpace(space)
    occ_def.setName(space_obj_name)
    occ_def.setNumberOfPeopleCalculationMethod("People", 1)
    occ_def.setNumberofPeople(space_num_occ)
    occ_def.setFractionRadiant(occ_rad)
    occ_def.setSensibleHeatFraction(occ_sens)
    occ_def.setMeanRadiantTemperatureCalculationType("ZoneAveraged")
    occ_def.setCarbonDioxideGenerationRate(0)
    occ_def.setEnableASHRAE55ComfortWarnings(false)
    occ.setActivityLevelSchedule(activity_sch)
    occ.setNumberofPeopleSchedule(people_sch.schedule)

    runner.registerInfo("Space '#{space.name}' been assigned #{space_num_occ.round(2)} occupant(s).")
    return true
  end

  def self.get_occupancy_default_num(nbeds)
    return Float(nbeds)
  end

  def self.get_occupancy_default_values()
    # Table 4.2.2(3). Internal Gains for Reference Homes
    hrs_per_day = 16.5 # hrs/day
    sens_gains = 3716.0 # Btu/person/day
    lat_gains = 2884.0 # Btu/person/day
    tot_gains = sens_gains + lat_gains
    heat_gain = tot_gains / hrs_per_day # Btu/person/hr
    sens = sens_gains / tot_gains
    lat = lat_gains / tot_gains
    return heat_gain, hrs_per_day, sens, lat
  end

  def self.create_single_family_detached(runner, model, total_ffa, wall_height, num_floors, aspect_ratio, garage_width, garage_depth, garage_protrusion, garage_position, foundation_type, foundation_height, attic_type, roof_type, roof_pitch, roof_structure)
    if foundation_type == "slab"
      foundation_height = 0.0
    end

    # error checking
    if model.getSpaces.size > 0
      runner.registerError("Starting model is not empty.")
      return false
    end
    if aspect_ratio < 0
      runner.registerError("Invalid aspect ratio entered.")
      return false
    end
    if foundation_type == "pier and beam" and (foundation_height <= 0.0)
      runner.registerError("The pier & beam height must be greater than 0 ft.")
      return false
    end
    if num_floors > 6
      runner.registerError("Too many floors.")
      return false
    end
    if garage_protrusion < 0 or garage_protrusion > 1
      runner.registerError("Invalid garage protrusion value entered.")
      return false
    end

    # Convert to SI
    total_ffa = UnitConversions.convert(total_ffa, "ft^2", "m^2")
    wall_height = UnitConversions.convert(wall_height, "ft", "m")
    garage_width = UnitConversions.convert(garage_width, "ft", "m")
    garage_depth = UnitConversions.convert(garage_depth, "ft", "m")
    foundation_height = UnitConversions.convert(foundation_height, "ft", "m")

    garage_area = garage_width * garage_depth
    has_garage = false
    if garage_area > 0
      has_garage = true
    end

    # error checking
    if garage_protrusion > 0 and roof_type == "hip" and has_garage
      runner.registerError("Cannot handle protruding garage and hip roof.")
      return false
    end
    if garage_protrusion > 0 and aspect_ratio < 1 and has_garage and roof_type == "gable"
      runner.registerError("Cannot handle protruding garage and attic ridge running from front to back.")
      return false
    end
    if foundation_type == "pier and beam" and has_garage
      runner.registerError("Cannot handle garages with a pier & beam foundation type.")
      return false
    end

    # calculate the footprint of the building
    garage_area_inside_footprint = 0
    if has_garage
      garage_area_inside_footprint = garage_area * (1.0 - garage_protrusion)
    end
    bonus_area_above_garage = garage_area * garage_protrusion
    if foundation_type == "finished basement" and attic_type == "finished attic"
      footprint = (total_ffa + 2 * garage_area_inside_footprint - (num_floors) * bonus_area_above_garage) / (num_floors + 2)
    elsif foundation_type == "finished basement"
      footprint = (total_ffa + 2 * garage_area_inside_footprint - (num_floors - 1) * bonus_area_above_garage) / (num_floors + 1)
    elsif attic_type == "finished attic"
      footprint = (total_ffa + garage_area_inside_footprint - (num_floors) * bonus_area_above_garage) / (num_floors + 1)
    else
      footprint = (total_ffa + garage_area_inside_footprint - (num_floors - 1) * bonus_area_above_garage) / num_floors
    end

    # calculate the dimensions of the building
    width = Math.sqrt(footprint / aspect_ratio)
    length = footprint / width

    # error checking
    if (garage_width > length and garage_depth > 0) or (((1.0 - garage_protrusion) * garage_depth) > width and garage_width > 0) or (((1.0 - garage_protrusion) * garage_depth) == width and garage_width == length)
      runner.registerError("Invalid living space and garage dimensions.")
      return false
    end

    # starting spaces
    runner.registerInitialCondition("The building started with #{model.getSpaces.size} spaces.")

    # create living zone
    living_zone = OpenStudio::Model::ThermalZone.new(model)
    living_zone.setName("living zone")

    foundation_offset = 0.0
    if foundation_type == "pier and beam"
      foundation_offset = foundation_height
    end

    space_types_hash = {}

    # loop through the number of floors
    foundation_polygon_with_wrong_zs = nil
    for floor in (0..num_floors - 1)

      z = wall_height * floor + foundation_offset

      if has_garage and z == foundation_offset # first floor and has garage

        # create garage zone
        garage_zone = OpenStudio::Model::ThermalZone.new(model)
        garage_zone.setName("garage zone")

        # make points and polygons
        if garage_position == "Right"
          garage_sw_point = OpenStudio::Point3d.new(length - garage_width, -garage_protrusion * garage_depth, z)
          garage_nw_point = OpenStudio::Point3d.new(length - garage_width, garage_depth - garage_protrusion * garage_depth, z)
          garage_ne_point = OpenStudio::Point3d.new(length, garage_depth - garage_protrusion * garage_depth, z)
          garage_se_point = OpenStudio::Point3d.new(length, -garage_protrusion * garage_depth, z)
          garage_polygon = Geometry.make_polygon(garage_sw_point, garage_nw_point, garage_ne_point, garage_se_point)
        elsif garage_position == "Left"
          garage_sw_point = OpenStudio::Point3d.new(0, -garage_protrusion * garage_depth, z)
          garage_nw_point = OpenStudio::Point3d.new(0, garage_depth - garage_protrusion * garage_depth, z)
          garage_ne_point = OpenStudio::Point3d.new(garage_width, garage_depth - garage_protrusion * garage_depth, z)
          garage_se_point = OpenStudio::Point3d.new(garage_width, -garage_protrusion * garage_depth, z)
          garage_polygon = Geometry.make_polygon(garage_sw_point, garage_nw_point, garage_ne_point, garage_se_point)
        end

        # make space
        garage_space = OpenStudio::Model::Space::fromFloorPrint(garage_polygon, wall_height, model)
        garage_space = garage_space.get
        garage_space_name = "garage space"
        garage_space.setName(garage_space_name)
        if space_types_hash.keys.include? Constants.SpaceTypeGarage
          garage_space_type = space_types_hash[Constants.SpaceTypeGarage]
        else
          garage_space_type = OpenStudio::Model::SpaceType.new(model)
          garage_space_type.setStandardsSpaceType(Constants.SpaceTypeGarage)
          space_types_hash[Constants.SpaceTypeGarage] = garage_space_type
        end
        garage_space.setSpaceType(garage_space_type)
        runner.registerInfo("Set #{garage_space_name}.")

        # set this to the garage zone
        garage_space.setThermalZone(garage_zone)

        m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
        m[0, 3] = 0
        m[1, 3] = 0
        m[2, 3] = z
        garage_space.changeTransformation(OpenStudio::Transformation.new(m))

        if garage_position == "Right"
          sw_point = OpenStudio::Point3d.new(0, 0, z)
          nw_point = OpenStudio::Point3d.new(0, width, z)
          ne_point = OpenStudio::Point3d.new(length, width, z)
          se_point = OpenStudio::Point3d.new(length, 0, z)
          l_se_point = OpenStudio::Point3d.new(length - garage_width, 0, z)
          if (garage_depth < width or garage_protrusion > 0) and garage_protrusion < 1 # garage protrudes but not fully
            living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, garage_ne_point, garage_nw_point, l_se_point)
          elsif garage_protrusion < 1 # garage fits perfectly within living space
            living_polygon = Geometry.make_polygon(sw_point, nw_point, garage_nw_point, garage_sw_point)
          else # garage fully protrudes
            living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
          end
        elsif garage_position == "Left"
          sw_point = OpenStudio::Point3d.new(0, 0, z)
          nw_point = OpenStudio::Point3d.new(0, width, z)
          ne_point = OpenStudio::Point3d.new(length, width, z)
          se_point = OpenStudio::Point3d.new(length, 0, z)
          l_sw_point = OpenStudio::Point3d.new(garage_width, 0, z)
          if (garage_depth < width or garage_protrusion > 0) and garage_protrusion < 1 # garage protrudes but not fully
            living_polygon = Geometry.make_polygon(garage_nw_point, nw_point, ne_point, se_point, l_sw_point, garage_ne_point)
          elsif garage_protrusion < 1 # garage fits perfectly within living space
            living_polygon = Geometry.make_polygon(garage_se_point, garage_ne_point, ne_point, se_point)
          else # garage fully protrudes
            living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
          end
        end
        foundation_polygon_with_wrong_zs = living_polygon

      else # first floor without garage or above first floor

        if has_garage
          garage_se_point = OpenStudio::Point3d.new(garage_se_point.x, garage_se_point.y, wall_height * floor + foundation_offset)
          garage_sw_point = OpenStudio::Point3d.new(garage_sw_point.x, garage_sw_point.y, wall_height * floor + foundation_offset)
          garage_nw_point = OpenStudio::Point3d.new(garage_nw_point.x, garage_nw_point.y, wall_height * floor + foundation_offset)
          garage_ne_point = OpenStudio::Point3d.new(garage_ne_point.x, garage_ne_point.y, wall_height * floor + foundation_offset)
          if garage_position == "Right"
            sw_point = OpenStudio::Point3d.new(0, 0, z)
            nw_point = OpenStudio::Point3d.new(0, width, z)
            ne_point = OpenStudio::Point3d.new(length, width, z)
            se_point = OpenStudio::Point3d.new(length, 0, z)
            l_se_point = OpenStudio::Point3d.new(length - garage_width, 0, z)
            if garage_protrusion > 0 # garage protrudes
              living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, garage_se_point, garage_sw_point, l_se_point)
            else # garage does not protrude
              living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
            end
          elsif garage_position == "Left"
            sw_point = OpenStudio::Point3d.new(0, 0, z)
            nw_point = OpenStudio::Point3d.new(0, width, z)
            ne_point = OpenStudio::Point3d.new(length, width, z)
            se_point = OpenStudio::Point3d.new(length, 0, z)
            l_sw_point = OpenStudio::Point3d.new(garage_width, 0, z)
            if garage_protrusion > 0 # garage protrudes
              living_polygon = Geometry.make_polygon(garage_sw_point, nw_point, ne_point, se_point, l_sw_point, garage_se_point)
            else # garage does not protrude
              living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
            end
          end

        else

          sw_point = OpenStudio::Point3d.new(0, 0, z)
          nw_point = OpenStudio::Point3d.new(0, width, z)
          ne_point = OpenStudio::Point3d.new(length, width, z)
          se_point = OpenStudio::Point3d.new(length, 0, z)
          living_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
          if z == foundation_offset
            foundation_polygon_with_wrong_zs = living_polygon
          end

        end

      end

      # make space
      living_space = OpenStudio::Model::Space::fromFloorPrint(living_polygon, wall_height, model)
      living_space = living_space.get
      if floor > 0
        living_space_name = "living space|story #{floor + 1}"
      else
        living_space_name = "living space"
      end
      living_space.setName(living_space_name)
      if space_types_hash.keys.include? Constants.SpaceTypeLiving
        living_space_type = space_types_hash[Constants.SpaceTypeLiving]
      else
        living_space_type = OpenStudio::Model::SpaceType.new(model)
        living_space_type.setStandardsSpaceType(Constants.SpaceTypeLiving)
        space_types_hash[Constants.SpaceTypeLiving] = living_space_type
      end
      living_space.setSpaceType(living_space_type)
      runner.registerInfo("Set #{living_space_name}.")

      # set these to the living zone
      living_space.setThermalZone(living_zone)

      m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
      m[0, 3] = 0
      m[1, 3] = 0
      m[2, 3] = z
      living_space.changeTransformation(OpenStudio::Transformation.new(m))

    end

    # Attic
    if roof_type != "flat"

      z = z + wall_height

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
      polygon_floor = Geometry.make_polygon(roof_nw_point, roof_ne_point, roof_se_point, roof_sw_point)
      side_type = nil
      if roof_type == "gable"
        if length >= width
          roof_w_point = OpenStudio::Point3d.new(0, width / 2.0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length, width / 2.0, z + attic_height)
          polygon_s_roof = Geometry.make_polygon(roof_e_point, roof_w_point, roof_sw_point, roof_se_point)
          polygon_n_roof = Geometry.make_polygon(roof_w_point, roof_e_point, roof_ne_point, roof_nw_point)
          polygon_w_wall = Geometry.make_polygon(roof_w_point, roof_nw_point, roof_sw_point)
          polygon_e_wall = Geometry.make_polygon(roof_e_point, roof_se_point, roof_ne_point)
        else
          roof_w_point = OpenStudio::Point3d.new(length / 2.0, 0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length / 2.0, width, z + attic_height)
          polygon_s_roof = Geometry.make_polygon(roof_e_point, roof_w_point, roof_se_point, roof_ne_point)
          polygon_n_roof = Geometry.make_polygon(roof_w_point, roof_e_point, roof_nw_point, roof_sw_point)
          polygon_w_wall = Geometry.make_polygon(roof_w_point, roof_sw_point, roof_se_point)
          polygon_e_wall = Geometry.make_polygon(roof_e_point, roof_ne_point, roof_nw_point)
        end
        side_type = "Wall"
      elsif roof_type == "hip"
        if length >= width
          roof_w_point = OpenStudio::Point3d.new(width / 2.0, width / 2.0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length - width / 2.0, width / 2.0, z + attic_height)
          polygon_s_roof = Geometry.make_polygon(roof_e_point, roof_w_point, roof_sw_point, roof_se_point)
          polygon_n_roof = Geometry.make_polygon(roof_w_point, roof_e_point, roof_ne_point, roof_nw_point)
          polygon_w_wall = Geometry.make_polygon(roof_w_point, roof_nw_point, roof_sw_point)
          polygon_e_wall = Geometry.make_polygon(roof_e_point, roof_se_point, roof_ne_point)
        else
          roof_w_point = OpenStudio::Point3d.new(length / 2.0, length / 2.0, z + attic_height)
          roof_e_point = OpenStudio::Point3d.new(length / 2.0, width - length / 2.0, z + attic_height)
          polygon_s_roof = Geometry.make_polygon(roof_e_point, roof_w_point, roof_se_point, roof_ne_point)
          polygon_n_roof = Geometry.make_polygon(roof_w_point, roof_e_point, roof_nw_point, roof_sw_point)
          polygon_w_wall = Geometry.make_polygon(roof_w_point, roof_sw_point, roof_se_point)
          polygon_e_wall = Geometry.make_polygon(roof_e_point, roof_ne_point, roof_nw_point)
        end
        side_type = "RoofCeiling"
      end

      # make surfaces
      surface_floor = OpenStudio::Model::Surface.new(polygon_floor, model)
      surface_floor.setSurfaceType("Floor")
      surface_floor.setOutsideBoundaryCondition("Surface")
      surface_s_roof = OpenStudio::Model::Surface.new(polygon_s_roof, model)
      surface_s_roof.setSurfaceType("RoofCeiling")
      surface_s_roof.setOutsideBoundaryCondition("Outdoors")
      surface_n_roof = OpenStudio::Model::Surface.new(polygon_n_roof, model)
      surface_n_roof.setSurfaceType("RoofCeiling")
      surface_n_roof.setOutsideBoundaryCondition("Outdoors")
      surface_w_wall = OpenStudio::Model::Surface.new(polygon_w_wall, model)
      surface_w_wall.setSurfaceType(side_type)
      surface_w_wall.setOutsideBoundaryCondition("Outdoors")
      surface_e_wall = OpenStudio::Model::Surface.new(polygon_e_wall, model)
      surface_e_wall.setSurfaceType(side_type)
      surface_e_wall.setOutsideBoundaryCondition("Outdoors")

      # assign surfaces to the space
      attic_space = OpenStudio::Model::Space.new(model)
      surface_floor.setSpace(attic_space)
      surface_s_roof.setSpace(attic_space)
      surface_n_roof.setSpace(attic_space)
      surface_w_wall.setSpace(attic_space)
      surface_e_wall.setSpace(attic_space)

      # set these to the attic zone
      if attic_type == "unfinished attic"
        # create attic zone
        attic_zone = OpenStudio::Model::ThermalZone.new(model)
        attic_zone.setName("unfinished attic zone")
        attic_space.setThermalZone(attic_zone)
        attic_space_name = "unfinished attic space"
        attic_space_type_name = "unfinished attic"
      elsif attic_type == "finished attic"
        attic_space.setThermalZone(living_zone)
        attic_space_name = "finished attic space"
        attic_space_type_name = Constants.SpaceTypeLiving
      end
      attic_space.setName(attic_space_name)
      if space_types_hash.keys.include? attic_space_type_name
        attic_space_type = space_types_hash[attic_space_type_name]
      else
        attic_space_type = OpenStudio::Model::SpaceType.new(model)
        attic_space_type.setStandardsSpaceType(attic_space_type_name)
        space_types_hash[attic_space_type_name] = attic_space_type
      end
      attic_space.setSpaceType(attic_space_type)
      runner.registerInfo("Set #{attic_space_name}.")

      m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
      m[0, 3] = 0
      m[1, 3] = 0
      m[2, 3] = z
      attic_space.changeTransformation(OpenStudio::Transformation.new(m))

    end

    # Foundation
    if ["crawlspace", "unfinished basement", "finished basement", "pier and beam"].include? foundation_type

      z = -foundation_height + foundation_offset

      # create foundation zone
      foundation_zone = OpenStudio::Model::ThermalZone.new(model)
      if foundation_type == "crawlspace"
        foundation_zone_name = "crawl zone"
      elsif foundation_type == "unfinished basement"
        foundation_zone_name = "unfinished basement zone"
      elsif foundation_type == "finished basement"
        foundation_zone_name = "finished basement zone"
      elsif foundation_type == "pier and beam"
        foundation_zone_name = "pier and beam zone"
      end
      foundation_zone.setName(foundation_zone_name)

      # make polygons
      p = OpenStudio::Point3dVector.new
      foundation_polygon_with_wrong_zs.each do |point|
        p << OpenStudio::Point3d.new(point.x, point.y, z)
      end
      foundation_polygon = p

      # make space
      foundation_space = OpenStudio::Model::Space::fromFloorPrint(foundation_polygon, foundation_height, model)
      foundation_space = foundation_space.get
      if foundation_type == "crawlspace"
        foundation_space_name = "crawl space"
        foundation_space_type_name = Constants.SpaceTypeCrawl
      elsif foundation_type == "unfinished basement"
        foundation_space_name = "unfinished basement space"
        foundation_space_type_name = Constants.SpaceTypeUnfinishedBasement
      elsif foundation_type == "finished basement"
        foundation_space_name = "finished basement space"
        foundation_space_type_name = Constants.SpaceTypeFinishedBasement
      elsif foundation_type == "pier and beam"
        foundation_space_name = "pier and beam space"
        foundation_space_type_name = Constants.SpaceTypePierBeam
      end
      foundation_space.setName(foundation_space_name)
      if space_types_hash.keys.include? foundation_space_type_name
        foundation_space_type = space_types_hash[foundation_space_type_name]
      else
        foundation_space_type = OpenStudio::Model::SpaceType.new(model)
        foundation_space_type.setStandardsSpaceType(foundation_space_type_name)
        space_types_hash[foundation_space_type_name] = foundation_space_type
      end
      foundation_space.setSpaceType(foundation_space_type)
      runner.registerInfo("Set #{foundation_space_name}.")

      # set these to the foundation zone
      foundation_space.setThermalZone(foundation_zone)

      # set foundation walls outside boundary condition
      spaces = model.getSpaces
      spaces.each do |space|
        if Geometry.get_space_floor_z(space) + UnitConversions.convert(space.zOrigin, "m", "ft") < 0
          surfaces = space.surfaces
          surfaces.each do |surface|
            next if surface.surfaceType.downcase != "wall"

            surface.setOutsideBoundaryCondition("Ground")
          end
        end
      end

      m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
      m[0, 3] = 0
      m[1, 3] = 0
      m[2, 3] = z
      foundation_space.changeTransformation(OpenStudio::Transformation.new(m))

    end

    # put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
    end

    # intersect and match surfaces for each space in the vector
    OpenStudio::Model.intersectSurfaces(spaces)
    OpenStudio::Model.matchSurfaces(spaces)

    if has_garage and roof_type != "flat"
      if num_floors > 1
        space_with_roof_over_garage = living_space
      else
        space_with_roof_over_garage = garage_space
      end
      space_with_roof_over_garage.surfaces.each do |surface|
        if surface.surfaceType.downcase == "roofceiling" and surface.outsideBoundaryCondition.downcase == "outdoors"
          n_points = []
          s_points = []
          surface.vertices.each do |vertex|
            if vertex.y == 0
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
            if not attic_type == "finished attic"
              nw_point = OpenStudio::Point3d.new(nw_point.x, nw_point.y, living_space.zOrigin + nw_point.z)
              ne_point = OpenStudio::Point3d.new(ne_point.x, ne_point.y, living_space.zOrigin + ne_point.z)
              sw_point = OpenStudio::Point3d.new(sw_point.x, sw_point.y, living_space.zOrigin + sw_point.z)
              se_point = OpenStudio::Point3d.new(se_point.x, se_point.y, living_space.zOrigin + se_point.z)
            else
              nw_point = OpenStudio::Point3d.new(nw_point.x, nw_point.y, nw_point.z - living_space.zOrigin)
              ne_point = OpenStudio::Point3d.new(ne_point.x, ne_point.y, ne_point.z - living_space.zOrigin)
              sw_point = OpenStudio::Point3d.new(sw_point.x, sw_point.y, sw_point.z - living_space.zOrigin)
              se_point = OpenStudio::Point3d.new(se_point.x, se_point.y, se_point.z - living_space.zOrigin)
            end
          else
            nw_point = OpenStudio::Point3d.new(nw_point.x, nw_point.y, num_floors * nw_point.z)
            ne_point = OpenStudio::Point3d.new(ne_point.x, ne_point.y, num_floors * ne_point.z)
            sw_point = OpenStudio::Point3d.new(sw_point.x, sw_point.y, num_floors * sw_point.z)
            se_point = OpenStudio::Point3d.new(se_point.x, se_point.y, num_floors * se_point.z)
          end

          garage_attic_height = (ne_point.x - nw_point.x) / 2 * roof_pitch

          garage_roof_pitch = roof_pitch
          if garage_attic_height >= attic_height
            garage_attic_height = attic_height - 0.01 # garage attic height slightly below attic height so that we don't get any roof decks with only three vertices
            garage_roof_pitch = garage_attic_height / (garage_width / 2)
            runner.registerWarning("The garage pitch was changed to accommodate garage ridge >= house ridge (from #{roof_pitch.round(3)} to #{garage_roof_pitch.round(3)}).")
          end

          if num_floors == 1
            if not attic_type == "finished attic"
              roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x) / 2, nw_point.y + garage_attic_height / roof_pitch, living_space.zOrigin + wall_height + garage_attic_height)
              roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x) / 2, sw_point.y, living_space.zOrigin + wall_height + garage_attic_height)
            else
              roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x) / 2, nw_point.y + garage_attic_height / roof_pitch, garage_attic_height + wall_height)
              roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x) / 2, sw_point.y, garage_attic_height + wall_height)
            end
          else
            roof_n_point = OpenStudio::Point3d.new((nw_point.x + ne_point.x) / 2, nw_point.y + garage_attic_height / roof_pitch, num_floors * wall_height + garage_attic_height)
            roof_s_point = OpenStudio::Point3d.new((sw_point.x + se_point.x) / 2, sw_point.y, num_floors * wall_height + garage_attic_height)
          end

          polygon_w_roof = Geometry.make_polygon(nw_point, sw_point, roof_s_point, roof_n_point)
          polygon_e_roof = Geometry.make_polygon(ne_point, roof_n_point, roof_s_point, se_point)
          polygon_n_wall = Geometry.make_polygon(nw_point, roof_n_point, ne_point)
          polygon_s_wall = Geometry.make_polygon(sw_point, se_point, roof_s_point)

          deck_w = OpenStudio::Model::Surface.new(polygon_w_roof, model)
          deck_w.setSurfaceType("RoofCeiling")
          deck_w.setOutsideBoundaryCondition("Outdoors")
          deck_e = OpenStudio::Model::Surface.new(polygon_e_roof, model)
          deck_e.setSurfaceType("RoofCeiling")
          deck_e.setOutsideBoundaryCondition("Outdoors")
          wall_n = OpenStudio::Model::Surface.new(polygon_n_wall, model)
          wall_n.setSurfaceType("Wall")
          wall_s = OpenStudio::Model::Surface.new(polygon_s_wall, model)
          wall_s.setSurfaceType("Wall")
          wall_s.setOutsideBoundaryCondition("Outdoors")

          garage_attic_space = OpenStudio::Model::Space.new(model)
          garage_attic_space_name = "garage attic space"
          garage_attic_space.setName(garage_attic_space_name)
          deck_w.setSpace(garage_attic_space)
          deck_e.setSpace(garage_attic_space)
          wall_n.setSpace(garage_attic_space)
          wall_s.setSpace(garage_attic_space)

          if attic_type == "finished attic"
            garage_attic_space_type_name = Constants.SpaceTypeLiving
            garage_attic_space.setThermalZone(living_zone)
          else
            if num_floors > 1
              garage_attic_space_type_name = Constants.SpaceTypeUnfinishedAttic
              garage_attic_space.setThermalZone(attic_zone)
            else
              garage_attic_space_type_name = Constants.SpaceTypeGarageAttic
              garage_attic_space.setThermalZone(garage_zone)
            end
          end

          surface.createAdjacentSurface(garage_attic_space) # garage attic floor
          if space_types_hash.keys.include? garage_attic_space_type_name
            garage_attic_space_type = space_types_hash[garage_attic_space_type_name]
          else
            garage_attic_space_type = OpenStudio::Model::SpaceType.new(model)
            garage_attic_space_type.setStandardsSpaceType(garage_attic_space_type_name)
            space_types_hash[garage_attic_space_type_name] = garage_attic_space_type
          end
          garage_attic_space.setSpaceType(garage_attic_space_type)
          runner.registerInfo("Set #{garage_attic_space_name}.")

          # put all of the spaces in the model into a vector
          spaces = OpenStudio::Model::SpaceVector.new
          model.getSpaces.each do |space|
            spaces << space
          end

          # intersect and match surfaces for each space in the vector
          OpenStudio::Model.intersectSurfaces(spaces)
          OpenStudio::Model.matchSurfaces(spaces)

          # remove triangular surface between unfinished attic and garage attic
          unless attic_space.nil?
            attic_space.surfaces.each do |surface|
              next if roof_type == "hip"
              next unless surface.vertices.length == 3
              next unless (90 - surface.tilt * 180 / Math::PI).abs > 0.01 # don't remove the vertical attic walls
              next unless surface.adjacentSurface.is_initialized

              surface.adjacentSurface.get.remove
              surface.remove
            end
          end

          garage_attic_space.surfaces.each do |surface|
            if num_floors > 1 or attic_type == "finished attic"
              m = Geometry.initialize_transformation_matrix(OpenStudio::Matrix.new(4, 4, 0))
              m[2, 3] = -attic_space.zOrigin
              transformation = OpenStudio::Transformation.new(m)
              new_vertices = transformation * surface.vertices
              surface.setVertices(new_vertices)
              surface.setSpace(attic_space)
            end
          end

          if num_floors > 1 or attic_type == "finished attic"
            garage_attic_space.remove
          end

          break

        end
      end
    end

    # set foundation outside boundary condition to Kiva "foundation"
    model.getSurfaces.each do |surface|
      next if surface.outsideBoundaryCondition.downcase != "ground"

      surface.setOutsideBoundaryCondition("Foundation")
    end

    # set foundation walls adjacent to garage to adiabatic
    foundation_walls = []
    model.getSurfaces.each do |surface|
      next if surface.surfaceType.downcase != "wall"
      next if surface.outsideBoundaryCondition.downcase != "foundation"

      foundation_walls << surface
    end
    garage_spaces = Geometry.get_garage_spaces(model.getSpaces)
    garage_spaces.each do |garage_space|
      garage_space.surfaces.each do |surface|
        next if surface.surfaceType.downcase != "floor"

        adjacent_wall_surfaces = Geometry.get_walls_connected_to_floor(foundation_walls, surface, false)
        adjacent_wall_surfaces.each do |adjacent_wall_surface|
          adjacent_wall_surface.setOutsideBoundaryCondition("Adiabatic")
        end
      end
    end

    return true
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

  def self.get_garage_spaces(spaces)
    garage_spaces = []
    spaces.each do |space|
      next if not self.is_garage(space)

      garage_spaces << space
    end
    return garage_spaces
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
    if ["living", "finished basement", "kitchen", "bedroom",
        "bathroom", "laundry room"].include? space_type
      return true
    end

    return false
  end
end
