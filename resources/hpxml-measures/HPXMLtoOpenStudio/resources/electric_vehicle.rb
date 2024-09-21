# frozen_string_literal: true

require_relative 'battery'

# Collection of methods for adding electric vehicle-related OpenStudio objects, built on the Battery class
class ElectricVehicle
  # Apply an electric vehicle to the model using the HPXMLtoOpenStudio/resources/battery.rb Battery class, which assigns OpenStudio ElectricLoadCenterStorageLiIonNMCBattery, ElectricLoadCenterDistribution, OtherEquipment, and EMS objects.
  # Custom adjustments for EV operation are made with an EMS object within this class and in the Battery class.
  # An EMS program models the effect of ambient temperature on the effective power output.
  # An EMS program writes a 'discharge offset' variable to omit this from aggregate home electricity outputs.
  # If no charging/discharging schedule is provided, then the electric vehicle is not modeled.
  # Bi-directional charging is not currently implemented
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param electric_vehicle [HPXML::Vehicle] Object that defines a single electric vehicle
  # @param ev_charger [HPXML::ElectricVehicleCharger] Object that defines a single electric vehicle charger connected to the electric vehicle
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @param unit_multiplier [Integer] Number of similar dwelling units
  # @return [nil]
  def self.apply(runner, model, electric_vehicle, ev_charger, schedules_file, unit_multiplier)
    if ev_charger.nil?
      runner.registerWarning('Electric vehicle specified with no charger provided; battery will not be modeled.')
      return
    end
    Battery.apply(runner, model, nil, nil, electric_vehicle, schedules_file, unit_multiplier, is_ev: true, ev_charger: ev_charger)

    # Apply EMS porgram to adjust discharge power based on ambient temperature.
    model.getElectricLoadCenterStorageLiIonNMCBatterys.each do |elcs|
      next unless elcs.name.to_s.include? electric_vehicle.id

      ev_elcd = nil
      model.getElectricLoadCenterDistributions.each do |elcd|
        if elcd.name.to_s.include? electric_vehicle.id
          ev_elcd = elcd
          break
        end
      end

      # Calculate effective discharge power
      hrs_driven_year = electric_vehicle.hours_per_week / 7 * UnitConversions.convert(1, 'yr', 'day') # hrs/year
      ev_annl_energy = electric_vehicle.energy_efficiency * electric_vehicle.miles_per_year # kWh/year
      eff_discharge_power = UnitConversions.convert(ev_annl_energy / hrs_driven_year, 'kw', 'w') # W

      eff_charge_power = ev_elcd.designStorageControlChargePower
      discharging_schedule = ev_elcd.storageDischargePowerFractionSchedule.get
      charging_schedule = ev_elcd.storageChargePowerFractionSchedule.get

      discharge_power_act = OpenStudio::Model::EnergyManagementSystemActuator.new(ev_elcd, 'Electrical Storage', 'Power Draw Rate')
      discharge_power_act.setName('battery_discharge_power_act')
      charge_power_act = OpenStudio::Model::EnergyManagementSystemActuator.new(ev_elcd, 'Electrical Storage', 'Power Charge Rate')
      charge_power_act.setName('battery_charge_power_act')

      temp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Drybulb Temperature')
      temp_sensor.setName('site_temp')
      temp_sensor.setKeyName('Environment')
      discharge_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      discharge_sch_sensor.setName('discharge_sch_sensor')
      discharge_sch_sensor.setKeyName(discharging_schedule.name.to_s)
      charge_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
      charge_sch_sensor.setName('charge_sch_sensor')
      charge_sch_sensor.setKeyName(charging_schedule.name.to_s)

      ev_discharge_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      ev_discharge_program.setName('ev_discharge')

      # Power adjustment vs ambient temperature curve; derived from most recent data for Figure 9 of https://www.nrel.gov/docs/fy23osti/83916.pdf
      coefs = [1.412768, -3.910397E-02, 9.408235E-04, 8.971560E-06, -7.699244E-07, 1.265614E-08]
      power_curve = ''
      coefs.each_with_index do |coef, i|
        power_curve += "+(#{coef}*(site_temp_adj^#{i}))"
      end
      power_curve = power_curve[1..]
      ev_discharge_program.addLine("  Set power_mult = #{power_curve}")
      ev_discharge_program.addLine("  Set site_temp_adj = #{temp_sensor.name}")
      ev_discharge_program.addLine("  If #{temp_sensor.name} < -17.778")
      ev_discharge_program.addLine('    Set site_temp_adj = -17.778')
      ev_discharge_program.addLine("  ElseIf #{temp_sensor.name} > 37.609")
      ev_discharge_program.addLine('    Set site_temp_adj = 37.609')
      ev_discharge_program.addLine('  EndIf')

      ev_discharge_program.addLine("  If #{discharge_sch_sensor.name} > 0.0")
      ev_discharge_program.addLine("    Set #{discharge_power_act.name} = #{eff_discharge_power} * power_mult")
      ev_discharge_program.addLine("    Set #{charge_power_act.name} = 0")
      ev_discharge_program.addLine("  ElseIf #{charge_sch_sensor.name} > 0.0")
      ev_discharge_program.addLine("    Set #{charge_power_act.name} = #{eff_charge_power}")
      ev_discharge_program.addLine("    Set #{discharge_power_act.name} = 0")
      ev_discharge_program.addLine('  Else')
      ev_discharge_program.addLine("    Set #{charge_power_act.name} = 0")
      ev_discharge_program.addLine("    Set #{discharge_power_act.name} = 0")
      ev_discharge_program.addLine('  EndIf')

      # Define equipment object to offset discharge power so that it is excluded from charging energy and electricity meter
      ev_discharge_offset_obj_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
      ev_discharge_offset_obj = OpenStudio::Model::OtherEquipment.new(ev_discharge_offset_obj_def)
      obj_name = Constants::ObjectTypeEVBatteryDischargeOffset
      ev_discharge_offset_obj.setName(obj_name)
      ev_discharge_offset_obj.setEndUseSubcategory(obj_name)
      ev_discharge_offset_obj.setFuelType(EPlus.fuel_type(HPXML::FuelTypeElectricity))
      offset_space = nil
      if not electric_vehicle.additional_properties.space.nil?
        offset_space = electric_vehicle.additional_properties.space
      else
        offset_space = model.getSpaces[0]
      end
      ev_discharge_offset_obj.setSpace(offset_space)
      ev_discharge_offset_obj_def.setName(obj_name)
      ev_discharge_offset_obj_def.setDesignLevel(0)
      ev_discharge_offset_obj_def.setFractionRadiant(0)
      ev_discharge_offset_obj_def.setFractionLatent(0)
      ev_discharge_offset_obj_def.setFractionLost(1)
      ev_discharge_offset_obj.setSchedule(model.alwaysOnDiscreteSchedule)
      ev_discharge_offset_act = OpenStudio::Model::EnergyManagementSystemActuator.new(ev_discharge_offset_obj, *EPlus::EMSActuatorOtherEquipmentPower, offset_space)
      ev_discharge_offset_act.setName('ev_discharge_offset_act')
      ev_discharge_program.addLine("Set #{ev_discharge_offset_act.name} = #{discharge_power_act.name}")

      ev_discharge_pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      ev_discharge_pcm.setName('ev_discharge_pcm')
      ev_discharge_pcm.setCallingPoint('EndOfZoneTimestepAfterZoneReporting')
      ev_discharge_pcm.addProgram(ev_discharge_program)
    end
  end

  # Get default lifetime model, miles/year, hours/week, nominal capacity/voltage, round trip efficiency, fraction charged at home, and usable fraction for an electric vehicle and its battery.
  #
  # @return [Hash] map of battery properties to default values
  def self.get_ev_battery_default_values
    return { lifetime_model: HPXML::BatteryLifetimeModelNone,
             miles_per_year: 5000,
             hours_per_week: 11.6,
             nominal_capacity_kwh: 100.0,
             nominal_voltage: 50.0,
             round_trip_efficiency: 0.925,
             fraction_charged_home: 1.0,
             usable_fraction: 0.8 } # Fraction of usable capacity to nominal capacity
  end

  # Get default location, charging power, and charging level for an electric vehicle charger. The default location is the garage if one is present.
  #
  # @param has_garage [Boolean] whether the HPXML Building object has a garage
  # @return [Hash] map of electric vehicle charger properties to default values
  def self.get_ev_charger_default_values(has_garage = false)
    if has_garage
      location = HPXML::LocationGarage
    else
      location = HPXML::LocationOutside
    end

    return { location: location,
             charging_power: 5690, # Median L2 charging rate in EVWatts
             charging_level: 2 }
  end
end
