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

def href_to_rst(str)
  urls_names = str.scan(/<a href='(.+?)'>(.+?)<\/a>/)
  return str if urls_names.empty?

  urls_names.each do |url_name|
    url, name = url_name

    str = str.gsub("<a href='#{url}'>#{name}</a>", "`#{name} <#{url}>`_")
  end
  return str
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
    desc = href_to_rst(desc.text)
  end
  resstockarguments[name] = [units, choices, desc]
end

f = File.open(File.join(File.dirname(__FILE__), 'characteristics.rst'), 'w')
f.puts('.. _housing_characteristics:')
f.puts
f.puts('Housing Characteristics')
f.puts('=======================')
f.puts
f.puts('Each parameter sampled by the national project is listed alphabetically below.')
f.puts('For each, the following (if applicable) are reported based on the contents of `source_report.csv <https://github.com/NREL/resstock/blob/develop/project_national/resources/source_report.csv>`_:')
f.puts
f.puts('- **Description**')
f.puts('- **Created by**')
f.puts('- **Source**')
f.puts('- **Assumption**')
f.puts
f.puts("Additionally for each parameter, an **Arguments** table is populated (if applicable) based on the contents of `ResStockArguments's measure.xml file <https://github.com/NREL/resstock/blob/develop/measures/ResStockArguments/measure.xml>`_:")
f.puts
f.puts('- **Name**')
f.puts('- **Units**')
f.puts('- **Choices**')
f.puts('- **Description**')
f.puts
f.puts('Each argument name is assigned using defined options found in the `options_lookup.tsv <https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv>`_.')
f.puts('Furthermore, all *optional* choice arguments include "auto" as one of the possible **Choices**.')
f.puts('Some *optional* double/integer/string/bool arguments can also be assigned a value of "auto" (e.g., ``site_ground_conductivity``).')
f.puts('Assigning "auto" means that downstream OS-HPXML default values (if applicable) will be used.')
f.puts('The **Description** field may include link(s) to applicable `OpenStudio-HPXML documentation <https://openstudio-hpxml.readthedocs.io/en/latest/?badge=latest>`_ describing these default values.')
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

  r_arguments = r_arguments.sort_by &resstockarguments.keys.method(:index)
  r_arguments.each do |r_argument|
    f.puts("   * - ``#{r_argument}``")

    units = resstockarguments[r_argument][0]
    choices = resstockarguments[r_argument][1]
    desc = resstockarguments[r_argument][2]
    f.puts("     - #{units}")
    if choices.empty?
      f.puts('     -')
    else
      f.puts("     - \"#{choices.join('", "')}\"")
    end
    f.puts("     - #{desc}")
  end
  f.puts
end
