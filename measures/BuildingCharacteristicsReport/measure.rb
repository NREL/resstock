require 'openstudio'

class BuildingCharacteristicsReport < OpenStudio::Measure::ReportingMeasure
  def name
    return "Building Characteristics Report"
  end

  def description
    return "Reports building characteristics for each simulation."
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end

  def outputs
    result = OpenStudio::Measure::OSOutputVector.new
    # Outputs based on parameters in options_lookup.tsv
    # Note: Not every parameter is used by every project; non-applicable outputs
    #       for a given project can be removed via a server finalization script.
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), "..", "..", "resources"))
    buildstock_file = File.join(resources_dir, "buildstock.rb")
    lookup_file = File.join(resources_dir, "options_lookup.tsv")
    require File.join(File.dirname(buildstock_file), File.basename(buildstock_file, File.extname(buildstock_file)))
    parameters = get_parameters_ordered_from_options_lookup_tsv(lookup_file)
    parameters.each do |parameter|
      result << OpenStudio::Measure::OSOutput.makeStringOutput(OpenStudio::toUnderscoreCase(parameter))
    end
    # Additional hard-coded outputs
    buildstock_outputs = [
      "location_city",
      "location_state",
      "location_latitude",
      "location_longitude",
      "climate_zone_ba",
      "climate_zone_iecc",
      "units_represented",
      "units_modeled"
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
    upgrade_name = get_value_from_runner_past_results(runner, "upgrade_name", "apply_upgrade", false)
    if not upgrade_name.nil?
      runner.registerInfo("Upgrade datapoint, no building characteristics will be reported.")
      return true
    end

    # Get existing building characteristics
    runner.workflow.workflowSteps.each do |step|
      next if not step.result.is_initialized

      step_result = step.result.get
      next if !step_result.measureName.is_initialized or (step_result.measureName.get != "build_existing_model" and step_result.measureName.get != "zone_multipliers")

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

    # Report some additional location and model characteristics

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    weather = WeatherProcess.new(model, runner)
    if !weather.error?
      runner.registerInfo("Registering #{weather.header.City} for location_city.")
      runner.registerValue("location_city", weather.header.City)
      runner.registerInfo("Registering #{weather.header.State} for location_state.")
      runner.registerValue("location_state", weather.header.State)
      runner.registerInfo("Registering #{weather.header.Latitude} for location_latitude.")
      runner.registerValue("location_latitude", weather.header.Latitude)
      runner.registerInfo("Registering #{weather.header.Longitude} for location_longitude.")
      runner.registerValue("location_longitude", weather.header.Longitude)
      climate_zone_ba = Location.get_climate_zone_ba(weather.header.Station)
      climate_zone_iecc = Location.get_climate_zone_iecc(weather.header.Station)
      unless climate_zone_ba.nil?
        runner.registerInfo("Registering #{climate_zone_ba} for climate_zone_ba.")
        runner.registerValue("climate_zone_ba", climate_zone_ba)
      end
      unless climate_zone_iecc.nil?
        runner.registerInfo("Registering #{climate_zone_iecc} for climate_zone_iecc.")
        runner.registerValue("climate_zone_iecc", climate_zone_iecc)
      end
      if climate_zone_ba.nil? and climate_zone_iecc.nil?
        runner.registerInfo("The weather station WMO has not been set appropriately in the EPW weather file header.")
      end
    end

    units_represented = model.getBuilding.additionalProperties.getFeatureAsInteger("Total Units Represented")
    runner.registerInfo("Registering #{units_represented} for units_represented.")
    runner.registerValue("units_represented", "#{units_represented.get}")
    units_modeled = model.getBuilding.additionalProperties.getFeatureAsInteger("Total Units Modeled")
    runner.registerInfo("Registering #{units_modeled} for units_modeled.")
    runner.registerValue("units_modeled", "#{units_modeled.get}")

    runner.registerFinalCondition("Report generated successfully.")

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
BuildingCharacteristicsReport.new.registerWithApplication
