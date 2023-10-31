# frozen_string_literal: true

require 'csv'
require 'oga'

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

resstockarguments = {}
resstockarguments_xml = Oga.parse_xml(File.read(File.join(resources_dir, '../measures/ResStockArguments/measure.xml')))
resstockarguments_xml.xpath('//measure/arguments/argument').each do |argument|
  name = argument.at_xpath('name').text
  units = argument.at_xpath('units')
  choices = []
  argument.xpath('choices/choice').each do |choice|
    choices << choice.at_xpath('value').text
  end
  desc = argument.at_xpath('description')
  if units.nil?
    units = ''
  else
    units = units.text
  end
  if desc.nil?
    puts "Warning: argument '#{name}' does not have a description."
    desc = ''
  else
    desc = desc.text
  end
  resstockarguments[name] = [units, choices, desc]
end

f = File.open(File.join(File.dirname(__FILE__), 'characteristics.rst'), 'w')
f.puts('.. _housing_characteristics:')
f.puts
f.puts('Housing Characteristics')
f.puts('=======================')
f.puts

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
  f.puts('   * - Name')
  f.puts('     - Units')
  f.puts('     - Choices')
  f.puts('     - Description')
  r_arguments.sort.each do |r_argument|
    f.puts("   * - ``#{r_argument}``")

    units = resstockarguments[r_argument][0]
    choices = resstockarguments[r_argument][1]
    desc = resstockarguments[r_argument][2]
    f.puts("     - #{units}")
    if !choices.empty?
      choices.each_with_index do |choice, i|
        if i == 0
          f.puts("     - | #{choice}")
        else
          f.puts("       | #{choice}")
        end
      end
    else
      f.puts('     -')
    end
    f.puts("     - #{desc}")
  end
  f.puts
end
