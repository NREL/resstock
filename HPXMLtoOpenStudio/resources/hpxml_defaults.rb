# frozen_string_literal: true

class HPXMLDefaults
  # Note: Each HPXML object has an additional_properties child object where
  # custom information can be attached to the object without being written
  # to the HPXML file. This is useful to associate additional values with the
  # HPXML objects that will ultimately get passed around.

  def self.apply(hpxml, runner, epw_file, weather, cfa, nbeds, ncfl, ncfl_ag, has_uncond_bsmnt, eri_version)
    apply_header(hpxml, epw_file, runner)
    apply_site(hpxml)
    apply_building_occupancy(hpxml, nbeds)
    apply_building_construction(hpxml, cfa, nbeds)
    apply_infiltration(hpxml)
    apply_attics(hpxml)
    apply_foundations(hpxml)
    apply_roofs(hpxml)
    apply_rim_joists(hpxml)
    apply_walls(hpxml)
    apply_foundation_walls(hpxml)
    apply_slabs(hpxml)
    apply_windows(hpxml)
    apply_skylights(hpxml)
    apply_hvac(hpxml, weather)
    apply_hvac_control(hpxml)
    apply_hvac_distribution(hpxml, ncfl, ncfl_ag)
    apply_ventilation_fans(hpxml)
    apply_water_heaters(hpxml, nbeds, eri_version)
    apply_hot_water_distribution(hpxml, cfa, ncfl, has_uncond_bsmnt)
    apply_water_fixtures(hpxml)
    apply_solar_thermal_systems(hpxml)
    apply_appliances(hpxml, nbeds, eri_version)
    apply_lighting(hpxml)
    apply_ceiling_fans(hpxml, nbeds)
    apply_pools_and_hot_tubs(hpxml, cfa, nbeds)
    apply_plug_loads(hpxml, cfa, nbeds)
    apply_fuel_loads(hpxml, cfa, nbeds)
    apply_pv_systems(hpxml)
    apply_generators(hpxml)

    # Do HVAC sizing after all other defaults have been applied
    apply_hvac_sizing(hpxml, runner, weather, cfa, nbeds)
  end

  private

  def self.apply_header(hpxml, epw_file, runner)
    if hpxml.header.timestep.nil?
      hpxml.header.timestep = 60
      hpxml.header.timestep_isdefaulted = true
    end

    if hpxml.header.sim_begin_month.nil?
      hpxml.header.sim_begin_month = 1
      hpxml.header.sim_begin_month_isdefaulted = true
    end
    if hpxml.header.sim_begin_day.nil?
      hpxml.header.sim_begin_day = 1
      hpxml.header.sim_begin_day_isdefaulted = true
    end
    if hpxml.header.sim_end_month.nil?
      hpxml.header.sim_end_month = 12
      hpxml.header.sim_end_month_isdefaulted = true
    end
    if hpxml.header.sim_end_day.nil?
      hpxml.header.sim_end_day = 31
      hpxml.header.sim_end_day_isdefaulted = true
    end

    if epw_file.startDateActualYear.is_initialized # AMY
      if not hpxml.header.sim_calendar_year.nil?
        if hpxml.header.sim_calendar_year != epw_file.startDateActualYear.get
          runner.registerWarning("Overriding Calendar Year (#{hpxml.header.sim_calendar_year}) with AMY year (#{epw_file.startDateActualYear.get}).")
          hpxml.header.sim_calendar_year = epw_file.startDateActualYear.get
          hpxml.header.sim_calendar_year_isdefaulted = true
        end
      else
        hpxml.header.sim_calendar_year = epw_file.startDateActualYear.get
        hpxml.header.sim_calendar_year_isdefaulted = true
      end
    else
      if hpxml.header.sim_calendar_year.nil?
        hpxml.header.sim_calendar_year = 2007 # For consistency with SAM utility bill calculations
        hpxml.header.sim_calendar_year_isdefaulted = true
      end
    end

    if hpxml.header.dst_enabled.nil?
      hpxml.header.dst_enabled = true # Assume DST since it occurs in most US locations
      hpxml.header.dst_enabled_isdefaulted = true
    end

    if hpxml.header.dst_enabled
      if hpxml.header.dst_begin_month.nil? || hpxml.header.dst_begin_day.nil? || hpxml.header.dst_end_month.nil? || hpxml.header.dst_end_day.nil?
        if epw_file.daylightSavingStartDate.is_initialized && epw_file.daylightSavingEndDate.is_initialized
          # Use weather file DST dates if available
          dst_start_date = epw_file.daylightSavingStartDate.get
          dst_end_date = epw_file.daylightSavingEndDate.get
          hpxml.header.dst_begin_month = dst_start_date.monthOfYear.value
          hpxml.header.dst_begin_day = dst_start_date.dayOfMonth
          hpxml.header.dst_end_month = dst_end_date.monthOfYear.value
          hpxml.header.dst_end_day = dst_end_date.dayOfMonth
        else
          # Roughly average US dates according to https://en.wikipedia.org/wiki/Daylight_saving_time_in_the_United_States
          hpxml.header.dst_begin_month = 3
          hpxml.header.dst_begin_day = 12
          hpxml.header.dst_end_month = 11
          hpxml.header.dst_end_day = 5
        end
        hpxml.header.dst_begin_month_isdefaulted = true
        hpxml.header.dst_begin_day_isdefaulted = true
        hpxml.header.dst_end_month_isdefaulted = true
        hpxml.header.dst_end_day_isdefaulted = true
      end
    end

    if hpxml.header.allow_increased_fixed_capacities.nil?
      hpxml.header.allow_increased_fixed_capacities = false
      hpxml.header.allow_increased_fixed_capacities_isdefaulted = true
    end
    if hpxml.header.use_max_load_for_heat_pumps.nil?
      hpxml.header.use_max_load_for_heat_pumps = true
      hpxml.header.use_max_load_for_heat_pumps_isdefaulted = true
    end
  end

  def self.apply_site(hpxml)
    if hpxml.site.site_type.nil?
      hpxml.site.site_type = HPXML::SiteTypeSuburban
      hpxml.site.site_type_isdefaulted = true
    end

    if hpxml.site.shelter_coefficient.nil?
      hpxml.site.shelter_coefficient = Airflow.get_default_shelter_coefficient()
      hpxml.site.shelter_coefficient_isdefaulted = true
    end
  end

  def self.apply_building_occupancy(hpxml, nbeds)
    if hpxml.building_occupancy.number_of_residents.nil?
      hpxml.building_occupancy.number_of_residents = Geometry.get_occupancy_default_num(nbeds)
      hpxml.building_occupancy.number_of_residents_isdefaulted = true
    end
  end

  def self.apply_building_construction(hpxml, cfa, nbeds)
    if hpxml.building_construction.conditioned_building_volume.nil? && hpxml.building_construction.average_ceiling_height.nil?
      hpxml.building_construction.average_ceiling_height = 8.0
      hpxml.building_construction.average_ceiling_height_isdefaulted = true
      hpxml.building_construction.conditioned_building_volume = cfa * hpxml.building_construction.average_ceiling_height
      hpxml.building_construction.conditioned_building_volume_isdefaulted = true
    elsif hpxml.building_construction.conditioned_building_volume.nil?
      hpxml.building_construction.conditioned_building_volume = cfa * hpxml.building_construction.average_ceiling_height
      hpxml.building_construction.conditioned_building_volume_isdefaulted = true
    elsif hpxml.building_construction.average_ceiling_height.nil?
      hpxml.building_construction.average_ceiling_height = hpxml.building_construction.conditioned_building_volume / cfa
      hpxml.building_construction.average_ceiling_height_isdefaulted = true
    end

    if hpxml.building_construction.number_of_bathrooms.nil?
      hpxml.building_construction.number_of_bathrooms = Float(Waterheater.get_default_num_bathrooms(nbeds)).to_i
      hpxml.building_construction.number_of_bathrooms_isdefaulted = true
    end

    if hpxml.building_construction.has_flue_or_chimney.nil?
      hpxml.building_construction.has_flue_or_chimney = false
      hpxml.building_construction.has_flue_or_chimney_isdefaulted = true
      hpxml.heating_systems.each do |heating_system|
        if [HPXML::HVACTypeFurnace, HPXML::HVACTypeBoiler, HPXML::HVACTypeWallFurnace, HPXML::HVACTypeFloorFurnace, HPXML::HVACTypeStove, HPXML::HVACTypeFixedHeater].include? heating_system.heating_system_type
          if not heating_system.heating_efficiency_afue.nil?
            next if heating_system.heating_efficiency_afue >= 0.89
          elsif not heating_system.heating_efficiency_percent.nil?
            next if heating_system.heating_efficiency_percent >= 0.89
          end

          hpxml.building_construction.has_flue_or_chimney = true
        elsif [HPXML::HVACTypeFireplace].include? heating_system.heating_system_type
          next if heating_system.heating_system_fuel == HPXML::FuelTypeElectricity

          hpxml.building_construction.has_flue_or_chimney = true
        end
      end
      hpxml.water_heating_systems.each do |water_heating_system|
        if not water_heating_system.energy_factor.nil?
          next if water_heating_system.energy_factor >= 0.63
        elsif not water_heating_system.uniform_energy_factor.nil?
          next if Waterheater.calc_ef_from_uef(water_heating_system) >= 0.63
        end

        hpxml.building_construction.has_flue_or_chimney = true
      end
    end
  end

  def self.apply_infiltration(hpxml)
    measurements = []
    infil_volume = nil
    hpxml.air_infiltration_measurements.each do |measurement|
      is_ach = ((measurement.unit_of_measure == HPXML::UnitsACH) && !measurement.house_pressure.nil?)
      is_cfm = ((measurement.unit_of_measure == HPXML::UnitsCFM) && !measurement.house_pressure.nil?)
      is_nach = (measurement.unit_of_measure == HPXML::UnitsACHNatural)
      next unless (is_ach || is_cfm || is_nach)

      measurements << measurement
      next if measurement.infiltration_volume.nil?

      infil_volume = measurement.infiltration_volume
    end
    if infil_volume.nil?
      infil_volume = hpxml.building_construction.conditioned_building_volume
      measurements.each do |measurement|
        measurement.infiltration_volume = infil_volume
        measurement.infiltration_volume_isdefaulted = true
      end
    end

    return infil_volume
  end

  def self.apply_attics(hpxml)
    return unless hpxml.has_space_type(HPXML::LocationAtticVented)

    vented_attic = nil
    hpxml.attics.each do |attic|
      next unless attic.attic_type == HPXML::AtticTypeVented

      vented_attic = attic
    end
    if vented_attic.nil?
      hpxml.attics.add(id: 'VentedAttic',
                       attic_type: HPXML::AtticTypeVented)
      vented_attic = hpxml.attics[-1]
    end
    if vented_attic.vented_attic_sla.nil? && vented_attic.vented_attic_ach.nil?
      vented_attic.vented_attic_sla = Airflow.get_default_vented_attic_sla()
      vented_attic.vented_attic_sla_isdefaulted = true
    end
  end

  def self.apply_foundations(hpxml)
    return unless hpxml.has_space_type(HPXML::LocationCrawlspaceVented)

    vented_crawl = nil
    hpxml.foundations.each do |foundation|
      next unless foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented

      vented_crawl = foundation
    end
    if vented_crawl.nil?
      hpxml.foundations.add(id: 'VentedCrawlspace',
                            foundation_type: HPXML::FoundationTypeCrawlspaceVented)
      vented_crawl = hpxml.foundations[-1]
    end
    if vented_crawl.vented_crawlspace_sla.nil?
      vented_crawl.vented_crawlspace_sla = Airflow.get_default_vented_crawl_sla()
      vented_crawl.vented_crawlspace_sla_isdefaulted = true
    end
  end

  def self.apply_roofs(hpxml)
    hpxml.roofs.each do |roof|
      if roof.roof_type.nil?
        roof.roof_type = HPXML::RoofTypeAsphaltShingles
        roof.roof_type_isdefaulted = true
      end
      if roof.emittance.nil?
        roof.emittance = 0.90
        roof.emittance_isdefaulted = true
      end
      if roof.radiant_barrier.nil?
        roof.radiant_barrier = false
        roof.radiant_barrier_isdefaulted = true
      end
      if roof.roof_color.nil?
        roof.roof_color = Constructions.get_default_roof_color(roof.roof_type, roof.solar_absorptance)
        roof.roof_color_isdefaulted = true
      elsif roof.solar_absorptance.nil?
        roof.solar_absorptance = Constructions.get_default_roof_solar_absorptance(roof.roof_type, roof.roof_color)
        roof.solar_absorptance_isdefaulted = true
      end
    end
  end

  def self.apply_rim_joists(hpxml)
    hpxml.rim_joists.each do |rim_joist|
      next unless rim_joist.is_exterior

      if rim_joist.emittance.nil?
        rim_joist.emittance = 0.90
        rim_joist.emittance_isdefaulted = true
      end
      if rim_joist.siding.nil?
        rim_joist.siding = HPXML::SidingTypeWood
        rim_joist.siding_isdefaulted = true
      end
      if rim_joist.color.nil?
        rim_joist.color = Constructions.get_default_wall_color(rim_joist.solar_absorptance)
        rim_joist.color_isdefaulted = true
      elsif rim_joist.solar_absorptance.nil?
        rim_joist.solar_absorptance = Constructions.get_default_wall_solar_absorptance(rim_joist.color)
        rim_joist.solar_absorptance_isdefaulted = true
      end
    end
  end

  def self.apply_walls(hpxml)
    hpxml.walls.each do |wall|
      next unless wall.is_exterior

      if wall.emittance.nil?
        wall.emittance = 0.90
        wall.emittance_isdefaulted = true
      end
      if wall.siding.nil?
        wall.siding = HPXML::SidingTypeWood
        wall.siding_isdefaulted = true
      end
      if wall.color.nil?
        wall.color = Constructions.get_default_wall_color(wall.solar_absorptance)
        wall.color_isdefaulted = true
      elsif wall.solar_absorptance.nil?
        wall.solar_absorptance = Constructions.get_default_wall_solar_absorptance(wall.color)
        wall.solar_absorptance_isdefaulted = true
      end
    end
  end

  def self.apply_foundation_walls(hpxml)
    hpxml.foundation_walls.each do |foundation_wall|
      if foundation_wall.thickness.nil?
        foundation_wall.thickness = 8.0
        foundation_wall.thickness_isdefaulted = true
      end
    end
  end

  def self.apply_slabs(hpxml)
    hpxml.slabs.each do |slab|
      if slab.thickness.nil?
        crawl_slab = [HPXML::LocationCrawlspaceVented, HPXML::LocationCrawlspaceUnvented].include?(slab.interior_adjacent_to)
        slab.thickness = crawl_slab ? 0.0 : 4.0
        slab.thickness_isdefaulted = true
      end
      conditioned_slab = [HPXML::LocationLivingSpace,
                          HPXML::LocationBasementConditioned].include?(slab.interior_adjacent_to)
      if slab.carpet_r_value.nil?
        slab.carpet_r_value = conditioned_slab ? 2.0 : 0.0
        slab.carpet_r_value_isdefaulted = true
      end
      if slab.carpet_fraction.nil?
        slab.carpet_fraction = conditioned_slab ? 0.8 : 0.0
        slab.carpet_fraction_isdefaulted = true
      end
    end
  end

  def self.apply_windows(hpxml)
    default_shade_summer, default_shade_winter = Constructions.get_default_interior_shading_factors()
    hpxml.windows.each do |window|
      if window.interior_shading_factor_summer.nil?
        window.interior_shading_factor_summer = default_shade_summer
        window.interior_shading_factor_summer_isdefaulted = true
      end
      if window.interior_shading_factor_winter.nil?
        window.interior_shading_factor_winter = default_shade_winter
        window.interior_shading_factor_winter_isdefaulted = true
      end
      if window.exterior_shading_factor_summer.nil?
        window.exterior_shading_factor_summer = 1.0
        window.exterior_shading_factor_summer_isdefaulted = true
      end
      if window.exterior_shading_factor_winter.nil?
        window.exterior_shading_factor_winter = 1.0
        window.exterior_shading_factor_winter_isdefaulted = true
      end
      if window.fraction_operable.nil?
        window.fraction_operable = Airflow.get_default_fraction_of_windows_operable()
        window.fraction_operable_isdefaulted = true
      end
    end
  end

  def self.apply_skylights(hpxml)
    hpxml.skylights.each do |skylight|
      if skylight.interior_shading_factor_summer.nil?
        skylight.interior_shading_factor_summer = 1.0
        skylight.interior_shading_factor_summer_isdefaulted = true
      end
      if skylight.interior_shading_factor_winter.nil?
        skylight.interior_shading_factor_winter = 1.0
        skylight.interior_shading_factor_winter_isdefaulted = true
      end
      if skylight.exterior_shading_factor_summer.nil?
        skylight.exterior_shading_factor_summer = 1.0
        skylight.exterior_shading_factor_summer_isdefaulted = true
      end
      if skylight.exterior_shading_factor_winter.nil?
        skylight.exterior_shading_factor_winter = 1.0
        skylight.exterior_shading_factor_winter_isdefaulted = true
      end
    end
  end

  def self.apply_hvac(hpxml, weather)
    # Default AC/HP compressor type
    hpxml.cooling_systems.each do |cooling_system|
      next unless cooling_system.compressor_type.nil?

      cooling_system.compressor_type = HVAC.get_default_compressor_type(cooling_system.cooling_system_type, cooling_system.cooling_efficiency_seer)
      cooling_system.compressor_type_isdefaulted = true
    end
    hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.compressor_type.nil?

      heat_pump.compressor_type = HVAC.get_default_compressor_type(heat_pump.heat_pump_type, heat_pump.cooling_efficiency_seer)
      heat_pump.compressor_type_isdefaulted = true
    end

    # Default boiler EAE
    hpxml.heating_systems.each do |heating_system|
      if heating_system.electric_auxiliary_energy.nil?
        heating_system.electric_auxiliary_energy_isdefaulted = true
        heating_system.electric_auxiliary_energy = HVAC.get_default_boiler_eae(heating_system)
      end
    end

    # Default AC/HP sensible heat ratio
    hpxml.cooling_systems.each do |cooling_system|
      next unless cooling_system.cooling_shr.nil?

      if cooling_system.cooling_system_type == HPXML::HVACTypeCentralAirConditioner
        if cooling_system.compressor_type == HPXML::HVACCompressorTypeSingleStage
          cooling_system.cooling_shr = 0.73
        elsif cooling_system.compressor_type == HPXML::HVACCompressorTypeTwoStage
          cooling_system.cooling_shr = 0.73
        elsif cooling_system.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
          cooling_system.cooling_shr = 0.78
        end
        cooling_system.cooling_shr_isdefaulted = true
      elsif cooling_system.cooling_system_type == HPXML::HVACTypeRoomAirConditioner
        cooling_system.cooling_shr = 0.65
        cooling_system.cooling_shr_isdefaulted = true
      elsif cooling_system.cooling_system_type == HPXML::HVACTypeMiniSplitAirConditioner
        cooling_system.cooling_shr = 0.73
        cooling_system.cooling_shr_isdefaulted = true
      end
    end
    hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.cooling_shr.nil?

      if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir
        if heat_pump.compressor_type == HPXML::HVACCompressorTypeSingleStage
          heat_pump.cooling_shr = 0.73
        elsif heat_pump.compressor_type == HPXML::HVACCompressorTypeTwoStage
          heat_pump.cooling_shr = 0.724
        elsif heat_pump.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
          heat_pump.cooling_shr = 0.78
        end
        heat_pump.cooling_shr_isdefaulted = true
      elsif heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpMiniSplit
        heat_pump.cooling_shr = 0.73
        heat_pump.cooling_shr_isdefaulted = true
      elsif heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
        heat_pump.cooling_shr = 0.732
        heat_pump.cooling_shr_isdefaulted = true
      end
    end

    # GSHP pump power
    hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
      next unless heat_pump.pump_watts_per_ton.nil?

      heat_pump.pump_watts_per_ton = HVAC.get_default_gshp_pump_power()
      heat_pump.pump_watts_per_ton_isdefaulted = true
    end

    # Charge defect ratio
    hpxml.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner,
                   HPXML::HVACTypeRoomAirConditioner].include? cooling_system.cooling_system_type
      next unless cooling_system.charge_defect_ratio.nil?

      cooling_system.charge_defect_ratio = 0.0
      cooling_system.charge_defect_ratio_isdefaulted = true
    end
    hpxml.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type
      next unless heat_pump.charge_defect_ratio.nil?

      heat_pump.charge_defect_ratio = 0.0
      heat_pump.charge_defect_ratio_isdefaulted = true
    end

    # Airflow defect ratio
    hpxml.heating_systems.each do |heating_system|
      next unless [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type
      next unless heating_system.airflow_defect_ratio.nil?

      heating_system.airflow_defect_ratio = 0.0
      heating_system.airflow_defect_ratio_isdefaulted = true
    end
    hpxml.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner,
                   HPXML::HVACTypeRoomAirConditioner].include? cooling_system.cooling_system_type
      if cooling_system.cooling_system_type == HPXML::HVACTypeMiniSplitAirConditioner && cooling_system.distribution_system_idref.nil?
        next # Ducted mini-splits only
      end
      next unless cooling_system.airflow_defect_ratio.nil?

      cooling_system.airflow_defect_ratio = 0.0
      cooling_system.airflow_defect_ratio_isdefaulted = true
    end
    hpxml.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpGroundToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type
      if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpMiniSplit && heat_pump.distribution_system_idref.nil?
        next # Ducted mini-splits only
      end
      next unless heat_pump.airflow_defect_ratio.nil?

      heat_pump.airflow_defect_ratio = 0.0
      heat_pump.airflow_defect_ratio_isdefaulted = true
    end

    # Fan power
    psc_watts_per_cfm = 0.5 # W/cfm, PSC fan
    ecm_watts_per_cfm = 0.375 # W/cfm, ECM fan
    mini_split_ducted_watts_per_cfm = 0.18 # W/cfm, ducted mini split
    hpxml.heating_systems.each do |heating_system|
      if [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type
        if heating_system.fan_watts_per_cfm.nil?
          if heating_system.heating_efficiency_afue > 0.9 # HEScore assumption
            heating_system.fan_watts_per_cfm = ecm_watts_per_cfm
          else
            heating_system.fan_watts_per_cfm = psc_watts_per_cfm
          end
          heating_system.fan_watts_per_cfm_isdefaulted = true
        end
      elsif [HPXML::HVACTypeStove].include? heating_system.heating_system_type
        if heating_system.fan_watts.nil?
          heating_system.fan_watts = 40.0 # W
          heating_system.fan_watts_isdefaulted = true
        end
      elsif [HPXML::HVACTypeWallFurnace,
             HPXML::HVACTypeFloorFurnace,
             HPXML::HVACTypePortableHeater,
             HPXML::HVACTypeFixedHeater,
             HPXML::HVACTypeFireplace].include? heating_system.heating_system_type
        if heating_system.fan_watts.nil?
          heating_system.fan_watts = 0.0 # W/cfm, assume no fan power
          heating_system.fan_watts_isdefaulted = true
        end
      end
    end
    hpxml.cooling_systems.each do |cooling_system|
      next unless cooling_system.fan_watts_per_cfm.nil?

      if (not cooling_system.attached_heating_system.nil?) && (not cooling_system.attached_heating_system.fan_watts_per_cfm.nil?)
        cooling_system.fan_watts_per_cfm = cooling_system.attached_heating_system.fan_watts_per_cfm
        cooling_system.fan_watts_per_cfm_isdefaulted = true
      elsif [HPXML::HVACTypeCentralAirConditioner].include? cooling_system.cooling_system_type
        if cooling_system.cooling_efficiency_seer > 13.5 # HEScore assumption
          cooling_system.fan_watts_per_cfm = ecm_watts_per_cfm
        else
          cooling_system.fan_watts_per_cfm = psc_watts_per_cfm
        end
        cooling_system.fan_watts_per_cfm_isdefaulted = true
      elsif [HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type
        if not cooling_system.distribution_system.nil?
          cooling_system.fan_watts_per_cfm = mini_split_ducted_watts_per_cfm
        end
        cooling_system.fan_watts_per_cfm_isdefaulted = true
      elsif [HPXML::HVACTypeEvaporativeCooler].include? cooling_system.cooling_system_type
        # Depends on airflow rate, so defaulted in hvac_sizing.rb
      end
    end
    hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.fan_watts_per_cfm.nil?

      if [HPXML::HVACTypeHeatPumpAirToAir].include? heat_pump.heat_pump_type
        if heat_pump.heating_efficiency_hspf > 8.75 # HEScore assumption
          heat_pump.fan_watts_per_cfm = ecm_watts_per_cfm
        else
          heat_pump.fan_watts_per_cfm = psc_watts_per_cfm
        end
        heat_pump.fan_watts_per_cfm_isdefaulted = true
      elsif [HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type
        if heat_pump.heating_efficiency_cop > 8.75 / 3.2 # HEScore assumption
          heat_pump.fan_watts_per_cfm = ecm_watts_per_cfm
        else
          heat_pump.fan_watts_per_cfm = psc_watts_per_cfm
        end
        heat_pump.fan_watts_per_cfm_isdefaulted = true
      elsif [HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type
        if not heat_pump.distribution_system.nil?
          heat_pump.fan_watts_per_cfm = mini_split_ducted_watts_per_cfm
        end
        heat_pump.fan_watts_per_cfm_isdefaulted = true
      end
    end

    # HVAC capacities
    # Transition capacity elements from -1 (old approach) to nil (new approach)
    hpxml.heating_systems.each do |heating_system|
      if (not heating_system.heating_capacity.nil?) && (heating_system.heating_capacity < 0)
        heating_system.heating_capacity = nil
      end
    end
    hpxml.cooling_systems.each do |cooling_system|
      if (not cooling_system.cooling_capacity.nil?) && (cooling_system.cooling_capacity < 0)
        cooling_system.cooling_capacity = nil
      end
    end
    hpxml.heat_pumps.each do |heat_pump|
      if (not heat_pump.cooling_capacity.nil?) && (heat_pump.cooling_capacity < 0)
        heat_pump.cooling_capacity = nil
      end
      if (not heat_pump.heating_capacity.nil?) && (heat_pump.heating_capacity < 0)
        heat_pump.heating_capacity = nil
      end
      if (not heat_pump.heating_capacity_17F.nil?) && (heat_pump.heating_capacity_17F < 0)
        heat_pump.heating_capacity_17F = nil
      end
      if (not heat_pump.backup_heating_capacity.nil?) && (heat_pump.backup_heating_capacity < 0)
        heat_pump.backup_heating_capacity = nil
      end
      if heat_pump.cooling_capacity.nil? && (not heat_pump.heating_capacity.nil?)
        heat_pump.cooling_capacity = heat_pump.heating_capacity
      elsif heat_pump.heating_capacity.nil? && (not heat_pump.cooling_capacity.nil?)
        heat_pump.heating_capacity = heat_pump.cooling_capacity
      end
    end

    # Performance curves, etc.
    hpxml.cooling_systems.each do |cooling_system|
      clg_ap = cooling_system.additional_properties
      if [HPXML::HVACTypeCentralAirConditioner].include? cooling_system.cooling_system_type
        # Note: We use HP cooling curve so that a central AC behaves the same, per
        # discussion within RESNET Software Consistency Committee.
        clg_ap.num_speeds = HVAC.get_num_speeds_from_compressor_type(cooling_system.compressor_type)
        clg_ap.fan_power_rated = HVAC.get_fan_power_rated(cooling_system.cooling_efficiency_seer)
        clg_ap.crankcase_kw, clg_ap.crankcase_temp = HVAC.get_crankcase_assumptions(cooling_system.fraction_cool_load_served)

        clg_ap.cool_c_d = HVAC.get_cool_c_d(clg_ap.num_speeds, cooling_system.cooling_efficiency_seer)
        clg_ap.cool_rated_airflow_rate, clg_ap.cool_fan_speed_ratios, clg_ap.cool_capacity_ratios, clg_ap.shrs, clg_ap.eers, clg_ap.cool_cap_ft_spec, clg_ap.cool_eir_ft_spec, clg_ap.cool_cap_fflow_spec, clg_ap.cool_eir_fflow_spec = HVAC.get_hp_clg_curves(cooling_system)
        clg_ap.cool_rated_cfm_per_ton = HVAC.calc_cfms_ton_rated(clg_ap.cool_rated_airflow_rate, clg_ap.cool_fan_speed_ratios, clg_ap.cool_capacity_ratios)
        clg_ap.cool_shrs_rated_gross = HVAC.calc_shrs_rated_gross(clg_ap.num_speeds, clg_ap.shrs, clg_ap.fan_power_rated, clg_ap.cool_rated_cfm_per_ton)
        clg_ap.cool_rated_eirs = HVAC.calc_cool_rated_eirs(clg_ap.num_speeds, clg_ap.eers, clg_ap.fan_power_rated)
        clg_ap.cool_closs_fplr_spec = [HVAC.calc_plr_coefficients(clg_ap.cool_c_d)] * clg_ap.num_speeds
      elsif [HPXML::HVACTypeRoomAirConditioner].include? cooling_system.cooling_system_type
        # FUTURE: Move values into hvac.rb
        # From Frigidaire 10.7 EER unit in Winkler et. al. Lab Testing of Window ACs (2013)
        clg_ap.cool_shrs_rated_gross = [cooling_system.cooling_shr]
        clg_ap.cool_cap_ft_spec = [[0.43945980246913574, -0.0008922469135802481, 0.00013984567901234569, 0.0038489259259259253, -5.6327160493827156e-05, 2.041358024691358e-05]]
        clg_ap.cool_eir_ft_spec = [[6.310506172839506, -0.17705185185185185, 0.0014645061728395061, 0.012571604938271608, 0.0001493827160493827, -0.00040308641975308644]]
        clg_ap.cool_cap_fflow_spec = [[0.887, 0.1128, 0]]
        clg_ap.cool_eir_fflow_spec = [[1.763, -0.6081, 0]]
        clg_ap.cool_plf_fplr = [[0.78, 0.22, 0]]
        clg_ap.cool_rated_cfm_per_ton = [312.0] # cfm/ton, medium speed
      elsif [HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type
        # FUTURE: Move some of this code into hvac.rb; combine w/ MSHP
        num_speeds = 10
        clg_ap.speed_indices = [1, 3, 5, 9]
        clg_ap.num_speeds = clg_ap.speed_indices.size # Number of speeds we model
        clg_ap.crankcase_kw, clg_ap.crankcase_temp = 0, nil
        if not cooling_system.distribution_system.nil?
          # Ducted, installed fan power may differ from rated fan power
          clg_ap.fan_power_rated = 0.18 # W/cfm, ducted
        else
          # Ductless, installed and rated value should be equal
          clg_ap.fan_power_rated = 0.07 # W/cfm
          cooling_system.fan_watts_per_cfm = clg_ap.fan_power_rated # W/cfm
        end

        min_cooling_capacity = 0.4 # frac
        max_cooling_capacity = 1.2 # frac
        min_cooling_airflow_rate = 200.0
        max_cooling_airflow_rate = 425.0

        clg_ap.cool_cap_ft_spec = [[0.7531983499655835, 0.003618193903031667, 0.0, 0.006574385031351544, -6.87181191015432e-05, 0.0]] * num_speeds
        clg_ap.cool_eir_ft_spec = [[-0.06376924779982301, -0.0013360593470367282, 1.413060577993827e-05, 0.019433076486584752, -4.91395947154321e-05, -4.909341249475308e-05]] * num_speeds
        clg_ap.cool_cap_fflow_spec = [[1, 0, 0]] * num_speeds
        clg_ap.cool_eir_fflow_spec = [[1, 0, 0]] * num_speeds
        clg_ap.cool_c_d = HVAC.get_cool_c_d(num_speeds, cooling_system.cooling_efficiency_seer)
        clg_ap.cool_closs_fplr_spec = [HVAC.calc_plr_coefficients(clg_ap.cool_c_d)] * num_speeds
        clg_ap.cool_rated_cfm_per_ton, clg_ap.cool_capacity_ratios, clg_ap.cool_shrs_rated_gross = HVAC.calc_mshp_cfms_ton_cooling(min_cooling_capacity, max_cooling_capacity, min_cooling_airflow_rate, max_cooling_airflow_rate, num_speeds, cooling_system.cooling_shr)
        clg_ap.cool_rated_eirs = HVAC.calc_mshp_cool_rated_eirs(cooling_system.cooling_efficiency_seer, clg_ap.fan_power_rated, clg_ap.cool_c_d, num_speeds, clg_ap.cool_capacity_ratios, clg_ap.cool_rated_cfm_per_ton, clg_ap.cool_eir_ft_spec, clg_ap.cool_cap_ft_spec)

        # Down-select to speed indices
        clg_ap.cool_cap_ft_spec = clg_ap.cool_cap_ft_spec.select.with_index { |x, i| clg_ap.speed_indices.include? i }
        clg_ap.cool_eir_ft_spec = clg_ap.cool_eir_ft_spec.select.with_index { |x, i| clg_ap.speed_indices.include? i }
        clg_ap.cool_cap_fflow_spec = clg_ap.cool_cap_fflow_spec.select.with_index { |x, i| clg_ap.speed_indices.include? i }
        clg_ap.cool_eir_fflow_spec = clg_ap.cool_eir_fflow_spec.select.with_index { |x, i| clg_ap.speed_indices.include? i }
        clg_ap.cool_closs_fplr_spec = clg_ap.cool_closs_fplr_spec.select.with_index { |x, i| clg_ap.speed_indices.include? i }
        clg_ap.cool_rated_cfm_per_ton = clg_ap.cool_rated_cfm_per_ton.select.with_index { |x, i| clg_ap.speed_indices.include? i }
        clg_ap.cool_capacity_ratios = clg_ap.cool_capacity_ratios.select.with_index { |x, i| clg_ap.speed_indices.include? i }
        clg_ap.cool_shrs_rated_gross = clg_ap.cool_shrs_rated_gross.select.with_index { |x, i| clg_ap.speed_indices.include? i }
        clg_ap.cool_rated_eirs = clg_ap.cool_rated_eirs.select.with_index { |x, i| clg_ap.speed_indices.include? i }
        clg_ap.cool_fan_speed_ratios = []
        for i in 0..(clg_ap.speed_indices.size - 1)
          clg_ap.cool_fan_speed_ratios << clg_ap.cool_rated_cfm_per_ton[i] / clg_ap.cool_rated_cfm_per_ton[-1]
        end
      elsif [HPXML::HVACTypeEvaporativeCooler].include? cooling_system.cooling_system_type
        clg_ap.effectiveness = 0.72 # Assumption from HEScore
      end
    end
    hpxml.heating_systems.each do |heating_system|
      htg_ap = heating_system.additional_properties
      next unless [HPXML::HVACTypeStove,
                   HPXML::HVACTypePortableHeater,
                   HPXML::HVACTypeFixedHeater,
                   HPXML::HVACTypeWallFurnace,
                   HPXML::HVACTypeFloorFurnace,
                   HPXML::HVACTypeFireplace].include? heating_system.heating_system_type
      htg_ap.heat_rated_cfm_per_ton = [350.0]
    end
    hpxml.heat_pumps.each do |heat_pump|
      hp_ap = heat_pump.additional_properties
      if [HPXML::HVACTypeHeatPumpAirToAir].include? heat_pump.heat_pump_type
        hp_ap.num_speeds = HVAC.get_num_speeds_from_compressor_type(heat_pump.compressor_type)
        hp_ap.fan_power_rated = HVAC.get_fan_power_rated(heat_pump.cooling_efficiency_seer)
        if heat_pump.fraction_heat_load_served <= 0
          hp_ap.crankcase_kw, hp_ap.crankcase_temp = 0, nil
        else
          hp_ap.crankcase_kw, hp_ap.crankcase_temp = HVAC.get_crankcase_assumptions(heat_pump.fraction_cool_load_served)
        end
        hp_ap.hp_min_temp, hp_ap.supp_max_temp = HVAC.get_heat_pump_temp_assumptions(heat_pump)

        hp_ap.cool_c_d = HVAC.get_cool_c_d(hp_ap.num_speeds, heat_pump.cooling_efficiency_seer)
        hp_ap.cool_rated_airflow_rate, hp_ap.cool_fan_speed_ratios, hp_ap.cool_capacity_ratios, hp_ap.cool_shrs, hp_ap.cool_eers, hp_ap.cool_cap_ft_spec, hp_ap.cool_eir_ft_spec, hp_ap.cool_cap_fflow_spec, hp_ap.cool_eir_fflow_spec = HVAC.get_hp_clg_curves(heat_pump)
        hp_ap.cool_rated_cfm_per_ton = HVAC.calc_cfms_ton_rated(hp_ap.cool_rated_airflow_rate, hp_ap.cool_fan_speed_ratios, hp_ap.cool_capacity_ratios)
        hp_ap.cool_shrs_rated_gross = HVAC.calc_shrs_rated_gross(hp_ap.num_speeds, hp_ap.cool_shrs, hp_ap.fan_power_rated, hp_ap.cool_rated_cfm_per_ton)
        hp_ap.cool_rated_eirs = HVAC.calc_cool_rated_eirs(hp_ap.num_speeds, hp_ap.cool_eers, hp_ap.fan_power_rated)
        hp_ap.cool_closs_fplr_spec = [HVAC.calc_plr_coefficients(hp_ap.cool_c_d)] * hp_ap.num_speeds

        hp_ap.heat_c_d = HVAC.get_heat_c_d(hp_ap.num_speeds, heat_pump.heating_efficiency_hspf)
        hp_ap.heat_rated_airflow_rate, hp_ap.heat_fan_speed_ratios, hp_ap.heat_capacity_ratios, hp_ap.heat_cops, hp_ap.heat_cap_ft_spec, hp_ap.heat_eir_ft_spec, hp_ap.heat_cap_fflow_spec, hp_ap.heat_eir_fflow_spec = HVAC.get_hp_htg_curves(heat_pump)
        hp_ap.heat_rated_cfm_per_ton = HVAC.calc_cfms_ton_rated(hp_ap.heat_rated_airflow_rate, hp_ap.heat_fan_speed_ratios, hp_ap.heat_capacity_ratios)
        hp_ap.heat_rated_eirs = HVAC.calc_heat_rated_eirs(hp_ap.num_speeds, hp_ap.heat_cops, hp_ap.fan_power_rated)
        hp_ap.heat_closs_fplr_spec = [HVAC.calc_plr_coefficients(hp_ap.heat_c_d)] * hp_ap.num_speeds
      elsif [HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type
        # FUTURE: Move some of this code into hvac.rb; combine w/ MSAC
        num_speeds = 10
        hp_ap.speed_indices = [1, 3, 5, 9]
        hp_ap.num_speeds = hp_ap.speed_indices.size # Number of speeds we model
        hp_ap.crankcase_kw, hp_ap.crankcase_temp = 0, nil
        if not heat_pump.distribution_system.nil?
          # Ducted, installed fan power may differ from rated fan power
          hp_ap.fan_power_rated = 0.18 # W/cfm, ducted
        else
          # Ductless, installed and rated value should be equal
          hp_ap.fan_power_rated = 0.07 # W/cfm
          heat_pump.fan_watts_per_cfm = hp_ap.fan_power_rated # W/cfm
        end
        hp_ap.hp_min_temp, hp_ap.supp_max_temp = HVAC.get_heat_pump_temp_assumptions(heat_pump)

        min_cooling_capacity = 0.4 # frac
        max_cooling_capacity = 1.2 # frac
        min_cooling_airflow_rate = 200.0
        max_cooling_airflow_rate = 425.0

        hp_ap.cool_cap_ft_spec = [[0.7531983499655835, 0.003618193903031667, 0.0, 0.006574385031351544, -6.87181191015432e-05, 0.0]] * num_speeds
        hp_ap.cool_eir_ft_spec = [[-0.06376924779982301, -0.0013360593470367282, 1.413060577993827e-05, 0.019433076486584752, -4.91395947154321e-05, -4.909341249475308e-05]] * num_speeds
        hp_ap.cool_cap_fflow_spec = [[1, 0, 0]] * num_speeds
        hp_ap.cool_eir_fflow_spec = [[1, 0, 0]] * num_speeds
        hp_ap.cool_c_d = HVAC.get_cool_c_d(num_speeds, heat_pump.cooling_efficiency_seer)
        hp_ap.cool_closs_fplr_spec = [HVAC.calc_plr_coefficients(hp_ap.cool_c_d)] * num_speeds
        hp_ap.cool_rated_cfm_per_ton, hp_ap.cool_capacity_ratios, hp_ap.cool_shrs_rated_gross = HVAC.calc_mshp_cfms_ton_cooling(min_cooling_capacity, max_cooling_capacity, min_cooling_airflow_rate, max_cooling_airflow_rate, num_speeds, heat_pump.cooling_shr)
        hp_ap.cool_rated_eirs = HVAC.calc_mshp_cool_rated_eirs(heat_pump.cooling_efficiency_seer, hp_ap.fan_power_rated, hp_ap.cool_c_d, num_speeds, hp_ap.cool_capacity_ratios, hp_ap.cool_rated_cfm_per_ton, hp_ap.cool_eir_ft_spec, hp_ap.cool_cap_ft_spec)

        # Down-select to speed indices
        hp_ap.cool_cap_ft_spec = hp_ap.cool_cap_ft_spec.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.cool_eir_ft_spec = hp_ap.cool_eir_ft_spec.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.cool_cap_fflow_spec = hp_ap.cool_cap_fflow_spec.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.cool_eir_fflow_spec = hp_ap.cool_eir_fflow_spec.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.cool_closs_fplr_spec = hp_ap.cool_closs_fplr_spec.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.cool_rated_cfm_per_ton = hp_ap.cool_rated_cfm_per_ton.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.cool_capacity_ratios = hp_ap.cool_capacity_ratios.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.cool_shrs_rated_gross = hp_ap.cool_shrs_rated_gross.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.cool_rated_eirs = hp_ap.cool_rated_eirs.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.cool_fan_speed_ratios = []
        for i in 0..(hp_ap.speed_indices.size - 1)
          hp_ap.cool_fan_speed_ratios << hp_ap.cool_rated_cfm_per_ton[i] / hp_ap.cool_rated_cfm_per_ton[-1]
        end

        min_heating_capacity = 0.3 # frac
        max_heating_capacity = 1.2 # frac
        min_heating_airflow_rate = 200.0
        max_heating_airflow_rate = 400.0

        # COP/EIR as a function of temperature
        # Generic curves (=Daikin from lab data)
        hp_ap.heat_eir_ft_spec = [[0.9999941697687026, 0.004684593830254383, 5.901286675833333e-05, -0.0028624467783091973, 1.3041120194135802e-05, -0.00016172918478765433]] * num_speeds
        hp_ap.heat_cap_fflow_spec = [[1, 0, 0]] * num_speeds
        hp_ap.heat_eir_fflow_spec = [[1, 0, 0]] * num_speeds

        # Derive coefficients from user input for capacity retention at outdoor drybulb temperature X [C].
        if heat_pump.heating_capacity_17F.nil? || ((heat_pump.heating_capacity_17F == 0) && (heat_pump.heating_capacity == 0))
          cap_retention_frac = 0.25 # frac
          cap_retention_temp = -5.0 # deg-F
        else
          cap_retention_frac = heat_pump.heating_capacity_17F / heat_pump.heating_capacity
          cap_retention_temp = 17.0 # deg-F
        end

        # Biquadratic: capacity multiplier = a + b*IAT + c*IAT^2 + d*OAT + e*OAT^2 + f*IAT*OAT
        x_A = UnitConversions.convert(cap_retention_temp, 'F', 'C')
        y_A = cap_retention_frac
        x_B = UnitConversions.convert(47.0, 'F', 'C') # 47F is the rating point
        y_B = 1.0 # Maximum capacity factor is 1 at the rating point, by definition (this is maximum capacity, not nominal capacity)
        oat_slope = (y_B - y_A) / (x_B - x_A)
        oat_intercept = y_A - (x_A * oat_slope)

        # Coefficients for the indoor temperature relationship are retained from the generic curve (Daikin lab data).
        iat_slope = -0.010386676170938
        iat_intercept = 0.219274275
        a = oat_intercept + iat_intercept
        b = iat_slope
        c = 0
        d = oat_slope
        e = 0
        f = 0
        hp_ap.heat_cap_ft_spec = [HVAC.convert_curve_biquadratic([a, b, c, d, e, f], false)] * num_speeds

        hp_ap.heat_c_d = HVAC.get_heat_c_d(num_speeds, heat_pump.heating_efficiency_hspf)
        hp_ap.heat_closs_fplr_spec = [HVAC.calc_plr_coefficients(hp_ap.heat_c_d)] * num_speeds
        hp_ap.heat_rated_cfm_per_ton, hp_ap.heat_capacity_ratios = HVAC.calc_mshp_cfms_ton_heating(min_heating_capacity, max_heating_capacity, min_heating_airflow_rate, max_heating_airflow_rate, num_speeds)
        hp_ap.heat_rated_eirs = HVAC.calc_mshp_heat_rated_eirs(heat_pump.heating_efficiency_hspf, hp_ap.fan_power_rated, hp_ap.hp_min_temp, hp_ap.heat_c_d, hp_ap.heat_rated_cfm_per_ton, num_speeds, hp_ap.heat_capacity_ratios, hp_ap.heat_rated_cfm_per_ton, hp_ap.heat_eir_ft_spec, hp_ap.heat_cap_ft_spec)

        # Down-select to speed indices
        hp_ap.heat_eir_ft_spec = hp_ap.heat_eir_ft_spec.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.heat_cap_fflow_spec = hp_ap.heat_cap_fflow_spec.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.heat_eir_fflow_spec = hp_ap.heat_eir_fflow_spec.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.heat_cap_ft_spec = hp_ap.heat_cap_ft_spec.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.heat_closs_fplr_spec = hp_ap.heat_closs_fplr_spec.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.heat_rated_cfm_per_ton = hp_ap.heat_rated_cfm_per_ton.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.heat_capacity_ratios = hp_ap.heat_capacity_ratios.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.heat_rated_eirs = hp_ap.heat_rated_eirs.select.with_index { |x, i| hp_ap.speed_indices.include? i }
        hp_ap.heat_fan_speed_ratios = []
        for i in 0..(hp_ap.speed_indices.size - 1)
          hp_ap.heat_fan_speed_ratios << hp_ap.heat_rated_cfm_per_ton[i] / hp_ap.heat_rated_cfm_per_ton[-1]
        end
      elsif [HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type
        hp_ap.design_chw = [85.0, weather.design.CoolingDrybulb - 15.0, weather.data.AnnualAvgDrybulb + 10.0].max # Temperature of water entering indoor coil,use 85F as lower bound
        hp_ap.design_delta_t = 10.0
        hp_ap.fluid_type = Constants.FluidPropyleneGlycol
        hp_ap.frac_glycol = 0.3
        if hp_ap.fluid_type == Constants.FluidWater
          hp_ap.design_hw = [45.0, weather.design.HeatingDrybulb + 35.0, weather.data.AnnualAvgDrybulb - 10.0].max # Temperature of fluid entering indoor coil, use 45F as lower bound for water
        else
          hp_ap.design_hw = [35.0, weather.design.HeatingDrybulb + 35.0, weather.data.AnnualAvgDrybulb - 10.0].min # Temperature of fluid entering indoor coil, use 35F as upper bound
        end
        hp_ap.ground_conductivity = 0.6 # Btu/h-ft-R
        hp_ap.ground_diffusivity = 0.0208
        hp_ap.grout_conductivity = 0.4 # Btu/h-ft-R
        hp_ap.bore_diameter = 5.0 # in
        hp_ap.pipe_size = 0.75 # in
        # Pipe nominal size conversion to pipe outside diameter and inside diameter,
        # only pipe sizes <= 2" are used here with DR11 (dimension ratio),
        if hp_ap.pipe_size == 0.75 # 3/4" pipe
          hp_ap.pipe_od = 1.050 # in
          hp_ap.pipe_id = 0.859 # in
        elsif hp_ap.pipe_size == 1.0 # 1" pipe
          hp_ap.pipe_od = 1.315 # in
          hp_ap.pipe_id = 1.076 # in
        elsif hp_ap.pipe_size == 1.25 # 1-1/4" pipe
          hp_ap.pipe_od = 1.660 # in
          hp_ap.pipe_id = 1.358 # in
        end
        hp_ap.pipe_cond = 0.23 # Btu/h-ft-R; Pipe thermal conductivity, default to high density polyethylene
        hp_ap.u_tube_spacing_type = 'b'
        # Calculate distance between pipes
        if hp_ap.u_tube_spacing_type == 'as'
          # Two tubes, spaced 1/8” apart at the center of the borehole
          hp_ap.u_tube_spacing = 0.125
        elsif hp_ap.u_tube_spacing_type == 'b'
          # Two tubes equally spaced between the borehole edges
          hp_ap.u_tube_spacing = 0.9661
        elsif hp_ap.u_tube_spacing_type == 'c'
          # Both tubes placed against outer edge of borehole
          hp_ap.u_tube_spacing = hp_ap.bore_diameter - 2 * hp_ap.pipe_od
        end
        hp_ap.shank_spacing = hp_ap.u_tube_spacing + hp_ap.pipe_od # Distance from center of pipe to center of pipe

        # E+ equation fit coil coefficients from Tang's thesis:
        # See Appendix B of  https://hvac.okstate.edu/sites/default/files/pubs/theses/MS/27-Tang_Thesis_05.pdf
        # Coefficients generated by catalog data
        hp_ap.cool_cap_ft_spec = [[-1.27373428, 3.73053580, -1.75023168, 0.04789060, 0.015777882]]
        hp_ap.cool_power_ft_spec = [[-7.66308745, 1.13961086, 7.57407956, 0.30151440, -0.091186547]]
        hp_ap.cool_sh_ft_spec = [[4.27615968, 13.90195633, -17.28090511, -0.70050924, 0.51366014, 0.017194205]]
        hp_ap.cool_shrs_rated_gross = [heat_pump.cooling_shr]
        # FUTURE: Reconcile these fan/pump adjustments with ANSI/RESNET/ICC 301-2019 Section 4.4.5
        fan_adjust_kw = UnitConversions.convert(400.0, 'Btu/hr', 'ton') * UnitConversions.convert(1.0, 'cfm', 'm^3/s') * 1000.0 * 0.35 * 249.0 / 300.0 # Adjustment per ISO 13256-1 Internal pressure drop across heat pump assumed to be 0.5 in. w.g.
        pump_adjust_kw = UnitConversions.convert(3.0, 'Btu/hr', 'ton') * UnitConversions.convert(1.0, 'gal/min', 'm^3/s') * 1000.0 * 6.0 * 2990.0 / 3000.0 # Adjustment per ISO 13256-1 Internal Pressure drop across heat pump coil assumed to be 11ft w.g.
        cool_eir = UnitConversions.convert((1.0 - heat_pump.cooling_efficiency_eer * (fan_adjust_kw + pump_adjust_kw)) / (heat_pump.cooling_efficiency_eer * (1.0 + UnitConversions.convert(fan_adjust_kw, 'Wh', 'Btu'))), 'Wh', 'Btu')
        hp_ap.cool_rated_eirs = [cool_eir]

        # E+ equation fit coil coefficients from Tang's thesis:
        # See Appendix B Figure B.3 of  https://hvac.okstate.edu/sites/default/files/pubs/theses/MS/27-Tang_Thesis_05.pdf
        # Coefficients generated by catalog data
        hp_ap.heat_cap_ft_spec = [[-5.12650150, -0.93997630, 7.21443206, 0.121065721, 0.051809805]]
        hp_ap.heat_power_ft_spec = [[-7.73235249, 6.43390775, 2.29152262, -0.175598629, 0.005888871]]
        heat_eir = (1.0 - heat_pump.heating_efficiency_cop * (fan_adjust_kw + pump_adjust_kw)) / (heat_pump.heating_efficiency_cop * (1.0 - fan_adjust_kw))
        hp_ap.heat_rated_eirs = [heat_eir]
      end
    end
  end

  def self.apply_hvac_control(hpxml)
    hpxml.hvac_controls.each do |hvac_control|
      if not hvac_control.heating_setback_temp.nil?
        if hvac_control.heating_setback_start_hour.nil?
          hvac_control.heating_setback_start_hour = 23 # 11 pm
          hvac_control.heating_setback_start_hour_isdefaulted = true
        end
      end

      next unless not hvac_control.cooling_setup_temp.nil?
      if hvac_control.cooling_setup_start_hour.nil?
        hvac_control.cooling_setup_start_hour = 9 # 9 am
        hvac_control.cooling_setup_start_hour_isdefaulted = true
      end
    end
  end

  def self.apply_hvac_distribution(hpxml, ncfl, ncfl_ag)
    # Check either all ducts have location and surface area or all ducts have no location and surface area
    n_ducts = 0
    n_ducts_to_be_defaulted = 0
    hpxml.hvac_distributions.each do |hvac_distribution|
      n_ducts += hvac_distribution.ducts.size
      n_ducts_to_be_defaulted += hvac_distribution.ducts.select { |duct| duct.duct_surface_area.nil? && duct.duct_location.nil? }.size
    end
    if n_ducts_to_be_defaulted > 0 && (n_ducts != n_ducts_to_be_defaulted)
      fail 'The location and surface area of all ducts must be provided or blank.'
    end

    hpxml.hvac_distributions.each do |hvac_distribution|
      next unless [HPXML::HVACDistributionTypeAir, HPXML::HVACDistributionTypeHydronicAndAir].include? hvac_distribution.distribution_system_type

      # Default return registers
      if hvac_distribution.number_of_return_registers.nil?
        hvac_distribution.number_of_return_registers = ncfl.ceil # Add 1 return register per conditioned floor if not provided
        hvac_distribution.number_of_return_registers_isdefaulted = true
      end

      # Default ducts
      cfa_served = hvac_distribution.conditioned_floor_area_served
      n_returns = hvac_distribution.number_of_return_registers

      supply_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeSupply }
      return_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeReturn }
      [supply_ducts, return_ducts].each do |ducts|
        ducts.each do |duct|
          next unless duct.duct_surface_area.nil?

          primary_duct_area, secondary_duct_area = HVAC.get_default_duct_surface_area(duct.duct_type, ncfl_ag, cfa_served, n_returns).map { |area| area / ducts.size }
          primary_duct_location, secondary_duct_location = HVAC.get_default_duct_locations(hpxml)
          if primary_duct_location.nil? # If a home doesn't have any non-living spaces (outside living space), place all ducts in living space.
            duct.duct_surface_area = primary_duct_area + secondary_duct_area
            duct.duct_location = secondary_duct_location
          else
            duct.duct_surface_area = primary_duct_area
            duct.duct_location = primary_duct_location
            if secondary_duct_area > 0
              hvac_distribution.ducts.add(duct_type: duct.duct_type,
                                          duct_insulation_r_value: duct.duct_insulation_r_value,
                                          duct_location: secondary_duct_location,
                                          duct_location_isdefaulted: true,
                                          duct_surface_area: secondary_duct_area,
                                          duct_surface_area_isdefaulted: true)
            end
          end
          duct.duct_surface_area_isdefaulted = true
          duct.duct_location_isdefaulted = true
        end
      end
    end
  end

  def self.apply_ventilation_fans(hpxml)
    # Default mech vent systems
    hpxml.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_whole_building_ventilation

      if vent_fan.is_shared_system.nil?
        vent_fan.is_shared_system = false
        vent_fan.is_shared_system_isdefaulted = true
      end
      if vent_fan.hours_in_operation.nil?
        vent_fan.hours_in_operation = (vent_fan.fan_type == HPXML::MechVentTypeCFIS) ? 8.0 : 24.0
        vent_fan.hours_in_operation_isdefaulted = true
      end
    end

    # Default kitchen fan
    hpxml.ventilation_fans.each do |vent_fan|
      next unless (vent_fan.used_for_local_ventilation && (vent_fan.fan_location == HPXML::LocationKitchen))

      if vent_fan.quantity.nil?
        vent_fan.quantity = 1
        vent_fan.quantity_isdefaulted = true
      end
      if vent_fan.rated_flow_rate.nil?
        vent_fan.rated_flow_rate = 100.0 # cfm, per BA HSP
        vent_fan.rated_flow_rate_isdefaulted = true
      end
      if vent_fan.hours_in_operation.nil?
        vent_fan.hours_in_operation = 1.0 # hrs/day, per BA HSP
        vent_fan.hours_in_operation_isdefaulted = true
      end
      if vent_fan.fan_power.nil?
        vent_fan.fan_power = 0.3 * vent_fan.rated_flow_rate # W, per BA HSP
        vent_fan.fan_power_isdefaulted = true
      end
      if vent_fan.start_hour.nil?
        vent_fan.start_hour = 18 # 6 pm, per BA HSP
        vent_fan.start_hour_isdefaulted = true
      end
    end

    # Default bath fans
    hpxml.ventilation_fans.each do |vent_fan|
      next unless (vent_fan.used_for_local_ventilation && (vent_fan.fan_location == HPXML::LocationBath))

      if vent_fan.quantity.nil?
        vent_fan.quantity = hpxml.building_construction.number_of_bathrooms
        vent_fan.quantity_isdefaulted = true
      end
      if vent_fan.rated_flow_rate.nil?
        vent_fan.rated_flow_rate = 50.0 # cfm, per BA HSP
        vent_fan.rated_flow_rate_isdefaulted = true
      end
      if vent_fan.hours_in_operation.nil?
        vent_fan.hours_in_operation = 1.0 # hrs/day, per BA HSP
        vent_fan.hours_in_operation_isdefaulted = true
      end
      if vent_fan.fan_power.nil?
        vent_fan.fan_power = 0.3 * vent_fan.rated_flow_rate # W, per BA HSP
        vent_fan.fan_power_isdefaulted = true
      end
      if vent_fan.start_hour.nil?
        vent_fan.start_hour = 7 # 7 am, per BA HSP
        vent_fan.start_hour_isdefaulted = true
      end
    end
  end

  def self.apply_water_heaters(hpxml, nbeds, eri_version)
    hpxml.water_heating_systems.each do |water_heating_system|
      if water_heating_system.is_shared_system.nil?
        water_heating_system.is_shared_system = false
        water_heating_system.is_shared_system_isdefaulted = true
      end
      if water_heating_system.temperature.nil?
        water_heating_system.temperature = Waterheater.get_default_hot_water_temperature(eri_version)
        water_heating_system.temperature_isdefaulted = true
      end
      if water_heating_system.performance_adjustment.nil?
        water_heating_system.performance_adjustment = Waterheater.get_default_performance_adjustment(water_heating_system)
        water_heating_system.performance_adjustment_isdefaulted = true
      end
      if (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeCombiStorage) && water_heating_system.standby_loss.nil?
        # Use equation fit from AHRI database
        # calculate independent variable SurfaceArea/vol(physically linear to standby_loss/skin_u under test condition) to fit the linear equation from AHRI database
        act_vol = Waterheater.calc_storage_tank_actual_vol(water_heating_system.tank_volume, nil)
        surface_area = Waterheater.calc_tank_areas(act_vol)[0]
        sqft_by_gal = surface_area / act_vol # sqft/gal
        water_heating_system.standby_loss = (2.9721 * sqft_by_gal - 0.4732).round(3) # linear equation assuming a constant u, F/hr
        water_heating_system.standby_loss_isdefaulted = true
      end
      if (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage)
        if water_heating_system.heating_capacity.nil?
          water_heating_system.heating_capacity = Waterheater.get_default_heating_capacity(water_heating_system.fuel_type, nbeds, hpxml.water_heating_systems.size, hpxml.building_construction.number_of_bathrooms) * 1000.0
          water_heating_system.heating_capacity_isdefaulted = true
        end
        if water_heating_system.tank_volume.nil?
          water_heating_system.tank_volume = Waterheater.get_default_tank_volume(water_heating_system.fuel_type, nbeds, hpxml.building_construction.number_of_bathrooms)
          water_heating_system.tank_volume_isdefaulted = true
        end
        if water_heating_system.recovery_efficiency.nil?
          water_heating_system.recovery_efficiency = Waterheater.get_default_recovery_efficiency(water_heating_system)
          water_heating_system.recovery_efficiency_isdefaulted = true
        end
      end
      if water_heating_system.location.nil?
        water_heating_system.location = Waterheater.get_default_location(hpxml, hpxml.climate_and_risk_zones.iecc_zone)
        water_heating_system.location_isdefaulted = true
      end
    end
  end

  def self.apply_hot_water_distribution(hpxml, cfa, ncfl, has_uncond_bsmnt)
    return if hpxml.hot_water_distributions.size == 0

    hot_water_distribution = hpxml.hot_water_distributions[0]

    if hot_water_distribution.pipe_r_value.nil?
      hot_water_distribution.pipe_r_value = 0.0
      hot_water_distribution.pipe_r_value_isdefaulted = true
    end

    if hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      if hot_water_distribution.standard_piping_length.nil?
        hot_water_distribution.standard_piping_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
        hot_water_distribution.standard_piping_length_isdefaulted = true
      end
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      if hot_water_distribution.recirculation_piping_length.nil?
        hot_water_distribution.recirculation_piping_length = HotWaterAndAppliances.get_default_recirc_loop_length(HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl))
        hot_water_distribution.recirculation_piping_length_isdefaulted = true
      end
      if hot_water_distribution.recirculation_branch_piping_length.nil?
        hot_water_distribution.recirculation_branch_piping_length = HotWaterAndAppliances.get_default_recirc_branch_loop_length()
        hot_water_distribution.recirculation_branch_piping_length_isdefaulted = true
      end
      if hot_water_distribution.recirculation_pump_power.nil?
        hot_water_distribution.recirculation_pump_power = HotWaterAndAppliances.get_default_recirc_pump_power()
        hot_water_distribution.recirculation_pump_power_isdefaulted = true
      end
    end

    if hot_water_distribution.has_shared_recirculation
      if hot_water_distribution.shared_recirculation_pump_power.nil?
        hot_water_distribution.shared_recirculation_pump_power = HotWaterAndAppliances.get_default_shared_recirc_pump_power()
        hot_water_distribution.shared_recirculation_pump_power_isdefaulted = true
      end
    end
  end

  def self.apply_water_fixtures(hpxml)
    if hpxml.water_heating.water_fixtures_usage_multiplier.nil?
      hpxml.water_heating.water_fixtures_usage_multiplier = 1.0
      hpxml.water_heating.water_fixtures_usage_multiplier_isdefaulted = true
    end
  end

  def self.apply_solar_thermal_systems(hpxml)
    return if hpxml.solar_thermal_systems.size == 0

    solar_thermal_system = hpxml.solar_thermal_systems[0]
    collector_area = solar_thermal_system.collector_area

    if not collector_area.nil? # Detailed solar water heater
      if solar_thermal_system.storage_volume.nil?
        solar_thermal_system.storage_volume = Waterheater.calc_default_solar_thermal_system_storage_volume(collector_area)
        solar_thermal_system.storage_volume_isdefaulted = true
      end
    end
  end

  def self.apply_pv_systems(hpxml)
    hpxml.pv_systems.each do |pv_system|
      if pv_system.is_shared_system.nil?
        pv_system.is_shared_system = false
        pv_system.is_shared_system_isdefaulted = true
      end
      if pv_system.location.nil?
        pv_system.location = HPXML::LocationRoof
        pv_system.location_isdefaulted = true
      end
      if pv_system.tracking.nil?
        pv_system.tracking = HPXML::PVTrackingTypeFixed
        pv_system.tracking_isdefaulted = true
      end
      if pv_system.module_type.nil?
        pv_system.module_type = HPXML::PVModuleTypeStandard
        pv_system.module_type_isdefaulted = true
      end
      if pv_system.inverter_efficiency.nil?
        pv_system.inverter_efficiency = PV.get_default_inv_eff()
        pv_system.inverter_efficiency_isdefaulted = true
      end
      if pv_system.system_losses_fraction.nil?
        pv_system.system_losses_fraction = PV.get_default_system_losses(pv_system.year_modules_manufactured)
        pv_system.system_losses_fraction_isdefaulted = true
      end
    end
  end

  def self.apply_generators(hpxml)
    hpxml.generators.each do |generator|
      if generator.is_shared_system.nil?
        generator.is_shared_system = false
        generator.is_shared_system_isdefaulted = true
      end
    end
  end

  def self.apply_appliances(hpxml, nbeds, eri_version)
    # Default clothes washer
    if hpxml.clothes_washers.size > 0
      clothes_washer = hpxml.clothes_washers[0]
      if clothes_washer.is_shared_appliance.nil?
        clothes_washer.is_shared_appliance = false
        clothes_washer.is_shared_appliance_isdefaulted = true
      end
      if clothes_washer.location.nil?
        clothes_washer.location = HPXML::LocationLivingSpace
        clothes_washer.location_isdefaulted = true
      end
      if clothes_washer.rated_annual_kwh.nil?
        default_values = HotWaterAndAppliances.get_clothes_washer_default_values(eri_version)
        clothes_washer.integrated_modified_energy_factor = default_values[:integrated_modified_energy_factor]
        clothes_washer.integrated_modified_energy_factor_isdefaulted = true
        clothes_washer.rated_annual_kwh = default_values[:rated_annual_kwh]
        clothes_washer.rated_annual_kwh_isdefaulted = true
        clothes_washer.label_electric_rate = default_values[:label_electric_rate]
        clothes_washer.label_electric_rate_isdefaulted = true
        clothes_washer.label_gas_rate = default_values[:label_gas_rate]
        clothes_washer.label_gas_rate_isdefaulted = true
        clothes_washer.label_annual_gas_cost = default_values[:label_annual_gas_cost]
        clothes_washer.label_annual_gas_cost_isdefaulted = true
        clothes_washer.capacity = default_values[:capacity]
        clothes_washer.capacity_isdefaulted = true
        clothes_washer.label_usage = default_values[:label_usage]
        clothes_washer.label_usage_isdefaulted = true
      end
      if clothes_washer.usage_multiplier.nil?
        clothes_washer.usage_multiplier = 1.0
        clothes_washer.usage_multiplier_isdefaulted = true
      end
    end

    # Default clothes dryer
    if hpxml.clothes_dryers.size > 0
      clothes_dryer = hpxml.clothes_dryers[0]
      if clothes_dryer.is_shared_appliance.nil?
        clothes_dryer.is_shared_appliance = false
        clothes_dryer.is_shared_appliance_isdefaulted = true
      end
      if clothes_dryer.location.nil?
        clothes_dryer.location = HPXML::LocationLivingSpace
        clothes_dryer.location_isdefaulted = true
      end
      if clothes_dryer.control_type.nil?
        default_values = HotWaterAndAppliances.get_clothes_dryer_default_values(eri_version, clothes_dryer.fuel_type)
        clothes_dryer.control_type = default_values[:control_type]
        clothes_dryer.control_type_isdefaulted = true
        clothes_dryer.combined_energy_factor = default_values[:combined_energy_factor]
        clothes_dryer.combined_energy_factor_isdefaulted = true
      end
      if clothes_dryer.usage_multiplier.nil?
        clothes_dryer.usage_multiplier = 1.0
        clothes_dryer.usage_multiplier_isdefaulted = true
      end
      if clothes_dryer.is_vented.nil?
        clothes_dryer.is_vented = true
        clothes_dryer.is_vented_isdefaulted = true
      end
      if clothes_dryer.is_vented && clothes_dryer.vented_flow_rate.nil?
        clothes_dryer.vented_flow_rate = 100.0
        clothes_dryer.vented_flow_rate_isdefaulted = true
      end
    end

    # Default dishwasher
    if hpxml.dishwashers.size > 0
      dishwasher = hpxml.dishwashers[0]
      if dishwasher.is_shared_appliance.nil?
        dishwasher.is_shared_appliance = false
        dishwasher.is_shared_appliance_isdefaulted = true
      end
      if dishwasher.location.nil?
        dishwasher.location = HPXML::LocationLivingSpace
        dishwasher.location_isdefaulted = true
      end
      if dishwasher.place_setting_capacity.nil?
        default_values = HotWaterAndAppliances.get_dishwasher_default_values(eri_version)
        dishwasher.rated_annual_kwh = default_values[:rated_annual_kwh]
        dishwasher.rated_annual_kwh_isdefaulted = true
        dishwasher.label_electric_rate = default_values[:label_electric_rate]
        dishwasher.label_electric_rate_isdefaulted = true
        dishwasher.label_gas_rate = default_values[:label_gas_rate]
        dishwasher.label_gas_rate_isdefaulted = true
        dishwasher.label_annual_gas_cost = default_values[:label_annual_gas_cost]
        dishwasher.label_annual_gas_cost_isdefaulted = true
        dishwasher.label_usage = default_values[:label_usage]
        dishwasher.label_usage_isdefaulted = true
        dishwasher.place_setting_capacity = default_values[:place_setting_capacity]
        dishwasher.place_setting_capacity_isdefaulted = true
      end
      if dishwasher.usage_multiplier.nil?
        dishwasher.usage_multiplier = 1.0
        dishwasher.usage_multiplier_isdefaulted = true
      end
    end

    # Default refrigerators
    if hpxml.refrigerators.size == 1
      hpxml.refrigerators[0].primary_indicator = true
      hpxml.refrigerators[0].primary_indicator_isdefaulted = true
    end
    hpxml.refrigerators.each do |refrigerator|
      if not refrigerator.primary_indicator # extra refrigerator
        if refrigerator.location.nil?
          refrigerator.location = HotWaterAndAppliances.get_default_extra_refrigerator_and_freezer_locations(hpxml)
          refrigerator.location_isdefaulted = true
        end
        if refrigerator.adjusted_annual_kwh.nil? && refrigerator.rated_annual_kwh.nil?
          default_values = HotWaterAndAppliances.get_extra_refrigerator_default_values
          refrigerator.rated_annual_kwh = default_values[:rated_annual_kwh]
          refrigerator.rated_annual_kwh_isdefaulted = true
        end
        if refrigerator.weekday_fractions.nil?
          refrigerator.weekday_fractions = Schedule.ExtraRefrigeratorWeekdayFractions
          refrigerator.weekday_fractions_isdefaulted = true
        end
        if refrigerator.weekend_fractions.nil?
          refrigerator.weekend_fractions = Schedule.ExtraRefrigeratorWeekendFractions
          refrigerator.weekend_fractions_isdefaulted = true
        end
        if refrigerator.monthly_multipliers.nil?
          refrigerator.monthly_multipliers = Schedule.ExtraRefrigeratorMonthlyMultipliers
          refrigerator.monthly_multipliers_isdefaulted = true
        end
      else # primary refrigerator
        if refrigerator.location.nil?
          refrigerator.location = HPXML::LocationLivingSpace
          refrigerator.location_isdefaulted = true
        end
        if refrigerator.adjusted_annual_kwh.nil? && refrigerator.rated_annual_kwh.nil?
          default_values = HotWaterAndAppliances.get_refrigerator_default_values(nbeds)
          refrigerator.rated_annual_kwh = default_values[:rated_annual_kwh]
          refrigerator.rated_annual_kwh_isdefaulted = true
        end
        if refrigerator.weekday_fractions.nil?
          refrigerator.weekday_fractions = Schedule.RefrigeratorWeekdayFractions
          refrigerator.weekday_fractions_isdefaulted = true
        end
        if refrigerator.weekend_fractions.nil?
          refrigerator.weekend_fractions = Schedule.RefrigeratorWeekendFractions
          refrigerator.weekend_fractions_isdefaulted = true
        end
        if refrigerator.monthly_multipliers.nil?
          refrigerator.monthly_multipliers = Schedule.RefrigeratorMonthlyMultipliers
          refrigerator.monthly_multipliers_isdefaulted = true
        end
      end
      if refrigerator.usage_multiplier.nil?
        refrigerator.usage_multiplier = 1.0
        refrigerator.usage_multiplier_isdefaulted = true
      end
    end

    # Default freezer
    hpxml.freezers.each do |freezer|
      if freezer.location.nil?
        freezer.location = HotWaterAndAppliances.get_default_extra_refrigerator_and_freezer_locations(hpxml)
        freezer.location_isdefaulted = true
      end
      if freezer.adjusted_annual_kwh.nil? && freezer.rated_annual_kwh.nil?
        default_values = HotWaterAndAppliances.get_freezer_default_values
        freezer.rated_annual_kwh = default_values[:rated_annual_kwh]
        freezer.rated_annual_kwh_isdefaulted = true
      end
      if freezer.usage_multiplier.nil?
        freezer.usage_multiplier = 1.0
        freezer.usage_multiplier_isdefaulted = true
      end
      if freezer.weekday_fractions.nil?
        freezer.weekday_fractions = Schedule.FreezerWeekdayFractions
        freezer.weekday_fractions_isdefaulted = true
      end
      if freezer.weekend_fractions.nil?
        freezer.weekend_fractions = Schedule.FreezerWeekendFractions
        freezer.weekend_fractions_isdefaulted = true
      end
      if freezer.monthly_multipliers.nil?
        freezer.monthly_multipliers = Schedule.FreezerMonthlyMultipliers
        freezer.monthly_multipliers_isdefaulted = true
      end
    end

    # Default cooking range
    if hpxml.cooking_ranges.size > 0
      cooking_range = hpxml.cooking_ranges[0]
      if cooking_range.location.nil?
        cooking_range.location = HPXML::LocationLivingSpace
        cooking_range.location_isdefaulted = true
      end
      if cooking_range.is_induction.nil?
        default_values = HotWaterAndAppliances.get_range_oven_default_values()
        cooking_range.is_induction = default_values[:is_induction]
        cooking_range.is_induction_isdefaulted = true
      end
      if cooking_range.usage_multiplier.nil?
        cooking_range.usage_multiplier = 1.0
        cooking_range.usage_multiplier_isdefaulted = true
      end
      if cooking_range.weekday_fractions.nil?
        cooking_range.weekday_fractions = Schedule.CookingRangeWeekdayFractions
        cooking_range.weekday_fractions_isdefaulted = true
      end
      if cooking_range.weekend_fractions.nil?
        cooking_range.weekend_fractions = Schedule.CookingRangeWeekendFractions
        cooking_range.weekend_fractions_isdefaulted = true
      end
      if cooking_range.monthly_multipliers.nil?
        cooking_range.monthly_multipliers = Schedule.CookingRangeMonthlyMultipliers
        cooking_range.monthly_multipliers_isdefaulted = true
      end
    end

    # Default oven
    if hpxml.ovens.size > 0
      oven = hpxml.ovens[0]
      if oven.is_convection.nil?
        default_values = HotWaterAndAppliances.get_range_oven_default_values()
        oven.is_convection = default_values[:is_convection]
        oven.is_convection_isdefaulted = true
      end
    end
  end

  def self.apply_lighting(hpxml)
    if hpxml.lighting.interior_usage_multiplier.nil?
      hpxml.lighting.interior_usage_multiplier = 1.0
      hpxml.lighting.interior_usage_multiplier_isdefaulted = true
    end
    if hpxml.lighting.garage_usage_multiplier.nil?
      hpxml.lighting.garage_usage_multiplier = 1.0
      hpxml.lighting.garage_usage_multiplier_isdefaulted = true
    end
    if hpxml.lighting.exterior_usage_multiplier.nil?
      hpxml.lighting.exterior_usage_multiplier = 1.0
      hpxml.lighting.exterior_usage_multiplier_isdefaulted = true
    end
    # Schedules from T24 2016 Residential ACM Appendix C Table 8 Exterior Lighting Hourly Multiplier (Weekdays and weekends)
    default_exterior_lighting_weekday_fractions = Schedule.LightingExteriorWeekdayFractions
    default_exterior_lighting_weekend_fractions = Schedule.LightingExteriorWeekendFractions
    default_exterior_lighting_monthly_multipliers = Schedule.LightingExteriorMonthlyMultipliers
    if hpxml.has_space_type(HPXML::LocationGarage)
      if hpxml.lighting.garage_weekday_fractions.nil?
        hpxml.lighting.garage_weekday_fractions = default_exterior_lighting_weekday_fractions
        hpxml.lighting.garage_weekday_fractions_isdefaulted = true
      end
      if hpxml.lighting.garage_weekend_fractions.nil?
        hpxml.lighting.garage_weekend_fractions = default_exterior_lighting_weekend_fractions
        hpxml.lighting.garage_weekend_fractions_isdefaulted = true
      end
      if hpxml.lighting.garage_monthly_multipliers.nil?
        hpxml.lighting.garage_monthly_multipliers = default_exterior_lighting_monthly_multipliers
        hpxml.lighting.garage_monthly_multipliers_isdefaulted = true
      end
    end
    if hpxml.lighting.exterior_weekday_fractions.nil?
      hpxml.lighting.exterior_weekday_fractions = default_exterior_lighting_weekday_fractions
      hpxml.lighting.exterior_weekday_fractions_isdefaulted = true
    end
    if hpxml.lighting.exterior_weekend_fractions.nil?
      hpxml.lighting.exterior_weekend_fractions = default_exterior_lighting_weekend_fractions
      hpxml.lighting.exterior_weekend_fractions_isdefaulted = true
    end
    if hpxml.lighting.exterior_monthly_multipliers.nil?
      hpxml.lighting.exterior_monthly_multipliers = default_exterior_lighting_monthly_multipliers
      hpxml.lighting.exterior_monthly_multipliers_isdefaulted = true
    end
    if hpxml.lighting.holiday_exists
      if hpxml.lighting.holiday_kwh_per_day.nil?
        # From LA100 repo (2017)
        if hpxml.building_construction.residential_facility_type == HPXML::ResidentialTypeSFD
          hpxml.lighting.holiday_kwh_per_day = 1.1
        else # Multifamily and others
          hpxml.lighting.holiday_kwh_per_day = 0.55
        end
        hpxml.lighting.holiday_kwh_per_day_isdefaulted = true
      end
      if hpxml.lighting.holiday_period_begin_month.nil?
        hpxml.lighting.holiday_period_begin_month = 11
        hpxml.lighting.holiday_period_begin_month_isdefaulted = true
        hpxml.lighting.holiday_period_begin_day = 24
        hpxml.lighting.holiday_period_begin_day_isdefaulted = true
      end
      if hpxml.lighting.holiday_period_end_day.nil?
        hpxml.lighting.holiday_period_end_month = 1
        hpxml.lighting.holiday_period_end_month_isdefaulted = true
        hpxml.lighting.holiday_period_end_day = 6
        hpxml.lighting.holiday_period_end_day_isdefaulted = true
      end
      if hpxml.lighting.holiday_weekday_fractions.nil?
        hpxml.lighting.holiday_weekday_fractions = Schedule.LightingExteriorHolidayWeekdayFractions
        hpxml.lighting.holiday_weekday_fractions_isdefaulted = true
      end
      if hpxml.lighting.holiday_weekend_fractions.nil?
        hpxml.lighting.holiday_weekend_fractions = Schedule.LightingExteriorHolidayWeekendFractions
        hpxml.lighting.holiday_weekend_fractions_isdefaulted = true
      end
    end
  end

  def self.apply_ceiling_fans(hpxml, nbeds)
    return if hpxml.ceiling_fans.size == 0

    ceiling_fan = hpxml.ceiling_fans[0]
    if ceiling_fan.efficiency.nil?
      medium_cfm = 3000.0
      ceiling_fan.efficiency = medium_cfm / HVAC.get_default_ceiling_fan_power()
      ceiling_fan.efficiency_isdefaulted = true
    end
    if ceiling_fan.quantity.nil?
      ceiling_fan.quantity = HVAC.get_default_ceiling_fan_quantity(nbeds)
      ceiling_fan.quantity_isdefaulted = true
    end
  end

  def self.apply_pools_and_hot_tubs(hpxml, cfa, nbeds)
    hpxml.pools.each do |pool|
      next if pool.type == HPXML::TypeNone

      if pool.pump_type != HPXML::TypeNone
        # Pump
        if pool.pump_kwh_per_year.nil?
          pool.pump_kwh_per_year = MiscLoads.get_pool_pump_default_values(cfa, nbeds)
          pool.pump_kwh_per_year_isdefaulted = true
        end
        if pool.pump_usage_multiplier.nil?
          pool.pump_usage_multiplier = 1.0
          pool.pump_usage_multiplier_isdefaulted = true
        end
        if pool.pump_weekday_fractions.nil?
          pool.pump_weekday_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
          pool.pump_weekday_fractions_isdefaulted = true
        end
        if pool.pump_weekend_fractions.nil?
          pool.pump_weekend_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
          pool.pump_weekend_fractions_isdefaulted = true
        end
        if pool.pump_monthly_multipliers.nil?
          pool.pump_monthly_multipliers = '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
          pool.pump_monthly_multipliers_isdefaulted = true
        end
      end

      next unless pool.heater_type != HPXML::TypeNone
      # Heater
      if pool.heater_load_value.nil?
        default_heater_load_units, default_heater_load_value = MiscLoads.get_pool_heater_default_values(cfa, nbeds, pool.heater_type)
        pool.heater_load_units = default_heater_load_units
        pool.heater_load_value = default_heater_load_value
        pool.heater_load_value_isdefaulted = true
      end
      if pool.heater_usage_multiplier.nil?
        pool.heater_usage_multiplier = 1.0
        pool.heater_usage_multiplier_isdefaulted = true
      end
      if pool.heater_weekday_fractions.nil?
        pool.heater_weekday_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
        pool.heater_weekday_fractions_isdefaulted = true
      end
      if pool.heater_weekend_fractions.nil?
        pool.heater_weekend_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
        pool.heater_weekend_fractions_isdefaulted = true
      end
      if pool.heater_monthly_multipliers.nil?
        pool.heater_monthly_multipliers = '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
        pool.heater_monthly_multipliers_isdefaulted = true
      end
    end

    hpxml.hot_tubs.each do |hot_tub|
      next if hot_tub.type == HPXML::TypeNone

      if hot_tub.pump_type != HPXML::TypeNone
        # Pump
        if hot_tub.pump_kwh_per_year.nil?
          hot_tub.pump_kwh_per_year = MiscLoads.get_hot_tub_pump_default_values(cfa, nbeds)
          hot_tub.pump_kwh_per_year_isdefaulted = true
        end
        if hot_tub.pump_usage_multiplier.nil?
          hot_tub.pump_usage_multiplier = 1.0
          hot_tub.pump_usage_multiplier_isdefaulted = true
        end
        if hot_tub.pump_weekday_fractions.nil?
          hot_tub.pump_weekday_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
          hot_tub.pump_weekday_fractions_isdefaulted = true
        end
        if hot_tub.pump_weekend_fractions.nil?
          hot_tub.pump_weekend_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
          hot_tub.pump_weekend_fractions_isdefaulted = true
        end
        if hot_tub.pump_monthly_multipliers.nil?
          hot_tub.pump_monthly_multipliers = '0.921, 0.928, 0.921, 0.915, 0.921, 1.160, 1.158, 1.158, 1.160, 0.921, 0.915, 0.921'
          hot_tub.pump_monthly_multipliers_isdefaulted = true
        end
      end

      next unless hot_tub.heater_type != HPXML::TypeNone
      # Heater
      if hot_tub.heater_load_value.nil?
        default_heater_load_units, default_heater_load_value = MiscLoads.get_hot_tub_heater_default_values(cfa, nbeds, hot_tub.heater_type)
        hot_tub.heater_load_units = default_heater_load_units
        hot_tub.heater_load_value = default_heater_load_value
        hot_tub.heater_load_value_isdefaulted = true
      end
      if hot_tub.heater_usage_multiplier.nil?
        hot_tub.heater_usage_multiplier = 1.0
        hot_tub.heater_usage_multiplier_isdefaulted = true
      end
      if hot_tub.heater_weekday_fractions.nil?
        hot_tub.heater_weekday_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
        hot_tub.heater_weekday_fractions_isdefaulted = true
      end
      if hot_tub.heater_weekend_fractions.nil?
        hot_tub.heater_weekend_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
        hot_tub.heater_weekend_fractions_isdefaulted = true
      end
      if hot_tub.heater_monthly_multipliers.nil?
        hot_tub.heater_monthly_multipliers = '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
        hot_tub.heater_monthly_multipliers_isdefaulted = true
      end
    end
  end

  def self.apply_plug_loads(hpxml, cfa, nbeds)
    hpxml.plug_loads.each do |plug_load|
      if plug_load.plug_load_type == HPXML::PlugLoadTypeOther
        default_annual_kwh, default_sens_frac, default_lat_frac = MiscLoads.get_residual_mels_default_values(cfa)
        if plug_load.kWh_per_year.nil?
          plug_load.kWh_per_year = default_annual_kwh
          plug_load.kWh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = default_sens_frac
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = default_lat_frac
          plug_load.frac_latent_isdefaulted = true
        end
        if plug_load.weekday_fractions.nil?
          plug_load.weekday_fractions = Schedule.PlugLoadsOtherWeekdayFractions
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil?
          plug_load.weekend_fractions = Schedule.PlugLoadsOtherWeekendFractions
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil?
          plug_load.monthly_multipliers = Schedule.PlugLoadsOtherMonthlyMultipliers
          plug_load.monthly_multipliers_isdefaulted = true
        end
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeTelevision
        default_annual_kwh, default_sens_frac, default_lat_frac = MiscLoads.get_televisions_default_values(cfa, nbeds)
        if plug_load.kWh_per_year.nil?
          plug_load.kWh_per_year = default_annual_kwh
          plug_load.kWh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = default_sens_frac
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = default_lat_frac
          plug_load.frac_latent_isdefaulted = true
        end
        if plug_load.weekday_fractions.nil?
          plug_load.weekday_fractions = Schedule.PlugLoadsTVWeekdayFractions
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil?
          plug_load.weekend_fractions = Schedule.PlugLoadsTVWeekendFractions
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil?
          plug_load.monthly_multipliers = Schedule.PlugLoadsTVMonthlyMultipliers
          plug_load.monthly_multipliers_isdefaulted = true
        end
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging
        default_annual_kwh = MiscLoads.get_electric_vehicle_charging_default_values
        if plug_load.kWh_per_year.nil?
          plug_load.kWh_per_year = default_annual_kwh
          plug_load.kWh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = 0.0
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = 0.0
          plug_load.frac_latent_isdefaulted = true
        end
        if plug_load.weekday_fractions.nil?
          plug_load.weekday_fractions = Schedule.PlugLoadsVehicleWeekdayFractions
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil?
          plug_load.weekend_fractions = Schedule.PlugLoadsVehicleWeekendFractions
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil?
          plug_load.monthly_multipliers = Schedule.PlugLoadsVehicleMonthlyMultipliers
          plug_load.monthly_multipliers_isdefaulted = true
        end
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeWellPump
        default_annual_kwh = MiscLoads.get_well_pump_default_values(cfa, nbeds)
        if plug_load.kWh_per_year.nil?
          plug_load.kWh_per_year = default_annual_kwh
          plug_load.kWh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = 0.0
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = 0.0
          plug_load.frac_latent_isdefaulted = true
        end
        if plug_load.weekday_fractions.nil?
          plug_load.weekday_fractions = Schedule.PlugLoadsWellPumpWeekdayFractions
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil?
          plug_load.weekend_fractions = Schedule.PlugLoadsWellPumpWeekendFractions
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil?
          plug_load.monthly_multipliers = Schedule.PlugLoadsWellPumpMonthlyMultipliers
          plug_load.monthly_multipliers_isdefaulted = true
        end
      end
      if plug_load.usage_multiplier.nil?
        plug_load.usage_multiplier = 1.0
        plug_load.usage_multiplier_isdefaulted = true
      end
    end
  end

  def self.apply_fuel_loads(hpxml, cfa, nbeds)
    hpxml.fuel_loads.each do |fuel_load|
      if fuel_load.fuel_load_type == HPXML::FuelLoadTypeGrill
        if fuel_load.therm_per_year.nil?
          fuel_load.therm_per_year = MiscLoads.get_gas_grill_default_values(cfa, nbeds)
          fuel_load.therm_per_year_isdefaulted = true
        end
        if fuel_load.frac_sensible.nil?
          fuel_load.frac_sensible = 0.0
          fuel_load.frac_sensible_isdefaulted = true
        end
        if fuel_load.frac_latent.nil?
          fuel_load.frac_latent = 0.0
          fuel_load.frac_latent_isdefaulted = true
        end
        if fuel_load.weekday_fractions.nil?
          fuel_load.weekday_fractions = Schedule.FuelLoadsGrillWeekdayFractions
          fuel_load.weekday_fractions_isdefaulted = true
        end
        if fuel_load.weekend_fractions.nil?
          fuel_load.weekend_fractions = Schedule.FuelLoadsGrillWeekendFractions
          fuel_load.weekend_fractions_isdefaulted = true
        end
        if fuel_load.monthly_multipliers.nil?
          fuel_load.monthly_multipliers = Schedule.FuelLoadsGrillMonthlyMultipliers
          fuel_load.monthly_multipliers_isdefaulted = true
        end
      elsif fuel_load.fuel_load_type == HPXML::FuelLoadTypeLighting
        if fuel_load.therm_per_year.nil?
          fuel_load.therm_per_year = MiscLoads.get_gas_lighting_default_values(cfa, nbeds)
          fuel_load.therm_per_year_isdefaulted = true
        end
        if fuel_load.frac_sensible.nil?
          fuel_load.frac_sensible = 0.0
          fuel_load.frac_sensible_isdefaulted = true
        end
        if fuel_load.frac_latent.nil?
          fuel_load.frac_latent = 0.0
          fuel_load.frac_latent_isdefaulted = true
        end
        if fuel_load.weekday_fractions.nil?
          fuel_load.weekday_fractions = Schedule.FuelLoadsLightingWeekdayFractions
          fuel_load.weekday_fractions_isdefaulted = true
        end
        if fuel_load.weekend_fractions.nil?
          fuel_load.weekend_fractions = Schedule.FuelLoadsLightingWeekendFractions
          fuel_load.weekend_fractions_isdefaulted = true
        end
        if fuel_load.monthly_multipliers.nil?
          fuel_load.monthly_multipliers = Schedule.FuelLoadsLightingMonthlyMultipliers
          fuel_load.monthly_multipliers_isdefaulted = true
        end
      elsif fuel_load.fuel_load_type == HPXML::FuelLoadTypeFireplace
        if fuel_load.therm_per_year.nil?
          fuel_load.therm_per_year = MiscLoads.get_gas_fireplace_default_values(cfa, nbeds)
          fuel_load.therm_per_year_isdefaulted = true
        end
        if fuel_load.frac_sensible.nil?
          fuel_load.frac_sensible = 0.5
          fuel_load.frac_sensible_isdefaulted = true
        end
        if fuel_load.frac_latent.nil?
          fuel_load.frac_latent = 0.1
          fuel_load.frac_latent_isdefaulted = true
        end
        if fuel_load.weekday_fractions.nil?
          fuel_load.weekday_fractions = Schedule.FuelLoadsFireplaceWeekdayFractions
          fuel_load.weekday_fractions_isdefaulted = true
        end
        if fuel_load.weekend_fractions.nil?
          fuel_load.weekend_fractions = Schedule.FuelLoadsFireplaceWeekendFractions
          fuel_load.weekend_fractions_isdefaulted = true
        end
        if fuel_load.monthly_multipliers.nil?
          fuel_load.monthly_multipliers = Schedule.FuelLoadsFireplaceMonthlyMultipliers
          fuel_load.monthly_multipliers_isdefaulted = true
        end
      end
      if fuel_load.usage_multiplier.nil?
        fuel_load.usage_multiplier = 1.0
        fuel_load.usage_multiplier_isdefaulted = true
      end
    end
  end

  def self.apply_hvac_sizing(hpxml, runner, weather, cfa, nbeds)
    # Calculate building design load (excluding HVAC distribution losses)
    bldg_design_loads = HVACSizing.calculate_building_design_loads(runner, weather, hpxml, cfa, nbeds)

    HVAC.get_hpxml_hvac_systems(hpxml).each do |hvac_system|
      htg_sys = hvac_system[:heating]
      clg_sys = hvac_system[:cooling]

      # Calculate design loads and capacities/airflows for this HVAC system
      # FUTURE: Calculate HeatingCapacity17F for ASHP/MSHP, assign back to HPXML objects
      hvac_design_loads, hvac_sizing_values = HVACSizing.calculate_hvac_values(runner, weather, hpxml, cfa, bldg_design_loads, hvac_system)

      # Heating -- Assign back to HPXML objects (HeatingSystem/HeatPump)
      if not htg_sys.nil?

        # Heating capacities
        if htg_sys.heating_capacity.nil? || ((htg_sys.heating_capacity - hvac_sizing_values.Heat_Capacity).abs >= Constants.small)
          htg_sys.heating_capacity = hvac_sizing_values.Heat_Capacity.round
          htg_sys.heating_capacity_isdefaulted = true
        end
        if htg_sys.respond_to? :backup_heating_capacity
          if not htg_sys.backup_heating_fuel.nil? # If there is a backup heating source
            if htg_sys.backup_heating_capacity.nil? || ((htg_sys.backup_heating_capacity - hvac_sizing_values.Heat_Capacity_Supp).abs >= Constants.small)
              htg_sys.backup_heating_capacity = hvac_sizing_values.Heat_Capacity_Supp.round
              htg_sys.backup_heating_capacity_isdefaulted = true
            end
          else
            htg_sys.backup_heating_capacity = 0.0
          end
        end

        # Heating airflow
        htg_sys.heating_airflow_cfm = hvac_sizing_values.Heat_Airflow.round
        htg_sys.heating_airflow_cfm_isdefaulted = true

        # Heating GSHP loop
        if htg_sys.is_a? HPXML::HeatPump
          htg_sys.additional_properties.GSHP_Loop_flow = hvac_sizing_values.GSHP_Loop_flow
          htg_sys.additional_properties.GSHP_Bore_Depth = hvac_sizing_values.GSHP_Bore_Depth
          htg_sys.additional_properties.GSHP_Bore_Holes = hvac_sizing_values.GSHP_Bore_Holes
          htg_sys.additional_properties.GSHP_G_Functions = hvac_sizing_values.GSHP_G_Functions
        end

        # Heating design loads
        htg_sys.hdl_total = (hvac_design_loads.Heat_Tot + hvac_sizing_values.Heat_Load_Ducts).round
        htg_sys.hdl_walls = hvac_design_loads.Heat_Walls.round
        htg_sys.hdl_ceilings = hvac_design_loads.Heat_Ceilings.round
        htg_sys.hdl_roofs = hvac_design_loads.Heat_Roofs.round
        htg_sys.hdl_floors = hvac_design_loads.Heat_Floors.round
        htg_sys.hdl_slabs = hvac_design_loads.Heat_Slabs.round
        htg_sys.hdl_windows = hvac_design_loads.Heat_Windows.round
        htg_sys.hdl_skylights = hvac_design_loads.Heat_Skylights.round
        htg_sys.hdl_doors = hvac_design_loads.Heat_Doors.round
        htg_sys.hdl_infilvent = hvac_design_loads.Heat_InfilVent.round
        htg_sys.hdl_ducts = hvac_sizing_values.Heat_Load_Ducts.round

        # Check that components sum to totals
        hdl_sum = (htg_sys.hdl_walls + htg_sys.hdl_ceilings + htg_sys.hdl_roofs +
                   htg_sys.hdl_floors + htg_sys.hdl_slabs + htg_sys.hdl_windows +
                   htg_sys.hdl_skylights + htg_sys.hdl_doors + htg_sys.hdl_infilvent +
                   htg_sys.hdl_ducts)
        if (hdl_sum - htg_sys.hdl_total).abs > 100
          runner.registerWarning('Heating design loads do not sum to total.')
        end
      end

      # Cooling -- Assign back to HPXML objects (CoolingSystem/HeatPump)
      next unless not clg_sys.nil?

      # Cooling capacities
      if clg_sys.cooling_capacity.nil? || ((clg_sys.cooling_capacity - hvac_sizing_values.Cool_Capacity).abs >= Constants.small)
        clg_sys.cooling_capacity = hvac_sizing_values.Cool_Capacity.round
        clg_sys.cooling_capacity_isdefaulted = true
      end
      clg_sys.additional_properties.cooling_capacity_sensible = hvac_sizing_values.Cool_Capacity_Sens.round

      # Cooling airflow
      clg_sys.cooling_airflow_cfm = hvac_sizing_values.Cool_Airflow.round
      clg_sys.cooling_airflow_cfm_isdefaulted = true

      # Cooling sensible design loads
      clg_sys.cdl_sens_total = (hvac_design_loads.Cool_Sens + hvac_sizing_values.Cool_Load_Ducts_Sens).round
      clg_sys.cdl_sens_walls = hvac_design_loads.Cool_Walls.round
      clg_sys.cdl_sens_ceilings = hvac_design_loads.Cool_Ceilings.round
      clg_sys.cdl_sens_roofs = hvac_design_loads.Cool_Roofs.round
      clg_sys.cdl_sens_floors = hvac_design_loads.Cool_Floors.round
      clg_sys.cdl_sens_slabs = 0.0
      clg_sys.cdl_sens_windows = hvac_design_loads.Cool_Windows.round
      clg_sys.cdl_sens_skylights = hvac_design_loads.Cool_Skylights.round
      clg_sys.cdl_sens_doors = hvac_design_loads.Cool_Doors.round
      clg_sys.cdl_sens_infilvent = hvac_design_loads.Cool_Infil_Sens.round
      clg_sys.cdl_sens_ducts = hvac_sizing_values.Cool_Load_Ducts_Sens.round
      clg_sys.cdl_sens_intgains = hvac_design_loads.Cool_IntGains_Sens.round

      # Cooling latent design loads
      if hvac_design_loads.Cool_Lat <= 0.001
        clg_sys.cdl_lat_total = 0.0
        clg_sys.cdl_lat_ducts = 0.0
        clg_sys.cdl_lat_infilvent = 0.0
        clg_sys.cdl_lat_intgains = 0.0
      else
        clg_sys.cdl_lat_total = (hvac_design_loads.Cool_Lat + hvac_sizing_values.Cool_Load_Ducts_Lat).round
        clg_sys.cdl_lat_ducts = hvac_sizing_values.Cool_Load_Ducts_Lat.round
        clg_sys.cdl_lat_infilvent = hvac_design_loads.Cool_Infil_Lat.round
        clg_sys.cdl_lat_intgains = hvac_design_loads.Cool_IntGains_Lat.round
      end

      # Check that components sum to totals
      cdl_sens_sum = (clg_sys.cdl_sens_walls + clg_sys.cdl_sens_ceilings +
                      clg_sys.cdl_sens_roofs + clg_sys.cdl_sens_floors +
                      clg_sys.cdl_sens_slabs + clg_sys.cdl_sens_windows +
                      clg_sys.cdl_sens_skylights + clg_sys.cdl_sens_doors +
                      clg_sys.cdl_sens_infilvent + clg_sys.cdl_sens_ducts +
                      clg_sys.cdl_sens_intgains)
      cdl_lat_sum = (clg_sys.cdl_lat_ducts + clg_sys.cdl_lat_infilvent +
                     clg_sys.cdl_lat_intgains)
      if (cdl_sens_sum - clg_sys.cdl_sens_total).abs > 100
        runner.registerWarning('Cooling sensible design loads do not sum to total.')
      end
      if (cdl_lat_sum - clg_sys.cdl_lat_total).abs > 100
        runner.registerWarning('Cooling latent design loads do not sum to total.')
      end
    end
  end
end
