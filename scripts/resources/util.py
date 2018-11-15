
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
  def savings_investment_ratio(discount_rate, analysis_period, measure_life, measure_cost, annual_bill_savings, tax_credit, tax_scenario):
    import numpy as np
    sir = 0
    if np.isnan(measure_life):
      sir = np.nan
    else:
      savings, costs = CostEffectiveness.cash_flows(analysis_period, measure_life, measure_cost, annual_bill_savings, tax_credit, tax_scenario)
      discounts = []
      for year in range(0,analysis_period + 1):
        discounts.append(1/(1 + discount_rate) ** year)
      savings = sum(np.array(discounts) * np.array(savings)) 
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