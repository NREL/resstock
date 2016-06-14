OpenStudio-ResStock
===================

ResStock, built on the OpenStudio platform, is a project geared at modeling the residential building stock for, e.g., the entire U.S. Nation or the Pacific Northwest region. As part of this project:
* Multiple data sources for building characteristics (e.g., [EIA RECS](http://www.eia.gov/consumption/residential/), [RBSA](http://neea.org/resource-center/regional-data-resources/residential-building-stock-assessment), [NAHB](http://www.homeinnovation.com/trends_and_reports/data/new_construction), [ACS](https://www.census.gov/programs-surveys/acs/)) have been combined into [conditional probability distributions](https://github.com/NREL/OpenStudio-ResStock/tree/master/resources/inputs/national) for, e.g., location, vintage, equipment types and efficiency levels, envelope insulation levels, etc.
* A sampling technique is used to generate thousands (up to hundreds of thousands) of OpenStudio models via OpenStudio measures.
* OpenStudio models are run through the [EnergyPlus simulation engine](http://energyplus.net) via Amazon cloud computing or other resources.
* FUTURE: Upgrades can applied to user-specified subsets of the housing stock (e.g., add insulation to only those homes with empty cavity walls or install ductless heat pumps only to those homes with electric baseboard heating) based on OpenStudio measures.
* FUTURE: A number of tabular reports and other output visualizations (e.g., geographic maps, heat maps) can be obtained.

This project is a <b>work-in-progress</b>. The models are not fully completed nor tested. 

## Setup

TODO: Add information here on how to get setup.

## Running simulations for existing housing stock

Simply execute:

```bundle exec ruby run_existing.rb```

By default, the script will 1) check for errors, 2) specify U.S. national-scale analysis, 3) use Amazon cloud computing, and 4) download the resulting CSV files. See `bundle exec ruby run_existing.rb -h` for other uses.

OpenStudio building models are built-up through a series of OpenStudio measures defined in an analysis spreadsheet (e.g., [U.S. Nation](https://github.com/NREL/OpenStudio-ResStock/blob/master/projects/res_stock_national_existing.xlsx) or [Pacific Northwest](https://github.com/NREL/OpenStudio-ResStock/blob/master/projects/res_stock_pnw_existing.xlsx)).

## Running simulations for upgrade scenarios

Simply execute:

```bundle exec ruby run_upgrades.rb```

By default, the script will 1) check for errors, 2) specify U.S. national-scale analysis, 3) use Amazon cloud computing, and 4) download the resulting CSV files. See `bundle exec ruby run_upgrades.rb -h` for other uses.

Upgrades to be applied are OpenStudio measures defined in an analysis spreadsheet (e.g., [U.S. Nation](https://github.com/NREL/OpenStudio-ResStock/blob/master/projects/res_stock_national_upgrades.xlsx) or [Pacific Northwest](https://github.com/NREL/OpenStudio-ResStock/blob/master/projects/res_stock_pnw_upgrades.xlsx)).