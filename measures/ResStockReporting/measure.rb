require 'openstudio'

class ResStockReporting < OpenStudio::Ruleset::ReportingUserScript

  def name
    "Res Stock Reporting"
  end
  
  def description
    "For the existing housing stock, reports the option name for each parameter. For upgrades, reports the existing building datapoint name associated with each simulation."
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

    # These values will show up in the results CSV file when added to 
    # the analysis spreadsheet's Outputs worksheet.
    if runner.past_results.keys.include?(:rebuild_existing_models)
        # Results for upgrades
        measure_hash = runner.past_results[:rebuild_existing_models]
        measure_hash.each do |k,v|
            runner.registerInfo("Registering #{v.to_s} for #{k.to_s}.")
            runner.registerValue(k.to_s, v.to_s)
        end
    else
        # Results for existing housing stock
        # FIXME: Improve this
        runner.past_results.each do |measure, measure_hash|
            next if not measure_hash.keys.include?(:"ResStock Parameter Name")
            
            parameter_name = measure_hash[:"ResStock Parameter Name"]
            option_name = measure_hash[:"ResStock Option Name"]
            runner.registerInfo("Registering #{option_name} for #{parameter_name}.")
            runner.registerValue(parameter_name, option_name)
        end
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResStockReporting.new.registerWithApplication