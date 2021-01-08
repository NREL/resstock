# frozen_string_literal: true

class Constants
  def self.excludes
    # don't make these BuildResidentialHPXML arguments into ResStockArguments arguments
    return ['hpxml_path',
            'software_program_used',
            'software_program_version',
            'setpoint_heating_weekday',
            'setpoint_heating_weekend',
            'setpoint_cooling_weekday',
            'setpoint_cooling_weekend',
            'geometry_has_flue_or_chimney']
  end
end
