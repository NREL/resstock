#start the measure
class SimulationOutputReport < OpenStudio::Ruleset::ReportingUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Simulation Output Report"
  end
  
  def description
    return "Reports simulation outputs of interest."
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
    
    elec_site_units = "kWh"
    gas_site_units = "therm"
    other_fuel_site_units = "MBtu"
           
    # Total
    report_output(runner, "Total Site Energy", sqlFile.totalSiteEnergy, "GJ", "MBtu")
    
    # Electricity
    report_output(runner, "Total Site Electricity", sqlFile.electricityTotalEndUses, "GJ", elec_site_units)
    report_output(runner, "Electricity Heating", sqlFile.electricityHeating, "GJ", elec_site_units)
    report_output(runner, "Electricity Cooling", sqlFile.electricityCooling, "GJ", elec_site_units)
    report_output(runner, "Electricity Interior Lighting", sqlFile.electricityInteriorLighting, "GJ", elec_site_units)
    report_output(runner, "Electricity Exterior Lighting", sqlFile.electricityExteriorLighting, "GJ", elec_site_units)
    report_output(runner, "Electricity Interior Equipment", sqlFile.electricityInteriorEquipment, "GJ", elec_site_units)
    report_output(runner, "Electricity Fans", sqlFile.electricityFans, "GJ", elec_site_units)
    report_output(runner, "Electricity Pumps", sqlFile.electricityPumps, "GJ", elec_site_units)
    report_output(runner, "Electricity Water Systems", sqlFile.electricityWaterSystems, "GJ", elec_site_units)
    
    # Natural Gas
    report_output(runner, "Total Site Natural Gas", sqlFile.naturalGasTotalEndUses, "GJ", gas_site_units)
    report_output(runner, "Natural Gas Heating", sqlFile.naturalGasHeating, "GJ", gas_site_units)
    report_output(runner, "Natural Gas Interior Equipment", sqlFile.naturalGasInteriorEquipment, "GJ", gas_site_units)
    report_output(runner, "Natural Gas Water Systems", sqlFile.naturalGasWaterSystems, "GJ", gas_site_units)
    
    # Other Fuel
    report_output(runner, "Total Site Other Fuel", sqlFile.otherFuelTotalEndUses, "GJ", other_fuel_site_units)
    report_output(runner, "Other Fuel Heating", sqlFile.otherFuelHeating, "GJ", other_fuel_site_units)
    report_output(runner, "Other Fuel Interior Equipment", sqlFile.otherFuelInteriorEquipment, "GJ", other_fuel_site_units)
    report_output(runner, "Other Fuel Water Systems", sqlFile.otherFuelWaterSystems, "GJ", other_fuel_site_units)
    
    # Loads Not Met
    report_output(runner, "Hours Heating Setpoint Not Met", sqlFile.hoursHeatingSetpointNotMet, nil, nil)
    report_output(runner, "Hours Cooling Setpoint Not Met", sqlFile.hoursCoolingSetpointNotMet, nil, nil)
    
    # HVAC Capacities
    cooling_capacity_query = "SELECT Value FROM ComponentSizes WHERE CompType IN ('Coil:Cooling:DX:SingleSpeed','Coil:Cooling:DX:TwoSpeed','Coil:Cooling:DX:MultiSpeed','Coil:Cooling:DX:VariableSpeed') AND Description IN ('Design Size Gross Rated Total Cooling Capacity')"
    cooling_capacity = sqlFile.execAndReturnFirstDouble(cooling_capacity_query)
    report_output(runner, "HVAC Cooling Capacity", cooling_capacity, "W", "W")
    heating_capacity_query = "SELECT Value FROM ComponentSizes WHERE CompType IN ('Coil:Heating:Fuel','Coil:Heating:Electric','ZONEHVAC:BASEBOARD:CONVECTIVE:ELECTRIC','Coil:Heating:DX:SingleSpeed','Coil:Heating:DX:MultiSpeed','Coil:Heating:DX:VariableSpeed','Boiler:HotWater') AND Description IN ('Design Size Nominal Capacity','Design Size Heating Design Capacity','Design Size Gross Rated Heating Capacity')"
    heating_capacity = sqlFile.execAndReturnFirstDouble(heating_capacity_query)
    report_output(runner, "HVAC Heating Capacity", heating_capacity, "W", "W")
    
    #closing the sql file
    sqlFile.close()

    #reporting final condition
    runner.registerFinalCondition("Report generated successfully.")

    return true

  end #end the run method

  def report_output(runner, name, val, os_units=nil, report_units=nil)
    return if val.empty?
    if not report_units.nil?
        name = "#{name} #{report_units}"
    end
    if os_units.nil? or report_units.nil? or os_units != report_units
        valInUnits = val.get
    else
        valInUnits = OpenStudio::convert(val.get,os_units,report_units).get
    end
    runner.registerValue(name,valInUnits)
    runner.registerInfo("Registered: #{name}, #{valInUnits.round(2)}")
  end
  
end #end the measure

#this allows the measure to be use by the application
SimulationOutputReport.new.registerWithApplication