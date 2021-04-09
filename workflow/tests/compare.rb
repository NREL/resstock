require 'csv'

folder = 'comparisons'
files = Dir[File.join(File.dirname(__FILE__), 'base_results/results*')].map { |x| File.basename(x) }

dir = File.join(File.dirname(__FILE__), folder)
unless Dir.exist?(dir)
  Dir.mkdir(dir)
end

files.each do |file|
  # load file
  base_rows = CSV.read(File.join(File.dirname(__FILE__), "base_results/#{file}"))
  feature_rows = CSV.read(File.join(File.dirname(__FILE__), "results/#{file}"))

  # get columns
  base_cols = base_rows[0]
  feature_cols = feature_rows[0]

  # get data
  base = {}
  base_rows[1..-1].each do |row|
    hpxml = row[0]
    base[hpxml] = {}
    row[1..-1].each_with_index do |field, i|
      begin
        base[hpxml][base_cols[i + 1]] = Float(field)
      rescue
      end
    end
  end

  feature = {}
  feature_rows[1..-1].each do |row|
    hpxml = row[0]
    feature[hpxml] = {}
    row[1..-1].each_with_index do |field, i|
      begin
        feature[hpxml][feature_cols[i + 1]] = Float(field)
      rescue
      end
    end
  end

  # get hpxml union
  base_hpxmls = base_rows.transpose[0][1..-1]
  feature_hpxmls = feature_rows.transpose[0][1..-1]
  hpxmls = base_hpxmls | feature_hpxmls

  # get column union
  cols = base_cols | feature_cols

  # create comparison table
  rows = [cols]
  hpxmls.each do |hpxml|
    row = [hpxml]
    cols.each do |col|
      next if col == 'HPXML'

      begin
        base_field = base[hpxml][col]
      rescue
      end

      begin
        feature_field = feature[hpxml][col]
      rescue
      end

      m = 'N/A'
      if (not base_field.nil?) && (not feature_field.nil?)
        m = "#{(feature_field - base_field).round(1)}"
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
end
