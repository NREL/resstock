# frozen_string_literal: true

require 'csv'

# allcols = ['Annual Name', 'Annual Units', 'Timeseries Name', 'Timeseries Units', 'Notes']
outputs = CSV.read(File.join(File.dirname(__FILE__), '../../../../resources/data/dictionary/outputs.csv'), headers: true)

csv_tables = {
  # 'characteristics.csv' => { 'annual' => false, 'timeseries' => false, 'kws' => ['.build_existing_model'] },
  'simulation_outputs.csv' => { 'annual' => true, 'timeseries' => true, 'kws' => ['.end_use_', '.energy_use_', 'fuel_use_', '.hot_water_', '.hvac_capacity_', '.hvac_design_', '.load_', '.peak_', '.unmet_hours_'] },
  'cost_multipliers.csv' => { 'annual' => true, 'timeseries' => false, 'kws' => ['upgrade_costs.'] },
  'component_loads.csv' => { 'annual' => true, 'timeseries' => true, 'kws' => ['.component_load_'] },
  'emissions.csv' => { 'annual' => true, 'timeseries' => true, 'kws' => ['.emissions_'] },
  'utility_bills.csv' => { 'annual' => true, 'timeseries' => false, 'kws' => ['report_utility_bills.'] },
  'qoi_report.csv' => { 'annual' => true, 'timeseries' => false, 'kws' => ['qoi_report.'] },
  'other_timeseries.csv' => { 'annual' => false, 'timeseries' => true, 'kws' => [nil] }
}

csv_tables_dir = File.join(File.dirname(__FILE__), 'csv_tables')
Dir.mkdir(csv_tables_dir) if !File.exist?(csv_tables_dir)
csv_tables.each do |csv_file, table_info|
  annual = table_info['annual']
  timeseries = table_info['timeseries']
  kws = table_info['kws']

  usecols = []
  usecols += ['Annual Name', 'Annual Units'] if annual
  usecols += ['Timeseries Name', 'Timeseries Units'] if timeseries
  usecols += ['Notes']

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
