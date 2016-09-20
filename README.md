OpenStudio-ResStock
===================

ResStock, built on the OpenStudio platform, is a project geared at modeling the residential building stock for, e.g., National or Pacific Northwest analysis. As part of this project:
* Multiple data sources for building characteristics (e.g., [EIA RECS](http://www.eia.gov/consumption/residential/), [RBSA](http://neea.org/resource-center/regional-data-resources/residential-building-stock-assessment), [NAHB](http://www.homeinnovation.com/trends_and_reports/data/new_construction), [ACS](https://www.census.gov/programs-surveys/acs/)) have been combined into conditional probability distributions for [National](https://github.com/NREL/OpenStudio-ResStock/tree/master/resources/inputs/national) and [Pacific Northwest](https://github.com/NREL/OpenStudio-ResStock/tree/master/resources/inputs/pnw) analyses for, e.g., location, vintage, equipment types and efficiency levels, envelope insulation levels, etc.
* A sampling technique is used to generate thousands (up to hundreds of thousands) of OpenStudio models via OpenStudio measures.
* OpenStudio models are run through the [EnergyPlus simulation engine](http://energyplus.net) via [Amazon cloud computing](https://aws.amazon.com) or other resources.
* FUTURE: Upgrades can applied to user-specified subsets of the housing stock (e.g., add insulation to only those homes with empty cavity walls or install ductless heat pumps only to those homes with electric baseboard heating) based on OpenStudio measures.
* FUTURE: A number of tabular reports and other output visualizations (e.g., geographic maps, heat maps) can be obtained.

This project is a <b>work-in-progress</b>. The models are not fully completed nor tested. 

## Setup

TODO: Add information here on how to get setup.

## Running simulations

Simply execute:

* National analysis: `bundle exec ruby cli.rb -p projects/resstock_national.xlsx -t aws -c`
* Pacific Northwest analysis: `bundle exec ruby cli.rb -p projects/resstock_pnw.xlsx -t aws -c`

The commands above will use Amazon cloud computing and download the results in a CSV file. See `bundle exec ruby cli.rb -h` for other uses.

The spreadsheets for [National](https://github.com/NREL/OpenStudio-ResStock/blob/master/projects/resstock_national.xlsx) or [Pacific Northwest](https://github.com/NREL/OpenStudio-ResStock/blob/master/projects/resstock_pnw.xlsx) analyses define the upgrade measures and/or packages to be applied.

## Results

Raw results are available in a CSV file after running the simulations. For each Building ID, one or more rows of data are available that define the existing building as well as any upgrade scenarios. Each row, representing an EnergyPlus simulation, includes housing characteristics as well as simulation results (end use outputs, HVAC capacities, hours loads not met, etc.).

There are [sample results](https://github.com/NREL/OpenStudio-ResStock/blob/master/analysis_results/) provided in the repository.
