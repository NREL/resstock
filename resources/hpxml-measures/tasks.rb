# frozen_string_literal: true

def create_hpxmls
  require_relative 'HPXMLtoOpenStudio/resources/constants'
  require_relative 'HPXMLtoOpenStudio/resources/hpxml'
  require_relative 'HPXMLtoOpenStudio/resources/meta_measure'

  this_dir = File.dirname(__FILE__)
  tests_dir = File.join(this_dir, 'workflow/sample_files')

  # Hash of HPXML -> Parent HPXML
  hpxmls_files = {
    'base.xml' => nil,

    'ASHRAE_Standard_140/L100AC.xml' => nil,
    'ASHRAE_Standard_140/L100AL.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L110AC.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L110AL.xml' => 'ASHRAE_Standard_140/L100AL.xml',
    'ASHRAE_Standard_140/L120AC.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L120AL.xml' => 'ASHRAE_Standard_140/L100AL.xml',
    'ASHRAE_Standard_140/L130AC.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L130AL.xml' => 'ASHRAE_Standard_140/L100AL.xml',
    'ASHRAE_Standard_140/L140AC.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L140AL.xml' => 'ASHRAE_Standard_140/L100AL.xml',
    'ASHRAE_Standard_140/L150AC.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L150AL.xml' => 'ASHRAE_Standard_140/L100AL.xml',
    'ASHRAE_Standard_140/L160AC.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L160AL.xml' => 'ASHRAE_Standard_140/L100AL.xml',
    'ASHRAE_Standard_140/L170AC.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L170AL.xml' => 'ASHRAE_Standard_140/L100AL.xml',
    'ASHRAE_Standard_140/L200AC.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L200AL.xml' => 'ASHRAE_Standard_140/L100AL.xml',
    'ASHRAE_Standard_140/L302XC.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L322XC.xml' => 'ASHRAE_Standard_140/L100AC.xml',
    'ASHRAE_Standard_140/L155AC.xml' => 'ASHRAE_Standard_140/L150AC.xml',
    'ASHRAE_Standard_140/L155AL.xml' => 'ASHRAE_Standard_140/L150AL.xml',
    'ASHRAE_Standard_140/L202AC.xml' => 'ASHRAE_Standard_140/L200AC.xml',
    'ASHRAE_Standard_140/L202AL.xml' => 'ASHRAE_Standard_140/L200AL.xml',
    'ASHRAE_Standard_140/L304XC.xml' => 'ASHRAE_Standard_140/L302XC.xml',
    'ASHRAE_Standard_140/L324XC.xml' => 'ASHRAE_Standard_140/L322XC.xml',

    'base-appliances-coal.xml' => 'base.xml',
    'base-appliances-dehumidifier.xml' => 'base-location-dallas-tx.xml',
    'base-appliances-dehumidifier-ief-portable.xml' => 'base-appliances-dehumidifier.xml',
    'base-appliances-dehumidifier-ief-whole-home.xml' => 'base-appliances-dehumidifier-ief-portable.xml',
    'base-appliances-dehumidifier-multiple.xml' => 'base-appliances-dehumidifier.xml',
    'base-appliances-gas.xml' => 'base.xml',
    'base-appliances-modified.xml' => 'base.xml',
    'base-appliances-none.xml' => 'base.xml',
    'base-appliances-oil.xml' => 'base.xml',
    'base-appliances-propane.xml' => 'base.xml',
    'base-appliances-wood.xml' => 'base.xml',
    'base-atticroof-cathedral.xml' => 'base.xml',
    'base-atticroof-conditioned.xml' => 'base.xml',
    'base-atticroof-flat.xml' => 'base.xml',
    'base-atticroof-radiant-barrier.xml' => 'base-location-dallas-tx.xml',
    'base-atticroof-unvented-insulated-roof.xml' => 'base.xml',
    'base-atticroof-vented.xml' => 'base.xml',
    'base-bldgtype-multifamily.xml' => 'base.xml',
    'base-bldgtype-multifamily-adjacent-to-multifamily-buffer-space.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-adjacent-to-multiple.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-adjacent-to-non-freezing-space.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-adjacent-to-other-heated-space.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-adjacent-to-other-housing-unit.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-boiler-chiller-baseboard.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-boiler-chiller-fan-coil.xml' => 'base-bldgtype-multifamily-shared-boiler-chiller-baseboard.xml',
    'base-bldgtype-multifamily-shared-boiler-chiller-fan-coil-ducted.xml' => 'base-bldgtype-multifamily-shared-boiler-chiller-fan-coil.xml',
    'base-bldgtype-multifamily-shared-boiler-chiller-water-loop-heat-pump.xml' => 'base-bldgtype-multifamily-shared-boiler-chiller-baseboard.xml',
    'base-bldgtype-multifamily-shared-boiler-cooling-tower-water-loop-heat-pump.xml' => 'base-bldgtype-multifamily-shared-boiler-chiller-water-loop-heat-pump.xml',
    'base-bldgtype-multifamily-shared-boiler-only-baseboard.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-boiler-only-fan-coil.xml' => 'base-bldgtype-multifamily-shared-boiler-only-baseboard.xml',
    'base-bldgtype-multifamily-shared-boiler-only-fan-coil-ducted.xml' => 'base-bldgtype-multifamily-shared-boiler-only-fan-coil.xml',
    'base-bldgtype-multifamily-shared-boiler-only-fan-coil-eae.xml' => 'base-bldgtype-multifamily-shared-boiler-only-fan-coil.xml',
    'base-bldgtype-multifamily-shared-boiler-only-water-loop-heat-pump.xml' => 'base-bldgtype-multifamily-shared-boiler-only-baseboard.xml',
    'base-bldgtype-multifamily-shared-chiller-only-baseboard.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-chiller-only-fan-coil.xml' => 'base-bldgtype-multifamily-shared-chiller-only-baseboard.xml',
    'base-bldgtype-multifamily-shared-chiller-only-fan-coil-ducted.xml' => 'base-bldgtype-multifamily-shared-chiller-only-fan-coil.xml',
    'base-bldgtype-multifamily-shared-chiller-only-water-loop-heat-pump.xml' => 'base-bldgtype-multifamily-shared-chiller-only-baseboard.xml',
    'base-bldgtype-multifamily-shared-cooling-tower-only-water-loop-heat-pump.xml' => 'base-bldgtype-multifamily-shared-chiller-only-water-loop-heat-pump.xml',
    'base-bldgtype-multifamily-shared-generator.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-ground-loop-ground-to-air-heat-pump.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-laundry-room.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-mechvent.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-mechvent-multiple.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-mechvent-preconditioning.xml' => 'base-bldgtype-multifamily-shared-mechvent.xml',
    'base-bldgtype-multifamily-shared-pv.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-water-heater.xml' => 'base-bldgtype-multifamily.xml',
    'base-bldgtype-multifamily-shared-water-heater-recirc.xml' => 'base-bldgtype-multifamily-shared-water-heater.xml',
    'base-bldgtype-single-family-attached.xml' => 'base.xml',
    'base-bldgtype-single-family-attached-2stories.xml' => 'base-bldgtype-single-family-attached.xml',
    'base-dhw-combi-tankless.xml' => 'base-dhw-indirect.xml',
    'base-dhw-combi-tankless-outside.xml' => 'base-dhw-combi-tankless.xml',
    'base-dhw-desuperheater.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'base-dhw-desuperheater-2-speed.xml' => 'base-hvac-central-ac-only-2-speed.xml',
    'base-dhw-desuperheater-gshp.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'base-dhw-desuperheater-hpwh.xml' => 'base-dhw-tank-heat-pump.xml',
    'base-dhw-desuperheater-tankless.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'base-dhw-desuperheater-var-speed.xml' => 'base-hvac-central-ac-only-var-speed.xml',
    'base-dhw-dwhr.xml' => 'base.xml',
    'base-dhw-indirect.xml' => 'base-hvac-boiler-gas-only.xml',
    'base-dhw-indirect-dse.xml' => 'base-dhw-indirect.xml',
    'base-dhw-indirect-outside.xml' => 'base-dhw-indirect.xml',
    'base-dhw-indirect-standbyloss.xml' => 'base-dhw-indirect.xml',
    'base-dhw-indirect-with-solar-fraction.xml' => 'base-dhw-indirect.xml',
    'base-dhw-jacket-electric.xml' => 'base.xml',
    'base-dhw-jacket-gas.xml' => 'base-dhw-tank-gas.xml',
    'base-dhw-jacket-hpwh.xml' => 'base-dhw-tank-heat-pump.xml',
    'base-dhw-jacket-indirect.xml' => 'base-dhw-indirect.xml',
    'base-dhw-low-flow-fixtures.xml' => 'base.xml',
    'base-dhw-multiple.xml' => 'base-hvac-boiler-gas-only.xml',
    'base-dhw-none.xml' => 'base.xml',
    'base-dhw-recirc-demand.xml' => 'base.xml',
    'base-dhw-recirc-manual.xml' => 'base.xml',
    'base-dhw-recirc-nocontrol.xml' => 'base.xml',
    'base-dhw-recirc-temperature.xml' => 'base.xml',
    'base-dhw-recirc-timer.xml' => 'base.xml',
    'base-dhw-solar-direct-evacuated-tube.xml' => 'base.xml',
    'base-dhw-solar-direct-flat-plate.xml' => 'base-dhw-solar-indirect-flat-plate.xml',
    'base-dhw-solar-direct-ics.xml' => 'base-dhw-solar-indirect-flat-plate.xml',
    'base-dhw-solar-fraction.xml' => 'base.xml',
    'base-dhw-solar-indirect-flat-plate.xml' => 'base.xml',
    'base-dhw-solar-thermosyphon-flat-plate.xml' => 'base-dhw-solar-indirect-flat-plate.xml',
    'base-dhw-tank-coal.xml' => 'base-dhw-tank-gas.xml',
    'base-dhw-tank-elec-uef.xml' => 'base.xml',
    'base-dhw-tank-gas.xml' => 'base.xml',
    'base-dhw-tank-gas-uef.xml' => 'base-dhw-tank-gas.xml',
    'base-dhw-tank-gas-uef-fhr.xml' => 'base-dhw-tank-gas-uef.xml',
    'base-dhw-tank-gas-outside.xml' => 'base-dhw-tank-gas.xml',
    'base-dhw-tank-heat-pump.xml' => 'base.xml',
    'base-dhw-tank-heat-pump-outside.xml' => 'base-dhw-tank-heat-pump.xml',
    'base-dhw-tank-heat-pump-uef.xml' => 'base-dhw-tank-heat-pump.xml',
    'base-dhw-tank-heat-pump-with-solar.xml' => 'base-dhw-tank-heat-pump.xml',
    'base-dhw-tank-heat-pump-with-solar-fraction.xml' => 'base-dhw-tank-heat-pump.xml',
    'base-dhw-tank-oil.xml' => 'base-dhw-tank-gas.xml',
    'base-dhw-tank-wood.xml' => 'base-dhw-tank-gas.xml',
    'base-dhw-tankless-electric.xml' => 'base.xml',
    'base-dhw-tankless-electric-outside.xml' => 'base-dhw-tankless-electric.xml',
    'base-dhw-tankless-electric-uef.xml' => 'base-dhw-tankless-electric.xml',
    'base-dhw-tankless-gas.xml' => 'base.xml',
    'base-dhw-tankless-gas-uef.xml' => 'base-dhw-tankless-gas.xml',
    'base-dhw-tankless-gas-with-solar.xml' => 'base-dhw-tankless-gas.xml',
    'base-dhw-tankless-gas-with-solar-fraction.xml' => 'base-dhw-tankless-gas.xml',
    'base-dhw-tankless-propane.xml' => 'base-dhw-tankless-gas.xml',
    'base-enclosure-2stories.xml' => 'base.xml',
    'base-enclosure-2stories-garage.xml' => 'base-enclosure-2stories.xml',
    'base-enclosure-beds-1.xml' => 'base.xml',
    'base-enclosure-beds-2.xml' => 'base.xml',
    'base-enclosure-beds-4.xml' => 'base.xml',
    'base-enclosure-beds-5.xml' => 'base.xml',
    'base-enclosure-garage.xml' => 'base.xml',
    'base-enclosure-infil-ach-house-pressure.xml' => 'base.xml',
    'base-enclosure-infil-cfm-house-pressure.xml' => 'base-enclosure-infil-cfm50.xml',
    'base-enclosure-infil-cfm50.xml' => 'base.xml',
    'base-enclosure-infil-flue.xml' => 'base.xml',
    'base-enclosure-infil-natural-ach.xml' => 'base.xml',
    'base-enclosure-orientations.xml' => 'base.xml',
    'base-enclosure-overhangs.xml' => 'base.xml',
    'base-enclosure-rooftypes.xml' => 'base.xml',
    'base-enclosure-skylights.xml' => 'base.xml',
    'base-enclosure-skylights-physical-properties.xml' => 'base-enclosure-skylights.xml',
    'base-enclosure-skylights-shading.xml' => 'base-enclosure-skylights.xml',
    'base-enclosure-split-level.xml' => 'base-foundation-slab.xml',
    'base-enclosure-split-surfaces.xml' => 'base-enclosure-skylights.xml', # Surfaces should collapse via HPXML.collapse_enclosure_surfaces()
    'base-enclosure-split-surfaces2.xml' => 'base-enclosure-skylights.xml', # Surfaces should NOT collapse via HPXML.collapse_enclosure_surfaces()
    'base-enclosure-walltypes.xml' => 'base.xml',
    'base-enclosure-windows-none.xml' => 'base.xml',
    'base-enclosure-windows-physical-properties.xml' => 'base.xml',
    'base-enclosure-windows-shading.xml' => 'base.xml',
    'base-foundation-ambient.xml' => 'base.xml',
    'base-foundation-basement-garage.xml' => 'base.xml',
    'base-foundation-complex.xml' => 'base.xml',
    'base-foundation-conditioned-basement-slab-insulation.xml' => 'base.xml',
    'base-foundation-conditioned-basement-wall-interior-insulation.xml' => 'base.xml',
    'base-foundation-multiple.xml' => 'base-foundation-unconditioned-basement.xml',
    'base-foundation-slab.xml' => 'base.xml',
    'base-foundation-unconditioned-basement.xml' => 'base.xml',
    'base-foundation-unconditioned-basement-above-grade.xml' => 'base-foundation-unconditioned-basement.xml',
    'base-foundation-unconditioned-basement-assembly-r.xml' => 'base-foundation-unconditioned-basement.xml',
    'base-foundation-unconditioned-basement-wall-insulation.xml' => 'base-foundation-unconditioned-basement.xml',
    'base-foundation-unvented-crawlspace.xml' => 'base.xml',
    'base-foundation-vented-crawlspace.xml' => 'base.xml',
    'base-foundation-walkout-basement.xml' => 'base.xml',
    'base-hvac-air-to-air-heat-pump-1-speed.xml' => 'base.xml',
    'base-hvac-air-to-air-heat-pump-1-speed-cooling-only.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-air-to-air-heat-pump-1-speed-heating-only.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-air-to-air-heat-pump-2-speed.xml' => 'base.xml',
    'base-hvac-air-to-air-heat-pump-var-speed.xml' => 'base.xml',
    'base-hvac-autosize.xml' => 'base.xml',
    'base-hvac-autosize-air-to-air-heat-pump-1-speed.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-autosize-air-to-air-heat-pump-1-speed-cooling-only.xml' => 'base-hvac-air-to-air-heat-pump-1-speed-cooling-only.xml',
    'base-hvac-autosize-air-to-air-heat-pump-1-speed-heating-only.xml' => 'base-hvac-air-to-air-heat-pump-1-speed-heating-only.xml',
    'base-hvac-autosize-air-to-air-heat-pump-1-speed-manual-s-oversize-allowances.xml' => 'base-hvac-autosize-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-autosize-air-to-air-heat-pump-2-speed.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'base-hvac-autosize-air-to-air-heat-pump-2-speed-manual-s-oversize-allowances.xml' => 'base-hvac-autosize-air-to-air-heat-pump-2-speed.xml',
    'base-hvac-autosize-air-to-air-heat-pump-var-speed.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'base-hvac-autosize-air-to-air-heat-pump-var-speed-manual-s-oversize-allowances.xml' => 'base-hvac-autosize-air-to-air-heat-pump-var-speed.xml',
    'base-hvac-autosize-boiler-elec-only.xml' => 'base-hvac-boiler-elec-only.xml',
    'base-hvac-autosize-boiler-gas-central-ac-1-speed.xml' => 'base-hvac-boiler-gas-central-ac-1-speed.xml',
    'base-hvac-autosize-boiler-gas-only.xml' => 'base-hvac-boiler-gas-only.xml',
    'base-hvac-autosize-central-ac-only-1-speed.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'base-hvac-autosize-central-ac-only-2-speed.xml' => 'base-hvac-central-ac-only-2-speed.xml',
    'base-hvac-autosize-central-ac-only-var-speed.xml' => 'base-hvac-central-ac-only-var-speed.xml',
    'base-hvac-autosize-central-ac-plus-air-to-air-heat-pump-heating.xml' => 'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml',
    'base-hvac-autosize-dual-fuel-air-to-air-heat-pump-1-speed.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-autosize-dual-fuel-mini-split-heat-pump-ducted.xml' => 'base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml',
    'base-hvac-autosize-elec-resistance-only.xml' => 'base-hvac-elec-resistance-only.xml',
    'base-hvac-autosize-evap-cooler-furnace-gas.xml' => 'base-hvac-evap-cooler-furnace-gas.xml',
    'base-hvac-autosize-floor-furnace-propane-only.xml' => 'base-hvac-floor-furnace-propane-only.xml',
    'base-hvac-autosize-furnace-elec-only.xml' => 'base-hvac-furnace-elec-only.xml',
    'base-hvac-autosize-furnace-gas-central-ac-2-speed.xml' => 'base-hvac-furnace-gas-central-ac-2-speed.xml',
    'base-hvac-autosize-furnace-gas-central-ac-var-speed.xml' => 'base-hvac-furnace-gas-central-ac-var-speed.xml',
    'base-hvac-autosize-furnace-gas-only.xml' => 'base-hvac-furnace-gas-only.xml',
    'base-hvac-autosize-furnace-gas-room-ac.xml' => 'base-hvac-furnace-gas-room-ac.xml',
    'base-hvac-autosize-ground-to-air-heat-pump.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'base-hvac-autosize-ground-to-air-heat-pump-cooling-only.xml' => 'base-hvac-ground-to-air-heat-pump-cooling-only.xml',
    'base-hvac-autosize-ground-to-air-heat-pump-heating-only.xml' => 'base-hvac-ground-to-air-heat-pump-heating-only.xml',
    'base-hvac-autosize-ground-to-air-heat-pump-manual-s-oversize-allowances.xml' => 'base-hvac-autosize-ground-to-air-heat-pump.xml',
    'base-hvac-autosize-mini-split-heat-pump-ducted.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'base-hvac-autosize-mini-split-heat-pump-ducted-cooling-only.xml' => 'base-hvac-mini-split-heat-pump-ducted-cooling-only.xml',
    'base-hvac-autosize-mini-split-heat-pump-ducted-heating-only.xml' => 'base-hvac-mini-split-heat-pump-ducted-heating-only.xml',
    'base-hvac-autosize-mini-split-heat-pump-ducted-manual-s-oversize-allowances.xml' => 'base-hvac-autosize-mini-split-heat-pump-ducted.xml',
    'base-hvac-autosize-mini-split-air-conditioner-only-ducted.xml' => 'base-hvac-mini-split-air-conditioner-only-ducted.xml',
    'base-hvac-autosize-room-ac-only.xml' => 'base-hvac-room-ac-only.xml',
    'base-hvac-autosize-stove-oil-only.xml' => 'base-hvac-stove-oil-only.xml',
    'base-hvac-autosize-wall-furnace-elec-only.xml' => 'base-hvac-wall-furnace-elec-only.xml',
    'base-hvac-boiler-coal-only.xml' => 'base-hvac-boiler-gas-only.xml',
    'base-hvac-boiler-elec-only.xml' => 'base.xml',
    'base-hvac-boiler-gas-central-ac-1-speed.xml' => 'base.xml',
    'base-hvac-boiler-gas-only.xml' => 'base.xml',
    'base-hvac-boiler-oil-only.xml' => 'base-hvac-boiler-gas-only.xml',
    'base-hvac-boiler-propane-only.xml' => 'base-hvac-boiler-gas-only.xml',
    'base-hvac-boiler-wood-only.xml' => 'base-hvac-boiler-gas-only.xml',
    'base-hvac-central-ac-only-1-speed.xml' => 'base.xml',
    'base-hvac-central-ac-only-2-speed.xml' => 'base.xml',
    'base-hvac-central-ac-only-var-speed.xml' => 'base.xml',
    'base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml' => 'base-hvac-central-ac-only-1-speed.xml',
    'base-hvac-dse.xml' => 'base.xml',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml' => 'base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'base-hvac-ducts-leakage-percent.xml' => 'base.xml',
    'base-hvac-ducts-area-fractions.xml' => 'base-enclosure-2stories.xml',
    'base-hvac-elec-resistance-only.xml' => 'base.xml',
    'base-hvac-evap-cooler-furnace-gas.xml' => 'base.xml',
    'base-hvac-evap-cooler-only.xml' => 'base.xml',
    'base-hvac-evap-cooler-only-ducted.xml' => 'base.xml',
    'base-hvac-fireplace-wood-only.xml' => 'base-hvac-stove-oil-only.xml',
    'base-hvac-fixed-heater-gas-only.xml' => 'base.xml',
    'base-hvac-floor-furnace-propane-only.xml' => 'base-hvac-stove-oil-only.xml',
    'base-hvac-furnace-coal-only.xml' => 'base-hvac-furnace-gas-only.xml',
    'base-hvac-furnace-elec-central-ac-1-speed.xml' => 'base.xml',
    'base-hvac-furnace-elec-only.xml' => 'base.xml',
    'base-hvac-furnace-gas-central-ac-2-speed.xml' => 'base.xml',
    'base-hvac-furnace-gas-central-ac-var-speed.xml' => 'base.xml',
    'base-hvac-furnace-gas-only.xml' => 'base.xml',
    'base-hvac-furnace-gas-room-ac.xml' => 'base.xml',
    'base-hvac-furnace-oil-only.xml' => 'base-hvac-furnace-gas-only.xml',
    'base-hvac-furnace-propane-only.xml' => 'base-hvac-furnace-gas-only.xml',
    'base-hvac-furnace-wood-only.xml' => 'base-hvac-furnace-gas-only.xml',
    'base-hvac-furnace-x3-dse.xml' => 'base.xml',
    'base-hvac-ground-to-air-heat-pump.xml' => 'base.xml',
    'base-hvac-ground-to-air-heat-pump-cooling-only.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'base-hvac-ground-to-air-heat-pump-heating-only.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml' => 'base-hvac-air-to-air-heat-pump-1-speed.xml',
    'base-hvac-install-quality-air-to-air-heat-pump-2-speed.xml' => 'base-hvac-air-to-air-heat-pump-2-speed.xml',
    'base-hvac-install-quality-air-to-air-heat-pump-var-speed.xml' => 'base-hvac-air-to-air-heat-pump-var-speed.xml',
    'base-hvac-install-quality-furnace-gas-central-ac-1-speed.xml' => 'base.xml',
    'base-hvac-install-quality-furnace-gas-central-ac-2-speed.xml' => 'base-hvac-furnace-gas-central-ac-2-speed.xml',
    'base-hvac-install-quality-furnace-gas-central-ac-var-speed.xml' => 'base-hvac-furnace-gas-central-ac-var-speed.xml',
    'base-hvac-install-quality-furnace-gas-only.xml' => 'base-hvac-furnace-gas-only.xml',
    'base-hvac-install-quality-ground-to-air-heat-pump.xml' => 'base-hvac-ground-to-air-heat-pump.xml',
    'base-hvac-install-quality-mini-split-heat-pump-ducted.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'base-hvac-install-quality-mini-split-air-conditioner-only-ducted.xml' => 'base-hvac-mini-split-air-conditioner-only-ducted.xml',
    'base-hvac-mini-split-air-conditioner-only-ducted.xml' => 'base.xml',
    'base-hvac-mini-split-air-conditioner-only-ductless.xml' => 'base-hvac-mini-split-air-conditioner-only-ducted.xml',
    'base-hvac-mini-split-heat-pump-ducted.xml' => 'base.xml',
    'base-hvac-mini-split-heat-pump-ducted-cooling-only.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'base-hvac-mini-split-heat-pump-ducted-heating-only.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'base-hvac-mini-split-heat-pump-ductless.xml' => 'base-hvac-mini-split-heat-pump-ducted.xml',
    'base-hvac-multiple.xml' => 'base.xml',
    'base-hvac-none.xml' => 'base.xml',
    'base-hvac-portable-heater-gas-only.xml' => 'base.xml',
    'base-hvac-programmable-thermostat.xml' => 'base.xml',
    'base-hvac-programmable-thermostat-detailed.xml' => 'base-hvac-programmable-thermostat.xml',
    'base-hvac-room-ac-only.xml' => 'base.xml',
    'base-hvac-room-ac-only-33percent.xml' => 'base-hvac-room-ac-only.xml',
    'base-hvac-room-ac-only-ceer.xml' => 'base-hvac-room-ac-only.xml',
    'base-hvac-seasons.xml' => 'base.xml',
    'base-hvac-setpoints.xml' => 'base.xml',
    'base-hvac-stove-oil-only.xml' => 'base.xml',
    'base-hvac-stove-wood-pellets-only.xml' => 'base-hvac-stove-oil-only.xml',
    'base-hvac-undersized.xml' => 'base.xml',
    'base-hvac-undersized-allow-increased-fixed-capacities.xml' => 'base-hvac-undersized.xml',
    'base-hvac-wall-furnace-elec-only.xml' => 'base.xml',
    'base-lighting-ceiling-fans.xml' => 'base.xml',
    'base-lighting-holiday.xml' => 'base.xml',
    'base-lighting-none.xml' => 'base.xml',
    'base-location-AMY-2012.xml' => 'base.xml',
    'base-location-baltimore-md.xml' => 'base-foundation-unvented-crawlspace.xml',
    'base-location-dallas-tx.xml' => 'base-foundation-slab.xml',
    'base-location-duluth-mn.xml' => 'base-foundation-unconditioned-basement.xml',
    'base-location-helena-mt.xml' => 'base.xml',
    'base-location-honolulu-hi.xml' => 'base-foundation-slab.xml',
    'base-location-miami-fl.xml' => 'base-foundation-slab.xml',
    'base-location-phoenix-az.xml' => 'base-foundation-slab.xml',
    'base-location-portland-or.xml' => 'base-foundation-vented-crawlspace.xml',
    'base-mechvent-balanced.xml' => 'base.xml',
    'base-mechvent-bath-kitchen-fans.xml' => 'base.xml',
    'base-mechvent-cfis.xml' => 'base.xml',
    'base-mechvent-cfis-dse.xml' => 'base-hvac-dse.xml',
    'base-mechvent-cfis-evap-cooler-only-ducted.xml' => 'base-hvac-evap-cooler-only-ducted.xml',
    'base-mechvent-erv.xml' => 'base.xml',
    'base-mechvent-erv-atre-asre.xml' => 'base.xml',
    'base-mechvent-exhaust.xml' => 'base.xml',
    'base-mechvent-exhaust-rated-flow-rate.xml' => 'base.xml',
    'base-mechvent-hrv.xml' => 'base.xml',
    'base-mechvent-hrv-asre.xml' => 'base.xml',
    'base-mechvent-multiple.xml' => 'base-mechvent-bath-kitchen-fans.xml',
    'base-mechvent-supply.xml' => 'base.xml',
    'base-mechvent-whole-house-fan.xml' => 'base.xml',
    'base-misc-defaults.xml' => 'base.xml',
    'base-misc-generators.xml' => 'base.xml',
    'base-misc-loads-large-uncommon.xml' => 'base-schedules-simple.xml',
    'base-misc-loads-large-uncommon2.xml' => 'base-misc-loads-large-uncommon.xml',
    'base-misc-loads-none.xml' => 'base.xml',
    'base-misc-neighbor-shading.xml' => 'base.xml',
    'base-misc-shielding-of-home.xml' => 'base.xml',
    'base-misc-usage-multiplier.xml' => 'base.xml',
    'base-multiple-buildings.xml' => 'base.xml',
    'base-pv.xml' => 'base.xml',
    'base-schedules-simple.xml' => 'base.xml',
    'base-schedules-detailed-smooth.xml' => 'base.xml',
    'base-schedules-detailed-stochastic.xml' => 'base.xml',
    'base-schedules-detailed-stochastic-vacancy.xml' => 'base.xml',
    'base-simcontrol-calendar-year-custom.xml' => 'base.xml',
    'base-simcontrol-daylight-saving-custom.xml' => 'base.xml',
    'base-simcontrol-daylight-saving-disabled.xml' => 'base.xml',
    'base-simcontrol-runperiod-1-month.xml' => 'base.xml',
    'base-simcontrol-timestep-10-mins.xml' => 'base.xml',
  }

  puts "Generating #{hpxmls_files.size} HPXML files..."

  hpxml_docs = {}
  hpxmls_files.each_with_index do |(hpxml_file, parent), i|
    puts "[#{i + 1}/#{hpxmls_files.size}] Generating #{hpxml_file}..."

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
        set_measure_argument_values(f, args)
      end

      measures_dir = File.dirname(__FILE__)
      measures = { 'BuildResidentialHPXML' => [args] }
      model = OpenStudio::Model::Model.new
      runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

      # Apply measure
      success = apply_measures(measures_dir, measures, runner, model)

      # Report warnings/errors
      runner.result.stepErrors.each do |s|
        puts "Error: #{s}"
      end

      if not success
        puts "\nError: Did not successfully generate #{hpxml_file}."
        exit!
      end

      if hpxml_file.include? 'ASHRAE_Standard_140'
        hpxml_path = File.absolute_path(File.join(tests_dir, '..', 'tests', hpxml_file))
        hpxml = HPXML.new(hpxml_path: hpxml_path, collapse_enclosure: false)
        apply_hpxml_modification_ashrae_140(hpxml_file, hpxml)
      else
        hpxml_path = File.absolute_path(File.join(tests_dir, hpxml_file))
        hpxml = HPXML.new(hpxml_path: hpxml_path, collapse_enclosure: false)
        apply_hpxml_modification(hpxml_file, hpxml)
      end

      hpxml_doc = hpxml.to_oga()

      if ['base-multiple-buildings.xml'].include? hpxml_file
        # HPXML class doesn't support multiple buildings, so we'll stitch together manually.
        hpxml_element = XMLHelper.get_element(hpxml_doc, '/HPXML')
        building_element = XMLHelper.get_element(hpxml_element, 'Building')
        for i in 2..3
          new_building_element = deep_copy_object(building_element)

          # Make all IDs unique so the HPXML is valid
          new_building_element.each_node do |node|
            next unless node.is_a?(Oga::XML::Element)
            next if XMLHelper.get_attribute_value(node, 'id').nil?

            XMLHelper.add_attribute(node, 'id', "#{XMLHelper.get_attribute_value(node, 'id')}_#{i}")
          end

          hpxml_element.children << new_building_element
        end
      end

      XMLHelper.write_file(hpxml_doc, hpxml_path)
      hpxml_docs[File.basename(hpxml_file)] = deep_copy_object(hpxml_doc)

      # Validate file against HPXML schema
      schemas_dir = File.absolute_path(File.join(File.dirname(__FILE__), 'HPXMLtoOpenStudio/resources'))
      errors = XMLHelper.validate(hpxml_doc.to_s, File.join(schemas_dir, 'HPXML.xsd'), nil)
      if errors.size > 0
        fail "ERRORS: #{errors}"
      end

      # Check for errors
      errors = hpxml.check_for_errors()
      if errors.size > 0
        fail "ERRORS: #{errors}"
      end
    rescue Exception => e
      puts "\n#{e}\n#{e.backtrace.join('\n')}"
      puts "\nError: Did not successfully generate #{hpxml_file}."
      exit!
    end
  end

  puts "\n"

  # Print warnings about extra files
  abs_hpxml_files = []
  dirs = [nil]
  hpxmls_files.keys.each do |hpxml_file|
    abs_hpxml_files << File.absolute_path(File.join(tests_dir, hpxml_file))
    next unless hpxml_file.include? '/'

    dirs << hpxml_file.split('/')[0] + '/'
  end
  dirs.uniq.each do |dir|
    Dir["#{tests_dir}/#{dir}*.xml"].each do |hpxml|
      next if abs_hpxml_files.include? File.absolute_path(hpxml)

      puts "Warning: Extra HPXML file found at #{File.absolute_path(hpxml)}"
    end
  end

  return hpxml_docs
end

def set_measure_argument_values(hpxml_file, args)
  if hpxml_file.include? 'ASHRAE_Standard_140'
    args['hpxml_path'] = "../workflow/tests/#{hpxml_file}"
  else
    args['hpxml_path'] = "../workflow/sample_files/#{hpxml_file}"
  end

  if ['base.xml'].include? hpxml_file
    args['simulation_control_timestep'] = 60
    args['weather_station_epw_filepath'] = 'USA_CO_Denver.Intl.AP.725650_TMY3.epw'
    args['site_type'] = HPXML::SiteTypeSuburban
    args['geometry_unit_type'] = HPXML::ResidentialTypeSFD
    args['geometry_unit_cfa'] = 2700.0
    args['geometry_num_floors_above_grade'] = 1
    args['geometry_average_ceiling_height'] = 8.0
    args['geometry_unit_orientation'] = 180.0
    args['geometry_unit_aspect_ratio'] = 1.5
    args['geometry_corridor_position'] = 'Double-Loaded Interior'
    args['geometry_corridor_width'] = 10.0
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
    args['foundation_wall_insulation_r'] = 8.9
    args['foundation_wall_insulation_distance_to_top'] = 0.0
    args['foundation_wall_insulation_distance_to_bottom'] = 8.0
    args['foundation_wall_thickness'] = 8.0
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
    args['heat_pump_backup_fuel'] = 'none'
    args['heat_pump_backup_heating_efficiency'] = 1
    args['heat_pump_backup_heating_capacity'] = 36000.0
    args['hvac_control_type'] = HPXML::HVACControlTypeManual
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
    args['pv_system_num_units_served'] = 1
    args['pv_system_2_module_type'] = 'none'
    args['pv_system_2_location'] = Constants.Auto
    args['pv_system_2_tracking'] = Constants.Auto
    args['pv_system_2_array_azimuth'] = 180
    args['pv_system_2_array_tilt'] = 20
    args['pv_system_2_max_power_output'] = 4000
    args['pv_system_2_inverter_efficiency'] = 0.96
    args['pv_system_2_system_losses_fraction'] = 0.14
    args['pv_system_2_num_units_served'] = 1
    args['lighting_present'] = true
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
  elsif ['ASHRAE_Standard_140/L100AC.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'USA_CO_Colorado.Springs-Peterson.Field.724660_TMY3.epw'
    args['geometry_unit_type'] = HPXML::ResidentialTypeSFD
    args['geometry_unit_cfa'] = 1539.0
    args['geometry_num_floors_above_grade'] = 1
    args['geometry_average_ceiling_height'] = 8.0
    args['geometry_unit_orientation'] = 180.0
    args['geometry_unit_aspect_ratio'] = 57.0 / 27.0
    args['geometry_corridor_position'] = 'Double-Loaded Interior'
    args['geometry_corridor_width'] = 0
    args['geometry_garage_width'] = 0
    args['geometry_garage_depth'] = 0
    args['geometry_garage_protrusion'] = 0
    args['geometry_garage_position'] = 'Right'
    args['geometry_foundation_type'] = HPXML::FoundationTypeAmbient
    args['geometry_foundation_height'] = 7.25
    args['geometry_foundation_height_above_grade'] = 0.667
    args['geometry_rim_joist_height'] = 9.0
    args['geometry_roof_type'] = 'gable'
    args['geometry_roof_pitch'] = '4:12'
    args['geometry_attic_type'] = HPXML::AtticTypeVented
    args['geometry_eaves_depth'] = 0
    args['geometry_unit_num_bedrooms'] = 3
    args['geometry_unit_num_bathrooms'] = Constants.Auto
    args['geometry_unit_num_occupants'] = 0
    args['geometry_has_flue_or_chimney'] = Constants.Auto
    args['floor_over_foundation_assembly_r'] = 14.15
    args['floor_over_garage_assembly_r'] = 0
    args['foundation_wall_insulation_r'] = 0
    args['foundation_wall_insulation_distance_to_top'] = 0
    args['foundation_wall_insulation_distance_to_bottom'] = 0
    args['foundation_wall_thickness'] = 6.0
    args['rim_joist_assembly_r'] = 5.01
    args['slab_perimeter_insulation_r'] = 0
    args['slab_perimeter_depth'] = 0
    args['slab_under_insulation_r'] = 0
    args['slab_under_width'] = 0
    args['slab_thickness'] = 4.0
    args['slab_carpet_fraction'] = 0
    args['slab_carpet_r'] = 0
    args['ceiling_assembly_r'] = 18.45
    args['roof_material_type'] = HPXML::RoofTypeAsphaltShingles
    args['roof_color'] = HPXML::ColorMedium
    args['roof_assembly_r'] = 1.99
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
    args['wall_assembly_r'] = 11.76
    args['window_front_wwr'] = 0
    args['window_back_wwr'] = 0
    args['window_left_wwr'] = 0
    args['window_right_wwr'] = 0
    args['window_area_front'] = 90
    args['window_area_back'] = 90
    args['window_area_left'] = 45
    args['window_area_right'] = 45
    args['window_aspect_ratio'] = 5.0 / 3.0
    args['window_fraction_operable'] = 0
    args['window_ufactor'] = 1.039
    args['window_shgc'] = 0.67
    args['window_interior_shading_winter'] = 1
    args['window_interior_shading_summer'] = 1
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
    args['skylight_ufactor'] = 0
    args['skylight_shgc'] = 0
    args['door_area'] = 40.0
    args['door_rvalue'] = 3.04
    args['air_leakage_units'] = HPXML::UnitsACHNatural
    args['air_leakage_house_pressure'] = 50
    args['air_leakage_value'] = 0.67
    args['site_shielding_of_home'] = Constants.Auto
    args['heating_system_type'] = 'none'
    args['heating_system_fuel'] = HPXML::FuelTypeNaturalGas
    args['heating_system_heating_efficiency'] = 0
    args['heating_system_heating_capacity'] = Constants.Auto
    args['heating_system_fraction_heat_load_served'] = 0
    args['cooling_system_type'] = 'none'
    args['cooling_system_cooling_efficiency_type'] = HPXML::UnitsSEER
    args['cooling_system_cooling_efficiency'] = 0
    args['cooling_system_cooling_compressor_type'] = HPXML::HVACCompressorTypeSingleStage
    args['cooling_system_cooling_sensible_heat_fraction'] = 0
    args['cooling_system_cooling_capacity'] = Constants.Auto
    args['cooling_system_fraction_cool_load_served'] = 0
    args['cooling_system_is_ducted'] = false
    args['heat_pump_type'] = 'none'
    args['heat_pump_heating_efficiency_type'] = HPXML::UnitsHSPF
    args['heat_pump_heating_efficiency'] = 0
    args['heat_pump_cooling_efficiency_type'] = HPXML::UnitsSEER
    args['heat_pump_cooling_efficiency'] = 0
    args['heat_pump_cooling_compressor_type'] = HPXML::HVACCompressorTypeSingleStage
    args['heat_pump_cooling_sensible_heat_fraction'] = 0
    args['heat_pump_heating_capacity'] = Constants.Auto
    args['heat_pump_heating_capacity_17_f'] = Constants.Auto
    args['heat_pump_cooling_capacity'] = Constants.Auto
    args['heat_pump_fraction_heat_load_served'] = 0
    args['heat_pump_fraction_cool_load_served'] = 0
    args['heat_pump_backup_fuel'] = 'none'
    args['heat_pump_backup_heating_efficiency'] = 0
    args['heat_pump_backup_heating_capacity'] = Constants.Auto
    args['hvac_control_type'] = HPXML::HVACControlTypeManual
    args['hvac_control_heating_weekday_setpoint'] = 68
    args['hvac_control_heating_weekend_setpoint'] = 68
    args['hvac_control_cooling_weekday_setpoint'] = 78
    args['hvac_control_cooling_weekend_setpoint'] = 78
    args['ducts_leakage_units'] = HPXML::UnitsCFM25
    args['ducts_supply_leakage_to_outside_value'] = 0
    args['ducts_return_leakage_to_outside_value'] = 0
    args['ducts_supply_insulation_r'] = 0
    args['ducts_return_insulation_r'] = 0
    args['ducts_supply_location'] = HPXML::LocationLivingSpace
    args['ducts_return_location'] = HPXML::LocationLivingSpace
    args['ducts_supply_surface_area'] = 0
    args['ducts_return_surface_area'] = 0
    args['ducts_number_of_return_registers'] = 0
    args['heating_system_2_type'] = 'none'
    args['heating_system_2_fuel'] = HPXML::FuelTypeElectricity
    args['heating_system_2_heating_efficiency'] = 0
    args['heating_system_2_heating_capacity'] = Constants.Auto
    args['heating_system_2_fraction_heat_load_served'] = 0
    args['mech_vent_fan_type'] = 'none'
    args['mech_vent_flow_rate'] = 0
    args['mech_vent_hours_in_operation'] = 0
    args['mech_vent_recovery_efficiency_type'] = 'Unadjusted'
    args['mech_vent_total_recovery_efficiency'] = 0
    args['mech_vent_sensible_recovery_efficiency'] = 0
    args['mech_vent_fan_power'] = 0
    args['mech_vent_num_units_served'] = 0
    args['mech_vent_2_fan_type'] = 'none'
    args['mech_vent_2_flow_rate'] = 0
    args['mech_vent_2_hours_in_operation'] = 0
    args['mech_vent_2_recovery_efficiency_type'] = 'Unadjusted'
    args['mech_vent_2_total_recovery_efficiency'] = 0
    args['mech_vent_2_sensible_recovery_efficiency'] = 0
    args['mech_vent_2_fan_power'] = 0
    args['kitchen_fans_quantity'] = 0
    args['bathroom_fans_quantity'] = 0
    args['whole_house_fan_present'] = false
    args['whole_house_fan_flow_rate'] = 0
    args['whole_house_fan_power'] = 0
    args['water_heater_type'] = 'none'
    args['water_heater_fuel_type'] = HPXML::FuelTypeElectricity
    args['water_heater_location'] = HPXML::LocationLivingSpace
    args['water_heater_tank_volume'] = 0
    args['water_heater_efficiency_type'] = 'EnergyFactor'
    args['water_heater_efficiency'] = 0
    args['water_heater_recovery_efficiency'] = 0
    args['water_heater_heating_capacity'] = Constants.Auto
    args['water_heater_standby_loss'] = 0
    args['water_heater_jacket_rvalue'] = 0
    args['water_heater_setpoint_temperature'] = 0
    args['water_heater_num_units_served'] = 0
    args['hot_water_distribution_system_type'] = HPXML::DHWDistTypeStandard
    args['hot_water_distribution_standard_piping_length'] = 0
    args['hot_water_distribution_recirc_control_type'] = HPXML::DHWRecirControlTypeNone
    args['hot_water_distribution_recirc_piping_length'] = 0
    args['hot_water_distribution_recirc_branch_piping_length'] = 0
    args['hot_water_distribution_recirc_pump_power'] = 0
    args['hot_water_distribution_pipe_r'] = 0
    args['dwhr_facilities_connected'] = 'none'
    args['dwhr_equal_flow'] = true
    args['dwhr_efficiency'] = 0
    args['water_fixtures_shower_low_flow'] = false
    args['water_fixtures_sink_low_flow'] = false
    args['water_fixtures_usage_multiplier'] = 0
    args['solar_thermal_system_type'] = 'none'
    args['solar_thermal_collector_area'] = 0
    args['solar_thermal_collector_loop_type'] = HPXML::SolarThermalLoopTypeDirect
    args['solar_thermal_collector_type'] = HPXML::SolarThermalTypeEvacuatedTube
    args['solar_thermal_collector_azimuth'] = 0
    args['solar_thermal_collector_tilt'] = 0
    args['solar_thermal_collector_rated_optical_efficiency'] = 0
    args['solar_thermal_collector_rated_thermal_losses'] = 0
    args['solar_thermal_storage_volume'] = Constants.Auto
    args['solar_thermal_solar_fraction'] = 0
    args['pv_system_module_type'] = 'none'
    args['pv_system_location'] = Constants.Auto
    args['pv_system_tracking'] = Constants.Auto
    args['pv_system_array_azimuth'] = 0
    args['pv_system_array_tilt'] = 0
    args['pv_system_max_power_output'] = 0
    args['pv_system_inverter_efficiency'] = 0
    args['pv_system_system_losses_fraction'] = 0
    args['pv_system_num_units_served'] = 0
    args['pv_system_2_module_type'] = 'none'
    args['pv_system_2_location'] = Constants.Auto
    args['pv_system_2_tracking'] = Constants.Auto
    args['pv_system_2_array_azimuth'] = 0
    args['pv_system_2_array_tilt'] = 0
    args['pv_system_2_max_power_output'] = 0
    args['pv_system_2_inverter_efficiency'] = 0
    args['pv_system_2_system_losses_fraction'] = 0
    args['pv_system_2_num_units_served'] = 0
    args['lighting_present'] = false
    args['lighting_interior_fraction_cfl'] = 0
    args['lighting_interior_fraction_lfl'] = 0
    args['lighting_interior_fraction_led'] = 0
    args['lighting_interior_usage_multiplier'] = 0
    args['lighting_exterior_fraction_cfl'] = 0
    args['lighting_exterior_fraction_lfl'] = 0
    args['lighting_exterior_fraction_led'] = 0
    args['lighting_exterior_usage_multiplier'] = 0
    args['lighting_garage_fraction_cfl'] = 0
    args['lighting_garage_fraction_lfl'] = 0
    args['lighting_garage_fraction_led'] = 0
    args['lighting_garage_usage_multiplier'] = 0
    args['holiday_lighting_present'] = false
    args['holiday_lighting_daily_kwh'] = Constants.Auto
    args['dehumidifier_type'] = 'none'
    args['dehumidifier_efficiency_type'] = 'EnergyFactor'
    args['dehumidifier_efficiency'] = 0
    args['dehumidifier_capacity'] = 0
    args['dehumidifier_rh_setpoint'] = 0
    args['dehumidifier_fraction_dehumidification_load_served'] = 0
    args['clothes_washer_location'] = 'none'
    args['clothes_washer_efficiency_type'] = 'IntegratedModifiedEnergyFactor'
    args['clothes_washer_efficiency'] = 0
    args['clothes_washer_rated_annual_kwh'] = 0
    args['clothes_washer_label_electric_rate'] = 0
    args['clothes_washer_label_gas_rate'] = 0
    args['clothes_washer_label_annual_gas_cost'] = 0
    args['clothes_washer_label_usage'] = 0
    args['clothes_washer_capacity'] = 0
    args['clothes_washer_usage_multiplier'] = 0
    args['clothes_dryer_location'] = 'none'
    args['clothes_dryer_fuel_type'] = HPXML::FuelTypeElectricity
    args['clothes_dryer_efficiency_type'] = 'CombinedEnergyFactor'
    args['clothes_dryer_efficiency'] = 0
    args['clothes_dryer_vented_flow_rate'] = 0
    args['clothes_dryer_usage_multiplier'] = 0
    args['dishwasher_location'] = 'none'
    args['dishwasher_efficiency_type'] = 'RatedAnnualkWh'
    args['dishwasher_efficiency'] = 0
    args['dishwasher_label_electric_rate'] = 0
    args['dishwasher_label_gas_rate'] = 0
    args['dishwasher_label_annual_gas_cost'] = 0
    args['dishwasher_label_usage'] = 0
    args['dishwasher_place_setting_capacity'] = 0
    args['dishwasher_usage_multiplier'] = 0
    args['refrigerator_location'] = 'none'
    args['refrigerator_rated_annual_kwh'] = 0
    args['refrigerator_usage_multiplier'] = 0
    args['extra_refrigerator_location'] = 'none'
    args['extra_refrigerator_rated_annual_kwh'] = Constants.Auto
    args['extra_refrigerator_usage_multiplier'] = 0
    args['freezer_location'] = 'none'
    args['freezer_rated_annual_kwh'] = Constants.Auto
    args['freezer_usage_multiplier'] = 0
    args['cooking_range_oven_location'] = 'none'
    args['cooking_range_oven_fuel_type'] = HPXML::FuelTypeElectricity
    args['cooking_range_oven_is_induction'] = false
    args['cooking_range_oven_is_convection'] = false
    args['cooking_range_oven_usage_multiplier'] = 0
    args['ceiling_fan_present'] = false
    args['ceiling_fan_efficiency'] = Constants.Auto
    args['ceiling_fan_quantity'] = Constants.Auto
    args['ceiling_fan_cooling_setpoint_temp_offset'] = 0
    args['misc_plug_loads_television_present'] = false
    args['misc_plug_loads_television_annual_kwh'] = 0
    args['misc_plug_loads_television_usage_multiplier'] = 0
    args['misc_plug_loads_other_annual_kwh'] = 7302.0
    args['misc_plug_loads_other_frac_sensible'] = 0.822
    args['misc_plug_loads_other_frac_latent'] = 0.178
    args['misc_plug_loads_other_usage_multiplier'] = 1.0
    args['misc_plug_loads_well_pump_present'] = false
    args['misc_plug_loads_well_pump_annual_kwh'] = Constants.Auto
    args['misc_plug_loads_well_pump_usage_multiplier'] = 0
    args['misc_plug_loads_vehicle_present'] = false
    args['misc_plug_loads_vehicle_annual_kwh'] = Constants.Auto
    args['misc_plug_loads_vehicle_usage_multiplier'] = 0
    args['misc_fuel_loads_grill_present'] = false
    args['misc_fuel_loads_grill_fuel_type'] = HPXML::FuelTypeNaturalGas
    args['misc_fuel_loads_grill_annual_therm'] = Constants.Auto
    args['misc_fuel_loads_grill_usage_multiplier'] = 0
    args['misc_fuel_loads_lighting_present'] = false
    args['misc_fuel_loads_lighting_fuel_type'] = HPXML::FuelTypeNaturalGas
    args['misc_fuel_loads_lighting_annual_therm'] = Constants.Auto
    args['misc_fuel_loads_lighting_usage_multiplier'] = 0
    args['misc_fuel_loads_fireplace_present'] = false
    args['misc_fuel_loads_fireplace_fuel_type'] = HPXML::FuelTypeNaturalGas
    args['misc_fuel_loads_fireplace_annual_therm'] = Constants.Auto
    args['misc_fuel_loads_fireplace_frac_sensible'] = Constants.Auto
    args['misc_fuel_loads_fireplace_frac_latent'] = Constants.Auto
    args['misc_fuel_loads_fireplace_usage_multiplier'] = 0
    args['pool_present'] = false
    args['pool_pump_annual_kwh'] = Constants.Auto
    args['pool_pump_usage_multiplier'] = 0
    args['pool_heater_type'] = HPXML::HeaterTypeElectricResistance
    args['pool_heater_annual_kwh'] = Constants.Auto
    args['pool_heater_annual_therm'] = Constants.Auto
    args['pool_heater_usage_multiplier'] = 0
    args['hot_tub_present'] = false
    args['hot_tub_pump_annual_kwh'] = Constants.Auto
    args['hot_tub_pump_usage_multiplier'] = 0
    args['hot_tub_heater_type'] = HPXML::HeaterTypeElectricResistance
    args['hot_tub_heater_annual_kwh'] = Constants.Auto
    args['hot_tub_heater_annual_therm'] = Constants.Auto
    args['hot_tub_heater_usage_multiplier'] = 0
  end

  # ASHRAE 140
  if ['ASHRAE_Standard_140/L100AL.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'USA_NV_Las.Vegas-McCarran.Intl.AP.723860_TMY3.epw'
  elsif ['ASHRAE_Standard_140/L110AC.xml',
         'ASHRAE_Standard_140/L110AL.xml'].include? hpxml_file
    args['air_leakage_value'] = 1.5
  elsif ['ASHRAE_Standard_140/L120AC.xml',
         'ASHRAE_Standard_140/L120AL.xml'].include? hpxml_file
    args['wall_assembly_r'] = 23.58
    args['ceiling_assembly_r'] = 57.49
  elsif ['ASHRAE_Standard_140/L130AC.xml',
         'ASHRAE_Standard_140/L130AL.xml'].include? hpxml_file
    args['window_ufactor'] = 0.3
    args['window_shgc'] = 0.335
  elsif ['ASHRAE_Standard_140/L140AC.xml',
         'ASHRAE_Standard_140/L140AL.xml'].include? hpxml_file
    args['window_area_front'] = 0.0
    args['window_area_back'] = 0.0
    args['window_area_left'] = 0.0
    args['window_area_right'] = 0.0
  elsif ['ASHRAE_Standard_140/L150AC.xml',
         'ASHRAE_Standard_140/L150AL.xml'].include? hpxml_file
    args['window_area_front'] = 270.0
    args['window_area_back'] = 0.0
    args['window_area_left'] = 0.0
    args['window_area_right'] = 0.0
    args['window_aspect_ratio'] = 5.0 / 1.5
  elsif ['ASHRAE_Standard_140/L155AC.xml',
         'ASHRAE_Standard_140/L155AL.xml'].include? hpxml_file
    args['overhangs_front_depth'] = 2.5
    args['overhangs_front_distance_to_top_of_window'] = 1.0
    args['overhangs_front_distance_to_bottom_of_window'] = 6.0
  elsif ['ASHRAE_Standard_140/L160AC.xml',
         'ASHRAE_Standard_140/L160AL.xml'].include? hpxml_file
    args['window_area_front'] = 0.0
    args['window_area_back'] = 0.0
    args['window_area_left'] = 135.0
    args['window_area_right'] = 135.0
    args['window_aspect_ratio'] = 5.0 / 1.5
  elsif ['ASHRAE_Standard_140/L170AC.xml',
         'ASHRAE_Standard_140/L170AL.xml'].include? hpxml_file
    args['misc_plug_loads_other_annual_kwh'] = 0.0
  elsif ['ASHRAE_Standard_140/L200AC.xml',
         'ASHRAE_Standard_140/L200AL.xml'].include? hpxml_file
    args['air_leakage_value'] = 1.5
    args['wall_assembly_r'] = 4.84
    args['ceiling_assembly_r'] = 11.75
    args['floor_over_foundation_assembly_r'] = 4.24
  elsif ['ASHRAE_Standard_140/L202AC.xml',
         'ASHRAE_Standard_140/L202AL.xml'].include? hpxml_file
    args['wall_color'] = HPXML::ColorReflective
    args['roof_color'] = HPXML::ColorReflective
  elsif ['ASHRAE_Standard_140/L302XC.xml'].include? hpxml_file
    args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
    args['slab_carpet_fraction'] = 1.0
    args['slab_carpet_r'] = 2.08
  elsif ['ASHRAE_Standard_140/L304XC.xml'].include? hpxml_file
    args['slab_perimeter_insulation_r'] = 5.4
    args['slab_perimeter_depth'] = 2.5
  elsif ['ASHRAE_Standard_140/L322XC.xml'].include? hpxml_file
    args['geometry_foundation_type'] = HPXML::FoundationTypeBasementConditioned
    args['geometry_unit_cfa'] = 3078
    args['air_leakage_value'] = 0.335
    args['foundation_wall_insulation_distance_to_top'] = 0
    args['foundation_wall_insulation_distance_to_bottom'] = 0
  elsif ['ASHRAE_Standard_140/L324XC.xml'].include? hpxml_file
    args['rim_joist_assembly_r'] = 13.14
    args['foundation_wall_insulation_r'] = 10.2
    args['foundation_wall_insulation_distance_to_bottom'] = 7.25
    args['foundation_wall_insulation_location'] = 'interior'
  end

  # Appliances
  if ['base-appliances-coal.xml'].include? hpxml_file
    args['clothes_dryer_fuel_type'] = HPXML::FuelTypeCoal
    args['clothes_dryer_efficiency'] = 3.3
    args['clothes_dryer_vented_flow_rate'] = Constants.Auto
    args['cooking_range_oven_fuel_type'] = HPXML::FuelTypeCoal
  elsif ['base-appliances-dehumidifier.xml'].include? hpxml_file
    args['heating_system_heating_capacity'] = 24000.0
    args['dehumidifier_type'] = HPXML::DehumidifierTypePortable
  elsif ['base-appliances-dehumidifier-ief-portable.xml'].include? hpxml_file
    args['dehumidifier_efficiency_type'] = 'IntegratedEnergyFactor'
    args['dehumidifier_efficiency'] = 1.5
  elsif ['base-appliances-dehumidifier-ief-whole-home.xml'].include? hpxml_file
    args['dehumidifier_type'] = HPXML::DehumidifierTypeWholeHome
  elsif ['base-appliances-gas.xml'].include? hpxml_file
    args['clothes_dryer_fuel_type'] = HPXML::FuelTypeNaturalGas
    args['clothes_dryer_efficiency'] = 3.3
    args['clothes_dryer_vented_flow_rate'] = Constants.Auto
    args['cooking_range_oven_fuel_type'] = HPXML::FuelTypeNaturalGas
  elsif ['base-appliances-modified.xml'].include? hpxml_file
    args['clothes_washer_efficiency_type'] = 'ModifiedEnergyFactor'
    args['clothes_washer_efficiency'] = 1.65
    args['clothes_dryer_efficiency_type'] = 'EnergyFactor'
    args['clothes_dryer_efficiency'] = 4.29
    args['clothes_dryer_vented_flow_rate'] = 0.0
    args['dishwasher_efficiency_type'] = 'EnergyFactor'
    args['dishwasher_efficiency'] = 0.7
    args['dishwasher_place_setting_capacity'] = 6
  elsif ['base-appliances-none.xml'].include? hpxml_file
    args['clothes_washer_location'] = 'none'
    args['clothes_dryer_location'] = 'none'
    args['dishwasher_location'] = 'none'
    args['refrigerator_location'] = 'none'
    args['cooking_range_oven_location'] = 'none'
  elsif ['base-appliances-oil.xml'].include? hpxml_file
    args['clothes_dryer_fuel_type'] = HPXML::FuelTypeOil
    args['clothes_dryer_efficiency'] = 3.3
    args['clothes_dryer_vented_flow_rate'] = Constants.Auto
    args['cooking_range_oven_fuel_type'] = HPXML::FuelTypeOil
  elsif ['base-appliances-propane.xml'].include? hpxml_file
    args['clothes_dryer_fuel_type'] = HPXML::FuelTypePropane
    args['clothes_dryer_efficiency'] = 3.3
    args['clothes_dryer_vented_flow_rate'] = Constants.Auto
    args['cooking_range_oven_fuel_type'] = HPXML::FuelTypePropane
  elsif ['base-appliances-wood.xml'].include? hpxml_file
    args['clothes_dryer_fuel_type'] = HPXML::FuelTypeWoodCord
    args['clothes_dryer_efficiency'] = 3.3
    args['clothes_dryer_vented_flow_rate'] = Constants.Auto
    args['cooking_range_oven_fuel_type'] = HPXML::FuelTypeWoodCord
  end

  # Attic/roof
  if ['base-atticroof-flat.xml'].include? hpxml_file
    args['geometry_roof_type'] = 'flat'
    args['roof_assembly_r'] = 25.8
    args['ducts_supply_leakage_to_outside_value'] = 0.0
    args['ducts_return_leakage_to_outside_value'] = 0.0
    args['ducts_supply_location'] = HPXML::LocationBasementConditioned
    args['ducts_return_location'] = HPXML::LocationBasementConditioned
  elsif ['base-atticroof-radiant-barrier.xml'].include? hpxml_file
    args['roof_radiant_barrier'] = true
    args['roof_radiant_barrier_grade'] = 2
    args['ceiling_assembly_r'] = 8.7
  elsif ['base-atticroof-unvented-insulated-roof.xml'].include? hpxml_file
    args['ceiling_assembly_r'] = 2.1
    args['roof_assembly_r'] = 25.8
  elsif ['base-atticroof-vented.xml'].include? hpxml_file
    args['geometry_attic_type'] = HPXML::AtticTypeVented
    args['water_heater_location'] = HPXML::LocationAtticVented
    args['ducts_supply_location'] = HPXML::LocationAtticVented
    args['ducts_return_location'] = HPXML::LocationAtticVented
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    args['geometry_attic_type'] = HPXML::AtticTypeConditioned
    args['geometry_num_floors_above_grade'] = 2
    args['geometry_unit_cfa'] = 3600
    args['ducts_supply_location'] = HPXML::LocationLivingSpace
    args['ducts_return_location'] = HPXML::LocationLivingSpace
    args['ducts_supply_leakage_to_outside_value'] = 50
    args['ducts_return_leakage_to_outside_value'] = 100
    args['ducts_number_of_return_registers'] = 3
    args['water_heater_location'] = HPXML::LocationBasementConditioned
    args['clothes_washer_location'] = HPXML::LocationBasementConditioned
    args['clothes_dryer_location'] = HPXML::LocationBasementConditioned
    args['dishwasher_location'] = HPXML::LocationBasementConditioned
    args['refrigerator_location'] = HPXML::LocationBasementConditioned
    args['cooking_range_oven_location'] = HPXML::LocationBasementConditioned
    args['misc_plug_loads_other_annual_kwh'] = 3276
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    # BuildResHPXML measure doesn't support cathedral ceiling; model as
    # conditioned attic and then update the resulting HPXML later.
    args['geometry_attic_type'] = HPXML::AtticTypeConditioned
    args['geometry_num_floors_above_grade'] = 2
    args['geometry_unit_cfa'] = 4050
    args['window_area_front'] = 108.0
    args['window_area_back'] = 108.0
    args['window_area_left'] = 120.0
    args['window_area_right'] = 120.0
    args['window_aspect_ratio'] = 5.0 / 2.5
    args['roof_assembly_r'] = 25.8
    args['ducts_supply_location'] = HPXML::LocationLivingSpace
    args['ducts_return_location'] = HPXML::LocationLivingSpace
    args['ducts_supply_leakage_to_outside_value'] = 0
    args['ducts_return_leakage_to_outside_value'] = 0
  end

  # Single-Family Attached
  if ['base-bldgtype-single-family-attached.xml'].include? hpxml_file
    args['geometry_unit_type'] = HPXML::ResidentialTypeSFA
    args['geometry_unit_cfa'] = 1800.0
    args['geometry_corridor_position'] = 'None'
    args['geometry_building_num_units'] = 3
    args['geometry_unit_horizontal_location'] = 'Left'
    args['window_front_wwr'] = 0.18
    args['window_back_wwr'] = 0.18
    args['window_left_wwr'] = 0.18
    args['window_right_wwr'] = 0.18
    args['window_area_front'] = 0
    args['window_area_back'] = 0
    args['window_area_left'] = 0
    args['window_area_right'] = 0
    args['heating_system_heating_capacity'] = 24000.0
    args['misc_plug_loads_other_annual_kwh'] = 1638.0
  elsif ['base-bldgtype-single-family-attached-2stories.xml'].include? hpxml_file
    args['geometry_num_floors_above_grade'] = 2
    args['geometry_unit_cfa'] = 2700.0
    args['heating_system_heating_capacity'] = 48000.0
    args['cooling_system_cooling_capacity'] = 36000.0
    args['ducts_supply_surface_area'] = 112.5
    args['ducts_return_surface_area'] = 37.5
    args['ducts_number_of_return_registers'] = 3
    args['misc_plug_loads_other_annual_kwh'] = 2457.0
  end

  # Multifamily
  if ['base-bldgtype-multifamily.xml'].include? hpxml_file
    args['geometry_unit_type'] = HPXML::ResidentialTypeApartment
    args['geometry_unit_cfa'] = 900.0
    args['geometry_corridor_position'] = 'None'
    args['geometry_foundation_type'] = HPXML::FoundationTypeBasementUnconditioned
    args['geometry_unit_level'] = 'Middle'
    args['geometry_unit_horizontal_location'] = 'Left'
    args['geometry_building_num_units'] = 6
    args['geometry_building_num_bedrooms'] = 6 * 3
    args['geometry_num_floors_above_grade'] = 3
    args['window_front_wwr'] = 0.18
    args['window_back_wwr'] = 0.18
    args['window_left_wwr'] = 0.18
    args['window_right_wwr'] = 0.18
    args['window_area_front'] = 0
    args['window_area_back'] = 0
    args['window_area_left'] = 0
    args['window_area_right'] = 0
    args['heating_system_heating_capacity'] = 12000.0
    args['cooling_system_cooling_capacity'] = 12000.0
    args['ducts_supply_leakage_to_outside_value'] = 0.0
    args['ducts_return_leakage_to_outside_value'] = 0.0
    args['ducts_supply_location'] = HPXML::LocationLivingSpace
    args['ducts_return_location'] = HPXML::LocationLivingSpace
    args['ducts_supply_insulation_r'] = 0.0
    args['ducts_return_insulation_r'] = 0.0
    args['ducts_number_of_return_registers'] = 1
    args['door_area'] = 20.0
    args['misc_plug_loads_other_annual_kwh'] = 819.0
  elsif ['base-bldgtype-multifamily-shared-boiler-only-baseboard.xml',
         'base-bldgtype-multifamily-shared-boiler-chiller-baseboard.xml'].include? hpxml_file
    args['heating_system_type'] = "Shared #{HPXML::HVACTypeBoiler} w/ Baseboard"
    args['cooling_system_type'] = 'none'
  elsif ['base-bldgtype-multifamily-shared-boiler-only-fan-coil.xml',
         'base-bldgtype-multifamily-shared-boiler-chiller-fan-coil.xml'].include? hpxml_file
    args['heating_system_type'] = "Shared #{HPXML::HVACTypeBoiler} w/ Ductless Fan Coil"
    args['cooling_system_type'] = 'none'
  elsif ['base-bldgtype-multifamily-shared-chiller-only-baseboard.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = 'none'
  elsif ['base-bldgtype-multifamily-shared-mechvent.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeSupply
    args['mech_vent_flow_rate'] = 800
    args['mech_vent_fan_power'] = 240
    args['mech_vent_num_units_served'] = 10
    args['mech_vent_shared_frac_recirculation'] = 0.5
    args['mech_vent_2_fan_type'] = HPXML::MechVentTypeExhaust
    args['mech_vent_2_flow_rate'] = 72
    args['mech_vent_2_fan_power'] = 26
  elsif ['base-bldgtype-multifamily-shared-mechvent-preconditioning.xml'].include? hpxml_file
    args['mech_vent_shared_preheating_fuel'] = HPXML::FuelTypeNaturalGas
    args['mech_vent_shared_preheating_efficiency'] = 0.92
    args['mech_vent_shared_preheating_fraction_heat_load_served'] = 0.7
    args['mech_vent_shared_precooling_fuel'] = HPXML::FuelTypeElectricity
    args['mech_vent_shared_precooling_efficiency'] = 4.0
    args['mech_vent_shared_precooling_fraction_cool_load_served'] = 0.8
  elsif ['base-bldgtype-multifamily-shared-pv.xml'].include? hpxml_file
    args['pv_system_num_units_served'] = 6
    args['pv_system_location'] = HPXML::LocationGround
    args['pv_system_module_type'] = HPXML::PVModuleTypeStandard
    args['pv_system_tracking'] = HPXML::PVTrackingTypeFixed
    args['pv_system_array_azimuth'] = 225
    args['pv_system_array_tilt'] = 30
    args['pv_system_max_power_output'] = 30000
    args['pv_system_inverter_efficiency'] = 0.96
    args['pv_system_system_losses_fraction'] = 0.14
  elsif ['base-bldgtype-multifamily-shared-water-heater.xml'].include? hpxml_file
    args['water_heater_fuel_type'] = HPXML::FuelTypeNaturalGas
    args['water_heater_num_units_served'] = 6
    args['water_heater_tank_volume'] = 120
    args['water_heater_efficiency'] = 0.59
    args['water_heater_recovery_efficiency'] = 0.76
    args['water_heater_heating_capacity'] = 40000
  end

  # DHW
  if ['base-dhw-combi-tankless.xml'].include? hpxml_file
    args['water_heater_type'] = HPXML::WaterHeaterTypeCombiTankless
    args['water_heater_tank_volume'] = Constants.Auto
  elsif ['base-dhw-combi-tankless-outside.xml',
         'base-dhw-indirect-outside.xml',
         'base-dhw-tank-gas-outside.xml',
         'base-dhw-tank-heat-pump-outside.xml',
         'base-dhw-tankless-electric-outside.xml'].include? hpxml_file
    args['water_heater_location'] = HPXML::LocationOtherExterior
  elsif ['base-dhw-dwhr.xml'].include? hpxml_file
    args['dwhr_facilities_connected'] = HPXML::DWHRFacilitiesConnectedAll
  elsif ['base-dhw-indirect.xml'].include? hpxml_file
    args['water_heater_type'] = HPXML::WaterHeaterTypeCombiStorage
    args['water_heater_tank_volume'] = 50
  elsif ['base-dhw-indirect-standbyloss.xml'].include? hpxml_file
    args['water_heater_standby_loss'] = 1.0
  elsif ['base-dhw-indirect-with-solar-fraction.xml',
         'base-dhw-solar-fraction.xml',
         'base-dhw-tank-heat-pump-with-solar-fraction.xml',
         'base-dhw-tankless-gas-with-solar-fraction.xml'].include? hpxml_file
    args['solar_thermal_system_type'] = HPXML::SolarThermalSystemType
    args['solar_thermal_solar_fraction'] = 0.65
  elsif ['base-dhw-jacket-electric.xml',
         'base-dhw-jacket-gas.xml',
         'base-dhw-jacket-hpwh.xml',
         'base-dhw-jacket-indirect.xml'].include? hpxml_file
    args['water_heater_jacket_rvalue'] = 10.0
  elsif ['base-dhw-low-flow-fixtures.xml'].include? hpxml_file
    args['water_fixtures_sink_low_flow'] = true
  elsif ['base-dhw-none.xml'].include? hpxml_file
    args['water_heater_type'] = 'none'
    args['dishwasher_location'] = 'none'
  elsif ['base-dhw-recirc-demand.xml'].include? hpxml_file
    args['hot_water_distribution_system_type'] = HPXML::DHWDistTypeRecirc
    args['hot_water_distribution_recirc_control_type'] = HPXML::DHWRecirControlTypeSensor
    args['hot_water_distribution_pipe_r'] = 3.0
  elsif ['base-dhw-recirc-manual.xml'].include? hpxml_file
    args['hot_water_distribution_system_type'] = HPXML::DHWDistTypeRecirc
    args['hot_water_distribution_recirc_control_type'] = HPXML::DHWRecirControlTypeManual
    args['hot_water_distribution_pipe_r'] = 3.0
  elsif ['base-dhw-recirc-nocontrol.xml'].include? hpxml_file
    args['hot_water_distribution_system_type'] = HPXML::DHWDistTypeRecirc
  elsif ['base-dhw-recirc-temperature.xml'].include? hpxml_file
    args['hot_water_distribution_system_type'] = HPXML::DHWDistTypeRecirc
    args['hot_water_distribution_recirc_control_type'] = HPXML::DHWRecirControlTypeTemperature
  elsif ['base-dhw-recirc-timer.xml'].include? hpxml_file
    args['hot_water_distribution_system_type'] = HPXML::DHWDistTypeRecirc
    args['hot_water_distribution_recirc_control_type'] = HPXML::DHWRecirControlTypeTimer
  elsif ['base-dhw-solar-direct-evacuated-tube.xml'].include? hpxml_file
    args['solar_thermal_system_type'] = HPXML::SolarThermalSystemType
    args['solar_thermal_storage_volume'] = 60
  elsif ['base-dhw-solar-indirect-flat-plate.xml'].include? hpxml_file
    args['solar_thermal_system_type'] = HPXML::SolarThermalSystemType
    args['solar_thermal_collector_type'] = HPXML::SolarThermalTypeSingleGlazing
    args['solar_thermal_collector_rated_optical_efficiency'] = 0.77
    args['solar_thermal_collector_rated_thermal_losses'] = 0.793
    args['solar_thermal_storage_volume'] = 60
    args['solar_thermal_collector_loop_type'] = HPXML::SolarThermalLoopTypeIndirect
  elsif ['base-dhw-solar-direct-flat-plate.xml'].include? hpxml_file
    args['solar_thermal_collector_loop_type'] = HPXML::SolarThermalLoopTypeDirect
  elsif ['base-dhw-solar-direct-ics.xml'].include? hpxml_file
    args['solar_thermal_collector_type'] = HPXML::SolarThermalTypeICS
    args['solar_thermal_collector_loop_type'] = HPXML::SolarThermalLoopTypeDirect
  elsif ['base-dhw-solar-thermosyphon-flat-plate.xml'].include? hpxml_file
    args['solar_thermal_collector_loop_type'] = HPXML::SolarThermalLoopTypeThermosyphon
  elsif ['base-dhw-tank-coal.xml'].include? hpxml_file
    args['water_heater_fuel_type'] = HPXML::FuelTypeCoal
  elsif ['base-dhw-tank-elec-uef.xml'].include? hpxml_file
    args['water_heater_tank_volume'] = 30
    args['water_heater_efficiency_type'] = 'UniformEnergyFactor'
    args['water_heater_efficiency'] = 0.93
    args['water_heater_usage_bin'] = HPXML::WaterHeaterUsageBinLow
    args['water_heater_recovery_efficiency'] = 0.98
    args['water_heater_heating_capacity'] = 15354
  elsif ['base-dhw-tank-gas.xml'].include? hpxml_file
    args['water_heater_fuel_type'] = HPXML::FuelTypeNaturalGas
    args['water_heater_tank_volume'] = 50
    args['water_heater_efficiency'] = 0.59
    args['water_heater_heating_capacity'] = 40000
  elsif ['base-dhw-tank-gas-uef.xml'].include? hpxml_file
    args['water_heater_tank_volume'] = 30
    args['water_heater_efficiency_type'] = 'UniformEnergyFactor'
    args['water_heater_usage_bin'] = HPXML::WaterHeaterUsageBinMedium
    args['water_heater_recovery_efficiency'] = 0.75
    args['water_heater_heating_capacity'] = 30000
  elsif ['base-dhw-tank-heat-pump.xml'].include? hpxml_file
    args['water_heater_type'] = HPXML::WaterHeaterTypeHeatPump
    args['water_heater_tank_volume'] = 80
    args['water_heater_efficiency'] = 2.3
  elsif ['base-dhw-tank-heat-pump-uef.xml'].include? hpxml_file
    args['water_heater_tank_volume'] = 50
    args['water_heater_efficiency_type'] = 'UniformEnergyFactor'
    args['water_heater_efficiency'] = 3.75
    args['water_heater_usage_bin'] = HPXML::WaterHeaterUsageBinMedium
    args['water_heater_heating_capacity'] = 18767
  elsif ['base-dhw-tank-heat-pump-with-solar.xml',
         'base-dhw-tankless-gas-with-solar.xml'].include? hpxml_file
    args['solar_thermal_system_type'] = HPXML::SolarThermalSystemType
    args['solar_thermal_collector_loop_type'] = HPXML::SolarThermalLoopTypeIndirect
    args['solar_thermal_collector_type'] = HPXML::SolarThermalTypeSingleGlazing
    args['solar_thermal_collector_rated_optical_efficiency'] = 0.77
    args['solar_thermal_collector_rated_thermal_losses'] = 0.793
    args['solar_thermal_storage_volume'] = 60
  elsif ['base-dhw-tankless-electric.xml'].include? hpxml_file
    args['water_heater_type'] = HPXML::WaterHeaterTypeTankless
    args['water_heater_tank_volume'] = Constants.Auto
    args['water_heater_efficiency'] = 0.99
  elsif ['base-dhw-tankless-electric-uef.xml'].include? hpxml_file
    args['water_heater_efficiency_type'] = 'UniformEnergyFactor'
    args['water_heater_efficiency'] = 0.98
  elsif ['base-dhw-tankless-gas.xml'].include? hpxml_file
    args['water_heater_type'] = HPXML::WaterHeaterTypeTankless
    args['water_heater_fuel_type'] = HPXML::FuelTypeNaturalGas
    args['water_heater_tank_volume'] = Constants.Auto
    args['water_heater_efficiency'] = 0.82
  elsif ['base-dhw-tankless-gas-uef.xml'].include? hpxml_file
    args['water_heater_efficiency_type'] = 'UniformEnergyFactor'
    args['water_heater_efficiency'] = 0.93
  elsif ['base-dhw-tankless-propane.xml'].include? hpxml_file
    args['water_heater_fuel_type'] = HPXML::FuelTypePropane
  elsif ['base-dhw-tank-oil.xml'].include? hpxml_file
    args['water_heater_fuel_type'] = HPXML::FuelTypeOil
  elsif ['base-dhw-tank-wood.xml'].include? hpxml_file
    args['water_heater_fuel_type'] = HPXML::FuelTypeWoodCord
  elsif ['base-dhw-desuperheater.xml',
         'base-dhw-desuperheater-2-speed.xml',
         'base-dhw-desuperheater-var-speed.xml',
         'base-dhw-desuperheater-hpwh.xml',
         'base-dhw-desuperheater-gshp.xml'].include? hpxml_file
    args['water_heater_uses_desuperheater'] = true
  elsif ['base-dhw-desuperheater-tankless.xml'].include? hpxml_file
    args['water_heater_uses_desuperheater'] = true
    args['water_heater_type'] = HPXML::WaterHeaterTypeTankless
    args['water_heater_tank_volume'] = Constants.Auto
    args['water_heater_efficiency'] = 0.99
  end

  # Enclosure
  if ['base-enclosure-2stories.xml'].include? hpxml_file
    args['geometry_unit_cfa'] = 4050.0
    args['geometry_num_floors_above_grade'] = 2
    args['window_area_front'] = 216.0
    args['window_area_back'] = 216.0
    args['window_area_left'] = 144.0
    args['window_area_right'] = 144.0
    args['heating_system_heating_capacity'] = 48000.0
    args['cooling_system_cooling_capacity'] = 36000.0
    args['ducts_supply_surface_area'] = 112.5
    args['ducts_return_surface_area'] = 37.5
    args['ducts_number_of_return_registers'] = 3
    args['misc_plug_loads_other_annual_kwh'] = 3685.5
  elsif ['base-enclosure-2stories-garage.xml'].include? hpxml_file
    args['geometry_unit_cfa'] = 3250.0
    args['geometry_garage_width'] = 20.0
    args['ducts_supply_surface_area'] = 112.5
    args['ducts_return_surface_area'] = 37.5
    args['misc_plug_loads_other_annual_kwh'] = 2957.5
    args['floor_over_garage_assembly_r'] = 39.3
  elsif ['base-enclosure-beds-1.xml'].include? hpxml_file
    args['geometry_unit_num_bedrooms'] = 1
    args['geometry_unit_num_bathrooms'] = 1
    args['geometry_unit_num_occupants'] = 1
    args['misc_plug_loads_television_annual_kwh'] = 482.0
  elsif ['base-enclosure-beds-2.xml'].include? hpxml_file
    args['geometry_unit_num_bedrooms'] = 2
    args['geometry_unit_num_bathrooms'] = 1
    args['geometry_unit_num_occupants'] = 2
    args['misc_plug_loads_television_annual_kwh'] = 551.0
  elsif ['base-enclosure-beds-4.xml'].include? hpxml_file
    args['geometry_unit_num_bedrooms'] = 4
    args['geometry_unit_num_occupants'] = 4
    args['misc_plug_loads_television_annual_kwh'] = 689.0
  elsif ['base-enclosure-beds-5.xml'].include? hpxml_file
    args['geometry_unit_num_bedrooms'] = 5
    args['geometry_unit_num_bathrooms'] = 3
    args['geometry_unit_num_occupants'] = 5
    args['misc_plug_loads_television_annual_kwh'] = 758.0
  elsif ['base-enclosure-garage.xml'].include? hpxml_file
    args['geometry_garage_width'] = 30.0
    args['geometry_garage_protrusion'] = 1.0
    args['window_area_front'] = 12.0
    args['window_aspect_ratio'] = 5.0 / 1.5
    args['ducts_supply_location'] = HPXML::LocationGarage
    args['ducts_return_location'] = HPXML::LocationGarage
    args['water_heater_location'] = HPXML::LocationGarage
    args['clothes_washer_location'] = HPXML::LocationGarage
    args['clothes_dryer_location'] = HPXML::LocationGarage
    args['dishwasher_location'] = HPXML::LocationGarage
    args['refrigerator_location'] = HPXML::LocationGarage
    args['cooking_range_oven_location'] = HPXML::LocationGarage
  elsif ['base-enclosure-infil-ach-house-pressure.xml',
         'base-enclosure-infil-cfm-house-pressure.xml'].include? hpxml_file
    args['air_leakage_house_pressure'] = 45
    args['air_leakage_value'] *= 0.9338
  elsif ['base-enclosure-infil-cfm50.xml'].include? hpxml_file
    args['air_leakage_units'] = HPXML::UnitsCFM
    args['air_leakage_value'] = 1080
  elsif ['base-enclosure-infil-flue.xml'].include? hpxml_file
    args['geometry_has_flue_or_chimney'] = 'true'
  elsif ['base-enclosure-infil-natural-ach.xml'].include? hpxml_file
    args['air_leakage_units'] = HPXML::UnitsACHNatural
    args['air_leakage_value'] = 0.2
  elsif ['base-enclosure-overhangs.xml'].include? hpxml_file
    args['overhangs_front_distance_to_top_of_window'] = 1.0
    args['overhangs_front_distance_to_bottom_of_window'] = 5.0
    args['overhangs_back_depth'] = 2.5
    args['overhangs_back_distance_to_bottom_of_window'] = 4.0
    args['overhangs_left_depth'] = 1.5
    args['overhangs_left_distance_to_top_of_window'] = 2.0
    args['overhangs_left_distance_to_bottom_of_window'] = 7.0
    args['overhangs_right_depth'] = 1.5
    args['overhangs_right_distance_to_top_of_window'] = 2.0
    args['overhangs_right_distance_to_bottom_of_window'] = 6.0
  elsif ['base-enclosure-windows-none.xml'].include? hpxml_file
    args['window_area_front'] = 0
    args['window_area_back'] = 0
    args['window_area_left'] = 0
    args['window_area_right'] = 0
  elsif ['base-enclosure-skylights.xml'].include? hpxml_file
    args['skylight_area_front'] = 15
    args['skylight_area_back'] = 15
    args['skylight_ufactor'] = 0.33
    args['skylight_shgc'] = 0.45
  elsif ['base-enclosure-split-level.xml'].include? hpxml_file
    args['ducts_number_of_return_registers'] = 2
  end

  # Foundation
  if ['base-foundation-ambient.xml'].include? hpxml_file
    args['geometry_unit_cfa'] = 1350.0
    args['geometry_foundation_type'] = HPXML::FoundationTypeAmbient
    args.delete('geometry_rim_joist_height')
    args['floor_over_foundation_assembly_r'] = 18.7
    args.delete('rim_joist_assembly_r')
    args['ducts_number_of_return_registers'] = 1
    args['misc_plug_loads_other_annual_kwh'] = 1228.5
  elsif ['base-foundation-conditioned-basement-slab-insulation.xml'].include? hpxml_file
    args['slab_under_insulation_r'] = 10
    args['slab_under_width'] = 4
  elsif ['base-foundation-conditioned-basement-wall-interior-insulation.xml'].include? hpxml_file
    args['foundation_wall_insulation_r'] = 18.9
    args['foundation_wall_insulation_distance_to_top'] = 1.0
  elsif ['base-foundation-slab.xml'].include? hpxml_file
    args['geometry_unit_cfa'] = 1350.0
    args['geometry_foundation_type'] = HPXML::FoundationTypeSlab
    args['geometry_foundation_height'] = 0.0
    args['geometry_foundation_height_above_grade'] = 0.0
    args['foundation_wall_insulation_distance_to_bottom'] = Constants.Auto
    args['slab_under_insulation_r'] = 5
    args['slab_under_width'] = 999
    args['slab_carpet_fraction'] = 1.0
    args['slab_carpet_r'] = 2.5
    args['ducts_supply_location'] = HPXML::LocationUnderSlab
    args['ducts_return_location'] = HPXML::LocationUnderSlab
    args['ducts_number_of_return_registers'] = 1
    args['misc_plug_loads_other_annual_kwh'] = 1228.5
  elsif ['base-foundation-unconditioned-basement.xml'].include? hpxml_file
    args['geometry_unit_cfa'] = 1350.0
    args['geometry_foundation_type'] = HPXML::FoundationTypeBasementUnconditioned
    args['floor_over_foundation_assembly_r'] = 18.7
    args['foundation_wall_insulation_r'] = 0
    args['foundation_wall_insulation_distance_to_bottom'] = 0.0
    args['rim_joist_assembly_r'] = 4.0
    args['ducts_supply_location'] = HPXML::LocationBasementUnconditioned
    args['ducts_return_location'] = HPXML::LocationBasementUnconditioned
    args['ducts_number_of_return_registers'] = 1
    args['water_heater_location'] = HPXML::LocationBasementUnconditioned
    args['clothes_washer_location'] = HPXML::LocationBasementUnconditioned
    args['clothes_dryer_location'] = HPXML::LocationBasementUnconditioned
    args['dishwasher_location'] = HPXML::LocationBasementUnconditioned
    args['refrigerator_location'] = HPXML::LocationBasementUnconditioned
    args['cooking_range_oven_location'] = HPXML::LocationBasementUnconditioned
    args['misc_plug_loads_other_annual_kwh'] = 1228.5
  elsif ['base-foundation-basement-garage.xml'].include? hpxml_file
    args['misc_plug_loads_other_annual_kwh'] = 1729
  elsif ['base-foundation-unconditioned-basement-above-grade.xml'].include? hpxml_file
    args['geometry_foundation_height_above_grade'] = 4.0
  elsif ['base-foundation-unconditioned-basement-assembly-r.xml'].include? hpxml_file
    args['foundation_wall_assembly_r'] = 10.69
  elsif ['base-foundation-unconditioned-basement-wall-insulation.xml'].include? hpxml_file
    args['floor_over_foundation_assembly_r'] = 2.1
    args['foundation_wall_insulation_r'] = 8.9
    args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    args['rim_joist_assembly_r'] = 23.0
  elsif ['base-foundation-unvented-crawlspace.xml'].include? hpxml_file
    args['geometry_unit_cfa'] = 1350.0
    args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceUnvented
    args['geometry_foundation_height'] = 4.0
    args['floor_over_foundation_assembly_r'] = 18.7
    args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    args['slab_carpet_r'] = 2.5
    args['ducts_supply_location'] = HPXML::LocationCrawlspaceUnvented
    args['ducts_return_location'] = HPXML::LocationCrawlspaceUnvented
    args['ducts_number_of_return_registers'] = 1
    args['water_heater_location'] = HPXML::LocationCrawlspaceUnvented
    args['misc_plug_loads_other_annual_kwh'] = 1228.5
  elsif ['base-foundation-vented-crawlspace.xml'].include? hpxml_file
    args['geometry_unit_cfa'] = 1350.0
    args['geometry_foundation_type'] = HPXML::FoundationTypeCrawlspaceVented
    args['geometry_foundation_height'] = 4.0
    args['floor_over_foundation_assembly_r'] = 18.7
    args['foundation_wall_insulation_distance_to_bottom'] = 4.0
    args['slab_carpet_r'] = 2.5
    args['ducts_supply_location'] = HPXML::LocationCrawlspaceVented
    args['ducts_return_location'] = HPXML::LocationCrawlspaceVented
    args['ducts_number_of_return_registers'] = 1
    args['water_heater_location'] = HPXML::LocationCrawlspaceVented
    args['misc_plug_loads_other_annual_kwh'] = 1228.5
  elsif ['base-foundation-walkout-basement.xml'].include? hpxml_file
    args['geometry_foundation_height_above_grade'] = 5.0
    args['foundation_wall_insulation_distance_to_bottom'] = 4.0
  end

  # HVAC
  if ['base-hvac-programmable-thermostat.xml'].include? hpxml_file
    args['hvac_control_type'] = HPXML::HVACControlTypeProgrammable
  elsif ['base-hvac-air-to-air-heat-pump-1-speed.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = 'none'
    args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
    args['heat_pump_heating_capacity_17_f'] = 22680.0
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
  elsif ['base-hvac-air-to-air-heat-pump-1-speed-cooling-only.xml'].include? hpxml_file
    args['heat_pump_heating_capacity'] = 0.0
    args['heat_pump_heating_capacity_17_f'] = 0.0
    args['heat_pump_fraction_heat_load_served'] = 0
    args['heat_pump_backup_fuel'] = 'none'
  elsif ['base-hvac-air-to-air-heat-pump-1-speed-heating-only.xml'].include? hpxml_file
    args['heat_pump_cooling_capacity'] = 0.0
    args['heat_pump_fraction_cool_load_served'] = 0
  elsif ['base-hvac-air-to-air-heat-pump-2-speed.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = 'none'
    args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
    args['heat_pump_heating_efficiency'] = 9.3
    args['heat_pump_cooling_compressor_type'] = HPXML::HVACCompressorTypeTwoStage
    args['heat_pump_heating_capacity_17_f'] = 21240.0
    args['heat_pump_cooling_efficiency'] = 18.0
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
  elsif ['base-hvac-air-to-air-heat-pump-var-speed.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = 'none'
    args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
    args['heat_pump_heating_efficiency'] = 10.0
    args['heat_pump_cooling_compressor_type'] = HPXML::HVACCompressorTypeVariableSpeed
    args['heat_pump_cooling_sensible_heat_fraction'] = 0.78
    args['heat_pump_heating_capacity_17_f'] = 23040.0
    args['heat_pump_cooling_efficiency'] = 22.0
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
  elsif ['base-hvac-autosize.xml',
         'base-hvac-autosize-boiler-elec-only.xml',
         'base-hvac-autosize-boiler-gas-central-ac-1-speed.xml',
         'base-hvac-autosize-boiler-gas-only.xml',
         'base-hvac-autosize-central-ac-only-1-speed.xml',
         'base-hvac-autosize-central-ac-only-2-speed.xml',
         'base-hvac-autosize-central-ac-only-var-speed.xml',
         'base-hvac-autosize-elec-resistance-only.xml',
         'base-hvac-autosize-evap-cooler-furnace-gas.xml',
         'base-hvac-autosize-floor-furnace-propane-only.xml',
         'base-hvac-autosize-furnace-elec-only.xml',
         'base-hvac-autosize-furnace-gas-central-ac-2-speed.xml',
         'base-hvac-autosize-furnace-gas-central-ac-var-speed.xml',
         'base-hvac-autosize-furnace-gas-only.xml',
         'base-hvac-autosize-furnace-gas-room-ac.xml',
         'base-hvac-autosize-mini-split-air-conditioner-only-ducted.xml',
         'base-hvac-autosize-room-ac-only.xml',
         'base-hvac-autosize-stove-oil-only.xml',
         'base-hvac-autosize-wall-furnace-elec-only.xml'].include? hpxml_file
    args['heating_system_heating_capacity'] = Constants.Auto
    args['cooling_system_cooling_capacity'] = Constants.Auto
  elsif ['base-hvac-autosize-air-to-air-heat-pump-1-speed.xml',
         'base-hvac-autosize-air-to-air-heat-pump-1-speed-cooling-only.xml',
         'base-hvac-autosize-air-to-air-heat-pump-1-speed-heating-only.xml',
         'base-hvac-autosize-air-to-air-heat-pump-2-speed.xml',
         'base-hvac-autosize-air-to-air-heat-pump-var-speed.xml',
         'base-hvac-autosize-dual-fuel-air-to-air-heat-pump-1-speed.xml',
         'base-hvac-autosize-dual-fuel-mini-split-heat-pump-ducted.xml',
         'base-hvac-autosize-ground-to-air-heat-pump.xml',
         'base-hvac-autosize-ground-to-air-heat-pump-cooling-only.xml',
         'base-hvac-autosize-ground-to-air-heat-pump-heating-only.xml',
         'base-hvac-autosize-mini-split-heat-pump-ducted.xml',
         'base-hvac-autosize-mini-split-heat-pump-ducted-cooling-only.xml',
         'base-hvac-autosize-mini-split-heat-pump-ducted-heating-only.xml'].include? hpxml_file
    args['heat_pump_heating_capacity'] = Constants.AutoMaxLoad
    args['heat_pump_heating_capacity_17_f'] = Constants.Auto
    args['heat_pump_backup_heating_capacity'] = Constants.Auto
    args['heat_pump_cooling_capacity'] = Constants.Auto
  elsif ['base-hvac-autosize-air-to-air-heat-pump-1-speed-manual-s-oversize-allowances.xml',
         'base-hvac-autosize-air-to-air-heat-pump-2-speed-manual-s-oversize-allowances.xml',
         'base-hvac-autosize-air-to-air-heat-pump-var-speed-manual-s-oversize-allowances.xml',
         'base-hvac-autosize-ground-to-air-heat-pump-manual-s-oversize-allowances.xml',
         'base-hvac-autosize-mini-split-heat-pump-ducted-manual-s-oversize-allowances.xml'].include? hpxml_file
    args['heat_pump_heating_capacity'] = Constants.Auto
    args['heat_pump_heating_capacity_17_f'] = Constants.Auto
    args['heat_pump_backup_heating_capacity'] = Constants.Auto
    args['heat_pump_cooling_capacity'] = Constants.Auto
  elsif ['base-hvac-autosize-central-ac-plus-air-to-air-heat-pump-heating.xml'].include? hpxml_file
    args['heating_system_heating_capacity'] = Constants.Auto
    args['cooling_system_cooling_capacity'] = Constants.Auto
    args['heat_pump_heating_capacity'] = Constants.AutoMaxLoad
    args['heat_pump_heating_capacity_17_f'] = Constants.Auto
    args['heat_pump_backup_heating_capacity'] = Constants.Auto
    args['heat_pump_cooling_capacity'] = Constants.Auto
  elsif ['base-hvac-boiler-coal-only.xml',
         'base-hvac-furnace-coal-only.xml'].include? hpxml_file
    args['heating_system_fuel'] = HPXML::FuelTypeCoal
  elsif ['base-hvac-boiler-elec-only.xml'].include? hpxml_file
    args['heating_system_type'] = HPXML::HVACTypeBoiler
    args['heating_system_fuel'] = HPXML::FuelTypeElectricity
    args['heating_system_heating_efficiency'] = 0.98
    args['cooling_system_type'] = 'none'
  elsif ['base-hvac-boiler-gas-central-ac-1-speed.xml'].include? hpxml_file
    args['heating_system_type'] = HPXML::HVACTypeBoiler
  elsif ['base-hvac-boiler-gas-only.xml'].include? hpxml_file
    args['heating_system_type'] = HPXML::HVACTypeBoiler
    args['cooling_system_type'] = 'none'
  elsif ['base-hvac-boiler-oil-only.xml',
         'base-hvac-furnace-oil-only.xml'].include? hpxml_file
    args['heating_system_fuel'] = HPXML::FuelTypeOil
  elsif ['base-hvac-boiler-propane-only.xml',
         'base-hvac-furnace-propane-only.xml'].include? hpxml_file
    args['heating_system_fuel'] = HPXML::FuelTypePropane
  elsif ['base-hvac-boiler-wood-only.xml',
         'base-hvac-furnace-wood-only.xml'].include? hpxml_file
    args['heating_system_fuel'] = HPXML::FuelTypeWoodCord
  elsif ['base-hvac-central-ac-only-1-speed.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
  elsif ['base-hvac-central-ac-only-2-speed.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_cooling_efficiency'] = 18.0
    args['cooling_system_cooling_compressor_type'] = HPXML::HVACCompressorTypeTwoStage
  elsif ['base-hvac-central-ac-only-var-speed.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_cooling_efficiency'] = 24.0
    args['cooling_system_cooling_compressor_type'] = HPXML::HVACCompressorTypeVariableSpeed
    args['cooling_system_cooling_sensible_heat_fraction'] = 0.78
  elsif ['base-hvac-central-ac-plus-air-to-air-heat-pump-heating.xml'].include? hpxml_file
    args['heat_pump_type'] = HPXML::HVACTypeHeatPumpAirToAir
    args['heat_pump_heating_efficiency'] = 7.7
    args['heat_pump_heating_capacity_17_f'] = 22680.0
    args['heat_pump_fraction_cool_load_served'] = 0
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed.xml'].include? hpxml_file
    args['cooling_system_type'] = 'none'
    args['heat_pump_heating_efficiency'] = 7.7
    args['heat_pump_heating_capacity_17_f'] = 22680.0
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeNaturalGas
    args['heat_pump_backup_heating_efficiency'] = 0.95
    args['heat_pump_backup_heating_switchover_temp'] = 25
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml'].include? hpxml_file
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
    args['heat_pump_backup_heating_efficiency'] = 1.0
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-2-speed.xml',
         'base-hvac-dual-fuel-air-to-air-heat-pump-var-speed.xml'].include? hpxml_file
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeNaturalGas
    args['heat_pump_backup_heating_efficiency'] = 0.95
    args['heat_pump_backup_heating_switchover_temp'] = 25
  elsif ['base-hvac-dual-fuel-mini-split-heat-pump-ducted.xml'].include? hpxml_file
    args['heat_pump_heating_capacity'] = 36000.0
    args['heat_pump_heating_capacity_17_f'] = 20423.0
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeNaturalGas
    args['heat_pump_backup_heating_efficiency'] = 0.95
    args['heat_pump_backup_heating_switchover_temp'] = 25
  elsif ['base-hvac-ducts-leakage-percent.xml'].include? hpxml_file
    args['ducts_leakage_units'] = HPXML::UnitsPercent
    args['ducts_supply_leakage_to_outside_value'] = 0.1
    args['ducts_return_leakage_to_outside_value'] = 0.05
  elsif ['base-hvac-elec-resistance-only.xml'].include? hpxml_file
    args['heating_system_type'] = HPXML::HVACTypeElectricResistance
    args['heating_system_fuel'] = HPXML::FuelTypeElectricity
    args['heating_system_heating_efficiency'] = 1.0
    args['cooling_system_type'] = 'none'
  elsif ['base-hvac-evap-cooler-furnace-gas.xml'].include? hpxml_file
    args['cooling_system_type'] = HPXML::HVACTypeEvaporativeCooler
    args.delete('cooling_system_cooling_compressor_type')
    args.delete('cooling_system_cooling_sensible_heat_fraction')
  elsif ['base-hvac-evap-cooler-only.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = HPXML::HVACTypeEvaporativeCooler
    args.delete('cooling_system_cooling_compressor_type')
    args.delete('cooling_system_cooling_sensible_heat_fraction')
  elsif ['base-hvac-evap-cooler-only-ducted.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = HPXML::HVACTypeEvaporativeCooler
    args.delete('cooling_system_cooling_compressor_type')
    args.delete('cooling_system_cooling_sensible_heat_fraction')
    args['cooling_system_is_ducted'] = true
    args['ducts_return_leakage_to_outside_value'] = 0.0
  elsif ['base-hvac-fireplace-wood-only.xml'].include? hpxml_file
    args['heating_system_type'] = HPXML::HVACTypeFireplace
    args['heating_system_fuel'] = HPXML::FuelTypeWoodCord
  elsif ['base-hvac-fixed-heater-gas-only.xml'].include? hpxml_file
    args['heating_system_type'] = HPXML::HVACTypeFixedHeater
    args['heating_system_heating_efficiency'] = 1.0
    args['cooling_system_type'] = 'none'
  elsif ['base-hvac-floor-furnace-propane-only.xml'].include? hpxml_file
    args['heating_system_type'] = HPXML::HVACTypeFloorFurnace
    args['heating_system_fuel'] = HPXML::FuelTypePropane
  elsif ['base-hvac-furnace-elec-central-ac-1-speed.xml'].include? hpxml_file
    args['heating_system_fuel'] = HPXML::FuelTypeElectricity
    args['heating_system_heating_efficiency'] = 1.0
  elsif ['base-hvac-furnace-elec-only.xml'].include? hpxml_file
    args['heating_system_fuel'] = HPXML::FuelTypeElectricity
    args['heating_system_heating_efficiency'] = 0.98
    args['cooling_system_type'] = 'none'
  elsif ['base-hvac-furnace-gas-central-ac-2-speed.xml'].include? hpxml_file
    args['cooling_system_cooling_efficiency'] = 18.0
    args['cooling_system_cooling_compressor_type'] = HPXML::HVACCompressorTypeTwoStage
  elsif ['base-hvac-furnace-gas-central-ac-var-speed.xml'].include? hpxml_file
    args['cooling_system_cooling_efficiency'] = 24.0
    args['cooling_system_cooling_compressor_type'] = HPXML::HVACCompressorTypeVariableSpeed
    args['cooling_system_cooling_sensible_heat_fraction'] = 0.78
  elsif ['base-hvac-furnace-gas-only.xml'].include? hpxml_file
    args['cooling_system_type'] = 'none'
  elsif ['base-hvac-furnace-gas-room-ac.xml'].include? hpxml_file
    args['cooling_system_type'] = HPXML::HVACTypeRoomAirConditioner
    args['cooling_system_cooling_efficiency_type'] = HPXML::UnitsEER
    args['cooling_system_cooling_efficiency'] = 8.5
    args.delete('cooling_system_cooling_compressor_type')
    args['cooling_system_cooling_sensible_heat_fraction'] = 0.65
  elsif ['base-hvac-mini-split-air-conditioner-only-ducted.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = HPXML::HVACTypeMiniSplitAirConditioner
    args['cooling_system_cooling_efficiency'] = 19.0
    args.delete('cooling_system_cooling_compressor_type')
    args['cooling_system_is_ducted'] = true
    args['ducts_supply_leakage_to_outside_value'] = 15.0
    args['ducts_return_leakage_to_outside_value'] = 5.0
    args['ducts_supply_insulation_r'] = 0.0
    args['ducts_supply_surface_area'] = 30.0
    args['ducts_return_surface_area'] = 10.0
  elsif ['base-hvac-mini-split-air-conditioner-only-ductless.xml'].include? hpxml_file
    args['cooling_system_is_ducted'] = false
  elsif ['base-hvac-ground-to-air-heat-pump.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = 'none'
    args['heat_pump_type'] = HPXML::HVACTypeHeatPumpGroundToAir
    args['heat_pump_heating_efficiency_type'] = HPXML::UnitsCOP
    args['heat_pump_heating_efficiency'] = 3.6
    args['heat_pump_cooling_efficiency_type'] = HPXML::UnitsEER
    args['heat_pump_cooling_efficiency'] = 16.6
    args.delete('heat_pump_cooling_compressor_type')
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
  elsif ['base-hvac-ground-to-air-heat-pump-cooling-only.xml'].include? hpxml_file
    args['heat_pump_heating_capacity'] = 0.0
    args['heat_pump_fraction_heat_load_served'] = 0
    args['heat_pump_backup_fuel'] = 'none'
  elsif ['base-hvac-ground-to-air-heat-pump-heating-only.xml'].include? hpxml_file
    args['heat_pump_cooling_capacity'] = 0.0
    args['heat_pump_fraction_cool_load_served'] = 0
  elsif ['base-hvac-seasons.xml'].include? hpxml_file
    args['hvac_control_heating_season_period'] = 'Nov 1 - Jun 30'
    args['hvac_control_cooling_season_period'] = 'Jun 1 - Oct 31'
  elsif ['base-hvac-install-quality-air-to-air-heat-pump-1-speed.xml',
         'base-hvac-install-quality-air-to-air-heat-pump-2-speed.xml',
         'base-hvac-install-quality-air-to-air-heat-pump-var-speed.xml',
         'base-hvac-install-quality-ground-to-air-heat-pump.xml',
         'base-hvac-install-quality-mini-split-heat-pump-ducted.xml'].include? hpxml_file
    args['heat_pump_airflow_defect_ratio'] = -0.25
    args['heat_pump_charge_defect_ratio'] = -0.25
  elsif ['base-hvac-install-quality-furnace-gas-central-ac-1-speed.xml',
         'base-hvac-install-quality-furnace-gas-central-ac-2-speed.xml',
         'base-hvac-install-quality-furnace-gas-central-ac-var-speed.xml'].include? hpxml_file
    args['heating_system_airflow_defect_ratio'] = -0.25
    args['cooling_system_airflow_defect_ratio'] = -0.25
    args['cooling_system_charge_defect_ratio'] = -0.25
  elsif ['base-hvac-install-quality-furnace-gas-only.xml'].include? hpxml_file
    args['heating_system_airflow_defect_ratio'] = -0.25
  elsif ['base-hvac-install-quality-mini-split-air-conditioner-only-ducted.xml'].include? hpxml_file
    args['cooling_system_airflow_defect_ratio'] = -0.25
    args['cooling_system_charge_defect_ratio'] = -0.25
  elsif ['base-hvac-mini-split-heat-pump-ducted.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = 'none'
    args['heat_pump_type'] = HPXML::HVACTypeHeatPumpMiniSplit
    args['heat_pump_heating_capacity_17_f'] = 20423.0
    args['heat_pump_heating_efficiency'] = 10.0
    args['heat_pump_cooling_efficiency'] = 19.0
    args.delete('heat_pump_cooling_compressor_type')
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
    args['heat_pump_is_ducted'] = true
    args['ducts_supply_leakage_to_outside_value'] = 15.0
    args['ducts_return_leakage_to_outside_value'] = 5.0
    args['ducts_supply_insulation_r'] = 0.0
    args['ducts_supply_surface_area'] = 30.0
    args['ducts_return_surface_area'] = 10.0
  elsif ['base-hvac-mini-split-heat-pump-ducted-cooling-only.xml'].include? hpxml_file
    args['heat_pump_heating_capacity'] = 0
    args['heat_pump_heating_capacity_17_f'] = 0
    args['heat_pump_fraction_heat_load_served'] = 0
    args['heat_pump_backup_fuel'] = 'none'
  elsif ['base-hvac-mini-split-heat-pump-ducted-heating-only.xml'].include? hpxml_file
    args['heat_pump_cooling_capacity'] = 0
    args['heat_pump_fraction_cool_load_served'] = 0
    args['heat_pump_backup_fuel'] = HPXML::FuelTypeElectricity
  elsif ['base-hvac-mini-split-heat-pump-ductless.xml'].include? hpxml_file
    args['heat_pump_backup_fuel'] = 'none'
    args['heat_pump_is_ducted'] = false
  elsif ['base-hvac-none.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = 'none'
  elsif ['base-hvac-portable-heater-gas-only.xml'].include? hpxml_file
    args['heating_system_type'] = HPXML::HVACTypePortableHeater
    args['heating_system_heating_efficiency'] = 1.0
    args['cooling_system_type'] = 'none'
  elsif ['base-hvac-programmable-thermostat-detailed.xml'].include? hpxml_file
    args['hvac_control_heating_weekday_setpoint'] = '64, 64, 64, 64, 64, 64, 64, 70, 70, 66, 66, 66, 66, 66, 66, 66, 66, 68, 68, 68, 68, 68, 64, 64'
    args['hvac_control_heating_weekend_setpoint'] = '68, 68, 68, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70, 70'
    args['hvac_control_cooling_weekday_setpoint'] = '80, 80, 80, 80, 80, 80, 80, 75, 75, 80, 80, 80, 80, 80, 80, 80, 80, 78, 78, 78, 78, 78, 80, 80'
    args['hvac_control_cooling_weekend_setpoint'] = '78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78, 78'
  elsif ['base-hvac-room-ac-only.xml'].include? hpxml_file
    args['heating_system_type'] = 'none'
    args['cooling_system_type'] = HPXML::HVACTypeRoomAirConditioner
    args['cooling_system_cooling_efficiency_type'] = HPXML::UnitsEER
    args['cooling_system_cooling_efficiency'] = 8.5
    args.delete('cooling_system_cooling_compressor_type')
    args['cooling_system_cooling_sensible_heat_fraction'] = 0.65
  elsif ['base-hvac-room-ac-only-ceer.xml'].include? hpxml_file
    args['cooling_system_cooling_efficiency_type'] = HPXML::UnitsCEER
    args['cooling_system_cooling_efficiency'] = 8.4
  elsif ['base-hvac-room-ac-only-33percent.xml'].include? hpxml_file
    args['cooling_system_fraction_cool_load_served'] = 0.33
    args['cooling_system_cooling_capacity'] = 8000.0
  elsif ['base-hvac-setpoints.xml'].include? hpxml_file
    args['hvac_control_heating_weekday_setpoint'] = 60
    args['hvac_control_heating_weekend_setpoint'] = 60
    args['hvac_control_cooling_weekday_setpoint'] = 80
    args['hvac_control_cooling_weekend_setpoint'] = 80
  elsif ['base-hvac-stove-oil-only.xml'].include? hpxml_file
    args['heating_system_type'] = HPXML::HVACTypeStove
    args['heating_system_fuel'] = HPXML::FuelTypeOil
    args['heating_system_heating_efficiency'] = 0.8
    args['cooling_system_type'] = 'none'
  elsif ['base-hvac-stove-wood-pellets-only.xml'].include? hpxml_file
    args['heating_system_fuel'] = HPXML::FuelTypeWoodPellets
  elsif ['base-hvac-undersized.xml'].include? hpxml_file
    args['heating_system_heating_capacity'] = 3600.0
    args['cooling_system_cooling_capacity'] = 2400.0
    args['ducts_supply_leakage_to_outside_value'] = 7.5
    args['ducts_return_leakage_to_outside_value'] = 2.5
  elsif ['base-hvac-wall-furnace-elec-only.xml'].include? hpxml_file
    args['heating_system_type'] = HPXML::HVACTypeWallFurnace
    args['heating_system_fuel'] = HPXML::FuelTypeElectricity
    args['heating_system_heating_efficiency'] = 0.98
    args['cooling_system_type'] = 'none'
  end

  # Lighting
  if ['base-lighting-none.xml'].include? hpxml_file
    args['lighting_present'] = false
  elsif ['base-lighting-ceiling-fans.xml'].include? hpxml_file
    args['ceiling_fan_present'] = true
    args['ceiling_fan_efficiency'] = 100.0
    args['ceiling_fan_quantity'] = 4
    args['ceiling_fan_cooling_setpoint_temp_offset'] = 0.5
  elsif ['base-lighting-holiday.xml'].include? hpxml_file
    args['holiday_lighting_present'] = true
    args['holiday_lighting_daily_kwh'] = 1.1
    args['holiday_lighting_period'] = 'Nov 24 - Jan 6'
  end

  # Location
  if ['base-location-AMY-2012.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'US_CO_Boulder_AMY_2012.epw'
  elsif ['base-location-baltimore-md.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'USA_MD_Baltimore-Washington.Intl.AP.724060_TMY3.epw'
    args['heating_system_heating_capacity'] = 24000.0
  elsif ['base-location-dallas-tx.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'USA_TX_Dallas-Fort.Worth.Intl.AP.722590_TMY3.epw'
    args['heating_system_heating_capacity'] = 24000.0
  elsif ['base-location-duluth-mn.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'USA_MN_Duluth.Intl.AP.727450_TMY3.epw'
  elsif ['base-location-helena-mt.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'USA_MT_Helena.Rgnl.AP.727720_TMY3.epw'
    args['heating_system_heating_capacity'] = 48000.0
  elsif ['base-location-honolulu-hi.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'USA_HI_Honolulu.Intl.AP.911820_TMY3.epw'
    args['heating_system_heating_capacity'] = 12000.0
  elsif ['base-location-miami-fl.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'USA_FL_Miami.Intl.AP.722020_TMY3.epw'
    args['heating_system_heating_capacity'] = 12000.0
  elsif ['base-location-phoenix-az.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'USA_AZ_Phoenix-Sky.Harbor.Intl.AP.722780_TMY3.epw'
    args['heating_system_heating_capacity'] = 24000.0
  elsif ['base-location-portland-or.xml'].include? hpxml_file
    args['weather_station_epw_filepath'] = 'USA_OR_Portland.Intl.AP.726980_TMY3.epw'
    args['heating_system_heating_capacity'] = 24000.0
  end

  # Mechanical Ventilation
  if ['base-mechvent-balanced.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeBalanced
    args['mech_vent_fan_power'] = 60
  elsif ['base-mechvent-bath-kitchen-fans.xml'].include? hpxml_file
    args['kitchen_fans_quantity'] = 1
    args['kitchen_fans_flow_rate'] = 100.0
    args['kitchen_fans_hours_in_operation'] = 1.5
    args['kitchen_fans_power'] = 30.0
    args['kitchen_fans_start_hour'] = 18
    args['bathroom_fans_quantity'] = 2
    args['bathroom_fans_flow_rate'] = 50.0
    args['bathroom_fans_hours_in_operation'] = 1.5
    args['bathroom_fans_power'] = 15.0
    args['bathroom_fans_start_hour'] = 7
  elsif ['base-mechvent-cfis.xml',
         'base-mechvent-cfis-dse.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeCFIS
    args['mech_vent_flow_rate'] = 330
    args['mech_vent_hours_in_operation'] = 8
    args['mech_vent_fan_power'] = 300
  elsif ['base-mechvent-cfis-evap-cooler-only-ducted.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeCFIS
    args['mech_vent_flow_rate'] = 330
    args['mech_vent_hours_in_operation'] = 8
    args['mech_vent_fan_power'] = 300
  elsif ['base-mechvent-erv.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeERV
    args['mech_vent_fan_power'] = 60
  elsif ['base-mechvent-erv-atre-asre.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeERV
    args['mech_vent_recovery_efficiency_type'] = 'Adjusted'
    args['mech_vent_total_recovery_efficiency'] = 0.526
    args['mech_vent_sensible_recovery_efficiency'] = 0.79
    args['mech_vent_fan_power'] = 60
  elsif ['base-mechvent-exhaust.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeExhaust
  elsif ['base-mechvent-exhaust-rated-flow-rate.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeExhaust
  elsif ['base-mechvent-hrv.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeHRV
    args['mech_vent_fan_power'] = 60
  elsif ['base-mechvent-hrv-asre.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeHRV
    args['mech_vent_recovery_efficiency_type'] = 'Adjusted'
    args['mech_vent_sensible_recovery_efficiency'] = 0.79
    args['mech_vent_fan_power'] = 60
  elsif ['base-mechvent-supply.xml'].include? hpxml_file
    args['mech_vent_fan_type'] = HPXML::MechVentTypeSupply
  elsif ['base-mechvent-whole-house-fan.xml'].include? hpxml_file
    args['whole_house_fan_present'] = true
  end

  # Misc
  if ['base-misc-defaults.xml'].include? hpxml_file
    args.delete('simulation_control_timestep')
    args.delete('site_type')
    args['geometry_unit_num_bathrooms'] = Constants.Auto
    args['geometry_unit_num_occupants'] = Constants.Auto
    args['foundation_wall_insulation_distance_to_top'] = Constants.Auto
    args['foundation_wall_insulation_distance_to_bottom'] = Constants.Auto
    args['foundation_wall_thickness'] = Constants.Auto
    args['slab_thickness'] = Constants.Auto
    args['slab_carpet_fraction'] = Constants.Auto
    args.delete('roof_material_type')
    args['roof_color'] = HPXML::ColorLight
    args.delete('roof_material_type')
    args['roof_radiant_barrier'] = false
    args.delete('wall_siding_type')
    args['wall_color'] = HPXML::ColorMedium
    args.delete('window_fraction_operable')
    args.delete('window_interior_shading_winter')
    args.delete('window_interior_shading_summer')
    args.delete('cooling_system_cooling_compressor_type')
    args.delete('cooling_system_cooling_sensible_heat_fraction')
    args['mech_vent_fan_type'] = HPXML::MechVentTypeExhaust
    args['mech_vent_hours_in_operation'] = Constants.Auto
    args['mech_vent_fan_power'] = Constants.Auto
    args['ducts_supply_location'] = Constants.Auto
    args['ducts_return_location'] = Constants.Auto
    args['ducts_supply_surface_area'] = Constants.Auto
    args['ducts_return_surface_area'] = Constants.Auto
    args['kitchen_fans_quantity'] = Constants.Auto
    args['bathroom_fans_quantity'] = Constants.Auto
    args['water_heater_location'] = Constants.Auto
    args['water_heater_tank_volume'] = Constants.Auto
    args['water_heater_setpoint_temperature'] = Constants.Auto
    args['hot_water_distribution_standard_piping_length'] = Constants.Auto
    args['hot_water_distribution_pipe_r'] = Constants.Auto
    args['solar_thermal_system_type'] = HPXML::SolarThermalSystemType
    args['solar_thermal_collector_type'] = HPXML::SolarThermalTypeSingleGlazing
    args['solar_thermal_collector_rated_optical_efficiency'] = 0.77
    args['solar_thermal_collector_rated_thermal_losses'] = 0.793
    args['pv_system_module_type'] = Constants.Auto
    args.delete('pv_system_inverter_efficiency')
    args.delete('pv_system_system_losses_fraction')
    args['clothes_washer_location'] = Constants.Auto
    args['clothes_washer_efficiency'] = Constants.Auto
    args['clothes_washer_rated_annual_kwh'] = Constants.Auto
    args['clothes_washer_label_electric_rate'] = Constants.Auto
    args['clothes_washer_label_gas_rate'] = Constants.Auto
    args['clothes_washer_label_annual_gas_cost'] = Constants.Auto
    args['clothes_washer_label_usage'] = Constants.Auto
    args['clothes_washer_capacity'] = Constants.Auto
    args['clothes_dryer_location'] = Constants.Auto
    args['clothes_dryer_efficiency'] = Constants.Auto
    args['clothes_dryer_vented_flow_rate'] = Constants.Auto
    args['dishwasher_location'] = Constants.Auto
    args['dishwasher_efficiency'] = Constants.Auto
    args['dishwasher_label_electric_rate'] = Constants.Auto
    args['dishwasher_label_gas_rate'] = Constants.Auto
    args['dishwasher_label_annual_gas_cost'] = Constants.Auto
    args['dishwasher_label_usage'] = Constants.Auto
    args['dishwasher_place_setting_capacity'] = Constants.Auto
    args['refrigerator_location'] = Constants.Auto
    args['refrigerator_rated_annual_kwh'] = Constants.Auto
    args['cooking_range_oven_location'] = Constants.Auto
    args.delete('cooking_range_oven_is_induction')
    args.delete('cooking_range_oven_is_convection')
    args['ceiling_fan_present'] = true
    args['misc_plug_loads_television_annual_kwh'] = Constants.Auto
    args['misc_plug_loads_other_annual_kwh'] = Constants.Auto
    args['misc_plug_loads_other_frac_sensible'] = Constants.Auto
    args['misc_plug_loads_other_frac_latent'] = Constants.Auto
    args['mech_vent_flow_rate'] = Constants.Auto
    args['kitchen_fans_flow_rate'] = Constants.Auto
    args['bathroom_fans_flow_rate'] = Constants.Auto
    args['whole_house_fan_present'] = true
    args['whole_house_fan_flow_rate'] = Constants.Auto
    args['whole_house_fan_power'] = Constants.Auto
  elsif ['base-misc-loads-large-uncommon.xml'].include? hpxml_file
    args['extra_refrigerator_location'] = Constants.Auto
    args['extra_refrigerator_rated_annual_kwh'] = 700.0
    args['freezer_location'] = HPXML::LocationLivingSpace
    args['freezer_rated_annual_kwh'] = 300.0
    args['misc_plug_loads_well_pump_present'] = true
    args['misc_plug_loads_well_pump_annual_kwh'] = 475.0
    args['misc_plug_loads_well_pump_usage_multiplier'] = 1.0
    args['misc_plug_loads_vehicle_present'] = true
    args['misc_plug_loads_vehicle_annual_kwh'] = 1500.0
    args['misc_plug_loads_vehicle_usage_multiplier'] = 1.0
    args['misc_fuel_loads_grill_present'] = true
    args['misc_fuel_loads_grill_fuel_type'] = HPXML::FuelTypePropane
    args['misc_fuel_loads_grill_annual_therm'] = 25.0
    args['misc_fuel_loads_grill_usage_multiplier'] = 1.0
    args['misc_fuel_loads_lighting_present'] = true
    args['misc_fuel_loads_lighting_annual_therm'] = 28.0
    args['misc_fuel_loads_lighting_usage_multiplier'] = 1.0
    args['misc_fuel_loads_fireplace_present'] = true
    args['misc_fuel_loads_fireplace_fuel_type'] = HPXML::FuelTypeWoodCord
    args['misc_fuel_loads_fireplace_annual_therm'] = 55.0
    args['misc_fuel_loads_fireplace_frac_sensible'] = 0.5
    args['misc_fuel_loads_fireplace_frac_latent'] = 0.1
    args['misc_fuel_loads_fireplace_usage_multiplier'] = 1.0
    args['pool_present'] = true
    args['pool_heater_type'] = HPXML::HeaterTypeGas
    args['pool_pump_annual_kwh'] = 2700.0
    args['pool_heater_annual_therm'] = 500.0
    args['hot_tub_present'] = true
    args['hot_tub_pump_annual_kwh'] = 1000.0
    args['hot_tub_heater_annual_kwh'] = 1300.0
  elsif ['base-misc-loads-large-uncommon2.xml'].include? hpxml_file
    args['pool_heater_type'] = HPXML::TypeNone
    args['hot_tub_heater_type'] = HPXML::HeaterTypeHeatPump
    args['hot_tub_heater_annual_kwh'] = 260.0
    args['misc_fuel_loads_grill_fuel_type'] = HPXML::FuelTypeOil
    args['misc_fuel_loads_fireplace_fuel_type'] = HPXML::FuelTypeWoodPellets
  elsif ['base-misc-neighbor-shading.xml'].include? hpxml_file
    args['neighbor_back_distance'] = 10
    args['neighbor_front_distance'] = 15
    args['neighbor_front_height'] = 12
  elsif ['base-misc-shielding-of-home.xml'].include? hpxml_file
    args['site_shielding_of_home'] = HPXML::ShieldingWellShielded
  elsif ['base-misc-usage-multiplier.xml'].include? hpxml_file
    args['water_fixtures_usage_multiplier'] = 0.9
    args['lighting_interior_usage_multiplier'] = 0.9
    args['lighting_exterior_usage_multiplier'] = 0.9
    args['lighting_garage_usage_multiplier'] = 0.9
    args['clothes_washer_usage_multiplier'] = 0.9
    args['clothes_dryer_usage_multiplier'] = 0.9
    args['dishwasher_usage_multiplier'] = 0.9
    args['refrigerator_usage_multiplier'] = 0.9
    args['freezer_location'] = HPXML::LocationLivingSpace
    args['freezer_rated_annual_kwh'] = 300.0
    args['freezer_usage_multiplier'] = 0.9
    args['cooking_range_oven_usage_multiplier'] = 0.9
    args['misc_plug_loads_television_usage_multiplier'] = 0.9
    args['misc_plug_loads_other_usage_multiplier'] = 0.9
    args['pool_present'] = true
    args['pool_pump_annual_kwh'] = 2700.0
    args['pool_pump_usage_multiplier'] = 0.9
    args['pool_heater_type'] = HPXML::HeaterTypeGas
    args['pool_heater_annual_therm'] = 500.0
    args['pool_heater_usage_multiplier'] = 0.9
    args['hot_tub_present'] = true
    args['hot_tub_pump_annual_kwh'] = 1000.0
    args['hot_tub_pump_usage_multiplier'] = 0.9
    args['hot_tub_heater_type'] = HPXML::HeaterTypeElectricResistance
    args['hot_tub_heater_annual_kwh'] = 1300.0
    args['hot_tub_heater_usage_multiplier'] = 0.9
    args['misc_fuel_loads_grill_present'] = true
    args['misc_fuel_loads_grill_fuel_type'] = HPXML::FuelTypePropane
    args['misc_fuel_loads_grill_annual_therm'] = 25.0
    args['misc_fuel_loads_grill_usage_multiplier'] = 0.9
    args['misc_fuel_loads_lighting_present'] = true
    args['misc_fuel_loads_lighting_annual_therm'] = 28.0
    args['misc_fuel_loads_lighting_usage_multiplier'] = 0.9
    args['misc_fuel_loads_fireplace_present'] = true
    args['misc_fuel_loads_fireplace_fuel_type'] = HPXML::FuelTypeWoodCord
    args['misc_fuel_loads_fireplace_annual_therm'] = 55.0
    args['misc_fuel_loads_fireplace_frac_sensible'] = 0.5
    args['misc_fuel_loads_fireplace_frac_latent'] = 0.1
    args['misc_fuel_loads_fireplace_usage_multiplier'] = 0.9
  elsif ['base-misc-loads-none.xml'].include? hpxml_file
    args['misc_plug_loads_television_present'] = false
    args['misc_plug_loads_other_annual_kwh'] = 0.0
    args['misc_plug_loads_other_frac_sensible'] = Constants.Auto
    args['misc_plug_loads_other_frac_latent'] = Constants.Auto
  end

  # PV
  if ['base-pv.xml'].include? hpxml_file
    args['pv_system_module_type'] = HPXML::PVModuleTypeStandard
    args['pv_system_location'] = HPXML::LocationRoof
    args['pv_system_tracking'] = HPXML::PVTrackingTypeFixed
    args['pv_system_2_module_type'] = HPXML::PVModuleTypePremium
    args['pv_system_2_location'] = HPXML::LocationRoof
    args['pv_system_2_tracking'] = HPXML::PVTrackingTypeFixed
    args['pv_system_2_array_azimuth'] = 90
    args['pv_system_2_max_power_output'] = 1500
  end

  # Simulation Control
  if ['base-simcontrol-calendar-year-custom.xml'].include? hpxml_file
    args['simulation_control_run_period_calendar_year'] = 2008
  elsif ['base-simcontrol-daylight-saving-custom.xml'].include? hpxml_file
    args['simulation_control_daylight_saving_enabled'] = true
    args['simulation_control_daylight_saving_period'] = 'Mar 10 - Nov 6'
  elsif ['base-simcontrol-daylight-saving-disabled.xml'].include? hpxml_file
    args['simulation_control_daylight_saving_enabled'] = false
  elsif ['base-simcontrol-runperiod-1-month.xml'].include? hpxml_file
    args['simulation_control_run_period'] = 'Jan 1 - Jan 31'
  elsif ['base-simcontrol-timestep-10-mins.xml'].include? hpxml_file
    args['simulation_control_timestep'] = 10
  end
end

def apply_hpxml_modification_ashrae_140(hpxml_file, hpxml)
  # Set detailed HPXML values for ASHRAE 140 test files

  renumber_hpxml_ids(hpxml)

  # ------------ #
  # HPXML Header #
  # ------------ #

  hpxml.header.xml_generated_by = 'tasks.rb'
  hpxml.header.created_date_and_time = Time.new(2000, 1, 1).strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs
  hpxml.header.apply_ashrae140_assumptions = true
  hpxml.header.state_code = nil

  # --------------------- #
  # HPXML BuildingSummary #
  # --------------------- #

  hpxml.site.azimuth_of_front_of_home = nil
  hpxml.building_construction.average_ceiling_height = nil
  hpxml.climate_and_risk_zones.iecc_zone = nil

  # --------------- #
  # HPXML Enclosure #
  # --------------- #

  hpxml.attics[0].vented_attic_ach = 2.4
  hpxml.foundations.reverse_each do |foundation|
    foundation.delete
  end
  hpxml.roofs.each do |roof|
    if roof.roof_color == HPXML::ColorReflective
      roof.solar_absorptance = 0.2
    else
      roof.solar_absorptance = 0.6
    end
    roof.emittance = 0.9
    roof.roof_color = nil
  end
  (hpxml.walls + hpxml.rim_joists).each do |wall|
    if wall.color == HPXML::ColorReflective
      wall.solar_absorptance = 0.2
    else
      wall.solar_absorptance = 0.6
    end
    wall.emittance = 0.9
    wall.color = nil
    if wall.is_a?(HPXML::Wall)
      if wall.attic_wall_type == HPXML::AtticWallTypeGable
        wall.insulation_assembly_r_value = 2.15
      else
        wall.interior_finish_type = HPXML::InteriorFinishGypsumBoard
        wall.interior_finish_thickness = 0.5
      end
    end
  end
  hpxml.frame_floors.each do |frame_floor|
    next unless frame_floor.is_ceiling

    frame_floor.interior_finish_type = HPXML::InteriorFinishGypsumBoard
    frame_floor.interior_finish_thickness = 0.5
  end
  hpxml.foundation_walls.each do |fwall|
    if fwall.insulation_interior_r_value == 0
      fwall.interior_finish_type = HPXML::InteriorFinishNone
    else
      fwall.interior_finish_type = HPXML::InteriorFinishGypsumBoard
      fwall.interior_finish_thickness = 0.5
    end
  end
  if hpxml.doors.size == 1
    hpxml.doors[0].area /= 2.0
    hpxml.doors << hpxml.doors[0].dup
    hpxml.doors[1].azimuth = 0
  end
  hpxml.windows.each do |window|
    next if window.overhangs_depth.nil?

    window.overhangs_distance_to_bottom_of_window = 6.0
  end

  # ---------- #
  # HPXML HVAC #
  # ---------- #

  hpxml.hvac_controls.add(id: "HVACControl#{hpxml.hvac_controls.size + 1}",
                          heating_setpoint_temp: 68.0,
                          cooling_setpoint_temp: 78.0)

  # --------------- #
  # HPXML MiscLoads #
  # --------------- #

  hpxml.plug_loads[0].weekday_fractions = '0.0203, 0.0203, 0.0203, 0.0203, 0.0203, 0.0339, 0.0426, 0.0852, 0.0497, 0.0304, 0.0304, 0.0406, 0.0304, 0.0254, 0.0264, 0.0264, 0.0386, 0.0416, 0.0447, 0.0700, 0.0700, 0.0731, 0.0731, 0.0660'
  hpxml.plug_loads[0].weekend_fractions = '0.0203, 0.0203, 0.0203, 0.0203, 0.0203, 0.0339, 0.0426, 0.0852, 0.0497, 0.0304, 0.0304, 0.0406, 0.0304, 0.0254, 0.0264, 0.0264, 0.0386, 0.0416, 0.0447, 0.0700, 0.0700, 0.0731, 0.0731, 0.0660'
  hpxml.plug_loads[0].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'

  # ----- #
  # FINAL #
  # ----- #

  renumber_hpxml_ids(hpxml)
end

def apply_hpxml_modification(hpxml_file, hpxml)
  # Set detailed HPXML values for sample files

  if hpxml_file.include? 'split-surfaces'
    (hpxml.roofs + hpxml.rim_joists + hpxml.walls + hpxml.foundation_walls).each do |surface|
      surface.azimuth = nil
    end
    hpxml.collapse_enclosure_surfaces()
  end
  renumber_hpxml_ids(hpxml)

  # ------------ #
  # HPXML Header #
  # ------------ #

  # General logic for all files
  hpxml.header.xml_generated_by = 'tasks.rb'
  hpxml.header.created_date_and_time = Time.new(2000, 1, 1).strftime('%Y-%m-%dT%H:%M:%S%:z') # Hard-code to prevent diffs

  # Logic that can only be applied based on the file name
  if ['base-hvac-undersized-allow-increased-fixed-capacities.xml'].include? hpxml_file
    hpxml.header.allow_increased_fixed_capacities = true
  elsif ['base-schedules-detailed-stochastic.xml'].include? hpxml_file
    hpxml.header.schedules_filepath = 'HPXMLtoOpenStudio/resources/schedule_files/stochastic.csv'
  elsif ['base-schedules-detailed-stochastic-vacancy.xml'].include? hpxml_file
    hpxml.header.schedules_filepath = 'HPXMLtoOpenStudio/resources/schedule_files/stochastic-vacancy.csv'
  elsif ['base-schedules-detailed-smooth.xml'].include? hpxml_file
    hpxml.header.schedules_filepath = 'HPXMLtoOpenStudio/resources/schedule_files/smooth.csv'
  end

  # --------------------- #
  # HPXML BuildingSummary #
  # --------------------- #

  # General logic for all files
  hpxml.site.fuels = [HPXML::FuelTypeElectricity, HPXML::FuelTypeNaturalGas]

  # Logic that can only be applied based on the file name
  if ['base-schedules-simple.xml',
      'base-misc-loads-large-uncommon.xml',
      'base-misc-loads-large-uncommon2.xml'].include? hpxml_file
    hpxml.building_occupancy.weekday_fractions = '0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.053, 0.025, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.018, 0.033, 0.054, 0.054, 0.054, 0.061, 0.061, 0.061'
    hpxml.building_occupancy.weekend_fractions = '0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.061, 0.053, 0.025, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.015, 0.018, 0.033, 0.054, 0.054, 0.054, 0.061, 0.061, 0.061'
    hpxml.building_occupancy.monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
  elsif ['base-misc-defaults.xml'].include? hpxml_file
    hpxml.building_construction.average_ceiling_height = nil
    hpxml.building_construction.conditioned_building_volume = nil
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    hpxml.building_construction.number_of_conditioned_floors = 2
    hpxml.building_construction.number_of_conditioned_floors_above_grade = 1
    hpxml.building_construction.conditioned_floor_area = 2700
    hpxml.attics[0].attic_type = HPXML::AtticTypeCathedral
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.building_construction.conditioned_building_volume = 23850
    hpxml.air_infiltration_measurements[0].infiltration_volume = hpxml.building_construction.conditioned_building_volume
  elsif ['base-enclosure-split-level.xml'].include? hpxml_file
    hpxml.building_construction.number_of_conditioned_floors = 1.5
    hpxml.building_construction.number_of_conditioned_floors_above_grade = 1.5
  elsif ['base-foundation-walkout-basement.xml'].include? hpxml_file
    hpxml.building_construction.number_of_conditioned_floors_above_grade = 2
  elsif ['base-foundation-basement-garage.xml'].include? hpxml_file
    hpxml.building_construction.conditioned_floor_area -= 400 * 2
    hpxml.building_construction.conditioned_building_volume -= 400 * 2 * 8
    hpxml.air_infiltration_measurements[0].infiltration_volume = hpxml.building_construction.conditioned_building_volume
    hpxml.hvac_distributions[0].conditioned_floor_area_served = hpxml.building_construction.conditioned_floor_area
  end

  # --------------- #
  # HPXML Enclosure #
  # --------------- #

  # General logic for all files
  (hpxml.roofs + hpxml.walls + hpxml.rim_joists).each do |surface|
    surface.solar_absorptance = 0.7
    surface.emittance = 0.92
    if surface.is_a? HPXML::Roof
      surface.roof_color = nil
    else
      surface.color = nil
    end
  end
  hpxml.roofs.each do |roof|
    next unless roof.interior_adjacent_to == HPXML::LocationLivingSpace

    roof.interior_finish_type = HPXML::InteriorFinishGypsumBoard
  end
  (hpxml.walls + hpxml.foundation_walls + hpxml.frame_floors).each do |surface|
    if surface.is_a?(HPXML::FoundationWall) && surface.interior_adjacent_to != HPXML::LocationBasementConditioned
      surface.interior_finish_type = HPXML::InteriorFinishNone
    end
    next unless [HPXML::LocationLivingSpace,
                 HPXML::LocationBasementConditioned].include?(surface.interior_adjacent_to) &&
                [HPXML::LocationOutside,
                 HPXML::LocationGround,
                 HPXML::LocationGarage,
                 HPXML::LocationAtticUnvented,
                 HPXML::LocationAtticVented,
                 HPXML::LocationOtherHousingUnit,
                 HPXML::LocationBasementConditioned].include?(surface.exterior_adjacent_to)
    next if surface.is_a?(HPXML::FrameFloor) && surface.is_floor

    surface.interior_finish_type = HPXML::InteriorFinishGypsumBoard
  end
  hpxml.attics.each do |attic|
    if attic.attic_type == HPXML::AtticTypeUnvented
      attic.within_infiltration_volume = false
    elsif attic.attic_type == HPXML::AtticTypeVented
      attic.vented_attic_sla = 0.003
    end
  end
  hpxml.foundations.each do |foundation|
    if foundation.foundation_type == HPXML::FoundationTypeCrawlspaceUnvented
      foundation.within_infiltration_volume = false
    elsif foundation.foundation_type == HPXML::FoundationTypeCrawlspaceVented
      foundation.vented_crawlspace_sla = 0.00667
    end
  end
  hpxml.skylights.each do |skylight|
    skylight.interior_shading_factor_summer = 1.0
    skylight.interior_shading_factor_winter = 1.0
  end

  # Logic that can only be applied based on the file name
  if ['base-bldgtype-multifamily-adjacent-to-multifamily-buffer-space.xml',
      'base-bldgtype-multifamily-adjacent-to-non-freezing-space.xml',
      'base-bldgtype-multifamily-adjacent-to-other-heated-space.xml',
      'base-bldgtype-multifamily-adjacent-to-other-housing-unit.xml'].include? hpxml_file
    if hpxml_file == 'base-bldgtype-multifamily-adjacent-to-multifamily-buffer-space.xml'
      adjacent_to = HPXML::LocationOtherMultifamilyBufferSpace
    elsif hpxml_file == 'base-bldgtype-multifamily-adjacent-to-non-freezing-space.xml'
      adjacent_to = HPXML::LocationOtherNonFreezingSpace
    elsif hpxml_file == 'base-bldgtype-multifamily-adjacent-to-other-heated-space.xml'
      adjacent_to = HPXML::LocationOtherHeatedSpace
    elsif hpxml_file == 'base-bldgtype-multifamily-adjacent-to-other-housing-unit.xml'
      adjacent_to = HPXML::LocationOtherHousingUnit
    end
    hpxml.walls[-1].exterior_adjacent_to = adjacent_to
    hpxml.frame_floors[0].exterior_adjacent_to = adjacent_to
    hpxml.frame_floors[1].exterior_adjacent_to = adjacent_to
    if hpxml_file != 'base-bldgtype-multifamily-adjacent-to-other-housing-unit.xml'
      hpxml.walls[-1].insulation_assembly_r_value = 23
      hpxml.frame_floors[0].insulation_assembly_r_value = 18.7
      hpxml.frame_floors[1].insulation_assembly_r_value = 18.7
    end
    hpxml.windows.each do |window|
      window.area *= 0.35
    end
    hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                    wall_idref: hpxml.walls[-1].id,
                    area: 20,
                    azimuth: 0,
                    r_value: 4.4)
    hpxml.hvac_distributions[0].ducts[0].duct_location = adjacent_to
    hpxml.hvac_distributions[0].ducts[1].duct_location = adjacent_to
    hpxml.water_heating_systems[0].location = adjacent_to
    hpxml.clothes_washers[0].location = adjacent_to
    hpxml.clothes_dryers[0].location = adjacent_to
    hpxml.dishwashers[0].location = adjacent_to
    hpxml.refrigerators[0].location = adjacent_to
    hpxml.cooking_ranges[0].location = adjacent_to
  elsif ['base-bldgtype-multifamily-adjacent-to-multiple.xml'].include? hpxml_file
    hpxml.walls[-1].delete
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationOtherHeatedSpace,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 100,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                    insulation_assembly_r_value: 23.0)
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationOtherMultifamilyBufferSpace,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 100,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                    insulation_assembly_r_value: 23.0)
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationOtherNonFreezingSpace,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 100,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                    insulation_assembly_r_value: 23.0)
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationOtherHousingUnit,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 100,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                    insulation_assembly_r_value: 4.0)
    hpxml.frame_floors[-1].delete
    hpxml.frame_floors.add(id: "FrameFloor#{hpxml.frame_floors.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOtherNonFreezingSpace,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 550,
                           insulation_assembly_r_value: 18.7,
                           other_space_above_or_below: HPXML::FrameFloorOtherSpaceBelow)
    hpxml.frame_floors.add(id: "FrameFloor#{hpxml.frame_floors.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOtherMultifamilyBufferSpace,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 200,
                           insulation_assembly_r_value: 18.7,
                           other_space_above_or_below: HPXML::FrameFloorOtherSpaceBelow)
    hpxml.frame_floors.add(id: "FrameFloor#{hpxml.frame_floors.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOtherHeatedSpace,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 150,
                           insulation_assembly_r_value: 2.1,
                           other_space_above_or_below: HPXML::FrameFloorOtherSpaceBelow)
    wall = hpxml.walls.select { |w|
             w.interior_adjacent_to == HPXML::LocationLivingSpace &&
               w.exterior_adjacent_to == HPXML::LocationOtherMultifamilyBufferSpace
           }           [0]
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 50,
                      azimuth: 270,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0.67,
                      wall_idref: wall.id)
    wall = hpxml.walls.select { |w|
             w.interior_adjacent_to == HPXML::LocationLivingSpace &&
               w.exterior_adjacent_to == HPXML::LocationOtherHeatedSpace
           }           [0]
    hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                    wall_idref: wall.id,
                    area: 20,
                    azimuth: 0,
                    r_value: 4.4)
    wall = hpxml.walls.select { |w|
             w.interior_adjacent_to == HPXML::LocationLivingSpace &&
               w.exterior_adjacent_to == HPXML::LocationOtherHousingUnit
           }           [0]
    hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                    wall_idref: wall.id,
                    area: 20,
                    azimuth: 0,
                    r_value: 4.4)
  elsif ['base-enclosure-orientations.xml'].include? hpxml_file
    hpxml.windows.each do |window|
      window.orientation = { 0 => 'north', 90 => 'east', 180 => 'south', 270 => 'west' }[window.azimuth]
      window.azimuth = nil
    end
    hpxml.doors[0].delete
    hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                    wall_idref: 'Wall1',
                    area: 20,
                    orientation: HPXML::OrientationNorth,
                    r_value: 4.4)
    hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                    wall_idref: 'Wall1',
                    area: 20,
                    orientation: HPXML::OrientationSouth,
                    r_value: 4.4)
  elsif ['base-atticroof-conditioned.xml'].include? hpxml_file
    hpxml.roofs.each do |roof|
      roof.area = 1006.0 / hpxml.roofs.size
      roof.insulation_assembly_r_value = 25.8
    end
    hpxml.roofs.add(id: "Roof#{hpxml.roofs.size + 1}",
                    interior_adjacent_to: HPXML::LocationAtticUnvented,
                    area: 504,
                    roof_type: HPXML::RoofTypeAsphaltShingles,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    pitch: 6,
                    radiant_barrier: false,
                    insulation_assembly_r_value: 2.3)
    hpxml.rim_joists.each do |rim_joist|
      rim_joist.area = 116.0 / hpxml.rim_joists.size
    end
    hpxml.walls.each do |wall|
      wall.area = 1200.0 / hpxml.walls.size
    end
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationAtticUnvented,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 316,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                    insulation_assembly_r_value: 23.0)
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationLivingSpace,
                    wall_type: HPXML::WallTypeWoodStud,
                    siding: HPXML::SidingTypeWood,
                    area: 240,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                    insulation_assembly_r_value: 22.3)
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationAtticUnvented,
                    attic_wall_type: HPXML::AtticWallTypeGable,
                    wall_type: HPXML::WallTypeWoodStud,
                    siding: HPXML::SidingTypeWood,
                    area: 50,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 4.0)
    hpxml.foundation_walls.each do |foundation_wall|
      foundation_wall.area = 1200.0 / hpxml.foundation_walls.size
    end
    hpxml.frame_floors.add(id: "FrameFloor#{hpxml.frame_floors.size + 1}",
                           exterior_adjacent_to: HPXML::LocationAtticUnvented,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 450,
                           interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                           insulation_assembly_r_value: 39.3)
    hpxml.slabs[0].area = 1350
    hpxml.slabs[0].exposed_perimeter = 150
    hpxml.windows[1].area = 108
    hpxml.windows[3].area = 108
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 12,
                      azimuth: 90,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0,
                      wall_idref: hpxml.walls[-2].id)
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 62,
                      azimuth: 270,
                      ufactor: 0.3,
                      shgc: 0.45,
                      fraction_operable: 0,
                      wall_idref: hpxml.walls[-2].id)
  elsif ['base-foundation-unconditioned-basement-above-grade.xml'].include? hpxml_file
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 20,
                      azimuth: 0,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0.0,
                      wall_idref: hpxml.foundation_walls[0].id)
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 10,
                      azimuth: 90,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0.0,
                      wall_idref: hpxml.foundation_walls[0].id)
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 20,
                      azimuth: 180,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0.0,
                      wall_idref: hpxml.foundation_walls[0].id)
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 10,
                      azimuth: 270,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0.0,
                      wall_idref: hpxml.foundation_walls[0].id)
  elsif ['base-enclosure-skylights-physical-properties.xml'].include? hpxml_file
    hpxml.skylights[0].ufactor = nil
    hpxml.skylights[0].shgc = nil
    hpxml.skylights[0].glass_layers = HPXML::WindowLayersSinglePane
    hpxml.skylights[0].frame_type = HPXML::WindowFrameTypeWood
    hpxml.skylights[0].glass_type = HPXML::WindowGlassTypeTinted
    hpxml.skylights[1].ufactor = nil
    hpxml.skylights[1].shgc = nil
    hpxml.skylights[1].glass_layers = HPXML::WindowLayersDoublePane
    hpxml.skylights[1].frame_type = HPXML::WindowFrameTypeMetal
    hpxml.skylights[1].thermal_break = true
    hpxml.skylights[1].glass_type = HPXML::WindowGlassTypeLowE
    hpxml.skylights[1].gas_fill = HPXML::WindowGasKrypton
  elsif ['base-enclosure-skylights-shading.xml'].include? hpxml_file
    hpxml.skylights[0].exterior_shading_factor_summer = 0.1
    hpxml.skylights[0].exterior_shading_factor_winter = 0.9
    hpxml.skylights[0].interior_shading_factor_summer = 0.01
    hpxml.skylights[0].interior_shading_factor_winter = 0.99
    hpxml.skylights[1].exterior_shading_factor_summer = 0.5
    hpxml.skylights[1].exterior_shading_factor_winter = 0.0
    hpxml.skylights[1].interior_shading_factor_summer = 0.5
    hpxml.skylights[1].interior_shading_factor_winter = 1.0
  elsif ['base-enclosure-windows-physical-properties.xml'].include? hpxml_file
    hpxml.windows[0].ufactor = nil
    hpxml.windows[0].shgc = nil
    hpxml.windows[0].glass_layers = HPXML::WindowLayersSinglePane
    hpxml.windows[0].frame_type = HPXML::WindowFrameTypeWood
    hpxml.windows[0].glass_type = HPXML::WindowGlassTypeTinted
    hpxml.windows[1].ufactor = nil
    hpxml.windows[1].shgc = nil
    hpxml.windows[1].glass_layers = HPXML::WindowLayersDoublePane
    hpxml.windows[1].frame_type = HPXML::WindowFrameTypeVinyl
    hpxml.windows[1].glass_type = HPXML::WindowGlassTypeReflective
    hpxml.windows[1].gas_fill = HPXML::WindowGasAir
    hpxml.windows[2].ufactor = nil
    hpxml.windows[2].shgc = nil
    hpxml.windows[2].glass_layers = HPXML::WindowLayersDoublePane
    hpxml.windows[2].frame_type = HPXML::WindowFrameTypeMetal
    hpxml.windows[2].thermal_break = true
    hpxml.windows[2].glass_type = HPXML::WindowGlassTypeLowE
    hpxml.windows[2].gas_fill = HPXML::WindowGasArgon
    hpxml.windows[3].ufactor = nil
    hpxml.windows[3].shgc = nil
    hpxml.windows[3].glass_layers = HPXML::WindowLayersGlassBlock
  elsif ['base-enclosure-windows-shading.xml'].include? hpxml_file
    hpxml.windows[1].exterior_shading_factor_summer = 0.5
    hpxml.windows[1].exterior_shading_factor_winter = 0.5
    hpxml.windows[1].interior_shading_factor_summer = 0.5
    hpxml.windows[1].interior_shading_factor_winter = 0.5
    hpxml.windows[2].exterior_shading_factor_summer = 0.1
    hpxml.windows[2].exterior_shading_factor_winter = 0.9
    hpxml.windows[2].interior_shading_factor_summer = 0.01
    hpxml.windows[2].interior_shading_factor_winter = 0.99
    hpxml.windows[3].exterior_shading_factor_summer = 0.0
    hpxml.windows[3].exterior_shading_factor_winter = 1.0
    hpxml.windows[3].interior_shading_factor_summer = 0.0
    hpxml.windows[3].interior_shading_factor_winter = 1.0
  elsif ['base-misc-defaults.xml'].include? hpxml_file
    hpxml.attics.reverse_each do |attic|
      attic.delete
    end
    hpxml.foundations.reverse_each do |foundation|
      foundation.delete
    end
    hpxml.air_infiltration_measurements[0].infiltration_volume = nil
    (hpxml.roofs + hpxml.walls + hpxml.rim_joists).each do |surface|
      surface.solar_absorptance = nil
      surface.emittance = nil
      if surface.is_a? HPXML::Roof
        surface.radiant_barrier = nil
      end
    end
    (hpxml.walls + hpxml.foundation_walls).each do |wall|
      wall.interior_finish_type = nil
    end
    hpxml.foundation_walls.each do |fwall|
      fwall.length = fwall.area / fwall.height
      fwall.area = nil
    end
    hpxml.doors[0].azimuth = nil
  elsif ['base-enclosure-2stories.xml',
         'base-enclosure-2stories-garage.xml',
         'base-hvac-ducts-area-fractions.xml'].include? hpxml_file
    hpxml.rim_joists << hpxml.rim_joists[-1].dup
    hpxml.rim_joists[-1].id = "RimJoist#{hpxml.rim_joists.size}"
    hpxml.rim_joists[-1].interior_adjacent_to = HPXML::LocationLivingSpace
    hpxml.rim_joists[-1].area = 116
  elsif ['base-foundation-conditioned-basement-wall-interior-insulation.xml'].include? hpxml_file
    hpxml.foundation_walls.each do |foundation_wall|
      foundation_wall.insulation_interior_r_value = 10
      foundation_wall.insulation_interior_distance_to_top = 0
      foundation_wall.insulation_interior_distance_to_bottom = 8
      foundation_wall.insulation_exterior_r_value = 8.9
      foundation_wall.insulation_exterior_distance_to_top = 1
      foundation_wall.insulation_exterior_distance_to_bottom = 8
    end
  elsif ['base-foundation-walkout-basement.xml'].include? hpxml_file
    hpxml.foundation_walls.reverse_each do |foundation_wall|
      foundation_wall.delete
    end
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 8,
                               area: 480,
                               thickness: 8,
                               depth_below_grade: 7,
                               interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                               insulation_interior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 8,
                               insulation_exterior_r_value: 8.9)
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 4,
                               area: 120,
                               thickness: 8,
                               depth_below_grade: 3,
                               interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                               insulation_interior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 4,
                               insulation_exterior_r_value: 8.9)
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 2,
                               area: 60,
                               thickness: 8,
                               depth_below_grade: 1,
                               interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                               insulation_interior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 2,
                               insulation_exterior_r_value: 8.9)
    hpxml.foundation_walls.each do |foundation_wall|
      hpxml.foundations[0].attached_to_foundation_wall_idrefs << foundation_wall.id
    end
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 20,
                      azimuth: 0,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0.0,
                      wall_idref: hpxml.foundation_walls[-1].id)
  elsif ['base-foundation-multiple.xml'].include? hpxml_file
    hpxml.foundations.add(id: "Foundation#{hpxml.foundations.size + 1}",
                          foundation_type: HPXML::FoundationTypeCrawlspaceUnvented,
                          within_infiltration_volume: false)
    hpxml.rim_joists.each do |rim_joist|
      next unless rim_joist.exterior_adjacent_to == HPXML::LocationOutside

      rim_joist.exterior_adjacent_to = HPXML::LocationCrawlspaceUnvented
      rim_joist.siding = nil
    end
    hpxml.rim_joists.add(id: "RimJoist#{hpxml.rim_joists.size + 1}",
                         exterior_adjacent_to: HPXML::LocationOutside,
                         interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                         siding: HPXML::SidingTypeWood,
                         area: 81,
                         solar_absorptance: 0.7,
                         emittance: 0.92,
                         insulation_assembly_r_value: 4.0)
    hpxml.foundation_walls.each do |foundation_wall|
      foundation_wall.area /= 2.0
    end
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                               interior_adjacent_to: HPXML::LocationBasementUnconditioned,
                               height: 8,
                               area: 360,
                               thickness: 8,
                               depth_below_grade: 4,
                               insulation_interior_r_value: 0,
                               insulation_exterior_r_value: 0)
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                               height: 4,
                               area: 600,
                               thickness: 8,
                               depth_below_grade: 3,
                               insulation_interior_r_value: 0,
                               insulation_exterior_r_value: 0)
    hpxml.frame_floors[1].area = 675
    hpxml.frame_floors.add(id: "FrameFloor#{hpxml.frame_floors.size + 1}",
                           exterior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 675,
                           insulation_assembly_r_value: 18.7)
    hpxml.slabs[0].area = 675
    hpxml.slabs[0].exposed_perimeter = 75
    hpxml.slabs.add(id: "Slab#{hpxml.slabs.size + 1}",
                    interior_adjacent_to: HPXML::LocationCrawlspaceUnvented,
                    area: 675,
                    thickness: 0,
                    exposed_perimeter: 75,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
  elsif ['base-foundation-complex.xml'].include? hpxml_file
    hpxml.foundation_walls.reverse_each do |foundation_wall|
      foundation_wall.delete
    end
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 8,
                               area: 160,
                               thickness: 8,
                               depth_below_grade: 7,
                               interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                               insulation_interior_r_value: 0,
                               insulation_exterior_r_value: 0.0)
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 8,
                               area: 240,
                               thickness: 8,
                               depth_below_grade: 7,
                               interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                               insulation_interior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 8,
                               insulation_exterior_r_value: 8.9)
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 4,
                               area: 160,
                               thickness: 8,
                               depth_below_grade: 3,
                               interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                               insulation_interior_r_value: 0,
                               insulation_exterior_r_value: 0.0)
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 4,
                               area: 120,
                               thickness: 8,
                               depth_below_grade: 3,
                               interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                               insulation_interior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 4,
                               insulation_exterior_r_value: 8.9)
    hpxml.foundation_walls.add(id: "FoundationWall#{hpxml.foundation_walls.size + 1}",
                               exterior_adjacent_to: HPXML::LocationGround,
                               interior_adjacent_to: HPXML::LocationBasementConditioned,
                               height: 4,
                               area: 80,
                               thickness: 8,
                               depth_below_grade: 3,
                               interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                               insulation_interior_r_value: 0,
                               insulation_exterior_distance_to_top: 0,
                               insulation_exterior_distance_to_bottom: 4,
                               insulation_exterior_r_value: 8.9)
    hpxml.foundation_walls.each do |foundation_wall|
      hpxml.foundations[0].attached_to_foundation_wall_idrefs << foundation_wall.id
    end
    hpxml.slabs.reverse_each do |slab|
      slab.delete
    end
    hpxml.slabs.add(id: "Slab#{hpxml.slabs.size + 1}",
                    interior_adjacent_to: HPXML::LocationBasementConditioned,
                    area: 675,
                    thickness: 4,
                    exposed_perimeter: 75,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
    hpxml.slabs.add(id: "Slab#{hpxml.slabs.size + 1}",
                    interior_adjacent_to: HPXML::LocationBasementConditioned,
                    area: 405,
                    thickness: 4,
                    exposed_perimeter: 45,
                    perimeter_insulation_depth: 1,
                    under_slab_insulation_width: 0,
                    perimeter_insulation_r_value: 5,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
    hpxml.slabs.add(id: "Slab#{hpxml.slabs.size + 1}",
                    interior_adjacent_to: HPXML::LocationBasementConditioned,
                    area: 270,
                    thickness: 4,
                    exposed_perimeter: 30,
                    perimeter_insulation_depth: 1,
                    under_slab_insulation_width: 0,
                    perimeter_insulation_r_value: 5,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
    hpxml.slabs.each do |slab|
      hpxml.foundations[0].attached_to_slab_idrefs << slab.id
    end
  elsif ['base-foundation-basement-garage.xml'].include? hpxml_file
    hpxml.roofs[0].area += 670
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationGarage,
                    interior_adjacent_to: HPXML::LocationBasementConditioned,
                    wall_type: HPXML::WallTypeWoodStud,
                    area: 320,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    interior_finish_type: HPXML::InteriorFinishGypsumBoard,
                    insulation_assembly_r_value: 23)
    hpxml.foundations[0].attached_to_wall_idrefs << hpxml.walls[-1].id
    hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                    exterior_adjacent_to: HPXML::LocationOutside,
                    interior_adjacent_to: HPXML::LocationGarage,
                    wall_type: HPXML::WallTypeWoodStud,
                    siding: HPXML::SidingTypeWood,
                    area: 320,
                    solar_absorptance: 0.7,
                    emittance: 0.92,
                    insulation_assembly_r_value: 4)
    hpxml.frame_floors.add(id: "FrameFloor#{hpxml.frame_floors.size + 1}",
                           exterior_adjacent_to: HPXML::LocationGarage,
                           interior_adjacent_to: HPXML::LocationLivingSpace,
                           area: 400,
                           insulation_assembly_r_value: 39.3)
    hpxml.slabs[0].area -= 400
    hpxml.slabs[0].exposed_perimeter -= 40
    hpxml.slabs.add(id: "Slab#{hpxml.slabs.size + 1}",
                    interior_adjacent_to: HPXML::LocationGarage,
                    area: 400,
                    thickness: 4,
                    exposed_perimeter: 40,
                    perimeter_insulation_depth: 0,
                    under_slab_insulation_width: 0,
                    depth_below_grade: 0,
                    perimeter_insulation_r_value: 0,
                    under_slab_insulation_r_value: 0,
                    carpet_fraction: 0,
                    carpet_r_value: 0)
    hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                    wall_idref: hpxml.walls[-3].id,
                    area: 70,
                    azimuth: 180,
                    r_value: 4.4)
    hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                    wall_idref: hpxml.walls[-2].id,
                    area: 4,
                    azimuth: 0,
                    r_value: 4.4)
  elsif ['base-enclosure-walltypes.xml'].include? hpxml_file
    hpxml.rim_joists.reverse_each do |rim_joist|
      rim_joist.delete
    end
    siding_types = [[HPXML::SidingTypeAluminum, HPXML::ColorDark],
                    [HPXML::SidingTypeAsbestos, HPXML::ColorMedium],
                    [HPXML::SidingTypeBrick, HPXML::ColorReflective],
                    [HPXML::SidingTypeCompositeShingle, HPXML::ColorDark],
                    [HPXML::SidingTypeFiberCement, HPXML::ColorMediumDark],
                    [HPXML::SidingTypeMasonite, HPXML::ColorLight],
                    [HPXML::SidingTypeStucco, HPXML::ColorMedium],
                    [HPXML::SidingTypeSyntheticStucco, HPXML::ColorMediumDark],
                    [HPXML::SidingTypeVinyl, HPXML::ColorLight],
                    [HPXML::SidingTypeNone, HPXML::ColorMedium]]
    siding_types.each_with_index do |siding_type, i|
      hpxml.rim_joists.add(id: "RimJoist#{hpxml.rim_joists.size + 1}",
                           exterior_adjacent_to: HPXML::LocationOutside,
                           interior_adjacent_to: HPXML::LocationBasementConditioned,
                           siding: siding_type[0],
                           color: siding_type[1],
                           area: 116 / siding_types.size,
                           emittance: 0.92,
                           insulation_assembly_r_value: 23.0)
      hpxml.foundations[0].attached_to_rim_joist_idrefs << hpxml.rim_joists[-1].id
    end
    gable_walls = hpxml.walls.select { |w| w.interior_adjacent_to == HPXML::LocationAtticUnvented }
    hpxml.walls.reverse_each do |wall|
      wall.delete
    end
    walls_map = { HPXML::WallTypeCMU => 12,
                  HPXML::WallTypeDoubleWoodStud => 28.7,
                  HPXML::WallTypeICF => 21,
                  HPXML::WallTypeLog => 7.1,
                  HPXML::WallTypeSIP => 16.1,
                  HPXML::WallTypeConcrete => 1.35,
                  HPXML::WallTypeSteelStud => 8.1,
                  HPXML::WallTypeStone => 5.4,
                  HPXML::WallTypeStrawBale => 58.8,
                  HPXML::WallTypeBrick => 7.9,
                  HPXML::WallTypeAdobe => 5.0 }
    siding_types = [[HPXML::SidingTypeAluminum, HPXML::ColorReflective],
                    [HPXML::SidingTypeAsbestos, HPXML::ColorLight],
                    [HPXML::SidingTypeBrick, HPXML::ColorMediumDark],
                    [HPXML::SidingTypeCompositeShingle, HPXML::ColorReflective],
                    [HPXML::SidingTypeFiberCement, HPXML::ColorMedium],
                    [HPXML::SidingTypeMasonite, HPXML::ColorDark],
                    [HPXML::SidingTypeStucco, HPXML::ColorLight],
                    [HPXML::SidingTypeSyntheticStucco, HPXML::ColorMedium],
                    [HPXML::SidingTypeVinyl, HPXML::ColorDark],
                    [HPXML::SidingTypeNone, HPXML::ColorMedium]]
    int_finish_types = [[HPXML::InteriorFinishGypsumBoard, 0.5],
                        [HPXML::InteriorFinishGypsumBoard, 1.0],
                        [HPXML::InteriorFinishGypsumCompositeBoard, 0.5],
                        [HPXML::InteriorFinishPlaster, 0.5],
                        [HPXML::InteriorFinishWood, 0.5],
                        [HPXML::InteriorFinishNone, nil]]
    walls_map.each_with_index do |(wall_type, assembly_r), i|
      hpxml.walls.add(id: "Wall#{hpxml.walls.size + 1}",
                      exterior_adjacent_to: HPXML::LocationOutside,
                      interior_adjacent_to: HPXML::LocationLivingSpace,
                      wall_type: wall_type,
                      siding: siding_types[i % siding_types.size][0],
                      color: siding_types[i % siding_types.size][1],
                      area: 1200 / walls_map.size,
                      emittance: 0.92,
                      interior_finish_type: int_finish_types[i % int_finish_types.size][0],
                      interior_finish_thickness: int_finish_types[i % int_finish_types.size][1],
                      insulation_assembly_r_value: assembly_r)
    end
    gable_walls.each do |gable_wall|
      hpxml.walls << gable_wall
      hpxml.walls[-1].id = "Wall#{hpxml.walls.size}"
      hpxml.attics[0].attached_to_wall_idrefs << hpxml.walls[-1].id
    end
    hpxml.windows.reverse_each do |window|
      window.delete
    end
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 108 / 8,
                      azimuth: 0,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0.67,
                      wall_idref: 'Wall1')
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 72 / 8,
                      azimuth: 90,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0.67,
                      wall_idref: 'Wall2')
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 108 / 8,
                      azimuth: 180,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0.67,
                      wall_idref: 'Wall3')
    hpxml.windows.add(id: "Window#{hpxml.windows.size + 1}",
                      area: 72 / 8,
                      azimuth: 270,
                      ufactor: 0.33,
                      shgc: 0.45,
                      fraction_operable: 0.67,
                      wall_idref: 'Wall4')
    hpxml.doors.reverse_each do |door|
      door.delete
    end
    hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                    wall_idref: 'Wall9',
                    area: 20,
                    azimuth: 0,
                    r_value: 4.4)
    hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                    wall_idref: 'Wall10',
                    area: 20,
                    azimuth: 180,
                    r_value: 4.4)
  elsif ['base-enclosure-rooftypes.xml'].include? hpxml_file
    hpxml.roofs.reverse_each do |roof|
      roof.delete
    end
    roof_types = [[HPXML::RoofTypeClayTile, HPXML::ColorLight],
                  [HPXML::RoofTypeMetal, HPXML::ColorReflective],
                  [HPXML::RoofTypeWoodShingles, HPXML::ColorDark],
                  [HPXML::RoofTypeShingles, HPXML::ColorMediumDark],
                  [HPXML::RoofTypePlasticRubber, HPXML::ColorLight],
                  [HPXML::RoofTypeEPS, HPXML::ColorMedium],
                  [HPXML::RoofTypeConcrete, HPXML::ColorLight],
                  [HPXML::RoofTypeCool, HPXML::ColorReflective]]
    int_finish_types = [[HPXML::InteriorFinishGypsumBoard, 0.5],
                        [HPXML::InteriorFinishPlaster, 0.5],
                        [HPXML::InteriorFinishWood, 0.5]]
    roof_types.each_with_index do |roof_type, i|
      hpxml.roofs.add(id: "Roof#{hpxml.roofs.size + 1}",
                      interior_adjacent_to: HPXML::LocationAtticUnvented,
                      area: 1509.3 / roof_types.size,
                      roof_type: roof_type[0],
                      roof_color: roof_type[1],
                      emittance: 0.92,
                      pitch: 6,
                      radiant_barrier: false,
                      interior_finish_type: int_finish_types[i % int_finish_types.size][0],
                      interior_finish_thickness: int_finish_types[i % int_finish_types.size][1],
                      insulation_assembly_r_value: roof_type[0] == HPXML::RoofTypeEPS ? 7.0 : 2.3)
      hpxml.attics[0].attached_to_roof_idrefs << hpxml.roofs[-1].id
    end
  elsif ['base-enclosure-split-surfaces.xml',
         'base-enclosure-split-surfaces2.xml'].include? hpxml_file
    for n in 1..hpxml.roofs.size
      hpxml.roofs[n - 1].area /= 9.0
      for i in 2..9
        hpxml.roofs << hpxml.roofs[n - 1].dup
        hpxml.roofs[-1].id += "_#{i}"
        if hpxml_file == 'base-enclosure-split-surfaces2.xml'
          hpxml.roofs[-1].insulation_assembly_r_value += 0.01 * i
        end
      end
    end
    hpxml.roofs << hpxml.roofs[-1].dup
    hpxml.roofs[-1].id += '_tiny'
    hpxml.roofs[-1].area = 0.05
    for n in 1..hpxml.rim_joists.size
      hpxml.rim_joists[n - 1].area /= 9.0
      for i in 2..9
        hpxml.rim_joists << hpxml.rim_joists[n - 1].dup
        hpxml.rim_joists[-1].id += "_#{i}"
        if hpxml_file == 'base-enclosure-split-surfaces2.xml'
          hpxml.rim_joists[-1].insulation_assembly_r_value += 0.01 * i
        end
      end
    end
    hpxml.rim_joists << hpxml.rim_joists[-1].dup
    hpxml.rim_joists[-1].id += '_tiny'
    hpxml.rim_joists[-1].area = 0.05
    for n in 1..hpxml.walls.size
      hpxml.walls[n - 1].area /= 9.0
      for i in 2..9
        hpxml.walls << hpxml.walls[n - 1].dup
        hpxml.walls[-1].id += "_#{i}"
        if hpxml_file == 'base-enclosure-split-surfaces2.xml'
          hpxml.walls[-1].insulation_assembly_r_value += 0.01 * i
        end
      end
    end
    hpxml.walls << hpxml.walls[-1].dup
    hpxml.walls[-1].id += '_tiny'
    hpxml.walls[-1].area = 0.05
    for n in 1..hpxml.foundation_walls.size
      hpxml.foundation_walls[n - 1].area /= 9.0
      for i in 2..9
        hpxml.foundation_walls << hpxml.foundation_walls[n - 1].dup
        hpxml.foundation_walls[-1].id += "_#{i}"
        if hpxml_file == 'base-enclosure-split-surfaces2.xml'
          hpxml.foundation_walls[-1].insulation_exterior_r_value += 0.01 * i
        end
      end
    end
    hpxml.foundation_walls << hpxml.foundation_walls[-1].dup
    hpxml.foundation_walls[-1].id += '_tiny'
    hpxml.foundation_walls[-1].area = 0.05
    for n in 1..hpxml.frame_floors.size
      hpxml.frame_floors[n - 1].area /= 9.0
      for i in 2..9
        hpxml.frame_floors << hpxml.frame_floors[n - 1].dup
        hpxml.frame_floors[-1].id += "_#{i}"
        if hpxml_file == 'base-enclosure-split-surfaces2.xml'
          hpxml.frame_floors[-1].insulation_assembly_r_value += 0.01 * i
        end
      end
    end
    hpxml.frame_floors << hpxml.frame_floors[-1].dup
    hpxml.frame_floors[-1].id += '_tiny'
    hpxml.frame_floors[-1].area = 0.05
    for n in 1..hpxml.slabs.size
      hpxml.slabs[n - 1].area /= 9.0
      hpxml.slabs[n - 1].exposed_perimeter /= 9.0
      for i in 2..9
        hpxml.slabs << hpxml.slabs[n - 1].dup
        hpxml.slabs[-1].id += "_#{i}"
        if hpxml_file == 'base-enclosure-split-surfaces2.xml'
          hpxml.slabs[-1].perimeter_insulation_depth += 0.01 * i
          hpxml.slabs[-1].perimeter_insulation_r_value += 0.01 * i
        end
      end
    end
    hpxml.slabs << hpxml.slabs[-1].dup
    hpxml.slabs[-1].id += '_tiny'
    hpxml.slabs[-1].area = 0.05
    area_adjustments = []
    for n in 1..hpxml.windows.size
      hpxml.windows[n - 1].area /= 9.0
      hpxml.windows[n - 1].fraction_operable = 0.0
      for i in 2..9
        hpxml.windows << hpxml.windows[n - 1].dup
        hpxml.windows[-1].id += "_#{i}"
        hpxml.windows[-1].wall_idref += "_#{i}"
        if i >= 4
          hpxml.windows[-1].fraction_operable = 1.0
        end
        next unless hpxml_file == 'base-enclosure-split-surfaces2.xml'

        hpxml.windows[-1].ufactor += 0.01 * i
        hpxml.windows[-1].interior_shading_factor_summer -= 0.02 * i
        hpxml.windows[-1].interior_shading_factor_winter -= 0.01 * i
      end
    end
    hpxml.windows << hpxml.windows[-1].dup
    hpxml.windows[-1].id += '_tiny'
    hpxml.windows[-1].area = 0.05
    for n in 1..hpxml.skylights.size
      hpxml.skylights[n - 1].area /= 9.0
      for i in 2..9
        hpxml.skylights << hpxml.skylights[n - 1].dup
        hpxml.skylights[-1].id += "_#{i}"
        hpxml.skylights[-1].roof_idref += "_#{i}"
        next unless hpxml_file == 'base-enclosure-split-surfaces2.xml'

        hpxml.skylights[-1].ufactor += 0.01 * i
        hpxml.skylights[-1].interior_shading_factor_summer -= 0.02 * i
        hpxml.skylights[-1].interior_shading_factor_winter -= 0.01 * i
      end
    end
    hpxml.skylights << hpxml.skylights[-1].dup
    hpxml.skylights[-1].id += '_tiny'
    hpxml.skylights[-1].area = 0.05
    area_adjustments = []
    for n in 1..hpxml.doors.size
      hpxml.doors[n - 1].area /= 9.0
      for i in 2..9
        hpxml.doors << hpxml.doors[n - 1].dup
        hpxml.doors[-1].id += "_#{i}"
        hpxml.doors[-1].wall_idref += "_#{i}"
        if hpxml_file == 'base-enclosure-split-surfaces2.xml'
          hpxml.doors[-1].r_value += 0.01 * i
        end
      end
    end
    hpxml.doors << hpxml.doors[-1].dup
    hpxml.doors[-1].id += '_tiny'
    hpxml.doors[-1].area = 0.05
  end
  if ['base-enclosure-2stories-garage.xml',
      'base-enclosure-garage.xml'].include? hpxml_file
    grg_wall = hpxml.walls.select { |w|
                 w.interior_adjacent_to == HPXML::LocationGarage &&
                   w.exterior_adjacent_to == HPXML::LocationOutside
               } [0]
    hpxml.doors.add(id: "Door#{hpxml.doors.size + 1}",
                    wall_idref: grg_wall.id,
                    area: 70,
                    azimuth: 180,
                    r_value: 4.4)
  end

  # ---------- #
  # HPXML HVAC #
  # ---------- #

  # General logic
  hpxml.heating_systems.each do |heating_system|
    if heating_system.heating_system_type == HPXML::HVACTypeBoiler &&
       heating_system.heating_system_fuel == HPXML::FuelTypeNaturalGas &&
       !heating_system.is_shared_system
      heating_system.electric_auxiliary_energy = 200
    elsif [HPXML::HVACTypeFloorFurnace,
           HPXML::HVACTypeWallFurnace,
           HPXML::HVACTypeFireplace,
           HPXML::HVACTypeFixedHeater,
           HPXML::HVACTypePortableHeater].include? heating_system.heating_system_type
      heating_system.fan_watts = 0
    elsif [HPXML::HVACTypeStove].include? heating_system.heating_system_type
      heating_system.fan_watts = 40
    end
  end
  hpxml.heat_pumps.each do |heat_pump|
    if heat_pump.heat_pump_type == HPXML::HVACTypeHeatPumpGroundToAir
      heat_pump.pump_watts_per_ton = 30.0
    end
  end

  # Logic that can only be applied based on the file name
  if hpxml_file.include?('chiller') || hpxml_file.include?('cooling-tower')
    # Handle chiller/cooling tower
    if hpxml_file.include? 'chiller'
      hpxml.cooling_systems.add(id: "CoolingSystem#{hpxml.cooling_systems.size + 1}",
                                cooling_system_type: HPXML::HVACTypeChiller,
                                cooling_system_fuel: HPXML::FuelTypeElectricity,
                                is_shared_system: true,
                                number_of_units_served: 6,
                                cooling_capacity: 24000 * 6,
                                cooling_efficiency_kw_per_ton: 0.9,
                                fraction_cool_load_served: 1.0,
                                primary_system: true)
    elsif hpxml_file.include? 'cooling-tower'
      hpxml.cooling_systems.add(id: "CoolingSystem#{hpxml.cooling_systems.size + 1}",
                                cooling_system_type: HPXML::HVACTypeCoolingTower,
                                cooling_system_fuel: HPXML::FuelTypeElectricity,
                                is_shared_system: true,
                                number_of_units_served: 6,
                                fraction_cool_load_served: 1.0,
                                primary_system: true)
    end
    if hpxml_file.include? 'boiler'
      hpxml.hvac_controls[0].cooling_setpoint_temp = 78.0
      hpxml.cooling_systems[-1].distribution_system_idref = hpxml.hvac_distributions[-1].id
    else
      hpxml.hvac_controls.add(id: "HVACControl#{hpxml.hvac_controls.size + 1}",
                              control_type: HPXML::HVACControlTypeManual,
                              cooling_setpoint_temp: 78.0)
      if hpxml_file.include? 'baseboard'
        hpxml.hvac_distributions.add(id: "HVACDistribution#{hpxml.hvac_distributions.size + 1}",
                                     distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                     hydronic_type: HPXML::HydronicTypeBaseboard)
        hpxml.cooling_systems[-1].distribution_system_idref = hpxml.hvac_distributions[-1].id
      end
    end
  end
  if hpxml_file.include?('water-loop-heat-pump') || hpxml_file.include?('fan-coil')
    # Handle WLHP/ducted fan coil
    hpxml.hvac_distributions.reverse_each do |hvac_distribution|
      hvac_distribution.delete
    end
    if hpxml_file.include? 'water-loop-heat-pump'
      hpxml.hvac_distributions.add(id: "HVACDistribution#{hpxml.hvac_distributions.size + 1}",
                                   distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                   hydronic_type: HPXML::HydronicTypeWaterLoop)
      hpxml.heat_pumps.add(id: "HeatPump#{hpxml.heat_pumps.size + 1}",
                           heat_pump_type: HPXML::HVACTypeHeatPumpWaterLoopToAir,
                           heat_pump_fuel: HPXML::FuelTypeElectricity)
      if hpxml_file.include? 'boiler'
        hpxml.heat_pumps[-1].heating_capacity = 24000
        hpxml.heat_pumps[-1].heating_efficiency_cop = 4.4
        hpxml.heating_systems[-1].distribution_system_idref = hpxml.hvac_distributions[-1].id
      end
      if hpxml_file.include?('chiller') || hpxml_file.include?('cooling-tower')
        hpxml.heat_pumps[-1].cooling_capacity = 24000
        hpxml.heat_pumps[-1].cooling_efficiency_eer = 12.8
        hpxml.cooling_systems[-1].distribution_system_idref = hpxml.hvac_distributions[-1].id
      end
      hpxml.hvac_distributions.add(id: "HVACDistribution#{hpxml.hvac_distributions.size + 1}",
                                   distribution_system_type: HPXML::HVACDistributionTypeAir,
                                   air_type: HPXML::AirTypeRegularVelocity)
      hpxml.heat_pumps[-1].distribution_system_idref = hpxml.hvac_distributions[-1].id
    elsif hpxml_file.include? 'fan-coil'
      hpxml.hvac_distributions.add(id: "HVACDistribution#{hpxml.hvac_distributions.size + 1}",
                                   distribution_system_type: HPXML::HVACDistributionTypeAir,
                                   air_type: HPXML::AirTypeFanCoil)

      if hpxml_file.include? 'boiler'
        hpxml.heating_systems[-1].distribution_system_idref = hpxml.hvac_distributions[-1].id
      end
      if hpxml_file.include?('chiller') || hpxml_file.include?('cooling-tower')
        hpxml.cooling_systems[-1].distribution_system_idref = hpxml.hvac_distributions[-1].id
      end
    end
    if hpxml_file.include?('water-loop-heat-pump') || hpxml_file.include?('fan-coil-ducted')
      hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                                 duct_leakage_units: HPXML::UnitsCFM25,
                                                                 duct_leakage_value: 15,
                                                                 duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
      hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                                 duct_leakage_units: HPXML::UnitsCFM25,
                                                                 duct_leakage_value: 10,
                                                                 duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
      hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                             duct_insulation_r_value: 0,
                                             duct_location: HPXML::LocationOtherMultifamilyBufferSpace,
                                             duct_surface_area: 50)
      hpxml.hvac_distributions[-1].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                             duct_insulation_r_value: 0,
                                             duct_location: HPXML::LocationOtherMultifamilyBufferSpace,
                                             duct_surface_area: 20)
      hpxml.hvac_distributions[-1].number_of_return_registers = 1
      hpxml.hvac_distributions[-1].conditioned_floor_area_served = 900
    end
  end
  if hpxml_file.include? 'shared-ground-loop'
    hpxml.heating_systems.reverse_each do |heating_system|
      heating_system.delete
    end
    hpxml.cooling_systems.reverse_each do |cooling_system|
      cooling_system.delete
    end
    hpxml.heat_pumps.add(id: "HeatPump#{hpxml.heat_pumps.size + 1}",
                         distribution_system_idref: hpxml.hvac_distributions[-1].id,
                         heat_pump_type: HPXML::HVACTypeHeatPumpGroundToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         is_shared_system: true,
                         number_of_units_served: 6,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 1,
                         fraction_cool_load_served: 1,
                         heating_efficiency_cop: 3.6,
                         cooling_efficiency_eer: 16.6,
                         heating_capacity: 12000,
                         cooling_capacity: 12000,
                         backup_heating_capacity: 12000,
                         cooling_shr: 0.73,
                         primary_heating_system: true,
                         primary_cooling_system: true,
                         pump_watts_per_ton: 0.0)

  end
  if hpxml_file.include? 'eae'
    hpxml.heating_systems[0].electric_auxiliary_energy = 500.0
  else
    if hpxml_file.include? 'shared-boiler'
      hpxml.heating_systems[0].shared_loop_watts = 600
    end
    if hpxml_file.include?('chiller') || hpxml_file.include?('cooling-tower')
      hpxml.cooling_systems[0].shared_loop_watts = 600
    end
    if hpxml_file.include? 'shared-ground-loop'
      hpxml.heat_pumps[0].shared_loop_watts = 600
    end
    if hpxml_file.include? 'fan-coil'
      if hpxml_file.include? 'boiler'
        hpxml.heating_systems[0].fan_coil_watts = 150
      end
      if hpxml_file.include? 'chiller'
        hpxml.cooling_systems[0].fan_coil_watts = 150
      end
    end
  end
  if hpxml_file.include? 'install-quality'
    hpxml.hvac_systems.each do |hvac_system|
      hvac_system.fan_watts_per_cfm = 0.365
    end
  elsif ['base-hvac-programmable-thermostat.xml'].include? hpxml_file
    hpxml.hvac_controls[0].heating_setback_temp = 66
    hpxml.hvac_controls[0].heating_setback_hours_per_week = 7 * 7
    hpxml.hvac_controls[0].heating_setback_start_hour = 23 # 11pm
    hpxml.hvac_controls[0].cooling_setup_temp = 80
    hpxml.hvac_controls[0].cooling_setup_hours_per_week = 6 * 7
    hpxml.hvac_controls[0].cooling_setup_start_hour = 9 # 9am
  elsif ['base-atticroof-cathedral.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].conditioned_floor_area_served = 2700
  elsif ['base-hvac-dse.xml',
         'base-dhw-indirect-dse.xml',
         'base-mechvent-cfis-dse.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].distribution_system_type = HPXML::HVACDistributionTypeDSE
    hpxml.hvac_distributions[0].annual_heating_dse = 0.8
    hpxml.hvac_distributions[0].annual_cooling_dse = 0.7
  elsif ['base-hvac-furnace-x3-dse.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].distribution_system_type = HPXML::HVACDistributionTypeDSE
    hpxml.hvac_distributions[0].annual_heating_dse = 0.8
    hpxml.hvac_distributions[0].annual_cooling_dse = 0.7
    hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
    hpxml.hvac_distributions[1].id = "HVACDistribution#{hpxml.hvac_distributions.size}"
    hpxml.hvac_distributions[1].annual_cooling_dse = 1.0
    hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
    hpxml.hvac_distributions[2].id = "HVACDistribution#{hpxml.hvac_distributions.size}"
    hpxml.hvac_distributions[2].annual_cooling_dse = 1.0
    hpxml.heating_systems[0].primary_system = false
    hpxml.heating_systems << hpxml.heating_systems[0].dup
    hpxml.heating_systems[1].id = "HeatingSystem#{hpxml.heating_systems.size}"
    hpxml.heating_systems[1].distribution_system_idref = hpxml.hvac_distributions[1].id
    hpxml.heating_systems << hpxml.heating_systems[0].dup
    hpxml.heating_systems[2].id = "HeatingSystem#{hpxml.heating_systems.size}"
    hpxml.heating_systems[2].distribution_system_idref = hpxml.hvac_distributions[2].id
    hpxml.heating_systems[2].primary_system = true
    for i in 0..2
      hpxml.heating_systems[i].heating_capacity /= 3.0
      # Test a file where sum is slightly greater than 1
      if i < 2
        hpxml.heating_systems[i].fraction_heat_load_served = 0.33
      else
        hpxml.heating_systems[i].fraction_heat_load_served = 0.35
      end
    end
  elsif ['base-misc-defaults.xml'].include? hpxml_file
    hpxml.heating_systems[0].year_installed = 2009
    hpxml.heating_systems[0].heating_efficiency_afue = nil
    hpxml.cooling_systems[0].year_installed = 2009
    hpxml.cooling_systems[0].cooling_efficiency_seer = nil
  elsif ['base-hvac-dual-fuel-air-to-air-heat-pump-1-speed-electric.xml'].include? hpxml_file
    hpxml.heat_pumps[0].backup_heating_efficiency_afue = hpxml.heat_pumps[0].backup_heating_efficiency_percent
    hpxml.heat_pumps[0].backup_heating_efficiency_percent = nil
  elsif ['base-enclosure-2stories.xml',
         'base-enclosure-2stories-garage.xml',
         'base-hvac-ducts-area-fractions.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts << hpxml.hvac_distributions[0].ducts[0].dup
    hpxml.hvac_distributions[0].ducts << hpxml.hvac_distributions[0].ducts[1].dup
    hpxml.hvac_distributions[0].ducts[2].duct_location = HPXML::LocationExteriorWall
    hpxml.hvac_distributions[0].ducts[2].duct_surface_area = 37.5
    hpxml.hvac_distributions[0].ducts[3].duct_location = HPXML::LocationLivingSpace
    hpxml.hvac_distributions[0].ducts[3].duct_surface_area = 12.5
    if hpxml_file == 'base-hvac-ducts-area-fractions.xml'
      hpxml.hvac_distributions[0].ducts[0].duct_surface_area = nil
      hpxml.hvac_distributions[0].ducts[1].duct_surface_area = nil
      hpxml.hvac_distributions[0].ducts[2].duct_surface_area = nil
      hpxml.hvac_distributions[0].ducts[3].duct_surface_area = nil
      hpxml.hvac_distributions[0].ducts[0].duct_fraction_area = 0.75
      hpxml.hvac_distributions[0].ducts[1].duct_fraction_area = 0.75
      hpxml.hvac_distributions[0].ducts[2].duct_fraction_area = 0.25
      hpxml.hvac_distributions[0].ducts[3].duct_fraction_area = 0.25
    end
  elsif ['base-hvac-multiple.xml'].include? hpxml_file
    hpxml.hvac_distributions.reverse_each do |hvac_distribution|
      hvac_distribution.delete
    end
    hpxml.hvac_distributions.add(id: "HVACDistribution#{hpxml.hvac_distributions.size + 1}",
                                 distribution_system_type: HPXML::HVACDistributionTypeAir,
                                 air_type: HPXML::AirTypeRegularVelocity,
                                 number_of_return_registers: 2,
                                 conditioned_floor_area_served: 270)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeSupply,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 75,
                                                               duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
    hpxml.hvac_distributions[-1].duct_leakage_measurements.add(duct_type: HPXML::DuctTypeReturn,
                                                               duct_leakage_units: HPXML::UnitsCFM25,
                                                               duct_leakage_value: 25,
                                                               duct_leakage_total_or_to_outside: HPXML::DuctLeakageToOutside)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: 8,
                                          duct_location: HPXML::LocationAtticUnvented,
                                          duct_surface_area: 75)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: 8,
                                          duct_location: HPXML::LocationOutside,
                                          duct_surface_area: 75)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: 4,
                                          duct_location: HPXML::LocationAtticUnvented,
                                          duct_surface_area: 25)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: 4,
                                          duct_location: HPXML::LocationOutside,
                                          duct_surface_area: 25)
    hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
    hpxml.hvac_distributions[-1].id = "HVACDistribution#{hpxml.hvac_distributions.size}"
    hpxml.hvac_distributions.add(id: "HVACDistribution#{hpxml.hvac_distributions.size + 1}",
                                 distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                 hydronic_type: HPXML::HydronicTypeBaseboard)
    hpxml.hvac_distributions.add(id: "HVACDistribution#{hpxml.hvac_distributions.size + 1}",
                                 distribution_system_type: HPXML::HVACDistributionTypeHydronic,
                                 hydronic_type: HPXML::HydronicTypeBaseboard)
    hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
    hpxml.hvac_distributions[-1].id = "HVACDistribution#{hpxml.hvac_distributions.size}"
    hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
    hpxml.hvac_distributions[-1].id = "HVACDistribution#{hpxml.hvac_distributions.size}"
    hpxml.heating_systems.reverse_each do |heating_system|
      heating_system.delete
    end
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: hpxml.hvac_distributions[0].id,
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: 6400,
                              heating_efficiency_afue: 1,
                              fraction_heat_load_served: 0.1)
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: hpxml.hvac_distributions[1].id,
                              heating_system_type: HPXML::HVACTypeFurnace,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 6400,
                              heating_efficiency_afue: 0.92,
                              fraction_heat_load_served: 0.1)
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: hpxml.hvac_distributions[2].id,
                              heating_system_type: HPXML::HVACTypeBoiler,
                              heating_system_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: 6400,
                              heating_efficiency_afue: 1,
                              fraction_heat_load_served: 0.1)
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              distribution_system_idref: hpxml.hvac_distributions[3].id,
                              heating_system_type: HPXML::HVACTypeBoiler,
                              heating_system_fuel: HPXML::FuelTypeNaturalGas,
                              heating_capacity: 6400,
                              heating_efficiency_afue: 0.92,
                              fraction_heat_load_served: 0.1,
                              electric_auxiliary_energy: 200)
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              heating_system_type: HPXML::HVACTypeElectricResistance,
                              heating_system_fuel: HPXML::FuelTypeElectricity,
                              heating_capacity: 6400,
                              heating_efficiency_percent: 1,
                              fraction_heat_load_served: 0.1)
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              heating_system_type: HPXML::HVACTypeStove,
                              heating_system_fuel: HPXML::FuelTypeOil,
                              heating_capacity: 6400,
                              heating_efficiency_percent: 0.8,
                              fraction_heat_load_served: 0.1,
                              fan_watts: 40.0)
    hpxml.heating_systems.add(id: "HeatingSystem#{hpxml.heating_systems.size + 1}",
                              heating_system_type: HPXML::HVACTypeWallFurnace,
                              heating_system_fuel: HPXML::FuelTypePropane,
                              heating_capacity: 6400,
                              heating_efficiency_afue: 0.8,
                              fraction_heat_load_served: 0.1,
                              fan_watts: 0.0)
    hpxml.cooling_systems[0].distribution_system_idref = hpxml.hvac_distributions[1].id
    hpxml.cooling_systems[0].fraction_cool_load_served = 0.2
    hpxml.cooling_systems[0].cooling_capacity *= 0.2
    hpxml.cooling_systems[0].primary_system = false
    hpxml.cooling_systems.add(id: "CoolingSystem#{hpxml.cooling_systems.size + 1}",
                              cooling_system_type: HPXML::HVACTypeRoomAirConditioner,
                              cooling_system_fuel: HPXML::FuelTypeElectricity,
                              cooling_capacity: 9600,
                              fraction_cool_load_served: 0.2,
                              cooling_efficiency_eer: 8.5,
                              cooling_shr: 0.65)
    hpxml.heat_pumps.add(id: "HeatPump#{hpxml.heat_pumps.size + 1}",
                         distribution_system_idref: hpxml.hvac_distributions[4].id,
                         heat_pump_type: HPXML::HVACTypeHeatPumpAirToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 4800,
                         cooling_capacity: 4800,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 3412,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 0.1,
                         fraction_cool_load_served: 0.2,
                         heating_efficiency_hspf: 7.7,
                         cooling_efficiency_seer: 13,
                         heating_capacity_17F: 4800 * 0.630, # Based on OAT slope of default curves
                         cooling_shr: 0.73,
                         compressor_type: HPXML::HVACCompressorTypeSingleStage)
    hpxml.heat_pumps.add(id: "HeatPump#{hpxml.heat_pumps.size + 1}",
                         distribution_system_idref: hpxml.hvac_distributions[5].id,
                         heat_pump_type: HPXML::HVACTypeHeatPumpGroundToAir,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 4800,
                         cooling_capacity: 4800,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 3412,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 0.1,
                         fraction_cool_load_served: 0.2,
                         heating_efficiency_cop: 3.6,
                         cooling_efficiency_eer: 16.6,
                         cooling_shr: 0.73,
                         pump_watts_per_ton: 30.0)
    f = 1.0 - (1.0 - 0.25) / (47.0 + 5.0) * (47.0 - 17.0)
    hpxml.heat_pumps.add(id: "HeatPump#{hpxml.heat_pumps.size + 1}",
                         heat_pump_type: HPXML::HVACTypeHeatPumpMiniSplit,
                         heat_pump_fuel: HPXML::FuelTypeElectricity,
                         heating_capacity: 4800,
                         cooling_capacity: 4800,
                         backup_heating_fuel: HPXML::FuelTypeElectricity,
                         backup_heating_capacity: 3412,
                         backup_heating_efficiency_percent: 1.0,
                         fraction_heat_load_served: 0.1,
                         fraction_cool_load_served: 0.2,
                         heating_efficiency_hspf: 10,
                         cooling_efficiency_seer: 19,
                         heating_capacity_17F: 4800 * f,
                         cooling_shr: 0.73,
                         primary_cooling_system: true,
                         primary_heating_system: true)
  elsif ['base-mechvent-multiple.xml',
         'base-bldgtype-multifamily-shared-mechvent-multiple.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].conditioned_floor_area_served /= 2.0
    hpxml.hvac_distributions << hpxml.hvac_distributions[0].dup
    hpxml.hvac_distributions[1].id = "HVACDistribution#{hpxml.hvac_distributions.size}"
    hpxml.heating_systems[0].heating_capacity /= 2.0
    hpxml.heating_systems[0].fraction_heat_load_served /= 2.0
    hpxml.heating_systems[0].primary_system = false
    hpxml.heating_systems << hpxml.heating_systems[0].dup
    hpxml.heating_systems[1].id = "HeatingSystem#{hpxml.heating_systems.size}"
    hpxml.heating_systems[1].distribution_system_idref = hpxml.hvac_distributions[1].id
    hpxml.heating_systems[1].primary_system = true
    hpxml.cooling_systems[0].fraction_cool_load_served /= 2.0
    hpxml.cooling_systems[0].cooling_capacity /= 2.0
    hpxml.cooling_systems[0].primary_system = false
    hpxml.cooling_systems << hpxml.cooling_systems[0].dup
    hpxml.cooling_systems[1].id = "CoolingSystem#{hpxml.cooling_systems.size}"
    hpxml.cooling_systems[1].distribution_system_idref = hpxml.hvac_distributions[1].id
    hpxml.cooling_systems[1].primary_system = true
  elsif ['base-bldgtype-multifamily-adjacent-to-multiple.xml'].include? hpxml_file
    hpxml.hvac_distributions[0].ducts[1].duct_location = HPXML::LocationOtherHousingUnit
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeSupply,
                                          duct_insulation_r_value: 4,
                                          duct_location: HPXML::LocationRoofDeck,
                                          duct_surface_area: 150)
    hpxml.hvac_distributions[0].ducts.add(duct_type: HPXML::DuctTypeReturn,
                                          duct_insulation_r_value: 0,
                                          duct_location: HPXML::LocationRoofDeck,
                                          duct_surface_area: 50)
  elsif ['base-appliances-dehumidifier-multiple.xml'].include? hpxml_file
    hpxml.dehumidifiers[0].fraction_served = 0.5
    hpxml.dehumidifiers.add(id: 'Dehumidifier2',
                            type: HPXML::DehumidifierTypePortable,
                            capacity: 30,
                            energy_factor: 1.6,
                            rh_setpoint: 0.5,
                            fraction_served: 0.25,
                            location: HPXML::LocationLivingSpace)
  end

  # ------------------ #
  # HPXML WaterHeating #
  # ------------------ #

  # Logic that can only be applied based on the file name
  if ['base-schedules-simple.xml',
      'base-misc-loads-large-uncommon.xml',
      'base-misc-loads-large-uncommon2.xml'].include? hpxml_file
    hpxml.water_heating.water_fixtures_weekday_fractions = '0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.087, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.039, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026'
    hpxml.water_heating.water_fixtures_weekend_fractions = '0.012, 0.006, 0.004, 0.005, 0.010, 0.034, 0.078, 0.087, 0.080, 0.067, 0.056, 0.047, 0.040, 0.035, 0.033, 0.031, 0.039, 0.051, 0.060, 0.060, 0.055, 0.048, 0.038, 0.026'
    hpxml.water_heating.water_fixtures_monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
  elsif ['base-bldgtype-multifamily-shared-water-heater-recirc.xml'].include? hpxml_file
    hpxml.hot_water_distributions[0].has_shared_recirculation = true
    hpxml.hot_water_distributions[0].shared_recirculation_number_of_units_served = 6
    hpxml.hot_water_distributions[0].shared_recirculation_pump_power = 220
    hpxml.hot_water_distributions[0].shared_recirculation_control_type = HPXML::DHWRecirControlTypeTimer
  elsif ['base-bldgtype-multifamily-shared-laundry-room.xml'].include? hpxml_file
    hpxml.water_heating_systems.reverse_each do |water_heating_system|
      water_heating_system.delete
    end
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    is_shared_system: true,
                                    number_of_units_served: 6,
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 120,
                                    fraction_dhw_load_served: 1.0,
                                    heating_capacity: 40000,
                                    energy_factor: 0.59,
                                    recovery_efficiency: 0.76,
                                    temperature: 125.0)
  elsif ['base-dhw-tank-gas-uef-fhr.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].first_hour_rating = 56.0
    hpxml.water_heating_systems[0].usage_bin = nil
  elsif ['base-dhw-tankless-electric-outside.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].performance_adjustment = 0.92
  elsif ['base-misc-defaults.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].year_installed = 2009
    hpxml.water_heating_systems[0].heating_capacity = nil
    hpxml.water_heating_systems[0].energy_factor = nil
  elsif ['base-dhw-multiple.xml'].include? hpxml_file
    hpxml.water_heating_systems[0].fraction_dhw_load_served = 0.2
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 50,
                                    fraction_dhw_load_served: 0.2,
                                    heating_capacity: 40000,
                                    energy_factor: 0.59,
                                    recovery_efficiency: 0.76,
                                    temperature: 125.0)
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeHeatPump,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 80,
                                    fraction_dhw_load_served: 0.2,
                                    energy_factor: 2.3,
                                    temperature: 125.0)
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    fuel_type: HPXML::FuelTypeElectricity,
                                    water_heater_type: HPXML::WaterHeaterTypeTankless,
                                    location: HPXML::LocationLivingSpace,
                                    fraction_dhw_load_served: 0.2,
                                    energy_factor: 0.99,
                                    temperature: 125.0)
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    fuel_type: HPXML::FuelTypeNaturalGas,
                                    water_heater_type: HPXML::WaterHeaterTypeTankless,
                                    location: HPXML::LocationLivingSpace,
                                    fraction_dhw_load_served: 0.1,
                                    energy_factor: 0.82,
                                    temperature: 125.0)
    hpxml.water_heating_systems.add(id: "WaterHeatingSystem#{hpxml.water_heating_systems.size + 1}",
                                    water_heater_type: HPXML::WaterHeaterTypeCombiStorage,
                                    location: HPXML::LocationLivingSpace,
                                    tank_volume: 50,
                                    fraction_dhw_load_served: 0.1,
                                    related_hvac_idref: 'HeatingSystem1',
                                    temperature: 125.0)
    hpxml.solar_thermal_systems.add(id: "SolarThermalSystem#{hpxml.solar_thermal_systems.size + 1}",
                                    system_type: HPXML::SolarThermalSystemType,
                                    water_heating_system_idref: nil, # Apply to all water heaters
                                    solar_fraction: 0.65)
  end

  # -------------------- #
  # HPXML VentilationFan #
  # -------------------- #

  # Logic that can only be applied based on the file name
  if ['base-bldgtype-multifamily-shared-mechvent-multiple.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeSupply,
                               is_shared_system: true,
                               in_unit_flow_rate: 100,
                               calculated_flow_rate: 1000,
                               hours_in_operation: 24,
                               fan_power: 300,
                               used_for_whole_building_ventilation: true,
                               fraction_recirculation: 0.0,
                               preheating_fuel: HPXML::FuelTypeNaturalGas,
                               preheating_efficiency_cop: 0.92,
                               preheating_fraction_load_served: 0.8,
                               precooling_fuel: HPXML::FuelTypeElectricity,
                               precooling_efficiency_cop: 4.0,
                               precooling_fraction_load_served: 0.8)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeERV,
                               is_shared_system: true,
                               in_unit_flow_rate: 50,
                               delivered_ventilation: 500,
                               hours_in_operation: 24,
                               total_recovery_efficiency: 0.48,
                               sensible_recovery_efficiency: 0.72,
                               fan_power: 150,
                               used_for_whole_building_ventilation: true,
                               fraction_recirculation: 0.4,
                               preheating_fuel: HPXML::FuelTypeNaturalGas,
                               preheating_efficiency_cop: 0.87,
                               preheating_fraction_load_served: 1.0,
                               precooling_fuel: HPXML::FuelTypeElectricity,
                               precooling_efficiency_cop: 3.5,
                               precooling_fraction_load_served: 1.0)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeHRV,
                               is_shared_system: true,
                               in_unit_flow_rate: 50,
                               rated_flow_rate: 500,
                               hours_in_operation: 24,
                               sensible_recovery_efficiency: 0.72,
                               fan_power: 150,
                               used_for_whole_building_ventilation: true,
                               fraction_recirculation: 0.3,
                               preheating_fuel: HPXML::FuelTypeElectricity,
                               preheating_efficiency_cop: 4.0,
                               precooling_fuel: HPXML::FuelTypeElectricity,
                               precooling_efficiency_cop: 4.5,
                               preheating_fraction_load_served: 1.0,
                               precooling_fraction_load_served: 1.0)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeBalanced,
                               is_shared_system: true,
                               in_unit_flow_rate: 30,
                               tested_flow_rate: 300,
                               hours_in_operation: 24,
                               fan_power: 150,
                               used_for_whole_building_ventilation: true,
                               fraction_recirculation: 0.3,
                               preheating_fuel: HPXML::FuelTypeElectricity,
                               preheating_efficiency_cop: 3.5,
                               precooling_fuel: HPXML::FuelTypeElectricity,
                               precooling_efficiency_cop: 4.0,
                               preheating_fraction_load_served: 0.9,
                               precooling_fraction_load_served: 1.0)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeExhaust,
                               is_shared_system: true,
                               in_unit_flow_rate: 70,
                               rated_flow_rate: 700,
                               hours_in_operation: 8,
                               fan_power: 300,
                               used_for_whole_building_ventilation: true,
                               fraction_recirculation: 0.0)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 50,
                               hours_in_operation: 14,
                               fan_power: 10,
                               used_for_whole_building_ventilation: true)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeCFIS,
                               tested_flow_rate: 160,
                               hours_in_operation: 8,
                               fan_power: 150,
                               used_for_whole_building_ventilation: true,
                               distribution_system_idref: 'HVACDistribution1')
  elsif ['base-mechvent-multiple.xml'].include? hpxml_file
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               rated_flow_rate: 2000,
                               fan_power: 150,
                               used_for_seasonal_cooling_load_reduction: true)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeSupply,
                               tested_flow_rate: 27.5,
                               hours_in_operation: 24,
                               fan_power: 7.5,
                               used_for_whole_building_ventilation: true)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeExhaust,
                               tested_flow_rate: 12.5,
                               hours_in_operation: 14,
                               fan_power: 2.5,
                               used_for_whole_building_ventilation: true)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeBalanced,
                               tested_flow_rate: 27.5,
                               hours_in_operation: 24,
                               fan_power: 15,
                               used_for_whole_building_ventilation: true)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeERV,
                               tested_flow_rate: 12.5,
                               hours_in_operation: 24,
                               total_recovery_efficiency: 0.48,
                               sensible_recovery_efficiency: 0.72,
                               fan_power: 6.25,
                               used_for_whole_building_ventilation: true)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeHRV,
                               tested_flow_rate: 15,
                               hours_in_operation: 24,
                               sensible_recovery_efficiency: 0.72,
                               fan_power: 7.5,
                               used_for_whole_building_ventilation: true)
    hpxml.ventilation_fans.reverse_each do |vent_fan|
      vent_fan.fan_power /= 2.0
      vent_fan.rated_flow_rate /= 2.0 unless vent_fan.rated_flow_rate.nil?
      vent_fan.tested_flow_rate /= 2.0 unless vent_fan.tested_flow_rate.nil?
      hpxml.ventilation_fans << vent_fan.dup
      hpxml.ventilation_fans[-1].id = "VentilationFan#{hpxml.ventilation_fans.size}"
      hpxml.ventilation_fans[-1].start_hour = vent_fan.start_hour - 1 unless vent_fan.start_hour.nil?
      hpxml.ventilation_fans[-1].hours_in_operation = vent_fan.hours_in_operation - 1 unless vent_fan.hours_in_operation.nil?
    end
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeCFIS,
                               tested_flow_rate: 40,
                               hours_in_operation: 8,
                               fan_power: 37.5,
                               used_for_whole_building_ventilation: true,
                               distribution_system_idref: 'HVACDistribution1')
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeCFIS,
                               tested_flow_rate: 42.5,
                               hours_in_operation: 8,
                               fan_power: 37.5,
                               used_for_whole_building_ventilation: true,
                               distribution_system_idref: 'HVACDistribution2')
    # Test ventilation system w/ zero airflow and hours
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeHRV,
                               tested_flow_rate: 0,
                               hours_in_operation: 24,
                               sensible_recovery_efficiency: 0.72,
                               fan_power: 7.5,
                               used_for_whole_building_ventilation: true)
    hpxml.ventilation_fans.add(id: "VentilationFan#{hpxml.ventilation_fans.size + 1}",
                               fan_type: HPXML::MechVentTypeHRV,
                               tested_flow_rate: 15,
                               hours_in_operation: 0,
                               sensible_recovery_efficiency: 0.72,
                               fan_power: 7.5,
                               used_for_whole_building_ventilation: true)
  end

  # ---------------- #
  # HPXML Generation #
  # ---------------- #

  # Logic that can only be applied based on the file name
  if ['base-misc-defaults.xml'].include? hpxml_file
    hpxml.pv_systems[0].year_modules_manufactured = 2015
  elsif ['base-misc-generators.xml'].include? hpxml_file
    hpxml.generators.add(id: "Generator#{hpxml.generators.size + 1}",
                         fuel_type: HPXML::FuelTypeNaturalGas,
                         annual_consumption_kbtu: 8500,
                         annual_output_kwh: 500)
    hpxml.generators.add(id: "Generator#{hpxml.generators.size + 1}",
                         fuel_type: HPXML::FuelTypeOil,
                         annual_consumption_kbtu: 8500,
                         annual_output_kwh: 500)
  elsif ['base-bldgtype-multifamily-shared-generator.xml'].include? hpxml_file
    hpxml.generators.add(id: "Generator#{hpxml.generators.size + 1}",
                         is_shared_system: true,
                         fuel_type: HPXML::FuelTypePropane,
                         annual_consumption_kbtu: 85000,
                         annual_output_kwh: 5000,
                         number_of_bedrooms_served: 18)
  end

  # ---------------- #
  # HPXML Appliances #
  # ---------------- #

  # Logic that can only be applied based on the file name
  if ['base-schedules-simple.xml',
      'base-misc-loads-large-uncommon.xml',
      'base-misc-loads-large-uncommon2.xml'].include? hpxml_file
    hpxml.clothes_washers[0].weekday_fractions = '0.009, 0.007, 0.004, 0.004, 0.007, 0.011, 0.022, 0.049, 0.073, 0.086, 0.084, 0.075, 0.067, 0.060, 0.049, 0.052, 0.050, 0.049, 0.049, 0.049, 0.049, 0.047, 0.032, 0.017'
    hpxml.clothes_washers[0].weekend_fractions = '0.009, 0.007, 0.004, 0.004, 0.007, 0.011, 0.022, 0.049, 0.073, 0.086, 0.084, 0.075, 0.067, 0.060, 0.049, 0.052, 0.050, 0.049, 0.049, 0.049, 0.049, 0.047, 0.032, 0.017'
    hpxml.clothes_washers[0].monthly_multipliers = '1.011, 1.002, 1.022, 1.020, 1.022, 0.996, 0.999, 0.999, 0.996, 0.964, 0.959, 1.011'
    hpxml.clothes_dryers[0].weekday_fractions = '0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024'
    hpxml.clothes_dryers[0].weekend_fractions = '0.010, 0.006, 0.004, 0.002, 0.004, 0.006, 0.016, 0.032, 0.048, 0.068, 0.078, 0.081, 0.074, 0.067, 0.057, 0.061, 0.055, 0.054, 0.051, 0.051, 0.052, 0.054, 0.044, 0.024'
    hpxml.clothes_dryers[0].monthly_multipliers = '1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0'
    hpxml.dishwashers[0].weekday_fractions = '0.015, 0.007, 0.005, 0.003, 0.003, 0.010, 0.020, 0.031, 0.058, 0.065, 0.056, 0.048, 0.041, 0.046, 0.036, 0.038, 0.038, 0.049, 0.087, 0.111, 0.090, 0.067, 0.044, 0.031'
    hpxml.dishwashers[0].weekend_fractions = '0.015, 0.007, 0.005, 0.003, 0.003, 0.010, 0.020, 0.031, 0.058, 0.065, 0.056, 0.048, 0.041, 0.046, 0.036, 0.038, 0.038, 0.049, 0.087, 0.111, 0.090, 0.067, 0.044, 0.031'
    hpxml.dishwashers[0].monthly_multipliers = '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097'
    hpxml.refrigerators[0].weekday_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
    hpxml.refrigerators[0].weekend_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
    hpxml.refrigerators[0].monthly_multipliers = '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
    hpxml.cooking_ranges[0].weekday_fractions = '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011'
    hpxml.cooking_ranges[0].weekend_fractions = '0.007, 0.007, 0.004, 0.004, 0.007, 0.011, 0.025, 0.042, 0.046, 0.048, 0.042, 0.050, 0.057, 0.046, 0.057, 0.044, 0.092, 0.150, 0.117, 0.060, 0.035, 0.025, 0.016, 0.011'
    hpxml.cooking_ranges[0].monthly_multipliers = '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097'
  end
  if ['base-misc-loads-large-uncommon.xml',
      'base-misc-loads-large-uncommon2.xml',
      'base-misc-usage-multiplier.xml'].include? hpxml_file
    if hpxml_file != 'base-misc-usage-multiplier.xml'
      hpxml.refrigerators.add(id: "Refrigerator#{hpxml.refrigerators.size + 1}",
                              rated_annual_kwh: 800,
                              primary_indicator: false)
    end
    hpxml.freezers.add(id: "Freezer#{hpxml.freezers.size + 1}",
                       location: HPXML::LocationLivingSpace,
                       rated_annual_kwh: 400)
    if hpxml_file == 'base-misc-usage-multiplier.xml'
      hpxml.freezers[-1].usage_multiplier = 0.9
    end
    (hpxml.refrigerators + hpxml.freezers).each do |appliance|
      next if appliance.is_a?(HPXML::Refrigerator) && hpxml_file == 'base-misc-usage-multiplier.xml'

      appliance.weekday_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
      appliance.weekend_fractions = '0.040, 0.039, 0.038, 0.037, 0.036, 0.036, 0.038, 0.040, 0.041, 0.041, 0.040, 0.040, 0.042, 0.042, 0.042, 0.041, 0.044, 0.048, 0.050, 0.048, 0.047, 0.046, 0.044, 0.041'
      appliance.monthly_multipliers = '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
    end
    hpxml.pools[0].pump_weekday_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
    hpxml.pools[0].pump_weekend_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
    hpxml.pools[0].pump_monthly_multipliers = '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
    hpxml.pools[0].heater_weekday_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
    hpxml.pools[0].heater_weekend_fractions = '0.003, 0.003, 0.003, 0.004, 0.008, 0.015, 0.026, 0.044, 0.084, 0.121, 0.127, 0.121, 0.120, 0.090, 0.075, 0.061, 0.037, 0.023, 0.013, 0.008, 0.004, 0.003, 0.003, 0.003'
    hpxml.pools[0].heater_monthly_multipliers = '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
    hpxml.hot_tubs[0].pump_weekday_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
    hpxml.hot_tubs[0].pump_weekend_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
    hpxml.hot_tubs[0].pump_monthly_multipliers = '0.837, 0.835, 1.084, 1.084, 1.084, 1.096, 1.096, 1.096, 1.096, 0.931, 0.925, 0.837'
    hpxml.hot_tubs[0].heater_weekday_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
    hpxml.hot_tubs[0].heater_weekend_fractions = '0.024, 0.029, 0.024, 0.029, 0.047, 0.067, 0.057, 0.024, 0.024, 0.019, 0.015, 0.014, 0.014, 0.014, 0.024, 0.058, 0.126, 0.122, 0.068, 0.061, 0.051, 0.043, 0.024, 0.024'
    hpxml.hot_tubs[0].heater_monthly_multipliers = '0.921, 0.928, 0.921, 0.915, 0.921, 1.160, 1.158, 1.158, 1.160, 0.921, 0.915, 0.921'
  end
  if ['base-bldgtype-multifamily-shared-laundry-room.xml'].include? hpxml_file
    hpxml.clothes_washers[0].is_shared_appliance = true
    hpxml.clothes_washers[0].location = HPXML::LocationOtherHeatedSpace
    hpxml.clothes_washers[0].water_heating_system_idref = hpxml.water_heating_systems[0].id
    hpxml.clothes_dryers[0].location = HPXML::LocationOtherHeatedSpace
    hpxml.clothes_dryers[0].is_shared_appliance = true
    hpxml.dishwashers[0].is_shared_appliance = true
    hpxml.dishwashers[0].location = HPXML::LocationOtherHeatedSpace
    hpxml.dishwashers[0].water_heating_system_idref = hpxml.water_heating_systems[0].id
  elsif ['base-misc-defaults.xml'].include? hpxml_file
    hpxml.refrigerators[0].primary_indicator = nil
  end

  # -------------- #
  # HPXML Lighting #
  # -------------- #

  # Logic that can only be applied based on the file name
  if ['base-lighting-ceiling-fans.xml'].include? hpxml_file
    hpxml.ceiling_fans[0].weekday_fractions = '0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057'
    hpxml.ceiling_fans[0].weekend_fractions = '0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.024, 0.057, 0.057, 0.057, 0.057, 0.057, 0.057'
    hpxml.ceiling_fans[0].monthly_multipliers = '0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0'
  elsif ['base-lighting-holiday.xml'].include? hpxml_file
    hpxml.lighting.holiday_weekday_fractions = '0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.008, 0.098, 0.168, 0.194, 0.284, 0.192, 0.037, 0.019'
    hpxml.lighting.holiday_weekend_fractions = '0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.008, 0.098, 0.168, 0.194, 0.284, 0.192, 0.037, 0.019'
  elsif ['base-schedules-simple.xml',
         'base-misc-loads-large-uncommon.xml',
         'base-misc-loads-large-uncommon2.xml'].include? hpxml_file
    hpxml.lighting.interior_weekday_fractions = '0.124, 0.074, 0.050, 0.050, 0.053, 0.140, 0.330, 0.420, 0.430, 0.424, 0.411, 0.394, 0.382, 0.378, 0.378, 0.379, 0.386, 0.412, 0.484, 0.619, 0.783, 0.880, 0.597, 0.249'
    hpxml.lighting.interior_weekend_fractions = '0.124, 0.074, 0.050, 0.050, 0.053, 0.140, 0.330, 0.420, 0.430, 0.424, 0.411, 0.394, 0.382, 0.378, 0.378, 0.379, 0.386, 0.412, 0.484, 0.619, 0.783, 0.880, 0.597, 0.249'
    hpxml.lighting.interior_monthly_multipliers = '1.075, 1.064951905, 1.0375, 1.0, 0.9625, 0.935048095, 0.925, 0.935048095, 0.9625, 1.0, 1.0375, 1.064951905'
    hpxml.lighting.exterior_weekday_fractions = '0.046, 0.046, 0.046, 0.046, 0.046, 0.037, 0.035, 0.034, 0.033, 0.028, 0.022, 0.015, 0.012, 0.011, 0.011, 0.012, 0.019, 0.037, 0.049, 0.065, 0.091, 0.105, 0.091, 0.063'
    hpxml.lighting.exterior_weekend_fractions = '0.046, 0.046, 0.045, 0.045, 0.046, 0.045, 0.044, 0.041, 0.036, 0.03, 0.024, 0.016, 0.012, 0.011, 0.011, 0.012, 0.019, 0.038, 0.048, 0.06, 0.083, 0.098, 0.085, 0.059'
    hpxml.lighting.exterior_monthly_multipliers = '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248'
    hpxml.lighting.garage_weekday_fractions = '0.046, 0.046, 0.046, 0.046, 0.046, 0.037, 0.035, 0.034, 0.033, 0.028, 0.022, 0.015, 0.012, 0.011, 0.011, 0.012, 0.019, 0.037, 0.049, 0.065, 0.091, 0.105, 0.091, 0.063'
    hpxml.lighting.garage_weekend_fractions = '0.046, 0.046, 0.045, 0.045, 0.046, 0.045, 0.044, 0.041, 0.036, 0.03, 0.024, 0.016, 0.012, 0.011, 0.011, 0.012, 0.019, 0.038, 0.048, 0.06, 0.083, 0.098, 0.085, 0.059'
    hpxml.lighting.garage_monthly_multipliers = '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248'
  end

  # --------------- #
  # HPXML MiscLoads #
  # --------------- #

  # Logic that can only be applied based on the file name
  if ['base-schedules-simple.xml',
      'base-misc-loads-large-uncommon.xml',
      'base-misc-loads-large-uncommon2.xml'].include? hpxml_file
    hpxml.plug_loads[0].weekday_fractions = '0.045, 0.019, 0.01, 0.001, 0.001, 0.001, 0.005, 0.009, 0.018, 0.026, 0.032, 0.038, 0.04, 0.041, 0.043, 0.045, 0.05, 0.055, 0.07, 0.085, 0.097, 0.108, 0.089, 0.07'
    hpxml.plug_loads[0].weekend_fractions = '0.045, 0.019, 0.01, 0.001, 0.001, 0.001, 0.005, 0.009, 0.018, 0.026, 0.032, 0.038, 0.04, 0.041, 0.043, 0.045, 0.05, 0.055, 0.07, 0.085, 0.097, 0.108, 0.089, 0.07'
    hpxml.plug_loads[0].monthly_multipliers = '1.137, 1.129, 0.961, 0.969, 0.961, 0.993, 0.996, 0.96, 0.993, 0.867, 0.86, 1.137'
    hpxml.plug_loads[1].weekday_fractions = '0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036'
    hpxml.plug_loads[1].weekend_fractions = '0.035, 0.033, 0.032, 0.031, 0.032, 0.033, 0.037, 0.042, 0.043, 0.043, 0.043, 0.044, 0.045, 0.045, 0.044, 0.046, 0.048, 0.052, 0.053, 0.05, 0.047, 0.045, 0.04, 0.036'
    hpxml.plug_loads[1].monthly_multipliers = '1.248, 1.257, 0.993, 0.989, 0.993, 0.827, 0.821, 0.821, 0.827, 0.99, 0.987, 1.248'
  end
  if ['base-misc-loads-large-uncommon.xml',
      'base-misc-loads-large-uncommon2.xml',
      'base-misc-usage-multiplier.xml'].include? hpxml_file
    if hpxml_file != 'base-misc-usage-multiplier.xml'
      hpxml.plug_loads[2].weekday_fractions = '0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042'
      hpxml.plug_loads[2].weekend_fractions = '0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042, 0.042'
      hpxml.plug_loads[2].monthly_multipliers = '1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1'
      hpxml.plug_loads[3].weekday_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
      hpxml.plug_loads[3].weekend_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
      hpxml.plug_loads[3].monthly_multipliers = '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
    end
    hpxml.fuel_loads[0].weekday_fractions = '0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007'
    hpxml.fuel_loads[0].weekend_fractions = '0.004, 0.001, 0.001, 0.002, 0.007, 0.012, 0.029, 0.046, 0.044, 0.041, 0.044, 0.046, 0.042, 0.038, 0.049, 0.059, 0.110, 0.161, 0.115, 0.070, 0.044, 0.019, 0.013, 0.007'
    hpxml.fuel_loads[0].monthly_multipliers = '1.097, 1.097, 0.991, 0.987, 0.991, 0.890, 0.896, 0.896, 0.890, 1.085, 1.085, 1.097'
    hpxml.fuel_loads[1].weekday_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
    hpxml.fuel_loads[1].weekend_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
    hpxml.fuel_loads[1].monthly_multipliers = '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
    hpxml.fuel_loads[2].weekday_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
    hpxml.fuel_loads[2].weekend_fractions = '0.044, 0.023, 0.019, 0.015, 0.016, 0.018, 0.026, 0.033, 0.033, 0.032, 0.033, 0.033, 0.032, 0.032, 0.032, 0.033, 0.045, 0.057, 0.066, 0.076, 0.081, 0.086, 0.075, 0.065'
    hpxml.fuel_loads[2].monthly_multipliers = '1.154, 1.161, 1.013, 1.010, 1.013, 0.888, 0.883, 0.883, 0.888, 0.978, 0.974, 1.154'
  end

  # ----- #
  # FINAL #
  # ----- #

  # Collapse some surfaces whose azimuth is a minor effect to simplify HPXMLs.
  if not hpxml_file.include? 'split-surfaces'
    (hpxml.roofs + hpxml.rim_joists + hpxml.walls + hpxml.foundation_walls).each do |surface|
      surface.azimuth = nil
    end
    hpxml.collapse_enclosure_surfaces()
  end

  renumber_hpxml_ids(hpxml)
end

def renumber_hpxml_ids(hpxml)
  # Renumber surfaces
  { hpxml.walls => 'Wall',
    hpxml.foundation_walls => 'FoundationWall',
    hpxml.rim_joists => 'RimJoist',
    hpxml.frame_floors => 'FrameFloor',
    hpxml.roofs => 'Roof',
    hpxml.slabs => 'Slab',
    hpxml.windows => 'Window',
    hpxml.doors => 'Door',
    hpxml.skylights => 'Skylight' }.each do |surfs, surf_name|
    surfs.each_with_index do |surf, i|
      (hpxml.attics + hpxml.foundations).each do |attic_or_fnd|
        if attic_or_fnd.respond_to?(:attached_to_roof_idrefs) && !attic_or_fnd.attached_to_roof_idrefs.nil? && !attic_or_fnd.attached_to_roof_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_roof_idrefs << "#{surf_name}#{i + 1}"
        end
        if attic_or_fnd.respond_to?(:attached_to_wall_idrefs) && !attic_or_fnd.attached_to_wall_idrefs.nil? && !attic_or_fnd.attached_to_wall_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_wall_idrefs << "#{surf_name}#{i + 1}"
        end
        if attic_or_fnd.respond_to?(:attached_to_rim_joist_idrefs) && !attic_or_fnd.attached_to_rim_joist_idrefs.nil? && !attic_or_fnd.attached_to_rim_joist_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_rim_joist_idrefs << "#{surf_name}#{i + 1}"
        end
        if attic_or_fnd.respond_to?(:attached_to_frame_floor_idrefs) && !attic_or_fnd.attached_to_frame_floor_idrefs.nil? && !attic_or_fnd.attached_to_frame_floor_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_frame_floor_idrefs << "#{surf_name}#{i + 1}"
        end
        if attic_or_fnd.respond_to?(:attached_to_slab_idrefs) && !attic_or_fnd.attached_to_slab_idrefs.nil? && !attic_or_fnd.attached_to_slab_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_slab_idrefs << "#{surf_name}#{i + 1}"
        end
        if attic_or_fnd.respond_to?(:attached_to_foundation_wall_idrefs) && !attic_or_fnd.attached_to_foundation_wall_idrefs.nil? && !attic_or_fnd.attached_to_foundation_wall_idrefs.delete(surf.id).nil?
          attic_or_fnd.attached_to_foundation_wall_idrefs << "#{surf_name}#{i + 1}"
        end
      end
      (hpxml.windows + hpxml.doors).each do |subsurf|
        if subsurf.respond_to?(:wall_idref) && (subsurf.wall_idref == surf.id)
          subsurf.wall_idref = "#{surf_name}#{i + 1}"
        end
      end
      hpxml.skylights.each do |subsurf|
        if subsurf.respond_to?(:roof_idref) && (subsurf.roof_idref == surf.id)
          subsurf.roof_idref = "#{surf_name}#{i + 1}"
        end
      end
      surf.id = "#{surf_name}#{i + 1}"
      if surf.respond_to? :insulation_id
        surf.insulation_id = "#{surf_name}#{i + 1}Insulation"
      end
      if surf.respond_to? :perimeter_insulation_id
        surf.perimeter_insulation_id = "#{surf_name}#{i + 1}PerimeterInsulation"
      end
      if surf.respond_to? :under_slab_insulation_id
        surf.under_slab_insulation_id = "#{surf_name}#{i + 1}UnderSlabInsulation"
      end
    end
  end
end

def download_epws
  require_relative 'HPXMLtoOpenStudio/resources/util'

  require 'tempfile'
  tmpfile = Tempfile.new('epw')

  UrlResolver.fetch('https://data.nrel.gov/system/files/128/tmy3s-cache-csv.zip', tmpfile)

  puts 'Extracting weather files...'
  weather_dir = File.join(File.dirname(__FILE__), 'weather')
  unzip_file = OpenStudio::UnzipFile.new(tmpfile.path.to_s)
  unzip_file.extractAllFiles(OpenStudio::toPath(weather_dir))

  num_epws_actual = Dir[File.join(weather_dir, '*.epw')].count
  puts "#{num_epws_actual} weather files are available in the weather directory."
  puts 'Completed.'
  exit!
end

def get_elements_from_sample_files(hpxml_docs)
  elements_being_used = []
  hpxml_docs.each do |xml, hpxml_doc|
    root = XMLHelper.get_element(hpxml_doc, '/HPXML')
    root.each_node do |node|
      next unless node.is_a?(Oga::XML::Element)

      ancestors = []
      node.each_ancestor do |parent_node|
        ancestors << ['h:', parent_node.name].join()
      end
      parent_element_xpath = ancestors.reverse
      child_element_xpath = ['h:', node.name].join()
      element_xpath = [parent_element_xpath, child_element_xpath].join('/')

      next if element_xpath.include? 'extension'

      elements_being_used << element_xpath if not elements_being_used.include? element_xpath
    end
  end

  return elements_being_used
end

def create_schematron_hpxml_validator(hpxml_docs)
  puts 'Generating HPXMLvalidator.xml...'
  elements_in_sample_files = get_elements_from_sample_files(hpxml_docs)

  base_elements_xsd = File.read(File.join(File.dirname(__FILE__), 'HPXMLtoOpenStudio', 'resources', 'BaseElements.xsd'))
  base_elements_xsd_doc = Oga.parse_xml(base_elements_xsd)

  # construct dictionary for enumerations and min/max values of HPXML data types
  hpxml_data_types_xsd = File.read(File.join(File.dirname(__FILE__), 'HPXMLtoOpenStudio', 'resources', 'HPXMLDataTypes.xsd'))
  hpxml_data_types_xsd_doc = Oga.parse_xml(hpxml_data_types_xsd)
  hpxml_data_types_dict = {}
  hpxml_data_types_xsd_doc.xpath('//xs:simpleType | //xs:complexType').each do |simple_type_element|
    enums = []
    simple_type_element.xpath('xs:restriction/xs:enumeration').each do |enum|
      enums << enum.get('value')
    end
    minInclusive_element = simple_type_element.at_xpath('xs:restriction/xs:minInclusive')
    min_inclusive = minInclusive_element.get('value') if not minInclusive_element.nil?
    maxInclusive_element = simple_type_element.at_xpath('xs:restriction/xs:maxInclusive')
    max_inclusive = maxInclusive_element.get('value') if not maxInclusive_element.nil?
    minExclusive_element = simple_type_element.at_xpath('xs:restriction/xs:minExclusive')
    min_exclusive = minExclusive_element.get('value') if not minExclusive_element.nil?
    maxExclusive_element = simple_type_element.at_xpath('xs:restriction/xs:maxExclusive')
    max_exclusive = maxExclusive_element.get('value') if not maxExclusive_element.nil?

    simple_type_element_name = simple_type_element.get('name')
    hpxml_data_types_dict[simple_type_element_name] = {}
    hpxml_data_types_dict[simple_type_element_name][:enums] = enums
    hpxml_data_types_dict[simple_type_element_name][:min_inclusive] = min_inclusive
    hpxml_data_types_dict[simple_type_element_name][:max_inclusive] = max_inclusive
    hpxml_data_types_dict[simple_type_element_name][:min_exclusive] = min_exclusive
    hpxml_data_types_dict[simple_type_element_name][:max_exclusive] = max_exclusive
  end

  # construct HPXMLvalidator.xml
  hpxml_validator = XMLHelper.create_doc(version = '1.0', encoding = 'UTF-8')
  root = XMLHelper.add_element(hpxml_validator, 'sch:schema')
  XMLHelper.add_attribute(root, 'xmlns:sch', 'http://purl.oclc.org/dsdl/schematron')
  XMLHelper.add_element(root, 'sch:title', 'HPXML Schematron Validator: HPXML.xsd', :string)
  name_space = XMLHelper.add_element(root, 'sch:ns')
  XMLHelper.add_attribute(name_space, 'uri', 'http://hpxmlonline.com/2019/10')
  XMLHelper.add_attribute(name_space, 'prefix', 'h')
  pattern = XMLHelper.add_element(root, 'sch:pattern')

  # construct complexType and group elements dictionary
  complex_type_or_group_dict = {}
  ['//xs:complexType', '//xs:group', '//xs:element'].each do |param|
    base_elements_xsd_doc.xpath(param).each do |param_type|
      next if param_type.name == 'element' && (not ['XMLTransactionHeaderInformation', 'ProjectStatus', 'SoftwareInfo'].include?(param_type.get('name')))
      next if param_type.get('name').nil?

      param_type_name = param_type.get('name')
      complex_type_or_group_dict[param_type_name] = {}

      param_type.each_node do |element|
        next unless element.is_a? Oga::XML::Element
        next unless (element.name == 'element' || element.name == 'group')
        next if element.name == 'element' && (element.get('name').nil? && element.get('ref').nil?)
        next if element.name == 'group' && element.get('ref').nil?

        ancestors = []
        element.each_ancestor do |node|
          next if node.get('name').nil?
          next if node.get('name') == param_type.get('name') # exclude complexType name from element xpath

          ancestors << node.get('name')
        end

        parent_element_names = ancestors.reverse
        if element.name == 'element'
          child_element_name = element.get('name')
          child_element_name = element.get('ref') if child_element_name.nil? # Backup
          element_type = element.get('type')
          element_type = element.get('ref') if element_type.nil? # Backup
        elsif element.name == 'group'
          child_element_name = nil # exclude group name from the element's xpath
          element_type = element.get('ref')
        end
        element_xpath = parent_element_names.push(child_element_name)
        complex_type_or_group_dict[param_type_name][element_xpath] = element_type
      end
    end
  end

  element_xpaths = {}
  top_level_elements_of_interest = elements_in_sample_files.map { |e| e.split('/')[1].gsub('h:', '') }.uniq
  top_level_elements_of_interest.each do |element|
    top_level_element = []
    top_level_element << element
    top_level_element_type = element
    get_element_full_xpaths(element_xpaths, complex_type_or_group_dict, top_level_element, top_level_element_type)
  end

  # Add enumeration and min/max numeric values
  rules = {}
  element_xpaths.each do |element_xpath, element_type|
    next if element_type.nil?

    # Skip element xpaths not being used in sample files
    element_xpath_with_prefix = element_xpath.compact.map { |e| "h:#{e}" }
    context_xpath = element_xpath_with_prefix.join('/').chomp('/')
    next unless elements_in_sample_files.any? { |item| item.include? context_xpath }

    hpxml_data_type_name = [element_type, '_simple'].join() # FUTURE: This may need to be improved later since enumeration and minimum/maximum values cannot be guaranteed to always be placed within simpleType.
    hpxml_data_type = hpxml_data_types_dict[hpxml_data_type_name]
    hpxml_data_type = hpxml_data_types_dict[element_type] if hpxml_data_type.nil? # Backup
    if hpxml_data_type.nil?
      fail "Could not find data type name for '#{element_type}'."
    end

    next if hpxml_data_type[:enums].empty? && hpxml_data_type[:min_inclusive].nil? && hpxml_data_type[:max_inclusive].nil? && hpxml_data_type[:min_exclusive].nil? && hpxml_data_type[:max_exclusive].nil?

    element_name = context_xpath.split('/')[-1]
    context_xpath = context_xpath.split('/')[0..-2].join('/').chomp('/').prepend('/h:HPXML/')
    rule = rules[context_xpath]
    if rule.nil?
      # Need new rule
      rule = XMLHelper.add_element(pattern, 'sch:rule')
      XMLHelper.add_attribute(rule, 'context', context_xpath)
      rules[context_xpath] = rule
    end

    if not hpxml_data_type[:enums].empty?
      assertion = XMLHelper.add_element(rule, 'sch:assert', "Expected #{element_name.gsub('h:', '')} to be \"#{hpxml_data_type[:enums].join('" or "')}\"", :string)
      XMLHelper.add_attribute(assertion, 'role', 'ERROR')
      XMLHelper.add_attribute(assertion, 'test', "#{element_name}[#{hpxml_data_type[:enums].map { |e| "text()=\"#{e}\"" }.join(' or ')}] or not(#{element_name})")
    else
      if hpxml_data_type[:min_inclusive]
        assertion = XMLHelper.add_element(rule, 'sch:assert', "Expected #{element_name.gsub('h:', '')} to be greater than or equal to #{hpxml_data_type[:min_inclusive]}", :string)
        XMLHelper.add_attribute(assertion, 'role', 'ERROR')
        XMLHelper.add_attribute(assertion, 'test', "number(#{element_name}) &gt;= #{hpxml_data_type[:min_inclusive]} or not(#{element_name})")
      end
      if hpxml_data_type[:max_inclusive]
        assertion = XMLHelper.add_element(rule, 'sch:assert', "Expected #{element_name.gsub('h:', '')} to be less than or equal to #{hpxml_data_type[:max_inclusive]}", :string)
        XMLHelper.add_attribute(assertion, 'role', 'ERROR')
        XMLHelper.add_attribute(assertion, 'test', "number(#{element_name}) &lt;= #{hpxml_data_type[:max_inclusive]} or not(#{element_name})")
      end
      if hpxml_data_type[:min_exclusive]
        assertion = XMLHelper.add_element(rule, 'sch:assert', "Expected #{element_name.gsub('h:', '')} to be greater than #{hpxml_data_type[:min_exclusive]}", :string)
        XMLHelper.add_attribute(assertion, 'role', 'ERROR')
        XMLHelper.add_attribute(assertion, 'test', "number(#{element_name}) &gt; #{hpxml_data_type[:min_exclusive]} or not(#{element_name})")
      end
      if hpxml_data_type[:max_exclusive]
        assertion = XMLHelper.add_element(rule, 'sch:assert', "Expected #{element_name.gsub('h:', '')} to be less than #{hpxml_data_type[:max_exclusive]}", :string)
        XMLHelper.add_attribute(assertion, 'role', 'ERROR')
        XMLHelper.add_attribute(assertion, 'test', "number(#{element_name}) &lt; #{hpxml_data_type[:max_exclusive]} or not(#{element_name})")
      end
    end
  end

  # Add ID/IDref checks
  # TODO: Dynamically obtain these lists
  id_names = ['SystemIdentifier',
              'BuildingID']
  idref_names = ['AttachedToRoof',
                 'AttachedToFrameFloor',
                 'AttachedToSlab',
                 'AttachedToFoundationWall',
                 'AttachedToWall',
                 'AttachedToRimJoist',
                 'DistributionSystem',
                 'AttachedToHVACDistributionSystem',
                 'RelatedHVACSystem',
                 'ConnectedTo']
  elements_in_sample_files.each do |element_xpath|
    element_name = element_xpath.split('/')[-1].gsub('h:', '')
    context_xpath = "/#{element_xpath.split('/')[0..-2].join('/')}"
    if id_names.include? element_name
      rule = rules[context_xpath]
      if rule.nil?
        # Need new rule
        rule = XMLHelper.add_element(pattern, 'sch:rule')
        XMLHelper.add_attribute(rule, 'context', context_xpath)
        rules[context_xpath] = rule
      end
      assertion = XMLHelper.add_element(rule, 'sch:assert', "Expected id attribute for #{element_name}", :string)
      XMLHelper.add_attribute(assertion, 'role', 'ERROR')
      XMLHelper.add_attribute(assertion, 'test', "count(h:#{element_name}[@id]) = count(h:#{element_name})")
    elsif idref_names.include?(element_name)
      rule = rules[context_xpath]
      if rule.nil?
        # Need new rule
        rule = XMLHelper.add_element(pattern, 'sch:rule')
        XMLHelper.add_attribute(rule, 'context', context_xpath)
        rules[context_xpath] = rule
      end
      assertion = XMLHelper.add_element(rule, 'sch:assert', "Expected idref attribute for #{element_name}", :string)
      XMLHelper.add_attribute(assertion, 'role', 'ERROR')
      XMLHelper.add_attribute(assertion, 'test', "count(h:#{element_name}[@idref]) = count(h:#{element_name})")
    end
  end

  XMLHelper.write_file(hpxml_validator, File.join(File.dirname(__FILE__), 'HPXMLtoOpenStudio', 'resources', 'HPXMLvalidator.xml'))
end

def get_element_full_xpaths(element_xpaths, complex_type_or_group_dict, element_xpath, element_type)
  if not complex_type_or_group_dict.keys.include? element_type
    element_xpaths[element_xpath] = element_type
  else
    complex_type_or_group = deep_copy_object(complex_type_or_group_dict[element_type])
    complex_type_or_group.each do |k, v|
      child_element_xpath = k.unshift(element_xpath).flatten!
      child_element_type = v

      if not complex_type_or_group_dict.keys.include? child_element_type
        element_xpaths[child_element_xpath] = child_element_type
        next
      end

      get_element_full_xpaths(element_xpaths, complex_type_or_group_dict, child_element_xpath, child_element_type)
    end
  end
end

def deep_copy_object(obj)
  return Marshal.load(Marshal.dump(obj))
end

command_list = [:update_measures, :update_hpxmls, :cache_weather, :create_release_zips, :download_weather]

def display_usage(command_list)
  puts "Usage: openstudio #{File.basename(__FILE__)} [COMMAND]\nCommands:\n  " + command_list.join("\n  ")
end

if ARGV.size == 0
  puts 'ERROR: Missing command.'
  display_usage(command_list)
  exit!
elsif ARGV.size > 1
  puts 'ERROR: Too many commands.'
  display_usage(command_list)
  exit!
elsif not command_list.include? ARGV[0].to_sym
  puts "ERROR: Invalid command '#{ARGV[0]}'."
  display_usage(command_list)
  exit!
end

if ARGV[0].to_sym == :update_measures
  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? && ENV['HOME'].start_with?('U:')
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? && ENV['HOMEDRIVE'].start_with?('U:')

  # Apply rubocop
  cops = ['Layout',
          'Lint/DeprecatedClassMethods',
          'Lint/RedundantStringCoercion',
          'Style/AndOr',
          'Style/FrozenStringLiteralComment',
          'Style/HashSyntax',
          'Style/Next',
          'Style/NilComparison',
          'Style/RedundantParentheses',
          'Style/RedundantSelf',
          'Style/ReturnNil',
          'Style/SelfAssignment',
          'Style/StringLiterals',
          'Style/StringLiteralsInInterpolation']
  commands = ["\"require 'rubocop/rake_task'\"",
              "\"RuboCop::RakeTask.new(:rubocop) do |t| t.options = ['--auto-correct', '--format', 'simple', '--only', '#{cops.join(',')}'] end\"",
              '"Rake.application[:rubocop].invoke"']
  command = "#{OpenStudio.getOpenStudioCLI} -e #{commands.join(' -e ')}"
  puts 'Applying rubocop auto-correct to measures...'
  system(command)

  # Update measures XMLs
  puts 'Updating measure.xmls...'
  require 'oga'
  require_relative 'HPXMLtoOpenStudio/resources/xmlhelper'
  Dir['**/measure.xml'].each do |measure_xml|
    for n_attempt in 1..5 # For some reason CLI randomly generates errors, so try multiple times; FIXME: Fix CLI so this doesn't happen
      measure_dir = File.dirname(measure_xml)
      command = "#{OpenStudio.getOpenStudioCLI} measure -u '#{measure_dir}'"
      system(command, [:out, :err] => File::NULL)

      # Check for error
      xml_doc = XMLHelper.parse_file(measure_xml)
      err_val = XMLHelper.get_value(xml_doc, '/measure/error', :string)
      if err_val.nil?
        err_val = XMLHelper.get_value(xml_doc, '/error', :string)
      end
      if err_val.nil?
        break # Successfully updated
      else
        if n_attempt == 5
          fail "#{measure_xml}: #{err_val}" # Error generated all 5 times, fail
        else
          # Remove error from measure XML, try again
          new_lines = File.readlines(measure_xml).select { |l| !l.include?('<error>') }
          File.open(measure_xml, 'w') do |file|
            file.puts new_lines
          end
        end
      end
    end
  end

  puts 'Done.'
end

if ARGV[0].to_sym == :update_hpxmls
  # Prevent NREL error regarding U: drive when not VPNed in
  ENV['HOME'] = 'C:' if !ENV['HOME'].nil? && ENV['HOME'].start_with?('U:')
  ENV['HOMEDRIVE'] = 'C:\\' if !ENV['HOMEDRIVE'].nil? && ENV['HOMEDRIVE'].start_with?('U:')

  # Create sample/test HPXMLs
  hpxml_docs = create_hpxmls()

  # Create Schematron file that reflects HPXML schema
  create_schematron_hpxml_validator(hpxml_docs)
end

if ARGV[0].to_sym == :cache_weather
  require_relative 'HPXMLtoOpenStudio/resources/weather'

  OpenStudio::Logger.instance.standardOutLogger.setLogLevel(OpenStudio::Fatal)
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  puts 'Creating cache *.csv for weather files...'

  Dir['weather/*.epw'].each do |epw|
    next if File.exist? epw.gsub('.epw', '.cache')

    puts "Processing #{epw}..."
    model = OpenStudio::Model::Model.new
    epw_file = OpenStudio::EpwFile.new(epw)
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file).get
    weather = WeatherProcess.new(model, runner)
    File.open(epw.gsub('.epw', '-cache.csv'), 'wb') do |file|
      weather.dump_to_csv(file)
    end
  end
end

if ARGV[0].to_sym == :download_weather
  download_epws
end

if ARGV[0].to_sym == :create_release_zips
  require_relative 'HPXMLtoOpenStudio/resources/version'

  release_map = { File.join(File.dirname(__FILE__), "OpenStudio-HPXML-v#{Version::OS_HPXML_Version}-minimal.zip") => false,
                  File.join(File.dirname(__FILE__), "OpenStudio-HPXML-v#{Version::OS_HPXML_Version}-full.zip") => true }

  release_map.keys.each do |zip_path|
    File.delete(zip_path) if File.exist? zip_path
  end

  if ENV['CI']
    # CI doesn't have git, so default to everything
    git_files = Dir['**/*.*']
  else
    # Only include files under git version control
    command = 'git ls-files'
    begin
      git_files = `#{command}`
    rescue
      puts "Command failed: '#{command}'. Perhaps git needs to be installed?"
      exit!
    end
  end

  files = ['Changelog.md',
           'LICENSE.md',
           'BuildResidentialHPXML/measure.*',
           'BuildResidentialHPXML/resources/*.*',
           'BuildResidentialScheduleFile/measure.*',
           'BuildResidentialScheduleFile/resources/*.*',
           'HPXMLtoOpenStudio/measure.*',
           'HPXMLtoOpenStudio/resources/*.*',
           'ReportSimulationOutput/measure.*',
           'ReportSimulationOutput/resources/*.*',
           'ReportHPXMLOutput/measure.*',
           'ReportHPXMLOutput/resources/*.*',
           'weather/*.*',
           'workflow/*.*',
           'workflow/sample_files/*.xml',
           'workflow/tests/*test*.rb',
           'workflow/tests/ASHRAE_Standard_140/*.xml',
           'workflow/tests/base_results/*.csv',
           'documentation/index.html',
           'documentation/_static/**/*.*']

  if not ENV['CI']
    # Generate documentation
    puts 'Generating documentation...'
    command = 'sphinx-build -b singlehtml docs/source documentation'
    begin
      `#{command}`
      if not File.exist? File.join(File.dirname(__FILE__), 'documentation', 'index.html')
        puts 'Documentation was not successfully generated. Aborting...'
        exit!
      end
    rescue
      puts "Command failed: '#{command}'. Perhaps sphinx needs to be installed?"
      exit!
    end
    FileUtils.rm_r(File.join(File.dirname(__FILE__), 'documentation', '_static', 'fonts'))

    # Check if we need to download weather files for the full release zip
    num_epws_expected = 1011
    num_epws_local = 0
    files.each do |f|
      Dir[f].each do |file|
        next unless file.end_with? '.epw'

        num_epws_local += 1
      end
    end

    # Make sure we have the full set of weather files
    if num_epws_local < num_epws_expected
      puts 'Fetching all weather files...'
      command = "#{OpenStudio.getOpenStudioCLI} #{__FILE__} download_weather"
      log = `#{command}`
    end
  end

  # Create zip files
  release_map.each do |zip_path, include_all_epws|
    puts "Creating #{zip_path}..."
    zip = OpenStudio::ZipFile.new(zip_path, false)
    files.each do |f|
      Dir[f].each do |file|
        if file.start_with? 'documentation'
          # always include
        elsif include_all_epws
          if (not git_files.include? file) && (not file.start_with? 'weather')
            next
          end
        else
          if not git_files.include? file
            next
          end
        end

        zip.addFile(file, File.join('OpenStudio-HPXML', file))
      end
    end
    puts "Wrote file at #{zip_path}."
  end

  # Cleanup
  if not ENV['CI']
    FileUtils.rm_r(File.join(File.dirname(__FILE__), 'documentation'))
  end

  puts 'Done.'
end
