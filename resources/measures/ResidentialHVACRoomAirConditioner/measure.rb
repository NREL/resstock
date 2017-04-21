# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"

# start the measure
class ProcessRoomAirConditioner < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Room Air Conditioner"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC cooling components from the building and adds a room air conditioner. For multifamily buildings, the room air conditioner can be set for all units of the building."
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any cooling components are removed from any existing air loops or zones. Any existing air loops are also removed. An HVAC packaged terminal air conditioner is added to the living zone."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make a double argument for room air eer
    eer = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer", true)
    eer.setDisplayName("EER")
    eer.setUnits("Btu/W-h")
    eer.setDescription("This is a measure of the instantaneous energy efficiency of the cooling equipment.")
    eer.setDefaultValue(8.5)
    args << eer         
    
    #make a double argument for room air shr
    shr = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr", true)
    shr.setDisplayName("Rated SHR")
    shr.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    shr.setDefaultValue(0.65)
    args << shr

    #make a double argument for room air airflow
    airflow = OpenStudio::Measure::OSArgument::makeDoubleArgument("airflow_rate", true)
    airflow.setDisplayName("Airflow")
    airflow.setUnits("cfm/ton")
    airflow.setDefaultValue(350.0)
    args << airflow
    
    #make a choice argument for room air cooling output capacity
    cap_display_names = OpenStudio::StringVector.new
    cap_display_names << Constants.SizingAuto
    (0.5..10.0).step(0.5) do |tons|
      cap_display_names << tons.to_s
    end
    output_capacity = OpenStudio::Measure::OSArgument::makeChoiceArgument("capacity", cap_display_names, true)
    output_capacity.setDisplayName("Cooling Capacity")
    output_capacity.setDescription("The output cooling capacity of the air conditioner.")
    output_capacity.setUnits("tons")
    output_capacity.setDefaultValue(Constants.SizingAuto)
    args << output_capacity  

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    roomaceer = runner.getDoubleArgumentValue("eer",user_arguments)
    sHR_Rated = runner.getDoubleArgumentValue("shr",user_arguments)
    coolingCFMs = [runner.getDoubleArgumentValue("airflow_rate",user_arguments)]
    acOutputCapacity = runner.getStringArgumentValue("capacity",user_arguments)
    unless acOutputCapacity == Constants.SizingAuto
      acOutputCapacity = OpenStudio::convert(acOutputCapacity.to_f,"ton","Btu/h").get
    end     
    
    # Performance curves
    # From Frigidaire 10.7 EER unit in Winkler et. al. Lab Testing of Window ACs (2013)
    # NOTE: These coefficients are in SI UNITS
    cOOL_CAP_FT_SPEC = [0.6405, 0.01568, 0.0004531, 0.001615, -0.0001825, 0.00006614]
    cOOL_EIR_FT_SPEC = [2.287, -0.1732, 0.004745, 0.01662, 0.000484, -0.001306]
    cOOL_CAP_FFLOW_SPEC = [0.887, 0.1128, 0]
    cOOL_EIR_FFLOW_SPEC = [1.763, -0.6081, 0]
    cOOL_PLF_FPLR = [0.78, 0.22, 0]
    cFM_TON_Rated = [312]    # medium speed

    # _processCurvesRoomAirConditioner    
    
    roomac_cap_ft_curve = HVAC.create_curve_biquadratic(model, cOOL_CAP_FT_SPEC, "RoomAC-Cap-fT", 0, 100, 0, 100)
    roomac_cap_fff_curve = HVAC.create_curve_quadratic(model, cOOL_CAP_FFLOW_SPEC, "RoomAC-Cap-fFF", 0, 2, 0, 2)
    roomac_eir_ft_curve = HVAC.create_curve_biquadratic(model, cOOL_EIR_FT_SPEC, "RoomAC-EIR-fT", 0, 100, 0, 100)
    roomcac_eir_fff_curve = HVAC.create_curve_quadratic(model, cOOL_EIR_FFLOW_SPEC, "RoomAC-EIR-fFF", 0, 2, 0, 2)
    roomac_plf_fplr_curve = HVAC.create_curve_quadratic(model, cOOL_PLF_FPLR, "RoomAC-PLF-fPLR", 0, 1, 0, 1)
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    units.each do |unit|
      
      obj_name = Constants.ObjectNameRoomAirConditioner(unit.name.to_s)
      
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)

      control_slave_zones_hash = HVAC.get_control_and_slave_zones(thermal_zones)
      control_slave_zones_hash.each do |control_zone, slave_zones|
    
        next unless Geometry.zone_is_above_grade(control_zone)

        # Remove existing equipment
        HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameRoomAirConditioner, control_zone)    
      
        # _processSystemRoomAC
      
        clg_coil = OpenStudio::Model::CoilCoolingDXSingleSpeed.new(model, model.alwaysOnDiscreteSchedule, roomac_cap_ft_curve, roomac_cap_fff_curve, roomac_eir_ft_curve, roomcac_eir_fff_curve, roomac_plf_fplr_curve)
        clg_coil.setName(obj_name + " cooling coil")
        if acOutputCapacity != Constants.SizingAuto
          clg_coil.setRatedTotalCoolingCapacity(OpenStudio::convert(acOutputCapacity,"Btu/h","W").get) # Used by HVACSizing measure
        end
        clg_coil.setRatedSensibleHeatRatio(sHR_Rated)
        clg_coil.setRatedCOP(OpenStudio::OptionalDouble.new(OpenStudio::convert(roomaceer, "Btu/h", "W").get))
        clg_coil.setRatedEvaporatorFanPowerPerVolumeFlowRate(OpenStudio::OptionalDouble.new(773.3))
        clg_coil.setEvaporativeCondenserEffectiveness(OpenStudio::OptionalDouble.new(0.9))
        clg_coil.setMaximumOutdoorDryBulbTemperatureForCrankcaseHeaterOperation(OpenStudio::OptionalDouble.new(10))
        clg_coil.setBasinHeaterSetpointTemperature(OpenStudio::OptionalDouble.new(2))
        
        fan = OpenStudio::Model::FanOnOff.new(model, model.alwaysOnDiscreteSchedule)
        fan.setName(obj_name + " supply fan")
        fan.setEndUseSubcategory(Constants.EndUseHVACFan)
        fan.setFanEfficiency(1)
        fan.setPressureRise(0)
        fan.setMotorEfficiency(1)
        fan.setMotorInAirstreamFraction(0)
        
        htg_coil = OpenStudio::Model::CoilHeatingElectric.new(model, model.alwaysOffDiscreteSchedule())
        htg_coil.setName(obj_name + " always off heating coil")
        
        ptac = OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner.new(model, model.alwaysOnDiscreteSchedule, fan, htg_coil, clg_coil)
        ptac.setName(obj_name + " zone ptac")
        ptac.setSupplyAirFanOperatingModeSchedule(model.alwaysOffDiscreteSchedule)
        ptac.addToThermalZone(control_zone)
        runner.registerInfo("Added '#{ptac.name}' to '#{control_zone.name}' of #{unit.name}")
              
        HVAC.prioritize_zone_hvac(model, runner, control_zone).reverse.each do |object|
          control_zone.setCoolingPriority(object, 1)
          control_zone.setHeatingPriority(object, 1)
        end
      
        slave_zones.each do |slave_zone|

          # Remove existing equipment
          HVAC.remove_existing_hvac_equipment(model, runner, Constants.ObjectNameRoomAirConditioner, slave_zone)

          HVAC.prioritize_zone_hvac(model, runner, slave_zone).reverse.each do |object|
            slave_zone.setCoolingPriority(object, 1)
            slave_zone.setHeatingPriority(object, 1)
          end
          
        end # slave_zone
      
      end # control_zone
      
      # Store info for HVAC Sizing measure
      unit.setFeature(Constants.SizingInfoHVACCoolingCFMs, coolingCFMs.join(","))
      unit.setFeature(Constants.SizingInfoHVACRatedCFMperTonCooling, cFM_TON_Rated.join(","))
      
    end # unit
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessRoomAirConditioner.new.registerWithApplication
