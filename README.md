OpenStudio-ResStock
===================

ResStock, built on the OpenStudio platform, is a project geared at modeling the residential building stock for the U.S. or other regions. As part of this project:
* Multiple data sources for building characteristics (e.g., [EIA RECS](http://www.eia.gov/consumption/residential/), [RBSA](http://neea.org/resource-center/regional-data-resources/residential-building-stock-assessment), [NAHB](www.homeinnovation.com/trends_and_reports/data/new_construction), [ACS](https://www.census.gov/programs-surveys/acs/)) have been combined into [conditional probability distributions](https://github.com/NREL/OpenStudio-ResStock/tree/master/measures/CallMetaMeasure/resources/inputs/national) for, e.g., location, vintage, equipment types and efficiency levels, evelope insulation levels, etc.
* A sampling technique is used to generate thousands (up to hundreds of thousands) of representative building models.
* FUTURE: Retrofit measures can applied to user-specified subsets of the housing stock (e.g., add insulation to only those homes with empty cavity walls or install ductless heat pumps only to those homes with electric baseboard heating).
* FUTURE: A number of tabular reports and other output visualizations (e.g., geographic maps, heat maps) can be obtained.

This project is a <b>work-in-progress</b>. The models are not fully completed nor tested. 

Note: OpenStudio models are built-up through calls to [residential OpenStudio measures](https://github.com/NREL/OpenStudio-Beopt). As part of the workflow, a meta-measure (an OpenStudio measure that calls another measure) facilitates passing [appropriate arguments](https://github.com/NREL/OpenStudio-ResStock/blob/master/measures/CallMetaMeasure/resources/options_lookup.txt) (e.g., wall R-value or air conditioner SEER) to the residential measure based on the sampling value and the probability distributions.

## Setup

TODO: Add information here on how to get setup.

## Running simulations

There is a run.rb script that wraps around OpenStudio's cli.rb and simplifies the process for us. It also performs a number of integrity checks to reduce the possibility of submitting jobs only to find out something went wrong. To use the script, simply execute:

```ruby run.rb```

By default, the script will 1) check for errors, 2) specify U.S. national-scale analysis, 3) use the 'nrel24a' server, and 4) download the resulting CSV files. See `ruby run.rb -h` for other uses.
