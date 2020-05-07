# frozen_string_literal: true

require_relative 'constants'
require_relative 'geometry'
require_relative 'util'
require_relative 'unit_conversions'
require_relative 'psychrometrics'
require_relative 'schedules'

class HVAC
  def self.apply_central_air_conditioner_furnace(model, runner, cooling_system, heating_system,
                                                 remaining_cool_load_frac, remaining_heat_load_frac,
                                                 control_zone, hvac_map)

    hvac_map[cooling_system.id] = [] unless cooling_system.nil?
    hvac_map[heating_system.id] = [] unless heating_system.nil?
    if heating_system.nil?
      obj_name = Constants.ObjectNameCentralAirConditioner
    elsif cooling_system.nil?
      obj_name = Constants.ObjectNameFurnace
    else
      obj_name = Constants.ObjectNameCentralAirConditionerAndFurnace
    end

    if not heating_system.nil?
      sequential_heat_load_frac = calc_sequential_load_fraction(heating_system.fraction_heat_load_served, remaining_heat_load_frac)
    else
      sequential_heat_load_frac = 0.0
    end
    if not cooling_system.nil?
      sequential_cool_load_frac = calc_sequential_load_fraction(cooling_system.fraction_cool_load_served, remaining_cool_load_frac)
    else
      sequential_cool_load_frac = 0.0
    end

    if not cooling_system.nil?
      fan_power_installed = get_fan_power_installed(cooling_system.cooling_efficiency_seer)
    else
      fan_power_installed = 0.5 # W/cfm; For fuel furnaces, will be overridden by EAE later
    end

    if not cooling_system.nil?
      if cooling_system.compressor_type == HPXML::HVACCompressorTypeSingleStage
        num_speeds = 1
      elsif cooling_system.compressor_type == HPXML::HVACCompressorTypeTwoStage
        num_speeds = 2
      elsif cooling_system.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
        num_speeds = 4
      end
      fan_power_rated = get_fan_power_rated(cooling_system.cooling_efficiency_seer)
      crankcase_kw, crankcase_temp = get_crankcase_assumptions()

      # Cooling Coil

      cool_c_d = get_cool_c_d(num_speeds, cooling_system.cooling_efficiency_seer)
      cool_cfm = cooling_system.cooling_cfm
      if num_speeds == 1
        cool_rated_airflow_rate = 386.1 # cfm/ton
        cool_capacity_ratios = [1.0]
        cool_fan_speed_ratios = [1.0]
        cool_shrs = [cooling_system.cooling_shr]
        cool_cap_ft_spec = [[3.670270705, -0.098652414, 0.000955906, 0.006552414, -0.0000156, -0.000131877]]
        cool_eir_ft_spec = [[-3.302695861, 0.137871531, -0.001056996, -0.012573945, 0.000214638, -0.000145054]]
        cool_cap_fflow_spec = [[0.718605468, 0.410099989, -0.128705457]]
        cool_eir_fflow_spec = [[1.32299905, -0.477711207, 0.154712157]]
        cool_eers = [calc_eer_cooling_1speed(cooling_system.cooling_efficiency_seer, fan_power_rated, cool_eir_ft_spec)]
      elsif num_speeds == 2
        cool_rated_airflow_rate = 355.2 # cfm/ton
        cool_capacity_ratios = [0.72, 1.0]
        cool_fan_speed_ratios = [0.86, 1.0]
        cool_shrs = [cooling_system.cooling_shr - 0.02, cooling_system.cooling_shr] # TODO: is the following assumption correct (revisit Dylan's data?)? OR should value from HPXML be used for both stages
        cool_cap_ft_spec = [[3.940185508, -0.104723455, 0.001019298, 0.006471171, -0.00000953, -0.000161658],
                            [3.109456535, -0.085520461, 0.000863238, 0.00863049, -0.0000210, -0.000140186]]
        cool_eir_ft_spec = [[-3.877526888, 0.164566276, -0.001272755, -0.019956043, 0.000256512, -0.000133539],
                            [-1.990708931, 0.093969249, -0.00073335, -0.009062553, 0.000165099, -0.0000997]]
        cool_cap_fflow_spec = [[0.65673024, 0.516470835, -0.172887149],
                               [0.690334551, 0.464383753, -0.154507638]]
        cool_eir_fflow_spec = [[1.562945114, -0.791859997, 0.230030877],
                               [1.31565404, -0.482467162, 0.166239001]]
        cool_eers = calc_eers_cooling_2speed(runner, cooling_system.cooling_efficiency_seer, cool_c_d, cool_capacity_ratios, cool_fan_speed_ratios, fan_power_rated, cool_eir_ft_spec, cool_cap_ft_spec)
      elsif num_speeds == 4
        cool_rated_airflow_rate = 411.0 # cfm/ton
        cool_capacity_ratios = [0.36, 0.51, 0.67, 1.0]
        cool_fan_speed_ratios = [0.42, 0.54, 0.68, 1.0]
        cool_shrs = [1.115, 1.026, 1.013, 1.0].map { |mult| cooling_system.cooling_shr * mult }
        # The following coefficients were generated using NREL experimental performance mapping for the Carrier unit
        cool_cap_coeff_perf_map = [[1.6516044444444447, 0.0698916049382716, -0.0005546296296296296, -0.08870160493827162, 0.0004135802469135802, 0.00029077160493827157],
                                   [-6.84948049382716, 0.26946, -0.0019413580246913577, -0.03281469135802469, 0.00015694444444444442, 3.32716049382716e-05],
                                   [-4.53543086419753, 0.15358543209876546, -0.0009345679012345678, 0.002666913580246914, -7.993827160493826e-06, -0.00011617283950617283],
                                   [-3.500948395061729, 0.11738987654320988, -0.0006580246913580248, 0.007003148148148148, -2.8518518518518517e-05, -0.0001284259259259259],
                                   [1.8769221728395058, -0.04768641975308643, 0.0006885802469135801, 0.006643395061728395, 1.4209876543209876e-05, -0.00024043209876543206]]
        cool_cap_ft_spec = cool_cap_coeff_perf_map.select { |i| [0, 1, 2, 4].include? cool_cap_coeff_perf_map.index(i) }
        cool_cap_ft_spec_3 = cool_cap_coeff_perf_map.select { |i| [0, 1, 4].include? cool_cap_coeff_perf_map.index(i) }
        cool_eir_coeff_perf_map = [[2.896298765432099, -0.12487654320987657, 0.0012148148148148148, 0.04492037037037037, 8.734567901234567e-05, -0.0006348765432098764],
                                   [6.428076543209876, -0.20913209876543212, 0.0018521604938271604, 0.024392592592592594, 0.00019691358024691356, -0.0006012345679012346],
                                   [5.136356049382716, -0.1591530864197531, 0.0014151234567901232, 0.018665555555555557, 0.00020398148148148147, -0.0005407407407407407],
                                   [1.3823471604938273, -0.02875123456790123, 0.00038302469135802463, 0.006344814814814816, 0.00024836419753086417, -0.00047469135802469134],
                                   [-1.0411735802469133, 0.055261604938271605, -0.0004404320987654321, 0.0002154938271604939, 0.00017484567901234564, -0.0002017901234567901]]
        cool_eir_ft_spec = cool_eir_coeff_perf_map.select { |i| [0, 1, 2, 4].include? cool_eir_coeff_perf_map.index(i) }
        cool_eir_ft_spec_3 = cool_eir_coeff_perf_map.select { |i| [0, 1, 4].include? cool_eir_coeff_perf_map.index(i) }
        cool_cap_fflow_spec = [[1, 0, 0]] * 4
        cool_eir_fflow_spec = [[1, 0, 0]] * 4
        cap_ratio_seer_3 = cool_capacity_ratios.select { |i| [0, 1, 3].include? cool_capacity_ratios.index(i) }
        fan_speed_seer_3 = cool_fan_speed_ratios.select { |i| [0, 1, 3].include? cool_fan_speed_ratios.index(i) }
        cool_eers = calc_eers_cooling_4speed(runner, cooling_system.cooling_efficiency_seer, cool_c_d, cap_ratio_seer_3, fan_speed_seer_3, fan_power_rated, cool_eir_ft_spec_3, cool_cap_ft_spec_3)
      end
      cool_cfms_ton_rated = calc_cfms_ton_rated(cool_rated_airflow_rate, cool_fan_speed_ratios, cool_capacity_ratios)
      cool_shrs_rated_gross = calc_shrs_rated_gross(num_speeds, cool_shrs, fan_power_rated, cool_cfms_ton_rated)
      cool_eirs = calc_cool_eirs(num_speeds, cool_eers, fan_power_rated)
      cool_closs_fplr_spec = [calc_plr_coefficients(cool_c_d)] * num_speeds
      clg_coil = create_dx_cooling_coil(model, obj_name, (0...num_speeds).to_a, cool_eirs, cool_cap_ft_spec, cool_eir_ft_spec, cool_closs_fplr_spec, cool_cap_fflow_spec, cool_eir_fflow_spec, cool_shrs_rated_gross, cooling_system.cooling_capacity, crankcase_kw, crankcase_temp, fan_power_rated)
      hvac_map[cooling_system.id] << clg_coil
    end

    if not heating_system.nil?
      heat_cfm = heating_system.heating_cfm

      # Heating Coil

      if heating_system.heating_system_fuel == HPXML::FuelTypeElectricity
        htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model)
        htg_coil.setEfficiency(heating_system.heating_efficiency_afue)
      else
        htg_coil = OpenStudio::Model::CoilHeatingGas.new(model)
        htg_coil.setGasBurnerEfficiency(heating_system.heating_efficiency_afue)
        htg_coil.setParasiticElectricLoad(0)
        htg_coil.setParasiticGasLoad(0)
        htg_coil.setFuelType(HelperMethods.eplus_fuel_map(heating_system.heating_system_fuel))
      end
      htg_coil.setName(obj_name + ' htg coil')
      if not heating_system.heating_capacity.nil?
        htg_coil.setNominalCapacity(UnitConversions.convert([heating_system.heating_capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
      end
      hvac_map[heating_system.id] << htg_coil
    end

    # Fan

    fan = create_supply_fan(model, obj_name, num_speeds, fan_power_installed)
    if not cooling_system.nil?
      hvac_map[cooling_system.id] += disaggregate_fan_or_pump(model, fan, nil, clg_coil, nil)
    end
    if not heating_system.nil?
      hvac_map[heating_system.id] += disaggregate_fan_or_pump(model, fan, htg_coil, nil, nil)
    end

    # Unitary System

    air_loop_unitary = create_air_loop_unitary_system(model, obj_name, fan, htg_coil, clg_coil, nil, clg_cfm: cool_cfm, htg_cfm: heat_cfm)
    if not cooling_system.nil?
      hvac_map[cooling_system.id] << air_loop_unitary
    end
    if not heating_system.nil?
      hvac_map[heating_system.id] << air_loop_unitary
    end

    if (not cooling_system.nil?) && (num_speeds > 1)
      # Unitary System Performance
      perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
      perf.setSingleModeOperation(false)
      for speed in 1..num_speeds
        f = OpenStudio::Model::SupplyAirflowRatioField.fromCoolingRatio(cool_fan_speed_ratios[speed - 1])
        perf.addSupplyAirflowRatioField(f)
      end
      air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
    end

    # Air Loop

    air_loop = create_air_loop(model, obj_name, air_loop_unitary, control_zone, sequential_heat_load_frac, sequential_cool_load_frac)
    if not cooling_system.nil?
      hvac_map[cooling_system.id] << air_loop
    end
    if not heating_system.nil?
      hvac_map[heating_system.id] << air_loop
    end

    # Store info for HVAC Sizing measure
    if not cooling_system.nil?
      air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, cool_capacity_ratios.join(','))
      air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cool_cfms_ton_rated.join(','))
      air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, cooling_system.fraction_cool_load_served)
      air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameCentralAirConditioner)
    end
    if not heating_system.nil?
      air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, heating_system.fraction_heat_load_served)
      air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameFurnace)
    end
  end

  def self.apply_room_air_conditioner(model, runner, cooling_system,
                                      remaining_cool_load_frac, control_zone,
                                      hvac_map)

    hvac_map[cooling_system.id] = []
    obj_name = Constants.ObjectNameRoomAirConditioner
    sequential_cool_load_frac = calc_sequential_load_fraction(cooling_system.fraction_cool_load_served, remaining_cool_load_frac)
    airflow_rate = 350.0 # cfm/ton; assumed

    # Performance curves
    # From Frigidaire 10.7 eer unit in Winkler et. al. Lab Testing of Window ACs (2013)

    cool_cap_ft_spec = [0.43945980246913574, -0.0008922469135802481, 0.00013984567901234569, 0.0038489259259259253, -5.6327160493827156e-05, 2.041358024691358e-05]
    cool_cap_ft_spec_si = convert_curve_biquadratic(cool_cap_ft_spec)
    cool_eir_ft_spec = [6.310506172839506, -0.17705185185185185, 0.0014645061728395061, 0.012571604938271608, 0.0001493827160493827, -0.00040308641975308644]
    cool_eir_ft_spec_si = convert_curve_biquadratic(cool_eir_ft_spec)
    cool_cap_fflow_spec = [0.887, 0.1128, 0]
    cool_eir_fflow_spec = [1.763, -0.6081, 0]
    cool_plf_fplr = [0.78, 0.22, 0]
    cfms_ton_rated = [312] # cfm/ton, medium speed

    roomac_cap_ft_curve = create_curve_biquadratic(model, cool_cap_ft_spec_si, 'RoomAC-Cap-fT', 0, 100, 0, 100)
    roomac_cap_fff_curve = create_curve_quadratic(model, cool_cap_fflow_spec, 'RoomAC-Cap-fFF', 0, 2, 0, 2)
    roomac_eir_ft_curve = create_curve_biquadratic(model, cool_eir_ft_spec_si, 'RoomAC-eir-fT', 0, 100, 0, 100)
    roomcac_eir_fff_curve = create_curve_quadratic(model, cool_eir_fflow_spec, 'RoomAC-eir-fFF', 0, 2, 0, 2)
    roomac_plf_fplr_curve = create_curve_quadratic(model, cool_plf_fplr, 'RoomAC-PLF-fPLR', 0, 1, 0, 1)

    # Cooling Coil

    clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, roomac_cap_ft_curve, roomac_cap_fff_curve, roomac_eir_ft_curve, roomcac_eir_fff_curve, roomac_plf_fplr_curve)
    clg_coil.setName(obj_name + ' clg coil')
    if not cooling_system.cooling_capacity.nil?
      clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert([cooling_system.cooling_capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
    end
    clg_coil.setRatedSensibleHeatRatio(cooling_system.cooling_shr)
    clg_coil.setRatedCOP(UnitConversions.convert(cooling_system.cooling_efficiency_eer, 'Btu/hr', 'W'))
    clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(773.3)
    clg_coil.setEvaporativeCondenserEffectiveness(0.9)
    clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(10)
    clg_coil.setBasinHeaterSetpointTemperature(2)
    hvac_map[cooling_system.id] << clg_coil

    # Fan

    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
    fan.setName(obj_name + ' supply fan')
    fan.setEndUseSubcategory('supply fan')
    fan.setFanEfficiency(1)
    fan.setPressureRise(0)
    fan.setMotorEfficiency(1)
    fan.setMotorInAirstreamFraction(0)
    hvac_map[cooling_system.id] += disaggregate_fan_or_pump(model, fan, nil, clg_coil, nil)

    # Heating Coil (none)

    htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOffDiscreteSchedule())
    htg_coil.setName(obj_name + ' htg coil')

    # PTAC

    ptac = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new(model, model.alwaysOnDiscreteSchedule, fan, htg_coil, clg_coil)
    ptac.setName(obj_name)
    ptac.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    ptac.addToThermalZone(control_zone)
    hvac_map[cooling_system.id] << ptac

    control_zone.setSequentialCoolingFractionSchedule(ptac, get_sequential_load_schedule(model, sequential_cool_load_frac))
    control_zone.setSequentialHeatingFractionSchedule(ptac, get_sequential_load_schedule(model, 0))

    # Store info for HVAC Sizing measure
    ptac.additionalProperties.setFeature(Constants.SizingInfoHVACCoolingCFMs, airflow_rate.to_s)
    ptac.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cfms_ton_rated.join(','))
    ptac.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, cooling_system.fraction_cool_load_served)
    ptac.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameRoomAirConditioner)
  end

  def self.apply_evaporative_cooler(model, runner, cooling_system,
                                    remaining_cool_load_frac, control_zone,
                                    hvac_map)

    hvac_map[cooling_system.id] = []
    obj_name = Constants.ObjectNameEvaporativeCooler
    sequential_cool_load_frac = calc_sequential_load_fraction(cooling_system.fraction_cool_load_served, remaining_cool_load_frac)

    # Evap Cooler

    evap_cooler = OpenStudio::Model::EvaporativeCoolerDirectResearchSpecial.new(model, model.alwaysOnDiscreteSchedule)
    evap_cooler.setName(obj_name)
    evap_cooler.setCoolerEffectiveness(0.72) # Assumed effectiveness
    evap_cooler.setEvaporativeOperationMinimumDrybulbTemperature(0) # relax limitation to open evap cooler for any potential cooling
    evap_cooler.setEvaporativeOperationMaximumLimitWetbulbTemperature(50) # relax limitation to open evap cooler for any potential cooling
    evap_cooler.setEvaporativeOperationMaximumLimitDrybulbTemperature(50) # relax limitation to open evap cooler for any potential cooling
    hvac_map[cooling_system.id] << evap_cooler

    # Air Loop

    air_loop = create_air_loop(model, obj_name, evap_cooler, control_zone, 0, sequential_cool_load_frac)
    air_loop.additionalProperties.setFeature(Constants.OptionallyDuctedSystemIsDucted, !cooling_system.distribution_system_idref.nil?)
    air_loop.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameEvaporativeCooler)
    hvac_map[cooling_system.id] << air_loop

    # Fan

    fan = OpenStudio::Model::FanVariableVolume.new(model, model.alwaysOnDiscreteSchedule)
    fan.setName(obj_name + ' supply fan')
    fan.setEndUseSubcategory('supply fan')
    fan.setFanEfficiency(1)
    fan.setMotorEfficiency(1)
    fan.setMotorInAirstreamFraction(0)
    fan.setFanPowerCoefficient1(0)
    fan.setFanPowerCoefficient2(1)
    fan.setFanPowerCoefficient3(0)
    fan.setFanPowerCoefficient4(0)
    fan.setFanPowerCoefficient5(0)
    fan.addToNode(air_loop.supplyInletNode)
    hvac_map[cooling_system.id] += disaggregate_fan_or_pump(model, fan, nil, evap_cooler, nil)

    # Outdoor air intake system
    oa_intake_controller = OpenStudio::Model::ControllerOutdoorAir.new(model)
    oa_intake_controller.setName("#{air_loop.name} OA Controller")
    oa_intake_controller.setMaximumOutdoorAirFlowRate(10) # Set an extreme large value here, will be reset by E+ using sized value
    oa_intake_controller.setMinimumLimitType('FixedMinimum')
    oa_intake_controller.resetEconomizerMinimumLimitDryBulbTemperature
    oa_intake_controller.setMinimumFractionofOutdoorAirSchedule(model.alwaysOnDiscreteSchedule)

    oa_intake = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, oa_intake_controller)
    oa_intake.setName("#{air_loop.name} OA System")
    oa_intake.addToNode(air_loop.supplyInletNode)

    # air handler controls
    # setpoint follows OAT WetBulb
    evap_stpt_manager = OpenStudio::Model::SetpointManagerFollowOutdoorAirTemperature.new(model)
    evap_stpt_manager.setName('Follow OATwb')
    evap_stpt_manager.setReferenceTemperatureType('OutdoorAirWetBulb')
    evap_stpt_manager.setOffsetTemperatureDifference(0.0)
    evap_stpt_manager.addToNode(air_loop.supplyOutletNode)

    # Store info for HVAC Sizing measure
    evap_cooler.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, cooling_system.fraction_cool_load_served)
    evap_cooler.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameEvaporativeCooler)
  end

  def self.apply_central_air_to_air_heat_pump(model, runner, heat_pump,
                                              remaining_heat_load_frac,
                                              remaining_cool_load_frac,
                                              control_zone, hvac_map)

    hvac_map[heat_pump.id] = []
    obj_name = Constants.ObjectNameAirSourceHeatPump
    sequential_heat_load_frac = calc_sequential_load_fraction(heat_pump.fraction_heat_load_served, remaining_heat_load_frac)
    sequential_cool_load_frac = calc_sequential_load_fraction(heat_pump.fraction_cool_load_served, remaining_cool_load_frac)
    if heat_pump.compressor_type == HPXML::HVACCompressorTypeSingleStage
      num_speeds = 1
    elsif heat_pump.compressor_type == HPXML::HVACCompressorTypeTwoStage
      num_speeds = 2
    elsif heat_pump.compressor_type == HPXML::HVACCompressorTypeVariableSpeed
      num_speeds = 4
    end
    fan_power_rated = get_fan_power_rated(heat_pump.cooling_efficiency_seer)
    fan_power_installed = get_fan_power_installed(heat_pump.cooling_efficiency_seer)
    if heat_pump.fraction_heat_load_served <= 0
      crankcase_kw, crankcase_temp = 0, nil
    else
      crankcase_kw, crankcase_temp = get_crankcase_assumptions()
    end
    hp_min_temp, supp_max_temp = get_heatpump_temp_assumptions(heat_pump)

    # Cooling Coil

    cool_c_d = get_cool_c_d(num_speeds, heat_pump.cooling_efficiency_seer)
    if num_speeds == 1
      cool_rated_airflow_rate = 394.2 # cfm/ton
      cool_capacity_ratios = [1.0]
      cool_fan_speed_ratios = [1.0]
      cool_shrs = [heat_pump.cooling_shr]
      cool_cap_ft_spec = [[3.68637657, -0.098352478, 0.000956357, 0.005838141, -0.0000127, -0.000131702]]
      cool_eir_ft_spec = [[-3.437356399, 0.136656369, -0.001049231, -0.0079378, 0.000185435, -0.0001441]]
      cool_cap_fflow_spec = [[0.718664047, 0.41797409, -0.136638137]]
      cool_eir_fflow_spec = [[1.143487507, -0.13943972, -0.004047787]]
      cool_eers = [calc_eer_cooling_1speed(heat_pump.cooling_efficiency_seer, fan_power_rated, cool_eir_ft_spec)]
    elsif num_speeds == 2
      cool_rated_airflow_rate = 344.1 # cfm/ton
      cool_capacity_ratios = [0.72, 1.0]
      cool_fan_speed_ratios = [0.86, 1.0]
      cool_shrs = [heat_pump.cooling_shr - 0.014, heat_pump.cooling_shr] # TODO: is the following assumption correct (revisit Dylan's data?)? OR should value from HPXML be used for both stages?
      cool_cap_ft_spec = [[3.998418659, -0.108728222, 0.001056818, 0.007512314, -0.0000139, -0.000164716],
                          [3.466810106, -0.091476056, 0.000901205, 0.004163355, -0.00000919, -0.000110829]]
      cool_eir_ft_spec = [[-4.282911381, 0.181023691, -0.001357391, -0.026310378, 0.000333282, -0.000197405],
                          [-3.557757517, 0.112737397, -0.000731381, 0.013184877, 0.000132645, -0.000338716]]
      cool_cap_fflow_spec = [[0.655239515, 0.511655216, -0.166894731],
                             [0.618281092, 0.569060264, -0.187341356]]
      cool_eir_fflow_spec = [[1.639108268, -0.998953996, 0.359845728],
                             [1.570774717, -0.914152018, 0.343377302]]
      cool_eers = calc_eers_cooling_2speed(runner, heat_pump.cooling_efficiency_seer, cool_c_d, cool_capacity_ratios, cool_fan_speed_ratios, fan_power_rated, cool_eir_ft_spec, cool_cap_ft_spec, true)
    elsif num_speeds == 4
      cool_rated_airflow_rate = 411.0 # cfm/ton
      cool_capacity_ratios = [0.36, 0.51, 0.67, 1.0]
      cool_fan_speed_ratios = [0.42, 0.54, 0.68, 1.0]
      cool_shrs = [1.115, 1.026, 1.013, 1.0].map { |mult| heat_pump.cooling_shr * mult }
      # The following coefficients were generated using NREL experimental performance mapping for the Carrier unit
      cool_cap_coeff_perf_map = [[1.6516044444444447, 0.0698916049382716, -0.0005546296296296296, -0.08870160493827162, 0.0004135802469135802, 0.00029077160493827157],
                                 [-6.84948049382716, 0.26946, -0.0019413580246913577, -0.03281469135802469, 0.00015694444444444442, 3.32716049382716e-05],
                                 [-4.53543086419753, 0.15358543209876546, -0.0009345679012345678, 0.002666913580246914, -7.993827160493826e-06, -0.00011617283950617283],
                                 [-3.500948395061729, 0.11738987654320988, -0.0006580246913580248, 0.007003148148148148, -2.8518518518518517e-05, -0.0001284259259259259],
                                 [1.8769221728395058, -0.04768641975308643, 0.0006885802469135801, 0.006643395061728395, 1.4209876543209876e-05, -0.00024043209876543206]]
      cool_cap_ft_spec = cool_cap_coeff_perf_map.select { |i| [0, 1, 2, 4].include? cool_cap_coeff_perf_map.index(i) }
      cool_cap_ft_spec_3 = cool_cap_coeff_perf_map.select { |i| [0, 1, 4].include? cool_cap_coeff_perf_map.index(i) }
      cool_eir_coeff_perf_map = [[2.896298765432099, -0.12487654320987657, 0.0012148148148148148, 0.04492037037037037, 8.734567901234567e-05, -0.0006348765432098764],
                                 [6.428076543209876, -0.20913209876543212, 0.0018521604938271604, 0.024392592592592594, 0.00019691358024691356, -0.0006012345679012346],
                                 [5.136356049382716, -0.1591530864197531, 0.0014151234567901232, 0.018665555555555557, 0.00020398148148148147, -0.0005407407407407407],
                                 [1.3823471604938273, -0.02875123456790123, 0.00038302469135802463, 0.006344814814814816, 0.00024836419753086417, -0.00047469135802469134],
                                 [-1.0411735802469133, 0.055261604938271605, -0.0004404320987654321, 0.0002154938271604939, 0.00017484567901234564, -0.0002017901234567901]]
      cool_eir_ft_spec = cool_eir_coeff_perf_map.select { |i| [0, 1, 2, 4].include? cool_eir_coeff_perf_map.index(i) }
      cool_eir_ft_spec_3 = cool_eir_coeff_perf_map.select { |i| [0, 1, 4].include? cool_eir_coeff_perf_map.index(i) }
      cool_eir_fflow_spec = [[1, 0, 0]] * 4
      cool_cap_fflow_spec = [[1, 0, 0]] * 4
      cap_ratio_seer_3 = cool_capacity_ratios.select { |i| [0, 1, 3].include? cool_capacity_ratios.index(i) }
      fan_speed_seer_3 = cool_fan_speed_ratios.select { |i| [0, 1, 3].include? cool_fan_speed_ratios.index(i) }
      cool_eers = calc_eers_cooling_4speed(runner, heat_pump.cooling_efficiency_seer, cool_c_d, cap_ratio_seer_3, fan_speed_seer_3, fan_power_rated, cool_eir_ft_spec_3, cool_cap_ft_spec_3)
    end
    cool_cfms_ton_rated = calc_cfms_ton_rated(cool_rated_airflow_rate, cool_fan_speed_ratios, cool_capacity_ratios)
    cool_shrs_rated_gross = calc_shrs_rated_gross(num_speeds, cool_shrs, fan_power_rated, cool_cfms_ton_rated)
    cool_eirs = calc_cool_eirs(num_speeds, cool_eers, fan_power_rated)
    cool_closs_fplr_spec = [calc_plr_coefficients(cool_c_d)] * num_speeds
    clg_coil = create_dx_cooling_coil(model, obj_name, (0...num_speeds).to_a, cool_eirs, cool_cap_ft_spec, cool_eir_ft_spec, cool_closs_fplr_spec, cool_cap_fflow_spec, cool_eir_fflow_spec, cool_shrs_rated_gross, heat_pump.cooling_capacity, 0, nil, fan_power_rated)
    hvac_map[heat_pump.id] << clg_coil

    # Heating Coil

    heat_c_d = get_heat_c_d(num_speeds, heat_pump.heating_efficiency_hspf)
    if num_speeds == 1
      heat_rated_airflow_rate = 384.1 # cfm/ton
      heat_capacity_ratios = [1.0]
      heat_fan_speed_ratios = [1.0]
      heat_eir_ft_spec = [[0.718398423, 0.003498178, 0.000142202, -0.005724331, 0.00014085, -0.000215321]]
      heat_cap_fflow_spec = [[0.694045465, 0.474207981, -0.168253446]]
      heat_eir_fflow_spec = [[2.185418751, -1.942827919, 0.757409168]]
      if heat_pump.heating_capacity_17F.nil?
        heat_cap_ft_spec = [[0.566333415, -0.000744164, -0.0000103, 0.009414634, 0.0000506, -0.00000675]]
      else
        heat_cap_ft_spec = calc_heat_cap_ft_spec_using_capacity_17F(num_speeds, heat_pump)
      end
      heat_cops = [calc_cop_heating_1speed(heat_pump.heating_efficiency_hspf, heat_c_d, fan_power_rated, heat_eir_ft_spec, heat_cap_ft_spec)]
    elsif num_speeds == 2
      heat_rated_airflow_rate = 352.2 # cfm/ton
      heat_capacity_ratios = [0.72, 1.0]
      heat_fan_speed_ratios = [0.8, 1.0]
      heat_eir_ft_spec = [[0.36338171, 0.013523725, 0.000258872, -0.009450269, 0.000439519, -0.000653723],
                          [0.981100941, -0.005158493, 0.000243416, -0.005274352, 0.000230742, -0.000336954]]
      heat_cap_fflow_spec = [[0.741466907, 0.378645444, -0.119754733],
                             [0.76634609, 0.32840943, -0.094701495]]
      heat_eir_fflow_spec = [[2.153618211, -1.737190609, 0.584269478],
                             [2.001041353, -1.58869128, 0.587593517]]
      if heat_pump.heating_capacity_17F.nil?
        heat_cap_ft_spec = [[0.335690634, 0.002405123, -0.0000464, 0.013498735, 0.0000499, -0.00000725],
                            [0.306358843, 0.005376987, -0.0000579, 0.011645092, 0.0000591, -0.0000203]]
      else
        heat_cap_ft_spec = calc_heat_cap_ft_spec_using_capacity_17F(num_speeds, heat_pump)
      end
      heat_cops = calc_cops_heating_2speed(heat_pump.heating_efficiency_hspf, heat_c_d, heat_capacity_ratios, heat_fan_speed_ratios, fan_power_rated, heat_eir_ft_spec, heat_cap_ft_spec)
    elsif num_speeds == 4
      heat_rated_airflow_rate = 296.9 # cfm/ton
      heat_capacity_ratios = [0.33, 0.56, 1.0, 1.17]
      heat_fan_speed_ratios = [0.63, 0.76, 1.0, 1.19]
      heat_eir_ft_spec = [[0.708311527, 0.020732093, 0.000391479, -0.037640031, 0.000979937, -0.001079042],
                          [0.025480155, 0.020169585, 0.000121341, -0.004429789, 0.000166472, -0.00036447],
                          [0.379003189, 0.014195012, 0.0000821046, -0.008894061, 0.000151519, -0.000210299],
                          [0.690404655, 0.00616619, 0.000137643, -0.009350199, 0.000153427, -0.000213258]]
      heat_cap_fflow_spec = [[1, 0, 0]] * 4
      heat_eir_fflow_spec = [[1, 0, 0]] * 4
      if heat_pump.heating_capacity_17F.nil?
        heat_cap_ft_spec = [[0.304192655, -0.003972566, 0.0000196432, 0.024471251, -0.000000774126, -0.0000841323],
                            [0.496381324, -0.00144792, 0.0, 0.016020855, 0.0000203447, -0.0000584118],
                            [0.697171186, -0.006189599, 0.0000337077, 0.014291981, 0.0000105633, -0.0000387956],
                            [0.555513805, -0.001337363, -0.00000265117, 0.014328826, 0.0000163849, -0.0000480711]]
      else
        heat_cap_ft_spec = calc_heat_cap_ft_spec_using_capacity_17F(num_speeds, heat_pump)
      end
      heat_cops = calc_cops_heating_4speed(runner, heat_pump.heating_efficiency_hspf, heat_c_d, heat_capacity_ratios, heat_fan_speed_ratios, fan_power_rated, heat_eir_ft_spec, heat_cap_ft_spec)
    end
    heat_cfms_ton_rated = calc_cfms_ton_rated(heat_rated_airflow_rate, heat_fan_speed_ratios, heat_capacity_ratios)
    heat_eirs = calc_heat_eirs(num_speeds, heat_cops, fan_power_rated)
    heat_closs_fplr_spec = [calc_plr_coefficients(heat_c_d)] * num_speeds
    htg_coil = create_dx_heating_coil(model, obj_name, (0...num_speeds).to_a, heat_eirs, heat_cap_ft_spec, heat_eir_ft_spec, heat_closs_fplr_spec, heat_cap_fflow_spec, heat_eir_fflow_spec, heat_pump.heating_capacity, crankcase_kw, crankcase_temp, fan_power_rated, hp_min_temp)
    hvac_map[heat_pump.id] << htg_coil

    # Supplemental Heating Coil

    htg_supp_coil = create_supp_heating_coil(model, obj_name, heat_pump)
    hvac_map[heat_pump.id] << htg_supp_coil

    # Fan

    fan = create_supply_fan(model, obj_name, num_speeds, fan_power_installed)
    hvac_map[heat_pump.id] += disaggregate_fan_or_pump(model, fan, htg_coil, clg_coil, htg_supp_coil)

    # Unitary System

    air_loop_unitary = create_air_loop_unitary_system(model, obj_name, fan, htg_coil, clg_coil, htg_supp_coil, supp_max_temp)
    hvac_map[heat_pump.id] << air_loop_unitary

    if num_speeds > 1
      # Unitary System Performance
      perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
      perf.setSingleModeOperation(false)
      for speed in 1..num_speeds
        f = OpenStudio::Model::SupplyAirflowRatioField.new(heat_fan_speed_ratios[speed - 1], cool_fan_speed_ratios[speed - 1])
        perf.addSupplyAirflowRatioField(f)
      end
      air_loop_unitary.setDesignSpecificationMultispeedObject(perf)
    end

    # Air Loop

    air_loop = create_air_loop(model, obj_name, air_loop_unitary, control_zone, sequential_heat_load_frac, sequential_cool_load_frac)
    hvac_map[heat_pump.id] << air_loop

    # Store info for HVAC Sizing measure
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioHeating, heat_capacity_ratios.join(','))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, cool_capacity_ratios.join(','))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonHeating, heat_cfms_ton_rated.join(','))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cool_cfms_ton_rated.join(','))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, heat_pump.fraction_heat_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, heat_pump.fraction_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameAirSourceHeatPump)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameAirSourceHeatPump)
  end

  def self.apply_mini_split_heat_pump(model, runner, heat_pump,
                                      remaining_heat_load_frac,
                                      remaining_cool_load_frac,
                                      control_zone, hvac_map)

    hvac_map[heat_pump.id] = []
    obj_name = Constants.ObjectNameMiniSplitHeatPump
    sequential_heat_load_frac = calc_sequential_load_fraction(heat_pump.fraction_heat_load_served, remaining_heat_load_frac)
    sequential_cool_load_frac = calc_sequential_load_fraction(heat_pump.fraction_cool_load_served, remaining_cool_load_frac)
    num_speeds = 10
    mshp_indices = [1, 3, 5, 9]
    hp_min_temp, supp_max_temp = get_heatpump_temp_assumptions(heat_pump)
    fan_power_installed = 0.07 # W/cfm
    pan_heater_power = 0.0 # W, disabled

    # Calculate generic inputs
    min_cooling_capacity = 0.4 # frac
    max_cooling_capacity = 1.2 # frac
    min_cooling_airflow_rate = 200.0
    max_cooling_airflow_rate = 425.0
    min_heating_capacity = 0.3 # frac
    max_heating_capacity = 1.2 # frac
    min_heating_airflow_rate = 200.0
    max_heating_airflow_rate = 400.0
    if heat_pump.heating_capacity.nil?
      heating_capacity_offset = 2300.0 # Btu/hr
    else
      heating_capacity_offset = heat_pump.heating_capacity - heat_pump.cooling_capacity
    end
    if heat_pump.heating_capacity_17F.nil?
      cap_retention_frac = 0.25 # frac
      cap_retention_temp = -5.0 # deg-F
    else
      cap_retention_frac = heat_pump.heating_capacity_17F / heat_pump.heating_capacity
      cap_retention_temp = 17.0 # deg-F
    end

    # Cooling Coil

    cool_cap_ft_spec = [[0.7531983499655835, 0.003618193903031667, 0.0, 0.006574385031351544, -6.87181191015432e-05, 0.0]] * num_speeds
    cool_eir_ft_spec = [[-0.06376924779982301, -0.0013360593470367282, 1.413060577993827e-05, 0.019433076486584752, -4.91395947154321e-05, -4.909341249475308e-05]] * num_speeds
    cool_cap_fflow_spec = [[1, 0, 0]] * num_speeds
    cool_eir_fflow_spec = [[1, 0, 0]] * num_speeds
    cool_c_d = get_cool_c_d(num_speeds, heat_pump.cooling_efficiency_seer)
    cool_closs_fplr_spec = [calc_plr_coefficients(cool_c_d)] * num_speeds
    dB_rated = 80.0 # deg-F
    wB_rated = 67.0 # deg-F
    cool_cfms_ton_rated, cool_capacity_ratios, cool_shrs_rated_gross = calc_mshp_cfms_ton_cooling(min_cooling_capacity, max_cooling_capacity, min_cooling_airflow_rate, max_cooling_airflow_rate, num_speeds, dB_rated, wB_rated, heat_pump.cooling_shr)
    cool_eirs = calc_mshp_cool_eirs(runner, heat_pump.cooling_efficiency_seer, fan_power_installed, cool_c_d, num_speeds, cool_capacity_ratios, cool_cfms_ton_rated, cool_eir_ft_spec, cool_cap_ft_spec)
    clg_coil = create_dx_cooling_coil(model, obj_name, mshp_indices, cool_eirs, cool_cap_ft_spec, cool_eir_ft_spec, cool_closs_fplr_spec, cool_cap_fflow_spec, cool_eir_fflow_spec, cool_shrs_rated_gross, heat_pump.cooling_capacity, 0.0, nil, nil)
    hvac_map[heat_pump.id] << clg_coil

    # Heating Coil

    # cop/eir as a function of temperature
    # Generic curves (=Daikin from lab data)
    heat_eir_ft_spec = [[0.9999941697687026, 0.004684593830254383, 5.901286675833333e-05, -0.0028624467783091973, 1.3041120194135802e-05, -0.00016172918478765433]] * num_speeds
    heat_cap_fflow_spec = [[1, 0, 0]] * num_speeds
    heat_eir_fflow_spec = [[1, 0, 0]] * num_speeds

    # Derive coefficients from user input for capacity retention at outdoor drybulb temperature X [C].
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
    heat_cap_ft_spec = [convert_curve_biquadratic([a, b, c, d, e, f], false)] * num_speeds

    heat_c_d = get_heat_c_d(num_speeds, heat_pump.heating_efficiency_hspf)
    heat_closs_fplr_spec = [calc_plr_coefficients(heat_c_d)] * num_speeds
    heat_cfms_ton_rated, heat_capacity_ratios = calc_mshp_cfms_ton_heating(min_heating_capacity, max_heating_capacity, min_heating_airflow_rate, max_heating_airflow_rate, num_speeds)
    heat_eirs = calc_mshp_heat_eirs(runner, heat_pump.heating_efficiency_hspf, fan_power_installed, hp_min_temp, heat_c_d, cool_cfms_ton_rated, num_speeds, heat_capacity_ratios, heat_cfms_ton_rated, heat_eir_ft_spec, heat_cap_ft_spec)
    htg_coil = create_dx_heating_coil(model, obj_name, mshp_indices, heat_eirs, heat_cap_ft_spec, heat_eir_ft_spec, heat_closs_fplr_spec, heat_cap_fflow_spec, heat_eir_fflow_spec, heat_pump.heating_capacity, 0.0, nil, nil, hp_min_temp)
    hvac_map[heat_pump.id] << htg_coil

    # Supplemental Heating Coil

    htg_supp_coil = create_supp_heating_coil(model, obj_name, heat_pump)
    hvac_map[heat_pump.id] << htg_supp_coil

    # Fan

    fan_power_curve = create_curve_exponent(model, [0, 1, 3], obj_name + ' fan power curve', -100, 100)
    fan_eff_curve = create_curve_cubic(model, [0, 1, 0, 0], obj_name + ' fan eff curve', 0, 1, 0.01, 1)
    fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule, fan_power_curve, fan_eff_curve)
    fan_eff = UnitConversions.convert(UnitConversions.convert(0.1, 'inH2O', 'Pa') / fan_power_installed, 'cfm', 'm^3/s') # Overall Efficiency of the Fan, Motor and Drive
    fan.setName(obj_name + ' supply fan')
    fan.setEndUseSubcategory('supply fan')
    fan.setFanEfficiency(fan_eff)
    fan.setPressureRise(calc_fan_pressure_rise(fan_eff, fan_power_installed))
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    hvac_map[heat_pump.id] += disaggregate_fan_or_pump(model, fan, htg_coil, clg_coil, htg_supp_coil)

    # Unitary System

    air_loop_unitary = create_air_loop_unitary_system(model, obj_name, fan, htg_coil, clg_coil, htg_supp_coil, supp_max_temp)
    hvac_map[heat_pump.id] << air_loop_unitary

    perf = OpenStudio::Model::UnitarySystemPerformanceMultispeed.new(model)
    perf.setSingleModeOperation(false)
    mshp_indices.each do |mshp_index|
      ratio_heating = heat_cfms_ton_rated[mshp_index] / heat_cfms_ton_rated[mshp_indices[-1]]
      ratio_cooling = cool_cfms_ton_rated[mshp_index] / cool_cfms_ton_rated[mshp_indices[-1]]
      f = OpenStudio::Model::SupplyAirflowRatioField.new(ratio_heating, ratio_cooling)
      perf.addSupplyAirflowRatioField(f)
    end
    air_loop_unitary.setDesignSpecificationMultispeedObject(perf)

    # Air Loop

    air_loop = create_air_loop(model, obj_name, air_loop_unitary, control_zone, sequential_heat_load_frac, sequential_cool_load_frac)
    hvac_map[heat_pump.id] << air_loop

    if pan_heater_power > 0

      mshp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Heating Coil Electric Energy')
      mshp_sensor.setName("#{obj_name} vrf energy sensor")
      mshp_sensor.setKeyName(obj_name + ' coil')

      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName(obj_name + ' pan heater equip')
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName(equip_def.name.to_s)
      equip.setSpace(control_zone.spaces[0])
      equip_def.setFractionRadiant(0)
      equip_def.setFractionLatent(0)
      equip_def.setFractionLost(1)
      equip.setSchedule(model.alwaysOnDiscreteSchedule)
      equip.setEndUseSubcategory(obj_name + ' pan heater')

      pan_heater_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, 'ElectricEquipment', 'Electric Power Level')
      pan_heater_actuator.setName("#{obj_name} pan heater actuator")

      tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Outdoor Air Drybulb Temperature')
      tout_sensor.setName("#{obj_name} tout sensor")
      thermal_zones.each do |thermal_zone|
        if Geometry.is_living(thermal_zone)
          tout_sensor.setKeyName(thermal_zone.name.to_s)
          break
        end
      end

      program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      program.setName(obj_name + ' pan heater program')
      if not heat_pump.cooling_capacity.nil?
        num_outdoor_units = (UnitConversions.convert([heat_pump.cooling_capacity, Constants.small].max, 'Btu/hr', 'ton') / 1.5).ceil # Assume 1.5 tons max per outdoor unit
      else
        num_outdoor_units = 2
      end
      pan_heater_power *= num_outdoor_units # W
      program.addLine("Set #{pan_heater_actuator.name} = 0")
      program.addLine("If #{mshp_sensor.name} > 0")
      program.addLine("  If #{tout_sensor.name} <= #{UnitConversions.convert(32.0, 'F', 'C').round(3)}")
      program.addLine("    Set #{pan_heater_actuator.name} = #{pan_heater_power}")
      program.addLine('  EndIf')
      program.addLine('EndIf')

      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName(obj_name + ' pan heater program calling manager')
      program_calling_manager.setCallingPoint('BeginTimestepBeforePredictor')
      program_calling_manager.addProgram(program)

    end

    # Store info for HVAC Sizing measure
    heat_capacity_ratios_4 = []
    cool_capacity_ratios_4 = []
    heat_cfms_ton_rated_4 = []
    cool_cfms_ton_rated_4 = []
    cool_shrs_rated_gross_4 = []
    mshp_indices.each do |mshp_index|
      heat_capacity_ratios_4 << heat_capacity_ratios[mshp_index]
      cool_capacity_ratios_4 << cool_capacity_ratios[mshp_index]
      heat_cfms_ton_rated_4 << heat_cfms_ton_rated[mshp_index]
      cool_cfms_ton_rated_4 << cool_cfms_ton_rated[mshp_index]
      cool_shrs_rated_gross_4 << cool_shrs_rated_gross[mshp_index]
    end
    air_loop_unitary.additionalProperties.setFeature(Constants.OptionallyDuctedSystemIsDucted, !heat_pump.distribution_system_idref.nil?)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioHeating, heat_capacity_ratios_4.join(','))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCapacityRatioCooling, cool_capacity_ratios_4.join(','))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatingCFMs, heat_cfms_ton_rated_4.join(','))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolingCFMs, cool_cfms_ton_rated_4.join(','))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatingCapacityOffset, heating_capacity_offset)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, heat_pump.fraction_heat_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, heat_pump.fraction_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACSHR, cool_shrs_rated_gross_4.join(','))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameMiniSplitHeatPump)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameMiniSplitHeatPump)
  end

  def self.apply_ground_to_air_heat_pump(model, runner, weather, heat_pump,
                                         remaining_heat_load_frac, remaining_cool_load_frac,
                                         control_zone, hvac_map)

    hvac_map[heat_pump.id] = []
    obj_name = Constants.ObjectNameGroundSourceHeatPump
    sequential_heat_load_frac = calc_sequential_load_fraction(heat_pump.fraction_heat_load_served, remaining_heat_load_frac)
    sequential_cool_load_frac = calc_sequential_load_fraction(heat_pump.fraction_cool_load_served, remaining_cool_load_frac)
    pipe_cond = 0.23 # Pipe thermal conductivity, default to high density polyethylene
    ground_conductivity = 0.6
    grout_conductivity = 0.4
    bore_config = nil # Autosize
    bore_holes = nil # Autosize
    bore_depth = nil # Autosize
    bore_spacing = 20.0
    bore_diameter = 5.0
    pipe_size = 0.75
    ground_diffusivity = 0.0208
    fluid_type = Constants.FluidPropyleneGlycol
    frac_glycol = 0.3
    design_delta_t = 10.0
    pump_head = 50.0
    u_tube_leg_spacing = 0.9661
    u_tube_spacing_type = 'b'
    fan_power_installed = 0.5 # W/cfm
    chw_design = [85.0, weather.design.CoolingDrybulb - 15.0, weather.data.AnnualAvgDrybulb + 10.0].max # Temperature of water entering indoor coil,use 85F as lower bound
    if fluid_type == Constants.FluidWater
      hw_design = [45.0, weather.design.HeatingDrybulb + 35.0, weather.data.AnnualAvgDrybulb - 10.0].max # Temperature of fluid entering indoor coil, use 45F as lower bound for water
    else
      hw_design = [35.0, weather.design.HeatingDrybulb + 35.0, weather.data.AnnualAvgDrybulb - 10.0].min # Temperature of fluid entering indoor coil, use 35F as upper bound
    end
    # Pipe nominal size conversion to pipe outside diameter and inside diameter,
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

    if frac_glycol == 0
      fluid_type = Constants.FluidWater
      runner.registerWarning("Specified #{fluid_type} fluid type and 0 fraction of glycol, so assuming #{Constants.FluidWater} fluid type.")
    end

    # Cooling Coil

    coil_bf = 0.08060000
    cool_cap_ft_spec = [0.39039063, 0.01382596, 0.00000000, -0.00445738, 0.00000000, 0.00000000]
    cool_SH_ft_spec = [4.27136253, -0.04678521, 0.00000000, -0.00219031, 0.00000000, 0.00000000]
    cool_power_ft_spec = [0.01717338, 0.00316077, 0.00000000, 0.01043792, 0.00000000, 0.00000000]
    coil_bf_ft_spec = [1.21005458, -0.00664200, 0.00000000, 0.00348246, 0.00000000, 0.00000000]
    gshp_cool_cap_fT_coeff = convert_curve_gshp(cool_cap_ft_spec, false)
    gshp_cool_power_fT_coeff = convert_curve_gshp(cool_power_ft_spec, false)
    gshp_cool_SH_fT_coeff = convert_curve_gshp(cool_SH_ft_spec, false)

    fan_adjust_kw = UnitConversions.convert(400.0, 'Btu/hr', 'ton') * UnitConversions.convert(1.0, 'cfm', 'm^3/s') * 1000.0 * 0.35 * 249.0 / 300.0 # Adjustment per ISO 13256-1 Internal pressure drop across heat pump assumed to be 0.5 in. w.g.
    pump_adjust_kw = UnitConversions.convert(3.0, 'Btu/hr', 'ton') * UnitConversions.convert(1.0, 'gal/min', 'm^3/s') * 1000.0 * 6.0 * 2990.0 / 3000.0 # Adjustment per ISO 13256-1 Internal Pressure drop across heat pump coil assumed to be 11ft w.g.
    cooling_eir = UnitConversions.convert((1.0 - heat_pump.cooling_efficiency_eer * (fan_adjust_kw + pump_adjust_kw)) / (heat_pump.cooling_efficiency_eer * (1.0 + UnitConversions.convert(fan_adjust_kw, 'Wh', 'Btu'))), 'Wh', 'Btu')

    clg_coil = OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit.new(model)
    clg_coil.setName(obj_name + ' clg coil')
    if not heat_pump.cooling_capacity.nil?
      clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert([heat_pump.cooling_capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
    end
    clg_coil.setRatedCoolingCoefficientofPerformance(1.0 / cooling_eir)
    clg_coil.setTotalCoolingCapacityCoefficient1(gshp_cool_cap_fT_coeff[0])
    clg_coil.setTotalCoolingCapacityCoefficient2(gshp_cool_cap_fT_coeff[1])
    clg_coil.setTotalCoolingCapacityCoefficient3(gshp_cool_cap_fT_coeff[2])
    clg_coil.setTotalCoolingCapacityCoefficient4(gshp_cool_cap_fT_coeff[3])
    clg_coil.setTotalCoolingCapacityCoefficient5(gshp_cool_cap_fT_coeff[4])
    clg_coil.setSensibleCoolingCapacityCoefficient1(gshp_cool_SH_fT_coeff[0])
    clg_coil.setSensibleCoolingCapacityCoefficient2(0)
    clg_coil.setSensibleCoolingCapacityCoefficient3(gshp_cool_SH_fT_coeff[1])
    clg_coil.setSensibleCoolingCapacityCoefficient4(gshp_cool_SH_fT_coeff[2])
    clg_coil.setSensibleCoolingCapacityCoefficient5(gshp_cool_SH_fT_coeff[3])
    clg_coil.setSensibleCoolingCapacityCoefficient6(gshp_cool_SH_fT_coeff[4])
    clg_coil.setCoolingPowerConsumptionCoefficient1(gshp_cool_power_fT_coeff[0])
    clg_coil.setCoolingPowerConsumptionCoefficient2(gshp_cool_power_fT_coeff[1])
    clg_coil.setCoolingPowerConsumptionCoefficient3(gshp_cool_power_fT_coeff[2])
    clg_coil.setCoolingPowerConsumptionCoefficient4(gshp_cool_power_fT_coeff[3])
    clg_coil.setCoolingPowerConsumptionCoefficient5(gshp_cool_power_fT_coeff[4])
    clg_coil.setNominalTimeforCondensateRemovaltoBegin(1000)
    clg_coil.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
    hvac_map[heat_pump.id] << clg_coil

    # Heating Coil

    heat_cap_ft_spec = [0.67104926, -0.00210834, 0.00000000, 0.01491424, 0.00000000, 0.00000000]
    heat_power_ft_spec = [-0.46308105, 0.02008988, 0.00000000, 0.00300222, 0.00000000, 0.00000000]
    gshp_heat_cap_fT_coeff = convert_curve_gshp(heat_cap_ft_spec, false)
    gshp_heat_power_fT_coeff = convert_curve_gshp(heat_power_ft_spec, false)

    heating_eir = (1.0 - heat_pump.heating_efficiency_cop * (fan_adjust_kw + pump_adjust_kw)) / (heat_pump.heating_efficiency_cop * (1.0 - fan_adjust_kw))

    htg_coil = OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit.new(model)
    htg_coil.setName(obj_name + ' htg coil')
    if not heat_pump.heating_capacity.nil?
      htg_coil.setRatedHeatingCapacity(UnitConversions.convert([heat_pump.heating_capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
    end
    htg_coil.setRatedHeatingCoefficientofPerformance(1.0 / heating_eir)
    htg_coil.setHeatingCapacityCoefficient1(gshp_heat_cap_fT_coeff[0])
    htg_coil.setHeatingCapacityCoefficient2(gshp_heat_cap_fT_coeff[1])
    htg_coil.setHeatingCapacityCoefficient3(gshp_heat_cap_fT_coeff[2])
    htg_coil.setHeatingCapacityCoefficient4(gshp_heat_cap_fT_coeff[3])
    htg_coil.setHeatingCapacityCoefficient5(gshp_heat_cap_fT_coeff[4])
    htg_coil.setHeatingPowerConsumptionCoefficient1(gshp_heat_power_fT_coeff[0])
    htg_coil.setHeatingPowerConsumptionCoefficient2(gshp_heat_power_fT_coeff[1])
    htg_coil.setHeatingPowerConsumptionCoefficient3(gshp_heat_power_fT_coeff[2])
    htg_coil.setHeatingPowerConsumptionCoefficient4(gshp_heat_power_fT_coeff[3])
    htg_coil.setHeatingPowerConsumptionCoefficient5(gshp_heat_power_fT_coeff[4])
    hvac_map[heat_pump.id] << htg_coil

    # Supplemental Heating Coil

    htg_supp_coil = create_supp_heating_coil(model, obj_name, heat_pump)
    hvac_map[heat_pump.id] << htg_supp_coil

    # Ground Heat Exchanger

    ground_heat_exch_vert = OpenStudio::Model::GroundHeatExchangerVertical.new(model)
    ground_heat_exch_vert.setName(obj_name + ' exchanger')
    ground_heat_exch_vert.setBoreHoleRadius(UnitConversions.convert(bore_diameter / 2.0, 'in', 'm'))
    ground_heat_exch_vert.setGroundThermalConductivity(UnitConversions.convert(ground_conductivity, 'Btu/(hr*ft*R)', 'W/(m*K)'))
    ground_heat_exch_vert.setGroundThermalHeatCapacity(UnitConversions.convert(ground_conductivity / ground_diffusivity, 'Btu/(ft^3*F)', 'J/(m^3*K)'))
    ground_heat_exch_vert.setGroundTemperature(UnitConversions.convert(weather.data.AnnualAvgDrybulb, 'F', 'C'))
    ground_heat_exch_vert.setGroutThermalConductivity(UnitConversions.convert(grout_conductivity, 'Btu/(hr*ft*R)', 'W/(m*K)'))
    ground_heat_exch_vert.setPipeThermalConductivity(UnitConversions.convert(pipe_cond, 'Btu/(hr*ft*R)', 'W/(m*K)'))
    ground_heat_exch_vert.setPipeOutDiameter(UnitConversions.convert(pipe_od, 'in', 'm'))
    ground_heat_exch_vert.setUTubeDistance(UnitConversions.convert(u_tube_leg_spacing, 'in', 'm'))
    ground_heat_exch_vert.setPipeThickness(UnitConversions.convert((pipe_od - pipe_id) / 2.0, 'in', 'm'))
    ground_heat_exch_vert.setMaximumLengthofSimulation(1)
    ground_heat_exch_vert.setGFunctionReferenceRatio(0.0005)

    # Plant Loop

    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName(obj_name + ' condenser loop')
    if fluid_type == Constants.FluidWater
      plant_loop.setFluidType('Water')
    else
      plant_loop.setFluidType({ Constants.FluidPropyleneGlycol => 'PropyleneGlycol', Constants.FluidEthyleneGlycol => 'EthyleneGlycol' }[fluid_type])
      plant_loop.setGlycolConcentration((frac_glycol * 100).to_i)
    end
    plant_loop.setMaximumLoopTemperature(48.88889)
    plant_loop.setMinimumLoopTemperature(UnitConversions.convert(hw_design, 'F', 'C'))
    plant_loop.setMinimumLoopFlowRate(0)
    plant_loop.setLoadDistributionScheme('SequentialLoad')
    plant_loop.addSupplyBranchForComponent(ground_heat_exch_vert)
    plant_loop.addDemandBranchForComponent(htg_coil)
    plant_loop.addDemandBranchForComponent(clg_coil)
    hvac_map[heat_pump.id] << plant_loop

    sizing_plant = plant_loop.sizingPlant
    sizing_plant.setLoopType('Condenser')
    sizing_plant.setDesignLoopExitTemperature(UnitConversions.convert(chw_design, 'F', 'C'))
    sizing_plant.setLoopDesignTemperatureDifference(UnitConversions.convert(design_delta_t, 'R', 'K'))

    setpoint_mgr_follow_ground_temp = OpenStudio::Model::SetpointManagerFollowGroundTemperature.new(model)
    setpoint_mgr_follow_ground_temp.setName(obj_name + ' condenser loop temp')
    setpoint_mgr_follow_ground_temp.setControlVariable('Temperature')
    setpoint_mgr_follow_ground_temp.setMaximumSetpointTemperature(48.88889)
    setpoint_mgr_follow_ground_temp.setMinimumSetpointTemperature(UnitConversions.convert(hw_design, 'F', 'C'))
    setpoint_mgr_follow_ground_temp.setReferenceGroundTemperatureObjectType('Site:GroundTemperature:Deep')
    setpoint_mgr_follow_ground_temp.addToNode(plant_loop.supplyOutletNode)

    # Pump

    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setName(obj_name + ' pump')
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
    hvac_map[heat_pump.id] << pump
    hvac_map[heat_pump.id] += disaggregate_fan_or_pump(model, pump, htg_coil, clg_coil, htg_supp_coil)

    # Pipes

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

    # Fan

    fan = create_supply_fan(model, obj_name, 1, fan_power_installed)
    hvac_map[heat_pump.id] += disaggregate_fan_or_pump(model, fan, htg_coil, clg_coil, htg_supp_coil)

    # Unitary System

    air_loop_unitary = create_air_loop_unitary_system(model, obj_name, fan, htg_coil, clg_coil, htg_supp_coil, 40.0)
    hvac_map[heat_pump.id] << air_loop_unitary

    # Air Loop

    air_loop = create_air_loop(model, obj_name, air_loop_unitary, control_zone, sequential_heat_load_frac, sequential_cool_load_frac)
    hvac_map[heat_pump.id] << air_loop

    # Store info for HVAC Sizing measure
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACSHR, heat_pump.cooling_shr.to_s)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPCoil_BF_FT_SPEC, coil_bf_ft_spec.join(','))
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPCoilBF, coil_bf)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, heat_pump.fraction_heat_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACFracCoolLoadServed, heat_pump.fraction_cool_load_served)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPBoreSpacing, bore_spacing)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPBoreHoles, bore_holes.to_s)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPBoreDepth, bore_depth.to_s)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPBoreConfig, bore_config.to_s)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoGSHPUTubeSpacingType, u_tube_spacing_type)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameGroundSourceHeatPump)
    air_loop_unitary.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameGroundSourceHeatPump)
  end

  def self.apply_boiler(model, runner, heating_system,
                        remaining_heat_load_frac, control_zone,
                        hvac_map)

    hvac_map[heating_system.id] = []
    obj_name = Constants.ObjectNameBoiler
    sequential_heat_load_frac = calc_sequential_load_fraction(heating_system.fraction_heat_load_served, remaining_heat_load_frac)
    system_type = Constants.BoilerTypeForcedDraft
    oat_reset_enabled = false
    oat_high = nil
    oat_low = nil
    oat_hwst_high = nil
    oat_hwst_low = nil
    design_temp = 180.0 # deg-F

    if system_type == Constants.BoilerTypeSteam
      fail 'Cannot currently model steam boilers.'
    end

    if oat_reset_enabled
      if oat_high.nil? || oat_low.nil? || oat_hwst_low.nil? || oat_hwst_high.nil?
        runner.registerWarning('Boiler outdoor air temperature (OAT) reset is enabled but no setpoints were specified so OAT reset is being disabled.')
        oat_reset_enabled = false
      end
    end

    # Plant Loop

    plant_loop = OpenStudio::Model::PlantLoop.new(model)
    plant_loop.setName(obj_name + ' hydronic heat loop')
    plant_loop.setFluidType('Water')
    plant_loop.setMaximumLoopTemperature(100)
    plant_loop.setMinimumLoopTemperature(0)
    plant_loop.setMinimumLoopFlowRate(0)
    plant_loop.autocalculatePlantLoopVolume()
    hvac_map[heating_system.id] << plant_loop

    loop_sizing = plant_loop.sizingPlant
    loop_sizing.setLoopType('Heating')
    loop_sizing.setDesignLoopExitTemperature(UnitConversions.convert(design_temp - 32.0, 'R', 'K'))
    loop_sizing.setLoopDesignTemperatureDifference(UnitConversions.convert(20.0, 'R', 'K'))

    # Pump

    pump = OpenStudio::Model::PumpVariableSpeed.new(model)
    pump.setName(obj_name + ' hydronic pump')
    pump.setRatedPumpHead(20000)
    pump.setMotorEfficiency(0.9)
    pump.setFractionofMotorInefficienciestoFluidStream(0)
    pump.setCoefficient1ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient2ofthePartLoadPerformanceCurve(1)
    pump.setCoefficient3ofthePartLoadPerformanceCurve(0)
    pump.setCoefficient4ofthePartLoadPerformanceCurve(0)
    pump.setPumpControlType('Intermittent')
    pump.addToNode(plant_loop.supplyInletNode)
    hvac_map[heating_system.id] << pump

    # Boiler

    boiler = OpenStudio::Model::BoilerHotWater.new(model)
    boiler.setName(obj_name)
    boiler.setFuelType(HelperMethods.eplus_fuel_map(heating_system.heating_system_fuel))
    if not heating_system.heating_capacity.nil?
      boiler.setNominalCapacity(UnitConversions.convert([heating_system.heating_capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
    end
    if system_type == Constants.BoilerTypeCondensing
      # Convert Rated Efficiency at 80F and 1.0PLR where the performance curves are derived from to Design condition as input
      boiler_RatedHWRT = UnitConversions.convert(80.0 - 32.0, 'R', 'K')
      plr_Rated = 1.0
      plr_Design = 1.0
      boiler_DesignHWRT = UnitConversions.convert(design_temp - 20.0 - 32.0, 'R', 'K')
      # Efficiency curves are normalized using 80F return water temperature, at 0.254PLR
      condBlr_TE_Coeff = [1.058343061, 0.052650153, 0.0087272, 0.001742217, 0.00000333715, 0.000513723]
      boilerEff_Norm = heating_system.heating_efficiency_afue / (condBlr_TE_Coeff[0] - condBlr_TE_Coeff[1] * plr_Rated - condBlr_TE_Coeff[2] * plr_Rated**2 - condBlr_TE_Coeff[3] * boiler_RatedHWRT + condBlr_TE_Coeff[4] * boiler_RatedHWRT**2 + condBlr_TE_Coeff[5] * boiler_RatedHWRT * plr_Rated)
      boilerEff_Design = boilerEff_Norm * (condBlr_TE_Coeff[0] - condBlr_TE_Coeff[1] * plr_Design - condBlr_TE_Coeff[2] * plr_Design**2 - condBlr_TE_Coeff[3] * boiler_DesignHWRT + condBlr_TE_Coeff[4] * boiler_DesignHWRT**2 + condBlr_TE_Coeff[5] * boiler_DesignHWRT * plr_Design)
      boiler.setNominalThermalEfficiency(boilerEff_Design)
      boiler.setEfficiencyCurveTemperatureEvaluationVariable('EnteringBoiler')
      boiler_eff_curve = create_curve_biquadratic(model, [1.058343061, -0.052650153, -0.0087272, -0.001742217, 0.00000333715, 0.000513723], 'CondensingBoilerEff', 0.2, 1.0, 30.0, 85.0)
    else
      boiler.setNominalThermalEfficiency(heating_system.heating_efficiency_afue)
      boiler.setEfficiencyCurveTemperatureEvaluationVariable('LeavingBoiler')
      boiler_eff_curve = create_curve_bicubic(model, [1.111720116, 0.078614078, -0.400425756, 0.0, -0.000156783, 0.009384599, 0.234257955, 1.32927e-06, -0.004446701, -1.22498e-05], 'NonCondensingBoilerEff', 0.1, 1.0, 20.0, 80.0)
    end
    boiler.setNormalizedBoilerEfficiencyCurve(boiler_eff_curve)
    boiler.setMinimumPartLoadRatio(0.0)
    boiler.setMaximumPartLoadRatio(1.0)
    boiler.setBoilerFlowMode('LeavingSetpointModulated')
    boiler.setOptimumPartLoadRatio(1.0)
    boiler.setWaterOutletUpperTemperatureLimit(99.9)
    boiler.setParasiticElectricLoad(0)
    plant_loop.addSupplyBranchForComponent(boiler)
    hvac_map[heating_system.id] << boiler

    if (system_type == Constants.BoilerTypeCondensing) && oat_reset_enabled
      setpoint_manager_oar = OpenStudio::Model::SetpointManagerOutdoorAirReset.new(model)
      setpoint_manager_oar.setName(obj_name + ' outdoor reset')
      setpoint_manager_oar.setControlVariable('Temperature')
      setpoint_manager_oar.setSetpointatOutdoorLowTemperature(UnitConversions.convert(oat_hwst_low, 'F', 'C'))
      setpoint_manager_oar.setOutdoorLowTemperature(UnitConversions.convert(oat_low, 'F', 'C'))
      setpoint_manager_oar.setSetpointatOutdoorHighTemperature(UnitConversions.convert(oat_hwst_high, 'F', 'C'))
      setpoint_manager_oar.setOutdoorHighTemperature(UnitConversions.convert(oat_high, 'F', 'C'))
      setpoint_manager_oar.addToNode(plant_loop.supplyOutletNode)
    end

    hydronic_heat_supply_setpoint = OpenStudio::Model::ScheduleConstant.new(model)
    hydronic_heat_supply_setpoint.setName(obj_name + ' hydronic heat supply setpoint')
    hydronic_heat_supply_setpoint.setValue(UnitConversions.convert(design_temp, 'F', 'C'))

    setpoint_manager_scheduled = OpenStudio::Model::SetpointManagerScheduled.new(model, hydronic_heat_supply_setpoint)
    setpoint_manager_scheduled.setName(obj_name + ' hydronic heat loop setpoint manager')
    setpoint_manager_scheduled.setControlVariable('Temperature')
    setpoint_manager_scheduled.addToNode(plant_loop.supplyOutletNode)

    pipe_supply_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    plant_loop.addSupplyBranchForComponent(pipe_supply_bypass)
    pipe_supply_outlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_supply_outlet.addToNode(plant_loop.supplyOutletNode)
    pipe_demand_bypass = OpenStudio::Model::PipeAdiabatic.new(model)
    plant_loop.addDemandBranchForComponent(pipe_demand_bypass)
    pipe_demand_inlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_inlet.addToNode(plant_loop.demandInletNode)
    pipe_demand_outlet = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe_demand_outlet.addToNode(plant_loop.demandOutletNode)

    # Baseboard Coil

    baseboard_coil = OpenStudio::Model::CoilHeatingWaterBaseboard.new(model)
    baseboard_coil.setName(obj_name + ' htg coil')
    if not heating_system.heating_capacity.nil?
      baseboard_coil.setHeatingDesignCapacity(UnitConversions.convert([heating_system.heating_capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
    end
    baseboard_coil.setConvergenceTolerance(0.001)
    plant_loop.addDemandBranchForComponent(baseboard_coil)
    hvac_map[heating_system.id] << baseboard_coil

    # Baseboard

    baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model, model.alwaysOnDiscreteSchedule, baseboard_coil)
    baseboard_heater.setName(obj_name)
    baseboard_heater.addToThermalZone(control_zone)
    hvac_map[heating_system.id] << baseboard_heater
    hvac_map[heating_system.id] += disaggregate_fan_or_pump(model, pump, baseboard_heater, nil, nil)

    control_zone.setSequentialHeatingFractionSchedule(baseboard_heater, get_sequential_load_schedule(model, sequential_heat_load_frac))
    control_zone.setSequentialCoolingFractionSchedule(baseboard_heater, get_sequential_load_schedule(model, 0))

    # Store info for HVAC Sizing measure
    baseboard_heater.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, heating_system.fraction_heat_load_served)
    baseboard_heater.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameBoiler)
  end

  def self.apply_electric_baseboard(model, runner, heating_system,
                                    remaining_heat_load_frac, control_zone,
                                    hvac_map)

    hvac_map[heating_system.id] = []
    obj_name = Constants.ObjectNameElectricBaseboard
    sequential_heat_load_frac = calc_sequential_load_fraction(heating_system.fraction_heat_load_served, remaining_heat_load_frac)

    # Baseboard

    baseboard_heater = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric.new(model)
    baseboard_heater.setName(obj_name)
    if not heating_system.heating_capacity.nil?
      baseboard_heater.setNominalCapacity(UnitConversions.convert([heating_system.heating_capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
    end
    baseboard_heater.setEfficiency(heating_system.heating_efficiency_percent)
    baseboard_heater.addToThermalZone(control_zone)
    hvac_map[heating_system.id] << baseboard_heater

    control_zone.setSequentialHeatingFractionSchedule(baseboard_heater, get_sequential_load_schedule(model, sequential_heat_load_frac))
    control_zone.setSequentialCoolingFractionSchedule(baseboard_heater, get_sequential_load_schedule(model, 0))

    # Store info for HVAC Sizing measure
    baseboard_heater.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, heating_system.fraction_heat_load_served)
    baseboard_heater.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameElectricBaseboard)
  end

  def self.apply_unit_heater(model, runner, heating_system,
                             remaining_heat_load_frac, control_zone,
                             hvac_map)

    hvac_map[heating_system.id] = []
    obj_name = Constants.ObjectNameUnitHeater
    sequential_heat_load_frac = calc_sequential_load_fraction(heating_system.fraction_heat_load_served, remaining_heat_load_frac)
    fan_power_installed = 0.5 # W/cfm # For fuel equipment, will be overridden by EAE later
    airflow_rate = 125.0 # cfm/ton; doesn't affect energy consumption

    if (fan_power_installed > 0) && (airflow_rate == 0)
      fail 'If Fan Power > 0, then Airflow Rate cannot be zero.'
    end

    # Heating Coil

    efficiency = heating_system.heating_efficiency_afue
    efficiency = heating_system.heating_efficiency_percent if efficiency.nil?
    if heating_system.heating_system_fuel == HPXML::FuelTypeElectricity
      htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model)
      htg_coil.setEfficiency(efficiency)
    else
      htg_coil = OpenStudio::Model::CoilHeatingGas.new(model)
      htg_coil.setGasBurnerEfficiency(efficiency)
      htg_coil.setParasiticElectricLoad(0.0)
      htg_coil.setParasiticGasLoad(0)
      htg_coil.setFuelType(HelperMethods.eplus_fuel_map(heating_system.heating_system_fuel))
    end
    htg_coil.setName(obj_name + ' htg coil')
    if not heating_system.heating_capacity.nil?
      htg_coil.setNominalCapacity(UnitConversions.convert([heating_system.heating_capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
    end
    hvac_map[heating_system.id] << htg_coil

    # Fan

    fan = create_supply_fan(model, obj_name, 1, fan_power_installed)
    hvac_map[heating_system.id] += disaggregate_fan_or_pump(model, fan, htg_coil, nil, nil)

    # Unitary System

    unitary_system = create_air_loop_unitary_system(model, obj_name, fan, htg_coil, nil, nil)
    unitary_system.setControllingZoneorThermostatLocation(control_zone)
    unitary_system.addToThermalZone(control_zone)
    hvac_map[heating_system.id] << unitary_system

    control_zone.setSequentialHeatingFractionSchedule(unitary_system, get_sequential_load_schedule(model, sequential_heat_load_frac))
    control_zone.setSequentialCoolingFractionSchedule(unitary_system, get_sequential_load_schedule(model, 0))

    # Store info for HVAC Sizing measure
    unitary_system.additionalProperties.setFeature(Constants.SizingInfoHVACRatedCFMperTonHeating, airflow_rate.to_s)
    unitary_system.additionalProperties.setFeature(Constants.SizingInfoHVACFracHeatLoadServed, heating_system.fraction_heat_load_served)
    unitary_system.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameUnitHeater)
  end

  def self.apply_ideal_air_loads(model, runner, sequential_cool_load_frac,
                                 sequential_heat_load_frac, control_zone)

    obj_name = Constants.ObjectNameIdealAirSystem

    # Ideal Air System

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

    control_zone.setSequentialCoolingFractionSchedule(ideal_air, get_sequential_load_schedule(model, sequential_cool_load_frac))
    control_zone.setSequentialHeatingFractionSchedule(ideal_air, get_sequential_load_schedule(model, sequential_heat_load_frac))

    # Store info for HVAC Sizing measure
    ideal_air.additionalProperties.setFeature(Constants.SizingInfoHVACCoolType, Constants.ObjectNameIdealAirSystem)
    ideal_air.additionalProperties.setFeature(Constants.SizingInfoHVACHeatType, Constants.ObjectNameIdealAirSystem)
  end

  def self.apply_dehumidifier(model, runner, dehumidifier, living_space, hvac_map)
    water_removal_rate = dehumidifier.capacity
    energy_factor = dehumidifier.energy_factor

    control_zone = living_space.thermalZone.get
    obj_name = Constants.ObjectNameDehumidifier

    avg_rh_setpoint = dehumidifier.rh_setpoint * 100.0 # (EnergyPlus uses 60 for 60% RH)
    relative_humidity_setpoint_sch = OpenStudio::Model::ScheduleConstant.new(model)
    relative_humidity_setpoint_sch.setName(Constants.ObjectNameRelativeHumiditySetpoint)
    relative_humidity_setpoint_sch.setValue(avg_rh_setpoint)

    # Dehumidifier coefficients
    # Generic model coefficients from Winkler, Christensen, and Tomerlin (2011)
    w_coeff = [-1.162525707, 0.02271469, -0.000113208, 0.021110538, -0.0000693034, 0.000378843]
    ef_coeff = [-1.902154518, 0.063466565, -0.000622839, 0.039540407, -0.000125637, -0.000176722]
    pl_coeff = [0.90, 0.10, 0.0]
    water_removal_curve = create_curve_biquadratic(model, w_coeff, 'DXDH-WaterRemove-Cap-fT', -100, 100, -100, 100)
    energy_factor_curve = create_curve_biquadratic(model, ef_coeff, 'DXDH-EnergyFactor-fT', -100, 100, -100, 100)
    part_load_frac_curve = create_curve_quadratic(model, pl_coeff, 'DXDH-PLF-fPLR', 0, 1, 0.7, 1)
    if energy_factor.nil?
      # shift inputs tested under IEF test conditions to those under EF test conditions with performance curves
      energy_factor, water_removal_rate = apply_dehumidifier_ief_to_ef_inputs(w_coeff, ef_coeff, dehumidifier.integrated_energy_factor, water_removal_rate)
    end

    # Calculate air flow rate by assuming 2.75 cfm/pint/day (based on experimental test data)
    air_flow_rate = 2.75 * water_removal_rate

    humidistat = OpenStudio::Model::ZoneControlHumidistat.new(model)
    humidistat.setName(obj_name + ' humidistat')
    humidistat.setHumidifyingRelativeHumiditySetpointSchedule(relative_humidity_setpoint_sch)
    humidistat.setDehumidifyingRelativeHumiditySetpointSchedule(relative_humidity_setpoint_sch)
    control_zone.setZoneControlHumidistat(humidistat)

    zone_hvac = OpenStudio::Model::ZoneHVACDehumidifierDX.new(model, water_removal_curve, energy_factor_curve, part_load_frac_curve)
    zone_hvac.setName(obj_name)
    zone_hvac.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    zone_hvac.setRatedWaterRemoval(UnitConversions.convert(water_removal_rate, 'pint', 'L'))
    zone_hvac.setRatedEnergyFactor(energy_factor / dehumidifier.fraction_served)
    zone_hvac.setRatedAirFlowRate(UnitConversions.convert(air_flow_rate, 'cfm', 'm^3/s'))
    zone_hvac.setMinimumDryBulbTemperatureforDehumidifierOperation(10)
    zone_hvac.setMaximumDryBulbTemperatureforDehumidifierOperation(40)

    zone_hvac.addToThermalZone(control_zone)

    hvac_map[dehumidifier.id] << zone_hvac
    if dehumidifier.fraction_served < 1.0
      adjust_dehumidifier_load_EMS(dehumidifier.fraction_served, zone_hvac, model, living_space)
    end
  end

  def self.apply_ceiling_fans(model, runner, annual_kWh, weekday_sch, weekend_sch, monthly_sch,
                              cfa, living_space)
    obj_name = Constants.ObjectNameCeilingFan

    ceiling_fan_sch = MonthWeekdayWeekendSchedule.new(model, obj_name + ' schedule', weekday_sch, weekend_sch, monthly_sch, 1.0, 1.0, true, true, Constants.ScheduleTypeLimitsFraction)

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
  end

  def self.apply_setpoints(model, runner, weather, living_zone,
                           htg_wkdy_monthly, htg_wked_monthly, htg_start_month, htg_end_month,
                           clg_wkdy_monthly, clg_wked_monthly, clg_start_month, clg_end_month)

    # Get heating season
    if htg_start_month <= htg_end_month
      heating_season = Array.new(htg_start_month - 1, 0) + Array.new(htg_end_month - htg_start_month + 1, 1) + Array.new(12 - htg_end_month, 0)
    else
      heating_season = Array.new(htg_end_month, 1) + Array.new(htg_start_month - htg_end_month - 1, 0) + Array.new(12 - htg_start_month + 1, 1)
    end

    # Get cooling season
    if clg_start_month <= clg_end_month
      cooling_season = Array.new(clg_start_month - 1, 0) + Array.new(clg_end_month - clg_start_month + 1, 1) + Array.new(12 - clg_end_month, 0)
    else
      cooling_season = Array.new(clg_end_month, 1) + Array.new(clg_start_month - clg_end_month - 1, 0) + Array.new(12 - clg_start_month + 1, 1)
    end

    heating_season_sch = MonthWeekdayWeekendSchedule.new(model, Constants.ObjectNameHeatingSeason, Array.new(24, 1), Array.new(24, 1), heating_season, 1.0, 1.0, false, true, Constants.ScheduleTypeLimitsOnOff)
    cooling_season_sch = MonthWeekdayWeekendSchedule.new(model, Constants.ObjectNameCoolingSeason, Array.new(24, 1), Array.new(24, 1), cooling_season, 1.0, 1.0, false, true, Constants.ScheduleTypeLimitsOnOff)

    htg_wkdy_monthly = htg_wkdy_monthly.map { |i| i.map { |j| UnitConversions.convert(j, 'F', 'C') } }
    htg_wked_monthly = htg_wked_monthly.map { |i| i.map { |j| UnitConversions.convert(j, 'F', 'C') } }
    clg_wkdy_monthly = clg_wkdy_monthly.map { |i| i.map { |j| UnitConversions.convert(j, 'F', 'C') } }
    clg_wked_monthly = clg_wked_monthly.map { |i| i.map { |j| UnitConversions.convert(j, 'F', 'C') } }

    (0..11).to_a.each do |i|
      if (heating_season[i] == 1) && (cooling_season[i] == 1) # overlap seasons
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
        fail 'Unhandled case.'
      end
      htg_wkdy_monthly[i] = htg_wkdy
      htg_wked_monthly[i] = htg_wked
      clg_wkdy_monthly[i] = clg_wkdy
      clg_wked_monthly[i] = clg_wked
    end

    heating_setpoint = HourlyByMonthSchedule.new(model, Constants.ObjectNameHeatingSetpoint, htg_wkdy_monthly, htg_wked_monthly, normalize_values = false)
    cooling_setpoint = HourlyByMonthSchedule.new(model, Constants.ObjectNameCoolingSetpoint, clg_wkdy_monthly, clg_wked_monthly, normalize_values = false)

    # Set the setpoint schedules
    thermostat_setpoint = living_zone.thermostatSetpointDualSetpoint
    if thermostat_setpoint.is_initialized
      thermostat_setpoint = thermostat_setpoint.get
      thermostat_setpoint.setHeatingSetpointTemperatureSchedule(heating_setpoint.schedule)
      thermostat_setpoint.setCoolingSetpointTemperatureSchedule(cooling_setpoint.schedule)
    else
      thermostat_setpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
      thermostat_setpoint.setName("#{living_zone.name} temperature setpoint")
      thermostat_setpoint.setHeatingSetpointTemperatureSchedule(heating_setpoint.schedule)
      thermostat_setpoint.setCoolingSetpointTemperatureSchedule(cooling_setpoint.schedule)
      living_zone.setThermostatSetpointDualSetpoint(thermostat_setpoint)
    end
  end

  def self.apply_eae_to_heating_fan(runner, eae_hvacs, eae, fuel, load_frac, htg_type)
    # Applies Electric Auxiliary Energy (EAE) for fuel heating equipment to fan power.

    if htg_type == HPXML::HVACTypeBoiler

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
            pump_gpm = UnitConversions.convert(pump.ratedFlowRate.get, 'm^3/s', 'gal/min')
            pump_w_gpm = elec_power / pump_gpm # W/gpm
            pump.setRatedPowerConsumption(elec_power)
            pump.setRatedPumpHead(calc_pump_head(pump_eff, pump_w_gpm))
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
          htg_capacity = UnitConversions.convert(htg_coil.nominalCapacity.get, 'W', 'kBtu/hr')
          eae = get_default_eae(htg_type, fuel, load_frac, htg_capacity)
        end
        elec_power = eae / 2.08 # W

        htg_coil = unitary_system.heatingCoil.get.to_CoilHeatingGas.get
        htg_coil.setParasiticElectricLoad(0.0)

        htg_cfm = UnitConversions.convert(unitary_system.supplyAirFlowRateDuringHeatingOperation.get, 'm^3/s', 'cfm')

        fan = unitary_system.supplyFan.get.to_FanOnOff.get
        if elec_power > 0
          fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
          fan_w_cfm = elec_power / htg_cfm # W/cfm
          fan.setFanEfficiency(fan_eff)
          fan.setPressureRise(calc_fan_pressure_rise(fan_eff, fan_w_cfm))
        else
          fan.setFanEfficiency(1)
          fan.setPressureRise(0)
        end
        fan.setMotorEfficiency(1.0)
        fan.setMotorInAirstreamFraction(1.0)
      end

    end
  end

  def self.get_default_heating_setpoint(control_type)
    # Per ANSI/RESNET/ICC 301
    htg_sp = 68 # F
    htg_setback_sp = nil
    htg_setback_hrs_per_week = nil
    htg_setback_start_hr = nil
    if control_type == HPXML::HVACControlTypeProgrammable
      htg_setback_sp = 66 # F
      htg_setback_hrs_per_week = 7 * 7 # 11 p.m. to 5:59 a.m., 7 days a week
      htg_setback_start_hr = 23 # 11 p.m.
    elsif control_type != HPXML::HVACControlTypeManual
      fail "Unexpected control type #{control_type}."
    end
    return htg_sp, htg_setback_sp, htg_setback_hrs_per_week, htg_setback_start_hr
  end

  def self.get_default_cooling_setpoint(control_type)
    # Per ANSI/RESNET/ICC 301
    clg_sp = 78 # F
    clg_setup_sp = nil
    clg_setup_hrs_per_week = nil
    clg_setup_start_hr = nil
    if control_type == HPXML::HVACControlTypeProgrammable
      clg_setup_sp = 80 # F
      clg_setup_hrs_per_week = 6 * 7 # 9 a.m. to 2:59 p.m., 7 days a week
      clg_setup_start_hr = 9 # 9 a.m.
    elsif control_type != HPXML::HVACControlTypeManual
      fail "Unexpected control type #{control_type}."
    end
    return clg_sp, clg_setup_sp, clg_setup_hrs_per_week, clg_setup_start_hr
  end

  def self.get_default_compressor_type(seer)
    if seer <= 15
      return HPXML::HVACCompressorTypeSingleStage
    elsif seer <= 21
      return HPXML::HVACCompressorTypeTwoStage
    elsif seer > 21
      return HPXML::HVACCompressorTypeVariableSpeed
    end
  end

  def self.get_default_ceiling_fan_power()
    # Per ANSI/RESNET/ICC 301
    return 42.6 # W
  end

  def self.get_default_ceiling_fan_quantity(nbeds)
    # Per ANSI/RESNET/ICC 301
    return nbeds + 1
  end

  def self.get_default_ceiling_fan_months(weather)
    # Per ANSI/RESNET/ICC 301
    months = [0] * 12
    weather.data.MonthlyAvgDrybulbs.each_with_index do |val, m|
      next unless val > 63.0 # deg-F

      months[m] = 1
    end
    return months
  end

  def self.get_default_heating_and_cooling_seasons(weather)
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

      if ((i == 0) || (i == 11)) && (heat_design_db < 59.0)
        heating_season_temp_basis[i] = 1.0
      elsif (i == 6) || (i == 7)
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

      if ((heating_season_temp_basis[i] == 1.0) || ((cooling_season_temp_basis[prevmonth] == 0.0) && (cooling_season_temp_basis[i] == 1.0)))
        heating_season[i] = 1.0
      else
        heating_season[i] = 0.0
      end

      if ((cooling_season_temp_basis[i] == 1.0) || ((heating_season_temp_basis[prevmonth] == 0.0) && (heating_season_temp_basis[i] == 1.0)))
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

  private

  def self.disaggregate_fan_or_pump(model, fan_or_pump, htg_object, clg_object, backup_htg_object)
    # Disaggregate into heating/cooling output energy use.

    hvac_objects = []

    if fan_or_pump.is_a?(OpenStudio::Model::FanOnOff) || fan_or_pump.is_a?(OpenStudio::Model::FanVariableVolume)
      fan_or_pump_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Fan Electric Energy')
    elsif fan_or_pump.is_a? OpenStudio::Model::PumpVariableSpeed
      fan_or_pump_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Pump Electric Energy')
    else
      fail "Unexpected fan/pump object '#{fan_or_pump.name}'."
    end
    fan_or_pump_sensor.setName("#{fan_or_pump.name} s")
    fan_or_pump_sensor.setKeyName(fan_or_pump.name.to_s)
    hvac_objects << fan_or_pump_sensor

    if clg_object.nil?
      clg_object_sensor = nil
    else
      if clg_object.is_a? OpenStudio::Model::EvaporativeCoolerDirectResearchSpecial
        var = 'Evaporative Cooler Water Volume'
      else
        var = 'Cooling Coil Electric Energy'
      end
      clg_object_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
      clg_object_sensor.setName("#{clg_object.name} s")
      clg_object_sensor.setKeyName(clg_object.name.to_s)
      hvac_objects << clg_object_sensor
    end

    var_map = { 'NaturalGas' => 'Heating Coil Gas Energy',
                'Propane' => 'Heating Coil Propane Energy',
                'FuelOilNo1' => 'Heating Coil FuelOil#1 Energy',
                'OtherFuel1' => 'Heating Coil OtherFuel1 Energy',
                'OtherFuel2' => 'Heating Coil OtherFuel2 Energy' }

    if htg_object.nil?
      htg_object_sensor = nil
    else
      var = 'Heating Coil Electric Energy'
      if htg_object.is_a? OpenStudio::Model::CoilHeatingGas
        var = var_map[htg_object.fuelType]
        fail "Unexpected heating coil '#{htg_object.name}'." if var.nil?
      elsif htg_object.is_a? OpenStudio::Model::ZoneHVACBaseboardConvectiveWater
        var = 'Baseboard Total Heating Energy'
      end

      htg_object_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
      htg_object_sensor.setName("#{htg_object.name} s")
      htg_object_sensor.setKeyName(htg_object.name.to_s)
      hvac_objects << htg_object_sensor
    end

    if backup_htg_object.nil?
      backup_htg_object_sensor = nil
    else
      var = 'Heating Coil Electric Energy'
      if backup_htg_object.is_a? OpenStudio::Model::CoilHeatingGas
        var = var_map[backup_htg_object.fuelType]
        fail "Unexpected heating coil '#{backup_htg_object.name}'." if var.nil?
      end

      backup_htg_object_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var)
      backup_htg_object_sensor.setName("#{backup_htg_object.name} s")
      backup_htg_object_sensor.setKeyName(backup_htg_object.name.to_s)
      hvac_objects << backup_htg_object_sensor
    end

    sensors = { 'clg' => clg_object_sensor,
                'primary_htg' => htg_object_sensor,
                'backup_htg' => backup_htg_object_sensor }

    fan_or_pump_var = fan_or_pump.name.to_s.gsub(' ', '_')

    # Disaggregate electric fan/pump energy
    fan_or_pump_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    fan_or_pump_program.setName("#{fan_or_pump_var} disaggregate program")
    sensors.each do |mode, sensor|
      next if sensor.nil?

      fan_or_pump_program.addLine("Set #{fan_or_pump_var}_#{mode} = 0")
    end
    i = 0
    sensors.each do |mode, sensor|
      next if sensor.nil?

      if i == 0
        fan_or_pump_program.addLine("If #{sensor.name} > 0")
      elsif i == 2
        fan_or_pump_program.addLine('Else')
      else
        fan_or_pump_program.addLine("ElseIf #{sensor.name} > 0")
      end
      fan_or_pump_program.addLine("  Set #{fan_or_pump_var}_#{mode} = #{fan_or_pump_sensor.name}")
      i += 1
    end
    fan_or_pump_program.addLine('EndIf')
    hvac_objects << fan_or_pump_program

    fan_or_pump_program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    fan_or_pump_program_calling_manager.setName("#{fan_or_pump.name} disaggregate program calling manager")
    fan_or_pump_program_calling_manager.setCallingPoint('EndOfSystemTimestepBeforeHVACReporting')
    fan_or_pump_program_calling_manager.addProgram(fan_or_pump_program)
    hvac_objects << fan_or_pump_program_calling_manager

    sensors.each do |mode, sensor|
      next if sensor.nil?

      fan_or_pump_ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "#{fan_or_pump_var}_#{mode}")
      name = { 'clg' => Constants.ObjectNameFanPumpDisaggregateCool(fan_or_pump.name.to_s),
               'primary_htg' => Constants.ObjectNameFanPumpDisaggregatePrimaryHeat(fan_or_pump.name.to_s),
               'backup_htg' => Constants.ObjectNameFanPumpDisaggregateBackupHeat(fan_or_pump.name.to_s) }[mode]
      fan_or_pump_ems_output_var.setName(name)
      fan_or_pump_ems_output_var.setTypeOfDataInVariable('Summed')
      fan_or_pump_ems_output_var.setUpdateFrequency('SystemTimestep')
      fan_or_pump_ems_output_var.setEMSProgramOrSubroutineName(fan_or_pump_program)
      fan_or_pump_ems_output_var.setUnits('J')
      hvac_objects << fan_or_pump_ems_output_var

      # Used by HEScore
      # TODO: Move to HEScore project or reporting measure
      outputVariable = OpenStudio::Model::OutputVariable.new(fan_or_pump_ems_output_var.name.to_s, model)
      outputVariable.setReportingFrequency('monthly')
      outputVariable.setKeyValue('*')
    end

    return hvac_objects
  end

  def self.adjust_dehumidifier_load_EMS(fraction_served, zone_hvac, model, living_space)
    # adjust hvac load to space when dehumidifier serves less than 100% dehumidification load. (With E+ dehumidifier object, it can only model 100%)

    # sensor
    dehumidifier_sens_htg = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Dehumidifier Sensible Heating Rate')
    dehumidifier_sens_htg.setName("#{zone_hvac.name} sens htg")
    dehumidifier_sens_htg.setKeyName(zone_hvac.name.to_s)
    dehumidifier_power = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Dehumidifier Electric Power')
    dehumidifier_power.setName("#{zone_hvac.name} power htg")
    dehumidifier_power.setKeyName(zone_hvac.name.to_s)

    # actuator
    dehumidifier_load_adj_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
    dehumidifier_load_adj_def.setName("#{zone_hvac.name} sens htg adj def")
    dehumidifier_load_adj_def.setDesignLevel(0)
    dehumidifier_load_adj_def.setFractionRadiant(0)
    dehumidifier_load_adj_def.setFractionLatent(0)
    dehumidifier_load_adj_def.setFractionLost(0)
    dehumidifier_load_adj = OpenStudio::Model::OtherEquipment.new(dehumidifier_load_adj_def)
    dehumidifier_load_adj.setName("#{zone_hvac.name} sens htg adj")
    dehumidifier_load_adj.setSpace(living_space)
    dehumidifier_load_adj.setSchedule(model.alwaysOnDiscreteSchedule)

    dehumidifier_load_adj_act = OpenStudio::Model::EnergyManagementSystemActuator.new(dehumidifier_load_adj, 'OtherEquipment', 'Power Level')
    dehumidifier_load_adj_act.setName("#{zone_hvac.name} sens htg adj act")

    # EMS program
    program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    program.setName("#{zone_hvac.name} load adj program")
    program.addLine("If #{dehumidifier_sens_htg.name} > 0")
    program.addLine("  Set #{dehumidifier_load_adj_act.name} = - (#{dehumidifier_sens_htg.name} - #{dehumidifier_power.name}) * (1 - #{fraction_served})")
    program.addLine('Else')
    program.addLine("  Set #{dehumidifier_load_adj_act.name} = 0")
    program.addLine('EndIf')

    program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    program_calling_manager.setName(program.name.to_s + 'calling manager')
    program_calling_manager.setCallingPoint('BeginTimestepBeforePredictor')
    program_calling_manager.addProgram(program)
  end

  def self.create_supp_heating_coil(model, obj_name, heat_pump)
    fuel = heat_pump.backup_heating_fuel
    capacity = heat_pump.backup_heating_capacity
    efficiency = heat_pump.backup_heating_efficiency_percent
    efficiency = heat_pump.backup_heating_efficiency_afue if efficiency.nil?

    if fuel.nil?
      fuel = HPXML::FuelTypeElectricity
      capacity = 0.0
      efficiency = 1.0
    end

    if fuel == HPXML::FuelTypeElectricity
      htg_supp_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOnDiscreteSchedule)
      htg_supp_coil.setEfficiency(efficiency)
    else
      htg_supp_coil = OpenStudio::Model::CoilHeatingGas.new(model)
      htg_supp_coil.setGasBurnerEfficiency(efficiency)
      htg_supp_coil.setParasiticElectricLoad(0)
      htg_supp_coil.setParasiticGasLoad(0)
      htg_supp_coil.setFuelType(HelperMethods.eplus_fuel_map(fuel))
    end
    htg_supp_coil.setName(obj_name + ' ' + Constants.ObjectNameBackupHeatingCoil)
    if not capacity.nil?
      htg_supp_coil.setNominalCapacity(UnitConversions.convert([capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
    end
    return htg_supp_coil
  end

  def self.create_supply_fan(model, obj_name, num_speeds, fan_power_installed)
    if num_speeds == 1
      fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
    else
      fan_power_curve = create_curve_exponent(model, [0, 1, 3], obj_name + ' fan power curve', -100, 100)
      fan_eff_curve = create_curve_cubic(model, [0, 1, 0, 0], obj_name + ' fan eff curve', 0, 1, 0.01, 1)
      fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule, fan_power_curve, fan_eff_curve)
    end
    if fan_power_installed > 0
      fan_eff = 0.75 # Overall Efficiency of the Fan, Motor and Drive
      fan.setFanEfficiency(fan_eff)
      fan.setPressureRise(calc_fan_pressure_rise(fan_eff, fan_power_installed))
    else
      fan.setFanEfficiency(1)
      fan.setPressureRise(0)
    end
    fan.setName(obj_name + ' supply fan')
    fan.setEndUseSubcategory('supply fan')
    fan.setMotorEfficiency(1.0)
    fan.setMotorInAirstreamFraction(1.0)
    return fan
  end

  def self.create_air_loop_unitary_system(model, obj_name, fan, htg_coil, clg_coil, htg_supp_coil, supp_max_temp = nil, htg_cfm: nil, clg_cfm: nil)
    air_loop_unitary = OpenStudio::Model::AirLoopHVACUnitarySystem.new(model)
    air_loop_unitary.setName(obj_name + ' unitary system')
    air_loop_unitary.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop_unitary.setSupplyFan(fan)
    air_loop_unitary.setFanPlacement('BlowThrough')
    air_loop_unitary.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
    if htg_coil.nil?
      air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(0.0)
    else
      air_loop_unitary.setHeatingCoil(htg_coil)
    end
    if clg_coil.nil?
      air_loop_unitary.setSupplyAirFlowRateDuringCoolingOperation(0.0)
    else
      air_loop_unitary.setCoolingCoil(clg_coil)
    end
    if htg_supp_coil.nil?
      air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(120.0, 'F', 'C'))
    else
      air_loop_unitary.setSupplementalHeatingCoil(htg_supp_coil)
      air_loop_unitary.setMaximumSupplyAirTemperature(UnitConversions.convert(200.0, 'F', 'C')) # higher temp for supplemental heat as to not severely limit its use, resulting in unmet hours.
      air_loop_unitary.setMaximumOutdoorDryBulbTemperatureforSupplementalHeaterOperation(UnitConversions.convert(supp_max_temp, 'F', 'C'))
    end
    air_loop_unitary.setSupplyAirFlowRateWhenNoCoolingorHeatingisRequired(0)
    if not clg_cfm.nil? # Hidden feature; used only for HERS DSE test
      air_loop_unitary.setSupplyAirFlowRateMethodDuringCoolingOperation('SupplyAirFlowRate')
      air_loop_unitary.setSupplyAirFlowRateDuringCoolingOperation(UnitConversions.convert(clg_cfm, 'cfm', 'm^3/s'))
    end
    if not htg_cfm.nil? # Hidden feature; used only for HERS DSE test
      air_loop_unitary.setSupplyAirFlowRateMethodDuringHeatingOperation('SupplyAirFlowRate')
      air_loop_unitary.setSupplyAirFlowRateDuringHeatingOperation(UnitConversions.convert(htg_cfm, 'cfm', 'm^3/s'))
    end
    return air_loop_unitary
  end

  def self.create_air_loop(model, obj_name, system, control_zone, sequential_heat_load_frac, sequential_cool_load_frac)
    air_loop = OpenStudio::Model::AirLoopHVAC.new(model)
    air_loop.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
    air_loop.setName(obj_name + ' airloop')
    air_loop.zoneSplitter.setName(obj_name + ' zone splitter')
    air_loop.zoneMixer.setName(obj_name + ' zone mixer')
    system.addToNode(air_loop.supplyInletNode)

    if system.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
      air_terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
      system.setControllingZoneorThermostatLocation(control_zone)
    else
      air_terminal = OpenStudio::Model::AirTerminalSingleDuctVAVNoReheat.new(model, model.alwaysOnDiscreteSchedule)
      air_terminal.setConstantMinimumAirFlowFraction(0)
    end
    air_terminal.setName(obj_name + ' terminal')
    air_loop.multiAddBranchForZone(control_zone, air_terminal)

    control_zone.setSequentialHeatingFractionSchedule(air_terminal, get_sequential_load_schedule(model, sequential_heat_load_frac))
    control_zone.setSequentialCoolingFractionSchedule(air_terminal, get_sequential_load_schedule(model, sequential_cool_load_frac))

    return air_loop
  end

  def self.apply_dehumidifier_ief_to_ef_inputs(w_coeff, ef_coeff, ief, water_removal_rate)
    # Shift inputs under IEF test conditions to E+ supported EF test conditions
    # test conditions
    ief_db = UnitConversions.convert(65.0, 'F', 'C') # degree C
    rh = 60.0 # for both EF and IEF test conditions, %

    # Independent ariables applied to curve equations
    var_array_ief = [1, ief_db, ief_db * ief_db, rh, rh * rh, ief_db * rh]

    # Curved values under EF test conditions
    curve_value_ef = 1 # Curves are nomalized to 1.0 under EF test conditions, 80F, 60%
    # Curve values under IEF test conditions
    ef_curve_value_ief = var_array_ief.zip(ef_coeff).map { |var, coeff| var * coeff }.inject(0, :+)
    water_removal_curve_value_ief = var_array_ief.zip(w_coeff).map { |var, coeff| var * coeff }.inject(0, :+)

    # E+ inputs under EF test conditions
    ef_input = ief / ef_curve_value_ief * curve_value_ef
    water_removal_rate_input = water_removal_rate / water_removal_curve_value_ief * curve_value_ef

    return ef_input, water_removal_rate_input
  end

  def self.get_default_eae(htg_type, fuel, load_frac, furnace_capacity_kbtuh)
    # From ANSI/RESNET/ICC 301 Standard
    if htg_type == HPXML::HVACTypeBoiler
      if (fuel == HPXML::FuelTypeNaturalGas) || (fuel == HPXML::FuelTypePropane)
        return 170.0 * load_frac # kWh/yr
      elsif fuel == HPXML::FuelTypeOil
        return 330.0 * load_frac # kWh/yr
      end
    elsif htg_type == HPXML::HVACTypeFurnace
      if (fuel == HPXML::FuelTypeNaturalGas) || (fuel == HPXML::FuelTypePropane)
        return (149.0 + 10.3 * furnace_capacity_kbtuh) * load_frac # kWh/yr
      elsif fuel == HPXML::FuelTypeOil
        return (439.0 + 5.5 * furnace_capacity_kbtuh) * load_frac # kWh/yr
      end
    end
    return 0.0
  end

  def self.calc_heat_cap_ft_spec_using_capacity_17F(num_speeds, heat_pump)
    # Indoor temperature slope and intercept used if Q_17 is specified (derived using heat_cap_ft_spec)
    # NOTE: Using Q_17 assumes the same curve for all speeds
    if num_speeds == 1
      iat_slope = -0.002303414
      iat_intercept = 0.18417308
    elsif num_speeds == 2
      iat_slope = -0.002947013
      iat_intercept = 0.23168251
    elsif num_speeds == 4
      iat_slope = -0.002897048
      iat_intercept = 0.209319129
    end

    # Derive coefficients from user input for heating capacity at 47F and 17F
    # Biquadratic: capacity multiplier = a + b*IAT + c*IAT^2 + d*OAT + e*OAT^2 + f*IAT*OAT
    x_A = 17.0
    y_A = heat_pump.heating_capacity_17F / heat_pump.heating_capacity
    x_B = 47.0 # 47F is the rating point
    y_B = 1.0

    oat_slope = (y_B - y_A) / (x_B - x_A)
    oat_intercept = y_A - (x_A * oat_slope)

    heat_cap_ft_spec = []
    (1..num_speeds).to_a.each do |speed, i|
      heat_cap_ft_spec << [oat_intercept + iat_intercept, iat_slope, 0, oat_slope, 0, 0]
    end

    return heat_cap_ft_spec
  end

  def self.calc_eir_from_cop(cop, fan_power_rated)
    return UnitConversions.convert((UnitConversions.convert(1.0, 'Btu', 'Wh') + fan_power_rated * 0.03333) / cop - fan_power_rated * 0.03333, 'Wh', 'Btu')
  end

  def self.calc_eir_from_eer(eer, fan_power_rated)
    return UnitConversions.convert((1.0 - UnitConversions.convert(fan_power_rated * 0.03333, 'Wh', 'Btu')) / eer - fan_power_rated * 0.03333, 'Wh', 'Btu')
  end

  def self.calc_eer_from_eir(eir, fan_power_rated)
    cfm_per_ton = 400.0
    cfm_per_btuh = cfm_per_ton / 12000.0
    return ((1.0 - 3.412 * (fan_power_rated * cfm_per_btuh)) / (eir / 3.412 + (fan_power_rated * cfm_per_btuh)))
  end

  def self.calc_eers_from_eir_2speed(eer_2, fan_power_rated, is_heat_pump)
    # Returns low and high stage eer A given high stage eer A

    eir_2_a = calc_eir_from_eer(eer_2, fan_power_rated)

    if not is_heat_pump
      eir_1_a = 0.8691 * eir_2_a + 0.0127 # Relationship derived using Dylan's data for two stage air conditioners
    else
      eir_1_a = 0.8887 * eir_2_a + 0.0083 # Relationship derived using Dylan's data for two stage heat pumps
    end

    return [calc_eer_from_eir(eir_1_a, fan_power_rated), eer_2]
  end

  def self.calc_eers_from_eir_4speed(eer_nom, fan_power_rated, calc_type = 'seer')
    # Returns eer A at minimum, intermediate, and nominal speed given eer A (and a fourth speed if calc_type != 'seer')

    eir_nom = calc_eir_from_eer(eer_nom, fan_power_rated)

    if calc_type.include? 'seer'
      indices = [0, 1, 4]
    else
      indices = [0, 1, 2, 4]
    end

    cop_ratios = [1.07, 1.11, 1.08, 1.05, 1.0] # Gross cop

    # Seer calculation is based on performance at three speeds
    cops = [cop_ratios[indices[0]], cop_ratios[indices[1]], cop_ratios[indices[2]]]

    unless calc_type.include? 'seer'
      cops << cop_ratios[indices[3]]
    end

    eers = []
    cops.each do |mult|
      eir = eir_nom / mult
      eers << calc_eer_from_eir(eir, fan_power_rated)
    end

    return eers
  end

  def self.calc_cop_from_eir(eir, fan_power_rated)
    cfm_per_ton = 400.0
    cfm_per_btuh = cfm_per_ton / 12000.0
    return (1.0 / 3.412 + fan_power_rated * cfm_per_btuh) / (eir / 3.412 + fan_power_rated * cfm_per_btuh)
  end

  def self.calc_cops_from_eir_2speed(cop_2, fan_power_rated)
    # Returns low and high stage rated cop given high stage cop

    eir_2 = calc_eir_from_cop(cop_2, fan_power_rated)

    eir_1 = 0.6241 * eir_2 + 0.0681 # Relationship derived using Dylan's data for Carrier two stage heat pumps

    return [calc_cop_from_eir(eir_1, fan_power_rated), cop_2]
  end

  def self.calc_cops_from_eir_4speed(cop_nom, fan_power_rated, calc_type = 'hspf')
    # Returns rated cop at minimum, intermediate, and nominal speed given rated cop

    eir_nom = calc_eir_from_cop(cop_nom, fan_power_rated)

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
      cops_net << calc_cop_from_eir(eir, fan_power_rated)
    end

    return cops_net
  end

  def self.calc_biquad(coeff, in_1, in_2)
    result = coeff[0] + coeff[1] * in_1 + coeff[2] * in_1 * in_1 + coeff[3] * in_2 + coeff[4] * in_2 * in_2 + coeff[5] * in_1 * in_2
    return result
  end

  def self.calc_eer_cooling_1speed(seer, fan_power_rated, coeff_eir)
    # Directly calculate cooling coil net eer at condition A (95/80/67) using Seer

    c_d = get_cool_c_d(1, seer)

    # 1. Calculate eer_b using Seer and c_d
    eer_b = seer / (1.0 - 0.5 * c_d)

    # 2. Calculate eir_b
    eir_b = calc_eir_from_eer(eer_b, fan_power_rated)

    # 3. Calculate eir_a using performance curves
    eir_a = eir_b / calc_biquad(coeff_eir[0], 67.0, 82.0)
    eer_a = calc_eer_from_eir(eir_a, fan_power_rated)

    return eer_a
  end

  def self.calc_eers_cooling_2speed(runner, seer, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q, is_heat_pump = false)
    # Iterate to find rated net eers given Seer using simple bisection method for two stage air conditioners

    # Initial large bracket of eer (A condition) to span possible seer range
    eer_a = 5.0
    eer_b = 20.0

    # Iterate
    iter_max = 100
    tol = 0.0001

    err = 1
    eer_c = (eer_a + eer_b) / 2.0
    (1..iter_max).each do |n|
      eers = calc_eers_from_eir_2speed(eer_a, fan_power_rated, is_heat_pump)
      f_a = calc_seer_2speed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - seer

      eers = calc_eers_from_eir_2speed(eer_c, fan_power_rated, is_heat_pump)
      f_c = calc_seer_2speed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - seer

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
      fail 'Two-speed cooling eers iteration failed to converge.'
    end

    return calc_eers_from_eir_2speed(eer_c, fan_power_rated, is_heat_pump)
  end

  def self.calc_eers_cooling_4speed(runner, seer, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    # Iterate to find rated net eers given Seer using simple bisection method for two stage and variable speed air conditioners

    # Initial large bracket of eer (A condition) to span possible seer range
    eer_a = 5.0
    eer_b = 30.0

    # Iterate
    iter_max = 100
    tol = 0.0001

    err = 1
    eer_c = (eer_a + eer_b) / 2.0
    (1..iter_max).each do |n|
      eers = calc_eers_from_eir_4speed(eer_a, fan_power_rated, calc_type = 'seer')
      f_a = calc_seer_4speed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - seer

      eers = calc_eers_from_eir_4speed(eer_c, fan_power_rated, calc_type = 'seer')
      f_c = calc_seer_4speed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - seer

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
      fail 'Variable-speed cooling eers iteration failed to converge.'
    end

    return calc_eers_from_eir_4speed(eer_c, fan_power_rated, calc_type = 'model')
  end

  def self.calc_seer_2speed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    eir_A2 = calc_eir_from_eer(eers[1], fan_power_rated)
    eir_B2 = eir_A2 * calc_biquad(coeff_eir[1], 67.0, 82.0)

    eir_A1 = calc_eir_from_eer(eers[0], fan_power_rated)
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
      elsif (q_low_i < bL_i) && (bL_i < q_high_i)
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

  def self.calc_seer_4speed(eers, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    n_max = 2
    n_int = 1
    n_min = 0

    wBin = 67.0
    tout_B = 82.0
    tout_E = 87.0
    tout_F = 67.0

    eir_A2 = calc_eir_from_eer(eers[n_max], fan_power_rated)
    eir_B2 = eir_A2 * calc_biquad(coeff_eir[n_max], wBin, tout_B)

    eir_Av = calc_eir_from_eer(eers[n_int], fan_power_rated)
    eir_Ev = eir_Av * calc_biquad(coeff_eir[n_int], wBin, tout_E)

    eir_A1 = calc_eir_from_eer(eers[n_min], fan_power_rated)
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
      elsif (q_k1 < bL) && (bL <= q_k2)
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

  def self.calc_cop_heating_1speed(hspf, c_d, fan_power_rated, coeff_eir, coeff_q)
    # Iterate to find rated net cop given HSPF using simple bisection method

    # Initial large bracket to span possible hspf range
    cop_a = 0.1
    cop_b = 10.0

    # Iterate
    iter_max = 100
    tol = 0.0001

    err = 1
    cop_c = (cop_a + cop_b) / 2.0
    (1..iter_max).each do |n|
      f_a = calc_hspf_1speed(cop_a, c_d, fan_power_rated, coeff_eir, coeff_q) - hspf
      f_c = calc_hspf_1speed(cop_c, c_d, fan_power_rated, coeff_eir, coeff_q) - hspf

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
      fail 'Single-speed heating cop iteration failed to converge.'
    end

    return cop_c
  end

  def self.calc_cops_heating_2speed(hspf, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    # Iterate to find rated net eers given Seer using simple bisection method for two stage air conditioners

    # Initial large bracket of cop to span possible hspf range
    cop_a = 1.0
    cop_b = 10.0

    # Iterate
    iter_max = 100
    tol = 0.0001

    err = 1
    cop_c = (cop_a + cop_b) / 2.0
    (1..iter_max).each do |n|
      cops = calc_cops_from_eir_2speed(cop_a, fan_power_rated)
      f_a = calc_hspf_2speed(cops, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - hspf

      cops = calc_cops_from_eir_2speed(cop_c, fan_power_rated)
      f_c = calc_hspf_2speed(cops, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - hspf

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
      fail 'Two-speed heating cop iteration failed to converge.'
    end

    return calc_cops_from_eir_2speed(cop_c, fan_power_rated)
  end

  def self.calc_cops_heating_4speed(runner, hspf, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    # Iterate to find rated net cops given HSPF using simple bisection method for variable speed heat pumps

    # Initial large bracket of cop to span possible hspf range
    cop_a = 1.0
    cop_b = 15.0

    # Iterate
    iter_max = 100
    tol = 0.0001

    err = 1
    cop_c = (cop_a + cop_b) / 2.0
    (1..iter_max).each do |n|
      cops = calc_cops_from_eir_4speed(cop_a, fan_power_rated, calc_type = 'hspf')
      f_a = calc_hspf_4speed(cops, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - hspf

      cops = calc_cops_from_eir_4speed(cop_c, fan_power_rated, calc_type = 'hspf')
      f_c = calc_hspf_4speed(cops, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q) - hspf

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
      fail 'Variable-speed heating cops iteration failed to converge.'
    end

    return calc_cops_from_eir_4speed(cop_c, fan_power_rated, calc_type = 'model')
  end

  def self.calc_hspf_1speed(cop_47, c_d, fan_power_rated, coeff_eir, coeff_q)
    eir_47 = calc_eir_from_cop(cop_47, fan_power_rated)
    eir_35 = eir_47 * calc_biquad(coeff_eir[0], 70.0, 35.0)
    eir_17 = eir_47 * calc_biquad(coeff_eir[0], 70.0, 17.0)

    q_47 = 1.0
    q_35 = 0.7519
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

      if (t_bins[i] > 17.0) && (t_bins[i] < 45.0)
        q_h = q_17_net + (((q_35_net - q_17_net) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
        p_h = p_17 + (((p_35 - p_17) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
      else
        q_h = q_17_net + (((q_47_net - q_17_net) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
        p_h = p_17 + (((p_47 - p_17) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
      end

      x_t = [bL / q_h, 1.0].min

      pLF = 1.0 - (c_d * (1.0 - x_t))
      if (t_bins[i] <= t_off) || (q_h / (3.412 * p_h) < 1.0)
        sigma_t = 0.0
      elsif (t_off < t_bins[i]) && (t_bins[i] <= t_on) && (q_h / (p_h * 3.412) >= 1.0)
        sigma_t = 0.5
      elsif (t_bins[i] > t_on) && (q_h / (3.412 * p_h) >= 1.0)
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

  def self.calc_hspf_2speed(cops, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    eir_47_H = calc_eir_from_cop(cops[1], fan_power_rated)
    eir_35_H = eir_47_H * calc_biquad(coeff_eir[1], 70.0, 35.0)
    eir_17_H = eir_47_H * calc_biquad(coeff_eir[1], 70.0, 17.0)

    eir_47_L = calc_eir_from_cop(cops[0], fan_power_rated)
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

      if (17.0 < t_bins[i]) && (t_bins[i] < 45.0)
        q_h = q_H17_net + (((q_H35_net - q_H17_net) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
        p_h = p_H17 + (((p_H35 - p_H17) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
      else
        q_h = q_H17_net + (((q_H47_net - q_H17_net) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
        p_h = p_H17 + (((p_H47 - p_H17) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
      end

      if t_bins[i] >= 40.0
        q_l = q_L47_net + (((q_L62_net - q_L47_net) * (t_bins[i] - 47.0)) / (62.0 - 47.0))
        p_l = p_L47 + (((p_L62 - p_L47) * (t_bins[i] - 47.0)) / (62.0 - 47.0))
      elsif (17.0 <= t_bins[i]) && (t_bins[i] < 40.0)
        q_l = q_L17_net + (((q_L35_net - q_L17_net) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
        p_l = p_L17 + (((p_L35 - p_L17) * (t_bins[i] - 17.0)) / (35.0 - 17.0))
      else
        q_l = q_L17_net + (((q_L47_net - q_L17_net) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
        p_l = p_L17 + (((p_L47 - p_L17) * (t_bins[i] - 17.0)) / (47.0 - 17.0))
      end

      x_t_h = [bL / q_h, 1.0].min
      x_t_l = [bL / q_l, 1.0].min
      pLF = 1.0 - (c_d * (1.0 - x_t_l))
      if (t_bins[i] <= t_off) || (q_h / (p_h * 3.412) < 1.0)
        sigma_t_h = 0.0
      elsif (t_off < t_bins[i]) && (t_bins[i] <= t_on) && (q_h / (p_h * 3.412) >= 1.0)
        sigma_t_h = 0.5
      elsif (t_bins[i] > t_on) && (q_h / (p_h * 3.412) >= 1.0)
        sigma_t_h = 1.0
      end

      if t_bins[i] <= t_off
        sigma_t_l = 0.0
      elsif (t_off < t_bins[i]) && (t_bins[i] <= t_on)
        sigma_t_l = 0.5
      elsif t_bins[i] > t_on
        sigma_t_l = 1.0
      end

      if q_l > bL
        p_h_i = (x_t_l * p_l * sigma_t_l / pLF) * frac_hours[i]
        rH_i = (bL * (1.0 - sigma_t_l)) / 3.412 * frac_hours[i]
      elsif (q_l < bL) && (q_h > bL)
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

  def self.calc_hspf_4speed(cop_47, c_d, capacity_ratios, fanspeed_ratios, fan_power_rated, coeff_eir, coeff_q)
    n_max = 2
    n_int = 1
    n_min = 0

    tin = 70.0
    tout_3 = 17.0
    tout_2 = 35.0
    tout_0 = 62.0

    eir_H1_2 = calc_eir_from_cop(cop_47[n_max], fan_power_rated)
    eir_H3_2 = eir_H1_2 * calc_biquad(coeff_eir[n_max], tin, tout_3)

    eir_adjv = calc_eir_from_cop(cop_47[n_int], fan_power_rated)
    eir_H2_v = eir_adjv * calc_biquad(coeff_eir[n_int], tin, tout_2)

    eir_H1_1 = calc_eir_from_cop(cop_47[n_min], fan_power_rated)
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
    m_Q = (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (1.0 - n_Q) + n_Q * (q_H35_2 - q_H3_2_net) / (35.0 - 17.0)
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

      if (t_bins[i] <= 17.0) || (t_bins[i] >= 45.0)
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
      elsif (q_1 < bL) && (bL <= q_2)
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
    const_biquadratic.setName('ConstantBiquadratic')
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
    constant_cubic = OpenStudio::Model::CurveCubic.new('ConstantCubic')
    constant_cubic.setName(name)
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

  def self.create_curve_biquadratic(model, coeff, name, min_x, max_x, min_y, max_y)
    curve = OpenStudio::Model::CurveBiquadratic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setCoefficient4y(coeff[3])
    curve.setCoefficient5yPOW2(coeff[4])
    curve.setCoefficient6xTIMESY(coeff[5])
    curve.setMinimumValueofx(min_x)
    curve.setMaximumValueofx(max_x)
    curve.setMinimumValueofy(min_y)
    curve.setMaximumValueofy(max_y)
    return curve
  end

  def self.create_curve_bicubic(model, coeff, name, min_x, max_x, min_y, max_y)
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
    curve.setMinimumValueofx(min_x)
    curve.setMaximumValueofx(max_x)
    curve.setMinimumValueofy(min_y)
    curve.setMaximumValueofy(max_y)
    return curve
  end

  def self.create_curve_quadratic(model, coeff, name, min_x, max_x, min_y, max_y, is_dimensionless = false)
    curve = OpenStudio::Model::CurveQuadratic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setMinimumValueofx(min_x)
    curve.setMaximumValueofx(max_x)
    if not min_y.nil?
      curve.setMinimumCurveOutput(min_y)
    end
    if not max_y.nil?
      curve.setMaximumCurveOutput(max_y)
    end
    if is_dimensionless
      curve.setInputUnitTypeforX('Dimensionless')
      curve.setOutputUnitType('Dimensionless')
    end
    return curve
  end

  def self.create_curve_cubic(model, coeff, name, min_x, max_x, min_y, max_y)
    curve = OpenStudio::Model::CurveCubic.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2x(coeff[1])
    curve.setCoefficient3xPOW2(coeff[2])
    curve.setCoefficient4xPOW3(coeff[3])
    curve.setMinimumValueofx(min_x)
    curve.setMaximumValueofx(max_x)
    curve.setMinimumCurveOutput(min_y)
    curve.setMaximumCurveOutput(max_y)
    return curve
  end

  def self.create_curve_exponent(model, coeff, name, min_x, max_x)
    curve = OpenStudio::Model::CurveExponent.new(model)
    curve.setName(name)
    curve.setCoefficient1Constant(coeff[0])
    curve.setCoefficient2Constant(coeff[1])
    curve.setCoefficient3Constant(coeff[2])
    curve.setMinimumValueofx(min_x)
    curve.setMaximumValueofx(max_x)
    return curve
  end

  def self.create_dx_cooling_coil(model, obj_name, speed_indices, eirs, cap_ft_spec, eir_ft_spec, closs_fplr_spec, cap_fflow_spec, eir_fflow_spec, shrs_rated_gross, capacity, crankcase_kw, crankcase_temp, fan_power_rated)
    num_speeds = speed_indices.size

    if num_speeds > 1
      constant_biquadratic = create_curve_biquadratic_constant(model)
    end

    clg_coil = nil

    for speed_idx in speed_indices
      speed = speed_idx + 1
      cap_ft_spec_si = convert_curve_biquadratic(cap_ft_spec[speed_idx])
      eir_ft_spec_si = convert_curve_biquadratic(eir_ft_spec[speed_idx])
      cap_ft_curve = create_curve_biquadratic(model, cap_ft_spec_si, "Cool-Cap-fT#{speed}", 13.88, 23.88, 18.33, 51.66)
      eir_ft_curve = create_curve_biquadratic(model, eir_ft_spec_si, "Cool-eir-fT#{speed}", 13.88, 23.88, 18.33, 51.66)
      plf_fplr_curve = create_curve_quadratic(model, closs_fplr_spec[speed_idx], "Cool-PLF-fPLR#{speed}", 0, 1, 0.7, 1)
      cap_fff_curve = create_curve_quadratic(model, cap_fflow_spec[speed_idx], "Cool-Cap-fFF#{speed}", 0, 2, 0, 2)
      eir_fff_curve = create_curve_quadratic(model, eir_fflow_spec[speed_idx], "Cool-eir-fFF#{speed}", 0, 2, 0, 2)

      if num_speeds == 1
        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, cap_ft_curve, cap_fff_curve, eir_ft_curve, eir_fff_curve, plf_fplr_curve)
        clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(fan_power_rated / UnitConversions.convert(1.0, 'cfm', 'm^3/s'))
        if not crankcase_temp.nil?
          clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(UnitConversions.convert(crankcase_temp, 'F', 'C'))
        end
        clg_coil.setRatedCOP(1.0 / eirs[speed_idx])
        clg_coil.setRatedSensibleHeatRatio(shrs_rated_gross[speed_idx])
        if not capacity.nil?
          clg_coil.setRatedTotalCoolingCapacity(UnitConversions.convert([capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
        end
        clg_coil.setNominalTimeForCondensateRemovalToBegin(1000.0)
        clg_coil.setRatioOfInitialMoistureEvaporationRateAndSteadyStateLatentCapacity(1.5)
        clg_coil.setMaximumCyclingRate(3.0)
        clg_coil.setLatentCapacityTimeConstant(45.0)
      else
        if clg_coil.nil?
          clg_coil = OpenStudio::Model::CoilCoolingDXMultiSpeed.new(model)
          clg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
          clg_coil.setApplyLatentDegradationtoSpeedsGreaterthan1(false)
          clg_coil.setFuelType('electricity')
          clg_coil.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
          if not crankcase_temp.nil?
            clg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(UnitConversions.convert(crankcase_temp, 'F', 'C'))
          end
        end
        stage = OpenStudio::Model::CoilCoolingDXMultiSpeedStageData.new(model, cap_ft_curve, cap_fff_curve, eir_ft_curve, eir_fff_curve, plf_fplr_curve, constant_biquadratic)
        stage.setGrossRatedCoolingCOP(1.0 / eirs[speed_idx])
        stage.setGrossRatedSensibleHeatRatio(shrs_rated_gross[speed_idx])
        if not capacity.nil?
          stage.setGrossRatedTotalCoolingCapacity(UnitConversions.convert([capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
        end
        stage.setNominalTimeforCondensateRemovaltoBegin(1000)
        stage.setRatioofInitialMoistureEvaporationRateandSteadyStateLatentCapacity(1.5)
        stage.setRatedWasteHeatFractionofPowerInput(0.2)
        stage.setMaximumCyclingRate(3.0)
        stage.setLatentCapacityTimeConstant(45.0)
        clg_coil.addStage(stage)
      end
    end

    clg_coil.setName(obj_name + ' clg coil')
    clg_coil.setCondenserType('AirCooled')
    clg_coil.setCrankcaseHeaterCapacity(UnitConversions.convert(crankcase_kw, 'kW', 'W'))

    return clg_coil
  end

  def self.create_dx_heating_coil(model, obj_name, speed_indices, eirs, cap_ft_spec, eir_ft_spec, closs_fplr_spec, cap_fflow_spec, eir_fflow_spec, capacity, crankcase_kw, crankcase_temp, fan_power_rated, hp_min_temp)
    num_speeds = speed_indices.size

    if num_speeds > 1
      constant_biquadratic = create_curve_biquadratic_constant(model)
    end

    htg_coil = nil

    for speed_idx in speed_indices
      speed = speed_idx + 1
      cap_ft_spec_si = convert_curve_biquadratic(cap_ft_spec[speed_idx])
      eir_ft_spec_si = convert_curve_biquadratic(eir_ft_spec[speed_idx])
      cap_ft_curve = create_curve_biquadratic(model, cap_ft_spec_si, "HP_Heat-Cap-fT#{speed}", -100, 100, -100, 100)
      eir_ft_curve = create_curve_biquadratic(model, eir_ft_spec_si, "HP_Heat-eir-fT#{speed}", -100, 100, -100, 100)
      plf_fplr_curve = create_curve_quadratic(model, closs_fplr_spec[speed_idx], "HP_Heat-PLF-fPLR#{speed}", 0, 1, 0.7, 1)
      cap_fff_curve = create_curve_quadratic(model, cap_fflow_spec[speed_idx], "HP_Heat-CAP-fFF#{speed}", 0, 2, 0, 2)
      eir_fff_curve = create_curve_quadratic(model, eir_fflow_spec[speed_idx], "HP_Heat-eir-fFF#{speed}", 0, 2, 0, 2)

      if num_speeds == 1
        htg_coil = OpenStudio::Model::CoilHeatingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, cap_ft_curve, cap_fff_curve, eir_ft_curve, eir_fff_curve, plf_fplr_curve)
        htg_coil.setRatedSupplyFanPowerPerVolumeFlowRate(fan_power_rated / UnitConversions.convert(1.0, 'cfm', 'm^3/s'))
        htg_coil.setRatedCOP(1.0 / eirs[speed_idx])
        if not capacity.nil?
          htg_coil.setRatedTotalHeatingCapacity(UnitConversions.convert([capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
        end
        if not crankcase_temp.nil?
          htg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(UnitConversions.convert(crankcase_temp, 'F', 'C'))
        end
      else
        if htg_coil.nil?
          htg_coil = OpenStudio::Model::CoilHeatingDXMultiSpeed.new(model)
          htg_coil.setFuelType('electricity')
          htg_coil.setApplyPartLoadFractiontoSpeedsGreaterthan1(false)
          htg_coil.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
          if not crankcase_temp.nil?
            htg_coil.setMaximumOutdoorDryBulbTemperatureforCrankcaseHeaterOperation(UnitConversions.convert(crankcase_temp, 'F', 'C'))
          end
        end
        stage = OpenStudio::Model::CoilHeatingDXMultiSpeedStageData.new(model, cap_ft_curve, cap_fff_curve, eir_ft_curve, eir_fff_curve, plf_fplr_curve, constant_biquadratic)
        stage.setGrossRatedHeatingCOP(1.0 / eirs[speed_idx])
        if not capacity.nil?
          stage.setGrossRatedHeatingCapacity(UnitConversions.convert([capacity, Constants.small].max, 'Btu/hr', 'W')) # Used by HVACSizing measure
        end
        stage.setRatedWasteHeatFractionofPowerInput(0.2)
        htg_coil.addStage(stage)
      end
    end

    htg_coil.setName(obj_name + ' htg coil')
    htg_coil.setMinimumOutdoorDryBulbTemperatureforCompressorOperation(UnitConversions.convert(hp_min_temp, 'F', 'C'))
    htg_coil.setMaximumOutdoorDryBulbTemperatureforDefrostOperation(UnitConversions.convert(40.0, 'F', 'C'))
    defrost_eir_curve = create_curve_biquadratic(model, [0.1528, 0, 0, 0, 0, 0], 'Defrosteir', -100, 100, -100, 100) # Heating defrost curve for reverse cycle
    htg_coil.setDefrostEnergyInputRatioFunctionofTemperatureCurve(defrost_eir_curve)
    htg_coil.setDefrostStrategy('ReverseCycle')
    htg_coil.setDefrostControl('OnDemand')
    htg_coil.setCrankcaseHeaterCapacity(0)
    htg_coil.setCrankcaseHeaterCapacity(UnitConversions.convert(crankcase_kw, 'kW', 'W'))

    return htg_coil
  end

  def self.calc_cool_eirs(num_speeds, eers, fan_power_rated)
    cool_eirs = []
    (0...num_speeds).to_a.each do |speed|
      eir = calc_eir_from_eer(eers[speed], fan_power_rated)
      cool_eirs << eir
    end
    return cool_eirs
  end

  def self.calc_heat_eirs(num_speeds, cops, fan_power_rated)
    heat_eirs = []
    (0...num_speeds).to_a.each do |speed|
      eir = calc_eir_from_cop(cops[speed], fan_power_rated)
      heat_eirs << eir
    end
    return heat_eirs
  end

  def self.calc_shrs_rated_gross(num_speeds, shr_Rated_Net, fan_power_rated, cfms_ton_rated)
    # Convert SHRs from net to gross
    cool_shrs_rated_gross = []
    (0...num_speeds).to_a.each do |speed|
      qtot_net_nominal = 12000.0
      qsens_net_nominal = qtot_net_nominal * shr_Rated_Net[speed]
      qtot_gross_nominal = qtot_net_nominal + UnitConversions.convert(cfms_ton_rated[speed] * fan_power_rated, 'Wh', 'Btu')
      qsens_gross_nominal = qsens_net_nominal + UnitConversions.convert(cfms_ton_rated[speed] * fan_power_rated, 'Wh', 'Btu')
      cool_shrs_rated_gross << (qsens_gross_nominal / qtot_gross_nominal)

      # Make sure SHR's are in valid range based on E+ model limits.
      # The following correlation was developed by Jon Winkler to test for maximum allowed SHR based on the 300 - 450 cfm/ton limits in E+
      maxSHR = 0.3821066 + 0.001050652 * cfms_ton_rated[speed] - 0.01
      cool_shrs_rated_gross[speed] = [cool_shrs_rated_gross[speed], maxSHR].min
      minSHR = 0.60 # Approximate minimum SHR such that an ADP exists
      cool_shrs_rated_gross[speed] = [cool_shrs_rated_gross[speed], minSHR].max
    end

    return cool_shrs_rated_gross
  end

  def self.calc_plr_coefficients(c_d)
    return [(1.0 - c_d), c_d, 0.0] # Linear part load model
  end

  def self.get_cool_c_d(num_speeds, seer)
    # Degradation coefficient for cooling
    if num_speeds == 1
      if seer < 13.0
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

  def self.get_heat_c_d(num_speeds, hspf)
    # Degradation coefficient for heating
    if num_speeds == 1
      if hspf < 7.0
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

  def self.get_fan_power_installed(seer)
    if seer <= 15
      return 0.365 # W/cfm
    else
      return 0.14 # W/cfm
    end
  end

  def self.calc_fan_pressure_rise(fan_eff, fan_power)
    # Calculates needed fan pressure rise to achieve a given fan power with an assumed efficiency.
    # Previously we calculated the fan efficiency from an assumed pressure rise, which could lead to
    # errors (fan efficiencies > 1).
    return fan_eff * fan_power / UnitConversions.convert(1.0, 'cfm', 'm^3/s') # Pa
  end

  def self.calc_pump_head(pump_eff, pump_power)
    # Calculate needed pump head to achieve a given pump power with an assumed efficiency.
    # Previously we calculated the pump efficiency from an assumed pump head, which could lead to
    # errors (pump efficiencies > 1).
    return pump_eff * pump_power / UnitConversions.convert(1.0, 'gal/min', 'm^3/s') # Pa
  end

  def self.existing_equipment(model, thermal_zone, runner)
    # Returns a list of equipment objects

    equipment = []
    hvac_types = []

    unitary_system_air_loops = get_unitary_system_air_loops(model, thermal_zone)
    unitary_system_air_loops.each do |unitary_system_air_loop|
      system, clg_coil, htg_coil, air_loop = unitary_system_air_loop
      equipment << system

      hvac_type_cool = system.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACCoolType)
      hvac_types << hvac_type_cool.get if hvac_type_cool.is_initialized

      hvac_type_heat = system.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType)
      hvac_types << hvac_type_heat.get if hvac_type_heat.is_initialized
    end

    ptacs = get_ptacs(model, thermal_zone)
    ptacs.each do |ptac|
      equipment << ptac
      hvac_types << ptac.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACCoolType).get
    end

    evap_coolers = get_evap_coolers(model, thermal_zone)
    evap_coolers.each do |evap_cooler|
      equipment << evap_cooler
      hvac_types << evap_cooler.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACCoolType).get
    end

    baseboards = get_baseboard_waters(model, thermal_zone)
    baseboards.each do |baseboard|
      equipment << baseboard
      hvac_types << baseboard.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType).get
    end

    baseboards = get_baseboard_electrics(model, thermal_zone)
    baseboards.each do |baseboard|
      equipment << baseboard
      hvac_types << baseboard.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType).get
    end

    unitary_system_hvac_map = get_unitary_system_hvac_map(model, thermal_zone)
    unitary_system_hvac_map.each do |unitary_system_zone_hvac|
      system, clg_coil, htg_coil = unitary_system_zone_hvac
      next if htg_coil.nil?

      equipment << system
      hvac_types << system.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType).get
    end

    ideal_air = get_ideal_air(model, thermal_zone)
    if not ideal_air.nil?
      equipment << ideal_air
      hvac_types << ideal_air.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACCoolType).get
      hvac_types << ideal_air.additionalProperties.getFeatureAsString(Constants.SizingInfoHVACHeatType).get
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
      if (not htg_coil.nil?) && (htg_coil.availabilitySchedule == model.alwaysOffDiscreteSchedule)
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
      return if not hvac_component.is_initialized

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
    return
  end

  def self.get_evap_cooler_from_air_loop_hvac(air_loop)
    # Returns the evap cooler or nil
    air_loop.supplyComponents.each do |comp|
      next unless comp.to_EvaporativeCoolerDirectResearchSpecial.is_initialized

      return comp.to_EvaporativeCoolerDirectResearchSpecial.get
    end
    return
  end

  def self.get_unitary_system_air_loops(model, thermal_zone)
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

  def self.get_unitary_system_hvac_map(model, thermal_zone)
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

  def self.get_ptacs(model, thermal_zone)
    # Returns the PTAC(s) if available
    ptacs = []
    model.getZoneHVACPackagedTerminalAirConditioners.each do |ptac|
      next unless thermal_zone.handle.to_s == ptac.thermalZone.get.handle.to_s

      ptacs << ptac
    end
    return ptacs
  end

  def self.get_evap_coolers(model, thermal_zone)
    # Returns the evaporative cooler if available
    evap_coolers = []
    thermal_zone.airLoopHVACs.each do |air_loop|
      evap_cooler = get_evap_cooler_from_air_loop_hvac(air_loop)
      next if evap_cooler.nil?

      evap_coolers << evap_cooler
    end
    return evap_coolers
  end

  def self.get_baseboard_waters(model, thermal_zone)
    # Returns the water baseboard if available
    baseboards = []
    model.getZoneHVACBaseboardConvectiveWaters.each do |baseboard|
      next unless thermal_zone.handle.to_s == baseboard.thermalZone.get.handle.to_s

      baseboards << baseboard
    end
    return baseboards
  end

  def self.get_baseboard_electrics(model, thermal_zone)
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

  def self.get_ideal_air(model, thermal_zone)
    # Returns the heating ideal air loads system if available
    model.getZoneHVACIdealLoadsAirSystems.each do |ideal_air|
      next unless thermal_zone.handle.to_s == ideal_air.thermalZone.get.handle.to_s

      return ideal_air
    end
    return
  end

  def self.has_ducted_equipment(model, air_loop)
    if air_loop.name.to_s.include? Constants.ObjectNameEvaporativeCooler
      system = air_loop
    else
      system = get_unitary_system_from_air_loop_hvac(air_loop)
    end

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
    elsif [Constants.ObjectNameMiniSplitHeatPump, Constants.ObjectNameEvaporativeCooler].include? hvac_type_cool
      is_ducted = system.additionalProperties.getFeatureAsBoolean(Constants.OptionallyDuctedSystemIsDucted).get
      if is_ducted
        return true
      end
    end

    return false
  end

  def self.calc_mshp_cfms_ton_cooling(cap_min_per, cap_max_per, cfm_ton_min, cfm_ton_max, num_speeds, dB_rated, wB_rated, shr)
    cool_capacity_ratios = [0.0] * num_speeds
    cool_cfms_ton_rated = [0.0] * num_speeds
    cool_shrs_rated = [0.0] * num_speeds

    cap_nom_per = 1.0
    cfm_ton_nom = ((cfm_ton_max - cfm_ton_min) / (cap_max_per - cap_min_per)) * (cap_nom_per - cap_min_per) + cfm_ton_min

    p_atm = 14.696 # standard atmospheric pressure (psia)

    ao = Psychrometrics.CoilAoFactor(dB_rated, wB_rated, p_atm, UnitConversions.convert(1, 'ton', 'kBtu/hr'), cfm_ton_nom, shr)

    (0...num_speeds).each do |i|
      cool_capacity_ratios[i] = cap_min_per + i * (cap_max_per - cap_min_per) / (num_speeds - 1)
      cool_cfms_ton_rated[i] = cfm_ton_min + i * (cfm_ton_max - cfm_ton_min) / (num_speeds - 1)
      # Calculate the SHR for each speed. Use minimum value of 0.98 to prevent E+ bypass factor calculation errors
      cool_shrs_rated[i] = [Psychrometrics.CalculateSHR(dB_rated, wB_rated, p_atm, UnitConversions.convert(cool_capacity_ratios[i], 'ton', 'kBtu/hr'), cool_cfms_ton_rated[i], ao), 0.98].min
    end

    return cool_cfms_ton_rated, cool_capacity_ratios, cool_shrs_rated
  end

  def self.calc_mshp_cool_eirs(runner, seer, fan_power, c_d, num_speeds, cool_capacity_ratios, cool_cfms_ton_rated, cool_eir_ft_spec, cool_cap_ft_spec)
    cops_norm = [1.901, 1.859, 1.746, 1.609, 1.474, 1.353, 1.247, 1.156, 1.079, 1.0]
    fan_powers_norm = [0.604, 0.634, 0.670, 0.711, 0.754, 0.800, 0.848, 0.898, 0.948, 1.0]

    cool_eirs = [0.0] * num_speeds
    fan_powers_rated = [0.0] * num_speeds
    eers_Rated = [0.0] * num_speeds

    cop_maxSpeed = 3.5 # 3.5 is an initial guess, final value solved for below

    (0...num_speeds).each do |i|
      fan_powers_rated[i] = fan_power * fan_powers_norm[i]
      eers_Rated[i] = UnitConversions.convert(cop_maxSpeed, 'W', 'Btu/hr') * cops_norm[i]
    end

    cop_maxSpeed_1 = cop_maxSpeed
    cop_maxSpeed_2 = cop_maxSpeed
    error = seer - calc_mshp_seer_4speed(eers_Rated, c_d, cool_capacity_ratios, cool_cfms_ton_rated, fan_powers_rated, true, cool_eir_ft_spec, cool_cap_ft_spec)
    error1 = error
    error2 = error

    itmax = 50 # maximum iterations
    cvg = false
    final_n = nil

    (1...itmax + 1).each do |n|
      final_n = n
      (0...num_speeds).each do |i|
        eers_Rated[i] = UnitConversions.convert(cop_maxSpeed, 'W', 'Btu/hr') * cops_norm[i]
      end

      error = seer - calc_mshp_seer_4speed(eers_Rated, c_d, cool_capacity_ratios, cool_cfms_ton_rated, fan_powers_rated, true, cool_eir_ft_spec, cool_cap_ft_spec)

      cop_maxSpeed, cvg, cop_maxSpeed_1, error1, cop_maxSpeed_2, error2 = MathTools.Iterate(cop_maxSpeed, error, cop_maxSpeed_1, error1, cop_maxSpeed_2, error2, n, cvg)

      if cvg
        break
      end
    end

    if (not cvg) || (final_n > itmax)
      cop_maxSpeed = UnitConversions.convert(0.547 * seer - 0.104, 'Btu/hr', 'W') # Correlation developed from JonW's MatLab scripts. Only used if an eer cannot be found.
      runner.registerWarning('Mini-split heat pump cop iteration failed to converge. Setting to default value.')
    end

    (0...num_speeds).each do |i|
      cool_eirs[i] = calc_eir_from_eer(UnitConversions.convert(cop_maxSpeed, 'W', 'Btu/hr') * cops_norm[i], fan_powers_rated[i])
    end

    return cool_eirs
  end

  def self.calc_mshp_seer_4speed(eer_a, c_d, capacity_ratio, cfm_tons, fan_power_rated, is_heat_pump, cool_eir_ft_spec, cool_cap_ft_spec)
    n_max = (eer_a.length - 1.0) - 3.0 # Don't use max speed; FIXME: this is different than calc_mshp_hspf_4speed?
    n_min = 0
    n_int = (n_min + (n_max - n_min) / 3.0).ceil.to_i

    wBin = 67.0
    tout_B = 82.0
    tout_E = 87.0
    tout_F = 67.0

    eir_A2 = calc_eir_from_eer(eer_a[n_max], fan_power_rated[n_max])
    eir_B2 = eir_A2 * MathTools.biquadratic(wBin, tout_B, cool_eir_ft_spec[n_max])

    eir_Av = calc_eir_from_eer(eer_a[n_int], fan_power_rated[n_int])
    eir_Ev = eir_Av * MathTools.biquadratic(wBin, tout_E, cool_eir_ft_spec[n_int])

    eir_A1 = calc_eir_from_eer(eer_a[n_min], fan_power_rated[n_min])
    eir_B1 = eir_A1 * MathTools.biquadratic(wBin, tout_B, cool_eir_ft_spec[n_min])
    eir_F1 = eir_A1 * MathTools.biquadratic(wBin, tout_F, cool_eir_ft_spec[n_min])

    q_A2 = capacity_ratio[n_max]
    q_B2 = q_A2 * MathTools.biquadratic(wBin, tout_B, cool_cap_ft_spec[n_max])
    q_Ev = capacity_ratio[n_int] * MathTools.biquadratic(wBin, tout_E, cool_cap_ft_spec[n_int])
    q_B1 = capacity_ratio[n_min] * MathTools.biquadratic(wBin, tout_B, cool_cap_ft_spec[n_min])
    q_F1 = capacity_ratio[n_min] * MathTools.biquadratic(wBin, tout_F, cool_cap_ft_spec[n_min])

    q_A2_net = q_A2 - fan_power_rated[n_max] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_max] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    q_B2_net = q_B2 - fan_power_rated[n_max] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_max] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    q_Ev_net = q_Ev - fan_power_rated[n_int] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_int] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    q_B1_net = q_B1 - fan_power_rated[n_min] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_min] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    q_F1_net = q_F1 - fan_power_rated[n_min] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_min] / UnitConversions.convert(1, 'ton', 'Btu/hr')

    p_A2 = UnitConversions.convert(q_A2 * eir_A2, 'Btu', 'Wh') + fan_power_rated[n_max] * cfm_tons[n_max] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    p_B2 = UnitConversions.convert(q_B2 * eir_B2, 'Btu', 'Wh') + fan_power_rated[n_max] * cfm_tons[n_max] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    p_Ev = UnitConversions.convert(q_Ev * eir_Ev, 'Btu', 'Wh') + fan_power_rated[n_int] * cfm_tons[n_int] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    p_B1 = UnitConversions.convert(q_B1 * eir_B1, 'Btu', 'Wh') + fan_power_rated[n_min] * cfm_tons[n_min] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    p_F1 = UnitConversions.convert(q_F1 * eir_F1, 'Btu', 'Wh') + fan_power_rated[n_min] * cfm_tons[n_min] / UnitConversions.convert(1, 'ton', 'Btu/hr')

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
      elsif (q_k1 < bL) && (bL <= q_k2)
        q_Tj_N = bL * frac_hours[_i]
        eer_T_j = a + b * t_bins[_i] + c * t_bins[_i]**2
        e_Tj_N = q_Tj_N / eer_T_j
      else
        q_Tj_N = frac_hours[_i] * q_k2
        e_Tj_N = frac_hours[_i] * p_k2
      end

      q_tot += q_Tj_N
      e_tot += e_Tj_N
    end

    seer = q_tot / e_tot
    return seer
  end

  def self.calc_mshp_cfms_ton_heating(cap_min_per, cap_max_per, cfm_ton_min, cfm_ton_max, num_speeds)
    heat_capacity_ratios = [0.0] * num_speeds
    heat_cfms_ton_rated = [0.0] * num_speeds

    (0...num_speeds).each do |i|
      heat_capacity_ratios[i] = cap_min_per + i * (cap_max_per - cap_min_per) / (num_speeds - 1)
      heat_cfms_ton_rated[i] = cfm_ton_min + i * (cfm_ton_max - cfm_ton_min) / (num_speeds - 1)
    end

    return heat_cfms_ton_rated, heat_capacity_ratios
  end

  def self.calc_mshp_heat_eirs(runner, hspf, fan_power, hp_min_temp, c_d, cool_cfms_ton_rated, num_speeds, heat_capacity_ratios, heat_cfms_ton_rated, heat_eir_ft_spec, heat_cap_ft_spec)
    cops_norm = [1.792, 1.502, 1.308, 1.207, 1.145, 1.105, 1.077, 1.056, 1.041, 1]
    fan_powers_norm = [0.577, 0.625, 0.673, 0.720, 0.768, 0.814, 0.861, 0.907, 0.954, 1]

    heat_eirs = [0.0] * num_speeds
    fan_powers_rated = [0.0] * num_speeds
    cops_rated = [0.0] * num_speeds

    cop_maxSpeed = 3.25 # 3.35 is an initial guess, final value solved for below

    (0...num_speeds).each do |i|
      fan_powers_rated[i] = fan_power * fan_powers_norm[i]
      cops_rated[i] = cop_maxSpeed * cops_norm[i]
    end

    cop_maxSpeed_1 = cop_maxSpeed
    cop_maxSpeed_2 = cop_maxSpeed
    error = hspf - calc_mshp_hspf_4speed(cops_rated, c_d, heat_capacity_ratios, heat_cfms_ton_rated, fan_powers_rated, hp_min_temp, heat_eir_ft_spec, heat_cap_ft_spec)

    error1 = error
    error2 = error

    itmax = 50 # maximum iterations
    cvg = false
    final_n = nil

    (1...itmax + 1).each do |n|
      final_n = n
      (0...num_speeds).each do |i|
        cops_rated[i] = cop_maxSpeed * cops_norm[i]
      end

      error = hspf - calc_mshp_hspf_4speed(cops_rated, c_d, heat_capacity_ratios, cool_cfms_ton_rated, fan_powers_rated, hp_min_temp, heat_eir_ft_spec, heat_cap_ft_spec)

      cop_maxSpeed, cvg, cop_maxSpeed_1, error1, cop_maxSpeed_2, error2 = MathTools.Iterate(cop_maxSpeed, error, cop_maxSpeed_1, error1, cop_maxSpeed_2, error2, n, cvg)

      if cvg
        break
      end
    end

    if (not cvg) || (final_n > itmax)
      cop_maxSpeed = UnitConversions.convert(0.4174 * hspf - 1.1134, 'Btu/hr', 'W') # Correlation developed from JonW's MatLab scripts. Only used if a cop cannot be found.
      runner.registerWarning('Mini-split heat pump cop iteration failed to converge. Setting to default value.')
    end

    (0...num_speeds).each do |i|
      heat_eirs[i] = calc_eir_from_cop(cop_maxSpeed * cops_norm[i], fan_powers_rated[i])
    end

    return heat_eirs
  end

  def self.calc_mshp_hspf_4speed(cop_47, c_d, capacity_ratio, cfm_tons, fan_power_rated, hp_min_temp, heat_eir_ft_spec, heat_cap_ft_spec)
    n_max = (cop_47.length - 1.0) #-3 # Don't use max speed; FIXME: this is different than calc_mshp_seer_4speed?
    n_min = 0
    n_int = (n_min + (n_max - n_min) / 3.0).ceil.to_i

    tin = 70.0
    tout_3 = 17.0
    tout_2 = 35.0
    tout_0 = 62.0

    eir_H1_2 = calc_eir_from_cop(cop_47[n_max], fan_power_rated[n_max])
    eir_H3_2 = eir_H1_2 * MathTools.biquadratic(tin, tout_3, heat_eir_ft_spec[n_max])

    eir_adjv = calc_eir_from_cop(cop_47[n_int], fan_power_rated[n_int])
    eir_H2_v = eir_adjv * MathTools.biquadratic(tin, tout_2, heat_eir_ft_spec[n_int])

    eir_H1_1 = calc_eir_from_cop(cop_47[n_min], fan_power_rated[n_min])
    eir_H0_1 = eir_H1_1 * MathTools.biquadratic(tin, tout_0, heat_eir_ft_spec[n_min])

    q_H1_2 = capacity_ratio[n_max]
    q_H3_2 = q_H1_2 * MathTools.biquadratic(tin, tout_3, heat_cap_ft_spec[n_max])

    q_H2_v = capacity_ratio[n_int] * MathTools.biquadratic(tin, tout_2, heat_cap_ft_spec[n_int])

    q_H1_1 = capacity_ratio[n_min]
    q_H0_1 = q_H1_1 * MathTools.biquadratic(tin, tout_0, heat_cap_ft_spec[n_min])

    q_H1_2_net = q_H1_2 + fan_power_rated[n_max] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_max] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    q_H3_2_net = q_H3_2 + fan_power_rated[n_max] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_max] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    q_H2_v_net = q_H2_v + fan_power_rated[n_int] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_int] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    q_H1_1_net = q_H1_1 + fan_power_rated[n_min] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_min] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    q_H0_1_net = q_H0_1 + fan_power_rated[n_min] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_min] / UnitConversions.convert(1, 'ton', 'Btu/hr')

    p_H1_2 = q_H1_2 * eir_H1_2 + fan_power_rated[n_max] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_max] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    p_H3_2 = q_H3_2 * eir_H3_2 + fan_power_rated[n_max] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_max] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    p_H2_v = q_H2_v * eir_H2_v + fan_power_rated[n_int] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_int] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    p_H1_1 = q_H1_1 * eir_H1_1 + fan_power_rated[n_min] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_min] / UnitConversions.convert(1, 'ton', 'Btu/hr')
    p_H0_1 = q_H0_1 * eir_H0_1 + fan_power_rated[n_min] * UnitConversions.convert(1, 'W', 'Btu/hr') * cfm_tons[n_min] / UnitConversions.convert(1, 'ton', 'Btu/hr')

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

    # T_off = hp_min_temp
    t_off = 10.0
    t_on = t_off + 4.0
    etot = 0
    bLtot = 0

    (0...15).each do |_i|
      bL = ((65.0 - t_bins[_i]) / (65.0 - t_OD)) * 0.77 * dHR

      q_1 = q_H1_1_net + (q_H0_1_net - q_H1_1_net) / (62.0 - 47.0) * (t_bins[_i] - 47.0)
      p_1 = p_H1_1 + (p_H0_1 - p_H1_1) / (62.0 - 47.0) * (t_bins[_i] - 47.0)

      if (t_bins[_i] <= 17.0) || (t_bins[_i] >= 45.0)
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
      elsif (q_1 < bL) && (bL <= q_2)
        cop_T_j = a + b * t_bins[_i] + c * t_bins[_i]**2
        e_Tj_n = delta * frac_hours[_i] * bL / cop_T_j + (1.0 - delta) * bL * (frac_hours[_i])
      else
        e_Tj_n = delta * frac_hours[_i] * p_2 + frac_hours[_i] * (bL - delta * q_2)
      end

      bLtot += frac_hours[_i] * bL
      etot += e_Tj_n
    end

    hspf = bLtot / UnitConversions.convert(etot, 'Btu/hr', 'W')
    return hspf
  end

  def self.calc_sequential_load_fraction(load_fraction, remaining_fraction)
    if remaining_fraction > 0
      sequential_load_frac = load_fraction / remaining_fraction # Fraction of remaining load served by this system
    else
      sequential_load_frac = 0.0
    end

    return sequential_load_frac
  end

  def self.get_sequential_load_schedule(model, value)
    s = OpenStudio::Model::ScheduleConstant.new(model)
    s.setName('Sequential Fraction Schedule')
    if value > 1
      s.setValue(1.0)
    else
      s.setValue(value.round(5))
    end
    Schedule.set_schedule_type_limits(model, s, Constants.ScheduleTypeLimitsFraction)
    return s
  end

  def self.get_crankcase_assumptions()
    crankcase_kw = 0.05 # From RESNET Publication No. 002-2017
    crankcase_temp = 50.0 # From RESNET Publication No. 002-2017
    return crankcase_kw, crankcase_temp
  end

  def self.get_heatpump_temp_assumptions(heat_pump)
    # Calculates:
    # 1. Minimum temperature for HP compressor operation
    # 2. Maximum temperature for HP supplemental heating operation
    if not heat_pump.backup_heating_switchover_temp.nil?
      hp_min_temp = heat_pump.backup_heating_switchover_temp
      supp_max_temp = heat_pump.backup_heating_switchover_temp
    else
      supp_max_temp = 40.0
      # Minimum temperature for Heat Pump operation:
      if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpMiniSplit
        hp_min_temp = -30.0 # deg-F
      else
        hp_min_temp = 0.0 # deg-F
      end
    end
    return hp_min_temp, supp_max_temp
  end
end
