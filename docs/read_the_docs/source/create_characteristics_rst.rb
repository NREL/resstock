# frozen_string_literal: true

require 'csv'

source_report = CSV.read(File.join(File.dirname(__FILE__), '../../../project_national/resources/source_report.csv'), headers: true)

def write_subsection(f, row, name, sc)
  f.puts(name)
  f.puts(sc * name.size)
  f.puts
  f.puts(row[name].tr('\\', '/')) if !row[name].nil?
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

f = File.open(File.join(File.dirname(__FILE__), 'characteristics.rst'), 'w')
f.puts('.. _housing_characteristics:')
f.puts
f.puts('Housing Characteristics')
f.puts('=======================')
f.puts
f.puts("The following is populated based on the national project's `source_report.csv <https://github.com/NREL/resstock/blob/data-dictionary/project_national/resources/source_report.csv>`_.")
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

  write_subsection(f, row, 'Created by', '*')
  write_subsection(f, row, 'Source', '*')
  write_subsection(f, row, 'Assumption', '*')
end
