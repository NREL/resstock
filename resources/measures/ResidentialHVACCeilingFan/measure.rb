# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/util"

# start the measure
class ProcessCeilingFan < OpenStudio::Measure::ModelMeasure

  class Unit
    def initialize
    end    
    attr_accessor(:living_zone, :finished_basement_zone, :above_grade_finished_floor_area, :cooling_setpoint_min, :num_bedrooms, :num_bathrooms, :finished_floor_area)
  end
  
  class Schedules
    def initialize
    end
    attr_accessor(:CeilingFan, :CeilingFansMaster)
  end

  # human readable name
  def name
    return "Set Residential Ceiling Fan"
  end

  # human readable description
  def description
    return "Adds (or replaces) residential ceiling fan(s) and schedule in all finished spaces. For multifamily buildings, the ceiling fan(s) can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Since there is no Ceiling Fan object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is residential ceiling fan. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a string argument for coverage
    coverage = OpenStudio::Measure::OSArgument::makeStringArgument("coverage", true)
    coverage.setDisplayName("Coverage")
    coverage.setUnits("frac")
    coverage.setDescription("Fraction of house conditioned by fans where # fans = (above-grade finished floor area)/(% coverage)/300.")
    coverage.setDefaultValue("NA")
    args << coverage

    #make a string argument for specified number
    specified_num = OpenStudio::Measure::OSArgument::makeStringArgument("specified_num", true)
    specified_num.setDisplayName("Specified Number")
    specified_num.setUnits("#/unit")
    specified_num.setDescription("Total number of fans.")
    specified_num.setDefaultValue("1")
    args << specified_num
    
    #make a double argument for power
    power = OpenStudio::Measure::OSArgument::makeDoubleArgument("power", true)
    power.setDisplayName("Power")
    power.setUnits("W")
    power.setDescription("Power consumption per fan assuming it runs at medium speed.")
    power.setDefaultValue(45.0)
    args << power
    
    #make choice arguments for control
    control_names = OpenStudio::StringVector.new
    control_names << Constants.CeilingFanControlTypical
    control_names << Constants.CeilingFanControlSmart
    control = OpenStudio::Measure::OSArgument::makeChoiceArgument("control", control_names, true)
    control.setDisplayName("Control")
    control.setDescription("'typical' indicates half of the fans will be on whenever the interior temperature is above the cooling setpoint; 'smart' indicates 50% of the energy consumption of 'typical.'")
    control.setDefaultValue(Constants.CeilingFanControlTypical)
    args << control 
    
    #make a bool argument for using benchmark energy
    use_benchmark_energy = OpenStudio::Measure::OSArgument::makeBoolArgument("use_benchmark_energy", true)
    use_benchmark_energy.setDisplayName("Use Benchmark Energy")
    use_benchmark_energy.setDescription("Use the energy value specified in the BA Benchmark: 77.3 + 0.0403 x FFA kWh/yr, where FFA is Finished Floor Area.")
    use_benchmark_energy.setDefaultValue(true)
    args << use_benchmark_energy
    
    #make a double argument for BA Benchamrk multiplier
    mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult")
    mult.setDisplayName("Building America Benchmark Multiplier")
    mult.setDefaultValue(1)
    mult.setDescription("A multiplier on the national average energy use. Only applies if 'Use Benchmark Energy' is set to True.")
    args << mult
    
    #make a double argument for cooling setpoint offset
    cooling_setpoint_offset = OpenStudio::Measure::OSArgument::makeDoubleArgument("cooling_setpoint_offset", true)
    cooling_setpoint_offset.setDisplayName("Cooling Setpoint Offset")
    cooling_setpoint_offset.setUnits("degrees F")
    cooling_setpoint_offset.setDescription("Increase in cooling set point due to fan usage.")
    cooling_setpoint_offset.setDefaultValue(0)
    args << cooling_setpoint_offset    
    
    #Make a string argument for 24 weekday schedule values
    weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_sch", true)
    weekday_sch.setDisplayName("Weekday schedule")
    weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    weekday_sch.setDefaultValue("0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05")
    args << weekday_sch
      
    #Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch", true)
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    weekend_sch.setDefaultValue("0.04, 0.037, 0.037, 0.036, 0.033, 0.036, 0.043, 0.047, 0.034, 0.023, 0.024, 0.025, 0.024, 0.028, 0.031, 0.032, 0.039, 0.053, 0.063, 0.067, 0.071, 0.069, 0.059, 0.05")
    args << weekend_sch

    #Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch", true)
    monthly_sch.setDisplayName("Month schedule")
    monthly_sch.setDescription("Specify the 12-month schedule.")
    monthly_sch.setDefaultValue("1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248")
    args << monthly_sch    
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    coverage = runner.getStringArgumentValue("coverage",user_arguments)
    unless coverage == "NA"
      coverage = coverage.to_f
    else
      coverage = nil
    end
    specified_num = runner.getStringArgumentValue("specified_num",user_arguments)
    unless specified_num == "NA"
      specified_num = specified_num.to_f
    else
      specified_num = nil
    end    
    power = runner.getDoubleArgumentValue("power",user_arguments)
    control = runner.getStringArgumentValue("control",user_arguments)
    use_benchmark_energy = runner.getBoolArgumentValue("use_benchmark_energy",user_arguments)
    cooling_setpoint_offset = runner.getDoubleArgumentValue("cooling_setpoint_offset",user_arguments)
    mult = runner.getDoubleArgumentValue("mult",user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)    
    
    # check for valid inputs
    if mult < 0
      runner.registerError("Multiplier must be greater than or equal to 0.")
      return false
    end    
    
    if use_benchmark_energy
      coverage = nil
      specified_num = nil
      power = nil
      control = nil
    end
    
    # get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end
    
    ["Schedule Value", "Zone Mean Air Temperature"].each do |output_var_name|
      unless model.getOutputVariables.any? {|existing_output_var| existing_output_var.name.to_s == output_var_name} 
        output_var = OpenStudio::Model::OutputVariable.new(output_var_name, model)
        output_var.setName(output_var_name)
      end
    end

    schedule_value_output_var = nil
    zone_mean_air_temp_output_var = nil
    model.getOutputVariables.each do |output_var|
      if output_var.name.to_s == "Schedule Value"
        schedule_value_output_var = output_var
      elsif output_var.name.to_s == "Zone Mean Air Temperature"
        zone_mean_air_temp_output_var = output_var
      end
    end
    
    sch = nil
    units.each do |building_unit|
    
      obj_name = Constants.ObjectNameCeilingFan(building_unit.name.to_s)
    
      # Remove existing ceiling fan
      model.getScheduleRulesets.each do |schedule|
        next unless schedule.name.to_s == obj_name + " schedule"
        schedule.remove
      end
      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless sensor.name.to_s == "#{obj_name} sched val sensor".gsub(" ","_").gsub("|","_")
        sensor.remove
      end
      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless sensor.name.to_s == "#{obj_name} tin sensor".gsub(" ","_").gsub("|","_")
        sensor.remove
      end
      model.getEnergyManagementSystemActuators.each do |actuator|
        next unless actuator.name.to_s == "#{obj_name} sched override".gsub(" ","_").gsub("|","_")
        actuator.remove
      end
      model.getEnergyManagementSystemPrograms.each do |program|
        next unless program.name.to_s == "#{obj_name} schedule program".gsub(" ","_")
        program.remove
      end      
      model.getEnergyManagementSystemProgramCallingManagers.each do |program_calling_manager|
        next unless program_calling_manager.name.to_s == obj_name + " program calling manager"
        program_calling_manager.remove
      end
    
      unit = Unit.new
      unit.num_bedrooms, unit.num_bathrooms = Geometry.get_unit_beds_baths(model, building_unit, runner)      
      if unit.num_bedrooms.nil? or unit.num_bathrooms.nil?
        return false
      end      
      unit.above_grade_finished_floor_area = Geometry.get_above_grade_finished_floor_area_from_spaces(building_unit.spaces, false, runner)
      unit.finished_floor_area = Geometry.get_finished_floor_area_from_spaces(building_unit.spaces, false, runner)

      schedules = Schedules.new
    
      # Determine geometry for spaces and zones that are unit specific
      Geometry.get_thermal_zones_from_spaces(building_unit.spaces).each do |thermal_zone|
        if Geometry.is_living(thermal_zone)
          unit.living_zone = thermal_zone
        elsif Geometry.is_finished_basement(thermal_zone)
          unit.finished_basement_zone = thermal_zone
        end
      end
          
      # Determine the number of ceiling fans
      ceiling_fan_num = 0
      if not coverage.nil?
        # User has chosen to specify the number of fans by indicating
        # % coverage, where it is assumed that 100% coverage requires 1 fan
        # per 300 square feet.
        ceiling_fan_num = get_ceiling_fan_number(unit.above_grade_finished_floor_area, coverage)
      elsif not specified_num.nil?
        ceiling_fan_num = specified_num
      else
        ceiling_fan_num = 0
      end
      
      # Adjust the power consumption based on the occupancy control.
      # The default assumption is that when the fans are "on" half of the
      # fans will be used. This is consistent with the results from an FSEC
      # survey (described in FSEC-PF-306-96) and approximates the reasonable
      # assumption that during the night the bedroom fans will be on and all
      # of the other fans will be off while during the day the reverse will
      # be true. "Smart" occupancy control indicates that fans are used more
      # sparingly; in other words, fans are frequently turned off when rooms
      # are vacant. To approximate this kind of control, the overall fan
      # power consumption is reduced by 50%.Note that although the idea here
      # is that in reality "smart" control means that fans will be run for
      # fewer hours, it is modeled as a reduction in power consumption.

      if control == Constants.CeilingFanControlSmart
        ceiling_fan_control_factor = 0.25
      else
        ceiling_fan_control_factor = 0.5
      end
        
      # Determine the power draw for the ceiling fans.
      # The power consumption depends on the number of fans, the "standard"
      # power consumption per fan, the fan efficiency, and the fan occupancy
      # control. Rather than specifying usage via a schedule, as for most
      # other electrical uses, the fans will be modeled as "on" with a
      # constant power consumption whenever the interior space temperature
      # exceeds the cooling setpoint and "off" at all other times (this
      # on/off behavior is accomplished in DOE2.bmi using EQUIP-PWR-FT - see
      # comments there). Note that there is also a fan schedule that accounts
      # for cooling setpoint setups (it is assumed that fans will always be
      # off during the setup period).
      
      if ceiling_fan_num > 0
        ceiling_fans_max_power = ceiling_fan_num * power * ceiling_fan_control_factor / OpenStudio::convert(1.0,"kW","W").get # kW
      else
        ceiling_fans_max_power = 0
      end
      
      # Determine ceiling fan schedule.
      # In addition to turning the fans off when the interior space
      # temperature falls below the cooling setpoint (handled in DOE2.bmi by
      # EQUIP-PWR-FT), the fans should be turned off during any setup of the
      # cooling setpoint (based on the assumption that the occupants leave
      # the house at those times). Therefore the fan schedule specifies zero
      # power during the setup period and full power outside of the setup
      # period. Determine the lowest value of all of the hourly cooling setpoints.
      
      # Get cooling setpoints
      clg_wkdy = nil
      clg_wked = nil
      thermostatsetpointdualsetpoint = unit.living_zone.thermostatSetpointDualSetpoint
      if thermostatsetpointdualsetpoint.is_initialized
        thermostatsetpointdualsetpoint.get.coolingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
          coolingSetpoint = Array.new(24, Constants.NoCoolingSetpoint)
          rule.daySchedule.values.each_with_index do |value, hour|
            if value < coolingSetpoint[hour]
              coolingSetpoint[hour] = OpenStudio::convert(value,"C","F").get + cooling_setpoint_offset
            end
          end
          # weekday
          if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
            unless rule.daySchedule.values.all? {|x| x == Constants.NoCoolingSetpoint}
              rule.daySchedule.clearValues
              coolingSetpoint.each_with_index do |value, hour|
                rule.daySchedule.addValue(OpenStudio::Time.new(0,hour+1,0,0), OpenStudio::convert(value,"F","C").get)
              end
              clg_wkdy = coolingSetpoint
            end            
          end
          # weekend
          if rule.applySaturday and rule.applySunday
            unless rule.daySchedule.values.all? {|x| x == Constants.NoCoolingSetpoint}          
              rule.daySchedule.clearValues
              coolingSetpoint.each_with_index do |value, hour|
                rule.daySchedule.addValue(OpenStudio::Time.new(0,hour+1,0,0), OpenStudio::convert(value,"F","C").get)
              end
              clg_wked = coolingSetpoint
            end            
          end
        end
      end    

      if clg_wkdy.nil? and clg_wked.nil?
        runner.registerWarning("No cooling equipment found. Assuming #{Constants.DefaultCoolingSetpoint} F for ceiling fan operation.")
        clg_wkdy = Array.new(24, Constants.DefaultCoolingSetpoint)
        clg_wked = Array.new(24, Constants.DefaultCoolingSetpoint)
      end
      
      unit.cooling_setpoint_min = (clg_wkdy + clg_wked).min
      
      ceiling_fans_hourly_weekday = []
      ceiling_fans_hourly_weekend = []
    
      (0..23).to_a.each do |hour|
        if clg_wkdy[hour] > unit.cooling_setpoint_min
          ceiling_fans_hourly_weekday << 0
        else
          ceiling_fans_hourly_weekday << 1
        end
        if clg_wked[hour] > unit.cooling_setpoint_min
          ceiling_fans_hourly_weekend << 0
        else
          ceiling_fans_hourly_weekend << 1
        end      
      end

      schedules.CeilingFan = MonthWeekdayWeekendSchedule.new(model, runner, obj_name + " schedule", ceiling_fans_hourly_weekday, ceiling_fans_hourly_weekend, Array.new(12, 1), mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)      
      
      unless schedules.CeilingFan.validated?
        return false
      end

      schedule_type_limits = OpenStudio::Model::ScheduleTypeLimits.new(model)
      schedule_type_limits.setName("OnOff")
      schedule_type_limits.setLowerLimitValue(0)
      schedule_type_limits.setUpperLimitValue(1)
      schedule_type_limits.setNumericType("Discrete")
      
      schedules.CeilingFansMaster = OpenStudio::Model::ScheduleConstant.new(model)
      schedules.CeilingFansMaster.setName(obj_name + " master")
      schedules.CeilingFansMaster.setScheduleTypeLimits(schedule_type_limits)
      schedules.CeilingFansMaster.setValue(1)
      
      # Ceiling Fans
      # As described in more detail in the schedules section, ceiling fans are controlled by two schedules, CeilingFan and CeilingFansMaster.
      # The program CeilingFanScheduleProgram checks to see if a cooling setpoint setup is in effect (by checking the sensor CeilingFan_sch) and
      # it checks the indoor temperature to see if it is less than the normal cooling setpoint. In either case, it turns the fans off.
      # Otherwise it turns the fans on.
      
      unit.living_zone.spaces.each do |space|
        space.electricEquipment.each do |equip|
          next unless equip.name.to_s == obj_name + " non benchmark equip"
          equip.electricEquipmentDefinition.remove
        end
      end
      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName(obj_name + " non benchmark equip")
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName(equip_def.name.to_s)
      equip.setSpace(unit.living_zone.spaces[0])
      equip_def.setDesignLevel(OpenStudio::convert(ceiling_fans_max_power,"kW","W").get)
      equip_def.setFractionRadiant(0.558)
      equip_def.setFractionLatent(0)
      equip_def.setFractionLost(0.07)
      equip.setSchedule(schedules.CeilingFansMaster)
      
      # Sensor that reports the value of the schedule CeilingFan (0 if cooling setpoint setup is in effect, 1 otherwise).
      sched_val_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      sched_val_sensor.setName("#{obj_name} sched val sensor".gsub("|","_"))
      sched_val_sensor.setKeyName(obj_name + " schedule")

      tin_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_mean_air_temp_output_var)
      tin_sensor.setName("#{obj_name} tin sensor".gsub("|","_"))
      tin_sensor.setKeyName(unit.living_zone.name.to_s)
      
      # Actuator that overrides the master ceiling fan schedule.
      sched_override_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(schedules.CeilingFansMaster, "Schedule:Constant", "Schedule Value")
      sched_override_actuator.setName("#{obj_name} sched override".gsub("|","_"))
      
      # Program that turns the ceiling fans off in the situations described above.
      program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      program.setName(obj_name + " schedule program")
      program.addLine("If #{sched_val_sensor.name} == 0")
      program.addLine("Set #{sched_override_actuator.name} = 0")
      # Subtract 0.1 from cooling setpoint to avoid fans cycling on and off with minor temperature variations.
      program.addLine("ElseIf #{tin_sensor.name} < #{OpenStudio::convert(unit.cooling_setpoint_min-0.1-32.0,"R","K").get.round(3)}")
      program.addLine("Set #{sched_override_actuator.name} = 0")
      program.addLine("Else")
      program.addLine("Set #{sched_override_actuator.name} = 1")
      program.addLine("EndIf")
      
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName(obj_name + " program calling manager")
      program_calling_manager.setCallingPoint("BeginTimestepBeforePredictor")
      program_calling_manager.addProgram(program)
      
      mel_ann_no_ceiling_fan = (1108.1 + 180.2 * unit.num_bedrooms + 0.2785 * unit.finished_floor_area) * mult
      mel_ann_with_ceiling_fan = (1185.4 + 180.2 * unit.num_bedrooms + 0.3188 * unit.finished_floor_area) * mult         
      mel_ann = mel_ann_with_ceiling_fan - mel_ann_no_ceiling_fan      
    
      building_unit.spaces.each do |space|
        next if Geometry.space_is_unfinished(space)
        
        space_obj_name = "#{obj_name} benchmark|#{space.name.to_s}"          

        space.electricEquipment.each do |equip|
          next unless equip.name.to_s == space_obj_name
          equip.electricEquipmentDefinition.remove
        end
        model.getScheduleRulesets.each do |schedule|
          next unless schedule.name.to_s == space_obj_name + " schedule"
          schedule.remove
        end
          
        if mel_ann > 0 and use_benchmark_energy
          
          if sch.nil?
            sch = MonthWeekdayWeekendSchedule.new(model, runner, space_obj_name + " schedule", weekday_sch, weekend_sch, monthly_sch)
            if not sch.validated?
              return false
            end
          end
          
          space_mel_ann = mel_ann * OpenStudio.convert(space.floorArea,"m^2","ft^2").get / unit.finished_floor_area
          space_design_level = sch.calcDesignLevelFromDailykWh(space_mel_ann / 365.0)

          mel_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
          mel = OpenStudio::Model::ElectricEquipment.new(mel_def)
          mel.setName(space_obj_name)
          mel.setEndUseSubcategory(obj_name)
          mel.setSpace(space)
          mel_def.setName(space_obj_name)
          mel_def.setDesignLevel(space_design_level)
          mel_def.setFractionRadiant(0.558)
          mel_def.setFractionLatent(0.0)
          mel_def.setFractionLost(0.07)
          mel.setSchedule(sch.schedule)
                      
        end # benchmark
        
      end # unit spaces

    end # units
    
    return true

  end
  
  def get_ceiling_fan_number(above_grade_finished_floor_area, coverage)
    return (above_grade_finished_floor_area * coverage / 300.0).round(1)
  end 
  
end

# register the measure to be used by the application
ProcessCeilingFan.new.registerWithApplication
