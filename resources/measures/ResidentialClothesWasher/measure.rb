require "#{File.dirname(__FILE__)}/resources/schedules"
require "#{File.dirname(__FILE__)}/resources/constants"
require "#{File.dirname(__FILE__)}/resources/util"
require "#{File.dirname(__FILE__)}/resources/weather"
require "#{File.dirname(__FILE__)}/resources/unit_conversions"
require "#{File.dirname(__FILE__)}/resources/geometry"
require "#{File.dirname(__FILE__)}/resources/waterheater"

#start the measure
class ResidentialClothesWasher < OpenStudio::Ruleset::ModelUserScript
  
  def name
    return "Set Residential Clothes Washer"
  end

  def description
    return "Adds (or replaces) a residential clothes washer with the specified efficiency, operation, and schedule in the given space."
  end
  
  def modeler_description
    return "Since there is no Clothes Washer object in OpenStudio/EnergyPlus, we look for an ElectricEquipment object with the name that denotes it is a residential clothes washer. If one is found, it is replaced with the specified properties. Otherwise, a new such object is added to the model. Note: This measure requires the number of bedrooms/bathrooms to have already been assigned."
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
	#TODO: New argument for demand response for clothes washer (alternate schedules if automatic DR control is specified)

	#make a double argument for Modified Energy Factor
	cw_mef = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cw_mef",true)
	cw_mef.setDisplayName("Energy Factor")
    cw_mef.setUnits("ft^3/kWh-cycle")
    cw_mef.setDescription("The Modified Energy Factor (MEF) is the quotient of the capacity of the clothes container, C, divided by the total clothes washer energy consumption per cycle, with such energy consumption expressed as the sum of the machine electrical energy consumption, M, the hot water energy consumption, E, and the energy required for removal of the remaining moisture in the wash load, D. The higher the value, the more efficient the clothes washer is. Procedures to test MEF are defined by the Department of Energy (DOE) in 10 Code of Federal Regulations Part 430, Appendix J to Subpart B.")
	cw_mef.setDefaultValue(1.41)
	args << cw_mef
    
    #make a double argument for Rated Annual Consumption
    cw_rated_annual_energy = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cw_rated_annual_energy",true)
	cw_rated_annual_energy.setDisplayName("Rated Annual Consumption")
    cw_rated_annual_energy.setUnits("kWh")
    cw_rated_annual_energy.setDescription("The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.")
	cw_rated_annual_energy.setDefaultValue(387.0)
	args << cw_rated_annual_energy
    
    #make a double argument for Annual Cost With Gas DHW
    cw_annual_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cw_annual_cost",true)
	cw_annual_cost.setDisplayName("Annual Cost with Gas DHW")
    cw_annual_cost.setUnits("$")
    cw_annual_cost.setDescription("The annual cost of using the system under test conditions.  Input is obtained from the EnergyGuide label.")
	cw_annual_cost.setDefaultValue(24.0)
	args << cw_annual_cost
	
	#make an integer argument for Test Date
	cw_test_date = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("cw_test_date",true)
	cw_test_date.setDisplayName("Test Date")
	cw_test_date.setDefaultValue(2007)
    cw_test_date.setDescription("Input obtained from EnergyGuide labels.  The new E-guide labels state that the test was performed under the 2004 DOE procedure, otherwise use year < 2004.")
	args << cw_test_date

	#make a double argument for Drum Volume
	cw_drum_volume = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cw_drum_volume",true)
	cw_drum_volume.setDisplayName("Drum Volume")
    cw_drum_volume.setUnits("ft^3")
    cw_drum_volume.setDescription("Volume of the washer drum.  Obtained from the EnergyStar website or the manufacturer's literature.")
	cw_drum_volume.setDefaultValue(3.5)
	args << cw_drum_volume
    
    #make a boolean argument for Use Cold Cycle Only
	cw_cold_cycle = OpenStudio::Ruleset::OSArgument::makeBoolArgument("cw_cold_cycle",true)
	cw_cold_cycle.setDisplayName("Use Cold Cycle Only")
	cw_cold_cycle.setDescription("The washer is operated using only the cold cycle.")
	cw_cold_cycle.setDefaultValue(false)
	args << cw_cold_cycle

    #make a boolean argument for Thermostatic Control
	cw_thermostatic_control = OpenStudio::Ruleset::OSArgument::makeBoolArgument("cw_thermostatic_control",true)
	cw_thermostatic_control.setDisplayName("Thermostatic Control")
	cw_thermostatic_control.setDescription("The clothes washer uses hot and cold water inlet valves to control temperature (varies hot water volume to control wash temperature).  Use this option for machines that use hot and cold inlet valves to control wash water temperature or machines that use both inlet valves AND internal electric heaters to control temperature of the wash water.  Input obtained from the manufacturer's literature.")
	cw_thermostatic_control.setDefaultValue(true)
	args << cw_thermostatic_control

    #make a boolean argument for Has Internal Heater Adjustment
	cw_internal_heater = OpenStudio::Ruleset::OSArgument::makeBoolArgument("cw_internal_heater",true)
	cw_internal_heater.setDisplayName("Has Internal Heater Adjustment")
	cw_internal_heater.setDescription("The washer uses an internal electric heater to adjust the temperature of wash water.  Use this option for washers that have hot and cold water connections but use an internal electric heater to adjust the wash water temperature.  Obtain the input from the manufacturer's literature.")
	cw_internal_heater.setDefaultValue(false)
	args << cw_internal_heater

    #make a boolean argument for Has Water Level Fill Sensor
	cw_fill_sensor = OpenStudio::Ruleset::OSArgument::makeBoolArgument("cw_fill_sensor",true)
	cw_fill_sensor.setDisplayName("Has Water Level Fill Sensor")
	cw_fill_sensor.setDescription("The washer has a vertical axis and water level fill sensor.  Input obtained from the manufacturer's literature.")
	cw_fill_sensor.setDefaultValue(false)
	args << cw_fill_sensor

  	#make a double argument for occupancy energy multiplier
	cw_mult_e = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cw_mult_e",true)
	cw_mult_e.setDisplayName("Occupancy Energy Multiplier")
	cw_mult_e.setDescription("Appliance energy use is multiplied by this factor to account for occupancy usage that differs from the national average.")
	cw_mult_e.setDefaultValue(1)
	args << cw_mult_e

  	#make a double argument for occupancy water multiplier
	cw_mult_hw = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cw_mult_hw",true)
	cw_mult_hw.setDisplayName("Occupancy Hot Water Multiplier")
	cw_mult_hw.setDescription("Appliance hot water use is multiplied by this factor to account for occupancy usage that differs from the national average. This should generally be equal to the Occupancy Energy Multiplier.")
	cw_mult_hw.setDefaultValue(1)
	args << cw_mult_hw

    #make a choice argument for space
    spaces = model.getSpaces
    space_args = OpenStudio::StringVector.new
    spaces.each do |space|
        space_args << space.name.to_s
    end
    if space_args.empty?
        space_args << Constants.LivingSpace(1)
    end
    space = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space", space_args, true)
    space.setDisplayName("Location")
    space.setDescription("Select the space where the clothes washer is located")
    if space_args.include?(Constants.LivingSpace(1))
        space.setDefaultValue(Constants.LivingSpace(1))
    end
    args << space
    
    #make a choice argument for plant loop
    plant_loops = model.getPlantLoops
    plant_loop_args = OpenStudio::StringVector.new
    plant_loops.each do |plant_loop|
        plant_loop_args << plant_loop.name.to_s
    end
    if plant_loop_args.empty?
        plant_loop_args << Constants.PlantLoopDomesticWater
    end
    plant_loop = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("plant_loop", plant_loop_args, true)
    plant_loop.setDisplayName("Plant Loop")
    plant_loop.setDescription("Select the plant loop for the clothes washer")
    if plant_loop_args.include?(Constants.PlantLoopDomesticWater)
        plant_loop.setDefaultValue(Constants.PlantLoopDomesticWater)
    end
	args << plant_loop
    
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
	cw_mef = runner.getDoubleArgumentValue("cw_mef",user_arguments)
    cw_rated_annual_energy = runner.getDoubleArgumentValue("cw_rated_annual_energy",user_arguments)
    cw_annual_cost = runner.getDoubleArgumentValue("cw_annual_cost",user_arguments)
	cw_test_date = runner.getIntegerArgumentValue("cw_test_date", user_arguments)
	cw_drum_volume = runner.getDoubleArgumentValue("cw_drum_volume",user_arguments)
    cw_cold_cycle = runner.getBoolArgumentValue("cw_cold_cycle",user_arguments)
    cw_thermostatic_control = runner.getBoolArgumentValue("cw_thermostatic_control",user_arguments)
    cw_internal_heater = runner.getBoolArgumentValue("cw_internal_heater",user_arguments)
    cw_fill_sensor = runner.getBoolArgumentValue("cw_fill_sensor",user_arguments)
	cw_mult_e = runner.getDoubleArgumentValue("cw_mult_e",user_arguments)
    cw_mult_hw = runner.getDoubleArgumentValue("cw_mult_hw",user_arguments)
	space_r = runner.getStringArgumentValue("space",user_arguments)
    plant_loop_s = runner.getStringArgumentValue("plant_loop", user_arguments)

    #Check for valid inputs
    if cw_mef <= 0
        runner.registerError("Modified energy factor must be greater than 0.0.")
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
	
    #Get space
    space = Geometry.get_space_from_string(model.getSpaces, space_r, runner)
    if space.nil?
        return false
    end

    #Get plant loop
    plant_loop = HelperMethods.get_plant_loop_from_string(model, plant_loop_s, runner)
    if plant_loop.nil?
        return false
    end
    
    # Get number of bedrooms/bathrooms
    nbeds, nbaths, unit_spaces = Geometry.get_unit_beds_baths_spaces(model, 1, runner)
    if nbeds.nil? or nbaths.nil?
        runner.registerError("Could not determine number of bedrooms or bathrooms. Run the 'Add Residential Bedrooms And Bathrooms' measure first.")
        return false
    end

    # Get water heater setpoint
    wh_setpoint = Waterheater.get_water_heater_setpoint(model, plant_loop, runner)
    if wh_setpoint.nil?
        return false
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

    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__))
    if weather.error?
        return false
    end

    # Set actual clothes washer water temperature for calculations below.
    if cw_cold_cycle
        # To model occupant behavior of using only a cold cycle.
        cw_water_temp = weather.data.MainsMonthlyTemps.inject(:+)/12 # degF
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

    weather.data.MainsMonthlyTemps.each_with_index do |monthly_main, i|

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
    
    obj_name = Constants.ObjectNameClothesWasher

    # Remove any existing clothes washer
    cw_removed = false
    space.electricEquipment.each do |space_equipment|
        if space_equipment.name.to_s == obj_name
            space_equipment.remove
            cw_removed = true
        end
    end
    space.waterUseEquipment.each do |space_equipment|
        if space_equipment.name.to_s == obj_name
            space_equipment.remove
            cw_removed = true
        end
    end
    if cw_removed
        runner.registerInfo("Removed existing clothes washer.")
    end

    if cw_ann_e > 0
        sch = HotWaterSchedule.new(model, runner, obj_name + " schedule", obj_name + " temperature schedule", nbeds, 0, "ClothesWasher", cw_water_temp, File.dirname(__FILE__))
        if not sch.validated?
            return false
        end
        design_level = sch.calcDesignLevelFromDailykWh(daily_energy)
        peak_flow = sch.calcPeakFlowFromDailygpm(total_daily_water_use)

        #Add equipment for the cw
        cw_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
        cw = OpenStudio::Model::ElectricEquipment.new(cw_def)
        cw.setName(obj_name)
        cw.setSpace(space)
        cw_def.setName(obj_name)
        cw_def.setDesignLevel(design_level)
        cw_def.setFractionRadiant(0.48)
        cw_def.setFractionLatent(0.0)
        cw_def.setFractionLost(0.2)
        sch.setSchedule(cw)

        #Add water use equipment for the dw
        cw_def2 = OpenStudio::Model::WaterUseEquipmentDefinition.new(model)
        cw2 = OpenStudio::Model::WaterUseEquipment.new(cw_def2)
        cw2.setName(obj_name)
        cw2.setSpace(space)
        cw_def2.setName(obj_name)
        cw_def2.setPeakFlowRate(peak_flow)
        cw_def2.setEndUseSubcategory("Domestic Hot Water")
        sch.setWaterSchedule(cw2)

        #Reuse existing water use connection if possible
        equip_added = false
        plant_loop.demandComponents.each do |component|
            next unless component.to_WaterUseConnections.is_initialized
            connection = component.to_WaterUseConnections.get
            connection.addWaterUseEquipment(cw2)
            equip_added = true
            break
        end
        if not equip_added
            #Need new water heater connection
            connection = OpenStudio::Model::WaterUseConnections.new(model)
            connection.addWaterUseEquipment(cw2)
            plant_loop.addDemandBranchForComponent(connection)
        end
        
        #reporting final condition of model
        runner.registerFinalCondition("A clothes washer with #{cw_ann_e.round} kWhs annual energy consumption has been added to plant loop '#{plant_loop.name}'.")
        
        return true
    end
	
  end

end #end the measure

#this allows the measure to be use by the application
ResidentialClothesWasher.new.registerWithApplication