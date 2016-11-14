# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/psychrometrics"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/hvac"

# start the measure
class ResidentialAirflow < OpenStudio::Ruleset::ModelUserScript

  class Ducts
    def initialize(ductTotalLeakage, ductNormLeakageToOutside, ductSupplySurfaceAreaMultiplier, ductReturnSurfaceAreaMultiplier, ductUnconditionedRvalue, ductSupplyLeakageFractionOfTotal, ductReturnLeakageFractionOfTotal, ductAHSupplyLeakageFractionOfTotal, ductAHReturnLeakageFractionOfTotal)
      @ductTotalLeakage = ductTotalLeakage
      @ductNormLeakageToOutside = ductNormLeakageToOutside
      @ductSupplySurfaceAreaMultiplier = ductSupplySurfaceAreaMultiplier
      @ductReturnSurfaceAreaMultiplier = ductReturnSurfaceAreaMultiplier
      @ductUnconditionedRvalue = ductUnconditionedRvalue
      @ductSupplyLeakageFractionOfTotal = ductSupplyLeakageFractionOfTotal
      @ductReturnLeakageFractionOfTotal = ductReturnLeakageFractionOfTotal
      @ductAHSupplyLeakageFractionOfTotal = ductAHSupplyLeakageFractionOfTotal
      @ductAHReturnLeakageFractionOfTotal = ductAHReturnLeakageFractionOfTotal
    end
    
    attr_accessor(:duct_location_zone, :duct_location_name, :has_ducts, :ducts_not_in_living, :num_stories, :num_stories_for_ducts, :DuctLocationFrac, :DuctLocationFracLeakage, :DuctLocationFracConduction, :DuctSupplyLeakageFractionOfTotal, :DuctReturnLeakageFractionOfTotal, :DuctAHSupplyLeakageFractionOfTotal, :DuctAHReturnLeakageFractionOfTotal, :DuctSupplyLeakage, :DuctReturnLeakage, :DuctAHSupplyLeakage, :DuctAHReturnLeakage, :DuctNumReturns, :supply_duct_surface_area, :return_duct_surface_area, :unconditioned_duct_area, :supply_duct_r, :return_duct_r, :unconditioned_duct_ua, :return_duct_ua, :supply_duct_volume, :return_duct_volume, :direct_oa_supply_duct_loss, :supply_duct_loss, :return_duct_loss, :supply_leak_oper, :return_leak_oper, :ah_supply_leak_oper, :ah_return_leak_oper, :total_duct_unbalance, :frac_oa, :oa_duct_makeup)
    
    def DuctTotalLeakage
      return @ductTotalLeakage
    end
    
    def DuctNormLeakageToOutside
      return @ductNormLeakageToOutside
    end
    
    def DuctSupplySurfaceAreaMultiplier
      return @ductSupplySurfaceAreaMultiplier
    end
    
    def DuctReturnSurfaceAreaMultiplier
      return @ductReturnSurfaceAreaMultiplier
    end
    
    def DuctUnconditionedRvalue
      return @ductUnconditionedRvalue
    end
    
    def DuctSupplyLeakageFractionOfTotal
      return @ductSupplyLeakageFractionOfTotal
    end
    
    def DuctReturnLeakageFractionOfTotal
      return @ductReturnLeakageFractionOfTotal
    end
    
    def DuctAHSupplyLeakageFractionOfTotal
      return @ductAHSupplyLeakageFractionOfTotal
    end
    
    def DuctAHReturnLeakageFractionOfTotal
      return @ductAHReturnLeakageFractionOfTotal
    end
    
  end

  class Infiltration
    def initialize(infiltrationLivingSpaceACH50, infiltrationShelterCoefficient, infiltrationGarageACH50)
      @infiltrationLivingSpaceACH50 = infiltrationLivingSpaceACH50
      @infiltrationShelterCoefficient = infiltrationShelterCoefficient
      @infiltrationGarageACH50 = infiltrationGarageACH50
    end

    attr_accessor(:assumed_inside_temp, :n_i, :A_o, :C_i, :Y_i, :flue_height, :S_wflue, :R_i, :X_i, :Z_f, :M_o, :M_i, :X_c, :F_i, :f_s, :stack_coef, :R_x, :Y_x, :X_s, :X_x, :f_w, :J_i, :f_w, :wind_coef, :default_rate, :rate_credit)

    def InfiltrationLivingSpaceACH50
      return @infiltrationLivingSpaceACH50
    end

    def InfiltrationShelterCoefficient
      return @infiltrationShelterCoefficient
    end

    def InfiltrationGarageACH50
      return @infiltrationGarageACH50
    end

  end

  class LivingSpace
    def initialize(height, area, volume, coord_z)
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z    
    end
    attr_accessor(:height, :area, :volume, :coord_z, :inf_method, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class Garage
    def initialize(height, area, volume, coord_z)
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z       
    end
    attr_accessor(:height, :area, :volume, :coord_z, :inf_method, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class FinBasement
    def initialize(ach, height, area, volume, coord_z)
      @ACH = ach      
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z
    end
    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class UnfinBasement
    def initialize(ach, height, area, volume, coord_z)
      @ACH = ach      
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z      
    end
    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class Crawl
    def initialize(ach, height, area, volume, coord_z)
      @ACH = ach    
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z      
    end
    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class UnfinAttic
    def initialize(sla, height, area, volume, coord_z)
      @SLA = sla
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z      
    end
    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class WindSpeed
    def initialize
    end
    attr_accessor(:height, :terrain_multiplier, :terrain_exponent, :ashrae_terrain_thickness, :ashrae_terrain_exponent, :site_terrain_multiplier, :site_terrain_exponent, :ashrae_site_terrain_thickness, :ashrae_site_terrain_exponent, :S_wo, :shielding_coef)
  end

  class MechanicalVentilation
    def initialize(mechVentType, mechVentInfilCredit, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower, mechVentSensibleEfficiency, mechVentASHRAEStandard)
      @mechVentType = mechVentType
      @mechVentInfilCredit = mechVentInfilCredit
      @mechVentTotalEfficiency = mechVentTotalEfficiency
      @mechVentFractionOfASHRAE = mechVentFractionOfASHRAE
      @mechVentHouseFanPower = mechVentHouseFanPower
      @mechVentSensibleEfficiency = mechVentSensibleEfficiency
	  @mechVentASHRAEStandard = mechVentASHRAEStandard
    end

    attr_accessor(:MechVentBathroomExhaust, :MechVentRangeHoodExhaust, :MechVentSpotFanPower, :bath_exhaust_operation, :range_hood_exhaust_operation, :clothes_dryer_exhaust_operation, :ashrae_vent_rate, :num_vent_fans, :percent_fan_heat_to_space, :whole_house_vent_rate, :bathroom_hour_avg_exhaust, :range_hood_hour_avg_exhaust, :clothes_dryer_hour_avg_exhaust, :max_power, :base_vent_rate, :max_vent_rate, :MechVentApparentSensibleEffectiveness, :MechVentHXCoreSensibleEffectiveness, :MechVentLatentEffectiveness, :hourly_energy_schedule, :hourly_schedule, :average_vent_fan_eff)

    def MechVentType
      return @mechVentType
    end

    def MechVentInfilCredit
      return @mechVentInfilCredit
    end

    def MechVentTotalEfficiency
      return @mechVentTotalEfficiency
    end

    def MechVentFractionOfASHRAE
      return @mechVentFractionOfASHRAE
    end

    def MechVentHouseFanPower
      return @mechVentHouseFanPower
    end

    def MechVentSensibleEfficiency
      return @mechVentSensibleEfficiency
    end
	
    def MechVentASHRAEStandard
      return @mechVentASHRAEStandard
    end
  end

  class Building
    def initialize
    end
    attr_accessor(:finished_floor_area, :above_grade_finished_floor_area, :building_height, :stories, :num_units, :above_grade_volume, :above_grade_exterior_wall_area, :SLA, :garage_zone, :garage, :unfinished_basement_zone, :unfinished_basement, :crawlspace_zone, :crawlspace, :unfinished_attic_zone, :unfinished_attic)    
  end
  
  class Unit
    def initialize
    end    
    attr_accessor(:unit_num, :num_bedrooms, :num_bathrooms, :age_of_home, :above_grade_exterior_wall_area, :above_grade_finished_floor_area, :finished_floor_area, :dryer_exhaust, :window_area, :living_zone, :living, :finished_basement_zone, :finished_basement)
  end  

  class NaturalVentilation
    def initialize(natVentHtgSsnSetpointOffset, natVentClgSsnSetpointOffset, natVentOvlpSsnSetpointOffset, natVentHeatingSeason, natVentCoolingSeason, natVentOverlapSeason, natVentNumberWeekdays, natVentNumberWeekendDays, natVentFractionWindowsOpen, natVentFractionWindowAreaOpen, natVentMaxOAHumidityRatio, natVentMaxOARelativeHumidity)
      @natVentHtgSsnSetpointOffset = natVentHtgSsnSetpointOffset
      @natVentClgSsnSetpointOffset = natVentClgSsnSetpointOffset
      @natVentOvlpSsnSetpointOffset = natVentOvlpSsnSetpointOffset
      @natVentHeatingSeason = natVentHeatingSeason
      @natVentCoolingSeason = natVentCoolingSeason
      @natVentOverlapSeason = natVentOverlapSeason
      @natVentNumberWeekdays = natVentNumberWeekdays
      @natVentNumberWeekendDays = natVentNumberWeekendDays
      @natVentFractionWindowsOpen = natVentFractionWindowsOpen
      @natVentFractionWindowAreaOpen = natVentFractionWindowAreaOpen
      @natVentMaxOAHumidityRatio = natVentMaxOAHumidityRatio
      @natVentMaxOARelativeHumidity = natVentMaxOARelativeHumidity
    end

    attr_accessor(:htg_ssn_hourly_temp, :htg_ssn_hourly_weekend_temp, :clg_ssn_hourly_temp, :clg_ssn_hourly_weekend_temp, :ovlp_ssn_hourly_temp, :ovlp_ssn_hourly_weekend_temp, :season_type, :area, :max_rate, :max_flow_rate, :hor_vent_frac, :C_s, :C_w)

    def NatVentHtgSsnSetpointOffset
      return @natVentHtgSsnSetpointOffset
    end

    def NatVentClgSsnSetpointOffset
      return @natVentClgSsnSetpointOffset
    end

    def NatVentOvlpSsnSetpointOffset
      return @natVentOvlpSsnSetpointOffset
    end

    def NatVentHeatingSeason
      return @natVentHeatingSeason
    end

    def NatVentCoolingSeason
      return @natVentCoolingSeason
    end

    def NatVentOverlapSeason
      return @natVentOverlapSeason
    end

    def NatVentNumberWeekdays
      return @natVentNumberWeekdays
    end

    def NatVentNumberWeekendDays
      return @natVentNumberWeekendDays
    end

    def NatVentFractionWindowsOpen
      return @natVentFractionWindowsOpen
    end

    def NatVentFractionWindowAreaOpen
      return @natVentFractionWindowAreaOpen
    end

    def NatVentMaxOAHumidityRatio
      return @natVentMaxOAHumidityRatio
    end

    def NatVentMaxOARelativeHumidity
      return @natVentMaxOARelativeHumidity
    end
  end

  class Schedules
    def initialize
    end
    attr_accessor(:MechanicalVentilationEnergy, :MechanicalVentilation, :BathExhaust, :ClothesDryerExhaust, :RangeHood, :NatVentProbability, :NatVentAvailability, :NatVentTemp)
  end

  # human readable name
  def name
    return "Set Residential Airflow"
  end

  # human readable description
  def description
    return "Sets (or replaces) all building components related to airflow: infiltration, mechanical ventilation, natural ventilation, and ducts."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Uses EMS to model the building airflow."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #make a double argument for infiltration of living space
    living_ach50 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("living_ach50", false)
    living_ach50.setDisplayName("Air Leakage: Above-Grade Living Space ACH50")
    living_ach50.setUnits("1/hr")
    living_ach50.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for above-grade living space (including finished attic).")
    living_ach50.setDefaultValue(7)
    args << living_ach50

    #make a double argument for infiltration of garage
    garage_ach50 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("garage_ach50", false)
    garage_ach50.setDisplayName("Garage: ACH50")
    garage_ach50.setUnits("1/hr")
    garage_ach50.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for the garage.")
    garage_ach50.setDefaultValue(7)
    args << garage_ach50

    #make a double argument for infiltration of finished basement
    finished_basement_ach = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("finished_basement_ach", false)
    finished_basement_ach.setDisplayName("Finished Basement: Constant ACH")
    finished_basement_ach.setUnits("1/hr")
    finished_basement_ach.setDescription("Constant air exchange rate, in Air Changes per Hour (ACH), for the finished basement.")
    finished_basement_ach.setDefaultValue(0.0)
    args << finished_basement_ach
	
    #make a double argument for infiltration of unfinished basement
    unfinished_basement_ach = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("unfinished_basement_ach", false)
    unfinished_basement_ach.setDisplayName("Unfinished Basement: Constant ACH")
    unfinished_basement_ach.setUnits("1/hr")
    unfinished_basement_ach.setDescription("Constant air exchange rate, in Air Changes per Hour (ACH), for the unfinished basement. A value of 0.10 ACH or greater is recommended for modeling Heat Pump Water Heaters in unfinished basements.")
    unfinished_basement_ach.setDefaultValue(0.1)
    args << unfinished_basement_ach
	
    #make a double argument for infiltration of crawlspace
    crawl_ach = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("crawl_ach", false)
    crawl_ach.setDisplayName("Crawlspace: Constant ACH")
    crawl_ach.setUnits("1/hr")
    crawl_ach.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for the crawlspace.")
    crawl_ach.setDefaultValue(0.0)
    args << crawl_ach

    #make a double argument for infiltration of unfinished attic
    unfinished_attic_ach = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("unfinished_attic_ach", false)
    unfinished_attic_ach.setDisplayName("Unfinished Attic: SLA")
    unfinished_attic_ach.setDescription("Ratio of the effective leakage area (infiltration and/or ventilation) in the unfinished attic to the total floor area of the attic.")
    unfinished_attic_ach.setDefaultValue(0.00333)
    args << unfinished_attic_ach

    #make a double argument for shelter coefficient
    shelter_coef = OpenStudio::Ruleset::OSArgument::makeStringArgument("shelter_coef", false)
    shelter_coef.setDisplayName("Air Leakage: Shelter Coefficient")
    shelter_coef.setDescription("The local shelter coefficient (AIM-2 infiltration model) accounts for nearby buildings, trees and obstructions.")
    shelter_coef.setDefaultValue("auto")
    args << shelter_coef
    
    #make a double argument for open flue
    has_flue = OpenStudio::Ruleset::OSArgument::makeBoolArgument("has_flue", false)
    has_flue.setDisplayName("Air Leakage: Has Open Flue")
    has_flue.setDescription("Specifies whether the building has an open flue or chimney (e.g., for a furnace, boiler, water heater, or fireplace).")
    has_flue.setDefaultValue(true)
    args << has_flue    

    #make a double argument for existing or new construction
    age_of_home = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("age_of_home", true)
    age_of_home.setDisplayName("Age of Home")
    age_of_home.setUnits("yrs")
    age_of_home.setDescription("Age of home [Enter 0 for New Construction].")
    age_of_home.setDefaultValue(0)
    args << age_of_home

    #make a choice arguments for terrain type
    terrain_types_names = OpenStudio::StringVector.new
    terrain_types_names << Constants.TerrainOcean
    terrain_types_names << Constants.TerrainPlains
    terrain_types_names << Constants.TerrainRural
    terrain_types_names << Constants.TerrainSuburban
    terrain_types_names << Constants.TerrainCity
    terrain = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("terrain", terrain_types_names, true)
    terrain.setDisplayName("Site Terrain")
    terrain.setDescription("The terrain of the site.")
    terrain.setDefaultValue(Constants.TerrainSuburban)
    args << terrain

    #make a choice argument for ventilation type
    ventilation_types_names = OpenStudio::StringVector.new
    ventilation_types_names << "none"
    ventilation_types_names << Constants.VentTypeExhaust
    ventilation_types_names << Constants.VentTypeSupply
    ventilation_types_names << Constants.VentTypeBalanced
    mech_vent_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("mech_vent_type", ventilation_types_names, false)
    mech_vent_type.setDisplayName("Mechanical Ventilation: Ventilation Type")
    mech_vent_type.setDefaultValue(Constants.VentTypeExhaust)
    args << mech_vent_type

    #make a bool argument for infiltration credit
    mech_vent_infil_credit = OpenStudio::Ruleset::OSArgument::makeBoolArgument("mech_vent_infil_credit",false)
    mech_vent_infil_credit.setDisplayName("Mechanical Ventilation: Allow Infiltration Credit")
    mech_vent_infil_credit.setDescription("Defines whether the infiltration credit allowed per the ASHRAE 62.2 Standard will be included in the calculation of the mechanical ventilation rate. If True, the infiltration credit will apply 1) to new/existing single-family detached homes for 2013 ASHRAE 62.2, or 2) to existing single-family detached or multi-family homes for 2010 ASHRAE 62.2.")
    mech_vent_infil_credit.setDefaultValue(true)
    args << mech_vent_infil_credit

    #make a double argument for total efficiency
    mech_vent_total_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mech_vent_total_efficiency",false)
    mech_vent_total_efficiency.setDisplayName("Mechanical Ventilation: Total Recovery Efficiency")
    mech_vent_total_efficiency.setDescription("The net total energy (sensible plus latent, also called enthalpy) recovered by the supply airstream adjusted by electric consumption, case heat loss or heat gain, air leakage and airflow mass imbalance between the two airstreams, as a percent of the potential total energy that could be recovered plus the exhaust fan energy.")
    mech_vent_total_efficiency.setDefaultValue(0)
    args << mech_vent_total_efficiency

    #make a double argument for sensible efficiency
    mech_vent_sensible_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mech_vent_sensible_efficiency",false)
    mech_vent_sensible_efficiency.setDisplayName("Mechanical Ventilation: Sensible Recovery Efficiency")
    mech_vent_sensible_efficiency.setDescription("The net sensible energy recovered by the supply airstream as adjusted by electric consumption, case heat loss or heat gain, air leakage, airflow mass imbalance between the two airstreams and the energy used for defrost (when running the Very Low Temperature Test), as a percent of the potential sensible energy that could be recovered plus the exhaust fan energy.")
    mech_vent_sensible_efficiency.setDefaultValue(0)
    args << mech_vent_sensible_efficiency

    #make a double argument for house fan power
    mech_vent_fan_power = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mech_vent_fan_power",false)
    mech_vent_fan_power.setDisplayName("Mechanical Ventilation: Fan Power")
    mech_vent_fan_power.setUnits("W/cfm")
    mech_vent_fan_power.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of fan(s) providing whole house ventilation. If the house uses a balanced ventilation system there is assumed to be two fans operating at this efficiency.")
    mech_vent_fan_power.setDefaultValue(0.3)
    args << mech_vent_fan_power

    #make a double argument for fraction of ashrae
    mech_vent_frac_62_2 = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("mech_vent_frac_62_2",false)
    mech_vent_frac_62_2.setDisplayName("Mechanical Ventilation: Fraction of ASHRAE 62.2")
    mech_vent_frac_62_2.setUnits("frac")
    mech_vent_frac_62_2.setDescription("Fraction of the ventilation rate (including any infiltration credit) specified by ASHRAE 62.2 that is desired in the building.")
    mech_vent_frac_62_2.setDefaultValue(1.0)
    args << mech_vent_frac_62_2

    #make a choice argument for ashrae standard
    standard_types_names = OpenStudio::StringVector.new
    standard_types_names << "2010"
    standard_types_names << "2013"
	
    #make a double argument for ashrae standard
    mech_vent_ashrae_std = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("mech_vent_ashrae_std", standard_types_names, false)
    mech_vent_ashrae_std.setDisplayName("Mechanical Ventilation: ASHRAE 62.2 Standard")
    mech_vent_ashrae_std.setDescription("Specifies which version (year) of the ASHRAE 62.2 Standard should be used.")
    mech_vent_ashrae_std.setDefaultValue("2010")
    args << mech_vent_ashrae_std	

    #make a double argument for dryer exhaust
    clothes_dryer_exhaust = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("clothes_dryer_exhaust",false)
    clothes_dryer_exhaust.setDisplayName("Clothes Dryer: Exhaust")
    clothes_dryer_exhaust.setUnits("cfm")
    clothes_dryer_exhaust.setDescription("Rated flow capacity of the clothes dryer exhaust. This fan is assumed to run 60 min/day between 11am and 12pm.")
    clothes_dryer_exhaust.setDefaultValue(100.0)
    args << clothes_dryer_exhaust

    #make a double argument for heating season setpoint offset
    nat_vent_htg_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nat_vent_htg_offset",false)
    nat_vent_htg_offset.setDisplayName("Natural Ventilation: Heating Season Setpoint Offset")
    nat_vent_htg_offset.setUnits("degrees F")
    nat_vent_htg_offset.setDescription("The temperature offset below the hourly cooling setpoint, to which the living space is allowed to cool during months that are only in the heating season.")
    nat_vent_htg_offset.setDefaultValue(1.0)
    args << nat_vent_htg_offset

    #make a double argument for cooling season setpoint offset
    nat_vent_clg_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nat_vent_clg_offset",false)
    nat_vent_clg_offset.setDisplayName("Natural Ventilation: Cooling Season Setpoint Offset")
    nat_vent_clg_offset.setUnits("degrees F")
    nat_vent_clg_offset.setDescription("The temperature offset above the hourly heating setpoint, to which the living space is allowed to cool during months that are only in the cooling season.")
    nat_vent_clg_offset.setDefaultValue(1.0)
    args << nat_vent_clg_offset

    #make a double argument for overlap season setpoint offset
    nat_vent_ovlp_offset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nat_vent_ovlp_offset",false)
    nat_vent_ovlp_offset.setDisplayName("Natural Ventilation: Overlap Season Setpoint Offset")
    nat_vent_ovlp_offset.setUnits("degrees F")
    nat_vent_ovlp_offset.setDescription("The temperature offset above the maximum heating setpoint, to which the living space is allowed to cool during months that are in both the heating season and cooling season.")
    nat_vent_ovlp_offset.setDefaultValue(1.0)
    args << nat_vent_ovlp_offset

    #make a bool argument for heating season
    nat_vent_htg_season = OpenStudio::Ruleset::OSArgument::makeBoolArgument("nat_vent_htg_season",false)
    nat_vent_htg_season.setDisplayName("Natural Ventilation: Heating Season")
    nat_vent_htg_season.setDescription("True if windows are allowed to be opened during months that are only in the heating season.")
    nat_vent_htg_season.setDefaultValue(true)
    args << nat_vent_htg_season

    #make a bool argument for cooling season
    nat_vent_clg_season = OpenStudio::Ruleset::OSArgument::makeBoolArgument("nat_vent_clg_season",false)
    nat_vent_clg_season.setDisplayName("Natural Ventilation: Cooling Season")
    nat_vent_clg_season.setDescription("True if windows are allowed to be opened during months that are only in the cooling season.")
    nat_vent_clg_season.setDefaultValue(true)
    args << nat_vent_clg_season

    #make a bool argument for overlap season
    nat_vent_ovlp_season = OpenStudio::Ruleset::OSArgument::makeBoolArgument("nat_vent_ovlp_season",false)
    nat_vent_ovlp_season.setDisplayName("Natural Ventilation: Overlap Season")
    nat_vent_ovlp_season.setDescription("True if windows are allowed to be opened during months that are in both the heating season and cooling season.")
    nat_vent_ovlp_season.setDefaultValue(true)
    args << nat_vent_ovlp_season

    #make a double argument for number weekdays
    nat_vent_num_weekdays = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("nat_vent_num_weekdays",false)
    nat_vent_num_weekdays.setDisplayName("Natural Ventilation: Number Weekdays")
    nat_vent_num_weekdays.setDescription("Number of weekdays in the week that natural ventilation can occur.")
    nat_vent_num_weekdays.setDefaultValue(3)
    args << nat_vent_num_weekdays

    #make a double argument for number weekend days
    nat_vent_num_weekends = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("nat_vent_num_weekends",false)
    nat_vent_num_weekends.setDisplayName("Natural Ventilation: Number Weekend Days")
    nat_vent_num_weekends.setDescription("Number of weekend days in the week that natural ventilation can occur.")
    nat_vent_num_weekends.setDefaultValue(0)
    args << nat_vent_num_weekends

    #make a double argument for fraction of windows open
    nat_vent_frac_windows_open = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nat_vent_frac_windows_open",false)
    nat_vent_frac_windows_open.setDisplayName("Natural Ventilation: Fraction of Openable Windows Open")
    nat_vent_frac_windows_open.setUnits("frac")
    nat_vent_frac_windows_open.setDescription("Specifies the fraction of the total openable window area in the building that is opened for ventilation.")
    nat_vent_frac_windows_open.setDefaultValue(0.33)
    args << nat_vent_frac_windows_open

    #make a double argument for fraction of window area open
    nat_vent_frac_window_area_openable = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nat_vent_frac_window_area_openable",false)
    nat_vent_frac_window_area_openable.setDisplayName("Natural Ventilation: Fraction Window Area Openable")
    nat_vent_frac_window_area_openable.setUnits("frac")
    nat_vent_frac_window_area_openable.setDescription("Specifies the fraction of total window area in the home that can be opened (e.g. typical sliding windows can be opened to half of their area).")
    nat_vent_frac_window_area_openable.setDefaultValue(0.2)
    args << nat_vent_frac_window_area_openable

    #make a double argument for humidity ratio
    nat_vent_max_oa_hr = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nat_vent_max_oa_hr",false)
    nat_vent_max_oa_hr.setDisplayName("Natural Ventilation: Max OA Humidity Ratio")
    nat_vent_max_oa_hr.setUnits("frac")
    nat_vent_max_oa_hr.setDescription("Outdoor air humidity ratio above which windows will not open for natural ventilation.")
    nat_vent_max_oa_hr.setDefaultValue(0.0115)
    args << nat_vent_max_oa_hr

    #make a double argument for relative humidity ratio
    nat_vent_max_oa_rh = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nat_vent_max_oa_rh",false)
    nat_vent_max_oa_rh.setDisplayName("Natural Ventilation: Max OA Relative Humidity")
    nat_vent_max_oa_rh.setUnits("frac")
    nat_vent_max_oa_rh.setDescription("Outdoor air relative humidity (0-1) above which windows will not open for natural ventilation.")
    nat_vent_max_oa_rh.setDefaultValue(0.7)
    args << nat_vent_max_oa_rh
	
    #make a choice arguments for duct location
    duct_locations = OpenStudio::StringVector.new
    duct_locations << "none"
    duct_locations << Constants.Auto
    duct_locations << Constants.LivingZone
    duct_locations << Constants.AtticZone
    duct_locations << Constants.BasementZone
    duct_locations << Constants.GarageZone
    duct_location = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("duct_location", duct_locations, true)
    duct_location.setDisplayName("Ducts: Location")
    duct_location.setDescription("The space with the primary location of ducts.")
    duct_location.setDefaultValue(Constants.Auto)
    args << duct_location
    
    #make a double argument for total leakage
    duct_total_leakage = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_total_leakage", false)
    duct_total_leakage.setDisplayName("Ducts: Total Leakage")
    duct_total_leakage.setUnits("frac")
    duct_total_leakage.setDescription("The total amount of air flow leakage expressed as a fraction of the total air flow rate.")
    duct_total_leakage.setDefaultValue(0.3)
    args << duct_total_leakage

    #make a double argument for supply leakage fraction of total
    duct_supply_frac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_supply_frac", false)
    duct_supply_frac.setDisplayName("Ducts: Supply Leakage Fraction of Total")
    duct_supply_frac.setUnits("frac")
    duct_supply_frac.setDescription("The amount of air flow leakage leaking out from the supply duct expressed as a fraction of the total duct leakage.")
    duct_supply_frac.setDefaultValue(0.6)
    args << duct_supply_frac

    #make a double argument for return leakage fraction of total
    duct_return_frac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_return_frac", false)
    duct_return_frac.setDisplayName("Ducts: Return Leakage Fraction of Total")
    duct_return_frac.setUnits("frac")
    duct_return_frac.setDescription("The amount of air flow leakage leaking into the return duct expressed as a fraction of the total duct leakage.")
    duct_return_frac.setDefaultValue(0.067)
    args << duct_return_frac  

    #make a double argument for supply AH leakage fraction of total
    duct_ah_supply_frac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_ah_supply_frac", false)
    duct_ah_supply_frac.setDisplayName("Ducts: Supply Air Handler Leakage Fraction of Total")
    duct_ah_supply_frac.setUnits("frac")
    duct_ah_supply_frac.setDescription("The amount of air flow leakage leaking out from the supply-side of the air handler expressed as a fraction of the total duct leakage.")
    duct_ah_supply_frac.setDefaultValue(0.067)
    args << duct_ah_supply_frac  

    #make a double argument for return AH leakage fraction of total
    duct_ah_return_frac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_ah_return_frac", false)
    duct_ah_return_frac.setDisplayName("Ducts: Return Air Handler Leakage Fraction of Total")
    duct_ah_return_frac.setUnits("frac")
    duct_ah_return_frac.setDescription("The amount of air flow leakage leaking out from the return-side of the air handler expressed as a fraction of the total duct leakage.")
    duct_ah_return_frac.setDefaultValue(0.267)
    args << duct_ah_return_frac
    
    #make a string argument for norm leakage to outside
    duct_norm_leakage_25pa = OpenStudio::Ruleset::OSArgument::makeStringArgument("duct_norm_leakage_25pa", false)
    duct_norm_leakage_25pa.setDisplayName("Ducts: Leakage to Outside at 25Pa")
    duct_norm_leakage_25pa.setUnits("cfm/100 ft^2")
    duct_norm_leakage_25pa.setDescription("Normalized leakage to the outside when tested at a pressure differential of 25 Pascals (0.1 inches w.g.) across the system.")
    duct_norm_leakage_25pa.setDefaultValue("NA")
    args << duct_norm_leakage_25pa
    
    #make a string argument for duct location frac    
    duct_location_frac = OpenStudio::Ruleset::OSArgument::makeStringArgument("duct_location_frac", true)
    duct_location_frac.setDisplayName("Ducts: Location Fraction")
    duct_location_frac.setUnits("frac")
    duct_location_frac.setDescription("Fraction of supply ducts in the space specified by Duct Location; the remainder of supply ducts will be located in above-grade conditioned space.")
    duct_location_frac.setDefaultValue(Constants.Auto)
    args << duct_location_frac

    #make a string argument for duct num returns
    duct_num_returns = OpenStudio::Ruleset::OSArgument::makeStringArgument("duct_num_returns", true)
    duct_num_returns.setDisplayName("Ducts: Number of Returns")
    duct_num_returns.setUnits("#")
    duct_num_returns.setDescription("The number of duct returns.")
    duct_num_returns.setDefaultValue(Constants.Auto)
    args << duct_num_returns       
    
    #make a double argument for supply surface area multiplier
    duct_supply_area_mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_supply_area_mult", true)
    duct_supply_area_mult.setDisplayName("Ducts: Supply Surface Area Multiplier")
    duct_supply_area_mult.setUnits("mult")
    duct_supply_area_mult.setDescription("Values specify a fraction of the Building America Benchmark supply duct surface area.")
    duct_supply_area_mult.setDefaultValue(1.0)
    args << duct_supply_area_mult

    #make a double argument for return surface area multiplier
    duct_return_area_mult = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_return_area_mult", true)
    duct_return_area_mult.setDisplayName("Ducts: Return Surface Area Multiplier")
    duct_return_area_mult.setUnits("mult")
    duct_return_area_mult.setDescription("Values specify a fraction of the Building America Benchmark return duct surface area.")
    duct_return_area_mult.setDefaultValue(1.0)
    args << duct_return_area_mult
    
    #make a double argument for duct unconditioned r value
    duct_unconditioned_r = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_unconditioned_r", true)
    duct_unconditioned_r.setDisplayName("Ducts: Insulation Nominal R-Value")
    duct_unconditioned_r.setUnits("h-ft^2-R/Btu")
    duct_unconditioned_r.setDescription("The nominal R-value for duct insulation.")
    duct_unconditioned_r.setDefaultValue(0.0)
    args << duct_unconditioned_r

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    infiltrationLivingSpaceACH50 = runner.getDoubleArgumentValue("living_ach50",user_arguments)
    if infiltrationLivingSpaceACH50 == 0
      infiltrationLivingSpaceACH50 = nil
    end
    infiltrationGarageACH50 = runner.getDoubleArgumentValue("garage_ach50",user_arguments)
    crawlACH = runner.getDoubleArgumentValue("crawl_ach",user_arguments)
    fbsmtACH = runner.getDoubleArgumentValue("finished_basement_ach",user_arguments)
    ufbsmtACH = runner.getDoubleArgumentValue("unfinished_basement_ach",user_arguments)
    uaSLA = runner.getDoubleArgumentValue("unfinished_attic_ach",user_arguments)
    infiltrationShelterCoefficient = runner.getStringArgumentValue("shelter_coef",user_arguments)
    has_flue = runner.getBoolArgumentValue("has_flue",user_arguments)
    terrainType = runner.getStringArgumentValue("terrain",user_arguments)
    mechVentType = runner.getStringArgumentValue("mech_vent_type",user_arguments)
    mechVentInfilCredit = runner.getBoolArgumentValue("mech_vent_infil_credit",user_arguments)
    mechVentTotalEfficiency = runner.getDoubleArgumentValue("mech_vent_total_efficiency",user_arguments)
    mechVentSensibleEfficiency = runner.getDoubleArgumentValue("mech_vent_sensible_efficiency",user_arguments)
    mechVentHouseFanPower = runner.getDoubleArgumentValue("mech_vent_fan_power",user_arguments)
    mechVentFractionOfASHRAE = runner.getDoubleArgumentValue("mech_vent_frac_62_2",user_arguments)
    mechVentASHRAEStandard = runner.getStringArgumentValue("mech_vent_ashrae_std",user_arguments)
    if mechVentType == "none"
      mechVentFractionOfASHRAE = 0.0
      mechVentHouseFanPower = 0.0
      mechVentTotalEfficiency = 0.0
      mechVentSensibleEfficiency = 0.0
    end
    dryerExhaust = runner.getDoubleArgumentValue("clothes_dryer_exhaust",user_arguments)
    ageOfHome = runner.getDoubleArgumentValue("age_of_home",user_arguments)
    natVentHtgSsnSetpointOffset = runner.getDoubleArgumentValue("nat_vent_htg_offset",user_arguments)
    natVentClgSsnSetpointOffset = runner.getDoubleArgumentValue("nat_vent_clg_offset",user_arguments)
    natVentOvlpSsnSetpointOffset = runner.getDoubleArgumentValue("nat_vent_ovlp_offset",user_arguments)
    natVentHeatingSeason = runner.getBoolArgumentValue("nat_vent_htg_season",user_arguments)
    natVentCoolingSeason = runner.getBoolArgumentValue("nat_vent_clg_season",user_arguments)
    natVentOverlapSeason = runner.getBoolArgumentValue("nat_vent_ovlp_season",user_arguments)
    natVentNumberWeekdays = runner.getIntegerArgumentValue("nat_vent_num_weekdays",user_arguments)
    natVentNumberWeekendDays = runner.getIntegerArgumentValue("nat_vent_num_weekends",user_arguments)
    natVentFractionWindowsOpen = runner.getDoubleArgumentValue("nat_vent_frac_windows_open",user_arguments)
    natVentFractionWindowAreaOpen = runner.getDoubleArgumentValue("nat_vent_frac_window_area_openable",user_arguments)
    natVentMaxOAHumidityRatio = runner.getDoubleArgumentValue("nat_vent_max_oa_hr",user_arguments)
    natVentMaxOARelativeHumidity = runner.getDoubleArgumentValue("nat_vent_max_oa_rh",user_arguments)    
    duct_location = runner.getStringArgumentValue("duct_location",user_arguments)
    ductTotalLeakage = runner.getDoubleArgumentValue("duct_total_leakage",user_arguments)
    ductSupplyLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_supply_frac",user_arguments)
    ductReturnLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_return_frac",user_arguments)
    ductAHSupplyLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_ah_supply_frac",user_arguments)
    ductAHReturnLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_ah_return_frac",user_arguments)
    ductNormLeakageToOutside = runner.getStringArgumentValue("duct_norm_leakage_25pa",user_arguments)
    unless ductNormLeakageToOutside == "NA"
      ductNormLeakageToOutside = ductNormLeakageToOutside.to_f
    else
      ductNormLeakageToOutside = nil
    end
    duct_location_frac = runner.getStringArgumentValue("duct_location_frac",user_arguments)
    duct_num_returns = runner.getStringArgumentValue("duct_num_returns",user_arguments)
    ductSupplySurfaceAreaMultiplier = runner.getDoubleArgumentValue("duct_supply_area_mult",user_arguments)
    ductReturnSurfaceAreaMultiplier = runner.getDoubleArgumentValue("duct_return_area_mult",user_arguments)
    ductUnconditionedRvalue = runner.getDoubleArgumentValue("duct_unconditioned_r",user_arguments)

    # Create the class instances
    infil = Infiltration.new(infiltrationLivingSpaceACH50, infiltrationShelterCoefficient, infiltrationGarageACH50)
    wind_speed = WindSpeed.new
    mech_vent = MechanicalVentilation.new(mechVentType, mechVentInfilCredit, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower, mechVentSensibleEfficiency, mechVentASHRAEStandard)
    building = Building.new
    nat_vent = NaturalVentilation.new(natVentHtgSsnSetpointOffset, natVentClgSsnSetpointOffset, natVentOvlpSsnSetpointOffset, natVentHeatingSeason, natVentCoolingSeason, natVentOverlapSeason, natVentNumberWeekdays, natVentNumberWeekendDays, natVentFractionWindowsOpen, natVentFractionWindowAreaOpen, natVentMaxOAHumidityRatio, natVentMaxOARelativeHumidity)
    schedules = Schedules.new
    ducts = Ducts.new(ductTotalLeakage, ductNormLeakageToOutside, ductSupplySurfaceAreaMultiplier, ductReturnSurfaceAreaMultiplier, ductUnconditionedRvalue, ductSupplyLeakageFractionOfTotal, ductReturnLeakageFractionOfTotal, ductAHSupplyLeakageFractionOfTotal, ductAHReturnLeakageFractionOfTotal)
    
    @weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if @weather.error?
        return false
    end    
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    # Remove any existing airflow objects
    HelperMethods.remove_object_from_osm_based_on_name(model, "SpaceInfiltrationDesignFlowRate", ["Living Infiltration", "Natural Ventilation"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "SpaceInfiltrationEffectiveLeakageArea", ["UAtcInfiltration"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "OutputVariable", ["Schedule Value", "System Node Temperature", "Zone Outdoor Air Drybulb Temperature", "Site Outdoor Air Enthalpy", "Zone Air Temperature", "System Node Humidity Ratio", "System Node Current Density Volume Flow Rate", "Fan Runtime Fraction", "System Node Mass Flow Rate", "Site Wind Speed", "Site Outdoor Air Humidity Ratio", "Zone Mean Air Humidity Ratio", "Zone Air Relative Humidity", "Zone Mean Air Temperature", "Site Outdoor Air Barometric Pressure"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemSensor", ["Tout_", "Hout_", "Tin_", "Pbar_", "Phiin_", "Win_", "Wout_", "Vwind_", "WH_sch_", "Range_sch_", "Bath_sch_", "Clothes_dryer_sch_", "NVAvail_", "NVSP_", "AH_MFR_Sensor_", "Fan_RTF_Sensor_", "AH_VFR_Sensor_", "AH_Tout_Sensor_", "RA_T_Sensor_", "AH_Wout_Sensor_", "AHZone_T_Sensor_", "RA_W_Sensor_", "AHZone_W_Sensor_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemActuator", ["InfilFlow_", "NatVentFlow_", "AHZoneToLivingFlowRateActuator_", "LivingToAHZoneFlowRateActuator_", "SupplyLeakSensibleActuator_", "SupplyLeakLatentActuator_", "SupplyDuctLoadToLivingActuator_", "ConductionToAHZoneActuator_", "ReturnDuctLoadToPlenumActuator_", "ReturnConductionToAHZoneActuator_", "SensibleLeakageToAHZoneActuator_", "LatentLeakageToAHZoneActuator_", "ReturnSensibleLeakageActuator_", "ReturnLatentLeakageActuator_", "WholeHouseFanPowerOverride_", "RangeHoodFanPowerOverride_", "BathExhaustFanPowerOverride_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemProgram", ["DuctLeakageProgram_", "NaturalVentilationProgram_", "InfiltrationProgram_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemOutputVariable", ["Bath Exhaust Fan Vent Flow Rate_", "Clothes Dryer Exhaust Fan Vent Flow Rate_", "Local Wind Speed_", "Range Hood Fan Vent Flow Rate_", "Whole House Fan Vent Flow Rate_", "Zone Infil/MechVent Flow Rate_", "Zone Natural Ventilation Flow Rate_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemProgramCallingManager", ["AirflowCalculator_", "DuctLeakageCallingManager_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemGlobalVariable", ["AH_MFR_", "Fan_RTF_", "AH_VFR_", "AH_Tout_", "AH_Wout_", "RA_T_", "RA_W_", "AHZone_T_", "AHZone_W_", "SupplyLeakSensibleLoad_", "SupplyLeakLatentLoad_", "SupplyDuctLoadToLiving_", "ConductionToAHZone_", "ReturnConductionToAHZone_", "ReturnDuctLoadToPlenum_", "SensibleLeakageToAHZone_", "LatentLeakageToAHZone_", "AHZoneToLivingFlowRate_", "LivingToAHZoneFlowRate_", "ReturnSensibleLeakage_", "ReturnLatentLeakage_", "DuctLeakSupplyFanEquivalent_", "DuctLeakExhaustFanEquivalent_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "EnergyManagementSystemSubroutine", ["CalculateDuctLeakage_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "MasslessOpaqueMaterial", ["Adiabatic"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "Construction", ["AdiabaticConst"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "ThermalZone", ["RA Duct Zone"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "Space", ["RA Duct Space"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "ZoneMixing", ["AHZoneToLivingZoneMixing", "LivingZoneToAHZoneMixing"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "AirLoopHVACReturnPlenum", ["Return Plenum"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "ElectricEquipmentDefinition", ["House Exhaust Fan Load_", "Range Hood Fan Load_", "Bath Exhaust Fan Load_"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "OtherEquipmentDefinition", ["Other Equipment"])
    HelperMethods.remove_object_from_osm_based_on_name(model, "ScheduleRuleset", ["MechanicalVentilationEnergy", "MechanicalVentilationSchedule", "BathExhaust", "ClothesDryerExhaust", "RangeHood", "NatVentSchedule", "NatVentTemp"])
    
    # Determine geometry for spaces and zones that aren't unit specific 
    building.building_height = Geometry.get_building_height(model.getSpaces)
    unless model.getBuilding.standardsNumberOfAboveGroundStories.is_initialized
      runner.registerError("Cannot determine the number of above grade stories.")
      return false
    end
    building.stories = model.getBuilding.standardsNumberOfAboveGroundStories.get
    building.num_units = units.size
    building.above_grade_volume = Geometry.get_above_grade_finished_volume_from_spaces(model.getSpaces, true)
    building.above_grade_exterior_wall_area = Geometry.calculate_exterior_wall_area(model.getSpaces, false)    
    model.getThermalZones.each do |thermal_zone|
      if thermal_zone.name.to_s.start_with? Constants.GarageZone
        building.garage_zone = Geometry.get_thermal_zone_from_string(model.getThermalZones, thermal_zone.name.to_s, runner)
        building.garage = Garage.new(Geometry.get_building_height(building.garage_zone.spaces), OpenStudio::convert(building.garage_zone.floorArea,"m^2","ft^2").get, Geometry.get_building_height(building.garage_zone.spaces) * OpenStudio::convert(building.garage_zone.floorArea,"m^2","ft^2").get, Geometry.get_z_origin_for_zone(thermal_zone))
      elsif thermal_zone.name.to_s.start_with? Constants.UnfinishedBasementZone
        building.unfinished_basement_zone = Geometry.get_thermal_zone_from_string(model.getThermalZones, thermal_zone.name.to_s, runner)
        building.unfinished_basement = UnfinBasement.new(ufbsmtACH, Geometry.get_building_height(building.unfinished_basement_zone.spaces), OpenStudio::convert(building.unfinished_basement_zone.floorArea,"m^2","ft^2").get, Geometry.get_building_height(building.unfinished_basement_zone.spaces) * OpenStudio::convert(building.unfinished_basement_zone.floorArea,"m^2","ft^2").get, Geometry.get_z_origin_for_zone(thermal_zone))
      elsif thermal_zone.name.to_s.start_with? Constants.CrawlZone
        building.crawlspace_zone = Geometry.get_thermal_zone_from_string(model.getThermalZones, thermal_zone.name.to_s, runner)
        building.crawlspace = Crawl.new(crawlACH, Geometry.get_building_height(building.crawlspace_zone.spaces), OpenStudio::convert(building.crawlspace_zone.floorArea,"m^2","ft^2").get, Geometry.get_building_height(building.crawlspace_zone.spaces) * OpenStudio::convert(building.crawlspace_zone.floorArea,"m^2","ft^2").get, Geometry.get_z_origin_for_zone(thermal_zone))
      elsif thermal_zone.name.to_s.start_with? Constants.UnfinishedAtticZone
        building.unfinished_attic_zone = Geometry.get_thermal_zone_from_string(model.getThermalZones, thermal_zone.name.to_s, runner)
        building.unfinished_attic = UnfinAttic.new(uaSLA, Geometry.get_building_height(building.unfinished_attic_zone.spaces), OpenStudio::convert(building.unfinished_attic_zone.floorArea,"m^2","ft^2").get, Geometry.get_building_height(building.unfinished_attic_zone.spaces) * OpenStudio::convert(building.unfinished_attic_zone.floorArea,"m^2","ft^2").get, Geometry.get_z_origin_for_zone(thermal_zone))
      end
    end

    building.finished_floor_area = Geometry.get_finished_floor_area_from_spaces(model.getSpaces, true, runner)
    if building.finished_floor_area.nil?
      return false
    end
    building.above_grade_finished_floor_area = Geometry.get_above_grade_finished_floor_area_from_spaces(model.getSpaces, true, runner)
    if building.above_grade_finished_floor_area.nil?
      return false
    end    

    wind_speed = _processWindSpeedCorrection(infil, wind_speed, terrainType, Geometry.get_closest_neighbor_distance(model), building)
    infil, building = _processInfiltration(infil, wind_speed, building)
        
    unless building.garage_zone.nil?
      if building.garage.SLA > 0
        space_infil_effective_leakage_area = OpenStudio::Model::SpaceInfiltrationEffectiveLeakageArea.new(model)
        space_infil_effective_leakage_area.setName("GarageInfiltration")
        space_infil_effective_leakage_area.setSchedule(model.alwaysOnDiscreteSchedule)
        space_infil_effective_leakage_area.setEffectiveAirLeakageArea(OpenStudio::convert(building.garage.ELA,"ft^2","cm^2").get)
        space_infil_effective_leakage_area.setStackCoefficient(UnitConversion.ft2_s2R2L2_s2cm4K(building.garage.C_s_SG))
        space_infil_effective_leakage_area.setWindCoefficient(UnitConversion._2L2s2_s2cm4m2(building.garage.C_w_SG))
        space_infil_effective_leakage_area.setSpace(building.garage_zone.spaces[0])
      end
    end
        
    unless building.unfinished_basement_zone.nil?
      if building.unfinished_basement.inf_method == Constants.InfMethodRes
        if building.unfinished_basement.ACH > 0
          space_infil_design_flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
          space_infil_design_flow_rate.setName("UBsmtInfiltration")
          space_infil_design_flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
          space_infil_design_flow_rate.setAirChangesperHour(building.unfinished_basement.ACH)
          space_infil_design_flow_rate.setSpace(building.unfinished_basement_zone.spaces[0])
        end
      end
    end
    
    unless building.crawlspace_zone.nil?
      space_infil_design_flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
      space_infil_design_flow_rate.setName("CSInfiltration")
      space_infil_design_flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
      space_infil_design_flow_rate.setAirChangesperHour(building.crawlspace.ACH)
      space_infil_design_flow_rate.setSpace(building.crawlspace_zone.spaces[0])
    end
    
    unless building.unfinished_attic_zone.nil?
      space_infil_effective_leakage_area = OpenStudio::Model::SpaceInfiltrationEffectiveLeakageArea.new(model)
      space_infil_effective_leakage_area.setName("UAtcInfiltration")
      space_infil_effective_leakage_area.setSchedule(model.alwaysOnDiscreteSchedule)
      space_infil_effective_leakage_area.setEffectiveAirLeakageArea(OpenStudio::convert(building.unfinished_attic.ELA,"ft^2","cm^2").get)
      space_infil_effective_leakage_area.setStackCoefficient(UnitConversion.ft2_s2R2L2_s2cm4K(building.unfinished_attic.C_s_SG))
      space_infil_effective_leakage_area.setWindCoefficient(UnitConversion._2L2s2_s2cm4m2(building.unfinished_attic.C_w_SG))
      space_infil_effective_leakage_area.setSpace(building.unfinished_attic_zone.spaces[0])
    end
        
    units.each do |building_unit|
      unit = Unit.new
      unit.num_bedrooms, unit.num_bathrooms = Geometry.get_unit_beds_baths(model, building_unit, runner)
      unit_spaces = building_unit.spaces
      if unit.num_bedrooms.nil? or unit.num_bathrooms.nil?
        return false
      end
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit_spaces)
      
      unit.unit_num = Geometry.get_unit_number(model, building_unit, runner)
      unit.age_of_home = ageOfHome
      unit.above_grade_exterior_wall_area = Geometry.calculate_exterior_wall_area(unit_spaces, false)
      unit.above_grade_finished_floor_area = Geometry.get_above_grade_finished_floor_area_from_spaces(unit_spaces, false, runner)
      unit.finished_floor_area = Geometry.get_finished_floor_area_from_spaces(unit_spaces, false, runner)
      unit.window_area = Geometry.get_window_area_from_spaces(unit_spaces, false)
      
      # Determine geometry for spaces and zones that are unit specific
      thermal_zones.each do |thermal_zone|
        if thermal_zone.name.to_s.start_with? Constants.LivingZone
          unit.living_zone = Geometry.get_thermal_zone_from_string(thermal_zones, thermal_zone.name.to_s, runner)
          unit.living = LivingSpace.new(Geometry.get_building_height(unit.living_zone.spaces), OpenStudio::convert(unit.living_zone.floorArea,"m^2","ft^2").get, Geometry.get_building_height(unit.living_zone.spaces) / building.stories * OpenStudio::convert(unit.living_zone.floorArea,"m^2","ft^2").get, Geometry.get_z_origin_for_zone(thermal_zone))
        elsif thermal_zone.name.to_s.start_with? Constants.FinishedBasementZone
          unit.finished_basement_zone = Geometry.get_thermal_zone_from_string(thermal_zones, thermal_zone.name.to_s, runner)
          unit.finished_basement = FinBasement.new(fbsmtACH, Geometry.get_building_height(unit.finished_basement_zone.spaces), OpenStudio::convert(unit.finished_basement_zone.floorArea,"m^2","ft^2").get, Geometry.get_building_height(unit.finished_basement_zone.spaces) * OpenStudio::convert(unit.finished_basement_zone.floorArea,"m^2","ft^2").get, Geometry.get_z_origin_for_zone(thermal_zone))
        end
      end

      if unit.living_zone.nil?
        return false
      end
            
      has_cd = false
      (model.getElectricEquipments + model.getGasEquipments).each do |equipment|
        if equipment.name.to_s.downcase.include? "clothes dryer"
          has_cd = true
          break
        end
      end
      if has_cd
        unit.dryer_exhaust = dryerExhaust
      else
        runner.registerWarning("No clothes dryer object was found in #{building_unit.name.to_s} but the clothes dryer exhaust specified is non-zero. Overriding clothes dryer exhaust to be zero.")
        unit.dryer_exhaust = 0
      end
      
      infil, building, unit = _processInfiltrationForUnit(infil, wind_speed, building, unit, has_flue, runner)
      mech_vent, schedules = _processMechanicalVentilation(model, runner, infil, mech_vent, building, unit, schedules)
      nat_vent, schedules = _processNaturalVentilation(model, runner, nat_vent, wind_speed, infil, building, unit, schedules)
      
      unless unit.finished_basement_zone.nil?
        if unit.finished_basement.inf_method == Constants.InfMethodRes
          if unit.finished_basement.ACH > 0            
            space_infil_design_flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
            space_infil_design_flow_rate.setName("FBsmtInfiltration_#{unit.unit_num}")
            space_infil_design_flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
            space_infil_design_flow_rate.setAirChangesperHour(unit.finished_basement.ACH)
            space_infil_design_flow_rate.setSpace(unit.finished_basement_zone.spaces[0])
          end
        end
      end      
      
      # Overridden by EMS
      
      space_infil_design_flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
      space_infil_design_flow_rate.setName("Living Infiltration_#{unit.unit_num}")
      space_infil_design_flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
      space_infil_design_flow_rate.setSpace(unit.living_zone.spaces[0])
      
      space_nat_vent_design_flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
      space_nat_vent_design_flow_rate.setName("Natural Ventilation_#{unit.unit_num}")
      space_nat_vent_design_flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
      space_nat_vent_design_flow_rate.setSpace(unit.living_zone.spaces[0])
      
      # Sensors
      
      zone_outdoor_air_drybulb_temp_output_var = OpenStudio::Model::OutputVariable.new("Zone Outdoor Air Drybulb Temperature", model)
      zone_outdoor_air_drybulb_temp_output_var.setName("Zone Outdoor Air Drybulb Temperature")
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_outdoor_air_drybulb_temp_output_var)
      sensor.setName("Tout_#{unit.unit_num}")
      sensor.setKeyName(unit.living_zone.name.to_s)      
      
      outdoor_air_enthalpy_output_var = OpenStudio::Model::OutputVariable.new("Site Outdoor Air Enthalpy", model)
      outdoor_air_enthalpy_output_var.setName("Site Outdoor Air Enthalpy")
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, outdoor_air_enthalpy_output_var)
      sensor.setName("Hout_#{unit.unit_num}")      
      
      outdoor_air_barometric_pressure_output_var = OpenStudio::Model::OutputVariable.new("Site Outdoor Air Barometric Pressure", model)
      outdoor_air_barometric_pressure_output_var.setName("Site Outdoor Air Barometric Pressure")
      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, outdoor_air_barometric_pressure_output_var)
      sensor.setName("Pbar_#{unit.unit_num}")      

      zone_mean_air_temp_output_var = OpenStudio::Model::OutputVariable.new("Zone Mean Air Temperature", model)
      zone_mean_air_temp_output_var.setName("Zone Mean Air Temperature")
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_mean_air_temp_output_var)
      sensor.setName("Tin_#{unit.unit_num}")
      sensor.setKeyName(unit.living_zone.name.to_s)
      
      zone_air_relative_humidity_output_var = OpenStudio::Model::OutputVariable.new("Zone Air Relative Humidity", model)
      zone_air_relative_humidity_output_var.setName("Zone Air Relative Humidity")      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_air_relative_humidity_output_var)
      sensor.setName("Phiin_#{unit.unit_num}")
      sensor.setKeyName(unit.living_zone.name.to_s)      
      
      zone_mean_air_humidity_ratio_output_var = OpenStudio::Model::OutputVariable.new("Zone Mean Air Humidity Ratio", model)
      zone_mean_air_humidity_ratio_output_var.setName("Zone Mean Air Humidity Ratio")      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_mean_air_humidity_ratio_output_var)
      sensor.setName("Win_#{unit.unit_num}")
      sensor.setKeyName(unit.living_zone.name.to_s)
      
      outdoor_air_humidity_ratio_output_var = OpenStudio::Model::OutputVariable.new("Site Outdoor Air Humidity Ratio", model)
      outdoor_air_humidity_ratio_output_var.setName("Site Outdoor Air Humidity Ratio")      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, outdoor_air_humidity_ratio_output_var)
      sensor.setName("Wout_#{unit.unit_num}")
     
      wind_speed_output_var = OpenStudio::Model::OutputVariable.new("Site Wind Speed", model)
      wind_speed_output_var.setName("Site Wind Speed")      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, wind_speed_output_var)
      sensor.setName("Vwind_#{unit.unit_num}")
      
      schedule_value_output_var = OpenStudio::Model::OutputVariable.new("Schedule Value", model)
      schedule_value_output_var.setName("Schedule Value")      
      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      sensor.setName("WH_sch_#{unit.unit_num}")
      sensor.setKeyName("Always On Discrete")      
      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      sensor.setName("Range_sch_#{unit.unit_num}")
      sensor.setKeyName("RangeHood_#{unit.unit_num}")
      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      sensor.setName("Bath_sch_#{unit.unit_num}")
      sensor.setKeyName("BathExhaust_#{unit.unit_num}")      
      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      sensor.setName("Clothes_dryer_sch_#{unit.unit_num}")
      sensor.setKeyName("ClothesDryerExhaust_#{unit.unit_num}")
      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      sensor.setName("NVAvail_#{unit.unit_num}")
      sensor.setKeyName("NatVentSchedule_#{unit.unit_num}")
      
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      sensor.setName("NVSP_#{unit.unit_num}")
      sensor.setKeyName("NatVentTemp_#{unit.unit_num}")
      
      # Actuators

      actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(space_infil_design_flow_rate, "Zone Infiltration", "Air Exchange Flow Rate")
      actuator.setName("InfilFlow_#{unit.unit_num}")

      actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(space_nat_vent_design_flow_rate, "Zone Infiltration", "Air Exchange Flow Rate")
      actuator.setName("NatVentFlow_#{unit.unit_num}")

      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName("House Exhaust Fan Load_#{unit.unit_num}")
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName("House Exhaust Fan Load_#{unit.unit_num}")
      equip.setSpace(unit.living_zone.spaces[0])
      equip_def.setFractionRadiant(0)
      equip_def.setFractionLatent(0)
      equip_def.setFractionLost(1.0 - mech_vent.percent_fan_heat_to_space)
      equip.setSchedule(model.alwaysOnDiscreteSchedule)
      equip.setEndUseSubcategory("VentFans")
      
      actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
      actuator.setName("WholeHouseFanPowerOverride_#{unit.unit_num}")      
      
      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName("Range Hood Fan Load_#{unit.unit_num}")
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName("Range Hood Fan Load_#{unit.unit_num}")
      equip.setSpace(unit.living_zone.spaces[0])
      equip_def.setFractionRadiant(0)
      equip_def.setFractionLatent(0)
      equip_def.setFractionLost(1)
      equip.setSchedule(model.alwaysOnDiscreteSchedule)
      equip.setEndUseSubcategory("VentFans")

      actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
      actuator.setName("RangeHoodFanPowerOverride_#{unit.unit_num}")      
      
      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName("Bath Exhaust Fan Load_#{unit.unit_num}")
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName("Bath Exhaust Fan Load_#{unit.unit_num}")
      equip.setSpace(unit.living_zone.spaces[0])
      equip_def.setFractionRadiant(0)
      equip_def.setFractionLatent(0)
      equip_def.setFractionLost(1)
      equip.setSchedule(model.alwaysOnDiscreteSchedule)
      equip.setEndUseSubcategory("VentFans")

      actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
      actuator.setName("BathExhaustFanPowerOverride_#{unit.unit_num}")      

      # Program
            
      infil_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      infil_program.setName("InfiltrationProgram_#{unit.unit_num}")
      infil_program.addLine("Set p_m = #{wind_speed.ashrae_terrain_exponent}")
      infil_program.addLine("Set p_s = #{wind_speed.ashrae_site_terrain_exponent}")
      infil_program.addLine("Set s_m = #{wind_speed.ashrae_terrain_thickness}")
      infil_program.addLine("Set s_s = #{wind_speed.ashrae_site_terrain_thickness}")
      infil_program.addLine("Set z_m = #{OpenStudio::convert(wind_speed.height,"ft","m").get}")
      infil_program.addLine("Set z_s = #{OpenStudio::convert(unit.living.height,"ft","m").get}")
      infil_program.addLine("Set f_t = (((s_m/z_m)^p_m)*((z_s/s_s)^p_s))")
      infil_program.addLine("Set VwindL_#{unit.unit_num} = (f_t*Vwind_#{unit.unit_num})")
      
      if unit.living.inf_method == Constants.InfMethodASHRAE
        if unit.living.SLA > 0
          infil_program.addLine("Set Tdiff = Tin_#{unit.unit_num} - Tout_#{unit.unit_num}")
          infil_program.addLine("Set DeltaT = @Abs Tdiff")
          infil_program.addLine("Set c = #{(OpenStudio::convert(infil.C_i,"cfm","m^3/s").get / (249.1 ** infil.n_i))}")
          infil_program.addLine("Set Cs = #{infil.stack_coef * (UnitConversion.inH2O_R2Pa_K(1.0) ** infil.n_i)}")
          infil_program.addLine("Set Cw = #{infil.wind_coef * (UnitConversion.inH2O_mph2Pas2_m2(1.0) ** infil.n_i)}")
          infil_program.addLine("Set n = #{infil.n_i}")
          infil_program.addLine("Set sft = (f_t*#{(((wind_speed.S_wo * (1.0 - infil.Y_i)) + (infil.S_wflue * (1.5 * infil.Y_i))))})")
          infil_program.addLine("Set Qn = (((c*Cs*(DeltaT^n))^2)+(((c*Cw)*((sft*Vwind_#{unit.unit_num})^(2*n)))^2))^0.5")
        else
          infil_program.addLine("Set Qn = 0")
        end
      elsif unit.living.inf_method == Constants.InfMethodRes
        infil_program.addLine("Set Qn = #{unit.living.ACH * OpenStudio::convert(unit.living.volume,"ft^3","m^3").get / OpenStudio::convert(1.0,"hr","s").get}")
      end
      
      infil_program.addLine("Set Tdiff = Tin_#{unit.unit_num} - Tout_#{unit.unit_num}")
      infil_program.addLine("Set DeltaT = @Abs Tdiff")
      infil_program.addLine("Set QWHV_#{unit.unit_num} = WH_sch_#{unit.unit_num}*#{OpenStudio::convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get}")
      infil_program.addLine("Set Qrange_#{unit.unit_num} = Range_sch_#{unit.unit_num}*#{OpenStudio::convert(mech_vent.range_hood_hour_avg_exhaust,"cfm","m^3/s").get}")
      infil_program.addLine("Set Qdryer_#{unit.unit_num} = Clothes_dryer_sch_#{unit.unit_num}*#{OpenStudio::convert(mech_vent.clothes_dryer_hour_avg_exhaust,"cfm","m^3/s").get}")
      infil_program.addLine("Set Qbath_#{unit.unit_num} = Bath_sch_#{unit.unit_num}*#{OpenStudio::convert(mech_vent.bathroom_hour_avg_exhaust,"cfm","m^3/s").get}")
      infil_program.addLine("Set QhpwhOut = 0")
      infil_program.addLine("Set QhpwhIn = 0")
      infil_program.addLine("Set QductsOut = DuctLeakExhaustFanEquivalent_#{unit.unit_num}")
      infil_program.addLine("Set QductsIn = DuctLeakSupplyFanEquivalent_#{unit.unit_num}")
      
      if mech_vent.MechVentType == Constants.VentTypeBalanced
        infil_program.addLine("Set Qout = Qrange_#{unit.unit_num}+Qbath_#{unit.unit_num}+Qdryer_#{unit.unit_num}+QhpwhOut+QductsOut")
        infil_program.addLine("Set Qin = QhpwhIn+QductsIn")
        infil_program.addLine("Set Qu = (@Abs (Qout - Qin))")
        infil_program.addLine("Set Qb = QWHV_#{unit.unit_num} + (@Min Qout Qin)")
        infil_program.addLine("Set WholeHouseFanPowerOverride = 0")
      else
        if mech_vent.MechVentType == Constants.VentTypeExhaust
          infil_program.addLine("Set Qout = QWHV_#{unit.unit_num}+Qrange_#{unit.unit_num}+Qbath_#{unit.unit_num}+Qdryer_#{unit.unit_num}+QhpwhOut+QductsOut")
          infil_program.addLine("Set Qin = QhpwhIn+QductsIn")
          infil_program.addLine("Set Qu = (@Abs (Qout - Qin))")
          infil_program.addLine("Set Qb = (@Min Qout Qin)")
        else # mech_vent.MechVentType == Constants.VentTypeSupply
          infil_program.addLine("Set Qout = Qrange_#{unit.unit_num}+Qbath_#{unit.unit_num}+Qdryer_#{unit.unit_num}+QhpwhOut+QductsOut")
          infil_program.addLine("Set Qin = QWHV_#{unit.unit_num}+QhpwhIn+QductsIn")
          infil_program.addLine("Set Qu = @Abs (Qout - Qin)")
          infil_program.addLine("Set Qb = (@Min Qout Qin)")
        end
        if mech_vent.MechVentHouseFanPower != 0
          infil_program.addLine("Set faneff_wh = #{OpenStudio::convert(300.0 / mech_vent.MechVentHouseFanPower,"cfm","m^3/s").get}")
        else
          infil_program.addLine("Set faneff_wh = 1")
        end
        infil_program.addLine("Set WholeHouseFanPowerOverride_#{unit.unit_num} = (QWHV_#{unit.unit_num}*300)/faneff_wh")
      end

      if mech_vent.MechVentSpotFanPower != 0
        infil_program.addLine("Set faneff_sp = #{OpenStudio::convert(300.0 / mech_vent.MechVentSpotFanPower,"cfm","m^3/s").get}")
      else
        infil_program.addLine("Set faneff_sp = 1")
      end
      
      infil_program.addLine("Set RangeHoodFanPowerOverride_#{unit.unit_num} = (Qrange_#{unit.unit_num}*300)/faneff_sp")
      infil_program.addLine("Set BathExhaustFanPowerOverride_#{unit.unit_num} = (Qbath_#{unit.unit_num}*300)/faneff_sp")
      infil_program.addLine("Set Q_acctd_for_elsewhere = QhpwhOut + QhpwhIn + QductsOut + QductsIn")
      infil_program.addLine("Set InfilFlow_#{unit.unit_num} = (((Qu^2) + (Qn^2))^0.5) - Q_acctd_for_elsewhere")
      infil_program.addLine("Set InfilFlow_#{unit.unit_num} = (@Max InfilFlow_#{unit.unit_num} 0)")
      infil_program.addLine("Set InfilFlow_display_#{unit.unit_num} = (((Qu^2) + (Qn^2))^0.5) - Qu")
      infil_program.addLine("Set InfMechVent_#{unit.unit_num} = Qb + InfilFlow_#{unit.unit_num}")

      # EMS Output Variables
      
      ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "InfMechVent_#{unit.unit_num}")
      ems_output_var.setName("Zone Infil/MechVent Flow Rate_#{unit.unit_num}")
      ems_output_var.setTypeOfDataInVariable("Averaged")
      ems_output_var.setUpdateFrequency("ZoneTimestep")
      ems_output_var.setEMSProgramOrSubroutineName(infil_program)
      ems_output_var.setUnits("m3/s")
      
      ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "QWHV_#{unit.unit_num}")
      ems_output_var.setName("Whole House Fan Vent Flow Rate_#{unit.unit_num}")
      ems_output_var.setTypeOfDataInVariable("Averaged")
      ems_output_var.setUpdateFrequency("ZoneTimestep")
      ems_output_var.setEMSProgramOrSubroutineName(infil_program)
      ems_output_var.setUnits("m3/s")
      
      ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "Qrange_#{unit.unit_num}")
      ems_output_var.setName("Range Hood Fan Vent Flow Rate_#{unit.unit_num}")
      ems_output_var.setTypeOfDataInVariable("Averaged")
      ems_output_var.setUpdateFrequency("ZoneTimestep")
      ems_output_var.setEMSProgramOrSubroutineName(infil_program)
      ems_output_var.setUnits("m3/s")
      
      ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "Qbath_#{unit.unit_num}")
      ems_output_var.setName("Bath Exhaust Fan Vent Flow Rate_#{unit.unit_num}")
      ems_output_var.setTypeOfDataInVariable("Averaged")
      ems_output_var.setUpdateFrequency("ZoneTimestep")
      ems_output_var.setEMSProgramOrSubroutineName(infil_program)
      ems_output_var.setUnits("m3/s")
      
      ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "Qdryer_#{unit.unit_num}")
      ems_output_var.setName("Clothes Dryer Exhaust Fan Vent Flow Rate_#{unit.unit_num}")
      ems_output_var.setTypeOfDataInVariable("Averaged")
      ems_output_var.setUpdateFrequency("ZoneTimestep")
      ems_output_var.setEMSProgramOrSubroutineName(infil_program)
      ems_output_var.setUnits("m3/s")
      
      ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "VwindL_#{unit.unit_num}")
      ems_output_var.setName("Local Wind Speed_#{unit.unit_num}")
      ems_output_var.setTypeOfDataInVariable("Averaged")
      ems_output_var.setUpdateFrequency("ZoneTimestep")
      ems_output_var.setEMSProgramOrSubroutineName(infil_program)
      ems_output_var.setUnits("m/s")
      
      # Program

      nat_vent_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      nat_vent_program.setName("NaturalVentilationProgram_#{unit.unit_num}")
      nat_vent_program.addLine("Set Tdiff = Tin_#{unit.unit_num} - Tout_#{unit.unit_num}")
      nat_vent_program.addLine("Set DeltaT = (@Abs Tdiff)")
      nat_vent_program.addLine("Set Phiout = (@RhFnTdbWPb Tout_#{unit.unit_num} Wout_#{unit.unit_num} Pbar_#{unit.unit_num})")
      nat_vent_program.addLine("Set Hin = (@HFnTdbRhPb Tin_#{unit.unit_num} Phiin_#{unit.unit_num} Pbar_#{unit.unit_num})")
      nat_vent_program.addLine("Set NVArea = #{OpenStudio::convert(nat_vent.area,"ft^2","cm^2").get}")
      nat_vent_program.addLine("Set Cs = #{UnitConversion.ft2_s2R2L2_s2cm4K(nat_vent.C_s)}")
      nat_vent_program.addLine("Set Cw = #{UnitConversion._2L2s2_s2cm4m2(nat_vent.C_w)}")
      nat_vent_program.addLine("Set MaxNV = #{OpenStudio::convert(nat_vent.max_flow_rate,"cfm","m^3/s").get}")
      nat_vent_program.addLine("Set MaxHR = #{nat_vent.NatVentMaxOAHumidityRatio}")
      nat_vent_program.addLine("Set MaxRH = #{nat_vent.NatVentMaxOARelativeHumidity}")
      nat_vent_program.addLine("Set SGNV = (NVAvail_#{unit.unit_num}*NVArea)*((((Cs*DeltaT)+(Cw*(Vwind_#{unit.unit_num}^2)))^0.5)/1000)")
      nat_vent_program.addLine("If (Wout_#{unit.unit_num} < MaxHR) && (Phiout < MaxRH) && (Tin_#{unit.unit_num} > NVSP_#{unit.unit_num})")
      nat_vent_program.addLine("Set NVadj1 = (Tin_#{unit.unit_num} - NVSP_#{unit.unit_num})/(Tin_#{unit.unit_num} - Tout_#{unit.unit_num})")
      nat_vent_program.addLine("Set NVadj2 = (@Min NVadj1 1)")
      nat_vent_program.addLine("Set NVadj3 = (@Max NVadj2 0)")
      nat_vent_program.addLine("Set NVadj = SGNV*NVadj3")
      nat_vent_program.addLine("Set NatVentFlow_#{unit.unit_num} = (@Min NVadj MaxNV)")
      nat_vent_program.addLine("Else")
      nat_vent_program.addLine("Set NatVentFlow_#{unit.unit_num} = 0")
      nat_vent_program.addLine("EndIf")
      
      # EMS Output Variables
      
      ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "NatVentFlow_#{unit.unit_num}")
      ems_output_var.setName("Zone Natural Ventilation Flow Rate_#{unit.unit_num}")
      ems_output_var.setTypeOfDataInVariable("Averaged")
      ems_output_var.setUpdateFrequency("ZoneTimestep")
      ems_output_var.setEMSProgramOrSubroutineName(nat_vent_program)
      ems_output_var.setUnits("m3/s")      
      
      # Program Calling Manager
      
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName("AirflowCalculator_#{unit.unit_num}")
      program_calling_manager.setCallingPoint("BeginTimestepBeforePredictor")
      program_calling_manager.addProgram(infil_program)
      program_calling_manager.addProgram(nat_vent_program)
      
      if mech_vent.MechVentType == Constants.VentTypeBalanced
      
        supply_fan = OpenStudio::Model::FanOnOff.new(model)
        supply_fan.setName("ERV Supply Fan_#{unit.unit_num}")
        supply_fan.setFanEfficiency(OpenStudio::convert(300.0 / mech_vent.MechVentHouseFanPower,"cfm","m^3/s").get)
        supply_fan.setPressureRise(300.0)
        supply_fan.setMaximumFlowRate(OpenStudio::convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get)
        supply_fan.setMotorEfficiency(1)
        supply_fan.setMotorInAirstreamFraction(1)
        supply_fan.setEndUseSubcategory(Constants.EndUseMechVentFan)

        exhaust_fan = OpenStudio::Model::FanOnOff.new(model)
        exhaust_fan.setName("ERV Exhaust Fan_#{unit.unit_num}")
        exhaust_fan.setFanEfficiency(OpenStudio::convert(300.0 / mech_vent.MechVentHouseFanPower,"cfm","m^3/s").get)
        exhaust_fan.setPressureRise(300.0)
        exhaust_fan.setMaximumFlowRate(OpenStudio::convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get)
        exhaust_fan.setMotorEfficiency(1)
        exhaust_fan.setMotorInAirstreamFraction(0)
        exhaust_fan.setEndUseSubcategory(Constants.EndUseMechVentFan)

        erv_controller = OpenStudio::Model::ZoneHVACEnergyRecoveryVentilatorController.new(model)
        erv_controller.setName("ERV Controller_#{unit.unit_num}")
        erv_controller.setExhaustAirTemperatureLimit("NoExhaustAirTemperatureLimit")
        erv_controller.setExhaustAirEnthalpyLimit("NoExhaustAirEnthalpyLimit")
        erv_controller.setTimeofDayEconomizerFlowControlSchedule(model.alwaysOnDiscreteSchedule)
        erv_controller.setHighHumidityControlFlag(false)

        heat_exchanger = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(model)
        heat_exchanger.setName("ERV Heat Exchanger_#{unit.unit_num}")
        heat_exchanger.setNominalSupplyAirFlowRate(OpenStudio::convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get)
        heat_exchanger.setSensibleEffectivenessat100HeatingAirFlow(mech_vent.MechVentHXCoreSensibleEffectiveness)
        heat_exchanger.setLatentEffectivenessat100HeatingAirFlow(mech_vent.MechVentLatentEffectiveness)
        heat_exchanger.setSensibleEffectivenessat75HeatingAirFlow(mech_vent.MechVentHXCoreSensibleEffectiveness)
        heat_exchanger.setLatentEffectivenessat75HeatingAirFlow(mech_vent.MechVentLatentEffectiveness)
        heat_exchanger.setSensibleEffectivenessat100CoolingAirFlow(mech_vent.MechVentHXCoreSensibleEffectiveness)
        heat_exchanger.setLatentEffectivenessat100CoolingAirFlow(mech_vent.MechVentLatentEffectiveness)
        heat_exchanger.setSensibleEffectivenessat75CoolingAirFlow(mech_vent.MechVentHXCoreSensibleEffectiveness)
        heat_exchanger.setLatentEffectivenessat75CoolingAirFlow(mech_vent.MechVentLatentEffectiveness)        

        zone_hvac = OpenStudio::Model::ZoneHVACEnergyRecoveryVentilator.new(model, heat_exchanger, supply_fan, exhaust_fan)
        zone_hvac.setName("ERV_#{unit.unit_num}")
        zone_hvac.setController(erv_controller)
        zone_hvac.setSupplyAirFlowRate(OpenStudio::convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get)
        zone_hvac.setExhaustAirFlowRate(OpenStudio::convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get)

      end
      
      # Ducts    
      
      if duct_location != "none" and HVAC.has_central_air_conditioner(model, runner, unit.living_zone, false, false).nil? and HVAC.has_furnace(model, runner, unit.living_zone, false, false).nil? and HVAC.has_air_source_heat_pump(model, runner, unit.living_zone, false).nil?
        runner.registerWarning("No ducted HVAC equipment was found but ducts were specified. Overriding duct specification.")
        duct_location = "none"
      end        
      
      ducts.duct_location_zone, ducts.duct_location_name = get_duct_location(runner, duct_location, building, unit)
      # Disallow placing ducts in locations that don't exist, and handle
      # exception for no ducts (in DuctLocation = None).    
      if !ducts.duct_location_zone
        runner.registerError("Duct location is basement, but the building does not have a basement.")
        return false
      end

      ducts.has_ducts = true  
      if ducts.duct_location_name == "none"
        ducts.duct_location_zone = unit.living_zone
        ducts.duct_location_name = unit.living_zone.name.to_s
        ducts.has_ducts = false
      end      
      
      unless HVAC.has_mini_split_heat_pump(model, runner, unit.living_zone, false).nil?
        ducts.duct_location_zone = unit.living_zone
        ducts.duct_location_name = unit.living_zone.name.to_s
        ducts.has_ducts = false
        runner.registerWarning("Duct losses are currently neglected when simulating mini-split heat pumps. Set Ducts to None or In Finished Space to avoid this warning message.")
      end     
      
      # Set has_uncond_ducts to False if ducts are in a conditioned space,
      # otherwise True    
      ducts.ducts_not_in_living = true
      if ducts.duct_location_name == unit.living_zone.name.to_s
        ducts.ducts_not_in_living = false
      end      
      
      ducts.num_stories_for_ducts = building.stories
      unless unit.finished_basement_zone.nil?
        ducts.num_stories_for_ducts += 1
      end
      
      ducts.num_stories = ducts.num_stories_for_ducts
      
      if ducts.DuctNormLeakageToOutside.nil?
        # Normalize values in case user inadvertently entered values that add up to the total duct leakage, 
        # as opposed to adding up to 1
        sumFractionOfTotal = (ducts.DuctSupplyLeakageFractionOfTotal + ducts.DuctReturnLeakageFractionOfTotal + ducts.DuctAHSupplyLeakageFractionOfTotal + ducts.DuctAHReturnLeakageFractionOfTotal)
        if sumFractionOfTotal > 0
          ducts.DuctSupplyLeakageFractionOfTotal = ductSupplyLeakageFractionOfTotal / sumFractionOfTotal
          ducts.DuctReturnLeakageFractionOfTotal = ductReturnLeakageFractionOfTotal / sumFractionOfTotal
          ducts.DuctAHSupplyLeakageFractionOfTotal = ductAHSupplyLeakageFractionOfTotal / sumFractionOfTotal
          ducts.DuctAHReturnLeakageFractionOfTotal = ductAHReturnLeakageFractionOfTotal / sumFractionOfTotal
        end        
        # Calculate actual leakages from percentages
        ducts.DuctSupplyLeakage = ducts.DuctSupplyLeakageFractionOfTotal * ducts.DuctTotalLeakage
        ducts.DuctReturnLeakage = ducts.DuctReturnLeakageFractionOfTotal * ducts.DuctTotalLeakage
        ducts.DuctAHSupplyLeakage = ducts.DuctAHSupplyLeakageFractionOfTotal * ducts.DuctTotalLeakage
        ducts.DuctAHReturnLeakage = ducts.DuctAHReturnLeakageFractionOfTotal * ducts.DuctTotalLeakage     
      end      
      
      # Fraction of ducts in primary duct location (remaining ducts are in above-grade conditioned space).
      if duct_location_frac == Constants.Auto
        # Duct location fraction per 2010 BA Benchmark
        if ducts.num_stories == 1
          ducts.DuctLocationFrac = 1
        else
          ducts.DuctLocationFrac = 0.65
        end
      else
        ducts.DuctLocationFrac = duct_location_frac.to_f
      end    
      
      ducts.DuctLocationFracLeakage = ducts.DuctLocationFrac
      ducts.DuctLocationFracConduction = ducts.DuctLocationFrac      
      ducts.DuctNumReturns = get_duct_num_returns(duct_num_returns, ducts.num_stories)
      ducts.supply_duct_surface_area = get_duct_supply_surface_area(ducts.DuctSupplySurfaceAreaMultiplier, unit, ducts.num_stories)
      ducts.return_duct_surface_area = get_duct_return_surface_area(ducts.DuctReturnSurfaceAreaMultiplier, unit, ducts.num_stories, ducts.DuctNumReturns)
      ducts_total_duct_surface_area = ducts.supply_duct_surface_area + ducts.return_duct_surface_area
      
      # Calculate Duct UA value
      if ducts.ducts_not_in_living
        ducts.unconditioned_duct_area = ducts.supply_duct_surface_area * ducts.DuctLocationFracConduction
        ducts.supply_duct_r = get_duct_insulation_rvalue(ducts.DuctUnconditionedRvalue, true)
        ducts.return_duct_r = get_duct_insulation_rvalue(ducts.DuctUnconditionedRvalue, false)
        ducts.unconditioned_duct_ua = ducts.unconditioned_duct_area / ducts.supply_duct_r
        ducts.return_duct_ua = ducts.return_duct_surface_area / ducts.return_duct_r
      else
        ducts.DuctLocationFracConduction = 0
        ducts.unconditioned_duct_ua = 0
        ducts.return_duct_ua = 0
      end
      
      # Calculate Duct Volume
      if ducts.ducts_not_in_living
        # Assume ducts are 3 ft by 1 ft, (8 is the perimeter)
        ducts.supply_duct_volume = (ducts.unconditioned_duct_area / 8.0) * 3.0
        ducts.return_duct_volume = (ducts.return_duct_surface_area / 8.0) * 3.0
      else
        ducts.supply_duct_volume = 0
        ducts.return_duct_volume = 0
      end
      
      # This can't be zero. A value of zero causes weird sizing issues in DOE-2.
      ducts.direct_oa_supply_duct_loss = 0.000001       
      
      # Only if using the Fractional Leakage Option Type:
      if ducts.DuctNormLeakageToOutside.nil?
        ducts.supply_duct_loss = (ducts.DuctLocationFracLeakage * (ducts.DuctSupplyLeakage - ducts.direct_oa_supply_duct_loss) + (ducts.DuctAHSupplyLeakage + ducts.direct_oa_supply_duct_loss))
        ducts.return_duct_loss = ducts.DuctReturnLeakage + ducts.DuctAHReturnLeakage
      end
      
      # _processDuctLeakage
      unless ducts.DuctNormLeakageToOutside.nil?
        runner.registerError("Duct leakage to outside was specified by we don't calculate fan air flow rate.")
        return false
      end
      
      ducts.total_duct_unbalance = (ducts.supply_duct_loss - ducts.return_duct_loss).abs
      ducts.frac_oa = nil

      if not ducts.duct_location_name == unit.living_zone.name.to_s and not ducts.duct_location_name == "none" and ducts.supply_duct_loss > 0
        # Calculate d.frac_oa = fraction of unbalanced make-up air that is outside air
        if ducts.total_duct_unbalance <= 0
          # Handle the exception for if there is no leakage unbalance.
          ducts.frac_oa = 0        
        else
          unless unit.finished_basement_zone.nil?
            if unit.finished_basement_zone == ducts.duct_location_zone
              ducts.frac_oa = ducts.direct_oa_supply_duct_loss / ducts.total_duct_unbalance
            end
          end
          unless building.unfinished_basement_zone.nil?
            if building.unfinished_basement_zone == ducts.duct_location_zone
              ducts.frac_oa = ducts.direct_oa_supply_duct_loss / ducts.total_duct_unbalance
            end
          end
          unless building.crawlspace_zone.nil?
            if building.crawlspace_zone == ducts.duct_location_zone and building.crawlspace.ACH == 0
              ducts.frac_oa = ducts.direct_oa_supply_duct_loss / ducts.total_duct_unbalance
            end
          end
          unless building.crawlspace_zone.nil?
            if building.crawlspace_zone == ducts.duct_location_zone and building.crawlspace.ACH == 0
              ducts.frac_oa = ducts.direct_oa_supply_duct_loss / ducts.total_duct_unbalance
            end
          end        
          # Assume that all of the unbalanced make-up air is driven infiltration from outdoors.
          # This assumes that the holes for attic ventilation are much larger than any attic bypasses.      
          if ducts.frac_oa.nil?
            ducts.frac_oa = 1
          end
        end
        # d.oa_duct_makeup =  fraction of the supply duct air loss that is made up by outside air (via return leakage)
        ducts.oa_duct_makeup = [ducts.frac_oa * ducts.total_duct_unbalance / [ducts.supply_duct_loss, ducts.return_duct_loss].max, 1].min
      else
        ducts.frac_oa = 0
        ducts.oa_duct_makeup = 0
      end
            
      hasForcedAirEquipment = false
      model.getAirLoopHVACs.each do |air_loop|
        next unless air_loop.thermalZones.include? unit.living_zone
        hasForcedAirEquipment = true
      end        

      if not ducts.duct_location_name == unit.living_zone.name.to_s and not ducts.duct_location_name == "none" and hasForcedAirEquipment
      
        adiabatic_mat = OpenStudio::Model::MasslessOpaqueMaterial.new(model, "Rough", 176.1)
        adiabatic_mat.setName("Adiabatic")

        adiabatic_const = OpenStudio::Model::Construction.new(model)
        adiabatic_const.setName("AdiabaticConst")
        adiabatic_const.insertLayer(0, adiabatic_mat)
      
        ra_duct_zone = OpenStudio::Model::ThermalZone.new(model)
        ra_duct_zone.setName("RA Duct Zone_#{unit.unit_num}")
        ra_duct_zone.setVolume(OpenStudio::convert(ducts.return_duct_volume,"ft^3","m^3").get)
        
        sw_point = OpenStudio::Point3d.new(0, 74, 0)
        nw_point = OpenStudio::Point3d.new(0, 75, 0)
        ne_point = OpenStudio::Point3d.new(1, 75, 0)
        se_point = OpenStudio::Point3d.new(1, 74, 0)
        ra_duct_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
        
        ra_duct_space = OpenStudio::Model::Space::fromFloorPrint(ra_duct_polygon, 1, model)
        ra_duct_space = ra_duct_space.get
        ra_duct_space.setName("RA Duct Space_#{unit.unit_num}")
        ra_duct_space.setThermalZone(ra_duct_zone)
        
        ra_duct_space.surfaces.each do |surface|
          surface.setConstruction(adiabatic_const)
          surface.setOutsideBoundaryCondition("Adiabatic")
          surface.setSunExposure("NoSun")
          surface.setWindExposure("NoWind")
        end
      
        # Two objects are required to model the air exchange between the air handler zone and the living space since
        # ZoneMixing objects can not account for direction of air flow (both are controlled by EMS)

        # Accounts for leaks from the AH zone to the Living zone
        
        zone_mixing_ah_to_living = OpenStudio::Model::ZoneMixing.new(unit.living_zone)
        zone_mixing_ah_to_living.setName("AHZoneToLivingZoneMixing_#{unit.unit_num}")
        zone_mixing_ah_to_living.setSourceZone(ducts.duct_location_zone)
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(zone_mixing_ah_to_living, "ZoneMixing", "Air Exchange Flow Rate")
        actuator.setName("AHZoneToLivingFlowRateActuator_#{unit.unit_num}")
        
        zone_mixing_living_to_ah = OpenStudio::Model::ZoneMixing.new(ducts.duct_location_zone)
        zone_mixing_living_to_ah.setName("LivingZoneToAHZoneMixing_#{unit.unit_num}")
        zone_mixing_living_to_ah.setSourceZone(unit.living_zone)
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(zone_mixing_living_to_ah, "ZoneMixing", "Air Exchange Flow Rate")
        actuator.setName("LivingToAHZoneFlowRateActuator_#{unit.unit_num}")
        
        air_demand_inlet_node = nil
        model.getAirLoopHVACs.each do |air_loop|
          next unless air_loop.thermalZones.include? unit.living_zone # get the correct air loop for this unit
          air_demand_inlet_node = air_loop.demandInletNode
        end
        living_zone_return_air_node = unit.living_zone.returnAirModelObject().get
        
        unit.living_zone.setReturnPlenum(ra_duct_zone)
        unless unit.finished_basement_zone.nil?
          unit.finished_basement_zone.setReturnPlenum(ra_duct_zone)
        end
        
        # Other equipment objects to cancel out the supply air leakage directly into the return plenum
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName("SupplySensibleLeakageToLiving_#{unit.unit_num}")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(unit.living_zone.spaces[0])
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        actuator.setName("SupplyLeakSensibleActuator_#{unit.unit_num}")
        
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName("SupplyLatentLeakageToLiving_#{unit.unit_num}")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(unit.living_zone.spaces[0])
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        actuator.setName("SupplyLeakLatentActuator_#{unit.unit_num}")        
        
        # Supply duct conduction load added to the living space
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName("SupplyDuctConductionToLiving_#{unit.unit_num}")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(unit.living_zone.spaces[0])
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        actuator.setName("SupplyDuctLoadToLivingActuator_#{unit.unit_num}")
        
        # Supply duct conduction impact on the air handler zone.
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName("SupplyDuctConductionToAHZone_#{unit.unit_num}")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ducts.duct_location_zone.spaces[0])
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        actuator.setName("ConductionToAHZoneActuator_#{unit.unit_num}")
        
        # Return duct conduction load added to the return plenum zone
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName("ReturnDuctConductionToPlenum_#{unit.unit_num}")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ra_duct_space)
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        actuator.setName("ReturnDuctLoadToPlenumActuator_#{unit.unit_num}")
      
        # Return duct conduction impact on the air handler zone.
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName("ReturnDuctConductionToAHZone_#{unit.unit_num}")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ducts.duct_location_zone.spaces[0])
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        actuator.setName("ReturnConductionToAHZoneActuator_#{unit.unit_num}")
        
        # Supply duct sensible leakage impact on the air handler zone.
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName("SupplySensibleLeakageToAHZone_#{unit.unit_num}")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ducts.duct_location_zone.spaces[0])
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        actuator.setName("SensibleLeakageToAHZoneActuator_#{unit.unit_num}")
        
        # Supply duct latent leakage impact on the air handler zone.
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName("SupplyLatentLeakageToAHZone_#{unit.unit_num}")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ducts.duct_location_zone.spaces[0])
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        actuator.setName("LatentLeakageToAHZoneActuator_#{unit.unit_num}")
      
        # Return duct sensible leakage impact on the return plenum
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName("ReturnSensibleLeakageEquip_#{unit.unit_num}")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ra_duct_space)
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        actuator.setName("ReturnSensibleLeakageActuator_#{unit.unit_num}")
        
        # Return duct latent leakage impact on the return plenum
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName("ReturnLatentLeakageEquip_#{unit.unit_num}")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ra_duct_space)
        actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        actuator.setName("ReturnLatentLeakageActuator_#{unit.unit_num}")

        # Sensors        
      
        system_node_mass_flow_rate_output_var = OpenStudio::Model::OutputVariable.new("System Node Mass Flow Rate", model)
        system_node_mass_flow_rate_output_var.setName("System Node Mass Flow Rate")        
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_mass_flow_rate_output_var)
        sensor.setName("AH_MFR_Sensor_#{unit.unit_num}")
        sensor.setKeyName(air_demand_inlet_node.name.to_s)        
        
        fan_runtime_fraction_output_var = OpenStudio::Model::OutputVariable.new("Fan Runtime Fraction", model)
        fan_runtime_fraction_output_var.setName("Fan Runtime Fraction")        
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, fan_runtime_fraction_output_var)
        sensor.setName("Fan_RTF_Sensor_#{unit.unit_num}")
        sensor.setKeyName("Supply Fan_#{unit.unit_num}")
        
        system_node_current_density_volume_flow_rate_output_var = OpenStudio::Model::OutputVariable.new("System Node Current Density Volume Flow Rate", model)
        system_node_current_density_volume_flow_rate_output_var.setName("System Node Current Density Volume Flow Rate")        
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_current_density_volume_flow_rate_output_var)
        sensor.setName("AH_VFR_Sensor_#{unit.unit_num}")
        sensor.setKeyName(air_demand_inlet_node.name.to_s)
        
        system_node_temp_output_var = OpenStudio::Model::OutputVariable.new("System Node Temperature", model)
        system_node_temp_output_var.setName("System Node Temperature Air")
        
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_temp_output_var)
        sensor.setName("AH_Tout_Sensor_#{unit.unit_num}")
        sensor.setKeyName(air_demand_inlet_node.name.to_s)        
        
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_temp_output_var)
        sensor.setName("RA_T_Sensor_#{unit.unit_num}")
        sensor.setKeyName(living_zone_return_air_node.name.to_s)
        
        system_node_humidity_ratio_output_var = OpenStudio::Model::OutputVariable.new("System Node Humidity Ratio", model)
        system_node_humidity_ratio_output_var.setName("System Node Humidity Ratio")
        
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_humidity_ratio_output_var)
        sensor.setName("AH_Wout_Sensor_#{unit.unit_num}")
        sensor.setKeyName(air_demand_inlet_node.name.to_s)        
        
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_humidity_ratio_output_var)
        sensor.setName("RA_W_Sensor_#{unit.unit_num}")
        sensor.setKeyName(living_zone_return_air_node.name.to_s)
        
        zone_air_temp_output_var = OpenStudio::Model::OutputVariable.new("Zone Air Temperature", model)
        zone_air_temp_output_var.setName("Zone Air Temperature")        
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_air_temp_output_var)
        sensor.setName("AHZone_T_Sensor_#{unit.unit_num}")
        sensor.setKeyName(ducts.duct_location_name)        
        
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_mean_air_humidity_ratio_output_var)
        sensor.setName("AHZone_W_Sensor_#{unit.unit_num}")
        sensor.setKeyName(ducts.duct_location_name)
        
        # Global Variables
        
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "AH_MFR_#{unit.unit_num}")        
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "Fan_RTF_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "AH_VFR_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "AH_Tout_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "AH_Wout_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "RA_T_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "RA_W_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "AHZone_T_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "AHZone_W_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "SupplyLeakSensibleLoad_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "SupplyLeakLatentLoad_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "SupplyDuctLoadToLiving_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "ConductionToAHZone_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "ReturnConductionToAHZone_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "ReturnDuctLoadToPlenum_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "SensibleLeakageToAHZone_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "LatentLeakageToAHZone_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "AHZoneToLivingFlowRate_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "LivingToAHZoneFlowRate_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "ReturnSensibleLeakage_#{unit.unit_num}")
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "ReturnLatentLeakage_#{unit.unit_num}")

        # Subroutine
        
        duct_leakage_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
        duct_leakage_subroutine.setName("CalculateDuctLeakage_#{unit.unit_num}")
        duct_leakage_subroutine.addLine("Set f_sup = #{ducts.supply_duct_loss}")
        duct_leakage_subroutine.addLine("Set f_ret = #{ducts.return_duct_loss}")
        duct_leakage_subroutine.addLine("Set f_OA = #{ducts.frac_oa * ducts.total_duct_unbalance}")
        duct_leakage_subroutine.addLine("Set OAFlowRate = f_OA * AH_VFR_#{unit.unit_num}")
        duct_leakage_subroutine.addLine("Set SupplyLeakFlowRate = f_sup * AH_VFR_#{unit.unit_num}")
        duct_leakage_subroutine.addLine("Set ReturnLeakFlowRate = f_ret * AH_VFR_#{unit.unit_num}")
        
        if ducts.return_duct_loss > ducts.supply_duct_loss
          # Supply air flow rate is greater than return flow rate
          # Living zone is pressurized in this case      
          duct_leakage_subroutine.addLine("Set LivingToAHZoneFlowRate_#{unit.unit_num} = (@Abs (ReturnLeakFlowRate - SupplyLeakFlowRate - OAFlowRate))")
          duct_leakage_subroutine.addLine("Set AHZoneToLivingFlowRate_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set DuctLeakSupplyFanEquivalent_#{unit.unit_num} = OAFlowRate")
          duct_leakage_subroutine.addLine("Set DuctLeakExhaustFanEquivalent_#{unit.unit_num} = 0")
        else
          # Living zone is depressurized in this case
          duct_leakage_subroutine.addLine("Set AHZoneToLivingFlowRate_#{unit.unit_num} = (@Abs (SupplyLeakFlowRate - ReturnLeakFlowRate - OAFlowRate))")
          duct_leakage_subroutine.addLine("Set LivingToAHZoneFlowRate_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set DuctLeakSupplyFanEquivalent_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set DuctLeakExhaustFanEquivalent_#{unit.unit_num} = OAFlowRate")
        end        
      
        if ducts.ducts_not_in_living
          duct_leakage_subroutine.addLine("If (AH_MFR_#{unit.unit_num} > 0)")
          duct_leakage_subroutine.addLine("Set h_SA = (@HFnTdbW AH_Tout_#{unit.unit_num} AH_Wout_#{unit.unit_num})")
          duct_leakage_subroutine.addLine("Set h_AHZone = (@HFnTdbW AHZone_T_#{unit.unit_num} AHZone_W_#{unit.unit_num})")
          duct_leakage_subroutine.addLine("Set h_RA = (@HFnTdbW RA_T_#{unit.unit_num} RA_W_#{unit.unit_num})")
          duct_leakage_subroutine.addLine("Set h_fg = (@HfgAirFnWTdb AH_Wout_#{unit.unit_num} AH_Tout_#{unit.unit_num})")
          duct_leakage_subroutine.addLine("Set SALeakageQtot = f_sup * AH_MFR_#{unit.unit_num} * (h_RA - h_SA)")
          duct_leakage_subroutine.addLine("Set SupplyLeakLatentLoad_#{unit.unit_num} = f_sup * AH_MFR_#{unit.unit_num} * h_fg * (RA_W_#{unit.unit_num} - AH_Wout_#{unit.unit_num})")
          duct_leakage_subroutine.addLine("Set SupplyLeakSensibleLoad_#{unit.unit_num} = SALeakageQtot - SupplyLeakLatentLoad_#{unit.unit_num}")
          duct_leakage_subroutine.addLine("Set expTerm = (Fan_RTF_#{unit.unit_num} / (AH_MFR_#{unit.unit_num} * 1006.0)) * #{OpenStudio::convert(ducts.unconditioned_duct_ua,"Btu/hr*R","W/K").get}")
          duct_leakage_subroutine.addLine("Set expTerm = 0 - expTerm")
          duct_leakage_subroutine.addLine("If expTerm < -1000")
          duct_leakage_subroutine.addLine("Set Tsupply = AHZone_T_#{unit.unit_num}")
          duct_leakage_subroutine.addLine("Else")
          duct_leakage_subroutine.addLine("Set Tsupply = AHZone_T_#{unit.unit_num} + ((AH_Tout_#{unit.unit_num} - AHZone_T_#{unit.unit_num}) * (@Exp expTerm))")
          duct_leakage_subroutine.addLine("EndIf")
          duct_leakage_subroutine.addLine("Set SupplyDuctLoadToLiving_#{unit.unit_num} = AH_MFR_#{unit.unit_num} * 1006.0 * (Tsupply - AH_Tout_#{unit.unit_num})")
          duct_leakage_subroutine.addLine("Set ConductionToAHZone_#{unit.unit_num} = 0 - SupplyDuctLoadToLiving_#{unit.unit_num}")
          duct_leakage_subroutine.addLine("Set expTerm = (Fan_RTF_#{unit.unit_num} / (AH_MFR_#{unit.unit_num} * 1006.0)) * #{OpenStudio::convert(ducts.return_duct_ua,"Btu/hr*R","W/K").get}")
          duct_leakage_subroutine.addLine("Set expTerm = 0 - expTerm")
          duct_leakage_subroutine.addLine("If expTerm < -1000")
          duct_leakage_subroutine.addLine("Set Treturn = AHZone_T_#{unit.unit_num}")
          duct_leakage_subroutine.addLine("Else")
          duct_leakage_subroutine.addLine("Set Treturn = AHZone_T_#{unit.unit_num} + ((RA_T_#{unit.unit_num} - AHZone_T_#{unit.unit_num}) * (@Exp expTerm))")
          duct_leakage_subroutine.addLine("EndIf")
          duct_leakage_subroutine.addLine("Set ReturnDuctLoadToPlenum_#{unit.unit_num} = AH_MFR_#{unit.unit_num} * 1006.0 * (Treturn - RA_T_#{unit.unit_num})")
          duct_leakage_subroutine.addLine("Set ReturnConductionToAHZone_#{unit.unit_num} = 0 - ReturnDuctLoadToPlenum_#{unit.unit_num}")
          duct_leakage_subroutine.addLine("Set ReturnLatentLeakage_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ReturnSensibleLeakage_#{unit.unit_num} = f_ret * AH_MFR_#{unit.unit_num} * 1006.0 * (AHZone_T_#{unit.unit_num} - RA_T_#{unit.unit_num})")
          duct_leakage_subroutine.addLine("Set QtotLeakageToAHZone = f_sup * AH_MFR_#{unit.unit_num} * (h_SA - h_AHZone)")
          duct_leakage_subroutine.addLine("Set LatentLeakageToAHZone_#{unit.unit_num} = f_sup * AH_MFR_#{unit.unit_num} * h_fg * (AH_Wout_#{unit.unit_num} - AHZone_W_#{unit.unit_num})")
          duct_leakage_subroutine.addLine("Set SensibleLeakageToAHZone_#{unit.unit_num} = QtotLeakageToAHZone - LatentLeakageToAHZone_#{unit.unit_num}")
          duct_leakage_subroutine.addLine("Else")
          duct_leakage_subroutine.addLine("Set SupplyLeakLatentLoad_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set SupplyLeakSensibleLoad_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set SupplyDuctLoadToLiving_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ConductionToAHZone_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ReturnDuctLoadToPlenum_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ReturnConductionToAHZone_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ReturnLatentLeakage_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ReturnSensibleLeakage_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set LatentLeakageToAHZone_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set SensibleLeakageToAHZone_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("EndIf")
        else
          duct_leakage_subroutine.addLine("Set SupplyLeakLatentLoad_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set SupplyLeakSensibleLoad_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set SupplyDuctLoadToLiving_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ConductionToAHZone_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ReturnDuctLoadToPlenum_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ReturnConductionToAHZone_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ReturnLatentLeakage_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set ReturnSensibleLeakage_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set LatentLeakageToAHZone_#{unit.unit_num} = 0")
          duct_leakage_subroutine.addLine("Set SensibleLeakageToAHZone_#{unit.unit_num} = 0")
        end      
      
        # Program

        duct_leakage_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
        duct_leakage_program.setName("DuctLeakageProgram_#{unit.unit_num}")
        duct_leakage_program.addLine("Set AH_MFR_#{unit.unit_num} = AH_MFR_Sensor_#{unit.unit_num}")
        duct_leakage_program.addLine("Set Fan_RTF_#{unit.unit_num} = Fan_RTF_Sensor_#{unit.unit_num}")
        duct_leakage_program.addLine("Set AH_VFR_#{unit.unit_num} = AH_VFR_Sensor_#{unit.unit_num}")
        duct_leakage_program.addLine("Set AH_Tout_#{unit.unit_num} = AH_Tout_Sensor_#{unit.unit_num}")
        duct_leakage_program.addLine("Set AH_Wout_#{unit.unit_num} = AH_Wout_Sensor_#{unit.unit_num}")
        duct_leakage_program.addLine("Set RA_T_#{unit.unit_num} = RA_T_Sensor_#{unit.unit_num}")
        duct_leakage_program.addLine("Set RA_W_#{unit.unit_num} = RA_W_Sensor_#{unit.unit_num}")
        duct_leakage_program.addLine("Set AHZone_T_#{unit.unit_num} = AHZone_T_Sensor_#{unit.unit_num}")
        duct_leakage_program.addLine("Set AHZone_W_#{unit.unit_num} = AHZone_W_Sensor_#{unit.unit_num}")
        duct_leakage_program.addLine("Run CalculateDuctLeakage_#{unit.unit_num}")
        duct_leakage_program.addLine("Set SupplyLeakSensibleActuator_#{unit.unit_num} = SupplyLeakSensibleLoad_#{unit.unit_num}")
        duct_leakage_program.addLine("Set SupplyLeakLatentActuator_#{unit.unit_num} = SupplyLeakLatentLoad_#{unit.unit_num}")
        duct_leakage_program.addLine("Set SupplyDuctLoadToLivingActuator_#{unit.unit_num} = SupplyDuctLoadToLiving_#{unit.unit_num}")
        duct_leakage_program.addLine("Set ConductionToAHZoneActuator_#{unit.unit_num} = ConductionToAHZone_#{unit.unit_num}")
        duct_leakage_program.addLine("Set SensibleLeakageToAHZoneActuator_#{unit.unit_num} = SensibleLeakageToAHZone_#{unit.unit_num}")
        duct_leakage_program.addLine("Set LatentLeakageToAHZoneActuator_#{unit.unit_num} = LatentLeakageToAHZone_#{unit.unit_num}")
        duct_leakage_program.addLine("Set ReturnSensibleLeakageActuator_#{unit.unit_num} = ReturnSensibleLeakage_#{unit.unit_num}")
        duct_leakage_program.addLine("Set ReturnLatentLeakageActuator_#{unit.unit_num} = ReturnLatentLeakage_#{unit.unit_num}")
        duct_leakage_program.addLine("Set ReturnDuctLoadToPlenumActuator_#{unit.unit_num} = ReturnDuctLoadToPlenum_#{unit.unit_num}")
        duct_leakage_program.addLine("Set ReturnConductionToAHZoneActuator_#{unit.unit_num} = ReturnConductionToAHZone_#{unit.unit_num}")
        duct_leakage_program.addLine("Set AHZoneToLivingFlowRateActuator_#{unit.unit_num} = AHZoneToLivingFlowRate_#{unit.unit_num}")
        duct_leakage_program.addLine("Set LivingToAHZoneFlowRateActuator_#{unit.unit_num} = LivingToAHZoneFlowRate_#{unit.unit_num}")
        
        # Return Plenum
        
      else # no ducts
      
        # Program
        
        duct_leakage_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
        duct_leakage_program.setName("DuctLeakageProgram_#{unit.unit_num}")
        duct_leakage_program.addLine("Set DuctLeakSupplyFanEquivalent_#{unit.unit_num} = 0")
        duct_leakage_program.addLine("Set DuctLeakExhaustFanEquivalent_#{unit.unit_num} = 0")
      
        # Zone Mixer
      
      end # end has ducts loop
      
      # Global Variables
      
      ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "DuctLeakSupplyFanEquivalent_#{unit.unit_num}")
      ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "DuctLeakExhaustFanEquivalent_#{unit.unit_num}")
    
      # Program Calling Manager
      
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName("DuctLeakageCallingManager_#{unit.unit_num}")
      program_calling_manager.setCallingPoint("EndOfSystemTimestepAfterHVACReporting")
      program_calling_manager.addProgram(duct_leakage_program)
      
    end # end unit loop

    terrain = {Constants.TerrainOcean=>"Ocean",      # Ocean, Bayou flat country
               Constants.TerrainPlains=>"Country",   # Flat, open country
               Constants.TerrainRural=>"Country",    # Flat, open country
               Constants.TerrainSuburban=>"Suburbs", # Rough, wooded country, suburbs
               Constants.TerrainCity=>"City"}        # Towns, city outskirts, center of large cities
    model.getSite.setTerrain(terrain[terrainType]) 
    
    model.getScheduleDays.each do |obj| # remove any orphaned day schedules
      next if obj.directUseCount > 0
      obj.remove
    end
    
    return true

  end
  
  def _processWindSpeedCorrection(infil, wind_speed, terrain_type, neighbors_min_nonzero_offset, building)
    # Wind speed correction
    wind_speed.height = 32.8 # ft (Standard weather station height)
    
    # Open, Unrestricted at Weather Station
    wind_speed.terrain_multiplier = 1.0 # Used for DOE-2's correlation
    wind_speed.terrain_exponent = 0.15 # Used for DOE-2's correlation
    wind_speed.ashrae_terrain_thickness = 270
    wind_speed.ashrae_terrain_exponent = 0.14
    
    if terrain_type == Constants.TerrainOcean
      wind_speed.site_terrain_multiplier = 1.30 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.10 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 210 # Ocean, Bayou flat country
      wind_speed.ashrae_site_terrain_exponent = 0.10 # Ocean, Bayou flat country
    elsif terrain_type == Constants.TerrainPlains
      wind_speed.site_terrain_multiplier = 1.00 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.15 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 270 # Flat, open country
      wind_speed.ashrae_site_terrain_exponent = 0.14 # Flat, open country
    elsif terrain_type == Constants.TerrainRural
      wind_speed.site_terrain_multiplier = 0.85 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.20 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 270 # Flat, open country
      wind_speed.ashrae_site_terrain_exponent = 0.14 # Flat, open country
    elsif terrain_type == Constants.TerrainSuburban
      wind_speed.site_terrain_multiplier = 0.67 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.25 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 370 # Rough, wooded country, suburbs
      wind_speed.ashrae_site_terrain_exponent = 0.22 # Rough, wooded country, suburbs
    elsif terrain_type == Constants.TerrainCity
      wind_speed.site_terrain_multiplier = 0.47 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.35 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 460 # Towns, city outskirs, center of large cities
      wind_speed.ashrae_site_terrain_exponent = 0.33 # Towns, city outskirs, center of large cities 
    end
    
    # Local Shielding
    if infil.InfiltrationShelterCoefficient == Constants.Auto
      if neighbors_min_nonzero_offset == 0
        # Typical shelter for isolated rural house
        wind_speed.S_wo = 0.90
      elsif neighbors_min_nonzero_offset > building.building_height
        # Typical shelter caused by other building across the street
        wind_speed.S_wo = 0.70
      else
        # Typical shelter for urban buildings where sheltering obstacles
        # are less than one building height away.
        # Recommended by C.Christensen.
        wind_speed.S_wo = 0.50
      end
    else
      wind_speed.S_wo = infil.InfiltrationShelterCoefficient.to_f
    end

    # S-G Shielding Coefficients are roughly 1/3 of AIM2 Shelter Coefficients
    wind_speed.shielding_coef = wind_speed.S_wo / 3.0
        
    return wind_speed
    
  end
  
  def _processInfiltration(infil, wind_speed, building)
  
    spaces = []
    unless building.garage_zone.nil?
      spaces << building.garage
    end
    unless building.unfinished_basement_zone.nil?
      spaces << building.unfinished_basement
    end
    unless building.crawlspace_zone.nil?
      spaces << building.crawlspace
    end
    unless building.unfinished_attic_zone.nil?
      spaces << building.unfinished_attic
    end 
  
    unless building.garage_zone.nil?
      building.garage.inf_method = Constants.InfMethodSG
      building.garage.hor_leak_frac = 0.4 # DOE-2 Default
      building.garage.neutral_level = 0.5 # DOE-2 Default
      building.garage.SLA = get_infiltration_SLA_from_ACH50(infil.InfiltrationGarageACH50, 0.67, building.garage.area, building.garage.volume)
      building.garage.ACH = get_infiltration_ACH_from_SLA(building.garage.SLA, 1.0)
      building.garage.inf_flow = building.garage.ACH / OpenStudio::convert(1.0,"hr","min").get * building.garage.volume # cfm          
    end

    unless building.unfinished_basement_zone.nil?
      building.unfinished_basement.inf_method = Constants.InfMethodRes # Used for constant ACH
      building.unfinished_basement.inf_flow = building.unfinished_basement.ACH / OpenStudio::convert(1.0,"hr","min").get * building.unfinished_basement.volume
    end

    unless building.crawlspace_zone.nil?
      building.crawlspace.inf_method = Constants.InfMethodRes
      building.crawlspace.inf_flow = building.crawlspace.ACH / OpenStudio::convert(1.0,"hr","min").get * building.crawlspace.volume
    end

    unless building.unfinished_attic_zone.nil?
      building.unfinished_attic.inf_method = Constants.InfMethodSG
      building.unfinished_attic.hor_leak_frac = 0.75 # Same as Energy Gauge USA Attic Model
      building.unfinished_attic.neutral_level = 0.5 # DOE-2 Default
      building.unfinished_attic.ACH = get_infiltration_ACH_from_SLA(building.unfinished_attic.SLA, 1.0)
      building.unfinished_attic.inf_flow = building.unfinished_attic.ACH / OpenStudio::convert(1.0,"hr","min").get * building.unfinished_attic.volume
    end
  
    spaces.each do |space|
    
      if space.volume == 0
        next
      end
      
      space.f_t_SG = wind_speed.site_terrain_multiplier * ((space.height + space.coord_z) / 32.8) ** wind_speed.site_terrain_exponent / (wind_speed.terrain_multiplier * (wind_speed.height / 32.8) ** wind_speed.terrain_exponent)

      if space.inf_method == Constants.InfMethodSG
        space.f_s_SG = 2.0 / 3.0 * (1 + space.hor_leak_frac / 2.0) * (2.0 * space.neutral_level * (1.0 - space.neutral_level)) ** 0.5 / (space.neutral_level ** 0.5 + (1.0 - space.neutral_level) ** 0.5)
        space.f_w_SG = wind_speed.shielding_coef * (1.0 - space.hor_leak_frac) ** (1.0 / 3.0) * space.f_t_SG
        space.C_s_SG = space.f_s_SG ** 2.0 * Constants.g * space.height / (Constants.AssumedInsideTemp + 460.0)
        space.C_w_SG = space.f_w_SG ** 2.0
        space.ELA = space.SLA * space.area # ft^2
      end

    end
    
    return infil, building  
  
  end
  
  def _processInfiltrationForUnit(infil, wind_speed, building, unit, has_flue, runner)
    # Infiltration calculations.
    
    spaces = []
    spaces << unit.living
    unless unit.finished_basement_zone.nil?
      spaces << unit.finished_basement
    end
  
    outside_air_density = UnitConversion.atm2Btu_ft3(@weather.header.LocalPressure) / (Gas.Air.r * (@weather.data.AnnualAvgDrybulb + 460.0))
    inf_conv_factor = 776.25 # [ft/min]/[inH2O^(1/2)*ft^(3/2)/lbm^(1/2)]
    delta_pref = 0.016 # inH2O

    # Assume an average inside temperature
    infil.assumed_inside_temp = Constants.AssumedInsideTemp # deg F, used other places. Make available.  
  
    if not infil.InfiltrationLivingSpaceACH50.nil?
      if unit.living.volume == 0
          unit.living.SLA = 0
          unit.living.ELA = 0
          unit.living.ACH = 0
          unit.living.inf_flow = 0
      else
          # Living Space Infiltration
          unit.living.inf_method = Constants.InfMethodASHRAE

          # Based on "Field Validation of Algebraic Equations for Stack and
          # Wind Driven Air Infiltration Calculations" by Walker and Wilson (1998)

          # Pressure Exponent
          infil.n_i = 0.67
          
          # Calculate SLA for above-grade portion of the building
          building.SLA = get_infiltration_SLA_from_ACH50(infil.InfiltrationLivingSpaceACH50, infil.n_i, building.above_grade_finished_floor_area, building.above_grade_volume)

          # Effective Leakage Area (ft^2)
          infil.A_o = building.SLA * building.above_grade_finished_floor_area * (unit.above_grade_exterior_wall_area/building.above_grade_exterior_wall_area)

          # Calculate SLA for unit
          unit.living.SLA = infil.A_o / unit.above_grade_finished_floor_area
    
          # Flow Coefficient (cfm/inH2O^n) (based on ASHRAE HoF)
          infil.C_i = infil.A_o * (2.0 / outside_air_density) ** 0.5 * delta_pref ** (0.5 - infil.n_i) * inf_conv_factor

          if has_flue
            infil.Y_i = 0.2 # Fraction of leakage through the flue; 0.2 is a "typical" value according to THE ALBERTA AIR INFIL1RATION MODEL, Walker and Wilson, 1990
            infil.flue_height = building.building_height + 2.0 # ft
            infil.S_wflue = 1.0 # Flue Shelter Coefficient
          else
            infil.Y_i = 0.0 # Fraction of leakage through the flu
            infil.flue_height = 0.0 # ft
            infil.S_wflue = 0.0 # Flue Shelter Coefficient
          end

          # Leakage distributions per Iain Walker (LBL) recommendations
          if not building.crawlspace_zone.nil? and building.crawlspace.ACH > 0
            # 15% ceiling, 35% walls, 50% floor leakage distribution for vented crawl
            leakage_ceiling = 0.15
            leakage_walls = 0.35
            leakage_floor = 0.50
          else
            # 25% ceiling, 50% walls, 25% floor leakage distribution for slab/basement/unvented crawl
            leakage_ceiling = 0.25
            leakage_walls = 0.50
            leakage_floor = 0.25          
          end
          if leakage_ceiling + leakage_walls + leakage_floor != 1
            runner.registerError("Invalid air leakage distribution specified (#{leakage_ceiling}, #{leakage_walls}, #{leakage_floor}); does not add up to 1.")
            return false
          end
          infil.R_i = (leakage_ceiling + leakage_floor)
          infil.X_i = (leakage_ceiling - leakage_floor)
          infil.R_i = infil.R_i * (1 - infil.Y_i)
          infil.X_i = infil.X_i * (1 - infil.Y_i)         
          
          unit.living.hor_leak_frac = infil.R_i
          infil.Z_f = infil.flue_height / (unit.living.height + unit.living.coord_z)

          # Calculate Stack Coefficient
          infil.M_o = (infil.X_i + (2.0 * infil.n_i + 1.0) * infil.Y_i) ** 2.0 / (2 - infil.R_i)

          if infil.M_o <= 1.0
            infil.M_i = infil.M_o # eq. 10
          else
            infil.M_i = 1.0 # eq. 11
          end

          if has_flue
            # Eq. 13
            infil.X_c = infil.R_i + (2.0 * (1.0 - infil.R_i - infil.Y_i)) / (infil.n_i + 1.0) - 2.0 * infil.Y_i * (infil.Z_f - 1.0) ** infil.n_i
            # Additive flue function, Eq. 12
            infil.F_i = infil.n_i * infil.Y_i * (infil.Z_f - 1.0) ** ((3.0 * infil.n_i - 1.0) / 3.0) * (1.0 - (3.0 * (infil.X_c - infil.X_i) ** 2.0 * infil.R_i ** (1 - infil.n_i)) / (2.0 * (infil.Z_f + 1.0)))
          else
            # Critical value of ceiling-floor leakage difference where the
            # neutral level is located at the ceiling (eq. 13)
            infil.X_c = infil.R_i + (2.0 * (1.0 - infil.R_i - infil.Y_i)) / (infil.n_i + 1.0)
            # Additive flue function (eq. 12)
            infil.F_i = 0.0
          end

          infil.f_s = ((1.0 + infil.n_i * infil.R_i) / (infil.n_i + 1.0)) * (0.5 - 0.5 * infil.M_i ** (1.2)) ** (infil.n_i + 1.0) + infil.F_i

          infil.stack_coef = infil.f_s * (UnitConversion.lbm_fts22inH2O(outside_air_density * Constants.g * unit.living.height) / (infil.assumed_inside_temp + 460.0)) ** infil.n_i # inH2O^n/R^n

          # Calculate wind coefficient
          if not building.crawlspace_zone.nil? and building.crawlspace.ACH > 0

            if infil.X_i > 1.0 - 2.0 * infil.Y_i
              # Critical floor to ceiling difference above which f_w does not change (eq. 25)
              infil.X_i = 1.0 - 2.0 * infil.Y_i
            end

            # Redefined R for wind calculations for houses with crawlspaces (eq. 21)
            infil.R_x = 1.0 - infil.R_i * (infil.n_i / 2.0 + 0.2)
            # Redefined Y for wind calculations for houses with crawlspaces (eq. 22)
            infil.Y_x = 1.0 - infil.Y_i / 4.0
            # Used to calculate X_x (eq.24)
            infil.X_s = (1.0 - infil.R_i) / 5.0 - 1.5 * infil.Y_i
            # Redefined X for wind calculations for houses with crawlspaces (eq. 23)
            infil.X_x = 1.0 - (((infil.X_i - infil.X_s) / (2.0 - infil.R_i)) ** 2.0) ** 0.75
            # Wind factor (eq. 20)
            infil.f_w = 0.19 * (2.0 - infil.n_i) * infil.X_x * infil.R_x * infil.Y_x

          else

            infil.J_i = (infil.X_i + infil.R_i + 2.0 * infil.Y_i) / 2.0
            infil.f_w = 0.19 * (2.0 - infil.n_i) * (1.0 - ((infil.X_i + infil.R_i) / 2.0) ** (1.5 - infil.Y_i)) - infil.Y_i / 4.0 * (infil.J_i - 2.0 * infil.Y_i * infil.J_i ** 4.0)

          end

          infil.wind_coef = infil.f_w * UnitConversion.lbm_ft32inH2O_mph2(outside_air_density / 2.0) ** infil.n_i # inH2O^n/mph^2n

          unit.living.ACH = get_infiltration_ACH_from_SLA(unit.living.SLA, building.stories)

          # Convert living space ACH to cfm:
          unit.living.inf_flow = unit.living.ACH / OpenStudio::convert(1.0,"hr","min").get * unit.living.volume # cfm
          
      end
          
    end
    
    unless unit.finished_basement_zone.nil?
      unit.finished_basement.inf_method = Constants.InfMethodRes # Used for constant ACH
      unit.finished_basement.inf_flow = unit.finished_basement.ACH / OpenStudio::convert(1.0,"hr","min").get * unit.finished_basement.volume
    end

    spaces.each do |space|
    
      if space.volume == 0
        next
      end
      
      space.f_t_SG = wind_speed.site_terrain_multiplier * ((space.height + space.coord_z) / 32.8) ** wind_speed.site_terrain_exponent / (wind_speed.terrain_multiplier * (wind_speed.height / 32.8) ** wind_speed.terrain_exponent)

      if space.inf_method == Constants.InfMethodSG
        space.f_s_SG = 2.0 / 3.0 * (1 + space.hor_leak_frac / 2.0) * (2.0 * space.neutral_level * (1.0 - space.neutral_level)) ** 0.5 / (space.neutral_level ** 0.5 + (1.0 - space.neutral_level) ** 0.5)
        space.f_w_SG = wind_speed.shielding_coef * (1.0 - space.hor_leak_frac) ** (1.0 / 3.0) * space.f_t_SG
        space.C_s_SG = space.f_s_SG ** 2.0 * Constants.g * space.height / (infil.assumed_inside_temp + 460.0)
        space.C_w_SG = space.f_w_SG ** 2.0
        space.ELA = space.SLA * space.area # ft^2
      end

    end
    
    return infil, building, unit
    
  end  
  
  def _processMechanicalVentilation(model, runner, infil, mech_vent, building, unit, schedules)
    # Mechanical Ventilation

    # Get ASHRAE 62.2 required ventilation rate (excluding infiltration credit)
    ashrae_mv_without_infil_credit = get_mech_vent_whole_house_cfm(1, unit.num_bedrooms, unit.finished_floor_area, mech_vent.MechVentASHRAEStandard) 
    
    # Determine mechanical ventilation infiltration credit (per ASHRAE 62.2)
    infil.rate_credit = 0 # default to no credit
    if mech_vent.MechVentInfilCredit
        if mech_vent.MechVentASHRAEStandard == '2010' and unit.age_of_home > 0
            # ASHRAE Standard 62.2 2010
            # Only applies to existing buildings
            # 2 cfm per 100ft^2 of occupiable floor area
            infil.default_rate = 2.0 * unit.finished_floor_area / 100.0 # cfm
            # Half the excess infiltration rate above the default rate is credited toward mech vent:
            infil.rate_credit = [(unit.living.inf_flow - infil.default_rate) / 2.0, 0].max          
        elsif mech_vent.MechVentASHRAEStandard == '2013' and building.num_units == 1
            # ASHRAE Standard 62.2 2013
            # Only applies to single-family homes (Section 8.2.1: "The required mechanical ventilation 
            # rate shall not be reduced as described in Section 4.1.3.").     
            ela = infil.A_o # Effective leakage area, ft^2
            nl = 1000.0 * ela / unit.living.area * (unit.living.height / 8.2) ** 0.4 # Normalized leakage, eq. 4.4
            qinf = nl * @weather.data.WSF * unit.living.area / 7.3 # Effective annual average infiltration rate, cfm, eq. 4.5a
            infil.rate_credit = [(2.0 / 3.0) * ashrae_mv_without_infil_credit, qinf].min
        end
    end
    
    # Apply infiltration credit (if any)
    mech_vent.ashrae_vent_rate = [ashrae_mv_without_infil_credit - infil.rate_credit, 0.0].max # cfm
    # Apply fraction of ASHRAE value
    mech_vent.whole_house_vent_rate = mech_vent.MechVentFractionOfASHRAE * mech_vent.ashrae_vent_rate # cfm    

    # Spot Ventilation
    mech_vent.MechVentBathroomExhaust = 50.0 # cfm, per HSP
    mech_vent.MechVentRangeHoodExhaust = 100.0 # cfm, per HSP
    mech_vent.MechVentSpotFanPower = 0.3 # W/cfm/fan, per HSP

    mech_vent.bath_exhaust_operation = 60.0 # min/day, per HSP
    mech_vent.range_hood_exhaust_operation = 60.0 # min/day, per HSP
    mech_vent.clothes_dryer_exhaust_operation = 60.0 # min/day, per HSP

    if mech_vent.MechVentType == Constants.VentTypeExhaust
        mech_vent.num_vent_fans = 1 # One fan for unbalanced airflow
    elsif mech_vent.MechVentType == Constants.VentTypeSupply
        mech_vent.num_vent_fans = 1 # One fan for unbalanced airflow
    elsif mech_vent.MechVentType == Constants.VentTypeBalanced
        mech_vent.num_vent_fans = 2 # Two fans for balanced airflow
    else
        mech_vent.num_vent_fans = 1 # Default to one fan
    end

    if mech_vent.MechVentType == Constants.VentTypeExhaust
      mech_vent.percent_fan_heat_to_space = 0.0 # Fan heat does not enter space
    elsif mech_vent.MechVentType == Constants.VentTypeSupply
      mech_vent.percent_fan_heat_to_space = 1.0 # Fan heat does enter space
    elsif mech_vent.MechVentType == Constants.VentTypeBalanced
      mech_vent.percent_fan_heat_to_space = 0.5 # Assumes supply fan heat enters space
    else
      mech_vent.percent_fan_heat_to_space = 0.0
    end

    mech_vent.bathroom_hour_avg_exhaust = mech_vent.MechVentBathroomExhaust * unit.num_bathrooms * mech_vent.bath_exhaust_operation / 60.0 # cfm
    mech_vent.range_hood_hour_avg_exhaust = mech_vent.MechVentRangeHoodExhaust * mech_vent.range_hood_exhaust_operation / 60.0 # cfm
    mech_vent.clothes_dryer_hour_avg_exhaust = unit.dryer_exhaust * mech_vent.clothes_dryer_exhaust_operation / 60.0 # cfm

    mech_vent.max_power = [mech_vent.bathroom_hour_avg_exhaust * mech_vent.MechVentSpotFanPower + mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans, mech_vent.range_hood_hour_avg_exhaust * mech_vent.MechVentSpotFanPower + mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans].max / OpenStudio::convert(1.0,"kW","W").get # kW

    # Fan energy schedule (as fraction of maximum power). Bathroom
    # exhaust at 7:00am and range hood exhaust at 6:00pm. Clothes
    # dryer exhaust not included in mech vent power.
    if mech_vent.max_power > 0
      mech_vent.hourly_energy_schedule = Array.new(24, mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans / OpenStudio::convert(1.0,"kW","W").get / mech_vent.max_power)
      mech_vent.hourly_energy_schedule[6] = ((mech_vent.bathroom_hour_avg_exhaust * mech_vent.MechVentSpotFanPower + mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans) / OpenStudio::convert(1.0,"kW","W").get / mech_vent.max_power)
      mech_vent.hourly_energy_schedule[17] = ((mech_vent.range_hood_hour_avg_exhaust * mech_vent.MechVentSpotFanPower + mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans) / OpenStudio::convert(1.0,"kW","W").get / mech_vent.max_power)
      mech_vent.average_vent_fan_eff = ((mech_vent.whole_house_vent_rate * 24.0 * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans + (mech_vent.bathroom_hour_avg_exhaust + mech_vent.range_hood_hour_avg_exhaust) * mech_vent.MechVentSpotFanPower) / (mech_vent.whole_house_vent_rate * 24.0 + mech_vent.bathroom_hour_avg_exhaust + mech_vent.range_hood_hour_avg_exhaust))
    else
      mech_vent.hourly_energy_schedule = Array.new(24, 0.0)
    end   
    
    schedules.MechanicalVentilationEnergy = HourlyByMonthSchedule.new(model, runner, "MechanicalVentilationEnergy_#{unit.unit_num}", [mech_vent.hourly_energy_schedule] * 12, [mech_vent.hourly_energy_schedule] * 12, normalize_values=false)
    
    mech_vent.base_vent_rate = mech_vent.whole_house_vent_rate * (1.0 - mech_vent.MechVentTotalEfficiency)
    mech_vent.max_vent_rate = [mech_vent.bathroom_hour_avg_exhaust, mech_vent.range_hood_hour_avg_exhaust, mech_vent.clothes_dryer_hour_avg_exhaust].max + mech_vent.base_vent_rate

    # Ventilation schedule (as fraction of maximum flow). Assume bathroom
    # exhaust at 7:00am, range hood exhaust at 6:00pm, and clothes dryer
    # exhaust at 11am.
    if mech_vent.max_vent_rate > 0
      mech_vent.hourly_schedule = Array.new(24, mech_vent.base_vent_rate / mech_vent.max_vent_rate)
      mech_vent.hourly_schedule[6] = (mech_vent.bathroom_hour_avg_exhaust + mech_vent.base_vent_rate) / mech_vent.max_vent_rate
      mech_vent.hourly_schedule[10] = (mech_vent.clothes_dryer_hour_avg_exhaust + mech_vent.base_vent_rate) / mech_vent.max_vent_rate
      mech_vent.hourly_schedule[17] = (mech_vent.range_hood_hour_avg_exhaust + mech_vent.base_vent_rate) / mech_vent.max_vent_rate
    else
      mech_vent.hourly_schedule = Array.new(24, 0.0)
    end

    schedules.MechanicalVentilation = HourlyByMonthSchedule.new(model, runner, "MechanicalVentilationSchedule_#{unit.unit_num}", [mech_vent.hourly_schedule] * 12, [mech_vent.hourly_schedule] * 12, normalize_values=false)

    bath_exhaust_hourly = Array.new(24, 0.0)
    bath_exhaust_hourly[6] = 1.0

    schedules.BathExhaust = HourlyByMonthSchedule.new(model, runner, "BathExhaust_#{unit.unit_num}", [bath_exhaust_hourly] * 12, [bath_exhaust_hourly] * 12, normalize_values=false)

    clothes_dryer_exhaust_hourly = Array.new(24, 0.0)
    clothes_dryer_exhaust_hourly[10] = 1.0

    schedules.ClothesDryerExhaust = HourlyByMonthSchedule.new(model, runner, "ClothesDryerExhaust_#{unit.unit_num}", [clothes_dryer_exhaust_hourly] * 12, [clothes_dryer_exhaust_hourly] * 12, normalize_values=false)

    range_hood_hourly = Array.new(24, 0.0)
    range_hood_hourly[17] = 1.0

    schedules.RangeHood = HourlyByMonthSchedule.new(model, runner, "RangeHood_#{unit.unit_num}", [range_hood_hourly] * 12, [range_hood_hourly] * 12, normalize_values=false)

    #--- Calculate HRV/ERV effectiveness values. Calculated here for use in sizing routines.

    mech_vent.MechVentApparentSensibleEffectiveness = 0.0
    mech_vent.MechVentHXCoreSensibleEffectiveness = 0.0
    mech_vent.MechVentLatentEffectiveness = 0.0

    if mech_vent.MechVentType == Constants.VentTypeBalanced and mech_vent.MechVentSensibleEfficiency > 0 and mech_vent.whole_house_vent_rate > 0
      # Must assume an operating condition (HVI seems to use CSA 439)
      t_sup_in = 0
      w_sup_in = 0.0028
      t_exh_in = 22
      w_exh_in = 0.0065
      cp_a = 1006
      p_fan = mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower # Watts

      m_fan = OpenStudio::convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get * 16.02 * Psychrometrics.rhoD_fT_w_P(OpenStudio::convert(t_sup_in,"C","F").get, w_sup_in, 14.7) # kg/s

      # The following is derived from (taken from CSA 439):
      #    E_SHR = (m_sup,fan * Cp * (Tsup,out - Tsup,in) - P_sup,fan) / (m_exh,fan * Cp * (Texh,in - Tsup,in) + P_exh,fan)
      t_sup_out = t_sup_in + (mech_vent.MechVentSensibleEfficiency * (m_fan * cp_a * (t_exh_in - t_sup_in) + p_fan) + p_fan) / (m_fan * cp_a)

      # Calculate the apparent sensible effectiveness
      mech_vent.MechVentApparentSensibleEffectiveness = (t_sup_out - t_sup_in) / (t_exh_in - t_sup_in)

      # Calculate the supply temperature before the fan
      t_sup_out_gross = t_sup_out - p_fan / (m_fan * cp_a)

      # Sensible effectiveness of the HX only
      mech_vent.MechVentHXCoreSensibleEffectiveness = (t_sup_out_gross - t_sup_in) / (t_exh_in - t_sup_in)

      if (mech_vent.MechVentHXCoreSensibleEffectiveness < 0.0) or (mech_vent.MechVentHXCoreSensibleEffectiveness > 1.0)
        return
      end

      # Use summer test condition to determine the latent effectivess since TRE is generally specified under the summer condition
      if mech_vent.MechVentTotalEfficiency > 0

        t_sup_in = 35.0
        w_sup_in = 0.0178
        t_exh_in = 24.0
        w_exh_in = 0.0092

        m_fan = OpenStudio::convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get * UnitConversion.lbm_ft32kg_m3(Psychrometrics.rhoD_fT_w_P(OpenStudio::convert(t_sup_in,"C","F").get, w_sup_in, 14.7)) # kg/s

        t_sup_out_gross = t_sup_in - mech_vent.MechVentHXCoreSensibleEffectiveness * (t_sup_in - t_exh_in)
        t_sup_out = t_sup_out_gross + p_fan / (m_fan * cp_a)

        h_sup_in = Psychrometrics.h_fT_w_SI(t_sup_in, w_sup_in)
        h_exh_in = Psychrometrics.h_fT_w_SI(t_exh_in, w_exh_in)
        h_sup_out = h_sup_in - (mech_vent.MechVentTotalEfficiency * (m_fan * (h_sup_in - h_exh_in) + p_fan) + p_fan) / m_fan

        w_sup_out = Psychrometrics.w_fT_h_SI(t_sup_out, h_sup_out)
        mech_vent.MechVentLatentEffectiveness = [0.0, (w_sup_out - w_sup_in) / (w_exh_in - w_sup_in)].max

        if (mech_vent.MechVentLatentEffectiveness < 0.0) or (mech_vent.MechVentLatentEffectiveness > 1.0)
          return
        end

      else
        mech_vent.MechVentLatentEffectiveness = 0.0
      end
    else
      if mech_vent.MechVentTotalEfficiency > 0
        mech_vent.MechVentApparentSensibleEffectiveness = mech_vent.MechVentTotalEfficiency
        mech_vent.MechVentHXCoreSensibleEffectiveness = mech_vent.MechVentTotalEfficiency
        mech_vent.MechVentLatentEffectiveness = mech_vent.MechVentTotalEfficiency
      end
    end

    return mech_vent, schedules

  end

  def _processNaturalVentilation(model, runner, nat_vent, wind_speed, infil, building, unit, schedules)    
    
    thermostatsetpointdualsetpoint = unit.living_zone.thermostatSetpointDualSetpoint
    
    # Get heating setpoints
    heatingSetpointWeekday = Array.new(24, -10000)
    heatingSetpointWeekend = Array.new(24, -10000)
    if thermostatsetpointdualsetpoint.is_initialized
      thermostatsetpointdualsetpoint.get.heatingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
        if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value > heatingSetpointWeekday[hour]
              heatingSetpointWeekday[hour] = OpenStudio::convert(value,"C","F").get
            end
          end
        end
        if rule.applySaturday and rule.applySunday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value > heatingSetpointWeekend[hour]
              heatingSetpointWeekend[hour] = OpenStudio::convert(value,"C","F").get
            end
          end
        end
      end
    end
    
    # Get cooling setpoints
    coolingSetpointWeekday = Array.new(24, 10000)
    coolingSetpointWeekend = Array.new(24, 10000)
    if thermostatsetpointdualsetpoint.is_initialized
      thermostatsetpointdualsetpoint.get.coolingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
        if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value < coolingSetpointWeekday[hour]
              coolingSetpointWeekday[hour] = OpenStudio::convert(value,"C","F").get
            end
          end
        end
        if rule.applySaturday and rule.applySunday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value < coolingSetpointWeekend[hour]
              coolingSetpointWeekend[hour] = OpenStudio::convert(value,"C","F").get
            end
          end
        end
      end
    end

    default_htg_sp = 71.0
    default_clg_sp = 76.0
    if heatingSetpointWeekday.all? {|x| x == -10000}
      runner.registerWarning("No heating equipment found. Assuming #{default_htg_sp} F for natural ventilation calculations.")
      nat_vent.ovlp_ssn_hourly_temp = Array.new(24, OpenStudio::convert(default_htg_sp + nat_vent.NatVentOvlpSsnSetpointOffset,"F","C").get)
    else
      nat_vent.ovlp_ssn_hourly_temp = Array.new(24, OpenStudio::convert([heatingSetpointWeekday.max, heatingSetpointWeekend.max].max + nat_vent.NatVentOvlpSsnSetpointOffset,"F","C").get)
    end
    if coolingSetpointWeekday.all? {|x| x == 10000}
      runner.registerWarning("No cooling equipment found. Assuming #{default_clg_sp} F for natural ventilation calculations.")
    end
    nat_vent.ovlp_ssn_hourly_weekend_temp = nat_vent.ovlp_ssn_hourly_temp
      
    # Get heating and cooling seasons
    heating_season, cooling_season = HVAC.calc_heating_and_cooling_seasons(model, @weather, runner)
    if heating_season.nil? or cooling_season.nil?
        return false
    end
  
    # Specify an array of hourly lower-temperature-limits for natural ventilation
    nat_vent.htg_ssn_hourly_temp = Array.new
    coolingSetpointWeekday.each do |x|
      if x == 10000
        nat_vent.htg_ssn_hourly_temp << OpenStudio::convert(default_clg_sp - nat_vent.NatVentHtgSsnSetpointOffset,"F","C").get
      else
        nat_vent.htg_ssn_hourly_temp << OpenStudio::convert(x - nat_vent.NatVentHtgSsnSetpointOffset,"F","C").get
      end
    end
    nat_vent.htg_ssn_hourly_weekend_temp = Array.new
    coolingSetpointWeekend.each do |x|
      if x == 10000
        nat_vent.htg_ssn_hourly_weekend_temp << OpenStudio::convert(default_clg_sp - nat_vent.NatVentHtgSsnSetpointOffset,"F","C").get
      else
        nat_vent.htg_ssn_hourly_weekend_temp << OpenStudio::convert(x - nat_vent.NatVentHtgSsnSetpointOffset,"F","C").get
      end
    end

    nat_vent.clg_ssn_hourly_temp = Array.new
    heatingSetpointWeekday.each do |x|
      if x == -10000
        nat_vent.clg_ssn_hourly_temp << OpenStudio::convert(default_htg_sp + nat_vent.NatVentClgSsnSetpointOffset,"F","C").get
      else
        nat_vent.clg_ssn_hourly_temp << OpenStudio::convert(x + nat_vent.NatVentClgSsnSetpointOffset,"F","C").get
      end
    end
    nat_vent.clg_ssn_hourly_weekend_temp = Array.new
    heatingSetpointWeekend.each do |x|
      if x == -10000
        nat_vent.clg_ssn_hourly_weekend_temp << OpenStudio::convert(default_htg_sp + nat_vent.NatVentClgSsnSetpointOffset,"F","C").get
      else
        nat_vent.clg_ssn_hourly_weekend_temp << OpenStudio::convert(x + nat_vent.NatVentClgSsnSetpointOffset,"F","C").get
      end
    end

    # Explanation for FRAC-VENT-AREA equation:
    # From DOE22 Vol2-Dictionary: For VENT-METHOD=S-G, this is 0.6 times
    # the open window area divided by the floor area.
    # According to 2010 BA Benchmark, 33% of the windows on any facade will
    # be open at any given time and can only be opened to 20% of their area.

    nat_vent.area = 0.6 * unit.window_area * nat_vent.NatVentFractionWindowsOpen * nat_vent.NatVentFractionWindowAreaOpen # ft^2 (For S-G, this is 0.6*(open window area))
    nat_vent.max_rate = 20.0 # Air Changes per hour
    nat_vent.max_flow_rate = nat_vent.max_rate * unit.living.volume / OpenStudio::convert(1.0,"hr","min").get
    nv_neutral_level = 0.5
    nat_vent.hor_vent_frac = 0.0
    f_s_nv = 2.0 / 3.0 * (1.0 + nat_vent.hor_vent_frac / 2.0) * (2.0 * nv_neutral_level * (1 - nv_neutral_level)) ** 0.5 / (nv_neutral_level ** 0.5 + (1 - nv_neutral_level) ** 0.5)
    f_w_nv = wind_speed.shielding_coef * (1 - nat_vent.hor_vent_frac) ** (1.0 / 3.0) * unit.living.f_t_SG
    nat_vent.C_s = f_s_nv ** 2.0 * Constants.g * unit.living.height / (infil.assumed_inside_temp + 460.0)
    nat_vent.C_w = f_w_nv ** 2.0
    
    nat_vent.season_type = []
    (0..11).to_a.each do |month|
      if heating_season[month] == 1.0 and cooling_season[month] == 0.0
        nat_vent.season_type << Constants.SeasonHeating
      elsif heating_season[month] == 0.0 and cooling_season[month] == 1.0
        nat_vent.season_type << Constants.SeasonCooling
      elsif heating_season[month] == 1.0 and cooling_season[month] == 1.0
        nat_vent.season_type << Constants.SeasonOverlap
      else
        nat_vent.season_type << Constants.SeasonNone
      end
    end
      
    nat_vent_temp_hourly_wkdy = []
    nat_vent_temp_hourly_wked = []
    nat_vent.season_type.each_with_index do |ssn_type, month|
      if ssn_type == Constants.SeasonHeating
        ssn_schedule_wkdy = nat_vent.htg_ssn_hourly_temp
        ssn_schedule_wked = nat_vent.htg_ssn_hourly_weekend_temp
      elsif ssn_type == Constants.SeasonCooling
        ssn_schedule_wkdy = nat_vent.clg_ssn_hourly_temp
        ssn_schedule_wked = nat_vent.clg_ssn_hourly_weekend_temp        
      else
        ssn_schedule_wkdy = nat_vent.ovlp_ssn_hourly_temp
        ssn_schedule_wked = nat_vent.ovlp_ssn_hourly_weekend_temp         
      end
      nat_vent_temp_hourly_wkdy << ssn_schedule_wkdy
      nat_vent_temp_hourly_wked << ssn_schedule_wked
    end

    schedules.NatVentTemp = HourlyByMonthSchedule.new(model, runner, "NatVentTemp_#{unit.unit_num}", nat_vent_temp_hourly_wkdy, nat_vent_temp_hourly_wked, normalize_values=false)
    
    schedules.NatVentAvailability = OpenStudio::Model::ScheduleRuleset.new(model)
    schedules.NatVentAvailability.setName("NatVentSchedule_#{unit.unit_num}")

    day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
    
    time = []
    for h in 1..24
      time[h] = OpenStudio::Time.new(0,h,0,0)
    end
    
    (1..12).to_a.each do |m|
      
      date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
      date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
      
      if ((nat_vent.season_type[m-1] == Constants.SeasonHeating and nat_vent.NatVentHeatingSeason) or (nat_vent.season_type[m-1] == Constants.SeasonCooling and nat_vent.NatVentCoolingSeason) or (nat_vent.season_type[m-1] == Constants.SeasonOverlap and nat_vent.NatVentOverlapSeason)) and (nat_vent.NatVentNumberWeekdays + nat_vent.NatVentNumberWeekendDays != 0)
        on_rule = OpenStudio::Model::ScheduleRule.new(schedules.NatVentAvailability)
        on_rule.setName("NatVentAvailability_#{unit.unit_num} NatVentOn ruleset#{m}")
        on_rule_day = on_rule.daySchedule
        on_rule_day.setName("NatVentAvailability_#{unit.unit_num} NatVentOn#{m}")
        for h in 1..24
            on_rule_day.addValue(time[h],1)
        end
        if nat_vent.NatVentNumberWeekdays == 1
          on_rule.setApplyMonday(true)
        elsif nat_vent.NatVentNumberWeekdays == 2
          on_rule.setApplyMonday(true)
          on_rule.setApplyWednesday(true)
        elsif nat_vent.NatVentNumberWeekdays == 3
          on_rule.setApplyMonday(true)
          on_rule.setApplyWednesday(true)
          on_rule.setApplyFriday(true)
        elsif nat_vent.NatVentNumberWeekdays == 4
          on_rule.setApplyMonday(true)
          on_rule.setApplyTuesday(true)
          on_rule.setApplyWednesday(true)
          on_rule.setApplyFriday(true)
        elsif nat_vent.NatVentNumberWeekdays == 5
          on_rule.setApplyMonday(true)
          on_rule.setApplyTuesday(true)
          on_rule.setApplyWednesday(true)
          on_rule.setApplyThursday(true)
          on_rule.setApplyFriday(true)
        end
        if nat_vent.NatVentNumberWeekendDays == 1
          on_rule.setApplySaturday(true)
        elsif nat_vent.NatVentNumberWeekendDays == 2
          on_rule.setApplySaturday(true)
          on_rule.setApplySunday(true)
        end
        on_rule.setStartDate(date_s)
        on_rule.setEndDate(date_e)        
      else
        off_rule = OpenStudio::Model::ScheduleRule.new(schedules.NatVentAvailability)
        off_rule.setName("NatVentAvailability_#{unit.unit_num} NatVentOff#{m}")
        off_rule_day = off_rule.daySchedule
        off_rule_day.setName("NatVentAvailability_#{unit.unit_num} NatVentOff#{m}")
        for h in 1..24
            off_rule_day.addValue(time[h],0)
        end
        off_rule.setApplyMonday(true)
        off_rule.setApplyTuesday(true)
        off_rule.setApplyWednesday(true)
        off_rule.setApplyThursday(true)
        off_rule.setApplyFriday(true)
        off_rule.setApplySaturday(true)
        off_rule.setApplySunday(true)
        off_rule.setStartDate(date_s)
        off_rule.setEndDate(date_e)
      end
    end

    return nat_vent, schedules

  end
  
  def calc_infiltration_w_factor
    # Returns a w factor for infiltration calculations; see ticket #852 for derivation.
    hdd65f = @weather.data.HDD65F
    ws = @weather.data.AnnualAvgWindspeed
    a = 0.36250748
    b = 0.365317169
    c = 0.028902855
    d = 0.050181043
    e = 0.009596674
    f = -0.041567541
    # in ACH
    w = (a + b * hdd65f / 10000.0 + c * (hdd65f / 10000.0) ** 2.0 + d * ws + e * ws ** 2 + f * hdd65f / 10000.0 * ws)
    return w
  end

  def get_infiltration_ACH_from_SLA(sla, numStories)
    # Returns the infiltration annual average ACH given a SLA.
    w = calc_infiltration_w_factor

    # Equation from ASHRAE 119-1998 (using numStories for simplification)
    norm_leakage = 1000.0 * sla * numStories ** 0.3

    # Equation from ASHRAE 136-1993
    return norm_leakage * w
  end  
  
  def get_infiltration_SLA_from_ACH50(ach50, n_i, livingSpaceFloorArea, livingSpaceVolume)
    # Pressure difference between indoors and outdoors, such as during a pressurization test.
    pressure_difference = 50.0 # Pa
    return ((ach50 * 0.2835 * 4.0 ** n_i * livingSpaceVolume) / (livingSpaceFloorArea * OpenStudio::convert(1.0,"ft^2","in^2").get * pressure_difference ** n_i * 60.0))
  end  
  
  def get_mech_vent_whole_house_cfm(frac622, num_beds, ffa, std)
    # Returns the ASHRAE 62.2 whole house mechanical ventilation rate, excluding any infiltration credit.
    if std == '2013'
      return frac622 * ((num_beds + 1.0) * 7.5 + 0.03 * ffa)
    end
    return frac622 * ((num_beds + 1.0) * 7.5 + 0.01 * ffa)
  end  
  
  def get_duct_location(runner, duct_location, building, unit)
    duct_location_zone = true
    duct_location_name = "none"
    if duct_location == Constants.Auto
      if not unit.finished_basement_zone.nil?
        duct_location_zone = unit.finished_basement_zone
        duct_location_name = unit.finished_basement_zone.name.to_s
      elsif not building.unfinished_basement_zone.nil?
        duct_location_zone = building.unfinished_basement_zone
        duct_location_name = building.unfinished_basement_zone.name.to_s
      elsif not building.crawlspace_zone.nil?
        duct_location_zone = building.crawlspace_zone
        duct_location_name = building.crawlspace_zone.name.to_s
      elsif not building.unfinished_attic_zone.nil?
        duct_location_zone = building.unfinished_attic_zone
        duct_location_name = building.unfinished_attic_zone.name.to_s
      elsif not building.garage_zone.nil?
        duct_location_zone = building.garage_zone
        duct_location_name = building.garage_zone.name.to_s
      else
        duct_location_zone = unit.living_zone
        duct_location_name = unit.living_zone.name.to_s
      end
    elsif duct_location == Constants.BasementZone
      if not unit.finished_basement_zone.nil?
        duct_location_zone = unit.finished_basement_zone
        duct_location_name = unit.finished_basement_zone.name.to_s
      elsif not building.unfinished_basement_zone.nil?
        duct_location_zone = building.unfinished_basement_zone
        duct_location_name = building.unfinished_basement_zone.name.to_s
      else
        return false, false
      end
    elsif duct_location == Constants.AtticZone
      if not building.unfinished_attic_zone.nil?
        duct_location_zone = building.unfinished_attic_zone
        duct_location_name = building.unfinished_attic_zone.name.to_s
      else
        duct_location_zone = unit.living_zone
        duct_location_name = unit.living_zone.name.to_s
      end
    end
    return duct_location_zone, duct_location_name
  end  
  
  def get_duct_num_returns(duct_num_returns, num_stories)
    if duct_num_returns.nil?
      return 0
    elsif duct_num_returns == Constants.Auto
      # Duct Number Returns per 2010 BA Benchmark Addendum
      return 1 + num_stories
    end
    return duct_num_returns
  end  
  
  def get_duct_supply_surface_area(mult, unit, num_stories)
    # Duct Surface Areas per 2010 BA Benchmark
    ffa = unit.finished_floor_area
    if num_stories == 1
      return 0.27 * ffa * mult # ft^2
    else
      return 0.2 * ffa * mult
    end
  end
  
  def get_duct_return_surface_area(mult, unit, num_stories, duct_num_returns)
    # Duct Surface Areas per 2010 BA Benchmark
    ffa = unit.finished_floor_area
    if num_stories == 1
      return [0.05 * duct_num_returns * ffa, 0.25 * ffa].min * mult
    else
      return [0.04 * duct_num_returns * ffa, 0.19 * ffa].min * mult
    end
  end
  
  def get_duct_insulation_rvalue(nominalR, isSupply)
    # Insulated duct values based on "True R-Values of Round Residential Ductwork" 
    # by Palmiter & Kruse 2006. Linear extrapolation from SEEM's "DuctTrueRValues"
    # worksheet in, e.g., ExistingResidentialSingleFamily_SEEMRuns_v05.xlsm.
    #
    # Nominal | 4.2 | 6.0 | 8.0 | 11.0
    # --------|-----|-----|-----|----
    # Supply  | 4.5 | 5.7 | 6.8 | 8.4
    # Return  | 4.9 | 6.3 | 7.8 | 9.7
    #
    # Uninsulated ducts are set to R-1.7 based on ASHRAE HOF and the above paper.
    if nominalR <= 0
      return 1.7
    end
    if isSupply
      return 2.2438 + 0.5619*nominalR
    else
      return 2.0388 + 0.7053*nominalR
    end
  end
  
end

# register the measure to be used by the application
ResidentialAirflow.new.registerWithApplication
