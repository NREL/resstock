# frozen_string_literal: true

require 'openstudio'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/minitest_helper'
require_relative '../../../resources/hpxml-measures/HPXMLtoOpenStudio/resources/hpxml'
require_relative '../measure.rb'
require 'csv'

class ResStockArgumentsTest < Minitest::Test
  def test_options_lookup_assignment
    resources_dir = File.absolute_path(File.join(File.dirname(__FILE__), '../../../resources'))
    lookup_file = File.join(resources_dir, 'options_lookup.tsv')
    lookup_csv_data = CSV.open(lookup_file, col_sep: "\t").each.to_a

    lookup_arguments = []
    lookup_csv_data.each do |lookup_row|
      next if lookup_row[2] != 'ResStockArguments'

      lookup_row[3..-1].each do |argument_value|
        argument, _value = argument_value.split('=')
        lookup_arguments << argument if !lookup_arguments.include?(argument)
      end
    end

    measure = ResStockArguments.new
    model = OpenStudio::Model::Model.new
    resstock_arguments = []
    measure.arguments(model).each do |arg|
      next if arg.name.start_with?('emissions_')
      next if arg.name.start_with?('utility_bill_')
      next if arg.name.start_with?('additional_properties')
      next if arg.name.start_with?('apply_defaults')
      next if arg.name.start_with?('apply_validation')
      next if arg.name.start_with?('combine_like_surfaces')
      next if arg.name.start_with?('schedules_')
      next if arg.name.start_with?('simulation_control_')
      next if arg.name.start_with?('air_leakage_has_flue_or_chimney_in_conditioned_space')
      next if arg.name.start_with?('heating_system_actual_cfm_per_ton')
      next if arg.name.start_with?('heating_system_rated_cfm_per_ton')

      resstock_arguments << arg.name
    end

    resstock_arguments_extras = resstock_arguments - lookup_arguments
    puts resstock_arguments_extras.sort
    assert_equal(0, resstock_arguments_extras.size)
  end
end
