# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioHVACSizingTest < MiniTest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @test_files_path = File.join(@root_path, 'workflow', 'tests')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_acca_block_load_residences
    default_tol_btuh = 500

    # Vatilo Residence
    # Expected values from Figure 7-4
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Vatilo_Residence.xml'))
    _model, hpxml = _test_measure(args_hash)
    assert_in_delta(9147, hpxml.hvac_plant.hdl_ducts, 2000)
    assert_in_delta(4234, hpxml.hvac_plant.hdl_windows, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.hdl_skylights, default_tol_btuh)
    assert_in_delta(574, hpxml.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(2874, hpxml.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(7415, hpxml.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(1498, hpxml.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(3089, hpxml.hvac_plant.hdl_infilvent, default_tol_btuh)
    assert_in_delta(9973, hpxml.hvac_plant.cdl_sens_ducts, 1500)
    assert_in_delta(5295, hpxml.hvac_plant.cdl_sens_windows, 1500)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_skylights, default_tol_btuh)
    assert_in_delta(456, hpxml.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(1715, hpxml.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(2112, hpxml.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(769, hpxml.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(3090, hpxml.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(2488, hpxml.hvac_plant.cdl_lat_ducts, 1500)
    assert_in_delta(1276, hpxml.hvac_plant.cdl_lat_infilvent, default_tol_btuh)
    assert_in_delta(600, hpxml.hvac_plant.cdl_lat_intgains, default_tol_btuh)

    # Section 8: Victor Residence
    # Expected values from Figure 8-3
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Victor_Residence.xml'))
    _model, hpxml = _test_measure(args_hash)
    assert_in_delta(29137, hpxml.hvac_plant.hdl_ducts, 12000)
    assert_in_delta(9978, hpxml.hvac_plant.hdl_windows, default_tol_btuh)
    assert_in_delta(471, hpxml.hvac_plant.hdl_skylights, default_tol_btuh)
    assert_in_delta(984, hpxml.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(6305, hpxml.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(7069, hpxml.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(6044, hpxml.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(21426, hpxml.hvac_plant.hdl_infilvent, default_tol_btuh)
    assert_in_delta(5602, hpxml.hvac_plant.cdl_sens_ducts, 3000)
    assert_in_delta(4706, hpxml.hvac_plant.cdl_sens_windows, default_tol_btuh)
    assert_in_delta(1409, hpxml.hvac_plant.cdl_sens_skylights, default_tol_btuh)
    assert_in_delta(382, hpxml.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(1130, hpxml.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(2743, hpxml.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(1393, hpxml.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(2504, hpxml.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(4520, hpxml.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(6282, hpxml.hvac_plant.cdl_lat_ducts, 5000)
    assert_in_delta(4644, hpxml.hvac_plant.cdl_lat_infilvent, default_tol_btuh)
    assert_in_delta(800, hpxml.hvac_plant.cdl_lat_intgains, default_tol_btuh)

    # Section 9: Long Residence
    # Modeled as a fully conditioned basement (e.g., no duct losses) for block load calculation
    # Expected values from Figure 9-3
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Long_Residence.xml'))
    _model, hpxml = _test_measure(args_hash)
    assert_in_delta(0, hpxml.hvac_plant.hdl_ducts, default_tol_btuh)
    assert_in_delta(8315, hpxml.hvac_plant.hdl_windows, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.hdl_skylights, default_tol_btuh)
    assert_in_delta(1006, hpxml.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(16608, hpxml.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(2440, hpxml.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(5435, hpxml.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(6944, hpxml.hvac_plant.hdl_infilvent, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_ducts, default_tol_btuh)
    assert_in_delta(5962, hpxml.hvac_plant.cdl_sens_windows, 1000)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_skylights, default_tol_btuh)
    assert_in_delta(349, hpxml.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(1730, hpxml.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(3624, hpxml.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(565, hpxml.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(3320, hpxml.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(0, hpxml.hvac_plant.cdl_lat_ducts, default_tol_btuh)
    assert_in_delta(998, hpxml.hvac_plant.cdl_lat_infilvent, default_tol_btuh)
    assert_in_delta(1200, hpxml.hvac_plant.cdl_lat_intgains, default_tol_btuh)
  end

  def test_heat_pumps
    ['base-hvac-autosize-air-to-air-heat-pump-1-speed-sizing-methodology',
     'base-hvac-autosize-air-to-air-heat-pump-2-speed-sizing-methodology',
     'base-hvac-autosize-air-to-air-heat-pump-var-speed-sizing-methodology',
     'base-hvac-autosize-ground-to-air-heat-pump-sizing-methodology',
     'base-hvac-autosize-mini-split-heat-pump-ducted-sizing-methodology',
     'base-hvac-autosize-pthp-sizing-methodology',
     'base-hvac-autosize-room-ac-with-reverse-cycle-sizing-methodology',
     'base-hvac-autosize-dual-fuel-air-to-air-heat-pump-1-speed-sizing-methodology'].each do |hpxml_file|
      # Run w/ ACCA sizing
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, "#{hpxml_file}-acca.xml"))
      _model_acca, hpxml_acca = _test_measure(args_hash)

      # Run w/ HERS sizing
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, "#{hpxml_file}-hers.xml"))
      _model_hers, hpxml_hers = _test_measure(args_hash)

      # Run w/ MaxLoad sizing
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, "#{hpxml_file}-maxload.xml"))
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-autosize-air-to-air-heat-pump-var-speed-backup-boiler.xml'))
    _model, hpxml = _test_measure(args_hash)

    # Check that boiler capacity equals building heating design load w/o duct load.
    htg_design_load_without_ducts = hpxml.hvac_plant.hdl_total - hpxml.hvac_plant.hdl_ducts
    htg_capacity = hpxml.heating_systems[0].heating_capacity
    assert_in_epsilon(htg_design_load_without_ducts, htg_capacity, 0.001) # 0.001 to handle rounding

    # Run w/ ducted heat pump and ducted backup
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-autosize-air-to-air-heat-pump-var-speed-backup-furnace.xml'))
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
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-autosize-mini-split-heat-pump-ductless-backup-stove.xml'))
    _model, hpxml = _test_measure(args_hash)

    # Check that stove capacity equals building heating design load
    htg_design_load = hpxml.hvac_plant.hdl_total
    htg_capacity = hpxml.heating_systems[0].heating_capacity
    assert_in_epsilon(htg_design_load, htg_capacity, 0.001) # 0.001 to handle rounding
  end

  def test_heat_pump_integrated_backup_systems
    # Check that HP backup heating capacity matches heating design load even when using MaxLoad in a hot climate (GitHub issue #1140)
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-hvac-autosize-air-to-air-heat-pump-1-speed-sizing-methodology-maxload-miami-fl.xml'))
    _model, hpxml = _test_measure(args_hash)

    assert_equal(hpxml.heat_pumps[0].backup_heating_capacity, hpxml.hvac_plant.hdl_total)
  end

  def test_allow_increased_fixed_capacities
    # Test hard-sized capacities are increased for various equipment types
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Test air conditioner + furnace
    hpxml = _create_hpxml('base-hvac-undersized-allow-increased-fixed-capacities.xml')
    htg_cap = hpxml.heating_systems[0].heating_capacity
    clg_cap = hpxml.cooling_systems[0].cooling_capacity
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    _model, hpxml = _test_measure(args_hash)
    assert(hpxml.heating_systems[0].heating_capacity > htg_cap)
    assert(hpxml.cooling_systems[0].cooling_capacity > clg_cap)

    # Test heat pump
    hpxml = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-heating-capacity-17f.xml')
    hpxml.header.allow_increased_fixed_capacities = true
    hpxml.heat_pumps[0].heating_capacity /= 10.0
    hpxml.heat_pumps[0].heating_capacity_17F /= 10.0
    hpxml.heat_pumps[0].backup_heating_capacity /= 10.0
    hpxml.heat_pumps[0].cooling_capacity /= 10.0
    htg_cap = hpxml.heat_pumps[0].heating_capacity
    htg_17f_cap = hpxml.heat_pumps[0].heating_capacity_17F
    htg_bak_cap = hpxml.heat_pumps[0].backup_heating_capacity
    clg_cap = hpxml.heat_pumps[0].cooling_capacity
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    _model, hpxml = _test_measure(args_hash)
    assert(hpxml.heat_pumps[0].heating_capacity > htg_cap)
    assert(hpxml.heat_pumps[0].heating_capacity_17F > htg_17f_cap)
    assert(hpxml.heat_pumps[0].backup_heating_capacity > htg_bak_cap)
    assert(hpxml.heat_pumps[0].cooling_capacity > clg_cap)
  end

  def test_manual_j_sizing_inputs
    # Run base
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base.xml'))
    _model, base_hpxml = _test_measure(args_hash)

    # Test heating/cooling design temps
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = _create_hpxml('base.xml')
    hpxml.header.manualj_heating_design_temp = 0.0
    hpxml.header.manualj_cooling_design_temp = 100.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    _model, test_hpxml = _test_measure(args_hash)
    assert_operator(test_hpxml.hvac_plant.hdl_total, :>, base_hpxml.hvac_plant.hdl_total)
    assert_operator(test_hpxml.hvac_plant.cdl_sens_total, :>, base_hpxml.hvac_plant.cdl_sens_total)

    # Test heating/cooling setpoints
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = _create_hpxml('base.xml')
    hpxml.header.manualj_heating_setpoint = 72.5
    hpxml.header.manualj_cooling_setpoint = 72.5
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    _model, test_hpxml = _test_measure(args_hash)
    assert_operator(test_hpxml.hvac_plant.hdl_total, :>, base_hpxml.hvac_plant.hdl_total)
    assert_operator(test_hpxml.hvac_plant.cdl_sens_total, :>, base_hpxml.hvac_plant.cdl_sens_total)

    # Test internal loads
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = _create_hpxml('base.xml')
    hpxml.header.manualj_internal_loads_sensible = 1000.0
    hpxml.header.manualj_internal_loads_latent = 500.0
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    _model, test_hpxml = _test_measure(args_hash)
    assert_equal(test_hpxml.hvac_plant.hdl_total, base_hpxml.hvac_plant.hdl_total)
    assert_operator(test_hpxml.hvac_plant.cdl_sens_intgains, :<, base_hpxml.hvac_plant.cdl_sens_intgains)
    assert_operator(test_hpxml.hvac_plant.cdl_lat_intgains, :>, base_hpxml.hvac_plant.cdl_lat_intgains)

    # Test number of occupants
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = _create_hpxml('base.xml')
    hpxml.header.manualj_num_occupants = 10
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    _model, test_hpxml = _test_measure(args_hash)
    assert_equal(test_hpxml.hvac_plant.hdl_total, base_hpxml.hvac_plant.hdl_total)
    assert_operator(test_hpxml.hvac_plant.cdl_sens_intgains, :>, base_hpxml.hvac_plant.cdl_sens_intgains)
    assert_operator(test_hpxml.hvac_plant.cdl_lat_intgains, :>, base_hpxml.hvac_plant.cdl_lat_intgains)
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
    f_factor = HVACSizing.calc_slab_f_value(slab, 1.0)
    assert_in_epsilon(1.41, f_factor, 0.01)

    # R-10, 4ft under slab insulation
    slab = get_unins_slab()
    slab.under_slab_insulation_width = 4
    slab.under_slab_insulation_r_value = 10
    f_factor = HVACSizing.calc_slab_f_value(slab, 1.0)
    assert_in_epsilon(1.27, f_factor, 0.01)

    # R-20, 4ft perimeter insulation
    slab = get_unins_slab()
    slab.perimeter_insulation_depth = 4
    slab.perimeter_insulation_r_value = 20
    f_factor = HVACSizing.calc_slab_f_value(slab, 1.0)
    assert_in_epsilon(0.39, f_factor, 0.01)

    # R-40, whole slab insulation
    slab = get_unins_slab()
    slab.under_slab_insulation_spans_entire_slab = true
    slab.under_slab_insulation_r_value = 40
    f_factor = HVACSizing.calc_slab_f_value(slab, 1.0)
    assert_in_epsilon(1.04, f_factor, 0.01)
  end

  def _test_measure(args_hash)
    # create an instance of the measure
    measure = HPXMLtoOpenStudio.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    args_hash['output_dir'] = File.dirname(__FILE__)
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

  def _create_hpxml(hpxml_name)
    return HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
  end
end
