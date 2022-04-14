# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

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
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    format_chs = OpenStudio::StringVector.new
    format_chs << 'csv'
    format_chs << 'json'
    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('output_format', format_chs, false)
    arg.setDisplayName('Output Format')
    arg.setDescription('The file format of the annual (and timeseries, if requested) outputs.')
    arg.setDefaultValue('csv')
    args << arg

    # electricity_bill_type_choices = OpenStudio::StringVector.new
    # electricity_bill_type_choices << 'Simple'
    # electricity_bill_type_choices << 'Detailed'

    # arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('electricity_bill_type', electricity_bill_type_choices, true)
    # arg.setDisplayName('Electricity: Simple or Detailed')
    # arg.setDescription("Choose either 'Simple' or 'Detailed'. If 'Simple' is selected, electric utility bills are calculated based on user-defined fixed charge and marginal rate. If 'Detailed' is selected, electric utility bills are calculated based on either: a tariff from the OpenEI Utility Rate Database (URDB), or a real-time pricing rate.")
    # arg.setDefaultValue('Simple')
    # args << arg

    # utility_rate_type_choices = OpenStudio::StringVector.new
    # utility_rate_type_choices << 'Autoselect OpenEI'
    # utility_rate_type_choices << 'Sample Real-Time Pricing Rate'
    # utility_rate_type_choices << 'Sample Tiered Rate'
    # utility_rate_type_choices << 'Sample Time-of-Use Rate'
    # utility_rate_type_choices << 'Sample Tiered Time-of-Use Rate'
    # utility_rate_type_choices << 'User-Specified'

    # arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('electricity_utility_rate_type', utility_rate_type_choices, false)
    # arg.setDisplayName('Electricity: Utility Rate Type')
    # arg.setDescription("Type of the utility rate. Required if electricity bill type is 'Detailed'.")
    # arg.setDefaultValue('Autoselect OpenEI')
    # args << arg

    # arg = OpenStudio::Measure::OSArgument::makeStringArgument('electricity_utility_rate_user_specified', false)
    # arg.setDisplayName('Electricity: User-Specified Utility Rate')
    # arg.setDescription("Absolute/relative path of the json. Relative paths are relative to the HPXML file. Required if utility rate type is 'User-Specified'.")
    # args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('electricity_fixed_charge', false)
    arg.setDisplayName('Electricity: Fixed Charge')
    arg.setUnits('$/month')
    arg.setDescription('Monthly fixed charge for electricity.')
    arg.setDefaultValue(12.0) # https://www.nrdc.org/experts/samantha-williams/there-war-attrition-electricity-fixed-charges says $11.19/month in 2018
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('electricity_marginal_rate', false)
    arg.setDisplayName('Electricity: Marginal Rate')
    arg.setUnits('$/kWh')
    arg.setDescription("Price per kilowatt-hour for electricity. Use '#{Constants.Auto}' to obtain a state-average value from EIA.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('natural_gas_fixed_charge', false)
    arg.setDisplayName('Natural Gas: Fixed Charge')
    arg.setUnits('$/month')
    arg.setDescription('Monthly fixed charge for natural gas.')
    arg.setDefaultValue(12.0) # https://www.aga.org/sites/default/files/aga_energy_analysis_-_natural_gas_utility_rate_structure.pdf says $11.25/month in 2015
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('natural_gas_marginal_rate', false)
    arg.setDisplayName('Natural Gas: Marginal Rate')
    arg.setUnits('$/therm')
    arg.setDescription("Price per therm for natural gas. Use '#{Constants.Auto}' to obtain a state-average value from EIA.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('fuel_oil_marginal_rate', false)
    arg.setDisplayName('Fuel Oil: Marginal Rate')
    arg.setUnits('$/gal')
    arg.setDescription("Price per gallon for fuel oil. Use '#{Constants.Auto}' to obtain a state-average value from EIA.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeStringArgument('propane_marginal_rate', false)
    arg.setDisplayName('Propane: Marginal Rate')
    arg.setUnits('$/gal')
    arg.setDescription("Price per gallon for propane. Use '#{Constants.Auto}' to obtain a state-average value from EIA.")
    arg.setDefaultValue(Constants.Auto)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('wood_cord_marginal_rate', false)
    arg.setDisplayName('Wood Cord: Marginal Rate')
    arg.setUnits('$/kBtu')
    arg.setDescription('Price per kBtu for wood cord.')
    arg.setDefaultValue(0.015)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('wood_pellets_marginal_rate', false)
    arg.setDisplayName('Wood Pellets: Marginal Rate')
    arg.setUnits('$/kBtu')
    arg.setDescription('Price per kBtu for wood pellets.')
    arg.setDefaultValue(0.015)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('coal_marginal_rate', false)
    arg.setDisplayName('Coal: Marginal Rate')
    arg.setUnits('$/kBtu')
    arg.setDescription('Price per kBtu for coal.')
    arg.setDefaultValue(0.015)
    args << arg

    pv_compensation_type_choices = OpenStudio::StringVector.new
    pv_compensation_type_choices << 'Net Metering'
    pv_compensation_type_choices << 'Feed-In Tariff'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('pv_compensation_type', pv_compensation_type_choices, false)
    arg.setDisplayName('PV: Compensation Type')
    arg.setDescription('The type of compensation for PV.')
    arg.setDefaultValue('Net Metering')
    args << arg

    pv_annual_excess_sellback_rate_type_choices = OpenStudio::StringVector.new
    pv_annual_excess_sellback_rate_type_choices << 'User-Specified'
    pv_annual_excess_sellback_rate_type_choices << 'Retail Electricity Cost'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('pv_annual_excess_sellback_rate_type', pv_annual_excess_sellback_rate_type_choices, false)
    arg.setDisplayName('PV: Net Metering Annual Excess Sellback Rate Type')
    arg.setDescription("The type of annual excess sellback rate for PV. Only applies if the PV compensation type is 'Net Metering'.")
    arg.setDefaultValue('User-Specified')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('pv_net_metering_annual_excess_sellback_rate', false)
    arg.setDisplayName('PV: Net Metering Annual Excess Sellback Rate')
    arg.setUnits('$/kWh')
    arg.setDescription("The annual excess sellback rate for PV. Only applies if the PV compensation type is 'Net Metering' and the PV annual excess sellback rate type is 'User-Specified'.")
    arg.setDefaultValue(0.03)
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('pv_feed_in_tariff_rate', false)
    arg.setDisplayName('PV: Feed-In Tariff Rate')
    arg.setUnits('$/kWh')
    arg.setDescription("The annual full/gross tariff rate for PV. Only applies if the PV compensation type is 'Feed-In Tariff'.")
    arg.setDefaultValue(0.12)
    args << arg

    pv_grid_connection_fee_units_choices = OpenStudio::StringVector.new
    pv_grid_connection_fee_units_choices << '$/kW'
    pv_grid_connection_fee_units_choices << '$'

    arg = OpenStudio::Measure::OSArgument::makeChoiceArgument('pv_grid_connection_fee_units', pv_grid_connection_fee_units_choices, false)
    arg.setDisplayName('PV: Grid Connection Fee Units')
    arg.setDescription('Units for PV grid connection fee. Only applies when there is PV.')
    arg.setDefaultValue('$/kW')
    args << arg

    arg = OpenStudio::Measure::OSArgument::makeDoubleArgument('pv_monthly_grid_connection_fee', false)
    arg.setDisplayName('PV: Monthly Grid Connection Fee')
    arg.setUnits('$')
    arg.setDescription('Monthly fee for PV grid connection. Only applies when there is PV.')
    arg.setDefaultValue(0.0)
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

    fuels, _, _ = setup_outputs()

    # Fuel outputs
    fuels.each do |fuel_type, fuel|
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

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError('Cannot find EnergyPlus sql file.')
      return false
    end
    @sqlFile = sqlFile.get
    if not @sqlFile.connectionOpen
      runner.registerError('EnergyPlus simulation failed.')
      return false
    end
    @model.setSqlFile(@sqlFile)

    hpxml_defaults_path = @model.getBuilding.additionalProperties.getFeatureAsString('hpxml_defaults_path').get
    building_id = @model.getBuilding.additionalProperties.getFeatureAsString('building_id').get
    @hpxml = HPXML.new(hpxml_path: hpxml_defaults_path, building_id: building_id)

    warnings = check_for_warnings(args, @hpxml.pv_systems)
    if register_warnings(runner, warnings)
      OutputMethods.teardown(@sqlFile)
      return true
    end

    # Set paths
    output_dir = File.dirname(@sqlFile.path.to_s)
    output_path = File.join(output_dir, "results_bills.#{output_format}")

    # Setup outputs
    fuels, utility_rates, utility_bills = setup_outputs()

    # Get timestamps
    @timestamps = OutputMethods.get_timestamps(timeseries_frequency, @sqlFile, @hpxml)

    # Get outputs
    get_outputs(fuels)

    # Preprocess arguments
    preprocess_arguments(args)

    # Get utility rates
    warnings = get_utility_rates(fuels, utility_rates, args, @hpxml.header.state_code, @hpxml.pv_systems, runner)
    if register_warnings(runner, warnings)
      OutputMethods.teardown(@sqlFile)
      return true
    end

    # Calculate utility bills
    net_elec = get_utility_bills(fuels, utility_rates, utility_bills, args, @hpxml.header)

    # Annual true up
    annual_true_up(utility_rates, utility_bills, net_elec)

    # Calculate annual bills
    get_annual_bills(utility_bills)

    # Report results
    utility_bill_type_str = OpenStudio::toUnderscoreCase('Total USD')
    utility_bill_type_val = utility_bills.sum { |fuel_type, utility_bill| utility_bill.annual_total.round(2) }.round(2)
    runner.registerValue(utility_bill_type_str, utility_bill_type_val)
    runner.registerInfo("Registering #{utility_bill_type_val} for #{utility_bill_type_str}.")

    utility_bills.each do |fuel_type, utility_bill|
      if [FT::Elec, FT::Gas].include? fuel_type
        utility_bill_type_str = OpenStudio::toUnderscoreCase("#{fuel_type} Fixed USD")
        utility_bill_type_val = utility_bill.annual_fixed_charge.round(2)
        runner.registerValue(utility_bill_type_str, utility_bill_type_val)
        runner.registerInfo("Registering #{utility_bill_type_val} for #{utility_bill_type_str}.")
      end

      if [FT::Elec, FT::Gas].include? fuel_type
        utility_bill_type_str = OpenStudio::toUnderscoreCase("#{fuel_type} Marginal USD")
        utility_bill_type_val = utility_bill.annual_energy_charge.round(2)
        runner.registerValue(utility_bill_type_str, utility_bill_type_val)
        runner.registerInfo("Registering #{utility_bill_type_val} for #{utility_bill_type_str}.")
      end

      if [FT::Elec].include? fuel_type
        utility_bill_type_str = OpenStudio::toUnderscoreCase("#{fuel_type} PV Credit USD")
        utility_bill_type_val = utility_bill.annual_production_credit.round(2)
        runner.registerValue(utility_bill_type_str, utility_bill_type_val)
        runner.registerInfo("Registering #{utility_bill_type_val} for #{utility_bill_type_str}.")
      end

      utility_bill_type_str = OpenStudio::toUnderscoreCase("#{fuel_type} Total USD")
      utility_bill_type_val = utility_bill.annual_total.round(2)
      runner.registerValue(utility_bill_type_str, utility_bill_type_val)
      runner.registerInfo("Registering #{utility_bill_type_val} for #{utility_bill_type_str}.")
    end

    # Write results
    write_output(runner, utility_bills, output_format, output_path)

    OutputMethods.teardown(@sqlFile)

    return true
  end

  def preprocess_arguments(args)
    args[:electricity_fixed_charge] = args[:electricity_fixed_charge].get
    args[:electricity_marginal_rate] = args[:electricity_marginal_rate].get
    args[:natural_gas_fixed_charge] = args[:natural_gas_fixed_charge].get
    args[:natural_gas_marginal_rate] = args[:natural_gas_marginal_rate].get
    args[:fuel_oil_marginal_rate] = args[:fuel_oil_marginal_rate].get
    args[:propane_marginal_rate] = args[:propane_marginal_rate].get
    args[:wood_cord_marginal_rate] = args[:wood_cord_marginal_rate].get
    args[:wood_pellets_marginal_rate] = args[:wood_pellets_marginal_rate].get
    args[:coal_marginal_rate] = args[:coal_marginal_rate].get
    args[:pv_compensation_type] = args[:pv_compensation_type].get
    args[:pv_annual_excess_sellback_rate_type] = args[:pv_annual_excess_sellback_rate_type].get
    args[:pv_net_metering_annual_excess_sellback_rate] = args[:pv_net_metering_annual_excess_sellback_rate].get
    args[:pv_feed_in_tariff_rate] = args[:pv_feed_in_tariff_rate].get
    args[:pv_grid_connection_fee_units] = args[:pv_grid_connection_fee_units].get
    args[:pv_monthly_grid_connection_fee] = args[:pv_monthly_grid_connection_fee].get
  end

  def get_utility_rates(fuels, utility_rates, args, state_code, pv_systems, runner = nil)
    warnings = []
    utility_rates.each do |fuel_type, rate|
      next if fuels[[fuel_type, false]].timeseries.sum == 0

      if fuel_type == FT::Elec
        if args[:electricity_bill_type] == 'Simple'
          rate.fixedmonthlycharge = args[:electricity_fixed_charge]
          rate.flatratebuy = args[:electricity_marginal_rate]
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
        rate.net_metering_excess_sellback_type = args[:pv_annual_excess_sellback_rate_type] if args[:pv_compensation_type] == 'Net Metering'
        rate.net_metering_user_excess_sellback_rate = args[:pv_net_metering_annual_excess_sellback_rate] if rate.net_metering_excess_sellback_type == 'User-Specified'

        # Feed-In Tariff
        rate.feed_in_tariff_rate = args[:pv_feed_in_tariff_rate] if args[:pv_compensation_type] == 'Feed-In Tariff'
      elsif fuel_type == FT::Gas
        rate.fixedmonthlycharge = args[:natural_gas_fixed_charge]
        rate.flatratebuy = args[:natural_gas_marginal_rate]
      elsif fuel_type == FT::Oil
        rate.flatratebuy = args[:fuel_oil_marginal_rate]
      elsif fuel_type == FT::Propane
        rate.flatratebuy = args[:propane_marginal_rate]
      elsif fuel_type == FT::WoodCord
        rate.flatratebuy = args[:wood_cord_marginal_rate]
      elsif fuel_type == FT::WoodPellets
        rate.flatratebuy = args[:wood_pellets_marginal_rate]
      elsif fuel_type == FT::Coal
        rate.flatratebuy = args[:coal_marginal_rate]
      end

      if rate.flatratebuy == Constants.Auto
        if [FT::Elec, FT::Gas, FT::Oil, FT::Propane].include? fuel_type
          rate.flatratebuy = get_auto_marginal_rate(runner, state_code, fuel_type, rate.fixedmonthlycharge)

          if !rate.flatratebuy.nil?
            runner.registerInfo("Found a marginal rate of '#{rate.flatratebuy}' for #{fuel_type}.") if !runner.nil?
          else
            warnings << "Could not find a marginal #{fuel_type} rate." if rate.flatratebuy.nil?
          end
        end
      else
        rate.flatratebuy = Float(rate.flatratebuy)
      end

      # Grid connection fee
      next unless fuel_type == FT::Elec

      next unless args[:electricity_bill_type] == 'Simple'

      next unless pv_systems.size > 0

      monthly_fee = 0.0
      if args[:pv_grid_connection_fee_units] == '$/kW'
        pv_systems.each do |pv_system|
          max_power_output_kW = UnitConversions.convert(pv_system.max_power_output, 'W', 'kW')
          monthly_fee += args[:pv_monthly_grid_connection_fee] * max_power_output_kW
        end
      elsif args[:pv_grid_connection_fee_units] == '$'
        monthly_fee = args[:pv_monthly_grid_connection_fee]
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
    if rate.net_metering_excess_sellback_type == 'User-Specified'
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

  def setup_outputs()
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

    fuels.each do |(fuel_type, is_production), fuel|
      fuel.units = get_timeseries_units_from_fuel_type(fuel_type)
    end

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

    return fuels, utility_rates, utility_bills
  end

  def get_outputs(fuels)
    fuels.each do |(fuel_type, is_production), fuel|
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

    vars = "'" + meter_names.uniq.join("','") + "'"
    query = "SELECT SUM(VariableValue*#{unit_conv}+#{unit_adder}) FROM ReportMeterData WHERE ReportMeterDataDictionaryIndex IN (SELECT ReportMeterDataDictionaryIndex FROM ReportMeterDataDictionary WHERE VariableName IN (#{vars}) AND ReportingFrequency='#{reporting_frequency_map[timeseries_frequency]}' AND VariableUnits='J') GROUP BY TimeIndex ORDER BY TimeIndex"
    values = @sqlFile.execAndReturnVectorOfDouble(query)
    fail "Query error: #{query}" unless values.is_initialized

    values = values.get
    values += [0.0] * @timestamps.size if values.size == 0
    return values
  end

  def average_rate_to_marginal_rate(average_rate, fixed_rate, household_consumption)
    return average_rate - 12.0 * fixed_rate / household_consumption
  end

  def get_household_consumption(state_code, fuel_type)
    rows = CSV.read(File.join(File.dirname(__FILE__), 'resources/Data/UtilityRates/HouseholdConsumption.csv'))
    rows.each do |row|
      next if row[0] != state_code

      if fuel_type == FT::Elec
        return Float(row[1])
      elsif fuel_type == FT::Gas
        return Float(row[2])
      end
    end
  end

  def get_auto_marginal_rate(runner, state_code, fuel_type, fixed_rate)
    state_name = Constants.StateCodesMap[state_code]
    return if state_name.nil?

    average_rate = nil
    marginal_rate = nil
    if fuel_type == FT::Elec
      year_ix = nil
      rows = CSV.read(File.join(File.dirname(__FILE__), 'resources/Data/UtilityRates/Average_retail_price_of_electricity.csv'))
      rows.each do |row|
        year_ix = row.index('2021') if row[0] == 'description'
        next if row[0].upcase != "Residential : #{state_name}".upcase

        average_rate = Float(row[year_ix]) / 100.0 # Convert cents/kWh to $/kWh
      end

      household_consumption = get_household_consumption(state_code, fuel_type)
      marginal_rate = average_rate_to_marginal_rate(average_rate, fixed_rate, household_consumption)

    elsif fuel_type == FT::Gas
      rows = CSV.read(File.join(File.dirname(__FILE__), 'resources/Data/UtilityRates/NG_PRI_SUM_A_EPG0_PRS_DMCF_A.csv'))
      rows = rows[2..-1]

      state_ix = rows[0].index("#{state_name} Price of Natural Gas Delivered to Residential Consumers (Dollars per Thousand Cubic Feet)")
      rows[1..-1].each do |row|
        average_rate = Float(row[state_ix]) / 10.37 if !row[state_ix].nil? # Convert Mcf to therms, from https://www.eia.gov/tools/faqs/faq.php?id=45&t=7
      end

      household_consumption = get_household_consumption(state_code, fuel_type)
      marginal_rate = average_rate_to_marginal_rate(average_rate, fixed_rate, household_consumption)

    elsif [FT::Oil, FT::Propane].include? fuel_type
      if fuel_type == FT::Oil
        marginal_rates = get_gallon_marginal_rates('PET_PRI_WFR_A_EPD2F_PRS_DPGAL_W.csv')
        header = "Weekly #{state_name} Weekly No. 2 Heating Oil Residential Price  (Dollars per Gallon)"
      elsif fuel_type == FT::Propane
        marginal_rates = marginal_rates = get_gallon_marginal_rates('PET_PRI_WFR_A_EPLLPA_PRS_DPGAL_W.csv')
        header = "Weekly #{state_name} Propane Residential Price  (Dollars per Gallon)"
      end

      if marginal_rates[header].nil?
        padd = get_state_code_to_padd[state_code]
        marginal_rates.each do |k, v|
          header = k if k.include?(padd)
        end
        average = "region (#{padd})"

        if marginal_rates[header].nil?
          if fuel_type == FT::Oil
            header = 'Weekly U.S. Weekly No. 2 Heating Oil Residential Price  (Dollars per Gallon)'
          elsif fuel_type == FT::Propane
            header = 'Weekly U.S. Propane Residential Price  (Dollars per Gallon)'
          end
          average = 'national'
        end

        runner.registerWarning("Could not find state average #{fuel_type} rate based on #{state_name}; using #{average} average.") if !runner.nil?
      end
      marginal_rate = marginal_rates[header].sum / marginal_rates[header].size
    end

    return marginal_rate
  end

  def get_state_code_to_padd
    # https://www.eia.gov/tools/glossary/index.php?id=petroleum%20administration%20for%20defense%20district
    padd_to_state_codes = { 'PADD 1A' => ['CT', 'MA', 'ME', 'NH', 'RI', 'VT'],
                            'PADD 1B' => ['DE', 'DC', 'MD', 'NJ', 'NY', 'PA'],
                            'PADD 1C' => ['FL', 'GA', 'NC', 'SC', 'WV', 'VA'],
                            'PADD 2' => ['IA', 'IL', 'IN', 'KS', 'KY', 'MI', 'MN', 'MO', 'ND', 'NE', 'OH', 'OK', 'SD', 'TN', 'WI'],
                            'PADD 3' => ['AL', 'AR', 'LA', 'MS', 'NM', 'TX'],
                            'PADD 4' => ['CO', 'ID', 'MT', 'UT', 'WY'],
                            'PADD 5' => ['AK', 'AZ', 'CA', 'HI', 'NV', 'OR', 'WA'] }

    state_code_to_padd = {}
    padd_to_state_codes.each do |padd, state_codes|
      state_codes.each do |state_code|
        state_code_to_padd[state_code] = padd
      end
    end

    return state_code_to_padd
  end

  def get_gallon_marginal_rates(filename)
    marginal_rates = {}

    rows = CSV.read(File.join(File.dirname(__FILE__), "resources/Data/UtilityRates/#{filename}"))
    rows = rows[2..-1]
    headers = rows[0]

    rows = rows.reverse[1..26].transpose
    rows.each_with_index do |row, i|
      marginal_rates[headers[i]] = row
    end

    marginal_rates.delete('Date')
    marginal_rates.each do |header, values|
      if values.all? { |x| x.nil? }
        marginal_rates.delete(header)
        next
      end
      marginal_rates[header] = marginal_rates[header].map { |x| Float(x) }
    end

    return marginal_rates
  end

  def write_output(runner, utility_bills, output_format, output_path)
    line_break = nil

    segment = utility_bills.keys[0].split(':', 2)[0]
    segment = segment.strip
    results_out = []
    results_out << ['Total ($)', utility_bills.sum { |key, bill| bill.annual_total.round(2) }.round(2)]
    results_out << [line_break]
    utility_bills.each do |key, bill|
      new_segment = key.split(':', 2)[0]
      new_segment = new_segment.strip
      if new_segment != segment
        results_out << [line_break]
        segment = new_segment
      end

      results_out << ["#{key}: Fixed ($)", bill.annual_fixed_charge.round(2)] if [FT::Elec, FT::Gas].include? key
      results_out << ["#{key}: Marginal ($)", bill.annual_energy_charge.round(2)] if [FT::Elec, FT::Gas].include? key
      results_out << ["#{key}: PV Credit ($)", bill.annual_production_credit.round(2)] if [FT::Elec].include? key
      results_out << ["#{key}: Total ($)", bill.annual_total.round(2)]
    end

    if output_format == 'csv'
      CSV.open(output_path, 'wb') { |csv| results_out.to_a.each { |elem| csv << elem } }
    elsif output_format == 'json'
      h = {}
      results_out.each do |out|
        next if out == [line_break]

        if out[0].include? ':'
          grp, name = out[0].split(':', 2)
          h[grp] = {} if h[grp].nil?
          h[grp][name.strip] = out[1]
        else
          h[out[0]] = out[1]
        end
      end

      require 'json'
      File.open(output_path, 'w') { |json| json.write(JSON.pretty_generate(h)) }
    end
    runner.registerInfo("Wrote bills output to #{output_path}.")
  end
end

# register the measure to be used by the application
ReportUtilityBills.new.registerWithApplication
