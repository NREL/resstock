# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioConstructionsTest < MiniTest::Test
  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def test_windows
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base.xml'))
    model, hpxml = _test_measure(args_hash)

    # Check window properties
    hpxml.windows.each do |window|
      os_window = model.getSubSurfaces.select { |w| w.name.to_s == window.id }[0]
      os_simple_glazing = os_window.construction.get.to_LayeredConstruction.get.getLayer(0).to_SimpleGlazing.get

      assert_equal(window.shgc, os_simple_glazing.solarHeatGainCoefficient)
      assert_in_epsilon(window.ufactor, UnitConversions.convert(os_simple_glazing.uFactor, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)'), 0.001)
    end
  end

  def test_windows_interior_shading
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-enclosure-windows-interior-shading.xml'))
    model, hpxml = _test_measure(args_hash)

    summer_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('June'), 1, model.yearDescription.get.assumedYear)
    winter_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1, model.yearDescription.get.assumedYear)

    # Check window shading properties
    hpxml.windows.each do |window|
      os_window = model.getSubSurfaces.select { |w| w.name.to_s == window.id }[0]
      os_summer_control = os_window.shadingControls.select { |sc| sc.schedule.get.to_ScheduleRuleset.get.getDaySchedules(summer_date, summer_date).map { |ds| ds.values.sum }.sum == 1 }[0]
      os_winter_control = os_window.shadingControls.select { |sc| sc.schedule.get.to_ScheduleRuleset.get.getDaySchedules(winter_date, winter_date).map { |ds| ds.values.sum }.sum == 1 }[0]

      if window.interior_shading_factor_summer == 1
        assert_nil(os_summer_control) # No shading
      else
        refute_nil(os_summer_control)
        assert_equal(window.interior_shading_factor_summer, os_summer_control.shadingMaterial.get.to_Shade.get.solarTransmittance)
      end
      if window.interior_shading_factor_winter == 1
        assert_nil(os_winter_control) # No shading
      else
        refute_nil(os_winter_control)
        assert_equal(window.interior_shading_factor_winter, os_winter_control.shadingMaterial.get.to_Shade.get.solarTransmittance)
      end
    end
  end

  def test_skylights
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-enclosure-skylights.xml'))
    model, hpxml = _test_measure(args_hash)

    # Check skylight properties
    hpxml.skylights.each do |skylight|
      os_skylight = model.getSubSurfaces.select { |w| w.name.to_s == skylight.id }[0]
      os_simple_glazing = os_skylight.construction.get.to_LayeredConstruction.get.getLayer(0).to_SimpleGlazing.get

      assert_equal(skylight.shgc, os_simple_glazing.solarHeatGainCoefficient)
      assert_in_epsilon(skylight.ufactor / 1.2, UnitConversions.convert(os_simple_glazing.uFactor, 'W/(m^2*K)', 'Btu/(hr*ft^2*F)'), 0.001)
    end
  end

  def _test_measure(args_hash)
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
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

    return model, hpxml
  end
end
