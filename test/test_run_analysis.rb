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

    FileUtils.rm_rf(@testing_baseline)
    FileUtils.rm_rf(@national_baseline)
    FileUtils.rm_rf(@testing_upgrades)
    FileUtils.rm_rf(@national_upgrades)
  end

  def _test_measure_order(osw)
    expected_order = ['BuildExistingModel',
                      'ApplyUpgrade',
                      'HPXMLtoOpenStudio',
                      'ReportSimulationOutput',
                      'ReportHPXMLOutput',
                      'ReportUtilityBills',
                      'UpgradeCosts',
                      'QOIReport',
                      'ServerDirectoryCleanup']
    json = JSON.parse(File.read(osw), symbolize_names: true)
    actual_order = json[:steps].collect { |k, _v| k[:measure_dir_name] }
    expected_order &= actual_order # subset expected_order to what's in actual_order
    assert_equal(expected_order, actual_order)
  end

  def _assert_and_puts(output, msg, expect_error = true)
    includes = output.include?(msg)
    if !includes && expect_error
      puts output
      assert(includes)
    elsif includes && !expect_error
      puts output
      assert(!includes)
    end
  end

  def test_version
    @command += ' -v'

    cli_output = `#{@command}`

    assert("ResStock v#{Version::ResStock_Version}", cli_output)
  end

  def test_errors_wrong_path
    yml = ' -y test/yml_bad_value/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    _assert_and_puts(cli_output, "Error: YML file does not exist at 'test/yml_bad_value/testing_baseline.yml'.")
  end

  def test_errors_bad_value
    yml = ' -y test/tests_yml_files/yml_bad_value/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    _assert_and_puts(cli_output, 'Failures detected for: 1, 2.')

    cli_output_log = File.read(File.join(@testing_baseline, 'cli_output.log'))
    _assert_and_puts(cli_output_log, 'ERROR')
    _assert_and_puts(cli_output_log, 'Run Period End Day of Month (32) must be one of')
  end

  def test_errors_already_exists
    yml = ' -y test/tests_yml_files/yml_bad_value/testing_baseline.yml'
    @command += yml

    `#{@command}`
    cli_output = `#{@command}`

    _assert_and_puts(cli_output, "Error: Output directory 'testing_baseline' already exists.")
  end

  def test_errors_downselect_resample
    yml = ' -y test/tests_yml_files/yml_resample/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    _assert_and_puts(cli_output, "Error: Not supporting residential_quota_downselect's 'resample' at this time.")
  end

  def test_errors_weather_files
    yml = ' -y test/tests_yml_files/yml_weather_files/testing_baseline.yml'
    @command += yml

    FileUtils.rm_rf(File.join(File.dirname(__FILE__), '../weather'))
    assert(!File.exist?(File.join(File.dirname(__FILE__), '../weather')))
    cli_output = `#{@command}`

    _assert_and_puts(cli_output, "Error: Must include 'weather_files_url' or 'weather_files_path' in yml.")
    assert(!File.exist?(File.join(File.dirname(__FILE__), '../weather')))
  end

  def test_errors_downsampler
    yml = ' -y test/tests_yml_files/yml_downsampler/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    _assert_and_puts(cli_output, "Error: Sampler type 'residential_quota_downsampler' is invalid or not supported.")
  end

  def test_errors_missing_key
    yml = ' -y test/tests_yml_files/yml_missing_key/testing_baseline.yml'
    @command += yml

    cli_output = `#{@command}`

    _assert_and_puts(cli_output, "Error: Both 'build_existing_model' and 'simulation_output_report' must be included in yml.")
  end

  def test_errors_precomputed_outdated_missing_parameter
    yml = ' -y test/tests_yml_files/yml_precomputed_outdated/testing_baseline_missing.yml'
    @command += yml

    `#{@command}`
    cli_output = File.read(File.join(@testing_baseline, 'cli_output.log'))

    _assert_and_puts(cli_output, 'Mismatch between buildstock.csv and options_lookup.tsv. Missing parameters: HVAC Cooling Partial Space Conditioning.')
  end

  def test_errors_precomputed_outdated_extra_parameter
    yml = ' -y test/tests_yml_files/yml_precomputed_outdated/testing_baseline_extra.yml'
    @command += yml

    `#{@command}`
    cli_output = File.read(File.join(@testing_baseline, 'cli_output.log'))

    _assert_and_puts(cli_output, 'Mismatch between buildstock.csv and options_lookup.tsv. Extra parameters: Extra Parameter.')
  end

  def test_measures_only
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -m'

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(!File.exist?(File.join(@testing_baseline, 'run1', 'eplusout.sql')))
  end

  def test_sampling_only
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -s'

    system(@command)

    assert(!File.exist?(File.join(@testing_baseline, 'testing_baseline-Baseline.osw')))
    assert(!File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'buildstock.csv')))
  end

  def test_building_id
    yml = ' -y test/tests_yml_files/yml_valid/testing_baseline.yml'
    @command += yml
    @command += ' -i 1'

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(!File.exist?(File.join(@testing_baseline, 'run2')))
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
  end

  def test_relative_weather_files_path
    yml = ' -y test/tests_yml_files/yml_relative_weather_path/testing_baseline.yml'
    @command += yml

    FileUtils.rm_rf(File.join(File.dirname(__FILE__), '../weather'))
    assert(!File.exist?(File.join(File.dirname(__FILE__), '../weather')))

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'run2')))

    FileUtils.rm_rf(File.join(File.dirname(__FILE__), '../weather'))
    assert(!File.exist?(File.join(File.dirname(__FILE__), '../weather')))
  end

  def test_precomputed
    yml = ' -y test/tests_yml_files/yml_precomputed/testing_baseline.yml'
    @command += yml

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'run2')))
    assert(!File.exist?(File.join(@testing_baseline, 'run3')))

    results_baseline = File.join(@testing_baseline, 'results-Baseline.csv')
    assert(File.exist?(results_baseline))
    results = CSV.read(results_baseline, headers: true)
    assert(results.headers.include?('build_existing_model.sample_weight'))
    assert_in_delta(results['build_existing_model.sample_weight'][0].to_f, 110000000 / 2, 0.001)
    assert_in_delta(results['build_existing_model.sample_weight'][1].to_f, 110000000 / 2, 0.001)
  end

  def test_precomputed_sample_weight
    yml = ' -y test/tests_yml_files/yml_precomputed_weight/testing_baseline.yml'
    @command += yml

    system(@command)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    assert(File.exist?(File.join(@testing_baseline, 'run1')))
    assert(File.exist?(File.join(@testing_baseline, 'run2')))
    assert(!File.exist?(File.join(@testing_baseline, 'run3')))

    results_baseline = File.join(@testing_baseline, 'results-Baseline.csv')
    assert(File.exist?(results_baseline))
    results = CSV.read(results_baseline, headers: true)
    assert(results.headers.include?('build_existing_model.sample_weight'))
    assert_in_delta(results['build_existing_model.sample_weight'][0].to_f, 226.2342, 0.001)
    assert_in_delta(results['build_existing_model.sample_weight'][1].to_f, 1.000009, 0.001)
  end

  def test_testing_baseline
    yml = ' -y project_testing/testing_baseline.yml'
    @command += yml
    @command += ' -k'

    system(@command)

    cli_output_log = File.join(@testing_baseline, 'cli_output.log')
    assert(File.exist?(cli_output_log))
    cli_output = File.read(cli_output_log)
    _assert_and_puts(cli_output, 'ERROR', false)

    _test_measure_order(File.join(@testing_baseline, 'testing_baseline-Baseline.osw'))
    results_baseline = File.join(@testing_baseline, 'results-Baseline.csv')
    assert(File.exist?(results_baseline))
    results = CSV.read(results_baseline, headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@testing_baseline, 'run1', 'run')))
    contents = Dir[File.join(@testing_baseline, 'run1', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_baseline, 'run*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))

    assert(File.exist?(File.join(@testing_baseline, 'osw', 'Baseline', '1.osw')))
    assert(File.exist?(File.join(@testing_baseline, 'xml', 'Baseline', '1.xml')))

    FileUtils.cp(results_baseline, File.join(File.dirname(@testing_baseline), 'project_testing'))
  end

  def test_national_baseline
    yml = ' -y project_national/national_baseline.yml'
    @command += yml
    @command += ' -k'

    system(@command)

    cli_output_log = File.join(@national_baseline, 'cli_output.log')
    assert(File.exist?(cli_output_log))
    cli_output = File.read(cli_output_log)
    _assert_and_puts(cli_output, 'ERROR', false)

    _test_measure_order(File.join(@national_baseline, 'national_baseline-Baseline.osw'))
    results_baseline = File.join(@national_baseline, 'results-Baseline.csv')
    assert(File.exist?(results_baseline))
    results = CSV.read(results_baseline, headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@national_baseline, 'run1', 'run')))
    contents = Dir[File.join(@national_baseline, 'run1', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@national_baseline, 'run*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))

    assert(!File.exist?(File.join(@national_baseline, 'osw', 'Baseline', '1.osw')))
    assert(File.exist?(File.join(@national_baseline, 'xml', 'Baseline', '1.xml')))

    FileUtils.cp(results_baseline, File.join(File.dirname(@national_baseline), 'project_national'))
  end

  def test_testing_upgrades
    yml = ' -y project_testing/testing_upgrades.yml'
    @command += yml
    @command += ' -d'
    @command += ' -k'

    system(@command)

    cli_output_log = File.join(@testing_upgrades, 'cli_output.log')
    assert(File.exist?(cli_output_log))
    cli_output = File.read(cli_output_log)
    _assert_and_puts(cli_output, 'ERROR', false)

    _test_measure_order(File.join(@testing_upgrades, 'testing_upgrades-Baseline.osw'))
    results_baseline = File.join(@testing_upgrades, 'results-Baseline.csv')
    assert(File.exist?(results_baseline))
    results = CSV.read(results_baseline, headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@testing_upgrades, 'run1', 'run')))
    contents = Dir[File.join(@testing_upgrades, 'run1', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, true)

    _test_measure_order(File.join(@testing_upgrades, 'testing_upgrades-AllUpgrades.osw'))
    results_allupgrades = File.join(@testing_upgrades, 'results-AllUpgrades.csv')
    assert(File.exist?(results_allupgrades))
    results = CSV.read(results_allupgrades, headers: true)

    _test_columns(results, true)

    assert(File.exist?(File.join(@testing_upgrades, 'run76', 'run')))
    contents = Dir[File.join(@testing_upgrades, 'run76', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true, true)

    timeseries = _get_timeseries_columns(Dir[File.join(@testing_upgrades, 'run*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries, true))

    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'Baseline', '1-existing.osw')))
    assert(!File.exist?(File.join(@testing_upgrades, 'osw', 'Baseline', '1-upgraded.osw')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'Baseline', '1-existing.xml')))
    assert(!File.exist?(File.join(@testing_upgrades, 'xml', 'Baseline', '1-upgraded.xml')))

    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'AllUpgrades', '1-existing.osw')))
    assert(File.exist?(File.join(@testing_upgrades, 'osw', 'AllUpgrades', '1-upgraded.osw')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'AllUpgrades', '1-existing.xml')))
    assert(File.exist?(File.join(@testing_upgrades, 'xml', 'AllUpgrades', '1-upgraded.xml')))

    FileUtils.cp(results_allupgrades, File.join(File.dirname(@testing_upgrades), 'project_testing'))
  end

  def test_national_upgrades
    yml = ' -y project_national/national_upgrades.yml'
    @command += yml
    @command += ' -d'
    @command += ' -k'

    system(@command)

    cli_output_log = File.join(@national_upgrades, 'cli_output.log')
    assert(File.exist?(cli_output_log))
    cli_output = File.read(cli_output_log)
    _assert_and_puts(cli_output, 'ERROR', false)

    _test_measure_order(File.join(@national_upgrades, 'national_upgrades-Baseline.osw'))
    results_baseline = File.join(@national_upgrades, 'results-Baseline.csv')
    assert(File.exist?(results_baseline))
    results = CSV.read(results_baseline, headers: true)

    _test_columns(results)

    assert(File.exist?(File.join(@national_upgrades, 'run1', 'run')))
    contents = Dir[File.join(@national_upgrades, 'run1', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, false, false)

    _test_measure_order(File.join(@national_upgrades, 'national_upgrades-AllUpgrades.osw'))
    results_allupgrades = File.join(@national_upgrades, 'results-AllUpgrades.csv')
    assert(File.exist?(results_allupgrades))
    results = CSV.read(results_allupgrades, headers: true)

    _test_columns(results, true)

    assert(File.exist?(File.join(@national_upgrades, 'run76', 'run')))
    contents = Dir[File.join(@national_upgrades, 'run76', 'run/*')].collect { |x| File.basename(x) }

    _test_contents(contents, true, false)

    timeseries = _get_timeseries_columns(Dir[File.join(@national_upgrades, 'run*/run/results_timeseries.csv')])
    assert(_test_timeseries_columns(timeseries))

    assert(!File.exist?(File.join(@national_upgrades, 'osw', 'Baseline', '1-existing.osw')))
    assert(!File.exist?(File.join(@national_upgrades, 'osw', 'Baseline', '1-upgraded.osw')))
    assert(!File.exist?(File.join(@national_upgrades, 'xml', 'Baseline', '1-existing.xml')))
    assert(!File.exist?(File.join(@national_upgrades, 'xml', 'Baseline', '1-upgraded.xml')))

    assert(!File.exist?(File.join(@national_upgrades, 'osw', 'AllUpgrades', '1-existing.osw')))
    assert(!File.exist?(File.join(@national_upgrades, 'osw', 'AllUpgrades', '1-upgraded.osw')))
    assert(!File.exist?(File.join(@national_upgrades, 'xml', 'AllUpgrades', '1-existing.xml')))
    assert(!File.exist?(File.join(@national_upgrades, 'xml', 'AllUpgrades', '1-upgraded.xml')))

    FileUtils.cp(results_allupgrades, File.join(File.dirname(@national_upgrades), 'project_national'))
  end
end
