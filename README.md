OpenStudio-ResStock
===================

OpenStudio-based Residential Building Stock Analysis

## Setup

TODO: Add information here on how to get setup.

## Running simulations

There is a run.rb script that wraps around OpenStudio's cli.rb and simplifies the process for us. It also performs a number of integrity checks to reduce the possibility of submitting jobs only to find out something went wrong. To use the script, simply execute:

```ruby run.rb```

By default, the script will 1) check for errors, 2) select our national-scale analysis (not, e.g., PNW analysis), 3) use the 'nrel24b' server, and 4) download the resulting CSV files. See `ruby run.rb -h` for other uses.
