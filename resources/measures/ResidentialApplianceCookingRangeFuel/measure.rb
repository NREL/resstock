require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/util"

#start the measure
class ResidentialCookingRangeFuel < OpenStudio::Measure::ModelMeasure
  
  def name
    return "Set Residential Fuel Cooking Range"
  end
  
  def description
    return "Adds (or replaces) a residential cooking range with the specified efficiency, operation, and schedule. For multifamily buildings, the cooking range can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Since there is no Cooking Range object in OpenStudio/EnergyPlus, we look for an OtherEquipment or ElectricEquipment object with the name that denotes it is a residential cooking range. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a double argument for Fuel Type
    fuel_display_names = OpenStudio::StringVector.new
    fuel_display_names << Constants.FuelTypeGas
    fuel_display_names << Constants.FuelTypePropane
    fuel_type = OpenStudio::Measure::OSArgument::makeChoiceArgument("fuel_type", fuel_display_names, true)
    fuel_type.setDisplayName("Fuel Type")
    fuel_type.setDescription("Type of fuel used by the cooking range.")
    fuel_type.setDefaultValue(Constants.FuelTypeGas)
    args << fuel_type

    #make a double argument for cooktop EF
    c_ef = OpenStudio::Measure::OSArgument::makeDoubleArgument("c_ef", true)
    c_ef.setDisplayName("Cooktop Energy Factor")
    c_ef.setDescription("Cooktop energy factor determined by DOE test procedures for cooking appliances (DOE 1997).")
    c_ef.setDefaultValue(0.4)
    args << c_ef

    #make a double argument for oven EF
    o_ef = OpenStudio::Measure::OSArgument::makeDoubleArgument("o_ef", true)
    o_ef.setDisplayName("Oven Energy Factor")
    o_ef.setDescription("Oven energy factor determined by DOE test procedures for cooking appliances (DOE 1997).")
    o_ef.setDefaultValue(0.058)
    args << o_ef
    
    #make a boolean argument for has electric ignition
    e_ignition = OpenStudio::Measure::OSArgument::makeBoolArgument("e_ignition", true)
    e_ignition.setDisplayName("Has Electronic Ignition")
    e_ignition.setDescription("For fuel cooking ranges with electronic ignition, an extra (40 + 13.3x(#BR)) kWh/yr of electricity will be included.")
    e_ignition.setDefaultValue(true)
    args << e_ignition

    #make a double argument for Occupancy Energy Multiplier
    mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult", true)
    mult.setDisplayName("Occupancy Energy Multiplier")
    mult.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
    mult.setDefaultValue(1)
    args << mult

    #Make a string argument for 24 weekday schedule values
    weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_sch", true)
    weekday_sch.setDisplayName("Weekday schedule")
    weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    weekday_sch.setDefaultValue("0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011")
    args << weekday_sch
    
    #Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch", true)
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    weekend_sch.setDefaultValue("0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011")
    args << weekend_sch

    #Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch", true)
    monthly_sch.setDisplayName("Month schedule")
    monthly_sch.setDescription("Specify the 12-month schedule.")
    monthly_sch.setDefaultValue("1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097")
    args << monthly_sch

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
    c_ef = runner.getDoubleArgumentValue("c_ef",user_arguments)
    o_ef = runner.getDoubleArgumentValue("o_ef",user_arguments)
    e_ignition = runner.getBoolArgumentValue("e_ignition",user_arguments)
    mult = runner.getDoubleArgumentValue("mult",user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
    space_r = runner.getStringArgumentValue("space",user_arguments)
    
    #check for valid inputs
    if o_ef <= 0 or o_ef > 1
        runner.registerError("Oven energy factor must be greater than 0 and less than or equal to 1.")
        return false
    end
    if c_ef <= 0 or c_ef > 1
        runner.registerError("Cooktop energy factor must be greater than 0 and less than or equal to 1.")
        return false
    end
    if mult < 0
        runner.registerError("Occupancy energy multiplier must be greater than or equal to 0.")
        return false
    end

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    tot_range_ann_f = 0
    tot_range_ann_i = 0
    msgs = []
    sch = nil
    units.each do |unit|
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        
        # Get space
        space = Geometry.get_space_from_string(unit.spaces, space_r)
        next if space.nil?

        unit_obj_name_e = Constants.ObjectNameCookingRange(Constants.FuelTypeElectric, false, unit.name.to_s)
        unit_obj_name_g = Constants.ObjectNameCookingRange(Constants.FuelTypeGas, false, unit.name.to_s)
        unit_obj_name_p = Constants.ObjectNameCookingRange(Constants.FuelTypePropane, false, unit.name.to_s)
        unit_obj_name_i = Constants.ObjectNameCookingRange(Constants.FuelTypeElectric, true, unit.name.to_s)
        unit_obj_name_f = Constants.ObjectNameCookingRange(fuel_type, false, unit.name.to_s)

        # Remove any existing cooking range
        objects_to_remove = []
        space.electricEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != unit_obj_name_e and space_equipment.name.to_s != unit_obj_name_i
            objects_to_remove << space_equipment
            objects_to_remove << space_equipment.electricEquipmentDefinition
            if space_equipment.schedule.is_initialized
                objects_to_remove << space_equipment.schedule.get
            end
        end
        space.otherEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != unit_obj_name_g and space_equipment.name.to_s != unit_obj_name_p
            objects_to_remove << space_equipment
            objects_to_remove << space_equipment.otherEquipmentDefinition
            if space_equipment.schedule.is_initialized
                objects_to_remove << space_equipment.schedule.get
            end
        end
        if objects_to_remove.size > 0
            runner.registerInfo("Removed existing cooking range from space '#{space.name.to_s}'.")
        end
        objects_to_remove.uniq.each do |object|
            begin
                object.remove
            rescue
                # no op
            end
        end

        #Calculate fuel range daily energy use
        range_ann_f = ((2.64 + 0.88 * nbeds) / c_ef + (0.44 + 0.15 * nbeds) / o_ef)*mult # therm/yr
        if e_ignition == true
            range_ann_i = (40 + 13.3 * nbeds)*mult #kWh/yr
        else
            range_ann_i = 0
        end

        if range_ann_f > 0

            if sch.nil?
                # Create schedule
                sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameCookingRange(fuel_type, false) + " schedule", weekday_sch, weekend_sch, monthly_sch)
                if not sch.validated?
                    return false
                end
            end
            
            design_level_f = sch.calcDesignLevelFromDailyTherm(range_ann_f/365.0)
            design_level_i = sch.calcDesignLevelFromDailykWh(range_ann_i/365.0)
            
            #Add equipment for the range
            if e_ignition == true
                rng_def2 = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
                rng2 = OpenStudio::Model::ElectricEquipment.new(rng_def2)
                rng2.setName(unit_obj_name_i)
                rng2.setEndUseSubcategory(unit_obj_name_i)
                rng2.setSpace(space)
                rng_def2.setName(unit_obj_name_i)
                rng_def2.setDesignLevel(design_level_i)
                rng_def2.setFractionRadiant(0.24)
                rng_def2.setFractionLatent(0.3)
                rng_def2.setFractionLost(0.3)
                rng2.setSchedule(sch.schedule)
            end

            rng_def = OpenStudio::Model::OtherEquipmentDefinition.new(model)
            rng = OpenStudio::Model::OtherEquipment.new(rng_def)
            rng.setName(unit_obj_name_f)
            rng.setEndUseSubcategory(unit_obj_name_f)
            rng.setFuelType(HelperMethods.eplus_fuel_map(fuel_type))
            rng.setSpace(space)
            rng_def.setName(unit_obj_name_f)
            rng_def.setDesignLevel(design_level_f)
            rng_def.setFractionRadiant(0.18)
            rng_def.setFractionLatent(0.2)
            rng_def.setFractionLost(0.5)
            rng.setSchedule(sch.schedule)

            # Report each assignment plus final condition
            s_ann = ""
            if fuel_type == Constants.FuelTypeGas
                s_ann = "#{range_ann_f.round} therms"
            else
                s_ann = "#{UnitConversions.btu2gal(UnitConversions.convert(range_ann_f, "therm", "Btu"), fuel_type).round} gallons"
            end
            s_ignition = ""
            if e_ignition
                s_ignition = " and #{range_ann_i.round} kWhs"
            end
            msgs << "A cooking range with #{s_ann}#{s_ignition} annual energy consumption has been assigned to space '#{space.name.to_s}'."
            
            tot_range_ann_f += range_ann_f
            tot_range_ann_i += range_ann_i
        end
        
    end
          
    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        s_ann = ""
        if fuel_type == Constants.FuelTypeGas
            s_ann = "#{tot_range_ann_f.round} therms"
        else
            s_ann = "#{UnitConversions.btu2gal(UnitConversions.convert(tot_range_ann_f, "therm", "Btu"), fuel_type).round} gallons"
        end
        s_ignition = ""
        if e_ignition
            s_ignition = " and #{tot_range_ann_i.round} kWhs"
        end
        runner.registerFinalCondition("The building has been assigned cooking ranges totaling #{s_ann}#{s_ignition} annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No cooking range has been assigned.")
    end
    
    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialCookingRangeFuel.new.registerWithApplication