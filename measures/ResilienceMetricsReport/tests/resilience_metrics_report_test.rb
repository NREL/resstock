require_relative '../../../test/minitest_helper'
require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class ResilienceMetricsReportTest < MiniTest::Test

  def test_argument_error
    args_hash = {}
    args_hash["output_variables"] = "Zone Mean Air Temperature, Zone Air Relative Humidity"
    args_hash["min_vals"] = "60, 5, 0"
    args_hash["max_vals"] = "80, 60, 0"
    result = _test_error(args_hash)
    assert_includes(result.errors.map{ |x| x.logMessage }, "Number of output variable elements specified inconsistent with either number of minimum or maximum values.")
    
  end

  def test_resilience_metric
    resilience_metrics = {
                         # output_var=>[timeseries, min_val, max_val, hours_below, hours_above]
                         "Zone Mean Air Temperature"=>[[40]*8760, 60, 80, 0, 8760],
                         "Zone Air Relative Humidity"=>[[60]*8760, 5, 60, 0, 0],
                        }
    _test_resilience_metrics(resilience_metrics)
  end
    
  private
  
  def _test_resilience_metrics(resilience_metrics)

    # create an instance of the measure
    measure = ResilienceMetricsReport.new
    
    # Check for correct resilience metrics values
    resilience_metrics.each do |resilience_metric, resilience_metric_values|
      values, min_val, max_val, expected_hours_below, expected_hours_above = resilience_metric_values
      actual_hours_below, actual_hours_above = measure.calc_resilience_metric(resilience_metric, values, min_val, max_val)
      assert(!actual_hours_below.nil?)
      assert(!actual_hours_above.nil?)
      assert_in_epsilon(expected_hours_below, actual_hours_below, 0.01)
      assert_in_epsilon(expected_hours_above, actual_hours_above, 0.01)
    end
  end

  def _test_error(args_hash)
    # create an instance of the measure
    measure = ResilienceMetricsReport.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(runner, argument_map)
    result = runner.result

    # show_output(result)

    # assert that it didn't run
    assert_equal("Fail", result.value.valueName)
    assert(result.errors.size == 1)

    return result
  end

end
