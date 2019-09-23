require_relative '../../test/minitest_helper'
require 'minitest/autorun'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "..")
load 'Rakefile'
require 'json'

class TestProjectSingleFamilyDetached < MiniTest::Test
  def test_housing_characteristics
    begin
      project_dir_name = File.basename(File.dirname(File.dirname(__FILE__)))
      integrity_check(project_dir_name)
      integrity_check_options_lookup_tsv(project_dir_name)
    rescue Exception => e
      flunk e

      # Need a backtrace? Uncomment below
      # flunk "#{e}\n#{e.backtrace.join('\n')}"
    end
  end
  
  def test_apply_upgrade_run_measure_arg
    json = JSON.parse(File.read(File.join(File.dirname(__FILE__), "..", "pat.json")), :symbolize_names => true)
    json[:measures].each do |measure|
      measure[:arguments].each do |args|
        if args[:name] == "run_measure"
          assert_equal("Discrete", args[:inputs][:variableSetting])
          assert_equal(2, args[:inputs][:discreteVariables].size)
          discrete_var_values = []
          discrete_var_weights = []
          args[:inputs][:discreteVariables].each do |arg_var|
            discrete_var_values << arg_var[:value]
            discrete_var_weights << arg_var[:weight]
          end
          discrete_var_values.sort!
          assert_equal(0.5, discrete_var_weights[0])
          assert_equal(0.5, discrete_var_weights[1])
          assert_equal(0, discrete_var_values[0])
          assert_equal(1, discrete_var_values[1])
        end
      end
    end
  end
end
