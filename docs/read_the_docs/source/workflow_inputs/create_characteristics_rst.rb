# frozen_string_literal: true

require 'csv'

source_report = CSV.read(File.join(File.dirname(__FILE__), '../../../../project_national/resources/source_report.csv'), headers: true)

def write_subsection(f, row, name, sc)
  return if row[name].nil?

  f.puts(name)
  f.puts(sc * name.size)
  f.puts
  f.puts(row[name].tr('\\', '/'))
  f.puts
end

class String
  def to_underscore_case
    gsub(/::/, '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr('-', '_')
      .tr(' ', '_')
      .downcase
  end

  def intersection(other)
    str = dup
    other.split(//).inject(0) do |sum, char|
      sum += 1 if str.sub!(char, '')
      sum
    end
  end
end

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

f = File.open(File.join(File.dirname(__FILE__), 'characteristics.rst'), 'w')
f.puts('.. _housing_characteristics:')
f.puts
f.puts('Housing Characteristics')
f.puts('=======================')
f.puts

resstock_arguments = []
source_report.each do |row|
  parameter = row['Parameter']

  # ref
  f.puts(".. _#{parameter.to_underscore_case}:")
  f.puts

  # section
  f.puts(parameter)
  f.puts('-' * parameter.size)
  f.puts

  write_subsection(f, row, 'Description', '*')
  write_subsection(f, row, 'Created by', '*')
  write_subsection(f, row, 'Source', '*')
  write_subsection(f, row, 'Assumption', '*')

  # Arguments
  r_arguments = []
  lookup_csv_data.each do |lookup_row|
    next if lookup_row[0] != parameter
    next if lookup_row[2] != 'ResStockArguments'

    lookup_row[3..-1].each do |argument_value|
      argument, _value = argument_value.split('=')
      r_arguments << argument if !r_arguments.include?(argument)
    end
  end
  next if r_arguments.empty?

  resstock_arguments += r_arguments

  name = 'Arguments'
  f.puts(name)
  f.puts('*' * name.size)
  f.puts
  f.puts('.. list-table::')
  f.puts('   :header-rows: 1')
  f.puts
  f.puts('   * - Used in Lookup')
  r_arguments.sort.each do |r_argument|
    f.puts("   * - #{r_argument}")
  end
  f.puts
end

# Arguments Available
f = File.open(File.join(File.dirname(__FILE__), 'arguments_available.rst'), 'w')
f.puts('.. _arguments_available:')
f.puts
f.puts('Arguments Available')
f.puts('===================')
f.puts
f.puts('The following is a sorted list of arguments that are not assigned in ``options_lookup.tsv``.')
f.puts('An argument may not be assigned in ``options_lookup.tsv`` because:')
f.puts
f.puts('1. It is instead assigned using ResStock :ref:`model-measures`, or')
f.puts('2. It is an optional argument.')
f.puts
f.puts('.. list-table::')
f.puts('   :header-rows: 1')
f.puts
f.puts('   * - Available for Use')
(build_arguments - resstock_arguments).sort.each do |argument|
  f.puts("   * - #{argument}")
end
