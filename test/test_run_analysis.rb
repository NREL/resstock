# frozen_string_literal: true

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../resources/buildstock'
require_relative '../test/analysis'
require 'openstudio'

class TestRunAnalysis < MiniTest::Test
  def before_setup
    cli_path = OpenStudio.getOpenStudioCLI
    @command = "\"#{cli_path}\" workflow/run_analysis.rb"

    buildstock_directory = File.join(File.dirname(__FILE__), '..')

    @testing_baseline = File.join(buildstock_directory, 'testing_baseline')
    @national_baseline = File.join(buildstock_directory, 'national_baseline')
    @testing_upgrades = File.join(buildstock_directory, 'testing_upgrades')
    @national_upgrades = File.join(buildstock_directory, 'national_upgrades')
  end

  def _test_measure_order(osw)
    expected_order = ['BuildExistingModel',
                      'ApplyUpgrade',
                      'ReportSimulationOutput',
                      'ReportHPXMLOutput',
                      'UpgradeCosts',
                      'QOIReport',
                      'ServerDirectoryCleanup']
    json = JSON.parse(File.read(osw), symbolize_names: true)
    actual_order = json[:steps].collect { |k, v| k[:measure_dir_name] }
    expected_order &= actual_order # subset expected_order to what's in actual_order
    assert_equal(expected_order, actual_order)
  end

  def test_version
    @command += ' -v'

    cli_output = `#{@command}`

    assert("#{Version.software_program_used} v#{Version.software_program_version}", cli_output)
  end

  def test_errors_wrong_path
    yml = ' -y test/yml_bad_value/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    assert(cli_output.include?("Error: YML file does not exist at 'test/yml_bad_value/testing_baseline.yml'."))
  end

  def test_errors_bad_value
    yml = ' -y test/tests_yml_files/yml_bad_value/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    assert(cli_output.include?('Failures detected for: 1, 2.'))

    cli_output_log = File.read(File.join(@testing_baseline, 'cli_output.log'))
    assert(cli_output_log.include?('ERROR'))
    assert(cli_output_log.include?('Run Period End Day of Month (32) must be one of'))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_errors_already_exists
    yml = ' -y test/tests_yml_files/yml_bad_value/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`
    cli_output = `#{@command}`

    assert(cli_output.include?("Output directory 'testing_baseline' already exists."))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_errors_downselect_resample
    yml = ' -y test/tests_yml_files/yml_resample/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    assert(cli_output.include?("Not supporting residential_quota_downselect's 'resample' at this time."))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_errors_weather_files
    yml = ' -y test/tests_yml_files/yml_weather_files/testing_baseline.yml'
    @command += yml

    FileUtils.rm_rf(File.join(File.dirname(__FILE__), '../weather'))
    cli_output = `#{@command}`

    assert(cli_output.include?("Must include 'weather_files_url' or 'weather_files_path' in yml."))
    assert(!File.exist?(File.join(File.dirname(__FILE__), '../weather')))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_errors_downsampler
    yml = ' -y test/tests_yml_files/yml_downsampler/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    assert(cli_output.include?("Sampler type 'residential_quota_downsampler' is invalid or not supported."))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_errors_missing_key
    yml = ' -y test/tests_yml_files/yml_missing_key/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    assert(cli_output.include?("Both 'build_existing_model' and 'simulation_output_report' must be included in yml."))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_measures_only
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -m'

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(!File.exist?(File.join(@testing_baseline, 'run1', 'eplusout.sql')))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_sampling_only
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -s'

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(!File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'buildstock.csv')))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_building_id
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -i 1'

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(!File.exist?(File.join(@testing_baseline, 'run2')))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_threads_and_keep_run_folders
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -n 1'
    @command += ' -k'

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'run2')))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_testing_baseline
    yml = ' -y project_testing/testing_baseline.yml'
    @command += yml
    @command += ' -k'

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'results-Baseline.csv')))
    results = CSV.read(File.join(@testing_baseline, 'results-Baseline.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@testing_baseline, 'run1', 'run')))
    contents = Dir[File.join(@testing_baseline, 'run1', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_baseline, 'run*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))

    assert(File.exist?(File.join(@testing_baseline, 'cli_output.log')))
    assert(!File.read(File.join(@testing_baseline, 'cli_output.log')).include?('ERROR'))

    assert(File.exist?(File.join(@testing_baseline, 'osw', 'Baseline', '1.osw')))
    assert(File.exist?(File.join(@testing_baseline, 'xml', 'Baseline', '1.xml')))

    FileUtils.rm_rf(@testing_baseline)
  end

  def test_national_baseline
    yml = ' -y project_national/national_baseline.yml'
    @command += yml
    @command += ' -k'

    system(@command)

    _test_measure_order(File.join(@national_baseline, 'national_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@national_baseline, 'results-Baseline.csv')))
    results = CSV.read(File.join(@national_baseline, 'results-Baseline.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@national_baseline, 'run1', 'run')))
    contents = Dir[File.join(@national_baseline, 'run1', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@national_baseline, 'run*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))

    assert(File.exist?(File.join(@national_baseline, 'cli_output.log')))
    assert(!File.read(File.join(@national_baseline, 'cli_output.log')).include?('ERROR'))

    assert(File.exist?(File.join(@national_baseline, 'osw', 'Baseline', '1.osw')))
    assert(File.exist?(File.join(@national_baseline, 'xml', 'Baseline', '1.xml')))

    FileUtils.rm_rf(@national_baseline)
  end

  def test_testing_upgrades
    yml = ' -y project_testing/testing_upgrades.yml'
    @command += yml
    @command += ' -d'
    @command += ' -k'

    system(@command)

    _test_measure_order(File.join(@testing_upgrades, 'testing_upgrades-Baseline.osw'))
    assert(File.exist?(File.join(@testing_upgrades, 'results-Baseline.csv')))
    results = CSV.read(File.join(@testing_upgrades, 'results-Baseline.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@testing_upgrades, 'run1', 'run')))
    contents = Dir[File.join(@testing_upgrades, 'run1', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    _test_measure_order(File.join(@testing_upgrades, 'testing_upgrades-Windows.osw'))
    assert(File.exist?(File.join(@testing_upgrades, 'results-Windows.csv')))
    results = CSV.read(File.join(@testing_upgrades, 'results-Windows.csv'), headers: true)

    _test_columns(results, true)

    assert(File.exist?(File.join(@testing_upgrades, 'run6', 'run')))
    contents = Dir[File.join(@testing_upgrades, 'run6', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_upgrades, 'run*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))

    assert(File.exist?(File.join(@testing_upgrades, 'cli_output.log')))
    assert(!File.read(File.join(@testing_upgrades, 'cli_output.log')).include?('ERROR'))

    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'Baseline', '1-existing.osw')))
    assert(!File.exist?(File.join(@testing_upgrades, 'osw', 'Baseline', '1-upgraded.osw')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Baseline', '1-existing-defaulted.xml')))
    assert(!File.exist?(File.join(@testing_upgrades, 'xml', 'Baseline', '1-upgraded-defaulted.xml')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Baseline', '1-existing.xml')))
    assert(!File.exist?(File.join(@testing_upgrades, 'xml', 'Baseline', '1-upgraded.xml')))

    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'Windows', '1-existing.osw')))
    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'Windows', '1-upgraded.osw')))
    assert(!File.exist?(File.join(@testing_upgrades, 'xml', 'Windows', '1-existing-defaulted.xml')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Windows', '1-upgraded-defaulted.xml')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Windows', '1-existing.xml')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Windows', '1-upgraded.xml')))

    FileUtils.rm_rf(@testing_upgrades)
  end

  def test_national_upgrades
    yml = ' -y project_national/national_upgrades.yml'
    @command += yml
    @command += ' -d'
    @command += ' -k'

    system(@command)

    _test_measure_order(File.join(@national_upgrades, 'national_upgrades-Baseline.osw'))
    assert(File.exist?(File.join(@national_upgrades, 'results-Baseline.csv')))
    results = CSV.read(File.join(@national_upgrades, 'results-Baseline.csv'), headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@national_upgrades, 'run1', 'run')))
    contents = Dir[File.join(@national_upgrades, 'run1', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, false)

    _test_measure_order(File.join(@national_upgrades, 'national_upgrades-Windows.osw'))
    assert(File.exist?(File.join(@national_upgrades, 'results-Windows.csv')))
    results = CSV.read(File.join(@national_upgrades, 'results-Windows.csv'), headers: true)

    _test_columns(results, true)

    assert(File.exist?(File.join(@national_upgrades, 'run6', 'run')))
    contents = Dir[File.join(@national_upgrades, 'run6', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@national_upgrades, 'run*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))

    assert(File.exist?(File.join(@national_upgrades, 'cli_output.log')))
    assert(!File.read(File.join(@national_upgrades, 'cli_output.log')).include?('ERROR'))

    assert(File.exist?(File.join(@national_upgrades, 'osw', 'Baseline', '1-existing.osw')))
    assert(!File.exist?(File.join(@national_upgrades, 'osw', 'Baseline', '1-upgraded.osw')))
    assert(File.exist?(File.join(@national_upgrades, 'xml', 'Baseline', '1-existing-defaulted.xml')))
    assert(!File.exist?(File.join(@national_upgrades, 'xml', 'Baseline', '1-upgraded-defaulted.xml')))
    assert(File.exist?(File.join(@national_upgrades, 'xml', 'Baseline', '1-existing.xml')))
    assert(!File.exist?(File.join(@national_upgrades, 'xml', 'Baseline', '1-upgraded.xml')))

    assert(File.exist?(File.join(@national_upgrades, 'osw', 'Windows', '1-existing.osw')))
    assert(File.exist?(File.join(@national_upgrades, 'osw', 'Windows', '1-upgraded.osw')))
    assert(!File.exist?(File.join(@national_upgrades, 'xml', 'Windows', '1-existing-defaulted.xml')))
    assert(File.exist?(File.join(@national_upgrades, 'xml', 'Windows', '1-upgraded-defaulted.xml')))
    assert(File.exist?(File.join(@national_upgrades, 'xml', 'Windows', '1-existing.xml')))
    assert(File.exist?(File.join(@national_upgrades, 'xml', 'Windows', '1-upgraded.xml')))

    FileUtils.rm_rf(@national_upgrades)
  end
end
