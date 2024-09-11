# frozen_string_literal: true

# TODO
module MiscLoads
  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param plug_load [TODO] TODO
  # @param obj_name [String] Name for the OpenStudio object
  # @param conditioned_space [TODO] TODO
  # @param apply_ashrae140_assumptions [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [TODO] TODO
  def self.apply_plug(model, runner, plug_load, obj_name, conditioned_space, apply_ashrae140_assumptions, schedules_file, unavailable_periods)
    kwh = 0
    if not plug_load.nil?
      kwh = plug_load.kwh_per_year * plug_load.usage_multiplier
    end

    return if kwh <= 0

    # Create schedule
    sch = nil
    if plug_load.plug_load_type == HPXML::PlugLoadTypeOther
      col_name = SchedulesFile::Columns[:PlugLoadsOther].name
    elsif plug_load.plug_load_type == HPXML::PlugLoadTypeTelevision
      col_name = SchedulesFile::Columns[:PlugLoadsTV].name
    elsif plug_load.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging
      col_name = SchedulesFile::Columns[:PlugLoadsVehicle].name
    elsif plug_load.plug_load_type == HPXML::PlugLoadTypeWellPump
      col_name = SchedulesFile::Columns[:PlugLoadsWellPump].name
    end
    if not schedules_file.nil?
      space_design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: col_name, annual_kwh: kwh)
      sch = schedules_file.create_schedule_file(model, col_name: col_name)
    end
    if sch.nil?
      col_unavailable_periods = Schedule.get_unavailable_periods(runner, col_name, unavailable_periods)
      sch = MonthWeekdayWeekendSchedule.new(model, obj_name + ' schedule', plug_load.weekday_fractions, plug_load.weekend_fractions, plug_load.monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: col_unavailable_periods)
      space_design_level = sch.calc_design_level_from_daily_kwh(kwh / 365.0)
      sch = sch.schedule
    else
      runner.registerWarning("Both '#{col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !plug_load.weekday_fractions.nil?
      runner.registerWarning("Both '#{col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !plug_load.weekend_fractions.nil?
      runner.registerWarning("Both '#{col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !plug_load.monthly_multipliers.nil?
    end

    sens_frac = plug_load.frac_sensible
    lat_frac = plug_load.frac_latent

    if apply_ashrae140_assumptions
      # ASHRAE 140, Table 7-9. Sensible loads are 70% radiative and 30% convective.
      rad_frac = 0.7 * sens_frac
    else
      rad_frac = 0.6 * sens_frac
    end

    # Add electric equipment for the mel
    mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
    mel.setName(obj_name)
    mel.setEndUseSubcategory(obj_name)
    mel.setSpace(conditioned_space)
    mel_def.setName(obj_name)
    mel_def.setDesignLevel(space_design_level)
    mel_def.setFractionRadiant(rad_frac)
    mel_def.setFractionLatent(lat_frac)
    mel_def.setFractionLost(1 - sens_frac - lat_frac)
    mel.setSchedule(sch)
  end

  # TODO
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param fuel_load [TODO] TODO
  # @param obj_name [String] Name for the OpenStudio object
  # @param conditioned_space [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [TODO] TODO
  def self.apply_fuel(model, runner, fuel_load, obj_name, conditioned_space, schedules_file, unavailable_periods)
    therm = 0
    if not fuel_load.nil?
      therm = fuel_load.therm_per_year * fuel_load.usage_multiplier
    end

    return if therm <= 0

    # Create schedule
    sch = nil
    if fuel_load.fuel_load_type == HPXML::FuelLoadTypeGrill
      col_name = SchedulesFile::Columns[:FuelLoadsGrill].name
    elsif fuel_load.fuel_load_type == HPXML::FuelLoadTypeLighting
      col_name = SchedulesFile::Columns[:FuelLoadsLighting].name
    elsif fuel_load.fuel_load_type == HPXML::FuelLoadTypeFireplace
      col_name = SchedulesFile::Columns[:FuelLoadsFireplace].name
    end
    if not schedules_file.nil?
      space_design_level = schedules_file.calc_design_level_from_annual_therm(col_name: col_name, annual_therm: therm)
      sch = schedules_file.create_schedule_file(model, col_name: col_name)
    end
    if sch.nil?
      col_unavailable_periods = Schedule.get_unavailable_periods(runner, col_name, unavailable_periods)
      sch = MonthWeekdayWeekendSchedule.new(model, obj_name + ' schedule', fuel_load.weekday_fractions, fuel_load.weekend_fractions, fuel_load.monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: col_unavailable_periods)
      space_design_level = sch.calc_design_level_from_daily_therm(therm / 365.0)
      sch = sch.schedule
    else
      runner.registerWarning("Both '#{col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !fuel_load.weekday_fractions.nil?
      runner.registerWarning("Both '#{col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !fuel_load.weekend_fractions.nil?
      runner.registerWarning("Both '#{col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !fuel_load.monthly_multipliers.nil?
    end

    sens_frac = fuel_load.frac_sensible
    lat_frac = fuel_load.frac_latent

    # Add other equipment for the mfl
    mfl_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
    mfl = OpenStudio::Model::OtherEquipment.new(mfl_def)
    mfl.setName(obj_name)
    mfl.setEndUseSubcategory(obj_name)
    mfl.setFuelType(EPlus.fuel_type(fuel_load.fuel_type))
    mfl.setSpace(conditioned_space)
    mfl_def.setName(obj_name)
    mfl_def.setDesignLevel(space_design_level)
    mfl_def.setFractionRadiant(0.6 * sens_frac)
    mfl_def.setFractionLatent(lat_frac)
    mfl_def.setFractionLost(1 - sens_frac - lat_frac)
    mfl.setSchedule(sch)
  end

  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param pool_or_spa [TODO] TODO
  # @param conditioned_space [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [TODO] TODO
  def self.apply_pool_or_permanent_spa_heater(runner, model, pool_or_spa, conditioned_space, schedules_file, unavailable_periods)
    return if pool_or_spa.heater_type == HPXML::TypeNone

    heater_kwh = 0
    heater_therm = 0
    if pool_or_spa.heater_load_units == HPXML::UnitsKwhPerYear
      heater_kwh = pool_or_spa.heater_load_value * pool_or_spa.heater_usage_multiplier
    elsif pool_or_spa.heater_load_units == HPXML::UnitsThermPerYear
      heater_therm = pool_or_spa.heater_load_value * pool_or_spa.heater_usage_multiplier
    end

    return if (heater_kwh <= 0) && (heater_therm <= 0)

    # Create schedule
    heater_sch = nil
    if pool_or_spa.is_a? HPXML::Pool
      obj_name = Constants::ObjectTypeMiscPoolHeater
      col_name = 'pool_heater'
    else
      obj_name = Constants::ObjectTypeMiscPermanentSpaHeater
      col_name = 'permanent_spa_heater'
    end
    if not schedules_file.nil?
      heater_sch = schedules_file.create_schedule_file(model, col_name: col_name)
    end
    if heater_sch.nil?
      col_unavailable_periods = Schedule.get_unavailable_periods(runner, col_name, unavailable_periods)
      heater_sch = MonthWeekdayWeekendSchedule.new(model, obj_name + ' schedule', pool_or_spa.heater_weekday_fractions, pool_or_spa.heater_weekend_fractions, pool_or_spa.heater_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: col_unavailable_periods)
    else
      runner.registerWarning("Both '#{col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !pool_or_spa.heater_weekday_fractions.nil?
      runner.registerWarning("Both '#{col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !pool_or_spa.heater_weekend_fractions.nil?
      runner.registerWarning("Both '#{col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !pool_or_spa.heater_monthly_multipliers.nil?
    end

    if heater_kwh > 0
      if not schedules_file.nil?
        space_design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: col_name, annual_kwh: heater_kwh)
      end
      if space_design_level.nil?
        space_design_level = heater_sch.calc_design_level_from_daily_kwh(heater_kwh / 365.0)
        heater_sch = heater_sch.schedule
      end

      mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
      mel.setName(obj_name)
      mel.setEndUseSubcategory(obj_name)
      mel.setSpace(conditioned_space) # no heat gain, so assign the equipment to an arbitrary space
      mel_def.setName(obj_name)
      mel_def.setDesignLevel(space_design_level)
      mel_def.setFractionRadiant(0)
      mel_def.setFractionLatent(0)
      mel_def.setFractionLost(1)
      mel.setSchedule(heater_sch)
    end

    if heater_therm > 0
      if not schedules_file.nil?
        space_design_level = schedules_file.calc_design_level_from_annual_therm(col_name: col_name, annual_therm: heater_therm)
      end
      if space_design_level.nil?
        space_design_level = heater_sch.calc_design_level_from_daily_therm(heater_therm / 365.0)
        heater_sch = heater_sch.schedule
      end

      mfl_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      mfl = OpenStudio::Model::OtherEquipment.new(mfl_def)
      mfl.setName(obj_name)
      mfl.setEndUseSubcategory(obj_name)
      mfl.setFuelType(EPlus.fuel_type(HPXML::FuelTypeNaturalGas))
      mfl.setSpace(conditioned_space) # no heat gain, so assign the equipment to an arbitrary space
      mfl_def.setName(obj_name)
      mfl_def.setDesignLevel(space_design_level)
      mfl_def.setFractionRadiant(0)
      mfl_def.setFractionLatent(0)
      mfl_def.setFractionLost(1)
      mfl.setSchedule(heater_sch)
    end
  end

  # TODO
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param pool_or_spa [TODO] TODO
  # @param conditioned_space [TODO] TODO
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unavailable_periods [HPXML::UnavailablePeriods] Object that defines periods for, e.g., power outages or vacancies
  # @return [TODO] TODO
  def self.apply_pool_or_permanent_spa_pump(runner, model, pool_or_spa, conditioned_space, schedules_file, unavailable_periods)
    pump_kwh = 0
    if not pool_or_spa.pump_kwh_per_year.nil?
      pump_kwh = pool_or_spa.pump_kwh_per_year * pool_or_spa.pump_usage_multiplier
    end

    return if pump_kwh <= 0

    # Create schedule
    pump_sch = nil
    if pool_or_spa.is_a? HPXML::Pool
      obj_name = Constants::ObjectTypeMiscPoolPump
      col_name = 'pool_pump'
    else
      obj_name = Constants::ObjectTypeMiscPermanentSpaPump
      col_name = 'permanent_spa_pump'
    end
    if not schedules_file.nil?
      pump_sch = schedules_file.create_schedule_file(model, col_name: col_name)
    end
    if pump_sch.nil?
      col_unavailable_periods = Schedule.get_unavailable_periods(runner, col_name, unavailable_periods)
      pump_sch = MonthWeekdayWeekendSchedule.new(model, obj_name + ' schedule', pool_or_spa.pump_weekday_fractions, pool_or_spa.pump_weekend_fractions, pool_or_spa.pump_monthly_multipliers, EPlus::ScheduleTypeLimitsFraction, unavailable_periods: col_unavailable_periods)
    else
      runner.registerWarning("Both '#{col_name}' schedule file and weekday fractions provided; the latter will be ignored.") if !pool_or_spa.pump_weekday_fractions.nil?
      runner.registerWarning("Both '#{col_name}' schedule file and weekend fractions provided; the latter will be ignored.") if !pool_or_spa.pump_weekend_fractions.nil?
      runner.registerWarning("Both '#{col_name}' schedule file and monthly multipliers provided; the latter will be ignored.") if !pool_or_spa.pump_monthly_multipliers.nil?
    end

    if not schedules_file.nil?
      space_design_level = schedules_file.calc_design_level_from_annual_kwh(col_name: col_name, annual_kwh: pump_kwh)
    end
    if space_design_level.nil?
      space_design_level = pump_sch.calc_design_level_from_daily_kwh(pump_kwh / 365.0)
      pump_sch = pump_sch.schedule
    end

    mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
    mel.setName(obj_name)
    mel.setEndUseSubcategory(obj_name)
    mel.setSpace(conditioned_space) # no heat gain, so assign the equipment to an arbitrary space
    mel_def.setName(obj_name)
    mel_def.setDesignLevel(space_design_level)
    mel_def.setFractionRadiant(0)
    mel_def.setFractionLatent(0)
    mel_def.setFractionLost(1)
    mel.setSchedule(pump_sch)
  end

  # Returns the default residual miscellaneous electric (plug) load energy use
  # and sensible/latent fractions.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param num_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] HPXML::ResidentialTypeXXX type of dwelling unit
  # @return [Array<Double, Double, Double>] Plug loads annual use (kWh), sensible fraction, and latent fraction
  def self.get_residual_mels_default_values(cfa, num_occ = nil, unit_type = nil)
    if num_occ.nil? # Asset calculation
      # ANSI/RESNET/ICC 301
      annual_kwh = 0.91 * cfa
    else # Operational calculation
      # RECS 2020
      if unit_type == HPXML::ResidentialTypeSFD
        annual_kwh = 786.9 + 241.8 * num_occ + 0.33 * cfa
      elsif unit_type == HPXML::ResidentialTypeSFA
        annual_kwh = 654.9 + 206.5 * num_occ + 0.21 * cfa
      elsif unit_type == HPXML::ResidentialTypeApartment
        annual_kwh = 706.6 + 149.3 * num_occ + 0.10 * cfa
      elsif unit_type == HPXML::ResidentialTypeManufactured
        annual_kwh = 1795.1 # No good relationship found in RECS, so just using a constant value
      end
    end
    frac_lost = 0.10
    frac_sens = (1.0 - frac_lost) * 0.95
    frac_lat = 1.0 - frac_sens - frac_lost
    return annual_kwh, frac_sens, frac_lat
  end

  # Returns the default television energy use and sensible/latent fractions.
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param num_occ [Double] Number of occupants in the dwelling unit
  # @param unit_type [String] HPXML::ResidentialTypeXXX type of dwelling unit
  # @return [Array<Double, Double, Double>] Television annual use (kWh), sensible fraction, and latent fraction
  def self.get_televisions_default_values(cfa, nbeds, num_occ = nil, unit_type = nil)
    if num_occ.nil? # Asset calculation
      # ANSI/RESNET/ICC 301
      annual_kwh = 413.0 + 69.0 * nbeds
    else # Operational calculation
      # RECS 2020
      # Note: If we know # of televisions, we could use these better relationships instead:
      # - SFD: 67.7 + 243.4 * num_tv
      # - SFA: 13.3 + 251.3 * num_tv
      # - MF:  11.4 + 250.7 * num_tv
      # - MH:  12.6 + 287.5 * num_tv
      if unit_type == HPXML::ResidentialTypeSFD
        annual_kwh = 334.0 + 92.2 * num_occ + 0.06 * cfa
      elsif unit_type == HPXML::ResidentialTypeSFA
        annual_kwh = 283.9 + 80.1 * num_occ + 0.07 * cfa
      elsif unit_type == HPXML::ResidentialTypeApartment
        annual_kwh = 190.3 + 81.0 * num_occ + 0.11 * cfa
      elsif unit_type == HPXML::ResidentialTypeManufactured
        annual_kwh = 99.9 + 129.6 * num_occ + 0.21 * cfa
      end
    end
    frac_lost = 0.0
    frac_sens = (1.0 - frac_lost) * 1.0
    frac_lat = 1.0 - frac_sens - frac_lost
    return annual_kwh, frac_sens, frac_lat
  end

  # TODO
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [TODO] TODO
  def self.get_pool_pump_default_values(cfa, nbeds)
    return 158.6 / 0.070 * (0.5 + 0.25 * nbeds / 3.0 + 0.25 * cfa / 1920.0) # kWh/yr
  end

  # TODO
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param type [TODO] TODO
  # @return [TODO] TODO
  def self.get_pool_heater_default_values(cfa, nbeds, type)
    load_units = nil
    load_value = nil
    if [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include? type
      load_units = HPXML::UnitsKwhPerYear
      load_value = 8.3 / 0.004 * (0.5 + 0.25 * nbeds / 3.0 + 0.25 * cfa / 1920.0) # kWh/yr
      if type == HPXML::HeaterTypeHeatPump
        load_value /= 5.0 # Assume seasonal COP of 5.0 per https://www.energy.gov/energysaver/heat-pump-swimming-pool-heaters
      end
    elsif type == HPXML::HeaterTypeGas
      load_units = HPXML::UnitsThermPerYear
      load_value = 3.0 / 0.014 * (0.5 + 0.25 * nbeds / 3.0 + 0.25 * cfa / 1920.0) # therm/yr
    end
    return load_units, load_value
  end

  # TODO
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [TODO] TODO
  def self.get_permanent_spa_pump_default_values(cfa, nbeds)
    return 59.5 / 0.059 * (0.5 + 0.25 * nbeds / 3.0 + 0.25 * cfa / 1920.0) # kWh/yr
  end

  # TODO
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @param type [TODO] TODO
  # @return [TODO] TODO
  def self.get_permanent_spa_heater_default_values(cfa, nbeds, type)
    load_units = nil
    load_value = nil
    if [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include? type
      load_units = HPXML::UnitsKwhPerYear
      load_value = 49.0 / 0.048 * (0.5 + 0.25 * nbeds / 3.0 + 0.25 * cfa / 1920.0) # kWh/yr
      if type == HPXML::HeaterTypeHeatPump
        load_value /= 5.0 # Assume seasonal COP of 5.0 per https://www.energy.gov/energysaver/heat-pump-swimming-pool-heaters
      end
    elsif type == HPXML::HeaterTypeGas
      load_units = HPXML::UnitsThermPerYear
      load_value = 0.87 / 0.011 * (0.5 + 0.25 * nbeds / 3.0 + 0.25 * cfa / 1920.0) # therm/yr
    end
    return load_units, load_value
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.get_electric_vehicle_charging_default_values
    ev_charger_efficiency = 0.9
    ev_battery_efficiency = 0.9
    vehicle_annual_miles_driven = 4500.0
    vehicle_kWh_per_mile = 0.3
    return vehicle_annual_miles_driven * vehicle_kWh_per_mile / (ev_charger_efficiency * ev_battery_efficiency) # kWh/yr
  end

  # TODO
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [TODO] TODO
  def self.get_well_pump_default_values(cfa, nbeds)
    return 50.8 / 0.127 * (0.5 + 0.25 * nbeds / 3.0 + 0.25 * cfa / 1920.0) # kWh/yr
  end

  # TODO
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [TODO] TODO
  def self.get_gas_grill_default_values(cfa, nbeds)
    return 0.87 / 0.029 * (0.5 + 0.25 * nbeds / 3.0 + 0.25 * cfa / 1920.0) # therm/yr
  end

  # TODO
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [TODO] TODO
  def self.get_gas_lighting_default_values(cfa, nbeds)
    return 0.22 / 0.012 * (0.5 + 0.25 * nbeds / 3.0 + 0.25 * cfa / 1920.0) # therm/yr
  end

  # TODO
  #
  # @param cfa [Double] Conditioned floor area in the dwelling unit (ft2)
  # @param nbeds [Integer] Number of bedrooms in the dwelling unit
  # @return [TODO] TODO
  def self.get_gas_fireplace_default_values(cfa, nbeds)
    return 1.95 / 0.032 * (0.5 + 0.25 * nbeds / 3.0 + 0.25 * cfa / 1920.0) # therm/yr
  end
end
