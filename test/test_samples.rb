# frozen_string_literal: true

require_relative 'minitest_helper'
require 'minitest/autorun'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..')
load 'Rakefile'
require 'openstudio'

class TestResStockMeasuresOSW < MiniTest::Test
  def before_setup
    cli_path = OpenStudio.getOpenStudioCLI
    @command = "\"#{cli_path}\" workflow/run_analysis.rb -y "
  end

  def test_testing_upgrades
    yml = 'project_testing/testing_upgrades.yml'
    @command += yml

    system(@command)
  end
end
