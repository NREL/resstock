# frozen_string_literal: true

# Collection of methods related to generic OpenStudio Model object operations.
module Model
  # Map of IDD objects => OSM classes
  UniqueObjectsMap = { 'OS:ConvergenceLimits' => 'ConvergenceLimits',
                       'OS:Foundation:Kiva:Settings' => 'FoundationKivaSettings',
                       'OS:OutputControl:Files' => 'OutputControlFiles',
                       'OS:Output:Diagnostics' => 'OutputDiagnostics',
                       'OS:Output:JSON' => 'OutputJSON',
                       'OS:PerformancePrecisionTradeoffs' => 'PerformancePrecisionTradeoffs',
                       'OS:RunPeriod' => 'RunPeriod',
                       'OS:RunPeriodControl:DaylightSavingTime' => 'RunPeriodControlDaylightSavingTime',
                       'OS:ShadowCalculation' => 'ShadowCalculation',
                       'OS:SimulationControl' => 'SimulationControl',
                       'OS:Site' => 'Site',
                       'OS:Site:GroundTemperature:Deep' => 'SiteGroundTemperatureDeep',
                       'OS:Site:GroundTemperature:Shallow' => 'SiteGroundTemperatureShallow',
                       'OS:Site:WaterMainsTemperature' => 'SiteWaterMainsTemperature',
                       'OS:SurfaceConvectionAlgorithm:Inside' => 'InsideSurfaceConvectionAlgorithm',
                       'OS:SurfaceConvectionAlgorithm:Outside' => 'OutsideSurfaceConvectionAlgorithm',
                       'OS:Timestep' => 'Timestep' }

  # Tear down the existing model if it exists.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param runner [OpenStudio::Measure::OSRunner] Object typically used to display warnings
  # @return [nil]
  def self.tear_down(model:,
                     runner:)
    handles = OpenStudio::UUIDVector.new
    model.objects.each do |obj|
      handles << obj.handle
    end
    if !handles.empty?
      runner.registerWarning('The model contains existing objects and is being reset.')
      model.removeObjects(handles)
    end
  end

  # When there are multiple dwelling units, merge all unit models into a single model.
  # First deal with unique objects; look for differences in values across unit models.
  # Then make all unit models "unique" by shifting geometry and prefixing object names.
  # Then bulk add all modified objects to the main OpenStudio Model object.
  #
  # @param model [OpenStudio::Model::Model] OpenStudio Model object
  # @param hpxml_osm_map [Hash] Map of HPXML::Building objects => OpenStudio Model objects for each dwelling unit
  # @return [nil]
  def self.merge_unit_models(model, hpxml_osm_map)
    # Handle unique objects first: Grab one from the first model we find the
    # object on (may not be the first unit).
    unit_model_objects = []
    unique_handles_to_skip = []
    uuid_regex = /\{(.*?)\}/
    UniqueObjectsMap.each do |idd_obj, osm_class|
      first_model_object_by_type = nil
      hpxml_osm_map.values.each do |unit_model|
        next if unit_model.getObjectsByType(idd_obj.to_IddObjectType).empty?

        model_object = unit_model.send("get#{osm_class}")

        if first_model_object_by_type.nil?
          # Retain object for model
          unit_model_objects << model_object
          first_model_object_by_type = model_object
          if idd_obj == 'OS:Site:WaterMainsTemperature' # Handle referenced child object too
            unit_model_objects << unit_model.getObjectsByName(model_object.temperatureSchedule.get.name.to_s)[0]
          end
        else
          # Throw error if different values between this model_object and first_model_object_by_type
          if model_object.to_s.gsub(uuid_regex, '') != first_model_object_by_type.to_s.gsub(uuid_regex, '')
            fail "Unique object (#{idd_obj}) has different values across dwelling units."
          end

          if idd_obj == 'OS:Site:WaterMainsTemperature' # Handle referenced child object too
            if model_object.temperatureSchedule.get.to_s.gsub(uuid_regex, '') != first_model_object_by_type.temperatureSchedule.get.to_s.gsub(uuid_regex, '')
              fail "Unique object (#{idd_obj}) has different values across dwelling units."
            end
          end
        end

        unique_handles_to_skip << model_object.handle.to_s
        if idd_obj == 'OS:Site:WaterMainsTemperature' # Handle referenced child object too
          unique_handles_to_skip << model_object.temperatureSchedule.get.handle.to_s
        end
      end
    end

    hpxml_osm_map.values.each_with_index do |unit_model, unit_number|
      Geometry.shift_surfaces(unit_model, unit_number)
      prefix_objects(unit_model, unit_number)

      # Handle remaining (non-unique) objects now
      unit_model.objects.each do |obj|
        next if unit_number > 0 && obj.to_Building.is_initialized
        next if unique_handles_to_skip.include? obj.handle.to_s

        unit_model_objects << obj
      end
    end

    model.addObjects(unit_model_objects, true)
  end

  # Prefix all object names using using a provided unit number.
  #
  # @param unit_model [OpenStudio::Model::Model] OpenStudio Model object (corresponding to one of multiple dwelling units)
  # @param unit_number [Integer] index number corresponding to an HPXML Building object
  # @return [nil]
  def self.prefix_objects(unit_model, unit_number)
    # FUTURE: Create objects with unique names up front so we don't have to do this

    # EMS objects
    ems_map = {}

    unit_model.getEnergyManagementSystemSensors.each do |sensor|
      ems_map[sensor.name.to_s] = make_variable_name(sensor.name, unit_number)
      sensor.setKeyName(make_variable_name(sensor.keyName, unit_number)) unless sensor.keyName.empty? || sensor.keyName.downcase == 'environment'
    end

    unit_model.getEnergyManagementSystemActuators.each do |actuator|
      ems_map[actuator.name.to_s] = make_variable_name(actuator.name, unit_number)
    end

    unit_model.getEnergyManagementSystemInternalVariables.each do |internal_variable|
      ems_map[internal_variable.name.to_s] = make_variable_name(internal_variable.name, unit_number)
      internal_variable.setInternalDataIndexKeyName(make_variable_name(internal_variable.internalDataIndexKeyName, unit_number)) unless internal_variable.internalDataIndexKeyName.empty?
    end

    unit_model.getEnergyManagementSystemGlobalVariables.each do |global_variable|
      ems_map[global_variable.name.to_s] = make_variable_name(global_variable.name, unit_number)
    end

    unit_model.getEnergyManagementSystemOutputVariables.each do |output_variable|
      next if output_variable.emsVariableObject.is_initialized

      new_ems_variable_name = make_variable_name(output_variable.emsVariableName, unit_number)
      ems_map[output_variable.emsVariableName.to_s] = new_ems_variable_name
      output_variable.setEMSVariableName(new_ems_variable_name)
    end

    unit_model.getEnergyManagementSystemSubroutines.each do |subroutine|
      ems_map[subroutine.name.to_s] = make_variable_name(subroutine.name, unit_number)
    end

    # variables in program lines don't get updated automatically
    lhs_characters = [' ', ',', '(', ')', '+', '-', '*', '/', ';']
    rhs_characters = [''] + lhs_characters
    (unit_model.getEnergyManagementSystemPrograms + unit_model.getEnergyManagementSystemSubroutines).each do |program|
      new_lines = []
      program.lines.each do |line|
        ems_map.each do |old_name, new_name|
          next unless line.include?(old_name)

          # old_name between at least 1 character, with the exception of '' on left and ' ' on right
          lhs_characters.each do |lhs|
            next unless line.include?("#{lhs}#{old_name}")

            rhs_characters.each do |rhs|
              next unless line.include?("#{lhs}#{old_name}#{rhs}")
              next if lhs == '' && ['', ' '].include?(rhs)

              line.gsub!("#{lhs}#{old_name}#{rhs}", "#{lhs}#{new_name}#{rhs}")
            end
          end
        end
        new_lines << line
      end
      program.setLines(new_lines)
    end

    # All model objects
    unit_model.objects.each do |model_object|
      next if model_object.name.nil?

      if unit_number == 0
        # OpenStudio is unhappy if these schedules are renamed
        next if model_object.name.to_s == unit_model.alwaysOnContinuousSchedule.name.to_s
        next if model_object.name.to_s == unit_model.alwaysOnDiscreteSchedule.name.to_s
        next if model_object.name.to_s == unit_model.alwaysOffDiscreteSchedule.name.to_s
      end

      model_object.setName(make_variable_name(model_object.name, unit_number))
    end
  end

  # Create a new OpenStudio object name by prefixing the old with "unit" plus the unit number.
  #
  # @param obj_name [String] the OpenStudio object name
  # @param unit_number [Integer] index number corresponding to an HPXML Building object
  # @return [String] the new OpenStudio object name with unique unit prefix
  def self.make_variable_name(obj_name, unit_number)
    return "unit#{unit_number + 1}_#{obj_name}".gsub(' ', '_').gsub('-', '_')
  end
end
