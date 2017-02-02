#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/weather"

#start the measure
class ProcessHVACSizing < OpenStudio::Ruleset::ModelUserScript

  class MJ8
    def initialize
    end
    attr_accessor(:daily_range_temp_adjust, :acf, :Cs, :Cw, 
                  :cool_setpoint, :heat_setpoint, :cool_design_grains, :dehum_design_grains, :ctd, :htd, 
                  :dtd, :daily_range_num, :grains_indoor_cooling, :wetbulb_indoor_cooling, :enthalpy_indoor_cooling, 
                  :RH_indoor_dehumid, :grains_indoor_dehumid, :wetbulb_indoor_dehumid, :LAT,
                  :cool_design_temps, :heat_design_temps, :dehum_design_temps)
  end
  
  class ZoneValues
    # Thermal zone loads
    def initialize
    end
    attr_accessor(:Cool_Windows, :Cool_Doors, :Cool_Walls, :Cool_Roofs, :Cool_Floors,
                  :Dehumid_Windows, :Dehumid_Doors, :Dehumid_Walls, :Dehumid_Roofs, :Dehumid_Floors,
                  :Heat_Windows, :Heat_Doors, :Heat_Walls, :Heat_Roofs, :Heat_Floors,
                  :Cool_Infil_Sens, :Cool_Infil_Lat, :Cool_IntGains_Sens, :Cool_IntGains_Lat,
                  :Dehumid_Infil_Sens, :Dehumid_Infil_Lat, :Dehumid_IntGains_Sens, :Dehumid_IntGains_Lat,
                  :Heat_Infil)
  end
  
  class UnitInitialValues
    # Unit initial loads (aggregated across thermal zones and excluding ducts) and airflow rates
    def initialize
    end
    attr_accessor(:Cool_Load_Sens, :Cool_Load_Lat, :Cool_Load_Tot, :Cool_Airflow,
                  :Dehumid_Load_Sens, :Dehumid_Load_Lat, 
                  :Heat_Load, :Heat_Airflow,
                  :LAT)
  end
  
  class UnitFinalValues
    # Unit final loads (including ducts), airflow rates, and equipment capacities
    def initialize
    end
    attr_accessor(:Cool_Load_Sens, :Cool_Load_Lat, :Cool_Load_Tot, 
                  :Cool_Load_Ducts_Sens, :Cool_Load_Ducts_Lat, :Cool_Load_Ducts_Tot,
                  :Cool_Capacity, :Cool_Capacity_Sens, :Cool_Airflow,
                  :Dehumid_Load_Sens, :Dehumid_Load_Ducts_Lat, 
                  :Heat_Load, :Heat_Load_Ducts, 
                  :Heat_Capacity, :Heat_Capacity_Supp, :Heat_Airflow,
                  :Fan_Airflow, :dse_Fregain, :Dehumid_WaterRemoval, :TotalCap_CurveValue)
  end
  
  class HVACInfo
    # Model info for HVAC
    def initialize
    end
    attr_accessor(:HasCooling, :HasHeating, :FixedCoolingCapacity, :FixedHeatingCapacity,
                  :HasForcedAir, :HasCentralAirConditioner, :HasRoomAirConditioner,
                  :HasFurnace, :HasBoiler, :HasElecBaseboard,
                  :HasAirSourceHeatPump, :HasMiniSplitHeatPump, :HasGroundSourceHeatPump,
                  :NumSpeedsCooling, :NumSpeedsHeating, :CoolingCFMs, :HeatingCFMs, 
                  :COOL_CAP_FT_SPEC_coefficients, :HEAT_CAP_FT_SPEC_coefficients,
                  :HtgSupplyAirTemp, :SHRRated, :CapacityRatioCooling, :CapacityRatioHeating, 
                  :MinOutdoorTemp, :HeatingCapacityOffset, :OverSizeLimit)
  end
  
  class DuctsInfo
    # Model info for ducts
    def initial
    end
    attr_accessor(:Has, :NotInLiving, :SystemEfficiency, :NormLeakageToOutside,
                  :SupplySurfaceArea, :ReturnSurfaceArea, :LocationFrac,
                  :SupplyLoss, :ReturnLoss, :SupplyRvalue, :ReturnRvalue,
                  :Location, :LocationSpace)
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
    building_num_stories = 2 # FIXME: Should finished attic count as a separate story? It wasn't in BEopt

    # Get year of model
    modelYear = 2009
    if model.yearDescription.is_initialized
        modelYear = model.yearDescription.get.assumedYear
    end
    
    northAxis = model.getBuilding.northAxis
    isExistingHome = false # FIXME
    hpSizeForMaxLoad = false # FIXME Auto size the heat pump heating capacity based on the heating design temperature (if the heating capacity is larger than the cooling capacity)
    spaceConditionedMult = 1.0 # FIXME
    minCoolingCapacity = 1 # Btu/hr
    
    # Based on EnergyPlus's model for calculating SHR at off-rated conditions. This curve fit 
    # avoids the iterations in the actual model. It does not account for altitude or variations 
    # in the SHRRated. It is a function of ODB (MJ design temp) and CFM/Ton (from MJ)
    shr_biquadratic_coefficients = [1.08464364, 0.002096954, 0, -0.005766327, 0, -0.000011147]
    
    
    mj8 = processSiteCalcsAndDesignTemps(runner, mj8, weather, model)
    return false if mj8.nil?
        
    units.each do |unit|
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        
        # Get floor area for unit spaces with people objects
        # FIXME: Is there a better approach here?
        spaces_with_people = []
        unit.spaces.each do |space|
            next if space.people.size == 0
            spaces_with_people << space
        end
        unit_ffa_for_people = Geometry.get_finished_floor_area_from_spaces(spaces_with_people)
        
        # Get unit number
        unit_num = Geometry.get_unit_number(model, unit)
        
        # Get shelter class
        unit_shelter_class = get_shelter_class(model, unit)
        
        # Get thermal zones for the unit
        unit_thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
            
        # Get HVAC system info
        hvac = get_hvac_for_unit(runner, model, unit_thermal_zones)
        return false if hvac.nil?
        
        ducts = get_ducts_for_unit(runner, model, unit.spaces, hvac, building_num_stories)
        return false if ducts.nil?

        # Calculate loads for each thermal zone in the unit
        zones_loads = {}
        unit_thermal_zones.each do |thermal_zone|
            next if not Geometry.zone_is_finished(thermal_zone)
            zone_loads = processZoneLoads(runner, mj8, thermal_zone, weather, northAxis, nbeds, unit_ffa_for_people, modelYear, model.alwaysOnDiscreteSchedule, unit_shelter_class, building_num_stories)
            return false if zone_loads.nil?
            zones_loads[thermal_zone] = zone_loads
        end
        display_zone_loads(runner, unit_num, zones_loads)
        
        # Aggregate zone loads into initial unit loads
        unit_init = processIntermediateTotalLoads(runner, mj8, zones_loads, weather, hvac)
        return false if unit_init.nil?
        display_unit_initial_results(runner, unit_num, unit_init)
        
        # Process unit duct loads and equipment
        unit_final = processUnitLoadsAndEquipment(runner, mj8, unit_init, weather, hvac, ducts, minCoolingCapacity, shr_biquadratic_coefficients, isExistingHome, hpSizeForMaxLoad, spaceConditionedMult)
        return false if unit_final.nil?
        
        display_unit_final_results(runner, unit_num, unit_final)
                
    end # unit
    
    return true
 
  end #end the run method
  
  def processSiteCalcsAndDesignTemps(runner, mj8, weather, model)
    '''
    Site Calculations and Design Temperatures
    '''
    
    mj8 = MJ8.new
    
    # CLTD adjustments based on daily temperature range
    mj8.daily_range_temp_adjust = [4, 0, -5]

    # Manual J inside conditions
    mj8.cool_setpoint = 75
    mj8.heat_setpoint = 70
    
    heat_design_db = weather.design.HeatingDrybulb
    cool_design_db = weather.design.CoolingDrybulb
    dehum_design_db = weather.design.DehumidDrybulb
           
    mj8.cool_design_grains = UnitConversion.lbm_lbm2grains(weather.design.CoolingHumidityRatio)
    mj8.dehum_design_grains = UnitConversion.lbm_lbm2grains(weather.design.DehumidHumidityRatio)
    
    # # Calculate the design temperature differences
    mj8.ctd = cool_design_db - mj8.cool_setpoint
    mj8.htd = mj8.heat_setpoint - heat_design_db
    mj8.dtd = dehum_design_db - mj8.cool_setpoint
    
    # # Calculate the average Daily Temperature Range (DTR) to determine the class (low, medium, high)
    dtr = weather.design.DailyTemperatureRange
    
    if dtr < 16
        mj8.daily_range_num = 0   # Low
    elsif dtr > 25
        mj8.daily_range_num = 2   # High
    else
        mj8.daily_range_num = 1   # Medium
    end
        
    # Altitude Correction Factors (ACF) taken from Table 10A (sea level - 12,000 ft)
    acfs = [1.0, 0.97, 0.93, 0.89, 0.87, 0.84, 0.80, 0.77, 0.75, 0.72, 0.69, 0.66, 0.63]

    # Calculate the altitude correction factor (ACF) for the site
    alt_cnt = (weather.header.Altitude / 1000.0).to_i
    mj8.acf = MathTools.interp2(weather.header.Altitude, alt_cnt * 1000, (alt_cnt + 1) * 1000, acfs[alt_cnt], acfs[alt_cnt + 1])
    
    # Calculate the interior humidity in Grains and enthalpy in Btu/lb for cooling
    pwsat = OpenStudio::convert(0.430075, "psi", "kPa").get   # Calculated for 75degF indoor temperature
    rh_indoor_cooling = 0.55 # Manual J is vague on the indoor RH. 55% corresponds to BA goals
    hr_indoor_cooling = (0.62198 * rh_indoor_cooling * pwsat) / (UnitConversion.atm2kPa(weather.header.LocalPressure) - rh_indoor_cooling * pwsat)
    mj8.grains_indoor_cooling = UnitConversion.lbm_lbm2grains(hr_indoor_cooling)
    mj8.wetbulb_indoor_cooling = Psychrometrics.Twb_fT_R_P(mj8.cool_setpoint, rh_indoor_cooling, UnitConversion.atm2psi(weather.header.LocalPressure))        
    
    db_indoor_degC = OpenStudio::convert(mj8.cool_setpoint, "F", "C").get
    mj8.enthalpy_indoor_cooling = (1.006 * db_indoor_degC + hr_indoor_cooling * (2501 + 1.86 * db_indoor_degC)) * OpenStudio::convert(1.0, "kJ", "Btu").get * OpenStudio::convert(1.0, "lb", "kg").get
    
    # Calculate the interior humidity in Grains and enthalpy in Btu/lb for dehumidification
    mj8.RH_indoor_dehumid = 0.60
    hr_indoor_dehumid = (0.62198 * mj8.RH_indoor_dehumid * pwsat) / (UnitConversion.atm2kPa(weather.header.LocalPressure) - mj8.RH_indoor_dehumid * pwsat)
    mj8.grains_indoor_dehumid = UnitConversion.lbm_lbm2grains(hr_indoor_dehumid)
    mj8.wetbulb_indoor_dehumid = Psychrometrics.Twb_fT_R_P(mj8.cool_setpoint, mj8.RH_indoor_dehumid, UnitConversion.atm2psi(weather.header.LocalPressure))
        
    # Design Temperatures
    
    mj8.cool_design_temps = {}
    mj8.heat_design_temps = {}
    mj8.dehum_design_temps = {}
    
    # Initialize Manual J buffer space temperatures using current design temperatures
    model.getSpaces.each do |space|
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
                temps['cool'] = 75 # FIXME: (ua_max_cool_design_temp - ua_percent_ua_from_ceiling * (ua_max_cool_design_temp - ua_min_cool_design_temp))
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
                # garage_area_under_attic += roof.area * Math::cos(roof.tilt.deg2rad)  

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
                        # runner.registerInfo('Specified roofing material is not supported by BEopt Manual J calculations. Assuming dark asphalt shingles')
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
                        # runner.registerInfo('Specified roofing material is not supported by BEopt Manual J calculations. Assuming dark asphalt shingles')
                        # unfinished_attic.cool_design_temp_mj8 = 120
            
            # # Adjust base CLTD for cooling design temperature and daily range
            # unfinished_attic.cool_design_temp_mj8 += (cool_design_db - 95) + mj8.daily_range_temp_adjust[mj8.daily_range_num]
            
    return mj8
  end
  
  def processZoneLoads(runner, mj8, thermal_zone, weather, northAxis, nbeds, unit_ffa_for_people, modelYear, alwaysOnDiscreteSchedule, unit_shelter_class, building_num_stories)
    # FIXME: ensure coincidence of window loads and internal gains across zones in a unit
    zone_loads = ZoneValues.new
    zone_loads = processLoadWindows(runner, mj8, thermal_zone, zone_loads, weather, northAxis)
    zone_loads = processLoadDoors(runner, mj8, thermal_zone, zone_loads, weather)
    zone_loads = processLoadWalls(runner, mj8, thermal_zone, zone_loads, weather, northAxis)
    zone_loads = processLoadRoofs(runner, mj8, thermal_zone, zone_loads, weather)
    zone_loads = processLoadFloors(runner, mj8, thermal_zone, zone_loads, weather)
    zone_loads = processInfiltrationVentilation(runner, mj8, thermal_zone, zone_loads, weather, unit_shelter_class, building_num_stories)
    zone_loads = processInternalGains(runner, mj8, thermal_zone, zone_loads, weather, nbeds, unit_ffa_for_people, modelYear, alwaysOnDiscreteSchedule)
    return zone_loads
  end
  
  def processLoadWindows(runner, mj8, thermal_zone, zone_loads, weather, northAxis)
    '''
    Heating, Cooling, and Dehumidification Loads: Windows
    '''
    
    return nil if mj8.nil? or zone_loads.nil?
    
    # Average cooling load factors for windows WITHOUT internal shading for surface 
    # azimuths of 0,22.5,45, ... ,337.5,360
    # Additional values (compared to values in MJ8 Table 3D-3) have been determined by 
    # linear interpolation to avoid interpolating                    
    clf_avg_nois = [0.24, 0.295, 0.35, 0.365, 0.38, 0.39, 0.4, 0.44, 0.48, 0.44, 0.4, 0.39, 0.38, 0.365, 0.35, 0.295, 0.24]

    # Average cooling load factors for windows WITH internal shading for surface 
    # azimuths of 0,22.5,45, ... ,337.5,360
    # Additional values (compared to values in MJ8 Table 3D-3) have been determined 
    # by linear interpolation to avoid interpolating in BMI
    clf_avg_is = [0.18, 0.235, 0.29, 0.305, 0.32, 0.32, 0.32, 0.305, 0.29, 0.305, 0.32, 0.32, 0.32, 0.305, 0.29, 0.235, 0.18]            
    
    # Hourly cooling load factor (CLF) for windows WITHOUT an internal shade taken from 
    # ASHRAE HOF Ch.26 Table 36 (subset of data in MJ8 Table A11-5)
    # Surface Azimuth = 0 (South), 22.5, 45.0, ... ,337.5,360 and Hour = 8,9, ... ,19,20 
    clf_hr_nois = [[0.14, 0.22, 0.34, 0.48, 0.59, 0.65, 0.65, 0.59, 0.50, 0.43, 0.36, 0.28, 0.22],
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
    clf_hr_is = [[0.23, 0.38, 0.58, 0.75, 0.83, 0.80, 0.68, 0.50, 0.35, 0.27, 0.19, 0.11, 0.09],
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
    # Nil denotes directions not used in the shading calculation (Note: south direction is symmetrical around noon)
    slm_alp_hr = [15.5, 14.75, 14, 14.75, 15.5, nil, nil, nil, nil, nil, nil, nil, 8.5, 9.75, 10, 9.75, 8.5]
    
    # Mid summer declination angle used for shading calculations
    declination_angle = 12.1  # Mid August
    
    # Peak solar factor (PSF) (aka solar heat gain factor) taken from ASHRAE HOF 1989 Ch.26 Table 34 
    # (subset of data in MJ8 Table 3D-2)            
    # Surface Azimuth = 0 (South), 22.5, 45.0, ... ,337.5,360 and Latitude = 20,24,28, ... ,60,64
    psf = [[ 57,  72,  91, 111, 131, 149, 165, 180, 193, 203, 211, 217],
           [ 88, 103, 120, 136, 151, 165, 177, 188, 197, 206, 213, 217],
           [152, 162, 172, 181, 189, 196, 202, 208, 212, 215, 217, 217],
           [200, 204, 207, 210, 212, 214, 215, 216, 216, 216, 214, 211],
           [220, 220, 220, 219, 218, 216, 214, 211, 208, 203, 199, 193],
           [206, 203, 199, 195, 190, 185, 180, 174, 169, 165, 161, 157],
           [162, 156, 149, 141, 138, 135, 132, 128, 124, 119, 114, 109],
           [ 91,  87,  83,  79,  75,  71,  66,  61,  56,  56,  57,  58],
           [ 40,  38,  38,  37,  36,  35,  34,  33,  32,  30,  28,  27],
           [ 91,  87,  83,  79,  75,  71,  66,  61,  56,  56,  57,  58],
           [162, 156, 149, 141, 138, 135, 132, 128, 124, 119, 114, 109],
           [206, 203, 199, 195, 190, 185, 180, 174, 169, 165, 161, 157],
           [220, 220, 220, 219, 218, 216, 214, 211, 208, 203, 199, 193],
           [200, 204, 207, 210, 212, 214, 215, 216, 216, 216, 214, 211],
           [152, 162, 172, 181, 189, 196, 202, 208, 212, 215, 217, 217],
           [ 88, 103, 120, 136, 151, 165, 177, 188, 197, 206, 213, 217],
           [ 57,  72,  91, 111, 131, 149, 165, 180, 193, 203, 211, 217]]
                    
    # Determine the PSF's for the building latitude
    psf_lat = []
    latitude = weather.header.Latitude.to_f
    for cnt in 0..16
        if latitude < 20.0
            psf_lat << psf[cnt][0]
            if cnt == 0
                runner.registerWarning('Latitude of 20 was assumed for Manual J solar load calculations.')
            end
        elsif latitude > 64.0
            psf_lat << psf[cnt][11]
            if cnt == 0
                runner.registerWarning('Latitude of 64 was assumed for Manual J solar load calculations.')
            end
        else
            cnt_lat_s = ((latitude - 20.0) / 4.0).to_i
            cnt_lat_n = cnt_lat_s + 1
            lat_s = 20 + 4 * cnt_lat_s
            lat_n = lat_s + 4
            psf_lat << MathTools.interp2(latitude, lat_s, lat_n, psf[cnt][cnt_lat_s], psf[cnt][cnt_lat_n])
        end
    end
    
    alp_load = 0 # Average Load Procedure (ALP) Load
    afl_hr = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] # Initialize Hourly Aggregate Fenestration Load (AFL)
    
    zone_loads.Heat_Windows = 0
    zone_loads.Dehumid_Windows = 0
    
    Geometry.get_thermal_zone_above_grade_exterior_walls(thermal_zone).each do |wall|
        wall_true_azimuth = true_azimuth(wall, northAxis)
        cnt225 = (wall_true_azimuth / 22.5).round.to_i
        
        wall.subSurfaces.each do |window|
            next if not window.subSurfaceType.downcase.include?("window")
            
            # U-value
            u_window = get_surface_uvalue(runner, window, window.subSurfaceType)
            return nil if u_window.nil?
            zone_loads.Heat_Windows += u_window * OpenStudio::convert(window.grossArea,"m^2","ft^2").get * mj8.htd
            zone_loads.Dehumid_Windows += u_window * OpenStudio::convert(window.grossArea,"m^2","ft^2").get * mj8.dtd
            
            # SHGC & Internal Shading
            shgc_with_IntGains_shade_cool, shgc_with_IntGains_shade_heat = get_window_shgc(runner, window)
            
            windowHeight = Geometry.surface_height(window)
            has_IntGains_shade = true # FIXME
            windowHasOverhang = true # FIXME
            overhangDepth = 2 # FIXME
            overhangOffset = 0.5 # FIXME
            
            for hr in -1..12
            
                # If hr == -1: Calculate the Average Load Procedure (ALP) Load
                # Else: Calculate the hourly Aggregate Fenestration Load (AFL)
                
                if hr == -1
                    if has_IntGains_shade
                        # Average Cooling Load Factor for the given window direction
                        clf_d = clf_avg_is[cnt225]
                        #Average Cooling Load Factor for a window facing North (fully shaded)
                        clf_n = clf_avg_is[8]
                    else
                        # Average Cooling Load Factor for the given window direction
                        clf_d = clf_avg_nois[cnt225]
                        #Average Cooling Load Factor for a window facing North (fully shaded)
                        clf_n = clf_avg_nois[8]
                    end
                else
                    if has_IntGains_shade
                        # Average Cooling Load Factor for the given window Direction
                        clf_d = clf_hr_is[cnt225][hr]
                        # Average Cooling Load Factor for a window facing North (fully shaded)
                        clf_n = clf_hr_is[8][hr]
                    else
                        # Average Cooling Load Factor for the given window Direction
                        clf_d = clf_hr_nois[cnt225][hr]
                        # Average Cooling Load Factor for a window facing North (fully shaded)
                        clf_n = clf_hr_nois[8][hr]
                    end
                end
        
                # Hourly Heat Transfer Multiplier for the given window Direction
                htm_d = psf_lat[cnt225] * clf_d * shgc_with_IntGains_shade_cool / 0.87 + u_window * mj8.ctd
        
                # Hourly Heat Transfer Multiplier for a window facing North (fully shaded)
                htm_n = psf_lat[8] * clf_n * shgc_with_IntGains_shade_cool / 0.87 + u_window * mj8.ctd
                
                if wall_true_azimuth < 180
                    surf_azimuth = wall_true_azimuth
                else
                    surf_azimuth = wall_true_azimuth - 360
                end
                
                # TODO: Account for eaves, porches, etc.
                if windowHasOverhang
                    if (hr == -1 and surf_azimuth.abs < 90.1) or (hr > -1) # FIXME: This if/else statement is in one spot in sizing.py but not another
                        if hr == -1
                            actual_hr = slm_alp_hr[cnt225]
                        else
                            actual_hr = hr + 8 # start at hour 8
                        end
                        hour_angle = 0.25 * (actual_hr - 12) * 60 # ASHRAE HOF 1997 pg 29.19
                        altitude_angle = (Math::asin((Math::cos(weather.header.Latitude.deg2rad) * 
                                                      Math::cos(declination_angle.deg2rad) * 
                                                      Math::cos(hour_angle.deg2rad) + 
                                                      Math::sin(weather.header.Latitude.deg2rad) * 
                                                      Math::sin(declination_angle.deg2rad)))).rad2deg
                        temp_arg = [(Math::sin(altitude_angle.deg2rad) * 
                                     Math::sin(weather.header.Latitude.deg2rad) - 
                                     Math::sin(declination_angle.deg2rad)) / 
                                    (Math::cos(altitude_angle.deg2rad) * 
                                     Math::cos(weather.header.Latitude.deg2rad)), 1.0].min
                        temp_arg = [temp_arg, -1.0].max
                        solar_azimuth = Math::acos(temp_arg).rad2deg
                        if actual_hr < 12
                            solar_azimuth = -1.0 * solar_azimuth
                        end

                        sol_surf_azimuth = solar_azimuth - surf_azimuth
                        if sol_surf_azimuth.abs >= 90 and sol_surf_azimuth.abs <= 270
                            # Window is entirely in the shade if the solar surface azimuth is greater than 90 and less than 270
                            htm = htm_n
                        else
                            slm = Math::tan(altitude_angle.deg2rad) / Math::cos(sol_surf_azimuth.deg2rad)
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
                        # Window is north of East and West azimuths. Shading calculations do not apply.
                        htm = htm_d
                    end
                else
                    htm = htm_d
                end

                if hr == -1
                    alp_load += htm * OpenStudio::convert(window.grossArea,"m^2","ft^2").get
                else
                    afl_hr[hr] += htm * OpenStudio::convert(window.grossArea,"m^2","ft^2").get
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
    zone_loads.Cool_Windows = alp_load + eal
    
    return zone_loads
  end
  
  def processLoadDoors(runner, mj8, thermal_zone, zone_loads, weather)
    '''
    Heating, Cooling, and Dehumidification Loads: Doors
    '''
    
    return nil if mj8.nil? or zone_loads.nil?
    
    if mj8.daily_range_num == 0
        cltd_Door = mj8.ctd + 15
    elsif mj8.daily_range_num == 1
        cltd_Door = mj8.ctd + 11
    else
        cltd_Door = mj8.ctd + 6
    end

    zone_loads.Heat_Doors = 0
    zone_loads.Cool_Doors = 0
    zone_loads.Dehumid_Doors = 0

    Geometry.get_thermal_zone_above_grade_exterior_walls(thermal_zone).each do |wall|
        wall.subSurfaces.each do |door|
            next if not door.subSurfaceType.downcase.include?("door")
            door_uvalue = get_surface_uvalue(runner, door, door.subSurfaceType)
            return nil if door_uvalue.nil?
            zone_loads.Heat_Doors += door_uvalue * OpenStudio::convert(door.grossArea,"m^2","ft^2").get * mj8.htd
            zone_loads.Cool_Doors += door_uvalue * OpenStudio::convert(door.grossArea,"m^2","ft^2").get * cltd_Door
            zone_loads.Dehumid_Doors += door_uvalue * OpenStudio::convert(door.grossArea,"m^2","ft^2").get * mj8.dtd
        end
    end
    
    return zone_loads
  end
  
  def processLoadWalls(runner, mj8, thermal_zone, zone_loads, weather, northAxis)
    '''
    Heating, Cooling, and Dehumidification Loads: Walls
    '''
    
    return nil if mj8.nil? or zone_loads.nil?
    
    wall_type = 'Constants.WallTypeWoodStud' # FIXME
    finishDensity = 11.0 # FIXME
    finishAbsorptivity = 0.6 # FIXME
    wallSheathingContInsRvalue = 5.0 # FIXME
    wallSheathingContInsThickness = 1.0 # FIXME
    wallCavityInsRvalueInstalled = 13.0 # FIXME
    sipInsThickness = 5.0 # FIXME
    cmuFurringInsRvalue = 15.0 # FIXME
    
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
    
    # Base Cooling Load Temperature Differences (CLTD's) for dark colored sunlit and shaded walls 
    # with 95 degF outside temperature taken from MJ8 Figure A12-8 (intermediate wall groups were 
    # determined using linear interpolation). Shaded walls apply to north facing and partition walls only.
    cltd_base_sun = [38, 34.95, 31.9, 29.45, 27, 24.5, 22, 21.25, 20.5, 19.65, 18.8]
    cltd_base_shade = [25, 22.5, 20, 18.45, 16.9, 15.45, 14, 13.55, 13.1, 12.85, 12.6]
    
    cltd_Wall_Sun = cltd_base_sun[wallGroup - 1] * colorMultiplier
    cltd_Wall_Shade = cltd_base_shade[wallGroup - 1] * colorMultiplier

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

    zone_loads.Heat_Walls = 0
    zone_loads.Cool_Walls = 0
    zone_loads.Dehumid_Walls = 0
    
    # Above-Grade Exterior Walls
    Geometry.get_thermal_zone_above_grade_exterior_walls(thermal_zone).each do |wall|
        wall_uvalue = get_surface_uvalue(runner, wall, wall.surfaceType)
        return nil if wall_uvalue.nil?
        wall_true_azimuth = true_azimuth(wall, northAxis)
        if wall_true_azimuth >= 157.5 and wall_true_azimuth <= 202.5
            zone_loads.Cool_Walls += wall_uvalue * OpenStudio::convert(wall.netArea,"m^2","ft^2").get * cltd_Wall_Shade
        else
            zone_loads.Cool_Walls += wall_uvalue * OpenStudio::convert(wall.netArea,"m^2","ft^2").get * cltd_Wall_Sun
        end
        zone_loads.Heat_Walls += wall_uvalue * OpenStudio::convert(wall.netArea,"m^2","ft^2").get * mj8.htd
        zone_loads.Dehumid_Walls += wall_uvalue * OpenStudio::convert(wall.netArea,"m^2","ft^2").get * mj8.dtd
    end

    # Interzonal Walls
    Geometry.get_thermal_zone_interzonal_walls(thermal_zone).each do |wall|
        wall_uvalue = get_surface_uvalue(runner, wall, wall.surfaceType)
        return nil if wall_uvalue.nil?
        adjacent_space = wall.adjacentSurface.get.space.get
        zone_loads.Cool_Walls += wall_uvalue * OpenStudio::convert(wall.netArea,"m^2","ft^2").get * (mj8.cool_design_temps[adjacent_space] - mj8.cool_setpoint)
        zone_loads.Heat_Walls += wall_uvalue * OpenStudio::convert(wall.netArea,"m^2","ft^2").get * (mj8.heat_setpoint - mj8.heat_design_temps[adjacent_space])
        zone_loads.Dehumid_Walls += wall_uvalue * OpenStudio::convert(wall.netArea,"m^2","ft^2").get * (mj8.cool_setpoint - mj8.dehum_design_temps[adjacent_space])
    end
        
    # Foundation walls
    Geometry.get_thermal_zone_below_grade_exterior_walls(thermal_zone).each do |wall|
        # FIXME: Deviating substantially from sizing.py
        wall_uvalue = get_surface_uvalue(runner, wall, wall.surfaceType)
        return nil if wall_uvalue.nil?
        zone_loads.Heat_Walls += wall_uvalue * OpenStudio::convert(wall.netArea,"m^2","ft^2").get * mj8.htd
    end
            
    return zone_loads
  end
  
  def processLoadRoofs(runner, mj8, thermal_zone, zone_loads, weather)
    '''
    Heating, Cooling, and Dehumidification Loads: Ceilings
    '''
    
    return nil if mj8.nil? or zone_loads.nil?
    
    finishedRoofTotalR = 20.0 # FIXME
    fRRoofContInsThickness = 2.0 # FIXME
    roofMatColor = 'Constants.ColorDark' # FIXME
    roofMatDescription = 'Constants.MaterialTile' # FIXME
        
    cool_design_db = weather.design.CoolingDrybulb
    
    cltd_FinishedRoof = 0
    
    above_grade_exterior_roofs = Geometry.get_thermal_zone_above_grade_exterior_roofs(thermal_zone)

    if above_grade_exterior_roofs.size > 0
        
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

    zone_loads.Heat_Roofs = 0
    zone_loads.Cool_Roofs = 0
    zone_loads.Dehumid_Roofs = 0
    
    # Roofs
    above_grade_exterior_roofs.each do |roof|
        roof_uvalue = get_surface_uvalue(runner, roof, roof.surfaceType)
        return nil if roof_uvalue.nil?
        zone_loads.Cool_Roofs += roof_uvalue * OpenStudio::convert(roof.netArea,"m^2","ft^2").get * cltd_FinishedRoof
        zone_loads.Heat_Roofs += roof_uvalue * OpenStudio::convert(roof.netArea,"m^2","ft^2").get * mj8.htd
        zone_loads.Dehumid_Roofs += roof_uvalue * OpenStudio::convert(roof.netArea,"m^2","ft^2").get * mj8.dtd
    end
  
    return zone_loads
  end
  
  def processLoadFloors(runner, mj8, thermal_zone, zone_loads, weather)
    '''
    Heating, Cooling, and Dehumidification Loads: Floors
    '''
    
    return nil if mj8.nil? or zone_loads.nil?
    
    zone_loads.Heat_Floors = 0
    zone_loads.Cool_Floors = 0
    zone_loads.Dehumid_Floors = 0

    # Exterior Floors
    Geometry.get_thermal_zone_above_grade_exterior_floors(thermal_zone).each do |floor|
        floor_uvalue = get_surface_uvalue(runner, floor, floor.surfaceType)
        return nil if floor_uvalue.nil?
        zone_loads.Cool_Floors += floor_uvalue * OpenStudio::convert(floor.netArea,"m^2","ft^2").get * (mj8.ctd - 5 + mj8.daily_range_temp_adjust[mj8.daily_range_num])
        zone_loads.Heat_Floors += floor_uvalue * OpenStudio::convert(floor.netArea,"m^2","ft^2").get * mj8.htd
        zone_loads.Dehumid_Floors += floor_uvalue * OpenStudio::convert(floor.netArea,"m^2","ft^2").get * mj8.dtd
    end
    
    # Interzonal Floors
    Geometry.get_thermal_zone_interzonal_floors(thermal_zone).each do |floor|
        floor_uvalue = get_surface_uvalue(runner, floor, floor.surfaceType)
        return nil if floor_uvalue.nil?
        adjacent_space = floor.adjacentSurface.get.space.get
        zone_loads.Cool_Floors += floor_uvalue * OpenStudio::convert(floor.netArea,"m^2","ft^2").get * (mj8.cool_design_temps[adjacent_space] - mj8.cool_setpoint)
        fr = OpenStudio::convert(floor.filmResistance,"m^2*K/W","ft^2*h*R/Btu").get
        zone_loads.Heat_Floors += floor_uvalue * OpenStudio::convert(floor.netArea,"m^2","ft^2").get * (mj8.heat_setpoint - mj8.heat_design_temps[adjacent_space])
        zone_loads.Dehumid_Floors += floor_uvalue * OpenStudio::convert(floor.netArea,"m^2","ft^2").get * (mj8.cool_setpoint - mj8.dehum_design_temps[adjacent_space])
    end
     
    # Foundation Floors
    Geometry.get_thermal_zone_below_grade_exterior_floors(thermal_zone).each do |floor|
        # FIXME: Need to do
        # if Geometry.get_finished_basement_spaces(model.getSpaces).include?(floor.space.get)
            # # Finished basement floor combinations based on MJ 8th Ed. A12-7 and ASHRAE HoF 2013 pg 18.31 Eq 40
            # R_other = sim.mat.materials[Constants.MaterialConcrete4in].Rvalue + sim.film.floor_average
            # for floor in unit.floors.floor:
                # floor.surface_type.Uvalue_fbsmt_mj8 = 0
                # z_f = below_grade_height
                # w_b = min( max(floor.vertices.coord.x) - min(floor.vertices.coord.x), max(floor.vertices.coord.y) - min(floor.vertices.coord.y) )
                # U_avg_bf = (2*k_soil/(Constants.Pi*w_b)) * (log(w_b/2+z_f/2+(k_soil*R_other)/Constants.Pi) - log(z_f/2+(k_soil*R_other)/Constants.Pi))                     
                # floor.surface_type.Uvalue_fbsmt_mj8 = 0.85 * U_avg_bf 
                # zone_loads.Heat_Floors += floor.surface_type.Uvalue_fbsmt_mj8 * floor.area * mj8.htd
        # else # Slab
        #     floor_uvalue = get_surface_uvalue(runner, floor, floor.surfaceType)
        #     return nil if floor_uvalue.nil?
        #     zone_loads.Heat_Floors += floor_uvalue * OpenStudio::convert(floor.netArea,"m^2","ft^2").get * (mj8.heat_setpoint - weather.data.GroundMonthlyTemps[0])
        # end
    end

    return zone_loads
  end
  
  def processInfiltrationVentilation(runner, mj8, thermal_zone, zone_loads, weather, unit_shelter_class, building_num_stories)
    '''
    Heating, Cooling, and Dehumidification Loads: Infiltration & Ventilation
    '''
    
    return nil if mj8.nil? or zone_loads.nil?
    
    infil_type = 'ach50' # FIXME
    space_ela = 0.6876 # FIXME
    space_inf_flow = 50.0 # FIXME
    mechVentType = 'Constants.VentTypeExhaust' # FIXME
    whole_house_vent_rate = 64.04 # FIXME
    mechVentApparentSensibleEffectiveness = nil # FIXME
    mechVentLatentEffectiveness = nil # FIXME
    mechVentTotalEfficiency = nil # FIXME
    
    dehumDesignWindSpeed = [weather.design.CoolingWindspeed, weather.design.HeatingWindspeed].max
    ft2in = OpenStudio::convert(1.0, "ft", "in").get
    mph2m_s = OpenStudio::convert(1.0, "mph", "m/s").get
    
    # Stack Coefficient (Cs) for infiltration calculation taken from Table 5D
    # Wind Coefficient (Cw) for Shielding Classes 1-5 for infiltration calculation taken from Table 5D
    # Coefficients converted to regression equations to allow for more than 3 stories
    c_s = 0.015 * building_num_stories
    if unit_shelter_class == 1
        c_w = 0.0119 * building_num_stories ** 0.4
    elsif unit_shelter_class == 2
        c_w = 0.0092 * building_num_stories ** 0.4
    elsif unit_shelter_class == 3
        c_w = 0.0065 * building_num_stories ** 0.4
    elsif unit_shelter_class == 4
        c_w = 0.0039 * building_num_stories ** 0.4
    elsif unit_shelter_class == 5
        c_w = 0.0012 * building_num_stories ** 0.4
    else
        runner.registerError('Invalid shelter_class: {}'.format(unit_shelter_class))
        return nil
    end
    
    if infil_type == 'ach50'
        icfm_Cooling = space_ela * ft2in ** 2 * (c_s * mj8.ctd.abs + c_w * (weather.design.CoolingWindspeed / mph2m_s) ** 2) ** 0.5
        icfm_Heating = space_ela * ft2in ** 2 * (c_s * mj8.htd.abs + c_w * (weather.design.HeatingWindspeed / mph2m_s) ** 2) ** 0.5
        icfm_Dehumid = space_ela * ft2in ** 2 * (c_s * mj8.dtd.abs + c_w * (dehumDesignWindSpeed / mph2m_s) ** 2) ** 0.5
    elsif infil_type == 'ach'
        icfm_Cooling = space_inf_flow
        icfm_Heating = space_inf_flow
        icfm_Dehumid = space_inf_flow
    end

    q_unb, q_bal_Sens, q_bal_Lat, ventMultiplier = get_ventilation_rates(mechVentType, whole_house_vent_rate, mechVentApparentSensibleEffectiveness, mechVentLatentEffectiveness, mechVentTotalEfficiency)

    cfm_Heating = q_bal_Sens + (icfm_Heating ** 2 + ventMultiplier * (q_unb ** 2)).abs ** 0.5
    
    cfm_Cool_Load_Sens = q_bal_Sens + (icfm_Cooling ** 2 + ventMultiplier * (q_unb ** 2)).abs ** 0.5
    cfm_Cool_Load_Lat = q_bal_Lat + (icfm_Cooling ** 2 + ventMultiplier * (q_unb ** 2)).abs ** 0.5
    
    cfm_Dehumid_Load_Sens = q_bal_Sens + (icfm_Dehumid ** 2 + ventMultiplier * (q_unb ** 2)).abs ** 0.5
    cfm_Dehumid_Load_Lat = q_bal_Lat + (icfm_Dehumid ** 2 + ventMultiplier * (q_unb ** 2)).abs ** 0.5
    
    zone_loads.Heat_Infil = 1.1 * mj8.acf * cfm_Heating * mj8.htd
    
    zone_loads.Cool_Infil_Sens = 1.1 * mj8.acf * cfm_Cool_Load_Sens * mj8.ctd
    zone_loads.Cool_Infil_Lat = 0.68 * mj8.acf * cfm_Cool_Load_Lat * (mj8.cool_design_grains - mj8.grains_indoor_cooling)
    
    zone_loads.Dehumid_Infil_Sens = 1.1 * mj8.acf * cfm_Dehumid_Load_Sens * mj8.dtd
    zone_loads.Dehumid_Infil_Lat = 0.68 * mj8.acf * cfm_Dehumid_Load_Lat * (mj8.dehum_design_grains - mj8.grains_indoor_dehumid)
    
    if Geometry.zone_is_below_grade(thermal_zone)
        zone_loads.Heat_Infil =  0 # FIXME: Calculate using actual basement infiltration?
        zone_loads.Cool_Infil_Sens = 0
        zone_loads.Cool_Infil_Lat = 0
        zone_loads.Dehumid_Infil_Sens = 0
        zone_loads.Dehumid_Infil_Lat = 0
    end
    
    return zone_loads
  end
  
  def processInternalGains(runner, mj8, thermal_zone, zone_loads, weather, nbeds, unit_ffa_for_people, modelYear, alwaysOnDiscreteSchedule)
    '''
    Cooling and Dehumidification Loads: Internal Gains
    '''
    
    return nil if mj8.nil? or zone_loads.nil?
    
    if Geometry.zone_is_below_grade(thermal_zone)
        zone_loads.Cool_IntGains_Sens = 0
        zone_loads.Cool_IntGains_Lat = 0
        zone_loads.Dehumid_IntGains_Sens = 0
        zone_loads.Dehumid_IntGains_Lat = 0
        return zone_loads
    end
    
    int_Tot_Max = 0
    int_Lat_Max = 0
    
    # Calculate number of occupants based on Section 22-3
    n_occupants = nbeds + 1
    
    # Plug loads, appliances, showers/sinks/baths, occupants, ceiling fans
    gains = []
    thermal_zone.spaces.each do |space|
        gains.push(*space.electricEquipment)
        gains.push(*space.gasEquipment)
        gains.push(*space.otherEquipment)
        gains.push(*space.people)
    end
    
    july_dates = []
    for day in 1..31
        july_dates << OpenStudio::Date.new(OpenStudio::MonthOfYear.new('July'), day, modelYear)
    end

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
            if sched_base.name.to_s == alwaysOnDiscreteSchedule.name.to_s
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
            else
                runner.registerError("Unexpected type for object '#{gain.name.to_s}' in processInternalGains.")
                return nil
            end
        
        elsif gain.is_a?(OpenStudio::Model::People)
            # Get schedule
            if not gain.numberofPeopleSchedule.is_initialized
                runner.registerError("NumberOfPeopleSchedule not provided for object '#{gain.name.to_s}'. Skipping...")
                return nil
            end
            sched_base = gain.numberofPeopleSchedule.get
            if sched_base.to_ScheduleRuleset.is_initialized
                sched = sched_base.to_ScheduleRuleset.get
            elsif sched_base.to_ScheduleFixedInterval.is_initialized
                sched = sched_base.to_ScheduleFixedInterval.get
            else
                runner.registerError("Expected ScheduleRuleset or ScheduleFixedInterval for object '#{gain.name.to_s}'. Skipping...")
                return nil
            end
        else
            runner.registerError("Unexpected type for object '#{gain.name.to_s}' in processInternalGains.")
            return nil
        end
        
        next if sched.nil?

        # Get schedule hourly values
        if sched.is_a?(OpenStudio::Model::ScheduleRuleset)
            sched_values = sched.getDaySchedules(july_dates[0], july_dates[1])[0].values
        elsif sched.is_a?(OpenStudio::Model::ScheduleFixedInterval)
            # Smooth by using all days in July
            sched_values = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
            for day in 1..(july_dates.size - 1)
                sched_values_timestep = sched.timeSeries.values(OpenStudio::DateTime.new(july_dates[day-1]), OpenStudio::DateTime.new(july_dates[day]))
                # Aggregate into hourly values
                timesteps_per_hr = ((sched_values_timestep.size - 1) / 24).to_i
                for ts in 0..(sched_values_timestep.size - 2)
                    hr = (ts / timesteps_per_hr).floor
                    sched_values[hr] += sched_values_timestep[ts] / (july_dates.size - 1).to_f
                end
            end
        else
            runner.registerError("Unexpected type for object '#{sched.name.to_s}' in processInternalGains.")
            return nil
        end
        if sched_values.size != 24
            runner.registerWarning("Expected 24 DaySchedule values for object '#{gain.name.to_s}'. Skipping...")
            next
        end
        
        if gain.is_a?(OpenStudio::Model::People)
            for hr in 0..23
                int_Sens_Hr[hr] += sched_values[hr] * 230 * n_occupants * OpenStudio::convert(gain.space.get.floorArea,"m^2","ft^2").get / unit_ffa_for_people
                int_Lat_Hr[hr] += sched_values[hr] * 200 * n_occupants * OpenStudio::convert(gain.space.get.floorArea,"m^2","ft^2").get / unit_ffa_for_people
            end
        else
            next if design_level.nil? or sensible_frac.nil? or latent_frac.nil?
            for hr in 0..23
                int_Sens_Hr[hr] += sched_values[hr] * OpenStudio::convert(design_level,"W","Btu/hr").get * sensible_frac
                int_Lat_Hr[hr] += sched_values[hr] * OpenStudio::convert(design_level,"W","Btu/hr").get * latent_frac
            end
        end
    end
    
    # Store the sensible and latent loads associated with the hour of the maximum total load for cooling load calculations
    zone_loads.Cool_IntGains_Sens = int_Sens_Hr.max
    zone_loads.Cool_IntGains_Lat = int_Lat_Hr.max
    
    # Store the sensible and latent loads associated with the hour of the maximum latent load for dehumidification load calculations
    idx = int_Lat_Hr.each_with_index.max[1]
    zone_loads.Dehumid_IntGains_Sens = int_Sens_Hr[idx]
    zone_loads.Dehumid_IntGains_Lat = int_Lat_Hr[idx]
            
    return zone_loads
  end
    
  def processIntermediateTotalLoads(runner, mj8, zones_loads, weather, hvac)
    '''
    Intermediate Loads
    (total loads excluding ducts)
    '''
    
    return nil if mj8.nil? or zones_loads.nil?
    
    # TODO: Ideally this would require an iterative procedure. A possible enhancement for BEopt2.
    
    unit_init = UnitInitialValues.new
    unit_init.Heat_Load = 0
    unit_init.Cool_Load_Sens = 0
    unit_init.Cool_Load_Lat = 0
    unit_init.Dehumid_Load_Sens = 0
    unit_init.Dehumid_Load_Lat = 0
    zones_loads.keys.each do |thermal_zone|
        zone_loads = zones_loads[thermal_zone]
        
        # FIXME: Ask Jon about where max(0,foo) is used below
        
        # Heating
        unit_init.Heat_Load += [zone_loads.Heat_Windows + zone_loads.Heat_Doors +
                                zone_loads.Heat_Walls + zone_loads.Heat_Floors + 
                                zone_loads.Heat_Roofs, 0].max + zone_loads.Heat_Infil

        # Cooling
        unit_init.Cool_Load_Sens += zone_loads.Cool_Windows + zone_loads.Cool_Doors +
                                    zone_loads.Cool_Walls + zone_loads.Cool_Floors +
                                    zone_loads.Cool_Roofs + zone_loads.Cool_Infil_Sens +
                                    zone_loads.Cool_IntGains_Sens
        unit_init.Cool_Load_Lat += [zone_loads.Cool_Infil_Lat + zone_loads.Cool_IntGains_Lat, 0].max
        
        # Dehumidification
        unit_init.Dehumid_Load_Sens += zone_loads.Dehumid_Windows + zone_loads.Dehumid_Doors + 
                                       zone_loads.Dehumid_Walls + zone_loads.Dehumid_Floors +
                                       zone_loads.Dehumid_Roofs + zone_loads.Dehumid_Infil_Sens + 
                                       zone_loads.Dehumid_IntGains_Sens
        unit_init.Dehumid_Load_Lat += zone_loads.Dehumid_Infil_Lat + zone_loads.Dehumid_IntGains_Lat
    end
    
    unit_init.Cool_Load_Tot = unit_init.Cool_Load_Sens + unit_init.Cool_Load_Lat
    shr = [unit_init.Cool_Load_Sens / unit_init.Cool_Load_Tot, 1.0].min
    
    # Determine the Leaving Air Temperature (LAT) based on Manual S Table 1-4
    if shr < 0.80
        unit_init.LAT = 54
    elsif shr < 0.85
        # MJ8 says to use 56 degF in this SHR range. Linear interpolation provides a more 
        # continuous supply air flow rate across building efficiency levels.
        unit_init.LAT = ((58-54)/(0.85-0.80))*(shr - 0.8) + 54
    else
        unit_init.LAT = 58
    end
    
    if hvac.HtgSupplyAirTemp.nil?
        hvac.HtgSupplyAirTemp = 105
    end
    
    unit_init.Cool_Airflow = unit_init.Cool_Load_Sens / (1.1 * mj8.acf * (mj8.cool_setpoint - unit_init.LAT))
    unit_init.Heat_Airflow = calc_heat_cfm(unit_init.Heat_Load, mj8.acf, mj8.heat_setpoint, hvac.HtgSupplyAirTemp)
    
    return unit_init
  end
  
  def processUnitLoadsAndEquipment(runner, mj8, unit_init, weather, hvac, ducts, minCoolingCapacity, shr_biquadratic_coefficients, isExistingHome, hpSizeForMaxLoad, spaceConditionedMult)
    unit_final = UnitFinalValues.new
    unit_final = processDuctRegainFactors(runner, unit_final, ducts)
    unit_final = processDuctLoads_Heating(runner, mj8, unit_final, weather, hvac, unit_init.Heat_Load, ducts)
    unit_final = processDuctLoads_Cool_Dehum(runner, mj8, unit_init, unit_final, weather, hvac, ducts)
    unit_final = processCoolingEquipmentAdjustments(runner, mj8, unit_init, unit_final, weather, hvac, minCoolingCapacity, shr_biquadratic_coefficients)
    unit_final = processFixedEquipment(runner, unit_final, hvac, spaceConditionedMult)
    unit_final = processFinalize(runner, mj8, unit_final, weather, hvac, minCoolingCapacity, isExistingHome, hpSizeForMaxLoad, spaceConditionedMult)
    unit_final = processSlaveZoneFlowRatios(runner, unit_final)
    unit_final = processEfficientCapacityDerate(runner, hvac, unit_final)
    unit_final = processDehumidifierSizing(runner, mj8, unit_final, weather, unit_init.Dehumid_Load_Lat, hvac, minCoolingCapacity, shr_biquadratic_coefficients)
    return unit_final
  end
  
  def processDuctRegainFactors(runner, unit_final, ducts)
    return nil if unit_final.nil?
  
    basement_ceiling_Rvalue = 0 # FIXME
    basement_wall_Rvalue = 10 # FIXME
    basement_ach = 0.1 # FIXME
    crawlACH = 2.0 # FIXME
    crawl_ceiling_Rvalue = 0 # FIXME
    crawl_wall_Rvalue = 10 # FIXME
        
    unit_final.dse_Fregain = nil
    
    # Distribution system efficiency (DSE) calculations based on ASHRAE Standard 152
    if (ducts.Has and ducts.NotInLiving) or not ducts.SystemEfficiency.nil?
        # dse_Fregain values comes from MJ8 pg 204 and Walker (1998) "Technical background for default 
        # values used for forced air systems in proposed ASHRAE Std. 152"
        if ['Constants.SpaceUnfinBasement', 'Constants.SpaceFinBasement'].include?(ducts.Location)
            if basement_ceiling_Rvalue == 0
                if basement_wall_Rvalue == 0
                    if basement_ach == 0
                        unit_final.dse_Fregain = 0.55     # Uninsulated ceiling, uninsulated walls, no infiltration                            
                    else
                        unit_final.dse_Fregain = 0.51     # Uninsulated ceiling, uninsulated walls, with infiltration
                    end
                else
                    if basement_ach == 0
                        unit_final.dse_Fregain = 0.78    # Uninsulated ceiling, insulated walls, no infiltration
                    else
                        unit_final.dse_Fregain = 0.74    # Uninsulated ceiling, insulated walls, with infiltration                        
                    end
                end
            else
                if basement_wall_Rvalue > 0
                    if basement_ach == 0
                        unit_final.dse_Fregain = 0.32     # Insulated ceiling, insulated walls, no infiltration
                    else
                        unit_final.dse_Fregain = 0.27     # Insulated ceiling, insulated walls, with infiltration                            
                    end
                else
                    unit_final.dse_Fregain = 0.06    # Insulated ceiling and uninsulated walls
                end
            end
        elsif ['Constants.SpaceCrawl', 'Constants.SpacePierbeam'].include?(ducts.Location)
            if crawlACH > 0
                if crawl_ceiling_Rvalue > 0
                    unit_final.dse_Fregain = 0.12    # Insulated ceiling and uninsulated walls
                else
                    unit_final.dse_Fregain = 0.50    # Uninsulated ceiling and uninsulated walls
                end
            else
                if crawl_ceiling_Rvalue == 0 and crawl_wall_Rvalue == 0
                    unit_final.dse_Fregain = 0.60    # Uninsulated ceiling and uninsulated walls
                elsif crawl_ceiling_Rvalue > 0 and crawl_wall_Rvalue == 0
                    unit_final.dse_Fregain = 0.16    # Insulated ceiling and uninsulated walls
                elsif crawl_ceiling_Rvalue == 0 and crawl_wall_Rvalue > 0
                    unit_final.dse_Fregain = 0.76    # Uninsulated ceiling and insulated walls (not explicitly included in A152)
                else
                    unit_final.dse_Fregain = 0.30    # Insulated ceiling and insulated walls (option currently not included in BEopt)
                end
            end
        elsif ducts.Location == 'Constants.SpaceUnfinAttic'
            unit_final.dse_Fregain = 0.10          # This would likely be higher for unvented attics with roof insulation
        elsif ducts.Location == 'Constants.SpaceGarage'
            unit_final.dse_Fregain = 0.05
        elsif ['Constants.SpaceLiving', 'Constants.SpaceFinAttic'].include?(ducts.Location)
            unit_final.dse_Fregain = 1.0
        elsif not ducts.SystemEfficiency.nil?
            #Regain is already incorporated into the DSE
            unit_final.dse_Fregain = 0.0
        else
            runner.registerError("Invalid duct location: #{ducts.Location.to_s}")        
            return nil
        end
    end
    
    return unit_final
  end
  
  def processDuctLoads_Heating(runner, mj8, unit_final, weather, hvac, heatingLoad, ducts)
    return nil if mj8.nil? or unit_final.nil?
    
    # Distribution system efficiency (DSE) calculations based on ASHRAE Standard 152
    if ducts.Has and ducts.NotInLiving and hvac.HasForcedAir
        if Geometry.space_is_finished(ducts.LocationSpace)
            # Ducts in finished spaces shouldn't affect the total heating capacity
            unit_final.Heat_Load = heatingLoad
            unit_final.Heat_Load_Ducts = 0
        else
            dse_Tamb_heating = mj8.heat_design_temps[ducts.LocationSpace]
            unit_final.Heat_Load_Ducts = calc_heat_duct_load(ducts, mj8.acf, mj8.heat_setpoint, unit_final.dse_Fregain, heatingLoad, hvac.HtgSupplyAirTemp, dse_Tamb_heating)
            unit_final.Heat_Load = heatingLoad + unit_final.Heat_Load_Ducts
        end
    else
        unit_final.Heat_Load = heatingLoad
        unit_final.Heat_Load_Ducts = 0
    end
    
    return unit_final
  end
                                     
  def processDuctLoads_Cool_Dehum(runner, mj8, unit_init, unit_final, weather, hvac, ducts)
    '''
    Duct Loads
    '''
    
    return nil if mj8.nil? or unit_init.nil? or unit_final.nil?
    
    # Distribution system efficiency (DSE) calculations based on ASHRAE Standard 152
    if ducts.Has and ducts.NotInLiving and hvac.HasForcedAir and unit_init.Cool_Load_Sens > 0
        
        dse_Tamb_cooling = mj8.cool_design_temps[ducts.LocationSpace]
        dse_Tamb_dehumid = mj8.dehum_design_temps[ducts.LocationSpace]
        
        # Calculate the air enthalpy in the return duct location for DSE calculations
        dse_h_Return_Cooling = (1.006 * OpenStudio::convert(dse_Tamb_cooling, "F", "C").get + weather.design.CoolingHumidityRatio * (2501 + 1.86 * OpenStudio::convert(dse_Tamb_cooling, "F", "C").get)) * OpenStudio::convert(1, "kJ", "Btu").get * OpenStudio::convert(1, "lb", "kg").get
        
        # Supply and return duct surface areas located outside conditioned space
        dse_As = ducts.SupplySurfaceArea * ducts.LocationFrac
        dse_Ar = ducts.ReturnSurfaceArea
    
        iterate_Tattic = false
        if ducts.Location == 'Constants.SpaceUnfinAttic'
            iterate_Tattic = true
            
            # FIXME
            # if (space_int.spacetype == Constants.SpaceUnfinAttic and
                  # space_ext.spacetype == Constants.SpaceOutside):
                # # Need to sum the gable UA for attic temperature iteration
                # mj8.gable_ua += (wall.surface_type.Uvalue * wall.net_area) 
                    
            ## Calculate constant variables used in iteration:
            ## Multiply by fraction of attic apportioned to this unit (unit.unfin_attic_floor_area_frac).
            #uA_atticfloor = (sim.getSurfaceType(Constants.SurfaceTypeFinInsUnfinUAFloor).Uvalue *
            #                     unit.unfin_attic_floor_area)
            #uA_roof = ((sim.getSurfaceType(Constants.SurfaceTypeUnfinInsExtRoof).Uvalue *
            #                geometry.roofs.ua_roof_area * unit.unfin_attic_floor_area_frac) + 
            #                mj8.gable_ua * unit.unfin_attic_floor_area_frac)
            #    mdotCp_atticvent = (sim._getSpace(Constants.SpaceUnfinAttic).inf_flow * # cfm
            #                        sim.outside_air_density *
            #                        sim.mat.air.inside_air_sh *
            #                        units.hr2min(1) *
            #                        unit.unfin_attic_floor_area_frac)
            
            # Get average roofing material absorptance
            sumRoofAbs = 0.0
            numSurf = 0.0
            ducts.LocationSpace.surfaces.each do |surface|
                next if surface.surfaceType.downcase != "roofceiling"
                sumRoofAbs += surface.construction.get.to_LayeredConstruction.get.getLayer(0).to_OpaqueMaterial.get.solarAbsorptance
                numSurf += 1.0
            end
            roofAbsorptance = sumRoofAbs / numSurf
            
            roofPitch = Geometry.calculate_avg_roof_pitch([ducts.LocationSpace])
            
            t_solair = calculate_t_solair(weather, roofAbsorptance, roofPitch) # Sol air temperature on outside of roof surface # 1)
             
            # Calculate starting attic temp (ignoring duct losses)
            unit_final.Cool_Load_Ducts_Sens = 0
            t_attic_iter = calculate_t_attic_iter(uA_roof, mdotCp_atticvent, t_solair, uA_atticfloor, mj8.cool_setpoint, unit_final.Cool_Load_Ducts_Sens)
            dse_Tamb_cooling = t_attic_iter
        end
        
        # Initialize for the iteration
        delta = 1
        coolingLoad_Tot_Prev = unit_init.Cool_Load_Tot
        coolingLoad_Tot_Next = unit_init.Cool_Load_Tot
        unit_final.Cool_Load_Tot  = unit_init.Cool_Load_Tot
        unit_final.Cool_Load_Sens = unit_init.Cool_Load_Sens
        
        unit_final.Cool_Load_Lat, unit_final.Cool_Load_Sens = calculate_sensible_latent_split(mj8.cool_design_grains, mj8.grains_indoor_cooling, mj8.acf, ducts.ReturnLoss, coolingLoad_Tot_Next, unit_init.Cool_Load_Lat, unit_init.Cool_Airflow)
        
        for _iter in 1..50
            break if delta.abs <= 0.001

            coolingLoad_Tot_Prev = coolingLoad_Tot_Next
            
            unit_final.Cool_Load_Lat, unit_final.Cool_Load_Sens = calculate_sensible_latent_split(mj8.cool_design_grains, mj8.grains_indoor_cooling, mj8.acf, ducts.ReturnLoss, coolingLoad_Tot_Next, unit_init.Cool_Load_Lat, unit_init.Cool_Airflow)
            unit_final.Cool_Load_Tot = unit_final.Cool_Load_Lat + unit_final.Cool_Load_Sens
            
            # Calculate the new cooling air flow rate
            unit_init.Cool_Airflow = unit_final.Cool_Load_Sens / (1.1 * mj8.acf * (mj8.cool_setpoint - unit_init.LAT))

            unit_final.Cool_Load_Ducts_Sens = unit_final.Cool_Load_Sens - unit_init.Cool_Load_Sens
            unit_final.Cool_Load_Ducts_Tot = coolingLoad_Tot_Next - unit_init.Cool_Load_Tot
            unit_final.Cool_Load_Ducts_Lat = unit_final.Cool_Load_Ducts_Tot - unit_final.Cool_Load_Ducts_Sens

            dse_DEcorr_cooling, dse_dTe_cooling, unit_final.Cool_Load_Ducts_Sens = calc_dse_cooling(ducts, mj8.acf, mj8.enthalpy_indoor_cooling, unit_init.LAT, unit_init.Cool_Airflow, unit_final.Cool_Load_Sens, dse_Tamb_cooling, dse_As, dse_Ar, mj8.cool_setpoint, unit_final.dse_Fregain, unit_final.Cool_Load_Tot, dse_h_Return_Cooling)
            dse_precorrect = 1 - (unit_final.Cool_Load_Ducts_Sens / unit_final.Cool_Load_Sens)
        
            if iterate_Tattic # Iterate attic temperature based on duct losses
                delta_attic = 1
                
                for _iter_attic in 1..20
                    break if delta_attic.abs <= 0.001
                    
                    t_attic_old = t_attic_iter
                    t_attic_iter = calculate_t_attic_iter(uA_roof, mdotCp_atticvent, t_solair, uA_atticfloor, mj8.cool_setpoint, unit_final.Cool_Load_Ducts_Sens)
                    
                    # FIXME
                    #sim._getSpace(Constants.SpaceUnfinAttic).cool_design_temp_mj8 = t_attic_iter
                    
                    # Calculate the change since the last iteration
                    delta_attic = (t_attic_iter - t_attic_old) / t_attic_old                  
                    
                    # Calculate enthalpy in attic using new Tattic
                    dse_h_Return_Cooling = (1.006 * OpenStudio::convert(t_attic_iter,"F","C").get + weather.design.CoolingHumidityRatio * (2501 + 1.86 * OpenStudio::convert(t_attic_iter,"F","C").get)) * OpenStudio::convert(1,"kJ","Btu").get * OpenStudio::convert(1,"lb","kg").get
                    
                    # Calculate duct efficiency using new Tattic:
                    dse_DEcorr_cooling, dse_dTe_cooling, unit_final.Cool_Load_Ducts_Sens = calc_dse_cooling(ducts, mj8.acf, mj8.enthalpy_indoor_cooling, unit_init.LAT, unit_init.Cool_Airflow, unit_final.Cool_Load_Sens, dse_Tamb_cooling, dse_As, dse_Ar, mj8.cool_setpoint, unit_final.dse_Fregain, unit_final.Cool_Load_Tot, dse_h_Return_Cooling)
                    
                    dse_precorrect = 1 - (unit_final.Cool_Load_Ducts_Sens / unit_final.Cool_Load_Sens)
                end
                
                dse_Tamb_cooling = t_attic_iter
                mj8 = processLoadFloors(runner, mj8, thermal_zone, zone_loads, weather)
                mj8 = processIntermediateTotalLoads(runner, mj8, FIXME, weather, hvac.HtgSupplyAirTemp, hvac)
                
                # Calculate the increase in total cooling load due to ducts (conservatively to prevent overshoot)
                coolingLoad_Tot_Next = unit_init.Cool_Load_Tot + coolingLoad_Tot_Prev * (1 - dse_precorrect)
                
                # Calculate unmet zone load:
                delta = unit_init.Cool_Load_Tot - (unit_final.Cool_Load_Tot*dse_precorrect)
            else
                coolingLoad_Tot_Next = unit_init.Cool_Load_Tot / dse_DEcorr_cooling    
                        
                # Calculate the change since the last iteration
                delta = (coolingLoad_Tot_Next - coolingLoad_Tot_Prev) / coolingLoad_Tot_Prev
            end
        end # _iter
        
        # Calculate the air flow rate required for design conditions
        unit_final.Cool_Airflow = unit_final.Cool_Load_Sens / (1.1 * mj8.acf * (mj8.cool_setpoint - unit_init.LAT))

        # Dehumidification duct loads
        
        dse_Qs_Dehumid = ducts.SupplyLoss * unit_final.Cool_Airflow
        dse_Qr_Dehumid = ducts.ReturnLoss * unit_final.Cool_Airflow
        
        # Supply and return conduction functions, Bs and Br
        if ducts.NotInLiving
            dse_Bs_dehumid = Math.exp((-1.0 * dse_As) / (60 * unit_final.Cool_Airflow * Gas.Air.rho * Gas.Air.cp * ducts.SupplyRvalue))
            dse_Br_dehumid = Math.exp((-1.0 * dse_Ar) / (60 * unit_final.Cool_Airflow * Gas.Air.rho * Gas.Air.cp * ducts.ReturnRvalue))
        else
            dse_Bs_dehumid = 1
            dse_Br_dehumid = 1
        end
            
        dse_a_s_dehumid = (unit_final.Cool_Airflow - dse_Qs_Dehumid) / unit_final.Cool_Airflow
        dse_a_r_dehumid = (unit_final.Cool_Airflow - dse_Qr_Dehumid) / unit_final.Cool_Airflow
        
        dse_dTe_dehumid = dse_dTe_cooling
        dse_dT_dehumid = mj8.cool_setpoint - dse_Tamb_dehumid
        
        # Calculate the delivery effectiveness (Equation 6-23)
        dse_DE_dehumid = dse_a_s_dehumid * dse_Bs_dehumid - dse_a_s_dehumid * dse_Bs_dehumid * \
                         (1 - dse_a_r_dehumid * dse_Br_dehumid) * (dse_dT_dehumid / dse_dTe_dehumid) - \
                         dse_a_s_dehumid * (1 - dse_Bs_dehumid) * (dse_dT_dehumid / dse_dTe_dehumid)
                         
        # Calculate the delivery effectiveness corrector for regain (Equation 6-40)
        dse_DEcorr_dehumid = dse_DE_dehumid + unit_final.dse_Fregain * (1 - dse_DE_dehumid) + dse_Br_dehumid * \
                             (dse_a_r_dehumid * unit_final.dse_Fregain - unit_final.dse_Fregain) * (dse_dT_dehumid / dse_dTe_dehumid)

        # Limit the DE to a reasonable value to prevent negative values and huge equipment
        dse_DEcorr_dehumid = [dse_DEcorr_dehumid, 0.25].max
        if not ducts.SystemEfficiency.nil?
            dse_DEcorr_dehumid = ducts.SystemEfficiency
        end
        
        # Calculate the increase in sensible dehumidification load due to ducts
        unit_final.Dehumid_Load_Sens = unit_init.Dehumid_Load_Sens / dse_DEcorr_dehumid

        # Calculate the latent duct leakage load (Manual J accounts only for return duct leakage)
        unit_final.Dehumid_Load_Ducts_Lat = 0.68 * mj8.acf * dse_Qr_Dehumid * (mj8.dehum_design_grains - mj8.grains_indoor_dehumid)
                                          
    else
        unit_final.Cool_Load_Lat = unit_init.Cool_Load_Lat
        unit_final.Cool_Load_Sens = unit_init.Cool_Load_Sens
        unit_final.Cool_Load_Tot = unit_final.Cool_Load_Sens + unit_final.Cool_Load_Lat
        
        unit_final.Cool_Load_Ducts_Sens = 0
        unit_final.Cool_Load_Ducts_Lat = 0
        unit_final.Cool_Load_Ducts_Tot = 0
            
        unit_final.Dehumid_Load_Sens = unit_init.Dehumid_Load_Sens
        unit_final.Dehumid_Load_Ducts_Lat = 0

        # Calculate the air flow rate required for design conditions
        unit_final.Cool_Airflow = unit_final.Cool_Load_Sens / (1.1 * mj8.acf * (mj8.cool_setpoint - unit_init.LAT))
    end
    
    return unit_final
  end
  
  def processCoolingEquipmentAdjustments(runner, mj8, unit_init, unit_final, weather, hvac, minCoolingCapacity, shr_biquadratic_coefficients)
    '''
    Equipment Adjustments
    '''
    
    return nil if mj8.nil? or unit_final.nil?
    
    underSizeLimit = 0.9
    
    if hvac.HasCooling
        
        if unit_final.Cool_Load_Tot < 0
            unit_final.Cool_Capacity = minCoolingCapacity
            unit_final.Cool_Capacity_Sens = 0.78 * minCoolingCapacity
            unit_final.Cool_Airflow = 400.0 * OpenStudio::convert(minCoolingCapacity,"Btu/h","ton").get
            return unit_final
        end
        
        cool_design_db = weather.design.CoolingDrybulb
        
        # Adjust the total cooling capacity to the rated conditions using performance curves
        if not hvac.HasGroundSourceHeatPump
            enteringTemp = cool_design_db
        else
            enteringTemp = 10 #FIXME: unit.supply.HXCHWDesign
        end
        
        if hvac.HasCentralAirConditioner or hvac.HasAirSourceHeatPump

            if hvac.NumSpeedsCooling > 1
                sizingSpeed = hvac.NumSpeedsCooling # Default
                sizingSpeed_Test = 10    # Initialize
                for speed in 0..(hvac.NumSpeedsCooling - 1)
                    # Select curves for sizing using the speed with the capacity ratio closest to 1
                    temp = (hvac.CapacityRatioCooling[speed] - 1).abs
                    if temp <= sizingSpeed_Test
                        sizingSpeed = speed
                        sizingSpeed_Test = temp
                    end
                end
                coefficients = hvac.COOL_CAP_FT_SPEC_coefficients[sizingSpeed]
            else
                coefficients = hvac.COOL_CAP_FT_SPEC_coefficients[0]
            end
            
            unit_final.TotalCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_cooling, enteringTemp, coefficients)
            coolCap_Rated = unit_final.Cool_Load_Tot / unit_final.TotalCap_CurveValue
            if hvac.NumSpeedsCooling > 1
                sHR_Rated_Equip = hvac.SHRRated[sizingSpeed]
            else
                sHR_Rated_Equip = hvac.SHRRated[0]
            end
                            
            sensCap_Rated = coolCap_Rated * sHR_Rated_Equip
        
            sensibleCap_CurveValue = process_curve_fit(unit_final.Cool_Airflow, unit_final.Cool_Load_Tot, enteringTemp, shr_biquadratic_coefficients)
            sensCap_Design = sensCap_Rated * sensibleCap_CurveValue
            latCap_Design = [unit_final.Cool_Load_Tot - sensCap_Design, 1].max
            
            a_sens = shr_biquadratic_coefficients[0]
            b_sens = shr_biquadratic_coefficients[1]
            c_sens = shr_biquadratic_coefficients[3]
            d_sens = shr_biquadratic_coefficients[5]
        
            # Adjust Sizing
            if latCap_Design < unit_final.Cool_Load_Lat
                # Size by MJ8 Latent load, return to rated conditions
                
                # Solve for the new sensible and total capacity at design conditions:
                # CoolingLoad_Lat = cool_Capacity_Design - cool_Load_SensCap_Design
                # solve the following for cool_Capacity_Design: SensCap_Design = SHRRated * cool_Capacity_Design / TotalCap_CurveValue * function(CFM/cool_Capacity_Design, ODB)
                # substituting in CFM = cool_Load_SensCap_Design / (1.1 * ACF * (cool_setpoint - LAT))
                
                cool_Load_SensCap_Design = unit_final.Cool_Load_Lat / ((unit_final.TotalCap_CurveValue / sHR_Rated_Equip - \
                                          (OpenStudio::convert(b_sens,"ton","Btu/h").get + OpenStudio::convert(d_sens,"ton","Btu/h").get * enteringTemp) / \
                                          (1.1 * mj8.acf * (mj8.cool_setpoint - unit_init.LAT))) / \
                                          (a_sens + c_sens * enteringTemp) - 1)
                
                cool_Capacity_Design = cool_Load_SensCap_Design + unit_final.Cool_Load_Lat
                
                # The SHR of the equipment at the design condition
                sHR_design = cool_Load_SensCap_Design / cool_Capacity_Design
                
                # If the adjusted equipment size is negative (occurs at altitude), oversize by 15% (the adjustment
                # almost always hits the oversize limit in this case, making this a safe assumption)
                if cool_Capacity_Design < 0 or cool_Load_SensCap_Design < 0
                    cool_Capacity_Design = hvac.OverSizeLimit * unit_final.Cool_Load_Tot
                end
                
                # Limit total capacity to oversize limit
                cool_Capacity_Design = [cool_Capacity_Design, hvac.OverSizeLimit * unit_final.Cool_Load_Tot].min
                
                # Determine the final sensible capacity at design using the SHR
                cool_Load_SensCap_Design = SHR_design * cool_Capacity_Design
                
                # Calculate the final air flow rate using final sensible capacity at design
                unit_final.Cool_Airflow = cool_Load_SensCap_Design / (1.1 * mj8.acf * \
                                       (mj8.cool_setpoint - unit_init.LAT))
                
                # Determine rated capacities
                unit_final.Cool_Capacity = cool_Capacity_Design / unit_final.TotalCap_CurveValue
                unit_final.Cool_Capacity_Sens = unit_final.Cool_Capacity * sHR_Rated_Equip
                            
            elsif  sensCap_Design < underSizeLimit * unit_final.Cool_Load_Sens
                # Size by MJ8 Sensible load, return to rated conditions, find Sens with SHRRated. Limit total 
                # capacity to oversizing limit
                
                sensCap_Design = underSizeLimit * unit_final.Cool_Load_Sens
                
                # Solve for the new total system capacity at design conditions:
                # SensCap_Design   = SensCap_Rated * SensibleCap_CurveValue
                #                  = SHRRated * cool_Capacity_Design / TotalCap_CurveValue * SensibleCap_CurveValue
                #                  = SHRRated * cool_Capacity_Design / TotalCap_CurveValue * function(CFM/cool_Capacity_Design, ODB)
                
                cool_Capacity_Design = (sensCap_Design / (sHR_Rated_Equip / unit_final.TotalCap_CurveValue) - \
                                                   (b_sens * OpenStudio::convert(unit_final.Cool_Airflow,"ton","Btu/h").get + \
                                                   d_sens * OpenStudio::convert(unit_final.Cool_Airflow,"ton","Btu/h").get * enteringTemp)) / \
                                                   (a_sens + c_sens * enteringTemp)

                # Limit total capacity to oversize limit
                cool_Capacity_Design = [cool_Capacity_Design, hvac.OverSizeLimit * unit_final.Cool_Load_Tot].min
                
                unit_final.Cool_Capacity = cool_Capacity_Design / unit_final.TotalCap_CurveValue
                unit_final.Cool_Capacity_Sens = unit_final.Cool_Capacity * sHR_Rated_Equip
                
                # Recalculate the air flow rate in case the oversizing limit has been used
                cool_Load_SensCap_Design = unit_final.Cool_Capacity_Sens * sensibleCap_CurveValue
                unit_final.Cool_Airflow = cool_Load_SensCap_Design / (1.1 * mj8.acf * (mj8.cool_setpoint - unit_init.LAT))

            else
                unit_final.Cool_Capacity = unit_final.Cool_Load_Tot / unit_final.TotalCap_CurveValue
                unit_final.Cool_Capacity_Sens = unit_final.Cool_Capacity * sHR_Rated_Equip
                
                cool_Load_SensCap_Design = unit_final.Cool_Capacity_Sens * sensibleCap_CurveValue
                unit_final.Cool_Airflow = cool_Load_SensCap_Design / (1.1 * mj8.acf * (mj8.cool_setpoint - unit_init.LAT))
                
            end
                
            # Ensure the air flow rate is in between 200 and 500 cfm/ton. 
            # Reset the air flow rate (with a safety margin), if required.
            if unit_final.Cool_Airflow / OpenStudio::convert(unit_final.Cool_Capacity,"Btu/h","ton").get > 500
                unit_final.Cool_Airflow = 499 * OpenStudio::convert(unit_final.Cool_Capacity,"Btu/h","ton").get      # CFM
            elsif unit_final.Cool_Airflow / OpenStudio::convert(unit_final.Cool_Capacity,"Btu/h","ton").get < 200
                unit_final.Cool_Airflow = 201 * OpenStudio::convert(unit_final.Cool_Capacity,"Btu/h","ton").get      # CFM
            end
                
        elsif hvac.HasMiniSplitHeatPump
                            
            sizingSpeed = hvac.NumSpeedsCooling # Default
            sizingSpeed_Test = 10    # Initialize
            for speed in 0..(hvac.NumSpeedsCooling - 1)
                # Select curves for sizing using the speed with the capacity ratio closest to 1
                temp = (hvac.CapacityRatioCooling[speed] - 1).abs
                if temp <= sizingSpeed_Test
                    sizingSpeed = speed
                    sizingSpeed_Test = temp
                end
            end
            coefficients = hvac.COOL_CAP_FT_SPEC_coefficients[sizingSpeed]
            
            unit_final.TotalCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_cooling, enteringTemp, coefficients)
            
            unit_final.Cool_Capacity = (unit_final.Cool_Load_Tot / unit_final.TotalCap_CurveValue)
            unit_final.Cool_Capacity_Sens =  unit_final.Cool_Capacity * hvac.SHRRated[sizingSpeed]
            unit_final.Cool_Airflow = hvac.CoolingCFMs[-1] * OpenStudio::convert(unit_final.Cool_Capacity,"Btu/h","ton").get 
        
        elsif hvac.HasRoomAirConditioner
            
            unit_final.TotalCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_cooling, enteringTemp, hvac.COOL_CAP_FT_SPEC_coefficients[0])
            
            unit_final.Cool_Capacity = unit_final.Cool_Load_Tot / unit_final.TotalCap_CurveValue                                            
            unit_final.Cool_Capacity_Sens = unit_final.Cool_Capacity * hvac.SHRRated[0]
            unit_final.Cool_Airflow = hvac.CoolingCFMs[0] * OpenStudio::convert(unit_final.Cool_Capacity,"Btu/h","ton").get 
                                            
        elsif hvac.HasGroundSourceHeatPump
        
            # Single speed as current
            unit_final.TotalCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_cooling, enteringTemp, hvac.COOL_CAP_FT_SPEC_coefficients[0])
            # FIXME
            #sensibleCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_cooling, enteringTemp, cOOL_SH_FT_SPEC_coefficients)
            # mj8.BypassFactor_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_cooling, mj8.cool_setpoint, cOIL_BF_FT_SPEC_coefficients)

            # unit_final.Cool_Capacity = unit_final.Cool_Load_Tot / unit_final.TotalCap_CurveValue          # Note: cool_Capacity_Design = unit_final.Cool_Load_Tot
            # mj8.sHR_Rated_Equip = hvac.SHRRated[0]
            # unit_final.Cool_Capacity_Sens = unit_final.Cool_Capacity * mj8.sHR_Rated_Equip
            
            # unit.supply.Cool_Load_SensCap_Design = (unit_final.Cool_Capacity_Sens * sensibleCap_CurveValue / 
                                              # (1 + (1 - unit.supply.CoilBF * mj8.BypassFactor_CurveValue) * 
                                               # (80 - mj8.cool_setpoint) / 
                                               # (mj8.cool_setpoint - unit_init.LAT)))
            # unit.supply.Cool_Load_LatCap_Design = unit_final.Cool_Load_Tot - unit.supply.Cool_Load_SensCap_Design
            
            # # Adjust Sizing so that a. coil sensible at design >= CoolingLoad_MJ8_Sens, and coil latent at design >= CoolingLoad_MJ8_Lat, and equipment SHRRated is maintained.
            # unit.supply.Cool_Load_SensCap_Design = max(unit.supply.Cool_Load_SensCap_Design, unit_final.Cool_Load_Sens)
            # unit.supply.Cool_Load_LatCap_Design = max(unit.supply.Cool_Load_LatCap_Design, unit_final.Cool_Load_Lat)
            # cool_Capacity_Design = unit.supply.Cool_Load_SensCap_Design + unit.supply.Cool_Load_LatCap_Design
            
            # # Limit total capacity to 15% oversizing
            # cool_Capacity_Design = min(cool_Capacity_Design, hvac.OverSizeLimit * unit_final.Cool_Load_Tot)
            # unit_final.Cool_Capacity = cool_Capacity_Design / unit_final.TotalCap_CurveValue
            # unit_final.Cool_Capacity_Sens = unit_final.Cool_Capacity * mj8.sHR_Rated_Equip
            
            # # Recalculate the air flow rate in case the 15% oversizing rule has been used
            # unit.supply.Cool_Load_SensCap_Design = (unit_final.Cool_Capacity_Sens * sensibleCap_CurveValue / 
                                              # (1 + (1 - unit.supply.CoilBF * mj8.BypassFactor_CurveValue) * 
                                               # (80 - mj8.cool_setpoint) / 
                                               # (mj8.cool_setpoint - unit_init.LAT)))
            # unit_final.Cool_Airflow = (unit.supply.Cool_Load_SensCap_Design / 
                                           # (1.1 * sim.site.acf * 
                                            # (mj8.cool_setpoint - unit_init.LAT)))
        else
        
            runner.registerError("Unexpected cooling system.")
            return nil
        
        end

    else
        unit_final.Cool_Capacity = 0
        unit_final.Cool_Capacity_Sens = 0
        unit_final.Cool_Airflow = 0
    end
    return unit_final
  end
    
  def processFixedEquipment(runner, unit_final, hvac, spaceConditionedMult)
    '''
    Fixed Sizing Equipment
    '''
    
    return nil if unit_final.nil?
    
    # Override Manual J sizes if Fixed sizes are being used
    if not hvac.FixedCoolingCapacity.nil?
        unit_final.Cool_Capacity = OpenStudio::convert(hvac.FixedCoolingCapacity,"ton","Btu/h").get / spaceConditionedMult
    end
    # FIXME: Better handle heat pump heating vs supplemental heating?
    if not hvac.FixedHeatingCapacity.nil?
        unit_final.Heat_Load = OpenStudio::convert(hvac.FixedHeatingCapacity,"ton","Btu/h").get # (supplemental capacity, so don't divide by spaceConditionedMult)
    end
  
    return unit_final
  end
    
  def processFinalize(runner, mj8, unit_final, weather, hvac, minCoolingCapacity, isExistingHome, hpSizeForMaxLoad, spaceConditionedMult)
    ''' 
    Finalize Sizing Calculations
    '''
    
    return nil if mj8.nil? or unit_final.nil?
    
    unit_final.Heat_Capacity_Supp = 0
    
    if hvac.HasFurnace
        unit_final.Heat_Capacity = unit_final.Heat_Load
        unit_final.Heat_Airflow = calc_heat_cfm(unit_final.Heat_Capacity, mj8.acf, mj8.heat_setpoint, hvac.HtgSupplyAirTemp)

    elsif hvac.HasAirSourceHeatPump
        
        if not hvac.FixedHeatingCapacity.nil? or not hvac.FixedCoolingCapacity.nil?
            unit_final.Heat_Capacity = unit_final.Heat_Load
        else
            unit_final = processHeatPumpAdjustment(runner, mj8, unit_final, weather, hvac, isExistingHome, hpSizeForMaxLoad)
        end
            
        unit_final.Heat_Capacity_Supp = unit_final.Heat_Load
            
        if unit_final.Cool_Capacity > minCoolingCapacity
            unit_final.Heat_Airflow = unit_final.Heat_Capacity / (1.1 * mj8.acf * (hvac.HtgSupplyAirTemp - mj8.heat_setpoint))
        else
            unit_final.Heat_Airflow = unit_final.Heat_Capacity_Supp / (1.1 * mj8.acf * (hvac.HtgSupplyAirTemp - mj8.heat_setpoint))
        end

    elsif hvac.HasMiniSplitHeatPump
        
        if hvac.FixedCoolingCapacity.nil?
            unit_final = processHeatPumpAdjustment(runner, mj8, unit_final, weather, hvac, isExistingHome, hpSizeForMaxLoad)
        end
        
         unit_final.Heat_Capacity = unit_final.Cool_Capacity + (hvac.HeatingCapacityOffset / spaceConditionedMult)
        
        if hvac.HasElecBaseboard
            unit_final.Heat_Capacity_Supp = unit_final.Heat_Load
        end
        
        unit_final.Heat_Airflow = hvac.HeatingCFMs[-1] * OpenStudio::convert(unit_final.Heat_Capacity,"Btu/hr","ton").get # Maximum air flow under heating operation

    elsif hvac.HasBoiler
        unit_final.Heat_Airflow = 0
        unit_final.Heat_Capacity = unit_final.Heat_Load
            
    elsif hvac.HasElecBaseboard
        unit_final.Heat_Airflow = 0
        unit_final.Heat_Capacity = unit_final.Heat_Load

    elsif hvac.HasGroundSourceHeatPump
        # FIXME
        # if unit.cool_capacity is None:
            # unit_final.Heat_Capacity = unit_final.Heat_Load
        # else:
            # unit_final.Heat_Capacity = unit_final.Cool_Capacity
        # unit_final.Heat_Capacity_Supp = unit_final.Heat_Load
        
        # HDD65F = weather.data.HDD65F
        # HDD50F = weather.data.HDD50F
        # CDD65F = weather.data.CDD65F
        # CDD50F = weather.data.CDD50F
        
        # # For single stage compressor, when heating capacity is much larger than cooling capacity, 
        # # in order to avoid frequent cycling in cooling mode, heating capacity is derated to 75%.
        # if unit_final.Heat_Capacity >= (1.5 * unit_final.Cool_Capacity):
            # unit_final.Heat_Capacity = unit_final.Heat_Load * 0.75
        # elif unit_final.Heat_Capacity < unit_final.Cool_Capacity:
            # unit_final.Heat_Capacity_Supp = unit_final.Heat_Capacity
        
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
            
            # VertHXBoreLength_Cool = Nom_Length_Cool * unit_final.Cool_Capacity / units.Ton2Btu_h(1)
            # VertHXBoreLength_Heat = Nom_Length_Heat * unit_final.Heat_Capacity / units.Ton2Btu_h(1)

            # unit.supply.VertHXBoreLength = max(VertHXBoreLength_Heat, VertHXBoreLength_Cool) # Using maximum of cooling and heating load effectively controls annual load balancing in heating climate
        
            # # Degree day calculation for balance temperature
            # BLC_Heat = mj8.Heat_LoadingLoad_Inter / mj8.htd
            # BLC_Cool = mj8.CoolingLoad_Inter_Sens / mj8.ctd
            # T_Ref_Bal = mj8.heat_setpoint - mj8.Int_Sens_Hr / BLC_Heat # FIXME: mj8.Int_Sens_Hr references the 24th hour of the day?
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

            # unit_final.Cool_Capacity = max(unit_final.Cool_Capacity, unit_final.Heat_Capacity)
            # unit_final.Heat_Capacity = unit_final.Cool_Capacity
            # unit_final.Cool_Capacity_Sens = unit_final.Cool_Capacity * mj8.sHR_Rated_Equip
            # unit.supply.Cool_Load_SensCap_Design = (unit_final.Cool_Capacity_Sens * sensibleCap_CurveValue / 
                                              # (1 + (1 - unit.supply.CoilBF * mj8.BypassFactor_CurveValue) * 
                                               # (80 - mj8.cool_setpoint) / 
                                               # (mj8.cool_setpoint - unit_init.LAT)))
            # unit_final.Cool_Airflow = (unit.supply.Cool_Load_SensCap_Design / 
                                           # (1.1 * sim.site.acf * 
                                            # (mj8.cool_setpoint - unit_init.LAT)))
            # unit_final.Heat_Airflow = (unit_final.Heat_Capacity / 
                                           # (1.1 * sim.site.acf * 
                                            # (hvac.HtgSupplyAirTemp - mj8.heat_setpoint)))
            
            # #Overwrite heating and cooling airflow rate to be 400 cfm/ton when doing HERS index calculations
            # if sim.hers_rated:
                # unit_final.Cool_Airflow = units.Btu_h2Ton(unit_final.Cool_Capacity) * 400
                # unit_final.Heat_Airflow = units.Btu_h2Ton(unit_final.Heat_Capacity) * 400
                
            # unit.gshp.loop_flow = floor(max(units.Btu_h2Ton(max(unit_final.Heat_Capacity, unit_final.Cool_Capacity)),1)) * 3.0
        
            # if unit.supply.HXNumOfBoreHole == Constants.SizingAuto and unit.supply.HXVertDepth == Constants.SizingAuto:
                # unit.supply.HXNumOfBoreHole = max(1, floor(units.Btu_h2Ton(unit_final.Cool_Capacity) + 0.5))
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
                # runner.registerInfo("User is hard sizing the bore field, improper sizing may lead to unbalanced / unsteady ground loop temperature and erroneous prediction of system energy related cost.")
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
        unit_final.Heat_Capacity = 0
        unit_final.Heat_Airflow = 0
    end

    # Use fixed airflow rates if provided
    # FIXME
    #if unit_final.Cool_Airflow != 0 and unit.cool_airflow_rate is not None:
    #    unit_final.Cool_Airflow = unit.cool_airflow_rate
    #if unit_final.Heat_Airflow != 0 and unit.heat_airflow_rate is not None:
    #    unit_final.Heat_Airflow = unit.heat_airflow_rate
    
    unit_final.Fan_Airflow = [unit_final.Heat_Airflow, unit_final.Cool_Airflow].max
  
    return unit_final
  end
  
  def processHeatPumpAdjustment(runner, mj8, unit_final, weather, hvac, isExistingHome, hpSizeForMaxLoad)
    '''
    Adjust heat pump sizing 
    '''
    if hvac.NumSpeedsHeating > 1
        coefficients = hvac.HEAT_CAP_FT_SPEC_coefficients[hvac.NumSpeedsHeating - 1]
        capacity_ratio = hvac.CapacityRatioHeating[hvac.NumSpeedsHeating - 1]
    else
        coefficients = hvac.HEAT_CAP_FT_SPEC_coefficients[0]
        capacity_ratio = 1.0
    end
    
    if hvac.MinOutdoorTemp < weather.design.HeatingDrybulb
        heat_db = weather.design.HeatingDrybulb
        heat_pump_load = unit_final.Heat_Load
    else
        
        # FIXME FIXME FIXME
        # Ask Jon: Why not calculate the loads up front using the min hp temp
        #          rather than the design drybulb?
        # FIXME FIXME FIXME
    
    
        # Calculate the heating load at the minimum compressor temperature to limit unutilized capacity
        heat_db = hvac.MinOutdoorTemp
        htd =  mj8.heat_setpoint - heat_db
        
        heat_pump_load = unit_final.Heat_Load # FIXME: Temporary
        
        # FIXME
        # Update the buffer space temperatures for the minimum
        #for space in geometry.spaces.space:
        #    if space.spacetype in [Constants.SpaceLiving, Constants.SpaceFinBasement, Constants.SpaceFinAttic]:
        #        if space.unit_id == unit.id:
        #            if simpy.hasSpaceType(geometry, space.spacetype, unit):                        
        #                space.heat_design_temp_mj8 = sim._calcSpaceTemperatureHeating(space.spacetype, unit, heat_db)
        #                                            
        #    elif simpy.hasSpaceType(geometry, space.spacetype):
        #        space.heat_design_temp_mj8 = space.heat_design_temp
        #        
        ## Calculate the cooling design temperature for the unfinished attic based on Figure A12-14
        #if simpy.hasSpaceType(geometry, Constants.SpaceUnfinAttic):                
        #     
        #    if sim.unfinished_attic.UACeilingInsRvalueNominal_Rev > sim.unfinished_attic.UARoofInsRvalueNominal:                
        #        sim.unfinished_attic.heat_design_temp_mj8 = heat_db
        
        # Calculate heating loads at the minimum compressor temperature
        # zones_loads = []
        # unit_thermal_zones.each do |thermal_zone|
            # next if not Geometry.zone_is_finished(thermal_zone)
            # zone_loads = processZoneLoads(runner, mj8, thermal_zone, weather, northAxis, nbeds, unit_ffa_for_people, modelYear, model.alwaysOnDiscreteSchedule)
            # return nil if zone_loads.nil?
            # zones_loads << zone_loads
        # end
        # unit_init = processIntermediateTotalLoads(runner, mj8, zones_loads, weather, hvac)
            
        # load_inter = 0
        # zones_loads.keys.each do |thermal_zone|
            # zone_loads = zones_loads[thermal_zone]
            
        # end
        # load_inter = cond_liv + cond_fbsmt + inf_vent_liv + inf_fbsmt
        
        # if ducts.Has and ducts.NotInLiving:
            # if ducts.Location != Constants.SpaceFinBasement:                    
                # dse_Tamb_heating = ducts.LocationSpace.heat_design_temp_mj8
                # duct_load_heating = self._calc_heating_duct_load(sim, mj8, weather, geometry, unit, load_inter, dse_Tamb_heating)
            # else:
                # #Ducts in the a finished basement does not impact equipment capacity
                # duct_load_heating = 0
        # else:
            # duct_load_heating = 0
        
        # heat_pump_load = load_inter + duct_load_heating
    end
        
    heatCap_Rated = (heat_pump_load / MathTools.biquadratic(mj8.heat_setpoint, heat_db, coefficients)) / capacity_ratio
    
    if heatCap_Rated < unit_final.Cool_Capacity
        if hvac.HasAirSourceHeatPump
            unit_final.Heat_Capacity = unit_final.Cool_Capacity
        elsif hvac.HasMiniSplitHeatPump
            unit_final.Heat_Capacity = unit_final.Cool_Capacity + hvac.HeatingCapacityOffset
        end
    else
        if hpSizeForMaxLoad
            unit_final.Heat_Capacity = heatCap_Rated
            if hvac.HasAirSourceHeatPump
                # When sizing based on heating load, limit the capacity to 5 tons for existing homes
                if isExistingHome
                    unit_final.Heat_Capacity = [unit_final.Heat_Capacity, OpenStudio::convert(5.0,"ton","Btu/hr").get].min
                end
                cfm_Btu = unit_final.Cool_Airflow / unit_final.Cool_Capacity
                unit_final.Cool_Capacity = unit_final.Heat_Capacity
                unit_final.Cool_Airflow = cfm_Btu * unit_final.Cool_Capacity
            elsif hvac.HasMiniSplitHeatPump
                unit_final.Cool_Capacity = unit_final.Heat_Capacity - hvac.HeatingCapacityOffset
                unit_final.Cool_Airflow = hvac.CoolingCFMs[-1] * OpenStudio::convert(unit_final.Cool_Capacity,"Btu/hr","ton").get
            end
        else
            cfm_Btu = unit_final.Cool_Airflow / unit_final.Cool_Capacity                
            load_shr = unit_final.Cool_Load_Sens / unit_final.Cool_Load_Tot
            if (weather.data.HDD65F / weather.data.CDD50F) < 2.0 or load_shr < 0.95
                #Mild winter or has a latent cooling load
                unit_final.Cool_Capacity = [(hvac.OverSizeLimit * unit_final.Cool_Load_Tot) / unit_final.TotalCap_CurveValue, heatCap_Rated].min
            else
                #Cold winter and no latent cooling load (add a ton rule applies)
                unit_final.Cool_Capacity = [(unit_final.Cool_Load_Tot + 15000) / unit_final.TotalCap_CurveValue, heatCap_Rated].min
            end
            if hvac.HasAirSourceHeatPump
                unit_final.Cool_Airflow = cfm_Btu * unit_final.Cool_Capacity
                unit_final.Heat_Capacity = unit_final.Cool_Capacity
            elsif hvac.HasMiniSplitHeatPump
                unit_final.Cool_Airflow = hvac.CoolingCFMs[-1] * OpenStudio::convert(unit_final.Cool_Capacity,"Btu/hr","ton").get
                unit_final.Heat_Capacity = unit_final.Cool_Capacity + hvac.HeatingCapacityOffset
            end
        end
    end

    return unit_final
  end
  
  def processSlaveZoneFlowRatios(runner, unit_final)
    '''
    Flow Ratios for Slave Zones
    '''
    
    return nil if unit_final.nil?
    
    # FIXME
    # if simpy.hasSpaceType(geometry, Constants.SpaceFinBasement, unit):
        
        # if unit.basement_airflow_ratio is not None:
            # unit.supply.FBsmt_FlowRatio = unit.basement_airflow_ratio
            
        # else:
            # # Divide up flow rate to Living and Finished Bsmt based on MJ8 loads
            
            # # mj8.Heat_LoadingLoad_FBsmt = mj8.Heat_LoadingLoad * (mj8.Heat_LoadingLoad_FBsmt + mj8.Heat_LoadingLoad_Inf_FBsmt) / mj8.Heat_LoadingLoad_Inter
            # mj8.Heat_LoadingLoad_FBsmt = mj8.Heat_LoadingLoad_FBsmt + mj8.Heat_LoadingLoad_Inf_FBsmt - mj8.DuctLoad_FinBasement
            
            # # Use a minimum flow ratio of 1%. Low flow ratios can be calculated for buildings with inefficient above grade construction
            # # or poor ductwork in the finished basement.  
            # unit.supply.FBsmt_FlowRatio = max(mj8.Heat_LoadingLoad_FBsmt / mj8.Heat_LoadingLoad, 0.01)

    # else:
        # unit.supply.FBsmt_FlowRatio = 0.0

    return unit_final
  end
  
  def processEfficientCapacityDerate(runner, hvac, unit_final)
    '''
    AC & HP Efficiency Capacity Derate
    '''
    
    return nil if unit_final.nil?
    
    eER_CapacityDerateFactor = [1.0, 1.0, 1.0, 1.0, 1.0] # FIXME
    cOP_CapacityDerateFactor = [1.0, 1.0, 1.0, 1.0, 1.0] # FIXME
    tonnages = [1.5, 2, 3, 4, 5] # FIXME: Get from HVAC measures
    
    if not hvac.HasCentralAirConditioner and not hvac.HasAirSourceHeatPump
        return unit_final
    end

    # EER_CapacityDerateFactor values correspond to 1.5, 2, 3, 4, 5 ton air-conditioners. Interpolate in between nominal sizes.
    aC_Tons = OpenStudio::convert(unit_final.Cool_Capacity,"Btu/h","ton").get
    
    if aC_Tons <= 1.5
        eER_Multiplier = eER_CapacityDerateFactor[0]
    elsif aC_Tons <= 5
        index = (aC_Tons.floor - 1).to_i
        eER_Multiplier = MathTools.interp2(aC_Tons, tonnages[index-1], tonnages[index],
                                           eER_CapacityDerateFactor[index-1], 
                                           eER_CapacityDerateFactor[index])
    elsif aC_Tons <= 10
        index = ((aC_Tons/2.0).floor - 1).to_i
        eER_Multiplier = MathTools.interp2(aC_Tons/2.0, tonnages[index-1], tonnages[index],
                                           eER_CapacityDerateFactor[index-1], 
                                           eER_CapacityDerateFactor[index])
    else
        eER_Multiplier = eER_CapacityDerateFactor[-1]
    end
    
    for speed in 0..(hvac.NumSpeedsCooling-1)
        # FIXME
        #unit.supply.CoolingEIR[speed] = unit.supply.CoolingEIR[speed] / eER_Multiplier
    end
    
    if hvac.HasAirSourceHeatPump
    
        if aC_Tons <= 1.5
            cOP_Multiplier = cOP_CapacityDerateFactor[0]
        elsif aC_Tons <= 5
            index = (aC_Tons.floor - 1).to_i
            cOP_Multiplier = MathTools.interp2(aC_Tons, tonnages[index-1], tonnages[index], 
                                               cOP_CapacityDerateFactor[index-1], 
                                               cOP_CapacityDerateFactor[index])
        elsif aC_Tons <= 10
            index = ((aC_Tons/2.0).floor - 1).to_i
            cOP_Multiplier = MathTools.interp2(aC_Tons/2.0, tonnages[index-1], tonnages[index], 
                                               cOP_CapacityDerateFactor[index-1], 
                                               cOP_CapacityDerateFactor[index])
        else
            cOP_Multiplier = cOP_CapacityDerateFactor[-1]
        end
    
        for speed in 0..(hvac.NumSpeedsCooling-1)
            # FIXME
            #unit.supply.HeatingEIR[speed] = unit.supply.HeatingEIR[speed] / cOP_Multiplier
        end
        
    end
  
    return unit_final
  end
    
  def processDehumidifierSizing(runner, mj8, unit_final, weather, dehumid_Load_Lat, hvac, minCoolingCapacity, shr_biquadratic_coefficients)
    '''
    Dehumidifier Sizing
    '''
    
    return nil if mj8.nil? or unit_final.nil?
    
    fanspeed_ratio = [0.7, 1.0] # FIXME
    
    # TODO: Simplify code
    if hvac.HasCooling and unit_final.Cool_Capacity > minCoolingCapacity
    
        dehum_design_db = weather.design.DehumidDrybulb
        
        if hvac.NumSpeedsCooling > 1
            
            if not hvac.HasMiniSplitHeatPump
            
                totalCap_CurveValue_1 = MathTools.biquadratic(mj8.wetbulb_indoor_dehumid, dehum_design_db, hvac.COOL_CAP_FT_SPEC_coefficients[0])
                dehumid_AC_TotCap_1 = totalCap_CurveValue_1 * unit_final.Cool_Capacity * hvac.CapacityRatioCooling[0]
            
                sensibleCap_CurveValue_1 = process_curve_fit(unit_final.Cool_Airflow * fanspeed_ratio[0], dehumid_AC_TotCap_1, dehum_design_db, shr_biquadratic_coefficients)
                dehumid_AC_SensCap_1 = sensibleCap_CurveValue_1 * unit_final.Cool_Capacity_Sens * hvac.CapacityRatioCooling[0]
            
                if unit_final.Dehumid_Load_Sens > dehumid_AC_SensCap_1
                    # AC will operate in Stage 2
                    totalCap_CurveValue_2 = MathTools.biquadratic(mj8.wetbulb_indoor_dehumid, dehum_design_db, hvac.COOL_CAP_FT_SPEC_coefficients[1])
                    dehumid_AC_TotCap_2 = totalCap_CurveValue_2 * unit_final.Cool_Capacity
            
                    sensibleCap_CurveValue_2 = process_curve_fit(unit_final.Cool_Airflow, dehumid_AC_TotCap_2, dehum_design_db, shr_biquadratic_coefficients)
                    dehumid_AC_SensCap_2 = sensibleCap_CurveValue_2 * unit_final.Cool_Capacity_Sens
            
                    dehumid_AC_LatCap = dehumid_AC_TotCap_2 - dehumid_AC_SensCap_2
                    dehumid_AC_RTF = [0, unit_final.Dehumid_Load_Sens / dehumid_AC_SensCap_2].max
                else
                    dehumid_AC_LatCap = dehumid_AC_TotCap_1 - dehumid_AC_SensCap_1
                    dehumid_AC_RTF = [0, unit_final.Dehumid_Load_Sens / dehumid_AC_SensCap_1].max
                end
                    
            else
                
                dehumid_AC_TotCap_i_1 = 0
                for i in 0..(hvac.NumSpeedsCooling - 1)
                
                    totalCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_dehumid, dehum_design_db, hvac.COOL_CAP_FT_SPEC_coefficients[i])
                    
                    dehumid_AC_TotCap = totalCap_CurveValue * unit_final.Cool_Capacity * hvac.CapacityRatioCooling[i]
                    sens_cap = hvac.SHRRated[i] * dehumid_AC_TotCap  #TODO: This could be slightly improved by not assuming a constant SHR
                  
                    if sens_cap >= unit_final.Dehumid_Load_Sens
                        
                        if i > 0
                            dehumid_AC_SensCap = unit_final.Dehumid_Load_Sens
                            
                            # Determine portion of load met by speed i and i-1 using: Q_i*s + Q_i-1*(s-1) = Q_load
                            s = (unit_final.Dehumid_Load_Sens + dehumid_AC_TotCap_i_1 * hvac.SHRRated[i-1]) / (sens_cap + dehumid_AC_TotCap_i_1 * hvac.SHRRated[i-1])
                            
                            dehumid_AC_LatCap = s * (1 - hvac.SHRRated[i]) * dehumid_AC_TotCap + \
                                                (1 - s) * (1 - hvac.SHRRated[i-1]) * dehumid_AC_TotCap_i_1
                            
                            dehumid_AC_RTF = 1
                        else
                            dehumid_AC_SensCap = sens_cap
                            dehumid_AC_LatCap = dehumid_AC_TotCap - dehumid_AC_SensCap
                            dehumid_AC_RTF = [0, unit_final.Dehumid_Load_Sens / dehumid_AC_SensCap].max
                        end
                        
                        break
                    
                    end
                    
                    dehumid_AC_TotCap_i_1 = dehumid_AC_TotCap                        
                
                end
                
            end
            
        else       # Single Speed
            
            if not hvac.HasGroundSourceHeatPump
                enteringTemp = dehum_design_db
            else   # Use annual average temperature for this evaluation
                enteringTemp = weather.data.AnnualAvgDrybulb
            end
            
            totalCap_CurveValue = MathTools.biquadratic(mj8.wetbulb_indoor_dehumid, enteringTemp, hvac.COOL_CAP_FT_SPEC_coefficients[0])
            dehumid_AC_TotCap = totalCap_CurveValue * unit_final.Cool_Capacity
        
            if hvac.HasRoomAirConditioner     # Assume constant SHR for now.
                sensibleCap_CurveValue = hvac.SHRRated[0]
            else
                # FIXME: For GSHP, there are two different temperatures, which deviates from all other uses of this curve fit
                sensibleCap_CurveValue = process_curve_fit(unit_final.Cool_Airflow, dehumid_AC_TotCap, enteringTemp, shr_biquadratic_coefficients)
            end
            
            dehumid_AC_SensCap = sensibleCap_CurveValue * unit_final.Cool_Capacity_Sens
            dehumid_AC_LatCap = dehumid_AC_TotCap - dehumid_AC_SensCap
            dehumid_AC_RTF = [0, unit_final.Dehumid_Load_Sens / dehumid_AC_SensCap].max
            
        end
            
    else
        dehumid_AC_SensCap = 0
        dehumid_AC_LatCap = 0
        dehumid_AC_RTF = 0
    end
            
            
    # Determine the average total latent load (there's duct latent load only when the AC is running)
    dehumidLoad_Lat = [0, dehumid_Load_Lat + unit_final.Dehumid_Load_Ducts_Lat * dehumid_AC_RTF].max

    air_h_fg = 1075.6  # Btu/lbm

    # Calculate the required water removal (in L/day) at 75 deg-F DB, 50% RH indoor conditions
    dehumid_WaterRemoval = [0, (dehumidLoad_Lat - dehumid_AC_RTF * dehumid_AC_LatCap) / air_h_fg /
                               Liquid.H2O_l.rho * OpenStudio::convert(1,"ft^3","L").get * OpenStudio::convert(1,"day","hr").get].max

    # Determine the rated water removal rate using the performance curve
    zone_Water_Remove_Cap_Ft_DB_RH_coefficients = [-1.162525707, 0.02271469, -0.000113208, 0.021110538, -0.0000693034, 0.000378843] # FIXME
    dehumid_CurveValue = MathTools.biquadratic(OpenStudio::convert(mj8.cool_setpoint,"F","C").get, mj8.RH_indoor_dehumid * 100, zone_Water_Remove_Cap_Ft_DB_RH_coefficients)
    unit_final.Dehumid_WaterRemoval = dehumid_WaterRemoval / dehumid_CurveValue
  
    return unit_final
  end
    
  def get_shelter_class(model, unit)

    neighbor_offset_ft = Geometry.get_closest_neighbor_distance(model)
    unit_height_ft = Geometry.get_building_height(unit.spaces)
    exposed_wall_ratio = Geometry.calculate_above_grade_exterior_wall_area(unit.spaces) / 
                         Geometry.calculate_above_grade_wall_area(unit.spaces)

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
        return OpenStudio::convert(simple_glazing.uFactor,"W/m^2*K","Btu/ft^2*h*R").get
     else
        if not surface.construction.is_initialized
            runner.registerError("Construction not assigned to '#{surface.name.to_s}'.")
            return nil
        end
        construction = surface.construction.get
        return OpenStudio::convert(surface.uFactor.get,"W/m^2*K","Btu/ft^2*h*R").get
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
  
  def calc_heat_cfm(load, acf, heat_setpoint, htg_supply_air_temp)
    return load / (1.1 * acf * (htg_supply_air_temp - heat_setpoint))
  end
  
  def calc_heat_duct_load(ducts, acf, heat_setpoint, dse_Fregain, heatingLoad, htg_supply_air_temp, t_amb)

    # Supply and return duct surface areas located outside conditioned space
    dse_As = ducts.SupplySurfaceArea * ducts.LocationFrac
    dse_Ar = ducts.ReturnSurfaceArea
        
    # Initialize for the iteration
    delta = 1
    heatingLoad_Prev = heatingLoad
    heat_cfm = calc_heat_cfm(heatingLoad, acf, heat_setpoint, htg_supply_air_temp)
    
    for _iter in 0..19
        break if delta.abs <= 0.001

        dse_DEcorr_heating, _dse_dTe_heating = calc_dse_heating(ducts, acf, heat_cfm, heatingLoad_Prev, t_amb, dse_As, dse_Ar, heat_setpoint, dse_Fregain)

        # Calculate the increase in heating load due to ducts (Approach: DE = Qload/Qequip -> Qducts = Qequip-Qload)
        heatingLoad_Next = heatingLoad / dse_DEcorr_heating
        
        # Calculate the change since the last iteration
        delta = (heatingLoad_Next - heatingLoad_Prev) / heatingLoad_Prev
        
        # Update the flow rate for the next iteration
        heatingLoad_Prev = heatingLoad_Next
        heat_cfm = calc_heat_cfm(heatingLoad_Next, acf, heat_setpoint, htg_supply_air_temp)
    end

    return heatingLoad_Next - heatingLoad

  end
  
  def calc_dse_heating(ducts, acf, cfm_inter, load_Inter_Sens, dse_Tamb, dse_As, dse_Ar, t_setpoint, dse_Fregain)
    '''
    Calculate the Distribution System Efficiency using the method of ASHRAE Standard 152 (used for heating and cooling).
    '''
  
    dse_Bs, dse_Br, dse_a_s, dse_a_r, dse_dTe, dse_dT = _calc_dse_init(ducts, acf, cfm_inter, load_Inter_Sens, dse_Tamb, dse_As, dse_Ar, t_setpoint)
    dse_DE = _calc_dse_DE_heating(dse_a_s, dse_Bs, dse_a_r, dse_Br, dse_dT, dse_dTe)
    dse_DEcorr = _calc_dse_DEcorr(ducts, dse_DE, dse_Fregain, dse_Br, dse_a_r)
    
    return dse_DEcorr, dse_dTe
  end
  
  def calc_dse_cooling(ducts, acf, enthalpy_indoor_cooling, leavingAirTemp, cfm_inter, load_Inter_Sens, dse_Tamb, dse_As, dse_Ar, t_setpoint, dse_Fregain, coolingLoad_Tot, dse_h_Return_Cooling)
    '''
    Calculate the Distribution System Efficiency using the method of ASHRAE Standard 152 (used for heating and cooling).
    '''
  
    dse_Bs, dse_Br, dse_a_s, dse_a_r, dse_dTe, dse_dT = _calc_dse_init(ducts, acf, cfm_inter, load_Inter_Sens, dse_Tamb, dse_As, dse_Ar, t_setpoint)
    dse_DE, coolingLoad_Ducts_Sens = _calc_dse_DE_cooling(dse_a_s, cfm_inter, coolingLoad_Tot, dse_a_r, dse_h_Return_Cooling, enthalpy_indoor_cooling, dse_Br, dse_dT, dse_Bs, leavingAirTemp, dse_Tamb, load_Inter_Sens)
    dse_DEcorr = _calc_dse_DEcorr(ducts, dse_DE, dse_Fregain, dse_Br, dse_a_r)
    
    return dse_DEcorr, dse_dTe, coolingLoad_Ducts_Sens
  end
  
  def _calc_dse_init(ducts, acf, cfm_inter, load_Inter_Sens, dse_Tamb, dse_As, dse_Ar, t_setpoint)
    
    dse_Qs = ducts.SupplyLoss * cfm_inter
    dse_Qr = ducts.ReturnLoss * cfm_inter

    # Supply and return conduction functions, Bs and Br
    if ducts.NotInLiving
        dse_Bs = Math.exp((-1.0 * dse_As) / (60 * cfm_inter * Gas.Air.rho * Gas.Air.cp * ducts.SupplyRvalue))
        dse_Br = Math.exp((-1.0 * dse_Ar) / (60 * cfm_inter * Gas.Air.rho * Gas.Air.cp * ducts.ReturnRvalue))

    else
        dse_Bs = 1
        dse_Br = 1
    end

    dse_a_s = (cfm_inter - dse_Qs) / cfm_inter
    dse_a_r = (cfm_inter - dse_Qr) / cfm_inter

    dse_dTe = load_Inter_Sens / (1.1 * acf * cfm_inter)
    dse_dT = t_setpoint - dse_Tamb
    
    return dse_Bs, dse_Br, dse_a_s, dse_a_r, dse_dTe, dse_dT
  end
  
  def _calc_dse_DE_cooling(dse_a_s, cfm_inter, coolingLoad_Tot, dse_a_r, dse_h_Return_Cooling, enthalpy_indoor_cooling, dse_Br, dse_dT, dse_Bs, leavingAirTemp, dse_Tamb, load_Inter_Sens)
    # FIXME: Comments below apply here or below?
    # Calculate the delivery effectiveness (Equation 6-23) 
    # NOTE: This equation is for heating but DE equation for cooling requires psychrometric calculations. This should be corrected.
    dse_DE = ((dse_a_s * 60 * cfm_inter * Gas.Air.rho) / (-1 * coolingLoad_Tot)) * \
              (((-1 * coolingLoad_Tot) / (60 * cfm_inter * Gas.Air.rho)) + \
               (1 - dse_a_r) * (dse_h_Return_Cooling - enthalpy_indoor_cooling) + \
               dse_a_r * Gas.Air.cp * (dse_Br - 1) * dse_dT + \
               Gas.Air.cp * (dse_Bs - 1) * (leavingAirTemp - dse_Tamb))
    
    # Calculate the sensible heat transfer from surroundings
    # FIXME: Move elsewhere?
    coolingLoad_Ducts_Sens = (1 - [dse_DE,0].max) * load_Inter_Sens
    
    return dse_DE, coolingLoad_Ducts_Sens
  end
  
  def _calc_dse_DE_heating(dse_a_s, dse_Bs, dse_a_r, dse_Br, dse_dT, dse_dTe)
    # FIXME: Comments below apply here or above?
    # Calculate the delivery effectiveness (Equation 6-23) 
    # NOTE: This equation is for heating but DE equation for cooling requires psychrometric calculations. This should be corrected.
    dse_DE = (dse_a_s * dse_Bs - 
              dse_a_s * dse_Bs * (1 - dse_a_r * dse_Br) * (dse_dT / dse_dTe) - 
              dse_a_s * (1 - dse_Bs) * (dse_dT / dse_dTe))
    
    return dse_DE
  end
  
  def _calc_dse_DEcorr(ducts, dse_DE, dse_Fregain, dse_Br, dse_a_r)
    # Calculate the delivery effectiveness corrector for regain (Equation 6-40)
    dse_DEcorr = (dse_DE + dse_Fregain * (1 - dse_DE) + 
                  dse_Br * (dse_a_r * dse_Fregain - dse_Fregain))

    # Limit the DE to a reasonable value to prevent negative values and huge equipment
    dse_DEcorr = [dse_DEcorr, 0.25].max
    dse_DEcorr = [dse_DEcorr, 1.00].min
    
    if not ducts.SystemEfficiency.nil?
        dse_DEcorr = ducts.SystemEfficiency
    end
    
    return dse_DEcorr
  end
  
  def calculate_sensible_latent_split(cool_design_grains, grains_indoor_cooling, acf, return_duct_loss, cool_load_tot, coolingLoadLat, cool_Airflow)
    # Calculate the latent duct leakage load (Manual J accounts only for return duct leakage)
    dse_Cool_Load_Latent = [0, 0.68 * acf * return_duct_loss * cool_Airflow * 
                             (cool_design_grains - grains_indoor_cooling)].max
    
    # Calculate final latent and load
    cool_Load_Lat = coolingLoadLat + dse_Cool_Load_Latent
    cool_Load_Sens = cool_load_tot - cool_Load_Lat
    
    return cool_Load_Lat, cool_Load_Sens
  end
  
  def get_ducts_for_unit(runner, model, unit_spaces, hvac, building_num_stories)
    ducts = DuctsInfo.new
    
    ducts.Has = false # FIXME
    if hvac.HasForcedAir and not hvac.HasMiniSplitHeatPump
        ducts.Has = true # FIXME
        ducts.NotInLiving = true # FIXME
        ducts.SystemEfficiency = nil # FIXME
        ducts.NormLeakageToOutside = nil # FIXME
        
        # Get number of stories for ducts
        has_finished_basement = false
        Geometry.get_finished_basement_spaces(unit_spaces).each do |sp|
            if unit_spaces.include?(sp)
                has_finished_basement = true
            end
        end
        if has_finished_basement
            num_stories_for_ducts = building_num_stories + 1
        else
            num_stories_for_ducts = building_num_stories
        end
        
        # Get finished floor area and number of returns
        ffa = Geometry.get_finished_floor_area_from_spaces(unit_spaces)
        num_returns = 1 + num_stories_for_ducts # FIXME
        
        if num_stories_for_ducts == 1
            ducts.SupplySurfaceArea = 0.27 * ffa
            ducts.ReturnSurfaceArea = [0.05 * num_returns * ffa, 0.25 * ffa].min
            ducts.LocationFrac = 1.0
        else
            ducts.SupplySurfaceArea = 0.2 * ffa
            ducts.ReturnSurfaceArea = [0.04 * num_returns * ffa, 0.19 * ffa].min
            ducts.LocationFrac = 0.65
        end
        
        totalLeakage = 0.3 # FIXME
        supplyLeakageFractionOfTotal = 0.6 # FIXME
        returnLeakageFractionOfTotal = 0.0667 # FIXME
        aHSupplyLeakageFractionOfTotal = 0.0667 # FIXME
        aHReturnLeakageFractionOfTotal = 0.267 # FIXME
        
        ductSupplyLeakage = supplyLeakageFractionOfTotal * totalLeakage
        ductReturnLeakage = returnLeakageFractionOfTotal * totalLeakage
        ductAHSupplyLeakage = aHSupplyLeakageFractionOfTotal * totalLeakage
        ductAHReturnLeakage = aHReturnLeakageFractionOfTotal * totalLeakage 
        
        direct_oa_supply_duct_loss = 0.000001
        ducts.SupplyLoss = (ducts.LocationFrac * 
                            (ductSupplyLeakage - direct_oa_supply_duct_loss) + 
                            (ductAHSupplyLeakage + direct_oa_supply_duct_loss))
        ducts.ReturnLoss = ductReturnLeakage + ductAHReturnLeakage
        
        duct_r = 2.0 # FIXME
        if duct_r <= 0
            ducts.SupplyRvalue = 1.7
            ducts.ReturnRvalue = 1.7
        else
            ducts.SupplyRvalue = 2.2438 + 0.5619*duct_r
            ducts.ReturnRvalue = 2.0388 + 0.7053*duct_r
        end
        
        ducts.Location = 'Constants.SpaceGarage' # FIXME
        if ducts.Location == 'Constants.SpaceGarage' # FIXME
            ducts.LocationSpace = Geometry.get_garage_spaces(unit_spaces, model)[0]
        else
            runner.registerError("Unexpected duct location '#{ducts.Location.to_s}'.")
            return false
        end
    end
    
    return ducts
  end
  
  def get_hvac_for_unit(runner, model, unit_thermal_zones)
  
    # Init
    hvac = HVACInfo.new
    hvac.HasForcedAir = false
    hvac.HasCooling = false
    hvac.HasHeating = false
    hvac.HasCentralAirConditioner = false
    hvac.HasRoomAirConditioner = false
    hvac.HasFurnace = false
    hvac.HasBoiler = false
    hvac.HasElecBaseboard = false
    hvac.HasAirSourceHeatPump = false
    hvac.HasMiniSplitHeatPump = false
    hvac.HasGroundSourceHeatPump = false
    hvac.NumSpeedsCooling = 0
    hvac.NumSpeedsHeating = 0
    hvac.COOL_CAP_FT_SPEC_coefficients = nil
    hvac.HEAT_CAP_FT_SPEC_coefficients = nil
    hvac.HtgSupplyAirTemp = nil
    hvac.MinOutdoorTemp = nil
    hvac.SHRRated = nil
    hvac.CapacityRatioCooling = nil
    hvac.CapacityRatioHeating = nil
    hvac.FixedCoolingCapacity = nil
    hvac.FixedHeatingCapacity = nil
    hvac.HeatingCapacityOffset = 2300.0 # FIXME
    hvac.OverSizeLimit = 1.15
    hvac.CoolingCFMs = nil
    hvac.HeatingCFMs = nil
    
    clg_equips = []
    htg_equips = []
    
    control_slave_zones_hash = HVAC.get_control_and_slave_zones(unit_thermal_zones)
    
    if control_slave_zones_hash.keys.size > 1
        runner.registerError("Cannot currently handle multiple HVAC equipment in a unit.")
        return nil
    end
    
    control_zone = control_slave_zones_hash.keys[0]
    
    HVAC.existing_cooling_equipment(model, runner, control_zone).each do |clg_equip|
        next if clg_equips.include? clg_equip
        clg_equips << clg_equip
    end
    
    HVAC.existing_heating_equipment(model, runner, control_zone).each do |htg_equip|
        next if htg_equips.include? htg_equip
        htg_equips << htg_equip
    end
    
    # FIXME: Can we get rid of all of this and just use the coil types?
    if not HVAC.has_central_air_conditioner(model, runner, control_zone, false, false).nil?
        hvac.HasCentralAirConditioner = true
    end
    if not HVAC.has_room_air_conditioner(model, runner, control_zone, false).nil?
        hvac.HasRoomAirConditioner = true
    end
    if not HVAC.has_furnace(model, runner, control_zone, false, false).nil?
        hvac.HasFurnace = true
    end
    if not HVAC.has_boiler(model, runner, control_zone, false).nil?
        hvac.HasBoiler = true
    end
    if not HVAC.has_electric_baseboard(model, runner, control_zone, false).nil?
        hvac.HasElecBaseboard = true
    end
    if not HVAC.has_air_source_heat_pump(model, runner, control_zone, false).nil?
        hvac.HasAirSourceHeatPump = true
    end
    if not HVAC.has_mini_split_heat_pump(model, runner, control_zone, false).nil?
        hvac.HasMiniSplitHeatPump = true
    end
    if not HVAC.has_gshp_vert_bore(model, runner, control_zone, false).nil?
        hvac.HasGroundSourceHeatPump = true
    end
    
    # Cooling equipment
    if clg_equips.size > 0
        hvac.HasCooling = true
    
        if clg_equips.size > 1
            runner.registerError("Cannot currently handle multiple cooling equipment in a unit: #{clg_equips.to_s}.")
            clg_equips.each do |clg_equip|
                runner.registerError(clg_equip.name.to_s)
            end
            return nil
        end
        clg_equip = clg_equips[0]
        
        clg_coil = nil
        if clg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
            hvac.HasForcedAir = true
            clg_coil = HVAC.get_coil_from_hvac_component(clg_equip.coolingCoil.get)
        elsif clg_equip.to_ZoneHVACComponent.is_initialized
            clg_coil = HVAC.get_coil_from_hvac_component(clg_equip.coolingCoil)
        else
            runner.registerError("Unexpected cooling equipment: #{clg_equip.name}.")
            return nil
        end
        
        # Cooling coil
        if clg_coil.is_a? OpenStudio::Model::CoilCoolingDXSingleSpeed
            hvac.NumSpeedsCooling = 1
            hvac.CapacityRatioCooling = [1.0]
            hvac.CoolingCFMs = [350.0] # FIXME; for Room AC
            curves = [clg_coil.totalCoolingCapacityFunctionOfTemperatureCurve]
            hvac.COOL_CAP_FT_SPEC_coefficients = get_2d_vector_from_CAP_FT_SPEC_curves(curves, hvac.NumSpeedsCooling)
            if not clg_coil.ratedSensibleHeatRatio.is_initialized
                runner.registerError("SHR not set for #{clg_coil.name}.")
                return nil
            end
            hvac.SHRRated = [clg_coil.ratedSensibleHeatRatio.get]
            if clg_coil.ratedTotalCoolingCapacity.is_initialized
                hvac.FixedCoolingCapacity = OpenStudio::convert(clg_coil.ratedTotalCoolingCapacity.get,"W","ton").get
            end
            
        elsif clg_coil.is_a? OpenStudio::Model::CoilCoolingDXMultiSpeed
            hvac.NumSpeedsCooling = clg_coil.stages.size
            if hvac.NumSpeedsCooling == 2
                hvac.CapacityRatioCooling = [0.71, 1.0] # FIXME
                hvac.OverSizeLimit = 1.2
            else
                hvac.CapacityRatioCooling = [0.36, 0.64, 1.0, 1.16] # FIXME
                hvac.OverSizeLimit = 1.3
            end
            curves = []
            hvac.SHRRated = []
            clg_coil.stages.each do |stage|
                curves << stage.totalCoolingCapacityFunctionofTemperatureCurve
                if not stage.grossRatedSensibleHeatRatio.is_initialized
                    runner.registerError("SHR not set for #{clg_coil.name}.")
                    return nil
                end
                hvac.SHRRated << stage.grossRatedSensibleHeatRatio.get
                if stage.grossRatedTotalCoolingCapacity.is_initialized
                    hvac.FixedCoolingCapacity = OpenStudio::convert(stage.grossRatedTotalCoolingCapacity.get,"W","ton").get # FIXME: Using last stage
                end
            end
            hvac.COOL_CAP_FT_SPEC_coefficients = get_2d_vector_from_CAP_FT_SPEC_curves(curves, hvac.NumSpeedsCooling)
            
        elsif clg_coil.is_a? OpenStudio::Model::CoilCoolingDXVariableRefrigerantFlow
            hvac.NumSpeedsCooling = Constants.Num_Speeds_MSHP # FIXME: Can we obtain from the object?
            hvac.CapacityRatioCooling = []
            for i in 1..hvac.NumSpeedsCooling
                hvac.CapacityRatioCooling << 0.4 + 0.122222222 * (i-1) # FIXME
            end
            hvac.OverSizeLimit = 1.3
            vrf = get_vrf_from_terminal_unit(model, clg_equip)
            curves = [vrf.coolingCapacityRatioModifierFunctionofLowTemperatureCurve.get]
            hvac.COOL_CAP_FT_SPEC_coefficients = get_2d_vector_from_CAP_FT_SPEC_curves(curves, hvac.NumSpeedsCooling)
            if not clg_coil.ratedSensibleHeatRatio.is_initialized
                runner.registerError("SHR not set for #{clg_coil.name}.")
                return nil
            end
            hvac.SHRRated = [0.896737099817, 0.814581591155, 0.762663646105, 0.726553338446, 0.699820222665,
                              0.679170768918, 0.662742694445, 0.649401104015, 0.638412246934, 0.629278372246] # FIXME
            hvac.CoolingCFMs = []
            for i in 1..hvac.NumSpeedsCooling
                hvac.CoolingCFMs << 200.0 + 200.0 / 8.0 * (i-1) # FIXME
            end
            
        elsif clg_coil.is_a? OpenStudio::Model::CoilCoolingWaterToAirHeatPumpEquationFit
            hvac.NumSpeedsCooling = 1
            hvac.CapacityRatioCooling = [1.0]
            hvac.COOL_CAP_FT_SPEC_coefficients = [[clg_coil.totalCoolingCapacityCoefficient1,
                                                   clg_coil.totalCoolingCapacityCoefficient2,
                                                   clg_coil.totalCoolingCapacityCoefficient3,
                                                   clg_coil.totalCoolingCapacityCoefficient4,
                                                   clg_coil.totalCoolingCapacityCoefficient5]] # FIXME: Probably not correct
            if not clg_coil.ratedTotalCoolingCapacity.is_initialized or not clg_coil.ratedSensibleCoolingCapacity.is_initialized
                runner.registerError("SHR not set for #{clg_coil.name}.")
                return nil
            end
            hvac.SHRRated = [clg_coil.ratedSensibleCoolingCapacity.get / clg_coil.ratedTotalCoolingCapacity.get]
            if clg_coil.ratedTotalCoolingCapacity.is_initialized
                hvac.FixedCoolingCapacity = OpenStudio::convert(clg_coil.ratedTotalCoolingCapacity.get,"W","ton").get
            end
            
        else
            runner.registerError("Unexpected cooling coil: #{clg_coil.name}.")
            return nil
        end
    end

    # Heating equipment
    if htg_equips.size > 0
        hvac.HasHeating = true
        
        if htg_equips.size == 2
            # If MSHP & Baseboard, remove Baseboard to allow this combination
            baseboard = OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric
            mshp = OpenStudio::Model::ZoneHVACTerminalUnitVariableRefrigerantFlow
            if htg_equips[0].is_a?(baseboard) and htg_equips[1].is_a?(mshp)
                htg_equips.delete_at(0)
            elsif htg_equips[0].is_a?(mshp) and htg_equips[1].is_a?(baseboard)
                htg_equips.delete_at(1)
            end
        end
        
        if htg_equips.size > 1
            runner.registerError("Cannot currently handle multiple heating equipment in a unit: #{htg_equips.to_s}.")
            htg_equips.each do |htg_equip|
                runner.registerError(htg_equip.name.to_s)
            end
            return nil
        end
        htg_equip = htg_equips[0]
        
        htg_coil = nil
        if htg_equip.is_a? OpenStudio::Model::AirLoopHVACUnitarySystem
            hvac.HasForcedAir = true
            htg_coil = HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil.get)
            if not htg_equip.maximumSupplyAirTemperature.is_initialized
                runner.registerError("Maximum supply air temperature not set for #{htg_equip.name}.")
                return nil
            end
            hvac.HtgSupplyAirTemp = OpenStudio::convert(htg_equip.maximumSupplyAirTemperature.get,"C","F").get # FIXME is this right?
            
        elsif htg_equip.to_ZoneHVACComponent.is_initialized
            if not htg_equip.is_a?(OpenStudio::Model::ZoneHVACBaseboardConvectiveElectric)
                htg_coil = HVAC.get_coil_from_hvac_component(htg_equip.heatingCoil)
            end
            hvac.HtgSupplyAirTemp = 105 # FIXME
            
        else
            runner.registerError("Unexpected heating equipment: #{htg_equip.name}.")
            return nil
            
        end
        
        # Heating coil
        if htg_coil.is_a? OpenStudio::Model::CoilHeatingElectric
            hvac.NumSpeedsHeating = 1
            if htg_coil.nominalCapacity.is_initialized
                hvac.FixedHeatingCapacity = OpenStudio::convert(htg_coil.nominalCapacity.get,"W","ton").get
            end
            
        elsif htg_coil.is_a? OpenStudio::Model::CoilHeatingGas
            hvac.NumSpeedsHeating = 1
            if htg_coil.nominalCapacity.is_initialized
                hvac.FixedHeatingCapacity = OpenStudio::convert(htg_coil.nominalCapacity.get,"W","ton").get
            end
            
        elsif htg_coil.is_a? OpenStudio::Model::CoilHeatingWaterBaseboard
            hvac.NumSpeedsHeating = 1
            if htg_coil.heatingDesignCapacity.is_initialized
                hvac.FixedHeatingCapacity = OpenStudio::convert(htg_coil.heatingDesignCapacity.get,"W","ton").get
            end
            
        elsif htg_coil.is_a? OpenStudio::Model::CoilHeatingDXSingleSpeed
            hvac.NumSpeedsHeating = 1
            hvac.CapacityRatioHeating = [1.0]
            hvac.MinOutdoorTemp = OpenStudio::convert(htg_coil.minimumOutdoorDryBulbTemperatureforCompressorOperation,"C","F").get
            curves = [htg_coil.totalHeatingCapacityFunctionofTemperatureCurve]
            hvac.HEAT_CAP_FT_SPEC_coefficients = get_2d_vector_from_CAP_FT_SPEC_curves(curves, hvac.NumSpeedsHeating)
            if htg_coil.ratedTotalHeatingCapacity.is_initialized
                hvac.FixedHeatingCapacity = OpenStudio::convert(htg_coil.ratedTotalHeatingCapacity.get,"W","ton").get
            end
            
        elsif htg_coil.is_a? OpenStudio::Model::CoilHeatingDXMultiSpeed
            hvac.NumSpeedsHeating = htg_coil.stages.size
            if hvac.NumSpeedsHeating == 2
                hvac.CapacityRatioHeating = [0.72, 1.0] # FIXME
            else
                hvac.CapacityRatioHeating = [0.49, 0.67, 1.0, 1.2] # FIXME
            end
            hvac.MinOutdoorTemp = OpenStudio::convert(htg_coil.minimumOutdoorDryBulbTemperatureforCompressorOperation,"C","F").get
            curves = []
            htg_coil.stages.each do |stage|
                curves << stage.heatingCapacityFunctionofTemperatureCurve
                if stage.grossRatedHeatingCapacity.is_initialized
                    hvac.FixedHeatingCapacity = OpenStudio::convert(stage.grossRatedHeatingCapacity.get,"W","ton").get # FIXME: Using last stage
                end
            end
            hvac.HEAT_CAP_FT_SPEC_coefficients = get_2d_vector_from_CAP_FT_SPEC_curves(curves, hvac.NumSpeedsHeating)
            
        elsif htg_coil.is_a? OpenStudio::Model::CoilHeatingDXVariableRefrigerantFlow
            hvac.NumSpeedsHeating = Constants.Num_Speeds_MSHP # FIXME: Can we obtain from the object?
            hvac.CapacityRatioHeating = []
            for i in 1..hvac.NumSpeedsHeating
                hvac.CapacityRatioHeating << 0.3 + 0.133333333 * (i-1) # FIXME
            end
            hvac.MinOutdoorTemp = OpenStudio::convert(vrf.minimumOutdoorTemperatureinHeatingMode,"C","F").get
            vrf = get_vrf_from_terminal_unit(model, htg_equip)
            curves = [vrf.heatingCapacityRatioModifierFunctionofLowTemperatureCurve.get]
            hvac.HEAT_CAP_FT_SPEC_coefficients = get_2d_vector_from_CAP_FT_SPEC_curves(curves, hvac.NumSpeedsHeating)
            if htg_coil.ratedTotalHeatingCapacity.is_initialized
                hvac.FixedHeatingCapacity = OpenStudio::convert(htg_coil.ratedTotalHeatingCapacity.get,"W","ton").get
            end
            hvac.HeatingCFMs = []
            for i in 1..hvac.NumSpeedsHeating
                hvac.HeatingCFMs << 200.0 + 200.0 / 9.0 * (i-1) # FIXME
            end
            
        elsif htg_coil.is_a? OpenStudio::Model::CoilHeatingWaterToAirHeatPumpEquationFit
            hvac.NumSpeedsHeating = 1
            hvac.CapacityRatioHeating = [1.0]
            hvac.HEAT_CAP_FT_SPEC_coefficients = [[htg_coil.totalHeatingCapacityCoefficient1,
                                                   htg_coil.totalHeatingCapacityCoefficient2,
                                                   htg_coil.totalHeatingCapacityCoefficient3,
                                                   htg_coil.totalHeatingCapacityCoefficient4,
                                                   htg_coil.totalHeatingCapacityCoefficient5]] # FIXME: Probably not correct
            if htg_coil.ratedHeatingCapacity.is_initialized
                hvac.FixedHeatingCapacity = OpenStudio::convert(htg_coil.ratedHeatingCapacity.get,"W","ton").get
            end
            
        elsif not htg_coil.nil?
            runner.registerError("Unexpected heating coil: #{htg_coil.name}.")
            return nil
            
        end
    end

    return hvac
  end
  
  def get_vrf_from_terminal_unit(model, tu)
    vrf = nil
    model.getAirConditionerVariableRefrigerantFlows.each do |acvrf|
        next if not acvrf.terminals.include?(tu)
        vrf = acvrf
    end
    return vrf
  end
  
  def get_2d_vector_from_CAP_FT_SPEC_curves(curves, num_speeds)
    vector = []
    curves.each do |curve|
        bi = curve.to_CurveBiquadratic.get
        c_si = [bi.coefficient1Constant, bi.coefficient2x, bi.coefficient3xPOW2, 
             bi.coefficient4y, bi.coefficient5yPOW2, bi.coefficient6xTIMESY]
        # Convert from SI coefficients to IP coefficients
        c_ip = []
        c_ip << c_si[0] - 160.0/9.0 * (c_si[1] + c_si[3]) + 25600.0/81.0 * (c_si[2] + c_si[4] + c_si[5])
        c_ip << 5.0/9.0 * (c_si[1] - 320.0/9.0 * c_si[2] - 160.0/9.0 * c_si[5])
        c_ip << 25.0/81.0 * c_si[2]
        c_ip << 5.0/9.0 * (c_si[3] - 320.0/9.0 * c_si[4] - 160.0/9.0 * c_si[5])
        c_ip << 25.0/81.0 * c_si[4]
        c_ip << 25.0/81.0 * c_si[5]
        vector << c_ip
    end
    if num_speeds > 1 and vector.size == 1
        # Repeat coefficients for each speed
        for i in 1..num_speeds
            vector << vector[0]
        end
    end
    return vector
  end
  
  def process_curve_fit(airFlowRate, capacity, temp, shr_biquadratic_coefficients)
    # TODO: Get rid of this curve by using ADP/BF calculations
    capacity_tons = OpenStudio::convert(capacity,"Btu/h","ton").get
    return MathTools.biquadratic(airFlowRate / capacity_tons, temp, shr_biquadratic_coefficients)
  end
  
  def true_azimuth(surface, northAxis)
    true_azimuth = nil
    facade = Geometry.get_facade_for_surface(surface)
    if facade == Constants.FacadeFront
        true_azimuth = northAxis
    elsif facade == Constants.FacadeBack
        true_azimuth = northAxis + 180
    elsif facade == Constants.FacadeLeft
        true_azimuth = northAxis + 90
    elsif facade == Constants.FacadeRight
        true_azimuth = northAxis + 270
    end
    if not true_azimuth.nil? and true_azimuth >= 360
        true_azimuth = true_azimuth - 360
    end
    return true_azimuth
  end
  
  def calculate_t_attic_iter(uA_roof, mdotCp_atticvent, t_solair, uA_atticfloor, cool_setpoint, coolingLoad_Ducts_Sens)
    # Calculate new value for Tattic based on updated duct losses
    t_attic_iter = (((uA_roof + mdotCp_atticvent) * t_solair + uA_atticfloor * cool_setpoint - coolingLoad_Ducts_Sens) /
                    (uA_atticfloor + uA_roof + mdotCp_atticvent))
    t_attic_iter = min(t_attic_iter, t_solair) # Prevent attic from being hotter than T_solair
    t_attic_iter = max(t_attic_iter, cool_setpoint) # Prevent attic from being colder than cool_setpoint
    return t_attic_iter
  end
  
  def calculate_t_solair(weather, roofAbsorptance, roofPitch)
    # Calculates Tsolair under design conditions
    # Uses equation (30) from 2009 ASHRAE Handbook-Fundamentals (IP), p 18.22:
    
    t_outdoor = weather.design.CoolingDrybulb # Design outdoor air temp (F)
    i_b = weather.design.CoolingDirectNormal
    i_d = weather.design.CoolingDiffuseHorizontal
    
    # Use max summer direct normal plus diffuse solar radiation, adjusted for roof pitch
    # (Not calculating max coincident i_b + i_d because that requires knowing roofPitch in advance; will typically coincide with peak i_b though.)
    i_T = OpenStudio::convert(i_b + i_d * (1 + Math::cos(roofPitch.deg2rad))/2,"W/m^2","Btu/ft^2*h") # total solar radiation incident on surface (Btu/h/ft2)
    # Adjust diffuse horizontal for roof pitch using isotropic diffuse model (Liu and Jordan 1963) from Duffie and Beckman eq 2.15.1
    
    h_o = 4 # coefficient of heat transfer for long-wave radiation and convection at outer surface (Btu/h-ft2-F)
            # Value of 4.0 for 7.5 mph wind (summer design) from 2009 ASHRAE H-F (IP) p 26.1
            # p 18.22 assumes h_o = 3.0 Btu/hft2F for horizontal surfaces, but we found 4.0 gives 
            # more realistic sol air temperatures and is more realistic for residential roofs. 
    
    emittance = 1.0 # hemispherical emittance of surface = 1 for horizontal surface, from 2009 ASHRAE H-F (IP) p 18.22
    
    deltaR = 20 # difference between long-wave radiation incident on surface from sky and surroundings
                # and radiation emitted by blackbody at outdoor air temperature
                # 20 Btu/h-ft2 appropriate for horizontal surfaces, from ASHRAE H-F (IP) p 18.22
                
    deltaR_inclined = deltaR * Math::cos(roofPitch.deg2rad) # Corrent deltaR for inclined surface,
    # from eq. 2.32 in  Castelino, R.L. 1992. "Implementation of the Revised Transfer Function Method and Evaluation of the CLTD/SCL/CLF Method" (Thesis) Oklahoma State University 
    
    t_solair = t_outdoor + (roofAbsorptance * i_T - emittance * deltaR_inclined) / h_o
    return t_solair
  end
  
  def display_zone_loads(runner, unit_num, zone_loads)
    zone_loads.keys.each do |thermal_zone|
        loads = zone_loads[thermal_zone]
        s = "Unit #{unit_num.to_s} Zone Loads for #{thermal_zone.name.to_s}:"
        properties = [
                      :Heat_Windows, :Heat_Doors,
                      :Heat_Walls, :Heat_Roofs,
                      :Heat_Floors, :Heat_Infil,
                      :Cool_Windows, :Cool_Doors, 
                      :Cool_Walls, :Cool_Roofs, 
                      :Cool_Floors, :Cool_Infil_Sens, 
                      :Cool_Infil_Lat, :Cool_IntGains_Sens, 
                      :Cool_IntGains_Lat, :Dehumid_Windows, 
                      :Dehumid_Doors, :Dehumid_Walls,
                      :Dehumid_Roofs, :Dehumid_Floors,
                      :Dehumid_Infil_Sens, :Dehumid_Infil_Lat,
                      :Dehumid_IntGains_Sens, :Dehumid_IntGains_Lat,
                     ]
        properties.each do |property|
            s += "\n#{property.to_s.gsub("_"," ")} = #{loads.send(property).round(0).to_s}" # FIXME: Btu/hr"
        end
        runner.registerInfo("#{s}\n")
    end
  end
  
  def display_unit_initial_results(runner, unit_num, unit_init)
    s = "Unit #{unit_num.to_s} Initial Results (w/o ducts):"
    loads = [
             :Heat_Load, :Cool_Load_Sens, :Cool_Load_Lat, 
             :Dehumid_Load_Sens, :Dehumid_Load_Lat,
            ]
    airflows = [
                :Heat_Airflow, :Cool_Airflow, 
               ]
    loads.each do |load|
        s += "\n#{load.to_s.gsub("_"," ")} = #{unit_init.send(load).round(0).to_s}" # FIXME: Btu/hr"
    end
    airflows.each do |airflow|
        s += "\n#{airflow.to_s.gsub("_"," ")} = #{unit_init.send(airflow).round(0).to_s}" # FIXME: cfm"
    end
    runner.registerInfo("#{s}\n")
  end
                  
  def display_unit_final_results(runner, unit_num, unit_final)
    s = "Unit #{unit_num.to_s} Final Results:"
    loads = [
             :Heat_Load, :Heat_Load_Ducts,
             :Cool_Load_Lat, :Cool_Load_Sens,
             :Cool_Load_Ducts_Lat, :Cool_Load_Ducts_Sens,
             :Dehumid_Load_Sens, :Dehumid_Load_Ducts_Lat,
            ]
    caps = [
             :Cool_Capacity, :Cool_Capacity_Sens,
             :Heat_Capacity, :Heat_Capacity_Supp,
            ]
    airflows = [
                :Cool_Airflow, :Heat_Airflow, :Fan_Airflow,
               ]
    waters = [
              :Dehumid_WaterRemoval,
             ]
    loads.each do |load|
        s += "\n#{load.to_s.gsub("_"," ")} = #{unit_final.send(load).round(0).to_s}"# FIXME: Btu/hr"
    end
    caps.each do |cap|
        s += "\n#{cap.to_s.gsub("_"," ")} = #{unit_final.send(cap).round(0).to_s}" # FIXME: Btu/hr"
    end
    airflows.each do |airflow|
        s += "\n#{airflow.to_s.gsub("_"," ")} = #{unit_final.send(airflow).round(0).to_s}" # FIXME: cfm"
    end
    waters.each do |water|
        s += "\n#{water.to_s.gsub("_"," ")} = #{unit_final.send(water).round(0).to_s}" # FIXME: L/day"
    end
    runner.registerInfo("#{s}\n")
  end
  
end #end the measure

class Numeric
  def deg2rad
    self * Math::PI / 180 
  end
  def rad2deg
    self * 180 / Math::PI 
  end
end

#this allows the measure to be use by the application
ProcessHVACSizing.new.registerWithApplication