# frozen_string_literal: true

require 'csv'

usecols = ['Annual Name', 'Annual Units', 'Timeseries Name', 'Timeseries Units', 'Notes']
outputs = CSV.read(File.join(File.dirname(__FILE__), '../../../../resources/data/dictionary/outputs.csv'), headers: true)

csv_tables = {
  # 'characteristics.csv' => ['.build_existing_model'],
  'simulation_outputs.csv' => ['.end_use', 'fuel_use', '.energy_use'],
  'cost_multipliers.csv' => ['.upgrade_costs'],
  'component_loads.csv' => ['.component_load'],
  'emissions.csv' => ['.emissions'],
  'utility_bills.csv' => ['report_utility_bills.'],
  'qoi_report.csv' => ['qoi_report.'],
  'other.csv' => [nil]
}

csv_tables_dir = File.join(File.dirname(__FILE__), 'csv_tables')
Dir.mkdir(csv_tables_dir) if !File.exist?(csv_tables_dir)
csv_tables.each do |csv_file, kws|
  puts csv_file
  csv_path = File.join(csv_tables_dir, csv_file)
  CSV.open(csv_path, 'wb') do |csv|
    csv << usecols
    outputs.each do |row|
      if row['Annual Name'].nil?
        next if !kws.include?(nil)
      else
        next if kws.include?(nil)
        next if !kws.any? { |kw| row['Annual Name'].include?(kw) }
      end

      new_row = []
      usecols.each do |usecol|
        new_row << row[usecol]
      end
      csv << new_row
    end
  end
end
