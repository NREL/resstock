# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

require_relative "../HPXMLtoOpenStudio/resources/constants"
require_relative "../HPXMLtoOpenStudio/resources/geometry"
require_relative "../HPXMLtoOpenStudio/resources/hvac"

# start the measure
class ProcessTwoSpeedCentralAirConditioner < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Residential Two-Speed Central Air Conditioner"
  end

  def description
    return "This measure removes any existing HVAC cooling components from the building and adds a two-speed central air conditioner along with an on/off supply fan to a unitary air loop. For multifamily buildings, the two-speed central air conditioner can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  def modeler_description
    return "Any cooling components are removed from any existing air loops or zones. Any existing air loops are also removed. A cooling DX coil and an on/off supply fan are added to a unitary air loop. The unitary air loop is added to the supply inlet node of the air loop. This air loop is added to a branch for the living zone. A diffuser is added to the branch for the living zone as well as for the finished basement if it exists."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a double argument for central ac cooling rated seer
    seer = OpenStudio::Measure::OSArgument::makeDoubleArgument("seer", true)
    seer.setDisplayName("Rated SEER")
    seer.setUnits("Btu/W-h")
    seer.setDescription("Seasonal Energy Efficiency Ratio (SEER) is a measure of equipment energy efficiency over the cooling season.")
    seer.setDefaultValue(16.0)
    args << seer

    # make a double argument for central ac eer
    eer = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer", true)
    eer.setDisplayName("EER")
    eer.setUnits("kBtu/kWh")
    eer.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB).")
    eer.setDefaultValue(13.5)
    args << eer

    # make a double argument for central ac eer 2
    eer2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer2", true)
    eer2.setDisplayName("EER 2")
    eer2.setUnits("kBtu/kWh")
    eer2.setDescription("EER (net) from the A test (95 ODB/80 EDB/67 EWB) for the second speed.")
    eer2.setDefaultValue(12.4)
    args << eer2

    # make a double argument for central ac rated shr
    shr = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr", true)
    shr.setDisplayName("Rated SHR")
    shr.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity.")
    shr.setDefaultValue(0.71)
    args << shr

    # make a double argument for central ac rated shr 2
    shr2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("shr2", true)
    shr2.setDisplayName("Rated SHR 2")
    shr2.setDescription("The sensible heat ratio (ratio of the sensible portion of the load to the total load) at the nominal rated capacity for the second speed.")
    shr2.setDefaultValue(0.73)
    args << shr2

    # make a double argument for central ac capacity ratio
    capacity_ratio = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio", true)
    capacity_ratio.setDisplayName("Capacity Ratio")
    capacity_ratio.setDescription("Capacity divided by rated capacity.")
    capacity_ratio.setDefaultValue(0.72)
    args << capacity_ratio

    # make a double argument for central ac capacity ratio 2
    capacity_ratio2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("capacity_ratio2", true)
    capacity_ratio2.setDisplayName("Capacity Ratio 2")
    capacity_ratio2.setDescription("Capacity divided by rated capacity for the second speed.")
    capacity_ratio2.setDefaultValue(1.0)
    args << capacity_ratio2

    # make a double argument for central ac fan speed ratio
    fan_speed_ratio = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio", true)
    fan_speed_ratio.setDisplayName("Fan Speed Ratio")
    fan_speed_ratio.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0.")
    fan_speed_ratio.setDefaultValue(0.86)
    args << fan_speed_ratio

    # make a double argument for central ac fan speed ratio 2
    fan_speed_ratio2 = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_speed_ratio2", true)
    fan_speed_ratio2.setDisplayName("Fan Speed Ratio 2")
    fan_speed_ratio2.setDescription("Fan speed divided by fan speed at the compressor speed for which Capacity Ratio = 1.0 for the second speed.")
    fan_speed_ratio2.setDefaultValue(1.0)
    args << fan_speed_ratio2

    # make a double argument for central ac rated supply fan power
    fan_power_rated = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_rated", true)
    fan_power_rated.setDisplayName("Rated Supply Fan Power")
    fan_power_rated.setUnits("W/cfm")
    fan_power_rated.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan under conditions prescribed by AHRI Standard 210/240 for SEER testing.")
    fan_power_rated.setDefaultValue(0.14)
    args << fan_power_rated

    # make a double argument for central ac installed supply fan power
    fan_power_installed = OpenStudio::Measure::OSArgument::makeDoubleArgument("fan_power_installed", true)
    fan_power_installed.setDisplayName("Installed Supply Fan Power")
    fan_power_installed.setUnits("W/cfm")
    fan_power_installed.setDescription("Fan power (in W) per delivered airflow rate (in cfm) of the outdoor fan for the maximum fan speed under actual operating conditions.")
    fan_power_installed.setDefaultValue(0.3)
    args << fan_power_installed

    # make a double argument for central ac crankcase
    crankcase_capacity = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_capacity", true)
    crankcase_capacity.setDisplayName("Crankcase")
    crankcase_capacity.setUnits("kW")
    crankcase_capacity.setDescription("Capacity of the crankcase heater for the compressor.")
    crankcase_capacity.setDefaultValue(0.0)
    args << crankcase_capacity

    # make a double argument for central ac crankcase max t
    crankcase_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument("crankcase_temp", true)
    crankcase_temp.setDisplayName("Crankcase Max Temp")
    crankcase_temp.setUnits("degrees F")
    crankcase_temp.setDescription("Outdoor dry-bulb temperature above which compressor crankcase heating is disabled.")
    crankcase_temp.setDefaultValue(55.0)
    args << crankcase_temp

    # make a double argument for central ac 1.5 ton eer capacity derate
    eer_capacity_derate_1ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_1ton", true)
    eer_capacity_derate_1ton.setDisplayName("1.5 Ton EER Capacity Derate")
    eer_capacity_derate_1ton.setDescription("EER multiplier for 1.5 ton air-conditioners.")
    eer_capacity_derate_1ton.setDefaultValue(1.0)
    args << eer_capacity_derate_1ton

    # make a double argument for central ac 2 ton eer capacity derate
    eer_capacity_derate_2ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_2ton", true)
    eer_capacity_derate_2ton.setDisplayName("2 Ton EER Capacity Derate")
    eer_capacity_derate_2ton.setDescription("EER multiplier for 2 ton air-conditioners.")
    eer_capacity_derate_2ton.setDefaultValue(1.0)
    args << eer_capacity_derate_2ton

    # make a double argument for central ac 3 ton eer capacity derate
    eer_capacity_derate_3ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_3ton", true)
    eer_capacity_derate_3ton.setDisplayName("3 Ton EER Capacity Derate")
    eer_capacity_derate_3ton.setDescription("EER multiplier for 3 ton air-conditioners.")
    eer_capacity_derate_3ton.setDefaultValue(1.0)
    args << eer_capacity_derate_3ton

    # make a double argument for central ac 4 ton eer capacity derate
    eer_capacity_derate_4ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_4ton", true)
    eer_capacity_derate_4ton.setDisplayName("4 Ton EER Capacity Derate")
    eer_capacity_derate_4ton.setDescription("EER multiplier for 4 ton air-conditioners.")
    eer_capacity_derate_4ton.setDefaultValue(1.0)
    args << eer_capacity_derate_4ton

    # make a double argument for central ac 5 ton eer capacity derate
    eer_capacity_derate_5ton = OpenStudio::Measure::OSArgument::makeDoubleArgument("eer_capacity_derate_5ton", true)
    eer_capacity_derate_5ton.setDisplayName("5 Ton EER Capacity Derate")
    eer_capacity_derate_5ton.setDescription("EER multiplier for 5 ton air-conditioners.")
    eer_capacity_derate_5ton.setDefaultValue(1.0)
    args << eer_capacity_derate_5ton

    # make a string argument for central air cooling output capacity
    capacity = OpenStudio::Measure::OSArgument::makeStringArgument("capacity", true)
    capacity.setDisplayName("Cooling Capacity")
    capacity.setDescription("The output cooling capacity of the air conditioner. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    capacity.setUnits("tons")
    capacity.setDefaultValue(Constants.SizingAuto)
    args << capacity

    # make a string argument for distribution system efficiency
    dse = OpenStudio::Measure::OSArgument::makeStringArgument("dse", true)
    dse.setDisplayName("Distribution System Efficiency")
    dse.setDescription("Defines the energy losses associated with the delivery of energy from the equipment to the source of the load.")
    dse.setDefaultValue("NA")
    args << dse

    return args
  end # end the arguments method

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    seer = runner.getDoubleArgumentValue("seer", user_arguments)
    eers = [runner.getDoubleArgumentValue("eer", user_arguments), runner.getDoubleArgumentValue("eer2", user_arguments)]
    shrs = [runner.getDoubleArgumentValue("shr", user_arguments), runner.getDoubleArgumentValue("shr2", user_arguments)]
    capacity_ratios = [runner.getDoubleArgumentValue("capacity_ratio", user_arguments), runner.getDoubleArgumentValue("capacity_ratio2", user_arguments)]
    fan_speed_ratios = [runner.getDoubleArgumentValue("fan_speed_ratio", user_arguments), runner.getDoubleArgumentValue("fan_speed_ratio2", user_arguments)]
    fan_power_rated = runner.getDoubleArgumentValue("fan_power_rated", user_arguments)
    fan_power_installed = runner.getDoubleArgumentValue("fan_power_installed", user_arguments)
    crankcase_capacity = runner.getDoubleArgumentValue("crankcase_capacity", user_arguments)
    crankcase_temp = runner.getDoubleArgumentValue("crankcase_temp", user_arguments)
    eer_capacity_derate_1ton = runner.getDoubleArgumentValue("eer_capacity_derate_1ton", user_arguments)
    eer_capacity_derate_2ton = runner.getDoubleArgumentValue("eer_capacity_derate_2ton", user_arguments)
    eer_capacity_derate_3ton = runner.getDoubleArgumentValue("eer_capacity_derate_3ton", user_arguments)
    eer_capacity_derate_4ton = runner.getDoubleArgumentValue("eer_capacity_derate_4ton", user_arguments)
    eer_capacity_derate_5ton = runner.getDoubleArgumentValue("eer_capacity_derate_5ton", user_arguments)
    eer_capacity_derates = [eer_capacity_derate_1ton, eer_capacity_derate_2ton, eer_capacity_derate_3ton, eer_capacity_derate_4ton, eer_capacity_derate_5ton]
    capacity = runner.getStringArgumentValue("capacity", user_arguments)
    unless capacity == Constants.SizingAuto
      capacity = UnitConversions.convert(capacity.to_f, "ton", "Btu/hr")
    end
    dse = runner.getStringArgumentValue("dse", user_arguments)
    if dse.to_f > 0
      dse = dse.to_f
    else
      dse = 1.0
    end

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
      return false
    end

    units.each do |unit|
      existing_objects = {}
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|
        ([control_zone] + slave_zones).each do |zone|
          existing_objects[zone] = HVAC.remove_hvac_equipment(model, runner, zone, unit,
                                                              Constants.ObjectNameCentralAirConditioner)
        end
      end

      success = HVAC.apply_central_ac_2speed(model, unit, runner, seer, eers, shrs,
                                             capacity_ratios, fan_speed_ratios,
                                             fan_power_rated, fan_power_installed,
                                             crankcase_capacity, crankcase_temp,
                                             eer_capacity_derates, capacity, dse,
                                             existing_objects)
      return false if not success
    end # unit

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ProcessTwoSpeedCentralAirConditioner.new.registerWithApplication
