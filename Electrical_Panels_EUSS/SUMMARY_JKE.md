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
_Summary_: Section 220.83 is used to determine if a panel upgrade is needed when a new load is added to existing building. It uses similar information about the building as the Standard Method and the Optional Method (Article 220 Parts III and IV respectively). This method hasn't been explored as much as others for panel capacity research purposes.

_Advantages_:  
+ It is fully intended to determine if a panel upgrade is needed when doing electrification research, which is highly applicable right now and for this project.
+ It is used by contractors and electricians when implementing panel upgrades currently, so it's very realistic all things considered.

_Disadvantages_:
+ It is not necessarily an effective method to find existing panel capacity, as that is not what it's intended for.

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

The input file for these calculations was created using the 'combine_raw_files_for_nec_220_87' file in this folder. It takes data from the EUSS parquet files for each package, sorts out the relevant columns, and renames them so they can be combined into a single file that has all the information needed for the 'electrical_panel_size_nec_220_87.py' program. As changes are made to one, they should probably also be made to the other, but that depends on how the user wants to go forward with their own process.

#### Slack Created with Envelope Upgrade
The 'electrical_panel_size_nec_220_87.py' file in this folder is intended to do a lot of the conversion from demand data into panel amperage using NEC 220.87. It also has some analysis built in. Several functions work to compare amperages in different ways, as detailed below:

+ **amp_dif_two_packages**: Uses the demand data and NEC 220.87 to find necessary amperages of any two packages, then takes the second package amperage and subtracts the first package amperage to find the difference.
+ **amp_dif_panel_size_and_amperage**: Uses the demand data and NEC 220.87 to size the panel for the first package, and finds the necessary amperage for the second package, then takes the second package amperage and subtracts the first package's panel size to find the amount of slack the second package creates plus the slack already existing in the panel.
+ **amp_percent_dif_two_packages**: Takes the result of 'amp_dif_two_packages' and divides by the amperage of the first package to normalize the result and find the percent change.
+ **amp_percent_dif_panel_size_and_amperage**: Takes the result of 'amp_dif_panel_size_and_amperage' and divides by the panel size found from the first package to normalize the result and find the percent change.

![Figure 1, uses 'amp_dif_two_packages' function for purple columns and 'amp_dif_panel_size_and_amperage' function for green columns.](<envelope_graphs/Figure 1.PNG>)
![Figure 2, uses 'amp_percent_dif_two_packages' function for purple columns and 'amp_percent_dif_panel_size_and_amperage' function for green columns.](<envelope_graphs/Figure 2.PNG>)

Figures 1 and 2 (above) use these four functions. Figure 1 has data analyzed with the 'amp_dif_two_packages' function for purple columns and 'amp_dif_panel_size_and_amperage' function for green columns. Figure 2 has data analyzed with the 'amp_percent_dif_two_packages' function for purple columns and 'amp_percent_dif_panel_size_and_amperage' function for green columns.

#### Upgrades Supported by Envelope Upgrade/Existing Slack
There's also a variety of functions in 'electrical_panel_size_nec_220_87.py' that have to do with determining if a specific upgrade can be supported or not. Some common electrification upgrades were determined based on End Use Savings Shapes Packages 7 and 8. The following are the specific upgrades that were investigated:

+ **Low Efficiency Heating**: SEER 15, 9 HSPF heat pump with electric resistance backup heating (specific system depends on whether HVAC system is ducted)
+ **High Efficiency Heating**: SEER 24, 13 HSPF variable speed mini split heat pump or SEER 29.3, 14 HSPF variable speed mini split heat pump (depending on ductwork) with electric resistance backup heating
+ **Electric Water Heater**: 50 gallon 3.45 UEF (1-3 bedrooms), 66 gallon 3.35 UEF (4 bedrooms), or 80 gallon 3.45 UEF (5+ bedrooms) heat pump water heater
+ **Low Efficiency Range**: Electric cooking range (no detailed specifications right now)
+ **High Efficiency Range**: Electric induction cooking range
+ **Low Efficiency Dryer**: Electric clothes dryer (no detailed specifications right now)
+ **High Efficiency Dryer**: Premium Electric Ventless Heat Pump Clothes Dryer

These upgrades correspond to each of the graphs below.  

![Figures 3-9, Percentage of dwelling units where a new electrification appliance is supported without needed a panel upgrade for each county in Illinois](<envelope_graphs/Figures 3-9.PNG>)

In order to create these graphs, a series of functions ('appliance load functions' in 'electrical_panel_size_nec_220_87.py') was used. For each upgrade, a function determines the additional nameplate rating (in volt-amps) for the appliance. Some, like the dryers and cooking ranges, just have a single value that is added on regardless of the dwelling unit's characteristics. Others, particularly heating, require some information about the dwelling unit to determine the power needed for the additional appliance. These nameplate values are added to the dwelling unit's maximum demand according to NEC 220.87, and the new amperage necessary for the appliances is found.  

From there, a second set of functions under the 'appliance analysis functions' section compare the panel capacity (sized with NEC 220.87) to the new amperage with the electrified appliance. Each upgrade is assigned one of four values when it's applied to a dwelling unit: true, false, none, or error. The function starts by determining if the upgrade is applicable - does the dwelling unit already have an electric version of the appliance? Does it have any version of the appliance? Depending on the answers to these questions, the function determines if the upgrade is applicable or not, and returns 'none' if it's not applicable. For example, if the dwelling unit is a multifamily housing type, the dryers may be in a communal area rather than contributing to the panel sizing for the individual unit, so it doesn't make sense to add an electrified load, and the function would return 'none.'  

If the load is applicable, the dwelling unit continues to the next part of the function. It compares the panel capacity of the existing dwelling unit, before any upgrades are applied, to the amperage after the envelope upgrade and with the new load added to it. If the new amperage is less than the baseline panel capacity, the function returns 'true:' the appliance is supported without an upgrade. If the opposite is true, the function returns 'false' and the appliance is not supported by the slack in the panel. Anything that doesn't have numbers or satisfy any of these conditions for whatever reasons returns an error.  

Figures 3-9 (above) calculate the number of dwelling units in each county where the functions above return the 'true' value, divided by the total number of dwelling units in each county. This is another area where performing other sorts of analysis might be beneficial. See Assumptions for more information.

**EXPLAIN ASSUMPTIONS AND UNCERTAINTY OF PROCESS AND RESULTS SECTION
**ADD DETAILS TO FUTURE WORK

### Major Takeaways
Building envelope upgrades can decrease demand on electrical panels enough to support electrification upgrades, depending on what appliances are currently installed in a dwelling unit. Some of the amperages showed insignificant, or even non-existant changes in demand after the envelope upgrade. This is likely because the heating loads impacted by the envelope upgrade were not powered by electricity to begin with, and therefore don't have an impact on the amperage.  

When slack from the envelope upgrade is combined with existing slack in panels from the difference between panel sizing and peak demand, there's a significant amount of 'wiggle room' to add in new appliances and electrify. This is an area that definitely needs more exploration - the better we can characterize existing panel capacity, the better we can understand how much slack we actually have to work with. Understanding how much slack is pre-existing and how much is from the envelope upgrade will also be useful information to have for this.  

Water heating is the most likely to be supported without a panel upgrade, while low efficiency heating is the least likely. This latter part makes sense, as heating usually consumes the most energy in a dwelling unit. This does not take into account any interactions between the envelope and the equipment. Envelope upgrades tend to allow smaller equipment to serve the same space, so it's possible that interaction might lead to more favorable results.  

For the majority of Figures 3-9, Chicago (the northeast counties) appears to be the most likely area to support electrification upgrades in the state of Illinois. This is reassuring in some aspects, and discouraging in others. Chicago has a high population, and a lot of buildings, so being able to electrify a large portion of those buildings without panel upgrades could make a huge impact. On the other hand, the fact that these rates are not as high in rural areas where electrification initiatives already face problems poses more questions about equity and outreach. More investigation into why the rates we currently have are so much lower in some areas might help shed more light. If the rate is low because upgrades are not applicable in those areas, that paints a very different story than if the rate is low because there's not enough slack in electrical panels.

### Assumptions
Assumptions about slack in the panel:
+ The estimates we have for the slack created from package two (and pre-existing slack) are heavily dependent on our panel sizing methods.
  + More comparison needs to be done to further pinpoint areas of uncertainty, and find ways to eliminate them.
  + More exploration of these results on smaller scales can also help clarify why the uncertainty might exist in the first place when it comes to panel sizing (and any other areas).
+ The results are also highly dependent on the demand numbers we have from the EUSS dataset for each dwelling unit.
  + Current results seem to be very realistic from the demand data, most uncertainty likely coming from the way we process it.
  + While the demand data is highly useful for our purposes, it is still a simulation and it is still processed to some extent, possibly in different ways than NEC 220.87 needs.
  + Doing (or finding) a case study that looks into existing panel capacity, load studies, and various electrification/envelope upgrades might also be a way to check how realistic our results are.

Assumptions about what upgrades are supported:
+ Again, it's hard to check if an appliance can be added without a panel upgrade when the initial panel size is approximated instead of known.
+ A second set of numbers that compares the number of appliance additions that returned 'true' to those that returned 'false' might give us a better idea of the upgrades that are actually supported.
  + Including the dwelling units in each county that returned 'none' or 'error' skews the data towards false.
  + This could be solved by finding a percentage that the number of 'true' responses, divided by the number of combined 'true' and 'false' responses.
  + It might also be interesting to have a set of percentages for how many returned 'false' divided by the total, and the same for 'none' and possibly 'error' as well.
+ Nameplate ratings of appliances are assumed from 'postprocess_electrical_panel_size_nec.py' for the appliance additions, and for any initial panel sizing using the standard and optional methods.
  + This gives us a good estimate for our values, but could be more accurate.
  + If we have the data for nameplate ratings of appliances in the Energy Plus models of the ResStock dwelling units, including it in the dataset output by ResStock would increase the accuracy of our calculations.
+ We haven't investigated how much an upgrade to an existing electric appliance impacts panel capacity.
  + NEC 220.87 includes all of the loads with no real separation in the maximum demand. If an existing load is already electric and is replaced with a more efficient version, it doesn't make sense to add on an entirely new load.
  + Usually, the more efficient the appliance, the more the demand tends to decrease. So replacing existing electric appliances doesn't appear to pose much of a problem in regards to panel capacity, but it could provide more slack for other non-electric appliances to be electrified.
  + This new slack from adding more efficient appliances in combination with the existing panel slack and the slack from an envelope upgrade might significantly increase what sorts of appliances can be added without an upgrade.


## Future Work
Some of these areas have been mentioned for future work, but below are more in-depth explanations of things that could be explored later on, or were not examined in detail in this round of analysis.

### Geographic Analysis
This study only analyzed Illinois data, as Illinois experiences both extreme hot and cold temperatures and would let us explore changes in cooling and heating. However, doing a larger scale analysis of the United States would provide even more insight, especially considering the majority of the country will need to be electrified sooner rather than later to meet our climate and emissions goals.  

While we analyzed Illinois by county, there are other geographical chunks we could examine for the entire country. Looking into the county or state level is always an option, depending on the resolution we're looking for in our results. Examining results in terms of the IECC Climate Zone or the Building America climate zone could provide a lot of information about how building envelope upgrades (and panel capacity) interacts with different ranges of weather.  

It might also be interesting to look into more specific upgrades - focus on the changes that only sealing and insulating the ducts creates, or reducing the ACH50 values for a dwelling unit - for different areas. For example, if you live in a warmer climate, like southern California, it doesn't make sense to make your dwelling unit more airtight if you leave your windows open all the time. By analyzing on a smaller scale, we can better determine the impact that individual upgrades make, whether or not it's worth the money to upgrade in a location, and save owners money by avoiding unnecessary upgrades. This has been done to a smaller extent (in terms of cost analysis) on the state fact sheets found on ResStocks online data viewer. A team determined which upgrades (electrification and envelope) would be most effective in each state, and determined how much it would cost, how much money it would save, and if it would provide a certain return on investment. This might be an opportunity for collaboration to do something similar more specific to panel capacity.

### Cost Analysis
One area we did not dive into at all was a cost analysis. The whole purpose of building envelope upgrades is to make electrification more accessible to all, and if it's not affordable, that defeats the purpose. There is some relevant cost data in the National Residential Efficiency Measures Database that could be used (and is already used?) to determine the cost of the upgrade for every dwelling unit. However, costs vary across the US and determining a low end and a high end cost, or even diving further into different regions might be useful. Investigating the actual cost of a panel upgrade in comparison to the price of the envelope upgrade, or other solutions to the panel capacity problem might help bring the market in tune with the best ways to electrify our housing stock.

### Analysis of Dwelling Units with Different Characteristics
Doing more analysis of a geographic area is one approach, but there are other characteristics of dwelling units that play into the effectiveness of different upgrades. For example, how does the size of a dwelling unit affect the (cost) effectiveness of a building envelope upgrade? What about the building's age or the last time it was remodeled? How does the initial fuel type or efficiency of different appliances play into the amount of slack we have to work with? We don't necessarily have all of the data right now to investigate some of these characteristics or others not listed here, but understanding what other features can impact the effectiveness, especially with regard to the money spent on upgrades, might help us refine our research and make it even more applicable.

### Investigation of Other End Use Savings Shapes Upgrade Packages
In this study, we investigated one package from the End Use Savings Shapes dataset, but there are 9 other upgrade packages that can be investigated. In terms of the panel capacity problem (and to further investigate some of the details listed above), I'd recommend starting with the following packages:

+ **Package 1**: This is a less intensive version of the envelope upgrade in Package 2. It would be interesting to compare costs and the impact both packages make on peak demand. This would be a great place to start looking into smaller scale envelope upgrades and their effectiveness in different regions of the country.
+ **Package 7 and Package 8**: Both packages focus on electrification upgrades. Package 7 does the bare minimum to make sure everything is electric but doesn't increase the efficiency, whereas Package 8 does its best to make sure all appliances are electric and as efficient as possible. These are the packages that we used as a framework for electrfication appliances in Figures 3-9. This would probably be a good place to start investigating how much slack going from low to high efficiency appliances creates.
+ **Package 9 and Package 10**: Package 9 is the combination of Packages 1 and 8 (low intensity envelope upgrade and high efficiency electrification). Package 10 is the combination of Packages 2 and 8 (enhanced envelope upgrade and high efficiency electrification). These packages are intended to investigate how envelopes and electrification play off of each other to reduce the energy and emissions further than either upgrade on its own. Looking into the combination of the two has a lot of potential in terms of panel slack and capacity.

### Other Areas for Exploration
Finally, there are a couple other areas where investigation could be beneficial:
+ Comparison of current panel sizing methods
+ Investigate the difference in panel capacity between NEC 2023 and an older version (to determine how accurate NEC 2023 is for older dwelling units)
+ Test combinations of appliances (and expand the list of appliances tested to include things like EV chargers) to see if different upgrades can support multiple new loads instead of just one