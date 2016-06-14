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
    return "This measure creates #{Constants.ObjectNameHeatingSeason} and #{Constants.ObjectNameCoolingSeason} ruleset objects. Schedule values are populated based on information contained in the EPW file. This measure also creates #{Constants.ObjectNameHeatingSetpoint} and #{Constants.ObjectNameCoolingSetpoint} ruleset objects. Schedule values are populated based on information input by the user as well as contained in the #{Constants.ObjectNameHeatingSeason} and #{Constants.ObjectNameCoolingSeason}. The heating and cooling setpoint schedules are added to the living zone's thermostat."
  end     
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

   	#Make a string argument for 24 weekday heating set point values
    htg_wkdy = OpenStudio::Ruleset::OSArgument::makeStringArgument("htg_wkdy")
    htg_wkdy.setDisplayName("Weekday Heating Setpoint Schedule")
    htg_wkdy.setDescription("Specify the 24-hour weekday heating schedule.")
    htg_wkdy.setUnits("degrees F")
    htg_wkdy.setDefaultValue("65.0, 65.0, 65.0, 65.0, 65.0, 65.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 65.0")
    args << htg_wkdy

   	#Make a string argument for 24 weekend heating set point values
    htg_wked = OpenStudio::Ruleset::OSArgument::makeStringArgument("htg_wked")
    htg_wked.setDisplayName("Weekend Heating Setpoint Schedule")
    htg_wked.setDescription("Specify the 24-hour weekend heating schedule.")
    htg_wked.setUnits("degrees F")
    htg_wked.setDefaultValue("65.0, 65.0, 65.0, 65.0, 65.0, 65.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 71.0, 65.0")
    args << htg_wked  
  
   	#Make a string argument for 24 weekday cooling set point values
    clg_wkdy = OpenStudio::Ruleset::OSArgument::makeStringArgument("clg_wkdy")
    clg_wkdy.setDisplayName("Weekday Cooling Setpoint Schedule")
    clg_wkdy.setDescription("Specify the 24-hour weekday cooling schedule.")
    clg_wkdy.setUnits("degrees F")
    clg_wkdy.setDefaultValue("76.0, 76.0, 76.0, 76.0, 76.0, 76.0, 76.0, 76.0, 76.0, 85.0, 85.0, 85.0, 85.0, 85.0, 85.0, 85.0, 85.0, 76.0, 76.0, 76.0, 76.0, 76.0, 76.0, 76.0")
    args << clg_wkdy  
    
   	#Make a string argument for 24 weekend cooling set point values
    clg_wked = OpenStudio::Ruleset::OSArgument::makeStringArgument("clg_wked")
    clg_wked.setDisplayName("Weekend Cooling Setpoint Schedule")
    clg_wked.setDescription("Specify the 24-hour weekend cooling schedule.")
    clg_wked.setUnits("degrees F")
    clg_wked.setDefaultValue("76.0, 76.0, 76.0, 76.0, 76.0, 76.0, 76.0, 76.0, 76.0, 85.0, 85.0, 85.0, 85.0, 85.0, 85.0, 85.0, 85.0, 76.0, 76.0, 76.0, 76.0, 76.0, 76.0, 76.0")
    args << clg_wked
    
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

    htg_wkdy = runner.getStringArgumentValue("htg_wkdy",user_arguments)
    htg_wked = runner.getStringArgumentValue("htg_wked",user_arguments)
    clg_wkdy = runner.getStringArgumentValue("clg_wkdy",user_arguments)
    clg_wked = runner.getStringArgumentValue("clg_wked",user_arguments)
    selectedheating = runner.getBoolArgumentValue("selectedheating",user_arguments)
    selectedcooling = runner.getBoolArgumentValue("selectedcooling",user_arguments)    
    
    if not selectedheating and not selectedcooling
      runner.registerWarning("No thermostat added because no heating and no cooling.")
      return true
    end      
    
    weather = WeatherProcess.new(model,runner)
    if weather.error?
      return false
    end
    
    heating_season, cooling_season = HelperMethods.calc_heating_and_cooling_seasons(model, weather, runner)
    if heating_season.nil? or cooling_season.nil?
        return false
    end
    
    heatingseasonschedule = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameHeatingSeason, Array.new(24, 1).join(", "), Array.new(24, 1).join(", "), heating_season.join(", "), mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)
    coolingseasonschedule = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameCoolingSeason, Array.new(24, 1).join(", "), Array.new(24, 1).join(", "), cooling_season.join(", "), mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)  
    
    if not heatingseasonschedule.validated? or not coolingseasonschedule.validated?
      return false
    end    

    htg_wkdy = htg_wkdy.split(",").map {|i| OpenStudio::convert(i.to_f,"F","C").get}
    htg_wked = htg_wked.split(",").map {|i| OpenStudio::convert(i.to_f,"F","C").get}
    clg_wkdy = clg_wkdy.split(",").map {|i| OpenStudio::convert(i.to_f,"F","C").get}
    clg_wked = clg_wked.split(",").map {|i| OpenStudio::convert(i.to_f,"F","C").get}
    
    htg_wd = []
    htg_we = []
    clg_wd = []
    clg_we = []
    htg_wd = htg_wkdy.zip(clg_wkdy).map {|h, c| c < h ? (h + c) / 2.0 : h}.join(", ")
    htg_we = htg_wked.zip(clg_wked).map {|h, c| c < h ? (h + c) / 2.0 : h}.join(", ")
    clg_wd = htg_wkdy.zip(clg_wkdy).map {|h, c| c < h ? (h + c) / 2.0 : c}.join(", ")
    clg_we = htg_wked.zip(clg_wked).map {|h, c| c < h ? (h + c) / 2.0 : c}.join(", ")
    
    htg_monthly_sch = Array.new(12, 1)
    for m in 1..12
      if heating_season[m-1] == 1.0
        htg_monthly_sch[m-1] = 1
      else
        htg_monthly_sch[m-1] = -10000
      end
    end
    htg_monthly_sch = htg_monthly_sch.join(", ")
    
    clg_monthly_sch = Array.new(12, 1)
    for m in 1..12
      if cooling_season[m-1] == 1.0
        clg_monthly_sch[m-1] = 1
      else
        clg_monthly_sch[m-1] = 10000
      end
    end
    clg_monthly_sch = clg_monthly_sch.join(", ")
    
    heatingsetpoint = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameHeatingSetpoint, htg_wd, htg_we, htg_monthly_sch, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)
    coolingsetpoint = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameCoolingSetpoint, clg_wd, clg_we, clg_monthly_sch, mult_weekday=1.0, mult_weekend=1.0, normalize_values=false)

    if not heatingsetpoint.validated? or not coolingsetpoint.validated?
      return false
    end    
    
    finished_zones = []
    model.getThermalZones.each do |thermal_zone|
      if Geometry.zone_is_finished(thermal_zone)
        finished_zones << thermal_zone
      end
    end
    
    finished_zones.each do |finished_zone|
    
      thermostatsetpointdualsetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
      thermostatsetpointdualsetpoint.setName("Living Zone Temperature SP")

      heatingsetpoint.setSchedule(thermostatsetpointdualsetpoint)
      coolingsetpoint.setSchedule(thermostatsetpointdualsetpoint)
    
      finished_zone.setThermostatSetpointDualSetpoint(thermostatsetpointdualsetpoint)
    
      runner.registerInfo("Set the thermostat '#{finished_zone.thermostatSetpointDualSetpoint.get.name}' for thermal zone '#{finished_zone.name}'")

    end

    return true
 
  end #end the run method
  
end #end the measure

#this allows the measure to be use by the application
ProcessHeatingandCoolingSetpoints.new.registerWithApplication