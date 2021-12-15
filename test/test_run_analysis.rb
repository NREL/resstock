# frozen_string_literal: true

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'minitest/autorun'
require 'openstudio'

class TestRunAnalysis < MiniTest::Test
  def before_setup
    cli_path = OpenStudio.getOpenStudioCLI
    @command = "\"#{cli_path}\" workflow/run_analysis.rb"
    @workflowdir = File.join(File.dirname(__FILE__), '..', 'workflow')
  end

  def test_version
    @command += ' -v'

    assert(!system(@command))
  end

  def test_testing_baseline_measures_only
    yml = ' -y project_testing/testing_baseline.yml'
    @command += yml
    @command += ' -m'

    system(@command)

    assert(!File.exist?(File.join(@workflowdir, 'testing_baseline', 'run0', 'run', 'data_point_out.json')))

    FileUtils.rm_rf(File.join(@workflowdir, 'testing_baseline'))
  end

  def test_testing_upgrades
    yml = ' -y project_testing/testing_upgrades.yml'
    @command += yml

    system(@command)

    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'osw', 'Baseline', '1.osw')))
    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'xml', 'Baseline', '1.xml')))

    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'osw', 'Windows', '1.osw')))
    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'xml', 'Windows', '1.xml')))

    FileUtils.rm_rf(File.join(@workflowdir, 'testing_upgrades'))
  end

  def test_testing_upgrades_debug
    yml = ' -y project_testing/testing_upgrades.yml'
    @command += yml
    @command += ' -d'

    system(@command)

    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'osw', 'Baseline', '1-existing.osw')))
    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'xml', 'Baseline', '1-existing.xml')))
    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'xml', 'Baseline', '1-existing-defaulted.xml')))
    assert(!File.exist?(File.join(@workflowdir, 'testing_upgrades', 'osw', 'Baseline', '1-upgraded.osw')))
    assert(!File.exist?(File.join(@workflowdir, 'testing_upgrades', 'xml', 'Baseline', '1-upgraded.xml')))
    assert(!File.exist?(File.join(@workflowdir, 'testing_upgrades', 'xml', 'Baseline', '1-upgraded-defaulted.xml')))

    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'osw', 'Windows', '1-existing.osw')))
    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'xml', 'Windows', '1-existing.xml')))
    assert(!File.exist?(File.join(@workflowdir, 'testing_upgrades', 'xml', 'Windows', '1-existing-defaulted.xml')))
    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'osw', 'Windows', '1-upgraded.osw')))
    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'xml', 'Windows', '1-upgraded.xml')))
    assert(File.exist?(File.join(@workflowdir, 'testing_upgrades', 'xml', 'Windows', '1-upgraded-defaulted.xml')))

    FileUtils.rm_rf(File.join(@workflowdir, 'testing_upgrades'))
  end
end
