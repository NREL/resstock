require 'openstudio'

class BuildingCharacteristicsReport < OpenStudio::Ruleset::ReportingUserScript

  def name
    return "Building Characteristics Report"
  end
  
  def description
    return "Reports building characteristics for each simulation."
  end

  #define the arguments that the user will input
  def arguments
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end
  
  def outputs
    # Other building characteristics should be manually entered in PAT
    # since they can vary across different projects (National, PNW, etc.).
    resstock_outputs = [
                        "location_city",
                        "location_state",
                        "location_latitude",
                        "location_longitude",
                       ]
    result = OpenStudio::Measure::OSOutputVector.new
    resstock_outputs.each do |output|
        result << OpenStudio::Measure::OSOutput.makeStringOutput(output)
    end
    return result
  end

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking
    unless runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    # Get existing building characteristics
    runner.workflow.workflowSteps.each do |step|
        next if not step.result.is_initialized
        step_result = step.result.get
        next if !step_result.measureName.is_initialized or step_result.measureName.get != "build_existing_model"
        step_result.stepValues.each do |step_value|
            # These values will show up in the results CSV file when added to 
            # the analysis spreadsheet's Outputs worksheet.
            begin
                # All building characteristics should be strings
                runner.registerInfo("Registering #{step_value.valueAsString} for #{step_value.name}.")
                runner.registerValue(step_value.name,step_value.valueAsString)
            rescue
                runner.registerInfo("Skipping #{step_value.name}.")
            end
        end
    end
    
    # Report some additional location characteristics
    
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError("Cannot find last model.")
      return false
    end
    model = model.get

    weather = WeatherProcess.new(model, runner, File.dirname(__FILE__), header_only=true)
    if weather.error?
      return false
    end

    runner.registerInfo("Registering #{weather.header.City} for location_city.")
    runner.registerValue("location_city", weather.header.City)
    runner.registerInfo("Registering #{weather.header.State} for location_state.")
    runner.registerValue("location_state", weather.header.State)
    runner.registerInfo("Registering #{weather.header.Latitude} for location_latitude.")
    runner.registerValue("location_latitude", weather.header.Latitude)
    runner.registerInfo("Registering #{weather.header.Longitude} for location_longitude.")
    runner.registerValue("location_longitude", weather.header.Longitude)
    
    runner.registerFinalCondition("Report generated successfully.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
BuildingCharacteristicsReport.new.registerWithApplication