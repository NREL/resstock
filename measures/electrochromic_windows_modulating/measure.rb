# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class ElectrochromicWindowsModulating < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Electrochromic Windows Modulating'
  end

  # human readable description
  def description
    return 'Adds electrochromic windows. SHGC and VLT will modulate linearly between specified clear and tinted properties.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Adds electrochromic windows. SHGC and VLT will modulate linearly between specified clear and tinted properties.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Set clear SHGC
    shgc_clear = OpenStudio::Measure::OSArgument::makeDoubleArgument('shgc_clear', true)
    shgc_clear.setDisplayName('SHGC Clear')
    shgc_clear.setDescription('Sets SHGC for clear state. Value of 0 will use current glazing property.')
    shgc_clear.setDefaultValue(0.319)
    args << shgc_clear

    # Set clear VT
    vt_clear = OpenStudio::Measure::OSArgument::makeDoubleArgument('vt_clear', true)
    vt_clear.setDisplayName('VT Clear')
    vt_clear.setDescription('Sets VT for clear state. Value of 0 will use current glazing property.')
    vt_clear.setDefaultValue(0.396)
    args << vt_clear

    # Set tinted SHGC
    shgc_tinted = OpenStudio::Measure::OSArgument::makeDoubleArgument('shgc_tinted', true)
    shgc_tinted.setDisplayName('SHGC Tinted')
    shgc_tinted.setDescription('Sets SHGC for tinted state.')
    shgc_tinted.setDefaultValue(0.077)
    args << shgc_tinted

    # Set tinted VT
    vt_tinted = OpenStudio::Measure::OSArgument::makeDoubleArgument('vt_tinted', true)
    vt_tinted.setDisplayName('VT Tinted')
    vt_tinted.setDescription('Sets VT for tinted state.')
    vt_tinted.setDefaultValue(0.007)
    args << vt_tinted

    # Set glazing u-value
    u_value = OpenStudio::Measure::OSArgument::makeDoubleArgument('u_value', true)
    u_value.setDisplayName('U-value (Btu/h·ft2·°F)')
    u_value.setDescription('Replaces u-value of existing applicable windows with this value. Use IP units.')
    u_value.setDefaultValue(0.322)
    args << u_value

    # Set solar radiation limit
    max_rad_w_per_m2 = OpenStudio::Measure::OSArgument::makeDoubleArgument('max_rad_w_per_m2', true)
    max_rad_w_per_m2.setDisplayName('Maximum Allowable Radiation (W/m^2)')
    max_rad_w_per_m2.setDescription('Windows will switch to a darker state if threshold is exceeded.')
    max_rad_w_per_m2.setDefaultValue(180)
    args << max_rad_w_per_m2

    # Set glare index
    gi = OpenStudio::Measure::OSArgument::makeDoubleArgument('gi', true)
    gi.setDisplayName('Maximum Allowable Glare Index')
    gi.setDescription('Sets maximum glare index allowance for EC windows.')
    gi.setDefaultValue(24)
    args << gi

    # Set minimum temperature threshold
    min_temp = OpenStudio::Measure::OSArgument::makeDoubleArgument('min_temp', true)
    min_temp.setDisplayName('Minimum Temperature for EC Tinting (F)')
    min_temp.setDescription('Sets minimum temperature to allow for EC tinting. A low value will mitigate heating penalties.')
    min_temp.setDefaultValue(55)
    args << min_temp

    # Set EC functionality prioritization; glare or temperature first
    ec_priority_logic = OpenStudio::Measure::OSArgument.makeBoolArgument('ec_priority_logic', false)
    ec_priority_logic.setDisplayName('Prioritize Glare Over Temperature?')
    ec_priority_logic.setDefaultValue(true)
    args << ec_priority_logic

    # Set facade applicability
    ['North', 'East', 'South', 'West'].each do |facade|
      facade_applicability = OpenStudio::Ruleset::OSArgument::makeBoolArgument(facade,false)
      facade_applicability.setDisplayName("Apply electrochromic glazing to #{facade} facade windows.")
      facade_applicability.setDefaultValue(true)
      args << facade_applicability

    end

    return args
  end

  def self.getAbsoluteAzimuthForSurface(surface, model)
    absolute_azimuth = OpenStudio.convert(surface.azimuth, 'rad', 'deg').get + surface.space.get.directionofRelativeNorth + model.getBuilding.northAxis
    absolute_azimuth -= 360.0 until absolute_azimuth < 360.0
    return absolute_azimuth
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Assign user-input variables
    shgc_clear = runner.getDoubleArgumentValue('shgc_clear', user_arguments)
    vt_clear = runner.getDoubleArgumentValue('vt_clear', user_arguments)
    shgc_tinted = runner.getDoubleArgumentValue('shgc_tinted', user_arguments)
    vt_tinted = runner.getDoubleArgumentValue('vt_tinted', user_arguments)
    u_value = runner.getDoubleArgumentValue('u_value', user_arguments)
    max_rad_w_per_m2 = runner.getDoubleArgumentValue('max_rad_w_per_m2', user_arguments)
    gi = runner.getDoubleArgumentValue('gi', user_arguments)
    min_temp = runner.getDoubleArgumentValue('min_temp', user_arguments)
    ec_priority_logic = runner.getBoolArgumentValue('ec_priority_logic', user_arguments)

    # convert u value
    u_value_si = OpenStudio.convert(u_value.to_f, 'Btu/hr*ft^2*R', 'W/m^2*K').get
    # convert temp
    min_temp_c = OpenStudio.convert(min_temp.to_f, 'F', 'C').get

    # make hash of facades to edit
    facades_to_edit_hash ={}
    ['North', 'East', 'South', 'West'].each do |facade|
      facades_to_edit = runner.getBoolArgumentValue(facade,user_arguments)
      facades_to_edit_hash[facade] = facades_to_edit
    end

    # create list of original window constructions
    simple_glazings = model.getSimpleGlazings.sort

    # set the four construction objects
    # set material 1 as clear
    sg_material_1 = OpenStudio::Model::SimpleGlazing.new(model)
    sg_material_1.setName("sg_material_1")
    sg_material_1.setUFactor(u_value_si)
    sg_material_1.setSolarHeatGainCoefficient(shgc_clear)
    sg_material_1.setVisibleTransmittance(vt_clear)
    # make construction for material 1
    win_const_1 = OpenStudio::Model::Construction.new(model)
    win_const_1.setName("win_const_1")
    li_sg_material_1 = [sg_material_1]
    win_const_1.setLayers(li_sg_material_1)
    # make construction index for calling in EMS
    ems_civ_1 = OpenStudio::Model::EnergyManagementSystemConstructionIndexVariable.new(model, win_const_1)
    ems_civ_1.setName('ems_civ_1')

    # set material 2 as 1/3rd of full range
    sg_material_2 = OpenStudio::Model::SimpleGlazing.new(model)
    sg_material_2.setName("sg_material_2")
    sg_material_2.setUFactor(u_value_si)
    shgc_2 = shgc_clear - ((shgc_clear - shgc_tinted)*(0.33333))
    sg_material_2.setSolarHeatGainCoefficient(shgc_2)
    vt_2 = vt_clear - ((vt_clear - vt_tinted )*(0.33333))
    sg_material_2.setVisibleTransmittance(vt_2)
    # make construction for material 2
    win_const_2 = OpenStudio::Model::Construction.new(model)
    win_const_2.setName("win_const_2")
    li_sg_material_2 = [sg_material_2]
    win_const_2.setLayers(li_sg_material_2)
    # make construction index for calling in EMS
    ems_civ_2 = OpenStudio::Model::EnergyManagementSystemConstructionIndexVariable.new(model, win_const_2)
    ems_civ_2.setName('ems_civ_2')

    # set material 3 as 2/3rd of full range
    sg_material_3 = OpenStudio::Model::SimpleGlazing.new(model)
    sg_material_3.setName("sg_material_3")
    sg_material_3.setUFactor(u_value_si)
    shgc_3 = shgc_clear - ((shgc_clear - shgc_tinted)*(0.66666))
    sg_material_3.setSolarHeatGainCoefficient(shgc_3)
    vt_3 = vt_clear - ((vt_clear - vt_tinted )*(0.66666))
    sg_material_3.setVisibleTransmittance(vt_3)
    # make construction for material 3
    win_const_3 = OpenStudio::Model::Construction.new(model)
    win_const_3.setName("win_const_3")
    li_sg_material_3 = [sg_material_3]
    win_const_3.setLayers(li_sg_material_3)
    # make construction index for calling in EMS
    ems_civ_3 = OpenStudio::Model::EnergyManagementSystemConstructionIndexVariable.new(model, win_const_3)
    ems_civ_3.setName('ems_civ_3')

    # set material 4 as fully tinted
    sg_material_4 = OpenStudio::Model::SimpleGlazing.new(model)
    sg_material_4.setName("sg_material_4")
    sg_material_4.setUFactor(u_value_si)
    sg_material_4.setSolarHeatGainCoefficient(shgc_tinted)
    sg_material_4.setVisibleTransmittance(vt_tinted)
    # make construction for material 4
    win_const_4 = OpenStudio::Model::Construction.new(model)
    win_const_4.setName("win_const_4")
    li_sg_material_4 = [sg_material_4]
    win_const_4.setLayers(li_sg_material_4)
    # make construction index for calling in EMS
    ems_civ_4 = OpenStudio::Model::EnergyManagementSystemConstructionIndexVariable.new(model, win_const_4)
    ems_civ_4.setName('ems_civ_4')

    # Set energy management system sensor for OA temp
    sens_oa_temp = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Drybulb Temperature')
    sens_oa_temp.setName("sens_oa_temp")
    sens_oa_temp.setKeyName("sens_oa_temp")

    # register as not applicable if no simple glazing is present on applicable facades
    if simple_glazings.size == 0
      runner.registerAsNotApplicable("The model has no simple glazing windows on the user-chosen facades; the measure is not applicable.")
    end

    # loop through subsurfaces and glazings
    sub_surfaces = []
    constructions = []
    model.getSubSurfaces.sort.each do |sub_surface|
      next unless sub_surface.subSurfaceType.include?('Window')
      simple_glazings.each do |simple_glazing|

        # get construction for surface
        construction = sub_surface.construction.get

        # check for simple glazing
        next unless construction.to_Construction.get.layers[0].name.get == simple_glazing.name.get

        # get surface and determine azimuth
        surface = sub_surface.surface.get
        absolute_azimuth = OpenStudio.convert(surface.azimuth, 'rad', 'deg').get + surface.space.get.directionofRelativeNorth + model.getBuilding.northAxis
        absolute_azimuth -= 360.0 until absolute_azimuth < 360.0

        # to select specific surfaces
        if absolute_azimuth >= 315.0 || absolute_azimuth < 45.0
          facade = 'North'
        elsif absolute_azimuth >= 45.0 && absolute_azimuth < 135.0
          facade = 'East'
        elsif absolute_azimuth >= 135.0 && absolute_azimuth < 225.0
          facade = 'South'
        elsif absolute_azimuth >= 225.0 && absolute_azimuth < 315.0
          facade = 'West'
        end

        # skip window if not included in desired facade
        next unless facades_to_edit_hash[facade] == true

        # set construction to be the new clear glazing construction
        sub_surface.setConstruction(win_const_1)

        # check for daylight controls; this will be needed for glare control
        space = sub_surface.space.get
        thermal_zone = sub_surface.space.get.thermalZone.get

        # skip window if less than 0.1m^2 (1sf)
        next unless sub_surface.grossArea > 0.1
        # skip window if zone is less than 20 sf
        next unless thermal_zone.floorArea > 1.89

        # add daylight sensor with no control fraction if none exists
        if thermal_zone.primaryDaylightingControl.empty? && thermal_zone.secondaryDaylightingControl.empty?
          # add daylight sensors
          # find floors for placing control
          floors = []
          space.surfaces.each do |surface|
            next if surface.surfaceType != 'Floor'
            floors << surface
          end
          # this method only works for flat (non-inclined) floors
          boundingBox = OpenStudio::BoundingBox.new
          floors.each do |floor|
            boundingBox.addPoints(floor.vertices)
          end
          xmin = boundingBox.minX.get
          ymin = boundingBox.minY.get
          zmin = boundingBox.minZ.get
          xmax = boundingBox.maxX.get
          ymax = boundingBox.maxY.get

          # create a new sensor and put at the center of the space
          sensor = OpenStudio::Model::DaylightingControl.new(model)
          sensor.setName("#{space.name.get.gsub("-", "")} daylighting control")
          sensor.setName("#{space.name.get.gsub("/", "")} daylighting control")
          x_pos = (xmin + xmax) / 2
          y_pos = (ymin + ymax) / 2
          z_pos = zmin + 1 # put it 1 meter above the floor
          new_point = OpenStudio::Point3d.new(x_pos, y_pos, z_pos)
          sensor.setPosition(new_point)
          sensor.setSpace(space)

          # add sensor to thermal zone with no control area
          thermal_zone.setPrimaryDaylightingControl(sensor)
          thermal_zone.setFractionofZoneControlledbyPrimaryDaylightingControl(0)
          runner.registerInfo("Thermal zone #{thermal_zone.name} does not contain daylight sensors, which are needed to get glare for EC control. Sensor #{sensor.name} has been added to this zone for glare. Lighting is not affected by this change.")
        end

        # Set energy management system sensor for simple glazing subsurface
        sens_window = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Surface Outside Face Incident Solar Radiation Rate per Area')
        sens_window.setName("sens_solar_#{sub_surface.name.get}")
        sens_window.setKeyName(sub_surface.name.get)

        # Set energy management system sensor for glare
        daylight_sensor = thermal_zone.primaryDaylightingControl.get

        # remove dashes in name
        if (daylight_sensor.name.get.include? "-")
          daylight_sensor.setName(daylight_sensor.name.get.gsub("-", ""))
        elsif (daylight_sensor.name.get.include? "/")
          daylight_sensor.setName(daylight_sensor.name.get.gsub("/", ""))
        end

        sens_window_glare = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Daylighting Reference Point 1 Glare Index')
        sens_window_glare.setName("sens_daylight_#{daylight_sensor.name.get}")
        sens_window_glare.setKeyName("#{thermal_zone.name.get} DaylightingControls")

        # set actuator for subsurface (window)
        act_window = OpenStudio::Model::EnergyManagementSystemActuator.new(sub_surface,
                                                                           'Surface',
                                                                           'Construction State')
        act_window.setName("act_#{sub_surface.name.get}")

        # write program
        # W/m^2 levels were set from Sillivan et. all 1996
        # 63 W/m^2 was the limit for untinted state, while trials of 189, 315 and 689 were chosen for tinted state
        window_electrochromic_prg = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
        window_electrochromic_prg.setName("electrochromic_prgm_#{sub_surface.name.get}")
        window_electrochromic_prg_body = <<-EMS
                SET sens_window = #{sens_window.name.get}
                SET sens_daylight = #{sens_window_glare.name.get}
                SET sens_oa_temp = #{sens_oa_temp.name.get}
                SET act_window = #{act_window.name.get}
                SET shgc_1 = #{shgc_clear}
                SET shgc_2 = #{shgc_2}
                SET shgc_3 = #{shgc_3}
                SET shgc_4 = #{shgc_tinted}
                SET max_rad_w_per_m2 = #{max_rad_w_per_m2}
                SET gi = #{gi}
                SET min_temp = #{min_temp_c}
                SET ec_priority_logic = "#{ec_priority_logic}"
                IF (#{ec_priority_logic} == false) && (#{sens_oa_temp.name.get} < #{min_temp_c}),
                    SET #{act_window.name.get} = #{ems_civ_1.name.get},
                ELSEIF #{sens_window_glare.name.get} >= #{gi},
                    SET #{act_window.name.get} = #{ems_civ_4.name.get},
                ELSEIF (#{sens_window.name.get} * #{shgc_clear} < #{max_rad_w_per_m2}) || (#{sens_oa_temp.name.get} < #{min_temp_c}),
                    SET #{act_window.name.get} = #{ems_civ_1.name.get},
                ELSEIF #{sens_window.name.get} * #{shgc_2} < #{max_rad_w_per_m2}
                    SET #{act_window.name.get} = #{ems_civ_2.name.get},
                ELSEIF #{sens_window.name.get} * #{shgc_3} < #{max_rad_w_per_m2}
                    SET #{act_window.name.get} = #{ems_civ_3.name.get},
                ELSEIF #{sens_window.name.get} * #{shgc_3} >= #{max_rad_w_per_m2}
                    SET #{act_window.name.get} = #{ems_civ_4.name.get}
                ELSE
                    SET #{act_window.name.get} = #{ems_civ_1.name.get},
                ENDIF
        EMS
        window_electrochromic_prg.setBody(window_electrochromic_prg_body)

        # set program calling manager
        programs_at_beginning_of_timestep = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
        programs_at_beginning_of_timestep.setName("Programs_At_Beginning_Of_Timestep_#{sub_surface.name.get}")
        # programs_at_beginning_of_timestep.setCallingPoint('BeginTimestepBeforePredictor')
        programs_at_beginning_of_timestep.setCallingPoint('BeginZoneTimestepBeforeInitHeatBalance')
        # programs_at_beginning_of_timestep.setCallingPoint('AfterPredictorAfterHVACManagers')
        programs_at_beginning_of_timestep.addProgram(window_electrochromic_prg)

        sub_surfaces << sub_surface
        constructions << sub_surface.construction.get
      end
    end

    # register as not applicable if no simple glazing is present on applicable facades
    if sub_surfaces.size == 0
      runner.registerAsNotApplicable("The model has no simple glazing windows on the user-chosen facades; the measure is not applicable.")
    end

    # register initial conditions
    runner.registerInitialCondition("The model started with #{sub_surfaces.size} applicable simple glazing windows. The U value for applicable windows will be changed to the user-input value of U=#{u_value} Btu/h·ft2·°F. Electrochromic features will be added to the applicable windows with 4 states. The clear state has SHGC-#{shgc_clear} and VT-#{vt_clear}, while the tinted state has SHGC-#{shgc_tinted} and VT-#{vt_tinted}. The other two states are set to equal intervals between the clear and tinted states.")

    # # set EMS output
    # output_ems = model.getOutputEnergyManagementSystem
    # output_ems.setActuatorAvailabilityDictionaryReporting("Verbose")
    # output_ems.setInternalVariableAvailabilityDictionaryReporting("Verbose")
    # output_ems.setEMSRuntimeLanguageDebugOutputLevel("Verbose")

    return true
  end
end

# register the measure to be used by the application
ElectrochromicWindowsModulating.new.registerWithApplication
