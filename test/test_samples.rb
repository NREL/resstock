# frozen_string_literal: true

require 'openstudio'
require 'minitest/autorun'

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../resources/run_sampling'
require_relative '../resources/buildstock'

class IntegrationWorkflowTest < MiniTest::Test
  def before_setup
    @project_dir = 'project_testing'
    @num_samples_baseline = 100
    @num_samples_upgrades = 10
    @outfile = File.join('..', 'test', 'test_samples_osw', 'buildstock.csv')
    @top_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'test_samples_osw'))
    @lib_dir = File.join(@top_dir, '..', '..', 'lib')
    @resources_dir = File.join(@top_dir, '..', '..', 'resources')
  end

  def after_teardown
    FileUtils.rm_rf(@lib_dir) if File.exist?(@lib_dir)
    FileUtils.rm_rf(File.join(@top_dir, 'run'))
    FileUtils.rm_rf(File.join(@top_dir, 'reports'))
    FileUtils.rm_rf(File.join(@top_dir, 'generated_files'))
    FileUtils.rm(File.join(@top_dir, 'out.osw'))
    FileUtils.rm(File.join(@top_dir, 'buildstock.csv'))
  end

  def test_baseline
    results_csv = samples_osw('baseline', @num_samples_baseline)

    rows = CSV.read(File.expand_path(results_csv))

    assert_equal(@num_samples_baseline, rows.length - 1)

    cols = rows.transpose
    cols.each do |col|
      next if col[0] != 'completed_status'

      assert(col[1..-1].all? { |x| x == 'Success' })
    end
  end

  def test_upgrades
    results_csv = samples_osw('upgrades', @num_samples_upgrades)

    rows = CSV.read(File.expand_path(results_csv))

    num_upgrades = Dir["#{@top_dir}/workflow-upgrades*.osw"].length
    assert_equal(@num_samples_upgrades * num_upgrades, rows.length - 1)

    cols = rows.transpose
    cols.each do |col|
      next if col[0] != 'completed_status'

      assert(col[1..-1].all? { |x| x != 'Fail' })
    end
  end

  private

  def samples_osw(scenario, num_samples)
    if @project_dir == 'project_national'
      parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
      if Dir["#{parent_dir}/weather/*.epw"].size < 10
        cli_path = OpenStudio.getOpenStudioCLI
        command = "cd #{parent_dir} && \"#{cli_path}\" tasks.rb download_weather"
        system(command)
      end
    end

    all_results = []
    parent_dir = File.join(@top_dir, scenario)
    Dir.mkdir(parent_dir) unless File.exist?(parent_dir)

    create_buildstock_csv(@project_dir, num_samples)
    create_lib_folder(@project_dir)

    Dir["#{@top_dir}/workflow*.osw"].each do |osw|
      next unless osw.include?(scenario)

      osw_basename = File.basename(osw)
      puts "\nWorkflow: #{osw_basename} ...\n"

      osw_dir = File.join(parent_dir, 'osw')
      Dir.mkdir(osw_dir) unless File.exist?(osw_dir)

      xml_dir = File.join(parent_dir, 'xml')
      Dir.mkdir(xml_dir) unless File.exist?(xml_dir)

      (1..num_samples).to_a.each do |building_unit_id|
        puts "\n\tBuilding Unit ID: #{building_unit_id} ...\n\n"

        change_building_unit_id(osw, building_unit_id)
        out_osw, result = RunOSWs.run_and_check(osw, @top_dir)
        result['OSW'] = "#{building_unit_id}.osw"
        all_results << result

        result = check_out_osw(result, out_osw)

        # Save existing/upgraded osws and xmls
        ['existing', 'upgraded'].each do |scen|
          ['osw', 'xml'].each do |type|
            from = File.join(@top_dir, 'run', "#{scen}.#{type}")

            dir = osw_dir
            if type == 'xml'
              dir = xml_dir
            end
            to = File.join(dir, "#{building_unit_id}-#{osw_basename.gsub('.osw', '')}-#{scen}.#{type}")

            if File.exist?(from)
              FileUtils.mv(from, to)
            end
          end
        end
      end
    end

    Dir["#{parent_dir}/workflow*.osw"].each do |osw|
      change_building_unit_id(osw, 1)
    end

    results_dir = File.join(parent_dir, 'results')
    RunOSWs._rm_path(results_dir)
    csv_out = RunOSWs.write_summary_results(results_dir, all_results)

    return csv_out
  end

  def create_buildstock_csv(project_dir, num_samples)
    r = RunSampling.new
    r.run(project_dir, num_samples, @outfile)
  end

  def create_lib_folder(project_dir)
    housing_characteristics_dir = File.join(@top_dir, '..', '..', project_dir, 'housing_characteristics')
    Dir.mkdir(@lib_dir) unless File.exist?(@lib_dir)
    FileUtils.cp_r(@resources_dir, @lib_dir)
    FileUtils.cp_r(housing_characteristics_dir, @lib_dir)
    FileUtils.cp(File.join(@resources_dir, @outfile), File.join(@lib_dir, 'housing_characteristics'))
  end

  def change_building_unit_id(osw, building_unit_id)
    json = JSON.parse(File.read(osw), symbolize_names: true)
    json[:steps].each do |measure|
      next if measure[:measure_dir_name] != 'BuildExistingModel'

      measure[:arguments][:building_unit_id] = "#{building_unit_id}"
    end
    File.open(osw, 'w') do |f|
      f.write(JSON.pretty_generate(json))
    end
  end

  def check_out_osw(result, out_osw)
    assert(File.exist?(out_osw))
    data_hash = JSON.parse(File.read(out_osw))

    completed_status = data_hash['completed_status']
    result['completed_status'] = completed_status

    data_hash['steps'].each do |step|
      return result unless step.keys.include?('result')

      step_time_str = "time_#{OpenStudio::toUnderscoreCase(step['measure_dir_name'])}"

      next unless step['result'].keys.include?('started_at') && step['result'].keys.include?('completed_at')
      started_at = DateTime.strptime(step['result']['started_at'], '%Y%m%dT%H%M%SZ')
      completed_at = DateTime.strptime(step['result']['completed_at'], '%Y%m%dT%H%M%SZ')
      result[step_time_str] = ((completed_at - started_at) * 24 * 3600).to_i
    end

    return result
  end
end
