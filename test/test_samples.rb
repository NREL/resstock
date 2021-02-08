# frozen_string_literal: true

require 'openstudio'
require 'minitest/autorun'

require_relative '../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../resources/run_sampling'
require_relative '../resources/buildstock'

class IntegrationWorkflowTest < MiniTest::Test
  def top_dir
    return File.absolute_path(File.join(File.dirname(__FILE__), 'test_samples_osw'))
  end

  def test_samples_osw_baseline
    project_dir = 'project_testing'
    num_samples = 100

    if project_dir == 'project_national'
      parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
      if Dir["#{parent_dir}/weather/*.epw"].size < 10
        cli_path = OpenStudio.getOpenStudioCLI
        command = "cd #{parent_dir} && \"#{cli_path}\" tasks.rb download_weather"
        system(command)
      end
    end

    all_results = []
    parent_dir = File.join(top_dir, 'baseline')
    Dir.mkdir(parent_dir) unless File.exist?(parent_dir)

    buildstock_csv = create_buildstock_csv(project_dir, num_samples)
    lib_dir = create_lib_folder(top_dir, project_dir, buildstock_csv)

    Dir["#{top_dir}/workflow-base.osw"].each do |osw|
      osw_basename = File.basename(osw)
      puts "\nWorkflow: #{osw_basename} ...\n"

      osw_dir = File.join(parent_dir, 'osw')
      Dir.mkdir(osw_dir) unless File.exist?(osw_dir)

      xml_dir = File.join(parent_dir, 'xml')
      Dir.mkdir(xml_dir) unless File.exist?(xml_dir)

      (1..num_samples).to_a.each do |building_unit_id|
        puts "\n\tBuilding Unit ID: #{building_unit_id} ...\n\n"

        change_building_unit_id(osw, building_unit_id)
        out_osw, result = RunOSWs.run_and_check(osw, top_dir)
        result['OSW'] = "#{building_unit_id}.osw"
        all_results << result

        # Check workflow was successful
        assert(File.exist?(out_osw))
        data_hash = JSON.parse(File.read(out_osw))
        result['completed_status'] = data_hash['completed_status']

        # Save existing osws and xmls
        ['existing'].each do |scenario|
          ['osw', 'xml'].each do |type|
            from = File.join(top_dir, 'run', "#{scenario}.#{type}")

            dir = osw_dir
            if type == 'xml'
              dir = xml_dir
            end
            to = File.join(dir, "#{building_unit_id}-#{osw_basename.gsub('.osw', '')}-#{scenario}.#{type}")

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

    remove_folders_and_files(lib_dir)

    results_dir = File.join(parent_dir, 'results')
    RunOSWs._rm_path(results_dir)
    RunOSWs.write_summary_results(results_dir, all_results)

    # TODO: assertions on results csv
  end

  def test_samples_osw_upgrades
    project_dir = 'project_testing'
    num_samples = 10

    if project_dir == 'project_national'
      parent_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
      if Dir["#{parent_dir}/weather/*.epw"].size < 10
        cli_path = OpenStudio.getOpenStudioCLI
        command = "cd #{parent_dir} && \"#{cli_path}\" tasks.rb download_weather"
        system(command)
      end
    end

    all_results = []
    parent_dir = File.join(top_dir, 'upgrades')
    Dir.mkdir(parent_dir) unless File.exist?(parent_dir)

    buildstock_csv = create_buildstock_csv(project_dir, num_samples)
    lib_dir = create_lib_folder(top_dir, project_dir, buildstock_csv)

    Dir["#{top_dir}/workflow*.osw"].each do |osw|
      next if osw.include?('base')

      osw_basename = File.basename(osw)
      puts "\nWorkflow: #{osw_basename} ...\n"

      osw_dir = File.join(parent_dir, 'osw')
      Dir.mkdir(osw_dir) unless File.exist?(osw_dir)

      xml_dir = File.join(parent_dir, 'xml')
      Dir.mkdir(xml_dir) unless File.exist?(xml_dir)

      (1..num_samples).to_a.each do |building_unit_id|
        puts "\n\tBuilding Unit ID: #{building_unit_id} ...\n\n"

        change_building_unit_id(osw, building_unit_id)
        out_osw, result = RunOSWs.run_and_check(osw, top_dir)
        result['OSW'] = "#{building_unit_id}.osw"
        all_results << result

        # Check workflow was successful
        assert(File.exist?(out_osw))
        data_hash = JSON.parse(File.read(out_osw))
        result['completed_status'] = data_hash['completed_status']

        # Save existing/upgraded osws and xmls
        ['existing', 'upgraded'].each do |scenario|
          ['osw', 'xml'].each do |type|
            from = File.join(top_dir, 'run', "#{scenario}.#{type}")

            dir = osw_dir
            if type == 'xml'
              dir = xml_dir
            end
            to = File.join(dir, "#{building_unit_id}-#{osw_basename.gsub('.osw', '')}-#{scenario}.#{type}")

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

    remove_folders_and_files(lib_dir)

    results_dir = File.join(parent_dir, 'results')
    RunOSWs._rm_path(results_dir)
    RunOSWs.write_summary_results(results_dir, all_results)

    # TODO: assertions on results csv
  end

  private

  def create_buildstock_csv(project_dir, num_samples)
    outfile = File.join('..', 'test', 'test_samples_osw', 'buildstock.csv')
    r = RunSampling.new
    r.run(project_dir, num_samples, outfile)

    return outfile
  end

  def create_lib_folder(top_dir, project_dir, buildstock_csv)
    lib_dir = File.join(top_dir, '..', '..', 'lib') # at top level
    resources_dir = File.join(top_dir, '..', '..', 'resources')
    housing_characteristics_dir = File.join(top_dir, '..', '..', project_dir, 'housing_characteristics')
    Dir.mkdir(lib_dir) unless File.exist?(lib_dir)
    FileUtils.cp_r(resources_dir, lib_dir)
    FileUtils.cp_r(housing_characteristics_dir, lib_dir)
    FileUtils.cp(File.join(resources_dir, buildstock_csv), File.join(lib_dir, 'housing_characteristics'))
    return lib_dir
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

  def remove_folders_and_files(lib_dir)
    FileUtils.rm_rf(lib_dir) if File.exist?(lib_dir)
    FileUtils.rm_rf(File.join(top_dir, 'run'))
    FileUtils.rm_rf(File.join(top_dir, 'reports'))
    FileUtils.rm_rf(File.join(top_dir, 'generated_files'))
    FileUtils.rm(File.join(top_dir, 'out.osw'))
  end
end
