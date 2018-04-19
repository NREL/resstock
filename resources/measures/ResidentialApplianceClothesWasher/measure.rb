require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/waterheater"
require "#{File.dirname(__FILE__)}/resources/appliances"

#start the measure
class ResidentialClothesWasher < OpenStudio::Measure::ModelMeasure
  
  def name
    return "Set Residential Clothes Washer"
  end

  def description
    return "Adds (or replaces) a residential clothes washer with the specified efficiency, operation, and schedule. For multifamily buildings, the clothes washer can be set for all units of the building.#{Constants.WorkflowDescription}"
  end
  
  def modeler_description
    return "Since there is no Clothes Washer object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential clothes washer. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make a double argument for Integrated Modified Energy Factor
    imef = OpenStudio::Measure::OSArgument::makeDoubleArgument("imef",true)
    imef.setDisplayName("Integrated Modified Energy Factor")
    imef.setUnits("ft^3/kWh-cycle")
    imef.setDescription("The Integrated Modified Energy Factor (IMEF) is the capacity of the clothes container divided by the total clothes washer energy consumption per cycle, where the energy consumption is the sum of the machine electrical energy consumption, the hot water energy consumption, the energy required for removal of the remaining moisture in the wash load, standby energy, and off-mode energy consumption. If only a Modified Energy Factor (MEF) is available, convert using the equation: IMEF = (MEF - 0.503) / 0.95.")
    imef.setDefaultValue(0.95)
    args << imef

    #make a double argument for Rated Annual Consumption
    rated_annual_energy = OpenStudio::Measure::OSArgument::makeDoubleArgument("rated_annual_energy",true)
    rated_annual_energy.setDisplayName("Rated Annual Consumption")
    rated_annual_energy.setUnits("kWh")
    rated_annual_energy.setDescription("The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
    rated_annual_energy.setDefaultValue(387.0)
    args << rated_annual_energy

    #make a double argument for Annual Cost With Gas DHW
    annual_cost = OpenStudio::Measure::OSArgument::makeDoubleArgument("annual_cost",true)
    annual_cost.setDisplayName("Annual Cost with Gas DHW")
    annual_cost.setUnits("$")
    annual_cost.setDescription("The annual cost of using the system under test conditions.  Input is obtained from the EnergyGuide label.")
    annual_cost.setDefaultValue(24.0)
    args << annual_cost

    #make an integer argument for Test Date
    test_date = OpenStudio::Measure::OSArgument::makeIntegerArgument("test_date",true)
    test_date.setDisplayName("Test Date")
    test_date.setDefaultValue(2007)
    test_date.setDescription("Input obtained from EnergyGuide labels.  The new E-guide labels state that the test was performed under the 2004 DOE procedure, otherwise use year < 2004.")
    args << test_date

    #make a double argument for Drum Volume
    drum_volume = OpenStudio::Measure::OSArgument::makeDoubleArgument("drum_volume",true)
    drum_volume.setDisplayName("Drum Volume")
    drum_volume.setUnits("ft^3")
    drum_volume.setDescription("Volume of the washer drum.  Obtained from the EnergyStar website or the manufacturer's literature.")
    drum_volume.setDefaultValue(3.5)
    args << drum_volume

    #make a boolean argument for Use Cold Cycle Only
    cold_cycle = OpenStudio::Measure::OSArgument::makeBoolArgument("cold_cycle",true)
    cold_cycle.setDisplayName("Use Cold Cycle Only")
    cold_cycle.setDescription("The washer is operated using only the cold cycle.")
    cold_cycle.setDefaultValue(false)
    args << cold_cycle

    #make a boolean argument for Thermostatic Control
    thermostatic_control = OpenStudio::Measure::OSArgument::makeBoolArgument("thermostatic_control",true)
    thermostatic_control.setDisplayName("Thermostatic Control")
    thermostatic_control.setDescription("The clothes washer uses hot and cold water inlet valves to control temperature (varies hot water volume to control wash temperature).  Use this option for machines that use hot and cold inlet valves to control wash water temperature or machines that use both inlet valves AND internal electric heaters to control temperature of the wash water.  Input obtained from the manufacturer's literature.")
    thermostatic_control.setDefaultValue(true)
    args << thermostatic_control

    #make a boolean argument for Has Internal Heater Adjustment
    internal_heater = OpenStudio::Measure::OSArgument::makeBoolArgument("internal_heater",true)
    internal_heater.setDisplayName("Has Internal Heater Adjustment")
    internal_heater.setDescription("The washer uses an internal electric heater to adjust the temperature of wash water.  Use this option for washers that have hot and cold water connections but use an internal electric heater to adjust the wash water temperature.  Obtain the input from the manufacturer's literature.")
    internal_heater.setDefaultValue(false)
    args << internal_heater

    #make a boolean argument for Has Water Level Fill Sensor
    fill_sensor = OpenStudio::Measure::OSArgument::makeBoolArgument("fill_sensor",true)
    fill_sensor.setDisplayName("Has Water Level Fill Sensor")
    fill_sensor.setDescription("The washer has a vertical axis and water level fill sensor.  Input obtained from the manufacturer's literature.")
    fill_sensor.setDefaultValue(false)
    args << fill_sensor

    #make a double argument for occupancy energy multiplier
    mult_e = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult_e",true)
    mult_e.setDisplayName("Occupancy Energy Multiplier")
    mult_e.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
    mult_e.setDefaultValue(1)
    args << mult_e

    #make a double argument for occupancy water multiplier
<<<<<<< HEAD
    cw_mult_hw = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult_hw",true)
    cw_mult_hw.setDisplayName("Occupancy Hot Water Multiplier")
    cw_mult_hw.setDescription("Appliance hot water use is multiplied by this factor to account for occupancy usage that differs from the national average. This should generally be equal to the Occupancy Energy Multiplier.")
    cw_mult_hw.setDefaultValue(1)
    args << cw_mult_hw
=======
    mult_hw = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult_hw",true)
    mult_hw.setDisplayName("Occupancy Hot Water Multiplier")
    mult_hw.setDescription("Appliance hot water use is multiplied by this factor to account for occupancy usage that differs from the national average. This should generally be equal to the Occupancy Energy Multiplier.")
    mult_hw.setDefaultValue(1)
    args << mult_hw
>>>>>>> master

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
    cw_imef = runner.getDoubleArgumentValue("imef",user_arguments)
    cw_rated_annual_energy = runner.getDoubleArgumentValue("rated_annual_energy",user_arguments)
    cw_annual_cost = runner.getDoubleArgumentValue("annual_cost",user_arguments)
    cw_test_date = runner.getIntegerArgumentValue("test_date", user_arguments)
    cw_drum_volume = runner.getDoubleArgumentValue("drum_volume",user_arguments)
    cw_cold_cycle = runner.getBoolArgumentValue("cold_cycle",user_arguments)
    cw_thermostatic_control = runner.getBoolArgumentValue("thermostatic_control",user_arguments)
    cw_internal_heater = runner.getBoolArgumentValue("internal_heater",user_arguments)
    cw_fill_sensor = runner.getBoolArgumentValue("fill_sensor",user_arguments)
    cw_mult_e = runner.getDoubleArgumentValue("mult_e",user_arguments)
    cw_mult_hw = runner.getDoubleArgumentValue("mult_hw",user_arguments)
=======
    imef = runner.getDoubleArgumentValue("imef",user_arguments)
    rated_annual_energy = runner.getDoubleArgumentValue("rated_annual_energy",user_arguments)
    annual_cost = runner.getDoubleArgumentValue("annual_cost",user_arguments)
    test_date = runner.getIntegerArgumentValue("test_date", user_arguments)
    drum_volume = runner.getDoubleArgumentValue("drum_volume",user_arguments)
    cold_cycle = runner.getBoolArgumentValue("cold_cycle",user_arguments)
    thermostatic_control = runner.getBoolArgumentValue("thermostatic_control",user_arguments)
    internal_heater = runner.getBoolArgumentValue("internal_heater",user_arguments)
    fill_sensor = runner.getBoolArgumentValue("fill_sensor",user_arguments)
    mult_e = runner.getDoubleArgumentValue("mult_e",user_arguments)
    mult_hw = runner.getDoubleArgumentValue("mult_hw",user_arguments)
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
    obj_name = Constants.ObjectNameClothesWasher
    model.getSpaces.each do |space|
        ClothesWasher.remove(runner, space, obj_name)
    end
<<<<<<< HEAD
    mainsMonthlyTemps = WeatherProcess.get_mains_temperature(site.siteWaterMainsTemperature.get, site.latitude)[1]
    
    # Remove all existing objects
    obj_name = Constants.ObjectNameClothesWasher
    model.getSpaces.each do |space|
        remove_existing(runner, space, obj_name)
    end
=======
>>>>>>> master
    
    location_hierarchy = [Constants.SpaceTypeLaundryRoom, 
                          Constants.SpaceTypeLiving, 
                          Constants.SpaceTypeFinishedBasement, 
                          Constants.SpaceTypeUnfinishedBasement, 
                          Constants.SpaceTypeGarage]

<<<<<<< HEAD
    tot_cw_ann_e = 0
    msgs = []
    cd_msgs = []
    cd_sch = nil
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
    cd_msgs = []
    cd_sch = nil
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

        unit_obj_name = Constants.ObjectNameClothesWasher(unit.name.to_s)

        # Use EnergyGuide Label test data to calculate per-cycle energy and water consumption.
        # Calculations are based on "Method for Evaluating Energy Use of Dishwashers, Clothes Washers, 
        # and Clothes Dryers" by Eastment and Hendron, Conference Paper NREL/CP-550-39769, August 2006.
        # Their paper is in part based on the energy use calculations  presented in the 10CFR Part 430,
        # Subpt. B, App. J1 (DOE 1999),
        # http://ecfr.gpoaccess.gov/cgi/t/text/text-idx?c=ecfr&tpl=/ecfrbrowse/Title10/10cfr430_main_02.tpl

        # Set the number of cycles per year for test conditions
        cw_cycles_per_year_test = 392 # (see Eastment and Hendron, NREL/CP-550-39769, 2006)

        # The water heater recovery efficiency - how efficiently the heat from natural gas is transferred 
        # to the water in the water heater. The DOE 10CFR Part 430 assumes a nominal gas water heater
        # recovery efficiency of 0.75.
        cw_gas_dhw_heater_efficiency_test = 0.75

        # Calculate test load weight (correlation based on data in Table 5.1 of 10CFR Part 430,
        # Subpt. B, App. J1, DOE 1999)
        cw_test_load = 4.103003337 * cw_drum_volume + 0.198242492 # lb

        # Set the Hot Water Inlet Temperature for test conditions
        if cw_test_date < 2004
            # (see 10CFR Part 430, Subpt. B, App. J, Section 2.3, DOE 1999)
            cw_hot_water_inlet_temperature_test = 140 # degF
        elsif cw_test_date >= 2004
            # (see 10CFR Part 430, Subpt. B, App. J1, Section 2.3, DOE 1999)
            cw_hot_water_inlet_temperature_test = 135 # degF
        end

        # Set the cold water inlet temperature for test conditions (see 10CFR Part 430, Subpt. B, App. J, 
        # Section 2.3, DOE 1999)
        cw_cold_water_inlet_temp_test = 60 #degF

        # Set/calculate the hot water fraction and mixed water temperature for test conditions.
        # Washer varies relative amounts of hot and cold water (by opening and closing valves) to achieve 
        # a specific wash temperature. This includes the option to simulate washers operating on cold
        # cycle only (cw_cold_cycle = True). This is an operating choice for the occupant - the 
        # washer itself was tested under normal test conditions (not cold cycle).
        if cw_thermostatic_control
            # (see p. 10 of Eastment and Hendron, NREL/CP-550-39769, 2006)
            mixed_cycle_temperature_test = 92.5 # degF
            # (eq. 17 Eastment and Hendron, NREL/CP-550-39769, 2006)
            hot_water_vol_frac_test = ((mixed_cycle_temperature_test - cw_cold_water_inlet_temp_test) / 
                                      (cw_hot_water_inlet_temperature_test - cw_cold_water_inlet_temp_test))
        else
            # Note: if washer only has cold water supply then the following code will run and 
            # incorrectly set the hot water fraction to 0.5. However, the code below will correctly 
            # determine hot and cold water usage.
            hot_water_vol_frac_test = 0.5
            mixed_cycle_temperature_test = ((cw_hot_water_inlet_temperature_test - cw_cold_water_inlet_temp_test) * \
                                           hot_water_vol_frac_test + cw_cold_water_inlet_temp_test) # degF
=======
        success, ann_e, cd_updated, cd_sch, mains_temps = ClothesWasher.apply(model, unit, runner, imef, rated_annual_energy, annual_cost,
                                                                              test_date, drum_volume, cold_cycle, thermostatic_control,
                                                                              internal_heater, fill_sensor, mult_e, mult_hw, d_sh, cd_sch,
                                                                              space, plant_loop, mains_temps, File.dirname(__FILE__))
        
        if not success
            return false
>>>>>>> master
        end
        
        if ann_e > 0
            msgs << "A clothes washer with #{ann_e.round} kWhs annual energy consumption has been added to plant loop '#{plant_loop.name}' and assigned to space '#{space.name.to_s}'."
        end
        
<<<<<<< HEAD
        cw_ann_e = daily_energy * 365
    
        if cw_ann_e > 0
        
            # Create schedule
            sch = HotWaterSchedule.new(model, runner, Constants.ObjectNameClothesWasher + " schedule", Constants.ObjectNameClothesWasher + " temperature schedule", nbeds, sch_unit_index, d_sh, "ClothesWasher", cw_water_temp, File.dirname(__FILE__))
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
            peak_flow = sch.calcPeakFlowFromDailygpm(total_daily_water_use)

            #Add equipment for the cw
            cw_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
            cw = OpenStudio::Model::ElectricEquipment.new(cw_def)
            cw.setName(unit_obj_name)
            cw.setEndUseSubcategory(unit_obj_name)
            cw.setSpace(space)
            cw_def.setName(unit_obj_name)
            cw_def.setDesignLevel(design_level)
            cw_def.setFractionRadiant(0.48)
            cw_def.setFractionLatent(0.0)
            cw_def.setFractionLost(0.2)
            cw.setSchedule(sch.schedule)

            #Add water use equipment for the dw
            cw_def2 = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
            cw2 = OpenStudio::Model::WaterUseEquipment.new(cw_def2)
            cw2.setName(unit_obj_name)
            cw2.setSpace(space)
            cw_def2.setName(unit_obj_name)
            cw_def2.setPeakFlowRate(peak_flow)
            cw_def2.setEndUseSubcategory(unit_obj_name)
            cw2.setFlowRateFractionSchedule(sch.schedule)
            cw_def2.setTargetTemperatureSchedule(sch.temperatureSchedule)
            water_use_connection.addWaterUseEquipment(cw2)
            
            msgs << "A clothes washer with #{cw_ann_e.round} kWhs annual energy consumption has been added to plant loop '#{plant_loop.name}' and assigned to space '#{space.name.to_s}'."
            
            tot_cw_ann_e += cw_ann_e
            
            # Store some info for Clothes Dryer measures
            unit.setFeature(Constants.ClothesWasherIMEF(cw), cw_imef)
            unit.setFeature(Constants.ClothesWasherRatedAnnualEnergy(cw), cw_rated_annual_energy)
            unit.setFeature(Constants.ClothesWasherDrumVolume(cw), cw_drum_volume)
            unit.setFeature(Constants.ClothesWasherDayShift(cw), d_sh.to_f)
            
            # Check if there's a clothes dryer that needs to be updated
            cd_unit_obj_name = Constants.ObjectNameClothesDryer(nil)
            cd = nil
            model.getElectricEquipments.each do |ee|
                next if not ee.name.to_s.start_with? cd_unit_obj_name
                next if not unit.spaces.include? ee.space.get
                cd = ee
            end
            model.getOtherEquipments.each do |oe|
                next if not oe.name.to_s.start_with? cd_unit_obj_name
                next if not unit.spaces.include? oe.space.get
                cd = oe
            end
            next if cd.nil?
            
            # Get clothes dryer properties
            cd_cef = unit.getFeatureAsDouble(Constants.ClothesDryerCEF(cd))
            cd_mult = unit.getFeatureAsDouble(Constants.ClothesDryerMult(cd))
            cd_fuel_type = unit.getFeatureAsString(Constants.ClothesDryerFuelType(cd))
            cd_fuel_split = unit.getFeatureAsDouble(Constants.ClothesDryerFuelSplit(cd))
            
            if !cd_cef.is_initialized or !cd_mult.is_initialized or !cd_fuel_type.is_initialized or !cd_fuel_split.is_initialized
                runner.registerError("Could not find clothes dryer properties.")
                return false
            end
            cd_cef = cd_cef.get
            cd_mult = cd_mult.get
            cd_fuel_type = cd_fuel_type.get
            cd_fuel_split = cd_fuel_split.get
            
            # Update clothes dryer
            cd_space = cd.space.get
            ClothesDryer.remove_existing(runner, cd_space, cd_unit_obj_name, false)
            success, cd_ann_e, cd_ann_f, cd_sch = ClothesDryer.apply(model, unit, runner, cd_sch, cd_cef, cd_mult, 
                                                                     cd_space, cd_fuel_type, cd_fuel_split)
            
            if not success
                return false
            end
            
            next if cd_ann_e == 0 and cd_ann_f == 0
            
=======
        if cd_updated
>>>>>>> master
            cd_msgs << "The clothes dryer assigned to space '#{space.name.to_s}' has been updated."
        end
        
        tot_ann_e += ann_e
        
    end
    
    # Reporting
    if (msgs.size + cd_msgs.size) > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        cd_msgs.each do |cd_msg|
            runner.registerInfo(cd_msg)
        end
        runner.registerFinalCondition("The building has been assigned clothes washers totaling #{tot_ann_e.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No clothes washer has been assigned.")
    end
    
    return true
	
  end
  
<<<<<<< HEAD
  def remove_existing(runner, space, obj_name)
    # Remove any existing clothes washer
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
        runner.registerInfo("Removed existing clothes washer from space '#{space.name.to_s}'.")
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
ResidentialClothesWasher.new.registerWithApplication