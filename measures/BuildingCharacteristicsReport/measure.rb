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

  #define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    #use the built-in error checking
    unless runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    # Uncomment the line below to debug:
    #runner.registerInfo("past_results: #{runner.past_results.to_s}")

    # Get existing building characteristics
    outputs = runner.past_results[:build_existing_models]
    
    # Update existing building characteristics with upgrade characteristics
    measures_used = 0
    runner.past_results.each do |measure, measure_hash|
        next if not measure_hash.keys.include?(:run_measure)
        next if measure_hash[:run_measure] == 0
        measures_used += 1
        outputs.merge!(measure_hash)
    end
    if measures_used > 1
        runner.registerError("Unexpected error.")
        return false
    end
    
    # These values will show up in the results CSV file when added to 
    # the analysis spreadsheet's Outputs worksheet.
    outputs.each do |k,v|
        runner.registerInfo("Registering #{v.to_s} for #{k.to_s}.")
        runner.registerValue(k.to_s, v.to_s)
    end
    
    runner.registerFinalCondition("Report generated successfully.")

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
BuildingCharacteristicsReport.new.registerWithApplication