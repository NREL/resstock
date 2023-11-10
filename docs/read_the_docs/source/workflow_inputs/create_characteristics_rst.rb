# frozen_string_literal: true

require 'csv'
require 'oga'

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

def write_subsection(f, row, name, sc, delim)
  return if row[name].nil?

  f.puts(name)
  f.puts(sc * name.size)
  f.puts
  entry = row[name].tr('\\', '/')
  entry = "``#{entry}``" if entry.include?('.py')
  if !delim.nil?
    items = []
    entries = entry.split(delim).map(&:strip)
    entries.each do |entry|
      if entry.start_with?(/\[\d\]/)
        item = "  - \\#{entry}"
      else
        item = "- \\#{entry}"
      end
      items << item
      items << ''
    end
    entry = items
  end
  f.puts(entry)
  f.puts
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

buildreshpxmlarguments = {}
buildreshpxmlarguments_xml = Oga.parse_xml(File.read(File.join(resources_dir, 'hpxml-measures/BuildResidentialHPXML/measure.xml')))
buildreshpxmlarguments_xml.xpath('//measure/arguments/argument').each do |argument|
  name = argument.at_xpath('name').text
  type = argument.at_xpath('type')
  req = argument.at_xpath('required')
  buildreshpxmlarguments[name] = [type, req]
end

resstockarguments = {}
resstockarguments_xml = Oga.parse_xml(File.read(File.join(resources_dir, '../measures/ResStockArguments/measure.xml')))
resstockarguments_xml.xpath('//measure/arguments/argument').each do |argument|
  name = argument.at_xpath('name').text

  # Units
  units = argument.at_xpath('units')
  if units.nil?
    units = ''
  else
    units = units.text
  end

  # Required
  req = buildreshpxmlarguments[name][1] if buildreshpxmlarguments.keys.include?(name)
  if req.nil?
    req = argument.at_xpath('required')
    if req.nil?
      req = ''
    else
      req = req.text
    end
  else
    req = req.text
  end

  # Type
  type = buildreshpxmlarguments[name][0] if buildreshpxmlarguments.keys.include?(name)
  if type.nil?
    type = argument.at_xpath('type')
    if type.nil?
      type = ''
    else
      type = type.text
    end
  else
    type = type.text
  end

  # Choices
  choices = []
  argument.xpath('choices/choice').each do |choice|
    choices << choice.at_xpath('value').text
  end
  choices.unshift('auto') if req == 'false' && ['String', 'Double', 'Integer'].include?(type) && buildreshpxmlarguments.keys.include?(name)

  # Description
  desc = argument.at_xpath('description')
  if desc.nil?
    puts "Warning: argument '#{name}' does not have a description."
    desc = ''
  else
    desc = href_to_rst(desc.text)
  end
  resstockarguments[name] = [units, req, type, choices, desc]
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
f.puts('- **Required**')
f.puts('- **Type**')
f.puts('- **Choices**')
f.puts('- **Description**')
f.puts
f.puts('Each argument name is assigned using defined options found in the `options_lookup.tsv <https://github.com/NREL/resstock/blob/develop/resources/options_lookup.tsv>`_.')
f.puts('Furthermore, all *optional* choice arguments include "auto" as one of the possible **Choices**.')
f.puts('Some *optional* double/integer/string/bool arguments can also be assigned a value of "auto" (e.g., ``site_ground_conductivity``).')
f.puts('Assigning "auto" means that downstream OS-HPXML default values (if applicable) will be used.')
f.puts('The **Description** field may include link(s) to applicable `OpenStudio-HPXML documentation <https://openstudio-hpxml.readthedocs.io/en/latest/?badge=latest>`_ describing these default values.')
f.puts

subsection_names = ['Description', 'Created by', 'Source', 'Assumption']
source_report = CSV.read(File.join(File.dirname(__FILE__), '../../../../project_national/resources/source_report.csv'), headers: true)
source_report.each do |row|
  parameter = row['Parameter']

  # ref
  f.puts(".. _#{parameter.to_underscore_case}:")
  f.puts

  # section
  f.puts(parameter)
  f.puts('-' * parameter.size)
  f.puts

  subsection_names.each do |subsection_name|
    # delim = nil
    delim = ';' if ['Source', 'Assumption'].include?(subsection_name)
    write_subsection(f, row, subsection_name, '*', delim)
  end

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
  f.puts('     - Required')
  f.puts('     - Type')
  f.puts('     - Choices')
  f.puts('     - Description')

  r_arguments = r_arguments.sort_by &resstockarguments.keys.method(:index)
  r_arguments.each do |r_argument|
    f.puts("   * - ``#{r_argument}``")

    units = resstockarguments[r_argument][0]
    req = resstockarguments[r_argument][1]
    type = resstockarguments[r_argument][2]
    choices = resstockarguments[r_argument][3]
    desc = resstockarguments[r_argument][4]
    f.puts("     - #{units}")
    f.puts("     - #{req}")
    f.puts("     - #{type}")
    if choices.empty?
      f.puts('     -')
    else
      f.puts("     - \"#{choices.join('", "')}\"")
    end
    f.puts("     - #{desc}")
  end
  f.puts
end
