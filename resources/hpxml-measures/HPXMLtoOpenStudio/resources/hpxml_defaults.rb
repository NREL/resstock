# frozen_string_literal: true

class HPXMLDefaults
  # Note: Each HPXML object (e.g., HPXML::Wall) has an additional_properties
  # child object where custom information can be attached to the object without
  # being written to the HPXML file. This will allow the custom information to
  # be used by subsequent calculations/logic.

  def self.apply(runner, hpxml, hpxml_bldg, eri_version, weather, epw_file: nil, schedules_file: nil, convert_shared_systems: true,
                 design_load_details_output_file_path: nil, output_format: 'csv')
    cfa = hpxml_bldg.building_construction.conditioned_floor_area
    nbeds = hpxml_bldg.building_construction.number_of_bedrooms
    ncfl = hpxml_bldg.building_construction.number_of_conditioned_floors
    ncfl_ag = hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade
    has_uncond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementUnconditioned)
    has_cond_bsmnt = hpxml_bldg.has_location(HPXML::LocationBasementConditioned)

    # Check for presence of fuels once
    has_fuel = hpxml_bldg.has_fuels(Constants.FossilFuels, hpxml.to_doc)

    add_zones_spaces_if_needed(hpxml, hpxml_bldg, cfa)

    apply_header(hpxml.header, epw_file, hpxml_bldg)
    apply_building(hpxml_bldg, epw_file)
    apply_emissions_scenarios(hpxml.header, has_fuel)
    apply_utility_bill_scenarios(runner, hpxml.header, hpxml_bldg, has_fuel)
    apply_building_header(hpxml.header, hpxml_bldg, weather)
    apply_building_header_sizing(runner, hpxml_bldg, weather, nbeds)
    apply_site(hpxml_bldg)
    apply_neighbor_buildings(hpxml_bldg)
    apply_building_occupancy(hpxml_bldg, schedules_file)
    apply_building_construction(hpxml_bldg, cfa, nbeds)
    apply_zone_spaces(hpxml_bldg)
    apply_climate_and_risk_zones(hpxml_bldg, epw_file)
    apply_attics(hpxml_bldg)
    apply_foundations(hpxml_bldg)
    apply_infiltration(hpxml_bldg)
    apply_roofs(hpxml_bldg)
    apply_rim_joists(hpxml_bldg)
    apply_walls(hpxml_bldg)
    apply_foundation_walls(hpxml_bldg)
    apply_floors(runner, hpxml_bldg)
    apply_slabs(hpxml_bldg)
    apply_windows(hpxml_bldg, eri_version)
    apply_skylights(hpxml_bldg)
    apply_doors(hpxml_bldg)
    apply_partition_wall_mass(hpxml_bldg)
    apply_furniture_mass(hpxml_bldg)
    apply_hvac(runner, hpxml, hpxml_bldg, weather, convert_shared_systems)
    apply_hvac_control(hpxml_bldg, schedules_file, eri_version)
    apply_hvac_distribution(hpxml_bldg, ncfl, ncfl_ag)
    apply_hvac_location(hpxml_bldg)
    apply_ventilation_fans(hpxml_bldg, weather, cfa, nbeds, eri_version)
    apply_water_heaters(hpxml_bldg, nbeds, eri_version, schedules_file)
    apply_flue_or_chimney(hpxml_bldg)
    apply_hot_water_distribution(hpxml_bldg, cfa, ncfl, has_uncond_bsmnt, has_cond_bsmnt, schedules_file)
    apply_water_fixtures(hpxml_bldg, schedules_file)
    apply_solar_thermal_systems(hpxml_bldg)
    apply_appliances(hpxml_bldg, nbeds, eri_version, schedules_file)
    apply_lighting(hpxml_bldg, schedules_file)
    apply_ceiling_fans(hpxml_bldg, nbeds, weather, schedules_file)
    apply_pools_and_permanent_spas(hpxml_bldg, cfa, schedules_file)
    apply_plug_loads(hpxml_bldg, cfa, schedules_file)
    apply_fuel_loads(hpxml_bldg, cfa, schedules_file)
    apply_pv_systems(hpxml_bldg)
    apply_generators(hpxml_bldg)
    apply_batteries(hpxml_bldg)

    # Do HVAC sizing after all other defaults have been applied
    apply_hvac_sizing(runner, hpxml_bldg, weather, output_format, design_load_details_output_file_path)

    # Default detailed performance has to be after sizing to have autosized capacity information
    apply_detailed_performance_data_for_var_speed_systems(hpxml_bldg)

    cleanup_zones_spaces(hpxml_bldg)
  end

  def self.get_default_azimuths(hpxml_bldg)
    def self.sanitize_azimuth(azimuth)
      # Ensure 0 <= orientation < 360
      while azimuth < 0
        azimuth += 360
      end
      while azimuth >= 360
        azimuth -= 360
      end
      return azimuth
    end

    # Returns a list of four azimuths (facing each direction). Determined based
    # on the primary azimuth, as defined by the azimuth with the largest surface
    # area, plus azimuths that are offset by 90/180/270 degrees. Used for
    # surfaces that may not have an azimuth defined (e.g., walls).
    azimuth_areas = {}
    (hpxml_bldg.surfaces + hpxml_bldg.subsurfaces).each do |surface|
      next unless surface.respond_to?(:azimuth)

      az = surface.azimuth
      next if az.nil?

      azimuth_areas[az] = 0 if azimuth_areas[az].nil?
      azimuth_areas[az] += surface.area
    end
    if azimuth_areas.empty?
      primary_azimuth = 0
    else
      primary_azimuth = azimuth_areas.max_by { |_k, v| v }[0]
    end
    return [primary_azimuth,
            sanitize_azimuth(primary_azimuth + 90),
            sanitize_azimuth(primary_azimuth + 180),
            sanitize_azimuth(primary_azimuth + 270)].sort
  end

  private

  def self.add_zones_spaces_if_needed(hpxml, hpxml_bldg, cfa)
    # Automatically add conditioned zone/space if not provided to simplify the HVAC sizing code
    bldg_idx = hpxml.buildings.index(hpxml_bldg)
    if hpxml_bldg.conditioned_zones.empty?
      hpxml_bldg.zones.add(id: "#{Constants.AutomaticallyAdded}Zone#{bldg_idx + 1}",
                           zone_type: HPXML::ZoneTypeConditioned)
      hpxml_bldg.hvac_systems.each do |hvac_system|
        hvac_system.attached_to_zone_idref = hpxml_bldg.zones[-1].id
      end
      hpxml_bldg.zones[-1].spaces.add(id: "#{Constants.AutomaticallyAdded}Space#{bldg_idx + 1}",
                                      floor_area: cfa)
      hpxml_bldg.surfaces.each do |surface|
        next unless HPXML::conditioned_locations_this_unit.include? surface.interior_adjacent_to
        next if surface.exterior_adjacent_to == HPXML::LocationOtherHousingUnit

        surface.attached_to_space_idref = hpxml_bldg.zones[-1].spaces[-1].id
      end
    end
  end

  def self.apply_header(hpxml_header, epw_file, hpxml_bldg)
    if hpxml_header.timestep.nil?
      hpxml_header.timestep = 60
      hpxml_header.timestep_isdefaulted = true
    end

    if hpxml_header.sim_begin_month.nil?
      hpxml_header.sim_begin_month = 1
      hpxml_header.sim_begin_month_isdefaulted = true
    end
    if hpxml_header.sim_begin_day.nil?
      hpxml_header.sim_begin_day = 1
      hpxml_header.sim_begin_day_isdefaulted = true
    end
    if hpxml_header.sim_end_month.nil?
      hpxml_header.sim_end_month = 12
      hpxml_header.sim_end_month_isdefaulted = true
    end
    if hpxml_header.sim_end_day.nil?
      hpxml_header.sim_end_day = 31
      hpxml_header.sim_end_day_isdefaulted = true
    end

    sim_calendar_year = Location.get_sim_calendar_year(hpxml_header.sim_calendar_year, epw_file)
    if not hpxml_header.sim_calendar_year.nil?
      if hpxml_header.sim_calendar_year != sim_calendar_year
        hpxml_header.sim_calendar_year = sim_calendar_year
        hpxml_header.sim_calendar_year_isdefaulted = true
      end
    else
      hpxml_header.sim_calendar_year = sim_calendar_year
      hpxml_header.sim_calendar_year_isdefaulted = true
    end

    if hpxml_header.temperature_capacitance_multiplier.nil?
      hpxml_header.temperature_capacitance_multiplier = 7.0
      hpxml_header.temperature_capacitance_multiplier_isdefaulted = true
    end

    if hpxml_header.defrost_model_type.nil? && (hpxml_bldg.heat_pumps.any? { |hp| [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit, HPXML::HVACTypeHeatPumpRoom, HPXML::HVACTypeHeatPumpPTHP].include? hp.heat_pump_type })
      hpxml_header.defrost_model_type = HPXML::AdvancedResearchDefrostModelTypeStandard
      hpxml_header.defrost_model_type_isdefaulted = true
    end

    hpxml_header.unavailable_periods.each do |unavailable_period|
      if unavailable_period.begin_hour.nil?
        unavailable_period.begin_hour = 0
        unavailable_period.begin_hour_isdefaulted = true
      end
      if unavailable_period.end_hour.nil?
        unavailable_period.end_hour = 24
        unavailable_period.end_hour_isdefaulted = true
      end
      if unavailable_period.natvent_availability.nil?
        unavailable_period.natvent_availability = HPXML::ScheduleRegular
        unavailable_period.natvent_availability_isdefaulted = true
      end
    end
  end

  def self.apply_building_header_sizing(runner, hpxml_bldg, weather, nbeds)
    if hpxml_bldg.header.manualj_heating_design_temp.nil?
      hpxml_bldg.header.manualj_heating_design_temp = weather.design.HeatingDrybulb.round(2)
      hpxml_bldg.header.manualj_heating_design_temp_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_cooling_design_temp.nil?
      hpxml_bldg.header.manualj_cooling_design_temp = weather.design.CoolingDrybulb.round(2)
      hpxml_bldg.header.manualj_cooling_design_temp_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_daily_temp_range.nil?
      hpxml_bldg.header.manualj_daily_temp_range = HVACSizing.determine_daily_temperature_range_class(weather.design.DailyTemperatureRange)
      hpxml_bldg.header.manualj_daily_temp_range_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_heating_setpoint.nil?
      hpxml_bldg.header.manualj_heating_setpoint = 70.0 # deg-F, per Manual J
      hpxml_bldg.header.manualj_heating_setpoint_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_cooling_setpoint.nil?
      hpxml_bldg.header.manualj_cooling_setpoint = 75.0 # deg-F, per Manual J
      hpxml_bldg.header.manualj_cooling_setpoint_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_humidity_setpoint.nil?
      hpxml_bldg.header.manualj_humidity_setpoint = 0.5 # 50%
      p_atm = UnitConversions.convert(Psychrometrics.Pstd_fZ(hpxml_bldg.elevation), 'psi', 'atm')
      hr_indoor_cooling = HVACSizing.calculate_indoor_hr(hpxml_bldg.header.manualj_humidity_setpoint, hpxml_bldg.header.manualj_cooling_setpoint, p_atm)
      if HVACSizing.calculate_design_grains(weather.design.CoolingHumidityRatio, hr_indoor_cooling) < 0
        # Dry summer climate per Manual J 18-1 Design Grains
        hpxml_bldg.header.manualj_humidity_setpoint = 0.45 # 45%
      end
      hpxml_bldg.header.manualj_humidity_setpoint_isdefaulted = true
    end

    if hpxml_bldg.header.manualj_humidity_difference.nil?
      p_atm = UnitConversions.convert(Psychrometrics.Pstd_fZ(hpxml_bldg.elevation), 'psi', 'atm')
      hr_indoor_cooling = HVACSizing.calculate_indoor_hr(hpxml_bldg.header.manualj_humidity_setpoint, hpxml_bldg.header.manualj_cooling_setpoint, p_atm)
      hpxml_bldg.header.manualj_humidity_difference = HVACSizing.calculate_design_grains(weather.design.CoolingHumidityRatio, hr_indoor_cooling).round(1)
      hpxml_bldg.header.manualj_humidity_difference_isdefaulted = true
    end

    sum_space_manualj_internal_loads_sensible = Float(hpxml_bldg.conditioned_spaces.map { |space| space.manualj_internal_loads_sensible.to_f }.sum.round)
    if hpxml_bldg.header.manualj_internal_loads_sensible.nil?
      if sum_space_manualj_internal_loads_sensible > 0
        hpxml_bldg.header.manualj_internal_loads_sensible = sum_space_manualj_internal_loads_sensible
      elsif hpxml_bldg.refrigerators.size + hpxml_bldg.freezers.size <= 1
        hpxml_bldg.header.manualj_internal_loads_sensible = 2400.0 # Btuh, per Manual J
      else
        hpxml_bldg.header.manualj_internal_loads_sensible = 3600.0 # Btuh, per Manual J
      end
      hpxml_bldg.header.manualj_internal_loads_sensible_isdefaulted = true
    end
    if sum_space_manualj_internal_loads_sensible == 0
      # Area weighted assignment
      total_floor_area = hpxml_bldg.conditioned_spaces.map { |space| space.floor_area }.sum
      hpxml_bldg.conditioned_spaces.each do |space|
        space.manualj_internal_loads_sensible = (hpxml_bldg.header.manualj_internal_loads_sensible * space.floor_area / total_floor_area).round
        space.manualj_internal_loads_sensible_isdefaulted = true
      end
    elsif (hpxml_bldg.header.manualj_internal_loads_sensible - sum_space_manualj_internal_loads_sensible).abs > 50 # Tolerance for rounding
      runner.registerWarning("ManualJInputs/InternalLoadsSensible (#{hpxml_bldg.header.manualj_internal_loads_sensible}) does not match sum of conditioned spaces (#{sum_space_manualj_internal_loads_sensible}).")
    end

    sum_space_manualj_internal_loads_latent = Float(hpxml_bldg.conditioned_spaces.map { |space| space.manualj_internal_loads_latent.to_f }.sum.round)
    if hpxml_bldg.header.manualj_internal_loads_latent.nil?
      hpxml_bldg.header.manualj_internal_loads_latent = sum_space_manualj_internal_loads_latent # Btuh
      hpxml_bldg.header.manualj_internal_loads_latent_isdefaulted = true
    end
    if sum_space_manualj_internal_loads_latent == 0
      # Area weighted assignment
      total_floor_area = hpxml_bldg.conditioned_spaces.map { |space| space.floor_area }.sum
      hpxml_bldg.conditioned_spaces.each do |space|
        space.manualj_internal_loads_latent = (hpxml_bldg.header.manualj_internal_loads_latent * space.floor_area / total_floor_area).round
        space.manualj_internal_loads_latent_isdefaulted = true
      end
    elsif (hpxml_bldg.header.manualj_internal_loads_latent - sum_space_manualj_internal_loads_latent).abs > 50 # Tolerance for rounding
      runner.registerWarning("ManualJInputs/InternalLoadsLatent (#{hpxml_bldg.header.manualj_internal_loads_latent}) does not match sum of conditioned spaces (#{sum_space_manualj_internal_loads_latent}).")
    end

    sum_space_manualj_num_occupants = hpxml_bldg.conditioned_spaces.map { |space| space.manualj_num_occupants.to_f }.sum.round
    if hpxml_bldg.header.manualj_num_occupants.nil?
      if sum_space_manualj_num_occupants > 0
        hpxml_bldg.header.manualj_num_occupants = sum_space_manualj_num_occupants
      else
        hpxml_bldg.header.manualj_num_occupants = nbeds + 1 # Per Manual J
      end
      hpxml_bldg.header.manualj_num_occupants_isdefaulted = true
    end
    if sum_space_manualj_num_occupants == 0
      # Area weighted assignment
      total_floor_area = hpxml_bldg.conditioned_spaces.map { |space| space.floor_area }.sum
      hpxml_bldg.conditioned_spaces.each do |space|
        space.manualj_num_occupants = (hpxml_bldg.header.manualj_num_occupants * space.floor_area / total_floor_area).round(2)
        space.manualj_num_occupants_isdefaulted = true
      end
    elsif (hpxml_bldg.header.manualj_num_occupants - sum_space_manualj_num_occupants).abs >= 1 # Tolerance for rounding
      runner.registerWarning("ManualJInputs/NumberofOccupants (#{hpxml_bldg.header.manualj_num_occupants}) does not match sum of conditioned spaces (#{sum_space_manualj_num_occupants}).")
    end
  end

  def self.apply_building_header(hpxml_header, hpxml_bldg, weather)
    if hpxml_bldg.header.natvent_days_per_week.nil?
      hpxml_bldg.header.natvent_days_per_week = 3
      hpxml_bldg.header.natvent_days_per_week_isdefaulted = true
    end

    if hpxml_bldg.header.heat_pump_sizing_methodology.nil? && (hpxml_bldg.heat_pumps.size > 0)
      hpxml_bldg.header.heat_pump_sizing_methodology = HPXML::HeatPumpSizingHERS
      hpxml_bldg.header.heat_pump_sizing_methodology_isdefaulted = true
    end

    if hpxml_bldg.header.heat_pump_backup_sizing_methodology.nil? && (hpxml_bldg.heat_pumps.size > 0)
      hpxml_bldg.header.heat_pump_backup_sizing_methodology = HPXML::HeatPumpBackupSizingEmergency
      hpxml_bldg.header.heat_pump_backup_sizing_methodology_isdefaulted = true
    end

    if hpxml_bldg.header.allow_increased_fixed_capacities.nil?
      hpxml_bldg.header.allow_increased_fixed_capacities = false
      hpxml_bldg.header.allow_increased_fixed_capacities_isdefaulted = true
    end

    if hpxml_bldg.header.shading_summer_begin_month.nil? || hpxml_bldg.header.shading_summer_begin_day.nil? || hpxml_bldg.header.shading_summer_end_month.nil? || hpxml_bldg.header.shading_summer_end_day.nil?
      if not weather.nil?
        # Default based on Building America seasons
        _, default_cooling_months = HVAC.get_default_heating_and_cooling_seasons(weather, hpxml_bldg.latitude)
        begin_month, begin_day, end_month, end_day = Schedule.get_begin_and_end_dates_from_monthly_array(default_cooling_months, hpxml_header.sim_calendar_year)
        if not begin_month.nil? # Check if no summer
          hpxml_bldg.header.shading_summer_begin_month = begin_month
          hpxml_bldg.header.shading_summer_begin_day = begin_day
          hpxml_bldg.header.shading_summer_end_month = end_month
          hpxml_bldg.header.shading_summer_end_day = end_day
          hpxml_bldg.header.shading_summer_begin_month_isdefaulted = true
          hpxml_bldg.header.shading_summer_begin_day_isdefaulted = true
          hpxml_bldg.header.shading_summer_end_month_isdefaulted = true
          hpxml_bldg.header.shading_summer_end_day_isdefaulted = true
        end
      end
    end
  end

  def self.apply_emissions_scenarios(hpxml_header, has_fuel)
    hpxml_header.emissions_scenarios.each do |scenario|
      # Electricity
      if not scenario.elec_schedule_filepath.nil?
        if scenario.elec_schedule_number_of_header_rows.nil?
          scenario.elec_schedule_number_of_header_rows = 0
          scenario.elec_schedule_number_of_header_rows_isdefaulted = true
        end
        if scenario.elec_schedule_column_number.nil?
          scenario.elec_schedule_column_number = 1
          scenario.elec_schedule_column_number_isdefaulted = true
        end
      end

      # Fossil fuels
      default_units = HPXML::EmissionsScenario::UnitsLbPerMBtu
      if scenario.emissions_type.downcase == 'co2e'
        natural_gas, propane, fuel_oil, coal, wood, wood_pellets = 147.3, 177.8, 195.9, nil, nil, nil
      elsif scenario.emissions_type.downcase == 'nox'
        natural_gas, propane, fuel_oil, coal, wood, wood_pellets = 0.0922, 0.1421, 0.1300, nil, nil, nil
      elsif scenario.emissions_type.downcase == 'so2'
        natural_gas, propane, fuel_oil, coal, wood, wood_pellets = 0.0006, 0.0002, 0.0015, nil, nil, nil
      else
        natural_gas, propane, fuel_oil, coal, wood, wood_pellets = nil, nil, nil, nil, nil, nil
      end
      if has_fuel[HPXML::FuelTypeNaturalGas]
        if (scenario.natural_gas_units.nil? || scenario.natural_gas_value.nil?) && (not natural_gas.nil?)
          scenario.natural_gas_units = default_units
          scenario.natural_gas_units_isdefaulted = true
          scenario.natural_gas_value = natural_gas
          scenario.natural_gas_value_isdefaulted = true
        end
      end
      if has_fuel[HPXML::FuelTypePropane]
        if (scenario.propane_units.nil? || scenario.propane_value.nil?) && (not propane.nil?)
          scenario.propane_units = default_units
          scenario.propane_units_isdefaulted = true
          scenario.propane_value = propane
          scenario.propane_value_isdefaulted = true
        end
      end
      if has_fuel[HPXML::FuelTypeOil]
        if (scenario.fuel_oil_units.nil? || scenario.fuel_oil_value.nil?) && (not fuel_oil.nil?)
          scenario.fuel_oil_units = default_units
          scenario.fuel_oil_units_isdefaulted = true
          scenario.fuel_oil_value = fuel_oil
          scenario.fuel_oil_value_isdefaulted = true
        end
      end
      if has_fuel[HPXML::FuelTypeCoal]
        if (scenario.coal_units.nil? || scenario.coal_value.nil?) && (not coal.nil?)
          scenario.coal_units = default_units
          scenario.coal_units_isdefaulted = true
          scenario.coal_value = coal
          scenario.coal_value_isdefaulted = true
        end
      end
      if has_fuel[HPXML::FuelTypeWoodCord]
        if (scenario.wood_units.nil? || scenario.wood_value.nil?) && (not wood.nil?)
          scenario.wood_units = default_units
          scenario.wood_units_isdefaulted = true
          scenario.wood_value = wood
          scenario.wood_value_isdefaulted = true
        end
      end
      next unless has_fuel[HPXML::FuelTypeWoodPellets]

      next unless (scenario.wood_pellets_units.nil? || scenario.wood_pellets_value.nil?) && (not wood_pellets.nil?)

      scenario.wood_pellets_units = default_units
      scenario.wood_pellets_units_isdefaulted = true
      scenario.wood_pellets_value = wood_pellets
      scenario.wood_pellets_value_isdefaulted = true
    end
  end

  def self.apply_utility_bill_scenarios(runner, hpxml_header, hpxml_bldg, has_fuel)
    hpxml_header.utility_bill_scenarios.each do |scenario|
      if scenario.elec_tariff_filepath.nil?
        if scenario.elec_fixed_charge.nil?
          scenario.elec_fixed_charge = 12.0 # https://www.nrdc.org/experts/samantha-williams/there-war-attrition-electricity-fixed-charges says $11.19/month in 2018
          scenario.elec_fixed_charge_isdefaulted = true
        end
        if scenario.elec_marginal_rate.nil?
          scenario.elec_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypeElectricity, scenario.elec_fixed_charge)
          scenario.elec_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypeNaturalGas]
        if scenario.natural_gas_fixed_charge.nil?
          scenario.natural_gas_fixed_charge = 12.0 # https://www.aga.org/sites/default/files/aga_energy_analysis_-_natural_gas_utility_rate_structure.pdf says $11.25/month in 2015
          scenario.natural_gas_fixed_charge_isdefaulted = true
        end
        if scenario.natural_gas_marginal_rate.nil?
          scenario.natural_gas_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypeNaturalGas, scenario.natural_gas_fixed_charge)
          scenario.natural_gas_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypePropane]
        if scenario.propane_fixed_charge.nil?
          scenario.propane_fixed_charge = 0.0
          scenario.propane_fixed_charge_isdefaulted = true
        end
        if scenario.propane_marginal_rate.nil?
          scenario.propane_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypePropane, nil)
          scenario.propane_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypeOil]
        if scenario.fuel_oil_fixed_charge.nil?
          scenario.fuel_oil_fixed_charge = 0.0
          scenario.fuel_oil_fixed_charge_isdefaulted = true
        end
        if scenario.fuel_oil_marginal_rate.nil?
          scenario.fuel_oil_marginal_rate, _ = UtilityBills.get_rates_from_eia_data(runner, hpxml_bldg.state_code, HPXML::FuelTypeOil, nil)
          scenario.fuel_oil_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypeCoal]
        if scenario.coal_fixed_charge.nil?
          scenario.coal_fixed_charge = 0.0
          scenario.coal_fixed_charge_isdefaulted = true
        end
        if scenario.coal_marginal_rate.nil?
          scenario.coal_marginal_rate = 0.015
          scenario.coal_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypeWoodCord]
        if scenario.wood_fixed_charge.nil?
          scenario.wood_fixed_charge = 0.0
          scenario.wood_fixed_charge_isdefaulted = true
        end
        if scenario.wood_marginal_rate.nil?
          scenario.wood_marginal_rate = 0.015
          scenario.wood_marginal_rate_isdefaulted = true
        end
      end

      if has_fuel[HPXML::FuelTypeWoodPellets]
        if scenario.wood_pellets_fixed_charge.nil?
          scenario.wood_pellets_fixed_charge = 0.0
          scenario.wood_pellets_fixed_charge_isdefaulted = true
        end
        if scenario.wood_pellets_marginal_rate.nil?
          scenario.wood_pellets_marginal_rate = 0.015
          scenario.wood_pellets_marginal_rate_isdefaulted = true
        end
      end

      next unless hpxml_bldg.pv_systems.size > 0

      if scenario.pv_compensation_type.nil?
        scenario.pv_compensation_type = HPXML::PVCompensationTypeNetMetering
        scenario.pv_compensation_type_isdefaulted = true
      end

      if scenario.pv_compensation_type == HPXML::PVCompensationTypeNetMetering
        if scenario.pv_net_metering_annual_excess_sellback_rate_type.nil?
          scenario.pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
          scenario.pv_net_metering_annual_excess_sellback_rate_type_isdefaulted = true
        end
        if scenario.pv_net_metering_annual_excess_sellback_rate_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
          if scenario.pv_net_metering_annual_excess_sellback_rate.nil?
            scenario.pv_net_metering_annual_excess_sellback_rate = 0.03
            scenario.pv_net_metering_annual_excess_sellback_rate_isdefaulted = true
          end
        end
      elsif scenario.pv_compensation_type == HPXML::PVCompensationTypeFeedInTariff
        if scenario.pv_feed_in_tariff_rate.nil?
          scenario.pv_feed_in_tariff_rate = 0.12
          scenario.pv_feed_in_tariff_rate_isdefaulted = true
        end
      end

      if scenario.pv_monthly_grid_connection_fee_dollars_per_kw.nil? && scenario.pv_monthly_grid_connection_fee_dollars.nil?
        scenario.pv_monthly_grid_connection_fee_dollars = 0.0
        scenario.pv_monthly_grid_connection_fee_dollars_isdefaulted = true
      end
    end
  end

  def self.apply_building(hpxml_bldg, epw_file)
    if hpxml_bldg.site.soil_type.nil? && hpxml_bldg.site.ground_conductivity.nil? && hpxml_bldg.site.ground_diffusivity.nil?
      hpxml_bldg.site.soil_type = HPXML::SiteSoilTypeUnknown
      hpxml_bldg.site.soil_type_isdefaulted = true
    end

    if hpxml_bldg.site.moisture_type.nil? && hpxml_bldg.site.ground_conductivity.nil? && hpxml_bldg.site.ground_diffusivity.nil?
      hpxml_bldg.site.moisture_type = HPXML::SiteSoilMoistureTypeMixed
      hpxml_bldg.site.moisture_type_isdefaulted = true
    end

    # Conductivity/diffusivity values come from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4813881 (with the exception of "unknown")
    if hpxml_bldg.site.ground_conductivity.nil? && hpxml_bldg.site.ground_diffusivity.nil?
      if hpxml_bldg.site.soil_type == HPXML::SiteSoilTypeSand
        if hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeDry
          hpxml_bldg.site.ground_conductivity = 0.2311 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0097 # ft^2/hr
        elsif hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeWet
          hpxml_bldg.site.ground_conductivity = 1.3865 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0322 # ft^2/hr
        elsif hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeMixed
          hpxml_bldg.site.ground_conductivity = ((0.2311 + 1.3865) / 2.0).round(4) # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = ((0.0097 + 0.0322) / 2.0).round(4) # ft^2/hr
        end
        hpxml_bldg.site.ground_conductivity_isdefaulted = true
        hpxml_bldg.site.ground_diffusivity_isdefaulted = true
      elsif hpxml_bldg.site.soil_type == HPXML::SiteSoilTypeSilt || hpxml_bldg.site.soil_type == HPXML::SiteSoilTypeClay
        if hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeDry
          hpxml_bldg.site.ground_conductivity = 0.2889 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0120 # ft^2/hr
        elsif hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeWet
          hpxml_bldg.site.ground_conductivity = 0.9821 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0194 # ft^2/hr
        elsif hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeMixed
          hpxml_bldg.site.ground_conductivity = ((0.2889 + 0.9821) / 2.0).round(4) # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = ((0.0120 + 0.0194) / 2.0).round(4) # ft^2/hr
        end
        hpxml_bldg.site.ground_conductivity_isdefaulted = true
        hpxml_bldg.site.ground_diffusivity_isdefaulted = true
      elsif hpxml_bldg.site.soil_type == HPXML::SiteSoilTypeLoam
        hpxml_bldg.site.ground_conductivity = 1.2132 # Btu/hr-ft-F
        hpxml_bldg.site.ground_diffusivity = 0.0353 # ft^2/hr

        hpxml_bldg.site.ground_conductivity_isdefaulted = true
        hpxml_bldg.site.ground_diffusivity_isdefaulted = true
      elsif hpxml_bldg.site.soil_type == HPXML::SiteSoilTypeGravel
        if hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeDry
          hpxml_bldg.site.ground_conductivity = 0.2311 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0097 # ft^2/hr
        elsif hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeWet
          hpxml_bldg.site.ground_conductivity = 1.0399 # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = 0.0291 # ft^2/hr
        elsif hpxml_bldg.site.moisture_type == HPXML::SiteSoilMoistureTypeMixed
          hpxml_bldg.site.ground_conductivity = ((0.2311 + 1.0399) / 2.0).round(4) # Btu/hr-ft-F
          hpxml_bldg.site.ground_diffusivity = ((0.0097 + 0.0291) / 2.0).round(4) # ft^2/hr
        end
        hpxml_bldg.site.ground_conductivity_isdefaulted = true
        hpxml_bldg.site.ground_diffusivity_isdefaulted = true
      elsif hpxml_bldg.site.soil_type == HPXML::SiteSoilTypeUnknown
        hpxml_bldg.site.ground_conductivity = 1.0
        hpxml_bldg.site.ground_diffusivity = 0.0208
        hpxml_bldg.site.ground_conductivity_isdefaulted = true
        hpxml_bldg.site.ground_diffusivity_isdefaulted = true
      end
    end
    if hpxml_bldg.site.ground_conductivity.nil? && !hpxml_bldg.site.ground_diffusivity.nil?
      # Divide diffusivity by 0.0208 to maintain 1/0.0208 relationship
      hpxml_bldg.site.ground_conductivity = hpxml_bldg.site.ground_diffusivity / 0.0208 # Btu/hr-ft-F
      hpxml_bldg.site.ground_conductivity_isdefaulted = true
    elsif !hpxml_bldg.site.ground_conductivity.nil? && hpxml_bldg.site.ground_diffusivity.nil?
      # Multiply conductivity by 0.0208 to maintain 1/0.0208 relationship
      hpxml_bldg.site.ground_diffusivity = hpxml_bldg.site.ground_conductivity * 0.0208 # ft^2/hr
      hpxml_bldg.site.ground_diffusivity_isdefaulted = true
    end

    if hpxml_bldg.dst_enabled.nil?
      hpxml_bldg.dst_enabled = true # Assume DST since it occurs in most US locations
      hpxml_bldg.dst_enabled_isdefaulted = true
    end

    if not epw_file.nil?

      if hpxml_bldg.state_code.nil?
        hpxml_bldg.state_code = get_default_state_code(hpxml_bldg.state_code, epw_file)
        hpxml_bldg.state_code_isdefaulted = true
      end

      if hpxml_bldg.city.nil?
        hpxml_bldg.city = epw_file.city
        hpxml_bldg.city_isdefaulted = true
      end

      if hpxml_bldg.time_zone_utc_offset.nil?
        hpxml_bldg.time_zone_utc_offset = get_default_time_zone(hpxml_bldg.time_zone_utc_offset, epw_file)
        hpxml_bldg.time_zone_utc_offset_isdefaulted = true
      end

      if hpxml_bldg.dst_enabled
        if hpxml_bldg.dst_begin_month.nil? || hpxml_bldg.dst_begin_day.nil? || hpxml_bldg.dst_end_month.nil? || hpxml_bldg.dst_end_day.nil?
          if epw_file.daylightSavingStartDate.is_initialized && epw_file.daylightSavingEndDate.is_initialized
            # Use weather file DST dates if available
            dst_start_date = epw_file.daylightSavingStartDate.get
            dst_end_date = epw_file.daylightSavingEndDate.get
            hpxml_bldg.dst_begin_month = dst_start_date.monthOfYear.value
            hpxml_bldg.dst_begin_day = dst_start_date.dayOfMonth
            hpxml_bldg.dst_end_month = dst_end_date.monthOfYear.value
            hpxml_bldg.dst_end_day = dst_end_date.dayOfMonth
          else
            # Roughly average US dates according to https://en.wikipedia.org/wiki/Daylight_saving_time_in_the_United_States
            hpxml_bldg.dst_begin_month = 3
            hpxml_bldg.dst_begin_day = 12
            hpxml_bldg.dst_end_month = 11
            hpxml_bldg.dst_end_day = 5
          end
          hpxml_bldg.dst_begin_month_isdefaulted = true
          hpxml_bldg.dst_begin_day_isdefaulted = true
          hpxml_bldg.dst_end_month_isdefaulted = true
          hpxml_bldg.dst_end_day_isdefaulted = true
        end
      end

      if hpxml_bldg.elevation.nil?
        hpxml_bldg.elevation = UnitConversions.convert([epw_file.elevation, 0.0].max, 'm', 'ft').round(1)
        hpxml_bldg.elevation_isdefaulted = true
      end

      if hpxml_bldg.latitude.nil?
        hpxml_bldg.latitude = get_default_latitude(hpxml_bldg.latitude, epw_file)
        hpxml_bldg.latitude_isdefaulted = true
      end

      if hpxml_bldg.longitude.nil?
        hpxml_bldg.longitude = get_default_longitude(hpxml_bldg.longitude, epw_file)
        hpxml_bldg.longitude_isdefaulted = true
      end
    end
  end

  def self.apply_site(hpxml_bldg)
    if hpxml_bldg.site.site_type.nil?
      hpxml_bldg.site.site_type = HPXML::SiteTypeSuburban
      hpxml_bldg.site.site_type_isdefaulted = true
    end

    if hpxml_bldg.site.shielding_of_home.nil?
      if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include?(hpxml_bldg.building_construction.residential_facility_type)
        # Shielding Class 5 is ACCA MJ8 default for Table 5B/5E for townhouses and condos
        hpxml_bldg.site.shielding_of_home = HPXML::ShieldingWellShielded
      else
        # Shielding Class 4 is ACCA MJ8 default for Table 5A/5D and ANSI/RESNET 301 default
        hpxml_bldg.site.shielding_of_home = HPXML::ShieldingNormal
      end
      hpxml_bldg.site.shielding_of_home_isdefaulted = true
    end

    if hpxml_bldg.site.ground_conductivity.nil?
      hpxml_bldg.site.ground_conductivity = 1.0 # Btu/hr-ft-F
      hpxml_bldg.site.ground_conductivity_isdefaulted = true
    end
  end

  def self.apply_neighbor_buildings(hpxml_bldg)
    hpxml_bldg.neighbor_buildings.each do |neighbor_building|
      if neighbor_building.azimuth.nil?
        neighbor_building.azimuth = get_azimuth_from_orientation(neighbor_building.orientation)
        neighbor_building.azimuth_isdefaulted = true
      end
      if neighbor_building.orientation.nil?
        neighbor_building.orientation = get_orientation_from_azimuth(neighbor_building.azimuth)
        neighbor_building.orientation_isdefaulted = true
      end
    end
  end

  def self.apply_building_occupancy(hpxml_bldg, schedules_file)
    if hpxml_bldg.building_occupancy.number_of_residents.nil?
      hpxml_bldg.building_construction.additional_properties.adjusted_number_of_bedrooms = hpxml_bldg.building_construction.number_of_bedrooms
    else
      # Set adjusted number of bedrooms for operational calculation; this is an adjustment on
      # ANSI 301 or Building America equations, which are based on number of bedrooms.
      hpxml_bldg.building_construction.additional_properties.adjusted_number_of_bedrooms = get_nbeds_adjusted_for_operational_calculation(hpxml_bldg)
    end
    schedules_file_includes_occupants = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:Occupants].name))
    if hpxml_bldg.building_occupancy.weekday_fractions.nil? && !schedules_file_includes_occupants
      hpxml_bldg.building_occupancy.weekday_fractions = Schedule.OccupantsWeekdayFractions
      hpxml_bldg.building_occupancy.weekday_fractions_isdefaulted = true
    end
    if hpxml_bldg.building_occupancy.weekend_fractions.nil? && !schedules_file_includes_occupants
      hpxml_bldg.building_occupancy.weekend_fractions = Schedule.OccupantsWeekendFractions
      hpxml_bldg.building_occupancy.weekend_fractions_isdefaulted = true
    end
    if hpxml_bldg.building_occupancy.monthly_multipliers.nil? && !schedules_file_includes_occupants
      hpxml_bldg.building_occupancy.monthly_multipliers = Schedule.OccupantsMonthlyMultipliers
      hpxml_bldg.building_occupancy.monthly_multipliers_isdefaulted = true
    end
    if hpxml_bldg.building_occupancy.general_water_use_usage_multiplier.nil?
      hpxml_bldg.building_occupancy.general_water_use_usage_multiplier = 1.0
      hpxml_bldg.building_occupancy.general_water_use_usage_multiplier_isdefaulted = true
    end
    schedules_file_includes_water = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:GeneralWaterUse].name))
    if hpxml_bldg.building_occupancy.general_water_use_weekday_fractions.nil? && !schedules_file_includes_water
      hpxml_bldg.building_occupancy.general_water_use_weekday_fractions = Schedule.GeneralWaterUseWeekdayFractions
      hpxml_bldg.building_occupancy.general_water_use_weekday_fractions_isdefaulted = true
    end
    if hpxml_bldg.building_occupancy.general_water_use_weekend_fractions.nil? && !schedules_file_includes_water
      hpxml_bldg.building_occupancy.general_water_use_weekend_fractions = Schedule.GeneralWaterUseWeekendFractions
      hpxml_bldg.building_occupancy.general_water_use_weekend_fractions_isdefaulted = true
    end
    if hpxml_bldg.building_occupancy.general_water_use_monthly_multipliers.nil? && !schedules_file_includes_water
      hpxml_bldg.building_occupancy.general_water_use_monthly_multipliers = Schedule.GeneralWaterUseMonthlyMultipliers
      hpxml_bldg.building_occupancy.general_water_use_monthly_multipliers_isdefaulted = true
    end
  end

  def self.apply_building_construction(hpxml_bldg, cfa, nbeds)
    cond_crawl_volume = hpxml_bldg.inferred_conditioned_crawlspace_volume()
    if hpxml_bldg.building_construction.average_ceiling_height.nil?
      # ASHRAE 62.2 default for average floor to ceiling height
      hpxml_bldg.building_construction.average_ceiling_height = 8.2
      hpxml_bldg.building_construction.average_ceiling_height_isdefaulted = true
    end
    if hpxml_bldg.building_construction.conditioned_building_volume.nil?
      hpxml_bldg.building_construction.conditioned_building_volume = (cfa * hpxml_bldg.building_construction.average_ceiling_height + cond_crawl_volume).round
      hpxml_bldg.building_construction.conditioned_building_volume_isdefaulted = true
    end
    if hpxml_bldg.building_construction.number_of_bathrooms.nil?
      hpxml_bldg.building_construction.number_of_bathrooms = Float(Waterheater.get_default_num_bathrooms(nbeds)).to_i
      hpxml_bldg.building_construction.number_of_bathrooms_isdefaulted = true
    end
    if hpxml_bldg.building_construction.number_of_units.nil?
      hpxml_bldg.building_construction.number_of_units = 1
      hpxml_bldg.building_construction.number_of_units_isdefaulted = true
    end
  end

  def self.apply_zone_spaces(hpxml_bldg)
    hpxml_bldg.conditioned_spaces.each do |space|
      if space.fenestration_load_procedure.nil?
        space.fenestration_load_procedure = HPXML::SpaceFenestrationLoadProcedureStandard
        space.fenestration_load_procedure_isdefaulted = true
      end
    end
  end

  def self.apply_climate_and_risk_zones(hpxml_bldg, epw_file)
    if (not epw_file.nil?) && hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.empty?
      zone = Location.get_climate_zone_iecc(epw_file.wmoNumber)
      if not zone.nil?
        hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(zone: zone,
                                                                 year: 2006,
                                                                 zone_isdefaulted: true,
                                                                 year_isdefaulted: true)
      end
    end
  end

  def self.apply_attics(hpxml_bldg)
    hpxml_bldg.attics.each do |attic|
      next unless attic.within_infiltration_volume.nil?

      if [HPXML::AtticTypeUnvented].include? attic.attic_type
        attic.within_infiltration_volume = false
        attic.within_infiltration_volume_isdefaulted = true
      end
    end

    return unless hpxml_bldg.has_location(HPXML::LocationAtticVented)

    vented_attics = hpxml_bldg.attics.select { |a| a.attic_type == HPXML::AtticTypeVented }
    if vented_attics.empty?
      hpxml_bldg.attics.add(id: 'VentedAttic',
                            attic_type: HPXML::AtticTypeVented)
      vented_attics << hpxml_bldg.attics[-1]
    end
    vented_attics.each do |vented_attic|
      next unless (vented_attic.vented_attic_sla.nil? && vented_attic.vented_attic_ach.nil?)

      vented_attic.vented_attic_sla = Airflow.get_default_vented_attic_sla()
      vented_attic.vented_attic_sla_isdefaulted = true
      break # EPvalidator.xml only allows a single ventilation rate
    end
  end

  def self.apply_foundations(hpxml_bldg)
    hpxml_bldg.foundations.each do |foundation|
      next unless foundation.within_infiltration_volume.nil?

      next unless [HPXML::FoundationTypeBasementUnconditioned,
                   HPXML::FoundationTypeCrawlspaceUnvented].include? foundation.foundation_type

      foundation.within_infiltration_volume = false
      foundation.within_infiltration_volume_isdefaulted = true
    end

    if hpxml_bldg.has_location(HPXML::LocationCrawlspaceVented)
      vented_crawls = hpxml_bldg.foundations.select { |f| f.foundation_type == HPXML::FoundationTypeCrawlspaceVented }
      if vented_crawls.empty?
        hpxml_bldg.foundations.add(id: 'VentedCrawlspace',
                                   foundation_type: HPXML::FoundationTypeCrawlspaceVented)
        vented_crawls << hpxml_bldg.foundations[-1]
      end
      vented_crawls.each do |vented_crawl|
        next unless vented_crawl.vented_crawlspace_sla.nil?

        vented_crawl.vented_crawlspace_sla = Airflow.get_default_vented_crawl_sla()
        vented_crawl.vented_crawlspace_sla_isdefaulted = true
        break # EPvalidator.xml only allows a single ventilation rate
      end
    end

    if hpxml_bldg.has_location(HPXML::LocationManufacturedHomeUnderBelly)
      belly_and_wing_foundations = hpxml_bldg.foundations.select { |f| f.foundation_type == HPXML::FoundationTypeBellyAndWing }
      if belly_and_wing_foundations.empty?
        hpxml_bldg.foundations.add(id: 'BellyAndWing',
                                   foundation_type: HPXML::FoundationTypeBellyAndWing)
        belly_and_wing_foundations << hpxml_bldg.foundations[-1]
      end
      belly_and_wing_foundations.each do |foundation|
        next unless foundation.belly_wing_skirt_present.nil?

        foundation.belly_wing_skirt_present_isdefaulted = true
        foundation.belly_wing_skirt_present = true
        break
      end
    end
  end

  def self.apply_infiltration(hpxml_bldg)
    infil_measurement = Airflow.get_infiltration_measurement_of_interest(hpxml_bldg.air_infiltration_measurements)
    if infil_measurement.infiltration_volume.nil?
      infil_measurement.infiltration_volume = hpxml_bldg.building_construction.conditioned_building_volume
      infil_measurement.infiltration_volume_isdefaulted = true
    end
    if infil_measurement.infiltration_height.nil?
      infil_measurement.infiltration_height = hpxml_bldg.inferred_infiltration_height(infil_measurement.infiltration_volume)
      infil_measurement.infiltration_height_isdefaulted = true
    end
    if infil_measurement.a_ext.nil?
      if (infil_measurement.infiltration_type == HPXML::InfiltrationTypeUnitTotal) &&
         [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include?(hpxml_bldg.building_construction.residential_facility_type)
        tot_cb_area, ext_cb_area = hpxml_bldg.compartmentalization_boundary_areas()
        infil_measurement.a_ext = (ext_cb_area / tot_cb_area).round(5)
        infil_measurement.a_ext_isdefaulted = true
      end
    end
  end

  def self.apply_roofs(hpxml_bldg)
    hpxml_bldg.roofs.each do |roof|
      if roof.azimuth.nil?
        roof.azimuth = get_azimuth_from_orientation(roof.orientation)
        roof.azimuth_isdefaulted = true
      end
      if roof.orientation.nil?
        roof.orientation = get_orientation_from_azimuth(roof.azimuth)
        roof.orientation_isdefaulted = true
      end
      if roof.roof_type.nil?
        roof.roof_type = HPXML::RoofTypeAsphaltShingles
        roof.roof_type_isdefaulted = true
      end
      if roof.emittance.nil?
        roof.emittance = 0.90
        roof.emittance_isdefaulted = true
      end
      if roof.radiant_barrier.nil?
        if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(roof.interior_adjacent_to)
          roof.radiant_barrier = false
          roof.radiant_barrier_isdefaulted = true
        end
      end
      if roof.radiant_barrier && roof.radiant_barrier_grade.nil?
        roof.radiant_barrier_grade = 1
        roof.radiant_barrier_grade_isdefaulted = true
      end
      if roof.roof_color.nil? && roof.solar_absorptance.nil?
        roof.roof_color = HPXML::ColorMedium
        roof.roof_color_isdefaulted = true
      end
      if roof.roof_color.nil?
        roof.roof_color = Constructions.get_default_roof_color(roof.roof_type, roof.solar_absorptance)
        roof.roof_color_isdefaulted = true
      elsif roof.solar_absorptance.nil?
        roof.solar_absorptance = Constructions.get_default_roof_solar_absorptance(roof.roof_type, roof.roof_color)
        roof.solar_absorptance_isdefaulted = true
      end
      if roof.interior_finish_type.nil?
        if HPXML::conditioned_finished_locations.include? roof.interior_adjacent_to
          roof.interior_finish_type = HPXML::InteriorFinishGypsumBoard
        else
          roof.interior_finish_type = HPXML::InteriorFinishNone
        end
        roof.interior_finish_type_isdefaulted = true
      end
      next unless roof.interior_finish_thickness.nil?

      if roof.interior_finish_type != HPXML::InteriorFinishNone
        roof.interior_finish_thickness = 0.5
        roof.interior_finish_thickness_isdefaulted = true
      end
    end
  end

  def self.apply_rim_joists(hpxml_bldg)
    hpxml_bldg.rim_joists.each do |rim_joist|
      if rim_joist.azimuth.nil?
        rim_joist.azimuth = get_azimuth_from_orientation(rim_joist.orientation)
        rim_joist.azimuth_isdefaulted = true
      end
      if rim_joist.orientation.nil?
        rim_joist.orientation = get_orientation_from_azimuth(rim_joist.azimuth)
        rim_joist.orientation_isdefaulted = true
      end

      next unless rim_joist.is_exterior

      if rim_joist.emittance.nil?
        rim_joist.emittance = 0.90
        rim_joist.emittance_isdefaulted = true
      end
      if rim_joist.siding.nil?
        rim_joist.siding = HPXML::SidingTypeWood
        rim_joist.siding_isdefaulted = true
      end
      if rim_joist.color.nil? && rim_joist.solar_absorptance.nil?
        rim_joist.color = HPXML::ColorMedium
        rim_joist.color_isdefaulted = true
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

  def self.apply_walls(hpxml_bldg)
    hpxml_bldg.walls.each do |wall|
      if wall.azimuth.nil?
        wall.azimuth = get_azimuth_from_orientation(wall.orientation)
        wall.azimuth_isdefaulted = true
      end
      if wall.orientation.nil?
        wall.orientation = get_orientation_from_azimuth(wall.azimuth)
        wall.orientation_isdefaulted = true
      end

      if wall.is_exterior
        if wall.emittance.nil?
          wall.emittance = 0.90
          wall.emittance_isdefaulted = true
        end
        if wall.siding.nil?
          wall.siding = HPXML::SidingTypeWood
          wall.siding_isdefaulted = true
        end
        if wall.color.nil? && wall.solar_absorptance.nil?
          wall.color = HPXML::ColorMedium
          wall.color_isdefaulted = true
        end
        if wall.color.nil?
          wall.color = Constructions.get_default_wall_color(wall.solar_absorptance)
          wall.color_isdefaulted = true
        elsif wall.solar_absorptance.nil?
          wall.solar_absorptance = Constructions.get_default_wall_solar_absorptance(wall.color)
          wall.solar_absorptance_isdefaulted = true
        end
      end
      if wall.interior_finish_type.nil?
        if HPXML::conditioned_finished_locations.include? wall.interior_adjacent_to
          wall.interior_finish_type = HPXML::InteriorFinishGypsumBoard
        else
          wall.interior_finish_type = HPXML::InteriorFinishNone
        end
        wall.interior_finish_type_isdefaulted = true
      end
      next unless wall.interior_finish_thickness.nil?

      if wall.interior_finish_type != HPXML::InteriorFinishNone
        wall.interior_finish_thickness = 0.5
        wall.interior_finish_thickness_isdefaulted = true
      end
      if wall.radiant_barrier.nil?
        if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(wall.interior_adjacent_to) || [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(wall.exterior_adjacent_to)
          wall.radiant_barrier = false
          wall.radiant_barrier_isdefaulted = true
        end
      end
      if wall.radiant_barrier && wall.radiant_barrier_grade.nil?
        wall.radiant_barrier_grade = 1
        wall.radiant_barrier_grade_isdefaulted = true
      end
    end
  end

  def self.apply_foundation_walls(hpxml_bldg)
    hpxml_bldg.foundation_walls.each do |foundation_wall|
      if foundation_wall.type.nil?
        foundation_wall.type = HPXML::FoundationWallTypeSolidConcrete
        foundation_wall.type_isdefaulted = true
      end
      if foundation_wall.azimuth.nil?
        foundation_wall.azimuth = get_azimuth_from_orientation(foundation_wall.orientation)
        foundation_wall.azimuth_isdefaulted = true
      end
      if foundation_wall.orientation.nil?
        foundation_wall.orientation = get_orientation_from_azimuth(foundation_wall.azimuth)
        foundation_wall.orientation_isdefaulted = true
      end
      if foundation_wall.thickness.nil?
        foundation_wall.thickness = 8.0
        foundation_wall.thickness_isdefaulted = true
      end
      if foundation_wall.area.nil?
        foundation_wall.area = foundation_wall.length * foundation_wall.height
        foundation_wall.area_isdefaulted = true
      end
      if foundation_wall.interior_finish_type.nil?
        if HPXML::conditioned_finished_locations.include? foundation_wall.interior_adjacent_to
          foundation_wall.interior_finish_type = HPXML::InteriorFinishGypsumBoard
        else
          foundation_wall.interior_finish_type = HPXML::InteriorFinishNone
        end
        foundation_wall.interior_finish_type_isdefaulted = true
      end
      if foundation_wall.insulation_interior_distance_to_top.nil?
        foundation_wall.insulation_interior_distance_to_top = 0.0
        foundation_wall.insulation_interior_distance_to_top_isdefaulted = true
      end
      if foundation_wall.insulation_interior_distance_to_bottom.nil?
        foundation_wall.insulation_interior_distance_to_bottom = foundation_wall.height
        foundation_wall.insulation_interior_distance_to_bottom_isdefaulted = true
      end
      if foundation_wall.insulation_exterior_distance_to_top.nil?
        foundation_wall.insulation_exterior_distance_to_top = 0.0
        foundation_wall.insulation_exterior_distance_to_top_isdefaulted = true
      end
      if foundation_wall.insulation_exterior_distance_to_bottom.nil?
        foundation_wall.insulation_exterior_distance_to_bottom = foundation_wall.height
        foundation_wall.insulation_exterior_distance_to_bottom_isdefaulted = true
      end
      next unless foundation_wall.interior_finish_thickness.nil?

      if foundation_wall.interior_finish_type != HPXML::InteriorFinishNone
        foundation_wall.interior_finish_thickness = 0.5
        foundation_wall.interior_finish_thickness_isdefaulted = true
      end
    end
  end

  def self.apply_floors(runner, hpxml_bldg)
    hpxml_bldg.floors.each do |floor|
      if floor.floor_or_ceiling.nil?
        if floor.is_ceiling
          floor.floor_or_ceiling = HPXML::FloorOrCeilingCeiling
          floor.floor_or_ceiling_isdefaulted = true
        elsif floor.is_floor
          floor.floor_or_ceiling = HPXML::FloorOrCeilingFloor
          floor.floor_or_ceiling_isdefaulted = true
        end
      else
        floor_is_ceiling = HPXML::is_floor_a_ceiling(floor, false)
        if not floor_is_ceiling.nil?
          if (floor.floor_or_ceiling == HPXML::FloorOrCeilingCeiling) && !floor_is_ceiling
            runner.registerWarning("Floor '#{floor.id}' has FloorOrCeiling=ceiling but it should be floor. The input will be overridden.")
            floor.floor_or_ceiling = HPXML::FloorOrCeilingFloor
            floor.floor_or_ceiling_isdefaulted = true
          elsif (floor.floor_or_ceiling == HPXML::FloorOrCeilingFloor) && floor_is_ceiling
            runner.registerWarning("Floor '#{floor.id}' has FloorOrCeiling=floor but it should be ceiling. The input will be overridden.")
            floor.floor_or_ceiling = HPXML::FloorOrCeilingCeiling
            floor.floor_or_ceiling_isdefaulted = true
          end
        end
      end

      if floor.interior_finish_type.nil?
        if floor.is_floor
          floor.interior_finish_type = HPXML::InteriorFinishNone
        elsif HPXML::conditioned_finished_locations.include? floor.interior_adjacent_to
          floor.interior_finish_type = HPXML::InteriorFinishGypsumBoard
        else
          floor.interior_finish_type = HPXML::InteriorFinishNone
        end
        floor.interior_finish_type_isdefaulted = true
      end
      next unless floor.interior_finish_thickness.nil?

      if floor.interior_finish_type != HPXML::InteriorFinishNone
        floor.interior_finish_thickness = 0.5
        floor.interior_finish_thickness_isdefaulted = true
      end
      if floor.radiant_barrier.nil?
        if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(floor.interior_adjacent_to) || [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(floor.exterior_adjacent_to)
          floor.radiant_barrier = false
          floor.radiant_barrier_isdefaulted = true
        end
      end
      if floor.radiant_barrier && floor.radiant_barrier_grade.nil?
        floor.radiant_barrier_grade = 1
        floor.radiant_barrier_grade_isdefaulted = true
      end
    end
  end

  def self.apply_slabs(hpxml_bldg)
    hpxml_bldg.slabs.each do |slab|
      if slab.thickness.nil?
        crawl_slab = [HPXML::LocationCrawlspaceVented, HPXML::LocationCrawlspaceUnvented].include?(slab.interior_adjacent_to)
        slab.thickness = crawl_slab ? 0.0 : 4.0
        slab.thickness_isdefaulted = true
      end
      if slab.gap_insulation_r_value.nil?
        slab.gap_insulation_r_value = slab.under_slab_insulation_r_value > 0 ? 5.0 : 0.0
        slab.gap_insulation_r_value_isdefaulted = true
      end
      conditioned_slab = HPXML::conditioned_finished_locations.include?(slab.interior_adjacent_to)
      if slab.carpet_r_value.nil?
        slab.carpet_r_value = conditioned_slab ? 2.0 : 0.0
        slab.carpet_r_value_isdefaulted = true
      end
      if slab.carpet_fraction.nil?
        slab.carpet_fraction = conditioned_slab ? 0.8 : 0.0
        slab.carpet_fraction_isdefaulted = true
      end
      if slab.connected_foundation_walls.empty?
        if slab.depth_below_grade.nil?
          slab.depth_below_grade = 0.0
          slab.depth_below_grade_isdefaulted = true
        end
      else
        if !slab.depth_below_grade.nil?
          slab.depth_below_grade = nil # Ignore Slab/DepthBelowGrade; use values from adjacent foundation walls instead
        end
      end
    end
  end

  def self.apply_windows(hpxml_bldg, eri_version)
    hpxml_bldg.windows.each do |window|
      if window.ufactor.nil? || window.shgc.nil?
        # Frame/Glass provided instead, fill in more defaults as needed
        if window.glass_type.nil?
          window.glass_type = HPXML::WindowGlassTypeClear
          window.glass_type_isdefaulted = true
        end
        if window.thermal_break.nil? && [HPXML::WindowFrameTypeAluminum, HPXML::WindowFrameTypeMetal].include?(window.frame_type)
          if window.glass_layers == HPXML::WindowLayersSinglePane
            window.thermal_break = false
            window.thermal_break_isdefaulted = true
          elsif window.glass_layers == HPXML::WindowLayersDoublePane
            window.thermal_break = true
            window.thermal_break_isdefaulted = true
          end
        end
        if window.gas_fill.nil?
          if window.glass_layers == HPXML::WindowLayersDoublePane
            if [HPXML::WindowGlassTypeLowE,
                HPXML::WindowGlassTypeLowEHighSolarGain,
                HPXML::WindowGlassTypeLowELowSolarGain].include? window.glass_type
              window.gas_fill = HPXML::WindowGasArgon
              window.gas_fill_isdefaulted = true
            else
              window.gas_fill = HPXML::WindowGasAir
              window.gas_fill_isdefaulted = true
            end
          elsif window.glass_layers == HPXML::WindowLayersTriplePane
            window.gas_fill = HPXML::WindowGasArgon
            window.gas_fill_isdefaulted = true
          end
        end
        # Now lookup U/SHGC based on properties
        ufactor, shgc = Constructions.get_default_window_skylight_ufactor_shgc(window, 'window')
        if window.ufactor.nil?
          window.ufactor = ufactor
          window.ufactor_isdefaulted = true
        end
        if window.shgc.nil?
          window.shgc = shgc
          window.shgc_isdefaulted = true
        end
      end
      default_shade_summer, default_shade_winter = Constructions.get_default_interior_shading_factors(eri_version, window.shgc)
      if window.azimuth.nil?
        window.azimuth = get_azimuth_from_orientation(window.orientation)
        window.azimuth_isdefaulted = true
      end
      if window.orientation.nil?
        window.orientation = get_orientation_from_azimuth(window.azimuth)
        window.orientation_isdefaulted = true
      end
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

  def self.apply_skylights(hpxml_bldg)
    hpxml_bldg.skylights.each do |skylight|
      if skylight.azimuth.nil?
        skylight.azimuth = get_azimuth_from_orientation(skylight.orientation)
        skylight.azimuth_isdefaulted = true
      end
      if skylight.orientation.nil?
        skylight.orientation = get_orientation_from_azimuth(skylight.azimuth)
        skylight.orientation_isdefaulted = true
      end
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
      next unless skylight.ufactor.nil? || skylight.shgc.nil?

      # Frame/Glass provided instead, fill in more defaults as needed
      if skylight.glass_type.nil?
        skylight.glass_type = HPXML::WindowGlassTypeClear
        skylight.glass_type_isdefaulted = true
      end
      if skylight.thermal_break.nil? && [HPXML::WindowFrameTypeAluminum, HPXML::WindowFrameTypeMetal].include?(skylight.frame_type)
        if skylight.glass_layers == HPXML::WindowLayersSinglePane
          skylight.thermal_break = false
          skylight.thermal_break_isdefaulted = true
        elsif skylight.glass_layers == HPXML::WindowLayersDoublePane
          skylight.thermal_break = true
          skylight.thermal_break_isdefaulted = true
        end
      end
      if skylight.gas_fill.nil?
        if skylight.glass_layers == HPXML::WindowLayersDoublePane
          if [HPXML::WindowGlassTypeLowE,
              HPXML::WindowGlassTypeLowEHighSolarGain,
              HPXML::WindowGlassTypeLowELowSolarGain].include? skylight.glass_type
            skylight.gas_fill = HPXML::WindowGasArgon
            skylight.gas_fill_isdefaulted = true
          else
            skylight.gas_fill = HPXML::WindowGasAir
            skylight.gas_fill_isdefaulted = true
          end
        elsif skylight.glass_layers == HPXML::WindowLayersTriplePane
          skylight.gas_fill = HPXML::WindowGasArgon
          skylight.gas_fill_isdefaulted = true
        end
      end
      # Now lookup U/SHGC based on properties
      ufactor, shgc = Constructions.get_default_window_skylight_ufactor_shgc(skylight, 'skylight')
      if skylight.ufactor.nil?
        skylight.ufactor = ufactor
        skylight.ufactor_isdefaulted = true
      end
      if skylight.shgc.nil?
        skylight.shgc = shgc
        skylight.shgc_isdefaulted = true
      end
    end
  end

  def self.apply_doors(hpxml_bldg)
    hpxml_bldg.doors.each do |door|
      if door.azimuth.nil?
        door.azimuth = get_azimuth_from_orientation(door.orientation)
        door.azimuth_isdefaulted = true
      end
      if door.orientation.nil?
        door.orientation = get_orientation_from_azimuth(door.azimuth)
        door.orientation_isdefaulted = true
      end

      next unless door.azimuth.nil?

      if (not door.wall.nil?) && (not door.wall.azimuth.nil?)
        door.azimuth = door.wall.azimuth
      else
        primary_azimuth = get_default_azimuths(hpxml_bldg)[0]
        door.azimuth = primary_azimuth
        door.azimuth_isdefaulted = true
      end
    end
  end

  def self.apply_partition_wall_mass(hpxml_bldg)
    if hpxml_bldg.partition_wall_mass.area_fraction.nil?
      hpxml_bldg.partition_wall_mass.area_fraction = 1.0
      hpxml_bldg.partition_wall_mass.area_fraction_isdefaulted = true
    end
    if hpxml_bldg.partition_wall_mass.interior_finish_type.nil?
      hpxml_bldg.partition_wall_mass.interior_finish_type = HPXML::InteriorFinishGypsumBoard
      hpxml_bldg.partition_wall_mass.interior_finish_type_isdefaulted = true
    end
    if hpxml_bldg.partition_wall_mass.interior_finish_thickness.nil?
      hpxml_bldg.partition_wall_mass.interior_finish_thickness = 0.5
      hpxml_bldg.partition_wall_mass.interior_finish_thickness_isdefaulted = true
    end
  end

  def self.apply_furniture_mass(hpxml_bldg)
    if hpxml_bldg.furniture_mass.area_fraction.nil?
      hpxml_bldg.furniture_mass.area_fraction = 0.4
      hpxml_bldg.furniture_mass.area_fraction_isdefaulted = true
    end
    if hpxml_bldg.furniture_mass.type.nil?
      hpxml_bldg.furniture_mass.type = HPXML::FurnitureMassTypeLightWeight
      hpxml_bldg.furniture_mass.type_isdefaulted = true
    end
  end

  def self.apply_hvac(runner, hpxml, hpxml_bldg, weather, convert_shared_systems)
    if convert_shared_systems
      HVAC.apply_shared_systems(hpxml_bldg)
    end

    # Convert negative values (e.g., -1) to nil as appropriate
    # This is needed to support autosizing in OS-ERI, where the capacities are required inputs
    hpxml_bldg.hvac_systems.each do |hvac_system|
      if hvac_system.respond_to?(:heating_capacity) && hvac_system.heating_capacity.to_f < 0
        hvac_system.heating_capacity = nil
      end
      if hvac_system.respond_to?(:cooling_capacity) && hvac_system.cooling_capacity.to_f < 0
        hvac_system.cooling_capacity = nil
      end
      if hvac_system.respond_to?(:heating_capacity_17F) && hvac_system.heating_capacity_17F.to_f < 0
        hvac_system.heating_capacity_17F = nil
      end
      if hvac_system.respond_to?(:backup_heating_capacity) && hvac_system.backup_heating_capacity.to_f < 0
        hvac_system.backup_heating_capacity = nil
      end
    end

    # Convert SEER2/HSPF2 to SEER/HSPF
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type
      next unless cooling_system.cooling_efficiency_seer.nil?

      is_ducted = !cooling_system.distribution_system_idref.nil?
      cooling_system.cooling_efficiency_seer = HVAC.calc_seer_from_seer2(cooling_system.cooling_efficiency_seer2, is_ducted).round(2)
      cooling_system.cooling_efficiency_seer_isdefaulted = true
      cooling_system.cooling_efficiency_seer2 = nil
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type
      next unless heat_pump.cooling_efficiency_seer.nil?

      is_ducted = !heat_pump.distribution_system_idref.nil?
      heat_pump.cooling_efficiency_seer = HVAC.calc_seer_from_seer2(heat_pump.cooling_efficiency_seer2, is_ducted).round(2)
      heat_pump.cooling_efficiency_seer_isdefaulted = true
      heat_pump.cooling_efficiency_seer2 = nil
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type
      next unless heat_pump.heating_efficiency_hspf.nil?

      is_ducted = !heat_pump.distribution_system_idref.nil?
      heat_pump.heating_efficiency_hspf = HVAC.calc_hspf_from_hspf2(heat_pump.heating_efficiency_hspf2, is_ducted).round(2)
      heat_pump.heating_efficiency_hspf_isdefaulted = true
      heat_pump.heating_efficiency_hspf2 = nil
    end

    # Default HVAC autosizing factors
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless cooling_system.cooling_autosizing_factor.nil?

      cooling_system.cooling_autosizing_factor = 1.0
      cooling_system.cooling_autosizing_factor_isdefaulted = true
    end
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.heating_autosizing_factor.nil?

      heating_system.heating_autosizing_factor = 1.0
      heating_system.heating_autosizing_factor_isdefaulted = true
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      if heat_pump.heating_autosizing_factor.nil?
        heat_pump.heating_autosizing_factor = 1.0
        heat_pump.heating_autosizing_factor_isdefaulted = true
      end
      if heat_pump.cooling_autosizing_factor.nil?
        heat_pump.cooling_autosizing_factor = 1.0
        heat_pump.cooling_autosizing_factor_isdefaulted = true
      end
      if (heat_pump.backup_type == HPXML::HeatPumpBackupTypeIntegrated) && heat_pump.backup_heating_autosizing_factor.nil?
        heat_pump.backup_heating_autosizing_factor = 1.0
        heat_pump.backup_heating_autosizing_factor_isdefaulted = true
      end
    end

    # Default AC/HP compressor type
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless cooling_system.compressor_type.nil?

      cooling_system.compressor_type = HVAC.get_default_compressor_type(cooling_system.cooling_system_type, cooling_system.cooling_efficiency_seer)
      cooling_system.compressor_type_isdefaulted = true
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless heat_pump.compressor_type.nil?

      heat_pump.compressor_type = HVAC.get_default_compressor_type(heat_pump.heat_pump_type, heat_pump.cooling_efficiency_seer)
      heat_pump.compressor_type_isdefaulted = true
    end

    # Default HP heating capacity retention
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless heat_pump.heating_capacity_retention_fraction.nil?
      next unless heat_pump.heating_capacity_17F.nil?
      next if [HPXML::HVACTypeHeatPumpGroundToAir, HPXML::HVACTypeHeatPumpWaterLoopToAir].include? heat_pump.heat_pump_type
      next unless heat_pump.heating_detailed_performance_data.empty? # set after hvac sizing

      heat_pump.heating_capacity_retention_temp, heat_pump.heating_capacity_retention_fraction = HVAC.get_default_heating_capacity_retention(heat_pump.compressor_type, heat_pump.heating_efficiency_hspf)
      heat_pump.heating_capacity_retention_fraction_isdefaulted = true
      heat_pump.heating_capacity_retention_temp_isdefaulted = true
    end

    # Default HP compressor lockout temp
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless heat_pump.compressor_lockout_temp.nil?
      next unless heat_pump.backup_heating_switchover_temp.nil?
      next if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir

      if heat_pump.backup_type == HPXML::HeatPumpBackupTypeIntegrated
        hp_backup_fuel = heat_pump.backup_heating_fuel
      elsif not heat_pump.backup_system.nil?
        hp_backup_fuel = heat_pump.backup_system.heating_system_fuel
      end

      if (not hp_backup_fuel.nil?) && (hp_backup_fuel != HPXML::FuelTypeElectricity)
        # Fuel backup
        heat_pump.compressor_lockout_temp = 25.0 # deg-F
      else
        # Electric backup or no backup
        if heat_pump.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
          heat_pump.compressor_lockout_temp = -20.0 # deg-F
        else
          heat_pump.compressor_lockout_temp = 0.0 # deg-F
        end
      end
      heat_pump.compressor_lockout_temp_isdefaulted = true
    end

    # Default HP backup lockout temp
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next if heat_pump.backup_type.nil?
      next unless heat_pump.backup_heating_lockout_temp.nil?
      next unless heat_pump.backup_heating_switchover_temp.nil?

      if heat_pump.backup_type == HPXML::HeatPumpBackupTypeIntegrated
        hp_backup_fuel = heat_pump.backup_heating_fuel
      else
        hp_backup_fuel = heat_pump.backup_system.heating_system_fuel
      end

      if hp_backup_fuel == HPXML::FuelTypeElectricity
        heat_pump.backup_heating_lockout_temp = 40.0 # deg-F
      else
        heat_pump.backup_heating_lockout_temp = 50.0 # deg-F
      end
      heat_pump.backup_heating_lockout_temp_isdefaulted = true
    end

    # Default electric resistance distribution
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.heating_system_type == HPXML::HVACTypeElectricResistance
      next unless heating_system.electric_resistance_distribution.nil?

      heating_system.electric_resistance_distribution = HPXML::ElectricResistanceDistributionBaseboard
      heating_system.electric_resistance_distribution_isdefaulted = true
    end

    # Default boiler EAE
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.electric_auxiliary_energy.nil?

      heating_system.electric_auxiliary_energy_isdefaulted = true
      heating_system.electric_auxiliary_energy = HVAC.get_default_boiler_eae(heating_system)
      heating_system.shared_loop_watts = nil
      heating_system.shared_loop_motor_efficiency = nil
      heating_system.fan_coil_watts = nil
    end

    # Default AC/HP sensible heat ratio
    hpxml_bldg.cooling_systems.each do |cooling_system|
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
      elsif cooling_system.cooling_system_type == HPXML::HVACTypeRoomAirConditioner ||
            cooling_system.cooling_system_type == HPXML::HVACTypePTAC
        cooling_system.cooling_shr = 0.65
        cooling_system.cooling_shr_isdefaulted = true
      elsif cooling_system.cooling_system_type == HPXML::HVACTypeMiniSplitAirConditioner
        cooling_system.cooling_shr = 0.73
        cooling_system.cooling_shr_isdefaulted = true
      end
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless heat_pump.cooling_shr.nil?

      if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpAirToAir
        if heat_pump.compressor_type == HPXML::HVACCompressorTypeSingleStage
          heat_pump.cooling_shr = 0.73
        elsif heat_pump.compressor_type == HPXML::HVACCompressorTypeTwoStage
          heat_pump.cooling_shr = 0.73
        elsif heat_pump.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
          heat_pump.cooling_shr = 0.78
        end
        heat_pump.cooling_shr_isdefaulted = true
      elsif heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpMiniSplit
        heat_pump.cooling_shr = 0.73
        heat_pump.cooling_shr_isdefaulted = true
      elsif heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
        heat_pump.cooling_shr = 0.73
        heat_pump.cooling_shr_isdefaulted = true
      elsif heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpPTHP ||
            heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpRoom
        heat_pump.cooling_shr = 0.65
        heat_pump.cooling_shr_isdefaulted = true
      end
    end

    # GSHP pump power
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
      next unless heat_pump.pump_watts_per_ton.nil?

      heat_pump.pump_watts_per_ton = HVAC.get_default_gshp_pump_power()
      heat_pump.pump_watts_per_ton_isdefaulted = true
    end

    # Charge defect ratio
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type
      next unless cooling_system.charge_defect_ratio.nil?

      cooling_system.charge_defect_ratio = 0.0
      cooling_system.charge_defect_ratio_isdefaulted = true
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit,
                   HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type
      next unless heat_pump.charge_defect_ratio.nil?

      heat_pump.charge_defect_ratio = 0.0
      heat_pump.charge_defect_ratio_isdefaulted = true
    end

    # Airflow defect ratio
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type
      next unless heating_system.airflow_defect_ratio.nil?

      heating_system.airflow_defect_ratio = 0.0
      heating_system.airflow_defect_ratio_isdefaulted = true
    end
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type
      next unless cooling_system.airflow_defect_ratio.nil?

      cooling_system.airflow_defect_ratio = 0.0
      cooling_system.airflow_defect_ratio_isdefaulted = true
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpGroundToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump.heat_pump_type
      next unless heat_pump.airflow_defect_ratio.nil?

      heat_pump.airflow_defect_ratio = 0.0
      heat_pump.airflow_defect_ratio_isdefaulted = true
    end

    # Fan power
    psc_watts_per_cfm = 0.5 # W/cfm, PSC fan
    ecm_watts_per_cfm = 0.375 # W/cfm, ECM fan
    mini_split_ductless_watts_per_cfm = 0.07 # W/cfm
    mini_split_ducted_watts_per_cfm = 0.18 # W/cfm
    hpxml_bldg.heating_systems.each do |heating_system|
      if [HPXML::HVACTypeFurnace].include? heating_system.heating_system_type
        if heating_system.fan_watts_per_cfm.nil?
          if (not heating_system.distribution_system.nil?) && (heating_system.distribution_system.air_type == HPXML::AirTypeGravity)
            heating_system.fan_watts_per_cfm = 0.0
          elsif heating_system.heating_efficiency_afue > 0.9 # HEScore assumption
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
             HPXML::HVACTypeSpaceHeater,
             HPXML::HVACTypeFireplace].include? heating_system.heating_system_type
        if heating_system.fan_watts.nil?
          heating_system.fan_watts = 0.0 # W/cfm, assume no fan power
          heating_system.fan_watts_isdefaulted = true
        end
      end
    end
    hpxml_bldg.cooling_systems.each do |cooling_system|
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
        else
          cooling_system.fan_watts_per_cfm = mini_split_ductless_watts_per_cfm
        end
        cooling_system.fan_watts_per_cfm_isdefaulted = true
      elsif [HPXML::HVACTypeEvaporativeCooler].include? cooling_system.cooling_system_type
        # Depends on airflow rate, so defaulted in hvac_sizing.rb
      end
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
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
        else
          heat_pump.fan_watts_per_cfm = mini_split_ductless_watts_per_cfm
        end
        heat_pump.fan_watts_per_cfm_isdefaulted = true
      end
    end

    # Crankcase heater power [Watts]
    hpxml_bldg.cooling_systems.each do |cooling_system|
      next unless [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeMiniSplitAirConditioner, HPXML::HVACTypeRoomAirConditioner, HPXML::HVACTypePTAC].include? cooling_system.cooling_system_type
      next unless cooling_system.crankcase_heater_watts.nil?

      if [HPXML::HVACTypeRoomAirConditioner, HPXML::HVACTypePTAC].include? cooling_system.cooling_system_type
        cooling_system.crankcase_heater_watts = 0.0
      else
        cooling_system.crankcase_heater_watts = 50 # From RESNET Publication No. 002-2017
      end
      cooling_system.crankcase_heater_watts_isdefaulted = true
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      next unless [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit, HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include? heat_pump.heat_pump_type
      next unless heat_pump.crankcase_heater_watts.nil?

      if [HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include? heat_pump.heat_pump_type
        heat_pump.crankcase_heater_watts = 0.0
      else
        heat_pump.crankcase_heater_watts = heat_pump.fraction_heat_load_served <= 0 ? 0.0 : 50 # From RESNET Publication No. 002-2017
      end
      heat_pump.crankcase_heater_watts_isdefaulted = true
    end

    # Pilot Light
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless [HPXML::HVACTypeFurnace,
                   HPXML::HVACTypeWallFurnace,
                   HPXML::HVACTypeFloorFurnace,
                   HPXML::HVACTypeFireplace,
                   HPXML::HVACTypeStove,
                   HPXML::HVACTypeBoiler].include? heating_system.heating_system_type

      if heating_system.pilot_light.nil?
        heating_system.pilot_light = false
        heating_system.pilot_light_isdefaulted = true
      end
      if heating_system.pilot_light && heating_system.pilot_light_btuh.nil?
        heating_system.pilot_light_btuh = 500.0
        heating_system.pilot_light_btuh_isdefaulted = true
      end
    end

    # Detailed HVAC performance
    hpxml_bldg.cooling_systems.each do |cooling_system|
      clg_ap = cooling_system.additional_properties
      if [HPXML::HVACTypeCentralAirConditioner,
          HPXML::HVACTypeMiniSplitAirConditioner,
          HPXML::HVACTypeRoomAirConditioner,
          HPXML::HVACTypePTAC].include? cooling_system.cooling_system_type
        if [HPXML::HVACTypeRoomAirConditioner,
            HPXML::HVACTypePTAC].include? cooling_system.cooling_system_type
          use_eer = true
        else
          use_eer = false
        end
        # Note: We use HP cooling curve so that a central AC behaves the same.
        HVAC.set_fan_power_rated(cooling_system, use_eer)
        HVAC.set_cool_curves_central_air_source(runner, cooling_system, use_eer)

      elsif [HPXML::HVACTypeEvaporativeCooler].include? cooling_system.cooling_system_type
        clg_ap.effectiveness = 0.72 # Assumption from HEScore

      end
    end
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless [HPXML::HVACTypeStove,
                   HPXML::HVACTypeSpaceHeater,
                   HPXML::HVACTypeWallFurnace,
                   HPXML::HVACTypeFloorFurnace,
                   HPXML::HVACTypeFireplace].include? heating_system.heating_system_type

      heating_system.additional_properties.heat_rated_cfm_per_ton = HVAC.get_default_heat_cfm_per_ton(HPXML::HVACCompressorTypeSingleStage, true)
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      if [HPXML::HVACTypeHeatPumpAirToAir,
          HPXML::HVACTypeHeatPumpMiniSplit,
          HPXML::HVACTypeHeatPumpPTHP,
          HPXML::HVACTypeHeatPumpRoom].include? heat_pump.heat_pump_type
        if [HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include? heat_pump.heat_pump_type
          use_eer_cop = true
        else
          use_eer_cop = false
        end
        HVAC.set_fan_power_rated(heat_pump, use_eer_cop)
        HVAC.set_heat_pump_temperatures(heat_pump, runner)
        HVAC.set_cool_curves_central_air_source(runner, heat_pump, use_eer_cop)
        HVAC.set_heat_curves_central_air_source(heat_pump, use_eer_cop)

      elsif [HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type
        if heat_pump.geothermal_loop.nil?
          if hpxml.buildings.size > 1
            bldg_idx = hpxml.buildings.index(hpxml_bldg)
            loop_id = "GeothermalLoop#{hpxml_bldg.geothermal_loops.size + 1}_#{bldg_idx + 1}"
          else
            loop_id = "GeothermalLoop#{hpxml_bldg.geothermal_loops.size + 1}"
          end
          hpxml_bldg.geothermal_loops.add(id: loop_id,
                                          loop_configuration: HPXML::GeothermalLoopLoopConfigurationVertical)
          heat_pump.geothermal_loop_idref = hpxml_bldg.geothermal_loops[-1].id
        end

        if heat_pump.geothermal_loop.pipe_diameter.nil?
          heat_pump.geothermal_loop.pipe_diameter = 1.25 # in
          heat_pump.geothermal_loop.pipe_diameter_isdefaulted = true
        end

        HVAC.set_gshp_assumptions(heat_pump, weather)
        HVAC.set_curves_gshp(heat_pump)

        if heat_pump.geothermal_loop.bore_spacing.nil?
          heat_pump.geothermal_loop.bore_spacing = 16.4 # ft, distance between bores
          heat_pump.geothermal_loop.bore_spacing_isdefaulted = true
        end

        if heat_pump.geothermal_loop.bore_diameter.nil?
          heat_pump.geothermal_loop.bore_diameter = 5.0 # in
          heat_pump.geothermal_loop.bore_diameter_isdefaulted = true
        end

        if heat_pump.geothermal_loop.grout_type.nil? && heat_pump.geothermal_loop.grout_conductivity.nil?
          heat_pump.geothermal_loop.grout_type = HPXML::GeothermalLoopGroutOrPipeTypeStandard
          heat_pump.geothermal_loop.grout_type_isdefaulted = true
        end

        if heat_pump.geothermal_loop.grout_conductivity.nil?
          if heat_pump.geothermal_loop.grout_type == HPXML::GeothermalLoopGroutOrPipeTypeStandard
            heat_pump.geothermal_loop.grout_conductivity = 0.75 # Btu/h-ft-R
          elsif heat_pump.geothermal_loop.grout_type == HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced
            heat_pump.geothermal_loop.grout_conductivity = 1.2 # Btu/h-ft-R
          end
          heat_pump.geothermal_loop.grout_conductivity_isdefaulted = true
        end

        if heat_pump.geothermal_loop.pipe_type.nil? && heat_pump.geothermal_loop.pipe_conductivity.nil?
          heat_pump.geothermal_loop.pipe_type = HPXML::GeothermalLoopGroutOrPipeTypeStandard
          heat_pump.geothermal_loop.pipe_type_isdefaulted = true
        end

        if heat_pump.geothermal_loop.pipe_conductivity.nil?
          if heat_pump.geothermal_loop.pipe_type == HPXML::GeothermalLoopGroutOrPipeTypeStandard
            heat_pump.geothermal_loop.pipe_conductivity = 0.23 # Btu/h-ft-R; Pipe thermal conductivity, default to high density polyethylene
          elsif heat_pump.geothermal_loop.pipe_type == HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced
            heat_pump.geothermal_loop.pipe_conductivity = 0.40 # Btu/h-ft-R; 0.7 W/m-K from https://www.dropbox.com/scl/fi/91yp8e9v34vdh1isvrfvy/GeoPerformX-Spec-Sheet.pdf?rlkey=kw7p01gs46z9lfjs78bo8aujq&dl=0
          end
          heat_pump.geothermal_loop.pipe_conductivity_isdefaulted = true
        end

        if heat_pump.geothermal_loop.shank_spacing.nil?
          hp_ap = heat_pump.additional_properties
          heat_pump.geothermal_loop.shank_spacing = (hp_ap.u_tube_spacing + hp_ap.pipe_od).round(2) # Distance from center of pipe to center of pipe
          heat_pump.geothermal_loop.shank_spacing_isdefaulted = true
        end
      elsif [HPXML::HVACTypeHeatPumpWaterLoopToAir].include? heat_pump.heat_pump_type
        HVAC.set_heat_pump_temperatures(heat_pump, runner)

      end
    end
  end

  def self.apply_detailed_performance_data_for_var_speed_systems(hpxml_bldg)
    (hpxml_bldg.cooling_systems + hpxml_bldg.heat_pumps).each do |hvac_system|
      is_hp = hvac_system.is_a? HPXML::HeatPump
      system_type = is_hp ? hvac_system.heat_pump_type : hvac_system.cooling_system_type
      next unless [HPXML::HVACTypeCentralAirConditioner,
                   HPXML::HVACTypeMiniSplitAirConditioner,
                   HPXML::HVACTypeHeatPumpAirToAir,
                   HPXML::HVACTypeHeatPumpMiniSplit].include? system_type

      next unless hvac_system.compressor_type == HPXML::HVACCompressorTypeVariableSpeed

      HVAC.drop_intermediate_speeds(hvac_system)

      hvac_ap = hvac_system.additional_properties
      if hvac_system.cooling_detailed_performance_data.empty?
        HVAC.set_cool_detailed_performance_data(hvac_system)
      else
        # process capacity fraction of nominal
        hvac_system.cooling_detailed_performance_data.each do |dp|
          next unless dp.capacity.nil?

          dp.capacity = (dp.capacity_fraction_of_nominal * hvac_system.cooling_capacity).round(3)
          dp.capacity_isdefaulted = true
        end

        # override some properties based on detailed performance data
        cool_rated_capacity = [hvac_system.cooling_capacity, 1.0].max
        cool_max_capacity = [hvac_system.cooling_detailed_performance_data.find { |dp| (dp.outdoor_temperature == HVAC::AirSourceCoolRatedODB) && (dp.capacity_description == HPXML::CapacityDescriptionMaximum) }.capacity, 1.0].max
        cool_min_capacity = [hvac_system.cooling_detailed_performance_data.find { |dp| (dp.outdoor_temperature == HVAC::AirSourceCoolRatedODB) && (dp.capacity_description == HPXML::CapacityDescriptionMinimum) }.capacity, 1.0].max
        hvac_ap.cool_capacity_ratios = [cool_min_capacity / cool_rated_capacity, cool_max_capacity / cool_rated_capacity]
        hvac_ap.cool_fan_speed_ratios = HVAC.calc_fan_speed_ratios(hvac_ap.cool_capacity_ratios, hvac_ap.cool_rated_cfm_per_ton, hvac_ap.cool_rated_airflow_rate)
      end
      if is_hp
        if hvac_system.heating_detailed_performance_data.empty?
          HVAC.set_heat_detailed_performance_data(hvac_system)
        else
          # process capacity fraction of nominal
          hvac_system.heating_detailed_performance_data.each do |dp|
            next unless dp.capacity.nil?

            dp.capacity = (dp.capacity_fraction_of_nominal * hvac_system.heating_capacity).round(3)
            dp.capacity_isdefaulted = true
          end

          if hvac_system.heating_capacity_retention_fraction.nil? && hvac_system.heating_capacity_17F.nil?
            # Calculate heating capacity retention at 5F outdoor drybulb
            target_odb = 5.0
            max_capacity_47 = hvac_system.heating_detailed_performance_data.find { |dp| dp.outdoor_temperature == HVAC::AirSourceHeatRatedODB && dp.capacity_description == HPXML::CapacityDescriptionMaximum }.capacity
            hvac_system.heating_capacity_retention_fraction = (HVAC.interpolate_to_odb_table_point(hvac_system.heating_detailed_performance_data, HPXML::CapacityDescriptionMaximum, target_odb, :capacity) / max_capacity_47).round(5)
            hvac_system.heating_capacity_retention_fraction = 0.0 if hvac_system.heating_capacity_retention_fraction < 0
            hvac_system.heating_capacity_retention_temp = target_odb
            hvac_system.heating_capacity_retention_fraction_isdefaulted = true
            hvac_system.heating_capacity_retention_temp_isdefaulted = true
          end
          # override some properties based on detailed performance data
          heat_rated_capacity = [hvac_system.heating_capacity, 1.0].max
          heat_max_capacity = [hvac_system.heating_detailed_performance_data.find { |dp| (dp.outdoor_temperature == HVAC::AirSourceHeatRatedODB) && (dp.capacity_description == HPXML::CapacityDescriptionMaximum) }.capacity, 1.0].max
          heat_min_capacity = [hvac_system.heating_detailed_performance_data.find { |dp| (dp.outdoor_temperature == HVAC::AirSourceHeatRatedODB) && (dp.capacity_description == HPXML::CapacityDescriptionMinimum) }.capacity, 1.0].max
          hvac_ap.heat_capacity_ratios = [heat_min_capacity / heat_rated_capacity, heat_max_capacity / heat_rated_capacity]
          hvac_ap.heat_fan_speed_ratios = HVAC.calc_fan_speed_ratios(hvac_ap.heat_capacity_ratios, hvac_ap.heat_rated_cfm_per_ton, hvac_ap.heat_rated_airflow_rate)
        end
      end
    end
  end

  def self.apply_hvac_control(hpxml_bldg, schedules_file, eri_version)
    hpxml_bldg.hvac_controls.each do |hvac_control|
      schedules_file_includes_heating_setpoint_temp = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:HeatingSetpoint].name))
      if hvac_control.heating_setpoint_temp.nil? && hvac_control.weekday_heating_setpoints.nil? && !schedules_file_includes_heating_setpoint_temp
        # No heating setpoints; set a default heating setpoint for, e.g., natural ventilation
        htg_weekday_setpoints, htg_weekend_setpoints = HVAC.get_default_heating_setpoint(HPXML::HVACControlTypeManual, eri_version)
        if htg_weekday_setpoints.split(', ').uniq.size == 1 && htg_weekend_setpoints.split(', ').uniq.size == 1 && htg_weekday_setpoints.split(', ').uniq == htg_weekend_setpoints.split(', ').uniq
          hvac_control.heating_setpoint_temp = htg_weekend_setpoints.split(', ').uniq[0].to_f
        else
          fail 'Unexpected heating setpoints.'
        end
        hvac_control.heating_setpoint_temp_isdefaulted = true
      end

      schedules_file_includes_cooling_setpoint_temp = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:CoolingSetpoint].name))
      if hvac_control.cooling_setpoint_temp.nil? && hvac_control.weekday_cooling_setpoints.nil? && !schedules_file_includes_cooling_setpoint_temp
        # No cooling setpoints; set a default cooling setpoint for, e.g., natural ventilation
        clg_weekday_setpoints, clg_weekend_setpoints = HVAC.get_default_cooling_setpoint(HPXML::HVACControlTypeManual, eri_version)
        if clg_weekday_setpoints.split(', ').uniq.size == 1 && clg_weekend_setpoints.split(', ').uniq.size == 1 && clg_weekday_setpoints.split(', ').uniq == clg_weekend_setpoints.split(', ').uniq
          hvac_control.cooling_setpoint_temp = clg_weekend_setpoints.split(', ').uniq[0].to_f
        else
          fail 'Unexpected cooling setpoints.'
        end
        hvac_control.cooling_setpoint_temp_isdefaulted = true
      end

      if hvac_control.heating_setback_start_hour.nil? && (not hvac_control.heating_setback_temp.nil?) && !schedules_file_includes_heating_setpoint_temp
        hvac_control.heating_setback_start_hour = 23 # 11 pm
        hvac_control.heating_setback_start_hour_isdefaulted = true
      end

      if hvac_control.cooling_setup_start_hour.nil? && (not hvac_control.cooling_setup_temp.nil?) && !schedules_file_includes_cooling_setpoint_temp
        hvac_control.cooling_setup_start_hour = 9 # 9 am
        hvac_control.cooling_setup_start_hour_isdefaulted = true
      end

      if hvac_control.seasons_heating_begin_month.nil? || hvac_control.seasons_heating_begin_day.nil? ||
         hvac_control.seasons_heating_end_month.nil? || hvac_control.seasons_heating_end_day.nil?
        hvac_control.seasons_heating_begin_month = 1
        hvac_control.seasons_heating_begin_day = 1
        hvac_control.seasons_heating_end_month = 12
        hvac_control.seasons_heating_end_day = 31
        hvac_control.seasons_heating_begin_month_isdefaulted = true
        hvac_control.seasons_heating_begin_day_isdefaulted = true
        hvac_control.seasons_heating_end_month_isdefaulted = true
        hvac_control.seasons_heating_end_day_isdefaulted = true
      end

      next unless hvac_control.seasons_cooling_begin_month.nil? || hvac_control.seasons_cooling_begin_day.nil? ||
                  hvac_control.seasons_cooling_end_month.nil? || hvac_control.seasons_cooling_end_day.nil?

      hvac_control.seasons_cooling_begin_month = 1
      hvac_control.seasons_cooling_begin_day = 1
      hvac_control.seasons_cooling_end_month = 12
      hvac_control.seasons_cooling_end_day = 31
      hvac_control.seasons_cooling_begin_month_isdefaulted = true
      hvac_control.seasons_cooling_begin_day_isdefaulted = true
      hvac_control.seasons_cooling_end_month_isdefaulted = true
      hvac_control.seasons_cooling_end_day_isdefaulted = true
    end
  end

  def self.apply_hvac_distribution(hpxml_bldg, ncfl, ncfl_ag)
    hpxml_bldg.hvac_distributions.each do |hvac_distribution|
      next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
      next if hvac_distribution.ducts.empty?

      supply_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeSupply }
      return_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeReturn }

      # Default return registers
      if hvac_distribution.number_of_return_registers.nil? && (return_ducts.size > 0)
        hvac_distribution.number_of_return_registers = ncfl.ceil # Add 1 return register per conditioned floor if not provided
        hvac_distribution.number_of_return_registers_isdefaulted = true
      end

      cfa_served = hvac_distribution.conditioned_floor_area_served
      n_returns = hvac_distribution.number_of_return_registers

      if hvac_distribution.ducts[0].duct_location.nil?
        # Default both duct location(s) and duct surface area(s)
        [supply_ducts, return_ducts].each do |ducts|
          ducts.each do |duct|
            primary_duct_area, secondary_duct_area = HVAC.get_default_duct_surface_area(duct.duct_type, ncfl_ag, cfa_served, n_returns).map { |area| area / ducts.size }
            primary_duct_location, secondary_duct_location = HVAC.get_default_duct_locations(hpxml_bldg)
            if primary_duct_location.nil? # If a home doesn't have any unconditioned spaces, place all ducts in conditioned space.
              duct.duct_surface_area = primary_duct_area + secondary_duct_area
              duct.duct_surface_area_isdefaulted = true
              duct.duct_location = secondary_duct_location
              duct.duct_location_isdefaulted = true
            else
              duct.duct_surface_area = primary_duct_area
              duct.duct_surface_area_isdefaulted = true
              duct.duct_location = primary_duct_location
              duct.duct_location_isdefaulted = true

              if secondary_duct_area > 0
                hvac_distribution.ducts.add(id: "#{duct.id}_secondary",
                                            duct_type: duct.duct_type,
                                            duct_insulation_r_value: duct.duct_insulation_r_value,
                                            duct_location: secondary_duct_location,
                                            duct_location_isdefaulted: true,
                                            duct_surface_area: secondary_duct_area,
                                            duct_surface_area_isdefaulted: true)
              end
            end
          end
        end

      elsif hvac_distribution.ducts[0].duct_surface_area.nil?
        # Default duct surface area(s)
        [supply_ducts, return_ducts].each do |ducts|
          ducts.each do |duct|
            total_duct_area = HVAC.get_default_duct_surface_area(duct.duct_type, ncfl_ag, cfa_served, n_returns).sum()
            duct.duct_surface_area = total_duct_area * duct.duct_fraction_area
            duct.duct_surface_area_isdefaulted = true
          end
        end
      end

      # Calculate FractionDuctArea from DuctSurfaceArea
      supply_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeSupply }
      return_ducts = hvac_distribution.ducts.select { |duct| duct.duct_type == HPXML::DuctTypeReturn }
      total_supply_area = supply_ducts.map { |d| d.duct_surface_area }.sum
      total_return_area = return_ducts.map { |d| d.duct_surface_area }.sum
      (supply_ducts + return_ducts).each do |duct|
        next unless duct.duct_fraction_area.nil?

        if duct.duct_type == HPXML::DuctTypeSupply
          if total_supply_area > 0
            duct.duct_fraction_area = (duct.duct_surface_area / total_supply_area).round(3)
          else
            duct.duct_fraction_area = (1.0 / supply_ducts.size).round(3) # Arbitrary
          end
          duct.duct_fraction_area_isdefaulted = true
        elsif duct.duct_type == HPXML::DuctTypeReturn
          if total_return_area > 0
            duct.duct_fraction_area = (duct.duct_surface_area / total_return_area).round(3)
          else
            duct.duct_fraction_area = (1.0 / return_ducts.size).round(3) # Arbitrary
          end
          duct.duct_fraction_area_isdefaulted = true
        end
      end

      hvac_distribution.ducts.each do |ducts|
        next unless ducts.duct_surface_area_multiplier.nil?

        ducts.duct_surface_area_multiplier = 1.0
        ducts.duct_surface_area_multiplier_isdefaulted = true
      end

      # Default buried insulation level
      hvac_distribution.ducts.each do |ducts|
        next unless ducts.duct_buried_insulation_level.nil?

        ducts.duct_buried_insulation_level = HPXML::DuctBuriedInsulationNone
        ducts.duct_buried_insulation_level_isdefaulted = true
      end

      # Default duct shape
      hvac_distribution.ducts.each do |ducts|
        next unless ducts.duct_fraction_rectangular.nil?

        if ducts.duct_shape.nil? || ducts.duct_shape == HPXML::DuctShapeOther
          if ducts.duct_type == HPXML::DuctTypeSupply
            ducts.duct_fraction_rectangular = 0.25
          elsif ducts.duct_type == HPXML::DuctTypeReturn
            ducts.duct_fraction_rectangular = 1.0
          end
        elsif ducts.duct_shape == HPXML::DuctShapeRound || ducts.duct_shape == HPXML::DuctShapeOval
          ducts.duct_fraction_rectangular = 0.0
        elsif ducts.duct_shape == HPXML::DuctShapeRectangular
          ducts.duct_fraction_rectangular = 1.0
        end
        ducts.duct_fraction_rectangular_isdefaulted = true
      end

      # Default effective R-value
      hvac_distribution.ducts.each do |ducts|
        next unless ducts.duct_effective_r_value.nil?

        ducts.duct_effective_r_value = Airflow.get_duct_effective_r_value(ducts.duct_insulation_r_value,
                                                                          ducts.duct_type,
                                                                          ducts.duct_buried_insulation_level,
                                                                          ducts.duct_fraction_rectangular)
        ducts.duct_effective_r_value_isdefaulted = true
      end
    end
  end

  def self.apply_hvac_location(hpxml_bldg)
    # This needs to come after we have applied defaults for ducts
    hpxml_bldg.hvac_systems.each do |hvac_system|
      next unless hvac_system.location.nil?

      hvac_system.location_isdefaulted = true

      if hvac_system.is_shared_system
        hvac_system.location = HPXML::LocationOtherHeatedSpace
        next
      end

      # Set default location based on distribution system
      dist_system = hvac_system.distribution_system
      if dist_system.nil?
        hvac_system.location = HPXML::LocationConditionedSpace
      else
        dist_type = dist_system.distribution_system_type
        if dist_type == HPXML::HVACDistributionTypeAir
          # Find largest unconditioned supply duct location
          uncond_duct_locations = {}
          dist_system.ducts.select { |d| d.duct_type == HPXML::DuctTypeSupply }.each do |d|
            next if HPXML::conditioned_locations_this_unit.include? d.duct_location
            next if [HPXML::LocationExteriorWall, HPXML::LocationUnderSlab].include? d.duct_location # air handler won't be here

            uncond_duct_locations[d.duct_location] = 0.0 if uncond_duct_locations[d.duct_location].nil?
            uncond_duct_locations[d.duct_location] += d.duct_surface_area
          end
          if uncond_duct_locations.empty?
            hvac_system.location = HPXML::LocationConditionedSpace
          else
            hvac_system.location = uncond_duct_locations.key(uncond_duct_locations.values.max)
            if hvac_system.location == HPXML::LocationOutside
              # DuctLocation "outside" needs to be converted to a valid UnitLocation enumeration
              hvac_system.location = HPXML::LocationOtherExterior
            end
          end
        elsif dist_type == HPXML::HVACDistributionTypeHydronic
          # Assume same default logic as a water heater
          hvac_system.location = Waterheater.get_default_location(hpxml_bldg, hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0])
        elsif dist_type == HPXML::HVACDistributionTypeDSE
          # DSE=1 implies distribution system in conditioned space
          has_dse_of_one = true
          if (hvac_system.respond_to? :fraction_heat_load_served) && (dist_system.annual_heating_dse != 1)
            has_dse_of_one = false
          end
          if (hvac_system.respond_to? :fraction_cool_load_served) && (dist_system.annual_cooling_dse != 1)
            has_dse_of_one = false
          end
          if has_dse_of_one
            hvac_system.location = HPXML::LocationConditionedSpace
          else
            hvac_system.location = HPXML::LocationUnconditionedSpace
          end
        end
      end
    end
  end

  def self.apply_ventilation_fans(hpxml_bldg, weather, cfa, nbeds, eri_version)
    # Default mech vent systems
    hpxml_bldg.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_whole_building_ventilation

      if vent_fan.is_shared_system.nil?
        vent_fan.is_shared_system = false
        vent_fan.is_shared_system_isdefaulted = true
      end

      if vent_fan.hours_in_operation.nil? && !vent_fan.is_cfis_supplemental_fan?
        vent_fan.hours_in_operation = (vent_fan.fan_type == HPXML::MechVentTypeCFIS) ? 8.0 : 24.0
        vent_fan.hours_in_operation_isdefaulted = true
      end

      if vent_fan.flow_rate.nil?
        if hpxml_bldg.ventilation_fans.select { |vf| vf.used_for_whole_building_ventilation && !vf.is_cfis_supplemental_fan? }.size > 1
          fail 'Defaulting flow rates for multiple mechanical ventilation systems is currently not supported.'
        end

        vent_fan.rated_flow_rate = Airflow.get_default_mech_vent_flow_rate(hpxml_bldg, vent_fan, weather, cfa, nbeds, eri_version).round(1)
        vent_fan.rated_flow_rate_isdefaulted = true
      end

      if vent_fan.fan_power.nil?
        vent_fan.fan_power = (vent_fan.flow_rate * Airflow.get_default_mech_vent_fan_power(vent_fan, eri_version)).round(1)
        vent_fan.fan_power_isdefaulted = true
      end
      next unless vent_fan.fan_type == HPXML::MechVentTypeCFIS

      if vent_fan.cfis_vent_mode_airflow_fraction.nil?
        vent_fan.cfis_vent_mode_airflow_fraction = 1.0
        vent_fan.cfis_vent_mode_airflow_fraction_isdefaulted = true
      end
      if vent_fan.cfis_addtl_runtime_operating_mode.nil?
        vent_fan.cfis_addtl_runtime_operating_mode = HPXML::CFISModeAirHandler
        vent_fan.cfis_addtl_runtime_operating_mode_isdefaulted = true
      end
    end

    # Default kitchen fan
    hpxml_bldg.ventilation_fans.each do |vent_fan|
      next unless (vent_fan.used_for_local_ventilation && (vent_fan.fan_location == HPXML::LocationKitchen))

      if vent_fan.count.nil?
        vent_fan.count = 1
        vent_fan.count_isdefaulted = true
      end
      if vent_fan.rated_flow_rate.nil? && vent_fan.tested_flow_rate.nil? && vent_fan.calculated_flow_rate.nil? && vent_fan.delivered_ventilation.nil?
        vent_fan.rated_flow_rate = 100.0 # cfm, per BA HSP
        vent_fan.rated_flow_rate_isdefaulted = true
      end
      if vent_fan.hours_in_operation.nil?
        vent_fan.hours_in_operation = 1.0 # hrs/day, per BA HSP
        vent_fan.hours_in_operation_isdefaulted = true
      end
      if vent_fan.fan_power.nil?
        vent_fan.fan_power = 0.3 * vent_fan.flow_rate # W, per BA HSP
        vent_fan.fan_power_isdefaulted = true
      end
      if vent_fan.start_hour.nil?
        vent_fan.start_hour = 18 # 6 pm, per BA HSP
        vent_fan.start_hour_isdefaulted = true
      end
    end

    # Default bath fans
    hpxml_bldg.ventilation_fans.each do |vent_fan|
      next unless (vent_fan.used_for_local_ventilation && (vent_fan.fan_location == HPXML::LocationBath))

      if vent_fan.count.nil?
        vent_fan.count = hpxml_bldg.building_construction.number_of_bathrooms
        vent_fan.count_isdefaulted = true
      end
      if vent_fan.rated_flow_rate.nil? && vent_fan.tested_flow_rate.nil? && vent_fan.calculated_flow_rate.nil? && vent_fan.delivered_ventilation.nil?
        vent_fan.rated_flow_rate = 50.0 # cfm, per BA HSP
        vent_fan.rated_flow_rate_isdefaulted = true
      end
      if vent_fan.hours_in_operation.nil?
        vent_fan.hours_in_operation = 1.0 # hrs/day, per BA HSP
        vent_fan.hours_in_operation_isdefaulted = true
      end
      if vent_fan.fan_power.nil?
        vent_fan.fan_power = 0.3 * vent_fan.flow_rate # W, per BA HSP
        vent_fan.fan_power_isdefaulted = true
      end
      if vent_fan.start_hour.nil?
        vent_fan.start_hour = 7 # 7 am, per BA HSP
        vent_fan.start_hour_isdefaulted = true
      end
    end

    # Default whole house fan
    hpxml_bldg.ventilation_fans.each do |vent_fan|
      next unless vent_fan.used_for_seasonal_cooling_load_reduction

      if vent_fan.rated_flow_rate.nil? && vent_fan.tested_flow_rate.nil? && vent_fan.calculated_flow_rate.nil? && vent_fan.delivered_ventilation.nil?
        vent_fan.rated_flow_rate = cfa * 2.0
        vent_fan.rated_flow_rate_isdefaulted = true
      end
      if vent_fan.fan_power.nil?
        vent_fan.fan_power = 0.1 * vent_fan.flow_rate # W
        vent_fan.fan_power_isdefaulted = true
      end
    end
  end

  def self.apply_water_heaters(hpxml_bldg, nbeds, eri_version, schedules_file)
    hpxml_bldg.water_heating_systems.each do |water_heating_system|
      if water_heating_system.is_shared_system.nil?
        water_heating_system.is_shared_system = false
        water_heating_system.is_shared_system_isdefaulted = true
      end
      schedules_file_includes_water_heater_setpoint_temp = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:WaterHeaterSetpoint].name))
      if water_heating_system.temperature.nil? && !schedules_file_includes_water_heater_setpoint_temp
        water_heating_system.temperature = Waterheater.get_default_hot_water_temperature(eri_version)
        water_heating_system.temperature_isdefaulted = true
      end
      if water_heating_system.performance_adjustment.nil?
        water_heating_system.performance_adjustment = Waterheater.get_default_performance_adjustment(water_heating_system)
        water_heating_system.performance_adjustment_isdefaulted = true
      end
      if (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeCombiStorage) && water_heating_system.standby_loss_value.nil?
        # Use equation fit from AHRI database
        # calculate independent variable SurfaceArea/vol(physically linear to standby_loss/skin_u under test condition) to fit the linear equation from AHRI database
        act_vol = Waterheater.calc_storage_tank_actual_vol(water_heating_system.tank_volume, nil)
        surface_area = Waterheater.calc_tank_areas(act_vol)[0]
        sqft_by_gal = surface_area / act_vol # sqft/gal
        water_heating_system.standby_loss_value = (2.9721 * sqft_by_gal - 0.4732).round(3) # linear equation assuming a constant u, F/hr
        water_heating_system.standby_loss_value_isdefaulted = true
        water_heating_system.standby_loss_units = HPXML::UnitsDegFPerHour
        water_heating_system.standby_loss_units_isdefaulted = true
      end
      if (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeStorage)
        if water_heating_system.heating_capacity.nil?
          water_heating_system.heating_capacity = (Waterheater.get_default_heating_capacity(water_heating_system.fuel_type, nbeds, hpxml_bldg.water_heating_systems.size, hpxml_bldg.building_construction.number_of_bathrooms) * 1000.0).round
          water_heating_system.heating_capacity_isdefaulted = true
        end
        if water_heating_system.tank_volume.nil?
          water_heating_system.tank_volume = Waterheater.get_default_tank_volume(water_heating_system.fuel_type, nbeds, hpxml_bldg.building_construction.number_of_bathrooms)
          water_heating_system.tank_volume_isdefaulted = true
        end
        if water_heating_system.recovery_efficiency.nil?
          water_heating_system.recovery_efficiency = Waterheater.get_default_recovery_efficiency(water_heating_system)
          water_heating_system.recovery_efficiency_isdefaulted = true
        end
        if water_heating_system.tank_model_type.nil?
          water_heating_system.tank_model_type = HPXML::WaterHeaterTankModelTypeMixed
          water_heating_system.tank_model_type_isdefaulted = true
        end
      end
      if (water_heating_system.water_heater_type == HPXML::WaterHeaterTypeHeatPump)
        schedules_file_includes_water_heater_operating_mode = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:WaterHeaterOperatingMode].name))
        if water_heating_system.operating_mode.nil? && !schedules_file_includes_water_heater_operating_mode
          water_heating_system.operating_mode = HPXML::WaterHeaterOperatingModeHybridAuto
          water_heating_system.operating_mode_isdefaulted = true
        end
      end
      if water_heating_system.location.nil?
        water_heating_system.location = Waterheater.get_default_location(hpxml_bldg, hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0])
        water_heating_system.location_isdefaulted = true
      end
      next unless water_heating_system.usage_bin.nil? && (not water_heating_system.uniform_energy_factor.nil?) # FHR & UsageBin only applies to UEF

      if not water_heating_system.first_hour_rating.nil?
        water_heating_system.usage_bin = Waterheater.get_usage_bin_from_first_hour_rating(water_heating_system.first_hour_rating)
      else
        water_heating_system.usage_bin = HPXML::WaterHeaterUsageBinMedium
      end
      water_heating_system.usage_bin_isdefaulted = true
    end
  end

  def self.apply_flue_or_chimney(hpxml_bldg)
    # This needs to come after we have applied defaults for HVAC/DHW systems
    if hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space.nil?
      hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space = get_default_flue_or_chimney_in_conditioned_space(hpxml_bldg)
      hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space_isdefaulted = true
    end
  end

  def self.apply_hot_water_distribution(hpxml_bldg, cfa, ncfl, has_uncond_bsmnt, has_cond_bsmnt, schedules_file)
    return if hpxml_bldg.hot_water_distributions.size == 0

    hot_water_distribution = hpxml_bldg.hot_water_distributions[0]

    if hot_water_distribution.pipe_r_value.nil?
      hot_water_distribution.pipe_r_value = 0.0
      hot_water_distribution.pipe_r_value_isdefaulted = true
    end

    if hot_water_distribution.system_type == HPXML::DHWDistTypeStandard
      if hot_water_distribution.standard_piping_length.nil?
        hot_water_distribution.standard_piping_length = HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl)
        hot_water_distribution.standard_piping_length_isdefaulted = true
      end
    elsif hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc
      if hot_water_distribution.recirculation_piping_length.nil?
        hot_water_distribution.recirculation_piping_length = HotWaterAndAppliances.get_default_recirc_loop_length(HotWaterAndAppliances.get_default_std_pipe_length(has_uncond_bsmnt, has_cond_bsmnt, cfa, ncfl))
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

    if hot_water_distribution.system_type == HPXML::DHWDistTypeRecirc || hot_water_distribution.has_shared_recirculation
      schedules_file_includes_recirculation_pump = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:HotWaterRecirculationPump].name))
      recirc_control_type = hot_water_distribution.has_shared_recirculation ? hot_water_distribution.shared_recirculation_control_type : hot_water_distribution.recirculation_control_type
      if [HPXML::DHWRecircControlTypeNone, HPXML::DHWRecircControlTypeTimer].include?(recirc_control_type)
        if hot_water_distribution.recirculation_pump_weekday_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekday_fractions = Schedule.RecirculationPumpWithoutControlWeekdayFractions
          hot_water_distribution.recirculation_pump_weekday_fractions_isdefaulted = true
        end
        if hot_water_distribution.recirculation_pump_weekend_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekend_fractions = Schedule.RecirculationPumpWithoutControlWeekendFractions
          hot_water_distribution.recirculation_pump_weekend_fractions_isdefaulted = true
        end
      elsif [HPXML::DHWRecircControlTypeSensor, HPXML::DHWRecircControlTypeManual].include?(recirc_control_type)
        if hot_water_distribution.recirculation_pump_weekday_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekday_fractions = Schedule.RecirculationPumpDemandControlledWeekdayFractions
          hot_water_distribution.recirculation_pump_weekday_fractions_isdefaulted = true
        end
        if hot_water_distribution.recirculation_pump_weekend_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekend_fractions = Schedule.RecirculationPumpDemandControlledWeekendFractions
          hot_water_distribution.recirculation_pump_weekend_fractions_isdefaulted = true
        end
      elsif [HPXML::DHWRecircControlTypeTemperature].include?(recirc_control_type)
        if hot_water_distribution.recirculation_pump_weekday_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekday_fractions = Schedule.RecirculationPumpTemperatureControlledWeekdayFractions
          hot_water_distribution.recirculation_pump_weekday_fractions_isdefaulted = true
        end
        if hot_water_distribution.recirculation_pump_weekend_fractions.nil? && !schedules_file_includes_recirculation_pump
          hot_water_distribution.recirculation_pump_weekend_fractions = Schedule.RecirculationPumpTemperatureControlledWeekendFractions
          hot_water_distribution.recirculation_pump_weekend_fractions_isdefaulted = true
        end
      end
      if hot_water_distribution.recirculation_pump_monthly_multipliers.nil? && !schedules_file_includes_recirculation_pump
        hot_water_distribution.recirculation_pump_monthly_multipliers = Schedule.RecirculationPumpMonthlyMultipliers
        hot_water_distribution.recirculation_pump_monthly_multipliers_isdefaulted = true
      end
    end
  end

  def self.apply_water_fixtures(hpxml_bldg, schedules_file)
    return if hpxml_bldg.hot_water_distributions.size == 0

    hpxml_bldg.water_fixtures.each do |wf|
      next unless [HPXML::WaterFixtureTypeShowerhead, HPXML::WaterFixtureTypeFaucet].include? wf.water_fixture_type

      if wf.low_flow.nil?
        wf.low_flow = (wf.flow_rate <= 2.0)
        wf.low_flow_isdefaulted = true
      end
    end

    if hpxml_bldg.water_heating.water_fixtures_usage_multiplier.nil?
      hpxml_bldg.water_heating.water_fixtures_usage_multiplier = 1.0
      hpxml_bldg.water_heating.water_fixtures_usage_multiplier_isdefaulted = true
    end
    schedules_file_includes_fixtures = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:HotWaterFixtures].name))
    if hpxml_bldg.water_heating.water_fixtures_weekday_fractions.nil? && !schedules_file_includes_fixtures
      hpxml_bldg.water_heating.water_fixtures_weekday_fractions = Schedule.FixturesWeekdayFractions
      hpxml_bldg.water_heating.water_fixtures_weekday_fractions_isdefaulted = true
    end
    if hpxml_bldg.water_heating.water_fixtures_weekend_fractions.nil? && !schedules_file_includes_fixtures
      hpxml_bldg.water_heating.water_fixtures_weekend_fractions = Schedule.FixturesWeekendFractions
      hpxml_bldg.water_heating.water_fixtures_weekend_fractions_isdefaulted = true
    end
    if hpxml_bldg.water_heating.water_fixtures_monthly_multipliers.nil? && !schedules_file_includes_fixtures
      hpxml_bldg.water_heating.water_fixtures_monthly_multipliers = Schedule.FixturesMonthlyMultipliers
      hpxml_bldg.water_heating.water_fixtures_monthly_multipliers_isdefaulted = true
    end
  end

  def self.apply_solar_thermal_systems(hpxml_bldg)
    hpxml_bldg.solar_thermal_systems.each do |solar_thermal_system|
      if solar_thermal_system.collector_azimuth.nil?
        solar_thermal_system.collector_azimuth = get_azimuth_from_orientation(solar_thermal_system.collector_orientation)
        solar_thermal_system.collector_azimuth_isdefaulted = true
      end
      if solar_thermal_system.collector_orientation.nil?
        solar_thermal_system.collector_orientation = get_orientation_from_azimuth(solar_thermal_system.collector_azimuth)
        solar_thermal_system.collector_orientation_isdefaulted = true
      end
      if solar_thermal_system.storage_volume.nil? && (not solar_thermal_system.collector_area.nil?) # Detailed solar water heater
        solar_thermal_system.storage_volume = Waterheater.calc_default_solar_thermal_system_storage_volume(solar_thermal_system.collector_area)
        solar_thermal_system.storage_volume_isdefaulted = true
      end
    end
  end

  def self.apply_pv_systems(hpxml_bldg)
    hpxml_bldg.pv_systems.each do |pv_system|
      if pv_system.array_azimuth.nil?
        pv_system.array_azimuth = get_azimuth_from_orientation(pv_system.array_orientation)
        pv_system.array_azimuth_isdefaulted = true
      end
      if pv_system.array_orientation.nil?
        pv_system.array_orientation = get_orientation_from_azimuth(pv_system.array_azimuth)
        pv_system.array_orientation_isdefaulted = true
      end
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
      if pv_system.system_losses_fraction.nil?
        pv_system.system_losses_fraction = PV.get_default_system_losses(pv_system.year_modules_manufactured)
        pv_system.system_losses_fraction_isdefaulted = true
      end
    end
    hpxml_bldg.inverters.each do |inverter|
      if inverter.inverter_efficiency.nil?
        inverter.inverter_efficiency = PV.get_default_inv_eff()
        inverter.inverter_efficiency_isdefaulted = true
      end
    end
  end

  def self.apply_generators(hpxml_bldg)
    hpxml_bldg.generators.each do |generator|
      if generator.is_shared_system.nil?
        generator.is_shared_system = false
        generator.is_shared_system_isdefaulted = true
      end
    end
  end

  def self.apply_batteries(hpxml_bldg)
    default_values = Battery.get_battery_default_values(hpxml_bldg.has_location(HPXML::LocationGarage))
    hpxml_bldg.batteries.each do |battery|
      if battery.location.nil?
        battery.location = default_values[:location]
        battery.location_isdefaulted = true
      end
      if battery.is_shared_system.nil?
        battery.is_shared_system = false
        battery.is_shared_system_isdefaulted = true
      end
      # if battery.lifetime_model.nil?
      # battery.lifetime_model = default_values[:lifetime_model]
      # battery.lifetime_model_isdefaulted = true
      # end
      if battery.nominal_voltage.nil?
        battery.nominal_voltage = default_values[:nominal_voltage] # V
        battery.nominal_voltage_isdefaulted = true
      end
      if battery.round_trip_efficiency.nil?
        battery.round_trip_efficiency = default_values[:round_trip_efficiency]
        battery.round_trip_efficiency_isdefaulted = true
      end
      if battery.nominal_capacity_kwh.nil? && battery.nominal_capacity_ah.nil?
        # Calculate nominal capacity from usable capacity or rated power output if available
        if not battery.usable_capacity_kwh.nil?
          battery.nominal_capacity_kwh = (battery.usable_capacity_kwh / default_values[:usable_fraction]).round(2)
          battery.nominal_capacity_kwh_isdefaulted = true
        elsif not battery.usable_capacity_ah.nil?
          battery.nominal_capacity_ah = (battery.usable_capacity_ah / default_values[:usable_fraction]).round(2)
          battery.nominal_capacity_ah_isdefaulted = true
        elsif not battery.rated_power_output.nil?
          battery.nominal_capacity_kwh = (UnitConversions.convert(battery.rated_power_output, 'W', 'kW') / 0.5).round(2)
          battery.nominal_capacity_kwh_isdefaulted = true
        else
          battery.nominal_capacity_kwh = default_values[:nominal_capacity_kwh] # kWh
          battery.nominal_capacity_kwh_isdefaulted = true
        end
      end
      if battery.usable_capacity_kwh.nil? && battery.usable_capacity_ah.nil?
        # Calculate usable capacity from nominal capacity
        if not battery.nominal_capacity_kwh.nil?
          battery.usable_capacity_kwh = (battery.nominal_capacity_kwh * default_values[:usable_fraction]).round(2)
          battery.usable_capacity_kwh_isdefaulted = true
        elsif not battery.nominal_capacity_ah.nil?
          battery.usable_capacity_ah = (battery.nominal_capacity_ah * default_values[:usable_fraction]).round(2)
          battery.usable_capacity_ah_isdefaulted = true
        end
      end
      next unless battery.rated_power_output.nil?

      # Calculate rated power from nominal capacity
      if not battery.nominal_capacity_kwh.nil?
        battery.rated_power_output = (UnitConversions.convert(battery.nominal_capacity_kwh, 'kWh', 'Wh') * 0.5).round(0)
      elsif not battery.nominal_capacity_ah.nil?
        battery.rated_power_output = (UnitConversions.convert(Battery.get_kWh_from_Ah(battery.nominal_capacity_ah, battery.nominal_voltage), 'kWh', 'Wh') * 0.5).round(0)
      end
      battery.rated_power_output_isdefaulted = true
    end
  end

  def self.apply_appliances(hpxml_bldg, nbeds, eri_version, schedules_file)
    # Default clothes washer
    if hpxml_bldg.clothes_washers.size > 0
      clothes_washer = hpxml_bldg.clothes_washers[0]
      if clothes_washer.is_shared_appliance.nil?
        clothes_washer.is_shared_appliance = false
        clothes_washer.is_shared_appliance_isdefaulted = true
      end
      if clothes_washer.location.nil?
        clothes_washer.location = HPXML::LocationConditionedSpace
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
      schedules_file_includes_cw = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:ClothesWasher].name))
      if clothes_washer.weekday_fractions.nil? && !schedules_file_includes_cw
        clothes_washer.weekday_fractions = Schedule.ClothesWasherWeekdayFractions
        clothes_washer.weekday_fractions_isdefaulted = true
      end
      if clothes_washer.weekend_fractions.nil? && !schedules_file_includes_cw
        clothes_washer.weekend_fractions = Schedule.ClothesWasherWeekendFractions
        clothes_washer.weekend_fractions_isdefaulted = true
      end
      if clothes_washer.monthly_multipliers.nil? && !schedules_file_includes_cw
        clothes_washer.monthly_multipliers = Schedule.ClothesWasherMonthlyMultipliers
        clothes_washer.monthly_multipliers_isdefaulted = true
      end
    end

    # Default clothes dryer
    if hpxml_bldg.clothes_dryers.size > 0
      clothes_dryer = hpxml_bldg.clothes_dryers[0]
      if clothes_dryer.is_shared_appliance.nil?
        clothes_dryer.is_shared_appliance = false
        clothes_dryer.is_shared_appliance_isdefaulted = true
      end
      if clothes_dryer.location.nil?
        clothes_dryer.location = HPXML::LocationConditionedSpace
        clothes_dryer.location_isdefaulted = true
      end
      if clothes_dryer.combined_energy_factor.nil? && clothes_dryer.energy_factor.nil?
        default_values = HotWaterAndAppliances.get_clothes_dryer_default_values(eri_version, clothes_dryer.fuel_type)
        clothes_dryer.combined_energy_factor = default_values[:combined_energy_factor]
        clothes_dryer.combined_energy_factor_isdefaulted = true
      end
      if clothes_dryer.control_type.nil?
        default_values = HotWaterAndAppliances.get_clothes_dryer_default_values(eri_version, clothes_dryer.fuel_type)
        clothes_dryer.control_type = default_values[:control_type]
        clothes_dryer.control_type_isdefaulted = true
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
      schedules_file_includes_cd = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:ClothesDryer].name))
      if clothes_dryer.weekday_fractions.nil? && !schedules_file_includes_cd
        clothes_dryer.weekday_fractions = Schedule.ClothesDryerWeekdayFractions
        clothes_dryer.weekday_fractions_isdefaulted = true
      end
      if clothes_dryer.weekend_fractions.nil? && !schedules_file_includes_cd
        clothes_dryer.weekend_fractions = Schedule.ClothesDryerWeekendFractions
        clothes_dryer.weekend_fractions_isdefaulted = true
      end
      if clothes_dryer.monthly_multipliers.nil? && !schedules_file_includes_cd
        clothes_dryer.monthly_multipliers = Schedule.ClothesDryerMonthlyMultipliers
        clothes_dryer.monthly_multipliers_isdefaulted = true
      end
    end

    # Default dishwasher
    if hpxml_bldg.dishwashers.size > 0
      dishwasher = hpxml_bldg.dishwashers[0]
      if dishwasher.is_shared_appliance.nil?
        dishwasher.is_shared_appliance = false
        dishwasher.is_shared_appliance_isdefaulted = true
      end
      if dishwasher.location.nil?
        dishwasher.location = HPXML::LocationConditionedSpace
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
      schedules_file_includes_dw = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:Dishwasher].name))
      if dishwasher.weekday_fractions.nil? && !schedules_file_includes_dw
        dishwasher.weekday_fractions = Schedule.DishwasherWeekdayFractions
        dishwasher.weekday_fractions_isdefaulted = true
      end
      if dishwasher.weekend_fractions.nil? && !schedules_file_includes_dw
        dishwasher.weekend_fractions = Schedule.DishwasherWeekendFractions
        dishwasher.weekend_fractions_isdefaulted = true
      end
      if dishwasher.monthly_multipliers.nil? && !schedules_file_includes_dw
        dishwasher.monthly_multipliers = Schedule.DishwasherMonthlyMultipliers
        dishwasher.monthly_multipliers_isdefaulted = true
      end
    end

    # Default refrigerators
    if hpxml_bldg.refrigerators.size == 1
      hpxml_bldg.refrigerators[0].primary_indicator = true
      hpxml_bldg.refrigerators[0].primary_indicator_isdefaulted = true
    end
    hpxml_bldg.refrigerators.each do |refrigerator|
      schedules_includes_fractions_multipliers = (!refrigerator.weekday_fractions.nil? || !refrigerator.weekend_fractions.nil? || !refrigerator.monthly_multipliers.nil?)
      if not refrigerator.primary_indicator # extra refrigerator
        if refrigerator.location.nil?
          refrigerator.location = HotWaterAndAppliances.get_default_extra_refrigerator_and_freezer_locations(hpxml_bldg)
          refrigerator.location_isdefaulted = true
        end
        if refrigerator.rated_annual_kwh.nil?
          default_values = HotWaterAndAppliances.get_extra_refrigerator_default_values
          refrigerator.rated_annual_kwh = default_values[:rated_annual_kwh]
          refrigerator.rated_annual_kwh_isdefaulted = true
        end
        schedules_file_includes_extrafridge = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:ExtraRefrigerator].name))
        if !schedules_file_includes_extrafridge
          if schedules_includes_fractions_multipliers
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
          else
            if refrigerator.constant_coefficients.nil?
              refrigerator.constant_coefficients = Schedule.ExtraRefrigeratorConstantCoefficients
              refrigerator.constant_coefficients_isdefaulted = true
            end
            if refrigerator.temperature_coefficients.nil?
              refrigerator.temperature_coefficients = Schedule.ExtraRefrigeratorTemperatureCoefficients
              refrigerator.temperature_coefficients_isdefaulted = true
            end
          end
        end
      else # primary refrigerator
        if refrigerator.location.nil?
          refrigerator.location = HPXML::LocationConditionedSpace
          refrigerator.location_isdefaulted = true
        end
        if refrigerator.rated_annual_kwh.nil?
          default_values = HotWaterAndAppliances.get_refrigerator_default_values(nbeds)
          refrigerator.rated_annual_kwh = default_values[:rated_annual_kwh]
          refrigerator.rated_annual_kwh_isdefaulted = true
        end
        schedules_file_includes_fridge = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:Refrigerator].name))
        if !schedules_file_includes_fridge
          if schedules_includes_fractions_multipliers
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
          else
            if refrigerator.constant_coefficients.nil?
              refrigerator.constant_coefficients = Schedule.RefrigeratorConstantCoefficients
              refrigerator.constant_coefficients_isdefaulted = true
            end
            if refrigerator.temperature_coefficients.nil?
              refrigerator.temperature_coefficients = Schedule.RefrigeratorTemperatureCoefficients
              refrigerator.temperature_coefficients_isdefaulted = true
            end
          end
        end
      end
      if refrigerator.usage_multiplier.nil?
        refrigerator.usage_multiplier = 1.0
        refrigerator.usage_multiplier_isdefaulted = true
      end
    end

    # Default freezer
    hpxml_bldg.freezers.each do |freezer|
      if freezer.location.nil?
        freezer.location = HotWaterAndAppliances.get_default_extra_refrigerator_and_freezer_locations(hpxml_bldg)
        freezer.location_isdefaulted = true
      end
      if freezer.rated_annual_kwh.nil?
        default_values = HotWaterAndAppliances.get_freezer_default_values
        freezer.rated_annual_kwh = default_values[:rated_annual_kwh]
        freezer.rated_annual_kwh_isdefaulted = true
      end
      if freezer.usage_multiplier.nil?
        freezer.usage_multiplier = 1.0
        freezer.usage_multiplier_isdefaulted = true
      end
      schedules_includes_schedule_coefficients = (!freezer.constant_coefficients.nil? || !freezer.temperature_coefficients.nil?)
      schedules_file_includes_freezer = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:Freezer].name))
      next unless !schedules_includes_schedule_coefficients

      if freezer.weekday_fractions.nil? && !schedules_file_includes_freezer
        freezer.weekday_fractions = Schedule.FreezerWeekdayFractions
        freezer.weekday_fractions_isdefaulted = true
      end
      if freezer.weekend_fractions.nil? && !schedules_file_includes_freezer
        freezer.weekend_fractions = Schedule.FreezerWeekendFractions
        freezer.weekend_fractions_isdefaulted = true
      end
      if freezer.monthly_multipliers.nil? && !schedules_file_includes_freezer
        freezer.monthly_multipliers = Schedule.FreezerMonthlyMultipliers
        freezer.monthly_multipliers_isdefaulted = true
      end
    end

    # Default cooking range
    if hpxml_bldg.cooking_ranges.size > 0
      cooking_range = hpxml_bldg.cooking_ranges[0]
      if cooking_range.location.nil?
        cooking_range.location = HPXML::LocationConditionedSpace
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
      schedules_file_includes_range = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:CookingRange].name))
      if cooking_range.weekday_fractions.nil? && !schedules_file_includes_range
        cooking_range.weekday_fractions = Schedule.CookingRangeWeekdayFractions
        cooking_range.weekday_fractions_isdefaulted = true
      end
      if cooking_range.weekend_fractions.nil? && !schedules_file_includes_range
        cooking_range.weekend_fractions = Schedule.CookingRangeWeekendFractions
        cooking_range.weekend_fractions_isdefaulted = true
      end
      if cooking_range.monthly_multipliers.nil? && !schedules_file_includes_range
        cooking_range.monthly_multipliers = Schedule.CookingRangeMonthlyMultipliers
        cooking_range.monthly_multipliers_isdefaulted = true
      end
    end

    # Default oven
    if hpxml_bldg.ovens.size > 0
      oven = hpxml_bldg.ovens[0]
      if oven.is_convection.nil?
        default_values = HotWaterAndAppliances.get_range_oven_default_values()
        oven.is_convection = default_values[:is_convection]
        oven.is_convection_isdefaulted = true
      end
    end
  end

  def self.apply_lighting(hpxml_bldg, schedules_file)
    return if hpxml_bldg.lighting_groups.empty?

    if hpxml_bldg.lighting.interior_usage_multiplier.nil?
      hpxml_bldg.lighting.interior_usage_multiplier = 1.0
      hpxml_bldg.lighting.interior_usage_multiplier_isdefaulted = true
    end
    if hpxml_bldg.lighting.garage_usage_multiplier.nil?
      hpxml_bldg.lighting.garage_usage_multiplier = 1.0
      hpxml_bldg.lighting.garage_usage_multiplier_isdefaulted = true
    end
    if hpxml_bldg.lighting.exterior_usage_multiplier.nil?
      hpxml_bldg.lighting.exterior_usage_multiplier = 1.0
      hpxml_bldg.lighting.exterior_usage_multiplier_isdefaulted = true
    end
    default_lighting_monthly_multipliers = Schedule.LightingMonthlyMultipliers
    schedules_file_includes_lighting_interior = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:LightingInterior].name))
    if hpxml_bldg.lighting.interior_weekday_fractions.nil? && !schedules_file_includes_lighting_interior
      hpxml_bldg.lighting.interior_weekday_fractions = Schedule.LightingInteriorWeekdayFractions
      hpxml_bldg.lighting.interior_weekday_fractions_isdefaulted = true
    end
    if hpxml_bldg.lighting.interior_weekend_fractions.nil? && !schedules_file_includes_lighting_interior
      hpxml_bldg.lighting.interior_weekend_fractions = Schedule.LightingInteriorWeekendFractions
      hpxml_bldg.lighting.interior_weekend_fractions_isdefaulted = true
    end
    if hpxml_bldg.lighting.interior_monthly_multipliers.nil? && !schedules_file_includes_lighting_interior
      hpxml_bldg.lighting.interior_monthly_multipliers = default_lighting_monthly_multipliers
      hpxml_bldg.lighting.interior_monthly_multipliers_isdefaulted = true
    end
    if hpxml_bldg.has_location(HPXML::LocationGarage)
      schedules_file_includes_lighting_garage = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:LightingGarage].name))
      if hpxml_bldg.lighting.garage_weekday_fractions.nil? && !schedules_file_includes_lighting_garage
        hpxml_bldg.lighting.garage_weekday_fractions = Schedule.LightingGarageWeekdayFractions
        hpxml_bldg.lighting.garage_weekday_fractions_isdefaulted = true
      end
      if hpxml_bldg.lighting.garage_weekend_fractions.nil? && !schedules_file_includes_lighting_garage
        hpxml_bldg.lighting.garage_weekend_fractions = Schedule.LightingGarageWeekendFractions
        hpxml_bldg.lighting.garage_weekend_fractions_isdefaulted = true
      end
      if hpxml_bldg.lighting.garage_monthly_multipliers.nil? && !schedules_file_includes_lighting_garage
        hpxml_bldg.lighting.garage_monthly_multipliers = default_lighting_monthly_multipliers
        hpxml_bldg.lighting.garage_monthly_multipliers_isdefaulted = true
      end
    end
    schedules_file_includes_lighting_exterior = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:LightingExterior].name))
    if hpxml_bldg.lighting.exterior_weekday_fractions.nil? && !schedules_file_includes_lighting_exterior
      hpxml_bldg.lighting.exterior_weekday_fractions = Schedule.LightingExteriorWeekdayFractions
      hpxml_bldg.lighting.exterior_weekday_fractions_isdefaulted = true
    end
    if hpxml_bldg.lighting.exterior_weekend_fractions.nil? && !schedules_file_includes_lighting_exterior
      hpxml_bldg.lighting.exterior_weekend_fractions = Schedule.LightingExteriorWeekendFractions
      hpxml_bldg.lighting.exterior_weekend_fractions_isdefaulted = true
    end
    if hpxml_bldg.lighting.exterior_monthly_multipliers.nil? && !schedules_file_includes_lighting_exterior
      hpxml_bldg.lighting.exterior_monthly_multipliers = default_lighting_monthly_multipliers
      hpxml_bldg.lighting.exterior_monthly_multipliers_isdefaulted = true
    end
    if hpxml_bldg.lighting.holiday_exists
      if hpxml_bldg.lighting.holiday_kwh_per_day.nil?
        # From LA100 repo (2017)
        if hpxml_bldg.building_construction.residential_facility_type == HPXML::ResidentialTypeSFD
          hpxml_bldg.lighting.holiday_kwh_per_day = 1.1
        else # Multifamily and others
          hpxml_bldg.lighting.holiday_kwh_per_day = 0.55
        end
        hpxml_bldg.lighting.holiday_kwh_per_day_isdefaulted = true
      end
      if hpxml_bldg.lighting.holiday_period_begin_month.nil?
        hpxml_bldg.lighting.holiday_period_begin_month = 11
        hpxml_bldg.lighting.holiday_period_begin_month_isdefaulted = true
        hpxml_bldg.lighting.holiday_period_begin_day = 24
        hpxml_bldg.lighting.holiday_period_begin_day_isdefaulted = true
      end
      if hpxml_bldg.lighting.holiday_period_end_day.nil?
        hpxml_bldg.lighting.holiday_period_end_month = 1
        hpxml_bldg.lighting.holiday_period_end_month_isdefaulted = true
        hpxml_bldg.lighting.holiday_period_end_day = 6
        hpxml_bldg.lighting.holiday_period_end_day_isdefaulted = true
      end
      schedules_file_includes_lighting_holiday_exterior = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:LightingExteriorHoliday].name))
      if hpxml_bldg.lighting.holiday_weekday_fractions.nil? && !schedules_file_includes_lighting_holiday_exterior
        hpxml_bldg.lighting.holiday_weekday_fractions = Schedule.LightingExteriorHolidayWeekdayFractions
        hpxml_bldg.lighting.holiday_weekday_fractions_isdefaulted = true
      end
      if hpxml_bldg.lighting.holiday_weekend_fractions.nil? && !schedules_file_includes_lighting_holiday_exterior
        hpxml_bldg.lighting.holiday_weekend_fractions = Schedule.LightingExteriorHolidayWeekendFractions
        hpxml_bldg.lighting.holiday_weekend_fractions_isdefaulted = true
      end
    end
  end

  def self.apply_ceiling_fans(hpxml_bldg, nbeds, weather, schedules_file)
    return if hpxml_bldg.ceiling_fans.size == 0

    ceiling_fan = hpxml_bldg.ceiling_fans[0]
    if ceiling_fan.efficiency.nil? && ceiling_fan.label_energy_use.nil?
      ceiling_fan.label_energy_use = HVAC.get_default_ceiling_fan_power()
      ceiling_fan.label_energy_use_isdefaulted = true
    end
    if ceiling_fan.count.nil?
      ceiling_fan.count = HVAC.get_default_ceiling_fan_quantity(nbeds)
      ceiling_fan.count_isdefaulted = true
    end
    schedules_file_includes_ceiling_fan = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:CeilingFan].name))
    if ceiling_fan.weekday_fractions.nil? && !schedules_file_includes_ceiling_fan
      ceiling_fan.weekday_fractions = Schedule.CeilingFanWeekdayFractions
      ceiling_fan.weekday_fractions_isdefaulted = true
    end
    if ceiling_fan.weekend_fractions.nil? && !schedules_file_includes_ceiling_fan
      ceiling_fan.weekend_fractions = Schedule.CeilingFanWeekendFractions
      ceiling_fan.weekend_fractions_isdefaulted = true
    end
    if ceiling_fan.monthly_multipliers.nil? && !schedules_file_includes_ceiling_fan
      ceiling_fan.monthly_multipliers = Schedule.CeilingFanMonthlyMultipliers(weather: weather)
      ceiling_fan.monthly_multipliers_isdefaulted = true
    end
  end

  def self.apply_pools_and_permanent_spas(hpxml_bldg, cfa, schedules_file)
    nbeds = hpxml_bldg.building_construction.additional_properties.adjusted_number_of_bedrooms
    hpxml_bldg.pools.each do |pool|
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
        schedules_file_includes_pool_pump = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PoolPump].name))
        if pool.pump_weekday_fractions.nil? && !schedules_file_includes_pool_pump
          pool.pump_weekday_fractions = Schedule.PoolPumpWeekdayFractions
          pool.pump_weekday_fractions_isdefaulted = true
        end
        if pool.pump_weekend_fractions.nil? && !schedules_file_includes_pool_pump
          pool.pump_weekend_fractions = Schedule.PoolPumpWeekendFractions
          pool.pump_weekend_fractions_isdefaulted = true
        end
        if pool.pump_monthly_multipliers.nil? && !schedules_file_includes_pool_pump
          pool.pump_monthly_multipliers = Schedule.PoolPumpMonthlyMultipliers
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
      schedules_file_includes_pool_heater = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PoolHeater].name))
      if pool.heater_weekday_fractions.nil? && !schedules_file_includes_pool_heater
        pool.heater_weekday_fractions = Schedule.PoolHeaterWeekdayFractions
        pool.heater_weekday_fractions_isdefaulted = true
      end
      if pool.heater_weekend_fractions.nil? && !schedules_file_includes_pool_heater
        pool.heater_weekend_fractions = Schedule.PoolHeaterWeekendFractions
        pool.heater_weekend_fractions_isdefaulted = true
      end
      if pool.heater_monthly_multipliers.nil? && !schedules_file_includes_pool_heater
        pool.heater_monthly_multipliers = Schedule.PoolHeaterMonthlyMultipliers
        pool.heater_monthly_multipliers_isdefaulted = true
      end
    end

    hpxml_bldg.permanent_spas.each do |spa|
      next if spa.type == HPXML::TypeNone

      if spa.pump_type != HPXML::TypeNone
        # Pump
        if spa.pump_kwh_per_year.nil?
          spa.pump_kwh_per_year = MiscLoads.get_permanent_spa_pump_default_values(cfa, nbeds)
          spa.pump_kwh_per_year_isdefaulted = true
        end
        if spa.pump_usage_multiplier.nil?
          spa.pump_usage_multiplier = 1.0
          spa.pump_usage_multiplier_isdefaulted = true
        end
        schedules_file_includes_permanent_spa_pump = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PermanentSpaPump].name))
        if spa.pump_weekday_fractions.nil? && !schedules_file_includes_permanent_spa_pump
          spa.pump_weekday_fractions = Schedule.PermanentSpaPumpWeekdayFractions
          spa.pump_weekday_fractions_isdefaulted = true
        end
        if spa.pump_weekend_fractions.nil? && !schedules_file_includes_permanent_spa_pump
          spa.pump_weekend_fractions = Schedule.PermanentSpaPumpWeekendFractions
          spa.pump_weekend_fractions_isdefaulted = true
        end
        if spa.pump_monthly_multipliers.nil? && !schedules_file_includes_permanent_spa_pump
          spa.pump_monthly_multipliers = Schedule.PermanentSpaPumpMonthlyMultipliers
          spa.pump_monthly_multipliers_isdefaulted = true
        end
      end

      next unless spa.heater_type != HPXML::TypeNone

      # Heater
      if spa.heater_load_value.nil?
        default_heater_load_units, default_heater_load_value = MiscLoads.get_permanent_spa_heater_default_values(cfa, nbeds, spa.heater_type)
        spa.heater_load_units = default_heater_load_units
        spa.heater_load_value = default_heater_load_value
        spa.heater_load_value_isdefaulted = true
      end
      if spa.heater_usage_multiplier.nil?
        spa.heater_usage_multiplier = 1.0
        spa.heater_usage_multiplier_isdefaulted = true
      end
      schedules_file_includes_permanent_spa_heater = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PermanentSpaHeater].name))
      if spa.heater_weekday_fractions.nil? && !schedules_file_includes_permanent_spa_heater
        spa.heater_weekday_fractions = Schedule.PermanentSpaHeaterWeekdayFractions
        spa.heater_weekday_fractions_isdefaulted = true
      end
      if spa.heater_weekend_fractions.nil? && !schedules_file_includes_permanent_spa_heater
        spa.heater_weekend_fractions = Schedule.PermanentSpaHeaterWeekendFractions
        spa.heater_weekend_fractions_isdefaulted = true
      end
      if spa.heater_monthly_multipliers.nil? && !schedules_file_includes_permanent_spa_heater
        spa.heater_monthly_multipliers = Schedule.PermanentSpaHeaterMonthlyMultipliers
        spa.heater_monthly_multipliers_isdefaulted = true
      end
    end
  end

  def self.apply_plug_loads(hpxml_bldg, cfa, schedules_file)
    nbeds = hpxml_bldg.building_construction.additional_properties.adjusted_number_of_bedrooms
    hpxml_bldg.plug_loads.each do |plug_load|
      if plug_load.plug_load_type == HPXML::PlugLoadTypeOther
        default_annual_kwh, default_sens_frac, default_lat_frac = MiscLoads.get_residual_mels_default_values(cfa)
        if plug_load.kwh_per_year.nil?
          plug_load.kwh_per_year = default_annual_kwh
          plug_load.kwh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = default_sens_frac
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = default_lat_frac
          plug_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_plug_loads_other = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PlugLoadsOther].name))
        if plug_load.weekday_fractions.nil? && !schedules_file_includes_plug_loads_other
          plug_load.weekday_fractions = Schedule.PlugLoadsOtherWeekdayFractions
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil? && !schedules_file_includes_plug_loads_other
          plug_load.weekend_fractions = Schedule.PlugLoadsOtherWeekendFractions
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil? && !schedules_file_includes_plug_loads_other
          plug_load.monthly_multipliers = Schedule.PlugLoadsOtherMonthlyMultipliers
          plug_load.monthly_multipliers_isdefaulted = true
        end
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeTelevision
        default_annual_kwh, default_sens_frac, default_lat_frac = MiscLoads.get_televisions_default_values(cfa, nbeds)
        if plug_load.kwh_per_year.nil?
          plug_load.kwh_per_year = default_annual_kwh
          plug_load.kwh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = default_sens_frac
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = default_lat_frac
          plug_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_plug_loads_tv = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PlugLoadsTV].name))
        if plug_load.weekday_fractions.nil? && !schedules_file_includes_plug_loads_tv
          plug_load.weekday_fractions = Schedule.PlugLoadsTVWeekdayFractions
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil? && !schedules_file_includes_plug_loads_tv
          plug_load.weekend_fractions = Schedule.PlugLoadsTVWeekendFractions
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil? && !schedules_file_includes_plug_loads_tv
          plug_load.monthly_multipliers = Schedule.PlugLoadsTVMonthlyMultipliers
          plug_load.monthly_multipliers_isdefaulted = true
        end
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeElectricVehicleCharging
        default_annual_kwh = MiscLoads.get_electric_vehicle_charging_default_values
        if plug_load.kwh_per_year.nil?
          plug_load.kwh_per_year = default_annual_kwh
          plug_load.kwh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = 0.0
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = 0.0
          plug_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_plug_loads_vehicle = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PlugLoadsVehicle].name))
        if plug_load.weekday_fractions.nil? && !schedules_file_includes_plug_loads_vehicle
          plug_load.weekday_fractions = Schedule.PlugLoadsVehicleWeekdayFractions
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil? && !schedules_file_includes_plug_loads_vehicle
          plug_load.weekend_fractions = Schedule.PlugLoadsVehicleWeekendFractions
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil? && !schedules_file_includes_plug_loads_vehicle
          plug_load.monthly_multipliers = Schedule.PlugLoadsVehicleMonthlyMultipliers
          plug_load.monthly_multipliers_isdefaulted = true
        end
      elsif plug_load.plug_load_type == HPXML::PlugLoadTypeWellPump
        default_annual_kwh = MiscLoads.get_well_pump_default_values(cfa, nbeds)
        if plug_load.kwh_per_year.nil?
          plug_load.kwh_per_year = default_annual_kwh
          plug_load.kwh_per_year_isdefaulted = true
        end
        if plug_load.frac_sensible.nil?
          plug_load.frac_sensible = 0.0
          plug_load.frac_sensible_isdefaulted = true
        end
        if plug_load.frac_latent.nil?
          plug_load.frac_latent = 0.0
          plug_load.frac_latent_isdefaulted = true
        end
        schedules_file_includes_plug_loads_well_pump = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:PlugLoadsWellPump].name))
        if plug_load.weekday_fractions.nil? && !schedules_file_includes_plug_loads_well_pump
          plug_load.weekday_fractions = Schedule.PlugLoadsWellPumpWeekdayFractions
          plug_load.weekday_fractions_isdefaulted = true
        end
        if plug_load.weekend_fractions.nil? && !schedules_file_includes_plug_loads_well_pump
          plug_load.weekend_fractions = Schedule.PlugLoadsWellPumpWeekendFractions
          plug_load.weekend_fractions_isdefaulted = true
        end
        if plug_load.monthly_multipliers.nil? && !schedules_file_includes_plug_loads_well_pump
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

  def self.apply_fuel_loads(hpxml_bldg, cfa, schedules_file)
    nbeds = hpxml_bldg.building_construction.additional_properties.adjusted_number_of_bedrooms
    hpxml_bldg.fuel_loads.each do |fuel_load|
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
        schedules_file_includes_fuel_loads_grill = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:FuelLoadsGrill].name))
        if fuel_load.weekday_fractions.nil? && !schedules_file_includes_fuel_loads_grill
          fuel_load.weekday_fractions = Schedule.FuelLoadsGrillWeekdayFractions
          fuel_load.weekday_fractions_isdefaulted = true
        end
        if fuel_load.weekend_fractions.nil? && !schedules_file_includes_fuel_loads_grill
          fuel_load.weekend_fractions = Schedule.FuelLoadsGrillWeekendFractions
          fuel_load.weekend_fractions_isdefaulted = true
        end
        if fuel_load.monthly_multipliers.nil? && !schedules_file_includes_fuel_loads_grill
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
        schedules_file_includes_fuel_loads_lighting = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:FuelLoadsLighting].name))
        if fuel_load.weekday_fractions.nil? && !schedules_file_includes_fuel_loads_lighting
          fuel_load.weekday_fractions = Schedule.FuelLoadsLightingWeekdayFractions
          fuel_load.weekday_fractions_isdefaulted = true
        end
        if fuel_load.weekend_fractions.nil? && !schedules_file_includes_fuel_loads_lighting
          fuel_load.weekend_fractions = Schedule.FuelLoadsLightingWeekendFractions
          fuel_load.weekend_fractions_isdefaulted = true
        end
        if fuel_load.monthly_multipliers.nil? && !schedules_file_includes_fuel_loads_lighting
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
        schedules_file_includes_fuel_loads_fireplace = (schedules_file.nil? ? false : schedules_file.includes_col_name(SchedulesFile::Columns[:FuelLoadsFireplace].name))
        if fuel_load.weekday_fractions.nil? && !schedules_file_includes_fuel_loads_fireplace
          fuel_load.weekday_fractions = Schedule.FuelLoadsFireplaceWeekdayFractions
          fuel_load.weekday_fractions_isdefaulted = true
        end
        if fuel_load.weekend_fractions.nil? && !schedules_file_includes_fuel_loads_fireplace
          fuel_load.weekend_fractions = Schedule.FuelLoadsFireplaceWeekendFractions
          fuel_load.weekend_fractions_isdefaulted = true
        end
        if fuel_load.monthly_multipliers.nil? && !schedules_file_includes_fuel_loads_fireplace
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

  def self.apply_hvac_sizing(runner, hpxml_bldg, weather, output_format, design_load_details_output_file_path)
    # Calculate building design loads and equipment capacities/airflows
    hvac_systems = HVAC.get_hpxml_hvac_systems(hpxml_bldg)
    HVACSizing.calculate(runner, weather, hpxml_bldg, hvac_systems, output_format: output_format, output_file_path: design_load_details_output_file_path)
  end

  def self.get_azimuth_from_orientation(orientation)
    return if orientation.nil?

    if orientation == HPXML::OrientationNorth
      return 0
    elsif orientation == HPXML::OrientationNortheast
      return 45
    elsif orientation == HPXML::OrientationEast
      return 90
    elsif orientation == HPXML::OrientationSoutheast
      return 135
    elsif orientation == HPXML::OrientationSouth
      return 180
    elsif orientation == HPXML::OrientationSouthwest
      return 225
    elsif orientation == HPXML::OrientationWest
      return 270
    elsif orientation == HPXML::OrientationNorthwest
      return 315
    end

    fail "Unexpected orientation: #{orientation}."
  end

  def self.get_orientation_from_azimuth(azimuth)
    return if azimuth.nil?

    if (azimuth >= 0.0 - 22.5 + 360.0) || (azimuth < 0.0 + 22.5)
      return HPXML::OrientationNorth
    elsif (azimuth >= 45.0 - 22.5) && (azimuth < 45.0 + 22.5)
      return HPXML::OrientationNortheast
    elsif (azimuth >= 90.0 - 22.5) && (azimuth < 90.0 + 22.5)
      return HPXML::OrientationEast
    elsif (azimuth >= 135.0 - 22.5) && (azimuth < 135.0 + 22.5)
      return HPXML::OrientationSoutheast
    elsif (azimuth >= 180.0 - 22.5) && (azimuth < 180.0 + 22.5)
      return HPXML::OrientationSouth
    elsif (azimuth >= 225.0 - 22.5) && (azimuth < 225.0 + 22.5)
      return HPXML::OrientationSouthwest
    elsif (azimuth >= 270.0 - 22.5) && (azimuth < 270.0 + 22.5)
      return HPXML::OrientationWest
    elsif (azimuth >= 315.0 - 22.5) && (azimuth < 315.0 + 22.5)
      return HPXML::OrientationNorthwest
    end
  end

  def self.get_nbeds_adjusted_for_operational_calculation(hpxml_bldg)
    n_occs = hpxml_bldg.building_occupancy.number_of_residents
    unit_type = hpxml_bldg.building_construction.residential_facility_type
    if [HPXML::ResidentialTypeApartment, HPXML::ResidentialTypeSFA].include? unit_type
      return -0.68 + 1.09 * n_occs
    elsif [HPXML::ResidentialTypeSFD, HPXML::ResidentialTypeManufactured].include? unit_type
      return -1.47 + 1.69 * n_occs
    else
      fail "Unexpected residential facility type: #{unit_type}."
    end
  end

  def self.get_default_flue_or_chimney_in_conditioned_space(hpxml_bldg)
    # Check for atmospheric heating system in conditioned space
    hpxml_bldg.heating_systems.each do |heating_system|
      next if heating_system.heating_system_fuel == HPXML::FuelTypeElectricity
      next unless HPXML::conditioned_locations_this_unit.include? heating_system.location

      if [HPXML::HVACTypeFurnace,
          HPXML::HVACTypeBoiler,
          HPXML::HVACTypeWallFurnace,
          HPXML::HVACTypeFloorFurnace,
          HPXML::HVACTypeStove,
          HPXML::HVACTypeSpaceHeater].include? heating_system.heating_system_type
        if not heating_system.heating_efficiency_afue.nil?
          next if heating_system.heating_efficiency_afue >= 0.89
        elsif not heating_system.heating_efficiency_percent.nil?
          next if heating_system.heating_efficiency_percent >= 0.89
        end

        return true
      elsif [HPXML::HVACTypeFireplace].include? heating_system.heating_system_type
        return true
      end
    end

    # Check for atmospheric water heater in conditioned space
    hpxml_bldg.water_heating_systems.each do |water_heating_system|
      next if water_heating_system.fuel_type == HPXML::FuelTypeElectricity
      next unless HPXML::conditioned_locations_this_unit.include? water_heating_system.location

      if not water_heating_system.energy_factor.nil?
        next if water_heating_system.energy_factor >= 0.63
      elsif not water_heating_system.uniform_energy_factor.nil?
        next if Waterheater.calc_ef_from_uef(water_heating_system) >= 0.63
      end

      return true
    end
    return false
  end

  def self.get_default_latitude(latitude, epw_file)
    return latitude unless latitude.nil?

    return epw_file.latitude
  end

  def self.get_default_longitude(longitude, epw_file)
    return longitude unless longitude.nil?

    return epw_file.longitude
  end

  def self.get_default_time_zone(time_zone, epw_file)
    return time_zone unless time_zone.nil?

    return epw_file.timeZone
  end

  def self.get_default_state_code(state_code, epw_file)
    return state_code unless state_code.nil?

    return epw_file.stateProvinceRegion.upcase
  end

  def self.cleanup_zones_spaces(hpxml_bldg)
    # Remove any automatically created zones/spaces
    auto_space = hpxml_bldg.conditioned_spaces.find { |space| space.id.start_with? Constants.AutomaticallyAdded }
    auto_space.delete if not auto_space.nil?
    auto_zone = hpxml_bldg.conditioned_zones.find { |zone| zone.id.start_with? Constants.AutomaticallyAdded }
    auto_zone.delete if not auto_zone.nil?
  end
end
