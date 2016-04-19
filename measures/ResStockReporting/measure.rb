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

    # Register any key/value pairs other than the keys ignored below.
    # These values will show up in the results CSV file when added to 
    # the analysis spreadsheet's Outputs worksheet.
    ignore_keys = [:source, :applicable, :sample_value, :probability_file, :standard_reports]
    runner.past_results.each do |key,hash|
        next if ignore_keys.include?(key)
        hash.each do |k,v|
            next if ignore_keys.include?(k)
            runner.registerValue(k.to_s, v.to_s)
        end
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ResStockReporting.new.registerWithApplication