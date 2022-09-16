# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'msgpack'
require_relative 'resources/util.rb'
require_relative '../HPXMLtoOpenStudio/resources/constants.rb'
require_relative '../HPXMLtoOpenStudio/resources/location.rb'
require_relative '../HPXMLtoOpenStudio/resources/meta_measure.rb'
require_relative '../HPXMLtoOpenStudio/resources/output.rb'

# start the measure
class ReportUtilityBills < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Utility Bills Report'
  end

  # human readable description
  def description
    return 'Calculates and reports utility bills for residential HPXML-based models.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "Calculate electric/gas utility bills based on monthly fixed charges and marginal rates. Calculate other utility bills based on marginal rates for oil, propane, wood cord, wood pellets, and coal. User can specify PV compensation types of 'Net-Metering' or 'Feed-In Tariff', along with corresponding rates and connection fees."
  end

  # define the arguments that the user will input
  def arguments(model = nil) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Measure::OSArgumentVector.new

    format_chs = OpenStudio::StringVector.new
    format_chs << 'csv'
    format_chs << 'json'
    format_chs << 'msgpack'
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('output_format', format_chs, false)
    arg.setDisplayName('Output Format')
    arg.setDescription('The file format of the annual (and timeseries, if requested) outputs.')
    arg.setDefaultValue('csv')
    args << arg

    return args
  end

  def timeseries_frequency
    # Use monthly for fossil fuels and simple electric rates
    # Use hourly for detailed electric rates (URDB tariff or real time pricing)
    return 'monthly'
  end

  def check_for_warnings(args, pv_systems)
    warnings = []

    # Require full annual simulation
    if !(@hpxml.header.sim_begin_month == 1 && @hpxml.header.sim_begin_day == 1 && @hpxml.header.sim_end_month == 12 && @hpxml.header.sim_end_day == 31)
      if args[:electricity_bill_type] != 'Simple' || pv_systems.size > 0
        warnings << 'A full annual simulation is required for calculating detailed utility bills.'
      end
    end

    # Require user-specified utility rate if 'User-Specified'
    if args[:electricity_bill_type] == 'Detailed' && args[:electricity_utility_rate_type].get == 'User-Specified' && !args[:electricity_utility_rate_user_specified].is_initialized
      warnings << 'Must specify a utility rate json path when choosing User-Specified utility rate type.'
    end

    # Require not DSE
    (@hpxml.heating_systems + @hpxml.heat_pumps).each do |htg_system|
      next unless (htg_system.is_a?(HPXML::HeatingSystem) && htg_system.is_heat_pump_backup_system) || htg_system.fraction_heat_load_served > 0
      next if htg_system.distribution_system_idref.nil?
      next unless htg_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeDSE
      next if htg_system.distribution_system.annual_heating_dse.nil?
      next if htg_system.distribution_system.annual_heating_dse == 1

      warnings << 'DSE is not currently supported when calculating utility bills.'
    end
    (@hpxml.cooling_systems + @hpxml.heat_pumps).each do |clg_system|
      next unless clg_system.fraction_cool_load_served > 0
      next if clg_system.distribution_system_idref.nil?
      next unless clg_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeDSE
      next if clg_system.distribution_system.annual_cooling_dse.nil?
      next if clg_system.distribution_system.annual_cooling_dse == 1

      warnings << 'DSE is not currently supported when calculating utility bills.'
    end

    return warnings.uniq
  end

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new
    return result if runner.halted

    model = runner.lastOpenStudioModel
    if model.empty?
      return result
    end

    @model = model.get

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return result
    end

    # assign the user inputs to variables
    args = get_argument_values(runner, arguments(@model), user_arguments)
    args = Hash[args.collect { |k, v| [k.to_sym, v] }]
    args[:electricity_bill_type] = 'Simple' # TODO: support Detailed

    hpxml_defaults_path = @model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    building_id = @model.getBuilding.additionalProperties.getFeatureAsString('building_id').get
    @hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, building_id: building_id)

    warnings = check_for_warnings(args, @hpxml.pv_systems)
    return result if !warnings.empty?

    fuels = setup_fuel_outputs()

    # Fuel outputs
    fuels.values.each do |fuel|
      fuel.meters.each do |meter|
        result << OpenStudio::IdfObject.load("Output:Meter,#{meter},#{timeseries_frequency};").get
      end
    end

    return result.uniq
  end

  def register_warnings(runner, warnings)
    return false if warnings.empty?

    warnings.each do |warning|
      runner.registerWarning(warning)
    end
    return true
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find OpenStudio model.')
      return false
    end
    @model = model.get

    # use the built-in error checking (need model)
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    args = get_argument_values(runner, arguments(model), user_arguments)
    args = Hash[args.collect { |k, v| [k.to_sym, v] }]
    args[:electricity_bill_type] = 'Simple' # TODO: support Detailed
    output_format = args[:output_format].get

    output_dir = File.dirname(runner.lastEpwFilePath.get.to_s)

    if not File.exist? File.join(output_dir, 'eplusout.msgpack')
      runner.registerError('Cannot find eplusout.msgpack.')
      return false
    end
    @msgpackData = MessagePack.unpack(File.read(File.join(output_dir, 'eplusout.msgpack'), mode: 'rb'))

    hpxml_defaults_path = @model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    building_id = @model.getBuilding.additionalProperties.getFeatureAsString('building_id').get
    @hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, building_id: building_id)

    return true if @hpxml.header.utility_bill_scenarios.empty?

    warnings = check_for_warnings(args, @hpxml.pv_systems)
    if register_warnings(runner, warnings)
      return true
    end

    # Set paths
    output_path = File.join(output_dir, "results_bills.#{output_format}")
    FileUtils.rm(output_path) if File.exist?(output_path)

    # Setup fuel outputs
    fuels = setup_fuel_outputs()

    # Get timestamps
    @timestamps, _, _ = OutputMethods.get_timestamps(@msgpackData, @hpxml)

    # Get outputs
    get_outputs(fuels)

    @hpxml.header.utility_bill_scenarios.each do |utility_bill_scenario|
      utility_rates, utility_bills = setup_utility_outputs()

      # Get utility rates
      warnings = get_utility_rates(fuels, utility_rates, args, utility_bill_scenario, @hpxml.pv_systems)
      if register_warnings(runner, warnings)
        return true
      end

      # Calculate utility bills
      net_elec = get_utility_bills(fuels, utility_rates, utility_bills, args, @hpxml.header)

      # Annual true up
      annual_true_up(utility_rates, utility_bills, net_elec)

      # Calculate annual bills
      get_annual_bills(utility_bills)

      # Write/report results
      report_runperiod_output_results(runner, utility_bills, output_format, output_path, utility_bill_scenario.name)
    end

    return true
  end

  def report_runperiod_output_results(runner, utility_bills, output_format, output_path, bill_scenario_name)
    segment = utility_bills.keys[0].split(':', 2)[0]
    segment = segment.strip

    results_out = []
    results_out << ["#{bill_scenario_name}: Total (USD)", utility_bills.values.sum { |bill| bill.annual_total.round(2) }.round(2)]

    utility_bills.each do |fuel_type, bill|
      new_segment = fuel_type.split(':', 2)[0]
      new_segment = new_segment.strip
      if new_segment != segment
        segment = new_segment
      end

      results_out << ["#{bill_scenario_name}: #{fuel_type}: Fixed (USD)", bill.annual_fixed_charge.round(2)] if bill.annual_fixed_charge != 0
      results_out << ["#{bill_scenario_name}: #{fuel_type}: Marginal (USD)", bill.annual_energy_charge.round(2)] if bill.annual_energy_charge != 0
      results_out << ["#{bill_scenario_name}: #{fuel_type}: PV Credit (USD)", bill.annual_production_credit.round(2)] if [FT::Elec].include?(fuel_type) && bill.annual_production_credit != 0
      results_out << ["#{bill_scenario_name}: #{fuel_type}: Total (USD)", bill.annual_total.round(2)] if bill.annual_total != 0
    end

    if ['csv'].include? output_format
      CSV.open(output_path, 'a') { |csv| results_out.to_a.each { |elem| csv << elem } }
    elsif ['json', 'msgpack'].include? output_format
      h = {}
      results_out.each do |out|
        if out[0].include? ':'
          grp, name = out[0].split(':', 2)
          h[grp] = {} if h[grp].nil?
          h[grp][name.strip] = out[1]
        else
          h[out[0]] = out[1]
        end
      end

      if output_format == 'json'
        require 'json'
        File.open(output_path, 'w') { |json| json.write(JSON.pretty_generate(h)) }
      elsif output_format == 'msgpack'
        File.open(output_path, 'w') { |json| h.to_msgpack(json) }
      end
    end
    runner.registerInfo("Wrote bills output to #{output_path}.")

    results_out.each do |name, value|
      next if name.nil? || value.nil?

      name = OpenStudio::toUnderscoreCase(name).chomp('_')

      runner.registerValue(name, value)
      runner.registerInfo("Registering #{value} for #{name}.")
    end
  end

  def get_utility_rates(fuels, utility_rates, args, bill_scenario, pv_systems)
    warnings = []
    utility_rates.each do |fuel_type, rate|
      next if fuels[[fuel_type, false]].timeseries.sum == 0

      if fuel_type == FT::Elec
        if args[:electricity_bill_type] == 'Simple'
          rate.fixedmonthlycharge = bill_scenario.elec_fixed_charge
          rate.flatratebuy = bill_scenario.elec_marginal_rate
        elsif args[:electricity_bill_type] == 'Detailed'
          if args[:electricity_utility_rate_type].get != 'Autoselect OpenEI'
            if args[:electricity_utility_rate_type].get == 'User-Specified'
              path = args[:electricity_utility_rate_user_specified].get

              hpxml_path = @model.getBuilding.additionalProperties.getFeatureAsString('hpxml_path').get
              filepath = FilePath.check_path(path,
                                             File.dirname(hpxml_path),
                                             'Tariff File')
            else # sample rates
              custom_rates_folder = File.join(File.dirname(__FILE__), 'resources/Data/CustomRates')
              custom_rate_file = "#{args[:electricity_utility_rate_type].get}.json"
              filepath = File.join(custom_rates_folder, custom_rate_file)
            end

            fileread = File.read(filepath)
            tariff = JSON.parse(fileread, symbolize_names: true)
            tariff = tariff[:items][0]

            if tariff.keys.include?(:realtimepricing)
              rate.fixedmonthlycharge = tariff[:fixedmonthlycharge] if tariff.keys.include?(:fixedmonthlycharge)
              rate.realtimeprice = tariff[:realtimepricing].split(',').map { |v| Float(v) }

            else
              rate.fixedmonthlycharge = tariff[:fixedmonthlycharge] if tariff.keys.include?(:fixedmonthlycharge)
              rate.flatratebuy = tariff[:flatratebuy] if tariff.keys.include?(:flatratebuy)

              rate.energyratestructure = tariff[:energyratestructure] if tariff.keys.include?(:energyratestructure)
              rate.energyweekdayschedule = tariff[:energyweekdayschedule] if tariff.keys.include?(:energyweekdayschedule)
              rate.energyweekendschedule = tariff[:energyweekendschedule] if tariff.keys.include?(:energyweekendschedule)

              rate.demandratestructure = tariff[:demandratestructure] if tariff.keys.include?(:demandratestructure)
              rate.demandweekdayschedule = tariff[:demandweekdayschedule] if tariff.keys.include?(:demandweekdayschedule)
              rate.demandweekendschedule = tariff[:demandweekendschedule] if tariff.keys.include?(:demandweekendschedule)

              rate.flatdemandstructure = tariff[:flatdemandstructure] if tariff.keys.include?(:flatdemandstructure)
            end
          else
            # TODO
          end
        end

        # Net Metering
        rate.net_metering_excess_sellback_type = bill_scenario.pv_net_metering_annual_excess_sellback_rate_type if bill_scenario.pv_compensation_type == HPXML::PVCompensationTypeNetMetering
        rate.net_metering_user_excess_sellback_rate = bill_scenario.pv_net_metering_annual_excess_sellback_rate if rate.net_metering_excess_sellback_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified

        # Feed-In Tariff
        rate.feed_in_tariff_rate = bill_scenario.pv_feed_in_tariff_rate if bill_scenario.pv_compensation_type == HPXML::PVCompensationTypeFeedInTariff
      elsif fuel_type == FT::Gas
        rate.fixedmonthlycharge = bill_scenario.natural_gas_fixed_charge
        rate.flatratebuy = bill_scenario.natural_gas_marginal_rate
      elsif fuel_type == FT::Oil
        rate.fixedmonthlycharge = bill_scenario.fuel_oil_fixed_charge
        rate.flatratebuy = bill_scenario.fuel_oil_marginal_rate
      elsif fuel_type == FT::Propane
        rate.fixedmonthlycharge = bill_scenario.propane_fixed_charge
        rate.flatratebuy = bill_scenario.propane_marginal_rate
      elsif fuel_type == FT::WoodCord
        rate.fixedmonthlycharge = bill_scenario.wood_fixed_charge
        rate.flatratebuy = bill_scenario.wood_marginal_rate
      elsif fuel_type == FT::WoodPellets
        rate.fixedmonthlycharge = bill_scenario.wood_pellets_fixed_charge
        rate.flatratebuy = bill_scenario.wood_pellets_marginal_rate
      elsif fuel_type == FT::Coal
        rate.fixedmonthlycharge = bill_scenario.coal_fixed_charge
        rate.flatratebuy = bill_scenario.coal_marginal_rate
      end

      warnings << "Could not find a marginal #{fuel_type} rate." if rate.flatratebuy.nil?

      # Grid connection fee
      next unless fuel_type == FT::Elec

      next unless args[:electricity_bill_type] == 'Simple'

      next unless pv_systems.size > 0

      monthly_fee = 0.0
      if not bill_scenario.pv_monthly_grid_connection_fee_dollars_per_kw.nil?
        pv_systems.each do |pv_system|
          max_power_output_kW = UnitConversions.convert(pv_system.max_power_output, 'W', 'kW')
          monthly_fee += bill_scenario.pv_monthly_grid_connection_fee_dollars_per_kw * max_power_output_kW
        end
      elsif not bill_scenario.pv_monthly_grid_connection_fee_dollars.nil?
        monthly_fee = bill_scenario.pv_monthly_grid_connection_fee_dollars
      end
      rate.fixedmonthlycharge += monthly_fee
    end
    return warnings
  end

  def get_utility_bills(fuels, utility_rates, utility_bills, args, header)
    net_elec = 0
    fuels.each do |(fuel_type, is_production), fuel|
      rate = utility_rates[fuel_type]
      bill = utility_bills[fuel_type]

      if fuel_type == FT::Elec
        if args[:electricity_bill_type] == 'Detailed' && rate.realtimeprice.empty?
          net_elec = CalculateUtilityBill.detailed_electric(fuels, rate, bill, net_elec)
        else
          net_elec = CalculateUtilityBill.simple(fuel_type, header, fuel.timeseries, is_production, rate, bill, net_elec)
        end
      else
        net_elec = CalculateUtilityBill.simple(fuel_type, header, fuel.timeseries, is_production, rate, bill, net_elec)
      end
    end
    return net_elec
  end

  def annual_true_up(utility_rates, utility_bills, net_elec)
    rate = utility_rates[FT::Elec]
    bill = utility_bills[FT::Elec]
    if rate.net_metering_excess_sellback_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
      if bill.annual_production_credit > bill.annual_energy_charge
        bill.annual_production_credit = bill.annual_energy_charge
      end
      if net_elec < 0
        bill.annual_production_credit += -net_elec * rate.net_metering_user_excess_sellback_rate
      end
    end
  end

  def get_annual_bills(utility_bills)
    utility_bills.values.each do |bill|
      if bill.annual_production_credit > 0
        bill.annual_production_credit *= -1
      end

      bill.annual_total = bill.annual_fixed_charge + bill.annual_energy_charge + bill.annual_production_credit
    end
  end

  def setup_fuel_outputs()
    def get_timeseries_units_from_fuel_type(fuel_type)
      if fuel_type == FT::Elec
        return 'kWh'
      elsif fuel_type == FT::Gas
        return 'therm'
      end

      return 'kBtu'
    end

    fuels = {}
    fuels[[FT::Elec, false]] = Fuel.new(meters: ["#{EPlus::FuelTypeElectricity}:Facility"])
    fuels[[FT::Elec, true]] = Fuel.new(meters: ["#{EPlus::FuelTypeElectricity}Produced:Facility"])
    fuels[[FT::Gas, false]] = Fuel.new(meters: ["#{EPlus::FuelTypeNaturalGas}:Facility"])
    fuels[[FT::Oil, false]] = Fuel.new(meters: ["#{EPlus::FuelTypeOil}:Facility"])
    fuels[[FT::Propane, false]] = Fuel.new(meters: ["#{EPlus::FuelTypePropane}:Facility"])
    fuels[[FT::WoodCord, false]] = Fuel.new(meters: ["#{EPlus::FuelTypeWoodCord}:Facility"])
    fuels[[FT::WoodPellets, false]] = Fuel.new(meters: ["#{EPlus::FuelTypeWoodPellets}:Facility"])
    fuels[[FT::Coal, false]] = Fuel.new(meters: ["#{EPlus::FuelTypeCoal}:Facility"])

    fuels.each do |(fuel_type, _is_production), fuel|
      fuel.units = get_timeseries_units_from_fuel_type(fuel_type)
    end

    return fuels
  end

  def setup_utility_outputs()
    utility_rates = {}
    utility_rates[FT::Elec] = UtilityRate.new
    utility_rates[FT::Gas] = UtilityRate.new
    utility_rates[FT::Oil] = UtilityRate.new
    utility_rates[FT::Propane] = UtilityRate.new
    utility_rates[FT::WoodCord] = UtilityRate.new
    utility_rates[FT::WoodPellets] = UtilityRate.new
    utility_rates[FT::Coal] = UtilityRate.new

    utility_bills = {}
    utility_bills[FT::Elec] = UtilityBill.new
    utility_bills[FT::Gas] = UtilityBill.new
    utility_bills[FT::Oil] = UtilityBill.new
    utility_bills[FT::Propane] = UtilityBill.new
    utility_bills[FT::WoodCord] = UtilityBill.new
    utility_bills[FT::WoodPellets] = UtilityBill.new
    utility_bills[FT::Coal] = UtilityBill.new

    return utility_rates, utility_bills
  end

  def get_outputs(fuels)
    fuels.each do |(fuel_type, _is_production), fuel|
      unit_conv = UnitConversions.convert(1.0, 'J', fuel.units)
      unit_conv /= 139.0 if fuel_type == FT::Oil
      unit_conv /= 91.6 if fuel_type == FT::Propane

      fuel.timeseries = get_report_meter_data_timeseries(fuel.meters, unit_conv, 0)
    end
  end

  def reporting_frequency_map
    return {
      'timestep' => 'Zone Timestep',
      'hourly' => 'Hourly',
      'daily' => 'Daily',
      'monthly' => 'Monthly',
    }
  end

  def get_report_meter_data_timeseries(meter_names, unit_conv, unit_adder)
    return [0.0] * @timestamps.size if meter_names.empty?

    msgpack_timeseries_name = OutputMethods.msgpack_frequency_map[timeseries_frequency]
    cols = @msgpackData['MeterData'][msgpack_timeseries_name]['Cols']
    rows = @msgpackData['MeterData'][msgpack_timeseries_name]['Rows']
    indexes = cols.each_index.select { |i| meter_names.include? cols[i]['Variable'] }
    vals = []
    rows.each do |row|
      row = row[row.keys[0]]
      val = 0.0
      indexes.each do |i|
        val += row[i] * unit_conv + unit_adder
      end
      vals << val
    end
    return vals
  end
end

# register the measure to be used by the application
ReportUtilityBills.new.registerWithApplication
