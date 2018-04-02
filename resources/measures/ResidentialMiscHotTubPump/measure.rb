require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class ResidentialHotTubPump < OpenStudio::Measure::ModelMeasure
  
  def name
    return "Set Residential Hot Tub Pump"
  end
  
  def description
    return "Adds (or replaces) a residential hot tub pump with the specified efficiency and schedule. The hot tub is assumed to be outdoors. For multifamily buildings, the hot tub pump is set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Since there is no Hot Tub Pump object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential hot tub pump. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #TODO: New argument for demand response for hot tub pumps (alternate schedules if automatic DR control is specified)
    
    #make a double argument for Base Energy Use
    base_energy = OpenStudio::Measure::OSArgument::makeDoubleArgument("base_energy")
    base_energy.setDisplayName("Base Energy Use")
    base_energy.setUnits("kWh/yr")
    base_energy.setDescription("The national average (Building America Benchmark) energy use.")
    base_energy.setDefaultValue(1014.1)
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
    weekday_sch.setDefaultValue("0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024")
    args << weekday_sch
    
    #Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch")
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    weekend_sch.setDefaultValue("0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024")
    args << weekend_sch

    #Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch")
    monthly_sch.setDisplayName("Month schedule")
    monthly_sch.setDescription("Specify the 12-month schedule.")
    monthly_sch.setDefaultValue("0.921, 0.928, 0.921, 0.915, 0.921, 1.160, 1.158, 1.158, 1.160, 0.921, 0.915, 0.921")
    args << monthly_sch

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
    
    # Remove all existing objects
    obj_name = Constants.ObjectNameHotTubPump
    model.getSpaces.each do |space|
        remove_existing(runner, space, obj_name)
    end

    location_hierarchy = [Constants.SpaceTypeLiving,
                          Constants.SpaceTypeFinishedBasement]

    tot_htp_ann = 0
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
        space = Geometry.get_space_from_location(unit, Constants.Auto, location_hierarchy)
        next if space.nil?

        unit_obj_name = Constants.ObjectNameHotTubPump(unit.name.to_s)
    
        #Calculate annual energy use
        ann_elec = base_energy * mult # kWh/yr
        
        if scale_energy
            #Scale energy use by num beds and floor area
            constant = ann_elec/2
            nbr_coef = ann_elec/4/3
            ffa_coef = ann_elec/4/1920
            htp_ann = constant + nbr_coef * nbeds + ffa_coef * ffa # kWh/yr
        else
            htp_ann = ann_elec # kWh/yr
        end

        if htp_ann > 0
            
            if sch.nil?
                # Create schedule
                sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameHotTubPump + " schedule", weekday_sch, weekend_sch, monthly_sch)
                if not sch.validated?
                    return false
                end
            end
            
            design_level = sch.calcDesignLevelFromDailykWh(htp_ann/365.0)
            
            #Add electric equipment for the hot tub pump
            htp_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
            htp = OpenStudio::Model::ElectricEquipment.new(htp_def)
            htp.setName(unit_obj_name)
            htp.setEndUseSubcategory(unit_obj_name)
            htp.setSpace(space)
            htp_def.setName(unit_obj_name)
            htp_def.setDesignLevel(design_level)
            htp_def.setFractionRadiant(0)
            htp_def.setFractionLatent(0)
            htp_def.setFractionLost(1)
            htp.setSchedule(sch.schedule)
            
            msgs << "A hot tub pump with #{htp_ann.round} kWhs annual energy consumption has been assigned to outside."
            
            tot_htp_ann += htp_ann
        end
        
    end
    
    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        runner.registerFinalCondition("The building has been assigned hot tub pumps totaling #{tot_htp_ann.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No hot tub pump has been assigned.")
    end
    
    return true
 
  end #end the run method
  
  def remove_existing(runner, space, obj_name)
    # Remove any existing hot tub pump
    objects_to_remove = []
    space.electricEquipment.each do |space_equipment|
        next if not space_equipment.name.to_s.start_with? obj_name
        objects_to_remove << space_equipment
        objects_to_remove << space_equipment.electricEquipmentDefinition
        if space_equipment.schedule.is_initialized
            objects_to_remove << space_equipment.schedule.get
        end
    end
    if objects_to_remove.size > 0
        runner.registerInfo("Removed existing hot tub pump from outside.")
    end
    objects_to_remove.uniq.each do |object|
        begin
            object.remove
        rescue
            # no op
        end
    end
  end

end #end the measure

#this allows the measure to be use by the application
ResidentialHotTubPump.new.registerWithApplication