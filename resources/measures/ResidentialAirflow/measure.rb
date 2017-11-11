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
require "#{File.dirname(__FILE__)}/resources/airflow"

# start the measure
class ResidentialAirflow < OpenStudio::Measure::ModelMeasure

  class Ducts
    def initialize(ductTotalLeakage, ductNormLeakageToOutside, ductSupplySurfaceAreaMultiplier, ductReturnSurfaceAreaMultiplier, ductRvalue, ductSupplyLeakageFractionOfTotal, ductReturnLeakageFractionOfTotal, ductAHSupplyLeakageFractionOfTotal, ductAHReturnLeakageFractionOfTotal, ductSystemEfficiency, ductLocationFrac, ductNumReturns, ductLocation)
      @DuctTotalLeakage = ductTotalLeakage
      @DuctNormLeakageToOutside = ductNormLeakageToOutside
      @DuctSupplySurfaceAreaMultiplier = ductSupplySurfaceAreaMultiplier
      @DuctReturnSurfaceAreaMultiplier = ductReturnSurfaceAreaMultiplier
      @DuctRvalue = ductRvalue
      @DuctSupplyLeakageFractionOfTotal = ductSupplyLeakageFractionOfTotal
      @DuctReturnLeakageFractionOfTotal = ductReturnLeakageFractionOfTotal
      @DuctAHSupplyLeakageFractionOfTotal = ductAHSupplyLeakageFractionOfTotal
      @DuctAHReturnLeakageFractionOfTotal = ductAHReturnLeakageFractionOfTotal
      @DuctSystemEfficiency = ductSystemEfficiency
      @DuctLocationFrac = ductLocationFrac
      @DuctNumReturns = ductNumReturns
      @DuctLocation = ductLocation
    end
    attr_accessor(:DuctTotalLeakage, :DuctNormLeakageToOutside, :DuctSupplySurfaceAreaMultiplier, :DuctReturnSurfaceAreaMultiplier, :DuctRvalue, :DuctSupplyLeakageFractionOfTotal, :DuctReturnLeakageFractionOfTotal, :DuctAHSupplyLeakageFractionOfTotal, :DuctAHReturnLeakageFractionOfTotal, :DuctSystemEfficiency, :duct_location_zone, :duct_location_name, :has_ducts, :ducts_not_in_living, :num_stories, :num_stories_for_ducts, :DuctLocationFrac, :DuctLocationFracLeakage, :DuctLocationFracConduction, :DuctSupplyLeakageFractionOfTotal, :DuctReturnLeakageFractionOfTotal, :DuctAHSupplyLeakageFractionOfTotal, :DuctAHReturnLeakageFractionOfTotal, :DuctSupplyLeakage, :DuctReturnLeakage, :DuctAHSupplyLeakage, :DuctAHReturnLeakage, :DuctNumReturns, :supply_duct_surface_area, :return_duct_surface_area, :unconditioned_duct_area, :supply_duct_r, :return_duct_r, :unconditioned_duct_ua, :return_duct_ua, :supply_duct_volume, :return_duct_volume, :direct_oa_supply_duct_loss, :supply_duct_loss, :return_duct_loss, :supply_lk_oper, :return_lk_oper, :ah_supply_lk_oper, :ah_return_lk_oper, :total_duct_unbalance, :frac_oa, :oa_duct_makeup, :has_forced_air_equipment, :DuctLocationFrac, :DuctNumReturns, :DuctLocation)
  end

  class Infiltration
    def initialize(infiltrationLivingSpaceACH50, infiltrationShelterCoefficient, infiltrationGarageACH50)
      @InfiltrationLivingSpaceACH50 = infiltrationLivingSpaceACH50
      @InfiltrationShelterCoefficient = infiltrationShelterCoefficient
      @InfiltrationGarageACH50 = infiltrationGarageACH50
    end
    attr_accessor(:InfiltrationLivingSpaceACH50, :InfiltrationShelterCoefficient, :InfiltrationGarageACH50, :assumed_inside_temp, :n_i, :A_o, :C_i, :Y_i, :flue_height, :S_wflue, :R_i, :X_i, :Z_f, :M_o, :M_i, :X_c, :F_i, :f_s, :stack_coef, :R_x, :Y_x, :X_s, :X_x, :f_w, :J_i, :f_w, :wind_coef, :default_rate, :rate_credit)
  end

  class LivingSpace
    def initialize(height, area, volume, coord_z)
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z
    end
    attr_accessor(:height, :area, :volume, :coord_z, :inf_method, :SLA, :ACH, :inf_flow, :hor_lk_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class Garage
    def initialize(height, area, volume, coord_z)
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z       
    end
    attr_accessor(:height, :area, :volume, :coord_z, :inf_method, :SLA, :ACH, :inf_flow, :hor_lk_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class FinBasement
    def initialize(ach, height, area, volume, coord_z)
      @ACH = ach      
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z
    end
    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_lk_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class UnfinBasement
    def initialize(ach, height, area, volume, coord_z)
      @ACH = ach      
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z      
    end
    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_lk_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class Crawl
    def initialize(ach, height, area, volume, coord_z)
      @ACH = ach    
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z      
    end
    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_lk_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class PierBeam
    def initialize(ach, height, area, volume, coord_z)
      @ACH = ach    
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z      
    end
    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_lk_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class UnfinAttic
    def initialize(sla, height, area, volume, coord_z)
      @SLA = sla
      @height = height
      @area = area
      @volume = volume
      @coord_z = coord_z      
    end
    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_lk_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class WindSpeed
    def initialize
    end
    attr_accessor(:height, :terrain_multiplier, :terrain_exponent, :ashrae_terrain_thickness, :ashrae_terrain_exponent, :site_terrain_multiplier, :site_terrain_exponent, :ashrae_site_terrain_thickness, :ashrae_site_terrain_exponent, :S_wo, :shielding_coef)
  end

  class MechanicalVentilation
    def initialize(mechVentType, mechVentInfilCredit, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower, mechVentSensibleEfficiency, mechVentASHRAEStandard)
      @MechVentType = mechVentType
      @MechVentInfilCredit = mechVentInfilCredit
      @MechVentTotalEfficiency = mechVentTotalEfficiency
      @MechVentFractionOfASHRAE = mechVentFractionOfASHRAE
      @MechVentHouseFanPower = mechVentHouseFanPower
      @MechVentSensibleEfficiency = mechVentSensibleEfficiency
      @MechVentASHRAEStandard = mechVentASHRAEStandard
    end
    attr_accessor(:MechVentType, :MechVentInfilCredit, :MechVentTotalEfficiency, :MechVentFractionOfASHRAE, :MechVentHouseFanPower, :MechVentSensibleEfficiency, :MechVentASHRAEStandard, :MechVentBathroomExhaust, :MechVentRangeHoodExhaust, :MechVentSpotFanPower, :bath_exhaust_operation, :range_hood_exhaust_operation, :clothes_dryer_exhaust_operation, :ashrae_vent_rate, :num_vent_fans, :percent_fan_heat_to_space, :whole_house_vent_rate, :bathroom_hour_avg_exhaust, :range_hood_hour_avg_exhaust, :clothes_dryer_hour_avg_exhaust, :max_power, :base_vent_rate, :max_vent_rate, :MechVentApparentSensibleEffectiveness, :MechVentHXCoreSensibleEffectiveness, :MechVentLatentEffectiveness, :hourly_energy_schedule, :hourly_schedule, :average_vent_fan_eff)
  end

  class Building
    def initialize
    end
    attr_accessor(:finished_floor_area, :above_grade_finished_floor_area, :building_height, :stories, :num_units, :above_grade_volume, :above_grade_exterior_wall_area, :SLA, :garage_zone, :garage, :unfinished_basement_zone, :unfinished_basement, :crawlspace_zone, :crawlspace, :pierbeam_zone, :pierbeam, :unfinished_attic_zone, :unfinished_attic)    
  end
  
  class Unit
    def initialize
    end    
    attr_accessor(:num_bedrooms, :num_bathrooms, :is_existing_home, :above_grade_exterior_wall_area, :above_grade_finished_floor_area, :finished_floor_area, :dryer_exhaust, :window_area, :living_zone, :living, :finished_basement_zone, :finished_basement)
  end  

  class NaturalVentilation
    def initialize(natVentHtgSsnSetpointOffset, natVentClgSsnSetpointOffset, natVentOvlpSsnSetpointOffset, natVentHeatingSeason, natVentCoolingSeason, natVentOverlapSeason, natVentNumberWeekdays, natVentNumberWeekendDays, natVentFractionWindowsOpen, natVentFractionWindowAreaOpen, natVentMaxOAHumidityRatio, natVentMaxOARelativeHumidity)
      @NatVentHtgSsnSetpointOffset = natVentHtgSsnSetpointOffset
      @NatVentClgSsnSetpointOffset = natVentClgSsnSetpointOffset
      @NatVentOvlpSsnSetpointOffset = natVentOvlpSsnSetpointOffset
      @NatVentHeatingSeason = natVentHeatingSeason
      @NatVentCoolingSeason = natVentCoolingSeason
      @NatVentOverlapSeason = natVentOverlapSeason
      @NatVentNumberWeekdays = natVentNumberWeekdays
      @NatVentNumberWeekendDays = natVentNumberWeekendDays
      @NatVentFractionWindowsOpen = natVentFractionWindowsOpen
      @NatVentFractionWindowAreaOpen = natVentFractionWindowAreaOpen
      @NatVentMaxOAHumidityRatio = natVentMaxOAHumidityRatio
      @NatVentMaxOARelativeHumidity = natVentMaxOARelativeHumidity
    end
    attr_accessor(:NatVentHtgSsnSetpointOffset, :NatVentClgSsnSetpointOffset, :NatVentOvlpSsnSetpointOffset, :NatVentHeatingSeason, :NatVentCoolingSeason, :NatVentOverlapSeason, :NatVentNumberWeekdays, :NatVentNumberWeekendDays, :NatVentFractionWindowsOpen, :NatVentFractionWindowAreaOpen, :NatVentMaxOAHumidityRatio, :NatVentMaxOARelativeHumidity, :htg_ssn_hourly_temp, :htg_ssn_hourly_weekend_temp, :clg_ssn_hourly_temp, :clg_ssn_hourly_weekend_temp, :ovlp_ssn_hourly_temp, :ovlp_ssn_hourly_weekend_temp, :season_type, :area, :max_rate, :max_flow_rate, :hor_vent_frac, :C_s, :C_w, :temp_hourly_wkdy, :temp_hourly_wked)
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
    return "Adds (or replaces) all building components related to airflow: infiltration, mechanical ventilation, natural ventilation, and ducts.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Uses EMS to model the building airflow."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for infiltration of living space
    living_ach50 = OpenStudio::Measure::OSArgument::makeDoubleArgument("living_ach50", false)
    living_ach50.setDisplayName("Air Leakage: Above-Grade Living ACH50")
    living_ach50.setUnits("1/hr")
    living_ach50.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for above-grade living space (including finished attic).")
    living_ach50.setDefaultValue(7)
    args << living_ach50

    #make a double argument for infiltration of garage
    garage_ach50 = OpenStudio::Measure::OSArgument::makeDoubleArgument("garage_ach50", false)
    garage_ach50.setDisplayName("Air Leakage: Garage ACH50")
    garage_ach50.setUnits("1/hr")
    garage_ach50.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for the garage.")
    garage_ach50.setDefaultValue(7)
    args << garage_ach50

    #make a double argument for infiltration of finished basement
    finished_basement_ach = OpenStudio::Measure::OSArgument::makeDoubleArgument("finished_basement_ach", false)
    finished_basement_ach.setDisplayName("Air Leakage: Finished Basement Constant ACH")
    finished_basement_ach.setUnits("1/hr")
    finished_basement_ach.setDescription("Constant air exchange rate, in Air Changes per Hour (ACH), for the finished basement.")
    finished_basement_ach.setDefaultValue(0.0)
    args << finished_basement_ach
    
    #make a double argument for infiltration of unfinished basement
    unfinished_basement_ach = OpenStudio::Measure::OSArgument::makeDoubleArgument("unfinished_basement_ach", false)
    unfinished_basement_ach.setDisplayName("Air Leakage: Unfinished Basement Constant ACH")
    unfinished_basement_ach.setUnits("1/hr")
    unfinished_basement_ach.setDescription("Constant air exchange rate, in Air Changes per Hour (ACH), for the unfinished basement. A value of 0.10 ACH or greater is recommended for modeling Heat Pump Water Heaters in unfinished basements.")
    unfinished_basement_ach.setDefaultValue(0.1)
    args << unfinished_basement_ach
    
    #make a double argument for infiltration of crawlspace
    crawl_ach = OpenStudio::Measure::OSArgument::makeDoubleArgument("crawl_ach", false)
    crawl_ach.setDisplayName("Air Leakage: Crawlspace Constant ACH")
    crawl_ach.setUnits("1/hr")
    crawl_ach.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for the crawlspace.")
    crawl_ach.setDefaultValue(0.0)
    args << crawl_ach

    #make a double argument for infiltration of pier & beam
    pier_beam_ach = OpenStudio::Measure::OSArgument::makeDoubleArgument("pier_beam_ach", false)
    pier_beam_ach.setDisplayName("Air Leakage: Pier & Beam Constant ACH")
    pier_beam_ach.setUnits("1/hr")
    pier_beam_ach.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for the pier & beam foundation.")
    pier_beam_ach.setDefaultValue(100.0)
    args << pier_beam_ach

    #make a double argument for infiltration of unfinished attic
    unfinished_attic_sla = OpenStudio::Measure::OSArgument::makeDoubleArgument("unfinished_attic_sla", false)
    unfinished_attic_sla.setDisplayName("Air Leakage: Unfinished Attic SLA")
    unfinished_attic_sla.setDescription("Ratio of the effective leakage area (infiltration and/or ventilation) in the unfinished attic to the total floor area of the attic.")
    unfinished_attic_sla.setDefaultValue(0.00333)
    args << unfinished_attic_sla

    #make a double argument for shelter coefficient
    shelter_coef = OpenStudio::Measure::OSArgument::makeStringArgument("shelter_coef", false)
    shelter_coef.setDisplayName("Air Leakage: Shelter Coefficient")
    shelter_coef.setDescription("The local shelter coefficient (AIM-2 infiltration model) accounts for nearby buildings, trees and obstructions.")
    shelter_coef.setDefaultValue("auto")
    args << shelter_coef
    
    #make a double argument for open hvac flue
    has_hvac_flue = OpenStudio::Measure::OSArgument::makeBoolArgument("has_hvac_flue", false)
    has_hvac_flue.setDisplayName("Air Leakage: Has Open HVAC Flue")
    has_hvac_flue.setDescription("Specifies whether the building has an open flue associated with the HVAC system.")
    has_hvac_flue.setDefaultValue(false)
    args << has_hvac_flue    

    #make a double argument for open water heater flue
    has_water_heater_flue = OpenStudio::Measure::OSArgument::makeBoolArgument("has_water_heater_flue", false)
    has_water_heater_flue.setDisplayName("Air Leakage: Has Open Water Heater Flue")
    has_water_heater_flue.setDescription("Specifies whether the building has an open flue associated with the water heater.")
    has_water_heater_flue.setDefaultValue(false)
    args << has_water_heater_flue    

    #make a double argument for open fireplace chimney
    has_fireplace_chimney = OpenStudio::Measure::OSArgument::makeBoolArgument("has_fireplace_chimney", false)
    has_fireplace_chimney.setDisplayName("Air Leakage: Has Open HVAC Flue")
    has_fireplace_chimney.setDescription("Specifies whether the building has an open chimney associated with a fireplace.")
    has_fireplace_chimney.setDefaultValue(false)
    args << has_fireplace_chimney    

    #make a choice arguments for terrain type
    terrain_types_names = OpenStudio::StringVector.new
    terrain_types_names << Constants.TerrainOcean
    terrain_types_names << Constants.TerrainPlains
    terrain_types_names << Constants.TerrainRural
    terrain_types_names << Constants.TerrainSuburban
    terrain_types_names << Constants.TerrainCity
    terrain = OpenStudio::Measure::OSArgument::makeChoiceArgument("terrain", terrain_types_names, true)
    terrain.setDisplayName("Air Leakage: Site Terrain")
    terrain.setDescription("The terrain of the site.")
    terrain.setDefaultValue(Constants.TerrainSuburban)
    args << terrain

    #make a choice argument for ventilation type
    ventilation_types_names = OpenStudio::StringVector.new
    ventilation_types_names << Constants.VentTypeNone
    ventilation_types_names << Constants.VentTypeExhaust
    ventilation_types_names << Constants.VentTypeSupply
    ventilation_types_names << Constants.VentTypeBalanced
    mech_vent_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("mech_vent_type", ventilation_types_names, false)
    mech_vent_type.setDisplayName("Mechanical Ventilation: Ventilation Type")
    mech_vent_type.setDescription("Whole house ventilation strategy used.")
    mech_vent_type.setDefaultValue(Constants.VentTypeExhaust)
    args << mech_vent_type

    #make a double argument for total efficiency
    mech_vent_total_efficiency = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_total_efficiency",false)
    mech_vent_total_efficiency.setDisplayName("Mechanical Ventilation: Total Recovery Efficiency")
    mech_vent_total_efficiency.setDescription("The net total energy (sensible plus latent, also called enthalpy) recovered by the supply airstream adjusted by electric consumption, case heat loss or heat gain, air leakage and airflow mass imbalance between the two airstreams, as a percent of the potential total energy that could be recovered plus the exhaust fan energy.")
    mech_vent_total_efficiency.setDefaultValue(0)
    args << mech_vent_total_efficiency

    #make a double argument for sensible efficiency
    mech_vent_sensible_efficiency = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_sensible_efficiency",false)
    mech_vent_sensible_efficiency.setDisplayName("Mechanical Ventilation: Sensible Recovery Efficiency")
    mech_vent_sensible_efficiency.setDescription("The net sensible energy recovered by the supply airstream as adjusted by electric consumption, case heat loss or heat gain, air leakage, airflow mass imbalance between the two airstreams and the energy used for defrost (when running the Very Low Temperature Test), as a percent of the potential sensible energy that could be recovered plus the exhaust fan energy.")
    mech_vent_sensible_efficiency.setDefaultValue(0)
    args << mech_vent_sensible_efficiency

    #make a double argument for house fan power
    mech_vent_fan_power = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_fan_power",false)
    mech_vent_fan_power.setDisplayName("Mechanical Ventilation: Fan Power")
    mech_vent_fan_power.setUnits("W/cfm")
    mech_vent_fan_power.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of fan(s) providing whole house ventilation. If the house uses a balanced ventilation system there is assumed to be two fans operating at this efficiency.")
    mech_vent_fan_power.setDefaultValue(0.3)
    args << mech_vent_fan_power

    #make a double argument for fraction of ashrae
    mech_vent_frac_62_2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("mech_vent_frac_62_2",false)
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
    mech_vent_ashrae_std = OpenStudio::Measure::OSArgument::makeChoiceArgument("mech_vent_ashrae_std", standard_types_names, false)
    mech_vent_ashrae_std.setDisplayName("Mechanical Ventilation: ASHRAE 62.2 Standard")
    mech_vent_ashrae_std.setDescription("Specifies which version (year) of the ASHRAE 62.2 Standard should be used.")
    mech_vent_ashrae_std.setDefaultValue("2010")
    args << mech_vent_ashrae_std    

    #make a bool argument for infiltration credit
    mech_vent_infil_credit = OpenStudio::Measure::OSArgument::makeBoolArgument("mech_vent_infil_credit",false)
    mech_vent_infil_credit.setDisplayName("Mechanical Ventilation: Allow Infiltration Credit")
    mech_vent_infil_credit.setDescription("Defines whether the infiltration credit allowed per the ASHRAE 62.2 Standard will be included in the calculation of the mechanical ventilation rate. If True, the infiltration credit will apply 1) to new/existing single-family detached homes for 2013 ASHRAE 62.2, or 2) to existing single-family detached or multi-family homes for 2010 ASHRAE 62.2.")
    mech_vent_infil_credit.setDefaultValue(true)
    args << mech_vent_infil_credit

    #make a boolean argument for if an existing home
    is_existing_home = OpenStudio::Measure::OSArgument::makeBoolArgument("is_existing_home", true)
    is_existing_home.setDisplayName("Mechanical Ventilation: Is Existing Home")
    is_existing_home.setDescription("Specifies whether the building is an existing home or new construction.")
    is_existing_home.setDefaultValue(false)
    args << is_existing_home
    
    #make a double argument for dryer exhaust
    clothes_dryer_exhaust = OpenStudio::Measure::OSArgument::makeDoubleArgument("clothes_dryer_exhaust",false)
    clothes_dryer_exhaust.setDisplayName("Clothes Dryer: Exhaust")
    clothes_dryer_exhaust.setUnits("cfm")
    clothes_dryer_exhaust.setDescription("Rated flow capacity of the clothes dryer exhaust. This fan is assumed to run 60 min/day between 11am and 12pm.")
    clothes_dryer_exhaust.setDefaultValue(100.0)
    args << clothes_dryer_exhaust

    #make a double argument for heating season setpoint offset
    nat_vent_htg_offset = OpenStudio::Measure::OSArgument::makeDoubleArgument("nat_vent_htg_offset",false)
    nat_vent_htg_offset.setDisplayName("Natural Ventilation: Heating Season Setpoint Offset")
    nat_vent_htg_offset.setUnits("degrees F")
    nat_vent_htg_offset.setDescription("The temperature offset below the hourly cooling setpoint, to which the living space is allowed to cool during months that are only in the heating season.")
    nat_vent_htg_offset.setDefaultValue(1.0)
    args << nat_vent_htg_offset

    #make a double argument for cooling season setpoint offset
    nat_vent_clg_offset = OpenStudio::Measure::OSArgument::makeDoubleArgument("nat_vent_clg_offset",false)
    nat_vent_clg_offset.setDisplayName("Natural Ventilation: Cooling Season Setpoint Offset")
    nat_vent_clg_offset.setUnits("degrees F")
    nat_vent_clg_offset.setDescription("The temperature offset above the hourly heating setpoint, to which the living space is allowed to cool during months that are only in the cooling season.")
    nat_vent_clg_offset.setDefaultValue(1.0)
    args << nat_vent_clg_offset

    #make a double argument for overlap season setpoint offset
    nat_vent_ovlp_offset = OpenStudio::Measure::OSArgument::makeDoubleArgument("nat_vent_ovlp_offset",false)
    nat_vent_ovlp_offset.setDisplayName("Natural Ventilation: Overlap Season Setpoint Offset")
    nat_vent_ovlp_offset.setUnits("degrees F")
    nat_vent_ovlp_offset.setDescription("The temperature offset above the maximum heating setpoint, to which the living space is allowed to cool during months that are in both the heating season and cooling season.")
    nat_vent_ovlp_offset.setDefaultValue(1.0)
    args << nat_vent_ovlp_offset

    #make a bool argument for heating season
    nat_vent_htg_season = OpenStudio::Measure::OSArgument::makeBoolArgument("nat_vent_htg_season",false)
    nat_vent_htg_season.setDisplayName("Natural Ventilation: Heating Season")
    nat_vent_htg_season.setDescription("True if windows are allowed to be opened during months that are only in the heating season.")
    nat_vent_htg_season.setDefaultValue(true)
    args << nat_vent_htg_season

    #make a bool argument for cooling season
    nat_vent_clg_season = OpenStudio::Measure::OSArgument::makeBoolArgument("nat_vent_clg_season",false)
    nat_vent_clg_season.setDisplayName("Natural Ventilation: Cooling Season")
    nat_vent_clg_season.setDescription("True if windows are allowed to be opened during months that are only in the cooling season.")
    nat_vent_clg_season.setDefaultValue(true)
    args << nat_vent_clg_season

    #make a bool argument for overlap season
    nat_vent_ovlp_season = OpenStudio::Measure::OSArgument::makeBoolArgument("nat_vent_ovlp_season",false)
    nat_vent_ovlp_season.setDisplayName("Natural Ventilation: Overlap Season")
    nat_vent_ovlp_season.setDescription("True if windows are allowed to be opened during months that are in both the heating season and cooling season.")
    nat_vent_ovlp_season.setDefaultValue(true)
    args << nat_vent_ovlp_season

    #make a double argument for number weekdays
    nat_vent_num_weekdays = OpenStudio::Measure::OSArgument::makeIntegerArgument("nat_vent_num_weekdays",false)
    nat_vent_num_weekdays.setDisplayName("Natural Ventilation: Number Weekdays")
    nat_vent_num_weekdays.setDescription("Number of weekdays in the week that natural ventilation can occur.")
    nat_vent_num_weekdays.setDefaultValue(3)
    args << nat_vent_num_weekdays

    #make a double argument for number weekend days
    nat_vent_num_weekends = OpenStudio::Measure::OSArgument::makeIntegerArgument("nat_vent_num_weekends",false)
    nat_vent_num_weekends.setDisplayName("Natural Ventilation: Number Weekend Days")
    nat_vent_num_weekends.setDescription("Number of weekend days in the week that natural ventilation can occur.")
    nat_vent_num_weekends.setDefaultValue(0)
    args << nat_vent_num_weekends

    #make a double argument for fraction of windows open
    nat_vent_frac_windows_open = OpenStudio::Measure::OSArgument::makeDoubleArgument("nat_vent_frac_windows_open",false)
    nat_vent_frac_windows_open.setDisplayName("Natural Ventilation: Fraction of Openable Windows Open")
    nat_vent_frac_windows_open.setUnits("frac")
    nat_vent_frac_windows_open.setDescription("Specifies the fraction of the total openable window area in the building that is opened for ventilation.")
    nat_vent_frac_windows_open.setDefaultValue(0.33)
    args << nat_vent_frac_windows_open

    #make a double argument for fraction of window area open
    nat_vent_frac_window_area_openable = OpenStudio::Measure::OSArgument::makeDoubleArgument("nat_vent_frac_window_area_openable",false)
    nat_vent_frac_window_area_openable.setDisplayName("Natural Ventilation: Fraction Window Area Openable")
    nat_vent_frac_window_area_openable.setUnits("frac")
    nat_vent_frac_window_area_openable.setDescription("Specifies the fraction of total window area in the home that can be opened (e.g. typical sliding windows can be opened to half of their area).")
    nat_vent_frac_window_area_openable.setDefaultValue(0.2)
    args << nat_vent_frac_window_area_openable

    #make a double argument for humidity ratio
    nat_vent_max_oa_hr = OpenStudio::Measure::OSArgument::makeDoubleArgument("nat_vent_max_oa_hr",false)
    nat_vent_max_oa_hr.setDisplayName("Natural Ventilation: Max OA Humidity Ratio")
    nat_vent_max_oa_hr.setUnits("frac")
    nat_vent_max_oa_hr.setDescription("Outdoor air humidity ratio above which windows will not open for natural ventilation.")
    nat_vent_max_oa_hr.setDefaultValue(0.0115)
    args << nat_vent_max_oa_hr

    #make a double argument for relative humidity ratio
    nat_vent_max_oa_rh = OpenStudio::Measure::OSArgument::makeDoubleArgument("nat_vent_max_oa_rh",false)
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
    duct_locations << Constants.FinishedAtticZone
    duct_locations << Constants.UnfinishedAtticZone
    duct_locations << Constants.BasementZone
    duct_locations << Constants.FinishedBasementZone
    duct_locations << Constants.UnfinishedBasementZone
    duct_locations << Constants.CrawlZone
    duct_locations << Constants.PierBeamZone
    duct_locations << Constants.GarageZone
    duct_location = OpenStudio::Measure::OSArgument::makeChoiceArgument("duct_location", duct_locations, true)
    duct_location.setDisplayName("Ducts: Location")
    duct_location.setDescription("The space with the primary location of ducts.")
    duct_location.setDefaultValue(Constants.Auto)
    args << duct_location
    
    #make a double argument for total leakage
    duct_total_leakage = OpenStudio::Measure::OSArgument::makeDoubleArgument("duct_total_leakage", false)
    duct_total_leakage.setDisplayName("Ducts: Total Leakage")
    duct_total_leakage.setUnits("frac")
    duct_total_leakage.setDescription("The total amount of air flow leakage expressed as a fraction of the total air flow rate.")
    duct_total_leakage.setDefaultValue(0.3)
    args << duct_total_leakage

    #make a double argument for supply leakage fraction of total
    duct_supply_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("duct_supply_frac", false)
    duct_supply_frac.setDisplayName("Ducts: Supply Leakage Fraction of Total")
    duct_supply_frac.setUnits("frac")
    duct_supply_frac.setDescription("The amount of air flow leakage leaking out from the supply duct expressed as a fraction of the total duct leakage.")
    duct_supply_frac.setDefaultValue(0.6)
    args << duct_supply_frac

    #make a double argument for return leakage fraction of total
    duct_return_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("duct_return_frac", false)
    duct_return_frac.setDisplayName("Ducts: Return Leakage Fraction of Total")
    duct_return_frac.setUnits("frac")
    duct_return_frac.setDescription("The amount of air flow leakage leaking into the return duct expressed as a fraction of the total duct leakage.")
    duct_return_frac.setDefaultValue(0.067)
    args << duct_return_frac  

    #make a double argument for supply AH leakage fraction of total
    duct_ah_supply_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("duct_ah_supply_frac", false)
    duct_ah_supply_frac.setDisplayName("Ducts: Supply Air Handler Leakage Fraction of Total")
    duct_ah_supply_frac.setUnits("frac")
    duct_ah_supply_frac.setDescription("The amount of air flow leakage leaking out from the supply-side of the air handler expressed as a fraction of the total duct leakage.")
    duct_ah_supply_frac.setDefaultValue(0.067)
    args << duct_ah_supply_frac  

    #make a double argument for return AH leakage fraction of total
    duct_ah_return_frac = OpenStudio::Measure::OSArgument::makeDoubleArgument("duct_ah_return_frac", false)
    duct_ah_return_frac.setDisplayName("Ducts: Return Air Handler Leakage Fraction of Total")
    duct_ah_return_frac.setUnits("frac")
    duct_ah_return_frac.setDescription("The amount of air flow leakage leaking out from the return-side of the air handler expressed as a fraction of the total duct leakage.")
    duct_ah_return_frac.setDefaultValue(0.267)
    args << duct_ah_return_frac
    
    # #make a string argument for norm leakage to outside
    # duct_norm_leakage_25pa = OpenStudio::Measure::OSArgument::makeStringArgument("duct_norm_leakage_25pa", false)
    # duct_norm_leakage_25pa.setDisplayName("Ducts: Leakage to Outside at 25Pa")
    # duct_norm_leakage_25pa.setUnits("cfm/100 ft^2 Finished Floor")
    # duct_norm_leakage_25pa.setDescription("Normalized leakage to the outside when tested at a pressure differential of 25 Pascals (0.1 inches w.g.) across the system.")
    # duct_norm_leakage_25pa.setDefaultValue("NA")
    # args << duct_norm_leakage_25pa
    
    #make a string argument for duct location frac    
    duct_location_frac = OpenStudio::Measure::OSArgument::makeStringArgument("duct_location_frac", true)
    duct_location_frac.setDisplayName("Ducts: Location Fraction")
    duct_location_frac.setUnits("frac")
    duct_location_frac.setDescription("Fraction of supply ducts in the space specified by Duct Location; the remainder of supply ducts will be located in above-grade conditioned space.")
    duct_location_frac.setDefaultValue(Constants.Auto)
    args << duct_location_frac

    #make a string argument for duct num returns
    duct_num_returns = OpenStudio::Measure::OSArgument::makeStringArgument("duct_num_returns", true)
    duct_num_returns.setDisplayName("Ducts: Number of Returns")
    duct_num_returns.setUnits("#")
    duct_num_returns.setDescription("The number of duct returns.")
    duct_num_returns.setDefaultValue(Constants.Auto)
    args << duct_num_returns       
    
    #make a double argument for supply surface area multiplier
    duct_supply_area_mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("duct_supply_area_mult", true)
    duct_supply_area_mult.setDisplayName("Ducts: Supply Surface Area Multiplier")
    duct_supply_area_mult.setUnits("mult")
    duct_supply_area_mult.setDescription("Values specify a fraction of the Building America Benchmark supply duct surface area.")
    duct_supply_area_mult.setDefaultValue(1.0)
    args << duct_supply_area_mult

    #make a double argument for return surface area multiplier
    duct_return_area_mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("duct_return_area_mult", true)
    duct_return_area_mult.setDisplayName("Ducts: Return Surface Area Multiplier")
    duct_return_area_mult.setUnits("mult")
    duct_return_area_mult.setDescription("Values specify a fraction of the Building America Benchmark return duct surface area.")
    duct_return_area_mult.setDefaultValue(1.0)
    args << duct_return_area_mult
    
    #make a double argument for duct unconditioned r value
    duct_r = OpenStudio::Measure::OSArgument::makeDoubleArgument("duct_r", true)
    duct_r.setDisplayName("Ducts: Insulation Nominal R-Value")
    duct_r.setUnits("h-ft^2-R/Btu")
    duct_r.setDescription("The nominal R-value for duct insulation.")
    duct_r.setDefaultValue(0.0)
    args << duct_r
    
    #make a string argument for distribution system efficiency
    dist_system_eff = OpenStudio::Measure::OSArgument::makeStringArgument("duct_dse", false)
    dist_system_eff.setDisplayName("Ducts: Distribution System Efficiency")
    dist_system_eff.setDescription("Defines the energy losses associated with the delivery of energy from the equipment to the source of the load. If provided, overrides all other duct inputs.")
    dist_system_eff.setDefaultValue("NA")
    args << dist_system_eff    

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
    pierbeamACH = runner.getDoubleArgumentValue("pier_beam_ach",user_arguments)
    fbsmtACH = runner.getDoubleArgumentValue("finished_basement_ach",user_arguments)
    ufbsmtACH = runner.getDoubleArgumentValue("unfinished_basement_ach",user_arguments)
    uaSLA = runner.getDoubleArgumentValue("unfinished_attic_sla",user_arguments)
    infiltrationShelterCoefficient = runner.getStringArgumentValue("shelter_coef",user_arguments)
    has_hvac_flue = runner.getBoolArgumentValue("has_hvac_flue",user_arguments)
    has_water_heater_flue = runner.getBoolArgumentValue("has_water_heater_flue",user_arguments)
    has_fireplace_chimney = runner.getBoolArgumentValue("has_fireplace_chimney",user_arguments)
    terrainType = runner.getStringArgumentValue("terrain",user_arguments)
    mechVentType = runner.getStringArgumentValue("mech_vent_type",user_arguments)
    mechVentInfilCredit = runner.getBoolArgumentValue("mech_vent_infil_credit",user_arguments)
    mechVentTotalEfficiency = runner.getDoubleArgumentValue("mech_vent_total_efficiency",user_arguments)
    mechVentSensibleEfficiency = runner.getDoubleArgumentValue("mech_vent_sensible_efficiency",user_arguments)
    mechVentHouseFanPower = runner.getDoubleArgumentValue("mech_vent_fan_power",user_arguments)
    mechVentFractionOfASHRAE = runner.getDoubleArgumentValue("mech_vent_frac_62_2",user_arguments)
    mechVentASHRAEStandard = runner.getStringArgumentValue("mech_vent_ashrae_std",user_arguments)
    if mechVentType == Constants.VentTypeNone
      mechVentFractionOfASHRAE = 0.0
      mechVentHouseFanPower = 0.0
      mechVentTotalEfficiency = 0.0
      mechVentSensibleEfficiency = 0.0
    end
    dryerExhaust = runner.getDoubleArgumentValue("clothes_dryer_exhaust",user_arguments)
    is_existing_home = runner.getBoolArgumentValue("is_existing_home",user_arguments)
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
    ductLocation = runner.getStringArgumentValue("duct_location",user_arguments)
    ductTotalLeakage = runner.getDoubleArgumentValue("duct_total_leakage",user_arguments)
    ductSupplyLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_supply_frac",user_arguments)
    ductReturnLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_return_frac",user_arguments)
    ductAHSupplyLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_ah_supply_frac",user_arguments)
    ductAHReturnLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_ah_return_frac",user_arguments)
    # ductNormLeakageToOutside = runner.getStringArgumentValue("duct_norm_leakage_25pa",user_arguments)
    ductNormLeakageToOutside = "NA"
    unless ductNormLeakageToOutside == "NA"
      ductNormLeakageToOutside = ductNormLeakageToOutside.to_f
    else
      ductNormLeakageToOutside = nil
    end
    ductLocationFrac = runner.getStringArgumentValue("duct_location_frac",user_arguments)
    ductNumReturns = runner.getStringArgumentValue("duct_num_returns",user_arguments)
    ductSupplySurfaceAreaMultiplier = runner.getDoubleArgumentValue("duct_supply_area_mult",user_arguments)
    ductReturnSurfaceAreaMultiplier = runner.getDoubleArgumentValue("duct_return_area_mult",user_arguments)
    ductRvalue = runner.getDoubleArgumentValue("duct_r",user_arguments)
    ductSystemEfficiency = runner.getStringArgumentValue("duct_dse",user_arguments)
    unless ductSystemEfficiency == "NA"
      ductSystemEfficiency = ductSystemEfficiency.to_f
      ductLocation = "none"
    else
      ductSystemEfficiency = nil
    end
    
    #Check for valid inputs
    if not ductSystemEfficiency.nil?
    
      if ductSystemEfficiency <= 0 or ductSystemEfficiency >= 1
        runner.registerError("Ducts: Distribution System Efficiency must be greater than 0 and less than 1.")
        return false
      end
      
    else
    
      if ductTotalLeakage < 0
        runner.registerError("Ducts: Total Leakage must be greater than or equal to 0.")
        return false
      end
      if ductSupplyLeakageFractionOfTotal < 0 or ductSupplyLeakageFractionOfTotal > 1
        runner.registerError("Ducts: Supply Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
        return false
      end
      if ductReturnLeakageFractionOfTotal < 0 or ductReturnLeakageFractionOfTotal > 1
        runner.registerError("Ducts: Return Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
        return false
      end
      if ductAHSupplyLeakageFractionOfTotal < 0 or ductAHSupplyLeakageFractionOfTotal > 1
        runner.registerError("Ducts: Supply Air Handler Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
        return false
      end
      if ductAHReturnLeakageFractionOfTotal < 0 or ductAHReturnLeakageFractionOfTotal > 1
        runner.registerError("Ducts: Return Air Handler Leakage Fraction of Total must be greater than or equal to 0 and less than or equal to 1.")
        return false
      end
      if ductRvalue < 0
        runner.registerError("Ducts: Insulation Nominal R-Value must be greater than or equal to 0.")
        return false
      end
      if ductSupplySurfaceAreaMultiplier < 0
        runner.registerError("Ducts: Supply Surface Area Multiplier must be greater than or equal to 0.")
        return false
      end
      if ductReturnSurfaceAreaMultiplier < 0
        runner.registerError("Ducts: Return Surface Area Multiplier must be greater than or equal to 0.")
        return false
      end

    end
    
    @infMethodRes = 'RESIDENTIAL'
    @infMethodASHRAE = 'ASHRAE-ENHANCED'
    @infMethodSG = 'SHERMAN-GRIMSRUD'

    # Create the class instances
    infil = Infiltration.new(infiltrationLivingSpaceACH50, infiltrationShelterCoefficient, infiltrationGarageACH50)
    wind_speed = WindSpeed.new
    mech_vent = MechanicalVentilation.new(mechVentType, mechVentInfilCredit, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower, mechVentSensibleEfficiency, mechVentASHRAEStandard)
    building = Building.new
    nat_vent = NaturalVentilation.new(natVentHtgSsnSetpointOffset, natVentClgSsnSetpointOffset, natVentOvlpSsnSetpointOffset, natVentHeatingSeason, natVentCoolingSeason, natVentOverlapSeason, natVentNumberWeekdays, natVentNumberWeekendDays, natVentFractionWindowsOpen, natVentFractionWindowAreaOpen, natVentMaxOAHumidityRatio, natVentMaxOARelativeHumidity)
    schedules = Schedules.new
    ducts = Ducts.new(ductTotalLeakage, ductNormLeakageToOutside, ductSupplySurfaceAreaMultiplier, ductReturnSurfaceAreaMultiplier, ductRvalue, ductSupplyLeakageFractionOfTotal, ductReturnLeakageFractionOfTotal, ductAHSupplyLeakageFractionOfTotal, ductAHReturnLeakageFractionOfTotal, ductSystemEfficiency, ductLocationFrac, ductNumReturns, ductLocation)
    
    @weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if @weather.error?
      return false
    end    
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end
    
    # Determine geometry for spaces and zones that aren't unit specific 
    spaces = []
    model.getSpaces.each do |space|
      next if Geometry.space_is_below_grade(space)
      spaces << space
    end
    building.building_height = Geometry.get_height_of_spaces(spaces)
    unless model.getBuilding.standardsNumberOfAboveGroundStories.is_initialized
      runner.registerError("Cannot determine the number of above grade stories.")
      return false
    end

    building.stories = model.getBuilding.standardsNumberOfAboveGroundStories.get
    building.num_units = units.size
    building.above_grade_volume = Geometry.get_above_grade_finished_volume_from_spaces(model.getSpaces, true)
    building.above_grade_exterior_wall_area = Geometry.calculate_above_grade_exterior_wall_area(model.getSpaces, false)
    model.getThermalZones.each do |thermal_zone|
      if Geometry.is_garage(thermal_zone)
        building.garage_zone = thermal_zone
        building.garage = Garage.new(Geometry.get_height_of_spaces(building.garage_zone.spaces), OpenStudio.convert(building.garage_zone.floorArea,"m^2","ft^2").get, Geometry.get_volume_from_spaces(thermal_zone.spaces), Geometry.get_z_origin_for_zone(thermal_zone))
      elsif Geometry.is_unfinished_basement(thermal_zone)
        building.unfinished_basement_zone = thermal_zone
        building.unfinished_basement = UnfinBasement.new(ufbsmtACH, Geometry.get_height_of_spaces(building.unfinished_basement_zone.spaces), OpenStudio.convert(building.unfinished_basement_zone.floorArea,"m^2","ft^2").get, Geometry.get_volume_from_spaces(thermal_zone.spaces), Geometry.get_z_origin_for_zone(thermal_zone))
      elsif Geometry.is_crawl(thermal_zone)
        building.crawlspace_zone = thermal_zone
        building.crawlspace = Crawl.new(crawlACH, Geometry.get_height_of_spaces(building.crawlspace_zone.spaces), OpenStudio.convert(building.crawlspace_zone.floorArea,"m^2","ft^2").get, Geometry.get_volume_from_spaces(thermal_zone.spaces), Geometry.get_z_origin_for_zone(thermal_zone))
      elsif Geometry.is_pier_beam(thermal_zone)
        building.pierbeam_zone = thermal_zone
        building.pierbeam = PierBeam.new(pierbeamACH, Geometry.get_height_of_spaces(building.pierbeam_zone.spaces), OpenStudio.convert(building.pierbeam_zone.floorArea,"m^2","ft^2").get, Geometry.get_volume_from_spaces(thermal_zone.spaces), Geometry.get_z_origin_for_zone(thermal_zone))
      elsif Geometry.is_unfinished_attic(thermal_zone)
        building.unfinished_attic_zone = thermal_zone
        building.unfinished_attic = UnfinAttic.new(uaSLA, Geometry.get_height_of_spaces(building.unfinished_attic_zone.spaces), OpenStudio.convert(building.unfinished_attic_zone.floorArea,"m^2","ft^2").get, Geometry.get_volume_from_spaces(thermal_zone.spaces), Geometry.get_z_origin_for_zone(thermal_zone))
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
      building.garage_zone.spaces.each do |space|
        obj_name = "#{Constants.ObjectNameInfiltration}|#{space.name}"
        space.spaceInfiltrationEffectiveLeakageAreas.each do |leakage_area|
          next unless leakage_area.name.to_s == obj_name
          leakage_area.remove
        end      
        if building.garage.SLA > 0
          leakage_area = OpenStudio::Model::SpaceInfiltrationEffectiveLeakageArea.new(model)
          leakage_area.setName(obj_name)
          leakage_area.setSchedule(model.alwaysOnDiscreteSchedule)
          leakage_area.setEffectiveAirLeakageArea(OpenStudio.convert(building.garage.ELA,"ft^2","cm^2").get)
          leakage_area.setStackCoefficient(UnitConversion.ft2_s2R2L2_s2cm4K(building.garage.C_s_SG))
          leakage_area.setWindCoefficient(UnitConversion._2L2s2_s2cm4m2(building.garage.C_w_SG))
          leakage_area.setSpace(space)
        end
      end
    end        

    unless building.unfinished_basement_zone.nil?
      building.unfinished_basement_zone.spaces.each do |space|
        obj_name = "#{Constants.ObjectNameInfiltration}|#{space.name}"
        space.spaceInfiltrationDesignFlowRates.each do |flow_rate|
          next unless flow_rate.name.to_s == obj_name
          flow_rate.remove
        end
        if building.unfinished_basement.inf_method == @infMethodRes
          if building.unfinished_basement.ACH > 0
            flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
            flow_rate.setName(obj_name)
            flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
            flow_rate.setAirChangesperHour(building.unfinished_basement.ACH)
            flow_rate.setSpace(space)
          end
        end
      end
    end
    
    unless building.crawlspace_zone.nil?
      building.crawlspace_zone.spaces.each do |space|
        obj_name = "#{Constants.ObjectNameInfiltration}|#{space.name}"
        space.spaceInfiltrationDesignFlowRates.each do |flow_rate|
          next unless flow_rate.name.to_s == obj_name
          flow_rate.remove
        end
        flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
        flow_rate.setName(obj_name)
        flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
        flow_rate.setAirChangesperHour(building.crawlspace.ACH)
        flow_rate.setSpace(space)
      end
    end
    
    unless building.pierbeam_zone.nil?
      building.pierbeam_zone.spaces.each do |space|
        obj_name = "#{Constants.ObjectNameInfiltration}|#{space.name}"
        space.spaceInfiltrationDesignFlowRates.each do |flow_rate|
          next unless flow_rate.name.to_s == obj_name
          flow_rate.remove
        end
        flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
        flow_rate.setName(obj_name)
        flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
        flow_rate.setAirChangesperHour(building.pierbeam.ACH)
        flow_rate.setSpace(space)
      end
    end

    unless building.unfinished_attic_zone.nil?
      building.unfinished_attic_zone.spaces.each do |space|
        obj_name = "#{Constants.ObjectNameInfiltration}|#{space.name}"
        space.spaceInfiltrationEffectiveLeakageAreas.each do |leakage_area|
          next unless leakage_area.name.to_s == obj_name
          leakage_area.remove
        end
        leakage_area = OpenStudio::Model::SpaceInfiltrationEffectiveLeakageArea.new(model)
        leakage_area.setName(obj_name)
        leakage_area.setSchedule(model.alwaysOnDiscreteSchedule)
        leakage_area.setEffectiveAirLeakageArea(OpenStudio.convert(building.unfinished_attic.ELA,"ft^2","cm^2").get)
        leakage_area.setStackCoefficient(UnitConversion.ft2_s2R2L2_s2cm4K(building.unfinished_attic.C_s_SG))
        leakage_area.setWindCoefficient(UnitConversion._2L2s2_s2cm4m2(building.unfinished_attic.C_w_SG))
        leakage_area.setSpace(space)
      end
    end

    ["Zone Outdoor Air Drybulb Temperature", "Site Outdoor Air Barometric Pressure", "Zone Mean Air Temperature", "Zone Air Relative Humidity", "Site Outdoor Air Humidity Ratio", "Zone Mean Air Humidity Ratio", "Site Wind Speed", "Schedule Value", "System Node Mass Flow Rate", "Fan Runtime Fraction", "System Node Current Density Volume Flow Rate", "System Node Temperature", "System Node Humidity Ratio", "Zone Air Temperature"].each do |output_var_name|
      unless model.getOutputVariables.any? {|existing_output_var| existing_output_var.name.to_s == output_var_name} 
        output_var = OpenStudio::Model::OutputVariable.new(output_var_name, model)
        output_var.setName(output_var_name)
      end
    end
    
    zone_outdoor_air_drybulb_temp_output_var = nil
    outdoor_air_barometric_pressure_output_var = nil
    zone_mean_air_temp_output_var = nil
    zone_air_relative_humidity_output_var = nil
    outdoor_air_humidity_ratio_output_var = nil
    zone_mean_air_humidity_ratio_output_var = nil
    wind_speed_output_var = nil
    schedule_value_output_var = nil
    system_node_mass_flow_rate_output_var = nil
    fan_runtime_fraction_output_var = nil
    system_node_current_density_volume_flow_rate_output_var = nil
    system_node_temp_output_var = nil
    system_node_humidity_ratio_output_var = nil
    zone_air_temp_output_var = nil
    model.getOutputVariables.each do |output_var|
      if output_var.name.to_s == "Zone Outdoor Air Drybulb Temperature"
        zone_outdoor_air_drybulb_temp_output_var = output_var
      elsif output_var.name.to_s == "Site Outdoor Air Barometric Pressure"
        outdoor_air_barometric_pressure_output_var = output_var
      elsif output_var.name.to_s == "Zone Mean Air Temperature"
        zone_mean_air_temp_output_var = output_var
      elsif output_var.name.to_s == "Zone Air Relative Humidity"
        zone_air_relative_humidity_output_var = output_var
      elsif output_var.name.to_s == "Site Outdoor Air Humidity Ratio"
        outdoor_air_humidity_ratio_output_var = output_var
      elsif output_var.name.to_s == "Zone Mean Air Humidity Ratio"
        zone_mean_air_humidity_ratio_output_var = output_var
      elsif output_var.name.to_s == "Site Wind Speed"
        wind_speed_output_var = output_var
      elsif output_var.name.to_s == "Schedule Value"
        schedule_value_output_var = output_var
      elsif output_var.name.to_s == "System Node Mass Flow Rate"
        system_node_mass_flow_rate_output_var = output_var
      elsif output_var.name.to_s == "Fan Runtime Fraction"
        fan_runtime_fraction_output_var = output_var
      elsif output_var.name.to_s == "System Node Current Density Volume Flow Rate"
        system_node_current_density_volume_flow_rate_output_var = output_var       
      elsif output_var.name.to_s == "System Node Temperature"
        system_node_temp_output_var = output_var
      elsif output_var.name.to_s == "System Node Humidity Ratio"
        system_node_humidity_ratio_output_var = output_var
      elsif output_var.name.to_s == "Zone Air Temperature"
        zone_air_temp_output_var = output_var        
      end
    end
 
    model.getLayeredConstructions.each do |construction|
      next unless construction.name.to_s == "AdiabaticConst"
      construction.layers.each do |material|
        material.remove
      end
      construction.remove
    end
    adiabatic_mat = OpenStudio::Model::MasslessOpaqueMaterial.new(model, "Rough", 176.1)
    adiabatic_mat.setName("Adiabatic")
    adiabatic_const = OpenStudio::Model::Construction.new(model)
    adiabatic_const.setName("AdiabaticConst")
    adiabatic_const.insertLayer(0, adiabatic_mat)

    units.each do |building_unit|

      obj_name_airflow = Constants.ObjectNameAirflow(building_unit.name.to_s.gsub("unit", "u")).gsub("|","_")
      obj_name_infil = Constants.ObjectNameInfiltration(building_unit.name.to_s.gsub("unit", "u")).gsub("|","_")
      obj_name_natvent = Constants.ObjectNameNaturalVentilation(building_unit.name.to_s.gsub("unit", "u")).gsub("|","_")
      obj_name_mechvent = Constants.ObjectNameMechanicalVentilation(building_unit.name.to_s.gsub("unit", "u")).gsub("|","_")
      obj_name_ducts = Constants.ObjectNameDucts(building_unit.name.to_s.gsub("unit", "u")).gsub("|","_")
    
      unit = Unit.new
      unit.num_bedrooms, unit.num_bathrooms = Geometry.get_unit_beds_baths(model, building_unit, runner)
      if unit.num_bedrooms.nil? or unit.num_bathrooms.nil?
        return false
      end
      unit.is_existing_home = is_existing_home
      unit.above_grade_exterior_wall_area = Geometry.calculate_above_grade_exterior_wall_area(building_unit.spaces, false)
      unit.above_grade_finished_floor_area = Geometry.get_above_grade_finished_floor_area_from_spaces(building_unit.spaces, false, runner)
      unit.finished_floor_area = Geometry.get_finished_floor_area_from_spaces(building_unit.spaces, false, runner)
      unit.window_area = Geometry.get_window_area_from_spaces(building_unit.spaces, false)
      
      # Determine geometry for spaces and zones that are unit specific
      Geometry.get_thermal_zones_from_spaces(building_unit.spaces).each do |thermal_zone|
        if Geometry.is_living(thermal_zone) or not /#{Constants.URBANoptFinishedZoneIdentifier} [1-9]\d*/.match(thermal_zone.name.to_s).nil?
          unit.living_zone = thermal_zone
          unit.living = LivingSpace.new(Geometry.get_height_of_spaces(unit.living_zone.spaces), OpenStudio.convert(unit.living_zone.floorArea,"m^2","ft^2").get, Geometry.get_volume_from_spaces(thermal_zone.spaces), Geometry.get_z_origin_for_zone(thermal_zone))
        elsif Geometry.is_finished_basement(thermal_zone) or thermal_zone.name.to_s.start_with? "#{Constants.URBANoptFinishedZoneIdentifier} 0"
          unit.finished_basement_zone = thermal_zone
          unit.finished_basement = FinBasement.new(fbsmtACH, Geometry.get_height_of_spaces(unit.finished_basement_zone.spaces), OpenStudio.convert(unit.finished_basement_zone.floorArea,"m^2","ft^2").get, Geometry.get_volume_from_spaces(thermal_zone.spaces), Geometry.get_z_origin_for_zone(thermal_zone))
        end
      end

      if unit.living_zone.nil?
        runner.registerError("Unable to identify the living zone for #{building_unit.name}.")
        return false
      end
      
      # Remove existing airflow
      
      model.getEnergyManagementSystemProgramCallingManagers.each do |program_calling_manager|
        next unless program_calling_manager.name.to_s == obj_name_airflow + " program calling manager"
        program_calling_manager.remove
      end
      
      # Remove existing infiltration  
      
      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless ["#{obj_name_airflow} tt", "#{obj_name_airflow} tin", "#{obj_name_natvent} pb", "#{obj_name_natvent} phiin", "#{obj_name_natvent} wt", "#{obj_name_airflow} vw", "#{obj_name_infil} wh sch", "#{obj_name_infil} range sch", "#{obj_name_infil} bath sch", "#{obj_name_infil} clothes dryer sch", "#{obj_name_natvent} nva", "#{obj_name_natvent} sp"].map{|x| "#{x} s".gsub(" ","_")}.include? sensor.name.to_s
        sensor.remove
      end
      
      model.getEnergyManagementSystemActuators.each do |actuator|
        next unless [obj_name_infil + " flow"].map{|x| "#{x} act".gsub(" ","_")}.include? actuator.name.to_s or [obj_name_natvent + " flow"].map{|x| "#{x} act".gsub(" ","_")}.include? actuator.name.to_s
        actuator.actuatedComponent.remove
        actuator.remove      
      end      
      
      model.getEnergyManagementSystemActuators.each do |actuator|
        next unless [obj_name_infil + " house exh", obj_name_infil + " range hood", obj_name_infil + " bath exh"].map{|x| "#{x} fan load equip act".gsub(" ","_")}.include? actuator.name.to_s
        actuator.actuatedComponent.to_ElectricEquipment.get.electricEquipmentDefinition.remove
        actuator.remove
      end
      
      model.getScheduleRulesets.each do |schedule|
        next unless schedule.name.to_s == obj_name_infil + " bath exhaust schedule" or schedule.name.to_s == obj_name_infil + " clothes dryer exhaust schedule" or schedule.name.to_s == obj_name_infil + " range hood schedule"
        schedule.remove
      end
      
      model.getEnergyManagementSystemPrograms.each do |program|
        next unless program.name.to_s == "#{obj_name_infil} program".gsub(" ","_")
        program.remove
      end
      
      model.getEnergyManagementSystemOutputVariables.each do |output_var|
        next unless output_var.name.to_s == "#{obj_name_infil} loc w spd"
        output_var.remove      
      end
      
      # Remove existing natural ventilation
      
      model.getEnergyManagementSystemPrograms.each do |program|
        next unless program.name.to_s == "#{obj_name_natvent} program".gsub(" ","_")
        program.remove
      end
      
      model.getScheduleRulesets.each do |schedule|
        next unless schedule.name.to_s == obj_name_natvent + " temp schedule" or schedule.name.to_s == obj_name_natvent + " avail schedule"
        schedule.remove
      end
      
      # Remove existing mechanical ventilation
    
      model.getZoneHVACEnergyRecoveryVentilators.each do |erv|
        next unless erv.name.to_s == obj_name_mechvent + " erv"
        erv.remove
      end
    
      model.getScheduleRulesets.each do |schedule|
        next unless schedule.name.to_s == obj_name_mechvent + " energy schedule" or schedule.name.to_s == obj_name_mechvent + " schedule"
        schedule.remove
      end
    
      # Remove existing ducts   
      
      air_handler_mfr = "#{obj_name_ducts} ah mfr".gsub(" ","_")
      fan_rtf = "#{obj_name_ducts} fan rtf".gsub(" ","_")
      air_handler_vfr = "#{obj_name_ducts} ah vfr".gsub(" ","_")
      air_handler_tout = "#{obj_name_ducts} ah tt".gsub(" ","_")
      return_air_t = "#{obj_name_ducts} ret air t".gsub(" ","_")
      air_handler_wout = "#{obj_name_ducts} ah wt".gsub(" ","_")
      return_air_w = "#{obj_name_ducts} ret air w".gsub(" ","_")
      air_handler_t = "#{obj_name_ducts} ah t".gsub(" ","_")
      air_handler_w = "#{obj_name_ducts} ah w".gsub(" ","_")       
      
      model.getEnergyManagementSystemSensors.each do |sensor|
        next unless [air_handler_mfr, fan_rtf, air_handler_vfr, air_handler_tout, return_air_t, air_handler_wout, return_air_w, air_handler_t, air_handler_w].map{|x| "#{x}_s"}.include? sensor.name.to_s
        sensor.remove
      end   
      
      air_handler_to_living_flow_rate = "#{obj_name_ducts} ah to liv".gsub(" ","_")
      living_to_air_handler_flow_rate = "#{obj_name_ducts} liv to ah".gsub(" ","_")
      model.getEnergyManagementSystemActuators.each do |actuator|
        next unless [air_handler_to_living_flow_rate, living_to_air_handler_flow_rate].map{|x| "#{x} mix act".gsub(" ","_")}.include? actuator.name.to_s
        actuator.actuatedComponent.remove
        actuator.remove
      end
      
      model.getEnergyManagementSystemSubroutines.each do |subroutine|
        next unless subroutine.name.to_s == "#{obj_name_ducts} lk subrout".gsub(" ","_")
        subroutine.remove
      end
    
      supply_sensible_lkage_to_living = "#{obj_name_ducts} sup s lk to lv".gsub(" ","_")
      supply_latent_lkage_to_living = "#{obj_name_ducts} sup lat lk to lv".gsub(" ","_")
      supply_duct_conduction_to_living = "#{obj_name_ducts} sup d cn to lv".gsub(" ","_")
      supply_duct_conduction_to_air_handler = "#{obj_name_ducts} sup d cn to ah".gsub(" ","_")
      return_duct_conduction_to_plenum = "#{obj_name_ducts} ret d cn to pl".gsub(" ","_")
      return_duct_conduction_to_air_handler = "#{obj_name_ducts} ret d cn to ah".gsub(" ","_")
      supply_sensible_lkage_to_air_handler = "#{obj_name_ducts} sup s lk to ah".gsub(" ","_")
      supply_latent_lkage_to_air_handler = "#{obj_name_ducts} sup lat lk to ah".gsub(" ","_")
      return_sensible_lkage = "#{obj_name_ducts} ret s lk".gsub(" ","_")
      return_latent_lkage = "#{obj_name_ducts} ret lat lk".gsub(" ","_")
      
      model.getEnergyManagementSystemActuators.each do |actuator|
        next unless [supply_sensible_lkage_to_living, supply_latent_lkage_to_living, supply_duct_conduction_to_living, supply_duct_conduction_to_air_handler, return_duct_conduction_to_plenum, return_duct_conduction_to_air_handler, supply_sensible_lkage_to_air_handler, supply_latent_lkage_to_air_handler, return_sensible_lkage, return_latent_lkage].map{|x| "#{x} equip act".gsub(" ","_")}.include? actuator.name.to_s
        actuator.actuatedComponent.to_OtherEquipment.get.otherEquipmentDefinition.remove
        actuator.remove
      end
    
      model.getEnergyManagementSystemPrograms.each do |program|
        next unless program.name.to_s == "#{obj_name_ducts} program".gsub(" ","_")
        program.remove
      end
      
      model.getEnergyManagementSystemProgramCallingManagers.each do |program_calling_manager|
        next unless program_calling_manager.name.to_s == obj_name_ducts + " program calling manager"
        program_calling_manager.remove
      end
      
      duct_lk_supply_fan_equiv = "#{obj_name_ducts} lk sup fan equiv".gsub(" ","_")
      duct_lk_exhaust_fan_equiv = "#{obj_name_ducts} lk exh fan equiv".gsub(" ","_")      
    
      model.getEnergyManagementSystemGlobalVariables.each do |ems_global_var|
        next unless [air_handler_mfr, fan_rtf, air_handler_vfr, air_handler_tout, return_air_t, air_handler_wout, return_air_w, air_handler_t, air_handler_w, supply_sensible_lkage_to_living, supply_latent_lkage_to_living, supply_duct_conduction_to_living, supply_duct_conduction_to_air_handler, return_duct_conduction_to_plenum, return_duct_conduction_to_air_handler, supply_sensible_lkage_to_air_handler, supply_latent_lkage_to_air_handler, return_sensible_lkage, return_latent_lkage, living_to_air_handler_flow_rate, air_handler_to_living_flow_rate, duct_lk_supply_fan_equiv, duct_lk_exhaust_fan_equiv].include? ems_global_var.name.to_s
        ems_global_var.remove
      end

      model.getThermalZones.each do |thermal_zone|
        next unless thermal_zone.name.to_s == obj_name_ducts + " dist system eff zone" or thermal_zone.name.to_s == obj_name_ducts + " ret air zone"
        thermal_zone.spaces.each do |space|
          space.surfaces.each do |surface|
            if surface.surfacePropertyConvectionCoefficients.is_initialized
              surface.surfacePropertyConvectionCoefficients.get.remove
            end
          end
          space.remove
        end
        thermal_zone.removeReturnPlenum
        thermal_zone.remove
      end

      # Search for clothes dryer
      (model.getElectricEquipments + model.getOtherEquipments).each do |equip|
        next unless equip.name.to_s == Constants.ObjectNameClothesDryer(Constants.FuelTypeElectric, building_unit.name.to_s) or equip.name.to_s == Constants.ObjectNameClothesDryer(Constants.FuelTypeGas, building_unit.name.to_s) or equip.name.to_s == Constants.ObjectNameClothesDryer(Constants.FuelTypePropane, building_unit.name.to_s)
        unit.dryer_exhaust = dryerExhaust
        break
      end
      if unit.dryer_exhaust.nil?
        runner.registerWarning("No clothes dryer object was found in #{building_unit.name.to_s} but the clothes dryer exhaust specified is non-zero. Overriding clothes dryer exhaust to be zero.")
        unit.dryer_exhaust = 0
      end
      
      infil, building, unit = _processInfiltrationForUnit(infil, wind_speed, building, unit, has_hvac_flue, has_water_heater_flue, has_fireplace_chimney, runner)
      mech_vent = _processMechanicalVentilationForUnit(model, runner, infil, mech_vent, building, unit)
      nat_vent = _processNaturalVentilationForUnit(model, runner, nat_vent, wind_speed, infil, building, unit)
      ducts = _processDuctsForUnit(model, runner, ducts, building, unit)
      
      schedules.BathExhaust = HourlyByMonthSchedule.new(model, runner, obj_name_infil + " bath exhaust schedule", [Array.new(6, 0.0) + [1.0] + Array.new(17, 0.0)] * 12, [Array.new(6, 0.0) + [1.0] + Array.new(17, 0.0)] * 12, normalize_values = false)
      schedules.ClothesDryerExhaust = HourlyByMonthSchedule.new(model, runner, obj_name_infil + " clothes dryer exhaust schedule", [Array.new(10, 0.0) + [1.0] + Array.new(13, 0.0)] * 12, [Array.new(10, 0.0) + [1.0] + Array.new(13, 0.0)] * 12, normalize_values = false)
      schedules.RangeHood = HourlyByMonthSchedule.new(model, runner, obj_name_infil + " range hood schedule", [Array.new(17, 0.0) + [1.0] + Array.new(6, 0.0)] * 12, [Array.new(17, 0.0) + [1.0] + Array.new(6, 0.0)] * 12, normalize_values = false)
      
      schedules.MechanicalVentilationEnergy = HourlyByMonthSchedule.new(model, runner, obj_name_mechvent + " energy schedule", [mech_vent.hourly_energy_schedule] * 12, [mech_vent.hourly_energy_schedule] * 12, normalize_values = false)
      schedules.MechanicalVentilation = HourlyByMonthSchedule.new(model, runner, obj_name_mechvent + " schedule", [mech_vent.hourly_schedule] * 12, [mech_vent.hourly_schedule] * 12, normalize_values = false)      
      
      schedules.NatVentTemp = HourlyByMonthSchedule.new(model, runner, obj_name_natvent + " temp schedule", nat_vent.temp_hourly_wkdy, nat_vent.temp_hourly_wked, normalize_values = false)
      schedules.NatVentAvailability = OpenStudio::Model::ScheduleRuleset.new(model)
      schedules.NatVentAvailability.setName(obj_name_natvent + " avail schedule")

      day_endm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
      day_startm = [0, 1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
      
      time = []
      for h in 1..24
        time[h] = OpenStudio::Time.new(0,h,0,0)
      end
      
      (1..12).to_a.each do |m|
        
        date_s = OpenStudio::Date::fromDayOfYear(day_startm[m])
        date_e = OpenStudio::Date::fromDayOfYear(day_endm[m])
        
        if ((nat_vent.season_type[m-1] == Constants.SeasonHeating and nat_vent.NatVentHeatingSeason) or (nat_vent.season_type[m-1] == Constants.SeasonCooling and nat_vent.NatVentCoolingSeason) or (nat_vent.season_type[m-1] == Constants.SeasonOverlap and nat_vent.NatVentOverlapSeason)) and (nat_vent.NatVentNumberWeekdays + nat_vent.NatVentNumberWeekendDays !=  0)
          on_rule = OpenStudio::Model::ScheduleRule.new(schedules.NatVentAvailability)
          on_rule.setName(obj_name_natvent + " availability schedule #{Schedule.allday_name} ruleset#{m} on")
          on_rule_day = on_rule.daySchedule
          on_rule_day.setName(obj_name_natvent + " availability schedule #{Schedule.allday_name}1 on")
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
          off_rule.setName(obj_name_natvent + " availability schedule #{Schedule.allday_name} ruleset#{m} off")
          off_rule_day = off_rule.daySchedule
          off_rule_day.setName(obj_name_natvent + " availability schedule #{Schedule.allday_name}1 off")
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
      
      unless unit.finished_basement_zone.nil?
        unit.finished_basement_zone.spaces.each do |space|
          obj_name = "#{obj_name_infil}|#{space.name}"
          space.spaceInfiltrationDesignFlowRates.each do |flow_rate|
            next unless flow_rate.name.to_s == obj_name
            flow_rate.remove
          end
          if unit.finished_basement.inf_method == @infMethodRes
            if unit.finished_basement.ACH > 0            
              flow_rate = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
              flow_rate.setName(obj_name)
              flow_rate.setSchedule(model.alwaysOnDiscreteSchedule)
              flow_rate.setAirChangesperHour(unit.finished_basement.ACH)
              flow_rate.setSpace(space)
            end
          end
        end
      end
      
      # Sensors
    
      tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_outdoor_air_drybulb_temp_output_var)
      tout_sensor.setName("#{obj_name_airflow} tt s")
      tout_sensor.setKeyName(unit.living_zone.name.to_s)
      
      tin_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_mean_air_temp_output_var)
      tin_sensor.setName("#{obj_name_airflow} tin s")
      tin_sensor.setKeyName(unit.living_zone.name.to_s)
      
      pbar_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, outdoor_air_barometric_pressure_output_var)
      pbar_sensor.setName("#{obj_name_natvent} pb s")      

      phiin_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_air_relative_humidity_output_var)
      phiin_sensor.setName("#{obj_name_natvent} phiin s")
      phiin_sensor.setKeyName(unit.living_zone.name.to_s)

      wout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, outdoor_air_humidity_ratio_output_var)
      wout_sensor.setName("#{obj_name_natvent} wt s")
   
      vwind_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, wind_speed_output_var)
      vwind_sensor.setName("#{obj_name_airflow} vw s")
      
      wh_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      wh_sch_sensor.setName("#{obj_name_infil} wh sch s")
      wh_sch_sensor.setKeyName(model.alwaysOnDiscreteSchedule.name.to_s)
      
      range_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      range_sch_sensor.setName("#{obj_name_infil} range sch s")
      range_sch_sensor.setKeyName(schedules.RangeHood.schedule.name.to_s)
      
      bath_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      bath_sch_sensor.setName("#{obj_name_infil} bath sch s")
      bath_sch_sensor.setKeyName(schedules.BathExhaust.schedule.name.to_s)      
      
      clothes_dryer_sch_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      clothes_dryer_sch_sensor.setName("#{obj_name_infil} clothes dryer sch s")
      clothes_dryer_sch_sensor.setKeyName(schedules.ClothesDryerExhaust.schedule.name.to_s)
      
      nvavail_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      nvavail_sensor.setName("#{obj_name_natvent} nva s")
      nvavail_sensor.setKeyName(schedules.NatVentAvailability.name.to_s)
      
      nvsp_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, schedule_value_output_var)
      nvsp_sensor.setName("#{obj_name_natvent} sp s")
      nvsp_sensor.setKeyName(schedules.NatVentTemp.schedule.name.to_s)
      
      # Actuators
      
      infil_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
      infil_flow.setName(obj_name_infil + " flow")
      infil_flow.setSchedule(model.alwaysOnDiscreteSchedule)
      infil_flow.setSpace(unit.living_zone.spaces[0])      
      infil_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(infil_flow, "Zone Infiltration", "Air Exchange Flow Rate")
      infil_flow_actuator.setName("#{infil_flow.name} act")

      natvent_flow = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
      natvent_flow.setName(obj_name_natvent + " flow")
      natvent_flow.setSchedule(model.alwaysOnDiscreteSchedule)
      natvent_flow.setSpace(unit.living_zone.spaces[0])       
      natvent_flow_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(natvent_flow, "Zone Infiltration", "Air Exchange Flow Rate")
      natvent_flow_actuator.setName("#{natvent_flow.name} act")

      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName(obj_name_infil + " house exh fan load equip")
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName(obj_name_infil + " house exh fan load equip")
      equip.setSpace(unit.living_zone.spaces[0])
      equip_def.setFractionRadiant(0)
      equip_def.setFractionLatent(0)
      equip_def.setFractionLost(1.0 - mech_vent.percent_fan_heat_to_space)
      equip.setSchedule(model.alwaysOnDiscreteSchedule)
      equip.setEndUseSubcategory(Constants.EndUseMechVentFan)
      
      whole_house_fan_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
      whole_house_fan_actuator.setName("#{equip.name} act")        
      
      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName(obj_name_infil + " range hood fan load equip")
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName(obj_name_infil + " range hood fan load equip")
      equip.setSpace(unit.living_zone.spaces[0])
      equip_def.setFractionRadiant(0)
      equip_def.setFractionLatent(0)
      equip_def.setFractionLost(1)
      equip.setSchedule(model.alwaysOnDiscreteSchedule)
      equip.setEndUseSubcategory(Constants.EndUseMechVentFan)

      range_hood_fan_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
      range_hood_fan_actuator.setName("#{equip.name} act")           
      
      equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
      equip_def.setName(obj_name_infil + " bath exh fan load equip")
      equip = OpenStudio::Model::ElectricEquipment.new(equip_def)
      equip.setName(obj_name_infil + " bath exh fan load equip")
      equip.setSpace(unit.living_zone.spaces[0])
      equip_def.setFractionRadiant(0)
      equip_def.setFractionLatent(0)
      equip_def.setFractionLost(1)
      equip.setSchedule(model.alwaysOnDiscreteSchedule)
      equip.setEndUseSubcategory(Constants.EndUseMechVentFan)
      
      bath_exhaust_fan_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(equip, "ElectricEquipment", "Electric Power Level")
      bath_exhaust_fan_actuator.setName("#{equip.name} act")
      
      # Global Variables
      
      ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, duct_lk_supply_fan_equiv)
      ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, duct_lk_exhaust_fan_equiv)
      
      # Programs

      infil_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      infil_program.setName(obj_name_infil + " program")
      infil_program.addLine("Set p_m = #{wind_speed.ashrae_terrain_exponent}")
      infil_program.addLine("Set p_s = #{wind_speed.ashrae_site_terrain_exponent}")
      infil_program.addLine("Set s_m = #{wind_speed.ashrae_terrain_thickness}")
      infil_program.addLine("Set s_s = #{wind_speed.ashrae_site_terrain_thickness}")
      infil_program.addLine("Set z_m = #{OpenStudio.convert(wind_speed.height,"ft","m").get}")
      infil_program.addLine("Set z_s = #{OpenStudio.convert(unit.living.height,"ft","m").get}")
      infil_program.addLine("Set f_t = (((s_m/z_m)^p_m)*((z_s/s_s)^p_s))")
      infil_program.addLine("Set #{building_unit.name.to_s.gsub("unit", "u").gsub(" ","_")}_VwindL = (f_t*#{vwind_sensor.name})")
      
      if unit.living.inf_method == @infMethodASHRAE
        if unit.living.SLA > 0
          infil_program.addLine("Set Tdiff = #{tin_sensor.name}-#{tout_sensor.name}")
          infil_program.addLine("Set dT = @Abs Tdiff")
          infil_program.addLine("Set c = #{((OpenStudio.convert(infil.C_i,"cfm","m^3/s").get / (UnitConversion.inH2O2Pa(1.0) ** infil.n_i))).round(4)}")
          infil_program.addLine("Set Cs = #{(infil.stack_coef * (UnitConversion.inH2O_R2Pa_K(1.0) ** infil.n_i)).round(4)}")
          infil_program.addLine("Set Cw = #{(infil.wind_coef * (UnitConversion.inH2O_mph2Pas2_m2(1.0) ** infil.n_i)).round(4)}")
          infil_program.addLine("Set n = #{infil.n_i}")
          infil_program.addLine("Set sft = (f_t*#{(((wind_speed.S_wo * (1.0 - infil.Y_i)) + (infil.S_wflue * (1.5 * infil.Y_i))))})")
          infil_program.addLine("Set temp1 = ((c*Cw)*((sft*#{vwind_sensor.name})^(2*n)))^2")
          infil_program.addLine("Set Qn = (((c*Cs*(dT^n))^2)+temp1)^0.5")
        else
          infil_program.addLine("Set Qn = 0")
        end
      elsif unit.living.inf_method == @infMethodRes
        infil_program.addLine("Set Qn = #{unit.living.ACH * OpenStudio.convert(unit.living.volume,"ft^3","m^3").get / OpenStudio.convert(1.0,"hr","s").get}")
      end
      
      infil_program.addLine("Set Tdiff = #{tin_sensor.name}-#{tout_sensor.name}")
      infil_program.addLine("Set dT = @Abs Tdiff")
      infil_program.addLine("Set QWHV = #{wh_sch_sensor.name}*#{OpenStudio.convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get.round(4)}")
      infil_program.addLine("Set Qrange = #{range_sch_sensor.name}*#{OpenStudio.convert(mech_vent.range_hood_hour_avg_exhaust,"cfm","m^3/s").get.round(4)}")
      infil_program.addLine("Set Qdryer = #{clothes_dryer_sch_sensor.name}*#{OpenStudio.convert(mech_vent.clothes_dryer_hour_avg_exhaust,"cfm","m^3/s").get}")
      infil_program.addLine("Set Qbath = #{bath_sch_sensor.name}*#{OpenStudio.convert(mech_vent.bathroom_hour_avg_exhaust,"cfm","m^3/s").get.round(4)}")
      infil_program.addLine("Set QhpwhOut = 0")
      infil_program.addLine("Set QhpwhIn = 0")
      infil_program.addLine("Set QductsOut = #{duct_lk_exhaust_fan_equiv}")
      infil_program.addLine("Set QductsIn = #{duct_lk_supply_fan_equiv}")
      
      if mech_vent.MechVentType == Constants.VentTypeBalanced
        infil_program.addLine("Set Qout = Qrange+Qbath+Qdryer+QhpwhOut+QductsOut")
        infil_program.addLine("Set Qin = QhpwhIn+QductsIn")
        infil_program.addLine("Set Qu = (@Abs (Qout-Qin))")
        infil_program.addLine("Set Qb = QWHV + (@Min Qout Qin)")
        infil_program.addLine("Set #{whole_house_fan_actuator.name} = 0")
      else
        if mech_vent.MechVentType == Constants.VentTypeExhaust
          infil_program.addLine("Set Qout = QWHV+Qrange+Qbath+Qdryer+QhpwhOut+QductsOut")
          infil_program.addLine("Set Qin = QhpwhIn+QductsIn")
          infil_program.addLine("Set Qu = (@Abs (Qout-Qin))")
          infil_program.addLine("Set Qb = (@Min Qout Qin)")
        else # mech_vent.MechVentType == Constants.VentTypeSupply
          infil_program.addLine("Set Qout = Qrange+Qbath+Qdryer+QhpwhOut+QductsOut")
          infil_program.addLine("Set Qin = QWHV+QhpwhIn+QductsIn")
          infil_program.addLine("Set Qu = @Abs (Qout- Qin)")
          infil_program.addLine("Set Qb = (@Min Qout Qin)")
        end
        if mech_vent.MechVentHouseFanPower !=  0
          infil_program.addLine("Set faneff_wh = #{OpenStudio.convert(300.0 / mech_vent.MechVentHouseFanPower,"cfm","m^3/s").get}")
        else
          infil_program.addLine("Set faneff_wh = 1")
        end
        infil_program.addLine("Set #{whole_house_fan_actuator.name} = (QWHV*300)/faneff_wh")
      end

      if mech_vent.MechVentSpotFanPower !=  0
        infil_program.addLine("Set faneff_sp = #{OpenStudio.convert(300.0 / mech_vent.MechVentSpotFanPower,"cfm","m^3/s").get}")
      else
        infil_program.addLine("Set faneff_sp = 1")
      end
      
      infil_program.addLine("Set #{range_hood_fan_actuator.name} = (Qrange*300)/faneff_sp")
      infil_program.addLine("Set #{bath_exhaust_fan_actuator.name} = (Qbath*300)/faneff_sp")
      infil_program.addLine("Set Q_acctd_for_elsewhere = QhpwhOut+QhpwhIn+QductsOut+QductsIn")
      infil_program.addLine("Set #{infil_flow_actuator.name} = (((Qu^2)+(Qn^2))^0.5)-Q_acctd_for_elsewhere")
      infil_program.addLine("Set #{infil_flow_actuator.name} = (@Max #{infil_flow_actuator.name} 0)")
      
      # EMS Output Variables
      ems_output_var = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, "#{building_unit.name.to_s.gsub("unit", "u").gsub(" ","_")}_VwindL")
      ems_output_var.setName(obj_name_infil + " loc w spd")
      ems_output_var.setEMSProgramOrSubroutineName(infil_program)
      ems_output_var.setUnits("m/s")
      
      nat_vent_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      nat_vent_program.setName(obj_name_natvent + " program")
      nat_vent_program.addLine("Set Tdiff = #{tin_sensor.name}-#{tout_sensor.name}")
      nat_vent_program.addLine("Set dT = (@Abs Tdiff)")
      nat_vent_program.addLine("Set pt = (@RhFnTdbWPb #{tout_sensor.name} #{wout_sensor.name} #{pbar_sensor.name})")
      nat_vent_program.addLine("Set NVA = #{OpenStudio.convert(nat_vent.area,"ft^2","cm^2").get}")
      nat_vent_program.addLine("Set Cs = #{UnitConversion.ft2_s2R2L2_s2cm4K(nat_vent.C_s)}")
      nat_vent_program.addLine("Set Cw = #{UnitConversion._2L2s2_s2cm4m2(nat_vent.C_w)}")
      nat_vent_program.addLine("Set MNV = #{OpenStudio.convert(nat_vent.max_flow_rate,"cfm","m^3/s").get}")
      nat_vent_program.addLine("Set MHR = #{nat_vent.NatVentMaxOAHumidityRatio}")
      nat_vent_program.addLine("Set MRH = #{nat_vent.NatVentMaxOARelativeHumidity}")
      nat_vent_program.addLine("Set temp1 = (#{nvavail_sensor.name}*NVA)")
      nat_vent_program.addLine("Set SGNV = temp1*((((Cs*dT)+(Cw*(#{vwind_sensor.name}^2)))^0.5)/1000)")
      nat_vent_program.addLine("If (#{wout_sensor.name}<MHR) && (pt<MRH) && (#{tin_sensor.name}>#{nvsp_sensor.name})")
      nat_vent_program.addLine("Set temp2 = (#{tin_sensor.name}-#{nvsp_sensor.name})")
      nat_vent_program.addLine("Set NVadj1 = temp2/(#{tin_sensor.name}-#{tout_sensor.name})")
      nat_vent_program.addLine("Set NVadj2 = (@Min NVadj1 1)")
      nat_vent_program.addLine("Set NVadj3 = (@Max NVadj2 0)")
      nat_vent_program.addLine("Set NVadj = SGNV*NVadj3")
      nat_vent_program.addLine("Set #{natvent_flow_actuator.name} = (@Min NVadj MNV)")
      nat_vent_program.addLine("Else")
      nat_vent_program.addLine("Set #{natvent_flow_actuator.name} = 0")
      nat_vent_program.addLine("EndIf")     
      
      # Program Calling Manager
      
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName(obj_name_airflow + " program calling manager")
      program_calling_manager.setCallingPoint("BeginTimestepBeforePredictor")
      program_calling_manager.addProgram(infil_program)
      program_calling_manager.addProgram(nat_vent_program)
      
      if mech_vent.MechVentType == Constants.VentTypeBalanced
      
        balanced_flow_rate = [OpenStudio.convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get,0.0000001].max
      
        supply_fan = OpenStudio::Model::FanOnOff.new(model)
        supply_fan.setName(obj_name_mechvent + " erv supply fan")
        supply_fan.setFanEfficiency(OpenStudio.convert(300.0 / mech_vent.MechVentHouseFanPower,"cfm","m^3/s").get)
        supply_fan.setPressureRise(300.0)
        supply_fan.setMaximumFlowRate(balanced_flow_rate)
        supply_fan.setMotorEfficiency(1)
        supply_fan.setMotorInAirstreamFraction(1)
        supply_fan.setEndUseSubcategory(Constants.EndUseMechVentFan)

        exhaust_fan = OpenStudio::Model::FanOnOff.new(model)
        exhaust_fan.setName(obj_name_mechvent + " erv exhaust fan")
        exhaust_fan.setFanEfficiency(OpenStudio.convert(300.0 / mech_vent.MechVentHouseFanPower,"cfm","m^3/s").get)
        exhaust_fan.setPressureRise(300.0)
        exhaust_fan.setMaximumFlowRate(balanced_flow_rate)
        exhaust_fan.setMotorEfficiency(1)
        exhaust_fan.setMotorInAirstreamFraction(0)
        exhaust_fan.setEndUseSubcategory(Constants.EndUseMechVentFan)

        erv_controller = OpenStudio::Model::ZoneHVACEnergyRecoveryVentilatorController.new(model)
        erv_controller.setName(obj_name_mechvent + " erv controller")
        erv_controller.setExhaustAirTemperatureLimit("NoExhaustAirTemperatureLimit")
        erv_controller.setExhaustAirEnthalpyLimit("NoExhaustAirEnthalpyLimit")
        erv_controller.setTimeofDayEconomizerFlowControlSchedule(model.alwaysOffDiscreteSchedule)
        erv_controller.setHighHumidityControlFlag(false)

        heat_exchanger = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(model)
        heat_exchanger.setName(obj_name_mechvent + " erv heat exchanger")
        heat_exchanger.setNominalSupplyAirFlowRate(balanced_flow_rate)
        heat_exchanger.setSensibleEffectivenessat100HeatingAirFlow(mech_vent.MechVentHXCoreSensibleEffectiveness)
        heat_exchanger.setLatentEffectivenessat100HeatingAirFlow(mech_vent.MechVentLatentEffectiveness)
        heat_exchanger.setSensibleEffectivenessat75HeatingAirFlow(mech_vent.MechVentHXCoreSensibleEffectiveness)
        heat_exchanger.setLatentEffectivenessat75HeatingAirFlow(mech_vent.MechVentLatentEffectiveness)
        heat_exchanger.setSensibleEffectivenessat100CoolingAirFlow(mech_vent.MechVentHXCoreSensibleEffectiveness)
        heat_exchanger.setLatentEffectivenessat100CoolingAirFlow(mech_vent.MechVentLatentEffectiveness)
        heat_exchanger.setSensibleEffectivenessat75CoolingAirFlow(mech_vent.MechVentHXCoreSensibleEffectiveness)
        heat_exchanger.setLatentEffectivenessat75CoolingAirFlow(mech_vent.MechVentLatentEffectiveness)        

        zone_hvac = OpenStudio::Model::ZoneHVACEnergyRecoveryVentilator.new(model, heat_exchanger, supply_fan, exhaust_fan)
        zone_hvac.setName(obj_name_mechvent + " erv")
        zone_hvac.setController(erv_controller)
        zone_hvac.setSupplyAirFlowRate(balanced_flow_rate)
        zone_hvac.setExhaustAirFlowRate(balanced_flow_rate)
        zone_hvac.setVentilationRateperUnitFloorArea(0)
        zone_hvac.setVentilationRateperOccupant(0)
        zone_hvac.addToThermalZone(unit.living_zone)
        
        HVAC.prioritize_zone_hvac(model, runner, unit.living_zone).reverse.each do |object|
          unit.living_zone.setCoolingPriority(object, 1)
          unit.living_zone.setHeatingPriority(object, 1)
        end

      end
      
      if not ducts.DuctSystemEfficiency.nil?
        
        dse_zone = OpenStudio::Model::ThermalZone.new(model)
        dse_zone.setName(Constants.DSEZone(building_unit.name.to_s))
        dse_zone.setVolume(0)
        
        sw_point = OpenStudio::Point3d.new(30, 50, 0)
        nw_point = OpenStudio::Point3d.new(30, 50.5, 0)
        ne_point = OpenStudio::Point3d.new(30.5, 50.5, 0)
        se_point = OpenStudio::Point3d.new(30.5, 50, 0)
        dse_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
        
        dse_space = OpenStudio::Model::Space::fromFloorPrint(dse_polygon, 0.5, model)
        dse_space = dse_space.get
        dse_space.setName(Constants.DSESpace(building_unit.name.to_s))
        dse_space.setThermalZone(dse_zone)
        dse_space.setBuildingUnit(building_unit)
        
        dse_space.surfaces.each do |surface|
          surface.setConstruction(adiabatic_const)
          surface.setOutsideBoundaryCondition("Adiabatic")
          surface.setSunExposure("NoSun")
          surface.setWindExposure("NoWind")
        end
        
        model.getAirLoopHVACs.each do |air_loop|
          next unless air_loop.thermalZones.include? unit.living_zone # get the correct air loop for this unit
          dse_diffuser = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, model.alwaysOnDiscreteSchedule)
          dse_diffuser.setName(obj_name_ducts + " dist system eff zone direct air")
          air_loop.addBranchForZone(dse_zone, dse_diffuser.to_StraightComponent)
        end
          
      end            
    
      ra_duct_zone = OpenStudio::Model::ThermalZone.new(model)
      ra_duct_zone.setName(obj_name_ducts + " ret air zone")
      ra_duct_zone.setVolume(OpenStudio.convert(ducts.return_duct_volume,"ft^3","m^3").get)
      
      sw_point = OpenStudio::Point3d.new(0, 74, 0)
      nw_point = OpenStudio::Point3d.new(0, 75, 0)
      ne_point = OpenStudio::Point3d.new(1, 75, 0)
      se_point = OpenStudio::Point3d.new(1, 74, 0)
      ra_duct_polygon = Geometry.make_polygon(sw_point, nw_point, ne_point, se_point)
      
      ra_duct_space = OpenStudio::Model::Space::fromFloorPrint(ra_duct_polygon, 1, model)
      ra_duct_space = ra_duct_space.get
      ra_duct_space.setName(obj_name_ducts + " ret air space")
      ra_duct_space.setThermalZone(ra_duct_zone)
      
      ra_duct_space.surfaces.each do |surface|
        surface.setConstruction(adiabatic_const)
        surface.setOutsideBoundaryCondition("Adiabatic")
        surface.setSunExposure("NoSun")
        surface.setWindExposure("NoWind")
        surface_property_convection_coefficients = OpenStudio::Model::SurfacePropertyConvectionCoefficients.new(surface)
        surface_property_convection_coefficients.setConvectionCoefficient1Location("Inside")
        surface_property_convection_coefficients.setConvectionCoefficient1Type("Value")
        surface_property_convection_coefficients.setConvectionCoefficient1(999)
      end
        
      if ducts.has_forced_air_equipment  
        
        air_demand_inlet_node = nil
        supply_fan = nil
        model.getAirLoopHVACs.each do |air_loop|
          next unless air_loop.thermalZones.include? unit.living_zone # get the correct air loop for this unit
          air_demand_inlet_node = air_loop.demandInletNode
          air_loop.supplyComponents.each do |supply_component|
            next unless supply_component.to_AirLoopHVACUnitarySystem.is_initialized
            air_loop_unitary = supply_component.to_AirLoopHVACUnitarySystem.get
            supply_fan = air_loop_unitary.supplyFan.get
          end
          break
        end
        living_zone_return_air_node = unit.living_zone.returnAirModelObject().get
        
        unit.living_zone.setReturnPlenum(ra_duct_zone)
        unless unit.finished_basement_zone.nil?
          unit.finished_basement_zone.setReturnPlenum(ra_duct_zone)
        end
        
      end
      
      if not ducts.duct_location_name == unit.living_zone.name.to_s and not ducts.duct_location_name == "none" and ducts.has_forced_air_equipment
      
        # Other equipment objects to cancel out the supply air leakage directly into the return plenum   
        
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip_def.setName(supply_sensible_lkage_to_living + " equip")
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName(other_equip_def.name.to_s)
        other_equip.setFuelType("None")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(unit.living_zone.spaces[0])
        supply_sensible_lkage_to_living_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        supply_sensible_lkage_to_living_actuator.setName("#{other_equip.name} act")
        
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip_def.setName(supply_latent_lkage_to_living + " equip")
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName(other_equip_def.name.to_s)
        other_equip.setFuelType("None")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(unit.living_zone.spaces[0])
        supply_latent_lkage_to_living_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        supply_latent_lkage_to_living_actuator.setName("#{other_equip.name} act")        
        
        # Supply duct conduction load added to the living space
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip_def.setName(supply_duct_conduction_to_living + " equip")
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName(other_equip_def.name.to_s)
        other_equip.setFuelType("None")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(unit.living_zone.spaces[0])
        supply_duct_conduction_to_living_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        supply_duct_conduction_to_living_actuator.setName("#{other_equip.name} act")
        
        # Supply duct conduction impact on the air handler zone.
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip_def.setName(supply_duct_conduction_to_air_handler + " equip")
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName(other_equip_def.name.to_s)
        other_equip.setFuelType("None")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ducts.duct_location_zone.spaces[0])
        supply_duct_conduction_to_air_handler_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        supply_duct_conduction_to_air_handler_actuator.setName("#{other_equip.name} act")
        
        # Return duct conduction load added to the return plenum zone
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip_def.setName(return_duct_conduction_to_plenum + " equip")
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName(other_equip_def.name.to_s)
        other_equip.setFuelType("None")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ra_duct_space)
        return_duct_conduction_to_plenum_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        return_duct_conduction_to_plenum_actuator.setName("#{other_equip.name} act")
      
        # Return duct conduction impact on the air handler zone.
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip_def.setName(return_duct_conduction_to_air_handler + " equip")
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName(other_equip_def.name.to_s)
        other_equip.setFuelType("None")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ducts.duct_location_zone.spaces[0])
        return_duct_conduction_to_air_handler_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        return_duct_conduction_to_air_handler_actuator.setName("#{other_equip.name} act")
        
        # Supply duct sensible lkage impact on the air handler zone.
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip_def.setName(supply_sensible_lkage_to_air_handler + " equip")
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName(other_equip_def.name.to_s)
        other_equip.setFuelType("None")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ducts.duct_location_zone.spaces[0])
        supply_sensible_lkage_to_air_handler_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        supply_sensible_lkage_to_air_handler_actuator.setName("#{other_equip.name} act")
        
        # Supply duct latent lkage impact on the air handler zone.
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip_def.setName(supply_latent_lkage_to_air_handler + " equip")
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName(other_equip_def.name.to_s)
        other_equip.setFuelType("None")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ducts.duct_location_zone.spaces[0])
        supply_latent_lkage_to_air_handler_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        supply_latent_lkage_to_air_handler_actuator.setName("#{other_equip.name} act")
      
        # Return duct sensible lkage impact on the return plenum
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip_def.setName(return_sensible_lkage + " equip")
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName(other_equip_def.name.to_s)
        other_equip.setFuelType("None")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ra_duct_space)
        return_sensible_lkage_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        return_sensible_lkage_actuator.setName("#{other_equip.name} act")
        
        # Return duct latent lkage impact on the return plenum
        other_equip_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
        other_equip_def.setName(return_latent_lkage + " equip")
        other_equip = OpenStudio::Model::OtherEquipment.new(other_equip_def)
        other_equip.setName(other_equip_def.name.to_s)
        other_equip.setFuelType("None")
        other_equip.setSchedule(model.alwaysOnDiscreteSchedule)
        other_equip.setSpace(ra_duct_space)
        return_latent_lkage_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(other_equip, "OtherEquipment", "Power Level")
        return_latent_lkage_actuator.setName("#{other_equip.name} act")
      
        # Two objects are required to model the air exchange between the air handler zone and the living space since
        # ZoneMixing objects can not account for direction of air flow (both are controlled by EMS)

        # Accounts for lks from the AH zone to the Living zone
        
        zone_mixing_ah_to_living = OpenStudio::Model::ZoneMixing.new(unit.living_zone)
        zone_mixing_ah_to_living.setName(air_handler_to_living_flow_rate + " mix")
        zone_mixing_ah_to_living.setSourceZone(ducts.duct_location_zone)
        zone_mixing_ah_to_living_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(zone_mixing_ah_to_living, "ZoneMixing", "Air Exchange Flow Rate")
        zone_mixing_ah_to_living_actuator.setName("#{zone_mixing_ah_to_living.name} act")

        zone_mixing_living_to_ah = OpenStudio::Model::ZoneMixing.new(ducts.duct_location_zone)
        zone_mixing_living_to_ah.setName(living_to_air_handler_flow_rate + " mix")
        zone_mixing_living_to_ah.setSourceZone(unit.living_zone)
        zone_mixing_living_to_ah_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(zone_mixing_living_to_ah, "ZoneMixing", "Air Exchange Flow Rate")
        zone_mixing_living_to_ah_actuator.setName("#{zone_mixing_living_to_ah.name} act")      
      
        # Sensors
        
        air_handler_mfr_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_mass_flow_rate_output_var)
        air_handler_mfr_sensor.setName(air_handler_mfr + " s")
        air_handler_mfr_sensor.setKeyName(air_demand_inlet_node.name.to_s)        
    
        fan_rtf_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, fan_runtime_fraction_output_var)
        fan_rtf_sensor.setName(fan_rtf + " s")
        fan_rtf_sensor.setKeyName(supply_fan.name.to_s)

        air_handler_vfr_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_current_density_volume_flow_rate_output_var)
        air_handler_vfr_sensor.setName(air_handler_vfr + " s")
        air_handler_vfr_sensor.setKeyName(air_demand_inlet_node.name.to_s)
        
        air_handler_tout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_temp_output_var)
        air_handler_tout_sensor.setName(air_handler_tout + " s")
        air_handler_tout_sensor.setKeyName(air_demand_inlet_node.name.to_s)        
        
        return_air_t_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_temp_output_var)
        return_air_t_sensor.setName(return_air_t + " s")
        return_air_t_sensor.setKeyName(living_zone_return_air_node.name.to_s)
        
        air_handler_wout_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_humidity_ratio_output_var)
        air_handler_wout_sensor.setName(air_handler_wout + " s")
        air_handler_wout_sensor.setKeyName(air_demand_inlet_node.name.to_s)        
        
        return_air_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, system_node_humidity_ratio_output_var)
        return_air_w_sensor.setName(return_air_w + " s")
        return_air_w_sensor.setKeyName(living_zone_return_air_node.name.to_s)
    
        air_handler_t_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_air_temp_output_var)
        air_handler_t_sensor.setName(air_handler_t + " s")
        air_handler_t_sensor.setKeyName(ducts.duct_location_name)        
        
        air_handler_w_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, zone_mean_air_humidity_ratio_output_var)
        air_handler_w_sensor.setName(air_handler_w + " s")
        air_handler_w_sensor.setKeyName(ducts.duct_location_name)
        
        # Global Variables
        
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, air_handler_mfr)        
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, fan_rtf)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, air_handler_vfr)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, air_handler_tout)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, return_air_t)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, air_handler_wout)        
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, return_air_w)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, air_handler_t)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, air_handler_w)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, supply_sensible_lkage_to_living)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, supply_latent_lkage_to_living)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, supply_duct_conduction_to_living)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, supply_duct_conduction_to_air_handler)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, return_duct_conduction_to_plenum)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, return_duct_conduction_to_air_handler)        
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, supply_sensible_lkage_to_air_handler)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, supply_latent_lkage_to_air_handler)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, return_sensible_lkage)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, return_latent_lkage)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, living_to_air_handler_flow_rate)
        ems_global_var = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, air_handler_to_living_flow_rate)        

        # Subroutine
        
        duct_lkage_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
        duct_lkage_subroutine.setName("#{obj_name_ducts} lk subrout")
        duct_lkage_subroutine.addLine("Set f_sup = #{ducts.supply_duct_loss}")
        duct_lkage_subroutine.addLine("Set f_ret = #{ducts.return_duct_loss}")
        duct_lkage_subroutine.addLine("Set f_OA = #{ducts.frac_oa * ducts.total_duct_unbalance}")
        duct_lkage_subroutine.addLine("Set oafrate = f_OA * #{air_handler_vfr_sensor.name}")
        duct_lkage_subroutine.addLine("Set suplkfrate = f_sup * #{air_handler_vfr_sensor.name}")
        duct_lkage_subroutine.addLine("Set retlkfrate = f_ret * #{air_handler_vfr_sensor.name}")
        
        if ducts.return_duct_loss > ducts.supply_duct_loss
          # Supply air flow rate is greater than return flow rate
          # Living zone is pressurized in this case      
          duct_lkage_subroutine.addLine("Set #{living_to_air_handler_flow_rate} = (@Abs (retlkfrate-suplkfrate-oafrate))")
          duct_lkage_subroutine.addLine("Set #{air_handler_to_living_flow_rate} = 0")
          duct_lkage_subroutine.addLine("Set #{duct_lk_supply_fan_equiv} = oafrate")
          duct_lkage_subroutine.addLine("Set #{duct_lk_exhaust_fan_equiv} = 0")
        else
          # Living zone is depressurized in this case
          duct_lkage_subroutine.addLine("Set #{air_handler_to_living_flow_rate} = (@Abs (suplkfrate-retlkfrate-oafrate))")
          duct_lkage_subroutine.addLine("Set #{living_to_air_handler_flow_rate} = 0")
          duct_lkage_subroutine.addLine("Set #{duct_lk_supply_fan_equiv} = 0")
          duct_lkage_subroutine.addLine("Set #{duct_lk_exhaust_fan_equiv} = oafrate")
        end        
      
        if ducts.ducts_not_in_living
          duct_lkage_subroutine.addLine("If #{air_handler_mfr_sensor.name}>0")
          duct_lkage_subroutine.addLine("Set h_SA = (@HFnTdbW #{air_handler_tout_sensor.name} #{air_handler_wout_sensor.name})")
          duct_lkage_subroutine.addLine("Set h_AHZone = (@HFnTdbW #{air_handler_t_sensor.name} #{air_handler_w_sensor.name})")
          duct_lkage_subroutine.addLine("Set h_RA = (@HFnTdbW #{return_air_t_sensor.name} #{return_air_w_sensor.name})")
          duct_lkage_subroutine.addLine("Set h_fg = (@HfgAirFnWTdb #{air_handler_wout_sensor.name} #{air_handler_tout_sensor.name})")
          duct_lkage_subroutine.addLine("Set SALeakageQtot = f_sup * #{air_handler_mfr_sensor.name}*(h_RA - h_SA)")          
          duct_lkage_subroutine.addLine("Set temp1 = h_fg*(#{return_air_w_sensor.name}-#{air_handler_wout_sensor.name})")
          duct_lkage_subroutine.addLine("Set #{supply_latent_lkage_to_living} = f_sup*#{air_handler_mfr_sensor.name}*temp1")
          duct_lkage_subroutine.addLine("Set #{supply_sensible_lkage_to_living} = SALeakageQtot-#{supply_latent_lkage_to_living}")
          duct_lkage_subroutine.addLine("Set eTm = (#{fan_rtf_sensor.name}/(#{air_handler_mfr_sensor.name}*1006.0))*#{OpenStudio.convert(ducts.unconditioned_duct_ua,"Btu/hr*R","W/K").get.round(3)}")
          duct_lkage_subroutine.addLine("Set eTm = 0-eTm")
          duct_lkage_subroutine.addLine("If eTm<-1000")
          duct_lkage_subroutine.addLine("Set tsup = #{air_handler_t_sensor.name}")
          duct_lkage_subroutine.addLine("Else")
          duct_lkage_subroutine.addLine("Set temp4 = #{air_handler_t_sensor.name}")
          duct_lkage_subroutine.addLine("Set tsup = temp4+((#{air_handler_tout_sensor.name}-#{air_handler_t_sensor.name})*(@Exp eTm))")
          duct_lkage_subroutine.addLine("EndIf")
          duct_lkage_subroutine.addLine("Set temp5 = tsup-#{air_handler_tout_sensor.name}")
          duct_lkage_subroutine.addLine("Set #{supply_duct_conduction_to_living} = #{air_handler_mfr_sensor.name}*1006.0*temp5")
          duct_lkage_subroutine.addLine("Set #{supply_duct_conduction_to_air_handler} = 0-#{supply_duct_conduction_to_living}")
          duct_lkage_subroutine.addLine("Set eTm = (#{fan_rtf_sensor.name}/(#{air_handler_mfr_sensor.name}*1006.0))*#{OpenStudio.convert(ducts.return_duct_ua,"Btu/hr*R","W/K").get.round(3)}")
          duct_lkage_subroutine.addLine("Set eTm = 0-eTm")
          duct_lkage_subroutine.addLine("If eTm<-1000")
          duct_lkage_subroutine.addLine("Set tret = #{air_handler_t_sensor.name}")
          duct_lkage_subroutine.addLine("Else")
          duct_lkage_subroutine.addLine("Set temp6 = #{air_handler_t_sensor.name}")
          duct_lkage_subroutine.addLine("Set tret = temp6+((#{return_air_t_sensor.name}-#{air_handler_t_sensor.name})*(@Exp eTm))")
          duct_lkage_subroutine.addLine("EndIf")
          duct_lkage_subroutine.addLine("Set temp7 = tret-#{return_air_t_sensor.name}")
          duct_lkage_subroutine.addLine("Set #{return_duct_conduction_to_plenum} = #{air_handler_mfr_sensor.name}*1006.0*temp7")
          duct_lkage_subroutine.addLine("Set #{return_duct_conduction_to_air_handler} = 0-#{return_duct_conduction_to_plenum}")
          duct_lkage_subroutine.addLine("Set #{return_latent_lkage} = 0")
          duct_lkage_subroutine.addLine("Set temp2 = (#{air_handler_t_sensor.name}-#{return_air_t_sensor.name})")
          duct_lkage_subroutine.addLine("Set #{return_sensible_lkage} = f_ret*#{air_handler_mfr_sensor.name}*1006.0*temp2")
          duct_lkage_subroutine.addLine("Set QtotLeakToAHZn = f_sup*#{air_handler_mfr_sensor.name}*(h_SA-h_AHZone)")
          duct_lkage_subroutine.addLine("Set temp3 = (#{air_handler_wout_sensor.name}-#{air_handler_w_sensor.name})")
          duct_lkage_subroutine.addLine("Set #{supply_latent_lkage_to_air_handler} = f_sup*#{air_handler_mfr_sensor.name}*h_fg*temp3")
          duct_lkage_subroutine.addLine("Set #{supply_sensible_lkage_to_air_handler} = QtotLeakToAHZn-#{supply_latent_lkage_to_air_handler}")
          duct_lkage_subroutine.addLine("Else")
          duct_lkage_subroutine.addLine("Set #{supply_latent_lkage_to_living} = 0")
          duct_lkage_subroutine.addLine("Set #{supply_sensible_lkage_to_living} = 0")
          duct_lkage_subroutine.addLine("Set #{supply_duct_conduction_to_living} = 0")
          duct_lkage_subroutine.addLine("Set #{supply_duct_conduction_to_air_handler} = 0")
          duct_lkage_subroutine.addLine("Set #{return_duct_conduction_to_plenum} = 0")
          duct_lkage_subroutine.addLine("Set #{return_duct_conduction_to_air_handler} = 0")
          duct_lkage_subroutine.addLine("Set #{return_latent_lkage} = 0")
          duct_lkage_subroutine.addLine("Set #{return_sensible_lkage} = 0")
          duct_lkage_subroutine.addLine("Set #{supply_latent_lkage_to_air_handler} = 0")
          duct_lkage_subroutine.addLine("Set #{supply_sensible_lkage_to_air_handler} = 0")
          duct_lkage_subroutine.addLine("EndIf")
        else
          duct_lkage_subroutine.addLine("Set #{supply_latent_lkage_to_living} = 0")
          duct_lkage_subroutine.addLine("Set #{supply_sensible_lkage_to_living} = 0")
          duct_lkage_subroutine.addLine("Set #{supply_duct_conduction_to_living} = 0")
          duct_lkage_subroutine.addLine("Set #{supply_duct_conduction_to_air_handler} = 0")
          duct_lkage_subroutine.addLine("Set #{return_duct_conduction_to_plenum} = 0")
          duct_lkage_subroutine.addLine("Set #{return_duct_conduction_to_air_handler} = 0")
          duct_lkage_subroutine.addLine("Set #{return_latent_lkage} = 0")
          duct_lkage_subroutine.addLine("Set #{return_sensible_lkage} = 0")
          duct_lkage_subroutine.addLine("Set #{supply_latent_lkage_to_air_handler} = 0")
          duct_lkage_subroutine.addLine("Set #{supply_sensible_lkage_to_air_handler} = 0")
        end      
      
        # Program     
        
        duct_lkage_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
        duct_lkage_program.setName(obj_name_ducts + " program")
        duct_lkage_program.addLine("Set #{air_handler_mfr} = #{air_handler_mfr_sensor.name}")
        duct_lkage_program.addLine("Set #{fan_rtf} = #{fan_rtf_sensor.name}")
        duct_lkage_program.addLine("Set #{air_handler_vfr} = #{air_handler_vfr_sensor.name}")
        duct_lkage_program.addLine("Set #{air_handler_tout} = #{air_handler_tout_sensor.name}")
        duct_lkage_program.addLine("Set #{air_handler_wout} = #{air_handler_wout_sensor.name}")
        duct_lkage_program.addLine("Set #{return_air_t} = #{return_air_t_sensor.name}")
        duct_lkage_program.addLine("Set #{return_air_w} = #{return_air_w_sensor.name}")
        duct_lkage_program.addLine("Set #{air_handler_t} = #{air_handler_t_sensor.name}")
        duct_lkage_program.addLine("Set #{air_handler_w} = #{air_handler_w_sensor.name}")
        duct_lkage_program.addLine("Run #{duct_lkage_subroutine.name}")
        duct_lkage_program.addLine("Set #{supply_sensible_lkage_to_living_actuator.name} = #{supply_sensible_lkage_to_living}")
        duct_lkage_program.addLine("Set #{supply_latent_lkage_to_living_actuator.name} = #{supply_latent_lkage_to_living}")
        duct_lkage_program.addLine("Set #{supply_duct_conduction_to_living_actuator.name} = #{supply_duct_conduction_to_living}")
        duct_lkage_program.addLine("Set #{supply_duct_conduction_to_air_handler_actuator.name} = #{supply_duct_conduction_to_air_handler}")
        duct_lkage_program.addLine("Set #{supply_sensible_lkage_to_air_handler_actuator.name} = #{supply_sensible_lkage_to_air_handler}")
        duct_lkage_program.addLine("Set #{supply_latent_lkage_to_air_handler_actuator.name} = #{supply_latent_lkage_to_air_handler}")
        duct_lkage_program.addLine("Set #{return_sensible_lkage_actuator.name} = #{return_sensible_lkage}")
        duct_lkage_program.addLine("Set #{return_latent_lkage_actuator.name} = #{return_latent_lkage}")
        duct_lkage_program.addLine("Set #{return_duct_conduction_to_plenum_actuator.name} = #{return_duct_conduction_to_plenum}")
        duct_lkage_program.addLine("Set #{return_duct_conduction_to_air_handler_actuator.name} = #{return_duct_conduction_to_air_handler}")
        duct_lkage_program.addLine("Set #{zone_mixing_ah_to_living_actuator.name} = #{air_handler_to_living_flow_rate}")
        duct_lkage_program.addLine("Set #{zone_mixing_living_to_ah_actuator.name} = #{living_to_air_handler_flow_rate}")
                
      else # no ducts
      
        # Program
        
        duct_lkage_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
        duct_lkage_program.setName(obj_name_ducts + " program")
        duct_lkage_program.addLine("Set #{duct_lk_supply_fan_equiv} = 0")
        duct_lkage_program.addLine("Set #{duct_lk_exhaust_fan_equiv} = 0")
            
      end # end has ducts loop
    
      # Program Calling Manager
      
      program_calling_manager = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      program_calling_manager.setName(obj_name_ducts + " program calling manager")
      program_calling_manager.setCallingPoint("EndOfSystemTimestepAfterHVACReporting")
      program_calling_manager.addProgram(duct_lkage_program)

      # Store info for HVAC Sizing measure
      building_unit.setFeature(Constants.SizingInfoMechVentType, mech_vent.MechVentType)
      building_unit.setFeature(Constants.SizingInfoMechVentTotalEfficiency, mech_vent.MechVentTotalEfficiency.to_f)
      building_unit.setFeature(Constants.SizingInfoMechVentLatentEffectiveness, mech_vent.MechVentLatentEffectiveness.to_f)
      building_unit.setFeature(Constants.SizingInfoMechVentApparentSensibleEffectiveness, mech_vent.MechVentApparentSensibleEffectiveness.to_f)
      building_unit.setFeature(Constants.SizingInfoMechVentWholeHouseRate, mech_vent.whole_house_vent_rate.to_f)
      if not ducts.DuctSystemEfficiency.nil?
        building_unit.setFeature(Constants.SizingInfoDuctsDSE, ducts.DuctSystemEfficiency.to_f)
      else
        building_unit.setFeature(Constants.SizingInfoDuctsSupplyRvalue, ducts.supply_duct_r.to_f)
        building_unit.setFeature(Constants.SizingInfoDuctsReturnRvalue, ducts.return_duct_r.to_f)
        building_unit.setFeature(Constants.SizingInfoDuctsSupplyLoss, ducts.supply_duct_loss.to_f)
        building_unit.setFeature(Constants.SizingInfoDuctsReturnLoss, ducts.return_duct_loss.to_f)
        building_unit.setFeature(Constants.SizingInfoDuctsSupplySurfaceArea, ducts.supply_duct_surface_area.to_f)
        building_unit.setFeature(Constants.SizingInfoDuctsReturnSurfaceArea, ducts.return_duct_surface_area.to_f)
        building_unit.setFeature(Constants.SizingInfoDuctsLocationZone, ducts.duct_location_name)
        building_unit.setFeature(Constants.SizingInfoDuctsLocationFrac, ducts.DuctLocationFracLeakage.to_f)
      end
      if not unit.living.ELA.nil?
        building_unit.setFeature(Constants.SizingInfoZoneInfiltrationELA(unit.living_zone), unit.living.ELA.to_f)
        building_unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(unit.living_zone), unit.living.inf_flow.to_f)
      else
        building_unit.setFeature(Constants.SizingInfoZoneInfiltrationELA(unit.living_zone), 0.0)
        building_unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(unit.living_zone), 0.0)
      end
      unless unit.finished_basement_zone.nil?
        building_unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(unit.finished_basement_zone), unit.finished_basement.inf_flow)
      end
      
    end # end unit loop
    
    # Store info for HVAC Sizing measure
    units.each do |building_unit|
      unless building.crawlspace_zone.nil?
        building_unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(building.crawlspace_zone), building.crawlspace.inf_flow.to_f)
      end
      unless building.pierbeam_zone.nil?
        building_unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(building.pierbeam_zone), building.pierbeam.inf_flow.to_f)
      end
      unless building.unfinished_basement_zone.nil?
        building_unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(building.unfinished_basement_zone), building.unfinished_basement.inf_flow.to_f)
      end
      unless building.unfinished_attic_zone.nil?
        building_unit.setFeature(Constants.SizingInfoZoneInfiltrationCFM(building.unfinished_attic_zone), building.unfinished_attic.inf_flow)
      end
    end

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
    unless building.pierbeam_zone.nil?
      spaces << building.pierbeam
    end
    unless building.unfinished_attic_zone.nil?
      spaces << building.unfinished_attic
    end 
  
    unless building.garage_zone.nil?
      building.garage.inf_method = @infMethodSG
      building.garage.hor_lk_frac = 0.4 # DOE-2 Default
      building.garage.neutral_level = 0.5 # DOE-2 Default
      building.garage.SLA = Airflow.get_infiltration_SLA_from_ACH50(infil.InfiltrationGarageACH50, 0.67, building.garage.area, building.garage.volume)
      building.garage.ACH = Airflow.get_infiltration_ACH_from_SLA(building.garage.SLA, 1.0, @weather)
      building.garage.inf_flow = building.garage.ACH / OpenStudio.convert(1.0,"hr","min").get * building.garage.volume # cfm          
    end

    unless building.unfinished_basement_zone.nil?
      building.unfinished_basement.inf_method = @infMethodRes # Used for constant ACH
      building.unfinished_basement.inf_flow = building.unfinished_basement.ACH / OpenStudio.convert(1.0,"hr","min").get * building.unfinished_basement.volume
    end

    unless building.crawlspace_zone.nil?
      building.crawlspace.inf_method = @infMethodRes
      building.crawlspace.inf_flow = building.crawlspace.ACH / OpenStudio.convert(1.0,"hr","min").get * building.crawlspace.volume
    end

    unless building.pierbeam_zone.nil?
      building.pierbeam.inf_method = @infMethodRes
      building.pierbeam.inf_flow = building.pierbeam.ACH / OpenStudio.convert(1.0,"hr","min").get * building.pierbeam.volume
    end

    unless building.unfinished_attic_zone.nil?
      building.unfinished_attic.inf_method = @infMethodSG
      building.unfinished_attic.hor_lk_frac = 0.75 # Same as Energy Gauge USA Attic Model
      building.unfinished_attic.neutral_level = 0.5 # DOE-2 Default
      building.unfinished_attic.ACH = Airflow.get_infiltration_ACH_from_SLA(building.unfinished_attic.SLA, 1.0, @weather)
      building.unfinished_attic.inf_flow = building.unfinished_attic.ACH / OpenStudio.convert(1.0,"hr","min").get * building.unfinished_attic.volume
    end
  
    spaces.each do |space|
    
      if space.volume == 0
        space.f_t_SG = 0 # FIXME: until we figure out how to deal with volumes
      else
        space.f_t_SG = wind_speed.site_terrain_multiplier * ((space.height + space.coord_z) / 32.8) ** wind_speed.site_terrain_exponent / (wind_speed.terrain_multiplier * (wind_speed.height / 32.8) ** wind_speed.terrain_exponent)
      end

      if space.inf_method == @infMethodSG
        space.f_s_SG = 2.0 / 3.0 * (1 + space.hor_lk_frac / 2.0) * (2.0 * space.neutral_level * (1.0 - space.neutral_level)) ** 0.5 / (space.neutral_level ** 0.5 + (1.0 - space.neutral_level) ** 0.5)
        space.f_w_SG = wind_speed.shielding_coef * (1.0 - space.hor_lk_frac) ** (1.0 / 3.0) * space.f_t_SG
        space.C_s_SG = space.f_s_SG ** 2.0 * Constants.g * space.height / (Constants.AssumedInsideTemp + 460.0)
        space.C_w_SG = space.f_w_SG ** 2.0
        space.ELA = space.SLA * space.area # ft^2
      end

    end
    
    return infil, building  
  
  end
  
  def _processInfiltrationForUnit(infil, wind_speed, building, unit, has_hvac_flue, has_water_heater_flue, has_fireplace_chimney, runner)
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
          infil.A_o = 0 # FIXME: until we figure out how to deal with volumes
          unit.living.SLA = 0
          unit.living.ELA = 0
          unit.living.ACH = 0
          unit.living.inf_flow = 0
      else
          # Living Space Infiltration
          unit.living.inf_method = @infMethodASHRAE

          # Based on "Field Validation of Algebraic Equations for Stack and
          # Wind Driven Air Infiltration Calculations" by Walker and Wilson (1998)

          # Pressure Exponent
          infil.n_i = 0.67
          
          # Calculate SLA for above-grade portion of the building
          building.SLA = Airflow.get_infiltration_SLA_from_ACH50(infil.InfiltrationLivingSpaceACH50, infil.n_i, building.above_grade_finished_floor_area, building.above_grade_volume)
          
          # Effective Leakage Area (ft^2)
          infil.A_o = building.SLA * building.above_grade_finished_floor_area * (unit.above_grade_exterior_wall_area/building.above_grade_exterior_wall_area)

          # Calculate SLA for unit
          unit.living.SLA = infil.A_o / unit.above_grade_finished_floor_area
    
          # Flow Coefficient (cfm/inH2O^n) (based on ASHRAE HoF)
          infil.C_i = infil.A_o * (2.0 / outside_air_density) ** 0.5 * delta_pref ** (0.5 - infil.n_i) * inf_conv_factor
          
          has_flue = false
          if has_hvac_flue or has_water_heater_flue or has_fireplace_chimney
            has_flue = true
          end

          if has_flue
            infil.Y_i = 0.2 # Fraction of leakage through the flue; 0.2 is a "typical" value according to THE ALBERTA AIR INFIL1RATION MODEL, Walker and Wilson, 1990
            infil.flue_height = building.building_height + 2.0 # ft
            infil.S_wflue = 1.0 # Flue Shelter Coefficient
          else
            infil.Y_i = 0.0 # Fraction of leakage through the flu
            infil.flue_height = 0.0 # ft
            infil.S_wflue = 0.0 # Flue Shelter Coefficient
          end
          
          vented_crawl = false
          if (not building.crawlspace_zone.nil? and building.crawlspace.ACH > 0) or (not building.pierbeam_zone.nil? and building.pierbeam.ACH > 0)
            vented_crawl = true
          end
          
          # Leakage distributions per Iain Walker (LBL) recommendations
          if vented_crawl
            # 15% ceiling, 35% walls, 50% floor leakage distribution for vented crawl
            lkage_ceiling = 0.15
            lkage_walls = 0.35
            lkage_floor = 0.50
          else
            # 25% ceiling, 50% walls, 25% floor leakage distribution for slab/basement/unvented crawl
            lkage_ceiling = 0.25
            lkage_walls = 0.50
            lkage_floor = 0.25          
          end
          if lkage_ceiling + lkage_walls + lkage_floor !=  1
            runner.registerError("Invalid air lkage distribution specified (#{lkage_ceiling}, #{lkage_walls}, #{lkage_floor}); does not add up to 1.")
            return false
          end
          infil.R_i = (lkage_ceiling + lkage_floor)
          infil.X_i = (lkage_ceiling - lkage_floor)
          infil.R_i = infil.R_i * (1 - infil.Y_i)
          infil.X_i = infil.X_i * (1 - infil.Y_i)         
          
          unit.living.hor_lk_frac = infil.R_i
          infil.Z_f = infil.flue_height / (unit.living.height + unit.living.coord_z)

          # Calculate Stack Coefficient
          infil.M_o = (infil.X_i + (2.0 * infil.n_i + 1.0) * infil.Y_i) ** 2.0 / (2 - infil.R_i)

          if infil.M_o <=  1.0
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
          if vented_crawl

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

          unit.living.ACH = Airflow.get_infiltration_ACH_from_SLA(unit.living.SLA, building.stories, @weather)

          # Convert living space ACH to cfm:
          unit.living.inf_flow = unit.living.ACH / OpenStudio.convert(1.0,"hr","min").get * unit.living.volume # cfm
          
      end
          
    end
    
    unless unit.finished_basement_zone.nil?
      unit.finished_basement.inf_method = @infMethodRes # Used for constant ACH
      unit.finished_basement.inf_flow = unit.finished_basement.ACH / OpenStudio.convert(1.0,"hr","min").get * unit.finished_basement.volume
    end

    spaces.each do |space|
      
      if space.volume == 0
        space.f_t_SG = 0 # FIXME: until we figure out how to deal with volumes
      else  
        space.f_t_SG = wind_speed.site_terrain_multiplier * ((space.height + space.coord_z) / 32.8) ** wind_speed.site_terrain_exponent / (wind_speed.terrain_multiplier * (wind_speed.height / 32.8) ** wind_speed.terrain_exponent)
      end

      if space.inf_method == @infMethodSG
        space.f_s_SG = 2.0 / 3.0 * (1 + space.hor_lk_frac / 2.0) * (2.0 * space.neutral_level * (1.0 - space.neutral_level)) ** 0.5 / (space.neutral_level ** 0.5 + (1.0 - space.neutral_level) ** 0.5)
        space.f_w_SG = wind_speed.shielding_coef * (1.0 - space.hor_lk_frac) ** (1.0 / 3.0) * space.f_t_SG
        space.C_s_SG = space.f_s_SG ** 2.0 * Constants.g * space.height / (infil.assumed_inside_temp + 460.0)
        space.C_w_SG = space.f_w_SG ** 2.0
        space.ELA = space.SLA * space.area # ft^2
      elsif space.inf_method == @infMethodASHRAE
        space.ELA = space.SLA * space.area # ft^2
      end

    end
    
    return infil, building, unit
    
  end  
  
  def _processMechanicalVentilationForUnit(model, runner, infil, mech_vent, building, unit)
    # Mechanical Ventilation

    # Get ASHRAE 62.2 required ventilation rate (excluding infiltration credit)
    ashrae_mv_without_infil_credit = Airflow.get_mech_vent_whole_house_cfm(1, unit.num_bedrooms, unit.finished_floor_area, mech_vent.MechVentASHRAEStandard) 
    
    # Determine mechanical ventilation infiltration credit (per ASHRAE 62.2)
    infil.rate_credit = 0 # default to no credit
    if mech_vent.MechVentInfilCredit
        if mech_vent.MechVentASHRAEStandard == '2010' and unit.is_existing_home
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

    mech_vent.max_power = [mech_vent.bathroom_hour_avg_exhaust * mech_vent.MechVentSpotFanPower + mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans, mech_vent.range_hood_hour_avg_exhaust * mech_vent.MechVentSpotFanPower + mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans].max / OpenStudio.convert(1.0,"kW","W").get # kW

    # Fan energy schedule (as fraction of maximum power). Bathroom
    # exhaust at 7:00am and range hood exhaust at 6:00pm. Clothes
    # dryer exhaust not included in mech vent power.
    if mech_vent.max_power > 0
      mech_vent.hourly_energy_schedule = Array.new(24, mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans / OpenStudio.convert(1.0,"kW","W").get / mech_vent.max_power)
      mech_vent.hourly_energy_schedule[6] = ((mech_vent.bathroom_hour_avg_exhaust * mech_vent.MechVentSpotFanPower + mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans) / OpenStudio.convert(1.0,"kW","W").get / mech_vent.max_power)
      mech_vent.hourly_energy_schedule[17] = ((mech_vent.range_hood_hour_avg_exhaust * mech_vent.MechVentSpotFanPower + mech_vent.whole_house_vent_rate * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans) / OpenStudio.convert(1.0,"kW","W").get / mech_vent.max_power)
      mech_vent.average_vent_fan_eff = ((mech_vent.whole_house_vent_rate * 24.0 * mech_vent.MechVentHouseFanPower * mech_vent.num_vent_fans + (mech_vent.bathroom_hour_avg_exhaust + mech_vent.range_hood_hour_avg_exhaust) * mech_vent.MechVentSpotFanPower) / (mech_vent.whole_house_vent_rate * 24.0 + mech_vent.bathroom_hour_avg_exhaust + mech_vent.range_hood_hour_avg_exhaust))
    else
      mech_vent.hourly_energy_schedule = Array.new(24, 0.0)
    end
    
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

      m_fan = OpenStudio.convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get * 16.02 * Psychrometrics.rhoD_fT_w_P(OpenStudio.convert(t_sup_in,"C","F").get, w_sup_in, 14.7) # kg/s

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

      # Use summer test condition to determine the latent effectiveness since TRE is generally specified under the summer condition
      if mech_vent.MechVentTotalEfficiency > 0

        t_sup_in = 35.0
        w_sup_in = 0.0178
        t_exh_in = 24.0
        w_exh_in = 0.0092

        m_fan = OpenStudio.convert(mech_vent.whole_house_vent_rate,"cfm","m^3/s").get * UnitConversion.lbm_ft32kg_m3(Psychrometrics.rhoD_fT_w_P(OpenStudio.convert(t_sup_in,"C","F").get, w_sup_in, 14.7)) # kg/s

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

    return mech_vent

  end

  def _processNaturalVentilationForUnit(model, runner, nat_vent, wind_speed, infil, building, unit)
    
    thermostatsetpointdualsetpoint = unit.living_zone.thermostatSetpointDualSetpoint
    
    # Get heating setpoints
    heatingSetpointWeekday = Array.new(24, Constants.NoHeatingSetpoint)
    heatingSetpointWeekend = Array.new(24, Constants.NoHeatingSetpoint)
    if thermostatsetpointdualsetpoint.is_initialized
      thermostatsetpointdualsetpoint.get.heatingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
        if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value > heatingSetpointWeekday[hour]
              heatingSetpointWeekday[hour] = OpenStudio.convert(value,"C","F").get
            end
          end
        end
        if rule.applySaturday and rule.applySunday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value > heatingSetpointWeekend[hour]
              heatingSetpointWeekend[hour] = OpenStudio.convert(value,"C","F").get
            end
          end
        end
      end
    end
    
    # Get cooling setpoints
    coolingSetpointWeekday = Array.new(24, Constants.NoCoolingSetpoint)
    coolingSetpointWeekend = Array.new(24, Constants.NoCoolingSetpoint)
    if thermostatsetpointdualsetpoint.is_initialized
      thermostatsetpointdualsetpoint.get.coolingSetpointTemperatureSchedule.get.to_Schedule.get.to_ScheduleRuleset.get.scheduleRules.each do |rule|
        if rule.applyMonday and rule.applyTuesday and rule.applyWednesday and rule.applyThursday and rule.applyFriday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value < coolingSetpointWeekday[hour]
              coolingSetpointWeekday[hour] = OpenStudio.convert(value,"C","F").get
            end
          end
        end
        if rule.applySaturday and rule.applySunday
          rule.daySchedule.values.each_with_index do |value, hour|
            if value < coolingSetpointWeekend[hour]
              coolingSetpointWeekend[hour] = OpenStudio.convert(value,"C","F").get
            end
          end
        end
      end
    end

    if heatingSetpointWeekday.all? {|x| x == Constants.NoHeatingSetpoint}
      runner.registerWarning("No heating setpoint schedule found. Assuming #{Constants.DefaultHeatingSetpoint} F for natural ventilation calculations.")
      nat_vent.ovlp_ssn_hourly_temp = Array.new(24, OpenStudio.convert(Constants.DefaultHeatingSetpoint + nat_vent.NatVentOvlpSsnSetpointOffset,"F","C").get)
    else
      nat_vent.ovlp_ssn_hourly_temp = Array.new(24, OpenStudio.convert([heatingSetpointWeekday.max, heatingSetpointWeekend.max].max + nat_vent.NatVentOvlpSsnSetpointOffset,"F","C").get)
    end
    if coolingSetpointWeekday.all? {|x| x == Constants.NoCoolingSetpoint}
      runner.registerWarning("No cooling setpoint schedule found. Assuming #{Constants.DefaultCoolingSetpoint} F for natural ventilation calculations.")
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
      if x == Constants.NoCoolingSetpoint
        nat_vent.htg_ssn_hourly_temp << OpenStudio.convert(Constants.DefaultCoolingSetpoint - nat_vent.NatVentHtgSsnSetpointOffset,"F","C").get
      else
        nat_vent.htg_ssn_hourly_temp << OpenStudio.convert(x - nat_vent.NatVentHtgSsnSetpointOffset,"F","C").get
      end
    end
    nat_vent.htg_ssn_hourly_weekend_temp = Array.new
    coolingSetpointWeekend.each do |x|
      if x == Constants.NoCoolingSetpoint
        nat_vent.htg_ssn_hourly_weekend_temp << OpenStudio.convert(Constants.DefaultCoolingSetpoint - nat_vent.NatVentHtgSsnSetpointOffset,"F","C").get
      else
        nat_vent.htg_ssn_hourly_weekend_temp << OpenStudio.convert(x - nat_vent.NatVentHtgSsnSetpointOffset,"F","C").get
      end
    end

    nat_vent.clg_ssn_hourly_temp = Array.new
    heatingSetpointWeekday.each do |x|
      if x == Constants.NoHeatingSetpoint
        nat_vent.clg_ssn_hourly_temp << OpenStudio.convert(Constants.DefaultHeatingSetpoint + nat_vent.NatVentClgSsnSetpointOffset,"F","C").get
      else
        nat_vent.clg_ssn_hourly_temp << OpenStudio.convert(x + nat_vent.NatVentClgSsnSetpointOffset,"F","C").get
      end
    end
    nat_vent.clg_ssn_hourly_weekend_temp = Array.new
    heatingSetpointWeekend.each do |x|
      if x == Constants.NoHeatingSetpoint
        nat_vent.clg_ssn_hourly_weekend_temp << OpenStudio.convert(Constants.DefaultHeatingSetpoint + nat_vent.NatVentClgSsnSetpointOffset,"F","C").get
      else
        nat_vent.clg_ssn_hourly_weekend_temp << OpenStudio.convert(x + nat_vent.NatVentClgSsnSetpointOffset,"F","C").get
      end
    end

    # Explanation for FRAC-VENT-AREA equation:
    # From DOE22 Vol2-Dictionary: For VENT-METHOD = S-G, this is 0.6 times
    # the open window area divided by the floor area.
    # According to 2010 BA Benchmark, 33% of the windows on any facade will
    # be open at any given time and can only be opened to 20% of their area.

    nat_vent.area = 0.6 * unit.window_area * nat_vent.NatVentFractionWindowsOpen * nat_vent.NatVentFractionWindowAreaOpen # ft^2 (For S-G, this is 0.6*(open window area))
    nat_vent.max_rate = 20.0 # Air Changes per hour
    nat_vent.max_flow_rate = nat_vent.max_rate * unit.living.volume / OpenStudio.convert(1.0,"hr","min").get
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
      
    nat_vent.temp_hourly_wkdy = []
    nat_vent.temp_hourly_wked = []
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
      nat_vent.temp_hourly_wkdy << ssn_schedule_wkdy
      nat_vent.temp_hourly_wked << ssn_schedule_wked
    end

    return nat_vent

  end
  
  def _processDuctsForUnit(model, runner, ducts, building, unit)
  
    ducts.has_forced_air_equipment = false
    model.getAirLoopHVACs.each do |air_loop|
      next unless air_loop.thermalZones.include? unit.living_zone
      ducts.has_forced_air_equipment = true
    end
    
    if (ducts.DuctLocation != "none" or not ducts.DuctSystemEfficiency.nil?) and not ducts.has_forced_air_equipment
      runner.registerWarning("No ducted HVAC equipment was found but ducts were specified. Overriding duct specification.")
      ducts.DuctLocation = "none"
      ducts.DuctSystemEfficiency = nil
    end        
    
    ducts.duct_location_zone, ducts.duct_location_name = get_duct_location(runner, ducts.DuctLocation, building, unit)

    ducts.has_ducts = true  
    if ducts.duct_location_name == "none" or not ducts.DuctSystemEfficiency.nil?
      ducts.duct_location_zone = unit.living_zone
      ducts.duct_location_name = unit.living_zone.name.to_s
      ducts.has_ducts = false
    end      
    
    unless HVAC.has_mini_split_heat_pump(model, runner, unit.living_zone, unit, false).nil?
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
    
    if not ducts.DuctSystemEfficiency.nil? and ducts.has_forced_air_equipment    
      ducts.ducts_not_in_living = true
      ducts.has_ducts = true      
    end
    
    ducts.num_stories_for_ducts = building.stories
    unless unit.finished_basement_zone.nil?
      ducts.num_stories_for_ducts +=  1
    end
    
    ducts.num_stories = ducts.num_stories_for_ducts
        
    if ducts.DuctNormLeakageToOutside.nil?
      # Normalize values in case user inadvertently entered values that add up to the total duct leakage, 
      # as opposed to adding up to 1
      sumFractionOfTotal = (ducts.DuctSupplyLeakageFractionOfTotal + ducts.DuctReturnLeakageFractionOfTotal + ducts.DuctAHSupplyLeakageFractionOfTotal + ducts.DuctAHReturnLeakageFractionOfTotal)
      if sumFractionOfTotal > 0
        ducts.DuctSupplyLeakageFractionOfTotal = ducts.DuctSupplyLeakageFractionOfTotal / sumFractionOfTotal
        ducts.DuctReturnLeakageFractionOfTotal = ducts.DuctReturnLeakageFractionOfTotal / sumFractionOfTotal
        ducts.DuctAHSupplyLeakageFractionOfTotal = ducts.DuctAHSupplyLeakageFractionOfTotal / sumFractionOfTotal
        ducts.DuctAHReturnLeakageFractionOfTotal = ducts.DuctAHReturnLeakageFractionOfTotal / sumFractionOfTotal
      end        
      # Calculate actual leakages from percentages
      ducts.DuctSupplyLeakage = ducts.DuctSupplyLeakageFractionOfTotal * ducts.DuctTotalLeakage
      ducts.DuctReturnLeakage = ducts.DuctReturnLeakageFractionOfTotal * ducts.DuctTotalLeakage
      ducts.DuctAHSupplyLeakage = ducts.DuctAHSupplyLeakageFractionOfTotal * ducts.DuctTotalLeakage
      ducts.DuctAHReturnLeakage = ducts.DuctAHReturnLeakageFractionOfTotal * ducts.DuctTotalLeakage     
    end      
    
    # Fraction of ducts in primary duct location (remaining ducts are in above-grade conditioned space).
    ducts.DuctLocationFracLeakage = Airflow.get_duct_location_frac_leakage(ducts.DuctLocationFrac, ducts.num_stories)
        
    ducts.DuctLocationFracConduction = ducts.DuctLocationFracLeakage
    ducts.DuctNumReturns = Airflow.get_duct_num_returns(ducts.DuctNumReturns, ducts.num_stories)
    ducts.supply_duct_surface_area = Airflow.get_duct_supply_surface_area(ducts.DuctSupplySurfaceAreaMultiplier, unit.finished_floor_area, ducts.num_stories)
    ducts.return_duct_surface_area = Airflow.get_duct_return_surface_area(ducts.DuctReturnSurfaceAreaMultiplier, unit.finished_floor_area, ducts.num_stories, ducts.DuctNumReturns)
    
    # Calculate Duct UA value
    if ducts.ducts_not_in_living
      ducts.unconditioned_duct_area = ducts.supply_duct_surface_area * ducts.DuctLocationFracConduction
      ducts.supply_duct_r = Airflow.get_duct_insulation_rvalue(ducts.DuctRvalue, true)
      ducts.return_duct_r = Airflow.get_duct_insulation_rvalue(ducts.DuctRvalue, false)
      ducts.unconditioned_duct_ua = ducts.unconditioned_duct_area / ducts.supply_duct_r
      ducts.return_duct_ua = ducts.return_duct_surface_area / ducts.return_duct_r
    else
      ducts.DuctLocationFracConduction = 0
      ducts.unconditioned_duct_ua = 0
      ducts.return_duct_ua = 0
      ducts.supply_duct_r = 0
      ducts.return_duct_r = 0
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
    
    unless ducts.DuctNormLeakageToOutside.nil?
      fan_AirFlowRate = 1000.0 # TODO: what should fan_AirFlowRate be?
      ducts = calc_duct_lkage_from_test(ducts, unit.finished_floor_area, fan_AirFlowRate)
    end
    
    ducts.total_duct_unbalance = (ducts.supply_duct_loss - ducts.return_duct_loss).abs
    ducts.frac_oa = nil

    if not ducts.duct_location_name == unit.living_zone.name.to_s and not ducts.duct_location_name == "none" and ducts.supply_duct_loss > 0
      # Calculate d.frac_oa = fraction of unbalanced make-up air that is outside air
      if ducts.total_duct_unbalance <=  0
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
        unless building.pierbeam_zone.nil?
          if building.pierbeam_zone == ducts.duct_location_zone and building.pierbeam.ACH == 0
            ducts.frac_oa = ducts.direct_oa_supply_duct_loss / ducts.total_duct_unbalance
          end
        end
        unless building.unfinished_attic_zone.nil?
          if building.unfinished_attic_zone == ducts.duct_location_zone and building.unfinished_attic.ACH == 0
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
    
    return ducts
  
  end
  
  def get_duct_location(runner, duct_location, building, unit)
    # FIXME: Need to improve this
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
      elsif not building.pierbeam_zone.nil?
        duct_location_zone = building.pierbeam_zone
        duct_location_name = building.pierbeam_zone.name.to_s
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
        duct_location_zone = unit.living_zone
        duct_location_name = unit.living_zone.name.to_s
      end
    elsif duct_location == Constants.FinishedBasementZone
      if not unit.finished_basement_zone.nil?
        duct_location_zone = unit.finished_basement_zone
        duct_location_name = unit.finished_basement_zone.name.to_s
      else
        duct_location_zone = unit.living_zone
        duct_location_name = unit.living_zone.name.to_s
      end
    elsif duct_location == Constants.UnfinishedBasementZone
      if not building.unfinished_basement_zone.nil?
        duct_location_zone = building.unfinished_basement_zone
        duct_location_name = building.unfinished_basement_zone.name.to_s
      else
        duct_location_zone = unit.living_zone
        duct_location_name = unit.living_zone.name.to_s
      end
    elsif duct_location == Constants.AtticZone or duct_location == Constants.UnfinishedAtticZone
      if not building.unfinished_attic_zone.nil?
        duct_location_zone = building.unfinished_attic_zone
        duct_location_name = building.unfinished_attic_zone.name.to_s
      else
        duct_location_zone = unit.living_zone
        duct_location_name = unit.living_zone.name.to_s
      end
    elsif duct_location == Constants.LivingZone or duct_location == Constants.FinishedAtticZone
      duct_location_zone = unit.living_zone
      duct_location_name = unit.living_zone.name.to_s
    elsif duct_location == Constants.GarageZone
      if not building.garage_zone.nil?
        duct_location_zone = building.garage_zone
        duct_location_name = building.garage_zone.name.to_s
      else
        duct_location_zone = unit.living_zone
        duct_location_name = unit.living_zone.name.to_s
      end
    elsif duct_location == Constants.CrawlZone
      if not building.crawlspace_zone.nil?
        duct_location_zone = building.crawlspace_zone
        duct_location_name = building.crawlspace_zone.name.to_s
      else
        duct_location_zone = unit.living_zone
        duct_location_name = unit.living_zone.name.to_s
      end
    elsif duct_location == Constants.PierBeamZone
      if not building.pierbeam_zone.nil?
        duct_location_zone = building.pierbeam_zone
        duct_location_name = building.pierbeam_zone.name.to_s
      else
        duct_location_zone = unit.living_zone
        duct_location_name = unit.living_zone.name.to_s
      end
    end
    return duct_location_zone, duct_location_name
  end  
  
  def calc_duct_lkage_from_test(ducts, ffa, fan_AirFlowRate)
    '''
    Calculates duct leakage inputs based on duct blaster type lkage measurements (cfm @ 25 Pa per 100 ft2 conditioned floor area).
    Requires assumptions about supply/return leakage split, air handler leakage, and duct plenum (de)pressurization. 
    '''
    # Assumptions
    supply_duct_lkage_frac = 0.67 # 2013 RESNET Standards, Appendix A, p.A-28
    return_duct_lkage_frac = 0.33 # 2013 RESNET Standards, Appendix A, p.A-28
    ah_lkage = 0.025 # 2.5% of air handler flow at 25 P (Reference: ASHRAE Standard 152-2004, Annex C, p 33; Walker et al 2010. "Air Leakage of Furnaces and Air Handlers") 
    ah_supply_frac = 0.20 # (Reference: Walker et al 2010. "Air Leakage of Furnaces and Air Handlers") 
    ah_return_frac = 0.80 # (Reference: Walker et al 2010. "Air Leakage of Furnaces and Air Handlers") 
    p_supply = 25.0 # Assume average operating pressure in ducts is 25 Pa, 
    p_return = 25.0 # though it is likely lower (Reference: Pigg and Francisco 2008 "A Field Study of Exterior Duct Leakage in New Wisconsin Homes")

    # Conversion
    cfm25 = ducts.DuctNormLeakageToOutside * ffa / 100.0 #denormalize leakage
    ah_cfm25 = ah_lkage * fan_AirFlowRate # air handler leakage flow rate at 25 Pa
    ah_supply_lk_cfm25 = [ah_cfm25 * ah_supply_frac, cfm25 * supply_duct_lkage_frac].min
    ah_return_lk_cfm25 = [ah_cfm25 * ah_return_frac, cfm25 * return_duct_lkage_frac].min
    supply_lk_cfm25 = [cfm25 * supply_duct_lkage_frac - ah_supply_lk_cfm25, 0].max
    return_lk_cfm25 = [cfm25 * return_duct_lkage_frac - ah_return_lk_cfm25, 0].max
    
    ducts.supply_lk_oper = Airflow.calc_duct_lkage_at_diff_pressure(supply_lk_cfm25, 25.0, p_supply) # cfm at operating pressure
    ducts.return_lk_oper = Airflow.calc_duct_lkage_at_diff_pressure(return_lk_cfm25, 25.0, p_return) # cfm at operating pressure
    ducts.ah_supply_lk_oper = Airflow.calc_duct_lkage_at_diff_pressure(ah_supply_lk_cfm25, 25.0, p_supply) # cfm at operating pressure
    ducts.ah_return_lk_oper = Airflow.calc_duct_lkage_at_diff_pressure(ah_return_lk_cfm25, 25.0, p_return) # cfm at operating pressure
    
    if fan_AirFlowRate == 0
        ducts.DuctSupplyLeakage = 0
        ducts.DuctReturnLeakage = 0
        ducts.DuctAHSupplyLeakage = 0
        ducts.DuctAHReturnLeakage = 0
    else
        ducts.DuctSupplyLeakage = ducts.supply_lk_oper / fan_AirFlowRate
        ducts.DuctReturnLeakage = ducts.return_lk_oper / fan_AirFlowRate
        ducts.DuctAHSupplyLeakage = ducts.ah_supply_lk_oper / fan_AirFlowRate
        ducts.DuctAHReturnLeakage = ducts.ah_return_lk_oper / fan_AirFlowRate
    end

    ducts.supply_duct_loss = ducts.DuctSupplyLeakage + ducts.DuctAHSupplyLeakage
    ducts.return_duct_loss = ducts.DuctReturnLeakage + ducts.DuctAHReturnLeakage

    # Leakage to outside was specified, so don't account for location fraction 
    ducts.DuctLocationFracLeakage = 1
    
    return ducts
  end
  
end

# register the measure to be used by the application
ResidentialAirflow.new.registerWithApplication