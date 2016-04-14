# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/weather"

# start the measure
class SetResidentialEPWFile < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Set Residential Location"
  end

  # human readable description
  def description
    return "Sets the EPW weather file (EPW) and supplemental data specific to the location."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Sets the weather file, site information (e.g., latitude, longitude, elevation, timezone), design day information (from the DDY file), and the mains water temperature using the correlation method."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_directory', true)
    arg.setDisplayName("Weather Directory")
    arg.setDescription("Absolute (or relative) directory to weather files.")
    arg.setDefaultValue("../../../../OpenStudio-Beopt/OpenStudio-analysis-spreadsheet/weather")
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeStringArgument('weather_file_name', true)
    arg.setDisplayName("Weather File Name")
    arg.setDescription("Name of the EPW weather file to assign. The corresponding DDY file must also be in the same directory.")
    arg.setDefaultValue("USA_CO_Denver.Intl.AP.725650_TMY3.epw")
    args << arg

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # grab the initial weather file
    weather_directory = runner.getStringArgumentValue("weather_directory", user_arguments)
    weather_file_name = runner.getStringArgumentValue("weather_file_name", user_arguments)

    # ----------------
    # Set weather file
    # ----------------
    
    unless (Pathname.new weather_directory).absolute?
      weather_directory = File.expand_path(File.join(File.dirname(__FILE__), weather_directory))
    end
    weather_file = File.join(weather_directory, weather_file_name)
    if File.exists?(weather_file) and weather_file_name.downcase.end_with? ".epw"
        epw_file = OpenStudio::EpwFile.new(weather_file)
    else
      runner.registerError("'#{weather_file}' does not exist or is not an .epw file.")
      return false
    end	

    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    runner.registerInfo("Setting weather file.")
    
    # -------------------
    # Set model site data
    # -------------------
    
    weather_name = "#{epw_file.city}_#{epw_file.stateProvinceRegion}_#{epw_file.country}"
    weather_lat = epw_file.latitude
    weather_lon = epw_file.longitude
    weather_time = epw_file.timeZone
    weather_elev = epw_file.elevation

    # Add or update site data
    site = model.getSite
    site.setName(weather_name)
    site.setLatitude(weather_lat)
    site.setLongitude(weather_lon)
    site.setTimeZone(weather_time)
    site.setElevation(weather_elev)
    runner.registerInfo("Setting site data.")

    # -------------------
    # Set design day info
    # -------------------

    # Remove all the Design Day objects that are in the file
    model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).each { |d| d.remove }

    # Load in the ddy file based on convention that it is in the same directory and has the same basename as the weather
    ddy_file = "#{File.join(File.dirname(weather_file), File.basename(weather_file, '.*'))}.ddy"
    if File.exist? ddy_file
      ddy_model = OpenStudio::EnergyPlus.loadAndTranslateIdf(ddy_file).get
      ddy_model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).each do |d|
        # grab only the ones that matter
        ddy_list = /(Htg 99.6. Condns DB)|(Clg .4. Condns WB=>MDB)|(Clg .4% Condns DB=>MWB)/
        if d.name.get =~ ddy_list
          runner.registerInfo("Adding object #{d.name}.")
          # add the object to the existing model
          model.addObject(d.clone)
        end
      end
    else
      runner.registerError("Could not find DDY file for #{ddy_file}.")
      return false
    end
    
    # ----------------------------
    # Set mains water temperatures
    # ----------------------------
    
    weather = WeatherProcess.new(model,runner)
    if weather.error?
      return false
    end

	avgOAT = OpenStudio::convert(weather.data.AnnualAvgDrybulb,"F","C").get
	monthlyOAT = weather.data.MonthlyAvgDrybulbs
	
	min_temp = monthlyOAT.min
	max_temp = monthlyOAT.max
	
	maxDiffOAT = OpenStudio::convert(max_temp,"F","C").get - OpenStudio::convert(min_temp,"F","C").get
	
	#Calc annual average mains temperature to report
	daily_mains, monthly_mains, annual_mains = WeatherProcess._calc_mains_temperature(weather.data, weather.header)
		
    swmt = model.getSiteWaterMainsTemperature
        
    swmt.setCalculationMethod "Correlation"
    swmt.setAnnualAverageOutdoorAirTemperature avgOAT
    swmt.setMaximumDifferenceInMonthlyAverageOutdoorAirTemperatures maxDiffOAT
    runner.registerInfo("Setting Site:MainsWaterTemperature object with an average temperature of #{annual_mains.round(1)} F.")

    # report final condition
    final_design_days = model.getDesignDays
    if site.weatherFile.is_initialized
      weather = site.weatherFile.get
      runner.registerFinalCondition("The final weather file path was '#{weather.path.get}' and the model has #{final_design_days.size} design days.")
    else
      runner.registerFinalCondition("The final weather file has not been set and the model has #{final_design_days.size} design days.")
    end    

    return true

  end
  
end

# register the measure to be used by the application
SetResidentialEPWFile.new.registerWithApplication
