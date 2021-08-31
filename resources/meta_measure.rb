# frozen_string_literal: true

def apply_child_measures(measures_dir, measures, runner, model, osw_out = nil, show_measure_calls = true, parent_measure_runner = {})
  require 'openstudio'

  if not osw_out.nil?
    # Create a workflow based on the measures we're going to call. Convenient for debugging.
    workflowJSON = OpenStudio::WorkflowJSON.new
    workflowJSON.setOswPath(File.expand_path("../#{osw_out}"))
    workflowJSON.addMeasurePath('measures')
    workflowJSON.addMeasurePath('resources/hpxml-measures')
    steps = OpenStudio::WorkflowStepVector.new
    measures.each do |measure_subdir, args_array|
      args_array.each do |args|
        step = OpenStudio::MeasureStep.new(measure_subdir)
        args.each do |k, v|
          next if v.nil?

          step.setArgument(k, "#{v}")
        end
        steps.push(step)
      end
    end
    workflowJSON.setWorkflowSteps(steps)
    workflowJSON.save
  end

  # Call each measure in the specified order
  measures.each do |measure_subdir, args_array|
    # Gather measure arguments and call measure
    full_measure_path = File.join(measures_dir, measure_subdir, 'measure.rb')
    check_file_exists(full_measure_path, runner)
    measure_instance = get_measure_instance(full_measure_path)
    args_array.each do |args|
      argument_map = get_argument_map(model, measure_instance, args, nil, measure_subdir, runner)
      if show_measure_calls
        print_measure_call(args, measure_subdir, runner)
      end

      measure_start = Time.now
      if not run_measure(model, measure_instance, argument_map, runner)
        return false
      end

      next if parent_measure_runner.empty?

      measure_time = (Time.now - measure_start).round(1)
      parent_measure = parent_measure_runner.keys[0]
      parent_runner = parent_measure_runner[parent_measure]
    end
  end

  return true
end

def validate_measure_args(measure_args, provided_args, lookup_file, measure_name, runner = nil)
  measure_arg_names = measure_args.map { |arg| arg.name }
  lookup_file_str = ''
  if not lookup_file.nil?
    lookup_file_str = " in #{lookup_file}"
  end
  # Verify all arguments have been provided
  measure_args.each do |arg|
    next if provided_args.keys.include?(arg.name)
    next if not arg.required
    next if arg.name.include?('hpxml_path')

    register_error("Required argument '#{arg.name}' not provided#{lookup_file_str} for measure '#{measure_name}'.", runner)
  end
  provided_args.keys.each do |k|
    next if measure_arg_names.include?(k)

    register_error("Extra argument '#{k}' specified#{lookup_file_str} for measure '#{measure_name}'.", runner)
  end
  # Check for valid argument values
  measure_args.each do |arg|
    # Get measure provided arg
    if provided_args[arg.name].nil?
      if arg.required
        next if arg.name.include?('hpxml_path')

        register_error("Required argument '#{arg.name}' for measure '#{measure_name}' must have a value provided.", runner)
      else
        next
      end
    else
      provided_args[arg.name] = provided_args[arg.name].to_s
    end
    case arg.type.valueName.downcase
    when 'boolean'
      if not ['true', 'false'].include?(provided_args[arg.name])
        register_error("Value of '#{provided_args[arg.name]}' for argument '#{arg.name}' and measure '#{measure_name}' must be 'true' or 'false'.", runner)
      end
    when 'double'
      if not provided_args[arg.name].is_number?
        register_error("Value of '#{provided_args[arg.name]}' for argument '#{arg.name}' and measure '#{measure_name}' must be a number.", runner)
      end
    when 'integer'
      if not provided_args[arg.name].is_integer?
        register_error("Value of '#{provided_args[arg.name]}' for argument '#{arg.name}' and measure '#{measure_name}' must be an integer.", runner)
      end
    when 'string'
    # no op
    when 'choice'
      if (not arg.choiceValues.include?(provided_args[arg.name])) && (not arg.modelDependent)
        register_error("Value of '#{provided_args[arg.name]}' for argument '#{arg.name}' and measure '#{measure_name}' must be one of: #{arg.choiceValues}.", runner)
      end
    end
  end
  return provided_args
end

def run_measure(model, measure, argument_map, runner)
  require 'openstudio'
  begin
    # run the measure
    runner_child = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    if model.instance_of? OpenStudio::Workspace
      runner_child.setLastOpenStudioModel(runner.lastOpenStudioModel.get)
    end
    measure.run(model, runner_child, argument_map)
    result_child = runner_child.result

    # get initial and final condition
    if result_child.initialCondition.is_initialized
      runner.registerInitialCondition(result_child.initialCondition.get.logMessage)
    end
    if result_child.finalCondition.is_initialized
      runner.registerFinalCondition(result_child.finalCondition.get.logMessage)
    end

    # re-register runner child registered values on the parent runner
    result_child.stepValues.each do |step_value|
      runner.registerValue(step_value.name, get_value_from_workflow_step_value(step_value))
    end

    # log messages
    result_child.warnings.each do |warning|
      runner.registerWarning(warning.logMessage)
    end
    result_child.info.each do |info|
      runner.registerInfo(info.logMessage)
    end
    result_child.errors.each do |error|
      runner.registerError(error.logMessage)
    end
    if result_child.errors.size > 0
      return false
    end

    # convert a return false in the measure to a return false and error here.
    if result_child.value.valueName == 'Fail'
      runner.registerError('The measure was not successful')
      return false
    end
  rescue => e
    runner.registerError("Measure Failed with an error: #{e.inspect} at: #{e.backtrace.join("\n")}")
    return false
  end
  return true
end
