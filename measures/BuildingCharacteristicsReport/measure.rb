require 'openstudio'

class BuildingCharacteristicsReport < OpenStudio::Measure::ReportingMeasure
  def name
    return 'Building Characteristics Report'
  end

  def description
    return 'Reports building characteristics for each simulation.'
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end

  def outputs
    result = OpenStudio::Measure::OSOutputVector.new
    # Outputs based on parameters in options_lookup.tsv
    # Note: Not every parameter is used by every project; non-applicable outputs for a given project can be removed via a server finalization script.
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', 'resources'))
    buildstock_file = File.join(resources_dir, 'buildstock.rb')
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')
    require File.join(File.dirname(buildstock_file), File.basename(buildstock_file, File.extname(buildstock_file)))
    parameters = get_parameters_ordered_from_options_lookup_tsv(lookup_file)
    parameters.each do |parameter|
      result << OpenStudio::Measure::OSOutput.makeStringOutput(OpenStudio::toUnderscoreCase(parameter))
    end
    buildstock_outputs = [
      'location_city',
      'location_state',
      'location_latitude',
      'location_longitude',
      'climate_zone_ba',
      'climate_zone_iecc',
      'units_represented',
      'units_modeled'
    ]
    buildstock_outputs.each do |output|
      result << OpenStudio::Measure::OSOutput.makeStringOutput(output)
    end
    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    unless runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    characteristics = {}

    # Exit if this is an upgrade datapoint
    upgrade_name = get_value_from_runner_past_results(runner, 'upgrade_name', 'apply_upgrade', false)
    if not upgrade_name.nil?
      runner.registerInfo('Upgrade datapoint, no building characteristics will be reported.')
      return true
    end

    # Get existing building characteristics
    runner.workflow.workflowSteps.each do |step|
      next if not step.result.is_initialized

      step_result = step.result.get
      next if !step_result.measureName.is_initialized || (step_result.measureName.get != 'build_existing_model')

      step_result.stepValues.each do |step_value|
        begin
          # All building characteristics will be strings
          characteristics[step_value.name] = step_value.valueAsString
        rescue
          runner.registerInfo("Skipping #{step_value.name}.")
        end
      end
    end

    # Report building characteristics
    characteristics.each do |k, v|
      runner.registerInfo("Registering #{v} for #{k}.")
      runner.registerValue(k, v)
    end

    runner.registerFinalCondition('Report generated successfully.')

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
BuildingCharacteristicsReport.new.registerWithApplication
