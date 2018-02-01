require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"

#start the measure
class ResidentialExtraRefrigerator < OpenStudio::Measure::ModelMeasure
  
  def name
    return "Set Residential Extra Refrigerator"
  end
  
  def description
    return "Adds (or replaces) a residential extra refrigerator with the specified efficiency, operation, and schedule. For multifamily buildings, the extra refrigerator can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Since there is no Extra Refrigerator object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential extra refrigerator. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model."
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #TODO: New argument for demand response for fridges (alternate schedules if automatic DR control is specified)
    
    #make a double argument for user defined fridge options
    fridge_E = OpenStudio::Measure::OSArgument::makeDoubleArgument("fridge_E",true)
    fridge_E.setDisplayName("Rated Annual Consumption")
    fridge_E.setUnits("kWh/yr")
    fridge_E.setDescription("The EnergyGuide rated annual energy consumption for a refrigerator.")
    fridge_E.setDefaultValue(1102)
    args << fridge_E
    
    #make a double argument for Occupancy Energy Multiplier
    mult = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult")
    mult.setDisplayName("Occupancy Energy Multiplier")
    mult.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
    mult.setDefaultValue(1)
    args << mult
    
    #Make a string argument for 24 weekday schedule values
    weekday_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekday_sch")
    weekday_sch.setDisplayName("Weekday schedule")
    weekday_sch.setDescription("Specify the 24-hour weekday schedule.")
    weekday_sch.setDefaultValue("0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041")
    args << weekday_sch
    
    #Make a string argument for 24 weekend schedule values
    weekend_sch = OpenStudio::Measure::OSArgument::makeStringArgument("weekend_sch")
    weekend_sch.setDisplayName("Weekend schedule")
    weekend_sch.setDescription("Specify the 24-hour weekend schedule.")
    weekend_sch.setDefaultValue("0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041")
    args << weekend_sch

    #Make a string argument for 12 monthly schedule values
    monthly_sch = OpenStudio::Measure::OSArgument::makeStringArgument("monthly_sch")
    monthly_sch.setDisplayName("Month schedule")
    monthly_sch.setDescription("Specify the 12-month schedule.")
    monthly_sch.setDefaultValue("0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837")
    args << monthly_sch

    #make a choice argument for location
    location_args = OpenStudio::StringVector.new
    location_args << Constants.Auto
    Geometry.get_model_locations(model).each do |loc|
        location_args << loc
    end
    location = OpenStudio::Measure::OSArgument::makeChoiceArgument("location", location_args, true)
    location.setDisplayName("Location")
    location.setDescription("The space type for the location. '#{Constants.Auto}' will automatically choose a space type based on the space types found in the model.")
    location.setDefaultValue(Constants.Auto)
    args << location

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
    fridge_E = runner.getDoubleArgumentValue("fridge_E",user_arguments)
    mult = runner.getDoubleArgumentValue("mult",user_arguments)
    weekday_sch = runner.getStringArgumentValue("weekday_sch",user_arguments)
    weekend_sch = runner.getStringArgumentValue("weekend_sch",user_arguments)
    monthly_sch = runner.getStringArgumentValue("monthly_sch",user_arguments)
    location = runner.getStringArgumentValue("location",user_arguments)
    
    #check for valid inputs
    if fridge_E < 0
        runner.registerError("Rated annual consumption must be greater than or equal to 0.")
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
    
    # Remove all existing objects
    obj_name = Constants.ObjectNameExtraRefrigerator
    model.getSpaces.each do |space|
        remove_existing(runner, space, obj_name)
    end
    
    #Calculate fridge daily energy use
    fridge_ann = fridge_E*mult
    
    location_hierarchy = [Constants.SpaceTypeGarage, 
                          Constants.SpaceTypeFinishedBasement,
                          Constants.SpaceTypeUnfinishedBasement, 
                          Constants.SpaceTypeLiving]
                              
    tot_fridge_ann = 0
    msgs = []
    sch = nil
    units.each_with_index do |unit, unit_index|

        # Get space
        space = Geometry.get_space_from_location(unit, location, location_hierarchy)
        next if space.nil?
        
        unit_obj_name = Constants.ObjectNameExtraRefrigerator(unit.name.to_s)

        if fridge_ann > 0
        
            if sch.nil?
                # Create schedule
                sch = MonthWeekdayWeekendSchedule.new(model, runner, Constants.ObjectNameExtraRefrigerator + " schedule", weekday_sch, weekend_sch, monthly_sch)
                if not sch.validated?
                    return false
                end
            end
            
            design_level = sch.calcDesignLevelFromDailykWh(fridge_ann/365.0)
            
            #Add electric equipment for the extra fridge
            frg_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
            frg = OpenStudio::Model::ElectricEquipment.new(frg_def)
            frg.setName(unit_obj_name)
            frg.setEndUseSubcategory(unit_obj_name)
            frg.setSpace(space)
            frg_def.setName(unit_obj_name)
            frg_def.setDesignLevel(design_level)
            frg_def.setFractionRadiant(0)
            frg_def.setFractionLatent(0)
            frg_def.setFractionLost(0)
            frg.setSchedule(sch.schedule)
            
            msgs << "An extra refrigerator with #{fridge_ann.round} kWhs annual energy consumption has been assigned to space '#{space.name.to_s}'."
            
            tot_fridge_ann += fridge_ann
        end
    end
    
    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        runner.registerFinalCondition("The building has been assigned extra refrigerators totaling #{tot_fridge_ann.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No extra refrigerator has been assigned.")
    end

    return true
 
  end #end the run method
  
  def remove_existing(runner, space, obj_name)
    # Remove any existing extra fridge
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
        runner.registerInfo("Removed existing extra refrigerator from space '#{space.name.to_s}'.")
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
ResidentialExtraRefrigerator.new.registerWithApplication