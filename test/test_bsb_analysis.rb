# frozen_string_literal: true

require_relative 'minitest_helper'
require 'minitest/autorun'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..')
load 'Rakefile'
require 'rubygems/package'
require 'zlib'

class TesBuildStockBatch < MiniTest::Test
  def before_setup
    @testing_baseline = 'projects/project_testing/testing_baseline'
    @national_baseline = 'projects/project_national/national_baseline'
    @testing_upgrades = 'projects/project_testing/testing_upgrades'
    @national_upgrades = 'projects/project_national/national_upgrades'
  end

  def test_testing_baseline
    assert(File.exist?(File.join(@testing_baseline, 'results_csvs', 'results_up00.csv.gz')))

    up00 = []

    simulations_job = File.join(@testing_baseline, 'simulation_output', 'simulations_job0.tar.gz')
    assert(File.exist?(simulations_job))
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(simulations_job))
    tar_extract.rewind
    tar_extract.each do |entry|
      next unless entry.file?

      scenario, sample, subfolder, filename = entry.full_name.split('/')
      if subfolder == 'run' && scenario == 'up00'
        up00 << filename
      end
    end
    tar_extract.close

    assert(up00.include?('data_point_out.json'))
    assert(up00.include?('existing.osw'))
    assert(!up00.include?('upgraded.osw'))
    assert(up00.include?('results_timeseries.csv'))
    assert(!up00.include?('in.idf'))
    assert(!up00.include?('schedules.csv'))
  end

  def test_national_baseline
    assert(File.exist?(File.join(@national_baseline, 'results_csvs', 'results_up00.csv.gz')))

    up00 = []

    simulations_job = File.join(@national_baseline, 'simulation_output', 'simulations_job0.tar.gz')
    assert(File.exist?(simulations_job))
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(simulations_job))
    tar_extract.rewind
    tar_extract.each do |entry|
      next unless entry.file?

      scenario, sample, subfolder, filename = entry.full_name.split('/')
      if subfolder == 'run' && scenario == 'up00'
        up00 << filename
      end
    end
    tar_extract.close

    assert(up00.include?('data_point_out.json'))
    assert(up00.include?('existing.osw'))
    assert(!up00.include?('upgraded.osw'))
    assert(up00.include?('results_timeseries.csv'))
    assert(!up00.include?('in.idf'))
    assert(!up00.include?('schedules.csv'))
  end

  def test_testing_upgrades
    assert(File.exist?(File.join(@testing_upgrades, 'results_csvs', 'results_up00.csv.gz')))
    assert(File.exist?(File.join(@testing_upgrades, 'results_csvs', 'results_up01.csv.gz')))

    up01 = []

    simulations_job = File.join(@testing_upgrades, 'simulation_output', 'simulations_job0.tar.gz')
    assert(File.exist?(simulations_job))
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(simulations_job))
    tar_extract.rewind
    tar_extract.each do |entry|
      next unless entry.file?

      scenario, sample, subfolder, filename = entry.full_name.split('/')
      if subfolder == 'run' && scenario == 'up01'
        up01 << filename
      end
    end
    tar_extract.close

    assert(up01.include?('data_point_out.json'))
    assert(up01.include?('existing.osw'))
    assert(up01.include?('upgraded.osw'))
    assert(up01.include?('results_timeseries.csv'))
    assert(!up01.include?('in.idf'))
    assert(!up01.include?('schedules.csv'))
  end

  def test_national_upgrades
    assert(File.exist?(File.join(@national_upgrades, 'results_csvs', 'results_up00.csv.gz')))
    assert(File.exist?(File.join(@national_upgrades, 'results_csvs', 'results_up01.csv.gz')))

    up01 = []

    simulations_job = File.join(@national_upgrades, 'simulation_output', 'simulations_job0.tar.gz')
    assert(File.exist?(simulations_job))
    tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(simulations_job))
    tar_extract.rewind
    tar_extract.each do |entry|
      next unless entry.file?

      scenario, sample, subfolder, filename = entry.full_name.split('/')
      if subfolder == 'run' && scenario == 'up01'
        up01 << filename
      end
    end
    tar_extract.close

    assert(up01.include?('data_point_out.json'))
    assert(up01.include?('existing.osw'))
    assert(up01.include?('upgraded.osw'))
    assert(up01.include?('results_timeseries.csv'))
    assert(!up01.include?('in.idf'))
    assert(!up01.include?('schedules.csv'))
  end
end
