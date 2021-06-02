# frozen_string_literal: true

require 'openstudio'

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../resources/run_sampling'
require_relative '../resources/buildstock'

class IntegrationWorkflowTest < MiniTest::Test
  def before_setup
    @project_dir_baseline = { 'project_testing' => 1, 'project_national' => 30 }
    @project_dir_upgrades = { 'project_testing' => 1, 'project_national' => 1 }

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
    FileUtils.rm(File.join(@top_dir, 'buildstock.csv'))
  end

  def test_baseline
    @project_dir_baseline.each do |project_dir, num_samples|
      results_csv = samples_osw('baseline', project_dir, num_samples)

      rows = CSV.read(results_csv)

      if project_dir == 'project_testing'
        assert_equal(num_samples, rows.length - 1)
      end

      cols = rows.transpose
      cols.each do |col|
        next if col[0] != 'completed_status'

        assert(col[1..-1].all? { |x| x == 'Success' })
      end
    end
  end

  def test_upgrades
    @project_dir_upgrades.each do |project_dir, num_samples|
      results_csv = samples_osw('upgrades', project_dir, num_samples)

      rows = CSV.read(results_csv)

      if project_dir == 'project_testing'
        num_upgrades = Dir["#{@top_dir}/workflow-upgrades*.osw"].length
        assert_equal(num_samples * num_upgrades, rows.length - 1)
      end

      cols = rows.transpose
      cols.each do |col|
        next if col[0] != 'completed_status'

        assert(col[1..-1].all? { |x| x != 'Fail' })
      end
    end
  end

  private

  def samples_osw(scenario, project_dir, num_samples)
    scenario_dir = File.join(@top_dir, scenario)
    Dir.mkdir(scenario_dir) unless File.exist?(scenario_dir)

    parent_dir = File.join(scenario_dir, project_dir)
    Dir.mkdir(parent_dir) unless File.exist?(parent_dir)

    create_buildstock_csv(project_dir, num_samples)
    create_lib_folder(project_dir)

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    all_results = []
    Dir["#{@top_dir}/workflow*.osw"].each do |osw|
      next unless osw.include?(scenario)

      osw_basename = File.basename(osw)
      puts "\nWorkflow: #{osw_basename} ...\n"

      osw_dir = File.join(parent_dir, 'osw')
      Dir.mkdir(osw_dir) unless File.exist?(osw_dir)

      xml_dir = File.join(parent_dir, 'xml')
      Dir.mkdir(xml_dir) unless File.exist?(xml_dir)

      (1..num_samples).to_a.each do |building_id|
        bldg_data = get_data_for_sample(File.join(@lib_dir, 'housing_characteristics/buildstock.csv'), building_id, runner)
        next unless counties.include? bldg_data['County']

        puts "\n\tBuilding Unit ID: #{building_id} ...\n"

        change_building_id(osw, building_id)
        finished_job, result = RunOSWs.run_and_check(osw, @top_dir)
        result['OSW'] = "#{building_id}.osw"
        all_results << result

        result = check_finished_job(result, finished_job)

        # Save existing/upgraded osws and xmls
        ['existing', 'upgraded'].each do |scen|
          ['osw', 'xml'].each do |type|
            from = File.join(@top_dir, 'run', "#{scen}.#{type}")

            dir = osw_dir
            if type == 'xml'
              dir = xml_dir
            end
            to = File.join(dir, "#{building_id}-#{osw_basename.gsub('.osw', '')}-#{scen}.#{type}")

            if File.exist?(from)
              FileUtils.mv(from, to)
            end
          end
        end
      end
    end

    Dir["#{@top_dir}/workflow*.osw"].each do |osw|
      change_building_id(osw, 1)
    end

    results_dir = File.join(parent_dir, 'results')
    RunOSWs._rm_path(results_dir)
    csv_out = RunOSWs.write_summary_results(results_dir, all_results)
    puts "\nWrote: #{csv_out}\n\n"

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

  def change_building_id(osw, building_id)
    json = JSON.parse(File.read(osw), symbolize_names: true)
    json[:steps].each do |measure|
      next if measure[:measure_dir_name] != 'BuildExistingModel'

      measure[:arguments][:building_id] = "#{building_id}"
    end
    File.open(osw, 'w') do |f|
      f.write(JSON.pretty_generate(json))
    end
  end

  def check_finished_job(result, finished_job)
    begin
      assert(File.exist?(finished_job))
      result['completed_status'] = 'Success'
    rescue
      result['completed_status'] = 'Fail'
    end

    return result
  end

  def counties
    return [
      'AZ, Maricopa County',
      'CA, Los Angeles County',
      'GA, Fulton County',
      'IL, Cook County',
      'TX, Harris County',
      'WA, King County'
    ]
  end
end
