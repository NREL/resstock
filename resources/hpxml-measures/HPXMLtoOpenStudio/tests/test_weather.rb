# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'

class HPXMLtoOpenStudioWaterHeaterTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @cache_orig = File.join(@root_path, 'weather', 'USA_CO_Denver.Intl.AP.725650_TMY3-cache.csv')
    @cache_bak = @cache_orig + '.bak'
    File.rename(@cache_orig, @cache_bak) unless File.exist? @cache_bak
  end

  def teardown
    File.rename(@cache_bak, @cache_orig) if File.exist? @cache_bak # Put original file back
  end

  def test_weather_cache
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base.xml'))
    _model, _hpxml = _test_measure(args_hash)
  end

  def test_weather_cache_marshal_dump
    # DFHPs can trigger code in hvac_sizing.rb where we Marshal.dump the weather object.
    # This tests that that code is successful.
    # See https://github.com/NREL/OpenStudio-HPXML/pull/1144 for reference.
    File.open(@cache_orig, 'w') do |_line| # Open file so that OS-HPXML can't write the cache file
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml'))
      _model, _hpxml = _test_measure(args_hash)
    end
  end

  def _test_measure(args_hash)
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    args_hash['output_dir'] = 'tests'
    arguments = measure.arguments(model)
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
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result) unless result.value.valueName == 'Success'

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)

    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])

    File.delete(File.join(File.dirname(__FILE__), 'in.xml'))

    return model, hpxml
  end
end
