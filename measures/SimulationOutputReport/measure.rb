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
    
    # FIXME: Temporary fix to convert propane heating (modeled as gas) to other fuel. 
    # Remove when https://github.com/NREL/OpenStudio-BEopt/issues/114 is closed.
    gas_should_be_propane = 0.0
    if runner.past_results[:build_existing_models][:"hvac_system_heating_propane"].include?("Propane")
        if not sqlFile.naturalGasHeating.empty?
            gas_should_be_propane = sqlFile.naturalGasHeating.get
            runner.registerWarning("Propane Air Loop HVAC detected. Gas heating will be converted to propane.")
        end
    end
    
    # FIXME: Temporary fix to handle % conditioned for Room AC and MSHP
    percent_cooling = 1.0
    percent_heating = 1.0
    (1..9).each do |i|
        percent = i*10
        if runner.past_results[:build_existing_models][:"hvac_system_cooling"].include?("#{percent}% Conditioned")
            percent_cooling = percent.to_f/100.0
            runner.registerWarning("Cooling system with % conditioned detected. #{percent_cooling.to_s} will be applied to cooling results.")
        elsif runner.past_results[:build_existing_models][:"hvac_system_combined"].include?("#{percent}% Conditioned")
            percent_cooling = percent.to_f/100.0
            percent_heating = percent_cooling
            runner.registerWarning("Combined system with % conditioned detected. #{percent_cooling.to_s} will be applied to cooling and heating results.")
        end
    end
           
    # TOTAL
    
    report_sim_output(runner, "Total Site Energy", sqlFile.totalSiteEnergy, "GJ", "MBtu")
    
    # ELECTRICITY
    
    report_sim_output(runner, "Total Site Electricity", sqlFile.electricityTotalEndUses, "GJ", elec_site_units)
    report_sim_output(runner, "Electricity Heating", sqlFile.electricityHeating, "GJ", elec_site_units, 0.0, percent_heating)
    report_sim_output(runner, "Electricity Cooling", sqlFile.electricityCooling, "GJ", elec_site_units, 0.0, percent_cooling)
    report_sim_output(runner, "Electricity Interior Lighting", sqlFile.electricityInteriorLighting, "GJ", elec_site_units)
    report_sim_output(runner, "Electricity Exterior Lighting", sqlFile.electricityExteriorLighting, "GJ", elec_site_units)
    report_sim_output(runner, "Electricity Interior Equipment", sqlFile.electricityInteriorEquipment, "GJ", elec_site_units)
    report_sim_output(runner, "Electricity Fans", sqlFile.electricityFans, "GJ", elec_site_units)
    report_sim_output(runner, "Electricity Pumps", sqlFile.electricityPumps, "GJ", elec_site_units)
    report_sim_output(runner, "Electricity Water Systems", sqlFile.electricityWaterSystems, "GJ", elec_site_units)
    
    # NATURAL GAS
    
    report_sim_output(runner, "Total Site Natural Gas", sqlFile.naturalGasTotalEndUses, "GJ", gas_site_units, -1.0*gas_should_be_propane)
    report_sim_output(runner, "Natural Gas Heating", sqlFile.naturalGasHeating, "GJ", gas_site_units, -1.0*gas_should_be_propane, percent_heating)
    report_sim_output(runner, "Natural Gas Interior Equipment", sqlFile.naturalGasInteriorEquipment, "GJ", gas_site_units)
    report_sim_output(runner, "Natural Gas Water Systems", sqlFile.naturalGasWaterSystems, "GJ", gas_site_units)
    
    # OTHER FUEL
    
    report_sim_output(runner, "Total Site Other Fuel", sqlFile.otherFuelTotalEndUses, "GJ", other_fuel_site_units, gas_should_be_propane)
    report_sim_output(runner, "Other Fuel Heating", sqlFile.otherFuelHeating, "GJ", other_fuel_site_units, gas_should_be_propane, percent_heating)
    report_sim_output(runner, "Other Fuel Interior Equipment", sqlFile.otherFuelInteriorEquipment, "GJ", other_fuel_site_units)
    report_sim_output(runner, "Other Fuel Water Systems", sqlFile.otherFuelWaterSystems, "GJ", other_fuel_site_units)
    
    # LOADS NOT MET
    
    report_sim_output(runner, "Hours Heating Setpoint Not Met", sqlFile.hoursHeatingSetpointNotMet, nil, nil)
    report_sim_output(runner, "Hours Cooling Setpoint Not Met", sqlFile.hoursCoolingSetpointNotMet, nil, nil)
    
    # HVAC CAPACITIES
    
    cooling_capacity_query = "SELECT Value FROM ComponentSizes WHERE CompType IN ('Coil:Cooling:DX:SingleSpeed','Coil:Cooling:DX:TwoSpeed','Coil:Cooling:DX:MultiSpeed','Coil:Cooling:DX:VariableSpeed') AND Description IN ('Design Size Gross Rated Total Cooling Capacity')"
    cooling_capacity_w = sqlFile.execAndReturnFirstDouble(cooling_capacity_query)
    report_sim_output(runner, "HVAC Cooling Capacity", cooling_capacity_w, "W", "W", 0.0, percent_cooling)
    heating_capacity_query = "SELECT Value FROM ComponentSizes WHERE CompType IN ('Coil:Heating:Fuel','Coil:Heating:Electric','ZONEHVAC:BASEBOARD:CONVECTIVE:ELECTRIC','Coil:Heating:DX:SingleSpeed','Coil:Heating:DX:MultiSpeed','Coil:Heating:DX:VariableSpeed','Boiler:HotWater') AND Description IN ('Design Size Nominal Capacity','Design Size Heating Design Capacity','Design Size Gross Rated Heating Capacity')"
    heating_capacity_w = sqlFile.execAndReturnFirstDouble(heating_capacity_query)
    report_sim_output(runner, "HVAC Heating Capacity", heating_capacity_w, "W", "W", 0.0, percent_heating)
    
    # UPGRADE COSTS
    
    # Get upgrade cost value/multiplier pairs from the upgrade measure
    cost_pairs = []
    measures_used = 0
    runner.past_results.each do |measure, measure_hash|
        next if not measure_hash.keys.include?(:run_measure)
        next if measure_hash[:run_measure] == 0
        measures_used += 1
        for option_num in 1..10 # Sync with ApplyUpgrade measure
            for cost_num in 1..5 # Sync with ApplyUpgrade measure
                cost_value = measure_hash["option_#{option_num}_cost_#{cost_num}_value_to_apply".to_sym]
                cost_mult_type = measure_hash["option_#{option_num}_cost_#{cost_num}_multiplier_to_apply".to_sym]
                next if cost_value.nil? or cost_mult_type.nil? or cost_value.to_f == 0.0
                cost_pairs << [cost_value.to_f, cost_mult_type]
            end
        end
    end
    if measures_used > 1
        runner.registerError("Unexpected error.")
        return false
    end
    
    # Obtain cost multiplier values from simulation results and calculate upgrade costs
    upgrade_cost = 0.0
    cost_pairs.each do |cost_value, cost_mult_type|
        cost_mult = 0.0
        
        if cost_mult_type == "Fixed (1)"
            cost_mult = 1.0
            
        elsif cost_mult_type == "Conditioned Floor Area (ft^2)"
            sql_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' AND ReportForString='Entire Facility' AND TableName='Building Area' AND RowName='Net Conditioned Building Area' AND ColumnName='Area' AND Units='m2'"
            sql_result = sqlFile.execAndReturnFirstDouble(sql_query)
            cost_mult = OpenStudio::convert(sql_result.get,"m^2","ft^2").get
            
        elsif cost_mult_type == "Lighting Floor Area (ft^2)"
            # Get zone names where Lighting > 0
            sql_query = "SELECT RowName FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND ColumnName='Lighting' AND Units='W/m2' AND CAST(Value AS DOUBLE)>0"
            sql_results = sqlFile.execAndReturnVectorOfString(sql_query)
            if sql_results.is_initialized
                sql_results.get.each do |lighting_zone_name|
                    # Get floor area for this zone
                    sql_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName='#{lighting_zone_name}' AND ColumnName='Area' AND Units='m2'"
                    sql_result = sqlFile.execAndReturnFirstDouble(sql_query)
                    cost_mult += OpenStudio::convert(sql_result.get,"m^2","ft^2").get
                end
            end
            
        elsif cost_mult_type == "Above-Grade Conditioned Wall Area (ft^2)"
            sql_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName='Conditioned Total' AND ColumnName='Above Ground Gross Wall Area' AND Units='m2'"
            sql_result = sqlFile.execAndReturnFirstDouble(sql_query)
            cost_mult = OpenStudio::convert(sql_result.get,"m^2","ft^2").get
            
        elsif cost_mult_type == "Above-Grade Total Wall Area (ft^2)"
            sql_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName='Total' AND ColumnName='Above Ground Gross Wall Area' AND Units='m2'"
            sql_result = sqlFile.execAndReturnFirstDouble(sql_query)
            cost_mult = OpenStudio::convert(sql_result.get,"m^2","ft^2").get
            
        elsif cost_mult_type == "Below-Grade Conditioned Wall Area (ft^2)"
            sql_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName='Conditioned Total' AND ColumnName='Underground Gross Wall Area' AND Units='m2'"
            sql_result = sqlFile.execAndReturnFirstDouble(sql_query)
            cost_mult = OpenStudio::convert(sql_result.get,"m^2","ft^2").get
            
        elsif cost_mult_type == "Below-Grade Total Wall Area (ft^2)"
            sql_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName='Total' AND ColumnName='Underground Gross Wall Area' AND Units='m2'"
            sql_result = sqlFile.execAndReturnFirstDouble(sql_query)
            cost_mult = OpenStudio::convert(sql_result.get,"m^2","ft^2").get
            
        elsif cost_mult_type == "Window Area (ft^2)"
            sql_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Zone Summary' AND RowName='Total' AND ColumnName='Window Glass Area' AND Units='m2'"
            sql_result = sqlFile.execAndReturnFirstDouble(sql_query)
            cost_mult = OpenStudio::convert(sql_result.get,"m^2","ft^2").get
            
        elsif cost_mult_type == "Roof Area (ft^2)"
            sql_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='InputVerificationandResultsSummary' AND ReportForString='Entire Facility' AND TableName='Skylight-Roof Ratio' AND RowName='Gross Roof Area' AND ColumnName='Total' AND Units='m2'"
            sql_result = sqlFile.execAndReturnFirstDouble(sql_query)
            cost_mult = OpenStudio::convert(sql_result.get,"m^2","ft^2").get
            
        elsif cost_mult_type == "Door Area (ft^2)"
            sql_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EnvelopeSummary' AND ReportForString='Entire Facility' AND TableName='Exterior Door' AND ColumnName='Gross Area' AND Units='m2'"
            sql_results = sqlFile.execAndReturnVectorOfDouble(sql_query)
            if sql_results.is_initialized
                sql_results.get.each do |sql_result|
                    cost_mult += OpenStudio::convert(sql_result,"m^2","ft^2").get
                end
            end
            
        elsif cost_mult_type == "Water Heater Tank Size (gal)"
            sql_query = "SELECT Value FROM TabularDataWithStrings WHERE ReportName='EquipmentSummary' AND ReportForString='Entire Facility' AND TableName='Service Water Heating' AND ColumnName='Storage Volume' AND Units='m3'"
            sql_result = sqlFile.execAndReturnFirstDouble(sql_query)
            if sql_result.is_initialized
                cost_mult = OpenStudio::convert(sql_result.get,"m^3","gal").get
            end
            
        elsif cost_mult_type == "HVAC Cooling Capacity (kBtuh)"
            if cooling_capacity_w.is_initialized
                cost_mult = OpenStudio::convert(cooling_capacity_w.get,"W","kBtu/h").get
            end
            
        elsif cost_mult_type == "HVAC Heating Capacity (kBtuh)"
            if heating_capacity_w.is_initialized
                cost_mult = OpenStudio::convert(heating_capacity.get,"W","kBtu/h").get
            end
            
        else
            runner.registerError("Unhandled cost multiplier: #{cost_mult_type.to_s}. Aborting...")
            return false
            
        end
        runner.registerInfo("Upgrade cost addition: $#{cost_value} x #{cost_mult} [#{cost_mult_type}].")
        upgrade_cost += cost_value * cost_mult
    end
    upgrade_cost_str = "$"+upgrade_cost.round(2).to_s
    runner.registerValue("Upgrade Cost", upgrade_cost_str)
    runner.registerInfo("Registering #{upgrade_cost_str} for Upgrade Cost.")

    sqlFile.close()

    runner.registerFinalCondition("Report generated successfully.")

    return true

  end #end the run method

  def report_sim_output(runner, name, val, os_units, report_units, additional_val=0.0, percent_of_val=1.0)
    return if val.empty?
    if not report_units.nil?
        name = "#{name} #{report_units}"
    end
    newVal = (val.get + additional_val) * percent_of_val
    if os_units.nil? or report_units.nil? or os_units == report_units
        valInUnits = newVal
    else
        valInUnits = OpenStudio::convert(newVal, os_units, report_units).get
    end
    runner.registerValue(name,valInUnits)
    runner.registerInfo("Registering #{valInUnits.round(2)} for #{name}.")
  end
  
end #end the measure

#this allows the measure to be use by the application
SimulationOutputReport.new.registerWithApplication