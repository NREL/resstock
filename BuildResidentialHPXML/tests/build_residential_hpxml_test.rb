# frozen_string_literal: true

require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class BuildResidentialHPXMLTest < MiniTest::Test
  def test_workflows
    # Extra buildings that don't correspond with sample files
    hpxmls_files = {
      # Base files to derive from
      'base-sfd.xml' => nil,
      'base-sfa.xml' => 'base-sfd.xml',
      'base-mf.xml' => 'base-sfd.xml',

      # Extra files to test
      'extra-auto.xml' => 'base-sfd.xml',
      'extra-pv-roofpitch.xml' => 'base-sfd.xml',
      'extra-dhw-solar-latitude.xml' => 'base-sfd.xml',
      'extra-second-refrigerator.xml' => 'base-sfd.xml',
      'extra-second-heating-system-portable-heater-to-heating-system.xml' => 'base-sfd.xml',
      'extra-second-heating-system-fireplace-to-heating-system.xml' => 'base-sfd.xml',
      'extra-second-heating-system-boiler-to-heating-system.xml' => 'base-sfd.xml',
      'extra-second-heating-system-portable-heater-to-heat-pump.xml' => 'base-sfd.xml',
      'extra-second-heating-system-fireplace-to-heat-pump.xml' => 'base-sfd.xml',
      'extra-second-heating-system-boiler-to-heat-pump.xml' => 'base-sfd.xml',
      'extra-enclosure-windows-shading.xml' => 'base-sfd.xml',
      'extra-enclosure-garage-partially-protruded.xml' => 'base-sfd.xml',
      'extra-enclosure-garage-atticroof-conditioned.xml' => 'base-sfd.xml',
      'extra-enclosure-atticroof-conditioned-eaves-gable.xml' => 'base-sfd.xml',
      'extra-enclosure-atticroof-conditioned-eaves-hip.xml' => 'extra-enclosure-atticroof-conditioned-eaves-gable.xml',
      'extra-zero-refrigerator-kwh.xml' => 'base-sfd.xml',
      'extra-zero-extra-refrigerator-kwh.xml' => 'base-sfd.xml',
      'extra-zero-freezer-kwh.xml' => 'base-sfd.xml',
      'extra-zero-clothes-washer-kwh.xml' => 'base-sfd.xml',
      'extra-zero-dishwasher-kwh.xml' => 'base-sfd.xml',
      'extra-sfa-atticroof-flat.xml' => 'base-sfa.xml',
      'extra-gas-pool-heater-with-zero-kwh.xml' => 'base-sfd.xml',
      'extra-gas-hot-tub-heater-with-zero-kwh.xml' => 'base-sfd.xml',
      'extra-no-rim-joists.xml' => 'base-sfd.xml',
      'extra-iecc-zone-different-than-epw.xml' => 'base-sfd.xml',
      'extra-state-code-different-than-epw.xml' => 'base-sfd.xml',

      'extra-sfa-atticroof-conditioned-eaves-gable.xml' => 'extra-sfa-slab.xml',
      'extra-sfa-atticroof-conditioned-eaves-hip.xml' => 'extra-sfa-atticroof-conditioned-eaves-gable.xml',
      'extra-mf-eaves.xml' => 'extra-mf-slab.xml',

      'extra-sfa-slab.xml' => 'base-sfa.xml',
      'extra-sfa-vented-crawlspace.xml' => 'base-sfa.xml',
      'extra-sfa-unvented-crawlspace.xml' => 'base-sfa.xml',
      'extra-sfa-conditioned-crawlspace.xml' => 'base-sfa.xml',
      'extra-sfa-unconditioned-basement.xml' => 'base-sfa.xml',

      'extra-sfa-rear-units.xml' => 'base-sfa.xml',
      'extra-sfa-exterior-corridor.xml' => 'base-sfa.xml',

      'extra-sfa-slab-middle.xml' => 'extra-sfa-slab.xml',
      'extra-sfa-slab-right.xml' => 'extra-sfa-slab.xml',
      'extra-sfa-vented-crawlspace-middle.xml' => 'extra-sfa-vented-crawlspace.xml',
      'extra-sfa-vented-crawlspace-right.xml' => 'extra-sfa-vented-crawlspace.xml',
      'extra-sfa-unvented-crawlspace-middle.xml' => 'extra-sfa-unvented-crawlspace.xml',
      'extra-sfa-unvented-crawlspace-right.xml' => 'extra-sfa-unvented-crawlspace.xml',
      'extra-sfa-unconditioned-basement-middle.xml' => 'extra-sfa-unconditioned-basement.xml',
      'extra-sfa-unconditioned-basement-right.xml' => 'extra-sfa-unconditioned-basement.xml',

      'extra-mf-slab.xml' => 'base-mf.xml',
      'extra-mf-vented-crawlspace.xml' => 'base-mf.xml',
      'extra-mf-unvented-crawlspace.xml' => 'base-mf.xml',

      'extra-mf-rear-units.xml' => 'base-mf.xml',
      'extra-mf-exterior-corridor.xml' => 'base-mf.xml',

      'extra-mf-slab-left-bottom.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-left-middle.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-left-top.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-middle-bottom.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-middle-middle.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-middle-top.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-right-bottom.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-right-middle.xml' => 'extra-mf-slab.xml',
      'extra-mf-slab-right-top.xml' => 'extra-mf-slab.xml',
      'extra-mf-vented-crawlspace-left-bottom.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-left-middle.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-left-top.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-middle-bottom.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-middle-middle.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-middle-top.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-right-bottom.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-right-middle.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-vented-crawlspace-right-top.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-left-bottom.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-left-middle.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-left-top.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-middle-bottom.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-middle-middle.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-middle-top.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-right-bottom.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-right-middle.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-right-top.xml' => 'extra-mf-unvented-crawlspace.xml',

      'extra-mf-slab-rear-units.xml' => 'extra-mf-slab.xml',
      'extra-mf-vented-crawlspace-rear-units.xml' => 'extra-mf-vented-crawlspace.xml',
      'extra-mf-unvented-crawlspace-rear-units.xml' => 'extra-mf-unvented-crawlspace.xml',
      'extra-mf-slab-left-bottom-rear-units.xml' => 'extra-mf-slab-left-bottom.xml',
      'extra-mf-slab-left-middle-rear-units.xml' => 'extra-mf-slab-left-middle.xml',
      'extra-mf-slab-left-top-rear-units.xml' => 'extra-mf-slab-left-top.xml',
      'extra-mf-slab-middle-bottom-rear-units.xml' => 'extra-mf-slab-middle-bottom.xml',
      'extra-mf-slab-middle-middle-rear-units.xml' => 'extra-mf-slab-middle-middle.xml',
      'extra-mf-slab-middle-top-rear-units.xml' => 'extra-mf-slab-middle-top.xml',
      'extra-mf-slab-right-bottom-rear-units.xml' => 'extra-mf-slab-right-bottom.xml',
      'extra-mf-slab-right-middle-rear-units.xml' => 'extra-mf-slab-right-middle.xml',
      'extra-mf-slab-right-top-rear-units.xml' => 'extra-mf-slab-right-top.xml',
      'extra-mf-vented-crawlspace-left-bottom-rear-units.xml' => 'extra-mf-vented-crawlspace-left-bottom.xml',
      'extra-mf-vented-crawlspace-left-middle-rear-units.xml' => 'extra-mf-vented-crawlspace-left-middle.xml',
      'extra-mf-vented-crawlspace-left-top-rear-units.xml' => 'extra-mf-vented-crawlspace-left-top.xml',
      'extra-mf-vented-crawlspace-middle-bottom-rear-units.xml' => 'extra-mf-vented-crawlspace-middle-bottom.xml',
      'extra-mf-vented-crawlspace-middle-middle-rear-units.xml' => 'extra-mf-vented-crawlspace-middle-middle.xml',
      'extra-mf-vented-crawlspace-middle-top-rear-units.xml' => 'extra-mf-vented-crawlspace-middle-top.xml',
      'extra-mf-vented-crawlspace-right-bottom-rear-units.xml' => 'extra-mf-vented-crawlspace-right-bottom.xml',
      'extra-mf-vented-crawlspace-right-middle-rear-units.xml' => 'extra-mf-vented-crawlspace-right-middle.xml',
      'extra-mf-vented-crawlspace-right-top-rear-units.xml' => 'extra-mf-vented-crawlspace-right-top.xml',
      'extra-mf-unvented-crawlspace-left-bottom-rear-units.xml' => 'extra-mf-unvented-crawlspace-left-bottom.xml',
      'extra-mf-unvented-crawlspace-left-middle-rear-units.xml' => 'extra-mf-unvented-crawlspace-left-middle.xml',
      'extra-mf-unvented-crawlspace-left-top-rear-units.xml' => 'extra-mf-unvented-crawlspace-left-top.xml',
      'extra-mf-unvented-crawlspace-middle-bottom-rear-units.xml' => 'extra-mf-unvented-crawlspace-middle-bottom.xml',
      'extra-mf-unvented-crawlspace-middle-middle-rear-units.xml' => 'extra-mf-unvented-crawlspace-middle-middle.xml',
      'extra-mf-unvented-crawlspace-middle-top-rear-units.xml' => 'extra-mf-unvented-crawlspace-middle-top.xml',
      'extra-mf-unvented-crawlspace-right-bottom-rear-units.xml' => 'extra-mf-unvented-crawlspace-right-bottom.xml',
      'extra-mf-unvented-crawlspace-right-middle-rear-units.xml' => 'extra-mf-unvented-crawlspace-right-middle.xml',
      'extra-mf-unvented-crawlspace-right-top-rear-units.xml' => 'extra-mf-unvented-crawlspace-right-top.xml',

      'error-heating-system-and-heat-pump.xml' => 'base-sfd.xml',
      'error-cooling-system-and-heat-pump.xml' => 'base-sfd.xml',
      'error-non-integer-geometry-num-bathrooms.xml' => 'base-sfd.xml',
      'error-non-integer-ceiling-fan-quantity.xml' => 'base-sfd.xml',
      'error-sfd-conditioned-basement-zero-foundation-height.xml' => 'base-sfd.xml',
      'error-sfd-adiabatic-walls.xml' => 'base-sfd.xml',
      'error-sfa-ambient.xml' => 'base-sfa.xml',
      'error-mf-bottom-crawlspace-zero-foundation-height.xml' => 'base-mf.xml',
      'error-ducts-location-and-areas-not-same-type.xml' => 'base-sfd.xml',
      'error-second-heating-system-serves-total-heat-load.xml' => 'base-sfd.xml',
      'error-second-heating-system-but-no-primary-heating.xml' => 'base-sfd.xml',
      'error-sfa-no-building-num-units.xml' => 'base-sfa.xml',
      'error-sfa-above-apartment.xml' => 'base-sfa.xml',
      'error-sfa-below-apartment.xml' => 'base-sfa.xml',
      'error-sfa-all-adiabatic-walls.xml' => 'base-sfa.xml',
      'error-mf-no-building-num-units.xml' => 'base-mf.xml',
      'error-mf-all-adiabatic-walls.xml' => 'base-mf.xml',
      'error-mf-two-stories.xml' => 'base-mf.xml',
      'error-dhw-indirect-without-boiler.xml' => 'base-sfd.xml',
      'error-foundation-wall-insulation-greater-than-height.xml' => 'base-sfd.xml',
      'error-conditioned-attic-with-one-floor-above-grade.xml' => 'base-sfd.xml',
      'error-zero-number-of-bedrooms.xml' => 'base-sfd.xml',
      'error-sfd-with-shared-system.xml' => 'base-sfd.xml',
      'error-rim-joist-height-but-no-assembly-r.xml' => 'base-sfd.xml',
      'error-rim-joist-assembly-r-but-no-height.xml' => 'base-sfd.xml',

      'warning-non-electric-heat-pump-water-heater.xml' => 'base-sfd.xml',
      'warning-sfd-slab-non-zero-foundation-height.xml' => 'base-sfd.xml',
      'warning-mf-bottom-slab-non-zero-foundation-height.xml' => 'base-mf.xml',
      'warning-slab-non-zero-foundation-height-above-grade.xml' => 'base-sfd.xml',
      'warning-second-heating-system-serves-majority-heat.xml' => 'base-sfd.xml',
      'warning-vented-crawlspace-with-wall-and-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-unvented-crawlspace-with-wall-and-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-unconditioned-basement-with-wall-and-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-vented-attic-with-floor-and-roof-insulation.xml' => 'base-sfd.xml',
      'warning-unvented-attic-with-floor-and-roof-insulation.xml' => 'base-sfd.xml',
      'warning-conditioned-basement-with-ceiling-insulation.xml' => 'base-sfd.xml',
      'warning-conditioned-attic-with-floor-insulation.xml' => 'base-sfd.xml',
      'warning-multipliers-without-tv-plug-loads.xml' => 'base-sfd.xml',
      'warning-multipliers-without-other-plug-loads.xml' => 'base-sfd.xml',
      'warning-multipliers-without-well-pump-plug-loads.xml' => 'base-sfd.xml',
      'warning-multipliers-without-vehicle-plug-loads.xml' => 'base-sfd.xml',
      'warning-multipliers-without-fuel-loads.xml' => 'base-sfd.xml',
    }

    expected_errors = {
      'error-heating-system-and-heat-pump.xml' => 'heating_system_type=Furnace and heat_pump_type=air-to-air',
      'error-cooling-system-and-heat-pump.xml' => 'cooling_system_type=central air conditioner and heat_pump_type=air-to-air',
      'error-non-integer-geometry-num-bathrooms.xml' => 'geometry_unit_num_bathrooms=1.5',
      'error-non-integer-ceiling-fan-quantity.xml' => 'ceiling_fan_quantity=0.5',
      'error-sfd-conditioned-basement-zero-foundation-height.xml' => 'geometry_unit_type=single-family detached and geometry_foundation_type=ConditionedBasement and geometry_foundation_height=0.0',
      'error-sfd-adiabatic-walls.xml' => 'No adiabatic surfaces can be applied to single-family detached homes',
      'error-sfa-ambient.xml' => 'geometry_unit_type=single-family attached and geometry_foundation_type=Ambient',
      'error-mf-conditioned-basement' => 'geometry_unit_type=apartment unit and geometry_foundation_type=ConditionedBasement',
      'error-mf-conditioned-crawlspace' => 'geometry_unit_type=apartment unit and geometry_foundation_type=ConditionedCrawlspace',
      'error-mf-bottom-crawlspace-zero-foundation-height.xml' => 'geometry_unit_type=apartment unit and geometry_foundation_type=UnventedCrawlspace and geometry_foundation_height=0.0',
      'error-ducts-location-and-areas-not-same-type.xml' => 'ducts_supply_location=auto and ducts_supply_surface_area=150.0 and ducts_return_location=attic - unvented and ducts_return_surface_area=50.0',
      'error-second-heating-system-serves-total-heat-load.xml' => 'heating_system_2_type=Fireplace and heating_system_2_fraction_heat_load_served=1.0',
      'error-second-heating-system-but-no-primary-heating.xml' => 'heating_system_type=none and heat_pump_type=none and heating_system_2_type=Fireplace',
      'error-sfa-no-building-num-units.xml' => 'geometry_unit_type=single-family attached and geometry_building_num_units=not provided',
      'error-sfa-above-apartment.xml' => 'Single-family attached buildings cannot be above another unit',
      'error-sfa-below-apartment.xml' => 'Single-family attached buildings cannot be below another unit',
      'error-sfa-all-adiabatic-walls.xml' => 'At least one wall must be set to non-adiabatic',
      'error-mf-no-building-num-units.xml' => 'geometry_unit_type=apartment unit and geometry_building_num_units=not provided',
      'error-mf-all-adiabatic-walls.xml' => 'At least one wall must be set to non-adiabatic',
      'error-mf-two-stories.xml' => 'Apartment units can only have one above grade floor',
      'error-dhw-indirect-without-boiler.xml' => 'water_heater_type=space-heating boiler with storage tank and heating_system_type=Furnace',
      'error-conditioned-attic-with-one-floor-above-grade.xml' => 'geometry_unit_num_floors_above_grade=1 and geometry_attic_type=ConditionedAttic',
      'error-zero-number-of-bedrooms.xml' => 'geometry_unit_num_bedrooms=0',
      'error-sfd-with-shared-system.xml' => 'geometry_unit_type=single-family detached and heating_system_type=Shared Boiler w/ Baseboard',
      'error-rim-joist-height-but-no-assembly-r.xml' => 'geometry_rim_joist_height=9.25 and rim_joist_assembly_r=not provided',
      'error-rim-joist-assembly-r-but-no-height.xml' => 'rim_joist_assembly_r=23.0 and geometry_rim_joist_height=not provided',
    }

    expected_warnings = {
      'warning-non-electric-heat-pump-water-heater.xml' => 'water_heater_type=heat pump water heater and water_heater_fuel_type=natural gas',
      'warning-sfd-slab-non-zero-foundation-height.xml' => 'geometry_unit_type=single-family detached and geometry_foundation_type=SlabOnGrade and geometry_foundation_height=8.0',
      'warning-mf-bottom-slab-non-zero-foundation-height.xml' => 'geometry_unit_type=apartment unit and geometry_foundation_type=SlabOnGrade and geometry_foundation_height=8.0',
      'warning-slab-non-zero-foundation-height-above-grade.xml' => 'geometry_foundation_type=SlabOnGrade and geometry_foundation_height_above_grade=1.0',
      'warning-second-heating-system-serves-majority-heat.xml' => 'heating_system_2_type=Fireplace and heating_system_2_fraction_heat_load_served=0.6',
      'warning-vented-crawlspace-with-wall-and-ceiling-insulation.xml' => 'geometry_foundation_type=VentedCrawlspace and foundation_wall_insulation_r=8.9 and foundation_wall_assembly_r=10.0 and floor_over_foundation_assembly_r=10.0',
      'warning-unvented-crawlspace-with-wall-and-ceiling-insulation.xml' => 'geometry_foundation_type=UnventedCrawlspace and foundation_wall_insulation_r=8.9 and foundation_wall_assembly_r=10.0 and floor_over_foundation_assembly_r=10.0',
      'warning-unconditioned-basement-with-wall-and-ceiling-insulation.xml' => 'geometry_foundation_type=UnconditionedBasement and foundation_wall_insulation_r=8.9 and foundation_wall_assembly_r=10.0 and floor_over_foundation_assembly_r=10.0',
      'warning-vented-attic-with-floor-and-roof-insulation.xml' => 'geometry_attic_type=VentedAttic and ceiling_assembly_r=39.3 and roof_assembly_r=10.0',
      'warning-unvented-attic-with-floor-and-roof-insulation.xml' => 'geometry_attic_type=UnventedAttic and ceiling_assembly_r=39.3 and roof_assembly_r=10.0',
      'warning-conditioned-basement-with-ceiling-insulation.xml' => 'geometry_foundation_type=ConditionedBasement and floor_over_foundation_assembly_r=10.0',
      'warning-conditioned-attic-with-floor-insulation.xml' => 'geometry_attic_type=ConditionedAttic and ceiling_assembly_r=39.3',
      'warning-multipliers-without-tv-plug-loads.xml' => 'misc_plug_loads_television_annual_kwh=0.0 and misc_plug_loads_television_usage_multiplier=1.0',
      'warning-multipliers-without-other-plug-loads.xml' => 'misc_plug_loads_other_annual_kwh=0.0 and misc_plug_loads_other_usage_multiplier=1.0',
      'warning-multipliers-without-well-pump-plug-loads.xml' => 'misc_plug_loads_well_pump_annual_kwh=0.0 and misc_plug_loads_well_pump_usage_multiplier=1.0',
      'warning-multipliers-without-vehicle-plug-loads.xml' => 'misc_plug_loads_vehicle_annual_kwh=0.0 and misc_plug_loads_vehicle_usage_multiplier=1.0',
      'warning-multipliers-without-fuel-loads.xml' => 'misc_fuel_loads_grill_present=false and misc_fuel_loads_grill_usage_multiplier=1.0 and misc_fuel_loads_lighting_present=false and misc_fuel_loads_lighting_usage_multiplier=1.0 and misc_fuel_loads_fireplace_present=false and misc_fuel_loads_fireplace_usage_multiplier=1.0',
    }

    hpxmls_files.each_with_index do |(hpxml_file, parent), i|
      puts "[#{i + 1}/#{hpxmls_files.size}] Testing #{hpxml_file}..."

      begin
        all_hpxml_files = [hpxml_file]
        unless parent.nil?
          all_hpxml_files.unshift(parent)
        end
        while not parent.nil?
          next unless hpxmls_files.keys.include? parent

          unless hpxmls_files[parent].nil?
            all_hpxml_files.unshift(hpxmls_files[parent])
          end
          parent = hpxmls_files[parent]
        end

        args = {}
        all_hpxml_files.each do |f|
          _set_measure_argument_values(f, args)
        end

        File.delete(args['hpxml_path']) if File.exist? args['hpxml_path']
        _test_measure(args, expected_errors[hpxml_file], expected_warnings[hpxml_file])
        File.delete(args['hpxml_path']) if File.exist? args['hpxml_path']
      rescue Exception => e
        puts "\n#{e}\n#{e.backtrace.join('\n')}"
        puts "\nError: Did not successfully generate #{hpxml_file}."
        exit!
      end
    end
  end

  private

  def _set_measure_argument_values(hpxml_file, args)
    args['hpxml_path'] = File.absolute_path(File.join(File.dirname(__FILE__), hpxml_file))

    # Base
    if ['base-sfd.xml'].include? hpxml_file
      args['simulation_control_timestep'] = 60
      args['weather_station_epw_filepath'] = 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'
      args['site_type'] = HPXML::SiteTypeSuburban
      args['geometry_unit_type'] = HPXML::ResidentialTypeSFD
      args['geometry_unit_cfa'] = 2700.0
      args['geometry_unit_left_wall_is_adiabatic'] = false
      args['geometry_unit_right_wall_is_adiabatic'] = false
      args['geometry_unit_front_wall_is_adiabatic'] = false
      args['geometry_unit_back_wall_is_adiabatic'] = false
      args['geometry_unit_num_floors_above_grade'] = 1
      args['geometry_average_ceiling_height'] = 8.0
      args['geometry_unit_orientation'] = 180.0
      args['geometry_unit_aspect_ratio'] = 1.5
      args['geometry_garage_width'] = 0.0
      args['geometry_garage_depth'] = 20.0
      args['geometry_garage_protrusion'] = 0.0
      args['geometry_garage_position'] = 'Right'
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementConditioned
      args['geometry_foundation_height'] = 8.0
      args['geometry_foundation_height_above_grade'] = 1.0
      args['geometry_rim_joist_height'] = 9.25
      args['geometry_roof_type'] = 'gable'
      args['geometry_roof_pitch'] = '6:12'
      args['geometry_attic_type'] = HPXML::AtticTypeUnvented
      args['geometry_eaves_depth'] = 0
      args['geometry_unit_num_bedrooms'] = 3
      args['geometry_unit_num_bathrooms'] = 2
      args['geometry_unit_num_occupants'] = 3
      args['geometry_has_flue_or_chimney'] = Constants.Auto
      args['floor_over_foundation_assembly_r'] = 0
      args['floor_over_garage_assembly_r'] = 0
      args['foundation_wall_type'] = Constants.Auto
      args['foundation_wall_thickness'] = 8.0
      args['foundation_wall_insulation_r'] = 8.9
      args['foundation_wall_insulation_distance_to_top'] = 0.0
      args['foundation_wall_insulation_distance_to_bottom'] = 8.0
      args['rim_joist_assembly_r'] = 23.0
      args['slab_perimeter_insulation_r'] = 0
      args['slab_perimeter_depth'] = 0
      args['slab_under_insulation_r'] = 0
      args['slab_under_width'] = 0
      args['slab_thickness'] = 4.0
      args['slab_carpet_fraction'] = 0.0
      args['slab_carpet_r'] = 0.0
      args['ceiling_assembly_r'] = 39.3
      args['roof_material_type'] = HPXML::RoofTypeAsphaltShingles
      args['roof_color'] = HPXML::ColorMedium
      args['roof_assembly_r'] = 2.3
      args['roof_radiant_barrier'] = false
      args['roof_radiant_barrier_grade'] = 1
      args['neighbor_front_distance'] = 0
      args['neighbor_back_distance'] = 0
      args['neighbor_left_distance'] = 0
      args['neighbor_right_distance'] = 0
      args['neighbor_front_height'] = Constants.Auto
      args['neighbor_back_height'] = Constants.Auto
      args['neighbor_left_height'] = Constants.Auto
      args['neighbor_right_height'] = Constants.Auto
      args['wall_type'] = HPXML::WallTypeWoodStud
      args['wall_siding_type'] = HPXML::SidingTypeWood
      args['wall_color'] = HPXML::ColorMedium
      args['wall_assembly_r'] = 23
      args['window_front_wwr'] = 0
      args['window_back_wwr'] = 0
      args['window_left_wwr'] = 0
      args['window_right_wwr'] = 0
      args['window_area_front'] = 108.0
      args['window_area_back'] = 108.0
      args['window_area_left'] = 72.0
      args['window_area_right'] = 72.0
      args['window_aspect_ratio'] = 1.333
      args['window_fraction_operable'] = 0.67
      args['window_ufactor'] = 0.33
      args['window_shgc'] = 0.45
      args['window_interior_shading_winter'] = 0.85
      args['window_interior_shading_summer'] = 0.7
      args['overhangs_front_depth'] = 0
      args['overhangs_back_depth'] = 0
      args['overhangs_left_depth'] = 0
      args['overhangs_right_depth'] = 0
      args['overhangs_front_distance_to_top_of_window'] = 0
      args['overhangs_back_distance_to_top_of_window'] = 0
      args['overhangs_left_distance_to_top_of_window'] = 0
      args['overhangs_right_distance_to_top_of_window'] = 0
      args['overhangs_front_distance_to_bottom_of_window'] = 0
      args['overhangs_back_distance_to_bottom_of_window'] = 0
      args['overhangs_left_distance_to_bottom_of_window'] = 0
      args['overhangs_right_distance_to_bottom_of_window'] = 0
      args['skylight_area_front'] = 0
      args['skylight_area_back'] = 0
      args['skylight_area_left'] = 0
      args['skylight_area_right'] = 0
      args['skylight_ufactor'] = 0.33
      args['skylight_shgc'] = 0.45
      args['door_area'] = 40.0
      args['door_rvalue'] = 4.4
      args['air_leakage_units'] = HPXML::UnitsACH
      args['air_leakage_house_pressure'] = 50
      args['air_leakage_value'] = 3
      args['site_shielding_of_home'] = Constants.Auto
      args['heating_system_type'] = HPXML::HVACTypeFurnace
      args['heating_system_fuel'] = HPXML::FuelTypeNaturalGas
      args['heating_system_heating_efficiency'] = 0.92
      args['heating_system_heating_capacity'] = 36000.0
      args['heating_system_fraction_heat_load_served'] = 1
      args['cooling_system_type'] = HPXML::HVACTypeCentralAirConditioner
      args['cooling_system_cooling_efficiency_type'] = HPXML::UnitsSEER
      args['cooling_system_cooling_efficiency'] = 13.0
      args['cooling_system_cooling_compressor_type'] = HPXML::HVACCompressorTypeSingleStage
      args['cooling_system_cooling_sensible_heat_fraction'] = 0.73
      args['cooling_system_cooling_capacity'] = 24000.0
      args['cooling_system_fraction_cool_load_served'] = 1
      args['cooling_system_is_ducted'] = false
      args['heat_pump_type'] = 'none'
      args['heat_pump_heating_efficiency_type'] = HPXML::UnitsHSPF
      args['heat_pump_heating_efficiency'] = 7.7
      args['heat_pump_cooling_efficiency_type'] = HPXML::UnitsSEER
      args['heat_pump_cooling_efficiency'] = 13.0
      args['heat_pump_cooling_compressor_type'] = HPXML::HVACCompressorTypeSingleStage
      args['heat_pump_cooling_sensible_heat_fraction'] = 0.73
      args['heat_pump_heating_capacity'] = 36000.0
      args['heat_pump_heating_capacity_17_f'] = Constants.Auto
      args['heat_pump_cooling_capacity'] = 36000.0
      args['heat_pump_fraction_heat_load_served'] = 1
      args['heat_pump_fraction_cool_load_served'] = 1
      args['heat_pump_backup_type'] = HPXML::HeatPumpBackupTypeIntegrated
      args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
      args['heat_pump_backup_heating_efficiency'] = 1
      args['heat_pump_backup_heating_capacity'] = 36000.0
      args['hvac_control_heating_weekday_setpoint'] = 68
      args['hvac_control_heating_weekend_setpoint'] = 68
      args['hvac_control_cooling_weekday_setpoint'] = 78
      args['hvac_control_cooling_weekend_setpoint'] = 78
      args['ducts_leakage_units'] = HPXML::UnitsCFM25
      args['ducts_supply_leakage_to_outside_value'] = 75.0
      args['ducts_return_leakage_to_outside_value'] = 25.0
      args['ducts_supply_insulation_r'] = 4.0
      args['ducts_return_insulation_r'] = 0.0
      args['ducts_supply_location'] = HPXML::LocationAtticUnvented
      args['ducts_return_location'] = HPXML::LocationAtticUnvented
      args['ducts_supply_surface_area'] = 150.0
      args['ducts_return_surface_area'] = 50.0
      args['ducts_number_of_return_registers'] = 2
      args['heating_system_2_type'] = 'none'
      args['heating_system_2_fuel'] = HPXML::FuelTypeElectricity
      args['heating_system_2_heating_efficiency'] = 1.0
      args['heating_system_2_heating_capacity'] = Constants.Auto
      args['heating_system_2_fraction_heat_load_served'] = 0.25
      args['mech_vent_fan_type'] = 'none'
      args['mech_vent_flow_rate'] = 110
      args['mech_vent_hours_in_operation'] = 24
      args['mech_vent_recovery_efficiency_type'] = 'Unadjusted'
      args['mech_vent_total_recovery_efficiency'] = 0.48
      args['mech_vent_sensible_recovery_efficiency'] = 0.72
      args['mech_vent_fan_power'] = 30
      args['mech_vent_num_units_served'] = 1
      args['mech_vent_2_fan_type'] = 'none'
      args['mech_vent_2_flow_rate'] = 110
      args['mech_vent_2_hours_in_operation'] = 24
      args['mech_vent_2_recovery_efficiency_type'] = 'Unadjusted'
      args['mech_vent_2_total_recovery_efficiency'] = 0.48
      args['mech_vent_2_sensible_recovery_efficiency'] = 0.72
      args['mech_vent_2_fan_power'] = 30
      args['kitchen_fans_quantity'] = 0
      args['bathroom_fans_quantity'] = 0
      args['whole_house_fan_present'] = false
      args['whole_house_fan_flow_rate'] = 4500
      args['whole_house_fan_power'] = 300
      args['water_heater_type'] = HPXML::WaterHeaterTypeStorage
      args['water_heater_fuel_type'] = HPXML::FuelTypeElectricity
      args['water_heater_location'] = HPXML::LocationLivingSpace
      args['water_heater_tank_volume'] = 40
      args['water_heater_efficiency_type'] = 'EnergyFactor'
      args['water_heater_efficiency'] = 0.95
      args['water_heater_recovery_efficiency'] = 0.76
      args['water_heater_heating_capacity'] = 18767
      args['water_heater_standby_loss'] = 0
      args['water_heater_jacket_rvalue'] = 0
      args['water_heater_setpoint_temperature'] = 125
      args['water_heater_num_units_served'] = 1
      args['hot_water_distribution_system_type'] = HPXML::DHWDistTypeStandard
      args['hot_water_distribution_standard_piping_length'] = 50
      args['hot_water_distribution_recirc_control_type'] = HPXML::DHWRecirControlTypeNone
      args['hot_water_distribution_recirc_piping_length'] = 50
      args['hot_water_distribution_recirc_branch_piping_length'] = 50
      args['hot_water_distribution_recirc_pump_power'] = 50
      args['hot_water_distribution_pipe_r'] = 0.0
      args['dwhr_facilities_connected'] = 'none'
      args['dwhr_equal_flow'] = true
      args['dwhr_efficiency'] = 0.55
      args['water_fixtures_shower_low_flow'] = true
      args['water_fixtures_sink_low_flow'] = false
      args['water_fixtures_usage_multiplier'] = 1.0
      args['solar_thermal_system_type'] = 'none'
      args['solar_thermal_collector_area'] = 40.0
      args['solar_thermal_collector_loop_type'] = HPXML::SolarThermalLoopTypeDirect
      args['solar_thermal_collector_type'] = HPXML::SolarThermalTypeEvacuatedTube
      args['solar_thermal_collector_azimuth'] = 180
      args['solar_thermal_collector_tilt'] = 20
      args['solar_thermal_collector_rated_optical_efficiency'] = 0.5
      args['solar_thermal_collector_rated_thermal_losses'] = 0.2799
      args['solar_thermal_storage_volume'] = Constants.Auto
      args['solar_thermal_solar_fraction'] = 0
      args['pv_system_module_type'] = 'none'
      args['pv_system_location'] = Constants.Auto
      args['pv_system_tracking'] = Constants.Auto
      args['pv_system_array_azimuth'] = 180
      args['pv_system_array_tilt'] = 20
      args['pv_system_max_power_output'] = 4000
      args['pv_system_inverter_efficiency'] = 0.96
      args['pv_system_system_losses_fraction'] = 0.14
      args['pv_system_num_bedrooms_served'] = 3
      args['pv_system_2_module_type'] = 'none'
      args['pv_system_2_location'] = Constants.Auto
      args['pv_system_2_tracking'] = Constants.Auto
      args['pv_system_2_array_azimuth'] = 180
      args['pv_system_2_array_tilt'] = 20
      args['pv_system_2_max_power_output'] = 4000
      args['battery_location'] = 'none'
      args['battery_power'] = Constants.Auto
      args['battery_capacity'] = Constants.Auto
      args['lighting_interior_fraction_cfl'] = 0.4
      args['lighting_interior_fraction_lfl'] = 0.1
      args['lighting_interior_fraction_led'] = 0.25
      args['lighting_interior_usage_multiplier'] = 1.0
      args['lighting_exterior_fraction_cfl'] = 0.4
      args['lighting_exterior_fraction_lfl'] = 0.1
      args['lighting_exterior_fraction_led'] = 0.25
      args['lighting_exterior_usage_multiplier'] = 1.0
      args['lighting_garage_fraction_cfl'] = 0.4
      args['lighting_garage_fraction_lfl'] = 0.1
      args['lighting_garage_fraction_led'] = 0.25
      args['lighting_garage_usage_multiplier'] = 1.0
      args['holiday_lighting_present'] = false
      args['holiday_lighting_daily_kwh'] = Constants.Auto
      args['dehumidifier_type'] = 'none'
      args['dehumidifier_efficiency_type'] = 'EnergyFactor'
      args['dehumidifier_efficiency'] = 1.8
      args['dehumidifier_capacity'] = 40
      args['dehumidifier_rh_setpoint'] = 0.5
      args['dehumidifier_fraction_dehumidification_load_served'] = 1
      args['clothes_washer_location'] = HPXML::LocationLivingSpace
      args['clothes_washer_efficiency_type'] = 'IntegratedModifiedEnergyFactor'
      args['clothes_washer_efficiency'] = 1.21
      args['clothes_washer_rated_annual_kwh'] = 380.0
      args['clothes_washer_label_electric_rate'] = 0.12
      args['clothes_washer_label_gas_rate'] = 1.09
      args['clothes_washer_label_annual_gas_cost'] = 27.0
      args['clothes_washer_label_usage'] = 6.0
      args['clothes_washer_capacity'] = 3.2
      args['clothes_washer_usage_multiplier'] = 1.0
      args['clothes_dryer_location'] = HPXML::LocationLivingSpace
      args['clothes_dryer_fuel_type'] = HPXML::FuelTypeElectricity
      args['clothes_dryer_efficiency_type'] = 'CombinedEnergyFactor'
      args['clothes_dryer_efficiency'] = 3.73
      args['clothes_dryer_vented_flow_rate'] = 150.0
      args['clothes_dryer_usage_multiplier'] = 1.0
      args['dishwasher_location'] = HPXML::LocationLivingSpace
      args['dishwasher_efficiency_type'] = 'RatedAnnualkWh'
      args['dishwasher_efficiency'] = 307
      args['dishwasher_label_electric_rate'] = 0.12
      args['dishwasher_label_gas_rate'] = 1.09
      args['dishwasher_label_annual_gas_cost'] = 22.32
      args['dishwasher_label_usage'] = 4.0
      args['dishwasher_place_setting_capacity'] = 12
      args['dishwasher_usage_multiplier'] = 1.0
      args['refrigerator_location'] = HPXML::LocationLivingSpace
      args['refrigerator_rated_annual_kwh'] = 650.0
      args['refrigerator_usage_multiplier'] = 1.0
      args['extra_refrigerator_location'] = 'none'
      args['extra_refrigerator_rated_annual_kwh'] = Constants.Auto
      args['extra_refrigerator_usage_multiplier'] = 1.0
      args['freezer_location'] = 'none'
      args['freezer_rated_annual_kwh'] = Constants.Auto
      args['freezer_usage_multiplier'] = 1.0
      args['cooking_range_oven_location'] = HPXML::LocationLivingSpace
      args['cooking_range_oven_fuel_type'] = HPXML::FuelTypeElectricity
      args['cooking_range_oven_is_induction'] = false
      args['cooking_range_oven_is_convection'] = false
      args['cooking_range_oven_usage_multiplier'] = 1.0
      args['ceiling_fan_present'] = false
      args['ceiling_fan_efficiency'] = Constants.Auto
      args['ceiling_fan_quantity'] = Constants.Auto
      args['ceiling_fan_cooling_setpoint_temp_offset'] = 0
      args['misc_plug_loads_television_present'] = true
      args['misc_plug_loads_television_annual_kwh'] = 620.0
      args['misc_plug_loads_television_usage_multiplier'] = 1.0
      args['misc_plug_loads_other_annual_kwh'] = 2457.0
      args['misc_plug_loads_other_frac_sensible'] = 0.855
      args['misc_plug_loads_other_frac_latent'] = 0.045
      args['misc_plug_loads_other_usage_multiplier'] = 1.0
      args['misc_plug_loads_well_pump_present'] = false
      args['misc_plug_loads_well_pump_annual_kwh'] = Constants.Auto
      args['misc_plug_loads_well_pump_usage_multiplier'] = 0.0
      args['misc_plug_loads_vehicle_present'] = false
      args['misc_plug_loads_vehicle_annual_kwh'] = Constants.Auto
      args['misc_plug_loads_vehicle_usage_multiplier'] = 0.0
      args['misc_fuel_loads_grill_present'] = false
      args['misc_fuel_loads_grill_fuel_type'] = HPXML::FuelTypeNaturalGas
      args['misc_fuel_loads_grill_annual_therm'] = Constants.Auto
      args['misc_fuel_loads_grill_usage_multiplier'] = 0.0
      args['misc_fuel_loads_lighting_present'] = false
      args['misc_fuel_loads_lighting_fuel_type'] = HPXML::FuelTypeNaturalGas
      args['misc_fuel_loads_lighting_annual_therm'] = Constants.Auto
      args['misc_fuel_loads_lighting_usage_multiplier'] = 0.0
      args['misc_fuel_loads_fireplace_present'] = false
      args['misc_fuel_loads_fireplace_fuel_type'] = HPXML::FuelTypeNaturalGas
      args['misc_fuel_loads_fireplace_annual_therm'] = Constants.Auto
      args['misc_fuel_loads_fireplace_frac_sensible'] = Constants.Auto
      args['misc_fuel_loads_fireplace_frac_latent'] = Constants.Auto
      args['misc_fuel_loads_fireplace_usage_multiplier'] = 0.0
      args['pool_present'] = false
      args['pool_pump_annual_kwh'] = Constants.Auto
      args['pool_pump_usage_multiplier'] = 1.0
      args['pool_heater_type'] = HPXML::HeaterTypeElectricResistance
      args['pool_heater_annual_kwh'] = Constants.Auto
      args['pool_heater_annual_therm'] = Constants.Auto
      args['pool_heater_usage_multiplier'] = 1.0
      args['hot_tub_present'] = false
      args['hot_tub_pump_annual_kwh'] = Constants.Auto
      args['hot_tub_pump_usage_multiplier'] = 1.0
      args['hot_tub_heater_type'] = HPXML::HeaterTypeElectricResistance
      args['hot_tub_heater_annual_kwh'] = Constants.Auto
      args['hot_tub_heater_annual_therm'] = Constants.Auto
      args['hot_tub_heater_usage_multiplier'] = 1.0
    elsif ['base-sfa.xml'].include? hpxml_file
      args['geometry_unit_type'] = HPXML::ResidentialTypeSFA
      args['geometry_unit_cfa'] = 1800.0
      args['geometry_building_num_units'] = 3
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['window_front_wwr'] = 0.18
      args['window_back_wwr'] = 0.18
      args['window_left_wwr'] = 0.18
      args['window_right_wwr'] = 0.18
      args['window_area_front'] = 0
      args['window_area_back'] = 0
      args['window_area_left'] = 0
      args['window_area_right'] = 0
    elsif ['base-mf.xml'].include? hpxml_file
      args['geometry_unit_type'] = HPXML::ResidentialTypeApartment
      args['geometry_unit_cfa'] = 900.0
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementUnconditioned
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_building_num_units'] = 6
      args['window_front_wwr'] = 0.18
      args['window_back_wwr'] = 0.18
      args['window_left_wwr'] = 0.18
      args['window_right_wwr'] = 0.18
      args['window_area_front'] = 0
      args['window_area_back'] = 0
      args['window_area_left'] = 0
      args['window_area_right'] = 0
      args['ducts_supply_leakage_to_outside_value'] = 0.0
      args['ducts_return_leakage_to_outside_value'] = 0.0
      args['ducts_supply_location'] = HPXML::LocationLivingSpace
      args['ducts_return_location'] = HPXML::LocationLivingSpace
      args['ducts_supply_insulation_r'] = 0.0
      args['ducts_number_of_return_registers'] = 1
      args['door_area'] = 20.0
    end

    # Extras
    if ['extra-auto.xml'].include? hpxml_file
      args['geometry_unit_num_occupants'] = Constants.Auto
      args['ducts_supply_location'] = Constants.Auto
      args['ducts_return_location'] = Constants.Auto
      args['ducts_supply_surface_area'] = Constants.Auto
      args['ducts_return_surface_area'] = Constants.Auto
      args['water_heater_location'] = Constants.Auto
      args['water_heater_tank_volume'] = Constants.Auto
      args['hot_water_distribution_standard_piping_length'] = Constants.Auto
      args['clothes_washer_location'] = Constants.Auto
      args['clothes_dryer_location'] = Constants.Auto
      args['refrigerator_location'] = Constants.Auto
    elsif ['extra-pv-roofpitch.xml'].include? hpxml_file
      args['pv_system_module_type'] = HPXML::PVModuleTypeStandard
      args['pv_system_2_module_type'] = HPXML::PVModuleTypeStandard
      args['pv_system_array_tilt'] = 'roofpitch'
      args['pv_system_2_array_tilt'] = 'roofpitch+15'
    elsif ['extra-dhw-solar-latitude.xml'].include? hpxml_file
      args['solar_thermal_system_type'] = HPXML::SolarThermalSystemType
      args['solar_thermal_collector_tilt'] = 'latitude-15'
    elsif ['extra-second-refrigerator.xml'].include? hpxml_file
      args['extra_refrigerator_location'] = HPXML::LocationLivingSpace
    elsif ['extra-second-heating-system-portable-heater-to-heating-system.xml'].include? hpxml_file
      args['heating_system_fuel'] = HPXML::FuelTypeElectricity
      args['heating_system_heating_capacity'] = 48000.0
      args['heating_system_fraction_heat_load_served'] = 0.75
      args['ducts_supply_leakage_to_outside_value'] = 0.0
      args['ducts_return_leakage_to_outside_value'] = 0.0
      args['ducts_supply_location'] = HPXML::LocationLivingSpace
      args['ducts_return_location'] = HPXML::LocationLivingSpace
      args['heating_system_2_type'] = HPXML::HVACTypePortableHeater
      args['heating_system_2_heating_capacity'] = 16000.0
    elsif ['extra-second-heating-system-fireplace-to-heating-system.xml'].include? hpxml_file
      args['heating_system_type'] = HPXML::HVACTypeElectricResistance
      args['heating_system_fuel'] = HPXML::FuelTypeElectricity
      args['heating_system_heating_efficiency'] = 1.0
      args['heating_system_heating_capacity'] = 48000.0
      args['heating_system_fraction_heat_load_served'] = 0.75
      args['cooling_system_type'] = 'none'
      args['heating_system_2_type'] = HPXML::HVACTypeFireplace
      args['heating_system_2_heating_capacity'] = 16000.0
    elsif ['extra-second-heating-system-boiler-to-heating-system.xml'].include? hpxml_file
      args['heating_system_type'] = HPXML::HVACTypeBoiler
      args['heating_system_fraction_heat_load_served'] = 0.75
      args['heating_system_2_type'] = HPXML::HVACTypeBoiler
    elsif ['extra-second-heating-system-portable-heater-to-heat-pump.xml'].include? hpxml_file
      args['heating_system_type'] = 'none'
      args['cooling_system_type'] = 'none'
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
      args['heat_pump_heating_capacity_17_f'] = 22680.0
      args['heat_pump_heating_capacity'] = 48000.0
      args['heat_pump_fraction_heat_load_served'] = 0.75
      args['ducts_supply_leakage_to_outside_value'] = 0.0
      args['ducts_return_leakage_to_outside_value'] = 0.0
      args['ducts_supply_location'] = HPXML::LocationLivingSpace
      args['ducts_return_location'] = HPXML::LocationLivingSpace
      args['heating_system_2_type'] = HPXML::HVACTypePortableHeater
      args['heating_system_2_heating_capacity'] = 16000.0
    elsif ['extra-second-heating-system-fireplace-to-heat-pump.xml'].include? hpxml_file
      args['heating_system_type'] = 'none'
      args['cooling_system_type'] = 'none'
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpMiniSplit
      args['heat_pump_heating_efficiency'] = 10.0
      args['heat_pump_cooling_efficiency'] = 19.0
      args['heat_pump_heating_capacity'] = 48000.0
      args['heat_pump_is_ducted'] = true
      args['heat_pump_fraction_heat_load_served'] = 0.75
      args['heating_system_2_type'] = HPXML::HVACTypeFireplace
      args['heating_system_2_heating_capacity'] = 16000.0
    elsif ['extra-second-heating-system-boiler-to-heat-pump.xml'].include? hpxml_file
      args['heating_system_type'] = 'none'
      args['cooling_system_type'] = 'none'
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpGroundToAir
      args['heat_pump_heating_efficiency_type'] = HPXML::UnitsCOP
      args['heat_pump_heating_efficiency'] = 3.6
      args['heat_pump_cooling_efficiency_type'] = HPXML::UnitsEER
      args['heat_pump_cooling_efficiency'] = 16.6
      args['heat_pump_fraction_heat_load_served'] = 0.75
      args['heating_system_2_type'] = HPXML::HVACTypeBoiler
    elsif ['extra-enclosure-windows-shading.xml'].include? hpxml_file
      args['window_interior_shading_winter'] = 0.99
      args['window_interior_shading_summer'] = 0.01
      args['window_exterior_shading_winter'] = 0.9
      args['window_exterior_shading_summer'] = 0.1
    elsif ['extra-enclosure-garage-partially-protruded.xml'].include? hpxml_file
      args['geometry_garage_width'] = 12
      args['geometry_garage_protrusion'] = 0.5
    elsif ['extra-enclosure-garage-atticroof-conditioned.xml'].include? hpxml_file
      args['geometry_garage_width'] = 30.0
      args['geometry_garage_protrusion'] = 1.0
      args['window_area_front'] = 12.0
      args['window_aspect_ratio'] = 5.0 / 1.5
      args['geometry_unit_cfa'] = 4500.0
      args['geometry_unit_num_floors_above_grade'] = 2
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
      args['floor_over_garage_assembly_r'] = 39.3
      args['ducts_supply_location'] = HPXML::LocationGarage
      args['ducts_return_location'] = HPXML::LocationGarage
    elsif ['extra-enclosure-atticroof-conditioned-eaves-gable.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height'] = 0.0
      args['geometry_foundation_height_above_grade'] = 0.0
      args['foundation_wall_insulation_distance_to_bottom'] = Constants.Auto
      args['geometry_unit_cfa'] = 4500.0
      args['geometry_unit_num_floors_above_grade'] = 2
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
      args['geometry_eaves_depth'] = 2
      args['ducts_supply_location'] = HPXML::LocationUnderSlab
      args['ducts_return_location'] = HPXML::LocationUnderSlab
    elsif ['extra-enclosure-atticroof-conditioned-eaves-hip.xml'].include? hpxml_file
      args['geometry_roof_type'] = 'hip'
    elsif ['extra-zero-refrigerator-kwh.xml'].include? hpxml_file
      args['refrigerator_rated_annual_kwh'] = 0
    elsif ['extra-zero-extra-refrigerator-kwh.xml'].include? hpxml_file
      args['extra_refrigerator_rated_annual_kwh'] = 0
    elsif ['extra-zero-freezer-kwh.xml'].include? hpxml_file
      args['freezer_rated_annual_kwh'] = 0
    elsif ['extra-zero-clothes-washer-kwh.xml'].include? hpxml_file
      args['clothes_washer_rated_annual_kwh'] = 0
      args['clothes_dryer_location'] = 'none'
    elsif ['extra-zero-dishwasher-kwh.xml'].include? hpxml_file
      args['dishwasher_efficiency'] = 0
    elsif ['extra-sfa-atticroof-flat.xml'].include? hpxml_file
      args['geometry_attic_type'] = HPXML::AtticTypeFlatRoof
      args['ducts_supply_leakage_to_outside_value'] = 0.0
      args['ducts_return_leakage_to_outside_value'] = 0.0
      args['ducts_supply_location'] = HPXML::LocationBasementConditioned
      args['ducts_return_location'] = HPXML::LocationBasementConditioned
    elsif ['extra-gas-pool-heater-with-zero-kwh.xml'].include? hpxml_file
      args['pool_present'] = true
      args['pool_heater_type'] = HPXML::HeaterTypeGas
      args['pool_heater_annual_kwh'] = 0
    elsif ['extra-gas-hot-tub-heater-with-zero-kwh.xml'].include? hpxml_file
      args['hot_tub_present'] = true
      args['hot_tub_heater_type'] = HPXML::HeaterTypeGas
      args['hot_tub_heater_annual_kwh'] = 0
    elsif ['extra-no-rim-joists.xml'].include? hpxml_file
      args.delete('geometry_rim_joist_height')
      args.delete('rim_joist_assembly_r')
    elsif ['extra-iecc-zone-different-than-epw.xml'].include? hpxml_file
      args['site_iecc_zone'] = '6B'
    elsif ['extra-state-code-different-than-epw.xml'].include? hpxml_file
      args['site_state_code'] = 'WY'
    elsif ['extra-sfa-atticroof-conditioned-eaves-gable.xml'].include? hpxml_file
      args['geometry_unit_num_floors_above_grade'] = 2
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
      args['geometry_eaves_depth'] = 2
      args['ducts_supply_location'] = HPXML::LocationLivingSpace
      args['ducts_return_location'] = HPXML::LocationLivingSpace
    elsif ['extra-sfa-atticroof-conditioned-eaves-hip.xml'].include? hpxml_file
      args['geometry_roof_type'] = 'hip'
    elsif ['extra-mf-eaves.xml'].include? hpxml_file
      args['geometry_eaves_depth'] = 2
    elsif ['extra-sfa-slab.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height'] = 0.0
      args['geometry_foundation_height_above_grade'] = 0.0
      args['foundation_wall_insulation_distance_to_bottom'] = Constants.Auto
    elsif ['extra-sfa-vented-crawlspace.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceVented
      args['geometry_foundation_height'] = 4.0
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    elsif ['extra-sfa-unvented-crawlspace.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 4.0
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    elsif ['extra-sfa-conditioned-crawlspace.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceConditioned
      args['geometry_foundation_height'] = 4.0
      args['floor_over_foundation_assembly_r'] = 2.1
      args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    elsif ['extra-sfa-unconditioned-basement.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementUnconditioned
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_r'] = 0
      args['foundation_wall_insulation_distance_to_bottom'] = 0.0
    elsif ['extra-sfa-rear-units.xml'].include? hpxml_file
      args['geometry_building_num_units'] = 4
    elsif ['extra-sfa-exterior-corridor.xml'].include? hpxml_file
      args['geometry_building_num_units'] = 4
    elsif ['extra-sfa-slab-middle.xml',
           'extra-sfa-vented-crawlspace-middle.xml',
           'extra-sfa-unvented-crawlspace-middle.xml',
           'extra-sfa-unconditioned-basement-middle.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_right_wall_is_adiabatic'] = true
    elsif ['extra-sfa-slab-right.xml',
           'extra-sfa-vented-crawlspace-right.xml',
           'extra-sfa-unvented-crawlspace-right.xml',
           'extra-sfa-unconditioned-basement-right.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
    elsif ['extra-mf-slab.xml'].include? hpxml_file
      args['geometry_building_num_units'] = 18
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height'] = 0.0
      args['geometry_foundation_height_above_grade'] = 0.0
      args['foundation_wall_insulation_distance_to_bottom'] = Constants.Auto
    elsif ['extra-mf-vented-crawlspace.xml'].include? hpxml_file
      args['geometry_building_num_units'] = 18
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceVented
      args['geometry_foundation_height'] = 4.0
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    elsif ['extra-mf-unvented-crawlspace.xml'].include? hpxml_file
      args['geometry_building_num_units'] = 18
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 4.0
      args['floor_over_foundation_assembly_r'] = 18.7
      args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    elsif ['extra-mf-rear-units.xml'].include? hpxml_file
      args['geometry_building_num_units'] = 18
    elsif ['extra-mf-exterior-corridor.xml'].include? hpxml_file
      args['geometry_building_num_units'] = 18
    elsif ['extra-mf-slab-left-bottom.xml',
           'extra-mf-vented-crawlspace-left-bottom.xml',
           'extra-mf-unvented-crawlspace-left-bottom.xml'].include? hpxml_file
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
    elsif ['extra-mf-slab-left-middle.xml',
           'extra-mf-vented-crawlspace-left-middle.xml',
           'extra-mf-unvented-crawlspace-left-middle.xml'].include? hpxml_file
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    elsif ['extra-mf-slab-left-top.xml',
           'extra-mf-vented-crawlspace-left-top.xml',
           'extra-mf-unvented-crawlspace-left-top.xml'].include? hpxml_file
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    elsif ['extra-mf-slab-middle-bottom.xml',
           'extra-mf-vented-crawlspace-middle-bottom.xml',
           'extra-mf-unvented-crawlspace-middle-bottom.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
    elsif ['extra-mf-slab-middle-middle.xml',
           'extra-mf-vented-crawlspace-middle-middle.xml',
           'extra-mf-unvented-crawlspace-middle-middle.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    elsif ['extra-mf-slab-middle-top.xml',
           'extra-mf-vented-crawlspace-middle-top.xml',
           'extra-mf-unvented-crawlspace-middle-top.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_right_wall_is_adiabatic'] = true
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    elsif ['extra-mf-slab-right-bottom.xml',
           'extra-mf-vented-crawlspace-right-bottom.xml',
           'extra-mf-unvented-crawlspace-right-bottom.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
    elsif ['extra-mf-slab-right-middle.xml',
           'extra-mf-vented-crawlspace-right-middle.xml',
           'extra-mf-unvented-crawlspace-right-middle.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    elsif ['extra-mf-slab-right-top.xml',
           'extra-mf-vented-crawlspace-right-top.xml',
           'extra-mf-unvented-crawlspace-right-top.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    elsif ['extra-mf-slab-rear-units.xml',
           'extra-mf-vented-crawlspace-rear-units.xml',
           'extra-mf-unvented-crawlspace-rear-units.xml',
           'extra-mf-slab-left-bottom-rear-units.xml',
           'extra-mf-slab-left-middle-rear-units.xml',
           'extra-mf-slab-left-top-rear-units.xml',
           'extra-mf-slab-middle-bottom-rear-units.xml',
           'extra-mf-slab-middle-middle-rear-units.xml',
           'extra-mf-slab-middle-top-rear-units.xml',
           'extra-mf-slab-right-bottom-rear-units.xml',
           'extra-mf-slab-right-middle-rear-units.xml',
           'extra-mf-slab-right-top-rear-units.xml',
           'extra-mf-vented-crawlspace-left-bottom-rear-units.xml',
           'extra-mf-vented-crawlspace-left-middle-rear-units.xml',
           'extra-mf-vented-crawlspace-left-top-rear-units.xml',
           'extra-mf-vented-crawlspace-middle-bottom-rear-units.xml',
           'extra-mf-vented-crawlspace-middle-middle-rear-units.xml',
           'extra-mf-vented-crawlspace-middle-top-rear-units.xml',
           'extra-mf-vented-crawlspace-right-bottom-rear-units.xml',
           'extra-mf-vented-crawlspace-right-middle-rear-units.xml',
           'extra-mf-vented-crawlspace-right-top-rear-units.xml',
           'extra-mf-unvented-crawlspace-left-bottom-rear-units.xml',
           'extra-mf-unvented-crawlspace-left-middle-rear-units.xml',
           'extra-mf-unvented-crawlspace-left-top-rear-units.xml',
           'extra-mf-unvented-crawlspace-middle-bottom-rear-units.xml',
           'extra-mf-unvented-crawlspace-middle-middle-rear-units.xml',
           'extra-mf-unvented-crawlspace-middle-top-rear-units.xml',
           'extra-mf-unvented-crawlspace-right-bottom-rear-units.xml',
           'extra-mf-unvented-crawlspace-right-middle-rear-units.xml',
           'extra-mf-unvented-crawlspace-right-top-rear-units.xml'].include? hpxml_file
      args['geometry_unit_front_wall_is_adiabatic'] = true
    end

    # Error
    if ['error-heating-system-and-heat-pump.xml'].include? hpxml_file
      args['cooling_system_type'] = 'none'
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
    elsif ['error-cooling-system-and-heat-pump.xml'].include? hpxml_file
      args['heating_system_type'] = 'none'
      args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
    elsif ['error-non-integer-geometry-num-bathrooms.xml'].include? hpxml_file
      args['geometry_unit_num_bathrooms'] = 1.5
    elsif ['error-non-integer-ceiling-fan-quantity.xml'].include? hpxml_file
      args['ceiling_fan_quantity'] = 0.5
    elsif ['error-sfd-conditioned-basement-zero-foundation-height.xml'].include? hpxml_file
      args['geometry_foundation_height'] = 0.0
      args['foundation_wall_insulation_distance_to_bottom'] = Constants.Auto
    elsif ['error-sfd-adiabatic-walls.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
    elsif ['error-sfa-ambient.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeAmbient
      args.delete('geometry_rim_joist_height')
      args.delete('rim_joist_assembly_r')
    elsif ['error-mf-conditioned-basement'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementConditioned
    elsif ['error-mf-conditioned-crawlspace'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceConditioned
    elsif ['error-mf-bottom-crawlspace-zero-foundation-height.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 0.0
      args['foundation_wall_insulation_distance_to_bottom'] = Constants.Auto
    elsif ['error-ducts-location-and-areas-not-same-type.xml'].include? hpxml_file
      args['ducts_supply_location'] = Constants.Auto
    elsif ['error-second-heating-system-serves-total-heat-load.xml'].include? hpxml_file
      args['heating_system_2_type'] = HPXML::HVACTypeFireplace
      args['heating_system_2_fraction_heat_load_served'] = 1.0
    elsif ['error-second-heating-system-but-no-primary-heating.xml'].include? hpxml_file
      args['heating_system_type'] = 'none'
      args['heating_system_2_type'] = HPXML::HVACTypeFireplace
    elsif ['error-sfa-no-building-num-units.xml'].include? hpxml_file
      args.delete('geometry_building_num_units')
    elsif ['error-sfa-above-apartment.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeAboveApartment
    elsif ['error-sfa-below-apartment.xml'].include? hpxml_file
      args['geometry_attic_type'] = HPXML::AtticTypeBelowApartment
    elsif ['error-sfa-all-adiabatic-walls.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_front_wall_is_adiabatic'] = true
      args['geometry_unit_back_wall_is_adiabatic'] = true
    elsif ['error-mf-no-building-num-units.xml'].include? hpxml_file
      args.delete('geometry_building_num_units')
    elsif ['error-mf-all-adiabatic-walls.xml'].include? hpxml_file
      args['geometry_unit_left_wall_is_adiabatic'] = true
      args['geometry_unit_front_wall_is_adiabatic'] = true
      args['geometry_unit_back_wall_is_adiabatic'] = true
    elsif ['error-mf-two-stories.xml'].include? hpxml_file
      args['geometry_unit_num_floors_above_grade'] = 2
    elsif ['error-dhw-indirect-without-boiler.xml'].include? hpxml_file
      args['water_heater_type'] = HPXML::WaterHeaterTypeCombiStorage
    elsif ['error-conditioned-attic-with-one-floor-above-grade.xml'].include? hpxml_file
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
      args['ceiling_assembly_r'] = 0.0
    elsif ['error-zero-number-of-bedrooms.xml'].include? hpxml_file
      args['geometry_unit_num_bedrooms'] = 0
    elsif ['error-sfd-with-shared-system.xml'].include? hpxml_file
      args['heating_system_type'] = "Shared #{HPXML::HVACTypeBoiler} w/ Baseboard"
    elsif ['error-rim-joist-height-but-no-assembly-r.xml'].include? hpxml_file
      args.delete('rim_joist_assembly_r')
    elsif ['error-rim-joist-assembly-r-but-no-height.xml'].include? hpxml_file
      args.delete('geometry_rim_joist_height')
    end

    # Warning
    if ['warning-non-electric-heat-pump-water-heater.xml'].include? hpxml_file
      args['water_heater_type'] = HPXML::WaterHeaterTypeHeatPump
      args['water_heater_fuel_type'] = HPXML::FuelTypeNaturalGas
      args['water_heater_efficiency'] = 2.3
    elsif ['warning-sfd-slab-non-zero-foundation-height.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height_above_grade'] = 0.0
    elsif ['warning-mf-bottom-slab-non-zero-foundation-height.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height_above_grade'] = 0.0
    elsif ['warning-slab-non-zero-foundation-height-above-grade.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
      args['geometry_foundation_height'] = 0.0
      args['foundation_wall_insulation_distance_to_bottom'] = Constants.Auto
    elsif ['warning-second-heating-system-serves-majority-heat.xml'].include? hpxml_file
      args['heating_system_fraction_heat_load_served'] = 0.4
      args['heating_system_2_type'] = HPXML::HVACTypeFireplace
      args['heating_system_2_fraction_heat_load_served'] = 0.6
    elsif ['warning-vented-crawlspace-with-wall-and-ceiling-insulation.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceVented
      args['geometry_foundation_height'] = 3.0
      args['floor_over_foundation_assembly_r'] = 10
      args['foundation_wall_insulation_distance_to_bottom'] = 0.0
      args['foundation_wall_assembly_r'] = 10
    elsif ['warning-unvented-crawlspace-with-wall-and-ceiling-insulation.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
      args['geometry_foundation_height'] = 3.0
      args['floor_over_foundation_assembly_r'] = 10
      args['foundation_wall_insulation_distance_to_bottom'] = 0.0
      args['foundation_wall_assembly_r'] = 10
    elsif ['warning-unconditioned-basement-with-wall-and-ceiling-insulation.xml'].include? hpxml_file
      args['geometry_foundation_type'] = HPXML::FoundationTypeBasementUnconditioned
      args['floor_over_foundation_assembly_r'] = 10
      args['foundation_wall_assembly_r'] = 10
    elsif ['warning-vented-attic-with-floor-and-roof-insulation.xml'].include? hpxml_file
      args['geometry_attic_type'] = HPXML::AtticTypeVented
      args['roof_assembly_r'] = 10
      args['ducts_supply_location'] = HPXML::LocationAtticVented
      args['ducts_return_location'] = HPXML::LocationAtticVented
    elsif ['warning-unvented-attic-with-floor-and-roof-insulation.xml'].include? hpxml_file
      args['roof_assembly_r'] = 10
    elsif ['warning-conditioned-basement-with-ceiling-insulation.xml'].include? hpxml_file
      args['floor_over_foundation_assembly_r'] = 10
    elsif ['warning-conditioned-attic-with-floor-insulation.xml'].include? hpxml_file
      args['geometry_unit_num_floors_above_grade'] = 2
      args['geometry_attic_type'] = HPXML::AtticTypeConditioned
      args['ducts_supply_location'] = HPXML::LocationLivingSpace
      args['ducts_return_location'] = HPXML::LocationLivingSpace
    elsif ['warning-multipliers-without-tv-plug-loads.xml'].include? hpxml_file
      args['misc_plug_loads_television_annual_kwh'] = 0.0
    elsif ['warning-multipliers-without-other-plug-loads.xml'].include? hpxml_file
      args['misc_plug_loads_other_annual_kwh'] = 0.0
    elsif ['warning-multipliers-without-well-pump-plug-loads.xml'].include? hpxml_file
      args['misc_plug_loads_well_pump_annual_kwh'] = 0.0
      args['misc_plug_loads_well_pump_usage_multiplier'] = 1.0
    elsif ['warning-multipliers-without-vehicle-plug-loads.xml'].include? hpxml_file
      args['misc_plug_loads_vehicle_annual_kwh'] = 0.0
      args['misc_plug_loads_vehicle_usage_multiplier'] = 1.0
    elsif ['warning-multipliers-without-fuel-loads.xml'].include? hpxml_file
      args['misc_fuel_loads_grill_usage_multiplier'] = 1.0
      args['misc_fuel_loads_lighting_usage_multiplier'] = 1.0
      args['misc_fuel_loads_fireplace_usage_multiplier'] = 1.0
    end
  end

  def _test_measure(args_hash, expected_error, expected_warning)
    # create an instance of the measure
    measure = BuildResidentialHPXML.new

    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.has_key?(arg.name)
        retval = temp_arg_var.setValue(args_hash[arg.name])
        if not retval # Try passing as string instead
          assert(temp_arg_var.setValue(args_hash[arg.name].to_s))
        end
      else
        next if !arg.required

        fail "Did not provide required argument: #{arg.name}"
      end
      argument_map[arg.name] = temp_arg_var
    end
    args_hash.keys.each do |arg_name|
      next if argument_map.keys.include? arg_name

      fail "Unexpected argument name: #{arg_name}"
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # assert whether it ran correctly
    if expected_error.nil?
      # show the output
      show_output(result) unless result.value.valueName == 'Success'

      assert_equal('Success', result.value.valueName)
      assert(File.exist?(args_hash['hpxml_path']))
    else
      assert_equal('Fail', result.value.valueName)
      assert(!File.exist?(args_hash['hpxml_path']))
    end

    # check warnings/errors
    if not expected_error.nil?
      if runner.result.stepErrors.select { |s| s == expected_error }.size <= 0
        runner.result.stepErrors.each do |s|
          puts "ERROR: #{s}"
        end
      end
      assert(runner.result.stepErrors.select { |s| s == expected_error }.size > 0)
    end
    if not expected_warning.nil?
      if runner.result.stepWarnings.select { |s| s == expected_warning }.size <= 0
        runner.result.stepErrors.each do |s|
          puts "WARNING: #{s}"
        end
      end
      assert(runner.result.stepWarnings.select { |s| s == expected_warning }.size > 0)
    end
  end
end
