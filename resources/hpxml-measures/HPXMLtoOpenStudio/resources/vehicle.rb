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
    model.getElectricEquipments.sort.each do |ee|
      if ee.endUseSubcategory.start_with? Constants::ObjectTypeMiscElectricVehicleCharging
        runner.registerWarning('Electric vehicle was specified as a plug load and as a battery, vehicle charging will be modeled as a plug load.')
        return
      end
    end

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
      min_soc = ev_elcd.minimumStorageStateofChargeFraction
      discharging_schedule = ev_elcd.storageDischargePowerFractionSchedule.get
      charging_schedule = ev_elcd.storageChargePowerFractionSchedule.get

      discharge_power_act = Model.add_ems_actuator(
        name: 'battery_discharge_power_act',
        model_object: ev_elcd,
        comp_type_and_control: ['Electrical Storage', 'Power Draw Rate']
      )
      charge_power_act = Model.add_ems_actuator(
        name: 'battery_charge_power_act',
        model_object: ev_elcd,
        comp_type_and_control: ['Electrical Storage', 'Power Charge Rate']
      )

      temp_sensor = Model.add_ems_sensor(
        model,
        name: 'site_temp',
        output_var_or_meter_name: 'Site Outdoor Air Drybulb Temperature',
        key_name: 'Environment'
      )
      discharge_sch_sensor = Model.add_ems_sensor(
        model,
        name: 'discharge_sch_sensor',
        output_var_or_meter_name: 'Schedule Value',
        key_name: discharging_schedule.name.to_s
      )
      charge_sch_sensor = Model.add_ems_sensor(
        model,
        name: 'charge_sch_sensor',
        output_var_or_meter_name: 'Schedule Value',
        key_name: charging_schedule.name.to_s
      )
      soc_sensor = Model.add_ems_sensor(
        model,
        name: 'soc_sensor',
        output_var_or_meter_name: 'Electric Storage Charge Fraction',
        key_name: elcs.name.to_s
      )

      ev_discharge_program = Model.add_ems_program(
        model,
        name: 'ev_discharge_program'
      )
      ev_discharge_program.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeBatteryElectricVehicle)
      unmet_hr_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, 'unmet_driving_hours')
      unmet_hr_var.setName('unmet_driving_hours')
      unmet_hr_var.setTypeOfDataInVariable('Summed')
      unmet_hr_var.setUpdateFrequency('SystemTimestep')
      unmet_hr_var.setEMSProgramOrSubroutineName(ev_discharge_program)
      unmet_hr_var.setUnits('hr')
      unmet_hr_var.additionalProperties.setFeature('HPXML_ID', vehicle.id) # Used by reporting measure
      unmet_hr_var.additionalProperties.setFeature('ObjectType', Constants::ObjectTypeUnmetDrivingHours) # Used by reporting measure

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
      ev_discharge_program.addLine("      If #{soc_sensor.name} <= #{min_soc}")
      ev_discharge_program.addLine("        Set #{unmet_hr_var.name} = ZoneTimeStep")
      ev_discharge_program.addLine('      Else')
      ev_discharge_program.addLine("        Set #{unmet_hr_var.name} = 0")
      ev_discharge_program.addLine('      EndIf')
      ev_discharge_program.addLine("  ElseIf #{charge_sch_sensor.name} > 0.0")
      ev_discharge_program.addLine("    Set #{charge_power_act.name} = #{eff_charge_power} * #{charge_sch_sensor.name}")
      ev_discharge_program.addLine("    Set #{discharge_power_act.name} = 0")
      ev_discharge_program.addLine("    Set #{unmet_hr_var.name} = 0")
      ev_discharge_program.addLine('  Else')
      ev_discharge_program.addLine("    Set #{charge_power_act.name} = 0")
      ev_discharge_program.addLine("    Set #{discharge_power_act.name} = 0")
      ev_discharge_program.addLine("    Set #{unmet_hr_var.name} = 0")
      ev_discharge_program.addLine('  EndIf')

      Model.add_ems_program_calling_manager(
        model,
        name: 'ev_discharge_pcm',
        calling_point: 'BeginTimestepBeforePredictor',
        ems_programs: [ev_discharge_program]
      )
    end
  end
end
