#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/util"

# FIXME: Unit conversions as needed
# FIXME: Combine heating/cooling/etc. calculations as appropriate

#start the measure
class ProcessHVACSizing < OpenStudio::Ruleset::ModelUserScript

  class MJ8
    def initialize
    end
    attr_accessor(:clf_avg_nois, :clf_avg_is, :psf, :clf_hr_nois, :clf_hr_is, :slm_alp_hr, :declination_angle, :cltd_base_sun, 
                  :cltd_base_shade, :daily_range_temp_adjust, :acfs, :acf, :Wetbulb_75DB_50RH, :Wetbulb_75DB_60RH, :Cs, :Cw, 
                  :n_occupants, :cooling_setpoint, :heating_setpoint, :cool_design_grains, :dehum_design_grains, :ctd, :htd, 
                  :dtd, :daily_range_num, :grains_indoor_cooling, :wetbulb_indoor_cooling, :enthalpy_indoor_cooling, 
                  :RH_indoor_dehumid, :grains_indoor_dehumid, :wetbulb_indoor_dehumid, :psf_lat, :gable_ua, :LAT, :dse_Fregain, 
                  :cool_design_temps, :heat_design_temps, :dehum_design_temps,
                  :CoolingLoad_Windows, :CoolingLoad_Doors, :CoolingLoad_Walls, :CoolingLoad_Roofs, :CoolingLoad_Floors, 
                  :CoolingLoad_Infil_Sens, :CoolingLoad_Infil_Lat, :DehumidLoad_Infil_Sens, :DehumidLoad_Infil_Lat,
                  :CoolingLoad_IntGains_Sens, :CoolingLoad_IntGains_Lat, :DehumidLoad_IntGains_Sens, :DehumidLoad_IntGains_Lat,
                  :HeatingLoad_Cond, :HeatingLoad_FBsmt, :HeatingLoad_Infil, :HeatingLoad_Infil_FBsmt, :DehumidLoad_Cond,
                  :HeatingLoad_Inter, :CoolingLoad_Inter_Sens, :CoolingLoad_Inter_Lat, :CoolingLoad_Inter_Tot,
                  :CoolingCFM_Inter, :HeatingCFM_Inter, :DehumidLoad_Inter_Sens, :DehumidLoad_Inter_Lat, :HeatingLoad,
                  :DuctLoad_FinBasement, :CoolingLoad_Tot, :CoolingLoad_Sens, :CoolingLoad_Lat, :CoolingLoad_Ducts_Sens, 
                  :CoolingLoad_Ducts_Tot, :DehumidLoad_Sens, :dse_h_Return_Cooling, :dse_h_Return_Dehumid, :Cool_AirFlowRate,
                  :dse_Dehumid_Latent, :Cool_Capacity, :Cool_SensCap, :EnteringTemp, :TotalCap_CurveValue, :SensCap_Design,
                  :LatCap_Design, :Cool_SensCap_Design, :Cool_Capacity_Design, :has_fixed_cooling, :has_fixed_heating,
                  :OverSizeLimit, :UnderSizeLimit, :Dehumid_WaterRemoval_Auto, :Heat_Capacity)
  end
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential HVAC Sizing"
  end
  
  def description
    return "This measure performs HVAC sizing calculations via Manual J, as well as sizing calculations for ground source heat pumps and dehumidifiers."
  end
  
  def modeler_description
    return "This measure assigns HVAC heating/cooling capacities, airflow rates, etc."
  end     
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
  
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    # Get the weather data
    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__), header_only=false)
    if weather.error?
        return false
    end
    
    # Number of stories
    unless model.getBuilding.standardsNumberOfAboveGroundStories.is_initialized
      runner.registerError("Cannot determine the number of above grade stories.")
      return false
    end
    building_num_stories = model.getBuilding.standardsNumberOfAboveGroundStories.get

    # Constants
    minCoolingCapacity = 1 # Btu/hr
    
    units.each do |unit|
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        
        # Get surfaces for the unit
        unit_surfaces = get_surfaces_for_unit(unit)
            
        # Get HVAC systems
        has_hvac = get_hvac_for_unit(runner, model, unit)
        
        # Walls
        wall_type = 'Constants.WallTypeWoodStud' # FIXME
        finishDensity = 11.0 # FIXME
        finishAbsorptivity = 0.6 # FIXME
        wallSheathingContInsRvalue = 5.0 # FIXME
        wallSheathingContInsThickness = 1.0 # FIXME
        wallCavityInsRvalueInstalled = 13.0 # FIXME
        sipInsThickness = 5.0 # FIXME
        cmuFurringInsRvalue = 15.0 # FIXME
        
        # Roof
        finishedRoofTotalR = 20.0 # FIXME
        fRRoofContInsThickness = 2.0 # FIXME
        roofMatColor = 'Constants.ColorDark' # FIXME
        roofMatDescription = 'Constants.MaterialTile' # FIXME

        # Windows, Overhangs, Internal Shades
        has_IntGains_shade = true # FIXME
        windowHasOverhang = true # FIXME
        overhangDepth = 2 # FIXME
        overhangOffset = 0.5 # FIXME
        windowHeight = 4 # FIXME
        
        # Foundation
        basement_ceiling_Rvalue = 0 # FIXME
        basement_wall_Rvalue = 10 # FIXME
        basement_ach = 0.1 # FIXME
        crawlACH = 2.0 # FIXME
        crawl_ceiling_Rvalue = 0 # FIXME
        crawl_wall_Rvalue = 10 # FIXME

        # Infiltration
        infil_type = 'ach50' # FIXME
        space_ela = 3.0 # FIXME
        space_inf_flow = 50.0 # FIXME
        
        # Mechanical Ventilation
        mechVentType = 'Constants.VentTypeExhaust' # FIXME
        whole_house_vent_rate = 50.0 # FIXME
        mechVentApparentSensibleEffectiveness = nil # FIXME
        mechVentLatentEffectiveness = nil # FIXME
        mechVentTotalEfficiency = nil # FIXME

        # Ducts
        has_ducts = true # FIXME
        ducts_not_in_living = true # FIXME
        ductSystemEfficiency = nil # FIXME
        ductNormLeakageToOutside = nil
        supply_duct_surface_area = 100 # FIXME
        return_duct_surface_area = 50 # FIXME
        ductLocationFracConduction = 0.5 # FIXME
        supply_duct_loss = 0.15 # FIXME
        return_duct_loss = 0.05 # FIXME
        supply_duct_r = 2.0 # FIXME
        return_duct_r = 1.5 # FIXME
        ductLocation = 'Constants.SpaceGarage' # FIXME
        if ductLocation == 'Constants.SpaceGarage'
            ductLocationSpace = Geometry.get_garage_spaces(unit.spaces, model)[0] # FIXME
        else
            runner.registerError("Unexpected duct location '#{ductLocation.to_s}'.")
            return false
        end
        
        # HVAC
        num_speeds = 1 # FIXME
        cOOL_CAP_FT_SPEC_coefficients = [[3.670270705, -0.098652414, 0.000955906, 0.006552414, -0.0000156, -0.000131877]] # FIXME
        sHR_Rated = [0.71, 0.73] # FIXME
        capacity_Ratio_Cooling = [0.72, 1.0] # FIXME
        tonnages = [1.5, 2, 3, 4, 5] # FIXME: Get from HVAC measures
        htg_supply_air_temp = 105 # FIXME
        fixed_cooling_capacity = nil # FIXME
        fixed_heating_capacity = nil # FIXME
        spaceConditionedMult = 1.0 # FIXME
        eER_CapacityDerateFactor = [] # FIXME
        cOP_CapacityDerateFactor = [] # FIXME

        mj8 = MJ8.new
        mj8.OverSizeLimit = 1.15
        mj8.UnderSizeLimit = 0.9
        #for zone in zones:
        #    loads = {living: mj8, basement: mj8, living2: mj8}
        mj8 = processDataTablesAndInit(runner, model, unit, mj8, building_num_stories)
        mj8 = processSiteCalcs(runner, model, unit, mj8, weather, nbeds)
        mj8 = processDesignTemps(runner, model, unit, mj8, weather)
        # FIXME: ensure coincidence of window loads across zones in a unit
        mj8 = processCoolingLoadWindows(runner, model, unit, mj8, weather, unit_surfaces, has_IntGains_shade, windowHasOverhang, overhangDepth, overhangOffset, windowHeight)
        mj8 = processCoolingLoadDoors(runner, model, unit, mj8, weather, unit_surfaces)
        mj8 = processCoolingLoadWalls(runner, model, unit, mj8, weather, unit_surfaces, wall_type, finishDensity, finishAbsorptivity, wallSheathingContInsRvalue, wallSheathingContInsThickness, wallCavityInsRvalueInstalled, sipInsThickness, cmuFurringInsRvalue)
        mj8 = processCoolingLoadCeilings(runner, model, unit, mj8, weather, unit_surfaces, finishedRoofTotalR, fRRoofContInsThickness, roofMatColor, roofMatDescription)
        mj8 = processCoolingLoadFloors(runner, model, unit, mj8, weather, unit_surfaces)
        mj8 = processInfiltrationVentilation(runner, model, unit, mj8, weather, infil_type, space_ela, space_inf_flow, mechVentType, whole_house_vent_rate, mechVentApparentSensibleEffectiveness, mechVentLatentEffectiveness, mechVentTotalEfficiency)
        mj8 = processInternalGains(runner, model, unit, mj8, weather)
        mj8.HeatingLoad_Cond, mj8.HeatingLoad_FBsmt = processHeatingLoadConduction(runner, model, unit, mj8, weather, unit_surfaces, mj8.htd)
        mj8.HeatingLoad_Infil, mj8.HeatingLoad_Infil_FBsmt = processInfiltrationVentilation_Heating(runner, model, unit, mj8, weather, mj8.htd, infil_type, space_ela, space_inf_flow, mechVentType, whole_house_vent_rate, mechVentApparentSensibleEffectiveness, mechVentLatentEffectiveness, mechVentTotalEfficiency)
        mj8 = processDehumidificationLoad(runner, model, unit, mj8, weather, unit_surfaces)
        display_Info(runner, mj8, true, false, false)
        mj8 = processIntermediateTotalLoads(runner, model, unit, mj8, weather, htg_supply_air_temp)
        display_Info(runner, mj8, false, true, false)
        
        #aggregate_loads
        
        mj8.dse_Fregain = processDuctRegainFactors(runner, mj8, has_ducts, ducts_not_in_living, ductSystemEfficiency, ductLocation, basement_ceiling_Rvalue, basement_wall_Rvalue, basement_ach, crawlACH, crawl_ceiling_Rvalue, crawl_wall_Rvalue)
        mj8 = processDuctLoads_Heating(runner, model, unit, mj8, weather, mj8.HeatingLoad_Inter, has_ducts, ducts_not_in_living, ductSystemEfficiency, ductLocation, supply_duct_surface_area, return_duct_surface_area, ductLocationFracConduction, ductNormLeakageToOutside, supply_duct_loss, return_duct_loss, supply_duct_r, return_duct_r, has_hvac['ForcedAir'], htg_supply_air_temp, ductLocationSpace)
        mj8 = processDuctLoads_Cooling_Dehum(runner, model, unit, mj8, weather, has_ducts, ducts_not_in_living, supply_duct_surface_area, return_duct_surface_area, ductLocationFracConduction, ductLocation, supply_duct_loss, return_duct_loss, ductNormLeakageToOutside, supply_duct_r, return_duct_r, ductSystemEfficiency, has_hvac['ForcedAir'], ductLocationSpace)
        display_Info(runner, mj8, false, false, true)
        mj8 = processCoolingEquipmentAdjustments(runner, model, unit, mj8, weather, has_hvac, minCoolingCapacity, num_speeds, cOOL_CAP_FT_SPEC_coefficients, sHR_Rated, capacity_Ratio_Cooling)
        mj8 = processFixedEquipment(runner, model, unit, mj8, weather, has_hvac, fixed_cooling_capacity, fixed_heating_capacity, spaceConditionedMult)
        mj9 = processFinalize(runner, model, unit, mj8, weather, has_hvac, htg_supply_air_temp)
        mj8 = processFinishedBasementFlowRatio(runner, model, unit, mj8, weather)
        mj8 = processEfficientCapacityDerate(runner, model, unit, mj8, weather, has_hvac, tonnages, eER_CapacityDerateFactor, cOP_CapacityDerateFactor)
        mj8 = processDehumidifierSizing(runner, model, unit, mj8, weather, has_hvac, minCoolingCapacity, cOOL_CAP_FT_SPEC_coefficients, capacity_Ratio_Cooling, sHR_Rated)
        
        return false if mj8.nil?
        
    end # unit
    
    return true
 
  end #end the run method
  
  def processDataTablesAndInit(runner, model, unit, mj8, building_num_stories)
    '''
    Data Tables and Initialization
    '''
    
    return nil if mj8.nil?
    
    # Average cooling load factors for windows WITHOUT internal shading for surface 
    # azimuths of 0,22.5,45, ... ,337.5,360
    # Additional values (compared to values in MJ8 Table 3D-3) have been determined by 
    # linear interpolation to avoid interpolating                    
    mj8.clf_avg_nois = [0.24, 0.295, 0.35, 0.365, 0.38, 0.39, 0.4, 0.44, 0.48, 0.44, 0.4, 0.39, 0.38, 0.365, 0.35, 0.295, 0.24]
    
    # Average cooling load factors for windows WITH internal shading for surface 
    # azimuths of 0,22.5,45, ... ,337.5,360
    # Additional values (compared to values in MJ8 Table 3D-3) have been determined 
    # by linear interpolation to avoid interpolating in BMI
    mj8.clf_avg_is = [0.18, 0.235, 0.29, 0.305, 0.32, 0.32, 0.32, 0.305, 0.29, 0.305, 0.32, 0.32, 0.32, 0.305, 0.29, 0.235, 0.18]            
    
    # Peak solar factor (PSF) (aka solar heat gain factor) taken from ASHRAE HOF 1989 Ch.26 Table 34 
    # (subset of data in MJ8 Table 3D-2)            
    # Surface Azimuth = 0 (South), 22.5, 45.0, ... ,337.5,360 and Latitude = 20,24,28, ... ,60,64
    mj8.psf = [[ 57, 72, 91, 111, 131, 149, 165, 180, 193, 203, 211, 217],
                    [ 88, 103, 120, 136, 151, 165, 177, 188, 197, 206, 213, 217],
                    [152, 162, 172, 181, 189, 196, 202, 208, 212, 215, 217, 217],
                    [200, 204, 207, 210, 212, 214, 215, 216, 216, 216, 214, 211],
                    [220, 220, 220, 219, 218, 216, 214, 211, 208, 203, 199, 193],
                    [206, 203, 199, 195, 190, 185, 180, 174, 169, 165, 161, 157],
                    [162, 156, 149, 141, 138, 135, 132, 128, 124, 119, 114, 109],
                    [ 91, 87, 83, 79, 75, 71, 66, 61, 56, 56, 57, 58],
                    [ 40, 38, 38, 37, 36, 35, 34, 33, 32, 30, 28, 27],
                    [ 91, 87, 83, 79, 75, 71, 66, 61, 56, 56, 57, 58],
                    [162, 156, 149, 141, 138, 135, 132, 128, 124, 119, 114, 109],
                    [206, 203, 199, 195, 190, 185, 180, 174, 169, 165, 161, 157],
                    [220, 220, 220, 219, 218, 216, 214, 211, 208, 203, 199, 193],
                    [200, 204, 207, 210, 212, 214, 215, 216, 216, 216, 214, 211],
                    [152, 162, 172, 181, 189, 196, 202, 208, 212, 215, 217, 217],
                    [ 88, 103, 120, 136, 151, 165, 177, 188, 197, 206, 213, 217],
                    [ 57, 72, 91, 111, 131, 149, 165, 180, 193, 203, 211, 217]]
  
    # Hourly cooling load factor (CLF) for windows WITHOUT an internal shade taken from 
    # ASHRAE HOF Ch.26 Table 36 (subset of data in MJ8 Table A11-5)
    # Surface Azimuth = 0 (South), 22.5, 45.0, ... ,337.5,360 and Hour = 8,9, ... ,19,20 
    mj8.clf_hr_nois = [[0.14, 0.22, 0.34, 0.48, 0.59, 0.65, 0.65, 0.59, 0.50, 0.43, 0.36, 0.28, 0.22],
                            [0.11, 0.15, 0.19, 0.27, 0.39, 0.52, 0.62, 0.67, 0.65, 0.58, 0.46, 0.36, 0.28],
                            [0.10, 0.12, 0.14, 0.16, 0.24, 0.36, 0.49, 0.60, 0.66, 0.66, 0.58, 0.43, 0.33],
                            [0.09, 0.10, 0.12, 0.13, 0.17, 0.26, 0.40, 0.52, 0.62, 0.66, 0.61, 0.44, 0.34],
                            [0.08, 0.10, 0.11, 0.12, 0.14, 0.20, 0.32, 0.45, 0.57, 0.64, 0.61, 0.44, 0.34],
                            [0.09, 0.10, 0.12, 0.13, 0.15, 0.17, 0.26, 0.40, 0.53, 0.63, 0.62, 0.44, 0.34],
                            [0.10, 0.12, 0.14, 0.16, 0.17, 0.19, 0.23, 0.33, 0.47, 0.59, 0.60, 0.43, 0.33],
                            [0.14, 0.18, 0.22, 0.25, 0.27, 0.29, 0.30, 0.33, 0.44, 0.57, 0.62, 0.44, 0.33],
                            [0.48, 0.56, 0.63, 0.71, 0.76, 0.80, 0.82, 0.82, 0.79, 0.75, 0.69, 0.61, 0.48],
                            [0.47, 0.44, 0.41, 0.40, 0.39, 0.39, 0.38, 0.36, 0.33, 0.30, 0.26, 0.20, 0.16],
                            [0.51, 0.51, 0.45, 0.39, 0.36, 0.33, 0.31, 0.28, 0.26, 0.23, 0.19, 0.15, 0.12],
                            [0.52, 0.57, 0.50, 0.45, 0.39, 0.34, 0.31, 0.28, 0.25, 0.22, 0.18, 0.14, 0.12],
                            [0.51, 0.57, 0.57, 0.50, 0.42, 0.37, 0.32, 0.29, 0.25, 0.22, 0.19, 0.15, 0.12],
                            [0.49, 0.58, 0.61, 0.57, 0.48, 0.41, 0.36, 0.32, 0.28, 0.24, 0.20, 0.16, 0.13],
                            [0.43, 0.55, 0.62, 0.63, 0.57, 0.48, 0.42, 0.37, 0.33, 0.28, 0.24, 0.19, 0.15],
                            [0.27, 0.43, 0.55, 0.63, 0.64, 0.60, 0.52, 0.45, 0.40, 0.35, 0.29, 0.23, 0.18],
                            [0.14, 0.22, 0.34, 0.48, 0.59, 0.65, 0.65, 0.59, 0.50, 0.43, 0.36, 0.28, 0.22]]
  
  
    # Hourly cooling load factor (CLF) for windows WITH an internal shade taken from 
    # ASHRAE HOF Ch.26 Table 39 (subset of data in MJ8 Table A11-6)
    # Surface Azimuth = 0 (South), 22.5, 45.0, ... ,337.5,360 and Hour = 8,9, ... ,19,20
    mj8.clf_hr_is = [[0.23, 0.38, 0.58, 0.75, 0.83, 0.80, 0.68, 0.50, 0.35, 0.27, 0.19, 0.11, 0.09],
                          [0.18, 0.22, 0.27, 0.43, 0.63, 0.78, 0.84, 0.80, 0.66, 0.46, 0.25, 0.13, 0.11],
                          [0.14, 0.16, 0.19, 0.22, 0.38, 0.59, 0.75, 0.83, 0.81, 0.69, 0.45, 0.16, 0.12],
                          [0.12, 0.14, 0.16, 0.17, 0.23, 0.44, 0.64, 0.78, 0.84, 0.78, 0.55, 0.16, 0.12],
                          [0.11, 0.13, 0.15, 0.16, 0.17, 0.31, 0.53, 0.72, 0.82, 0.81, 0.61, 0.16, 0.12],
                          [0.12, 0.14, 0.16, 0.17, 0.18, 0.22, 0.43, 0.65, 0.80, 0.84, 0.66, 0.16, 0.12],
                          [0.14, 0.17, 0.19, 0.20, 0.21, 0.22, 0.30, 0.52, 0.73, 0.82, 0.69, 0.16, 0.12],
                          [0.22, 0.26, 0.30, 0.32, 0.33, 0.34, 0.34, 0.39, 0.61, 0.82, 0.76, 0.17, 0.12],
                          [0.65, 0.73, 0.80, 0.86, 0.89, 0.89, 0.86, 0.82, 0.75, 0.78, 0.91, 0.24, 0.18],
                          [0.62, 0.42, 0.37, 0.37, 0.37, 0.36, 0.35, 0.32, 0.28, 0.23, 0.17, 0.08, 0.07],
                          [0.74, 0.58, 0.37, 0.29, 0.27, 0.26, 0.24, 0.22, 0.20, 0.16, 0.12, 0.06, 0.05],
                          [0.80, 0.71, 0.52, 0.31, 0.26, 0.24, 0.22, 0.20, 0.18, 0.15, 0.11, 0.06, 0.05],
                          [0.80, 0.76, 0.62, 0.41, 0.27, 0.24, 0.22, 0.20, 0.17, 0.14, 0.11, 0.06, 0.05],
                          [0.79, 0.80, 0.72, 0.54, 0.34, 0.27, 0.24, 0.21, 0.19, 0.15, 0.12, 0.07, 0.06],
                          [0.74, 0.81, 0.79, 0.68, 0.49, 0.33, 0.28, 0.25, 0.22, 0.18, 0.13, 0.08, 0.07],
                          [0.54, 0.72, 0.81, 0.81, 0.71, 0.54, 0.38, 0.32, 0.27, 0.22, 0.16, 0.09, 0.08],
                          [0.23, 0.38, 0.58, 0.75, 0.83, 0.80, 0.68, 0.50, 0.35, 0.27, 0.19, 0.11, 0.09]]
  
    # Shade Line Multipliers (SLM) for shaded windows will be calculated using the procedure 
    # described in ASHRAE HOF 1997 instead of using the SLM's from MJ8 Table 3E-1
  
    # The time of day (assuming 24 hr clock) to calculate the SLM for the ALP for azimuths 
    # starting at 0 (South) in increments of 22.5 to 360
    # NA denotes directions not used in the shading calculation (Note: south direction is symmetrical around noon)
    mj8.slm_alp_hr = [15.5, 14.75, 14, 14.75, 15.5, nil, nil, nil, nil, nil, nil, nil, 8.5, 9.75, 10, 9.75, 8.5]
  
    # Mid summer declination angle used for shading calculations
    mj8.declination_angle = 12.1  # Mid August
  
    # Base Cooling Load Temperature Differences (CLTD's) for dark colored sunlit and shaded walls 
    # with 95 degF outside temperature taken from MJ8 Figure A12-8 (intermediate wall groups were 
    # determined using linear interpolation). Shaded walls apply to north facing and partition walls only.
    mj8.cltd_base_sun = [38, 34.95, 31.9, 29.45, 27, 24.5, 22, 21.25, 20.5, 19.65, 18.8]
    mj8.cltd_base_shade = [25, 22.5, 20, 18.45, 16.9, 15.45, 14, 13.55, 13.1, 12.85, 12.6]
  
    # CLTD adjustments based on daily temperature range
    mj8.daily_range_temp_adjust = [4, 0, -5]
  
    # Altitude Correction Factors (ACF) taken from Table 10A (sea level - 12,000 ft)
    mj8.acfs = [1.0, 0.97, 0.93, 0.89, 0.87, 0.84, 0.80, 0.77, 0.75, 0.72, 0.69, 0.66, 0.63]
    
    # Wetbulb temperatures for 75degF DB and 50% RH (using lookup tables since WB calculations 
    # involve iteration) (sea level - 12,000 ft)
    mj8.Wetbulb_75DB_50RH = [62.6, 62.4, 62.3, 62.1, 61.9, 61.8, 61.6, 61.5, 61.3, 61.1, 61.0, 60.8, 60.7]
    
    # Wetbulb temperatures for 75degF DB and 60% RH (using lookup tables since WB calculations 
    # involve iteration) (sea level - 12,000 ft)
    mj8.Wetbulb_75DB_60RH = [65.3, 65.2, 65.1, 65.0, 64.9, 64.7, 64.6, 64.5, 64.4, 64.3, 64.2, 64.1, 64.0]
    
    # Stack Coefficient (Cs) for infiltration calculation taken from Table 5D
    # Wind Coefficient (Cw) for Shielding Classes 1-5 for infiltration calculation taken from Table 5D
    # Coefficients converted to regression equations to allow for more than 3 stories
    mj8.Cs = 0.015 * building_num_stories
    shelter_class = get_shelter_class(model, unit)
    if shelter_class == 1
        mj8.Cw = 0.0119 * building_num_stories ** 0.4
    elsif shelter_class == 2
        mj8.Cw = 0.0092 * building_num_stories ** 0.4
    elsif shelter_class == 3
        mj8.Cw = 0.0065 * building_num_stories ** 0.4
    elsif shelter_class == 4
        mj8.Cw = 0.0039 * building_num_stories ** 0.4
    elsif shelter_class == 5
        mj8.Cw = 0.0012 * building_num_stories ** 0.4
    else
        runner.registerError('Invalid shelter_class: {}'.format(shelter_class))
    end
    
    return mj8

  end
  
  def processSiteCalcs(runner, model, unit, mj8, weather, nbeds)
    '''
    Site Calculations
    '''
    
    return nil if mj8.nil?
    
    # Calculate number of occupants based on Section 22-3
    mj8.n_occupants = nbeds + 1
    
    # Manual J inside conditions
    mj8.cooling_setpoint = 75
    mj8.heating_setpoint = 70
    
    heat_design_db = weather.design.HeatingDrybulb
    cool_design_db = weather.design.CoolingDrybulb
    dehum_design_db = weather.design.DehumidDrybulb
           
    mj8.cool_design_grains = UnitConversion.lbm_lbm2grains(weather.design.CoolingHumidityRatio)
    mj8.dehum_design_grains = UnitConversion.lbm_lbm2grains(weather.design.DehumidHumidityRatio)
    
    # # Calculate the design temperature differences
    mj8.ctd = cool_design_db - mj8.cooling_setpoint
    mj8.htd = mj8.heating_setpoint - heat_design_db
    mj8.dtd = dehum_design_db - mj8.cooling_setpoint
    
    # # Calculate the average Daily Temperature Range (DTR) to determine the class (low, medium, high)
    dtr = weather.design.DailyTemperatureRange
    
    if dtr < 16
        mj8.daily_range_num = 0   # Low
    elsif dtr > 25
        mj8.daily_range_num = 2   # High
    else
        mj8.daily_range_num = 1   # Medium
    end
        
    # Calculate the altitude correction factor (ACF) for the site
    alt_cnt = (weather.header.Altitude / 1000.0).to_i
    mj8.acf = MathTools.interp2(weather.header.Altitude, alt_cnt * 1000, (alt_cnt + 1) * 1000, mj8.acfs[alt_cnt], mj8.acfs[alt_cnt + 1])
    
    # Calculate the interior humidity in Grains and enthalpy in Btu/lb for cooling
    pwsat = OpenStudio::convert(0.430075, "psi", "kPa").get   # Calculated for 75degF indoor temperature
    rh_indoor_cooling = 0.55 # Manual J is vague on the indoor RH. 55% corresponds to BA goals
    hr_indoor_cooling = (0.62198 * rh_indoor_cooling * pwsat) / (UnitConversion.atm2kPa(weather.header.LocalPressure) - rh_indoor_cooling * pwsat)
    mj8.grains_indoor_cooling = UnitConversion.lbm_lbm2grains(hr_indoor_cooling)
    mj8.wetbulb_indoor_cooling = Psychrometrics.Twb_fT_R_P(mj8.cooling_setpoint, rh_indoor_cooling, UnitConversion.atm2psi(weather.header.LocalPressure))        
    
    db_indoor_degC = OpenStudio::convert(mj8.cooling_setpoint, "F", "C").get
    mj8.enthalpy_indoor_cooling = (1.006 * db_indoor_degC + hr_indoor_cooling * (2501 + 1.86 * db_indoor_degC)) * OpenStudio::convert(1.0, "kJ", "Btu").get * OpenStudio::convert(1.0, "lb", "kg").get
    
    # Calculate the interior humidity in Grains and enthalpy in Btu/lb for dehumidification
    mj8.RH_indoor_dehumid = 0.60
    hr_indoor_dehumid = (0.62198 * mj8.RH_indoor_dehumid * pwsat) / (UnitConversion.atm2kPa(weather.header.LocalPressure) - mj8.RH_indoor_dehumid * pwsat)
    mj8.grains_indoor_dehumid = UnitConversion.lbm_lbm2grains(hr_indoor_dehumid)
    mj8.wetbulb_indoor_dehumid = Psychrometrics.Twb_fT_R_P(mj8.cooling_setpoint, mj8.RH_indoor_dehumid, UnitConversion.atm2psi(weather.header.LocalPressure))
        
    # Determine the PSF's for the building latitude
    mj8.psf_lat = []
    latitude = weather.header.Latitude.to_f
    for cnt in 0..16
        if latitude < 20.0
            mj8.psf_lat << mj8.psf[cnt][0]
            if cnt == 0
                runner.registerWarning('Latitude of 20 was assumed for Manual J solar load calculations.')
            end
        elsif latitude > 64.0
            mj8.psf_lat << mj8.psf[cnt][11]
            if cnt == 0
                runner.registerWarning('Latitude of 64 was assumed for Manual J solar load calculations.')
            end
        else
            cnt_lat_s = ((latitude - 20.0) / 4.0).to_i
            cnt_lat_n = cnt_lat_s + 1
            lat_s = 20 + 4 * cnt_lat_s
            lat_n = lat_s + 4
            mj8.psf_lat << MathTools.interp2(latitude, lat_s, lat_n, mj8.psf[cnt][cnt_lat_s], mj8.psf[cnt][cnt_lat_n])
        end
    end
            
    return mj8
    
  end
  
  def processDesignTemps(runner, model, unit, mj8, weather)
    
    return nil if mj8.nil?
    
    mj8.cool_design_temps = {}
    mj8.heat_design_temps = {}
    mj8.dehum_design_temps = {}
    
    # Initialize Manual J buffer space temperatures using current design temperatures
    unit.spaces.each do |space|
        temps = {}
        if Geometry.space_is_finished(space)
            # Living space, finished attic, finished basement
            temps['heat'] = 70
            temps['cool'] = 75
            temps['dehum'] = 75
        elsif Geometry.get_garage_spaces(model.getSpaces, model).include?(space)
            # Garage
            temps['heat'] = weather.design.HeatingDrybulb + 13
            temps['cool'] = weather.design.CoolingDrybulb + 7
            temps['dehum'] = weather.design.DehumidDrybulb + 7
        elsif Geometry.get_unfinished_basement_spaces(model.getSpaces).include?(space)
            # Unfinished basement
            temps['heat'] = 55 # FIXME: (ub.CeilingUA * living_heat_temp + (ub.WallUA + ub.FloorUA) * min(self.ground_temps) + ub.InfUA * heat_db) / ub.OverallUA
            temps['cool'] = 55 # FIXME: (ub.CeilingUA * living_space.cool_design_temp + (ub.WallUA + ub.FloorUA) * max(self.ground_temps) + ub.InfUA * cool_design_db) / ub.OverallUA
            temps['dehum'] = 55 # FIXME: (ub.CeilingUA * living_space.dehum_design_temp + (ub.WallUA + ub.FloorUA) * min(self.ground_temps) + ub.InfUA * dehum_design_db) / ub.OverallUA
        elsif Geometry.get_crawl_spaces(model.getSpaces).include?(space)
            # Crawlspace
            temps['heat'] = 55 # FIXME: (cs.CeilingUA * living_heat_temp + (cs.WallUA + cs.FloorUA) * min(self.ground_temps) + cs.InfUA * heat_db) / cs.OverallUA
            temps['cool'] = 55 # FIXME: (cs.CeilingUA * living_space.cool_design_temp + (cs.WallUA + cs.FloorUA) * max(self.ground_temps) + cs.InfUA * cool_design_db) / cs.OverallUA
            temps['dehum'] = 55 # FIXME: (cs.CeilingUA * living_space.dehum_design_temp + (cs.WallUA + cs.FloorUA) * min(self.ground_temps) + cs.InfUA * dehum_design_db) / cs.OverallUA
        elsif Geometry.get_pier_beam_spaces(model.getSpaces).include?(space)
            # Pier & beam
            temps['heat'] = weather.design.HeatingDrybulb
            temps['cool'] = weather.design.CoolingDrybulb
            temps['dehum'] = weather.design.DehumidDrybulb
        elsif Geometry.get_unfinished_attic_spaces(model.getSpaces, model).include?(space)
            # Unfinished attic (Based on EnergyGauge USA)
            attic_is_vented = true # FIXME
            attic_temp_rise = 40 # This is the number from a California study with dark shingle roof and similar ventilation.
            if attic_is_vented
                temps['heat'] = weather.design.HeatingDrybulb
                temps['cool'] = weather.design.CoolingDrybulb + attic_temp_rise
                temps['dehum'] = weather.design.DehumidDrybulb
            else
                temps['heat'] = 70 # FIXME: (ua.AtticLivingUA * living_heat_temp + ua.AtticOutsideUA * heat_db) / (ua.AtticLivingUA + ua.AtticOutsideUA)
                temps['cool'] = 75 # FIXME: (ua_max_cooling_design_temp - ua_percent_ua_from_ceiling * (ua_max_cooling_design_temp - ua_min_cooling_design_temp))
                temps['dehum'] = 75 # FIXME: (ua.AtticLivingUA * living_space.dehum_design_temp + ua.AtticOutsideUA * dehum_design_db) / (ua.AtticLivingUA + ua.AtticOutsideUA)
            end
        else
            runner.registerError("Unexpected space '#{space.name.to_s}' in get_space_design_temps.")
            return nil
        end
        mj8.cool_design_temps[space] = temps['cool']
        mj8.heat_design_temps[space] = temps['heat']
        mj8.dehum_design_temps[space] = temps['dehum']
    end
            
    # # FIXME: Calculate the cooling design temperature for the garage
    # # TODO: Only do if unit is adjacent to garage
    # if simpy.hasSpaceType(geometry, Constants.SpaceGarage):
        # #---Garage Design Temp
        # garage = sim._getSpace(Constants.SpaceGarage)
        # garage_area_under_living = 0
        # garage_area_under_attic = 0
        
        # for floor in geometry.floors.floor:
            # space_above = sim._getSpace(floor.space_above_id)
            # space_below = sim._getSpace(floor.space_below_id)
            # if space_below.spacetype == Constants.SpaceGarage and \
              # (space_above.spacetype == Constants.SpaceLiving or space_above.spacetype == Constants.SpaceFinAttic):
                # garage_area_under_living += floor.area
            # if space_below.spacetype == Constants.SpaceGarage and space_above.spacetype == Constants.SpaceUnfinAttic:
                # garage_area_under_attic += floor.area

        # for roof in geometry.roofs.roof:
            # if sim._getSpace(roof.space_below_id).spacetype == Constants.SpaceGarage:
                # garage_area_under_attic += roof.area * Math::cos(roof.tilt.degrees)  

        # garage_area_mj8 = garage_area_under_living + garage_area_under_attic

        # # Calculate the garage cooling design temperature based on Table 4C
        # # Linearly interpolate between having living space over the garage and not having living space above the garage
        # if mj8.daily_range_num == 0:
            # garage.cool_design_temp_mj8 = (weather.design.CoolingDrybulb + 
                                           # (11 * garage_area_under_living / garage_area_mj8) + 
                                           # (22 * garage_area_under_attic / garage_area_mj8))
        # elif mj8.daily_range_num == 1:
            # garage.cool_design_temp_mj8 = (weather.design.CoolingDrybulb + 
                                           # (6 * garage_area_under_living / garage_area_mj8) + 
                                           # (17 * garage_area_under_attic / garage_area_mj8))
        # else:
            # garage.cool_design_temp_mj8 = (weather.design.CoolingDrybulb + 
                                           # (1 * garage_area_under_living / garage_area_mj8) + 
                                           # (12 * garage_area_under_attic / garage_area_mj8))


    # # FIXME: Calculate the cooling design temperature for the unfinished attic based on Figure A12-14
    # if simpy.hasSpaceType(geometry, Constants.SpaceUnfinAttic):
        # #---Unfinished Attic Design Temp
        # unfinished_attic = sim._getSpace(Constants.SpaceUnfinAttic)
        
        # if sim.unfinished_attic.UACeilingInsRvalueNominal_Rev < sim.unfinished_attic.UARoofInsRvalueNominal:                
            
            # # Attic is considered to be encapsulated. MJ8 says to use an attic 
            # # temperature of 95F, however alternative approaches are permissible
            # unfinished_attic.cool_design_temp_mj8 = unfinished_attic.cool_design_temp
            # unfinished_attic.heat_design_temp_mj8 = unfinished_attic.heat_design_temp
            # unfinished_attic.dehum_design_temp_mj8 = unfinished_attic.dehum_design_temp_mj8
        
        # else:
            # unfinished_attic.heat_design_temp_mj8 = heat_design_db
            # unfinished_attic.dehum_design_temp_mj8 = dehum_design_db
            
            # if sim.unfinished_attic.UASLA < Constants.AtticIsVentedMinSLA:
                # if not sim.radiant_barrier.HasRadiantBarrier:
                    # unfinished_attic.cool_design_temp_mj8 = 150 + (cool_design_db - 95) + mj8.daily_range_temp_adjust[mj8.daily_range_num]
                # else:
                    # unfinished_attic.cool_design_temp_mj8 = 130 + (cool_design_db - 95) + mj8.daily_range_temp_adjust[mj8.daily_range_num]
                
            # else:
                
                # if not sim.radiant_barrier.HasRadiantBarrier:
                    # if sim.roofing_material.RoofMatDescription == Constants.RoofMaterialAsphalt or \
                        # sim.roofing_material.RoofMatDescription == Constants.RoofMaterialTarGravel:
                        # if sim.roofing_material.RoofMatColor == Constants.ColorDark:
                            # unfinished_attic.cool_design_temp_mj8 = 130
                        # else:
                            # unfinished_attic.cool_design_temp_mj8 = 120
                    
                    # elif sim.roofing_material.RoofMatDescription == Constants.RoofMaterialWoodShakes:
                        # unfinished_attic.cool_design_temp_mj8 = 120
                        
                    # elif sim.roofing_material.RoofMatDescription == Constants.RoofMaterialMetal or \
                        # sim.roofing_material.RoofMatDescription == Constants.RoofMaterialMembrane:
                        # if sim.roofing_material.RoofMatColor == Constants.ColorDark:
                            # unfinished_attic.cool_design_temp_mj8 = 130
                        # elif sim.roofing_material.RoofMatColor == Constants.ColorWhite:
                            # unfinished_attic.cool_design_temp_mj8 = 95
                        # else:
                            # unfinished_attic.cool_design_temp_mj8 = 120
                            
                    # elif sim.roofing_material.RoofMatDescription == Constants.MaterialTile:
                        # if sim.roofing_material.RoofMatColor == Constants.ColorDark:
                            # unfinished_attic.cool_design_temp_mj8 = 110
                        # elif sim.roofing_material.RoofMatColor == Constants.ColorWhite:
                            # unfinished_attic.cool_design_temp_mj8 = 95
                        # else:
                            # unfinished_attic.cool_design_temp_mj8 = 105
                       
                    # else:
                        # SimWarning('Specified roofing material is not supported by BEopt Manual J calculations. Assuming dark asphalt shingles')
                        # unfinished_attic.cool_design_temp_mj8 = 130
                
                # else: # with a radiant barrier
                    # if sim.roofing_material.RoofMatDescription == Constants.RoofMaterialAsphalt or \
                        # sim.roofing_material.RoofMatDescription == Constants.RoofMaterialTarGravel:
                        # if sim.roofing_material.RoofMatColor == Constants.ColorDark:
                            # unfinished_attic.cool_design_temp_mj8 = 120
                        # else:
                            # unfinished_attic.cool_design_temp_mj8 = 110
                    
                    # elif sim.roofing_material.RoofMatDescription == Constants.RoofMaterialWoodShakes:
                        # unfinished_attic.cool_design_temp_mj8 = 110
                        
                    # elif sim.roofing_material.RoofMatDescription == Constants.RoofMaterialMetal or \
                        # sim.roofing_material.RoofMatDescription == Constants.RoofMaterialMembrane:
                        # if sim.roofing_material.RoofMatColor == Constants.ColorDark:
                            # unfinished_attic.cool_design_temp_mj8 = 120
                        # elif sim.roofing_material.RoofMatColor == Constants.ColorWhite:
                            # unfinished_attic.cool_design_temp_mj8 = 95
                        # else:
                            # unfinished_attic.cool_design_temp_mj8 = 110
                            
                    # elif sim.roofing_material.RoofMatDescription == Constants.MaterialTile:
                        # if sim.roofing_material.RoofMatColor == Constants.ColorDark:
                            # unfinished_attic.cool_design_temp_mj8 = 105
                        # elif sim.roofing_material.RoofMatColor == Constants.ColorWhite:
                            # unfinished_attic.cool_design_temp_mj8 = 95
                        # else:
                            # unfinished_attic.cool_design_temp_mj8 = 105
                       
                    # else:
                        # SimWarning('Specified roofing material is not supported by BEopt Manual J calculations. Assuming dark asphalt shingles')
                        # unfinished_attic.cool_design_temp_mj8 = 120
            
            # # Adjust base CLTD for cooling design temperature and daily range
            # unfinished_attic.cool_design_temp_mj8 += (cool_design_db - 95) + mj8.daily_range_temp_adjust[mj8.daily_range_num]
            
    return mj8
  end
  
  def processCoolingLoadWindows(runner, model, unit, mj8, weather, unit_surfaces, has_IntGains_shade, windowHasOverhang, overhangDepth, overhangOffset, windowHeight)
    '''
    Cooling Load: Windows
    '''
    
    return nil if mj8.nil?
    
    alp_load = 0 # Average Load Procedure (ALP) Load
    afl_hr = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # Initialize Hourly Aggregate Fenestration Load (AFL)
    
    unit_surfaces['living_walls_exterior'].each do |wall|
        # FIXME: Need to include north axis?
        cnt225 = (wall.azimuth / 22.5).to_i
        
        wall.subSurfaces.each do |window|
            next if not window.subSurfaceType.downcase.include?("window")
            
            # U-value
            u_window = get_surface_uvalue(runner, window, window.subSurfaceType)
            return nil if u_window.nil?
            
            # SHGC & Internal Shading
            shgc_with_IntGains_shade_cool, shgc_with_IntGains_shade_heat = get_window_shgc(runner, window)
            
            for hr in 0..12
    
                # If hr == 0: Calculate the Average Load Procedure (ALP) Load
                # Else: Calculate the hourly Aggregate Fenestration Load (AFL)
                
                if hr == 0
                    if has_IntGains_shade
                        # Average Cooling Load Factor for the given window direction
                        clf_d = mj8.clf_avg_is[cnt225]
                        #Average Cooling Load Factor for a window facing North (fully shaded)
                        clf_n = mj8.clf_avg_is[8]
                    else
                        # Average Cooling Load Factor for the given window direction
                        clf_d = mj8.clf_avg_nois[cnt225]
                        #Average Cooling Load Factor for a window facing North (fully shaded)
                        clf_n = mj8.clf_avg_nois[8]
                    end
                else
                    if has_IntGains_shade
                        # Average Cooling Load Factor for the given window Direction
                        clf_d = mj8.clf_hr_is[cnt225][hr]
                        # Average Cooling Load Factor for a window facing North (fully shaded)
                        clf_n = mj8.clf_hr_is[8][hr]
                    else
                        # Average Cooling Load Factor for the given window Direction
                        clf_d = mj8.clf_hr_nois[cnt225][hr]
                        # Average Cooling Load Factor for a window facing North (fully shaded)
                        clf_n = mj8.clf_hr_nois[8][hr]
                    end
                end
        
                # Hourly Heat Transfer Multiplier for the given window Direction
                htm_d = mj8.psf_lat[cnt225] * clf_d * shgc_with_IntGains_shade_cool / 0.87 + u_window * mj8.ctd
        
                # Hourly Heat Transfer Multiplier for a window facing North (fully shaded)
                htm_n = mj8.psf_lat[8] * clf_n * shgc_with_IntGains_shade_cool / 0.87 + u_window * mj8.ctd
               
                surf_azimuth = wall.azimuth # FIXME
               
                # TODO: Account for eaves, porches, etc.
                if windowHasOverhang
                    hour_angle = 0.25 * ((hr + 8) - 12) * 60 # ASHRAE HOF 1997 pg 29.19 (start at hour 8)
                    altitude_angle = (Math::asin((Math::cos(weather.header.Latitude.degrees) * 
                                                  Math::cos(mj8.declination_angle.degrees) * 
                                                  Math::cos(hour_angle.degrees) + 
                                                  Math::sin(weather.header.Latitude.degrees) * 
                                                  Math::sin(mj8.declination_angle.degrees)).degrees))
                    temp_arg = [(Math::sin(altitude_angle.degrees) * 
                                 Math::sin(weather.header.Latitude.degrees) - 
                                 Math::sin(mj8.declination_angle.degrees)) / 
                                (Math::cos(altitude_angle.degrees) * 
                                 Math::cos(weather.header.Latitude.degrees)), 1.0].min
                    temp_arg = [temp_arg, -1.0].max
                    solar_azimuth = Math::acos(temp_arg.degrees)

                    if (hr > 0 and (hr + 8) < 12) or (hr == 0 and mj8.slm_alp_hr[cnt225] < 12)
                        solar_azimuth = -1.0 * solar_azimuth
                    end

                    sol_surf_azimuth = solar_azimuth - surf_azimuth

                    if sol_surf_azimuth.abs >= 90 and sol_surf_azimuth.abs <= 270
                        # Window is entirely in the shade if the solar surface azimuth is greater than 90 and less than 270
                        htm = htm_n
                    else
                        slm = Math::tan(altitude_angle.degrees) / Math::cos(sol_surf_azimuth.degrees)
                        z_sl = slm * overhangDepth

                        if z_sl < overhangOffset
                            # Overhang is too short to provide shade
                            htm = htm_d
                        elsif z_sl < (overhangOffset + windowHeight)
                            percent_shaded = (z_sl - overhangOffset) / windowHeight
                            htm = percent_shaded * htm_n + (1 - percent_shaded) * htm_d
                        else
                            # Window is entirely in the shade since the shade line is below the windowsill
                            htm = htm_n
                        end
                    end
                    
                else
                    htm = htm_d
                end

                if hr == 0
                    alp_load = alp_load + htm * window.grossArea
                else
                    afl_hr[hr] = afl_hr[hr] + htm * window.grossArea
                end
            end
        end # window
    end # wall

    # Daily Average Load (DAL)
    dal = afl_hr.inject{ |sum, n| sum + n } / afl_hr.size

    # Excursion Limit line (ELL)
    ell = 1.3 * dal

    # Peak Fenestration Load (PFL)
    pfl = afl_hr.max

    # Excursion Adjustment Load (EAL)
    eal = [0, pfl - ell].max

    # Window Cooling Load
    mj8.CoolingLoad_Windows = alp_load + eal
    
    return mj8
  end
  
  def processCoolingLoadDoors(runner, model, unit, mj8, weather, unit_surfaces)
    '''
    Cooling Load: Doors
    '''
    
    return nil if mj8.nil?
    
    if mj8.daily_range_num == 0
        cltd_Door = mj8.ctd + 15
    elsif mj8.daily_range_num == 1
        cltd_Door = mj8.ctd + 11
    else
        cltd_Door = mj8.ctd + 6
    end

    mj8.CoolingLoad_Doors = 0

    unit_surfaces['living_walls_exterior'].each do |wall|
        wall.subSurfaces.each do |door|
            next if not door.subSurfaceType.downcase.include?("door")
            door_uvalue = get_surface_uvalue(runner, door, door.subSurfaceType)
            return nil if door_uvalue.nil?
            mj8.CoolingLoad_Doors += door_uvalue * door.grossArea * cltd_Door
        end
    end
    
    return mj8
  end
  
  def processCoolingLoadWalls(runner, model, unit, mj8, weather, unit_surfaces, wall_type, finishDensity, finishAbsorptivity, wallSheathingContInsRvalue, wallSheathingContInsThickness, wallCavityInsRvalueInstalled, sipInsThickness, cmuFurringInsRvalue)
    '''
    Cooling Load: Walls
    '''
    
    return nil if mj8.nil?
    
    cool_design_db = weather.design.CoolingDrybulb
    
    # Determine the wall Group Number (A - K = 1 - 11) for exterior walls (ie. all walls except basement walls)
    maxWallGroup = 11
    
    # The following correlations were estimated by analyzing MJ8 construction tables. This is likely a better
    # approach than including the Group Number.
    if ['Constants.WallTypeWoodStud', 'Constants.WallTypeSteelStud'].include?(wall_type)
        wallGroup = get_wallgroup_wood_or_steel_stud(wallCavityInsRvalueInstalled)
        # Adjust the base wall group for rigid foam insulation
        if wallSheathingContInsRvalue > 1 and wallSheathingContInsRvalue <= 7
            if wallCavityInsRvalueInstalled < 2
                wallGroup = wallGroup + 2
            else
                wallGroup = wallGroup + 4
            end
        elsif wallSheathingContInsRvalue > 7
            if wallCavityInsRvalueInstalled < 2
                wallGroup = wallGroup + 4
            else
                wallGroup = wallGroup + 6
            end
        end
        #Assume brick if the outside finish density is >= 100 lb/ft^3
        if finishDensity >= 100
            if wallCavityInsRvalueInstalled < 2
                wallGroup = wallGroup + 4
            else
                wallGroup = wallGroup + 6
            end
        end
    elsif wall_type == 'Constants.WallTypeDoubleStud'
        wallGroup = 10     # J (assumed since MJ8 does not include double stud constructions)
        if finishDensity >= 100
            wallGroup = 11  # K
        end
    elsif wall_type == 'Constants.WallTypeSIP'
        # Manual J refers to SIPs as Structural Foam Panel (SFP)
        if sipInsThickness + wallSheathingContInsThickness < 4.5
            wallGroup = 7   # G
        elsif sipInsThickness + wallSheathingContInsThickness < 6.5
            wallGroup = 9   # I
        else
            wallGroup = 11  # K
        end
        if finishDensity >= 100
            wallGroup = wallGroup + 3
        end
    elsif wall_type == 'Constants.WallTypeCMU'
        # Manual J uses the same wall group for filled or hollow block
        if cmuFurringInsRvalue < 2
            wallGroup = 5   # E
        elsif cmuFurringInsRvalue <= 11
            wallGroup = 8   # H
        elsif cmuFurringInsRvalue <= 13
            wallGroup = 9   # I
        elsif cmuFurringInsRvalue <= 15
            wallGroup = 9   # I
        elsif cmuFurringInsRvalue <= 19
            wallGroup = 10  # J
        elsif cmuFurringInsRvalue <= 21
            wallGroup = 11  # K
        else
            wallGroup = 11  # K
        end
        # This is an estimate based on Table 4A - Construction Number 13
        wallGroup = wallGroup + (wallSheathingContInsRvalue / 3.0).floor # Group is increased by approximately 1 letter for each R3
    elsif wall_type == 'Constants.WallTypeICF'
        wallGroup = 11  # K
    elsif wall_type == 'Constants.WallTypeMisc'
        # Assume Wall Group K since 'Other' Wall Type is likely to have a high thermal mass
        wallGroup = 11  # K
    else
        runner.registerError('Wall type #{walL_type} not found.')
        return nil
    end

    # Maximum wall group is K
    wallGroup = [wallGroup, maxWallGroup].min

    # Adjust base Cooling Load Temperature Difference (CLTD)
    # Assume absorptivity for light walls < 0.5, medium walls <= 0.75, dark walls > 0.75 (based on MJ8 Table 4B Notes)

    if finishAbsorptivity <= 0.5
        colorMultiplier = 0.65      # MJ8 Table 4B Notes, pg 348
    elsif finishAbsorptivity <= 0.75
        colorMultiplier = 0.83      # MJ8 Appendix 12, pg 519
    else
        colorMultiplier = 1.0
    end
    
    cltd_Wall_Sun = mj8.cltd_base_sun[wallGroup - 1] * colorMultiplier
    cltd_Wall_Shade = mj8.cltd_base_shade[wallGroup - 1] * colorMultiplier

    if mj8.ctd >= 10
        # Adjust the CLTD for different cooling design temperatures
        cltd_Wall_Sun = cltd_Wall_Sun + (cool_design_db - 95)
        cltd_Wall_Shade = cltd_Wall_Shade + (cool_design_db - 95)

        # Adjust the CLTD for daily temperature range
        cltd_Wall_Sun = cltd_Wall_Sun + mj8.daily_range_temp_adjust[mj8.daily_range_num]
        cltd_Wall_Shade = cltd_Wall_Shade + mj8.daily_range_temp_adjust[mj8.daily_range_num]
    else
        # Handling cases ctd < 10 is based on A12-18 in MJ8
        cltd_corr = mj8.ctd - 20 - mj8.daily_range_temp_adjust[mj8.daily_range_num]

        cltd_Wall_Sun = [cltd_Wall_Sun + cltd_corr, 0].max       # Assume zero cooling load for negative CLTD's
        cltd_Wall_Shade = [cltd_Wall_Shade + cltd_corr, 0].max     # Assume zero cooling load for negative CLTD's
    end

    mj8.CoolingLoad_Walls = 0
    mj8.gable_ua = 0 # UA of the gables

    unit_surfaces['living_walls_exterior'].each do |wall|
        wall_uvalue = get_surface_uvalue(runner, wall, wall.surfaceType)
        return nil if wall_uvalue.nil?
        if wall.azimuth >= 157.5 and wall.azimuth <= 202.5
            mj8.CoolingLoad_Walls += cltd_Wall_Shade * wall_uvalue * wall.netArea
        else
            mj8.CoolingLoad_Walls += cltd_Wall_Sun * wall_uvalue * wall.netArea
        end
    end

    unit_surfaces['living_walls_interzonal'].each do |wall|
        #Accounts for garage walls and knee walls; basement walls are neglected
        wall_uvalue = get_surface_uvalue(runner, wall, wall.surfaceType)
        return nil if wall_uvalue.nil?
        adjacent_space = wall.adjacentSurface.get.space.get
        mj8.CoolingLoad_Walls += (wall_uvalue * wall.netArea * (mj8.cool_design_temps[adjacent_space] - mj8.cooling_setpoint))
    end
        
    # FIXME: Need to handle gable walls
        # elif (space_int.spacetype == Constants.SpaceUnfinAttic and
              # space_ext.spacetype == Constants.SpaceOutside):
            # # Need to sum the gable UA for attic temperature iteration
            # mj8.gable_ua += (wall.surface_type.Uvalue * wall.net_area) 
            
    return mj8
  end
  
  def processCoolingLoadCeilings(runner, model, unit, mj8, weather, unit_surfaces, finishedRoofTotalR, fRRoofContInsThickness, roofMatColor, roofMatDescription)
    '''
    Cooling Load: Ceilings
    '''
    
    return nil if mj8.nil?
    
    cool_design_db = weather.design.CoolingDrybulb
    
    cltd_FinishedRoof = 0

    if unit_surfaces['living_roofs_exterior'].size > 0
        
        if fRRoofContInsThickness > 0
            finishedRoofTotalR = finishedRoofTotalR + fRRoofContInsThickness
        end

        # Base CLTD for finished roofs (Roof-Joist-Ceiling Sandwiches) taken from MJ8 Figure A12-16
        if finishedRoofTotalR <= 6
            cltd_FinishedRoof = 50
        elsif finishedRoofTotalR <= 13
            cltd_FinishedRoof = 45
        elsif finishedRoofTotalR <= 15
            cltd_FinishedRoof = 38
        elsif finishedRoofTotalR <= 21
            cltd_FinishedRoof = 31
        elsif finishedRoofTotalR <= 30
            cltd_FinishedRoof = 30
        else
            cltd_FinishedRoof = 27
        end

        # Base CLTD color adjustment based on notes in MJ8 Figure A12-16
        if roofMatColor == 'Constants.ColorDark'
            if ['Constants.MaterialTile', 'Constants.RoofMaterialWoodShakes'].include?(roofMatDescription)
                cltd_FinishedRoof = cltd_FinishedRoof * 0.83
            end
        elsif ['Constants.ColorMedium', 'Constants.ColorLight'].include?(roofMatColor)
            if roofMatDescription == 'Constants.MaterialTile'
                cltd_FinishedRoof = cltd_FinishedRoof * 0.65
            else
                cltd_FinishedRoof = cltd_FinishedRoof * 0.83
            end
        elsif roofMatColor == 'Constants.ColorWhite'
            if ['Constants.RoofMaterialAsphalt', 'Constants.RoofMaterialWoodShakes'].include?(roofMatDescription)
                cltd_FinishedRoof = cltd_FinishedRoof * 0.83
            else
                cltd_FinishedRoof = cltd_FinishedRoof * 0.65
            end
        end

        # Adjust base CLTD for different CTD or DR
        cltd_FinishedRoof = cltd_FinishedRoof + (cool_design_db - 95) + mj8.daily_range_temp_adjust[mj8.daily_range_num]
    end

    mj8.CoolingLoad_Roofs = 0
    unit_surfaces['living_roofs_exterior'].each do |roof|
        # Finished roofs
        roof_uvalue = get_surface_uvalue(runner, roof, roof.surfaceType)
        return nil if roof_uvalue.nil?
        mj8.CoolingLoad_Roofs += roof_uvalue * roof.netArea * cltd_FinishedRoof
    end
  
    return mj8
  end
  
  def processCoolingLoadFloors(runner, model, unit, mj8, weather, unit_surfaces)
    '''
    Cooling Load: Floors
    '''
    
    return nil if mj8.nil?
    
    mj8.CoolingLoad_Floors = 0

    unit_surfaces['living_floors_exterior'].each do |floor|
        # Cantilevered floor
        floor_uvalue = get_surface_uvalue(runner, floor, floor.surfaceType)
        return nil if floor_uvalue.nil?
        mj8.CoolingLoad_Floors += floor_uvalue * floor.netArea * (mj8.ctd - 5 + mj8.daily_range_temp_adjust[mj8.daily_range_num])
    end
    
    unit_surfaces['living_floors_interzonal'].each do |floor|
        # Interzonal floor
        floor_uvalue = get_surface_uvalue(runner, floor, floor.surfaceType)
        return nil if floor_uvalue.nil?
        adjacent_space = floor.adjacentSurface.get.space.get
        mj8.CoolingLoad_Floors += floor_uvalue * floor.netArea * (mj8.cool_design_temps[adjacent_space] - mj8.cooling_setpoint)
    end
                
    return mj8
  end
  
  def processInfiltrationVentilation(runner, model, unit, mj8, weather, infil_type, space_ela, space_inf_flow, mechVentType, whole_house_vent_rate, mechVentApparentSensibleEffectiveness, mechVentLatentEffectiveness, mechVentTotalEfficiency)
    '''
    Infiltration & Ventilation
    '''
    
    return nil if mj8.nil?
    
    dehumDesignWindSpeed = [weather.design.CoolingWindspeed, weather.design.HeatingWindspeed].max
    ft2in = OpenStudio::convert(1.0, "ft", "in").get
    mph2m_s = OpenStudio::convert(1.0, "mph", "m/s").get
    
    if infil_type == 'ach50'
        icfm_Cooling = space_ela * ft2in ** 2 * (mj8.Cs * mj8.ctd.abs + mj8.Cw * (weather.design.CoolingWindspeed / mph2m_s) ** 2) ** 0.5
        icfm_Heating = space_ela * ft2in ** 2 * (mj8.Cs * mj8.htd.abs + mj8.Cw * (weather.design.HeatingWindspeed / mph2m_s) ** 2) ** 0.5
        icfm_Dehumid = space_ela * ft2in ** 2 * (mj8.Cs * mj8.dtd.abs + mj8.Cw * (dehumDesignWindSpeed / mph2m_s) ** 2) ** 0.5
    elsif infil_type == 'ach'
        icfm_Cooling = space_inf_flow
        icfm_Heating = space_inf_flow
        icfm_Dehumid = space_inf_flow
    end

    q_unb, q_bal_Sens, q_bal_Lat, ventMultiplier = get_ventilation_rates(mechVentType, whole_house_vent_rate, mechVentApparentSensibleEffectiveness, mechVentLatentEffectiveness, mechVentTotalEfficiency)

    cfm_Cooling_Sens = q_bal_Sens + (icfm_Cooling ** 2 + ventMultiplier * (q_unb ** 2)).abs ** 0.5
    cfm_Cooling_Lat = q_bal_Lat + (icfm_Cooling ** 2 + ventMultiplier * (q_unb ** 2)).abs ** 0.5
    
    cfm_Dehumid_Sens = q_bal_Sens + (icfm_Dehumid ** 2 + ventMultiplier * (q_unb ** 2)).abs ** 0.5
    cfm_Dehumid_Lat = q_bal_Lat + (icfm_Dehumid ** 2 + ventMultiplier * (q_unb ** 2)).abs ** 0.5
    
    mj8.CoolingLoad_Infil_Sens = 1.1 * mj8.acf * cfm_Cooling_Sens * mj8.ctd
    mj8.CoolingLoad_Infil_Lat = 0.68 * mj8.acf * cfm_Cooling_Lat * (mj8.cool_design_grains - mj8.grains_indoor_cooling)
    
    mj8.DehumidLoad_Infil_Sens = 1.1 * mj8.acf * cfm_Dehumid_Sens * mj8.dtd
    mj8.DehumidLoad_Infil_Lat = 0.68 * mj8.acf * cfm_Dehumid_Lat * (mj8.dehum_design_grains - mj8.grains_indoor_dehumid)
    
    return mj8
  end
  
  def processInternalGains(runner, model, unit, mj8, weather)
    '''
    Internal Gains
    '''
    
    return nil if mj8.nil?
    
    int_Tot_Max = 0
    int_Lat_Max = 0
    
    # Plug loads, appliances, showers/sinks/baths, occupants, ceiling fans
    gains = []
    unit.spaces.each do |space|
        gains.push(*space.electricEquipment)
        gains.push(*space.gasEquipment)
        gains.push(*space.otherEquipment)
        gains.push(*space.people)
    end
    
    year = 2009
    if model.yearDescription.is_initialized
        year = model.yearDescription.get.assumedYear
    end
    start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('July'), 1, year)
    end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('July'), 2, year)

    int_Sens_Hr = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    int_Lat_Hr = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

    gains.each do |gain|
    
        sched = nil
        sensible_frac = nil
        latent_frac = nil
        design_level = nil
        
        if gain.is_a?(OpenStudio::Model::ElectricEquipment) or gain.is_a?(OpenStudio::Model::GasEquipment) or gain.is_a?(OpenStudio::Model::OtherEquipment)
            # Get design level
            if gain.is_a?(OpenStudio::Model::OtherEquipment)
                design_level_obj = gain.otherEquipmentDefinition
            else
                design_level_obj = gain
            end
            if not design_level_obj.designLevel.is_initialized
                runner.registerWarning("DesignLevel not provided for object '#{gain.name.to_s}'. Skipping...")
                next
            end
            design_level = design_level_obj.designLevel.get
            
            # Get schedule
            if not gain.schedule.is_initialized
                runner.registerError("Schedule not provided for object '#{gain.name.to_s}'. Skipping...")
                next
            end
            sched_base = gain.schedule.get
            if sched_base.name.to_s == model.alwaysOnDiscreteSchedule.name.to_s
                next # Skip our airflow dummy equipment objects
            elsif sched_base.to_ScheduleRuleset.is_initialized
                sched = sched_base.to_ScheduleRuleset.get
            elsif sched_base.to_ScheduleFixedInterval.is_initialized
                sched = sched_base.to_ScheduleFixedInterval.get
            else
                runner.registerWarning("Expected ScheduleRuleset or ScheduleFixedInterval for object '#{gain.name.to_s}'. Skipping...")
                next
            end
            
            # Get sensible/latent fractions
            if gain.is_a?(OpenStudio::Model::ElectricEquipment)
                sensible_frac = 1.0 - gain.electricEquipmentDefinition.fractionLost - gain.electricEquipmentDefinition.fractionLatent
                latent_frac = gain.electricEquipmentDefinition.fractionLatent
            elsif gain.is_a?(OpenStudio::Model::GasEquipment)
                sensible_frac = 1.0 - gain.gasEquipmentDefinition.fractionLost - gain.gasEquipmentDefinition.fractionLatent
                latent_frac = gain.gasEquipmentDefinition.fractionLatent
            elsif gain.is_a?(OpenStudio::Model::OtherEquipment)
                sensible_frac = 1.0 - gain.otherEquipmentDefinition.fractionLost - gain.otherEquipmentDefinition.fractionLatent
                latent_frac = gain.otherEquipmentDefinition.fractionLatent
            end
        
        elsif gain.is_a?(OpenStudio::Model::People)
            # Get design level
            if not gain.peopleDefinition.numberofPeople.is_initialized
                runner.registerWarning("NumberOfPeople not provided for object '#{gain.name.to_s}'. Skipping...")
                next
            end
            design_level = gain.peopleDefinition.numberofPeople.get
            
            # Get schedule
            if not gain.numberofPeopleSchedule.is_initialized
                runner.registerError("NumberOfPeopleSchedule not provided for object '#{gain.name.to_s}'. Skipping...")
                next
            end
            sched_base = gain.numberofPeopleSchedule.get
            if sched_base.to_ScheduleRuleset.is_initialized
                sched = sched_base.to_ScheduleRuleset.get
            elsif sched_base.to_ScheduleFixedInterval.is_initialized
                sched = sched_base.to_ScheduleFixedInterval.get
            else
                runner.registerWarning("Expected ScheduleRuleset or ScheduleFixedInterval for object '#{gain.name.to_s}'. Skipping...")
                next
            end
            
            # Get sensible/latent fractions
            if not gain.peopleDefinition.sensibleHeatFraction.is_initialized
                runner.registerWarning("SensibleHeatFraction not provided for object '#{gain.name.to_s}'. Skipping...")
                next
            end
            sensible_frac = gain.peopleDefinition.sensibleHeatFraction.get
            latent_frac = 1.0 - sensible_frac
        else
            runner.registerWarning("Unexpected type for object '#{gain.name.to_s}' in processInternalGains.")
            return nil
        end
        
        next if sched.nil? or sensible_frac.nil? or latent_frac.nil? or design_level.nil?

        # Get schedule hourly values
        if sched.is_a?(OpenStudio::Model::ScheduleRuleset)
            sched_values = sched.getDaySchedules(start_date, end_date)[0].values
        elsif sched.is_a?(OpenStudio::Model::ScheduleFixedInterval)
            sched_values_timestep = sched.timeSeries.values(OpenStudio::DateTime.new(start_date), OpenStudio::DateTime.new(end_date))
            # Aggregate into hourly values
            sched_values = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
            timesteps_per_hr = ((sched_values_timestep.size - 1) / 24).to_i
            for ts in 0..(sched_values_timestep.size - 2)
                hr = (ts / timesteps_per_hr).floor
                sched_values[hr] += sched_values_timestep[ts]
            end
        else
            runner.registerWarning("Unexpected type for object '#{sched.name.to_s}' in processInternalGains.")
            return nil
        end
        if sched_values.size != 24
            runner.registerWarning("Expected 24 DaySchedule values for object '#{gain.name.to_s}'. Skipping...")
            next
        end
        
        for hr in 0..23
            int_Sens_Hr[hr] += sched_values[hr] * design_level * sensible_frac
            int_Lat_Hr[hr] += sched_values[hr] * design_level * latent_frac
        end
    end
    
    # Store the sensible and latent loads associated with the hour of the maximum total load for cooling load calculations
    mj8.CoolingLoad_IntGains_Sens = int_Sens_Hr.max
    mj8.CoolingLoad_IntGains_Lat = int_Lat_Hr.max
    
    # Store the sensible and latent loads associated with the hour of the maximum latent load for dehumidification load calculations
    idx = int_Lat_Hr.each_with_index.max[1]
    mj8.DehumidLoad_IntGains_Sens = int_Sens_Hr[idx]
    mj8.DehumidLoad_IntGains_Lat = int_Lat_Hr[idx]
            
    return mj8
  end
  
  def processHeatingLoadConduction(runner, model, unit, mj8, weather, unit_surfaces, htd)
    '''
    Heating Load: Walls
    '''
    
    return nil if mj8.nil?
    
    heat_load = 0
    heat_load_fbsmt = 0

    # Exterior walls
    unit_surfaces['living_walls_exterior'].each do |wall|
        wall_uvalue = get_surface_uvalue(runner, wall, wall.surfaceType)
        return nil if wall_uvalue.nil?
        heat_load += wall_uvalue * wall.netArea * htd
        
        # Windows
        wall.subSurfaces.each do |window|
            next if not window.subSurfaceType.downcase.include?("window")
            u_window = get_surface_uvalue(runner, window, window.subSurfaceType)
            return nil if u_window.nil?
            heat_load += u_window * window.grossArea * htd
        end
        
        # Doors
        wall.subSurfaces.each do |door|
            next if not door.subSurfaceType.downcase.include?("door")
            door_uvalue = get_surface_uvalue(runner, door, door.subSurfaceType)
            return nil if door_uvalue.nil?
            heat_load += door_uvalue * door.grossArea * htd
        end
    end
    
    # Interzonal walls
    unit_surfaces['living_walls_interzonal'].each do |wall|
        wall_uvalue = get_surface_uvalue(runner, wall, wall.surfaceType)
        return nil if wall_uvalue.nil?
        adjacent_space = wall.adjacentSurface.get.space.get
        heat_load += wall_uvalue * wall.netArea * (mj8.heating_setpoint - mj8.heat_design_temps[adjacent_space])
    end
    
    # Foundation walls
    unit_surfaces['fbasement_walls_exterior'].each do |wall|
        # FIXME: Deviating substantially from sizing.py
        wall_uvalue = get_surface_uvalue(runner, wall, wall.surfaceType)
        return nil if wall_uvalue.nil?
        heat_load_fbsmt += wall_uvalue * wall.netArea * htd
    end

    # Exterior floors
    unit_surfaces['living_floors_exterior'].each do |floor|
        floor_uvalue = get_surface_uvalue(runner, floor, floor.surfaceType)
        return nil if floor_uvalue.nil?
        heat_load += floor_uvalue * floor.netArea * htd
    end
    
    # Interzonal floors
    unit_surfaces['living_floors_interzonal'].each do |floor|
        floor_uvalue = get_surface_uvalue(runner, floor, floor.surfaceType)
        return nil if floor_uvalue.nil?
        adjacent_space = floor.adjacentSurface.get.space.get
        heat_load += floor_uvalue * floor.netArea * (mj8.heating_setpoint - mj8.heat_design_temps[adjacent_space])
    end
    
    # Foundation floors
    unit_surfaces['fbasement_floors_exterior'].each do |floor|
        if Geometry.get_finished_basement_spaces(model.getSpaces).include?(floor.space.get)
            # FIXME: Need to do
            # # Finished basement floor combinations based on MJ 8th Ed. A12-7 and ASHRAE HoF 2013 pg 18.31 Eq 40
            # R_other = sim.mat.materials[Constants.MaterialConcrete4in].Rvalue + sim.film.floor_average
            # for floor in unit.floors.floor:
                # floor.surface_type.Uvalue_fbsmt_mj8 = 0
                # z_f = below_grade_height
                # w_b = min( max(floor.vertices.coord.x) - min(floor.vertices.coord.x), max(floor.vertices.coord.y) - min(floor.vertices.coord.y) )
                # U_avg_bf = (2*k_soil/(Constants.Pi*w_b)) * (log(w_b/2+z_f/2+(k_soil*R_other)/Constants.Pi) - log(z_f/2+(k_soil*R_other)/Constants.Pi))                     
                # floor.surface_type.Uvalue_fbsmt_mj8 = 0.85 * U_avg_bf 
                # heat_load_fbsmt += floor.surface_type.Uvalue_fbsmt_mj8 * floor.area * htd
        else # Slab
            floor_uvalue = get_surface_uvalue(runner, floor, floor.surfaceType)
            return nil if floor_uvalue.nil?
            heat_load += floor_uvalue * floor.netArea * (mj8.heating_setpoint - weather.data.GroundMonthlyTemps[0])
        end
    end

    # Roofs
    unit_surfaces['living_roofs_exterior'].each do |roof|
        roof_uvalue = get_surface_uvalue(runner, roof, roof.surfaceType)
        return nil if roof_uvalue.nil?
        heat_load += roof_uvalue * roof.netArea * htd
    end
            
    # Prevent a negative heating load, which can happen in hot climates
    heat_load_fbsmt = [0, heat_load_fbsmt].max
    
    return heat_load, heat_load_fbsmt
  end
  
  def processInfiltrationVentilation_Heating(runner, model, unit, mj8, weather, htd, infil_type, space_ela, space_inf_flow, mechVentType, whole_house_vent_rate, mechVentApparentSensibleEffectiveness, mechVentLatentEffectiveness, mechVentTotalEfficiency)
    '''
    Infiltration & Ventilation
    '''
    
    return nil if mj8.nil?
    
    ft2in = OpenStudio::convert(1.0, "ft", "in").get
    mph2m_s = OpenStudio::convert(1.0, "mph", "m/s").get
    
    if infil_type == 'ach50'
        icfm_Heating = space_ela * ft2in ** 2 * (mj8.Cs * htd.abs + mj8.Cw * (weather.design.HeatingWindspeed / mph2m_s) ** 2) ** 0.5            
    elsif infil_type == 'ach'
        icfm_Heating = space_inf_flow
    end
        
    q_unb, q_bal_Sens, q_bal_Lat, ventMultiplier = get_ventilation_rates(mechVentType, whole_house_vent_rate, mechVentApparentSensibleEffectiveness, mechVentLatentEffectiveness, mechVentTotalEfficiency)

    cfm_Heating = q_bal_Sens + (icfm_Heating ** 2 + ventMultiplier * (q_unb ** 2)).abs ** 0.5
    heating_Infil = 1.1 * mj8.acf * cfm_Heating * mj8.htd
    
    # FIXME
    heating_Infil_fbsmt = 0

    return heating_Infil, heating_Infil_fbsmt
  end
  
  def processDehumidificationLoad(runner, model, unit, mj8, weather, unit_surfaces)
    '''
    Dehumidification Load
    '''
    
    return nil if mj8.nil?
    
    mj8.DehumidLoad_Cond = 0
    
    # Exterior walls
    unit_surfaces['living_walls_exterior'].each do |wall|
        wall_uvalue = get_surface_uvalue(runner, wall, wall.surfaceType)
        return nil if wall_uvalue.nil?
        mj8.DehumidLoad_Cond += wall_uvalue * wall.netArea * mj8.dtd
        
        # Windows
        wall.subSurfaces.each do |window|
            next if not window.subSurfaceType.downcase.include?("window")
            u_window = get_surface_uvalue(runner, window, window.subSurfaceType)
            return nil if u_window.nil?
            mj8.DehumidLoad_Cond += u_window * window.grossArea * mj8.dtd
        end
        
        # Doors
        wall.subSurfaces.each do |door|
            next if not door.subSurfaceType.downcase.include?("door")
            door_uvalue = get_surface_uvalue(runner, door, door.subSurfaceType)
            return nil if door_uvalue.nil?
            mj8.DehumidLoad_Cond += door_uvalue * door.grossArea * mj8.dtd
        end
    end

    # Interzonal walls
    unit_surfaces['living_walls_interzonal'].each do |wall|
        wall_uvalue = get_surface_uvalue(runner, wall, wall.surfaceType)
        return nil if wall_uvalue.nil?
        adjacent_space = wall.adjacentSurface.get.space.get
        mj8.DehumidLoad_Cond += wall_uvalue * wall.netArea * (mj8.cooling_setpoint - mj8.dehum_design_temps[adjacent_space])
    end
    
    # Exterior floors
    unit_surfaces['living_floors_exterior'].each do |floor|
        floor_uvalue = get_surface_uvalue(runner, floor, floor.surfaceType)
        return nil if floor_uvalue.nil?
        mj8.DehumidLoad_Cond += floor_uvalue * floor.netArea * mj8.dtd
    end
    
    # Interzonal floors
    unit_surfaces['living_floors_interzonal'].each do |floor|
        floor_uvalue = get_surface_uvalue(runner, floor, floor.surfaceType)
        return nil if floor_uvalue.nil?
        adjacent_space = floor.adjacentSurface.get.space.get
        mj8.DehumidLoad_Cond += floor_uvalue * floor.netArea * (mj8.cooling_setpoint - mj8.dehum_design_temps[adjacent_space])
    end

    # Roofs
    unit_surfaces['living_roofs_exterior'].each do |roof|
        roof_uvalue = get_surface_uvalue(runner, roof, roof.surfaceType)
        return nil if roof_uvalue.nil?
        mj8.DehumidLoad_Cond += roof_uvalue * roof.netArea * mj8.dtd
    end
  
    return mj8
  end
  
  def processIntermediateTotalLoads(runner, model, unit, mj8, weather, htg_supply_air_temp)
    '''
    Intermediate Loads
    (total loads excluding ducts)
    '''
    
    return nil if mj8.nil?
    
    # TODO: Ideally this would require an iterative procedure. A possible enhancement for BEopt2.
    #---Total Loads
    mj8.HeatingLoad_Inter = mj8.HeatingLoad_Infil + mj8.HeatingLoad_Cond + \
                            mj8.HeatingLoad_FBsmt + mj8.HeatingLoad_Infil_FBsmt

    mj8.CoolingLoad_Inter_Sens = mj8.CoolingLoad_Windows + mj8.CoolingLoad_Doors + \
                                 mj8.CoolingLoad_Walls + mj8.CoolingLoad_Floors + \
                                 mj8.CoolingLoad_Roofs + mj8.CoolingLoad_Infil_Sens + \
                                 mj8.CoolingLoad_IntGains_Sens
    mj8.CoolingLoad_Inter_Lat = [mj8.CoolingLoad_Infil_Lat + mj8.CoolingLoad_IntGains_Lat, 0].max
    mj8.CoolingLoad_Inter_Tot = mj8.CoolingLoad_Inter_Sens + mj8.CoolingLoad_Inter_Lat
    
    shr = [mj8.CoolingLoad_Inter_Sens / mj8.CoolingLoad_Inter_Tot, 1.0].min
    
    # Determine the Leaving Air Temperature (LAT) based on Manual S Table 1-4
    if shr < 0.80
        mj8.LAT = 54
    elsif shr < 0.85
        # MJ8 says to use 56 degF in this SHR range. Linear interpolation provides a more 
        # continuous supply air flow rate across building efficiency levels.
        mj8.LAT = ((58-54)/(0.85-0.80))*(shr - 0.8) + 54
    else
        mj8.LAT = 58
    end
    
    mj8.CoolingCFM_Inter = mj8.CoolingLoad_Inter_Sens / (1.1 * mj8.acf * (mj8.cooling_setpoint - mj8.LAT))
    mj8.HeatingCFM_Inter = calc_heat_cfm(mj8.HeatingLoad_Inter, mj8, htg_supply_air_temp)
        
    mj8.DehumidLoad_Inter_Sens = mj8.DehumidLoad_Infil_Sens + mj8.DehumidLoad_IntGains_Sens + mj8.DehumidLoad_Cond
    mj8.DehumidLoad_Inter_Lat = mj8.DehumidLoad_Infil_Lat + mj8.DehumidLoad_IntGains_Lat
    
    return mj8
  end
  
  def processDuctRegainFactors(runner, mj8, has_ducts, ducts_not_in_living, ductSystemEfficiency, ductLocation, basement_ceiling_Rvalue, basement_wall_Rvalue, basement_ach, crawlACH, crawl_ceiling_Rvalue, crawl_wall_Rvalue)
    return nil if mj8.nil?
  
    dse_Fregain = nil
    
    # Distribution system efficiency (DSE) calculations based on ASHRAE Standard 152
    if (has_ducts and ducts_not_in_living) or not ductSystemEfficiency.nil?
        # dse_Fregain values comes from MJ8 pg 204 and Walker (1998) "Technical background for default 
        # values used for forced air systems in proposed ASHRAE Std. 152"
        if ['Constants.SpaceUnfinBasement', 'Constants.SpaceFinBasement'].include?(ductLocation)
            if basement_ceiling_Rvalue == 0
                if basement_wall_Rvalue == 0
                    if basement_ach == 0
                        dse_Fregain = 0.55     # Uninsulated ceiling, uninsulated walls, no infiltration                            
                    else
                        dse_Fregain = 0.51     # Uninsulated ceiling, uninsulated walls, with infiltration
                    end
                else
                    if basement_ach == 0
                        dse_Fregain = 0.78    # Uninsulated ceiling, insulated walls, no infiltration
                    else
                        dse_Fregain = 0.74    # Uninsulated ceiling, insulated walls, with infiltration                        
                    end
                end
            else
                if basement_wall_Rvalue > 0
                    if basement_ach == 0
                        dse_Fregain = 0.32     # Insulated ceiling, insulated walls, no infiltration
                    else
                        dse_Fregain = 0.27     # Insulated ceiling, insulated walls, with infiltration                            
                    end
                else
                    dse_Fregain = 0.06    # Insulated ceiling and uninsulated walls
                end
            end
        elsif ['Constants.SpaceCrawl', 'Constants.SpacePierbeam'].include?(ductLocation)
            if crawlACH > 0
                if crawl_ceiling_Rvalue > 0
                    dse_Fregain = 0.12    # Insulated ceiling and uninsulated walls
                else
                    dse_Fregain = 0.50    # Uninsulated ceiling and uninsulated walls
                end
            else
                if crawl_ceiling_Rvalue == 0 and crawl_wall_Rvalue == 0
                    dse_Fregain = 0.60    # Uninsulated ceiling and uninsulated walls
                elsif crawl_ceiling_Rvalue > 0 and crawl_wall_Rvalue == 0
                    dse_Fregain = 0.16    # Insulated ceiling and uninsulated walls
                elsif crawl_ceiling_Rvalue == 0 and crawl_wall_Rvalue > 0
                    dse_Fregain = 0.76    # Uninsulated ceiling and insulated walls (not explicitly included in A152)
                else
                    dse_Fregain = 0.30    # Insulated ceiling and insulated walls (option currently not included in BEopt)
                end
            end
        elsif ductLocation == 'Constants.SpaceUnfinAttic'
            dse_Fregain = 0.10          # This would likely be higher for unvented attics with roof insulation
        elsif ductLocation == 'Constants.SpaceGarage'
            dse_Fregain = 0.05
        elsif ['Constants.SpaceLiving', 'Constants.SpaceFinAttic'].include?(DuctLocation)
            dse_Fregain = 1.0
        elsif not ductSystemEfficiency.nil?
            #Regain is already incorporated into the DSE
            dse_Fregain = 0.0
        else
            runner.registerError("Invalid duct location: #{ductLocation.to_s}")        
            return nil
        end
    end
    
    return dse_Fregain
  end
  
  def processDuctLoads_Heating(runner, model, unit, mj8, weather, heatingLoad_Inter, has_ducts, ducts_not_in_living, ductSystemEfficiency, ductLocation, supply_duct_surface_area, return_duct_surface_area, ductLocationFracConduction, ductNormLeakageToOutside, supply_duct_loss, return_duct_loss, supply_duct_r, return_duct_r, has_forced_air_equip, htg_supply_air_temp, ductLocationSpace)
    return nil if mj8.nil?
    
    # Distribution system efficiency (DSE) calculations based on ASHRAE Standard 152
    if has_ducts and ducts_not_in_living and has_forced_air_equip
        dse_Tamb_heating = mj8.heat_design_temps[ductLocationSpace]
        duct_load_heating = calc_heating_duct_load(mj8, heatingLoad_Inter, supply_duct_surface_area, return_duct_surface_area, ductLocationFracConduction, ducts_not_in_living, ductNormLeakageToOutside, supply_duct_loss, return_duct_loss, supply_duct_r, return_duct_r, htg_supply_air_temp, dse_Tamb_heating, ductSystemEfficiency)
        if ductLocation == 'Constants.SpaceFinBasement'
            # Ducts in the finished basement shouldn't effect the total heating capacity
            mj8.HeatingLoad = heatingLoad_Inter
            mj8.DuctLoad_FinBasement = duct_load_heating
        else
            mj8.HeatingLoad = heatingLoad_Inter + duct_load_heating
            mj8.DuctLoad_FinBasement = 0
        end
    else
        mj8.HeatingLoad = heatingLoad_Inter
        mj8.DuctLoad_FinBasement = 0
    end
    
    return mj8
  end
                                     
  def processDuctLoads_Cooling_Dehum(runner, model, unit, mj8, weather, has_ducts, ducts_not_in_living, supply_duct_surface_area, return_duct_surface_area, ductLocationFracConduction, ductLocation, supply_duct_loss, return_duct_loss, ductNormLeakageToOutside, supply_duct_r, return_duct_r, ductSystemEfficiency, has_forced_air_equip, ductLocationSpace)
    '''
    Duct Loads
    '''
    
    return nil if mj8.nil?
    
    # Distribution system efficiency (DSE) calculations based on ASHRAE Standard 152
    if has_ducts and ducts_not_in_living and has_forced_air_equip and mj8.CoolingLoad_Inter_Sens > 0
        
        dse_Tamb_cooling = mj8.cool_design_temps[ductLocationSpace]
        dse_Tamb_dehumid = mj8.dehum_design_temps[ductLocationSpace]
        
        # Calculate the air enthalpy in the return duct location for DSE calculations
        mj8.dse_h_Return_Cooling = (1.006 * OpenStudio::convert(dse_Tamb_cooling, "F", "C").get + weather.design.CoolingHumidityRatio * (2501 + 1.86 * OpenStudio::convert(dse_Tamb_cooling, "F", "C").get)) * OpenStudio::convert(1, "kJ", "Btu").get * OpenStudio::convert(1, "lb", "kg").get
        mj8.dse_h_Return_Dehumid = (1.006 * OpenStudio::convert(dse_Tamb_dehumid, "F", "C").get + weather.design.DehumidHumidityRatio * (2501 + 1.86 * OpenStudio::convert(dse_Tamb_dehumid, "F", "C").get)) * OpenStudio::convert(1, "kJ", "Btu").get * OpenStudio::convert(1, "lb", "kg").get
        
        # Supply and return duct surface areas located outside conditioned space
        dse_As = supply_duct_surface_area * ductLocationFracConduction
        dse_Ar = return_duct_surface_area
    
        iterate_Tattic = false
        if ductLocation == 'Constants.SpaceUnfinAttic'
            iterate_Tattic = true
            
            # FIXME: Need to do
            ## Calculate constant variables used in iteration:
            ## Multiply by fraction of attic apportioned to this unit (unit.unfin_attic_floor_area_frac).
            #mj8.UA_atticfloor = (sim.getSurfaceType(Constants.SurfaceTypeFinInsUnfinUAFloor).Uvalue *
            #                     unit.unfin_attic_floor_area)
            #mj8.UA_roof = ((sim.getSurfaceType(Constants.SurfaceTypeUnfinInsExtRoof).Uvalue *
            #                geometry.roofs.ua_roof_area * unit.unfin_attic_floor_area_frac) + 
            #                mj8.gable_ua * unit.unfin_attic_floor_area_frac)
            #try:
            #    mj8.mdotCp_atticvent = (sim._getSpace(Constants.SpaceUnfinAttic).inf_flow * # cfm
            #                        sim.outside_air_density *
            #                        sim.mat.air.inside_air_sh *
            #                        units.hr2min(1) *
            #                        unit.unfin_attic_floor_area_frac)
            #except TypeError:
            #    pass
            #self._calculate_Tsolair(sim, mj8, geometry, weather) # Sol air temperature on outside of roof surface # 1)
            # 
            ## Calculate starting attic temp (ignoring duct losses)
            #mj8.CoolingLoad_Ducts_Sens = 0
            #self._calculate_Tattic_iter(mj8)
            #dse_Tamb_cooling = mj8.Tattic_iter
        end
        
        # Initialize for the iteration
        delta = 1
        coolingLoad_Tot_Prev = mj8.CoolingLoad_Inter_Tot
        coolingLoad_Tot_Next = mj8.CoolingLoad_Inter_Tot
        mj8.CoolingLoad_Tot  = mj8.CoolingLoad_Inter_Tot
        mj8.CoolingLoad_Sens = mj8.CoolingLoad_Inter_Sens
        
        # FIXME
        #if not hasattr(unit.ducts, 'return_duct_loss'):
        #    mj8.CoolingCFM_Inter = mj8.CoolingLoad_Sens / (1.1 * sim.site.acf * (mj8.cooling_setpoint - mj8.LAT))
        #    simpy.calc_duct_leakage_from_test(sim, unit.ducts, unit.finished_floor_area, mj8.CoolingCFM_Inter)
        
        mj8 = calculate_sensible_latent_split(mj8, mj8.acf, return_duct_loss, coolingLoad_Tot_Next)
        
        for _iter in 1..50
            break if delta.abs <= 0.001

            coolingLoad_Tot_Prev = coolingLoad_Tot_Next
            
            mj8 = calculate_sensible_latent_split(mj8, mj8.acf, return_duct_loss, coolingLoad_Tot_Next)
            mj8.CoolingLoad_Tot = mj8.CoolingLoad_Lat + mj8.CoolingLoad_Sens
            
            # Calculate the new cooling air flow rate
            mj8.CoolingCFM_Inter = mj8.CoolingLoad_Sens / (1.1 * mj8.acf * (mj8.cooling_setpoint - mj8.LAT))

            mj8.CoolingLoad_Ducts_Sens = mj8.CoolingLoad_Sens - mj8.CoolingLoad_Inter_Sens
            mj8.CoolingLoad_Ducts_Tot = coolingLoad_Tot_Next - mj8.CoolingLoad_Inter_Tot

            dse_DEcorr_cooling, dse_dTe_cooling = calc_dse(mj8, mj8.CoolingCFM_Inter, mj8.CoolingLoad_Sens, dse_Tamb_cooling, dse_As, dse_Ar, mj8.cooling_setpoint, mj8.dse_Fregain, mj8.CoolingLoad_Tot, true, ductNormLeakageToOutside, supply_duct_loss, return_duct_loss, ducts_not_in_living, supply_duct_r, return_duct_r, ductSystemEfficiency)
            dse_precorrect = 1 - (mj8.CoolingLoad_Ducts_Sens / mj8.CoolingLoad_Sens)
        
            if iterate_Tattic # Iterate attic temperature based on duct losses
                delta_attic = 1
                
                for _iter_attic in 1..20
                    # FIXME: Need to do
                    #break if delta_attic.abs <= 0.001
                    #
                    #t_attic_old = mj8.Tattic_iter
                    #self._calculate_Tattic_iter(mj8)
                    #sim._getSpace(Constants.SpaceUnfinAttic).cool_design_temp_mj8 = mj8.Tattic_iter
                    #
                    ## Calculate the change since the last iteration
                    #delta_attic = (mj8.Tattic_iter - t_attic_old) / t_attic_old                  
                    #
                    ## Calculate enthalpy in attic using new Tattic
                    #mj8.dse_h_Return_Cooling = (1.006 * units.F2C(mj8.Tattic_iter) + weather.design.CoolingHumidityRatio * (2501 + 1.86 * units.F2C(mj8.Tattic_iter))) * units.kJ2Btu(1) * units.lbm2kg(1)
                    #
                    ## Calculate duct efficiency using new Tattic:
                    #dse_DEcorr_cooling, dse_dTe_cooling = self._calc_dse(sim, mj8, unit, mj8.CoolingCFM_Inter, mj8.CoolingLoad_Sens, mj8.Tattic_iter, dse_As, dse_Ar, mj8.cooling_setpoint, mj8.dse_Fregain, mj8.CoolingLoad_Tot, IsCooling=True)
                    #dse_precorrect = 1-(mj8.CoolingLoad_Ducts_Sens/mj8.CoolingLoad_Sens)
                end
                
                dse_Tamb_cooling = mj8.Tattic_iter
                mj8 = processCoolingLoadFloors(runner, model, unit, mj8, weather, unit_surfaces)
                mj8 = processIntermediateTotalLoads(runner, model, unit, mj8, weather, htg_supply_air_temp)
                
                # Calculate the increase in total cooling load due to ducts (conservatively to prevent overshoot)
                coolingLoad_Tot_Next = mj8.CoolingLoad_Inter_Tot + coolingLoad_Tot_Prev * (1 - dse_precorrect)
                
                # Calculate unmet zone load:
                delta = mj8.CoolingLoad_Inter_Tot - (mj8.CoolingLoad_Tot*dse_precorrect)
            else
                coolingLoad_Tot_Next = mj8.CoolingLoad_Inter_Tot / dse_DEcorr_cooling    
                        
                # Calculate the change since the last iteration
                delta = (coolingLoad_Tot_Next - coolingLoad_Tot_Prev) / coolingLoad_Tot_Prev
            end
        end # _iter
        
        # Calculate the air flow rate required for design conditions
        mj8.Cool_AirFlowRate = mj8.CoolingLoad_Sens / (1.1 * mj8.acf * (mj8.cooling_setpoint - mj8.LAT))

        # Dehumidification duct loads
        
        dse_Qs_Dehumid = supply_duct_loss * mj8.Cool_AirFlowRate
        dse_Qr_Dehumid = return_duct_loss * mj8.Cool_AirFlowRate
        
        # Supply and return conduction functions, Bs and Br
        if ducts_not_in_living
            dse_Bs_dehumid = Math.exp((-1.0 * dse_As) / (60 * mj8.Cool_AirFlowRate * Gas.Air.rho * Gas.Air.cp * supply_duct_r))
            dse_Br_dehumid = Math.exp((-1.0 * dse_Ar) / (60 * mj8.Cool_AirFlowRate * Gas.Air.rho * Gas.Air.cp * return_duct_r))
        else
            dse_Bs_dehumid = 1
            dse_Br_dehumid = 1
        end
            
        dse_a_s_dehumid = (mj8.Cool_AirFlowRate - dse_Qs_Dehumid) / mj8.Cool_AirFlowRate
        dse_a_r_dehumid = (mj8.Cool_AirFlowRate - dse_Qr_Dehumid) / mj8.Cool_AirFlowRate
        
        dse_dTe_dehumid = dse_dTe_cooling
        dse_dT_dehumid = mj8.cooling_setpoint - dse_Tamb_dehumid
        
        # Calculate the delivery effectiveness (Equation 6-23)
        dse_DE_dehumid = dse_a_s_dehumid * dse_Bs_dehumid - dse_a_s_dehumid * dse_Bs_dehumid * \
                         (1 - dse_a_r_dehumid * dse_Br_dehumid) * (dse_dT_dehumid / dse_dTe_dehumid) - \
                         dse_a_s_dehumid * (1 - dse_Bs_dehumid) * (dse_dT_dehumid / dse_dTe_dehumid)
                         
        # Calculate the delivery effectiveness corrector for regain (Equation 6-40)
        dse_DEcorr_dehumid = dse_DE_dehumid + mj8.dse_Fregain * (1 - dse_DE_dehumid) + dse_Br_dehumid * \
                             (dse_a_r_dehumid * mj8.dse_Fregain - mj8.dse_Fregain) * (dse_dT_dehumid / dse_dTe_dehumid)

        # Limit the DE to a reasonable value to prevent negative values and huge equipment
        dse_DEcorr_dehumid = [dse_DEcorr_dehumid, 0.25].max
        if not ductSystemEfficiency.nil?
            dse_DEcorr_dehumid = ductSystemEfficiency
        end
        
        # Calculate the increase in sensible dehumidification load due to ducts
        mj8.DehumidLoad_Sens = mj8.DehumidLoad_Inter_Sens / dse_DEcorr_dehumid

        # Calculate the latent duct leakage load (Manual J accounts only for return duct leakage)
        mj8.dse_Dehumid_Latent = 0.68 * mj8.acf * dse_Qr_Dehumid * (mj8.dehum_design_grains - mj8.grains_indoor_dehumid)
                                          
    else
        mj8.CoolingLoad_Lat = mj8.CoolingLoad_Inter_Lat
        mj8.CoolingLoad_Sens = mj8.CoolingLoad_Inter_Sens
        
        mj8.dse_Dehumid_Latent = 0
        mj8.DehumidLoad_Sens = mj8.DehumidLoad_Inter_Sens

        mj8.CoolingLoad_Tot = mj8.CoolingLoad_Sens + mj8.CoolingLoad_Lat

        # Calculate the air flow rate required for design conditions
        mj8.Cool_AirFlowRate = mj8.CoolingLoad_Sens / (1.1 * mj8.acf * (mj8.cooling_setpoint - mj8.LAT))
    end
    
    return mj8
  end
  
  def processCoolingEquipmentAdjustments(runner, model, unit, mj8, weather, has_hvac, minCoolingCapacity, num_speeds, cOOL_CAP_FT_SPEC_coefficients, sHR_Rated, capacity_Ratio_Cooling)
    '''
    Equipment Adjustments
    '''
    
    return nil if mj8.nil?
    
    if has_hvac['Cooling']
        
        if mj8.CoolingLoad_Tot < 0
            mj8.Cool_Capacity = minCoolingCapacity
            mj8.Cool_SensCap = 0.78 * minCoolingCapacity
            mj8.Cool_AirFlowRate = 400.0 * OpenStudio::convert(minCoolingCapacity,"Btu/h","ton").get
            return mj8
        end
        
        cool_design_db = weather.design.CoolingDrybulb

        # Adjust the total cooling capacity to the rated conditions using performance curves
        if not has_hvac['GroundSourceHP']
            mj8.EnteringTemp = cool_design_db
        else
            mj8.EnteringTemp = unit.supply.HXCHWDesign # FIXME
        end
        
        if has_hvac['AirConditioner'] or has_hvac['HeatPump']

            if num_speeds > 1
                sizingSpeed = num_speeds # Default
                sizingSpeed_Test = 10    # Initialize
                for speed in 0..(num_speeds - 1)
                    # Select curves for sizing using the speed with the capacity ratio closest to 1
                    temp = (capacity_Ratio_Cooling[speed] - 1).abs
                    if temp <= sizingSpeed_Test
                        sizingSpeed = speed
                        sizingSpeed_Test = temp
                    end
                end
                coefficients = cOOL_CAP_FT_SPEC_coefficients[sizingSpeed]
            else
                coefficients = cOOL_CAP_FT_SPEC_coefficients[0]
            end

            mj8.TotalCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_cooling, mj8.EnteringTemp, coefficients)
            coolCap_Rated = mj8.CoolingLoad_Tot / mj8.TotalCap_CurveValue
            if num_speeds > 1
                sHR_Rated_Equip = sHR_Rated[sizingSpeed]
            else
                sHR_Rated_Equip = sHR_Rated[0]
            end
                            
            sensCap_Rated = coolCap_Rated * sHR_Rated_Equip
        
            # Based on EnergyPlus's model for calculating SHR at off-rated conditions. This curve fit 
            # avoids the iterations in the actual model. It does not account for altitude or variations 
            # in the SHR_rated. It is a function of ODB (MJ design temp) and CFM/Ton (from MJ)
            a_sens = 1.08464364
            b_sens = 0.002096954
            c_sens = -0.005766327
            d_sens = -0.000011147
        
            # TODO: Get rid of this curve by using ADP/BF calculations
            sensibleCap_CurveValue = a_sens + \
                                     b_sens * (mj8.Cool_AirFlowRate / OpenStudio::convert(mj8.CoolingLoad_Tot,"Btu/h","ton").get) + \
                                     c_sens * mj8.EnteringTemp + \
                                     d_sens * (mj8.Cool_AirFlowRate / OpenStudio::convert(mj8.CoolingLoad_Tot,"Btu/h","ton").get) * mj8.EnteringTemp
            mj8.SensCap_Design = sensCap_Rated * sensibleCap_CurveValue
            mj8.LatCap_Design = [mj8.CoolingLoad_Tot - mj8.SensCap_Design, 1].max
        
            if num_speeds == 1
                mj8.OverSizeLimit = 1.15
            elsif num_speeds == 2
                mj8.OverSizeLimit = 1.2
            elsif num_speeds > 2
                mj8.OverSizeLimit = 1.3
            else
                runner.registerError("Unexpected num_speeds: #{num_speeds.to_s}.")
                return nil
            end
        
            # Adjust Sizing
            if mj8.LatCap_Design < mj8.CoolingLoad_Lat
                # Size by MJ8 Latent load, return to rated conditions
                
                # Solve for the new sensible and total capacity at design conditions:
                # CoolingLoad_Lat = mj8.Cool_Capacity_Design - Cool_SensCap_Design
                # solve the following for mj8.Cool_Capacity_Design: SensCap_Design = SHR_Rated * mj8.Cool_Capacity_Design / TotalCap_CurveValue * function(CFM/mj8.Cool_Capacity_Design, ODB)
                # substituting in CFM = Cool_SensCap_Design / (1.1 * ACF * (cooling_setpoint - LAT))
                
                mj8.Cool_SensCap_Design = mj8.CoolingLoad_Lat / ((mj8.TotalCap_CurveValue / sHR_Rated_Equip - \
                                          (OpenStudio::convert(b_sens,"ton","Btu/h").get + OpenStudio::convert(d_sens,"ton","Btu/h").get * mj8.EnteringTemp) / \
                                          (1.1 * mj8.acf * (mj8.cooling_setpoint - mj8.LAT))) / \
                                          (a_sens + c_sens * mj8.EnteringTemp) - 1)
                
                mj8.Cool_Capacity_Design = mj8.Cool_SensCap_Design + mj8.CoolingLoad_Lat
                
                # The SHR of the equipment at the design condition
                sHR_design = mj8.Cool_SensCap_Design / mj8.Cool_Capacity_Design
                
                # If the adjusted equipment size is negative (occurs at altitude), oversize by 15% (the adjustment
                # almost always hits the oversize limit in this case, making this a safe assumption)
                if mj8.Cool_Capacity_Design < 0 or mj8.Cool_SensCap_Design < 0
                    mj8.Cool_Capacity_Design = mj8.OverSizeLimit * mj8.CoolingLoad_Tot
                end
                
                # Limit total capacity to oversize limit
                mj8.Cool_Capacity_Design = [mj8.Cool_Capacity_Design, mj8.OverSizeLimit * mj8.CoolingLoad_Tot].min
                
                # Determine the final sensible capacity at design using the SHR
                mj8.Cool_SensCap_Design = SHR_design * mj8.Cool_Capacity_Design
                
                # Calculate the final air flow rate using final sensible capacity at design
                mj8.Cool_AirFlowRate = mj8.Cool_SensCap_Design / (1.1 * mj8.acf * \
                                       (mj8.cooling_setpoint - mj8.LAT))
                
                # Determine rated capacities
                mj8.Cool_Capacity = mj8.Cool_Capacity_Design / mj8.TotalCap_CurveValue
                mj8.Cool_SensCap = mj8.Cool_Capacity * sHR_Rated_Equip
                            
            elsif  mj8.SensCap_Design < mj8.UnderSizeLimit * mj8.CoolingLoad_Sens
                
                # Size by MJ8 Sensible load, return to rated conditions, find Sens with SHR_rated. Limit total 
                # capacity to oversizing limit
                
                mj8.SensCap_Design = mj8.UnderSizeLimit * mj8.CoolingLoad_Sens
                
                # Solve for the new total system capacity at design conditions:
                # SensCap_Design   = SensCap_Rated * SensibleCap_CurveValue
                #                  = SHR_Rated * mj8.Cool_Capacity_Design / TotalCap_CurveValue * SensibleCap_CurveValue
                #                  = SHR_Rated * mj8.Cool_Capacity_Design / TotalCap_CurveValue * function(CFM/mj8.Cool_Capacity_Design, ODB)
                
                mj8.Cool_Capacity_Design = (mj8.SensCap_Design / (sHR_Rated_Equip / mj8.TotalCap_CurveValue) - \
                                                   (b_sens * OpenStudio::convert(mj8.Cool_AirFlowRate,"ton","Btu/h").get + \
                                                   d_sens * OpenStudio::convert(mj8.Cool_AirFlowRate,"ton","Btu/h").get * mj8.EnteringTemp)) / \
                                                   (a_sens + c_sens * mj8.EnteringTemp)

                # Limit total capacity to oversize limit
                mj8.Cool_Capacity_Design = [mj8.Cool_Capacity_Design, mj8.OverSizeLimit * mj8.CoolingLoad_Tot].min
                
                mj8.Cool_Capacity = mj8.Cool_Capacity_Design / mj8.TotalCap_CurveValue
                mj8.Cool_SensCap = mj8.Cool_Capacity * sHR_Rated_Equip
                
                # Recalculate the air flow rate in case the oversizing limit has been used
                mj8.Cool_SensCap_Design = mj8.Cool_SensCap * sensibleCap_CurveValue
                mj8.Cool_AirFlowRate = mj8.Cool_SensCap_Design / (1.1 * mj8.acf * (mj8.cooling_setpoint - mj8.LAT))

            else
                
                mj8.Cool_Capacity = mj8.CoolingLoad_Tot / mj8.TotalCap_CurveValue
                mj8.Cool_SensCap = mj8.Cool_Capacity * sHR_Rated_Equip
                
                mj8.Cool_SensCap_Design = mj8.Cool_SensCap * sensibleCap_CurveValue
                mj8.Cool_AirFlowRate = mj8.Cool_SensCap_Design / (1.1 * mj8.acf * (mj8.cooling_setpoint - mj8.LAT))
                
            end
                
            # Ensure the air flow rate is in between 200 and 500 cfm/ton. 
            # Reset the air flow rate (with a safety margin), if required.
            if mj8.Cool_AirFlowRate / OpenStudio::convert(mj8.Cool_Capacity,"Btu/h","ton").get > 500
                mj8.Cool_AirFlowRate = 499 * OpenStudio::convert(mj8.Cool_Capacity,"Btu/h","ton").get      # CFM
            elsif mj8.Cool_AirFlowRate / OpenStudio::convert(mj8.Cool_Capacity,"Btu/h","ton").get < 200
                mj8.Cool_AirFlowRate = 201 * OpenStudio::convert(mj8.Cool_Capacity,"Btu/h","ton").get      # CFM
            end
                
        elsif has_hvac['MiniSplitHP']
                            
            # FIXME
            # sizingSpeed = num_speeds # Default
            # sizingSpeed_Test = 10    # Initialize
            # for Speed in range(num_speeds):
                # # Select curves for sizing using the speed with the capacity ratio closest to 1
                # temp = abs(unit.supply.Capacity_Ratio_Cooling[Speed] - 1)
                # if temp <= sizingSpeed_Test:
                    # sizingSpeed = Speed
                    # sizingSpeed_Test = temp
            
            # coefficients = cOOL_CAP_FT_SPEC_coefficients[sizingSpeed]
            
            # mj8.OverSizeLimit = 1.3
                         
            # mj8.TotalCap_CurveValue = MathTools.biquadratic(units.deltaF2C(mj8.wetbulb_indoor_cooling), units.deltaF2C(mj8.EnteringTemp), coefficients)
            
            # unit.supply.Cool_Capacity = (mj8.CoolingLoad_Tot / mj8.TotalCap_CurveValue)
            # unit.supply.Cool_SensCap =  unit.supply.Cool_Capacity * unit.supply.SHR_Rated[sizingSpeed]
            # unit.supply.Cool_AirFlowRate = unit.supply.CoolingCFMs[-1] * OpenStudio::convert(unit.supply.Cool_Capacity,"Btu/h","ton").get 
        
        elsif has_hvac['RoomAirConditioner']
            
            # FIXME
            # coefficients = cOOL_CAP_FT_SPEC_coefficients[0]
                         
            # mj8.TotalCap_CurveValue = MathTools.biquadratic(units.deltaF2C(mj8.wetbulb_indoor_cooling), units.deltaF2C(mj8.EnteringTemp), coefficients)
            
            # unit.supply.Cool_Capacity = mj8.CoolingLoad_Tot / mj8.TotalCap_CurveValue                                            
            # unit.supply.Cool_SensCap =  unit.supply.Cool_Capacity * unit.supply.SHR_Rated
            # unit.supply.Cool_AirFlowRate = unit.supply.CoolingCFMs * OpenStudio::convert(unit.supply.Cool_Capacity,"Btu/h","ton").get 
                                            
        elsif has_hvac['GroundSourceHP']
        
            # FIXME
            # # Single speed as current
            # mj8.TotalCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_cooling, mj8.EnteringTemp, cOOL_CAP_FT_SPEC_coefficients[0])
            # mj8.SensibleCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_cooling, mj8.EnteringTemp, cOOL_SH_FT_SPEC_coefficients)
            # mj8.BypassFactor_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_cooling, mj8.cooling_setpoint, cOIL_BF_FT_SPEC_coefficients)

            # unit.supply.Cool_Capacity = mj8.CoolingLoad_Tot / mj8.TotalCap_CurveValue          # Note: mj8.Cool_Capacity_Design = mj8.CoolingLoad_Tot
            # mj8.SHR_Rated_Equip = unit.supply.SHR_Rated[0]
            # unit.supply.Cool_SensCap = unit.supply.Cool_Capacity * mj8.SHR_Rated_Equip
            
            # unit.supply.Cool_SensCap_Design = (unit.supply.Cool_SensCap * mj8.SensibleCap_CurveValue / 
                                              # (1 + (1 - unit.supply.CoilBF * mj8.BypassFactor_CurveValue) * 
                                               # (80 - mj8.cooling_setpoint) / 
                                               # (mj8.cooling_setpoint - mj8.LAT)))
            # unit.supply.Cool_LatCap_Design = mj8.CoolingLoad_Tot - unit.supply.Cool_SensCap_Design
            
            # # Adjust Sizing so that a. coil sensible at design >= CoolingLoad_MJ8_Sens, and coil latent at design >= CoolingLoad_MJ8_Lat, and equipment SHR_rated is maintained.
            # unit.supply.Cool_SensCap_Design = max(unit.supply.Cool_SensCap_Design, mj8.CoolingLoad_Sens)
            # unit.supply.Cool_LatCap_Design = max(unit.supply.Cool_LatCap_Design, mj8.CoolingLoad_Lat)
            # mj8.Cool_Capacity_Design = unit.supply.Cool_SensCap_Design + unit.supply.Cool_LatCap_Design
            
            # # Limit total capacity to 15% oversizing
            # mj8.Cool_Capacity_Design = min(mj8.Cool_Capacity_Design, mj8.OverSizeLimit * mj8.CoolingLoad_Tot)
            # unit.supply.Cool_Capacity = mj8.Cool_Capacity_Design / mj8.TotalCap_CurveValue
            # unit.supply.Cool_SensCap = unit.supply.Cool_Capacity * mj8.SHR_Rated_Equip
            
            # # Recalculate the air flow rate in case the 15% oversizing rule has been used
            # unit.supply.Cool_SensCap_Design = (unit.supply.Cool_SensCap * mj8.SensibleCap_CurveValue / 
                                              # (1 + (1 - unit.supply.CoilBF * mj8.BypassFactor_CurveValue) * 
                                               # (80 - mj8.cooling_setpoint) / 
                                               # (mj8.cooling_setpoint - mj8.LAT)))
            # unit.supply.Cool_AirFlowRate = (unit.supply.Cool_SensCap_Design / 
                                           # (1.1 * sim.site.acf * 
                                            # (mj8.cooling_setpoint - mj8.LAT)))
        else
        
            runner.registerError("Unexpected cooling system.")
            return nil
        
        end

    else
        mj8.Cool_AirFlowRate = 0
    end
    return mj8
  end
    
  def processFixedEquipment(runner, model, unit, mj8, weather, has_hvac, fixed_cooling_capacity, fixed_heating_capacity, spaceConditionedMult)
    '''
    Fixed Sizing Equipment
    '''
    
    return nil if mj8.nil?
    
    mj8.has_fixed_cooling = false
    mj8.has_fixed_heating = false
    
    # Override Manual J sizes if Fixed sizes are being used
    if has_hvac['Cooling'] and not fixed_cooling_capacity.nil?
        mj8.Cool_Capacity = OpenStudio::convert(fixed_cooling_capacity,"ton","Btu/h").get / spaceConditionedMult
        mj8.has_fixed_cooling = true
    end
    if has_hvac['Heating'] and not fixed_heating_capacity.nil?
        mj8.HeatingLoad = OpenStudio::convert(fixed_heating_capacity,"ton","Btu/h").get # (supplemental capacity, so don't divide by spaceConditionedMult)
        mj8.has_fixed_heating = true
    end
  
    return mj8
  end
    
  def processFinalize(runner, model, unit, mj8, weather, has_hvac, htg_supply_air_temp)
    ''' 
    Finalize Sizing Calculations
    '''
    
    return nil if mj8.nil?
    
    if has_hvac['Furnace']
        mj8.Heat_Capacity = mj8.HeatingLoad
        mj8.Heat_AirFlowRate = calc_heat_cfm(mj8.Heat_Capacity, mj8, htg_supply_air_temp)

    elsif has_hvac['HeatPump']
        
        # FIXME
        # if mj8.has_fixed_heating or mj8.has_fixed_cooling:
            # unit.supply.Heat_Capacity = mj8.HeatingLoad
        # else:
            # self._processHeatPumpAdjustment(sim, mj8, weather, geometry, unit)
            
        # unit.supply.SuppHeat_Capacity = mj8.HeatingLoad
            
        # if unit.supply.Cool_Capacity > Constants.MinCoolingCapacity:
            # unit.supply.Heat_AirFlowRate = unit.supply.Heat_Capacity / (1.1 * sim.site.acf * \
                                    # (unit.supply.htg_supply_air_temp - mj8.heating_setpoint))
        # else:
            # unit.supply.Heat_AirFlowRate = unit.supply.SuppHeat_Capacity / (1.1 * sim.site.acf * \
                                    # (unit.supply.htg_supply_air_temp - mj8.heating_setpoint))

    elsif has_hvac['MiniSplitHP']
        
        # FIXME
        # if not mj8.has_fixed_cooling:
            # self._processHeatPumpAdjustment(sim, mj8, weather, geometry, unit)
        
        # unit.supply.Heat_Capacity = unit.supply.Cool_Capacity + (unit.supply.MiniSplitHPHeatingCapacityOffset / unit.supply.SpaceConditionedMult)
        
        # if sim.hasElecBaseboard:
            # unit.supply.SuppHeat_Capacity = mj8.HeatingLoad
        # else:
            # unit.supply.SuppHeat_Capacity = 0                        
        
        # unit.supply.Heat_AirFlowRate = unit.supply.HeatingCFMs[-1] * units.Btu_h2Ton(unit.supply.Heat_Capacity) # Maximum air flow under heating operation

    elsif has_hvac['Boiler']
        mj8.Heat_AirFlowRate = 0
        mj8.Heat_Capacity = mj8.HeatingLoad
            
    elsif has_hvac['ElecBaseboard']
        mj8.Heat_AirFlowRate = 0
        mj8.Heat_Capacity = mj8.HeatingLoad

    elsif has_hvac['GroundSourceHP']
        # FIXME
        # if unit.cooling_capacity is None:
            # unit.supply.Heat_Capacity = mj8.HeatingLoad
        # else:
            # unit.supply.Heat_Capacity = unit.supply.Cool_Capacity
        # unit.supply.SuppHeat_Capacity = mj8.HeatingLoad
        
        # HDD65F = weather.data.HDD65F
        # HDD50F = weather.data.HDD50F
        # CDD65F = weather.data.CDD65F
        # CDD50F = weather.data.CDD50F
        
        # # For single stage compressor, when heating capacity is much larger than cooling capacity, 
        # # in order to avoid frequent cycling in cooling mode, heating capacity is derated to 75%.
        # if unit.supply.Heat_Capacity >= (1.5 * unit.supply.Cool_Capacity):
            # unit.supply.Heat_Capacity = mj8.HeatingLoad * 0.75
        # elif unit.supply.Heat_Capacity < unit.supply.Cool_Capacity:
            # unit.supply.SuppHeat_Capacity = unit.supply.Heat_Capacity
        
        # if unit.gshp.GLHXType == Constants.BoreTypeVertical:
        
            # # Autosize ground loop heat exchanger length
            # Nom_Length_Heat, Nom_Length_Cool = gshp_hxbore_ft_per_ton(weather, mj8.htd, mj8.ctd, 
                                                                      # unit.supply.HXVertSpacing,
                                                                      # unit.supply.HXGroundConductivity,
                                                                      # unit.supply.HXUTubeSpacingType,
                                                                      # unit.supply.HXVertGroutCond,
                                                                      # unit.supply.HXVertBoreDia,
                                                                      # unit.supply.HXPipeOD,
                                                                      # unit.supply.HXPipeRvalue,
                                                                      # unit.supply.HeatingEIR,
                                                                      # unit.supply.CoolingEIR,
                                                                      # unit.supply.HXCHWDesign,
                                                                      # unit.supply.HXHWDesign,
                                                                      # unit.supply.HXDTDesign)
            
            # VertHXBoreLength_Cool = Nom_Length_Cool * unit.supply.Cool_Capacity / units.Ton2Btu_h(1)
            # VertHXBoreLength_Heat = Nom_Length_Heat * unit.supply.Heat_Capacity / units.Ton2Btu_h(1)

            # unit.supply.VertHXBoreLength = max(VertHXBoreLength_Heat, VertHXBoreLength_Cool) # Using maximum of cooling and heating load effectively controls annual load balancing in heating climate
        
            # # Degree day calculation for balance temperature
            # BLC_Heat = mj8.HeatingLoad_Inter / mj8.htd
            # BLC_Cool = mj8.CoolingLoad_Inter_Sens / mj8.ctd
            # T_Ref_Bal = mj8.heating_setpoint - mj8.Int_Sens_Hr / BLC_Heat # FIXME: mj8.Int_Sens_Hr references the 24th hour of the day?
            # HDD_Ref_Bal = min(HDD65F, max(HDD50F, HDD50F + (HDD65F - HDD50F) / (65 - 50) * (T_Ref_Bal - 50)))
            # CDD_Ref_Bal = min(CDD50F, max(CDD65F, CDD50F + (CDD65F - CDD50F) / (65 - 50) * (T_Ref_Bal - 50)))
            # ANNL_Grnd_Cool = (1 + unit.supply.CoolingEIR[0]) * CDD_Ref_Bal * BLC_Cool * 24 * 0.6  # use 0.6 to account for average solar load
            # ANNL_Grnd_Heat = (1 - unit.supply.HeatingEIR[0]) * HDD_Ref_Bal * BLC_Heat * 24
    
            # # Normalized net annual ground energy load
            # NNAGL = max((ANNL_Grnd_Heat - ANNL_Grnd_Cool) / (weather.data.AnnualAvgDrybulb - (2 * unit.supply.HXHWDesign - unit.supply.HXDTDesign) / 2), \
                        # (ANNL_Grnd_Cool - ANNL_Grnd_Heat) / ((2 * unit.supply.HXCHWDesign + unit.supply.HXDTDesign) / 2 - weather.data.AnnualAvgDrybulb)) / \
                                                                                                              # unit.supply.VertHXBoreLength 
    
            # if unit.supply.HXVertSpacing > 15 and unit.supply.HXVertSpacing <= 20:
                # Borelength_Multiplier = 1.0 + NNAGL / 7000 * (0.55 / unit.supply.HXGroundConductivity)
            # elif unit.gshp.HXVertSpace <= 15:
                # Borelength_Multiplier = 1.0 + NNAGL / 6700 * (1.00 / unit.supply.HXGroundConductivity)
    
            # unit.supply.VertHXBoreLength = Borelength_Multiplier * unit.supply.VertHXBoreLength

            # unit.supply.Cool_Capacity = max(unit.supply.Cool_Capacity, unit.supply.Heat_Capacity)
            # unit.supply.Heat_Capacity = unit.supply.Cool_Capacity
            # unit.supply.Cool_SensCap = unit.supply.Cool_Capacity * mj8.SHR_Rated_Equip
            # unit.supply.Cool_SensCap_Design = (unit.supply.Cool_SensCap * mj8.SensibleCap_CurveValue / 
                                              # (1 + (1 - unit.supply.CoilBF * mj8.BypassFactor_CurveValue) * 
                                               # (80 - mj8.cooling_setpoint) / 
                                               # (mj8.cooling_setpoint - mj8.LAT)))
            # unit.supply.Cool_AirFlowRate = (unit.supply.Cool_SensCap_Design / 
                                           # (1.1 * sim.site.acf * 
                                            # (mj8.cooling_setpoint - mj8.LAT)))
            # unit.supply.Heat_AirFlowRate = (unit.supply.Heat_Capacity / 
                                           # (1.1 * sim.site.acf * 
                                            # (unit.supply.htg_supply_air_temp - mj8.heating_setpoint)))
            
            # #Overwrite heating and cooling airflow rate to be 400 cfm/ton when doing HERS index calculations
            # if sim.hers_rated:
                # unit.supply.Cool_AirFlowRate = units.Btu_h2Ton(unit.supply.Cool_Capacity) * 400
                # unit.supply.Heat_AirFlowRate = units.Btu_h2Ton(unit.supply.Heat_Capacity) * 400
                
            # unit.gshp.loop_flow = floor(max(units.Btu_h2Ton(max(unit.supply.Heat_Capacity, unit.supply.Cool_Capacity)),1)) * 3.0
        
            # if unit.supply.HXNumOfBoreHole == Constants.SizingAuto and unit.supply.HXVertDepth == Constants.SizingAuto:
                # unit.supply.HXNumOfBoreHole = max(1, floor(units.Btu_h2Ton(unit.supply.Cool_Capacity) + 0.5))
                # unit.supply.HXVertDepth = floor(unit.supply.VertHXBoreLength / unit.supply.HXNumOfBoreHole)
                # MinHXVertDepth = 0.15 * unit.supply.HXVertSpacing  # 0.15 is the maximum Spacing2DepthRatio defined for the G-function in EnergyPlus.bmi
        
                # for _tmp in range(5):
                    # if unit.supply.HXVertDepth < MinHXVertDepth and unit.supply.HXNumOfBoreHole > 1:
                        # unit.supply.HXNumOfBoreHole = unit.supply.HXNumOfBoreHole - 1
                        # unit.supply.HXVertDepth = floor(unit.supply.VertHXBoreLength / unit.supply.HXNumOfBoreHole)
        
                    # elif unit.supply.HXVertDepth > 345:
                        # unit.supply.HXNumOfBoreHole = unit.supply.HXNumOfBoreHole + 1
                        # unit.supply.HXVertDepth = floor(unit.supply.VertHXBoreLength / unit.supply.HXNumOfBoreHole)
                        
                # unit.supply.HXVertDepth = floor(unit.supply.VertHXBoreLength / unit.supply.HXNumOfBoreHole) + 5
        
            # elif unit.supply.HXVertDepth != Constants.SizingAuto and unit.supply.HXNumOfBoreHole == Constants.SizingAuto:
                # unit.supply.HXNumOfBoreHole = floor(unit.supply.VertHXBoreLength / unit.supply.HXVertDepth + 0.5)
                # unit.supply.HXVertDepth = float(unit.supply.HXVertDepth)
        
            # elif unit.supply.HXNumOfBoreHole != Constants.SizingAuto and unit.supply.HXVertDepth == Constants.SizingAuto:
                # unit.supply.HXNumOfBoreHole = float(unit.supply.HXNumOfBoreHole)
                # unit.supply.HXVertDepth = floor(unit.supply.VertHXBoreLength / unit.supply.HXNumOfBoreHole) + 5
        
            # else:
                # SimWarning("User is hard sizing the bore field, improper sizing may lead to unbalanced / unsteady ground loop temperature and erroneous prediction of system energy related cost.")
                # unit.supply.HXNumOfBoreHole = float(unit.supply.HXNumOfBoreHole)
                # unit.supply.HXVertDepth = float(unit.supply.HXVertDepth)
        
            # unit.supply.VertHXBoreLength = unit.supply.HXVertDepth * unit.supply.HXNumOfBoreHole

            # if unit.supply.HXVertBoreConfig == Constants.SizingAuto:
                # if unit.supply.HXNumOfBoreHole == 1:
                    # unit.supply.HXVertBoreConfig = Constants.BoreConfigSingle
                # elif unit.supply.HXNumOfBoreHole == 2:
                    # unit.supply.HXVertBoreConfig = Constants.BoreConfigLine
                # elif unit.supply.HXNumOfBoreHole == 3:
                    # unit.supply.HXVertBoreConfig = Constants.BoreConfigLine
                # elif unit.supply.HXNumOfBoreHole == 4:
                    # unit.supply.HXVertBoreConfig = Constants.BoreConfigRectangle
                # elif unit.supply.HXNumOfBoreHole == 5:
                    # unit.supply.HXVertBoreConfig = Constants.BoreConfigUconfig
                # elif unit.supply.HXNumOfBoreHole > 5:
                    # unit.supply.HXVertBoreConfig = Constants.BoreConfigLine
        
    else
        mj8.Heat_Capacity = 0
        mj8.Heat_AirFlowRate = 0
    end

    # Use fixed airflow rates if provided
    # FIXME
    #if unit.supply.Cool_AirFlowRate != 0 and unit.cooling_airflow_rate is not None:
    #    unit.supply.Cool_AirFlowRate = unit.cooling_airflow_rate
    #if unit.supply.Heat_AirFlowRate != 0 and unit.heating_airflow_rate is not None:
    #    unit.supply.Heat_AirFlowRate = unit.heating_airflow_rate
    
    mj8.Fan_AirFlowRate = [mj8.Heat_AirFlowRate, mj8.Cool_AirFlowRate].max
  
    return mj8
  end
  
  def processFinishedBasementFlowRatio(runner, model, unit, mj8, weather)
    '''
    Finished Basement Flow Ratio
    '''
    
    return nil if mj8.nil?
    
    # FIXME
    # if simpy.hasSpaceType(geometry, Constants.SpaceFinBasement, unit):
        
        # if unit.basement_airflow_ratio is not None:
            # unit.supply.FBsmt_FlowRatio = unit.basement_airflow_ratio
            
        # else:
            # # Divide up flow rate to Living and Finished Bsmt based on MJ8 loads
            
            # # mj8.HeatingLoad_FBsmt = mj8.HeatingLoad * (mj8.HeatingLoad_FBsmt + mj8.HeatingLoad_Inf_FBsmt) / mj8.HeatingLoad_Inter
            # mj8.HeatingLoad_FBsmt = mj8.HeatingLoad_FBsmt + mj8.HeatingLoad_Inf_FBsmt - mj8.DuctLoad_FinBasement
            
            # # Use a minimum flow ratio of 1%. Low flow ratios can be calculated for buildings with inefficient above grade construction
            # # or poor ductwork in the finished basement.  
            # unit.supply.FBsmt_FlowRatio = max(mj8.HeatingLoad_FBsmt / mj8.HeatingLoad, 0.01)

    # else:
        # unit.supply.FBsmt_FlowRatio = 0.0

    return mj8
  end
  
  def processEfficientCapacityDerate(runner, model, unit, mj8, weather, has_hvac, tonnages, eER_CapacityDerateFactor, cOP_CapacityDerateFactor)
    '''
    AC & HP Efficiency Capacity Derate
    '''
    
    return nil if mj8.nil?
    
    if not has_hvac['AirConditioner'] and not has_hvac['HeatPump']
        return mj8
    end

    # EER_CapacityDerateFactor values correspond to 1.5, 2, 3, 4, 5 ton air-conditioners. Interpolate in between nominal sizes.
    aC_Tons = units.Btu_h2Ton(unit.supply.Cool_Capacity)
    
    eER_Multiplier = 1
    
    if aC_Tons <= 1.5
        eER_Multiplier = eER_CapacityDerateFactor[0]
    elsif aC_Tons <= 5
        index = int(floor(aC_Tons) - 1)
        eER_Multiplier = MathTools.interp2(aC_Tons, tonnages[index-1], tonnages[index],
                                      eER_CapacityDerateFactor[index-1], 
                                      eER_CapacityDerateFactor[index])
    elsif aC_Tons <= 10
        index = int(floor(aC_Tons/2) - 1)
        eER_Multiplier = MathTools.interp2(aC_Tons/2, tonnages[index-1], tonnages[index],
                                      eER_CapacityDerateFactor[index-1], 
                                      eER_CapacityDerateFactor[index])
    else
        eER_Multiplier = eER_CapacityDerateFactor[-1]
    end
    
    for speed in 0..(sim.curves.Number_Speeds-1)
        # FIXME
        #unit.supply.CoolingEIR[speed] = unit.supply.CoolingEIR[speed] / eER_Multiplier
    end
    
    if has_hvac['HeatPump']
    
        cOP_Multiplier = 1
    
        if aC_Tons <= 1.5
            cOP_Multiplier = cOP_CapacityDerateFactor[0]
        elsif aC_Tons <= 5
            index = int(floor(aC_Tons) - 1)
            cOP_Multiplier = MathTools.interp2(aC_Tons, tonnages[index-1], tonnages[index], 
                                               cOP_CapacityDerateFactor[index-1], 
                                               cOP_CapacityDerateFactor[index])
        elsif aC_Tons <= 10
            index = int(floor(aC_Tons/2) - 1)
            cOP_Multiplier = MathTools.interp2(aC_Tons/2, tonnages[index-1], tonnages[index], 
                                               cOP_CapacityDerateFactor[index-1], 
                                               cOP_CapacityDerateFactor[index])
        else
            cOP_Multiplier = unit.supply.COP_CapacityDerateFactor[-1]
        end
    
        for speed in 0..(sim.curves.Number_Speeds-1)
            # FIXME
            #unit.supply.HeatingEIR[speed] = unit.supply.HeatingEIR[speed] / cOP_Multiplier
        end
        
    end
  
    return mj8
  end
    
  def processDehumidifierSizing(runner, model, unit, mj8, weather, has_hvac, minCoolingCapacity, num_speeds, cOOL_CAP_FT_SPEC_coefficients, capacity_Ratio_Cooling)
    '''
    Dehumidifier Sizing
    '''
    
    return nil if mj8.nil?
    
    # FIXME: Handle 1..n speeds with the same code
    if has_hvac['Cooling'] and mj8.Cool_Capacity > minCoolingCapacity
    
        dehum_design_db = weather.design.DehumidDrybulb
        
        if num_speeds > 1
            
            if not has_hvac['MiniSplitHP']
            
                totalCap_CurveValue_1 = MathTools.biquadratic(mj8.wetbulb_indoor_dehumid, dehum_design_db, cOOL_CAP_FT_SPEC_coefficients[0])
                dehumid_AC_TotCap_1 = totalCap_CurveValue_1 * mj8.Cool_Capacity * capacity_Ratio_Cooling[0]
            
                #TODO: This could be improved by not using this correlation with added Python capability in BEopt2
                sensibleCap_CurveValue_1 = 1.08464364 + 0.002096954 * ((mj8.Cool_AirFlowRate * unit.supply.fanspeed_ratio[0]) / 
                                           OpenStudio::convert(dehumid_AC_TotCap_1,"Btu/h","ton").get) - 0.005766327 * dehum_design_db - \
                                           0.000011147 * ((mj8.Cool_AirFlowRate * unit.supply.fanspeed_ratio[0]) / 
                                           OpenStudio::convert(dehumid_AC_TotCap_1,"Btu/h","ton").get) * dehum_design_db
                dehumid_AC_SensCap_1 = sensibleCap_CurveValue_1 * mj8.Cool_SensCap * capacity_Ratio_Cooling[0]
            
                if mj8.DehumidLoad_Sens > dehumid_AC_SensCap_1
                    # AC will operate in Stage 2
                    totalCap_CurveValue_2 = MathTools.biquadratic(mj8.wetbulb_indoor_dehumid, dehum_design_db, cOOL_CAP_FT_SPEC_coefficients[1])
                    dehumid_AC_TotCap_2 = totalCap_CurveValue_2 * mj8.Cool_Capacity
            
                    sensibleCap_CurveValue_2 = 1.08464364 + 0.002096954 * (mj8.Cool_AirFlowRate / \
                                               OpenStudio::convert(dehumid_AC_TotCap_2,"Btu/h","ton").get) - 0.005766327 * dehum_design_db - \
                                               0.000011147 * (mj8.Cool_AirFlowRate / OpenStudio::convert(dehumid_AC_TotCap_2,"Btu/h","ton").get) * \
                                               dehum_design_db
                    dehumid_AC_SensCap_2 = sensibleCap_CurveValue_2 * mj8.Cool_SensCap
            
                    dehumid_AC_LatCap = dehumid_AC_TotCap_2 - dehumid_AC_SensCap_2
                    dehumid_AC_RTF = [0, mj8.DehumidLoad_Sens / dehumid_AC_SensCap_2].max
                else
                    dehumid_AC_LatCap = dehumid_AC_TotCap_1 - dehumid_AC_SensCap_1
                    dehumid_AC_RTF = [0, mj8.DehumidLoad_Sens / dehumid_AC_SensCap_1].max
                end
                    
            else
                
                dehumid_AC_TotCap_i_1 = 0
                for i in 0..(Constants.Num_Speeds_MSHP - 1)
                
                    # FIXME: This has unit conversions and above equations don't. Is this correct?
                    totalCap_CurveValue = MathTools.biquadratic(OpenStudio::convert(mj8.wetbulb_indoor_dehumid,"F","C").get, OpenStudio::convert(dehum_design_db,"F","C").get, cOOL_CAP_FT_SPEC_coefficients[i])
                    
                    dehumid_AC_TotCap = totalCap_CurveValue * mj8.Cool_Capacity * capacity_Ratio_Cooling[i]
                    sens_cap = sHR_Rated[i] * dehumid_AC_TotCap  #TODO: This could be slightly improved by not assuming a constant SHR
                  
                    if sens_cap >= mj8.DehumidLoad_Sens
                        
                        if i > 0
                            dehumid_AC_SensCap = mj8.DehumidLoad_Sens
                            
                            # Determine portion of load met by speed i and i-1 using: Q_i*s + Q_i-1*(s-1) = Q_load
                            s = (mj8.DehumidLoad_Sens + dehumid_AC_TotCap_i_1 * sHR_Rated[i-1]) / (sens_cap + dehumid_AC_TotCap_i_1 * sHR_Rated[i-1])
                            
                            dehumid_AC_LatCap = s * (1 - sHR_Rated[i]) * dehumid_AC_TotCap + \
                                                (1 - s) * (1 - sHR_Rated[i-1]) * dehumid_AC_TotCap_i_1
                            
                            dehumid_AC_RTF = 1
                        else
                            dehumid_AC_SensCap = sens_cap
                            dehumid_AC_LatCap = dehumid_AC_TotCap - dehumid_AC_SensCap
                            dehumid_AC_RTF = max(0, mj8.DehumidLoad_Sens / dehumid_AC_SensCap)
                        end
                        
                        break
                    
                    end
                    
                    dehumid_AC_TotCap_i_1 = dehumid_AC_TotCap                        
                
                end
                
            end
            
        else       # Single Speed
            
            if not has_hvac['GroundSourceHP']
                enteringTemp = dehum_design_db
            else   # Use annual average temperature for this evaluation
                enteringTemp = weather.data.AnnualAvgDrybulb
            end
            
             totalCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_dehumid, enteringTemp, cOOL_CAP_FT_SPEC_coefficients[0])
            dehumid_AC_TotCap = totalCap_CurveValue * mj8.Cool_Capacity
        
            if has_hvac['RoomAirConditioner']     # Assume constant SHR for now.
                  
                sensibleCap_CurveValue = 0.5 # FIXME: unit.room_air_conditioner.RoomACSHR

            else
                
                sensibleCap_CurveValue = 1.08464364 + 0.002096954 * (mj8.Cool_AirFlowRate / \
                                         OpenStudio::convert(dehumid_AC_TotCap,"Btu/h","ton").get) - 0.005766327 * enteringTemp - \
                                         0.000011147 * (mj8.Cool_AirFlowRate / OpenStudio::convert(dehumid_AC_TotCap,"Btu/h","ton").get) * \
                                         dehum_design_db
                                     
            end
            
            dehumid_AC_SensCap = sensibleCap_CurveValue * mj8.Cool_SensCap
            dehumid_AC_LatCap = dehumid_AC_TotCap - dehumid_AC_SensCap
            dehumid_AC_RTF = [0, mj8.DehumidLoad_Sens / dehumid_AC_SensCap].max
            
        end
            
    else
        
        dehumid_AC_SensCap = 0
        dehumid_AC_LatCap = 0
        dehumid_AC_RTF = 0
        
    end
            
            
    # Determine the average total latent load (there's duct latent load only when the AC is running)
    dehumidLoad_Lat = max(0, mj8.DehumidLoad_Inter_Lat + mj8.dse_Dehumid_Latent * dehumid_AC_RTF)

    air_h_fg = 1075.6  # Btu/lbm

    # Calculate the required water removal (in L/day) at 75 deg-F DB, 50% RH indoor conditions
    dehumid_WaterRemoval = [0, (dehumidLoad_Lat - dehumid_AC_RTF * dehumid_AC_LatCap) / air_h_fg / \
                                  Properties.H2O_l.rho * units.ft32liter(1) * units.day2hr(1)].max

    zone_Water_Remove_Cap_Ft_DB_RH_coefficients = [-1.162525707, 0.02271469, -0.000113208, 0.021110538, -0.0000693034, 0.000378843] # FIXME
                                  
    # Determine the rated water removal rate using the performance curve
    dehumid_CurveValue = MathTools.biquadratic(OpenStudio::convert(mj8.cooling_setpoint,"F","C").get, mj8.RH_indoor_dehumid * 100, zone_Water_Remove_Cap_Ft_DB_RH_coefficients)
    mj8.Dehumid_WaterRemoval_Auto = dehumid_WaterRemoval / dehumid_CurveValue
  
    return mj8
  end
    
  def get_shelter_class(model, unit)

    neighbor_offset_ft = Geometry.get_closest_neighbor_distance(model)
    unit_height_ft = Geometry.get_building_height(unit.spaces)
    exposed_wall_ratio = Geometry.calculate_above_grade_exterior_wall_area(unit.spaces) / Geometry.calculate_above_grade_wall_area(unit.spaces)

    if exposed_wall_ratio > 0.5 # 3 or 4 exposures; Table 5D
        if neighbor_offset_ft == 0
            shelter_class = 2 # Typical shelter for isolated rural house
        elsif neighbor_offset_ft > unit_height_ft
            shelter_class = 3 # Typical shelter caused by other buildings across the street
        else
            shelter_class = 4 # Typical shelter for urban buildings where sheltering obstacles are less than one building height away
        end
    else # 0, 1, or 2 exposures; Table 5E
        if neighbor_offset_ft == 0
            if exposed_wall_ratio > 0.25 # 2 exposures; Table 5E
                shelter_class = 2 # Typical shelter for isolated rural house
            else # 1 exposure; Table 5E
                shelter_class = 3 # Typical shelter caused by other buildings across the street
            end
        elsif neighbor_offset_ft > unit_height_ft
            shelter_class = 4 # Typical shelter for urban buildings where sheltering obstacles are less than one building height away
        else
            shelter_class = 5 # Typical shelter for urban buildings where sheltering obstacles are less than one building height away
        end
    end
        
    return shelter_class
  end
  
  def get_wallgroup_wood_or_steel_stud(cavity_ins_r_value)
    '''
    Determine the base Group Number based on cavity R-value for siding or stucco walls
    '''
    if cavity_ins_r_value < 2
        wallGroup = 1   # A
    elsif cavity_ins_r_value <= 11
        wallGroup = 2   # B
    elsif cavity_ins_r_value <= 13
        wallGroup = 3   # C
    elsif cavity_ins_r_value <= 15
        wallGroup = 4   # D
    elsif cavity_ins_r_value <= 19
        wallGroup = 5   # E
    elsif cavity_ins_r_value <= 21
        wallGroup = 6   # F
    else
        wallGroup = 7   # G
    end
    
    return wallGroup
  end
  
  def get_ventilation_rates(mechVentType, whole_house_vent_rate, mechVentApparentSensibleEffectiveness, mechVentLatentEffectiveness, mechVentTotalEfficiency)
    q_unb = 0
    q_bal_Sens = 0
    q_bal_Lat = 0
    ventMultiplier = 1

    if mechVentType == 'Constants.VentTypeExhaust'
        q_unb = whole_house_vent_rate
        ventMultiplier = 1
    elsif mechVentType == 'Constants.VentTypeSupply'
        q_unb = whole_house_vent_rate
        ventMultiplier = -1
    elsif mechVentType == 'Constants.VentTypeBalanced'
        if not mechVentApparentSensibleEffectiveness.nil? and not mechVentLatentEffectiveness.nil?
            q_bal_Sens = whole_house_vent_rate * (1 - mechVentApparentSensibleEffectiveness)
            q_bal_Lat = whole_house_vent_rate * (1 - mechVentLatentEffectiveness)
        else
            q_bal_Sens = whole_house_vent_rate * (1 - mechVentTotalEfficiency)
            q_bal_Lat = q_bal_Sens
        end
    end
    
    return [q_unb, q_bal_Sens, q_bal_Lat, ventMultiplier]
  end
  
  def get_surface_uvalue(runner, surface, surface_type)
    if surface_type.downcase.include?("window")
        simple_glazing = get_window_simple_glazing(runner, surface)
        return nil if simple_glazing.nil?
        return simple_glazing.uFactor
     else
        if not surface.construction.is_initialized
            runner.registerError("Construction not assigned to '#{surface.name.to_s}'.")
            return nil
        end
        construction = surface.construction.get
        return surface.uFactor.get
     end
  end
  
  def get_window_simple_glazing(runner, surface)
    if not surface.construction.is_initialized
        runner.registerError("Construction not assigned to '#{surface.name.to_s}'.")
        return nil
    end
    construction = surface.construction.get
    if not construction.to_LayeredConstruction.is_initialized
        runner.registerError("Expected LayeredConstruction for '#{surface.name.to_s}'.")
        return nil
    end
    window_layered_construction = construction.to_LayeredConstruction.get
    if not window_layered_construction.getLayer(0).to_SimpleGlazing.is_initialized
        runner.registerError("Expected SimpleGlazing for '#{surface.name.to_s}'.")
        return nil
    end
    simple_glazing = window_layered_construction.getLayer(0).to_SimpleGlazing.get
    return simple_glazing
  end
  
  def get_window_shgc(runner, surface)
    simple_glazing = get_window_simple_glazing(runner, surface)
    return [nil, nil] if simple_glazing.nil?
    shgc_with_IntGains_shade_heat = simple_glazing.solarHeatGainCoefficient
    if not surface.shadingControl.is_initialized
        runner.registerError("Expected shading control for window '#{surface.name.to_s}'.")
        return [nil, nil]
    end
    shading_control = surface.shadingControl.get
    if not shading_control.shadingMaterial.is_initialized
        runner.registerError("Expected shading material for window '#{surface.name.to_s}'.")
        return [nil, nil]
    end
    shading_material = shading_control.shadingMaterial.get
    if not shading_material.to_Shade.is_initialized
        runner.registerError("Expected shade for window '#{surface.name.to_s}'.")
        return [nil, nil]
    end
    shade = shading_material.to_Shade.get
    int_shade_heat_to_cool_ratio = shade.solarTransmittance
    shgc_with_IntGains_shade_cool = shgc_with_IntGains_shade_heat * int_shade_heat_to_cool_ratio
    return [shgc_with_IntGains_shade_cool, shgc_with_IntGains_shade_heat]
  end
  
  def calc_heat_cfm(load, mj8, htg_supply_air_temp)
    return load / (1.1 * mj8.acf * (htg_supply_air_temp - mj8.heating_setpoint))
  end
  
  def calc_heating_duct_load(mj8, heating_load_inter, supply_duct_surface_area, return_duct_surface_area, ductLocationFracConduction, ducts_not_in_living, ductNormLeakageToOutside, supply_duct_loss, return_duct_loss, supply_duct_r, return_duct_r, htg_supply_air_temp, t_amb, ductSystemEfficiency)

    # Supply and return duct surface areas located outside conditioned space
    dse_As = supply_duct_surface_area * ductLocationFracConduction
    dse_Ar = return_duct_surface_area
        
    # Initialize for the iteration
    delta = 1
    heatingLoad_Inter_Prev = heating_load_inter
    heating_cfm = calc_heat_cfm(heating_load_inter, mj8, htg_supply_air_temp)
    
    for _iter in 0..19
        break if delta.abs <= 0.001

        dse_DEcorr_heating, _dse_dTe_heating = calc_dse(mj8, heating_cfm, heatingLoad_Inter_Prev, t_amb, dse_As, dse_Ar, mj8.heating_setpoint, mj8.dse_Fregain, nil, false, ductNormLeakageToOutside, supply_duct_loss, return_duct_loss, ducts_not_in_living, supply_duct_r, return_duct_r, ductSystemEfficiency)

        # Calculate the increase in heating load due to ducts (Approach: DE = Qload/Qequip -> Qducts = Qequip-Qload)
        heatingLoad_Inter_Next = heating_load_inter / dse_DEcorr_heating
        
        # Calculate the change since the last iteration
        delta = (heatingLoad_Inter_Next - heatingLoad_Inter_Prev) / heatingLoad_Inter_Prev
        
        # Update the flow rate for the next iteration
        heatingLoad_Inter_Prev = heatingLoad_Inter_Next
        heating_cfm = calc_heat_cfm(heatingLoad_Inter_Next, mj8, htg_supply_air_temp)
    end

    return heatingLoad_Inter_Next - heating_load_inter

  end
  
  def calc_dse(mj8, cfm_inter, load_Inter_Sens, dse_Tamb, dse_As, dse_Ar, t_setpoint, dse_Fregain, coolingLoad_Tot, isCooling, ductNormLeakageToOutside, supply_duct_loss, return_duct_loss, ducts_not_in_living, supply_duct_r, return_duct_r, ductSystemEfficiency)
    '''
    Calculate the Distribution System Efficiency using the method of ASHRAE Standard 152 (used for heating and cooling).
    '''
    
    # Supply and return duct leakage flow rates
    if not ductNormLeakageToOutside.nil?
        # FIXME: simpy.calc_duct_leakage_from_test(sim, unit.ducts, unit.finished_floor_area, CFM_Inter)
    end
    
    dse_Qs = supply_duct_loss * cfm_inter
    dse_Qr = return_duct_loss * cfm_inter

    # Supply and return conduction functions, Bs and Br
    if ducts_not_in_living
        dse_Bs = Math.exp((-1.0 * dse_As) / (60 * cfm_inter * Gas.Air.rho * Gas.Air.cp * supply_duct_r))
        dse_Br = Math.exp((-1.0 * dse_Ar) / (60 * cfm_inter * Gas.Air.rho * Gas.Air.cp * return_duct_r))

    else
        dse_Bs = 1
        dse_Br = 1
    end

    dse_a_s = (cfm_inter - dse_Qs) / cfm_inter
    dse_a_r = (cfm_inter - dse_Qr) / cfm_inter

    dse_dTe = load_Inter_Sens / (1.1 * mj8.acf * cfm_inter)
    dse_dT = t_setpoint - dse_Tamb

    # Calculate the delivery effectiveness (Equation 6-23) 
    # NOTE: This equation is for heating but DE equation for cooling requires psychrometric calculations. This should be corrected.
    if isCooling
        dse_DE = ((dse_a_s * 60 * cfm_inter * Gas.Air.rho) / (-1 * coolingLoad_Tot)) * \
                  (((-1 * coolingLoad_Tot) / (60 * cfm_inter * Gas.Air.rho)) + \
                   (1 - dse_a_r) * (mj8.dse_h_Return_Cooling - mj8.enthalpy_indoor_cooling) + \
                   dse_a_r * Gas.Air.cp * (dse_Br - 1) * dse_dT + \
                   Gas.Air.cp * (dse_Bs - 1) * (mj8.LAT - dse_Tamb))
        
        # Calculate the sensible heat transfer from surroundings
        coolingLoad_Ducts_Sens = (1 - [dse_DE,0].max) * load_Inter_Sens
    else
        dse_DE = (dse_a_s * dse_Bs - 
                  dse_a_s * dse_Bs * (1 - dse_a_r * dse_Br) * (dse_dT / dse_dTe) - 
                  dse_a_s * (1 - dse_Bs) * (dse_dT / dse_dTe))
        coolingLoad_Ducts_Sens = nil
    end

    # Calculate the delivery effectiveness corrector for regain (Equation 6-40)
    dse_DEcorr = (dse_DE + dse_Fregain * (1 - dse_DE) + 
                  dse_Br * (dse_a_r * dse_Fregain - dse_Fregain))

    # Limit the DE to a reasonable value to prevent negative values and huge equipment
    dse_DEcorr = [dse_DEcorr, 0.25].max
    dse_DEcorr = [dse_DEcorr, 1.00].min
    
    if not ductSystemEfficiency.nil?
        dse_DEcorr = ductSystemEfficiency
    end
    
    return dse_DEcorr, dse_dTe, coolingLoad_Ducts_Sens
  end
  
  def calculate_sensible_latent_split(mj8, acf, return_duct_loss, cooling_load_tot)
    # Calculate the latent duct leakage load (Manual J accounts only for return duct leakage)
    dse_Cooling_Latent = [0, 0.68 * acf * return_duct_loss * mj8.CoolingCFM_Inter * 
                             (mj8.cool_design_grains - mj8.grains_indoor_cooling)].max
    
    # Calculate final latent and load
    mj8.CoolingLoad_Lat = mj8.CoolingLoad_Inter_Lat + dse_Cooling_Latent
    mj8.CoolingLoad_Sens = cooling_load_tot - mj8.CoolingLoad_Lat
    
    return mj8
  end
  
  def get_surfaces_for_unit(unit)
    unit_surfaces = {}
    unit_surfaces['living_walls_exterior'] = []
    unit_surfaces['living_walls_interzonal'] = []
    unit_surfaces['living_roofs_exterior'] = []
    unit_surfaces['living_floors_exterior'] = []
    unit_surfaces['living_floors_interzonal'] = []
    unit_surfaces['fbasement_walls_exterior'] = []
    unit_surfaces['fbasement_floors_exterior'] = []
    unit.spaces.each do |space|
        next if not Geometry.space_is_finished(space)
        space.surfaces.each do |surface|
            if surface.surfaceType.downcase == "wall"
                if surface.outsideBoundaryCondition.downcase == "outdoors" and not unit_surfaces['living_walls_exterior'].include?(surface)
                    unit_surfaces['living_walls_exterior'] << surface
                elsif surface.outsideBoundaryCondition.downcase == "ground" and not unit_surfaces['fbasement_walls_exterior'].include?(surface)
                    unit_surfaces['fbasement_walls_exterior'] << surface
                elsif surface.adjacentSurface.is_initialized and not Geometry.space_is_finished(surface.adjacentSurface.get.space.get) and not unit_surfaces['living_walls_interzonal'].include?(surface)
                    unit_surfaces['living_walls_interzonal'] << surface
                end
            elsif surface.surfaceType.downcase == "roofceiling"
                if surface.outsideBoundaryCondition.downcase == "outdoors" and not unit_surfaces['living_roofs_exterior'].include?(surface)
                    unit_surfaces['living_roofs_exterior'] << surface
                end
            elsif surface.surfaceType.downcase == "floor"
                if surface.outsideBoundaryCondition.downcase == "outdoors" and not unit_surfaces['living_floors_exterior'].include?(surface)
                    unit_surfaces['living_floors_exterior'] << surface
                elsif surface.outsideBoundaryCondition.downcase == "ground" and not unit_surfaces['fbasement_floors_exterior'].include?(surface)
                    unit_surfaces['fbasement_floors_exterior'] << surface
                elsif surface.adjacentSurface.is_initialized and not Geometry.space_is_finished(surface.adjacentSurface.get.space.get) and not unit_surfaces['living_floors_interzonal'].include?(surface)
                    unit_surfaces['living_floors_interzonal'] << surface
                end
            end
        end # surface
    end # space
    return unit_surfaces
  end
  
  def get_hvac_for_unit(runner, model, unit)
    has_hvac = {}
    has_hvac['ForcedAir'] = false
    has_hvac['Cooling'] = false
    has_hvac['Heating'] = false
    has_hvac['AirConditioner'] = false
    has_hvac['RoomAirConditioner'] = false
    has_hvac['Furnace'] = false
    has_hvac['Boiler'] = false
    has_hvac['ElecBaseboard'] = false
    has_hvac['HeatPump'] = false
    has_hvac['MiniSplitHP'] = false
    has_hvac['GroundSourceHP'] = false
    Geometry.get_thermal_zones_from_spaces(unit.spaces).each do |thermal_zone|
        if not HVAC.has_air_loop(model, runner, thermal_zone, false).nil?
            has_hvac['ForcedAir'] = true
        end
        if not HVAC.existing_cooling_equipment(model, runner, thermal_zone).nil?
            has_hvac['Cooling'] = true
        end
        if not HVAC.existing_heating_equipment(model, runner, thermal_zone).nil?
            has_hvac['Heating'] = true
        end
        if not HVAC.has_central_air_conditioner(model, runner, thermal_zone, false, false).nil?
            has_hvac['AirConditioner'] = true
        end
        if not HVAC.has_room_air_conditioner(model, runner, thermal_zone, false).nil?
            has_hvac['RoomAirConditioner'] = true
        end
        if not HVAC.has_furnace(model, runner, thermal_zone, false, false).nil?
            has_hvac['Furnace'] = true
        end
        if not HVAC.has_boiler(model, runner, thermal_zone, false).nil?
            has_hvac['Boiler'] = true
        end
        if not HVAC.has_electric_baseboard(model, runner, thermal_zone, false).nil?
            has_hvac['ElecBaseboard'] = true
        end
        if not HVAC.has_air_source_heat_pump(model, runner, thermal_zone, false).nil?
            has_hvac['HeatPump'] = true
        end
        if not HVAC.has_mini_split_heat_pump(model, runner, thermal_zone, false).nil?
            has_hvac['MiniSplitHP'] = true
        end
        if not HVAC.has_gshp_vert_bore(model, runner, thermal_zone, false).nil?
            has_hvac['GroundSourceHP'] = true
        end
    end
    return has_hvac
  end
  
  def display_Info(runner, mj8, display_initial_data, display_intermediate_data, display_ducts_data)
    if display_initial_data
        s = "Initial Loads:"
        loads = [
                 :HeatingLoad_Cond,
                 :HeatingLoad_Infil,
                 :HeatingLoad_FBsmt,
                 :HeatingLoad_Infil_FBsmt,
                 :CoolingLoad_Windows, 
                 :CoolingLoad_Doors, 
                 :CoolingLoad_Walls, 
                 :CoolingLoad_Roofs, 
                 :CoolingLoad_Floors, 
                 :CoolingLoad_Infil_Sens, 
                 :CoolingLoad_Infil_Lat, 
                 :CoolingLoad_IntGains_Sens, 
                 :CoolingLoad_IntGains_Lat, 
                 :DehumidLoad_Cond,
                 :DehumidLoad_Infil_Sens, 
                 :DehumidLoad_Infil_Lat,
                 :DehumidLoad_IntGains_Sens, 
                 :DehumidLoad_IntGains_Lat,
                ]
        loads.each do |load|
            s += "\n#{load.to_s} = #{mj8.send(load).round(0).to_s} Btu/hr"
        end
        runner.registerInfo("#{s}\n")
    end
    if display_intermediate_data
        s = "Intermediate Loads & Airflows (totals without ducts):"
        loads = [
                 :HeatingLoad_Inter, 
                 :CoolingLoad_Inter_Sens, 
                 :CoolingLoad_Inter_Lat, 
                 :DehumidLoad_Inter_Sens, 
                 :DehumidLoad_Inter_Lat,
                ]
        cfms = [
                :HeatingCFM_Inter, 
                :CoolingCFM_Inter, 
               ]
        loads.each do |load|
            s += "\n#{load.to_s} = #{mj8.send(load).round(0).to_s} Btu/hr"
        end
        cfms.each do |cfm|
            s += "\n#{cfm.to_s} = #{mj8.send(cfm).round(0).to_s} cfm"
        end
        runner.registerInfo("#{s}\n")
    end
    if display_ducts_data
        s = "Duct Loads:"
        loads = [
                 :HeatingLoad,
                 :CoolingLoad_Lat,
                 :CoolingLoad_Sens,
                 :DehumidLoad_Sens,
                ]
        loads.each do |load|
            s += "\n#{load.to_s} = #{mj8.send(load).round(0).to_s} Btu/hr"
        end
        runner.registerInfo("#{s}\n")
    end
  end
  
end #end the measure

class Numeric
  def degrees
    self * Math::PI / 180 
  end
end

#this allows the measure to be use by the application
ProcessHVACSizing.new.registerWithApplication