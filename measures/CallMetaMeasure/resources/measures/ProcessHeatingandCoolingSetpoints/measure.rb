#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ProcessHeatingandCoolingSetpoints < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Heating/Cooling Setpoints and Schedules"
  end
  
  def description
    return "This measure creates the heating season and cooling season schedules based on weather data, and the heating setpoint and cooling setpoint schedules."
  end
  
  def modeler_description
    return "This measure creates HeatingSeasonSchedule and CoolingSeasonSchedule ruleset objects. Schedule values are populated based on information contained in the EPW file. This measure also creates HeatingSetPoint and CoolingSetPoint ruleset objects. Schedule values are populated based on information input by the user as well as contained in the HeatingSeasonSchedule and CoolingSeasonSchedule. The heating and cooling setpoint schedules are added to the living zone's thermostat."
  end     
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for constant heating setpoint
    userdefinedhsp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhsp", false)
    userdefinedhsp.setDisplayName("Heating Set Point: Constant Setpoint")
    userdefinedhsp.setUnits("degrees F")
    userdefinedhsp.setDescription("Constant heating setpoint for every hour.")
    userdefinedhsp.setDefaultValue(71.0)
    args << userdefinedhsp

    #make a double argument for constant cooling setpoint
    userdefinedcsp = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedcsp", false)
    userdefinedcsp.setDisplayName("Cooling Set Point: Constant Setpoint")
    userdefinedcsp.setUnits("degrees F")
    userdefinedcsp.setDescription("Constant cooling setpoint for every hour.")
    userdefinedcsp.setDefaultValue(76.0)
    args << userdefinedcsp

    #make a bool argument for whether the house has heating equipment
    selectedheating = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedheating", false)
    selectedheating.setDisplayName("Has Heating Equipment")
    selectedheating.setDescription("Indicates whether the house has heating equipment.")
    selectedheating.setDefaultValue(true)
    args << selectedheating

    #make a bool argument for whether the house has cooling equipment
    selectedcooling = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedcooling", false)
    selectedcooling.setDisplayName("Has Cooling Equipment")
    selectedcooling.setDescription("Indicates whether the house has cooling equipment.")
    selectedcooling.setDefaultValue(true)
    args << selectedcooling	
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    weather = WeatherProcess.new(model,runner)
    if weather.error?
      return false
    end
    
    heating_season, cooling_season = HelperMethods.calc_heating_and_cooling_seasons(weather)

    day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

    sched_type = OpenStudio::Model::ScheduleTypeLimits.new(model)
    sched_type.setName("ON/OFF")
    sched_type.setLowerLimitValue(0)
    sched_type.setUpperLimitValue(1)
    sched_type.setNumericType("Discrete")

    # HeatingSeasonSchedule
    htgssn_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
    htgssn_ruleset.setName("HeatingSeasonSchedule")

    htgssn_ruleset.setScheduleTypeLimits(sched_type)

    htgssn_rule_days = []
    for m in 1..12
      date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
      date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
      htgssn_rule = OpenStudio::Model::ScheduleRule.new(htgssn_ruleset)
      htgssn_rule.setName("HeatingSeasonSchedule%02d" % m.to_s)
      htgssn_rule_day = htgssn_rule.daySchedule
      htgssn_rule_day.setName("HeatingSeasonSchedule%02dd" % m.to_s)
      for h in 1..24
        time = OpenStudio::Time.new(0,h,0,0)
        val = heating_season[m - 1]
        htgssn_rule_day.addValue(time,val)
      end
      htgssn_rule_days << htgssn_rule_day
      htgssn_rule.setApplySunday(true)
      htgssn_rule.setApplyMonday(true)
      htgssn_rule.setApplyTuesday(true)
      htgssn_rule.setApplyWednesday(true)
      htgssn_rule.setApplyThursday(true)
      htgssn_rule.setApplyFriday(true)
      htgssn_rule.setApplySaturday(true)
      htgssn_rule.setStartDate(date_s)
      htgssn_rule.setEndDate(date_e)
    end

    htgssn_sumDesSch = htgssn_rule_days[6]
    htgssn_winDesSch = htgssn_rule_days[1]
    htgssn_ruleset.setSummerDesignDaySchedule(htgssn_sumDesSch)
    htgssn_summer = htgssn_ruleset.summerDesignDaySchedule
    htgssn_summer.setName("HeatingSeasonScheduleSummer")
    htgssn_ruleset.setWinterDesignDaySchedule(htgssn_winDesSch)
    htgssn_winter = htgssn_ruleset.winterDesignDaySchedule
    htgssn_winter.setName("HeatingSeasonScheduleWinter")

    # CoolingSeasonSchedule
    clgssn_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
    clgssn_ruleset.setName("CoolingSeasonSchedule")

    clgssn_ruleset.setScheduleTypeLimits(sched_type)

    clgssn_rule_days = []
    for m in 1..12
      date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
      date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
      clgssn_rule = OpenStudio::Model::ScheduleRule.new(clgssn_ruleset)
      clgssn_rule.setName("CoolingSeasonSchedule%02d" % m.to_s)
      clgssn_rule_day = clgssn_rule.daySchedule
      clgssn_rule_day.setName("CoolingSeasonSchedule%02dd" % m.to_s)
      for h in 1..24
        time = OpenStudio::Time.new(0,h,0,0)
        val = cooling_season[m - 1]
        clgssn_rule_day.addValue(time,val)
      end
      clgssn_rule_days << clgssn_rule_day
      clgssn_rule.setApplySunday(true)
      clgssn_rule.setApplyMonday(true)
      clgssn_rule.setApplyTuesday(true)
      clgssn_rule.setApplyWednesday(true)
      clgssn_rule.setApplyThursday(true)
      clgssn_rule.setApplyFriday(true)
      clgssn_rule.setApplySaturday(true)
      clgssn_rule.setStartDate(date_s)
      clgssn_rule.setEndDate(date_e)
    end

    clgssn_sumDesSch = clgssn_rule_days[6]
    clgssn_winDesSch = clgssn_rule_days[1]
    clgssn_ruleset.setSummerDesignDaySchedule(clgssn_sumDesSch)
    clgssn_summer = clgssn_ruleset.summerDesignDaySchedule
    clgssn_summer.setName("CoolingSeasonScheduleSummer")
    clgssn_ruleset.setWinterDesignDaySchedule(clgssn_winDesSch)
    clgssn_winter = clgssn_ruleset.winterDesignDaySchedule
    clgssn_winter.setName("CoolingSeasonScheduleWinter")

    runner.registerInfo("Set the monthly HeatingSeasonSchedule as #{heating_season.join(", ")}")
    runner.registerInfo("Set the monthly CoolingSeasonSchedule as #{cooling_season.join(", ")}")

    # Setpoints
    heatingSetpointConstantSetpoint = runner.getDoubleArgumentValue("userdefinedhsp",user_arguments)
    coolingSetpointConstantSetpoint = runner.getDoubleArgumentValue("userdefinedcsp",user_arguments)

    # Equipment
    selectedheating = runner.getBoolArgumentValue("selectedheating",user_arguments)
    selectedcooling = runner.getBoolArgumentValue("selectedcooling",user_arguments)

    if not selectedheating
      heatingSetpointConstantSetpoint = -1000
      runner.registerWarning("House has no heating equipment; heating setpoint set to -1000 so there's no heating")
    end
    if not selectedcooling
      coolingSetpointConstantSetpoint = 1000
      runner.registerWarning("House has no cooling equipment; cooling setpoint set to 1000 so there's no cooling")
    end

    # get the heating and cooling season schedules
    heating_season = {}
    cooling_season = {}
    scheduleRulesets = model.getScheduleRulesets
    scheduleRulesets.each do |scheduleRuleset|
      if scheduleRuleset.name.to_s == "HeatingSeasonSchedule"
        scheduleRules = scheduleRuleset.scheduleRules
        scheduleRules.each do |scheduleRule|
          daySchedule = scheduleRule.daySchedule
          values = daySchedule.values
          heating_season[scheduleRule.name.to_s] = values[0]
        end
      elsif scheduleRuleset.name.to_s == "CoolingSeasonSchedule"
        scheduleRules = scheduleRuleset.scheduleRules
        scheduleRules.each do |scheduleRule|
          daySchedule = scheduleRule.daySchedule
          values = daySchedule.values
          cooling_season[scheduleRule.name.to_s] = values[0]
        end
      end
    end

    # Process the heating and cooling setpoints
    heatingSetpointSchedule, heatingSetpointWeekday, heatingSetpointWeekend, coolingSetpointSchedule, coolingSetpointWeekday, coolingSetpointWeekend, controlType = _processHeatingCoolingSetpoints(heatingSetpointConstantSetpoint, coolingSetpointConstantSetpoint, selectedheating, selectedcooling)

    finished_zones = []
    model.getThermalZones.each do |thermal_zone|
      if Geometry.zone_is_finished(thermal_zone)
        finished_zones << thermal_zone
      end
    end
    
    finished_zones.each do |finished_zone|
    
      thermostatsetpointdualsetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
      thermostatsetpointdualsetpoint.setName("Living Zone Temperature SP")

      day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
      day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

      heatingsetpoint = OpenStudio::Model::ScheduleRuleset.new(model)
      heatingsetpoint.setName("HeatingSetPoint")

      htgssn_rule_days = []
      for m in 1..12
        date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
        date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
        htgssn_rule = OpenStudio::Model::ScheduleRule.new(heatingsetpoint)
        htgssn_rule.setName("HeatingSetPointSchedule%02d" % m.to_s)
        htgssn_rule_day = htgssn_rule.daySchedule
        htgssn_rule_day.setName("HeatingSetPointSchedule%02dd" % m.to_s)
        for h in 1..24
          time = OpenStudio::Time.new(0,h,0,0)
          if heating_season["HeatingSeasonSchedule%02d" % m.to_s] == 1.0
            val = OpenStudio::convert(heatingSetpointWeekday[h - 1],"F","C").get
          else
            val = -1000
          end
          htgssn_rule_day.addValue(time,val)
        end
        htgssn_rule_days << htgssn_rule_day
        htgssn_rule.setApplySunday(true)
        htgssn_rule.setApplyMonday(true)
        htgssn_rule.setApplyTuesday(true)
        htgssn_rule.setApplyWednesday(true)
        htgssn_rule.setApplyThursday(true)
        htgssn_rule.setApplyFriday(true)
        htgssn_rule.setApplySaturday(true)
        htgssn_rule.setStartDate(date_s)
        htgssn_rule.setEndDate(date_e)
      end

      htgssn_sumDesSch = htgssn_rule_days[6]
      htgssn_winDesSch = htgssn_rule_days[1]
      heatingsetpoint.setSummerDesignDaySchedule(htgssn_sumDesSch)
      htgssn_summer = heatingsetpoint.summerDesignDaySchedule
      htgssn_summer.setName("HeatingSetPointScheduleSummer")
      htgssn_summer.clearValues
      for h in 1..24
        time = OpenStudio::Time.new(0,h,0,0)
        val = OpenStudio::convert(heatingSetpointWeekday[h - 1],"F","C").get
        htgssn_summer.addValue(time,val)
      end
      heatingsetpoint.setWinterDesignDaySchedule(htgssn_winDesSch)
      htgssn_winter = heatingsetpoint.winterDesignDaySchedule
      htgssn_winter.setName("HeatingSetPointScheduleWinter")
      htgssn_winter.clearValues
      for h in 1..24
        time = OpenStudio::Time.new(0,h,0,0)
        val = OpenStudio::convert(heatingSetpointWeekday[h - 1],"F","C").get
        htgssn_winter.addValue(time,val)
      end

      coolingsetpoint = OpenStudio::Model::ScheduleRuleset.new(model)
      coolingsetpoint.setName("CoolingSetPoint")

      clgssn_rule_days = []
      for m in 1..12
        date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
        date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
        clgssn_rule = OpenStudio::Model::ScheduleRule.new(coolingsetpoint)
        clgssn_rule.setName("CoolingSetPointSchedule%02d" % m.to_s)
        clgssn_rule_day = clgssn_rule.daySchedule
        clgssn_rule_day.setName("CoolingSetPointSchedule%02dd" % m.to_s)
        for h in 1..24
          time = OpenStudio::Time.new(0,h,0,0)
          if cooling_season["CoolingSeasonSchedule%02d" % m.to_s] == 1.0
            val = OpenStudio::convert(coolingSetpointWeekday[h - 1],"F","C").get
          else
            val = 1000
          end
          clgssn_rule_day.addValue(time,val)
        end
        clgssn_rule_days << clgssn_rule_day
        clgssn_rule.setApplySunday(true)
        clgssn_rule.setApplyMonday(true)
        clgssn_rule.setApplyTuesday(true)
        clgssn_rule.setApplyWednesday(true)
        clgssn_rule.setApplyThursday(true)
        clgssn_rule.setApplyFriday(true)
        clgssn_rule.setApplySaturday(true)
        clgssn_rule.setStartDate(date_s)
        clgssn_rule.setEndDate(date_e)
      end

      clgssn_sumDesSch = clgssn_rule_days[6]
      clgssn_winDesSch = clgssn_rule_days[1]
      coolingsetpoint.setSummerDesignDaySchedule(clgssn_sumDesSch)
      clgssn_summer = coolingsetpoint.summerDesignDaySchedule
      clgssn_summer.setName("CoolingSetPointScheduleSummer")
      clgssn_summer.clearValues
      for h in 1..24
        time = OpenStudio::Time.new(0,h,0,0)
        val = OpenStudio::convert(coolingSetpointWeekday[h - 1],"F","C").get
        clgssn_summer.addValue(time,val)
      end
      coolingsetpoint.setWinterDesignDaySchedule(clgssn_winDesSch)
      clgssn_winter = coolingsetpoint.winterDesignDaySchedule
      clgssn_winter.setName("CoolingSetPointScheduleWinter")
      clgssn_winter.clearValues
      for h in 1..24
        time = OpenStudio::Time.new(0,h,0,0)
        val = OpenStudio::convert(coolingSetpointWeekday[h - 1],"F","C").get
        clgssn_winter.addValue(time,val)
      end

      if controlType == 4 or controlType == 2 or controlType == 1

        thermostatsetpointdualsetpoint.setHeatingSetpointTemperatureSchedule(heatingsetpoint)
        thermostatsetpointdualsetpoint.setCoolingSetpointTemperatureSchedule(coolingsetpoint)

      #   sched_type = heatingsetpoint.scheduleTypeLimits.get
      #   sched_type.setName("TEMPERATURE")
      #   sched_type.setLowerLimitValue(-60)
      #   sched_type.setUpperLimitValue(200)
      #   sched_type.setNumericType("Continuous")
      #   sched_type.resetUnitType
      #
      #   sched_type = coolingsetpoint.scheduleTypeLimits.get
      #   sched_type.setName("TEMPERATURE")
      #   sched_type.setLowerLimitValue(-60)
      #   sched_type.setUpperLimitValue(200)
      #   sched_type.setNumericType("Continuous")
      #   sched_type.resetUnitType
      #
      # elsif controlType == 2
      #
      #   thermostatsetpointdualsetpoint.setCoolingSetpointTemperatureSchedule(coolingsetpoint)
      #
      #   sched_type = coolingsetpoint.scheduleTypeLimits.get
      #   sched_type.setName("TEMPERATURE")
      #   sched_type.setLowerLimitValue(-60)
      #   sched_type.setUpperLimitValue(200)
      #   sched_type.setNumericType("Continuous")
      #   sched_type.resetUnitType
      #
      # elsif controlType == 1
      #
      #   thermostatsetpointdualsetpoint.setHeatingSetpointTemperatureSchedule(heatingsetpoint)
      #
      #   sched_type = heatingsetpoint.scheduleTypeLimits.get
      #   sched_type.setName("TEMPERATURE")
      #   sched_type.setLowerLimitValue(-60)
      #   sched_type.setUpperLimitValue(200)
      #   sched_type.setNumericType("Continuous")
      #   sched_type.resetUnitType

      end

      finished_zone.setThermostatSetpointDualSetpoint(thermostatsetpointdualsetpoint)

      if controlType == 4
        runner.registerInfo("Set the thermostat '#{finished_zone.thermostatSetpointDualSetpoint.get.name}' for thermal zone '#{finished_zone.name}' with heating setpoint schedule '#{heatingsetpoint.name}' and cooling setpoint schedule '#{coolingsetpoint.name}'")
      elsif controlType == 2
        runner.registerInfo("Set the thermostat '#{finished_zone.thermostatSetpointDualSetpoint.get.name}' for thermal zone '#{finished_zone.name}' with cooling setpoint schedule '#{coolingsetpoint.name}'")
      elsif controlType == 1
        runner.registerInfo("Set the thermostat '#{finished_zone.thermostatSetpointDualSetpoint.get.name}' for thermal zone '#{finished_zone.name}' with heating setpoint schedule '#{heatingsetpoint.name}'")
      end   
    
    end

    return true
 
  end #end the run method
  
  def _processHeatingCoolingSetpoints(heatingSetpointConstantSetpoint, coolingSetpointConstantSetpoint, selectedheating, selectedcooling)
    # Heating/Cooling Setpoints

    # Adjust cooling setpoints according to the offset the user has selected in conjunction with the user of ceiling fans.

    # Convert to Weekday/Weekend 24-hour lists
    if not heatingSetpointConstantSetpoint.nil?
      heatingSetpointSchedule = Array.new(48, heatingSetpointConstantSetpoint)
    end
    if not coolingSetpointConstantSetpoint.nil?
      coolingSetpointSchedule = Array.new(48, coolingSetpointConstantSetpoint)
    end

    coolingSetpointWeekday = coolingSetpointSchedule[0...24]
    if coolingSetpointSchedule.length > 24
      coolingSetpointWeekend = coolingSetpointSchedule[24...48]
    else
      coolingSetpointWeekend = coolingSetpointWeekday
    end
    heatingSetpointWeekday = heatingSetpointSchedule[0...24]
    if heatingSetpointSchedule.length > 24
      heatingSetpointWeekend = heatingSetpointSchedule[0...24]
    else
      heatingSetpointWeekend = heatingSetpointWeekday
    end

    # self.cooling_set_point.weekday_hourly_schedule_with_offset = \
    #             [x + self.ceiling_fans.CeilingFanCoolingSetptOffset for x in coolingSetpointWeekday]
    # self.cooling_set_point.weekend_hourly_schedule_with_offset = \
    #             [x + self.ceiling_fans.CeilingFanCoolingSetptOffset for x in coolingSetpointWeekend]

    # Thermostatic Control type schedule
    if selectedheating and selectedcooling
      controlType = 4 # Dual Setpoint (Heating and Cooling) with deadband
    elsif selectedcooling
      controlType = 2 # Single Cooling Setpoint
    elsif selectedheating
      controlType = 1 # Single Heating Setpoint
    else
      controlType = 0 # Uncontrolled
    end

    return heatingSetpointSchedule, heatingSetpointWeekday, heatingSetpointWeekend, coolingSetpointSchedule, coolingSetpointWeekday, coolingSetpointWeekend, controlType

  end
  
end #end the measure

#this allows the measure to be use by the application
ProcessHeatingandCoolingSetpoints.new.registerWithApplication