# frozen_string_literal: true

require 'csv'

# Example args: https://github.com/NREL/resstock/blob/develop/resources/hpxml-measures/workflow/hpxml_inputs.json
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

  def sample_rated_capacity_bin(prng, rated_capacity_map, args)
    if args[:heating_system_fuel] == HPXML::FuelTypeElectricity
      row_probability = rated_capacity_map[[
        args[:clothes_dyers],
        args[:cooking_ranges],
        args[:geometry_unit_type],
        args[:geometry_unit_cfa_bin], 
        args[:cooling_system_type],
        args[:pv_system_present],
        args[:vintage],
        args[:water_heater_fuel_type],
        ]]
    else
      row_probability = rated_capacity_map[[
        args[:geometry_unit_type], 
        args[:geometry_unit_cfa_bin], 
        args[:vintage]
        ]]
    capacity_bin = weighted_random(prng, row_probability)
    
    return capacity_bin
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

  def read_rated_capacity_probs(heating_system_fuel)
    if heating_system_fuel == HPXML::FuelTypeElectricity
      file = "resources/electrical_panel_rated_capacity__electric_heating.csv"
    else
      file = "resources/electrical_panel_rated_capacity__nonelectric_heating.csv"
    end
    probabilities = CSV.read(file)
    probabilities = probabilities.map { |entry| entry[0].to_f }
    return probabilities
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

end
