# frozen_string_literal: true

# Require all gems up front; this is much faster than multiple resource
# files lazy loading as needed, as it prevents multiple lookups for the
# same gem.
require 'openstudio'
require 'pathname'
require 'csv'
require 'oga'
Dir["#{File.dirname(__FILE__)}/resources/*.rb"].each do |resource_file|
  require resource_file
end
Dir["#{File.dirname(__FILE__)}/../HPXMLtoOpenStudio/resources/*.rb"].each do |resource_file|
  next if resource_file.include? 'minitest_helper.rb'

  require resource_file
end

# start the measure
class BuildResidentialHPXML < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'HPXML Builder'
  end

  # human readable description
  def description
    return 'Builds a residential HPXML file.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "The measure handles geometry by 1) translating high-level geometry inputs (conditioned floor area, number of stories, etc.) to 3D closed-form geometry in an OpenStudio model and then 2) mapping the OpenStudio surfaces to HPXML surfaces (using surface type, boundary condition, area, orientation, etc.). Like surfaces are collapsed into a single surface with aggregate surface area. Note: OS-HPXML default values can be found in the documentation or can be seen by using the 'apply_defaults' argument."
  end

  # Define the arguments that the user will input.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @return [OpenStudio::Measure::OSArgumentVector] an OpenStudio::Measure::OSArgumentVector object
  def arguments(model) # rubocop:disable Lint/UnusedMethodArgument
    docs_base_url = "https://openstudio-hpxml.readthedocs.io/en/v#{Version::OS_HPXML_Version}/workflow_inputs.html"

    # TODO
    def makeArgument(name:,
                     type:,
                     required:,
                     display_name:,
                     description:,
                     units: nil,
                     choices: [],
                     default_href: nil)

      fail "Specified #{type} argument with no choices." if type == Argument::Choice && choices.empty?
      fail 'Specified required argument with indication of OS-HPXML default.' if required && !default_href.nil?

      if !default_href.nil?
        if type == Argument::Boolean
          choices = ['true', 'false']
          type = Argument::Choice
        elsif [Argument::Double, Argument::Integer].include?(type)
          type = Argument::String
        end
      end

      if choices.empty?
        arg = OpenStudio::Measure::OSArgument.send(type, name, required)
      else
        if !default_href.nil?
          choices.unshift(Constants::Auto)
        end
        arg = OpenStudio::Measure::OSArgument.send(type, name, choices, required)
      end
      arg.setDisplayName(display_name)
      arg.setUnits(units) if !units.nil?
      if !default_href.nil?
        description += " If #{Constants::Auto} or not provided, the OS-HPXML default (see #{default_href}) is used."
      end
      arg.setDescription(description)
      return arg
    end

    args = OpenStudio::Measure::OSArgumentVector.new

    args << makeArgument(
      name: 'hpxml_path',
      type: Argument::String,
      required: true,
      display_name: 'HPXML File Path',
      description: 'Absolute/relative path of the HPXML file.'
    )

    args << makeArgument(
      name: 'existing_hpxml_path',
      type: Argument::String,
      required: false,
      display_name: 'Existing HPXML File Path',
      description: 'Absolute/relative path of the existing HPXML file. If not provided, a new HPXML file with one Building element is created. If provided, a new Building element will be appended to this HPXML file (e.g., to create a multifamily HPXML file describing multiple dwelling units).'
    )

    args << makeArgument(
      name: 'whole_sfa_or_mf_building_sim',
      type: Argument::Boolean,
      required: false,
      display_name: 'Whole SFA/MF Building Simulation?',
      description: 'If the HPXML file represents a single family-attached/multifamily building with multiple dwelling units defined, specifies whether to run the HPXML file as a single whole building model.'
    )

    args << makeArgument(
      name: 'software_info_program_used',
      type: Argument::String,
      required: false,
      display_name: 'Software Info: Program Used',
      description: 'The name of the software program used.'
    )

    args << makeArgument(
      name: 'software_info_program_version',
      type: Argument::String,
      required: false,
      display_name: 'Software Info: Program Version',
      description: 'The version of the software program used.'
    )

    args << makeArgument(
      name: 'schedules_filepaths',
      type: Argument::String,
      required: false,
      display_name: 'Schedules: CSV File Paths',
      description: 'Absolute/relative paths of csv files containing user-specified detailed schedules. If multiple files, use a comma-separated list.'
    )

    args << makeArgument(
      name: 'schedules_unavailable_period_types',
      type: Argument::String,
      required: false,
      display_name: 'Schedules: Unavailable Period Types',
      description: "Specifies the unavailable period types. Possible types are column names defined in unavailable_periods.csv: #{Schedule.unavailable_period_types.join(', ')}. If multiple periods, use a comma-separated list."
    )

    args << makeArgument(
      name: 'schedules_unavailable_period_dates',
      type: Argument::String,
      required: false,
      display_name: 'Schedules: Unavailable Period Dates',
      description: 'Specifies the unavailable period date ranges. Enter a date range like "Dec 15 - Jan 15". Optionally, can enter hour of the day like "Dec 15 2 - Jan 15 20" (start hour can be 0 through 23 and end hour can be 1 through 24). If multiple periods, use a comma-separated list.'
    )

    args << makeArgument(
      name: 'schedules_unavailable_period_window_natvent_availabilities',
      type: Argument::String,
      required: false,
      display_name: 'Schedules: Unavailable Period Window Natural Ventilation Availabilities',
      description: "The availability of the natural ventilation schedule during unavailable periods. Valid choices are: #{[HPXML::ScheduleRegular, HPXML::ScheduleAvailable, HPXML::ScheduleUnavailable].join(', ')}. If multiple periods, use a comma-separated list.",
      default_href: "<a href='#{docs_base_url}#hpxml-unavailable-periods'>HPXML Unavailable Periods</a>"
    )

    args << makeArgument(
      name: 'simulation_control_timestep',
      type: Argument::Integer,
      required: false,
      display_name: 'Simulation Control: Timestep',
      description: 'Value must be a divisor of 60.',
      units: 'min',
      default_href: "<a href='#{docs_base_url}#hpxml-simulation-control'>HPXML Simulation Control</a>"
    )

    args << makeArgument(
      name: 'simulation_control_run_period',
      type: Argument::String,
      required: false,
      display_name: 'Simulation Control: Run Period',
      description: "Enter a date range like 'Jan 1 - Dec 31'. If not provided, the OS-HPXML default (see <a href='#{docs_base_url}#hpxml-simulation-control'>HPXML Simulation Control</a>) is used."
    )

    args << makeArgument(
      name: 'simulation_control_run_period_calendar_year',
      type: Argument::Integer,
      required: false,
      display_name: 'Simulation Control: Run Period Calendar Year',
      units: 'year',
      description: 'This numeric field should contain the calendar year that determines the start day of week. If you are running simulations using AMY weather files, the value entered for calendar year will not be used; it will be overridden by the actual year found in the AMY weather file.',
      default_href: "<a href='#{docs_base_url}#hpxml-simulation-control'>HPXML Simulation Control</a>"
    )

    args << makeArgument(
      name: 'simulation_control_daylight_saving_enabled',
      type: Argument::Boolean,
      required: false,
      display_name: 'Simulation Control: Daylight Saving Enabled',
      description: 'Whether to use daylight saving.',
      default_href: "<a href='#{docs_base_url}#hpxml-building-site'>HPXML Building Site</a>"
    )

    args << makeArgument(
      name: 'simulation_control_daylight_saving_period',
      type: Argument::String,
      required: false,
      display_name: 'Simulation Control: Daylight Saving Period',
      description: "Enter a date range like 'Mar 15 - Dec 15'.",
      default_href: "<a href='#{docs_base_url}#hpxml-building-site'>HPXML Building Site</a>"
    )

    args << makeArgument(
      name: 'simulation_control_temperature_capacitance_multiplier',
      type: Argument::Double,
      required: false,
      display_name: 'Simulation Control: Temperature Capacitance Multiplier',
      description: 'Affects the transient calculation of indoor air temperatures.',
      default_href: "<a href='#{docs_base_url}#hpxml-simulation-control'>HPXML Simulation Control</a>"
    )

    defrost_model_type_choices = OpenStudio::StringVector.new
    defrost_model_type_choices << HPXML::AdvancedResearchDefrostModelTypeStandard
    defrost_model_type_choices << HPXML::AdvancedResearchDefrostModelTypeAdvanced

    args << makeArgument(
      name: 'simulation_control_defrost_model_type',
      type: Argument::Choice,
      required: false,
      display_name: 'Simulation Control: Defrost Model Type',
      description: "Research feature to select the type of defrost model. Use #{HPXML::AdvancedResearchDefrostModelTypeStandard} for default E+ defrost setting. Use #{HPXML::AdvancedResearchDefrostModelTypeAdvanced} for an improved model that better accounts for load and energy use during defrost; using #{HPXML::AdvancedResearchDefrostModelTypeAdvanced} may impact simulation runtime.",
      choices: defrost_model_type_choices,
      default_href: "<a href='#{docs_base_url}#hpxml-simulation-control'>HPXML Simulation Control</a>"
    )

    args << makeArgument(
      name: 'simulation_control_onoff_thermostat_deadband',
      type: Argument::Double,
      required: false,
      display_name: 'Simulation Control: HVAC On-Off Thermostat Deadband',
      description: 'Research feature to model on-off thermostat deadband and start-up degradation for single or two speed AC/ASHP systems, and realistic time-based staging for two speed AC/ASHP systems. Currently only supported with 1 min timestep.',
      units: 'deg-F'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'simulation_control_heat_pump_backup_heating_capacity_increment',
      required: false,
      display_name: 'Simulation Control: Heat Pump Backup Heating Capacity Increment',
      description: "Research feature to model capacity increment of multi-stage heat pump backup systems with time-based staging. Only applies to air-source heat pumps where Backup Type is '#{HPXML::HeatPumpBackupTypeIntegrated}' and Backup Fuel Type is '#{HPXML::FuelTypeElectricity}'. Currently only supported with 1 min timestep.",
      units: 'Btu/hr'
    )

    site_type_choices = OpenStudio::StringVector.new
    site_type_choices << HPXML::SiteTypeSuburban
    site_type_choices << HPXML::SiteTypeUrban
    site_type_choices << HPXML::SiteTypeRural

    args << makeArgument(
      type: Argument::Choice,
      name: 'site_type',
      choices: site_type_choices,
      required: false,
      display_name: 'Site: Type',
      description: 'The type of site.',
      default_href: "<a href='#{docs_base_url}#hpxml-site'>HPXML Site</a>"
    )

    site_shielding_of_home_choices = OpenStudio::StringVector.new
    site_shielding_of_home_choices << HPXML::ShieldingExposed
    site_shielding_of_home_choices << HPXML::ShieldingNormal
    site_shielding_of_home_choices << HPXML::ShieldingWellShielded

    args << makeArgument(
      type: Argument::Choice,
      name: 'site_shielding_of_home',
      choices: site_shielding_of_home_choices,
      required: false,
      display_name: 'Site: Shielding of Home',
      description: 'Presence of nearby buildings, trees, obstructions for infiltration model.',
      default_href: "<a href='#{docs_base_url}#hpxml-site'>HPXML Site</a>"
    )

    soil_types = [HPXML::SiteSoilTypeClay,
                  HPXML::SiteSoilTypeGravel,
                  HPXML::SiteSoilTypeLoam,
                  HPXML::SiteSoilTypeSand,
                  HPXML::SiteSoilTypeSilt,
                  HPXML::SiteSoilTypeUnknown]

    moisture_types = [HPXML::SiteSoilMoistureTypeDry,
                      HPXML::SiteSoilMoistureTypeMixed,
                      HPXML::SiteSoilMoistureTypeWet]

    site_soil_and_moisture_type_choices = OpenStudio::StringVector.new
    soil_types.each do |soil_type|
      moisture_types.each do |moisture_type|
        site_soil_and_moisture_type_choices << "#{soil_type}, #{moisture_type}"
      end
    end

    args << makeArgument(
      type: Argument::Choice,
      name: 'site_soil_and_moisture_type',
      choices: site_soil_and_moisture_type_choices,
      required: false,
      display_name: 'Site: Soil and Moisture Type',
      description: 'Type of soil and moisture. This is used to inform ground conductivity and diffusivity.',
      default_href: "<a href='#{docs_base_url}#hpxml-site'>HPXML Site</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'site_ground_conductivity',
      required: false,
      display_name: 'Site: Ground Conductivity',
      description: 'Conductivity of the ground soil. If provided, overrides the previous site and moisture type input.',
      units: 'Btu/hr-ft-F'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'site_ground_diffusivity',
      required: false,
      display_name: 'Site: Ground Diffusivity',
      description: 'Diffusivity of the ground soil. If provided, overrides the previous site and moisture type input.',
      units: 'ft^2/hr'
    )

    site_iecc_zone_choices = OpenStudio::StringVector.new
    Constants::IECCZones.each do |iz|
      site_iecc_zone_choices << iz
    end

    args << makeArgument(
      type: Argument::Choice,
      name: 'site_iecc_zone',
      choices: site_iecc_zone_choices,
      required: false,
      display_name: 'Site: IECC Zone',
      description: 'IECC zone of the home address.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'site_city',
      required: false,
      display_name: 'Site: City',
      description: 'City/municipality of the home address.'
    )

    site_state_code_choices = OpenStudio::StringVector.new
    Constants::StateCodesMap.keys.each do |sc|
      site_state_code_choices << sc
    end

    args << makeArgument(
      type: Argument::Choice,
      name: 'site_state_code',
      choices: site_state_code_choices,
      required: false,
      display_name: 'Site: State Code',
      description: 'State code of the home address.',
      default_href: "<a href='#{docs_base_url}#hpxml-site'>HPXML Site</a>"
    )

    args << makeArgument(
      type: Argument::String,
      name: 'site_zip_code',
      required: false,
      display_name: 'Site: Zip Code',
      description: 'Zip code of the home address. Either this or the Weather Station: EnergyPlus Weather (EPW) Filepath input below must be provided.'
    )

    args << makeArgument(
      name: 'site_time_zone_utc_offset',
      type: Argument::Double,
      required: false,
      display_name: 'Site: Time Zone UTC Offset',
      description: 'Time zone UTC offset of the home address. Must be between -12 and 14.',
      units: 'hr',
      default_href: "<a href='#{docs_base_url}#hpxml-site'>HPXML Site</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'site_elevation',
      required: false,
      display_name: 'Site: Elevation',
      description: 'Elevation of the home address.',
      units: 'ft',
      default_href: "<a href='#{docs_base_url}#hpxml-site'>HPXML Site</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'site_latitude',
      required: false,
      display_name: 'Site: Latitude',
      description: 'Latitude of the home address. Must be between -90 and 90. Use negative values for southern hemisphere.',
      units: 'deg',
      default_href: "<a href='#{docs_base_url}#hpxml-site'>HPXML Site</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'site_longitude',
      required: false,
      display_name: 'Site: Longitude',
      description: 'Longitude of the home address. Must be between -180 and 180. Use negative values for the western hemisphere.',
      units: 'deg',
      default_href: "<a href='#{docs_base_url}#hpxml-site'>HPXML Site</a>"
    )

    args << makeArgument(
      type: Argument::String,
      name: 'weather_station_epw_filepath',
      required: false,
      display_name: 'Weather Station: EnergyPlus Weather (EPW) Filepath',
      description: 'Path of the EPW file. Either this or the Site: Zip Code input above must be provided.'
    )

    args << makeArgument(
      name: 'year_built',
      type: Argument::Integer,
      required: false,
      display_name: 'Building Construction: Year Built',
      description: 'The year the building was built.'
    )

    unit_type_choices = OpenStudio::StringVector.new
    unit_type_choices << HPXML::ResidentialTypeSFD
    unit_type_choices << HPXML::ResidentialTypeSFA
    unit_type_choices << HPXML::ResidentialTypeApartment
    unit_type_choices << HPXML::ResidentialTypeManufactured

    args << makeArgument(
      type: Argument::Integer,
      name: 'unit_multiplier',
      required: false,
      display_name: 'Building Construction: Unit Multiplier',
      description: 'The number of similar dwelling units. EnergyPlus simulation results will be multiplied this value. If not provided, defaults to 1.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'geometry_unit_type',
      choices: unit_type_choices,
      required: true,
      display_name: 'Geometry: Unit Type',
      description: "The type of dwelling unit. Use #{HPXML::ResidentialTypeSFA} for a dwelling unit with 1 or more stories, attached units to one or both sides, and no units above/below. Use #{HPXML::ResidentialTypeApartment} for a dwelling unit with 1 story, attached units to one, two, or three sides, and units above and/or below."
    )

    args << makeArgument(
      name: 'geometry_unit_left_wall_is_adiabatic',
      type: Argument::Boolean,
      required: false,
      display_name: 'Geometry: Unit Left Wall Is Adiabatic',
      description: 'Presence of an adiabatic left wall.'
    )

    args << makeArgument(
      name: 'geometry_unit_right_wall_is_adiabatic',
      type: Argument::Boolean,
      required: false,
      display_name: 'Geometry: Unit Right Wall Is Adiabatic',
      description: 'Presence of an adiabatic right wall.'
    )

    args << makeArgument(
      name: 'geometry_unit_front_wall_is_adiabatic',
      type: Argument::Boolean,
      required: false,
      display_name: 'Geometry: Unit Front Wall Is Adiabatic',
      description: 'Presence of an adiabatic front wall, for example, the unit is adjacent to a conditioned corridor.'
    )

    args << makeArgument(
      name: 'geometry_unit_back_wall_is_adiabatic',
      type: Argument::Boolean,
      required: false,
      display_name: 'Geometry: Unit Back Wall Is Adiabatic',
      description: 'Presence of an adiabatic back wall.'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'geometry_unit_num_floors_above_grade',
      required: true,
      display_name: 'Geometry: Unit Number of Floors Above Grade',
      units: '#',
      description: "The number of floors above grade in the unit. Attic type #{HPXML::AtticTypeConditioned} is included. Assumed to be 1 for #{HPXML::ResidentialTypeApartment}s."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_unit_cfa',
      required: true,
      display_name: 'Geometry: Unit Conditioned Floor Area',
      units: 'ft^2',
      description: "The total floor area of the unit's conditioned space (including any conditioned basement floor area)."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_unit_aspect_ratio',
      required: true,
      display_name: 'Geometry: Unit Aspect Ratio',
      units: 'Frac',
      description: 'The ratio of front/back wall length to left/right wall length for the unit, excluding any protruding garage wall area.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_unit_orientation',
      required: true,
      display_name: 'Geometry: Unit Orientation',
      units: 'degrees',
      description: "The unit's orientation is measured clockwise from north (e.g., North=0, East=90, South=180, West=270)."
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'geometry_unit_num_bedrooms',
      required: true,
      display_name: 'Geometry: Unit Number of Bedrooms',
      units: '#',
      description: 'The number of bedrooms in the unit.'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'geometry_unit_num_bathrooms',
      required: false,
      display_name: 'Geometry: Unit Number of Bathrooms',
      units: '#',
      description: 'The number of bathrooms in the unit.',
      default_href: "<a href='#{docs_base_url}#hpxml-building-construction'>HPXML Building Construction</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_unit_num_occupants',
      required: false,
      display_name: 'Geometry: Unit Number of Occupants',
      units: '#',
      description: 'The number of occupants in the unit. If not provided, an *asset* calculation is performed assuming standard occupancy, in which various end use defaults (e.g., plug loads, appliances, and hot water usage) are calculated based on Number of Bedrooms and Conditioned Floor Area per ANSI/RESNET/ICC 301-2019. If provided, an *operational* calculation is instead performed in which the end use defaults are adjusted using the relationship between Number of Bedrooms and Number of Occupants from RECS 2015.'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'geometry_building_num_units',
      required: false,
      display_name: 'Geometry: Building Number of Units',
      units: '#',
      description: "The number of units in the building. Required for #{HPXML::ResidentialTypeSFA} and #{HPXML::ResidentialTypeApartment}s."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_average_ceiling_height',
      required: true,
      display_name: 'Geometry: Average Ceiling Height',
      units: 'ft',
      description: 'Average distance from the floor to the ceiling.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_unit_height_above_grade',
      required: false,
      display_name: 'Geometry: Unit Height Above Grade',
      units: 'ft',
      description: 'Describes the above-grade height of apartment units on upper floors or homes above ambient or belly-and-wing foundations. It is defined as the height of the lowest conditioned floor above grade and is used to calculate the wind speed for the infiltration model.',
      default_href: "<a href='#{docs_base_url}#hpxml-building-construction'>HPXML Building Construction</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_garage_width',
      required: false,
      display_name: 'Geometry: Garage Width',
      units: 'ft',
      description: "The width of the garage. Only applies to #{HPXML::ResidentialTypeSFD} units. If not provided, defaults to zero (no garage)."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_garage_depth',
      required: false,
      display_name: 'Geometry: Garage Depth',
      units: 'ft',
      description: "The depth of the garage. Only applies to #{HPXML::ResidentialTypeSFD} units."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_garage_protrusion',
      required: false,
      display_name: 'Geometry: Garage Protrusion',
      units: 'Frac',
      description: "The fraction of the garage that is protruding from the conditioned space. Only applies to #{HPXML::ResidentialTypeSFD} units."
    )

    garage_position_choices = OpenStudio::StringVector.new
    garage_position_choices << Constants::PositionRight
    garage_position_choices << Constants::PositionLeft

    args << makeArgument(
      type: Argument::Choice,
      name: 'geometry_garage_position',
      choices: garage_position_choices,
      required: false,
      display_name: 'Geometry: Garage Position',
      description: "The position of the garage. Only applies to #{HPXML::ResidentialTypeSFD} units."
    )

    foundation_type_choices = OpenStudio::StringVector.new
    foundation_type_choices << HPXML::FoundationTypeSlab
    foundation_type_choices << HPXML::FoundationTypeCrawlspaceVented
    foundation_type_choices << HPXML::FoundationTypeCrawlspaceUnvented
    foundation_type_choices << HPXML::FoundationTypeCrawlspaceConditioned
    foundation_type_choices << HPXML::FoundationTypeBasementUnconditioned
    foundation_type_choices << HPXML::FoundationTypeBasementConditioned
    foundation_type_choices << HPXML::FoundationTypeAmbient
    foundation_type_choices << HPXML::FoundationTypeAboveApartment # I.e., adiabatic
    foundation_type_choices << "#{HPXML::FoundationTypeBellyAndWing}WithSkirt"
    foundation_type_choices << "#{HPXML::FoundationTypeBellyAndWing}NoSkirt"

    args << makeArgument(
      type: Argument::Choice,
      name: 'geometry_foundation_type',
      choices: foundation_type_choices,
      required: true,
      display_name: 'Geometry: Foundation Type',
      description: "The foundation type of the building. Foundation types #{HPXML::FoundationTypeBasementConditioned} and #{HPXML::FoundationTypeCrawlspaceConditioned} are not allowed for #{HPXML::ResidentialTypeApartment}s."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_foundation_height',
      required: false,
      display_name: 'Geometry: Foundation Height',
      units: 'ft',
      description: 'The height of the foundation (e.g., 3ft for crawlspace, 8ft for basement). Only applies to basements/crawlspaces.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_foundation_height_above_grade',
      required: false,
      display_name: 'Geometry: Foundation Height Above Grade',
      units: 'ft',
      description: 'The depth above grade of the foundation wall. Only applies to basements/crawlspaces.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_rim_joist_height',
      required: false,
      display_name: 'Geometry: Rim Joist Height',
      units: 'in',
      description: 'The height of the rim joists. Only applies to basements/crawlspaces.'
    )

    attic_type_choices = OpenStudio::StringVector.new
    attic_type_choices << HPXML::AtticTypeFlatRoof
    attic_type_choices << HPXML::AtticTypeVented
    attic_type_choices << HPXML::AtticTypeUnvented
    attic_type_choices << HPXML::AtticTypeConditioned
    attic_type_choices << HPXML::AtticTypeBelowApartment # I.e., adiabatic

    args << makeArgument(
      type: Argument::Choice,
      name: 'geometry_attic_type',
      choices: attic_type_choices,
      required: true,
      display_name: 'Geometry: Attic Type',
      description: "The attic type of the building. Attic type #{HPXML::AtticTypeConditioned} is not allowed for #{HPXML::ResidentialTypeApartment}s."
    )

    roof_type_choices = OpenStudio::StringVector.new
    roof_type_choices << Constants::RoofTypeGable
    roof_type_choices << Constants::RoofTypeHip

    args << makeArgument(
      type: Argument::Choice,
      name: 'geometry_roof_type',
      choices: roof_type_choices,
      required: false,
      display_name: 'Geometry: Roof Type',
      description: 'The roof type of the building. Ignored if the building has a flat roof.'
    )

    roof_pitch_choices = OpenStudio::StringVector.new
    roof_pitch_choices << '1:12'
    roof_pitch_choices << '2:12'
    roof_pitch_choices << '3:12'
    roof_pitch_choices << '4:12'
    roof_pitch_choices << '5:12'
    roof_pitch_choices << '6:12'
    roof_pitch_choices << '7:12'
    roof_pitch_choices << '8:12'
    roof_pitch_choices << '9:12'
    roof_pitch_choices << '10:12'
    roof_pitch_choices << '11:12'
    roof_pitch_choices << '12:12'

    args << makeArgument(
      type: Argument::Choice,
      name: 'geometry_roof_pitch',
      choices: roof_pitch_choices,
      required: false,
      display_name: 'Geometry: Roof Pitch',
      description: 'The roof pitch of the attic. Ignored if the building has a flat roof.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geometry_eaves_depth',
      required: false,
      display_name: 'Geometry: Eaves Depth',
      units: 'ft',
      description: 'The eaves depth of the roof.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'neighbor_front_distance',
      required: false,
      display_name: 'Neighbor: Front Distance',
      units: 'ft',
      description: 'The distance between the unit and the neighboring building to the front (not including eaves). A value of zero indicates no neighbors. Used for shading.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'neighbor_back_distance',
      required: false,
      display_name: 'Neighbor: Back Distance',
      units: 'ft',
      description: 'The distance between the unit and the neighboring building to the back (not including eaves). A value of zero indicates no neighbors. Used for shading.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'neighbor_left_distance',
      required: false,
      display_name: 'Neighbor: Left Distance',
      units: 'ft',
      description: 'The distance between the unit and the neighboring building to the left (not including eaves). A value of zero indicates no neighbors. Used for shading.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'neighbor_right_distance',
      required: false,
      display_name: 'Neighbor: Right Distance',
      units: 'ft',
      description: 'The distance between the unit and the neighboring building to the right (not including eaves). A value of zero indicates no neighbors. Used for shading.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'neighbor_front_height',
      required: false,
      display_name: 'Neighbor: Front Height',
      units: 'ft',
      description: 'The height of the neighboring building to the front.',
      default_href: "<a href='#{docs_base_url}#hpxml-neighbor-buildings'>HPXML Neighbor Building</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'neighbor_back_height',
      required: false,
      display_name: 'Neighbor: Back Height',
      units: 'ft',
      description: 'The height of the neighboring building to the back.',
      default_href: "<a href='#{docs_base_url}#hpxml-neighbor-buildings'>HPXML Neighbor Building</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'neighbor_left_height',
      required: false,
      display_name: 'Neighbor: Left Height',
      units: 'ft',
      description: 'The height of the neighboring building to the left.',
      default_href: "<a href='#{docs_base_url}#hpxml-neighbor-buildings'>HPXML Neighbor Building</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'neighbor_right_height',
      required: false,
      display_name: 'Neighbor: Right Height',
      units: 'ft',
      description: 'The height of the neighboring building to the right.',
      default_href: "<a href='#{docs_base_url}#hpxml-neighbor-buildings'>HPXML Neighbor Building</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'floor_over_foundation_assembly_r',
      required: false,
      display_name: 'Floor: Over Foundation Assembly R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Assembly R-value for the floor over the foundation. Ignored if the building has a slab-on-grade foundation.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'floor_over_garage_assembly_r',
      required: false,
      display_name: 'Floor: Over Garage Assembly R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Assembly R-value for the floor over the garage. Ignored unless the building has a garage under conditioned space.'
    )

    floor_type_choices = OpenStudio::StringVector.new
    floor_type_choices << HPXML::FloorTypeWoodFrame
    floor_type_choices << HPXML::FloorTypeSIP
    floor_type_choices << HPXML::FloorTypeConcrete
    floor_type_choices << HPXML::FloorTypeSteelFrame

    args << makeArgument(
      type: Argument::Choice,
      name: 'floor_type',
      choices: floor_type_choices,
      required: true,
      display_name: 'Floor: Type',
      description: 'The type of floors.'
    )

    foundation_wall_type_choices = OpenStudio::StringVector.new
    foundation_wall_type_choices << HPXML::FoundationWallTypeSolidConcrete
    foundation_wall_type_choices << HPXML::FoundationWallTypeConcreteBlock
    foundation_wall_type_choices << HPXML::FoundationWallTypeConcreteBlockFoamCore
    foundation_wall_type_choices << HPXML::FoundationWallTypeConcreteBlockPerliteCore
    foundation_wall_type_choices << HPXML::FoundationWallTypeConcreteBlockVermiculiteCore
    foundation_wall_type_choices << HPXML::FoundationWallTypeConcreteBlockSolidCore
    foundation_wall_type_choices << HPXML::FoundationWallTypeDoubleBrick
    foundation_wall_type_choices << HPXML::FoundationWallTypeWood

    args << makeArgument(
      type: Argument::Choice,
      name: 'foundation_wall_type',
      choices: foundation_wall_type_choices,
      required: false,
      display_name: 'Foundation Wall: Type',
      description: 'The material type of the foundation wall.',
      default_href: "<a href='#{docs_base_url}#hpxml-foundation-walls'>HPXML Foundation Walls</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'foundation_wall_thickness',
      required: false,
      display_name: 'Foundation Wall: Thickness',
      units: 'in',
      description: 'The thickness of the foundation wall.',
      default_href: "<a href='#{docs_base_url}#hpxml-foundation-walls'>HPXML Foundation Walls</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'foundation_wall_insulation_r',
      required: false,
      display_name: 'Foundation Wall: Insulation Nominal R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Nominal R-value for the foundation wall insulation. Only applies to basements/crawlspaces.'
    )

    wall_ins_location_choices = OpenStudio::StringVector.new
    wall_ins_location_choices << Constants::LocationInterior
    wall_ins_location_choices << Constants::LocationExterior

    args << makeArgument(
      type: Argument::Choice,
      name: 'foundation_wall_insulation_location',
      choices: wall_ins_location_choices,
      required: false,
      display_name: 'Foundation Wall: Insulation Location',
      units: 'ft',
      description: 'Whether the insulation is on the interior or exterior of the foundation wall. Only applies to basements/crawlspaces.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'foundation_wall_insulation_distance_to_top',
      required: false,
      display_name: 'Foundation Wall: Insulation Distance To Top',
      units: 'ft',
      description: 'The distance from the top of the foundation wall to the top of the foundation wall insulation. Only applies to basements/crawlspaces.',
      default_href: "<a href='#{docs_base_url}#hpxml-foundation-walls'>HPXML Foundation Walls</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'foundation_wall_insulation_distance_to_bottom',
      required: false,
      display_name: 'Foundation Wall: Insulation Distance To Bottom',
      units: 'ft',
      description: 'The distance from the top of the foundation wall to the bottom of the foundation wall insulation. Only applies to basements/crawlspaces.',
      default_href: "<a href='#{docs_base_url}#hpxml-foundation-walls'>HPXML Foundation Walls</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'foundation_wall_assembly_r',
      required: false,
      display_name: 'Foundation Wall: Assembly R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Assembly R-value for the foundation walls. Only applies to basements/crawlspaces. If provided, overrides the previous foundation wall insulation inputs. If not provided, it is ignored.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'rim_joist_assembly_r',
      required: false,
      display_name: 'Rim Joist: Assembly R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Assembly R-value for the rim joists. Only applies to basements/crawlspaces. Required if a rim joist height is provided.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'slab_perimeter_insulation_r',
      required: false,
      display_name: 'Slab: Perimeter Insulation Nominal R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Nominal R-value of the vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'slab_perimeter_insulation_depth',
      required: false,
      display_name: 'Slab: Perimeter Insulation Depth',
      units: 'ft',
      description: 'Depth from grade to bottom of vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'slab_exterior_horizontal_insulation_r',
      required: false,
      display_name: 'Slab: Exterior Horizontal Insulation Nominal R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Nominal R-value of the slab exterior horizontal insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'slab_exterior_horizontal_insulation_width',
      required: false,
      display_name: 'Slab: Exterior Horizontal Insulation Width',
      units: 'ft',
      description: 'Width of the slab exterior horizontal insulation measured from the exterior surface of the vertical slab perimeter insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'slab_exterior_horizontal_insulation_depth_below_grade',
      required: false,
      display_name: 'Slab: Exterior Horizontal Insulation Depth Below Grade',
      units: 'ft',
      description: 'Depth of the slab exterior horizontal insulation measured from the top surface of the slab exterior horizontal insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'slab_under_insulation_r',
      required: false,
      display_name: 'Slab: Under Slab Insulation Nominal R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Nominal R-value of the horizontal under slab insulation. Applies to slab-on-grade foundations and basement/crawlspace floors.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'slab_under_insulation_width',
      required: false,
      display_name: 'Slab: Under Slab Insulation Width',
      units: 'ft',
      description: 'Width from slab edge inward of horizontal under-slab insulation. Enter 999 to specify that the under slab insulation spans the entire slab. Applies to slab-on-grade foundations and basement/crawlspace floors.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'slab_thickness',
      required: false,
      display_name: 'Slab: Thickness',
      units: 'in',
      description: 'The thickness of the slab. Zero can be entered if there is a dirt floor instead of a slab.',
      default_href: "<a href='#{docs_base_url}#hpxml-slabs'>HPXML Slabs</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'slab_carpet_fraction',
      required: false,
      display_name: 'Slab: Carpet Fraction',
      units: 'Frac',
      description: 'Fraction of the slab floor area that is carpeted.',
      default_href: "<a href='#{docs_base_url}#hpxml-slabs'>HPXML Slabs</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'slab_carpet_r',
      required: false,
      display_name: 'Slab: Carpet R-value',
      units: 'h-ft^2-R/Btu',
      description: 'R-value of the slab carpet.',
      default_href: "<a href='#{docs_base_url}#hpxml-slabs'>HPXML Slabs</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ceiling_assembly_r',
      required: false,
      display_name: 'Ceiling: Assembly R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Assembly R-value for the ceiling (attic floor).'
    )

    roof_material_type_choices = OpenStudio::StringVector.new
    roof_material_type_choices << HPXML::RoofTypeAsphaltShingles
    roof_material_type_choices << HPXML::RoofTypeConcrete
    roof_material_type_choices << HPXML::RoofTypeCool
    roof_material_type_choices << HPXML::RoofTypeClayTile
    roof_material_type_choices << HPXML::RoofTypeEPS
    roof_material_type_choices << HPXML::RoofTypeMetal
    roof_material_type_choices << HPXML::RoofTypePlasticRubber
    roof_material_type_choices << HPXML::RoofTypeShingles
    roof_material_type_choices << HPXML::RoofTypeWoodShingles

    args << makeArgument(
      type: Argument::Choice,
      name: 'roof_material_type',
      choices: roof_material_type_choices,
      required: false,
      display_name: 'Roof: Material Type',
      description: 'The material type of the roof.',
      default_href: "<a href='#{docs_base_url}#hpxml-roofs'>HPXML Roofs</a>"
    )

    color_choices = OpenStudio::StringVector.new
    color_choices << HPXML::ColorDark
    color_choices << HPXML::ColorLight
    color_choices << HPXML::ColorMedium
    color_choices << HPXML::ColorMediumDark
    color_choices << HPXML::ColorReflective

    args << makeArgument(
      type: Argument::Choice,
      name: 'roof_color',
      choices: color_choices,
      required: false,
      display_name: 'Roof: Color',
      description: 'The color of the roof.',
      default_href: "<a href='#{docs_base_url}#hpxml-roofs'>HPXML Roofs</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'roof_assembly_r',
      required: false,
      display_name: 'Roof: Assembly R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Assembly R-value of the roof.'
    )

    radiant_barrier_attic_location_choices = OpenStudio::StringVector.new
    radiant_barrier_attic_location_choices << Constants::None
    radiant_barrier_attic_location_choices << HPXML::RadiantBarrierLocationAtticRoofOnly
    radiant_barrier_attic_location_choices << HPXML::RadiantBarrierLocationAtticRoofAndGableWalls
    radiant_barrier_attic_location_choices << HPXML::RadiantBarrierLocationAtticFloor

    args << makeArgument(
      type: Argument::Choice,
      name: 'radiant_barrier_attic_location',
      choices: radiant_barrier_attic_location_choices,
      required: false,
      display_name: 'Attic: Radiant Barrier Location',
      description: 'The location of the radiant barrier in the attic.'
    )

    radiant_barrier_grade_choices = OpenStudio::StringVector.new
    radiant_barrier_grade_choices << '1'
    radiant_barrier_grade_choices << '2'
    radiant_barrier_grade_choices << '3'

    args << makeArgument(
      type: Argument::Choice,
      name: 'radiant_barrier_grade',
      choices: radiant_barrier_grade_choices,
      required: false,
      display_name: 'Attic: Radiant Barrier Grade',
      description: 'The grade of the radiant barrier in the attic.',
      default_href: "<a href='#{docs_base_url}#hpxml-roofs'>HPXML Roofs</a>"
    )

    wall_type_choices = OpenStudio::StringVector.new
    wall_type_choices << HPXML::WallTypeWoodStud
    wall_type_choices << HPXML::WallTypeCMU
    wall_type_choices << HPXML::WallTypeDoubleWoodStud
    wall_type_choices << HPXML::WallTypeICF
    wall_type_choices << HPXML::WallTypeLog
    wall_type_choices << HPXML::WallTypeSIP
    wall_type_choices << HPXML::WallTypeConcrete
    wall_type_choices << HPXML::WallTypeSteelStud
    wall_type_choices << HPXML::WallTypeStone
    wall_type_choices << HPXML::WallTypeStrawBale
    wall_type_choices << HPXML::WallTypeBrick

    args << makeArgument(
      type: Argument::Choice,
      name: 'wall_type',
      choices: wall_type_choices,
      required: true,
      display_name: 'Wall: Type',
      description: 'The type of walls.'
    )

    wall_siding_type_choices = OpenStudio::StringVector.new
    wall_siding_type_choices << HPXML::SidingTypeAluminum
    wall_siding_type_choices << HPXML::SidingTypeAsbestos
    wall_siding_type_choices << HPXML::SidingTypeBrick
    wall_siding_type_choices << HPXML::SidingTypeCompositeShingle
    wall_siding_type_choices << HPXML::SidingTypeFiberCement
    wall_siding_type_choices << HPXML::SidingTypeMasonite
    wall_siding_type_choices << HPXML::SidingTypeNone
    wall_siding_type_choices << HPXML::SidingTypeStucco
    wall_siding_type_choices << HPXML::SidingTypeSyntheticStucco
    wall_siding_type_choices << HPXML::SidingTypeVinyl
    wall_siding_type_choices << HPXML::SidingTypeWood

    args << makeArgument(
      type: Argument::Choice,
      name: 'wall_siding_type',
      choices: wall_siding_type_choices,
      required: false,
      display_name: 'Wall: Siding Type',
      description: 'The siding type of the walls. Also applies to rim joists.',
      default_href: "<a href='#{docs_base_url}#hpxml-walls'>HPXML Walls</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'wall_color',
      choices: color_choices,
      required: false,
      display_name: 'Wall: Color',
      description: 'The color of the walls. Also applies to rim joists.',
      default_href: "<a href='#{docs_base_url}#hpxml-walls'>HPXML Walls</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'wall_assembly_r',
      required: true,
      display_name: 'Wall: Assembly R-value',
      units: 'h-ft^2-R/Btu',
      description: 'Assembly R-value of the walls.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_area_front',
      required: true,
      display_name: 'Windows: Front Window Area',
      units: 'ft^2',
      description: "The amount of window area on the unit's front facade. A value less than 1 will be treated as a window-to-wall ratio. If the front wall is adiabatic, the value will be ignored."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_area_back',
      required: true,
      display_name: 'Windows: Back Window Area',
      units: 'ft^2',
      description: "The amount of window area on the unit's back facade. A value less than 1 will be treated as a window-to-wall ratio. If the back wall is adiabatic, the value will be ignored."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_area_left',
      required: true,
      display_name: 'Windows: Left Window Area',
      units: 'ft^2',
      description: "The amount of window area on the unit's left facade (when viewed from the front). A value less than 1 will be treated as a window-to-wall ratio. If the left wall is adiabatic, the value will be ignored."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_area_right',
      required: true,
      display_name: 'Windows: Right Window Area',
      units: 'ft^2',
      description: "The amount of window area on the unit's right facade (when viewed from the front). A value less than 1 will be treated as a window-to-wall ratio. If the right wall is adiabatic, the value will be ignored."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_aspect_ratio',
      required: true,
      display_name: 'Windows: Aspect Ratio',
      units: 'Frac',
      description: 'Ratio of window height to width.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_ufactor',
      required: true,
      display_name: 'Windows: U-Factor',
      units: 'Btu/hr-ft^2-R',
      description: 'Full-assembly NFRC U-factor.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_shgc',
      required: true,
      display_name: 'Windows: SHGC',
      description: 'Full-assembly NFRC solar heat gain coefficient.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_fraction_operable',
      required: false,
      display_name: 'Windows: Fraction Operable',
      units: 'Frac',
      description: 'Fraction of windows that are operable.',
      default_href: "<a href='#{docs_base_url}#hpxml-windows'>HPXML Windows</a>"
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'window_natvent_availability',
      required: false,
      display_name: 'Windows: Natural Ventilation Availability',
      units: 'Days/week',
      description: 'For operable windows, the number of days/week that windows can be opened by occupants for natural ventilation.',
      default_href: "<a href='#{docs_base_url}#hpxml-windows'>HPXML Windows</a>"
    )

    window_interior_shading_type_choices = OpenStudio::StringVector.new
    window_interior_shading_type_choices << HPXML::InteriorShadingTypeLightCurtains
    window_interior_shading_type_choices << HPXML::InteriorShadingTypeLightShades
    window_interior_shading_type_choices << HPXML::InteriorShadingTypeLightBlinds
    window_interior_shading_type_choices << HPXML::InteriorShadingTypeMediumCurtains
    window_interior_shading_type_choices << HPXML::InteriorShadingTypeMediumShades
    window_interior_shading_type_choices << HPXML::InteriorShadingTypeMediumBlinds
    window_interior_shading_type_choices << HPXML::InteriorShadingTypeDarkCurtains
    window_interior_shading_type_choices << HPXML::InteriorShadingTypeDarkShades
    window_interior_shading_type_choices << HPXML::InteriorShadingTypeDarkBlinds
    window_interior_shading_type_choices << HPXML::InteriorShadingTypeNone
    # Not adding inputs for other because that can be anything

    args << makeArgument(
      type: Argument::Choice,
      name: 'window_interior_shading_type',
      choices: window_interior_shading_type_choices,
      required: false,
      display_name: 'Windows: Interior Shading Type',
      description: 'Type of window interior shading. Summer/winter shading coefficients can be provided below instead.',
      default_href: "<a href='#{docs_base_url}#hpxml-interior-shading'>HPXML Interior Shading</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_interior_shading_winter',
      required: false,
      display_name: 'Windows: Winter Interior Shading Coefficient',
      units: 'Frac',
      description: 'Interior shading coefficient for the winter season, which if provided overrides the shading type input. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.',
      default_href: "<a href='#{docs_base_url}#hpxml-interior-shading'>HPXML Interior Shading</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_interior_shading_summer',
      required: false,
      display_name: 'Windows: Summer Interior Shading Coefficient',
      units: 'Frac',
      description: 'Interior shading coefficient for the summer season, which if provided overrides the shading type input. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.',
      default_href: "<a href='#{docs_base_url}#hpxml-interior-shading'>HPXML Interior Shading</a>"
    )

    window_exterior_shading_type_choices = OpenStudio::StringVector.new
    window_exterior_shading_type_choices << HPXML::ExteriorShadingTypeSolarFilm
    window_exterior_shading_type_choices << HPXML::ExteriorShadingTypeSolarScreens
    window_exterior_shading_type_choices << HPXML::ExteriorShadingTypeNone
    # Not adding inputs for trees since that is more specific to select windows, whereas this will apply to every window
    # Not adding inputs for overhangs/neighbors because there are other inputs to describe those (and in more detail)
    # Not adding inputs for other because that can be anything

    args << makeArgument(
      type: Argument::Choice,
      name: 'window_exterior_shading_type',
      choices: window_exterior_shading_type_choices,
      required: false,
      display_name: 'Windows: Exterior Shading Type',
      description: 'Type of window exterior shading. Summer/winter shading coefficients can be provided below instead.',
      default_href: "<a href='#{docs_base_url}#hpxml-exterior-shading'>HPXML Exterior Shading</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_exterior_shading_winter',
      required: false,
      display_name: 'Windows: Winter Exterior Shading Coefficient',
      units: 'Frac',
      description: 'Exterior shading coefficient for the winter season, which if provided overrides the shading type input. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.',
      default_href: "<a href='#{docs_base_url}#hpxml-exterior-shading'>HPXML Exterior Shading</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'window_exterior_shading_summer',
      required: false,
      display_name: 'Windows: Summer Exterior Shading Coefficient',
      units: 'Frac',
      description: 'Exterior shading coefficient for the summer season, which if provided overrides the shading type input. 1.0 indicates no reduction in solar gain, 0.85 indicates 15% reduction, etc.',
      default_href: "<a href='#{docs_base_url}#hpxml-exterior-shading'>HPXML Exterior Shading</a>"
    )

    args << makeArgument(
      type: Argument::String,
      name: 'window_shading_summer_season',
      required: false,
      display_name: 'Windows: Shading Summer Season',
      description: "Enter a date range like 'May 1 - Sep 30'. Defines the summer season for purposes of shading coefficients; the rest of the year is assumed to be winter.",
      default_href: "<a href='#{docs_base_url}#hpxml-windows'>HPXML Windows</a>"
    )

    window_insect_screen_choices = OpenStudio::StringVector.new
    window_insect_screen_choices << Constants::None
    window_insect_screen_choices << HPXML::LocationExterior
    window_insect_screen_choices << HPXML::LocationInterior

    args << makeArgument(
      type: Argument::Choice,
      name: 'window_insect_screens',
      choices: window_insect_screen_choices,
      required: false,
      display_name: 'Windows: Insect Screens',
      description: 'The type of insect screens, if present. If not provided, assumes there are no insect screens.'
    )

    storm_window_type_choices = OpenStudio::StringVector.new
    storm_window_type_choices << HPXML::WindowGlassTypeClear
    storm_window_type_choices << HPXML::WindowGlassTypeLowE

    args << makeArgument(
      type: Argument::Choice,
      name: 'window_storm_type',
      choices: storm_window_type_choices,
      required: false,
      display_name: 'Windows: Storm Type',
      description: 'The type of storm, if present. If not provided, assumes there is no storm.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_front_depth',
      required: false,
      display_name: 'Overhangs: Front Depth',
      units: 'ft',
      description: 'The depth of overhangs for windows for the front facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_front_distance_to_top_of_window',
      required: false,
      display_name: 'Overhangs: Front Distance to Top of Window',
      units: 'ft',
      description: 'The overhangs distance to the top of window for the front facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_front_distance_to_bottom_of_window',
      required: false,
      display_name: 'Overhangs: Front Distance to Bottom of Window',
      units: 'ft',
      description: 'The overhangs distance to the bottom of window for the front facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_back_depth',
      required: false,
      display_name: 'Overhangs: Back Depth',
      units: 'ft',
      description: 'The depth of overhangs for windows for the back facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_back_distance_to_top_of_window',
      required: false,
      display_name: 'Overhangs: Back Distance to Top of Window',
      units: 'ft',
      description: 'The overhangs distance to the top of window for the back facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_back_distance_to_bottom_of_window',
      required: false,
      display_name: 'Overhangs: Back Distance to Bottom of Window',
      units: 'ft',
      description: 'The overhangs distance to the bottom of window for the back facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_left_depth',
      required: false,
      display_name: 'Overhangs: Left Depth',
      units: 'ft',
      description: 'The depth of overhangs for windows for the left facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_left_distance_to_top_of_window',
      required: false,
      display_name: 'Overhangs: Left Distance to Top of Window',
      units: 'ft',
      description: 'The overhangs distance to the top of window for the left facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_left_distance_to_bottom_of_window',
      required: false,
      display_name: 'Overhangs: Left Distance to Bottom of Window',
      units: 'ft',
      description: 'The overhangs distance to the bottom of window for the left facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_right_depth',
      required: false,
      display_name: 'Overhangs: Right Depth',
      units: 'ft',
      description: 'The depth of overhangs for windows for the right facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_right_distance_to_top_of_window',
      required: false,
      display_name: 'Overhangs: Right Distance to Top of Window',
      units: 'ft',
      description: 'The overhangs distance to the top of window for the right facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'overhangs_right_distance_to_bottom_of_window',
      required: false,
      display_name: 'Overhangs: Right Distance to Bottom of Window',
      units: 'ft',
      description: 'The overhangs distance to the bottom of window for the right facade.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'skylight_area_front',
      required: false,
      display_name: 'Skylights: Front Roof Area',
      units: 'ft^2',
      description: "The amount of skylight area on the unit's front conditioned roof facade."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'skylight_area_back',
      required: false,
      display_name: 'Skylights: Back Roof Area',
      units: 'ft^2',
      description: "The amount of skylight area on the unit's back conditioned roof facade."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'skylight_area_left',
      required: false,
      display_name: 'Skylights: Left Roof Area',
      units: 'ft^2',
      description: "The amount of skylight area on the unit's left conditioned roof facade (when viewed from the front)."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'skylight_area_right',
      required: false,
      display_name: 'Skylights: Right Roof Area',
      units: 'ft^2',
      description: "The amount of skylight area on the unit's right conditioned roof facade (when viewed from the front)."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'skylight_ufactor',
      required: false,
      display_name: 'Skylights: U-Factor',
      units: 'Btu/hr-ft^2-R',
      description: 'Full-assembly NFRC U-factor.'
    )

    args << makeArgument(
      name: 'skylight_shgc',
      type: Argument::Double,
      required: false,
      display_name: 'Skylights: SHGC',
      description: 'Full-assembly NFRC solar heat gain coefficient.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'skylight_storm_type',
      choices: storm_window_type_choices,
      required: false,
      display_name: 'Skylights: Storm Type',
      description: 'The type of storm, if present. If not provided, assumes there is no storm.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'door_area',
      required: true,
      display_name: 'Doors: Area',
      units: 'ft^2',
      description: 'The area of the opaque door(s).'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'door_rvalue',
      required: true,
      display_name: 'Doors: R-value',
      units: 'h-ft^2-R/Btu',
      description: 'R-value of the opaque door(s).'
    )

    air_leakage_leakiness_description_choices = OpenStudio::StringVector.new
    air_leakage_leakiness_description_choices << HPXML::LeakinessVeryTight
    air_leakage_leakiness_description_choices << HPXML::LeakinessTight
    air_leakage_leakiness_description_choices << HPXML::LeakinessAverage
    air_leakage_leakiness_description_choices << HPXML::LeakinessLeaky
    air_leakage_leakiness_description_choices << HPXML::LeakinessVeryLeaky

    args << makeArgument(
      type: Argument::Choice,
      name: 'air_leakage_leakiness_description',
      choices: air_leakage_leakiness_description_choices,
      required: false,
      display_name: 'Air Leakage: Leakiness Description',
      description: 'Qualitative description of infiltration. If provided, the Year Built of the home is required. Either provide this input or provide a numeric air leakage value below.'
    )

    air_leakage_units_choices = OpenStudio::StringVector.new
    air_leakage_units_choices << HPXML::UnitsACH
    air_leakage_units_choices << HPXML::UnitsCFM
    air_leakage_units_choices << HPXML::UnitsACHNatural
    air_leakage_units_choices << HPXML::UnitsCFMNatural
    air_leakage_units_choices << HPXML::UnitsELA

    args << makeArgument(
      type: Argument::Choice,
      name: 'air_leakage_units',
      choices: air_leakage_units_choices,
      required: false,
      display_name: 'Air Leakage: Units',
      description: 'The unit of measure for the air leakage if providing a numeric air leakage value.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'air_leakage_house_pressure',
      required: false,
      display_name: 'Air Leakage: House Pressure',
      units: 'Pa',
      description: "The house pressure relative to outside if providing a numeric air leakage value. Required when units are #{HPXML::UnitsACH} or #{HPXML::UnitsCFM}."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'air_leakage_value',
      required: false,
      display_name: 'Air Leakage: Value',
      description: "Numeric air leakage value. For '#{HPXML::UnitsELA}', provide value in sq. in. If provided, overrides Leakiness Description input."
    )

    air_leakage_type_choices = OpenStudio::StringVector.new
    air_leakage_type_choices << HPXML::InfiltrationTypeUnitTotal
    air_leakage_type_choices << HPXML::InfiltrationTypeUnitExterior

    args << makeArgument(
      type: Argument::Choice,
      name: 'air_leakage_type',
      choices: air_leakage_type_choices,
      required: false,
      display_name: 'Air Leakage: Type',
      description: "Type of air leakage if providing a numeric air leakage value. If '#{HPXML::InfiltrationTypeUnitTotal}', represents the total infiltration to the unit as measured by a compartmentalization test, in which case the air leakage value will be adjusted by the ratio of exterior envelope surface area to total envelope surface area. Otherwise, if '#{HPXML::InfiltrationTypeUnitExterior}', represents the infiltration to the unit from outside only as measured by a guarded test. Required when unit type is #{HPXML::ResidentialTypeSFA} or #{HPXML::ResidentialTypeApartment}."
    )

    args << makeArgument(
      name: 'air_leakage_has_flue_or_chimney_in_conditioned_space',
      type: Argument::Boolean,
      required: false,
      display_name: 'Air Leakage: Has Flue or Chimney in Conditioned Space',
      description: 'Presence of flue or chimney with combustion air from conditioned space; used for infiltration model.',
      default_href: "<a href='#{docs_base_url}#flue-or-chimney'>Flue or Chimney</a>"
    )

    heating_system_type_choices = OpenStudio::StringVector.new
    heating_system_type_choices << Constants::None
    heating_system_type_choices << HPXML::HVACTypeFurnace
    heating_system_type_choices << HPXML::HVACTypeWallFurnace
    heating_system_type_choices << HPXML::HVACTypeFloorFurnace
    heating_system_type_choices << HPXML::HVACTypeBoiler
    heating_system_type_choices << HPXML::HVACTypeElectricResistance
    heating_system_type_choices << HPXML::HVACTypeStove
    heating_system_type_choices << HPXML::HVACTypeSpaceHeater
    heating_system_type_choices << HPXML::HVACTypeFireplace
    heating_system_type_choices << "Shared #{HPXML::HVACTypeBoiler} w/ Baseboard"
    heating_system_type_choices << "Shared #{HPXML::HVACTypeBoiler} w/ Ductless Fan Coil"

    heating_system_fuel_choices = OpenStudio::StringVector.new
    heating_system_fuel_choices << HPXML::FuelTypeElectricity
    heating_system_fuel_choices << HPXML::FuelTypeNaturalGas
    heating_system_fuel_choices << HPXML::FuelTypeOil
    heating_system_fuel_choices << HPXML::FuelTypePropane
    heating_system_fuel_choices << HPXML::FuelTypeWoodCord
    heating_system_fuel_choices << HPXML::FuelTypeWoodPellets
    heating_system_fuel_choices << HPXML::FuelTypeCoal

    cooling_system_type_choices = OpenStudio::StringVector.new
    cooling_system_type_choices << Constants::None
    cooling_system_type_choices << HPXML::HVACTypeCentralAirConditioner
    cooling_system_type_choices << HPXML::HVACTypeRoomAirConditioner
    cooling_system_type_choices << HPXML::HVACTypeEvaporativeCooler
    cooling_system_type_choices << HPXML::HVACTypeMiniSplitAirConditioner
    cooling_system_type_choices << HPXML::HVACTypePTAC

    cooling_efficiency_type_choices = OpenStudio::StringVector.new
    cooling_efficiency_type_choices << HPXML::UnitsSEER
    cooling_efficiency_type_choices << HPXML::UnitsSEER2
    cooling_efficiency_type_choices << HPXML::UnitsEER
    cooling_efficiency_type_choices << HPXML::UnitsCEER

    compressor_type_choices = OpenStudio::StringVector.new
    compressor_type_choices << HPXML::HVACCompressorTypeSingleStage
    compressor_type_choices << HPXML::HVACCompressorTypeTwoStage
    compressor_type_choices << HPXML::HVACCompressorTypeVariableSpeed

    args << makeArgument(
      type: Argument::Choice,
      name: 'heating_system_type',
      choices: heating_system_type_choices,
      required: true,
      display_name: 'Heating System: Type',
      description: "The type of heating system. Use '#{Constants::None}' if there is no heating system or if there is a heat pump serving a heating load."
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'heating_system_fuel',
      choices: heating_system_fuel_choices,
      required: false,
      display_name: 'Heating System: Fuel Type',
      description: "The fuel type of the heating system. Ignored for #{HPXML::HVACTypeElectricResistance}."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_heating_efficiency',
      required: false,
      display_name: 'Heating System: Rated AFUE or Percent',
      units: 'Frac',
      description: 'The rated heating efficiency value of the heating system.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_heating_capacity',
      required: false,
      display_name: 'Heating System: Heating Capacity',
      description: 'The output heating capacity of the heating system.',
      units: 'Btu/hr',
      default_href: "<a href='#{docs_base_url}#hpxml-heating-systems'>HPXML Heating Systems</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_heating_autosizing_factor',
      required: false,
      display_name: 'Heating System: Heating Autosizing Factor',
      description: 'The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_heating_autosizing_limit',
      required: false,
      display_name: 'Heating System: Heating Autosizing Limit',
      description: 'The maximum capacity limit applied to the auto-sizing methodology. If not provided, no limit is used.',
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_fraction_heat_load_served',
      required: false,
      display_name: 'Heating System: Fraction Heat Load Served',
      description: 'The heating load served by the heating system.',
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_pilot_light',
      required: false,
      display_name: 'Heating System: Pilot Light',
      description: "The fuel usage of the pilot light. Applies only to #{HPXML::HVACTypeFurnace}, #{HPXML::HVACTypeWallFurnace}, #{HPXML::HVACTypeFloorFurnace}, #{HPXML::HVACTypeStove}, #{HPXML::HVACTypeBoiler}, and #{HPXML::HVACTypeFireplace} with non-electric fuel type. If not provided, assumes no pilot light.",
      units: 'Btuh'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_airflow_defect_ratio',
      required: false,
      display_name: 'Heating System: Airflow Defect Ratio',
      description: "The airflow defect ratio, defined as (InstalledAirflow - DesignAirflow) / DesignAirflow, of the heating system per ANSI/RESNET/ACCA Standard 310. A value of zero means no airflow defect. Applies only to #{HPXML::HVACTypeFurnace}. If not provided, assumes no defect.",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'cooling_system_type',
      choices: cooling_system_type_choices,
      required: true,
      display_name: 'Cooling System: Type',
      description: "The type of cooling system. Use '#{Constants::None}' if there is no cooling system or if there is a heat pump serving a cooling load."
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'cooling_system_cooling_efficiency_type',
      choices: cooling_efficiency_type_choices,
      required: false,
      display_name: 'Cooling System: Efficiency Type',
      description: "The efficiency type of the cooling system. System types #{HPXML::HVACTypeCentralAirConditioner} and #{HPXML::HVACTypeMiniSplitAirConditioner} use #{HPXML::UnitsSEER} or #{HPXML::UnitsSEER2}. System types #{HPXML::HVACTypeRoomAirConditioner} and #{HPXML::HVACTypePTAC} use #{HPXML::UnitsEER} or #{HPXML::UnitsCEER}. Ignored for system type #{HPXML::HVACTypeEvaporativeCooler}."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_cooling_efficiency',
      required: false,
      display_name: 'Cooling System: Efficiency',
      description: "The rated efficiency value of the cooling system. Ignored for #{HPXML::HVACTypeEvaporativeCooler}."
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'cooling_system_cooling_compressor_type',
      choices: compressor_type_choices,
      required: false,
      display_name: 'Cooling System: Cooling Compressor Type',
      description: "The compressor type of the cooling system. Only applies to #{HPXML::HVACTypeCentralAirConditioner} and #{HPXML::HVACTypeMiniSplitAirConditioner}.",
      default_href: "<a href='#{docs_base_url}#central-air-conditioner'>Central Air Conditioner</a>, <a href='#{docs_base_url}#mini-split-air-conditioner'>Mini-Split Air Conditioner</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_cooling_sensible_heat_fraction',
      required: false,
      display_name: 'Cooling System: Cooling Sensible Heat Fraction',
      description: "The sensible heat fraction of the cooling system. Ignored for #{HPXML::HVACTypeEvaporativeCooler}.",
      default_href: "<a href='#{docs_base_url}#central-air-conditioner'>Central Air Conditioner</a>, <a href='#{docs_base_url}#room-air-conditioner'>Room Air Conditioner</a>, <a href='#{docs_base_url}#packaged-terminal-air-conditioner'>Packaged Terminal Air Conditioner</a>, <a href='#{docs_base_url}#mini-split-air-conditioner'>Mini-Split Air Conditioner</a>",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_cooling_capacity',
      required: false,
      display_name: 'Cooling System: Cooling Capacity',
      description: 'The output cooling capacity of the cooling system.',
      default_href: "<a href='#{docs_base_url}#central-air-conditioner'>Central Air Conditioner</a>, <a href='#{docs_base_url}#room-air-conditioner'>Room Air Conditioner</a>, <a href='#{docs_base_url}#packaged-terminal-air-conditioner'>Packaged Terminal Air Conditioner</a>, <a href='#{docs_base_url}#evaporative-cooler'>Evaporative Cooler</a>, <a href='#{docs_base_url}#mini-split-air-conditioner'>Mini-Split Air Conditioner</a>",
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_cooling_autosizing_factor',
      required: false,
      display_name: 'Cooling System: Cooling Autosizing Factor',
      description: 'The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_cooling_autosizing_limit',
      required: false,
      display_name: 'Cooling System: Cooling Autosizing Limit',
      description: 'The maximum capacity limit applied to the auto-sizing methodology. If not provided, no limit is used.',
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_fraction_cool_load_served',
      required: false,
      display_name: 'Cooling System: Fraction Cool Load Served',
      description: 'The cooling load served by the cooling system.',
      units: 'Frac'
    )

    args << makeArgument(
      name: 'cooling_system_is_ducted',
      type: Argument::Boolean,
      required: false,
      display_name: 'Cooling System: Is Ducted',
      description: "Whether the cooling system is ducted or not. Only used for #{HPXML::HVACTypeMiniSplitAirConditioner} and #{HPXML::HVACTypeEvaporativeCooler}. It's assumed that #{HPXML::HVACTypeCentralAirConditioner} is ducted, and #{HPXML::HVACTypeRoomAirConditioner} and #{HPXML::HVACTypePTAC} are not ducted."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_airflow_defect_ratio',
      required: false,
      display_name: 'Cooling System: Airflow Defect Ratio',
      description: "The airflow defect ratio, defined as (InstalledAirflow - DesignAirflow) / DesignAirflow, of the cooling system per ANSI/RESNET/ACCA Standard 310. A value of zero means no airflow defect. Applies only to #{HPXML::HVACTypeCentralAirConditioner} and ducted #{HPXML::HVACTypeMiniSplitAirConditioner}. If not provided, assumes no defect.",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_charge_defect_ratio',
      required: false,
      display_name: 'Cooling System: Charge Defect Ratio',
      description: "The refrigerant charge defect ratio, defined as (InstalledCharge - DesignCharge) / DesignCharge, of the cooling system per ANSI/RESNET/ACCA Standard 310. A value of zero means no refrigerant charge defect. Applies only to #{HPXML::HVACTypeCentralAirConditioner} and #{HPXML::HVACTypeMiniSplitAirConditioner}. If not provided, assumes no defect.",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_crankcase_heater_watts',
      required: false,
      display_name: 'Cooling System: Crankcase Heater Power Watts',
      description: "Cooling system crankcase heater power consumption in Watts. Applies only to #{HPXML::HVACTypeCentralAirConditioner}, #{HPXML::HVACTypeRoomAirConditioner}, #{HPXML::HVACTypePTAC} and #{HPXML::HVACTypeMiniSplitAirConditioner}.",
      default_href: "<a href='#{docs_base_url}#central-air-conditioner'>Central Air Conditioner</a>, <a href='#{docs_base_url}#room-air-conditioner'>Room Air Conditioner</a>, <a href='#{docs_base_url}#packaged-terminal-air-conditioner'>Packaged Terminal Air Conditioner</a>, <a href='#{docs_base_url}#mini-split-air-conditioner'>Mini-Split Air Conditioner</a>",
      units: 'W'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'cooling_system_integrated_heating_system_fuel',
      choices: heating_system_fuel_choices,
      required: false,
      display_name: 'Cooling System: Integrated Heating System Fuel Type',
      description: "The fuel type of the heating system integrated into cooling system. Only used for #{HPXML::HVACTypePTAC} and #{HPXML::HVACTypeRoomAirConditioner}."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_integrated_heating_system_efficiency_percent',
      required: false,
      display_name: 'Cooling System: Integrated Heating System Efficiency',
      units: 'Frac',
      description: "The rated heating efficiency value of the heating system integrated into cooling system. Only used for #{HPXML::HVACTypePTAC} and #{HPXML::HVACTypeRoomAirConditioner}."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_integrated_heating_system_capacity',
      required: false,
      display_name: 'Cooling System: Integrated Heating System Heating Capacity',
      description: "The output heating capacity of the heating system integrated into cooling system. Only used for #{HPXML::HVACTypeRoomAirConditioner} and #{HPXML::HVACTypePTAC}.",
      default_href: "<a href='#{docs_base_url}#room-air-conditioner'>Room Air Conditioner</a>, <a href='#{docs_base_url}#packaged-terminal-air-conditioner'>Packaged Terminal Air Conditioner</a>",
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooling_system_integrated_heating_system_fraction_heat_load_served',
      required: false,
      display_name: 'Cooling System: Integrated Heating System Fraction Heat Load Served',
      description: "The heating load served by the heating system integrated into cooling system. Only used for #{HPXML::HVACTypePTAC} and #{HPXML::HVACTypeRoomAirConditioner}.",
      units: 'Frac'
    )

    heat_pump_type_choices = OpenStudio::StringVector.new
    heat_pump_type_choices << Constants::None
    heat_pump_type_choices << HPXML::HVACTypeHeatPumpAirToAir
    heat_pump_type_choices << HPXML::HVACTypeHeatPumpMiniSplit
    heat_pump_type_choices << HPXML::HVACTypeHeatPumpGroundToAir
    heat_pump_type_choices << HPXML::HVACTypeHeatPumpPTHP
    heat_pump_type_choices << HPXML::HVACTypeHeatPumpRoom

    heat_pump_heating_efficiency_type_choices = OpenStudio::StringVector.new
    heat_pump_heating_efficiency_type_choices << HPXML::UnitsHSPF
    heat_pump_heating_efficiency_type_choices << HPXML::UnitsHSPF2
    heat_pump_heating_efficiency_type_choices << HPXML::UnitsCOP

    heat_pump_backup_type_choices = OpenStudio::StringVector.new
    heat_pump_backup_type_choices << Constants::None
    heat_pump_backup_type_choices << HPXML::HeatPumpBackupTypeIntegrated
    heat_pump_backup_type_choices << HPXML::HeatPumpBackupTypeSeparate

    heat_pump_backup_fuel_choices = OpenStudio::StringVector.new
    heat_pump_backup_fuel_choices << HPXML::FuelTypeElectricity
    heat_pump_backup_fuel_choices << HPXML::FuelTypeNaturalGas
    heat_pump_backup_fuel_choices << HPXML::FuelTypeOil
    heat_pump_backup_fuel_choices << HPXML::FuelTypePropane

    heat_pump_sizing_choices = OpenStudio::StringVector.new
    heat_pump_sizing_choices << HPXML::HeatPumpSizingACCA
    heat_pump_sizing_choices << HPXML::HeatPumpSizingHERS
    heat_pump_sizing_choices << HPXML::HeatPumpSizingMaxLoad

    heat_pump_backup_sizing_choices = OpenStudio::StringVector.new
    heat_pump_backup_sizing_choices << HPXML::HeatPumpBackupSizingEmergency
    heat_pump_backup_sizing_choices << HPXML::HeatPumpBackupSizingSupplemental

    args << makeArgument(
      type: Argument::Choice,
      name: 'heat_pump_type',
      choices: heat_pump_type_choices,
      required: true,
      display_name: 'Heat Pump: Type',
      description: "The type of heat pump. Use '#{Constants::None}' if there is no heat pump."
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'heat_pump_heating_efficiency_type',
      choices: heat_pump_heating_efficiency_type_choices,
      required: false,
      display_name: 'Heat Pump: Heating Efficiency Type',
      description: "The heating efficiency type of heat pump. System types #{HPXML::HVACTypeHeatPumpAirToAir} and #{HPXML::HVACTypeHeatPumpMiniSplit} use #{HPXML::UnitsHSPF} or #{HPXML::UnitsHSPF2}. System types #{HPXML::HVACTypeHeatPumpGroundToAir}, #{HPXML::HVACTypeHeatPumpPTHP} and #{HPXML::HVACTypeHeatPumpRoom} use #{HPXML::UnitsCOP}."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_heating_efficiency',
      required: false,
      display_name: 'Heat Pump: Heating Efficiency',
      description: 'The rated heating efficiency value of the heat pump.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'heat_pump_cooling_efficiency_type',
      choices: cooling_efficiency_type_choices,
      required: false,
      display_name: 'Heat Pump: Cooling Efficiency Type',
      description: "The cooling efficiency type of heat pump. System types #{HPXML::HVACTypeHeatPumpAirToAir} and #{HPXML::HVACTypeHeatPumpMiniSplit} use #{HPXML::UnitsSEER} or #{HPXML::UnitsSEER2}. System types #{HPXML::HVACTypeHeatPumpGroundToAir}, #{HPXML::HVACTypeHeatPumpPTHP} and #{HPXML::HVACTypeHeatPumpRoom} use #{HPXML::UnitsEER}."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_cooling_efficiency',
      required: false,
      display_name: 'Heat Pump: Cooling Efficiency',
      description: 'The rated cooling efficiency value of the heat pump.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'heat_pump_cooling_compressor_type',
      choices: compressor_type_choices,
      required: false,
      display_name: 'Heat Pump: Cooling Compressor Type',
      description: "The compressor type of the heat pump. Only applies to #{HPXML::HVACTypeHeatPumpAirToAir} and #{HPXML::HVACTypeHeatPumpMiniSplit}.",
      default_href: "<a href='#{docs_base_url}#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='#{docs_base_url}#mini-split-heat-pump'>Mini-Split Heat Pump</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_cooling_sensible_heat_fraction',
      required: false,
      display_name: 'Heat Pump: Cooling Sensible Heat Fraction',
      description: 'The sensible heat fraction of the heat pump.',
      default_href: "<a href='#{docs_base_url}#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='#{docs_base_url}#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='#{docs_base_url}#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='#{docs_base_url}#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>, <a href='#{docs_base_url}#ground-to-air-heat-pump'>Ground-to-Air Heat Pump</a>",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_heating_capacity',
      required: false,
      display_name: 'Heat Pump: Heating Capacity',
      description: 'The output heating capacity of the heat pump.',
      default_href: "<a href='#{docs_base_url}#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='#{docs_base_url}#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='#{docs_base_url}#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='#{docs_base_url}#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>, <a href='#{docs_base_url}#ground-to-air-heat-pump'>Ground-to-Air Heat Pump</a>",
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_heating_autosizing_factor',
      required: false,
      display_name: 'Heat Pump: Heating Autosizing Factor',
      description: 'The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_heating_autosizing_limit',
      required: false,
      display_name: 'Heat Pump: Heating Autosizing Limit',
      description: 'The maximum capacity limit applied to the auto-sizing methodology. If not provided, no limit is used.',
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_heating_capacity_retention_fraction',
      required: false,
      display_name: 'Heat Pump: Heating Capacity Retention Fraction',
      description: "The output heating capacity of the heat pump at a user-specified temperature (e.g., 17F or 5F) divided by the above nominal heating capacity. Applies to all heat pump types except #{HPXML::HVACTypeHeatPumpGroundToAir}.",
      default_href: "<a href='#{docs_base_url}#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='#{docs_base_url}#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='#{docs_base_url}#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='#{docs_base_url}#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_heating_capacity_retention_temp',
      required: false,
      display_name: 'Heat Pump: Heating Capacity Retention Temperature',
      description: "The user-specified temperature (e.g., 17F or 5F) for the above heating capacity retention fraction. Applies to all heat pump types except #{HPXML::HVACTypeHeatPumpGroundToAir}. Required if the Heating Capacity Retention Fraction is provided.",
      units: 'F'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_cooling_capacity',
      required: false,
      display_name: 'Heat Pump: Cooling Capacity',
      description: 'The output cooling capacity of the heat pump.',
      default_href: "<a href='#{docs_base_url}#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='#{docs_base_url}#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='#{docs_base_url}#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='#{docs_base_url}#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>, <a href='#{docs_base_url}#ground-to-air-heat-pump'>Ground-to-Air Heat Pump</a>",
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_cooling_autosizing_factor',
      required: false,
      display_name: 'Heat Pump: Cooling Autosizing Factor',
      description: 'The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_cooling_autosizing_limit',
      required: false,
      display_name: 'Heat Pump: Cooling Autosizing Limit',
      description: 'The maximum capacity limit applied to the auto-sizing methodology. If not provided, no limit is used.',
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_fraction_heat_load_served',
      required: false,
      display_name: 'Heat Pump: Fraction Heat Load Served',
      description: 'The heating load served by the heat pump.',
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_fraction_cool_load_served',
      required: false,
      display_name: 'Heat Pump: Fraction Cool Load Served',
      description: 'The cooling load served by the heat pump.',
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_compressor_lockout_temp',
      required: false,
      display_name: 'Heat Pump: Compressor Lockout Temperature',
      description: "The temperature below which the heat pump compressor is disabled. If both this and Backup Heating Lockout Temperature are provided and use the same value, it essentially defines a switchover temperature (for, e.g., a dual-fuel heat pump). Applies to all heat pump types other than #{HPXML::HVACTypeHeatPumpGroundToAir}.",
      default_href: "<a href='#{docs_base_url}#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='#{docs_base_url}#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='#{docs_base_url}#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='#{docs_base_url}#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>",
      units: 'F'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'heat_pump_backup_type',
      choices: heat_pump_backup_type_choices,
      required: false,
      display_name: 'Heat Pump: Backup Type',
      description: "The backup type of the heat pump. If '#{HPXML::HeatPumpBackupTypeIntegrated}', represents e.g. built-in electric strip heat or dual-fuel integrated furnace. If '#{HPXML::HeatPumpBackupTypeSeparate}', represents e.g. electric baseboard or boiler based on the Heating System 2 specified below. Use '#{Constants::None}' if there is no backup heating."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_backup_heating_autosizing_factor',
      required: false,
      display_name: 'Heat Pump: Backup Heating Autosizing Factor',
      description: "The capacity scaling factor applied to the auto-sizing methodology if Backup Type is '#{HPXML::HeatPumpBackupTypeIntegrated}'. If not provided, 1.0 is used. If Backup Type is '#{HPXML::HeatPumpBackupTypeSeparate}', use Heating System 2: Heating Autosizing Factor."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_backup_heating_autosizing_limit',
      required: false,
      display_name: 'Heat Pump: Backup Heating Autosizing Limit',
      description: "The maximum capacity limit applied to the auto-sizing methodology if Backup Type is '#{HPXML::HeatPumpBackupTypeIntegrated}'. If not provided, no limit is used. If Backup Type is '#{HPXML::HeatPumpBackupTypeSeparate}', use Heating System 2: Heating Autosizing Limit.",
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'heat_pump_backup_fuel',
      choices: heat_pump_backup_fuel_choices,
      required: false,
      display_name: 'Heat Pump: Backup Fuel Type',
      description: "The backup fuel type of the heat pump. Only applies if Backup Type is '#{HPXML::HeatPumpBackupTypeIntegrated}'."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_backup_heating_efficiency',
      required: false,
      display_name: 'Heat Pump: Backup Rated Efficiency',
      description: "The backup rated efficiency value of the heat pump. Percent for electricity fuel type. AFUE otherwise. Only applies if Backup Type is '#{HPXML::HeatPumpBackupTypeIntegrated}'."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_backup_heating_capacity',
      required: false,
      display_name: 'Heat Pump: Backup Heating Capacity',
      description: "The backup output heating capacity of the heat pump. Only applies if Backup Type is '#{HPXML::HeatPumpBackupTypeIntegrated}'.",
      default_href: "<a href='#{docs_base_url}#backup'>Backup</a>",
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_backup_heating_lockout_temp',
      required: false,
      display_name: 'Heat Pump: Backup Heating Lockout Temperature',
      description: "The temperature above which the heat pump backup system is disabled. If both this and Compressor Lockout Temperature are provided and use the same value, it essentially defines a switchover temperature (for, e.g., a dual-fuel heat pump). Applies for both Backup Type of '#{HPXML::HeatPumpBackupTypeIntegrated}' and '#{HPXML::HeatPumpBackupTypeSeparate}'.",
      default_href: "<a href='#{docs_base_url}#backup'>Backup</a>",
      units: 'F'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'heat_pump_sizing_methodology',
      choices: heat_pump_sizing_choices,
      required: false,
      display_name: 'Heat Pump: Sizing Methodology',
      description: 'The auto-sizing methodology to use when the heat pump capacity is not provided.',
      default_href: "<a href='#{docs_base_url}#hpxml-hvac-sizing-control'>HPXML HVAC Sizing Control</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'heat_pump_backup_sizing_methodology',
      choices: heat_pump_backup_sizing_choices,
      required: false,
      display_name: 'Heat Pump: Backup Sizing Methodology',
      description: 'The auto-sizing methodology to use when the heat pump backup capacity is not provided.',
      default_href: "<a href='#{docs_base_url}#hpxml-hvac-sizing-control'>HPXML HVAC Sizing Control</a>"
    )

    args << makeArgument(
      name: 'heat_pump_is_ducted',
      type: Argument::Boolean,
      required: false,
      display_name: 'Heat Pump: Is Ducted',
      description: "Whether the heat pump is ducted or not. Only used for #{HPXML::HVACTypeHeatPumpMiniSplit}. It's assumed that #{HPXML::HVACTypeHeatPumpAirToAir} and #{HPXML::HVACTypeHeatPumpGroundToAir} are ducted, and #{HPXML::HVACTypeHeatPumpPTHP} and #{HPXML::HVACTypeHeatPumpRoom} are not ducted. If not provided, assumes not ducted."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_airflow_defect_ratio',
      required: false,
      display_name: 'Heat Pump: Airflow Defect Ratio',
      description: "The airflow defect ratio, defined as (InstalledAirflow - DesignAirflow) / DesignAirflow, of the heat pump per ANSI/RESNET/ACCA Standard 310. A value of zero means no airflow defect. Applies only to #{HPXML::HVACTypeHeatPumpAirToAir}, ducted #{HPXML::HVACTypeHeatPumpMiniSplit}, and #{HPXML::HVACTypeHeatPumpGroundToAir}. If not provided, assumes no defect.",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_charge_defect_ratio',
      required: false,
      display_name: 'Heat Pump: Charge Defect Ratio',
      description: 'The refrigerant charge defect ratio, defined as (InstalledCharge - DesignCharge) / DesignCharge, of the heat pump per ANSI/RESNET/ACCA Standard 310. A value of zero means no refrigerant charge defect. Applies to all heat pump types. If not provided, assumes no defect.',
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heat_pump_crankcase_heater_watts',
      required: false,
      display_name: 'Heat Pump: Crankcase Heater Power Watts',
      description: "Heat Pump crankcase heater power consumption in Watts. Applies only to #{HPXML::HVACTypeHeatPumpAirToAir}, #{HPXML::HVACTypeHeatPumpMiniSplit}, #{HPXML::HVACTypeHeatPumpPTHP} and #{HPXML::HVACTypeHeatPumpRoom}.",
      default_href: "<a href='#{docs_base_url}#air-to-air-heat-pump'>Air-to-Air Heat Pump</a>, <a href='#{docs_base_url}#mini-split-heat-pump'>Mini-Split Heat Pump</a>, <a href='#{docs_base_url}#packaged-terminal-heat-pump'>Packaged Terminal Heat Pump</a>, <a href='#{docs_base_url}#room-air-conditioner-w-reverse-cycle'>Room Air Conditioner w/ Reverse Cycle</a>",
      units: 'W'
    )

    perf_data_capacity_type_choices = OpenStudio::StringVector.new
    perf_data_capacity_type_choices << 'Absolute capacities'
    perf_data_capacity_type_choices << 'Normalized capacity fractions'

    args << makeArgument(
      type: Argument::Choice,
      name: 'hvac_perf_data_capacity_type',
      choices: perf_data_capacity_type_choices,
      required: false,
      display_name: 'HVAC Detailed Performance Data: Capacity Type',
      description: 'Type of capacity values for detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps).'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_perf_data_heating_outdoor_temperatures',
      required: false,
      display_name: 'HVAC Detailed Performance Data: Heating Outdoor Temperatures',
      description: 'Outdoor temperatures of heating detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps). One of the outdoor temperatures must be 47 F. At least two performance data points are required using a comma-separated list.',
      units: 'F'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_perf_data_heating_min_speed_capacities',
      required: false,
      display_name: 'HVAC Detailed Performance Data: Heating Minimum Speed Capacities',
      description: 'Minimum speed capacities of heating detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps). At least two performance data points are required using a comma-separated list.',
      units: 'Btu/hr or Frac'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_perf_data_heating_max_speed_capacities',
      required: false,
      display_name: 'HVAC Detailed Performance Data: Heating Maximum Speed Capacities',
      description: 'Maximum speed capacities of heating detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps). At least two performance data points are required using a comma-separated list.',
      units: 'Btu/hr or Frac'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_perf_data_heating_min_speed_cops',
      required: false,
      display_name: 'HVAC Detailed Performance Data: Heating Minimum Speed COPs',
      description: 'Minimum speed efficiency COP values of heating detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps). At least two performance data points are required using a comma-separated list.',
      units: 'W/W'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_perf_data_heating_max_speed_cops',
      required: false,
      display_name: 'HVAC Detailed Performance Data: Heating Maximum Speed COPs',
      description: 'Maximum speed efficiency COP values of heating detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps). At least two performance data points are required using a comma-separated list.',
      units: 'W/W'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_perf_data_cooling_outdoor_temperatures',
      required: false,
      display_name: 'HVAC Detailed Performance Data: Cooling Outdoor Temperatures',
      description: 'Outdoor temperatures of cooling detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps). One of the outdoor temperatures must be 95 F. At least two performance data points are required using a comma-separated list.',
      units: 'F'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_perf_data_cooling_min_speed_capacities',
      required: false,
      display_name: 'HVAC Detailed Performance Data: Cooling Minimum Speed Capacities',
      description: 'Minimum speed capacities of cooling detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps). At least two performance data points are required using a comma-separated list.',
      units: 'Btu/hr or Frac'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_perf_data_cooling_max_speed_capacities',
      required: false,
      display_name: 'HVAC Detailed Performance Data: Cooling Maximum Speed Capacities',
      description: 'Maximum speed capacities of cooling detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps). At least two performance data points are required using a comma-separated list.',
      units: 'Btu/hr or Frac'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_perf_data_cooling_min_speed_cops',
      required: false,
      display_name: 'HVAC Detailed Performance Data: Cooling Minimum Speed COPs',
      description: 'Minimum speed efficiency COP values of cooling detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps). At least two performance data points are required using a comma-separated list.',
      units: 'W/W'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_perf_data_cooling_max_speed_cops',
      required: false,
      display_name: 'HVAC Detailed Performance Data: Cooling Maximum Speed COPs',
      description: 'Maximum speed efficiency COP values of cooling detailed performance data if available. Applies only to variable-speed air-source HVAC systems (central air conditioners, mini-split air conditioners, air-to-air heat pumps, and mini-split heat pumps). At least two performance data points are required using a comma-separated list.',
      units: 'W/W'
    )

    geothermal_loop_configuration_choices = OpenStudio::StringVector.new
    geothermal_loop_configuration_choices << Constants::None
    # geothermal_loop_configuration_choices << HPXML::GeothermalLoopLoopConfigurationDiagonal
    # geothermal_loop_configuration_choices << HPXML::GeothermalLoopLoopConfigurationHorizontal
    # geothermal_loop_configuration_choices << HPXML::GeothermalLoopLoopConfigurationOther
    geothermal_loop_configuration_choices << HPXML::GeothermalLoopLoopConfigurationVertical

    args << makeArgument(
      type: Argument::Choice,
      name: 'geothermal_loop_configuration',
      choices: geothermal_loop_configuration_choices,
      required: false,
      display_name: 'Geothermal Loop: Configuration',
      description: "Configuration of the geothermal loop. Only applies to #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump type.",
      default_href: "<a href='#{docs_base_url}#ground-to-air-heat-pump'>Ground-to-Air Heat Pump</a>"
    )

    geothermal_loop_borefield_configuration_choices = OpenStudio::StringVector.new
    valid_bore_configs = HVACSizing.get_geothermal_loop_valid_configurations
    valid_bore_configs.keys.each do |valid_bore_config|
      geothermal_loop_borefield_configuration_choices << valid_bore_config
    end

    args << makeArgument(
      type: Argument::Choice,
      name: 'geothermal_loop_borefield_configuration',
      choices: geothermal_loop_borefield_configuration_choices,
      required: false,
      display_name: 'Geothermal Loop: Borefield Configuration',
      description: "Borefield configuration of the geothermal loop. Only applies to #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump type.",
      default_href: "<a href='#{docs_base_url}#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geothermal_loop_loop_flow',
      required: false,
      display_name: 'Geothermal Loop: Loop Flow',
      description: "Water flow rate through the geothermal loop. Only applies to #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump type.",
      default_href: "<a href='#{docs_base_url}#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>",
      units: 'gpm'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'geothermal_loop_boreholes_count',
      required: false,
      display_name: 'Geothermal Loop: Boreholes Count',
      description: "Number of boreholes. Only applies to #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump type.",
      default_href: "<a href='#{docs_base_url}#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>",
      units: '#'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geothermal_loop_boreholes_length',
      required: false,
      display_name: 'Geothermal Loop: Boreholes Length',
      description: "Average length of each borehole (vertical). Only applies to #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump type.",
      default_href: "<a href='#{docs_base_url}#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>",
      units: 'ft'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geothermal_loop_boreholes_spacing',
      required: false,
      display_name: 'Geothermal Loop: Boreholes Spacing',
      description: "Distance between bores. Only applies to #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump type.",
      default_href: "<a href='#{docs_base_url}#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>",
      units: 'ft'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'geothermal_loop_boreholes_diameter',
      required: false,
      display_name: 'Geothermal Loop: Boreholes Diameter',
      description: "Diameter of bores. Only applies to #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump type.",
      default_href: "<a href='#{docs_base_url}#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>",
      units: 'in'
    )

    geothermal_loop_grout_or_pipe_type_choices = OpenStudio::StringVector.new
    geothermal_loop_grout_or_pipe_type_choices << HPXML::GeothermalLoopGroutOrPipeTypeStandard
    geothermal_loop_grout_or_pipe_type_choices << HPXML::GeothermalLoopGroutOrPipeTypeThermallyEnhanced

    args << makeArgument(
      type: Argument::Choice,
      name: 'geothermal_loop_grout_type',
      choices: geothermal_loop_grout_or_pipe_type_choices,
      required: false,
      display_name: 'Geothermal Loop: Grout Type',
      description: "Grout type of the geothermal loop. Only applies to #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump type.",
      default_href: "<a href='#{docs_base_url}#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'geothermal_loop_pipe_type',
      choices: geothermal_loop_grout_or_pipe_type_choices,
      required: false,
      display_name: 'Geothermal Loop: Pipe Type',
      description: "Pipe type of the geothermal loop. Only applies to #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump type.",
      default_href: "<a href='#{docs_base_url}#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>"
    )

    geothermal_loop_pipe_diameter_choices = OpenStudio::StringVector.new
    geothermal_loop_pipe_diameter_choices << '3/4" pipe'
    geothermal_loop_pipe_diameter_choices << '1" pipe'
    geothermal_loop_pipe_diameter_choices << '1-1/4" pipe'

    args << makeArgument(
      type: Argument::Choice,
      name: 'geothermal_loop_pipe_diameter',
      choices: geothermal_loop_pipe_diameter_choices,
      required: false,
      display_name: 'Geothermal Loop: Pipe Diameter',
      description: "Pipe diameter of the geothermal loop. Only applies to #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump type.",
      default_href: "<a href='#{docs_base_url}#hpxml-geothermal-loops'>HPXML Geothermal Loops</a>",
      units: 'in'
    )

    heating_system_2_type_choices = OpenStudio::StringVector.new
    heating_system_2_type_choices << Constants::None
    heating_system_2_type_choices << HPXML::HVACTypeFurnace
    heating_system_2_type_choices << HPXML::HVACTypeWallFurnace
    heating_system_2_type_choices << HPXML::HVACTypeFloorFurnace
    heating_system_2_type_choices << HPXML::HVACTypeBoiler
    heating_system_2_type_choices << HPXML::HVACTypeElectricResistance
    heating_system_2_type_choices << HPXML::HVACTypeStove
    heating_system_2_type_choices << HPXML::HVACTypeSpaceHeater
    heating_system_2_type_choices << HPXML::HVACTypeFireplace

    args << makeArgument(
      type: Argument::Choice,
      name: 'heating_system_2_type',
      choices: heating_system_2_type_choices,
      required: false,
      display_name: 'Heating System 2: Type',
      description: "The type of the second heating system. If a heat pump is specified and the backup type is '#{HPXML::HeatPumpBackupTypeSeparate}', this heating system represents '#{HPXML::HeatPumpBackupTypeSeparate}' backup heating. For ducted heat pumps where the backup heating system is a '#{HPXML::HVACTypeFurnace}', the backup would typically be characterized as '#{HPXML::HeatPumpBackupTypeIntegrated}' in that the furnace and heat pump share the same distribution system and blower fan; a '#{HPXML::HVACTypeFurnace}' as '#{HPXML::HeatPumpBackupTypeSeparate}' backup to a ducted heat pump is not supported. If not provided, defaults to none."
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'heating_system_2_fuel',
      choices: heating_system_fuel_choices,
      required: false,
      display_name: 'Heating System 2: Fuel Type',
      description: "The fuel type of the second heating system. Ignored for #{HPXML::HVACTypeElectricResistance}."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_2_heating_efficiency',
      required: false,
      display_name: 'Heating System 2: Rated AFUE or Percent',
      units: 'Frac',
      description: 'The rated heating efficiency value of the second heating system.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_2_heating_capacity',
      required: false,
      display_name: 'Heating System 2: Heating Capacity',
      description: 'The output heating capacity of the second heating system.',
      default_href: "<a href='#{docs_base_url}#hpxml-heating-systems'>HPXML Heating Systems</a>",
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_2_heating_autosizing_factor',
      required: false,
      display_name: 'Heating System 2: Heating Autosizing Factor',
      description: 'The capacity scaling factor applied to the auto-sizing methodology. If not provided, 1.0 is used.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_2_heating_autosizing_limit',
      required: false,
      display_name: 'Heating System 2: Heating Autosizing Limit',
      description: 'The maximum capacity limit applied to the auto-sizing methodology. If not provided, no limit is used.',
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'heating_system_2_fraction_heat_load_served',
      required: false,
      display_name: 'Heating System 2: Fraction Heat Load Served',
      description: 'The heat load served fraction of the second heating system. Ignored if this heating system serves as a backup system for a heat pump.',
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_control_heating_weekday_setpoint',
      required: false,
      display_name: 'HVAC Control: Heating Weekday Setpoint Schedule',
      description: 'Specify the constant or 24-hour comma-separated weekday heating setpoint schedule. Required unless a detailed CSV schedule is provided.',
      units: 'F'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_control_heating_weekend_setpoint',
      required: false,
      display_name: 'HVAC Control: Heating Weekend Setpoint Schedule',
      description: 'Specify the constant or 24-hour comma-separated weekend heating setpoint schedule. Required unless a detailed CSV schedule is provided.',
      units: 'F'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_control_cooling_weekday_setpoint',
      required: false,
      display_name: 'HVAC Control: Cooling Weekday Setpoint Schedule',
      description: 'Specify the constant or 24-hour comma-separated weekday cooling setpoint schedule. Required unless a detailed CSV schedule is provided.',
      units: 'F'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_control_cooling_weekend_setpoint',
      required: false,
      display_name: 'HVAC Control: Cooling Weekend Setpoint Schedule',
      description: 'Specify the constant or 24-hour comma-separated weekend cooling setpoint schedule. Required unless a detailed CSV schedule is provided.',
      units: 'F'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_control_heating_season_period',
      required: false,
      display_name: 'HVAC Control: Heating Season Period',
      description: "Enter a date range like 'Nov 1 - Jun 30'. Can also provide '#{Constants::BuildingAmerica}' to use automatic seasons from the Building America House Simulation Protocols.",
      default_href: "<a href='#{docs_base_url}#hpxml-hvac-control'>HPXML HVAC Control</a>"
    )

    args << makeArgument(
      type: Argument::String,
      name: 'hvac_control_cooling_season_period',
      required: false,
      display_name: 'HVAC Control: Cooling Season Period',
      description: "Enter a date range like 'Jun 1 - Oct 31'. Can also provide '#{Constants::BuildingAmerica}' to use automatic seasons from the Building America House Simulation Protocols.",
      default_href: "<a href='#{docs_base_url}#hpxml-hvac-control'>HPXML HVAC Control</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'hvac_blower_fan_watts_per_cfm',
      required: false,
      display_name: 'HVAC Blower: Fan Efficiency',
      description: "The blower fan efficiency at maximum fan speed. Applies only to split (not packaged) systems (i.e., applies to ducted systems as well as ductless #{HPXML::HVACTypeHeatPumpMiniSplit} systems).",
      default_href: "<a href='#{docs_base_url}#hpxml-heating-systems'>HPXML Heating Systems</a>, <a href='#{docs_base_url}#hpxml-cooling-systems'>HPXML Cooling Systems</a>, <a href='#{docs_base_url}#hpxml-heat-pumps'>HPXML Heat Pumps</a>",
      units: 'W/CFM'
    )

    duct_leakage_units_choices = OpenStudio::StringVector.new
    duct_leakage_units_choices << HPXML::UnitsCFM25
    duct_leakage_units_choices << HPXML::UnitsCFM50
    duct_leakage_units_choices << HPXML::UnitsPercent

    duct_location_choices = OpenStudio::StringVector.new
    duct_location_choices << HPXML::LocationConditionedSpace
    duct_location_choices << HPXML::LocationBasementConditioned
    duct_location_choices << HPXML::LocationBasementUnconditioned
    duct_location_choices << HPXML::LocationCrawlspace
    duct_location_choices << HPXML::LocationCrawlspaceVented
    duct_location_choices << HPXML::LocationCrawlspaceUnvented
    duct_location_choices << HPXML::LocationCrawlspaceConditioned
    duct_location_choices << HPXML::LocationAttic
    duct_location_choices << HPXML::LocationAtticVented
    duct_location_choices << HPXML::LocationAtticUnvented
    duct_location_choices << HPXML::LocationGarage
    duct_location_choices << HPXML::LocationExteriorWall
    duct_location_choices << HPXML::LocationUnderSlab
    duct_location_choices << HPXML::LocationRoofDeck
    duct_location_choices << HPXML::LocationOutside
    duct_location_choices << HPXML::LocationOtherHousingUnit
    duct_location_choices << HPXML::LocationOtherHeatedSpace
    duct_location_choices << HPXML::LocationOtherMultifamilyBufferSpace
    duct_location_choices << HPXML::LocationOtherNonFreezingSpace
    duct_location_choices << HPXML::LocationManufacturedHomeBelly

    args << makeArgument(
      type: Argument::Choice,
      name: 'ducts_leakage_units',
      choices: duct_leakage_units_choices,
      required: false,
      display_name: 'Ducts: Leakage Units',
      description: 'The leakage units of the ducts.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ducts_supply_leakage_to_outside_value',
      required: false,
      display_name: 'Ducts: Supply Leakage to Outside Value',
      description: 'The leakage value to outside for the supply ducts.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'ducts_supply_location',
      choices: duct_location_choices,
      required: false,
      display_name: 'Ducts: Supply Location',
      description: 'The location of the supply ducts.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ducts_supply_insulation_r',
      required: false,
      display_name: 'Ducts: Supply Insulation R-Value',
      description: 'The nominal insulation r-value of the supply ducts excluding air films. Use 0 for uninsulated ducts.',
      units: 'h-ft^2-R/Btu'
    )

    duct_buried_level_choices = OpenStudio::StringVector.new
    duct_buried_level_choices << HPXML::DuctBuriedInsulationNone
    duct_buried_level_choices << HPXML::DuctBuriedInsulationPartial
    duct_buried_level_choices << HPXML::DuctBuriedInsulationFull
    duct_buried_level_choices << HPXML::DuctBuriedInsulationDeep

    args << makeArgument(
      type: Argument::Choice,
      name: 'ducts_supply_buried_insulation_level',
      choices: duct_buried_level_choices,
      required: false,
      display_name: 'Ducts: Supply Buried Insulation Level',
      description: 'Whether the supply ducts are buried in, e.g., attic loose-fill insulation. Partially buried ducts have insulation that does not cover the top of the ducts. Fully buried ducts have insulation that just covers the top of the ducts. Deeply buried ducts have insulation that continues above the top of the ducts.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ducts_supply_surface_area',
      required: false,
      display_name: 'Ducts: Supply Surface Area',
      description: 'The supply ducts surface area in the given location.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>",
      units: 'ft^2'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ducts_supply_surface_area_fraction',
      required: false,
      display_name: 'Ducts: Supply Area Fraction',
      description: 'The fraction of supply ducts surface area in the given location. Only used if Surface Area is not provided. If the fraction is less than 1, the remaining duct area is assumed to be in conditioned space.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>",
      units: 'frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ducts_supply_fraction_rectangular',
      required: false,
      display_name: 'Ducts: Supply Fraction Rectangular',
      description: 'The fraction of supply ducts that are rectangular (as opposed to round); this affects the duct effective R-value used for modeling.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>",
      units: 'frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ducts_return_leakage_to_outside_value',
      required: false,
      display_name: 'Ducts: Return Leakage to Outside Value',
      description: 'The leakage value to outside for the return ducts.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'ducts_return_location',
      choices: duct_location_choices,
      required: false,
      display_name: 'Ducts: Return Location',
      description: 'The location of the return ducts.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ducts_return_insulation_r',
      required: false,
      display_name: 'Ducts: Return Insulation R-Value',
      description: 'The nominal insulation r-value of the return ducts excluding air films. Use 0 for uninsulated ducts.',
      units: 'h-ft^2-R/Btu'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'ducts_return_buried_insulation_level',
      choices: duct_buried_level_choices,
      required: false,
      display_name: 'Ducts: Return Buried Insulation Level',
      description: 'Whether the return ducts are buried in, e.g., attic loose-fill insulation. Partially buried ducts have insulation that does not cover the top of the ducts. Fully buried ducts have insulation that just covers the top of the ducts. Deeply buried ducts have insulation that continues above the top of the ducts.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ducts_return_surface_area',
      required: false,
      display_name: 'Ducts: Return Surface Area',
      description: 'The return ducts surface area in the given location.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>",
      units: 'ft^2'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ducts_return_surface_area_fraction',
      required: false,
      display_name: 'Ducts: Return Area Fraction',
      description: 'The fraction of return ducts surface area in the given location. Only used if Surface Area is not provided. If the fraction is less than 1, the remaining duct area is assumed to be in conditioned space.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>",
      units: 'frac'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'ducts_number_of_return_registers',
      required: false,
      display_name: 'Ducts: Number of Return Registers',
      description: 'The number of return registers of the ducts. Only used to calculate default return duct surface area.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>",
      units: '#'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ducts_return_fraction_rectangular',
      required: false,
      display_name: 'Ducts: Return Fraction Rectangular',
      description: 'The fraction of return ducts that are rectangular (as opposed to round); this affects the duct effective R-value used for modeling.',
      default_href: "<a href='#{docs_base_url}#air-distribution'>Air Distribution</a>",
      units: 'frac'
    )

    mech_vent_fan_type_choices = OpenStudio::StringVector.new
    mech_vent_fan_type_choices << Constants::None
    mech_vent_fan_type_choices << HPXML::MechVentTypeExhaust
    mech_vent_fan_type_choices << HPXML::MechVentTypeSupply
    mech_vent_fan_type_choices << HPXML::MechVentTypeERV
    mech_vent_fan_type_choices << HPXML::MechVentTypeHRV
    mech_vent_fan_type_choices << HPXML::MechVentTypeBalanced
    mech_vent_fan_type_choices << HPXML::MechVentTypeCFIS

    mech_vent_recovery_efficiency_type_choices = OpenStudio::StringVector.new
    mech_vent_recovery_efficiency_type_choices << 'Unadjusted'
    mech_vent_recovery_efficiency_type_choices << 'Adjusted'

    args << makeArgument(
      type: Argument::Choice,
      name: 'mech_vent_fan_type',
      choices: mech_vent_fan_type_choices,
      required: false,
      display_name: 'Mechanical Ventilation: Fan Type',
      description: "The type of the mechanical ventilation. Use '#{Constants::None}' if there is no mechanical ventilation system. If not provided, defaults to none."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_flow_rate',
      required: false,
      display_name: 'Mechanical Ventilation: Flow Rate',
      description: 'The flow rate of the mechanical ventilation.',
      default_href: "<a href='#{docs_base_url}#hpxml-mechanical-ventilation-fans'>HPXML Mechanical Ventilation Fans</a>",
      units: 'CFM'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_hours_in_operation',
      required: false,
      display_name: 'Mechanical Ventilation: Hours In Operation',
      description: 'The hours in operation of the mechanical ventilation.',
      default_href: "<a href='#{docs_base_url}#hpxml-mechanical-ventilation-fans'>HPXML Mechanical Ventilation Fans</a>",
      units: 'hrs/day'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'mech_vent_recovery_efficiency_type',
      choices: mech_vent_recovery_efficiency_type_choices,
      required: false,
      display_name: 'Mechanical Ventilation: Total Recovery Efficiency Type',
      description: 'The total recovery efficiency type of the mechanical ventilation.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_total_recovery_efficiency',
      required: false,
      display_name: 'Mechanical Ventilation: Total Recovery Efficiency',
      description: "The Unadjusted or Adjusted total recovery efficiency of the mechanical ventilation. Applies to #{HPXML::MechVentTypeERV}.",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_sensible_recovery_efficiency',
      required: false,
      display_name: 'Mechanical Ventilation: Sensible Recovery Efficiency',
      description: "The Unadjusted or Adjusted sensible recovery efficiency of the mechanical ventilation. Applies to #{HPXML::MechVentTypeERV} and #{HPXML::MechVentTypeHRV}.",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_fan_power',
      required: false,
      display_name: 'Mechanical Ventilation: Fan Power',
      description: 'The fan power of the mechanical ventilation.',
      default_href: "<a href='#{docs_base_url}#hpxml-mechanical-ventilation-fans'>HPXML Mechanical Ventilation Fans</a>",
      units: 'W'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'mech_vent_num_units_served',
      required: false,
      display_name: 'Mechanical Ventilation: Number of Units Served',
      description: "Number of dwelling units served by the mechanical ventilation system. Must be 1 if #{HPXML::ResidentialTypeSFD}. Used to apportion flow rate and fan power to the unit.",
      units: '#'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_shared_frac_recirculation',
      required: false,
      display_name: 'Shared Mechanical Ventilation: Fraction Recirculation',
      description: 'Fraction of the total supply air that is recirculated, with the remainder assumed to be outdoor air. The value must be 0 for exhaust only systems. Required for a shared mechanical ventilation system.',
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'mech_vent_shared_preheating_fuel',
      choices: heating_system_fuel_choices,
      required: false,
      display_name: 'Shared Mechanical Ventilation: Preheating Fuel',
      description: 'Fuel type of the preconditioning heating equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no preheating.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_shared_preheating_efficiency',
      required: false,
      display_name: 'Shared Mechanical Ventilation: Preheating Efficiency',
      description: 'Efficiency of the preconditioning heating equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no preheating.',
      units: 'COP'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_shared_preheating_fraction_heat_load_served',
      required: false,
      display_name: 'Shared Mechanical Ventilation: Preheating Fraction Ventilation Heat Load Served',
      description: 'Fraction of heating load introduced by the shared ventilation system that is met by the preconditioning heating equipment. If not provided, assumes no preheating.',
      units: 'Frac'
    )

    cooling_system_fuel_choices = OpenStudio::StringVector.new
    cooling_system_fuel_choices << HPXML::FuelTypeElectricity

    args << makeArgument(
      type: Argument::Choice,
      name: 'mech_vent_shared_precooling_fuel',
      choices: cooling_system_fuel_choices,
      required: false,
      display_name: 'Shared Mechanical Ventilation: Precooling Fuel',
      description: 'Fuel type of the preconditioning cooling equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no precooling.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_shared_precooling_efficiency',
      required: false,
      display_name: 'Shared Mechanical Ventilation: Precooling Efficiency',
      description: 'Efficiency of the preconditioning cooling equipment. Only used for a shared mechanical ventilation system. If not provided, assumes no precooling.',
      units: 'COP'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_shared_precooling_fraction_cool_load_served',
      required: false,
      display_name: 'Shared Mechanical Ventilation: Precooling Fraction Ventilation Cool Load Served',
      description: 'Fraction of cooling load introduced by the shared ventilation system that is met by the preconditioning cooling equipment. If not provided, assumes no precooling.',
      units: 'Frac'
    )

    mech_vent_2_fan_type_choices = OpenStudio::StringVector.new
    mech_vent_2_fan_type_choices << Constants::None
    mech_vent_2_fan_type_choices << HPXML::MechVentTypeExhaust
    mech_vent_2_fan_type_choices << HPXML::MechVentTypeSupply
    mech_vent_2_fan_type_choices << HPXML::MechVentTypeERV
    mech_vent_2_fan_type_choices << HPXML::MechVentTypeHRV
    mech_vent_2_fan_type_choices << HPXML::MechVentTypeBalanced

    args << makeArgument(
      type: Argument::Choice,
      name: 'mech_vent_2_fan_type',
      choices: mech_vent_2_fan_type_choices,
      required: false,
      display_name: 'Mechanical Ventilation 2: Fan Type',
      description: "The type of the second mechanical ventilation. Use '#{Constants::None}' if there is no second mechanical ventilation system. If not provided, defaults to none."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_2_flow_rate',
      required: false,
      display_name: 'Mechanical Ventilation 2: Flow Rate',
      description: 'The flow rate of the second mechanical ventilation.',
      units: 'CFM'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_2_hours_in_operation',
      required: false,
      display_name: 'Mechanical Ventilation 2: Hours In Operation',
      description: 'The hours in operation of the second mechanical ventilation.',
      units: 'hrs/day'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'mech_vent_2_recovery_efficiency_type',
      choices: mech_vent_recovery_efficiency_type_choices,
      required: false,
      display_name: 'Mechanical Ventilation 2: Total Recovery Efficiency Type',
      description: 'The total recovery efficiency type of the second mechanical ventilation.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_2_total_recovery_efficiency',
      required: false,
      display_name: 'Mechanical Ventilation 2: Total Recovery Efficiency',
      description: "The Unadjusted or Adjusted total recovery efficiency of the second mechanical ventilation. Applies to #{HPXML::MechVentTypeERV}.",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_2_sensible_recovery_efficiency',
      required: false,
      display_name: 'Mechanical Ventilation 2: Sensible Recovery Efficiency',
      description: "The Unadjusted or Adjusted sensible recovery efficiency of the second mechanical ventilation. Applies to #{HPXML::MechVentTypeERV} and #{HPXML::MechVentTypeHRV}.",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'mech_vent_2_fan_power',
      required: false,
      display_name: 'Mechanical Ventilation 2: Fan Power',
      description: 'The fan power of the second mechanical ventilation.',
      units: 'W'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'kitchen_fans_quantity',
      required: false,
      display_name: 'Kitchen Fans: Quantity',
      description: 'The quantity of the kitchen fans.',
      default_href: "<a href='#{docs_base_url}#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>",
      units: '#'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'kitchen_fans_flow_rate',
      required: false,
      display_name: 'Kitchen Fans: Flow Rate',
      description: 'The flow rate of the kitchen fan.',
      default_href: "<a href='#{docs_base_url}#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>",
      units: 'CFM'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'kitchen_fans_hours_in_operation',
      required: false,
      display_name: 'Kitchen Fans: Hours In Operation',
      description: 'The hours in operation of the kitchen fan.',
      default_href: "<a href='#{docs_base_url}#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>",
      units: 'hrs/day'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'kitchen_fans_power',
      required: false,
      display_name: 'Kitchen Fans: Fan Power',
      description: 'The fan power of the kitchen fan.',
      default_href: "<a href='#{docs_base_url}#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>",
      units: 'W'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'kitchen_fans_start_hour',
      required: false,
      display_name: 'Kitchen Fans: Start Hour',
      description: 'The start hour of the kitchen fan.',
      default_href: "<a href='#{docs_base_url}#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>",
      units: 'hr'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'bathroom_fans_quantity',
      required: false,
      display_name: 'Bathroom Fans: Quantity',
      description: 'The quantity of the bathroom fans.',
      default_href: "<a href='#{docs_base_url}#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>",
      units: '#'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'bathroom_fans_flow_rate',
      required: false,
      display_name: 'Bathroom Fans: Flow Rate',
      description: 'The flow rate of the bathroom fans.',
      default_href: "<a href='#{docs_base_url}#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>",
      units: 'CFM'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'bathroom_fans_hours_in_operation',
      required: false,
      display_name: 'Bathroom Fans: Hours In Operation',
      description: 'The hours in operation of the bathroom fans.',
      default_href: "<a href='#{docs_base_url}#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>",
      units: 'hrs/day'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'bathroom_fans_power',
      required: false,
      display_name: 'Bathroom Fans: Fan Power',
      description: 'The fan power of the bathroom fans.',
      default_href: "<a href='#{docs_base_url}#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>",
      units: 'W'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'bathroom_fans_start_hour',
      required: false,
      display_name: 'Bathroom Fans: Start Hour',
      description: 'The start hour of the bathroom fans.',
      default_href: "<a href='#{docs_base_url}#hpxml-local-ventilation-fans'>HPXML Local Ventilation Fans</a>",
      units: 'hr'
    )

    args << makeArgument(
      name: 'whole_house_fan_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Whole House Fan: Present',
      description: 'Whether there is a whole house fan.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'whole_house_fan_flow_rate',
      required: false,
      display_name: 'Whole House Fan: Flow Rate',
      description: 'The flow rate of the whole house fan.',
      default_href: "<a href='#{docs_base_url}#hpxml-whole-house-fans'>HPXML Whole House Fans</a>",
      units: 'CFM'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'whole_house_fan_power',
      required: false,
      display_name: 'Whole House Fan: Fan Power',
      description: 'The fan power of the whole house fan.',
      default_href: "<a href='#{docs_base_url}#hpxml-whole-house-fans'>HPXML Whole House Fans</a>",
      units: 'W'
    )

    water_heater_type_choices = OpenStudio::StringVector.new
    water_heater_type_choices << Constants::None
    water_heater_type_choices << HPXML::WaterHeaterTypeStorage
    water_heater_type_choices << HPXML::WaterHeaterTypeTankless
    water_heater_type_choices << HPXML::WaterHeaterTypeHeatPump
    water_heater_type_choices << HPXML::WaterHeaterTypeCombiStorage
    water_heater_type_choices << HPXML::WaterHeaterTypeCombiTankless

    water_heater_fuel_choices = OpenStudio::StringVector.new
    water_heater_fuel_choices << HPXML::FuelTypeElectricity
    water_heater_fuel_choices << HPXML::FuelTypeNaturalGas
    water_heater_fuel_choices << HPXML::FuelTypeOil
    water_heater_fuel_choices << HPXML::FuelTypePropane
    water_heater_fuel_choices << HPXML::FuelTypeWoodCord
    water_heater_fuel_choices << HPXML::FuelTypeCoal

    water_heater_location_choices = OpenStudio::StringVector.new
    water_heater_location_choices << HPXML::LocationConditionedSpace
    water_heater_location_choices << HPXML::LocationBasementConditioned
    water_heater_location_choices << HPXML::LocationBasementUnconditioned
    water_heater_location_choices << HPXML::LocationGarage
    water_heater_location_choices << HPXML::LocationAttic
    water_heater_location_choices << HPXML::LocationAtticVented
    water_heater_location_choices << HPXML::LocationAtticUnvented
    water_heater_location_choices << HPXML::LocationCrawlspace
    water_heater_location_choices << HPXML::LocationCrawlspaceVented
    water_heater_location_choices << HPXML::LocationCrawlspaceUnvented
    water_heater_location_choices << HPXML::LocationCrawlspaceConditioned
    water_heater_location_choices << HPXML::LocationOtherExterior
    water_heater_location_choices << HPXML::LocationOtherHousingUnit
    water_heater_location_choices << HPXML::LocationOtherHeatedSpace
    water_heater_location_choices << HPXML::LocationOtherMultifamilyBufferSpace
    water_heater_location_choices << HPXML::LocationOtherNonFreezingSpace

    water_heater_efficiency_type_choices = OpenStudio::StringVector.new
    water_heater_efficiency_type_choices << 'EnergyFactor'
    water_heater_efficiency_type_choices << 'UniformEnergyFactor'

    water_heater_usage_bin_choices = OpenStudio::StringVector.new
    water_heater_usage_bin_choices << HPXML::WaterHeaterUsageBinVerySmall
    water_heater_usage_bin_choices << HPXML::WaterHeaterUsageBinLow
    water_heater_usage_bin_choices << HPXML::WaterHeaterUsageBinMedium
    water_heater_usage_bin_choices << HPXML::WaterHeaterUsageBinHigh

    args << makeArgument(
      type: Argument::Choice,
      name: 'water_heater_type',
      choices: water_heater_type_choices,
      required: true,
      display_name: 'Water Heater: Type',
      description: "The type of water heater. Use '#{Constants::None}' if there is no water heater."
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'water_heater_fuel_type',
      choices: water_heater_fuel_choices,
      required: false,
      display_name: 'Water Heater: Fuel Type',
      description: "The fuel type of water heater. Ignored for #{HPXML::WaterHeaterTypeHeatPump}."
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'water_heater_location',
      choices: water_heater_location_choices,
      required: false,
      display_name: 'Water Heater: Location',
      description: 'The location of water heater.',
      default_href: "<a href='#{docs_base_url}#hpxml-water-heating-systems'>HPXML Water Heating Systems</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'water_heater_tank_volume',
      required: false,
      display_name: 'Water Heater: Tank Volume',
      description: 'Nominal volume of water heater tank.',
      default_href: "<a href='#{docs_base_url}#conventional-storage'>Conventional Storage</a>, <a href='#{docs_base_url}#heat-pump'>Heat Pump</a>, <a href='#{docs_base_url}#combi-boiler-w-storage'>Combi Boiler w/ Storage</a>",
      units: 'gal'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'water_heater_efficiency_type',
      choices: water_heater_efficiency_type_choices,
      required: false,
      display_name: 'Water Heater: Efficiency Type',
      description: 'The efficiency type of water heater. Does not apply to space-heating boilers.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'water_heater_efficiency',
      required: false,
      display_name: 'Water Heater: Efficiency',
      description: 'Rated Energy Factor or Uniform Energy Factor. Does not apply to space-heating boilers.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'water_heater_usage_bin',
      choices: water_heater_usage_bin_choices,
      required: false,
      display_name: 'Water Heater: Usage Bin',
      description: "The usage of the water heater. Only applies if Efficiency Type is UniformEnergyFactor and Type is not #{HPXML::WaterHeaterTypeTankless}. Does not apply to space-heating boilers.",
      default_href: "<a href='#{docs_base_url}#conventional-storage'>Conventional Storage</a>, <a href='#{docs_base_url}#heat-pump'>Heat Pump</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'water_heater_recovery_efficiency',
      required: false,
      display_name: 'Water Heater: Recovery Efficiency',
      description: 'Ratio of energy delivered to water heater to the energy content of the fuel consumed by the water heater. Only used for non-electric storage water heaters.',
      default_href: "<a href='#{docs_base_url}#conventional-storage'>Conventional Storage</a>",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'water_heater_heating_capacity',
      required: false,
      display_name: 'Water Heater: Heating Capacity',
      description: "Heating capacity. Only applies to #{HPXML::WaterHeaterTypeStorage} and #{HPXML::WaterHeaterTypeHeatPump} (compressor).",
      default_href: "<a href='#{docs_base_url}#conventional-storage'>Conventional Storage</a>, <a href='#{docs_base_url}#heat-pump'>Heat Pump</a>",
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'water_heater_backup_heating_capacity',
      required: false,
      display_name: 'Water Heater: Backup Heating Capacity',
      description: "Backup heating capacity for a #{HPXML::WaterHeaterTypeHeatPump}.",
      default_href: "<a href='#{docs_base_url}#heat-pump'>Heat Pump</a>",
      units: 'Btu/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'water_heater_standby_loss',
      required: false,
      display_name: 'Water Heater: Standby Loss',
      description: 'The standby loss of water heater. Only applies to space-heating boilers.',
      default_href: "<a href='#{docs_base_url}#combi-boiler-w-storage'>Combi Boiler w/ Storage</a>",
      units: 'F/hr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'water_heater_jacket_rvalue',
      required: false,
      display_name: 'Water Heater: Jacket R-value',
      description: "The jacket R-value of water heater. Doesn't apply to #{HPXML::WaterHeaterTypeTankless} or #{HPXML::WaterHeaterTypeCombiTankless}. If not provided, defaults to no jacket insulation.",
      units: 'h-ft^2-R/Btu'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'water_heater_setpoint_temperature',
      required: false,
      display_name: 'Water Heater: Setpoint Temperature',
      description: 'The setpoint temperature of water heater.',
      default_href: "<a href='#{docs_base_url}#hpxml-water-heating-systems'>HPXML Water Heating Systems</a>",
      units: 'F'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'water_heater_num_bedrooms_served',
      required: false,
      display_name: 'Water Heater: Number of Bedrooms Served',
      description: "Number of bedrooms served (directly or indirectly) by the water heater. Only needed if #{HPXML::ResidentialTypeSFA} or #{HPXML::ResidentialTypeApartment} and it is a shared water heater serving multiple dwelling units. Used to apportion water heater tank losses to the unit.",
      units: '#'
    )

    args << makeArgument(
      name: 'water_heater_uses_desuperheater',
      type: Argument::Boolean,
      required: false,
      display_name: 'Water Heater: Uses Desuperheater',
      description: "Requires that the dwelling unit has a #{HPXML::HVACTypeHeatPumpAirToAir}, #{HPXML::HVACTypeHeatPumpMiniSplit}, or #{HPXML::HVACTypeHeatPumpGroundToAir} heat pump or a #{HPXML::HVACTypeCentralAirConditioner} or #{HPXML::HVACTypeMiniSplitAirConditioner} air conditioner. If not provided, assumes no desuperheater."
    )

    water_heater_tank_model_type_choices = OpenStudio::StringVector.new
    water_heater_tank_model_type_choices << HPXML::WaterHeaterTankModelTypeMixed
    water_heater_tank_model_type_choices << HPXML::WaterHeaterTankModelTypeStratified

    args << makeArgument(
      type: Argument::Choice,
      name: 'water_heater_tank_model_type',
      choices: water_heater_tank_model_type_choices,
      required: false,
      display_name: 'Water Heater: Tank Type',
      description: "Type of tank model to use. The '#{HPXML::WaterHeaterTankModelTypeStratified}' tank generally provide more accurate results, but may significantly increase run time. Applies only to #{HPXML::WaterHeaterTypeStorage}.",
      default_href: "<a href='#{docs_base_url}#conventional-storage'>Conventional Storage</a>"
    )

    water_heater_operating_mode_choices = OpenStudio::StringVector.new
    water_heater_operating_mode_choices << HPXML::WaterHeaterOperatingModeHybridAuto
    water_heater_operating_mode_choices << HPXML::WaterHeaterOperatingModeHeatPumpOnly

    args << makeArgument(
      type: Argument::Choice,
      name: 'water_heater_operating_mode',
      choices: water_heater_operating_mode_choices,
      required: false,
      display_name: 'Water Heater: Operating Mode',
      description: "The water heater operating mode. The '#{HPXML::WaterHeaterOperatingModeHeatPumpOnly}' option only uses the heat pump, while '#{HPXML::WaterHeaterOperatingModeHybridAuto}' allows the backup electric resistance to come on in high demand situations. This is ignored if a scheduled operating mode type is selected. Applies only to #{HPXML::WaterHeaterTypeHeatPump}.",
      default_href: "<a href='#{docs_base_url}#heat-pump'>Heat Pump</a>"
    )

    hot_water_distribution_system_type_choices = OpenStudio::StringVector.new
    hot_water_distribution_system_type_choices << HPXML::DHWDistTypeStandard
    hot_water_distribution_system_type_choices << HPXML::DHWDistTypeRecirc

    args << makeArgument(
      type: Argument::Choice,
      name: 'hot_water_distribution_system_type',
      choices: hot_water_distribution_system_type_choices,
      required: true,
      display_name: 'Hot Water Distribution: System Type',
      description: 'The type of the hot water distribution system.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'hot_water_distribution_standard_piping_length',
      required: false,
      display_name: 'Hot Water Distribution: Standard Piping Length',
      units: 'ft',
      description: "If the distribution system is #{HPXML::DHWDistTypeStandard}, the length of the piping.",
      default_href: "<a href='#{docs_base_url}#standard'>Standard</a>"
    )

    recirculation_control_type_choices = OpenStudio::StringVector.new
    recirculation_control_type_choices << HPXML::DHWRecircControlTypeNone
    recirculation_control_type_choices << HPXML::DHWRecircControlTypeTimer
    recirculation_control_type_choices << HPXML::DHWRecircControlTypeTemperature
    recirculation_control_type_choices << HPXML::DHWRecircControlTypeSensor
    recirculation_control_type_choices << HPXML::DHWRecircControlTypeManual

    args << makeArgument(
      type: Argument::Choice,
      name: 'hot_water_distribution_recirc_control_type',
      choices: recirculation_control_type_choices,
      required: false,
      display_name: 'Hot Water Distribution: Recirculation Control Type',
      description: "If the distribution system is #{HPXML::DHWDistTypeRecirc}, the type of hot water recirculation control, if any."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'hot_water_distribution_recirc_piping_length',
      required: false,
      display_name: 'Hot Water Distribution: Recirculation Piping Length',
      units: 'ft',
      description: "If the distribution system is #{HPXML::DHWDistTypeRecirc}, the length of the recirculation piping.",
      default_href: "<a href='#{docs_base_url}#recirculation-in-unit'>Recirculation (In-Unit)</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'hot_water_distribution_recirc_branch_piping_length',
      required: false,
      display_name: 'Hot Water Distribution: Recirculation Branch Piping Length',
      units: 'ft',
      description: "If the distribution system is #{HPXML::DHWDistTypeRecirc}, the length of the recirculation branch piping.",
      default_href: "<a href='#{docs_base_url}#recirculation-in-unit'>Recirculation (In-Unit)</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'hot_water_distribution_recirc_pump_power',
      required: false,
      display_name: 'Hot Water Distribution: Recirculation Pump Power',
      units: 'W',
      description: "If the distribution system is #{HPXML::DHWDistTypeRecirc}, the recirculation pump power.",
      default_href: "<a href='#{docs_base_url}#recirculation-in-unit'>Recirculation (In-Unit)</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'hot_water_distribution_pipe_r',
      required: false,
      display_name: 'Hot Water Distribution: Pipe Insulation Nominal R-Value',
      units: 'h-ft^2-R/Btu',
      description: 'Nominal R-value of the pipe insulation.',
      default_href: "<a href='#{docs_base_url}#hpxml-hot-water-distribution'>HPXML Hot Water Distribution</a>"
    )

    dwhr_facilities_connected_choices = OpenStudio::StringVector.new
    dwhr_facilities_connected_choices << Constants::None
    dwhr_facilities_connected_choices << HPXML::DWHRFacilitiesConnectedOne
    dwhr_facilities_connected_choices << HPXML::DWHRFacilitiesConnectedAll

    args << makeArgument(
      type: Argument::Choice,
      name: 'dwhr_facilities_connected',
      choices: dwhr_facilities_connected_choices,
      required: false,
      display_name: 'Drain Water Heat Recovery: Facilities Connected',
      description: "Which facilities are connected for the drain water heat recovery. Use '#{Constants::None}' if there is no drain water heat recovery system."
    )

    args << makeArgument(
      name: 'dwhr_equal_flow',
      type: Argument::Boolean,
      required: false,
      display_name: 'Drain Water Heat Recovery: Equal Flow',
      description: 'Whether the drain water heat recovery has equal flow.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dwhr_efficiency',
      required: false,
      display_name: 'Drain Water Heat Recovery: Efficiency',
      units: 'Frac',
      description: 'The efficiency of the drain water heat recovery.'
    )

    args << makeArgument(
      name: 'water_fixtures_shower_low_flow',
      type: Argument::Boolean,
      required: false,
      display_name: 'Hot Water Fixtures: Is Shower Low Flow',
      description: 'Whether the shower fixture is low flow. If not provided, defaults to false.'
    )

    args << makeArgument(
      name: 'water_fixtures_sink_low_flow',
      type: Argument::Boolean,
      required: false,
      display_name: 'Hot Water Fixtures: Is Sink Low Flow',
      description: 'Whether the sink fixture is low flow. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'water_fixtures_usage_multiplier',
      required: false,
      display_name: 'Hot Water Fixtures: Usage Multiplier',
      description: 'Multiplier on the hot water usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-water-fixtures'>HPXML Water Fixtures</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'general_water_use_usage_multiplier',
      required: false,
      display_name: 'General Water Use: Usage Multiplier',
      description: 'Multiplier on internal gains from general water use (floor mopping, shower evaporation, water films on showers, tubs & sinks surfaces, plant watering, etc.) that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-building-occupancy'>HPXML Building Occupancy</a>"
    )

    solar_thermal_system_type_choices = OpenStudio::StringVector.new
    solar_thermal_system_type_choices << Constants::None
    solar_thermal_system_type_choices << HPXML::SolarThermalSystemTypeHotWater

    solar_thermal_collector_loop_type_choices = OpenStudio::StringVector.new
    solar_thermal_collector_loop_type_choices << HPXML::SolarThermalLoopTypeDirect
    solar_thermal_collector_loop_type_choices << HPXML::SolarThermalLoopTypeIndirect
    solar_thermal_collector_loop_type_choices << HPXML::SolarThermalLoopTypeThermosyphon

    solar_thermal_collector_type_choices = OpenStudio::StringVector.new
    solar_thermal_collector_type_choices << HPXML::SolarThermalCollectorTypeEvacuatedTube
    solar_thermal_collector_type_choices << HPXML::SolarThermalCollectorTypeSingleGlazing
    solar_thermal_collector_type_choices << HPXML::SolarThermalCollectorTypeDoubleGlazing
    solar_thermal_collector_type_choices << HPXML::SolarThermalCollectorTypeICS

    args << makeArgument(
      type: Argument::Choice,
      name: 'solar_thermal_system_type',
      choices: solar_thermal_system_type_choices,
      required: false,
      display_name: 'Solar Thermal: System Type',
      description: "The type of solar thermal system. Use '#{Constants::None}' if there is no solar thermal system."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'solar_thermal_collector_area',
      required: false,
      display_name: 'Solar Thermal: Collector Area',
      units: 'ft^2',
      description: 'The collector area of the solar thermal system.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'solar_thermal_collector_loop_type',
      choices: solar_thermal_collector_loop_type_choices,
      required: false,
      display_name: 'Solar Thermal: Collector Loop Type',
      description: 'The collector loop type of the solar thermal system.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'solar_thermal_collector_type',
      choices: solar_thermal_collector_type_choices,
      required: false,
      display_name: 'Solar Thermal: Collector Type',
      description: 'The collector type of the solar thermal system.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'solar_thermal_collector_azimuth',
      required: false,
      display_name: 'Solar Thermal: Collector Azimuth',
      units: 'degrees',
      description: 'The collector azimuth of the solar thermal system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'solar_thermal_collector_tilt',
      required: false,
      display_name: 'Solar Thermal: Collector Tilt',
      units: 'degrees',
      description: 'The collector tilt of the solar thermal system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'solar_thermal_collector_rated_optical_efficiency',
      required: false,
      display_name: 'Solar Thermal: Collector Rated Optical Efficiency',
      units: 'Frac',
      description: 'The collector rated optical efficiency of the solar thermal system.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'solar_thermal_collector_rated_thermal_losses',
      required: false,
      display_name: 'Solar Thermal: Collector Rated Thermal Losses',
      units: 'Btu/hr-ft^2-R',
      description: 'The collector rated thermal losses of the solar thermal system.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'solar_thermal_storage_volume',
      required: false,
      display_name: 'Solar Thermal: Storage Volume',
      units: 'gal',
      description: 'The storage volume of the solar thermal system.',
      default_href: "<a href='#{docs_base_url}#detailed-inputs'>Detailed Inputs</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'solar_thermal_solar_fraction',
      required: false,
      display_name: 'Solar Thermal: Solar Fraction',
      units: 'Frac',
      description: 'The solar fraction of the solar thermal system. If provided, overrides all other solar thermal inputs.'
    )

    pv_system_module_type_choices = OpenStudio::StringVector.new
    pv_system_module_type_choices << HPXML::PVModuleTypeStandard
    pv_system_module_type_choices << HPXML::PVModuleTypePremium
    pv_system_module_type_choices << HPXML::PVModuleTypeThinFilm

    pv_system_location_choices = OpenStudio::StringVector.new
    pv_system_location_choices << HPXML::LocationRoof
    pv_system_location_choices << HPXML::LocationGround

    pv_system_tracking_choices = OpenStudio::StringVector.new
    pv_system_tracking_choices << HPXML::PVTrackingTypeFixed
    pv_system_tracking_choices << HPXML::PVTrackingType1Axis
    pv_system_tracking_choices << HPXML::PVTrackingType1AxisBacktracked
    pv_system_tracking_choices << HPXML::PVTrackingType2Axis

    args << makeArgument(
      name: 'pv_system_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'PV System: Present',
      description: 'Whether there is a PV system present. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'pv_system_module_type',
      choices: pv_system_module_type_choices,
      required: false,
      display_name: 'PV System: Module Type',
      description: 'Module type of the PV system.',
      default_href: "<a href='#{docs_base_url}#hpxml-photovoltaics'>HPXML Photovoltaics</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'pv_system_location',
      choices: pv_system_location_choices,
      required: false,
      display_name: 'PV System: Location',
      description: 'Location of the PV system.',
      default_href: "<a href='#{docs_base_url}#hpxml-photovoltaics'>HPXML Photovoltaics</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'pv_system_tracking',
      choices: pv_system_tracking_choices,
      required: false,
      display_name: 'PV System: Tracking',
      description: 'Type of tracking for the PV system.',
      default_href: "<a href='#{docs_base_url}#hpxml-photovoltaics'>HPXML Photovoltaics</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pv_system_array_azimuth',
      required: false,
      display_name: 'PV System: Array Azimuth',
      units: 'degrees',
      description: 'Array azimuth of the PV system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'pv_system_array_tilt',
      required: false,
      display_name: 'PV System: Array Tilt',
      units: 'degrees',
      description: 'Array tilt of the PV system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pv_system_max_power_output',
      required: false,
      display_name: 'PV System: Maximum Power Output',
      units: 'W',
      description: 'Maximum power output of the PV system. For a shared system, this is the total building maximum power output.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pv_system_inverter_efficiency',
      required: false,
      display_name: 'PV System: Inverter Efficiency',
      units: 'Frac',
      description: 'Inverter efficiency of the PV system. If there are two PV systems, this will apply to both.',
      default_href: "<a href='#{docs_base_url}#hpxml-photovoltaics'>HPXML Photovoltaics</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pv_system_system_losses_fraction',
      required: false,
      display_name: 'PV System: System Losses Fraction',
      units: 'Frac',
      description: 'System losses fraction of the PV system. If there are two PV systems, this will apply to both.',
      default_href: "<a href='#{docs_base_url}#hpxml-photovoltaics'>HPXML Photovoltaics</a>"
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'pv_system_num_bedrooms_served',
      required: false,
      display_name: 'PV System: Number of Bedrooms Served',
      description: "Number of bedrooms served by PV system. Only needed if #{HPXML::ResidentialTypeSFA} or #{HPXML::ResidentialTypeApartment} and it is a shared PV system serving multiple dwelling units. Used to apportion PV generation to the unit of a SFA/MF building. If there are two PV systems, this will apply to both.",
      units: '#'
    )

    args << makeArgument(
      name: 'pv_system_2_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'PV System 2: Present',
      description: 'Whether there is a second PV system present. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'pv_system_2_module_type',
      choices: pv_system_module_type_choices,
      required: false,
      display_name: 'PV System 2: Module Type',
      description: 'Module type of the second PV system.',
      default_href: "<a href='#{docs_base_url}#hpxml-photovoltaics'>HPXML Photovoltaics</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'pv_system_2_location',
      choices: pv_system_location_choices,
      required: false,
      display_name: 'PV System 2: Location',
      description: 'Location of the second PV system.',
      default_href: "<a href='#{docs_base_url}#hpxml-photovoltaics'>HPXML Photovoltaics</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'pv_system_2_tracking',
      choices: pv_system_tracking_choices,
      required: false,
      display_name: 'PV System 2: Tracking',
      description: 'Type of tracking for the second PV system.',
      default_href: "<a href='#{docs_base_url}#hpxml-photovoltaics'>HPXML Photovoltaics</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pv_system_2_array_azimuth',
      required: false,
      display_name: 'PV System 2: Array Azimuth',
      units: 'degrees',
      description: 'Array azimuth of the second PV system. Azimuth is measured clockwise from north (e.g., North=0, East=90, South=180, West=270).'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'pv_system_2_array_tilt',
      required: false,
      display_name: 'PV System 2: Array Tilt',
      units: 'degrees',
      description: 'Array tilt of the second PV system. Can also enter, e.g., RoofPitch, RoofPitch+20, Latitude, Latitude-15, etc.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pv_system_2_max_power_output',
      required: false,
      display_name: 'PV System 2: Maximum Power Output',
      units: 'W',
      description: 'Maximum power output of the second PV system. For a shared system, this is the total building maximum power output.'
    )

    battery_location_choices = OpenStudio::StringVector.new
    battery_location_choices << HPXML::LocationConditionedSpace
    battery_location_choices << HPXML::LocationBasementConditioned
    battery_location_choices << HPXML::LocationBasementUnconditioned
    battery_location_choices << HPXML::LocationCrawlspace
    battery_location_choices << HPXML::LocationCrawlspaceVented
    battery_location_choices << HPXML::LocationCrawlspaceUnvented
    battery_location_choices << HPXML::LocationCrawlspaceConditioned
    battery_location_choices << HPXML::LocationAttic
    battery_location_choices << HPXML::LocationAtticVented
    battery_location_choices << HPXML::LocationAtticUnvented
    battery_location_choices << HPXML::LocationGarage
    battery_location_choices << HPXML::LocationOutside

    args << makeArgument(
      name: 'battery_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Battery: Present',
      description: 'Whether there is a lithium ion battery present. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'battery_location',
      choices: battery_location_choices,
      required: false,
      display_name: 'Battery: Location',
      description: 'The space type for the lithium ion battery location.',
      default_href: "<a href='#{docs_base_url}#hpxml-batteries'>HPXML Batteries</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'battery_power',
      required: false,
      display_name: 'Battery: Rated Power Output',
      description: 'The rated power output of the lithium ion battery.',
      default_href: "<a href='#{docs_base_url}#hpxml-batteries'>HPXML Batteries</a>",
      units: 'W'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'battery_capacity',
      required: false,
      display_name: 'Battery: Nominal Capacity',
      description: 'The nominal capacity of the lithium ion battery.',
      default_href: "<a href='#{docs_base_url}#hpxml-batteries'>HPXML Batteries</a>",
      units: 'kWh'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'battery_usable_capacity',
      required: false,
      display_name: 'Battery: Usable Capacity',
      description: 'The usable capacity of the lithium ion battery.',
      default_href: "<a href='#{docs_base_url}#hpxml-batteries'>HPXML Batteries</a>",
      units: 'kWh'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'battery_round_trip_efficiency',
      required: false,
      display_name: 'Battery: Round Trip Efficiency',
      description: 'The round trip efficiency of the lithium ion battery.',
      default_href: "<a href='#{docs_base_url}#hpxml-batteries'>HPXML Batteries</a>",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'battery_num_bedrooms_served',
      required: false,
      display_name: 'Battery: Number of Bedrooms Served',
      description: "Number of bedrooms served by the lithium ion battery. Only needed if #{HPXML::ResidentialTypeSFA} or #{HPXML::ResidentialTypeApartment} and it is a shared battery serving multiple dwelling units. Used to apportion battery charging/discharging to the unit of a SFA/MF building.",
      units: '#'
    )

    args << makeArgument(
      name: 'lighting_present',
      type: Argument::Boolean,
      required: true,
      display_name: 'Lighting: Present',
      description: 'Whether there is lighting energy use.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_interior_fraction_cfl',
      required: false,
      display_name: 'Lighting: Interior Fraction CFL',
      description: 'Fraction of all lamps (interior) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_interior_fraction_lfl',
      required: false,
      display_name: 'Lighting: Interior Fraction LFL',
      description: 'Fraction of all lamps (interior) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_interior_fraction_led',
      required: false,
      display_name: 'Lighting: Interior Fraction LED',
      description: 'Fraction of all lamps (interior) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_interior_usage_multiplier',
      required: false,
      display_name: 'Lighting: Interior Usage Multiplier',
      description: 'Multiplier on the lighting energy usage (interior) that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-lighting'>HPXML Lighting</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_exterior_fraction_cfl',
      required: false,
      display_name: 'Lighting: Exterior Fraction CFL',
      description: 'Fraction of all lamps (exterior) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_exterior_fraction_lfl',
      required: false,
      display_name: 'Lighting: Exterior Fraction LFL',
      description: 'Fraction of all lamps (exterior) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_exterior_fraction_led',
      required: false,
      display_name: 'Lighting: Exterior Fraction LED',
      description: 'Fraction of all lamps (exterior) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_exterior_usage_multiplier',
      required: false,
      display_name: 'Lighting: Exterior Usage Multiplier',
      description: 'Multiplier on the lighting energy usage (exterior) that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-lighting'>HPXML Lighting</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_garage_fraction_cfl',
      required: false,
      display_name: 'Lighting: Garage Fraction CFL',
      description: 'Fraction of all lamps (garage) that are compact fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_garage_fraction_lfl',
      required: false,
      display_name: 'Lighting: Garage Fraction LFL',
      description: 'Fraction of all lamps (garage) that are linear fluorescent. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_garage_fraction_led',
      required: false,
      display_name: 'Lighting: Garage Fraction LED',
      description: 'Fraction of all lamps (garage) that are light emitting diodes. Lighting not specified as CFL, LFL, or LED is assumed to be incandescent.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'lighting_garage_usage_multiplier',
      required: false,
      display_name: 'Lighting: Garage Usage Multiplier',
      description: 'Multiplier on the lighting energy usage (garage) that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-lighting'>HPXML Lighting</a>"
    )

    args << makeArgument(
      name: 'holiday_lighting_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Holiday Lighting: Present',
      description: 'Whether there is holiday lighting. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'holiday_lighting_daily_kwh',
      required: false,
      display_name: 'Holiday Lighting: Daily Consumption',
      units: 'kWh/day',
      description: 'The daily energy consumption for holiday lighting (exterior).',
      default_href: "<a href='#{docs_base_url}#hpxml-lighting'>HPXML Lighting</a>"
    )

    args << makeArgument(
      type: Argument::String,
      name: 'holiday_lighting_period',
      required: false,
      display_name: 'Holiday Lighting: Period',
      description: "Enter a date range like 'Nov 25 - Jan 5'.",
      default_href: "<a href='#{docs_base_url}#hpxml-lighting'>HPXML Lighting</a>"
    )

    dehumidifier_type_choices = OpenStudio::StringVector.new
    dehumidifier_type_choices << Constants::None
    dehumidifier_type_choices << HPXML::DehumidifierTypePortable
    dehumidifier_type_choices << HPXML::DehumidifierTypeWholeHome

    dehumidifier_efficiency_type_choices = OpenStudio::StringVector.new
    dehumidifier_efficiency_type_choices << 'EnergyFactor'
    dehumidifier_efficiency_type_choices << 'IntegratedEnergyFactor'

    args << makeArgument(
      type: Argument::Choice,
      name: 'dehumidifier_type',
      choices: dehumidifier_type_choices,
      required: false,
      display_name: 'Dehumidifier: Type',
      description: 'The type of dehumidifier. If not provided, defaults to none.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'dehumidifier_efficiency_type',
      choices: dehumidifier_efficiency_type_choices,
      required: false,
      display_name: 'Dehumidifier: Efficiency Type',
      description: 'The efficiency type of dehumidifier.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dehumidifier_efficiency',
      required: false,
      display_name: 'Dehumidifier: Efficiency',
      units: 'liters/kWh',
      description: 'The efficiency of the dehumidifier.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dehumidifier_capacity',
      required: false,
      display_name: 'Dehumidifier: Capacity',
      description: 'The capacity (water removal rate) of the dehumidifier.',
      units: 'pint/day'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dehumidifier_rh_setpoint',
      required: false,
      display_name: 'Dehumidifier: Relative Humidity Setpoint',
      description: 'The relative humidity setpoint of the dehumidifier.',
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dehumidifier_fraction_dehumidification_load_served',
      required: false,
      display_name: 'Dehumidifier: Fraction Dehumidification Load Served',
      description: 'The dehumidification load served fraction of the dehumidifier.',
      units: 'Frac'
    )

    appliance_location_choices = OpenStudio::StringVector.new
    appliance_location_choices << HPXML::LocationConditionedSpace
    appliance_location_choices << HPXML::LocationBasementConditioned
    appliance_location_choices << HPXML::LocationBasementUnconditioned
    appliance_location_choices << HPXML::LocationGarage
    appliance_location_choices << HPXML::LocationOtherHousingUnit
    appliance_location_choices << HPXML::LocationOtherHeatedSpace
    appliance_location_choices << HPXML::LocationOtherMultifamilyBufferSpace
    appliance_location_choices << HPXML::LocationOtherNonFreezingSpace

    clothes_washer_efficiency_type_choices = OpenStudio::StringVector.new
    clothes_washer_efficiency_type_choices << 'ModifiedEnergyFactor'
    clothes_washer_efficiency_type_choices << 'IntegratedModifiedEnergyFactor'

    args << makeArgument(
      name: 'clothes_washer_present',
      type: Argument::Boolean,
      required: true,
      display_name: 'Clothes Washer: Present',
      description: 'Whether there is a clothes washer present.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'clothes_washer_location',
      choices: appliance_location_choices,
      required: false,
      display_name: 'Clothes Washer: Location',
      description: 'The space type for the clothes washer location.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-washer'>HPXML Clothes Washer</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'clothes_washer_efficiency_type',
      choices: clothes_washer_efficiency_type_choices,
      required: false,
      display_name: 'Clothes Washer: Efficiency Type',
      description: 'The efficiency type of the clothes washer.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_washer_efficiency',
      required: false,
      display_name: 'Clothes Washer: Efficiency',
      units: 'ft^3/kWh-cyc',
      description: 'The efficiency of the clothes washer.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-washer'>HPXML Clothes Washer</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_washer_rated_annual_kwh',
      required: false,
      display_name: 'Clothes Washer: Rated Annual Consumption',
      units: 'kWh/yr',
      description: 'The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-washer'>HPXML Clothes Washer</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_washer_label_electric_rate',
      required: false,
      display_name: 'Clothes Washer: Label Electric Rate',
      units: '$/kWh',
      description: 'The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-washer'>HPXML Clothes Washer</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_washer_label_gas_rate',
      required: false,
      display_name: 'Clothes Washer: Label Gas Rate',
      units: '$/therm',
      description: 'The annual energy consumed by the clothes washer, as rated, obtained from the EnergyGuide label. This includes both the appliance electricity consumption and the energy required for water heating.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-washer'>HPXML Clothes Washer</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_washer_label_annual_gas_cost',
      required: false,
      display_name: 'Clothes Washer: Label Annual Cost with Gas DHW',
      units: '$',
      description: 'The annual cost of using the system under test conditions. Input is obtained from the EnergyGuide label.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-washer'>HPXML Clothes Washer</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_washer_label_usage',
      required: false,
      display_name: 'Clothes Washer: Label Usage',
      units: 'cyc/wk',
      description: 'The clothes washer loads per week.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-washer'>HPXML Clothes Washer</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_washer_capacity',
      required: false,
      display_name: 'Clothes Washer: Drum Volume',
      units: 'ft^3',
      description: "Volume of the washer drum. Obtained from the EnergyStar website or the manufacturer's literature.",
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-washer'>HPXML Clothes Washer</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_washer_usage_multiplier',
      required: false,
      display_name: 'Clothes Washer: Usage Multiplier',
      description: 'Multiplier on the clothes washer energy and hot water usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-washer'>HPXML Clothes Washer</a>"
    )

    args << makeArgument(
      name: 'clothes_dryer_present',
      type: Argument::Boolean,
      required: true,
      display_name: 'Clothes Dryer: Present',
      description: 'Whether there is a clothes dryer present.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'clothes_dryer_location',
      choices: appliance_location_choices,
      required: false,
      display_name: 'Clothes Dryer: Location',
      description: 'The space type for the clothes dryer location.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-dryer'>HPXML Clothes Dryer</a>"
    )

    clothes_dryer_fuel_choices = OpenStudio::StringVector.new
    clothes_dryer_fuel_choices << HPXML::FuelTypeElectricity
    clothes_dryer_fuel_choices << HPXML::FuelTypeNaturalGas
    clothes_dryer_fuel_choices << HPXML::FuelTypeOil
    clothes_dryer_fuel_choices << HPXML::FuelTypePropane
    clothes_dryer_fuel_choices << HPXML::FuelTypeWoodCord
    clothes_dryer_fuel_choices << HPXML::FuelTypeCoal

    clothes_dryer_efficiency_type_choices = OpenStudio::StringVector.new
    clothes_dryer_efficiency_type_choices << 'EnergyFactor'
    clothes_dryer_efficiency_type_choices << 'CombinedEnergyFactor'

    args << makeArgument(
      type: Argument::Choice,
      name: 'clothes_dryer_fuel_type',
      choices: clothes_dryer_fuel_choices,
      required: false,
      display_name: 'Clothes Dryer: Fuel Type',
      description: 'Type of fuel used by the clothes dryer.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'clothes_dryer_efficiency_type',
      choices: clothes_dryer_efficiency_type_choices,
      required: false,
      display_name: 'Clothes Dryer: Efficiency Type',
      description: 'The efficiency type of the clothes dryer.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_dryer_efficiency',
      required: false,
      display_name: 'Clothes Dryer: Efficiency',
      units: 'lb/kWh',
      description: 'The efficiency of the clothes dryer.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-dryer'>HPXML Clothes Dryer</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_dryer_vented_flow_rate',
      required: false,
      display_name: 'Clothes Dryer: Vented Flow Rate',
      description: 'The exhaust flow rate of the vented clothes dryer.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-dryer'>HPXML Clothes Dryer</a>",
      units: 'CFM'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'clothes_dryer_usage_multiplier',
      required: false,
      display_name: 'Clothes Dryer: Usage Multiplier',
      description: 'Multiplier on the clothes dryer energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-clothes-dryer'>HPXML Clothes Dryer</a>"
    )

    args << makeArgument(
      name: 'dishwasher_present',
      type: Argument::Boolean,
      required: true,
      display_name: 'Dishwasher: Present',
      description: 'Whether there is a dishwasher present.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'dishwasher_location',
      choices: appliance_location_choices,
      required: false,
      display_name: 'Dishwasher: Location',
      description: 'The space type for the dishwasher location.',
      default_href: "<a href='#{docs_base_url}#hpxml-dishwasher'>HPXML Dishwasher</a>"
    )

    dishwasher_efficiency_type_choices = OpenStudio::StringVector.new
    dishwasher_efficiency_type_choices << 'RatedAnnualkWh'
    dishwasher_efficiency_type_choices << 'EnergyFactor'

    args << makeArgument(
      type: Argument::Choice,
      name: 'dishwasher_efficiency_type',
      choices: dishwasher_efficiency_type_choices,
      required: false,
      display_name: 'Dishwasher: Efficiency Type',
      description: 'The efficiency type of dishwasher.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dishwasher_efficiency',
      required: false,
      display_name: 'Dishwasher: Efficiency',
      units: 'RatedAnnualkWh or EnergyFactor',
      description: 'The efficiency of the dishwasher.',
      default_href: "<a href='#{docs_base_url}#hpxml-dishwasher'>HPXML Dishwasher</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dishwasher_label_electric_rate',
      required: false,
      display_name: 'Dishwasher: Label Electric Rate',
      units: '$/kWh',
      description: 'The label electric rate of the dishwasher.',
      default_href: "<a href='#{docs_base_url}#hpxml-dishwasher'>HPXML Dishwasher</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dishwasher_label_gas_rate',
      required: false,
      display_name: 'Dishwasher: Label Gas Rate',
      units: '$/therm',
      description: 'The label gas rate of the dishwasher.',
      default_href: "<a href='#{docs_base_url}#hpxml-dishwasher'>HPXML Dishwasher</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dishwasher_label_annual_gas_cost',
      required: false,
      display_name: 'Dishwasher: Label Annual Gas Cost',
      units: '$',
      description: 'The label annual gas cost of the dishwasher.',
      default_href: "<a href='#{docs_base_url}#hpxml-dishwasher'>HPXML Dishwasher</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dishwasher_label_usage',
      required: false,
      display_name: 'Dishwasher: Label Usage',
      units: 'cyc/wk',
      description: 'The dishwasher loads per week.',
      default_href: "<a href='#{docs_base_url}#hpxml-dishwasher'>HPXML Dishwasher</a>"
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'dishwasher_place_setting_capacity',
      required: false,
      display_name: 'Dishwasher: Number of Place Settings',
      units: '#',
      description: "The number of place settings for the unit. Data obtained from manufacturer's literature.",
      default_href: "<a href='#{docs_base_url}#hpxml-dishwasher'>HPXML Dishwasher</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'dishwasher_usage_multiplier',
      required: false,
      display_name: 'Dishwasher: Usage Multiplier',
      description: 'Multiplier on the dishwasher energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-dishwasher'>HPXML Dishwasher</a>"
    )

    args << makeArgument(
      name: 'refrigerator_present',
      type: Argument::Boolean,
      required: true,
      display_name: 'Refrigerator: Present',
      description: 'Whether there is a refrigerator present.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'refrigerator_location',
      choices: appliance_location_choices,
      required: false,
      display_name: 'Refrigerator: Location',
      description: 'The space type for the refrigerator location.',
      default_href: "<a href='#{docs_base_url}#hpxml-refrigerators'>HPXML Refrigerators</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'refrigerator_rated_annual_kwh',
      required: false,
      display_name: 'Refrigerator: Rated Annual Consumption',
      units: 'kWh/yr',
      description: 'The EnergyGuide rated annual energy consumption for a refrigerator.',
      default_href: "<a href='#{docs_base_url}#hpxml-refrigerators'>HPXML Refrigerators</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'refrigerator_usage_multiplier',
      required: false,
      display_name: 'Refrigerator: Usage Multiplier',
      description: 'Multiplier on the refrigerator energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-refrigerators'>HPXML Refrigerators</a>"
    )

    args << makeArgument(
      name: 'extra_refrigerator_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Extra Refrigerator: Present',
      description: 'Whether there is an extra refrigerator present. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'extra_refrigerator_location',
      choices: appliance_location_choices,
      required: false,
      display_name: 'Extra Refrigerator: Location',
      description: 'The space type for the extra refrigerator location.',
      default_href: "<a href='#{docs_base_url}#hpxml-refrigerators'>HPXML Refrigerators</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'extra_refrigerator_rated_annual_kwh',
      required: false,
      display_name: 'Extra Refrigerator: Rated Annual Consumption',
      units: 'kWh/yr',
      description: 'The EnergyGuide rated annual energy consumption for an extra refrigerator.',
      default_href: "<a href='#{docs_base_url}#hpxml-refrigerators'>HPXML Refrigerators</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'extra_refrigerator_usage_multiplier',
      required: false,
      display_name: 'Extra Refrigerator: Usage Multiplier',
      description: 'Multiplier on the extra refrigerator energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-refrigerators'>HPXML Refrigerators</a>"
    )

    args << makeArgument(
      name: 'freezer_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Freezer: Present',
      description: 'Whether there is a freezer present. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'freezer_location',
      choices: appliance_location_choices,
      required: false,
      display_name: 'Freezer: Location',
      description: 'The space type for the freezer location.',
      default_href: "<a href='#{docs_base_url}#hpxml-freezers'>HPXML Freezers</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'freezer_rated_annual_kwh',
      required: false,
      display_name: 'Freezer: Rated Annual Consumption',
      units: 'kWh/yr',
      description: 'The EnergyGuide rated annual energy consumption for a freezer.',
      default_href: "<a href='#{docs_base_url}#hpxml-freezers'>HPXML Freezers</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'freezer_usage_multiplier',
      required: false,
      display_name: 'Freezer: Usage Multiplier',
      description: 'Multiplier on the freezer energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-freezers'>HPXML Freezers</a>"
    )

    cooking_range_oven_fuel_choices = OpenStudio::StringVector.new
    cooking_range_oven_fuel_choices << HPXML::FuelTypeElectricity
    cooking_range_oven_fuel_choices << HPXML::FuelTypeNaturalGas
    cooking_range_oven_fuel_choices << HPXML::FuelTypeOil
    cooking_range_oven_fuel_choices << HPXML::FuelTypePropane
    cooking_range_oven_fuel_choices << HPXML::FuelTypeWoodCord
    cooking_range_oven_fuel_choices << HPXML::FuelTypeCoal

    args << makeArgument(
      name: 'cooking_range_oven_present',
      type: Argument::Boolean,
      required: true,
      display_name: 'Cooking Range/Oven: Present',
      description: 'Whether there is a cooking range/oven present.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'cooking_range_oven_location',
      choices: appliance_location_choices,
      required: false,
      display_name: 'Cooking Range/Oven: Location',
      description: 'The space type for the cooking range/oven location.',
      default_href: "<a href='#{docs_base_url}#hpxml-cooking-range-oven'>HPXML Cooking Range/Oven</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'cooking_range_oven_fuel_type',
      choices: cooking_range_oven_fuel_choices,
      required: false,
      display_name: 'Cooking Range/Oven: Fuel Type',
      description: 'Type of fuel used by the cooking range/oven.'
    )

    args << makeArgument(
      name: 'cooking_range_oven_is_induction',
      type: Argument::Boolean,
      required: false,
      display_name: 'Cooking Range/Oven: Is Induction',
      description: 'Whether the cooking range is induction.',
      default_href: "<a href='#{docs_base_url}#hpxml-cooking-range-oven'>HPXML Cooking Range/Oven</a>"
    )

    args << makeArgument(
      name: 'cooking_range_oven_is_convection',
      type: Argument::Boolean,
      required: false,
      display_name: 'Cooking Range/Oven: Is Convection',
      description: 'Whether the oven is convection.',
      default_href: "<a href='#{docs_base_url}#hpxml-cooking-range-oven'>HPXML Cooking Range/Oven</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'cooking_range_oven_usage_multiplier',
      required: false,
      display_name: 'Cooking Range/Oven: Usage Multiplier',
      description: 'Multiplier on the cooking range/oven energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-cooking-range-oven'>HPXML Cooking Range/Oven</a>"
    )

    args << makeArgument(
      name: 'ceiling_fan_present',
      type: Argument::Boolean,
      required: true,
      display_name: 'Ceiling Fan: Present',
      description: 'Whether there are any ceiling fans.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ceiling_fan_label_energy_use',
      required: false,
      display_name: 'Ceiling Fan: Label Energy Use',
      units: 'W',
      description: 'The label average energy use of the ceiling fan(s).',
      default_href: "<a href='#{docs_base_url}#hpxml-ceiling-fans'>HPXML Ceiling Fans</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ceiling_fan_efficiency',
      required: false,
      display_name: 'Ceiling Fan: Efficiency',
      units: 'CFM/W',
      description: 'The efficiency rating of the ceiling fan(s) at medium speed. Only used if Label Energy Use not provided.',
      default_href: "<a href='#{docs_base_url}#hpxml-ceiling-fans'>HPXML Ceiling Fans</a>"
    )

    args << makeArgument(
      type: Argument::Integer,
      name: 'ceiling_fan_quantity',
      required: false,
      display_name: 'Ceiling Fan: Quantity',
      units: '#',
      description: 'Total number of ceiling fans.',
      default_href: "<a href='#{docs_base_url}#hpxml-ceiling-fans'>HPXML Ceiling Fans</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'ceiling_fan_cooling_setpoint_temp_offset',
      required: false,
      display_name: 'Ceiling Fan: Cooling Setpoint Temperature Offset',
      units: 'F',
      description: 'The cooling setpoint temperature offset during months when the ceiling fans are operating. Only applies if ceiling fan quantity is greater than zero.',
      default_href: "<a href='#{docs_base_url}#hpxml-ceiling-fans'>HPXML Ceiling Fans</a>"
    )

    args << makeArgument(
      name: 'misc_plug_loads_television_present',
      type: Argument::Boolean,
      required: true,
      display_name: 'Misc Plug Loads: Television Present',
      description: 'Whether there are televisions.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_plug_loads_television_annual_kwh',
      required: false,
      display_name: 'Misc Plug Loads: Television Annual kWh',
      description: 'The annual energy consumption of the television plug loads.',
      default_href: "<a href='#{docs_base_url}#hpxml-plug-loads'>HPXML Plug Loads</a>",
      units: 'kWh/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_plug_loads_television_usage_multiplier',
      required: false,
      display_name: 'Misc Plug Loads: Television Usage Multiplier',
      description: 'Multiplier on the television energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-plug-loads'>HPXML Plug Loads</a>"
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_plug_loads_other_annual_kwh',
      required: false,
      display_name: 'Misc Plug Loads: Other Annual kWh',
      description: 'The annual energy consumption of the other residual plug loads.',
      default_href: "<a href='#{docs_base_url}#hpxml-plug-loads'>HPXML Plug Loads</a>",
      units: 'kWh/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_plug_loads_other_frac_sensible',
      required: false,
      display_name: 'Misc Plug Loads: Other Sensible Fraction',
      description: "Fraction of other residual plug loads' internal gains that are sensible.",
      default_href: "<a href='#{docs_base_url}#hpxml-plug-loads'>HPXML Plug Loads</a>",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_plug_loads_other_frac_latent',
      required: false,
      display_name: 'Misc Plug Loads: Other Latent Fraction',
      description: "Fraction of other residual plug loads' internal gains that are latent.",
      default_href: "<a href='#{docs_base_url}#hpxml-plug-loads'>HPXML Plug Loads</a>",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_plug_loads_other_usage_multiplier',
      required: false,
      display_name: 'Misc Plug Loads: Other Usage Multiplier',
      description: 'Multiplier on the other energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-plug-loads'>HPXML Plug Loads</a>"
    )

    args << makeArgument(
      name: 'misc_plug_loads_well_pump_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Misc Plug Loads: Well Pump Present',
      description: 'Whether there is a well pump. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_plug_loads_well_pump_annual_kwh',
      required: false,
      display_name: 'Misc Plug Loads: Well Pump Annual kWh',
      description: 'The annual energy consumption of the well pump plug loads.',
      default_href: "<a href='#{docs_base_url}#hpxml-plug-loads'>HPXML Plug Loads</a>",
      units: 'kWh/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_plug_loads_well_pump_usage_multiplier',
      required: false,
      display_name: 'Misc Plug Loads: Well Pump Usage Multiplier',
      description: 'Multiplier on the well pump energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-plug-loads'>HPXML Plug Loads</a>"
    )

    args << makeArgument(
      name: 'misc_plug_loads_vehicle_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Misc Plug Loads: Vehicle Present',
      description: 'Whether there is an electric vehicle. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_plug_loads_vehicle_annual_kwh',
      required: false,
      display_name: 'Misc Plug Loads: Vehicle Annual kWh',
      description: 'The annual energy consumption of the electric vehicle plug loads.',
      default_href: "<a href='#{docs_base_url}#hpxml-plug-loads'>HPXML Plug Loads</a>",
      units: 'kWh/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_plug_loads_vehicle_usage_multiplier',
      required: false,
      display_name: 'Misc Plug Loads: Vehicle Usage Multiplier',
      description: 'Multiplier on the electric vehicle energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-plug-loads'>HPXML Plug Loads</a>"
    )

    misc_fuel_loads_fuel_choices = OpenStudio::StringVector.new
    misc_fuel_loads_fuel_choices << HPXML::FuelTypeNaturalGas
    misc_fuel_loads_fuel_choices << HPXML::FuelTypeOil
    misc_fuel_loads_fuel_choices << HPXML::FuelTypePropane
    misc_fuel_loads_fuel_choices << HPXML::FuelTypeWoodCord
    misc_fuel_loads_fuel_choices << HPXML::FuelTypeWoodPellets

    args << makeArgument(
      name: 'misc_fuel_loads_grill_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Misc Fuel Loads: Grill Present',
      description: 'Whether there is a fuel loads grill. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'misc_fuel_loads_grill_fuel_type',
      choices: misc_fuel_loads_fuel_choices,
      required: false,
      display_name: 'Misc Fuel Loads: Grill Fuel Type',
      description: 'The fuel type of the fuel loads grill.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_fuel_loads_grill_annual_therm',
      required: false,
      display_name: 'Misc Fuel Loads: Grill Annual therm',
      description: 'The annual energy consumption of the fuel loads grill.',
      default_href: "<a href='#{docs_base_url}#hpxml-fuel-loads'>HPXML Fuel Loads</a>",
      units: 'therm/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_fuel_loads_grill_usage_multiplier',
      required: false,
      display_name: 'Misc Fuel Loads: Grill Usage Multiplier',
      description: 'Multiplier on the fuel loads grill energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-fuel-loads'>HPXML Fuel Loads</a>"
    )

    args << makeArgument(
      name: 'misc_fuel_loads_lighting_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Misc Fuel Loads: Lighting Present',
      description: 'Whether there is fuel loads lighting. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'misc_fuel_loads_lighting_fuel_type',
      choices: misc_fuel_loads_fuel_choices,
      required: false,
      display_name: 'Misc Fuel Loads: Lighting Fuel Type',
      description: 'The fuel type of the fuel loads lighting.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_fuel_loads_lighting_annual_therm',
      required: false,
      display_name: 'Misc Fuel Loads: Lighting Annual therm',
      description: 'The annual energy consumption of the fuel loads lighting.',
      default_href: "<a href='#{docs_base_url}#hpxml-fuel-loads'>HPXML Fuel Loads</a>",
      units: 'therm/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_fuel_loads_lighting_usage_multiplier',
      required: false,
      display_name: 'Misc Fuel Loads: Lighting Usage Multiplier',
      description: 'Multiplier on the fuel loads lighting energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-fuel-loads'>HPXML Fuel Loads</a>"
    )

    args << makeArgument(
      name: 'misc_fuel_loads_fireplace_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Misc Fuel Loads: Fireplace Present',
      description: 'Whether there is fuel loads fireplace. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'misc_fuel_loads_fireplace_fuel_type',
      choices: misc_fuel_loads_fuel_choices,
      required: false,
      display_name: 'Misc Fuel Loads: Fireplace Fuel Type',
      description: 'The fuel type of the fuel loads fireplace.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_fuel_loads_fireplace_annual_therm',
      required: false,
      display_name: 'Misc Fuel Loads: Fireplace Annual therm',
      description: 'The annual energy consumption of the fuel loads fireplace.',
      default_href: "<a href='#{docs_base_url}#hpxml-fuel-loads'>HPXML Fuel Loads</a>",
      units: 'therm/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_fuel_loads_fireplace_frac_sensible',
      required: false,
      display_name: 'Misc Fuel Loads: Fireplace Sensible Fraction',
      description: "Fraction of fireplace residual fuel loads' internal gains that are sensible.",
      default_href: "<a href='#{docs_base_url}#hpxml-fuel-loads'>HPXML Fuel Loads</a>",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_fuel_loads_fireplace_frac_latent',
      required: false,
      display_name: 'Misc Fuel Loads: Fireplace Latent Fraction',
      description: "Fraction of fireplace residual fuel loads' internal gains that are latent.",
      default_href: "<a href='#{docs_base_url}#hpxml-fuel-loads'>HPXML Fuel Loads</a>",
      units: 'Frac'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'misc_fuel_loads_fireplace_usage_multiplier',
      required: false,
      display_name: 'Misc Fuel Loads: Fireplace Usage Multiplier',
      description: 'Multiplier on the fuel loads fireplace energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#hpxml-fuel-loads'>HPXML Fuel Loads</a>"
    )

    heater_type_choices = OpenStudio::StringVector.new
    heater_type_choices << HPXML::TypeNone
    heater_type_choices << HPXML::HeaterTypeElectricResistance
    heater_type_choices << HPXML::HeaterTypeGas
    heater_type_choices << HPXML::HeaterTypeHeatPump

    args << makeArgument(
      name: 'pool_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Pool: Present',
      description: 'Whether there is a pool. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pool_pump_annual_kwh',
      required: false,
      display_name: 'Pool: Pump Annual kWh',
      description: 'The annual energy consumption of the pool pump.',
      default_href: "<a href='#{docs_base_url}#pool-pump'>Pool Pump</a>",
      units: 'kWh/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pool_pump_usage_multiplier',
      required: false,
      display_name: 'Pool: Pump Usage Multiplier',
      description: 'Multiplier on the pool pump energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#pool-pump'>Pool Pump</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'pool_heater_type',
      choices: heater_type_choices,
      required: false,
      display_name: 'Pool: Heater Type',
      description: "The type of pool heater. Use '#{HPXML::TypeNone}' if there is no pool heater."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pool_heater_annual_kwh',
      required: false,
      display_name: 'Pool: Heater Annual kWh',
      description: "The annual energy consumption of the #{HPXML::HeaterTypeElectricResistance} pool heater.",
      default_href: "<a href='#{docs_base_url}#pool-heater'>Pool Heater</a>",
      units: 'kWh/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pool_heater_annual_therm',
      required: false,
      display_name: 'Pool: Heater Annual therm',
      description: "The annual energy consumption of the #{HPXML::HeaterTypeGas} pool heater.",
      default_href: "<a href='#{docs_base_url}#pool-heater'>Pool Heater</a>",
      units: 'therm/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'pool_heater_usage_multiplier',
      required: false,
      display_name: 'Pool: Heater Usage Multiplier',
      description: 'Multiplier on the pool heater energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#pool-heater'>Pool Heater</a>"
    )

    args << makeArgument(
      name: 'permanent_spa_present',
      type: Argument::Boolean,
      required: false,
      display_name: 'Permanent Spa: Present',
      description: 'Whether there is a permanent spa. If not provided, defaults to false.'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'permanent_spa_pump_annual_kwh',
      required: false,
      display_name: 'Permanent Spa: Pump Annual kWh',
      description: 'The annual energy consumption of the permanent spa pump.',
      default_href: "<a href='#{docs_base_url}#permanent-spa-pump'>Permanent Spa Pump</a>",
      units: 'kWh/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'permanent_spa_pump_usage_multiplier',
      required: false,
      display_name: 'Permanent Spa: Pump Usage Multiplier',
      description: 'Multiplier on the permanent spa pump energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#permanent-spa-pump'>Permanent Spa Pump</a>"
    )

    args << makeArgument(
      type: Argument::Choice,
      name: 'permanent_spa_heater_type',
      choices: heater_type_choices,
      required: false,
      display_name: 'Permanent Spa: Heater Type',
      description: "The type of permanent spa heater. Use '#{HPXML::TypeNone}' if there is no permanent spa heater."
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'permanent_spa_heater_annual_kwh',
      required: false,
      display_name: 'Permanent Spa: Heater Annual kWh',
      description: "The annual energy consumption of the #{HPXML::HeaterTypeElectricResistance} permanent spa heater.",
      default_href: "<a href='#{docs_base_url}#permanent-spa-heater'>Permanent Spa Heater</a>",
      units: 'kWh/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'permanent_spa_heater_annual_therm',
      required: false,
      display_name: 'Permanent Spa: Heater Annual therm',
      description: "The annual energy consumption of the #{HPXML::HeaterTypeGas} permanent spa heater.",
      default_href: "<a href='#{docs_base_url}#permanent-spa-heater'>Permanent Spa Heater</a>",
      units: 'therm/yr'
    )

    args << makeArgument(
      type: Argument::Double,
      name: 'permanent_spa_heater_usage_multiplier',
      required: false,
      display_name: 'Permanent Spa: Heater Usage Multiplier',
      description: 'Multiplier on the permanent spa heater energy usage that can reflect, e.g., high/low usage occupants.',
      default_href: "<a href='#{docs_base_url}#permanent-spa-heater'>Permanent Spa Heater</a>"
    )

    args << makeArgument(
      type: Argument::String,
      name: 'emissions_scenario_names',
      required: false,
      display_name: 'Emissions: Scenario Names',
      description: 'Names of emissions scenarios. If multiple scenarios, use a comma-separated list. If not provided, no emissions scenarios are calculated.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'emissions_types',
      required: false,
      display_name: 'Emissions: Types',
      description: 'Types of emissions (e.g., CO2e, NOx, etc.). If multiple scenarios, use a comma-separated list.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'emissions_electricity_units',
      required: false,
      display_name: 'Emissions: Electricity Units',
      description: 'Electricity emissions factors units. If multiple scenarios, use a comma-separated list. Only lb/MWh and kg/MWh are allowed.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'emissions_electricity_values_or_filepaths',
      required: false,
      display_name: 'Emissions: Electricity Values or File Paths',
      description: 'Electricity emissions factors values, specified as either an annual factor or an absolute/relative path to a file with hourly factors. If multiple scenarios, use a comma-separated list.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'emissions_electricity_number_of_header_rows',
      required: false,
      display_name: 'Emissions: Electricity Files Number of Header Rows',
      description: 'The number of header rows in the electricity emissions factor file. Only applies when an electricity filepath is used. If multiple scenarios, use a comma-separated list.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'emissions_electricity_column_numbers',
      required: false,
      display_name: 'Emissions: Electricity Files Column Numbers',
      description: 'The column number in the electricity emissions factor file. Only applies when an electricity filepath is used. If multiple scenarios, use a comma-separated list.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'emissions_fossil_fuel_units',
      required: false,
      display_name: 'Emissions: Fossil Fuel Units',
      description: 'Fossil fuel emissions factors units. If multiple scenarios, use a comma-separated list. Only lb/MBtu and kg/MBtu are allowed.'
    )

    HPXML::fossil_fuels.each do |fossil_fuel|
      underscore_case = OpenStudio::toUnderscoreCase(fossil_fuel)
      all_caps_case = fossil_fuel.split(' ').map(&:capitalize).join(' ')
      cap_case = fossil_fuel.capitalize

      args << makeArgument(
        type: Argument::String,
        name: "emissions_#{underscore_case}_values",
        required: false,
        display_name: "Emissions: #{all_caps_case} Values",
        description: "#{cap_case} emissions factors values, specified as an annual factor. If multiple scenarios, use a comma-separated list."
      )
    end

    args << makeArgument(
      type: Argument::String,
      name: 'utility_bill_scenario_names',
      required: false,
      display_name: 'Utility Bills: Scenario Names',
      description: 'Names of utility bill scenarios. If multiple scenarios, use a comma-separated list. If not provided, no utility bills scenarios are calculated.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'utility_bill_electricity_filepaths',
      required: false,
      display_name: 'Utility Bills: Electricity File Paths',
      description: 'Electricity tariff file specified as an absolute/relative path to a file with utility rate structure information. Tariff file must be formatted to OpenEI API version 7. If multiple scenarios, use a comma-separated list.'
    )


    HPXML::all_fuels.each do |fuel|
      underscore_case = OpenStudio::toUnderscoreCase(fuel)
      all_caps_case = fuel.split(' ').map(&:capitalize).join(' ')
      cap_case = fuel.capitalize

      args << makeArgument(
        type: Argument::String,
        name: "utility_bill_#{underscore_case}_fixed_charges",
        required: false,
        display_name: "Utility Bills: #{all_caps_case} Fixed Charges",
        description: "#{cap_case} utility bill monthly fixed charges. If multiple scenarios, use a comma-separated list."
      )
    end

    HPXML::all_fuels.each do |fuel|
      underscore_case = OpenStudio::toUnderscoreCase(fuel)
      all_caps_case = fuel.split(' ').map(&:capitalize).join(' ')
      cap_case = fuel.capitalize

      args << makeArgument(
        type: Argument::String,
        name: "utility_bill_#{underscore_case}_marginal_rates",
        required: false,
        display_name: "Utility Bills: #{all_caps_case} Marginal Rates",
        description: "#{cap_case} utility bill marginal rates. If multiple scenarios, use a comma-separated list."
      )
    end

    args << makeArgument(
      type: Argument::String,
      name: 'utility_bill_pv_compensation_types',
      required: false,
      display_name: 'Utility Bills: PV Compensation Types',
      description: 'Utility bill PV compensation types. If multiple scenarios, use a comma-separated list.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'utility_bill_pv_net_metering_annual_excess_sellback_rate_types',
      required: false,
      display_name: 'Utility Bills: PV Net Metering Annual Excess Sellback Rate Types',
      description: "Utility bill PV net metering annual excess sellback rate types. Only applies if the PV compensation type is '#{HPXML::PVCompensationTypeNetMetering}'. If multiple scenarios, use a comma-separated list."
    )

    args << makeArgument(
      type: Argument::String,
      name: 'utility_bill_pv_net_metering_annual_excess_sellback_rates',
      required: false,
      display_name: 'Utility Bills: PV Net Metering Annual Excess Sellback Rates',
      description: "Utility bill PV net metering annual excess sellback rates. Only applies if the PV compensation type is '#{HPXML::PVCompensationTypeNetMetering}' and the PV annual excess sellback rate type is '#{HPXML::PVAnnualExcessSellbackRateTypeUserSpecified}'. If multiple scenarios, use a comma-separated list."
    )

    args << makeArgument(
      type: Argument::String,
      name: 'utility_bill_pv_feed_in_tariff_rates',
      required: false,
      display_name: 'Utility Bills: PV Feed-In Tariff Rates',
      description: "Utility bill PV annual full/gross feed-in tariff rates. Only applies if the PV compensation type is '#{HPXML::PVCompensationTypeFeedInTariff}'. If multiple scenarios, use a comma-separated list."
    )

    args << makeArgument(
      type: Argument::String,
      name: 'utility_bill_pv_monthly_grid_connection_fee_units',
      required: false,
      display_name: 'Utility Bills: PV Monthly Grid Connection Fee Units',
      description: 'Utility bill PV monthly grid connection fee units. If multiple scenarios, use a comma-separated list.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'utility_bill_pv_monthly_grid_connection_fees',
      required: false,
      display_name: 'Utility Bills: PV Monthly Grid Connection Fees',
      description: 'Utility bill PV monthly grid connection fees. If multiple scenarios, use a comma-separated list.'
    )

    args << makeArgument(
      type: Argument::String,
      name: 'additional_properties',
      required: false,
      display_name: 'Additional Properties',
      description: "Additional properties specified as key-value pairs (i.e., key=value). If multiple additional properties, use a |-separated list. For example, 'LowIncome=false|Remodeled|Description=2-story home in Denver'. These properties will be stored in the HPXML file under /HPXML/SoftwareInfo/extension/AdditionalProperties."
    )

    args << makeArgument(
      name: 'combine_like_surfaces',
      type: Argument::Boolean,
      required: false,
      display_name: 'Combine like surfaces?',
      description: 'If true, combines like surfaces to simplify the HPXML file generated.'
    )

    args << makeArgument(
      name: 'apply_defaults',
      type: Argument::Boolean,
      required: false,
      display_name: 'Apply Default Values?',
      description: 'If true, applies OS-HPXML default values to the HPXML output file. Setting to true will also force validation of the HPXML output file before applying OS-HPXML default values.'
    )

    args << makeArgument(
      name: 'apply_validation',
      type: Argument::Boolean,
      required: false,
      display_name: 'Apply Validation?',
      description: 'If true, validates the HPXML output file. Set to false for faster performance. Note that validation is not needed if the HPXML file will be validated downstream (e.g., via the HPXMLtoOpenStudio measure).'
    )

    return args
  end

  # TODO
  def defaultOptionalArgumentValues(args)
    # these were previously required arguments with default values set (i.e., arg.setDefaultValue(xxx))
    args[:floor_over_foundation_assembly_r] = 28.1 if args[:floor_over_foundation_assembly_r].nil?
    args[:floor_over_garage_assembly_r] = 28.1 if args[:floor_over_garage_assembly_r].nil?
    args[:ceiling_assembly_r] = 31.6 if args[:ceiling_assembly_r].nil?
    args[:geometry_foundation_height] = 0.0 if args[:geometry_foundation_height].nil?
    args[:geometry_foundation_height_above_grade] = 0.0 if args[:geometry_foundation_height_above_grade].nil?
    args[:geometry_roof_pitch] = '6:12' if args[:geometry_roof_pitch].nil?
    args[:geometry_garage_width] = 0.0 if args[:geometry_garage_width].nil?
    args[:geometry_garage_depth] = 20.0 if args[:geometry_garage_depth].nil?
    args[:geometry_garage_protrusion] = 0.0 if args[:geometry_garage_protrusion].nil?
    args[:geometry_garage_position] = Constants::PositionRight if args[:geometry_garage_position].nil?
    args[:slab_perimeter_insulation_r] = 0 if args[:slab_perimeter_insulation_r].nil?
    args[:slab_perimeter_insulation_depth] = 0 if args[:slab_perimeter_insulation_depth].nil?
    args[:slab_under_insulation_r] = 0 if args[:slab_under_insulation_r].nil?
    args[:slab_under_insulation_width] = 0 if args[:slab_under_insulation_width].nil?
    args[:neighbor_front_distance] = 0.0 if args[:neighbor_front_distance].nil?
    args[:neighbor_back_distance] = 0.0 if args[:neighbor_back_distance].nil?
    args[:neighbor_left_distance] = 10.0 if args[:neighbor_left_distance].nil?
    args[:neighbor_right_distance] = 10.0 if args[:neighbor_right_distance].nil?
    args[:overhangs_front_depth] = 0 if args[:overhangs_front_depth].nil?
    args[:overhangs_front_distance_to_top_of_window] = 0 if args[:overhangs_front_distance_to_top_of_window].nil?
    args[:overhangs_front_distance_to_bottom_of_window] = 4 if args[:overhangs_front_distance_to_bottom_of_window].nil?
    args[:overhangs_back_depth] = 0 if args[:overhangs_back_depth].nil?
    args[:overhangs_back_distance_to_top_of_window] = 0 if args[:overhangs_back_distance_to_top_of_window].nil?
    args[:overhangs_back_distance_to_bottom_of_window] = 4 if args[:overhangs_back_distance_to_bottom_of_window].nil?
    args[:overhangs_left_depth] = 0 if args[:overhangs_left_depth].nil?
    args[:overhangs_left_distance_to_top_of_window] = 0 if args[:overhangs_left_distance_to_top_of_window].nil?
    args[:overhangs_left_distance_to_bottom_of_window] = 4 if args[:overhangs_left_distance_to_bottom_of_window].nil?
    args[:overhangs_right_depth] = 0 if args[:overhangs_right_depth].nil?
    args[:overhangs_right_distance_to_top_of_window] = 0 if args[:overhangs_right_distance_to_top_of_window].nil?
    args[:overhangs_right_distance_to_bottom_of_window] = 4 if args[:overhangs_right_distance_to_bottom_of_window].nil?
    args[:skylight_ufactor] = 0.33 if args[:skylight_ufactor].nil?
    args[:skylight_shgc] = 0.45 if args[:skylight_shgc].nil?
    args[:heating_system_fuel] = HPXML::FuelTypeNaturalGas if args[:heating_system_fuel].nil?
    args[:heating_system_heating_efficiency] = 0.78 if args[:heating_system_heating_efficiency].nil?
    args[:heating_system_fraction_heat_load_served] = 1 if args[:heating_system_fraction_heat_load_served].nil?
    args[:cooling_system_cooling_efficiency_type] = HPXML::UnitsSEER if args[:cooling_system_cooling_efficiency_type].nil?
    args[:cooling_system_cooling_efficiency] = 13.0 if args[:cooling_system_cooling_efficiency].nil?
    args[:cooling_system_fraction_cool_load_served] = 1 if args[:cooling_system_fraction_cool_load_served].nil?
    args[:heat_pump_heating_efficiency_type] = HPXML::UnitsHSPF if args[:heat_pump_heating_efficiency_type].nil?
    args[:heat_pump_heating_efficiency] = 7.7 if args[:heat_pump_heating_efficiency].nil?
    args[:heat_pump_cooling_efficiency_type] = HPXML::UnitsSEER if args[:heat_pump_cooling_efficiency_type].nil?
    args[:heat_pump_cooling_efficiency] = 13.0 if args[:heat_pump_cooling_efficiency].nil?
    args[:heat_pump_fraction_heat_load_served] = 1 if args[:heat_pump_fraction_heat_load_served].nil?
    args[:heat_pump_fraction_cool_load_served] = 1 if args[:heat_pump_fraction_cool_load_served].nil?
    args[:heat_pump_backup_type] = HPXML::HeatPumpBackupTypeIntegrated if args[:heat_pump_backup_type].nil?
    args[:heat_pump_backup_fuel] = HPXML::FuelTypeElectricity if args[:heat_pump_backup_fuel].nil?
    args[:heat_pump_backup_heating_efficiency] = 1 if args[:heat_pump_backup_heating_efficiency].nil?
    args[:heating_system_2_type] = Constants::None if args[:heating_system_2_type].nil?
    args[:heating_system_2_fuel] = HPXML::FuelTypeElectricity if args[:heating_system_2_fuel].nil?
    args[:heating_system_2_heating_efficiency] = 1.0 if args[:heating_system_2_heating_efficiency].nil?
    args[:heating_system_2_fraction_heat_load_served] = 0.25 if args[:heating_system_2_fraction_heat_load_served].nil?
    args[:mech_vent_fan_type] = Constants::None if args[:mech_vent_fan_type].nil?
    args[:mech_vent_recovery_efficiency_type] = 'Unadjusted' if args[:mech_vent_recovery_efficiency_type].nil?
    args[:mech_vent_total_recovery_efficiency] = 0.48 if args[:mech_vent_total_recovery_efficiency].nil?
    args[:mech_vent_sensible_recovery_efficiency] = 0.72 if args[:mech_vent_sensible_recovery_efficiency].nil?
    args[:mech_vent_2_fan_type] = Constants::None if args[:mech_vent_2_fan_type].nil?
    args[:dehumidifier_type] = Constants::None if args[:dehumidifier_type].nil?
    args[:water_heater_type] = HPXML::WaterHeaterTypeStorage if args[:water_heater_type].nil?
    args[:water_heater_jacket_rvalue] = Constants::None if args[:water_heater_jacket_rvalue].nil?
    args[:water_fixtures_shower_low_flow] = false if args[:water_fixtures_shower_low_flow].nil?
    args[:water_fixtures_sink_low_flow] = false if args[:water_fixtures_sink_low_flow].nil?
    args[:solar_thermal_system_type] = Constants::None if args[:solar_thermal_system_type].nil?
    args[:solar_thermal_collector_area] = 40.0 if args[:solar_thermal_collector_area].nil?
    args[:solar_thermal_collector_loop_type] = HPXML::SolarThermalLoopTypeDirect if args[:solar_thermal_collector_loop_type].nil?
    args[:solar_thermal_collector_type] = HPXML::SolarThermalCollectorTypeEvacuatedTube if args[:solar_thermal_collector_type].nil?
    args[:solar_thermal_collector_azimuth] = 180 if args[:solar_thermal_collector_azimuth].nil?
    args[:solar_thermal_collector_tilt] = 'RoofPitch' if args[:solar_thermal_collector_tilt].nil?
    args[:solar_thermal_collector_rated_optical_efficiency] = 0.5 if args[:solar_thermal_collector_rated_optical_efficiency].nil?
    args[:solar_thermal_collector_rated_thermal_losses] = 0.2799 if args[:solar_thermal_collector_rated_thermal_losses].nil?
    args[:solar_thermal_solar_fraction] = 0 if args[:solar_thermal_solar_fraction].nil?
    args[:misc_fuel_loads_grill_fuel_type] = HPXML::FuelTypeNaturalGas if args[:misc_fuel_loads_grill_fuel_type].nil?
    args[:misc_fuel_loads_lighting_fuel_type] = HPXML::FuelTypeNaturalGas if args[:misc_fuel_loads_lighting_fuel_type].nil?
    args[:misc_fuel_loads_fireplace_fuel_type] = HPXML::FuelTypeNaturalGas if args[:misc_fuel_loads_fireplace_fuel_type].nil?
    args[:lighting_interior_fraction_cfl] = 0.1 if args[:lighting_interior_fraction_cfl].nil?
    args[:lighting_interior_fraction_lfl] = 0.0 if args[:lighting_interior_fraction_lfl].nil?
    args[:lighting_interior_fraction_led] = 0.0 if args[:lighting_interior_fraction_led].nil?
    args[:lighting_exterior_fraction_cfl] = 0.0 if args[:lighting_exterior_fraction_cfl].nil?
    args[:lighting_exterior_fraction_lfl] = 0.0 if args[:lighting_exterior_fraction_lfl].nil?
    args[:lighting_exterior_fraction_led] = 0.0 if args[:lighting_exterior_fraction_led].nil?
    args[:lighting_garage_fraction_cfl] = 0.0 if args[:lighting_garage_fraction_cfl].nil?
    args[:lighting_garage_fraction_lfl] = 0.0 if args[:lighting_garage_fraction_lfl].nil?
    args[:lighting_garage_fraction_led] = 0.0 if args[:lighting_garage_fraction_led].nil?
    return args
  end

  # Define what happens when the measure is run.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param user_arguments [OpenStudio::Measure::OSArgumentMap] OpenStudio measure arguments
  # @return [Boolean] true if successful
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    Model.reset(model, runner)

    Version.check_openstudio_version()

    args = runner.getArgumentValues(arguments(model), user_arguments)
    args = convertArgumentValues(arguments(model), args)
    args = defaultOptionalArgumentValues(args)

    # Argument error checks
    warnings, errors = validate_arguments(args)
    unless warnings.empty?
      warnings.each do |warning|
        runner.registerWarning(warning)
      end
    end
    unless errors.empty?
      errors.each do |error|
        runner.registerError(error)
      end
      return false
    end

    if args[:weather_station_epw_filepath].nil? && args[:site_zip_code].nil?
      runner.registerError('Either EPW filepath or site zip code is required.')
      return false
    end

    epw_path = args[:weather_station_epw_filepath]
    if epw_path.nil?
      # Get EPW path from zip code
      epw_path = Defaults.lookup_weather_data_from_zipcode("#{args[:site_zip_code]}")[:station_filename]
    end

    # Create EpwFile object
    if not File.exist? epw_path
      epw_path = File.join(File.expand_path(File.join(File.dirname(__FILE__), '..', 'weather')), epw_path) # a filename was entered for weather_station_epw_filepath
    end
    if not File.exist? epw_path
      runner.registerError("Could not find EPW file at '#{epw_path}'.")
      return false
    end

    # Create HPXML file
    hpxml_path = args[:hpxml_path]
    unless (Pathname.new hpxml_path).absolute?
      hpxml_path = File.expand_path(hpxml_path)
    end

    # Existing HPXML File
    if not args[:existing_hpxml_path].nil?
      existing_hpxml_path = args[:existing_hpxml_path]
      unless (Pathname.new existing_hpxml_path).absolute?
        existing_hpxml_path = File.expand_path(existing_hpxml_path)
      end
    end

    hpxml_doc = HPXMLFile.create(runner, model, args, epw_path, hpxml_path, existing_hpxml_path)
    if not hpxml_doc
      runner.registerError('Unsuccessful creation of HPXML file.')
      return false
    end

    runner.registerInfo("Wrote file: #{hpxml_path}")

    # Uncomment for debugging purposes
    # File.write(hpxml_path.gsub('.xml', '.osm'), model.to_s)

    return true
  end

  # Issue warnings or errors for certain combinations of argument values.
  #
  # @param args [Hash] Map of :argument_name => value
  # @return [Array<String>, Array<String>] arrays of warnings and errors
  def validate_arguments(args)
    warnings = argument_warnings(args)
    errors = argument_errors(args)

    return warnings, errors
  end

  # Collection of warning checks on combinations of user argument values.
  # Warnings are registered to the runner, but do not exit the measure.
  #
  # @param args [Hash] Map of :argument_name => value
  # @return [Array<String>] array of warnings
  def argument_warnings(args)
    warnings = []

    max_uninsulated_floor_rvalue = 6.0
    max_uninsulated_ceiling_rvalue = 3.0
    max_uninsulated_roof_rvalue = 3.0

    warning = ([HPXML::WaterHeaterTypeHeatPump].include?(args[:water_heater_type]) && (args[:water_heater_fuel_type] != HPXML::FuelTypeElectricity))
    warnings << 'Cannot model a heat pump water heater with non-electric fuel type.' if warning

    warning = [HPXML::FoundationTypeSlab, HPXML::FoundationTypeAboveApartment].include?(args[:geometry_foundation_type]) && (args[:geometry_foundation_height] > 0)
    warnings << "Foundation type of '#{args[:geometry_foundation_type]}' cannot have a non-zero height. Assuming height is zero." if warning

    warning = (args[:geometry_foundation_type] == HPXML::FoundationTypeSlab) && (args[:geometry_foundation_height_above_grade] > 0)
    warnings << 'Specified a slab foundation type with a non-zero height above grade.' if warning

    warning = [HPXML::FoundationTypeCrawlspaceVented, HPXML::FoundationTypeCrawlspaceUnvented, HPXML::FoundationTypeBasementUnconditioned].include?(args[:geometry_foundation_type]) && ((args[:foundation_wall_insulation_r] > 0) || !args[:foundation_wall_assembly_r].nil?) && (args[:floor_over_foundation_assembly_r] > max_uninsulated_floor_rvalue)
    warnings << 'Home with unconditioned basement/crawlspace foundation type has both foundation wall insulation and floor insulation.' if warning

    warning = [HPXML::AtticTypeVented, HPXML::AtticTypeUnvented].include?(args[:geometry_attic_type]) && (args[:ceiling_assembly_r] > max_uninsulated_ceiling_rvalue) && (args[:roof_assembly_r] > max_uninsulated_roof_rvalue)
    warnings << 'Home with unconditioned attic type has both ceiling insulation and roof insulation.' if warning

    warning = (args[:geometry_foundation_type] == HPXML::FoundationTypeBasementConditioned) && (args[:floor_over_foundation_assembly_r] > max_uninsulated_floor_rvalue)
    warnings << 'Home with conditioned basement has floor insulation.' if warning

    warning = (args[:geometry_attic_type] == HPXML::AtticTypeConditioned) && (args[:ceiling_assembly_r] > max_uninsulated_ceiling_rvalue)
    warnings << 'Home with conditioned attic has ceiling insulation.' if warning

    warning = (args[:heat_pump_type] != HPXML::HVACTypeHeatPumpGroundToAir) && (!args[:geothermal_loop_configuration].nil? && args[:geothermal_loop_configuration] != Constants::None)
    warnings << 'Specified an attached geothermal loop but home has no ground source heat pump.' if warning

    return warnings
  end

  # Collection of error checks on combinations of user argument values.
  # Errors are registered to the runner, and exit the measure.
  #
  # @param args [Hash] Map of :argument_name => value
  # @return [Array<String>] array of errors
  def argument_errors(args)
    errors = []

    error = (args[:heating_system_type] != Constants::None) && (args[:heat_pump_type] != Constants::None) && (args[:heating_system_fraction_heat_load_served] > 0) && (args[:heat_pump_fraction_heat_load_served] > 0)
    errors << 'Multiple central heating systems are not currently supported.' if error

    error = (args[:cooling_system_type] != Constants::None) && (args[:heat_pump_type] != Constants::None) && (args[:cooling_system_fraction_cool_load_served] > 0) && (args[:heat_pump_fraction_cool_load_served] > 0)
    errors << 'Multiple central cooling systems are not currently supported.' if error

    error = ![HPXML::FoundationTypeSlab, HPXML::FoundationTypeAboveApartment].include?(args[:geometry_foundation_type]) && (args[:geometry_foundation_height] == 0)
    errors << "Foundation type of '#{args[:geometry_foundation_type]}' cannot have a height of zero." if error

    error = (args[:geometry_unit_type] == HPXML::ResidentialTypeApartment) && ([HPXML::FoundationTypeBasementConditioned, HPXML::FoundationTypeCrawlspaceConditioned].include? args[:geometry_foundation_type])
    errors << 'Conditioned basement/crawlspace foundation type for apartment units is not currently supported.' if error

    error = (args[:heating_system_type] == Constants::None) && (args[:heat_pump_type] == Constants::None) && (args[:heating_system_2_type] != Constants::None)
    errors << 'A second heating system was specified without a primary heating system.' if error

    if ((args[:heat_pump_backup_type] == HPXML::HeatPumpBackupTypeSeparate) && (args[:heating_system_2_type] == HPXML::HVACTypeFurnace)) # separate ducted backup
      if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpGroundToAir].include?(args[:heat_pump_type]) ||
         ((args[:heat_pump_type] == HPXML::HVACTypeHeatPumpMiniSplit) && args[:heat_pump_is_ducted]) # ducted heat pump
        errors << "A ducted heat pump with '#{HPXML::HeatPumpBackupTypeSeparate}' ducted backup is not supported."
      end
    end

    error = [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include?(args[:geometry_unit_type]) && args[:geometry_building_num_units].nil?
    errors << 'Did not specify the number of units in the building for single-family attached or apartment units.' if error

    error = (args[:geometry_unit_type] == HPXML::ResidentialTypeApartment) && (args[:geometry_unit_num_floors_above_grade] > 1)
    errors << 'Apartment units can only have one above-grade floor.' if error

    error = (args[:geometry_unit_type] == HPXML::ResidentialTypeSFD) && (args[:geometry_unit_left_wall_is_adiabatic] || args[:geometry_unit_right_wall_is_adiabatic] || args[:geometry_unit_front_wall_is_adiabatic] || args[:geometry_unit_back_wall_is_adiabatic] || (args[:geometry_attic_type] == HPXML::AtticTypeBelowApartment) || (args[:geometry_foundation_type] == HPXML::FoundationTypeAboveApartment))
    errors << 'No adiabatic surfaces can be applied to single-family detached homes.' if error

    error = (args[:geometry_unit_type] == HPXML::ResidentialTypeApartment) && (args[:geometry_attic_type] == HPXML::AtticTypeConditioned)
    errors << 'Conditioned attic type for apartment units is not currently supported.' if error

    error = (args[:geometry_unit_num_floors_above_grade] == 1 && args[:geometry_attic_type] == HPXML::AtticTypeConditioned)
    errors << 'Units with a conditioned attic must have at least two above-grade floors.' if error

    error = ((args[:water_heater_type] == HPXML::WaterHeaterTypeCombiStorage) || (args[:water_heater_type] == HPXML::WaterHeaterTypeCombiTankless)) && (args[:heating_system_type] != HPXML::HVACTypeBoiler)
    errors << 'Must specify a boiler when modeling an indirect water heater type.' if error

    error = [HPXML::ResidentialTypeSFD].include?(args[:geometry_unit_type]) && args[:heating_system_type].include?('Shared')
    errors << 'Specified a shared system for a single-family detached unit.' if error

    error = !args[:geometry_rim_joist_height].nil? && args[:rim_joist_assembly_r].nil?
    errors << 'Specified a rim joist height but no rim joist assembly R-value.' if error

    error = !args[:rim_joist_assembly_r].nil? && args[:geometry_rim_joist_height].nil?
    errors << 'Specified a rim joist assembly R-value but no rim joist height.' if error

    schedules_unavailable_period_args_initialized = [!args[:schedules_unavailable_period_types].nil?,
                                                     !args[:schedules_unavailable_period_dates].nil?]
    error = (schedules_unavailable_period_args_initialized.uniq.size != 1)
    errors << 'Did not specify all required unavailable period arguments.' if error

    if schedules_unavailable_period_args_initialized.uniq.size == 1 && schedules_unavailable_period_args_initialized.uniq[0]
      schedules_unavailable_period_lengths = [args[:schedules_unavailable_period_types].count(','),
                                              args[:schedules_unavailable_period_dates].count(',')]

      if !args[:schedules_unavailable_period_window_natvent_availabilities].nil?
        schedules_unavailable_period_lengths += [args[:schedules_unavailable_period_window_natvent_availabilities].count(',')]
      end

      error = (schedules_unavailable_period_lengths.uniq.size != 1)
      errors << 'One or more unavailable period arguments does not have enough comma-separated elements specified.' if error
    end

    if !args[:schedules_unavailable_period_window_natvent_availabilities].nil?
      natvent_availabilities = args[:schedules_unavailable_period_window_natvent_availabilities].split(',').map(&:strip)
      natvent_availabilities.each do |natvent_availability|
        next if natvent_availability.empty?

        error = ![HPXML::ScheduleRegular, HPXML::ScheduleAvailable, HPXML::ScheduleUnavailable].include?(natvent_availability)
        errors << "Window natural ventilation availability '#{natvent_availability}' during an unavailable period is invalid." if error
      end
    end

    hvac_perf_data_heating_args_initialized = [!args[:hvac_perf_data_heating_outdoor_temperatures].nil?,
                                               !args[:hvac_perf_data_heating_min_speed_capacities].nil?,
                                               !args[:hvac_perf_data_heating_max_speed_capacities].nil?,
                                               !args[:hvac_perf_data_heating_min_speed_cops].nil?,
                                               !args[:hvac_perf_data_heating_max_speed_cops].nil?]
    error = (hvac_perf_data_heating_args_initialized.uniq.size != 1)
    errors << 'Did not specify all required heating detailed performance data arguments.' if error

    if hvac_perf_data_heating_args_initialized.uniq.size == 1 && hvac_perf_data_heating_args_initialized.uniq[0]
      heating_data_points_lengths = ["#{args[:hvac_perf_data_heating_outdoor_temperatures]}".count(','),
                                     "#{args[:hvac_perf_data_heating_min_speed_capacities]}".count(','),
                                     "#{args[:hvac_perf_data_heating_max_speed_capacities]}".count(','),
                                     "#{args[:hvac_perf_data_heating_min_speed_cops]}".count(','),
                                     "#{args[:hvac_perf_data_heating_max_speed_cops]}".count(',')]

      error = (heating_data_points_lengths.uniq.size != 1)
      errors << 'One or more detailed heating performance data arguments does not have enough comma-separated elements specified.' if error
    end

    hvac_perf_data_cooling_args_initialized = [!args[:hvac_perf_data_cooling_outdoor_temperatures].nil?,
                                               !args[:hvac_perf_data_cooling_min_speed_capacities].nil?,
                                               !args[:hvac_perf_data_cooling_max_speed_capacities].nil?,
                                               !args[:hvac_perf_data_cooling_min_speed_cops].nil?,
                                               !args[:hvac_perf_data_cooling_max_speed_cops].nil?]
    error = (hvac_perf_data_cooling_args_initialized.uniq.size != 1)
    errors << 'Did not specify all required cooling detailed performance data arguments.' if error

    if hvac_perf_data_cooling_args_initialized.uniq.size == 1 && hvac_perf_data_cooling_args_initialized.uniq[0]
      cooling_data_points_lengths = ["#{args[:hvac_perf_data_cooling_outdoor_temperatures]}".count(','),
                                     "#{args[:hvac_perf_data_cooling_min_speed_capacities]}".count(','),
                                     "#{args[:hvac_perf_data_cooling_max_speed_capacities]}".count(','),
                                     "#{args[:hvac_perf_data_cooling_min_speed_cops]}".count(','),
                                     "#{args[:hvac_perf_data_cooling_max_speed_cops]}".count(',')]

      error = (cooling_data_points_lengths.uniq.size != 1)
      errors << 'One or more detailed cooling performance data arguments does not have enough comma-separated elements specified.' if error
    end

    emissions_args_initialized = [!args[:emissions_scenario_names].nil?,
                                  !args[:emissions_types].nil?,
                                  !args[:emissions_electricity_units].nil?,
                                  !args[:emissions_electricity_values_or_filepaths].nil?]
    error = (emissions_args_initialized.uniq.size != 1)
    errors << 'Did not specify all required emissions arguments.' if error

    HPXML::fossil_fuels.each do |fossil_fuel|
      underscore_case = OpenStudio::toUnderscoreCase(fossil_fuel)

      if !args["emissions_#{underscore_case}_values".to_sym].nil?
        error = args[:emissions_fossil_fuel_units].nil?
        errors << "Did not specify fossil fuel emissions units for #{fossil_fuel} emissions values." if error
      end
    end

    if emissions_args_initialized.uniq.size == 1 && emissions_args_initialized.uniq[0]
      emissions_scenario_lengths = [args[:emissions_scenario_names].count(','),
                                    args[:emissions_types].count(','),
                                    args[:emissions_electricity_units].count(','),
                                    "#{args[:emissions_electricity_values_or_filepaths]}".count(',')]

      emissions_scenario_lengths += [args[:emissions_electricity_number_of_header_rows].count(',')] unless args[:emissions_electricity_number_of_header_rows].nil?
      emissions_scenario_lengths += [args[:emissions_electricity_column_numbers].count(',')] unless args[:emissions_electricity_column_numbers].nil?

      HPXML::fossil_fuels.each do |fossil_fuel|
        underscore_case = OpenStudio::toUnderscoreCase(fossil_fuel)

        emissions_scenario_lengths += ["#{args["emissions_#{underscore_case}_values".to_sym]}".count(',')] unless args["emissions_#{underscore_case}_values".to_sym].nil?
      end

      error = (emissions_scenario_lengths.uniq.size != 1)
      errors << 'One or more emissions arguments does not have enough comma-separated elements specified.' if error
    end

    bills_args_initialized = [!args[:utility_bill_scenario_names].nil?]
    if bills_args_initialized.uniq[0]
      bills_scenario_lengths = [args[:utility_bill_scenario_names].count(',')]
      HPXML::all_fuels.each do |fuel|
        underscore_case = OpenStudio::toUnderscoreCase(fuel)

        bills_scenario_lengths += ["#{args["utility_bill_#{underscore_case}_fixed_charges".to_sym]}".count(',')] unless args["utility_bill_#{underscore_case}_fixed_charges".to_sym].nil?
        bills_scenario_lengths += ["#{args["utility_bill_#{underscore_case}_marginal_rates".to_sym]}".count(',')] unless args["utility_bill_#{underscore_case}_marginal_rates".to_sym].nil?
      end

      error = (bills_scenario_lengths.uniq.size != 1)
      errors << 'One or more utility bill arguments does not have enough comma-separated elements specified.' if error
    end

    error = (args[:geometry_unit_aspect_ratio] <= 0)
    errors << 'Aspect ratio must be greater than zero.' if error

    error = (args[:geometry_foundation_height] < 0)
    errors << 'Foundation height cannot be negative.' if error

    error = (args[:geometry_unit_num_floors_above_grade] > 6)
    errors << 'Number of above-grade floors must be six or less.' if error

    error = (args[:geometry_garage_protrusion] < 0) || (args[:geometry_garage_protrusion] > 1)
    errors << 'Garage protrusion fraction must be between zero and one.' if error

    error = (args[:geometry_unit_left_wall_is_adiabatic] && args[:geometry_unit_right_wall_is_adiabatic] && args[:geometry_unit_front_wall_is_adiabatic] && args[:geometry_unit_back_wall_is_adiabatic])
    errors << 'At least one wall must be set to non-adiabatic.' if error

    error = (args[:geometry_unit_type] == HPXML::ResidentialTypeSFA) && (args[:geometry_foundation_type] == HPXML::FoundationTypeAboveApartment)
    errors << 'Single-family attached units cannot be above another unit.' if error

    error = (args[:geometry_unit_type] == HPXML::ResidentialTypeSFA) && (args[:geometry_attic_type] == HPXML::AtticTypeBelowApartment)
    errors << 'Single-family attached units cannot be below another unit.' if error

    error = (args[:geometry_garage_protrusion] > 0) && (args[:geometry_roof_type] == Constants::RoofTypeHip) && (args[:geometry_garage_width] * args[:geometry_garage_depth] > 0)
    errors << 'Cannot handle protruding garage and hip roof.' if error

    error = (args[:geometry_garage_protrusion] > 0) && (args[:geometry_unit_aspect_ratio] < 1) && (args[:geometry_garage_width] * args[:geometry_garage_depth] > 0) && (args[:geometry_roof_type] == Constants::RoofTypeGable)
    errors << 'Cannot handle protruding garage and attic ridge running from front to back.' if error

    error = (args[:geometry_foundation_type] == HPXML::FoundationTypeAmbient) && (args[:geometry_garage_width] * args[:geometry_garage_depth] > 0)
    errors << 'Cannot handle garages with an ambient foundation type.' if error

    error = (args[:door_area] < 0)
    errors << 'Door area cannot be negative.' if error

    error = (args[:window_aspect_ratio] <= 0)
    errors << 'Window aspect ratio must be greater than zero.' if error

    return errors
  end
end

# Collection of methods for creating the HPXML file and setting properties based on user arguments
module HPXMLFile
  # Create the closed-form geometry, and then call individual set_xxx methods
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param args [Hash] Map of :argument_name => value
  # @param epw_path [String] Path to the EPW weather file
  # @param hpxml_path [String] Path to the created HPXML file
  # @param existing_hpxml_path [String] Path to the existing HPXML file
  # @return [Oga::XML::Element] Root XML element of the updated HPXML document
  def self.create(runner, model, args, epw_path, hpxml_path, existing_hpxml_path)
    if need_weather_based_on_args(args)
      weather = WeatherFile.new(epw_path: epw_path, runner: nil)
    end

    success = create_geometry_envelope(runner, model, args)
    return false if not success

    @surface_ids = {}

    # Sorting of objects to make the measure deterministic
    sorted_surfaces = model.getSurfaces.sort_by { |s| s.additionalProperties.getFeatureAsInteger('Index').get }
    sorted_subsurfaces = model.getSubSurfaces.sort_by { |ss| ss.additionalProperties.getFeatureAsInteger('Index').get }

    hpxml = HPXML.new(hpxml_path: existing_hpxml_path)

    if not set_header(runner, hpxml, args)
      return false
    end

    hpxml_bldg = add_building(hpxml, args)
    set_site(hpxml_bldg, args)
    set_neighbor_buildings(hpxml_bldg, args)
    set_building_occupancy(hpxml_bldg, args)
    set_building_construction(hpxml_bldg, args)
    set_building_header(hpxml_bldg, args)
    set_climate_and_risk_zones(hpxml_bldg, args)
    set_air_infiltration_measurements(hpxml_bldg, args)
    set_roofs(hpxml_bldg, args, sorted_surfaces)
    set_rim_joists(hpxml_bldg, model, args, sorted_surfaces)
    set_walls(hpxml_bldg, model, args, sorted_surfaces)
    set_foundation_walls(hpxml_bldg, model, args, sorted_surfaces)
    set_floors(hpxml_bldg, args, sorted_surfaces)
    set_slabs(hpxml_bldg, model, args, sorted_surfaces)
    set_windows(hpxml_bldg, model, args, sorted_subsurfaces)
    set_skylights(hpxml_bldg, args, sorted_subsurfaces)
    set_doors(hpxml_bldg, model, args, sorted_subsurfaces)
    set_attics(hpxml_bldg, args)
    set_foundations(hpxml_bldg, args)
    set_heating_systems(hpxml_bldg, args)
    set_cooling_systems(hpxml_bldg, args)
    set_heat_pumps(hpxml_bldg, args)
    set_geothermal_loop(hpxml_bldg, args)
    set_secondary_heating_systems(hpxml_bldg, args)
    set_hvac_distribution(hpxml_bldg, args)
    set_hvac_blower(hpxml_bldg, args)
    set_hvac_control(hpxml, hpxml_bldg, args, weather)
    set_ventilation_fans(hpxml_bldg, args)
    set_water_heating_systems(hpxml_bldg, args)
    set_hot_water_distribution(hpxml_bldg, args)
    set_water_fixtures(hpxml_bldg, args)
    set_solar_thermal(hpxml_bldg, args, weather)
    set_pv_systems(hpxml_bldg, args, weather)
    set_battery(hpxml_bldg, args)
    set_lighting(hpxml_bldg, args)
    set_dehumidifier(hpxml_bldg, args)
    set_clothes_washer(hpxml_bldg, args)
    set_clothes_dryer(hpxml_bldg, args)
    set_dishwasher(hpxml_bldg, args)
    set_refrigerator(hpxml_bldg, args)
    set_extra_refrigerator(hpxml_bldg, args)
    set_freezer(hpxml_bldg, args)
    set_cooking_range_oven(hpxml_bldg, args)
    set_ceiling_fans(hpxml_bldg, args)
    set_misc_plug_loads_television(hpxml_bldg, args)
    set_misc_plug_loads_other(hpxml_bldg, args)
    set_misc_plug_loads_vehicle(hpxml_bldg, args)
    set_misc_plug_loads_well_pump(hpxml_bldg, args)
    set_misc_fuel_loads_grill(hpxml_bldg, args)
    set_misc_fuel_loads_lighting(hpxml_bldg, args)
    set_misc_fuel_loads_fireplace(hpxml_bldg, args)
    set_pool(hpxml_bldg, args)
    set_permanent_spa(hpxml_bldg, args)
    collapse_surfaces(hpxml_bldg, args)
    renumber_hpxml_ids(hpxml_bldg)

    hpxml_doc = hpxml.to_doc()
    hpxml.set_unique_hpxml_ids(hpxml_doc, true) if hpxml.buildings.size > 1
    XMLHelper.write_file(hpxml_doc, hpxml_path)

    if args[:apply_defaults]
      # Always check for invalid HPXML file before applying defaults
      if not validate_hpxml(runner, hpxml, hpxml_doc, hpxml_path)
        return false
      end

      Defaults.apply(runner, hpxml, hpxml_bldg, weather)
      hpxml_doc = hpxml.to_doc()
      hpxml.set_unique_hpxml_ids(hpxml_doc, true) if hpxml.buildings.size > 1
      XMLHelper.write_file(hpxml_doc, hpxml_path)
    end

    if args[:apply_validation]
      # Optionally check for invalid HPXML file (with or without defaults applied)
      if not validate_hpxml(runner, hpxml, hpxml_doc, hpxml_path)
        return false
      end
    end

    return hpxml_doc
  end

  # Determines if we need to process the weather; we avoid this if we can because it has a runtime performance impact
  #
  # @param args [Hash] Map of :argument_name => value
  # @return [Boolean] True if we need to process the weather file
  def self.need_weather_based_on_args(args)
    if (args[:hvac_control_heating_season_period].to_s == Constants::BuildingAmerica) ||
       (args[:hvac_control_cooling_season_period].to_s == Constants::BuildingAmerica) ||
       (args[:solar_thermal_system_type] != Constants::None && "#{args[:solar_thermal_collector_tilt]}".start_with?('latitude')) ||
       (args[:pv_system_present] && "#{args[:pv_system_array_tilt]}".start_with?('latitude')) ||
       (args[:pv_system_2_present] && "#{args[:pv_system_2_array_tilt]}".start_with?('latitude')) ||
       (args[:apply_defaults])
      return true
    end

    return false
  end

  # Check for errors in hpxml, and validate hpxml_doc against hpxml_path
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml [HPXML] HPXML object
  # @param hpxml_doc [Oga::XML::Element] Root XML element of the HPXML document
  # @param hpxml_path [String] Path to the created HPXML file
  # @return [Boolean] True if the HPXML is valid
  def self.validate_hpxml(runner, hpxml, hpxml_doc, hpxml_path)
    # Check for errors in the HPXML object
    errors = []
    hpxml.buildings.each do |hpxml_bldg|
      errors += hpxml_bldg.check_for_errors()
    end
    if errors.size > 0
      fail "ERROR: Invalid HPXML object produced.\n#{errors}"
    end

    is_valid = true

    # Validate input HPXML against schema
    schema_path = File.join(File.dirname(__FILE__), '..', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schema', 'HPXML.xsd')
    schema_validator = XMLValidator.get_xml_validator(schema_path)
    xsd_errors, xsd_warnings = XMLValidator.validate_against_schema(hpxml_path, schema_validator)

    # Validate input HPXML against schematron docs
    schematron_path = File.join(File.dirname(__FILE__), '..', 'HPXMLtoOpenStudio', 'resources', 'hpxml_schematron', 'EPvalidator.xml')
    schematron_validator = XMLValidator.get_xml_validator(schematron_path)
    sct_errors, sct_warnings = XMLValidator.validate_against_schematron(hpxml_path, schematron_validator, hpxml_doc)

    # Handle errors/warnings
    (xsd_errors + sct_errors).each do |error|
      runner.registerError("#{hpxml_path}: #{error}")
      is_valid = false
    end
    (xsd_warnings + sct_warnings).each do |warning|
      runner.registerWarning("#{hpxml_path}: #{warning}")
    end

    return is_valid
  end

  # Create 3D geometry (surface, subsurfaces) for a given unit type
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param args [Hash] Map of :argument_name => value
  # @return [Boolean] True if successful
  def self.create_geometry_envelope(runner, model, args)
    args[:geometry_roof_pitch] = { '1:12' => 1.0 / 12.0,
                                   '2:12' => 2.0 / 12.0,
                                   '3:12' => 3.0 / 12.0,
                                   '4:12' => 4.0 / 12.0,
                                   '5:12' => 5.0 / 12.0,
                                   '6:12' => 6.0 / 12.0,
                                   '7:12' => 7.0 / 12.0,
                                   '8:12' => 8.0 / 12.0,
                                   '9:12' => 9.0 / 12.0,
                                   '10:12' => 10.0 / 12.0,
                                   '11:12' => 11.0 / 12.0,
                                   '12:12' => 12.0 / 12.0 }[args[:geometry_roof_pitch]]

    args[:geometry_rim_joist_height] = args[:geometry_rim_joist_height].to_f / 12.0

    if args[:geometry_foundation_type] == HPXML::FoundationTypeSlab
      args[:geometry_foundation_height] = 0.0
      args[:geometry_foundation_height_above_grade] = 0.0
      args[:geometry_rim_joist_height] = 0.0
    elsif (args[:geometry_foundation_type] == HPXML::FoundationTypeAmbient) || args[:geometry_foundation_type].start_with?(HPXML::FoundationTypeBellyAndWing)
      args[:geometry_rim_joist_height] = 0.0
    end

    if model.getSpaces.size > 0
      runner.registerError('Starting model is not empty.')
      return false
    end

    if args[:geometry_unit_type] == HPXML::ResidentialTypeSFD
      success = Geometry.create_single_family_detached(runner: runner, model: model, **args)
    elsif args[:geometry_unit_type] == HPXML::ResidentialTypeSFA
      success = Geometry.create_single_family_attached(model: model, **args)
    elsif args[:geometry_unit_type] == HPXML::ResidentialTypeApartment
      success = Geometry.create_apartment(model: model, **args)
    elsif args[:geometry_unit_type] == HPXML::ResidentialTypeManufactured
      success = Geometry.create_single_family_detached(runner: runner, model: model, **args)
    end
    return false if not success

    success = Geometry.create_doors(runner: runner, model: model, **args)
    return false if not success

    success = Geometry.create_windows_and_skylights(runner: runner, model: model, **args)
    return false if not success

    return true
  end

  # Check if unavailable period already exists for given name and begin/end times.
  #
  # @param hpxml [HPXML] HPXML object
  # @param column_name [String] Column name associated with unavailable_periods.csv
  # @param begin_month [Integer] Unavailable period begin month
  # @param begin_day [Integer] Unavailable period begin day
  # @param begin_hour [Integer] Unavailable period begin hour
  # @param end_month [Integer] Unavailable period end month
  # @param end_day [Integer] Unavailable period end day
  # @param end_hour [Integer] Unavailable period end hour
  # @param natvent_availability [String] Natural ventilation availability (HXPML::ScheduleXXX)
  # @return [Boolean] True if the unavailability period already exists
  def self.unavailable_period_exists(hpxml, column_name, begin_month, begin_day, begin_hour, end_month, end_day, end_hour, natvent_availability = nil)
    natvent_availability = HPXML::ScheduleUnavailable if natvent_availability.nil?

    hpxml.header.unavailable_periods.each do |unavailable_period|
      begin_hour = 0 if begin_hour.nil?
      end_hour = 24 if end_hour.nil?

      next unless (unavailable_period.column_name == column_name) &&
                  (unavailable_period.begin_month == begin_month) &&
                  (unavailable_period.begin_day == begin_day) &&
                  (unavailable_period.begin_hour == begin_hour) &&
                  (unavailable_period.end_month == end_month) &&
                  (unavailable_period.end_day == end_day) &&
                  (unavailable_period.end_hour == end_hour) &&
                  (unavailable_period.natvent_availability == natvent_availability)

      return true
    end
    return false
  end

  # Set header properties, including:
  # - vacancy periods
  # - power outage periods
  # - software info program
  # - simulation control
  # - emissions scenarios
  # - utility bill scenarios
  #
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @param hpxml [HPXML] HPXML object
  # @param args [Hash] Map of :argument_name => value
  # @return [Boolean] true if no errors, otherwise false
  def self.set_header(runner, hpxml, args)
    errors = []

    hpxml.header.xml_type = 'HPXML'
    hpxml.header.xml_generated_by = 'BuildResidentialHPXML'
    hpxml.header.transaction = 'create'
    hpxml.header.whole_sfa_or_mf_building_sim = args[:whole_sfa_or_mf_building_sim]

    if not args[:schedules_unavailable_period_types].nil?
      unavailable_period_types = args[:schedules_unavailable_period_types].split(',').map(&:strip)
      unavailable_period_dates = args[:schedules_unavailable_period_dates].split(',').map(&:strip)
      if !args[:schedules_unavailable_period_window_natvent_availabilities].nil?
        natvent_availabilities = args[:schedules_unavailable_period_window_natvent_availabilities].split(',').map(&:strip)
      else
        natvent_availabilities = [''] * unavailable_period_types.size
      end

      unavailable_periods = unavailable_period_types.zip(unavailable_period_dates,
                                                         natvent_availabilities)

      unavailable_periods.each do |unavailable_period|
        column_name, date_time_range, natvent_availability = unavailable_period
        natvent_availability = nil if natvent_availability.empty?

        begin_month, begin_day, begin_hour, end_month, end_day, end_hour = Calendar.parse_date_time_range(date_time_range)

        if not unavailable_period_exists(hpxml, column_name, begin_month, begin_day, begin_hour, end_month, end_day, end_hour)
          hpxml.header.unavailable_periods.add(column_name: column_name, begin_month: begin_month, begin_day: begin_day, begin_hour: begin_hour, end_month: end_month, end_day: end_day, end_hour: end_hour, natvent_availability: natvent_availability)
        end
      end
    end

    if not args[:software_info_program_used].nil?
      if (not hpxml.header.software_program_used.nil?) && (hpxml.header.software_program_used != args[:software_info_program_used])
        errors << "'Software Info: Program Used' cannot vary across dwelling units."
      end
      hpxml.header.software_program_used = args[:software_info_program_used]
    end
    if not args[:software_info_program_version].nil?
      if (not hpxml.header.software_program_version.nil?) && (hpxml.header.software_program_version != "#{args[:software_info_program_version]}")
        errors << "'Software Info: Program Version' cannot vary across dwelling units."
      end
      hpxml.header.software_program_version = "#{args[:software_info_program_version]}"
    end

    if not args[:simulation_control_timestep].nil?
      if (not hpxml.header.timestep.nil?) && (hpxml.header.timestep != args[:simulation_control_timestep])
        errors << "'Simulation Control: Timestep' cannot vary across dwelling units."
      end
      hpxml.header.timestep = args[:simulation_control_timestep]
    end

    if not args[:simulation_control_run_period].nil?
      begin_month, begin_day, _begin_hour, end_month, end_day, _end_hour = Calendar.parse_date_time_range(args[:simulation_control_run_period])
      if (!hpxml.header.sim_begin_month.nil? && (hpxml.header.sim_begin_month != begin_month)) ||
         (!hpxml.header.sim_begin_day.nil? && (hpxml.header.sim_begin_day != begin_day)) ||
         (!hpxml.header.sim_end_month.nil? && (hpxml.header.sim_end_month != end_month)) ||
         (!hpxml.header.sim_end_day.nil? && (hpxml.header.sim_end_day != end_day))
        errors << "'Simulation Control: Run Period' cannot vary across dwelling units."
      end
      hpxml.header.sim_begin_month = begin_month
      hpxml.header.sim_begin_day = begin_day
      hpxml.header.sim_end_month = end_month
      hpxml.header.sim_end_day = end_day
    end

    if not args[:simulation_control_run_period_calendar_year].nil?
      if (not hpxml.header.sim_calendar_year.nil?) && (hpxml.header.sim_calendar_year != Integer(args[:simulation_control_run_period_calendar_year]))
        errors << "'Simulation Control: Run Period Calendar Year' cannot vary across dwelling units."
      end
      hpxml.header.sim_calendar_year = args[:simulation_control_run_period_calendar_year]
    end

    if not args[:simulation_control_temperature_capacitance_multiplier].nil?
      if (not hpxml.header.temperature_capacitance_multiplier.nil?) && (hpxml.header.temperature_capacitance_multiplier != Float(args[:simulation_control_temperature_capacitance_multiplier]))
        errors << "'Simulation Control: Temperature Capacitance Multiplier' cannot vary across dwelling units."
      end
      hpxml.header.temperature_capacitance_multiplier = args[:simulation_control_temperature_capacitance_multiplier]
    end

    if not args[:simulation_control_defrost_model_type].nil?
      if (not hpxml.header.defrost_model_type.nil?) && (hpxml.header.defrost_model_type != args[:simulation_control_defrost_model_type])
        errors << "'Simulation Control: Defrost Model Type' cannot vary across dwelling units."
      end
      hpxml.header.defrost_model_type = args[:simulation_control_defrost_model_type]
    end

    if not args[:simulation_control_onoff_thermostat_deadband].nil?
      if (not hpxml.header.hvac_onoff_thermostat_deadband.nil?) && (hpxml.header.hvac_onoff_thermostat_deadband != args[:simulation_control_onoff_thermostat_deadband])
        errors << "'Simulation Control: HVAC On-Off Thermostat Deadband' cannot vary across dwelling units."
      end
      hpxml.header.hvac_onoff_thermostat_deadband = args[:simulation_control_onoff_thermostat_deadband]
    end

    if not args[:simulation_control_heat_pump_backup_heating_capacity_increment].nil?
      if (not hpxml.header.heat_pump_backup_heating_capacity_increment.nil?) && (hpxml.header.heat_pump_backup_heating_capacity_increment != args[:simulation_control_heat_pump_backup_heating_capacity_increment])
        errors << "'Simulation Control: Heat Pump Backup Heating Capacity Increment' cannot vary across dwelling units."
      end
      hpxml.header.heat_pump_backup_heating_capacity_increment = args[:simulation_control_heat_pump_backup_heating_capacity_increment]
    end

    if not args[:emissions_scenario_names].nil?
      emissions_scenario_names = args[:emissions_scenario_names].split(',').map(&:strip)
      emissions_types = args[:emissions_types].split(',').map(&:strip)
      emissions_electricity_units = args[:emissions_electricity_units].split(',').map(&:strip)
      emissions_electricity_values_or_filepaths = "#{args[:emissions_electricity_values_or_filepaths]}".split(',').map(&:strip)

      if not args[:emissions_electricity_number_of_header_rows].nil?
        emissions_electricity_number_of_header_rows = args[:emissions_electricity_number_of_header_rows].split(',').map(&:strip)
      else
        emissions_electricity_number_of_header_rows = [nil] * emissions_scenario_names.size
      end
      if not args[:emissions_electricity_column_numbers].nil?
        emissions_electricity_column_numbers = args[:emissions_electricity_column_numbers].split(',').map(&:strip)
      else
        emissions_electricity_column_numbers = [nil] * emissions_scenario_names.size
      end
      if not args[:emissions_fossil_fuel_units].nil?
        fuel_units = args[:emissions_fossil_fuel_units].split(',').map(&:strip)
      else
        fuel_units = [nil] * emissions_scenario_names.size
      end

      fuel_values = {}
      HPXML::fossil_fuels.each do |fossil_fuel|
        underscore_case = OpenStudio::toUnderscoreCase(fossil_fuel)

        if not args["emissions_#{underscore_case}_values".to_sym].nil?
          fuel_values[fossil_fuel] = "#{args["emissions_#{underscore_case}_values".to_sym]}".split(',').map(&:strip)
        else
          fuel_values[fossil_fuel] = [nil] * emissions_scenario_names.size
        end
      end

      emissions_scenarios = emissions_scenario_names.zip(emissions_types,
                                                         emissions_electricity_units,
                                                         emissions_electricity_values_or_filepaths,
                                                         emissions_electricity_number_of_header_rows,
                                                         emissions_electricity_column_numbers,
                                                         fuel_units,
                                                         fuel_values[HPXML::FuelTypeNaturalGas],
                                                         fuel_values[HPXML::FuelTypePropane],
                                                         fuel_values[HPXML::FuelTypeOil],
                                                         fuel_values[HPXML::FuelTypeCoal],
                                                         fuel_values[HPXML::FuelTypeWoodCord],
                                                         fuel_values[HPXML::FuelTypeWoodPellets])
      emissions_scenarios.each do |emissions_scenario|
        name, emissions_type, elec_units, elec_value_or_schedule_filepath, elec_num_headers, elec_column_num, fuel_units, natural_gas_value, propane_value, fuel_oil_value, coal_value, wood_value, wood_pellets_value = emissions_scenario

        elec_value = Float(elec_value_or_schedule_filepath) rescue nil
        if elec_value.nil?
          elec_schedule_filepath = elec_value_or_schedule_filepath
          elec_num_headers = Integer(elec_num_headers) rescue nil
          elec_column_num = Integer(elec_column_num) rescue nil
        end
        natural_gas_value = Float(natural_gas_value) rescue nil
        propane_value = Float(propane_value) rescue nil
        fuel_oil_value = Float(fuel_oil_value) rescue nil
        coal_value = Float(coal_value) rescue nil
        wood_value = Float(wood_value) rescue nil
        wood_pellets_value = Float(wood_pellets_value) rescue nil

        emissions_scenario_exists = false
        hpxml.header.emissions_scenarios.each do |es|
          if (es.name != name) || (es.emissions_type != emissions_type)
            next
          end

          if (es.emissions_type != emissions_type) ||
             (!elec_units.nil? && es.elec_units != elec_units) ||
             (!elec_value.nil? && es.elec_value != elec_value) ||
             (!elec_schedule_filepath.nil? && es.elec_schedule_filepath != elec_schedule_filepath) ||
             (!elec_num_headers.nil? && es.elec_schedule_number_of_header_rows != elec_num_headers) ||
             (!elec_column_num.nil? && es.elec_schedule_column_number != elec_column_num) ||
             (!es.natural_gas_units.nil? && !fuel_units.nil? && es.natural_gas_units != fuel_units) ||
             (!natural_gas_value.nil? && es.natural_gas_value != natural_gas_value) ||
             (!es.propane_units.nil? && !fuel_units.nil? && es.propane_units != fuel_units) ||
             (!propane_value.nil? && es.propane_value != propane_value) ||
             (!es.fuel_oil_units.nil? && !fuel_units.nil? && es.fuel_oil_units != fuel_units) ||
             (!fuel_oil_value.nil? && es.fuel_oil_value != fuel_oil_value) ||
             (!es.coal_units.nil? && !fuel_units.nil? && es.coal_units != fuel_units) ||
             (!coal_value.nil? && es.coal_value != coal_value) ||
             (!es.wood_units.nil? && !fuel_units.nil? && es.wood_units != fuel_units) ||
             (!wood_value.nil? && es.wood_value != wood_value) ||
             (!es.wood_pellets_units.nil? && !fuel_units.nil? && es.wood_pellets_units != fuel_units) ||
             (!wood_pellets_value.nil? && es.wood_pellets_value != wood_pellets_value)
            errors << "HPXML header already includes an emissions scenario named '#{name}' with type '#{emissions_type}'."
          else
            emissions_scenario_exists = true
          end
        end

        next if emissions_scenario_exists

        hpxml.header.emissions_scenarios.add(name: name,
                                             emissions_type: emissions_type,
                                             elec_units: elec_units,
                                             elec_value: elec_value,
                                             elec_schedule_filepath: elec_schedule_filepath,
                                             elec_schedule_number_of_header_rows: elec_num_headers,
                                             elec_schedule_column_number: elec_column_num,
                                             natural_gas_units: fuel_units,
                                             natural_gas_value: natural_gas_value,
                                             propane_units: fuel_units,
                                             propane_value: propane_value,
                                             fuel_oil_units: fuel_units,
                                             fuel_oil_value: fuel_oil_value,
                                             coal_units: fuel_units,
                                             coal_value: coal_value,
                                             wood_units: fuel_units,
                                             wood_value: wood_value,
                                             wood_pellets_units: fuel_units,
                                             wood_pellets_value: wood_pellets_value)
      end
    end

    if not args[:utility_bill_scenario_names].nil?
      bills_scenario_names = args[:utility_bill_scenario_names].split(',').map(&:strip)

      if not args[:utility_bill_electricity_filepaths].nil?
        bills_electricity_filepaths = args[:utility_bill_electricity_filepaths].split(',').map(&:strip)
      else
        bills_electricity_filepaths = [nil] * bills_scenario_names.size
      end

      fixed_charges = {}
      HPXML::all_fuels.each do |fuel|
        underscore_case = OpenStudio::toUnderscoreCase(fuel)

        if not args["utility_bill_#{underscore_case}_fixed_charges".to_sym].nil?
          fixed_charges[fuel] = "#{args["utility_bill_#{underscore_case}_fixed_charges".to_sym]}".split(',').map(&:strip)
        else
          fixed_charges[fuel] = [nil] * bills_scenario_names.size
        end
      end

      marginal_rates = {}
      HPXML::all_fuels.each do |fuel|
        underscore_case = OpenStudio::toUnderscoreCase(fuel)

        if not args["utility_bill_#{underscore_case}_marginal_rates".to_sym].nil?
          marginal_rates[fuel] = "#{args["utility_bill_#{underscore_case}_marginal_rates".to_sym]}".split(',').map(&:strip)
        else
          marginal_rates[fuel] = [nil] * bills_scenario_names.size
        end
      end

      if not args[:utility_bill_pv_compensation_types].nil?
        bills_pv_compensation_types = args[:utility_bill_pv_compensation_types].split(',').map(&:strip)
      else
        bills_pv_compensation_types = [nil] * bills_scenario_names.size
      end

      if not args[:utility_bill_pv_net_metering_annual_excess_sellback_rate_types].nil?
        bills_pv_net_metering_annual_excess_sellback_rate_types = args[:utility_bill_pv_net_metering_annual_excess_sellback_rate_types].split(',').map(&:strip)
      else
        bills_pv_net_metering_annual_excess_sellback_rate_types = [nil] * bills_scenario_names.size
      end

      if not args[:utility_bill_pv_net_metering_annual_excess_sellback_rates].nil?
        bills_pv_net_metering_annual_excess_sellback_rates = "#{args[:utility_bill_pv_net_metering_annual_excess_sellback_rates]}".split(',').map(&:strip)
      else
        bills_pv_net_metering_annual_excess_sellback_rates = [nil] * bills_scenario_names.size
      end

      if not args[:utility_bill_pv_feed_in_tariff_rates].nil?
        bills_pv_feed_in_tariff_rates = "#{args[:utility_bill_pv_feed_in_tariff_rates]}".split(',').map(&:strip)
      else
        bills_pv_feed_in_tariff_rates = [nil] * bills_scenario_names.size
      end

      if not args[:utility_bill_pv_monthly_grid_connection_fee_units].nil?
        bills_pv_monthly_grid_connection_fee_units = args[:utility_bill_pv_monthly_grid_connection_fee_units].split(',').map(&:strip)
      else
        bills_pv_monthly_grid_connection_fee_units = [nil] * bills_scenario_names.size
      end

      if not args[:utility_bill_pv_monthly_grid_connection_fees].nil?
        bills_pv_monthly_grid_connection_fees = "#{args[:utility_bill_pv_monthly_grid_connection_fees]}".split(',').map(&:strip)
      else
        bills_pv_monthly_grid_connection_fees = [nil] * bills_scenario_names.size
      end

      bills_scenarios = bills_scenario_names.zip(bills_electricity_filepaths,
                                                 fixed_charges[HPXML::FuelTypeElectricity],
                                                 fixed_charges[HPXML::FuelTypeNaturalGas],
                                                 fixed_charges[HPXML::FuelTypePropane],
                                                 fixed_charges[HPXML::FuelTypeOil],
                                                 fixed_charges[HPXML::FuelTypeCoal],
                                                 fixed_charges[HPXML::FuelTypeWoodCord],
                                                 fixed_charges[HPXML::FuelTypeWoodPellets],
                                                 marginal_rates[HPXML::FuelTypeElectricity],
                                                 marginal_rates[HPXML::FuelTypeNaturalGas],
                                                 marginal_rates[HPXML::FuelTypePropane],
                                                 marginal_rates[HPXML::FuelTypeOil],
                                                 marginal_rates[HPXML::FuelTypeCoal],
                                                 marginal_rates[HPXML::FuelTypeWoodCord],
                                                 marginal_rates[HPXML::FuelTypeWoodPellets],
                                                 bills_pv_compensation_types,
                                                 bills_pv_net_metering_annual_excess_sellback_rate_types,
                                                 bills_pv_net_metering_annual_excess_sellback_rates,
                                                 bills_pv_feed_in_tariff_rates,
                                                 bills_pv_monthly_grid_connection_fee_units,
                                                 bills_pv_monthly_grid_connection_fees)

      bills_scenarios.each do |bills_scenario|
        name, elec_tariff_filepath, elec_fixed_charge, natural_gas_fixed_charge, propane_fixed_charge, fuel_oil_fixed_charge, coal_fixed_charge, wood_fixed_charge, wood_pellets_fixed_charge, elec_marginal_rate, natural_gas_marginal_rate, propane_marginal_rate, fuel_oil_marginal_rate, coal_marginal_rate, wood_marginal_rate, wood_pellets_marginal_rate, pv_compensation_type, pv_net_metering_annual_excess_sellback_rate_type, pv_net_metering_annual_excess_sellback_rate, pv_feed_in_tariff_rate, pv_monthly_grid_connection_fee_unit, pv_monthly_grid_connection_fee = bills_scenario

        elec_tariff_filepath = (elec_tariff_filepath.to_s.include?('.') ? elec_tariff_filepath : nil)
        elec_fixed_charge = Float(elec_fixed_charge) rescue nil
        natural_gas_fixed_charge = Float(natural_gas_fixed_charge) rescue nil
        propane_fixed_charge = Float(propane_fixed_charge) rescue nil
        fuel_oil_fixed_charge = Float(fuel_oil_fixed_charge) rescue nil
        coal_fixed_charge = Float(coal_fixed_charge) rescue nil
        wood_fixed_charge = Float(wood_fixed_charge) rescue nil
        wood_pellets_fixed_charge = Float(wood_pellets_fixed_charge) rescue nil
        elec_marginal_rate = Float(elec_marginal_rate) rescue nil
        natural_gas_marginal_rate = Float(natural_gas_marginal_rate) rescue nil
        propane_marginal_rate = Float(propane_marginal_rate) rescue nil
        fuel_oil_marginal_rate = Float(fuel_oil_marginal_rate) rescue nil
        coal_marginal_rate = Float(coal_marginal_rate) rescue nil
        wood_marginal_rate = Float(wood_marginal_rate) rescue nil
        wood_pellets_marginal_rate = Float(wood_pellets_marginal_rate) rescue nil

        if pv_compensation_type == HPXML::PVCompensationTypeNetMetering
          if pv_net_metering_annual_excess_sellback_rate_type == HPXML::PVAnnualExcessSellbackRateTypeUserSpecified
            pv_net_metering_annual_excess_sellback_rate = Float(pv_net_metering_annual_excess_sellback_rate) rescue nil
          else
            pv_net_metering_annual_excess_sellback_rate = nil
          end
          pv_feed_in_tariff_rate = nil
        elsif pv_compensation_type == HPXML::PVCompensationTypeFeedInTariff
          pv_feed_in_tariff_rate = Float(pv_feed_in_tariff_rate) rescue nil
          pv_net_metering_annual_excess_sellback_rate_type = nil
          pv_net_metering_annual_excess_sellback_rate = nil
        end

        if pv_monthly_grid_connection_fee_unit == HPXML::UnitsDollarsPerkW
          pv_monthly_grid_connection_fee_dollars_per_kw = Float(pv_monthly_grid_connection_fee) rescue nil
        elsif pv_monthly_grid_connection_fee_unit == HPXML::UnitsDollars
          pv_monthly_grid_connection_fee_dollars = Float(pv_monthly_grid_connection_fee) rescue nil
        end

        utility_bill_scenario_exists = false
        hpxml.header.utility_bill_scenarios.each do |ubs|
          next if ubs.name != name

          if (!elec_tariff_filepath.nil? && ubs.elec_tariff_filepath != elec_tariff_filepath) ||
             (!elec_fixed_charge.nil? && ubs.elec_fixed_charge != elec_fixed_charge) ||
             (!natural_gas_fixed_charge.nil? && ubs.natural_gas_fixed_charge != natural_gas_fixed_charge) ||
             (!propane_fixed_charge.nil? && ubs.propane_fixed_charge != propane_fixed_charge) ||
             (!fuel_oil_fixed_charge.nil? && ubs.fuel_oil_fixed_charge != fuel_oil_fixed_charge) ||
             (!coal_fixed_charge.nil? && ubs.coal_fixed_charge != coal_fixed_charge) ||
             (!wood_fixed_charge.nil? && ubs.wood_fixed_charge != wood_fixed_charge) ||
             (!wood_pellets_fixed_charge.nil? && ubs.wood_pellets_fixed_charge != wood_pellets_fixed_charge) ||
             (!elec_marginal_rate.nil? && ubs.elec_marginal_rate != elec_marginal_rate) ||
             (!natural_gas_marginal_rate.nil? && ubs.natural_gas_marginal_rate != natural_gas_marginal_rate) ||
             (!propane_marginal_rate.nil? && ubs.propane_marginal_rate != propane_marginal_rate) ||
             (!fuel_oil_marginal_rate.nil? && ubs.fuel_oil_marginal_rate != fuel_oil_marginal_rate) ||
             (!coal_marginal_rate.nil? && ubs.coal_marginal_rate != coal_marginal_rate) ||
             (!wood_marginal_rate.nil? && ubs.wood_marginal_rate != wood_marginal_rate) ||
             (!wood_pellets_marginal_rate.nil? && ubs.wood_pellets_marginal_rate != wood_pellets_marginal_rate) ||
             (!pv_compensation_type.nil? && ubs.pv_compensation_type != pv_compensation_type) ||
             (!pv_net_metering_annual_excess_sellback_rate_type.nil? && ubs.pv_net_metering_annual_excess_sellback_rate_type != pv_net_metering_annual_excess_sellback_rate_type) ||
             (!pv_net_metering_annual_excess_sellback_rate.nil? && ubs.pv_net_metering_annual_excess_sellback_rate != pv_net_metering_annual_excess_sellback_rate) ||
             (!pv_feed_in_tariff_rate.nil? && ubs.pv_feed_in_tariff_rate != pv_feed_in_tariff_rate) ||
             (!pv_monthly_grid_connection_fee_dollars_per_kw.nil? && ubs.pv_monthly_grid_connection_fee_dollars_per_kw != pv_monthly_grid_connection_fee_dollars_per_kw) ||
             (!pv_monthly_grid_connection_fee_dollars.nil? && ubs.pv_monthly_grid_connection_fee_dollars != pv_monthly_grid_connection_fee_dollars)
            errors << "HPXML header already includes a utility bill scenario named '#{name}'."
          else
            utility_bill_scenario_exists = true
          end
        end

        next if utility_bill_scenario_exists

        hpxml.header.utility_bill_scenarios.add(name: name,
                                                elec_tariff_filepath: elec_tariff_filepath,
                                                elec_fixed_charge: elec_fixed_charge,
                                                natural_gas_fixed_charge: natural_gas_fixed_charge,
                                                propane_fixed_charge: propane_fixed_charge,
                                                fuel_oil_fixed_charge: fuel_oil_fixed_charge,
                                                coal_fixed_charge: coal_fixed_charge,
                                                wood_fixed_charge: wood_fixed_charge,
                                                wood_pellets_fixed_charge: wood_pellets_fixed_charge,
                                                elec_marginal_rate: elec_marginal_rate,
                                                natural_gas_marginal_rate: natural_gas_marginal_rate,
                                                propane_marginal_rate: propane_marginal_rate,
                                                fuel_oil_marginal_rate: fuel_oil_marginal_rate,
                                                coal_marginal_rate: coal_marginal_rate,
                                                wood_marginal_rate: wood_marginal_rate,
                                                wood_pellets_marginal_rate: wood_pellets_marginal_rate,
                                                pv_compensation_type: pv_compensation_type,
                                                pv_net_metering_annual_excess_sellback_rate_type: pv_net_metering_annual_excess_sellback_rate_type,
                                                pv_net_metering_annual_excess_sellback_rate: pv_net_metering_annual_excess_sellback_rate,
                                                pv_feed_in_tariff_rate: pv_feed_in_tariff_rate,
                                                pv_monthly_grid_connection_fee_dollars_per_kw: pv_monthly_grid_connection_fee_dollars_per_kw,
                                                pv_monthly_grid_connection_fee_dollars: pv_monthly_grid_connection_fee_dollars)
      end
    end

    errors.each do |error|
      runner.registerError(error)
    end
    return errors.empty?
  end

  # Add a building (i.e., unit), along with site properties, to the HPXML file.
  # Return the building so we can then set more properties on it.
  #
  # @param hpxml [HPXML] HPXML object
  # @param args [Hash] Map of :argument_name => value
  # @return [HPXML::Building] HPXML Building object representing an individual dwelling unit
  def self.add_building(hpxml, args)
    if not args[:simulation_control_daylight_saving_period].nil?
      begin_month, begin_day, _begin_hour, end_month, end_day, _end_hour = Calendar.parse_date_time_range(args[:simulation_control_daylight_saving_period])
      dst_begin_month = begin_month
      dst_begin_day = begin_day
      dst_end_month = end_month
      dst_end_day = end_day
    end

    hpxml.buildings.add(building_id: 'MyBuilding',
                        site_id: 'SiteID',
                        event_type: 'proposed workscope',
                        city: args[:site_city],
                        state_code: args[:site_state_code],
                        zip_code: args[:site_zip_code],
                        time_zone_utc_offset: args[:site_time_zone_utc_offset],
                        elevation: args[:site_elevation],
                        latitude: args[:site_latitude],
                        longitude: args[:site_longitude],
                        dst_enabled: args[:simulation_control_daylight_saving_enabled],
                        dst_begin_month: dst_begin_month,
                        dst_begin_day: dst_begin_day,
                        dst_end_month: dst_end_month,
                        dst_end_day: dst_end_day)

    return hpxml.buildings[-1]
  end

  # Set site properties, including:
  # - shielding
  # - ground/soil
  # - surroundings
  # - orientation
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_site(hpxml_bldg, args)
    hpxml_bldg.site.shielding_of_home = args[:site_shielding_of_home]
    hpxml_bldg.site.ground_conductivity = args[:site_ground_conductivity]
    hpxml_bldg.site.ground_diffusivity = args[:site_ground_diffusivity]

    if not args[:site_soil_and_moisture_type].nil?
      soil_type, moisture_type = args[:site_soil_and_moisture_type].split(', ')
      hpxml_bldg.site.soil_type = soil_type
      hpxml_bldg.site.moisture_type = moisture_type
    end

    hpxml_bldg.site.site_type = args[:site_type]

    adb_walls = [args[:geometry_unit_left_wall_is_adiabatic], args[:geometry_unit_right_wall_is_adiabatic], args[:geometry_unit_front_wall_is_adiabatic], args[:geometry_unit_back_wall_is_adiabatic]]
    n_walls_attached = adb_walls.count(true)

    if [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include? args[:geometry_unit_type]
      if n_walls_attached == 3
        hpxml_bldg.site.surroundings = HPXML::SurroundingsThreeSides
      elsif n_walls_attached == 2
        hpxml_bldg.site.surroundings = HPXML::SurroundingsTwoSides
      elsif n_walls_attached == 1
        hpxml_bldg.site.surroundings = HPXML::SurroundingsOneSide
      else
        hpxml_bldg.site.surroundings = HPXML::SurroundingsStandAlone
      end
      if args[:geometry_attic_type] == HPXML::AtticTypeBelowApartment
        if args[:geometry_foundation_type] == HPXML::FoundationTypeAboveApartment
          hpxml_bldg.site.vertical_surroundings = HPXML::VerticalSurroundingsAboveAndBelow
        else
          hpxml_bldg.site.vertical_surroundings = HPXML::VerticalSurroundingsAbove
        end
      else
        if args[:geometry_foundation_type] == HPXML::FoundationTypeAboveApartment
          hpxml_bldg.site.vertical_surroundings = HPXML::VerticalSurroundingsBelow
        else
          hpxml_bldg.site.vertical_surroundings = HPXML::VerticalSurroundingsNoAboveOrBelow
        end
      end
    elsif [HPXML::ResidentialTypeSFD, HPXML::ResidentialTypeManufactured].include? args[:geometry_unit_type]
      hpxml_bldg.site.surroundings = HPXML::SurroundingsStandAlone
      hpxml_bldg.site.vertical_surroundings = HPXML::VerticalSurroundingsNoAboveOrBelow
    end

    hpxml_bldg.site.azimuth_of_front_of_home = args[:geometry_unit_orientation]
  end

  # Set neighboring buildings, including:
  # - facade
  # - distance
  # - height
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_neighbor_buildings(hpxml_bldg, args)
    nbr_map = { Constants::FacadeFront => [args[:neighbor_front_distance], args[:neighbor_front_height]],
                Constants::FacadeBack => [args[:neighbor_back_distance], args[:neighbor_back_height]],
                Constants::FacadeLeft => [args[:neighbor_left_distance], args[:neighbor_left_height]],
                Constants::FacadeRight => [args[:neighbor_right_distance], args[:neighbor_right_height]] }

    nbr_map.each do |facade, data|
      distance, neighbor_height = data
      next if distance == 0

      azimuth = Geometry.get_azimuth_from_facade(facade: facade, orientation: args[:geometry_unit_orientation])

      if (distance > 0) && (not neighbor_height.nil?)
        height = neighbor_height
      end

      hpxml_bldg.neighbor_buildings.add(azimuth: azimuth,
                                        distance: distance,
                                        height: height)
    end
  end

  # Set building occupancy properties, including:
  # - number of occupants
  # - general water use usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_building_occupancy(hpxml_bldg, args)
    hpxml_bldg.building_occupancy.number_of_residents = args[:geometry_unit_num_occupants]
    hpxml_bldg.building_occupancy.general_water_use_usage_multiplier = args[:general_water_use_usage_multiplier]
  end

  # Set building construction properties, including:
  # - number of conditioned floors
  # - number of beds/baths
  # - conditioned floor area / building volume
  # - ceiling height
  # - unit type
  # - number of dwelling units in the building
  # - year built
  # - dwelling unit multipliers
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_building_construction(hpxml_bldg, args)
    if args[:geometry_unit_type] == HPXML::ResidentialTypeApartment
      args[:geometry_unit_num_floors_above_grade] = 1
    end
    number_of_conditioned_floors_above_grade = args[:geometry_unit_num_floors_above_grade]
    number_of_conditioned_floors = number_of_conditioned_floors_above_grade
    if args[:geometry_foundation_type] == HPXML::FoundationTypeBasementConditioned
      number_of_conditioned_floors += 1
    end

    hpxml_bldg.building_construction.number_of_conditioned_floors = number_of_conditioned_floors
    hpxml_bldg.building_construction.number_of_conditioned_floors_above_grade = number_of_conditioned_floors_above_grade
    hpxml_bldg.building_construction.number_of_bedrooms = args[:geometry_unit_num_bedrooms]
    hpxml_bldg.building_construction.number_of_bathrooms = args[:geometry_unit_num_bathrooms]
    hpxml_bldg.building_construction.conditioned_floor_area = args[:geometry_unit_cfa]
    hpxml_bldg.building_construction.conditioned_building_volume = args[:geometry_unit_cfa] * args[:geometry_average_ceiling_height]
    hpxml_bldg.building_construction.average_ceiling_height = args[:geometry_average_ceiling_height]
    hpxml_bldg.building_construction.residential_facility_type = args[:geometry_unit_type]
    hpxml_bldg.building_construction.number_of_units_in_building = args[:geometry_building_num_units]
    hpxml_bldg.building_construction.year_built = args[:year_built]
    hpxml_bldg.building_construction.number_of_units = args[:unit_multiplier]
    hpxml_bldg.building_construction.unit_height_above_grade = args[:geometry_unit_height_above_grade]
  end

  # Set building header properties, including:
  # - detailed schedule file paths
  # - heat pump sizing methodologies
  # - natural ventilation availability
  # - summer shading season
  # - user-specified additional properties
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_building_header(hpxml_bldg, args)
    if not args[:schedules_filepaths].nil?
      hpxml_bldg.header.schedules_filepaths = args[:schedules_filepaths].split(',').map(&:strip)
    end
    hpxml_bldg.header.heat_pump_sizing_methodology = args[:heat_pump_sizing_methodology]
    hpxml_bldg.header.heat_pump_backup_sizing_methodology = args[:heat_pump_backup_sizing_methodology]
    hpxml_bldg.header.natvent_days_per_week = args[:window_natvent_availability]

    if not args[:window_shading_summer_season].nil?
      begin_month, begin_day, _begin_hour, end_month, end_day, _end_hour = Calendar.parse_date_time_range(args[:window_shading_summer_season])
      hpxml_bldg.header.shading_summer_begin_month = begin_month
      hpxml_bldg.header.shading_summer_begin_day = begin_day
      hpxml_bldg.header.shading_summer_end_month = end_month
      hpxml_bldg.header.shading_summer_end_day = end_day
    end

    if not args[:additional_properties].nil?
      extension_properties = {}
      args[:additional_properties].split('|').map(&:strip).each do |additional_property|
        key, value = additional_property.split('=').map(&:strip)
        extension_properties[key] = value
      end
      hpxml_bldg.header.extension_properties = extension_properties
    end
  end

  # Set climate and risk zones properties, including:
  # - 2006 IECC zone
  # - weather station name / EPW file path
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_climate_and_risk_zones(hpxml_bldg, args)
    if not args[:site_iecc_zone].nil?
      hpxml_bldg.climate_and_risk_zones.climate_zone_ieccs.add(zone: args[:site_iecc_zone],
                                                               year: 2006)
    end

    if not args[:weather_station_epw_filepath].nil?
      hpxml_bldg.climate_and_risk_zones.weather_station_id = 'WeatherStation'
      hpxml_bldg.climate_and_risk_zones.weather_station_name = File.basename(args[:weather_station_epw_filepath]).gsub('.epw', '')
      hpxml_bldg.climate_and_risk_zones.weather_station_epw_filepath = args[:weather_station_epw_filepath]
    end
  end

  # Set air infiltration measurements properties, including:
  # - infiltration type
  # - unit of measure
  # - leakage value
  # - presence of flue or chimney in conditioned space
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_air_infiltration_measurements(hpxml_bldg, args)
    if args[:air_leakage_value]
      if args[:air_leakage_units] == HPXML::UnitsELA
        effective_leakage_area = args[:air_leakage_value]
      else
        unit_of_measure = args[:air_leakage_units]
        air_leakage = args[:air_leakage_value]
        if [HPXML::UnitsACH, HPXML::UnitsCFM].include? args[:air_leakage_units]
          house_pressure = args[:air_leakage_house_pressure]
        end
      end
    else
      leakiness_description = args[:air_leakage_leakiness_description]
    end
    if not args[:air_leakage_type].nil?
      if [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include? args[:geometry_unit_type]
        air_leakage_type = args[:air_leakage_type]
      end
    end
    infiltration_volume = hpxml_bldg.building_construction.conditioned_building_volume

    hpxml_bldg.air_infiltration_measurements.add(id: "AirInfiltrationMeasurement#{hpxml_bldg.air_infiltration_measurements.size + 1}",
                                                 house_pressure: house_pressure,
                                                 unit_of_measure: unit_of_measure,
                                                 air_leakage: air_leakage,
                                                 effective_leakage_area: effective_leakage_area,
                                                 infiltration_volume: infiltration_volume,
                                                 infiltration_type: air_leakage_type,
                                                 leakiness_description: leakiness_description)

    hpxml_bldg.air_infiltration.has_flue_or_chimney_in_conditioned_space = args[:air_leakage_has_flue_or_chimney_in_conditioned_space]
  end

  # Set roofs properties, including:
  # - adjacent space
  # - orientation
  # - gross area
  # - material type and color
  # - pitch
  # - assembly R-value
  # - presence and grade of radiant barrier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @param sorted_surfaces [Array<OpenStudio::Model::Surface>] surfaces sorted by deterministically assigned Index
  # @return [nil]
  def self.set_roofs(hpxml_bldg, args, sorted_surfaces)
    args[:geometry_roof_pitch] *= 12.0
    if (args[:geometry_attic_type] == HPXML::AtticTypeFlatRoof) || (args[:geometry_attic_type] == HPXML::AtticTypeBelowApartment)
      args[:geometry_roof_pitch] = 0.0
    end

    sorted_surfaces.each do |surface|
      next if surface.outsideBoundaryCondition != EPlus::BoundaryConditionOutdoors
      next if surface.surfaceType != EPlus::SurfaceTypeRoofCeiling

      interior_adjacent_to = Geometry.get_adjacent_to(surface: surface)
      next if [HPXML::LocationOtherHousingUnit].include? interior_adjacent_to

      if args[:geometry_attic_type] == HPXML::AtticTypeFlatRoof
        azimuth = nil
      else
        azimuth = Geometry.get_surface_azimuth(surface: surface, orientation: args[:geometry_unit_orientation])
      end

      hpxml_bldg.roofs.add(id: "Roof#{hpxml_bldg.roofs.size + 1}",
                           interior_adjacent_to: Geometry.get_adjacent_to(surface: surface),
                           azimuth: azimuth,
                           area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2'),
                           roof_type: args[:roof_material_type],
                           roof_color: args[:roof_color],
                           pitch: args[:geometry_roof_pitch],
                           insulation_assembly_r_value: args[:roof_assembly_r])
      @surface_ids[surface.name.to_s] = hpxml_bldg.roofs[-1].id

      next unless [HPXML::RadiantBarrierLocationAtticRoofOnly, HPXML::RadiantBarrierLocationAtticRoofAndGableWalls].include?(args[:radiant_barrier_attic_location].to_s)
      next unless [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(hpxml_bldg.roofs[-1].interior_adjacent_to)

      hpxml_bldg.roofs[-1].radiant_barrier = true
      hpxml_bldg.roofs[-1].radiant_barrier_grade = args[:radiant_barrier_grade]
    end
  end

  # Set rim joists properties, including:
  # - adjacent spaces
  # - orientation
  # - gross area
  # - siding type and color
  # - assembly R-value
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param args [Hash] Map of :argument_name => value
  # @param sorted_surfaces [Array<OpenStudio::Model::Surface>] surfaces sorted by deterministically assigned Index
  # @return [nil]
  def self.set_rim_joists(hpxml_bldg, model, args, sorted_surfaces)
    sorted_surfaces.each do |surface|
      next if surface.surfaceType != EPlus::SurfaceTypeWall
      next unless [EPlus::BoundaryConditionOutdoors, EPlus::BoundaryConditionAdiabatic].include? surface.outsideBoundaryCondition
      next unless Geometry.surface_is_rim_joist(surface: surface, height: args[:geometry_rim_joist_height])

      interior_adjacent_to = Geometry.get_adjacent_to(surface: surface)
      next unless [HPXML::LocationBasementConditioned,
                   HPXML::LocationBasementUnconditioned,
                   HPXML::LocationCrawlspaceUnvented,
                   HPXML::LocationCrawlspaceVented,
                   HPXML::LocationCrawlspaceConditioned].include? interior_adjacent_to

      exterior_adjacent_to = HPXML::LocationOutside
      if surface.outsideBoundaryCondition == EPlus::BoundaryConditionAdiabatic # can be adjacent to foundation space
        adjacent_surface = Geometry.get_adiabatic_adjacent_surface(model: model, surface: surface)
        if adjacent_surface.nil? # adjacent to a space that is not explicitly in the model
          unless [HPXML::ResidentialTypeSFD].include?(args[:geometry_unit_type])
            exterior_adjacent_to = interior_adjacent_to
            if exterior_adjacent_to == HPXML::LocationConditionedSpace # conditioned space adjacent to conditioned space
              exterior_adjacent_to = HPXML::LocationOtherHousingUnit
            end
          end
        else # adjacent to a space that is explicitly in the model
          exterior_adjacent_to = Geometry.get_adjacent_to(surface: adjacent_surface)
        end
      end

      if exterior_adjacent_to == HPXML::LocationOutside
        siding = args[:wall_siding_type]
      end

      if interior_adjacent_to == exterior_adjacent_to
        insulation_assembly_r_value = 4.0 # Uninsulated
      else
        insulation_assembly_r_value = args[:rim_joist_assembly_r]
      end

      azimuth = Geometry.get_surface_azimuth(surface: surface, orientation: args[:geometry_unit_orientation])

      hpxml_bldg.rim_joists.add(id: "RimJoist#{hpxml_bldg.rim_joists.size + 1}",
                                exterior_adjacent_to: exterior_adjacent_to,
                                interior_adjacent_to: interior_adjacent_to,
                                azimuth: azimuth,
                                area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2'),
                                siding: siding,
                                color: args[:wall_color],
                                insulation_assembly_r_value: insulation_assembly_r_value)
      @surface_ids[surface.name.to_s] = hpxml_bldg.rim_joists[-1].id
    end
  end

  # Set walls properties, including:
  # - adjacent spaces
  # - orientation
  # - assembly type and R-value
  # - presence and grade of attic wall radiant barrier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param args [Hash] Map of :argument_name => value
  # @param sorted_surfaces [Array<OpenStudio::Model::Surface>] surfaces sorted by deterministically assigned Index
  # @return [nil]
  def self.set_walls(hpxml_bldg, model, args, sorted_surfaces)
    sorted_surfaces.each do |surface|
      next if surface.surfaceType != EPlus::SurfaceTypeWall
      next if Geometry.surface_is_rim_joist(surface: surface, height: args[:geometry_rim_joist_height])

      interior_adjacent_to = Geometry.get_adjacent_to(surface: surface)
      next unless [HPXML::LocationConditionedSpace, HPXML::LocationAtticUnvented, HPXML::LocationAtticVented, HPXML::LocationGarage].include? interior_adjacent_to

      exterior_adjacent_to = HPXML::LocationOutside
      if surface.adjacentSurface.is_initialized
        exterior_adjacent_to = Geometry.get_adjacent_to(surface: surface.adjacentSurface.get)
      elsif surface.outsideBoundaryCondition == EPlus::BoundaryConditionAdiabatic # can be adjacent to conditioned space, attic
        adjacent_surface = Geometry.get_adiabatic_adjacent_surface(model: model, surface: surface)
        if adjacent_surface.nil? # adjacent to a space that is not explicitly in the model
          exterior_adjacent_to = interior_adjacent_to
          if exterior_adjacent_to == HPXML::LocationConditionedSpace # conditioned space adjacent to conditioned space
            exterior_adjacent_to = HPXML::LocationOtherHousingUnit
          end
        else # adjacent to a space that is explicitly in the model
          exterior_adjacent_to = Geometry.get_adjacent_to(surface: adjacent_surface)
        end
      end

      next if exterior_adjacent_to == HPXML::LocationConditionedSpace # already captured these surfaces

      attic_locations = [HPXML::LocationAtticUnconditioned, HPXML::LocationAtticUnvented, HPXML::LocationAtticVented]
      attic_wall_type = nil
      if (attic_locations.include? interior_adjacent_to) && (exterior_adjacent_to == HPXML::LocationOutside)
        attic_wall_type = HPXML::AtticWallTypeGable
      end

      wall_type = args[:wall_type]
      if attic_locations.include? interior_adjacent_to
        wall_type = HPXML::WallTypeWoodStud
      end

      if exterior_adjacent_to == HPXML::LocationOutside && (not args[:wall_siding_type].nil?)
        if (attic_locations.include? interior_adjacent_to) && (args[:wall_siding_type] == HPXML::SidingTypeNone)
          siding = nil
        else
          siding = args[:wall_siding_type]
        end
      end

      azimuth = Geometry.get_surface_azimuth(surface: surface, orientation: args[:geometry_unit_orientation])

      hpxml_bldg.walls.add(id: "Wall#{hpxml_bldg.walls.size + 1}",
                           exterior_adjacent_to: exterior_adjacent_to,
                           interior_adjacent_to: interior_adjacent_to,
                           azimuth: azimuth,
                           wall_type: wall_type,
                           attic_wall_type: attic_wall_type,
                           siding: siding,
                           color: args[:wall_color],
                           area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2'))
      @surface_ids[surface.name.to_s] = hpxml_bldg.walls[-1].id

      is_uncond_attic_roof_insulated = false
      if attic_locations.include? interior_adjacent_to
        hpxml_bldg.roofs.each do |roof|
          next unless (roof.interior_adjacent_to == interior_adjacent_to) && (roof.insulation_assembly_r_value > 4.0)

          is_uncond_attic_roof_insulated = true
        end
      end

      if hpxml_bldg.walls[-1].is_thermal_boundary || is_uncond_attic_roof_insulated # Assume wall is insulated if roof is insulated
        hpxml_bldg.walls[-1].insulation_assembly_r_value = args[:wall_assembly_r]
      else
        hpxml_bldg.walls[-1].insulation_assembly_r_value = 4.0 # Uninsulated
      end

      next unless hpxml_bldg.walls[-1].attic_wall_type == HPXML::AtticWallTypeGable && args[:radiant_barrier_attic_location].to_s == HPXML::RadiantBarrierLocationAtticRoofAndGableWalls
      next unless [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(hpxml_bldg.walls[-1].interior_adjacent_to)

      hpxml_bldg.walls[-1].radiant_barrier = true
      hpxml_bldg.walls[-1].radiant_barrier_grade = args[:radiant_barrier_grade]
    end
  end

  # Set foundation walls properties, including:
  # - adjacent spaces
  # - orientation
  # - gross area
  # - height above and below grade
  # - thickness
  # - assembly type and R-value
  # - other insulation
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param args [Hash] Map of :argument_name => value
  # @param sorted_surfaces [Array<OpenStudio::Model::Surface>] surfaces sorted by deterministically assigned Index
  # @return [nil]
  def self.set_foundation_walls(hpxml_bldg, model, args, sorted_surfaces)
    sorted_surfaces.each do |surface|
      next if surface.surfaceType != EPlus::SurfaceTypeWall
      next unless [EPlus::BoundaryConditionFoundation, EPlus::BoundaryConditionAdiabatic].include? surface.outsideBoundaryCondition
      next if Geometry.surface_is_rim_joist(surface: surface, height: args[:geometry_rim_joist_height])

      interior_adjacent_to = Geometry.get_adjacent_to(surface: surface)
      next unless [HPXML::LocationBasementConditioned,
                   HPXML::LocationBasementUnconditioned,
                   HPXML::LocationCrawlspaceUnvented,
                   HPXML::LocationCrawlspaceVented,
                   HPXML::LocationCrawlspaceConditioned].include? interior_adjacent_to

      exterior_adjacent_to = HPXML::LocationGround
      if surface.outsideBoundaryCondition == EPlus::BoundaryConditionAdiabatic # can be adjacent to foundation space
        adjacent_surface = Geometry.get_adiabatic_adjacent_surface(model: model, surface: surface)
        if adjacent_surface.nil? # adjacent to a space that is not explicitly in the model
          unless [HPXML::ResidentialTypeSFD].include?(args[:geometry_unit_type])
            exterior_adjacent_to = interior_adjacent_to
            if exterior_adjacent_to == HPXML::LocationConditionedSpace # conditioned space adjacent to conditioned space
              exterior_adjacent_to = HPXML::LocationOtherHousingUnit
            end
          end
        else # adjacent to a space that is explicitly in the model
          exterior_adjacent_to = Geometry.get_adjacent_to(surface: adjacent_surface)
        end
      end

      foundation_wall_insulation_location = Constants::LocationExterior # default
      if not args[:foundation_wall_insulation_location].nil?
        foundation_wall_insulation_location = args[:foundation_wall_insulation_location]
      end

      if args[:foundation_wall_assembly_r].to_f > 0
        insulation_assembly_r_value = args[:foundation_wall_assembly_r]
      else
        insulation_interior_r_value = 0
        insulation_exterior_r_value = 0
        if interior_adjacent_to == exterior_adjacent_to # E.g., don't insulate wall between basement and neighbor basement
          # nop
        elsif foundation_wall_insulation_location == Constants::LocationInterior
          insulation_interior_r_value = args[:foundation_wall_insulation_r]
          if insulation_interior_r_value > 0
            insulation_interior_distance_to_top = args[:foundation_wall_insulation_distance_to_top]
            insulation_interior_distance_to_bottom = args[:foundation_wall_insulation_distance_to_bottom]
          end
        elsif foundation_wall_insulation_location == Constants::LocationExterior
          insulation_exterior_r_value = args[:foundation_wall_insulation_r]
          if insulation_exterior_r_value > 0
            insulation_exterior_distance_to_top = args[:foundation_wall_insulation_distance_to_top]
            insulation_exterior_distance_to_bottom = args[:foundation_wall_insulation_distance_to_bottom]
          end
        end
      end

      azimuth = Geometry.get_surface_azimuth(surface: surface, orientation: args[:geometry_unit_orientation])

      hpxml_bldg.foundation_walls.add(id: "FoundationWall#{hpxml_bldg.foundation_walls.size + 1}",
                                      exterior_adjacent_to: exterior_adjacent_to,
                                      interior_adjacent_to: interior_adjacent_to,
                                      type: args[:foundation_wall_type],
                                      azimuth: azimuth,
                                      height: args[:geometry_foundation_height],
                                      area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2'),
                                      thickness: args[:foundation_wall_thickness],
                                      depth_below_grade: args[:geometry_foundation_height] - args[:geometry_foundation_height_above_grade],
                                      insulation_assembly_r_value: insulation_assembly_r_value,
                                      insulation_interior_r_value: insulation_interior_r_value,
                                      insulation_interior_distance_to_top: insulation_interior_distance_to_top,
                                      insulation_interior_distance_to_bottom: insulation_interior_distance_to_bottom,
                                      insulation_exterior_r_value: insulation_exterior_r_value,
                                      insulation_exterior_distance_to_top: insulation_exterior_distance_to_top,
                                      insulation_exterior_distance_to_bottom: insulation_exterior_distance_to_bottom)
      @surface_ids[surface.name.to_s] = hpxml_bldg.foundation_walls[-1].id
    end
  end

  # Set the floors properties, including:
  # - adjacent spaces
  # - gross area
  # - assembly type and R-value
  # - presence and grade of attic floor radiant barrier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @param sorted_surfaces [Array<OpenStudio::Model::Surface>] surfaces sorted by deterministically assigned Index
  # @return [nil]
  def self.set_floors(hpxml_bldg, args, sorted_surfaces)
    if [HPXML::FoundationTypeBasementConditioned,
        HPXML::FoundationTypeCrawlspaceConditioned].include?(args[:geometry_foundation_type]) && (args[:floor_over_foundation_assembly_r] > 2.1)
      args[:floor_over_foundation_assembly_r] = 2.1 # Uninsulated
    end

    if [HPXML::AtticTypeConditioned].include?(args[:geometry_attic_type]) && (args[:ceiling_assembly_r] > 2.1)
      args[:ceiling_assembly_r] = 2.1 # Uninsulated
    end

    sorted_surfaces.each do |surface|
      next if surface.outsideBoundaryCondition == EPlus::BoundaryConditionFoundation
      next unless [EPlus::SurfaceTypeFloor, EPlus::SurfaceTypeRoofCeiling].include? surface.surfaceType

      interior_adjacent_to = Geometry.get_adjacent_to(surface: surface)
      next unless [HPXML::LocationConditionedSpace, HPXML::LocationGarage].include? interior_adjacent_to

      exterior_adjacent_to = HPXML::LocationOutside
      if surface.adjacentSurface.is_initialized
        exterior_adjacent_to = Geometry.get_adjacent_to(surface: surface.adjacentSurface.get)
      elsif surface.outsideBoundaryCondition == EPlus::BoundaryConditionAdiabatic
        exterior_adjacent_to = HPXML::LocationOtherHousingUnit
        if surface.surfaceType == EPlus::SurfaceTypeFloor
          floor_or_ceiling = HPXML::FloorOrCeilingFloor
        elsif surface.surfaceType == EPlus::SurfaceTypeRoofCeiling
          floor_or_ceiling = HPXML::FloorOrCeilingCeiling
        end
      end

      next if interior_adjacent_to == exterior_adjacent_to
      next if (surface.surfaceType == EPlus::SurfaceTypeRoofCeiling) && (exterior_adjacent_to == HPXML::LocationOutside)
      next if [HPXML::LocationConditionedSpace,
               HPXML::LocationBasementConditioned,
               HPXML::LocationCrawlspaceConditioned].include? exterior_adjacent_to

      hpxml_bldg.floors.add(id: "Floor#{hpxml_bldg.floors.size + 1}",
                            exterior_adjacent_to: exterior_adjacent_to,
                            interior_adjacent_to: interior_adjacent_to,
                            floor_type: args[:floor_type],
                            area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2'),
                            floor_or_ceiling: floor_or_ceiling)
      if hpxml_bldg.floors[-1].floor_or_ceiling.nil?
        if hpxml_bldg.floors[-1].is_floor
          hpxml_bldg.floors[-1].floor_or_ceiling = HPXML::FloorOrCeilingFloor
        elsif hpxml_bldg.floors[-1].is_ceiling
          hpxml_bldg.floors[-1].floor_or_ceiling = HPXML::FloorOrCeilingCeiling
        end
      end
      @surface_ids[surface.name.to_s] = hpxml_bldg.floors[-1].id

      if hpxml_bldg.floors[-1].is_thermal_boundary
        if [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include? exterior_adjacent_to
          hpxml_bldg.floors[-1].insulation_assembly_r_value = args[:ceiling_assembly_r]
        elsif [HPXML::LocationGarage].include? exterior_adjacent_to
          hpxml_bldg.floors[-1].insulation_assembly_r_value = args[:floor_over_garage_assembly_r]
        else
          hpxml_bldg.floors[-1].insulation_assembly_r_value = args[:floor_over_foundation_assembly_r]
        end
      else
        hpxml_bldg.floors[-1].insulation_assembly_r_value = 2.1 # Uninsulated
      end

      next unless args[:radiant_barrier_attic_location].to_s == HPXML::RadiantBarrierLocationAtticFloor
      next unless [HPXML::LocationAtticUnvented, HPXML::LocationAtticVented].include?(hpxml_bldg.floors[-1].exterior_adjacent_to) && hpxml_bldg.floors[-1].interior_adjacent_to == HPXML::LocationConditionedSpace

      hpxml_bldg.floors[-1].radiant_barrier = true
      hpxml_bldg.floors[-1].radiant_barrier_grade = args[:radiant_barrier_grade]
    end
  end

  # Set the slabs properties, including:
  # - adjacent space
  # - gross area
  # - thickness
  # - exposed perimeter
  # - perimeter or under-slab insulation dimensions and R-value
  # - carpet fraction and R-value
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param args [Hash] Map of :argument_name => value
  # @param sorted_surfaces [Array<OpenStudio::Model::Surface>] surfaces sorted by deterministically assigned Index
  # @return [nil]
  def self.set_slabs(hpxml_bldg, model, args, sorted_surfaces)
    sorted_surfaces.each do |surface|
      next unless [EPlus::BoundaryConditionFoundation].include? surface.outsideBoundaryCondition
      next if surface.surfaceType != EPlus::SurfaceTypeFloor

      interior_adjacent_to = Geometry.get_adjacent_to(surface: surface)
      next if [HPXML::LocationOutside, HPXML::LocationOtherHousingUnit].include? interior_adjacent_to

      has_foundation_walls = false
      if [HPXML::LocationCrawlspaceVented,
          HPXML::LocationCrawlspaceUnvented,
          HPXML::LocationCrawlspaceConditioned,
          HPXML::LocationBasementUnconditioned,
          HPXML::LocationBasementConditioned].include? interior_adjacent_to
        has_foundation_walls = true
      end
      exposed_perimeter = Geometry.calculate_exposed_perimeter(model: model, ground_floor_surfaces: [surface], has_foundation_walls: has_foundation_walls).round(1)
      next if exposed_perimeter == 0

      if [HPXML::LocationCrawlspaceVented,
          HPXML::LocationCrawlspaceUnvented,
          HPXML::LocationCrawlspaceConditioned,
          HPXML::LocationBasementUnconditioned,
          HPXML::LocationBasementConditioned].include? interior_adjacent_to
        exposed_perimeter -= Geometry.get_unexposed_garage_perimeter(**args)
      end

      if args[:slab_under_insulation_width] >= 999
        under_slab_insulation_spans_entire_slab = true
      else
        under_slab_insulation_width = args[:slab_under_insulation_width]
      end

      hpxml_bldg.slabs.add(id: "Slab#{hpxml_bldg.slabs.size + 1}",
                           interior_adjacent_to: interior_adjacent_to,
                           area: UnitConversions.convert(surface.grossArea, 'm^2', 'ft^2'),
                           thickness: args[:slab_thickness],
                           exposed_perimeter: exposed_perimeter,
                           perimeter_insulation_r_value: args[:slab_perimeter_insulation_r],
                           perimeter_insulation_depth: args[:slab_perimeter_insulation_depth],
                           exterior_horizontal_insulation_r_value: args[:slab_exterior_horizontal_insulation_r],
                           exterior_horizontal_insulation_width: args[:slab_exterior_horizontal_insulation_width],
                           exterior_horizontal_insulation_depth_below_grade: args[:slab_exterior_horizontal_insulation_depth_below_grade],
                           under_slab_insulation_width: under_slab_insulation_width,
                           under_slab_insulation_r_value: args[:slab_under_insulation_r],
                           under_slab_insulation_spans_entire_slab: under_slab_insulation_spans_entire_slab,
                           carpet_fraction: args[:slab_carpet_fraction],
                           carpet_r_value: args[:slab_carpet_r])
      @surface_ids[surface.name.to_s] = hpxml_bldg.slabs[-1].id

      next unless interior_adjacent_to == HPXML::LocationCrawlspaceConditioned

      # Increase Conditioned Building Volume & Infiltration Volume
      conditioned_crawlspace_volume = hpxml_bldg.slabs[-1].area * args[:geometry_foundation_height]
      hpxml_bldg.building_construction.conditioned_building_volume += conditioned_crawlspace_volume
      hpxml_bldg.air_infiltration_measurements[0].infiltration_volume += conditioned_crawlspace_volume
    end
  end

  # Set the windows properties, including:
  # - gross area
  # - orientation
  # - U-Factor and SHGC
  # - storm type
  # - winter and summer interior and exterior shading fractions
  # - operable fraction
  # - overhangs location and depth
  # - attached walls
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param args [Hash] Map of :argument_name => value
  # @param sorted_subsurfaces [Array<OpenStudio::Model::SubSurface>] subsurfaces sorted by deterministically assigned Index
  # @return [nil]
  def self.set_windows(hpxml_bldg, model, args, sorted_subsurfaces)
    sorted_subsurfaces.each do |sub_surface|
      next if sub_surface.subSurfaceType != EPlus::SubSurfaceTypeWindow

      surface = sub_surface.surface.get

      sub_surface_height = Geometry.get_surface_height(surface: sub_surface)
      sub_surface_facade = Geometry.get_facade_for_surface(surface: sub_surface)

      if (sub_surface_facade == Constants::FacadeFront) && (args[:overhangs_front_depth] > 0)
        overhangs_depth = args[:overhangs_front_depth]
        overhangs_distance_to_top_of_window = args[:overhangs_front_distance_to_top_of_window]
        overhangs_distance_to_bottom_of_window = args[:overhangs_front_distance_to_bottom_of_window]
      elsif (sub_surface_facade == Constants::FacadeBack) && (args[:overhangs_back_depth] > 0)
        overhangs_depth = args[:overhangs_back_depth]
        overhangs_distance_to_top_of_window = args[:overhangs_back_distance_to_top_of_window]
        overhangs_distance_to_bottom_of_window = args[:overhangs_back_distance_to_bottom_of_window]
      elsif (sub_surface_facade == Constants::FacadeLeft) && (args[:overhangs_left_depth] > 0)
        overhangs_depth = args[:overhangs_left_depth]
        overhangs_distance_to_top_of_window = args[:overhangs_left_distance_to_top_of_window]
        overhangs_distance_to_bottom_of_window = args[:overhangs_left_distance_to_bottom_of_window]
      elsif (sub_surface_facade == Constants::FacadeRight) && (args[:overhangs_right_depth] > 0)
        overhangs_depth = args[:overhangs_right_depth]
        overhangs_distance_to_top_of_window = args[:overhangs_right_distance_to_top_of_window]
        overhangs_distance_to_bottom_of_window = args[:overhangs_right_distance_to_bottom_of_window]
      elsif args[:geometry_eaves_depth] > 0
        # Get max z coordinate of eaves
        eaves_z = args[:geometry_average_ceiling_height] * args[:geometry_unit_num_floors_above_grade] + args[:geometry_rim_joist_height]
        if args[:geometry_attic_type] == HPXML::AtticTypeConditioned
          eaves_z += Geometry.get_conditioned_attic_height(spaces: model.getSpaces)
        end
        if args[:geometry_foundation_type] == HPXML::FoundationTypeAmbient
          eaves_z += args[:geometry_foundation_height]
        end

        # Get max z coordinate of this window
        sub_surface_z = Geometry.get_surface_z_values(surfaceArray: [sub_surface]).max + UnitConversions.convert(sub_surface.space.get.zOrigin, 'm', 'ft')

        overhangs_depth = args[:geometry_eaves_depth]
        overhangs_distance_to_top_of_window = eaves_z - sub_surface_z # difference between max z coordinates of eaves and this window
        overhangs_distance_to_bottom_of_window = (overhangs_distance_to_top_of_window + sub_surface_height).round(1)
      end

      azimuth = Geometry.get_azimuth_from_facade(facade: sub_surface_facade, orientation: args[:geometry_unit_orientation])

      wall_idref = @surface_ids[surface.name.to_s]
      next if wall_idref.nil?

      insect_screen_present = ([HPXML::LocationExterior, HPXML::LocationInterior].include? args[:window_insect_screens])
      if insect_screen_present
        insect_screen_location = args[:window_insect_screens]
      end

      hpxml_bldg.windows.add(id: "Window#{hpxml_bldg.windows.size + 1}",
                             area: UnitConversions.convert(sub_surface.grossArea, 'm^2', 'ft^2'),
                             azimuth: azimuth,
                             ufactor: args[:window_ufactor],
                             shgc: args[:window_shgc],
                             storm_type: args[:window_storm_type],
                             overhangs_depth: overhangs_depth,
                             overhangs_distance_to_top_of_window: overhangs_distance_to_top_of_window,
                             overhangs_distance_to_bottom_of_window: overhangs_distance_to_bottom_of_window,
                             interior_shading_type: args[:window_interior_shading_type],
                             interior_shading_factor_winter: args[:window_interior_shading_winter],
                             interior_shading_factor_summer: args[:window_interior_shading_summer],
                             exterior_shading_type: args[:window_exterior_shading_type],
                             exterior_shading_factor_winter: args[:window_exterior_shading_winter],
                             exterior_shading_factor_summer: args[:window_exterior_shading_summer],
                             insect_screen_present: insect_screen_present,
                             insect_screen_location: insect_screen_location,
                             fraction_operable: args[:window_fraction_operable],
                             attached_to_wall_idref: wall_idref)
    end
  end

  # Set the skylights properties, including:
  # - gross area
  # - orientation
  # - U-Factor and SHGC
  # - storm type
  # - attached roofs
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @param sorted_subsurfaces [Array<OpenStudio::Model::SubSurface>] subsurfaces sorted by deterministically assigned Index
  # @return [nil]
  def self.set_skylights(hpxml_bldg, args, sorted_subsurfaces)
    sorted_subsurfaces.each do |sub_surface|
      next if sub_surface.subSurfaceType != 'Skylight'

      surface = sub_surface.surface.get

      sub_surface_facade = Geometry.get_facade_for_surface(surface: sub_surface)
      azimuth = Geometry.get_azimuth_from_facade(facade: sub_surface_facade, orientation: args[:geometry_unit_orientation])

      roof_idref = @surface_ids[surface.name.to_s]
      next if roof_idref.nil?

      roof = hpxml_bldg.roofs.find { |roof| roof.id == roof_idref }
      if roof.interior_adjacent_to != HPXML::LocationConditionedSpace
        # This is the roof of an attic, so the skylight must have a shaft; attach it to the attic floor as well.
        floor = hpxml_bldg.floors.find { |floor| floor.interior_adjacent_to == HPXML::LocationConditionedSpace && floor.exterior_adjacent_to == roof.interior_adjacent_to }
        floor_idref = floor.id
      end

      hpxml_bldg.skylights.add(id: "Skylight#{hpxml_bldg.skylights.size + 1}",
                               area: UnitConversions.convert(sub_surface.grossArea, 'm^2', 'ft^2'),
                               azimuth: azimuth,
                               ufactor: args[:skylight_ufactor],
                               shgc: args[:skylight_shgc],
                               storm_type: args[:skylight_storm_type],
                               attached_to_roof_idref: roof_idref,
                               attached_to_floor_idref: floor_idref)
    end
  end

  # Set the doors properties, including:
  # - gross area
  # - orientation
  # - R-value
  # - attached walls
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param args [Hash] Map of :argument_name => value
  # @param sorted_subsurfaces [Array<OpenStudio::Model::SubSurface>] subsurfaces sorted by deterministically assigned Index
  # @return [nil]
  def self.set_doors(hpxml_bldg, model, args, sorted_subsurfaces)
    sorted_subsurfaces.each do |sub_surface|
      next if sub_surface.subSurfaceType != EPlus::SubSurfaceTypeDoor

      surface = sub_surface.surface.get

      interior_adjacent_to = Geometry.get_adjacent_to(surface: surface)

      if [HPXML::LocationOtherHousingUnit].include?(interior_adjacent_to)
        adjacent_surface = Geometry.get_adiabatic_adjacent_surface(model: model, surface: surface)
        next if adjacent_surface.nil?
      end

      wall_idref = @surface_ids[surface.name.to_s]
      next if wall_idref.nil?

      hpxml_bldg.doors.add(id: "Door#{hpxml_bldg.doors.size + 1}",
                           attached_to_wall_idref: wall_idref,
                           area: UnitConversions.convert(sub_surface.grossArea, 'm^2', 'ft^2'),
                           azimuth: args[:geometry_unit_orientation],
                           r_value: args[:door_rvalue])
    end
  end

  # Set the attics properties, including:
  # - type
  # - attached roofs, walls, and floors
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_attics(hpxml_bldg, args)
    surf_ids = { 'roofs' => { 'surfaces' => hpxml_bldg.roofs, 'ids' => [] },
                 'walls' => { 'surfaces' => hpxml_bldg.walls, 'ids' => [] },
                 'floors' => { 'surfaces' => hpxml_bldg.floors, 'ids' => [] } }

    attic_locations = [HPXML::LocationAtticUnconditioned, HPXML::LocationAtticUnvented, HPXML::LocationAtticVented]
    surf_ids.values.each do |surf_hash|
      surf_hash['surfaces'].each do |surface|
        next if (not attic_locations.include? surface.interior_adjacent_to) &&
                (not attic_locations.include? surface.exterior_adjacent_to)

        surf_hash['ids'] << surface.id
      end
    end

    # Add attached roofs for cathedral ceiling
    conditioned_space = HPXML::LocationConditionedSpace
    surf_ids['roofs']['surfaces'].each do |surface|
      next if (conditioned_space != surface.interior_adjacent_to) &&
              (conditioned_space != surface.exterior_adjacent_to)

      surf_ids['roofs']['ids'] << surface.id
    end

    hpxml_bldg.attics.add(id: "Attic#{hpxml_bldg.attics.size + 1}",
                          attic_type: args[:geometry_attic_type],
                          attached_to_roof_idrefs: surf_ids['roofs']['ids'],
                          attached_to_wall_idrefs: surf_ids['walls']['ids'],
                          attached_to_floor_idrefs: surf_ids['floors']['ids'])
  end

  # Set the foundations properties, including:
  # - type
  # - attached slabs, floors, foundation walls, walls, and rim joists
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_foundations(hpxml_bldg, args)
    surf_ids = { 'slabs' => { 'surfaces' => hpxml_bldg.slabs, 'ids' => [] },
                 'floors' => { 'surfaces' => hpxml_bldg.floors, 'ids' => [] },
                 'foundation_walls' => { 'surfaces' => hpxml_bldg.foundation_walls, 'ids' => [] },
                 'walls' => { 'surfaces' => hpxml_bldg.walls, 'ids' => [] },
                 'rim_joists' => { 'surfaces' => hpxml_bldg.rim_joists, 'ids' => [] }, }

    foundation_locations = [HPXML::LocationBasementConditioned,
                            HPXML::LocationBasementUnconditioned,
                            HPXML::LocationCrawlspaceUnvented,
                            HPXML::LocationCrawlspaceVented,
                            HPXML::LocationCrawlspaceConditioned]

    surf_ids.each do |surf_type, surf_hash|
      surf_hash['surfaces'].each do |surface|
        next unless (foundation_locations.include? surface.interior_adjacent_to) ||
                    (foundation_locations.include? surface.exterior_adjacent_to) ||
                    (surf_type == 'slabs' && surface.interior_adjacent_to == HPXML::LocationConditionedSpace) ||
                    (surf_type == 'floors' && [HPXML::LocationOutside, HPXML::LocationManufacturedHomeUnderBelly].include?(surface.exterior_adjacent_to))

        surf_hash['ids'] << surface.id
      end
    end

    if args[:geometry_foundation_type].start_with?(HPXML::FoundationTypeBellyAndWing)
      foundation_type = HPXML::FoundationTypeBellyAndWing
      if args[:geometry_foundation_type].end_with?('WithSkirt')
        belly_wing_skirt_present = true
      elsif args[:geometry_foundation_type].end_with?('NoSkirt')
        belly_wing_skirt_present = false
      else
        fail 'Unepected belly and wing foundation type.'
      end
    else
      foundation_type = args[:geometry_foundation_type]
    end

    hpxml_bldg.foundations.add(id: "Foundation#{hpxml_bldg.foundations.size + 1}",
                               foundation_type: foundation_type,
                               attached_to_slab_idrefs: surf_ids['slabs']['ids'],
                               attached_to_floor_idrefs: surf_ids['floors']['ids'],
                               attached_to_foundation_wall_idrefs: surf_ids['foundation_walls']['ids'],
                               attached_to_wall_idrefs: surf_ids['walls']['ids'],
                               attached_to_rim_joist_idrefs: surf_ids['rim_joists']['ids'],
                               belly_wing_skirt_present: belly_wing_skirt_present)
  end

  # Set the primary heating systems properties, including:
  # - type
  # - fuel
  # - capacity
  # - efficiency
  # - heat load served
  # - presence and burn rate of pilot light
  # - number of dwelling units served
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_heating_systems(hpxml_bldg, args)
    heating_system_type = args[:heating_system_type]

    return if heating_system_type == Constants::None

    if [HPXML::HVACTypeElectricResistance].include? heating_system_type
      args[:heating_system_fuel] = HPXML::FuelTypeElectricity
    end

    if [HPXML::HVACTypeFurnace,
        HPXML::HVACTypeWallFurnace,
        HPXML::HVACTypeFloorFurnace].include?(heating_system_type) || heating_system_type.include?(HPXML::HVACTypeBoiler)
      heating_efficiency_afue = args[:heating_system_heating_efficiency]
    elsif [HPXML::HVACTypeElectricResistance,
           HPXML::HVACTypeStove,
           HPXML::HVACTypeSpaceHeater,
           HPXML::HVACTypeFireplace].include?(heating_system_type)
      heating_efficiency_percent = args[:heating_system_heating_efficiency]
    end

    if [HPXML::HVACTypeFurnace].include? heating_system_type
      airflow_defect_ratio = args[:heating_system_airflow_defect_ratio]
    end

    if args[:heating_system_fuel] != HPXML::FuelTypeElectricity
      pilot_light_btuh = args[:heating_system_pilot_light].to_f
      if pilot_light_btuh > 0
        pilot_light = true
      end
    end

    fraction_heat_load_served = args[:heating_system_fraction_heat_load_served]

    if heating_system_type.include?('Shared')
      is_shared_system = true
      number_of_units_served = args[:geometry_building_num_units]
      args[:heating_system_heating_capacity] = nil
    end

    if heating_system_type.include?(HPXML::HVACTypeBoiler)
      heating_system_type = HPXML::HVACTypeBoiler
    end

    hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                   heating_system_type: heating_system_type,
                                   heating_system_fuel: args[:heating_system_fuel],
                                   heating_capacity: args[:heating_system_heating_capacity],
                                   heating_autosizing_factor: args[:heating_system_heating_autosizing_factor],
                                   heating_autosizing_limit: args[:heating_system_heating_autosizing_limit],
                                   fraction_heat_load_served: fraction_heat_load_served,
                                   heating_efficiency_afue: heating_efficiency_afue,
                                   heating_efficiency_percent: heating_efficiency_percent,
                                   airflow_defect_ratio: airflow_defect_ratio,
                                   pilot_light: pilot_light,
                                   pilot_light_btuh: pilot_light_btuh,
                                   is_shared_system: is_shared_system,
                                   number_of_units_served: number_of_units_served,
                                   primary_system: true)
  end

  # Set the primary cooling systems properties, including:
  # - type
  # - fuel
  # - capacity
  # - efficiency
  # - cool load served
  # - compressor speeds
  # - crankcase heater power
  # - integrated heating system type, fuel, efficiency, and heat load served
  # - detailed performance data
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_cooling_systems(hpxml_bldg, args)
    cooling_system_type = args[:cooling_system_type]

    return if cooling_system_type == Constants::None

    if [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system_type
      compressor_type = args[:cooling_system_cooling_compressor_type]
    end

    if cooling_system_type != HPXML::HVACTypeEvaporativeCooler
      cooling_shr = args[:cooling_system_cooling_sensible_heat_fraction]
    end

    if cooling_system_type != HPXML::HVACTypeEvaporativeCooler
      if args[:cooling_system_cooling_efficiency_type] == HPXML::UnitsSEER
        cooling_efficiency_seer = args[:cooling_system_cooling_efficiency]
      elsif args[:cooling_system_cooling_efficiency_type] == HPXML::UnitsSEER2
        cooling_efficiency_seer2 = args[:cooling_system_cooling_efficiency]
      elsif args[:cooling_system_cooling_efficiency_type] == HPXML::UnitsEER
        cooling_efficiency_eer = args[:cooling_system_cooling_efficiency]
      elsif args[:cooling_system_cooling_efficiency_type] == HPXML::UnitsCEER
        cooling_efficiency_ceer = args[:cooling_system_cooling_efficiency]
      end
    end

    if [HPXML::HVACTypeCentralAirConditioner].include?(cooling_system_type) || ([HPXML::HVACTypeMiniSplitAirConditioner].include?(cooling_system_type) && (args[:cooling_system_is_ducted]))
      airflow_defect_ratio = args[:cooling_system_airflow_defect_ratio]
    end

    if [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeMiniSplitAirConditioner].include?(cooling_system_type)
      charge_defect_ratio = args[:cooling_system_charge_defect_ratio]
    end

    if [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeMiniSplitAirConditioner, HPXML::HVACTypeRoomAirConditioner, HPXML::HVACTypePTAC].include?(cooling_system_type)
      cooling_system_crankcase_heater_watts = args[:cooling_system_crankcase_heater_watts]
    end

    if [HPXML::HVACTypePTAC, HPXML::HVACTypeRoomAirConditioner].include?(cooling_system_type)
      integrated_heating_system_fuel = args[:cooling_system_integrated_heating_system_fuel]
      integrated_heating_system_fraction_heat_load_served = args[:cooling_system_integrated_heating_system_fraction_heat_load_served]
      integrated_heating_system_capacity = args[:cooling_system_integrated_heating_system_capacity]
      integrated_heating_system_efficiency_percent = args[:cooling_system_integrated_heating_system_efficiency_percent]
    end

    hpxml_bldg.cooling_systems.add(id: "CoolingSystem#{hpxml_bldg.cooling_systems.size + 1}",
                                   cooling_system_type: cooling_system_type,
                                   cooling_system_fuel: HPXML::FuelTypeElectricity,
                                   cooling_capacity: args[:cooling_system_cooling_capacity],
                                   cooling_autosizing_factor: args[:cooling_system_cooling_autosizing_factor],
                                   cooling_autosizing_limit: args[:cooling_system_cooling_autosizing_limit],
                                   fraction_cool_load_served: args[:cooling_system_fraction_cool_load_served],
                                   compressor_type: compressor_type,
                                   cooling_shr: cooling_shr,
                                   cooling_efficiency_seer: cooling_efficiency_seer,
                                   cooling_efficiency_seer2: cooling_efficiency_seer2,
                                   cooling_efficiency_eer: cooling_efficiency_eer,
                                   cooling_efficiency_ceer: cooling_efficiency_ceer,
                                   airflow_defect_ratio: airflow_defect_ratio,
                                   charge_defect_ratio: charge_defect_ratio,
                                   crankcase_heater_watts: cooling_system_crankcase_heater_watts,
                                   primary_system: true,
                                   integrated_heating_system_fuel: integrated_heating_system_fuel,
                                   integrated_heating_system_capacity: integrated_heating_system_capacity,
                                   integrated_heating_system_efficiency_percent: integrated_heating_system_efficiency_percent,
                                   integrated_heating_system_fraction_heat_load_served: integrated_heating_system_fraction_heat_load_served)

    if (not args[:hvac_perf_data_cooling_outdoor_temperatures].nil?) && [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeMiniSplitAirConditioner].include?(cooling_system_type) && compressor_type == HPXML::HVACCompressorTypeVariableSpeed
      hvac_perf_data_capacity_type = args[:hvac_perf_data_capacity_type]
      hvac_perf_data_cooling_outdoor_temperatures = args[:hvac_perf_data_cooling_outdoor_temperatures].split(',').map(&:strip)
      hvac_perf_data_cooling_min_speed_capacities = args[:hvac_perf_data_cooling_min_speed_capacities].split(',').map(&:strip)
      hvac_perf_data_cooling_max_speed_capacities = args[:hvac_perf_data_cooling_max_speed_capacities].split(',').map(&:strip)
      hvac_perf_data_cooling_min_speed_cops = args[:hvac_perf_data_cooling_min_speed_cops].split(',').map(&:strip)
      hvac_perf_data_cooling_max_speed_cops = args[:hvac_perf_data_cooling_max_speed_cops].split(',').map(&:strip)

      clg_perf_data = hpxml_bldg.cooling_systems[0].cooling_detailed_performance_data
      cooling_perf_data_data_points = hvac_perf_data_cooling_outdoor_temperatures.zip(hvac_perf_data_cooling_min_speed_capacities,
                                                                                      hvac_perf_data_cooling_max_speed_capacities,
                                                                                      hvac_perf_data_cooling_min_speed_cops,
                                                                                      hvac_perf_data_cooling_max_speed_cops)
      cooling_perf_data_data_points.each do |cooling_perf_data_data_point|
        outdoor_temperature, min_speed_cap_or_frac, max_speed_cap_or_frac, min_speed_cop, max_speed_cop = cooling_perf_data_data_point

        if hvac_perf_data_capacity_type == 'Absolute capacities'
          min_speed_capacity = Float(min_speed_cap_or_frac)
          max_speed_capacity = Float(max_speed_cap_or_frac)
        elsif hvac_perf_data_capacity_type == 'Normalized capacity fractions'
          min_speed_capacity_fraction_of_nominal = Float(min_speed_cap_or_frac)
          max_speed_capacity_fraction_of_nominal = Float(max_speed_cap_or_frac)
        end

        clg_perf_data.add(outdoor_temperature: Float(outdoor_temperature),
                          capacity: min_speed_capacity,
                          capacity_fraction_of_nominal: min_speed_capacity_fraction_of_nominal,
                          capacity_description: HPXML::CapacityDescriptionMinimum,
                          efficiency_cop: Float(min_speed_cop))
        clg_perf_data.add(outdoor_temperature: Float(outdoor_temperature),
                          capacity: max_speed_capacity,
                          capacity_fraction_of_nominal: max_speed_capacity_fraction_of_nominal,
                          capacity_description: HPXML::CapacityDescriptionMaximum,
                          efficiency_cop: Float(max_speed_cop))
      end
    end
  end

  # Set the primary heat pumps properties, including:
  # - type
  # - fuel
  # - heating and cooling capacities
  # - heating capacity retention fraction and temperature
  # - heating and cooling efficiencies
  # - heat and cool loads served
  # - compressor speeds and lockout temperature
  # - backup heating fuel, capacity, efficiency, and switchover/lockout temperatures
  # - crankcase heater power
  # - detailed performance data
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_heat_pumps(hpxml_bldg, args)
    heat_pump_type = args[:heat_pump_type]

    return if heat_pump_type == Constants::None

    if args[:heat_pump_backup_type] == HPXML::HeatPumpBackupTypeIntegrated
      backup_type = args[:heat_pump_backup_type]
      backup_heating_fuel = args[:heat_pump_backup_fuel]
      backup_heating_capacity = args[:heat_pump_backup_heating_capacity]

      if backup_heating_fuel == HPXML::FuelTypeElectricity
        backup_heating_efficiency_percent = args[:heat_pump_backup_heating_efficiency]
      else
        backup_heating_efficiency_afue = args[:heat_pump_backup_heating_efficiency]
      end
    elsif args[:heat_pump_backup_type] == HPXML::HeatPumpBackupTypeSeparate
      if args[:heating_system_2_type] == Constants::None
        fail "Heat pump backup type specified as '#{args[:heat_pump_backup_type]}' but no heating system provided."
      end

      backup_type = args[:heat_pump_backup_type]
      backup_system_idref = "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}"
    end

    if backup_heating_fuel != HPXML::FuelTypeElectricity
      if (not args[:heat_pump_compressor_lockout_temp].nil?) && (not args[:heat_pump_backup_heating_lockout_temp].nil?) && args[:heat_pump_compressor_lockout_temp] == args[:heat_pump_backup_heating_lockout_temp]
        # Translate to HPXML as switchover temperature instead
        backup_heating_switchover_temp = args[:heat_pump_compressor_lockout_temp]
        args[:heat_pump_compressor_lockout_temp] = nil
        args[:heat_pump_backup_heating_lockout_temp] = nil
      end
    end

    if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit].include? heat_pump_type
      compressor_type = args[:heat_pump_cooling_compressor_type]
    end

    if args[:heat_pump_heating_efficiency_type] == HPXML::UnitsHSPF
      heating_efficiency_hspf = args[:heat_pump_heating_efficiency]
    elsif args[:heat_pump_heating_efficiency_type] == HPXML::UnitsHSPF2
      heating_efficiency_hspf2 = args[:heat_pump_heating_efficiency]
    elsif args[:heat_pump_heating_efficiency_type] == HPXML::UnitsCOP
      heating_efficiency_cop = args[:heat_pump_heating_efficiency]
    end

    if args[:heat_pump_cooling_efficiency_type] == HPXML::UnitsSEER
      cooling_efficiency_seer = args[:heat_pump_cooling_efficiency]
    elsif args[:heat_pump_cooling_efficiency_type] == HPXML::UnitsSEER2
      cooling_efficiency_seer2 = args[:heat_pump_cooling_efficiency]
    elsif args[:heat_pump_cooling_efficiency_type] == HPXML::UnitsEER
      cooling_efficiency_eer = args[:heat_pump_cooling_efficiency]
    end

    if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpGroundToAir].include?(heat_pump_type) || ([HPXML::HVACTypeHeatPumpMiniSplit].include?(heat_pump_type) && (args[:heat_pump_is_ducted]))
      airflow_defect_ratio = args[:heat_pump_airflow_defect_ratio]
    end

    if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit, HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include?(heat_pump_type)
      heat_pump_crankcase_heater_watts = args[:heat_pump_crankcase_heater_watts]
    end

    hpxml_bldg.heat_pumps.add(id: "HeatPump#{hpxml_bldg.heat_pumps.size + 1}",
                              heat_pump_type: heat_pump_type,
                              heat_pump_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: args[:heat_pump_heating_capacity],
                              heating_autosizing_factor: args[:heat_pump_heating_autosizing_factor],
                              heating_autosizing_limit: args[:heat_pump_heating_autosizing_limit],
                              backup_heating_autosizing_factor: args[:heat_pump_backup_heating_autosizing_factor],
                              backup_heating_autosizing_limit: args[:heat_pump_backup_heating_autosizing_limit],
                              heating_capacity_retention_fraction: args[:heat_pump_heating_capacity_retention_fraction],
                              heating_capacity_retention_temp: args[:heat_pump_heating_capacity_retention_temp],
                              compressor_type: compressor_type,
                              compressor_lockout_temp: args[:heat_pump_compressor_lockout_temp],
                              cooling_shr: args[:heat_pump_cooling_sensible_heat_fraction],
                              cooling_capacity: args[:heat_pump_cooling_capacity],
                              cooling_autosizing_factor: args[:heat_pump_cooling_autosizing_factor],
                              cooling_autosizing_limit: args[:heat_pump_cooling_autosizing_limit],
                              fraction_heat_load_served: args[:heat_pump_fraction_heat_load_served],
                              fraction_cool_load_served: args[:heat_pump_fraction_cool_load_served],
                              backup_type: backup_type,
                              backup_system_idref: backup_system_idref,
                              backup_heating_fuel: backup_heating_fuel,
                              backup_heating_capacity: backup_heating_capacity,
                              backup_heating_efficiency_afue: backup_heating_efficiency_afue,
                              backup_heating_efficiency_percent: backup_heating_efficiency_percent,
                              backup_heating_switchover_temp: backup_heating_switchover_temp,
                              backup_heating_lockout_temp: args[:heat_pump_backup_heating_lockout_temp],
                              heating_efficiency_hspf: heating_efficiency_hspf,
                              heating_efficiency_hspf2: heating_efficiency_hspf2,
                              cooling_efficiency_seer: cooling_efficiency_seer,
                              cooling_efficiency_seer2: cooling_efficiency_seer2,
                              heating_efficiency_cop: heating_efficiency_cop,
                              cooling_efficiency_eer: cooling_efficiency_eer,
                              airflow_defect_ratio: airflow_defect_ratio,
                              charge_defect_ratio: args[:heat_pump_charge_defect_ratio],
                              crankcase_heater_watts: heat_pump_crankcase_heater_watts,
                              primary_heating_system: args[:heat_pump_fraction_heat_load_served] > 0,
                              primary_cooling_system: args[:heat_pump_fraction_cool_load_served] > 0)

    if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit].include?(heat_pump_type) && compressor_type == HPXML::HVACCompressorTypeVariableSpeed
      if not args[:hvac_perf_data_heating_outdoor_temperatures].nil?
        hvac_perf_data_capacity_type = args[:hvac_perf_data_capacity_type]
        hvac_perf_data_heating_outdoor_temperatures = args[:hvac_perf_data_heating_outdoor_temperatures].split(',').map(&:strip)
        hvac_perf_data_heating_min_speed_capacities = args[:hvac_perf_data_heating_min_speed_capacities].split(',').map(&:strip)
        hvac_perf_data_heating_max_speed_capacities = args[:hvac_perf_data_heating_max_speed_capacities].split(',').map(&:strip)
        hvac_perf_data_heating_min_speed_cops = args[:hvac_perf_data_heating_min_speed_cops].split(',').map(&:strip)
        hvac_perf_data_heating_max_speed_cops = args[:hvac_perf_data_heating_max_speed_cops].split(',').map(&:strip)

        htg_perf_data = hpxml_bldg.heat_pumps[0].heating_detailed_performance_data
        heating_perf_data_data_points = hvac_perf_data_heating_outdoor_temperatures.zip(hvac_perf_data_heating_min_speed_capacities,
                                                                                        hvac_perf_data_heating_max_speed_capacities,
                                                                                        hvac_perf_data_heating_min_speed_cops,
                                                                                        hvac_perf_data_heating_max_speed_cops)
        heating_perf_data_data_points.each do |heating_perf_data_data_point|
          outdoor_temperature, min_speed_cap_or_frac, max_speed_cap_or_frac, min_speed_cop, max_speed_cop = heating_perf_data_data_point

          if hvac_perf_data_capacity_type == 'Absolute capacities'
            min_speed_capacity = Float(min_speed_cap_or_frac)
            max_speed_capacity = Float(max_speed_cap_or_frac)
          elsif hvac_perf_data_capacity_type == 'Normalized capacity fractions'
            min_speed_capacity_fraction_of_nominal = Float(min_speed_cap_or_frac)
            max_speed_capacity_fraction_of_nominal = Float(max_speed_cap_or_frac)
          end

          htg_perf_data.add(outdoor_temperature: Float(outdoor_temperature),
                            capacity: min_speed_capacity,
                            capacity_fraction_of_nominal: min_speed_capacity_fraction_of_nominal,
                            capacity_description: HPXML::CapacityDescriptionMinimum,
                            efficiency_cop: Float(min_speed_cop))
          htg_perf_data.add(outdoor_temperature: Float(outdoor_temperature),
                            capacity: max_speed_capacity,
                            capacity_fraction_of_nominal: max_speed_capacity_fraction_of_nominal,
                            capacity_description: HPXML::CapacityDescriptionMaximum,
                            efficiency_cop: Float(max_speed_cop))
        end
      end

      if not args[:hvac_perf_data_cooling_outdoor_temperatures].nil?
        hvac_perf_data_capacity_type = args[:hvac_perf_data_capacity_type]
        hvac_perf_data_cooling_outdoor_temperatures = args[:hvac_perf_data_cooling_outdoor_temperatures].split(',').map(&:strip)
        hvac_perf_data_cooling_min_speed_capacities = args[:hvac_perf_data_cooling_min_speed_capacities].split(',').map(&:strip)
        hvac_perf_data_cooling_max_speed_capacities = args[:hvac_perf_data_cooling_max_speed_capacities].split(',').map(&:strip)
        hvac_perf_data_cooling_min_speed_cops = args[:hvac_perf_data_cooling_min_speed_cops].split(',').map(&:strip)
        hvac_perf_data_cooling_max_speed_cops = args[:hvac_perf_data_cooling_max_speed_cops].split(',').map(&:strip)

        clg_perf_data = hpxml_bldg.heat_pumps[0].cooling_detailed_performance_data
        cooling_perf_data_data_points = hvac_perf_data_cooling_outdoor_temperatures.zip(hvac_perf_data_cooling_min_speed_capacities,
                                                                                        hvac_perf_data_cooling_max_speed_capacities,
                                                                                        hvac_perf_data_cooling_min_speed_cops,
                                                                                        hvac_perf_data_cooling_max_speed_cops)
        cooling_perf_data_data_points.each do |cooling_perf_data_data_point|
          outdoor_temperature, min_speed_cap_or_frac, max_speed_cap_or_frac, min_speed_cop, max_speed_cop = cooling_perf_data_data_point

          if hvac_perf_data_capacity_type == 'Absolute capacities'
            min_speed_capacity = Float(min_speed_cap_or_frac)
            max_speed_capacity = Float(max_speed_cap_or_frac)
          elsif hvac_perf_data_capacity_type == 'Normalized capacity fractions'
            min_speed_capacity_fraction_of_nominal = Float(min_speed_cap_or_frac)
            max_speed_capacity_fraction_of_nominal = Float(max_speed_cap_or_frac)
          end

          clg_perf_data.add(outdoor_temperature: Float(outdoor_temperature),
                            capacity: min_speed_capacity,
                            capacity_fraction_of_nominal: min_speed_capacity_fraction_of_nominal,
                            capacity_description: HPXML::CapacityDescriptionMinimum,
                            efficiency_cop: Float(min_speed_cop))
          clg_perf_data.add(outdoor_temperature: Float(outdoor_temperature),
                            capacity: max_speed_capacity,
                            capacity_fraction_of_nominal: max_speed_capacity_fraction_of_nominal,
                            capacity_description: HPXML::CapacityDescriptionMaximum,
                            efficiency_cop: Float(max_speed_cop))
        end
      end
    end
  end

  # Set the geothermal loop properties, including:
  # - loop configuration
  # - water flow rate
  # - borefield configuration
  # - number of boreholes
  # - average borehole length
  # - borehole spacing and diameter
  # - grout type
  # - pipe type and diameter
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_geothermal_loop(hpxml_bldg, args)
    return if hpxml_bldg.heat_pumps.count { |hp| hp.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir } == 0
    return if args[:geothermal_loop_configuration].nil? || args[:geothermal_loop_configuration] == Constants::None

    if not args[:geothermal_loop_pipe_diameter].nil?
      pipe_diameter = args[:geothermal_loop_pipe_diameter]
      if pipe_diameter == '3/4" pipe'
        pipe_diameter = 0.75
      elsif pipe_diameter == '1" pipe'
        pipe_diameter = 1.0
      elsif pipe_diameter == '1-1/4" pipe'
        pipe_diameter = 1.25
      end
    end

    hpxml_bldg.geothermal_loops.add(id: "GeothermalLoop#{hpxml_bldg.geothermal_loops.size + 1}",
                                    loop_configuration: args[:geothermal_loop_configuration],
                                    loop_flow: args[:geothermal_loop_loop_flow],
                                    bore_config: args[:geothermal_loop_borefield_configuration],
                                    num_bore_holes: args[:geothermal_loop_boreholes_count],
                                    bore_length: args[:geothermal_loop_boreholes_length],
                                    bore_spacing: args[:geothermal_loop_boreholes_spacing],
                                    bore_diameter: args[:geothermal_loop_boreholes_diameter],
                                    grout_type: args[:geothermal_loop_grout_type],
                                    pipe_type: args[:geothermal_loop_pipe_type],
                                    pipe_diameter: pipe_diameter)
    hpxml_bldg.heat_pumps[-1].geothermal_loop_idref = hpxml_bldg.geothermal_loops[-1].id
  end

  # Set the secondary heating system properties, including:
  # - type
  # - fuel
  # - capacity
  # - efficiency
  # - heat load served
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_secondary_heating_systems(hpxml_bldg, args)
    heating_system_type = args[:heating_system_2_type]
    heating_system_is_heatpump_backup = (args[:heat_pump_type] != Constants::None && args[:heat_pump_backup_type] == HPXML::HeatPumpBackupTypeSeparate)

    return if heating_system_type == Constants::None && (not heating_system_is_heatpump_backup)

    if args[:heating_system_type] == HPXML::HVACTypeElectricResistance
      args[:heating_system_2_fuel] = HPXML::FuelTypeElectricity
    end

    if [HPXML::HVACTypeFurnace, HPXML::HVACTypeWallFurnace, HPXML::HVACTypeFloorFurnace].include?(heating_system_type) || heating_system_type.include?(HPXML::HVACTypeBoiler)
      heating_efficiency_afue = args[:heating_system_2_heating_efficiency]
    elsif [HPXML::HVACTypeElectricResistance, HPXML::HVACTypeStove, HPXML::HVACTypeSpaceHeater, HPXML::HVACTypeFireplace].include?(heating_system_type)
      heating_efficiency_percent = args[:heating_system_2_heating_efficiency]
    end

    if heating_system_type.include?(HPXML::HVACTypeBoiler)
      heating_system_type = HPXML::HVACTypeBoiler
    end

    if not heating_system_is_heatpump_backup
      fraction_heat_load_served = args[:heating_system_2_fraction_heat_load_served]
    end

    hpxml_bldg.heating_systems.add(id: "HeatingSystem#{hpxml_bldg.heating_systems.size + 1}",
                                   heating_system_type: heating_system_type,
                                   heating_system_fuel: args[:heating_system_2_fuel],
                                   heating_capacity: args[:heating_system_2_heating_capacity],
                                   heating_autosizing_factor: args[:heating_system_2_heating_autosizing_factor],
                                   heating_autosizing_limit: args[:heating_system_2_heating_autosizing_limit],
                                   fraction_heat_load_served: fraction_heat_load_served,
                                   heating_efficiency_afue: heating_efficiency_afue,
                                   heating_efficiency_percent: heating_efficiency_percent)
  end

  # Set the HVAC distribution properties, including:
  # - system type
  # - number of return registers
  # - presence of ducts
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_hvac_distribution(hpxml_bldg, args)
    # HydronicDistribution?
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless [heating_system.heating_system_type].include?(HPXML::HVACTypeBoiler)
      next if args[:heating_system_type].include?('Fan Coil')

      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                        hydronic_type: HPXML::HydronicTypeBaseboard)
      heating_system.distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
    end

    # AirDistribution?
    air_distribution_systems = []
    hpxml_bldg.heating_systems.each do |heating_system|
      if [HPXML::HVACTypeFurnace].include?(heating_system.heating_system_type)
        air_distribution_systems << heating_system
      end
    end
    hpxml_bldg.cooling_systems.each do |cooling_system|
      if [HPXML::HVACTypeCentralAirConditioner].include?(cooling_system.cooling_system_type)
        air_distribution_systems << cooling_system
      elsif [HPXML::HVACTypeEvaporativeCooler, HPXML::HVACTypeMiniSplitAirConditioner].include?(cooling_system.cooling_system_type) && args[:cooling_system_is_ducted]
        air_distribution_systems << cooling_system
      end
    end
    hpxml_bldg.heat_pumps.each do |heat_pump|
      if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type
        air_distribution_systems << heat_pump
      elsif [HPXML::HVACTypeHeatPumpMiniSplit].include?(heat_pump.heat_pump_type)
        if args[:heat_pump_is_ducted]
          air_distribution_systems << heat_pump if args[:heat_pump_is_ducted]
        end
      end
    end

    # FanCoil?
    fan_coil_distribution_systems = []
    hpxml_bldg.heating_systems.each do |heating_system|
      next unless heating_system.primary_system

      if args[:heating_system_type].include?('Fan Coil')
        fan_coil_distribution_systems << heating_system
      end
    end

    return if air_distribution_systems.size == 0 && fan_coil_distribution_systems.size == 0

    if [HPXML::HVACTypeEvaporativeCooler].include?(args[:cooling_system_type]) && hpxml_bldg.heating_systems.size == 0 && hpxml_bldg.heat_pumps.size == 0
      args[:ducts_number_of_return_registers] = nil
      if args[:cooling_system_is_ducted]
        args[:ducts_number_of_return_registers] = 0
      end
    end

    if air_distribution_systems.size > 0
      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeAir,
                                        air_type: HPXML::AirTypeRegularVelocity,
                                        number_of_return_registers: args[:ducts_number_of_return_registers])
      air_distribution_systems.each do |hvac_system|
        hvac_system.distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
      end
      set_duct_leakages(args, hpxml_bldg.hvac_distributions[-1])
      set_ducts(hpxml_bldg, args, hpxml_bldg.hvac_distributions[-1])
    end

    if fan_coil_distribution_systems.size > 0
      hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                        distribution_system_type: HPXML::HVACDistributionTypeAir,
                                        air_type: HPXML::AirTypeFanCoil)
      fan_coil_distribution_systems.each do |hvac_system|
        hvac_system.distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
      end
    end
  end

  # Set the HVAC blower properties, including:
  # - fan W/cfm
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_hvac_blower(hpxml_bldg, args)
    # Blower fan W/cfm
    hpxml_bldg.hvac_systems.each do |hvac_system|
      next unless (!hvac_system.distribution_system.nil? && hvac_system.distribution_system.distribution_system_type == HPXML::HVACDistributionTypeAir) || (hvac_system.is_a?(HPXML::HeatPump) && [HPXML::HVACTypeHeatPumpMiniSplit].include?(hvac_system.heat_pump_type))

      fan_watts_per_cfm = args[:hvac_blower_fan_watts_per_cfm]

      if hvac_system.is_a?(HPXML::HeatingSystem)
        if [HPXML::HVACTypeFurnace].include?(hvac_system.heating_system_type)
          hvac_system.fan_watts_per_cfm = fan_watts_per_cfm
        end
      elsif hvac_system.is_a?(HPXML::CoolingSystem)
        if [HPXML::HVACTypeCentralAirConditioner, HPXML::HVACTypeMiniSplitAirConditioner].include?(hvac_system.cooling_system_type)
          hvac_system.fan_watts_per_cfm = fan_watts_per_cfm
        end
      elsif hvac_system.is_a?(HPXML::HeatPump)
        if [HPXML::HVACTypeHeatPumpAirToAir, HPXML::HVACTypeHeatPumpMiniSplit, HPXML::HVACTypeHeatPumpGroundToAir].include?(hvac_system.heat_pump_type)
          hvac_system.fan_watts_per_cfm = fan_watts_per_cfm
        end
      end
    end
  end

  # Set the duct leakages properties, including:
  # - type
  # - leakage type, units, and value
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_duct_leakages(args, hvac_distribution)
    hvac_distribution.duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                    duct_leakage_units: args[:ducts_leakage_units],
                                                    duct_leakage_value: args[:ducts_supply_leakage_to_outside_value],
                                                    duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)

    hvac_distribution.duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                    duct_leakage_units: args[:ducts_leakage_units],
                                                    duct_leakage_value: args[:ducts_return_leakage_to_outside_value],
                                                    duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
  end

  # Get the specific HPXML foundation or attic location based on general HPXML location and specific HPXML foundation or attic type.
  #
  # @param location [String] the location of interest (HPXML::LocationCrawlspace or HPXML::LocationAttic)
  # @param foundation_type [String] the specific HPXML foundation type (unvented crawlspace, vented crawlspace, conditioned crawlspace)
  # @param attic_type [String] the specific HPXML attic type (unvented attic, vented attic, conditioned attic)
  # @return [nil]
  def self.get_location(location, foundation_type, attic_type)
    return if location.nil?

    if location == HPXML::LocationCrawlspace
      if foundation_type == HPXML::FoundationTypeCrawlspaceUnvented
        return HPXML::LocationCrawlspaceUnvented
      elsif foundation_type == HPXML::FoundationTypeCrawlspaceVented
        return HPXML::LocationCrawlspaceVented
      elsif foundation_type == HPXML::FoundationTypeCrawlspaceConditioned
        return HPXML::LocationCrawlspaceConditioned
      else
        fail "Specified '#{location}' but foundation type is '#{foundation_type}'."
      end
    elsif location == HPXML::LocationAttic
      if attic_type == HPXML::AtticTypeUnvented
        return HPXML::LocationAtticUnvented
      elsif attic_type == HPXML::AtticTypeVented
        return HPXML::LocationAtticVented
      elsif attic_type == HPXML::AtticTypeConditioned
        return HPXML::LocationConditionedSpace
      else
        fail "Specified '#{location}' but attic type is '#{attic_type}'."
      end
    end
    return location
  end

  # Set the ducts properties, including:
  # - type
  # - insulation R-value
  # - location
  # - surface area
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @param hvac_distribution [HPXML::HVACDistribution] HPXML HVAC Distribution object
  # @return [nil]
  def self.set_ducts(hpxml_bldg, args, hvac_distribution)
    ducts_supply_location = get_location(args[:ducts_supply_location], hpxml_bldg.foundations[-1].foundation_type, hpxml_bldg.attics[-1].attic_type)
    ducts_return_location = get_location(args[:ducts_return_location], hpxml_bldg.foundations[-1].foundation_type, hpxml_bldg.attics[-1].attic_type)

    if not args[:ducts_supply_fraction_rectangular].nil?
      ducts_supply_fraction_rectangular = args[:ducts_supply_fraction_rectangular]
      if ducts_supply_fraction_rectangular == 0
        ducts_supply_fraction_rectangular = nil
        ducts_supply_shape = HPXML::DuctShapeRound
      elsif ducts_supply_fraction_rectangular == 1
        ducts_supply_shape = HPXML::DuctShapeRectangular
        ducts_supply_fraction_rectangular = nil
      end
    end

    if (not ducts_supply_location.nil?) && args[:ducts_supply_surface_area].nil? && args[:ducts_supply_surface_area_fraction].nil?
      # Supply duct location without any area inputs provided; set area fraction
      if ducts_supply_location == HPXML::LocationConditionedSpace
        args[:ducts_supply_surface_area_fraction] = 1.0
      else
        args[:ducts_supply_surface_area_fraction] = Defaults.get_duct_outside_fraction(args[:geometry_unit_num_floors_above_grade])
      end
    end

    if (not ducts_return_location.nil?) && args[:ducts_return_surface_area].nil? && args[:ducts_return_surface_area_fraction].nil?
      # Return duct location without any area inputs provided; set area fraction
      if ducts_return_location == HPXML::LocationConditionedSpace
        args[:ducts_return_surface_area_fraction] = 1.0
      else
        args[:ducts_return_surface_area_fraction] = Defaults.get_duct_outside_fraction(args[:geometry_unit_num_floors_above_grade])
      end
    end

    if not args[:ducts_return_fraction_rectangular].nil?
      ducts_return_fraction_rectangular = args[:ducts_return_fraction_rectangular]
      if ducts_return_fraction_rectangular == 0
        ducts_return_fraction_rectangular = nil
        ducts_return_shape = HPXML::DuctShapeRound
      elsif ducts_return_fraction_rectangular == 1
        ducts_return_shape = HPXML::DuctShapeRectangular
        ducts_return_fraction_rectangular = nil
      end
    end

    hvac_distribution.ducts.add(id: "Ducts#{hvac_distribution.ducts.size + 1}",
                                duct_type: HPXML::DuctTypeSupply,
                                duct_insulation_r_value: args[:ducts_supply_insulation_r],
                                duct_buried_insulation_level: args[:ducts_supply_buried_insulation_level],
                                duct_location: ducts_supply_location,
                                duct_surface_area: args[:ducts_supply_surface_area],
                                duct_fraction_area: args[:ducts_supply_surface_area_fraction],
                                duct_shape: ducts_supply_shape,
                                duct_fraction_rectangular: ducts_supply_fraction_rectangular)

    if not ([HPXML::HVACTypeEvaporativeCooler].include?(args[:cooling_system_type]) && args[:cooling_system_is_ducted])
      hvac_distribution.ducts.add(id: "Ducts#{hvac_distribution.ducts.size + 1}",
                                  duct_type: HPXML::DuctTypeReturn,
                                  duct_insulation_r_value: args[:ducts_return_insulation_r],
                                  duct_buried_insulation_level: args[:ducts_return_buried_insulation_level],
                                  duct_location: ducts_return_location,
                                  duct_surface_area: args[:ducts_return_surface_area],
                                  duct_fraction_area: args[:ducts_return_surface_area_fraction],
                                  duct_shape: ducts_return_shape,
                                  duct_fraction_rectangular: ducts_return_fraction_rectangular)
    end

    if (not args[:ducts_supply_surface_area_fraction].nil?) && (args[:ducts_supply_surface_area_fraction] < 1)
      # OS-HPXML needs duct fractions to sum to 1; add remaining ducts in conditioned space.
      hvac_distribution.ducts.add(id: "Ducts#{hvac_distribution.ducts.size + 1}",
                                  duct_type: HPXML::DuctTypeSupply,
                                  duct_insulation_r_value: 0.0,
                                  duct_location: HPXML::LocationConditionedSpace,
                                  duct_fraction_area: 1.0 - args[:ducts_supply_surface_area_fraction])
    end

    if not hvac_distribution.ducts.find { |d| d.duct_type == HPXML::DuctTypeReturn }.nil?
      if (not args[:ducts_return_surface_area_fraction].nil?) && (args[:ducts_return_surface_area_fraction] < 1)
        # OS-HPXML needs duct fractions to sum to 1; add remaining ducts in conditioned space.
        hvac_distribution.ducts.add(id: "Ducts#{hvac_distribution.ducts.size + 1}",
                                    duct_type: HPXML::DuctTypeReturn,
                                    duct_insulation_r_value: 0.0,
                                    duct_location: HPXML::LocationConditionedSpace,
                                    duct_fraction_area: 1.0 - args[:ducts_return_surface_area_fraction])
      end
    end

    # If duct surface areas are defaulted, set CFA served
    if hvac_distribution.ducts.count { |d| d.duct_surface_area.nil? } > 0
      max_fraction_load_served = 0.0
      hvac_distribution.hvac_systems.each do |hvac_system|
        if hvac_system.respond_to?(:fraction_heat_load_served)
          if hvac_system.is_a?(HPXML::HeatingSystem) && hvac_system.is_heat_pump_backup_system
            # HP backup system, use HP fraction heat load served
            fraction_heat_load_served = hvac_system.primary_heat_pump.fraction_heat_load_served
          else
            fraction_heat_load_served = hvac_system.fraction_heat_load_served
          end
          max_fraction_load_served = [max_fraction_load_served, fraction_heat_load_served].max
        end
        if hvac_system.respond_to?(:fraction_cool_load_served)
          max_fraction_load_served = [max_fraction_load_served, hvac_system.fraction_cool_load_served].max
        end
      end
      hvac_distribution.conditioned_floor_area_served = args[:geometry_unit_cfa] * max_fraction_load_served
    end
  end

  # Set the HVAC control properties, including:
  # - simple heating and cooling setpoint temperatures
  # - hourly heating and cooling setpoint temperatures
  # - heating and cooling seasons
  # - cooling setpoint temperature offset
  #
  # @param hpxml [HPXML] HPXML object
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.set_hvac_control(hpxml, hpxml_bldg, args, weather)
    return if (args[:heating_system_type] == Constants::None) && (args[:cooling_system_type] == Constants::None) && (args[:heat_pump_type] == Constants::None)

    latitude = Defaults.get_latitude(args[:site_latitude], weather) unless weather.nil?

    # Heating
    if hpxml_bldg.total_fraction_heat_load_served > 0

      if (not args[:hvac_control_heating_weekday_setpoint].nil?) && (not args[:hvac_control_heating_weekend_setpoint].nil?)
        if args[:hvac_control_heating_weekday_setpoint] == args[:hvac_control_heating_weekend_setpoint] && !"#{args[:hvac_control_heating_weekday_setpoint]}".include?(',')
          heating_setpoint_temp = Float(args[:hvac_control_heating_weekday_setpoint])
        else
          weekday_heating_setpoints = args[:hvac_control_heating_weekday_setpoint]
          weekend_heating_setpoints = args[:hvac_control_heating_weekend_setpoint]
        end
      end

      if not args[:hvac_control_heating_season_period].nil?
        hvac_control_heating_season_period = args[:hvac_control_heating_season_period]
        if hvac_control_heating_season_period == Constants::BuildingAmerica
          heating_months, _cooling_months = HVAC.get_building_america_hvac_seasons(weather, latitude)
          sim_calendar_year = Location.get_sim_calendar_year(hpxml.header.sim_calendar_year, weather)
          begin_month, begin_day, end_month, end_day = Calendar.get_begin_and_end_dates_from_monthly_array(heating_months, sim_calendar_year)
        else
          begin_month, begin_day, _begin_hour, end_month, end_day, _end_hour = Calendar.parse_date_time_range(hvac_control_heating_season_period)
        end
        seasons_heating_begin_month = begin_month
        seasons_heating_begin_day = begin_day
        seasons_heating_end_month = end_month
        seasons_heating_end_day = end_day
      end

    end

    # Cooling
    if hpxml_bldg.total_fraction_cool_load_served > 0

      if (not args[:hvac_control_cooling_weekday_setpoint].nil?) && (not args[:hvac_control_cooling_weekend_setpoint].nil?)
        if args[:hvac_control_cooling_weekday_setpoint] == args[:hvac_control_cooling_weekend_setpoint] && !args[:hvac_control_cooling_weekday_setpoint].is_a?(String)
          cooling_setpoint_temp = Float(args[:hvac_control_cooling_weekday_setpoint])
        else
          weekday_cooling_setpoints = args[:hvac_control_cooling_weekday_setpoint]
          weekend_cooling_setpoints = args[:hvac_control_cooling_weekend_setpoint]
        end
      end

      if not args[:hvac_control_cooling_season_period].nil?
        hvac_control_cooling_season_period = args[:hvac_control_cooling_season_period]
        if hvac_control_cooling_season_period == Constants::BuildingAmerica
          _heating_months, cooling_months = HVAC.get_building_america_hvac_seasons(weather, latitude)
          sim_calendar_year = Location.get_sim_calendar_year(hpxml.header.sim_calendar_year, weather)
          begin_month, begin_day, end_month, end_day = Calendar.get_begin_and_end_dates_from_monthly_array(cooling_months, sim_calendar_year)
        else
          begin_month, begin_day, _begin_hour, end_month, end_day, _end_hour = Calendar.parse_date_time_range(hvac_control_cooling_season_period)
        end
        seasons_cooling_begin_month = begin_month
        seasons_cooling_begin_day = begin_day
        seasons_cooling_end_month = end_month
        seasons_cooling_end_day = end_day
      end

    end

    hpxml_bldg.hvac_controls.add(id: "HVACControl#{hpxml_bldg.hvac_controls.size + 1}",
                                 heating_setpoint_temp: heating_setpoint_temp,
                                 cooling_setpoint_temp: cooling_setpoint_temp,
                                 weekday_heating_setpoints: weekday_heating_setpoints,
                                 weekend_heating_setpoints: weekend_heating_setpoints,
                                 weekday_cooling_setpoints: weekday_cooling_setpoints,
                                 weekend_cooling_setpoints: weekend_cooling_setpoints,
                                 ceiling_fan_cooling_setpoint_temp_offset: args[:ceiling_fan_cooling_setpoint_temp_offset],
                                 seasons_heating_begin_month: seasons_heating_begin_month,
                                 seasons_heating_begin_day: seasons_heating_begin_day,
                                 seasons_heating_end_month: seasons_heating_end_month,
                                 seasons_heating_end_day: seasons_heating_end_day,
                                 seasons_cooling_begin_month: seasons_cooling_begin_month,
                                 seasons_cooling_begin_day: seasons_cooling_begin_day,
                                 seasons_cooling_end_month: seasons_cooling_end_month,
                                 seasons_cooling_end_day: seasons_cooling_end_day)
  end

  # Set the ventilation fans properties, including:
  # - mechanical ventilation
  #   - fan type
  #   - flow rate
  #   - hours in operation
  #   - efficiency type and value
  #   - fan power
  #   - number of dwelling units served
  #   - shared system recirculation, preheating/precooling efficiencies
  #   - presence of a second system
  # - local ventilation
  #   - kitchen fans quantity, hours in operation, power, start hour
  #   - bathroom fans quantity, hours in operation, power, start hour
  # - whole house fan
  #   - flow rate
  #   - fan power
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_ventilation_fans(hpxml_bldg, args)
    if args[:mech_vent_fan_type] != Constants::None

      if [HPXML::MechVentTypeERV].include?(args[:mech_vent_fan_type])
        if args[:mech_vent_recovery_efficiency_type] == 'Unadjusted'
          total_recovery_efficiency = args[:mech_vent_total_recovery_efficiency]
          sensible_recovery_efficiency = args[:mech_vent_sensible_recovery_efficiency]
        elsif args[:mech_vent_recovery_efficiency_type] == 'Adjusted'
          total_recovery_efficiency_adjusted = args[:mech_vent_total_recovery_efficiency]
          sensible_recovery_efficiency_adjusted = args[:mech_vent_sensible_recovery_efficiency]
        end
      elsif [HPXML::MechVentTypeHRV].include?(args[:mech_vent_fan_type])
        if args[:mech_vent_recovery_efficiency_type] == 'Unadjusted'
          sensible_recovery_efficiency = args[:mech_vent_sensible_recovery_efficiency]
        elsif args[:mech_vent_recovery_efficiency_type] == 'Adjusted'
          sensible_recovery_efficiency_adjusted = args[:mech_vent_sensible_recovery_efficiency]
        end
      end

      distribution_system_idref = nil
      if args[:mech_vent_fan_type] == HPXML::MechVentTypeCFIS
        hpxml_bldg.hvac_distributions.each do |hvac_distribution|
          next unless hvac_distribution.distribution_system_type == HPXML::HVACDistributionTypeAir
          next if hvac_distribution.air_type != HPXML::AirTypeRegularVelocity

          distribution_system_idref = hvac_distribution.id
        end
        if distribution_system_idref.nil?
          # Allow for PTAC/PTHP by automatically adding a DSE=1 distribution system to attach the CFIS to
          hpxml_bldg.hvac_systems.each do |hvac_system|
            next unless (hvac_system.is_a?(HPXML::CoolingSystem) && [HPXML::HVACTypePTAC, HPXML::HVACTypeRoomAirConditioner].include?(hvac_system.cooling_system_type)) ||
                        (hvac_system.is_a?(HPXML::HeatPump) && [HPXML::HVACTypeHeatPumpPTHP, HPXML::HVACTypeHeatPumpRoom].include?(hvac_system.heat_pump_type))

            hpxml_bldg.hvac_distributions.add(id: "HVACDistribution#{hpxml_bldg.hvac_distributions.size + 1}",
                                              distribution_system_type: HPXML::HVACDistributionTypeDSE,
                                              annual_cooling_dse: 1.0,
                                              annual_heating_dse: 1.0)
            hvac_system.distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
            distribution_system_idref = hpxml_bldg.hvac_distributions[-1].id
          end
        end

        return if distribution_system_idref.nil? # No distribution system to attach the CFIS to

        cfis_addtl_runtime_operating_mode = HPXML::CFISModeAirHandler
      end

      if args[:mech_vent_num_units_served] > 1
        is_shared_system = true
        in_unit_flow_rate = args[:mech_vent_flow_rate] / args[:mech_vent_num_units_served].to_f
        fraction_recirculation = args[:mech_vent_shared_frac_recirculation]
        preheating_fuel = args[:mech_vent_shared_preheating_fuel]
        preheating_efficiency_cop = args[:mech_vent_shared_preheating_efficiency]
        preheating_fraction_load_served = args[:mech_vent_shared_preheating_fraction_heat_load_served]
        precooling_fuel = args[:mech_vent_shared_precooling_fuel]
        precooling_efficiency_cop = args[:mech_vent_shared_precooling_efficiency]
        precooling_fraction_load_served = args[:mech_vent_shared_precooling_fraction_cool_load_served]
      end

      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: args[:mech_vent_fan_type],
                                      cfis_addtl_runtime_operating_mode: cfis_addtl_runtime_operating_mode,
                                      rated_flow_rate: args[:mech_vent_flow_rate],
                                      hours_in_operation: args[:mech_vent_hours_in_operation],
                                      used_for_whole_building_ventilation: true,
                                      total_recovery_efficiency: total_recovery_efficiency,
                                      total_recovery_efficiency_adjusted: total_recovery_efficiency_adjusted,
                                      sensible_recovery_efficiency: sensible_recovery_efficiency,
                                      sensible_recovery_efficiency_adjusted: sensible_recovery_efficiency_adjusted,
                                      fan_power: args[:mech_vent_fan_power],
                                      distribution_system_idref: distribution_system_idref,
                                      is_shared_system: is_shared_system,
                                      in_unit_flow_rate: in_unit_flow_rate,
                                      fraction_recirculation: fraction_recirculation,
                                      preheating_fuel: preheating_fuel,
                                      preheating_efficiency_cop: preheating_efficiency_cop,
                                      preheating_fraction_load_served: preheating_fraction_load_served,
                                      precooling_fuel: precooling_fuel,
                                      precooling_efficiency_cop: precooling_efficiency_cop,
                                      precooling_fraction_load_served: precooling_fraction_load_served)
    end

    if args[:mech_vent_2_fan_type] != Constants::None

      if [HPXML::MechVentTypeERV].include?(args[:mech_vent_2_fan_type])

        if args[:mech_vent_2_recovery_efficiency_type] == 'Unadjusted'
          total_recovery_efficiency = args[:mech_vent_2_total_recovery_efficiency]
          sensible_recovery_efficiency = args[:mech_vent_2_sensible_recovery_efficiency]
        elsif args[:mech_vent_2_recovery_efficiency_type] == 'Adjusted'
          total_recovery_efficiency_adjusted = args[:mech_vent_2_total_recovery_efficiency]
          sensible_recovery_efficiency_adjusted = args[:mech_vent_2_sensible_recovery_efficiency]
        end
      elsif [HPXML::MechVentTypeHRV].include?(args[:mech_vent_2_fan_type])
        if args[:mech_vent_2_recovery_efficiency_type] == 'Unadjusted'
          sensible_recovery_efficiency = args[:mech_vent_2_sensible_recovery_efficiency]
        elsif args[:mech_vent_2_recovery_efficiency_type] == 'Adjusted'
          sensible_recovery_efficiency_adjusted = args[:mech_vent_2_sensible_recovery_efficiency]
        end
      end

      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      fan_type: args[:mech_vent_2_fan_type],
                                      rated_flow_rate: args[:mech_vent_2_flow_rate],
                                      hours_in_operation: args[:mech_vent_2_hours_in_operation],
                                      used_for_whole_building_ventilation: true,
                                      total_recovery_efficiency: total_recovery_efficiency,
                                      total_recovery_efficiency_adjusted: total_recovery_efficiency_adjusted,
                                      sensible_recovery_efficiency: sensible_recovery_efficiency,
                                      sensible_recovery_efficiency_adjusted: sensible_recovery_efficiency_adjusted,
                                      fan_power: args[:mech_vent_2_fan_power])
    end

    if args[:kitchen_fans_quantity].nil? || (args[:kitchen_fans_quantity] > 0)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      rated_flow_rate: args[:kitchen_fans_flow_rate],
                                      used_for_local_ventilation: true,
                                      hours_in_operation: args[:kitchen_fans_hours_in_operation],
                                      fan_location: HPXML::LocationKitchen,
                                      fan_power: args[:kitchen_fans_power],
                                      start_hour: args[:kitchen_fans_start_hour],
                                      count: args[:kitchen_fans_quantity])
    end

    if args[:bathroom_fans_quantity].nil? || (args[:bathroom_fans_quantity] > 0)
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      rated_flow_rate: args[:bathroom_fans_flow_rate],
                                      used_for_local_ventilation: true,
                                      hours_in_operation: args[:bathroom_fans_hours_in_operation],
                                      fan_location: HPXML::LocationBath,
                                      fan_power: args[:bathroom_fans_power],
                                      start_hour: args[:bathroom_fans_start_hour],
                                      count: args[:bathroom_fans_quantity])
    end

    if args[:whole_house_fan_present]
      hpxml_bldg.ventilation_fans.add(id: "VentilationFan#{hpxml_bldg.ventilation_fans.size + 1}",
                                      rated_flow_rate: args[:whole_house_fan_flow_rate],
                                      used_for_seasonal_cooling_load_reduction: true,
                                      fan_power: args[:whole_house_fan_power])
    end
  end

  # Set the water heating systems properties, including:
  # - type
  # - fuel
  # - capacity
  # - location
  # - tank volume
  # - efficiencies
  # - jacket R-value
  # - setpoint temperature
  # - standby loss units and value
  # - presence of desuperheater
  # - number of bedrooms served
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_water_heating_systems(hpxml_bldg, args)
    water_heater_type = args[:water_heater_type]
    return if water_heater_type == Constants::None

    if water_heater_type == HPXML::WaterHeaterTypeHeatPump
      args[:water_heater_fuel_type] = HPXML::FuelTypeElectricity
    end

    location = get_location(args[:water_heater_location], hpxml_bldg.foundations[-1].foundation_type, hpxml_bldg.attics[-1].attic_type)

    if not [HPXML::WaterHeaterTypeCombiStorage, HPXML::WaterHeaterTypeCombiTankless].include? water_heater_type
      if args[:water_heater_efficiency_type] == 'EnergyFactor'
        energy_factor = args[:water_heater_efficiency]
      elsif args[:water_heater_efficiency_type] == 'UniformEnergyFactor'
        uniform_energy_factor = args[:water_heater_efficiency]
        if water_heater_type != HPXML::WaterHeaterTypeTankless
          usage_bin = args[:water_heater_usage_bin]
        end
      end
    end

    if (args[:water_heater_fuel_type] != HPXML::FuelTypeElectricity) && (water_heater_type == HPXML::WaterHeaterTypeStorage)
      recovery_efficiency = args[:water_heater_recovery_efficiency]
    end

    if [HPXML::WaterHeaterTypeTankless, HPXML::WaterHeaterTypeCombiTankless].include? water_heater_type
      args[:water_heater_tank_volume] = nil
    end

    if [HPXML::WaterHeaterTypeTankless].include? water_heater_type
      heating_capacity = nil
      recovery_efficiency = nil
    elsif [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? water_heater_type
      args[:water_heater_fuel_type] = nil
      heating_capacity = nil
      energy_factor = nil
      if hpxml_bldg.heating_systems.size > 0
        related_hvac_idref = hpxml_bldg.heating_systems[0].id
      end
    end

    if [HPXML::WaterHeaterTypeCombiTankless, HPXML::WaterHeaterTypeCombiStorage].include? water_heater_type
      if args[:water_heater_standby_loss].to_f > 0
        standby_loss_units = HPXML::UnitsDegFPerHour
        standby_loss_value = args[:water_heater_standby_loss]
      end
    end

    if not [HPXML::WaterHeaterTypeTankless, HPXML::WaterHeaterTypeCombiTankless].include? water_heater_type
      if args[:water_heater_jacket_rvalue].to_f > 0
        jacket_r_value = args[:water_heater_jacket_rvalue]
      end
    end

    if [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include? args[:geometry_unit_type]
      if args[:water_heater_num_bedrooms_served].to_f > args[:geometry_unit_num_bedrooms]
        is_shared_system = true
        number_of_bedrooms_served = args[:water_heater_num_bedrooms_served]
      end
    end

    uses_desuperheater = args[:water_heater_uses_desuperheater]
    if uses_desuperheater
      related_hvac_idref = nil
      hpxml_bldg.cooling_systems.each do |cooling_system|
        next unless [HPXML::HVACTypeCentralAirConditioner,
                     HPXML::HVACTypeMiniSplitAirConditioner].include? cooling_system.cooling_system_type

        related_hvac_idref = cooling_system.id
      end
      hpxml_bldg.heat_pumps.each do |heat_pump|
        next unless [HPXML::HVACTypeHeatPumpAirToAir,
                     HPXML::HVACTypeHeatPumpMiniSplit,
                     HPXML::HVACTypeHeatPumpGroundToAir].include? heat_pump.heat_pump_type

        related_hvac_idref = heat_pump.id
      end
    end

    if [HPXML::WaterHeaterTypeStorage].include? water_heater_type
      heating_capacity = args[:water_heater_heating_capacity]
      tank_model_type = args[:water_heater_tank_model_type]
    elsif [HPXML::WaterHeaterTypeHeatPump].include? water_heater_type
      heating_capacity = args[:water_heater_heating_capacity]
      backup_heating_capacity = args[:water_heater_backup_heating_capacity]
      operating_mode = args[:water_heater_operating_mode]
    end

    hpxml_bldg.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml_bldg.water_heating_systems.size + 1}",
                                         water_heater_type: water_heater_type,
                                         fuel_type: args[:water_heater_fuel_type],
                                         location: location,
                                         tank_volume: args[:water_heater_tank_volume],
                                         fraction_dhw_load_served: 1.0,
                                         energy_factor: energy_factor,
                                         uniform_energy_factor: uniform_energy_factor,
                                         usage_bin: usage_bin,
                                         recovery_efficiency: recovery_efficiency,
                                         uses_desuperheater: uses_desuperheater,
                                         related_hvac_idref: related_hvac_idref,
                                         standby_loss_units: standby_loss_units,
                                         standby_loss_value: standby_loss_value,
                                         jacket_r_value: jacket_r_value,
                                         temperature: args[:water_heater_setpoint_temperature],
                                         heating_capacity: heating_capacity,
                                         backup_heating_capacity: backup_heating_capacity,
                                         is_shared_system: is_shared_system,
                                         number_of_bedrooms_served: number_of_bedrooms_served,
                                         tank_model_type: tank_model_type,
                                         operating_mode: operating_mode)
  end

  # Set the hot water distribution properties, including:
  # - system type
  # - pipe lengths and insulation R-value
  # - recirculation control type and pump power
  # - drain water heat recovery facilities connected, flow configuration, efficiency
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_hot_water_distribution(hpxml_bldg, args)
    return if args[:water_heater_type] == Constants::None

    if args[:dwhr_facilities_connected] != Constants::None
      dwhr_facilities_connected = args[:dwhr_facilities_connected]
      dwhr_equal_flow = args[:dwhr_equal_flow]
      dwhr_efficiency = args[:dwhr_efficiency]
    end

    if args[:hot_water_distribution_system_type] == HPXML::DHWDistTypeStandard
      standard_piping_length = args[:hot_water_distribution_standard_piping_length]
    else
      recirculation_control_type = args[:hot_water_distribution_recirc_control_type]
      recirculation_piping_loop_length = args[:hot_water_distribution_recirc_piping_length]
      recirculation_branch_piping_length = args[:hot_water_distribution_recirc_branch_piping_length]
      recirculation_pump_power = args[:hot_water_distribution_recirc_pump_power]
    end

    hpxml_bldg.hot_water_distributions.add(id: "HotWaterDistribution#{hpxml_bldg.hot_water_distributions.size + 1}",
                                           system_type: args[:hot_water_distribution_system_type],
                                           standard_piping_length: standard_piping_length,
                                           recirculation_control_type: recirculation_control_type,
                                           recirculation_piping_loop_length: recirculation_piping_loop_length,
                                           recirculation_branch_piping_length: recirculation_branch_piping_length,
                                           recirculation_pump_power: recirculation_pump_power,
                                           pipe_r_value: args[:hot_water_distribution_pipe_r],
                                           dwhr_facilities_connected: dwhr_facilities_connected,
                                           dwhr_equal_flow: dwhr_equal_flow,
                                           dwhr_efficiency: dwhr_efficiency)
  end

  # Set the water fixtures properties, including:
  # - showerhead low flow
  # - faucet/sink low flow
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_water_fixtures(hpxml_bldg, args)
    return if args[:water_heater_type] == Constants::None

    hpxml_bldg.water_fixtures.add(id: "WaterFixture#{hpxml_bldg.water_fixtures.size + 1}",
                                  water_fixture_type: HPXML::WaterFixtureTypeShowerhead,
                                  low_flow: args[:water_fixtures_shower_low_flow])

    hpxml_bldg.water_fixtures.add(id: "WaterFixture#{hpxml_bldg.water_fixtures.size + 1}",
                                  water_fixture_type: HPXML::WaterFixtureTypeFaucet,
                                  low_flow: args[:water_fixtures_sink_low_flow])

    hpxml_bldg.water_heating.water_fixtures_usage_multiplier = args[:water_fixtures_usage_multiplier]
  end

  # Set the solar thermal properties, including:
  # - system type
  # - collector area, loop type, orientation, tilt, optical efficiency, and thermal losses
  # - storage volume
  # - solar fraction
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.set_solar_thermal(hpxml_bldg, args, weather)
    return if args[:solar_thermal_system_type] == Constants::None

    if args[:solar_thermal_solar_fraction] > 0
      solar_fraction = args[:solar_thermal_solar_fraction]
    else
      collector_area = args[:solar_thermal_collector_area]
      collector_loop_type = args[:solar_thermal_collector_loop_type]
      collector_type = args[:solar_thermal_collector_type]
      collector_azimuth = args[:solar_thermal_collector_azimuth]
      latitude = Defaults.get_latitude(args[:site_latitude], weather) unless weather.nil?
      collector_tilt = Geometry.get_absolute_tilt(tilt_str: "#{args[:solar_thermal_collector_tilt]}", roof_pitch: args[:geometry_roof_pitch], latitude: latitude)
      collector_rated_optical_efficiency = args[:solar_thermal_collector_rated_optical_efficiency]
      collector_rated_thermal_losses = args[:solar_thermal_collector_rated_thermal_losses]
      storage_volume = args[:solar_thermal_storage_volume]
    end

    if hpxml_bldg.water_heating_systems.size == 0
      fail 'Solar thermal system specified but no water heater found.'
    end

    hpxml_bldg.solar_thermal_systems.add(id: "SolarThermalSystem#{hpxml_bldg.solar_thermal_systems.size + 1}",
                                         system_type: args[:solar_thermal_system_type],
                                         collector_area: collector_area,
                                         collector_loop_type: collector_loop_type,
                                         collector_type: collector_type,
                                         collector_azimuth: collector_azimuth,
                                         collector_tilt: collector_tilt,
                                         collector_rated_optical_efficiency: collector_rated_optical_efficiency,
                                         collector_rated_thermal_losses: collector_rated_thermal_losses,
                                         storage_volume: storage_volume,
                                         water_heating_system_idref: hpxml_bldg.water_heating_systems[0].id,
                                         solar_fraction: solar_fraction)
  end

  # Set the PV systems properties, including:
  # - module type
  # - roof or ground location
  # - tracking type
  # - array orientation and tilt
  # - power output
  # - inverter efficiency
  # - losses fraction
  # - number of bedrooms served
  # - presence of a second system
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @param weather [WeatherFile] Weather object containing EPW information
  # @return [nil]
  def self.set_pv_systems(hpxml_bldg, args, weather)
    return unless args[:pv_system_present]

    if [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include? args[:geometry_unit_type]
      if args[:pv_system_num_bedrooms_served].to_f > args[:geometry_unit_num_bedrooms]
        is_shared_system = true
        number_of_bedrooms_served = args[:pv_system_num_bedrooms_served]
      end
    end

    latitude = Defaults.get_latitude(args[:site_latitude], weather) unless weather.nil?

    hpxml_bldg.pv_systems.add(id: "PVSystem#{hpxml_bldg.pv_systems.size + 1}",
                              location: args[:pv_system_location],
                              module_type: args[:pv_system_module_type],
                              tracking: args[:pv_system_tracking],
                              array_azimuth: args[:pv_system_array_azimuth],
                              array_tilt: Geometry.get_absolute_tilt(tilt_str: "#{args[:pv_system_array_tilt]}", roof_pitch: args[:geometry_roof_pitch], latitude: latitude),
                              max_power_output: args[:pv_system_max_power_output],
                              system_losses_fraction: args[:pv_system_system_losses_fraction],
                              is_shared_system: is_shared_system,
                              number_of_bedrooms_served: number_of_bedrooms_served)

    if args[:pv_system_2_present]
      hpxml_bldg.pv_systems.add(id: "PVSystem#{hpxml_bldg.pv_systems.size + 1}",
                                location: args[:pv_system_2_location],
                                module_type: args[:pv_system_2_module_type],
                                tracking: args[:pv_system_2_tracking],
                                array_azimuth: args[:pv_system_2_array_azimuth],
                                array_tilt: Geometry.get_absolute_tilt(tilt_str: "#{args[:pv_system_2_array_tilt]}", roof_pitch: args[:geometry_roof_pitch], latitude: latitude),
                                max_power_output: args[:pv_system_2_max_power_output],
                                system_losses_fraction: args[:pv_system_system_losses_fraction],
                                is_shared_system: is_shared_system,
                                number_of_bedrooms_served: number_of_bedrooms_served)
    end

    # Add inverter efficiency; assume a single inverter even if multiple PV arrays
    hpxml_bldg.inverters.add(id: "Inverter#{hpxml_bldg.inverters.size + 1}",
                             inverter_efficiency: args[:pv_system_inverter_efficiency])
    hpxml_bldg.pv_systems.each do |pv_system|
      pv_system.inverter_idref = hpxml_bldg.inverters[-1].id
    end
  end

  # Set the battery properties, including:
  # - location
  # - power output
  # - nominal and usable capacity
  # - round-trip efficiency
  # - number of bedrooms served
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_battery(hpxml_bldg, args)
    return unless args[:battery_present]

    location = get_location(args[:battery_location], hpxml_bldg.foundations[-1].foundation_type, hpxml_bldg.attics[-1].attic_type)

    if [HPXML::ResidentialTypeSFA, HPXML::ResidentialTypeApartment].include? args[:geometry_unit_type]
      if args[:battery_num_bedrooms_served].to_f > args[:geometry_unit_num_bedrooms]
        is_shared_system = true
        number_of_bedrooms_served = args[:battery_num_bedrooms_served]
      end
    end

    hpxml_bldg.batteries.add(id: "Battery#{hpxml_bldg.batteries.size + 1}",
                             type: HPXML::BatteryTypeLithiumIon,
                             location: location,
                             rated_power_output: args[:battery_power],
                             nominal_capacity_kwh: args[:battery_capacity],
                             usable_capacity_kwh: args[:battery_usable_capacity],
                             round_trip_efficiency: args[:battery_round_trip_efficiency],
                             is_shared_system: is_shared_system,
                             number_of_bedrooms_served: number_of_bedrooms_served)
  end

  # Set the lighting properties, including:
  # - interior/exterior/garage fraction of lamps that are LFL/CFL/LED
  # - interior/exterior/garage usage multipliers
  # - holiday lighting daily energy and period
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_lighting(hpxml_bldg, args)
    if args[:lighting_present]
      has_garage = (args[:geometry_garage_width] * args[:geometry_garage_depth] > 0)

      # Interior
      interior_usage_multiplier = args[:lighting_interior_usage_multiplier]
      if interior_usage_multiplier.nil? || interior_usage_multiplier.to_f > 0
        hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                       location: HPXML::LocationInterior,
                                       fraction_of_units_in_location: args[:lighting_interior_fraction_cfl],
                                       lighting_type: HPXML::LightingTypeCFL)
        hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                       location: HPXML::LocationInterior,
                                       fraction_of_units_in_location: args[:lighting_interior_fraction_lfl],
                                       lighting_type: HPXML::LightingTypeLFL)
        hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                       location: HPXML::LocationInterior,
                                       fraction_of_units_in_location: args[:lighting_interior_fraction_led],
                                       lighting_type: HPXML::LightingTypeLED)
        hpxml_bldg.lighting.interior_usage_multiplier = interior_usage_multiplier
      end

      # Exterior
      exterior_usage_multiplier = args[:lighting_exterior_usage_multiplier]
      if exterior_usage_multiplier.nil? || exterior_usage_multiplier.to_f > 0
        hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                       location: HPXML::LocationExterior,
                                       fraction_of_units_in_location: args[:lighting_exterior_fraction_cfl],
                                       lighting_type: HPXML::LightingTypeCFL)
        hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                       location: HPXML::LocationExterior,
                                       fraction_of_units_in_location: args[:lighting_exterior_fraction_lfl],
                                       lighting_type: HPXML::LightingTypeLFL)
        hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                       location: HPXML::LocationExterior,
                                       fraction_of_units_in_location: args[:lighting_exterior_fraction_led],
                                       lighting_type: HPXML::LightingTypeLED)
        hpxml_bldg.lighting.exterior_usage_multiplier = exterior_usage_multiplier
      end

      # Garage
      if has_garage
        garage_usage_multiplier = args[:lighting_garage_usage_multiplier]
        if garage_usage_multiplier.nil? || garage_usage_multiplier.to_f > 0
          hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                         location: HPXML::LocationGarage,
                                         fraction_of_units_in_location: args[:lighting_garage_fraction_cfl],
                                         lighting_type: HPXML::LightingTypeCFL)
          hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                         location: HPXML::LocationGarage,
                                         fraction_of_units_in_location: args[:lighting_garage_fraction_lfl],
                                         lighting_type: HPXML::LightingTypeLFL)
          hpxml_bldg.lighting_groups.add(id: "LightingGroup#{hpxml_bldg.lighting_groups.size + 1}",
                                         location: HPXML::LocationGarage,
                                         fraction_of_units_in_location: args[:lighting_garage_fraction_led],
                                         lighting_type: HPXML::LightingTypeLED)
          hpxml_bldg.lighting.garage_usage_multiplier = garage_usage_multiplier
        end
      end
    end

    return unless args[:holiday_lighting_present]

    hpxml_bldg.lighting.holiday_exists = true
    hpxml_bldg.lighting.holiday_kwh_per_day = args[:holiday_lighting_daily_kwh]

    if not args[:holiday_lighting_period].nil?
      begin_month, begin_day, _begin_hour, end_month, end_day, _end_hour = Calendar.parse_date_time_range(args[:holiday_lighting_period])
      hpxml_bldg.lighting.holiday_period_begin_month = begin_month
      hpxml_bldg.lighting.holiday_period_begin_day = begin_day
      hpxml_bldg.lighting.holiday_period_end_month = end_month
      hpxml_bldg.lighting.holiday_period_end_day = end_day
    end
  end

  # Set the dehumidifier properties, including:
  # - type
  # - efficiency
  # - capacity
  # - relative humidity setpoint
  # - dehumidification load served
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_dehumidifier(hpxml_bldg, args)
    return if args[:dehumidifier_type] == Constants::None

    if args[:dehumidifier_efficiency_type] == 'EnergyFactor'
      energy_factor = args[:dehumidifier_efficiency]
    elsif args[:dehumidifier_efficiency_type] == 'IntegratedEnergyFactor'
      integrated_energy_factor = args[:dehumidifier_efficiency]
    end

    hpxml_bldg.dehumidifiers.add(id: "Dehumidifier#{hpxml_bldg.dehumidifiers.size + 1}",
                                 type: args[:dehumidifier_type],
                                 capacity: args[:dehumidifier_capacity],
                                 energy_factor: energy_factor,
                                 integrated_energy_factor: integrated_energy_factor,
                                 rh_setpoint: args[:dehumidifier_rh_setpoint],
                                 fraction_served: args[:dehumidifier_fraction_dehumidification_load_served],
                                 location: HPXML::LocationConditionedSpace)
  end

  # Set the clothes washer properties, including:
  # - location
  # - efficiency
  # - capacity
  # - annual consumption
  # - label electric rate
  # - label gas rate and annual cost
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_clothes_washer(hpxml_bldg, args)
    return if args[:water_heater_type] == Constants::None
    return unless args[:clothes_washer_present]

    if args[:clothes_washer_efficiency_type] == 'ModifiedEnergyFactor'
      modified_energy_factor = args[:clothes_washer_efficiency]
    elsif args[:clothes_washer_efficiency_type] == 'IntegratedModifiedEnergyFactor'
      integrated_modified_energy_factor = args[:clothes_washer_efficiency]
    end

    hpxml_bldg.clothes_washers.add(id: "ClothesWasher#{hpxml_bldg.clothes_washers.size + 1}",
                                   location: args[:clothes_washer_location],
                                   modified_energy_factor: modified_energy_factor,
                                   integrated_modified_energy_factor: integrated_modified_energy_factor,
                                   rated_annual_kwh: args[:clothes_washer_rated_annual_kwh],
                                   label_electric_rate: args[:clothes_washer_label_electric_rate],
                                   label_gas_rate: args[:clothes_washer_label_gas_rate],
                                   label_annual_gas_cost: args[:clothes_washer_label_annual_gas_cost],
                                   label_usage: args[:clothes_washer_label_usage],
                                   capacity: args[:clothes_washer_capacity],
                                   usage_multiplier: args[:clothes_washer_usage_multiplier])
  end

  # Set the clothes dryer properties, including:
  # - location
  # - fuel
  # - efficiency
  # - exhaust flow rate
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_clothes_dryer(hpxml_bldg, args)
    return if args[:water_heater_type] == Constants::None
    return unless args[:clothes_washer_present]
    return unless args[:clothes_dryer_present]

    if args[:clothes_dryer_efficiency_type] == 'EnergyFactor'
      energy_factor = args[:clothes_dryer_efficiency]
    elsif args[:clothes_dryer_efficiency_type] == 'CombinedEnergyFactor'
      combined_energy_factor = args[:clothes_dryer_efficiency]
    end

    if not args[:clothes_dryer_vented_flow_rate].nil?
      is_vented = false
      if args[:clothes_dryer_vented_flow_rate] > 0
        is_vented = true
        vented_flow_rate = args[:clothes_dryer_vented_flow_rate]
      end
    end

    hpxml_bldg.clothes_dryers.add(id: "ClothesDryer#{hpxml_bldg.clothes_dryers.size + 1}",
                                  location: args[:clothes_dryer_location],
                                  fuel_type: args[:clothes_dryer_fuel_type],
                                  energy_factor: energy_factor,
                                  combined_energy_factor: combined_energy_factor,
                                  is_vented: is_vented,
                                  vented_flow_rate: vented_flow_rate,
                                  usage_multiplier: args[:clothes_dryer_usage_multiplier])
  end

  # Set the dishwasher properties, including:
  # - location
  # - efficiency type and value
  # - label electric rate
  # - label gas rate and annual cost
  # - loads per week
  # - number of place settings
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_dishwasher(hpxml_bldg, args)
    return if args[:water_heater_type] == Constants::None
    return unless args[:dishwasher_present]

    if args[:dishwasher_efficiency_type] == 'RatedAnnualkWh'
      rated_annual_kwh = args[:dishwasher_efficiency]
    elsif args[:dishwasher_efficiency_type] == 'EnergyFactor'
      energy_factor = args[:dishwasher_efficiency]
    end

    hpxml_bldg.dishwashers.add(id: "Dishwasher#{hpxml_bldg.dishwashers.size + 1}",
                               location: args[:dishwasher_location],
                               rated_annual_kwh: rated_annual_kwh,
                               energy_factor: energy_factor,
                               label_electric_rate: args[:dishwasher_label_electric_rate],
                               label_gas_rate: args[:dishwasher_label_gas_rate],
                               label_annual_gas_cost: args[:dishwasher_label_annual_gas_cost],
                               label_usage: args[:dishwasher_label_usage],
                               place_setting_capacity: args[:dishwasher_place_setting_capacity],
                               usage_multiplier: args[:dishwasher_usage_multiplier])
  end

  # Set the primary refrigerator properties, including:
  # - location
  # - annual consumption
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_refrigerator(hpxml_bldg, args)
    return unless args[:refrigerator_present]

    hpxml_bldg.refrigerators.add(id: "Refrigerator#{hpxml_bldg.refrigerators.size + 1}",
                                 location: args[:refrigerator_location],
                                 rated_annual_kwh: args[:refrigerator_rated_annual_kwh],
                                 usage_multiplier: args[:refrigerator_usage_multiplier])
  end

  # Set the extra refrigerator properties, including:
  # - location
  # - annual consumption
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_extra_refrigerator(hpxml_bldg, args)
    return unless args[:extra_refrigerator_present]

    hpxml_bldg.refrigerators.add(id: "Refrigerator#{hpxml_bldg.refrigerators.size + 1}",
                                 location: args[:extra_refrigerator_location],
                                 rated_annual_kwh: args[:extra_refrigerator_rated_annual_kwh],
                                 usage_multiplier: args[:extra_refrigerator_usage_multiplier],
                                 primary_indicator: false)
    hpxml_bldg.refrigerators[0].primary_indicator = true
  end

  # Set the freezer properties, including:
  # - location
  # - annual consumption
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_freezer(hpxml_bldg, args)
    return unless args[:freezer_present]

    hpxml_bldg.freezers.add(id: "Freezer#{hpxml_bldg.freezers.size + 1}",
                            location: args[:freezer_location],
                            rated_annual_kwh: args[:freezer_rated_annual_kwh],
                            usage_multiplier: args[:freezer_usage_multiplier])
  end

  # Set the cooking range/oven properties, including:
  # - location
  # - whether induction or convection
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_cooking_range_oven(hpxml_bldg, args)
    return unless args[:cooking_range_oven_present]

    hpxml_bldg.cooking_ranges.add(id: "CookingRange#{hpxml_bldg.cooking_ranges.size + 1}",
                                  location: args[:cooking_range_oven_location],
                                  fuel_type: args[:cooking_range_oven_fuel_type],
                                  is_induction: args[:cooking_range_oven_is_induction],
                                  usage_multiplier: args[:cooking_range_oven_usage_multiplier])

    hpxml_bldg.ovens.add(id: "Oven#{hpxml_bldg.ovens.size + 1}",
                         is_convection: args[:cooking_range_oven_is_convection])
  end

  # Set the ceiling fans properties, including:
  # - label energy use
  # - efficiency
  # - quantity
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_ceiling_fans(hpxml_bldg, args)
    return unless args[:ceiling_fan_present]

    hpxml_bldg.ceiling_fans.add(id: "CeilingFan#{hpxml_bldg.ceiling_fans.size + 1}",
                                efficiency: args[:ceiling_fan_efficiency],
                                label_energy_use: args[:ceiling_fan_label_energy_use],
                                count: args[:ceiling_fan_quantity])
  end

  # Set the miscellaneous television plug loads properties, including:
  # - annual consumption
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_misc_plug_loads_television(hpxml_bldg, args)
    return unless args[:misc_plug_loads_television_present]

    hpxml_bldg.plug_loads.add(id: "PlugLoad#{hpxml_bldg.plug_loads.size + 1}",
                              plug_load_type: HPXML::PlugLoadTypeTelevision,
                              kwh_per_year: args[:misc_plug_loads_television_annual_kwh],
                              usage_multiplier: args[:misc_plug_loads_television_usage_multiplier])
  end

  # Set the miscellaneous other plug loads properties, including:
  # - annual consumption
  # - sensible and latent fractions
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_misc_plug_loads_other(hpxml_bldg, args)
    hpxml_bldg.plug_loads.add(id: "PlugLoad#{hpxml_bldg.plug_loads.size + 1}",
                              plug_load_type: HPXML::PlugLoadTypeOther,
                              kwh_per_year: args[:misc_plug_loads_other_annual_kwh],
                              frac_sensible: args[:misc_plug_loads_other_frac_sensible],
                              frac_latent: args[:misc_plug_loads_other_frac_latent],
                              usage_multiplier: args[:misc_plug_loads_other_usage_multiplier])
  end

  # Set the miscellaneous well pump plug loads properties, including:
  # - annual consumption
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_misc_plug_loads_well_pump(hpxml_bldg, args)
    return unless args[:misc_plug_loads_well_pump_present]

    hpxml_bldg.plug_loads.add(id: "PlugLoad#{hpxml_bldg.plug_loads.size + 1}",
                              plug_load_type: HPXML::PlugLoadTypeWellPump,
                              kwh_per_year: args[:misc_plug_loads_well_pump_annual_kwh],
                              usage_multiplier: args[:misc_plug_loads_well_pump_usage_multiplier])
  end

  # Set the miscellaneous vehicle plug loads properties, including:
  # - annual consumption
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_misc_plug_loads_vehicle(hpxml_bldg, args)
    return unless args[:misc_plug_loads_vehicle_present]

    hpxml_bldg.plug_loads.add(id: "PlugLoad#{hpxml_bldg.plug_loads.size + 1}",
                              plug_load_type: HPXML::PlugLoadTypeElectricVehicleCharging,
                              kwh_per_year: args[:misc_plug_loads_vehicle_annual_kwh],
                              usage_multiplier: args[:misc_plug_loads_vehicle_usage_multiplier])
  end

  # Set the miscellaneous grill fuel loads properties, including:
  # - fuel
  # - annual consumption
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_misc_fuel_loads_grill(hpxml_bldg, args)
    return unless args[:misc_fuel_loads_grill_present]

    hpxml_bldg.fuel_loads.add(id: "FuelLoad#{hpxml_bldg.fuel_loads.size + 1}",
                              fuel_load_type: HPXML::FuelLoadTypeGrill,
                              fuel_type: args[:misc_fuel_loads_grill_fuel_type],
                              therm_per_year: args[:misc_fuel_loads_grill_annual_therm],
                              usage_multiplier: args[:misc_fuel_loads_grill_usage_multiplier])
  end

  # Set the miscellaneous lighting fuel loads properties, including:
  # - fuel
  # - annual consumption
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_misc_fuel_loads_lighting(hpxml_bldg, args)
    return unless args[:misc_fuel_loads_lighting_present]

    hpxml_bldg.fuel_loads.add(id: "FuelLoad#{hpxml_bldg.fuel_loads.size + 1}",
                              fuel_load_type: HPXML::FuelLoadTypeLighting,
                              fuel_type: args[:misc_fuel_loads_lighting_fuel_type],
                              therm_per_year: args[:misc_fuel_loads_lighting_annual_therm],
                              usage_multiplier: args[:misc_fuel_loads_lighting_usage_multiplier])
  end

  # Set the miscellaneous fireplace fuel loads properties, including:
  # - fuel
  # - annual consumption
  # - sensible and latent fractions
  # - usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_misc_fuel_loads_fireplace(hpxml_bldg, args)
    return unless args[:misc_fuel_loads_fireplace_present]

    hpxml_bldg.fuel_loads.add(id: "FuelLoad#{hpxml_bldg.fuel_loads.size + 1}",
                              fuel_load_type: HPXML::FuelLoadTypeFireplace,
                              fuel_type: args[:misc_fuel_loads_fireplace_fuel_type],
                              therm_per_year: args[:misc_fuel_loads_fireplace_annual_therm],
                              frac_sensible: args[:misc_fuel_loads_fireplace_frac_sensible],
                              frac_latent: args[:misc_fuel_loads_fireplace_frac_latent],
                              usage_multiplier: args[:misc_fuel_loads_fireplace_usage_multiplier])
  end

  # Set the pool properties, including:
  # - pump annual consumption
  # - pump usage multiplier
  # - heater type
  # - heater annual consumption
  # - heater usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_pool(hpxml_bldg, args)
    return unless args[:pool_present]

    if [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(args[:pool_heater_type])
      if not args[:pool_heater_annual_kwh].nil?
        heater_load_units = HPXML::UnitsKwhPerYear
        heater_load_value = args[:pool_heater_annual_kwh]
      end
    end

    if [HPXML::HeaterTypeGas].include?(args[:pool_heater_type])
      if not args[:pool_heater_annual_therm].nil?
        heater_load_units = HPXML::UnitsThermPerYear
        heater_load_value = args[:pool_heater_annual_therm]
      end
    end

    hpxml_bldg.pools.add(id: "Pool#{hpxml_bldg.pools.size + 1}",
                         type: HPXML::TypeUnknown,
                         pump_type: HPXML::TypeUnknown,
                         pump_kwh_per_year: args[:pool_pump_annual_kwh],
                         pump_usage_multiplier: args[:pool_pump_usage_multiplier],
                         heater_type: args[:pool_heater_type],
                         heater_load_units: heater_load_units,
                         heater_load_value: heater_load_value,
                         heater_usage_multiplier: args[:pool_heater_usage_multiplier])
  end

  # Set the permanent spa properties, including:
  # - pump annual consumption
  # - pump usage multiplier
  # - heater type
  # - heater annual consumption
  # - heater usage multiplier
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.set_permanent_spa(hpxml_bldg, args)
    return unless args[:permanent_spa_present]

    if [HPXML::HeaterTypeElectricResistance, HPXML::HeaterTypeHeatPump].include?(args[:permanent_spa_heater_type])
      if not args[:permanent_spa_heater_annual_kwh].nil?
        heater_load_units = HPXML::UnitsKwhPerYear
        heater_load_value = args[:permanent_spa_heater_annual_kwh]
      end
    end

    if [HPXML::HeaterTypeGas].include?(args[:permanent_spa_heater_type])
      if not args[:permanent_spa_heater_annual_therm].nil?
        heater_load_units = HPXML::UnitsThermPerYear
        heater_load_value = args[:permanent_spa_heater_annual_therm]
      end
    end

    hpxml_bldg.permanent_spas.add(id: "PermanentSpa#{hpxml_bldg.permanent_spas.size + 1}",
                                  type: HPXML::TypeUnknown,
                                  pump_type: HPXML::TypeUnknown,
                                  pump_kwh_per_year: args[:permanent_spa_pump_annual_kwh],
                                  pump_usage_multiplier: args[:permanent_spa_pump_usage_multiplier],
                                  heater_type: args[:permanent_spa_heater_type],
                                  heater_load_units: heater_load_units,
                                  heater_load_value: heater_load_value,
                                  heater_usage_multiplier: args[:permanent_spa_heater_usage_multiplier])
  end

  # Combine surfaces to simplify the HPXML file.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @param args [Hash] Map of :argument_name => value
  # @return [nil]
  def self.collapse_surfaces(hpxml_bldg, args)
    if args[:combine_like_surfaces]
      # Collapse some surfaces whose azimuth is a minor effect to simplify HPXMLs.
      (hpxml_bldg.roofs + hpxml_bldg.rim_joists + hpxml_bldg.walls + hpxml_bldg.foundation_walls).each do |surface|
        surface.azimuth = nil
      end
      hpxml_bldg.collapse_enclosure_surfaces()
    else
      # Collapse surfaces so that we don't get, e.g., individual windows
      # or the front wall split because of the door. Exclude foundation walls
      # from the list so we get all 4 foundation walls.
      hpxml_bldg.collapse_enclosure_surfaces([:roofs, :walls, :rim_joists, :floors,
                                              :slabs, :windows, :skylights, :doors])
    end

    # After surfaces are collapsed, round all areas
    (hpxml_bldg.surfaces + hpxml_bldg.subsurfaces).each do |s|
      s.area = s.area.round(1)
    end
  end

  # After having collapsed some surfaces, renumber SystemIdentifier ids and AttachedToXXX idrefs.
  #
  # @param hpxml_bldg [HPXML::Building] HPXML Building object representing an individual dwelling unit
  # @return [nil]
  def self.renumber_hpxml_ids(hpxml_bldg)
    # Renumber surfaces
    indexes = {}
    (hpxml_bldg.surfaces + hpxml_bldg.subsurfaces).each do |surf|
      surf_name = surf.class.to_s.gsub('HPXML::', '')
      indexes[surf_name] = 0 if indexes[surf_name].nil?
      indexes[surf_name] += 1
      (hpxml_bldg.attics + hpxml_bldg.foundations).each do |attic_or_fnd|
        if attic_or_fnd.respond_to?(:attached_to_roof_idrefs) && !attic_or_fnd.attached_to_roof_idrefs.nil? && !attic_or_fnd.attached_to_roof_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_roof_idrefs << "#{surf_name}#{indexes[surf_name]}"
        end
        if attic_or_fnd.respond_to?(:attached_to_wall_idrefs) && !attic_or_fnd.attached_to_wall_idrefs.nil? && !attic_or_fnd.attached_to_wall_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_wall_idrefs << "#{surf_name}#{indexes[surf_name]}"
        end
        if attic_or_fnd.respond_to?(:attached_to_rim_joist_idrefs) && !attic_or_fnd.attached_to_rim_joist_idrefs.nil? && !attic_or_fnd.attached_to_rim_joist_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_rim_joist_idrefs << "#{surf_name}#{indexes[surf_name]}"
        end
        if attic_or_fnd.respond_to?(:attached_to_floor_idrefs) && !attic_or_fnd.attached_to_floor_idrefs.nil? && !attic_or_fnd.attached_to_floor_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_floor_idrefs << "#{surf_name}#{indexes[surf_name]}"
        end
        if attic_or_fnd.respond_to?(:attached_to_slab_idrefs) && !attic_or_fnd.attached_to_slab_idrefs.nil? && !attic_or_fnd.attached_to_slab_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_slab_idrefs << "#{surf_name}#{indexes[surf_name]}"
        end
        if attic_or_fnd.respond_to?(:attached_to_foundation_wall_idrefs) && !attic_or_fnd.attached_to_foundation_wall_idrefs.nil? && !attic_or_fnd.attached_to_foundation_wall_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_foundation_wall_idrefs << "#{surf_name}#{indexes[surf_name]}"
        end
      end
      (hpxml_bldg.windows + hpxml_bldg.doors).each do |subsurf|
        if subsurf.respond_to?(:attached_to_wall_idref) && (subsurf.attached_to_wall_idref == surf.id)
          subsurf.attached_to_wall_idref = "#{surf_name}#{indexes[surf_name]}"
        end
      end
      hpxml_bldg.skylights.each do |subsurf|
        if subsurf.respond_to?(:attached_to_roof_idref) && (subsurf.attached_to_roof_idref == surf.id)
          subsurf.attached_to_roof_idref = "#{surf_name}#{indexes[surf_name]}"
        end
      end
      surf.id = "#{surf_name}#{indexes[surf_name]}"
      if surf.respond_to?(:insulation_id) && (not surf.insulation_id.nil?)
        surf.insulation_id = "#{surf_name}#{indexes[surf_name]}Insulation"
      end
      if surf.respond_to?(:perimeter_insulation_id) && (not surf.perimeter_insulation_id.nil?)
        surf.perimeter_insulation_id = "#{surf_name}#{indexes[surf_name]}PerimeterInsulation"
      end
      if surf.respond_to?(:exterior_horizontal_insulation_id) && (not surf.exterior_horizontal_insulation_id.nil?)
        surf.exterior_horizontal_insulation_id = "#{surf_name}#{indexes[surf_name]}ExteriorHorizontalInsulation"
      end
      if surf.respond_to?(:under_slab_insulation_id) && (not surf.under_slab_insulation_id.nil?)
        surf.under_slab_insulation_id = "#{surf_name}#{indexes[surf_name]}UnderSlabInsulation"
      end
    end
  end
end

# register the measure to be used by the application
BuildResidentialHPXML.new.registerWithApplication
