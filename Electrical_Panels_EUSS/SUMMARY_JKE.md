# Summary: Using building envelope upgrades to avoid residential electrical panel upgrades
This file is meant as a summary of the work that Julia Ehlers did on panel capacity and envelope upgrades in collaboration with Willy Bernal Heredia, Omkar Ghatpande, Lixi Liu, and Yingli Lou. It briefly describes the background of the problem, methods used and explored, the details of the work and results, and areas for future work and improvement.

_Notes_: For simplicity's sake, all houses, residences, multifamily units, etc. will be called dwelling units in this summary.

## Background

### Abstract
Residential buildings account for 22% of final energy use and 17% of energy-related CO2 emissions globally according to the International Energy Agency. Complete residential electrification is necessary to decarbonize energy usage, meet sustainability goals and limit the impacts of climate change. New loads required by electrification trigger panel upgrades due to insufficient panel and service capacity or local codes on panel sizing. Panel upgrades slow electrification efforts as they are financially inaccessible to many, especially low-income communities impacted the most by climate change. Past research has examined energy savings and emission reductions created by building envelope upgrades. This study quantifies the impact of envelope upgrades on the required panel amperage and how this change offsets increases in amperage created by new loads.  

We implemented the National Electric Code Article 220 guidelines in a panel-sizing Python program. The program calculated panel amperage for each building before and after an envelope upgrade to simulate the US housing stock. Building data was previously generated for the National Renewable Energy Laboratory’s ResStock tool to simulate energy savings shapes and facilitate large scale electrification research. We analyzed the change in amperage in buildings with different heating and cooling equipment, climates, and building sizes. From this data, we determined which electrification upgrades will likely offset the decrease in amperage caused by an envelope upgrade. Further cost analysis will help find the most cost-effective envelope upgrades to reduce amperage and avoid panel upgrades. This information will also alleviate the financial burden of decarbonization and electrification for residents of all income backgrounds.


### Other Relevant Facts and Figures
The goal was to study a best case scenario of an envelope upgrade to see how much the demand on the panel can be reduced with it. By making heating and cooling in a residence more efficient with an envelope upgrade, the amount of electricity needed to produce the same amount of heating/cooling should decrease. With the decrease in electricity consumed comes a decrease in the maximum demand, and by extension, the necessary panel capacity. Once a baseline is established for the best case scenario, individual upgrades can be studied to determine which ones have the most impact on demand, and which are the most cost effective for that change.

### Research Question
How does an enhanced enclosure package affect demand on a panel when electrifying residential loads?


## Methods and Guidelines

### Panel Sizing
Currently, (as of July 2023) we've explored 5 different avenues for determining existing panel capacity for the US housing stock. Without a good baseline, it's difficult to determine if changes to the housing stock will help us avoid panel upgrades or not. The first 4 are based on the 2023 National Electric Code, and the last is a regression model created by Lawrence Berkley National Lab for the residential panel capacity problem as a whole.

#### NEC Article 220, Part III: The Standard Method
_Summary_: The Standard Method is used for sizing service connections and electrical panels of new residential construction. It combines three types of loads (general, special, and fixed), applies necessary demand factors, and determines the panel capacity necessary for a dwelling unit. General loads consider lighting, outlets, general kitchen and laundry circuits, and exhaust/ceiling fans, then applies a tiered demand factor. Special loads involve appliances like clothes dryers, ovens/ranges, space heating or cooling (whichever is larger), and any motor loads. Fixed loads include water heaters, dishwashers, and garbage disposals. These three loads are added to find the total power rating of the house, then can be divided by the maximum voltage supplied (usually 240V) to find the amperage of the panel. The smallest (while still supporting the calculated amperage) of a set of standard panel sizes is selected for the dwelling unit.  

_Advantages_:  
+ This is how new dwelling units are sized today, so it should be somewhat accurate, particularly for newer parts of the housing stock.
+ The set of steps makes it easy to see how much each appliance contributes to the total load for the panel.

_Disadvantages_:  
+ Since this method is geared towards new construction, it may not be the most accurate sizing method for older dwelling units.
  + Code has changed a lot over the last 100+ years as the technology has changed, and non-code compliant buildigns are often grandfathered in to a point.
  + 2023 code requires larger panel sizes than in the past by default, so upgrades may appear to be supported when in reality, the panel is actually too small for new loads.
  + The vintage (when the dwelling unit was built) does not take into account remodels or upgrades, so using past versions of the NEC is not necessarily the best option.
+ The datasets we're using to determine panel sizing don't have perfect nameplate ratings for appliances.
  + Usually nameplate ratings are used in the calculations to size appliances.
  + This information could be included later on as developments happen behind the scenes, but is not currently.
  + Currently, the lack of nameplate data makes sizing panels more difficult, especially when it comes to heating and cooling loads.
+ This method cannot be used to compare panel amperage before and after an envelope upgrade, since the python program that does the calculations doesn't consider how upgrades change the demands and loads. (The panel amperage would appear the same before and after the upgrade.)

#### NEC Article 220, Part IV: The Optional Method
_Summary_: The optional method is very similar to the standard method in the fact that it is used to size service connections and electrical panels in new construction. The calculations aren't significantly different, though the two handle loads differently and have different demand factors in some cases. The optional method requires a minimum panel capcity of 100A, and generally results in smaller panel sizing than the standard method does.

_Advantages_:  
+ Again, the optional method makes it easy to see what loads are the largest contributers to the service/panel capacity, and is a modern way new dwelling units are currently sized, so it seems to be a fairly accurate way to estimate capacity of dwelling units built recently.
+ Considering the optional method tends to size smaller panels, data on upgrades that can be supported by the current panel are more likely to be accurate. 

_Disadvantages_:  
+ Also because panel sizing using the optional method outputs smaller panels, data on upgrades that can't be supported without an upgrade are less likely to be accurate.
+ Again, using 2023 code requirements is probably not going to give the most accurate representation of panel capacity for older vintages.
+ The lack of nameplate ratings for each dwelling unit's appliances means we don't have the best data to use for sizing panels.
+ This method can't be used before and after an envelope upgrade, as it would give the same panel sizing and not take the upgrade into account appropriately.

#### NEC Section 220.83
_Summary_: used to determine if panel upgrade is needed when new load is added to existing building, uses similar data as parts III and IV, this method hasn't been explored as much as others in research so far

_Advantages_: works well to determine if panel upgrade is needed when doing electrification research, used by contractors and electricians in the real world currently

_Disadvantages_: not an effective method to find initial panel capacity (not what it's intended for)

#### NEC Section 220.87
_Summary_: Section 220.87 is intended to determine if a pre-existing dwelling unit has an adequately-sized panel to handle a new load. It does this by conducting a load study - homeowners can use peak demand data they already have from the last year for this purpose. Otherwise, contractors will often use an exception in the code to conduct a 30-day load study, and use information from that to determine if an upgrade is needed.

_Advantages_:
+ It serves as a realistic prediction in our simulations, as it's currently used frequently in the real world.
+ It's an extremely simple calculation that's easy to use.
+ Given the actual panel capacity for a dwelling unit, this method would be useful to determine how much slack exists in current panels based on the demand without any electrification or envelope upgrades.

_Disadvantages_:  
+ This method is not intended for initial panel sizing, it's only meant for changes to existing dwelling units like electrification.
+ It does not necessarily show what appliances are contributing to the maximum peak demand or to what extent.
  + This makes it difficult to account for loads where the new appliance is replacing an old, already-electric appliance.
  + For example, replacing an electric resistance heater with a heat pump. The demand data includes the electric resistance heater, and NEC 220.87 wants the demand data plus the new load. The heat pump will reduce the demand on the panel, but this isn't apparent when analyzing large datasets with NEC 220.87, so a work-around is needed.

#### LBNL Regression Model
_Summary_: LBNL's regression model uses field data to statistically determine the baseline panel capacity of an area. They collected data on existing dwelling units about their panel capacity, and other characteristics of the dwelling unit to find relationships between the characteristics and the capacity. With those relationships, we're able to input the characteristics, and the program will output the probability that the dwelling unit has a particular panel capacity.  

_Advantages_:  
+ It can be used deterministically (selecting the panel capacity with the highest likelihood of being accurate)
  + Deterministic: selects the panel capacity with the highest likelihood of being accurate, so the same dataset yields the same results every time
  + Stochastic: a more complex method that takes into account a certain amount of randomness, usually making the model more accurate and giving different results from the same dataset
+ It takes into account characteristics (particularly age) when determining panel capacity that other models miss.
+ The model is based on data collected in the field, so it provides a different sort of insight into baseline panel sizing than any of the NEC methods.  

_Disadvantages_:  
+ Currently, the LBNL model only works for dwelling units located in California, as data for statistical analysis has not been collected anywhere else.


### Envelope Upgrade Definition
Our best case scenario envelope upgrade is determined by the End-Use Savings Shapes Package 2 dataset. For Illinois (IECC Climate Zones 4A and 5A), it is defined as follows:

+ R-60 attic floor insulation
+ 30% reduction in air leakage
+ R-8 insulation and 10% leakage rates for ductwork
+ R-13 drill and fill wall insulation
+ R-10 foundation insulation or rim joist insulation
+ Seal vented crawlspaces
+ R-30 roof insulation

Other climates have slightly different specifications for the R-value of the insulation, so these upgrades may differ depending on where is analyzed.

### Data Used
We used End Use Savings Shapes data for Illinois from NREL's ResStock tool. This data uses information from the Residential Energy Consumption Survey (RECS), defined 10 upgrade packages, and then compared the baseline energy usage and carbon emissions to those after each upgrade package. Based on the specifications from each dataset, we can find an approximate panel size and start to do some analysis with different upgrade possibilities on a sample large enough to be representative of the US. Specific columns used for analysis can be found in the python scripts for NEC 220.87.  

We did analysis on one package of ten, and picked a single state to start out with for ease of analysis. Specifically, we analyzed Illinois for the extreme high and low temperatures it experiences at different times during the year to better evaluate heating and cooling loads. There's a lot more potential for geographic analysis and more exploration of other upgrade packages. The 'Future Work' section has more details and ideas concerning this.


## Envelope Upgrade Work

### Process and Results
To analyze the housing stock data we had from Illinois, we created a python program modeled off of NEC 220.87 to determine the demand on the panel (in amps) before and after the upgrade. We used a column from ResStock data that contained the peak demand (given in kilowatts, aka power) from a year's worth of simulation. In accordance with 220.87, we converted it to volt-amps (multiplied by 1000) and multiplied that demand number by 1.25, a demand factor implemented for safety so the panel (hopefully) never exceeds an acceptable capacity. This data and process was used to answer two questions: (1) How much slack does an envelope upgrade create in the demand on a panel? (2) What upgrades can be supported with this additional slack?

#### Slack Created with Envelope Upgrade
The 'electrical_panel_size_nec_220_87.py' file in this folder is intended to do a lot of the conversion from demand data into panel amperage using NEC 220.87. It also has some analysis built in. Several functions work to compare amperages in different ways, as detailed below:

+ **amp_dif_two_packages**: Uses the demand data and NEC 220.87 to find necessary amperages of any two packages, then takes the second package amperage and subtracts the first package amperage to find the difference.
+ **amp_dif_panel_size_and_amperage**: Uses the demand data and NEC 220.87 to size the panel for the first package, and finds the necessary amperage for the second package, then takes the second package amperage and subtracts the first package's panel size to find the amount of slack the second package creates plus the slack already existing in the panel.
+ **amp_percent_dif_two_packages**: Takes the result of 'amp_dif_two_packages' and divides by the amperage of the first package to normalize the result and find the percent change.
+ **amp_percent_dif_panel_size_and_amperage**: Takes the result of 'amp_dif_panel_size_and_amperage' and divides by the panel size found from the first package to normalize the result and find the percent change.

![Figure 1, uses 'amp_dif_two_packages' function for purple columns and 'amp_dif_panel_size_and_amperage' function for green columns.](<Figure 1.PNG>)
![Figure 2, uses 'amp_percent_dif_two_packages' function for purple columns and 'amp_percent_dif_panel_size_and_amperage' function for green columns.](<Figure 2.PNG>)

Figures 1 and 2 (above) use these four functions. Figure 1 has data analyzed with the 'amp_dif_two_packages' function for purple columns and 'amp_dif_panel_size_and_amperage' function for green columns. Figure 2 has data analyzed with the 'amp_percent_dif_two_packages' function for purple columns and 'amp_percent_dif_panel_size_and_amperage' function for green columns.

#### Upgrades Supported by Envelope Upgrade/Existing Slack


### Major Takeaways


### Assumptions
Slack in the panel:
- baseline panel sizing for slack created and upgrades supported is an estimate with lots of uncertainty due to disadvantages of current sizing methods
- assumes the demand data is exactly what's needed for the code - still a simulation, still processed to some extent, but seems to be a pretty good estimate

What upgrades are supported:
- again, existing panel capacity has a lot of uncertainty, but is a huge part of whether or not an upgrade can be supported

(Assumptions and slight tweaks that could be made to those assumptions)


## Future Work
(Areas to explore and ideas/suggestions for how to explore them, particularly how my code could facilitate that)

### Geographic Analysis
- analyze by state, by IECC climate zone, by Building America climate zone
- look into more specific upgrades for different regions - people behave differently in different places, so some parts of the building envelope upgrade might be pointless and others might be really effective... if we can determine the most effective ones, we can save money by avoiding the others
- essentially, are the upgrades that are universal across all areas? that only work in a couple places?

### Analysis of Dwelling Units with Different Characteristics
- does size of a building affect how effective a building envelope upgrade is?
- how does effectiveness vary with building age?
- what about intial fuel type/efficiency for different appliances?

### Cost Analysis
Some cost data with National Residential Efficiency Measures Database
Use this in combination with quantity of upgrade needed from ResStock needed to find upgrade cost
May need more information regionally - upgrades aren't going to cost the same in NE and CA
Find data to compare this cost with the cost of a panel upgrade in different regions

### Investigation of Other End Use Savings Shapes Upgrade Packages
Package 1 - lower scale envelope upgrade
Package 7/8 - low and high efficiency electrification packages
Package 9 - low efficiency envelope + high efficiency electrification
Package 10 - high efficiency envelope + electrification

### Other Areas for Exploration
comparison of current sizing methods
use an older version of the code and see how much of a difference in panel capacity between that version and the 2023 version?
test combinations of appliances to see if the upgrade can support multiple rather than just one