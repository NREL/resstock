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
class ProcessHeatingSetpoints < OpenStudio::Ruleset::ModelUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Heating Setpoints and Schedules"
  end
  
  def description
    return "This measure creates the heating season schedules based on weather data, and the heating setpoint schedules."
  end
  
  def modeler_description
    return "This measure creates #{Constants.ObjectNameHeatingSeason} ruleset objects. Schedule values are populated based on information contained in the EPW file. This measure also creates #{Constants.ObjectNameHeatingSetpoint} ruleset objects. Schedule values are populated based on information input by the user as well as contained in the #{Constants.ObjectNameHeatingSeason}. The heating setpoint schedules are added to the living zone's thermostat."
  end     
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

   	#Make a string argument for 24 weekday heating set point values
    htg_wkdy = OpenStudio::Ruleset::OSArgument::makeStringArgument("htg_wkdy", false)
    htg_wkdy.setDisplayName("Weekday Setpoint")
    htg_wkdy.setDescription("Specify a single heating setpoint or a 24-hour heating schedule for the weekdays.")
    htg_wkdy.setUnits("degrees F")
    htg_wkdy.setDefaultValue("71")
    args << htg_wkdy

   	#Make a string argument for 24 weekend heating set point values
    htg_wked = OpenStudio::Ruleset::OSArgument::makeStringArgument("htg_wked", false)
    htg_wked.setDisplayName("Weekend Setpoint")
    htg_wked.setDescription("Specify a single heating setpoint or a 24-hour heating schedule for the weekend.")
    htg_wked.setUnits("degrees F")
    htg_wked.setDefaultValue("71")
    args << htg_wked
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    htg_wkdy = runner.getStringArgumentValue("htg_wkdy",user_arguments)
    htg_wked = runner.getStringArgumentValue("htg_wked",user_arguments)
    
    weather = WeatherProcess.new(model,runner)
    if weather.error?
      return false
    end
    
    heating_season, cooling_season = HelperMethods.calc_heating_and_cooling_seasons(model, weather, runner)
    if heating_season.nil?
        return false
    end
    
    heatingseasonschedule = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameHeatingSeason, Array.new(24, 1), Array.new(24, 1), heating_season, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)
    
    unless heatingseasonschedule.validated?
      return false
    end

    # assign the availability schedules to the equipment objects
    htg_equip = false
    model.getThermalZones.each do |thermal_zone|
    htg_coil = HelperMethods.existing_heating_equipment(model, runner, thermal_zone)
      unless htg_coil.nil?
        if htg_coil.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
          air_loop_unitary = htg_coil
          htg_coil = air_loop_unitary.heatingCoil.get
          if htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized
            htg_coil = htg_coil.to_CoilHeatingDXSingleSpeed.get
          elsif htg_coil.to_CoilHeatingDXMultiSpeed.is_initialized
            htg_coil = htg_coil.to_CoilHeatingDXMultiSpeed.get
          end          
          supp_htg_coil = air_loop_unitary.supplementalHeatingCoil.get
          supp_htg_coil = supp_htg_coil.to_CoilHeatingElectric.get
          heatingseasonschedule.setSchedule(supp_htg_coil)           
          runner.registerInfo("Added availability schedule to #{supp_htg_coil.name}.")
        elsif htg_coil.is_a? OpenStudio::Model::AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed
          air_loop_unitary = htg_coil
          htg_coil = air_loop_unitary.heatingCoil
          htg_coil = htg_coil.to_CoilHeatingDXMultiSpeed.get
          supp_htg_coil = air_loop_unitary.supplementalHeatingCoil
          supp_htg_coil = supp_htg_coil.to_CoilHeatingElectric.get
          heatingseasonschedule.setSchedule(supp_htg_coil)          
          runner.registerInfo("Added availability schedule to #{supp_htg_coil.name}.")
        end
        heatingseasonschedule.setSchedule(htg_coil)
        runner.registerInfo("Added availability schedule to #{htg_coil.name}.")
        htg_equip = true
      end
    end
    
    unless htg_equip
      runner.registerWarning("No heating equipment found.")
      return true
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
    
    finished_zones.each do |finished_zone|
    
      thermostatsetpointdualsetpoint = finished_zone.thermostatSetpointDualSetpoint
      if thermostatsetpointdualsetpoint.is_initialized
      
        thermostatsetpointdualsetpoint = thermostatsetpointdualsetpoint.get
        runner.registerInfo("Found existing thermostat #{thermostatsetpointdualsetpoint.name} for #{finished_zone.name}.")
        
        clg_wkdy = Array.new(24, 10000)
        clg_wked = Array.new(24, 10000)
        cooling_season = Array.new(12, 0.0)
        thermostatsetpointdualsetpoint.coolingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
          if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
            rule.daySchedule.values.each_with_index do |value, hour|
              if value < clg_wkdy[hour]
                clg_wkdy[hour] = value
              end
            end
          elsif rule.applySaturday and rule.applySunday
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
            clg_wkdy_monthly << Array.new(24, 10000)
            clg_wked_monthly << Array.new(24, 10000)
          else
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
        
        htg_monthly_sch = Array.new(12, 1)
        for m in 1..12
          if heating_season[m-1] == 1
            htg_monthly_sch[m-1] = 1
          else
            htg_monthly_sch[m-1] = -10000
          end
        end        
        clg_monthly_sch = Array.new(12, 1)
        for m in 1..12
          clg_monthly_sch[m-1] = 10000
        end        
        
        heatingsetpoint = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameHeatingSetpoint, htg_wkdy, htg_wked, htg_monthly_sch, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)
        coolingsetpoint = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameCoolingSetpoint, Array.new(24, 1), Array.new(24, 1), clg_monthly_sch, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)

        unless heatingsetpoint.validated?
          return false
        end        
        
        thermostatsetpointdualsetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
        thermostatsetpointdualsetpoint.setName("Living Zone Temperature SP")
        runner.registerInfo("Created new thermostat #{thermostatsetpointdualsetpoint.name} for #{finished_zone.name}.")
        heatingsetpoint.setSchedule(thermostatsetpointdualsetpoint)
        finished_zone.setThermostatSetpointDualSetpoint(thermostatsetpointdualsetpoint)
        coolingsetpoint.setSchedule(thermostatsetpointdualsetpoint)
        runner.registerInfo("Set a dummy cooling setpoint schedule for #{thermostatsetpointdualsetpoint.name}.")              
      
      end
      
      runner.registerInfo("Set the heating setpoint schedule for #{thermostatsetpointdualsetpoint.name}.")

    end

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessHeatingSetpoints.new.registerWithApplication