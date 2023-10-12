# frozen_string_literal: true

require 'csv'

resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../../resources'))
lookup_file = File.join(resources_dir, 'options_lookup.tsv')
lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a

build_arguments = []
File.readlines(File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/measure.rb')).each do |line|
  next if !line.include?('arg = OpenStudio::Measure::OSArgument')
  next if line.include?('emissions')
  next if line.include?('utility_bill')

  build_arguments << line.split("'")[1]
end

resstock_arguments = { 'Air Leakage' => [],
                       'Bathroom Fans' => [],
                       'Battery' => [],
                       'Ceiling' => [],
                       'Clothes Dryer' => [],
                       'Clothes Washer' => [],
                       'Cooking Range' => [],
                       'Cooling System' => [],
                       'Dehumidifier' => [],
                       'Dishwasher' => [],
                       'Door' => [],
                       'Ducts' => [],
                       'DWHR' => [],
                       'Exterior' => [],
                       'Extra Refrigerator' => [],
                       'Floor' => [],
                       'Foundation Wall' => [],
                       'Freezer' => [],
                       'Geometry' => [],
                       'Heat Pump' => [],
                       'Heating System' => [],
                       'Holiday Lighting' => [],
                       'Hot Water Distribution' => [],
                       'HVAC Control' => [],
                       'Kitchen Fans' => [],
                       'Lighting' => [],
                       'Mech Vent' => [],
                       'Misc Fuel Loads' => [],
                       'Misc Plug Loads' => [],
                       'Neighbor' => [],
                       'Overhangs' => [],
                       'Permanent Spa' => [],
                       'Pool' => [],
                       'PV System' => [],
                       'Refrigerator' => [],
                       'Rim Joist' => [],
                       'Roof' => [],
                       'Schedules' => [],
                       'Simulation Control' => [],
                       'Site' => [],
                       'Skylight' => [],
                       'Slab' => [],
                       'Solar Thermal' => [],
                       'Use Auto' => [],
                       'Vintage' => [],
                       'Wall' => [],
                       'Water Fixtures' => [],
                       'Water Heater' => [],
                       'Weather Station' => [],
                       'Whole House Fan' => [],
                       'Window' => [] }

class String
  def to_underscore_case
    gsub(/::/, '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr('-', '_')
      .tr(' ', '_')
      .downcase
  end
end

lookup_csv_data.each do |row|
  next if row[2] != 'ResStockArguments'

  row[3..-1].each do |argument_value|
    argument, _value = argument_value.split('=')
    category = resstock_arguments.keys.find { |k| argument.start_with?(k.to_underscore_case) }
    resstock_arguments[category] << argument if !resstock_arguments[category].include?(argument)
  end
end

f = File.open(File.join(File.dirname(__FILE__), 'resstock_arguments.rst'), 'w')
f.puts('.. _resstock_arguments:')
f.puts
f.puts('ResStock Arguments')
f.puts('==================')
f.puts

resstock_arguments.each do |category, r_arguments|
  f.puts(".. _#{category.to_underscore_case}:")
  f.puts

  f.puts(category)
  f.puts('-' * category.size)
  f.puts

  b_arguments = build_arguments.select { |arg_name| arg_name.start_with?(category.to_underscore_case) }
  b_arguments -= r_arguments

  f.puts('.. list-table::')
  f.puts('   :header-rows: 1')
  f.puts
  f.puts('   * - Used in Lookup')
  f.puts('     - Available for Use')
  r_arguments.sort.zip(b_arguments.sort).each do |r, b|
    f.puts("   * - #{r}")
    f.puts("     - #{b}")
  end
  f.puts
end
