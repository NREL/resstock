
###### (Automatically generated documentation)

# Utility Bills Report

## Description
Calculates and reports utility bills for residential HPXML-based models.

Calculate electric/gas utility bills based on monthly fixed charges and marginal rates. Calculate other utility bills based on marginal rates for oil, propane, wood cord, wood pellets, and coal. User can specify PV compensation types of 'Net-Metering' or 'Feed-In Tariff', along with corresponding rates and connection fees.

## Arguments


**Output Format**

The file format of the annual (and timeseries, if requested) outputs.

- **Name:** ``output_format``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `csv`, `json`, `msgpack`

<br/>

**Generate Annual Utility Bills**

Generates output file containing annual utility bills.

- **Name:** ``include_annual_bills``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Monthly Utility Bills**

Generates output file containing monthly utility bills.

- **Name:** ``include_monthly_bills``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Generate Monthly Output: Timestamp Convention**

Determines whether monthly timestamps use the start-of-period or end-of-period convention.

- **Name:** ``monthly_timestamp_convention``
- **Type:** ``Choice``

- **Required:** ``false``

- **Choices:** `start`, `end`

<br/>

**Annual Output File Name**

If not provided, defaults to 'results_bills.csv' (or 'results_bills.json' or 'results_bills.msgpack').

- **Name:** ``annual_output_file_name``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Monthly Output File Name**

If not provided, defaults to 'results_bills_monthly.csv' (or 'results_bills_monthly.json' or 'results_bills_monthly.msgpack').

- **Name:** ``monthly_output_file_name``
- **Type:** ``String``

- **Required:** ``false``

<br/>

**Register Annual Utility Bills**

Registers annual utility bills with the OpenStudio runner for downstream processing.

- **Name:** ``register_annual_bills``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>

**Register Monthly Utility Bills**

Registers monthly utility bills with the OpenStudio runner for downstream processing.

- **Name:** ``register_monthly_bills``
- **Type:** ``Boolean``

- **Required:** ``false``

<br/>





