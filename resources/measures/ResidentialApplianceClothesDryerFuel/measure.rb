require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/clothesdryer"

#start the measure
class ResidentialClothesDryerFuel < OpenStudio::Measure::ModelMeasure
  
  def name
    return "Set Residential Fuel Clothes Dryer"
  end

  def description
    return "Adds (or replaces) a residential clothes dryer with the specified efficiency, operation, and schedule. For multifamily buildings, the clothes dryer can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Since there is no Clothes Dryer object in OpenStudio/EnergyPlus, we look for an OtherEquipment or GasEquipment object with the name that denotes it is a residential clothes dryer. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a double argument for Fuel Type
    fuel_display_names = OpenStudio::StringVector.new
    fuel_display_names << Constants.FuelTypeGas
    fuel_display_names << Constants.FuelTypePropane
    cd_fuel_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("fuel_type", fuel_display_names, true)
    cd_fuel_type.setDisplayName("Fuel Type")
    cd_fuel_type.setDescription("Type of fuel used by the clothes dryer.")
    cd_fuel_type.setDefaultValue(Constants.FuelTypeGas)
    args << cd_fuel_type

    #make a double argument for Energy Factor
    cd_cef = OpenStudio::Measure::OSArgument::makeDoubleArgument("cef",true)
    cd_cef.setDisplayName("Combined Energy Factor")
    cd_cef.setDescription("The Combined Energy Factor (CEF) measures the pounds of clothing that can be dried per kWh (Fuel equivalent) of electricity, including energy consumed during Stand-by and Off modes. If only an Energy Factor (EF) is available, convert using the equation: CEF = EF / 1.15.")
    cd_cef.setDefaultValue(2.4)
    cd_cef.setUnits("lb/kWh")
    args << cd_cef
    
    #make a double argument for Assumed Fuel Electric Split
    cd_fuel_split = OpenStudio::Measure::OSArgument::makeDoubleArgument("fuel_split",true)
    cd_fuel_split.setDisplayName("Assumed Fuel Electric Split")
    cd_fuel_split.setDescription("Defined as (Electric Energy) / (Fuel Energy + Electric Energy).")
    cd_fuel_split.setDefaultValue(0.07)
    cd_fuel_split.setUnits("frac")
    args << cd_fuel_split
    
    #make a double argument for occupancy energy multiplier
    cd_mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult",true)
    cd_mult.setDisplayName("Occupancy Energy Multiplier")
    cd_mult.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
    cd_mult.setDefaultValue(1)
    args << cd_mult

       #Make a string argument for 24 weekday schedule values
    cd_weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_sch")
    cd_weekday_sch.setDisplayName("Weekday schedule")
    cd_weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    cd_weekday_sch.setDefaultValue("0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024")
    args << cd_weekday_sch
    
    #Make a string argument for 24 weekend schedule values
    cd_weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch")
    cd_weekend_sch.setDisplayName("Weekend schedule")
    cd_weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    cd_weekend_sch.setDefaultValue("0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024")
    args << cd_weekend_sch

      #Make a string argument for 12 monthly schedule values
    cd_monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch", true)
    cd_monthly_sch.setDisplayName("Month schedule")
    cd_monthly_sch.setDescription("Specify the 12-month schedule.")
    cd_monthly_sch.setDefaultValue("1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0")
    args << cd_monthly_sch

    #make a choice argument for space
    spaces = Geometry.get_all_unit_spaces(model)
    if spaces.nil?
        spaces = []
    end
    space_args = OpenStudio::StringVector.new
    space_args << Constants.Auto
    spaces.each do |space|
        space_args << space.name.to_s
    end
    space = OpenStudio::Measure::OSArgument::makeChoiceArgument("space", space_args, true)
    space.setDisplayName("Location")
    space.setDescription("Select the space where the cooking range is located. '#{Constants.Auto}' will choose the lowest above-grade finished space available (e.g., first story living space), or a below-grade finished space as last resort. For multifamily buildings, '#{Constants.Auto}' will choose a space for each unit of the building.")
    space.setDefaultValue(Constants.Auto)
    args << space
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    fuel_type = runner.getStringArgumentValue("fuel_type",user_arguments)
    cef = runner.getDoubleArgumentValue("cef",user_arguments)
    fuel_split = runner.getDoubleArgumentValue("fuel_split",user_arguments)
    mult = runner.getDoubleArgumentValue("mult",user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
    space_r = runner.getStringArgumentValue("space",user_arguments)

    #Check for valid inputs
    if cef <= 0
        runner.registerError("Combined energy factor must be greater than 0.0.")
        return false
    end
    if fuel_split < 0 or fuel_split > 1
        runner.registerError("Assumed fuel electric split must be greater than or equal to 0.0 and less than or equal to 1.0.")
    end
    if mult < 0
        runner.registerError("Occupancy energy multiplier must be greater than or equal to 0.0.")
        return false
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    tot_ann_e = 0
    tot_ann_f = 0
    msgs = []
    sch = nil
    units.each do |unit|
    
        # Get space
        space = Geometry.get_space_from_string(unit.spaces, space_r)
        next if space.nil?
        
        success, ann_e, ann_f, sch = ClothesDryer.apply(model, unit, runner, sch, cef, mult, weekday_sch, weekend_sch, monthly_sch, 
                                                        space, fuel_type, fuel_split)
        
        if not success
            return false
        end
        
        next if ann_e == 0 and ann_f == 0

        msg_f = ""
        if fuel_type == Constants.FuelTypeGas
            msg_f = "#{ann_f.round} therms"
        else
            msg_f = "#{UnitConversion.btu2gal(OpenStudio.convert(ann_f, "therm", "Btu").get, fuel_type).round} gallons"
        end
        msg_e = ""
        if ann_e > 0
            msg_e = " and #{ann_e.round} kWhs"
        end
        msgs << "A clothes dryer with #{msg_f}#{msg_e} annual energy consumption has been assigned to space '#{space.name.to_s}'."
        
        tot_ann_e += ann_e
        tot_ann_f += ann_f
        
    end
    
    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        msg_f = ""
        if fuel_type == Constants.FuelTypeGas
            msg_f = "#{tot_ann_f.round} therms"
        else
            msg_f = "#{UnitConversion.btu2gal(OpenStudio.convert(tot_ann_f, "therm", "Btu").get, fuel_type).round} gallons"
        end
        msg_e = ""
        if tot_ann_e > 0
            msg_e = " and #{tot_ann_e.round} kWhs"
        end
        runner.registerFinalCondition("The building has been assigned clothes dryers totaling #{msg_f}#{msg_e} annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No clothes dryer has been assigned.")
    end
    
    return true

    
    end

end #end the measure

#this allows the measure to be use by the application
ResidentialClothesDryerFuel.new.registerWithApplication