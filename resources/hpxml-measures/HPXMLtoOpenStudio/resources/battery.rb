# frozen_string_literal: true

class Battery
  def self.apply(runner, model, battery)
    obj_name = battery.id

    rated_power_output = battery.rated_power_output # W
    nominal_voltage = battery.nominal_voltage # V
    if not battery.nominal_capacity_kwh.nil?
      nominal_capacity_kwh = battery.nominal_capacity_kwh # kWh
    else
      nominal_capacity_kwh = get_kWh_from_Ah(battery.nominal_capacity_ah, nominal_voltage) # kWh
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

    minimum_storage_state_of_charge_fraction = 0.15 # from SAM
    maximum_storage_state_of_charge_fraction = 0.95 # from SAM
    initial_fractional_state_of_charge = 0.5 # from SAM

    elcs = OpenStudio::Model::ElectricLoadCenterStorageLiIonNMCBattery.new(model, number_of_cells_in_series, number_of_strings_in_parallel, battery_mass, battery_surface_area)
    elcs.setName("#{obj_name} li ion")
    unless is_outside
      space = battery.additional_properties.space
      thermal_zone = space.thermalZone.get
      elcs.setThermalZone(thermal_zone)
    end
    elcs.setRadiativeFraction(0.9 * frac_sens)
    elcs.setLifetimeModel(battery.lifetime_model)
    elcs.setNumberofCellsinSeries(number_of_cells_in_series)
    elcs.setNumberofStringsinParallel(number_of_strings_in_parallel)
    elcs.setInitialFractionalStateofCharge(initial_fractional_state_of_charge)
    elcs.setBatteryMass(battery_mass)
    elcs.setBatterySurfaceArea(battery_surface_area)
    elcs.setDefaultNominalCellVoltage(default_nominal_cell_voltage)
    elcs.setCellVoltageatEndofNominalZone(default_nominal_cell_voltage)
    elcs.setFullyChargedCellCapacity(default_cell_capacity)

    model.getElectricLoadCenterDistributions.each do |elcd|
      next unless elcd.inverter.is_initialized

      elcd.setElectricalBussType('DirectCurrentWithInverterDCStorage')
      elcd.setMinimumStorageStateofChargeFraction(minimum_storage_state_of_charge_fraction)
      elcd.setMaximumStorageStateofChargeFraction(maximum_storage_state_of_charge_fraction)
      elcd.setStorageOperationScheme('TrackFacilityElectricDemandStoreExcessOnSite')
      elcd.setElectricalStorage(elcs)
      runner.registerWarning("Due to an OpenStudio bug, the battery's rated power output will not be honored; the simulation will proceed without a maximum charge/discharge limit.")
      elcd.setDesignStorageControlDischargePower(rated_power_output)
      elcd.setDesignStorageControlChargePower(rated_power_output)
    end
  end

  def self.get_battery_default_values()
    return { location: HPXML::LocationOutside,
             lifetime_model: HPXML::BatteryLifetimeModelNone,
             rated_power_output: 5000.0,
             nominal_capacity_kwh: 10.0,
             nominal_voltage: 50.0 }
  end

  def self.get_Ah_from_kWh(nominal_capacity_kwh, nominal_voltage)
    return nominal_capacity_kwh * 1000.0 / nominal_voltage
  end

  def self.get_kWh_from_Ah(nominal_capacity_ah, nominal_voltage)
    return nominal_capacity_ah * nominal_voltage / 1000.0
  end
end
