require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"

#start the measure
class ResidentialGasFireplace < OpenStudio::Measure::ModelMeasure
  
  def name
    return "Set Residential Gas Fireplace"
  end
  
  def description
    return "Adds (or replaces) a residential gas fireplace with the specified efficiency and schedule. For multifamily buildings, the fireplace can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Since there is no Gas Fireplace object in OpenStudio/EnergyPlus, we look for a GasEquipment object with the name that denotes it is a residential gas fireplace. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a double argument for Base Energy Use
    base_energy = OpenStudio::Measure::OSArgument::makeDoubleArgument("base_energy")
    base_energy.setDisplayName("Base Energy Use")
    base_energy.setUnits("therm/yr")
    base_energy.setDescription("The national average (Building America Benchmark) energy use.")
    base_energy.setDefaultValue(60)
    args << base_energy

    #make a double argument for Energy Multiplier
    mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult")
    mult.setDisplayName("Energy Multiplier")
    mult.setDescription("Sets the annual energy use equal to the base energy use times this multiplier.")
    mult.setDefaultValue(1)
    args << mult
    
    #make a boolean argument for Scale Energy Use
    scale_energy = OpenStudio::Measure::OSArgument::makeBoolArgument("scale_energy",true)
    scale_energy.setDisplayName("Scale Energy Use")
    scale_energy.setDescription("If true, scales the energy use relative to a 3-bedroom, 1920 sqft house using the following equation: Fscale = (0.5 + 0.25 x Nbr/3 + 0.25 x FFA/1920) where Nbr is the number of bedrooms and FFA is the finished floor area.")
    scale_energy.setDefaultValue(true)
    args << scale_energy

    #Make a string argument for 24 weekday schedule values
    weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_sch")
    weekday_sch.setDisplayName("Weekday schedule")
    weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    weekday_sch.setDefaultValue("0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065")
    args << weekday_sch
    
    #Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch")
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    weekend_sch.setDefaultValue("0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065")
    args << weekend_sch

    #Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch")
    monthly_sch.setDisplayName("Month schedule")
    monthly_sch.setDescription("Specify the 12-month schedule.")
    monthly_sch.setDefaultValue("1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154")
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
    base_energy = runner.getDoubleArgumentValue("base_energy",user_arguments)
    mult = runner.getDoubleArgumentValue("mult",user_arguments)
    scale_energy = runner.getBoolArgumentValue("scale_energy",user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
    space_r = runner.getStringArgumentValue("space",user_arguments)

    #check for valid inputs
    if base_energy < 0
        runner.registerError("Base energy use must be greater than or equal to 0.")
        return false
    end
    if mult < 0
        runner.registerError("Energy multiplier must be greater than or equal to 0.")
        return false
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    tot_gf_ann_g = 0
    msgs = []
    sch = nil
    units.each do |unit|
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        
        # Get unit ffa
        ffa = Geometry.get_finished_floor_area_from_spaces(unit.spaces, false, runner)
        if ffa.nil?
            return false
        end
        
        # Get space
        space = Geometry.get_space_from_string(unit.spaces, space_r)
        next if space.nil?

        unit_obj_name = Constants.ObjectNameGasFireplace(unit.name.to_s)

        # Remove any existing gas fireplace
        objects_to_remove = []
        space.gasEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != unit_obj_name
            objects_to_remove << space_equipment
            objects_to_remove << space_equipment.gasEquipmentDefinition
            if space_equipment.schedule.is_initialized
                objects_to_remove << space_equipment.schedule.get
            end
        end
        if objects_to_remove.size > 0
            runner.registerInfo("Removed existing gas fireplace from space #{space.name.to_s}.")
        end
        objects_to_remove.uniq.each do |object|
            begin
                object.remove
            rescue
                # no op
            end
        end

        #Calculate annual energy use
        ann_g = base_energy * mult # therm/yr
        
        if scale_energy
            #Scale energy use by num beds and floor area
            constant = ann_g/2
            nbr_coef = ann_g/4/3
            ffa_coef = ann_g/4/1920
            gf_ann_g = constant + nbr_coef * nbeds + ffa_coef * ffa # therm/yr
        else
            gf_ann_g = ann_g # therm/yr
        end
        
        if gf_ann_g > 0
            
            if sch.nil?
                # Create schedule
                sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameGasFireplace + " schedule", weekday_sch, weekend_sch, monthly_sch)
                if not sch.validated?
                    return false
                end
            end
            
            design_level = sch.calcDesignLevelFromDailyTherm(gf_ann_g/365.0)

            #Add gas equipment for the fireplace
            gf_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
            gf = OpenStudio::Model::GasEquipment.new(gf_def)
            gf.setName(unit_obj_name)
            gf.setEndUseSubcategory(unit_obj_name)
            gf.setSpace(space)
            gf_def.setName(unit_obj_name)
            gf_def.setDesignLevel(design_level)
            gf_def.setFractionRadiant(0.3)
            gf_def.setFractionLatent(0.1)
            gf_def.setFractionLost(0.4)
            gf.setSchedule(sch.schedule)
    
            msgs << "A gas fireplace with #{gf_ann_g.round} therms annual energy consumption has been assigned to space '#{space.name.to_s}'."
            
            tot_gf_ann_g += gf_ann_g
        end
        
    end
    
    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        runner.registerFinalCondition("The building has been assigned gas fireplaces totaling #{tot_gf_ann_g.round} therms annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No gas fireplace has been assigned.")
    end

    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialGasFireplace.new.registerWithApplication