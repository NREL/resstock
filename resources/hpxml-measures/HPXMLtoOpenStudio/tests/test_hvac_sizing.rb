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
          max_htg_cfm = hp.max_heating_airflow_cfm
          max_clg_cfm = hp.max_cooling_airflow_cfm
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
                if max_htg_cfm.nil? && max_clg_cfm.nil?
                  assert_in_delta(htg_cap, [htg_load, clg_load].max, 1.0)
                  assert_in_delta(clg_cap, [htg_load, clg_load].max, 1.0)
                else
                  # Check HP capacity is less than max(htg_load, clg_load)
                  assert_operator(htg_cap, :<, [htg_load, clg_load].max, 1.0)
                  assert_operator(clg_cap, :<, [htg_load, clg_load].max, 1.0)
                end
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

  def test_manual_j_block_load_residences
    default_tol_btuh = 500

    # Section 7: Vatilo Residence
    # Expected values from Figure 7-4
    puts 'Testing Vatilo Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Vatilo_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(9147, hpxml_bldg.hvac_plant.hdl_ducts, 1500)
    assert_in_delta(4234, hpxml_bldg.hvac_plant.hdl_windows, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_skylights, default_tol_btuh)
    assert_in_delta(574, hpxml_bldg.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(2874, hpxml_bldg.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(7415, hpxml_bldg.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(1498, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(3089, hpxml_bldg.hvac_plant.hdl_infilvent, default_tol_btuh)
    assert_in_delta(9973, hpxml_bldg.hvac_plant.cdl_sens_ducts, 2000)
    assert_in_delta(6260, hpxml_bldg.hvac_plant.cdl_sens_windows, default_tol_btuh) # AE worksheet, so assumes AED; added AED=965 Btuh to their value since we actually calculate it
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_skylights, default_tol_btuh)
    assert_in_delta(456, hpxml_bldg.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(1715, hpxml_bldg.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(2112, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(769, hpxml_bldg.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(1890, hpxml_bldg.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(2488, hpxml_bldg.hvac_plant.cdl_lat_ducts, 1500)
    assert_in_delta(1276, hpxml_bldg.hvac_plant.cdl_lat_infilvent, default_tol_btuh)
    assert_in_delta(600, hpxml_bldg.hvac_plant.cdl_lat_intgains, default_tol_btuh)

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
    assert_in_delta(3449, hpxml_bldg.hvac_plant.cdl_sens_ducts, default_tol_btuh)
    assert_in_delta(563, hpxml_bldg.hvac_plant.cdl_lat_ducts, default_tol_btuh)

    # Section 8: Victor Residence
    # Expected values from Figure 8-3
    puts 'Testing Victor Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Victor_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(29137, hpxml_bldg.hvac_plant.hdl_ducts, 3000)
    assert_in_delta(9978, hpxml_bldg.hvac_plant.hdl_windows, default_tol_btuh)
    assert_in_delta(471, hpxml_bldg.hvac_plant.hdl_skylights, default_tol_btuh)
    assert_in_delta(984, hpxml_bldg.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(6305, hpxml_bldg.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(7069, hpxml_bldg.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(6044, hpxml_bldg.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(21426, hpxml_bldg.hvac_plant.hdl_infilvent, 1000)
    assert_in_delta(5602, hpxml_bldg.hvac_plant.cdl_sens_ducts, 3500)
    assert_in_delta(4706, hpxml_bldg.hvac_plant.cdl_sens_windows, default_tol_btuh)
    assert_in_delta(1409, hpxml_bldg.hvac_plant.cdl_sens_skylights, default_tol_btuh)
    assert_in_delta(382, hpxml_bldg.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(1130, hpxml_bldg.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(2743, hpxml_bldg.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(1393, hpxml_bldg.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(2504, hpxml_bldg.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(3320, hpxml_bldg.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(6282, hpxml_bldg.hvac_plant.cdl_lat_ducts, 4500)
    assert_in_delta(4644, hpxml_bldg.hvac_plant.cdl_lat_infilvent, 1000)
    assert_in_delta(800, hpxml_bldg.hvac_plant.cdl_lat_intgains, default_tol_btuh)

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
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_ducts, default_tol_btuh)
    assert_in_delta(8315, hpxml_bldg.hvac_plant.hdl_windows, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_skylights, default_tol_btuh)
    assert_in_delta(1006, hpxml_bldg.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(16608, hpxml_bldg.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(2440, hpxml_bldg.hvac_plant.hdl_slabs, 1000)
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

    # Section 12: Smith Residence
    # Expected values from Form J1
    puts 'Testing Smith Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Smith_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(2561, hpxml_bldg.hvac_plant.hdl_ducts, 2000)
    assert_in_delta(9634, hpxml_bldg.hvac_plant.hdl_windows, default_tol_btuh)
    # assert_in_delta(2994, hpxml_bldg.hvac_plant.hdl_skylights, default_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(1118, hpxml_bldg.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(17440, hpxml_bldg.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(1788, hpxml_bldg.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(3692, hpxml_bldg.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(4261, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(13224, hpxml_bldg.hvac_plant.hdl_infilvent, 1000)
    assert_in_delta(530, hpxml_bldg.hvac_plant.cdl_sens_ducts, default_tol_btuh)
    assert_in_delta(6187, hpxml_bldg.hvac_plant.cdl_sens_windows, default_tol_btuh)
    # assert_in_delta(3780, hpxml_bldg.hvac_plant.cdl_sens_skylights, default_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(382, hpxml_bldg.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(2669, hpxml_bldg.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(352, hpxml_bldg.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(2803, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(1513, hpxml_bldg.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(3320, hpxml_bldg.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(565, hpxml_bldg.hvac_plant.cdl_lat_ducts, 1500)
    assert_in_delta(3406, hpxml_bldg.hvac_plant.cdl_lat_infilvent, 1000)
    assert_in_delta(800, hpxml_bldg.hvac_plant.cdl_lat_intgains, default_tol_btuh)

    # Section 13: Walker Residence
    # Expected values from Form J1 (Note: it shows Ceiling Option 3 for some reason)
    puts 'Testing Walker Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Walker_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_ducts, default_tol_btuh)
    assert_in_delta(1608, hpxml_bldg.hvac_plant.hdl_windows, default_tol_btuh)
    # assert_in_delta(543, hpxml_bldg.hvac_plant.hdl_skylights, default_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(264, hpxml_bldg.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(1446, hpxml_bldg.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(2172, hpxml_bldg.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(820, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(1446, hpxml_bldg.hvac_plant.hdl_infilvent, default_tol_btuh)
    assert_in_delta(851, hpxml_bldg.hvac_plant.cdl_sens_ducts, 2500)
    assert_in_delta(1776, hpxml_bldg.hvac_plant.cdl_sens_windows, default_tol_btuh)
    # assert_in_delta(3182, hpxml_bldg.hvac_plant.cdl_sens_skylights, default_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(442, hpxml_bldg.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(1173, hpxml_bldg.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(865, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    # assert_in_delta(825, hpxml_bldg.hvac_plant.cdl_sens_infilvent, default_tol_btuh) Skip due to dehumidifying ventilation
    assert_in_delta(5541, hpxml_bldg.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(655, hpxml_bldg.hvac_plant.cdl_lat_ducts, default_tol_btuh)
    # assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_lat_infilvent, default_tol_btuh) Skip due to dehumidifying ventilation
    assert_in_delta(800, hpxml_bldg.hvac_plant.cdl_lat_intgains, default_tol_btuh)

    # Section 13: Walker Residence - Ceiling Option 1
    puts 'Testing Walker Residence - Ceiling Option 1...'
    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])
    hpxml.buildings[0].roofs[0].roof_type = HPXML::RoofTypeAsphaltShingles
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(820, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(2003, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)

    # Section 13: Walker Residence - Ceiling Option 2
    puts 'Testing Walker Residence - Ceiling Option 2...'
    hpxml = HPXML.new(hpxml_path: args_hash['hpxml_path'])
    hpxml.buildings[0].roofs[0].roof_type = HPXML::RoofTypeAsphaltShingles
    hpxml.buildings[0].roofs[0].radiant_barrier = true
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    args_hash['hpxml_path'] = @tmp_hpxml_path
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(820, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(1548, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)

    # Section 14: Cobb Residence
    # Expected values from Form J1
    puts 'Testing Cobb Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Cobb_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    # assert_in_delta(499, hpxml_bldg.hvac_plant.hdl_ducts, default_tol_btuh) Skip due to ducts in closed ceiling cavity
    assert_in_delta(3015, hpxml_bldg.hvac_plant.hdl_windows, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_skylights, default_tol_btuh)
    assert_in_delta(169, hpxml_bldg.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(1975, hpxml_bldg.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(1770, hpxml_bldg.hvac_plant.hdl_infilvent, default_tol_btuh)
    # assert_in_delta(1631, hpxml_bldg.hvac_plant.cdl_sens_ducts, default_tol_btuh) Skip due to ducts in closed ceiling cavity
    assert_in_delta(13170, hpxml_bldg.hvac_plant.cdl_sens_windows, default_tol_btuh) # Includes 5516 Btuh for AED excursion
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_skylights, default_tol_btuh)
    assert_in_delta(228, hpxml_bldg.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(1236, hpxml_bldg.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(764, hpxml_bldg.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(5224, hpxml_bldg.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    # assert_in_delta(1189, hpxml_bldg.hvac_plant.cdl_lat_ducts, default_tol_btuh) Skip due to ducts in closed ceiling cavity
    assert_in_delta(1391, hpxml_bldg.hvac_plant.cdl_lat_infilvent, default_tol_btuh)
    assert_in_delta(800, hpxml_bldg.hvac_plant.cdl_lat_intgains, default_tol_btuh)

    # Section 15: Bell Residence
    # Expected values from Form J1
    puts 'Testing Bell Residence...'
    args_hash = {}
    args_hash['hpxml_path'] = File.absolute_path(File.join(@test_files_path, 'ACCA_Examples', 'Bell_Residence.xml'))
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_delta(1340, hpxml_bldg.hvac_plant.hdl_ducts, 2000)
    assert_in_delta(10912, hpxml_bldg.hvac_plant.hdl_windows, default_tol_btuh)
    # assert_in_delta(1981, hpxml_bldg.hvac_plant.hdl_skylights, default_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(1538, hpxml_bldg.hvac_plant.hdl_doors, default_tol_btuh)
    assert_in_delta(3672, hpxml_bldg.hvac_plant.hdl_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.hdl_floors, default_tol_btuh)
    assert_in_delta(3431, hpxml_bldg.hvac_plant.hdl_slabs, default_tol_btuh)
    assert_in_delta(1992, hpxml_bldg.hvac_plant.hdl_ceilings, default_tol_btuh)
    assert_in_delta(3322, hpxml_bldg.hvac_plant.hdl_infilvent, default_tol_btuh)
    assert_in_delta(1673, hpxml_bldg.hvac_plant.cdl_sens_ducts, default_tol_btuh)
    assert_in_delta(11654, hpxml_bldg.hvac_plant.cdl_sens_windows, default_tol_btuh) # Excludes 2045 Btuh for AED excursion since skylight is not modeled
    # assert_in_delta(5514, hpxml_bldg.hvac_plant.cdl_sens_skylights, default_tol_btuh) Skip due to not being able to model skylights w/ shafts
    assert_in_delta(782, hpxml_bldg.hvac_plant.cdl_sens_doors, default_tol_btuh)
    assert_in_delta(939, hpxml_bldg.hvac_plant.cdl_sens_walls, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_roofs, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_floors, default_tol_btuh)
    assert_in_delta(0, hpxml_bldg.hvac_plant.cdl_sens_slabs, default_tol_btuh)
    assert_in_delta(1796, hpxml_bldg.hvac_plant.cdl_sens_ceilings, default_tol_btuh)
    assert_in_delta(810, hpxml_bldg.hvac_plant.cdl_sens_infilvent, default_tol_btuh)
    assert_in_delta(4541, hpxml_bldg.hvac_plant.cdl_sens_intgains, default_tol_btuh)
    assert_in_delta(64, hpxml_bldg.hvac_plant.cdl_lat_ducts, default_tol_btuh)
    assert_in_delta(570, hpxml_bldg.hvac_plant.cdl_lat_infilvent, default_tol_btuh)
    assert_in_delta(1000, hpxml_bldg.hvac_plant.cdl_lat_intgains, default_tol_btuh)
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

  def test_autosizing_factors
    clg_autosizing_factors = [0.8, 1.2]
    htg_autosizing_factors = [0.9, 1.7]
    for caf in clg_autosizing_factors
      for haf in htg_autosizing_factors
        args_hash = {}
        args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)

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
        # use a reverse factor for backup heating sizing
        hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = (2.0 - haf)
        hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = caf
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap_orig * haf, 0.001)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].backup_heating_capacity, backup_htg_cap_orig * (2.0 - haf), 0.001)
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
        # use a reverse factor for backup heating sizing
        hpxml_bldg.heat_pumps[0].backup_heating_autosizing_factor = (2.0 - haf)
        XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
        _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap_orig * haf, 0.001)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].backup_heating_capacity, backup_htg_cap_orig * (2.0 - haf), 0.001)
        assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, clg_cap_orig * caf, 0.001)

        # Test allow fixed capacity
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

    # Test heat pump with separate back up heating
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
    hpxml_bldg.heat_pumps[0].heating_autosizing_factor = 0.8
    hpxml_bldg.heat_pumps[0].cooling_autosizing_factor = 1.5
    hpxml_bldg.heating_systems[0].heating_autosizing_factor = 1.2
    XMLHelper.write_file(hpxml.to_doc, @tmp_hpxml_path)
    _model, _hpxml, hpxml_bldg = _test_measure(args_hash)
    assert_in_epsilon(hpxml_bldg.heat_pumps[0].heating_capacity, htg_cap_orig * 0.8, 0.001)
    assert_in_epsilon(hpxml_bldg.heating_systems[0].heating_capacity, backup_htg_cap_orig * 1.2, 0.001)
    assert_in_epsilon(hpxml_bldg.heat_pumps[0].cooling_capacity, clg_cap_orig * 1.5, 0.001)
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
