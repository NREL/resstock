require_relative "constants"
require_relative "geometry"
require_relative "util"
require_relative "unit_conversions"
require_relative "psychrometrics"
require_relative "schedules"

class HVAC
  def self.apply_central_ac_1speed(model, runner, seer, shrs,
                                   fan_power_installed, crankcase_kw, crankcase_temp,
                                   capacity, frac_cool_load_served,
                                   sequential_cool_load_frac, control_zone,
                                   hvac_map, sys_id)

    num_speeds = 1
    fan_power_rated = get_fan_power_rated(seer)
    capacity_ratios = HVAC.one_speed_capacity_ratios
    fan_speed_ratios = HVAC.one_speed_fan_speed_ratios

    # Cooling Coil
    rated_airflow_rate = 386.1 # cfm
    cfms_ton_rated = calc_cfms_ton_rated(rated_airflow_rate, fan_speed_ratios, capacity_ratios)
    eers = [calc_EER_cooling_1spd(seer, fan_power_rated, cOOL_EIR_FT_SPEC_AC)]
    cooling_eirs = calc_cooling_eirs(num_speeds, eers, fan_power_rated)
    shrs_rated_gross = calc_shrs_rated_gross(num_speeds, shrs, fan_power_rated, cfms_ton_rated)
    cOOL_CLOSS_FPLR_SPEC = [calc_plr_coefficients_cooling(num_speeds, seer)]

    obj_name = Constants.ObjectNameCentralAirConditioner

    # _processCurvesDXCooling

    clg_coil_stage_data = calc_coil_stage_data_cooling(model, capacity, (0...num_speeds).to_a, cooling_eirs, shrs_rated_gross, cOOL_CAP_FT_SPEC_AC, cOOL_EIR_FT_SPEC_AC, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC_AC, cOOL_EIR_FFLOW_SPEC_AC)

    # _processSystemCoolingCoil

    clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, clg_coil_stage_data[0].totalCoolingCapacityFunctionofTemperatureCurve, clg_coil_stage_data[0].totalCoolingCapacityFunctionofFlowFractionCurve, clg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, clg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, clg_coil_stage_data[0].partLoadFractionCorrelationCurve)
    clg_coil_stage_data[0].remove
    clg_coil.setName(obj_name + " clg coil")
    if capacity != Constants.SizingAuto
      clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert([capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    clg_coil.setRatedSensibleHeatRatio(shrs_rated_gross[0])
    clg_coil.setRatedCOP(1.0 / cooling_eirs[0])
    clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(fan_power_rated / UnitConversions.convert(1.0, "cfm", "m^3/s"))
    clg_coil.setNominalTimeForCondensateRemovalToBegin(1000.0)
    clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(1.5)
    clg_coil.setMaximumCyclingRate(3.0)
    clg_coil.setLatentCapacityTimeConstant(45.0)
    clg_coil.setCondenserType("AirCooled")
    clg_coil.setCrankcaseHeaterCapacity(UnitConversions.convert(crankcase_kw, "kW", "W"))
    clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(UnitConversions.convert(crankcase_temp, "F", "C"))
    hvac_map[sys_id] << clg_coil

    # _processSystemFan

    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
    fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
    fan.setName(obj_name + " supply fan")
    fan.setEndUseSubcategory("supply fan")
    fan.setFanEfficiency(fan_eff)
    fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_power_installed))
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [], [clg_coil])

    # _processSystemAir

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName(obj_name + " unitary system")
    air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop_unitary.setCoolingCoil(clg_coil)
    air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0)
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(120.0, "F", "C"))
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    hvac_map[sys_id] << air_loop_unitary

    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName(obj_name + " airloop")
    air_supply_inlet_node = air_loop.supplyInletNode
    air_supply_outlet_node = air_loop.supplyOutletNode
    air_demand_inlet_node = air_loop.demandInletNode
    air_demand_outlet_node = air_loop.demandOutletNode
    hvac_map[sys_id] << air_loop

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added '#{fan.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{clg_coil.name}' to '#{air_loop_unitary.name}'")

    air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)

    # _processSystemDemandSideAir
    # Demand Side

    # Supply Air
    zone_splitter = air_loop.zoneSplitter
    zone_splitter.setName(obj_name + " zone splitter")

    zone_mixer = air_loop.zoneMixer
    zone_mixer.setName(obj_name + " zone mixer")

    air_terminal_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
    air_terminal_living.setName(obj_name + " #{control_zone.name} terminal")
    air_loop.multiAddBranchForZone(control_zone, air_terminal_living)
    runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}'")

    control_zone.setSequentialCoolingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_cool_load_frac.round(5)))
    control_zone.setSequentialHeatingFractionSchedule(air_terminal_living, get_constant_schedule(model, 0))

    # Store info for HVAC Sizing measure
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cfms_ton_rated.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, frac_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameCentralAirConditioner)

    return true
  end

  def self.apply_central_ac_2speed(model, runner, seer, shrs,
                                   fan_power_installed, crankcase_kw, crankcase_temp,
                                   capacity, frac_cool_load_served,
                                   sequential_cool_load_frac, control_zone,
                                   hvac_map, sys_id)

    num_speeds = 2
    fan_power_rated = get_fan_power_rated(seer)
    capacity_ratios = HVAC.two_speed_capacity_ratios
    fan_speed_ratios = HVAC.two_speed_fan_speed_ratios_cooling

    # Cooling Coil
    rated_airflow_rate = 355.2 # cfm
    cfms_ton_rated = calc_cfms_ton_rated(rated_airflow_rate, fan_speed_ratios, capacity_ratios)
    eers = calc_EERs_cooling_2spd(runner, seer, HVAC.get_c_d_cooling(num_speeds, seer), capacity_ratios, fan_speed_ratios, fan_power_rated, cOOL_EIR_FT_SPEC_AC(2), cOOL_CAP_FT_SPEC_AC(2))
    cooling_eirs = calc_cooling_eirs(num_speeds, eers, fan_power_rated)
    shrs_rated_gross = calc_shrs_rated_gross(num_speeds, shrs, fan_power_rated, cfms_ton_rated)
    cOOL_CLOSS_FPLR_SPEC = [calc_plr_coefficients_cooling(num_speeds, seer)] * num_speeds

    obj_name = Constants.ObjectNameCentralAirConditioner

    # _processCurvesDXCooling

    clg_coil_stage_data = calc_coil_stage_data_cooling(model, capacity, (0...num_speeds).to_a, cooling_eirs, shrs_rated_gross, cOOL_CAP_FT_SPEC_AC(2), cOOL_EIR_FT_SPEC_AC(2), cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC_AC(2), cOOL_EIR_FFLOW_SPEC_AC(2))

    # _processSystemCoolingCoil

    clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
    clg_coil.setName(obj_name + " clg coil")
    clg_coil.setCondenserType("AirCooled")
    clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
    clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
    clg_coil.setCrankcaseHeaterCapacity(UnitConversions.convert(crankcase_kw, "kW", "W"))
    clg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(UnitConversions.convert(crankcase_temp, "F", "C"))
    clg_coil.setFuelType("Electricity")
    clg_coil_stage_data.each do |stage|
      clg_coil.addStage(stage)
    end
    hvac_map[sys_id] << clg_coil

    # _processSystemFan

    fan_power_curve = create_curve_exponent(model, [0, 1, 3], obj_name + " fan power curve", -100, 100)
    fan_eff_curve = create_curve_cubic(model, [0, 1, 0, 0], obj_name + " fan eff curve", 0, 1, 0.01, 1)
    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule, fan_power_curve, fan_eff_curve)
    fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
    fan.setName(obj_name + " supply fan")
    fan.setEndUseSubcategory("supply fan")
    fan.setFanEfficiency(fan_eff)
    fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_power_installed))
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [], [clg_coil])

    # _processSystemAir

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName(obj_name + " unitary system")
    air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop_unitary.setCoolingCoil(clg_coil)
    air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0)
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(120.0, "F", "C"))
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    hvac_map[sys_id] << air_loop_unitary

    perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
    air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
    perf.setSingleModeOperation(false)
    for speed in 1..num_speeds
      f = OpenStudio::Model::SupplyAirflowRatioField.fromCoolingRatio(fan_speed_ratios[speed - 1])
      perf.addSupplyAirflowRatioField(f)
    end

    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName(obj_name + " airloop")
    air_supply_inlet_node = air_loop.supplyInletNode
    air_supply_outlet_node = air_loop.supplyOutletNode
    air_demand_inlet_node = air_loop.demandInletNode
    air_demand_outlet_node = air_loop.demandOutletNode
    hvac_map[sys_id] << air_loop

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added '#{fan.name}' to #{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{clg_coil.name}' to '#{air_loop_unitary.name}'")

    air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)

    # _processSystemDemandSideAir
    # Demand Side

    # Supply Air
    zone_splitter = air_loop.zoneSplitter
    zone_splitter.setName(obj_name + " zone splitter")

    zone_mixer = air_loop.zoneMixer
    zone_mixer.setName(obj_name + " zone mixer")

    air_terminal_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
    air_terminal_living.setName(obj_name + " #{control_zone.name} terminal")
    air_loop.multiAddBranchForZone(control_zone, air_terminal_living)
    runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}'")

    control_zone.setSequentialCoolingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_cool_load_frac.round(5)))
    control_zone.setSequentialHeatingFractionSchedule(air_terminal_living, get_constant_schedule(model, 0))

    # Store info for HVAC Sizing measure
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, capacity_ratios.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cfms_ton_rated.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, frac_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameCentralAirConditioner)

    return true
  end

  def self.apply_central_ac_4speed(model, runner, seer, shrs,
                                   fan_power_installed, crankcase_kw, crankcase_temp,
                                   capacity, frac_cool_load_served,
                                   sequential_cool_load_frac, control_zone,
                                   hvac_map, sys_id)

    num_speeds = 4
    fan_power_rated = get_fan_power_rated(seer)
    capacity_ratios = HVAC.variable_speed_capacity_ratios_cooling
    fan_speed_ratios = HVAC.variable_speed_fan_speed_ratios_cooling

    cap_ratio_seer = [capacity_ratios[0], capacity_ratios[1], capacity_ratios[3]]
    fan_speed_seer = [fan_speed_ratios[0], fan_speed_ratios[1], fan_speed_ratios[3]]

    # Cooling Coil
    rated_airflow_rate = 411.0 # cfm
    cfms_ton_rated = calc_cfms_ton_rated(rated_airflow_rate, fan_speed_ratios, capacity_ratios)
    eers = calc_EERs_cooling_4spd(runner, seer, HVAC.get_c_d_cooling(num_speeds, seer), cap_ratio_seer, fan_speed_seer, fan_power_rated, cOOL_EIR_FT_SPEC_AC([0, 1, 4]), cOOL_CAP_FT_SPEC_AC([0, 1, 4]))
    cooling_eirs = calc_cooling_eirs(num_speeds, eers, fan_power_rated)
    shrs_rated_gross = calc_shrs_rated_gross(num_speeds, shrs, fan_power_rated, cfms_ton_rated)
    cOOL_CLOSS_FPLR_SPEC = [calc_plr_coefficients_cooling(num_speeds, seer)] * num_speeds

    hvac_map[sys_id] = []

    obj_name = Constants.ObjectNameCentralAirConditioner

    # _processCurvesDXCooling

    clg_coil_stage_data = calc_coil_stage_data_cooling(model, capacity, (0...num_speeds).to_a, cooling_eirs, shrs_rated_gross, cOOL_CAP_FT_SPEC_AC([0, 1, 2, 4]), cOOL_EIR_FT_SPEC_AC([0, 1, 2, 4]), cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC_AC(4), cOOL_EIR_FFLOW_SPEC_AC(4))

    # _processSystemCoolingCoil

    clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
    clg_coil.setName(obj_name + " clg coil")
    clg_coil.setCondenserType("AirCooled")
    clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
    clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
    clg_coil.setCrankcaseHeaterCapacity(UnitConversions.convert(crankcase_kw, "kW", "W"))
    clg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(UnitConversions.convert(crankcase_temp, "F", "C"))
    clg_coil.setFuelType("Electricity")
    clg_coil_stage_data.each do |stage|
      clg_coil.addStage(stage)
    end
    hvac_map[sys_id] << clg_coil

    # _processSystemFan

    fan_power_curve = create_curve_exponent(model, [0, 1, 3], obj_name + " fan power curve", -100, 100)
    fan_eff_curve = create_curve_cubic(model, [0, 1, 0, 0], obj_name + " fan eff curve", 0, 1, 0.01, 1)
    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule, fan_power_curve, fan_eff_curve)
    fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
    fan.setName(obj_name + " supply fan")
    fan.setEndUseSubcategory("supply fan")
    fan.setFanEfficiency(fan_eff)
    fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_power_installed))
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [], [clg_coil])

    # _processSystemAir

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName(obj_name + " unitary system")
    air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop_unitary.setCoolingCoil(clg_coil)
    air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0)
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(120.0, "F", "C"))
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    hvac_map[sys_id] << air_loop_unitary

    perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
    air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
    perf.setSingleModeOperation(false)
    for speed in 1..num_speeds
      f = OpenStudio::Model::SupplyAirflowRatioField.fromCoolingRatio(fan_speed_ratios[speed - 1])
      perf.addSupplyAirflowRatioField(f)
    end

    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName(obj_name + " airloop")
    air_supply_inlet_node = air_loop.supplyInletNode
    air_supply_outlet_node = air_loop.supplyOutletNode
    air_demand_inlet_node = air_loop.demandInletNode
    air_demand_outlet_node = air_loop.demandOutletNode
    hvac_map[sys_id] << air_loop

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added '#{fan.name}' to #{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{clg_coil.name}' to #{air_loop_unitary.name}'")

    air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)

    # _processSystemDemandSideAir
    # Demand Side

    # Supply Air
    zone_splitter = air_loop.zoneSplitter
    zone_splitter.setName(obj_name + " zone splitter")

    zone_mixer = air_loop.zoneMixer
    zone_mixer.setName(obj_name + " zone mixer")

    air_terminal_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
    air_terminal_living.setName(obj_name + " #{control_zone.name} terminal")
    air_loop.multiAddBranchForZone(control_zone, air_terminal_living)
    runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}'")

    control_zone.setSequentialCoolingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_cool_load_frac.round(5)))
    control_zone.setSequentialHeatingFractionSchedule(air_terminal_living, get_constant_schedule(model, 0))

    # Store info for HVAC Sizing measure
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, capacity_ratios.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cfms_ton_rated.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, frac_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameCentralAirConditioner)

    return true
  end

  def self.apply_central_ashp_1speed(model, runner, seer, hspf, shrs,
                                     fan_power_installed, min_temp, crankcase_kw, crankcase_temp,
                                     heat_pump_capacity_cool, heat_pump_capacity_heat, heat_pump_capacity_heat_17F,
                                     supplemental_efficiency, supplemental_capacity,
                                     frac_heat_load_served, frac_cool_load_served,
                                     sequential_heat_load_frac, sequential_cool_load_frac,
                                     control_zone, hvac_map, sys_id)

    num_speeds = 1
    fan_power_rated = get_fan_power_rated(seer)
    capacity_ratios = HVAC.one_speed_capacity_ratios
    fan_speed_ratios = HVAC.one_speed_fan_speed_ratios

    # Cooling Coil
    rated_airflow_rate_cooling = 394.2 # cfm
    cfms_ton_rated_cooling = calc_cfms_ton_rated(rated_airflow_rate_cooling, fan_speed_ratios, capacity_ratios)
    eers = [calc_EER_cooling_1spd(seer, fan_power_rated, cOOL_EIR_FT_SPEC_ASHP)]
    cooling_eirs = calc_cooling_eirs(num_speeds, eers, fan_power_rated)
    shrs_rated_gross = calc_shrs_rated_gross(num_speeds, shrs, fan_power_rated, cfms_ton_rated_cooling)
    cOOL_CLOSS_FPLR_SPEC = [calc_plr_coefficients_cooling(num_speeds, seer)]

    # Heating Coil
    rated_airflow_rate_heating = 384.1 # cfm
    cfms_ton_rated_heating = calc_cfms_ton_rated(rated_airflow_rate_heating, fan_speed_ratios, capacity_ratios)
    cops = [calc_COP_heating_1spd(hspf, HVAC.get_c_d_heating(num_speeds, hspf), fan_power_rated, hEAT_EIR_FT_SPEC_ASHP, hEAT_CAP_FT_SPEC_ASHP(1, heat_pump_capacity_heat, heat_pump_capacity_heat_17F))]
    heating_eirs = calc_heating_eirs(num_speeds, cops, fan_power_rated)
    hEAT_CLOSS_FPLR_SPEC = [calc_plr_coefficients_heating(num_speeds, hspf)]

    # Heating defrost curve for reverse cycle
    defrost_eir_curve = create_curve_biquadratic(model, [0.1528, 0, 0, 0, 0, 0], "DefrostEIR", -100, 100, -100, 100)

    obj_name = Constants.ObjectNameAirSourceHeatPump

    # _processCurvesDX

    htg_coil_stage_data = calc_coil_stage_data_heating(model, heat_pump_capacity_heat, (0...num_speeds).to_a, heating_eirs, hEAT_CAP_FT_SPEC_ASHP(1, heat_pump_capacity_heat, heat_pump_capacity_heat_17F), hEAT_EIR_FT_SPEC_ASHP, hEAT_CLOSS_FPLR_SPEC, hEAT_CAP_FFLOW_SPEC_ASHP, hEAT_EIR_FFLOW_SPEC_ASHP)
    clg_coil_stage_data = calc_coil_stage_data_cooling(model, heat_pump_capacity_cool, (0...num_speeds).to_a, cooling_eirs, shrs_rated_gross, cOOL_CAP_FT_SPEC_ASHP, cOOL_EIR_FT_SPEC_ASHP, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC_ASHP, cOOL_EIR_FFLOW_SPEC_ASHP)

    # _processSystemCoil

    htg_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, htg_coil_stage_data[0].heatingCapacityFunctionofTemperatureCurve, htg_coil_stage_data[0].heatingCapacityFunctionofFlowFractionCurve, htg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, htg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, htg_coil_stage_data[0].partLoadFractionCorrelationCurve)
    htg_coil_stage_data[0].remove
    htg_coil.setName(obj_name + " htg coil")
    if heat_pump_capacity_heat != Constants.SizingAuto
      htg_coil.setRatedTotalHeatingCapacity(UnitConversions.convert([heat_pump_capacity_heat, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    htg_coil.setRatedCOP(1.0 / heating_eirs[0])
    htg_coil.setRatedSupplyFanPowerPerVolumeFlowRate(fan_power_rated / UnitConversions.convert(1.0, "cfm", "m^3/s"))
    htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir_curve)
    htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(UnitConversions.convert(min_temp, "F", "C"))
    htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(UnitConversions.convert(40.0, "F", "C"))
    if frac_heat_load_served <= 0
      htg_coil.setCrankcaseHeaterCapacity(0.0)
    else
      htg_coil.setCrankcaseHeaterCapacity(UnitConversions.convert(crankcase_kw, "kW", "W"))
    end
    htg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(UnitConversions.convert(crankcase_temp, "F", "C"))
    htg_coil.setDefrostStrategy("ReverseCycle")
    htg_coil.setDefrostControl("OnDemand")
    hvac_map[sys_id] << htg_coil

    htg_supp_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
    htg_supp_coil.setName(obj_name + " supp htg coil")
    htg_supp_coil.setEfficiency(supplemental_efficiency)
    if supplemental_capacity != Constants.SizingAuto
      htg_supp_coil.setNominalCapacity(UnitConversions.convert([supplemental_capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    hvac_map[sys_id] << htg_supp_coil

    clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, clg_coil_stage_data[0].totalCoolingCapacityFunctionofTemperatureCurve, clg_coil_stage_data[0].totalCoolingCapacityFunctionofFlowFractionCurve, clg_coil_stage_data[0].energyInputRatioFunctionofTemperatureCurve, clg_coil_stage_data[0].energyInputRatioFunctionofFlowFractionCurve, clg_coil_stage_data[0].partLoadFractionCorrelationCurve)
    clg_coil_stage_data[0].remove
    clg_coil.setName(obj_name + " clg coil")
    if heat_pump_capacity_cool != Constants.SizingAuto
      clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert([heat_pump_capacity_cool, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    clg_coil.setRatedSensibleHeatRatio(shrs_rated_gross[0])
    clg_coil.setRatedCOP(1.0 / cooling_eirs[0])
    clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(fan_power_rated / UnitConversions.convert(1.0, "cfm", "m^3/s"))
    clg_coil.setNominalTimeForCondensateRemovalToBegin(1000.0)
    clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(1.5)
    clg_coil.setMaximumCyclingRate(3.0)
    clg_coil.setLatentCapacityTimeConstant(45.0)
    clg_coil.setCondenserType("AirCooled")
    hvac_map[sys_id] << clg_coil

    # _processSystemFan

    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
    fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
    fan.setName(obj_name + " supply fan")
    fan.setEndUseSubcategory("supply fan")
    fan.setFanEfficiency(fan_eff)
    fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_power_installed))
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [htg_coil, htg_supp_coil], [clg_coil])

    # _processSystemAir

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName(obj_name + " unitary system")
    air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setHeatingCoil(htg_coil)
    air_loop_unitary.setCoolingCoil(clg_coil)
    air_loop_unitary.setSupplementalHeatingCoil(htg_supp_coil)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(170.0, "F", "C")) # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.
    air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(UnitConversions.convert(40.0, "F", "C"))
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    hvac_map[sys_id] << air_loop_unitary

    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName(obj_name + " airloop")
    air_supply_inlet_node = air_loop.supplyInletNode
    air_supply_outlet_node = air_loop.supplyOutletNode
    air_demand_inlet_node = air_loop.demandInletNode
    air_demand_outlet_node = air_loop.demandOutletNode
    hvac_map[sys_id] << air_loop

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added '#{fan.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{clg_coil.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{htg_supp_coil.name}' to '#{air_loop_unitary.name}'")

    air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)

    # _processSystemDemandSideAir
    # Demand Side

    # Supply Air
    zone_splitter = air_loop.zoneSplitter
    zone_splitter.setName(obj_name + " zone splitter")

    zone_mixer = air_loop.zoneMixer
    zone_mixer.setName(obj_name + " zone mixer")

    air_terminal_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
    air_terminal_living.setName(obj_name + " #{control_zone.name} terminal")
    air_loop.multiAddBranchForZone(control_zone, air_terminal_living)
    runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}'")

    control_zone.setSequentialHeatingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_heat_load_frac.round(5)))
    control_zone.setSequentialCoolingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_cool_load_frac.round(5)))

    # Store info for HVAC Sizing measure
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonHeating, cfms_ton_rated_heating.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cfms_ton_rated_cooling.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, frac_heat_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, frac_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameAirSourceHeatPump)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameAirSourceHeatPump)

    return true
  end

  def self.apply_central_ashp_2speed(model, runner, seer, hspf, shrs,
                                     fan_power_installed, min_temp, crankcase_kw, crankcase_temp,
                                     heat_pump_capacity_cool, heat_pump_capacity_heat, heat_pump_capacity_heat_17F,
                                     supplemental_efficiency, supplemental_capacity,
                                     frac_heat_load_served, frac_cool_load_served,
                                     sequential_heat_load_frac, sequential_cool_load_frac,
                                     control_zone, hvac_map, sys_id)

    num_speeds = 2
    fan_power_rated = get_fan_power_rated(seer)
    capacity_ratios = HVAC.two_speed_capacity_ratios
    fan_speed_ratios_heating = HVAC.two_speed_fan_speed_ratios_heating
    fan_speed_ratios_cooling = HVAC.two_speed_fan_speed_ratios_cooling

    # Cooling Coil
    rated_airflow_rate_cooling = 344.1 # cfm
    cfms_ton_rated_cooling = calc_cfms_ton_rated(rated_airflow_rate_cooling, fan_speed_ratios_cooling, capacity_ratios)
    eers = calc_EERs_cooling_2spd(runner, seer, HVAC.get_c_d_cooling(num_speeds, seer), capacity_ratios, fan_speed_ratios_cooling, fan_power_rated, cOOL_EIR_FT_SPEC_ASHP(2), cOOL_CAP_FT_SPEC_ASHP(2), true)
    cooling_eirs = calc_cooling_eirs(num_speeds, eers, fan_power_rated)
    shrs_rated_gross = calc_shrs_rated_gross(num_speeds, shrs, fan_power_rated, cfms_ton_rated_cooling)
    cOOL_CLOSS_FPLR_SPEC = [calc_plr_coefficients_cooling(num_speeds, seer)] * num_speeds

    # Heating Coil
    rated_airflow_rate_heating = 352.2 # cfm
    cfms_ton_rated_heating = calc_cfms_ton_rated(rated_airflow_rate_heating, fan_speed_ratios_heating, capacity_ratios)
    cops = calc_COPs_heating_2spd(hspf, HVAC.get_c_d_heating(num_speeds, hspf), capacity_ratios, fan_speed_ratios_heating, fan_power_rated, hEAT_EIR_FT_SPEC_ASHP(2), hEAT_CAP_FT_SPEC_ASHP(2, heat_pump_capacity_heat, heat_pump_capacity_heat_17F))
    heating_eirs = calc_heating_eirs(num_speeds, cops, fan_power_rated)
    hEAT_CLOSS_FPLR_SPEC = [calc_plr_coefficients_heating(num_speeds, hspf)] * num_speeds

    # Heating defrost curve for reverse cycle
    defrost_eir_curve = create_curve_biquadratic(model, [0.1528, 0, 0, 0, 0, 0], "DefrostEIR", -100, 100, -100, 100)

    obj_name = Constants.ObjectNameAirSourceHeatPump

    # _processCurvesDX

    htg_coil_stage_data = calc_coil_stage_data_heating(model, heat_pump_capacity_heat, (0...num_speeds).to_a, heating_eirs, hEAT_CAP_FT_SPEC_ASHP(2, heat_pump_capacity_heat, heat_pump_capacity_heat_17F), hEAT_EIR_FT_SPEC_ASHP(2), hEAT_CLOSS_FPLR_SPEC, hEAT_CAP_FFLOW_SPEC_ASHP(2), hEAT_EIR_FFLOW_SPEC_ASHP(2))
    clg_coil_stage_data = calc_coil_stage_data_cooling(model, heat_pump_capacity_cool, (0...num_speeds).to_a, cooling_eirs, shrs_rated_gross, cOOL_CAP_FT_SPEC_ASHP(2), cOOL_EIR_FT_SPEC_ASHP(2), cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC_ASHP(2), cOOL_EIR_FFLOW_SPEC_ASHP(2))

    # _processSystemCoil

    htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
    htg_coil.setName(obj_name + " htg coil")
    htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(UnitConversions.convert(min_temp, "F", "C"))
    if frac_heat_load_served <= 0
      htg_coil.setCrankcaseHeaterCapacity(0.0)
    else
      htg_coil.setCrankcaseHeaterCapacity(UnitConversions.convert(crankcase_kw, "kW", "W"))
    end
    htg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(UnitConversions.convert(crankcase_temp, "F", "C"))
    htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir_curve)
    htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(UnitConversions.convert(40.0, "F", "C"))
    htg_coil.setDefrostStrategy("ReverseCycle")
    htg_coil.setDefrostControl("OnDemand")
    htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
    htg_coil.setFuelType("Electricity")
    htg_coil_stage_data.each do |stage|
      htg_coil.addStage(stage)
    end
    hvac_map[sys_id] << htg_coil

    htg_supp_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
    htg_supp_coil.setName(obj_name + " supp htg coil")
    htg_supp_coil.setEfficiency(supplemental_efficiency)
    if supplemental_capacity != Constants.SizingAuto
      htg_supp_coil.setNominalCapacity(UnitConversions.convert([supplemental_capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    hvac_map[sys_id] << htg_supp_coil

    clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
    clg_coil.setName(obj_name + " clg coil")
    clg_coil.setCondenserType("AirCooled")
    clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
    clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
    clg_coil.setFuelType("Electricity")
    clg_coil_stage_data.each do |stage|
      clg_coil.addStage(stage)
    end
    hvac_map[sys_id] << clg_coil

    # _processSystemFan

    fan_power_curve = create_curve_exponent(model, [0, 1, 3], obj_name + " fan power curve", -100, 100)
    fan_eff_curve = create_curve_cubic(model, [0, 1, 0, 0], obj_name + " fan eff curve", 0, 1, 0.01, 1)
    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule, fan_power_curve, fan_eff_curve)
    fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
    fan.setName(obj_name + " supply fan")
    fan.setEndUseSubcategory("supply fan")
    fan.setFanEfficiency(fan_eff)
    fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_power_installed))
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [htg_coil, htg_supp_coil], [clg_coil])

    perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
    perf.setSingleModeOperation(false)
    for speed in 1..num_speeds
      f = OpenStudio::Model::SupplyAirflowRatioField.new(fan_speed_ratios_heating[speed - 1], fan_speed_ratios_cooling[speed - 1])
      perf.addSupplyAirflowRatioField(f)
    end

    # _processSystemAir

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName(obj_name + " unitary system")
    air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setHeatingCoil(htg_coil)
    air_loop_unitary.setCoolingCoil(clg_coil)
    air_loop_unitary.setSupplementalHeatingCoil(htg_supp_coil)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(170.0, "F", "C")) # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.
    air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(UnitConversions.convert(40.0, "F", "C"))
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
    hvac_map[sys_id] << air_loop_unitary

    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName(obj_name + " airloop")
    air_supply_inlet_node = air_loop.supplyInletNode
    air_supply_outlet_node = air_loop.supplyOutletNode
    air_demand_inlet_node = air_loop.demandInletNode
    air_demand_outlet_node = air_loop.demandOutletNode
    hvac_map[sys_id] << air_loop

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added '#{fan.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{clg_coil.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{htg_supp_coil.name}' to '#{air_loop_unitary.name}'")

    air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)

    # _processSystemDemandSideAir
    # Demand Side

    # Supply Air
    zone_splitter = air_loop.zoneSplitter
    zone_splitter.setName(obj_name + " zone splitter")

    zone_mixer = air_loop.zoneMixer
    zone_mixer.setName(obj_name + " zone mixer")

    air_terminal_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
    air_terminal_living.setName(obj_name + " #{control_zone.name} terminal")
    air_loop.multiAddBranchForZone(control_zone, air_terminal_living)
    runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}'")

    control_zone.setSequentialHeatingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_heat_load_frac.round(5)))
    control_zone.setSequentialCoolingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_cool_load_frac.round(5)))

    # Store info for HVAC Sizing measure
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioHeating, capacity_ratios.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, capacity_ratios.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonHeating, cfms_ton_rated_heating.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cfms_ton_rated_cooling.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, frac_heat_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, frac_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameAirSourceHeatPump)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameAirSourceHeatPump)

    return true
  end

  def self.apply_central_ashp_4speed(model, runner, seer, hspf, shrs,
                                     fan_power_installed, min_temp, crankcase_kw, crankcase_temp,
                                     heat_pump_capacity_cool, heat_pump_capacity_heat, heat_pump_capacity_heat_17F,
                                     supplemental_efficiency, supplemental_capacity,
                                     frac_heat_load_served, frac_cool_load_served,
                                     sequential_heat_load_frac, sequential_cool_load_frac,
                                     control_zone, hvac_map, sys_id)

    num_speeds = 4
    fan_power_rated = get_fan_power_rated(seer)
    capacity_ratios_heating = HVAC.variable_speed_capacity_ratios_heating
    capacity_ratios_cooling = HVAC.variable_speed_capacity_ratios_cooling
    fan_speed_ratios_heating = HVAC.variable_speed_fan_speed_ratios_heating
    fan_speed_ratios_cooling = HVAC.variable_speed_fan_speed_ratios_cooling

    cap_ratio_seer = [capacity_ratios_cooling[0], capacity_ratios_cooling[1], capacity_ratios_cooling[3]]
    fan_speed_seer = [fan_speed_ratios_cooling[0], fan_speed_ratios_cooling[1], fan_speed_ratios_cooling[3]]

    # Cooling Coil
    rated_airflow_rate_cooling = 411.0 # cfm
    cfms_ton_rated_cooling = calc_cfms_ton_rated(rated_airflow_rate_cooling, fan_speed_ratios_cooling, capacity_ratios_cooling)
    eers = calc_EERs_cooling_4spd(runner, seer, HVAC.get_c_d_cooling(num_speeds, seer), cap_ratio_seer, fan_speed_seer, fan_power_rated, cOOL_EIR_FT_SPEC_ASHP([0, 1, 4]), cOOL_CAP_FT_SPEC_ASHP([0, 1, 4]))
    cooling_eirs = calc_cooling_eirs(num_speeds, eers, fan_power_rated)
    shrs_rated_gross = calc_shrs_rated_gross(num_speeds, shrs, fan_power_rated, cfms_ton_rated_cooling)
    cOOL_CLOSS_FPLR_SPEC = [calc_plr_coefficients_cooling(num_speeds, seer)] * num_speeds

    # Heating Coil
    rated_airflow_rate_heating = 296.9 # cfm
    cfms_ton_rated_heating = calc_cfms_ton_rated(rated_airflow_rate_heating, fan_speed_ratios_heating, capacity_ratios_heating)
    cops = calc_COPs_heating_4spd(runner, hspf, HVAC.get_c_d_heating(num_speeds, hspf), capacity_ratios_heating, fan_speed_ratios_heating, fan_power_rated, hEAT_EIR_FT_SPEC_ASHP(4), hEAT_CAP_FT_SPEC_ASHP(4, heat_pump_capacity_heat, heat_pump_capacity_heat_17F))
    heating_eirs = calc_heating_eirs(num_speeds, cops, fan_power_rated)
    hEAT_CLOSS_FPLR_SPEC = [calc_plr_coefficients_heating(num_speeds, hspf)] * num_speeds

    # Heating defrost curve for reverse cycle
    defrost_eir_curve = create_curve_biquadratic(model, [0.1528, 0, 0, 0, 0, 0], "DefrostEIR", -100, 100, -100, 100)

    obj_name = Constants.ObjectNameAirSourceHeatPump

    # _processCurvesDX

    htg_coil_stage_data = calc_coil_stage_data_heating(model, heat_pump_capacity_heat, (0...num_speeds).to_a, heating_eirs, hEAT_CAP_FT_SPEC_ASHP(4, heat_pump_capacity_heat, heat_pump_capacity_heat_17F), hEAT_EIR_FT_SPEC_ASHP(4), hEAT_CLOSS_FPLR_SPEC, hEAT_CAP_FFLOW_SPEC_ASHP(4), hEAT_EIR_FFLOW_SPEC_ASHP(4))
    clg_coil_stage_data = calc_coil_stage_data_cooling(model, heat_pump_capacity_cool, (0...num_speeds).to_a, cooling_eirs, shrs_rated_gross, cOOL_CAP_FT_SPEC_ASHP([0, 1, 2, 4]), cOOL_EIR_FT_SPEC_ASHP([0, 1, 2, 4]), cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC_ASHP(4), cOOL_EIR_FFLOW_SPEC_ASHP(4))

    # _processSystemCoil

    htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
    htg_coil.setName(obj_name + " htg coil")
    htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(UnitConversions.convert(min_temp, "F", "C"))
    if frac_heat_load_served <= 0
      htg_coil.setCrankcaseHeaterCapacity(0.0)
    else
      htg_coil.setCrankcaseHeaterCapacity(UnitConversions.convert(crankcase_kw, "kW", "W"))
    end
    htg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(UnitConversions.convert(crankcase_temp, "F", "C"))
    htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir_curve)
    htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(UnitConversions.convert(40.0, "F", "C"))
    htg_coil.setDefrostStrategy("ReverseCycle")
    htg_coil.setDefrostControl("OnDemand")
    htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
    htg_coil.setFuelType("Electricity")
    htg_coil_stage_data.each do |stage|
      htg_coil.addStage(stage)
    end
    hvac_map[sys_id] << htg_coil

    htg_supp_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
    htg_supp_coil.setName(obj_name + " supp htg coil")
    htg_supp_coil.setEfficiency(supplemental_efficiency)
    if supplemental_capacity != Constants.SizingAuto
      htg_supp_coil.setNominalCapacity(UnitConversions.convert([supplemental_capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end

    clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
    clg_coil.setName(obj_name + " clg coil")
    clg_coil.setCondenserType("AirCooled")
    clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
    clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
    clg_coil.setFuelType("Electricity")
    clg_coil_stage_data.each do |stage|
      clg_coil.addStage(stage)
    end
    hvac_map[sys_id] << clg_coil

    # _processSystemFan

    fan_power_curve = create_curve_exponent(model, [0, 1, 3], obj_name + " fan power curve", -100, 100)
    fan_eff_curve = create_curve_cubic(model, [0, 1, 0, 0], obj_name + " fan eff curve", 0, 1, 0.01, 1)
    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule, fan_power_curve, fan_eff_curve)
    fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
    fan.setName(obj_name + " supply fan")
    fan.setEndUseSubcategory("supply fan")
    fan.setFanEfficiency(fan_eff)
    fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_power_installed))
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [htg_coil, htg_supp_coil], [clg_coil])

    perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
    perf.setSingleModeOperation(false)
    for speed in 1..num_speeds
      f = OpenStudio::Model::SupplyAirflowRatioField.new(fan_speed_ratios_heating[speed - 1], fan_speed_ratios_cooling[speed - 1])
      perf.addSupplyAirflowRatioField(f)
    end

    # _processSystemAir

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName(obj_name + " unitary system")
    air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setHeatingCoil(htg_coil)
    air_loop_unitary.setCoolingCoil(clg_coil)
    air_loop_unitary.setSupplementalHeatingCoil(htg_supp_coil)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(170.0, "F", "C")) # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.
    air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(UnitConversions.convert(40.0, "F", "C"))
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
    hvac_map[sys_id] << air_loop_unitary

    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName(obj_name + " airloop")
    air_supply_inlet_node = air_loop.supplyInletNode
    air_supply_outlet_node = air_loop.supplyOutletNode
    air_demand_inlet_node = air_loop.demandInletNode
    air_demand_outlet_node = air_loop.demandOutletNode
    hvac_map[sys_id] << air_loop

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added '#{fan.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{clg_coil.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{htg_supp_coil.name}' to '#{air_loop_unitary.name}'")

    air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)

    # _processSystemDemandSideAir
    # Demand Side

    # Supply Air
    zone_splitter = air_loop.zoneSplitter
    zone_splitter.setName(obj_name + " zone splitter")

    zone_mixer = air_loop.zoneMixer
    zone_mixer.setName(obj_name + " zone mixer")

    air_terminal_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
    air_terminal_living.setName(obj_name + " #{control_zone.name} terminal")
    air_loop.multiAddBranchForZone(control_zone, air_terminal_living)
    runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}'")

    control_zone.setSequentialHeatingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_heat_load_frac.round(5)))
    control_zone.setSequentialCoolingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_cool_load_frac.round(5)))

    # Store info for HVAC Sizing measure
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioHeating, capacity_ratios_heating.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, capacity_ratios_cooling.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonHeating, cfms_ton_rated_heating.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cfms_ton_rated_cooling.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, frac_heat_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, frac_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameAirSourceHeatPump)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameAirSourceHeatPump)

    return true
  end

  def self.apply_mshp(model, runner, seer, hspf, shr,
                      min_cooling_capacity, max_cooling_capacity,
                      min_cooling_airflow_rate, max_cooling_airflow_rate,
                      min_heating_capacity, max_heating_capacity,
                      min_heating_airflow_rate, max_heating_airflow_rate,
                      heating_capacity_offset, cap_retention_frac, cap_retention_temp,
                      pan_heater_power, fan_power, is_ducted,
                      heat_pump_capacity, supplemental_efficiency, supplemental_capacity,
                      frac_heat_load_served, frac_cool_load_served,
                      sequential_heat_load_frac, sequential_cool_load_frac,
                      control_zone, hvac_map, sys_id)

    num_speeds = 10

    # htg_supply_air_temp = 105
    supp_htg_max_supply_temp = 200.0
    min_hp_temp = -30.0 # F; Minimum temperature for Heat Pump operation
    supp_htg_max_outdoor_temp = 40.0
    max_defrost_temp = 40.0 # F

    # Performance curves
    cOOL_CAP_FT_SPEC = [[0.7531983499655835, 0.003618193903031667, 0.0, 0.006574385031351544, -6.87181191015432e-05, 0.0]] * num_speeds
    cOOL_EIR_FT_SPEC = [[-0.06376924779982301, -0.0013360593470367282, 1.413060577993827e-05, 0.019433076486584752, -4.91395947154321e-05, -4.909341249475308e-05]] * num_speeds
    cOOL_CAP_FFLOW_SPEC = [[1, 0, 0]] * num_speeds
    cOOL_EIR_FFLOW_SPEC = [[1, 0, 0]] * num_speeds

    # Mini-Split Heat Pump Heating Curve Coefficients
    # Derive coefficients from user input for capacity retention at outdoor drybulb temperature X [C].
    # Biquadratic: capacity multiplier = a + b*IAT + c*IAT^2 + d*OAT + e*OAT^2 + f*IAT*OAT
    x_A = UnitConversions.convert(cap_retention_temp, "F", "C")
    y_A = cap_retention_frac
    x_B = UnitConversions.convert(47.0, "F", "C") # 47F is the rating point
    y_B = 1.0 # Maximum capacity factor is 1 at the rating point, by definition (this is maximum capacity, not nominal capacity)
    oat_slope = (y_B - y_A) / (x_B - x_A)
    oat_intercept = y_A - (x_A * oat_slope)

    # Coefficients for the indoor temperature relationship are retained from the BEoptDefault curve (Daikin lab data).
    iat_slope = -0.010386676170938
    iat_intercept = 0.219274275

    a = oat_intercept + iat_intercept
    b = iat_slope
    c = 0
    d = oat_slope
    e = 0
    f = 0

    hEAT_CAP_FT_SPEC = [convert_curve_biquadratic([a, b, c, d, e, f], false)] * num_speeds

    # COP/EIR as a function of temperature
    # Generic "BEoptDefault" curves (=Daikin from lab data)
    hEAT_EIR_FT_SPEC = [[0.9999941697687026, 0.004684593830254383, 5.901286675833333e-05, -0.0028624467783091973, 1.3041120194135802e-05, -0.00016172918478765433]] * num_speeds
    hEAT_CAP_FFLOW_SPEC = [[1, 0, 0]] * num_speeds
    hEAT_EIR_FFLOW_SPEC = [[1, 0, 0]] * num_speeds

    # Cooling Coil
    c_d_cooling = HVAC.get_c_d_cooling(num_speeds, seer)
    cOOL_CLOSS_FPLR_SPEC = [calc_plr_coefficients_cooling(num_speeds, seer, c_d_cooling)] * num_speeds
    dB_rated = 80.0
    wB_rated = 67.0
    cfms_cooling, capacity_ratios_cooling, shrs_rated = calc_mshp_cfms_ton_cooling(min_cooling_capacity, max_cooling_capacity, min_cooling_airflow_rate, max_cooling_airflow_rate, num_speeds, dB_rated, wB_rated, shr)
    cooling_eirs = calc_mshp_cooling_eirs(runner, seer, fan_power, c_d_cooling, num_speeds, capacity_ratios_cooling, cfms_cooling, cOOL_EIR_FT_SPEC, cOOL_CAP_FT_SPEC)

    # Heating Coil
    c_d_heating = HVAC.get_c_d_heating(num_speeds, hspf)
    hEAT_CLOSS_FPLR_SPEC = [calc_plr_coefficients_heating(num_speeds, hspf, c_d_heating)] * num_speeds
    cfms_heating, capacity_ratios_heating = calc_mshp_cfms_ton_heating(min_heating_capacity, max_heating_capacity, min_heating_airflow_rate, max_heating_airflow_rate, num_speeds)
    heating_eirs = calc_mshp_heating_eirs(runner, hspf, fan_power, min_hp_temp, c_d_heating, cfms_cooling, num_speeds, capacity_ratios_heating, cfms_heating, hEAT_EIR_FT_SPEC, hEAT_CAP_FT_SPEC)

    defrost_eir_curve = create_curve_biquadratic(model, [0.1528, 0, 0, 0, 0, 0], "DefrostEIR", -100, 100, -100, 100)

    mshp_indices = [1, 3, 5, 9]

    obj_name = Constants.ObjectNameMiniSplitHeatPump

    # _processCurvesDX

    htg_coil_stage_data = calc_coil_stage_data_heating(model, heat_pump_capacity, mshp_indices, heating_eirs, hEAT_CAP_FT_SPEC, hEAT_EIR_FT_SPEC, hEAT_CLOSS_FPLR_SPEC, hEAT_CAP_FFLOW_SPEC, hEAT_EIR_FFLOW_SPEC)
    clg_coil_stage_data = calc_coil_stage_data_cooling(model, heat_pump_capacity, mshp_indices, cooling_eirs, shrs_rated, cOOL_CAP_FT_SPEC, cOOL_EIR_FT_SPEC, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC, cOOL_EIR_FFLOW_SPEC)

    # _processSystemCoil

    htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
    htg_coil.setName(obj_name + " htg coil")
    htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(UnitConversions.convert(min_hp_temp, "F", "C"))
    htg_coil.setCrankcaseHeaterCapacity(0)
    htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir_curve)
    htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(UnitConversions.convert(max_defrost_temp, "F", "C"))
    htg_coil.setDefrostStrategy("ReverseCycle")
    htg_coil.setDefrostControl("OnDemand")
    htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
    htg_coil.setFuelType("Electricity")
    htg_coil_stage_data.each do |stage|
      htg_coil.addStage(stage)
    end
    hvac_map[sys_id] << htg_coil

    htg_supp_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
    htg_supp_coil.setName(obj_name + " supp htg coil")
    htg_supp_coil.setEfficiency(supplemental_efficiency)
    if supplemental_capacity != Constants.SizingAuto
      htg_supp_coil.setNominalCapacity(UnitConversions.convert([supplemental_capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    hvac_map[sys_id] << htg_supp_coil

    clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
    clg_coil.setName(obj_name + " clg coil")
    clg_coil.setCondenserType("AirCooled")
    clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
    clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
    clg_coil.setCrankcaseHeaterCapacity(0)
    clg_coil.setFuelType("Electricity")
    clg_coil_stage_data.each do |stage|
      clg_coil.addStage(stage)
    end
    hvac_map[sys_id] << clg_coil

    # _processSystemFan

    fan_power_curve = create_curve_exponent(model, [0, 1, 3], obj_name + " fan power curve", -100, 100)
    fan_eff_curve = create_curve_cubic(model, [0, 1, 0, 0], obj_name + " fan eff curve", 0, 1, 0.01, 1)
    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule, fan_power_curve, fan_eff_curve)
    fan_eff = UnitConversions.convert(UnitConversions.convert(0.1, "inH2O", "Pa") / fan_power, "cfm", "m^3/s") # Overall Efficiency of the Fan, Motor and Drive
    fan.setName(obj_name + " supply fan")
    fan.setEndUseSubcategory("supply fan")
    fan.setFanEfficiency(fan_eff)
    fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_power))
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [htg_coil, htg_supp_coil], [clg_coil])

    perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
    perf.setSingleModeOperation(false)
    mshp_indices.each do |mshp_index|
      ratio_heating = cfms_heating[mshp_index] / cfms_heating[mshp_indices[-1]]
      ratio_cooling = cfms_cooling[mshp_index] / cfms_cooling[mshp_indices[-1]]
      f = OpenStudio::Model::SupplyAirflowRatioField.new(ratio_heating, ratio_cooling)
      perf.addSupplyAirflowRatioField(f)
    end

    # _processSystemAir

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName(obj_name + " unitary system")
    air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setHeatingCoil(htg_coil)
    air_loop_unitary.setCoolingCoil(clg_coil)
    air_loop_unitary.setSupplementalHeatingCoil(htg_supp_coil)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(supp_htg_max_supply_temp, "F", "C")) # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.
    air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(UnitConversions.convert(supp_htg_max_outdoor_temp, "F", "C"))
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
    hvac_map[sys_id] << air_loop_unitary

    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName(obj_name + " airloop")
    air_supply_inlet_node = air_loop.supplyInletNode
    air_supply_outlet_node = air_loop.supplyOutletNode
    air_demand_inlet_node = air_loop.demandInletNode
    air_demand_outlet_node = air_loop.demandOutletNode
    hvac_map[sys_id] << air_loop

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added '#{fan.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{clg_coil.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{htg_supp_coil.name}' to '#{air_loop_unitary.name}'")

    air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)

    # _processSystemDemandSideAir
    # Demand Side

    # Supply Air
    zone_splitter = air_loop.zoneSplitter
    zone_splitter.setName(obj_name + " zone splitter")

    zone_mixer = air_loop.zoneMixer
    zone_mixer.setName(obj_name + " zone mixer")

    air_terminal_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
    air_terminal_living.setName(obj_name + " #{control_zone.name} terminal")
    air_loop.multiAddBranchForZone(control_zone, air_terminal_living)
    runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}'")

    control_zone.setSequentialHeatingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_heat_load_frac.round(5)))
    control_zone.setSequentialCoolingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_cool_load_frac.round(5)))

    if pan_heater_power > 0

      mshp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Heating Coil Electric Energy")
      mshp_sensor.setName("#{obj_name} vrf energy sensor")
      mshp_sensor.setKeyName(obj_name + " coil")

      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName(obj_name + " pan heater equip")
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName(equip_def.name.to_s)
      equip.setSpace(control_zone.spaces[0])
      equip_def.setFractionRadiant(0)
      equip_def.setFractionLatent(0)
      equip_def.setFractionLost(1)
      equip.setSchedule(model.alwaysOnDiscreteSchedule)
      equip.setEndUseSubcategory(obj_name + " pan heater")

      pan_heater_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
      pan_heater_actuator.setName("#{obj_name} pan heater actuator")

      tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Zone Outdoor Air Drybulb Temperature")
      tout_sensor.setName("#{obj_name} tout sensor")
      thermal_zones.each do |thermal_zone|
        if Geometry.is_living(thermal_zone)
          tout_sensor.setKeyName(thermal_zone.name.to_s)
          break
        end
      end

      program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      program.setName(obj_name + " pan heater program")
      if heat_pump_capacity != Constants.SizingAuto
        num_outdoor_units = (UnitConversions.convert([heat_pump_capacity, Constants.small].max, "Btu/hr", "ton") / 1.5).ceil # Assume 1.5 tons max per outdoor unit
      else
        num_outdoor_units = 2
      end
      pan_heater_power = pan_heater_power * num_outdoor_units # W
      program.addLine("Set #{pan_heater_actuator.name} = 0")
      program.addLine("If #{mshp_sensor.name} > 0")
      program.addLine("  If #{tout_sensor.name} <= #{UnitConversions.convert(32.0, "F", "C").round(3)}")
      program.addLine("    Set #{pan_heater_actuator.name} = #{pan_heater_power}")
      program.addLine("  EndIf")
      program.addLine("EndIf")

      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName(obj_name + " pan heater program calling manager")
      program_calling_manager.setCallingPoint("BeginTimestepBeforePredictor")
      program_calling_manager.addProgram(program)

    end

    # Store info for HVAC Sizing measure
    capacity_ratios_heating_4 = []
    capacity_ratios_cooling_4 = []
    cfms_heating_4 = []
    cfms_cooling_4 = []
    shrs_rated_4 = []
    mshp_indices.each do |mshp_index|
      capacity_ratios_heating_4 << capacity_ratios_heating[mshp_index]
      capacity_ratios_cooling_4 << capacity_ratios_cooling[mshp_index]
      cfms_heating_4 << cfms_heating[mshp_index]
      cfms_cooling_4 << cfms_cooling[mshp_index]
      shrs_rated_4 << shrs_rated[mshp_index]
    end
    air_loop_unitary.additionalProperties.setFeature(Constants.DuctedInfoMiniSplitHeatPump, is_ducted)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioHeating, capacity_ratios_heating_4.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, capacity_ratios_cooling_4.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatingCFMs, cfms_heating_4.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolingCFMs, cfms_cooling_4.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatingCapacityOffset, heating_capacity_offset)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, frac_heat_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, frac_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACSHR, shrs_rated_4.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameMiniSplitHeatPump)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameMiniSplitHeatPump)

    return true
  end

  def self.apply_gshp(model, runner, weather, cop, eer, shr,
                      ground_conductivity, grout_conductivity,
                      bore_config, bore_holes, bore_depth,
                      bore_spacing, bore_diameter, pipe_size,
                      ground_diffusivity, fluid_type, frac_glycol,
                      design_delta_t, pump_head,
                      u_tube_leg_spacing, u_tube_spacing_type,
                      fan_power, heat_pump_capacity_cool, heat_pump_capacity_heat,
                      supplemental_efficiency, supplemental_capacity,
                      frac_heat_load_served, frac_cool_load_served,
                      sequential_heat_load_frac, sequential_cool_load_frac,
                      control_zone, hvac_map, sys_id)

    if frac_glycol == 0
      fluid_type = Constants.FluidWater
      runner.registerWarning("Specified #{fluid_type} fluid type and 0 fraction of glycol, so assuming #{Constants.FluidWater} fluid type.")
    end

    # Ground Loop Heat Exchanger
    pipe_od, pipe_id = get_gshp_hx_pipe_diameters(pipe_size)

    # Thermal Resistance of Pipe
    pipe_cond = 0.23 # Pipe thermal conductivity, default to high density polyethylene

    chw_design = get_gshp_HXCHWDesign(weather)
    hw_design = get_gshp_HXHWDesign(weather, fluid_type)

    # Cooling Coil
    coilBF = 0.08060000
    cOOL_CAP_FT_SPEC = [0.39039063, 0.01382596, 0.00000000, -0.00445738, 0.00000000, 0.00000000]
    cOOL_SH_FT_SPEC = [4.27136253, -0.04678521, 0.00000000, -0.00219031, 0.00000000, 0.00000000]
    cOOL_POWER_FT_SPEC = [0.01717338, 0.00316077, 0.00000000, 0.01043792, 0.00000000, 0.00000000]
    cOIL_BF_FT_SPEC = [1.21005458, -0.00664200, 0.00000000, 0.00348246, 0.00000000, 0.00000000]
    gshp_COOL_CAP_fT_coeff = convert_curve_gshp(cOOL_CAP_FT_SPEC, false)
    gshp_COOL_POWER_fT_coeff = convert_curve_gshp(cOOL_POWER_FT_SPEC, false)
    gshp_COOL_SH_fT_coeff = convert_curve_gshp(cOOL_SH_FT_SPEC, false)

    # Heating Coil
    hEAT_CAP_FT_SEC = [0.67104926, -0.00210834, 0.00000000, 0.01491424, 0.00000000, 0.00000000]
    hEAT_POWER_FT_SPEC = [-0.46308105, 0.02008988, 0.00000000, 0.00300222, 0.00000000, 0.00000000]
    gshp_HEAT_CAP_fT_coeff = convert_curve_gshp(hEAT_CAP_FT_SEC, false)
    gshp_HEAT_POWER_fT_coeff = convert_curve_gshp(hEAT_POWER_FT_SPEC, false)

    fanKW_Adjust = get_gshp_FanKW_Adjust(UnitConversions.convert(400.0, "Btu/hr", "ton"))
    pumpKW_Adjust = get_gshp_PumpKW_Adjust(UnitConversions.convert(3.0, "Btu/hr", "ton"))
    coolingEIR = get_gshp_cooling_eir(eer, fanKW_Adjust, pumpKW_Adjust)

    # Heating Coil
    heatingEIR = get_gshp_heating_eir(cop, fanKW_Adjust, pumpKW_Adjust)
    min_hp_temp = -30.0

    obj_name = Constants.ObjectNameGroundSourceHeatPump

    ground_heat_exch_vert = OpenStudio::Model::GroundHeatExchangerVertical.new(model)
    ground_heat_exch_vert.setName(obj_name + " exchanger")
    ground_heat_exch_vert.setBoreHoleRadius(UnitConversions.convert(bore_diameter / 2.0, "in", "m"))
    ground_heat_exch_vert.setGroundThermalConductivity(UnitConversions.convert(ground_conductivity, "Btu/(hr*ft*R)", "W/(m*K)"))
    ground_heat_exch_vert.setGroundThermalHeatCapacity(UnitConversions.convert(ground_conductivity / ground_diffusivity, "Btu/(ft^3*F)", "J/(m^3*K)"))
    ground_heat_exch_vert.setGroundTemperature(UnitConversions.convert(weather.data.AnnualAvgDrybulb, "F", "C"))
    ground_heat_exch_vert.setGroutThermalConductivity(UnitConversions.convert(grout_conductivity, "Btu/(hr*ft*R)", "W/(m*K)"))
    ground_heat_exch_vert.setPipeThermalConductivity(UnitConversions.convert(pipe_cond, "Btu/(hr*ft*R)", "W/(m*K)"))
    ground_heat_exch_vert.setPipeOutDiameter(UnitConversions.convert(pipe_od, "in", "m"))
    ground_heat_exch_vert.setUTubeDistance(UnitConversions.convert(u_tube_leg_spacing, "in", "m"))
    ground_heat_exch_vert.setPipeThickness(UnitConversions.convert((pipe_od - pipe_id) / 2.0, "in", "m"))
    ground_heat_exch_vert.setMaximumLengthofSimulation(1)
    ground_heat_exch_vert.setGFunctionReferenceRatio(0.0005)

    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName(obj_name + " condenser loop")
    if fluid_type == Constants.FluidWater
      plant_loop.setFluidType('Water')
    else
      plant_loop.setFluidType({ Constants.FluidPropyleneGlycol => 'PropyleneGlycol', Constants.FluidEthyleneGlycol => 'EthyleneGlycol' }[fluid_type])
      plant_loop.setGlycolConcentration((frac_glycol * 100).to_i)
    end
    plant_loop.setMaximumLoopTemperature(48.88889)
    plant_loop.setMinimumLoopTemperature(UnitConversions.convert(hw_design, "F", "C"))
    plant_loop.setMinimumLoopFlowRate(0)
    plant_loop.setLoadDistributionScheme('SequentialLoad')
    runner.registerInfo("Added '#{plant_loop.name}' to model.")
    hvac_map[sys_id] << plant_loop

    sizing_plant = plant_loop.sizingPlant
    sizing_plant.setLoopType('Condenser')
    sizing_plant.setDesignLoopExitTemperature(UnitConversions.convert(chw_design, "F", "C"))
    sizing_plant.setLoopDesignTemperatureDifference(UnitConversions.convert(design_delta_t, "R", "K"))

    setpoint_mgr_follow_ground_temp = OpenStudio::Model::SetpointManagerFollowGroundTemperature.new(model)
    setpoint_mgr_follow_ground_temp.setName(obj_name + " condenser loop temp")
    setpoint_mgr_follow_ground_temp.setControlVariable('Temperature')
    setpoint_mgr_follow_ground_temp.setMaximumSetpointTemperature(48.88889)
    setpoint_mgr_follow_ground_temp.setMinimumSetpointTemperature(UnitConversions.convert(hw_design, "F", "C"))
    setpoint_mgr_follow_ground_temp.setReferenceGroundTemperatureObjectType('Site:GroundTemperature:Deep')
    setpoint_mgr_follow_ground_temp.addToNode(plant_loop.supplyOutletNode)

    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setName(obj_name + " pump")
    pump.setRatedPumpHead(pump_head)
    pump.setMotorEfficiency(0.77 * 0.6)
    pump.setFractionofMotorInefficienciestoFluidStream(0)
    pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
    pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
    pump.setMinimumFlowRate(0)
    pump.setPumpControlType('Intermittent')
    pump.addToNode(plant_loop.supplyInletNode)
    hvac_map[sys_id] << pump

    plant_loop.addSupplyBranchForComponent(ground_heat_exch_vert)

    chiller_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    plant_loop.addSupplyBranchForComponent(chiller_bypass_pipe)
    coil_bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    plant_loop.addDemandBranchForComponent(coil_bypass_pipe)
    supply_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    supply_outlet_pipe.addToNode(plant_loop.supplyOutletNode)
    demand_inlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    demand_inlet_pipe.addToNode(plant_loop.demandInletNode)
    demand_outlet_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    demand_outlet_pipe.addToNode(plant_loop.demandOutletNode)

    htg_coil = OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit.new(model)
    htg_coil.setName(obj_name + " htg coil")
    if heat_pump_capacity_heat != Constants.SizingAuto
      htg_coil.setRatedHeatingCapacity(UnitConversions.convert([heat_pump_capacity_heat, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    htg_coil.setRatedHeatingCoefficientofPerformance(1.0 / heatingEIR)
    htg_coil.setHeatingCapacityCoefficient1(gshp_HEAT_CAP_fT_coeff[0])
    htg_coil.setHeatingCapacityCoefficient2(gshp_HEAT_CAP_fT_coeff[1])
    htg_coil.setHeatingCapacityCoefficient3(gshp_HEAT_CAP_fT_coeff[2])
    htg_coil.setHeatingCapacityCoefficient4(gshp_HEAT_CAP_fT_coeff[3])
    htg_coil.setHeatingCapacityCoefficient5(gshp_HEAT_CAP_fT_coeff[4])
    htg_coil.setHeatingPowerConsumptionCoefficient1(gshp_HEAT_POWER_fT_coeff[0])
    htg_coil.setHeatingPowerConsumptionCoefficient2(gshp_HEAT_POWER_fT_coeff[1])
    htg_coil.setHeatingPowerConsumptionCoefficient3(gshp_HEAT_POWER_fT_coeff[2])
    htg_coil.setHeatingPowerConsumptionCoefficient4(gshp_HEAT_POWER_fT_coeff[3])
    htg_coil.setHeatingPowerConsumptionCoefficient5(gshp_HEAT_POWER_fT_coeff[4])
    hvac_map[sys_id] << htg_coil

    htg_supp_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
    htg_supp_coil.setName(obj_name + " supp htg coil")
    htg_supp_coil.setEfficiency(supplemental_efficiency)
    if supplemental_capacity != Constants.SizingAuto
      htg_supp_coil.setNominalCapacity(UnitConversions.convert([supplemental_capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    hvac_map[sys_id] << htg_supp_coil

    clg_coil = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model)
    clg_coil.setName(obj_name + " clg coil")
    if heat_pump_capacity_cool != Constants.SizingAuto
      clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert([heat_pump_capacity_cool, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    clg_coil.setRatedCoolingCoefficientofPerformance(1.0 / coolingEIR)
    clg_coil.setTotalCoolingCapacityCoefficient1(gshp_COOL_CAP_fT_coeff[0])
    clg_coil.setTotalCoolingCapacityCoefficient2(gshp_COOL_CAP_fT_coeff[1])
    clg_coil.setTotalCoolingCapacityCoefficient3(gshp_COOL_CAP_fT_coeff[2])
    clg_coil.setTotalCoolingCapacityCoefficient4(gshp_COOL_CAP_fT_coeff[3])
    clg_coil.setTotalCoolingCapacityCoefficient5(gshp_COOL_CAP_fT_coeff[4])
    clg_coil.setSensibleCoolingCapacityCoefficient1(gshp_COOL_SH_fT_coeff[0])
    clg_coil.setSensibleCoolingCapacityCoefficient2(0)
    clg_coil.setSensibleCoolingCapacityCoefficient3(gshp_COOL_SH_fT_coeff[1])
    clg_coil.setSensibleCoolingCapacityCoefficient4(gshp_COOL_SH_fT_coeff[2])
    clg_coil.setSensibleCoolingCapacityCoefficient5(gshp_COOL_SH_fT_coeff[3])
    clg_coil.setSensibleCoolingCapacityCoefficient6(gshp_COOL_SH_fT_coeff[4])
    clg_coil.setCoolingPowerConsumptionCoefficient1(gshp_COOL_POWER_fT_coeff[0])
    clg_coil.setCoolingPowerConsumptionCoefficient2(gshp_COOL_POWER_fT_coeff[1])
    clg_coil.setCoolingPowerConsumptionCoefficient3(gshp_COOL_POWER_fT_coeff[2])
    clg_coil.setCoolingPowerConsumptionCoefficient4(gshp_COOL_POWER_fT_coeff[3])
    clg_coil.setCoolingPowerConsumptionCoefficient5(gshp_COOL_POWER_fT_coeff[4])
    clg_coil.setNominalTimeforCondensateRemovaltoBegin(1000)
    clg_coil.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
    hvac_map[sys_id] << clg_coil

    plant_loop.addDemandBranchForComponent(htg_coil)
    plant_loop.addDemandBranchForComponent(clg_coil)

    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
    fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
    fan.setName(obj_name + " supply fan")
    fan.setEndUseSubcategory("supply fan")
    fan.setFanEfficiency(fan_eff)
    fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_power))
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [htg_coil, htg_supp_coil], [clg_coil])
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, pump, [htg_coil, htg_supp_coil], [clg_coil])

    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName(obj_name + " unitary system")
    air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setHeatingCoil(htg_coil)
    air_loop_unitary.setCoolingCoil(clg_coil)
    air_loop_unitary.setSupplementalHeatingCoil(htg_supp_coil)
    air_loop_unitary.setFanPlacement("BlowThrough")
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(170.0, "F", "C")) # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.
    air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(UnitConversions.convert(40.0, "F", "C"))
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    hvac_map[sys_id] << air_loop_unitary

    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setName(obj_name + " airloop")
    air_supply_inlet_node = air_loop.supplyInletNode
    air_supply_outlet_node = air_loop.supplyOutletNode
    air_demand_inlet_node = air_loop.demandInletNode
    air_demand_outlet_node = air_loop.demandOutletNode
    hvac_map[sys_id] << air_loop

    air_loop_unitary.addToNode(air_supply_inlet_node)

    runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{clg_coil.name}' to '#{air_loop_unitary.name}'")
    runner.registerInfo("Added '#{htg_supp_coil.name}' to '#{air_loop_unitary.name}'")

    air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)

    zone_splitter = air_loop.zoneSplitter
    zone_splitter.setName(obj_name + " zone splitter")

    zone_mixer = air_loop.zoneMixer
    zone_mixer.setName(obj_name + " zone mixer")

    air_terminal_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
    air_terminal_living.setName(obj_name + " #{control_zone.name} terminal")
    air_loop.multiAddBranchForZone(control_zone, air_terminal_living)
    runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}'")

    control_zone.setSequentialHeatingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_heat_load_frac.round(5)))
    control_zone.setSequentialCoolingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_cool_load_frac.round(5)))

    # Store info for HVAC Sizing measure
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACSHR, shr.to_s)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPCoil_BF_FT_SPEC, cOIL_BF_FT_SPEC.join(","))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPCoilBF, coilBF)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, frac_heat_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, frac_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPBoreSpacing, bore_spacing)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPBoreHoles, bore_holes)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPBoreDepth, bore_depth)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPBoreConfig, bore_config)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPUTubeSpacingType, u_tube_spacing_type)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameGroundSourceHeatPump)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameGroundSourceHeatPump)

    return true
  end

  def self.apply_room_ac(model, runner, eer, shr,
                         airflow_rate, capacity, frac_cool_load_served,
                         sequential_cool_load_frac, control_zone,
                         hvac_map, sys_id)

    # Performance curves
    # From Frigidaire 10.7 EER unit in Winkler et. al. Lab Testing of Window ACs (2013)

    cOOL_CAP_FT_SPEC = [0.43945980246913574, -0.0008922469135802481, 0.00013984567901234569, 0.0038489259259259253, -5.6327160493827156e-05, 2.041358024691358e-05]
    cOOL_CAP_FT_SPEC_si = convert_curve_biquadratic(cOOL_CAP_FT_SPEC)
    cOOL_EIR_FT_SPEC = [6.310506172839506, -0.17705185185185185, 0.0014645061728395061, 0.012571604938271608, 0.0001493827160493827, -0.00040308641975308644]
    cOOL_EIR_FT_SPEC_si = convert_curve_biquadratic(cOOL_EIR_FT_SPEC)
    cOOL_CAP_FFLOW_SPEC = [0.887, 0.1128, 0]
    cOOL_EIR_FFLOW_SPEC = [1.763, -0.6081, 0]
    cOOL_PLF_FPLR = [0.78, 0.22, 0]
    cfms_ton_rated = [312] # medium speed

    roomac_cap_ft_curve = create_curve_biquadratic(model, cOOL_CAP_FT_SPEC_si, "RoomAC-Cap-fT", 0, 100, 0, 100)
    roomac_cap_fff_curve = create_curve_quadratic(model, cOOL_CAP_FFLOW_SPEC, "RoomAC-Cap-fFF", 0, 2, 0, 2)
    roomac_eir_ft_curve = create_curve_biquadratic(model, cOOL_EIR_FT_SPEC_si, "RoomAC-EIR-fT", 0, 100, 0, 100)
    roomcac_eir_fff_curve = create_curve_quadratic(model, cOOL_EIR_FFLOW_SPEC, "RoomAC-EIR-fFF", 0, 2, 0, 2)
    roomac_plf_fplr_curve = create_curve_quadratic(model, cOOL_PLF_FPLR, "RoomAC-PLF-fPLR", 0, 1, 0, 1)

    obj_name = Constants.ObjectNameRoomAirConditioner

    # _processSystemRoomAC

    clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, roomac_cap_ft_curve, roomac_cap_fff_curve, roomac_eir_ft_curve, roomcac_eir_fff_curve, roomac_plf_fplr_curve)
    clg_coil.setName(obj_name + " #{control_zone.name} clg coil")
    if capacity != Constants.SizingAuto
      clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert([capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    clg_coil.setRatedSensibleHeatRatio(shr)
    clg_coil.setRatedCOP(UnitConversions.convert(eer, "Btu/hr", "W"))
    clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(773.3)
    clg_coil.setEvaporativeCondenserEffectiveness(0.9)
    clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(10)
    clg_coil.setBasinHeaterSetpointTemperature(2)
    hvac_map[sys_id] << clg_coil

    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
    fan.setName(obj_name + " #{control_zone.name} supply fan")
    fan.setEndUseSubcategory("supply fan")
    fan.setFanEfficiency(1)
    fan.setPressureRise(0)
    fan.setMotorEfficiency(1)
    fan.setMotorInAirstreamFraction(0)
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [], [clg_coil])

    htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOffDiscreteSchedule())
    htg_coil.setName(obj_name + " #{control_zone.name} htg coil")

    ptac = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new(model, model.alwaysOnDiscreteSchedule, fan, htg_coil, clg_coil)
    ptac.setName(obj_name + " #{control_zone.name}")
    ptac.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    ptac.addToThermalZone(control_zone)
    runner.registerInfo("Added '#{ptac.name}' to '#{control_zone.name}'")
    hvac_map[sys_id] << ptac

    control_zone.setSequentialCoolingFractionSchedule(ptac, get_constant_schedule(model, sequential_cool_load_frac.round(5)))
    control_zone.setSequentialHeatingFractionSchedule(ptac, get_constant_schedule(model, 0))

    # Store info for HVAC Sizing measure
    ptac.additionalProperties.setFeature(Constants.SizingInfoHVACCoolingCFMs, airflow_rate.to_s)
    ptac.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cfms_ton_rated.join(","))
    ptac.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, frac_cool_load_served)
    ptac.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameRoomAirConditioner)

    return true
  end

  def self.apply_furnace(model, runner, fuel_type, afue,
                         capacity, fan_power_installed,
                         frac_heat_load_served, sequential_heat_load_frac,
                         attached_cooling_system, control_zone,
                         hvac_map, sys_id)

    # _processAirSystem

    obj_name = Constants.ObjectNameFurnace

    # _processSystemHeatingCoil

    if fuel_type == Constants.FuelTypeElectric
      htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model)
      htg_coil.setEfficiency(afue)
    else
      htg_coil = OpenStudio::Model::CoilHeatingGas.new(model)
      htg_coil.setGasBurnerEfficiency(afue)
      htg_coil.setParasiticElectricLoad(0)
      htg_coil.setParasiticGasLoad(0)
      htg_coil.setFuelType(HelperMethods.eplus_fuel_map(fuel_type))
    end
    htg_coil.setName(obj_name + " htg coil")
    if capacity != Constants.SizingAuto
      htg_coil.setNominalCapacity(UnitConversions.convert([capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    hvac_map[sys_id] << htg_coil

    if attached_cooling_system.nil?
      # _processSystemFan

      fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
      fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
      fan.setName(obj_name + " supply fan")
      fan.setEndUseSubcategory("supply fan")
      fan.setFanEfficiency(fan_eff)
      fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_power_installed))
      fan.setMotorEfficiency(1.0)
      fan.setMotorInAirstreamFraction(1.0)
      hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [htg_coil], [])

      # _processSystemAir

      air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
      air_loop_unitary.setName(obj_name + " unitary system")
      air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
      air_loop_unitary.setHeatingCoil(htg_coil)
      air_loop_unitary.setSupplyAirFlowRateDuringCoolingOperation(0.0)
      air_loop_unitary.setSupplyFan(fan)
      air_loop_unitary.setFanPlacement("BlowThrough")
      air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
      air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(120.0, "F", "C"))
      air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
      hvac_map[sys_id] << air_loop_unitary

      air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
      air_loop.setName(obj_name + " airloop")
      air_supply_inlet_node = air_loop.supplyInletNode
      air_supply_outlet_node = air_loop.supplyOutletNode
      air_demand_inlet_node = air_loop.demandInletNode
      air_demand_outlet_node = air_loop.demandOutletNode
      hvac_map[sys_id] << air_loop

      air_loop_unitary.addToNode(air_supply_inlet_node)

      runner.registerInfo("Added '#{fan.name}' to '#{air_loop_unitary.name}'")
      runner.registerInfo("Added '#{htg_coil.name}' to '#{air_loop_unitary.name}'")

      air_loop_unitary.setControllingZoneorThermostatLocation(control_zone)

      # _processSystemDemandSideAir
      # Demand Side

      # Supply Air
      zone_splitter = air_loop.zoneSplitter
      zone_splitter.setName(obj_name + " zone splitter")

      zone_mixer = air_loop.zoneMixer
      zone_mixer.setName(obj_name + " zone mixer")

      air_terminal_living = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
      air_terminal_living.setName(obj_name + " #{control_zone.name} terminal")
      air_loop.multiAddBranchForZone(control_zone, air_terminal_living)
      runner.registerInfo("Added '#{air_loop.name}' to '#{control_zone.name}'")

      control_zone.setSequentialHeatingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_heat_load_frac.round(5)))
      control_zone.setSequentialCoolingFractionSchedule(air_terminal_living, get_constant_schedule(model, 0))

      air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, frac_heat_load_served)
      air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameFurnace)
    else
      # Attach to existing cooling unitary system
      obj_name = Constants.ObjectNameCentralAirConditionerAndFurnace

      fan = attached_cooling_system.supplyFan.get.to_FanOnOff.get
      fan.setName(obj_name + " supply fan")

      # Remove old disaggregation program
      attached_clg_sys_id = nil
      hvac_map.each do |clg_sys_id, clg_objects|
        clg_objects.each do |clg_object|
          next unless clg_object == attached_cooling_system

          attached_clg_sys_id = clg_sys_id
        end
      end
      hvac_map[attached_clg_sys_id].dup.each do |clg_object|
        if clg_object.is_a? OpenStudio::Model::EnergyManagementSystemSensor or
           clg_object.is_a? OpenStudio::Model::EnergyManagementSystemProgram or
           clg_object.is_a? OpenStudio::Model::EnergyManagementSystemProgramCallingManager or
           clg_object.is_a? OpenStudio::Model::EnergyManagementSystemOutputVariable
          clg_object.remove
          hvac_map[attached_clg_sys_id].delete clg_object
        end
      end

      # Add new disaggregation program
      ems_fan_objects = self.disaggregate_fan_or_pump(model, fan, [htg_coil], [attached_cooling_system.coolingCoil.get])
      hvac_map[sys_id] += ems_fan_objects
      hvac_map[attached_clg_sys_id] += ems_fan_objects

      attached_cooling_system.setHeatingCoil(htg_coil)
      attached_cooling_system.setName(obj_name + " unitary system")
      hvac_map[sys_id] << attached_cooling_system

      air_loop = attached_cooling_system.airLoopHVAC.get
      air_loop.setName(obj_name + " airloop")
      hvac_map[sys_id] << air_loop

      runner.registerInfo("Added '#{htg_coil.name}' to '#{attached_cooling_system.name}'")

      zone_splitter = air_loop.zoneSplitter
      zone_splitter.setName(obj_name + " zone splitter")

      zone_mixer = air_loop.zoneMixer
      zone_mixer.setName(obj_name + " zone mixer")

      control_zone.airLoopHVACTerminals.each do |air_terminal_living|
        next unless air_terminal_living.airLoopHVAC.get == air_loop

        air_terminal_living.setName(obj_name + " #{control_zone.name} terminal")
        control_zone.setSequentialHeatingFractionSchedule(air_terminal_living, get_constant_schedule(model, sequential_heat_load_frac.round(5)))
      end

      attached_cooling_system.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, frac_heat_load_served)
      attached_cooling_system.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameFurnace)
    end

    return true
  end

  def self.apply_boiler(model, runner, fuel_type, system_type, afue,
                        oat_reset_enabled, oat_high, oat_low, oat_hwst_high, oat_hwst_low,
                        capacity, design_temp, frac_heat_load_served,
                        sequential_heat_load_frac, control_zone,
                        hvac_map, sys_id)

    # _processHydronicSystem

    if system_type == Constants.BoilerTypeSteam
      runner.registerError("Cannot currently model steam boilers.")
      return false
    end

    if oat_reset_enabled
      if oat_high.nil? or oat_low.nil? or oat_hwst_low.nil? or oat_hwst_high.nil?
        runner.registerWarning("Boiler outdoor air temperature (OAT) reset is enabled but no setpoints were specified so OAT reset is being disabled.")
        oat_reset_enabled = false
      end
    end

    # _processCurvesBoiler

    boiler_eff_curve = get_boiler_curve(model, system_type == Constants.BoilerTypeCondensing)

    obj_name = Constants.ObjectNameBoiler

    # _processSystemHydronic

    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName(obj_name + " hydronic heat loop")
    plant_loop.setFluidType("Water")
    plant_loop.setMaximumLoopTemperature(100)
    plant_loop.setMinimumLoopTemperature(0)
    plant_loop.setMinimumLoopFlowRate(0)
    plant_loop.autocalculatePlantLoopVolume()
    runner.registerInfo("Added '#{plant_loop.name}' to model.")
    hvac_map[sys_id] << plant_loop

    loop_sizing = plant_loop.sizingPlant
    loop_sizing.setLoopType("Heating")
    loop_sizing.setDesignLoopExitTemperature(UnitConversions.convert(design_temp - 32.0, "R", "K"))
    loop_sizing.setLoopDesignTemperatureDifference(UnitConversions.convert(20.0, "R", "K"))

    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setName(obj_name + " hydronic pump")
    pump.setRatedPumpHead(20000)
    pump.setMotorEfficiency(0.9)
    pump.setFractionofMotorInefficienciestoFluidStream(0)
    pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
    pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
    pump.setPumpControlType("Intermittent")
    hvac_map[sys_id] << pump

    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setName(obj_name)
    boiler.setFuelType(HelperMethods.eplus_fuel_map(fuel_type))
    if capacity != Constants.SizingAuto
      boiler.setNominalCapacity(UnitConversions.convert([capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    if system_type == Constants.BoilerTypeCondensing
      # Convert Rated Efficiency at 80F and 1.0PLR where the performance curves are derived from to Design condition as input
      boiler_RatedHWRT = UnitConversions.convert(80.0 - 32.0, "R", "K")
      plr_Rated = 1.0
      plr_Design = 1.0
      boiler_DesignHWRT = UnitConversions.convert(design_temp - 20.0 - 32.0, "R", "K")
      # Efficiency curves are normalized using 80F return water temperature, at 0.254PLR
      condBlr_TE_Coeff = [1.058343061, 0.052650153, 0.0087272, 0.001742217, 0.00000333715, 0.000513723]
      boilerEff_Norm = afue / (condBlr_TE_Coeff[0] - condBlr_TE_Coeff[1] * plr_Rated - condBlr_TE_Coeff[2] * plr_Rated**2 - condBlr_TE_Coeff[3] * boiler_RatedHWRT + condBlr_TE_Coeff[4] * boiler_RatedHWRT**2 + condBlr_TE_Coeff[5] * boiler_RatedHWRT * plr_Rated)
      boilerEff_Design = boilerEff_Norm * (condBlr_TE_Coeff[0] - condBlr_TE_Coeff[1] * plr_Design - condBlr_TE_Coeff[2] * plr_Design**2 - condBlr_TE_Coeff[3] * boiler_DesignHWRT + condBlr_TE_Coeff[4] * boiler_DesignHWRT**2 + condBlr_TE_Coeff[5] * boiler_DesignHWRT * plr_Design)
      boiler.setNominalThermalEfficiency(boilerEff_Design)
      boiler.setEfficiencyCurveTemperatureEvaluationVariable("EnteringBoiler")
    else
      boiler.setNominalThermalEfficiency(afue)
      boiler.setEfficiencyCurveTemperatureEvaluationVariable("LeavingBoiler")
    end
    boiler.setNormalizedBoilerEfficiencyCurve(boiler_eff_curve)
    boiler.setDesignWaterOutletTemperature(UnitConversions.convert(design_temp - 32.0, "R", "K"))
    boiler.setMinimumPartLoadRatio(0.0)
    boiler.setMaximumPartLoadRatio(1.0)
    boiler.setBoilerFlowMode("LeavingSetpointModulated")
    boiler.setOptimumPartLoadRatio(1.0)
    boiler.setWaterOutletUpperTemperatureLimit(99.9)
    boiler.setParasiticElectricLoad(0)
    hvac_map[sys_id] << boiler

    if system_type == Constants.BoilerTypeCondensing and oat_reset_enabled
      setpoint_manager_oar = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
      setpoint_manager_oar.setName(obj_name + " outdoor reset")
      setpoint_manager_oar.setControlVariable("Temperature")
      setpoint_manager_oar.setSetpointatOutdoorLowTemperature(UnitConversions.convert(oat_hwst_low, "F", "C"))
      setpoint_manager_oar.setOutdoorLowTemperature(UnitConversions.convert(oat_low, "F", "C"))
      setpoint_manager_oar.setSetpointatOutdoorHighTemperature(UnitConversions.convert(oat_hwst_high, "F", "C"))
      setpoint_manager_oar.setOutdoorHighTemperature(UnitConversions.convert(oat_high, "F", "C"))
      setpoint_manager_oar.addToNode(plant_loop.supplyOutletNode)
    end

    hydronic_heat_supply_setpoint = OpenStudio::Model::ScheduleConstant.new(model)
    hydronic_heat_supply_setpoint.setName(obj_name + " hydronic heat supply setpoint")
    hydronic_heat_supply_setpoint.setValue(UnitConversions.convert(design_temp, "F", "C"))

    setpoint_manager_scheduled = OpenStudio::Model::SetpointManagerScheduled.new(model, hydronic_heat_supply_setpoint)
    setpoint_manager_scheduled.setName(obj_name + " hydronic heat loop setpoint manager")
    setpoint_manager_scheduled.setControlVariable("Temperature")

    pipe_supply_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_supply_outlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_inlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_outlet = OpenStudio::Model::PipeAdiabatic.new(model)

    plant_loop.addSupplyBranchForComponent(boiler)
    plant_loop.addSupplyBranchForComponent(pipe_supply_bypass)
    pump.addToNode(plant_loop.supplyInletNode)
    pipe_supply_outlet.addToNode(plant_loop.supplyOutletNode)
    setpoint_manager_scheduled.addToNode(plant_loop.supplyOutletNode)
    plant_loop.addDemandBranchForComponent(pipe_demand_bypass)
    pipe_demand_inlet.addToNode(plant_loop.demandInletNode)
    pipe_demand_outlet.addToNode(plant_loop.demandOutletNode)

    baseboard_coil = OpenStudio::Model::CoilHeatingWaterBaseboard.new(model)
    baseboard_coil.setName(obj_name + " #{control_zone.name} htg coil")
    if capacity != Constants.SizingAuto
      baseboard_coil.setHeatingDesignCapacity(UnitConversions.convert([capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    baseboard_coil.setConvergenceTolerance(0.001)
    hvac_map[sys_id] << baseboard_coil

    baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model, model.alwaysOnDiscreteSchedule, baseboard_coil)
    baseboard_heater.setName(obj_name + " #{control_zone.name}")
    baseboard_heater.addToThermalZone(control_zone)
    runner.registerInfo("Added '#{baseboard_heater.name}' to '#{control_zone.name}'")
    hvac_map[sys_id] << baseboard_heater

    plant_loop.addDemandBranchForComponent(baseboard_coil)

    control_zone.setSequentialHeatingFractionSchedule(baseboard_heater, get_constant_schedule(model, sequential_heat_load_frac.round(5)))
    control_zone.setSequentialCoolingFractionSchedule(baseboard_heater, get_constant_schedule(model, 0))

    # Store info for HVAC Sizing measure
    baseboard_heater.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, frac_heat_load_served)
    baseboard_heater.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameBoiler)

    htg_objects = []
    hvac_map[sys_id].each do |hvac_object|
      if hvac_object.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater
        htg_objects << hvac_object
      end
    end
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, pump, htg_objects, [])

    return true
  end

  def self.apply_electric_baseboard(model, runner, efficiency, capacity,
                                    frac_heat_load_served, sequential_heat_load_frac,
                                    control_zone, hvac_map, sys_id)

    obj_name = Constants.ObjectNameElectricBaseboard

    baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
    baseboard_heater.setName(obj_name + " #{control_zone.name}")
    if capacity != Constants.SizingAuto
      baseboard_heater.setNominalCapacity(UnitConversions.convert([capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    baseboard_heater.setEfficiency(efficiency)
    hvac_map[sys_id] << baseboard_heater

    baseboard_heater.addToThermalZone(control_zone)
    runner.registerInfo("Added '#{baseboard_heater.name}' to '#{control_zone.name}'")

    control_zone.setSequentialHeatingFractionSchedule(baseboard_heater, get_constant_schedule(model, sequential_heat_load_frac.round(5)))
    control_zone.setSequentialCoolingFractionSchedule(baseboard_heater, get_constant_schedule(model, 0))

    # Store info for HVAC Sizing measure
    baseboard_heater.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, frac_heat_load_served)
    baseboard_heater.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameElectricBaseboard)

    return true
  end

  def self.apply_unit_heater(model, runner, fuel_type,
                             efficiency, capacity, fan_power,
                             airflow_rate, frac_heat_load_served,
                             sequential_heat_load_frac, control_zone,
                             hvac_map, sys_id)

    if fan_power > 0 and airflow_rate == 0
      runner.registerError("If Fan Power > 0, then Airflow Rate cannot be zero.")
      return false
    end

    obj_name = Constants.ObjectNameUnitHeater

    # _processSystemHeatingCoil

    if fuel_type == Constants.FuelTypeElectric
      htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model)
      htg_coil.setEfficiency(efficiency)
    else
      htg_coil = OpenStudio::Model::CoilHeatingGas.new(model)
      htg_coil.setGasBurnerEfficiency(efficiency)
      htg_coil.setParasiticElectricLoad(0.0)
      htg_coil.setParasiticGasLoad(0)
      htg_coil.setFuelType(HelperMethods.eplus_fuel_map(fuel_type))
    end
    htg_coil.setName(obj_name + " #{control_zone.name} htg coil")
    if capacity != Constants.SizingAuto
      htg_coil.setNominalCapacity(UnitConversions.convert([capacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
    end
    hvac_map[sys_id] << htg_coil

    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
    fan.setName(obj_name + " #{control_zone.name} supply fan")
    fan.setEndUseSubcategory("supply fan")
    if fan_power > 0
      fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
      fan.setFanEfficiency(fan_eff)
      fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_power))
    else
      fan.setFanEfficiency(1)
      fan.setPressureRise(0)
    end
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    hvac_map[sys_id] += self.disaggregate_fan_or_pump(model, fan, [htg_coil], [])

    # _processSystemAir

    unitary_system = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    unitary_system.setName(obj_name + " #{control_zone.name} unitary system")
    unitary_system.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    unitary_system.setHeatingCoil(htg_coil)
    unitary_system.setSupplyAirFlowRateMethodDuringCoolingOperation("SupplyAirFlowRate")
    unitary_system.setSupplyAirFlowRateDuringCoolingOperation(0.0)
    unitary_system.setSupplyFan(fan)
    unitary_system.setFanPlacement("BlowThrough")
    unitary_system.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    unitary_system.setMaximumSupplyAirTemperature(UnitConversions.convert(120.0, "F", "C"))
    unitary_system.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    hvac_map[sys_id] << unitary_system

    runner.registerInfo("Added '#{fan.name}' to '#{unitary_system.name}''")
    runner.registerInfo("Added '#{htg_coil.name}' to '#{unitary_system.name}'")

    unitary_system.setControllingZoneorThermostatLocation(control_zone)
    unitary_system.addToThermalZone(control_zone)

    control_zone.setSequentialHeatingFractionSchedule(unitary_system, get_constant_schedule(model, sequential_heat_load_frac.round(5)))
    control_zone.setSequentialCoolingFractionSchedule(unitary_system, get_constant_schedule(model, 0))

    # Store info for HVAC Sizing measure
    unitary_system.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonHeating, airflow_rate.to_s)
    unitary_system.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, frac_heat_load_served)
    unitary_system.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameUnitHeater)

    return true
  end

  def self.apply_ideal_air_loads(model, runner, sequential_cool_load_frac, sequential_heat_load_frac,
                                 control_zone)

    obj_name = Constants.ObjectNameIdealAirSystem

    ideal_air = OpenStudio::Model::ZoneHVACIdealLoadsAirSystem.new(model)
    ideal_air.setName(obj_name)
    ideal_air.setMaximumHeatingSupplyAirTemperature(50)
    ideal_air.setMinimumCoolingSupplyAirTemperature(10)
    ideal_air.setMaximumHeatingSupplyAirHumidityRatio(0.015)
    ideal_air.setMinimumCoolingSupplyAirHumidityRatio(0.01)
    ideal_air.setHeatingLimit('NoLimit')
    ideal_air.setCoolingLimit('NoLimit')
    ideal_air.setDehumidificationControlType('None')
    ideal_air.setHumidificationControlType('None')
    ideal_air.addToThermalZone(control_zone)

    control_zone.setSequentialCoolingFractionSchedule(ideal_air, get_constant_schedule(model, sequential_cool_load_frac.round(5)))
    control_zone.setSequentialHeatingFractionSchedule(ideal_air, get_constant_schedule(model, sequential_heat_load_frac.round(5)))

    # Store info for HVAC Sizing measure
    ideal_air.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameIdealAirSystem)
    ideal_air.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameIdealAirSystem)

    return true
  end

  def self.disaggregate_fan_or_pump(model, fan_or_pump, htg_objects, clg_objects)
    # Disaggregate into heating/cooling output energy use.

    hvac_objects = []

    if fan_or_pump.is_a? OpenStudio::Model::FanOnOff
      fan_or_pump_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Fan Electric Energy')
    elsif fan_or_pump.is_a? OpenStudio::Model::PumpVariableSpeed
      fan_or_pump_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Pump Electric Energy')
    else
      fail "Unexpected fan/pump object '#{fan_or_pump.name}'."
    end
    fan_or_pump_sensor.setName("#{fan_or_pump.name} s")
    fan_or_pump_sensor.setKeyName(fan_or_pump.name.to_s)
    hvac_objects << fan_or_pump_sensor

    clg_object_sensors = []
    clg_objects.each do |clg_object|
      clg_object_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling Coil Electric Energy")
      clg_object_sensor.setName("#{clg_object.name} s")
      clg_object_sensor.setKeyName(clg_object.name.to_s)
      clg_object_sensors << clg_object_sensor
      hvac_objects << clg_object_sensor
    end

    htg_object_sensors = []
    htg_objects.each do |htg_object|
      var = 'Heating Coil Electric Energy'
      if htg_object.is_a? OpenStudio::Model::CoilHeatingGas
        var = { 'NaturalGas' => 'Heating Coil Gas Energy',
                'PropaneGas' => 'Heating Coil Propane Energy',
                'FuelOil#1' => 'Heating Coil FuelOil#1 Energy',
                'OtherFuel1' => 'Heating Coil OtherFuel1 Energy',
                'OtherFuel2' => 'Heating Coil OtherFuel2 Energy' }[htg_object.fuelType]
        fail "Unexpected heating coil '#{htg_object.name}'." if var.nil?
      elsif htg_object.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater
        var = 'Baseboard Total Heating Energy'
      end

      htg_object_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
      htg_object_sensor.setName("#{htg_object.name} s")
      htg_object_sensor.setKeyName(htg_object.name.to_s)
      htg_object_sensors << htg_object_sensor
      hvac_objects << htg_object_sensor
    end

    all_sensors = { "cool" => clg_object_sensors,
                    "heat" => htg_object_sensors }

    fan_or_pump_var = fan_or_pump.name.to_s.gsub(' ', '_')

    # Disaggregate electric fan/pump energy
    fan_or_pump_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    fan_or_pump_program.setName("#{fan_or_pump_var} disaggregate program")
    fan_or_pump_program.addLine("Set #{fan_or_pump_var}_heat = 0") unless htg_objects.empty?
    fan_or_pump_program.addLine("Set #{fan_or_pump_var}_cool = 0") unless clg_objects.empty?
    i = 0
    all_sensors.each do |heat_or_cool, sensors|
      next if sensors.empty?

      sum_of_sensors = sensors.map { |sensor| sensor.name }.join(" + ")
      if i == 0
        fan_or_pump_program.addLine("If #{sum_of_sensors} > 0")
      else
        fan_or_pump_program.addLine("ElseIf #{sum_of_sensors} > 0")
      end
      fan_or_pump_program.addLine("  Set #{fan_or_pump_var}_#{heat_or_cool} = #{fan_or_pump_sensor.name}")
      i += 1
    end
    fan_or_pump_program.addLine("EndIf")
    hvac_objects << fan_or_pump_program

    fan_or_pump_program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    fan_or_pump_program_calling_manager.setName("#{fan_or_pump.name} disaggregate program calling manager")
    fan_or_pump_program_calling_manager.setCallingPoint("EndOfSystemTimestepBeforeHVACReporting")
    fan_or_pump_program_calling_manager.addProgram(fan_or_pump_program)
    hvac_objects << fan_or_pump_program_calling_manager

    if not htg_objects.empty?
      fan_or_pump_ems_output_var_heat = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "#{fan_or_pump_var}_heat")
      fan_or_pump_ems_output_var_heat.setName(Constants.ObjectNameFanPumpDisaggregate(false, fan_or_pump.name.to_s))
      fan_or_pump_ems_output_var_heat.setTypeOfDataInVariable("Summed")
      fan_or_pump_ems_output_var_heat.setUpdateFrequency("SystemTimestep")
      fan_or_pump_ems_output_var_heat.setEMSProgramOrSubroutineName(fan_or_pump_program)
      fan_or_pump_ems_output_var_heat.setUnits("J")
      hvac_objects << fan_or_pump_ems_output_var_heat

      outputVariable = OpenStudio::Model::OutputVariable.new(fan_or_pump_ems_output_var_heat.name.to_s, model)
      outputVariable.setReportingFrequency('monthly')
      outputVariable.setKeyValue('*')
    end

    if not clg_objects.empty?
      fan_or_pump_ems_output_var_cool = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "#{fan_or_pump_var}_cool")
      fan_or_pump_ems_output_var_cool.setName(Constants.ObjectNameFanPumpDisaggregate(true, fan_or_pump.name.to_s))
      fan_or_pump_ems_output_var_cool.setTypeOfDataInVariable("Summed")
      fan_or_pump_ems_output_var_cool.setUpdateFrequency("SystemTimestep")
      fan_or_pump_ems_output_var_cool.setEMSProgramOrSubroutineName(fan_or_pump_program)
      fan_or_pump_ems_output_var_cool.setUnits("J")
      hvac_objects << fan_or_pump_ems_output_var_cool

      outputVariable = OpenStudio::Model::OutputVariable.new(fan_or_pump_ems_output_var_cool.name.to_s, model)
      outputVariable.setReportingFrequency('monthly')
      outputVariable.setKeyValue('*')
    end

    return hvac_objects
  end

  def self.apply_heating_setpoints(model, runner, weather, htg_wkdy_monthly, htg_wked_monthly,
                                   use_auto_season, season_start_month, season_end_month,
                                   living_zone)

    # Get heating season
    if use_auto_season
      heating_season, _ = calc_heating_and_cooling_seasons(model, weather, runner)
    else
      if season_start_month <= season_end_month
        heating_season = Array.new(season_start_month - 1, 0) + Array.new(season_end_month - season_start_month + 1, 1) + Array.new(12 - season_end_month, 0)
      elsif season_start_month > season_end_month
        heating_season = Array.new(season_end_month, 1) + Array.new(season_start_month - season_end_month - 1, 0) + Array.new(12 - season_start_month + 1, 1)
      end
    end
    if heating_season.nil?
      return false
    end

    cooling_season = get_season(model, weather, runner, Constants.ObjectNameCoolingSeason)

    heating_season_sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameHeatingSeason, Array.new(24, 1), Array.new(24, 1), heating_season, mult_weekday = 1.0, mult_weekend = 1.0, normalize_values = false, create_sch_object = true, schedule_type_limits_name = Constants.ScheduleTypeLimitsOnOff)
    unless heating_season_sch.validated?
      return false
    end

    htg_wkdy_monthly = htg_wkdy_monthly.map { |i| i.map { |j| UnitConversions.convert(j, "F", "C") } }
    htg_wked_monthly = htg_wked_monthly.map { |i| i.map { |j| UnitConversions.convert(j, "F", "C") } }

    # Make the setpoint schedules
    clg_wkdy_monthly = nil
    clg_wked_monthly = nil
    thermostat_setpoint = living_zone.thermostatSetpointDualSetpoint
    if thermostat_setpoint.is_initialized

      thermostat_setpoint = thermostat_setpoint.get
      runner.registerInfo("Found existing thermostat #{thermostat_setpoint.name} for #{living_zone.name}.")

      clg_wkdy_monthly = get_setpoint_schedule(thermostat_setpoint.coolingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get, 'weekday', runner)
      clg_wked_monthly = get_setpoint_schedule(thermostat_setpoint.coolingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get, 'weekend', runner)
      if clg_wkdy_monthly.nil? or clg_wked_monthly.nil?
        return false
      end

      if not clg_wkdy_monthly.uniq.length == 1 or not clg_wked_monthly.uniq.length == 1
        runner.registerError("Found monthly variation in cooling setpoint schedule.")
        return false
      end

      model.getScheduleRulesets.each do |sch|
        next unless sch.name.to_s == Constants.ObjectNameCoolingSetpoint

        sch.remove
      end
    else # no thermostat in model yet

      clg_wkdy_monthly = [[UnitConversions.convert(Constants.DefaultCoolingSetpoint, "F", "C")] * 24] * 12
      clg_wked_monthly = [[UnitConversions.convert(Constants.DefaultCoolingSetpoint, "F", "C")] * 24] * 12

    end

    (0..11).to_a.each do |i|
      if heating_season[i] == 1 and cooling_season[i] == 1 # overlap seasons
        htg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? (h + c) / 2.0 : h }
        htg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? (h + c) / 2.0 : h }
        clg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? (h + c) / 2.0 : c }
        clg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? (h + c) / 2.0 : c }
      elsif heating_season[i] == 1 # heating only seasons; cooling has minimum of heating
        htg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? h : h }
        htg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? h : h }
        clg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? h : c }
        clg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? h : c }
      elsif cooling_season[i] == 1 # cooling only seasons; heating has maximum of cooling
        htg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? c : h }
        htg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? c : h }
        clg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? c : c }
        clg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? c : c }
      else
        htg_wkdy = [UnitConversions.convert(Constants.DefaultHeatingSetpoint, "F", "C")] * 24
        htg_wked = [UnitConversions.convert(Constants.DefaultHeatingSetpoint, "F", "C")] * 24
        clg_wkdy = [UnitConversions.convert(Constants.DefaultCoolingSetpoint, "F", "C")] * 24
        clg_wked = [UnitConversions.convert(Constants.DefaultCoolingSetpoint, "F", "C")] * 24
      end
      htg_wkdy_monthly[i] = htg_wkdy
      htg_wked_monthly[i] = htg_wked
      clg_wkdy_monthly[i] = clg_wkdy
      clg_wked_monthly[i] = clg_wked
    end

    heating_setpoint = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameHeatingSetpoint, htg_wkdy_monthly, htg_wked_monthly, normalize_values = false)
    cooling_setpoint = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameCoolingSetpoint, clg_wkdy_monthly, clg_wked_monthly, normalize_values = false)

    unless heating_setpoint.validated? and cooling_setpoint.validated?
      return false
    end

    # Set the setpoint schedules
    thermostat_setpoint = living_zone.thermostatSetpointDualSetpoint
    if thermostat_setpoint.is_initialized

      thermostat_setpoint = thermostat_setpoint.get
      thermostat_setpoint.setHeatingSetpointTemperatureSchedule(heating_setpoint.schedule)
      thermostat_setpoint.setCoolingSetpointTemperatureSchedule(cooling_setpoint.schedule)

    else

      thermostat_setpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
      thermostat_setpoint.setName("#{living_zone.name} temperature setpoint")
      runner.registerInfo("Created new thermostat #{thermostat_setpoint.name} for #{living_zone.name}.")
      thermostat_setpoint.setHeatingSetpointTemperatureSchedule(heating_setpoint.schedule)
      thermostat_setpoint.setCoolingSetpointTemperatureSchedule(cooling_setpoint.schedule)
      living_zone.setThermostatSetpointDualSetpoint(thermostat_setpoint)
      runner.registerInfo("Set a dummy cooling setpoint schedule for #{thermostat_setpoint.name}.")

    end

    runner.registerInfo("Set the heating setpoint schedule for #{thermostat_setpoint.name}.")

    model.getScheduleDays.each do |obj| # remove orphaned summer and winter design day schedules
      next if obj.directUseCount > 0

      obj.remove
    end

    return true
  end

  def self.apply_cooling_setpoints(model, runner, weather, clg_wkdy_monthly, clg_wked_monthly,
                                   use_auto_season, season_start_month, season_end_month,
                                   living_zone)

    # Get cooling season
    if use_auto_season
      _, cooling_season = calc_heating_and_cooling_seasons(model, weather, runner)
    else
      if season_start_month <= season_end_month
        cooling_season = Array.new(season_start_month - 1, 0) + Array.new(season_end_month - season_start_month + 1, 1) + Array.new(12 - season_end_month, 0)
      elsif season_start_month > season_end_month
        cooling_season = Array.new(season_end_month, 1) + Array.new(season_start_month - season_end_month - 1, 0) + Array.new(12 - season_start_month + 1, 1)
      end
    end
    if cooling_season.nil?
      return false
    end

    heating_season = get_season(model, weather, runner, Constants.ObjectNameHeatingSeason)

    cooling_season_sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameCoolingSeason, Array.new(24, 1), Array.new(24, 1), cooling_season, mult_weekday = 1.0, mult_weekend = 1.0, normalize_values = false, create_sch_object = true, schedule_type_limits_name = Constants.ScheduleTypeLimitsOnOff)
    unless cooling_season_sch.validated?
      return false
    end

    clg_wkdy_monthly = clg_wkdy_monthly.map { |i| i.map { |j| UnitConversions.convert(j, "F", "C") } }
    clg_wked_monthly = clg_wked_monthly.map { |i| i.map { |j| UnitConversions.convert(j, "F", "C") } }

    # Make the setpoint schedules
    htg_wkdy_monthly = nil
    htg_wked_monthly = nil
    thermostat_setpoint = living_zone.thermostatSetpointDualSetpoint
    if thermostat_setpoint.is_initialized

      thermostat_setpoint = thermostat_setpoint.get
      runner.registerInfo("Found existing thermostat #{thermostat_setpoint.name} for #{living_zone.name}.")

      htg_wkdy_monthly = get_setpoint_schedule(thermostat_setpoint.heatingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get, 'weekday', runner)
      htg_wked_monthly = get_setpoint_schedule(thermostat_setpoint.heatingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get, 'weekend', runner)
      if htg_wkdy_monthly.nil? or htg_wked_monthly.nil?
        return false
      end

      if not htg_wkdy_monthly.uniq.length == 1 or not htg_wked_monthly.uniq.length == 1
        runner.registerError("Found monthly variation in heating setpoint schedule.")
        return false
      end

      model.getScheduleRulesets.each do |sch|
        next unless sch.name.to_s == Constants.ObjectNameHeatingSetpoint

        sch.remove
      end
    else # no thermostat in model yet

      htg_wkdy_monthly = [[UnitConversions.convert(Constants.DefaultHeatingSetpoint, "F", "C")] * 24] * 12
      htg_wked_monthly = [[UnitConversions.convert(Constants.DefaultHeatingSetpoint, "F", "C")] * 24] * 12

    end

    (0..11).to_a.each do |i|
      if heating_season[i] == 1 and cooling_season[i] == 1 # overlap seasons
        htg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? (h + c) / 2.0 : h }
        htg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? (h + c) / 2.0 : h }
        clg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? (h + c) / 2.0 : c }
        clg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? (h + c) / 2.0 : c }
      elsif heating_season[i] == 1 # heating only seasons; cooling has minimum of heating
        htg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? h : h }
        htg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? h : h }
        clg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? h : c }
        clg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? h : c }
      elsif cooling_season[i] == 1 # cooling only seasons; heating has maximum of cooling
        htg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? c : h }
        htg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? c : h }
        clg_wkdy = htg_wkdy_monthly[i].zip(clg_wkdy_monthly[i]).map { |h, c| c < h ? c : c }
        clg_wked = htg_wked_monthly[i].zip(clg_wked_monthly[i]).map { |h, c| c < h ? c : c }
      else
        htg_wkdy = [UnitConversions.convert(Constants.DefaultHeatingSetpoint, "F", "C")] * 24
        htg_wked = [UnitConversions.convert(Constants.DefaultHeatingSetpoint, "F", "C")] * 24
        clg_wkdy = [UnitConversions.convert(Constants.DefaultCoolingSetpoint, "F", "C")] * 24
        clg_wked = [UnitConversions.convert(Constants.DefaultCoolingSetpoint, "F", "C")] * 24
      end
      htg_wkdy_monthly[i] = htg_wkdy
      htg_wked_monthly[i] = htg_wked
      clg_wkdy_monthly[i] = clg_wkdy
      clg_wked_monthly[i] = clg_wked
    end

    heating_setpoint = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameHeatingSetpoint, htg_wkdy_monthly, htg_wked_monthly, normalize_values = false)
    cooling_setpoint = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameCoolingSetpoint, clg_wkdy_monthly, clg_wked_monthly, normalize_values = false)

    unless heating_setpoint.validated? and cooling_setpoint.validated?
      return false
    end

    # Set the setpoint schedules
    thermostat_setpoint = living_zone.thermostatSetpointDualSetpoint
    if thermostat_setpoint.is_initialized

      thermostat_setpoint = thermostat_setpoint.get
      thermostat_setpoint.setHeatingSetpointTemperatureSchedule(heating_setpoint.schedule)
      thermostat_setpoint.setCoolingSetpointTemperatureSchedule(cooling_setpoint.schedule)

    else

      thermostat_setpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
      thermostat_setpoint.setName("#{living_zone.name} temperature setpoint")
      runner.registerInfo("Created new thermostat #{thermostat_setpoint.name} for #{living_zone.name}.")
      thermostat_setpoint.setHeatingSetpointTemperatureSchedule(heating_setpoint.schedule)
      thermostat_setpoint.setCoolingSetpointTemperatureSchedule(cooling_setpoint.schedule)
      living_zone.setThermostatSetpointDualSetpoint(thermostat_setpoint)
      runner.registerInfo("Set a dummy heating setpoint schedule for #{thermostat_setpoint.name}.")

    end

    runner.registerInfo("Set the cooling setpoint schedule for #{thermostat_setpoint.name}.")

    model.getScheduleDays.each do |obj| # remove orphaned summer and winter design day schedules
      next if obj.directUseCount > 0

      obj.remove
    end

    return true
  end

  def self.get_setpoint_schedule(schedule_ruleset, weekday_or_weekend, runner)
    setpoint_schedule = [[0] * 24] * 12
    schedule_ruleset.scheduleRules.each do |rule|
      month = rule.startDate.get.monthOfYear.value.to_i - 1
      next unless weekday_or_weekend_rule(rule).include? weekday_or_weekend

      rule.daySchedule.values.each_with_index do |value, i|
        hour = rule.daySchedule.times[i].hours - 1
        setpoint_schedule[month][hour] = value
      end
      setpoint_schedule[month] = backfill_schedule_values(setpoint_schedule[month])
    end
    if setpoint_schedule.any? { |m| m.any? { |h| h == 0 } }
      runner.registerError("Failed to get the setpoint schedule.")
      return nil
    end
    return setpoint_schedule
  end

  def self.weekday_or_weekend_rule(rule)
    if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday and rule.applySaturday and rule.applySunday
      return 'weekday/weekend'
    elsif rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
      return 'weekday'
    elsif rule.applySaturday and rule.applySunday
      return 'weekend'
    end

    return nil
  end

  def self.backfill_schedule_values(values)
    # backfill the array values
    values = values.reverse
    previous_value = values[0]
    values.each_with_index do |c, i|
      if values[i + 1] == 0
        values[i + 1] = previous_value
      end
      previous_value = values[i + 1]
    end
    values = values.reverse
    return values
  end

  def self.get_season(model, weather, runner, sch_name)
    season = []
    model.getScheduleRulesets.each do |sch|
      if sch.name.to_s == sch_name
        sch.scheduleRules.each do |rule|
          ix = rule.startDate.get.monthOfYear.value.to_i - 1
          season[ix] = rule.daySchedule.values[0]
        end
      end
    end
    if season.empty?
      heating_season, cooling_season = calc_heating_and_cooling_seasons(model, weather, runner)
      if sch_name == Constants.ObjectNameHeatingSeason
        season = heating_season
      else
        season = cooling_season
      end
    end
    return season
  end

  def self.get_default_heating_setpoint(control_type)
    htg_sp = 68 # F
    htg_setback_sp = nil
    htg_setback_hrs_per_week = nil
    htg_setback_start_hr = nil
    if control_type == "programmable thermostat"
      htg_setback_sp = 66 # F
      htg_setback_hrs_per_week = 7 * 7 # 11 p.m. to 5:59 a.m., 7 days a week
      htg_setback_start_hr = 23 # 11 p.m.
    elsif control_type != "manual thermostat"
      fail "Unexpected control type #{control_type}."
    end
    return htg_sp, htg_setback_sp, htg_setback_hrs_per_week, htg_setback_start_hr
  end

  def self.get_default_cooling_setpoint(control_type)
    clg_sp = 78 # F
    clg_setup_sp = nil
    clg_setup_hrs_per_week = nil
    clg_setup_start_hr = nil
    if control_type == "programmable thermostat"
      clg_setup_sp = 80 # F
      clg_setup_hrs_per_week = 6 * 7 # 9 a.m. to 2:59 p.m., 7 days a week
      clg_setup_start_hr = 9 # 9 a.m.
    elsif control_type != "manual thermostat"
      fail "Unexpected control type #{control_type}."
    end
    return clg_sp, clg_setup_sp, clg_setup_hrs_per_week, clg_setup_start_hr
  end

  def self.apply_dehumidifier(model, runner, energy_factor, water_removal_rate,
                              air_flow_rate, humidity_setpoint, control_zone)

    # error checking
    if humidity_setpoint < 0 or humidity_setpoint > 1
      runner.registerError("Invalid humidity setpoint value entered.")
      return false
    end
    if water_removal_rate != Constants.Auto and water_removal_rate.to_f <= 0
      runner.registerError("Invalid water removal rate value entered.")
      return false
    end
    if energy_factor != Constants.Auto and energy_factor.to_f < 0
      runner.registerError("Invalid energy factor value entered.")
      return false
    end
    if air_flow_rate != Constants.Auto and air_flow_rate.to_f < 0
      runner.registerError("Invalid air flow rate value entered.")
      return false
    end

    obj_name = Constants.ObjectNameDehumidifier

    avg_rh_setpoint = humidity_setpoint * 100.0 # (EnergyPlus uses 60 for 60% RH)
    relative_humidity_setpoint_sch = OpenStudio::Model::ScheduleConstant.new(model)
    relative_humidity_setpoint_sch.setName(Constants.ObjectNameRelativeHumiditySetpoint)
    relative_humidity_setpoint_sch.setValue(avg_rh_setpoint)

    # Dehumidifier coefficients
    # Generic model coefficients from Winkler, Christensen, and Tomerlin (2011)
    water_removal_curve = create_curve_biquadratic(model, [-1.162525707, 0.02271469, -0.000113208, 0.021110538, -0.0000693034, 0.000378843], "DXDH-WaterRemove-Cap-fT", -100, 100, -100, 100)
    energy_factor_curve = create_curve_biquadratic(model, [-1.902154518, 0.063466565, -0.000622839, 0.039540407, -0.000125637, -0.000176722], "DXDH-EnergyFactor-fT", -100, 100, -100, 100)
    part_load_frac_curve = create_curve_quadratic(model, [0.90, 0.10, 0.0], "DXDH-PLF-fPLR", 0, 1, 0.7, 1)

    control_zone.each do |control_zone, slave_zones|
      humidistat = OpenStudio::Model::ZoneControlHumidistat.new(model)
      humidistat.setName(obj_name + " #{control_zone.name} humidistat")
      humidistat.setHumidifyingRelativeHumiditySetpointSchedule(relative_humidity_setpoint_sch)
      humidistat.setDehumidifyingRelativeHumiditySetpointSchedule(relative_humidity_setpoint_sch)
      control_zone.setZoneControlHumidistat(humidistat)

      zone_hvac = OpenStudio::Model::ZoneHVACDehumidifierDX.new(model, water_removal_curve, energy_factor_curve, part_load_frac_curve)
      zone_hvac.setName(obj_name + " #{control_zone.name} dx")
      zone_hvac.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
      if water_removal_rate != Constants.Auto
        zone_hvac.setRatedWaterRemoval(UnitConversions.convert(water_removal_rate.to_f, "pint", "L"))
      else
        zone_hvac.setRatedWaterRemoval(Constants.small) # Autosize flag for HVACSizing measure
      end
      if energy_factor != Constants.Auto
        zone_hvac.setRatedEnergyFactor(energy_factor.to_f)
      else
        zone_hvac.setRatedEnergyFactor(Constants.small) # Autosize flag for HVACSizing measure
      end
      if air_flow_rate != Constants.Auto
        zone_hvac.setRatedAirFlowRate(UnitConversions.convert(air_flow_rate.to_f, "cfm", "m^3/s"))
      else
        zone_hvac.setRatedAirFlowRate(Constants.small) # Autosize flag for HVACSizing measure
      end
      zone_hvac.setMinimumDryBulbTemperatureforDehumidifierOperation(10)
      zone_hvac.setMaximumDryBulbTemperatureforDehumidifierOperation(40)

      zone_hvac.addToThermalZone(control_zone)
      runner.registerInfo("Added '#{zone_hvac.name}' to '#{control_zone.name}'")
    end

    return true
  end

  def self.apply_ceiling_fans(model, runner, annual_kWh, weekday_sch, weekend_sch, monthly_sch,
                              cfa, living_space)
    obj_name = Constants.ObjectNameCeilingFan

    ceiling_fan_sch = MonthWeekdayWeekendSchedule.new(model, runner, obj_name + " schedule", weekday_sch, weekend_sch, monthly_sch, mult_weekday = 1.0, mult_weekend = 1.0, normalized_values = true, create_sch_object = true, schedule_type_limits_name = Constants.ScheduleTypeLimitsFraction)
    if not ceiling_fan_sch.validated?
      return false
    end

    space_design_level = ceiling_fan_sch.calcDesignLevelFromDailykWh(annual_kWh / 365.0)

    equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    equip_def.setName(obj_name)
    equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
    equip.setName(equip_def.name.to_s)
    equip.setSpace(living_space)
    equip_def.setDesignLevel(space_design_level)
    equip_def.setFractionRadiant(0.558)
    equip_def.setFractionLatent(0)
    equip_def.setFractionLost(0)
    equip.setEndUseSubcategory(obj_name)
    equip.setSchedule(ceiling_fan_sch.schedule)

    return true
  end

  def self.get_default_ceiling_fan_power()
    return 42.6 # W
  end

  def self.get_default_ceiling_fan_quantity(nbeds)
    return nbeds + 1
  end

  def self.get_ceiling_fan_operation_months(weather)
    months = [0] * 12
    weather.data.MonthlyAvgDrybulbs.each_with_index do |val, m|
      next unless val > 63.0 # deg-F

      months[m] = 1
    end
    return months
  end

  def self.apply_eae_to_heating_fan(runner, eae_hvacs, eae, fuel, load_frac, htg_type)
    # Applies Electric Auxiliary Energy (EAE) for fuel heating equipment to fan power.

    if htg_type == 'Boiler'

      if eae.nil?
        eae = get_default_eae(htg_type, fuel, load_frac, nil)
      end

      elec_power = (eae / 2.08) # W

      eae_hvacs.each do |eae_hvac|
        next unless eae_hvac.is_a? OpenStudio::Model::PlantLoop

        eae_hvac.components.each do |plc|
          if plc.to_BoilerHotWater.is_initialized
            boiler = plc.to_BoilerHotWater.get
            boiler.setParasiticElectricLoad(0.0)
          elsif plc.to_PumpVariableSpeed.is_initialized
            pump = plc.to_PumpVariableSpeed.get
            pump_eff = 0.9
            pump_gpm = UnitConversions.convert(pump.ratedFlowRate.get, "m^3/s", "gal/min")
            pump_w_gpm = elec_power / pump_gpm # W/gpm
            pump.setRatedPowerConsumption(elec_power)
            pump.setRatedPumpHead(calculate_pump_head(pump_eff, pump_w_gpm))
            pump.setMotorEfficiency(1.0)
          end
        end
      end

    else # Furnace/WallFurnace/Stove

      unitary_systems = []
      eae_hvacs.each do |eae_hvac|
        if eae_hvac.is_a? OpenStudio::Model::AirLoopHVAC # Furnace
          unitary_systems << get_unitary_system_from_air_loop_hvac(eae_hvac)
        elsif eae_hvac.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem # WallFurnace/Stove
          unitary_systems << eae_hvac
        end
      end

      unitary_systems.each do |unitary_system|
        if eae.nil?
          htg_coil = unitary_system.heatingCoil.get.to_CoilHeatingGas.get
          htg_capacity = UnitConversions.convert(htg_coil.nominalCapacity.get, "W", "kBtu/hr")
          eae = get_default_eae(htg_type, fuel, load_frac, htg_capacity)
        end
        elec_power = eae / 2.08 # W

        htg_coil = unitary_system.heatingCoil.get.to_CoilHeatingGas.get
        htg_coil.setParasiticElectricLoad(0.0)

        htg_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringHeatingOperation.get, "m^3/s", "cfm")

        fan = unitary_system.supplyFan.get.to_FanOnOff.get
        if elec_power > 0
          fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
          fan_w_cfm = elec_power / htg_cfm # W/cfm
          fan.setFanEfficiency(fan_eff)
          fan.setPressureRise(calculate_fan_pressure_rise(fan_eff, fan_w_cfm))
        else
          fan.setFanEfficiency(1)
          fan.setPressureRise(0)
        end
        fan.setMotorEfficiency(1.0)
        fan.setMotorInAirstreamFraction(1.0)
      end

    end

    return true
  end

  def self.get_default_eae(htg_type, fuel, load_frac, furnace_capacity_kbtuh)
    # From ANSI/RESNET/ICC 301 Standard
    if htg_type == 'Boiler'
      if fuel == Constants.FuelTypeGas or fuel == Constants.FuelTypePropane
        return 170.0 * load_frac # kWh/yr
      elsif fuel == Constants.FuelTypeOil
        return 330.0 * load_frac # kWh/yr
      end
    elsif htg_type == 'Furnace'
      if fuel == Constants.FuelTypeGas or fuel == Constants.FuelTypePropane
        return (149.0 + 10.3 * furnace_capacity_kbtuh) * load_frac # kWh/yr
      elsif fuel == Constants.FuelTypeOil
        return (439.0 + 5.5 * furnace_capacity_kbtuh) * load_frac # kWh/yr
      end
    end
    return 0.0
  end

  def self.one_speed_capacity_ratios
    return [1.0]
  end

  def self.one_speed_fan_speed_ratios
    return [1.0]
  end

  def self.two_speed_capacity_ratios
    return [0.72, 1.0]
  end

  def self.two_speed_fan_speed_ratios_heating
    return [0.8, 1.0]
  end

  def self.two_speed_fan_speed_ratios_cooling
    return [0.86, 1.0]
  end

  def self.variable_speed_capacity_ratios_cooling
    return [0.36, 0.51, 0.67, 1.0]
  end

  def self.variable_speed_fan_speed_ratios_cooling
    return [0.42, 0.54, 0.68, 1.0]
  end

  def self.variable_speed_capacity_ratios_heating
    return [0.33, 0.56, 1.0, 1.17]
  end

  def self.variable_speed_fan_speed_ratios_heating
    return [0.63, 0.76, 1.0, 1.19]
  end

  def self.cOOL_CAP_FT_SPEC_AC(num_speeds = 1)
    if num_speeds == 1
      return [[3.670270705, -0.098652414, 0.000955906, 0.006552414, -0.0000156, -0.000131877]]
    elsif num_speeds == 2
      return [[3.940185508, -0.104723455, 0.001019298, 0.006471171, -0.00000953, -0.000161658],
              [3.109456535, -0.085520461, 0.000863238, 0.00863049, -0.0000210, -0.000140186]]
    else
      # The following coefficients were generated using NREL experimental performance mapping for the Carrier unit
      cOOL_CAP_coeff_perf_map = [[1.6516044444444447, 0.0698916049382716, -0.0005546296296296296, -0.08870160493827162, 0.0004135802469135802, 0.00029077160493827157],
                                 [-6.84948049382716, 0.26946, -0.0019413580246913577, -0.03281469135802469, 0.00015694444444444442, 3.32716049382716e-05],
                                 [-4.53543086419753, 0.15358543209876546, -0.0009345679012345678, 0.002666913580246914, -7.993827160493826e-06, -0.00011617283950617283],
                                 [-3.500948395061729, 0.11738987654320988, -0.0006580246913580248, 0.007003148148148148, -2.8518518518518517e-05, -0.0001284259259259259],
                                 [1.8769221728395058, -0.04768641975308643, 0.0006885802469135801, 0.006643395061728395, 1.4209876543209876e-05, -0.00024043209876543206]]
      return cOOL_CAP_coeff_perf_map.select { |i| num_speeds.include? cOOL_CAP_coeff_perf_map.index(i) }
    end
  end

  def self.cOOL_EIR_FT_SPEC_AC(num_speeds = 1)
    if num_speeds == 1
      return [[-3.302695861, 0.137871531, -0.001056996, -0.012573945, 0.000214638, -0.000145054]]
    elsif num_speeds == 2
      return [[-3.877526888, 0.164566276, -0.001272755, -0.019956043, 0.000256512, -0.000133539],
              [-1.990708931, 0.093969249, -0.00073335, -0.009062553, 0.000165099, -0.0000997]]
    else
      # The following coefficients were generated using NREL experimental performance mapping for the Carrier unit
      cOOL_EIR_coeff_perf_map = [[2.896298765432099, -0.12487654320987657, 0.0012148148148148148, 0.04492037037037037, 8.734567901234567e-05, -0.0006348765432098764],
                                 [6.428076543209876, -0.20913209876543212, 0.0018521604938271604, 0.024392592592592594, 0.00019691358024691356, -0.0006012345679012346],
                                 [5.136356049382716, -0.1591530864197531, 0.0014151234567901232, 0.018665555555555557, 0.00020398148148148147, -0.0005407407407407407],
                                 [1.3823471604938273, -0.02875123456790123, 0.00038302469135802463, 0.006344814814814816, 0.00024836419753086417, -0.00047469135802469134],
                                 [-1.0411735802469133, 0.055261604938271605, -0.0004404320987654321, 0.0002154938271604939, 0.00017484567901234564, -0.0002017901234567901]]
      return cOOL_EIR_coeff_perf_map.select { |i| num_speeds.include? cOOL_EIR_coeff_perf_map.index(i) }
    end
  end

  def self.cOOL_CAP_FFLOW_SPEC_AC(num_speeds = 1)
    if num_speeds == 1
      return [[0.718605468, 0.410099989, -0.128705457]]
    elsif num_speeds == 2
      return [[0.65673024, 0.516470835, -0.172887149],
              [0.690334551, 0.464383753, -0.154507638]]
    elsif num_speeds == 4
      return [[1, 0, 0]] * 4
    end
  end

  def self.cOOL_EIR_FFLOW_SPEC_AC(num_speeds = 1)
    if num_speeds == 1
      return [[1.32299905, -0.477711207, 0.154712157]]
    elsif num_speeds == 2
      return [[1.562945114, -0.791859997, 0.230030877],
              [1.31565404, -0.482467162, 0.166239001]]
    elsif num_speeds == 4
      return [[1, 0, 0]] * 4
    end
  end

  def self.cOOL_CAP_FT_SPEC_ASHP(num_speeds = 1)
    if num_speeds == 1
      return [[3.68637657, -0.098352478, 0.000956357, 0.005838141, -0.0000127, -0.000131702]]
    elsif num_speeds == 2
      return [[3.998418659, -0.108728222, 0.001056818, 0.007512314, -0.0000139, -0.000164716],
              [3.466810106, -0.091476056, 0.000901205, 0.004163355, -0.00000919, -0.000110829]]
    else
      return cOOL_CAP_FT_SPEC_AC(num_speeds)
    end
  end

  def self.cOOL_EIR_FT_SPEC_ASHP(num_speeds = 1)
    if num_speeds == 1
      return [[-3.437356399, 0.136656369, -0.001049231, -0.0079378, 0.000185435, -0.0001441]]
    elsif num_speeds == 2
      return [[-4.282911381, 0.181023691, -0.001357391, -0.026310378, 0.000333282, -0.000197405],
              [-3.557757517, 0.112737397, -0.000731381, 0.013184877, 0.000132645, -0.000338716]]
    else
      return cOOL_EIR_FT_SPEC_AC(num_speeds)
    end
  end

  def self.cOOL_CAP_FFLOW_SPEC_ASHP(num_speeds = 1)
    if num_speeds == 1
      return [[0.718664047, 0.41797409, -0.136638137]]
    elsif num_speeds == 2
      return [[0.655239515, 0.511655216, -0.166894731],
              [0.618281092, 0.569060264, -0.187341356]]
    elsif num_speeds == 4
      return [[1, 0, 0]] * 4
    end
  end

  def self.cOOL_EIR_FFLOW_SPEC_ASHP(num_speeds = 1)
    if num_speeds == 1
      return [[1.143487507, -0.13943972, -0.004047787]]
    elsif num_speeds == 2
      return [[1.639108268, -0.998953996, 0.359845728],
              [1.570774717, -0.914152018, 0.343377302]]
    elsif num_speeds == 4
      return [[1, 0, 0]] * 4
    end
  end

  def self.hEAT_CAP_FT_SPEC_ASHP(num_speeds = 1, heat_pump_capacity_heat = nil, heat_pump_capacity_heat_17F = nil)
    if num_speeds == 1
      cap_coeff = [[0.566333415, -0.000744164, -0.0000103, 0.009414634, 0.0000506, -0.00000675]]

      # Indoor temperature slope and intercept used if Q_17 is specified (derived using cap_coeff)
      iat_slope = -0.002303414
      iat_intercept = 0.18417308
    elsif num_speeds == 2
      cap_coeff = [[0.335690634, 0.002405123, -0.0000464, 0.013498735, 0.0000499, -0.00000725],
                   [0.306358843, 0.005376987, -0.0000579, 0.011645092, 0.0000591, -0.0000203]]

      # Indoor temperature slope and intercept used if Q_17 is specified (derived using cap_coeff)
      # NOTE: Using Q_17 assumes the same curve for all speeds
      iat_slope = -0.002947013
      iat_intercept = 0.23168251
    elsif num_speeds == 4
      cap_coeff = [[0.304192655, -0.003972566, 0.0000196432, 0.024471251, -0.000000774126, -0.0000841323],
                   [0.496381324, -0.00144792, 0.0, 0.016020855, 0.0000203447, -0.0000584118],
                   [0.697171186, -0.006189599, 0.0000337077, 0.014291981, 0.0000105633, -0.0000387956],
                   [0.555513805, -0.001337363, -0.00000265117, 0.014328826, 0.0000163849, -0.0000480711]]

      # Indoor temperature slope and intercept used if Q_17 is specified (derived using cap_coeff)
      # NOTE: Using Q_17 assumes the same curve for all speeds
      iat_slope = -0.002897048
      iat_intercept = 0.209319129
    end

    if heat_pump_capacity_heat.nil? or heat_pump_capacity_heat_17F.nil? or heat_pump_capacity_heat == Constants.SizingAuto
      return cap_coeff
    end

    # Derive coefficients from user input for heating capacity at 47F and 17F
    # Biquadratic: capacity multiplier = a + b*IAT + c*IAT^2 + d*OAT + e*OAT^2 + f*IAT*OAT
    x_A = 17.0
    y_A = heat_pump_capacity_heat_17F / heat_pump_capacity_heat
    x_B = 47.0 # 47F is the rating point
    y_B = 1.0

    oat_slope = (y_B - y_A) / (x_B - x_A)
    oat_intercept = y_A - (x_A * oat_slope)

    cap_coeff = []
    (1..num_speeds).to_a.each do |speed, i|
      cap_coeff << [oat_intercept + iat_intercept, iat_slope, 0, oat_slope, 0, 0]
    end

    return cap_coeff
  end

  def self.hEAT_EIR_FT_SPEC_ASHP(num_speeds = 1)
    if num_speeds == 1
      return [[0.718398423, 0.003498178, 0.000142202, -0.005724331, 0.00014085, -0.000215321]]
    elsif num_speeds == 2
      return [[0.36338171, 0.013523725, 0.000258872, -0.009450269, 0.000439519, -0.000653723],
              [0.981100941, -0.005158493, 0.000243416, -0.005274352, 0.000230742, -0.000336954]]
    elsif num_speeds == 4
      return [[0.708311527, 0.020732093, 0.000391479, -0.037640031, 0.000979937, -0.001079042],
              [0.025480155, 0.020169585, 0.000121341, -0.004429789, 0.000166472, -0.00036447],
              [0.379003189, 0.014195012, 0.0000821046, -0.008894061, 0.000151519, -0.000210299],
              [0.690404655, 0.00616619, 0.000137643, -0.009350199, 0.000153427, -0.000213258]]
    end
  end

  def self.hEAT_CAP_FFLOW_SPEC_ASHP(num_speeds = 1)
    if num_speeds == 1
      return [[0.694045465, 0.474207981, -0.168253446]]
    elsif num_speeds == 2
      return [[0.741466907, 0.378645444, -0.119754733],
              [0.76634609, 0.32840943, -0.094701495]]
    elsif num_speeds == 4
      return [[1, 0, 0]] * 4
    end
  end

  def self.hEAT_EIR_FFLOW_SPEC_ASHP(num_speeds = 1)
    if num_speeds == 1
      return [[2.185418751, -1.942827919, 0.757409168]]
    elsif num_speeds == 2
      return [[2.153618211, -1.737190609, 0.584269478],
              [2.001041353, -1.58869128, 0.587593517]]
    elsif num_speeds == 4
      return [[1, 0, 0]] * 4
    end
  end

  private

  def self.get_gshp_hx_pipe_diameters(pipe_size)
    # Pipe norminal size convertion to pipe outside diameter and inside diameter,
    # only pipe sizes <= 2" are used here with DR11 (dimension ratio),
    if pipe_size == 0.75 # 3/4" pipe
      pipe_od = 1.050
      pipe_id = 0.859
    elsif pipe_size == 1.0 # 1" pipe
      pipe_od = 1.315
      pipe_id = 1.076
    elsif pipe_size == 1.25 # 1-1/4" pipe
      pipe_od = 1.660
      pipe_id = 1.358
    end
    return pipe_od, pipe_id
  end

  def self.get_gshp_HXCHWDesign(weather)
    return [85.0, weather.design.CoolingDrybulb - 15.0, weather.data.AnnualAvgDrybulb + 10.0].max # Temperature of water entering indoor coil,use 85F as lower bound
  end

  def self.get_gshp_HXHWDesign(weather, fluid_type)
    if fluid_type == Constants.FluidWater
      return [45.0, weather.design.HeatingDrybulb + 35.0, weather.data.AnnualAvgDrybulb - 10.0].max # Temperature of fluid entering indoor coil, use 45F as lower bound for water
    else
      return [35.0, weather.design.HeatingDrybulb + 35.0, weather.data.AnnualAvgDrybulb - 10.0].min # Temperature of fluid entering indoor coil, use 35F as upper bound
    end
  end

  def self.get_gshp_cooling_eir(eer, fanKW_Adjust, pumpKW_Adjust)
    return UnitConversions.convert((1.0 - eer * (fanKW_Adjust + pumpKW_Adjust)) / (eer * (1 + UnitConversions.convert(fanKW_Adjust, "Wh", "Btu"))), "Wh", "Btu")
  end

  def self.get_gshp_heating_eir(cop, fanKW_Adjust, pumpKW_Adjust)
    return (1.0 - cop * (fanKW_Adjust + pumpKW_Adjust)) / (cop * (1 - fanKW_Adjust))
  end

  def self.get_gshp_FanKW_Adjust(cfm_btuh)
    return cfm_btuh * UnitConversions.convert(1.0, "cfm", "m^3/s") * 1000.0 * 0.35 * 249.0 / 300.0 # Adjustment per ISO 13256-1 Internal pressure drop across heat pump assumed to be 0.5 in. w.g.
  end

  def self.get_gshp_PumpKW_Adjust(gpm_btuh)
    return gpm_btuh * UnitConversions.convert(1.0, "gal/min", "m^3/s") * 1000.0 * 6.0 * 2990.0 / 3000.0 # Adjustment per ISO 13256-1 Internal Pressure drop across heat pump coil assumed to be 11ft w.g.
  end

  def self.calc_EIR_from_COP(cop, fan_power_rated)
    return UnitConversions.convert((UnitConversions.convert(1, "Btu", "Wh") + fan_power_rated * 0.03333) / cop - fan_power_rated * 0.03333, "Wh", "Btu")
  end

  def self.calc_EIR_from_EER(eer, fan_power_rated)
    return UnitConversions.convert((1 - UnitConversions.convert(fan_power_rated * 0.03333, "Wh", "Btu")) / eer - fan_power_rated * 0.03333, "Wh", "Btu")
  end

  def self.calc_EER_from_EIR(eir, fan_power_rated)
    cfm_per_ton = 400.0
    cfm_per_btuh = cfm_per_ton / 12000.0
    return ((1 - 3.412 * (fan_power_rated * cfm_per_btuh)) / (eir / 3.412 + (fan_power_rated * cfm_per_btuh)))
  end

  def self.calc_COP_from_EIR(eir, fan_power_rated)
    cfm_per_ton = 400.0
    cfm_per_btuh = cfm_per_ton / 12000.0
    return (1.0 / 3.412 + fan_power_rated * cfm_per_btuh) / (eir / 3.412 + fan_power_rated * cfm_per_btuh)
  end

  def self.calc_EERs_from_EIR_2spd(eer_2, fan_power_rated, is_heat_pump)
    # Returns low and high stage EER A given high stage EER A

    eir_2_a = calc_EIR_from_EER(eer_2, fan_power_rated)

    if not is_heat_pump
      eir_1_a = 0.8691 * eir_2_a + 0.0127 # Relationship derived using Dylan's data for two stage air conditioners
    else
      eir_1_a = 0.8887 * eir_2_a + 0.0083 # Relationship derived using Dylan's data for two stage heat pumps
    end

    return [calc_EER_from_EIR(eir_1_a, fan_power_rated), eer_2]
  end

  def self.calc_EERs_from_EIR_4spd(eer_nom, fan_power_rated, calc_type = 'seer')
    # Returns EER A at minimum, intermediate, and nominal speed given EER A (and a fourth speed if calc_type != 'seer')

    eir_nom = calc_EIR_from_EER(eer_nom, fan_power_rated)

    if calc_type.include? 'seer'
      indices = [0, 1, 4]
    else
      indices = [0, 1, 2, 4]
    end

    cop_ratios = [1.07, 1.11, 1.08, 1.05, 1.0] # Gross COP

    # SEER calculation is based on performance at three speeds
    cops = [cop_ratios[indices[0]], cop_ratios[indices[1]], cop_ratios[indices[2]]]

    unless calc_type.include? 'seer'
      cops << cop_ratios[indices[3]]
    end

    eers = []
    cops.each do |mult|
      eir = eir_nom / mult
      eers << calc_EER_from_EIR(eir, fan_power_rated)
    end

    return eers
  end

  def self.calc_COPs_from_EIR_2spd(cop_2, fan_power_rated)
    # Returns low and high stage rated COP given high stage COP

    eir_2 = calc_EIR_from_COP(cop_2, fan_power_rated)

    eir_1 = 0.6241 * eir_2 + 0.0681 # Relationship derived using Dylan's data for Carrier two stage heat pumps

    return [calc_COP_from_EIR(eir_1, fan_power_rated), cop_2]
  end

  def self.calc_COPs_from_EIR_4spd(cop_nom, fan_power_rated, calc_type = 'hspf')
    # Returns rated COP at minimum, intermediate, and nominal speed given rated COP

    eir_nom = calc_EIR_from_COP(cop_nom, fan_power_rated)

    cop_ratios = [1.385171617, 1.183214059, 1.0, 0.95544453] # Updated based on Nordyne 3 ton heat pump

    # HSPF calculation is based on performance at three speeds
    if calc_type.include? 'hspf'
      indices = [0, 1, 2]
    else
      indices = [0, 1, 2, 3]
    end

    cops_net = []
    indices.each do |i|
      eir = eir_nom / cop_ratios[i]
      cops_net << calc_COP_from_EIR(eir, fan_power_rated)
    end

    return cops_net
  end

  def self.calc_biquad(coeff, in_1, in_2)
    result = coeff[0] + coeff[1] * in_1 + coeff[2] * in_1 * in_1 + coeff[3] * in_2 + coeff[4] * in_2 * in_2 + coeff[5] * in_1 * in_2
    return result
  end

  def self.calc_EER_cooling_1spd(seer, fan_power_rated, coeff_eir)
    # Directly calculate cooling coil net EER at condition A (95/80/67) using SEER

    c_d = HVAC.get_c_d_cooling(1, seer)

    # 1. Calculate eer_b using SEER and c_d
    eer_b = seer / (1 - 0.5 * c_d)

    # 2. Calculate eir_b
    eir_b = calc_EIR_from_EER(eer_b, fan_power_rated)

    # 3. Calculate eir_a using performance curves
    eir_a = eir_b / calc_biquad(coeff_eir[0], 67.0, 82.0)
    eer_a = calc_EER_from_EIR(eir_a, fan_power_rated)

    return eer_a
  end

  def self.calc_EERs_cooling_2spd(runner, seer, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q, is_heat_pump = false)
    # Iterate to find rated net EERs given SEER using simple bisection method for two stage air conditioners

    # Initial large bracket of EER (A condition) to span possible seer range
    eer_a = 5.0
    eer_b = 20.0

    # Iterate
    iter_max = 100
    tol = 0.0001

    err = 1
    eer_c = (eer_a + eer_b) / 2.0
    (1..iter_max).each do |n|
      eers = calc_EERs_from_EIR_2spd(eer_a, fan_power_rated, is_heat_pump)
      f_a = calc_SEER_TwoSpeed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - seer

      eers = calc_EERs_from_EIR_2spd(eer_c, fan_power_rated, is_heat_pump)
      f_c = calc_SEER_TwoSpeed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - seer

      if f_c == 0
        return eer_c
      elsif f_a * f_c < 0
        eer_b = eer_c
      else
        eer_a = eer_c
      end

      eer_c = (eer_a + eer_b) / 2.0
      err = (eer_b - eer_a) / 2.0

      if err <= tol
        break
      end
    end

    if err > tol
      eer_c = -99
      runner.registerWarning('Two-speed cooling EERs iteration failed to converge.')
    end

    return calc_EERs_from_EIR_2spd(eer_c, fan_power_rated, is_heat_pump)
  end

  def self.calc_EERs_cooling_4spd(runner, seer, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    # Iterate to find rated net EERs given SEER using simple bisection method for two stage and variable speed air conditioners

    # Initial large bracket of EER (A condition) to span possible seer range
    eer_a = 5.0
    eer_b = 30.0

    # Iterate
    iter_max = 100
    tol = 0.0001

    err = 1
    eer_c = (eer_a + eer_b) / 2.0
    (1..iter_max).each do |n|
      eers = calc_EERs_from_EIR_4spd(eer_a, fan_power_rated, calc_type = 'seer')
      f_a = calc_SEER_VariableSpeed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - seer

      eers = calc_EERs_from_EIR_4spd(eer_c, fan_power_rated, calc_type = 'seer')
      f_c = calc_SEER_VariableSpeed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - seer

      if f_c == 0
        return eer_c
      elsif f_a * f_c < 0
        eer_b = eer_c
      else
        eer_a = eer_c
      end

      eer_c = (eer_a + eer_b) / 2.0
      err = (eer_b - eer_a) / 2.0

      if err <= tol
        break
      end
    end

    if err > tol
      eer_c = -99
      runner.registerWarning('Variable-speed cooling EERs iteration failed to converge.')
    end

    return calc_EERs_from_EIR_4spd(eer_c, fan_power_rated, calc_type = 'model')
  end

  def self.calc_SEER_TwoSpeed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    # Two speed SEER calculation ported from BEopt v2.8 sim.py

    eir_A2 = calc_EIR_from_EER(eers[1], fan_power_rated)
    eir_B2 = eir_A2 * calc_biquad(coeff_eir[1], 67.0, 82.0)

    eir_A1 = calc_EIR_from_EER(eers[0], fan_power_rated)
    eir_B1 = eir_A1 * calc_biquad(coeff_eir[0], 67.0, 82.0)
    eir_F1 = eir_A1 * calc_biquad(coeff_eir[0], 67.0, 67.0)

    q_A2 = 1.0
    q_B2 = q_A2 * calc_biquad(coeff_q[1], 67.0, 82.0)

    q_B1 = q_A2 * capacity_ratios[0] * calc_biquad(coeff_q[0], 67.0, 82.0)
    q_F1 = q_A2 * capacity_ratios[0] * calc_biquad(coeff_q[0], 67.0, 67.0)

    cfm_Btu_h = 400.0 / 12000.0

    q_A2_net = q_A2 - fan_power_rated * 3.412 * cfm_Btu_h
    q_B2_net = q_B2 - fan_power_rated * 3.412 * cfm_Btu_h
    q_B1_net = q_B1 - fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[0]
    q_F1_net = q_F1 - fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[0]

    p_A2 = (q_A2 * eir_A2) / 3.412 + fan_power_rated * cfm_Btu_h
    p_B2 = (q_B2 * eir_B2) / 3.412 + fan_power_rated * cfm_Btu_h
    p_B1 = (q_B1 * eir_B1) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[0]
    p_F1 = (q_F1 * eir_F1) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[0]

    t_bins = [67.0, 72.0, 77.0, 82.0, 87.0, 92.0, 97.0, 102.0]
    frac_hours = [0.214, 0.231, 0.216, 0.161, 0.104, 0.052, 0.018, 0.004]

    e_tot = 0.0
    q_tot = 0.0
    (0..7).each do |i|
      bL_i = ((t_bins[i] - 65.0) / (95.0 - 65.0)) * (q_A2_net / 1.1)
      q_low_i = q_F1_net + ((q_B1_net - q_F1_net) / (82.0 - 67.0)) * (t_bins[i] - 67.0)
      e_low_i = p_F1 + ((p_B1 - p_F1) / (82.0 - 67.0)) * (t_bins[i] - 67.0)
      q_high_i = q_B2_net + ((q_A2_net - q_B2_net) / (95.0 - 82.0)) * (t_bins[i] - 82.0)
      e_high_i = p_B2 + ((p_A2 - p_B2) / (95.0 - 82.0)) * (t_bins[i] - 82.0)
      if q_low_i >= bL_i
        pLF_i = 1.0 - c_d * (1.0 - (bL_i / q_low_i))
        q_i = bL_i * frac_hours[i]
        e_i = (((bL_i / q_low_i) * e_low_i) / pLF_i) * frac_hours[i]
      elsif q_low_i < bL_i and bL_i < q_high_i
        x_i = (q_high_i - bL_i) / (q_high_i - q_low_i)
        q_i = (x_i * q_low_i + (1.0 - x_i) * q_high_i) * frac_hours[i]
        e_i = (x_i * e_low_i + (1.0 - x_i) * e_high_i) * frac_hours[i]
      elsif q_high_i <= bL_i
        q_i = q_high_i * frac_hours[i]
        e_i = e_high_i * frac_hours[i]
      end

      e_tot += e_i
      q_tot += q_i
    end

    seer = q_tot / e_tot
    return seer
  end

  def self.calc_SEER_VariableSpeed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    n_max = 2
    n_int = 1
    n_min = 0

    wBin = 67.0
    tout_B = 82.0
    tout_E = 87.0
    tout_F = 67.0

    eir_A2 = calc_EIR_from_EER(eers[n_max], fan_power_rated)
    eir_B2 = eir_A2 * calc_biquad(coeff_eir[n_max], wBin, tout_B)

    eir_Av = calc_EIR_from_EER(eers[n_int], fan_power_rated)
    eir_Ev = eir_Av * calc_biquad(coeff_eir[n_int], wBin, tout_E)

    eir_A1 = calc_EIR_from_EER(eers[n_min], fan_power_rated)
    eir_B1 = eir_A1 * calc_biquad(coeff_eir[n_min], wBin, tout_B)
    eir_F1 = eir_A1 * calc_biquad(coeff_eir[n_min], wBin, tout_F)

    q_A2 = capacity_ratios[n_max]
    q_B2 = q_A2 * calc_biquad(coeff_q[n_max], wBin, tout_B)
    q_Ev = capacity_ratios[n_int] * calc_biquad(coeff_q[n_int], wBin, tout_E)
    q_B1 = capacity_ratios[n_min] * calc_biquad(coeff_q[n_min], wBin, tout_B)
    q_F1 = capacity_ratios[n_min] * calc_biquad(coeff_q[n_min], wBin, tout_F)

    cfm_Btu_h = 400.0 / 12000.0

    q_A2_net = q_A2 - fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_max]
    q_B2_net = q_B2 - fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_max]
    q_Ev_net = q_Ev - fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_int]
    q_B1_net = q_B1 - fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_min]
    q_F1_net = q_F1 - fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_min]

    p_A2 = (q_A2 * eir_A2) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[n_max]
    p_B2 = (q_B2 * eir_B2) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[n_max]
    p_Ev = (q_Ev * eir_Ev) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[n_int]
    p_B1 = (q_B1 * eir_B1) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[n_min]
    p_F1 = (q_F1 * eir_F1) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[n_min]

    q_k1_87 = q_F1_net + (q_B1_net - q_F1_net) / (82.0 - 67.0) * (87.0 - 67.0)
    q_k2_87 = q_B2_net + (q_A2_net - q_B2_net) / (95.0 - 82.0) * (87.0 - 82.0)
    n_Q = (q_Ev_net - q_k1_87) / (q_k2_87 - q_k1_87)
    m_Q = (q_B1_net - q_F1_net) / (82.0 - 67.0) * (1.0 - n_Q) + (q_A2_net - q_B2_net) / (95.0 - 82.0) * n_Q
    p_k1_87 = p_F1 + (p_B1 - p_F1) / (82.0 - 67.0) * (87.0 - 67.0)
    p_k2_87 = p_B2 + (p_A2 - p_B2) / (95.0 - 82.0) * (87.0 - 82.0)
    n_E = (p_Ev - p_k1_87) / (p_k2_87 - p_k1_87)
    m_E = (p_B1 - p_F1) / (82.0 - 67.0) * (1.0 - n_E) + (p_A2 - p_B2) / (95.0 - 82.0) * n_E

    c_T_1_1 = q_A2_net / (1.1 * (95.0 - 65.0))
    c_T_1_2 = q_F1_net
    c_T_1_3 = (q_B1_net - q_F1_net) / (82.0 - 67.0)
    t_1 = (c_T_1_2 - 67.0 * c_T_1_3 + 65.0 * c_T_1_1) / (c_T_1_1 - c_T_1_3)
    q_T_1 = q_F1_net + (q_B1_net - q_F1_net) / (82.0 - 67.0) * (t_1 - 67.0)
    p_T_1 = p_F1 + (p_B1 - p_F1) / (82.0 - 67.0) * (t_1 - 67.0)
    eer_T_1 = q_T_1 / p_T_1

    t_v = (q_Ev_net - 87.0 * m_Q + 65.0 * c_T_1_1) / (c_T_1_1 - m_Q)
    q_T_v = q_Ev_net + m_Q * (t_v - 87.0)
    p_T_v = p_Ev + m_E * (t_v - 87.0)
    eer_T_v = q_T_v / p_T_v

    c_T_2_1 = c_T_1_1
    c_T_2_2 = q_B2_net
    c_T_2_3 = (q_A2_net - q_B2_net) / (95.0 - 82.0)
    t_2 = (c_T_2_2 - 82.0 * c_T_2_3 + 65.0 * c_T_2_1) / (c_T_2_1 - c_T_2_3)
    q_T_2 = q_B2_net + (q_A2_net - q_B2_net) / (95.0 - 82.0) * (t_2 - 82.0)
    p_T_2 = p_B2 + (p_A2 - p_B2) / (95.0 - 82.0) * (t_2 - 82.0)
    eer_T_2 = q_T_2 / p_T_2

    d = (t_2**2.0 - t_1**2.0) / (t_v**2.0 - t_1**2.0)
    b = (eer_T_1 - eer_T_2 - d * (eer_T_1 - eer_T_v)) / (t_1 - t_2 - d * (t_1 - t_v))
    c = (eer_T_1 - eer_T_2 - b * (t_1 - t_2)) / (t_1**2.0 - t_2**2.0)
    a = eer_T_2 - b * t_2 - c * t_2**2.0

    t_bins = [67.0, 72.0, 77.0, 82.0, 87.0, 92.0, 97.0, 102.0]
    frac_hours = [0.214, 0.231, 0.216, 0.161, 0.104, 0.052, 0.018, 0.004]

    e_tot = 0.0
    q_tot = 0.0
    (0..7).each do |i|
      bL = ((t_bins[i] - 65.0) / (95.0 - 65.0)) * (q_A2_net / 1.1)
      q_k1 = q_F1_net + (q_B1_net - q_F1_net) / (82.0 - 67.0) * (t_bins[i] - 67.0)
      p_k1 = p_F1 + (p_B1 - p_F1) / (82.0 - 67.0) * (t_bins[i] - 67)
      q_k2 = q_B2_net + (q_A2_net - q_B2_net) / (95.0 - 82.0) * (t_bins[i] - 82.0)
      p_k2 = p_B2 + (p_A2 - p_B2) / (95.0 - 82.0) * (t_bins[i] - 82.0)

      if bL <= q_k1
        x_k1 = bL / q_k1
        q_Tj_N = x_k1 * q_k1 * frac_hours[i]
        e_Tj_N = x_k1 * p_k1 * frac_hours[i] / (1.0 - c_d * (1.0 - x_k1))
      elsif q_k1 < bL and bL <= q_k2
        q_Tj_N = bL * frac_hours[i]
        eer_T_j = a + b * t_bins[i] + c * t_bins[i]**2.0
        e_Tj_N = q_Tj_N / eer_T_j
      else
        q_Tj_N = frac_hours[i] * q_k2
        e_Tj_N = frac_hours[i] * p_k2
      end

      q_tot += q_Tj_N
      e_tot += e_Tj_N
    end

    seer = q_tot / e_tot
    return seer
  end

  def self.calc_COP_heating_1spd(hspf, c_d, fan_power_rated, coeff_eir, coeff_q)
    # Iterate to find rated net COP given HSPF using simple bisection method

    # Initial large bracket to span possible hspf range
    cop_a = 0.1
    cop_b = 10.0

    # Iterate
    iter_max = 100
    tol = 0.0001

    err = 1
    cop_c = (cop_a + cop_b) / 2.0
    (1..iter_max).each do |n|
      f_a = calc_HSPF_SingleSpeed(cop_a, c_d, fan_power_rated, coeff_eir, coeff_q) - hspf
      f_c = calc_HSPF_SingleSpeed(cop_c, c_d, fan_power_rated, coeff_eir, coeff_q) - hspf

      if f_c == 0
        return cop_c
      elsif f_a * f_c < 0
        cop_b = cop_c
      else
        cop_a = cop_c
      end

      cop_c = (cop_a + cop_b) / 2.0
      err = (cop_b - cop_a) / 2.0

      if err <= tol
        break
      end
    end

    if err > tol
      cop_c = -99
      runner.registerWarning('Single-speed heating COP iteration failed to converge.')
    end

    return cop_c
  end

  def self.calc_HSPF_SingleSpeed(cop_47, c_d, fan_power_rated, coeff_eir, coeff_q)
    # Single speed HSPF calculation ported from BEopt v2.8 sim.py

    eir_47 = calc_EIR_from_COP(cop_47, fan_power_rated)
    eir_35 = eir_47 * calc_biquad(coeff_eir[0], 70.0, 35.0)
    eir_17 = eir_47 * calc_biquad(coeff_eir[0], 70.0, 17.0)

    q_47 = 1.0
    q_35 = 0.7519 # Hard code Q_35 from BEopt1
    q_17 = q_47 * calc_biquad(coeff_q[0], 70.0, 17.0)

    cfm_Btu_h = 400.0 / 12000.0

    q_47_net = q_47 + fan_power_rated * 3.412 * cfm_Btu_h
    q_35_net = q_35 + fan_power_rated * 3.412 * cfm_Btu_h
    q_17_net = q_17 + fan_power_rated * 3.412 * cfm_Btu_h

    p_47 = (q_47 * eir_47) / 3.412 + fan_power_rated * cfm_Btu_h
    p_35 = (q_35 * eir_35) / 3.412 + fan_power_rated * cfm_Btu_h
    p_17 = (q_17 * eir_17) / 3.412 + fan_power_rated * cfm_Btu_h

    t_bins = [62.0, 57.0, 52.0, 47.0, 42.0, 37.0, 32.0, 27.0, 22.0, 17.0, 12.0, 7.0, 2.0, -3.0, -8.0]
    frac_hours = [0.132, 0.111, 0.103, 0.093, 0.100, 0.109, 0.126, 0.087, 0.055, 0.036, 0.026, 0.013, 0.006, 0.002, 0.001]

    designtemp = 5.0
    t_off = 10.0
    t_on = 14.0
    ptot = 0.0
    rHtot = 0.0
    bLtot = 0.0
    dHRmin = q_47
    (0..14).each do |i|
      bL = ((65.0 - t_bins[i]) / (65.0 - designtemp)) * 0.77 * dHRmin

      if t_bins[i] > 17.0 and t_bins[i] < 45.0
        q_h = q_17_net + (((q_35_net - q_17_net) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
        p_h = p_17 + (((p_35 - p_17) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
      else
        q_h = q_17_net + (((q_47_net - q_17_net) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
        p_h = p_17 + (((p_47 - p_17) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
      end

      x_t = [bL / q_h, 1].min

      pLF = 1 - (c_d * (1 - x_t))
      if t_bins[i] <= t_off or q_h / (3.412 * p_h) < 1.0
        sigma_t = 0.0
      elsif t_off < t_bins[i] and t_bins[i] <= t_on and q_h / (p_h * 3.412) >= 1.0
        sigma_t = 0.5
      elsif t_bins[i] > t_on and q_h / (3.412 * p_h) >= 1.0
        sigma_t = 1.0
      end

      p_h_i = (x_t * p_h * sigma_t / pLF) * frac_hours[i]
      rH_i = ((bL - (x_t * q_h * sigma_t)) / 3.412) * frac_hours[i]
      bL_i = bL * frac_hours[i]
      ptot += p_h_i
      rHtot += rH_i
      bLtot += bL_i
    end

    hspf = bLtot / (ptot + rHtot)
    return hspf
  end

  def self.calc_COPs_heating_2spd(hspf, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    # Iterate to find rated net EERs given SEER using simple bisection method for two stage air conditioners

    # Initial large bracket of COP to span possible hspf range
    cop_a = 1.0
    cop_b = 10.0

    # Iterate
    iter_max = 100
    tol = 0.0001

    err = 1
    cop_c = (cop_a + cop_b) / 2.0
    (1..iter_max).each do |n|
      cops = calc_COPs_from_EIR_2spd(cop_a, fan_power_rated)
      f_a = calc_HSPF_TwoSpeed(cops, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - hspf

      cops = calc_COPs_from_EIR_2spd(cop_c, fan_power_rated)
      f_c = calc_HSPF_TwoSpeed(cops, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - hspf

      if f_c == 0
        return cop_c
      elsif f_a * f_c < 0
        cop_b = cop_c
      else
        cop_a = cop_c
      end

      cop_c = (cop_a + cop_b) / 2.0
      err = (cop_b - cop_a) / 2.0

      if err <= tol
        break
      end
    end

    if err > tol
      cop_c = -99
      runner.registerWarning('Two-speed heating COP iteration failed to converge.')
    end

    return calc_COPs_from_EIR_2spd(cop_c, fan_power_rated)
  end

  def self.calc_COPs_heating_4spd(runner, hspf, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    # Iterate to find rated net COPs given HSPF using simple bisection method for variable speed heat pumps

    # Initial large bracket of COP to span possible hspf range
    cop_a = 1.0
    cop_b = 15.0

    # Iterate
    iter_max = 100
    tol = 0.0001

    err = 1
    cop_c = (cop_a + cop_b) / 2.0
    (1..iter_max).each do |n|
      cops = calc_COPs_from_EIR_4spd(cop_a, fan_power_rated, calc_type = 'hspf')
      f_a = calc_HSPF_VariableSpeed(cops, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - hspf

      cops = calc_COPs_from_EIR_4spd(cop_c, fan_power_rated, calc_type = 'hspf')
      f_c = calc_HSPF_VariableSpeed(cops, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - hspf

      if f_c == 0
        return cop_c
      elsif f_a * f_c < 0
        cop_b = cop_c
      else
        cop_a = cop_c
      end

      cop_c = (cop_a + cop_b) / 2.0
      err = (cop_b - cop_a) / 2.0

      if err <= tol
        break
      end
    end

    if err > tol
      cop_c = -99
      runner.registerWarning('Variable-speed heating COPs iteration failed to converge.')
    end

    return calc_COPs_from_EIR_4spd(cop_c, fan_power_rated, calc_type = 'model')
  end

  def self.calc_HSPF_TwoSpeed(cops, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    eir_47_H = calc_EIR_from_COP(cops[1], fan_power_rated)
    eir_35_H = eir_47_H * calc_biquad(coeff_eir[1], 70.0, 35.0)
    eir_17_H = eir_47_H * calc_biquad(coeff_eir[1], 70.0, 17.0)

    eir_47_L = calc_EIR_from_COP(cops[0], fan_power_rated)
    eir_62_L = eir_47_L * calc_biquad(coeff_eir[0], 70.0, 62.0)
    eir_35_L = eir_47_L * calc_biquad(coeff_eir[0], 70.0, 35.0)
    eir_17_L = eir_47_L * calc_biquad(coeff_eir[0], 70.0, 17.0)

    q_H47 = 1.0
    q_H35 = q_H47 * calc_biquad(coeff_q[1], 70.0, 35.0)
    q_H17 = q_H47 * calc_biquad(coeff_q[1], 70.0, 17.0)

    q_L47 = q_H47 * capacity_ratios[0]
    q_L62 = q_L47 * calc_biquad(coeff_q[0], 70.0, 62.0)
    q_L35 = q_L47 * calc_biquad(coeff_q[0], 70.0, 35.0)
    q_L17 = q_L47 * calc_biquad(coeff_q[0], 70.0, 17.0)

    cfm_Btu_h = 400.0 / 12000.0

    q_H47_net = q_H47 + fan_power_rated * 3.412 * cfm_Btu_h
    q_H35_net = q_H35 + fan_power_rated * 3.412 * cfm_Btu_h
    q_H17_net = q_H17 + fan_power_rated * 3.412 * cfm_Btu_h
    q_L62_net = q_L62 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[0]
    q_L47_net = q_L47 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[0]
    q_L35_net = q_L35 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[0]
    q_L17_net = q_L17 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[0]

    p_H47 = (q_H47 * eir_47_H) / 3.412 + fan_power_rated * cfm_Btu_h
    p_H35 = (q_H35 * eir_35_H) / 3.412 + fan_power_rated * cfm_Btu_h
    p_H17 = (q_H17 * eir_17_H) / 3.412 + fan_power_rated * cfm_Btu_h
    p_L62 = (q_L62 * eir_62_L) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[0]
    p_L47 = (q_L47 * eir_47_L) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[0]
    p_L35 = (q_L35 * eir_35_L) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[0]
    p_L17 = (q_L17 * eir_17_L) / 3.412 + fan_power_rated * cfm_Btu_h * fanspeed_ratios[0]

    t_bins = [62.0, 57.0, 52.0, 47.0, 42.0, 37.0, 32.0, 27.0, 22.0, 17.0, 12.0, 7.0, 2.0, -3.0, -8.0]
    frac_hours = [0.132, 0.111, 0.103, 0.093, 0.100, 0.109, 0.126, 0.087, 0.055, 0.036, 0.026, 0.013, 0.006, 0.002, 0.001]

    designtemp = 5.0
    t_off = 10.0
    t_on = 14.0
    ptot = 0.0
    rHtot = 0.0
    bLtot = 0.0
    dHRmin = q_H47
    (0..14).each do |i|
      bL = ((65.0 - t_bins[i]) / (65.0 - designtemp)) * 0.77 * dHRmin

      if 17.0 < t_bins[i] and t_bins[i] < 45.0
        q_h = q_H17_net + (((q_H35_net - q_H17_net) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
        p_h = p_H17 + (((p_H35 - p_H17) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
      else
        q_h = q_H17_net + (((q_H47_net - q_H17_net) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
        p_h = p_H17 + (((p_H47 - p_H17) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
      end

      if t_bins[i] >= 40.0
        q_l = q_L47_net + (((q_L62_net - q_L47_net) * (t_bins[i] - 47.0)) / (62.0 - 47.0))
        p_l = p_L47 + (((p_L62 - p_L47) * (t_bins[i] - 47.0)) / (62.0 - 47.0))
      elsif 17 <= t_bins[i] and t_bins[i] < 40.0
        q_l = q_L17_net + (((q_L35_net - q_L17_net) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
        p_l = p_L17 + (((p_L35 - p_L17) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
      else
        q_l = q_L17_net + (((q_L47_net - q_L17_net) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
        p_l = p_L17 + (((p_L47 - p_L17) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
      end

      x_t_h = [bL / q_h, 1].min
      x_t_l = [bL / q_l, 1].min
      pLF = 1 - (c_d * (1 - x_t_l))
      if t_bins[i] <= t_off or q_h / (p_h * 3.412) < 1.0
        sigma_t_h = 0.0
      elsif t_off < t_bins[i] and t_bins[i] <= t_on and q_h / (p_h * 3.412) >= 1.0
        sigma_t_h = 0.5
      elsif t_bins[i] > t_on and q_h / (p_h * 3.412) >= 1.0
        sigma_t_h = 1.0
      end

      if t_bins[i] <= t_off
        sigma_t_l = 0.0
      elsif t_off < t_bins[i] and t_bins[i] <= t_on
        sigma_t_l = 0.5
      elsif t_bins[i] > t_on
        sigma_t_l = 1.0
      end

      if q_l > bL
        p_h_i = (x_t_l * p_l * sigma_t_l / pLF) * frac_hours[i]
        rH_i = (bL * (1.0 - sigma_t_l)) / 3.412 * frac_hours[i]
      elsif q_l < bL and q_h > bL
        x_t_l = ((q_h - bL) / (q_h - q_l))
        x_t_h = 1.0 - x_t_l
        p_h_i = (x_t_l * p_l + x_t_h * p_h) * sigma_t_l * frac_hours[i]
        rH_i = (bL * (1.0 - sigma_t_l)) / 3.412 * frac_hours[i]
      elsif q_h <= bL
        p_h_i = p_h * sigma_t_h * frac_hours[i]
        rH_i = (bL - (q_h * sigma_t_l)) / 3.412 * frac_hours[i]
      end

      bL_i = bL * frac_hours[i]
      ptot += p_h_i
      rHtot += rH_i
      bLtot += bL_i
    end

    hspf = bLtot / (ptot + rHtot)
    return hspf
  end

  def self.calc_HSPF_VariableSpeed(cop_47, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    n_max = 2
    n_int = 1
    n_min = 0

    tin = 70.0
    tout_3 = 17.0
    tout_2 = 35.0
    tout_0 = 62.0

    eir_H1_2 = calc_EIR_from_COP(cop_47[n_max], fan_power_rated)
    eir_H3_2 = eir_H1_2 * calc_biquad(coeff_eir[n_max], tin, tout_3)

    eir_adjv = calc_EIR_from_COP(cop_47[n_int], fan_power_rated)
    eir_H2_v = eir_adjv * calc_biquad(coeff_eir[n_int], tin, tout_2)

    eir_H1_1 = calc_EIR_from_COP(cop_47[n_min], fan_power_rated)
    eir_H0_1 = eir_H1_1 * calc_biquad(coeff_eir[n_min], tin, tout_0)

    q_H1_2 = capacity_ratios[n_max]
    q_H3_2 = q_H1_2 * calc_biquad(coeff_q[n_max], tin, tout_3)

    q_H2_v = capacity_ratios[n_int] * calc_biquad(coeff_q[n_int], tin, tout_2)

    q_H1_1 = capacity_ratios[n_min]
    q_H0_1 = q_H1_1 * calc_biquad(coeff_q[n_min], tin, tout_0)

    cfm_Btu_h = 400.0 / 12000.0

    q_H1_2_net = q_H1_2 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_max]
    q_H3_2_net = q_H3_2 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_max]
    q_H2_v_net = q_H2_v + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_int]
    q_H1_1_net = q_H1_1 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_min]
    q_H0_1_net = q_H0_1 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_min]

    p_H1_2 = q_H1_2 * eir_H1_2 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_max]
    p_H3_2 = q_H3_2 * eir_H3_2 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_max]
    p_H2_v = q_H2_v * eir_H2_v + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_int]
    p_H1_1 = q_H1_1 * eir_H1_1 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_min]
    p_H0_1 = q_H0_1 * eir_H0_1 + fan_power_rated * 3.412 * cfm_Btu_h * fanspeed_ratios[n_min]

    q_H35_2 = 0.9 * (q_H3_2_net + 0.6 * (q_H1_2_net - q_H3_2_net))
    p_H35_2 = 0.985 * (p_H3_2 + 0.6 * (p_H1_2 - p_H3_2))
    q_H35_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (35.0 - 47.0)
    p_H35_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (35.0 - 47.0)
    n_Q = (q_H2_v_net - q_H35_1) / (q_H35_2 - q_H35_1)
    m_Q = (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (1 - n_Q) + n_Q * (q_H35_2 - q_H3_2_net) / (35.0 - 17.0)
    n_E = (p_H2_v - p_H35_1) / (p_H35_2 - p_H35_1)
    m_E = (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (1.0 - n_E) + n_E * (p_H35_2 - p_H3_2) / (35.0 - 17.0)

    t_OD = 5.0
    dHR = q_H1_2_net * (65.0 - t_OD) / 60.0

    c_T_3_1 = q_H1_1_net
    c_T_3_2 = (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0)
    c_T_3_3 = 0.77 * dHR / (65.0 - t_OD)
    t_3 = (47.0 * c_T_3_2 + 65.0 * c_T_3_3 - c_T_3_1) / (c_T_3_2 + c_T_3_3)
    q_HT3_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (t_3 - 47.0)
    p_HT3_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (t_3 - 47.0)
    cop_T3_1 = q_HT3_1 / p_HT3_1

    c_T_v_1 = q_H2_v_net
    c_T_v_3 = c_T_3_3
    t_v = (35.0 * m_Q + 65 * c_T_v_3 - c_T_v_1) / (m_Q + c_T_v_3)
    q_HTv_v = q_H2_v_net + m_Q * (t_v - 35.0)
    p_HTv_v = p_H2_v + m_E * (t_v - 35.0)
    cop_Tv_v = q_HTv_v / p_HTv_v

    c_T_4_1 = q_H3_2_net
    c_T_4_2 = (q_H35_2 - q_H3_2_net) / (35.0 - 17.0)
    c_T_4_3 = c_T_v_3
    t_4 = (17.0 * c_T_4_2 + 65.0 * c_T_4_3 - c_T_4_1) / (c_T_4_2 + c_T_4_3)
    q_HT4_2 = q_H3_2_net + (q_H35_2 - q_H3_2_net) / (35.0 - 17.0) * (t_4 - 17.0)
    p_HT4_2 = p_H3_2 + (p_H35_2 - p_H3_2) / (35.0 - 17.0) * (t_4 - 17.0)
    cop_T4_2 = q_HT4_2 / p_HT4_2

    d = (t_3**2.0 - t_4**2.0) / (t_v**2.0 - t_4**2.0)
    b = (cop_T4_2 - cop_T3_1 - d * (cop_T4_2 - cop_Tv_v)) / (t_4 - t_3 - d * (t_4 - t_v))
    c = (cop_T4_2 - cop_T3_1 - b * (t_4 - t_3)) / (t_4**2.0 - t_3**2.0)
    a = cop_T4_2 - b * t_4 - c * t_4**2.0

    t_bins = [62.0, 57.0, 52.0, 47.0, 42.0, 37.0, 32.0, 27.0, 22.0, 17.0, 12.0, 7.0, 2.0, -3.0, -8.0]
    frac_hours = [0.132, 0.111, 0.103, 0.093, 0.100, 0.109, 0.126, 0.087, 0.055, 0.036, 0.026, 0.013, 0.006, 0.002, 0.001]

    t_off = 10.0
    t_on = t_off + 4
    etot = 0.0
    bLtot = 0.0
    (0..14).each do |i|
      bL = ((65.0 - t_bins[i]) / (65.0 - t_OD)) * 0.77 * dHR

      q_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (t_bins[i] - 47.0)
      p_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (t_bins[i] - 47.0)

      if t_bins[i] <= 17.0 or t_bins[i] >= 45.0
        q_2 = q_H3_2_net + (q_H1_2_net - q_H3_2_net) * (t_bins[i] - 17.0) / (47.0 - 17.0)
        p_2 = p_H3_2 + (p_H1_2 - p_H3_2) * (t_bins[i] - 17.0) / (47.0 - 17.0)
      else
        q_2 = q_H3_2_net + (q_H35_2 - q_H3_2_net) * (t_bins[i] - 17.0) / (35.0 - 17.0)
        p_2 = p_H3_2 + (p_H35_2 - p_H3_2) * (t_bins[i] - 17.0) / (35.0 - 17.0)
      end

      if t_bins[i] <= t_off
        delta = 0.0
      elsif t_bins[i] >= t_on
        delta = 1.0
      else
        delta = 0.5
      end

      if bL <= q_1
        x_1 = bL / q_1
        e_Tj_n = delta * x_1 * p_1 * frac_hours[i] / (1.0 - c_d * (1.0 - x_1))
      elsif q_1 < bL and bL <= q_2
        cop_T_j = a + b * t_bins[i] + c * t_bins[i]**2.0
        e_Tj_n = delta * frac_hours[i] * bL / cop_T_j + (1.0 - delta) * bL * (frac_hours[i])
      else
        e_Tj_n = delta * frac_hours[i] * p_2 + frac_hours[i] * (bL - delta * q_2)
      end

      bLtot += frac_hours[i] * bL
      etot += e_Tj_n
    end

    hspf = bLtot / (etot / 3.412)
    return hspf
  end

  def self.calc_cfms_ton_rated(rated_airflow_rate, fan_speed_ratios, capacity_ratios)
    array = []
    fan_speed_ratios.each_with_index do |fanspeed_ratio, i|
      capacity_ratio = capacity_ratios[i]
      array << fanspeed_ratio * rated_airflow_rate / capacity_ratio
    end
    return array
  end

  def self.create_curve_biquadratic_constant(model)
    const_biquadratic = OpenStudio::Model::CurveBiquadratic.new(model)
    const_biquadratic.setName("ConstantBiquadratic")
    const_biquadratic.setCoefficient1Constant(1)
    const_biquadratic.setCoefficient2x(0)
    const_biquadratic.setCoefficient3xPOW2(0)
    const_biquadratic.setCoefficient4y(0)
    const_biquadratic.setCoefficient5yPOW2(0)
    const_biquadratic.setCoefficient6xTIMESY(0)
    const_biquadratic.setMinimumValueofx(-100)
    const_biquadratic.setMaximumValueofx(100)
    const_biquadratic.setMinimumValueofy(-100)
    const_biquadratic.setMaximumValueofy(100)
    return const_biquadratic
  end

  def self.create_curve_cubic_constant(model)
    constant_cubic = OpenStudio::Model::CurveCubic.new(model)
    constant_cubic.setName("ConstantCubic")
    constant_cubic.setCoefficient1Constant(1)
    constant_cubic.setCoefficient2x(0)
    constant_cubic.setCoefficient3xPOW2(0)
    constant_cubic.setCoefficient4xPOW3(0)
    constant_cubic.setMinimumValueofx(-100)
    constant_cubic.setMaximumValueofx(100)
    return constant_cubic
  end

  def self.convert_curve_biquadratic(coeff, ip_to_si = true)
    if ip_to_si
      # Convert IP curves to SI curves
      si_coeff = []
      si_coeff << coeff[0] + 32.0 * (coeff[1] + coeff[3]) + 1024.0 * (coeff[2] + coeff[4] + coeff[5])
      si_coeff << 9.0 / 5.0 * coeff[1] + 576.0 / 5.0 * coeff[2] + 288.0 / 5.0 * coeff[5]
      si_coeff << 81.0 / 25.0 * coeff[2]
      si_coeff << 9.0 / 5.0 * coeff[3] + 576.0 / 5.0 * coeff[4] + 288.0 / 5.0 * coeff[5]
      si_coeff << 81.0 / 25.0 * coeff[4]
      si_coeff << 81.0 / 25.0 * coeff[5]
      return si_coeff
    else
      # Convert SI curves to IP curves
      ip_coeff = []
      ip_coeff << coeff[0] - 160.0 / 9.0 * (coeff[1] + coeff[3]) + 25600.0 / 81.0 * (coeff[2] + coeff[4] + coeff[5])
      ip_coeff << 5.0 / 9.0 * (coeff[1] - 320.0 / 9.0 * coeff[2] - 160.0 / 9.0 * coeff[5])
      ip_coeff << 25.0 / 81.0 * coeff[2]
      ip_coeff << 5.0 / 9.0 * (coeff[3] - 320.0 / 9.0 * coeff[4] - 160.0 / 9.0 * coeff[5])
      ip_coeff << 25.0 / 81.0 * coeff[4]
      ip_coeff << 25.0 / 81.0 * coeff[5]
      return ip_coeff
    end
  end

  def self.convert_curve_gshp(coeff, gshp_to_biquadratic)
    m1 = 32 - 273.15 * 1.8
    m2 = 283 * 1.8
    if gshp_to_biquadratic
      biq_coeff = []
      biq_coeff << coeff[0] - m1 * ((coeff[1] + coeff[2]) / m2)
      biq_coeff << coeff[1] / m2
      biq_coeff << 0
      biq_coeff << coeff[2] / m2
      biq_coeff << 0
      biq_coeff << 0
      return biq_coeff
    else
      gsph_coeff = []
      gsph_coeff << coeff[0] + m1 * (coeff[1] + coeff[3])
      gsph_coeff << m2 * coeff[1]
      gsph_coeff << m2 * coeff[3]
      gsph_coeff << 0
      gsph_coeff << 0
      return gsph_coeff
    end
  end

  def self.create_curve_biquadratic(model, coeff, name, minX, maxX, minY, maxY)
    curve = OpenStudio::Model::CurveBiquadratic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setCoefficient4y(coeff[3])
    curve.setCoefficient5yPOW2(coeff[4])
    curve.setCoefficient6xTIMESY(coeff[5])
    curve.setMinimumValueofx(minX)
    curve.setMaximumValueofx(maxX)
    curve.setMinimumValueofy(minY)
    curve.setMaximumValueofy(maxY)
    return curve
  end

  def self.create_curve_bicubic(model, coeff, name, minX, maxX, minY, maxY)
    curve = OpenStudio::Model::CurveBicubic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setCoefficient4y(coeff[3])
    curve.setCoefficient5yPOW2(coeff[4])
    curve.setCoefficient6xTIMESY(coeff[5])
    curve.setCoefficient7xPOW3(coeff[6])
    curve.setCoefficient8yPOW3(coeff[7])
    curve.setCoefficient9xPOW2TIMESY(coeff[8])
    curve.setCoefficient10xTIMESYPOW2(coeff[9])
    curve.setMinimumValueofx(minX)
    curve.setMaximumValueofx(maxX)
    curve.setMinimumValueofy(minY)
    curve.setMaximumValueofy(maxY)
    return curve
  end

  def self.create_curve_quadratic(model, coeff, name, minX, maxX, minY, maxY, is_dimensionless = false)
    curve = OpenStudio::Model::CurveQuadratic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setMinimumValueofx(minX)
    curve.setMaximumValueofx(maxX)
    if not minY.nil?
      curve.setMinimumCurveOutput(minY)
    end
    if not maxY.nil?
      curve.setMaximumCurveOutput(maxY)
    end
    if is_dimensionless
      curve.setInputUnitTypeforX("Dimensionless")
      curve.setOutputUnitType("Dimensionless")
    end
    return curve
  end

  def self.create_curve_cubic(model, coeff, name, minX, maxX, minY, maxY)
    curve = OpenStudio::Model::CurveCubic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setCoefficient4xPOW3(coeff[3])
    curve.setMinimumValueofx(minX)
    curve.setMaximumValueofx(maxX)
    curve.setMinimumCurveOutput(minY)
    curve.setMaximumCurveOutput(maxY)
    return curve
  end

  def self.create_curve_exponent(model, coeff, name, minX, maxX)
    curve = OpenStudio::Model::CurveExponent.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2Constant(coeff[1])
    curve.setCoefficient3Constant(coeff[2])
    curve.setMinimumValueofx(minX)
    curve.setMaximumValueofx(maxX)
    return curve
  end

  def self.calc_coil_stage_data_cooling(model, outputCapacity, speeds, cooling_eirs, shrs_rated_gross, cOOL_CAP_FT_SPEC, cOOL_EIR_FT_SPEC, cOOL_CLOSS_FPLR_SPEC, cOOL_CAP_FFLOW_SPEC, cOOL_EIR_FFLOW_SPEC)
    const_biquadratic = create_curve_biquadratic_constant(model)

    clg_coil_stage_data = []
    speeds.each_with_index do |speed, i|
      cOOL_CAP_FT_SPEC_si = convert_curve_biquadratic(cOOL_CAP_FT_SPEC[speed])
      cOOL_EIR_FT_SPEC_si = convert_curve_biquadratic(cOOL_EIR_FT_SPEC[speed])
      cool_cap_ft_curve = create_curve_biquadratic(model, cOOL_CAP_FT_SPEC_si, "Cool-Cap-fT#{speed + 1}", 13.88, 23.88, 18.33, 51.66)
      cool_eir_ft_curve = create_curve_biquadratic(model, cOOL_EIR_FT_SPEC_si, "Cool-EIR-fT#{speed + 1}", 13.88, 23.88, 18.33, 51.66)
      cool_plf_fplr_curve = create_curve_quadratic(model, cOOL_CLOSS_FPLR_SPEC[speed], "Cool-PLF-fPLR#{speed + 1}", 0, 1, 0.7, 1)
      cool_cap_fff_curve = create_curve_quadratic(model, cOOL_CAP_FFLOW_SPEC[speed], "Cool-Cap-fFF#{speed + 1}", 0, 2, 0, 2)
      cool_eir_fff_curve = create_curve_quadratic(model, cOOL_EIR_FFLOW_SPEC[speed], "Cool-EIR-fFF#{speed + 1}", 0, 2, 0, 2)

      stage_data = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model,
                                                                           cool_cap_ft_curve,
                                                                           cool_cap_fff_curve,
                                                                           cool_eir_ft_curve,
                                                                           cool_eir_fff_curve,
                                                                           cool_plf_fplr_curve,
                                                                           const_biquadratic)
      if outputCapacity != Constants.SizingAuto
        stage_data.setGrossRatedTotalCoolingCapacity(UnitConversions.convert([outputCapacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
      end
      stage_data.setGrossRatedSensibleHeatRatio(shrs_rated_gross[speed])
      stage_data.setGrossRatedCoolingCOP(1.0 / cooling_eirs[speed])
      stage_data.setNominalTimeforCondensateRemovaltoBegin(1000)
      stage_data.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
      stage_data.setMaximumCyclingRate(3)
      stage_data.setLatentCapacityTimeConstant(45)
      stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
      clg_coil_stage_data[i] = stage_data
    end
    return clg_coil_stage_data
  end

  def self.calc_coil_stage_data_heating(model, outputCapacity, speeds, heating_eirs, hEAT_CAP_FT_SPEC, hEAT_EIR_FT_SPEC, hEAT_CLOSS_FPLR_SPEC, hEAT_CAP_FFLOW_SPEC, hEAT_EIR_FFLOW_SPEC)
    const_biquadratic = create_curve_biquadratic_constant(model)

    htg_coil_stage_data = []
    # Loop through speeds to create curves for each speed
    speeds.each_with_index do |speed, i|
      hEAT_CAP_FT_SPEC_si = convert_curve_biquadratic(hEAT_CAP_FT_SPEC[speed])
      hEAT_EIR_FT_SPEC_si = convert_curve_biquadratic(hEAT_EIR_FT_SPEC[speed])
      hp_heat_cap_ft_curve = create_curve_biquadratic(model, hEAT_CAP_FT_SPEC_si, "HP_Heat-Cap-fT#{speed + 1}", -100, 100, -100, 100)
      hp_heat_eir_ft_curve = create_curve_biquadratic(model, hEAT_EIR_FT_SPEC_si, "HP_Heat-EIR-fT#{speed + 1}", -100, 100, -100, 100)
      hp_heat_plf_fplr_curve = create_curve_quadratic(model, hEAT_CLOSS_FPLR_SPEC[speed], "HP_Heat-PLF-fPLR#{speed + 1}", 0, 1, 0.7, 1)
      hp_heat_cap_fff_curve = create_curve_quadratic(model, hEAT_CAP_FFLOW_SPEC[speed], "HP_Heat-CAP-fFF#{speed + 1}", 0, 2, 0, 2)
      hp_heat_eir_fff_curve = create_curve_quadratic(model, hEAT_EIR_FFLOW_SPEC[speed], "HP_Heat-EIR-fFF#{speed + 1}", 0, 2, 0, 2)

      stage_data = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model,
                                                                           hp_heat_cap_ft_curve,
                                                                           hp_heat_cap_fff_curve,
                                                                           hp_heat_eir_ft_curve,
                                                                           hp_heat_eir_fff_curve,
                                                                           hp_heat_plf_fplr_curve,
                                                                           const_biquadratic)
      if outputCapacity != Constants.SizingAuto
        stage_data.setGrossRatedHeatingCapacity(UnitConversions.convert([outputCapacity, Constants.small].max, "Btu/hr", "W")) # Used by HVACSizing measure
      end
      stage_data.setGrossRatedHeatingCOP(1.0 / heating_eirs[speed])
      stage_data.setRatedWasteHeatFractionofPowerInput(0.2)
      htg_coil_stage_data[i] = stage_data
    end
    return htg_coil_stage_data
  end

  def self.calc_cooling_eirs(num_speeds, coolingEER, fan_power_rated)
    cooling_eirs = []
    (0...num_speeds).to_a.each do |speed|
      eir = calc_EIR_from_EER(coolingEER[speed], fan_power_rated)
      cooling_eirs << eir
    end
    return cooling_eirs
  end

  def self.calc_heating_eirs(num_speeds, heatingCOP, fan_power_rated)
    heating_eirs = []
    (0...num_speeds).to_a.each do |speed|
      eir = calc_EIR_from_COP(heatingCOP[speed], fan_power_rated)
      heating_eirs << eir
    end
    return heating_eirs
  end

  def self.calc_shrs_rated_gross(num_speeds, shr_Rated_Net, fan_power_rated, cfms_ton_rated)
    # Convert SHRs from net to gross
    shrs_rated_gross = []
    (0...num_speeds).to_a.each do |speed|
      qtot_net_nominal = 12000.0
      qsens_net_nominal = qtot_net_nominal * shr_Rated_Net[speed]
      qtot_gross_nominal = qtot_net_nominal + UnitConversions.convert(cfms_ton_rated[speed] * fan_power_rated, "Wh", "Btu")
      qsens_gross_nominal = qsens_net_nominal + UnitConversions.convert(cfms_ton_rated[speed] * fan_power_rated, "Wh", "Btu")
      shrs_rated_gross << (qsens_gross_nominal / qtot_gross_nominal)

      # Make sure SHR's are in valid range based on E+ model limits.
      # The following correlation was developed by Jon Winkler to test for maximum allowed SHR based on the 300 - 450 cfm/ton limits in E+
      maxSHR = 0.3821066 + 0.001050652 * cfms_ton_rated[speed] - 0.01
      shrs_rated_gross[speed] = [shrs_rated_gross[speed], maxSHR].min
      minSHR = 0.60 # Approximate minimum SHR such that an ADP exists
      shrs_rated_gross[speed] = [shrs_rated_gross[speed], minSHR].max
    end

    return shrs_rated_gross
  end

  def self.calc_plr_coefficients_cooling(num_speeds, coolingSEER, c_d = nil)
    if c_d.nil?
      c_d = self.get_c_d_cooling(num_speeds, coolingSEER)
    end
    return [(1.0 - c_d), c_d, 0.0] # Linear part load model
  end

  def self.calc_plr_coefficients_heating(num_speeds, heatingHSPF, c_d = nil)
    if c_d.nil?
      c_d = self.get_c_d_heating(num_speeds, heatingHSPF)
    end
    return [(1 - c_d), c_d, 0] # Linear part load model
  end

  def self.get_c_d_cooling(num_speeds, coolingSEER)
    # Degradation coefficient for cooling
    if num_speeds == 1
      if coolingSEER < 13.0
        return 0.20
      else
        return 0.07
      end
    elsif num_speeds == 2
      return 0.11
    elsif num_speeds == 4
      return 0.25
    elsif num_speeds == 10
      return 0.25
    end
  end

  def self.get_c_d_heating(num_speeds, heatingHSPF)
    # Degradation coefficient for heating
    if num_speeds == 1
      if heatingHSPF < 7.0
        return 0.20
      else
        return 0.11
      end
    elsif num_speeds == 2
      return 0.11
    elsif num_speeds == 4
      return 0.24
    elsif num_speeds == 10
      return 0.40
    end
  end

  def self.get_fan_power_rated(seer)
    if seer <= 15
      return 0.365 # W/cfm
    else
      return 0.14 # W/cfm
    end
  end

  def self.get_boiler_curve(model, isCondensing)
    if isCondensing
      return create_curve_biquadratic(model, [1.058343061, -0.052650153, -0.0087272, -0.001742217, 0.00000333715, 0.000513723], "CondensingBoilerEff", 0.2, 1.0, 30.0, 85.0)
    else
      return create_curve_bicubic(model, [1.111720116, 0.078614078, -0.400425756, 0.0, -0.000156783, 0.009384599, 0.234257955, 1.32927e-06, -0.004446701, -1.22498e-05], "NonCondensingBoilerEff", 0.1, 1.0, 20.0, 80.0)
    end
  end

  def self.calculate_fan_pressure_rise(fan_eff, fan_power)
    # Calculates needed fan pressure rise to achieve a given fan power with an assumed efficiency.
    # Previously we calculated the fan efficiency from an assumed pressure rise, which could lead to
    # errors (fan efficiencies > 1).
    return fan_eff * fan_power / UnitConversions.convert(1.0, "cfm", "m^3/s") # Pa
  end

  def self.calculate_pump_head(pump_eff, pump_power)
    # Calculate needed pump head to achieve a given pump power with an assumed efficiency.
    # Previously we calculated the pump efficiency from an assumed pump head, which could lead to
    # errors (pump efficiencies > 1).
    return pump_eff * pump_power / UnitConversions.convert(1.0, "gal/min", "m^3/s") # Pa
  end

  def self.get_control_zone(thermal_zones)
    thermal_zones.each do |zone|
      next unless Geometry.zone_is_conditioned(zone)

      return zone
    end
    return nil
  end

  def self.existing_equipment(model, runner, thermal_zone)
    # Returns a list of equipment objects

    equipment = []
    hvac_types = []

    unitary_system_air_loops = self.get_unitary_system_air_loops(model, runner, thermal_zone)
    unitary_system_air_loops.each do |unitary_system_air_loop|
      system, clg_coil, htg_coil, air_loop = unitary_system_air_loop
      equipment << system

      hvac_type_cool = system.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACCoolType)
      hvac_types << hvac_type_cool.get if hvac_type_cool.is_initialized

      hvac_type_heat = system.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType)
      hvac_types << hvac_type_heat.get if hvac_type_heat.is_initialized
    end

    ptacs = self.get_ptacs(model, runner, thermal_zone)
    ptacs.each do |ptac|
      equipment << ptac
      hvac_types << ptac.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACCoolType).get
    end

    baseboards = self.get_baseboard_waters(model, runner, thermal_zone)
    baseboards.each do |baseboard|
      equipment << baseboard
      hvac_types << baseboard.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType).get
    end

    baseboards = self.get_baseboard_electrics(model, runner, thermal_zone)
    baseboards.each do |baseboard|
      equipment << baseboard
      hvac_types << baseboard.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType).get
    end

    unitary_system_hvac_map = self.get_unitary_system_hvac_map(model, runner, thermal_zone)
    unitary_system_hvac_map.each do |unitary_system_zone_hvac|
      system, clg_coil, htg_coil = unitary_system_zone_hvac
      next if htg_coil.nil?

      equipment << system
      hvac_types << system.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType).get
    end

    ideal_air = self.get_ideal_air(model, runner, thermal_zone)
    if not ideal_air.nil?
      equipment << ideal_air
      hvac_types << ideal_air.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACCoolType).get
      hvac_types << ideal_air.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType).get
    end

    hvac_types.uniq.each do |hvac_type|
      if hvac_type == Constants.ObjectNameCentralAirConditioner
        runner.registerInfo("Found central air conditioner in #{thermal_zone.name}.")
      elsif hvac_type == Constants.ObjectNameAirSourceHeatPump
        runner.registerInfo("Found air source heat pump in #{thermal_zone.name}.")
      elsif hvac_type == Constants.ObjectNameGroundSourceHeatPump
        runner.registerInfo("Found ground source heat pump in #{thermal_zone.name}.")
      elsif hvac_type == Constants.ObjectNameMiniSplitHeatPump
        runner.registerInfo("Found mini split heat pump in #{thermal_zone.name}.")
      elsif hvac_type == Constants.ObjectNameRoomAirConditioner
        runner.registerInfo("Found room air conditioner in #{thermal_zone.name}.")
      elsif hvac_type == Constants.ObjectNameIdealAirSystem
        runner.registerInfo("Found ideal air system in #{thermal_zone.name}.")
      elsif hvac_type == Constants.ObjectNameFurnace
        runner.registerInfo("Found furnace in #{thermal_zone.name}.")
      elsif hvac_type == Constants.ObjectNameElectricBaseboard
        runner.registerInfo("Found electric baseboard in #{thermal_zone.name}.")
      elsif hvac_type == Constants.ObjectNameBoiler
        runner.registerInfo("Found boiler serving #{thermal_zone.name}.")
      elsif hvac_type == Constants.ObjectNameUnitHeater
        runner.registerInfo("Found unit heater in #{thermal_zone.name}.")
      end
    end

    return equipment
  end

  def self.get_coils_from_hvac_equip(model, hvac_equip)
    # Returns the clg coil, htg coil, and supp htg coil as applicable
    clg_coil = nil
    htg_coil = nil
    supp_htg_coil = nil
    if hvac_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
      htg_coil = get_coil_from_hvac_component(hvac_equip.heatingCoil)
      clg_coil = get_coil_from_hvac_component(hvac_equip.coolingCoil)
      supp_htg_coil = get_coil_from_hvac_component(hvac_equip.supplementalHeatingCoil)
    elsif hvac_equip.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater
      htg_coil = get_coil_from_hvac_component(hvac_equip.heatingCoil)
    elsif hvac_equip.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner
      htg_coil = get_coil_from_hvac_component(hvac_equip.heatingCoil)
      if not htg_coil.nil? and htg_coil.availabilitySchedule == model.alwaysOffDiscreteSchedule
        # Don't return coil if it is unused
        htg_coil = nil
      end
      clg_coil = get_coil_from_hvac_component(hvac_equip.coolingCoil)
    end
    return clg_coil, htg_coil, supp_htg_coil
  end

  def self.get_coil_from_hvac_component(hvac_component)
    # Check for optional objects
    if hvac_component.is_a? OpenStudio::Model::OptionalHVACComponent
      return nil if not hvac_component.is_initialized

      hvac_component = hvac_component.get
    end

    # Cooling coils
    if hvac_component.to_CoilCoolingDXSingleSpeed.is_initialized
      return hvac_component.to_CoilCoolingDXSingleSpeed.get
    elsif hvac_component.to_CoilCoolingDXMultiSpeed.is_initialized
      return hvac_component.to_CoilCoolingDXMultiSpeed.get
    elsif hvac_component.to_CoilCoolingWaterToAirHeatPumpEquationFit.is_initialized
      return hvac_component.to_CoilCoolingWaterToAirHeatPumpEquationFit.get
    end

    # Heating coils
    if hvac_component.to_CoilHeatingDXSingleSpeed.is_initialized
      return hvac_component.to_CoilHeatingDXSingleSpeed.get
    elsif hvac_component.to_CoilHeatingDXMultiSpeed.is_initialized
      return hvac_component.to_CoilHeatingDXMultiSpeed.get
    elsif hvac_component.to_CoilHeatingGas.is_initialized
      return hvac_component.to_CoilHeatingGas.get
    elsif hvac_component.to_CoilHeatingElectric.is_initialized
      return hvac_component.to_CoilHeatingElectric.get
    elsif hvac_component.to_CoilHeatingWaterBaseboard.is_initialized
      return hvac_component.to_CoilHeatingWaterBaseboard.get
    elsif hvac_component.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
      return hvac_component.to_CoilHeatingWaterToAirHeatPumpEquationFit.get
    end

    return hvac_component
  end

  def self.get_unitary_system_from_air_loop_hvac(air_loop)
    # Returns the unitary system or nil
    air_loop.supplyComponents.each do |comp|
      next unless comp.to_AirLoopHVACUnitarySystem.is_initialized

      return comp.to_AirLoopHVACUnitarySystem.get
    end
    return nil
  end

  def self.get_unitary_system_air_loops(model, runner, thermal_zone)
    # Returns the unitary system(s), cooling coil(s), heating coil(s), and air loops(s) if available
    unitary_system_air_loops = []
    thermal_zone.airLoopHVACs.each do |air_loop|
      system = get_unitary_system_from_air_loop_hvac(air_loop)
      next if system.nil?

      clg_coil = nil
      htg_coil = nil
      if system.coolingCoil.is_initialized
        clg_coil = system.coolingCoil.get
      end
      if system.heatingCoil.is_initialized
        htg_coil = system.heatingCoil.get
      end
      unitary_system_air_loops << [system, clg_coil, htg_coil, air_loop]
    end
    return unitary_system_air_loops
  end

  def self.get_unitary_system_hvac_map(model, runner, thermal_zone)
    # Returns the unitary system, cooling coil, and heating coil if available
    unitary_system_hvac_map = []
    thermal_zone.equipment.each do |equipment|
      next unless equipment.to_AirLoopHVACUnitarySystem.is_initialized

      system = equipment.to_AirLoopHVACUnitarySystem.get
      clg_coil = nil
      htg_coil = nil
      if system.coolingCoil.is_initialized
        clg_coil = system.coolingCoil.get
      end
      if system.heatingCoil.is_initialized
        htg_coil = system.heatingCoil.get
      end
      unitary_system_hvac_map << [system, clg_coil, htg_coil]
    end
    return unitary_system_hvac_map
  end

  def self.get_ptacs(model, runner, thermal_zone)
    # Returns the PTAC(s) if available
    ptacs = []
    model.getZoneHVACPackagedTerminalAirConditioners.each do |ptac|
      next unless thermal_zone.handle.to_s == ptac.thermalZone.get.handle.to_s

      ptacs << ptac
    end
    return ptacs
  end

  def self.get_baseboard_waters(model, runner, thermal_zone)
    # Returns the water baseboard if available
    baseboards = []
    model.getZoneHVACBaseboardConvectiveWaters.each do |baseboard|
      next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s

      baseboards << baseboard
    end
    return baseboards
  end

  def self.get_baseboard_electrics(model, runner, thermal_zone)
    # Returns the electric baseboard if available
    baseboards = []
    model.getZoneHVACBaseboardConvectiveElectrics.each do |baseboard|
      next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s

      baseboards << baseboard
    end
    return baseboards
  end

  def self.get_dehumidifiers(model, runner, thermal_zone)
    # Returns the dehumidifier if available
    dehums = []
    model.getZoneHVACDehumidifierDXs.each do |dehum|
      next unless thermal_zone.handle.to_s == dehum.thermalZone.get.handle.to_s

      dehums << dehum
    end
    return dehums
  end

  def self.get_ideal_air(model, runner, thermal_zone)
    # Returns the heating ideal air loads system if available
    model.getZoneHVACIdealLoadsAirSystems.each do |ideal_air|
      next unless thermal_zone.handle.to_s == ideal_air.thermalZone.get.handle.to_s

      return ideal_air
    end
    return nil
  end

  def self.has_ducted_equipment(model, runner, air_loop)
    system = get_unitary_system_from_air_loop_hvac(air_loop)

    hvac_type_cool = system.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACCoolType)
    hvac_type_cool = hvac_type_cool.get if hvac_type_cool.is_initialized
    hvac_type_heat = system.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType)
    hvac_type_heat = hvac_type_heat.get if hvac_type_heat.is_initialized

    if [Constants.ObjectNameCentralAirConditioner,
        Constants.ObjectNameAirSourceHeatPump,
        Constants.ObjectNameGroundSourceHeatPump].include? hvac_type_cool
      return true
    elsif Constants.ObjectNameFurnace == hvac_type_heat
      return true
    elsif hvac_type_cool == Constants.ObjectNameMiniSplitHeatPump
      is_ducted = system.additionalProperties.getFeatureAsBoolean(Constants.DuctedInfoMiniSplitHeatPump).get
      if is_ducted
        return true
      end
    end

    return false
  end

  def self.calc_heating_and_cooling_seasons(model, weather, runner = nil)
    # Calculates heating/cooling seasons from BAHSP definition

    monthly_temps = weather.data.MonthlyAvgDrybulbs
    heat_design_db = weather.design.HeatingDrybulb

    # create basis lists with zero for every month
    cooling_season_temp_basis = Array.new(monthly_temps.length, 0.0)
    heating_season_temp_basis = Array.new(monthly_temps.length, 0.0)

    monthly_temps.each_with_index do |temp, i|
      if temp < 66.0
        heating_season_temp_basis[i] = 1.0
      elsif temp >= 66.0
        cooling_season_temp_basis[i] = 1.0
      end

      if (i == 0 or i == 11) and heat_design_db < 59.0
        heating_season_temp_basis[i] = 1.0
      elsif i == 6 or i == 7
        cooling_season_temp_basis[i] = 1.0
      end
    end

    cooling_season = Array.new(monthly_temps.length, 0.0)
    heating_season = Array.new(monthly_temps.length, 0.0)

    monthly_temps.each_with_index do |temp, i|
      # Heating overlaps with cooling at beginning of summer
      if i == 0 # January
        prevmonth = 11 # December
      else
        prevmonth = i - 1
      end

      if (heating_season_temp_basis[i] == 1.0 or (cooling_season_temp_basis[prevmonth] == 0.0 and cooling_season_temp_basis[i] == 1.0))
        heating_season[i] = 1.0
      else
        heating_season[i] = 0.0
      end

      if (cooling_season_temp_basis[i] == 1.0 or (heating_season_temp_basis[prevmonth] == 0.0 and heating_season_temp_basis[i] == 1.0))
        cooling_season[i] = 1.0
      else
        cooling_season[i] = 0.0
      end
    end

    # Find the first month of cooling and add one month
    (1...12).to_a.each do |i|
      if cooling_season[i] == 1.0
        cooling_season[i - 1] = 1.0
        break
      end
    end

    return heating_season, cooling_season
  end

  def self.calc_mshp_cfms_ton_cooling(cap_min_per, cap_max_per, cfm_ton_min, cfm_ton_max, num_speeds, dB_rated, wB_rated, shr)
    capacity_ratios_cooling = [0.0] * num_speeds
    cfms_cooling = [0.0] * num_speeds
    shrs_rated = [0.0] * num_speeds

    cap_nom_per = 1.0
    cfm_ton_nom = ((cfm_ton_max - cfm_ton_min) / (cap_max_per - cap_min_per)) * (cap_nom_per - cap_min_per) + cfm_ton_min

    ao = Psychrometrics.CoilAoFactor(dB_rated, wB_rated, Constants.Patm, UnitConversions.convert(1, "ton", "kBtu/hr"), cfm_ton_nom, shr)

    (0...num_speeds).each do |i|
      capacity_ratios_cooling[i] = cap_min_per + i * (cap_max_per - cap_min_per) / (num_speeds - 1)
      cfms_cooling[i] = cfm_ton_min + i * (cfm_ton_max - cfm_ton_min) / (num_speeds - 1)
      # Calculate the SHR for each speed. Use minimum value of 0.98 to prevent E+ bypass factor calculation errors
      shrs_rated[i] = [Psychrometrics.CalculateSHR(dB_rated, wB_rated, Constants.Patm, UnitConversions.convert(capacity_ratios_cooling[i], "ton", "kBtu/hr"), cfms_cooling[i], ao), 0.98].min
    end

    return cfms_cooling, capacity_ratios_cooling, shrs_rated
  end

  def self.calc_mshp_cooling_eirs(runner, coolingSEER, supplyFanPower, c_d, num_speeds, capacity_ratios_cooling, cfms_cooling, cOOL_EIR_FT_SPEC, cOOL_CAP_FT_SPEC)
    cops_Norm = [1.901, 1.859, 1.746, 1.609, 1.474, 1.353, 1.247, 1.156, 1.079, 1.0]
    fanPows_Norm = [0.604, 0.634, 0.670, 0.711, 0.754, 0.800, 0.848, 0.898, 0.948, 1.0]

    cooling_eirs = [0.0] * num_speeds
    fanPowsRated = [0.0] * num_speeds
    eers_Rated = [0.0] * num_speeds

    cop_maxSpeed = 3.5 # 3.5 is an initial guess, final value solved for below

    (0...num_speeds).each do |i|
      fanPowsRated[i] = supplyFanPower * fanPows_Norm[i]
      eers_Rated[i] = UnitConversions.convert(cop_maxSpeed, "W", "Btu/hr") * cops_Norm[i]
    end

    cop_maxSpeed_1 = cop_maxSpeed
    cop_maxSpeed_2 = cop_maxSpeed
    error = coolingSEER - calc_mshp_SEER_VariableSpeed(eers_Rated, c_d, capacity_ratios_cooling, cfms_cooling, fanPowsRated, true, cOOL_EIR_FT_SPEC, cOOL_CAP_FT_SPEC)
    error1 = error
    error2 = error

    itmax = 50 # maximum iterations
    cvg = false
    final_n = nil

    (1...itmax + 1).each do |n|
      final_n = n
      (0...num_speeds).each do |i|
        eers_Rated[i] = UnitConversions.convert(cop_maxSpeed, "W", "Btu/hr") * cops_Norm[i]
      end

      error = coolingSEER - calc_mshp_SEER_VariableSpeed(eers_Rated, c_d, capacity_ratios_cooling, cfms_cooling, fanPowsRated, true, cOOL_EIR_FT_SPEC, cOOL_CAP_FT_SPEC)

      cop_maxSpeed, cvg, cop_maxSpeed_1, error1, cop_maxSpeed_2, error2 = MathTools.Iterate(cop_maxSpeed, error, cop_maxSpeed_1, error1, cop_maxSpeed_2, error2, n, cvg)

      if cvg
        break
      end
    end

    if not cvg or final_n > itmax
      cop_maxSpeed = UnitConversions.convert(0.547 * coolingSEER - 0.104, "Btu/hr", "W") # Correlation developed from JonW's MatLab scripts. Only used is an EER cannot be found.
      runner.registerWarning('Mini-split heat pump COP iteration failed to converge. Setting to default value.')
    end

    (0...num_speeds).each do |i|
      cooling_eirs[i] = calc_EIR_from_EER(UnitConversions.convert(cop_maxSpeed, "W", "Btu/hr") * cops_Norm[i], fanPowsRated[i])
    end

    return cooling_eirs
  end

  def self.calc_mshp_SEER_VariableSpeed(eer_A, c_d, capacityRatio, cfm_Tons, fan_power_rated, isHeatPump, cOOL_EIR_FT_SPEC, cOOL_CAP_FT_SPEC)
    n_max = (eer_A.length - 1.0) - 3.0 # Don't use max speed
    n_min = 0.0
    n_int = (n_min + (n_max - n_min) / 3.0).ceil.to_i

    wBin = 67.0
    tout_B = 82.0
    tout_E = 87.0
    tout_F = 67.0

    eir_A2 = calc_EIR_from_EER(eer_A[n_max], fan_power_rated[n_max])
    eir_B2 = eir_A2 * MathTools.biquadratic(wBin, tout_B, cOOL_EIR_FT_SPEC[n_max])

    eir_Av = calc_EIR_from_EER(eer_A[n_int], fan_power_rated[n_int])
    eir_Ev = eir_Av * MathTools.biquadratic(wBin, tout_E, cOOL_EIR_FT_SPEC[n_int])

    eir_A1 = calc_EIR_from_EER(eer_A[n_min], fan_power_rated[n_min])
    eir_B1 = eir_A1 * MathTools.biquadratic(wBin, tout_B, cOOL_EIR_FT_SPEC[n_min])
    eir_F1 = eir_A1 * MathTools.biquadratic(wBin, tout_F, cOOL_EIR_FT_SPEC[n_min])

    q_A2 = capacityRatio[n_max]
    q_B2 = q_A2 * MathTools.biquadratic(wBin, tout_B, cOOL_CAP_FT_SPEC[n_max])
    q_Ev = capacityRatio[n_int] * MathTools.biquadratic(wBin, tout_E, cOOL_CAP_FT_SPEC[n_int])
    q_B1 = capacityRatio[n_min] * MathTools.biquadratic(wBin, tout_B, cOOL_CAP_FT_SPEC[n_min])
    q_F1 = capacityRatio[n_min] * MathTools.biquadratic(wBin, tout_F, cOOL_CAP_FT_SPEC[n_min])

    q_A2_net = q_A2 - fan_power_rated[n_max] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_max] / UnitConversions.convert(1, "ton", "Btu/hr")
    q_B2_net = q_B2 - fan_power_rated[n_max] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_max] / UnitConversions.convert(1, "ton", "Btu/hr")
    q_Ev_net = q_Ev - fan_power_rated[n_int] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_int] / UnitConversions.convert(1, "ton", "Btu/hr")
    q_B1_net = q_B1 - fan_power_rated[n_min] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_min] / UnitConversions.convert(1, "ton", "Btu/hr")
    q_F1_net = q_F1 - fan_power_rated[n_min] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_min] / UnitConversions.convert(1, "ton", "Btu/hr")

    p_A2 = UnitConversions.convert(q_A2 * eir_A2, "Btu", "Wh") + fan_power_rated[n_max] * cfm_Tons[n_max] / UnitConversions.convert(1, "ton", "Btu/hr")
    p_B2 = UnitConversions.convert(q_B2 * eir_B2, "Btu", "Wh") + fan_power_rated[n_max] * cfm_Tons[n_max] / UnitConversions.convert(1, "ton", "Btu/hr")
    p_Ev = UnitConversions.convert(q_Ev * eir_Ev, "Btu", "Wh") + fan_power_rated[n_int] * cfm_Tons[n_int] / UnitConversions.convert(1, "ton", "Btu/hr")
    p_B1 = UnitConversions.convert(q_B1 * eir_B1, "Btu", "Wh") + fan_power_rated[n_min] * cfm_Tons[n_min] / UnitConversions.convert(1, "ton", "Btu/hr")
    p_F1 = UnitConversions.convert(q_F1 * eir_F1, "Btu", "Wh") + fan_power_rated[n_min] * cfm_Tons[n_min] / UnitConversions.convert(1, "ton", "Btu/hr")

    q_k1_87 = q_F1_net + (q_B1_net - q_F1_net) / (82.0 - 67.0) * (87 - 67.0)
    q_k2_87 = q_B2_net + (q_A2_net - q_B2_net) / (95.0 - 82.0) * (87.0 - 82.0)
    n_Q = (q_Ev_net - q_k1_87) / (q_k2_87 - q_k1_87)
    m_Q = (q_B1_net - q_F1_net) / (82.0 - 67.0) * (1.0 - n_Q) + (q_A2_net - q_B2_net) / (95.0 - 82.0) * n_Q
    p_k1_87 = p_F1 + (p_B1 - p_F1) / (82.0 - 67.0) * (87.0 - 67.0)
    p_k2_87 = p_B2 + (p_A2 - p_B2) / (95.0 - 82.0) * (87.0 - 82.0)
    n_E = (p_Ev - p_k1_87) / (p_k2_87 - p_k1_87)
    m_E = (p_B1 - p_F1) / (82.0 - 67.0) * (1.0 - n_E) + (p_A2 - p_B2) / (95.0 - 82.0) * n_E

    c_T_1_1 = q_A2_net / (1.1 * (95.0 - 65.0))
    c_T_1_2 = q_F1_net
    c_T_1_3 = (q_B1_net - q_F1_net) / (82.0 - 67.0)
    t_1 = (c_T_1_2 - 67.0 * c_T_1_3 + 65.0 * c_T_1_1) / (c_T_1_1 - c_T_1_3)
    q_T_1 = q_F1_net + (q_B1_net - q_F1_net) / (82.0 - 67.0) * (t_1 - 67.0)
    p_T_1 = p_F1 + (p_B1 - p_F1) / (82.0 - 67.0) * (t_1 - 67.0)
    eer_T_1 = q_T_1 / p_T_1

    t_v = (q_Ev_net - 87.0 * m_Q + 65.0 * c_T_1_1) / (c_T_1_1 - m_Q)
    q_T_v = q_Ev_net + m_Q * (t_v - 87.0)
    p_T_v = p_Ev + m_E * (t_v - 87.0)
    eer_T_v = q_T_v / p_T_v

    c_T_2_1 = c_T_1_1
    c_T_2_2 = q_B2_net
    c_T_2_3 = (q_A2_net - q_B2_net) / (95.0 - 82.0)
    t_2 = (c_T_2_2 - 82.0 * c_T_2_3 + 65.0 * c_T_2_1) / (c_T_2_1 - c_T_2_3)
    q_T_2 = q_B2_net + (q_A2_net - q_B2_net) / (95.0 - 82.0) * (t_2 - 82.0)
    p_T_2 = p_B2 + (p_A2 - p_B2) / (95.0 - 82.0) * (t_2 - 82.0)
    eer_T_2 = q_T_2 / p_T_2

    d = (t_2**2 - t_1**2) / (t_v**2 - t_1**2)
    b = (eer_T_1 - eer_T_2 - d * (eer_T_1 - eer_T_v)) / (t_1 - t_2 - d * (t_1 - t_v))
    c = (eer_T_1 - eer_T_2 - b * (t_1 - t_2)) / (t_1**2 - t_2**2)
    a = eer_T_2 - b * t_2 - c * t_2**2

    e_tot = 0
    q_tot = 0
    t_bins = [67.0, 72.0, 77.0, 82.0, 87.0, 92.0, 97.0, 102.0]
    frac_hours = [0.214, 0.231, 0.216, 0.161, 0.104, 0.052, 0.018, 0.004]

    (0...8).each do |_i|
      bL = ((t_bins[_i] - 65.0) / (95.0 - 65.0)) * (q_A2_net / 1.1)
      q_k1 = q_F1_net + (q_B1_net - q_F1_net) / (82.0 - 67.0) * (t_bins[_i] - 67.0)
      p_k1 = p_F1 + (p_B1 - p_F1) / (82.0 - 67.0) * (t_bins[_i] - 67)
      q_k2 = q_B2_net + (q_A2_net - q_B2_net) / (95.0 - 82.0) * (t_bins[_i] - 82.0)
      p_k2 = p_B2 + (p_A2 - p_B2) / (95.0 - 82.0) * (t_bins[_i] - 82.0)

      if bL <= q_k1
        x_k1 = bL / q_k1
        q_Tj_N = x_k1 * q_k1 * frac_hours[_i]
        e_Tj_N = x_k1 * p_k1 * frac_hours[_i] / (1 - c_d * (1 - x_k1))
      elsif q_k1 < bL and bL <= q_k2
        q_Tj_N = bL * frac_hours[_i]
        eer_T_j = a + b * t_bins[_i] + c * t_bins[_i]**2
        e_Tj_N = q_Tj_N / eer_T_j
      else
        q_Tj_N = frac_hours[_i] * q_k2
        e_Tj_N = frac_hours[_i] * p_k2
      end

      q_tot = q_tot + q_Tj_N
      e_tot = e_tot + e_Tj_N
    end

    seer = q_tot / e_tot
    return seer
  end

  def self.calc_mshp_cfms_ton_heating(cap_min_per, cap_max_per, cfm_ton_min, cfm_ton_max, num_speeds)
    capacity_ratios_heating = [0.0] * num_speeds
    cfms_heating = [0.0] * num_speeds

    (0...num_speeds).each do |i|
      capacity_ratios_heating[i] = cap_min_per + i * (cap_max_per - cap_min_per) / (num_speeds - 1)
      cfms_heating[i] = cfm_ton_min + i * (cfm_ton_max - cfm_ton_min) / (num_speeds - 1)
    end

    return cfms_heating, capacity_ratios_heating
  end

  def self.calc_mshp_heating_eirs(runner, heatingHSPF, supplyFanPower, min_hp_temp, c_d, cfms_cooling, num_speeds, capacity_ratios_heating, cfms_heating, hEAT_EIR_FT_SPEC, hEAT_CAP_FT_SPEC)
    # COPs_Norm = [1.636, 1.757, 1.388, 1.240, 1.162, 1.119, 1.084, 1.062, 1.044, 1] #Report Avg
    # COPs_Norm = [1.792, 1.502, 1.308, 1.207, 1.145, 1.105, 1.077, 1.056, 1.041, 1] #BEopt Default

    cops_Norm = [1.792, 1.502, 1.308, 1.207, 1.145, 1.105, 1.077, 1.056, 1.041, 1] # BEopt Default
    fanPows_Norm = [0.577, 0.625, 0.673, 0.720, 0.768, 0.814, 0.861, 0.907, 0.954, 1]

    heating_eirs = [0.0] * num_speeds
    fanPowsRated = [0.0] * num_speeds
    cops_Rated = [0.0] * num_speeds

    cop_maxSpeed = 3.25 # 3.35 is an initial guess, final value solved for below

    (0...num_speeds).each do |i|
      fanPowsRated[i] = supplyFanPower * fanPows_Norm[i]
      cops_Rated[i] = cop_maxSpeed * cops_Norm[i]
    end

    cop_maxSpeed_1 = cop_maxSpeed
    cop_maxSpeed_2 = cop_maxSpeed
    error = heatingHSPF - calc_mshp_HSPF_VariableSpeed(cops_Rated, c_d, capacity_ratios_heating, cfms_heating, fanPowsRated, min_hp_temp, hEAT_EIR_FT_SPEC, hEAT_CAP_FT_SPEC)

    error1 = error
    error2 = error

    itmax = 50 # maximum iterations
    cvg = false
    final_n = nil

    (1...itmax + 1).each do |n|
      final_n = n
      (0...num_speeds).each do |i|
        cops_Rated[i] = cop_maxSpeed * cops_Norm[i]
      end

      error = heatingHSPF - calc_mshp_HSPF_VariableSpeed(cops_Rated, c_d, capacity_ratios_heating, cfms_cooling, fanPowsRated, min_hp_temp, hEAT_EIR_FT_SPEC, hEAT_CAP_FT_SPEC)

      cop_maxSpeed, cvg, cop_maxSpeed_1, error1, cop_maxSpeed_2, error2 = MathTools.Iterate(cop_maxSpeed, error, cop_maxSpeed_1, error1, cop_maxSpeed_2, error2, n, cvg)

      if cvg
        break
      end
    end

    if not cvg or final_n > itmax
      cop_maxSpeed = UnitConversions.convert(0.4174 * heatingHSPF - 1.1134, "Btu/hr", "W") # Correlation developed from JonW's MatLab scripts. Only used if a COP cannot be found.
      runner.registerWarning('Mini-split heat pump COP iteration failed to converge. Setting to default value.')
    end

    (0...num_speeds).each do |i|
      heating_eirs[i] = calc_EIR_from_COP(cop_maxSpeed * cops_Norm[i], fanPowsRated[i])
    end

    return heating_eirs
  end

  def self.calc_mshp_HSPF_VariableSpeed(cop_47, c_d, capacityRatio, cfm_Tons, fan_power_rated, min_temp, hEAT_EIR_FT_SPEC, hEAT_CAP_FT_SPEC)
    n_max = (cop_47.length - 1.0) #-3 # Don't use max speed
    n_min = 0
    n_int = (n_min + (n_max - n_min) / 3.0).ceil.to_i

    tin = 70.0
    tout_3 = 17.0
    tout_2 = 35.0
    tout_0 = 62.0

    eir_H1_2 = calc_EIR_from_COP(cop_47[n_max], fan_power_rated[n_max])
    eir_H3_2 = eir_H1_2 * MathTools.biquadratic(tin, tout_3, hEAT_EIR_FT_SPEC[n_max])

    eir_adjv = calc_EIR_from_COP(cop_47[n_int], fan_power_rated[n_int])
    eir_H2_v = eir_adjv * MathTools.biquadratic(tin, tout_2, hEAT_EIR_FT_SPEC[n_int])

    eir_H1_1 = calc_EIR_from_COP(cop_47[n_min], fan_power_rated[n_min])
    eir_H0_1 = eir_H1_1 * MathTools.biquadratic(tin, tout_0, hEAT_EIR_FT_SPEC[n_min])

    q_H1_2 = capacityRatio[n_max]
    q_H3_2 = q_H1_2 * MathTools.biquadratic(tin, tout_3, hEAT_CAP_FT_SPEC[n_max])

    q_H2_v = capacityRatio[n_int] * MathTools.biquadratic(tin, tout_2, hEAT_CAP_FT_SPEC[n_int])

    q_H1_1 = capacityRatio[n_min]
    q_H0_1 = q_H1_1 * MathTools.biquadratic(tin, tout_0, hEAT_CAP_FT_SPEC[n_min])

    q_H1_2_net = q_H1_2 + fan_power_rated[n_max] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_max] / UnitConversions.convert(1, "ton", "Btu/hr")
    q_H3_2_net = q_H3_2 + fan_power_rated[n_max] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_max] / UnitConversions.convert(1, "ton", "Btu/hr")
    q_H2_v_net = q_H2_v + fan_power_rated[n_int] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_int] / UnitConversions.convert(1, "ton", "Btu/hr")
    q_H1_1_net = q_H1_1 + fan_power_rated[n_min] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_min] / UnitConversions.convert(1, "ton", "Btu/hr")
    q_H0_1_net = q_H0_1 + fan_power_rated[n_min] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_min] / UnitConversions.convert(1, "ton", "Btu/hr")

    p_H1_2 = q_H1_2 * eir_H1_2 + fan_power_rated[n_max] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_max] / UnitConversions.convert(1, "ton", "Btu/hr")
    p_H3_2 = q_H3_2 * eir_H3_2 + fan_power_rated[n_max] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_max] / UnitConversions.convert(1, "ton", "Btu/hr")
    p_H2_v = q_H2_v * eir_H2_v + fan_power_rated[n_int] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_int] / UnitConversions.convert(1, "ton", "Btu/hr")
    p_H1_1 = q_H1_1 * eir_H1_1 + fan_power_rated[n_min] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_min] / UnitConversions.convert(1, "ton", "Btu/hr")
    p_H0_1 = q_H0_1 * eir_H0_1 + fan_power_rated[n_min] * UnitConversions.convert(1, "W", "Btu/hr") * cfm_Tons[n_min] / UnitConversions.convert(1, "ton", "Btu/hr")

    q_H35_2 = 0.9 * (q_H3_2_net + 0.6 * (q_H1_2_net - q_H3_2_net))
    p_H35_2 = 0.985 * (p_H3_2 + 0.6 * (p_H1_2 - p_H3_2))
    q_H35_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (35.0 - 47.0)
    p_H35_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (35.0 - 47.0)
    n_Q = (q_H2_v_net - q_H35_1) / (q_H35_2 - q_H35_1)
    m_Q = (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (1 - n_Q) + n_Q * (q_H35_2 - q_H3_2_net) / (35.0 - 17.0)
    n_E = (p_H2_v - p_H35_1) / (p_H35_2 - p_H35_1)
    m_E = (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (1.0 - n_E) + n_E * (p_H35_2 - p_H3_2) / (35.0 - 17.0)

    t_OD = 5.0
    dHR = q_H1_2_net * (65.0 - t_OD) / 60.0

    c_T_3_1 = q_H1_1_net
    c_T_3_2 = (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0)
    c_T_3_3 = 0.77 * dHR / (65.0 - t_OD)
    t_3 = (47.0 * c_T_3_2 + 65.0 * c_T_3_3 - c_T_3_1) / (c_T_3_2 + c_T_3_3)
    q_HT3_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (t_3 - 47.0)
    p_HT3_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (t_3 - 47.0)
    cop_T3_1 = q_HT3_1 / p_HT3_1

    c_T_v_1 = q_H2_v_net
    c_T_v_3 = c_T_3_3
    t_v = (35.0 * m_Q + 65.0 * c_T_v_3 - c_T_v_1) / (m_Q + c_T_v_3)
    q_HTv_v = q_H2_v_net + m_Q * (t_v - 35.0)
    p_HTv_v = p_H2_v + m_E * (t_v - 35.0)
    cop_Tv_v = q_HTv_v / p_HTv_v

    c_T_4_1 = q_H3_2_net
    c_T_4_2 = (q_H35_2 - q_H3_2_net) / (35.0 - 17.0)
    c_T_4_3 = c_T_v_3
    t_4 = (17.0 * c_T_4_2 + 65.0 * c_T_4_3 - c_T_4_1) / (c_T_4_2 + c_T_4_3)
    q_HT4_2 = q_H3_2_net + (q_H35_2 - q_H3_2_net) / (35.0 - 17.0) * (t_4 - 17.0)
    p_HT4_2 = p_H3_2 + (p_H35_2 - p_H3_2) / (35.0 - 17.0) * (t_4 - 17.0)
    cop_T4_2 = q_HT4_2 / p_HT4_2

    d = (t_3**2 - t_4**2) / (t_v**2 - t_4**2)
    b = (cop_T4_2 - cop_T3_1 - d * (cop_T4_2 - cop_Tv_v)) / (t_4 - t_3 - d * (t_4 - t_v))
    c = (cop_T4_2 - cop_T3_1 - b * (t_4 - t_3)) / (t_4**2 - t_3**2)
    a = cop_T4_2 - b * t_4 - c * t_4**2

    t_bins = [62.0, 57.0, 52.0, 47.0, 42.0, 37.0, 32.0, 27.0, 22.0, 17.0, 12.0, 7.0, 2.0, -3.0, -8.0]
    frac_hours = [0.132, 0.111, 0.103, 0.093, 0.100, 0.109, 0.126, 0.087, 0.055, 0.036, 0.026, 0.013, 0.006, 0.002, 0.001]

    # T_off = min_temp
    t_off = 10.0
    t_on = t_off + 4.0
    etot = 0
    bLtot = 0

    (0...15).each do |_i|
      bL = ((65.0 - t_bins[_i]) / (65.0 - t_OD)) * 0.77 * dHR

      q_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (t_bins[_i] - 47.0)
      p_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (t_bins[_i] - 47.0)

      if t_bins[_i] <= 17.0 or t_bins[_i] >= 45.0
        q_2 = q_H3_2_net + (q_H1_2_net - q_H3_2_net) * (t_bins[_i] - 17.0) / (47.0 - 17.0)
        p_2 = p_H3_2 + (p_H1_2 - p_H3_2) * (t_bins[_i] - 17.0) / (47.0 - 17.0)
      else
        q_2 = q_H3_2_net + (q_H35_2 - q_H3_2_net) * (t_bins[_i] - 17) / (35.0 - 17.0)
        p_2 = p_H3_2 + (p_H35_2 - p_H3_2) * (t_bins[_i] - 17.0) / (35.0 - 17.0)
      end

      if t_bins[_i] <= t_off
        delta = 0
      elsif t_bins[_i] >= t_on
        delta = 1.0
      else
        delta = 0.5
      end

      if bL <= q_1
        x_1 = bL / q_1
        e_Tj_n = delta * x_1 * p_1 * frac_hours[_i] / (1.0 - c_d * (1.0 - x_1))
      elsif q_1 < bL and bL <= q_2
        cop_T_j = a + b * t_bins[_i] + c * t_bins[_i]**2
        e_Tj_n = delta * frac_hours[_i] * bL / cop_T_j + (1.0 - delta) * bL * (frac_hours[_i])
      else
        e_Tj_n = delta * frac_hours[_i] * p_2 + frac_hours[_i] * (bL - delta * q_2)
      end

      bLtot = bLtot + frac_hours[_i] * bL
      etot = etot + e_Tj_n
    end

    hspf = bLtot / UnitConversions.convert(etot, "Btu/hr", "W")
    return hspf
  end

  def self.get_constant_schedule(model, value)
    s = OpenStudio::Model::ScheduleConstant.new(model)
    s.setName("Sequential Fraction Schedule")
    s.setValue(value)
    Schedule.set_schedule_type_limits(model, s, Constants.ScheduleTypeLimitsFraction)
    return s
  end
end
