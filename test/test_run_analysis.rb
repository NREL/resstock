# frozen_string_literal: true

require_relative 'minitest_helper'
require 'minitest/autorun'
require 'openstudio'

require_relative '../resources/measures/HPXMLtoOpenStudio/resources/version'

class TestRunAnalysis < MiniTest::Test
  def before_setup
    cli_path = OpenStudio.getOpenStudioCLI
    @command = "\"#{cli_path}\" workflow/run_analysis.rb"

    workflow_dir = File.join(File.dirname(__FILE__), '../workflow')
    @testing_baseline = File.join(workflow_dir, 'testing_baseline')
    @national_baseline = File.join(workflow_dir, 'national_baseline')
    @testing_upgrades = File.join(workflow_dir, 'testing_upgrades')
    @national_upgrades = File.join(workflow_dir, 'national_upgrades')
  end

  def test_version
    @command += ' -v'

    cli_output = `#{@command}`

    assert("#{Version.software_program_used} v#{Version.software_program_version}", cli_output)
  end

  def test_testing_baseline
    yml = ' -y project_testing/testing_baseline.yml'
    @command += yml

    system(@command)

    assert(File.exist?(File.join(@testing_baseline, 'results_characteristics.csv')))
    assert(File.exist?(File.join(@testing_baseline, 'results_output.csv')))

    assert(File.exist?(File.join(@testing_baseline, 'osw', 'Baseline', '1-measures.osw')))
    assert(!File.exist?(File.join(@testing_baseline, 'osw', 'Baseline', '1-measures-upgrade.osw')))

    assert(File.exist?(File.join(@testing_baseline, 'run1', 'run', 'data_point_out.json')))
    assert(File.exist?(File.join(@testing_baseline, 'run1', 'run', 'enduse_timeseries.csv')))
    assert(File.exist?(File.join(@testing_baseline, 'run1', 'run', 'in.idf')))
    assert(File.exist?(File.join(@testing_baseline, 'run1', 'run', 'schedules.csv')))
  end

  def test_national_baseline
    yml = ' -y project_national/national_baseline.yml'
    @command += yml

    system(@command)

    assert(File.exist?(File.join(@national_baseline, 'results_characteristics.csv')))
    assert(File.exist?(File.join(@national_baseline, 'results_output.csv')))

    assert(File.exist?(File.join(@national_baseline, 'osw', 'Baseline', '1-measures.osw')))
    assert(!File.exist?(File.join(@national_baseline, 'osw', 'Baseline', '1-measures-upgrade.osw')))

    assert(File.exist?(File.join(@national_baseline, 'run1', 'run', 'data_point_out.json')))
    assert(File.exist?(File.join(@national_baseline, 'run1', 'run', 'enduse_timeseries.csv')))
    assert(!File.exist?(File.join(@national_baseline, 'run1', 'run', 'in.idf')))
    assert(!File.exist?(File.join(@national_baseline, 'run1', 'run', 'schedules.csv')))
  end

  def test_testing_upgrades
    yml = ' -y project_testing/testing_upgrades.yml'
    @command += yml

    system(@command)

    assert(File.exist?(File.join(@testing_upgrades, 'results_characteristics.csv')))
    assert(File.exist?(File.join(@testing_upgrades, 'results_output.csv')))

    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'Baseline', '1-measures.osw')))
    assert(!File.exist?(File.join(@testing_upgrades, 'osw', 'Baseline', '1-measures-upgrade.osw')))

    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'Windows', '1-measures.osw')))
    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'Windows', '1-measures-upgrade.osw')))

    assert(File.exist?(File.join(@testing_upgrades, 'run1', 'run', 'data_point_out.json')))
    assert(File.exist?(File.join(@testing_upgrades, 'run1', 'run', 'enduse_timeseries.csv')))
    assert(File.exist?(File.join(@testing_upgrades, 'run1', 'run', 'in.idf')))
    assert(File.exist?(File.join(@testing_upgrades, 'run1', 'run', 'schedules.csv')))
  end

  def test_national_upgrades
    yml = ' -y project_national/national_upgrades.yml'
    @command += yml

    system(@command)

    assert(File.exist?(File.join(@national_upgrades, 'results_characteristics.csv')))
    assert(File.exist?(File.join(@national_upgrades, 'results_output.csv')))

    assert(File.exist?(File.join(@national_upgrades, 'osw', 'Baseline', '1-measures.osw')))
    assert(!File.exist?(File.join(@national_upgrades, 'osw', 'Baseline', '1-measures-upgrade.osw')))

    assert(File.exist?(File.join(@national_upgrades, 'osw', 'Windows', '1-measures.osw')))
    assert(File.exist?(File.join(@national_upgrades, 'osw', 'Windows', '1-measures-upgrade.osw')))

    assert(File.exist?(File.join(@national_upgrades, 'run1', 'run', 'data_point_out.json')))
    assert(File.exist?(File.join(@national_upgrades, 'run1', 'run', 'enduse_timeseries.csv')))
    assert(!File.exist?(File.join(@national_upgrades, 'run1', 'run', 'in.idf')))
    assert(!File.exist?(File.join(@national_upgrades, 'run1', 'run', 'schedules.csv')))
  end
end
