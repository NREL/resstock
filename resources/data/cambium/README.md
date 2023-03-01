These are all five available Standard Scenarios for three metrics at GEA geographic resolution. Metrics:
1. LRMER levelized over 15 years
2. LRMER levelized over 30 years
3. average emissions rate (AER) non-levelized

2021 Cambium release data:
- Levelized LRMER come from Cambium22_LRMER_GEAregions.xlsx (available at https://data.nrel.gov/submissions/206):

  On the "Levelized LRMER" tab:
  - Emission | CO2e
  - Emission stage | Combined
  - Start year | 2023
  - Evaluation period (years) | 15, 30
  - Discount rate (real) | 0.03
  - Scenario | Mid-case, Low RE Costs, High RE Costs, 95% Decarb by 2050, 95% Decarb by 2035, others?
  - Global Warming Potentials | 100-year (AR6)
  - Location | End-use

- Non-levelized AER come from the Scenario Viewer (available at cambium.nrel.gov):

  Browse "Cambium 22", and on the "Download" tab:
  - Scenarios | High renewable energy cost, Low renewable energy cost, Mid-case, Mid-case with 100% decarbonization by 2035, Mid-case with 95% decarbonization by 2050, others?
  - Time Resolutions | Hourly
  - Location Types | GEA Regions

  Use column "aer_load_co2e" from each "StdScen21_[Scenario]\_hourly_[GEA]_2022.csv" file.

See the Generation And Emissions Assessment Region map [here](https://github.com/NREL/resstock/wiki/Generation-And-Emissions-Assessment-Region-Map).
