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

#start the measure
class ProcessCoolingSetpoints < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Cooling Setpoints and Schedules"
  end
  
  def description
    return "This measure creates the cooling season schedules based on weather data, and the cooling setpoint schedules."
  end
  
  def modeler_description
    return "This measure creates #{Constants.ObjectNameCoolingSeason} ruleset objects. Schedule values are populated based on information contained in the EPW file. This measure also creates #{Constants.ObjectNameCoolingSetpoint} ruleset objects. Schedule values are populated based on information input by the user as well as contained in the #{Constants.ObjectNameCoolingSeason}. The cooling setpoint schedules are added to the living zone's thermostat."
  end     
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
  
   	#Make a string argument for 24 weekday cooling set point values
    clg_wkdy = OpenStudio::Ruleset::OSArgument::makeStringArgument("clg_wkdy", false)
    clg_wkdy.setDisplayName("Weekday Setpoint")
    clg_wkdy.setDescription("Specify a single cooling setpoint or a 24-hour cooling schedule for the weekdays.")
    clg_wkdy.setUnits("degrees F")
    clg_wkdy.setDefaultValue("76")
    args << clg_wkdy  
    
   	#Make a string argument for 24 weekend cooling set point values
    clg_wked = OpenStudio::Ruleset::OSArgument::makeStringArgument("clg_wked", false)
    clg_wked.setDisplayName("Weekend Setpoint")
    clg_wked.setDescription("Specify a single cooling setpoint or a 24-hour cooling schedule for the weekend.")
    clg_wked.setUnits("degrees F")
    clg_wked.setDefaultValue("76")
    args << clg_wked	
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    clg_wkdy = runner.getStringArgumentValue("clg_wkdy",user_arguments)
    clg_wked = runner.getStringArgumentValue("clg_wked",user_arguments)
    
    weather = WeatherProcess.new(model,runner)
    if weather.error?
      return false
    end
    
    heating_season, cooling_season = HelperMethods.calc_heating_and_cooling_seasons(model, weather, runner)
    if cooling_season.nil?
        return false
    end
    
    coolingseasonschedule = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameCoolingSeason, Array.new(24, 1), Array.new(24, 1), cooling_season, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)  
    
    unless coolingseasonschedule.validated?
      return false
    end

    # assign the availability schedules to the equipment objects
    clg_equip = false
    model.getThermalZones.each do |thermal_zone|
      clg_coil = HelperMethods.existing_cooling_equipment(model, runner, thermal_zone)
      unless clg_coil.nil?
        if clg_coil.is_a? OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner
          coolingseasonschedule.setSchedule(clg_coil)
          runner.registerInfo("Added availability schedule to #{clg_coil.name}.")
          clg_coil = clg_coil.coolingCoil.to_CoilCoolingDXSingleSpeed.get
        end
        coolingseasonschedule.setSchedule(clg_coil)
        runner.registerInfo("Added availability schedule to #{clg_coil.name}.")
        clg_equip = true
      end
    end
    
    unless clg_equip
      runner.registerWarning("No cooling equipment found.")
      return true
    end
    
    # Convert to 24-values if a single value entered
    if not clg_wkdy.include?(",")
      clg_wkdy = Array.new(24, clg_wkdy).join(", ")
    end
    if not clg_wked.include?(",")
      clg_wked = Array.new(24, clg_wked).join(", ")
    end

    clg_wkdy = clg_wkdy.split(",").map {|i| OpenStudio::convert(i.to_f,"F","C").get}
    clg_wked = clg_wked.split(",").map {|i| OpenStudio::convert(i.to_f,"F","C").get}  
    
    finished_zones = []
    model.getThermalZones.each do |thermal_zone|
      if Geometry.zone_is_finished(thermal_zone)
        finished_zones << thermal_zone
      end
    end
    
    finished_zones.each do |finished_zone|
    
      thermostatsetpointdualsetpoint = finished_zone.thermostatSetpointDualSetpoint
      if thermostatsetpointdualsetpoint.is_initialized
        
        thermostatsetpointdualsetpoint = thermostatsetpointdualsetpoint.get
        runner.registerInfo("Found existing thermostat #{thermostatsetpointdualsetpoint.name} for #{finished_zone.name}.")        
        
        htg_wkdy = Array.new(24, -10000)
        htg_wked = Array.new(24, -10000)
        heating_season = Array.new(12, 0.0)
        thermostatsetpointdualsetpoint.heatingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
          if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
            rule.daySchedule.values.each_with_index do |value, hour|
              if value > htg_wkdy[hour]
                htg_wkdy[hour] = value
              end
            end
          elsif rule.applySaturday and rule.applySunday
            rule.daySchedule.values.each_with_index do |value, hour|
              if value > htg_wked[hour]
                htg_wked[hour] = value
              end
              if value > -50
                heating_season[rule.startDate.get.monthOfYear.value-1] = 1.0
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
            clg_wkdy_monthly << Array.new(24, 10000)
            clg_wked_monthly << Array.new(24, 10000)
          elsif cooling_season[i] == 1
            htg_wkdy_monthly << Array.new(24, -10000)
            htg_wked_monthly << Array.new(24, -10000)
            clg_wkdy_monthly << clg_wkdy
            clg_wked_monthly << clg_wked
          end          
        end
        
        heatingsetpoint = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameHeatingSetpoint, htg_wkdy_monthly, htg_wked_monthly, normalize_values=false)
        coolingsetpoint = HourlyByMonthSchedule.new(model, runner, Constants.ObjectNameCoolingSetpoint, clg_wkdy_monthly, clg_wked_monthly, normalize_values=false)

        unless heatingsetpoint.validated? and coolingsetpoint.validated?
          return false
        end

        heatingsetpoint.setSchedule(thermostatsetpointdualsetpoint)
        coolingsetpoint.setSchedule(thermostatsetpointdualsetpoint)        
        
      else
        
        clg_monthly_sch = Array.new(12, 1)
        for m in 1..12
          if cooling_season[m-1] == 1
            clg_monthly_sch[m-1] = 1
          else
            clg_monthly_sch[m-1] = 10000
          end
        end        
        htg_monthly_sch = Array.new(12, 1)
        for m in 1..12
          htg_monthly_sch[m-1] = -10000
        end
        
        heatingsetpoint = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameHeatingSetpoint, Array.new(24, 1), Array.new(24, 1), htg_monthly_sch, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)
        coolingsetpoint = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameCoolingSetpoint, clg_wkdy, clg_wked, clg_monthly_sch, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)

        unless coolingsetpoint.validated?
          return false
        end        
        
        thermostatsetpointdualsetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
        thermostatsetpointdualsetpoint.setName("Living Zone Temperature SP")
        runner.registerInfo("Created new thermostat #{thermostatsetpointdualsetpoint.name} for #{finished_zone.name}.")
        coolingsetpoint.setSchedule(thermostatsetpointdualsetpoint)
        finished_zone.setThermostatSetpointDualSetpoint(thermostatsetpointdualsetpoint)
        heatingsetpoint.setSchedule(thermostatsetpointdualsetpoint)
        runner.registerInfo("Set a dummy heating setpoint schedule for #{thermostatsetpointdualsetpoint.name}.")              
      
      end
      
      runner.registerInfo("Set the cooling setpoint schedule for #{thermostatsetpointdualsetpoint.name}.")      

    end

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessCoolingSetpoints.new.registerWithApplication