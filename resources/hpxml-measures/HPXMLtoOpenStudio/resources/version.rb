# frozen_string_literal: true

class Version
  OS_HPXML_Version = '0.10.0' # Version of the OS-HPXML workflow
  OS_Version = '3.0' # Required version of OpenStudio (can be 'X.X' or 'X.X.X')

  def self.check_openstudio_version
    if not OpenStudio.openStudioVersion.start_with? OS_Version
      if OS_Version.count('.') == 2
        fail "OpenStudio version #{OS_Version} is required."
      else
        fail "OpenStudio version #{OS_Version}.X is required."
      end
    end
  end
end
