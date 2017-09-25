require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/waterheater"

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
    
    #TODO: New argument for demand response for dws (alternate schedules if automatic DR control is specified)

    #make an integer argument for number of place settings
    num_settings = OpenStudio::Measure::OSArgument::makeIntegerArgument("num_settings",true)
    num_settings.setDisplayName("Number of Place Settings")
    num_settings.setUnits("#")
    num_settings.setDescription("The number of place settings for the unit. Data obtained from manufacturer's literature.")
    num_settings.setDefaultValue(12)
    args << num_settings

    #make a double argument for rated annual consumption
    dw_E = OpenStudio::Measure::OSArgument::makeDoubleArgument("dw_E",true)
    dw_E.setDisplayName("Rated Annual Consumption")
    dw_E.setUnits("kWh")
    dw_E.setDescription("The annual energy consumed by the dishwasher, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
    dw_E.setDefaultValue(290)
    args << dw_E

    #make a bool argument for internal heater adjustment
    int_htr = OpenStudio::Measure::OSArgument::makeBoolArgument("int_htr",true)
    int_htr.setDisplayName("Internal Heater Adjustment")
    int_htr.setDescription("Does the system use an internal electric heater to adjust water temperature? Input obtained from manufacturer's literature.")
    int_htr.setDefaultValue("true")
    args << int_htr

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
    eg_date = OpenStudio::Measure::OSArgument::makeIntegerArgument("eg_date",true)
    eg_date.setDisplayName("Energy Guide Date")
    eg_date.setDescription("Energy Guide test date.")
    eg_date.setDefaultValue(2007)
    args << eg_date

    #make a double argument for energy guide annual gas cost
    eg_gas_cost = OpenStudio::Measure::OSArgument::makeDoubleArgument("eg_gas_cost",true)
    eg_gas_cost.setDisplayName("Energy Guide Annual Gas Cost")
    eg_gas_cost.setUnits("$/yr")
    eg_gas_cost.setDescription("Annual cost of gas, as rated.  Obtained from the EnergyGuide label.")
    eg_gas_cost.setDefaultValue(23)
    args << eg_gas_cost

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
    space.setDescription("Select the space where the dishwasher is located. '#{Constants.Auto}' will choose the lowest above-grade finished space available (e.g., first story living space), or a below-grade finished space as last resort. For multifamily buildings, '#{Constants.Auto}' will choose a space for each unit of the building.")
    space.setDefaultValue(Constants.Auto)
    args << space
    
    #make a choice argument for plant loop
    plant_loops = model.getPlantLoops
    plant_loop_args = OpenStudio::StringVector.new
    plant_loop_args << Constants.Auto
    plant_loops.each do |plant_loop|
        plant_loop_args << plant_loop.name.to_s
    end
    plant_loop = OpenStudio::Measure::OSArgument::makeChoiceArgument("plant_loop", plant_loop_args, true)
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
    dw_capacity = runner.getIntegerArgumentValue("num_settings",user_arguments).to_f
    dw_energy_guide_annual_energy = runner.getDoubleArgumentValue("dw_E", user_arguments)
    dw_is_cold_water_inlet_only = runner.getBoolArgumentValue("cold_inlet", user_arguments)
    dw_internal_heater_adjustment = runner.getBoolArgumentValue("int_htr", user_arguments)
    dw_cold_water_conn_use_per_cycle = runner.getDoubleArgumentValue("cold_use", user_arguments)
    dw_energy_guide_date = runner.getIntegerArgumentValue("eg_date", user_arguments)
    dw_energy_guide_annual_gas_cost = runner.getDoubleArgumentValue("eg_gas_cost", user_arguments)
    dw_energy_multiplier = runner.getDoubleArgumentValue("mult_e", user_arguments)
    dw_hot_water_multiplier = runner.getDoubleArgumentValue("mult_hw", user_arguments)
    space_r = runner.getStringArgumentValue("space",user_arguments)
    plant_loop_s = runner.getStringArgumentValue("plant_loop", user_arguments)
    d_sh = runner.getIntegerArgumentValue("schedule_day_shift",user_arguments)

    #Check for valid inputs
    if dw_capacity < 1
        runner.registerError("Number of place settings must be greater than or equal to 1.")
        return false
    end
    if dw_energy_guide_annual_energy < 0
        runner.registerError("Rated annual energy consumption must be greater than or equal to 0.")
        return false
    end
    if dw_cold_water_conn_use_per_cycle < 0
        runner.registerError("Cold water connection use must be greater than or equal to 0.")
        return false
    end
    if dw_energy_guide_date < 1900
        runner.registerError("Energy Guide date must be greater than or equal to 1900.")
        return false
    end
    if dw_energy_guide_annual_gas_cost <= 0
        runner.registerError("Energy Guide annual gas cost must be greater than 0.")
        return false
    end
    if dw_energy_multiplier < 0
        runner.registerError("Occupancy energy multiplier must be greater than or equal to 0.")
        return false
    end
    if dw_hot_water_multiplier < 0
        runner.registerError("Occupancy hot water multiplier must be greater than or equal to 0.")
        return false
    end
    if d_sh < 0 or d_sh > 364
        runner.registerError("Hot water draw profile can only be shifted by 0-364 days.")
        return false
    end
    
    # Get building units
    units = Geometry.get_building_units(model, runner)
    if units.nil?
        return false
    end
    
    # Get mains monthly temperatures if needed
    if dw_is_cold_water_inlet_only
        site = model.getSite
        if !site.siteWaterMainsTemperature.is_initialized
            runner.registerError("Mains water temperature has not been set.")
            return false
        end
        mainsMonthlyTemps = WeatherProcess.get_mains_temperature(site.siteWaterMainsTemperature.get, site.latitude)[1]
    end
    
    tot_dw_ann = 0
    msgs = []
    units.each do |unit|
        # Get unit beds/baths
        nbeds, nbaths = Geometry.get_unit_beds_baths(model, unit, runner)
        if nbeds.nil? or nbaths.nil?
            return false
        end
        sch_unit_index = Geometry.get_unit_dhw_sched_index(model, unit, runner)
        if sch_unit_index.nil?
            return false
        end
        
        # Get space
        space = Geometry.get_space_from_string(unit.spaces, space_r)
        next if space.nil?

        #Get plant loop
        plant_loop = Waterheater.get_plant_loop_from_string(model.getPlantLoops, plant_loop_s, unit.spaces, Constants.ObjectNameWaterHeater(unit.name.to_s.gsub("unit", "u")).gsub("|","_"), runner)
        if plant_loop.nil?
            return false
        end
    
        # Get water heater setpoint
        wh_setpoint = Waterheater.get_water_heater_setpoint(model, plant_loop, runner)
        if wh_setpoint.nil?
            return false
        end

        obj_name = Constants.ObjectNameDishwasher(unit.name.to_s)

        # Remove any existing dishwasher
        objects_to_remove = []
        space.electricEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != obj_name
            objects_to_remove << space_equipment
            objects_to_remove << space_equipment.electricEquipmentDefinition
            if space_equipment.schedule.is_initialized
                objects_to_remove << space_equipment.schedule.get
            end
        end
        space.waterUseEquipment.each do |space_equipment|
            next if space_equipment.name.to_s != obj_name
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
            runner.registerInfo("Removed existing dishwasher from space #{space.name.to_s}.")
        end
        objects_to_remove.uniq.each do |object|
            begin
                object.remove
            rescue
                # no op
            end
        end
        
        # The water used in dishwashers must be heated, either internally or
        # externally, to at least 140 degF for proper operation (dissolving of
        # detergent, cleaning of dishes).
        dw_operating_water_temp = 140 # degF
        
        water_dens = Liquid.H2O_l.rho # lbm/ft^3
        water_sh = Liquid.H2O_l.cp  # Btu/lbm-R

        # Use EnergyGuide Label test data to calculate per-cycle energy and
        # water consumption. Calculations are based on "Method for
        # Evaluating Energy Use of Dishwashers, Clothes Washers, and
        # Clothes Dryers" by Eastment and Hendron, Conference Paper
        # NREL/CP-550-39769, August 2006. Their paper is in part based on
        # the energy use calculations presented in the 10CFR Part 430,
        # Subpt. B, App. C (DOE 1999),
        # http://ecfr.gpoaccess.gov/cgi/t/text/text-idx?c=ecfr&tpl=/ecfrbrowse/Title10/10cfr430_main_02.tpl
        if dw_energy_guide_date <= 2002
            test_dw_cycles_per_year = 322
        elsif dw_energy_guide_date < 2004
            test_dw_cycles_per_year = 264
        else
            test_dw_cycles_per_year = 215
        end

        # The water heater recovery efficiency - how efficiently the heat
        # from natural gas is transferred to the water in the water heater.
        # The DOE 10CFR Part 430 assumes a nominal gas water heater
        # recovery efficiency of 0.75.
        test_dw_gas_dhw_heater_efficiency = 0.75

        # Cold water supply temperature during tests (see 10CFR Part 430,
        # Subpt. B, App. C, Section 1.19, DOE 1999).
        test_dw_mains_temp = 50 # degF
        # Hot water supply temperature during tests (see 10CFR Part 430,
        # Subpt. B, App. C, Section 1.19, DOE 1999).
        test_dw_dhw_temp = 120 # degF

        # Determine the Gas use for domestic hot water per cycle for test conditions
        if dw_is_cold_water_inlet_only
            test_dw_gas_use_per_cycle = 0 # therms/cycle
        else
            # Use the EnergyGuide Label information (eq. 1 Eastment and
            # Hendron, NREL/CP-550-39769, 2006).
            dw_energy_guide_gas_cost = EnergyGuideLabel.get_energy_guide_gas_cost(dw_energy_guide_date)/100
            dw_energy_guide_elec_cost = EnergyGuideLabel.get_energy_guide_elec_cost(dw_energy_guide_date)/100
            test_dw_gas_use_per_cycle = ((dw_energy_guide_annual_energy * 
                                         dw_energy_guide_elec_cost - 
                                         dw_energy_guide_annual_gas_cost) / 
                                        (OpenStudio.convert(test_dw_gas_dhw_heater_efficiency, "therm", "kWh").get * 
                                         dw_energy_guide_elec_cost - 
                                         dw_energy_guide_gas_cost) / 
                                        test_dw_cycles_per_year) # Therns/cycle
        end
        
        # Use additional EnergyGuide Label information to determine how much
        # electricity was used in the test to power the dishwasher's
        # internal machinery (eq. 2 Eastment and Hendron, NREL/CP-550-39769,
        # 2006). Any energy required for internal water heating will be
        # included in this value.
        test_dw_elec_use_per_cycle = dw_energy_guide_annual_energy / \
                test_dw_cycles_per_year - \
                OpenStudio.convert(test_dw_gas_dhw_heater_efficiency, "therm", "kWh").get * \
                test_dw_gas_use_per_cycle # kWh/cycle

        if dw_is_cold_water_inlet_only
            # for Type 3 Dishwashers - those with an electric element
            # internal to the machine to provide all of the water heating
            # (see Eastment and Hendron, NREL/CP-550-39769, 2006)
            test_dw_dhw_use_per_cycle = 0 # gal/cycle
        else
            if dw_internal_heater_adjustment
                # for Type 2 Dishwashers - those with an electric element
                # internal to the machine for providing auxiliary water
                # heating (see Eastment and Hendron, NREL/CP-550-39769,
                # 2006)
                test_dw_water_heater_temp_diff = test_dw_dhw_temp - \
                        test_dw_mains_temp # degF water heater temperature rise in the test
            else
                test_dw_water_heater_temp_diff = dw_operating_water_temp - \
                        test_dw_mains_temp # water heater temperature rise in the test
            end
            
            # Determine how much hot water was used in the test based on
            # the amount of gas used in the test to heat the water and the
            # temperature rise in the water heater in the test (eq. 3
            # Eastment and Hendron, NREL/CP-550-39769, 2006).
            test_dw_dhw_use_per_cycle = (OpenStudio.convert(test_dw_gas_use_per_cycle, "therm", "kWh").get * \
                                         test_dw_gas_dhw_heater_efficiency) / \
                                         (test_dw_water_heater_temp_diff * \
                                          water_dens * water_sh * \
                                          OpenStudio.convert(1, "Btu", "kWh").get / UnitConversion.ft32gal(1)) # gal/cycle (hot water)
        end
                                          
        # (eq. 16 Eastment and Hendron, NREL/CP-550-39769, 2006)
        actual_dw_cycles_per_year = 215 * (0.5 + nbeds / 6) * (8 / dw_capacity) # cycles/year

        daily_dishwasher_dhw = actual_dw_cycles_per_year * test_dw_dhw_use_per_cycle / 365 # gal/day (hot water)

        # Calculate total (hot or cold) daily water usage.
        if dw_is_cold_water_inlet_only
            # From the 2010 BA Benchmark for dishwasher hot water
            # consumption. Should be appropriate for cold-water-inlet-only
            # dishwashers also.
            daily_dishwasher_water = 2.5 + 0.833 * nbeds # gal/day
        else
            # Dishwasher uses only hot water so total water usage = DHW usage.
            daily_dishwasher_water = daily_dishwasher_dhw # gal/day
        end
        
        # Calculate actual electricity use per cycle by adjusting test
        # electricity use per cycle (up or down) to account for differences
        # between actual water supply temperatures and test conditions.
        # Also convert from per-cycle to daily electricity usage amounts.
        if dw_is_cold_water_inlet_only

            monthly_dishwasher_energy = Array.new(12, 0)
            mainsMonthlyTemps.each_with_index do |monthly_main, i|
                # Adjust for monthly variation in Tmains vs. test cold
                # water supply temperature.
                actual_dw_elec_use_per_cycle = test_dw_elec_use_per_cycle + \
                                               (test_dw_mains_temp - monthly_main) * \
                                               dw_cold_water_conn_use_per_cycle * \
                                               (water_dens * water_sh * OpenStudio.convert(1, "Btu", "kWh").get / 
                                               UnitConversion.ft32gal(1)) # kWh/cycle
                monthly_dishwasher_energy[i] = (actual_dw_elec_use_per_cycle * \
                                                Constants.MonthNumDays[i] * \
                                                actual_dw_cycles_per_year / \
                                                365) # kWh/month
            end

            daily_energy = monthly_dishwasher_energy.inject(:+) / 365 # kWh/day

        elsif dw_internal_heater_adjustment

            # Adjust for difference in water heater supply temperature vs.
            # test hot water supply temperature.
            actual_dw_elec_use_per_cycle = test_dw_elec_use_per_cycle + \
                    (test_dw_dhw_temp - wh_setpoint) * \
                    test_dw_dhw_use_per_cycle * \
                    (water_dens * water_sh * \
                     OpenStudio.convert(1, "Btu", "kWh").get / 
                     UnitConversion.ft32gal(1)) # kWh/cycle
            daily_energy = actual_dw_elec_use_per_cycle * \
                    actual_dw_cycles_per_year / 365 # kWh/day

        else

            # Dishwasher has no internal heater
            actual_dw_elec_use_per_cycle = test_dw_elec_use_per_cycle # kWh/cycle
            daily_energy = actual_dw_elec_use_per_cycle * \
                    actual_dw_cycles_per_year / 365 # kWh/day
        
        end
        
        daily_energy = daily_energy * dw_energy_multiplier
        daily_dishwasher_water = daily_dishwasher_water * dw_hot_water_multiplier

        dw_ann = daily_energy * 365

        if daily_energy < 0
            runner.registerError("The inputs for the dishwasher resulted in a negative amount of energy consumption.")
            return false
        end
        
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
            dw.setName(obj_name)
            dw.setEndUseSubcategory(obj_name)
            dw.setSpace(space)
            dw_def.setName(obj_name)
            dw_def.setDesignLevel(design_level)
            dw_def.setFractionRadiant(0.36)
            dw_def.setFractionLatent(0.15)
            dw_def.setFractionLost(0.25)
            dw.setSchedule(sch.schedule)
            
            #Add water use equipment for the dw
            dw_def2 = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
            dw2 = OpenStudio::Model::WaterUseEquipment.new(dw_def2)
            dw2.setName(obj_name)
            dw2.setSpace(space)
            dw_def2.setName(obj_name)
            dw_def2.setPeakFlowRate(peak_flow)
            dw_def2.setEndUseSubcategory(obj_name)
            dw2.setFlowRateFractionSchedule(sch.schedule)
            dw_def2.setTargetTemperatureSchedule(sch.temperatureSchedule)
            water_use_connection.addWaterUseEquipment(dw2)

            msgs << "A dishwasher with #{dw_ann.round} kWhs annual energy consumption has been added to plant loop '#{plant_loop.name}' and assigned to space '#{space.name.to_s}'."
            
            tot_dw_ann += dw_ann
        end
        
    end
	
    # Reporting
    if msgs.size > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        runner.registerFinalCondition("The building has been assigned dishwashers totaling #{tot_dw_ann.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No dishwasher has been assigned.")
    end
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResidentialDishwasher.new.registerWithApplication