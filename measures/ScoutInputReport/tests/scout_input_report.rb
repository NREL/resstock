require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ScoutInputReportTest < MiniTest::Test
  def test
  end

  private

  def _test_cost_multipliers(osm_file, cost_multipliers)
    # load the test model
    model = get_model(File.dirname(__FILE__), osm_file)

    # create an instance of the measure
    measure = SimulationOutputReport.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  end
end
