# frozen_string_literal: true

class HPXMLDefaults
  def self.apply(hpxml, cfa, nbeds, ncfl, ncfl_ag, has_uncond_bsmnt, eri_version)
    apply_header(hpxml)
    apply_site(hpxml)
    apply_building_occupancy(hpxml, nbeds)
    apply_building_construction(hpxml, cfa, nbeds)
    apply_attics(hpxml)
    apply_foundations(hpxml)
    apply_infiltration(hpxml)
    apply_roofs(hpxml)
    apply_walls(hpxml)
    apply_rim_joists(hpxml)
    apply_windows(hpxml)
    apply_skylights(hpxml)
    apply_hvac(hpxml)
    apply_hvac_distribution(hpxml, ncfl, ncfl_ag)
    apply_water_heaters(hpxml, nbeds, eri_version)
    apply_hot_water_distribution(hpxml, cfa, ncfl, has_uncond_bsmnt)
    apply_water_fixtures(hpxml)
    apply_solar_thermal_systems(hpxml)
    apply_ventilation_fans(hpxml)
    apply_ceiling_fans(hpxml, nbeds)
    apply_plug_loads(hpxml, cfa, nbeds)
    apply_appliances(hpxml, nbeds, eri_version)
    apply_lighting(hpxml)
    apply_pv_systems(hpxml)
  end

  private

  def self.apply_header(hpxml)
    hpxml.header.timestep = 60 if hpxml.header.timestep.nil?
    hpxml.header.begin_month = 1 if hpxml.header.begin_month.nil?
    hpxml.header.begin_day_of_month = 1 if hpxml.header.begin_day_of_month.nil?
    hpxml.header.end_month = 12 if hpxml.header.end_month.nil?
    hpxml.header.end_day_of_month = 31 if hpxml.header.end_day_of_month.nil?
  end

  def self.apply_site(hpxml)
    hpxml.site.site_type = HPXML::SiteTypeSuburban if hpxml.site.site_type.nil?
    hpxml.site.shelter_coefficient = Airflow.get_default_shelter_coefficient() if hpxml.site.shelter_coefficient.nil?
  end

  def self.apply_building_occupancy(hpxml, nbeds)
    hpxml.building_occupancy.number_of_residents = Geometry.get_occupancy_default_num(nbeds) if hpxml.building_occupancy.number_of_residents.nil?
  end

  def self.apply_building_construction(hpxml, cfa, nbeds)
    if hpxml.building_construction.conditioned_building_volume.nil?
      hpxml.building_construction.conditioned_building_volume = cfa * hpxml.building_construction.average_ceiling_height
    end
    hpxml.building_construction.number_of_bathrooms = Float(Waterheater.get_default_num_bathrooms(nbeds)).to_i if hpxml.building_construction.number_of_bathrooms.nil?
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
    end
  end

  def self.apply_infiltration(hpxml)
    measurements = []
    infil_volume = nil
    hpxml.air_infiltration_measurements.each do |measurement|
      is_ach50 = ((measurement.unit_of_measure == HPXML::UnitsACH) && (measurement.house_pressure == 50))
      is_cfm50 = ((measurement.unit_of_measure == HPXML::UnitsCFM) && (measurement.house_pressure == 50))
      is_nach = (measurement.unit_of_measure == HPXML::UnitsACHNatural)
      next unless (is_ach50 || is_cfm50 || is_nach)

      measurements << measurement
      next if measurement.infiltration_volume.nil?

      infil_volume = measurement.infiltration_volume
    end
    if infil_volume.nil?
      infil_volume = hpxml.building_construction.conditioned_building_volume
      measurements.each do |measurement|
        measurement.infiltration_volume = infil_volume
      end
    end
  end

  def self.apply_roofs(hpxml)
    hpxml.roofs.each do |roof|
      if roof.roof_type.nil?
        roof.roof_type = HPXML::RoofTypeAsphaltShingles
      end
      if roof.roof_color.nil?
        roof.roof_color = Constructions.get_default_roof_color(roof.roof_type, roof.solar_absorptance)
      elsif roof.solar_absorptance.nil?
        roof.solar_absorptance = Constructions.get_default_roof_solar_absorptance(roof.roof_type, roof.roof_color)
      end
    end
  end

  def self.apply_walls(hpxml)
    hpxml.walls.each do |wall|
      next unless wall.is_exterior

      if wall.siding.nil?
        wall.siding = HPXML::SidingTypeWood
      end
      if wall.color.nil?
        wall.color = Constructions.get_default_wall_color(wall.solar_absorptance)
      elsif wall.solar_absorptance.nil?
        wall.solar_absorptance = Constructions.get_default_wall_solar_absorptance(wall.color)
      end
    end
  end

  def self.apply_rim_joists(hpxml)
    hpxml.rim_joists.each do |rim_joist|
      next unless rim_joist.is_exterior

      if rim_joist.siding.nil?
        rim_joist.siding = HPXML::SidingTypeWood
      end
      if rim_joist.color.nil?
        rim_joist.color = Constructions.get_default_wall_color(rim_joist.solar_absorptance)
      elsif rim_joist.solar_absorptance.nil?
        rim_joist.solar_absorptance = Constructions.get_default_wall_solar_absorptance(rim_joist.color)
      end
    end
  end

  def self.apply_windows(hpxml)
    default_shade_summer, default_shade_winter = Constructions.get_default_interior_shading_factors()
    hpxml.windows.each do |window|
      if window.interior_shading_factor_summer.nil?
        window.interior_shading_factor_summer = default_shade_summer
      end
      if window.interior_shading_factor_winter.nil?
        window.interior_shading_factor_winter = default_shade_winter
      end
      if window.fraction_operable.nil?
        window.fraction_operable = Airflow.get_default_fraction_of_windows_operable()
      end
    end
  end

  def self.apply_skylights(hpxml)
    hpxml.skylights.each do |skylight|
      if skylight.interior_shading_factor_summer.nil?
        skylight.interior_shading_factor_summer = 1.0
      end
      if skylight.interior_shading_factor_winter.nil?
        skylight.interior_shading_factor_winter = 1.0
      end
    end
  end

  def self.apply_hvac(hpxml)
    # Default AC/HP compressor type
    hpxml.cooling_systems.each do |cooling_system|
      next unless cooling_system.cooling_system_type == HPXML::HVACTypeCentralAirConditioner
      next unless cooling_system.compressor_type.nil?

      cooling_system.compressor_type = HVAC.get_default_compressor_type(cooling_system.cooling_efficiency_seer)
    end
    hpxml.heat_pumps.each do |heat_pump|
      next unless heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir
      next unless heat_pump.compressor_type.nil?

      heat_pump.compressor_type = HVAC.get_default_compressor_type(heat_pump.cooling_efficiency_seer)
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
      elsif cooling_system.cooling_system_type == HPXML::HVACTypeRoomAirConditioner
        cooling_system.cooling_shr = 0.65
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
      elsif heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpMiniSplit
        heat_pump.cooling_shr = 0.73
      elsif heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
        heat_pump.cooling_shr = 0.732
      end
    end

    # HVAC capacities
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

    # TODO: Default HeatingCapacity17F
    # TODO: Default Electric Auxiliary Energy (EAE; requires autosized HVAC capacity)
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
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir

      # Default return registers
      if hvac_distribution.number_of_return_registers.nil?
        hvac_distribution.number_of_return_registers = ncfl # Add 1 return register per conditioned floor if not provided
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
                                          duct_surface_area: secondary_duct_area)
            end
          end
        end
      end
    end
  end

  def self.apply_water_heaters(hpxml, nbeds, eri_version)
    hpxml.water_heating_systems.each do |water_heating_system|
      if water_heating_system.temperature.nil?
        water_heating_system.temperature = Waterheater.get_default_hot_water_temperature(eri_version)
      end
      if water_heating_system.performance_adjustment.nil?
        water_heating_system.performance_adjustment = Waterheater.get_default_performance_adjustment(water_heating_system)
      end
      if (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeCombiStorage) && water_heating_system.standby_loss.nil?
        # Use equation fit from AHRI database
        # calculate independent variable SurfaceArea/vol(physically linear to standby_loss/skin_u under test condition) to fit the linear equation from AHRI database
        act_vol = Waterheater.calc_storage_tank_actual_vol(water_heating_system.tank_volume, nil)
        surface_area = Waterheater.calc_tank_areas(act_vol)[0]
        sqft_by_gal = surface_area / act_vol # sqft/gal
        water_heating_system.standby_loss = (2.9721 * sqft_by_gal - 0.4732).round(3) # linear equation assuming a constant u, F/hr
      end
      if (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage)
        if water_heating_system.heating_capacity.nil?
          water_heating_system.heating_capacity = Waterheater.get_default_heating_capacity(water_heating_system.fuel_type, nbeds, hpxml.water_heating_systems.size, hpxml.building_construction.number_of_bathrooms) * 1000.0
        end
        if water_heating_system.tank_volume.nil?
          water_heating_system.tank_volume = Waterheater.get_default_tank_volume(water_heating_system.fuel_type, nbeds, hpxml.building_construction.number_of_bathrooms)
        end
        if water_heating_system.recovery_efficiency.nil?
          water_heating_system.recovery_efficiency = Waterheater.get_default_recovery_efficiency(water_heating_system)
        end
      end
      if water_heating_system.location.nil?
        water_heating_system.location = Waterheater.get_default_location(hpxml, hpxml.climate_and_risk_zones.iecc_zone)
      end
    end
  end

  def self.apply_hot_water_distribution(hpxml, cfa, ncfl, has_uncond_bsmnt)
    return if hpxml.hot_water_distributions.size == 0

    hot_water_distribution = hpxml.hot_water_distributions[0]
    if hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      if hot_water_distribution.standard_piping_length.nil?
        hot_water_distribution.standard_piping_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
      end
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      if hot_water_distribution.recirculation_piping_length.nil?
        hot_water_distribution.recirculation_piping_length = HotWaterAndAppliances.get_default_recirc_loop_length(HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl))
      end
      if hot_water_distribution.recirculation_branch_piping_length.nil?
        hot_water_distribution.recirculation_branch_piping_length = HotWaterAndAppliances.get_default_recirc_branch_loop_length()
      end
      if hot_water_distribution.recirculation_pump_power.nil?
        hot_water_distribution.recirculation_pump_power = HotWaterAndAppliances.get_default_recirc_pump_power()
      end
    end
  end

  def self.apply_water_fixtures(hpxml)
    if hpxml.water_heating.water_fixtures_usage_multiplier.nil?
      hpxml.water_heating.water_fixtures_usage_multiplier = 1.0
    end
  end

  def self.apply_solar_thermal_systems(hpxml)
    return if hpxml.solar_thermal_systems.size == 0

    solar_thermal_system = hpxml.solar_thermal_systems[0]
    collector_area = solar_thermal_system.collector_area

    if not collector_area.nil? # Detailed solar water heater
      if solar_thermal_system.storage_volume.nil?
        solar_thermal_system.storage_volume = Waterheater.calc_default_solar_thermal_system_storage_volume(collector_area)
      end
    end
  end

  def self.apply_ventilation_fans(hpxml)
    # Default kitchen fan
    hpxml.ventilation_fans.each do |vent_fan|
      next unless (vent_fan.used_for_local_ventilation && (vent_fan.fan_location == HPXML::LocationKitchen))

      if vent_fan.rated_flow_rate.nil?
        vent_fan.rated_flow_rate = 100.0 # cfm, per BA HSP
      end
      if vent_fan.hours_in_operation.nil?
        vent_fan.hours_in_operation = 1.0 # hrs/day, per BA HSP
      end
      if vent_fan.fan_power.nil?
        vent_fan.fan_power = 0.3 * vent_fan.rated_flow_rate # W, per BA HSP
      end
      if vent_fan.start_hour.nil?
        vent_fan.start_hour = 18 # 6 pm, per BA HSP
      end
    end

    # Default bath fans
    hpxml.ventilation_fans.each do |vent_fan|
      next unless (vent_fan.used_for_local_ventilation && (vent_fan.fan_location == HPXML::LocationBath))

      if vent_fan.quantity.nil?
        vent_fan.quantity = hpxml.building_construction.number_of_bathrooms
      end
      if vent_fan.rated_flow_rate.nil?
        vent_fan.rated_flow_rate = 50.0 # cfm, per BA HSP
      end
      if vent_fan.hours_in_operation.nil?
        vent_fan.hours_in_operation = 1.0 # hrs/day, per BA HSP
      end
      if vent_fan.fan_power.nil?
        vent_fan.fan_power = 0.3 * vent_fan.rated_flow_rate # W, per BA HSP
      end
      if vent_fan.start_hour.nil?
        vent_fan.start_hour = 7 # 7 am, per BA HSP
      end
    end
  end

  def self.apply_ceiling_fans(hpxml, nbeds)
    return if hpxml.ceiling_fans.size == 0

    ceiling_fan = hpxml.ceiling_fans[0]
    if ceiling_fan.efficiency.nil?
      medium_cfm = 3000.0
      ceiling_fan.efficiency = medium_cfm / HVAC.get_default_ceiling_fan_power()
    end
    if ceiling_fan.quantity.nil?
      ceiling_fan.quantity = HVAC.get_default_ceiling_fan_quantity(nbeds)
    end
  end

  def self.apply_plug_loads(hpxml, cfa, nbeds)
    hpxml.plug_loads.each do |plug_load|
      if plug_load.plug_load_type == HPXML::PlugLoadTypeOther
        default_annual_kwh, default_sens_frac, default_lat_frac = MiscLoads.get_residual_mels_default_values(cfa)
        if plug_load.kWh_per_year.nil?
          plug_load.kWh_per_year = default_annual_kwh
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = default_sens_frac
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = default_lat_frac
        end
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeTelevision
        default_annual_kwh, default_sens_frac, default_lat_frac = MiscLoads.get_televisions_default_values(cfa, nbeds)
        if plug_load.kWh_per_year.nil?
          plug_load.kWh_per_year = default_annual_kwh
        end
      end
      if plug_load.usage_multiplier.nil?
        plug_load.usage_multiplier = 1.0
      end
    end
    if hpxml.misc_loads_schedule.weekday_fractions.nil?
      hpxml.misc_loads_schedule.weekday_fractions = '0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05'
    end
    if hpxml.misc_loads_schedule.weekend_fractions.nil?
      hpxml.misc_loads_schedule.weekend_fractions = '0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05'
    end
    if hpxml.misc_loads_schedule.monthly_multipliers.nil?
      hpxml.misc_loads_schedule.monthly_multipliers = '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248'
    end
  end

  def self.apply_appliances(hpxml, nbeds, eri_version)
    # Default clothes washer
    if hpxml.clothes_washers.size > 0
      clothes_washer = hpxml.clothes_washers[0]
      if clothes_washer.location.nil?
        clothes_washer.location = HPXML::LocationLivingSpace
      end
      if clothes_washer.rated_annual_kwh.nil?
        default_values = HotWaterAndAppliances.get_clothes_washer_default_values(eri_version)
        clothes_washer.integrated_modified_energy_factor = default_values[:integrated_modified_energy_factor]
        clothes_washer.rated_annual_kwh = default_values[:rated_annual_kwh]
        clothes_washer.label_electric_rate = default_values[:label_electric_rate]
        clothes_washer.label_gas_rate = default_values[:label_gas_rate]
        clothes_washer.label_annual_gas_cost = default_values[:label_annual_gas_cost]
        clothes_washer.capacity = default_values[:capacity]
        clothes_washer.label_usage = default_values[:label_usage]
      end
      if clothes_washer.usage_multiplier.nil?
        clothes_washer.usage_multiplier = 1.0
      end
    end

    # Default clothes dryer
    if hpxml.clothes_dryers.size > 0
      clothes_dryer = hpxml.clothes_dryers[0]
      if clothes_dryer.location.nil?
        clothes_dryer.location = HPXML::LocationLivingSpace
      end
      if clothes_dryer.control_type.nil?
        default_values = HotWaterAndAppliances.get_clothes_dryer_default_values(eri_version, clothes_dryer.fuel_type)
        clothes_dryer.control_type = default_values[:control_type]
        clothes_dryer.combined_energy_factor = default_values[:combined_energy_factor]
      end
      if clothes_dryer.usage_multiplier.nil?
        clothes_dryer.usage_multiplier = 1.0
      end
    end

    # Default dishwasher
    if hpxml.dishwashers.size > 0
      dishwasher = hpxml.dishwashers[0]
      if dishwasher.location.nil?
        dishwasher.location = HPXML::LocationLivingSpace
      end
      if dishwasher.place_setting_capacity.nil?
        default_values = HotWaterAndAppliances.get_dishwasher_default_values()
        dishwasher.rated_annual_kwh = default_values[:rated_annual_kwh]
        dishwasher.label_electric_rate = default_values[:label_electric_rate]
        dishwasher.label_gas_rate = default_values[:label_gas_rate]
        dishwasher.label_annual_gas_cost = default_values[:label_annual_gas_cost]
        dishwasher.label_usage = default_values[:label_usage]
        dishwasher.place_setting_capacity = default_values[:place_setting_capacity]
      end
      if dishwasher.usage_multiplier.nil?
        dishwasher.usage_multiplier = 1.0
      end
    end

    # Default refrigerator
    if hpxml.refrigerators.size > 0
      refrigerator = hpxml.refrigerators[0]
      if refrigerator.location.nil?
        refrigerator.location = HPXML::LocationLivingSpace
      end
      if refrigerator.adjusted_annual_kwh.nil? && refrigerator.rated_annual_kwh.nil?
        default_values = HotWaterAndAppliances.get_refrigerator_default_values(nbeds)
        refrigerator.rated_annual_kwh = default_values[:rated_annual_kwh]
      end
      if refrigerator.usage_multiplier.nil?
        refrigerator.usage_multiplier = 1.0
      end
      if refrigerator.weekday_fractions.nil?
        refrigerator.weekday_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
      end
      if refrigerator.weekend_fractions.nil?
        refrigerator.weekend_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
      end
      if refrigerator.monthly_multipliers.nil?
        refrigerator.monthly_multipliers = '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
      end
    end

    # Default cooking range
    if hpxml.cooking_ranges.size > 0
      cooking_range = hpxml.cooking_ranges[0]
      if cooking_range.location.nil?
        cooking_range.location = HPXML::LocationLivingSpace
      end
      if cooking_range.is_induction.nil?
        default_values = HotWaterAndAppliances.get_range_oven_default_values()
        cooking_range.is_induction = default_values[:is_induction]
      end
      if cooking_range.usage_multiplier.nil?
        cooking_range.usage_multiplier = 1.0
      end
      if cooking_range.weekday_fractions.nil?
        cooking_range.weekday_fractions = '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011'
      end
      if cooking_range.weekend_fractions.nil?
        cooking_range.weekend_fractions = '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011'
      end
      if cooking_range.monthly_multipliers.nil?
        cooking_range.monthly_multipliers = '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097'
      end
    end

    # Default oven
    if hpxml.ovens.size > 0
      oven = hpxml.ovens[0]
      if oven.is_convection.nil?
        default_values = HotWaterAndAppliances.get_range_oven_default_values()
        oven.is_convection = default_values[:is_convection]
      end
    end
  end

  def self.apply_lighting(hpxml)
    if hpxml.lighting.usage_multiplier.nil?
      hpxml.lighting.usage_multiplier = 1.0
    end
  end

  def self.apply_pv_systems(hpxml)
    hpxml.pv_systems.each do |pv_system|
      if pv_system.inverter_efficiency.nil?
        pv_system.inverter_efficiency = PV.get_default_inv_eff()
      end
      if pv_system.system_losses_fraction.nil?
        pv_system.system_losses_fraction = PV.get_default_system_losses(pv_system.year_modules_manufactured)
      end
    end
  end
end
