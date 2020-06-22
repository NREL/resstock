# frozen_string_literal: true

class HotWaterAndAppliances
  def self.apply(model, runner, weather, living_space,
                 cfa, nbeds, ncfl, has_uncond_bsmnt, clothes_washers,
                 clothes_dryers, dishwashers, refrigerators,
                 freezers, cooking_ranges, ovens, fixtures_usage_multiplier,
                 water_fixtures, water_heating_systems, hot_water_distribution,
                 solar_thermal_system, eri_version, dhw_map)

    # Map plant loops to sys_ids
    dhw_loops = {}
    dhw_map.each do |sys_id, dhw_objects|
      dhw_objects.each do |dhw_object|
        next unless dhw_object.is_a? OpenStudio::Model::PlantLoop

        dhw_loops[sys_id] = dhw_object
      end
    end

    # Calculate load fractions for each water heater
    dhw_loop_fracs = {}
    water_heating_systems.each do |water_heating_system|
      solar_fraction = Waterheater.get_water_heater_solar_fraction(water_heating_system, solar_thermal_system)
      dhw_load_frac = water_heating_system.fraction_dhw_load_served * (1.0 - solar_fraction)
      dhw_loop_fracs[water_heating_system.id] = dhw_load_frac
    end

    dist_type = hot_water_distribution.system_type unless hot_water_distribution.nil?

    if not dist_type.nil?
      water_use_connections = {}
      setpoint_scheds = {}

      dhw_loop_fracs.each do |sys_id, dhw_load_frac|
        dhw_loop = dhw_loops[sys_id]
        water_use_connections[dhw_loop] = OpenStudio::Model::WaterUseConnections.new(model)
        dhw_map[sys_id] << water_use_connections[dhw_loop]
        dhw_loop.addDemandBranchForComponent(water_use_connections[dhw_loop])

        # Get water heater setpoint schedule
        dhw_map[sys_id].each do |dhw_object|
          if dhw_object.is_a? OpenStudio::Model::WaterHeaterMixed
            setpoint_scheds[dhw_loop] = dhw_object.setpointTemperatureSchedule.get
          elsif dhw_object.is_a? OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser
            setpoint_scheds[dhw_loop] = dhw_object.compressorSetpointTemperatureSchedule
          end
        end
        fail 'Could not find setpoint schedule.' if setpoint_scheds[dhw_loop].nil?
      end

      fixtures_all_low_flow = true # default
      water_fixtures.each do |water_fixture|
        next unless [HPXML::WaterFixtureTypeShowerhead, HPXML::WaterFixtureTypeFaucet].include? water_fixture.water_fixture_type

        fixtures_all_low_flow = false if not water_fixture.low_flow
      end

      t_mix = 105.0 # F, Temperature of mixed water at fixtures

      # Calculate mixed water fractions
      # WH Setpoint: Weighted average by fraction DHW load served
      avg_setpoint_temp = 0.0
      water_heating_systems.each do |water_heating_system|
        avg_setpoint_temp += water_heating_system.temperature * water_heating_system.fraction_dhw_load_served
      end
      daily_wh_inlet_temperatures = calc_water_heater_daily_inlet_temperatures(weather, nbeds, hot_water_distribution, fixtures_all_low_flow)
      daily_wh_inlet_temperatures_c = daily_wh_inlet_temperatures.map { |t| UnitConversions.convert(t, 'F', 'C') }
      daily_mw_fractions = calc_mixed_water_daily_fractions(daily_wh_inlet_temperatures, avg_setpoint_temp, t_mix)

      # Schedules init
      start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(1), 1, model.getYearDescription.assumedYear)
      timestep_day = OpenStudio::Time.new(1, 0)
      # Replace mains water temperature schedule with water heater inlet temperature schedule.
      # These are identical unless there is a DWHR.
      time_series_tmains = OpenStudio::TimeSeries.new(start_date, timestep_day, OpenStudio::createVector(daily_wh_inlet_temperatures_c), 'C')
      schedule_tmains = OpenStudio::Model::ScheduleInterval.fromTimeSeries(time_series_tmains, model).get
      schedule_tmains.setName('mains temperature schedule')
      model.getSiteWaterMainsTemperature.setTemperatureSchedule(schedule_tmains)

      # Fixtures (showers, sinks, baths) + distribution waste
      fx_gpd = get_fixtures_gpd(eri_version, nbeds, fixtures_all_low_flow, daily_mw_fractions)
      fx_gpd *= fixtures_usage_multiplier
      w_gpd = get_dist_waste_gpd(eri_version, nbeds, has_uncond_bsmnt, cfa, ncfl, hot_water_distribution, fixtures_all_low_flow)
      w_gpd *= fixtures_usage_multiplier # Fixture draws are the reason for most distribution waste, so scale this too

      mw_schedule = OpenStudio::Model::ScheduleConstant.new(model)
      mw_schedule.setValue(UnitConversions.convert(t_mix, 'F', 'C'))
      Schedule.set_schedule_type_limits(model, mw_schedule, Constants.ScheduleTypeLimitsTemperature)

      water_name = Constants.ObjectNameWater
      water_schedule = HotWaterSchedule.new(model, Constants.ObjectNameFixtures, nbeds)

      # Fixtures
      fx_name = Constants.ObjectNameFixtures
      fx_peak_flow = water_schedule.calcPeakFlowFromDailygpm(fx_gpd)
      dhw_loop_fracs.each do |sys_id, dhw_load_frac|
        dhw_loop = dhw_loops[sys_id]
        add_water_use_equipment(model, fx_name, fx_peak_flow * dhw_load_frac, water_schedule.schedule, mw_schedule, water_use_connections[dhw_loop])
      end

      # Distribution waste
      dist_water_name = Constants.ObjectNameDistributionWaste
      dist_water_peak_flow = water_schedule.calcPeakFlowFromDailygpm(w_gpd)
      dhw_loop_fracs.each do |sys_id, dhw_load_frac|
        dhw_loop = dhw_loops[sys_id]
        add_water_use_equipment(model, dist_water_name, dist_water_peak_flow * dhw_load_frac, water_schedule.schedule, mw_schedule, water_use_connections[dhw_loop])
      end

      # Internal gains
      # Floor mopping, shower evaporation, water films on showers, tubs & sinks surfaces, plant watering, etc.
      water_sens_btu, water_lat_btu = get_water_gains_sens_lat(nbeds)
      water_design_level_sens = water_schedule.calcDesignLevelFromDailykWh(UnitConversions.convert(water_sens_btu, 'Btu', 'kWh') / 365.0)
      water_design_level_lat = water_schedule.calcDesignLevelFromDailykWh(UnitConversions.convert(water_lat_btu, 'Btu', 'kWh') / 365.0)
      add_other_equipment(model, "#{water_name} Sensible", living_space, water_design_level_sens, 1.0, 0.0, water_schedule.schedule, nil)
      add_other_equipment(model, "#{water_name} Latent", living_space, water_design_level_lat, 0.0, 1.0, water_schedule.schedule, nil)

      # Recirculation pump
      dist_pump_annual_kwh = get_hwdist_recirc_pump_energy(hot_water_distribution)
      if dist_pump_annual_kwh > 0
        dist_pump_name = Constants.ObjectNameHotWaterRecircPump
        dist_pump_weekday_sch = '0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024'
        dist_pump_monthly_sch = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
        dist_pump_schedule = MonthWeekdayWeekendSchedule.new(model, dist_pump_name, dist_pump_weekday_sch, dist_pump_weekday_sch, dist_pump_monthly_sch, 1.0, 1.0)
        dist_pump_design_level = dist_pump_schedule.calcDesignLevelFromDailykWh(dist_pump_annual_kwh / 365.0)
        dhw_loop_fracs.each do |sys_id, dhw_load_frac|
          dist_pump = add_electric_equipment(model, dist_pump_name, living_space, dist_pump_design_level * dhw_load_frac, 0.0, 0.0, dist_pump_schedule.schedule)
          dhw_map[sys_id] << dist_pump unless dist_pump.nil?
        end
      end

      # Clothes washer
      if not clothes_washers.empty?
        clothes_washer = clothes_washers[0]

        cw_annual_kwh, cw_frac_sens, cw_frac_lat, cw_gpd = calc_clothes_washer_energy_gpd(eri_version, nbeds, clothes_washer, clothes_washer.additional_properties.space.nil?)
        cw_name = Constants.ObjectNameClothesWasher
        cw_schedule = HotWaterSchedule.new(model, cw_name, nbeds)
        cw_peak_flow = cw_schedule.calcPeakFlowFromDailygpm(cw_gpd)
        cw_design_level_w = cw_schedule.calcDesignLevelFromDailykWh(cw_annual_kwh / 365.0)

        cw_space = clothes_washer.additional_properties.space
        cw_space = living_space if cw_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space
        add_electric_equipment(model, cw_name, cw_space, cw_design_level_w, cw_frac_sens, cw_frac_lat, cw_schedule.schedule)
        dhw_loop_fracs.each do |sys_id, dhw_load_frac|
          dhw_loop = dhw_loops[sys_id]
          add_water_use_equipment(model, cw_name, cw_peak_flow * dhw_load_frac, cw_schedule.schedule, setpoint_scheds[dhw_loop], water_use_connections[dhw_loop])
        end
      end

      # Dishwasher
      if not dishwashers.empty?
        dishwasher = dishwashers[0]

        dw_annual_kwh, dw_frac_sens, dw_frac_lat, dw_gpd = calc_dishwasher_energy_gpd(eri_version, nbeds, dishwasher, dishwasher.additional_properties.space.nil?)
        dw_name = Constants.ObjectNameDishwasher
        dw_schedule = HotWaterSchedule.new(model, dw_name, nbeds)
        dw_peak_flow = dw_schedule.calcPeakFlowFromDailygpm(dw_gpd)
        dw_design_level_w = dw_schedule.calcDesignLevelFromDailykWh(dw_annual_kwh / 365.0)

        dw_space = dishwasher.additional_properties.space
        dw_space = living_space if dw_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space
        add_electric_equipment(model, dw_name, dw_space, dw_design_level_w, dw_frac_sens, dw_frac_lat, dw_schedule.schedule)
        dhw_loop_fracs.each do |sys_id, dhw_load_frac|
          dhw_loop = dhw_loops[sys_id]
          add_water_use_equipment(model, dw_name, dw_peak_flow * dhw_load_frac, dw_schedule.schedule, setpoint_scheds[dhw_loop], water_use_connections[dhw_loop])
        end
      end
    end

    # Clothes dryer
    if not clothes_dryers.empty?
      clothes_dryer = clothes_dryers[0]
      clothes_washer = clothes_washers[0]

      cd_annual_kwh, cd_annual_therm, cd_frac_sens, cd_frac_lat = calc_clothes_dryer_energy(eri_version, nbeds, clothes_dryer, clothes_washer, clothes_dryer.additional_properties.space.nil?)
      cd_name = Constants.ObjectNameClothesDryer
      cd_weekday_sch = '0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024'
      cd_monthly_sch = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
      cd_schedule = MonthWeekdayWeekendSchedule.new(model, cd_name, cd_weekday_sch, cd_weekday_sch, cd_monthly_sch, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)
      cd_design_level_e = cd_schedule.calcDesignLevelFromDailykWh(cd_annual_kwh / 365.0)
      cd_design_level_f = cd_schedule.calcDesignLevelFromDailyTherm(cd_annual_therm / 365.0)

      cd_space = clothes_dryer.additional_properties.space
      cd_space = living_space if cd_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space
      add_electric_equipment(model, cd_name, cd_space, cd_design_level_e, cd_frac_sens, cd_frac_lat, cd_schedule.schedule)
      add_other_equipment(model, cd_name, cd_space, cd_design_level_f, cd_frac_sens, cd_frac_lat, cd_schedule.schedule, clothes_dryer.fuel_type)
    end

    # Refrigerator
    if not refrigerators.empty?
      fridge_name = Constants.ObjectNameRefrigerator
      refrigerators.each do |refrigerator|
        rf_annual_kwh, rf_frac_sens, rf_frac_lat = calc_refrigerator_or_freezer_energy(refrigerator, refrigerator.additional_properties.space.nil?)
        fridge_weekday_sch = refrigerator.weekday_fractions
        fridge_weekend_sch = refrigerator.weekend_fractions
        fridge_monthly_sch = refrigerator.monthly_multipliers
        fridge_schedule = MonthWeekdayWeekendSchedule.new(model, fridge_name, fridge_weekday_sch, fridge_weekend_sch, fridge_monthly_sch, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)
        fridge_design_level = fridge_schedule.calcDesignLevelFromDailykWh(rf_annual_kwh / 365.0)

        rf_space = refrigerator.additional_properties.space
        rf_space = living_space if rf_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space
        add_electric_equipment(model, fridge_name, rf_space, fridge_design_level, rf_frac_sens, rf_frac_lat, fridge_schedule.schedule)
      end
    end

    # Freezer
    if not freezers.empty?
      freezer_name = Constants.ObjectNameFreezer
      freezers.each do |freezer|
        fz_annual_kwh, fz_frac_sens, fz_frac_lat = calc_refrigerator_or_freezer_energy(freezer, freezer.additional_properties.space.nil?)
        freezer_weekday_sch = freezer.weekday_fractions
        freezer_weekend_sch = freezer.weekend_fractions
        freezer_monthly_sch = freezer.monthly_multipliers
        freezer_schedule = MonthWeekdayWeekendSchedule.new(model, freezer_name, freezer_weekday_sch, freezer_weekend_sch, freezer_monthly_sch, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)
        freezer_design_level = freezer_schedule.calcDesignLevelFromDailykWh(fz_annual_kwh / 365.0)

        fz_space = freezer.additional_properties.space
        fz_space = living_space if fz_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space
        add_electric_equipment(model, freezer_name, fz_space, freezer_design_level, fz_frac_sens, fz_frac_lat, freezer_schedule.schedule)
      end
    end

    # Cooking Range
    if not cooking_ranges.empty?
      cooking_range = cooking_ranges[0]
      oven = ovens[0]

      cook_annual_kwh, cook_annual_therm, cook_frac_sens, cook_frac_lat = calc_range_oven_energy(nbeds, cooking_range, oven, cooking_range.additional_properties.space.nil?)
      cook_name = Constants.ObjectNameCookingRange
      cook_weekday_sch = cooking_range.weekday_fractions
      cook_weekend_sch = cooking_range.weekend_fractions
      cook_monthly_sch = cooking_range.monthly_multipliers
      cook_schedule = MonthWeekdayWeekendSchedule.new(model, cook_name, cook_weekday_sch, cook_weekend_sch, cook_monthly_sch, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)
      cook_design_level_e = cook_schedule.calcDesignLevelFromDailykWh(cook_annual_kwh / 365.0)
      cook_design_level_f = cook_schedule.calcDesignLevelFromDailyTherm(cook_annual_therm / 365.0)

      cook_space = cooking_range.additional_properties.space
      cook_space = living_space if cook_space.nil? # appliance is outdoors, so we need to assign the equipment to an arbitrary space
      add_electric_equipment(model, cook_name, cook_space, cook_design_level_e, cook_frac_sens, cook_frac_lat, cook_schedule.schedule)
      add_other_equipment(model, cook_name, cook_space, cook_design_level_f, cook_frac_sens, cook_frac_lat, cook_schedule.schedule, cooking_range.fuel_type)
    end
  end

  def self.get_range_oven_default_values()
    return { is_induction: false,
             is_convection: false }
  end

  def self.calc_range_oven_energy(nbeds, cooking_range, oven, is_outside = false)
    if cooking_range.is_induction
      burner_ef = 0.91
    else
      burner_ef = 1.0
    end
    if oven.is_convection
      oven_ef = 0.95
    else
      oven_ef = 1.0
    end
    if cooking_range.fuel_type != HPXML::FuelTypeElectricity
      annual_kwh = 22.6 + 2.7 * nbeds
      annual_therm = oven_ef * (22.6 + 2.7 * nbeds)
    else
      annual_kwh = burner_ef * oven_ef * (331 + 39.0 * nbeds)
      annual_therm = 0.0
    end

    annual_kwh *= cooking_range.usage_multiplier
    annual_therm *= cooking_range.usage_multiplier

    if not is_outside
      frac_lost = 0.20
      if cooking_range.fuel_type == HPXML::FuelTypeElectricity
        frac_sens = (1.0 - frac_lost) * 0.90
      else
        elec_btu = UnitConversions.convert(annual_kwh, 'kWh', 'Btu')
        gas_btu = UnitConversions.convert(annual_therm, 'therm', 'Btu')
        frac_sens = (1.0 - frac_lost) * ((0.90 * elec_btu + 0.7942 * gas_btu) / (elec_btu + gas_btu))
      end
      frac_lat = 1.0 - frac_sens - frac_lost
    else # Internal gains outside unit
      frac_sens = 0.0
      frac_lat = 0.0
    end

    if not @runner.nil?
      @runner.registerWarning('Negative energy use calculated for cooking range/oven; this may indicate incorrect ENERGY GUIDE label inputs.') if (annual_kwh < 0) || (annual_therm < 0)
    end

    return annual_kwh, annual_therm, frac_sens, frac_lat
  end

  def self.get_dishwasher_default_values()
    return { rated_annual_kwh: 467.0, # kWh/yr
             label_electric_rate: 0.12, # $/kWh
             label_gas_rate: 1.09, # $/therm
             label_annual_gas_cost: 33.12, # $
             label_usage: 4.0, # cyc/week
             place_setting_capacity: 12.0 }
  end

  def self.calc_dishwasher_energy_gpd(eri_version, nbeds, dishwasher, is_outside = false)
    if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2019A')
      if dishwasher.rated_annual_kwh.nil?
        dishwasher.rated_annual_kwh = calc_dishwasher_annual_kwh_from_ef(dishwasher.energy_factor)
      end
      lcy = dishwasher.label_usage * 52.0
      kwh_per_cyc = ((dishwasher.label_annual_gas_cost * 0.5497 / dishwasher.label_gas_rate - dishwasher.rated_annual_kwh * dishwasher.label_electric_rate * 0.02504 / dishwasher.label_electric_rate) / (dishwasher.label_electric_rate * 0.5497 / dishwasher.label_gas_rate - 0.02504)) / lcy
      dwcpy = (88.4 + 34.9 * nbeds) * (12.0 / dishwasher.place_setting_capacity)
      annual_kwh = kwh_per_cyc * dwcpy

      gpd = (dishwasher.rated_annual_kwh - kwh_per_cyc * lcy) * 0.02504 * dwcpy / 365.0
    else
      if dishwasher.energy_factor.nil?
        dishwasher.energy_factor = calc_dishwasher_ef_from_annual_kwh(dishwasher.rated_annual_kwh)
      end
      dwcpy = (88.4 + 34.9 * nbeds) * (12.0 / dishwasher.place_setting_capacity)
      annual_kwh = ((86.3 + 47.73 / dishwasher.energy_factor) / 215.0) * dwcpy

      if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2014A')
        gpd = dwcpy * (4.6415 * (1.0 / dishwasher.energy_factor) - 1.9295) / 365.0
      else
        gpd = ((88.4 + 34.9 * nbeds) * 8.16 - (88.4 + 34.9 * nbeds) * 12.0 / dishwasher.place_setting_capacity * (4.6415 * (1.0 / dishwasher.energy_factor) - 1.9295)) / 365.0
      end
    end

    annual_kwh *= dishwasher.usage_multiplier
    gpd *= dishwasher.usage_multiplier

    if not is_outside
      frac_lost = 0.40
      frac_sens = (1.0 - frac_lost) * 0.50
      frac_lat = 1.0 - frac_sens - frac_lost
    else # Internal gains outside unit
      frac_sens = 0.0
      frac_lat = 0.0
    end

    if not @runner.nil?
      @runner.registerWarning('Negative energy use calculated for dishwasher; this may indicate incorrect ENERGY GUIDE label inputs.') if annual_kwh < 0
      @runner.registerWarning('Negative hot water use calculated for dishwasher; this may indicate incorrect ENERGY GUIDE label inputs.') if gpd < 0
    end

    return annual_kwh, frac_sens, frac_lat, gpd
  end

  def self.calc_dishwasher_ef_from_annual_kwh(annual_kwh)
    return 215.0 / annual_kwh
  end

  def self.calc_dishwasher_annual_kwh_from_ef(ef)
    return 215.0 / ef
  end

  def self.get_refrigerator_default_values(nbeds)
    return { rated_annual_kwh: 637.0 + 18.0 * nbeds } # kWh/yr
  end

  def self.get_extra_refrigerator_default_values
    return { rated_annual_kwh: 243.6 } # kWh/yr
  end

  def self.get_freezer_default_values
    return { rated_annual_kwh: 319.8 } # kWh/yr
  end

  def self.get_clothes_dryer_default_values(eri_version, fuel_type)
    if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2019A')
      return { combined_energy_factor: 3.01,
               control_type: HPXML::ClothesDryerControlTypeTimer }
    else
      if fuel_type == HPXML::FuelTypeElectricity
        return { combined_energy_factor: 2.62,
                 control_type: HPXML::ClothesDryerControlTypeTimer }
      else
        return { combined_energy_factor: 2.32,
                 control_type: HPXML::ClothesDryerControlTypeTimer }
      end
    end
  end

  def self.calc_clothes_dryer_energy(eri_version, nbeds, clothes_dryer, clothes_washer, is_outside = false)
    if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2019A')
      if clothes_dryer.combined_energy_factor.nil?
        clothes_dryer.combined_energy_factor = calc_clothes_dryer_cef_from_ef(clothes_dryer.energy_factor)
      end
      if clothes_washer.integrated_modified_energy_factor.nil?
        clothes_washer.integrated_modified_energy_factor = calc_clothes_washer_imef_from_mef(clothes_washer.modified_energy_factor)
      end
      rmc = (0.97 * (clothes_washer.capacity / clothes_washer.integrated_modified_energy_factor) - clothes_washer.rated_annual_kwh / 312.0) / ((2.0104 * clothes_washer.capacity + 1.4242) * 0.455) + 0.04
      acy = (164.0 + 46.5 * nbeds) * ((3.0 * 2.08 + 1.59) / (clothes_washer.capacity * 2.08 + 1.59))
      annual_kwh = (((rmc - 0.04) * 100) / 55.5) * (8.45 / clothes_dryer.combined_energy_factor) * acy
      if clothes_dryer.fuel_type == HPXML::FuelTypeElectricity
        annual_therm = 0.0
      else
        annual_therm = annual_kwh * 3412.0 * (1.0 - 0.07) * (3.73 / 3.30) / 100000
        annual_kwh = annual_kwh * 0.07 * (3.73 / 3.30)
      end
    else
      if clothes_dryer.energy_factor.nil?
        clothes_dryer.energy_factor = calc_clothes_dryer_ef_from_cef(clothes_dryer.combined_energy_factor)
      end
      if clothes_washer.modified_energy_factor.nil?
        clothes_washer.modified_energy_factor = calc_clothes_washer_mef_from_imef(clothes_washer.integrated_modified_energy_factor)
      end
      if clothes_dryer.control_type == HPXML::ClothesDryerControlTypeTimer
        field_util_factor = 1.18
      elsif clothes_dryer.control_type == HPXML::ClothesDryerControlTypeMoisture
        field_util_factor = 1.04
      end
      if clothes_dryer.fuel_type == HPXML::FuelTypeElectricity
        annual_kwh = 12.5 * (164.0 + 46.5 * nbeds) * (field_util_factor / clothes_dryer.energy_factor) * ((clothes_washer.capacity / clothes_washer.modified_energy_factor) - clothes_washer.rated_annual_kwh / 392.0) / (0.2184 * (clothes_washer.capacity * 4.08 + 0.24))
        annual_therm = 0.0
      else
        annual_kwh = 12.5 * (164.0 + 46.5 * nbeds) * (field_util_factor / 3.01) * ((clothes_washer.capacity / clothes_washer.modified_energy_factor) - clothes_washer.rated_annual_kwh / 392.0) / (0.2184 * (clothes_washer.capacity * 4.08 + 0.24))
        annual_therm = annual_kwh * 3412.0 * (1.0 - 0.07) * (3.01 / clothes_dryer.energy_factor) / 100000
        annual_kwh = annual_kwh * 0.07 * (3.01 / clothes_dryer.energy_factor)
      end
    end

    annual_kwh *= clothes_dryer.usage_multiplier
    annual_therm *= clothes_dryer.usage_multiplier

    if not is_outside
      frac_lost = 0.85
      if clothes_dryer.fuel_type == HPXML::FuelTypeElectricity
        frac_sens = (1.0 - frac_lost) * 0.90
      else
        elec_btu = UnitConversions.convert(annual_kwh, 'kWh', 'Btu')
        gas_btu = UnitConversions.convert(annual_therm, 'therm', 'Btu')
        frac_sens = (1.0 - frac_lost) * ((0.90 * elec_btu + 0.8894 * gas_btu) / (elec_btu + gas_btu))
      end
      frac_lat = 1.0 - frac_sens - frac_lost
    else # Internal gains outside unit
      frac_sens = 0.0
      frac_lat = 0.0
    end

    if not @runner.nil?
      @runner.registerWarning('Negative energy use calculated for clothes dryer; this may indicate incorrect ENERGY GUIDE label inputs.') if (annual_kwh < 0) || (annual_therm < 0)
    end

    return annual_kwh, annual_therm, frac_sens, frac_lat
  end

  def self.calc_clothes_dryer_cef_from_ef(ef)
    return ef / 1.15 # Interpretation on ANSI/RESNET/ICC 301-2014 Clothes Dryer CEF
  end

  def self.calc_clothes_dryer_ef_from_cef(cef)
    return cef * 1.15 # Interpretation on ANSI/RESNET/ICC 301-2014 Clothes Dryer CEF
  end

  def self.get_clothes_washer_default_values(eri_version)
    if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2019A')
      return { integrated_modified_energy_factor: 1.0, # ft3/(kWh/cyc)
               rated_annual_kwh: 400.0, # kWh/yr
               label_electric_rate: 0.12, # $/kWh
               label_gas_rate: 1.09, # $/therm
               label_annual_gas_cost: 27.0, # $
               capacity: 3.0, # ft^3
               label_usage: 6.0 } # cyc/week
    else
      return { integrated_modified_energy_factor: 0.331, # ft3/(kWh/cyc)
               rated_annual_kwh: 704.0, # kWh/yr
               label_electric_rate: 0.08, # $/kWh, unused
               label_gas_rate: 0.58, # $/therm, unused
               label_annual_gas_cost: 23.0, # $, unused
               capacity: 2.874, # ft^3
               label_usage: 6.0 } # cyc/week, unused
    end
  end

  def self.calc_clothes_washer_energy_gpd(eri_version, nbeds, clothes_washer, is_outside = false)
    if Constants.ERIVersions.index(eri_version) >= Constants.ERIVersions.index('2019A')
      gas_h20 = 0.3914 # (gal/cyc) per (therm/y)
      elec_h20 = 0.0178 # (gal/cyc) per (kWh/y)
      lcy = clothes_washer.label_usage * 52.0 # label cycles per year
      scy = 164.0 + nbeds * 46.5
      acy = scy * ((3.0 * 2.08 + 1.59) / (clothes_washer.capacity * 2.08 + 1.59)) # Annual Cycles per Year
      cw_appl = (clothes_washer.label_annual_gas_cost * gas_h20 / clothes_washer.label_gas_rate - (clothes_washer.rated_annual_kwh * clothes_washer.label_electric_rate) * elec_h20 / clothes_washer.label_electric_rate) / (clothes_washer.label_electric_rate * gas_h20 / clothes_washer.label_gas_rate - elec_h20)
      annual_kwh = cw_appl / lcy * acy

      gpd = (clothes_washer.rated_annual_kwh - cw_appl) * elec_h20 * acy / 365.0
    else
      ncy = (3.0 / 2.874) * (164 + nbeds * 46.5)
      acy = ncy * ((3.0 * 2.08 + 1.59) / (clothes_washer.capacity * 2.08 + 1.59)) # Adjusted Cycles per Year
      annual_kwh = ((clothes_washer.rated_annual_kwh / 392.0) - ((clothes_washer.rated_annual_kwh * clothes_washer.label_electric_rate - clothes_washer.label_annual_gas_cost) / (21.9825 * clothes_washer.label_electric_rate - clothes_washer.label_gas_rate) / 392.0) * 21.9825) * acy

      gpd = 60.0 * ((clothes_washer.rated_annual_kwh * clothes_washer.label_electric_rate - clothes_washer.label_annual_gas_cost) / (21.9825 * clothes_washer.label_electric_rate - clothes_washer.label_gas_rate) / 392.0) * acy / 365.0
      if Constants.ERIVersions.index(eri_version) < Constants.ERIVersions.index('2014A')
        gpd -= 3.97 # Section 4.2.2.5.2.10
      end
    end

    annual_kwh *= clothes_washer.usage_multiplier
    gpd *= clothes_washer.usage_multiplier

    if not is_outside
      frac_lost = 0.70
      frac_sens = (1.0 - frac_lost) * 0.90
      frac_lat = 1.0 - frac_sens - frac_lost
    else # Internal gains outside unit
      frac_sens = 0.0
      frac_lat = 0.0
    end

    if not @runner.nil?
      @runner.registerWarning('Negative energy use calculated for clothes washer; this may indicate incorrect ENERGY GUIDE label inputs.') if annual_kwh < 0
      @runner.registerWarning('Negative hot water use calculated for clothes washer; this may indicate incorrect ENERGY GUIDE label inputs.') if gpd < 0
    end

    return annual_kwh, frac_sens, frac_lat, gpd
  end

  def self.calc_clothes_washer_imef_from_mef(mef)
    return (mef - 0.503) / 0.95 # Interpretation on ANSI/RESNET 301-2014 Clothes Washer IMEF
  end

  def self.calc_clothes_washer_mef_from_imef(imef)
    return 0.503 + 0.95 * imef # Interpretation on ANSI/RESNET 301-2014 Clothes Washer IMEF
  end

  def self.calc_refrigerator_or_freezer_energy(refrigerator_or_freezer, is_outside = false)
    # Get values
    annual_kwh = refrigerator_or_freezer.adjusted_annual_kwh
    if annual_kwh.nil?
      annual_kwh = refrigerator_or_freezer.rated_annual_kwh
    end

    annual_kwh *= refrigerator_or_freezer.usage_multiplier
    if not is_outside
      frac_sens = 1.0
      frac_lat = 0.0
    else # Internal gains outside unit
      frac_sens = 0.0
      frac_lat = 0.0
    end

    if not @runner.nil?
      @runner.registerWarning('Negative energy use calculated for refrigerator; this may indicate incorrect ENERGY GUIDE label inputs.') if annual_kwh < 0
    end

    return annual_kwh, frac_sens, frac_lat
  end

  def self.get_dist_energy_consumption_adjustment(has_uncond_bsmnt, cfa, ncfl,
                                                  hot_water_distribution)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # Eq. 4.2-16
    ew_fact = get_dist_energy_waste_factor(hot_water_distribution)
    o_frac = 0.25 # fraction of hot water waste from standard operating conditions
    oew_fact = ew_fact * o_frac # standard operating condition portion of hot water energy waste
    ocd_eff = 0.0
    sew_fact = ew_fact - oew_fact
    ref_pipe_l = get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
    if hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      pe_ratio = hot_water_distribution.standard_piping_length / ref_pipe_l
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      ref_loop_l = get_default_recirc_loop_length(ref_pipe_l)
      pe_ratio = hot_water_distribution.recirculation_piping_length / ref_loop_l
    end
    e_waste = oew_fact * (1.0 - ocd_eff) + sew_fact * pe_ratio
    return (e_waste + 128.0) / 160.0
  end

  def self.get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    bsmnt = has_uncond_bsmnt ? 1 : 0
    return 2.0 * (cfa / ncfl)**0.5 + 10.0 * ncfl + 5.0 * bsmnt # Eq. 4.2-13 (refPipeL)
  end

  def self.get_default_recirc_loop_length(std_pipe_length)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    return 2.0 * std_pipe_length - 20.0 # Eq. 4.2-17 (refLoopL)
  end

  def self.get_default_recirc_branch_loop_length()
    return 10.0  # ft
  end

  def self.get_default_recirc_pump_power()
    return 50.0  # Watts
  end

  private

  def self.add_electric_equipment(model, obj_name, space, design_level_w, frac_sens, frac_lat, schedule)
    return if design_level_w == 0.0

    ee_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    ee = OpenStudio::Model::ElectricEquipment.new(ee_def)
    ee.setName(obj_name)
    ee.setEndUseSubcategory(obj_name)
    ee.setSpace(space)
    ee_def.setName(obj_name)
    ee_def.setDesignLevel(design_level_w)
    ee_def.setFractionRadiant(0.6 * frac_sens)
    ee_def.setFractionLatent(frac_lat)
    ee_def.setFractionLost(1.0 - frac_sens - frac_lat)
    ee.setSchedule(schedule)

    return ee
  end

  def self.add_other_equipment(model, obj_name, space, design_level_w, frac_sens, frac_lat, schedule, fuel_type)
    return if design_level_w == 0.0

    oe_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
    oe = OpenStudio::Model::OtherEquipment.new(oe_def)
    oe.setName(obj_name)
    oe.setEndUseSubcategory(obj_name)
    if fuel_type.nil?
      oe.setFuelType('None')
    else
      oe.setFuelType(HelperMethods.eplus_fuel_map(fuel_type))
    end
    oe.setSpace(space)
    oe_def.setName(obj_name)
    oe_def.setDesignLevel(design_level_w)
    oe_def.setFractionRadiant(0.6 * frac_sens)
    oe_def.setFractionLatent(frac_lat)
    oe_def.setFractionLost(1.0 - frac_sens - frac_lat)
    oe.setSchedule(schedule)

    return oe
  end

  def self.add_water_use_equipment(model, obj_name, peak_flow, schedule, temp_schedule, water_use_connection)
    return if peak_flow == 0.0

    wu_def = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
    wu = OpenStudio::Model::WaterUseEquipment.new(wu_def)
    wu.setName(obj_name)
    wu_def.setName(obj_name)
    wu_def.setPeakFlowRate(peak_flow)
    wu_def.setEndUseSubcategory(obj_name)
    wu.setFlowRateFractionSchedule(schedule)
    wu_def.setTargetTemperatureSchedule(temp_schedule)
    water_use_connection.addWaterUseEquipment(wu)

    return wu
  end

  def self.get_dwhr_factors(nbeds, hot_water_distribution, fixtures_all_low_flow)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # Eq. 4.2-14

    eff_adj = 1.0
    if fixtures_all_low_flow
      eff_adj = 1.082
    end

    iFrac = 0.56 + 0.015 * nbeds - 0.0004 * nbeds**2 # fraction of hot water use impacted by DWHR

    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      pLength = hot_water_distribution.recirculation_branch_piping_length
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      pLength = hot_water_distribution.standard_piping_length
    end
    plc = 1 - 0.0002 * pLength # piping loss coefficient

    # Location factors for DWHR placement
    if hot_water_distribution.dwhr_equal_flow
      locF = 1.000
    else
      locF = 0.777
    end

    # Fixture Factor
    if hot_water_distribution.dwhr_facilities_connected == HPXML::DWHRFacilitiesConnectedAll
      fixF = 1.0
    elsif hot_water_distribution.dwhr_facilities_connected == HPXML::DWHRFacilitiesConnectedOne
      fixF = 0.5
    end

    return eff_adj, iFrac, plc, locF, fixF
  end

  def self.calc_water_heater_daily_inlet_temperatures(weather, nbeds, hot_water_distribution, fixtures_all_low_flow)
    # Get daily mains temperatures
    avgOAT = weather.data.AnnualAvgDrybulb
    maxDiffMonthlyAvgOAT = weather.data.MonthlyAvgDrybulbs.max - weather.data.MonthlyAvgDrybulbs.min
    tmains_daily = WeatherProcess.calc_mains_temperatures(avgOAT, maxDiffMonthlyAvgOAT, weather.header.Latitude)[2]

    wh_temps_daily = tmains_daily
    if (not hot_water_distribution.dwhr_efficiency.nil?)
      dwhr_eff_adj, dwhr_iFrac, dwhr_plc, dwhr_locF, dwhr_fixF = get_dwhr_factors(nbeds, hot_water_distribution, fixtures_all_low_flow)
      # Adjust inlet temperatures
      dwhr_inT = 97.0 # F
      for day in 0..364
        dwhr_WHinTadj = dwhr_iFrac * (dwhr_inT - tmains_daily[day]) * hot_water_distribution.dwhr_efficiency * dwhr_eff_adj * dwhr_plc * dwhr_locF * dwhr_fixF
        wh_temps_daily[day] = (wh_temps_daily[day] + dwhr_WHinTadj).round(3)
      end
    else
      for day in 0..364
        wh_temps_daily[day] = (wh_temps_daily[day]).round(3)
      end
    end

    return wh_temps_daily
  end

  def self.calc_mixed_water_daily_fractions(daily_wh_inlet_temperatures, tHot, tMix)
    adjFmix = []
    for day in 0..364
      adjFmix << (1.0 - ((tHot - tMix) / (tHot - daily_wh_inlet_temperatures[day]))).round(4)
    end

    return adjFmix
  end

  def self.get_hwdist_recirc_pump_energy(hot_water_distribution)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # Table 4.2.2.5.2.11(5) Annual electricity consumption factor for hot water recirculation system pumps
    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      if (hot_water_distribution.recirculation_control_type == HPXML::DHWRecirControlTypeNone) ||
         (hot_water_distribution.recirculation_control_type == HPXML::DHWRecirControlTypeTimer)
        return 8.76 * hot_water_distribution.recirculation_pump_power
      elsif hot_water_distribution.recirculation_control_type == HPXML::DHWRecirControlTypeTemperature
        return 1.46 * hot_water_distribution.recirculation_pump_power
      elsif hot_water_distribution.recirculation_control_type == HPXML::DHWRecirControlTypeSensor
        return 0.15 * hot_water_distribution.recirculation_pump_power
      elsif hot_water_distribution.recirculation_control_type == HPXML::DHWRecirControlTypeManual
        return 0.10 * hot_water_distribution.recirculation_pump_power
      end
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      return 0.0
    end
    fail 'Unexpected hot water distribution system.'
  end

  def self.get_fixtures_effectiveness(fixtures_all_low_flow)
    f_eff = fixtures_all_low_flow ? 0.95 : 1.0
    return f_eff
  end

  def self.get_fixtures_gpd(eri_version, nbeds, fixtures_all_low_flow, daily_mw_fractions)
    if Constants.ERIVersions.index(eri_version) < Constants.ERIVersions.index('2014A')
      hw_gpd = 30.0 + 10.0 * nbeds # Table 4.2.2(1) Service water heating systems
      # Convert to mixed water gpd
      avg_mw_fraction = daily_mw_fractions.reduce(:+) / daily_mw_fractions.size.to_f
      return hw_gpd / avg_mw_fraction
    end

    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    ref_f_gpd = 14.6 + 10.0 * nbeds # Eq. 4.2-2 (refFgpd)
    f_eff = get_fixtures_effectiveness(fixtures_all_low_flow)
    return f_eff * ref_f_gpd
  end

  def self.get_water_gains_sens_lat(nbeds)
    # Table 4.2.2(3). Internal Gains for Reference Homes
    sens_gains = -1227.0 - 409.0 * nbeds # Btu/day
    lat_gains = 1245.0 + 415.0 * nbeds # Btu/day
    return sens_gains * 365.0, lat_gains * 365.0
  end

  def self.get_dist_waste_gpd(eri_version, nbeds, has_uncond_bsmnt, cfa, ncfl,
                              hot_water_distribution, fixtures_all_low_flow)
    if Constants.ERIVersions.index(eri_version) <= Constants.ERIVersions.index('2014')
      return 0.0
    end

    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # 4.2.2.5.2.11 Service Hot Water Use

    # Table 4.2.2.5.2.11(2) Hot Water Distribution System Insulation Factors
    sys_factor = nil
    if (hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc) && (hot_water_distribution.pipe_r_value < 3.0)
      sys_factor = 1.11
    elsif (hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc) && (hot_water_distribution.pipe_r_value >= 3.0)
      sys_factor = 1.0
    elsif (hot_water_distribution.system_type == HPXML::DHWDistTypeStandard) && (hot_water_distribution.pipe_r_value >= 3.0)
      sys_factor = 0.90
    elsif (hot_water_distribution.system_type == HPXML::DHWDistTypeStandard) && (hot_water_distribution.pipe_r_value < 3.0)
      sys_factor = 1.0
    end

    ref_w_gpd = 9.8 * (nbeds**0.43) # Eq. 4.2-2 (refWgpd)
    o_frac = 0.25
    o_cd_eff = 0.0

    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      p_ratio = hot_water_distribution.recirculation_branch_piping_length / 10.0
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      ref_pipe_l = get_default_std_pipe_length(has_uncond_bsmnt, cfa, ncfl)
      p_ratio = hot_water_distribution.standard_piping_length / ref_pipe_l
    end

    o_w_gpd = ref_w_gpd * o_frac * (1.0 - o_cd_eff) # Eq. 4.2-12
    s_w_gpd = (ref_w_gpd - ref_w_gpd * o_frac) * p_ratio * sys_factor # Eq. 4.2-13

    # Table 4.2.2.5.2.11(3) Distribution system water use effectiveness
    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      wd_eff = 0.1
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      wd_eff = 1.0
    end

    f_eff = get_fixtures_effectiveness(fixtures_all_low_flow)

    mw_gpd = f_eff * (o_w_gpd + s_w_gpd * wd_eff) # Eq. 4.2-11

    return mw_gpd
  end

  def self.get_dist_energy_waste_factor(hot_water_distribution)
    # ANSI/RESNET 301-2014 Addendum A-2015
    # Amendment on Domestic Hot Water (DHW) Systems
    # Table 4.2.2.5.2.11(6) Hot water distribution system relative annual energy waste factors
    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      if (hot_water_distribution.recirculation_control_type == HPXML::DHWRecirControlTypeNone) ||
         (hot_water_distribution.recirculation_control_type == HPXML::DHWRecirControlTypeTimer)
        if hot_water_distribution.pipe_r_value < 3.0
          return 500.0
        else
          return 250.0
        end
      elsif hot_water_distribution.recirculation_control_type == HPXML::DHWRecirControlTypeTemperature
        if hot_water_distribution.pipe_r_value < 3.0
          return 375.0
        else
          return 187.5
        end
      elsif hot_water_distribution.recirculation_control_type == HPXML::DHWRecirControlTypeSensor
        if hot_water_distribution.pipe_r_value < 3.0
          return 64.8
        else
          return 43.2
        end
      elsif hot_water_distribution.recirculation_control_type == HPXML::DHWRecirControlTypeManual
        if hot_water_distribution.pipe_r_value < 3.0
          return 43.2
        else
          return 28.8
        end
      end
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      if hot_water_distribution.pipe_r_value < 3.0
        return 32.0
      else
        return 28.8
      end
    end
    fail 'Unexpected hot water distribution system.'
  end

  def self.get_default_extra_refrigerator_and_freezer_locations(hpxml)
    extra_refrigerator_location_hierarchy = [HPXML::LocationGarage,
                                             HPXML::LocationBasementUnconditioned,
                                             HPXML::LocationBasementConditioned,
                                             HPXML::LocationLivingSpace]

    extra_refrigerator_location = nil
    extra_refrigerator_location_hierarchy.each do |space_type|
      if hpxml.has_space_type(space_type)
        extra_refrigerator_location = space_type
        break
      end
    end

    return extra_refrigerator_location
  end
end
