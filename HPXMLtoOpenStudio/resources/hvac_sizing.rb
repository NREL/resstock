# frozen_string_literal: true

class HVACSizing
  def self.calculate(weather, hpxml_bldg, cfa, hvac_systems)
    # Calculates heating/cooling design loads, and selects equipment
    # values (e.g., capacities, airflows) specific to each HVAC system.
    # Calculations generally follow ACCA Manual J/S.

    @hpxml_bldg = hpxml_bldg
    @cfa = cfa

    process_site_calcs_and_design_temps(weather)

    # Calculate loads for the conditioned thermal zone
    bldg_design_loads = DesignLoads.new
    process_load_windows_skylights(bldg_design_loads, weather)
    process_load_doors(bldg_design_loads)
    process_load_walls(bldg_design_loads)
    process_load_roofs(bldg_design_loads)
    process_load_ceilings(bldg_design_loads)
    process_load_floors(bldg_design_loads)
    process_load_slabs(bldg_design_loads)
    process_load_infiltration_ventilation(bldg_design_loads, weather)
    process_load_internal_gains(bldg_design_loads)

    # Aggregate zone loads into initial loads
    aggregate_loads(bldg_design_loads)

    # Loop through each HVAC system and calculate equipment values.
    all_hvac_sizing_values = {}
    system_design_loads = bldg_design_loads.dup
    hvac_systems.each do |hvac_system|
      hvac_heating, hvac_cooling = hvac_system[:heating], hvac_system[:cooling]
      set_hvac_types(hvac_heating, hvac_cooling)
      next if is_system_to_skip(hvac_heating)

      # Apply duct loads as needed
      set_fractions_load_served(hvac_heating, hvac_cooling)
      apply_hvac_temperatures(system_design_loads, hvac_heating, hvac_cooling)
      ducts_heat_load = calculate_load_ducts_heating(system_design_loads, hvac_heating)
      ducts_cool_load_sens, ducts_cool_load_lat = calculate_load_ducts_cooling(system_design_loads, weather, hvac_cooling)
      apply_load_ducts(bldg_design_loads, ducts_heat_load, ducts_cool_load_sens, ducts_cool_load_lat) # Update duct loads in reported building design loads

      hvac_sizing_values = HVACSizingValues.new
      apply_hvac_loads(hvac_heating, hvac_sizing_values, system_design_loads, ducts_heat_load, ducts_cool_load_sens, ducts_cool_load_lat)
      apply_hvac_size_limits(hvac_cooling)
      apply_hvac_heat_pump_logic(hvac_sizing_values, hvac_cooling)
      apply_hvac_equipment_adjustments(hvac_sizing_values, weather, hvac_heating, hvac_cooling, hvac_system)
      apply_hvac_installation_quality(hvac_sizing_values, hvac_heating, hvac_cooling)
      apply_hvac_fixed_capacities(hvac_sizing_values, hvac_heating, hvac_cooling)
      apply_hvac_ground_loop(hvac_sizing_values, weather, hvac_cooling)
      apply_hvac_finalize_airflows(hvac_sizing_values, hvac_heating, hvac_cooling)

      all_hvac_sizing_values[hvac_system] = hvac_sizing_values
    end

    return bldg_design_loads, all_hvac_sizing_values
  end

  private

  def self.is_system_to_skip(hvac_heating)
    # These shared systems should be converted to other equivalent
    # systems before being autosized
    if [HPXML::HVACTypeChiller,
        HPXML::HVACTypeCoolingTower].include?(@cooling_type)
      return true
    end
    if (@heating_type == HPXML::HVACTypeHeatPumpWaterLoopToAir) &&
       hvac_heating.fraction_heat_load_served.nil?
      return true
    end

    return false
  end

  def self.process_site_calcs_and_design_temps(weather)
    '''
    Site Calculations and Design Temperatures
    '''

    # CLTD adjustments based on daily temperature range
    @daily_range_temp_adjust = [4, 0, -5]

    # Manual J inside conditions
    @cool_setpoint = @hpxml_bldg.header.manualj_cooling_setpoint
    @heat_setpoint = @hpxml_bldg.header.manualj_heating_setpoint

    @cool_design_grains = UnitConversions.convert(weather.design.CoolingHumidityRatio, 'lbm/lbm', 'grains')

    # Calculate the design temperature differences
    @ctd = [@hpxml_bldg.header.manualj_cooling_design_temp - @cool_setpoint, 0.0].max
    @htd = [@heat_setpoint - @hpxml_bldg.header.manualj_heating_design_temp, 0.0].max

    # Calculate the average Daily Temperature Range (DTR) to determine the class (low, medium, high)
    dtr = weather.design.DailyTemperatureRange

    if dtr < 16.0
      @daily_range_num = 0.0   # Low
    elsif dtr > 25.0
      @daily_range_num = 2.0   # High
    else
      @daily_range_num = 1.0   # Medium
    end

    # Altitude Correction Factors (ACF) taken from Table 10A (sea level - 12,000 ft)
    acfs = [1.0, 0.97, 0.93, 0.89, 0.87, 0.84, 0.80, 0.77, 0.75, 0.72, 0.69, 0.66, 0.63]

    # Calculate the altitude correction factor (ACF) for the site
    alt_cnt = (weather.header.Altitude / 1000.0).to_i
    @acf = MathTools.interp2(weather.header.Altitude, alt_cnt * 1000.0, (alt_cnt + 1.0) * 1000.0, acfs[alt_cnt], acfs[alt_cnt + 1])

    # Calculate the interior humidity in Grains and enthalpy in Btu/lb for cooling
    cool_setpoint_c = UnitConversions.convert(@cool_setpoint, 'F', 'C')
    pwsat = 6.11 * 10**(7.5 * cool_setpoint_c / (237.3 + cool_setpoint_c)) / 10.0 # kPa, using https://www.weather.gov/media/epz/wxcalc/vaporPressure.pdf
    rh_indoor_cooling = 0.5 # Manual J is vague on the indoor RH but uses 50% in its examples
    hr_indoor_cooling = (0.62198 * rh_indoor_cooling * pwsat) / (UnitConversions.convert(weather.header.LocalPressure, 'atm', 'kPa') - rh_indoor_cooling * pwsat)
    @cool_indoor_grains = UnitConversions.convert(hr_indoor_cooling, 'lbm/lbm', 'grains')
    @wetbulb_indoor_cooling = Psychrometrics.Twb_fT_R_P(nil, @cool_setpoint, rh_indoor_cooling, UnitConversions.convert(weather.header.LocalPressure, 'atm', 'psi'))

    db_indoor_degC = UnitConversions.convert(@cool_setpoint, 'F', 'C')
    @enthalpy_indoor_cooling = (1.006 * db_indoor_degC + hr_indoor_cooling * (2501.0 + 1.86 * db_indoor_degC)) * UnitConversions.convert(1.0, 'kJ', 'Btu') * UnitConversions.convert(1.0, 'lbm', 'kg')
    @wetbulb_outdoor_cooling = weather.design.CoolingWetbulb

    # Inside air density
    avg_setpoint = (@cool_setpoint + @heat_setpoint) / 2.0
    @inside_air_dens = UnitConversions.convert(weather.header.LocalPressure, 'atm', 'Btu/ft^3') / (Gas.Air.r * (avg_setpoint + 460.0))

    # Design Temperatures

    @cool_design_temps = {}
    @heat_design_temps = {}

    locations = []
    (@hpxml_bldg.roofs + @hpxml_bldg.rim_joists + @hpxml_bldg.walls + @hpxml_bldg.foundation_walls + @hpxml_bldg.floors + @hpxml_bldg.slabs).each do |surface|
      locations << surface.interior_adjacent_to
      locations << surface.exterior_adjacent_to
    end
    @hpxml_bldg.hvac_distributions.each do |hvac_dist|
      hvac_dist.ducts.each do |duct|
        locations << duct.duct_location
      end
    end

    locations.uniq.each do |location|
      next if [HPXML::LocationGround].include? location

      if [HPXML::LocationOtherHousingUnit, HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace,
          HPXML::LocationOtherNonFreezingSpace, HPXML::LocationExteriorWall, HPXML::LocationUnderSlab,
          HPXML::LocationManufacturedHomeBelly].include? location
        @cool_design_temps[location] = calculate_scheduled_space_design_temps(location, @cool_setpoint, @hpxml_bldg.header.manualj_cooling_design_temp, weather.data.GroundMonthlyTemps.max)
        @heat_design_temps[location] = calculate_scheduled_space_design_temps(location, @heat_setpoint, @hpxml_bldg.header.manualj_heating_design_temp, weather.data.GroundMonthlyTemps.min)
      elsif [HPXML::LocationOutside, HPXML::LocationRoofDeck, HPXML::LocationManufacturedHomeUnderBelly].include? location
        @cool_design_temps[location] = @hpxml_bldg.header.manualj_cooling_design_temp
        @heat_design_temps[location] = @hpxml_bldg.header.manualj_heating_design_temp
      elsif HPXML::conditioned_locations.include? location
        @cool_design_temps[location] = process_design_temp_cooling(weather, HPXML::LocationConditionedSpace)
        @heat_design_temps[location] = process_design_temp_heating(weather, HPXML::LocationConditionedSpace)
      else
        @cool_design_temps[location] = process_design_temp_cooling(weather, location)
        @heat_design_temps[location] = process_design_temp_heating(weather, location)
      end
    end
  end

  def self.process_design_temp_heating(weather, location)
    if location == HPXML::LocationConditionedSpace
      heat_temp = @heat_setpoint

    elsif location == HPXML::LocationGarage
      heat_temp = @hpxml_bldg.header.manualj_heating_design_temp + 13.0

    elsif (location == HPXML::LocationAtticUnvented) || (location == HPXML::LocationAtticVented)

      attic_floors = @hpxml_bldg.floors.select { |f| f.is_ceiling && [f.interior_adjacent_to, f.exterior_adjacent_to].include?(location) }
      avg_floor_rvalue = calculate_average_r_value(attic_floors)

      attic_roofs = @hpxml_bldg.roofs.select { |r| r.interior_adjacent_to == location }
      avg_roof_rvalue = calculate_average_r_value(attic_roofs)

      if avg_floor_rvalue < avg_roof_rvalue
        # Attic is considered to be encapsulated. MJ8 says to use an attic
        # temperature of 95F, however alternative approaches are permissible
        if location == HPXML::LocationAtticVented
          heat_temp = @hpxml_bldg.header.manualj_heating_design_temp
        else
          heat_temp = calculate_space_design_temps(location, weather, @heat_setpoint, @hpxml_bldg.header.manualj_heating_design_temp, weather.data.GroundMonthlyTemps.min)
        end
      else
        heat_temp = @hpxml_bldg.header.manualj_heating_design_temp
      end

    elsif [HPXML::LocationBasementUnconditioned, HPXML::LocationCrawlspaceUnvented, HPXML::LocationCrawlspaceVented].include? location
      heat_temp = calculate_space_design_temps(location, weather, @heat_setpoint, @hpxml_bldg.header.manualj_heating_design_temp, weather.data.GroundMonthlyTemps.min)

    end

    fail "Design temp heating not calculated for #{location}." if heat_temp.nil?

    return heat_temp
  end

  def self.process_design_temp_cooling(weather, location)
    if location == HPXML::LocationConditionedSpace
      cool_temp = @cool_setpoint

    elsif location == HPXML::LocationGarage
      # Calculate fraction of garage under conditioned space
      area_total = 0.0
      area_conditioned = 0.0
      @hpxml_bldg.roofs.each do |roof|
        next unless roof.interior_adjacent_to == location

        area_total += roof.area
      end
      @hpxml_bldg.floors.each do |floor|
        next unless [floor.interior_adjacent_to, floor.exterior_adjacent_to].include? location

        area_total += floor.area
        area_conditioned += floor.area if floor.is_thermal_boundary
      end
      if area_total == 0
        garage_frac_under_conditioned = 0.5
      else
        garage_frac_under_conditioned = area_conditioned / area_total
      end

      # Calculate the garage cooling design temperature based on Table 4C
      # Linearly interpolate between having conditioned space over the garage and not having conditioned space above the garage
      if @daily_range_num == 0.0
        cool_temp = (@hpxml_bldg.header.manualj_cooling_design_temp +
                     (11.0 * garage_frac_under_conditioned) +
                     (22.0 * (1.0 - garage_frac_under_conditioned)))
      elsif @daily_range_num == 1.0
        cool_temp = (@hpxml_bldg.header.manualj_cooling_design_temp +
                     (6.0 * garage_frac_under_conditioned) +
                     (17.0 * (1.0 - garage_frac_under_conditioned)))
      elsif @daily_range_num == 2.0
        cool_temp = (@hpxml_bldg.header.manualj_cooling_design_temp +
                     (1.0 * garage_frac_under_conditioned) +
                     (12.0 * (1.0 - garage_frac_under_conditioned)))
      end

    elsif (location == HPXML::LocationAtticUnvented) || (location == HPXML::LocationAtticVented)

      attic_floors = @hpxml_bldg.floors.select { |f| f.is_ceiling && [f.interior_adjacent_to, f.exterior_adjacent_to].include?(location) }
      avg_floor_rvalue = calculate_average_r_value(attic_floors)

      attic_roofs = @hpxml_bldg.roofs.select { |r| r.interior_adjacent_to == location }
      avg_roof_rvalue = calculate_average_r_value(attic_roofs)

      if avg_floor_rvalue < avg_roof_rvalue
        # Attic is considered to be encapsulated. MJ8 says to use an attic
        # temperature of 95F, however alternative approaches are permissible
        if location == HPXML::LocationAtticVented
          cool_temp = @hpxml_bldg.header.manualj_cooling_design_temp + 40.0 # This is the number from a California study with dark shingle roof and similar ventilation.
        else
          cool_temp = calculate_space_design_temps(location, weather, @cool_setpoint, @hpxml_bldg.header.manualj_cooling_design_temp, weather.data.GroundMonthlyTemps.max, true)
        end

      else
        # Calculate the cooling design temperature for the unconditioned attic based on Figure A12-14
        # Use an area-weighted temperature in case roof surfaces are different
        tot_roof_area = 0.0
        cool_temp = 0.0

        @hpxml_bldg.roofs.each do |roof|
          next unless roof.interior_adjacent_to == location

          tot_roof_area += roof.net_area

          if location == HPXML::LocationAtticUnvented
            if not roof.radiant_barrier
              cool_temp += (150.0 + (@hpxml_bldg.header.manualj_cooling_design_temp - 95.0) + @daily_range_temp_adjust[@daily_range_num]) * roof.net_area
            else
              cool_temp += (130.0 + (@hpxml_bldg.header.manualj_cooling_design_temp - 95.0) + @daily_range_temp_adjust[@daily_range_num]) * roof.net_area
            end
          else
            if not roof.radiant_barrier
              if roof.roof_type == HPXML::RoofTypeAsphaltShingles
                if [HPXML::ColorDark, HPXML::ColorMediumDark].include? roof.roof_color
                  cool_temp += 130.0 * roof.net_area
                else
                  cool_temp += 120.0 * roof.net_area
                end
              elsif roof.roof_type == HPXML::RoofTypeWoodShingles
                cool_temp += 120.0 * roof.net_area
              elsif roof.roof_type == HPXML::RoofTypeMetal
                if [HPXML::ColorDark, HPXML::ColorMediumDark].include? roof.roof_color
                  cool_temp += 130.0 * roof.net_area
                elsif [HPXML::ColorMedium, HPXML::ColorLight].include? roof.roof_color
                  cool_temp += 120.0 * roof.net_area
                elsif [HPXML::ColorReflective].include? roof.roof_color
                  cool_temp += 95.0 * roof.net_area
                end
              elsif roof.roof_type == HPXML::RoofTypeClayTile
                if [HPXML::ColorDark, HPXML::ColorMediumDark].include? roof.roof_color
                  cool_temp += 110.0 * roof.net_area
                elsif [HPXML::ColorMedium, HPXML::ColorLight].include? roof.roof_color
                  cool_temp += 105.0 * roof.net_area
                elsif [HPXML::ColorReflective].include? roof.roof_color
                  cool_temp += 95.0 * roof.net_area
                end
              end
            else # with a radiant barrier
              if roof.roof_type == HPXML::RoofTypeAsphaltShingles
                if [HPXML::ColorDark, HPXML::ColorMediumDark].include? roof.roof_color
                  cool_temp += 120.0 * roof.net_area
                else
                  cool_temp += 110.0 * roof.net_area
                end
              elsif roof.roof_type == HPXML::RoofTypeWoodShingles
                cool_temp += 110.0 * roof.net_area
              elsif roof.roof_type == HPXML::RoofTypeMetal
                if [HPXML::ColorDark, HPXML::ColorMediumDark].include? roof.roof_color
                  cool_temp += 120.0 * roof.net_area
                elsif [HPXML::ColorMedium, HPXML::ColorLight].include? roof.roof_color
                  cool_temp += 110.0 * roof.net_area
                elsif [HPXML::ColorReflective].include? roof.roof_color
                  cool_temp += 95.0 * roof.net_area
                end
              elsif roof.roof_type == HPXML::RoofTypeClayTile
                if [HPXML::ColorDark, HPXML::ColorMediumDark].include? roof.roof_color
                  cool_temp += 105.0 * roof.net_area
                elsif [HPXML::ColorMedium, HPXML::ColorLight].include? roof.roof_color
                  cool_temp += 100.0 * roof.net_area
                elsif [HPXML::ColorReflective].include? roof.roof_color
                  cool_temp += 95.0 * roof.net_area
                end
              end
            end
          end # vented/unvented
        end # each roof surface

        cool_temp /= tot_roof_area

        # Adjust base CLTD for cooling design temperature and daily range
        cool_temp += (@hpxml_bldg.header.manualj_cooling_design_temp - 95.0) + @daily_range_temp_adjust[@daily_range_num]
      end

    elsif [HPXML::LocationBasementUnconditioned, HPXML::LocationCrawlspaceUnvented, HPXML::LocationCrawlspaceVented].include? location
      cool_temp = calculate_space_design_temps(location, weather, @cool_setpoint, @hpxml_bldg.header.manualj_cooling_design_temp, weather.data.GroundMonthlyTemps.max)

    end

    fail "Design temp cooling not calculated for #{location}." if cool_temp.nil?

    return cool_temp
  end

  def self.process_load_windows_skylights(bldg_design_loads, weather)
    '''
    Heating and Cooling Loads: Windows & Skylights
    '''

    # Average cooling load factors for windows/skylights WITHOUT internal shading for surface
    # azimuths of 0,22.5,45, ... ,337.5,360
    # Additional values (compared to values in MJ8 Table 3D-3) have been determined by
    # linear interpolation to avoid interpolating
    clf_avg_nois = [0.24, 0.295, 0.35, 0.365, 0.38, 0.39, 0.4, 0.44, 0.48, 0.44, 0.4, 0.39, 0.38, 0.365, 0.35, 0.295, 0.24]
    clf_avg_nois_horiz = 0.68

    # Average cooling load factors for windows/skylights WITH internal shading for surface
    # azimuths of 0,22.5,45, ... ,337.5,360
    # Additional values (compared to values in MJ8 Table 3D-3) have been determined
    # by linear interpolation to avoid interpolating in BMI
    clf_avg_is = [0.18, 0.235, 0.29, 0.305, 0.32, 0.32, 0.32, 0.305, 0.29, 0.305, 0.32, 0.32, 0.32, 0.305, 0.29, 0.235, 0.18]
    clf_avg_is_horiz = 0.52

    # Hourly cooling load factor (CLF) for windows/skylights WITHOUT an internal shade taken from
    # ASHRAE HOF Ch.26 Table 36 (subset of data in MJ8 Table A11-5)
    # Surface Azimuth = 0 (South), 22.5, 45.0, ... ,337.5,360 and Hour = 8,9, ... ,19,20
    clf_hr_nois = [[0.14, 0.22, 0.34, 0.48, 0.59, 0.65, 0.65, 0.59, 0.50, 0.43, 0.36, 0.28, 0.22],
                   [0.11, 0.15, 0.19, 0.27, 0.39, 0.52, 0.62, 0.67, 0.65, 0.58, 0.46, 0.36, 0.28],
                   [0.10, 0.12, 0.14, 0.16, 0.24, 0.36, 0.49, 0.60, 0.66, 0.66, 0.58, 0.43, 0.33],
                   [0.09, 0.10, 0.12, 0.13, 0.17, 0.26, 0.40, 0.52, 0.62, 0.66, 0.61, 0.44, 0.34],
                   [0.08, 0.10, 0.11, 0.12, 0.14, 0.20, 0.32, 0.45, 0.57, 0.64, 0.61, 0.44, 0.34],
                   [0.09, 0.10, 0.12, 0.13, 0.15, 0.17, 0.26, 0.40, 0.53, 0.63, 0.62, 0.44, 0.34],
                   [0.10, 0.12, 0.14, 0.16, 0.17, 0.19, 0.23, 0.33, 0.47, 0.59, 0.60, 0.43, 0.33],
                   [0.14, 0.18, 0.22, 0.25, 0.27, 0.29, 0.30, 0.33, 0.44, 0.57, 0.62, 0.44, 0.33],
                   [0.48, 0.56, 0.63, 0.71, 0.76, 0.80, 0.82, 0.82, 0.79, 0.75, 0.69, 0.61, 0.48],
                   [0.47, 0.44, 0.41, 0.40, 0.39, 0.39, 0.38, 0.36, 0.33, 0.30, 0.26, 0.20, 0.16],
                   [0.51, 0.51, 0.45, 0.39, 0.36, 0.33, 0.31, 0.28, 0.26, 0.23, 0.19, 0.15, 0.12],
                   [0.52, 0.57, 0.50, 0.45, 0.39, 0.34, 0.31, 0.28, 0.25, 0.22, 0.18, 0.14, 0.12],
                   [0.51, 0.57, 0.57, 0.50, 0.42, 0.37, 0.32, 0.29, 0.25, 0.22, 0.19, 0.15, 0.12],
                   [0.49, 0.58, 0.61, 0.57, 0.48, 0.41, 0.36, 0.32, 0.28, 0.24, 0.20, 0.16, 0.13],
                   [0.43, 0.55, 0.62, 0.63, 0.57, 0.48, 0.42, 0.37, 0.33, 0.28, 0.24, 0.19, 0.15],
                   [0.27, 0.43, 0.55, 0.63, 0.64, 0.60, 0.52, 0.45, 0.40, 0.35, 0.29, 0.23, 0.18],
                   [0.14, 0.22, 0.34, 0.48, 0.59, 0.65, 0.65, 0.59, 0.50, 0.43, 0.36, 0.28, 0.22]]
    clf_hr_nois_horiz = [0.24, 0.36, 0.48, 0.58, 0.66, 0.72, 0.74, 0.73, 0.67, 0.59, 0.47, 0.37, 0.29]

    # Hourly cooling load factor (CLF) for windows/skylights WITH an internal shade taken from
    # ASHRAE HOF Ch.26 Table 39 (subset of data in MJ8 Table A11-6)
    # Surface Azimuth = 0 (South), 22.5, 45.0, ... ,337.5,360 and Hour = 8,9, ... ,19,20
    clf_hr_is = [[0.23, 0.38, 0.58, 0.75, 0.83, 0.80, 0.68, 0.50, 0.35, 0.27, 0.19, 0.11, 0.09],
                 [0.18, 0.22, 0.27, 0.43, 0.63, 0.78, 0.84, 0.80, 0.66, 0.46, 0.25, 0.13, 0.11],
                 [0.14, 0.16, 0.19, 0.22, 0.38, 0.59, 0.75, 0.83, 0.81, 0.69, 0.45, 0.16, 0.12],
                 [0.12, 0.14, 0.16, 0.17, 0.23, 0.44, 0.64, 0.78, 0.84, 0.78, 0.55, 0.16, 0.12],
                 [0.11, 0.13, 0.15, 0.16, 0.17, 0.31, 0.53, 0.72, 0.82, 0.81, 0.61, 0.16, 0.12],
                 [0.12, 0.14, 0.16, 0.17, 0.18, 0.22, 0.43, 0.65, 0.80, 0.84, 0.66, 0.16, 0.12],
                 [0.14, 0.17, 0.19, 0.20, 0.21, 0.22, 0.30, 0.52, 0.73, 0.82, 0.69, 0.16, 0.12],
                 [0.22, 0.26, 0.30, 0.32, 0.33, 0.34, 0.34, 0.39, 0.61, 0.82, 0.76, 0.17, 0.12],
                 [0.65, 0.73, 0.80, 0.86, 0.89, 0.89, 0.86, 0.82, 0.75, 0.78, 0.91, 0.24, 0.18],
                 [0.62, 0.42, 0.37, 0.37, 0.37, 0.36, 0.35, 0.32, 0.28, 0.23, 0.17, 0.08, 0.07],
                 [0.74, 0.58, 0.37, 0.29, 0.27, 0.26, 0.24, 0.22, 0.20, 0.16, 0.12, 0.06, 0.05],
                 [0.80, 0.71, 0.52, 0.31, 0.26, 0.24, 0.22, 0.20, 0.18, 0.15, 0.11, 0.06, 0.05],
                 [0.80, 0.76, 0.62, 0.41, 0.27, 0.24, 0.22, 0.20, 0.17, 0.14, 0.11, 0.06, 0.05],
                 [0.79, 0.80, 0.72, 0.54, 0.34, 0.27, 0.24, 0.21, 0.19, 0.15, 0.12, 0.07, 0.06],
                 [0.74, 0.81, 0.79, 0.68, 0.49, 0.33, 0.28, 0.25, 0.22, 0.18, 0.13, 0.08, 0.07],
                 [0.54, 0.72, 0.81, 0.81, 0.71, 0.54, 0.38, 0.32, 0.27, 0.22, 0.16, 0.09, 0.08],
                 [0.23, 0.38, 0.58, 0.75, 0.83, 0.80, 0.68, 0.50, 0.35, 0.27, 0.19, 0.11, 0.09]]
    clf_hr_is_horiz = [0.44, 0.59, 0.72, 0.81, 0.85, 0.85, 0.81, 0.71, 0.58, 0.42, 0.25, 0.14, 0.12]

    # Shade Line Multipliers (SLM) for shaded windows will be calculated using the procedure
    # described in ASHRAE HOF 1997 instead of using the SLM's from MJ8 Table 3E-1

    # The time of day (assuming 24 hr clock) to calculate the SLM for the ALP for azimuths
    # starting at 0 (South) in increments of 22.5 to 360
    # Nil denotes directions not used in the shading calculation (Note: south direction is symmetrical around noon)
    slm_alp_hr = [15.5, 14.75, 14.0, 14.75, 15.5, nil, nil, nil, nil, nil, nil, nil, 8.5, 9.75, 10.0, 9.75, 8.5]

    # Mid summer declination angle used for shading calculations
    declination_angle = 12.1 # Mid August

    # Peak solar factor (PSF) (aka solar heat gain factor) taken from ASHRAE HOF 1989 Ch.26 Table 34
    # (subset of data in MJ8 Table 3D-2)
    # Surface Azimuth = 0 (South), 22.5, 45.0, ... ,337.5,360 and Latitude = 20,24,28, ... ,60,64
    psf = [[57.0,  72.0,  91.0,  111.0, 131.0, 149.0, 165.0, 180.0, 193.0, 203.0, 211.0, 217.0],
           [88.0,  103.0, 120.0, 136.0, 151.0, 165.0, 177.0, 188.0, 197.0, 206.0, 213.0, 217.0],
           [152.0, 162.0, 172.0, 181.0, 189.0, 196.0, 202.0, 208.0, 212.0, 215.0, 217.0, 217.0],
           [200.0, 204.0, 207.0, 210.0, 212.0, 214.0, 215.0, 216.0, 216.0, 216.0, 214.0, 211.0],
           [220.0, 220.0, 220.0, 219.0, 218.0, 216.0, 214.0, 211.0, 208.0, 203.0, 199.0, 193.0],
           [206.0, 203.0, 199.0, 195.0, 190.0, 185.0, 180.0, 174.0, 169.0, 165.0, 161.0, 157.0],
           [162.0, 156.0, 149.0, 141.0, 138.0, 135.0, 132.0, 128.0, 124.0, 119.0, 114.0, 109.0],
           [91.0,  87.0,  83.0,  79.0,  75.0,  71.0,  66.0,  61.0,  56.0,  56.0,  57.0,  58.0],
           [40.0,  38.0,  38.0,  37.0,  36.0,  35.0,  34.0,  33.0,  32.0,  30.0,  28.0,  27.0],
           [91.0,  87.0,  83.0,  79.0,  75.0,  71.0,  66.0,  61.0,  56.0,  56.0,  57.0,  58.0],
           [162.0, 156.0, 149.0, 141.0, 138.0, 135.0, 132.0, 128.0, 124.0, 119.0, 114.0, 109.0],
           [206.0, 203.0, 199.0, 195.0, 190.0, 185.0, 180.0, 174.0, 169.0, 165.0, 161.0, 157.0],
           [220.0, 220.0, 220.0, 219.0, 218.0, 216.0, 214.0, 211.0, 208.0, 203.0, 199.0, 193.0],
           [200.0, 204.0, 207.0, 210.0, 212.0, 214.0, 215.0, 216.0, 216.0, 216.0, 214.0, 211.0],
           [152.0, 162.0, 172.0, 181.0, 189.0, 196.0, 202.0, 208.0, 212.0, 215.0, 217.0, 217.0],
           [88.0,  103.0, 120.0, 136.0, 151.0, 165.0, 177.0, 188.0, 197.0, 206.0, 213.0, 217.0],
           [57.0,  72.0,  91.0,  111.0, 131.0, 149.0, 165.0, 180.0, 193.0, 203.0, 211.0, 217.0]]
    psf_horiz = [280.0, 277.0, 272.0, 265.0, 257.0, 247.0, 236.0, 223.0, 208.0, 193.0, 176.0, 159.0]

    # Hourly Temperature Adjustment Values (HTA_DR) (MJ8 Table A11-3)
    # Low DR, Medium DR, High DR and Hour = 8,9, ... ,19,20
    hta = [[-6.3,  -5.0,  -3.7,  -2.5, -1.5, -0.7, -0.2, 0.0, -0.2, -0.7, -1.5, -2.5, -3.7], # Low DR
           [-12.6, -10.0, -7.4,  -5.0, -2.9, -1.3, -0.3, 0.0, -0.3, -1.3, -2.9, -5.0, -7.4], # Medium DR
           [-18.9, -15.0, -11.1, -7.5, -4.4, -2.0, -0.5, 0.0, -0.5, -2.0, -4.4, -7.5, -11.1]] # High DR

    # Determine the PSF's for the building latitude
    psf_lat = []
    psf_lat_horiz = nil
    latitude = weather.header.Latitude.to_f
    for cnt in 0..16
      if latitude < 20.0
        psf_lat << psf[cnt][0]
        if cnt == 0
          psf_lat_horiz = psf_horiz[0]
        end
      elsif latitude >= 64.0
        psf_lat << psf[cnt][11]
        if cnt == 0
          psf_lat_horiz = psf_horiz[11]
        end
      else
        cnt_lat_s = ((latitude - 20.0) / 4.0).to_i
        cnt_lat_n = cnt_lat_s + 1.0
        lat_s = 20.0 + 4.0 * cnt_lat_s
        lat_n = lat_s + 4.0
        psf_lat << MathTools.interp2(latitude, lat_s, lat_n, psf[cnt][cnt_lat_s], psf[cnt][cnt_lat_n])
        if cnt == 0
          psf_lat_horiz = MathTools.interp2(latitude, lat_s, lat_n, psf_horiz[cnt_lat_s], psf_horiz[cnt_lat_n])
        end
      end
    end

    # Windows
    bldg_design_loads.Heat_Windows = 0.0
    alp_load = 0.0 # Average Load Procedure (ALP) Load
    afl_hr = [0.0] * 12 # Initialize Hourly Aggregate Fenestration Load (AFL)

    @hpxml_bldg.windows.each do |window|
      next unless window.wall.is_exterior_thermal_boundary

      window_summer_sf = window.interior_shading_factor_summer * window.exterior_shading_factor_summer
      window_true_azimuth = get_true_azimuth(window.azimuth)
      cnt225 = (window_true_azimuth / 22.5).round.to_i

      window_ufactor, window_shgc = Constructions.get_ufactor_shgc_adjusted_by_storms(window.storm_type, window.ufactor, window.shgc)

      bldg_design_loads.Heat_Windows += window_ufactor * window.area * @htd

      for hr in -1..11

        # If hr == -1: Calculate the Average Load Procedure (ALP) Load
        # Else: Calculate the hourly Aggregate Fenestration Load (AFL)

        # clf_d: Average Cooling Load Factor for the given window direction
        # clf_n: Average Cooling Load Factor for a window facing North (fully shaded)
        if hr == -1
          if window_summer_sf < 1
            clf_d = clf_avg_is[cnt225]
            clf_n = clf_avg_is[8]
          else
            clf_d = clf_avg_nois[cnt225]
            clf_n = clf_avg_nois[8]
          end
        else
          if window_summer_sf < 1
            clf_d = clf_hr_is[cnt225][hr]
            clf_n = clf_hr_is[8][hr]
          else
            clf_d = clf_hr_nois[cnt225][hr]
            clf_n = clf_hr_nois[8][hr]
          end
        end

        ctd_adj = @ctd
        if hr > -1
          # Calculate hourly CTD adjusted value for mid-summer
          ctd_adj += hta[@daily_range_num][hr]
        end

        # Hourly Heat Transfer Multiplier for the given window Direction
        htm_d = psf_lat[cnt225] * clf_d * window_shgc * window_summer_sf / 0.87 + window_ufactor * ctd_adj

        # Hourly Heat Transfer Multiplier for a window facing North (fully shaded)
        htm_n = psf_lat[8] * clf_n * window_shgc * window_summer_sf / 0.87 + window_ufactor * ctd_adj

        if window_true_azimuth < 180
          surf_azimuth = window_true_azimuth
        else
          surf_azimuth = window_true_azimuth - 360.0
        end

        if (not window.overhangs_depth.nil?) && (window.overhangs_depth > 0)
          if ((hr == -1) && (surf_azimuth.abs < 90.1)) || (hr > -1)
            if hr == -1
              actual_hr = slm_alp_hr[cnt225]
            else
              actual_hr = hr + 8 # start at hour 8
            end
            hour_angle = 0.25 * (actual_hr - 12.0) * 60.0 # ASHRAE HOF 1997 pg 29.19
            altitude_angle = Math::asin((Math::cos(weather.header.Latitude.deg2rad) *
                                          Math::cos(declination_angle.deg2rad) *
                                          Math::cos(hour_angle.deg2rad) +
                                          Math::sin(weather.header.Latitude.deg2rad) *
                                          Math::sin(declination_angle.deg2rad))).rad2deg
            temp_arg = [(Math::sin(altitude_angle.deg2rad) *
                         Math::sin(weather.header.Latitude.deg2rad) -
                         Math::sin(declination_angle.deg2rad)) /
              (Math::cos(altitude_angle.deg2rad) *
                 Math::cos(weather.header.Latitude.deg2rad)), 1.0].min
            temp_arg = [temp_arg, -1.0].max
            solar_azimuth = Math::acos(temp_arg).rad2deg
            if actual_hr < 12
              solar_azimuth = -1.0 * solar_azimuth
            end

            sol_surf_azimuth = solar_azimuth - surf_azimuth
            if (sol_surf_azimuth.abs >= 90) && (sol_surf_azimuth.abs <= 270)
              # Window is entirely in the shade if the solar surface azimuth is greater than 90 and less than 270
              htm = htm_n
            else
              slm = Math::tan(altitude_angle.deg2rad) / Math::cos(sol_surf_azimuth.deg2rad)
              z_sl = slm * window.overhangs_depth

              window_height = window.overhangs_distance_to_bottom_of_window - window.overhangs_distance_to_top_of_window
              if z_sl < window.overhangs_distance_to_top_of_window
                # Overhang is too short to provide shade
                htm = htm_d
              elsif z_sl < window.overhangs_distance_to_bottom_of_window
                percent_shaded = (z_sl - window.overhangs_distance_to_top_of_window) / window_height
                htm = percent_shaded * htm_n + (1.0 - percent_shaded) * htm_d
              else
                # Window is entirely in the shade since the shade line is below the windowsill
                htm = htm_n
              end
            end
          else
            # Window is north of East and West azimuths. Shading calculations do not apply.
            htm = htm_d
          end
        else
          htm = htm_d
        end

        if hr == -1
          alp_load += htm * window.area
        else
          afl_hr[hr] += htm * window.area
        end
      end
    end # window

    # Daily Average Load (DAL)
    dal = afl_hr.sum(0.0) / afl_hr.size

    # Excursion Limit line (ELL)
    ell = 1.3 * dal

    # Peak Fenestration Load (PFL)
    pfl = afl_hr.max

    # Excursion Adjustment Load (EAL)
    eal = [0.0, pfl - ell].max

    # Window Cooling Load
    bldg_design_loads.Cool_Windows = alp_load + eal

    # Skylights
    bldg_design_loads.Heat_Skylights = 0.0
    alp_load = 0.0 # Average Load Procedure (ALP) Load
    afl_hr = [0.0] * 12 # Initialize Hourly Aggregate Fenestration Load (AFL)

    @hpxml_bldg.skylights.each do |skylight|
      skylight_summer_sf = skylight.interior_shading_factor_summer * skylight.exterior_shading_factor_summer
      skylight_true_azimuth = get_true_azimuth(skylight.azimuth)
      cnt225 = (skylight_true_azimuth / 22.5).round.to_i
      inclination_angle = UnitConversions.convert(Math.atan(skylight.roof.pitch / 12.0), 'rad', 'deg')

      skylight_ufactor, skylight_shgc = Constructions.get_ufactor_shgc_adjusted_by_storms(skylight.storm_type, skylight.ufactor, skylight.shgc)

      bldg_design_loads.Heat_Skylights += skylight_ufactor * skylight.area * @htd

      for hr in -1..11

        # If hr == -1: Calculate the Average Load Procedure (ALP) Load
        # Else: Calculate the hourly Aggregate Fenestration Load (AFL)

        # clf_d: Average Cooling Load Factor for the given skylight direction
        # clf_d: Average Cooling Load Factor for horizontal
        if hr == -1
          if skylight_summer_sf < 1
            clf_d = clf_avg_is[cnt225]
            clf_horiz = clf_avg_is_horiz
          else
            clf_d = clf_avg_nois[cnt225]
            clf_horiz = clf_avg_nois_horiz
          end
        else
          if skylight_summer_sf < 1
            clf_d = clf_hr_is[cnt225][hr]
            clf_horiz = clf_hr_is_horiz[hr]
          else
            clf_d = clf_hr_nois[cnt225][hr]
            clf_horiz = clf_hr_nois_horiz[hr]
          end
        end

        sol_h = Math::cos(inclination_angle.deg2rad) * (psf_lat_horiz * clf_horiz)
        sol_v = Math::sin(inclination_angle.deg2rad) * (psf_lat[cnt225] * clf_d)

        ctd_adj = @ctd
        if hr > -1
          # Calculate hourly CTD adjusted value for mid-summer
          ctd_adj += hta[@daily_range_num][hr]
        end

        # Hourly Heat Transfer Multiplier for the given skylight Direction
        u_curb = 0.51 # default to wood (Table 2B-3)
        ar_curb = 0.35 # default to small (Table 2B-3)
        u_eff_skylight = skylight_ufactor + u_curb * ar_curb
        htm = (sol_h + sol_v) * (skylight_shgc * skylight_summer_sf / 0.87) + u_eff_skylight * (ctd_adj + 15.0)

        if hr == -1
          alp_load += htm * skylight.area
        else
          afl_hr[hr] += htm * skylight.area
        end
      end
    end # skylight

    # Daily Average Load (DAL)
    dal = afl_hr.sum(0.0) / afl_hr.size

    # Excursion Limit line (ELL)
    ell = 1.3 * dal

    # Peak Fenestration Load (PFL)
    pfl = afl_hr.max

    # Excursion Adjustment Load (EAL)
    eal = [0.0, pfl - ell].max

    # Skylight Cooling Load
    bldg_design_loads.Cool_Skylights = alp_load + eal
  end

  def self.process_load_doors(bldg_design_loads)
    '''
    Heating and Cooling Loads: Doors
    '''

    if @daily_range_num == 0.0
      cltd = @ctd + 15.0
    elsif @daily_range_num == 1.0
      cltd = @ctd + 11.0
    elsif @daily_range_num == 2.0
      cltd = @ctd + 6.0
    end

    bldg_design_loads.Heat_Doors = 0.0
    bldg_design_loads.Cool_Doors = 0.0

    @hpxml_bldg.doors.each do |door|
      next unless door.is_thermal_boundary

      if door.wall.is_exterior
        bldg_design_loads.Heat_Doors += (1.0 / door.r_value) * door.area * @htd
        bldg_design_loads.Cool_Doors += (1.0 / door.r_value) * door.area * cltd
      else # Partition door
        adjacent_space = door.wall.exterior_adjacent_to
        bldg_design_loads.Cool_Doors += (1.0 / door.r_value) * door.area * (@cool_design_temps[adjacent_space] - @cool_setpoint)
        bldg_design_loads.Heat_Doors += (1.0 / door.r_value) * door.area * (@heat_setpoint - @heat_design_temps[adjacent_space])
      end
    end
  end

  def self.process_load_walls(bldg_design_loads)
    '''
    Heating and Cooling Loads: Walls
    '''

    bldg_design_loads.Heat_Walls = 0.0
    bldg_design_loads.Cool_Walls = 0.0

    # Above-Grade Walls
    (@hpxml_bldg.walls + @hpxml_bldg.rim_joists).each do |wall|
      next unless wall.is_thermal_boundary

      wall_group = get_wall_group(wall)

      if wall.azimuth.nil?
        azimuths = [0.0, 90.0, 180.0, 270.0] # Assume 4 equal surfaces facing every direction
      else
        azimuths = [wall.azimuth]
      end

      if wall.is_a? HPXML::RimJoist
        wall_area = wall.area
      else
        wall_area = wall.net_area
      end

      azimuths.each do |azimuth|
        if wall.is_exterior

          # Adjust base Cooling Load Temperature Difference (CLTD)
          # Assume absorptivity for light walls < 0.5, medium walls <= 0.75, dark walls > 0.75 (based on MJ8 Table 4B Notes)
          if wall.solar_absorptance <= 0.5
            colorMultiplier = 0.65      # MJ8 Table 4B Notes, pg 348
          elsif wall.solar_absorptance <= 0.75
            colorMultiplier = 0.83      # MJ8 Appendix 12, pg 519
          else
            colorMultiplier = 1.0
          end

          true_azimuth = get_true_azimuth(azimuth)

          # Base Cooling Load Temperature Differences (CLTD's) for dark colored sunlit and shaded walls
          # with 95 degF outside temperature taken from MJ8 Figure A12-8 (intermediate wall groups were
          # determined using linear interpolation). Shaded walls apply to north facing and partition walls only.
          cltd_base_sun = [38.0, 34.95, 31.9, 29.45, 27.0, 24.5, 22.0, 21.25, 20.5, 19.65, 18.8]
          cltd_base_shade = [25.0, 22.5, 20.0, 18.45, 16.9, 15.45, 14.0, 13.55, 13.1, 12.85, 12.6]

          if (true_azimuth >= 157.5) && (true_azimuth <= 202.5)
            cltd = cltd_base_shade[wall_group - 1] * colorMultiplier
          else
            cltd = cltd_base_sun[wall_group - 1] * colorMultiplier
          end

          if @ctd >= 10.0
            # Adjust the CLTD for different cooling design temperatures
            cltd += (@hpxml_bldg.header.manualj_cooling_design_temp - 95.0)
            # Adjust the CLTD for daily temperature range
            cltd += @daily_range_temp_adjust[@daily_range_num]
          else
            # Handling cases ctd < 10 is based on A12-18 in MJ8
            cltd_corr = @ctd - 20.0 - @daily_range_temp_adjust[@daily_range_num]
            cltd = [cltd + cltd_corr, 0.0].max # Assume zero cooling load for negative CLTD's
          end

          bldg_design_loads.Cool_Walls += (1.0 / wall.insulation_assembly_r_value) * wall_area / azimuths.size * cltd
          bldg_design_loads.Heat_Walls += (1.0 / wall.insulation_assembly_r_value) * wall_area / azimuths.size * @htd
        else # Partition wall
          adjacent_space = wall.exterior_adjacent_to
          bldg_design_loads.Cool_Walls += (1.0 / wall.insulation_assembly_r_value) * wall_area / azimuths.size * (@cool_design_temps[adjacent_space] - @cool_setpoint)
          bldg_design_loads.Heat_Walls += (1.0 / wall.insulation_assembly_r_value) * wall_area / azimuths.size * (@heat_setpoint - @heat_design_temps[adjacent_space])
        end
      end
    end

    # Foundation walls
    @hpxml_bldg.foundation_walls.each do |foundation_wall|
      next unless foundation_wall.is_exterior_thermal_boundary

      u_wall_with_soil, _u_wall_without_soil = get_foundation_wall_properties(foundation_wall)
      bldg_design_loads.Heat_Walls += u_wall_with_soil * foundation_wall.net_area * @htd
    end
  end

  def self.process_load_roofs(bldg_design_loads)
    '''
    Heating and Cooling Loads: Roofs
    '''

    bldg_design_loads.Heat_Roofs = 0.0
    bldg_design_loads.Cool_Roofs = 0.0

    # Roofs
    @hpxml_bldg.roofs.each do |roof|
      next unless roof.is_thermal_boundary

      # Base CLTD for conditioned roofs (Roof-Joist-Ceiling Sandwiches) taken from MJ8 Figure A12-16
      if roof.insulation_assembly_r_value <= 6
        cltd = 50.0
      elsif roof.insulation_assembly_r_value <= 13
        cltd = 45.0
      elsif roof.insulation_assembly_r_value <= 15
        cltd = 38.0
      elsif roof.insulation_assembly_r_value <= 21
        cltd = 31.0
      elsif roof.insulation_assembly_r_value <= 30
        cltd = 30.0
      else
        cltd = 27.0
      end

      # Base CLTD color adjustment based on notes in MJ8 Figure A12-16
      if [HPXML::ColorDark, HPXML::ColorMediumDark].include? roof.roof_color
        if [HPXML::RoofTypeClayTile, HPXML::RoofTypeWoodShingles].include? roof.roof_type
          cltd *= 0.83
        end
      elsif [HPXML::ColorMedium, HPXML::ColorLight].include? roof.roof_color
        if [HPXML::RoofTypeClayTile].include? roof.roof_type
          cltd *= 0.65
        else
          cltd *= 0.83
        end
      elsif [HPXML::ColorReflective].include? roof.roof_color
        if [HPXML::RoofTypeAsphaltShingles, HPXML::RoofTypeWoodShingles].include? roof.roof_type
          cltd *= 0.83
        else
          cltd *= 0.65
        end
      end

      # Adjust base CLTD for different CTD or DR
      cltd += (@hpxml_bldg.header.manualj_cooling_design_temp - 95.0) + @daily_range_temp_adjust[@daily_range_num]

      bldg_design_loads.Cool_Roofs += (1.0 / roof.insulation_assembly_r_value) * roof.net_area * cltd
      bldg_design_loads.Heat_Roofs += (1.0 / roof.insulation_assembly_r_value) * roof.net_area * @htd
    end
  end

  def self.process_load_ceilings(bldg_design_loads)
    '''
    Heating and Cooling Loads: Ceilings
    '''

    bldg_design_loads.Heat_Ceilings = 0.0
    bldg_design_loads.Cool_Ceilings = 0.0

    @hpxml_bldg.floors.each do |floor|
      next unless floor.is_ceiling
      next unless floor.is_thermal_boundary

      if floor.is_exterior
        bldg_design_loads.Cool_Ceilings += (1.0 / floor.insulation_assembly_r_value) * floor.area * (@ctd - 5.0 + @daily_range_temp_adjust[@daily_range_num])
        bldg_design_loads.Heat_Ceilings += (1.0 / floor.insulation_assembly_r_value) * floor.area * @htd
      else
        adjacent_space = floor.exterior_adjacent_to
        bldg_design_loads.Cool_Ceilings += (1.0 / floor.insulation_assembly_r_value) * floor.area * (@cool_design_temps[adjacent_space] - @cool_setpoint)
        bldg_design_loads.Heat_Ceilings += (1.0 / floor.insulation_assembly_r_value) * floor.area * (@heat_setpoint - @heat_design_temps[adjacent_space])
      end
    end
  end

  def self.process_load_floors(bldg_design_loads)
    '''
    Heating and Cooling Loads: Floors
    '''

    bldg_design_loads.Heat_Floors = 0.0
    bldg_design_loads.Cool_Floors = 0.0

    @hpxml_bldg.floors.each do |floor|
      next unless floor.is_floor
      next unless floor.is_thermal_boundary

      if floor.is_exterior
        bldg_design_loads.Cool_Floors += (1.0 / floor.insulation_assembly_r_value) * floor.area * (@ctd - 5.0 + @daily_range_temp_adjust[@daily_range_num])
        bldg_design_loads.Heat_Floors += (1.0 / floor.insulation_assembly_r_value) * floor.area * @htd
      else # Partition floor
        adjacent_space = floor.exterior_adjacent_to
        if floor.is_floor && [HPXML::LocationCrawlspaceVented, HPXML::LocationCrawlspaceUnvented, HPXML::LocationBasementUnconditioned].include?(adjacent_space)
          u_floor = 1.0 / floor.insulation_assembly_r_value

          sum_ua_wall = 0.0
          sum_a_wall = 0.0
          @hpxml_bldg.foundation_walls.each do |foundation_wall|
            next unless foundation_wall.is_exterior && foundation_wall.interior_adjacent_to == adjacent_space

            _u_wall_with_soil, u_wall_without_soil = get_foundation_wall_properties(foundation_wall)

            sum_a_wall += foundation_wall.net_area
            sum_ua_wall += (u_wall_without_soil * foundation_wall.net_area)
          end
          @hpxml_bldg.walls.each do |wall|
            next unless wall.is_exterior && wall.interior_adjacent_to == adjacent_space

            sum_a_wall += wall.net_area
            sum_ua_wall += (1.0 / wall.insulation_assembly_r_value * wall.net_area)
          end
          fail 'Could not find connected walls.' if sum_a_wall <= 0

          u_wall = sum_ua_wall / sum_a_wall

          # Calculate partition temperature different cooling (PTDC) per Manual J Figure A12-17
          # Calculate partition temperature different heating (PTDH) per Manual J Figure A12-6
          if [HPXML::LocationCrawlspaceVented].include? adjacent_space
            # Vented or Leaky
            ptdc_floor = @ctd / (1.0 + (4.0 * u_floor) / (u_wall + 0.11))
            ptdh_floor = @htd / (1.0 + (4.0 * u_floor) / (u_wall + 0.11))
          elsif [HPXML::LocationCrawlspaceUnvented, HPXML::LocationBasementUnconditioned].include? adjacent_space
            # Sealed Tight
            ptdc_floor = u_wall * @ctd / (4.0 * u_floor + u_wall)
            ptdh_floor = u_wall * @htd / (4.0 * u_floor + u_wall)
          end

          bldg_design_loads.Cool_Floors += (1.0 / floor.insulation_assembly_r_value) * floor.area * ptdc_floor
          bldg_design_loads.Heat_Floors += (1.0 / floor.insulation_assembly_r_value) * floor.area * ptdh_floor
        else # E.g., floor over garage
          bldg_design_loads.Cool_Floors += (1.0 / floor.insulation_assembly_r_value) * floor.area * (@cool_design_temps[adjacent_space] - @cool_setpoint)
          bldg_design_loads.Heat_Floors += (1.0 / floor.insulation_assembly_r_value) * floor.area * (@heat_setpoint - @heat_design_temps[adjacent_space])
        end
      end
    end
  end

  def self.process_load_slabs(bldg_design_loads)
    '''
    Heating and Cooling Loads: Floors
    '''

    bldg_design_loads.Heat_Slabs = 0.0

    @hpxml_bldg.slabs.each do |slab|
      next unless slab.is_thermal_boundary

      if slab.interior_adjacent_to == HPXML::LocationConditionedSpace # Slab-on-grade
        f_value = calc_slab_f_value(slab, @hpxml_bldg.site.ground_conductivity)
        bldg_design_loads.Heat_Slabs += f_value * slab.exposed_perimeter * @htd
      elsif HPXML::conditioned_below_grade_locations.include? slab.interior_adjacent_to
        # Based on MJ 8th Ed. A12-7 and ASHRAE HoF 2013 pg 18.31 Eq 40
        slab_is_insulated = false
        if slab.under_slab_insulation_width.to_f > 0 && slab.under_slab_insulation_r_value > 0
          slab_is_insulated = true
        elsif slab.perimeter_insulation_depth > 0 && slab.perimeter_insulation_r_value > 0
          slab_is_insulated = true
        elsif slab.under_slab_insulation_spans_entire_slab && slab.under_slab_insulation_r_value > 0
          slab_is_insulated = true
        end
        k_soil = 0.8 # Value from ASHRAE HoF, probably used by Manual J
        r_other = 1.47 # Value from ASHRAE HoF, probably used by Manual J
        ext_fnd_walls = @hpxml_bldg.foundation_walls.select { |fw| fw.is_exterior }
        z_f = ext_fnd_walls.map { |fw| fw.depth_below_grade * (fw.area / fw.height) }.sum(0.0) / ext_fnd_walls.map { |fw| fw.area / fw.height }.sum # Weighted-average (by length) below-grade depth
        sqrt_term = [slab.exposed_perimeter**2 - 16.0 * slab.area, 0.0].max
        length = slab.exposed_perimeter / 4.0 + Math.sqrt(sqrt_term) / 4.0
        width = slab.exposed_perimeter / 4.0 - Math.sqrt(sqrt_term) / 4.0
        w_b = [length, width].min
        w_b = [w_b, 1.0].max # handle zero exposed perimeter
        u_avg_bf = (2.0 * k_soil / (Math::PI * w_b)) * (Math::log(w_b / 2.0 + z_f / 2.0 + (k_soil * r_other) / Math::PI) - Math::log(z_f / 2.0 + (k_soil * r_other) / Math::PI))
        u_value = 0.85 * u_avg_bf # To account for the storage effect of soil, multiply by 0.85
        if slab_is_insulated
          u_value *= 0.7 # U-values are multiplied y 0.70 to produce U-values for insulated floors
        end
        bldg_design_loads.Heat_Slabs += u_value * slab.area * @htd
      end
    end
  end

  def self.process_load_infiltration_ventilation(bldg_design_loads, weather)
    '''
    Heating and Cooling Loads: Infiltration & Ventilation
    '''

    sla, _ach50, _nach, _volume, _height, a_ext = Airflow.get_values_from_air_infiltration_measurements(@hpxml_bldg, @cfa, weather)
    sla *= a_ext
    ela = sla * @cfa

    ncfl_ag = @hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade

    # Set stack/wind coefficients from Tables 5D/5E
    c_s = 0.015 * ncfl_ag
    c_w_base = [0.0133 * @hpxml_bldg.site.additional_properties.aim2_shelter_coeff - 0.0027, 0.0].max # Linear relationship between shelter coefficient and c_w coefficients by shielding class
    c_w = c_w_base * ncfl_ag**0.4

    ela_in2 = UnitConversions.convert(ela, 'ft^2', 'in^2')
    windspeed_cooling_mph = 7.5 # Table 5D/5E Wind Velocity Value footnote
    windspeed_heating_mph = 15.0 # Table 5D/5E Wind Velocity Value footnote

    icfm_Cooling = ela_in2 * (c_s * @ctd + c_w * windspeed_cooling_mph**2)**0.5
    icfm_Heating = ela_in2 * (c_s * @htd + c_w * windspeed_heating_mph**2)**0.5

    q_unb_cfm, q_preheat, q_precool, q_recirc, q_bal_Sens, q_bal_Lat = get_ventilation_rates()

    cfm_Heating = q_bal_Sens + (icfm_Heating**2.0 + q_unb_cfm**2.0)**0.5 - q_preheat - q_recirc

    cfm_cool_load_sens = q_bal_Sens + (icfm_Cooling**2.0 + q_unb_cfm**2.0)**0.5 - q_precool - q_recirc
    cfm_cool_load_lat = q_bal_Lat + (icfm_Cooling**2.0 + q_unb_cfm**2.0)**0.5 - q_recirc

    bldg_design_loads.Heat_InfilVent = 1.1 * @acf * cfm_Heating * @htd

    bldg_design_loads.Cool_InfilVent_Sens = 1.1 * @acf * cfm_cool_load_sens * @ctd
    bldg_design_loads.Cool_InfilVent_Lat = 0.68 * @acf * cfm_cool_load_lat * (@cool_design_grains - @cool_indoor_grains)
  end

  def self.process_load_internal_gains(bldg_design_loads)
    '''
    Cooling Load: Internal Gains
    '''

    bldg_design_loads.Cool_IntGains_Sens = @hpxml_bldg.header.manualj_internal_loads_sensible + 230.0 * @hpxml_bldg.header.manualj_num_occupants
    bldg_design_loads.Cool_IntGains_Lat = @hpxml_bldg.header.manualj_internal_loads_latent + 200.0 * @hpxml_bldg.header.manualj_num_occupants
  end

  def self.aggregate_loads(bldg_design_loads)
    '''
    Building Loads (excluding ducts)
    '''

    # Heating
    bldg_design_loads.Heat_Tot = [bldg_design_loads.Heat_Windows + bldg_design_loads.Heat_Skylights +
      bldg_design_loads.Heat_Doors + bldg_design_loads.Heat_Walls +
      bldg_design_loads.Heat_Floors + bldg_design_loads.Heat_Slabs +
      bldg_design_loads.Heat_Ceilings + bldg_design_loads.Heat_Roofs, 0.0].max +
                                 bldg_design_loads.Heat_InfilVent

    # Cooling
    bldg_design_loads.Cool_Sens = bldg_design_loads.Cool_Windows + bldg_design_loads.Cool_Skylights +
                                  bldg_design_loads.Cool_Doors + bldg_design_loads.Cool_Walls +
                                  bldg_design_loads.Cool_Floors + bldg_design_loads.Cool_Ceilings +
                                  bldg_design_loads.Cool_Roofs + bldg_design_loads.Cool_InfilVent_Sens +
                                  bldg_design_loads.Cool_IntGains_Sens
    bldg_design_loads.Cool_Lat = bldg_design_loads.Cool_InfilVent_Lat + bldg_design_loads.Cool_IntGains_Lat
    if bldg_design_loads.Cool_Lat < 0 # No latent loads; also zero out individual components
      bldg_design_loads.Cool_Lat = 0.0
      bldg_design_loads.Cool_InfilVent_Lat = 0.0
      bldg_design_loads.Cool_IntGains_Lat = 0.0
    end
    bldg_design_loads.Cool_Tot = bldg_design_loads.Cool_Sens + bldg_design_loads.Cool_Lat

    # Initialize ducts
    bldg_design_loads.Heat_Ducts = 0.0
    bldg_design_loads.Cool_Ducts_Sens = 0.0
    bldg_design_loads.Cool_Ducts_Lat = 0.0
  end

  def self.apply_hvac_temperatures(system_design_loads, hvac_heating, hvac_cooling)
    '''
    HVAC Temperatures
    '''
    # Evaporative cooler temperature calculation based on Manual S Figure 4-7
    if @cooling_type == HPXML::HVACTypeEvaporativeCooler
      td_potential = @cool_design_temps[HPXML::LocationOutside] - @wetbulb_outdoor_cooling
      td = td_potential * hvac_cooling.additional_properties.effectiveness
      @leaving_air_temp = @cool_design_temps[HPXML::LocationOutside] - td
    else
      # Calculate Leaving Air Temperature
      shr = [system_design_loads.Cool_Sens / system_design_loads.Cool_Tot, 1.0].min
      # Determine the Leaving Air Temperature (LAT) based on Manual S Table 1-4
      if shr < 0.80
        @leaving_air_temp = 54.0 # F
      elsif shr < 0.85
        # MJ8 says to use 56 degF in this SHR range. Linear interpolation provides a more
        # continuous supply air flow rate across building efficiency levels.
        @leaving_air_temp = ((58.0 - 54.0) / (0.85 - 0.80)) * (shr - 0.8) + 54.0 # F
      else
        @leaving_air_temp = 58.0 # F
      end
    end

    # Calculate Supply Air Temperature
    if hvac_heating.is_a? HPXML::HeatPump
      @supply_air_temp = 105.0 # F
      @backup_supply_air_temp = 120.0 # F
    else
      @supply_air_temp = 120.0 # F
    end
  end

  def self.apply_hvac_loads(hvac_heating, system_design_loads, bldg_design_loads, ducts_heat_load, ducts_cool_load_sens, ducts_cool_load_lat)
    # Calculate design loads that this HVAC system serves

    # Heating
    system_design_loads.Heat_Load = bldg_design_loads.Heat_Tot * @fraction_heat_load_served
    if @heating_type == HPXML::HVACTypeHeatPumpWaterLoopToAir
      # Size to meet original fraction load served (not adjusted value from HVAC.apply_shared_heating_systems()
      # This ensures, e.g., that an appropriate heating airflow is used for duct losses.
      system_design_loads.Heat_Load = system_design_loads.Heat_Load / (1.0 / hvac_heating.heating_efficiency_cop)
    end
    system_design_loads.Heat_Load_Supp = system_design_loads.Heat_Load

    # Cooling
    system_design_loads.Cool_Load_Tot = bldg_design_loads.Cool_Tot * @fraction_cool_load_served
    system_design_loads.Cool_Load_Sens = bldg_design_loads.Cool_Sens * @fraction_cool_load_served
    system_design_loads.Cool_Load_Lat = bldg_design_loads.Cool_Lat * @fraction_cool_load_served

    # After applying load fraction to building design loads (w/o ducts), add duct load specific to this HVAC system
    system_design_loads.Heat_Load += ducts_heat_load.to_f
    system_design_loads.Heat_Load_Supp += ducts_heat_load.to_f
    system_design_loads.Cool_Load_Sens += ducts_cool_load_sens.to_f
    system_design_loads.Cool_Load_Lat += ducts_cool_load_lat.to_f
    system_design_loads.Cool_Load_Tot += ducts_cool_load_sens.to_f + ducts_cool_load_lat.to_f
  end

  def self.apply_hvac_size_limits(hvac_cooling)
    @oversize_limit = 1.15
    @oversize_delta = 15000.0
    @undersize_limit = 0.9

    if not hvac_cooling.nil?
      if hvac_cooling.compressor_type == HPXML::HVACCompressorTypeTwoStage
        @oversize_limit = 1.2
      elsif hvac_cooling.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
        @oversize_limit = 1.3
      end
    end
  end

  def self.apply_hvac_heat_pump_logic(hvac_sizing_values, hvac_cooling)
    # If HERS/MaxLoad methodology, uses at least the larger of heating and cooling loads for heat pump sizing (required for ERI).
    return unless hvac_cooling.is_a? HPXML::HeatPump
    return if @fraction_cool_load_served == 0
    return if @fraction_heat_load_served == 0

    if (@hpxml_bldg.header.heat_pump_sizing_methodology != HPXML::HeatPumpSizingACCA)
      # Note: Heat_Load_Supp should NOT be adjusted; we only want to adjust the HP capacity, not the HP backup heating capacity.
      max_load = [hvac_sizing_values.Heat_Load, hvac_sizing_values.Cool_Load_Tot].max
      hvac_sizing_values.Heat_Load = max_load
      hvac_sizing_values.Cool_Load_Sens *= max_load / hvac_sizing_values.Cool_Load_Tot
      hvac_sizing_values.Cool_Load_Lat *= max_load / hvac_sizing_values.Cool_Load_Tot
      hvac_sizing_values.Cool_Load_Tot = max_load

      # Override Manual S oversize allowances:
      @oversize_limit = 1.0
      @oversize_delta = 0.0
    end
  end

  def self.get_duct_regain_factor(duct)
    # dse_Fregain values comes from MJ8 pg 204 and Walker (1998) "Technical background for default
    # values used for forced air systems in proposed ASHRAE Std. 152"

    dse_Fregain = nil

    if [HPXML::LocationOutside, HPXML::LocationRoofDeck].include? duct.duct_location
      dse_Fregain = 0.0

    elsif [HPXML::LocationOtherHousingUnit, HPXML::LocationOtherHeatedSpace, HPXML::LocationOtherMultifamilyBufferSpace,
           HPXML::LocationOtherNonFreezingSpace, HPXML::LocationExteriorWall, HPXML::LocationUnderSlab,
           HPXML::LocationManufacturedHomeBelly].include? duct.duct_location
      space_values = Geometry.get_temperature_scheduled_space_values(duct.duct_location)
      dse_Fregain = space_values[:f_regain]

    elsif [HPXML::LocationBasementUnconditioned, HPXML::LocationCrawlspaceVented, HPXML::LocationCrawlspaceUnvented].include? duct.duct_location

      ceilings = @hpxml_bldg.floors.select { |f| f.is_floor && [f.interior_adjacent_to, f.exterior_adjacent_to].include?(duct.duct_location) }
      avg_ceiling_rvalue = calculate_average_r_value(ceilings)
      ceiling_insulated = (avg_ceiling_rvalue > 4)

      walls = @hpxml_bldg.foundation_walls.select { |f| [f.interior_adjacent_to, f.exterior_adjacent_to].include? duct.duct_location }
      avg_wall_rvalue = calculate_average_r_value(walls)
      walls_insulated = (avg_wall_rvalue > 4)

      if duct.duct_location == HPXML::LocationBasementUnconditioned
        if not ceiling_insulated
          if not walls_insulated
            dse_Fregain = 0.50 # Uninsulated ceiling, uninsulated walls
          else
            dse_Fregain = 0.75 # Uninsulated ceiling, insulated walls
          end
        else
          dse_Fregain = 0.30 # Insulated ceiling
        end
      elsif duct.duct_location == HPXML::LocationCrawlspaceVented
        if ceiling_insulated && walls_insulated
          dse_Fregain = 0.17 # Insulated ceiling, insulated walls
        elsif ceiling_insulated && (not walls_insulated)
          dse_Fregain = 0.12 # Insulated ceiling, uninsulated walls
        elsif (not ceiling_insulated) && walls_insulated
          dse_Fregain = 0.66 # Uninsulated ceiling, insulated walls
        elsif (not ceiling_insulated) && (not walls_insulated)
          dse_Fregain = 0.50 # Uninsulated ceiling, uninsulated walls
        end
      elsif duct.duct_location == HPXML::LocationCrawlspaceUnvented
        if ceiling_insulated && walls_insulated
          dse_Fregain = 0.30 # Insulated ceiling, insulated walls
        elsif ceiling_insulated && (not walls_insulated)
          dse_Fregain = 0.16 # Insulated ceiling, uninsulated walls
        elsif (not ceiling_insulated) && walls_insulated
          dse_Fregain = 0.76 # Uninsulated ceiling, insulated walls
        elsif (not ceiling_insulated) && (not walls_insulated)
          dse_Fregain = 0.60 # Uninsulated ceiling, uninsulated walls
        end
      end

    elsif [HPXML::LocationAtticVented, HPXML::LocationAtticUnvented].include? duct.duct_location
      dse_Fregain = 0.10 # This would likely be higher for unvented attics with roof insulation

    elsif [HPXML::LocationGarage].include? duct.duct_location
      dse_Fregain = 0.05

    elsif HPXML::conditioned_locations.include? duct.duct_location
      dse_Fregain = 1.0

    end

    return dse_Fregain
  end

  def self.calculate_load_ducts_heating(system_design_loads, hvac_heating)
    '''
    Heating Duct Loads
    '''

    return if hvac_heating.nil? || (system_design_loads.Heat_Tot == 0) || hvac_heating.distribution_system.nil? || hvac_heating.distribution_system.ducts.empty?
    return if @fraction_heat_load_served == 0

    init_heat_load = system_design_loads.Heat_Tot * @fraction_heat_load_served

    # Distribution system efficiency (DSE) calculations based on ASHRAE Standard 152

    duct_values = calc_duct_conduction_values(hvac_heating.distribution_system, @heat_design_temps)
    dse_As, dse_Ar, supply_r, return_r, dse_Tamb_s, dse_Tamb_r, dse_Fregain_s, dse_Fregain_r = duct_values

    # Initialize for the iteration
    delta = 1
    heat_load_next = init_heat_load

    for _iter in 0..19
      break if delta.abs <= 0.001

      heat_load_prev = heat_load_next

      # Calculate the new heating air flow rate
      heat_cfm = calc_airflow_rate_manual_s(heat_load_next, (@supply_air_temp - @heat_setpoint))

      dse_Qs, dse_Qr = calc_duct_leakages_cfm25(hvac_heating.distribution_system, heat_cfm)

      dse_DE = calc_delivery_effectiveness_heating(dse_Qs, dse_Qr, heat_cfm, heat_load_next, dse_Tamb_s, dse_Tamb_r, dse_As, dse_Ar, @heat_setpoint, dse_Fregain_s, dse_Fregain_r, supply_r, return_r)

      # Calculate the increase in heating load due to ducts (Approach: DE = Qload/Qequip -> Qducts = Qequip-Qload)
      heat_load_next = init_heat_load / dse_DE

      # Calculate the change since the last iteration
      delta = (heat_load_next - heat_load_prev) / heat_load_prev
    end

    ducts_heat_load = heat_load_next - init_heat_load
    return ducts_heat_load
  end

  def self.calculate_load_ducts_cooling(system_design_loads, weather, hvac_cooling)
    '''
    Cooling Duct Loads
    '''

    return if hvac_cooling.nil? || (system_design_loads.Cool_Sens == 0) || hvac_cooling.distribution_system.nil? || hvac_cooling.distribution_system.ducts.empty?
    return if @fraction_cool_load_served == 0

    init_cool_load_sens = system_design_loads.Cool_Sens * @fraction_cool_load_served
    init_cool_load_lat = system_design_loads.Cool_Lat * @fraction_cool_load_served

    # Distribution system efficiency (DSE) calculations based on ASHRAE Standard 152

    duct_values = calc_duct_conduction_values(hvac_cooling.distribution_system, @cool_design_temps)
    dse_As, dse_Ar, supply_r, return_r, dse_Tamb_s, dse_Tamb_r, dse_Fregain_s, dse_Fregain_r = duct_values

    # Calculate the air enthalpy in the return duct location for DSE calculations
    dse_h_r = (1.006 * UnitConversions.convert(dse_Tamb_r, 'F', 'C') + weather.design.CoolingHumidityRatio * (2501.0 + 1.86 * UnitConversions.convert(dse_Tamb_r, 'F', 'C'))) * UnitConversions.convert(1.0, 'kJ', 'Btu') * UnitConversions.convert(1.0, 'lbm', 'kg')

    # Initialize for the iteration
    delta = 1
    cool_load_tot_next = init_cool_load_sens + init_cool_load_lat

    cool_cfm = calc_airflow_rate_manual_s(init_cool_load_sens, (@cool_setpoint - @leaving_air_temp))
    _dse_Qs, dse_Qr = calc_duct_leakages_cfm25(hvac_cooling.distribution_system, cool_cfm)

    for _iter in 1..50
      break if delta.abs <= 0.001

      cool_load_tot_prev = cool_load_tot_next

      cool_load_lat, cool_load_sens = calculate_sensible_latent_split(dse_Qr, cool_load_tot_next, init_cool_load_lat)
      cool_load_tot = cool_load_lat + cool_load_sens

      # Calculate the new cooling air flow rate
      cool_cfm = calc_airflow_rate_manual_s(cool_load_sens, (@cool_setpoint - @leaving_air_temp))

      dse_Qs, dse_Qr = calc_duct_leakages_cfm25(hvac_cooling.distribution_system, cool_cfm)

      dse_DE, _dse_dTe_cooling, _cool_duct_sens = calc_delivery_effectiveness_cooling(dse_Qs, dse_Qr, @leaving_air_temp, cool_cfm, cool_load_sens, dse_Tamb_s, dse_Tamb_r, dse_As, dse_Ar, @cool_setpoint, dse_Fregain_s, dse_Fregain_r, cool_load_tot, dse_h_r, supply_r, return_r)

      cool_load_tot_next = (init_cool_load_sens + init_cool_load_lat) / dse_DE

      # Calculate the change since the last iteration
      delta = (cool_load_tot_next - cool_load_tot_prev) / cool_load_tot_prev
    end

    ducts_cool_load_sens = cool_load_sens - init_cool_load_sens
    ducts_cool_load_lat = cool_load_lat - init_cool_load_lat
    return ducts_cool_load_sens, ducts_cool_load_lat
  end

  def self.apply_load_ducts(bldg_design_loads, total_ducts_heat_load, total_ducts_cool_load_sens, total_ducts_cool_load_lat)
    bldg_design_loads.Heat_Ducts += total_ducts_heat_load.to_f
    bldg_design_loads.Heat_Tot += total_ducts_heat_load.to_f
    bldg_design_loads.Cool_Ducts_Sens += total_ducts_cool_load_sens.to_f
    bldg_design_loads.Cool_Sens += total_ducts_cool_load_sens.to_f
    bldg_design_loads.Cool_Ducts_Lat += total_ducts_cool_load_lat.to_f
    bldg_design_loads.Cool_Lat += total_ducts_cool_load_lat.to_f
    bldg_design_loads.Cool_Tot += total_ducts_cool_load_sens.to_f + total_ducts_cool_load_lat.to_f
  end

  def self.apply_hvac_equipment_adjustments(hvac_sizing_values, weather, hvac_heating, hvac_cooling, hvac_system)
    '''
    Equipment Adjustments
    '''

    # Cooling

    if not hvac_cooling.nil?
      hvac_cooling_ap = hvac_cooling.additional_properties
    end

    # Calculate the air flow rate required for design conditions
    hvac_sizing_values.Cool_Airflow = calc_airflow_rate_manual_s(hvac_sizing_values.Cool_Load_Sens, (@cool_setpoint - @leaving_air_temp))

    if hvac_sizing_values.Cool_Load_Tot <= 0

      hvac_sizing_values.Cool_Capacity = 0.0
      hvac_sizing_values.Cool_Capacity_Sens = 0.0
      hvac_sizing_values.Cool_Airflow = 0.0

    elsif [HPXML::HVACTypeCentralAirConditioner,
           HPXML::HVACTypeHeatPumpAirToAir].include? @cooling_type

      entering_temp = @hpxml_bldg.header.manualj_cooling_design_temp
      hvac_cooling_speed = get_sizing_speed(hvac_cooling_ap)
      coefficients = hvac_cooling_ap.cool_cap_ft_spec[hvac_cooling_speed]

      total_cap_curve_value = MathTools.biquadratic(@wetbulb_indoor_cooling, entering_temp, coefficients)
      cool_cap_rated = hvac_sizing_values.Cool_Load_Tot / total_cap_curve_value

      hvac_cooling_shr = hvac_cooling_ap.cool_rated_shrs_gross[hvac_cooling_speed]
      sens_cap_rated = cool_cap_rated * hvac_cooling_shr

      sensible_cap_curve_value = process_curve_fit(hvac_sizing_values.Cool_Airflow, hvac_sizing_values.Cool_Load_Tot, entering_temp)
      sens_cap_design = sens_cap_rated * sensible_cap_curve_value
      lat_cap_design = [hvac_sizing_values.Cool_Load_Tot - sens_cap_design, 1.0].max

      shr_biquadratic = get_shr_biquadratic
      a_sens = shr_biquadratic[0]
      b_sens = shr_biquadratic[1]
      c_sens = shr_biquadratic[3]
      d_sens = shr_biquadratic[5]

      # Adjust Sizing
      if lat_cap_design < hvac_sizing_values.Cool_Load_Lat
        # Size by MJ8 Latent load, return to rated conditions

        # Solve for the new sensible and total capacity at design conditions:
        # CoolingLoad_Lat = cool_cap_design - cool_load_sens_cap_design
        # solve the following for cool_cap_design: sens_cap_design = SHRRated * cool_cap_design / total_cap_curve_value * function(CFM/cool_cap_design, ODB)
        # substituting in CFM = cool_load_sens_cap_design / (1.1 * ACF * (cool_setpoint - LAT))

        cool_load_sens_cap_design = hvac_sizing_values.Cool_Load_Lat / ((total_cap_curve_value / hvac_cooling_shr - \
                                  (UnitConversions.convert(b_sens, 'ton', 'Btu/hr') + UnitConversions.convert(d_sens, 'ton', 'Btu/hr') * entering_temp) / \
                                  (1.1 * @acf * (@cool_setpoint - @leaving_air_temp))) / \
                                  (a_sens + c_sens * entering_temp) - 1.0)

        cool_cap_design = cool_load_sens_cap_design + hvac_sizing_values.Cool_Load_Lat

        # The SHR of the equipment at the design condition
        shr_design = cool_load_sens_cap_design / cool_cap_design

        # If the adjusted equipment size is negative (occurs at altitude), use oversize limit (the adjustment
        # almost always hits the oversize limit in this case, making this a safe assumption)
        if (cool_cap_design < 0) || (cool_load_sens_cap_design < 0)
          cool_cap_design = @oversize_limit * hvac_sizing_values.Cool_Load_Tot
        end

        # Limit total capacity to oversize limit
        cool_cap_design = [cool_cap_design, @oversize_limit * hvac_sizing_values.Cool_Load_Tot].min

        # Determine the final sensible capacity at design using the SHR
        cool_load_sens_cap_design = shr_design * cool_cap_design

        # Calculate the final air flow rate using final sensible capacity at design
        hvac_sizing_values.Cool_Airflow = calc_airflow_rate_manual_s(cool_load_sens_cap_design, (@cool_setpoint - @leaving_air_temp))

        # Determine rated capacities
        hvac_sizing_values.Cool_Capacity = cool_cap_design / total_cap_curve_value
        hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Capacity * hvac_cooling_shr

      elsif sens_cap_design < @undersize_limit * hvac_sizing_values.Cool_Load_Sens
        # Size by MJ8 Sensible load, return to rated conditions, find Sens with SHRRated. Limit total
        # capacity to oversizing limit

        sens_cap_design = @undersize_limit * hvac_sizing_values.Cool_Load_Sens

        # Solve for the new total system capacity at design conditions:
        # sens_cap_design   = sens_cap_rated * sensible_cap_curve_value
        #                  = SHRRated * cool_cap_design / total_cap_curve_value * sensible_cap_curve_value
        #                  = SHRRated * cool_cap_design / total_cap_curve_value * function(CFM/cool_cap_design, ODB)

        cool_cap_design = (sens_cap_design / (hvac_cooling_shr / total_cap_curve_value) - \
                                           (b_sens * UnitConversions.convert(hvac_sizing_values.Cool_Airflow, 'ton', 'Btu/hr') + \
                                           d_sens * UnitConversions.convert(hvac_sizing_values.Cool_Airflow, 'ton', 'Btu/hr') * entering_temp)) / \
                          (a_sens + c_sens * entering_temp)

        # Limit total capacity to oversize limit
        cool_cap_design = [cool_cap_design, @oversize_limit * hvac_sizing_values.Cool_Load_Tot].min

        hvac_sizing_values.Cool_Capacity = cool_cap_design / total_cap_curve_value
        hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Capacity * hvac_cooling_shr

        # Recalculate the air flow rate in case the oversizing limit has been used
        cool_load_sens_cap_design = hvac_sizing_values.Cool_Capacity_Sens * sensible_cap_curve_value
        hvac_sizing_values.Cool_Airflow = calc_airflow_rate_manual_s(cool_load_sens_cap_design, (@cool_setpoint - @leaving_air_temp))

      else
        hvac_sizing_values.Cool_Capacity = hvac_sizing_values.Cool_Load_Tot / total_cap_curve_value
        hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Capacity * hvac_cooling_shr

        cool_load_sens_cap_design = hvac_sizing_values.Cool_Capacity_Sens * sensible_cap_curve_value
        hvac_sizing_values.Cool_Airflow = calc_airflow_rate_manual_s(cool_load_sens_cap_design, (@cool_setpoint - @leaving_air_temp))
      end

      # Ensure the air flow rate is in between 200 and 500 cfm/ton.
      # Reset the air flow rate (with a safety margin), if required.
      if hvac_sizing_values.Cool_Airflow / UnitConversions.convert(hvac_sizing_values.Cool_Capacity, 'Btu/hr', 'ton') > 500
        hvac_sizing_values.Cool_Airflow = 499.0 * UnitConversions.convert(hvac_sizing_values.Cool_Capacity, 'Btu/hr', 'ton')      # CFM
      elsif hvac_sizing_values.Cool_Airflow / UnitConversions.convert(hvac_sizing_values.Cool_Capacity, 'Btu/hr', 'ton') < 200
        hvac_sizing_values.Cool_Airflow = 201.0 * UnitConversions.convert(hvac_sizing_values.Cool_Capacity, 'Btu/hr', 'ton')      # CFM
      end

    elsif [HPXML::HVACTypeHeatPumpMiniSplit,
           HPXML::HVACTypeMiniSplitAirConditioner].include? @cooling_type

      entering_temp = @hpxml_bldg.header.manualj_cooling_design_temp
      hvac_cooling_speed = get_sizing_speed(hvac_cooling_ap)
      coefficients = hvac_cooling_ap.cool_cap_ft_spec[hvac_cooling_speed]

      total_cap_curve_value = MathTools.biquadratic(@wetbulb_indoor_cooling, entering_temp, coefficients)
      hvac_cooling_shr = hvac_cooling_ap.cool_rated_shrs_gross[hvac_cooling_speed]

      hvac_sizing_values.Cool_Capacity = (hvac_sizing_values.Cool_Load_Tot / total_cap_curve_value)
      hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Capacity * hvac_cooling_shr
      hvac_sizing_values.Cool_Airflow = calc_airflow_rate_user(hvac_sizing_values.Cool_Capacity, hvac_cooling_ap.cool_rated_cfm_per_ton[-1], hvac_cooling_ap.cool_capacity_ratios[-1])

    elsif [HPXML::HVACTypeRoomAirConditioner,
           HPXML::HVACTypePTAC,
           HPXML::HVACTypeHeatPumpPTHP,
           HPXML::HVACTypeHeatPumpRoom].include? @cooling_type

      entering_temp = @hpxml_bldg.header.manualj_cooling_design_temp
      hvac_cooling_speed = get_sizing_speed(hvac_cooling_ap)
      total_cap_curve_value = MathTools.biquadratic(@wetbulb_indoor_cooling, entering_temp, hvac_cooling_ap.cool_cap_ft_spec[hvac_cooling_speed])
      hvac_cooling_shr = hvac_cooling_ap.cool_rated_shrs_gross[hvac_cooling_speed]

      hvac_sizing_values.Cool_Capacity = hvac_sizing_values.Cool_Load_Tot / total_cap_curve_value
      hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Capacity * hvac_cooling_shr
      hvac_sizing_values.Cool_Airflow = calc_airflow_rate_user(hvac_sizing_values.Cool_Capacity, hvac_cooling_ap.cool_rated_cfm_per_ton[hvac_cooling_speed], 1.0)

    elsif HPXML::HVACTypeHeatPumpGroundToAir == @cooling_type
      coil_bf = gshp_coil_bf
      entering_temp = hvac_cooling_ap.design_chw
      hvac_cooling_speed = get_sizing_speed(hvac_cooling_ap)

      # Neglecting the water flow rate for now because it's not available yet. Air flow rate is pre-adjusted values.
      design_wb_temp = UnitConversions.convert(@wetbulb_indoor_cooling, 'f', 'k')
      design_db_temp = UnitConversions.convert(@cool_setpoint, 'f', 'k')
      design_w_temp = UnitConversions.convert(entering_temp, 'f', 'k')
      design_vfr_air = UnitConversions.convert(hvac_sizing_values.Cool_Airflow, 'cfm', 'm^3/s')

      cool_cap_curve_spec = hvac_cooling_ap.cool_cap_curve_spec[hvac_cooling_speed]
      cool_sh_curve_spec = hvac_cooling_ap.cool_sh_curve_spec[hvac_cooling_speed]
      total_cap_curve_value, sensible_cap_curve_value = calc_gshp_clg_curve_value(cool_cap_curve_spec, cool_sh_curve_spec, design_wb_temp, design_db_temp, design_w_temp, design_vfr_air, nil)

      bypass_factor_curve_value = MathTools.biquadratic(@wetbulb_indoor_cooling, @cool_setpoint, gshp_coil_bf_ft_spec)
      hvac_cooling_shr = hvac_cooling_ap.cool_rated_shrs_gross[hvac_cooling_speed]

      hvac_sizing_values.Cool_Capacity = hvac_sizing_values.Cool_Load_Tot / total_cap_curve_value # Note: cool_cap_design = hvac_sizing_values.Cool_Load_Tot
      hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Capacity * hvac_cooling_shr

      cool_load_sens_cap_design = (hvac_sizing_values.Cool_Capacity_Sens * sensible_cap_curve_value /
                                 (1.0 + (1.0 - coil_bf * bypass_factor_curve_value) *
                                 (80.0 - @cool_setpoint) / (@cool_setpoint - @leaving_air_temp)))
      cool_load_lat_cap_design = hvac_sizing_values.Cool_Load_Tot - cool_load_sens_cap_design

      # Adjust Sizing so that coil sensible at design >= CoolingLoad_Sens, and coil latent at design >= CoolingLoad_Lat, and equipment SHRRated is maintained.
      cool_load_sens_cap_design = [cool_load_sens_cap_design, hvac_sizing_values.Cool_Load_Sens].max
      cool_load_lat_cap_design = [cool_load_lat_cap_design, hvac_sizing_values.Cool_Load_Lat].max
      cool_cap_design = cool_load_sens_cap_design + cool_load_lat_cap_design

      # Limit total capacity via oversizing limit
      cool_cap_design = [cool_cap_design, @oversize_limit * hvac_sizing_values.Cool_Load_Tot].min
      hvac_sizing_values.Cool_Capacity = cool_cap_design / total_cap_curve_value
      hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Capacity * hvac_cooling_shr

      # Recalculate the air flow rate in case the oversizing limit has been used
      cool_load_sens_cap_design = (hvac_sizing_values.Cool_Capacity_Sens * sensible_cap_curve_value /
                                 (1.0 + (1.0 - coil_bf * bypass_factor_curve_value) *
                                 (80.0 - @cool_setpoint) / (@cool_setpoint - @leaving_air_temp)))
      hvac_sizing_values.Cool_Airflow = calc_airflow_rate_manual_s(cool_load_sens_cap_design, (@cool_setpoint - @leaving_air_temp))

    elsif HPXML::HVACTypeEvaporativeCooler == @cooling_type

      hvac_sizing_values.Cool_Capacity = hvac_sizing_values.Cool_Load_Tot
      hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Load_Sens
      if @cool_setpoint - @leaving_air_temp > 0
        hvac_sizing_values.Cool_Airflow = calc_airflow_rate_manual_s(hvac_sizing_values.Cool_Load_Sens, (@cool_setpoint - @leaving_air_temp))
      else
        hvac_sizing_values.Cool_Airflow = @cfa * 2.0 # Use industry rule of thumb sizing method adopted by HEScore
      end

    elsif HPXML::HVACTypeHeatPumpWaterLoopToAir == @cooling_type

      # Model only currently used for heating
      hvac_sizing_values.Cool_Capacity = 0.0
      hvac_sizing_values.Cool_Capacity_Sens = 0.0
      hvac_sizing_values.Cool_Airflow = 0.0

    elsif @cooling_type.nil?

      hvac_sizing_values.Cool_Capacity = 0.0
      hvac_sizing_values.Cool_Capacity_Sens = 0.0
      hvac_sizing_values.Cool_Airflow = 0.0

    else

      fail "Unexpected cooling type: #{@cooling_type}."

    end

    # Heating

    if not hvac_heating.nil?
      hvac_heating_ap = hvac_heating.additional_properties
    end

    if hvac_sizing_values.Heat_Load <= 0

      hvac_sizing_values.Heat_Capacity = 0.0
      hvac_sizing_values.Heat_Capacity_Supp = 0.0
      hvac_sizing_values.Heat_Airflow = 0.0
      hvac_sizing_values.Heat_Airflow_Supp = 0.0

    elsif [HPXML::HVACTypeHeatPumpAirToAir,
           HPXML::HVACTypeHeatPumpMiniSplit,
           HPXML::HVACTypeHeatPumpPTHP,
           HPXML::HVACTypeHeatPumpRoom].include? @heating_type
      process_heat_pump_adjustment(hvac_sizing_values, weather, hvac_heating, total_cap_curve_value, hvac_system)
      hvac_sizing_values.Heat_Capacity_Supp = hvac_sizing_values.Heat_Load_Supp
      if @heating_type == HPXML::HVACTypeHeatPumpAirToAir
        hvac_sizing_values.Heat_Airflow = calc_airflow_rate_manual_s(hvac_sizing_values.Heat_Capacity, (@supply_air_temp - @heat_setpoint))
      else
        hvac_sizing_values.Heat_Airflow = calc_airflow_rate_user(hvac_sizing_values.Heat_Capacity, hvac_heating_ap.heat_rated_cfm_per_ton[-1], hvac_heating_ap.heat_capacity_ratios[-1])
      end
      hvac_sizing_values.Heat_Airflow_Supp = calc_airflow_rate_manual_s(hvac_sizing_values.Heat_Capacity_Supp, (@backup_supply_air_temp - @heat_setpoint))

    elsif [HPXML::HVACTypeHeatPumpGroundToAir].include? @heating_type

      if hvac_sizing_values.Cool_Capacity > 0
        hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Heat_Load
        hvac_sizing_values.Heat_Capacity_Supp = hvac_sizing_values.Heat_Load_Supp

        # For single stage compressor, when heating capacity is much larger than cooling capacity,
        # in order to avoid frequent cycling in cooling mode, heating capacity is derated to 75%.
        if hvac_sizing_values.Heat_Capacity >= 1.5 * hvac_sizing_values.Cool_Capacity
          hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Heat_Load * 0.75
        end

        hvac_sizing_values.Cool_Capacity = [hvac_sizing_values.Cool_Capacity, hvac_sizing_values.Heat_Capacity].max
        hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Cool_Capacity

        hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Capacity * hvac_cooling_shr
        cool_load_sens_cap_design = (hvac_sizing_values.Cool_Capacity_Sens * sensible_cap_curve_value /
                                   (1.0 + (1.0 - gshp_coil_bf * bypass_factor_curve_value) *
                                   (80.0 - @cool_setpoint) / (@cool_setpoint - @leaving_air_temp)))
        hvac_sizing_values.Cool_Airflow = calc_airflow_rate_manual_s(cool_load_sens_cap_design, (@cool_setpoint - @leaving_air_temp))
      else
        hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Heat_Load
        hvac_sizing_values.Heat_Capacity_Supp = hvac_sizing_values.Heat_Load_Supp
      end
      hvac_sizing_values.Heat_Airflow = calc_airflow_rate_manual_s(hvac_sizing_values.Heat_Capacity, (@supply_air_temp - @heat_setpoint))
      hvac_sizing_values.Heat_Airflow_Supp = calc_airflow_rate_manual_s(hvac_sizing_values.Heat_Capacity_Supp, (@backup_supply_air_temp - @heat_setpoint))

    elsif [HPXML::HVACTypeHeatPumpWaterLoopToAir].include? @heating_type

      hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Heat_Load
      hvac_sizing_values.Heat_Capacity_Supp = hvac_sizing_values.Heat_Load_Supp

      hvac_sizing_values.Heat_Airflow = calc_airflow_rate_manual_s(hvac_sizing_values.Heat_Capacity, (@supply_air_temp - @heat_setpoint))
      hvac_sizing_values.Heat_Airflow_Supp = calc_airflow_rate_manual_s(hvac_sizing_values.Heat_Capacity_Supp, (@backup_supply_air_temp - @heat_setpoint))

    elsif (@heating_type == HPXML::HVACTypeFurnace) || ((not hvac_cooling.nil?) && hvac_cooling.has_integrated_heating)

      hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Heat_Load
      hvac_sizing_values.Heat_Capacity_Supp = 0.0

      hvac_sizing_values.Heat_Airflow = calc_airflow_rate_manual_s(hvac_sizing_values.Heat_Capacity, (@supply_air_temp - @heat_setpoint))
      hvac_sizing_values.Heat_Airflow_Supp = 0.0

    elsif [HPXML::HVACTypeStove,
           HPXML::HVACTypeSpaceHeater,
           HPXML::HVACTypeWallFurnace,
           HPXML::HVACTypeFloorFurnace,
           HPXML::HVACTypeFireplace].include? @heating_type

      hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Heat_Load
      hvac_sizing_values.Heat_Capacity_Supp = 0.0

      if hvac_heating_ap.heat_rated_cfm_per_ton[0] > 0
        # Fixed airflow rate
        hvac_sizing_values.Heat_Airflow = UnitConversions.convert(hvac_sizing_values.Heat_Capacity, 'Btu/hr', 'ton') * hvac_heating_ap.heat_rated_cfm_per_ton[0]
      else
        # Autosized airflow rate
        hvac_sizing_values.Heat_Airflow = calc_airflow_rate_manual_s(hvac_sizing_values.Heat_Capacity, (@supply_air_temp - @heat_setpoint))
      end
      hvac_sizing_values.Heat_Airflow_Supp = 0.0

    elsif [HPXML::HVACTypeBoiler,
           HPXML::HVACTypeElectricResistance].include? @heating_type

      hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Heat_Load
      hvac_sizing_values.Heat_Capacity_Supp = 0.0
      hvac_sizing_values.Heat_Airflow = 0.0
      hvac_sizing_values.Heat_Airflow_Supp = 0.0

    elsif @heating_type.nil?

      hvac_sizing_values.Heat_Capacity = 0.0
      hvac_sizing_values.Heat_Capacity_Supp = 0.0
      hvac_sizing_values.Heat_Airflow = 0.0
      hvac_sizing_values.Heat_Airflow_Supp = 0.0

    else

      fail "Unexpected heating type: #{@heating_type}."

    end
  end

  def self.apply_hvac_installation_quality(hvac_sizing_values, hvac_heating, hvac_cooling)
    # Increases the autosized heating/cooling capacities to account for any reduction
    # in capacity due to HVAC installation quality. This is done to prevent causing
    # unmet loads.

    cool_charge_defect_ratio = 0.0
    cool_airflow_defect_ratio = 0.0
    heat_airflow_defect_ratio = 0.0

    if not hvac_cooling.nil?
      if hvac_cooling.respond_to? :charge_defect_ratio
        cool_charge_defect_ratio = hvac_cooling.charge_defect_ratio.to_f
      end
      if hvac_cooling.respond_to? :airflow_defect_ratio
        cool_airflow_defect_ratio = hvac_cooling.airflow_defect_ratio.to_f
      end
    end
    if (not hvac_heating.nil?)
      if hvac_heating.respond_to? :airflow_defect_ratio
        heat_airflow_defect_ratio = hvac_heating.airflow_defect_ratio.to_f
      end
    end

    return if (cool_charge_defect_ratio.abs < 0.001) && (cool_airflow_defect_ratio.abs < 0.001) && (heat_airflow_defect_ratio.abs < 0.001)

    # Cooling

    f_ch = cool_charge_defect_ratio.round(3)

    if [HPXML::HVACTypeHeatPumpAirToAir,
        HPXML::HVACTypeCentralAirConditioner,
        HPXML::HVACTypeHeatPumpMiniSplit,
        HPXML::HVACTypeMiniSplitAirConditioner,
        HPXML::HVACTypeHeatPumpGroundToAir].include?(@cooling_type) && @fraction_cool_load_served > 0

      hvac_cooling_ap = hvac_cooling.additional_properties

      cool_airflow_rated_defect_ratio = []
      cool_airflow_rated_ratio = []
      if @cooling_type != HPXML::HVACTypeHeatPumpGroundToAir
        cool_cfm_m3s = UnitConversions.convert(hvac_sizing_values.Cool_Airflow, 'cfm', 'm^3/s')
        for speed in 0..(hvac_cooling_ap.cool_rated_cfm_per_ton.size - 1)
          cool_airflow_rated_ratio << cool_cfm_m3s / HVAC.calc_rated_airflow(hvac_sizing_values.Cool_Capacity, hvac_cooling_ap.cool_rated_cfm_per_ton[speed], hvac_cooling_ap.cool_capacity_ratios[speed])
          cool_airflow_rated_defect_ratio << cool_cfm_m3s * (1 + cool_airflow_defect_ratio) / HVAC.calc_rated_airflow(hvac_sizing_values.Cool_Capacity, hvac_cooling_ap.cool_rated_cfm_per_ton[speed], hvac_cooling_ap.cool_capacity_ratios[speed])
        end
      else
        cool_airflow_rated_ratio = [1.0] # actual air flow is equal to rated (before applying defect ratio) in current methodology
        cool_airflow_rated_defect_ratio = [1 + cool_airflow_defect_ratio]
      end

      if not cool_airflow_rated_defect_ratio.empty?
        cap_clg_ratios = []
        for speed in 0..(cool_airflow_rated_defect_ratio.size - 1)
          # NOTE: heat pump (cooling) curves don't exhibit expected trends at extreme faults;
          clg_fff_cap_coeff, _clg_fff_eir_coeff = HVAC.get_airflow_fault_cooling_coeff()
          a1_AF_Qgr_c = clg_fff_cap_coeff[0]
          a2_AF_Qgr_c = clg_fff_cap_coeff[1]
          a3_AF_Qgr_c = clg_fff_cap_coeff[2]

          qgr_values, _p_values, ff_chg_values = HVAC.get_charge_fault_cooling_coeff(f_ch)

          a1_CH_Qgr_c = qgr_values[0]
          a2_CH_Qgr_c = qgr_values[1]
          a3_CH_Qgr_c = qgr_values[2]
          a4_CH_Qgr_c = qgr_values[3]

          q0_CH = a1_CH_Qgr_c
          q1_CH = a2_CH_Qgr_c * UnitConversions.convert(@cool_setpoint, 'F', 'C')
          q2_CH = a3_CH_Qgr_c * UnitConversions.convert(@hpxml_bldg.header.manualj_cooling_design_temp, 'F', 'C')
          q3_CH = a4_CH_Qgr_c * f_ch
          y_CH_Q_c = 1 + ((q0_CH + q1_CH + q2_CH + q3_CH) * f_ch)

          ff_ch_c = (1.0 / (1.0 + (qgr_values[0] + (qgr_values[1] * ff_chg_values[0]) + (qgr_values[2] * ff_chg_values[1]) + (qgr_values[3] * f_ch)) * f_ch)).round(3)
          ff_AF_c = cool_airflow_rated_defect_ratio[speed].round(3)
          ff_AF_comb_c = ff_ch_c * ff_AF_c

          q_AF_CH = a1_AF_Qgr_c + (a2_AF_Qgr_c * ff_ch_c) + (a3_AF_Qgr_c * ff_ch_c * ff_ch_c)
          p_CH_Q_c = y_CH_Q_c / q_AF_CH

          p_AF_Q_c = a1_AF_Qgr_c + (a2_AF_Qgr_c * ff_AF_comb_c) + (a3_AF_Qgr_c * ff_AF_comb_c * ff_AF_comb_c)

          cool_cap_fff = (p_CH_Q_c * p_AF_Q_c)

          # calculate the capacity impact by defects
          ff_AF_c_nodefect = cool_airflow_rated_ratio[speed].round(3)
          cool_cap_fff_nodefect = a1_AF_Qgr_c + a2_AF_Qgr_c * ff_AF_c_nodefect + a3_AF_Qgr_c * ff_AF_c_nodefect * ff_AF_c_nodefect
          cap_clg_ratio = 1 / (cool_cap_fff / cool_cap_fff_nodefect)
          cap_clg_ratios << cap_clg_ratio
        end

        prev_capacity = hvac_sizing_values.Cool_Capacity
        hvac_sizing_values.Cool_Capacity *= cap_clg_ratios.max
        hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Capacity * hvac_cooling_ap.cool_rated_shrs_gross[get_sizing_speed(hvac_cooling_ap)]
        if prev_capacity > 0 # Preserve cfm/ton
          hvac_sizing_values.Cool_Airflow = hvac_sizing_values.Cool_Airflow * hvac_sizing_values.Cool_Capacity / prev_capacity
        else
          hvac_sizing_values.Cool_Airflow = 0.0
        end
      end
    end

    # Heating

    if [HPXML::HVACTypeHeatPumpAirToAir,
        HPXML::HVACTypeHeatPumpMiniSplit,
        HPXML::HVACTypeHeatPumpGroundToAir].include?(@heating_type) && @fraction_heat_load_served > 0

      hvac_heating_ap = hvac_heating.additional_properties

      heat_airflow_rated_defect_ratio = []
      heat_airflow_rated_ratio = []
      if @heating_type != HPXML::HVACTypeHeatPumpGroundToAir
        heat_cfm_m3s = UnitConversions.convert(hvac_sizing_values.Heat_Airflow, 'cfm', 'm^3/s')
        for speed in 0..(hvac_heating_ap.heat_rated_cfm_per_ton.size - 1)
          heat_airflow_rated_ratio << heat_cfm_m3s / HVAC.calc_rated_airflow(hvac_sizing_values.Heat_Capacity, hvac_heating_ap.heat_rated_cfm_per_ton[speed], hvac_heating_ap.heat_capacity_ratios[speed])
          heat_airflow_rated_defect_ratio << heat_cfm_m3s * (1 + heat_airflow_defect_ratio) / HVAC.calc_rated_airflow(hvac_sizing_values.Heat_Capacity, hvac_heating_ap.heat_rated_cfm_per_ton[speed], hvac_heating_ap.heat_capacity_ratios[speed])
        end
      else
        heat_airflow_rated_ratio = [1.0] # actual air flow is equal to rated (before applying defect ratio) in current methodology
        heat_airflow_rated_defect_ratio = [1 + heat_airflow_defect_ratio]
      end

      if not heat_airflow_rated_defect_ratio.empty?
        cap_htg_ratios = []
        for speed in 0..(heat_airflow_rated_defect_ratio.size - 1)
          htg_fff_cap_coeff, _htg_fff_eir_coeff = HVAC.get_airflow_fault_heating_coeff()
          a1_AF_Qgr_h = htg_fff_cap_coeff[0]
          a2_AF_Qgr_h = htg_fff_cap_coeff[1]
          a3_AF_Qgr_h = htg_fff_cap_coeff[2]

          qgr_values, _p_values, ff_chg_values = HVAC.get_charge_fault_heating_coeff(f_ch)

          a1_CH_Qgr_h = qgr_values[0]
          a2_CH_Qgr_h = qgr_values[2]
          a3_CH_Qgr_h = qgr_values[3]

          qh1_CH = a1_CH_Qgr_h
          qh2_CH = a2_CH_Qgr_h * UnitConversions.convert(@hpxml_bldg.header.manualj_heating_design_temp, 'F', 'C')
          qh3_CH = a3_CH_Qgr_h * f_ch
          y_CH_Q_h = 1 + ((qh1_CH + qh2_CH + qh3_CH) * f_ch)

          ff_ch_h = (1 / (1 + (qgr_values[0] + qgr_values[2] * ff_chg_values[1] + qgr_values[3] * f_ch) * f_ch)).round(3)
          ff_AF_h = heat_airflow_rated_defect_ratio[speed].round(3)
          ff_AF_comb_h = ff_ch_h * ff_AF_h

          qh_AF_CH = a1_AF_Qgr_h + (a2_AF_Qgr_h * ff_ch_h) + (a3_AF_Qgr_h * ff_ch_h * ff_ch_h)
          p_CH_Q_h = y_CH_Q_h / qh_AF_CH

          p_AF_Q_h = a1_AF_Qgr_h + (a2_AF_Qgr_h * ff_AF_comb_h) + (a3_AF_Qgr_h * ff_AF_comb_h * ff_AF_comb_h)

          heat_cap_fff = (p_CH_Q_h * p_AF_Q_h)

          # calculate the capacity impact by defects
          ff_AF_h_nodefect = heat_airflow_rated_ratio[speed].round(3)
          heat_cap_fff_nodefect = a1_AF_Qgr_h + a2_AF_Qgr_h * ff_AF_h_nodefect + a3_AF_Qgr_h * ff_AF_h_nodefect * ff_AF_h_nodefect
          cap_htg_ratio = 1 / (heat_cap_fff / heat_cap_fff_nodefect)
          cap_htg_ratios << cap_htg_ratio
        end

        prev_capacity = hvac_sizing_values.Heat_Capacity
        hvac_sizing_values.Heat_Capacity *= cap_htg_ratios.max
        if prev_capacity > 0 # Preserve cfm/ton
          hvac_sizing_values.Heat_Airflow = hvac_sizing_values.Heat_Airflow * hvac_sizing_values.Heat_Capacity / prev_capacity
        else
          hvac_sizing_values.Heat_Airflow = 0.0
        end
      end
    end
  end

  def self.apply_hvac_fixed_capacities(hvac_sizing_values, hvac_heating, hvac_cooling)
    '''
    Fixed Sizing Equipment
    '''

    # Override HVAC capacities if values are provided
    if not hvac_cooling.nil?
      fixed_cooling_capacity = hvac_cooling.cooling_capacity
    end
    if (not fixed_cooling_capacity.nil?) && (hvac_sizing_values.Cool_Capacity > 0)
      prev_capacity = hvac_sizing_values.Cool_Capacity
      hvac_sizing_values.Cool_Capacity = fixed_cooling_capacity
      if @hpxml_bldg.header.allow_increased_fixed_capacities
        hvac_sizing_values.Cool_Capacity = [hvac_sizing_values.Cool_Capacity, prev_capacity].max
      end
      hvac_sizing_values.Cool_Capacity_Sens = hvac_sizing_values.Cool_Capacity_Sens * hvac_sizing_values.Cool_Capacity / prev_capacity
      hvac_sizing_values.Cool_Airflow = hvac_sizing_values.Cool_Airflow * hvac_sizing_values.Cool_Capacity / prev_capacity
    end
    if not hvac_heating.nil?
      fixed_heating_capacity = hvac_heating.heating_capacity
    elsif (not hvac_cooling.nil?) && hvac_cooling.has_integrated_heating
      fixed_heating_capacity = hvac_cooling.integrated_heating_system_capacity
    end
    if (not fixed_heating_capacity.nil?) && (hvac_sizing_values.Heat_Capacity > 0)
      prev_capacity = hvac_sizing_values.Heat_Capacity
      hvac_sizing_values.Heat_Capacity = fixed_heating_capacity
      if @hpxml_bldg.header.allow_increased_fixed_capacities
        hvac_sizing_values.Heat_Capacity = [hvac_sizing_values.Heat_Capacity, prev_capacity].max
      end
      hvac_sizing_values.Heat_Airflow = hvac_sizing_values.Heat_Airflow * hvac_sizing_values.Heat_Capacity / prev_capacity
    end
    if hvac_heating.is_a? HPXML::HeatPump
      if not hvac_heating.backup_heating_capacity.nil?
        fixed_supp_heating_capacity = hvac_heating.backup_heating_capacity
      elsif not hvac_heating.backup_system.nil?
        fixed_supp_heating_capacity = hvac_heating.backup_system.heating_capacity
      end
    end
    if (not fixed_supp_heating_capacity.nil?) && (hvac_sizing_values.Heat_Capacity_Supp > 0)
      prev_capacity = hvac_sizing_values.Heat_Capacity_Supp
      hvac_sizing_values.Heat_Capacity_Supp = fixed_supp_heating_capacity
      if @hpxml_bldg.header.allow_increased_fixed_capacities
        hvac_sizing_values.Heat_Capacity_Supp = [hvac_sizing_values.Heat_Capacity_Supp, prev_capacity].max
      end
      hvac_sizing_values.Heat_Airflow_Supp = hvac_sizing_values.Heat_Airflow_Supp * hvac_sizing_values.Heat_Capacity_Supp / prev_capacity
    end
  end

  def self.apply_hvac_ground_loop(hvac_sizing_values, weather, hvac_cooling)
    '''
    GSHP Ground Loop Sizing Calculations
    '''
    return if @cooling_type != HPXML::HVACTypeHeatPumpGroundToAir

    hvac_cooling_ap = hvac_cooling.additional_properties

    # Autosize ground loop heat exchanger length
    bore_spacing = 20.0 # ft, distance between bores
    pipe_r_value = gshp_hx_pipe_rvalue(hvac_cooling_ap)
    nom_length_heat, nom_length_cool = gshp_hxbore_ft_per_ton(weather, hvac_cooling_ap, bore_spacing, pipe_r_value)

    bore_length_heat = nom_length_heat * hvac_sizing_values.Heat_Capacity / UnitConversions.convert(1.0, 'ton', 'Btu/hr')
    bore_length_cool = nom_length_cool * hvac_sizing_values.Cool_Capacity / UnitConversions.convert(1.0, 'ton', 'Btu/hr')
    bore_length = [bore_length_heat, bore_length_cool].max

    loop_flow = [1.0, UnitConversions.convert([hvac_sizing_values.Heat_Capacity, hvac_sizing_values.Cool_Capacity].max, 'Btu/hr', 'ton')].max.floor * 3.0

    num_bore_holes = [1, (UnitConversions.convert(hvac_sizing_values.Cool_Capacity, 'Btu/hr', 'ton') + 0.5).floor].max
    bore_depth = (bore_length / num_bore_holes).floor # ft
    min_bore_depth = 0.15 * bore_spacing # 0.15 is the maximum Spacing2DepthRatio defined for the G-function

    for _i in 0..4
      if (bore_depth < min_bore_depth) && (num_bore_holes > 1)
        num_bore_holes -= 1
        bore_depth = (bore_length / num_bore_holes).floor
      elsif bore_depth > 345
        num_bore_holes += 1
        bore_depth = (bore_length / num_bore_holes).floor
      end
    end

    bore_depth = (bore_length / num_bore_holes).floor + 5

    if num_bore_holes == 1
      bore_config = 'single'
    elsif num_bore_holes == 2
      bore_config = 'line'
    elsif num_bore_holes == 3
      bore_config = 'line'
    elsif num_bore_holes == 4
      bore_config = 'rectangle'
    elsif num_bore_holes == 5
      bore_config = 'u-config'
    elsif num_bore_holes > 5
      bore_config = 'line'
    end

    # Test for valid GSHP bore field configurations
    valid_configs = { 'single' => [1],
                      'line' => [2, 3, 4, 5, 6, 7, 8, 9, 10],
                      'l-config' => [3, 4, 5, 6],
                      'rectangle' => [2, 4, 6, 8],
                      'u-config' => [5, 7, 9],
                      'l2-config' => [8],
                      'open-rectangle' => [8] }
    valid_num_bores = valid_configs[bore_config]
    max_valid_configs = { 'line' => 10, 'l-config' => 6 }
    unless valid_num_bores.include? num_bore_holes
      # Any configuration with a max_valid_configs value can accept any number of bores up to the maximum
      if max_valid_configs.keys.include? bore_config
        max_num_bore_holes = max_valid_configs[bore_config]
        num_bore_holes = max_num_bore_holes
      else
        # Search for first valid bore field
        new_bore_config = nil
        valid_configs.keys.each do |bore_config|
          next unless valid_configs[bore_config].include? num_bore_holes

          new_bore_config = bore_config
          break
        end
        if not new_bore_config.nil?
          bore_config = new_bore_config
        else
          fail 'Could not construct a valid GSHP bore field configuration.'
        end
      end
    end

    spacing_to_depth_ratio = bore_spacing / bore_depth

    lntts = [-8.5, -7.8, -7.2, -6.5, -5.9, -5.2, -4.5, -3.963, -3.27, -2.864, -2.577, -2.171, -1.884, -1.191, -0.497, -0.274, -0.051, 0.196, 0.419, 0.642, 0.873, 1.112, 1.335, 1.679, 2.028, 2.275, 3.003]
    gfnc_coeff = gshp_gfnc_coeff(bore_config, num_bore_holes, spacing_to_depth_ratio)

    hvac_sizing_values.GSHP_Loop_flow = loop_flow
    hvac_sizing_values.GSHP_Bore_Depth = bore_depth
    hvac_sizing_values.GSHP_Bore_Holes = num_bore_holes
    hvac_sizing_values.GSHP_G_Functions = [lntts, gfnc_coeff]
  end

  def self.apply_hvac_finalize_airflows(hvac_sizing_values, hvac_heating, hvac_cooling)
    '''
    Finalize Sizing Calculations
    '''

    if (not hvac_heating.nil?) && hvac_heating.respond_to?(:airflow_defect_ratio)
      if hvac_sizing_values.Heat_Airflow > 0
        hvac_sizing_values.Heat_Airflow *= (1.0 + hvac_heating.airflow_defect_ratio.to_f)
      end
    end

    if (not hvac_cooling.nil?) && hvac_cooling.respond_to?(:airflow_defect_ratio)
      if hvac_sizing_values.Cool_Airflow > 0
        hvac_sizing_values.Cool_Airflow *= (1.0 + hvac_cooling.airflow_defect_ratio.to_f)
      end
    end
  end

  def self.process_heat_pump_adjustment(hvac_sizing_values, weather, hvac_heating, total_cap_curve_value, hvac_system)
    '''
    Adjust heat pump sizing
    '''

    hvac_heating_ap = hvac_heating.additional_properties

    if hvac_heating_ap.heat_cap_ft_spec.size > 1
      coefficients = hvac_heating_ap.heat_cap_ft_spec[-1]
      capacity_ratio = hvac_heating_ap.heat_capacity_ratios[-1]
    else
      coefficients = hvac_heating_ap.heat_cap_ft_spec[0]
      capacity_ratio = 1.0
    end

    if hvac_heating.is_a? HPXML::HeatPump
      if not hvac_heating.backup_heating_switchover_temp.nil?
        min_compressor_temp = hvac_heating.backup_heating_switchover_temp
      elsif not hvac_heating.compressor_lockout_temp.nil?
        min_compressor_temp = hvac_heating.compressor_lockout_temp
      end
    end
    if (not min_compressor_temp.nil?) && (min_compressor_temp > @hpxml_bldg.header.manualj_heating_design_temp)
      # Calculate the heating load at the switchover temperature to limit unutilized capacity
      temp_heat_design_temp = @hpxml_bldg.header.manualj_heating_design_temp
      @hpxml_bldg.header.manualj_heating_design_temp = min_compressor_temp
      _alternate_bldg_design_loads, alternate_all_hvac_sizing_values = calculate(weather, @hpxml_bldg, @cfa, [hvac_system])
      heating_load = alternate_all_hvac_sizing_values[hvac_system].Heat_Load
      heating_db = min_compressor_temp
      @hpxml_bldg.header.manualj_heating_design_temp = temp_heat_design_temp
    else
      heating_load = hvac_sizing_values.Heat_Load
      heating_db = @hpxml_bldg.header.manualj_heating_design_temp
    end

    heat_cap_rated = (heating_load / MathTools.biquadratic(@heat_setpoint, heating_db, coefficients)) / capacity_ratio

    if total_cap_curve_value.nil? # Heat pump has no cooling
      if @hpxml_bldg.header.heat_pump_sizing_methodology == HPXML::HeatPumpSizingMaxLoad
        # Size based on heating, taking into account reduced heat pump capacity at the design temperature
        hvac_sizing_values.Heat_Capacity = heat_cap_rated
      else
        # Size equal to heating design load
        hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Heat_Load
      end
    elsif heat_cap_rated < hvac_sizing_values.Cool_Capacity
      # Size based on cooling
      hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Cool_Capacity
    else
      cfm_per_btuh = hvac_sizing_values.Cool_Airflow / hvac_sizing_values.Cool_Capacity
      if @hpxml_bldg.header.heat_pump_sizing_methodology == HPXML::HeatPumpSizingMaxLoad
        # Size based on heating, taking into account reduced heat pump capacity at the design temperature
        hvac_sizing_values.Cool_Capacity = heat_cap_rated
      else
        # Size based on cooling, but with ACCA oversizing allowances for heating
        load_shr = hvac_sizing_values.Cool_Load_Sens / hvac_sizing_values.Cool_Load_Tot
        if ((weather.data.HDD65F / weather.data.CDD50F) < 2.0) || (load_shr < 0.95)
          # Mild winter or has a latent cooling load
          hvac_sizing_values.Cool_Capacity = [(@oversize_limit * hvac_sizing_values.Cool_Load_Tot) / total_cap_curve_value, heat_cap_rated].min
        else
          # Cold winter and no latent cooling load (add a ton rule applies)
          hvac_sizing_values.Cool_Capacity = [(hvac_sizing_values.Cool_Load_Tot + @oversize_delta) / total_cap_curve_value, heat_cap_rated].min
        end
      end
      hvac_sizing_values.Cool_Airflow = cfm_per_btuh * hvac_sizing_values.Cool_Capacity
      hvac_sizing_values.Heat_Capacity = hvac_sizing_values.Cool_Capacity
    end
  end

  def self.get_ventilation_rates()
    # If CFIS w/ supplemental fan, assume air handler is running most of the hour and can provide
    # all ventilation needs (i.e., supplemental fan does not need to run), so skip supplement fan
    vent_fans_mech = @hpxml_bldg.ventilation_fans.select { |f| f.used_for_whole_building_ventilation && !f.is_cfis_supplemental_fan? && f.flow_rate > 0 && f.hours_in_operation > 0 }
    if vent_fans_mech.empty?
      return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    end

    # Categorize fans into different types
    vent_mech_preheat = vent_fans_mech.select { |vent_mech| (not vent_mech.preheating_efficiency_cop.nil?) }
    vent_mech_precool = vent_fans_mech.select { |vent_mech| (not vent_mech.precooling_efficiency_cop.nil?) }
    vent_mech_shared = vent_fans_mech.select { |vent_mech| vent_mech.is_shared_system }

    vent_mech_sup_tot = vent_fans_mech.select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeSupply }
    vent_mech_exh_tot = vent_fans_mech.select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeExhaust }
    vent_mech_cfis_tot = vent_fans_mech.select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeCFIS }
    vent_mech_bal_tot = vent_fans_mech.select { |vent_mech| vent_mech.fan_type == HPXML::MechVentTypeBalanced }
    vent_mech_erv_hrv_tot = vent_fans_mech.select { |vent_mech| [HPXML::MechVentTypeERV, HPXML::MechVentTypeHRV].include? vent_mech.fan_type }

    # Average in-unit CFMs (include recirculation from in unit CFMs for shared systems)
    sup_cfm_tot = vent_mech_sup_tot.map { |vent_mech| vent_mech.average_total_unit_flow_rate }.sum(0.0)
    exh_cfm_tot = vent_mech_exh_tot.map { |vent_mech| vent_mech.average_total_unit_flow_rate }.sum(0.0)
    bal_cfm_tot = vent_mech_bal_tot.map { |vent_mech| vent_mech.average_total_unit_flow_rate }.sum(0.0)
    erv_hrv_cfm_tot = vent_mech_erv_hrv_tot.map { |vent_mech| vent_mech.average_total_unit_flow_rate }.sum(0.0)
    cfis_cfm_tot = vent_mech_cfis_tot.map { |vent_mech| vent_mech.average_total_unit_flow_rate }.sum(0.0)

    # Average preconditioned OA air CFMs (only OA, recirculation will be addressed below for all shared systems)
    oa_cfm_preheat = vent_mech_preheat.map { |vent_mech| vent_mech.average_oa_unit_flow_rate * vent_mech.preheating_fraction_load_served }.sum(0.0)
    oa_cfm_precool = vent_mech_precool.map { |vent_mech| vent_mech.average_oa_unit_flow_rate * vent_mech.precooling_fraction_load_served }.sum(0.0)
    recirc_cfm_shared = vent_mech_shared.map { |vent_mech| vent_mech.average_total_unit_flow_rate - vent_mech.average_oa_unit_flow_rate }.sum(0.0)

    # Total CFMS
    tot_sup_cfm = sup_cfm_tot + bal_cfm_tot + erv_hrv_cfm_tot + cfis_cfm_tot
    tot_exh_cfm = exh_cfm_tot + bal_cfm_tot + erv_hrv_cfm_tot
    tot_unbal_cfm = (tot_sup_cfm - tot_exh_cfm).abs
    tot_bal_cfm = [tot_exh_cfm, tot_sup_cfm].min

    # Calculate effectiveness for all ERV/HRV and store results in a hash
    hrv_erv_effectiveness_map = Airflow.calc_hrv_erv_effectiveness(vent_mech_erv_hrv_tot)

    # Calculate cfm weighted average effectiveness for the combined balanced airflow
    weighted_vent_mech_lat_eff = 0.0
    weighted_vent_mech_apparent_sens_eff = 0.0
    vent_mech_erv_hrv_unprecond = vent_mech_erv_hrv_tot.select { |vent_mech| vent_mech.preheating_efficiency_cop.nil? && vent_mech.precooling_efficiency_cop.nil? }
    vent_mech_erv_hrv_unprecond.each do |vent_mech|
      weighted_vent_mech_lat_eff += vent_mech.average_oa_unit_flow_rate / tot_bal_cfm * hrv_erv_effectiveness_map[vent_mech][:vent_mech_lat_eff]
      weighted_vent_mech_apparent_sens_eff += vent_mech.average_oa_unit_flow_rate / tot_bal_cfm * hrv_erv_effectiveness_map[vent_mech][:vent_mech_apparent_sens_eff]
    end

    tot_bal_cfm_sens = tot_bal_cfm * (1.0 - weighted_vent_mech_apparent_sens_eff)
    tot_bal_cfm_lat = tot_bal_cfm * (1.0 - weighted_vent_mech_lat_eff)

    return [tot_unbal_cfm, oa_cfm_preheat, oa_cfm_precool, recirc_cfm_shared, tot_bal_cfm_sens, tot_bal_cfm_lat]
  end

  def self.calc_airflow_rate_manual_s(sens_load_or_capacity, deltaT)
    # Airflow sizing following Manual S based on design calculation
    return sens_load_or_capacity / (1.1 * @acf * deltaT)
  end

  def self.calc_airflow_rate_user(capacity, rated_cfm_per_ton, capacity_ratio)
    # Airflow determined by user setting, not based on design
    return rated_cfm_per_ton * capacity_ratio * UnitConversions.convert(capacity, 'Btu/hr', 'ton') # Maximum air flow under heating operation
  end

  def self.calc_gshp_clg_curve_value(cool_cap_curve_spec, cool_sh_curve_spec, wb_temp, db_temp, w_temp, vfr_air, loop_flow = nil, rated_vfr_air = nil)
    # Reference conditions in thesis with largest capacity:
    # See Appendix B Figure B.3 of  https://hvac.okstate.edu/sites/default/files/pubs/theses/MS/27-Tang_Thesis_05.pdf
    ref_temp = 283 # K
    if rated_vfr_air.nil?
      # rated volume flow rate used to fit the curve
      ref_vfr_air = UnitConversions.convert(1200, 'cfm', 'm^3/s')
    else
      ref_vfr_air = UnitConversions.convert(rated_vfr_air, 'cfm', 'm^3/s')
    end
    ref_vfr_water = 0.000284

    a_1 = cool_cap_curve_spec[0]
    a_2 = cool_cap_curve_spec[1]
    a_3 = cool_cap_curve_spec[2]
    a_4 = cool_cap_curve_spec[3]
    a_5 = cool_cap_curve_spec[4]
    b_1 = cool_sh_curve_spec[0]
    b_2 = cool_sh_curve_spec[1]
    b_3 = cool_sh_curve_spec[2]
    b_4 = cool_sh_curve_spec[3]
    b_5 = cool_sh_curve_spec[4]
    b_6 = cool_sh_curve_spec[5]

    loop_flow = 0.0 if loop_flow.nil?

    total_cap_curve_value = a_1 + wb_temp / ref_temp * a_2 + w_temp / ref_temp * a_3 + vfr_air / ref_vfr_air * a_4 + loop_flow / ref_vfr_water * a_5
    sensible_cap_curve_value = b_1 + db_temp / ref_temp * b_2 + wb_temp / ref_temp * b_3 + w_temp / ref_temp * b_4 + vfr_air / ref_vfr_air * b_5 + loop_flow / ref_vfr_water * b_6

    return total_cap_curve_value, sensible_cap_curve_value
  end

  def self.calc_delivery_effectiveness_heating(dse_Qs, dse_Qr, system_cfm, load_sens, dse_Tamb_s, dse_Tamb_r, dse_As, dse_Ar, t_setpoint, dse_Fregain_s, dse_Fregain_r, supply_r, return_r, air_dens = @inside_air_dens, air_cp = Gas.Air.cp)
    '''
    Calculate the Delivery Effectiveness for heating (using the method of ASHRAE Standard 152).
    '''
    dse_Bs, dse_Br, dse_As, dse_Ar, dse_dTe, dse_dT_s, dse_dT_r = _calc_dse_init(system_cfm, load_sens, dse_Tamb_s, dse_Tamb_r, dse_As, dse_Ar, t_setpoint, dse_Qs, dse_Qr, supply_r, return_r, air_dens, air_cp)
    dse_DE = _calc_dse_DE_heating(dse_As, dse_Bs, dse_Ar, dse_Br, dse_dT_s, dse_dT_r, dse_dTe)
    dse_DEcorr = _calc_dse_DEcorr(dse_DE, dse_Fregain_s, dse_Fregain_r, dse_Br, dse_Ar, dse_dT_r, dse_dTe)

    return dse_DEcorr
  end

  def self.calc_delivery_effectiveness_cooling(dse_Qs, dse_Qr, leaving_air_temp, system_cfm, load_sens, dse_Tamb_s, dse_Tamb_r, dse_As, dse_Ar, t_setpoint, dse_Fregain_s, dse_Fregain_r, load_total, dse_h_r, supply_r, return_r, air_dens = @inside_air_dens, air_cp = Gas.Air.cp, h_in = @enthalpy_indoor_cooling)
    '''
    Calculate the Delivery Effectiveness for cooling (using the method of ASHRAE Standard 152).
    '''
    dse_Bs, dse_Br, dse_As, dse_Ar, dse_dTe, _dse_dT_s, dse_dT_r = _calc_dse_init(system_cfm, load_sens, dse_Tamb_s, dse_Tamb_r, dse_As, dse_Ar, t_setpoint, dse_Qs, dse_Qr, supply_r, return_r, air_dens, air_cp)
    dse_dTe *= -1.0
    dse_DE, cooling_load_ducts_sens = _calc_dse_DE_cooling(dse_As, system_cfm, load_total, dse_Ar, dse_h_r, dse_Br, dse_dT_r, dse_Bs, leaving_air_temp, dse_Tamb_s, load_sens, air_dens, air_cp, h_in)
    dse_DEcorr = _calc_dse_DEcorr(dse_DE, dse_Fregain_s, dse_Fregain_r, dse_Br, dse_Ar, dse_dT_r, dse_dTe)

    return dse_DEcorr, dse_dTe, cooling_load_ducts_sens
  end

  def self._calc_dse_init(system_cfm, load_sens, dse_Tamb_s, dse_Tamb_r, dse_As, dse_Ar, t_setpoint, dse_Qs, dse_Qr, supply_r, return_r, air_dens, air_cp)
    # Supply and return conduction functions, Bs and Br
    dse_Bs = Math.exp((-1.0 * dse_As) / (60.0 * system_cfm * air_dens * air_cp * supply_r))
    dse_Br = Math.exp((-1.0 * dse_Ar) / (60.0 * system_cfm * air_dens * air_cp * return_r))

    dse_As = (system_cfm - dse_Qs) / system_cfm
    dse_Ar = (system_cfm - dse_Qr) / system_cfm

    dse_dTe = load_sens / (60.0 * system_cfm * air_dens * air_cp)
    dse_dT_s = t_setpoint - dse_Tamb_s
    dse_dT_r = t_setpoint - dse_Tamb_r

    return dse_Bs, dse_Br, dse_As, dse_Ar, dse_dTe, dse_dT_s, dse_dT_r
  end

  def self._calc_dse_DE_cooling(dse_As, system_cfm, load_total, dse_Ar, dse_h_r, dse_Br, dse_dT_r, dse_Bs, leaving_air_temp, dse_Tamb_s, load_sens, air_dens, air_cp, h_in)
    # Calculate the delivery effectiveness (Equation 6-25)
    dse_DE = ((dse_As * 60.0 * system_cfm * air_dens) / (-1.0 * load_total)) * \
             (((-1.0 * load_total) / (60.0 * system_cfm * air_dens)) + \
              (1.0 - dse_Ar) * (dse_h_r - h_in) + \
              dse_Ar * air_cp * (dse_Br - 1.0) * dse_dT_r + \
              air_cp * (dse_Bs - 1.0) * (leaving_air_temp - dse_Tamb_s))

    # Calculate the sensible heat transfer from surroundings
    cooling_load_ducts_sens = (1.0 - [dse_DE, 0.0].max) * load_sens

    return dse_DE, cooling_load_ducts_sens
  end

  def self._calc_dse_DE_heating(dse_As, dse_Bs, dse_Ar, dse_Br, dse_dT_s, dse_dT_r, dse_dTe)
    # Calculate the delivery effectiveness (Equation 6-23)
    dse_DE = (dse_As * dse_Bs -
              dse_As * dse_Bs * (1.0 - dse_Ar * dse_Br) * (dse_dT_r / dse_dTe) -
              dse_As * (1.0 - dse_Bs) * (dse_dT_s / dse_dTe))

    return dse_DE
  end

  def self._calc_dse_DEcorr(dse_DE, dse_Fregain_s, dse_Fregain_r, dse_Br, dse_Ar, dse_dT_r, dse_dTe)
    # Calculate the delivery effectiveness corrector for regain (Equation 6-40)
    dse_DEcorr = (dse_DE + dse_Fregain_s * (1.0 - dse_DE) - (dse_Fregain_s - dse_Fregain_r -
                  dse_Br * (dse_Ar * dse_Fregain_s - dse_Fregain_r)) * dse_dT_r / dse_dTe)

    # Limit the DE to a reasonable value to prevent negative values and huge equipment
    dse_DEcorr = [dse_DEcorr, 0.25].max
    dse_DEcorr = [dse_DEcorr, 1.00].min

    return dse_DEcorr
  end

  def self.calculate_sensible_latent_split(return_leakage_cfm, cool_load_tot, cool_load_lat)
    # Calculate the latent duct leakage load (Manual J accounts only for return duct leakage)
    dse_cool_load_latent = [0.0, 0.68 * @acf * return_leakage_cfm * (@cool_design_grains - @cool_indoor_grains)].max

    # Calculate final latent and load
    cool_load_lat += dse_cool_load_latent
    cool_load_sens = cool_load_tot - cool_load_lat

    return cool_load_lat, cool_load_sens
  end

  def self.calc_duct_conduction_values(distribution_system, design_temps)
    dse_A = { HPXML::DuctTypeSupply => 0.0, HPXML::DuctTypeReturn => 0.0 }
    dse_Ufactor = { HPXML::DuctTypeSupply => 0.0, HPXML::DuctTypeReturn => 0.0 }
    dse_Tamb = { HPXML::DuctTypeSupply => 0.0, HPXML::DuctTypeReturn => 0.0 }
    dse_Fregain = { HPXML::DuctTypeSupply => 0.0, HPXML::DuctTypeReturn => 0.0 }

    [HPXML::DuctTypeSupply, HPXML::DuctTypeReturn].each do |duct_type|
      # Calculate total area outside this unit's conditioned space
      total_area = 0.0
      distribution_system.ducts.each do |duct|
        next if duct.duct_type != duct_type
        next if HPXML::conditioned_locations_this_unit.include? duct.duct_location

        total_area += duct.duct_surface_area * duct.duct_surface_area_multiplier
      end

      if total_area == 0
        # There still may be leakage to the outside, so set Tamb to outside environment
        dse_Tamb[duct_type] = design_temps[HPXML::LocationOutside]
      else
        distribution_system.ducts.each do |duct|
          next if duct.duct_type != duct_type
          next if HPXML::conditioned_locations_this_unit.include? duct.duct_location

          duct_area = duct.duct_surface_area * duct.duct_surface_area_multiplier
          dse_A[duct_type] += duct_area

          # Calculate area-weighted values:

          duct_area_fraction = duct_area / total_area

          dse_Ufactor[duct_type] += 1.0 / duct.duct_effective_r_value * duct_area_fraction

          dse_Tamb[duct_type] += design_temps[duct.duct_location] * duct_area_fraction

          dse_Fregain[duct_type] += get_duct_regain_factor(duct) * duct_area_fraction
        end
      end
    end

    return dse_A[HPXML::DuctTypeSupply], dse_A[HPXML::DuctTypeReturn],
           1.0 / dse_Ufactor[HPXML::DuctTypeSupply], 1.0 / dse_Ufactor[HPXML::DuctTypeReturn],
           dse_Tamb[HPXML::DuctTypeSupply], dse_Tamb[HPXML::DuctTypeReturn],
           dse_Fregain[HPXML::DuctTypeSupply], dse_Fregain[HPXML::DuctTypeReturn]
  end

  def self.calc_duct_leakages_cfm25(distribution_system, system_cfm)
    '''
    Calculate supply & return duct leakage in cfm25.
    '''

    cfms = { HPXML::DuctTypeSupply => 0.0, HPXML::DuctTypeReturn => 0.0 }

    distribution_system.duct_leakage_measurements.each do |m|
      next if m.duct_leakage_total_or_to_outside != HPXML::DuctLeakageToOutside
      next unless [HPXML::DuctTypeSupply, HPXML::DuctTypeReturn].include? m.duct_type

      if m.duct_leakage_units == HPXML::UnitsPercent
        cfms[m.duct_type] += m.duct_leakage_value * system_cfm
      elsif m.duct_leakage_units == HPXML::UnitsCFM25
        cfms[m.duct_type] += m.duct_leakage_value
      elsif m.duct_leakage_units == HPXML::UnitsCFM50
        cfms[m.duct_type] += Airflow.calc_air_leakage_at_diff_pressure(0.65, m.duct_leakage_value, 50.0, 25.0)
      end
    end

    return cfms[HPXML::DuctTypeSupply], cfms[HPXML::DuctTypeReturn]
  end

  def self.process_curve_fit(airflow_rate, capacity, temp)
    # TODO: Get rid of this curve by using ADP/BF calculations
    return 0 if capacity == 0

    capacity_tons = UnitConversions.convert(capacity, 'Btu/hr', 'ton')
    return MathTools.biquadratic(airflow_rate / capacity_tons, temp, get_shr_biquadratic)
  end

  def self.get_shr_biquadratic
    # Based on EnergyPlus's model for calculating SHR at off-rated conditions. This curve fit
    # avoids the iterations in the actual model. It does not account for altitude or variations
    # in the SHRRated. It is a function of ODB (MJ design temp) and CFM/Ton (from MJ)
    return [1.08464364, 0.002096954, 0, -0.005766327, 0, -0.000011147]
  end

  def self.get_sizing_speed(hvac_cooling_ap)
    if hvac_cooling_ap.respond_to?(:cool_capacity_ratios) && (hvac_cooling_ap.cool_capacity_ratios.size > 1)
      sizing_speed = hvac_cooling_ap.cool_capacity_ratios.size # Default
      sizing_speed_delta = 10 # Initialize
      for speed in 0..(hvac_cooling_ap.cool_capacity_ratios.size - 1)
        # Select curves for sizing using the speed with the capacity ratio closest to 1
        delta = (hvac_cooling_ap.cool_capacity_ratios[speed] - 1).abs
        if delta <= sizing_speed_delta
          sizing_speed = speed
          sizing_speed_delta = delta
        end
      end
      return sizing_speed
    end
    return 0
  end

  def self.get_true_azimuth(azimuth)
    true_az = azimuth - 180.0
    if true_az < 0
      true_az += 360.0
    end
    return true_az
  end

  def self.get_space_ua_values(location, weather)
    if HPXML::conditioned_locations.include? location
      fail 'Method should not be called for a conditioned space.'
    end

    space_UAs = { HPXML::LocationOutside => 0.0,
                  HPXML::LocationGround => 0.0,
                  HPXML::LocationConditionedSpace => 0.0 }

    # Surface UAs
    (@hpxml_bldg.roofs + @hpxml_bldg.floors + @hpxml_bldg.walls + @hpxml_bldg.foundation_walls).each do |surface|
      next unless ((location == surface.interior_adjacent_to && space_UAs.keys.include?(surface.exterior_adjacent_to)) ||
                   (location == surface.exterior_adjacent_to && space_UAs.keys.include?(surface.interior_adjacent_to)))

      if [surface.interior_adjacent_to, surface.exterior_adjacent_to].include? HPXML::LocationOutside
        space_UAs[HPXML::LocationOutside] += (1.0 / surface.insulation_assembly_r_value) * surface.area
      elsif HPXML::conditioned_locations.include?(surface.interior_adjacent_to) || HPXML::conditioned_locations.include?(surface.exterior_adjacent_to)
        space_UAs[HPXML::LocationConditionedSpace] += (1.0 / surface.insulation_assembly_r_value) * surface.area
      elsif [surface.interior_adjacent_to, surface.exterior_adjacent_to].include? HPXML::LocationGround
        if surface.is_a? HPXML::FoundationWall
          _u_wall_with_soil, u_wall_without_soil = get_foundation_wall_properties(surface)
          space_UAs[HPXML::LocationGround] += u_wall_without_soil * surface.area
        end
      end
    end

    # Infiltration UA
    ach = nil
    if [HPXML::LocationCrawlspaceVented, HPXML::LocationAtticVented].include? location
      # Vented space
      if location == HPXML::LocationCrawlspaceVented
        vented_crawl = @hpxml_bldg.foundations.find { |f| f.foundation_type == HPXML::FoundationTypeCrawlspaceVented }
        sla = vented_crawl.vented_crawlspace_sla
      else
        vented_attic = @hpxml_bldg.attics.find { |f| f.attic_type == HPXML::AtticTypeVented }
        if not vented_attic.vented_attic_sla.nil?
          sla = vented_attic.vented_attic_sla
        else
          ach = vented_attic.vented_attic_ach
        end
      end
      ach = Airflow.get_infiltration_ACH_from_SLA(sla, 8.202, weather) if ach.nil?
    else # Unvented space
      ach = Airflow.get_default_unvented_space_ach()
    end
    volume = Geometry.calculate_zone_volume(@hpxml_bldg, location)
    infiltration_cfm = ach / UnitConversions.convert(1.0, 'hr', 'min') * volume
    outside_air_density = UnitConversions.convert(weather.header.LocalPressure, 'atm', 'Btu/ft^3') / (Gas.Air.r * (weather.data.AnnualAvgDrybulb + 460.0))
    space_UAs['infil'] = infiltration_cfm * outside_air_density * Gas.Air.cp * UnitConversions.convert(1.0, 'hr', 'min')

    # Total UA
    total_UA = 0.0
    space_UAs.values.each do |ua|
      total_UA += ua
    end
    space_UAs['total'] = total_UA
    return space_UAs
  end

  def self.calculate_space_design_temps(location, weather, conditioned_design_temp, design_db, ground_db, is_cooling_for_unvented_attic_roof_insulation = false)
    space_UAs = get_space_ua_values(location, weather)

    # Calculate space design temp from space UAs
    design_temp = nil
    if not is_cooling_for_unvented_attic_roof_insulation

      sum_uat = 0.0
      space_UAs.each do |ua_type, ua|
        if ua_type == HPXML::LocationGround
          sum_uat += ua * ground_db
        elsif (ua_type == HPXML::LocationOutside) || (ua_type == 'infil')
          sum_uat += ua * design_db
        elsif ua_type == HPXML::LocationConditionedSpace
          sum_uat += ua * conditioned_design_temp
        elsif ua_type == 'total'
        # skip
        else
          fail "Unexpected space ua type: '#{ua_type}'."
        end
      end
      design_temp = sum_uat / space_UAs['total']

    else

      # Special case due to effect of solar

      # This number comes from the number from the Vented Attic
      # assumption, but assuming an unvented attic will be hotter
      # during the summer when insulation is at the ceiling level
      max_temp_rise = 50.0

      # Estimate from running a few cases in E+ and DOE2 since the
      # attic will always be a little warmer than the conditioned space
      # when the roof is insulated
      min_temp_rise = 5.0

      max_cooling_temp = @cool_setpoint + max_temp_rise
      min_cooling_temp = @cool_setpoint + min_temp_rise

      ua_conditioned = 0.0
      ua_outside = 0.0
      space_UAs.each do |ua_type, ua|
        if (ua_type == HPXML::LocationOutside) || (ua_type == 'infil')
          ua_outside += ua
        elsif ua_type == HPXML::LocationConditionedSpace
          ua_conditioned += ua
        elsif not ((ua_type == 'total') || (ua_type == HPXML::LocationGround))
          fail "Unexpected space ua type: '#{ua_type}'."
        end
      end
      percent_ua_conditioned = ua_conditioned / (ua_conditioned + ua_outside)
      design_temp = max_cooling_temp - percent_ua_conditioned * (max_cooling_temp - min_cooling_temp)

    end

    return design_temp
  end

  def self.calculate_scheduled_space_design_temps(location, setpoint, oa_db, gnd_db)
    space_values = Geometry.get_temperature_scheduled_space_values(location)
    design_temp = setpoint * space_values[:indoor_weight] + oa_db * space_values[:outdoor_weight] + gnd_db * space_values[:ground_weight]
    if not space_values[:temp_min].nil?
      design_temp = [design_temp, space_values[:temp_min]].max
    end
    return design_temp
  end

  def self.get_wall_group(wall)
    # Determine the wall Group Number (A - K = 1 - 11) for above-grade walls

    if wall.is_a? HPXML::RimJoist
      wall_type = HPXML::WallTypeWoodStud
    else
      wall_type = wall.wall_type
    end

    wall_ufactor = 1.0 / wall.insulation_assembly_r_value

    # The following correlations were estimated by analyzing MJ8 construction tables.
    if wall_type == HPXML::WallTypeWoodStud
      if wall.siding == HPXML::SidingTypeBrick
        if wall_ufactor <= 0.070
          wall_group = 11 # K
        elsif wall_ufactor <= 0.083
          wall_group = 10 # J
        elsif wall_ufactor <= 0.095
          wall_group = 9 # I
        elsif wall_ufactor <= 0.100
          wall_group = 8 # H
        elsif wall_ufactor <= 0.130
          wall_group = 7 # G
        elsif wall_ufactor <= 0.175
          wall_group = 6 # F
        else
          wall_group = 5 # E
        end
      else
        if wall_ufactor <= 0.048
          wall_group = 10 # J
        elsif wall_ufactor <= 0.051
          wall_group = 9 # I
        elsif wall_ufactor <= 0.059
          wall_group = 8 # H
        elsif wall_ufactor <= 0.063
          wall_group = 7 # G
        elsif wall_ufactor <= 0.067
          wall_group = 6 # F
        elsif wall_ufactor <= 0.075
          wall_group = 5 # E
        elsif wall_ufactor <= 0.086
          wall_group = 4 # D
        elsif wall_ufactor <= 0.110
          wall_group = 3 # C
        elsif wall_ufactor <= 0.170
          wall_group = 2 # B
        else
          wall_group = 1 # A
        end
      end

    elsif wall_type == HPXML::WallTypeSteelStud
      if wall.siding == HPXML::SidingTypeBrick
        if wall_ufactor <= 0.090
          wall_group = 11 # K
        elsif wall_ufactor <= 0.105
          wall_group = 10 # J
        elsif wall_ufactor <= 0.118
          wall_group = 9 # I
        elsif wall_ufactor <= 0.125
          wall_group = 8 # H
        elsif wall_ufactor <= 0.145
          wall_group = 7 # G
        elsif wall_ufactor <= 0.200
          wall_group = 6 # F
        else
          wall_group = 5 # E
        end
      else
        if wall_ufactor <= 0.066
          wall_group = 10 # J
        elsif wall_ufactor <= 0.070
          wall_group = 9 # I
        elsif wall_ufactor <= 0.075
          wall_group = 8 # H
        elsif wall_ufactor <= 0.081
          wall_group = 7 # G
        elsif wall_ufactor <= 0.088
          wall_group = 6 # F
        elsif wall_ufactor <= 0.100
          wall_group = 5 # E
        elsif wall_ufactor <= 0.105
          wall_group = 4 # D
        elsif wall_ufactor <= 0.120
          wall_group = 3 # C
        elsif wall_ufactor <= 0.200
          wall_group = 2 # B
        else
          wall_group = 1 # A
        end
      end

    elsif wall_type == HPXML::WallTypeDoubleWoodStud
      wall_group = 10 # J (assumed since MJ8 does not include double stud constructions)
      if wall.siding == HPXML::SidingTypeBrick
        wall_group = 11 # K
      end

    elsif wall_type == HPXML::WallTypeSIP
      # Manual J refers to SIPs as Structural Foam Panel (SFP)
      if wall_ufactor >= (0.072 + 0.050) / 2
        if wall.siding == HPXML::SidingTypeBrick
          wall_group = 10 # J
        else
          wall_group = 7 # G
        end
      elsif wall_ufactor >= 0.050
        if wall.siding == HPXML::SidingTypeBrick
          wall_group = 11 # K
        else
          wall_group = 9 # I
        end
      else
        wall_group = 11 # K
      end

    elsif wall_type == HPXML::WallTypeCMU
      # Table 4A - Construction Number 13
      if wall_ufactor <= 0.0575
        wall_group = 10 # J
      elsif wall_ufactor <= 0.067
        wall_group = 9 # I
      elsif wall_ufactor <= 0.080
        wall_group = 8 # H
      elsif wall_ufactor <= 0.108
        wall_group = 7 # G
      elsif wall_ufactor <= 0.148
        wall_group = 6 # F
      else
        wall_group = 5 # E
      end

    elsif [HPXML::WallTypeBrick, HPXML::WallTypeAdobe].include? wall_type
      # Two Courses Brick
      if wall_ufactor >= (0.218 + 0.179) / 2
        wall_group = 7  # G
      elsif wall_ufactor >= (0.152 + 0.132) / 2
        wall_group = 8  # H
      elsif wall_ufactor >= (0.117 + 0.079) / 2
        wall_group = 9  # I
      elsif wall_ufactor >= 0.079
        wall_group = 10 # J
      else
        wall_group = 11 # K
      end

    elsif wall_type == HPXML::WallTypeLog
      # Stacked Logs
      if wall_ufactor >= (0.103 + 0.091) / 2
        wall_group = 7  # G
      elsif wall_ufactor >= (0.091 + 0.082) / 2
        wall_group = 8  # H
      elsif wall_ufactor >= (0.074 + 0.068) / 2
        wall_group = 9  # I
      elsif wall_ufactor >= (0.068 + 0.063) / 2
        wall_group = 10 # J
      else
        wall_group = 11 # K
      end

    elsif [HPXML::WallTypeICF, HPXML::WallTypeConcrete, HPXML::WallTypeStrawBale, HPXML::WallTypeStone].include? wall_type
      wall_group = 11 # K

    end

    # Maximum wall group is K
    wall_group = [wall_group, 11].min

    return wall_group
  end

  def self.gshp_coil_bf
    return 0.0806
  end

  def self.gshp_coil_bf_ft_spec
    return [1.21005458, -0.00664200, 0.00000000, 0.00348246, 0.00000000, 0.00000000]
  end

  def self.gshp_hx_pipe_rvalue(hvac_cooling_ap)
    # Thermal Resistance of Pipe
    return Math.log(hvac_cooling_ap.pipe_od / hvac_cooling_ap.pipe_id) / 2.0 / Math::PI / hvac_cooling_ap.pipe_cond
  end

  def self.gshp_hxbore_ft_per_ton(weather, hvac_cooling_ap, bore_spacing, pipe_r_value)
    if hvac_cooling_ap.u_tube_spacing_type == 'b'
      beta_0 = 17.4427
      beta_1 = -0.6052
    elsif hvac_cooling_ap.u_tube_spacing_type == 'c'
      beta_0 = 21.9059
      beta_1 = -0.3796
    elsif hvac_cooling_ap.u_tube_spacing_type == 'as'
      beta_0 = 20.1004
      beta_1 = -0.94467
    end

    r_value_ground = Math.log(bore_spacing / hvac_cooling_ap.bore_diameter * 12.0) / 2.0 / Math::PI / @hpxml_bldg.site.ground_conductivity
    r_value_grout = 1.0 / hvac_cooling_ap.grout_conductivity / beta_0 / ((hvac_cooling_ap.bore_diameter / hvac_cooling_ap.pipe_od)**beta_1)
    r_value_bore = r_value_grout + pipe_r_value / 2.0 # Note: Convection resistance is negligible when calculated against Glhepro (Jeffrey D. Spitler, 2000)

    rtf_DesignMon_Heat = [0.25, (71.0 - weather.data.MonthlyAvgDrybulbs[0]) / @htd].max
    rtf_DesignMon_Cool = [0.25, (weather.data.MonthlyAvgDrybulbs[6] - 76.0) / @ctd].max

    nom_length_heat = (1.0 - hvac_cooling_ap.heat_rated_eirs[0]) * (r_value_bore + r_value_ground * rtf_DesignMon_Heat) / (weather.data.AnnualAvgDrybulb - (2.0 * hvac_cooling_ap.design_hw - hvac_cooling_ap.design_delta_t) / 2.0) * UnitConversions.convert(1.0, 'ton', 'Btu/hr')
    nom_length_cool = (1.0 + hvac_cooling_ap.cool_rated_eirs[0]) * (r_value_bore + r_value_ground * rtf_DesignMon_Cool) / ((2.0 * hvac_cooling_ap.design_chw + hvac_cooling_ap.design_delta_t) / 2.0 - weather.data.AnnualAvgDrybulb) * UnitConversions.convert(1.0, 'ton', 'Btu/hr')

    return nom_length_heat, nom_length_cool
  end

  def self.gshp_gfnc_coeff(bore_config, num_bore_holes, spacing_to_depth_ratio)
    # Set GFNC coefficients
    gfnc_coeff = nil
    if bore_config == 'single'
      gfnc_coeff = 2.681, 3.024, 3.320, 3.666, 3.963, 4.306, 4.645, 4.899, 5.222, 5.405, 5.531, 5.704, 5.821, 6.082, 6.304, 6.366, 6.422, 6.477, 6.520, 6.558, 6.591, 6.619, 6.640, 6.665, 6.893, 6.694, 6.715
    elsif bore_config == 'line'
      if num_bore_holes == 2
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.681, 3.043, 3.397, 3.9, 4.387, 5.005, 5.644, 6.137, 6.77, 7.131, 7.381, 7.722, 7.953, 8.462, 8.9, 9.022, 9.13, 9.238, 9.323, 9.396, 9.46, 9.515, 9.556, 9.604, 9.636, 9.652, 9.678
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.024, 3.332, 3.734, 4.143, 4.691, 5.29, 5.756, 6.383, 6.741, 6.988, 7.326, 7.557, 8.058, 8.5, 8.622, 8.731, 8.839, 8.923, 8.997, 9.061, 9.115, 9.156, 9.203, 9.236, 9.252, 9.277
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.668, 3.988, 4.416, 4.921, 5.323, 5.925, 6.27, 6.512, 6.844, 7.073, 7.574, 8.015, 8.137, 8.247, 8.354, 8.439, 8.511, 8.575, 8.629, 8.67, 8.718, 8.75, 8.765, 8.791
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.31, 4.672, 4.919, 5.406, 5.711, 5.932, 6.246, 6.465, 6.945, 7.396, 7.52, 7.636, 7.746, 7.831, 7.905, 7.969, 8.024, 8.066, 8.113, 8.146, 8.161, 8.187
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.648, 4.835, 5.232, 5.489, 5.682, 5.964, 6.166, 6.65, 7.087, 7.208, 7.32, 7.433, 7.52, 7.595, 7.661, 7.717, 7.758, 7.806, 7.839, 7.855, 7.88
        end
      elsif num_bore_holes == 3
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.682, 3.05, 3.425, 3.992, 4.575, 5.366, 6.24, 6.939, 7.86, 8.39, 8.759, 9.263, 9.605, 10.358, 11.006, 11.185, 11.345, 11.503, 11.628, 11.736, 11.831, 11.911, 11.971, 12.041, 12.089, 12.112, 12.151
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.336, 3.758, 4.21, 4.855, 5.616, 6.243, 7.124, 7.639, 7.999, 8.493, 8.833, 9.568, 10.22, 10.399, 10.56, 10.718, 10.841, 10.949, 11.043, 11.122, 11.182, 11.252, 11.299, 11.322, 11.36
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.67, 3.997, 4.454, 5.029, 5.517, 6.298, 6.768, 7.106, 7.578, 7.907, 8.629, 9.274, 9.452, 9.612, 9.769, 9.893, 9.999, 10.092, 10.171, 10.231, 10.3, 10.347, 10.37, 10.407
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.311, 4.681, 4.942, 5.484, 5.844, 6.116, 6.518, 6.807, 7.453, 8.091, 8.269, 8.435, 8.595, 8.719, 8.826, 8.919, 8.999, 9.06, 9.128, 9.175, 9.198, 9.235
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.649, 4.836, 5.25, 5.53, 5.746, 6.076, 6.321, 6.924, 7.509, 7.678, 7.836, 7.997, 8.121, 8.229, 8.325, 8.405, 8.465, 8.535, 8.582, 8.605, 8.642
        end
      elsif num_bore_holes == 4
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.682, 3.054, 3.438, 4.039, 4.676, 5.575, 6.619, 7.487, 8.662, 9.35, 9.832, 10.492, 10.943, 11.935, 12.787, 13.022, 13.232, 13.44, 13.604, 13.745, 13.869, 13.975, 14.054, 14.145, 14.208, 14.238, 14.289
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.339, 3.77, 4.244, 4.941, 5.798, 6.539, 7.622, 8.273, 8.734, 9.373, 9.814, 10.777, 11.63, 11.864, 12.074, 12.282, 12.443, 12.584, 12.706, 12.81, 12.888, 12.979, 13.041, 13.071, 13.12
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.671, 4.001, 4.474, 5.086, 5.62, 6.514, 7.075, 7.487, 8.075, 8.49, 9.418, 10.253, 10.484, 10.692, 10.897, 11.057, 11.195, 11.316, 11.419, 11.497, 11.587, 11.647, 11.677, 11.726
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.311, 4.686, 4.953, 5.523, 5.913, 6.214, 6.67, 7.005, 7.78, 8.574, 8.798, 9.011, 9.215, 9.373, 9.512, 9.632, 9.735, 9.814, 9.903, 9.963, 9.993, 10.041
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.649, 4.837, 5.259, 5.55, 5.779, 6.133, 6.402, 7.084, 7.777, 7.983, 8.178, 8.379, 8.536, 8.672, 8.795, 8.898, 8.975, 9.064, 9.125, 9.155, 9.203
        end
      elsif num_bore_holes == 5
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.056, 3.446, 4.067, 4.737, 5.709, 6.877, 7.879, 9.272, 10.103, 10.69, 11.499, 12.053, 13.278, 14.329, 14.618, 14.878, 15.134, 15.336, 15.51, 15.663, 15.792, 15.89, 16.002, 16.079, 16.117, 16.179
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.34, 3.777, 4.265, 4.993, 5.913, 6.735, 7.974, 8.737, 9.285, 10.054, 10.591, 11.768, 12.815, 13.103, 13.361, 13.616, 13.814, 13.987, 14.137, 14.264, 14.36, 14.471, 14.548, 14.584, 14.645
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.671, 4.004, 4.485, 5.12, 5.683, 6.653, 7.279, 7.747, 8.427, 8.914, 10.024, 11.035, 11.316, 11.571, 11.82, 12.016, 12.185, 12.332, 12.458, 12.553, 12.663, 12.737, 12.773, 12.833
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.688, 4.96, 5.547, 5.955, 6.274, 6.764, 7.132, 8.002, 8.921, 9.186, 9.439, 9.683, 9.873, 10.041, 10.186, 10.311, 10.406, 10.514, 10.588, 10.624, 10.683
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.837, 5.264, 5.562, 5.798, 6.168, 6.452, 7.186, 7.956, 8.191, 8.415, 8.649, 8.834, 8.995, 9.141, 9.265, 9.357, 9.465, 9.539, 9.575, 9.634
        end
      elsif num_bore_holes == 6
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.057, 3.452, 4.086, 4.779, 5.8, 7.06, 8.162, 9.74, 10.701, 11.385, 12.334, 12.987, 14.439, 15.684, 16.027, 16.335, 16.638, 16.877, 17.083, 17.264, 17.417, 17.532, 17.665, 17.756, 17.801, 17.874
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.341, 3.782, 4.278, 5.029, 5.992, 6.87, 8.226, 9.081, 9.704, 10.59, 11.212, 12.596, 13.828, 14.168, 14.473, 14.773, 15.007, 15.211, 15.388, 15.538, 15.652, 15.783, 15.872, 15.916, 15.987
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.671, 4.005, 4.493, 5.143, 5.726, 6.747, 7.42, 7.93, 8.681, 9.227, 10.5, 11.672, 12.001, 12.299, 12.591, 12.821, 13.019, 13.192, 13.34, 13.452, 13.581, 13.668, 13.71, 13.78
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.69, 4.964, 5.563, 5.983, 6.314, 6.828, 7.218, 8.159, 9.179, 9.479, 9.766, 10.045, 10.265, 10.458, 10.627, 10.773, 10.883, 11.01, 11.096, 11.138, 11.207
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.838, 5.268, 5.57, 5.811, 6.191, 6.485, 7.256, 8.082, 8.339, 8.586, 8.848, 9.055, 9.238, 9.404, 9.546, 9.653, 9.778, 9.864, 9.907, 9.976
        end
      elsif num_bore_holes == 7
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.058, 3.456, 4.1, 4.809, 5.867, 7.195, 8.38, 10.114, 11.189, 11.961, 13.04, 13.786, 15.456, 16.89, 17.286, 17.64, 17.989, 18.264, 18.501, 18.709, 18.886, 19.019, 19.172, 19.276, 19.328, 19.412
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.342, 3.785, 4.288, 5.054, 6.05, 6.969, 8.418, 9.349, 10.036, 11.023, 11.724, 13.296, 14.706, 15.096, 15.446, 15.791, 16.059, 16.293, 16.497, 16.668, 16.799, 16.949, 17.052, 17.102, 17.183
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.672, 4.007, 4.499, 5.159, 5.756, 6.816, 7.524, 8.066, 8.874, 9.469, 10.881, 12.2, 12.573, 12.912, 13.245, 13.508, 13.734, 13.932, 14.1, 14.228, 14.376, 14.475, 14.524, 14.604
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.691, 4.967, 5.574, 6.003, 6.343, 6.874, 7.28, 8.276, 9.377, 9.706, 10.022, 10.333, 10.578, 10.795, 10.985, 11.15, 11.276, 11.419, 11.518, 11.565, 11.644
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.838, 5.27, 5.576, 5.821, 6.208, 6.509, 7.307, 8.175, 8.449, 8.715, 8.998, 9.224, 9.426, 9.61, 9.768, 9.887, 10.028, 10.126, 10.174, 10.252
        end
      elsif num_bore_holes == 8
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.059, 3.459, 4.11, 4.832, 5.918, 7.3, 8.55, 10.416, 11.59, 12.442, 13.641, 14.475, 16.351, 17.97, 18.417, 18.817, 19.211, 19.522, 19.789, 20.024, 20.223, 20.373, 20.546, 20.664, 20.721, 20.816
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.342, 3.788, 4.295, 5.073, 6.093, 7.045, 8.567, 9.56, 10.301, 11.376, 12.147, 13.892, 15.472, 15.911, 16.304, 16.692, 16.993, 17.257, 17.486, 17.679, 17.826, 17.995, 18.111, 18.167, 18.259
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.672, 4.008, 4.503, 5.171, 5.779, 6.868, 7.603, 8.17, 9.024, 9.659, 11.187, 12.64, 13.055, 13.432, 13.804, 14.098, 14.351, 14.573, 14.762, 14.905, 15.07, 15.182, 15.237, 15.326
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.692, 4.97, 5.583, 6.018, 6.364, 6.909, 7.327, 8.366, 9.531, 9.883, 10.225, 10.562, 10.83, 11.069, 11.28, 11.463, 11.602, 11.762, 11.872, 11.925, 12.013
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.838, 5.272, 5.58, 5.828, 6.22, 6.527, 7.345, 8.246, 8.533, 8.814, 9.114, 9.356, 9.573, 9.772, 9.944, 10.076, 10.231, 10.34, 10.393, 10.481
        end
      elsif num_bore_holes == 9
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.06, 3.461, 4.118, 4.849, 5.958, 7.383, 8.687, 10.665, 11.927, 12.851, 14.159, 15.075, 17.149, 18.947, 19.443, 19.888, 20.326, 20.672, 20.969, 21.23, 21.452, 21.618, 21.81, 21.941, 22.005, 22.11
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.342, 3.79, 4.301, 5.088, 6.127, 7.105, 8.686, 9.732, 10.519, 11.671, 12.504, 14.408, 16.149, 16.633, 17.069, 17.499, 17.833, 18.125, 18.379, 18.593, 18.756, 18.943, 19.071, 19.133, 19.235
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.672, 4.008, 4.506, 5.181, 5.797, 6.909, 7.665, 8.253, 9.144, 9.813, 11.441, 13.015, 13.468, 13.881, 14.29, 14.613, 14.892, 15.136, 15.345, 15.503, 15.686, 15.809, 15.87, 15.969
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.693, 4.972, 5.589, 6.03, 6.381, 6.936, 7.364, 8.436, 9.655, 10.027, 10.391, 10.751, 11.04, 11.298, 11.527, 11.726, 11.879, 12.054, 12.175, 12.234, 12.331
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.838, 5.273, 5.584, 5.833, 6.23, 6.541, 7.375, 8.302, 8.6, 8.892, 9.208, 9.463, 9.692, 9.905, 10.089, 10.231, 10.4, 10.518, 10.576, 10.673
        end
      elsif num_bore_holes == 10
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.06, 3.463, 4.125, 4.863, 5.99, 7.45, 8.799, 10.872, 12.211, 13.197, 14.605, 15.598, 17.863, 19.834, 20.379, 20.867, 21.348, 21.728, 22.055, 22.342, 22.585, 22.767, 22.978, 23.122, 23.192, 23.307
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.026, 3.343, 3.792, 4.306, 5.1, 6.154, 7.153, 8.784, 9.873, 10.699, 11.918, 12.805, 14.857, 16.749, 17.278, 17.755, 18.225, 18.591, 18.91, 19.189, 19.423, 19.601, 19.807, 19.947, 20.015, 20.126
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.672, 4.009, 4.509, 5.189, 5.812, 6.942, 7.716, 8.32, 9.242, 9.939, 11.654, 13.336, 13.824, 14.271, 14.714, 15.065, 15.368, 15.635, 15.863, 16.036, 16.235, 16.37, 16.435, 16.544
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.694, 4.973, 5.595, 6.039, 6.395, 6.958, 7.394, 8.493, 9.757, 10.146, 10.528, 10.909, 11.215, 11.491, 11.736, 11.951, 12.116, 12.306, 12.437, 12.501, 12.607
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.838, 5.275, 5.587, 5.837, 6.238, 6.552, 7.399, 8.347, 8.654, 8.956, 9.283, 9.549, 9.79, 10.014, 10.209, 10.36, 10.541, 10.669, 10.732, 10.837
        end
      end
    elsif bore_config == 'l-config'
      if num_bore_holes == 3
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.682, 3.052, 3.435, 4.036, 4.668, 5.519, 6.435, 7.155, 8.091, 8.626, 8.997, 9.504, 9.847, 10.605, 11.256, 11.434, 11.596, 11.755, 11.88, 11.988, 12.083, 12.163, 12.224, 12.294, 12.342, 12.365, 12.405
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.337, 3.767, 4.242, 4.937, 5.754, 6.419, 7.33, 7.856, 8.221, 8.721, 9.063, 9.818, 10.463, 10.641, 10.801, 10.959, 11.084, 11.191, 11.285, 11.365, 11.425, 11.495, 11.542, 11.565, 11.603
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.67, 3.999, 4.472, 5.089, 5.615, 6.449, 6.942, 7.292, 7.777, 8.111, 8.847, 9.497, 9.674, 9.836, 9.993, 10.117, 10.224, 10.317, 10.397, 10.457, 10.525, 10.573, 10.595, 10.633
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.311, 4.684, 4.95, 5.525, 5.915, 6.209, 6.64, 6.946, 7.645, 8.289, 8.466, 8.63, 8.787, 8.912, 9.018, 9.112, 9.192, 9.251, 9.32, 9.367, 9.39, 9.427
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.649, 4.836, 5.255, 5.547, 5.777, 6.132, 6.397, 7.069, 7.673, 7.848, 8.005, 8.161, 8.29, 8.397, 8.492, 8.571, 8.631, 8.7, 8.748, 8.771, 8.808
        end
      elsif num_bore_holes == 4
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.055, 3.446, 4.075, 4.759, 5.729, 6.841, 7.753, 8.96, 9.659, 10.147, 10.813, 11.266, 12.265, 13.122, 13.356, 13.569, 13.778, 13.942, 14.084, 14.208, 14.314, 14.393, 14.485, 14.548, 14.579, 14.63
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.339, 3.777, 4.27, 5.015, 5.945, 6.739, 7.875, 8.547, 9.018, 9.668, 10.116, 11.107, 11.953, 12.186, 12.395, 12.603, 12.766, 12.906, 13.029, 13.133, 13.212, 13.303, 13.365, 13.395, 13.445
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.671, 4.003, 4.488, 5.137, 5.713, 6.678, 7.274, 7.707, 8.319, 8.747, 9.698, 10.543, 10.774, 10.984, 11.19, 11.351, 11.49, 11.612, 11.715, 11.793, 11.882, 11.944, 11.974, 12.022
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.311, 4.688, 4.959, 5.558, 5.976, 6.302, 6.794, 7.155, 8.008, 8.819, 9.044, 9.255, 9.456, 9.618, 9.755, 9.877, 9.98, 10.057, 10.146, 10.207, 10.236, 10.285
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.649, 4.837, 5.263, 5.563, 5.804, 6.183, 6.473, 7.243, 7.969, 8.185, 8.382, 8.58, 8.743, 8.88, 9.001, 9.104, 9.181, 9.27, 9.332, 9.361, 9.409
        end
      elsif num_bore_holes == 5
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.057, 3.453, 4.097, 4.806, 5.842, 7.083, 8.14, 9.579, 10.427, 11.023, 11.841, 12.399, 13.633, 14.691, 14.98, 15.242, 15.499, 15.701, 15.877, 16.03, 16.159, 16.257, 16.37, 16.448, 16.485, 16.549
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.34, 3.783, 4.285, 5.054, 6.038, 6.915, 8.219, 9.012, 9.576, 10.362, 10.907, 12.121, 13.161, 13.448, 13.705, 13.96, 14.16, 14.332, 14.483, 14.61, 14.707, 14.819, 14.895, 14.932, 14.993
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.671, 4.005, 4.497, 5.162, 5.76, 6.796, 7.461, 7.954, 8.665, 9.17, 10.31, 11.338, 11.62, 11.877, 12.127, 12.324, 12.494, 12.643, 12.77, 12.865, 12.974, 13.049, 13.085, 13.145
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.69, 4.964, 5.575, 6.006, 6.347, 6.871, 7.263, 8.219, 9.164, 9.432, 9.684, 9.926, 10.121, 10.287, 10.434, 10.56, 10.654, 10.762, 10.836, 10.872, 10.93
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.837, 5.267, 5.573, 5.819, 6.208, 6.51, 7.33, 8.136, 8.384, 8.613, 8.844, 9.037, 9.2, 9.345, 9.468, 9.562, 9.67, 9.744, 9.78, 9.839
        end
      elsif num_bore_holes == 6
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.058, 3.457, 4.111, 4.837, 5.916, 7.247, 8.41, 10.042, 11.024, 11.72, 12.681, 13.339, 14.799, 16.054, 16.396, 16.706, 17.011, 17.25, 17.458, 17.639, 17.792, 17.907, 18.041, 18.133, 18.177, 18.253
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.341, 3.786, 4.296, 5.08, 6.099, 7.031, 8.456, 9.346, 9.988, 10.894, 11.528, 12.951, 14.177, 14.516, 14.819, 15.12, 15.357, 15.56, 15.737, 15.888, 16.002, 16.134, 16.223, 16.267, 16.338
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.671, 4.007, 4.503, 5.178, 5.791, 6.872, 7.583, 8.119, 8.905, 9.472, 10.774, 11.969, 12.3, 12.6, 12.895, 13.126, 13.326, 13.501, 13.649, 13.761, 13.89, 13.977, 14.02, 14.09
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.691, 4.968, 5.586, 6.026, 6.375, 6.919, 7.331, 8.357, 9.407, 9.71, 9.997, 10.275, 10.501, 10.694, 10.865, 11.011, 11.121, 11.247, 11.334, 11.376, 11.445
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.838, 5.27, 5.579, 5.828, 6.225, 6.535, 7.384, 8.244, 8.515, 8.768, 9.026, 9.244, 9.428, 9.595, 9.737, 9.845, 9.97, 10.057, 10.099, 10.168
        end
      end
    elsif bore_config == 'l2-config'
      if num_bore_holes == 8
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.685, 3.078, 3.547, 4.438, 5.521, 7.194, 9.237, 10.973, 13.311, 14.677, 15.634, 16.942, 17.831, 19.791, 21.462, 21.917, 22.329, 22.734, 23.052, 23.328, 23.568, 23.772, 23.925, 24.102, 24.224, 24.283, 24.384
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.027, 3.354, 3.866, 4.534, 5.682, 7.271, 8.709, 10.845, 12.134, 13.046, 14.308, 15.177, 17.106, 18.741, 19.19, 19.592, 19.989, 20.303, 20.57, 20.805, 21.004, 21.155, 21.328, 21.446, 21.504, 21.598
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.676, 4.034, 4.639, 5.587, 6.514, 8.195, 9.283, 10.09, 11.244, 12.058, 13.88, 15.491, 15.931, 16.328, 16.716, 17.02, 17.282, 17.511, 17.706, 17.852, 18.019, 18.134, 18.19, 18.281
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.315, 4.72, 5.041, 5.874, 6.525, 7.06, 7.904, 8.541, 10.093, 11.598, 12.018, 12.41, 12.784, 13.084, 13.338, 13.562, 13.753, 13.895, 14.058, 14.169, 14.223, 14.312
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.307, 4.653, 4.842, 5.325, 5.717, 6.058, 6.635, 7.104, 8.419, 9.714, 10.108, 10.471, 10.834, 11.135, 11.387, 11.61, 11.798, 11.94, 12.103, 12.215, 12.268, 12.356
        end
      elsif num_bore_holes == 10
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.685, 3.08, 3.556, 4.475, 5.611, 7.422, 9.726, 11.745, 14.538, 16.199, 17.369, 18.975, 20.071, 22.489, 24.551, 25.111, 25.619, 26.118, 26.509, 26.848, 27.143, 27.393, 27.582, 27.8, 27.949, 28.022, 28.146
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.027, 3.356, 3.874, 4.559, 5.758, 7.466, 9.07, 11.535, 13.06, 14.153, 15.679, 16.739, 19.101, 21.106, 21.657, 22.15, 22.637, 23.021, 23.348, 23.635, 23.879, 24.063, 24.275, 24.42, 24.49, 24.605
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.676, 4.037, 4.653, 5.634, 6.61, 8.44, 9.664, 10.589, 11.936, 12.899, 15.086, 17.041, 17.575, 18.058, 18.53, 18.9, 19.218, 19.496, 19.733, 19.91, 20.113, 20.252, 20.32, 20.431
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.315, 4.723, 5.048, 5.904, 6.584, 7.151, 8.062, 8.764, 10.521, 12.281, 12.779, 13.246, 13.694, 14.054, 14.36, 14.629, 14.859, 15.03, 15.226, 15.36, 15.425, 15.531
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.307, 4.653, 4.842, 5.331, 5.731, 6.083, 6.683, 7.178, 8.6, 10.054, 10.508, 10.929, 11.356, 11.711, 12.009, 12.275, 12.5, 12.671, 12.866, 13, 13.064, 13.17
        end
      end
    elsif bore_config == 'u-config'
      if num_bore_holes == 5
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.057, 3.46, 4.134, 4.902, 6.038, 7.383, 8.503, 9.995, 10.861, 11.467, 12.294, 12.857, 14.098, 15.16, 15.449, 15.712, 15.97, 16.173, 16.349, 16.503, 16.633, 16.731, 16.844, 16.922, 16.96, 17.024
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.341, 3.789, 4.31, 5.136, 6.219, 7.172, 8.56, 9.387, 9.97, 10.774, 11.328, 12.556, 13.601, 13.889, 14.147, 14.403, 14.604, 14.777, 14.927, 15.056, 15.153, 15.265, 15.341, 15.378, 15.439
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.671, 4.007, 4.51, 5.213, 5.864, 6.998, 7.717, 8.244, 8.993, 9.518, 10.69, 11.73, 12.015, 12.273, 12.525, 12.723, 12.893, 13.043, 13.17, 13.265, 13.374, 13.449, 13.486, 13.546
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.692, 4.969, 5.607, 6.072, 6.444, 7.018, 7.446, 8.474, 9.462, 9.737, 9.995, 10.241, 10.438, 10.606, 10.754, 10.88, 10.975, 11.083, 11.157, 11.193, 11.252
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.838, 5.27, 5.585, 5.843, 6.26, 6.588, 7.486, 8.353, 8.614, 8.854, 9.095, 9.294, 9.46, 9.608, 9.733, 9.828, 9.936, 10.011, 10.047, 10.106
        end
      elsif num_bore_holes == 7
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.059, 3.467, 4.164, 4.994, 6.319, 8.011, 9.482, 11.494, 12.679, 13.511, 14.651, 15.427, 17.139, 18.601, 18.999, 19.359, 19.714, 19.992, 20.233, 20.443, 20.621, 20.755, 20.91, 21.017, 21.069, 21.156
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.342, 3.795, 4.329, 5.214, 6.465, 7.635, 9.435, 10.54, 11.327, 12.421, 13.178, 14.861, 16.292, 16.685, 17.038, 17.386, 17.661, 17.896, 18.101, 18.276, 18.408, 18.56, 18.663, 18.714, 18.797
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.672, 4.009, 4.519, 5.253, 5.965, 7.304, 8.204, 8.882, 9.866, 10.566, 12.145, 13.555, 13.941, 14.29, 14.631, 14.899, 15.129, 15.331, 15.502, 15.631, 15.778, 15.879, 15.928, 16.009
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.694, 4.975, 5.629, 6.127, 6.54, 7.207, 7.723, 9.019, 10.314, 10.68, 11.023, 11.352, 11.617, 11.842, 12.04, 12.209, 12.335, 12.48, 12.579, 12.627, 12.705
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.838, 5.275, 5.595, 5.861, 6.304, 6.665, 7.709, 8.785, 9.121, 9.434, 9.749, 10.013, 10.233, 10.43, 10.597, 10.723, 10.868, 10.967, 11.015, 11.094
        end
      elsif num_bore_holes == 9
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.683, 3.061, 3.47, 4.178, 5.039, 6.472, 8.405, 10.147, 12.609, 14.086, 15.131, 16.568, 17.55, 19.72, 21.571, 22.073, 22.529, 22.976, 23.327, 23.632, 23.896, 24.121, 24.29, 24.485, 24.619, 24.684, 24.795
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.025, 3.343, 3.798, 4.338, 5.248, 6.588, 7.902, 10.018, 11.355, 12.321, 13.679, 14.625, 16.74, 18.541, 19.036, 19.478, 19.916, 20.261, 20.555, 20.812, 21.031, 21.197, 21.387, 21.517, 21.58, 21.683
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.672, 4.01, 4.524, 5.27, 6.01, 7.467, 8.489, 9.281, 10.452, 11.299, 13.241, 14.995, 15.476, 15.912, 16.337, 16.67, 16.957, 17.208, 17.421, 17.581, 17.764, 17.889, 17.95, 18.05
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.312, 4.695, 4.977, 5.639, 6.15, 6.583, 7.298, 7.869, 9.356, 10.902, 11.347, 11.766, 12.169, 12.495, 12.772, 13.017, 13.225, 13.381, 13.559, 13.681, 13.74, 13.837
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.65, 4.838, 5.277, 5.6, 5.87, 6.322, 6.698, 7.823, 9.044, 9.438, 9.809, 10.188, 10.506, 10.774, 11.015, 11.219, 11.374, 11.552, 11.674, 11.733, 11.83
        end
      end
    elsif bore_config == 'open-rectangle'
      if num_bore_holes == 8
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.684, 3.066, 3.497, 4.275, 5.229, 6.767, 8.724, 10.417, 12.723, 14.079, 15.03, 16.332, 17.217, 19.17, 20.835, 21.288, 21.698, 22.101, 22.417, 22.692, 22.931, 23.133, 23.286, 23.462, 23.583, 23.642, 23.742
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.026, 3.347, 3.821, 4.409, 5.418, 6.87, 8.226, 10.299, 11.565, 12.466, 13.716, 14.58, 16.498, 18.125, 18.572, 18.972, 19.368, 19.679, 19.946, 20.179, 20.376, 20.527, 20.699, 20.816, 20.874, 20.967
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.673, 4.018, 4.564, 5.389, 6.21, 7.763, 8.801, 9.582, 10.709, 11.51, 13.311, 14.912, 15.349, 15.744, 16.13, 16.432, 16.693, 16.921, 17.114, 17.259, 17.426, 17.54, 17.595, 17.686
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.313, 4.704, 4.999, 5.725, 6.294, 6.771, 7.543, 8.14, 9.629, 11.105, 11.52, 11.908, 12.28, 12.578, 12.831, 13.054, 13.244, 13.386, 13.548, 13.659, 13.712, 13.8
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.651, 4.839, 5.293, 5.641, 5.938, 6.44, 6.856, 8.062, 9.297, 9.681, 10.036, 10.394, 10.692, 10.941, 11.163, 11.35, 11.492, 11.654, 11.766, 11.819, 11.907
        end
      elsif num_bore_holes == 10
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.684, 3.066, 3.494, 4.262, 5.213, 6.81, 8.965, 10.906, 13.643, 15.283, 16.443, 18.038, 19.126, 21.532, 23.581, 24.138, 24.642, 25.137, 25.525, 25.862, 26.155, 26.403, 26.59, 26.806, 26.955, 27.027, 27.149
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.026, 3.346, 3.818, 4.399, 5.4, 6.889, 8.358, 10.713, 12.198, 13.27, 14.776, 15.824, 18.167, 20.158, 20.704, 21.194, 21.677, 22.057, 22.382, 22.666, 22.907, 23.09, 23.3, 23.443, 23.513, 23.627
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.673, 4.018, 4.559, 5.374, 6.193, 7.814, 8.951, 9.831, 11.13, 12.069, 14.219, 16.154, 16.684, 17.164, 17.631, 17.998, 18.314, 18.59, 18.824, 19, 19.201, 19.338, 19.405, 19.515
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.313, 4.703, 4.996, 5.712, 6.275, 6.755, 7.549, 8.183, 9.832, 11.54, 12.029, 12.49, 12.933, 13.29, 13.594, 13.862, 14.09, 14.26, 14.455, 14.588, 14.652, 14.758
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.651, 4.839, 5.292, 5.636, 5.928, 6.425, 6.841, 8.089, 9.44, 9.875, 10.284, 10.7, 11.05, 11.344, 11.608, 11.831, 12.001, 12.196, 12.329, 12.393, 12.499
        end
      end
    elsif bore_config == 'rectangle'
      if num_bore_holes == 4
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.684, 3.066, 3.493, 4.223, 5.025, 6.131, 7.338, 8.291, 9.533, 10.244, 10.737, 11.409, 11.865, 12.869, 13.73, 13.965, 14.178, 14.388, 14.553, 14.696, 14.821, 14.927, 15.007, 15.099, 15.162, 15.193, 15.245
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.026, 3.347, 3.818, 4.383, 5.255, 6.314, 7.188, 8.392, 9.087, 9.571, 10.233, 10.686, 11.685, 12.536, 12.77, 12.98, 13.189, 13.353, 13.494, 13.617, 13.721, 13.801, 13.892, 13.955, 13.985, 14.035
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.673, 4.018, 4.555, 5.313, 5.984, 7.069, 7.717, 8.177, 8.817, 9.258, 10.229, 11.083, 11.316, 11.527, 11.733, 11.895, 12.035, 12.157, 12.261, 12.339, 12.429, 12.491, 12.521, 12.57
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.313, 4.703, 4.998, 5.69, 6.18, 6.557, 7.115, 7.514, 8.428, 9.27, 9.501, 9.715, 9.92, 10.083, 10.221, 10.343, 10.447, 10.525, 10.614, 10.675, 10.704, 10.753
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.306, 4.651, 4.839, 5.293, 5.633, 5.913, 6.355, 6.693, 7.559, 8.343, 8.57, 8.776, 8.979, 9.147, 9.286, 9.409, 9.512, 9.59, 9.68, 9.741, 9.771, 9.819
        end
      elsif num_bore_holes == 6
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.684, 3.074, 3.526, 4.349, 5.308, 6.719, 8.363, 9.72, 11.52, 12.562, 13.289, 14.282, 14.956, 16.441, 17.711, 18.057, 18.371, 18.679, 18.921, 19.132, 19.315, 19.47, 19.587, 19.722, 19.815, 19.861, 19.937
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.026, 3.351, 3.847, 4.472, 5.499, 6.844, 8.016, 9.702, 10.701, 11.403, 12.369, 13.032, 14.502, 15.749, 16.093, 16.4, 16.705, 16.945, 17.15, 17.329, 17.482, 17.598, 17.731, 17.822, 17.866, 17.938
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.675, 4.028, 4.605, 5.471, 6.283, 7.688, 8.567, 9.207, 10.112, 10.744, 12.149, 13.389, 13.727, 14.033, 14.332, 14.567, 14.769, 14.946, 15.096, 15.21, 15.339, 15.428, 15.471, 15.542
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.314, 4.714, 5.024, 5.798, 6.378, 6.841, 7.553, 8.079, 9.327, 10.512, 10.84, 11.145, 11.437, 11.671, 11.869, 12.044, 12.192, 12.303, 12.431, 12.518, 12.56, 12.629
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.307, 4.652, 4.841, 5.313, 5.684, 5.999, 6.517, 6.927, 8.034, 9.087, 9.401, 9.688, 9.974, 10.21, 10.408, 10.583, 10.73, 10.841, 10.969, 11.056, 11.098, 11.167
        end
      elsif num_bore_holes == 8
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.685, 3.078, 3.543, 4.414, 5.459, 7.06, 9.021, 10.701, 12.991, 14.34, 15.287, 16.586, 17.471, 19.423, 21.091, 21.545, 21.956, 22.36, 22.677, 22.953, 23.192, 23.395, 23.548, 23.725, 23.847, 23.906, 24.006
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.027, 3.354, 3.862, 4.517, 5.627, 7.142, 8.525, 10.589, 11.846, 12.741, 13.986, 14.847, 16.762, 18.391, 18.839, 19.24, 19.637, 19.95, 20.217, 20.45, 20.649, 20.8, 20.973, 21.091, 21.148, 21.242
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.675, 4.033, 4.63, 5.553, 6.444, 8.051, 9.096, 9.874, 10.995, 11.79, 13.583, 15.182, 15.619, 16.016, 16.402, 16.705, 16.967, 17.195, 17.389, 17.535, 17.702, 17.817, 17.873, 17.964
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.315, 4.719, 5.038, 5.852, 6.48, 6.993, 7.799, 8.409, 9.902, 11.371, 11.784, 12.17, 12.541, 12.839, 13.092, 13.315, 13.505, 13.647, 13.81, 13.921, 13.975, 14.063
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.307, 4.653, 4.842, 5.323, 5.71, 6.042, 6.6, 7.05, 8.306, 9.552, 9.935, 10.288, 10.644, 10.94, 11.188, 11.409, 11.596, 11.738, 11.9, 12.011, 12.065, 12.153
        end
      elsif num_bore_holes == 9
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.685, 3.082, 3.561, 4.49, 5.635, 7.436, 9.672, 11.59, 14.193, 15.721, 16.791, 18.256, 19.252, 21.447, 23.318, 23.826, 24.287, 24.74, 25.095, 25.404, 25.672, 25.899, 26.071, 26.269, 26.405, 26.471, 26.583
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.027, 3.357, 3.879, 4.57, 5.781, 7.488, 9.052, 11.408, 12.84, 13.855, 15.263, 16.235, 18.39, 20.216, 20.717, 21.166, 21.61, 21.959, 22.257, 22.519, 22.74, 22.909, 23.102, 23.234, 23.298, 23.403
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.676, 4.039, 4.659, 5.65, 6.633, 8.447, 9.638, 10.525, 11.802, 12.705, 14.731, 16.525, 17.014, 17.456, 17.887, 18.225, 18.516, 18.77, 18.986, 19.148, 19.334, 19.461, 19.523, 19.625
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.316, 4.725, 5.052, 5.917, 6.603, 7.173, 8.08, 8.772, 10.47, 12.131, 12.596, 13.029, 13.443, 13.775, 14.057, 14.304, 14.515, 14.673, 14.852, 14.975, 15.035, 15.132
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.307, 4.653, 4.842, 5.334, 5.739, 6.094, 6.7, 7.198, 8.611, 10.023, 10.456, 10.855, 11.256, 11.588, 11.866, 12.112, 12.32, 12.477, 12.656, 12.779, 12.839, 12.935
        end
      elsif num_bore_holes == 10
        if spacing_to_depth_ratio <= 0.02
          gfnc_coeff = 2.685, 3.08, 3.553, 4.453, 5.552, 7.282, 9.472, 11.405, 14.111, 15.737, 16.888, 18.476, 19.562, 21.966, 24.021, 24.579, 25.086, 25.583, 25.973, 26.311, 26.606, 26.855, 27.043, 27.26, 27.409, 27.482, 27.605
        elsif spacing_to_depth_ratio <= 0.03
          gfnc_coeff = 2.679, 3.027, 3.355, 3.871, 4.545, 5.706, 7.332, 8.863, 11.218, 12.688, 13.749, 15.242, 16.284, 18.618, 20.613, 21.161, 21.652, 22.138, 22.521, 22.847, 23.133, 23.376, 23.56, 23.771, 23.915, 23.985, 24.1
        elsif spacing_to_depth_ratio <= 0.05
          gfnc_coeff = 2.679, 3.023, 3.319, 3.676, 4.036, 4.645, 5.603, 6.543, 8.285, 9.449, 10.332, 11.623, 12.553, 14.682, 16.613, 17.143, 17.624, 18.094, 18.462, 18.78, 19.057, 19.293, 19.47, 19.673, 19.811, 19.879, 19.989
        elsif spacing_to_depth_ratio <= 0.1
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.962, 4.315, 4.722, 5.045, 5.885, 6.543, 7.086, 7.954, 8.621, 10.291, 11.988, 12.473, 12.931, 13.371, 13.727, 14.03, 14.299, 14.527, 14.698, 14.894, 15.027, 15.092, 15.199
        else
          gfnc_coeff = 2.679, 3.023, 3.318, 3.664, 3.961, 4.307, 4.653, 4.842, 5.329, 5.725, 6.069, 6.651, 7.126, 8.478, 9.863, 10.298, 10.704, 11.117, 11.463, 11.755, 12.016, 12.239, 12.407, 12.602, 12.735, 12.8, 12.906
        end
      end
    end
    return gfnc_coeff
  end

  def self.calculate_average_r_value(surfaces)
    # Crude approximation of average R-value
    surfaces_a = 0.0
    surfaces_ua = 0.0
    surfaces.each do |surface|
      surfaces_a += surface.area
      if not surface.insulation_assembly_r_value.nil?
        surfaces_ua += (1.0 / surface.insulation_assembly_r_value) * surface.area
      else
        surfaces_ua += (1.0 / (surface.insulation_interior_r_value + surface.insulation_exterior_r_value)) * surface.area
      end
    end
    return surfaces_a / surfaces_ua
  end

  def self.get_foundation_wall_properties(foundation_wall)
    # Calculate effective U-factor

    if not foundation_wall.insulation_assembly_r_value.nil?
      wall_constr_rvalue = foundation_wall.insulation_assembly_r_value - Material.AirFilmVertical.rvalue
      wall_ins_rvalue_int, wall_ins_rvalue_ext = 0, 0
      wall_ins_dist_to_top_int, wall_ins_dist_to_top_ext = 0, 0
      wall_ins_dist_to_bottom_int, wall_ins_dist_to_bottom_ext = 0, 0
    else
      wall_constr_rvalue = Material.Concrete(foundation_wall.thickness).rvalue
      wall_ins_rvalue_int = foundation_wall.insulation_interior_r_value
      wall_ins_rvalue_ext = foundation_wall.insulation_exterior_r_value
      wall_ins_dist_to_top_int = foundation_wall.insulation_interior_distance_to_top
      wall_ins_dist_to_top_ext = foundation_wall.insulation_exterior_distance_to_top
      wall_ins_dist_to_bottom_int = foundation_wall.insulation_interior_distance_to_bottom
      wall_ins_dist_to_bottom_ext = foundation_wall.insulation_exterior_distance_to_bottom
    end
    k_soil = @hpxml_bldg.site.ground_conductivity

    # Calculated based on Manual J 8th Ed. procedure in section A12-4 (15% decrease due to soil thermal storage)
    u_wall_with_soil = 0.0
    u_wall_without_soil = 0.0
    wall_height = foundation_wall.height.ceil
    wall_depth_above_grade = foundation_wall.height - foundation_wall.depth_below_grade
    for distance_to_top in 1..wall_height
      # Calculate R-wall at this depth
      r_wall = wall_constr_rvalue + Material.AirFilmVertical.rvalue # Base wall construction + interior film
      if distance_to_top <= wall_depth_above_grade
        # Above-grade: no soil, add exterior film
        r_soil = 0.0
        r_wall += Material.AirFilmOutside.rvalue
      else
        # Below-grade: add soil, no exterior film
        distance_to_grade = distance_to_top - wall_depth_above_grade
        r_soil = (Math::PI * distance_to_grade / 2.0) / k_soil
      end
      if (distance_to_top > wall_ins_dist_to_top_int) && (distance_to_top <= wall_ins_dist_to_bottom_int)
        r_wall += wall_ins_rvalue_int # Interior insulation at this depth, add R-value
      end
      if (distance_to_top > wall_ins_dist_to_top_ext) && (distance_to_top <= wall_ins_dist_to_bottom_ext)
        r_wall += wall_ins_rvalue_ext # Interior insulation at this depth, add R-value
      end
      u_wall_with_soil += 1.0 / (r_soil + r_wall)
      u_wall_without_soil += 1.0 / r_wall
    end
    u_wall_with_soil = (u_wall_with_soil / wall_height) * 0.85
    u_wall_without_soil = (u_wall_without_soil / wall_height)

    return u_wall_with_soil, u_wall_without_soil
  end

  def self.calc_slab_f_value(slab, ground_conductivity)
    # Calculation for the F-values in Table 4A for slab foundations.
    # Important pages are the Table values (pg. 344-345) and the software protocols
    # in Appendix 12 (pg. 517-518).
    ins_rvalue = slab.under_slab_insulation_r_value + slab.perimeter_insulation_r_value
    ins_rvalue_edge = slab.perimeter_insulation_r_value
    if slab.under_slab_insulation_spans_entire_slab
      ins_length = 1000.0
    else
      ins_length = 0
      if slab.under_slab_insulation_r_value > 0
        ins_length += slab.under_slab_insulation_width
      end
      if slab.perimeter_insulation_r_value > 0
        ins_length += slab.perimeter_insulation_depth
      end
    end

    soil_r_per_foot = ground_conductivity
    slab_r_gravel_per_inch = 0.65 # Based on calibration by Tony Fontanini

    # Because of uncertainty pertaining to the effective path radius, F-values are calculated
    # for six radii (8, 9, 10, 11, 12, and 13 feet) and averaged.
    f_values = []
    for path_radius in 8..13
      u_effective = []
      for radius in 0..path_radius
        spl = [Math::PI * radius - 1, 0].max # soil path length (SPL)

        # Concrete, gravel, and insulation
        if radius == 0
          r_concrete = 0.0
          r_gravel = 0.0 # No gravel on edge
          r_ins = ins_rvalue_edge
        else
          r_concrete = Material.Concrete(slab.thickness).rvalue
          r_gravel = [slab_r_gravel_per_inch * (12.0 - slab.thickness), 0].max
          if radius <= ins_length
            r_ins = ins_rvalue
          else
            r_ins = 0.0
          end
        end

        # Air Films = Indoor Finish + Indoor Air Film + Exposed Air Film (Figure A12-6 pg. 517)
        r_air_film = 0.05 + 0.92 + 0.17

        # Soil
        r_soil = soil_r_per_foot * spl # (h-F-ft2/BTU)

        # Effective R-Value
        r_air_to_air = r_concrete + r_gravel + r_ins + r_air_film + r_soil

        # Effective U-Factor
        u_effective << 1.0 / r_air_to_air
      end

      f_values << u_effective.inject(0, :+) # sum array
    end

    return f_values.sum() / f_values.size
  end

  def self.set_hvac_types(hvac_heating, hvac_cooling)
    if hvac_heating.nil?
      @heating_type = nil
    elsif hvac_heating.is_a? HPXML::HeatingSystem
      @heating_type = hvac_heating.heating_system_type
    else
      @heating_type = hvac_heating.heat_pump_type
    end
    if hvac_cooling.nil?
      @cooling_type = nil
    elsif hvac_cooling.is_a? HPXML::CoolingSystem
      @cooling_type = hvac_cooling.cooling_system_type
    else
      @cooling_type = hvac_cooling.heat_pump_type
    end
  end

  def self.set_fractions_load_served(hvac_heating, hvac_cooling)
    if hvac_cooling.is_a?(HPXML::CoolingSystem) && hvac_cooling.has_integrated_heating
      @fraction_heat_load_served = hvac_cooling.integrated_heating_system_fraction_heat_load_served
    elsif hvac_heating.nil?
      @fraction_heat_load_served = 0
    elsif hvac_heating.is_a?(HPXML::HeatingSystem) && hvac_heating.is_heat_pump_backup_system
      # Use the same load fractions as the heat pump
      heat_pump = @hpxml_bldg.heat_pumps.find { |hp| hp.backup_system_idref == hvac_heating.id }
      @fraction_heat_load_served = heat_pump.fraction_heat_load_served
    else
      @fraction_heat_load_served = hvac_heating.fraction_heat_load_served
    end
    if hvac_cooling.nil?
      @fraction_cool_load_served = 0
    else
      @fraction_cool_load_served = hvac_cooling.fraction_cool_load_served
    end
  end
end

class DesignLoads
  def initialize
  end
  attr_accessor(:Cool_Sens, :Cool_Lat, :Cool_Tot, :Heat_Tot, :Heat_Ducts, :Cool_Ducts_Sens, :Cool_Ducts_Lat,
                :Cool_Windows, :Cool_Skylights, :Cool_Doors, :Cool_Walls, :Cool_Roofs, :Cool_Floors,
                :Cool_Ceilings, :Cool_InfilVent_Sens, :Cool_InfilVent_Lat, :Cool_IntGains_Sens, :Cool_IntGains_Lat,
                :Heat_Windows, :Heat_Skylights, :Heat_Doors, :Heat_Walls, :Heat_Roofs, :Heat_Floors,
                :Heat_Slabs, :Heat_Ceilings, :Heat_InfilVent)
end

class HVACSizingValues
  def initialize
  end
  attr_accessor(:Cool_Load_Sens, :Cool_Load_Lat, :Cool_Load_Tot,
                :Cool_Capacity, :Cool_Capacity_Sens, :Cool_Airflow,
                :Heat_Load, :Heat_Load_Supp, :Heat_Capacity, :Heat_Capacity_Supp,
                :Heat_Airflow, :Heat_Airflow_Supp,
                :GSHP_Loop_flow, :GSHP_Bore_Holes, :GSHP_Bore_Depth, :GSHP_G_Functions)
end

class Numeric
  def deg2rad
    self * Math::PI / 180
  end

  def rad2deg
    self * 180 / Math::PI
  end
end
