# frozen_string_literal: true

# start the measure
class ServerDirectoryCleanup < OpenStudio::Measure::ReportingMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    'Server Directory Cleanup'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    return args
  end # end the arguments method

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find OpenStudio model.')
      return false
    end
    model = model.get

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    Dir.glob('./../*.sql').each do |f|
      File.delete(f)
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../*.audit').each do |f|
      File.delete(f)
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../in.osm').each do |f|
      File.delete(f)
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../*.bnd').each do |f|
      File.delete(f)
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../*.eio').each do |f|
      File.delete(f)
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../*.shd').each do |f|
      File.delete(f)
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../*.mdd').each do |f|
      File.delete(f)
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../*.eso').each do |f|
      File.delete(f)
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../pre-preprocess.idf').each do |f|
      File.delete(f)
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end

    true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ServerDirectoryCleanup.new.registerWithApplication
