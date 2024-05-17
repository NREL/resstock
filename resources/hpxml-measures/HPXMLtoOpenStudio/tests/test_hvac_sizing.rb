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
    @results_dir = File.join(@test_files_path, 'test_results')
    FileUtils.mkdir_p @results_dir
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    File.delete(File.join(File.dirname(__FILE__), 'results_annual.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_annual.csv')
    File.delete(File.join(File.dirname(__FILE__), 'results_design_load_details.csv')) if File.exist? File.join(File.dirname(__FILE__), 'results_design_load_details.csv')
  end

  def test_hvac_configurations
    # Test autosizing calculations for all base-hvac-foo.xml sample files.
    results_out = File.join(@results_dir, 'results_sizing.csv')
    File.delete(results_out) if File.exist? results_out

    air_source_hp_types = [HPXML::HVACTypeHeatPumpAirToAir,
                           HPXML::HVACTypeHeatPumpMiniSplit,
                           HPXML::HVACTypeHeatPumpPTHP,
                           HPXML::HVACTypeHeatPumpRoom]

    sizing_results = {}
    args_hash = { 'hpxml_path' => File.absolute_path(@tmp_hpxml_path),
                  'skip_validation' => true }
    Dir["#{@sample_files_path}/base-hvac*.xml"].each do |hvac_hpxml|
      next if (hvac_hpxml.include? 'autosize')
      next if hvac_hpxml.include? 'detailed-performance' # Autosizing not allowed

      { 'USA_CO_Denver.Intl.AP.725650_TMY3.epw' => 'denver',
        'USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw' => 'houston' }.each do |epw_path, location|
        hvac_hpxml = File.basename(hvac_hpxml)

        hpxml, hpxml_bldg = _create_hpxml(hvac_hpxml)
        hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = epw_path
        _remove_hardsized_capacities(hpxml_bldg)

        hp_backup_sizing_methodologies = [nil]
        if hpxml_bldg.heat_pumps.size > 0
          hp_sizing_methodologies = [HPXML::HeatPumpSizingACCA,
                                     HPXML::HeatPumpSizingHERS,
                                     HPXML::HeatPumpSizingMaxLoad]
          if hpxml_bldg.heat_pumps.any? { |hp| !hp.backup_type.nil? }
            hp_backup_sizing_methodologies = [HPXML::HeatPumpBackupSizingEmergency,
                                              HPXML::HeatPumpBackupSizingSupplemental]
          end
        else
          hp_sizing_methodologies = [nil]
        end

        hp_capacity_acca, hp_capacity_maxload = {}, {}
        hp_backup_capacity_emergency, hp_backup_capacity_supplemental = {}, {}
        hp_sizing_methodologies.product(hp_backup_sizing_methodologies).each do |hp_sizing_methodology, hp_backup_sizing_methodology|
          test_name = hvac_hpxml.gsub('base-hvac-', "#{location}-hvac-autosize-")
          if not hp_sizing_methodology.nil?
            test_name = test_name.gsub('.xml', "-sizing-methodology-#{hp_sizing_methodology}.xml")
            if not hp_backup_sizing_methodology.nil?
              test_name = test_name.gsub('.xml', "-backup-#{hp_backup_sizing_methodology}.xml")
            end
          end

          puts "Testing #{test_name}..."

          hpxml_bldg.header.heat_pump_sizing_methodology = hp_sizing_methodology
          hpxml_bldg.header.heat_pump_backup_sizing_methodology = hp_backup_sizing_methodology

          XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
          _autosized_model, _autosized_hpxml, autosized_bldg = _test_measure(args_hash)

          # Get values
          htg_cap, clg_cap, hp_backup_cap = Outputs.get_total_hvac_capacities(autosized_bldg)
          htg_cfm, clg_cfm = Outputs.get_total_hvac_airflows(autosized_bldg)
          sizing_results[test_name] = { 'HVAC Capacity: Heating (Btu/h)' => htg_cap.round(1),
                                        'HVAC Capacity: Cooling (Btu/h)' => clg_cap.round(1),
                                        'HVAC Capacity: Heat Pump Backup (Btu/h)' => hp_backup_cap.round(1),
                                        'HVAC Airflow: Heating (cfm)' => htg_cfm.round(1),
                                        'HVAC Airflow: Cooling (cfm)' => clg_cfm.round(1) }

          next if hpxml_bldg.heat_pumps.size != 1

          # Get more values for heat pump checks
          htg_load = autosized_bldg.hvac_plant.hdl_total
          clg_load = autosized_bldg.hvac_plant.cdl_sens_total + autosized_bldg.hvac_plant.cdl_lat_total
          hp = autosized_bldg.heat_pumps[0]
          # Test the sizing results before applying autosizing factors
          htg_cap = hp.heating_capacity
          if hp.backup_type == HPXML::HeatPumpBackupTypeIntegrated
            htg_backup_cap = hp.backup_heating_capacity
          elsif hp.backup_type == HPXML::HeatPumpBackupTypeSeparate
            htg_backup_cap = hp.backup_system.heating_capacity
          end
          clg_cap = hp.cooling_capacity
          charge_defect_ratio = hp.charge_defect_ratio.to_f
          airflow_defect_ratio = hp.airflow_defect_ratio.to_f
          if not hp.backup_heating_switchover_temp.nil?
            min_compressor_temp = hp.backup_heating_switchover_temp
          elsif not hp.compressor_lockout_temp.nil?
            min_compressor_temp = hp.compressor_lockout_temp
          end

          # Check HP capacity
          if hp_sizing_methodology == HPXML::HeatPumpSizingACCA
            hp_capacity_acca[hp_backup_sizing_methodology] = htg_cap
          elsif hp_sizing_methodology == HPXML::HeatPumpSizingMaxLoad
            hp_capacity_maxload[hp_backup_sizing_methodology] = htg_cap
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
          end

          # Check HP backup capacity
          if location == 'denver' && air_source_hp_types.include?(hp.heat_pump_type) && !htg_backup_cap.nil?
            if hp_backup_sizing_methodology == HPXML::HeatPumpBackupSizingEmergency
              hp_backup_capacity_emergency[hp_sizing_methodology] = htg_backup_cap
              if hp.fraction_heat_load_served == 0
                assert_equal(0, htg_backup_cap)
              else
                assert_operator(htg_backup_cap, :>, 0)
              end
            elsif hp_backup_sizing_methodology == HPXML::HeatPumpBackupSizingSupplemental
              hp_backup_capacity_supplemental[hp_sizing_methodology] = htg_backup_cap
              if hp.fraction_heat_load_served == 0
                assert_equal(0, htg_backup_cap)
              elsif hp_sizing_methodology == HPXML::HeatPumpSizingMaxLoad && min_compressor_temp <= autosized_bldg.header.manualj_heating_design_temp
                assert_equal(0, htg_backup_cap)
              else
                assert_operator(htg_backup_cap, :>, 0)
              end
            end
          end
        end

        next if hpxml_bldg.heat_pumps.size != 1

        # Check that MaxLoad >= ACCA for heat pump heating capacity
        hp_capacity_maxload.keys.each do |hp_backup_sizing_methodology|
          cap_maxload = hp_capacity_maxload[hp_backup_sizing_methodology]
          cap_acca = hp_capacity_acca[hp_backup_sizing_methodology]
          assert_operator(cap_maxload, :>=, cap_acca)
        end

        # Check that Emergency >= Supplemental for heat pump backup heating capacity
        hp_backup_capacity_emergency.keys.each do |hp_sizing_methodology|
          cap_emergency = hp_backup_capacity_emergency[hp_sizing_methodology]
          cap_supplemental = hp_backup_capacity_supplemental[hp_sizing_methodology]
          assert_operator(cap_emergency, :>=, cap_supplemental)
        end
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

  def test_manual_j_residences
    block_tol_btuh = 500 # Individual block load components
    space_tol_frac = 0.1 # Space totals
    space_tol_frac_duct = 0.5 # Space duct tolerance

    # Section 7: Vatilo Residence
    # Expected values from Figure 7-4
    puts 'Testing Vatilo Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Vatilo_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(9147, hpxml_bldg.hvac_plant.hdl_ducts, 1500)
    assert_in_delta(4234, hpxml_bldg.hvac_plant.hdl_windows, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_skylights, block_tol_btuh)
    assert_in_delta(574, hpxml_bldg.hvac_plant.hdl_doors, block_tol_btuh)
    assert_in_delta(2874, hpxml_bldg.hvac_plant.hdl_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, block_tol_btuh)
    assert_in_delta(7415, hpxml_bldg.hvac_plant.hdl_slabs, block_tol_btuh)
    assert_in_delta(1498, hpxml_bldg.hvac_plant.hdl_ceilings, block_tol_btuh)
    assert_in_delta(3089, hpxml_bldg.hvac_plant.hdl_infil, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_vent, block_tol_btuh)
    assert_in_delta(9973, hpxml_bldg.hvac_plant.cdl_sens_ducts, 2000)
    assert_in_delta(5295, hpxml_bldg.hvac_plant.cdl_sens_windows, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_skylights, block_tol_btuh)
    assert_in_delta(456, hpxml_bldg.hvac_plant.cdl_sens_doors, block_tol_btuh)
    assert_in_delta(1715, hpxml_bldg.hvac_plant.cdl_sens_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, block_tol_btuh)
    assert_in_delta(2112, hpxml_bldg.hvac_plant.cdl_sens_ceilings, block_tol_btuh)
    assert_in_delta(769, hpxml_bldg.hvac_plant.cdl_sens_infil, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_vent, block_tol_btuh)
    assert_in_delta(1890, hpxml_bldg.hvac_plant.cdl_sens_intgains, block_tol_btuh)
    assert_in_delta(2488, hpxml_bldg.hvac_plant.cdl_lat_ducts, 1500)
    assert_in_delta(1276, hpxml_bldg.hvac_plant.cdl_lat_infil, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_lat_vent, block_tol_btuh)
    assert_in_delta(600, hpxml_bldg.hvac_plant.cdl_lat_intgains, block_tol_btuh)

    # Vatilo Residence - Improved Ducts
    puts 'Testing Vatilo Residence - Improved Ducts...'
    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])
    hvac_dist = hpxml.buildings[0].hvac_distributions[0]
    hvac_dist.duct_leakage_measurements.find { |dlm| dlm.duct_type == HPXML::DuctTypeSupply }.duct_leakage_value *= 0.12 / 0.35
    hvac_dist.duct_leakage_measurements.find { |dlm| dlm.duct_type == HPXML::DuctTypeReturn }.duct_leakage_value *= 0.24 / 0.70
    hvac_dist.ducts.each do |duct|
      duct.duct_effective_r_value = 9.0
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(3170, hpxml_bldg.hvac_plant.hdl_ducts, 2000)
    assert_in_delta(3449, hpxml_bldg.hvac_plant.cdl_sens_ducts, block_tol_btuh)
    assert_in_delta(563, hpxml_bldg.hvac_plant.cdl_lat_ducts, block_tol_btuh)

    # Section 8: Victor Residence
    # Expected values from Figure 8-3
    puts 'Testing Victor Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Victor_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(29137, hpxml_bldg.hvac_plant.hdl_ducts, 3000)
    assert_in_delta(9978, hpxml_bldg.hvac_plant.hdl_windows, block_tol_btuh)
    assert_in_delta(471, hpxml_bldg.hvac_plant.hdl_skylights, block_tol_btuh)
    assert_in_delta(984, hpxml_bldg.hvac_plant.hdl_doors, block_tol_btuh)
    assert_in_delta(6305, hpxml_bldg.hvac_plant.hdl_walls, block_tol_btuh)
    assert_in_delta(7069, hpxml_bldg.hvac_plant.hdl_roofs, block_tol_btuh)
    assert_in_delta(6044, hpxml_bldg.hvac_plant.hdl_floors, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_slabs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_ceilings, block_tol_btuh)
    assert_in_delta(19981, hpxml_bldg.hvac_plant.hdl_infil, block_tol_btuh)
    assert_in_delta(1445, hpxml_bldg.hvac_plant.hdl_vent, block_tol_btuh)
    assert_in_delta(5602, hpxml_bldg.hvac_plant.cdl_sens_ducts, 3500)
    assert_in_delta(4706, hpxml_bldg.hvac_plant.cdl_sens_windows, block_tol_btuh)
    assert_in_delta(1409, hpxml_bldg.hvac_plant.cdl_sens_skylights, block_tol_btuh)
    assert_in_delta(382, hpxml_bldg.hvac_plant.cdl_sens_doors, block_tol_btuh)
    assert_in_delta(1130, hpxml_bldg.hvac_plant.cdl_sens_walls, block_tol_btuh)
    assert_in_delta(2743, hpxml_bldg.hvac_plant.cdl_sens_roofs, block_tol_btuh)
    assert_in_delta(1393, hpxml_bldg.hvac_plant.cdl_sens_floors, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_ceilings, block_tol_btuh)
    assert_in_delta(2181, hpxml_bldg.hvac_plant.cdl_sens_infil, block_tol_btuh)
    assert_in_delta(323, hpxml_bldg.hvac_plant.cdl_sens_vent, block_tol_btuh)
    assert_in_delta(3320, hpxml_bldg.hvac_plant.cdl_sens_intgains, block_tol_btuh)
    assert_in_delta(6282, hpxml_bldg.hvac_plant.cdl_lat_ducts, 4500)
    assert_in_delta(4044, hpxml_bldg.hvac_plant.cdl_lat_infil, block_tol_btuh)
    assert_in_delta(600, hpxml_bldg.hvac_plant.cdl_lat_vent, block_tol_btuh)
    assert_in_delta(800, hpxml_bldg.hvac_plant.cdl_lat_intgains, block_tol_btuh)

    # Section 8: Victor Residence - Improved Ducts
    puts 'Testing Victor Residence - Improved Ducts...'
    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])
    hvac_dist = hpxml.buildings[0].hvac_distributions[0]
    hvac_dist.duct_leakage_measurements.find { |dlm| dlm.duct_type == HPXML::DuctTypeSupply }.duct_leakage_value *= 0.12 / 0.35
    hvac_dist.duct_leakage_measurements.find { |dlm| dlm.duct_type == HPXML::DuctTypeReturn }.duct_leakage_value *= 0.24 / 0.70
    hvac_dist.ducts.each do |duct|
      duct.duct_effective_r_value = 9.0
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(5640, hpxml_bldg.hvac_plant.hdl_ducts, 4500) # Note Manual J Figure 8-1 has a typo
    assert_in_delta(1263, hpxml_bldg.hvac_plant.cdl_sens_ducts, 2500)
    assert_in_delta(1442, hpxml_bldg.hvac_plant.cdl_lat_ducts, 1000)

    # Section 9: Long Residence
    # Modeled as a fully conditioned basement (e.g., no duct losses) for block load calculation
    # Expected values from Figure 9-3
    puts 'Testing Long Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Long_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_ducts, block_tol_btuh)
    assert_in_delta(8315, hpxml_bldg.hvac_plant.hdl_windows, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_skylights, block_tol_btuh)
    assert_in_delta(1006, hpxml_bldg.hvac_plant.hdl_doors, block_tol_btuh)
    assert_in_delta(16608, hpxml_bldg.hvac_plant.hdl_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, block_tol_btuh)
    assert_in_delta(2440, hpxml_bldg.hvac_plant.hdl_slabs, block_tol_btuh)
    assert_in_delta(5435, hpxml_bldg.hvac_plant.hdl_ceilings, block_tol_btuh)
    assert_in_delta(6944, hpxml_bldg.hvac_plant.hdl_infil, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_vent, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_ducts, block_tol_btuh)
    assert_in_delta(5962, hpxml_bldg.hvac_plant.cdl_sens_windows, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_skylights, block_tol_btuh)
    assert_in_delta(349, hpxml_bldg.hvac_plant.cdl_sens_doors, block_tol_btuh)
    assert_in_delta(1730, hpxml_bldg.hvac_plant.cdl_sens_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, block_tol_btuh)
    assert_in_delta(3624, hpxml_bldg.hvac_plant.cdl_sens_ceilings, block_tol_btuh)
    assert_in_delta(565, hpxml_bldg.hvac_plant.cdl_sens_infil, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_vent, block_tol_btuh)
    assert_in_delta(3320, hpxml_bldg.hvac_plant.cdl_sens_intgains, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_lat_ducts, block_tol_btuh)
    assert_in_delta(998, hpxml_bldg.hvac_plant.cdl_lat_infil, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_lat_vent, block_tol_btuh)
    assert_in_delta(1200, hpxml_bldg.hvac_plant.cdl_lat_intgains, block_tol_btuh)
    space_tol_btuh = 100 # Individual space load components
    dining_space = hpxml_bldg.conditioned_spaces.find { |s| s.id.include? 'dining' }
    assert_in_delta(902 + 407, dining_space.hdl_walls, space_tol_btuh)
    assert_in_delta(463, dining_space.hdl_ceilings, space_tol_btuh)
    assert_in_delta(779, dining_space.hdl_infil, space_tol_btuh)
    assert_in_delta(153 + 69, dining_space.cdl_sens_walls, space_tol_btuh)
    assert_in_delta(309, dining_space.cdl_sens_ceilings, space_tol_btuh)
    assert_in_delta(63, dining_space.cdl_sens_infil, space_tol_btuh)
    assert_in_delta(0, dining_space.cdl_sens_ducts, space_tol_btuh)
    assert_in_delta(0, dining_space.cdl_sens_intgains, space_tol_btuh)
    living_space = hpxml_bldg.conditioned_spaces.find { |s| s.id.include? 'living' }
    assert_in_delta(930, living_space.hdl_walls, space_tol_btuh)
    assert_in_delta(1080, living_space.hdl_ceilings, space_tol_btuh)
    assert_in_delta(655, living_space.hdl_infil, space_tol_btuh)
    assert_in_delta(158, living_space.cdl_sens_walls, space_tol_btuh)
    assert_in_delta(720, living_space.cdl_sens_ceilings, space_tol_btuh)
    assert_in_delta(53, living_space.cdl_sens_infil, space_tol_btuh)
    assert_in_delta(0, living_space.cdl_sens_ducts, space_tol_btuh)
    assert_in_delta(460, living_space.cdl_sens_intgains, space_tol_btuh)
    hall_1_space = hpxml_bldg.conditioned_spaces.find { |s| s.id.include? 'hall_1' }
    assert_in_delta(551, hall_1_space.hdl_doors, space_tol_btuh)
    assert_in_delta(313, hall_1_space.hdl_walls, space_tol_btuh)
    assert_in_delta(412, hall_1_space.hdl_ceilings, space_tol_btuh)
    assert_in_delta(249, hall_1_space.hdl_infil, space_tol_btuh)

    # Section 12: Smith Residence
    # Expected values from Form J1
    puts 'Testing Smith Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Smith_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(2561, hpxml_bldg.hvac_plant.hdl_ducts, 2000)
    assert_in_delta(9634, hpxml_bldg.hvac_plant.hdl_windows, block_tol_btuh)
    # assert_in_delta(2994, hpxml_bldg.hvac_plant.hdl_skylights, block_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(1118, hpxml_bldg.hvac_plant.hdl_doors, block_tol_btuh)
    assert_in_delta(17440, hpxml_bldg.hvac_plant.hdl_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, block_tol_btuh)
    assert_in_delta(1788, hpxml_bldg.hvac_plant.hdl_floors, block_tol_btuh)
    assert_in_delta(3692, hpxml_bldg.hvac_plant.hdl_slabs, block_tol_btuh)
    assert_in_delta(4261, hpxml_bldg.hvac_plant.hdl_ceilings, block_tol_btuh)
    assert_in_delta(11237, hpxml_bldg.hvac_plant.hdl_infil, block_tol_btuh)
    assert_in_delta(1987, hpxml_bldg.hvac_plant.hdl_vent, block_tol_btuh)
    assert_in_delta(530, hpxml_bldg.hvac_plant.cdl_sens_ducts, block_tol_btuh)
    assert_in_delta(6187, hpxml_bldg.hvac_plant.cdl_sens_windows, block_tol_btuh)
    # assert_in_delta(3780, hpxml_bldg.hvac_plant.cdl_sens_skylights, block_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(382, hpxml_bldg.hvac_plant.cdl_sens_doors, block_tol_btuh)
    assert_in_delta(2669, hpxml_bldg.hvac_plant.cdl_sens_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, block_tol_btuh)
    assert_in_delta(352, hpxml_bldg.hvac_plant.cdl_sens_floors, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, block_tol_btuh)
    assert_in_delta(2803, hpxml_bldg.hvac_plant.cdl_sens_ceilings, block_tol_btuh)
    assert_in_delta(1054, hpxml_bldg.hvac_plant.cdl_sens_infil, block_tol_btuh)
    assert_in_delta(459, hpxml_bldg.hvac_plant.cdl_sens_vent, block_tol_btuh)
    assert_in_delta(3320, hpxml_bldg.hvac_plant.cdl_sens_intgains, block_tol_btuh)
    assert_in_delta(565, hpxml_bldg.hvac_plant.cdl_lat_ducts, 1500)
    assert_in_delta(1651, hpxml_bldg.hvac_plant.cdl_lat_infil, block_tol_btuh)
    assert_in_delta(1755, hpxml_bldg.hvac_plant.cdl_lat_vent, block_tol_btuh)
    assert_in_delta(800, hpxml_bldg.hvac_plant.cdl_lat_intgains, block_tol_btuh)

    # eyeball observation from figure 13-5
    # Fixme: Skylight not included so disable for now
    # block_aed = [6800, 8800, 11000, 13000, 14000, 15800, 16900, 17200, 16900, 15900, 13000, 6800]
    # hpxml_bldg.hvac_plant.cdl_sens_aed_curve.split(', ').map{|s| s.to_f}.each_with_index do |aed_curve_value, i|
    #  assert_in_delta(block_aed[i], aed_curve_value, block_aed[i] * space_tol_frac)
    # end

    # skylight excluded
    space_load_results = {
      ['living', 'dining'] => [9939 - 2207, 6531 - 2974],
      ['kitchen'] => [6703 - 787, 3648 - 806],
      ['bedroom_3'] => [2768, 1010],
      ['bedroom_1'] => [5070, 1520],
      ['bedroom_2'] => [4722, 1428],
      ['bathroom'] => [2407, 560],
      ['entry', 'hall'] => [1932, 674],
      ['recroom'] => [15586, 7890],
      ['laundry'] => [2292, 635],
      ['workshop'] => [3057, 192]
    }
    total_htg_loads = space_load_results.values.map { |loads| loads[0] }.sum.to_f
    total_clg_sens_loads = space_load_results.values.map { |loads| loads[1] }.sum.to_f
    space_load_results.each do |space_names, loads|
      est_space_duct_loads_htg = (loads[0].to_f / total_htg_loads * 2561.0)
      est_space_duct_loads_clg = (loads[1].to_f / total_clg_sens_loads * 530.0)
      space_load_no_ducts_htg = loads[0].to_f - est_space_duct_loads_htg
      space_load_no_ducts_clg = loads[1].to_f - est_space_duct_loads_clg
      spaces = hpxml_bldg.conditioned_spaces.select { |space| space_names.any? { |space_name| space.id.include? space_name } }
      spaces_htg_load = spaces.map { |space| space.hdl_total - space.hdl_ducts }.sum
      spaces_clg_load = spaces.map { |space| space.cdl_sens_total - space.cdl_sens_ducts }.sum
      spaces_duct_load_htg = spaces.map { |space| space.hdl_ducts }.sum
      spaces_duct_load_clg = spaces.map { |space| space.cdl_sens_ducts }.sum
      assert_in_delta(space_load_no_ducts_clg, spaces_clg_load, [space_load_no_ducts_clg * space_tol_frac, block_tol_btuh].max)
      assert_in_delta(space_load_no_ducts_htg, spaces_htg_load, [space_load_no_ducts_htg * space_tol_frac, block_tol_btuh].max)
      assert_in_delta(est_space_duct_loads_clg, spaces_duct_load_clg, [est_space_duct_loads_clg * space_tol_frac_duct, block_tol_btuh].max)
      assert_in_delta(est_space_duct_loads_htg, spaces_duct_load_htg, [est_space_duct_loads_htg * space_tol_frac_duct, block_tol_btuh].max)
    end
    # eyeball observation from figure 12-9
    rec_room_aed = [1300, 1800, 2200, 2600, 2800, 4000, 5500, 6900, 7400, 7200, 5600, 1800]
    rec_room_space = hpxml_bldg.conditioned_spaces.find { |space| space.id.include? 'recroom' }
    rec_room_space.cdl_sens_aed_curve.split(', ').map { |s| s.to_f }.each_with_index do |aed_curve_value, i|
      assert_in_delta(rec_room_aed[i], aed_curve_value, [rec_room_aed[i] * space_tol_frac, block_tol_btuh].max)
    end

    # Section 13: Walker Residence
    # Expected values from Form J1 (Note: it shows Ceiling Option 3 for some reason)
    puts 'Testing Walker Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Walker_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_ducts, block_tol_btuh)
    assert_in_delta(1608, hpxml_bldg.hvac_plant.hdl_windows, block_tol_btuh)
    # assert_in_delta(543, hpxml_bldg.hvac_plant.hdl_skylights, block_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(264, hpxml_bldg.hvac_plant.hdl_doors, block_tol_btuh)
    assert_in_delta(1446, hpxml_bldg.hvac_plant.hdl_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, block_tol_btuh)
    assert_in_delta(2172, hpxml_bldg.hvac_plant.hdl_slabs, block_tol_btuh)
    assert_in_delta(820, hpxml_bldg.hvac_plant.hdl_ceilings, block_tol_btuh)
    assert_in_delta(456, hpxml_bldg.hvac_plant.hdl_infil, block_tol_btuh)
    assert_in_delta(990, hpxml_bldg.hvac_plant.hdl_vent, block_tol_btuh)
    assert_in_delta(851, hpxml_bldg.hvac_plant.cdl_sens_ducts, 2500)
    assert_in_delta(1776, hpxml_bldg.hvac_plant.cdl_sens_windows, block_tol_btuh)
    # assert_in_delta(3182, hpxml_bldg.hvac_plant.cdl_sens_skylights, block_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(442, hpxml_bldg.hvac_plant.cdl_sens_doors, block_tol_btuh)
    assert_in_delta(1173, hpxml_bldg.hvac_plant.cdl_sens_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, block_tol_btuh)
    assert_in_delta(865, hpxml_bldg.hvac_plant.cdl_sens_ceilings, block_tol_btuh)
    # assert_in_delta(825, hpxml_bldg.hvac_plant.cdl_sens_infilvent, block_tol_btuh) Skip due to dehumidifying ventilation
    assert_in_delta(5541, hpxml_bldg.hvac_plant.cdl_sens_intgains, block_tol_btuh)
    assert_in_delta(655, hpxml_bldg.hvac_plant.cdl_lat_ducts, block_tol_btuh)
    # assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_lat_infilvent, block_tol_btuh) Skip due to dehumidifying ventilation
    assert_in_delta(800, hpxml_bldg.hvac_plant.cdl_lat_intgains, block_tol_btuh)

    # Fixme: Skylight not included so disable for now
    # eyeball observation from figure 13-5
    # block_aed = [3800, 4600, 5400, 6200, 6900, 7200, 7250, 7250, 7000, 6500, 5800, 4100]
    # hpxml_bldg.hvac_plant.cdl_sens_aed_curve.split(', ').map{|s| s.to_f}.each_with_index do |aed_curve_value, i|
    #  assert_in_delta(block_aed[i], aed_curve_value, block_aed[i] * space_tol_frac)
    # end

    # skylight excluded
    space_load_results = {
      ['living', 'dining'] => [1880 - 409, 5478 - 2507],
      ['kitchen'] => [1084 - 134, 4845 - 675],
      ['bedroom_3'] => [384, 763],
      ['bedroom_1'] => [680, 1050],
      ['bedroom_2'] => [640, 1110],
      ['bathroom'] => [353, 290],
      ['entry', 'hall'] => [306, 390]
    }
    total_htg_loads = space_load_results.values.map { |loads| loads[0] }.sum.to_f
    total_clg_sens_loads = space_load_results.values.map { |loads| loads[1] }.sum.to_f
    space_load_results.each do |space_names, loads|
      est_space_duct_loads_htg = (loads[0].to_f / total_htg_loads * 0.0)
      est_space_duct_loads_clg = (loads[1].to_f / total_clg_sens_loads * 851.0)
      space_load_no_ducts_htg = loads[0].to_f - est_space_duct_loads_htg
      space_load_no_ducts_clg = loads[1].to_f - est_space_duct_loads_clg
      spaces = hpxml_bldg.conditioned_spaces.select { |space| space_names.any? { |space_name| space.id.include? space_name } }
      # Note: Exclude radiant floor from room load below per Section 13-4
      spaces_htg_load = spaces.map { |space| space.hdl_total - space.hdl_ducts - space.hdl_slabs }.sum
      spaces_clg_load = spaces.map { |space| space.cdl_sens_total - space.cdl_sens_ducts }.sum
      spaces_duct_load_htg = spaces.map { |space| space.hdl_ducts }.sum
      spaces_duct_load_clg = spaces.map { |space| space.cdl_sens_ducts }.sum
      assert_in_delta(space_load_no_ducts_htg, spaces_htg_load, [space_load_no_ducts_htg * space_tol_frac, block_tol_btuh].max)
      assert_in_delta(space_load_no_ducts_clg, spaces_clg_load, [space_load_no_ducts_clg * space_tol_frac, block_tol_btuh].max)
      assert_in_delta(est_space_duct_loads_htg, spaces_duct_load_htg, [est_space_duct_loads_htg * space_tol_frac_duct, block_tol_btuh].max)
      assert_in_delta(est_space_duct_loads_clg, spaces_duct_load_clg, [est_space_duct_loads_clg * space_tol_frac_duct, 800].max)
    end

    # Section 13: Walker Residence - Ceiling Option 1
    puts 'Testing Walker Residence - Ceiling Option 1...'
    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])
    hpxml.buildings[0].roofs[0].roof_type = HPXML::RoofTypeAsphaltShingles
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(820, hpxml_bldg.hvac_plant.hdl_ceilings, block_tol_btuh)
    assert_in_delta(2003, hpxml_bldg.hvac_plant.cdl_sens_ceilings, block_tol_btuh)

    # Section 13: Walker Residence - Ceiling Option 2
    puts 'Testing Walker Residence - Ceiling Option 2...'
    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])
    hpxml.buildings[0].roofs[0].roof_type = HPXML::RoofTypeAsphaltShingles
    hpxml.buildings[0].roofs[0].radiant_barrier = true
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(820, hpxml_bldg.hvac_plant.hdl_ceilings, block_tol_btuh)
    assert_in_delta(1548, hpxml_bldg.hvac_plant.cdl_sens_ceilings, block_tol_btuh)

    # Section 14: Cobb Residence
    # Expected values from Form J1
    puts 'Testing Cobb Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Cobb_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    # assert_in_delta(499, hpxml_bldg.hvac_plant.hdl_ducts, block_tol_btuh) Skip due to ducts in closed ceiling cavity
    assert_in_delta(3015, hpxml_bldg.hvac_plant.hdl_windows, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_skylights, block_tol_btuh)
    assert_in_delta(169, hpxml_bldg.hvac_plant.hdl_doors, block_tol_btuh)
    assert_in_delta(1975, hpxml_bldg.hvac_plant.hdl_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_slabs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_ceilings, block_tol_btuh)
    assert_in_delta(1770, hpxml_bldg.hvac_plant.hdl_infil, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_vent, block_tol_btuh)
    # assert_in_delta(1631, hpxml_bldg.hvac_plant.cdl_sens_ducts, block_tol_btuh) Skip due to ducts in closed ceiling cavity
    assert_in_delta(7654, hpxml_bldg.hvac_plant.cdl_sens_windows, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_skylights, block_tol_btuh)
    assert_in_delta(228, hpxml_bldg.hvac_plant.cdl_sens_doors, block_tol_btuh)
    assert_in_delta(1236, hpxml_bldg.hvac_plant.cdl_sens_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_ceilings, block_tol_btuh)
    assert_in_delta(764, hpxml_bldg.hvac_plant.cdl_sens_infil, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_vent, block_tol_btuh)
    assert_in_delta(5224, hpxml_bldg.hvac_plant.cdl_sens_intgains, block_tol_btuh)
    assert_in_delta(5516, hpxml_bldg.hvac_plant.cdl_sens_aedexcursion, block_tol_btuh)
    # assert_in_delta(1189, hpxml_bldg.hvac_plant.cdl_lat_ducts, block_tol_btuh) Skip due to ducts in closed ceiling cavity
    assert_in_delta(1391, hpxml_bldg.hvac_plant.cdl_lat_infil, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_lat_vent, block_tol_btuh)
    assert_in_delta(800, hpxml_bldg.hvac_plant.cdl_lat_intgains, block_tol_btuh)
    # eyeball observation from figure 14-3
    block_aed = [2500, 3200, 3900, 4200, 4600, 7500, 10600, 13900, 15200, 16100, 12700, 4100]
    hpxml_bldg.hvac_plant.cdl_sens_aed_curve.split(', ').map { |s| s.to_f }.each_with_index do |aed_curve_value, i|
      assert_in_delta(block_aed[i], aed_curve_value, [block_aed[i] * space_tol_frac, block_tol_btuh].max)
    end
    space_load_results = {
      ['living', 'dining'] => [2534, 7176],
      ['kitchen', 'utility', 'entry'] => [773, 2121],
      # ['bedroom_3'] => [1550, 3572], # Bedroom 3 for some reason has much greater heating loads than bedroom 2, which is of similar layout, exclude it for now
      ['bedroom_2'] => [1059, 2930],
      ['bedroom_1'] => [2163, 6174],
      ['bathroom'] => [351, 161]
    }
    total_htg_loads = space_load_results.values.map { |loads| loads[0] }.sum.to_f
    total_clg_sens_loads = space_load_results.values.map { |loads| loads[1] }.sum.to_f
    space_load_results.each do |space_names, loads|
      est_space_duct_loads_htg = (loads[0].to_f / total_htg_loads * 499.0)
      est_space_duct_loads_clg = (loads[1].to_f / total_clg_sens_loads * 1631.0)
      space_load_no_ducts_htg = loads[0].to_f - est_space_duct_loads_htg
      space_load_no_ducts_clg = loads[1].to_f - est_space_duct_loads_clg
      spaces = hpxml_bldg.conditioned_spaces.select { |space| space_names.any? { |space_name| space.id.include? space_name } }
      spaces_htg_load = spaces.map { |space| space.hdl_total - space.hdl_ducts }.sum
      spaces_clg_load = spaces.map { |space| space.cdl_sens_total - space.cdl_sens_ducts }.sum
      # spaces_duct_load_htg = spaces.map { |space| space.hdl_ducts }.sum
      # spaces_duct_load_clg = spaces.map { |space| space.cdl_sens_ducts }.sum
      assert_in_delta(space_load_no_ducts_htg, spaces_htg_load, [space_load_no_ducts_htg * space_tol_frac, block_tol_btuh].max)
      assert_in_delta(space_load_no_ducts_clg, spaces_clg_load, [space_load_no_ducts_clg * space_tol_frac, block_tol_btuh].max)
      # Skip duct check
      # assert_in_delta(est_space_duct_loads_htg, spaces_duct_load_htg, [est_space_duct_loads_htg * space_tol_frac_duct, block_tol_btuh].max)
      # assert_in_delta(est_space_duct_loads_clg, spaces_duct_load_clg, [est_space_duct_loads_clg * space_tol_frac_duct, 1000.0].max)
    end
    # eyeball observation from figure 14-5, 14-6, 14-7
    living_dining_aed = [1000, 1250, 1550, 1800, 1900, 3000, 4450, 5700, 6300, 6600, 5100, 1800]
    living_dining_space = hpxml_bldg.conditioned_spaces.find { |space| space.id.include? 'living_dining' }
    living_dining_space.cdl_sens_aed_curve.split(', ').map { |s| s.to_f }.each_with_index do |aed_curve_value, i|
      assert_in_delta(living_dining_aed[i], aed_curve_value, [living_dining_aed[i] * space_tol_frac, block_tol_btuh].max)
    end
    bedroom_1_aed = [850, 1050, 1250, 1400, 1550, 2450, 3500, 4600, 5050, 5200, 4100, 1400]
    bedroom_1_space = hpxml_bldg.conditioned_spaces.find { |space| space.id.include? 'bedroom_1' }
    bedroom_1_space.cdl_sens_aed_curve.split(', ').map { |s| s.to_f }.each_with_index do |aed_curve_value, i|
      assert_in_delta(bedroom_1_aed[i], aed_curve_value, [bedroom_1_aed[i] * space_tol_frac, block_tol_btuh].max)
    end
    bedroom_2_aed = [370, 440, 510, 570, 630, 950, 1480, 1850, 2050, 2200, 1650, 550]
    bedroom_2_space = hpxml_bldg.conditioned_spaces.find { |space| space.id.include? 'bedroom_2' }
    bedroom_2_space.cdl_sens_aed_curve.split(', ').map { |s| s.to_f }.each_with_index do |aed_curve_value, i|
      assert_in_delta(bedroom_2_aed[i], aed_curve_value, [bedroom_2_aed[i] * space_tol_frac, block_tol_btuh].max)
    end
    bedroom_3_aed = [370, 440, 510, 570, 630, 950, 1480, 1850, 2050, 2200, 1650, 550]
    bedroom_3_space = hpxml_bldg.conditioned_spaces.find { |space| space.id.include? 'bedroom_3' }
    bedroom_3_space.cdl_sens_aed_curve.split(', ').map { |s| s.to_f }.each_with_index do |aed_curve_value, i|
      assert_in_delta(bedroom_3_aed[i], aed_curve_value, [bedroom_3_aed[i] * space_tol_frac, block_tol_btuh].max)
    end

    # Section 15: Bell Residence
    # Expected values from Form J1
    puts 'Testing Bell Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Bell_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(1340, hpxml_bldg.hvac_plant.hdl_ducts, 2000)
    assert_in_delta(10912, hpxml_bldg.hvac_plant.hdl_windows, block_tol_btuh)
    # assert_in_delta(1981, hpxml_bldg.hvac_plant.hdl_skylights, block_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(1538, hpxml_bldg.hvac_plant.hdl_doors, block_tol_btuh)
    assert_in_delta(3672, hpxml_bldg.hvac_plant.hdl_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, block_tol_btuh)
    assert_in_delta(3431, hpxml_bldg.hvac_plant.hdl_slabs, block_tol_btuh)
    assert_in_delta(1992, hpxml_bldg.hvac_plant.hdl_ceilings, block_tol_btuh)
    assert_in_delta(1760, hpxml_bldg.hvac_plant.hdl_infil, block_tol_btuh)
    assert_in_delta(1562, hpxml_bldg.hvac_plant.hdl_vent, block_tol_btuh)
    assert_in_delta(1673, hpxml_bldg.hvac_plant.cdl_sens_ducts, block_tol_btuh)
    assert_in_delta(11654, hpxml_bldg.hvac_plant.cdl_sens_windows, block_tol_btuh) # Excludes 2045 Btuh for AED excursion since skylight is not modeled
    # assert_in_delta(5514, hpxml_bldg.hvac_plant.cdl_sens_skylights, block_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(782, hpxml_bldg.hvac_plant.cdl_sens_doors, block_tol_btuh)
    assert_in_delta(939, hpxml_bldg.hvac_plant.cdl_sens_walls, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, block_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, block_tol_btuh)
    assert_in_delta(1796, hpxml_bldg.hvac_plant.cdl_sens_ceilings, block_tol_btuh)
    assert_in_delta(317, hpxml_bldg.hvac_plant.cdl_sens_infil, block_tol_btuh)
    assert_in_delta(493, hpxml_bldg.hvac_plant.cdl_sens_vent, block_tol_btuh)
    assert_in_delta(4541, hpxml_bldg.hvac_plant.cdl_sens_intgains, block_tol_btuh)
    assert_in_delta(64, hpxml_bldg.hvac_plant.cdl_lat_ducts, block_tol_btuh)
    assert_in_delta(241, hpxml_bldg.hvac_plant.cdl_lat_infil, block_tol_btuh)
    assert_in_delta(329, hpxml_bldg.hvac_plant.cdl_lat_vent, block_tol_btuh)
    assert_in_delta(1000, hpxml_bldg.hvac_plant.cdl_lat_intgains, block_tol_btuh)
    # skylight excluded
    space_load_results = {
      ['family'] => [8931 - 1981, 18173 - 5514],
      ['kitchen'] => [3007, 3272],
      ['utility'] => [970, 1181],
      ['dining'] => [4750, 3821],
      ['bedroom_3'] => [1314, 1748],
      ['bedroom_2'] => [2493, 2811],
      ['bedroom_1'] => [3847, 4005],
      ['bathroom_1'] => [793, 980],
      ['bathroom_2'] => [58, 53],
      ['hall', 'closet'] => [369, 195]
    }
    total_htg_loads = space_load_results.values.map { |loads| loads[0] }.sum.to_f
    total_clg_sens_loads = space_load_results.values.map { |loads| loads[1] }.sum.to_f
    space_load_results.each do |space_names, loads|
      est_space_duct_loads_htg = (loads[0].to_f / total_htg_loads * 1340.0)
      est_space_duct_loads_clg = (loads[1].to_f / total_clg_sens_loads * 1673.0)
      space_load_no_ducts_htg = loads[0].to_f - est_space_duct_loads_htg
      space_load_no_ducts_clg = loads[1].to_f - est_space_duct_loads_clg
      spaces = hpxml_bldg.conditioned_spaces.select { |space| space_names.any? { |space_name| space.id.include? space_name } }
      spaces_htg_load = spaces.map { |space| space.hdl_total - space.hdl_ducts }.sum
      spaces_clg_load = spaces.map { |space| space.cdl_sens_total - space.cdl_sens_ducts }.sum
      spaces_duct_load_htg = spaces.map { |space| space.hdl_ducts }.sum
      spaces_duct_load_clg = spaces.map { |space| space.cdl_sens_ducts }.sum
      assert_in_delta(space_load_no_ducts_htg, spaces_htg_load, [space_load_no_ducts_htg * space_tol_frac, block_tol_btuh].max)
      assert_in_delta(space_load_no_ducts_clg, spaces_clg_load, [space_load_no_ducts_clg * space_tol_frac, block_tol_btuh].max)
      assert_in_delta(est_space_duct_loads_htg, spaces_duct_load_htg, [est_space_duct_loads_htg * space_tol_frac_duct, block_tol_btuh].max)
      assert_in_delta(est_space_duct_loads_clg, spaces_duct_load_clg, [est_space_duct_loads_clg * space_tol_frac_duct, 800].max)
    end
    # eyeball observation from figure 15-5, 15-6, 15-7
    # family includes skylihgt, disable for now
    # family_room_aed = [4100, 5500, 6900, 7600, 8900, 10000, 12900, 14500, 15400, 15100, 13000, 8900]
    # family_room_space = hpxml_bldg.conditioned_spaces.find { |space| space.id.include? 'family_room' }
    # family_room_space.cdl_sens_aed_curve.split(', ').map{|s| s.to_f}.each_with_index do |aed_curve_value, i|
    #  assert_in_delta(family_room_aed[i], aed_curve_value, family_room_aed[i] * space_tol_frac)
    # end
    dining_aed = [1300, 1250, 1150, 1100, 1230, 1350, 1780, 2100, 2300, 2250, 1800, 770]
    dining_space = hpxml_bldg.conditioned_spaces.find { |space| space.id.include? 'dining' }
    dining_space.cdl_sens_aed_curve.split(', ').map { |s| s.to_f }.each_with_index do |aed_curve_value, i|
      assert_in_delta(dining_aed[i], aed_curve_value, [dining_aed[i] * space_tol_frac, block_tol_btuh].max)
    end
    bedroom_1_aed = [2550, 2490, 2200, 1950, 1650, 1450, 1350, 1250, 1150, 1000, 850, 550]
    bedroom_1_space = hpxml_bldg.conditioned_spaces.find { |space| space.id.include? 'bedroom_1' }
    bedroom_1_space.cdl_sens_aed_curve.split(', ').map { |s| s.to_f }.each_with_index do |aed_curve_value, i|
      assert_in_delta(bedroom_1_aed[i], aed_curve_value, [bedroom_1_aed[i] * space_tol_frac, block_tol_btuh].max)
    end
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

    # Check that furnace capacity is greater than the building heating design load.
    # The building heating design load includes HP duct loads, while the furnace capacity includes
    # furnace duct loads. Since the furnace has a higher supply air temperature, it will experience
    # higher duct loads than the HP.
    htg_design_load_with_ducts = hpxml_bldg.hvac_plant.hdl_total
    htg_capacity = hpxml_bldg.heating_systems[0].heating_capacity
    assert_operator(htg_capacity, :>, htg_design_load_with_ducts * 1.01)

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

  def test_autosizing_factors
    clg_autosizing_factors = [0.8, 1.2]
    htg_autosizing_factors = [0.9, 1.7]
    for caf in clg_autosizing_factors
      for haf in htg_autosizing_factors
        args_hash = {}
        args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

        bhaf = 2.0 - haf # use a reverse factor for backup heating sizing

        # Test air conditioner + furnace
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.heating_systems[0].heating_capacity = nil
        hpxml_bldg.cooling_systems[0].cooling_capacity = nil
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        htg_cap_orig = hpxml_bldg.heating_systems[0].heating_capacity
        clg_cap_orig = hpxml_bldg.cooling_systems[0].cooling_capacity
        # apply autosizing factor
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.heating_systems[0].heating_capacity = nil
        hpxml_bldg.cooling_systems[0].cooling_capacity = nil
        hpxml_bldg.heating_systems[0].heating_autosizing_factor = haf
        hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = caf
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        assert_in_epsilon(hpxml_bldg.heating_systems[0].heating_capacity, htg_cap_orig * haf, 0.001)
        assert_in_epsilon(hpxml_bldg.cooling_systems[0].cooling_capacity, clg_cap_orig * caf, 0.001)

        # Test heat pump
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].cooling_capacity = nil
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        htg_cap_orig = hpxml_bldg.heat_pumps[0].heating_capacity
        clg_cap_orig = hpxml_bldg.heat_pumps[0].cooling_capacity
        backup_htg_cap_orig = hpxml_bldg.heat_pumps[0].backup_heating_capacity
        # apply autosizing factor
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].cooling_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_autosizing_factor = haf
        hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = bhaf
        hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = caf
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap_orig * haf, 0.001)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].backup_heating_capacity, backup_htg_cap_orig * bhaf, 0.001)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, clg_cap_orig * caf, 0.001)

        # Test heat pump w/ detailed performance
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance-autosize.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        htg_cap_orig = hpxml_bldg.heat_pumps[0].heating_capacity
        clg_cap_orig = hpxml_bldg.heat_pumps[0].cooling_capacity
        backup_htg_cap_orig = hpxml_bldg.heat_pumps[0].backup_heating_capacity
        # apply autosizing factor
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance-autosize.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].cooling_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_autosizing_factor = haf
        hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = caf
        hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = bhaf
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap_orig * haf, 0.001)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].backup_heating_capacity, backup_htg_cap_orig * bhaf, 0.001)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, clg_cap_orig * caf, 0.001)

        # Test heat pump with separate backup heating
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-furnace.xml')
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].cooling_capacity = nil
        hpxml_bldg.heating_systems[0].heating_capacity = nil
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        htg_cap_orig = hpxml_bldg.heat_pumps[0].heating_capacity
        clg_cap_orig = hpxml_bldg.heat_pumps[0].cooling_capacity
        backup_htg_cap_orig = hpxml_bldg.heating_systems[0].heating_capacity
        # apply autosizing factor
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-furnace.xml')
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].cooling_capacity = nil
        hpxml_bldg.heating_systems[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_autosizing_factor = haf
        hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = caf
        hpxml_bldg.heating_systems[0].heating_autosizing_factor = bhaf
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap_orig * haf, 0.001)
        assert_in_epsilon(hpxml_bldg.heating_systems[0].heating_capacity, backup_htg_cap_orig * bhaf, 0.001)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, clg_cap_orig * caf, 0.001)

        # Test allow increased fixed capacity
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-undersized.xml')
        hpxml_bldg.header.allow_increased_fixed_capacities = true
        # apply autosizing factor
        hpxml_bldg.heating_systems[0].heating_autosizing_factor = haf
        hpxml_bldg.cooling_systems[0].cooling_autosizing_factor = caf
        htg_cap = hpxml_bldg.heating_systems[0].heating_capacity
        clg_cap = hpxml_bldg.cooling_systems[0].cooling_capacity
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        assert_operator(hpxml_bldg.heating_systems[0].heating_capacity, :>, htg_cap)
        assert_operator(hpxml_bldg.cooling_systems[0].cooling_capacity, :>, clg_cap)
      end
    end
  end

  def test_autosizing_limits
    clg_autosizing_limits = { true => 1000, false => 100000 }
    htg_autosizing_limits = { true => 1200, false => 120000 }
    for clg_limit, cal in clg_autosizing_limits
      for htg_limit, hal in htg_autosizing_limits
        args_hash = {}
        args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

        bhal = hal + 500.0 # use a similar limit for backup heating sizing

        # Test air conditioner + furnace
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.heating_systems[0].heating_capacity = nil
        hpxml_bldg.cooling_systems[0].cooling_capacity = nil
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        htg_cap_orig = hpxml_bldg.heating_systems[0].heating_capacity
        clg_cap_orig = hpxml_bldg.cooling_systems[0].cooling_capacity
        # apply autosizing limit
        hpxml, hpxml_bldg = _create_hpxml('base.xml')
        hpxml_bldg.heating_systems[0].heating_capacity = nil
        hpxml_bldg.cooling_systems[0].cooling_capacity = nil
        hpxml_bldg.heating_systems[0].heating_autosizing_limit = hal
        hpxml_bldg.cooling_systems[0].cooling_autosizing_limit = cal
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        if htg_limit
          assert_in_epsilon(hpxml_bldg.heating_systems[0].heating_capacity, hal, 0.001)
        else
          assert_in_epsilon(hpxml_bldg.heating_systems[0].heating_capacity, htg_cap_orig, 0.001)
        end
        if clg_limit
          assert_in_epsilon(hpxml_bldg.cooling_systems[0].cooling_capacity, cal, 0.001)
        else
          assert_in_epsilon(hpxml_bldg.cooling_systems[0].cooling_capacity, clg_cap_orig, 0.001)
        end

        # Test heat pump
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].cooling_capacity = nil
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        htg_cap_orig = hpxml_bldg.heat_pumps[0].heating_capacity
        clg_cap_orig = hpxml_bldg.heat_pumps[0].cooling_capacity
        backup_htg_cap_orig = hpxml_bldg.heat_pumps[0].backup_heating_capacity
        # apply autosizing limit
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-1-speed.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].cooling_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_autosizing_limit = hal
        hpxml_bldg.heat_pumps[0].backup_heating_autosizing_limit = bhal
        hpxml_bldg.heat_pumps[0].cooling_autosizing_limit = cal
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        if htg_limit
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, hal, 0.001)
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].backup_heating_capacity, bhal, 0.001)
        else
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap_orig, 0.001)
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].backup_heating_capacity, backup_htg_cap_orig, 0.001)
        end
        if clg_limit
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, cal, 0.001)
        else
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, clg_cap_orig, 0.001)
        end

        # Test heat pump w/ detailed performance
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance-autosize.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        htg_cap_orig = hpxml_bldg.heat_pumps[0].heating_capacity
        clg_cap_orig = hpxml_bldg.heat_pumps[0].cooling_capacity
        backup_htg_cap_orig = hpxml_bldg.heat_pumps[0].backup_heating_capacity
        # apply autosizing limit
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-detailed-performance-autosize.xml')
        hpxml_bldg.heat_pumps[0].backup_heating_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].cooling_capacity = nil
        hpxml_bldg.heat_pumps[0].heating_autosizing_limit = hal
        hpxml_bldg.heat_pumps[0].cooling_autosizing_limit = cal
        hpxml_bldg.heat_pumps[0].backup_heating_autosizing_limit = bhal
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        if htg_limit
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, hal, 0.001)
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].backup_heating_capacity, bhal, 0.001)
        else
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap_orig, 0.001)
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].backup_heating_capacity, backup_htg_cap_orig, 0.001)
        end
        if clg_limit
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, cal, 0.001)
        else
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, clg_cap_orig, 0.001)
        end

        # Test heat pump with separate backup heating
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-furnace.xml')
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].cooling_capacity = nil
        hpxml_bldg.heating_systems[0].heating_capacity = nil
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        htg_cap_orig = hpxml_bldg.heat_pumps[0].heating_capacity
        clg_cap_orig = hpxml_bldg.heat_pumps[0].cooling_capacity
        backup_htg_cap_orig = hpxml_bldg.heating_systems[0].heating_capacity
        # apply autosizing factor
        hpxml, hpxml_bldg = _create_hpxml('base-hvac-air-to-air-heat-pump-var-speed-backup-furnace.xml')
        hpxml_bldg.heat_pumps[0].heating_capacity = nil
        hpxml_bldg.heat_pumps[0].cooling_capacity = nil
        hpxml_bldg.heating_systems[0].heating_capacity = nil
        # use a reverse factor for backup heating sizing
        hpxml_bldg.heat_pumps[0].heating_autosizing_limit = hal
        hpxml_bldg.heat_pumps[0].cooling_autosizing_limit = cal
        hpxml_bldg.heating_systems[0].heating_autosizing_limit = bhal
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        if htg_limit
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, hal, 0.001)
          assert_in_epsilon(hpxml_bldg.heating_systems[0].heating_capacity, bhal, 0.001)
        else
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap_orig, 0.001)
          assert_in_epsilon(hpxml_bldg.heating_systems[0].heating_capacity, backup_htg_cap_orig, 0.001)
        end
        if clg_limit
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, cal, 0.001)
        else
          assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, clg_cap_orig, 0.001)
        end
      end
    end
  end

  def test_manual_j_detailed_sizing_inputs
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

    # Test room by room calculations
    # Run ACCA test file base
    acca_files_path = File.join(@test_files_path, 'ACCA_Examples')
    acca_test_file_name = 'Long_Residence.xml'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(acca_files_path, acca_test_file_name))
    _model, _base_hpxml, base_hpxml_bldg = _test_measure(args_hash)

    # Test window methodology
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml, hpxml_bldg = _create_hpxml(acca_test_file_name, acca_files_path)
    hpxml_bldg.conditioned_spaces.each do |space|
      space.fenestration_load_procedure = HPXML::SpaceFenestrationLoadProcedurePeak
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    test_hpxml_bldg.conditioned_spaces.each do |space|
      base_space = base_hpxml_bldg.conditioned_spaces.find { |s| s.id == space.id }
      assert_operator(space.cdl_sens_windows, :>=, base_space.cdl_sens_windows * 1.3)
      assert_operator(space.cdl_sens_skylights, :>=, base_space.cdl_sens_skylights * 1.3)
      assert_operator(space.cdl_sens_windows + space.cdl_sens_skylights, :>=, base_space.cdl_sens_skylights * 1.3 + base_space.cdl_sens_skylights * 1.3 + base_space.cdl_sens_aedexcursion)
    end

    # Test space internal gain & number of occupants
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml, hpxml_bldg = _create_hpxml(acca_test_file_name, acca_files_path)
    hpxml_bldg.conditioned_spaces.each do |space|
      space.manualj_internal_loads_sensible = 200
      space.manualj_num_occupants = 1
    end
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    test_hpxml_bldg.conditioned_spaces.each do |space|
      assert_equal(200 + 230, space.cdl_sens_intgains)
    end
  end

  def test_manual_j_slab_f_factor
    # Check values against MJ8 Table 5A Construction Number 22 (Concrete Slab on Grade Floor)
    tol = 0.1

    slab = HPXML::Slab.new(nil)
    slab.thickness = 4.0 # in
    slab.perimeter_insulation_depth = 0
    slab.perimeter_insulation_r_value = 0
    slab.under_slab_insulation_width = 0
    slab.under_slab_insulation_spans_entire_slab = false
    slab.under_slab_insulation_r_value = 0

    # 22A — No Edge Insulation, No insulation Below Floor, any Floor Cover
    assert_in_delta(1.358, HVACSizing.calc_slab_f_value(slab, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(1.180, HVACSizing.calc_slab_f_value(slab, 1.0 / 2.0), tol) # Heavy dry or light moist soil, R-value/ft=2.0
    assert_in_delta(0.989, HVACSizing.calc_slab_f_value(slab, 1.0 / 5.0), tol) # Light dry soil, R-value/ft=5.0

    # 22B — Vertical Board Insulation Covers Slab Edge and Extends Straight Down to Three Feet Below Grade, any Floor Cover
    slab.perimeter_insulation_depth = 3
    slab.perimeter_insulation_r_value = 5
    assert_in_delta(0.589, HVACSizing.calc_slab_f_value(slab, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.449, HVACSizing.calc_slab_f_value(slab, 1.0 / 2.0), tol) # Heavy dry or light moist soil, R-value/ft=2.0
    assert_in_delta(0.289, HVACSizing.calc_slab_f_value(slab, 1.0 / 5.0), tol) # Light dry soil, R-value/ft=5.0

    slab.perimeter_insulation_r_value = 10
    assert_in_delta(0.481, HVACSizing.calc_slab_f_value(slab, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.355, HVACSizing.calc_slab_f_value(slab, 1.0 / 2.0), tol) # Heavy dry or light moist soil, R-value/ft=2.0
    assert_in_delta(0.210, HVACSizing.calc_slab_f_value(slab, 1.0 / 5.0), tol) # Light dry soil, R-value/ft=5.0

    slab.perimeter_insulation_r_value = 15
    assert_in_delta(0.432, HVACSizing.calc_slab_f_value(slab, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.314, HVACSizing.calc_slab_f_value(slab, 1.0 / 2.0), tol) # Heavy dry or light moist soil, R-value/ft=2.0
    assert_in_delta(0.178, HVACSizing.calc_slab_f_value(slab, 1.0 / 5.0), tol) # Light dry soil, R-value/ft=5.0

    # 22C — Horizontal Board Insulation Extends Four Feet Under Slab, any Floor Cover
    slab.perimeter_insulation_depth = 0
    slab.perimeter_insulation_r_value = 0
    slab.under_slab_insulation_width = 4
    slab.under_slab_insulation_r_value = 5
    assert_in_delta(1.266, HVACSizing.calc_slab_f_value(slab, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(1.135, HVACSizing.calc_slab_f_value(slab, 1.0 / 2.0), tol) # Heavy dry or light moist soil, R-value/ft=2.0
    assert_in_delta(0.980, HVACSizing.calc_slab_f_value(slab, 1.0 / 5.0), tol) # Light dry soil, R-value/ft=5.0

    slab.under_slab_insulation_r_value = 10
    assert_in_delta(1.221, HVACSizing.calc_slab_f_value(slab, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(1.108, HVACSizing.calc_slab_f_value(slab, 1.0 / 2.0), tol) # Heavy dry or light moist soil, R-value/ft=2.0
    assert_in_delta(0.937, HVACSizing.calc_slab_f_value(slab, 1.0 / 5.0), tol) # Light dry soil, R-value/ft=5.0

    slab.under_slab_insulation_r_value = 15
    assert_in_delta(1.194, HVACSizing.calc_slab_f_value(slab, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(1.091, HVACSizing.calc_slab_f_value(slab, 1.0 / 2.0), tol) # Heavy dry or light moist soil, R-value/ft=2.0
    assert_in_delta(0.967, HVACSizing.calc_slab_f_value(slab, 1.0 / 5.0), tol) # Light dry soil, R-value/ft=5.0

    # 22D — Vertical Board Insulation Covers Slab Edge, Turns Under the Slab and Extends Four Feet Horizontally, any Floor Cover
    slab.under_slab_insulation_width = 4
    slab.under_slab_insulation_r_value = 5
    slab.perimeter_insulation_depth = 0.333 # 4" slab
    slab.perimeter_insulation_r_value = 5
    assert_in_delta(0.574, HVACSizing.calc_slab_f_value(slab, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.442, HVACSizing.calc_slab_f_value(slab, 1.0 / 2.0), tol) # Heavy dry or light moist soil, R-value/ft=2.0
    assert_in_delta(0.287, HVACSizing.calc_slab_f_value(slab, 1.0 / 5.0), tol) # Light dry soil, R-value/ft=5.0

    slab.under_slab_insulation_r_value = 10
    slab.perimeter_insulation_r_value = 10
    assert_in_delta(0.456, HVACSizing.calc_slab_f_value(slab, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.343, HVACSizing.calc_slab_f_value(slab, 1.0 / 2.0), tol) # Heavy dry or light moist soil, R-value/ft=2.0
    assert_in_delta(0.208, HVACSizing.calc_slab_f_value(slab, 1.0 / 5.0), tol) # Light dry soil, R-value/ft=5.0

    slab.under_slab_insulation_r_value = 15
    slab.perimeter_insulation_r_value = 15
    assert_in_delta(0.401, HVACSizing.calc_slab_f_value(slab, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.298, HVACSizing.calc_slab_f_value(slab, 1.0 / 2.0), tol) # Heavy dry or light moist soil, R-value/ft=2.0
    assert_in_delta(0.174, HVACSizing.calc_slab_f_value(slab, 1.0 / 5.0), tol) # Light dry soil, R-value/ft=5.0
  end

  def test_manual_j_basement_effective_uvalue
    # Check values against MJ8 Table 4A Construction Number 21 (Basement Floor)
    tol = 0.002

    # 21A — No Insulation Below Floor, Any Floor Cover
    assert_in_delta(0.027, HVACSizing.calc_basement_effective_uvalue(false, 8.0, 20.0, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.025, HVACSizing.calc_basement_effective_uvalue(false, 8.0, 24.0, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.022, HVACSizing.calc_basement_effective_uvalue(false, 8.0, 28.0, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.020, HVACSizing.calc_basement_effective_uvalue(false, 8.0, 32.0, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25

    # 21B — Insulation Installed Below Floor, Any Floor Cover
    assert_in_delta(0.019, HVACSizing.calc_basement_effective_uvalue(true, 8.0, 20.0, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.017, HVACSizing.calc_basement_effective_uvalue(true, 8.0, 24.0, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.015, HVACSizing.calc_basement_effective_uvalue(true, 8.0, 28.0, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
    assert_in_delta(0.014, HVACSizing.calc_basement_effective_uvalue(true, 8.0, 32.0, 1.0 / 1.25), tol) # Heavy moist soil, R-value/ft=1.25
  end

  def test_multiple_zones
    # Run base-zones-spaces-multiple.xml
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-zones-spaces-multiple.xml'))
    _model_mult, _base_hpxml, hpxml_bldg_mult = _test_measure(args_hash)

    # Check above-grade zone loads are much greater than below-grade zone loads
    assert_operator(hpxml_bldg_mult.conditioned_zones[0].hdl_total, :>, 1.5 * hpxml_bldg_mult.conditioned_zones[1].hdl_total)
    assert_operator(hpxml_bldg_mult.conditioned_zones[0].cdl_sens_total, :>, 1.5 * hpxml_bldg_mult.conditioned_zones[1].cdl_sens_total)

    # Check space and zone values are equal
    (HPXML::HDL_ATTRS.keys + HPXML::CDL_SENS_ATTRS.keys).each do |key|
      assert_equal(hpxml_bldg_mult.conditioned_zones[0].send(key), hpxml_bldg_mult.conditioned_spaces[0].send(key))
      assert_equal(hpxml_bldg_mult.conditioned_zones[1].send(key), hpxml_bldg_mult.conditioned_spaces[1].send(key))
    end

    # Run base-zones-spaces.xml
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@sample_files_path, 'base-zones-spaces.xml'))
    _model, _base_hpxml, hpxml_bldg = _test_measure(args_hash)

    # Check results between base-zones-spaces.xml and base-zones-spaces-multiple.xml
    (HPXML::HDL_ATTRS.keys + HPXML::CDL_SENS_ATTRS.keys + HPXML::CDL_LAT_ATTRS.keys).each do |key|
      if key == :cdl_sens_aed_curve
        # Check for identical arrays
        assert_equal(hpxml_bldg.hvac_plant.send(key).split(',').map(&:to_f), hpxml_bldg_mult.hvac_plant.send(key).split(',').map(&:to_f))
        assert_equal(hpxml_bldg.conditioned_zones[0].send(key).split(',').map(&:to_f), hpxml_bldg_mult.conditioned_zones[0].send(key).split(',').map(&:to_f).zip(hpxml_bldg_mult.conditioned_zones[1].send(key).split(',').map(&:to_f)).map { |a, b| a + b })
        assert_equal(hpxml_bldg.conditioned_spaces[0].send(key).split(',').map(&:to_f), hpxml_bldg_mult.conditioned_spaces[0].send(key).split(',').map(&:to_f).zip(hpxml_bldg_mult.conditioned_spaces[1].send(key).split(',').map(&:to_f)).map { |a, b| a + b })
      else
        if key.to_s.include?('ducts') || key.to_s.include?('total')
          # Check values are similar (ducts, and thus totals, will not be exactly identical)
          tol_btuh = 500
        else
          # Check values are identical (aside from rounding)
          tol_btuh = 1
        end
        assert_in_delta(hpxml_bldg.hvac_plant.send(key), hpxml_bldg_mult.hvac_plant.send(key), tol_btuh)
        assert_in_delta(hpxml_bldg.conditioned_zones[0].send(key), hpxml_bldg_mult.conditioned_zones[0].send(key) + hpxml_bldg_mult.conditioned_zones[1].send(key), tol_btuh)
        if not HPXML::CDL_LAT_ATTRS.keys.include?(key) # Latent loads are not calculated for spaces
          assert_in_delta(hpxml_bldg.conditioned_spaces[0].send(key), hpxml_bldg_mult.conditioned_spaces[0].send(key) + hpxml_bldg_mult.conditioned_spaces[1].send(key), tol_btuh)
        end
      end
    end
  end

  def test_gshp_ground_loop
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

    # Base case
    hpxml, _hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump.xml')
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    assert_equal(3, test_hpxml_bldg.geothermal_loops[0].num_bore_holes)
    assert_in_epsilon(558.0 / 3, test_hpxml_bldg.geothermal_loops[0].bore_length, 0.01)

    # Bore depth greater than the max -> increase number of boreholes
    hpxml, hpxml_bldg = _create_hpxml('base-hvac-ground-to-air-heat-pump.xml')
    hpxml_bldg.site.ground_conductivity = 0.18
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _test_hpxml, test_hpxml_bldg = _test_measure(args_hash)
    assert_equal(5, test_hpxml_bldg.geothermal_loops[0].num_bore_holes)
    assert_in_epsilon(2120.0 / 5, test_hpxml_bldg.geothermal_loops[0].bore_length, 0.01)

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
    assert_in_epsilon(2340.0 / 10, test_hpxml_bldg.geothermal_loops[0].bore_length, 0.01)
  end

  def test_gshp_g_function_library_linear_interpolation_example
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

  def test_gshp_all_g_function_configs_exist
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

  def _create_hpxml(hpxml_name, file_path = nil)
    path = file_path.nil? ? @sample_files_path : file_path
    hpxml = HPXML.new(hpxml_path: File.join(path, hpxml_name))
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
