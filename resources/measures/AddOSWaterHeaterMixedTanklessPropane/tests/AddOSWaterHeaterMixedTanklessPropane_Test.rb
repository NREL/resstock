# -*- coding: iso-8859-1 -*-
require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class AddOSWaterHeaterMixedTanklessGas_Test < Test::Unit::TestCase
  
  def setup
    # create an instance of the measure
    @measure = AddOSWaterHeaterMixedTanklessPropane.new
    
    #create an instance of the runner
    @runner = OpenStudio::Ruleset::OSRunner.new
    
    # Make an empty model
    @model = OpenStudio::Model::Model.new
    
    # Set up model
    make_existing_plant_loop(@model, "Test Plant Loop 1")
    make_existing_plant_loop(@model, "Test Plant Loop 2")
    make_thermal_zone(@model, "Thermal Zone 1")
    make_thermal_zone(@model, "Thermal Zone 2")
    
    # get arguments    
    @arguments = @measure.arguments(@model)
    
    # make arguement map
    make_argument_map    
  end
  
  #
  # Tests
  #
  
  def test_default_test_arguments_are_good
    @measure.run(@model, @runner, @argument_map)
    result = @runner.result

    assert_equal "Success", result.value.valueName
    assert_equal 1, result.warnings.count
    assert_empty result.errors
  end
  
  # Argument 1: existing_plant_loop
  
  def test_first_argument_is_existing_plant_loop
    arg = @arguments[0]
    assert_equal "existing_plant_loop_name", arg.name
    assert_equal "Plant Loop to assign Water heater as a Supply Equipment", arg.displayName
    refute arg.hasDefaultValue
  end
  
  def test_existing_plant_loop_has_existing_plant_loops_and_new_plant_loop
    
    loop_options = @arguments[0].choiceValues()
    assert_equal loop_options.count, 3
    assert_includes(loop_options, "Test Plant Loop 1")
    assert_includes(loop_options, "Test Plant Loop 2")
    assert_includes(loop_options, "New Plant Loop")   
  end
  
  def test_existing_plant_loop_only_does_heating_loops
    cooling_loop = make_existing_plant_loop(@model, "Cooling Loop")
    cooling_loop.sizingPlant.setLoopType("Cooling")
    @arguments = @measure.arguments(@model)
    
    loop_options = @arguments[0].choiceValues()
    assert_equal 3, loop_options.count
    refute_includes(loop_options, "Cooling Loop")
  end
  
  def test_existing_plant_loop_does_all_existing_heating_loops
    heating_loop = make_existing_plant_loop(@model, "Test Plant Loop 3")
    heating_loop.sizingPlant.setLoopType("Heating")
    @arguments = @measure.arguments(@model)
    
    loop_options = @arguments[0].choiceValues()
    assert_equal 4, loop_options.count
    assert_includes(loop_options, "Test Plant Loop 3")
  end
  
  # Argument 2: rated_energy_factor
  
  def test_second_argument_is_rated_energy_factor
    arg = @arguments[1]
    assert_equal "rated_energy_factor", arg.name
    assert_equal "Rated Energy Factor of Propane Tankless Water Heater. This field is ignored for NCTH and B10 protocols.", arg.displayName
    refute arg.hasDefaultValue
    assert_equal 1, arg.type.value # DoubleArgument
  end

  # Argument 3: shw_setpoint_temperature
  
  def test_third_argument_is_hot_water_setpoint_temperature
    arg = @arguments[2]
    assert_equal "shw_setpoint_temperature", arg.name
    assert_equal "Hot Water Temperature Setpoint", arg.displayName
    refute arg.hasDefaultValue
    assert_equal 1, arg.type.value # DoubleArgument
  end
  
  # Argument 4: water_heater_location
  def test_fourth_argument_is_water_heater_location
    arg = @arguments[3]
    refute_nil arg
    assert_equal "water_heater_location", arg.name
    assert_equal "Thermal Zone where the Propane Tankless Water Heater is located", arg.displayName
    refute arg.hasDefaultValue
    
    choices = arg.choiceValues
    assert_equal 2, choices.size
    assert_includes choices, "Thermal Zone 1"
    assert_includes choices, "Thermal Zone 2"
  end
  
  def test_water_heater_location_offers_all_thermal_zones
    make_thermal_zone(@model, "Test Thermal Zone")
    @arguments = @measure.arguments(@model)
    
    zone_options = @arguments[3].choiceValues()
    assert_equal 3, zone_options.count
    assert_includes(zone_options, "Test Thermal Zone")
  end
  
  # Argument 5: water_heater_capacity
  def test_fifth_argument_is_water_heater_capacity
    arg = @arguments[4]
    refute_nil arg
    assert_equal "water_heater_capacity", arg.name
    assert_equal "The nominal capacity [kBtu/hr] of the gas storage water heater. Set to 0 to have this field autosized.", arg.displayName
    refute arg.hasDefaultValue
    assert_equal 1, arg.type.value
  end

  # Argument 6: derate_for_cycling_inefficiencies
  def test_sixth_argument_is_cycling_inefficiencies
    arg = @arguments[5]
    refute_nil arg
    assert_equal "derate_for_cycling_inefficiencies", arg.name
    assert_equal "Annual Energy Derate for Cycling Inefficiencies - this factor accounts for the small water draws on the heat exchanger that are not currently reflected in the DOE Energy Factor test procedure. CEC 2008 Title 24 implemented an 8% derate for tankless water heaters.", arg.displayName
    refute arg.hasDefaultValue
    assert_equal 1, arg.type.value
  end

  # Argument 7: fuel_type
  def test_seventh_argument_is_fuel_type
    arg = @arguments[6]
    refute_nil arg
    assert_equal "fuel_type", arg.name
    assert_equal "Type of Fuel Used for Heating", arg.displayName
    refute arg.hasDefaultValue
    
    choices = arg.choiceValues
    assert_equal 2, choices.size
    assert_includes choices, "Natural Gas"
    assert_includes choices, "Propane Gas"
  end

  def test_there_are_only_seven_arguments
    assert_equal 7, @arguments.count
  end  
  
  #
  # Error Message Tests
  #
  
  def test_setpoint_temp_must_be_positive
    assert_error_if_not_positive("shw_setpoint_temperature", "Hot water temperature should be greater than 0")
  end
  
  def test_rated_energy_factor_at_most_one
    assert_error_if_arg_greater_than(1.0, "rated_energy_factor", "Rated Energy Factor must be between 0.0 and 1.0.")
  end

  def test_rated_energy_factor_must_be_positive
    assert_error_if_not_positive("rated_energy_factor", "Rated Energy Factor must be between 0.0 and 1.0.")
  end
  
  def test_rated_energy_factor_at_negative_one_is_an_error
    set_argument("rated_energy_factor", -1)
    
    @measure.run(@model, @runner, @argument_map)
    
    errors = @runner.result.errors.collect{ |w| w.logMessage}
    assert_includes errors, "Rated Energy Factor must be between 0.0 and 1.0."
  end  
  
  def test_water_heater_capacity_must_be_greater_than_0kW
    assert_error_if_arg_less_than(0, "water_heater_capacity", "Propane Tankless Water Heater Nominal Capacity must be greater than 0 kBtu/hr.")
  end
  
  def test_water_heater_capacity_of_negative_one_is_an_error
    set_argument("water_heater_capacity",-1)
    
    @measure.run(@model, @runner, @argument_map)
    
    errors = @runner.result.errors.collect{ |w| w.logMessage}
    assert_includes errors, "Propane Tankless Water Heater Nominal Capacity must be greater than 0 kBtu/hr."    
  end

  def test_derating_for_cycling_inefficiencies_must_be_at_least_zero
    assert_error_if_arg_less_than(0, "derate_for_cycling_inefficiencies", "Derate for cycling inefficiencies must be between 0.0 and 1.0.")
  end

  def test_derating_for_cycling_inefficiencies_must_be_at_most_one
    assert_error_if_arg_greater_than(1.0, "derate_for_cycling_inefficiencies", "Derate for cycling inefficiencies must be between 0.0 and 1.0.")
  end

  #
  # Warning Message tests:
  #
  
  def test_new_loop_generates_proper_warning
    set_argument("existing_plant_loop_name", "New Plant Loop")
    
    @measure.run(@model, @runner, @argument_map)
    
    warnings = @runner.result.warnings.collect{ |w| w.logMessage}
    assert_includes warnings, "The water heater will be applied to a new OS:PlantLoop object. The plant loop object will be created using default values. Please review the values for appropriateness."
  end
  
  def test_existing_loop_generates_proper_warning
    set_argument( "existing_plant_loop_name", "Test Plant Loop 1")
    
    @measure.run(@model, @runner, @argument_map)
    
    warnings = @runner.result.warnings.collect{ |w| w.logMessage}
    assert_includes warnings, "Additional Water heater being added to Test Plant Loop 1. User will need to confirm controls."
  end
  
  def test_setpoint_temp_should_be_in_sensible_range
    assert_warning_if_arg_greater_than(140,"shw_setpoint_temperature",
                                       "Hot Water Setpoint schedule SHW_Temp has values greater than 140F." +
                                       " This temperature, if achieved, may cause scalding.")
    assert_warning_if_arg_less_than(120,"shw_setpoint_temperature",
                                    "Hot Water Setpoint schedule SHW_Temp has values less than 120F." +
                                    " This temperature may promote the growth of Legionellae or other bacteria.")
  end
  
  def test_rated_energy_factor_should_be_in_sensible_range
    assert_warning_if_arg_less_than(0.68, "rated_energy_factor",
                                    "AHRI Certified Energy Factors for Commercially available Propane Tankless Water Heaters should be 0.68 or greater.")
    assert_warning_if_arg_greater_than(0.99, "rated_energy_factor",
                                    "AHRI Certified Energy Factors for Commercially available Propane Tankless Water Heaters should be less than 0.99.", 0.001)
  end
  
  def test_water_heater_capacity_should_be_in_sensible_range
    assert_warning_if_arg_less_than(74.9,"water_heater_capacity",
                                    "Commercially Available Propane Tankless Water Heaters should have a minimum Nominal Capacity of 74.9 kBtu/hr.")
    assert_warning_if_arg_greater_than(199.9,"water_heater_capacity",
                                    "Commercially Available Propane Tankless Water Heaters should have a maximum Nominal Capacity of 199.9 kBtu/hr.",0.001)
  end
  
  def test_derate_for_cycling_should_be_at_most_12_percent
    assert_warning_if_arg_greater_than(0.12,
                                    "derate_for_cycling_inefficiencies",
                                    "Derate for cycling inefficiencies of 0.13 appears large. CEC 2008 Title 24 recommends 0.088.")
  end
  
  def test_initial_conditions_have_sensible_message_if_no_existing_water_heaters
    @measure.run(@model, @runner, @argument_map)
    initial_condition = @runner.result.initialCondition.get.logMessage
    
    assert_includes initial_condition, "No water heaters in initial model"
    
  end
  
  
  def test_initial_conditions_include_existing_water_heaters
    gal = OpenStudio::createUnit("gal").get
    # create 2 existing water heaters
    new_heater1 = OpenStudio::Model::WaterHeaterMixed.new(@model)
    new_heater1.setName("Test Existing Heater 1")
    new_heater1.setHeaterMaximumCapacity(25497.183) # 87 kBtu/hr
    new_heater1.setTankVolume(OpenStudio::Quantity.new(54, gal))
    
    new_heater2 = OpenStudio::Model::WaterHeaterMixed.new(@model)
    new_heater2.setName("Test Existing Heater 2")
    new_heater2.setHeaterMaximumCapacity(48356.727) # 165 kBtu/hr
    new_heater2.setTankVolume(OpenStudio::Quantity.new(47, gal))

    new_tankless = OpenStudio::Model::WaterHeaterMixed.new(@model)
    new_tankless.setName("Test Existing Tankless Heater Propane")
    new_tankless.setHeaterMaximumCapacity(27548.681) # 94 kBtu/hr
    new_tankless.setTankVolume(OpenStudio::Quantity.new(1,gal))
    new_tankless.setHeaterFuelType("Propane")
    
    
    # Add water heaters to existing loops; not fully configuring because unnessarty for this test
    loop1 = @model.getPlantLoops().find{|pl| pl.name.get == "Test Plant Loop 1"}
    loop2 = @model.getPlantLoops().find{|pl| pl.name.get == "Test Plant Loop 2"}
    loop1.addSupplyBranchForComponent(new_heater1)
    loop2.addSupplyBranchForComponent(new_heater2)
    loop2.addSupplyBranchForComponent(new_tankless)
    assert_equal loop1, new_heater1.plantLoop.get
    
    @measure.run(@model, @runner, @argument_map)
    initial_condition = @runner.result.initialCondition.get.logMessage
    
    assert_includes initial_condition, "Test Existing Heater 1"
    assert_includes initial_condition, "Test Plant Loop 1", "Initial condition should include existing heater's plant loop"
    assert_includes initial_condition, "87 kBtu/h", "Initial condition should include existing heater's capacity"
    assert_includes initial_condition, "54 gal", "Initial condition should include existing heater's size"
    
    assert_includes initial_condition, "Test Existing Heater 2"
    assert_includes initial_condition, "Test Plant Loop 2", "Initial condition should include existing heater's plant loop"
    assert_includes initial_condition, "165 kBtu/h", "Initial condition should include existing heater's capacity"
    assert_includes initial_condition, "47 gal", "Initial condition should include existing heater's size"   

    assert_includes initial_condition, "Test Existing Tankless Heater Propane"
    assert_includes initial_condition, "Test Plant Loop 2", "Initial condition should include existing heater's plant loop"
    assert_includes initial_condition, "94 kBtu/h", "Initial condition should include existing heater's capacity"
    refute_includes initial_condition, "1 gal", "Initial condition should include existing heater's size"   
  end
  
  def test_final_conditions_include_name_of_new_hot_water_loop
    set_argument("existing_plant_loop_name", "Test Plant Loop 1")
    @measure.run(@model, @runner, @argument_map)
    
    final_condition = @runner.result.finalCondition.get.logMessage
    refute_includes final_condition, "Service Hot Water Loop"
    
    set_argument("existing_plant_loop_name", "New Plant Loop")
    @measure.run(@model, @runner, @argument_map)
    final_condition = @runner.result.finalCondition.get.logMessage
    assert_includes final_condition, "Service Hot Water Loop"
  end
  
  def test_final_conditions_include_name_capacity_and_size_of_new_heater
    @measure.run(@model, @runner, @argument_map)
    
    final_condition = @runner.result.finalCondition.get.logMessage
    assert_includes final_condition, "Water Heater Mixed 1"
    assert_includes final_condition, "142 kBtu/h"
    assert_includes final_condition, "tankless" # Tank size is reduced by 10%
  end
  
  def test_make_with_new_plant_loop_has_new_plant_loop
    assert_equal 2, @model.getPlantLoops.count
    refute_includes @model.getPlantLoops.collect{|l| l.name.get}, "Service Hot Water Loop"
    
    @measure.run(@model, @runner, @argument_map)
    
    assert_equal 3, @model.getPlantLoops.count
    assert_includes @model.getPlantLoops.collect{|l| l.name.get}, "Service Hot Water Loop"
    
  end
  
  def test_make_with_existing_loop_does_not_have_new_plant_loop
    old_plant_loops = @model.getPlantLoops
    
    set_argument("existing_plant_loop_name", old_plant_loops.first.name.get)
    
    @measure.run(@model, @runner, @argument_map)
    
    assert_equal old_plant_loops, @model.getPlantLoops
  end
  
  
  def test_new_plant_loop_has_pump
    assert_empty @model.getPumpConstantSpeeds
    
    @measure.run(@model, @runner, @argument_map)
    
    loop = @model.getPlantLoops.find{|l| l.name.get == "Service Hot Water Loop"}
    pump = @model.getPumpConstantSpeeds.first
    refute_nil pump
    assert_includes loop.components, pump
  end

  def test_new_plant_loop_has_pipes
    assert_empty @model.getPipeAdiabatics

    @measure.run(@model, @runner, @argument_map)

    pipes = @model.getPipeAdiabatics
    assert_equal 2, pipes.count
    loop = @model.getPlantLoops.find{|l| l.name.get == "Service Hot Water Loop"}
    loop_stuff = loop.components
    assert_includes loop_stuff, pipes[0]
    assert_includes loop_stuff, pipes[1]
  end

  def test_new_plant_loop_has_heater
    assert_empty @model.getWaterHeaterMixeds

    @measure.run(@model, @runner, @argument_map)

    heaters = @model.getWaterHeaterMixeds
    assert_equal 1, heaters.count
    loop = @model.getPlantLoops.find{|l| l.name.get == "Service Hot Water Loop"}
    loop_stuff = loop.components
    assert_includes loop_stuff, heaters[0]
  end

  def test_new_plant_loop_has_schedule
    assert_empty @model.getSetpointManagerScheduleds

    @measure.run(@model, @runner, @argument_map)

    managers = @model.getSetpointManagerScheduleds
    assert_equal 1, managers.count

    loop = @model.getPlantLoops.find{|l| l.name.get == "Service Hot Water Loop"}
    outlet_node = loop.supplyOutletNode
    assert_includes outlet_node.setpointManagers, managers[0]
  end

  def test_new_plant_loop_heater_has_specified_capacity
    set_argument("water_heater_capacity", 4.143)
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]

    assert_in_delta 4143/3.412142, heater.heaterMaximumCapacity.get, 0.01
  end

  def test_new_plant_loop_is_configured_with_standard_values
    @measure.run(@model, @runner, @argument_map)
    
    new_plant_loop = @model.getPlantLoops.find{|l| l.name.get == "Service Hot Water Loop"}
    refute_nil new_plant_loop
    new_sizing_plant = new_plant_loop.sizingPlant
    
    assert_equal "Heating", new_sizing_plant.loopType
    assert_equal 60, new_sizing_plant.designLoopExitTemperature
    assert_equal 50, new_sizing_plant.loopDesignTemperatureDifference
  end

  def test_existing_plant_loop_without_pump_gets_pump
    assert_empty @model.getPumpConstantSpeeds

    test_loop = @model.getPlantLoops[0]
    set_argument("existing_plant_loop_name", test_loop.name.get)

    @measure.run(@model, @runner, @argument_map)

    refute_empty @model.getPumpConstantSpeeds
    new_pump = @model.getPumpConstantSpeeds[0]
    assert_includes test_loop.components, new_pump
  end

  def test_new_pump_configured_for_consuming_near_zero_energy
    @measure.run(@model, @runner, @argument_map)

    pump = @model.getPumpConstantSpeeds[0]

    assert_equal 1, pump.fractionofMotorInefficienciestoFluidStream
    assert_equal 0.999, pump.motorEfficiency
    assert              pump.isRatedFlowRateAutosized
    assert_equal "Intermittent", pump.pumpControlType
    assert_equal 0.001, pump.ratedPowerConsumption.get
    assert_equal 0.001, pump.ratedPumpHead
  end
  

  def test_existing_plant_loop_with_pump_is_left_alone
    test_loop = @model.getPlantLoops[0]
    pump = OpenStudio::Model::PumpConstantSpeed.new(@model)
    pump.addToNode(test_loop.supplyInletNode)
    assert_equal 1, test_loop.components(OpenStudio::Model::PumpConstantSpeed::iddObjectType).count    

    set_argument("existing_plant_loop_name", test_loop.name.get)

    @measure.run(@model, @runner, @argument_map)

    assert_equal 1, test_loop.components(OpenStudio::Model::PumpConstantSpeed::iddObjectType).count    
  end

  def test_existing_plant_loop_gets_new_schedule_manager
    test_loop = @model.getPlantLoops[0]
    assert_empty test_loop.supplyOutletNode.setpointManagers

    set_argument("existing_plant_loop_name", test_loop.name.get)

    @measure.run(@model, @runner, @argument_map)

    assert_equal 1, test_loop.supplyOutletNode.setpointManagers.count
  end

  def test_schedule_manager_configured
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    loop = heater.plantLoop.get
    manager = loop.supplyOutletNode.setpointManagers[0].to_SetpointManagerScheduled.get
    schedule = manager.schedule.to_ScheduleRuleset.get
    schedule_for_default_day = schedule.defaultDaySchedule
    times = schedule_for_default_day.times
    
    assert_equal "SHW Temp", schedule.name.get
    assert_equal "HW Temp Default", schedule_for_default_day.name.get
    assert_equal 1, times.count
    time = times[0]
    assert_equal "24:00:00", time.to_s

    assert_in_delta 54.44444, schedule_for_default_day.values[0], 0.01 # 130 F = 54.4444 C
  end

  def test_existing_plant_loop_with_schedule_gets_left_alone
    test_sched = OpenStudio::Model::ScheduleRuleset.new(@model)
    test_manager = OpenStudio::Model::SetpointManagerScheduled.new(@model, test_sched)
    test_loop = @model.getPlantLoops[0]
    test_manager.addToNode(test_loop.supplyOutletNode)
    assert_equal 1, test_loop.supplyOutletNode.setpointManagers.count

    set_argument("existing_plant_loop_name", test_loop.name.get)
    @measure.run(@model, @runner, @argument_map)

    assert_equal 1, test_loop.supplyOutletNode.setpointManagers.count
    assert_includes test_loop.supplyOutletNode.setpointManagers, test_manager
  end

  def test_tankless_tank_volume_is_one_gallon
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_in_delta 0.00379, heater.tankVolume.get # 0.00379 m^3 = 1 gallon
  end
  

  def test_setpoint_temperature_schedule_for_general_uses_input_value
    set_argument("shw_setpoint_temperature", 146)
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    refute_nil heater
    refute heater.setpointTemperatureSchedule.empty?
    schedule = heater.setpointTemperatureSchedule.get.to_ScheduleRuleset.get
    refute_nil schedule

    assert_equal "SHW Set Temp", schedule.name.get
    schedule_for_default_day = schedule.defaultDaySchedule

    assert_equal 1, schedule_for_default_day.times.count
    assert_in_delta 63.3, schedule_for_default_day.values[0], 0.1 # 146F is 63.3333C
  end

  def test_deadband_temp_should_be_0C
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]

    assert_equal 0, heater.deadbandTemperatureDifference
  end
  
  def test_max_temp_limit_should_be_99C
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]

    assert_equal 99, heater.maximumTemperatureLimit.get
  end
  

  def test_heater_control_type_should_be_modulate
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]

    assert_equal "Modulate", heater.heaterControlType
  end

  def test_general_has_capacity_from_input
    set_argument("water_heater_capacity", 123)
    @measure.run(@model, @runner, @argument_map)
    
    heater = @model.getWaterHeaterMixeds[0]
    refute_nil heater
    assert_in_delta 123*293.07107, heater.heaterMaximumCapacity.get, 0.0001
  end
  
  def test_capacity_should_be_autosized_on_0_input
    set_argument("water_heater_capacity", 0)
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    refute_nil heater
    assert heater.isHeaterMaximumCapacityAutosized
  end
  
  
  def test_water_heater_minimum_capacity_is_0
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_equal 0, heater.heaterMinimumCapacity.get
  end
  
  def test_water_heater_fuel_is_gas
    set_argument("fuel_type", "Propane Gas")
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_equal "NaturalGas", heater.heaterFuelType
  end
  
  def test_water_heater_fuel_is_propane  
    set_argument("fuel_type", "Propane Gas")
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_equal "PropaneGas", heater.heaterFuelType
  end

  [[0.98,0.08, 0.9016], [0.99, 0.05, 0.9405] ].each do |ef, derate, expected|
    define_method("test_#{ef}_ef_with_#{derate}_derate_for_cycling_has_#{expected}_thermal_efficiency") do
      set_argument("rated_energy_factor", ef)
      set_argument("derate_for_cycling_inefficiencies", derate)
      @measure.run(@model, @runner, @argument_map                   )

      heater = @model.getWaterHeaterMixeds[0]
      assert_in_delta expected, heater.heaterThermalEfficiency.get, 0.0001
    end
  end
  
  def test_water_heater_ambient_temperature_indicator_is_zone
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_equal "ThermalZone", heater.ambientTemperatureIndicator
  end

  [[0.80, 3.3437],  [0.95, 0.70394]].each do |energy_factor, watts_per_kelvin|
    define_method("test_water_heater_off_cycle_loss_coefficient__for_#{energy_factor}_ef_is_#{watts_per_kelvin}") do
      set_argument("rated_energy_factor", energy_factor)
      @measure.run(@model, @runner, @argument_map)
      
      heater = @model.getWaterHeaterMixeds[0]
      assert_in_delta 0, heater.offCycleLossCoefficienttoAmbientTemperature.get, 0.001
    end
  end

  def test_water_heater_off_cycle_loss_to_thermal_zone_is_1
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_in_delta 1, heater.offCycleLossFractiontoThermalZone, 0.001
  end

  [[0.80, 3.3437],  [0.95, 0.70394]].each do |energy_factor, watts_per_kelvin|
    define_method("test_water_heater_on_cycle_loss_coefficient__for_#{energy_factor}_ef_is_#{watts_per_kelvin}") do
      set_argument("rated_energy_factor", energy_factor)
      @measure.run(@model, @runner, @argument_map)
      
      heater = @model.getWaterHeaterMixeds[0]
      assert_in_delta 0, heater.onCycleLossCoefficienttoAmbientTemperature.get, 0.001
    end
  end

  def test_water_heater_on_cycle_loss_to_thermal_zone_is_1
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_in_delta 1, heater.onCycleLossFractiontoThermalZone, 0.001
  end

  def test_water_heater_on_use_side_effectiveness_is_1
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_in_delta 1, heater.useSideEffectiveness, 0.001
  end

  def test_water_heater_on_source_side_effectiveness_is_1
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_in_delta 1, heater.sourceSideEffectiveness, 0.001
  end

  def test_water_heater_use_side_design_flow_rate_is_autosized
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert heater.isUseSideDesignFlowRateAutosized
  end

  def test_water_heater_ambient_temperature_thermal_zone_is_set
    @measure.run(@model, @runner, @argument_map              )

    heater = @model.getWaterHeaterMixeds[0]
    thermal_zone = heater.ambientTemperatureThermalZone
    refute thermal_zone.empty?
    assert_equal "Thermal Zone 1", thermal_zone.get.name.get
  end
  

  def test_result_returns_info_messages
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]


    
    assert_info_contains "Water heater of type", "1 gal"
    assert_info_contains "A schedule named SHW Set Temp was created and applied to", heater.name.get
    assert_info_contains "Water heater '#{heater.name.get}' has a deadband temperature difference of 0 K"
    assert_info_contains "Water heater '#{heater.name.get}' has a maximum temperature limit of 210.2 F"
    assert_info_contains "Water heater '#{heater.name.get}' has a heater maximum capacity of 142 kBtu/h"
    assert_info_contains "Water heater '#{heater.name.get}' has a heater minimum capacity of 0 W"
    assert_info_contains "Water heater '#{heater.name.get}' has a heater fuel type of 'PropaneGas'"
    assert_info_contains "Water heater '#{heater.name.get}' has a heater thermal efficiency of 0.9108"
    assert_info_contains "Water heater '#{heater.name.get}' has an ambient temperature indicator of 'ThermalZone'"
    assert_info_contains "Water heater '#{heater.name.get}' has an on-cycle loss coefficient to ambient temperature of "
    assert_info_contains "Water heater '#{heater.name.get}' has an on-cycle loss fraction to thermal zone of 1.0"
    assert_info_contains "Water heater '#{heater.name.get}' has an off-cycle loss coefficient to ambient temperature of "
    assert_info_contains "Water heater '#{heater.name.get}' has an off-cycle loss fraction to thermal zone of 1.0"
    assert_info_contains "Water heater '#{heater.name.get}' has a use side effectiveness of 1.0"
    assert_info_contains "Water heater '#{heater.name.get}' has a source side effectiveness of 1.0"
    assert_info_contains "Water heater '#{heater.name.get}' has an ambient temperature thermal zone of 'Thermal Zone 1'"
  end

  def test_run_returns_false_if_error
    set_argument("shw_setpoint_temperature", -20)
    refute @measure.run(@model, @runner, @argument_map)
  end
  
  
  
  
  #
  # Helper Methods
  #
  
  def make_existing_plant_loop(model, name)
    loop = OpenStudio::Model::PlantLoop.new(@model)
    loop.setName(name)
    return loop
  end
  
  def make_thermal_zone(model, name)
    zone = OpenStudio::Model::ThermalZone.new(@model)
    zone.setName(name)
    return zone
  end
  
  def make_argument_map
    
    argMap = {
      "existing_plant_loop_name" => "New Plant Loop",
      "rated_energy_factor" => 0.99,
      "shw_setpoint_temperature" => 130,
      "water_heater_location" => "Thermal Zone 1",
      "water_heater_capacity" => 142,
      "derate_for_cycling_inefficiencies" => 0.08,
      "fuel_type" => "Propane Gas"
    }
    @argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    argMap.each { | key, value | set_argument(key, value) }

  end

  def assert_warning_bound_check(arg, warning, good, bad)
    # works at limit
    set_argument(arg, good )
    @measure.run(@model, @runner, @argument_map)
    
    warnings = @runner.result.warnings.collect{ |w| w.logMessage }
    refute_includes warnings, warning

    # warns beyond limit
    set_argument(arg, bad )
    @measure.run(@model, @runner, @argument_map)

    warnings = @runner.result.warnings.collect{ |w| w.logMessage }
    assert_includes warnings, warning
  end
  
  def assert_error_bound_check(arg,error, good, bad)
    # works at limit
    set_argument(arg,good)
    @measure.run(@model, @runner, @argument_map)

    errors = @runner.result.errors.collect{ |e| e.logMessage }
    refute_includes errors, error

    # warns beyond limit
    set_argument(arg,bad)
    @measure.run(@model, @runner, @argument_map)
    
    errors = @runner.result.errors.collect{ |w| w.logMessage }
    assert_includes errors, error
  end
  
  def assert_warning_if_arg_less_than(limit, arg, warning, delta = 0.01)
    assert_warning_bound_check(arg, warning, limit, limit - delta)
  end

  def assert_warning_if_arg_greater_than(limit, arg, warning, delta = 0.01)
    assert_warning_bound_check(arg, warning, limit, limit + delta)
  end  
  
  def assert_error_if_arg_less_than(limit, arg, error, delta = 0.01)
    assert_error_bound_check(arg, error,limit, limit - delta)
  end

  def assert_error_if_arg_greater_than(limit, arg, error, delta = 0.01)
    assert_error_bound_check(arg, error, limit, limit + delta)
  end

  def assert_error_if_not_positive(arg, error, integer = false)
    if integer
      delta = 1
    else
      delta = 0.01
    end
    
    assert_error_bound_check(arg, error, delta, 0)
    assert_error_bound_check(arg, error, delta, -delta)
  end

  def assert_info_contains(match, *subs)
    infos = @runner.result.info.collect{|i| i.logMessage}

    matched_infos = infos.find_all { |i| i.include? match}
    refute_empty matched_infos, "No info message containing '#{match}' was found"
    assert_equal 1, matched_infos.count, "Too many info messages containing '#{match}' were found."

    matched_info = matched_infos[0]

    subs.each { |s|  assert_includes matched_info, s }
  end
  
  
  
  def set_argument( key, value)
    arg = @arguments.find { |a| a.name == key }
    refute_nil arg, "Expected to find argument of name #{key}, but didn't."
    
    newArg = arg.clone
    assert(newArg.setValue(value), "Could not set argument #{key} to #{value}")
    @argument_map[key] = newArg
  end  
end
