
class StateAbbrev():

  @staticmethod
  def statename_to_stateabbrev():  
    return {
      'Alabama': 'AL',
      'Alaska': 'AK',
      'Arizona': 'AZ',
      'Arkansas': 'AR',
      'California': 'CA',
      'Colorado': 'CO',
      'Connecticut': 'CT',
      'Delaware': 'DE',
      'District of Columbia': 'DC',
      'Florida': 'FL',
      'Georgia': 'GA',
      'Hawaii': 'HI',
      'Idaho': 'ID',
      'Illinois': 'IL',
      'Indiana': 'IN',
      'Iowa': 'IA',
      'Kansas': 'KS',
      'Kentucky': 'KY',
      'Louisiana': 'LA',
      'Maine': 'ME',
      'Maryland': 'MD',
      'Massachusetts': 'MA',
      'Michigan': 'MI',
      'Minnesota': 'MN',
      'Mississippi': 'MS',
      'Missouri': 'MO',
      'Montana': 'MT',
      'Nebraska': 'NE',
      'Nevada': 'NV',
      'New Hampshire': 'NH',
      'New Jersey': 'NJ',
      'New Mexico': 'NM',
      'New York': 'NY',
      'North Carolina': 'NC',
      'North Dakota': 'ND',
      'Ohio': 'OH',
      'Oklahoma': 'OK',
      'Oregon': 'OR',
      'Pennsylvania': 'PA',
      'Rhode Island': 'RI',
      'South Carolina': 'SC',
      'South Dakota': 'SD',
      'Tennessee': 'TN',
      'Texas': 'TX',
      'Utah': 'UT',
      'Vermont': 'VT',
      'Virginia': 'VA',
      'Washington': 'WA',
      'West Virginia': 'WV',
      'Wisconsin': 'WI',
      'Wyoming': 'WY'
    }
  
  @staticmethod
  def stateabbrev_to_statename(): 
    return {v: k for k, v in StateAbbrev.statename_to_stateabbrev().iteritems()}
    
class ReportableDomain():

  @staticmethod
  def statename_to_reportabledomain():
    return {
      'Connecticut': 1,
      'Maine': 1,
      'New Hampshire': 1,
      'Rhode Island': 1,
      'Vermont': 1,
      'Massachusetts': 2,
      'New York': 3,
      'New Jersey': 4,
      'Pennsylvania': 5,
      'Illinois': 6,
      'Indiana': 7,
      'Ohio': 7,
      'Michigan': 8,
      'Wisconsin': 9,
      'Iowa': 10,
      'Minnesota': 10,
      'North Dakota': 10,
      'South Dakota': 10,
      'Kansas': 11,
      'Nebraska': 11,
      'Missouri': 12,
      'Virginia': 13,
      'Delaware': 14,
      'District of Columbia': 14,
      'Maryland': 14,
      'West Virginia': 14,
      'Georgia': 15,
      'North Carolina': 16,
      'South Carolina': 16,
      'Florida': 17,
      'Alabama': 18,
      'Kentucky': 18,
      'Mississippi': 18,
      'Tennessee': 19,
      'Arkansas': 20,
      'Louisiana': 20,
      'Oklahoma': 20,
      'Texas': 21,
      'Colorado': 22,
      'Idaho': 23,
      'Montana': 23,
      'Utah': 23,
      'Wyoming': 23,
      'Arizona': 24,
      'Nevada': 25,
      'New Mexico': 25,
      'California': 26,
      'Alaska': 27,
      'Hawaii': 27,
      'Oregon': 27,
      'Washington': 27
    }
  
  @staticmethod
  def stateabbrev_to_reportabledomain():
    return {StateAbbrev.statename_to_stateabbrev()[k]: v for k, v in ReportableDomain.statename_to_reportabledomain().iteritems()}
    
class CostEffectiveness():

  @staticmethod
  def simple_payback(incremental_cost, annual_bill_savings):
    return incremental_cost / annual_bill_savings

  @staticmethod
  def net_present_value(discount_rate, analysis_period, measure_life, measure_cost, annual_bill_savings, tax_credit, tax_scenario):
    import numpy as np
    npv = 0
    if np.isnan(measure_life):
      npv = np.nan
    else:
      savings, costs = CostEffectiveness.cash_flows(analysis_period, measure_life, measure_cost, annual_bill_savings, tax_credit, tax_scenario)
      cash_flows = list(np.array(savings) - np.array(costs))
      for year in range(0,analysis_period + 1):
        npv += (1/(1 + discount_rate) ** year) * cash_flows[year]
    return npv

  @staticmethod
  def savings_investment_ratio(discount_rate, analysis_period, measure_life, measure_cost, state, fuel_price_indices, annual_bill_savings_electricity, annual_bill_savings_natural_gas, annual_bill_savings_fuel_oil, annual_bill_savings_propane, tax_credit, tax_scenario):
    import pandas as pd
    import numpy as np
    sir = 0
    if np.isnan(measure_life) or pd.isnull(state):
      sir = np.nan
    else:
      savings_electricity, costs = CostEffectiveness.cash_flows(analysis_period, measure_life, measure_cost, annual_bill_savings_electricity, tax_credit, tax_scenario)
      savings_natural_gas, costs = CostEffectiveness.cash_flows(analysis_period, measure_life, measure_cost, annual_bill_savings_natural_gas, tax_credit, tax_scenario)
      savings_fuel_oil, costs = CostEffectiveness.cash_flows(analysis_period, measure_life, measure_cost, annual_bill_savings_fuel_oil, tax_credit, tax_scenario)
      savings_propane, costs = CostEffectiveness.cash_flows(analysis_period, measure_life, measure_cost, annual_bill_savings_propane, tax_credit, tax_scenario)
      discounts = []
      for year in range(0,analysis_period + 1):
        discounts.append(1/(1 + discount_rate) ** year)
      savings_electricity = sum(np.array(discounts) * np.array(savings_electricity) * np.array(get_fuel_price_indices_for_state_and_fuel_type(fuel_price_indices, state, 'electricity'))) 
      savings_natural_gas = sum(np.array(discounts) * np.array(savings_natural_gas) * np.array(get_fuel_price_indices_for_state_and_fuel_type(fuel_price_indices, state, 'natural_gas')))
      savings_fuel_oil = sum(np.array(discounts) * np.array(savings_fuel_oil) * np.array(get_fuel_price_indices_for_state_and_fuel_type(fuel_price_indices, state, 'fuel_oil')))
      savings_propane = sum(np.array(discounts) * np.array(savings_propane) * np.array(get_fuel_price_indices_for_state_and_fuel_type(fuel_price_indices, state, 'propane')))
      savings = savings_electricity + savings_natural_gas + savings_fuel_oil + savings_propane
      costs = sum(np.array(discounts) * np.array(costs))
      sir = savings / costs
    return sir

  @staticmethod
  def cash_flows(analysis_period, measure_life, measure_cost, annual_bill_savings, tax_credit, tax_scenario):

    # Construct list of cash flow values
    savings = []
    costs = []

    # Initialize
    savings.append(0)
    costs.append(measure_cost)
    measure_age = 0
    year = 0
    
    # Years of cash flow
    for year in range(1, analysis_period):
      measure_age += 1
      if measure_age == measure_life:
        # Replace equipment
        savings.append(annual_bill_savings)
        costs.append(measure_cost)
        measure_age = 0
      else:
        savings.append(annual_bill_savings)
        costs.append(0)
    
    # Final year with Residual value
    year += 1
    measure_age += 1
    if measure_life == 999: # Flag for enclosure measure; full residual value
      residual_value = measure_cost
    else:
      residual_value = (measure_cost * (measure_life - measure_age)/measure_life)
    savings.append(annual_bill_savings + residual_value)
    costs.append(0)
    if tax_scenario in ['1', '2a', '2b']:
      savings[1] += tax_credit
    elif tax_scenario in ['3a', '3b']:
      for i in range(1, 11):
        savings[i] += tax_credit # apply tax credit to years 1-10        
    
    return savings, costs

def get_fuel_price_indices_for_state_and_fuel_type(json, state, fuel_type):
  fuel_type_indices = json[fuel_type]
  for states_indices in fuel_type_indices:
    states = states_indices['states']
    if state in states:
      indices = [1.0] + states_indices['indices']
      return indices

class IncomeBins:

  @staticmethod
  def federal_poverty_level():
    return {
          'Owner 0-50': ['Owner 0-50'],
          'Owner 50-100': ['Owner 50-100'],
          'Owner 100-150': ['Owner 100-150'],
          'Owner 150-200': ['Owner 150-200'],
          'Owner 200-250': ['Owner 200-250'],
          'Owner 250-300': ['Owner 250-300'],
          'Owner 300+': ['Owner 300+'],
          'Owner <100': ['Owner 0-50', 'Owner 50-100'],
          'Owner <150': ['Owner 0-50', 'Owner 50-100', 'Owner 100-150'],
          'Owner <200': ['Owner 0-50', 'Owner 50-100', 'Owner 100-150', 'Owner 150-200'],
          'Owner <250': ['Owner 0-50', 'Owner 50-100', 'Owner 100-150', 'Owner 150-200', 'Owner 200-250'],
          'Owner <300': ['Owner 0-50', 'Owner 50-100', 'Owner 100-150', 'Owner 150-200', 'Owner 200-250', 'Owner 250-300'],
          'Owner all': ['Owner 0-50', 'Owner 50-100', 'Owner 100-150', 'Owner 150-200', 'Owner 200-250', 'Owner 250-300', 'Owner 300+'],
          'Renter 0-50': ['Renter 0-50'],
          'Renter 50-100': ['Renter 50-100'],
          'Renter 100-150': ['Renter 100-150'],
          'Renter 150-200': ['Renter 150-200'],
          'Renter 200-250': ['Renter 200-250'],
          'Renter 250-300': ['Renter 250-300'],
          'Renter 300+': ['Renter 300+'],
          'Renter <100': ['Renter 0-50', 'Renter 50-100'],
          'Renter <150': ['Renter 0-50', 'Renter 50-100', 'Renter 100-150'],
          'Renter <200': ['Renter 0-50', 'Renter 50-100', 'Renter 100-150', 'Renter 150-200'],
          'Renter <250': ['Renter 0-50', 'Renter 50-100', 'Renter 100-150', 'Renter 150-200', 'Renter 200-250'],
          'Renter <300': ['Renter 0-50', 'Renter 50-100', 'Renter 100-150', 'Renter 150-200', 'Renter 200-250', 'Renter 250-300'],
          'Renter all': ['Renter 0-50', 'Renter 50-100', 'Renter 100-150', 'Renter 150-200', 'Renter 200-250', 'Renter 250-300', 'Renter 300+'],
          '<200': ['Owner 0-50', 'Owner 50-100', 'Owner 100-150', 'Owner 150-200', 'Renter 0-50', 'Renter 50-100', 'Renter 100-150', 'Renter 150-200'],
          '<250': ['Owner 0-50', 'Owner 50-100', 'Owner 100-150', 'Owner 150-200', 'Owner 200-250', 'Renter 0-50', 'Renter 50-100', 'Renter 100-150', 'Renter 150-200', 'Renter 200-250'],
          '<300': ['Owner 0-50', 'Owner 50-100', 'Owner 100-150', 'Owner 150-200', 'Owner 200-250', 'Owner 250-300', 'Renter 0-50', 'Renter 50-100', 'Renter 100-150', 'Renter 150-200', 'Renter 200-250', 'Renter 250-300'],
          '200-300': ['Owner 200-250', 'Owner 250-300', 'Renter 200-250', 'Renter 250-300'],
          '300+': ['Owner 300+', 'Renter 300+'],
          'all': ['Owner 0-50', 'Owner 50-100', 'Owner 100-150', 'Owner 150-200', 'Owner 200-250', 'Owner 250-300', 'Owner 300+', 'Renter 0-50', 'Renter 50-100', 'Renter 100-150', 'Renter 150-200', 'Renter 200-250', 'Renter 250-300', 'Renter 300+']
          }

  @staticmethod
  def area_median_income():
    return {
          'Owner 0-30': ['Owner 0-30'],
          'Owner 30-50': ['Owner 30-50'],
          'Owner 50-80': ['Owner 50-80'],
          'Owner 80-100': ['Owner 80-100'],
          'Owner 100-120': ['Owner 100-120'],
          'Owner 120+': ['Owner 120+'],
          'Owner <50': ['Owner 0-30', 'Owner 30-50'],
          'Owner <80': ['Owner 0-30', 'Owner 30-50', 'Owner 50-80'],
          'Owner >80': ['Owner 80-100', 'Owner 100-120', 'Owner 120+'],
          'Owner <100': ['Owner 0-30', 'Owner 30-50', 'Owner 50-80', 'Owner 80-100'],
          'Owner <120': ['Owner 0-30', 'Owner 30-50', 'Owner 50-80', 'Owner 80-100', 'Owner 100-120'],
          'Owner all': ['Owner 0-30', 'Owner 30-50', 'Owner 50-80', 'Owner 80-100', 'Owner 100-120', 'Owner 120+'],
          'Renter 0-30': ['Renter 0-30'],
          'Renter 30-50': ['Renter 30-50'],
          'Renter 50-80': ['Renter 50-80'],
          'Renter 80-100': ['Renter 80-100'],
          'Renter 100-120': ['Renter 100-120'],
          'Renter 120+': ['Renter 120+'],
          'renter <50': ['Renter 0-30', 'Renter 30-50'],
          'Renter <80': ['Renter 0-30', 'Renter 30-50', 'Renter 50-80'],
          'Renter >80': ['Renter 80-100', 'Renter 100-120', 'Renter 120+'],
          'Renter <100': ['Renter 0-30', 'Renter 30-50', 'Renter 50-80', 'Renter 80-100'],
          'Renter <120': ['Renter 0-30', 'Renter 30-50', 'Renter 50-80', 'Renter 80-100', 'Renter 100-120'],
          'Renter all': ['Renter 0-30', 'Renter 30-50', 'Renter 50-80', 'Renter 80-100', 'Renter 100-120', 'Renter 120+'],
          '<80': ['Owner 0-30', 'Owner 30-50', 'Owner 50-80', 'Renter 0-30', 'Renter 30-50', 'Renter 50-80'],
          '>80': ['Owner 80-100', 'Owner 100-120', 'Owner 120+', 'Renter 80-100', 'Renter 100-120', 'Renter 120+'],
          '<100': ['Owner 0-30', 'Owner 30-50', 'Owner 50-80', 'Owner 80-100', 'Renter 0-30', 'Renter 30-50', 'Renter 50-80', 'Renter 80-100'],
          '<120': ['Owner 0-30', 'Owner 30-50', 'Owner 50-80', 'Owner 80-100', 'Owner 100-120', 'Renter 0-30', 'Renter 30-50', 'Renter 50-80', 'Renter 80-100', 'Renter 100-120'],
          'all': ['Owner 0-30', 'Owner 30-50', 'Owner 50-80', 'Owner 80-100', 'Owner 100-120', 'Owner 120+', 'Renter 0-30', 'Renter 30-50', 'Renter 50-80', 'Renter 80-100', 'Renter 100-120', 'Renter 120+']
          }

class UtilityBillCalculations():

  @staticmethod
  def state_level_rates(df):
    """
    Optionally called by the results_savings_csv script. This method assigns utility rates based on epw state for each simulation.
    For electricity and natural gas, marginal rates are first calculated using average rates, a fixed $/month rate, and average annual household consumptions.

    Parameters:
      df (dataframe): A pandas dataframe (results csv file) without any utility_bill_calculations columns.

    Returns:
      df (dataframe): A pandas dataframe with calculated utility bill columns (electricity, gas, oil, propane).

    """
    import os
    import pandas as pd

    elec_rates = pd.read_csv(os.path.join(os.path.dirname(__file__), 'electricity_rates_state_average.csv'))
    elec_rates = elec_rates[pd.notnull(elec_rates['Location'])]
    elec_rates = elec_rates[pd.notnull(elec_rates['Unadjusted'])]
    elec_rates = elec_rates.rename(columns={'Location': 'build_existing_model.state', 'Unadjusted': 'average_elec_rate', 'Household': 'kwh_per_home_per_yr'})
    elec_rates = elec_rates[['build_existing_model.state', 'average_elec_rate', 'kwh_per_home_per_yr']]
    elec_rates = elec_rates.set_index('build_existing_model.state')

    gas_rates = pd.read_csv(os.path.join(os.path.dirname(__file__), 'natural_gas_rates_state_average.csv'))
    gas_rates = gas_rates[pd.notnull(gas_rates['Location'])]
    gas_rates = gas_rates[pd.notnull(gas_rates['Unadjusted'])]
    gas_rates = gas_rates.rename(columns={'Location': 'build_existing_model.state', 'Unadjusted': 'average_gas_rate', 'Household': 'therm_per_home_per_yr'})
    gas_rates = gas_rates[['build_existing_model.state', 'average_gas_rate', 'therm_per_home_per_yr']]
    gas_rates = gas_rates.set_index('build_existing_model.state')

    oil_rates = pd.read_csv(os.path.join(os.path.dirname(__file__), 'oil_rates_state_average.csv'))
    oil_rates = oil_rates[pd.notnull(oil_rates['Location'])]
    oil_rates = oil_rates[pd.notnull(oil_rates['Price'])]
    oil_rates = oil_rates.rename(columns={'Location': 'build_existing_model.state', 'Price': 'average_oil_rate'})
    oil_rates = oil_rates[['build_existing_model.state', 'average_oil_rate']]
    oil_rates = oil_rates.set_index('build_existing_model.state')

    prop_rates = pd.read_csv(os.path.join(os.path.dirname(__file__), 'propane_rates_state_average.csv'))
    prop_rates = prop_rates[pd.notnull(prop_rates['Location'])]
    prop_rates = prop_rates[pd.notnull(prop_rates['Price'])]
    prop_rates = prop_rates.rename(columns={'Location': 'build_existing_model.state', 'Price': 'average_prop_rate'})
    prop_rates = prop_rates[['build_existing_model.state', 'average_prop_rate']]
    prop_rates = prop_rates.set_index('build_existing_model.state')

    rates = pd.concat([elec_rates, gas_rates, oil_rates, prop_rates], axis=1)
    rates = rates.reset_index()
    for col in rates.columns:
      if 'state' in col:
        continue
      rates[col] = rates[col].astype(float)
    df = df.reset_index()
    df = pd.merge(df, rates, how='left', on='build_existing_model.state')
    df = df.set_index('_id')

    fixed_elec_rate = 8.0 # $/month
    df['marginal_elec_rate'] = df['average_elec_rate'] - 12.0 * fixed_elec_rate / df['kwh_per_home_per_yr'] # convert average rate to marginal rate
    df['utility_bill_calculations.electricity'] = 12.0 * fixed_elec_rate + df['simulation_output_report.total_site_electricity_kwh'] * df['marginal_elec_rate']

    fixed_gas_rate = 8.0 # $/month
    df['marginal_gas_rate'] = df['average_gas_rate'] - 12.0 * fixed_gas_rate / df['therm_per_home_per_yr'] # convert average rate to marginal rate
    df['utility_bill_calculations.natural_gas'] = 12.0 * fixed_elec_rate + df['simulation_output_report.total_site_natural_gas_therm'] * df['marginal_gas_rate']

    df['utility_bill_calculations.fuel_oil'] = ( df['simulation_output_report.total_site_fuel_oil_mbtu'] * 1e6 / 139000 ) * df['average_oil_rate']

    df['utility_bill_calculations.propane'] = ( df['simulation_output_report.total_site_propane_mbtu'] * 1e6 / 91600 ) * df['average_prop_rate']

    del df['average_elec_rate']
    del df['average_gas_rate']
    del df['average_oil_rate']
    del df['average_prop_rate']

    del df['kwh_per_home_per_yr']
    del df['marginal_elec_rate']
    del df['therm_per_home_per_yr']
    del df['marginal_gas_rate']

    return df

  @staticmethod
  def county_level_rates(df, upgrade):
    """
    Optionally called by the income_bin_disaggregation script. This method assigns utility rates based on counties (nsrdb_utility_weights resource file).
    For electricity and natural gas, marginal rates are first calculated using average rates, a fixed $/month rate, and average annual household consumptions.

    Parameters:
      df (dataframe): A pandas dataframe (results csv file) without any utility_bill_calculations columns.

    Returns:
      df (dataframe): A pandas dataframe with calculated utility bill columns (electricity, gas, oil, propane).

    """
    import pandas as pd

    fixed_elec_rate = 8.0 # $/month
    t = df[['simulation_output_report.total_site_electricity_kwh', 'weight', 'Dependency=Location County']]
    t['simulation_output_report.total_site_electricity_kwh'] *= t['weight']
    t = t.groupby('Dependency=Location County').sum()
    t['kwh_per_home_per_yr'] = t['simulation_output_report.total_site_electricity_kwh'] / t['weight']
    del t['simulation_output_report.total_site_electricity_kwh']
    del t['weight']
    t = t.reset_index()
    df = pd.merge(df, t, on='Dependency=Location County')    
    df['marginal_elec_rate'] = df['average_elec_rate'] - 12.0 * fixed_elec_rate / df['kwh_per_home_per_yr'] # convert average rate to marginal rate
    df['utility_bill_calculations.electricity'] = 12.0 * fixed_elec_rate + df['simulation_output_report.total_site_electricity_kwh'] * df['marginal_elec_rate']
    if upgrade:
      df['savings_utility_bill_calculations.electricity'] = df['savings_simulation_output_report.total_site_electricity_kwh'] * df['marginal_elec_rate']
    del df['marginal_elec_rate']
    del df['kwh_per_home_per_yr']

    fixed_gas_rate = 8.0 # $/month
    df['marginal_gas_rate'] = df['average_gas_rate'] - 12.0 * fixed_gas_rate / df['therm_per_home_per_yr'] # convert average rate to marginal rate
    df['utility_bill_calculations.natural_gas'] = 12.0 * fixed_gas_rate + df['simulation_output_report.total_site_natural_gas_therm'] * df['marginal_gas_rate']
    if upgrade:
      df['savings_utility_bill_calculations.natural_gas'] = df['savings_simulation_output_report.total_site_natural_gas_therm'] * df['marginal_gas_rate']
    del df['marginal_gas_rate']    

    df['utility_bill_calculations.fuel_oil'] = ( df['simulation_output_report.total_site_fuel_oil_mbtu'] * 1e6 / 139000 ) * df['average_oil_rate']
    if upgrade:
      df['savings_utility_bill_calculations.fuel_oil'] = ( df['savings_simulation_output_report.total_site_fuel_oil_mbtu'] * 1e6 / 139000 ) * df['average_oil_rate']

    df['utility_bill_calculations.propane'] = ( df['simulation_output_report.total_site_propane_mbtu'] * 1e6 / 91600 ) * df['average_prop_rate']
    if upgrade:
      df['savings_utility_bill_calculations.propane'] = ( df['savings_simulation_output_report.total_site_propane_mbtu'] * 1e6 / 91600 ) * df['average_prop_rate']

    df['utility_bill_calculations.total_bill'] = df['utility_bill_calculations.electricity'] + df['utility_bill_calculations.natural_gas'] + df['utility_bill_calculations.fuel_oil'] + df['utility_bill_calculations.propane']

    return df