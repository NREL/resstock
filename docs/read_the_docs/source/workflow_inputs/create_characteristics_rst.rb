# frozen_string_literal: true

require 'csv'
require "#{File.dirname(__FILE__)}/../../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/hpxml.rb"

source_report = CSV.read(File.join(File.dirname(__FILE__), '../../../../project_national/resources/source_report.csv'), headers: true)

def write_subsection(f, row, name, sc)
  return if row[name].nil?

  f.puts(name)
  f.puts(sc * name.size)
  f.puts
  entry = row[name].tr('\\', '/')
  entry = "``#{entry}``" if entry.include?('.py')
  f.puts(entry)
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
end

resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../../resources'))
lookup_file = File.join(resources_dir, 'options_lookup.tsv')
lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a

buildreshpxml_measure = File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/measure.rb')
buildreshpxml_measure = File.readlines(buildreshpxml_measure)

resstockarguments_measure = File.join(resources_dir, '../measures/ResStockArguments/measure.rb')
resstockarguments_measure = File.readlines(resstockarguments_measure)

f = File.open(File.join(File.dirname(__FILE__), 'characteristics.rst'), 'w')
f.puts('.. _housing_characteristics:')
f.puts
f.puts('Housing Characteristics')
f.puts('=======================')
f.puts

set_description = '.setDescription'
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

  name = 'Arguments'
  f.puts(name)
  f.puts('*' * name.size)
  f.puts
  f.puts('.. list-table::')
  f.puts('   :header-rows: 1')
  f.puts
  f.puts('   * - Argument')
  f.puts('     - Description')
  r_arguments.sort.each do |r_argument|
    f.puts("   * - ``#{r_argument}``")

    desc = nil
    [buildreshpxml_measure, resstockarguments_measure].each do |measure|
      m = measure.each_index.select { |i| /'#{r_argument}'/.match(measure[i]) }
      if !m.empty?
        measure[m[0]..m[0] + 5].each do |line|
          next if !line.include?(set_description)

          desc = eval(line[line.index(set_description) + set_description.size + 1..-3])
        end
      end
      break if !desc.nil?
    end

    desc = '' if desc.nil?
    f.puts("     - #{desc}")
  end
  f.puts
end
