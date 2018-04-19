# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/hvac"

# start the measure
class ProcessBoiler < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "Set Residential Boiler"
  end

  # human readable description
  def description
    return "This measure removes any existing HVAC heating components from the building and adds a boiler along with constant speed pump and water baseboard coils to a hot water plant loop. For multifamily buildings, the supply components on the plant loop can be set for all units of the building.#{Constants.WorkflowDescription}"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Any heating components or baseboard convective electrics/waters are removed from any existing air/plant loops or zones. A boiler along with constant speed pump and water baseboard coils are added to a hot water plant loop."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a string argument for boiler fuel type
    fuel_display_names = OpenStudio::StringVector.new
    fuel_display_names << Constants.FuelTypeGas
    fuel_display_names << Constants.FuelTypeOil
    fuel_display_names << Constants.FuelTypePropane
    fuel_display_names << Constants.FuelTypeElectric
    fuel_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("fuel_type", fuel_display_names, true)
    fuel_type.setDisplayName("Fuel Type")
    fuel_type.setDescription("Type of fuel used for heating.")
    fuel_type.setDefaultValue(Constants.FuelTypeGas)
    args << fuel_type    
    
    #make a string argument for boiler system type
    boiler_display_names = OpenStudio::StringVector.new
    boiler_display_names << Constants.BoilerTypeForcedDraft
    boiler_display_names << Constants.BoilerTypeCondensing
    boiler_display_names << Constants.BoilerTypeNaturalDraft
    #boiler_display_names << Constants.BoilerTypeSteam
    system_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("system_type", boiler_display_names, true)
    system_type.setDisplayName("System Type")
    system_type.setDescription("The system type of the boiler.")
    system_type.setDefaultValue(Constants.BoilerTypeForcedDraft)
    args << system_type
    
    #make an argument for entering boiler installed afue
    afue = OpenStudio::Measure::OSArgument::makeDoubleArgument("afue",true)
    afue.setDisplayName("Installed AFUE")
    afue.setUnits("Btu/Btu")
    afue.setDescription("The installed Annual Fuel Utilization Efficiency (AFUE) of the boiler, which can be used to account for performance derating or degradation relative to the rated value.")
    afue.setDefaultValue(0.80)
    args << afue
    
    #make a bool argument for whether the boiler OAT enabled
    oat_reset_enabled = OpenStudio::Measure::OSArgument::makeBoolArgument("oat_reset_enabled", true)
    oat_reset_enabled.setDisplayName("Outside Air Reset Enabled")
    oat_reset_enabled.setDescription("Outside Air Reset Enabled on Hot Water Supply Temperature.")
    oat_reset_enabled.setDefaultValue(false)
    args << oat_reset_enabled    
    
    #make an argument for entering boiler OAT high
    oat_high = OpenStudio::Measure::OSArgument::makeDoubleArgument("oat_high",false)
    oat_high.setDisplayName("High Outside Air Temp")
    oat_high.setUnits("degrees F")
    oat_high.setDescription("High Outside Air Temperature.")
    args << oat_high    
    
    #make an argument for entering boiler OAT low
    oat_low = OpenStudio::Measure::OSArgument::makeDoubleArgument("oat_low",false)
    oat_low.setDisplayName("Low Outside Air Temp")
    oat_low.setUnits("degrees F")
    oat_low.setDescription("Low Outside Air Temperature.")
    args << oat_low
    
    #make an argument for entering boiler OAT high HWST
    oat_hwst_high = OpenStudio::Measure::OSArgument::makeDoubleArgument("oat_hwst_high",false)
    oat_hwst_high.setDisplayName("Hot Water Supply Temp High Outside Air")
    oat_hwst_high.setUnits("degrees F")
    oat_hwst_high.setDescription("Hot Water Supply Temperature corresponding to High Outside Air Temperature.")
    args << oat_hwst_high
    
    #make an argument for entering boiler OAT low HWST
    oat_hwst_low = OpenStudio::Measure::OSArgument::makeDoubleArgument("oat_hwst_low",false)
    oat_hwst_low.setDisplayName("Hot Water Supply Temp Low Outside Air")
    oat_hwst_low.setUnits("degrees F")
    oat_hwst_low.setDescription("Hot Water Supply Temperature corresponding to Low Outside Air Temperature.")
    args << oat_hwst_low        
    
    #make an argument for entering boiler design temp
    design_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument("design_temp",true)
    design_temp.setDisplayName("Design Temperature")
    design_temp.setUnits("degrees F")
    design_temp.setDescription("Temperature of the outlet water.")
    design_temp.setDefaultValue(180.0)
    args << design_temp     
    
    #make an argument for whether the boiler is modulating or not
    is_modulating = OpenStudio::Measure::OSArgument::makeBoolArgument("is_modulating", true)
    is_modulating.setDisplayName("Modulating Boiler")
    is_modulating.setDescription("Whether the burner on the boiler can fully modulate or not. Typically modulating boilers are higher efficiency units (such as condensing boilers). Only used for non-electric boilers.")
    is_modulating.setDefaultValue(false)
    args << is_modulating

    #make a string argument for furnace heating output capacity
    capacity = OpenStudio::Measure::OSArgument::makeStringArgument("capacity", true)
    capacity.setDisplayName("Heating Capacity")
    capacity.setDescription("The output heating capacity of the boiler. If using '#{Constants.SizingAuto}', the autosizing algorithm will use ACCA Manual S to set the capacity.")
    capacity.setUnits("kBtu/hr")
    capacity.setDefaultValue(Constants.SizingAuto)
    args << capacity  
    
    #make a string argument for distribution system efficiency
    dse = OpenStudio::Measure::OSArgument::makeStringArgument("dse", true)
    dse.setDisplayName("Distribution System Efficiency")
    dse.setDescription("Defines the energy losses associated with the delivery of energy from the equipment to the source of the load.")
    dse.setDefaultValue("NA")
    args << dse  
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
    
    fuel_type = runner.getStringArgumentValue("fuel_type",user_arguments)
    system_type = runner.getStringArgumentValue("system_type",user_arguments)
    afue = runner.getDoubleArgumentValue("afue",user_arguments)
    oat_reset_enabled = runner.getBoolArgumentValue("oat_reset_enabled",user_arguments)    
    oat_high = runner.getOptionalDoubleArgumentValue("oat_high", user_arguments)
    oat_high.is_initialized ? oat_high = oat_high.get : oat_high = nil    
    oat_low = runner.getOptionalDoubleArgumentValue("oat_low", user_arguments)
    oat_low.is_initialized ? oat_low = oat_low.get : oat_low = nil     
    oat_hwst_high = runner.getOptionalDoubleArgumentValue("oat_hwst_high", user_arguments)
    oat_hwst_high.is_initialized ? oat_hwst_high = oat_hwst_high.get : oat_hwst_high = nil
    oat_hwst_low = runner.getOptionalDoubleArgumentValue("oat_hwst_low", user_arguments)
    oat_hwst_low.is_initialized ? oat_hwst_low = oat_hwst_low.get : oat_hwst_low = nil      
    capacity = runner.getStringArgumentValue("capacity",user_arguments)
    if not capacity == Constants.SizingAuto
      capacity = UnitConversions.convert(capacity.to_f,"kBtu/hr","Btu/hr")
    end
    design_temp = runner.getDoubleArgumentValue("design_temp",user_arguments)
    is_modulating = runner.getBoolArgumentValue("is_modulating",user_arguments)
    dse = runner.getStringArgumentValue("dse",user_arguments)
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
      
      thermal_zones = Geometry.get_thermal_zones_from_spaces(unit.spaces)
      HVAC.get_control_and_slave_zones(thermal_zones).each do |control_zone, slave_zones|
        ([control_zone] + slave_zones).each do |zone|
          HVAC.remove_hvac_equipment(model, runner, zone, unit,
                                     Constants.ObjectNameBoiler)
        end
      end
    
      success = HVAC.apply_boiler(model, unit, runner, fuel_type, system_type, afue,
                                  oat_reset_enabled, oat_high, oat_low, oat_hwst_high, oat_hwst_low,
                                  capacity, design_temp, is_modulating, dse)
      return false if not success
      
    end
    
    return true

  end
  
end

# register the measure to be used by the application
ProcessBoiler.new.registerWithApplication