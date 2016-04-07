OpenStudio-ResStock
===================

OpenStudio-based Residential Building Stock Analysis

## Setup

TODO: Add information here on how to get setup.

## Running simulations

Currently simulations will only run on the nrel24b server as they make use of OS 2.0 capabilities only available there. Here's an example of running the national-scale simulations:

```bundle exec ruby cli.rb -t nrel24b -p projects/res_stock_national.xlsx -c```
