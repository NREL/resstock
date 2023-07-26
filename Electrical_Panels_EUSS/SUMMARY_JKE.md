# Summary: Using building envelope upgrades to avoid residential electrical panel upgrades
This file is meant as a summary of the work that Julia Ehlers did on panel capacity and envelope upgrades. It briefly describes the background of the problem, methods used and explored, the details of the work and results, and areas for future work and improvement.

## Background

### Abstract
Residential buildings account for 22% of final energy use and 17% of energy-related CO2 emissions globally according to the International Energy Agency. Complete residential electrification is necessary to decarbonize energy usage, meet sustainability goals and limit the impacts of climate change. New loads required by electrification trigger panel upgrades due to insufficient panel and service capacity or local codes on panel sizing. Panel upgrades slow electrification efforts as they are financially inaccessible to many, especially low-income communities impacted the most by climate change. Past research has examined energy savings and emission reductions created by building envelope upgrades. This study quantifies the impact of envelope upgrades on the required panel amperage and how this change offsets increases in amperage created by new loads.  

We implemented the National Electric Code Article 220 guidelines in a panel-sizing Python program. The program calculated panel amperage for each building before and after an envelope upgrade to simulate the US housing stock. Building data was previously generated for the National Renewable Energy Laboratory’s ResStock tool to simulate energy savings shapes and facilitate large scale electrification research. We analyzed the change in amperage in buildings with different heating and cooling equipment, climates, and building sizes. From this data, we determined which electrification upgrades will likely offset the decrease in amperage caused by an envelope upgrade. Further cost analysis will help find the most cost-effective envelope upgrades to reduce amperage and avoid panel upgrades. This information will also alleviate the financial burden of decarbonization and electrification for residents of all income backgrounds.


### Other Relevant Facts and Figures
The goal was to study a best case scenario of an envelope upgrade to see how much we can 

### Research Question
How does an enhanced enclosure package affect demand on a panel when electrifying residential loads?


## Methods and Guidelines

### Panel Sizing
(Brief synopsis, pros, cons, etc. for each one)

#### NEC Article 220, Part III: The Standard Method
_Summary_: The Standard Method is used for sizing service connections and electrical panels of new residential construction.  

_Advantages_: takes into account all loads  

_Disadvantages_: since we're using 2023 version, makes finding the baseline difficult since most houses did not use that code when they were made.  

#### NEC Article 220, Part IV: The Optional Method
for sizing service connections and electrcial panels.

#### NEC Section 220.83

#### NEC Section 220.87

#### LBNL Regression Model


### Envelope Upgrade Definition

### Data Used
(What set of data, what specific columns, and reasoning behind it all)


## Envelope Upgrade Work

### Specific Process

### Results

### Assumptions
(Assumptions and slight tweaks that could be made to those assumptions)

### Major Takeaways


## Future Work
(Areas to explore and ideas/suggestions for how to explore them, particularly how my code could facilitate that)