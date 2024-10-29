# frozen_string_literal: true

require 'csv'

# HPXML declared values: https://github.com/NREL/OpenStudio-HPXML/blob/master/HPXMLtoOpenStudio/resources/hpxml.rb
class RatedCapacityGenerator
  def initialize(runner:,
                 **)
    @runner = runner
  end

  def assign_rated_capacity(args:)
    # initialize a random number generator
    prng = Random.new(args[:building_id])

    # load probability distribution csv
    capacity_prob_map = read_rated_capacity_probs(args[:heating_system_fuel])

    # assign rated capacity bin and value
    capacity_bin = sample_rated_capacity_bin(prng, capacity_prob_map, args)
    capacity_value = convert_capacity_bin_to_value(capacity_bin, args[:heating_system_fuel], args[:geometry_unit_cfa_bin])

    return capacity_bin, capacity_value
  end

  def assign_breaker_spaces_headroom(args:)
    # initialize a random number generator
    prng = Random.new(args[:building_id])

    # load probability distribution csv
    breaker_spaces_headroom_prob_map = read_breaker_spaces_headroom_probs()

    # assign breaker space headroom number
    breaker_spaces_headroom = sample_breaker_spaces_headroom(prng, breaker_spaces_headroom_prob_map, args)

    return breaker_spaces_headroom
  end

  def sample_rated_capacity_bin(prng, rated_capacity_map, args)
    # emulate Geometry Building Type RECS
    geometry_building_type_recs = convert_building_type(args[:geometry_unit_type], args[:geometry_building_num_units])
    # get default vintage if nil (for project_testing)
    if args[:vintage].nil?
      vintage = '1960s'
    else
      vintage = args[:vintage]
    end

    if args[:heating_system_fuel] == HPXML::FuelTypeElectricity
      # emulate HVAC Cooling Type
      hvac_cooling_type = convert_cooling_type(args[:cooling_system_type], args[:heat_pump_type])

      # simplify appliance presence and fuel
      clothes_dryer = convert_fuel_and_presence(args[:clothes_dryer_present], args[:clothes_dryer_fuel_type])
      cooking_range = convert_fuel_and_presence(args[:cooking_range_oven_present], args[:cooking_range_fuel_type])
      water_heater_fuel_type = simplify_fuel_type(args[:water_heater_fuel_type])

      lookup_array = [
        clothes_dryer,
        cooking_range,
        geometry_building_type_recs,
        args[:geometry_unit_cfa_bin],
        hvac_cooling_type,
        args[:pv_system_present].to_s,
        vintage,
        water_heater_fuel_type,
      ]
    else
      lookup_array = [
        geometry_building_type_recs,
        args[:geometry_unit_cfa_bin],
        vintage,
      ]
    end
    capacity_bins = get_row_headers(rated_capacity_map, lookup_array)
    row_probability = get_row_probability(rated_capacity_map, lookup_array)
    index = weighted_random(prng, row_probability)
    return capacity_bins[index]
  end

  def sample_breaker_spaces_headroom(prng, breaker_spaces_headroom_prob_map, args)
    # get panel capacity bin 
    cap_bin, cap_val = assign_rated_capacity(args: args)

    # emulate HVAC Cooling Type 
    hvac_cooling_type = convert_cooling_type(args[:cooling_system_type], args[:heat_pump_type])
    # emulate HVAC Heating Type 
    hvac_heating_type = convert_heating_type(args[:heat_pump_type])

    # simplify appliance presence and fuel
    clothes_dryer = convert_fuel_and_presence(args[:clothes_dryer_present], args[:clothes_dryer_fuel_type])
    cooking_range = convert_fuel_and_presence(args[:cooking_range_oven_present], args[:cooking_range_fuel_type])
    water_heater_fuel_type = simplify_fuel_type(args[:water_heater_fuel_type])
    heating_fuel_type = simplify_fuel_type(args[:heating_system_fuel])
    ev_charger_present = 'FALSE'

    lookup_array = [
      hvac_cooling_type,
      hvac_heating_type,
      heating_fuel_type,
      water_heater_fuel_type,
      clothes_dryer,
      cooking_range,
      args[:pv_system_present].to_s.upcase,
      ev_charger_present.to_s,
      cap_bin.to_s,
    ]
    breaker_spaces_headroom = get_row_headers_breaker_spaces_headroom(breaker_spaces_headroom_prob_map, lookup_array)
    row_probability = get_row_probability_breaker_spaces_headroom(breaker_spaces_headroom_prob_map, lookup_array)
    index = weighted_random(prng, row_probability)
    return breaker_spaces_headroom[index]
  end

  def convert_capacity_bin_to_value(capacity_bin, heating_system_fuel, geometry_unit_cfa_bin)
    if capacity_bin == '<100'
      if heating_system_fuel == HPXML::FuelTypeElectricity
        return 90
      else
        return 60
      end
    elsif capacity_bin == '101-124'
      return 120
    elsif capacity_bin == '126-199'
      return 150
    elsif capacity_bin == '201+'
      if geometry_unit_cfa_bin == '3000-3999'
        return 300
      elsif geometry_unit_cfa_bin == '4000+'
        return 400
      else
        return 250
      end
    else
      return Float(capacity_bin)
    end
  end

  def read_rated_capacity_probs(heating_system_fuel)
    if heating_system_fuel == HPXML::FuelTypeElectricity
      filename = 'electrical_panel_rated_capacity__electric_heating.csv'
    else
      filename = 'electrical_panel_rated_capacity__nonelectric_heating.csv'
    end
    file = File.absolute_path(File.join(File.dirname(__FILE__), 'electrical_panel_resources', filename))
    prob_table = CSV.read(file)
    return prob_table
  end

  def read_breaker_spaces_headroom_probs()
    filename = 'electrical_panel_breaker_space.csv'
    file = File.absolute_path(File.join(File.dirname(__FILE__), 'electrical_panel_resources', filename))
    prob_table = CSV.read(file)
    return prob_table
  end

  def get_row_headers(prob_table, lookup_array)
    len = lookup_array.length()
    row_headers = prob_table[0][len..len + 7]
    return row_headers
  end

  def get_row_headers_breaker_spaces_headroom(prob_table, lookup_array)
    len = lookup_array.length()
    row_headers = prob_table[0][len..len + 32]
    return row_headers
  end

  def get_row_probability(prob_table, lookup_array)
    len = lookup_array.length()
    row_probability = []
    prob_table.each do |row|
      next if row[0..len - 1] != lookup_array

      row_probability = row[len..len + 7].map(&:to_f)
    end

    if row_probability.length() != 7
      @runner.registerError("RatedCapacityGenerator cannot find row_probability for keys: #{lookup_array}")
    end
    return row_probability
  end

  def get_row_probability_breaker_spaces_headroom(prob_table, lookup_array)
    len = lookup_array.length()
    row_probability = []
    prob_table.each do |row|
      next if row[0..len - 1] != lookup_array

      row_probability = row[len..len + 32].map(&:to_f)
    end

    if row_probability.length() != 32
      @runner.registerError("BreakerSpacesHeadroomGenerator cannot find row_probability for keys: #{lookup_array}")
    end
    return row_probability
  end

  def weighted_random(prng, weights)
    n = prng.rand
    cum_weights = 0
    weights.each_with_index do |w, index|
      cum_weights += w
      if n <= cum_weights
        return index
      end
    end
    return weights.size - 1 # If the prob weight don't sum to n, return last index
  end

  def convert_building_type(geometry_unit_type, geometry_building_num_units)
    if geometry_unit_type == HPXML::ResidentialTypeApartment
      if geometry_building_num_units < 5
        return 'apartment unit, 2-4'
      else
        return 'apartment unit, 5+'
      end
    elsif [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeSFD, HPXML::ResidentialTypeManufactured].include?(geometry_unit_type)
      return geometry_unit_type
    else
      @runner.registerError("RatedCapacityGenerator does not support geometry_unit_type: '#{geometry_unit_type}'.")
    end
  end

  def convert_cooling_type(cooling_system_type, heat_pump_type)
    if [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeRoomAirConditioner].include?(cooling_system_type)
      return cooling_system_type
    elsif cooling_system_type == HPXML::TypeNone
      if heat_pump_type != HPXML::TypeNone
        return 'heat pump'
      else
        return 'none'
      end
    elsif cooling_system_type == HPXML::HVACTypeMiniSplitAirConditioner
      # shared cooling, use none for lookup (note: this would be different if assigned via tsv since shared cooling is not none in HVAC Cooling Type)
      return 'none'
    else
      @runner.registerError("RatedCapacityGenerator cannot determine cooling type based on '#{args[:system_cooling_type]}' and '#{args[:heat_pump_type]}'.")
    end
  end

  def convert_heating_type(heat_pump_type)
    if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpGroundToAir].include?(heat_pump_type)
      return 'ASHP or GHP'
    else
      return 'not ASHP or GHP'
    end
  end

  def convert_fuel_and_presence(equipment_present, fuel_type)
    if equipment_present == 'false'
      return 'none'
    else
      return simplify_fuel_type(fuel_type)
    end
  end

  def simplify_fuel_type(fuel_type)
    if fuel_type == HPXML::FuelTypeElectricity
      return fuel_type
    else
      return 'non-electricity'
    end
  end
end
