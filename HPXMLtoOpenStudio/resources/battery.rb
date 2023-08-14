# frozen_string_literal: true

class Battery
  def self.apply(runner, model, pv_systems, battery, schedules_file)
    charging_schedule = nil
    discharging_schedule = nil
    if not schedules_file.nil?
      charging_schedule = schedules_file.create_schedule_file(col_name: SchedulesFile::ColumnBatteryCharging)
      discharging_schedule = schedules_file.create_schedule_file(col_name: SchedulesFile::ColumnBatteryDischarging)
    end

    if pv_systems.empty? && charging_schedule.nil? && discharging_schedule.nil?
      runner.registerWarning('Battery without PV specified, and no charging/discharging schedule provided; battery is assumed to operate as backup and will not be modeled.')
      return
    end

    obj_name = battery.id

    rated_power_output = battery.rated_power_output # W
    nominal_voltage = battery.nominal_voltage # V
    if not battery.nominal_capacity_kwh.nil?
      if battery.usable_capacity_kwh.nil?
        fail "UsableCapacity and NominalCapacity for Battery '#{battery.id}' must be in the same units."
      end

      nominal_capacity_kwh = battery.nominal_capacity_kwh # kWh
      usable_capacity_kwh = battery.usable_capacity_kwh
      usable_fraction = usable_capacity_kwh / nominal_capacity_kwh
    else
      if battery.usable_capacity_ah.nil?
        fail "UsableCapacity and NominalCapacity for Battery '#{battery.id}' must be in the same units."
      end

      nominal_capacity_kwh = get_kWh_from_Ah(battery.nominal_capacity_ah, nominal_voltage) # kWh
      usable_capacity_ah = battery.usable_capacity_ah
      usable_capacity_kwh = get_kWh_from_Ah(usable_capacity_ah, nominal_voltage) # kWh
      usable_fraction = usable_capacity_ah / battery.nominal_capacity_ah
    end

    return if rated_power_output <= 0 || nominal_capacity_kwh <= 0 || nominal_voltage <= 0

    is_outside = (battery.location == HPXML::LocationOutside)
    if not is_outside
      frac_sens = 1.0
    else # Internal gains outside unit
      frac_sens = 0.0
    end

    default_nominal_cell_voltage = 3.342 # V, EnergyPlus default
    default_cell_capacity = 3.2 # Ah, EnergyPlus default

    number_of_cells_in_series = Integer((nominal_voltage / default_nominal_cell_voltage).round)
    number_of_strings_in_parallel = Integer(((nominal_capacity_kwh * 1000.0) / ((default_nominal_cell_voltage * number_of_cells_in_series) * default_cell_capacity)).round)
    battery_mass = (nominal_capacity_kwh / 10.0) * 99.0 # kg
    battery_surface_area = 0.306 * (nominal_capacity_kwh**(2.0 / 3.0)) # m^2

    # Assuming 3/4 of unusable charge is minimum SOC and 1/4 of unusable charge is maximum SOC, based on SAM defaults
    unusable_fraction = 1.0 - usable_fraction
    minimum_storage_state_of_charge_fraction = 0.75 * unusable_fraction
    maximum_storage_state_of_charge_fraction = 1.0 - 0.25 * unusable_fraction

    # disable voltage dependency unless lifetime model is requested: this prevents some scenarios where changes to SoC didn't seem to reflect charge rate due to voltage dependency and constant current
    voltage_dependence = false
    if battery.lifetime_model == HPXML::BatteryLifetimeModelKandlerSmith
      voltage_dependence = true
    end

    elcs = OpenStudio::Model::ElectricLoadCenterStorageLiIonNMCBattery.new(model, number_of_cells_in_series, number_of_strings_in_parallel, battery_mass, battery_surface_area)
    elcs.setName("#{obj_name} li ion")
    unless is_outside
      elcs.setThermalZone(battery.additional_properties.space.thermalZone.get)
    end
    elcs.setRadiativeFraction(0.9 * frac_sens)
    # elcs.setLifetimeModel(battery.lifetime_model)
    elcs.setLifetimeModel(HPXML::BatteryLifetimeModelNone)
    elcs.setNumberofCellsinSeries(number_of_cells_in_series)
    elcs.setNumberofStringsinParallel(number_of_strings_in_parallel)
    elcs.setInitialFractionalStateofCharge(0.0)
    elcs.setBatteryMass(battery_mass)
    elcs.setBatterySurfaceArea(battery_surface_area)
    elcs.setDefaultNominalCellVoltage(default_nominal_cell_voltage)
    elcs.setFullyChargedCellCapacity(default_cell_capacity)
    elcs.setCellVoltageatEndofNominalZone(default_nominal_cell_voltage)
    if not voltage_dependence
      elcs.setBatteryCellInternalElectricalResistance(0.002) # 2 mOhm/cell, based on OCHRE defaults (which are based on fitting to lab results)
      # FIXME: if the voltage reported during charge/discharge is different, energy may not balance
      # elcs.setFullyChargedCellVoltage(default_nominal_cell_voltage)
      # elcs.setCellVoltageatEndofExponentialZone(default_nominal_cell_voltage)
    end
    elcs.setFullyChargedCellVoltage(default_nominal_cell_voltage)
    elcs.setCellVoltageatEndofExponentialZone(default_nominal_cell_voltage)

    elcds = model.getElectricLoadCenterDistributions
    elcds = elcds.select { |elcd| elcd.inverter.is_initialized } # i.e., not generators
    if elcds.empty?
      elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
      elcd.setName('Battery elec load center dist')
      elcd.setElectricalBussType('AlternatingCurrentWithStorage')
    else
      elcd = elcds[0] # i.e., pv

      elcd.setElectricalBussType('DirectCurrentWithInverterACStorage')
      elcd.setStorageOperationScheme('TrackFacilityElectricDemandStoreExcessOnSite')
    end

    elcd.setMinimumStorageStateofChargeFraction(minimum_storage_state_of_charge_fraction)
    elcd.setMaximumStorageStateofChargeFraction(maximum_storage_state_of_charge_fraction)
    elcd.setElectricalStorage(elcs)
    elcd.setDesignStorageControlDischargePower(rated_power_output)
    elcd.setDesignStorageControlChargePower(rated_power_output)

    if (not charging_schedule.nil?) && (not discharging_schedule.nil?)
      elcd.setStorageOperationScheme('TrackChargeDischargeSchedules')
      elcd.setStorageChargePowerFractionSchedule(charging_schedule)
      elcd.setStorageDischargePowerFractionSchedule(discharging_schedule)

      elcsc = OpenStudio::Model::ElectricLoadCenterStorageConverter.new(model)
      elcsc.setName("#{obj_name} li ion converter")
      elcsc.setSimpleFixedEfficiency(1.0)
      elcd.setStorageConverter(elcsc)
    end

    frac_lost = 0.0
    space = battery.additional_properties.space
    if space.nil?
      space = model.getSpaces[0]
      frac_lost = 1.0
    end

    # Apply round trip efficiency as EMS program b/c E+ input is not hooked up.
    # Replace this when the first item in https://github.com/NREL/EnergyPlus/issues/9176 is fixed.
    charge_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Electric Storage Charge Energy')
    charge_sensor.setName('battery_charge')
    charge_sensor.setKeyName(elcs.name.to_s)

    loss_adj_object_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
    loss_adj_object = OpenStudio::Model::OtherEquipment.new(loss_adj_object_def)
    obj_name = Constants.ObjectNameBatteryLossesAdjustment
    loss_adj_object.setName(obj_name)
    loss_adj_object.setEndUseSubcategory(obj_name)
    loss_adj_object.setFuelType(EPlus.fuel_type(HPXML::FuelTypeElectricity))
    loss_adj_object.setSpace(space)
    loss_adj_object_def.setName(obj_name)
    loss_adj_object_def.setDesignLevel(0.01)
    loss_adj_object_def.setFractionRadiant(0)
    loss_adj_object_def.setFractionLatent(0)
    loss_adj_object_def.setFractionLost(frac_lost)
    loss_adj_object.setSchedule(model.alwaysOnDiscreteSchedule)

    battery_adj_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(loss_adj_object, *EPlus::EMSActuatorOtherEquipmentPower, loss_adj_object.space.get)
    battery_adj_actuator.setName('battery loss_adj_act')

    battery_losses_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    battery_losses_program.setName('battery_losses')
    battery_losses_program.addLine("Set losses = -1 * #{charge_sensor.name} * (1 - #{battery.round_trip_efficiency})")
    battery_losses_program.addLine("Set #{battery_adj_actuator.name} = -1 * losses / ( 3600 * SystemTimeStep )")

    battery_losses_pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    battery_losses_pcm.setName('battery_losses')
    battery_losses_pcm.setCallingPoint('EndOfSystemTimestepBeforeHVACReporting')
    battery_losses_pcm.addProgram(battery_losses_program)

    # FIXME: Shouldn't need this; can use OtherEquipment output var instead
    battery_losses_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'losses')
    battery_losses_output_var.setName("#{obj_name} outvar")
    battery_losses_output_var.setTypeOfDataInVariable('Summed')
    battery_losses_output_var.setUpdateFrequency('SystemTimestep')
    battery_losses_output_var.setEMSProgramOrSubroutineName(battery_losses_program)
    battery_losses_output_var.setUnits('J')

    elcd.additionalProperties.setFeature('HPXML_ID', battery.id)
    elcs.additionalProperties.setFeature('HPXML_ID', battery.id)
    elcs.additionalProperties.setFeature('UsableCapacity_kWh', Float(usable_capacity_kwh))
    elcs.additionalProperties.setFeature('BatteryLosses', battery_losses_output_var.name.to_s)
  end

  def self.get_battery_default_values(has_garage = false)
    if has_garage
      location = HPXML::LocationGarage
    else
      location = HPXML::LocationOutside
    end
    return { location: location,
             lifetime_model: HPXML::BatteryLifetimeModelNone,
             nominal_capacity_kwh: 10.0,
             nominal_voltage: 50.0,
             round_trip_efficiency: 0.925, # Based on Tesla Powerwall round trip efficiency (new)
             usable_fraction: 0.9 } # Fraction of usable capacity to nominal capacity
  end

  def self.get_Ah_from_kWh(nominal_capacity_kwh, nominal_voltage)
    return nominal_capacity_kwh * 1000.0 / nominal_voltage
  end

  def self.get_kWh_from_Ah(nominal_capacity_ah, nominal_voltage)
    return nominal_capacity_ah * nominal_voltage / 1000.0
  end
end
