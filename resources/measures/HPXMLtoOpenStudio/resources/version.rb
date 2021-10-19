# frozen_string_literal: true

require 'csv'

class Version
  def self.version
    version = {}
    File.open("#{File.dirname(__FILE__)}/../../../__version__.py", 'r') do |file|
      file.each_line do |line|
        key, value = line.split(' = ')
        version[key] = value.chomp.gsub("'", '')
      end
    end
    return version
  end

  def self.software_program_used
    return version['__title__']
  end

  def self.software_program_version
    return version['__resstock_version__']
  end

  def self.check_openstudio_version
    if not OpenStudio.openStudioVersion.start_with? version['__os_version__']
      if version['__os_version__'].count('.') == 2
        fail "OpenStudio version #{version['__os_version__']} is required."
      else
        fail "OpenStudio version #{version['__os_version__']}.X is required."
      end
    end
  end
end
