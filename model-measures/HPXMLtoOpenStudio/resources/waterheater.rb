require_relative "constants"
require_relative "util"
require_relative "weather"
require_relative "geometry"
require_relative "schedules"
require_relative "unit_conversions"
require_relative "psychrometrics"
require_relative "hotwater_appliances"

class Waterheater
  def self.apply_tank(model, runner, space, fuel_type, cap, vol, ef,
                      re, t_set, oncycle_p, offcycle_p, ec_adj, nbeds, dhw_map, sys_id, desuperheater_clg_coil, jacket_r)

    if fuel_type == Constants.FuelTypeElectric
      re = 0.98 # recovery efficiency set by fiat
      oncycle_p = 0
      offcycle_p = 0
    end

    runner.registerInfo("A new plant loop for DHW will be added to the model")
    runner.registerInitialCondition("No water heater model currently exists")
    loop = create_new_loop(model, Constants.PlantLoopDomesticWater, t_set, Constants.WaterHeaterTypeTank)
    dhw_map[sys_id] << loop

    new_pump = create_new_pump(model)
    new_pump.addToNode(loop.supplyInletNode)

    new_manager = create_new_schedule_manager(t_set, model, Constants.WaterHeaterTypeTank)
    new_manager.addToNode(loop.supplyOutletNode)

    act_vol = calc_storage_tank_actual_vol(vol, fuel_type)
    u, ua, eta_c = calc_tank_UA(act_vol, fuel_type, ef, re, cap, Constants.WaterHeaterTypeTank, 0, jacket_r, runner)
    new_heater = create_new_heater(Constants.ObjectNameWaterHeater, cap, fuel_type, act_vol, ef, t_set, space, oncycle_p, offcycle_p, Constants.WaterHeaterTypeTank, nbeds, model, runner, ua, eta_c)
    dhw_map[sys_id] << new_heater

    loop.addSupplyBranchForComponent(new_heater)

    dhw_map[sys_id] << add_ec_adj(model, runner, new_heater, ec_adj, space, fuel_type, Constants.WaterHeaterTypeTank)

    if not desuperheater_clg_coil.nil?
      add_desuperheater(model, t_set, new_heater, desuperheater_clg_coil, Constants.WaterHeaterTypeTank, fuel_type, space, loop, runner, ec_adj).each { |e| dhw_map[sys_id] << e }
    end
    return true
  end

  def self.apply_tankless(model, runner, space, fuel_type, cap, ef,
                          cd, t_set, oncycle_p, offcycle_p, ec_adj, nbeds, dhw_map, sys_id, desuperheater_clg_coil)

    if cd < 0 or cd > 1
      runner.registerError("Cycling derate must be at least 0 and at most 1.")
      return false
    end
    if fuel_type == Constants.FuelTypeElectric
      oncycle_p = 0
      offcycle_p = 0
    end

    runner.registerInfo("A new plant loop for DHW will be added to the model")
    runner.registerInitialCondition("No water heater model currently exists")
    loop = Waterheater.create_new_loop(model, Constants.PlantLoopDomesticWater, t_set, Constants.WaterHeaterTypeTankless)
    dhw_map[sys_id] << loop

    new_pump = create_new_pump(model)
    new_pump.addToNode(loop.supplyInletNode)

    new_manager = create_new_schedule_manager(t_set, model, Constants.WaterHeaterTypeTankless)
    new_manager.addToNode(loop.supplyOutletNode)

    act_vol = 1.0
    u, ua, eta_c = calc_tank_UA(act_vol, fuel_type, ef, nil, cap, Constants.WaterHeaterTypeTankless, cd, nil, runner)
    new_heater = create_new_heater(Constants.ObjectNameWaterHeater, cap, fuel_type, act_vol, ef, t_set, space, oncycle_p, offcycle_p, Constants.WaterHeaterTypeTankless, nbeds, model, runner, ua, eta_c)
    dhw_map[sys_id] << new_heater

    loop.addSupplyBranchForComponent(new_heater)

    dhw_map[sys_id] << add_ec_adj(model, runner, new_heater, ec_adj, space, fuel_type, Constants.WaterHeaterTypeTankless)

    if not desuperheater_clg_coil.nil?
      add_desuperheater(model, t_set, new_heater, desuperheater_clg_coil, Constants.WaterHeaterTypeTank, fuel_type, space, loop, runner, ec_adj).each { |e| dhw_map[sys_id] << e }
    end
    return true
  end

  def self.apply_heatpump(model, runner, space, weather, t_set, vol, ef,
                          ec_adj, nbeds, dhw_map, sys_id, jacket_r)

    # Hard coded values for things that wouldn't be captured by hpxml
    int_factor = 1.0 # unitless
    temp_depress = 0.0 # F
    ducting = "none"

    # Based on Ecotope lab testing of most recent AO Smith HPWHs (series HPTU)
    if vol <= 58.0
      tank_ua = 3.6 # Btu/h-R
    elsif vol <= 73.0
      tank_ua = 4.0 # Btu/h-R
    else
      tank_ua = 4.7 # Btu/h-R
    end

    e_cap = 4.5 # kW
    min_temp = 42.0 # F
    max_temp = 120.0 # F
    cap = 0.5 # kW
    shr = 0.88 # unitless
    airflow_rate = 181.0 # cfm
    fan_power = 0.0462 # FIXME
    parasitics = 3.0 # W

    # Calculate the COP based on EF
    uef = (0.60522 + ef) / 1.2101
    cop = 1.174536058 * uef # Based on simulation of the UEF test procedure at varying COPs

    obj_name_hpwh = Constants.ObjectNameWaterHeater

    alt = weather.header.Altitude
    if space.nil? # Located outside
      water_heater_tz = nil
    else
      water_heater_tz = space.thermalZone.get
    end

    runner.registerInfo("A new plant loop for DHW will be added to the model")
    runner.registerInitialCondition("There is no existing water heater")
    loop = create_new_loop(model, Constants.PlantLoopDomesticWater, t_set, Constants.WaterHeaterTypeHeatPump)
    dhw_map[sys_id] << loop

    new_pump = create_new_pump(model)
    new_pump.addToNode(loop.supplyInletNode)

    new_manager = create_new_schedule_manager(t_set, model, Constants.WaterHeaterTypeHeatPump)
    new_manager.addToNode(loop.supplyOutletNode)

    # Calculate some geometry parameters for UA, the location of sensors and heat sources in the tank

    h_tank = 0.0188 * vol + 0.0935 # Linear relationship that gets GE height at 50 gal and AO Smith height at 80 gal
    v_actual = 0.9 * vol
    pi = Math::PI
    r_tank = (UnitConversions.convert(v_actual, "gal", "m^3") / (pi * h_tank))**0.5
    a_tank = 2 * pi * r_tank * (r_tank + h_tank)

    a_side = 2 * pi * UnitConversions.convert(r_tank, "m", "ft") * UnitConversions.convert(h_tank, "m", "ft") # sqft
    tank_ua = apply_tank_jacket(jacket_r, ef, Constants.FuelTypeElectric, tank_ua, a_side)
    u_tank = (5.678 * tank_ua) / UnitConversions.convert(a_tank, "m^2", "ft^2")

    h_UE = (1 - (3.5 / 12)) * h_tank # in the 3rd node of the tank (counting from top)
    h_LE = (1 - (9.5 / 12)) * h_tank # in the 10th node of the tank (counting from top)
    h_condtop = (1 - (5.5 / 12)) * h_tank # in the 6th node of the tank (counting from top)
    h_condbot = 0.01 # bottom node
    h_hpctrl_up = (1 - (2.5 / 12)) * h_tank # in the 3rd node of the tank
    h_hpctrl_low = (1 - (8.5 / 12)) * h_tank # in the 9th node of the tank

    # Calculate an altitude adjusted rated evaporator wetbulb temperature
    rated_ewb_F = 56.4
    rated_edb_F = 67.5
    rated_ewb = UnitConversions.convert(rated_ewb_F, "F", "C")
    rated_edb = UnitConversions.convert(rated_edb_F, "F", "C")
    w_rated = Psychrometrics.w_fT_Twb_P(rated_edb_F, rated_ewb_F, 14.7)
    dp_rated = Psychrometrics.Tdp_fP_w(14.7, w_rated)
    p_atm = Psychrometrics.Pstd_fZ(alt)
    w_adj = Psychrometrics.w_fT_Twb_P(dp_rated, dp_rated, p_atm)
    twb_adj = Psychrometrics.Twb_fT_w_P(rated_edb_F, w_adj, p_atm)

    # Add in schedules for Tamb, RHamb, and the compressor
    hpwh_tamb = OpenStudio::Model::ScheduleConstant.new(model)
    hpwh_tamb.setName("#{obj_name_hpwh} Tamb act")
    hpwh_tamb.setValue(23)

    hpwh_rhamb = OpenStudio::Model::ScheduleConstant.new(model)
    hpwh_rhamb.setName("#{obj_name_hpwh} RHamb act")
    hpwh_rhamb.setValue(0.5)

    if ducting == Constants.VentTypeSupply or ducting == Constants.VentTypeBalanced
      hpwh_tamb2 = OpenStudio::Model::ScheduleConstant.new(model)
      hpwh_tamb2.setName("#{obj_name_hpwh} Tamb act2")
      hpwh_tamb2.setValue(23)
    end

    tset_C = UnitConversions.convert(t_set, "F", "C").to_f.round(2)
    hp_setpoint = OpenStudio::Model::ScheduleConstant.new(model)
    hp_setpoint.setName("#{obj_name_hpwh} WaterHeaterHPSchedule")
    hp_setpoint.setValue(tset_C)

    hpwh_bottom_element_sp = OpenStudio::Model::ScheduleConstant.new(model)
    hpwh_bottom_element_sp.setName("#{obj_name_hpwh} BottomElementSetpoint")

    hpwh_top_element_sp = OpenStudio::Model::ScheduleConstant.new(model)
    hpwh_top_element_sp.setName("#{obj_name_hpwh} TopElementSetpoint")

    hpwh_bottom_element_sp.setValue(-60)
    sp = (tset_C - 9.0001).round(4)
    hpwh_top_element_sp.setValue(sp)

    # WaterHeater:HeatPump:WrappedCondenser
    hpwh = OpenStudio::Model::WaterHeaterHeatPumpWrappedCondenser.new(model)
    hpwh.setName("#{obj_name_hpwh} hpwh")
    hpwh.setCompressorSetpointTemperatureSchedule(hp_setpoint)
    hpwh.setDeadBandTemperatureDifference(3.89)
    hpwh.setCondenserBottomLocation(h_condbot)
    hpwh.setCondenserTopLocation(h_condtop)
    hpwh.setEvaporatorAirFlowRate(UnitConversions.convert(airflow_rate, "ft^3/min", "m^3/s"))
    hpwh.setInletAirConfiguration("Schedule")
    hpwh.setInletAirTemperatureSchedule(hpwh_tamb)
    hpwh.setInletAirHumiditySchedule(hpwh_rhamb)
    hpwh.setMinimumInletAirTemperatureforCompressorOperation(UnitConversions.convert(min_temp, "F", "C"))
    hpwh.setMaximumInletAirTemperatureforCompressorOperation(UnitConversions.convert(max_temp, "F", "C"))
    hpwh.setCompressorLocation("Schedule")
    hpwh.setCompressorAmbientTemperatureSchedule(hpwh_tamb)
    hpwh.setFanPlacement("DrawThrough")
    hpwh.setOnCycleParasiticElectricLoad(0)
    hpwh.setOffCycleParasiticElectricLoad(0)
    hpwh.setParasiticHeatRejectionLocation("Outdoors")
    hpwh.setTankElementControlLogic("MutuallyExclusive")
    hpwh.setControlSensor1HeightInStratifiedTank(h_hpctrl_up)
    hpwh.setControlSensor1Weight(0.75)
    hpwh.setControlSensor2HeightInStratifiedTank(h_hpctrl_low)
    dhw_map[sys_id] << hpwh

    # Curves
    hpwh_cap = OpenStudio::Model::CurveBiquadratic.new(model)
    hpwh_cap.setName("HPWH-Cap-fT")
    hpwh_cap.setCoefficient1Constant(0.563)
    hpwh_cap.setCoefficient2x(0.0437)
    hpwh_cap.setCoefficient3xPOW2(0.000039)
    hpwh_cap.setCoefficient4y(0.0055)
    hpwh_cap.setCoefficient5yPOW2(-0.000148)
    hpwh_cap.setCoefficient6xTIMESY(-0.000145)
    hpwh_cap.setMinimumValueofx(0)
    hpwh_cap.setMaximumValueofx(100)
    hpwh_cap.setMinimumValueofy(0)
    hpwh_cap.setMaximumValueofy(100)

    hpwh_cop = OpenStudio::Model::CurveBiquadratic.new(model)
    hpwh_cop.setName("HPWH-COP-fT")
    hpwh_cop.setCoefficient1Constant(1.1332)
    hpwh_cop.setCoefficient2x(0.063)
    hpwh_cop.setCoefficient3xPOW2(-0.0000979)
    hpwh_cop.setCoefficient4y(-0.00972)
    hpwh_cop.setCoefficient5yPOW2(-0.0000214)
    hpwh_cop.setCoefficient6xTIMESY(-0.000686)
    hpwh_cop.setMinimumValueofx(0)
    hpwh_cop.setMaximumValueofx(100)
    hpwh_cop.setMinimumValueofy(0)
    hpwh_cop.setMaximumValueofy(100)

    # Coil:WaterHeating:AirToWaterHeatPump:Wrapped
    coil = hpwh.dXCoil.to_CoilWaterHeatingAirToWaterHeatPumpWrapped.get
    coil.setName("#{obj_name_hpwh} coil")
    coil.setRatedHeatingCapacity(UnitConversions.convert(cap, "kW", "W") * cop)
    coil.setRatedCOP(cop)
    coil.setRatedSensibleHeatRatio(shr)
    coil.setRatedEvaporatorInletAirDryBulbTemperature(rated_edb)
    coil.setRatedEvaporatorInletAirWetBulbTemperature(UnitConversions.convert(twb_adj, "F", "C"))
    coil.setRatedCondenserWaterTemperature(48.89)
    coil.setRatedEvaporatorAirFlowRate(UnitConversions.convert(airflow_rate, "ft^3/min", "m^3/s"))
    coil.setEvaporatorFanPowerIncludedinRatedCOP(true)
    coil.setEvaporatorAirTemperatureTypeforCurveObjects("WetBulbTemperature")
    coil.setHeatingCapacityFunctionofTemperatureCurve(hpwh_cap)
    coil.setHeatingCOPFunctionofTemperatureCurve(hpwh_cop)
    coil.setMaximumAmbientTemperatureforCrankcaseHeaterOperation(0)
    dhw_map[sys_id] << coil

    # WaterHeater:Stratified
    tank = hpwh.tank.to_WaterHeaterStratified.get
    tank.setName("#{obj_name_hpwh} tank")
    tank.setEndUseSubcategory("Domestic Hot Water")
    tank.setTankVolume(UnitConversions.convert(v_actual, "gal", "m^3"))
    tank.setTankHeight(h_tank)
    tank.setMaximumTemperatureLimit(90)
    tank.setHeaterPriorityControl("MasterSlave")
    tank.setHeater1SetpointTemperatureSchedule(hpwh_top_element_sp) # Overwritten later by EMS
    tank.setHeater1Capacity(UnitConversions.convert(e_cap, "kW", "W"))
    tank.setHeater1Height(h_UE)
    tank.setHeater1DeadbandTemperatureDifference(18.5)
    tank.setHeater2SetpointTemperatureSchedule(hpwh_bottom_element_sp)
    tank.setHeater2Capacity(UnitConversions.convert(e_cap, "kW", "W"))
    tank.setHeater2Height(h_LE)
    tank.setHeater2DeadbandTemperatureDifference(3.89)
    tank.setHeaterFuelType("Electricity")
    tank.setHeaterThermalEfficiency(1)
    tank.setOffCycleParasiticFuelConsumptionRate(parasitics)
    tank.setOffCycleParasiticFuelType("Electricity")
    tank.setOnCycleParasiticFuelConsumptionRate(parasitics)
    tank.setOnCycleParasiticFuelType("Electricity")
    tank.setAmbientTemperatureIndicator("Schedule")
    tank.setUniformSkinLossCoefficientperUnitAreatoAmbientTemperature(u_tank)
    if ducting == Constants.VentTypeSupply or ducting == Constants.VentTypeBalanced
      tank.setAmbientTemperatureSchedule(hpwh_tamb2)
    else
      tank.setAmbientTemperatureSchedule(hpwh_tamb)
    end
    tank.setNumberofNodes(6)
    tank.setAdditionalDestratificationConductivity(0)
    tank.setNode1AdditionalLossCoefficient(0)
    tank.setNode2AdditionalLossCoefficient(0)
    tank.setNode3AdditionalLossCoefficient(0)
    tank.setNode4AdditionalLossCoefficient(0)
    tank.setNode5AdditionalLossCoefficient(0)
    tank.setNode6AdditionalLossCoefficient(0)
    tank.setNode7AdditionalLossCoefficient(0)
    tank.setNode8AdditionalLossCoefficient(0)
    tank.setNode9AdditionalLossCoefficient(0)
    tank.setNode10AdditionalLossCoefficient(0)
    tank.setNode11AdditionalLossCoefficient(0)
    tank.setNode12AdditionalLossCoefficient(0)
    tank.setUseSideDesignFlowRate((UnitConversions.convert(v_actual, "gal", "m^3")) / 60.1)
    tank.setSourceSideDesignFlowRate(0)
    tank.setSourceSideFlowControlMode("")
    tank.setSourceSideInletHeight(0)
    tank.setSourceSideOutletHeight(0)
    dhw_map[sys_id] << tank

    # Fan:OnOff
    fan = hpwh.fan.to_FanOnOff.get
    fan.setName("#{obj_name_hpwh} fan")
    fan.setFanEfficiency(65.0 / fan_power * UnitConversions.convert(1.0, "ft^3/min", "m^3/s"))
    fan.setPressureRise(65.0)
    fan.setMaximumFlowRate(UnitConversions.convert(airflow_rate, "ft^3/min", "m^3/s"))
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    fan.setEndUseSubcategory("Domestic Hot Water")

    # Add in EMS program for HPWH interaction with the living space & ambient air temperature depression
    if int_factor != 1 and ducting != "none"
      runner.registerWarning("Interaction factor must be 1 when ducting a HPWH. The input interaction factor value will be ignored and a value of 1 will be used instead.")
      int_factor = 1
    end

    if not space.nil? # If not located outside
      # Add in other equipment objects for sensible/latent gains
      hpwh_sens_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      hpwh_sens_def.setName("#{obj_name_hpwh} sens")
      hpwh_sens = OpenStudio::Model::OtherEquipment.new(hpwh_sens_def)
      hpwh_sens.setName(hpwh_sens_def.name.to_s)
      hpwh_sens.setSpace(space)
      hpwh_sens_def.setDesignLevel(0)
      hpwh_sens_def.setFractionRadiant(0)
      hpwh_sens_def.setFractionLatent(0)
      hpwh_sens_def.setFractionLost(0)
      hpwh_sens.setSchedule(model.alwaysOnDiscreteSchedule)

      hpwh_lat_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      hpwh_lat_def.setName("#{obj_name_hpwh} lat")
      hpwh_lat = OpenStudio::Model::OtherEquipment.new(hpwh_lat_def)
      hpwh_lat.setName(hpwh_lat_def.name.to_s)
      hpwh_lat.setSpace(space)
      hpwh_lat_def.setDesignLevel(0)
      hpwh_lat_def.setFractionRadiant(0)
      hpwh_lat_def.setFractionLatent(1)
      hpwh_lat_def.setFractionLost(0)
      hpwh_lat.setSchedule(model.alwaysOnDiscreteSchedule)
    end

    # If ducted to outside, get outdoor air T & RH and add a separate actuator for the space temperature for tank losses
    if ducting == Constants.VentTypeSupply or ducting == Constants.VentTypeBalanced

      tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Zone Outdoor Air Drybulb Temperature")
      tout_sensor.setName("#{obj_name_hpwh} Tout")
      tout_sensor.setKeyName(living_zone.name.to_s)

      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Zone Outdoor Air Relative Humidity")
      sensor.setName("#{obj_name_hpwh} RHout")
      sensor.setKeyName(living_zone.name.to_s)

      hpwh_tamb2 = OpenStudio::Model::ScheduleConstant.new(model)
      hpwh_tamb2.setName("#{obj_name_hpwh} Tamb act2")
      hpwh_tamb2.setValue(23)

      tamb_act2_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_tamb2, "Schedule:Constant", "Schedule Value")
      tamb_act2_actuator.setName("#{obj_name_hpwh} Tamb act2")

    end

    # EMS Sensors: Space Temperature & RH, HP sens and latent loads, tank losses, fan power
    if water_heater_tz.nil? # Located outside
      amb_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Site Outdoor Air Drybulb Temperature")
      amb_temp_sensor.setName("#{obj_name_hpwh} amb temp")
      amb_temp_sensor.setKeyName("Environment")

      amb_rh_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Site Outdoor Air Relative Humidity")
      amb_rh_sensor.setName("#{obj_name_hpwh} amb rh")
      amb_rh_sensor.setKeyName("Environment")
    else
      amb_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Zone Mean Air Temperature")
      amb_temp_sensor.setName("#{obj_name_hpwh} amb temp")
      amb_temp_sensor.setKeyName(water_heater_tz.name.to_s)

      amb_rh_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Zone Air Relative Humidity")
      amb_rh_sensor.setName("#{obj_name_hpwh} amb rh")
      amb_rh_sensor.setKeyName(water_heater_tz.name.to_s)
    end

    tl_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater Heat Loss Rate")
    tl_sensor.setName("#{obj_name_hpwh} tl")
    tl_sensor.setKeyName("#{obj_name_hpwh} tank")

    sens_cool_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling Coil Sensible Cooling Rate")
    sens_cool_sensor.setName("#{obj_name_hpwh} sens cool")
    sens_cool_sensor.setKeyName("#{obj_name_hpwh} coil")

    lat_cool_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling Coil Latent Cooling Rate")
    lat_cool_sensor.setName("#{obj_name_hpwh} lat cool")
    lat_cool_sensor.setKeyName("#{obj_name_hpwh} coil")

    fan_power_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Fan Electric Power")
    fan_power_sensor.setName("#{obj_name_hpwh} fan pwr")
    fan_power_sensor.setKeyName("#{obj_name_hpwh} fan")

    # EMS Actuators: Inlet T & RH, sensible and latent gains to the space
    tamb_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_tamb, "Schedule:Constant", "Schedule Value")
    tamb_act_actuator.setName("#{obj_name_hpwh} Tamb act")

    rhamb_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_rhamb, "Schedule:Constant", "Schedule Value")
    rhamb_act_actuator.setName("#{obj_name_hpwh} RHamb act")

    if not space.nil?
      sens_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_sens, "OtherEquipment", "Power Level")
      sens_act_actuator.setName("#{hpwh_sens.name} act")

      lat_act_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_lat, "OtherEquipment", "Power Level")
      lat_act_actuator.setName("#{hpwh_lat.name} act")
    end

    on_off_trend_var = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, "#{obj_name_hpwh} sens cool".gsub(" ", "_"))
    on_off_trend_var.setName("#{obj_name_hpwh} on off")
    on_off_trend_var.setNumberOfTimestepsToBeLogged(2)

    # Additional sensors if supply or exhaust to calculate the load on the space from the HPWH
    if ducting == Constants.VentTypeSupply or ducting == Constants.VentTypeExhaust

      if water_heater_tz.nil?
        runner.registerError("Water heater cannot be located outside and ducted.")
        return false
      end

      amb_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Zone Mean Air Humidity Ratio")
      amb_w_sensor.setName("#{obj_name_hpwh} amb w")
      amb_w_sensor.setKeyName(water_heater_tz)

      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "System Node Pressure")
      sensor.setName("#{obj_name_hpwh} amb p")
      sensor.setKeyName(water_heater_tz)

      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "System Node Temperature")
      sensor.setName("#{obj_name_hpwh} tair out")
      sensor.setKeyName(water_heater_tz)

      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "System Node Humidity Ratio")
      sensor.setName("#{obj_name_hpwh} wair out")
      sensor.setKeyName(water_heater_tz)

      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "System Node Current Density Volume Flow Rate")
      sensor.setName("#{obj_name_hpwh} v air")

    end

    temp_depress_c = temp_depress / 1.8 # don't use convert because it's a delta
    timestep_minutes = (60 / model.getTimestep.numberOfTimestepsPerHour).to_i
    # EMS Program for ducting
    hpwh_ducting_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    hpwh_ducting_program.setName("#{obj_name_hpwh} InletAir")
    if not water_heater_tz.nil? and not Geometry.is_living(water_heater_tz) and temp_depress_c > 0
      runner.registerWarning("Confined space HPWH installations are typically used to represent installations in locations like a utility closet. Utility closets installations are typically only done in conditioned spaces.")
    end
    if temp_depress_c > 0 and ducting == "none"
      hpwh_ducting_program.addLine("Set HPWH_last = (@TrendValue #{on_off_trend_var.name} 1)")
      hpwh_ducting_program.addLine("Set HPWH_now = #{on_off_trend_var.name}")
      hpwh_ducting_program.addLine("Set num = (@Ln 2)")
      hpwh_ducting_program.addLine("If (HPWH_last == 0) && (HPWH_now<>0)") # HPWH just turned on
      hpwh_ducting_program.addLine("Set HPWHOn = 0")
      hpwh_ducting_program.addLine("Set exp = -(HPWHOn / 9.4) * num")
      hpwh_ducting_program.addLine("Set exponent = (@Exp exp)")
      hpwh_ducting_program.addLine("Set T_dep = (#{temp_depress_c} * exponent) - #{temp_depress_c}")
      hpwh_ducting_program.addLine("Set HPWHOn = HPWHOn + #{timestep_minutes}")
      hpwh_ducting_program.addLine("ElseIf (HPWH_last <> 0) && (HPWH_now<>0)") # HPWH has been running for more than 1 timestep
      hpwh_ducting_program.addLine("Set exp = -(HPWHOn / 9.4) * num")
      hpwh_ducting_program.addLine("Set exponent = (@Exp exp)")
      hpwh_ducting_program.addLine("Set T_dep = (#{temp_depress_c} * exponent) - #{temp_depress_c}")
      hpwh_ducting_program.addLine("Set HPWHOn = HPWHOn + #{timestep_minutes}")
      hpwh_ducting_program.addLine("Else")
      hpwh_ducting_program.addLine("If (Hour == 0) && (DayOfYear == 1)")
      hpwh_ducting_program.addLine("Set HPWHOn = 0") # Assume HPWH starts off for initial conditions
      hpwh_ducting_program.addLine("EndIF")
      hpwh_ducting_program.addLine("Set HPWHOn = HPWHOn - #{timestep_minutes}")
      hpwh_ducting_program.addLine("If HPWHOn < 0")
      hpwh_ducting_program.addLine("Set HPWHOn = 0")
      hpwh_ducting_program.addLine("EndIf")
      hpwh_ducting_program.addLine("Set exp = -(HPWHOn / 9.4) * num")
      hpwh_ducting_program.addLine("Set exponent = (@Exp exp)")
      hpwh_ducting_program.addLine("Set T_dep = (#{temp_depress_c} * exponent) - #{temp_depress_c}")
      hpwh_ducting_program.addLine("EndIf")
      hpwh_ducting_program.addLine("Set T_hpwh_inlet = #{amb_temp_sensor.name} + T_dep")
    else
      if ducting == Constants.VentTypeBalanced or ducting == Constants.VentTypeSupply
        hpwh_ducting_program.addLine("Set T_hpwh_inlet = HPWH_out_temp")
      else
        hpwh_ducting_program.addLine("Set T_hpwh_inlet = #{amb_temp_sensor.name}")
      end
    end
    if space.nil? # If located outside
      hpwh_ducting_program.addLine("Set #{tamb_act_actuator.name} = #{amb_temp_sensor.name}")
      hpwh_ducting_program.addLine("Set #{rhamb_act_actuator.name} = #{amb_rh_sensor.name}/100")
    else
      # Sensible/latent heat gain to the space
      if ducting == "none"
        hpwh_ducting_program.addLine("Set #{tamb_act_actuator.name} = T_hpwh_inlet")
        hpwh_ducting_program.addLine("Set #{rhamb_act_actuator.name} = #{amb_rh_sensor.name}/100")
        hpwh_ducting_program.addLine("Set temp1=(#{tl_sensor.name}*#{int_factor})+#{fan_power_sensor.name}*#{int_factor}")
        hpwh_ducting_program.addLine("Set #{sens_act_actuator.name} = 0-(#{sens_cool_sensor.name}*#{int_factor})-temp1")
        hpwh_ducting_program.addLine("Set #{lat_act_actuator.name} = 0 - #{lat_cool_sensor.name} * #{int_factor}")
      elsif ducting == Constants.VentTypeBalanced
        hpwh_ducting_program.addLine("Set #{tamb_act_actuator.name} = T_hpwh_inlet")
        hpwh_ducting_program.addLine("Set #{tamb_act2_actuator.name} = #{amb_temp_sensor.name}")
        hpwh_ducting_program.addLine("Set #{rhamb_act_actuator.name} = HPWH_out_rh/100")
        hpwh_ducting_program.addLine("Set #{sens_act_actuator.name} = 0 - #{tl_sensor.name}")
        hpwh_ducting_program.addLine("Set #{lat_act_actuator.name} = 0")
      elsif ducting == Constants.VentTypeSupply
        hpwh_ducting_program.addLine("Set rho = (@RhoAirFnPbTdbW HPWH_amb_P HPWHTair_out HPWHWair_out)")
        hpwh_ducting_program.addLine("Set cp = (@CpAirFnWTdb HPWHWair_out HPWHTair_out)")
        hpwh_ducting_program.addLine("Set h = (@HFnTdbW HPWHTair_out HPWHWair_out)")
        hpwh_ducting_program.addLine("Set HPWH_sens_gain = rho*cp*(HPWHTair_out-#{amb_temp_sensor.name})*V_airHPWH")
        hpwh_ducting_program.addLine("Set HPWH_lat_gain = h*rho*(HPWHWair_out-#{amb_w_sensor.name})*V_airHPWH")
        hpwh_ducting_program.addLine("Set #{tamb_act_actuator.name} = T_hpwh_inlet")
        hpwh_ducting_program.addLine("Set #{tamb_act2_actuator.name} = #{amb_temp_sensor.name}")
        hpwh_ducting_program.addLine("Set #{rhamb_act_actuator.name} = HPWH_out_rh/100")
        hpwh_ducting_program.addLine("Set #{sens_act_actuator.name} = HPWH_sens_gain - #{tl_sensor.name}")
        hpwh_ducting_program.addLine("Set #{lat_act_actuator.name} = HPWH_lat_gain")
      elsif ducting == Constants.VentTypeExhaust
        hpwh_ducting_program.addLine("Set rho = (@RhoAirFnPbTdbW HPWH_amb_P HPWHTair_out HPWHWair_out)")
        hpwh_ducting_program.addLine("Set cp = (@CpAirFnWTdb HPWHWair_out HPWHTair_out)")
        hpwh_ducting_program.addLine("Set h = (@HFnTdbW HPWHTair_out HPWHWair_out)")
        hpwh_ducting_program.addLine("Set HPWH_sens_gain = rho*cp*(#{tout_sensor.name}-#{amb_temp_sensor.name})*V_airHPWH")
        hpwh_ducting_program.addLine("Set HPWH_lat_gain = h*rho*(Wout-#{amb_w_sensor.name})*V_airHPWH")
        hpwh_ducting_program.addLine("Set #{tamb_act_actuator.name} = T_hpwh_inlet")
        hpwh_ducting_program.addLine("Set #{rhamb_act_actuator.name} = #{amb_rh_sensor.name}/100")
        hpwh_ducting_program.addLine("Set #{sens_act_actuator.name} = HPWH_sens_gain - #{tl_sensor.name}")
        hpwh_ducting_program.addLine("Set #{lat_act_actuator.name} = HPWH_lat_gain")
      end
    end

    leschedoverride_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(hpwh_bottom_element_sp, "Schedule:Constant", "Schedule Value")
    leschedoverride_actuator.setName("#{obj_name_hpwh} LESchedOverride")

    # EMS for the HPWH control logic
    # Lower element is enabled if the ambient air temperature prevents the HP from running

    hpwh_ctrl_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    hpwh_ctrl_program.setName("#{obj_name_hpwh} Control")
    if ducting == Constants.VentTypeSupply or ducting == Constants.VentTypeBalanced
      hpwh_ctrl_program.addLine("If (HPWH_out_temp < #{UnitConversions.convert(min_temp, "F", "C")}) || (HPWH_out_temp > #{UnitConversions.convert(max_temp, "F", "C")})")
    else
      hpwh_ctrl_program.addLine("If (#{amb_temp_sensor.name}<#{UnitConversions.convert(min_temp, "F", "C").round(2)}) || (#{amb_temp_sensor.name}>#{UnitConversions.convert(max_temp, "F", "C").round(2)})")
    end
    hpwh_ctrl_program.addLine("Set #{leschedoverride_actuator.name} = #{tset_C}")
    hpwh_ctrl_program.addLine("Else")
    hpwh_ctrl_program.addLine("Set #{leschedoverride_actuator.name} = 0")
    hpwh_ctrl_program.addLine("EndIf")

    # ProgramCallingManagers
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{obj_name_hpwh} ProgramManager")
    program_calling_manager.setCallingPoint("InsideHVACSystemIterationLoop")
    program_calling_manager.addProgram(hpwh_ctrl_program)
    program_calling_manager.addProgram(hpwh_ducting_program)

    loop.addSupplyBranchForComponent(tank)

    dhw_map[sys_id] << add_ec_adj(model, runner, hpwh, ec_adj, space, Constants.FuelTypeElectric, "heat pump water heater")

    return true
  end

  def self.apply_indirect(model, runner, space, cap, vol, t_set, oncycle_p, offcycle_p, ec_adj,
                          nbeds, boiler, boiler_plant_loop, boiler_fuel_type, dhw_map, sys_id, wh_type, jacket_r, standby_loss)
    obj_name_indirect = Constants.ObjectNameWaterHeater
    convlim = model.getConvergenceLimits
    convlim.setMinimumPlantIterations(3) # add one more minimum plant iteration to achieve better energy balance across plant loops.

    if wh_type == "space-heating boiler with storage tank"
      tank_type = Constants.WaterHeaterTypeTank
      act_vol = calc_storage_tank_actual_vol(vol, nil)
      a_side = calc_tank_areas(act_vol)[1]
      standby_loss = get_indirect_standbyloss(standby_loss, act_vol)
      if standby_loss > 10.0
        runner.registerWarning("Indirect water heater standby loss is over 10.0 F/hr, double check water heater inputs.")
      end
      ua = calc_indirect_ua_with_standbyloss(act_vol, standby_loss, jacket_r, a_side)
    else
      tank_type = Constants.WaterHeaterTypeTankless
      ua = 0.0
      act_vol = 1.0
    end

    loop = create_new_loop(model, Constants.PlantLoopDomesticWater, t_set, tank_type)

    new_pump = create_new_pump(model)
    new_pump.addToNode(loop.supplyInletNode)

    new_manager = create_new_schedule_manager(t_set, model, tank_type)
    new_manager.addToNode(loop.supplyOutletNode)

    # Create water heater
    new_heater = create_new_heater(obj_name_indirect, cap, nil, act_vol, nil, t_set, space, oncycle_p, offcycle_p, tank_type, nbeds, model, runner, ua, nil)
    new_heater.setSourceSideDesignFlowRate(100) # set one large number, override by EMS
    dhw_map[sys_id] << new_heater

    # Create alternate setpoint schedule for source side flow request
    alternate_stp_sch = OpenStudio::Model::ScheduleConstant.new(model)
    alternate_stp_sch.setName("#{obj_name_indirect} Alt Spt")
    alt_temp = UnitConversions.convert(t_set, "F", "C") + deadband(tank_type) / 2.0
    alternate_stp_sch.setValue(alt_temp)
    new_heater.setSourceSideFlowControlMode("IndirectHeatAlternateSetpoint")
    new_heater.setIndirectAlternateSetpointTemperatureSchedule(alternate_stp_sch)

    # Create hx setpoint schedule to specify source side temperature
    hx_stp_sch = OpenStudio::Model::ScheduleConstant.new(model)
    hx_stp_sch.setName("#{obj_name_indirect} HX Spt")
    hx_temp = 55 # tank source side inlet temperature, degree C
    hx_stp_sch.setValue(hx_temp)

    # change loop equipment operation scheme to heating load
    scheme_dhw = OpenStudio::Model::PlantEquipmentOperationHeatingLoad.new(model)
    scheme_dhw.addEquipment(1000000000, new_heater)
    loop.setPrimaryPlantEquipmentOperationScheme(scheme_dhw)
    dhw_map[sys_id] << loop

    # Create loop for source side
    source_loop = create_new_loop(model, 'dhw source loop', UnitConversions.convert(hx_temp, "C", "F"), tank_type)
    source_loop.autosizeMaximumLoopFlowRate()

    # Create heat exchanger
    indirect_hx = create_new_hx(model, Constants.ObjectNameTankHX)
    dhw_map[sys_id] << indirect_hx

    # Add heat exchanger to the load distribution scheme
    scheme = OpenStudio::Model::PlantEquipmentOperationHeatingLoad.new(model)
    scheme.addEquipment(1000000000, indirect_hx)
    source_loop.setPrimaryPlantEquipmentOperationScheme(scheme)

    # Add components to the tank source side plant loop
    source_loop.addSupplyBranchForComponent(indirect_hx)

    new_pump = create_new_pump(model)
    new_pump.autosizeRatedFlowRate()
    new_pump.addToNode(source_loop.supplyInletNode)
    dhw_map[sys_id] << new_pump

    new_source_manager = OpenStudio::Model::SetpointManagerScheduled.new(model, hx_stp_sch)
    new_source_manager.addToNode(source_loop.supplyOutletNode)
    dhw_map[sys_id] << new_source_manager

    source_loop.addDemandBranchForComponent(new_heater)

    # Add heat exchanger to boiler loop
    boiler_plant_loop.addDemandBranchForComponent(indirect_hx)
    boiler_plant_loop.setPlantLoopVolume(0.001) # Cannot be autocalculated because of large default tank source side mfr(set to be overwritten by EMS)

    loop.addSupplyBranchForComponent(new_heater)

    dhw_map[sys_id] << add_ec_adj(model, runner, new_heater, ec_adj, space, boiler_fuel_type, "boiler", boiler, indirect_hx)

    return true
  end

  def self.apply_combi_system_EMS(model, runner, combi_sys_id, dhw_map)
    # EMS for modulate source side mass flow rate
    # Initialization
    equipment_peaks = {}
    equipment_sch_sensors = {}
    equipment_target_temp_sensors = {}
    tank_volume, deadband, tank_source_temp = 0.0, 0.0, 0.0
    alt_spt_sch = nil
    tank_temp_sensor, tank_spt_sensor, tank_loss_energy_sensor = nil, nil, nil
    altsch_actuator, pump_actuator = nil, nil

    # Create sensors and actuators by dhw map information
    dhw_map[combi_sys_id].each do |object|
      if object.is_a? OpenStudio::Model::WaterUseConnections
        object.waterUseEquipment.each do |wu|
          # water use equipment peak mass flow rate
          wu_peak = wu.waterUseEquipmentDefinition.peakFlowRate
          equipment_peaks[wu.name.to_s] = wu_peak
          # mfr fraction schedule sensors
          wu_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Schedule Value")
          wu_sch_sensor.setName("#{wu.name.to_s} sch value")
          wu_sch_sensor.setKeyName(wu.flowRateFractionSchedule.get.name.to_s)
          equipment_sch_sensors[wu.name.to_s] = wu_sch_sensor
          # water use equipment target temperature schedule sensors
          target_temp_sch = wu.waterUseEquipmentDefinition.targetTemperatureSchedule.get
          target_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Schedule Value")
          target_temp_sensor.setName("#{wu.name.to_s} target temp")
          target_temp_sensor.setKeyName(target_temp_sch.name.to_s)
          equipment_target_temp_sensors[wu.name.to_s] = target_temp_sensor
        end
      elsif object.is_a? OpenStudio::Model::WaterHeaterMixed
        # Some parameters to use
        tank_volume = object.tankVolume.get
        deadband = object.deadbandTemperatureDifference
        # Sensors and actuators related to OS water heater object
        tank_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater Tank Temperature")
        tank_temp_sensor.setName("#{combi_sys_id} Tank Temp")
        tank_temp_sensor.setKeyName(object.name.to_s)
        tank_loss_energy_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater Heat Loss Energy")
        tank_loss_energy_sensor.setName("#{combi_sys_id} Tank Loss Energy")
        tank_loss_energy_sensor.setKeyName(object.name.to_s)
        tank_spt_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Schedule Value")
        tank_spt_sensor.setName("#{combi_sys_id} Setpoint Temperature")
        tank_spt_sensor.setKeyName(object.setpointTemperatureSchedule.get.name.to_s)
        alt_spt_sch = object.indirectAlternateSetpointTemperatureSchedule.get
        altsch_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(alt_spt_sch, "Schedule:Constant", "Schedule Value")
        altsch_actuator.setName("#{combi_sys_id} AltSchedOverride")
      elsif object.is_a? OpenStudio::Model::PumpVariableSpeed
        pump_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(object, "Pump", "Pump Mass Flow Rate")
        pump_actuator.setName("#{combi_sys_id} Pump MFR")
      elsif object.is_a? OpenStudio::Model::SetpointManagerScheduled
        tank_source_temp = object.schedule.to_ScheduleConstant.get.value
      end
    end

    mains_temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Site Mains Water Temperature")
    mains_temp_sensor.setName("Mains Temperature")
    mains_temp_sensor.setKeyName("*")

    # Program
    indirect_ctrl_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    indirect_ctrl_program.setName("#{combi_sys_id} Source MFR Control")
    indirect_ctrl_program.addLine("Set Rho = @RhoH2O #{tank_temp_sensor.name}")
    indirect_ctrl_program.addLine("Set Cp = @CpHW #{tank_temp_sensor.name}")
    indirect_ctrl_program.addLine("Set Tank_Water_Mass = #{tank_volume} * Rho")
    indirect_ctrl_program.addLine("Set DeltaT = #{tank_source_temp} - #{tank_spt_sensor.name}")
    indirect_ctrl_program.addLine("Set WU_Hot_Temp = #{tank_temp_sensor.name}")
    indirect_ctrl_program.addLine("Set WU_Cold_Temp = #{mains_temp_sensor.name}")
    indirect_ctrl_program.addLine("Set Tank_Use_Total_MFR = 0.0")
    equipment_peaks.each do |wu_name, peak|
      wu_id = wu_name.gsub(' ', '_')
      indirect_ctrl_program.addLine("Set #{wu_id}_Peak = #{peak}")
      indirect_ctrl_program.addLine("Set #{wu_id}_MFR_Total = #{wu_id}_Peak * #{equipment_sch_sensors[wu_name].name} * Rho")
      indirect_ctrl_program.addLine("If #{equipment_target_temp_sensors[wu_name].name} > WU_Hot_Temp")
      indirect_ctrl_program.addLine("Set #{wu_id}_MFR_Hot = #{wu_id}_MFR_Total")
      indirect_ctrl_program.addLine("Else")
      indirect_ctrl_program.addLine("Set #{wu_id}_MFR_Hot = #{wu_id}_MFR_Total * (#{equipment_target_temp_sensors[wu_name].name} - WU_Cold_Temp)/(WU_Hot_Temp - WU_Cold_Temp)")
      indirect_ctrl_program.addLine("EndIf")
      indirect_ctrl_program.addLine("Set Tank_Use_Total_MFR = Tank_Use_Total_MFR + #{wu_id}_MFR_Hot")
    end
    indirect_ctrl_program.addLine("Set WH_Loss = - #{tank_loss_energy_sensor.name}")
    indirect_ctrl_program.addLine("Set WH_Use = Tank_Use_Total_MFR * Cp * (#{tank_temp_sensor.name} - #{mains_temp_sensor.name}) * ZoneTimeStep * 3600")
    indirect_ctrl_program.addLine("Set WH_HeatToLowSetpoint = Tank_Water_Mass * Cp * (#{tank_temp_sensor.name} - #{tank_spt_sensor.name} + #{deadband})")
    indirect_ctrl_program.addLine("Set WH_Energy_Demand = WH_Use + WH_Loss - WH_HeatToLowSetpoint")
    indirect_ctrl_program.addLine("If WH_Energy_Demand > 0")
    indirect_ctrl_program.addLine("Set #{pump_actuator.name} = WH_Energy_Demand / (Cp * DeltaT * 3600 * ZoneTimeStep)")
    indirect_ctrl_program.addLine("Set #{altsch_actuator.name} = 100") # Set the alternate setpoint temperature to highest level to ensure maximum source side flow rate
    indirect_ctrl_program.addLine("Else")
    indirect_ctrl_program.addLine("Set #{pump_actuator.name} = 0")
    indirect_ctrl_program.addLine("Set #{altsch_actuator.name} = #{alt_spt_sch.to_ScheduleConstant.get.value}")
    indirect_ctrl_program.addLine("EndIf")

    # ProgramCallingManagers
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{combi_sys_id} ProgramManager")
    program_calling_manager.setCallingPoint("BeginTimestepBeforePredictor")
    program_calling_manager.addProgram(indirect_ctrl_program)
  end

  def self.add_desuperheater(model, t_set, tank, desuperheater_clg_coil, wh_type, fuel_type, space, loop, runner, ec_adj)
    reclaimed_efficiency = 0.25 # default
    workaround_flag = true # switch after E+ 9.3 release
    if workaround_flag
      eta_c = tank.heaterThermalEfficiency.get
      tank_name = tank.name.to_s.gsub(' ', '_')

      coil_clg_energy = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling Coil Total Cooling Energy")
      coil_clg_energy.setName("#{desuperheater_clg_coil.name} clg energy")
      coil_clg_energy.setKeyName(desuperheater_clg_coil.name.to_s)

      coil_elec_energy = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling Coil Electric Energy")
      coil_elec_energy.setName("#{desuperheater_clg_coil.name} elec energy")
      coil_elec_energy.setKeyName(desuperheater_clg_coil.name.to_s)

      wh_energy = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater Heating Energy")
      wh_energy.setName("#{tank.name} wh energy")
      wh_energy.setKeyName(tank.name.to_s)

      dsh_object = HotWaterAndAppliances.add_other_equipment(model, Constants.ObjectNameDesuperheater(tank.name), space, 0.01, 0, 0, model.alwaysOnDiscreteSchedule, fuel_type)

      # Actuators
      dsh_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(dsh_object, "OtherEquipment", "Power Level")
      dsh_actuator.setName("#{tank.name} dsh fuel saving")

      # energy variables
      dsh_total = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{tank_name}_dsh_total")

      dsh_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      dsh_program.setName("#{tank_name} DSH Program")
      dsh_program.addLine("Set #{tank_name}_eta_c = #{eta_c}")
      dsh_program.addLine("Set Avail_Cap = #{reclaimed_efficiency} * (#{coil_clg_energy.name} + #{coil_elec_energy.name})")
      dsh_program.addLine("If WarmupFlag") # need to initialize cumulative dsh energy number
      dsh_program.addLine("  Set #{dsh_total.name} = 0.0")
      dsh_program.addLine("Else")
      dsh_program.addLine("  Set #{dsh_total.name} = #{dsh_total.name} + Avail_Cap")
      dsh_program.addLine("EndIf")
      dsh_program.addLine("Set #{tank_name}_dsh_load_saving = -(@Min #{wh_energy.name} #{dsh_total.name})")
      dsh_program.addLine("Set #{dsh_total.name} = #{dsh_total.name} + #{tank_name}_dsh_load_saving") # update cumulative dsh energy pool
      dsh_program.addLine("Set #{dsh_actuator.name} = #{tank_name}_dsh_load_saving * #{ec_adj.round(5)} / (SystemTimeStep * 3600) / #{tank_name}_eta_c") # convert to water heater power savings

      # Sensor for EMS reporting
      ep_consumption_name = { Constants.FuelTypeElectric => "Electric Power",
                              Constants.FuelTypePropane => "Propane Rate",
                              Constants.FuelTypeOil => "FuelOil#1 Rate",
                              Constants.FuelTypeGas => "Gas Rate",
                              Constants.FuelTypeWood => "OtherFuel1 Rate" }[fuel_type]
      dsh_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Other Equipment #{ep_consumption_name.gsub('Rate', 'Energy').gsub('Power', 'Energy')}")
      dsh_sensor.setName("#{dsh_object.name} energy consumption")
      dsh_sensor.setKeyName(dsh_object.name.to_s)

      dsh_energy_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, dsh_sensor)
      dsh_energy_output_var.setName("#{Constants.ObjectNameDesuperheaterEnergy(tank.name)} outvar")
      dsh_energy_output_var.setTypeOfDataInVariable("Summed")
      dsh_energy_output_var.setUpdateFrequency("SystemTimestep")
      dsh_energy_output_var.setEMSProgramOrSubroutineName(dsh_program)
      dsh_energy_output_var.setUnits("J")

      dsh_load_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "#{tank_name}_dsh_load_saving")
      dsh_load_output_var.setName("#{Constants.ObjectNameDesuperheaterLoad(tank.name)} outvar")
      dsh_load_output_var.setTypeOfDataInVariable("Summed")
      dsh_load_output_var.setUpdateFrequency("SystemTimestep")
      dsh_load_output_var.setEMSProgramOrSubroutineName(dsh_program)
      dsh_load_output_var.setUnits("J")

      # ProgramCallingManagers
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName("#{tank.name} DSH ProgramManager")
      program_calling_manager.setCallingPoint("EndOfSystemTimestepBeforeHVACReporting")
      program_calling_manager.addProgram(dsh_program)

      return [dsh_energy_output_var, dsh_load_output_var]
    else # need to test after switch
      # create a storage tank
      vol = 50.0 # FIXME: Input vs assumption?
      storage_vol_actual = calc_storage_tank_actual_vol(vol, nil)
      cap = 0
      nbeds = 0 # won't be used
      assumed_ua = 6.0 # Btu/hr-F FIXME: Assumption: indirect tank ua calculated based on 1.0 standby_loss and 50gal nominal vol
      storage_tank_name = "#{tank.name} storage tank"
      storage_tank = create_new_heater(storage_tank_name, cap, nil, storage_vol_actual, nil, t_set, space, 0, 0, Constants.WaterHeaterTypeTank, nbeds, model, runner, assumed_ua, nil)

      loop.addSupplyBranchForComponent(storage_tank)
      runner.registerInfo("Added '#{storage_tank.name}' to supply branch of '#{loop.name}'.")

      tank.addToNode(storage_tank.supplyOutletModelObject.get.to_Node.get)
      runner.registerInfo("Moved '#{tank.name}' to supply outlet node of '#{storage_tank.name}'.")

      # Create a schedule for desuperheater
      new_schedule = OpenStudio::Model::ScheduleConstant.new(model)
      new_schedule.setName("#{tank.name} desuperheater setpoint schedule")
      new_schedule.setValue(100)

      # create a desuperheater object
      desuperheater = OpenStudio::Model::CoilWaterHeatingDesuperheater.new(model, new_schedule)
      desuperheater.setName("#{tank.name} desuperheater")
      desuperheater.setMaximumInletWaterTemperatureforHeatReclaim(100)
      desuperheater.setDeadBandTemperatureDifference(0.2)
      desuperheater.setRatedHeatReclaimRecoveryEfficiency(reclaimed_efficiency)
      desuperheater.addToHeatRejectionTarget(storage_tank)
      desuperheater.setWaterPumpPower(0)
      # attach to the clg coil source
      desuperheater.setHeatingSource(desuperheater_clg_coil)

      return [desuperheater]
    end
  end

  def self.create_new_hx(model, name)
    hx = OpenStudio::Model::HeatExchangerFluidToFluid.new(model)
    hx.setName(name)
    hx.setControlType("OperationSchemeModulated")

    return hx
  end

  def self.calc_water_heater_capacity(fuel, num_beds, num_water_heaters, num_baths = nil)
    # Calculate the capacity of the water heater based on the fuel type and number
    # of bedrooms and bathrooms in a home. Returns the capacity in kBtu/hr.

    if num_baths.nil?
      num_baths = get_default_num_bathrooms(num_beds)
    end

    # Adjust the heating capacity if there are multiple water heaters in the home
    num_baths /= num_water_heaters.to_f

    if fuel != Constants.FuelTypeElectric
      if num_beds <= 4
        cap_kbtuh = 40.0
      elsif num_beds == 5
        cap_kbtuh = 47.0
      else
        cap_kbtuh = 50.0
      end
      return cap_kbtuh
    else
      if num_beds == 1
        cap_kw = 2.5
      elsif num_beds == 2
        if num_baths <= 1.5
          cap_kw = 3.5
        else
          cap_kw = 4.5
        end
      elsif num_beds == 3
        if num_baths <= 1.5
          cap_kw = 4.5
        else
          cap_kw = 5.5
        end
      else
        cap_kw = 5.5
      end
      return UnitConversions.convert(cap_kw, "kW", "kBtu/hr")
    end
  end

  def self.calc_ef_from_uef(uef, type, fuel_type)
    # Interpretation on Water Heater UEF
    if fuel_type == Constants.FuelTypeElectric
      if type == Constants.WaterHeaterTypeTank
        return [2.4029 * uef - 1.2844, 0.96].min
      elsif type == Constants.WaterHeaterTypeTankless
        return uef
      elsif type == Constants.WaterHeaterTypeHeatPump
        return 1.2101 * uef - 0.6052
      end
    else # Fuel
      if type == Constants.WaterHeaterTypeTank
        return 0.9066 * uef + 0.0711
      elsif type == Constants.WaterHeaterTypeTankless
        return uef
      end
    end
    return nil
  end

  def self.calc_tank_areas(act_vol)
    pi = Math::PI
    height = 48.0 # inches
    diameter = 24.0 * ((act_vol * 0.1337) / (height / 12.0 * pi))**0.5 # inches
    a_top = pi * (diameter / 12.0)**(2.0) / 4.0 # sqft
    a_side = pi * (diameter / 12.0) * (height / 12.0) # sqft
    surface_area = 2.0 * a_top + a_side # sqft

    return surface_area, a_side
  end

  def self.get_indirect_standbyloss(standby_loss, act_vol)
    # Tank geometry
    surface_area = calc_tank_areas(act_vol)[0]
    if standby_loss.nil? # Swiched to standby_loss equation fit from AHRI database
      # calculate independent variable SurfaceArea/vol(physically linear to standby_loss/skin_u under test condition) to fit the linear equation from AHRI database
      sqft_by_gal = surface_area / act_vol # sqft/gal
      standby_loss = 2.9721 * sqft_by_gal - 0.4732 # linear equation assuming a constant u, F/hr
    end
    if standby_loss <= 0
      fail "Indirect water heater standby loss is negative, double check TankVolume to be <829 gal or /extension/StandbyLoss to be >0.0 F/hr."
    end

    return standby_loss
  end

  def self.calc_indirect_ua_with_standbyloss(act_vol, standby_loss, jacket_r, a_side)
    # Test conditions
    cp = 0.999 # Btu/lb-F
    rho = 8.216 # lb/gal
    t_amb = 70.0 # F
    t_tank_avg = 135.0 # F, Test begins at 137-138F stop at 133F

    # UA calculation
    q = standby_loss * cp * act_vol * rho # Btu/hr
    ua = q / (t_tank_avg - t_amb) # Btu/hr-F

    # jacket
    ua = apply_tank_jacket(jacket_r, nil, nil, ua, a_side)
    return ua
  end

  def self.get_default_num_bathrooms(num_beds)
    # From https://www.sansomeandgeorge.co.uk/news-updates/what-is-the-ideal-ratio-of-bathrooms-to-bedrooms.html
    # "According to 70% of estate agents, a property should have two bathrooms for every three bedrooms..."
    num_baths = 2.0 / 3.0 * num_beds
  end

  def self.add_ec_adj(model, runner, heater, ec_adj, space, fuel_type, wh_type, combi_boiler = nil, combi_hx = nil)
    adjustment = ec_adj - 1.0

    if space.nil? # WH is outdoors, set the other equipment to be in a random space
      space = model.getSpaces[0]
    end

    if wh_type == "heat pump water heater"
      tank = heater.tank
    else
      tank = heater
    end

    # Add an other equipment object for water heating that will get actuated, has a small initial load but gets overwritten by EMS
    ec_adj_object = HotWaterAndAppliances.add_other_equipment(model, Constants.ObjectNameWaterHeaterAdjustment(heater.name), space, 0.01, 0, 0, model.alwaysOnDiscreteSchedule, fuel_type)

    # EMS for calculating the EC_adj

    # Sensors
    ep_consumption_name = { Constants.FuelTypeElectric => "Electric Power",
                            Constants.FuelTypePropane => "Propane Rate",
                            Constants.FuelTypeOil => "FuelOil#1 Rate",
                            Constants.FuelTypeGas => "Gas Rate",
                            Constants.FuelTypeWood => "OtherFuel1 Rate" }[fuel_type]
    if wh_type.include? "boiler"
      ec_adj_sensor_hx = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Fluid Heat Exchanger Heat Transfer Energy")
      ec_adj_sensor_hx.setName("#{combi_hx.name} energy")
      ec_adj_sensor_hx.setKeyName(combi_hx.name.to_s)
      ec_adj_sensor_boiler_heating = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Boiler Heating Energy")
      ec_adj_sensor_boiler_heating.setName("#{combi_boiler.name} heating energy")
      ec_adj_sensor_boiler_heating.setKeyName(combi_boiler.name.to_s)
      ec_adj_sensor_boiler = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Boiler #{ep_consumption_name}")
      ec_adj_sensor_boiler.setName("#{combi_boiler.name} energy")
      ec_adj_sensor_boiler.setKeyName(combi_boiler.name.to_s)
    elsif wh_type == "heat pump water heater"
      ec_adj_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater Electric Power")
      ec_adj_sensor.setName("#{heater.tank.name} energy")
      ec_adj_sensor.setKeyName(heater.tank.name.to_s)
      ec_adj_hp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Cooling Coil Water Heating Electric Power")
      ec_adj_hp_sensor.setName("#{heater.dXCoil.name} energy")
      ec_adj_hp_sensor.setKeyName(heater.dXCoil.name.to_s)
      ec_adj_fan_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Fan Electric Power")
      ec_adj_fan_sensor.setName("#{heater.fan.name} energy")
      ec_adj_fan_sensor.setKeyName(heater.fan.name.to_s)
    else
      ec_adj_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater #{ep_consumption_name}")
      ec_adj_sensor.setName("#{heater.name} energy")
      ec_adj_sensor.setKeyName(heater.name.to_s)
    end

    ec_adj_oncyc_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater On Cycle Parasitic Electric Power")
    ec_adj_oncyc_sensor.setName("#{tank.name} on cycle parasitic")
    ec_adj_oncyc_sensor.setKeyName(tank.name.to_s)
    ec_adj_offcyc_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Water Heater Off Cycle Parasitic Electric Power")
    ec_adj_offcyc_sensor.setName("#{tank.name} off cycle parasitic")
    ec_adj_offcyc_sensor.setKeyName(tank.name.to_s)

    # Actuators
    ec_adj_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(ec_adj_object, "OtherEquipment", "Power Level")
    ec_adj_actuator.setName("#{heater.name} ec_adj_act")

    # Program
    ec_adj_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    ec_adj_program.setName("#{heater.name} EC_adj")
    if wh_type.include? "boiler"
      ec_adj_program.addLine("Set tmp_ec_adj_oncyc_sensor = #{ec_adj_oncyc_sensor.name}")
      ec_adj_program.addLine("Set tmp_ec_adj_offcyc_sensor = #{ec_adj_offcyc_sensor.name}")
      ec_adj_program.addLine("Set tmp_ec_adj_sensor_hx = #{ec_adj_sensor_hx.name}")
      ec_adj_program.addLine("Set tmp_ec_adj_sensor_boiler_heating = #{ec_adj_sensor_boiler_heating.name}")
      ec_adj_program.addLine("Set tmp_ec_adj_sensor_boiler = #{ec_adj_sensor_boiler.name}")
      ec_adj_program.addLine("Set wh_e_cons = #{ec_adj_oncyc_sensor.name} + #{ec_adj_offcyc_sensor.name}")
      ec_adj_program.addLine("If #{ec_adj_sensor_boiler_heating.name} > 0")
      ec_adj_program.addLine("  Set wh_e_cons = wh_e_cons + (@Abs #{ec_adj_sensor_hx.name}) / #{ec_adj_sensor_boiler_heating.name} * #{ec_adj_sensor_boiler.name}")
      ec_adj_program.addLine("EndIf")
    elsif wh_type == "heat pump water heater"
      ec_adj_program.addLine("Set wh_e_cons = #{ec_adj_sensor.name} + #{ec_adj_oncyc_sensor.name} + #{ec_adj_offcyc_sensor.name} + #{ec_adj_hp_sensor.name} + #{ec_adj_fan_sensor.name}")
    else
      ec_adj_program.addLine("Set wh_e_cons = #{ec_adj_sensor.name} + #{ec_adj_oncyc_sensor.name} + #{ec_adj_offcyc_sensor.name}")
    end
    ec_adj_program.addLine("Set #{ec_adj_actuator.name} = #{adjustment} * wh_e_cons")

    # Program Calling Manager
    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName("#{heater.name} EC_adj ProgramManager")
    program_calling_manager.setCallingPoint("EndOfSystemTimestepBeforeHVACReporting")
    program_calling_manager.addProgram(ec_adj_program)

    # Sensor for EMS reporting
    ec_adj_object_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, "Other Equipment #{ep_consumption_name.gsub('Rate', 'Energy').gsub('Power', 'Energy')}")
    ec_adj_object_sensor.setName("#{ec_adj_object.name} energy consumption")
    ec_adj_object_sensor.setKeyName(ec_adj_object.name.to_s)

    # EMS Output Variable for reporting
    ec_adj_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ec_adj_object_sensor)
    ec_adj_output_var.setName("#{Constants.ObjectNameWaterHeaterAdjustment(heater.name)} outvar")
    ec_adj_output_var.setTypeOfDataInVariable("Summed")
    ec_adj_output_var.setUpdateFrequency("SystemTimestep")
    ec_adj_output_var.setEMSProgramOrSubroutineName(ec_adj_program)
    ec_adj_output_var.setUnits("J")

    return ec_adj_output_var
  end

  def self.get_default_hot_water_temperature(eri_version)
    if eri_version.include? "A"
      return 125.0
    end

    return 120.0
  end

  def self.get_combi_system_fuel(idref, orig_details)
    orig_details.elements.each("Systems/HVAC/HVACPlant/HeatingSystem") do |heating_system|
      heating_system_values = HPXML.get_heating_system_values(heating_system: heating_system,
                                                              select: [:id, :heating_system_fuel])
      next unless heating_system_values[:id] == idref

      return heating_system_values[:heating_system_fuel]
    end
  end

  def self.get_tankless_cycling_derate()
    return 0.08
  end

  private

  def self.deadband(wh_type)
    if wh_type == Constants.WaterHeaterTypeTank
      return 2.0 # deg-C
    else
      return 0.0 # deg-C
    end
  end

  def self.calc_storage_tank_actual_vol(vol, fuel)
    # Convert the nominal tank volume to an actual volume
    if fuel.nil?
      act_vol = 0.95 * vol # indirect tank
    else
      if fuel == Constants.FuelTypeElectric
        act_vol = 0.9 * vol
      else
        act_vol = 0.95 * vol
      end
    end
    return act_vol
  end

  def self.calc_tank_UA(act_vol, fuel, ef, re, pow, wh_type, cyc_derate, jacket_r, runner)
    # Calculates the U value, UA of the tank and conversion efficiency (eta_c)
    # based on the Energy Factor and recovery efficiency of the tank
    # Source: Burch and Erickson 2004 - http://www.nrel.gov/docs/gen/fy04/36035.pdf
    if wh_type == Constants.WaterHeaterTypeTankless
      eta_c = ef * (1.0 - cyc_derate)
      ua = 0.0
      surface_area = 1.0
    else
      volume_drawn = 64.3 # gal/day
      density = 8.2938 # lb/gal
      draw_mass = volume_drawn * density # lb
      cp = 1.0007 # Btu/lb-F
      t = 135.0 # F
      t_in = 58.0 # F
      t_env = 67.5 # F
      q_load = draw_mass * cp * (t - t_in) # Btu/day
      surface_area, a_side = calc_tank_areas(act_vol)
      if fuel != Constants.FuelTypeElectric
        ua = (re / ef - 1.0) / ((t - t_env) * (24.0 / q_load - 1.0 / (1000.0 * (pow) * ef))) # Btu/hr-F
        eta_c = (re + ua * (t - t_env) / (1000 * pow)) # conversion efficiency is supposed to be calculated with initial tank ua
      else # is Electric
        ua = q_load * (1.0 / ef - 1.0) / ((t - t_env) * 24.0)
        eta_c = 1.0
      end
      ua = apply_tank_jacket(jacket_r, ef, fuel, ua, a_side)
    end
    u = ua / surface_area # Btu/hr-ft^2-F
    if eta_c > 1.0
      runner.registerError("A water heater heat source (either burner or element) efficiency of > 1 has been calculated, double check water heater inputs.")
    end
    if ua < 0.0
      runner.registerError("A negative water heater standby loss coefficient (UA) was calculated, double check water heater inputs.")
    end

    return u, ua, eta_c
  end

  def self.apply_tank_jacket(jacket_r, ef, fuel, ua_pre, a_side)
    if not jacket_r.nil?
      skin_insulation_R = 5.0 # R5
      if fuel.nil? # indirect water heater, etc. Assume 2 inch skin insulation
        skin_insulation_t = 2.0 # inch
      elsif fuel != Constants.FuelTypeElectric
        if ef < 0.7
          skin_insulation_t = 1.0 # inch
        else
          skin_insulation_t = 2.0 # inch
        end
      else # electric
        skin_insulation_t = 2.0 # inch
      end
      # water heater wrap calculation based on:
      # Modeling Water Heat Wraps in BEopt DRAFT Technical Note
      # Authors:  Ben Polly and Jay Burch (NREL)
      u_pre_skin = 1.0 / (skin_insulation_t * skin_insulation_R + 1.0 / 1.3 + 1.0 / 52.8) # Btu/hr-ft^2-F = (1 / hout + kins / tins + t / hin)^-1
      ua = ua_pre - jacket_r / (1.0 / u_pre_skin + jacket_r) * u_pre_skin * a_side
    else
      ua = ua_pre
    end
    return ua
  end

  def self.calc_tank_EF(wh_type, ua, eta_c)
    # Calculates the energy factor based on UA of the tank and conversion efficiency (eta_c)
    # Source: Burch and Erickson 2004 - http://www.nrel.gov/docs/gen/fy04/36035.pdf
    if wh_type == Constants.WaterHeaterTypeTankless
      ef = eta_c
    else
      pi = Math::PI
      volume_drawn = 64.3 # gal/day
      density = 8.2938 # lb/gal
      draw_mass = volume_drawn * density # lb
      cp = 1.0007 # Btu/lb-F
      t = 135.0 # F
      t_in = 58.0 # F
      t_env = 67.5 # F
      q_load = draw_mass * cp * (t - t_in) # Btu/day

      ef = q_load / ((ua * (t - t_env) * 24.0 + q_load) / eta_c)
    end
    return ef
  end

  def self.create_new_pump(model)
    # Add a pump to the new DHW loop
    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setRatedFlowRate(0.01)
    pump.setFractionofMotorInefficienciestoFluidStream(0)
    pump.setMotorEfficiency(1)
    pump.setRatedPowerConsumption(0)
    pump.setRatedPumpHead(1)
    pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
    pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
    pump.setPumpControlType("Intermittent")
    return pump
  end

  def self.create_new_schedule_manager(t_set, model, wh_type)
    new_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    new_schedule.setName("dhw temp")
    new_schedule.setValue(UnitConversions.convert(t_set, "F", "C") + deadband(wh_type) / 2.0)
    OpenStudio::Model::SetpointManagerScheduled.new(model, new_schedule)
  end

  def self.create_new_heater(name, cap, fuel, act_vol, ef, t_set, space, oncycle_p, offcycle_p, wh_type, nbeds, model, runner, ua, eta_c)
    new_heater = OpenStudio::Model::WaterHeaterMixed.new(model)
    new_heater.setName(name)
    new_heater.setHeaterThermalEfficiency(eta_c) unless eta_c.nil?
    new_heater.setHeaterFuelType(HelperMethods.eplus_fuel_map(fuel)) unless fuel.nil?
    configure_setpoint_schedule(new_heater, t_set, wh_type, model)
    new_heater.setMaximumTemperatureLimit(99.0)
    if wh_type == Constants.WaterHeaterTypeTankless
      new_heater.setHeaterControlType("Modulate")
    else
      new_heater.setHeaterControlType("Cycle")
    end
    new_heater.setDeadbandTemperatureDifference(deadband(wh_type))

    new_heater.setHeaterMinimumCapacity(0.0)
    new_heater.setHeaterMaximumCapacity(UnitConversions.convert(cap, "kBtu/hr", "W"))
    new_heater.setTankVolume(UnitConversions.convert(act_vol, "gal", "m^3"))

    # Set parasitic power consumption
    if wh_type == Constants.WaterHeaterTypeTankless
      # Tankless WHs are set to "modulate", not "cycle", so they end up
      # effectively always on. Thus, we need to use a weighted-average of
      # on-cycle and off-cycle parasitics.
      # Values used here are based on the average across 10 units originally used when modeling MF buildings
      avg_runtime_frac = [0.0268, 0.0333, 0.0397, 0.0462, 0.0529]
      if nbeds <= 5
        if nbeds == 0
          runtime_frac = avg_runtime_frac[0]
        else
          runtime_frac = avg_runtime_frac[nbeds - 1]
        end
      else
        runtime_frac = avg_runtime_frac[4]
      end
      avg_elec = oncycle_p * runtime_frac + offcycle_p * (1 - runtime_frac)

      new_heater.setOnCycleParasiticFuelConsumptionRate(avg_elec)
      new_heater.setOffCycleParasiticFuelConsumptionRate(avg_elec)
    else
      new_heater.setOnCycleParasiticFuelConsumptionRate(oncycle_p)
      new_heater.setOffCycleParasiticFuelConsumptionRate(offcycle_p)
    end
    new_heater.setOnCycleParasiticFuelType("Electricity")
    new_heater.setOffCycleParasiticFuelType("Electricity")
    new_heater.setOnCycleParasiticHeatFractiontoTank(0)
    new_heater.setOffCycleParasiticHeatFractiontoTank(0)

    # Set fraction of heat loss from tank to ambient (vs out flue)
    # Based on lab testing done by LBNL
    skinlossfrac = 1.0
    if not fuel.nil?
      if fuel != Constants.FuelTypeElectric and wh_type == Constants.WaterHeaterTypeTank
        if oncycle_p == 0.0
          skinlossfrac = 0.64
        elsif ef < 0.8
          skinlossfrac = 0.91
        else
          skinlossfrac = 0.96
        end
      end
    end
    new_heater.setOffCycleLossFractiontoThermalZone(skinlossfrac)
    new_heater.setOnCycleLossFractiontoThermalZone(1.0)

    if space.nil? # Located outside
      new_heater.setAmbientTemperatureIndicator("Outdoors")
    else
      new_heater.setAmbientTemperatureIndicator("ThermalZone")
      new_heater.setAmbientTemperatureThermalZone(space.thermalZone.get)
    end
    if new_heater.ambientTemperatureSchedule.is_initialized
      new_heater.ambientTemperatureSchedule.get.remove
    end
    ua_w_k = UnitConversions.convert(ua, "Btu/(hr*F)", "W/K")
    new_heater.setOnCycleLossCoefficienttoAmbientTemperature(ua_w_k)
    new_heater.setOffCycleLossCoefficienttoAmbientTemperature(ua_w_k)

    return new_heater
  end

  def self.configure_setpoint_schedule(new_heater, t_set, wh_type, model)
    set_temp_c = UnitConversions.convert(t_set, "F", "C") + deadband(wh_type) / 2.0 # Half the deadband to account for E+ deadband
    new_schedule = OpenStudio::Model::ScheduleConstant.new(model)
    new_schedule.setName("WH Setpoint Temp")
    new_schedule.setValue(set_temp_c)
    if new_heater.setpointTemperatureSchedule.is_initialized
      new_heater.setpointTemperatureSchedule.get.remove
    end
    new_heater.setSetpointTemperatureSchedule(new_schedule)
  end

  def self.create_new_loop(model, name, t_set, wh_type)
    # Create a new plant loop for the water heater
    loop = OpenStudio::Model::PlantLoop.new(model)
    loop.setName(name)
    loop.sizingPlant.setDesignLoopExitTemperature(UnitConversions.convert(t_set, "F", "C") + deadband(wh_type) / 2.0)
    loop.sizingPlant.setLoopDesignTemperatureDifference(UnitConversions.convert(10.0, "R", "K"))
    loop.setPlantLoopVolume(0.003) # ~1 gal
    loop.setMaximumLoopFlowRate(0.01) # This size represents the physical limitations to flow due to losses in the piping system. For BEopt we assume that the pipes are always adequately sized

    bypass_pipe = OpenStudio::Model::PipeAdiabatic.new(model)
    out_pipe = OpenStudio::Model::PipeAdiabatic.new(model)

    loop.addSupplyBranchForComponent(bypass_pipe)
    out_pipe.addToNode(loop.supplyOutletNode)

    return loop
  end
end
