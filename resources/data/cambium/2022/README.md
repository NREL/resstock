These are all 10 available Standard Scenarios for three metrics at GEA geographic resolution. Metrics:
1. LRMER levelized over 15 years
2. LRMER levelized over 30 years
3. average emissions rate (AER) non-levelized

2022 Cambium release data:
- Levelized **LRMER** come from Cambium22_LRMER_GEAregions.xlsx (available via [Long-run Marginal Emission Rates for Electricity - Workbooks for 2022 Cambium Data](https://data.nrel.gov/submissions/206)):

  On the "Levelized LRMER" tab:
  - Emission | CO2e
  - Emission stage | Combined
  - Start year | 2025
  - Evaluation period (years) | 15, 30
  - Discount rate (real) | 0.03
  - Scenario | Mid-case, Low RE Costs, High RE Costs, 95% Decarb by 2050, 95% Decarb by 2035, Low NG Prices, High NG Prices, Electrification, Mid-case (credits expire), Low RE Costs (credits expire)
  - Global Warming Potentials | 100-year (AR5)
  - Location | End-use

- Non-levelized **AER** come from the Scenario Viewer (available via [Scenario Viewer :: Data Downloader](https://cambium.nrel.gov)):

  Browse "Cambium 22", and on the "Download" tab:
  - Scenarios | Mid-case, High renewable energy cost, Low renewable energy cost, Mid-case with 95% decarbonization by 2050, Mid-case with 100% decarbonization by 2035, Low natural gas prices, High natural gas prices, High electrification, Mid-case with tax credit expiration, Low renewable energy cost with tax credit expiration
  - Time Resolutions | Hourly
  - Location Types | GEA Regions

  Use column "aer_load_co2e" from each "Cambium2022_[Scenario]\_hourly_[GEA]_2024.csv" file.

See the Generation And Emissions Assessment Region map [here](https://github.com/NREL/resstock/wiki/Generation-And-Emissions-Assessment-Region-Map).
