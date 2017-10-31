#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessHeatingSetpoints < OpenStudio::Measure::ModelMeasure

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Heating Setpoints and Schedules"
  end
  
  def description
    return "This measure creates the heating season schedules and the heating setpoint schedules.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "This measure creates #{Constants.ObjectNameHeatingSeason} ruleset objects. Schedule values are either user-defined or populated based on information contained in the EPW file. This measure also creates #{Constants.ObjectNameHeatingSetpoint} ruleset objects. Schedule values are populated based on information input by the user as well as contained in the #{Constants.ObjectNameHeatingSeason}. The heating setpoint schedules are added to the living zone's thermostat."
  end     
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

   #Make a string argument for 24 weekday heating set point values
    htg_wkdy = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_setpoint", true)
    htg_wkdy.setDisplayName("Weekday Setpoint")
    htg_wkdy.setDescription("Specify a single heating setpoint or a 24-hour comma-separated heating schedule for the weekdays.")
    htg_wkdy.setUnits("degrees F")
    htg_wkdy.setDefaultValue("71")
    args << htg_wkdy

    #Make a string argument for 24 weekend heating set point values
    htg_wked = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_setpoint", true)
    htg_wked.setDisplayName("Weekend Setpoint")
    htg_wked.setDescription("Specify a single heating setpoint or a 24-hour comma-separated heating schedule for the weekend.")
    htg_wked.setUnits("degrees F")
    htg_wked.setDefaultValue("71")
    args << htg_wked

    #make a bool argument for using hsp season or not
    arg = OpenStudio::Measure::OSArgument::makeBoolArgument("use_auto_season", true)
    arg.setDisplayName("Use Auto Heating Season")
    arg.setDescription("Specifies whether to automatically define the heating season based on the weather file. User-defined heating season start/end months will be ignored if this is selected")
    arg.setDefaultValue(false)
    args << arg
    
    #make a choice argument for months of the year
    month_display_names = OpenStudio::StringVector.new
    month_display_names << "Jan"
    month_display_names << "Feb"
    month_display_names << "Mar"
    month_display_names << "Apr"
    month_display_names << "May"
    month_display_names << "Jun"
    month_display_names << "Jul"
    month_display_names << "Aug"
    month_display_names << "Sep"
    month_display_names << "Oct"
    month_display_names << "Nov"
    month_display_names << "Dec"
    
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("season_start_month", month_display_names, false)
    arg.setDisplayName("Heating Season Start Month")
    arg.setDescription("Start month of the heating season.")
    arg.setDefaultValue("Jan")
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument("season_end_month", month_display_names, false)
    arg.setDisplayName("Heating Season End Month")
    arg.setDescription("End month of the heating season.")
    arg.setDefaultValue("Dec")
    args << arg
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    htg_wkdy = runner.getStringArgumentValue("weekday_setpoint",user_arguments)
    htg_wked = runner.getStringArgumentValue("weekend_setpoint",user_arguments)
    use_auto_season = runner.getBoolArgumentValue("use_auto_season",user_arguments)
    htg_start_month = runner.getOptionalStringArgumentValue("season_start_month",user_arguments)
    htg_end_month = runner.getOptionalStringArgumentValue("season_end_month",user_arguments)    
    
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
      return false
    end

    # Get heating season
    if use_auto_season
      heating_season, cooling_season = HVAC.calc_heating_and_cooling_seasons(model, weather, runner)
    else
      month_map = {"Jan"=>1, "Feb"=>2, "Mar"=>3, "Apr"=>4, "May"=>5, "Jun"=>6, "Jul"=>7, "Aug"=>8, "Sep"=>9, "Oct"=>10, "Nov"=>11, "Dec"=>12}
      if htg_start_month.is_initialized
        htg_start_month = month_map[htg_start_month.get]
      end
      if htg_end_month.is_initialized
        htg_end_month = month_map[htg_end_month.get]
      end
      if htg_start_month <= htg_end_month
        heating_season = Array.new(htg_start_month-1, 0) + Array.new(htg_end_month-htg_start_month+1, 1) + Array.new(12-htg_end_month, 0)
      elsif htg_start_month > htg_end_month
        heating_season = Array.new(htg_end_month, 1) + Array.new(htg_start_month-htg_end_month-1, 0) + Array.new(12-htg_start_month+1, 1)
      end
    end
    if heating_season.nil?
      return false
    end
    
    # Remove existing heating season schedule
    model.getScheduleRulesets.each do |sch|
      next unless sch.name.to_s == Constants.ObjectNameHeatingSeason
      sch.remove
    end
    heatingseasonschedule = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameHeatingSeason, Array.new(24, 1), Array.new(24, 1), heating_season, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)
        
    unless heatingseasonschedule.validated?
      return false
    end

    # assign the availability schedules to the equipment objects
    has_htg_equip = false
    model.getThermalZones.each do |thermal_zone|
      heating_equipment = HVAC.existing_heating_equipment(model, runner, thermal_zone)
      heating_equipment.each do |htg_equip|
        has_htg_equip = true
        htg_obj = nil
        supp_htg_obj = nil
        if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          if htg_equip.heatingCoil.is_initialized
            htg_obj = HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil.get)
          end
          if htg_equip.supplementalHeatingCoil.is_initialized
            supp_htg_obj = HVAC.get_coil_from_hvac_component(htg_equip.supplementalHeatingCoil.get)
          end
        elsif htg_equip.is_a? OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow
          htg_obj = HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil)
        elsif htg_equip.to_ZoneHVACComponent.is_initialized
          htg_obj = htg_equip
        else
          runner.registerError("Unexpected heating system: '#{htg_equip.name}'.")
          return false
        end
        unless htg_obj.nil? or htg_obj.to_CoilHeatingWaterToAirHeatPumpEquationFit.is_initialized
          htg_obj.setAvailabilitySchedule(heatingseasonschedule.schedule)
          runner.registerInfo("Added availability schedule to #{htg_obj.name}.")
        end
        unless supp_htg_obj.nil?
          supp_htg_obj.setAvailabilitySchedule(heatingseasonschedule.schedule)
          runner.registerInfo("Added availability schedule to #{supp_htg_obj.name}.")
        end
      end
    end
    
    # Convert to 24-values if a single value entered
    if not htg_wkdy.include?(",")
      htg_wkdy = Array.new(24, htg_wkdy).join(", ")
    end
    if not htg_wked.include?(",")
      htg_wked = Array.new(24, htg_wked).join(", ")
    end

    htg_wkdy = htg_wkdy.split(",").map {|i| OpenStudio::convert(i.to_f,"F","C").get}
    htg_wked = htg_wked.split(",").map {|i| OpenStudio::convert(i.to_f,"F","C").get}   
    
    finished_zones = []
    model.getThermalZones.each do |thermal_zone|
      if Geometry.zone_is_finished(thermal_zone)
        finished_zones << thermal_zone
      end
    end
    
    # Remove existing heating setpoint schedule
    model.getScheduleRulesets.each do |sch|
      next unless sch.name.to_s == Constants.ObjectNameHeatingSetpoint
      sch.remove
    end
    
    # Make the setpoint schedules
    heatingsetpoint = nil
    coolingsetpoint = nil
    finished_zones.each do |finished_zone|
    
      thermostatsetpointdualsetpoint = finished_zone.thermostatSetpointDualSetpoint
      if thermostatsetpointdualsetpoint.is_initialized
      
        thermostatsetpointdualsetpoint = thermostatsetpointdualsetpoint.get
        runner.registerInfo("Found existing thermostat #{thermostatsetpointdualsetpoint.name} for #{finished_zone.name}.")
        
        clg_wkdy = Array.new(24, Constants.NoCoolingSetpoint)
        clg_wked = Array.new(24, Constants.NoCoolingSetpoint)
        cooling_season = Array.new(12, 0.0)
        thermostatsetpointdualsetpoint.coolingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
          if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
            rule.daySchedule.values.each_with_index do |value, hour|
              if value < clg_wkdy[hour]
                clg_wkdy[hour] = value
              end
            end
          end
          if rule.applySaturday and rule.applySunday
            rule.daySchedule.values.each_with_index do |value, hour|
              if value < clg_wked[hour]
                clg_wked[hour] = value
              end
              if value < 50
                cooling_season[rule.startDate.get.monthOfYear.value-1] = 1.0
              end
            end
          end
        end
        
        htg_wkdy_monthly = []
        htg_wked_monthly = []
        clg_wkdy_monthly = []
        clg_wked_monthly = []
        (0..11).to_a.each do |i|        
          if cooling_season[i] == 1 and heating_season[i] == 1
            htg_wkdy_monthly << htg_wkdy.zip(clg_wkdy).map {|h, c| c < h ? (h + c) / 2.0 : h}
            htg_wked_monthly << htg_wked.zip(clg_wked).map {|h, c| c < h ? (h + c) / 2.0 : h}
            clg_wkdy_monthly << htg_wkdy.zip(clg_wkdy).map {|h, c| c < h ? (h + c) / 2.0 : c}
            clg_wked_monthly << htg_wked.zip(clg_wked).map {|h, c| c < h ? (h + c) / 2.0 : c}
          elsif heating_season[i] == 1
            htg_wkdy_monthly << htg_wkdy
            htg_wked_monthly << htg_wked
            clg_wkdy_monthly << Array.new(24, Constants.NoCoolingSetpoint)
            clg_wked_monthly << Array.new(24, Constants.NoCoolingSetpoint)
          else
            htg_wkdy_monthly << Array.new(24, Constants.NoHeatingSetpoint)
            htg_wked_monthly << Array.new(24, Constants.NoHeatingSetpoint)
            clg_wkdy_monthly << clg_wkdy
            clg_wked_monthly << clg_wked
          end          
        end
        
        model.getScheduleRulesets.each do |sch|
          next unless sch.name.to_s == Constants.ObjectNameCoolingSetpoint
          sch.remove
        end
        
        heatingsetpoint = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameHeatingSetpoint, htg_wkdy_monthly, htg_wked_monthly, normalize_values=false)
        coolingsetpoint = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameCoolingSetpoint, clg_wkdy_monthly, clg_wked_monthly, normalize_values=false)

        unless heatingsetpoint.validated? and coolingsetpoint.validated?
          return false
        end
        
      else
        
        htg_monthly_sch = Array.new(12, 1)
        for m in 1..12
          if heating_season[m-1] == 1
            htg_monthly_sch[m-1] = 1
          else
            htg_monthly_sch[m-1] = Constants.NoHeatingSetpoint
          end
        end        
        clg_monthly_sch = Array.new(12, 1)
        for m in 1..12
          clg_monthly_sch[m-1] = Constants.NoCoolingSetpoint
        end
        
        heatingsetpoint = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameHeatingSetpoint, htg_wkdy, htg_wked, htg_monthly_sch, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)
        coolingsetpoint = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameCoolingSetpoint, Array.new(24, 1), Array.new(24, 1), clg_monthly_sch, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)

        unless heatingsetpoint.validated?
          return false
        end             
      
      end
      break # assume all finished zones have the same schedules
      
    end    
    
    # Set the setpoint schedules
    finished_zones.each do |finished_zone|
    
      thermostatsetpointdualsetpoint = finished_zone.thermostatSetpointDualSetpoint
      if thermostatsetpointdualsetpoint.is_initialized
        
        thermostatsetpointdualsetpoint = thermostatsetpointdualsetpoint.get
        thermostatsetpointdualsetpoint.setHeatingSetpointTemperatureSchedule(heatingsetpoint.schedule)
        thermostatsetpointdualsetpoint.setCoolingSetpointTemperatureSchedule(coolingsetpoint.schedule)
        
      else
        
        thermostatsetpointdualsetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
        thermostatsetpointdualsetpoint.setName("#{finished_zone.name} temperature setpoint")
        runner.registerInfo("Created new thermostat #{thermostatsetpointdualsetpoint.name} for #{finished_zone.name}.")
        thermostatsetpointdualsetpoint.setHeatingSetpointTemperatureSchedule(heatingsetpoint.schedule)
        thermostatsetpointdualsetpoint.setCoolingSetpointTemperatureSchedule(coolingsetpoint.schedule)
        finished_zone.setThermostatSetpointDualSetpoint(thermostatsetpointdualsetpoint)        
        runner.registerInfo("Set a dummy cooling setpoint schedule for #{thermostatsetpointdualsetpoint.name}.")              
      
      end
      
      runner.registerInfo("Set the heating setpoint schedule for #{thermostatsetpointdualsetpoint.name}.")

    end

    model.getScheduleDays.each do |obj| # remove orphaned summer and winter design day schedules
      next if obj.directUseCount > 0
      obj.remove
    end
    
    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessHeatingSetpoints.new.registerWithApplication