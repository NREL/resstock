# frozen_string_literal: true

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require 'openstudio'

class TestResStockMeasuresOSW < MiniTest::Test
  def before_setup
    cli_path = OpenStudio.getOpenStudioCLI
    @command = "\"#{cli_path}\" workflow/run_analysis.rb -y "
  end

  def test_testing_baseline_measures_only
    yml = 'project_testing/testing_baseline.yml'
    @command += yml
    @command += ' -m'

    system(@command)
  end

  def test_testing_upgrades
    yml = 'project_testing/testing_upgrades.yml'
    @command += yml

    system(@command)
  end
end
