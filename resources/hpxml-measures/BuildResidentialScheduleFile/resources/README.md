Stochastic Occupancy Modeling introduces major changes to most occupant-related schedules.
Occupant activities are now generated on-the-fly and saved to CSV files used by `OpenStudio` Schedule:File objects.
Schedules are generated using time-inhomogenous Markov chains derived from American Time Use Survey data, supplemented with sampling duration and power level from NEEA RBSA data, as well as DHW draw duration and flow rate data from Aquacraft/AWWA data.

The `BuildResidentialScheduleFile` measure outputs a schedule CSV file (available inside the `run` folder of each building simulation output).
The schedule CSV file contains the following columns:
* `occupants`
* `lighting_interior`
* `lighting_garage`
* `cooking_range`
* `dishwasher`
* `clothes_washer`
* `clothes_dryer`
* `ceiling_fan`
* `plug_loads_other`
* `plug_loads_tv`
* `hot_water_dishwasher`
* `hot_water_clothes_washer`
* `hot_water_fixtures`
* `sleep`*

*Column `sleep` is optionally exported only when "debug" mode is enabled.

Each of the columns, except `occupants`, represent schedule values (kW for power schedules, and gallons per minute for water schedules) normalized using universal maximum values found in `constants.rb`.

The `occupants` column represents the fractional percent of occupants present out of the total number of occupants assigned to the unit.
The `sleep` column represents the fractional percent of the total number of occupants who are sleeping.

There are the same number of rows as the total simulation time-step (e.g., 35040 if 15-min, 8760 if hourly [8784, if leap year]).

The `ScheduleGenerator` class uses Markov chain based simulation to generate the schedule.csv.
To support that, several pre-generated set of files are used, contained in the following folders:
* `weekday`
* `weekend`

These two folders contain the Markov chain initial probability, Markov chain transition and also appliance duration probabilities csv files.
The appliance duration probabilities here are used during the Markov chain simulation to determine duration of various appliances.
The files are divided into four clusters (cluster0 to cluster3), for 4 occupant behavior types.

`<enduse>_consumption_dist.csv`

These files contain the 15-min power consumption kWh samples for the given end use, obtained from RBSA (average 15-min end use kWh for each submetered home; N=number of homes with that end use).
The schedule generator randomly picks one of these values to determine the power level of the appliance schedule.

`<enduse>_duration_dist.csv`

These files contain the samples of runtime duration of different end uses, in 15-min increments, generated from the RBSA dataset.
So, a value of 3 means 45 minutes.
Each row is for one household, and each column is the duration of one instance of the appliance running.

For the above `<enduse>_consumption_dist.csv` and `<enduse>_duration_dist.csv` files, `<enduse>` may be:
* `clothes_dryer`
* `clothes_washer`
* `cooking`
* `dishwasher`

`<enduse>_cluster_size_probability.csv`

These files contain the probability distribution of the event cluster size for different domestic hot water end uses, obtained from the HotWaterEventScheduleGenerator Excel file.
The first row is the probability of a cluster size of 1 event, second row for probability of cluster size of 2 events and so on.

For the above `<enduse>_cluster_size_probability.csv` files, `<enduse>` may be:
* `hot_water_clothes_washer`
* `hot_water_dishwasher`
* `shower`

`constants.rb`

This file contains various miscellaneous configurations for the schedule generator, and their meanings and sources are defined within the file.
