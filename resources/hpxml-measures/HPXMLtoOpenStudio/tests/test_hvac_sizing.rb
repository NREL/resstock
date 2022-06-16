# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioHVACSizingTest < MiniTest::Test
  def sample_files_dir
    return File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'sample_files')
  end

  def test_heat_pumps
    ['base-hvac-autosize-air-to-air-heat-pump-1-speed-sizing-methodology',
     'base-hvac-autosize-air-to-air-heat-pump-2-speed-sizing-methodology',
     'base-hvac-autosize-air-to-air-heat-pump-var-speed-sizing-methodology',
     'base-hvac-autosize-ground-to-air-heat-pump-sizing-methodology',
     'base-hvac-autosize-mini-split-heat-pump-ducted-sizing-methodology',
     'base-hvac-autosize-pthp-sizing-methodology',
     'base-hvac-autosize-dual-fuel-air-to-air-heat-pump-1-speed-sizing-methodology'].each do |hpxml_file|
      # Run w/ ACCA sizing
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, "#{hpxml_file}-acca.xml"))
      _model_acca, hpxml_acca = _test_measure(args_hash)

      # Run w/ HERS sizing
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, "#{hpxml_file}-hers.xml"))
      _model_hers, hpxml_hers = _test_measure(args_hash)

      # Run w/ MaxLoad sizing
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, "#{hpxml_file}-maxload.xml"))
      _model_maxload, hpxml_maxload = _test_measure(args_hash)

      # Check that MaxLoad >= HERS > ACCA for heat pump heating capacity
      hp_capacity_acca = hpxml_acca.heat_pumps[0].heating_capacity
      hp_capacity_hers = hpxml_hers.heat_pumps[0].heating_capacity
      hp_capacity_maxload = hpxml_maxload.heat_pumps[0].heating_capacity
      assert_operator(hp_capacity_maxload, :>=, hp_capacity_hers)
      assert_operator(hp_capacity_hers, :>, hp_capacity_acca)
    end
  end

  def test_heat_pump_separate_backup_systems
    # Run w/ ducted heat pump and ductless backup
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-autosize-air-to-air-heat-pump-var-speed-backup-boiler.xml'))
    _model, hpxml = _test_measure(args_hash)

    # Check that boiler capacity equals building heating design load w/o duct load.
    htg_design_load_without_ducts = hpxml.hvac_plant.hdl_total - hpxml.hvac_plant.hdl_ducts
    htg_capacity = hpxml.heating_systems[0].heating_capacity
    assert_in_epsilon(htg_design_load_without_ducts, htg_capacity, 0.001) # 0.001 to handle rounding

    # Run w/ ducted heat pump and ducted backup
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-autosize-air-to-air-heat-pump-var-speed-backup-furnace.xml'))
    _model, hpxml = _test_measure(args_hash)

    # Check that furnace capacity is between the building heating design load w/o duct load
    # and the building heating design load w/ duct load. This is because the building duct
    # load is the sum of the furnace duct load AND the heat pump duct load.
    htg_design_load_with_ducts = hpxml.hvac_plant.hdl_total
    htg_design_load_without_ducts = htg_design_load_with_ducts - hpxml.hvac_plant.hdl_ducts
    htg_capacity = hpxml.heating_systems[0].heating_capacity
    assert_operator(htg_capacity, :>, htg_design_load_without_ducts * 1.001) # 1.001 to handle rounding
    assert_operator(htg_capacity, :<, htg_design_load_with_ducts * 0.999) # 0.999 to handle rounding

    # Run w/ ductless heat pump and ductless backup
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(sample_files_dir, 'base-hvac-autosize-mini-split-heat-pump-ductless-backup-stove.xml'))
    _model, hpxml = _test_measure(args_hash)

    # Check that stove capacity equals building heating design load
    htg_design_load = hpxml.hvac_plant.hdl_total
    htg_capacity = hpxml.heating_systems[0].heating_capacity
    assert_in_epsilon(htg_design_load, htg_capacity, 0.001) # 0.001 to handle rounding
  end

  def test_slab_f_factor
    def get_unins_slab()
      slab = HPXML::Slab.new(nil)
      slab.thickness = 4.0 # in
      slab.perimeter_insulation_depth = 0
      slab.perimeter_insulation_r_value = 0
      slab.under_slab_insulation_width = 0
      slab.under_slab_insulation_spans_entire_slab = false
      slab.under_slab_insulation_r_value = 0
      return slab
    end

    # Uninsulated slab
    slab = get_unins_slab()
    f_factor = HVACSizing.calc_slab_f_value(slab)
    assert_in_epsilon(1.41, f_factor, 0.01)

    # R-10, 4ft under slab insulation
    slab = get_unins_slab()
    slab.under_slab_insulation_width = 4
    slab.under_slab_insulation_r_value = 10
    f_factor = HVACSizing.calc_slab_f_value(slab)
    assert_in_epsilon(1.27, f_factor, 0.01)

    # R-20, 4ft perimeter insulation
    slab = get_unins_slab()
    slab.perimeter_insulation_depth = 4
    slab.perimeter_insulation_r_value = 20
    f_factor = HVACSizing.calc_slab_f_value(slab)
    assert_in_epsilon(0.39, f_factor, 0.01)

    # R-40, whole slab insulation
    slab = get_unins_slab()
    slab.under_slab_insulation_spans_entire_slab = true
    slab.under_slab_insulation_r_value = 40
    f_factor = HVACSizing.calc_slab_f_value(slab)
    assert_in_epsilon(1.04, f_factor, 0.01)
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

    hpxml = HPXML.new(hpxml_path: File.join(File.dirname(__FILE__), 'in.xml'))

    File.delete(File.join(File.dirname(__FILE__), 'in.xml'))

    return model, hpxml
  end
end
