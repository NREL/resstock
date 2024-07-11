# frozen_string_literal: true

# TODO
module Constants
  # Numbers --------------------

  # TODO
  #
  # @return [Double] the assumed inside temperature (F)
  def self.AssumedInsideTemp
    return 73.5
  end

  # TODO
  #
  # @return [Double] gravity (ft/s2)
  def self.g
    return 32.174
  end

  # TODO
  #
  # @return [Double] a small constant number
  def self.small
    return 1e-9
  end

  # TODO
  #
  # @param year [Integer] the calendar year
  # @return [TODO] TODO
  def self.NumDaysInMonths(year)
    num_days_in_months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    num_days_in_months[1] += 1 if Date.leap?(year)
    return num_days_in_months
  end

  # TODO
  #
  # @param year [Integer] the calendar year
  # @return [Integer] number of days in the calendar year
  def self.NumDaysInYear(year)
    num_days_in_months = NumDaysInMonths(year)
    num_days_in_year = num_days_in_months.sum
    return num_days_in_year
  end

  # TODO
  #
  # @param year [Integer] the calendar year
  # @return [Integer] number of hours in the calendar year
  def self.NumHoursInYear(year)
    num_days_in_year = NumDaysInYear(year)
    num_hours_in_year = num_days_in_year * 24
    return num_hours_in_year
  end

  # Strings --------------------

  # TODO
  #
  # @return [TODO] TODO
  def self.AirFilm
    return 'AirFilm'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.AutomaticallyAdded
    return 'AutomaticallyAdded'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ERIVersions
    return ['2014', '2014A', '2014AE', '2014AEG', '2019', '2019A',
            '2019AB', '2019ABC', '2019ABCD', '2022', '2022C']
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.FacadeFront
    return 'front'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.FacadeBack
    return 'back'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.FacadeLeft
    return 'left'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.FacadeRight
    return 'right'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.FluidWater
    return 'water'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.FluidPropyleneGlycol
    return 'propylene-glycol'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.FluidEthyleneGlycol
    return 'ethylene-glycol'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.IECCZones
    return ['1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C',
            '4A', '4B', '4C', '5A', '5B', '5C', '6A', '6B', '6C', '7', '8']
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameAirSourceHeatPump
    return 'air source heat pump'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameBatteryLossesAdjustment
    return 'battery losses adjustment'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameBoiler
    return 'boiler'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameCeilingFan
    return 'ceiling fan'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameCentralAirConditioner
    return 'central ac'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameCentralAirConditionerAndFurnace
    return 'central ac and furnace'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameClothesWasher
    return 'clothes washer'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameClothesDryer
    return 'clothes dryer'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameComponentLoadsProgram
    return 'component loads program'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameCookingRange
    return 'cooking range'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameDehumidifier
    return 'dehumidifier'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameDishwasher
    return 'dishwasher'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameDistributionWaste
    return 'dhw distribution waste'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameDuctLoad
    return 'duct load'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameElectricBaseboard
    return 'electric baseboard'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameEvaporativeCooler
    return 'evap cooler'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameFanPumpDisaggregateCool
    return 'disaggregate clg'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameFanPumpDisaggregatePrimaryHeat
    return 'disaggregate htg primary'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameFanPumpDisaggregateBackupHeat
    return 'disaggregate htg backup'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameFixtures
    return 'dhw fixtures'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameFreezer
    return 'freezer'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameFurnace
    return 'furnace'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameGeneralWaterUse
    return 'general water use'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameGeneralWaterUseLatent
    return 'general water use latent'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameGeneralWaterUseSensible
    return 'general water use sensible'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameGroundSourceHeatPump
    return 'ground source heat pump'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameGSHPSharedPump
    return 'gshp shared loop pump'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameHotWaterRecircPump
    return 'dhw recirc pump'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameHVACAvailabilitySensor
    return 'hvac availability sensor'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameIdealAirSystem
    return 'ideal air system'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameInfiltration
    return 'infil'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameLightingExterior
    return 'exterior lighting'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameLightingExteriorHoliday
    return 'exterior holiday lighting'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameLightingGarage
    return 'garage lighting'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameLightingInterior
    return 'interior lighting'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMechanicalVentilation
    return 'mech vent'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMechanicalVentilationPrecooling
    return 'mech vent precooling'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMechanicalVentilationPreheating
    return 'mech vent preheating'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMechanicalVentilationHouseFan
    return 'mech vent house fan'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMechanicalVentilationHouseFanCFIS
    return 'mech vent house fan cfis'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMechanicalVentilationHouseFanCFISSupplFan
    return 'mech vent house fan cfis suppl'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMechanicalVentilationBathFan
    return 'mech vent bath fan'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMechanicalVentilationRangeFan
    return 'mech vent range fan'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiniSplitAirConditioner
    return 'mini split air conditioner'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiniSplitHeatPump
    return 'mini split heat pump'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNamePTHP
    return 'packaged terminal heat pump'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameRoomHP
    return 'room ac with reverse cycle'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNamePTAC
    return 'packaged terminal air conditioner'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameBackupSuppHeat
    return 'back up supp heat'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscGrill
    return 'misc grill'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscLighting
    return 'misc lighting'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscFireplace
    return 'misc fireplace'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscPoolHeater
    return 'misc pool heater'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscPoolPump
    return 'misc pool pump'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscPermanentSpaHeater
    return 'misc permanent spa heater'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscPermanentSpaPump
    return 'misc permanent spa pump'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscPlugLoads
    return 'misc plug loads'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscTelevision
    return 'misc tv'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscElectricVehicleCharging
    return 'misc electric vehicle charging'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameMiscWellPump
    return 'misc well pump'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameNaturalVentilation
    return 'natural vent'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameNeighbors
    return 'neighbors'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameOccupants
    return 'occupants'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameRefrigerator
    return 'fridge'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameRoomAirConditioner
    return 'room ac'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameSolarHotWater
    return 'solar hot water'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameTotalLoadsProgram
    return 'total loads program'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameUnitHeater
    return 'unit heater'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameUnmetHoursProgram
    return 'unmet hours program'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameWaterHeater
    return 'water heater'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameWaterHeaterSetpoint
    return 'water heater setpoint'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameWaterHeaterAdjustment
    return 'water heater energy adjustment'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameWaterLoopHeatPump
    return 'water loop heat pump'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ObjectNameWholeHouseFan
    return 'whole house fan'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ScheduleTypeLimitsFraction
    return 'Fractional'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ScheduleTypeLimitsOnOff
    return 'OnOff'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.ScheduleTypeLimitsTemperature
    return 'Temperature'
  end

  # TODO
  #
  # @return [TODO] TODO
  def self.StateCodesMap
    return { 'AK' => 'Alaska',
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
end
