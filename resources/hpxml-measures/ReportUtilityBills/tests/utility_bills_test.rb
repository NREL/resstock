# frozen_string_literal: true

require 'oga'
require_relative '../../HPXMLtoOpenStudio/resources/utility_bills'
require_relative '../../HPXMLtoOpenStudio/resources/constants'
require_relative '../../HPXMLtoOpenStudio/resources/energyplus'
require_relative '../../HPXMLtoOpenStudio/resources/hpxml'
require_relative '../../HPXMLtoOpenStudio/resources/hpxml_defaults'
require_relative '../../HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../HPXMLtoOpenStudio/resources/schedules'
require_relative '../../HPXMLtoOpenStudio/resources/unit_conversions'
require_relative '../../HPXMLtoOpenStudio/resources/xmlhelper'
require_relative '../resources/util.rb'
require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require_relative '../measure.rb'
require 'csv'

class ReportUtilityBillsTest < MiniTest::Test
  # BEopt 2.8.0.0:
  # - Standard, New Construction, Single-Family Detached
  # - 600 sq ft (30 x 20)
  # - EPW Location: USA_CO_Denver.Intl.AP.725650_TMY3.epw
  # - Cooking Range: Propane
  # - Water Heater: Oil Standard
  # - PV System: None, 1.0 kW, 10.0 kW
  # - Timestep: 10 min
  # - User-Specified rates (calculated using default value):
  #   - Electricity: 0.1195179675994109 $/kWh
  #   - Natural Gas: 0.7468734851091381 $/therm
  #   - Fuel Oil: 3.495346153846154 $/gal
  #   - Propane: 2.4532692307692305 $/gal
  # - All other options left at default values
  # Then retrieve 1.csv from output folder, copy it, rename it

  def setup
    @args_hash = {}

    # From BEopt Output screen (Utility Bills $/yr)
    @expected_bills = {
      'Test: Total (USD)' => 1514,
      'Test: Electricity: Fixed (USD)' => 96,
      'Test: Electricity: Marginal (USD)' => 629,
      'Test: Electricity: Total (USD)' => 725,
      'Test: Natural Gas: Fixed (USD)' => 96,
      'Test: Natural Gas: Marginal (USD)' => 154,
      'Test: Natural Gas: Total (USD)' => 250,
      'Test: Fuel Oil: Marginal (USD)' => 462,
      'Test: Fuel Oil: Total (USD)' => 462,
      'Test: Propane: Marginal (USD)' => 76,
      'Test: Propane: Total (USD)' => 76
    }

    @measure = ReportUtilityBills.new
    @hpxml = HPXML.new(hpxml_path: File.join(File.dirname(__FILE__), '../../workflow/sample_files/base-pv.xml'))
    @hpxml.header.utility_bill_scenarios.clear
    @hpxml.header.utility_bill_scenarios.add(name: 'Test',
                                             elec_fixed_charge: 8.0,
                                             natural_gas_fixed_charge: 8.0,
                                             propane_marginal_rate: 2.4532692307692305,
                                             fuel_oil_marginal_rate: 3.495346153846154)

    HPXMLDefaults.apply_header(@hpxml, nil)
    HPXMLDefaults.apply_utility_bill_scenarios(nil, @hpxml)

    @root_path = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..'))
    @sample_files_path = File.join(@root_path, 'workflow', 'sample_files')
    @tmp_hpxml_path = File.join(@sample_files_path, 'tmp.xml')
    @bills_csv = File.join(File.dirname(__FILE__), 'results_bills.csv')
  end

  def teardown
    File.delete(@tmp_hpxml_path) if File.exist? @tmp_hpxml_path
    File.delete(@bills_csv) if File.exist? @bills_csv
  end

  def test_simple_calculations_pv_none
    fuels = _load_timeseries(fuels, '../tests/PV_None.csv')
    @hpxml.header.utility_bill_scenarios.each do |utility_bill_scenario|
      utility_rates, utility_bills = @measure.setup_utility_outputs()
      actual_bills = _bill_calcs(fuels, utility_rates, utility_bills, @hpxml.header, [], utility_bill_scenario)
      _check_bills(@expected_bills, actual_bills)
    end
  end

  def test_simple_calculations_pv_1kW_net_metering_user_specified_excess_rate
    fuels = _load_timeseries(fuels, '../tests/PV_1kW.csv')
    @hpxml.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml.pv_systems.size }
    @hpxml.header.utility_bill_scenarios.each do |utility_bill_scenario|
      utility_rates, utility_bills = @measure.setup_utility_outputs()
      actual_bills = _bill_calcs(fuels, utility_rates, utility_bills, @hpxml.header, @hpxml.pv_systems, utility_bill_scenario)
      @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
      @expected_bills['Test: Electricity: Total (USD)'] = 548
      @expected_bills['Test: Total (USD)'] = 1337
      _check_bills(@expected_bills, actual_bills)
    end
  end

  def test_simple_calculations_pv_10kW_net_metering_user_specified_excess_rate
    fuels = _load_timeseries(fuels, '../tests/PV_10kW.csv')
    @hpxml.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml.pv_systems.size }
    @hpxml.header.utility_bill_scenarios.each do |utility_bill_scenario|
      utility_rates, utility_bills = @measure.setup_utility_outputs()
      actual_bills = _bill_calcs(fuels, utility_rates, utility_bills, @hpxml.header, @hpxml.pv_systems, utility_bill_scenario)
      @expected_bills['Test: Electricity: PV Credit (USD)'] = -918
      @expected_bills['Test: Electricity: Total (USD)'] = -193
      @expected_bills['Test: Total (USD)'] = 596
      _check_bills(@expected_bills, actual_bills)
    end
  end

  def test_simple_calculations_pv_10kW_net_metering_retail_excess_rate
    @hpxml.header.utility_bill_scenarios[-1].pv_net_metering_annual_excess_sellback_rate_type = HPXML::PVAnnualExcessSellbackRateTypeRetailElectricityCost
    fuels = _load_timeseries(fuels, '../tests/PV_10kW.csv')
    @hpxml.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml.pv_systems.size }
    @hpxml.header.utility_bill_scenarios.each do |utility_bill_scenario|
      utility_rates, utility_bills = @measure.setup_utility_outputs()
      actual_bills = _bill_calcs(fuels, utility_rates, utility_bills, @hpxml.header, @hpxml.pv_systems, utility_bill_scenario)
      @expected_bills['Test: Electricity: PV Credit (USD)'] = -1779
      @expected_bills['Test: Electricity: Total (USD)'] = -1054
      @expected_bills['Test: Total (USD)'] = -265
      _check_bills(@expected_bills, actual_bills)
    end
  end

  def test_simple_calculations_pv_1kW_feed_in_tariff
    @hpxml.header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml.header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    fuels = _load_timeseries(fuels, '../tests/PV_1kW.csv')
    @hpxml.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml.pv_systems.size }
    @hpxml.header.utility_bill_scenarios.each do |utility_bill_scenario|
      utility_rates, utility_bills = @measure.setup_utility_outputs()
      actual_bills = _bill_calcs(fuels, utility_rates, utility_bills, @hpxml.header, @hpxml.pv_systems, utility_bill_scenario)
      @expected_bills['Test: Electricity: PV Credit (USD)'] = -178
      @expected_bills['Test: Electricity: Total (USD)'] = 547
      @expected_bills['Test: Total (USD)'] = 1336
      _check_bills(@expected_bills, actual_bills)
    end
  end

  def test_simple_calculations_pv_10kW_feed_in_tariff
    @hpxml.header.utility_bill_scenarios[-1].pv_compensation_type = HPXML::PVCompensationTypeFeedInTariff
    @hpxml.header.utility_bill_scenarios[-1].pv_feed_in_tariff_rate = 0.12
    fuels = _load_timeseries(fuels, '../tests/PV_10kW.csv')
    @hpxml.pv_systems.each { |pv_system| pv_system.max_power_output = 10000.0 / @hpxml.pv_systems.size }
    @hpxml.header.utility_bill_scenarios.each do |utility_bill_scenario|
      utility_rates, utility_bills = @measure.setup_utility_outputs()
      actual_bills = _bill_calcs(fuels, utility_rates, utility_bills, @hpxml.header, @hpxml.pv_systems, utility_bill_scenario)
      @expected_bills['Test: Electricity: PV Credit (USD)'] = -1787
      @expected_bills['Test: Electricity: Total (USD)'] = -1061
      @expected_bills['Test: Total (USD)'] = -272
      _check_bills(@expected_bills, actual_bills)
    end
  end

  def test_simple_calculations_pv_1kW_grid_fee_dollars_per_kW
    @hpxml.header.utility_bill_scenarios[-1].pv_monthly_grid_connection_fee_dollars_per_kw = 2.50
    fuels = _load_timeseries(fuels, '../tests/PV_1kW.csv')
    @hpxml.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml.pv_systems.size }
    @hpxml.header.utility_bill_scenarios.each do |utility_bill_scenario|
      utility_rates, utility_bills = @measure.setup_utility_outputs()
      actual_bills = _bill_calcs(fuels, utility_rates, utility_bills, @hpxml.header, @hpxml.pv_systems, utility_bill_scenario)
      @expected_bills['Test: Electricity: Fixed (USD)'] = 126
      @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
      @expected_bills['Test: Electricity: Total (USD)'] = 578
      @expected_bills['Test: Total (USD)'] = 1367
      _check_bills(@expected_bills, actual_bills)
    end
  end

  def test_simple_calculations_pv_1kW_grid_fee_dollars
    @hpxml.header.utility_bill_scenarios[-1].pv_monthly_grid_connection_fee_dollars = 7.50
    fuels = _load_timeseries(fuels, '../tests/PV_1kW.csv')
    @hpxml.pv_systems.each { |pv_system| pv_system.max_power_output = 1000.0 / @hpxml.pv_systems.size }
    @hpxml.header.utility_bill_scenarios.each do |utility_bill_scenario|
      utility_rates, utility_bills = @measure.setup_utility_outputs()
      actual_bills = _bill_calcs(fuels, utility_rates, utility_bills, @hpxml.header, @hpxml.pv_systems, utility_bill_scenario)
      @expected_bills['Test: Electricity: Fixed (USD)'] = 186
      @expected_bills['Test: Electricity: PV Credit (USD)'] = -177
      @expected_bills['Test: Electricity: Total (USD)'] = 638
      @expected_bills['Test: Total (USD)'] = 1427
      _check_bills(@expected_bills, actual_bills)
    end
  end

  def test_workflow_wood_cord
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-furnace-wood-only.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', wood_marginal_rate: 0.015)
    hpxml.header.utility_bill_scenarios.add(name: 'Test 2', wood_marginal_rate: 0.03)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    actual_bills = _test_measure()
    expected_val = actual_bills['Test 1: Wood Cord: Total (USD)']
    assert_in_delta(expected_val * 2, actual_bills['Test 2: Wood Cord: Total (USD)'], 1)
  end

  def test_workflow_wood_pellets
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-stove-wood-pellets-only.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', wood_pellets_marginal_rate: 0.02)
    hpxml.header.utility_bill_scenarios.add(name: 'Test 2', wood_pellets_marginal_rate: 0.01)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    actual_bills = _test_measure()
    expected_val = actual_bills['Test 1: Wood Pellets: Total (USD)']
    assert_in_delta(expected_val / 2, actual_bills['Test 2: Wood Pellets: Total (USD)'], 1)
  end

  def test_workflow_coal
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-furnace-coal-only.xml'))
    hpxml.header.utility_bill_scenarios.add(name: 'Test 1', coal_marginal_rate: 0.05)
    hpxml.header.utility_bill_scenarios.add(name: 'Test 2', coal_marginal_rate: 0.1)
    hpxml.header.utility_bill_scenarios.add(name: 'Test 3', coal_marginal_rate: 0.025)
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    actual_bills = _test_measure()
    expected_val = actual_bills['Test 1: Coal: Total (USD)']
    assert_in_delta(expected_val * 2, actual_bills['Test 2: Coal: Total (USD)'], 1)
    assert_in_delta(expected_val / 2, actual_bills['Test 3: Coal: Total (USD)'], 1)
  end

  def test_workflow_leap_year
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-location-AMY-2012.xml'))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    actual_bills = _test_measure()
    assert_operator(actual_bills['Bills: Total (USD)'], :>, 0)
  end

  def test_workflow_semi_annual_run_period
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-simcontrol-runperiod-1-month.xml'))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    actual_bills = _test_measure()
    assert_operator(actual_bills['Bills: Total (USD)'], :>, 0)
  end

  def test_workflow_no_bill_scenarios
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-misc-bills-none.xml'))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    actual_bills = _test_measure(hpxml: hpxml)
    assert_nil(actual_bills)
  end

  def test_auto_marginal_rate
    fuel_types = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas, HPXML::FuelTypeOil, HPXML::FuelTypePropane]

    # Check that we can successfully look up "auto" rates for every state
    # and every fuel type.
    Constants.StateCodesMap.keys.each do |state_code|
      fuel_types.each do |fuel_type|
        flatratebuy, _ = UtilityBills.get_rates_from_eia_data(nil, state_code, fuel_type, 0)
        refute_nil(flatratebuy)
      end
    end

    # Check that we can successfully look up "auto" rates for the US too.
    fuel_types.each do |fuel_type|
      flatratebuy, _ = UtilityBills.get_rates_from_eia_data(nil, 'US', fuel_type, 0)
      refute_nil(flatratebuy)
    end

    # Check that any other state code is gracefully handled (no error)
    fuel_types.each do |fuel_type|
      UtilityBills.get_rates_from_eia_data(nil, 'XX', fuel_type, 0)
    end
  end

  def test_warning_region
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-appliances-oil-location-miami-fl.xml'))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    expected_warnings = ['Could not find state average fuel oil rate based on Florida; using region (PADD 1C) average.']
    actual_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_national
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-appliances-propane-location-portland-or.xml'))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    expected_warnings = ['Could not find state average propane rate based on Oregon; using national average.']
    actual_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_dse
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-hvac-dse.xml'))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    expected_warnings = ['DSE is not currently supported when calculating utility bills.']
    actual_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_warning_no_rates
    @args_hash['hpxml_path'] = File.absolute_path(@tmp_hpxml_path)
    hpxml = HPXML.new(hpxml_path: File.join(@sample_files_path, 'base-location-capetown-zaf.xml'))
    XMLHelper.write_file(hpxml.to_oga, @tmp_hpxml_path)
    expected_warnings = ['Could not find a marginal Electricity rate.', 'Could not find a marginal Natural Gas rate.']
    actual_bills = _test_measure(expected_warnings: expected_warnings)
    assert_nil(actual_bills)
  end

  def test_error_user_specified_but_no_rates
    skip
    @args_hash['electricity_bill_type'] = 'Detailed'
    @args_hash['electricity_utility_rate_type'] = 'User-Specified'
    expected_errors = ['Must specify a utility rate json path when choosing User-Specified utility rate type.']
    actual_bills = _test_measure(expected_errors: expected_errors)
    assert_nil(actual_bills)
  end

  def test_monthly_prorate
    # Test begin_month == end_month
    header = HPXML::Header.new(nil)
    header.sim_begin_month = 3
    header.sim_begin_day = 5
    header.sim_end_month = 3
    header.sim_end_day = 20
    header.sim_calendar_year = 2002
    assert_equal(0.0, CalculateUtilityBill.calculate_monthly_prorate(header, 2))
    assert_equal((20 - 5 + 1) / 31.0, CalculateUtilityBill.calculate_monthly_prorate(header, 3))
    assert_equal(0.0, CalculateUtilityBill.calculate_monthly_prorate(header, 4))

    # Test begin_month != end_month
    header = HPXML::Header.new(nil)
    header.sim_begin_month = 2
    header.sim_begin_day = 10
    header.sim_end_month = 4
    header.sim_end_day = 10
    header.sim_calendar_year = 2002
    assert_equal(0.0, CalculateUtilityBill.calculate_monthly_prorate(header, 1))
    assert_equal((28 - 10 + 1) / 28.0, CalculateUtilityBill.calculate_monthly_prorate(header, 2))
    assert_equal(1.0, CalculateUtilityBill.calculate_monthly_prorate(header, 3))
    assert_equal(10 / 30.0, CalculateUtilityBill.calculate_monthly_prorate(header, 4))
    assert_equal(0.0, CalculateUtilityBill.calculate_monthly_prorate(header, 5))
  end

  def _check_bills(expected_bills, actual_bills)
    bills = expected_bills.keys | actual_bills.keys
    bills.each do |bill|
      assert(expected_bills.keys.include?(bill))
      assert(actual_bills.keys.include?(bill))
      assert_in_delta(expected_bills[bill], actual_bills[bill], 1) # within a dollar
    end
  end

  def _load_timeseries(fuels, path)
    fuels = @measure.setup_fuel_outputs()

    columns = CSV.read(File.join(File.dirname(__FILE__), path)).transpose
    columns.each do |col|
      col_name = col[0]
      next if col_name == 'Date/Time'

      values = col[1..-1].map { |v| Float(v) }

      if col_name == 'ELECTRICITY:UNIT_1 [J](Hourly)'
        fuel = fuels[[FT::Elec, false]]
        unit_conv = UnitConversions.convert(1.0, 'J', fuel.units)
        fuel.timeseries = values.map { |v| v * unit_conv }
      elsif col_name == 'GAS:UNIT_1 [J](Hourly)'
        fuel = fuels[[FT::Gas, false]]
        unit_conv = UnitConversions.convert(1.0, 'J', fuel.units)
        fuel.timeseries = values.map { |v| v * unit_conv }
      elsif col_name == 'Appl_1:ExteriorEquipment:Propane [J](Hourly)'
        fuel = fuels[[FT::Propane, false]]
        unit_conv = UnitConversions.convert(1.0, 'J', fuel.units) / 91.6
        fuel.timeseries = values.map { |v| v * unit_conv }
      elsif col_name == 'FUELOIL:UNIT_1 [m3](Hourly)'
        fuel = fuels[[FT::Oil, false]]
        unit_conv = UnitConversions.convert(1.0, 'm^3', 'gal')
        fuel.timeseries = values.map { |v| v * unit_conv }
      elsif col_name == 'PV:ELECTRICITY_1 [J](Hourly) '
        fuel = fuels[[FT::Elec, true]]
        unit_conv = UnitConversions.convert(1.0, 'J', fuel.units)
        fuel.timeseries = values.map { |v| v * unit_conv }
      end
    end

    fuels.values.each do |fuel|
      fuel.timeseries = [0] * fuels[[FT::Elec, false]].timeseries.size if fuel.timeseries.empty?
    end

    # Convert hourly data to monthly data
    num_days_in_month = Constants.NumDaysInMonths(2002) # Arbitrary non-leap year
    fuels.values.each do |fuel|
      ts_data = fuel.timeseries.dup
      fuel.timeseries = []
      start_day = 0
      num_days_in_month.each do |num_days|
        fuel.timeseries << ts_data[start_day * 24..(start_day + num_days) * 24 - 1].sum
        start_day += num_days
      end
    end

    return fuels
  end

  def _bill_calcs(fuels, utility_rates, utility_bills, header, pv_systems, utility_bill_scenario)
    args = Hash[@args_hash.collect { |k, v| [k.to_sym, v] }]
    args[:electricity_bill_type] = 'Simple'
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    output_format = 'csv'
    output_path = File.join(File.dirname(__FILE__), "results_bills.#{output_format}")

    @measure.get_utility_rates(fuels, utility_rates, args, utility_bill_scenario, pv_systems)
    net_elec = @measure.get_utility_bills(fuels, utility_rates, utility_bills, args, header)
    @measure.annual_true_up(utility_rates, utility_bills, net_elec)
    @measure.get_annual_bills(utility_bills)

    @measure.report_runperiod_output_results(runner, utility_bills, output_format, output_path, utility_bill_scenario.name)

    # Check written values exist and are registered
    assert(File.exist?(@bills_csv))
    actual_bills = _get_actual_bills(@bills_csv)

    _check_for_runner_registered_values(runner, nil, actual_bills)

    return actual_bills
  end

  def _test_measure(hpxml: nil, expected_errors: [], expected_warnings: [])
    # Run measure via OSW
    require 'json'
    template_osw = File.join(File.dirname(__FILE__), '..', '..', 'workflow', 'template-run-hpxml.osw')
    workflow = OpenStudio::WorkflowJSON.new(template_osw)
    json = JSON.parse(workflow.to_s)

    # Update measure args
    steps = OpenStudio::WorkflowStepVector.new
    found_args = []
    json['steps'].each do |json_step|
      step = OpenStudio::MeasureStep.new(json_step['measure_dir_name'])
      json_step['arguments'].each do |json_arg_name, json_arg_val|
        if @args_hash.keys.include? json_arg_name
          # Override value
          found_args << json_arg_name
          json_arg_val = @args_hash[json_arg_name]
        end
        step.setArgument(json_arg_name, json_arg_val)
      end
      steps.push(step)
    end
    workflow.setWorkflowSteps(steps)
    osw_path = File.join(File.dirname(template_osw), 'test.osw')
    workflow.saveAs(osw_path)
    assert_equal(@args_hash.size, found_args.size)

    # Run OSW
    command = "#{OpenStudio.getOpenStudioCLI} run -w #{osw_path}"
    cli_output = `#{command}`

    # Cleanup
    File.delete(osw_path)

    bills_csv = File.join(File.dirname(template_osw), 'run', 'results_bills.csv')

    # Check warnings/errors
    if not expected_errors.empty?
      expected_errors.each do |expected_error|
        assert(cli_output.include?("ERROR] #{expected_error}"))
      end
    end
    if not expected_warnings.empty?
      expected_warnings.each do |expected_warning|
        assert(cli_output.include?("WARN] #{expected_warning}"))
      end
    end

    if !hpxml.nil?
      return if hpxml.header.utility_bill_scenarios.empty?
    elsif (not expected_errors.empty?) || (not expected_warnings.empty?)
      return
    end

    # Check written values exist and are registered
    assert(File.exist?(bills_csv))
    actual_bills = _get_actual_bills(bills_csv)

    _check_for_runner_registered_values(nil, File.join(File.dirname(bills_csv), 'results.json'), actual_bills)

    return actual_bills
  end

  def _get_actual_bills(bills_csv)
    actual_bills = {}
    File.readlines(bills_csv).each do |line|
      next if line.strip.empty?

      key, value = line.split(',').map { |x| x.strip }
      actual_bills[key] = Float(value)
    end
    return actual_bills
  end

  def _check_for_runner_registered_values(runner, results_json, actual_bills)
    if !runner.nil?
      runner_bills = {}
      runner.result.stepValues.each do |step_value|
        runner_bills[step_value.name] = get_value_from_workflow_step_value(step_value)
      end
    elsif !results_json.nil?
      require 'json'
      runner_bills = JSON.parse(File.read(results_json))
      runner_bills = runner_bills['ReportUtilityBills']
    end

    actual_bills.each do |name, value|
      name = OpenStudio::toUnderscoreCase(name).chomp('_')

      assert_includes(runner_bills.keys, name)
      assert_equal(value, runner_bills[name])
    end
  end
end
