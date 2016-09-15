#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/psychrometrics"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/hvac"

#start the measure
class ProcessAirflow < OpenStudio::Ruleset::WorkspaceUserScript

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
    
    attr_accessor(:DuctLocation, :has_ducts, :ducts_not_in_living, :num_stories, :num_stories_for_ducts, :DuctLocationFrac, :DuctLocationFracLeakage, :DuctLocationFracConduction, :DuctSupplyLeakageFractionOfTotal, :DuctReturnLeakageFractionOfTotal, :DuctAHSupplyLeakageFractionOfTotal, :DuctAHReturnLeakageFractionOfTotal, :DuctSupplyLeakage, :DuctReturnLeakage, :DuctAHSupplyLeakage, :DuctAHReturnLeakage, :DuctNumReturns, :supply_duct_surface_area, :return_duct_surface_area, :unconditioned_duct_area, :supply_duct_r, :return_duct_r, :unconditioned_duct_ua, :return_duct_ua, :supply_duct_volume, :return_duct_volume, :direct_oa_supply_duct_loss, :supply_duct_loss, :return_duct_loss, :supply_leak_oper, :return_leak_oper, :ah_supply_leak_oper, :ah_return_leak_oper, :total_duct_unbalance, :frac_oa, :oa_duct_makeup)
    
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
    def initialize
    end
    attr_accessor(:height, :area, :volume, :coord_z, :inf_method, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class Garage
    def initialize
    end
    attr_accessor(:height, :area, :volume, :coord_z, :inf_method, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)
  end

  class FinBasement
    def initialize(fbsmtACH)
      @fbsmtACH = fbsmtACH
    end

    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)

    def FBsmtACH
      return @fbsmtACH
    end
  end

  class UnfinBasement
    def initialize(ufbsmtACH)
      @ufbsmtACH = ufbsmtACH
    end

    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)

    def UFBsmtACH
      return @ufbsmtACH
    end
  end

  class Crawl
    def initialize(crawlACH)
      @crawlACH = crawlACH
    end

    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)

    def CrawlACH
      return @crawlACH
    end
  end

  class UnfinAttic
    def initialize(uaSLA)
      @uaSLA = uaSLA
    end

    attr_accessor(:height, :area, :volume, :inf_method, :coord_z, :SLA, :ACH, :inf_flow, :hor_leak_frac, :neutral_level, :f_t_SG, :f_s_SG, :f_w_SG, :C_s_SG, :C_w_SG, :ELA)

    def UASLA
      return @uaSLA
    end
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

  class Geom
    def initialize
    end
    attr_accessor(:finished_floor_area, :above_grade_finished_floor_area, :building_height, :stories, :window_area, :num_units, :above_grade_volume, :above_grade_exterior_wall_area, :SLA)    
  end
  
  class Unit
    def initialize
    end    
    attr_accessor(:num_bedrooms, :num_bathrooms, :above_grade_exterior_wall_area, :above_grade_finished_floor_area, :finished_floor_area)    
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

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Airflow"
  end
  
  def description
    return "This measure processes infiltration for the living space, garage, finished basement, unfinished basement, crawlspace, and unfinished attic. It also processes mechanical ventilation and natural ventilation for the living space."
  end
  
  def modeler_description
    return "Using EMS code, this measure processes the building's airflow (infiltration, mechanical ventilation, and natural ventilation). Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end     
  
  def get_least_neighbor_offset(workspace)
	neighborOffset = 10000
	surfaces = workspace.getObjectsByType("BuildingSurface:Detailed".to_IddObjectType)
	surfaces.each do |surface|
		next unless surface.getString(1).to_s == "Wall"
		vertices1 = []
		vertices1 << [surface.getString(10).get.to_f, surface.getString(11).get.to_f, surface.getString(12).get.to_f]
		vertices1 << [surface.getString(13).get.to_f, surface.getString(14).get.to_f, surface.getString(15).get.to_f]
		vertices1 << [surface.getString(16).get.to_f, surface.getString(17).get.to_f, surface.getString(18).get.to_f]
		begin
			vertices1 << [surface.getString(19).get.to_f, surface.getString(20).get.to_f, surface.getString(21).get.to_f]
		rescue
		end
		vertices1.each do |vertex1|
			shading_surfaces = workspace.getObjectsByType("Shading:Building:Detailed".to_IddObjectType)
			shading_surfaces.each do |shading_surface|
				next unless shading_surface.getString(0).to_s.downcase.include? "neighbor"
				vertices2 = []
				vertices2 << [shading_surface.getString(3).get.to_f, shading_surface.getString(4).get.to_f, shading_surface.getString(5).get.to_f]
				vertices2 << [shading_surface.getString(6).get.to_f, shading_surface.getString(7).get.to_f, shading_surface.getString(8).get.to_f]
				vertices2 << [shading_surface.getString(9).get.to_f, shading_surface.getString(10).get.to_f, shading_surface.getString(11).get.to_f]
				begin
					vertices2 << [shading_surface.getString(12).get.to_f, shading_surface.getString(13).get.to_f, shading_surface.getString(14).get.to_f]
				rescue
				end
				vertices2.each do |vertex2|
					if Math.sqrt((vertex2[0] - vertex1[0]) ** 2 + (vertex2[1] - vertex1[1]) ** 2 + (vertex2[2] - vertex1[2]) ** 2) < neighborOffset
						neighborOffset = Math.sqrt((vertex2[0] - vertex1[0]) ** 2 + (vertex2[1] - vertex1[1]) ** 2 + (vertex2[2] - vertex1[2]) ** 2)
					end								
				end
			end
		end
	end
	if neighborOffset == 10000
		neighborOffset = 0
	end
	return OpenStudio::convert(neighborOffset,"m","ft").get
  end
  
  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    # Air Leakage

    #make a double argument for infiltration of living space
    userdefined_inflivingspace = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinflivingspace", false)
    userdefined_inflivingspace.setDisplayName("Air Leakage: Above-Grade Living Space ACH50")
    userdefined_inflivingspace.setUnits("1/hr")
    userdefined_inflivingspace.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for above-grade living space (including finished attic).")
    userdefined_inflivingspace.setDefaultValue(7)
    args << userdefined_inflivingspace

    #make a double argument for infiltration of garage
    userdefined_garage = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfgarage", false)
    userdefined_garage.setDisplayName("Garage: ACH50")
    userdefined_garage.setUnits("1/hr")
    userdefined_garage.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for the garage.")
    userdefined_garage.setDefaultValue(7)
    args << userdefined_garage

    #make a double argument for infiltration of finished basement
    userdefined_inffbsmt = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinffbsmt", false)
    userdefined_inffbsmt.setDisplayName("Finished Basement: Constant ACH")
    userdefined_inffbsmt.setUnits("1/hr")
    userdefined_inffbsmt.setDescription("Constant air exchange rate, in Air Changes per Hour (ACH), for the finished basement.")
    userdefined_inffbsmt.setDefaultValue(0.0)
    args << userdefined_inffbsmt
	
    #make a double argument for infiltration of unfinished basement
    userdefined_infufbsmt = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfufbsmt", false)
    userdefined_infufbsmt.setDisplayName("Unfinished Basement: Constant ACH")
    userdefined_infufbsmt.setUnits("1/hr")
    userdefined_infufbsmt.setDescription("Constant air exchange rate, in Air Changes per Hour (ACH), for the unfinished basement. A value of 0.10 ACH or greater is recommended for modeling Heat Pump Water Heaters in unfinished basements.")
    userdefined_infufbsmt.setDefaultValue(0.1)
    args << userdefined_infufbsmt
	
    #make a double argument for infiltration of crawlspace
    userdefined_infcrawl = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfcrawl", false)
    userdefined_infcrawl.setDisplayName("Crawlspace: Constant ACH")
    userdefined_infcrawl.setUnits("1/hr")
    userdefined_infcrawl.setDescription("Air exchange rate, in Air Changes per Hour at 50 Pascals (ACH50), for the crawlspace.")
    userdefined_infcrawl.setDefaultValue(0.0)
    args << userdefined_infcrawl

    #make a double argument for infiltration of unfinished attic
    userdefined_infunfinattic = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedinfunfinattic", false)
    userdefined_infunfinattic.setDisplayName("Unfinished Attic: SLA")
    userdefined_infunfinattic.setDescription("Ratio of the effective leakage area (infiltration and/or ventilation) in the unfinished attic to the total floor area of the attic.")
    userdefined_infunfinattic.setDefaultValue(0.00333)
    args << userdefined_infunfinattic

    #make a double argument for shelter coefficient
    userdefined_infsheltercoef = OpenStudio::Ruleset::OSArgument::makeStringArgument("userdefinedinfsheltercoef", false)
    userdefined_infsheltercoef.setDisplayName("Air Leakage: Shelter Coefficient")
    userdefined_infsheltercoef.setDescription("The local shelter coefficient (AIM-2 infiltration model) accounts for nearby buildings, trees and obstructions.")
    userdefined_infsheltercoef.setDefaultValue("auto")
    args << userdefined_infsheltercoef

    # Age of Home

    #make a double argument for existing or new construction
    userdefined_homeage = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhomeage", true)
    userdefined_homeage.setDisplayName("Age of Home")
    userdefined_homeage.setUnits("yrs")
    userdefined_homeage.setDescription("Age of home [Enter 0 for New Construction].")
    userdefined_homeage.setDefaultValue(0)
    args << userdefined_homeage

    # Terrain

    #make a choice arguments for terrain type
    terrain_types_names = OpenStudio::StringVector.new
    terrain_types_names << Constants.TerrainOcean
    terrain_types_names << Constants.TerrainPlains
    terrain_types_names << Constants.TerrainRural
    terrain_types_names << Constants.TerrainSuburban
    terrain_types_names << Constants.TerrainCity
    selected_terraintype = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedterraintype", terrain_types_names, true)
    selected_terraintype.setDisplayName("Site Terrain")
    selected_terraintype.setDescription("The terrain of the site.")
    selected_terraintype.setDefaultValue("suburban")
    args << selected_terraintype

    # Mechanical Ventilation

    #make a choice argument for ventilation type
    ventilation_types_names = OpenStudio::StringVector.new
    ventilation_types_names << "none"
    ventilation_types_names << Constants.VentTypeExhaust
    ventilation_types_names << Constants.VentTypeSupply
    ventilation_types_names << Constants.VentTypeBalanced
    selected_venttype = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedventtype", ventilation_types_names, false)
    selected_venttype.setDisplayName("Mechanical Ventilation: Ventilation Type")
    selected_venttype.setDefaultValue("exhaust")
    args << selected_venttype

    #make a bool argument for infiltration credit
    selected_infilcredit = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedinfilcredit",false)
    selected_infilcredit.setDisplayName("Mechanical Ventilation: Allow Infiltration Credit")
    selected_infilcredit.setDescription("Defines whether the infiltration credit allowed per the ASHRAE 62.2 Standard will be included in the calculation of the mechanical ventilation rate. If True, the infiltration credit will apply 1) to new/existing single-family detached homes for 2013 ASHRAE 62.2, or 2) to existing single-family detached or multi-family homes for 2010 ASHRAE 62.2.")
    selected_infilcredit.setDefaultValue(true)
    args << selected_infilcredit

    #make a double argument for total efficiency
    userdefined_totaleff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedtotaleff",false)
    userdefined_totaleff.setDisplayName("Mechanical Ventilation: Total Recovery Efficiency")
    userdefined_totaleff.setDescription("The net total energy (sensible plus latent, also called enthalpy) recovered by the supply airstream adjusted by electric consumption, case heat loss or heat gain, air leakage and airflow mass imbalance between the two airstreams, as a percent of the potential total energy that could be recovered plus the exhaust fan energy.")
    userdefined_totaleff.setDefaultValue(0)
    args << userdefined_totaleff

    #make a double argument for sensible efficiency
    userdefined_senseff = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedsenseff",false)
    userdefined_senseff.setDisplayName("Mechanical Ventilation: Sensible Recovery Efficiency")
    userdefined_senseff.setDescription("The net sensible energy recovered by the supply airstream as adjusted by electric consumption, case heat loss or heat gain, air leakage, airflow mass imbalance between the two airstreams and the energy used for defrost (when running the Very Low Temperature Test), as a percent of the potential sensible energy that could be recovered plus the exhaust fan energy.")
    userdefined_senseff.setDefaultValue(0)
    args << userdefined_senseff

    #make a double argument for house fan power
    userdefined_fanpower = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfanpower",false)
    userdefined_fanpower.setDisplayName("Mechanical Ventilation: Fan Power")
    userdefined_fanpower.setUnits("W/cfm")
    userdefined_fanpower.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of fan(s) providing whole house ventilation. If the house uses a balanced ventilation system there is assumed to be two fans operating at this efficiency.")
    userdefined_fanpower.setDefaultValue(0.3)
    args << userdefined_fanpower

    #make a double argument for fraction of ashrae
    userdefined_fracofashrae = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfracofashrae",false)
    userdefined_fracofashrae.setDisplayName("Mechanical Ventilation: Fraction of ASHRAE 62.2")
    userdefined_fracofashrae.setUnits("frac")
    userdefined_fracofashrae.setDescription("Fraction of the ventilation rate (including any infiltration credit) specified by ASHRAE 62.2 that is desired in the building.")
    userdefined_fracofashrae.setDefaultValue(1.0)
    args << userdefined_fracofashrae

    #make a choice argument for ashrae standard
    standard_types_names = OpenStudio::StringVector.new
    standard_types_names << "2010"
    standard_types_names << "2013"
	
    #make a double argument for ashrae standard
    selected_ashraestandard = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("selectedashraestandard", standard_types_names, false)
    selected_ashraestandard.setDisplayName("Mechanical Ventilation: ASHRAE 62.2 Standard")
    selected_ashraestandard.setDescription("Specifies which version (year) of the ASHRAE 62.2 Standard should be used.")
    selected_ashraestandard.setDefaultValue("2010")
    args << selected_ashraestandard	

    #make a double argument for dryer exhaust
    userdefined_dryerexhaust = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefineddryerexhaust",false)
    userdefined_dryerexhaust.setDisplayName("Clothes Dryer: Exhaust")
    userdefined_dryerexhaust.setUnits("cfm")
    userdefined_dryerexhaust.setDescription("Rated flow capacity of the clothes dryer exhaust. This fan is assumed to run 60 min/day between 11am and 12pm.")
    userdefined_dryerexhaust.setDefaultValue(100.0)
    args << userdefined_dryerexhaust

    # Natural Ventilation

    #make a double argument for heating season setpoint offset
    userdefined_htgoffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhtgoffset",false)
    userdefined_htgoffset.setDisplayName("Natural Ventilation: Heating Season Setpoint Offset")
    userdefined_htgoffset.setUnits("degrees F")
    userdefined_htgoffset.setDescription("The temperature offset below the hourly cooling setpoint, to which the living space is allowed to cool during months that are only in the heating season.")
    userdefined_htgoffset.setDefaultValue(1.0)
    args << userdefined_htgoffset

    #make a double argument for cooling season setpoint offset
    userdefined_clgoffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedclgoffset",false)
    userdefined_clgoffset.setDisplayName("Natural Ventilation: Cooling Season Setpoint Offset")
    userdefined_clgoffset.setUnits("degrees F")
    userdefined_clgoffset.setDescription("The temperature offset above the hourly heating setpoint, to which the living space is allowed to cool during months that are only in the cooling season.")
    userdefined_clgoffset.setDefaultValue(1.0)
    args << userdefined_clgoffset

    #make a double argument for overlap season setpoint offset
    userdefined_ovlpoffset = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedovlpoffset",false)
    userdefined_ovlpoffset.setDisplayName("Natural Ventilation: Overlap Season Setpoint Offset")
    userdefined_ovlpoffset.setUnits("degrees F")
    userdefined_ovlpoffset.setDescription("The temperature offset above the maximum heating setpoint, to which the living space is allowed to cool during months that are in both the heating season and cooling season.")
    userdefined_ovlpoffset.setDefaultValue(1.0)
    args << userdefined_ovlpoffset

    #make a bool argument for heating season
    selected_heatingssn = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedheatingssn",false)
    selected_heatingssn.setDisplayName("Natural Ventilation: Heating Season")
    selected_heatingssn.setDescription("True if windows are allowed to be opened during months that are only in the heating season.")
    selected_heatingssn.setDefaultValue(true)
    args << selected_heatingssn

    #make a bool argument for cooling season
    selected_coolingssn = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedcoolingssn",false)
    selected_coolingssn.setDisplayName("Natural Ventilation: Cooling Season")
    selected_coolingssn.setDescription("True if windows are allowed to be opened during months that are only in the cooling season.")
    selected_coolingssn.setDefaultValue(true)
    args << selected_coolingssn

    #make a bool argument for overlap season
    selected_overlapssn = OpenStudio::Ruleset::OSArgument::makeBoolArgument("selectedoverlapssn",false)
    selected_overlapssn.setDisplayName("Natural Ventilation: Overlap Season")
    selected_overlapssn.setDescription("True if windows are allowed to be opened during months that are in both the heating season and cooling season.")
    selected_overlapssn.setDefaultValue(true)
    args << selected_overlapssn

    #make a double argument for number weekdays
    userdefined_ventweekdays = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("userdefinedventweekdays",false)
    userdefined_ventweekdays.setDisplayName("Natural Ventilation: Number Weekdays")
    userdefined_ventweekdays.setDescription("Number of weekdays in the week that natural ventilation can occur.")
    userdefined_ventweekdays.setDefaultValue(3)
    args << userdefined_ventweekdays

    #make a double argument for number weekend days
    userdefined_ventweekenddays = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("userdefinedventweekenddays",false)
    userdefined_ventweekenddays.setDisplayName("Natural Ventilation: Number Weekend Days")
    userdefined_ventweekenddays.setDescription("Number of weekend days in the week that natural ventilation can occur.")
    userdefined_ventweekenddays.setDefaultValue(0)
    args << userdefined_ventweekenddays

    #make a double argument for fraction of windows open
    userdefined_fracwinopen = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfracwinopen",false)
    userdefined_fracwinopen.setDisplayName("Natural Ventilation: Fraction of Openable Windows Open")
    userdefined_fracwinopen.setUnits("frac")
    userdefined_fracwinopen.setDescription("Specifies the fraction of the total openable window area in the building that is opened for ventilation.")
    userdefined_fracwinopen.setDefaultValue(0.33)
    args << userdefined_fracwinopen

    #make a double argument for fraction of window area open
    userdefined_fracwinareaopen = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedfracwinareaopen",false)
    userdefined_fracwinareaopen.setDisplayName("Natural Ventilation: Fraction Window Area Openable")
    userdefined_fracwinareaopen.setUnits("frac")
    userdefined_fracwinareaopen.setDescription("Specifies the fraction of total window area in the home that can be opened (e.g. typical sliding windows can be opened to half of their area).")
    userdefined_fracwinareaopen.setDefaultValue(0.2)
    args << userdefined_fracwinareaopen

    #make a double argument for humidity ratio
    userdefined_humratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedhumratio",false)
    userdefined_humratio.setDisplayName("Natural Ventilation: Max OA Humidity Ratio")
    userdefined_humratio.setUnits("frac")
    userdefined_humratio.setDescription("Outdoor air humidity ratio above which windows will not open for natural ventilation.")
    userdefined_humratio.setDefaultValue(0.0115)
    args << userdefined_humratio

    #make a double argument for relative humidity ratio
    userdefined_relhumratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("userdefinedrelhumratio",false)
    userdefined_relhumratio.setDisplayName("Natural Ventilation: Max OA Relative Humidity")
    userdefined_relhumratio.setUnits("frac")
    userdefined_relhumratio.setDescription("Outdoor air relative humidity (0-1) above which windows will not open for natural ventilation.")
    userdefined_relhumratio.setDefaultValue(0.7)
    args << userdefined_relhumratio
	
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
    duct_sup_frac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_sup_frac", false)
    duct_sup_frac.setDisplayName("Ducts: Supply Leakage Fraction of Total")
    duct_sup_frac.setUnits("frac")
    duct_sup_frac.setDescription("The amount of air flow leakage leaking out from the supply duct expressed as a fraction of the total duct leakage.")
    duct_sup_frac.setDefaultValue(0.6)
    args << duct_sup_frac

    #make a double argument for return leakage fraction of total
    duct_ret_frac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_ret_frac", false)
    duct_ret_frac.setDisplayName("Ducts: Return Leakage Fraction of Total")
    duct_ret_frac.setUnits("frac")
    duct_ret_frac.setDescription("The amount of air flow leakage leaking into the return duct expressed as a fraction of the total duct leakage.")
    duct_ret_frac.setDefaultValue(0.067)
    args << duct_ret_frac  

    #make a double argument for supply AH leakage fraction of total
    duct_ah_sup_frac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_ah_sup_frac", false)
    duct_ah_sup_frac.setDisplayName("Ducts: Supply Air Handler Leakage Fraction of Total")
    duct_ah_sup_frac.setUnits("frac")
    duct_ah_sup_frac.setDescription("The amount of air flow leakage leaking out from the supply-side of the air handler expressed as a fraction of the total duct leakage.")
    duct_ah_sup_frac.setDefaultValue(0.067)
    args << duct_ah_sup_frac  

    #make a double argument for return AH leakage fraction of total
    duct_ah_ret_frac = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_ah_ret_frac", false)
    duct_ah_ret_frac.setDisplayName("Ducts: Return Air Handler Leakage Fraction of Total")
    duct_ah_ret_frac.setUnits("frac")
    duct_ah_ret_frac.setDescription("The amount of air flow leakage leaking out from the return-side of the air handler expressed as a fraction of the total duct leakage.")
    duct_ah_ret_frac.setDefaultValue(0.267)
    args << duct_ah_ret_frac
    
    #make a string argument for norm leakage to outside
    duct_norm_leakage_to_outside = OpenStudio::Ruleset::OSArgument::makeStringArgument("duct_norm_leakage_to_outside", false)
    duct_norm_leakage_to_outside.setDisplayName("Ducts: Leakage to Outside at 25Pa")
    duct_norm_leakage_to_outside.setUnits("cfm/100 ft^2")
    duct_norm_leakage_to_outside.setDescription("Normalized leakage to the outside when tested at a pressure differential of 25 Pascals (0.1 inches w.g.) across the system.")
    duct_norm_leakage_to_outside.setDefaultValue("NA")
    args << duct_norm_leakage_to_outside
    
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
    supply_surface_area_multiplier = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("supply_surface_area_multiplier", true)
    supply_surface_area_multiplier.setDisplayName("Ducts: Supply Surface Area Multiplier")
    supply_surface_area_multiplier.setUnits("mult")
    supply_surface_area_multiplier.setDescription("Values specify a fraction of the Building America Benchmark supply duct surface area.")
    supply_surface_area_multiplier.setDefaultValue(1.0)
    args << supply_surface_area_multiplier

    #make a double argument for return surface area multiplier
    return_surface_area_multiplier = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("return_surface_area_multiplier", true)
    return_surface_area_multiplier.setDisplayName("Ducts: Return Surface Area Multiplier")
    return_surface_area_multiplier.setUnits("mult")
    return_surface_area_multiplier.setDescription("Values specify a fraction of the Building America Benchmark return duct surface area.")
    return_surface_area_multiplier.setDefaultValue(1.0)
    args << return_surface_area_multiplier
    
    #make a double argument for duct unconditioned r value
    duct_unconditioned_rvalue = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("duct_unconditioned_rvalue", true)
    duct_unconditioned_rvalue.setDisplayName("Ducts: Insulation Nominal R-Value")
    duct_unconditioned_rvalue.setUnits("h-ft^2-R/Btu")
    duct_unconditioned_rvalue.setDescription("The nominal R-value for duct insulation.")
    duct_unconditioned_rvalue.setDefaultValue(0.0)
    args << duct_unconditioned_rvalue    
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)
        
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end
    
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Could not load last OpenStudio model, cannot apply measure.")
      return false
    end
    model = model.get

    # Remove existing airflow objects
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["NatVentProbability"], "Schedule:Constant", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["MechanicalVentilationEnergyWk", "MechanicalVentilationWk", "BathExhaustWk", "ClothesDryerExhaustWk", "RangeHoodWk", "NatVentOffSeason-Week", "NatVent-Week", "NatVentClgSsnTempWeek", "NatVentHtgSsnTempWeek", "NatVentOvlpSsnTempWeek"], "Schedule:Week:Compact", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["MechanicalVentilationEnergy", "MechanicalVentilation", "BathExhaust", "ClothesDryerExhaust", "RangeHood", "NatVent", "NatVentTemp"], "Schedule:Year", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["MechanicalVentilationDay", "MechanicalVentilationEnergyDay", "BathExhaustDay", "ClothesDryerExhaustDay", "RangeHoodDay", "NatVentOn-Day", "NatVentOff-Day", "NatVentHtgSsnTempWkDay", "NatVentHtgSsnTempWkEnd", "NatVentClgSsnTempWkDay", "NatVentClgSsnTempWkEnd", "NatVentOvlpSsnTempWkDay", "NatVentOvlpSsnTempWkEnd", "NatVentOvlpSsnTempWkEnd"], "Schedule:Day:Hourly", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["Living Infiltration"], "ZoneInfiltration:FlowCoefficient", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["Natural Ventilation"], "ZoneVentilation:DesignFlowRate", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["Tout", "Hout", "Pbar", "Tin", "Phiin", "Win", "Wout", "Vwind", "WH_sch", "Range_sch", "Bath_sch", "Clothes_dryer_sch", "NVAvail", "NVSP", "AH_MFR_Sensor", "Fan_RTF_Sensor", "AH_VFR_Sensor", "AH_Tout_Sensor", "AH_Wout_Sensor", "RA_T_Sensor", "RA_W_Sensor", "AHZone_T_Sensor", "AHZone_W_Sensor"], "EnergyManagementSystem:Sensor", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["NatVentFlow", "InfilFlow", "SupplyLeakSensibleActuator", "SupplyLeakLatentActuator", "SupplyDuctLoadToLivingActuator", "ConductionToAHZoneActuator", "ReturnDuctLoadToPlenumActuator", "ReturnConductionToAHZoneActuator", "SensibleLeakageToAHZoneActuator", "LatentLeakageToAHZoneActuator", "ReturnSensibleLeakageActuator", "ReturnLatentLeakageActuator", "AHZoneToLivingFlowRateActuator", "LivingToAHZoneFlowRateActuator"], "EnergyManagementSystem:Actuator", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["InfiltrationProgram", "NaturalVentilationProgram", "DuctLeakageProgram"], "EnergyManagementSystem:Program", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["Zone Infil/MechVent Flow Rate", "Whole House Fan Vent Flow Rate", "Range Hood Fan Vent Flow Rate", "Bath Exhaust Fan Vent Flow Rate", "Clothes Dryer Exhaust Fan Vent Flow Rate", "Local Wind Speed", "Zone Natural Ventilation Flow Rate"], "EnergyManagementSystem:OutputVariable", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["AirflowCalculator", "DuctLeakageCallingManager"], "EnergyManagementSystem:ProgramCallingManager", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["UAtcInfiltration"], "ZoneInfiltration:EffectiveLeakageArea", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["AH_MFR", "Fan_RTF", "AH_VFR", "AH_Tout", "AH_Wout", "RA_T", "RA_W", "AHZone_T", "AHZone_W", "SupplyLeakSensibleLoad", "SupplyLeakLatentLoad", "SupplyDuctLoadToLiving", "ConductionToAHZone", "ReturnConductionToAHZone", "ReturnDuctLoadToPlenum", "SensibleLeakageToAHZone", "LatentLeakageToAHZone", "AHZoneToLivingFlowRate", "LivingToAHZoneFlowRate", "ReturnSensibleLeakage", "ReturnLatentLeakage", "DuctLeakSupplyFanEquivalent"], "EnergyManagementSystem:GlobalVariable", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["CalculateDuctLeakage"], "EnergyManagementSystem:Subroutine", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["AdiabaticConst"], "Construction", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["RA Duct Zone"], "Zone", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["RADuctWall_N", "RADuctWall_S", "RADuctWall_E", "RADuctWall_W", "RADuctCeiling", "RADuctFloor"], "SurfaceProperty:ConvectionCoefficients", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["RADuctWall_N", "RADuctWall_E", "RADuctWall_S", "RADuctWall_W"], "Wall:Adiabatic", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["RADuctCeiling"], "Ceiling:Adiabatic", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["RADuctFloor"], "Floor:Adiabatic", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["Return Plenum"], "AirLoopHVAC:ReturnPlenum", runner)
    workspace = HelperMethods.remove_object_from_idf_based_on_name(workspace, ["SupplySensibleLeakageToLiving", "SupplyLatentLeakageToLiving", "SupplyDuctConductionToLiving", "SupplyDuctConductionToAHZone", "ReturnDuctConductionToPlenum", "ReturnDuctConductionTOAHZone", "SupplySensibleLeakageToAHZone", "SupplyLatentLeakageToAHZone", "ReturnSensibleLeakageEquip", "ReturnLatentLeakageEquip"], "OtherEquipment", runner)
    
    infiltrationLivingSpaceACH50 = runner.getDoubleArgumentValue("userdefinedinflivingspace",user_arguments)
    infiltrationGarageACH50 = runner.getDoubleArgumentValue("userdefinedinfgarage",user_arguments)
    crawlACH = runner.getDoubleArgumentValue("userdefinedinfcrawl",user_arguments)
    fbsmtACH = runner.getDoubleArgumentValue("userdefinedinffbsmt",user_arguments)
    ufbsmtACH = runner.getDoubleArgumentValue("userdefinedinfufbsmt",user_arguments)
    uaSLA = runner.getDoubleArgumentValue("userdefinedinfunfinattic",user_arguments)
    infiltrationShelterCoefficient = runner.getStringArgumentValue("userdefinedinfsheltercoef",user_arguments)
    terrainType = runner.getStringArgumentValue("selectedterraintype",user_arguments)
    mechVentType = runner.getStringArgumentValue("selectedventtype",user_arguments)
    mechVentInfilCredit = runner.getBoolArgumentValue("selectedinfilcredit",user_arguments)
    mechVentTotalEfficiency = runner.getDoubleArgumentValue("userdefinedtotaleff",user_arguments)
    mechVentSensibleEfficiency = runner.getDoubleArgumentValue("userdefinedsenseff",user_arguments)
    mechVentHouseFanPower = runner.getDoubleArgumentValue("userdefinedfanpower",user_arguments)
    mechVentFractionOfASHRAE = runner.getDoubleArgumentValue("userdefinedfracofashrae",user_arguments)
    mechVentASHRAEStandard = runner.getStringArgumentValue("selectedashraestandard",user_arguments)
    if mechVentType == "none"
      mechVentFractionOfASHRAE = 0.0
      mechVentHouseFanPower = 0.0
      mechVentTotalEfficiency = 0.0
      mechVentSensibleEfficiency = 0.0
    end
    dryerExhaust = runner.getDoubleArgumentValue("userdefineddryerexhaust",user_arguments)

    ageOfHome = runner.getDoubleArgumentValue("userdefinedhomeage",user_arguments)

    natVentHtgSsnSetpointOffset = runner.getDoubleArgumentValue("userdefinedhtgoffset",user_arguments)
    natVentClgSsnSetpointOffset = runner.getDoubleArgumentValue("userdefinedclgoffset",user_arguments)
    natVentOvlpSsnSetpointOffset = runner.getDoubleArgumentValue("userdefinedovlpoffset",user_arguments)
    natVentHeatingSeason = runner.getBoolArgumentValue("selectedheatingssn",user_arguments)
    natVentCoolingSeason = runner.getBoolArgumentValue("selectedcoolingssn",user_arguments)
    natVentOverlapSeason = runner.getBoolArgumentValue("selectedoverlapssn",user_arguments)
    natVentNumberWeekdays = runner.getIntegerArgumentValue("userdefinedventweekdays",user_arguments)
    natVentNumberWeekendDays = runner.getIntegerArgumentValue("userdefinedventweekenddays",user_arguments)
    natVentFractionWindowsOpen = runner.getDoubleArgumentValue("userdefinedfracwinopen",user_arguments)
    natVentFractionWindowAreaOpen = runner.getDoubleArgumentValue("userdefinedfracwinareaopen",user_arguments)
    natVentMaxOAHumidityRatio = runner.getDoubleArgumentValue("userdefinedhumratio",user_arguments)
    natVentMaxOARelativeHumidity = runner.getDoubleArgumentValue("userdefinedrelhumratio",user_arguments)
    
    duct_location = runner.getStringArgumentValue("duct_location",user_arguments)
    ductTotalLeakage = runner.getDoubleArgumentValue("duct_total_leakage",user_arguments)
    ductSupplyLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_sup_frac",user_arguments)
    ductReturnLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_ret_frac",user_arguments)
    ductAHSupplyLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_ah_sup_frac",user_arguments)
    ductAHReturnLeakageFractionOfTotal = runner.getDoubleArgumentValue("duct_ah_ret_frac",user_arguments)
    ductNormLeakageToOutside = runner.getStringArgumentValue("duct_norm_leakage_to_outside",user_arguments)
    unless ductNormLeakageToOutside == "NA"
      ductNormLeakageToOutside = ductNormLeakageToOutside.to_f
    else
      ductNormLeakageToOutside = nil
    end
    duct_location_frac = runner.getStringArgumentValue("duct_location_frac",user_arguments)
    duct_num_returns = runner.getStringArgumentValue("duct_num_returns",user_arguments)
    ductSupplySurfaceAreaMultiplier = runner.getDoubleArgumentValue("supply_surface_area_multiplier",user_arguments)
    ductReturnSurfaceAreaMultiplier = runner.getDoubleArgumentValue("return_surface_area_multiplier",user_arguments)
    ductUnconditionedRvalue = runner.getDoubleArgumentValue("duct_unconditioned_rvalue",user_arguments)
	
    if infiltrationLivingSpaceACH50 == 0
      infiltrationLivingSpaceACH50 = nil
    end
	
    # Create the material class instances
    si = Infiltration.new(infiltrationLivingSpaceACH50, infiltrationShelterCoefficient, infiltrationGarageACH50)
    wind_speed = WindSpeed.new
    neighbors_min_nonzero_offset = get_least_neighbor_offset(workspace)
    vent = MechanicalVentilation.new(mechVentType, mechVentInfilCredit, mechVentTotalEfficiency, mechVentFractionOfASHRAE, mechVentHouseFanPower, mechVentSensibleEfficiency, mechVentASHRAEStandard)
    geometry = Geom.new
    nv = NaturalVentilation.new(natVentHtgSsnSetpointOffset, natVentClgSsnSetpointOffset, natVentOvlpSsnSetpointOffset, natVentHeatingSeason, natVentCoolingSeason, natVentOverlapSeason, natVentNumberWeekdays, natVentNumberWeekendDays, natVentFractionWindowsOpen, natVentFractionWindowAreaOpen, natVentMaxOAHumidityRatio, natVentMaxOARelativeHumidity)
    schedules = Schedules.new
    d = Ducts.new(ductTotalLeakage, ductNormLeakageToOutside, ductSupplySurfaceAreaMultiplier, ductReturnSurfaceAreaMultiplier, ductUnconditionedRvalue, ductSupplyLeakageFractionOfTotal, ductReturnLeakageFractionOfTotal, ductAHSupplyLeakageFractionOfTotal, ductAHReturnLeakageFractionOfTotal)
    garage = Garage.new
    unfinished_basement = UnfinBasement.new(ufbsmtACH)
    crawlspace = Crawl.new(crawlACH)
    unfinished_attic = UnfinAttic.new(uaSLA)
  
    heatingSetpointWeekday = Array.new
    coolingSetpointWeekday = Array.new
    heatingSetpointWeekend = Array.new
    coolingSetpointWeekend = Array.new    
    schedule_days = workspace.getObjectsByType("Schedule:Day:Interval".to_IddObjectType)
    (1..12).to_a.each do |m|
      schedule_days.each do |schedule_day|
        schedule_day_name = schedule_day.getString(0).to_s # Name
        if schedule_day_name == "#{Constants.ObjectNameHeatingSetpoint} weekday#{m}"
          unless schedule_day.getString(4).get.to_f < -1000
            if heatingSetpointWeekday.empty?
              (4..50).step(2) do |x|
                deg = OpenStudio::convert(schedule_day.getString(x).get.to_f,"C","F").get
                heatingSetpointWeekday << deg
              end
            end
          end
        end
        if schedule_day_name == "#{Constants.ObjectNameCoolingSetpoint} weekday#{m}"
          unless schedule_day.getString(4).get.to_f > 1000
            if coolingSetpointWeekday.empty?
              (4..50).step(2) do |x|
                deg = OpenStudio::convert(schedule_day.getString(x).get.to_f,"C","F").get
                coolingSetpointWeekday << deg
              end
            end
          end
        end
        if schedule_day_name == "#{Constants.ObjectNameHeatingSetpoint} weekend#{m}"
          unless schedule_day.getString(4).get.to_f < -1000
            if heatingSetpointWeekend.empty?
              (4..50).step(2) do |x|
                deg = OpenStudio::convert(schedule_day.getString(x).get.to_f,"C","F").get
                heatingSetpointWeekend << deg
              end
            end
          end
        end
        if schedule_day_name == "#{Constants.ObjectNameCoolingSetpoint} weekend#{m}"
          unless schedule_day.getString(4).get.to_f > 1000
            if coolingSetpointWeekend.empty?
              (4..50).step(2) do |x|
                deg = OpenStudio::convert(schedule_day.getString(x).get.to_f,"C","F").get
                coolingSetpointWeekend << deg
              end
            end
          end
        end        
      end
    end
    
    if heatingSetpointWeekday.empty?
      (0..23).to_a.each do |x|
        heatingSetpointWeekday << -10000
      end
    end
    if coolingSetpointWeekday.empty?
      (0..23).to_a.each do |x|
        coolingSetpointWeekday << 10000
      end
    end
    if heatingSetpointWeekend.empty?
      (0..23).to_a.each do |x|
        heatingSetpointWeekend << -10000
      end
    end
    if coolingSetpointWeekend.empty?
      (0..23).to_a.each do |x|
        coolingSetpointWeekend << 10000
      end
    end
    
    # Create the sim object
    @weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if @weather.error?
        return false
    end

    ems = []

    sch = "
    ScheduleTypeLimits,
      Fraction,                     !- Name
      0,                            !- Lower Limit Value
      1,                            !- Upper Limit Value
      Continuous;                   !- Numeric Type"
    ems << sch

    sch = "
    ScheduleTypeLimits,
      Temperature,                  !- Name
      -60,                          !- Lower Limit Value
      200,                          !- Upper Limit Value
      Continuous;                   !- Numeric Type"
    ems << sch

    sch = "
    Schedule:Constant,
      AlwaysOff,                    !- Name
      FRACTION,                     !- Schedule Type
      0;                            !- Hourly Value"
    ems << sch

    sch = "
    Schedule:Constant,
      AlwaysOn,                     !- Name
      FRACTION,                     !- Schedule Type
      1;                            !- Hourly Value"
    ems << sch    
    
    hasForcedAirEquipment = false
    if workspace.getObjectsByType("AirLoopHVAC".to_IddObjectType).length > 0
      hasForcedAirEquipment = true
    end

    num_units = Geometry.get_num_units(model, runner)
    if num_units.nil?
        return false
    end

    geometry.finished_floor_area = Geometry.get_finished_floor_area_from_spaces(model.getSpaces, runner)
    if geometry.finished_floor_area.nil?
      return false
    end
    geometry.above_grade_finished_floor_area = Geometry.get_above_grade_finished_floor_area_from_spaces(model.getSpaces, runner)
    if geometry.above_grade_finished_floor_area.nil?
      return false
    end
    geometry.building_height = Geometry.get_building_height(model.getSpaces)
    geometry.stories = Geometry.get_building_stories(model.getSpaces)
    geometry.window_area = Geometry.get_building_window_area(model, runner)
    geometry.num_units = num_units
    geometry.above_grade_volume = Geometry.get_above_grade_finished_volume_from_spaces(model.getSpaces)
    geometry.above_grade_exterior_wall_area = Geometry.calculate_exterior_wall_area(model.getSpaces)
    
    garage_thermal_zone = nil
    ufbasement_thermal_zone = nil
    crawl_thermal_zone = nil
    ufattic_thermal_zone = nil
    model.getThermalZones.each do |thermal_zone|
      if thermal_zone.name.to_s.start_with? Constants.GarageZone
        garage_thermal_zone = Geometry.get_thermal_zone_from_string(model.getThermalZones, thermal_zone.name.to_s, runner)
        garage.height = Geometry.get_building_height(garage_thermal_zone.spaces)
        garage.area = OpenStudio::convert(garage_thermal_zone.floorArea,"m^2","ft^2").get
        garage.volume = garage.height * garage.area        
      elsif thermal_zone.name.to_s.start_with? Constants.UnfinishedBasementZone
        ufbasement_thermal_zone = Geometry.get_thermal_zone_from_string(model.getThermalZones, thermal_zone.name.to_s, runner)
        unfinished_basement.height = Geometry.get_building_height(ufbasement_thermal_zone.spaces)
        unfinished_basement.area = OpenStudio::convert(ufbasement_thermal_zone.floorArea,"m^2","ft^2").get
        unfinished_basement.volume = unfinished_basement.height * unfinished_basement.area        
      elsif thermal_zone.name.to_s.start_with? Constants.CrawlZone
        crawl_thermal_zone = Geometry.get_thermal_zone_from_string(model.getThermalZones, thermal_zone.name.to_s, runner)
        crawlspace.height = Geometry.get_building_height(crawl_thermal_zone.spaces)
        crawlspace.area = OpenStudio::convert(crawl_thermal_zone.floorArea,"m^2","ft^2").get
        crawlspace.volume = crawlspace.height * crawlspace.area        
      elsif thermal_zone.name.to_s.start_with? Constants.UnfinishedAtticZone
        ufattic_thermal_zone = Geometry.get_thermal_zone_from_string(model.getThermalZones, thermal_zone.name.to_s, runner)
        unfinished_attic.height = Geometry.get_building_height(ufattic_thermal_zone.spaces)
        unfinished_attic.area = OpenStudio::convert(ufattic_thermal_zone.floorArea,"m^2","ft^2").get
        unfinished_attic.volume = unfinished_attic.height * unfinished_attic.area        
      end
    end
    
    zones = workspace.getObjectsByType("Zone".to_IddObjectType)
    zones.each do |zone|    
      unless ufattic_thermal_zone.nil?
        if ufattic_thermal_zone.name.to_s == zone.getString(0).to_s
          unfinished_attic.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
        end
      end
      unless crawl_thermal_zone.nil?
        if crawl_thermal_zone.name.to_s == zone.getString(0).to_s
          crawlspace.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
        end
      end
      unless garage_thermal_zone.nil?
        if garage_thermal_zone.name.to_s == zone.getString(0).to_s
          garage.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
        end
      end
      unless ufbasement_thermal_zone.nil?
        if ufbasement_thermal_zone.name.to_s == zone.getString(0).to_s
          unfinished_basement.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
        end
      end
    end
      
    wind_speed = _processWindSpeedCorrection(wind_speed, terrainType)
    
    duct_locations = {}
    
    (1..num_units).to_a.each do |unit_num|
      _nbeds, _nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
      unit = Unit.new
      unit.num_bedrooms = _nbeds
      unit.num_bathrooms = _nbaths
      unit.above_grade_exterior_wall_area = Geometry.calculate_exterior_wall_area(unit_spaces)
      unit.above_grade_finished_floor_area = Geometry.get_above_grade_finished_floor_area_from_spaces(unit_spaces, runner)
      unit.finished_floor_area = Geometry.get_finished_floor_area_from_spaces(unit_spaces, runner)
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit_spaces)
      if thermal_zones.length > 1
        runner.registerInfo("Unit #{unit_num} spans more than one thermal zone.")
      end
      
      living_space = LivingSpace.new
      finished_basement = FinBasement.new(fbsmtACH)
      
      living_thermal_zone = nil
      fbasement_thermal_zone = nil
      thermal_zones.each do |thermal_zone|
        if thermal_zone.name.to_s.start_with? Constants.LivingZone
          living_thermal_zone = Geometry.get_thermal_zone_from_string(thermal_zones, thermal_zone.name.to_s, runner)
          living_space.height = Geometry.get_building_height(living_thermal_zone.spaces)
          living_space.area = OpenStudio::convert(living_thermal_zone.floorArea,"m^2","ft^2").get
          living_space.volume = living_space.height/geometry.stories.to_f * living_space.area          
        elsif thermal_zone.name.to_s.start_with? Constants.FinishedBasementZone
          fbasement_thermal_zone = Geometry.get_thermal_zone_from_string(thermal_zones, thermal_zone.name.to_s, runner)
          finished_basement.height = Geometry.get_building_height(fbasement_thermal_zone.spaces)
          finished_basement.area = OpenStudio::convert(fbasement_thermal_zone.floorArea,"m^2","ft^2").get
          finished_basement.volume = finished_basement.height * finished_basement.area            
        end
      end

      if living_thermal_zone.nil?
          return false
      end

      if duct_location != "none" and HVAC.has_central_air_conditioner(model, runner, living_thermal_zone, false, false).nil? and HVAC.has_furnace(model, runner, living_thermal_zone, false, false).nil? and HVAC.has_air_source_heat_pump(model, runner, living_thermal_zone, false).nil?
        runner.registerWarning("No ducted HVAC equipment was found but ducts were specified. Overriding duct specification.")
        duct_location = "none"
      end
      
      zones = workspace.getObjectsByType("Zone".to_IddObjectType)
      zones.each do |zone|
        unless living_thermal_zone.nil?
          if living_thermal_zone.name.to_s == zone_name = zone.getString(0).to_s
            living_space.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
          end
        end
        unless fbasement_thermal_zone.nil?
          if fbasement_thermal_zone.name.to_s == zone_name = zone.getString(0).to_s
            finished_basement.coord_z = OpenStudio::convert(zone.getString(4).get.to_f,"m","ft").get # Z Origin {m}
          end
        end
      end

      has_cd = false
      (workspace.getObjectsByType("ElectricEquipment".to_IddObjectType) + workspace.getObjectsByType("GasEquipment".to_IddObjectType)).each do |equipment|
        if equipment.getString(1).to_s == living_thermal_zone.name.to_s
          has_cd = true
        end
      end
      unit_dryer_exhaust = dryerExhaust
      if not has_cd and dryerExhaust > 0
        runner.registerWarning("No clothes dryer object was found in unit #{unit_num} but the clothes dryer exhaust specified is non-zero. Overriding clothes dryer exhaust to be zero.")
        unit_dryer_exhaust = 0
      end
      
      wind_speed = _processWindSpeedCorrectionForUnit(wind_speed, si, neighbors_min_nonzero_offset, geometry)
      si, living_space, fb, garage, ub, cs, ua, wind_speed = _processInfiltrationForUnit(si, living_space, finished_basement, garage, unfinished_basement, crawlspace, unfinished_attic, fbasement_thermal_zone, garage_thermal_zone, ufbasement_thermal_zone, crawl_thermal_zone, ufattic_thermal_zone, wind_speed, geometry, unit_spaces)
      vent, schedules = _processMechanicalVentilation(unit_num, si, vent, ageOfHome, unit_dryer_exhaust, geometry, unit, living_space, schedules)
      nv, schedules = _processNaturalVentilation(workspace, unit_num, nv, living_space, wind_speed, si, schedules, geometry, coolingSetpointWeekday, coolingSetpointWeekend, heatingSetpointWeekday, heatingSetpointWeekend)

      schedules.MechanicalVentilationEnergy.each do |sch|
        ems << sch
      end
      schedules.MechanicalVentilation.each do |sch|
        ems << sch
      end
      schedules.BathExhaust.each do |sch|
        ems << sch
      end
      schedules.ClothesDryerExhaust.each do |sch|
        ems << sch
      end
      schedules.RangeHood.each do |sch|
        ems << sch
      end
      schedules.NatVentProbability.each do |sch|
        ems << sch
      end
      schedules.NatVentAvailability.each do |sch|
        ems << sch
      end
      schedules.NatVentTemp.each do |sch|
        ems << sch
      end      

      # _processZoneLiving

      # Infiltration (Overridden by EMS. Values here are arbitrary)
      # Living Infiltration
      ems << "
      ZoneInfiltration:FlowCoefficient,
        Living Infiltration_#{unit_num},                            !- Name
        #{living_thermal_zone.name.to_s},                           !- Zone Name
        AlwaysOn,                                                   !- Schedule Name
        1,                                                          !- Flow Coefficient {m/s-Pa^n}
        1,                                                          !- Stack Coefficient {Pa^n/K^n}
        1,                                                          !- Pressure Exponent
        1,                                                          !- Wind Coefficient {Pa^n-s^n/m^n}
        1;                                                          !- Shelter Factor (From Walker and Wilson (1998) (eq. 16))"

      # The ventilation flow rate from this object is overriden by EMS language
      # Natural Ventilation
      ems << "
      ZoneVentilation:DesignFlowRate,
        Natural Ventilation_#{unit_num},                            !- Name
        #{living_thermal_zone.name.to_s},                           !- Zone Name
        NatVent_#{unit_num},                                        !- Schedule Name
        Flow/Zone,                                                  !- Design Flow Rate Calculation Method
        0.001,                                                      !- Design Flow rate {m^3/s}
        ,                                                           !- Flow Rate per Zone Floor Area {m/s-m}
        ,                                                           !- Flow Rate per Person {m/s-person}
        ,                                                           !- Air Changes per Hour {1/hr}
        Natural,                                                    !- Ventilation Type
        0,                                                          !- Fan Pressure Rise {Pa} (Fan Energy is accounted for in Fan:ZoneExhaust)
        1,                                                          !- Fan Total Efficiency
        1,                                                          !- Constant Term Coefficient
        0,                                                          !- Temperature Term Coefficient   
        0,                                                          !- Velocity Term Coefficient
        0;                                                          !- Velocity Squared Term Coefficient"      
      
      # Sensors

      # Tout
      ems << "
      EnergyManagementSystem:Sensor,
        Tout_#{unit_num},                                           !- Name
        #{living_thermal_zone.name.to_s},                           !- Output:Variable or Output:Meter Index Key Name
        Zone Outdoor Air Drybulb Temperature;                       !- Output:Variable or Output:Meter Index Key Name"

      # Hout
      ems << "
      EnergyManagementSystem:Sensor,
        Hout_#{unit_num},                                           !- Name
        ,                                                           !- Output:Variable or Output:Meter Index Key Name
        Site Outdoor Air Enthalpy;                                  !- Output:Variable or Output:Meter Index Key Name"

      # Pbar
      ems << "
      EnergyManagementSystem:Sensor,
        Pbar_#{unit_num},                                           !- Name
        ,                                                           !- Output:Variable or Output:Meter Index Key Name
        Site Outdoor Air Barometric Pressure;                       !- Output:Variable or Output:Meter Index Key Name"

      # Tin
      ems << "
      EnergyManagementSystem:Sensor,
        Tin_#{unit_num},                                            !- Name
        #{living_thermal_zone.name.to_s},                           !- Output:Variable or Output:Meter Index Key Name
        Zone Mean Air Temperature;                                  !- Output:Variable or Output:Meter Index Key Name"

      # Phiin
      ems << "
      EnergyManagementSystem:Sensor,
        Phiin_#{unit_num},                                          !- Name
        #{living_thermal_zone.name.to_s},                           !- Output:Variable or Output:Meter Index Key Name
        Zone Air Relative Humidity;                                 !- Output:Variable or Output:Meter Index Key Name"	  
      
      # Win
      ems << "
      EnergyManagementSystem:Sensor,
        Win_#{unit_num},                                            !- Name
        #{living_thermal_zone.name.to_s},                           !- Output:Variable or Output:Meter Index Key Name
        Zone Mean Air Humidity Ratio;                               !- Output:Variable or Output:Meter Index Key Name"

      # Wout
      ems << "
      EnergyManagementSystem:Sensor,
        Wout_#{unit_num},                                           !- Name
        ,                                                           !- Output:Variable or Output:Meter Index Key Name
        Site Outdoor Air Humidity Ratio;                            !- Output:Variable or Output:Meter Index Key Name"

      # Vwind
      ems << "
      EnergyManagementSystem:Sensor,
        Vwind_#{unit_num},                                          !- Name
        ,                                                           !- Output:Variable or Output:Meter Index Key Name
        Site Wind Speed;                                            !- Output:Variable or Output:Meter Index Key Name"

      # WH_sch
      ems << "
      EnergyManagementSystem:Sensor,
        WH_sch_#{unit_num},                                         !- Name
        AlwaysOn,                                                   !- Output:Variable or Output:Meter Index Key Name
        Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

      # Range_sch
      ems << "
      EnergyManagementSystem:Sensor,
        Range_sch_#{unit_num},                                      !- Name
        RangeHood_#{unit_num},                                      !- Output:Variable or Output:Meter Index Key Name
        Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

      # Bath_sch
      ems << "
      EnergyManagementSystem:Sensor,
        Bath_sch_#{unit_num},                                       !- Name
        BathExhaust_#{unit_num},                                    !- Output:Variable or Output:Meter Index Key Name
        Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

      # Clothes_dryer_sch
      ems << "
      EnergyManagementSystem:Sensor,
        Clothes_dryer_sch_#{unit_num},                              !- Name
        ClothesDryerExhaust_#{unit_num},                            !- Output:Variable or Output:Meter Index Key Name
        Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

      # NVAvail
      ems << "
      EnergyManagementSystem:Sensor,
        NVAvail_#{unit_num},                                        !- Name
        NatVent_#{unit_num},                                        !- Output:Variable or Output:Meter Index Key Name
        Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

      # NVSP
      ems << "
      EnergyManagementSystem:Sensor,
        NVSP_#{unit_num},                                           !- Name
        NatVentTemp_#{unit_num},                                    !- Output:Variable or Output:Meter Index Key Name
        Schedule Value;                                             !- Output:Variable or Output:Meter Index Key Name"

      # Actuators

      # NatVentFlow
      ems << "
      EnergyManagementSystem:Actuator,
        NatVentFlow_#{unit_num},                                    !- Name
        Natural Ventilation_#{unit_num},                            !- Actuated Component Unique Name
        Zone Ventilation,                                           !- Actuated Component Type
        Air Exchange Flow Rate;                                     !- Actuated Component Control Type"

      # InfilFlow
      ems << "
      EnergyManagementSystem:Actuator,
        InfilFlow_#{unit_num},                                      !- Name
        Living Infiltration_#{unit_num},                            !- Actuated Component Unique Name
        Zone Infiltration,                                          !- Actuated Component Type
        Air Exchange Flow Rate;                                     !- Actuated Component Control Type"      
      
      # Program

      # InfiltrationProgram
      ems_program = "
      EnergyManagementSystem:Program,
        InfiltrationProgram_#{unit_num},                            !- Name
        Set p_m = #{wind_speed.ashrae_terrain_exponent},
        Set p_s = #{wind_speed.ashrae_site_terrain_exponent},
        Set s_m = #{wind_speed.ashrae_terrain_thickness},
        Set s_s = #{wind_speed.ashrae_site_terrain_thickness},
        Set z_m = #{OpenStudio::convert(wind_speed.height,"ft","m").get},
        Set z_s = #{OpenStudio::convert(living_space.height,"ft","m").get},
        Set f_t = (((s_m/z_m)^p_m)*((z_s/s_s)^p_s)),
        Set VwindL_#{unit_num} = (f_t*Vwind_#{unit_num}),"
      if living_space.inf_method == Constants.InfMethodASHRAE
        if living_space.SLA > 0
          inf = si
          ems_program += "
            Set Tdiff = Tin_#{unit_num} - Tout_#{unit_num},
            Set DeltaT = @Abs Tdiff,
            Set c = #{(OpenStudio::convert(inf.C_i,"cfm","m^3/s").get / (249.1 ** inf.n_i))},
            Set Cs = #{inf.stack_coef * (448.4 ** inf.n_i)},
            Set Cw = #{inf.wind_coef * (1246.0 ** inf.n_i)},
            Set n = #{inf.n_i},
            Set sft = (f_t*#{(((wind_speed.S_wo * (1.0 - inf.Y_i)) + (inf.S_wflue * (1.5 * inf.Y_i))))}),
            Set Qn = (((c*Cs*(DeltaT^n))^2)+(((c*Cw)*((sft*Vwind_#{unit_num})^(2*n)))^2))^0.5,"
        else
          ems_program += "
            Set Qn = 0,"
        end
      elsif living_space.inf_method == Constants.InfMethodRes
        ems_program += "
        Set Qn = #{living_space.ACH * OpenStudio::convert(living_space.volume,"ft^3","m^3").get / OpenStudio::convert(1.0,"hr","s").get},"
      end

      ems_program += "
        Set Tdiff = Tin_#{unit_num} - Tout_#{unit_num},
        Set DeltaT = @Abs Tdiff,"

      ems_program += "
        Set QWHV_#{unit_num} = WH_sch_#{unit_num}*#{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},
        Set Qrange_#{unit_num} = Range_sch_#{unit_num}*#{OpenStudio::convert(vent.range_hood_hour_avg_exhaust,"cfm","m^3/s").get},
        Set Qdryer_#{unit_num} = Clothes_dryer_sch_#{unit_num}*#{OpenStudio::convert(vent.clothes_dryer_hour_avg_exhaust,"cfm","m^3/s").get},
        Set Qbath_#{unit_num} = Bath_sch_#{unit_num}*#{OpenStudio::convert(vent.bathroom_hour_avg_exhaust,"cfm","m^3/s").get},
        Set QhpwhOut = 0,
        Set QhpwhIn = 0,
        Set QductsOut = DuctLeakExhaustFanEquivalent_#{unit_num},
        Set QductsIn = DuctLeakSupplyFanEquivalent_#{unit_num},"

      if vent.MechVentType == Constants.VentTypeBalanced
        ems_program += "
          Set Qout = Qrange_#{unit_num}+Qbath_#{unit_num}+Qdryer_#{unit_num}+QhpwhOut+QductsOut,          !- Exhaust flows
          Set Qin = QhpwhIn+QductsIn,                                 !- Supply flows
          Set Qu = (@Abs (Qout - Qin)),                               !- Unbalanced flow
          Set Qb = QWHV_#{unit_num} + (@Min Qout Qin),                !- Balanced flow"
      else
        if vent.MechVentType == Constants.VentTypeExhaust
          ems_program += "
            Set Qout = QWHV_#{unit_num}+Qrange_#{unit_num}+Qbath_#{unit_num}+Qdryer_#{unit_num}+QhpwhOut+QductsOut,    !- Exhaust flows
            Set Qin = QhpwhIn+QductsIn,                                !- Supply flows
            Set Qu = (@Abs (Qout - Qin)),                              !- Unbalanced flow
            Set Qb = (@Min Qout Qin),                                  !- Balanced flow"
        else #vent.MechVentType == Constants.VentTypeSupply:
          ems_program += "
            Set Qout = Qrange_#{unit_num}+Qbath_#{unit_num}+Qdryer_#{unit_num}+QhpwhOut+QductsOut,         !- Exhaust flows
            Set Qin = QWHV_#{unit_num}+QhpwhIn+QductsIn,               !- Supply flows
            Set Qu = @Abs (Qout - Qin),                                !- QductOA
            Set Qb = (@Min Qout Qin),                                  !- Balanced flow"
        end

        if vent.MechVentHouseFanPower != 0
          ems_program += "
            Set faneff_wh = #{OpenStudio::convert(300.0 / vent.MechVentHouseFanPower,"cfm","m^3/s").get},  !- Fan Efficiency"
        else
          ems_program += "
            Set faneff_wh = 1,"
        end
        ems_program += "
          Set WholeHouseFanPowerOverride_#{unit_num} = (QWHV_#{unit_num}*300)/faneff_wh,"
      end
      if vent.MechVentSpotFanPower != 0
        ems_program += "
          Set faneff_sp = #{OpenStudio::convert(300.0 / vent.MechVentSpotFanPower,"cfm","m^3/s").get},     !- Fan Efficiency"
      else
        ems_program += "
          Set faneff_sp = 1,"
      end

      ems_program += "
        Set RangeHoodFanPowerOverride_#{unit_num} = (Qrange_#{unit_num}*300)/faneff_sp,
        Set BathExhaustFanPowerOverride_#{unit_num} = (Qbath_#{unit_num}*300)/faneff_sp,
        Set Q_acctd_for_elsewhere = QhpwhOut + QhpwhIn + QductsOut + QductsIn,
        Set InfilFlow_#{unit_num} = (((Qu^2) + (Qn^2))^0.5) - Q_acctd_for_elsewhere,
        Set InfilFlow_#{unit_num} = (@Max InfilFlow_#{unit_num} 0),
        Set InfilFlow_display_#{unit_num} = (((Qu^2) + (Qn^2))^0.5) - Qu,
        Set InfMechVent_#{unit_num} = Qb + InfilFlow_#{unit_num};"

      ems << ems_program      

      # OutputVariable

      # Zone Infil/MechVent Flow Rate
      ems << "
      EnergyManagementSystem:OutputVariable,
        Zone Infil/MechVent Flow Rate_#{unit_num},                      !- Name
        InfMechVent_#{unit_num},                                        !- EMS Variable Name
        Averaged,                                                       !- Type of Data in Variable
        ZoneTimestep,                                                   !- Update Frequency
        InfiltrationProgram_#{unit_num},                                !- EMS Program or Subroutine Name
        m3/s;                                                           !- Units"

      # Whole House Fan Vent Flow Rate
      ems << "
      EnergyManagementSystem:OutputVariable,
        Whole House Fan Vent Flow Rate_#{unit_num},                     !- Name
        QWHV_#{unit_num},                                               !- EMS Variable Name
        Averaged,                                                       !- Type of Data in Variable
        ZoneTimestep,                                                   !- Update Frequency
        InfiltrationProgram_#{unit_num},                                !- EMS Program or Subroutine Name
        m3/s;                                                           !- Units"

      # Range Hood Fan Vent Flow Rate
      ems << "
      EnergyManagementSystem:OutputVariable,
        Range Hood Fan Vent Flow Rate_#{unit_num},                      !- Name
        Qrange_#{unit_num},                                             !- EMS Variable Name
        Averaged,                                                       !- Type of Data in Variable
        ZoneTimestep,                                                   !- Update Frequency
        InfiltrationProgram_#{unit_num},                                !- EMS Program or Subroutine Name
        m3/s;                                                           !- Units"

      # Bath Exhaust Fan Vent Flow Rate
      ems << "
      EnergyManagementSystem:OutputVariable,
        Bath Exhaust Fan Vent Flow Rate_#{unit_num},                    !- Name
        Qbath_#{unit_num},                                              !- EMS Variable Name
        Averaged,                                                       !- Type of Data in Variable
        ZoneTimestep,                                                   !- Update Frequency
        InfiltrationProgram_#{unit_num},                                !- EMS Program or Subroutine Name
        m3/s;                                                           !- Units"

      # Clothes Dryer Exhaust Fan Vent Flow Rate
      ems << "
      EnergyManagementSystem:OutputVariable,
        Clothes Dryer Exhaust Fan Vent Flow Rate_#{unit_num},           !- Name
        Qdryer_#{unit_num},                                             !- EMS Variable Name
        Averaged,                                                       !- Type of Data in Variable
        ZoneTimestep,                                                   !- Update Frequency
        InfiltrationProgram_#{unit_num},                                !- EMS Program or Subroutine Name
        m3/s;                                                           !- Units"

      # Local Wind Speed
      ems << "
      EnergyManagementSystem:OutputVariable,
        Local Wind Speed_#{unit_num},                                   !- Name
        VwindL_#{unit_num},                                             !- EMS Variable Name
        Averaged,                                                       !- Type of Data in Variable
        ZoneTimestep,                                                   !- Update Frequency
        InfiltrationProgram_#{unit_num},                                !- EMS Program or Subroutine Name
        m/s;                                                            !- Units"

      # Program

      # NaturalVentilationProgram
      ems << "
      EnergyManagementSystem:Program,
        NaturalVentilationProgram_#{unit_num},                          !- Name
        Set Tdiff = Tin_#{unit_num} - Tout_#{unit_num},
        Set DeltaT = (@Abs Tdiff),
        Set Phiout = (@RhFnTdbWPb Tout_#{unit_num} Wout_#{unit_num} Pbar_#{unit_num}),
        Set Hin = (@HFnTdbRhPb Tin_#{unit_num} Phiin_#{unit_num} Pbar_#{unit_num}),
        Set NVArea = #{929.0304 * nv.area},
        Set Cs = #{0.001672 * nv.C_s},
        Set Cw = #{0.01 * nv.C_w},
        Set MaxNV = #{OpenStudio::convert(nv.max_flow_rate,"cfm","m^3/s").get},
        Set MaxHR = #{nv.NatVentMaxOAHumidityRatio},
        Set MaxRH = #{nv.NatVentMaxOARelativeHumidity},
        Set SGNV = (NVAvail_#{unit_num}*NVArea)*((((Cs*DeltaT)+(Cw*(Vwind_#{unit_num}^2)))^0.5)/1000),
        If (Wout_#{unit_num} < MaxHR) && (Phiout < MaxRH) && (Tin_#{unit_num} > NVSP_#{unit_num}),
          Set NVadj1 = (Tin_#{unit_num} - NVSP_#{unit_num})/(Tin_#{unit_num} - Tout_#{unit_num}),
          Set NVadj2 = (@Min NVadj1 1),
          Set NVadj3 = (@Max NVadj2 0),
          Set NVadj = SGNV*NVadj3,
          Set NatVentFlow_#{unit_num} = (@Min NVadj MaxNV),
        Else,
          Set NatVentFlow_#{unit_num} = 0,
        EndIf;"
          
      # OutputVariable

      # Zone Natural Ventilation Flow Rate
      ems << "
      EnergyManagementSystem:OutputVariable,
        Zone Natural Ventilation Flow Rate_#{unit_num},                 !- Name
        NatVentFlow_#{unit_num},                                        !- EMS Variable Name
        Averaged,                                                       !- Type of Data in Variable
        ZoneTimestep,                                                   !- Update Frequency
        NaturalVentilationProgram_#{unit_num},                          !- EMS Program or Subroutine Name
        m3/s;                                                           !- Units"        
        
      # ProgramCallingManager

      # AirflowCalculator
      ems << "
      EnergyManagementSystem:ProgramCallingManager,
        AirflowCalculator_#{unit_num},                                  !- Name
        BeginTimestepBeforePredictor,                                   !- EnergyPlus Model Calling Point
        InfiltrationProgram_#{unit_num},                                !- Program Name 1
        NaturalVentilationProgram_#{unit_num};                          !- Program Name 2"

      # Mechanical Ventilation
      if vent.MechVentType == Constants.VentTypeBalanced # TODO: will need to complete _processSystemVentilationNodes for this to work

        ems << "
        Fan:OnOff,
          ERV Supply Fan_#{unit_num},                                                   !- Name
          AlwaysOn,                                                                     !- Availability Schedule Name
          #{OpenStudio::convert(300.0 / vent.MechVentHouseFanPower,"cfm","m^3/s").get}, !- Fan Efficiency
          300,                                                                          !- Pressure Rise {Pa}
          #{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},         !- Maximum Flow rate {m^3/s}
          1,                                                                            !- Motor Efficiency
          1,                                                                            !- Motor in Airstream Fraction
          ERV Supply Fan Inlet Node_#{unit_num},                                        !- Air Inlet Node Name
          ERV Supply Fan Outlet Node_#{unit_num},                                       !- Air Outlet Node Name
          Fan-EIR-fPLR,                                                                 !- Fan Power Ratio Function of Speed Ratio Curve Name
          ,                                                                             !- Fan Efficiency Ratio Function of Speed Ratio Curve Name
          VentFans_#{unit_num};                                                         !- End-Use Subcategory"

        # TODO: Fan-EIR-fPLR has not been added so does not show up in IDF (does it need to?)

        ems << "
        Fan:OnOff,
          ERV Exhaust Fan_#{unit_num},                                                  !- Name
          AlwaysOn,                                                                     !- Availability Schedule Name
          #{OpenStudio::convert(300.0 / vent.MechVentHouseFanPower,"cfm","m^3/s").get}, !- Fan Efficiency
          300,                                                                          !- Pressure Rise {Pa}
          #{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},         !- Maximum Flow rate {m^3/s}
          1,                                                                            !- Motor Efficiency
          0,                                                                            !- Motor in Airstream Fraction
          ERV Exhaust Fan Inlet Node_#{unit_num},                                       !- Air Inlet Node Name
          ERV Exhaust Fan Outlet Node_#{unit_num},                                      !- Air Outlet Node Name
          Fan-EIR-fPLR,                                                                 !- Fan Power Ratio Function of Speed Ratio Curve Name
          ,                                                                             !- Fan Efficiency Ratio Function of Speed Ratio Curve Name
          VentFans_#{unit_num};                                                         !- End-Use Subcategory"

        # TODO: Fan-EIR-fPLR has not been added so does not show up in IDF (does it need to?)

        ems << "
        ZoneHVAC:EnergyRecoveryVentilator:Controller,
          ERV Controller_#{unit_num},                                             !- Name
          ,                                                                       !- Temperature High Limit {C}
          ,                                                                       !- Temperature Low Limit {C}
          ,                                                                       !- Enthalpy High Limit {J/kg}
          ,                                                                       !- Dewpoint Temperature Limit {C}
          ,                                                                       !- Electronic Enthalpy Limit Curve Name
          NoExhaustAirTemperatureLimit,                                           !- Exhaust Air Temperature Limit
          NoExhaustAirEnthalpyLimit,                                              !- Exhaust Air Enthalpy Limit
          AlwaysOff,                                                              !- Time of Day Economizer Flow Control Schedule Name
          No;                                                                     !- High Humidity Control Flag"

        ems << "
        OutdoorAir:Node,
          ERV Outside Air Inlet Node_#{unit_num},                                 !- Name
          #{OpenStudio::convert(living_space.height,"ft","m").get / 2.0};         !- Height Above Ground"

        ems << "
        HeatExchanger:AirToAir:SensibleAndLatent,
          ERV Heat Exchanger_#{unit_num},                                         !- Name
          AlwaysOn,                                                               !- Availability Schedule Name
          #{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},   !- Nominal Supply Air Flow Rate
          #{vent.MechVentHXCoreSensibleEffectiveness},                            !- Sensible Effectiveness at 100% Heating Air Flow
          #{vent.MechVentLatentEffectiveness},                                    !- Latent Effectiveness at 100% Heating Air Flow
          #{vent.MechVentHXCoreSensibleEffectiveness},                            !- Sensible Effectiveness at 75% Heating Air Flow
          #{vent.MechVentLatentEffectiveness},                                    !- Latent Effectiveness at 75% Heating Air Flow
          #{vent.MechVentHXCoreSensibleEffectiveness},                            !- Sensible Effectiveness at 100% Cooling Air Flow
          #{vent.MechVentLatentEffectiveness},                                    !- Latent Effectiveness at 100% Cooling Air Flow
          #{vent.MechVentHXCoreSensibleEffectiveness},                            !- Sensible Effectiveness at 75% Cooling Air Flow
          #{vent.MechVentLatentEffectiveness},                                    !- Latent Effectiveness at 75% Cooling Air Flow
          ERV Outside Air Inlet Node_#{unit_num},                                 !- Supply Air Inlet Node Name
          ERV Supply Fan Inlet Node_#{unit_num},                                  !- Supply Air Outlet Node Name
          Living Exhaust Node_#{unit_num},                                        !- Exhaust Air Inlet Node Name
          ERV Exhaust Fan Inlet Node_#{unit_num};                                 !- Exhaust Air Outlet Node Name"

        ems << "
        ZoneHVAC:EnergyRecoveryVentilator,
          ERV_#{unit_num},                                                        !- Name
          AlwaysOn,                                                               !- Availability Schedule Name
          ERV Heat Exchanger_#{unit_num},                                         !- Heat Exchanger Name
          #{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},   !- Supply Air Flow rate {m^3/s}
          #{OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get},   !- Exhaust Air Flor rate {m^3/s}
          ERV Supply Fan_#{unit_num},                                             !- Supply Air Fan Name
          ERV Exhaust Fan_#{unit_num},                                            !- Exhaust Air Fan Name
          ERV Controller_#{unit_num};                                             !- Controller Name"

      end        

      garage_thermal_zone_r = nil
      fbasement_thermal_zone_r = nil
      ufbasement_thermal_zone_r = nil
      crawl_thermal_zone_r = nil
      ufattic_thermal_zone_r = nil
      if not garage_thermal_zone.nil?
        garage_thermal_zone_r = garage_thermal_zone.name.to_s
      end
      if not fbasement_thermal_zone.nil?
        fbasement_thermal_zone_r = fbasement_thermal_zone.name.to_s
      end
      if not ufbasement_thermal_zone.nil?
        ufbasement_thermal_zone_r = ufbasement_thermal_zone.name.to_s
      end
      if not crawl_thermal_zone.nil?
        crawl_thermal_zone_r = crawl_thermal_zone.name.to_s
      end
      if not ufattic_thermal_zone.nil?
        ufattic_thermal_zone_r = ufattic_thermal_zone.name.to_s
      end

      # _processZoneGarage
      unless garage_thermal_zone.nil?
        if garage.SLA > 0
          # Infiltration
          ems << "
          ZoneInfiltration:EffectiveLeakageArea,
            GarageInfiltration,                                                         !- Name
            #{garage_thermal_zone.name.to_s},                                           !- Zone Name
            AlwaysOn,                                                                   !- Schedule Name
            #{OpenStudio::convert(garage.ELA,"ft^2","cm^2").get},                       !- Effective Air Leakage Area {cm}
            #{0.001672 * garage.C_s_SG},                                                !- Stack Coefficient {(L/s)/(cm^4-K)}
            #{0.01 * garage.C_w_SG};                                                    !- Wind Coefficient {(L/s)/(cm^4-(m/s))}"
        end
      end

      # _processZoneFinishedBasement
      unless fbasement_thermal_zone.nil?
        #--- Infiltration
        if fb.inf_method == Constants.InfMethodRes
          if fb.ACH > 0
            ems << "
            ZoneInfiltration:DesignFlowRate,
              FBsmtInfiltration_#{unit_num},                                            !- Name
              #{fbasement_thermal_zone.name.to_s},                                      !- Zone Name
              AlwaysOn,                                                                 !- Schedule Name
              AirChanges/Hour,                                                          !- Design Flow Rate Calculation Method
              ,                                                                         !- Design Flow rate {m^3/s}
              ,                                                                         !- Flow per Zone Floor Area {m/s-m}
              ,                                                                         !- Flow per Exterior Surface Area {m/s-m}
              #{fb.ACH},                                                                !- Air Changes per Hour {1/hr}
              1,                                                                        !- Constant Term Coefficient
              0,                                                                        !- Temperature Term Coefficient
              0,                                                                        !- Velocity Term Coefficient
              0;                                                                        !- Velocity Squared Term Coefficient"
          end
        end
      end

      # _processZoneUnfinishedBasement
      unless ufbasement_thermal_zone.nil?
        #--- Infiltration
        if ub.inf_method == Constants.InfMethodRes
          if ub.ACH > 0
            ems << "
            ZoneInfiltration:DesignFlowRate,
              UBsmtInfiltration,                                                        !- Name
              #{ufbasement_thermal_zone.name.to_s},                                     !- Zone Name
              AlwaysOn,                                                                 !- Schedule Name
              AirChanges/Hour,                                                          !- Design Flow Rate Calculation Method
              ,                                                                         !- Design Flow rate {m^3/s}
              ,                                                                         !- Flow per Zone Floor Area {m/s-m}
              ,                                                                         !- Flow per Exterior Surface Area {m/s-m}
              #{ub.ACH},                                                                !- Air Changes per Hour {1/hr}
              1,                                                                        !- Constant Term Coefficient
              0,                                                                        !- Temperature Term Coefficient
              0,                                                                        !- Velocity Term Coefficient
              0;                                                                        !- Velocity Squared Term Coefficient"
          end
        end
      end

      # _processZoneCrawlspace
      unless crawl_thermal_zone.nil?
        #--- Infiltration
        ems << "
        ZoneInfiltration:DesignFlowRate,
          CSInfiltration,                                                               !- Name
          #{crawl_thermal_zone.name.to_s},                                              !- Zone Name
          AlwaysOn,                                                                     !- Schedule Name
          AirChanges/Hour,                                                              !- Design Flow Rate Calculation Method
          ,                                                                             !- Design Flow rate {m^3/s}
          ,                                                                             !- Flow per Zone Floor Area {m/s-m}
          ,                                                                             !- Flow per Exterior Surface Area {m/s-m}
          #{cs.ACH},                                                                    !- Air Changes per Hour {1/hr}
          1,                                                                            !- Constant Term Coefficient
          0,                                                                            !- Temperature Term Coefficient
          0,                                                                            !- Velocity Term Coefficient
          0;                                                                            !- Velocity Squared Term Coefficient"
      end

      # _processZoneUnfinishedAttic
      unless ufattic_thermal_zone.nil?
        #--- Infiltration
        if ua.ELA > 0
          ems << "
          ZoneInfiltration:EffectiveLeakageArea,
          UAtcInfiltration,                                                             !- Name
          #{ufattic_thermal_zone.name.to_s},                                            !- Zone Name
          AlwaysOn,                                                                     !- Schedule Name
          #{OpenStudio::convert(ua.ELA,"ft^2","cm^2").get},                             !- Effective Air Leakage Area {cm}
          #{0.001672 * ua.C_s_SG},                                                      !- Stack Coefficient {(L/s)/(cm^4-K)}
          #{0.01 * ua.C_w_SG};                                                          !- Wind Coefficient {(L/s)/(cm^4-(m/s))}"
        end
      end
      
      # _processDuctwork
      d.DuctLocation = get_duct_location(runner, duct_location, living_thermal_zone, garage_thermal_zone, fbasement_thermal_zone, ufbasement_thermal_zone, crawl_thermal_zone, ufattic_thermal_zone)
      # Disallow placing ducts in locations that don't exist, and handle
      # exception for no ducts (in DuctLocation = None).    
      if !d.DuctLocation
        runner.registerError("Duct location is basement, but the building does not have a basement.")
        return false
      end
      
      d.has_ducts = true  
      if d.DuctLocation == "none"
          d.DuctLocation = living_thermal_zone.name.to_s
          d.has_ducts = false
      end
      
      has_mini_split_hp = false
      unless HVAC.has_mini_split_heat_pump(model, runner, living_thermal_zone, false).nil?
        has_mini_split_hp = true
      end
      if has_mini_split_hp and ( d.DuctLocation != (living_thermal_zone.name.to_s or "none") )
        d.DuctLocation = living_thermal_zone.name.to_s
        d.has_ducts = false
        runner.registerWarning("Duct losses are currently neglected when simulating mini-split heat pumps. Set Ducts to None or In Finished Space to avoid this warning message.")
      end    
      
      # Set has_uncond_ducts to False if ducts are in a conditioned space,
      # otherwise True    
      if d.DuctLocation == living_thermal_zone.name.to_s
          d.ducts_not_in_living = false
      elsif d.DuctLocation == fbasement_thermal_zone_r or d.DuctLocation == ufbasement_thermal_zone_r or d.DuctLocation == crawl_thermal_zone_r or d.DuctLocation == garage_thermal_zone_r or d.DuctLocation == ufattic_thermal_zone_r
          d.ducts_not_in_living = true
      end
      
      # unless d.DuctSystemEfficiency.nil?
          # d.ducts_not_in_living = true
          # d.has_ducts = true
      # end
      
      d.num_stories_for_ducts = geometry.stories
      unless fbasement_thermal_zone.nil?
        d.num_stories_for_ducts += 1
      end
      
      d.num_stories = d.num_stories_for_ducts
      
      if d.DuctNormLeakageToOutside.nil?
        # Normalize values in case user inadvertently entered values that add up to the total duct leakage, 
        # as opposed to adding up to 1
        sumFractionOfTotal = (d.DuctSupplyLeakageFractionOfTotal + d.DuctReturnLeakageFractionOfTotal + d.DuctAHSupplyLeakageFractionOfTotal + d.DuctAHReturnLeakageFractionOfTotal)
        if sumFractionOfTotal > 0
          d.DuctSupplyLeakageFractionOfTotal = ductSupplyLeakageFractionOfTotal / sumFractionOfTotal
          d.DuctReturnLeakageFractionOfTotal = ductReturnLeakageFractionOfTotal / sumFractionOfTotal
          d.DuctAHSupplyLeakageFractionOfTotal = ductAHSupplyLeakageFractionOfTotal / sumFractionOfTotal
          d.DuctAHReturnLeakageFractionOfTotal = ductAHReturnLeakageFractionOfTotal / sumFractionOfTotal
        end
        
        # Calculate actual leakages from percentages
        d.DuctSupplyLeakage = d.DuctSupplyLeakageFractionOfTotal * d.DuctTotalLeakage
        d.DuctReturnLeakage = d.DuctReturnLeakageFractionOfTotal * d.DuctTotalLeakage
        d.DuctAHSupplyLeakage = d.DuctAHSupplyLeakageFractionOfTotal * d.DuctTotalLeakage
        d.DuctAHReturnLeakage = d.DuctAHReturnLeakageFractionOfTotal * d.DuctTotalLeakage     
      end
      
      # Fraction of ducts in primary duct location (remaining ducts are in above-grade conditioned space).
      if duct_location_frac == Constants.Auto
        # Duct location fraction per 2010 BA Benchmark
        if d.num_stories == 1
          d.DuctLocationFrac = 1
        else
          d.DuctLocationFrac = 0.65
        end
      else
        d.DuctLocationFrac = duct_location_frac.to_f
      end    
      
      d.DuctLocationFracLeakage = d.DuctLocationFrac
      d.DuctLocationFracConduction = d.DuctLocationFrac
      
      d.supply_duct_surface_area = get_duct_supply_surface_area(d.DuctSupplySurfaceAreaMultiplier, geometry, d.num_stories)
      
      d.DuctNumReturns = get_duct_num_returns(duct_num_returns, d.num_stories)
      
      d.return_duct_surface_area = get_duct_return_surface_area(d.DuctReturnSurfaceAreaMultiplier, geometry, d.num_stories, d.DuctNumReturns)
     
      ducts_total_duct_surface_area = d.supply_duct_surface_area + d.return_duct_surface_area
       
      # Calculate Duct UA value
      if d.ducts_not_in_living
        d.unconditioned_duct_area = d.supply_duct_surface_area * d.DuctLocationFracConduction
        d.supply_duct_r = get_duct_insulation_rvalue(d.DuctUnconditionedRvalue, true)
        d.return_duct_r = get_duct_insulation_rvalue(d.DuctUnconditionedRvalue, false)
        d.unconditioned_duct_ua = d.unconditioned_duct_area / d.supply_duct_r
        d.return_duct_ua = d.return_duct_surface_area / d.return_duct_r
      else
        d.DuctLocationFracConduction = 0
        d.unconditioned_duct_ua = 0
        d.return_duct_ua = 0
      end
      
      # Calculate Duct Volume
      if d.ducts_not_in_living
        # Assume ducts are 3 ft by 1 ft, (8 is the perimeter)
        d.supply_duct_volume = (d.unconditioned_duct_area / 8.0) * 3.0
        d.return_duct_volume = (d.return_duct_surface_area / 8.0) * 3.0
      else
        d.supply_duct_volume = 0
        d.return_duct_volume = 0
      end
      
      # This can't be zero. A value of zero causes weird sizing issues in DOE-2.
      d.direct_oa_supply_duct_loss = 0.000001    
      
      # Only if using the Fractional Leakage Option Type:
      if d.DuctNormLeakageToOutside.nil?
        d.supply_duct_loss = (d.DuctLocationFracLeakage * (d.DuctSupplyLeakage - d.direct_oa_supply_duct_loss) + (d.DuctAHSupplyLeakage + d.direct_oa_supply_duct_loss))
        d.return_duct_loss = d.DuctReturnLeakage + d.DuctAHReturnLeakage
      end
      
      # _processDuctLeakage
      unless d.DuctNormLeakageToOutside.nil?
        runner.registerError("Duct leakage to outside was specified by we don't calculate fan air flow rate.")
        return false
        d = calc_duct_leakage_from_test(geometry.finished_floor_area, supply.FanAirFlowRate) # TODO: if DuctNormLeakageToOutside is specified, this will error because we don't calculate FanAirFlowRate
      end
      
      d.total_duct_unbalance = (d.supply_duct_loss - d.return_duct_loss).abs
      
      if not d.DuctLocation == living_thermal_zone.name.to_s and not d.DuctLocation == "none" and d.supply_duct_loss > 0
        # Calculate d.frac_oa = fraction of unbalanced make-up air that is outside air
        if d.total_duct_unbalance <= 0
          # Handle the exception for if there is no leakage unbalance.
          d.frac_oa = 0
        elsif [fbasement_thermal_zone_r, ufbasement_thermal_zone_r].include? d.DuctLocation or (d.DuctLocation == crawl_thermal_zone_r and crawlACH == 0) or (d.DuctLocation == ufattic_thermal_zone_r and uaSLA == 0)         
          d.frac_oa = d.direct_oa_supply_duct_loss / d.total_duct_unbalance
        else
          # Assume that all of the unbalanced make-up air is driven infiltration from outdoors.
          # This assumes that the holes for attic ventilation are much larger than any attic bypasses.      
          d.frac_oa = 1
        end
        # d.oa_duct_makeup =  fraction of the supply duct air loss that is made up by outside air (via return leakage)
        d.oa_duct_makeup = [d.frac_oa * d.total_duct_unbalance / [d.supply_duct_loss,d.return_duct_loss].max, 1].min
      else
        d.frac_oa = 0
        d.oa_duct_makeup = 0
      end

      duct_locations[unit_num] = d.DuctLocation
      if not d.DuctLocation == living_thermal_zone.name.to_s and not d.DuctLocation == "none" and hasForcedAirEquipment
      
        # _processMaterials
        ems << "
        Material:NoMass,
          Adiabatic,                                                          !- Name
          Rough,                                                              !- Roughness
          176.1;                                                              !- Thermal Resistance {m2-K/W}"   
      
        # _processConstructionsAdiabatic
        # Adiabatic Constructions are used for interior underground surfaces
        ems << "
        Construction,
          AdiabaticConst,                                                     !- Name
          Adiabatic;                                                          !- Outside Layer"
      
        # _processZoneReturnPlenum
        # Return Plenum Zone and Duct Leakage Objects
        
        ems << "
        Zone,
          RA Duct Zone_#{unit_num},                                           !- Name
          0,                                                                  !- Direction of Relative North {deg}
          0,                                                                  !- X Origin {m}
          0,                                                                  !- Y Origin {m}
          0,                                                                  !- Z Origin {m}
          ,                                                                   !- Type
          ,                                                                   !- Multiplier
          0,                                                                  !- Ceiling Height {m}
          #{OpenStudio::convert(d.return_duct_volume,"ft^3","m^3").get},      !- Volume {m3}
          0;                                                                  !- Floor Area {m2}"    
        
        ems << "
        Wall:Adiabatic,
          RADuctWall_N_#{unit_num},                                           !- Name
          AdiabaticConst,                                                     !- Construction Name
          RA Duct Zone_#{unit_num},                                           !- RA Duct Zone
          0,                                                                  !- Azimuth
          90,                                                                 !- Tilt
          0,                                                                  !- Vertex 1 X-Coordinate
          75,                                                                 !- Vertex 1 Y-Coordinate
          0,                                                                  !- Vertex 1 Z-Coordinate
          1,                                                                  !- Length
          1;                                                                  !- Height"      
        
        ems << "
        Wall:Adiabatic,
          RADuctWall_E_#{unit_num},                                           !- Name
          AdiabaticConst,                                                     !- Construction Name
          RA Duct Zone_#{unit_num},                                           !- RA Duct Zone
          90,                                                                 !- Azimuth
          90,                                                                 !- Tilt
          0,                                                                  !- Vertex 1 X-Coordinate
          74,                                                                 !- Vertex 1 Y-Coordinate
          0,                                                                  !- Vertex 1 Z-Coordinate
          1,                                                                  !- Length
          1;                                                                  !- Height" 
   
        ems << "
        Wall:Adiabatic,
          RADuctWall_S_#{unit_num},                                           !- Name
          AdiabaticConst,                                                     !- Construction Name
          RA Duct Zone_#{unit_num},                                           !- RA Duct Zone
          180,                                                                !- Azimuth
          90,                                                                 !- Tilt
          -1,                                                                 !- Vertex 1 X-Coordinate
          74,                                                                 !- Vertex 1 Y-Coordinate
          0,                                                                  !- Vertex 1 Z-Coordinate
          1,                                                                  !- Length
          1;                                                                  !- Height"
   
        ems << "
        Wall:Adiabatic,
          RADuctWall_W_#{unit_num},                                           !- Name
          AdiabaticConst,                                                     !- Construction Name
          RA Duct Zone_#{unit_num},                                           !- RA Duct Zone
          270,                                                                !- Azimuth
          90,                                                                 !- Tilt
          -1,                                                                 !- Vertex 1 X-Coordinate
          75,                                                                 !- Vertex 1 Y-Coordinate
          0,                                                                  !- Vertex 1 Z-Coordinate
          1,                                                                  !- Length
          1;                                                                  !- Height"

        ems << "
        Ceiling:Adiabatic,
          RADuctCeiling_#{unit_num},                                          !- Name
          AdiabaticConst,                                                     !- Construction Name
          RA Duct Zone_#{unit_num},                                           !- RA Duct Zone
          0,                                                                  !- Azimuth
          90,                                                                 !- Tilt
          0,                                                                  !- Vertex 1 X-Coordinate
          75,                                                                 !- Vertex 1 Y-Coordinate
          1,                                                                  !- Vertex 1 Z-Coordinate
          1,                                                                  !- Length
          1;                                                                  !- Height"
          
        ems << "
        Floor:Adiabatic,
          RADuctFloor_#{unit_num},                                            !- Name
          AdiabaticConst,                                                     !- Construction Name
          RA Duct Zone_#{unit_num},                                           !- RA Duct Zone
          0,                                                                  !- Azimuth
          180,                                                                !- Tilt
          0,                                                                  !- Vertex 1 X-Coordinate
          74,                                                                 !- Vertex 1 Y-Coordinate
          0,                                                                  !- Vertex 1 Z-Coordinate
          1,                                                                  !- Length
          1;                                                                  !- Height"        
         
        # Two objects are required to model the air exchange between the air handler zone and the living space since
        # ZoneMixing objects can not account for direction of air flow (both are controlled by EMS)

        # Accounts for leaks from the AH zone to the Living zone
        ems << "
        ZoneMixing,
          AHZoneToLivingZoneMixing_#{unit_num},                               !- Name
          #{living_thermal_zone.name.to_s},                                   !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          Flow/Zone,                                                          !- Design Flow Rate Calculation Method
          0,                                                                  !- Design Flow Rate (set by EMS)
          ,                                                                   !- Flow Rate per Zone Floor Area
          ,                                                                   !- Flow Rate per Person
          ,                                                                   !- Air Changes per Hour
          #{d.DuctLocation};                                                  !- Source Zone Name"
              
        # Accounts for leaks from the Living zone to the AH Zone
        ems << "
        ZoneMixing,
          LivingZoneToAHZoneMixing_#{unit_num},                               !- Name
          #{d.DuctLocation},                                                  !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          Flow/Zone,                                                          !- Design Flow Rate Calculation Method
          0,                                                                  !- Design Flow Rate (set by EMS)
          ,                                                                   !- Flow Rate per Zone Floor Area
          ,                                                                   !- Flow Rate per Person
          ,                                                                   !- Air Changes per Hour
          #{living_thermal_zone.name.to_s};                                   !- Source Zone Name"      
       
        ems << "
        SurfaceProperty:ConvectionCoefficients,
          RADuctWall_N_#{unit_num},                                           !- Surface Name
          Inside,                                                             !- Convection Coefficient 1 Location
          Value,                                                              !- Convection Coefficient 1 Type
          999;                                                                !- Convection Coefficient 1 {W/m2-K}"        

        ems << "
        SurfaceProperty:ConvectionCoefficients,
          RADuctWall_S_#{unit_num},                                           !- Surface Name
          Inside,                                                             !- Convection Coefficient 1 Location
          Value,                                                              !- Convection Coefficient 1 Type
          999;                                                                !- Convection Coefficient 1 {W/m2-K}" 
   
        ems << "
        SurfaceProperty:ConvectionCoefficients,
          RADuctWall_E_#{unit_num},                                           !- Surface Name
          Inside,                                                             !- Convection Coefficient 1 Location
          Value,                                                              !- Convection Coefficient 1 Type
          999;                                                                !- Convection Coefficient 1 {W/m2-K}" 

        ems << "
        SurfaceProperty:ConvectionCoefficients,
          RADuctWall_W_#{unit_num},                                           !- Surface Name
          Inside,                                                             !- Convection Coefficient 1 Location
          Value,                                                              !- Convection Coefficient 1 Type
          999;                                                                !- Convection Coefficient 1 {W/m2-K}"  
   
        ems << "
        SurfaceProperty:ConvectionCoefficients,
          RADuctCeiling_#{unit_num},                                          !- Surface Name
          Inside,                                                             !- Convection Coefficient 1 Location
          Value,                                                              !- Convection Coefficient 1 Type
          999;                                                                !- Convection Coefficient 1 {W/m2-K}"  
          
        ems << "
        SurfaceProperty:ConvectionCoefficients,
          RADuctFloor_#{unit_num},                                            !- Surface Name
          Inside,                                                             !- Convection Coefficient 1 Location
          Value,                                                              !- Convection Coefficient 1 Type
          999;                                                                !- Convection Coefficient 1 {W/m2-K}"
      
        # _processSystemDemandSideAir
        
        living_zone_return_air_node_name = nil
        fbasement_zone_return_air_node_name = nil
        workspace.getObjectsByType("ZoneHVAC:EquipmentConnections".to_IddObjectType).each do |zonehvac|
          if zonehvac.getString(0).to_s == living_thermal_zone.name.to_s
            living_zone_return_air_node_name = zonehvac.getString(5)
          elsif zonehvac.getString(0).to_s == fbasement_thermal_zone_r
            fbasement_zone_return_air_node_name = zonehvac.getString(5)
          end
        end

        demand_side_outlet_node_name = nil
        demand_side_inlet_node_names = nil
        workspace.getObjectsByType("AirLoopHVAC".to_IddObjectType).each do |airloop|
          if airloop.getString(0).to_s.include? "Central Air System_#{unit_num}"
            demand_side_outlet_node_name = airloop.getString(7).to_s
            demand_side_inlet_node_names = airloop.getString(8).to_s
          end
        end
        
        demand_side_inlet_node_name = nil
        workspace.getObjectsByType("NodeList".to_IddObjectType).each do |nodelist|
          if nodelist.getString(0).to_s == demand_side_inlet_node_names
            demand_side_inlet_node_name = nodelist.getString(1).to_s
          end
        end
              
        # Return Air
        ems_returnplenum = "
        AirLoopHVAC:ReturnPlenum,
          Return Plenum_#{unit_num},                                          !- Name
          RA Duct Zone_#{unit_num},                                           !- Zone Name
          RA Plenum Air Node_#{unit_num},                                     !- Zone Node Name
          #{demand_side_outlet_node_name},                                    !- Outlet Node Name" "Demand Side Outlet Node Name of AirLoopHVAC
          ,                                                                   !- Induced Air Outlet Node or NodeList Name"
          
        if not fbasement_thermal_zone.nil?
          ems_returnplenum += "
          #{living_zone_return_air_node_name},                                !- Inlet 1 Node Name
          #{fbasement_zone_return_air_node_name};                             !- Inlet 2 Node Name"
        else
          ems_returnplenum += "
          #{living_zone_return_air_node_name};                                !- Inlet 1 Node Name"
        end
        
        ems << ems_returnplenum
      
        # Other equipment objects to cancel out the supply air leakage directly into the return plenum
        ems << "
        OtherEquipment,
          SupplySensibleLeakageToLiving_#{unit_num},                          !- Name
          #{living_thermal_zone.name.to_s},                                   !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          EquipmentLevel,                                                     !- Design Level Calculation Method
          0,                                                                  !- Design Level {W}
          ,                                                                   !- Power per Zone Floor Area {W/m}
          ,                                                                   !- Power per Person {W/person}
          0,                                                                  !- Fraction Latent
          0,                                                                  !- Fraction Radiant
          0;                                                                  !- Fraction Lost"

        ems << "
        OtherEquipment,
          SupplyLatentLeakageToLiving_#{unit_num},                            !- Name
          #{living_thermal_zone.name.to_s},                                    !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          EquipmentLevel,                                                     !- Design Level Calculation Method
          0,                                                                  !- Design Level {W}
          ,                                                                   !- Power per Zone Floor Area {W/m}
          ,                                                                   !- Power per Person {W/person}
          0,                                                                  !- Fraction Latent
          0,                                                                  !- Fraction Radiant
          0;                                                                  !- Fraction Lost"

        # Supply duct conduction load added to the living space
        ems << "
        OtherEquipment,
          SupplyDuctConductionToLiving_#{unit_num},                           !- Name
          #{living_thermal_zone.name.to_s},                                   !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          EquipmentLevel,                                                     !- Design Level Calculation Method
          0,                                                                  !- Design Level {W}
          ,                                                                   !- Power per Zone Floor Area {W/m}
          ,                                                                   !- Power per Person {W/person}
          0,                                                                  !- Fraction Latent
          0,                                                                  !- Fraction Radiant
          0;                                                                  !- Fraction Lost"        
          
        # Supply duct conduction impact on the air handler zone.
        ems << "
        OtherEquipment,
          SupplyDuctConductionToAHZone_#{unit_num},                           !- Name
          #{d.DuctLocation},                                                  !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          EquipmentLevel,                                                     !- Design Level Calculation Method
          0,                                                                  !- Design Level {W}
          ,                                                                   !- Power per Zone Floor Area {W/m}
          ,                                                                   !- Power per Person {W/person}
          0,                                                                  !- Fraction Latent
          0,                                                                  !- Fraction Radiant
          0;                                                                  !- Fraction Lost"  
        
        # Return duct conduction load added to the return plenum zone
        ems << "
        OtherEquipment,
          ReturnDuctConductionToPlenum_#{unit_num},                           !- Name
          RA Duct Zone_#{unit_num},                                           !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          EquipmentLevel,                                                     !- Design Level Calculation Method
          0,                                                                  !- Design Level {W}
          ,                                                                   !- Power per Zone Floor Area {W/m}
          ,                                                                   !- Power per Person {W/person}
          0,                                                                  !- Fraction Latent
          0,                                                                  !- Fraction Radiant
          0;                                                                  !- Fraction Lost"        
        
        # Return duct conduction impact on the air handler zone.
        ems << "
        OtherEquipment,
          ReturnDuctConductionToAHZone_#{unit_num},                           !- Name
          #{d.DuctLocation},                                                  !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          EquipmentLevel,                                                     !- Design Level Calculation Method
          0,                                                                  !- Design Level {W}
          ,                                                                   !- Power per Zone Floor Area {W/m}
          ,                                                                   !- Power per Person {W/person}
          0,                                                                  !- Fraction Latent
          0,                                                                  !- Fraction Radiant
          0;                                                                  !- Fraction Lost"        
        
        # Supply duct sensible leakage impact on the air handler zone.
        ems << "
        OtherEquipment,
          SupplySensibleLeakageToAHZone_#{unit_num},                          !- Name
          #{d.DuctLocation},                                                  !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          EquipmentLevel,                                                     !- Design Level Calculation Method
          0,                                                                  !- Design Level {W}
          ,                                                                   !- Power per Zone Floor Area {W/m}
          ,                                                                   !- Power per Person {W/person}
          0,                                                                  !- Fraction Latent
          0,                                                                  !- Fraction Radiant
          0;                                                                  !- Fraction Lost"        
        
        # Supply duct latent leakage impact on the air handler zone.
        ems << "
        OtherEquipment,
          SupplyLatentLeakageToAHZone_#{unit_num},                            !- Name
          #{d.DuctLocation},                                                  !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          EquipmentLevel,                                                     !- Design Level Calculation Method
          0,                                                                  !- Design Level {W}
          ,                                                                   !- Power per Zone Floor Area {W/m}
          ,                                                                   !- Power per Person {W/person}
          0,                                                                  !- Fraction Latent
          0,                                                                  !- Fraction Radiant
          0;                                                                  !- Fraction Lost"        
        
        # Return duct sensible leakage impact on the return plenum
        ems << "
        OtherEquipment,
          ReturnSensibleLeakageEquip_#{unit_num},                             !- Name
          RA Duct Zone_#{unit_num},                                           !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          EquipmentLevel,                                                     !- Design Level Calculation Method
          0,                                                                  !- Design Level {W}
          ,                                                                   !- Power per Zone Floor Area {W/m}
          ,                                                                   !- Power per Person {W/person}
          0,                                                                  !- Fraction Latent
          0,                                                                  !- Fraction Radiant
          0;                                                                  !- Fraction Lost"        
        
        # Return duct latent leakage impact on the return plenum
        ems << "
        OtherEquipment,
          ReturnLatentLeakageEquip_#{unit_num},                               !- Name
          RA Duct Zone_#{unit_num},                                           !- Zone Name
          AlwaysOn,                                                           !- Schedule Name
          EquipmentLevel,                                                     !- Design Level Calculation Method
          0,                                                                  !- Design Level {W}
          ,                                                                   !- Power per Zone Floor Area {W/m}
          ,                                                                   !- Power per Person {W/person}
          0,                                                                  !- Fraction Latent
          0,                                                                  !- Fraction Radiant
          0;                                                                  !- Fraction Lost"      
        
        # Sensor to report the air handler mass flow rate
        ems << "
        EnergyManagementSystem:Sensor,
          AH_MFR_Sensor_#{unit_num},                                          !- Name
          #{demand_side_inlet_node_name},                                   !- Output:Variable or Output:Meter Index Key Name
          System Node Mass Flow Rate;                                         !- Output:Variable or Output:Meter Index Key Name"      
      
        # Sensor to report the supply fan runtime fraction
        ems << "
        EnergyManagementSystem:Sensor,
          Fan_RTF_Sensor_#{unit_num},                                         !- Name
          Supply Fan_#{unit_num},                                             !- Output:Variable or Output:Meter Index Key Name
          Fan Runtime Fraction;                                               !- Output:Variable or Output:Meter Index Key Name"     
      
        # Sensor to report the air handler volume flow rate
        ems << "
        EnergyManagementSystem:Sensor,
          AH_VFR_Sensor_#{unit_num},                                          !- Name
          #{demand_side_inlet_node_name},                                     !- Output:Variable or Output:Meter Index Key Name
          System Node Current Density Volume Flow Rate;                       !- Output:Variable or Output:Meter Index Key Name"       
        
        # Sensor to report the air handler outlet temperature
        ems << "
        EnergyManagementSystem:Sensor,
          AH_Tout_Sensor_#{unit_num},                                         !- Name
          #{demand_side_inlet_node_name},                                     !- Output:Variable or Output:Meter Index Key Name
          System Node Temperature;                                            !- Output:Variable or Output:Meter Index Key Name"       
        
        # Sensor to report the air handler outlet humidity ratio
        ems << "
        EnergyManagementSystem:Sensor,
          AH_Wout_Sensor_#{unit_num},                                         !- Name
          #{demand_side_inlet_node_name},                                     !- Output:Variable or Output:Meter Index Key Name
          System Node Humidity Ratio;                                         !- Output:Variable or Output:Meter Index Key Name" 
      
        # Sensor to report the return air temperature (assumed to be the living zone return temperature)
        ems << "
        EnergyManagementSystem:Sensor,
          RA_T_Sensor_#{unit_num},                                            !- Name
          #{living_zone_return_air_node_name},                                !- Output:Variable or Output:Meter Index Key Name
          System Node Temperature;                                            !- Output:Variable or Output:Meter Index Key Name"      
        
        # Sensor to report the return air humidity ratio (assumed to be the living zone return temperature)
        ems << "
        EnergyManagementSystem:Sensor,
          RA_W_Sensor_#{unit_num},                                            !- Name
          #{living_zone_return_air_node_name},                                !- Output:Variable or Output:Meter Index Key Name
          System Node Humidity Ratio;                                         !- Output:Variable or Output:Meter Index Key Name"    
      
        ems << "
        EnergyManagementSystem:Sensor,
          AHZone_T_Sensor_#{unit_num},                                        !- Name
          #{d.DuctLocation},                                                  !- Output:Variable or Output:Meter Index Key Name
          Zone Air Temperature;                                               !- Output:Variable or Output:Meter Index Key Name"    
      
        ems << "
        EnergyManagementSystem:Sensor,
          AHZone_W_Sensor_#{unit_num},                                        !- Name
          #{d.DuctLocation},                                                  !- Output:Variable or Output:Meter Index Key Name
          Zone Mean Air Humidity Ratio;                                       !- Output:Variable or Output:Meter Index Key Name"    
      
        # Global variable to store the air handler mass flow rate
        ems << "
        EnergyManagementSystem:GlobalVariable,
          AH_MFR_#{unit_num};                                                 !- Name"
      
        # Global variable to store the supply fan runtime fraction
        ems << "
        EnergyManagementSystem:GlobalVariable,
          Fan_RTF_#{unit_num};                                                !- Name"    
      
        # Global variable to store the air handler volume flow rate
        ems << "
        EnergyManagementSystem:GlobalVariable,
          AH_VFR_#{unit_num};                                                 !- Name"      
      
        # Global variable to store the air handler outlet temperature
        ems << "
        EnergyManagementSystem:GlobalVariable,
          AH_Tout_#{unit_num};                                                !- Name"    
      
        # Global variable to store the air handler outlet humidity ratio
        ems << "
        EnergyManagementSystem:GlobalVariable,
          AH_Wout_#{unit_num};                                                !- Name"      
        
        # Global variable to store the return air temperature (assumed to be the living zone return temperature)
        ems << "
        EnergyManagementSystem:GlobalVariable,
          RA_T_#{unit_num};                                                   !- Name"      
        
        # Global variable to store the return air humidity ratio (assumed to be the living zone return temperature)
        ems << "
        EnergyManagementSystem:GlobalVariable,
          RA_W_#{unit_num};                                                   !- Name"      
        
        # Global variable to store the air handlder zone temperature
        ems << "
        EnergyManagementSystem:GlobalVariable,
          AHZone_T_#{unit_num};                                               !- Name"      
        
        # Global variable to store the air handler zone humidity ratio
        ems << "
        EnergyManagementSystem:GlobalVariable,
          AHZone_W_#{unit_num};                                               !- Name"
        
        ems << "
        EnergyManagementSystem:GlobalVariable,
          SupplyLeakSensibleLoad_#{unit_num};                                 !- Name"      
        
        ems << "
        EnergyManagementSystem:GlobalVariable,
          SupplyLeakLatentLoad_#{unit_num};                                   !- Name"       
        
        ems << "
        EnergyManagementSystem:GlobalVariable,
          SupplyDuctLoadToLiving_#{unit_num};                                 !- Name" 

        ems << "
        EnergyManagementSystem:GlobalVariable,
          ConductionToAHZone_#{unit_num};                                     !- Name" 

        ems << "
        EnergyManagementSystem:GlobalVariable,
          ReturnConductionToAHZone_#{unit_num};                               !- Name" 

        ems << "
        EnergyManagementSystem:GlobalVariable,
          ReturnDuctLoadToPlenum_#{unit_num};                                 !- Name" 

        ems << "
        EnergyManagementSystem:GlobalVariable,
          SensibleLeakageToAHZone_#{unit_num};                                !- Name" 

        ems << "
        EnergyManagementSystem:GlobalVariable,
          LatentLeakageToAHZone_#{unit_num};                                  !- Name" 

        ems << "
        EnergyManagementSystem:GlobalVariable,
          AHZoneToLivingFlowRate_#{unit_num};                                 !- Name" 

        ems << "
        EnergyManagementSystem:GlobalVariable,
          LivingToAHZoneFlowRate_#{unit_num};                                 !- Name" 

        ems << "
        EnergyManagementSystem:GlobalVariable,
          ReturnSensibleLeakage_#{unit_num};                                  !- Name" 

        ems << "
        EnergyManagementSystem:GlobalVariable,
          ReturnLatentLeakage_#{unit_num};                                    !- Name"         
      
        ems << "
        EnergyManagementSystem:Actuator,
          SupplyLeakSensibleActuator_#{unit_num},                             !- Name
          SupplySensibleLeakageToLiving_#{unit_num},                          !- Actuated Component Unique Name
          OtherEquipment,                                                     !- Actuated Component Type
          Power Level;                                                        !- Actuated Component Control Type"    
      
        ems << "
        EnergyManagementSystem:Actuator,
          SupplyLeakLatentActuator_#{unit_num},                               !- Name
          SupplyLatentLeakageToLiving_#{unit_num},                            !- Actuated Component Unique Name
          OtherEquipment,                                                     !- Actuated Component Type
          Power Level;                                                        !- Actuated Component Control Type"     
      
        # Actuator to account for the load of the supply duct conduction on the living space
        ems << "
        EnergyManagementSystem:Actuator,
          SupplyDuctLoadToLivingActuator_#{unit_num},                         !- Name
          SupplyDuctConductionToLiving_#{unit_num},                           !- Actuated Component Unique Name
          OtherEquipment,                                                     !- Actuated Component Type
          Power Level;                                                        !- Actuated Component Control Type"       
        
        # Actuator to account for the load of the supply duct conduction on the air handler zone
        ems << "
        EnergyManagementSystem:Actuator,
          ConductionToAHZoneActuator_#{unit_num},                             !- Name
          SupplyDuctConductionToAHZone_#{unit_num},                           !- Actuated Component Unique Name
          OtherEquipment,                                                     !- Actuated Component Type
          Power Level;                                                        !- Actuated Component Control Type"       
        
        # Actuator to account for the load of the return duct conduction on the return plenum
        ems << "
        EnergyManagementSystem:Actuator,
          ReturnDuctLoadToPlenumActuator_#{unit_num},                         !- Name
          ReturnDuctConductionToPlenum_#{unit_num},                           !- Actuated Component Unique Name
          OtherEquipment,                                                     !- Actuated Component Type
          Power Level;                                                        !- Actuated Component Control Type"             
        
        # Actuator to account for the load of the return duct conduction on the air handler zone
        ems << "
        EnergyManagementSystem:Actuator,
          ReturnConductionToAHZoneActuator_#{unit_num},                       !- Name
          ReturnDuctConductionToAHZone_#{unit_num},                           !- Actuated Component Unique Name
          OtherEquipment,                                                     !- Actuated Component Type
          Power Level;                                                        !- Actuated Component Control Type"       
        
        # Actuator to account for the sensible leakage from the supply duct to the AH zone
        ems << "
        EnergyManagementSystem:Actuator,
          SensibleLeakageToAHZoneActuator_#{unit_num},                        !- Name
          SupplySensibleLeakageToAHZone_#{unit_num},                          !- Actuated Component Unique Name
          OtherEquipment,                                                     !- Actuated Component Type
          Power Level;                                                        !- Actuated Component Control Type"       
        
        # Actuator to account for the latent leakage from the supply duct to the AH zone
        ems << "
        EnergyManagementSystem:Actuator,
          LatentLeakageToAHZoneActuator_#{unit_num},                          !- Name
          SupplyLatentLeakageToAHZone_#{unit_num},                            !- Actuated Component Unique Name
          OtherEquipment,                                                     !- Actuated Component Type
          Power Level;                                                        !- Actuated Component Control Type"     
      
        # Actuator to account fot the sensible leakage from the AH zone to the return plenum
        ems << "
        EnergyManagementSystem:Actuator,
          ReturnSensibleLeakageActuator_#{unit_num},                          !- Name
          ReturnSensibleLeakageEquip_#{unit_num},                             !- Actuated Component Unique Name
          OtherEquipment,                                                     !- Actuated Component Type
          Power Level;                                                        !- Actuated Component Control Type"             
        
        # Actuator to account fot the latent leakage from the AH zone to the return plenum
        ems << "
        EnergyManagementSystem:Actuator,
          ReturnLatentLeakageActuator_#{unit_num},                            !- Name
          ReturnLatentLeakageEquip_#{unit_num},                               !- Actuated Component Unique Name
          OtherEquipment,                                                     !- Actuated Component Type
          Power Level;                                                        !- Actuated Component Control Type"       
        
        ems << "
        EnergyManagementSystem:Actuator,
          AHZoneToLivingFlowRateActuator_#{unit_num},                         !- Name
          AHZoneToLivingZoneMixing_#{unit_num},                               !- Actuated Component Unique Name
          ZoneMixing,                                                         !- Actuated Component Type
          Air Exchange Flow Rate;                                             !- Actuated Component Control Type"       
        
        ems << "
        EnergyManagementSystem:Actuator,
          LivingToAHZoneFlowRateActuator_#{unit_num},                         !- Name
          LivingZoneToAHZoneMixing_#{unit_num},                               !- Actuated Component Unique Name
          ZoneMixing,                                                         !- Actuated Component Type
          Air Exchange Flow Rate;                                             !- Actuated Component Control Type"       
        
        ems << "
        EnergyManagementSystem:GlobalVariable,
          DuctLeakSupplyFanEquivalent_#{unit_num},                            !- Name
          DuctLeakExhaustFanEquivalent_#{unit_num};                           !- Name"
        
        ems_subroutine = "
        EnergyManagementSystem:Subroutine,
          CalculateDuctLeakage_#{unit_num},                                         
          Set f_sup = #{d.supply_duct_loss},
          Set f_ret = #{d.return_duct_loss},
          Set f_OA = #{d.frac_oa * d.total_duct_unbalance},
          Set OAFlowRate = f_OA * AH_VFR_#{unit_num},
          Set SupplyLeakFlowRate = f_sup * AH_VFR_#{unit_num},
          Set ReturnLeakFlowRate = f_ret * AH_VFR_#{unit_num},"

        if d.return_duct_loss > d.supply_duct_loss
          # Supply air flow rate is greater than return flow rate
          # Living zone is pressurized in this case      
          ems_subroutine += "
            Set LivingToAHZoneFlowRate_#{unit_num} = (@Abs (ReturnLeakFlowRate - SupplyLeakFlowRate - OAFlowRate)),
            Set AHZoneToLivingFlowRate_#{unit_num} = 0,
            Set DuctLeakSupplyFanEquivalent_#{unit_num} = OAFlowRate,
            Set DuctLeakExhaustFanEquivalent_#{unit_num} = 0,"
        else
          # Living zone is depressurized in this case
          ems_subroutine += "
          Set AHZoneToLivingFlowRate_#{unit_num} = (@Abs (SupplyLeakFlowRate - ReturnLeakFlowRate - OAFlowRate)),
          Set LivingToAHZoneFlowRate_#{unit_num} = 0,
          Set DuctLeakSupplyFanEquivalent_#{unit_num} = 0,
          Set DuctLeakExhaustFanEquivalent_#{unit_num} = OAFlowRate,"        
        end
        
        if d.ducts_not_in_living
          ems_subroutine += "
          Set h_SA = (@HFnTdbW AH_Tout_#{unit_num} AH_Wout_#{unit_num}),
          Set h_AHZone = (@HFnTdbW AHZone_T_#{unit_num} AHZone_W_#{unit_num}),
          Set h_RA = (@HFnTdbW RA_T_#{unit_num} RA_W_#{unit_num}),
          Set h_fg = (@HfgAirFnWTdb AH_Wout_#{unit_num} AH_Tout_#{unit_num}),
          Set SALeakageQtot = f_sup * AH_MFR_#{unit_num} * (h_RA - h_SA),
          Set SupplyLeakLatentLoad_#{unit_num} = f_sup * AH_MFR_#{unit_num} * h_fg * (RA_W_#{unit_num} - AH_Wout_#{unit_num}),
          Set SupplyLeakSensibleLoad_#{unit_num} = SALeakageQtot - SupplyLeakLatentLoad_#{unit_num},
          Set expTerm = (Fan_RTF_#{unit_num} / (AH_MFR_#{unit_num} * 1006.0)) * #{OpenStudio::convert(d.unconditioned_duct_ua,"Btu/hr*R","W/K").get},
          Set expTerm = 0 - expTerm,
          Set Tsupply = AHZone_T_#{unit_num} + ((AH_Tout_#{unit_num} - AHZone_T_#{unit_num}) * (@Exp expTerm)),
          Set SupplyDuctLoadToLiving_#{unit_num} = AH_MFR_#{unit_num} * 1006.0 * (Tsupply - AH_Tout_#{unit_num}),
          Set ConductionToAHZone_#{unit_num} = 0 - SupplyDuctLoadToLiving_#{unit_num},
          Set expTerm = (Fan_RTF_#{unit_num} / (AH_MFR_#{unit_num} * 1006.0)) * #{OpenStudio::convert(d.return_duct_ua,"Btu/hr*R","W/K").get},
          Set expTerm = 0 - expTerm,
          Set Treturn = AHZone_T_#{unit_num} + ((RA_T_#{unit_num} - AHZone_T_#{unit_num}) * (@Exp expTerm)),
          Set ReturnDuctLoadToPlenum_#{unit_num} = AH_MFR_#{unit_num} * 1006.0 * (Treturn - RA_T_#{unit_num}),
          Set ReturnConductionToAHZone_#{unit_num} = 0 - ReturnDuctLoadToPlenum_#{unit_num},
          Set ReturnLatentLeakage_#{unit_num} = 0,
          Set ReturnSensibleLeakage_#{unit_num} = f_ret * AH_MFR_#{unit_num} * 1006.0 * (AHZone_T_#{unit_num} - RA_T_#{unit_num}),
          Set QtotLeakageToAHZone = f_sup * AH_MFR_#{unit_num} * (h_SA - h_AHZone),
          Set LatentLeakageToAHZone_#{unit_num} = f_sup * AH_MFR_#{unit_num} * h_fg * (AH_Wout_#{unit_num} - AHZone_W_#{unit_num}),
          Set SensibleLeakageToAHZone_#{unit_num} = QtotLeakageToAHZone - LatentLeakageToAHZone_#{unit_num};"
        else
          ems_subroutine += "
          Set SupplyLeakLatentLoad_#{unit_num} = 0,
          Set SupplyLeakSensibleLoad_#{unit_num} = 0,
          Set SupplyDuctLoadToLiving_#{unit_num} = 0,
          Set ConductionToAHZone_#{unit_num} = 0,
          Set ReturnDuctLoadToPlenum_#{unit_num} = 0,
          Set ReturnConductionToAHZone_#{unit_num} = 0,
          Set ReturnLatentLeakage_#{unit_num} = 0,
          Set ReturnSensibleLeakage_#{unit_num} = 0,
          Set LatentLeakageToAHZone_#{unit_num} = 0,
          Set SensibleLeakageToAHZone_#{unit_num} = 0;"
        end
        
        ems << ems_subroutine      
        
        ems << "
        EnergyManagementSystem:Program,
          DuctLeakageProgram_#{unit_num},                                         
          Set AH_MFR_#{unit_num} = AH_MFR_Sensor_#{unit_num},                              
          Set Fan_RTF_#{unit_num} = Fan_RTF_Sensor_#{unit_num},
          Set AH_VFR_#{unit_num} = AH_VFR_Sensor_#{unit_num},
          Set AH_Tout_#{unit_num} = AH_Tout_Sensor_#{unit_num},
          Set AH_Wout_#{unit_num} = AH_Wout_Sensor_#{unit_num},
          Set RA_T_#{unit_num} = RA_T_Sensor_#{unit_num},
          Set RA_W_#{unit_num} = RA_W_Sensor_#{unit_num},
          Set AHZone_T_#{unit_num} = AHZone_T_Sensor_#{unit_num},
          Set AHZone_W_#{unit_num} = AHZone_W_Sensor_#{unit_num},
          Run CalculateDuctLeakage_#{unit_num},
          Set SupplyLeakSensibleActuator_#{unit_num} = SupplyLeakSensibleLoad_#{unit_num},
          Set SupplyLeakLatentActuator_#{unit_num} = SupplyLeakLatentLoad_#{unit_num},
          Set SupplyDuctLoadToLivingActuator_#{unit_num} = SupplyDuctLoadToLiving_#{unit_num},
          Set ConductionToAHZoneActuator_#{unit_num} = ConductionToAHZone_#{unit_num},
          Set SensibleLeakageToAHZoneActuator_#{unit_num} = SensibleLeakageToAHZone_#{unit_num},
          Set LatentLeakageToAHZoneActuator_#{unit_num} = LatentLeakageToAHZone_#{unit_num},
          Set ReturnSensibleLeakageActuator_#{unit_num} = ReturnSensibleLeakage_#{unit_num},
          Set ReturnLatentLeakageActuator_#{unit_num} = ReturnLatentLeakage_#{unit_num},
          Set ReturnDuctLoadToPlenumActuator_#{unit_num} = ReturnDuctLoadToPlenum_#{unit_num},
          Set ReturnConductionToAHZoneActuator_#{unit_num} = ReturnConductionToAHZone_#{unit_num},
          Set AHZoneToLivingFlowRateActuator_#{unit_num} = AHZoneToLivingFlowRate_#{unit_num},
          Set LivingToAHZoneFlowRateActuator_#{unit_num} = LivingToAHZoneFlowRate_#{unit_num};"       
        
        ems << "
        EnergyManagementSystem:ProgramCallingManager,
          DuctLeakageCallingManager_#{unit_num},                              !- Name
          EndOfSystemTimestepAfterHVACReporting,                              !- EnergyPlus Model Calling Point
          DuctLeakageProgram_#{unit_num};                                     !- Program Name 1"
          
      end      
      
    end

    ems.each do |str|
      idfObject = OpenStudio::IdfObject::load(str)
      object = idfObject.get
      wsObject = workspace.addObject(object)
      runner.registerInfo("Set object '#{str.split("\n")[1].gsub(",","")} - #{str.split("\n")[2].split(",")[0]}'")
    end    
        
    (1..num_units).to_a.each do |unit_num|
      _nbeds, _nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, unit_num, runner)
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit_spaces)      
      living_thermal_zone_name = nil
      thermal_zones.each do |thermal_zone|
        if thermal_zone.name.to_s.start_with? Constants.LivingZone
          living_thermal_zone_name = thermal_zone.name.to_s
        end
      end
      if not duct_locations[unit_num] == living_thermal_zone_name and not duct_locations[unit_num] == "none" and hasForcedAirEquipment # has ducts
        workspace.getObjectsByType("AirLoopHVAC:ReturnPath".to_IddObjectType).each do |return_path|
          if return_path.getString(0).to_s == "Central Air System_#{unit_num} Return Path"
            return_path.setString(2, "AirLoopHVAC:ReturnPlenum")
            return_path.setString(3, "Return Plenum_#{unit_num}")
          end
        end
      else # no ducts
        workspace.getObjectsByType("AirLoopHVAC:ReturnPath".to_IddObjectType).each do |return_path|
          if return_path.getString(0).to_s == "Central Air System_#{unit_num} Return Path"
            return_path.setString(2, "AirLoopHVAC:ZoneMixer")
            return_path.setString(3, "Zone Mixer_#{unit_num}")
          end
        end      
      end
    end
    
    # terrain
    terrain = {Constants.TerrainOcean=> 'Ocean',      # Ocean, Bayou flat country
               Constants.TerrainPlains=> 'Country',   # Flat, open country
               Constants.TerrainRural=> 'Country',    # Flat, open country
               Constants.TerrainSuburban=> 'Suburbs', # Rough, wooded country, suburbs
               Constants.TerrainCity=> 'City'}        # Towns, city outskirts, center of large cities
    workspace.getObjectsByType("Building".to_IddObjectType).each do |building|
      building.setString(2, terrain[terrainType])
    end
    
    return true
 
  end #end the run method

  def get_duct_location(runner, duct_location, living_thermal_zone, garage_thermal_zone, fbasement_thermal_zone, ufbasement_thermal_zone, crawl_thermal_zone, ufattic_thermal_zone)
    if duct_location == Constants.Auto
      if not fbasement_thermal_zone.nil?
        duct_location = fbasement_thermal_zone.name.to_s
      elsif not ufbasement_thermal_zone.nil?
        duct_location = ufbasement_thermal_zone.name.to_s
      elsif not crawl_thermal_zone.nil?
        duct_location = crawl_thermal_zone.name.to_s
      elsif not ufattic_thermal_zone.nil?
        duct_location = ufattic_thermal_zone.name.to_s
      elsif not garage_thermal_zone.nil?
        duct_location = garage_thermal_zone.name.to_s
      else
        duct_location = living_thermal_zone.name.to_s
      end
    elsif duct_location == Constants.BasementZone
      if not fbasement_thermal_zone.nil?
        duct_location = fbasement_thermal_zone.name.to_s
      elsif not ufbasement_thermal_zone.nil?
        duct_location = ufbasement_thermal_zone.name.to_s
      else
        return false
      end
    elsif duct_location == Constants.AtticZone
      if not ufattic_thermal_zone.nil?
        duct_location = ufattic_thermal_zone.name.to_s
      else
        duct_location = living_thermal_zone.name.to_s
      end
    end
    if duct_location == Constants.FinishedAtticZone
      duct_location = living_thermal_zone.name.to_s
    elsif duct_location == Constants.PierBeamZone
      duct_location = crawl_thermal_zone.name.to_s
    end
    return duct_location    
  end
  
  def get_duct_supply_surface_area(mult, geometry, num_stories)
    # Duct Surface Areas per 2010 BA Benchmark
    ffa = geometry.finished_floor_area
    if num_stories == 1
      return 0.27 * ffa * mult # ft^2
    else
      return 0.2 * ffa * mult
    end
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
  
  def get_duct_return_surface_area(mult, geometry, num_stories, duct_num_returns)
    # Duct Surface Areas per 2010 BA Benchmark
    ffa = geometry.finished_floor_area
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
  
  def calc_duct_leakage_from_test(d, ffa, fan_airflowrate)
    # Calculates duct leakage inputs based on duct blaster type leakage measurements (cfm @ 25 Pa per 100 ft2 conditioned floor area).
    # Requires assumptions about supply/return leakage split, air handler leakage, and duct plenum (de)pressurization.
    # Assumptions
    supply_duct_leakage_frac = 0.67 # 2013 RESNET Standards, Appendix A, p.A-28
    return_duct_leakage_frac = 0.33 # 2013 RESNET Standards, Appendix A, p.A-28
    ah_leakage = 0.025 # 2.5% of air handler flow at 25 P (Reference: ASHRAE Standard 152-2004, Annex C, p 33; Walker et al 2010. "Air Leakage of Furnaces and Air Handlers") 
    ah_supply_frac = 0.20 # (Reference: Walker et al 2010. "Air Leakage of Furnaces and Air Handlers") 
    ah_return_frac = 0.80 # (Reference: Walker et al 2010. "Air Leakage of Furnaces and Air Handlers")
    p_supply = 25 # Assume average operating pressure in ducts is 25 Pa, 
    p_return = 25 # though it is likely lower (Reference: Pigg and Francisco 2008 "A Field Study of Exterior Duct Leakage in New Wisconsin Homes")
    
    # Conversion
    cfm25 = d.DuctNormLeakageToOutside * ffa / 100.0 #denormalize leakage
    ah_cfm25 = ah_leakage * fan_airflowrate # air handler leakage flow rate at 25 Pa
    ah_supply_leak_cfm25 = [ah_cfm25 * ah_supply_frac, cfm25 * supply_duct_leakage_frac].min
    ah_return_leak_cfm25 = [ah_cfm25 * ah_return_frac, cfm25 * return_duct_leakage_frac].min
    supply_leak_cfm25 = [cfm25 * supply_duct_leakage_frac - ah_supply_leak_cfm25, 0].max
    return_leak_cfm25 = [cfm25 * return_duct_leakage_frac - ah_return_leak_cfm25, 0].max
    
    d.supply_leak_oper = calc_duct_leakage_at_diff_pressure(supply_leak_cfm25, 25, P_supply) # cfm at operating pressure
    d.return_leak_oper = calc_duct_leakage_at_diff_pressure(return_leak_cfm25, 25, P_return) # cfm at operating pressure
    d.ah_supply_leak_oper = calc_duct_leakage_at_diff_pressure(AH_supply_leak_cfm25, 25, P_supply) # cfm at operating pressure
    d.ah_return_leak_oper = calc_duct_leakage_at_diff_pressure(AH_return_leak_cfm25, 25, P_return) # cfm at operating pressure
    
    if fan_airflowrate == 0
      d.DuctSupplyLeakage = 0
      d.DuctReturnLeakage = 0
      d.DuctAHSupplyLeakage = 0
      d.DuctAHReturnLeakage = 0
    else
      d.DuctSupplyLeakage = d.supply_leak_oper / fan_airflowrate
      d.DuctReturnLeakage = d.return_leak_oper / fan_airflowrate
      d.DuctAHSupplyLeakage = d.ah_supply_leak_oper / fan_airflowrate
      d.DuctAHReturnLeakage = d.ah_return_leak_oper / fan_airflowrate      
    end
    
    d.supply_duct_loss = d.DuctSupplyLeakage + d.DuctAHSupplyLeakage
    d.return_duct_loss = d.DuctReturnLeakage + d.DuctAHReturnLeakage
    
    # Leakage to outside was specified, so don't account for location fraction
    d.DuctLocationFracLeakage = 1
    
    return d
  end 
  
  def _processInfiltrationForUnit(si, living_space, finished_basement, garage, unfinished_basement, crawlspace, unfinished_attic, fbasement_thermal_zone, garage_thermal_zone, ufbasement_thermal_zone, crawl_thermal_zone, ufattic_thermal_zone, ws, geometry, unit_spaces)
    # Infiltration calculations.
    
    spaces = []
    spaces << living_space
    unless fbasement_thermal_zone.nil?
      spaces << finished_basement
    end    
    unless garage_thermal_zone.nil?
      spaces << garage
    end
    unless ufbasement_thermal_zone.nil?
      spaces << unfinished_basement
    end
    unless crawl_thermal_zone.nil?
      spaces << crawlspace
    end
    unless ufattic_thermal_zone.nil?
      spaces << unfinished_attic
    end
    
    spaces.each do |space|
      space.inf_method = nil
      space.SLA = nil
      space.ACH = nil
      space.inf_flow = nil
      space.hor_leak_frac = nil
      space.neutral_level = nil
    end

    unless garage_thermal_zone.nil?
    
      garage.inf_method = Constants.InfMethodSG
      garage.hor_leak_frac = 0.4 # DOE-2 Default
      garage.neutral_level = 0.5 # DOE-2 Default
      garage.SLA = get_infiltration_SLA_from_ACH50(si.InfiltrationGarageACH50, 0.67, garage.area, garage.volume)
      garage.ACH = get_infiltration_ACH_from_SLA(garage.SLA, 1.0, @weather)
      # Convert ACH to cfm:
      garage.inf_flow = garage.ACH / OpenStudio::convert(1.0,"hr","min").get * garage.volume # cfm
          
    end

    unless ufbasement_thermal_zone.nil?

      unfinished_basement.inf_method = Constants.InfMethodRes # Used for constant ACH
      unfinished_basement.ACH = unfinished_basement.UFBsmtACH
      # Convert ACH to cfm
      unfinished_basement.inf_flow = unfinished_basement.ACH / OpenStudio::convert(1.0,"hr","min").get * unfinished_basement.volume

    end

    unless crawl_thermal_zone.nil?

      crawlspace.inf_method = Constants.InfMethodRes

      crawlspace.ACH = crawlspace.CrawlACH
      # Convert ACH to cfm
      crawlspace.inf_flow = crawlspace.ACH / OpenStudio::convert(1.0,"hr","min").get * crawlspace.volume

    end

    unless ufattic_thermal_zone.nil?

      unfinished_attic.inf_method = Constants.InfMethodSG
      unfinished_attic.hor_leak_frac = 0.75 # Same as Energy Gauge USA Attic Model
      unfinished_attic.neutral_level = 0.5 # DOE-2 Default
      unfinished_attic.SLA = unfinished_attic.UASLA

      unfinished_attic.ACH = get_infiltration_ACH_from_SLA(unfinished_attic.SLA, 1.0, @weather)

      # Convert ACH to cfm
      unfinished_attic.inf_flow = unfinished_attic.ACH / OpenStudio::convert(1.0,"hr","min").get * unfinished_attic.volume

    end    
        
    living_space.inf_method = nil
    living_space.SLA = nil
    living_space.ACH = nil
    living_space.inf_flow = nil
    living_space.hor_leak_frac = nil
    living_space.neutral_level = nil
    unless fbasement_thermal_zone.nil?
      finished_basement.inf_method = nil
      finished_basement.SLA = nil
      finished_basement.ACH = nil
      finished_basement.inf_flow = nil
      finished_basement.hor_leak_frac = nil
      finished_basement.neutral_level = nil
    end
  
    outside_air_density = UnitConversion.atm2Btu_ft3(@weather.header.LocalPressure) / (Gas.Air.r * (@weather.data.AnnualAvgDrybulb + 460.0))
    inf_conv_factor = 776.25 # [ft/min]/[inH2O^(1/2)*ft^(3/2)/lbm^(1/2)]
    delta_pref = 0.016 # inH2O

    # Assume an average inside temperature
    si.assumed_inside_temp = Constants.AssumedInsideTemp # deg F, used other places. Make available.  
  
    if not si.InfiltrationLivingSpaceACH50.nil?
      if living_space.volume == 0
          living_space.SLA = 0
          living_space.ELA = 0
          living_space.ACH = 0
          living_space.inf_flow = 0
      else
          # Living Space Infiltration
          living_space.inf_method = Constants.InfMethodASHRAE

          # Based on "Field Validation of Algebraic Equations for Stack and
          # Wind Driven Air Infiltration Calculations" by Walker and Wilson (1998)

          # Pressure Exponent
          si.n_i = 0.67
          
          # Calculate SLA for above-grade portion of the building
          geometry.SLA = get_infiltration_SLA_from_ACH50(si.InfiltrationLivingSpaceACH50, si.n_i, geometry.above_grade_finished_floor_area, geometry.above_grade_volume)

          # Effective Leakage Area (ft^2)
          si.A_o = geometry.SLA * geometry.above_grade_finished_floor_area * (Geometry.calculate_exterior_wall_area(unit_spaces)/geometry.above_grade_exterior_wall_area)

          # Calculate SLA for unit
          living_space.SLA = si.A_o / Geometry.get_above_grade_finished_floor_area_from_spaces(unit_spaces)
    
          # Flow Coefficient (cfm/inH2O^n) (based on ASHRAE HoF)
          si.C_i = si.A_o * (2.0 / outside_air_density) ** 0.5 * delta_pref ** (0.5 - si.n_i) * inf_conv_factor
          has_flue = false

          if has_flue
            # for future use
            flue_diameter = 0.5 # after() do
            si.Y_i = flue_diameter ** 2.0 / 4.0 / si.A_o # Fraction of leakage through the flu
            si.flue_height = geometry.building_height + 2.0 # ft
            si.S_wflue = 1.0 # Flue Shelter Coefficient
          else
            si.Y_i = 0.0 # Fraction of leakage through the flu
            si.flue_height = 0.0 # ft
            si.S_wflue = 0.0 # Flue Shelter Coefficient
          end

          # Leakage distributions per Iain Walker (LBL) recommendations
          if not crawl_thermal_zone.nil? and crawlspace.CrawlACH > 0
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
          si.R_i = (leakage_ceiling + leakage_floor)
          si.X_i = (leakage_ceiling - leakage_floor)
          si.R_i = si.R_i * (1 - si.Y_i)
          si.X_i = si.X_i * (1 - si.Y_i)         
          
          living_space.hor_leak_frac = si.R_i
          si.Z_f = si.flue_height / (living_space.height + living_space.coord_z)

          # Calculate Stack Coefficient
          si.M_o = (si.X_i + (2.0 * si.n_i + 1.0) * si.Y_i) ** 2.0 / (2 - si.R_i)

          if si.M_o <= 1.0
            si.M_i = si.M_o # eq. 10
          else
            si.M_i = 1.0 # eq. 11
          end

          if has_flue
            # Eq. 13
            si.X_c = si.R_i + (2.0 * (1.0 - si.R_i - si.Y_i)) / (si.n_i + 1.0) - 2.0 * si.Y_i * (si.Z_f - 1.0) ** si.n_i
            # Additive flue function, Eq. 12
            si.F_i = si.n_i * si.Y_y * (si.Z_f - 1.0) ** ((3.0 * si.n_i - 1.0) / 3.0) * (1.0 - (3.0 * (si.X_c - si.X_i) ** 2.0 * si.R_i ** (1 - si.n_i)) / (2.0 * (si.Z_f + 1.0)))
          else
            # Critical value of ceiling-floor leakage difference where the
            # neutral level is located at the ceiling (eq. 13)
            si.X_c = si.R_i + (2.0 * (1.0 - si.R_i - si.Y_i)) / (si.n_i + 1.0)
            # Additive flue function (eq. 12)
            si.F_i = 0.0
          end

          si.f_s = ((1.0 + si.n_i * si.R_i) / (si.n_i + 1.0)) * (0.5 - 0.5 * si.M_i ** (1.2)) ** (si.n_i + 1.0) + si.F_i

          si.stack_coef = si.f_s * (UnitConversion.lbm_fts22inH2O(outside_air_density * Constants.g * living_space.height) / (si.assumed_inside_temp + 460.0)) ** si.n_i # inH2O^n/R^n

          # Calculate wind coefficient
          if not crawl_thermal_zone.nil? and crawlspace.CrawlACH > 0

            if si.X_i > 1.0 - 2.0 * si.Y_i
              # Critical floor to ceiling difference above which f_w does not change (eq. 25)
              si.X_i = 1.0 - 2.0 * si.Y_i
            end

            # Redefined R for wind calculations for houses with crawlspaces (eq. 21)
            si.R_x = 1.0 - si.R_i * (si.n_i / 2.0 + 0.2)
            # Redefined Y for wind calculations for houses with crawlspaces (eq. 22)
            si.Y_x = 1.0 - si.Y_i / 4.0
            # Used to calculate X_x (eq.24)
            si.X_s = (1.0 - si.R_i) / 5.0 - 1.5 * si.Y_i
            # Redefined X for wind calculations for houses with crawlspaces (eq. 23)
            si.X_x = 1.0 - (((si.X_i - si.X_s) / (2.0 - si.R_i)) ** 2.0) ** 0.75
            # Wind factor (eq. 20)
            si.f_w = 0.19 * (2.0 - si.n_i) * si.X_x * si.R_x * si.Y_x

          else

            si.J_i = (si.X_i + si.R_i + 2.0 * si.Y_i) / 2.0
            si.f_w = 0.19 * (2.0 - si.n_i) * (1.0 - ((si.X_i + si.R_i) / 2.0) ** (1.5 - si.Y_i)) - si.Y_i / 4.0 * (si.J_i - 2.0 * si.Y_i * si.J_i ** 4.0)

          end

          si.wind_coef = si.f_w * UnitConversion.lbm_ft32inH2O_mph2(outside_air_density / 2.0) ** si.n_i # inH2O^n/mph^2n

          living_space.ACH = get_infiltration_ACH_from_SLA(living_space.SLA, geometry.stories, @weather)

          # Convert living space ACH to cfm:
          living_space.inf_flow = living_space.ACH / OpenStudio::convert(1.0,"hr","min").get * living_space.volume # cfm
          
      end
          
    end
    
    unless fbasement_thermal_zone.nil?

      finished_basement.inf_method = Constants.InfMethodRes # Used for constant ACH
      finished_basement.ACH = finished_basement.FBsmtACH
      # Convert ACH to cfm
      finished_basement.inf_flow = finished_basement.ACH / OpenStudio::convert(1.0,"hr","min").get * finished_basement.volume

    end

    spaces.each do |space|
    
      if space.volume == 0
        next
      end
      
      space.f_t_SG = ws.site_terrain_multiplier * ((space.height + space.coord_z) / 32.8) ** ws.site_terrain_exponent / (ws.terrain_multiplier * (ws.height / 32.8) ** ws.terrain_exponent)
      space.f_s_SG = nil
      space.f_w_SG = nil
      space.C_s_SG = nil
      space.C_w_SG = nil
      space.ELA = nil

      if space.inf_method == Constants.InfMethodSG

        space.f_s_SG = 2.0 / 3.0 * (1 + space.hor_leak_frac / 2.0) * (2.0 * space.neutral_level * (1.0 - space.neutral_level)) ** 0.5 / (space.neutral_level ** 0.5 + (1.0 - space.neutral_level) ** 0.5)
        space.f_w_SG = ws.shielding_coef * (1.0 - space.hor_leak_frac) ** (1.0 / 3.0) * space.f_t_SG
        space.C_s_SG = space.f_s_SG ** 2.0 * Constants.g * space.height / (si.assumed_inside_temp + 460.0)
        space.C_w_SG = space.f_w_SG ** 2.0
        space.ELA = space.SLA * space.area # ft^2

      elsif space.inf_method == Constants.InfMethodASHRAE

        space.ELA = space.SLA * space.area # ft^2

      else

        space.ELA = 0 # ft^2
        space.hor_leak_frac = 0

      end

    end
    
    return si, living_space, finished_basement, garage, unfinished_basement, crawlspace, unfinished_attic, ws
    
  end
  
  def _processMechanicalVentilation(unit_num, infil, vent, ageOfHome, dryerExhaust, geometry, unit, living_space, schedules)
    # Mechanical Ventilation

    # Get ASHRAE 62.2 required ventilation rate (excluding infiltration credit)
    ashrae_mv_without_infil_credit = get_mech_vent_whole_house_cfm(1, unit.num_bedrooms, unit.finished_floor_area, vent.MechVentASHRAEStandard) 
    
    # Determine mechanical ventilation infiltration credit (per ASHRAE 62.2)
    infil.rate_credit = 0 # default to no credit
    if vent.MechVentInfilCredit
        if vent.MechVentASHRAEStandard == '2010' and ageOfHome > 0
            # ASHRAE Standard 62.2 2010
            # Only applies to existing buildings
            # 2 cfm per 100ft^2 of occupiable floor area
            infil.default_rate = 2.0 * geometry.finished_floor_area / 100.0 # cfm
            # Half the excess infiltration rate above the default rate is credited toward mech vent:
            infil.rate_credit = [(living_space.inf_flow - infil.default_rate) / 2.0, 0].max          
        elsif vent.MechVentASHRAEStandard == '2013' and geometry.num_units == 1
            # ASHRAE Standard 62.2 2013
            # Only applies to single-family homes (Section 8.2.1: "The required mechanical ventilation 
            # rate shall not be reduced as described in Section 4.1.3.").     
            ela = infil.A_o # Effective leakage area, ft^2
            nl = 1000.0 * ela / living_space.area * (living_space.height / 8.2) ** 0.4 # Normalized leakage, eq. 4.4
            qinf = nl * @weather.data.WSF * living_space.area / 7.3 # Effective annual average infiltration rate, cfm, eq. 4.5a
            infil.rate_credit = [(2.0 / 3.0) * ashrae_mv_without_infil_credit, qinf].min
        end
    end
    
    # Apply infiltration credit (if any)
    vent.ashrae_vent_rate = [ashrae_mv_without_infil_credit - infil.rate_credit, 0.0].max # cfm
    # Apply fraction of ASHRAE value
    vent.whole_house_vent_rate = vent.MechVentFractionOfASHRAE * vent.ashrae_vent_rate # cfm    

    # Spot Ventilation
    vent.MechVentBathroomExhaust = 50.0 # cfm, per HSP
    vent.MechVentRangeHoodExhaust = 100.0 # cfm, per HSP
    vent.MechVentSpotFanPower = 0.3 # W/cfm/fan, per HSP

    vent.bath_exhaust_operation = 60.0 # min/day, per HSP
    vent.range_hood_exhaust_operation = 60.0 # min/day, per HSP
    vent.clothes_dryer_exhaust_operation = 60.0 # min/day, per HSP

    if vent.MechVentType == Constants.VentTypeExhaust
        vent.num_vent_fans = 1 # One fan for unbalanced airflow
    elsif vent.MechVentType == Constants.VentTypeSupply
        vent.num_vent_fans = 1 # One fan for unbalanced airflow
    elsif vent.MechVentType == Constants.VentTypeBalanced
        vent.num_vent_fans = 2 # Two fans for balanced airflow
    else
        vent.num_vent_fans = 1 # Default to one fan
    end

    if vent.MechVentType == Constants.VentTypeExhaust
      vent.percent_fan_heat_to_space = 0.0 # Fan heat does not enter space
    elsif vent.MechVentType == Constants.VentTypeSupply
      vent.percent_fan_heat_to_space = 1.0 # Fan heat does enter space
    elsif vent.MechVentType == Constants.VentTypeBalanced
      vent.percent_fan_heat_to_space = 0.5 # Assumes supply fan heat enters space
    else
      vent.percent_fan_heat_to_space = 0.0
    end

    vent.bathroom_hour_avg_exhaust = vent.MechVentBathroomExhaust * unit.num_bathrooms * vent.bath_exhaust_operation / 60.0 # cfm
    vent.range_hood_hour_avg_exhaust = vent.MechVentRangeHoodExhaust * vent.range_hood_exhaust_operation / 60.0 # cfm
    vent.clothes_dryer_hour_avg_exhaust = dryerExhaust * vent.clothes_dryer_exhaust_operation / 60.0 # cfm

    vent.max_power = [vent.bathroom_hour_avg_exhaust * vent.MechVentSpotFanPower + vent.whole_house_vent_rate * vent.MechVentHouseFanPower * vent.num_vent_fans, vent.range_hood_hour_avg_exhaust * vent.MechVentSpotFanPower + vent.whole_house_vent_rate * vent.MechVentHouseFanPower * vent.num_vent_fans].max / OpenStudio::convert(1.0,"kW","W").get # kW

    # Fan energy schedule (as fraction of maximum power). Bathroom
    # exhaust at 7:00am and range hood exhaust at 6:00pm. Clothes
    # dryer exhaust not included in mech vent power.
    if vent.max_power > 0
      vent.hourly_energy_schedule = Array.new(24, vent.whole_house_vent_rate * vent.MechVentHouseFanPower * vent.num_vent_fans / OpenStudio::convert(1.0,"kW","W").get / vent.max_power)
      vent.hourly_energy_schedule[6] = ((vent.bathroom_hour_avg_exhaust * vent.MechVentSpotFanPower + vent.whole_house_vent_rate * vent.MechVentHouseFanPower * vent.num_vent_fans) / OpenStudio::convert(1.0,"kW","W").get / vent.max_power)
      vent.hourly_energy_schedule[17] = ((vent.range_hood_hour_avg_exhaust * vent.MechVentSpotFanPower + vent.whole_house_vent_rate * vent.MechVentHouseFanPower * vent.num_vent_fans) / OpenStudio::convert(1.0,"kW","W").get / vent.max_power)
      vent.average_vent_fan_eff = ((vent.whole_house_vent_rate * 24.0 * vent.MechVentHouseFanPower * vent.num_vent_fans + (vent.bathroom_hour_avg_exhaust + vent.range_hood_hour_avg_exhaust) * vent.MechVentSpotFanPower) / (vent.whole_house_vent_rate * 24.0 + vent.bathroom_hour_avg_exhaust + vent.range_hood_hour_avg_exhaust))
    else
      vent.hourly_energy_schedule = Array.new(24, 0.0)
    end

    sch_year = "
    Schedule:Year,
      MechanicalVentilationEnergy_#{unit_num},            !- Name
      FRACTION,                                           !- Schedule Type
      MechanicalVentilationEnergyWk_#{unit_num},          !- Week Schedule Name
      1,                                                  !- Start Month
      1,                                                  !- Start Day
      12,                                                 !- End Month
      31;                                                 !- End Day"

    sch_hourly = "
    Schedule:Day:Hourly,
      MechanicalVentilationEnergyDay_#{unit_num},         !- Name
      FRACTION,                                           !- Schedule Type"

    vent.hourly_energy_schedule[0..22].each do |hour|
      sch_hourly += "#{hour},\n"
    end
    sch_hourly += "#{vent.hourly_energy_schedule[23]};"

    sch_week = "
    Schedule:Week:Compact,
      MechanicalVentilationEnergyWk_#{unit_num},          !- Name
      For: Weekdays,
      MechanicalVentilationEnergyDay_#{unit_num},
      For: CustomDay1,
      MechanicalVentilationEnergyDay_#{unit_num},
      For: CustomDay2,
      MechanicalVentilationEnergyDay_#{unit_num},
      For: AllOtherDays,
      MechanicalVentilationEnergyDay_#{unit_num};"

    schedules.MechanicalVentilationEnergy = [sch_hourly, sch_week, sch_year]

    vent.base_vent_rate = vent.whole_house_vent_rate * (1.0 - vent.MechVentTotalEfficiency)
    vent.max_vent_rate = [vent.bathroom_hour_avg_exhaust, vent.range_hood_hour_avg_exhaust, vent.clothes_dryer_hour_avg_exhaust].max + vent.base_vent_rate

    # Ventilation schedule (as fraction of maximum flow). Assume bathroom
    # exhaust at 7:00am, range hood exhaust at 6:00pm, and clothes dryer
    # exhaust at 11am.
    if vent.max_vent_rate > 0
      vent.hourly_schedule = Array.new(24, vent.base_vent_rate / vent.max_vent_rate)
      vent.hourly_schedule[6] = (vent.bathroom_hour_avg_exhaust + vent.base_vent_rate) / vent.max_vent_rate
      vent.hourly_schedule[10] = (vent.clothes_dryer_hour_avg_exhaust + vent.base_vent_rate) / vent.max_vent_rate
      vent.hourly_schedule[17] = (vent.range_hood_hour_avg_exhaust + vent.base_vent_rate) / vent.max_vent_rate
    else
      vent.hourly_schedule = Array.new(24, 0.0)
    end

    sch_year = "
    Schedule:Year,
      MechanicalVentilation_#{unit_num},                  !- Name
      FRACTION,                                           !- Schedule Type
      MechanicalVentilationWk_#{unit_num},                !- Week Schedule Name
      1,                                                  !- Start Month
      1,                                                  !- Start Day
      12,                                                 !- End Month
      31;                                                 !- End Day"

    sch_hourly = "
    Schedule:Day:Hourly,
      MechanicalVentilationDay_#{unit_num},               !- Name
      FRACTION,                                           !- Schedule Type"

    vent.hourly_schedule[0..22].each do |hour|
      sch_hourly += "#{hour},\n"
    end
    sch_hourly += "#{vent.hourly_schedule[23]};"

    sch_week = "
    Schedule:Week:Compact,
      MechanicalVentilationWk_#{unit_num},                !- Name
      For: Weekdays,
      MechanicalVentilationDay_#{unit_num},
      For: CustomDay1,
      MechanicalVentilationDay_#{unit_num},
      For: CustomDay2,
      MechanicalVentilationDay_#{unit_num},
      For: AllOtherDays,
      MechanicalVentilationDay_#{unit_num};"

    schedules.MechanicalVentilation = [sch_hourly, sch_week, sch_year]

    bath_exhaust_hourly = Array.new(24, 0.0)
    bath_exhaust_hourly[6] = 1.0

    sch_year = "
    Schedule:Year,
      BathExhaust_#{unit_num},                            !- Name
      FRACTION,                                           !- Schedule Type
      BathExhaustWk_#{unit_num},                          !- Week Schedule Name
      1,                                                  !- Start Month
      1,                                                  !- Start Day
      12,                                                 !- End Month
      31;                                                 !- End Day"

    sch_hourly = "
    Schedule:Day:Hourly,
      BathExhaustDay_#{unit_num},                         !- Name
      FRACTION,                                           !- Schedule Type
      "
    bath_exhaust_hourly[0..22].each do |hour|
      sch_hourly += "#{hour}\n,"
    end
    sch_hourly += "#{bath_exhaust_hourly[23]};"

    sch_week = "
    Schedule:Week:Compact,
      BathExhaustWk_#{unit_num},                          !- Name
      For: Weekdays,
      BathExhaustDay_#{unit_num},
      For: CustomDay1,
      BathExhaustDay_#{unit_num},
      For: CustomDay2,
      BathExhaustDay_#{unit_num},
      For: AllOtherDays,
      BathExhaustDay_#{unit_num};"

    schedules.BathExhaust = [sch_hourly, sch_week, sch_year]

    clothes_dryer_exhaust_hourly = Array.new(24, 0.0)
    clothes_dryer_exhaust_hourly[10] = 1.0

    sch_year = "
    Schedule:Year,
      ClothesDryerExhaust_#{unit_num},                    !- Name
      FRACTION,                                           !- Schedule Type
      ClothesDryerExhaustWk_#{unit_num},                  !- Week Schedule Name
      1,                                                  !- Start Month
      1,                                                  !- Start Day
      12,                                                 !- End Month
      31;                                                 !- End Day"

    sch_hourly = "
    Schedule:Day:Hourly,
      ClothesDryerExhaustDay_#{unit_num},                 !- Name
      FRACTION,                                           !- Schedule Type
      "
    clothes_dryer_exhaust_hourly[0..22].each do |hour|
      sch_hourly += "#{hour},\n"
    end
    sch_hourly += "#{clothes_dryer_exhaust_hourly[23]};"

    sch_week = "
    Schedule:Week:Compact,
      ClothesDryerExhaustWk_#{unit_num},                  !- Name
      For: Weekdays,
      ClothesDryerExhaustDay_#{unit_num},
      For: CustomDay1,
      ClothesDryerExhaustDay_#{unit_num},
      For: CustomDay2,
      ClothesDryerExhaustDay_#{unit_num},
      For: AllOtherDays,
      ClothesDryerExhaustDay_#{unit_num};"

    schedules.ClothesDryerExhaust = [sch_hourly, sch_week, sch_year]

    range_hood_hourly = Array.new(24, 0.0)
    range_hood_hourly[17] = 1.0

    sch_year = "
    Schedule:Year,
      RangeHood_#{unit_num},                              !- Name
      FRACTION,                                           !- Schedule Type
      RangeHoodWk_#{unit_num},                            !- Week Schedule Name
      1,                                                  !- Start Month
      1,                                                  !- Start Day
      12,                                                 !- End Month
      31;                                                 !- End Day"

    sch_hourly = "
    Schedule:Day:Hourly,
      RangeHoodDay_#{unit_num},                           !- Name
      FRACTION,                                           !- Schedule Type
      "
    range_hood_hourly[0..22].each do |hour|
      sch_hourly += "#{hour},\n"
    end
    sch_hourly += "#{range_hood_hourly[23]};"

    sch_week = "
    Schedule:Week:Compact,
      RangeHoodWk_#{unit_num},                            !- Name
      For: Weekdays,
      RangeHoodDay_#{unit_num},
      For: CustomDay1,
      RangeHoodDay_#{unit_num},
      For: CustomDay2,
      RangeHoodDay_#{unit_num},
      For: AllOtherDays,
      RangeHoodDay_#{unit_num};"

    schedules.RangeHood = [sch_hourly, sch_week, sch_year]

    #--- Calculate HRV/ERV effectiveness values. Calculated here for use in sizing routines.

    vent.MechVentApparentSensibleEffectiveness = 0.0
    vent.MechVentHXCoreSensibleEffectiveness = 0.0
    vent.MechVentLatentEffectiveness = 0.0

    if vent.MechVentType == Constants.VentTypeBalanced and vent.MechVentSensibleEfficiency > 0 and vent.whole_house_vent_rate > 0
      # Must assume an operating condition (HVI seems to use CSA 439)
      t_sup_in = 0
      w_sup_in = 0.0028
      t_exh_in = 22
      w_exh_in = 0.0065
      cp_a = 1006
      p_fan = vent.whole_house_vent_rate * vent.MechVentHouseFanPower                                         # Watts

      m_fan = OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get * 16.02 * Psychrometrics.rhoD_fT_w_P(OpenStudio::convert(t_sup_in,"C","F").get, w_sup_in, 14.7) # kg/s

      # The following is derived from (taken from CSA 439):
      #    E_SHR = (m_sup,fan * Cp * (Tsup,out - Tsup,in) - P_sup,fan) / (m_exh,fan * Cp * (Texh,in - Tsup,in) + P_exh,fan)
      t_sup_out = t_sup_in + (vent.MechVentSensibleEfficiency * (m_fan * cp_a * (t_exh_in - t_sup_in) + p_fan) + p_fan) / (m_fan * cp_a)

      # Calculate the apparent sensible effectiveness
      vent.MechVentApparentSensibleEffectiveness = (t_sup_out - t_sup_in) / (t_exh_in - t_sup_in)

      # Calculate the supply temperature before the fan
      t_sup_out_gross = t_sup_out - p_fan / (m_fan * cp_a)

      # Sensible effectiveness of the HX only
      vent.MechVentHXCoreSensibleEffectiveness = (t_sup_out_gross - t_sup_in) / (t_exh_in - t_sup_in)

      if (vent.MechVentHXCoreSensibleEffectiveness < 0.0) or (vent.MechVentHXCoreSensibleEffectiveness > 1.0)
        return
      end

      # Use summer test condition to determine the latent effectivess since TRE is generally specified under the summer condition
      if vent.MechVentTotalEfficiency > 0

        t_sup_in = 35.0
        w_sup_in = 0.0178
        t_exh_in = 24.0
        w_exh_in = 0.0092

        m_fan = OpenStudio::convert(vent.whole_house_vent_rate,"cfm","m^3/s").get * UnitConversion.lbm_ft32kg_m3(Psychrometrics.rhoD_fT_w_P(OpenStudio::convert(t_sup_in,"C","F").get, w_sup_in, 14.7)) # kg/s

        t_sup_out_gross = t_sup_in - vent.MechVentHXCoreSensibleEffectiveness * (t_sup_in - t_exh_in)
        t_sup_out = t_sup_out_gross + p_fan / (m_fan * cp_a)

        h_sup_in = Psychrometrics.h_fT_w_SI(t_sup_in, w_sup_in)
        h_exh_in = Psychrometrics.h_fT_w_SI(t_exh_in, w_exh_in)
        h_sup_out = h_sup_in - (vent.MechVentTotalEfficiency * (m_fan * (h_sup_in - h_exh_in) + p_fan) + p_fan) / m_fan

        w_sup_out = Psychrometrics.w_fT_h_SI(t_sup_out, h_sup_out)
        vent.MechVentLatentEffectiveness = [0.0, (w_sup_out - w_sup_in) / (w_exh_in - w_sup_in)].max

        if (vent.MechVentLatentEffectiveness < 0.0) or (vent.MechVentLatentEffectiveness > 1.0)
          return
        end

      else
        vent.MechVentLatentEffectiveness = 0.0
      end
    else
      if vent.MechVentTotalEfficiency > 0
        vent.MechVentApparentSensibleEffectiveness = vent.MechVentTotalEfficiency
        vent.MechVentHXCoreSensibleEffectiveness = vent.MechVentTotalEfficiency
        vent.MechVentLatentEffectiveness = vent.MechVentTotalEfficiency
      end
    end

    return vent, schedules

  end

  def _processNaturalVentilation(workspace, unit_num, nv, living_space, wind_speed, infiltration, schedules, geometry, coolingSetpointWeekday, coolingSetpointWeekend, heatingSetpointWeekday, heatingSetpointWeekend)
    # Natural Ventilation

    # Specify an array of hourly lower-temperature-limits for natural ventilation
    nv.htg_ssn_hourly_temp = Array.new
    coolingSetpointWeekday.each do |x|
      nv.htg_ssn_hourly_temp << OpenStudio::convert(x - nv.NatVentHtgSsnSetpointOffset,"F","C").get
    end
    nv.htg_ssn_hourly_weekend_temp = Array.new
    coolingSetpointWeekend.each do |x|
      nv.htg_ssn_hourly_weekend_temp << OpenStudio::convert(x - nv.NatVentHtgSsnSetpointOffset,"F","C").get
    end

    nv.clg_ssn_hourly_temp = Array.new
    heatingSetpointWeekday.each do |x|
      nv.clg_ssn_hourly_temp << OpenStudio::convert(x + nv.NatVentClgSsnSetpointOffset,"F","C").get
    end
    nv.clg_ssn_hourly_weekend_temp = Array.new
    heatingSetpointWeekend.each do |x|
      nv.clg_ssn_hourly_weekend_temp << OpenStudio::convert(x + nv.NatVentClgSsnSetpointOffset,"F","C").get
    end

    nv.ovlp_ssn_hourly_temp = Array.new(24, OpenStudio::convert([heatingSetpointWeekday.max, heatingSetpointWeekend.max].max + nv.NatVentOvlpSsnSetpointOffset,"F","C").get)
    nv.ovlp_ssn_hourly_weekend_temp = nv.ovlp_ssn_hourly_temp

    # Natural Ventilation Probability Schedule (DOE2, not E+)
    sch_year = "
    Schedule:Constant,
      NatVentProbability_#{unit_num},                     !- Name
      FRACTION,                                           !- Schedule Type
      1,                                                  !- Hourly Value"

    schedules.NatVentProbability = [sch_year]

    nat_vent_clg_ssn_temp = "
    Schedule:Week:Compact,
      NatVentClgSsnTempWeek_#{unit_num},                  !- Name
      For: Weekdays,
      NatVentClgSsnTempWkDay_#{unit_num},
      For: CustomDay1,
      NatVentClgSsnTempWkDay_#{unit_num},
      For: CustomDay2,
      NatVentClgSsnTempWkEnd_#{unit_num},
      For: AllOtherDays,
      NatVentClgSsnTempWkEnd_#{unit_num};"

    nat_vent_htg_ssn_temp = "
    Schedule:Week:Compact,
      NatVentHtgSsnTempWeek_#{unit_num},                  !- Name
      For: Weekdays,
      NatVentHtgSsnTempWkDay_#{unit_num},
      For: CustomDay1,
      NatVentHtgSsnTempWkDay_#{unit_num},
      For: CustomDay2,
      NatVentHtgSsnTempWkEnd_#{unit_num},
      For: AllOtherDays,
      NatVentHtgSsnTempWkEnd_#{unit_num};"

    nat_vent_ovlp_ssn_temp = "
    Schedule:Week:Compact,
      NatVentOvlpSsnTempWeek_#{unit_num},                 !- Name
      For: Weekdays,
      NatVentOvlpSsnTempWkDay_#{unit_num},
      For: CustomDay1,
      NatVentOvlpSsnTempWkDay_#{unit_num},
      For: CustomDay2,
      NatVentOvlpSsnTempWkEnd_#{unit_num},
      For: AllOtherDays,
      NatVentOvlpSsnTempWkEnd_#{unit_num};"

    natVentHtgSsnTempWkDay_hourly = "
    Schedule:Day:Hourly,
      NatVentHtgSsnTempWkDay_#{unit_num},                 !- Name
      TEMPERATURE,                                        !- Schedule Type"

    nv.htg_ssn_hourly_temp[0..22].each do |hour|
      natVentHtgSsnTempWkDay_hourly += "#{hour}\n,"
    end
    natVentHtgSsnTempWkDay_hourly += "#{nv.htg_ssn_hourly_temp[23]};"

    natVentHtgSsnTempWkEnd_hourly = "
    Schedule:Day:Hourly,
      NatVentHtgSsnTempWkEnd_#{unit_num},                 !- Name
      TEMPERATURE,                                        !- Schedule Type"

    nv.htg_ssn_hourly_weekend_temp[0..22].each do |hour|
      natVentHtgSsnTempWkEnd_hourly += "#{hour}\n,"
    end
    natVentHtgSsnTempWkEnd_hourly += "#{nv.htg_ssn_hourly_weekend_temp[23]};"

    natVentClgSsnTempWkDay_hourly = "
    Schedule:Day:Hourly,
      NatVentClgSsnTempWkDay_#{unit_num},                 !- Name
      TEMPERATURE,                                        !- Schedule Type"

    nv.clg_ssn_hourly_temp[0..22].each do |hour|
      natVentClgSsnTempWkDay_hourly += "#{hour}\n,"
    end
    natVentClgSsnTempWkDay_hourly += "#{nv.clg_ssn_hourly_temp[23]};"

    natVentClgSsnTempWkEnd_hourly = "
    Schedule:Day:Hourly,
      NatVentClgSsnTempWkEnd_#{unit_num},                 !- Name
      TEMPERATURE,                                        !- Schedule Type"

    nv.clg_ssn_hourly_weekend_temp[0..22].each do |hour|
      natVentClgSsnTempWkEnd_hourly += "#{hour}\n,"
    end
    natVentClgSsnTempWkEnd_hourly += "#{nv.clg_ssn_hourly_weekend_temp[23]};"

    natVentOvlpSsnTempWkDay_hourly = "
    Schedule:Day:Hourly,
      NatVentOvlpSsnTempWkDay_#{unit_num},                !- Name
      TEMPERATURE,                                        !- Schedule Type"

    nv.ovlp_ssn_hourly_temp[0..22].each do |hour|
      natVentOvlpSsnTempWkDay_hourly += "#{hour}\n,"
    end
    natVentOvlpSsnTempWkDay_hourly += "#{nv.ovlp_ssn_hourly_temp[23]};"

    natVentOvlpSsnTempWkEnd_hourly = "
    Schedule:Day:Hourly,
      NatVentOvlpSsnTempWkEnd_#{unit_num},                !- Name
      TEMPERATURE,                                        !- Schedule Type"
      
    nv.ovlp_ssn_hourly_weekend_temp[0..22].each do |hour|
      natVentOvlpSsnTempWkEnd_hourly += "#{hour}\n,"
    end
    natVentOvlpSsnTempWkEnd_hourly += "#{nv.ovlp_ssn_hourly_weekend_temp[23]};"

    # Parse the idf for season_type array
    heating_season_names = []
    heating_season = Array.new(12, 0.0)
    cooling_season_names = []
    cooling_season = Array.new(12, 0.0)
    (1..12).to_a.each do |i|
      heating_season_names << "#{Constants.ObjectNameHeatingSeason} weekday#{i}"
      cooling_season_names << "#{Constants.ObjectNameCoolingSeason} weekday#{i}"
    end

    sch_args = workspace.getObjectsByType("Schedule:Day:Interval".to_IddObjectType)
    heating_season_names.each_with_index do |sch_name, i|
      sch_args.each do |sch_arg|
        sch_arg_name = sch_arg.getString(0).to_s # Name
        if sch_arg_name == sch_name
          heating_season[i] = sch_arg.getString(4).get.to_f
        end
      end
    end
    cooling_season_names.each_with_index do |sch_name, i|
      sch_args.each do |sch_arg|
        sch_arg_name = sch_arg.getString(0).to_s # Name
        if sch_arg_name == sch_name
          cooling_season[i] = sch_arg.getString(4).get.to_f
        end
      end
    end
    
    nv.season_type = []
    (0...12).to_a.each do |month|
      if heating_season[month] == 1.0 and cooling_season[month] == 0.0
        nv.season_type << Constants.SeasonHeating
      elsif heating_season[month] == 0.0 and cooling_season[month] == 1.0
        nv.season_type << Constants.SeasonCooling
      elsif heating_season[month] == 1.0 and cooling_season[month] == 1.0
        nv.season_type << Constants.SeasonOverlap
      else
        nv.season_type << Constants.SeasonNone
      end
    end

    sch_year = "
    Schedule:Year,
      NatVentTemp_#{unit_num},     !- Name
      TEMPERATURE,                 !- Schedule Type"
      
    nv.season_type.each_with_index do |ssn_type, month|
      if ssn_type == Constants.SeasonHeating
        week_schedule_name = "NatVentHtgSsnTempWeek_#{unit_num}"
      elsif ssn_type == Constants.SeasonCooling
        week_schedule_name = "NatVentClgSsnTempWeek_#{unit_num}"
      else
        week_schedule_name = "NatVentOvlpSsnTempWeek_#{unit_num}"
      end
      if month == 0
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        1,                        !- Start Month
        1,                        !- Start Day
        1,                        !- End Month
        31,                       !- End Day"
      elsif month == 1
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        2,                        !- Start Month
        1,                        !- Start Day
        2,                        !- End Month
        28,                       !- End Day"
      elsif month == 2
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        3,                        !- Start Month
        1,                        !- Start Day
        3,                        !- End Month
        31,                       !- End Day"
      elsif month == 3
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        4,                        !- Start Month
        1,                        !- Start Day
        4,                        !- End Month
        30,                       !- End Day"
      elsif month == 4
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        5,                        !- Start Month
        1,                        !- Start Day
        5,                        !- End Month
        31,                       !- End Day"
      elsif month == 5
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        6,                        !- Start Month
        1,                        !- Start Day
        6,                        !- End Month
        30,                       !- End Day"
      elsif month == 6
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        7,                        !- Start Month
        1,                        !- Start Day
        7,                        !- End Month
        31,                       !- End Day"
      elsif month == 7
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        8,                        !- Start Month
        1,                        !- Start Day
        8,                        !- End Month
        31,                       !- End Day"
      elsif month == 8
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        9,                        !- Start Month
        1,                        !- Start Day
        9,                        !- End Month
        30,                       !- End Day"
      elsif month == 9
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        10,                       !- Start Month
        1,                        !- Start Day
        10,                       !- End Month
        31,                       !- End Day"
      elsif month == 10
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        11,                       !- Start Month
        1,                        !- Start Day
        11,                       !- End Month
        30,                       !- End Day"
      elsif month == 11
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        12,                       !- Start Month
        1,                        !- Start Day
        12,                       !- End Month
        31,                       !- End Day"
      end
    end

    schedules.NatVentTemp = [natVentHtgSsnTempWkDay_hourly, natVentHtgSsnTempWkEnd_hourly, natVentClgSsnTempWkDay_hourly, natVentClgSsnTempWkEnd_hourly, natVentOvlpSsnTempWkDay_hourly, natVentOvlpSsnTempWkEnd_hourly, nat_vent_clg_ssn_temp, nat_vent_htg_ssn_temp, nat_vent_ovlp_ssn_temp, sch_year]

    natventon_day_hourly = Array.new(24, 1)

    on_day = "
    Schedule:Day:Hourly,
      NatVentOn-Day_#{unit_num},                       !- Name
      FRACTION,                                        !- Schedule Type"
      
    natventon_day_hourly[0..22].each do |hour|
      on_day += "#{hour}\n,"
    end
    on_day += "#{natventon_day_hourly[23]};"

    natventoff_day_hourly = Array.new(24, 0)

    off_day = "
    Schedule:Day:Hourly,
      NatVentOff-Day_#{unit_num},                      !- Name
      FRACTION,                                        !- Schedule Type"
      
    natventoff_day_hourly[0..22].each do |hour|
      off_day += "#{hour}\n,"
    end
    off_day += "#{natventoff_day_hourly[23]};"

    days = []
    if nv.NatVentNumberWeekdays == 0 and nv.NatVentNumberWeekendDays == 0
      days << "None"
    else
      if nv.NatVentNumberWeekdays == 1
        days << "Monday"
      elsif nv.NatVentNumberWeekdays == 2
        days << "Monday"
        days << "Wednesday"
      elsif nv.NatVentNumberWeekdays == 3
        days << "Monday"
        days << "Wednesday"
        days << "Friday"
      elsif nv.NatVentNumberWeekdays == 4
        days << "Monday"
        days << "Tuesday"
        days << "Wednesday"
        days << "Friday"
      elsif nv.NatVentNumberWeekdays == 5
        days << "Monday"
        days << "Tuesday"
        days << "Wednesday"
        days << "Thursday"
        days << "Friday"
      end
      if nv.NatVentNumberWeekendDays == 1
        days << "Saturday"
      elsif nv.NatVentNumberWeekendDays == 2
        days << "Saturday"
        days << "Sunday"
      end
    end
    
    off_week = "
    Schedule:Week:Compact,
      NatVentOffSeason-Week_#{unit_num},               !- Name
      For: Weekdays,
      NatVentOff-Day_#{unit_num},
      For: CustomDay1,
      NatVentOff-Day_#{unit_num},
      For: CustomDay2,
      NatVentOff-Day_#{unit_num},
      For: AllOtherDays,
      NatVentOff-Day_#{unit_num};"

    on_week = "
    Schedule:Week:Compact,
      NatVent-Week_#{unit_num},                        !- Name"
    if not days[0] == "None"
      days.each do |day|
        on_week += "
        For: #{day},
        NatVentOn-Day_#{unit_num},"
      end
    else
      on_week += "
      For: Weekdays,
      NatVentOn-Day_#{unit_num},"
    end
    on_week += "
    For: AllOtherDays,
    NatVentOff-Day_#{unit_num};"
    
    sch_year = "
    Schedule:Year,
      NatVent_#{unit_num},      !- Name
      FRACTION,                 !- Schedule Type"
      
    (0...12).to_a.each do |month|
      if ((nv.season_type[month] == Constants.SeasonHeating and nv.NatVentHeatingSeason) or (nv.season_type[month] == Constants.SeasonCooling and nv.NatVentCoolingSeason) or (nv.season_type[month] == Constants.SeasonOverlap and nv.NatVentOverlapSeason)) and (not days[0] == "None")
        week_schedule_name = "NatVent-Week_#{unit_num}"
      else
        week_schedule_name = "NatVentOffSeason-Week_#{unit_num}"
      end
      if month == 0
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        1,                        !- Start Month
        1,                        !- Start Day
        1,                        !- End Month
        31,                       !- End Day"
      elsif month == 1
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        2,                        !- Start Month
        1,                        !- Start Day
        2,                        !- End Month
        28,                       !- End Day"
      elsif month == 2
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        3,                        !- Start Month
        1,                        !- Start Day
        3,                        !- End Month
        31,                       !- End Day"
      elsif month == 3
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        4,                        !- Start Month
        1,                        !- Start Day
        4,                        !- End Month
        30,                       !- End Day"
      elsif month == 4
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        5,                        !- Start Month
        1,                        !- Start Day
        5,                        !- End Month
        31,                       !- End Day"
      elsif month == 5
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        6,                        !- Start Month
        1,                        !- Start Day
        6,                        !- End Month
        30,                       !- End Day"
      elsif month == 6
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        7,                        !- Start Month
        1,                        !- Start Day
        7,                        !- End Month
        31,                       !- End Day"
      elsif month == 7
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        8,                        !- Start Month
        1,                        !- Start Day
        8,                        !- End Month
        31,                       !- End Day"
      elsif month == 8
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        9,                        !- Start Month
        1,                        !- Start Day
        9,                        !- End Month
        30,                       !- End Day"
      elsif month == 9
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        10,                       !- Start Month
        1,                        !- Start Day
        10,                       !- End Month
        31,                       !- End Day"
      elsif month == 10
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        11,                       !- Start Month
        1,                        !- Start Day
        11,                       !- End Month
        30,                       !- End Day"
      elsif month == 11
        sch_year += "
        #{week_schedule_name},    !- Week Schedule Name
        12,                       !- Start Month
        1,                        !- Start Day
        12,                       !- End Month
        31,                       !- End Day"
      end
    end

    schedules.NatVentAvailability = [on_day, off_day, off_week, on_week, sch_year]

    # Explanation for FRAC-VENT-AREA equation:
    # From DOE22 Vol2-Dictionary: For VENT-METHOD=S-G, this is 0.6 times
    # the open window area divided by the floor area.
    # According to 2010 BA Benchmark, 33% of the windows on any facade will
    # be open at any given time and can only be opened to 20% of their area.

    nv.area = 0.6 * geometry.window_area * nv.NatVentFractionWindowsOpen * nv.NatVentFractionWindowAreaOpen # ft^2 (For S-G, this is 0.6*(open window area))
    nv.max_rate = 20.0 # Air Changes per hour
    nv.max_flow_rate = nv.max_rate * living_space.volume / OpenStudio::convert(1.0,"hr","min").get
    nv_neutral_level = 0.5
    nv.hor_vent_frac = 0.0
    f_s_nv = 2.0 / 3.0 * (1.0 + nv.hor_vent_frac / 2.0) * (2.0 * nv_neutral_level * (1 - nv_neutral_level)) ** 0.5 / (nv_neutral_level ** 0.5 + (1 - nv_neutral_level) ** 0.5)
    f_w_nv = wind_speed.shielding_coef * (1 - nv.hor_vent_frac) ** (1.0 / 3.0) * living_space.f_t_SG
    nv.C_s = f_s_nv ** 2.0 * Constants.g * living_space.height / (infiltration.assumed_inside_temp + 460.0)
    nv.C_w = f_w_nv ** 2.0

    return nv, schedules

  end  
  
  def _processWindSpeedCorrection(wind_speed, terrainType)
    # Wind speed correction
    wind_speed.height = 32.8 # ft (Standard weather station height)
    
    # Open, Unrestricted at Weather Station
    wind_speed.terrain_multiplier = 1.0 # Used for DOE-2's correlation
    wind_speed.terrain_exponent = 0.15 # Used for DOE-2's correlation
    wind_speed.ashrae_terrain_thickness = 270
    wind_speed.ashrae_terrain_exponent = 0.14
    
    if terrainType == Constants.TerrainOcean
      wind_speed.site_terrain_multiplier = 1.30 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.10 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 210 # Ocean, Bayou flat country
      wind_speed.ashrae_site_terrain_exponent = 0.10 # Ocean, Bayou flat country
    elsif terrainType == Constants.TerrainPlains
      wind_speed.site_terrain_multiplier = 1.00 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.15 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 270 # Flat, open country
      wind_speed.ashrae_site_terrain_exponent = 0.14 # Flat, open country
    elsif terrainType == Constants.TerrainRural
      wind_speed.site_terrain_multiplier = 0.85 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.20 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 270 # Flat, open country
      wind_speed.ashrae_site_terrain_exponent = 0.14 # Flat, open country
    elsif terrainType == Constants.TerrainSuburban
      wind_speed.site_terrain_multiplier = 0.67 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.25 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 370 # Rough, wooded country, suburbs
      wind_speed.ashrae_site_terrain_exponent = 0.22 # Rough, wooded country, suburbs
    elsif terrainType == Constants.TerrainCity
      wind_speed.site_terrain_multiplier = 0.47 # Used for DOE-2's correlation
      wind_speed.site_terrain_exponent = 0.35 # Used for DOE-2's correlation
      wind_speed.ashrae_site_terrain_thickness = 460 # Towns, city outskirs, center of large cities
      wind_speed.ashrae_site_terrain_exponent = 0.33 # Towns, city outskirs, center of large cities 
    end
    
    return wind_speed
    
  end
    
  def _processWindSpeedCorrectionForUnit(wind_speed, infiltration, neighbors_min_nonzero_offset, geometry)
    
    # Local Shielding
    if infiltration.InfiltrationShelterCoefficient == Constants.Auto
      if neighbors_min_nonzero_offset == 0
        # Typical shelter for isolated rural house
        wind_speed.S_wo = 0.90
      elsif neighbors_min_nonzero_offset > geometry.building_height
        # Typical shelter caused by other building across the street
        wind_speed.S_wo = 0.70
      else
        # Typical shelter for urban buildings where sheltering obstacles
        # are less than one building height away.
        # Recommended by C.Christensen.
        wind_speed.S_wo = 0.50
      end
    else
      wind_speed.S_wo = infiltration.InfiltrationShelterCoefficient.to_f
    end

    # S-G Shielding Coefficients are roughly 1/3 of AIM2 Shelter Coefficients
    wind_speed.shielding_coef = wind_speed.S_wo / 3.0
    
    return wind_speed

  end  
  
  def calc_infiltration_w_factor(weather)
    # Returns a w factor for infiltration calculations; see ticket #852 for derivation.
    hdd65f = weather.data.HDD65F
    ws = weather.data.AnnualAvgWindspeed
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

  def get_infiltration_ACH_from_SLA(sla, numStories, weather)
    # Returns the infiltration annual average ACH given a SLA.
    w = calc_infiltration_w_factor(weather)

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
  
end #end the measure

#this allows the measure to be use by the application
ProcessAirflow.new.registerWithApplication