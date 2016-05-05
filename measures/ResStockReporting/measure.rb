require 'openstudio'

class ResStockReporting < OpenStudio::Ruleset::ReportingUserScript

  def name
    "Res Stock Reporting"
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
    runner.past_results.each do |key,hash|
        next if not hash.keys.include?(:probability_file)
        
        hash.each do |k,v|
            next if [:source, :applicable, :sample_value, :probability_file].include?(k) # Ignore these keys
            
            probability_file = hash[:probability_file].to_s
            report_name = File.basename(probability_file,File.extname(probability_file)) # Strip off file extension
            report_value = v.to_s
            
            runner.registerInfo("Registering #{report_value} for #{report_name}.")
            runner.registerValue(report_name, report_value)
        end
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResStockReporting.new.registerWithApplication