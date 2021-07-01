# frozen_string_literal: true

require 'csv'

base = 'base'
feature = 'feature'
folder = 'comparisons' # comparison csv files will be exported to this folder
files = Dir[File.join(Dir.getwd, 'test/test_samples_osw/base/results*.csv')].map { |x| File.basename(x) }
files = files.sort # characteristics first to store building type map

dir = File.join(Dir.getwd, "test/test_samples_osw/#{folder}")
unless Dir.exist?(dir)
  Dir.mkdir(dir)
end

btype_hash = {}
files.each do |file|
  results = { base => {}, feature => {} }

  # load files
  results.keys.each do |key|
    if key == base
      results[key]['file'] = "test/test_samples_osw/base/#{file}"
    elsif key == feature
      results[key]['file'] = "test/test_samples_osw/results/#{file}"
    end

    filepath = File.join(Dir.getwd, results[key]['file'])
    if File.exist?(filepath)
      results[key]['rows'] = CSV.read(filepath)
    else
      puts "Could not find #{filepath}."
    end
  end

  if (not results[base].keys.include?('rows')) || (not results[feature].keys.include?('rows'))
    next
  end

  # get columns
  results.keys.each do |key|
    results[key]['cols'] = results[key]['rows'][0][1..-1] # exclude index column
  end

  # write column mapping
  cwd = Dir.getwd
  rows = CSV.read(File.join(Dir.getwd, 'test/column_mapping.csv'))
  col_map = {}
  feature_cols = []
  rows[1..-1].each do |row|
    next unless row[1]
    dev_row = row[1].split(',')
    dev_row = dev_row.map { |x| x.split('.')[1] }
    dev_row.each do |field|
      col_map[field] = row[0].split(',')[0]
    end
    feature_cols << row[0]
  end

  # use first column name for multiple feature cols
  feature_map = {}
  feature_cols.each do |col|
    col.split(',').each do |col_s|
      feature_map[col_s] = col.split(',')[0]
    end
  end

  results[feature]['cols'].each do |col|
    if col.include? 'build_existing_model'
      col_map[col.split('.')[1]] = col
    end
  end

  # get data
  results.keys.each do |key|
    results[key]['rows'][1..-1].each do |row|
      hpxml = row[0]
      results[key][hpxml] = {}
      row[1..-1].each_with_index do |field, i|
        col = results[key]['cols'][i]
        if field.nil?
          vals = [''] # string
        elsif field.include?(',')
          begin
            vals = field.split(',').map { |x| Float(x) } # float
            if col.split('_')[-1] == 'kwh'
              if col == 'electricity_heating_supplemental_kwh'
                vals[0] *= 3412.14 / 1000 # to kbtu
              else
                vals[0] *= 3412.14 / 1000000 # to mbtu
              end
            elsif col.split('_')[-1] == 'therm'
              vals[0] *= 0.1 # to mbtu
            end
          rescue ArgumentError
            vals = [field] # string
          end
        else
          begin
            vals = [Float(field)] # float
            if col.split('_')[-1] == 'kwh'
              if col == 'electricity_heating_supplemental_kwh'
                vals[0] *= 3412.14 / 1000 # to kbtu
              else
                vals[0] *= 3412.14 / 1000000 # to mbtu
              end
            elsif col.split('_')[-1] == 'therm'
              vals[0] *= 0.1 # to mbtu
            end
          rescue ArgumentError
            vals = [field] # string
          end
        end

        # Map base and feature cols
        if not col_map[col].nil?
          col = col_map[col]
        end
        if (key == feature) && (not feature_map[col].nil?)
          col = feature_map[col]
        end

        # Aggregate columns
        if results[key][hpxml][col]
          results[key][hpxml][col] += vals
        else
          results[key][hpxml][col] = vals
        end
      end
    end
  end

  # update 'cols' with mapped column names
  results[base]['cols'].each_with_index do |col, i|
    if not col_map[col].nil?
      results[base]['cols'][i] = col_map[col]
    end
  end
  results[feature]['cols'].each_with_index do |col, i|
    if not feature_map[col].nil?
      results[feature]['cols'][i] = feature_map[col]
    end
  end

  # get hpxml union
  base_hpxmls = results[base]['rows'].transpose[0][1..-1]
  feature_hpxmls = results[feature]['rows'].transpose[0][1..-1]
  hpxmls = base_hpxmls | feature_hpxmls

  # get column union
  base_cols = results[base]['cols']
  feature_cols = results[feature]['cols']
  cols = base_cols | feature_cols
  cols = cols.sort

  # create comparison table
  rows = [[results[base]['rows'][0][0]] + cols] # index column + union of all other columns

  # populate the rows hash
  hpxmls.sort.each do |hpxml|
    row = [hpxml]
    cols.each_with_index do |col, i|
      if results[base].keys.include?(hpxml) && (not results[feature].keys.include?(hpxml)) # feature removed an xml
        m = 'N/A'
      elsif (not results[base].keys.include?(hpxml)) && results[feature].keys.include?(hpxml) # feature added an xml
        m = 'N/A'
      elsif results[base][hpxml].keys.include?(col) && (not results[feature][hpxml].keys.include?(col)) # feature removed a column
        m = 'N/A'
      elsif (not results[base][hpxml].keys.include?(col)) && results[feature][hpxml].keys.include?(col) # feature added a column
        m = 'N/A'
      else
        base_field = results[base][hpxml][col]
        feature_field = results[feature][hpxml][col]

        begin
          # float comparisons
          m = []

          # sum multiple cols
          if base_field[0].is_a? Numeric
            base_field = [base_field.sum]
          end
          if feature_field[0].is_a? Numeric
            feature_field = [feature_field.sum]
          end

          base_field.zip(feature_field).each do |b, f|
            m << (f - b).round(1)
          end
        rescue *[NoMethodError, TypeError]
          # string comparisons
          m = []
          base_field.zip(feature_field).each do |b, f|
            if b != f
              m << 1
            else
              m << 0
            end
          end
        end
        m = m.reduce(:+)
      end

      row << m
    end

    rows << row
  end

  # export comparison table
  CSV.open(File.join(dir, file), 'wb') do |csv|
    rows.each do |row|
      csv << row
    end
  end

  # write building type hash
  if file.include? 'characteristics'
    btype_name_hash = { 'Single-Family Detached' => 'SFD',
                        'Mobile Home' => 'SFD',
                        'Single-Family Attached' => 'SFA',
                        'Multi-Family with 5+ Units' => 'MF',
                        'Multi-Family with 2 - 4 Units' => 'MF' }

    btype_hash = {}
    hpxmls.sort.each do |hpxml|
      btype_hash[hpxml] = btype_name_hash[results[base][hpxml]['build_existing_model.geometry_building_type_recs'][0]]
    end
  end

  # write aggregated results
  agg_cols = []
  agg_cols = rows[0].select { |x| ['simulation_output_report', 'upgrade_costs'].include? x.split('.')[0] }
  rows = [['enduse', 'building type', 'base', 'feature', 'diff', 'percent diff']]
  btypes = ['SFD', 'SFA', 'MF']

  agg_cols.each do |col|
    row_sum = { 'SFD' => [0, 0], 'SFA' => [0, 0], 'MF' => [0, 0] }
    base_field, feature_field = nil, nil

    # aggregate all osws
    hpxmls.sort.each do |hpxml|
      btype = btype_hash[hpxml]
      # btype = btype_hash[results[base][hpxml]['build_existing_model.geometry_building_type_recs'][0]]
      base_field = results[base][hpxml][col]
      feature_field = results[feature][hpxml][col]

      if base_field.nil? # has feature value but not base
        row_sum[btype][0] = 'N/A'
      end
      if feature_field.nil? # has base value but not feature
        row_sum[btype][1] = 'N/A'
      end

      # sum values
      if (not base_field.nil?) && base_field[0].is_a?(Numeric)
        row_sum[btype][0] += base_field.sum
      else
        row_sum[btype][0] = 'N/A'
      end
      if (not feature_field.nil?) && feature_field[0].is_a?(Numeric)
        row_sum[btype][1] += feature_field.sum
      else
        row_sum[btype][1] = 'N/A'
      end
    end

    # calculate absolute and percent diffs
    diff = {}
    percent = {}
    btypes.each do |btype|
      if (not base_field.nil?) && (not feature_field.nil?)
        if base_field[0].is_a?(Numeric) && feature_field[0].is_a?(Numeric)
          diff[btype] = (row_sum[btype][0] - row_sum[btype][1]).round(2)
          row_sum[btype] = row_sum[btype].map { |x| x.round(2) }
          if row_sum[btype][0] != 0
            percent[btype] = (100 * diff[btype] / row_sum[btype][0]).round(2)
          else
            percent[btype] = 'N/A'
          end
        else
          diff[btype] = 'N/A'
          percent[btype] = 'N/A'
        end
      else
        diff[btype] = 'N/A'
        percent[btype] = 'N/A'
      end
    end

    btypes.each do |btype|
      next unless (row_sum[btype][0] != 'N/A') || (row_sum[btype][1] != 'N/A')
      row = [col.split('.')[1]]
      row << btype
      row += row_sum[btype]
      row << diff[btype]
      row << percent[btype]
      rows << row
    end
  end

  # export aggregate comparision table
  CSV.open(File.join(dir, 'aggregate_results.csv'), 'wb') do |csv|
    rows.each do |row|
      csv << row
    end
  end
end
