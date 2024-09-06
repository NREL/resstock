# frozen_string_literal: true

# Collection of constants used across the code.
module Constants
  # Strings/Numbers
  AirFilm = 'AirFilm'
  AutomaticallyAdded = 'AutomaticallyAdded'
  Small = 1e-9

  # Object types
  ObjectTypeAirSourceHeatPump = 'air source heat pump'
  ObjectTypeBackupSuppHeat = 'back up supp heat'
  ObjectTypeBatteryLossesAdjustment = 'battery losses adjustment'
  ObjectTypeBoiler = 'boiler'
  ObjectTypeCeilingFan = 'ceiling fan'
  ObjectTypeCentralAirConditioner = 'central ac'
  ObjectTypeCentralAirConditionerAndFurnace = 'central ac and furnace'
  ObjectTypeClothesWasher = 'clothes washer'
  ObjectTypeClothesDryer = 'clothes dryer'
  ObjectTypeComponentLoadsProgram = 'component loads program'
  ObjectTypeCookingRange = 'cooking range'
  ObjectTypeDehumidifier = 'dehumidifier'
  ObjectTypeDishwasher = 'dishwasher'
  ObjectTypeDistributionWaste = 'dhw distribution waste'
  ObjectTypeDuctLoad = 'duct load'
  ObjectTypeElectricBaseboard = 'electric baseboard'
  ObjectTypeEvaporativeCooler = 'evap cooler'
  ObjectTypeEVBatteryDischargeOffset = 'ev battery discharge offset'
  ObjectTypeFanPumpDisaggregateCool = 'disaggregate clg'
  ObjectTypeFanPumpDisaggregatePrimaryHeat = 'disaggregate htg primary'
  ObjectTypeFanPumpDisaggregateBackupHeat = 'disaggregate htg backup'
  ObjectTypeFixtures = 'dhw fixtures'
  ObjectTypeFreezer = 'freezer'
  ObjectTypeFurnace = 'furnace'
  ObjectTypeGeneralWaterUse = 'general water use'
  ObjectTypeGeneralWaterUseLatent = 'general water use latent'
  ObjectTypeGeneralWaterUseSensible = 'general water use sensible'
  ObjectTypeGroundSourceHeatPump = 'ground source heat pump'
  ObjectTypeGSHPSharedPump = 'gshp shared loop pump'
  ObjectTypeHotWaterRecircPump = 'dhw recirc pump'
  ObjectTypeHVACAvailabilitySensor = 'hvac availability sensor'
  ObjectTypeIdealAirSystem = 'ideal air system'
  ObjectTypeInfiltration = 'infil'
  ObjectTypeLightingExterior = 'exterior lighting'
  ObjectTypeLightingExteriorHoliday = 'exterior holiday lighting'
  ObjectTypeLightingGarage = 'garage lighting'
  ObjectTypeLightingInterior = 'interior lighting'
  ObjectTypeMechanicalVentilation = 'mech vent'
  ObjectTypeMechanicalVentilationPrecooling = 'mech vent precooling'
  ObjectTypeMechanicalVentilationPreheating = 'mech vent preheating'
  ObjectTypeMechanicalVentilationHouseFan = 'mech vent house fan'
  ObjectTypeMechanicalVentilationHouseFanCFIS = 'mech vent house fan cfis'
  ObjectTypeMechanicalVentilationHouseFanCFISSupplFan = 'mech vent house fan cfis suppl'
  ObjectTypeMechanicalVentilationBathFan = 'mech vent bath fan'
  ObjectTypeMechanicalVentilationRangeFan = 'mech vent range fan'
  ObjectTypeMiniSplitAirConditioner = 'mini split air conditioner'
  ObjectTypeMiniSplitHeatPump = 'mini split heat pump'
  ObjectTypeMiscGrill = 'misc grill'
  ObjectTypeMiscLighting = 'misc lighting'
  ObjectTypeMiscFireplace = 'misc fireplace'
  ObjectTypeMiscPoolHeater = 'misc pool heater'
  ObjectTypeMiscPoolPump = 'misc pool pump'
  ObjectTypeMiscPermanentSpaHeater = 'misc permanent spa heater'
  ObjectTypeMiscPermanentSpaPump = 'misc permanent spa pump'
  ObjectTypeMiscPlugLoads = 'misc plug loads'
  ObjectTypeMiscTelevision = 'misc tv'
  ObjectTypeMiscElectricVehicleCharging = 'misc electric vehicle charging'
  ObjectTypeMiscWellPump = 'misc well pump'
  ObjectTypeNaturalVentilation = 'natural vent'
  ObjectTypeNeighbors = 'neighbors'
  ObjectTypeOccupants = 'occupants'
  ObjectTypePTAC = 'packaged terminal air conditioner'
  ObjectTypePTHP = 'packaged terminal heat pump'
  ObjectTypeRefrigerator = 'fridge'
  ObjectTypeRoomAC = 'room ac'
  ObjectTypeRoomHP = 'room ac with reverse cycle'
  ObjectTypeSolarHotWater = 'solar hot water'
  ObjectTypeTotalAirflowsProgram = 'total airflows program'
  ObjectTypeTotalLoadsProgram = 'total loads program'
  ObjectTypeUnitHeater = 'unit heater'
  ObjectTypeUnmetHoursProgram = 'unmet hours program'
  ObjectTypeWaterHeater = 'water heater'
  ObjectTypeWaterHeaterSetpoint = 'water heater setpoint'
  ObjectTypeWaterHeaterAdjustment = 'water heater energy adjustment'
  ObjectTypeWaterLoopHeatPump = 'water loop heat pump'
  ObjectTypeWholeHouseFan = 'whole house fan'

  # Arrays/Maps
  ERIVersions = ['2014', '2014A', '2014AE', '2014AEG', '2019', '2019A',
                 '2019AB', '2019ABC', '2019ABCD', '2022', '2022C']
  IECCZones = ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C',
               '4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8']
  StateCodesMap = { 'AK' => 'Alaska',
                    'AL' => 'Alabama',
                    'AR' => 'Arkansas',
                    'AZ' => 'Arizona',
                    'CA' => 'California',
                    'CO' => 'Colorado',
                    'CT' => 'Connecticut',
                    'DC' => 'District of Columbia',
                    'DE' => 'Delaware',
                    'FL' => 'Florida',
                    'GA' => 'Georgia',
                    'HI' => 'Hawaii',
                    'IA' => 'Iowa',
                    'ID' => 'Idaho',
                    'IL' => 'Illinois',
                    'IN' => 'Indiana',
                    'KS' => 'Kansas',
                    'KY' => 'Kentucky',
                    'LA' => 'Louisiana',
                    'MA' => 'Massachusetts',
                    'MD' => 'Maryland',
                    'ME' => 'Maine',
                    'MI' => 'Michigan',
                    'MN' => 'Minnesota',
                    'MO' => 'Missouri',
                    'MS' => 'Mississippi',
                    'MT' => 'Montana',
                    'NC' => 'North Carolina',
                    'ND' => 'North Dakota',
                    'NE' => 'Nebraska',
                    'NH' => 'New Hampshire',
                    'NJ' => 'New Jersey',
                    'NM' => 'New Mexico',
                    'NV' => 'Nevada',
                    'NY' => 'New York',
                    'OH' => 'Ohio',
                    'OK' => 'Oklahoma',
                    'OR' => 'Oregon',
                    'PA' => 'Pennsylvania',
                    'RI' => 'Rhode Island',
                    'SC' => 'South Carolina',
                    'SD' => 'South Dakota',
                    'TN' => 'Tennessee',
                    'TX' => 'Texas',
                    'UT' => 'Utah',
                    'VA' => 'Virginia',
                    'VT' => 'Vermont',
                    'WA' => 'Washington',
                    'WI' => 'Wisconsin',
                    'WV' => 'West Virginia',
                    'WY' => 'Wyoming' }
end
