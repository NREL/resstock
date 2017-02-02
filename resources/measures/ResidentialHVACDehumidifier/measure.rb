# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/hvac"
require "#{File.dirname(__FILE__)}/resources/constants"

# start the measure
class ProcessDehumidifier < OpenStudio::Ruleset::ModelUserScript

  class Curves
    def initialize
    end
    attr_accessor(:Zone_Water_Remove_Cap_Ft_DB_RH_coefficients, :Zone_Energy_Factor_Ft_DB_RH_coefficients, :Zone_DXDH_PLF_F_PLR_coefficients)
  end

  # human readable name
  def name
    return "Set Residential Dehumidifier"
  end

  # human readable description
  def description
    return "This measure removes any existing dehumidifiers from the building and adds a dehumidifier. For multifamily buildings, the dehumidifier can be set for all units of the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any HVAC dehumidifier DXs are removed from any existing zones. An HVAC dehumidifier DX is added to the living zone, as well as to the finished basement if it exists. A humidistat is also added to the zone, with the relative humidity setpoint input by the user."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

   	#Make a string argument for dehumidifier energy factor
    energy_factor = OpenStudio::Ruleset::OSArgument::makeStringArgument("energy_factor", true)
    energy_factor.setDisplayName("Energy Factor")
    energy_factor.setDescription("The energy efficiency of dehumidifiers is measured by its energy factor, in liters of water removed per kilowatt-hour (kWh) of energy consumed or L/kWh.")
    energy_factor.setUnits("L/kWh")
    energy_factor.setDefaultValue(Constants.Auto)
    args << energy_factor
    
   	#Make a string argument for dehumidifier water removal rate
    water_removal_rate = OpenStudio::Ruleset::OSArgument::makeStringArgument("water_removal_rate", true)
    water_removal_rate.setDisplayName("Water Removal Rate")
    water_removal_rate.setDescription("Dehumidifier rated water removal rate measured in pints per day at an inlet condition of 80 degrees F DB/60%RH.")
    water_removal_rate.setUnits("Pints/day")
    water_removal_rate.setDefaultValue(Constants.Auto)
    args << water_removal_rate
    
   	#Make a string argument for dehumidifier air flow rate
    air_flow_rate = OpenStudio::Ruleset::OSArgument::makeStringArgument("air_flow_rate", true)
    air_flow_rate.setDisplayName("Air Flow Rate")
    air_flow_rate.setDescription("The dehumidifier rated air flow rate in CFM. If 'auto' is entered, the air flow will be determined using the rated water removal rate.")
    air_flow_rate.setUnits("cfm")
    air_flow_rate.setDefaultValue(Constants.Auto)
    args << air_flow_rate
    
    #make a string argument for dehumidifier configuration
    # config_display_names = OpenStudio::StringVector.new
    # config_display_names << Constants.Standalone
    # config_display_names << Constants.Ducted
    # config = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("config", config_display_names, true)
    # config.setDisplayName("Configuration")
    # config.setDescription("The configuration of the dehumidifier. Only affects costing. If 'auto' is selected, dehumidifiers larger than 70 pints/day will be ducted.")
    # config.setDefaultValue(Constants.Standalone)
    # args << config
    
   	#Make a string argument for humidity setpoint
    humidity_setpoint = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("humidity_setpoint", true)
    humidity_setpoint.setDisplayName("Annual Relative Humidity Setpoint")
    humidity_setpoint.setDescription("The annual relative humidity setpoint.")
    humidity_setpoint.setUnits("frac")
    humidity_setpoint.setDefaultValue(Constants.DefaultHumiditySetpoint)
    args << humidity_setpoint    
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    energy_factor = runner.getStringArgumentValue("energy_factor",user_arguments)
    water_removal_rate = runner.getStringArgumentValue("water_removal_rate",user_arguments)
    air_flow_rate = runner.getStringArgumentValue("air_flow_rate",user_arguments)
    # config = runner.getStringArgumentValue("config",user_arguments)
    humidity_setpoint = runner.getDoubleArgumentValue("humidity_setpoint",user_arguments)
    
    # error checking
    if humidity_setpoint < 0 or humidity_setpoint > 1
      runner.registerError("Invalid humidity setpoint value entered.")
      return false
    end
    
    model.getScheduleConstants.each do |sch|
      next unless sch.name.to_s == Constants.ObjectNameRelativeHumiditySetpoint
      sch.remove
    end
    
    avg_rh_setpoint = humidity_setpoint * 100.0 # (EnergyPlus uses 60 for 60% RH)
    relative_humidity_setpoint_sch = OpenStudio::Model::ScheduleConstant.new(model)
    relative_humidity_setpoint_sch.setName(Constants.ObjectNameRelativeHumiditySetpoint)
    relative_humidity_setpoint_sch.setValue(avg_rh_setpoint)
    
    # Use a minimum capacity of 20 pints/day
    water_removal_rate_auto = UnitConversion.pint2liter(25.0) # TODO: calculate water_removal_rate_auto using sizing.rb
    water_removal_rate_auto = [water_removal_rate_auto, UnitConversion.pint2liter(20.0)].max
    
    # Dehumidifier sizing
    if water_removal_rate == Constants.Auto
      water_removal_rate_rated = water_removal_rate_auto
    else
      water_removal_rate_rated = UnitConversion.pint2liter(water_removal_rate.to_f)
    end

    # error checking
    if water_removal_rate_rated <= 0
      runner.registerError("Invalid water removal rate value entered.")
      return false
    end    
    
    # Select an Energy Factor based on ENERGY STAR requirements
    if energy_factor == Constants.Auto
      if UnitConversion.liter2pint(water_removal_rate_rated) <= 25.0
        energy_factor = 1.2
      elsif UnitConversion.liter2pint(water_removal_rate_rated) <= 35.0
        energy_factor = 1.4
      elsif UnitConversion.liter2pint(water_removal_rate_rated) <= 45.0
        energy_factor = 1.5
      elsif UnitConversion.liter2pint(water_removal_rate_rated) <= 54.0
        energy_factor = 1.6
      elsif UnitConversion.liter2pint(water_removal_rate_rated) <= 75.0
        energy_factor = 1.8
      else
        energy_factor = 2.5
      end
    else
      energy_factor = energy_factor.to_f
    end
  
    # error checking
    if energy_factor < 0
      runner.registerError("Invalid energy factor value entered.")
      return false
    end
    
    if air_flow_rate == Constants.Auto
      # Calculate the dehumidifer air flow rate by assuming 2.75 cfm/pint/day (based on experimental test data)
      air_flow_rate = 2.75 * water_removal_rate_rated * UnitConversion.liter2pint(1.0) * OpenStudio::convert(1.0,"cfm","m^3/s").get
    else
      air_flow_rate = OpenStudio::convert(air_flow_rate.to_f,"cfm","m^3/s").get
    end    

    # Dehumidifier coefficients
    # Generic model coefficients from Winkler, Christensen, and Tomerlin (2011)
    curves = Curves.new
    curves.Zone_Water_Remove_Cap_Ft_DB_RH_coefficients = [-1.162525707, 0.02271469, -0.000113208, 0.021110538, -0.0000693034, 0.000378843]
    curves.Zone_Energy_Factor_Ft_DB_RH_coefficients = [-1.902154518, 0.063466565, -0.000622839, 0.039540407, -0.000125637, -0.000176722]
    curves.Zone_DXDH_PLF_F_PLR_coefficients = [0.90, 0.10, 0.0]
    
    water_removal_curve = OpenStudio::Model::CurveBiquadratic.new(model)
    water_removal_curve.setName("DXDH-WaterRemove-Cap-fT")
    water_removal_curve.setCoefficient1Constant(curves.Zone_Water_Remove_Cap_Ft_DB_RH_coefficients[0])
    water_removal_curve.setCoefficient2x(curves.Zone_Water_Remove_Cap_Ft_DB_RH_coefficients[1])
    water_removal_curve.setCoefficient3xPOW2(curves.Zone_Water_Remove_Cap_Ft_DB_RH_coefficients[2])
    water_removal_curve.setCoefficient4y(curves.Zone_Water_Remove_Cap_Ft_DB_RH_coefficients[3])
    water_removal_curve.setCoefficient5yPOW2(curves.Zone_Water_Remove_Cap_Ft_DB_RH_coefficients[4])
    water_removal_curve.setCoefficient6xTIMESY(curves.Zone_Water_Remove_Cap_Ft_DB_RH_coefficients[5])
    water_removal_curve.setMinimumValueofx(-100)
    water_removal_curve.setMaximumValueofx(100)
    water_removal_curve.setMinimumValueofy(-100)
    water_removal_curve.setMaximumValueofy(100)

    energy_factor_curve = OpenStudio::Model::CurveBiquadratic.new(model)
    energy_factor_curve.setName("DXDH-EnergyFactor-fT")
    energy_factor_curve.setCoefficient1Constant(curves.Zone_Energy_Factor_Ft_DB_RH_coefficients[0])
    energy_factor_curve.setCoefficient2x(curves.Zone_Energy_Factor_Ft_DB_RH_coefficients[1])
    energy_factor_curve.setCoefficient3xPOW2(curves.Zone_Energy_Factor_Ft_DB_RH_coefficients[2])
    energy_factor_curve.setCoefficient4y(curves.Zone_Energy_Factor_Ft_DB_RH_coefficients[3])
    energy_factor_curve.setCoefficient5yPOW2(curves.Zone_Energy_Factor_Ft_DB_RH_coefficients[4])
    energy_factor_curve.setCoefficient6xTIMESY(curves.Zone_Energy_Factor_Ft_DB_RH_coefficients[5])
    energy_factor_curve.setMinimumValueofx(-100)
    energy_factor_curve.setMaximumValueofx(100)
    energy_factor_curve.setMinimumValueofy(-100)
    energy_factor_curve.setMaximumValueofy(100)

    part_load_frac_curve = OpenStudio::Model::CurveQuadratic.new(model)
    part_load_frac_curve.setName("DXDH-PLF-fPLR")
    part_load_frac_curve.setCoefficient1Constant(curves.Zone_DXDH_PLF_F_PLR_coefficients[0])
    part_load_frac_curve.setCoefficient2x(curves.Zone_DXDH_PLF_F_PLR_coefficients[1])
    part_load_frac_curve.setCoefficient3xPOW2(curves.Zone_DXDH_PLF_F_PLR_coefficients[2])
    part_load_frac_curve.setMinimumValueofx(0)
    part_load_frac_curve.setMaximumValueofx(1)
    part_load_frac_curve.setMinimumCurveOutput(0.7)
    part_load_frac_curve.setMaximumCurveOutput(1)
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end
    
    units.each do |unit|
    
      obj_name = Constants.ObjectNameDehumidifier(unit.name.to_s)    
    
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      
      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|

        # Remove existing dehumidifier
        model.getZoneHVACDehumidifierDXs.each do |dehumidifier|
          next unless control_zone.handle.to_s == dehumidifier.thermalZone.get.handle.to_s
          runner.registerInfo("Removed '#{dehumidifier.name}' from #{control_zone.name}.")
          dehumidifier.remove
        end
      
        humidistat = control_zone.zoneControlHumidistat
        if humidistat.is_initialized
          humidistat.get.remove
        end
        humidistat = OpenStudio::Model::ZoneControlHumidistat.new(model)
        humidistat.setName(obj_name + " #{control_zone.name} humidistat")
        humidistat.setHumidifyingRelativeHumiditySetpointSchedule(relative_humidity_setpoint_sch)
        humidistat.setDehumidifyingRelativeHumiditySetpointSchedule(relative_humidity_setpoint_sch)
        control_zone.setZoneControlHumidistat(humidistat)  
      
        zone_hvac = OpenStudio::Model::ZoneHVACDehumidifierDX.new(model, water_removal_curve, energy_factor_curve, part_load_frac_curve)
        zone_hvac.setName(obj_name + " #{control_zone.name} dx")
        zone_hvac.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
        zone_hvac.setRatedWaterRemoval(water_removal_rate_rated)
        zone_hvac.setRatedEnergyFactor(energy_factor)
        zone_hvac.setRatedAirFlowRate(air_flow_rate)
        zone_hvac.setMinimumDryBulbTemperatureforDehumidifierOperation(10)
        zone_hvac.setMaximumDryBulbTemperatureforDehumidifierOperation(40)
        
        zone_hvac.addToThermalZone(control_zone)
        runner.registerInfo("Added '#{zone_hvac.name}' to '#{control_zone.name}' of #{unit.name}")
        
        # slave_zones.each do |slave_zone|
        
          # # Remove existing dehumidifier
          # model.getZoneHVACDehumidifierDXs.each do |dehumidifier|
            # next unless slave_zone.handle.to_s == dehumidifier.thermalZone.get.handle.to_s
            # runner.registerInfo("Removed '#{dehumidifier.name}' from #{slave_zone.name}.")
            # dehumidifier.remove
          # end
          
          # humidistat = slave_zone.zoneControlHumidistat
          # if humidistat.is_initialized
            # humidistat.get.remove
          # end
          # humidistat = OpenStudio::Model::ZoneControlHumidistat.new(model)
          # humidistat.setName(obj_name + " #{slave_zone.name} humidistat")
          # humidistat.setHumidifyingRelativeHumiditySetpointSchedule(relative_humidity_setpoint_sch)
          # humidistat.setDehumidifyingRelativeHumiditySetpointSchedule(relative_humidity_setpoint_sch)
          # slave_zone.setZoneControlHumidistat(humidistat)
        
          # zone_hvac = OpenStudio::Model::ZoneHVACDehumidifierDX.new(model, water_removal_curve, energy_factor_curve, part_load_frac_curve)
          # zone_hvac.setName(obj_name + " #{slave_zone.name} dx")
          # zone_hvac.setAvailabilitySchedule(model.alwaysOnDiscreteSchedule)
          # zone_hvac.setRatedWaterRemoval(water_removal_rate_rated)
          # zone_hvac.setRatedEnergyFactor(energy_factor)
          # zone_hvac.setRatedAirFlowRate(air_flow_rate)
          # zone_hvac.setMinimumDryBulbTemperatureforDehumidifierOperation(10)
          # zone_hvac.setMaximumDryBulbTemperatureforDehumidifierOperation(40)
          
          # zone_hvac.addToThermalZone(slave_zone)
          # runner.registerInfo("Added '#{zone_hvac.name}' to '#{slave_zone.name}' of #{unit.name}")
        
        # end
      
      end
    
    end
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessDehumidifier.new.registerWithApplication
