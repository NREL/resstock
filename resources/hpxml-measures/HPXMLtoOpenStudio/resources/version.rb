# frozen_string_literal: true

class Version
  OS_HPXML_Version = '1.6.0' # Version of the OS-HPXML workflow
  OS_Version = '3.6.1' # Required version of OpenStudio (can be 'X.X' or 'X.X.X')
  HPXML_Version = '4.0' # HPXML schemaVersion

  def self.check_openstudio_version
    if not OpenStudio.openStudioVersion.start_with? OS_Version
      if OS_Version.count('.') == 2
        fail "OpenStudio version #{OS_Version} is required. Found version: #{OpenStudio.openStudioVersion}"
      else
        fail "OpenStudio version #{OS_Version}.X is required. Found version: #{OpenStudio.openStudioVersion}"
      end
    end
  end

  def self.check_hpxml_version(hpxml_version)
    if hpxml_version != HPXML_Version
      fail "HPXML version #{HPXML_Version} is required."
    end
  end
end
