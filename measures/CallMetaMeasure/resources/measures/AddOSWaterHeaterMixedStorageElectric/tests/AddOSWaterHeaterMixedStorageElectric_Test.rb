# -*- coding: iso-8859-1 -*-
require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class AddOSWaterHeaterMixedStorageElectric_Test < Test::Unit::TestCase

  def setup
    # create an instance of the measure
    @measure = AddOSWaterHeaterMixedStorageElectric.new
    
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
  
  # Argument 1: object_to_be_created
  
  def test_first_argument_is_object_to_be_created
    arg = @arguments[0]
    assert_equal "object_to_be_created", arg.name
    refute arg.hasDefaultValue
    
    choices = arg.choiceValues
    assert_equal 4, choices.size
    assert_includes choices, "Create a water heater representing B10 Benchmark standard"
    assert_includes choices, "Create a water heater representing NCTH standard"
    assert_includes choices, "Create a water heater representing BA Pre-Retrofit Case standard"
    assert_includes choices, "General"
  end
  
  # Argument 2: number_of_bedrooms
  
  def test_second_argument_is_number_of_bedrooms
    arg = @arguments[1]
    assert_equal "number_of_bedrooms", arg.name
    refute arg.hasDefaultValue
    assert_equal 3, arg.type.value # IntegerArgument
  end
  
  def test_number_of_bedrooms_must_be_between_1_and_5
    assert_error_if_arg_less_than(1,"number_of_bedrooms", "The number of bedrooms must be from 1 to 5", 1)
    assert_error_if_arg_greater_than(5,"number_of_bedrooms", "The number of bedrooms must be from 1 to 5", 1)
  end
  
  
  # Argument 3: number_of_bathrooms
  
  def test_third_argument_is_number_of_bathrooms
    arg = @arguments[2]
    assert_equal "number_of_bathrooms", arg.name
    refute arg.hasDefaultValue
    
    choices = arg.choiceValues
    assert_equal 6, choices.size
    assert_includes choices, "1"
    assert_includes choices, "1.5"
    assert_includes choices, "2"
    assert_includes choices, "2.5"
    assert_includes choices, "3"
    assert_includes choices, "3.5 or more"
  end
  
  # Argument 4: existing_plant_loop
  
  def test_fourth_argument_is_existing_plant_loop
    arg = @arguments[3]
    assert_equal "existing_plant_loop_name", arg.name
    assert_equal "Plant Loop to assign Water heater as a Supply Equipment", arg.displayName
    refute arg.hasDefaultValue
  end
  
  def test_existing_plant_loop_has_existing_plant_loops_and_new_plant_loop
    
    loop_options = @arguments[3].choiceValues()
    assert_equal loop_options.count, 3
    assert_includes(loop_options, "Test Plant Loop 1")
    assert_includes(loop_options, "Test Plant Loop 2")
    assert_includes(loop_options, "New Plant Loop")   
  end
  
  def test_existing_plant_loop_only_does_heating_loops
    cooling_loop = make_existing_plant_loop(@model, "Cooling Loop")
    cooling_loop.sizingPlant.setLoopType("Cooling")
    @arguments = @measure.arguments(@model)
    
    loop_options = @arguments[3].choiceValues()
    assert_equal 3, loop_options.count
    refute_includes(loop_options, "Cooling Loop")
  end
  
  def test_existing_plant_loop_does_all_existing_heating_loops
    heating_loop = make_existing_plant_loop(@model, "Test Plant Loop 3")
    heating_loop.sizingPlant.setLoopType("Heating")
    @arguments = @measure.arguments(@model)
    
    loop_options = @arguments[3].choiceValues()
    assert_equal 4, loop_options.count
    assert_includes(loop_options, "Test Plant Loop 3")
  end
  
  # Argument 5: storage_tank_volume
  
  def test_fifth_argument_is_storage_tank_volume
    arg = @arguments[4]
    assert_equal "storage_tank_volume", arg.name
    assert_equal "Volume of the Storage Tank (gallons) of the Electric Hot Water Heater. Set to 0 to have Storage tank volume autosized. This field is ignored for NCTH and B10 protocols.", arg.displayName
    refute arg.hasDefaultValue
    assert_equal 1, arg.type.value # DoubleArgument
  end
  
  
  # Argument 6: rated_energy_factor
  
  def test_sixth_argument_is_rated_energy_factor
    arg = @arguments[5]
    assert_equal "rated_energy_factor", arg.name
    assert_equal "Rated Energy Factor of Electric Storage Tank Water Heater. This field is ignored for NCTH and B10 protocols.", arg.displayName
    refute arg.hasDefaultValue
    assert_equal 1, arg.type.value # DoubleArgument
  end
  
  # Argument 7: shw_setpoint_temperature
  
  def test_seventh_argument_is_hot_water_setpoint_temperature
    arg = @arguments[6]
    assert_equal "shw_setpoint_temperature", arg.name
    assert_equal "Hot Water Temperature Setpoint", arg.displayName
    refute arg.hasDefaultValue
    assert_equal 1, arg.type.value # DoubleArgument
  end
  
  # Argument 8: water_heater_location
  def test_eighth_argument_is_water_heater_location
    arg = @arguments[7]
    refute_nil arg
    assert_equal "water_heater_location", arg.name
    assert_equal "Thermal Zone where the Electric Storage Water Heater is located", arg.displayName
    refute arg.hasDefaultValue
    
    choices = arg.choiceValues
    assert_equal 2, choices.size
    assert_includes choices, "Thermal Zone 1"
    assert_includes choices, "Thermal Zone 2"
  end
  
  def test_water_heater_location_offers_all_thermal_zones
    make_thermal_zone(@model, "Test Thermal Zone")
    @arguments = @measure.arguments(@model)
    
    zone_options = @arguments[7].choiceValues()
    assert_equal 3, zone_options.count
    assert_includes(zone_options, "Test Thermal Zone")
  end
  
  # Argument 9: water_heater_capacity
  def test_ninth_argument_is_water_heater_capacity
    arg = @arguments[8]
    refute_nil arg
    assert_equal "water_heater_capacity", arg.name
    assert_equal "The nominal capacity [W] of the electric storage water heater. Set to 0 to have this field autosized. This field is ignored for NCTH or B10 protocols.", arg.displayName
    refute arg.hasDefaultValue
    assert_equal 1, arg.type.value
  end
  
  
  
  #
  # Error Message Tests
  #
  
  def test_setpoint_temp_must_be_positive
    assert_error_if_not_positive("shw_setpoint_temperature", "Hot water temperature should be greater than 0")
  end
  
  def test_storage_tank_must_be_positive
    assert_error_if_arg_less_than(0, "storage_tank_volume", "Storage Tank Volume cannot be &lt; 0 gallons. Please correct.")
  end
  
  def test_storage_tank_at_negative_1_is_an_error
    set_argument("storage_tank_volume",-1)
    
    @measure.run(@model, @runner, @argument_map)
    
    errors = @runner.result.errors.collect{ |w| w.logMessage}
    assert_includes errors, "Storage Tank Volume cannot be &lt; 0 gallons. Please correct."
  end    
  
  def test_rated_energy_factor_at_most_one
    assert_error_if_arg_greater_than(1.0, "rated_energy_factor", "Rated Energy Factor has a maximum value of 1.0")
  end
  
  def test_rated_energy_factor_at_negative_one_is_an_error
    set_argument("rated_energy_factor", -1)
    
    @measure.run(@model, @runner, @argument_map)
    
    errors = @runner.result.errors.collect{ |w| w.logMessage}
    assert_includes errors, "Rated Energy Factor must be &gt; 0"
  end  
  
  def test_water_heater_capacity_must_be_greater_than_0kW
    assert_error_if_arg_less_than(0, "water_heater_capacity", "Electric Storage Water Heater Nominal Capacity must be &gt; 0 kW.")
  end
  
  def test_water_heater_capacity_of_negative_one_is_an_error
    set_argument("water_heater_capacity",-1)
    
    @measure.run(@model, @runner, @argument_map)
    
    errors = @runner.result.errors.collect{ |w| w.logMessage}
    assert_includes errors, "Electric Storage Water Heater Nominal Capacity must be &gt; 0 kW."
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
  
  def test_warning_if_setpoint_temp_not_sensible
    assert_warning_if_arg_greater_than(140,"shw_setpoint_temperature",
                                       "Hot Water Setpoint schedule SHW_Temp has values &gt; 140F." +
                                       " This temperature, if achieved, may cause scalding.")
    assert_warning_if_arg_less_than(120,"shw_setpoint_temperature",
                                    "Hot Water Setpoint schedule SHW_Temp has values less than 120F." +
                                    " This temperature may promote the growth of Legionellae or other bacteria.")
  end
  
  def test_warning_if_small_storage_tank_not_sensible
    assert_warning_if_arg_less_than(25, "storage_tank_volume",
                                    "A storage tank volume of less than 25 gallons is not commercially available. Please review the input.")
    assert_warning_if_arg_greater_than(125, "storage_tank_volume",
                                       "A storage tank volume of greater than 125 gallons is not commercially available. Please review the input.")
  end
  
  def test_warning_if_rated_energy_factor_too_low
    assert_warning_if_arg_less_than(0.90, "rated_energy_factor",
                                    "Rated Energy Factor for Commercially available Electric Storage Water Heaters should be greater than 0.90")
  end
  
  def test_water_heater_capacity_should_be_in_sensible_range
    assert_warning_if_arg_less_than(2000,"water_heater_capacity",
                                    "Commercially Available Electric Storage Water Heaters should have a minimum Nominal Capacity of 2.0 kW.")
    assert_warning_if_arg_greater_than(6000,"water_heater_capacity",
                                       "Commercially Available Electric Storage Water Heaters should have a maximum Nominal Capacity of 6.0 kW.")
  end
  
  def test_warning_if_building_america_measure
    expected_warning = "BA protocols require water heater location to be in attached garage (if it exists and climate =" +
      " hot-humid or hot-dry or unconditioned basement if it exists and climate = all others). Please check table 9 of 2014 simulation protocols."
    
    ba_protocols = [ "Create a water heater representing B10 Benchmark standard",
                     "Create a water heater representing NCTH standard",
                     "Create a water heater representing BA Pre-Retrofit Case standard"
                   ]
    
    for protocol in ba_protocols do
      set_argument("object_to_be_created", "Create a water heater representing B10 Benchmark standard")
      @measure.run(@model, @runner, @argument_map)
      warnings = @runner.result.warnings.collect{|w| w.logMessage }
      assert_includes warnings, expected_warning, "Warning not generated for '#{protocol}'"
      
      # "General"" is not a BA protocol
      set_argument("object_to_be_created", "General")
      @measure.run(@model, @runner, @argument_map)
      warnings = @runner.result.warnings.collect{|w| w.logMessage }
      refute_includes warnings, expected_warning
    end
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
    new_heater1.setHeaterMaximumCapacity(2014)
    new_heater1.setTankVolume(OpenStudio::Quantity.new(54, gal))
    
    new_heater2 = OpenStudio::Model::WaterHeaterMixed.new(@model)
    new_heater2.setName("Test Existing Heater 2")
    new_heater2.setHeaterMaximumCapacity(1964)
    new_heater2.setTankVolume(OpenStudio::Quantity.new(47, gal))
    
    
    # Add water heaters to existing loops; not fully configuring because unnessarty for this test
    loop1 = @model.getPlantLoops().find{|pl| pl.name.get == "Test Plant Loop 1"}
    loop2 = @model.getPlantLoops().find{|pl| pl.name.get == "Test Plant Loop 2"}
    loop1.addSupplyBranchForComponent(new_heater1)
    loop2.addSupplyBranchForComponent(new_heater2)
    assert_equal loop1, new_heater1.plantLoop.get
    
    @measure.run(@model, @runner, @argument_map)
    initial_condition = @runner.result.initialCondition.get.logMessage
    
    assert_includes initial_condition, "Test Existing Heater 1"
    assert_includes initial_condition, "Test Plant Loop 1", "Initial condition should include existing heater's plant loop"
    assert_includes initial_condition, "2014", "Initial condition should include existing heater's capacity"
    assert_includes initial_condition, "54", "Initial condition should include existing heater's size"
    
    assert_includes initial_condition, "Test Existing Heater 2"
    assert_includes initial_condition, "Test Plant Loop 2", "Initial condition should include existing heater's plant loop"
    assert_includes initial_condition, "1964", "Initial condition should include existing heater's capacity"
    assert_includes initial_condition, "47", "Initial condition should include existing heater's size"   
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
    assert_includes final_condition, "4000 W"
    assert_includes final_condition, "36 gal" # Tank size is reduced by 10%
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
    set_argument("water_heater_capacity", 4143)
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds.first

    assert_equal 4143, heater.heaterMaximumCapacity.get
  end

  def test_new_plant_loop_heater_has_specified_volume
    set_argument("storage_tank_volume", 34) # 34 gallons, 0.128704 m^3
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds.first

    # 1 gal = 0.0037854117839698515 m^3
    
    assert_in_delta 0.90 * 34 * 0.0037854117839698515, heater.tankVolume.get, 0.000001 # match within a mL
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

  def test_storage_tank_volume_for_general_specified_size
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]

    assert_in_delta 0.9 * 0.15142, heater.tankVolume.get, 0.001 # 40 gal = 0.15142 m^3
    refute heater.isTankVolumeAutosized
  end

  def test_storage_tank_volume_for_general_autosized
    set_argument("storage_tank_volume", 0)

    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]

    assert heater.isTankVolumeAutosized
  end

  # This ia a doubly-parameterized test case, testing 4 table values for each of NCTH and B10 cases
  ["NCTH", "B10 Benchmark"].each do |standard|
    [[1,"1.5",30, 0.11356 ], [3,"2", 50,0.18927], [2,"1", 30,0.11356], [4, "3",66, 0.24984 ],].each do | testcase |
      (beds, baths, gallons, si_result) = testcase
      define_method("test_#{standard}_with_#{beds}_and_#{baths}_has_#{gallons}_gallon_tank") do
        set_argument("object_to_be_created", "Create a water heater representing #{standard} standard")
        set_argument("number_of_bedrooms", beds)
        set_argument("number_of_bathrooms", baths)
        @measure.run(@model, @runner, @argument_map)
        
        heater = @model.getWaterHeaterMixeds[0]
        refute_nil heater
        refute heater.tankVolume.empty?
        assert_in_delta 0.90 * si_result, heater.tankVolume.get, 0.00001
      end
    end
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

  ["NCTH", "B10 Benchmark", "BA Pre-Retrofit Case"].each do |standard|
    define_method("test_setpoint_temperature_for_#{standard}_uses_125F") do
      set_argument("object_to_be_created", "Create a water heater representing #{standard} standard")
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
      assert_in_delta 51.7, schedule_for_default_day.values[0], 0.1 # 125F is 51.6667C
    end
  end

  def test_deadband_temp_should_be_2C
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]

    assert_equal 2, heater.deadbandTemperatureDifference
  end
  
  def test_max_temp_limit_should_be_100C
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]

    assert_equal 100, heater.maximumTemperatureLimit.get
  end
  

  def test_heater_control_type_should_be_modulate
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]

    assert_equal "Modulate", heater.heaterControlType
  end

  # This ia a doubly-parameterized test case, testing 4 table values for each of NCTH and B10 cases
  ["NCTH", "B10 Benchmark"].each do |standard|
    [[1,"1.5",2.5 ], [3,"2", 5.5], [2,"1", 3.5], [3, "1.5",4.5 ],].each do | testcase |
      (beds, baths, capacity) = testcase
      define_method("test_#{standard}_with_#{beds}_and_#{baths}_has_#{capacity}_capacity") do
        set_argument("object_to_be_created", "Create a water heater representing #{standard} standard")
        set_argument("number_of_bedrooms", beds)
        set_argument("number_of_bathrooms", baths)
        @measure.run(@model, @runner, @argument_map)
        
        heater = @model.getWaterHeaterMixeds[0]
        refute_nil heater
        refute heater.tankVolume.empty?
        si_result = capacity * 1000
        assert_in_delta si_result, heater.heaterMaximumCapacity.get, 1
      end
    end
  end

  def test_general_has_capacity_from_input
    set_argument("water_heater_capacity", 2700)
    @measure.run(@model, @runner, @argument_map)
        
    heater = @model.getWaterHeaterMixeds[0]
    refute_nil heater
    refute heater.tankVolume.empty?
    assert_equal 2700, heater.heaterMaximumCapacity.get
  end
  
  def test_BA_Retrofit_has_capacity_from_input
    set_argument("water_heater_capacity", 2732)
    set_argument("object_to_be_created", "Create a water heater representing BA Pre-Retrofit Case standard")
    @measure.run(@model, @runner, @argument_map)
        
    heater = @model.getWaterHeaterMixeds[0]
    refute_nil heater
    refute heater.tankVolume.empty?
    assert_equal 2732, heater.heaterMaximumCapacity.get
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
  
  def test_water_heater_fuel_is_electric
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_equal "Electricity", heater.heaterFuelType
  end
  
  def test_water_heater_thermal_efficiency_is_1
    @measure.run(@model, @runner, @argument_map)

    heater = @model.getWaterHeaterMixeds[0]
    assert_in_delta 1.0, heater.heaterThermalEfficiency.get, 0.01
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
      assert_in_delta watts_per_kelvin, heater.offCycleLossCoefficienttoAmbientTemperature.get, 0.001
    end
  end

  [[1,"2",1.0067], [5,"3",1.82383]].each do |beds, baths, watts_per_kelvin|
    define_method("test_ba_protocol_water_heater_loss_coefficients_for_#{beds}_beds_#{baths}_baths_is_#{watts_per_kelvin}") do
      set_argument("object_to_be_created", "Create a water heater representing NCTH standard")
      set_argument("number_of_bedrooms", beds)
      set_argument("number_of_bathrooms", baths)

      @measure.run(@model, @runner, @argument_map)

      heater = @model.getWaterHeaterMixeds[0]
      assert_in_delta watts_per_kelvin, heater.offCycleLossCoefficienttoAmbientTemperature.get, 0.001
      assert_in_delta watts_per_kelvin, heater.onCycleLossCoefficienttoAmbientTemperature.get, 0.001
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
      assert_in_delta watts_per_kelvin, heater.onCycleLossCoefficienttoAmbientTemperature.get, 0.001
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

    assert_info_contains "Water heater of type", "General", "36 gal"
    assert_info_contains "A schedule named SHW Set Temp was created and applied to", heater.name.get
    assert_info_contains "Water heater '#{heater.name.get}' has a deadband temperature difference of 2 K"
    assert_info_contains "Water heater '#{heater.name.get}' has a maximum temperature limit of 212 F"
    assert_info_contains "Water heater '#{heater.name.get}' has a heater maximum capacity of 4000 W"
    assert_info_contains "Water heater '#{heater.name.get}' has a heater minimum capacity of 0 W"
    assert_info_contains "Water heater '#{heater.name.get}' has a heater fuel type of 'Electricity'"
    assert_info_contains "Water heater '#{heater.name.get}' has a heater thermal efficiency of 1"
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
      "object_to_be_created" => "General",
      "number_of_bedrooms" => "2",
      "number_of_bathrooms" => "3",
      "existing_plant_loop_name" => "New Plant Loop",
      "storage_tank_volume" => 40,
      "rated_energy_factor" => 0.95,
      "shw_setpoint_temperature" => 130,
      "water_heater_location" => "Thermal Zone 1",
      "water_heater_capacity" => 4000,
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
