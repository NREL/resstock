# frozen_string_literal: true

# Collection of methods for adding vehicle-related OpenStudio objects, built on the Battery class
class Vehicle
  # Adds any HPXML Vehicles to the OpenStudio model.
  # Currently only models electric vehicles.
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply(runner, model, spaces, hpxml_bldg, schedules_file)
    hpxml_bldg.vehicles.each do |vehicle|
      next unless vehicle.vehicle_type == Constants::ObjectTypeBatteryElectricVehicle

      apply_electric_vehicle(runner, model, spaces, hpxml_bldg, vehicle, schedules_file)
    end
  end

  # Apply an electric vehicle to the model using the battery.rb Battery class, which assigns OpenStudio ElectricLoadCenterStorageLiIonNMCBattery, ElectricLoadCenterDistribution, OtherEquipment, and EMS objects.
  # Custom adjustments for EV operation are made with an EMS object within this class and in the Battery class.
  # An EMS program models the effect of ambient temperature on the effective power output.
  # An EMS program writes a 'discharge offset' variable to omit this from aggregate home electricity outputs.
  # If no charging/discharging schedule is provided, then the electric vehicle is not modeled.
  # Bi-directional charging is not currently implemented
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param spaces [Hash] Map of HPXML locations => OpenStudio Space objects
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param vehicle [HPXML::Vehicle] Object that defines a single electric vehicle
  # @param schedules_file [SchedulesFile] SchedulesFile wrapper class instance of detailed schedule files
  # @return [nil]
  def self.apply_electric_vehicle(runner, model, spaces, hpxml_bldg, vehicle, schedules_file)
    # Assign charging and vehicle space
    ev_charger = vehicle.ev_charger
    if ev_charger.nil?
      runner.registerWarning('Electric vehicle specified with no charger provided; battery will not be modeled.')
      return
    else
      ev_charger.additional_properties.space = Geometry.get_space_from_location(ev_charger.location, spaces)
      vehicle.location = ev_charger.location
      vehicle.additional_properties.space = Geometry.get_space_from_location(vehicle.location, spaces)
    end
    Battery.apply_battery(runner, model, spaces, hpxml_bldg, vehicle, schedules_file)

    # Apply EMS program to adjust discharge power based on ambient temperature.
    model.getElectricLoadCenterStorageLiIonNMCBatterys.each do |elcs|
      next unless elcs.name.to_s.include? vehicle.id

      ev_elcd = nil
      model.getElectricLoadCenterDistributions.each do |elcd|
        if elcd.name.to_s.include? vehicle.id
          ev_elcd = elcd
          break
        end
      end

      # Calculate effective discharge power
      hrs_driven_year = vehicle.hours_per_week / 7 * UnitConversions.convert(1, 'yr', 'day') # hrs/year
      ev_annl_energy = vehicle.energy_efficiency * vehicle.miles_per_year # kWh/year
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
      ev_discharge_program.addLine("    Set #{discharge_power_act.name} = #{eff_discharge_power} * power_mult * #{discharge_sch_sensor.name}")
      ev_discharge_program.addLine("    Set #{charge_power_act.name} = 0")
      ev_discharge_program.addLine("  ElseIf #{charge_sch_sensor.name} > 0.0")
      ev_discharge_program.addLine("    Set #{charge_power_act.name} = #{eff_charge_power} * #{charge_sch_sensor.name}")
      ev_discharge_program.addLine("    Set #{discharge_power_act.name} = 0")
      ev_discharge_program.addLine('  Else')
      ev_discharge_program.addLine("    Set #{charge_power_act.name} = 0")
      ev_discharge_program.addLine("    Set #{discharge_power_act.name} = 0")
      ev_discharge_program.addLine('  EndIf')

      ev_discharge_pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      ev_discharge_pcm.setName('ev_discharge_pcm')
      ev_discharge_pcm.setCallingPoint('BeginTimestepBeforePredictor')
      ev_discharge_pcm.addProgram(ev_discharge_program)
    end
  end
end
