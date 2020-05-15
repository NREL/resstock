# frozen_string_literal: true

class Geometry
  def self.get_zone_volume(zone)
    if zone.isVolumeAutocalculated || (not zone.volume.is_initialized)
      # Calculate volume from spaces
      volume = 0
      zone.spaces.each do |space|
        volume += UnitConversions.convert(space.volume, 'm^3', 'ft^3')
      end
    else
      volume = UnitConversions.convert(zone.volume.get, 'm^3', 'ft^3')
    end
    if volume <= 0
      fail 'Could not find any volume.'
    end

    return volume
  end

  # Calculates space heights as the max z coordinate minus the min z coordinate
  def self.get_height_of_spaces(spaces)
    minzs = []
    maxzs = []
    spaces.each do |space|
      zvalues = getSurfaceZValues(space.surfaces)
      minzs << zvalues.min + UnitConversions.convert(space.zOrigin, 'm', 'ft')
      maxzs << zvalues.max + UnitConversions.convert(space.zOrigin, 'm', 'ft')
    end
    return maxzs.max - minzs.min
  end

  def self.get_max_z_of_spaces(spaces)
    maxzs = []
    spaces.each do |space|
      zvalues = getSurfaceZValues(space.surfaces)
      maxzs << zvalues.max + UnitConversions.convert(space.zOrigin, 'm', 'ft')
    end
    return maxzs.max
  end

  # Calculates the surface height as the max z coordinate minus the min z coordinate
  def self.surface_height(surface)
    zvalues = getSurfaceZValues([surface])
    minz = zvalues.min
    maxz = zvalues.max
    return maxz - minz
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

  def self.space_is_conditioned(space)
    unless space.isPlenum
      if space.spaceType.is_initialized
        if space.spaceType.get.standardsSpaceType.is_initialized
          return is_conditioned_space_type(space.spaceType.get.standardsSpaceType.get)
        end
      end
    end
    return false
  end

  def self.is_conditioned_space_type(space_type)
    if [HPXML::LocationLivingSpace].include? space_type
      return true
    end

    return false
  end

  def self.get_space_from_location(model, location, location_hierarchy)
    if location == Constants.Auto
      location_hierarchy.each do |space_type|
        model.getSpaces.each do |space|
          next if not space_is_of_type(space, space_type)

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
    return
  end

  # Return an array of x values for surfaces passed in. The values will be relative to the parent origin. This was intended for spaces.
  def self.getSurfaceXValues(surfaceArray)
    xValueArray = []
    surfaceArray.each do |surface|
      surface.vertices.each do |vertex|
        xValueArray << UnitConversions.convert(vertex.x, 'm', 'ft')
      end
    end
    return xValueArray
  end

  # Return an array of y values for surfaces passed in. The values will be relative to the parent origin. This was intended for spaces.
  def self.getSurfaceYValues(surfaceArray)
    yValueArray = []
    surfaceArray.each do |surface|
      surface.vertices.each do |vertex|
        yValueArray << UnitConversions.convert(vertex.y, 'm', 'ft')
      end
    end
    return yValueArray
  end

  # Return an array of z values for surfaces passed in. The values will be relative to the parent origin. This was intended for spaces.
  def self.getSurfaceZValues(surfaceArray)
    zValueArray = []
    surfaceArray.each do |surface|
      surface.vertices.each do |vertex|
        zValueArray << UnitConversions.convert(vertex.z, 'm', 'ft')
      end
    end
    return zValueArray
  end

  def self.get_z_origin_for_zone(zone)
    z_origins = []
    zone.spaces.each do |space|
      z_origins << UnitConversions.convert(space.zOrigin, 'm', 'ft')
    end
    return z_origins.min
  end

  # Takes in a list of spaces and returns the total above grade wall area
  def self.calculate_above_grade_wall_area(spaces)
    wall_area = 0
    spaces.each do |space|
      space.surfaces.each do |surface|
        next if surface.surfaceType.downcase != 'wall'
        next if surface.outsideBoundaryCondition.downcase == 'foundation'

        wall_area += UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2')
      end
    end
    return wall_area
  end

  def self.calculate_above_grade_exterior_wall_area(spaces)
    wall_area = 0
    spaces.each do |space|
      space.surfaces.each do |surface|
        next if surface.surfaceType.downcase != 'wall'
        next if surface.outsideBoundaryCondition.downcase != 'outdoors'
        next if surface.outsideBoundaryCondition.downcase == 'foundation'
        next unless space_is_conditioned(surface.space.get)

        wall_area += UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2')
      end
    end
    return wall_area
  end

  def self.get_roof_pitch(surfaces)
    tilts = []
    surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'roofceiling'
      next if (surface.outsideBoundaryCondition.downcase != 'outdoors') && (surface.outsideBoundaryCondition.downcase != 'adiabatic')

      tilts << surface.tilt
    end
    return UnitConversions.convert(tilts.max, 'rad', 'deg')
  end

  # Checks if the surface is between conditioned and unconditioned space
  def self.is_interzonal_surface(surface)
    if (surface.outsideBoundaryCondition.downcase != 'surface') || (not surface.space.is_initialized) || (not surface.adjacentSurface.is_initialized)
      return false
    end

    adjacent_surface = surface.adjacentSurface.get
    if not adjacent_surface.space.is_initialized
      return false
    end
    if space_is_conditioned(surface.space.get) == space_is_conditioned(adjacent_surface.space.get)
      return false
    end

    return true
  end

  # TODO: Remove these methods
  def self.is_living(space_or_zone)
    return space_or_zone_is_of_type(space_or_zone, HPXML::LocationLivingSpace)
  end

  def self.is_vented_crawl(space_or_zone)
    return space_or_zone_is_of_type(space_or_zone, HPXML::LocationCrawlspaceVented)
  end

  def self.is_unvented_crawl(space_or_zone)
    return space_or_zone_is_of_type(space_or_zone, HPXML::LocationCrawlspaceUnvented)
  end

  def self.is_unconditioned_basement(space_or_zone)
    return space_or_zone_is_of_type(space_or_zone, HPXML::LocationBasementUnconditioned)
  end

  def self.is_vented_attic(space_or_zone)
    return space_or_zone_is_of_type(space_or_zone, HPXML::LocationAtticVented)
  end

  def self.is_unvented_attic(space_or_zone)
    return space_or_zone_is_of_type(space_or_zone, HPXML::LocationAtticUnvented)
  end

  def self.is_garage(space_or_zone)
    return space_or_zone_is_of_type(space_or_zone, HPXML::LocationGarage)
  end

  def self.space_or_zone_is_of_type(space_or_zone, space_type)
    if space_or_zone.is_a? OpenStudio::Model::Space
      return space_is_of_type(space_or_zone, space_type)
    elsif space_or_zone.is_a? OpenStudio::Model::ThermalZone
      return zone_is_of_type(space_or_zone, space_type)
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
      return space_is_of_type(space, space_type)
    end
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

  def self.get_surface_length(surface)
    xvalues = getSurfaceXValues([surface])
    yvalues = getSurfaceYValues([surface])
    xrange = xvalues.max - xvalues.min
    yrange = yvalues.max - yvalues.min
    if xrange > yrange
      return xrange
    end

    return yrange
  end

  def self.get_surface_height(surface)
    zvalues = getSurfaceZValues([surface])
    zrange = zvalues.max - zvalues.min
    return zrange
  end

  def self.space_has_foundation_walls(space)
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'wall'
      next if surface.outsideBoundaryCondition.downcase != 'foundation'

      return true
    end
    return false
  end

  def self.get_spaces_above_grade_exterior_walls(space)
    above_grade_exterior_walls = []
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'wall'
      next if surface.outsideBoundaryCondition.downcase != 'outdoors'

      above_grade_exterior_walls << surface
    end
    return above_grade_exterior_walls
  end

  def self.get_spaces_above_grade_exterior_floors(space)
    above_grade_exterior_floors = []
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'floor'
      next if surface.outsideBoundaryCondition.downcase != 'outdoors'

      above_grade_exterior_floors << surface
    end
    return above_grade_exterior_floors
  end

  def self.get_spaces_above_grade_ground_floors(space)
    return [] if Geometry.space_has_foundation_walls(space)

    above_grade_ground_floors = []
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'floor'
      next if surface.outsideBoundaryCondition.downcase != 'foundation'

      above_grade_ground_floors << surface
    end
    return above_grade_ground_floors
  end

  def self.get_spaces_above_grade_exterior_roofs(space)
    above_grade_exterior_roofs = []
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'roofceiling'
      next if surface.outsideBoundaryCondition.downcase != 'outdoors'

      above_grade_exterior_roofs << surface
    end
    return above_grade_exterior_roofs
  end

  def self.get_spaces_interzonal_walls(space)
    interzonal_walls = []
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'wall'
      next if not is_interzonal_surface(surface)

      interzonal_walls << surface
    end
    return interzonal_walls
  end

  def self.get_sfa_mf_space_floors_and_ceilings(space)
    mf_floors = []
    space.surfaces.each do |surface|
      next if (surface.surfaceType.downcase != 'floor') && (surface.surfaceType.downcase != 'roofceiling')
      next if surface.outsideBoundaryCondition.downcase != 'othersidecoefficients'

      mf_floors << surface
    end
    return mf_floors
  end

  def self.get_sfa_mf_space_walls(space)
    mf_walls = []
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'wall'
      next if surface.outsideBoundaryCondition.downcase != 'othersidecoefficients'

      mf_walls << surface
    end
    return mf_walls
  end

  def self.get_spaces_interzonal_floors_and_ceilings(space)
    interzonal_floors = []
    space.surfaces.each do |surface|
      next if (surface.surfaceType.downcase != 'floor') && (surface.surfaceType.downcase != 'roofceiling')
      next if not is_interzonal_surface(surface)

      interzonal_floors << surface
    end
    return interzonal_floors
  end

  def self.get_spaces_below_grade_exterior_walls(space)
    below_grade_exterior_walls = []

    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'wall'
      next if surface.outsideBoundaryCondition.downcase != 'foundation'

      below_grade_exterior_walls << surface
    end
    return below_grade_exterior_walls
  end

  def self.get_spaces_below_grade_exterior_floors(space)
    return [] if not Geometry.space_has_foundation_walls(space)

    below_grade_exterior_floors = []
    space.surfaces.each do |surface|
      next if surface.surfaceType.downcase != 'floor'
      next if surface.outsideBoundaryCondition.downcase != 'foundation'

      below_grade_exterior_floors << surface
    end
    return below_grade_exterior_floors
  end

  def self.process_occupants(model, num_occ, occ_gain, sens_frac, lat_frac, weekday_sch, weekend_sch, monthly_sch,
                             cfa, nbeds, space)

    # Error checking
    if (sens_frac < 0) || (sens_frac > 1)
      fail 'Sensible fraction must be greater than or equal to 0 and less than or equal to 1.'
    end
    if (lat_frac < 0) || (lat_frac > 1)
      fail 'Latent fraction must be greater than or equal to 0 and less than or equal to 1.'
    end
    if lat_frac + sens_frac > 1
      fail 'Sum of sensible and latent fractions must be less than or equal to 1.'
    end

    activity_per_person = UnitConversions.convert(occ_gain, 'Btu/hr', 'W')

    # Hard-coded convective, radiative, latent, and lost fractions
    occ_lat = lat_frac
    occ_sens = sens_frac
    occ_conv = 0.442 * occ_sens
    occ_rad = 0.558 * occ_sens
    occ_lost = 1 - occ_lat - occ_conv - occ_rad

    space_obj_name = "#{Constants.ObjectNameOccupants}"
    space_num_occ = num_occ * UnitConversions.convert(space.floorArea, 'm^2', 'ft^2') / cfa

    # Create schedule
    people_sch = MonthWeekdayWeekendSchedule.new(model, Constants.ObjectNameOccupants + ' schedule', weekday_sch, weekend_sch, monthly_sch, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)

    # Create schedule
    activity_sch = OpenStudio::Model::ScheduleRuleset.new(model, activity_per_person)

    # Add people definition for the occ
    occ_def = OpenStudio::Model::PeopleDefinition.new(model)
    occ = OpenStudio::Model::People.new(occ_def)
    occ.setName(space_obj_name)
    occ.setSpace(space)
    occ_def.setName(space_obj_name)
    occ_def.setNumberOfPeopleCalculationMethod('People', 1)
    occ_def.setNumberofPeople(space_num_occ)
    occ_def.setFractionRadiant(occ_rad)
    occ_def.setSensibleHeatFraction(occ_sens)
    occ_def.setMeanRadiantTemperatureCalculationType('ZoneAveraged')
    occ_def.setCarbonDioxideGenerationRate(0)
    occ_def.setEnableASHRAE55ComfortWarnings(false)
    occ.setActivityLevelSchedule(activity_sch)
    occ.setNumberofPeopleSchedule(people_sch.schedule)
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
end
