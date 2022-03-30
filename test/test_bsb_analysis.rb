# frozen_string_literal: true

require 'minitest/autorun'
require 'rubygems/package'
require 'zlib'
require 'csv'

class TesBuildStockBatch < MiniTest::Test
  def before_setup
    @testing_baseline = 'project_testing/testing_baseline'
    @national_baseline = 'project_national/national_baseline'
    @testing_upgrades = 'project_testing/testing_upgrades'
    @national_upgrades = 'project_national/national_upgrades'

    # check that up00 (baseline) contains these files
    @expected_baseline_contents = [
      'data_point_out.json',
      'existing.xml',
      'results_timeseries.csv'
    ]

    # check that up01 (upgrade) contains these files
    @expected_upgrade_contents = @expected_baseline_contents + [
      'upgraded.xml'
    ]

    # check that results_timeseries.csv contains these column prefixes
    @expected_timeseries_columns = [
      'TimeDST',
      'TimeUTC',
      'Energy Use: Total',
      'Energy Use: Net',
      'Fuel Use: Electricity: Total',
      'End Use: Natural Gas: Heating',
      'Emissions: CO2e: LRMER_MidCase_15: Total'
    ]
  end

  def _get_timeseries_columns(timeseries, entry)
    CSV.new(entry.read).each_with_index do |row, i|
      next if i != 0

      row.each do |col|
        timeseries << col if !timeseries.include?(col)
      end
    end
  end

  def test_testing_baseline
    assert(File.exist?(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv.gz')))

    up00 = []
    timeseries = []

    simulations_job = File.join(@testing_baseline, 'simulation_output', 'simulations_job0.tar.gz')
    assert(File.exist?(simulations_job))
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(simulations_job))
    tar_extract.rewind
    tar_extract.each do |entry|
      next unless entry.file?

      scenario, sample, subfolder, filename = entry.full_name.split('/')
      next unless subfolder == 'run' && scenario == 'up00'

      up00 << filename if !up00.include?(filename)
      _get_timeseries_columns(timeseries, entry) if filename == 'results_timeseries.csv'
    end
    tar_extract.close

    @expected_baseline_contents.each do |file|
      assert(up00.include?(file))
    end
    assert(up00.include?('in.osm'))
    assert(up00.include?('in.idf'))
    assert(up00.include?('schedules.csv'))

    (@expected_upgrade_contents - @expected_baseline_contents).each do |file|
      assert(!up00.include?(file))
    end

    @expected_timeseries_columns.each do |col|
      assert(timeseries.include?(col))
    end
    assert(timeseries.include?('Zone People Occupant Count: Living Space'))
  end

  def test_national_baseline
    assert(File.exist?(File.join(@national_baseline, 'results_csvs', 'results_up00.csv.gz')))

    up00 = []
    timeseries = []

    simulations_job = File.join(@national_baseline, 'simulation_output', 'simulations_job0.tar.gz')
    assert(File.exist?(simulations_job))
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(simulations_job))
    tar_extract.rewind
    tar_extract.each do |entry|
      next unless entry.file?

      scenario, sample, subfolder, filename = entry.full_name.split('/')
      next unless subfolder == 'run' && scenario == 'up00'

      up00 << filename if !up00.include?(filename)
      _get_timeseries_columns(timeseries, entry) if filename == 'results_timeseries.csv'
    end
    tar_extract.close

    @expected_baseline_contents.each do |file|
      assert(up00.include?(file))
    end

    (@expected_upgrade_contents - @expected_baseline_contents).each do |file|
      assert(!up00.include?(file))
    end

    @expected_timeseries_columns.each do |col|
      assert(timeseries.include?(col))
    end
  end

  def test_testing_upgrades
    assert(File.exist?(File.join(@testing_upgrades, 'results_csvs', 'results_up00.csv.gz')))
    assert(File.exist?(File.join(@testing_upgrades, 'results_csvs', 'results_up01.csv.gz')))

    up01 = []
    timeseries = []

    simulations_job = File.join(@testing_upgrades, 'simulation_output', 'simulations_job0.tar.gz')
    assert(File.exist?(simulations_job))
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(simulations_job))
    tar_extract.rewind
    tar_extract.each do |entry|
      next unless entry.file?

      scenario, sample, subfolder, filename = entry.full_name.split('/')
      next unless subfolder == 'run' && scenario == 'up01'

      up01 << filename if !up01.include?(filename)
      _get_timeseries_columns(timeseries, entry) if filename == 'results_timeseries.csv'
    end
    tar_extract.close

    @expected_upgrade_contents.each do |file|
      assert(up01.include?(file))
    end
    assert(up01.include?('in.osm'))
    assert(up01.include?('in.idf'))
    assert(up01.include?('schedules.csv'))

    @expected_timeseries_columns.each do |col|
      assert(timeseries.include?(col))
    end
    assert(timeseries.include?('Zone People Occupant Count: Living Space'))
  end

  def test_national_upgrades
    assert(File.exist?(File.join(@national_upgrades, 'results_csvs', 'results_up00.csv.gz')))
    assert(File.exist?(File.join(@national_upgrades, 'results_csvs', 'results_up01.csv.gz')))

    up01 = []
    timeseries = []

    simulations_job = File.join(@national_upgrades, 'simulation_output', 'simulations_job0.tar.gz')
    assert(File.exist?(simulations_job))
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(simulations_job))
    tar_extract.rewind
    tar_extract.each do |entry|
      next unless entry.file?

      scenario, sample, subfolder, filename = entry.full_name.split('/')
      next unless subfolder == 'run' && scenario == 'up01'

      up01 << filename if !up01.include?(filename)
      _get_timeseries_columns(timeseries, entry) if filename == 'results_timeseries.csv'
    end
    tar_extract.close

    @expected_upgrade_contents.each do |file|
      assert(up01.include?(file))
    end

    @expected_timeseries_columns.each do |col|
      assert(timeseries.include?(col))
    end
  end
end
