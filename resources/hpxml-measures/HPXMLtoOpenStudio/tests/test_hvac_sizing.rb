# frozen_string_literal: true

require_relative '../resources/minitest_helper'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'
require_relative '../measure.rb'
require_relative '../resources/util.rb'

class HPXMLtoOpenStudioHVACSizingTest < Minitest::Test
  def setup
    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @test_files_path = File.join(@root_path, 'workflow', 'tests')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @results_dir = File.join(@test_files_path, 'results')
    FileUtils.mkdir_p @results_dir
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
  end

  def test_hvac_configurations
    # Test autosizing calculations for all base-hvac-foo.xml sample files.
    results_out = File.join(@results_dir, 'results_sizing.csv')
    File.delete(results_out) if File.exist? results_out

    sizing_results = {}
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }
    Dir["#{@sample_files_path}/base-hvac*.xml"].each do |hvac_hpxml|
      next if hvac_hpxml.include? 'autosize'
      next if hvac_hpxml.include? 'detailed-performance' # Autosizing not allowed

      { 'USA_CO_Denver.Intl.AP.725650_TMY3.epw' => 'denver',
        'USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw' => 'houston' }.each do |epw_path, location|
        hvac_hpxml = File.basename(hvac_hpxml)

        hpxml, hpxml_bldg = _create_hpxml(hvac_hpxml)
        hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = epw_path
        _remove_hardsized_capacities(hpxml_bldg)

        if hpxml_bldg.heat_pumps.size > 0
          hp_sizing_methodologies = [HPXML::HeatPumpSizingACCA,
                                     HPXML::HeatPumpSizingHERS,
                                     HPXML::HeatPumpSizingMaxLoad]
        else
          hp_sizing_methodologies = [nil]
        end

        hp_capacity_acca, hp_capacity_maxload = nil, nil
        hp_sizing_methodologies.each do |hp_sizing_methodology|
          test_name = hvac_hpxml.gsub('base-hvac-', "#{location}-hvac-autosize-")
          if not hp_sizing_methodology.nil?
            test_name = test_name.gsub('.xml', "-sizing-methodology-#{hp_sizing_methodology}.xml")
          end

          puts "Testing #{test_name}..."

          hpxml_bldg.header.heat_pump_sizing_methodology = hp_sizing_methodology

          XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
          _autosized_model, _autosized_hpxml, autosized_bldg = _test_measure(args_hash)

          htg_cap, clg_cap, hp_backup_cap = Outputs.get_total_hvac_capacities(autosized_bldg)
          htg_cfm, clg_cfm = Outputs.get_total_hvac_airflows(autosized_bldg)
          sizing_results[test_name] = { 'HVAC Capacity: Heating (Btu/h)' => htg_cap.round(1),
                                        'HVAC Capacity: Cooling (Btu/h)' => clg_cap.round(1),
                                        'HVAC Capacity: Heat Pump Backup (Btu/h)' => hp_backup_cap.round(1),
                                        'HVAC Airflow: Heating (cfm)' => htg_cfm.round(1),
                                        'HVAC Airflow: Cooling (cfm)' => clg_cfm.round(1) }

          next unless hpxml_bldg.heat_pumps.size == 1

          htg_load = autosized_bldg.hvac_plant.hdl_total
          clg_load = autosized_bldg.hvac_plant.cdl_sens_total + autosized_bldg.hvac_plant.cdl_lat_total
          hp = autosized_bldg.heat_pumps[0]
          htg_cap = hp.heating_capacity
          clg_cap = hp.cooling_capacity
          charge_defect_ratio = hp.charge_defect_ratio.to_f
          airflow_defect_ratio = hp.airflow_defect_ratio.to_f

          if hp_sizing_methodology == HPXML::HeatPumpSizingACCA
            hp_capacity_acca = htg_cap
          elsif hp_sizing_methodology == HPXML::HeatPumpSizingHERS
            next if hp.is_dual_fuel

            if (charge_defect_ratio != 0) || (airflow_defect_ratio != 0)
              # Check HP capacity is greater than max(htg_load, clg_load)
              if hp.fraction_heat_load_served == 0
                assert_operator(clg_cap, :>, clg_load)
              elsif hp.fraction_cool_load_served == 0
                assert_operator(htg_cap, :>, htg_load)
              else
                assert_operator(htg_cap, :>, [htg_load, clg_load].max)
                assert_operator(clg_cap, :>, [htg_load, clg_load].max)
              end
            else
              # Check HP capacity equals max(htg_load, clg_load)
              if hp.fraction_heat_load_served == 0
                assert_in_delta(clg_cap, clg_load, 1.0)
              elsif hp.fraction_cool_load_served == 0
                assert_in_delta(htg_cap, htg_load, 1.0)
              else
                assert_in_delta(htg_cap, [htg_load, clg_load].max, 1.0)
                assert_in_delta(clg_cap, [htg_load, clg_load].max, 1.0)
              end
            end
          elsif hp_sizing_methodology == HPXML::HeatPumpSizingMaxLoad
            hp_capacity_maxload = htg_cap
          end
        end

        next unless hpxml_bldg.heat_pumps.size == 1

        # Check that MaxLoad >= >= ACCA for heat pump heating capacity
        assert_operator(hp_capacity_maxload, :>=, hp_capacity_acca)
      end
    end

    # Write results to a file
    require 'csv'
    output_keys = sizing_results.values[0].keys
    CSV.open(results_out, 'w') do |csv|
      csv << ['HPXML'] + output_keys
      sizing_results.sort.each do |xml, xml_results|
        csv_row = [xml]
        output_keys.each do |key|
          if xml_results[key].nil?
            csv_row << 0
          else
            csv_row << xml_results[key]
          end
        end
        csv << csv_row
      end
    end
  end

  def test_acca_block_load_residences
    default_tol_btuh = 500

    # Vatilo Residence
    # Expected values from Figure 7-4
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Vatilo_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(9147, hpxml_bldg.hvac_plant.hdl_ducts, 2000)
    assert_in_delta(4234, hpxml_bldg.hvac_plant.hdl_windows, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_skylights, default_tol_btuh)
    assert_in_delta(574, hpxml_bldg.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(2874, hpxml_bldg.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(7415, hpxml_bldg.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(1498, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(3089, hpxml_bldg.hvac_plant.hdl_infilvent, default_tol_btuh)
    assert_in_delta(9973, hpxml_bldg.hvac_plant.cdl_sens_ducts, 1500)
    assert_in_delta(5295, hpxml_bldg.hvac_plant.cdl_sens_windows, 1500)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_skylights, default_tol_btuh)
    assert_in_delta(456, hpxml_bldg.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(1715, hpxml_bldg.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(2112, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(769, hpxml_bldg.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(3090, hpxml_bldg.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(2488, hpxml_bldg.hvac_plant.cdl_lat_ducts, 1500)
    assert_in_delta(1276, hpxml_bldg.hvac_plant.cdl_lat_infilvent, default_tol_btuh)
    assert_in_delta(600, hpxml_bldg.hvac_plant.cdl_lat_intgains, default_tol_btuh)

    # Section 8: Victor Residence
    # Expected values from Figure 8-3
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Victor_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(29137, hpxml_bldg.hvac_plant.hdl_ducts, 12000)
    assert_in_delta(9978, hpxml_bldg.hvac_plant.hdl_windows, default_tol_btuh)
    assert_in_delta(471, hpxml_bldg.hvac_plant.hdl_skylights, default_tol_btuh)
    assert_in_delta(984, hpxml_bldg.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(6305, hpxml_bldg.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(7069, hpxml_bldg.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(6044, hpxml_bldg.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(21426, hpxml_bldg.hvac_plant.hdl_infilvent, default_tol_btuh)
    assert_in_delta(5602, hpxml_bldg.hvac_plant.cdl_sens_ducts, 3000)
    assert_in_delta(4706, hpxml_bldg.hvac_plant.cdl_sens_windows, default_tol_btuh)
    assert_in_delta(1409, hpxml_bldg.hvac_plant.cdl_sens_skylights, default_tol_btuh)
    assert_in_delta(382, hpxml_bldg.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(1130, hpxml_bldg.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(2743, hpxml_bldg.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(1393, hpxml_bldg.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(2504, hpxml_bldg.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(4520, hpxml_bldg.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(6282, hpxml_bldg.hvac_plant.cdl_lat_ducts, 5000)
    assert_in_delta(4644, hpxml_bldg.hvac_plant.cdl_lat_infilvent, default_tol_btuh)
    assert_in_delta(800, hpxml_bldg.hvac_plant.cdl_lat_intgains, default_tol_btuh)

    # Section 9: Long Residence
    # Modeled as a fully conditioned basement (e.g., no duct losses) for block load calculation
    # Expected values from Figure 9-3
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Long_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_ducts, default_tol_btuh)
    assert_in_delta(8315, hpxml_bldg.hvac_plant.hdl_windows, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_skylights, default_tol_btuh)
    assert_in_delta(1006, hpxml_bldg.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(16608, hpxml_bldg.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(2440, hpxml_bldg.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(5435, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(6944, hpxml_bldg.hvac_plant.hdl_infilvent, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_ducts, default_tol_btuh)
    assert_in_delta(5962, hpxml_bldg.hvac_plant.cdl_sens_windows, 1000)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_skylights, default_tol_btuh)
    assert_in_delta(349, hpxml_bldg.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(1730, hpxml_bldg.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(3624, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(565, hpxml_bldg.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(3320, hpxml_bldg.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_lat_ducts, default_tol_btuh)
    assert_in_delta(998, hpxml_bldg.hvac_plant.cdl_lat_infilvent, default_tol_btuh)
    assert_in_delta(1200, hpxml_bldg.hvac_plant.cdl_lat_intgains, default_tol_btuh)
  end

  def test_heat_pump_separate_backup_systems
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path) }

    # Run w/ ducted heat pump and ductless backup
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-boiler.xml')
    _remove_hardsized_capacities(hpxml_bldg)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check that boiler capacity equals building heating design load w/o duct load.
    htg_design_load_without_ducts = hpxml_bldg.hvac_plant.hdl_total - hpxml_bldg.hvac_plant.hdl_ducts
    htg_capacity = hpxml_bldg.heating_systems[0].heating_capacity
    assert_in_epsilon(htg_design_load_without_ducts, htg_capacity, 0.001) # 0.001 to handle rounding

    # Run w/ ducted heat pump and ducted backup
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-furnace.xml')
    _remove_hardsized_capacities(hpxml_bldg)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check that furnace capacity is between the building heating design load w/o duct load
    # and the building heating design load w/ duct load. This is because the building duct
    # load is the sum of the furnace duct load AND the heat pump duct load.
    htg_design_load_with_ducts = hpxml_bldg.hvac_plant.hdl_total
    htg_design_load_without_ducts = htg_design_load_with_ducts - hpxml_bldg.hvac_plant.hdl_ducts
    htg_capacity = hpxml_bldg.heating_systems[0].heating_capacity
    assert_operator(htg_capacity, :>, htg_design_load_without_ducts * 1.001) # 1.001 to handle rounding
    assert_operator(htg_capacity, :<, htg_design_load_with_ducts * 0.999) # 0.999 to handle rounding

    # Run w/ ductless heat pump and ductless backup
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-mini-split-heat-pump-ductless-backup-stove.xml')
    _remove_hardsized_capacities(hpxml_bldg)
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check that stove capacity equals building heating design load
    htg_design_load = hpxml_bldg.hvac_plant.hdl_total
    htg_capacity = hpxml_bldg.heating_systems[0].heating_capacity
    assert_in_epsilon(htg_design_load, htg_capacity, 0.001) # 0.001 to handle rounding
  end

  def test_heat_pump_integrated_backup_systems
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path) }

    # Check that HP backup heating capacity matches heating design load even when using MaxLoad in a hot climate (GitHub issue #1140)
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
    _remove_hardsized_capacities(hpxml_bldg)
    hpxml_bldg.header.heat_pump_sizing_methodology = HPXML::HeatPumpSizingMaxLoad
    hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = 'USA_FL_Miami.Intl.AP.722020_TMY3.epw'
    hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs[0].zone = '1A'
    hpxml_bldg.state_code = 'FL'
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)

    assert_equal(hpxml_bldg.heat_pumps[0].backup_heating_capacity, hpxml_bldg.hvac_plant.hdl_total)
  end

  def test_allow_increased_fixed_capacities
    for allow_increased_fixed_capacities in [true, false]
      # Test hard-sized capacities are increased (or not) for various equipment types
      args_hash = {}
      args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

      # Test air conditioner + furnace
      hpxml, hpxml_bldg = _create_hpxml('base-hvac-undersized.xml')
      hpxml_bldg.header.allow_increased_fixed_capacities = allow_increased_fixed_capacities
      htg_cap = hpxml_bldg.heating_systems[0].heating_capacity
      clg_cap = hpxml_bldg.cooling_systems[0].cooling_capacity
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
      if allow_increased_fixed_capacities
        assert_operator(hpxml_bldg.heating_systems[0].heating_capacity, :>, htg_cap)
        assert_operator(hpxml_bldg.cooling_systems[0].cooling_capacity, :>, clg_cap)
      else
        assert_equal(hpxml_bldg.heating_systems[0].heating_capacity, htg_cap)
        assert_equal(hpxml_bldg.cooling_systems[0].cooling_capacity, clg_cap)
      end

      # Test heat pump
      hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed-heating-capacity-17f.xml')
      hpxml_bldg.header.allow_increased_fixed_capacities = allow_increased_fixed_capacities
      hpxml_bldg.heat_pumps[0].heating_capacity /= 10.0
      hpxml_bldg.heat_pumps[0].heating_capacity_17F /= 10.0
      hpxml_bldg.heat_pumps[0].backup_heating_capacity /= 10.0
      hpxml_bldg.heat_pumps[0].cooling_capacity /= 10.0
      htg_cap = hpxml_bldg.heat_pumps[0].heating_capacity
      htg_17f_cap = hpxml_bldg.heat_pumps[0].heating_capacity_17F
      htg_bak_cap = hpxml_bldg.heat_pumps[0].backup_heating_capacity
      clg_cap = hpxml_bldg.heat_pumps[0].cooling_capacity
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
      if allow_increased_fixed_capacities
        assert_operator(hpxml_bldg.heat_pumps[0].heating_capacity, :>, htg_cap)
        assert_operator(hpxml_bldg.heat_pumps[0].heating_capacity_17F, :>, htg_17f_cap)
        assert_operator(hpxml_bldg.heat_pumps[0].backup_heating_capacity, :>, htg_bak_cap)
        assert_operator(hpxml_bldg.heat_pumps[0].cooling_capacity, :>, clg_cap)
      else
        assert_equal(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap)
        assert_equal(hpxml_bldg.heat_pumps[0].heating_capacity_17F, htg_17f_cap)
        assert_equal(hpxml_bldg.heat_pumps[0].backup_heating_capacity, htg_bak_cap)
        assert_equal(hpxml_bldg.heat_pumps[0].cooling_capacity, clg_cap)
      end

      # Test heat pump w/ detailed performance
      hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance.xml')
      hpxml_bldg.header.allow_increased_fixed_capacities = allow_increased_fixed_capacities
      htg_capacities_detailed = []
      clg_capacities_detailed = []
      hpxml_bldg.heat_pumps[0].heating_capacity /= 10.0
      hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.each do |dp|
        dp.capacity /= 10.0
        htg_capacities_detailed << dp.capacity
      end
      hpxml_bldg.heat_pumps[0].backup_heating_capacity /= 10.0
      hpxml_bldg.heat_pumps[0].cooling_capacity /= 10.0
      hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.each do |dp|
        dp.capacity /= 10.0
        clg_capacities_detailed << dp.capacity
      end
      htg_cap = hpxml_bldg.heat_pumps[0].heating_capacity
      htg_bak_cap = hpxml_bldg.heat_pumps[0].backup_heating_capacity
      clg_cap = hpxml_bldg.heat_pumps[0].cooling_capacity
      XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
      _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
      if allow_increased_fixed_capacities
        assert_operator(hpxml_bldg.heat_pumps[0].heating_capacity, :>, htg_cap)
        assert_operator(hpxml_bldg.heat_pumps[0].backup_heating_capacity, :>, htg_bak_cap)
        assert_operator(hpxml_bldg.heat_pumps[0].cooling_capacity, :>, clg_cap)
        hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.each_with_index do |dp, i|
          assert_operator(dp.capacity, :>, htg_capacities_detailed[i])
        end
        hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.each_with_index do |dp, i|
          assert_operator(dp.capacity, :>, clg_capacities_detailed[i])
        end
      else
        assert_equal(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap)
        assert_equal(hpxml_bldg.heat_pumps[0].backup_heating_capacity, htg_bak_cap)
        assert_equal(hpxml_bldg.heat_pumps[0].cooling_capacity, clg_cap)
        hpxml_bldg.heat_pumps[0].heating_detailed_performance_data.each_with_index do |dp, i|
          assert_equal(dp.capacity, htg_capacities_detailed[i])
        end
        hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data.each_with_index do |dp, i|
          assert_equal(dp.capacity, clg_capacities_detailed[i])
        end
      end
    end
  end

  def test_manual_j_sizing_inputs
    # Run base
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base.xml'))
    _model, _base_hpxml, base_hpxml_bldg = _test_measure(args_hash)

    # Test heating/cooling design temps
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.header.manualj_heating_design_temp = 0.0
    hpxml_bldg.header.manualj_cooling_design_temp = 100.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    assert_operator(test_hpxml_bldg.hvac_plant.hdl_total, :>, base_hpxml_bldg.hvac_plant.hdl_total)
    assert_operator(test_hpxml_bldg.hvac_plant.cdl_sens_total, :>, base_hpxml_bldg.hvac_plant.cdl_sens_total)

    # Test heating/cooling setpoints
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.header.manualj_heating_setpoint = 72.5
    hpxml_bldg.header.manualj_cooling_setpoint = 72.5
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    assert_operator(test_hpxml_bldg.hvac_plant.hdl_total, :>, base_hpxml_bldg.hvac_plant.hdl_total)
    assert_operator(test_hpxml_bldg.hvac_plant.cdl_sens_total, :>, base_hpxml_bldg.hvac_plant.cdl_sens_total)

    # Test internal loads
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.header.manualj_internal_loads_sensible = 1000.0
    hpxml_bldg.header.manualj_internal_loads_latent = 500.0
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    assert_equal(test_hpxml_bldg.hvac_plant.hdl_total, base_hpxml_bldg.hvac_plant.hdl_total)
    assert_operator(test_hpxml_bldg.hvac_plant.cdl_sens_intgains, :<, base_hpxml_bldg.hvac_plant.cdl_sens_intgains)
    assert_operator(test_hpxml_bldg.hvac_plant.cdl_lat_intgains, :>, base_hpxml_bldg.hvac_plant.cdl_lat_intgains)

    # Test number of occupants
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml, hpxml_bldg = _create_hpxml('base.xml')
    hpxml_bldg.header.manualj_num_occupants = 10
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    assert_equal(test_hpxml_bldg.hvac_plant.hdl_total, base_hpxml_bldg.hvac_plant.hdl_total)
    assert_operator(test_hpxml_bldg.hvac_plant.cdl_sens_intgains, :>, base_hpxml_bldg.hvac_plant.cdl_sens_intgains)
    assert_operator(test_hpxml_bldg.hvac_plant.cdl_lat_intgains, :>, base_hpxml_bldg.hvac_plant.cdl_lat_intgains)
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

  def test_ground_loop
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Base case
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    assert_equal(3, test_hpxml_bldg.geothermal_loops[0].num_bore_holes)
    assert_in_epsilon(688.5 / 3 + 5.0, test_hpxml_bldg.geothermal_loops[0].bore_length, 0.01)

    # Bore depth greater than the max -> increase number of boreholes
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump.xml')
    hpxml_bldg.site.ground_conductivity = 0.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    assert_equal(5, test_hpxml_bldg.geothermal_loops[0].num_bore_holes)
    assert_in_epsilon(2062.9 / 5 + 5, test_hpxml_bldg.geothermal_loops[0].bore_length, 0.01)

    # Bore depth greater than the max -> increase number of boreholes until the max, set depth to the max, and issue warning
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump.xml')
    hpxml_bldg.site.ground_conductivity = 0.07
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    assert_equal(10, test_hpxml_bldg.geothermal_loops[0].num_bore_holes)
    assert_in_epsilon(500.0, test_hpxml_bldg.geothermal_loops[0].bore_length, 0.01)

    # Boreholes greater than the max -> decrease the number of boreholes until the max
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump.xml')
    hpxml_bldg.heat_pumps[0].cooling_capacity *= 5
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    assert_equal(10, test_hpxml_bldg.geothermal_loops[0].num_bore_holes)
    assert_in_epsilon(3187.0 / 10 + 5, test_hpxml_bldg.geothermal_loops[0].bore_length, 0.01)
  end

  def test_g_function_library_linear_interpolation_example
    bore_config = HPXML::GeothermalLoopBorefieldConfigurationRectangle
    num_bore_holes = 40
    bore_spacing = UnitConversions.convert(7.0, 'm', 'ft')
    bore_depth = UnitConversions.convert(150.0, 'm', 'ft')
    bore_diameter = UnitConversions.convert(UnitConversions.convert(80.0, 'mm', 'm'), 'm', 'in') * 2
    valid_bore_configs = HVACSizing.valid_bore_configs
    g_functions_filename = valid_bore_configs[bore_config]
    g_functions_json = HVACSizing.get_g_functions_json(g_functions_filename)

    actual_lntts, actual_gfnc_coeff = HVACSizing.gshp_gfnc_coeff(bore_config, g_functions_json, num_bore_holes, bore_spacing, bore_depth, bore_diameter)

    expected_lntts = [-8.5, -7.8, -7.2, -6.5, -5.9, -5.2, -4.5, -3.963, -3.27, -2.864, -2.577, -2.171, -1.884, -1.191, -0.497, -0.274, -0.051, 0.196, 0.419, 0.642, 0.873, 1.112, 1.335, 1.679, 2.028, 2.275, 3.003]
    expected_gfnc_coeff = [2.619, 2.967, 3.279, 3.700, 4.190, 5.107, 6.680, 8.537, 11.991, 14.633, 16.767, 20.083, 22.593, 28.734, 34.345, 35.927, 37.342, 38.715, 39.768, 40.664, 41.426, 42.056, 42.524, 43.054, 43.416, 43.594, 43.885]

    expected_lntts.zip(actual_lntts).each do |v1, v2|
      assert_in_epsilon(v1, v2, 0.01)
    end
    expected_gfnc_coeff.zip(actual_gfnc_coeff).each do |v1, v2|
      assert_in_epsilon(v1, v2, 0.01)
    end
  end

  def test_all_g_function_configs_exist
    valid_configs = { HPXML::GeothermalLoopBorefieldConfigurationRectangle => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                      HPXML::GeothermalLoopBorefieldConfigurationOpenRectangle => [8, 10],
                      HPXML::GeothermalLoopBorefieldConfigurationC => [7, 9],
                      HPXML::GeothermalLoopBorefieldConfigurationL => [4, 5, 6, 7, 8, 9, 10],
                      HPXML::GeothermalLoopBorefieldConfigurationU => [7, 9, 10],
                      HPXML::GeothermalLoopBorefieldConfigurationLopsidedU => [6, 7, 8, 9, 10] }

    valid_configs.each do |bore_config, valid_num_bores|
      g_functions_filename = HVACSizing.valid_bore_configs[bore_config]
      g_functions_json = HVACSizing.get_g_functions_json(g_functions_filename)
      valid_num_bores.each do |num_bore_holes|
        HVACSizing.get_g_functions(g_functions_json, bore_config, num_bore_holes, '5._192._0.08') # b_h_rb is arbitrary
      end
    end
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

    return model, hpxml, hpxml.buildings[0]
  end

  def _create_hpxml(hpxml_name)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, hpxml_name))
    return hpxml, hpxml.buildings[0]
  end

  def _remove_hardsized_capacities(hpxml_bldg)
    hpxml_bldg.heating_systems.each do |htgsys|
      htgsys.heating_capacity = nil
    end
    hpxml_bldg.cooling_systems.each do |clgsys|
      clgsys.cooling_capacity = nil
      clgsys.integrated_heating_system_capacity = nil
    end
    hpxml_bldg.heat_pumps.each do |hpsys|
      hpsys.heating_capacity = nil
      hpsys.heating_capacity_17F = nil
      hpsys.heating_capacity_retention_fraction = nil
      hpsys.heating_capacity_retention_temp = nil
      hpsys.backup_heating_capacity = nil
      hpsys.cooling_capacity = nil
    end
  end
end
