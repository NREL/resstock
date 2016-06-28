#start the measure
class StandardReports < OpenStudio::Ruleset::ReportingUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Standard Reports"
  end
  
  def description
    return "Reports fuel and end use simulation outputs."
  end

  #define the arguments that the user will input
  def arguments()
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(), user_arguments)
      return false
    end
    
    # get the last model and sql file

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    fuel_type = ""
    units = ""

    map = {"site_energy_use"=>"Total Site Energy MBtu",
           "electricity"=>"Total Site Electricity kWh",
           "natural_gas"=>"Total Site Natural Gas therm",
           "additional_fuel"=>"Total Site Other Fuel MBtu",
           "electricity_heating"=>"Electricity Heating kWh",
           "electricity_cooling"=>"Electricity Cooling kWh",
           "electricity_interior_lighting"=>"Electricity Interior Lighting kWh",
           "electricity_exterior_lighting"=>"Electricity Exterior Lighting kWh",
           "electricity_interior_equipment"=>"Electricity Interior Equipment kWh",
           "electricity_fans"=>"Electricity Fans kWh",
           "electricity_pumps"=>"Electricity Pumps kWh",
           "electricity_water_systems"=>"Electricity Water Systems kWh",
           "natural_gas_heating"=>"Natural Gas Heating therm",
           "natural_gas_interior_equipment"=>"Natural Gas Interior Equipment therm",
           "natural_gas_water_systems"=>"Natural Gas Water Systems therm",
           "additional_fuel_heating"=>"Other Fuel Heating MBtu",
           "additional_fuel_interior_equipment"=>"Other Fuel Interior Equipment MBtu",
           "additional_fuel_water_systems"=>"Other Fuel Water Systems MBtu"}
    
    site_energy_use = 0.0
    OpenStudio::EndUseFuelType::getValues.each do |fuel_type|
      fuel_type = OpenStudio::EndUseFuelType.new(fuel_type).valueDescription
      if fuel_type == "Electricity"
        units = "\"kWh\""
        unit_str = "kWh"
      elsif fuel_type == "Natural Gas"
        units = "\"therm\""
        unit_str = "therm"
      else
        units = "\"Million Btu\""
        unit_str = "MBtu"
      end
      fuel_type_aggregation = 0.0
      OpenStudio::EndUseCategoryType::getValues.each do |category_type|
        fuel_and_category_aggregation = 0.0
        category_str = OpenStudio::EndUseCategoryType.new(category_type).valueDescription
        OpenStudio::MonthOfYear::getValues.each do |month|
          if month >= 1 and month <= 12
            if not sqlFile.energyConsumptionByMonth(OpenStudio::EndUseFuelType.new(fuel_type),
                                                    OpenStudio::EndUseCategoryType.new(category_type),
                                                    OpenStudio::MonthOfYear.new(month)).empty?
              valInJ = sqlFile.energyConsumptionByMonth(OpenStudio::EndUseFuelType.new(fuel_type),
                                                        OpenStudio::EndUseCategoryType.new(category_type),
                                                        OpenStudio::MonthOfYear.new(month)).get
              fuel_and_category_aggregation += valInJ
              month_str = OpenStudio::MonthOfYear.new(month).valueDescription
              name = OpenStudio::toUnderscoreCase("#{fuel_type}_#{category_str}_#{month_str}")
              valInUnits = OpenStudio::convert(valInJ,"J",unit_str).get()
              #runner.registerValue(name,valInUnits,unit_str)
              #runner.registerInfo("Registered: #{name},#{valInUnits},#{unit_str}")
            end
          end
        end
        name = get_mapped_name(OpenStudio::toUnderscoreCase("#{fuel_type}_#{category_str}"), map)
        valInUnits = OpenStudio::convert(fuel_and_category_aggregation,"J",unit_str).get
        runner.registerValue(name,valInUnits,unit_str)
        runner.registerInfo("Registered: #{name},#{valInUnits},#{unit_str}")
        fuel_type_aggregation += fuel_and_category_aggregation
      end
      name = get_mapped_name(OpenStudio::toUnderscoreCase("#{fuel_type}"), map)
      valInUnits = OpenStudio::convert(fuel_type_aggregation,"J",unit_str).get
      runner.registerValue(name,valInUnits,unit_str)
      runner.registerInfo("Registered: #{name},#{valInUnits},#{unit_str}")
      site_energy_use += fuel_type_aggregation
    end
    name = get_mapped_name("site_energy_use", map)
    valInUnits = OpenStudio::convert(site_energy_use,"J","MBtu").get
    runner.registerValue(name,valInUnits,"MBtu")
    runner.registerInfo("Registered: #{name},#{valInUnits},MBtu")

    #closing the sql file
    sqlFile.close()

    #reporting final condition
    runner.registerFinalCondition("Standard Report generated successfully.")

    return true

  end #end the run method

  def get_mapped_name(name, map)
    if map.has_key?(name)
      return map[name]
    end
    return name
  end
  
end #end the measure

#this allows the measure to be use by the application
StandardReports.new.registerWithApplication