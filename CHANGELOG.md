## ResStock v2.1.0 (pending)

Features
- Unit tests and performance improvements for integrity checks ([#228](https://github.com/NREL/OpenStudio-BuildStock/pull/228), [#237](https://github.com/NREL/OpenStudio-BuildStock/pull/237), [#239](https://github.com/NREL/OpenStudio-BuildStock/pull/239))
- Register climate zones (BA and IECC) based on the simulation EPW file ([#245](https://github.com/NREL/OpenStudio-BuildStock/pull/245))
- Split ResidentialLighting into separate ResidentialLightingInterior and ResidentialLightingOther (with optional exterior holiday lighting) measures ([#244](https://github.com/NREL/OpenStudio-BuildStock/pull/244), [#252](https://github.com/NREL/OpenStudio-BuildStock/pull/252))
- Additional example workflow osw files using TMY/ AMY2012/AMY2014 weather for use in regression testing ([#259](https://github.com/NREL/OpenStudio-BuildStock/pull/259), [#261](https://github.com/NREL/OpenStudio-BuildStock/pull/261))
- Update all projects with new heating/cooling setpoint, offset, and magnitude distributions ([#272](https://github.com/NREL/OpenStudio-BuildStock/pull/272))
- Add new ResidentialDemandResponse measure that allows for 8760 DR schedules to be applied to heating/cooling schedules ([#276](https://github.com/NREL/OpenStudio-BuildStock/pull/276))
- Additional options for HVAC, dehumidifier, clothes washer, misc loads, infiltration, etc. ([#264](https://github.com/NREL/OpenStudio-BuildStock/pull/264), [#278](https://github.com/NREL/OpenStudio-BuildStock/pull/278), [#292](https://github.com/NREL/OpenStudio-BuildStock/pull/292))
- Add EV options and update ResidentialMiscLargeUncommonLoads measure with new electric vehicle argument ([#282](https://github.com/NREL/OpenStudio-BuildStock/pull/282))
- Update ResidentialSimulation Controls measure to include a calendar year argument for controlling the simulation start day of week ([#287](https://github.com/NREL/OpenStudio-BuildStock/pull/287))
- Increase number of possible upgrade options from 10 to 25 ([#273](https://github.com/NREL/OpenStudio-BuildStock/pull/273), [#293](https://github.com/NREL/OpenStudio-BuildStock/pull/293))
- Additional "max-tech" options for slab, wall, refrigerator, dishwasher, clothes washer, and lighting ([#296](https://github.com/NREL/OpenStudio-BuildStock/pull/296))
- Add references to ResStock trademark in both the license and readme files ([#302](https://github.com/NREL/OpenStudio-BuildStock/pull/302))
- Report all cost multipliers in the SimulationOutputReport measure ([#304](https://github.com/NREL/OpenStudio-BuildStock/pull/304))
- Add options for low flow fixtures ([#305](https://github.com/NREL/OpenStudio-BuildStock/pull/305))
- Add argument to BuildExistingModel measure that allows the user to ignore measures ([#310](https://github.com/NREL/OpenStudio-BuildStock/pull/310))
- Create example project yaml files for use with buildstockbatch ([#291](https://github.com/NREL/OpenStudio-BuildStock/pull/291), [#314](https://github.com/NREL/OpenStudio-BuildStock/pull/314))
- Create a pull request template to facilitate development ([#317](https://github.com/NREL/OpenStudio-BuildStock/pull/317))
- Update documentation to clarify downselect logic parameters ([#321](https://github.com/NREL/OpenStudio-BuildStock/pull/321))
- Additional options for EnergyStar clothes washer, clothes dryer, dishwasher ([#329](https://github.com/NREL/OpenStudio-BuildStock/pull/329), [#333](https://github.com/NREL/OpenStudio-BuildStock/pull/333))
- Update to OpenStudio v2.9.0 ([#322](https://github.com/NREL/OpenStudio-BuildStock/pull/322))

Fixes
- Bugfix for assuming that all simulations are exactly 365 days ([#255](https://github.com/NREL/OpenStudio-BuildStock/pull/255))
- Bugfix for heating coil defrost strategy ([#258](https://github.com/NREL/OpenStudio-BuildStock/pull/258))
- Various HVAC-related fixes for buildings with central systems ([#263](https://github.com/NREL/OpenStudio-BuildStock/pull/263))
- Update testing project to sweep through more options ([#280](https://github.com/NREL/OpenStudio-BuildStock/pull/280))
- Updates, edits, and clarification to the documentation ([#270](https://github.com/NREL/OpenStudio-BuildStock/pull/270), [#274](https://github.com/NREL/OpenStudio-BuildStock/pull/274), [#285](https://github.com/NREL/OpenStudio-BuildStock/pull/285))
- Skip any reporting measure output requests for datapoints that have been registered as invalid ([#286](https://github.com/NREL/OpenStudio-BuildStock/pull/286))
- Bugfix for when bedrooms are specified for each unit but bathrooms are not ([#295](https://github.com/NREL/OpenStudio-BuildStock/pull/295))
- Ensure that autosizing does not draw the whole tank volume in one minute for solar hot water storage tank ([#307](https://github.com/NREL/OpenStudio-BuildStock/pull/307))
- Remove invalid characters from option names for consistency with buildstockbatch ([#308](https://github.com/NREL/OpenStudio-BuildStock/pull/308))
- Bugfix for ducts occasionally getting placed in the garage attic instead of only unfinished attic ([#309](https://github.com/NREL/OpenStudio-BuildStock/pull/309))
- Able to get past runner values of any type, and not just as string ([#312](https://github.com/NREL/OpenStudio-BuildStock/pull/312))
- Log the error message along with the backtrace when an applied measure fails ([#315](https://github.com/NREL/OpenStudio-BuildStock/pull/315))
- Add tests to ensure that the Run Measure argument is correctly defined in all Apply Upgrade measures for all projects ([#320](https://github.com/NREL/OpenStudio-BuildStock/pull/320))
- Bugfix when specifying numbers of bedrooms to building units ([#330](https://github.com/NREL/OpenStudio-BuildStock/pull/330))
- Enforce rubocop as CI test so code with offenses cannot be merged ([#331](https://github.com/NREL/OpenStudio-BuildStock/pull/331))
- Bugfix for some clothes washer, dishwasher options causing increased energy consumption ([#329](https://github.com/NREL/OpenStudio-BuildStock/pull/329), [#333](https://github.com/NREL/OpenStudio-BuildStock/pull/333))


## ResStock v2.0.0
###### April 17, 2019 - [Diff](https://github.com/NREL/OpenStudio-BuildStock/compare/v1.0.0...v2.0.0)

Features
- Update to OpenStudio v2.8.0

Fixes

## ResStock v1.0.0
###### April 17, 2019