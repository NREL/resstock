require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/waterheater"
require "#{File.dirname(__FILE__)}/resources/appliances"

#start the measure
class ResidentialDishwasher < OpenStudio::Measure::ModelMeasure
  
  def name
    return "Set Residential Dishwasher"
  end
 
  def description
    return "Adds (or replaces) a residential dishwasher with the specified efficiency, operation, and schedule. For multifamily buildings, the dishwasher can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Since there is no Dishwasher object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential dishwasher. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end
 
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make an integer argument for number of place settings
    num_settings = OpenStudio::Measure::OSArgument::makeIntegerArgument("num_settings",true)
    num_settings.setDisplayName("Number of Place Settings")
    num_settings.setUnits("#")
    num_settings.setDescription("The number of place settings for the unit. Data obtained from manufacturer's literature.")
    num_settings.setDefaultValue(12)
    args << num_settings

    #make a double argument for rated annual consumption
    rated_annual_energy = OpenStudio::Measure::OSArgument::makeDoubleArgument("rated_annual_energy",true)
    rated_annual_energy.setDisplayName("Rated Annual Consumption")
    rated_annual_energy.setUnits("kWh")
    rated_annual_energy.setDescription("The annual energy consumed by the dishwasher, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
    rated_annual_energy.setDefaultValue(290)
    args << rated_annual_energy

    #make a bool argument for internal heater adjustment
    has_internal_heater = OpenStudio::Measure::OSArgument::makeBoolArgument("has_internal_heater",true)
    has_internal_heater.setDisplayName("Internal Heater Adjustment")
    has_internal_heater.setDescription("Does the system use an internal electric heater to adjust water temperature? Input obtained from manufacturer's literature.")
    has_internal_heater.setDefaultValue("true")
    args << has_internal_heater

    #make a bool argument for cold water inlet only
    cold_inlet = OpenStudio::Measure::OSArgument::makeBoolArgument("cold_inlet",true)
    cold_inlet.setDisplayName("Cold Water Inlet Only")
    cold_inlet.setDescription("Does the dishwasher use a cold water connection only.   Input obtained from manufacturer's literature.")
    cold_inlet.setDefaultValue("false")
    args << cold_inlet

    #make a double argument for cold water connection use
    cold_use = OpenStudio::Measure::OSArgument::makeDoubleArgument("cold_use",true)
    cold_use.setDisplayName("Cold Water Conn Use Per Cycle")
    cold_use.setUnits("gal/cycle")
    cold_use.setDescription("Volume of water per cycle used if there is only a cold water inlet connection, for the dishwasher. Input obtained from manufacturer's literature.")
    cold_use.setDefaultValue(0)
    args << cold_use

    #make an integer argument for energy guide date
    test_date = OpenStudio::Measure::OSArgument::makeIntegerArgument("test_date",true)
    test_date.setDisplayName("Energy Guide Date")
    test_date.setDescription("Energy Guide test date.")
    test_date.setDefaultValue(2007)
    args << test_date

    #make a double argument for energy guide annual gas cost
    annual_gas_cost = OpenStudio::Measure::OSArgument::makeDoubleArgument("annual_gas_cost",true)
    annual_gas_cost.setDisplayName("Energy Guide Annual Gas Cost")
    annual_gas_cost.setUnits("$/yr")
    annual_gas_cost.setDescription("Annual cost of gas, as rated.  Obtained from the EnergyGuide label.")
    annual_gas_cost.setDefaultValue(23)
    args << annual_gas_cost

    #make a double argument for occupancy energy multiplier
    mult_e = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult_e",true)
    mult_e.setDisplayName("Occupancy Energy Multiplier")
    mult_e.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
    mult_e.setDefaultValue(1)
    args << mult_e

    #make a double argument for occupancy water multiplier
    mult_hw = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult_hw",true)
    mult_hw.setDisplayName("Occupancy Hot Water Multiplier")
    mult_hw.setDescription("Appliance hot water use is multiplied by this factor to account for occupancy usage that differs from the national average. This should generally be equal to the Occupancy Energy Multiplier.")
    mult_hw.setDefaultValue(1)
    args << mult_hw

    #make a choice argument for location
    location_args = OpenStudio::StringVector.new
    location_args << Constants.Auto
    Geometry.get_model_locations(model).each do |loc|
        location_args << loc
    end
    location = OpenStudio::Measure::OSArgument::makeChoiceArgument("location", location_args, true, true)
    location.setDisplayName("Location")
    location.setDescription("The space type for the location. '#{Constants.Auto}' will automatically choose a space type based on the space types found in the model.")
    location.setDefaultValue(Constants.Auto)
    args << location
    
    #make a choice argument for plant loop
    plant_loops = model.getPlantLoops
    plant_loop_args = OpenStudio::StringVector.new
    plant_loop_args << Constants.Auto
    plant_loops.each do |plant_loop|
        plant_loop_args << plant_loop.name.to_s
    end
    plant_loop = OpenStudio::Measure::OSArgument::makeChoiceArgument("plant_loop", plant_loop_args, true, true)
    plant_loop.setDisplayName("Plant Loop")
    plant_loop.setDescription("Select the plant loop for the dishwasher. '#{Constants.Auto}' will try to choose the plant loop associated with the specified space. For multifamily buildings, '#{Constants.Auto}' will choose the plant loop for each unit of the building.")
    plant_loop.setDefaultValue(Constants.Auto)
	  args << plant_loop
    
    #make an argument for the number of days to shift the draw profile by
    schedule_day_shift = OpenStudio::Measure::OSArgument::makeIntegerArgument("schedule_day_shift",true)
    schedule_day_shift.setDisplayName("Schedule Day Shift")
    schedule_day_shift.setDescription("Draw profiles are shifted to prevent coincident hot water events when performing portfolio analyses. For multifamily buildings, draw profiles for each unit are automatically shifted by one week.")
    schedule_day_shift.setDefaultValue(0)
    args << schedule_day_shift

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
<<<<<<< HEAD
    dw_capacity = runner.getIntegerArgumentValue("num_settings",user_arguments).to_f
    dw_energy_guide_annual_energy = runner.getDoubleArgumentValue("dw_E", user_arguments)
    dw_is_cold_water_inlet_only = runner.getBoolArgumentValue("cold_inlet", user_arguments)
    dw_internal_heater_adjustment = runner.getBoolArgumentValue("int_htr", user_arguments)
    dw_cold_water_conn_use_per_cycle = runner.getDoubleArgumentValue("cold_use", user_arguments)
    dw_energy_guide_date = runner.getIntegerArgumentValue("eg_date", user_arguments)
    dw_energy_guide_annual_gas_cost = runner.getDoubleArgumentValue("eg_gas_cost", user_arguments)
    dw_energy_multiplier = runner.getDoubleArgumentValue("mult_e", user_arguments)
    dw_hot_water_multiplier = runner.getDoubleArgumentValue("mult_hw", user_arguments)
=======
    num_settings = runner.getIntegerArgumentValue("num_settings",user_arguments).to_f
    rated_annual_energy = runner.getDoubleArgumentValue("rated_annual_energy", user_arguments)
    cold_inlet = runner.getBoolArgumentValue("cold_inlet", user_arguments)
    has_internal_heater = runner.getBoolArgumentValue("has_internal_heater", user_arguments)
    cold_use = runner.getDoubleArgumentValue("cold_use", user_arguments)
    test_date = runner.getIntegerArgumentValue("test_date", user_arguments)
    annual_gas_cost = runner.getDoubleArgumentValue("annual_gas_cost", user_arguments)
    mult_e = runner.getDoubleArgumentValue("mult_e", user_arguments)
    mult_hw = runner.getDoubleArgumentValue("mult_hw", user_arguments)
>>>>>>> master
    location = runner.getStringArgumentValue("location",user_arguments)
    plant_loop_s = runner.getStringArgumentValue("plant_loop", user_arguments)
    d_sh = runner.getIntegerArgumentValue("schedule_day_shift",user_arguments)

    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    # Remove all existing objects
    obj_name = Constants.ObjectNameDishwasher
    model.getSpaces.each do |space|
        Dishwasher.remove(runner, space, obj_name)
    end
    
<<<<<<< HEAD
    # Remove all existing objects
    obj_name = Constants.ObjectNameDishwasher
    model.getSpaces.each do |space|
        remove_existing(runner, space, obj_name)
    end
    
=======
>>>>>>> master
    location_hierarchy = [Constants.SpaceTypeKitchen, 
                          Constants.SpaceTypeLiving, 
                          Constants.SpaceTypeLiving, 
                          Constants.SpaceTypeUnfinishedBasement, 
                          Constants.SpaceTypeGarage]

<<<<<<< HEAD
    tot_dw_ann = 0
    msgs = []
    units.each_with_index do |unit, unit_index|
    
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        sch_unit_index = Geometry.get_unit_dhw_sched_index(model, unit, runner)
        if sch_unit_index.nil?
            return false
        end
        
=======
    tot_ann_e = 0
    msgs = []
    mains_temps = nil
    units.each_with_index do |unit, unit_index|
    
>>>>>>> master
        # Get space
        space = Geometry.get_space_from_location(unit, location, location_hierarchy)
        next if space.nil?

        #Get plant loop
        plant_loop = Waterheater.get_plant_loop_from_string(model.getPlantLoops, plant_loop_s, unit, Constants.ObjectNameWaterHeater(unit.name.to_s.gsub("unit ", "")).gsub("|","_"), runner)
        if plant_loop.nil?
            return false
        end
    
<<<<<<< HEAD
        # Get water heater setpoint
        wh_setpoint = Waterheater.get_water_heater_setpoint(model, plant_loop, runner)
        if wh_setpoint.nil?
            return false
        end

        unit_obj_name = Constants.ObjectNameDishwasher(unit.name.to_s)

        # The water used in dishwashers must be heated, either internally or
        # externally, to at least 140 degF for proper operation (dissolving of
        # detergent, cleaning of dishes).
        dw_operating_water_temp = 140 # degF
=======
        success, ann_e, mains_temps = Dishwasher.apply(model, unit, runner, num_settings, rated_annual_energy,
                                                       cold_inlet, has_internal_heater, cold_use, test_date,
                                                       annual_gas_cost, mult_e, mult_hw, d_sh, space, plant_loop, 
                                                       mains_temps, File.dirname(__FILE__))
>>>>>>> master
        
        if not success
            return false
        end
<<<<<<< HEAD
        
        if dw_ann > 0
            
            # Create schedule
            sch = HotWaterSchedule.new(model, runner, Constants.ObjectNameDishwasher + " schedule", Constants.ObjectNameDishwasher + " temperature schedule", nbeds, sch_unit_index, d_sh, "Dishwasher", wh_setpoint, File.dirname(__FILE__))
            if not sch.validated?
                return false
            end
            
            #Reuse existing water use connection if possible
            water_use_connection = nil
            plant_loop.demandComponents.each do |component|
                next unless component.to_WaterUseConnections.is_initialized
                water_use_connection = component.to_WaterUseConnections.get
                break
            end
            if water_use_connection.nil?
                #Need new water heater connection
                water_use_connection = OpenStudio::Model::WaterUseConnections.new(model)
                plant_loop.addDemandBranchForComponent(water_use_connection)
            end
            
            design_level = sch.calcDesignLevelFromDailykWh(daily_energy)
            peak_flow = sch.calcPeakFlowFromDailygpm(daily_dishwasher_water)
            
            #Add electric equipment for the dw
            dw_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
            dw = OpenStudio::Model::ElectricEquipment.new(dw_def)
            dw.setName(unit_obj_name)
            dw.setEndUseSubcategory(unit_obj_name)
            dw.setSpace(space)
            dw_def.setName(unit_obj_name)
            dw_def.setDesignLevel(design_level)
            dw_def.setFractionRadiant(0.36)
            dw_def.setFractionLatent(0.15)
            dw_def.setFractionLost(0.25)
            dw.setSchedule(sch.schedule)
            
            #Add water use equipment for the dw
            dw_def2 = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
            dw2 = OpenStudio::Model::WaterUseEquipment.new(dw_def2)
            dw2.setName(unit_obj_name)
            dw2.setSpace(space)
            dw_def2.setName(unit_obj_name)
            dw_def2.setPeakFlowRate(peak_flow)
            dw_def2.setEndUseSubcategory(unit_obj_name)
            dw2.setFlowRateFractionSchedule(sch.schedule)
            dw_def2.setTargetTemperatureSchedule(sch.temperatureSchedule)
            water_use_connection.addWaterUseEquipment(dw2)
=======
>>>>>>> master

        if ann_e > 0
            msgs << "A dishwasher with #{ann_e.round} kWhs annual energy consumption has been added to plant loop '#{plant_loop.name}' and assigned to space '#{space.name.to_s}'."
        end
        
        tot_ann_e += ann_e
        
    end
	
    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        runner.registerFinalCondition("The building has been assigned dishwashers totaling #{tot_ann_e.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No dishwasher has been assigned.")
    end
    
    return true
 
  end #end the run method
  
<<<<<<< HEAD
  def remove_existing(runner, space, obj_name)
    # Remove any existing dishwasher
    objects_to_remove = []
    space.electricEquipment.each do |space_equipment|
        next if not space_equipment.name.to_s.start_with? obj_name
        objects_to_remove << space_equipment
        objects_to_remove << space_equipment.electricEquipmentDefinition
        if space_equipment.schedule.is_initialized
            objects_to_remove << space_equipment.schedule.get
        end
    end
    space.waterUseEquipment.each do |space_equipment|
        next if not space_equipment.name.to_s.start_with? obj_name
        objects_to_remove << space_equipment
        objects_to_remove << space_equipment.waterUseEquipmentDefinition
        if space_equipment.flowRateFractionSchedule.is_initialized
            objects_to_remove << space_equipment.flowRateFractionSchedule.get
        end
        if space_equipment.waterUseEquipmentDefinition.targetTemperatureSchedule.is_initialized
            objects_to_remove << space_equipment.waterUseEquipmentDefinition.targetTemperatureSchedule.get
        end
    end
    if objects_to_remove.size > 0
        runner.registerInfo("Removed existing dishwasher from space '#{space.name.to_s}'.")
    end
    objects_to_remove.uniq.each do |object|
        begin
            object.remove
        rescue
            # no op
        end
    end
  end

=======
>>>>>>> master
end #end the measure

#this allows the measure to be use by the application
ResidentialDishwasher.new.registerWithApplication