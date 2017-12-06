require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/waterheater"
require "#{File.dirname(__FILE__)}/resources/clothesdryer"

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
    
    #TODO: New argument for demand response for clothes washer (alternate schedules if automatic DR control is specified)

    #make a double argument for Integrated Modified Energy Factor
    cw_imef = OpenStudio::Measure::OSArgument::makeDoubleArgument("imef",true)
    cw_imef.setDisplayName("Integrated Modified Energy Factor")
    cw_imef.setUnits("ft^3/kWh-cycle")
    cw_imef.setDescription("The Integrated Modified Energy Factor (IMEF) is the capacity of the clothes container divided by the total clothes washer energy consumption per cycle, where the energy consumption is the sum of the machine electrical energy consumption, the hot water energy consumption, the energy required for removal of the remaining moisture in the wash load, standby energy, and off-mode energy consumption. If only a Modified Energy Factor (MEF) is available, convert using the equation: IMEF = (MEF - 0.503) / 0.95.")
    cw_imef.setDefaultValue(0.95)
    args << cw_imef

    #make a double argument for Rated Annual Consumption
    cw_rated_annual_energy = OpenStudio::Measure::OSArgument::makeDoubleArgument("rated_annual_energy",true)
    cw_rated_annual_energy.setDisplayName("Rated Annual Consumption")
    cw_rated_annual_energy.setUnits("kWh")
    cw_rated_annual_energy.setDescription("The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
    cw_rated_annual_energy.setDefaultValue(387.0)
    args << cw_rated_annual_energy

    #make a double argument for Annual Cost With Gas DHW
    cw_annual_cost = OpenStudio::Measure::OSArgument::makeDoubleArgument("annual_cost",true)
    cw_annual_cost.setDisplayName("Annual Cost with Gas DHW")
    cw_annual_cost.setUnits("$")
    cw_annual_cost.setDescription("The annual cost of using the system under test conditions.  Input is obtained from the EnergyGuide label.")
    cw_annual_cost.setDefaultValue(24.0)
    args << cw_annual_cost

    #make an integer argument for Test Date
    cw_test_date = OpenStudio::Measure::OSArgument::makeIntegerArgument("test_date",true)
    cw_test_date.setDisplayName("Test Date")
    cw_test_date.setDefaultValue(2007)
    cw_test_date.setDescription("Input obtained from EnergyGuide labels.  The new E-guide labels state that the test was performed under the 2004 DOE procedure, otherwise use year < 2004.")
    args << cw_test_date

    #make a double argument for Drum Volume
    cw_drum_volume = OpenStudio::Measure::OSArgument::makeDoubleArgument("drum_volume",true)
    cw_drum_volume.setDisplayName("Drum Volume")
    cw_drum_volume.setUnits("ft^3")
    cw_drum_volume.setDescription("Volume of the washer drum.  Obtained from the EnergyStar website or the manufacturer's literature.")
    cw_drum_volume.setDefaultValue(3.5)
    args << cw_drum_volume

    #make a boolean argument for Use Cold Cycle Only
    cw_cold_cycle = OpenStudio::Measure::OSArgument::makeBoolArgument("cold_cycle",true)
    cw_cold_cycle.setDisplayName("Use Cold Cycle Only")
    cw_cold_cycle.setDescription("The washer is operated using only the cold cycle.")
    cw_cold_cycle.setDefaultValue(false)
    args << cw_cold_cycle

    #make a boolean argument for Thermostatic Control
    cw_thermostatic_control = OpenStudio::Measure::OSArgument::makeBoolArgument("thermostatic_control",true)
    cw_thermostatic_control.setDisplayName("Thermostatic Control")
    cw_thermostatic_control.setDescription("The clothes washer uses hot and cold water inlet valves to control temperature (varies hot water volume to control wash temperature).  Use this option for machines that use hot and cold inlet valves to control wash water temperature or machines that use both inlet valves AND internal electric heaters to control temperature of the wash water.  Input obtained from the manufacturer's literature.")
    cw_thermostatic_control.setDefaultValue(true)
    args << cw_thermostatic_control

    #make a boolean argument for Has Internal Heater Adjustment
    cw_internal_heater = OpenStudio::Measure::OSArgument::makeBoolArgument("internal_heater",true)
    cw_internal_heater.setDisplayName("Has Internal Heater Adjustment")
    cw_internal_heater.setDescription("The washer uses an internal electric heater to adjust the temperature of wash water.  Use this option for washers that have hot and cold water connections but use an internal electric heater to adjust the wash water temperature.  Obtain the input from the manufacturer's literature.")
    cw_internal_heater.setDefaultValue(false)
    args << cw_internal_heater

    #make a boolean argument for Has Water Level Fill Sensor
    cw_fill_sensor = OpenStudio::Measure::OSArgument::makeBoolArgument("fill_sensor",true)
    cw_fill_sensor.setDisplayName("Has Water Level Fill Sensor")
    cw_fill_sensor.setDescription("The washer has a vertical axis and water level fill sensor.  Input obtained from the manufacturer's literature.")
    cw_fill_sensor.setDefaultValue(false)
    args << cw_fill_sensor

    #make a double argument for occupancy energy multiplier
    cw_mult_e = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult_e",true)
    cw_mult_e.setDisplayName("Occupancy Energy Multiplier")
    cw_mult_e.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
    cw_mult_e.setDefaultValue(1)
    args << cw_mult_e

    #make a double argument for occupancy water multiplier
    cw_mult_hw = OpenStudio::Measure::OSArgument::makeDoubleArgument("mult_hw",true)
    cw_mult_hw.setDisplayName("Occupancy Hot Water Multiplier")
    cw_mult_hw.setDescription("Appliance hot water use is multiplied by this factor to account for occupancy usage that differs from the national average. This should generally be equal to the Occupancy Energy Multiplier.")
    cw_mult_hw.setDefaultValue(1)
    args << cw_mult_hw

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
    space_r = runner.getStringArgumentValue("space",user_arguments)
    plant_loop_s = runner.getStringArgumentValue("plant_loop", user_arguments)
    d_sh = runner.getIntegerArgumentValue("schedule_day_shift",user_arguments)

    #Check for valid inputs
    if cw_imef <= 0
        runner.registerError("Integrated modified energy factor must be greater than 0.0.")
        return false
    end
    if cw_rated_annual_energy <= 0
        runner.registerError("Rated annual consumption must be greater than 0.0.")
        return false
    end
    if cw_annual_cost <= 0
        runner.registerError("Annual cost with gas DHW must be greater than 0.0.")
        return false
    end
    if cw_test_date < 1900
        runner.registerError("Test date must be greater than or equal to 1900.")
        return false
    end
    if cw_drum_volume <= 0
        runner.registerError("Drum volume must be greater than 0.0.")
        return false
    end
    if cw_mult_e < 0
        runner.registerError("Occupancy energy multiplier must be greater than or equal to 0.0.")
        return false
    end
    if cw_mult_hw < 0
        runner.registerError("Occupancy hot water multiplier must be greater than or equal to 0.0.")
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

    # Get mains monthly temperatures
    site = model.getSite
    if !site.siteWaterMainsTemperature.is_initialized
        runner.registerError("Mains water temperature has not been set.")
        return false
    end
    mainsMonthlyTemps = WeatherProcess.get_mains_temperature(site.siteWaterMainsTemperature.get, site.latitude)[1]
    
    tot_cw_ann_e = 0
    
    msgs = []
    cd_msgs = []
    cd_sch = nil
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

        obj_name = Constants.ObjectNameClothesWasher(unit.name.to_s)

        # Remove any existing clothes washer
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
            runner.registerInfo("Removed existing clothes washer from space '#{space.name.to_s}'.")
        end
        objects_to_remove.uniq.each do |object|
            begin
                object.remove
            rescue
                # no op
            end
        end
        
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
        end
                                               
        # Determine the Gas use for domestic hot water per cycle for test conditions
        cw_energy_guide_gas_cost = EnergyGuideLabel.get_energy_guide_gas_cost(cw_test_date)/100
        cw_energy_guide_elec_cost = EnergyGuideLabel.get_energy_guide_elec_cost(cw_test_date)/100
        
        # Use the EnergyGuide Label information (eq. 4 Eastment and Hendron, NREL/CP-550-39769, 2006).
        cw_gas_consumption_for_dhw_per_cycle_test = ((cw_rated_annual_energy * cw_energy_guide_elec_cost - 
                                                    cw_annual_cost) / 
                                                    (OpenStudio.convert(cw_gas_dhw_heater_efficiency_test, "therm", "kWh").get * 
                                                    cw_energy_guide_elec_cost - cw_energy_guide_gas_cost) / 
                                                    cw_cycles_per_year_test) # therms/cycle

        # Use additional EnergyGuide Label information to determine how  much electricity was used in 
        # the test to power the clothes washer's internal machinery (eq. 5 Eastment and Hendron, 
        # NREL/CP-550-39769, 2006). Any energy required for internal water heating will be included
        # in this value.
        cw_elec_use_per_cycle_test = (cw_rated_annual_energy / cw_cycles_per_year_test -
                                     cw_gas_consumption_for_dhw_per_cycle_test * 
                                     OpenStudio.convert(cw_gas_dhw_heater_efficiency_test, "therm", "kWh").get) # kWh/cycle 
        
        if cw_test_date < 2004
            # (see 10CFR Part 430, Subpt. B, App. J, Section 4.1.2, DOE 1999)
            cw_dhw_deltaT_test = 90
        else
            # (see 10CFR Part 430, Subpt. B, App. J1, Section 4.1.2, DOE 1999)
            cw_dhw_deltaT_test = 75
        end

        # Determine how much hot water was used in the test based on the amount of gas used in the 
        # test to heat the water and the temperature rise in the water heater in the test (eq. 6 
        # Eastment and Hendron, NREL/CP-550-39769, 2006).
        water_dens = Liquid.H2O_l.rho # lbm/ft^3
        water_sh = Liquid.H2O_l.cp  # Btu/lbm-R
        cw_dhw_use_per_cycle_test = ((OpenStudio.convert(cw_gas_consumption_for_dhw_per_cycle_test, "therm", "kWh").get * 
                                    cw_gas_dhw_heater_efficiency_test) / (cw_dhw_deltaT_test * 
                                    water_dens * water_sh * OpenStudio.convert(1.0, "Btu", "kWh").get / UnitConversion.ft32gal(1.0)))
         
        if cw_fill_sensor and cw_test_date < 2004
            # For vertical axis washers that are sensor-filled, use a multiplying factor of 0.94 
            # (see 10CFR Part 430, Subpt. B, App. J, Section 4.1.2, DOE 1999)
            cw_dhw_use_per_cycle_test = cw_dhw_use_per_cycle_test / 0.94
        end

        # Calculate total per-cycle usage of water (combined from hot and cold supply).
        # Note that the actual total amount of water used per cycle is assumed to be the same as 
        # the total amount of water used per cycle in the test. Under actual conditions, however, 
        # the ratio of hot and cold water can vary with thermostatic control (see below).
        actual_cw_total_per_cycle_water_use = cw_dhw_use_per_cycle_test / hot_water_vol_frac_test # gal/cycle

        # Set actual clothes washer water temperature for calculations below.
        if cw_cold_cycle
            # To model occupant behavior of using only a cold cycle.
            cw_water_temp = mainsMonthlyTemps.inject(:+)/12 # degF
        elsif cw_thermostatic_control
            # Washer is being operated "normally" - at the same temperature as in the test.
            cw_water_temp = mixed_cycle_temperature_test # degF
        else
            cw_water_temp = wh_setpoint # degF
        end

        # (eq. 14 Eastment and Hendron, NREL/CP-550-39769, 2006)
        actual_cw_cycles_per_year = (cw_cycles_per_year_test * (0.5 + nbeds / 6) * 
                                    (12.5 / cw_test_load)) # cycles/year

        cw_total_daily_water_use = (actual_cw_total_per_cycle_water_use * actual_cw_cycles_per_year / 
                                   365) # gal/day

        # Calculate actual DHW use and elecricity use.
        # First calculate per-cycle usages.
        #    If the clothes washer has thermostatic control, then the test per-cycle DHW usage 
        #    amounts will have to be adjusted (up or down) to account for differences between 
        #    actual water supply temperatures and test conditions. If the clothes washer has 
        #    an internal heater, then the test per-cycle electricity usage amounts will have to 
        #    be adjusted (up or down) to account for differences between actual water supply 
        #    temperatures and hot water amounts and test conditions.
        # The calculations are done on a monthly basis to reflect monthly variations in TMains 
        # temperatures. Per-cycle amounts are then used to calculate monthly amounts and finally 
        # daily amounts.

        monthly_clothes_washer_dhw = Array.new(12, 0)
        monthly_clothes_washer_energy = Array.new(12, 0)

        mainsMonthlyTemps.each_with_index do |monthly_main, i|

            # Adjust per-cycle DHW amount.
            if cw_thermostatic_control
                # If the washer has thermostatic control then its use of DHW will vary as the 
                # cold and hot water supply temperatures vary.

                if cw_cold_cycle and monthly_main >= cw_water_temp
                    # In this special case, the washer uses only a cold cycle and the TMains 
                    # temperature exceeds the desired cold cycle temperature. In this case, no 
                    # DHW will be used (the adjustment is -100%). A special calculation is 
                    # needed here since the formula for the general case (below) would imply
                    # that a negative volume of DHW is used.
                    cw_dhw_use_per_cycle_adjustment = -1 * cw_dhw_use_per_cycle_test # gal/cycle

                else
                    # With thermostatic control, the washer will adjust the amount of hot water 
                    # when either the hot water or cold water supply temperatures vary (eq. 18 
                    # Eastment and Hendron, NREL/CP-550-39769, 2006).
                    cw_dhw_use_per_cycle_adjustment = (cw_dhw_use_per_cycle_test * 
                                                      ((1 / hot_water_vol_frac_test) * 
                                                      (cw_water_temp - monthly_main) + 
                                                      monthly_main - wh_setpoint) / 
                                                      (wh_setpoint - monthly_main)) # gal/cycle
                             
                end

            else
                # Without thermostatic control, the washer will not adjust the amount of hot water.
                cw_dhw_use_per_cycle_adjustment = 0 # gal/cycle
            end

            # Calculate actual water usage amounts for the current month in the loop.
            actual_cw_dhw_use_per_cycle = (cw_dhw_use_per_cycle_test + 
                                          cw_dhw_use_per_cycle_adjustment) # gal/cycle

            # Adjust per-cycle electricity amount.
            if cw_internal_heater
                # If the washer heats the water internally, then its use of electricity will vary 
                # as the cold and hot water supply temperatures vary.

                # Calculate cold water usage per cycle to facilitate calculation of electricity 
                # usage below.
                actual_cw_cold_water_use_per_cycle = (actual_cw_total_per_cycle_water_use - 
                                                     actual_cw_dhw_use_per_cycle) # gal/cycle

                # With an internal heater, the washer will adjust its heating (up or down) when 
                # actual conditions differ from test conditions according to the following three 
                # equations. Compensation for changes in sensible heat due to:
                # 1) a difference in hot water supply temperatures and
                # 2) a difference in cold water supply temperatures
                # (modified version of eq. 20 Eastment and Hendron, NREL/CP-550-39769, 2006).
                cw_elec_use_per_cycle_adjustment_supply_temps = ((actual_cw_dhw_use_per_cycle * 
                                                                (cw_hot_water_inlet_temperature_test - 
                                                                wh_setpoint) + 
                                                                actual_cw_cold_water_use_per_cycle * 
                                                                (cw_cold_water_inlet_temp_test - 
                                                                monthly_main)) * 
                                                                (water_dens * water_sh * 
                                                                OpenStudio.convert(1.0, "Btu", "kWh").get / 
                                                                UnitConversion.ft32gal(1.0))) # kWh/cycle

                # Compensation for the change in sensible heat due to a difference in hot water 
                # amounts due to thermostatic control.
                cw_elec_use_per_cycle_adjustment_hot_water_amount = (cw_dhw_use_per_cycle_adjustment * 
                                                                    (cw_cold_water_inlet_temp_test - 
                                                                    cw_hot_water_inlet_temperature_test) * 
                                                                    (water_dens * water_sh * 
                                                                    OpenStudio.convert(1.0, "Btu", "kWh").get /
                                                                    UnitConversion.ft32gal(1.0))) # kWh/cycle

                # Compensation for the change in sensible heat due to a difference in operating 
                # temperature vs. test temperature (applies only to cold cycle only).
                # Note: This adjustment can result in the calculation of zero electricity use 
                # per cycle below. This would not be correct (the washer will always use some 
                # electricity to operate). However, if the washer has an internal heater, it is 
                # not possible to determine how much of the electricity was  used for internal 
                # heating of water and how much for other machine operations.
                cw_elec_use_per_cycle_adjustment_operating_temp = (actual_cw_total_per_cycle_water_use * 
                                                                  (cw_water_temp - mixed_cycle_temperature_test) * 
                                                                  (water_dens * water_sh * 
                                                                  OpenStudio.convert(1.0, "Btu", "kWh").get / 
                                                                  UnitConversion.ft32gal(1.0))) # kWh/cycle

                # Sum the three adjustments above
                cw_elec_use_per_cycle_adjustment = cw_elec_use_per_cycle_adjustment_supply_temps + 
                                                   cw_elec_use_per_cycle_adjustment_hot_water_amount + 
                                                   cw_elec_use_per_cycle_adjustment_operating_temp

            else

                cw_elec_use_per_cycle_adjustment = 0 # kWh/cycle
                
            end

            # Calculate actual electricity usage amount for the current month in the loop.
            actual_cw_elec_use_per_cycle = (cw_elec_use_per_cycle_test + 
                                           cw_elec_use_per_cycle_adjustment) # kWh/cycle

            # Do not allow negative electricity use
            if actual_cw_elec_use_per_cycle < 0
                actual_cw_elec_use_per_cycle = 0
            end

            # Calculate monthly totals
            monthly_clothes_washer_dhw[i] = ((actual_cw_dhw_use_per_cycle * 
                                            actual_cw_cycles_per_year * 
                                            Constants.MonthNumDays[i] / 365)) # gal/month
            monthly_clothes_washer_energy[i] = ((actual_cw_elec_use_per_cycle * 
                                               actual_cw_cycles_per_year * 
                                               Constants.MonthNumDays[i] / 365)) # kWh/month
        end

        daily_energy = monthly_clothes_washer_energy.inject(:+) / 365
                    
        daily_energy = daily_energy * cw_mult_e
        total_daily_water_use = cw_total_daily_water_use * cw_mult_hw
        
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
            cw.setName(obj_name)
            cw.setEndUseSubcategory(obj_name)
            cw.setSpace(space)
            cw_def.setName(obj_name)
            cw_def.setDesignLevel(design_level)
            cw_def.setFractionRadiant(0.48)
            cw_def.setFractionLatent(0.0)
            cw_def.setFractionLost(0.2)
            cw.setSchedule(sch.schedule)

            #Add water use equipment for the dw
            cw_def2 = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
            cw2 = OpenStudio::Model::WaterUseEquipment.new(cw_def2)
            cw2.setName(obj_name)
            cw2.setSpace(space)
            cw_def2.setName(obj_name)
            cw_def2.setPeakFlowRate(peak_flow)
            cw_def2.setEndUseSubcategory(obj_name)
            cw2.setFlowRateFractionSchedule(sch.schedule)
            cw_def2.setTargetTemperatureSchedule(sch.temperatureSchedule)
            water_use_connection.addWaterUseEquipment(cw2)
            
            msgs << "A clothes washer with #{cw_ann_e.round} kWhs annual energy consumption has been added to plant loop '#{plant_loop.name}' and assigned to space '#{space.name.to_s}'."
            
            tot_cw_ann_e += cw_ann_e
            
            # Store some info for Clothes Dryer measures
            unit.setFeature(Constants.ClothesWasherIMEF(cw), cw_imef)
            unit.setFeature(Constants.ClothesWasherRatedAnnualEnergy(cw), cw_rated_annual_energy)
            unit.setFeature(Constants.ClothesWasherDrumVolume(cw), cw_drum_volume)
            
            # Check if there's a clothes dryer that needs to be updated
            cd = nil
            model.getElectricEquipments.each do |ee|
                next if not ee.name.to_s.start_with?(Constants.ObjectNameClothesDryer(nil))
                cd = ee
            end
            model.getOtherEquipments.each do |oe|
                next if not oe.name.to_s.start_with?(Constants.ObjectNameClothesDryer(nil))
                cd = oe
            end
            next if cd.nil?
            
            # Get clothes dryer properties
            cd_cef = unit.getFeatureAsDouble(Constants.ClothesDryerCEF(cd))
            cd_mult = unit.getFeatureAsDouble(Constants.ClothesDryerMult(cd))
            cd_weekday_sch = unit.getFeatureAsString(Constants.ClothesDryerWeekdaySch(cd))
            cd_weekend_sch = unit.getFeatureAsString(Constants.ClothesDryerWeekendSch(cd))
            cd_monthly_sch = unit.getFeatureAsString(Constants.ClothesDryerMonthlySch(cd))
            cd_fuel_type = unit.getFeatureAsString(Constants.ClothesDryerFuelType(cd))
            cd_fuel_split = unit.getFeatureAsDouble(Constants.ClothesDryerFuelSplit(cd))
            if !cd_cef.is_initialized or !cd_mult.is_initialized or !cd_weekday_sch.is_initialized or !cd_weekend_sch.is_initialized or !cd_monthly_sch.is_initialized or !cd_fuel_type.is_initialized or !cd_fuel_split.is_initialized
                runner.registerError("Could not find clothes dryer properties.")
                return false
            end
            cd_cef = cd_cef.get
            cd_mult = cd_mult.get
            cd_weekday_sch = cd_weekday_sch.get
            cd_weekend_sch = cd_weekend_sch.get
            cd_monthly_sch = cd_monthly_sch.get
            cd_fuel_type = cd_fuel_type.get
            cd_fuel_split = cd_fuel_split.get
            
            # Update clothes dryer
            success, cd_ann_e, cd_ann_f, cd_sch = ClothesDryer.apply(model, unit, runner, cd_sch, cd_cef, cd_mult, cd_weekday_sch, cd_weekend_sch, cd_monthly_sch, 
                                                                     cd.space.get, cd_fuel_type, cd_fuel_split, false)
            
            if not success
                return false
            end
            
            next if cd_ann_e == 0 and cd_ann_f == 0
            
            cd_msgs << "The clothes dryer assigned to space '#{space.name.to_s}' has been updated."
            
        end
        
    end
    
    # Reporting
    if (msgs.size + cd_msgs.size) > 1
        msgs.each do |msg|
            runner.registerInfo(msg)
        end
        cd_msgs.each do |cd_msg|
            runner.registerInfo(cd_msg)
        end
        runner.registerFinalCondition("The building has been assigned clothes washers totaling #{tot_cw_ann_e.round} kWhs annual energy consumption across #{units.size} units.")
    elsif msgs.size == 1
        runner.registerFinalCondition(msgs[0])
    else
        runner.registerFinalCondition("No clothes washer has been assigned.")
    end
    
    return true
	
  end

end #end the measure

#this allows the measure to be use by the application
ResidentialClothesWasher.new.registerWithApplication