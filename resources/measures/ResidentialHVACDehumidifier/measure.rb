# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/hvac"
require "#{File.dirname(__FILE__)}/resources/constants"

# start the measure
class ProcessDehumidifier < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Dehumidifier"
  end

  # human readable description
  def description
    return "This measure removes any existing dehumidifiers from the building and adds a dehumidifier. For multifamily buildings, the dehumidifier can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any HVAC dehumidifier DXs are removed from any existing zones. An HVAC dehumidifier DX is added to the living zone, as well as to the finished basement if it exists. A humidistat is also added to the zone, with the relative humidity setpoint input by the user."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #Make a string argument for dehumidifier energy factor
    energy_factor = OpenStudio::Measure::OSArgument::makeStringArgument("energy_factor", true)
    energy_factor.setDisplayName("Energy Factor")
    energy_factor.setDescription("The energy efficiency of dehumidifiers is measured by its energy factor, in liters of water removed per kilowatt-hour (kWh) of energy consumed or L/kWh.")
    energy_factor.setUnits("L/kWh")
    energy_factor.setDefaultValue(Constants.Auto)
    args << energy_factor
    
    #Make a string argument for dehumidifier water removal rate
    water_removal_rate = OpenStudio::Measure::OSArgument::makeStringArgument("water_removal_rate", true)
    water_removal_rate.setDisplayName("Water Removal Rate")
    water_removal_rate.setDescription("Dehumidifier rated water removal rate measured in pints per day at an inlet condition of 80 degrees F DB/60%RH.")
    water_removal_rate.setUnits("Pints/day")
    water_removal_rate.setDefaultValue(Constants.Auto)
    args << water_removal_rate
    
    #Make a string argument for dehumidifier air flow rate
    air_flow_rate = OpenStudio::Measure::OSArgument::makeStringArgument("air_flow_rate", true)
    air_flow_rate.setDisplayName("Air Flow Rate")
    air_flow_rate.setDescription("The dehumidifier rated air flow rate in CFM. If 'auto' is entered, the air flow will be determined using the rated water removal rate.")
    air_flow_rate.setUnits("cfm")
    air_flow_rate.setDefaultValue(Constants.Auto)
    args << air_flow_rate
    
    #Make a string argument for humidity setpoint
    humidity_setpoint = OpenStudio::Measure::OSArgument::makeDoubleArgument("humidity_setpoint", true)
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
    
    # error checking
    if water_removal_rate != Constants.Auto and water_removal_rate.to_f <= 0
      runner.registerError("Invalid water removal rate value entered.")
      return false
    end    
    if energy_factor != Constants.Auto and energy_factor.to_f < 0
      runner.registerError("Invalid energy factor value entered.")
      return false
    end
    if air_flow_rate != Constants.Auto and air_flow_rate.to_f < 0
      runner.registerError("Invalid air flow rate value entered.")
      return false
    end

    # Dehumidifier coefficients
    # Generic model coefficients from Winkler, Christensen, and Tomerlin (2011)
    water_removal_curve = HVAC.create_curve_biquadratic(model, [-1.162525707, 0.02271469, -0.000113208, 0.021110538, -0.0000693034, 0.000378843], "DXDH-WaterRemove-Cap-fT", -100, 100, -100, 100)
    energy_factor_curve = HVAC.create_curve_biquadratic(model, [-1.902154518, 0.063466565, -0.000622839, 0.039540407, -0.000125637, -0.000176722], "DXDH-EnergyFactor-fT", -100, 100, -100, 100)
    part_load_frac_curve = HVAC.create_curve_quadratic(model, [0.90, 0.10, 0.0], "DXDH-PLF-fPLR", 0, 1, 0.7, 1)
    
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
        if water_removal_rate != Constants.Auto
          zone_hvac.setRatedWaterRemoval(UnitConversions.convert(water_removal_rate.to_f,"pint","L"))
        else
          zone_hvac.setRatedWaterRemoval(Constants.small) # Autosize flag for HVACSizing measure
        end
        if energy_factor != Constants.Auto
          zone_hvac.setRatedEnergyFactor(energy_factor.to_f)
        else
          zone_hvac.setRatedEnergyFactor(Constants.small) # Autosize flag for HVACSizing measure
        end
        if air_flow_rate != Constants.Auto
          zone_hvac.setRatedAirFlowRate(UnitConversions.convert(air_flow_rate.to_f,"cfm","m^3/s"))
        else
          zone_hvac.setRatedAirFlowRate(Constants.small) # Autosize flag for HVACSizing measure
        end
        zone_hvac.setMinimumDryBulbTemperatureforDehumidifierOperation(10)
        zone_hvac.setMaximumDryBulbTemperatureforDehumidifierOperation(40)
        
        zone_hvac.addToThermalZone(control_zone)
        runner.registerInfo("Added '#{zone_hvac.name}' to '#{control_zone.name}' of #{unit.name}")
        
        HVAC.prioritize_zone_hvac(model, runner, control_zone)
              
      end
    
    end
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessDehumidifier.new.registerWithApplication
