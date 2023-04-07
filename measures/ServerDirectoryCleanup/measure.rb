# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ServerDirectoryCleanup < OpenStudio::Measure::ReportingMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    'Server Directory Cleanup'
  end

  # human readable description
  def description
    return 'Optionally removes a significant portion of the saved results from each run, helping to alleviate memory problems.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Present a bunch of bool arguments corresponding to EnergyPlus output files. "False" deletes the file, and "True" retains it. Most arguments default to not retaining the file. Only the in.idf and schedules.csv are retained by default.'
  end

  # define the arguments that the user will input
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    args = OpenStudio::Ruleset::OSArgumentVector.new

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_in_osm', true)
    arg.setDisplayName('Retain in.osm')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_in_idf', true)
    arg.setDisplayName('Retain in.idf')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_pre_process_idf', true)
    arg.setDisplayName('Retain pre_process.idf')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_audit', true)
    arg.setDisplayName('Retain eplusout.audit')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_bnd', true)
    arg.setDisplayName('Retain eplusout.bnd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_eio', true)
    arg.setDisplayName('Retain eplusout.eio')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_end', true)
    arg.setDisplayName('Retain eplusout.end')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_err', true)
    arg.setDisplayName('Retain eplusout.err')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_eso', true)
    arg.setDisplayName('Retain eplusout.eso')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_mdd', true)
    arg.setDisplayName('Retain eplusout.mdd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_mtd', true)
    arg.setDisplayName('Retain eplusout.mtd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_rdd', true)
    arg.setDisplayName('Retain eplusout.rdd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_shd', true)
    arg.setDisplayName('Retain eplusout.shd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplusout_msgpack', true)
    arg.setDisplayName('Retain eplusout.msgpack')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_eplustbl_htm', true)
    arg.setDisplayName('Retain eplustbl.htm')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_stdout_energyplus', true)
    arg.setDisplayName('Retain stdout-energyplus')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_stdout_expandobject', true)
    arg.setDisplayName('Retain stdout-expandobject.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('retain_schedules_csv', true)
    arg.setDisplayName('Retain schedules.csv.')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Measure::OSArgument.makeBoolArgument('debug', false)
    arg.setDisplayName('Debug Mode?')
    arg.setDescription('If true, retain all files.')
    arg.setDefaultValue(false)
    args << arg

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

    in_osm = runner.getBoolArgumentValue('retain_in_osm', user_arguments)
    in_idf = runner.getBoolArgumentValue('retain_in_idf', user_arguments)
    pre_process_idf = runner.getBoolArgumentValue('retain_pre_process_idf', user_arguments)
    eplusout_audit = runner.getBoolArgumentValue('retain_eplusout_audit', user_arguments)
    eplusout_bnd = runner.getBoolArgumentValue('retain_eplusout_bnd', user_arguments)
    eplusout_eio = runner.getBoolArgumentValue('retain_eplusout_eio', user_arguments)
    eplusout_end = runner.getBoolArgumentValue('retain_eplusout_end', user_arguments)
    eplusout_err = runner.getBoolArgumentValue('retain_eplusout_err', user_arguments)
    eplusout_eso = runner.getBoolArgumentValue('retain_eplusout_eso', user_arguments)
    eplusout_mdd = runner.getBoolArgumentValue('retain_eplusout_mdd', user_arguments)
    eplusout_mtd = runner.getBoolArgumentValue('retain_eplusout_mtd', user_arguments)
    eplusout_rdd = runner.getBoolArgumentValue('retain_eplusout_rdd', user_arguments)
    eplusout_shd = runner.getBoolArgumentValue('retain_eplusout_shd', user_arguments)
    eplusout_msgpack = runner.getBoolArgumentValue('retain_eplusout_msgpack', user_arguments)
    eplustbl_htm = runner.getBoolArgumentValue('retain_eplustbl_htm', user_arguments)
    stdout_energyplus = runner.getBoolArgumentValue('retain_stdout_energyplus', user_arguments)
    stdout_expandobject = runner.getBoolArgumentValue('retain_stdout_expandobject', user_arguments)
    schedules_csv = runner.getBoolArgumentValue('retain_schedules_csv', user_arguments)
    debug = runner.getBoolArgumentValue('debug', user_arguments)

    if debug
      in_osm = in_idf = pre_process_idf = eplusout_audit = eplusout_bnd = eplusout_eio = eplusout_end = eplusout_err = eplusout_eso = eplusout_mdd = eplusout_mtd = eplusout_rdd = eplusout_shd = eplusout_msgpack = stdout_energyplus = stdout_expandobject = schedules_csv = true
    end

    Dir.glob('./../in.osm').each do |f|
      File.delete(f) unless in_osm
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../in.idf').each do |f|
      File.delete(f) unless in_idf
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../pre-preprocess.idf').each do |f|
      File.delete(f) unless pre_process_idf
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout.audit').each do |f|
      File.delete(f) unless eplusout_audit
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout.bnd').each do |f|
      File.delete(f) unless eplusout_bnd
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout.eio').each do |f|
      File.delete(f) unless eplusout_eio
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout.end').each do |f|
      File.delete(f) unless eplusout_end
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout.err').each do |f|
      File.delete(f) unless eplusout_err
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout.eso').each do |f|
      File.delete(f) unless eplusout_eso
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout.mdd').each do |f|
      File.delete(f) unless eplusout_mdd
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout.mtd').each do |f|
      File.delete(f) unless eplusout_mtd
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout.rdd').each do |f|
      File.delete(f) unless eplusout_rdd
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout.shd').each do |f|
      File.delete(f) unless eplusout_shd
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplusout*.msgpack').each do |f|
      File.delete(f) unless eplusout_msgpack
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplustbl.htm').each do |f|
      File.delete(f) unless eplustbl_htm
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../stdout-energyplus').each do |f|
      File.delete(f) unless stdout_energyplus
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../stdout-expandobject').each do |f|
      File.delete(f) unless stdout_expandobject
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../schedules.csv').each do |f|
      File.delete(f) unless schedules_csv
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end

    true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
ServerDirectoryCleanup.new.registerWithApplication
