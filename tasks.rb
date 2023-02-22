# frozen_string_literal: true

def download_epws
  require_relative 'resources/hpxml-measures/HPXMLtoOpenStudio/resources/util'

  require 'tempfile'
  tmpfile = Tempfile.new('epw')

  UrlResolver.fetch('https://data.nrel.gov/system/files/156/BuildStock_TMY3_FIPS.zip', tmpfile)

  puts 'Extracting weather files...'
  require 'zip'
  weather_dir = File.join(File.dirname(__FILE__), 'weather')
  Zip.on_exists_proc = true
  Zip::File.open(tmpfile.path.to_s) do |zip_file|
    zip_file.each do |f|
      zip_file.extract(f, File.join(weather_dir, f.name))
    end
  end

  num_epws_actual = Dir[File.join(weather_dir, '*.epw')].count
  puts "#{num_epws_actual} weather files are available in the weather directory."
  puts 'Completed.'
  exit!
end

command_list = [:update_measures, :integrity_check_national, :integrity_check_testing, :download_weather]

def display_usage(command_list)
  puts "Usage: openstudio #{File.basename(__FILE__)} [COMMAND]\nCommands:\n  " + command_list.join("\n  ")
end

if ARGV.size == 0
  puts 'ERROR: Missing command.'
  display_usage(command_list)
  exit!
elsif ARGV.size > 1
  puts 'ERROR: Too many commands.'
  display_usage(command_list)
  exit!
elsif not command_list.include? ARGV[0].to_sym
  puts "ERROR: Invalid command '#{ARGV[0]}'."
  display_usage(command_list)
  exit!
end

if ARGV[0].to_sym == :update_measures
  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? && ENV['HOME'].start_with?('U:')
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? && ENV['HOMEDRIVE'].start_with?('U:')

  # Apply rubocop
  cops = ['Layout',
          'Lint/DeprecatedClassMethods',
          'Lint/DuplicateElsifCondition',
          'Lint/DuplicateHashKey',
          'Lint/DuplicateMethods',
          'Lint/InterpolationCheck',
          'Lint/LiteralAsCondition',
          'Lint/RedundantStringCoercion',
          'Lint/SelfAssignment',
          'Lint/UnderscorePrefixedVariableName',
          'Lint/UnusedBlockArgument',
          'Lint/UnusedMethodArgument',
          'Lint/UselessAssignment',
          'Style/AndOr',
          'Style/FrozenStringLiteralComment',
          'Style/HashSyntax',
          'Style/Next',
          'Style/NilComparison',
          'Style/RedundantParentheses',
          'Style/RedundantSelf',
          'Style/ReturnNil',
          'Style/SelfAssignment',
          'Style/StringLiterals',
          'Style/StringLiteralsInInterpolation']
  commands = ["\"require 'rubocop/rake_task' \"",
              "\"RuboCop::RakeTask.new(:rubocop) do |t| t.options = ['--auto-correct', '--format', 'simple', '--only', '#{cops.join(',')}'] end\"",
              '"Rake.application[:rubocop].invoke"']
  command = "#{OpenStudio.getOpenStudioCLI} -e #{commands.join(' -e ')}"
  puts 'Applying rubocop auto-correct to measures...'
  system(command)

  # Update measures XMLs
  command = "#{OpenStudio.getOpenStudioCLI} measure -t '#{File.join(File.dirname(__FILE__), 'measures')}'"
  puts 'Updating measure.xmls...'
  system(command, [:out, :err] => File::NULL)

  puts 'Done.'
end

if ARGV[0].to_sym == :integrity_check_national
  require_relative 'test/integrity_checks'

  project_dir_name = 'project_national'
  integrity_check(project_dir_name)
  integrity_check_options_lookup_tsv(project_dir_name)
end

if ARGV[0].to_sym == :integrity_check_testing
  require_relative 'test/integrity_checks'

  project_dir_name = 'project_testing'
  integrity_check(project_dir_name)
  integrity_check_options_lookup_tsv(project_dir_name)
end

if ARGV[0].to_sym == :download_weather
  download_epws
end
