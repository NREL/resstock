require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class AddWaterUseEquipmentObject_Test < Test::Unit::TestCase


	def set_argument(argument_map, key, value)
		arg = @arguments.find { |a| a.name == key }
		refute_nil arg, "Expected to find argument of name #{key}, but didn't."

		newArg = arg.clone
		assert(newArg.setValue(value), "Could not set argument #{key} to #{value}")
		argument_map[key] = newArg
	end

	def setup
		# create an instance of the measure
		@measure = AddWaterUseEquipmentObject.new
		# create an instance of a runner
		@runner = OpenStudio::Ruleset::OSRunner.new
		# make an empty model
		@model = OpenStudio::Model::Model.new
		
		["Space 1", "Space 2", "Space 3"].each do |s|
			OpenStudio::Model::Space.new(@model).setName(s)
		end
		
		OpenStudio::Model::PlantLoop.new(@model).setName("Plant Loop 1")

		@arguments = @measure.arguments(@model)
	end
	
	def default_args
		{
			"existing_plant_loop_name" => "Plant Loop 1",
			"using_standard_dhw_event_schedules" => true,
			"number_of_bedrooms" => "2",
			"shower_gpd" => 10.2,
			"bath_gpd" => 8.1,
			"sinks_gpd" => 7.5,
			"shower_sinks_bath_space_name" => "Space 1",
			"clothes_washer_gpd" => 12.8,
			"clothes_washer_space_name" => "Space 2",
			"dishwasher_gpd" => 2.4,
			"dishwasher_space_name" => "Space 3",
			"avg_annual_temp" => 58,
			"min_monthly_avg_temp" => 12,
			"max_monthly_avg_temp" => 82,
			"distribution_type" => "Trunk and Branch",
			"distribution_location" => "Basement or Interior Space",
			"pipe_material" => "Copper",
			"recirculation_type" => "None",
			"insulation_nominal_r_value" => 3.0,
			"using_distribution" => false
		}
	end

	def test_faucets_added_to_loop
		argument_map = OpenStudio::Ruleset::OSArgumentMap.new

		args = default_args
		args.each { |key, value| set_argument(argument_map, key, value) }
		
		@measure.run(@model, @runner, argument_map)
		
		loop = @model.getPlantLoops[0]

		# Loop should have showers, sinks and bath water use equipment added to it
		use_equipment = @model.getWaterUseEquipments
		showers = use_equipment.find { |e| e.name.get == "showers" }
		sinks = use_equipment.find { |e| e.name.get == "sinks" }
		baths = use_equipment.find { |e| e.name.get == "baths" }
		
		assert_equal loop, showers.waterUseConnections.get.plantLoop.get
		assert_equal loop, sinks.waterUseConnections.get.plantLoop.get
		assert_equal loop, baths.waterUseConnections.get.plantLoop.get
	end

	def test_appliances_added_to_loop
		argument_map = OpenStudio::Ruleset::OSArgumentMap.new

		default_args.each { |key, value| set_argument(argument_map, key, value) }
		
		@measure.run(@model, @runner, argument_map)
		
		loop = @model.getPlantLoops[0]

		# Loop should have clothes washer and dishwasher use equipment added to it
		use_equipment = @model.getWaterUseEquipments
		clothes_washer = use_equipment.find { |e| e.name.get == "clothes_washer" }
		dishwasher = use_equipment.find { |e| e.name.get == "dishwasher" }
		
		assert_equal loop, clothes_washer.waterUseConnections.get.plantLoop.get
		assert_equal loop, dishwasher.waterUseConnections.get.plantLoop.get
	end

	def test_equipment_added_to_correct_spaces
		argument_map = OpenStudio::Ruleset::OSArgumentMap.new

		default_args.each { |key, value| set_argument(argument_map, key, value) }
		
		@measure.run(@model, @runner, argument_map)
		
		use_equipment = @model.getWaterUseEquipments
		
		space1 = @model.getSpaces.find { |s| s.name.get == "Space 1" }
		space2 = @model.getSpaces.find { |s| s.name.get == "Space 2" }
		space3 = @model.getSpaces.find { |s| s.name.get == "Space 3" }
		
		water_use_equipment_types = [:dishwasher, :clothes_washer, :showers, :baths, :sinks]
		expected_space = { :dishwasher => space3, :clothes_washer => space2, :showers => space1, :baths => space1, :sinks => space1 }
		
		water_use_equipment_types.each do |et|
			equipment = use_equipment.find { |e| e.name.get == "#{et}" }
			refute_nil equipment, "Equipment for #{et} not found"
			assert_equal expected_space[et], equipment.space.get
		end
	end

	def test_gains_equipment_added_to_correct_spaces
		argument_map = OpenStudio::Ruleset::OSArgumentMap.new

		default_args.each { |key, value| set_argument(argument_map, key, value) }
		
		@measure.run(@model, @runner, argument_map)
		
		use_equipment = @model.getOtherEquipments

		space1 = @model.getSpaces.find { |s| s.name.get == "Space 1" }
		
		water_use_equipment_types = [:showers, :baths, :sinks]
		expected_space = { :showers => space1, :baths => space1, :sinks => space1 }
		
		water_use_equipment_types.each do |et|
			equipment = use_equipment.find { |e| e.name.get == "#{et} internal gains" }
			refute_nil equipment, "Equipment for #{et} not found"
			assert_equal expected_space[et], equipment.space.get
		end
	end

	# Clothes washers and dishwashers have no internal gains (2.b)
	def test_no_gains_equipment_for_clothes_washers_and_dishwashers
		argument_map = OpenStudio::Ruleset::OSArgumentMap.new

		default_args.each { |key, value| set_argument(argument_map, key, value) }
		
		@measure.run(@model, @runner, argument_map)
		
		use_equipment = @model.getOtherEquipments
		
		assert_equal 3, use_equipment.length

		water_use_equipment_types = [:clothes_washer, :dishwasher]
		water_use_equipment_types.each do |et|
			equipment = use_equipment.find { |e| e.name.get == "#{et} internal gains" }
			assert_nil equipment, "Equipment for #{et} found but none expected"
		end
	end
	
	def test_turning_on_distribution_adds_pump
		# A waterheater with an ambient thermal zone set is required in order to add the recirculation pump
		tzone = OpenStudio::Model::ThermalZone.new(@model)
		space1 = @model.getSpaces.find { |s| s.name.get == "Space 1" }
		space1.setThermalZone(tzone)
		waterheater = OpenStudio::Model::WaterHeaterMixed.new(@model)
		waterheater.setAmbientTemperatureThermalZone(tzone)
		loop = @model.getPlantLoops[0]
		loop.addSupplyBranchForComponent(waterheater)
	
		argument_map = OpenStudio::Ruleset::OSArgumentMap.new
		default_args.merge({"using_distribution" => true}).each { |key, value| set_argument(argument_map, key, value) }
		@measure.run(@model, @runner, argument_map)
		
		use_equipment = @model.getOtherEquipments
		
		pump = use_equipment.find { |e| e.name.get == "#{:pump} internal gains" }
		refute_nil pump
	end

end
