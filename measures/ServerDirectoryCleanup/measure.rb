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

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('in_osm', true)
    arg.setDisplayName('Retain in.osm')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('in_idf', true)
    arg.setDisplayName('Retain in.idf')
    arg.setDefaultValue(true)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('pre_process_idf', true)
    arg.setDisplayName('Retain eplusout.bnd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_audit', true)
    arg.setDisplayName('Retain eplusout.audit')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_bnd', true)
    arg.setDisplayName('Retain eplusout.bnd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_eio', true)
    arg.setDisplayName('Retain eplusout.bnd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_end', true)
    arg.setDisplayName('Retain eplusout.end')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_err', true)
    arg.setDisplayName('Retain eplusout.err')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_eso', true)
    arg.setDisplayName('Retain eplusout.bnd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_mdd', true)
    arg.setDisplayName('Retain eplusout.bnd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_mtd', true)
    arg.setDisplayName('Retain eplusout.mtd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_rdd', true)
    arg.setDisplayName('Retain eplusout.rdd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_shd', true)
    arg.setDisplayName('Retain eplusout.bnd')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplusout_sql', true)
    arg.setDisplayName('eplusout.sql')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('eplustbl_htm', true)
    arg.setDisplayName('Retain eplustbl.htm')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('sqlite_err', true)
    arg.setDisplayName('Retain sqlite.err.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('stdout_energyplus', true)
    arg.setDisplayName('Retain stdout-energyplus')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('stdout_expandobject', true)
    arg.setDisplayName('Retain stdout-expandobject.')
    arg.setDefaultValue(false)
    args << arg

    arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument('schedules_csv', true)
    arg.setDisplayName('Retain schedules.csv.')
    arg.setDefaultValue(true)
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

    in_osm = runner.getBoolArgumentValue('in_osm', user_arguments)
    in_idf = runner.getBoolArgumentValue('in_idf', user_arguments)
    pre_process_idf = runner.getBoolArgumentValue('pre_process_idf', user_arguments)
    eplusout_audit = runner.getBoolArgumentValue('eplusout_audit', user_arguments)
    eplusout_bnd = runner.getBoolArgumentValue('eplusout_bnd', user_arguments)
    eplusout_eio = runner.getBoolArgumentValue('eplusout_eio', user_arguments)
    eplusout_end = runner.getBoolArgumentValue('eplusout_end', user_arguments)
    eplusout_err = runner.getBoolArgumentValue('eplusout_err', user_arguments)
    eplusout_eso = runner.getBoolArgumentValue('eplusout_eso', user_arguments)
    eplusout_mdd = runner.getBoolArgumentValue('eplusout_mdd', user_arguments)
    eplusout_mtd = runner.getBoolArgumentValue('eplusout_mtd', user_arguments)
    eplusout_rdd = runner.getBoolArgumentValue('eplusout_rdd', user_arguments)
    eplusout_shd = runner.getBoolArgumentValue('eplusout_shd', user_arguments)
    eplusout_sql = runner.getBoolArgumentValue('eplusout_sql', user_arguments)
    eplustbl_htm = runner.getBoolArgumentValue('eplustbl_htm', user_arguments)
    sqlite_err = runner.getBoolArgumentValue('sqlite_err', user_arguments)
    stdout_energyplus = runner.getBoolArgumentValue('stdout_energyplus', user_arguments)
    stdout_expandobject = runner.getBoolArgumentValue('stdout_expandobject', user_arguments)
    schedules_csv = runner.getBoolArgumentValue('schedules_csv', user_arguments)

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
    Dir.glob('./../eplusout.sql').each do |f|
      File.delete(f) unless eplusout_sql
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
    Dir.glob('./../eplusout.shd').each do |f|
      File.delete(f) unless eplusout_shd
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../eplustbl.htm').each do |f|
      File.delete(f) unless eplustbl_htm
      runner.registerInfo("Deleted #{f} from the run directory.") if !File.exist?(f)
    end
    Dir.glob('./../sqlite.err').each do |f|
      File.delete(f) unless sqlite_err
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
