import pandas as pd

'''This function assigns the number of major electric loads in a dwelling. It is intended to be used with
np.vectorize()

We did not have data on the presence of pool/hot tub/spa heaters or pumps.
We should account for the impact of pool/hot tub/spa heater and or pumps in post-processing
and only inlude space heating, water heating, drying, cooking, and cooling as major loads in this calculation.
Major load count, therefore, will range from 0 to 5.'''


def get_major_elec_load_count(has_elec_heating_primary,
                              has_elec_water_heater,
                              has_elec_drying,
                              has_elec_cooking,
                              has_cooling,
                              hvac_cooling_type,
                              hvac_heating_type):
    '''

    :param has_elec_heating_primary: Boolean indicator for electricity as primary heating fuel
    :param has_elec_water_heater: Boolean indicator for electricity as primary water heating fuel
    :param has_elec_drying: Boolean indicator for electricity as drying fuel
    :param has_elec_cooking: Boolean indicator for electricity as cooking fuel
    :param has_cooling: Boolean indicator for presence of cooling
    :param hvac_cooling_type: Aligns with hvac_cooling_type in ResStock data dictionary
    :param hvac_heating_type: Aligns with hvac_heating_type in ResStock data dictionary
    :return: Count (0-5 or 'nan') of major electric loads
    '''

    #Determining if everything is null.
    '''Function was implemented wtih np.vectorize which sometimes has issues returning np.nan.
     I converted 'nan' to np.nan after I called the function. '''

    if any([pd.isna(has_elec_heating_primary),
            pd.isna(has_elec_water_heater),
            pd.isna(has_elec_drying),
            pd.isna(has_elec_cooking),
            pd.isna(has_cooling)]
           ):

        return "nan"

    else:

        #Calculating number of major electric loads
        load_vars = [has_elec_heating_primary,
                     has_elec_water_heater,
                     has_elec_drying,
                     has_elec_cooking,
                     has_cooling
                     ]
        load_count = sum(load_vars)


        ### Dealing with potential double counting ###

        #Count heat pump only once if it provides heating and cooling
        if hvac_cooling_type == "Heat Pump" and hvac_heating_type == "Ducted Heat Pump":

            load_count = load_count - 1 #Assuming a single heat pump provides heating and cooling

        #Don't count plug-in Room ACs as major loads
        elif hvac_cooling_type == "Room AC":

            load_count = load_count - 1


        return load_count