import pandas as pd

'''This function assigns the number of major electric loads in a dwelling. It is intended to be used with
np.vectorize()

We did not have data on the presence of pool/hot tub/spa heaters or pumps.
We should account for the impact of pool/hot tub/spa heater and or pumps in post-processing
and only inlude space heating, water heating, drying, cooking, and cooling as major loads in this calculation.
Major load count, therefore, will range from 0 to 5.'''


def get_major_elec_load_count_w_ev_pv(has_elec_heating_primary,
                                      has_elec_water_heater,
                                      has_elec_drying,
                                      has_elec_cooking,
                                      has_cooling,
                                      has_ev_charging,
                                      has_pv,
                                      has_elec_hot_tub_spa,
                                      has_elec_pool_heater,
                                      has_elec_pool_pump,
                                      has_elec_well_pump):
    '''

    :param has_elec_heating_primary: Boolean indicator for electricity as primary heating fuel
    :param has_elec_water_heater: Boolean indicator for electricity as primary water heating fuel
    :param has_elec_drying: Boolean indicator for electricity as drying fuel
    :param has_elec_cooking: Boolean indicator for electricity as cooking fuel
    :param has_cooling: Boolean indicator for presence of cooling
    :param hvac_cooling_type: Aligns with hvac_cooling_type in ResStock data dictionary
    :param hvac_heating_type: Aligns with hvac_heating_type in ResStock data dictionary
    :param has_ev_charging: Presence of any EV charging (could not differentiate betwee L1 and L2)
    :param has_pv: Presence of PV
    :return: Count (0-6 or 'nan') of major electric loads
    '''

    #Determining if everything is null.
    '''Function was implemented wtih np.vectorize which sometimes has issues returning np.nan.
     I converted 'nan' to np.nan after I called the function. '''

    if any([pd.isna(has_elec_heating_primary),
            pd.isna(has_elec_water_heater),
            pd.isna(has_elec_drying),
            pd.isna(has_elec_cooking),
            pd.isna(has_cooling),
            pd.isna(has_ev_charging),
            pd.isna(has_pv),
            pd.isna(has_elec_hot_tub_spa),
            pd.isna(has_elec_pool_heater),
            pd.isna(has_elec_pool_pump),
            pd.isna(has_elec_well_pump)]
           ):

        return "nan"

    else:

        has_pv_int = 1 if has_pv == "Yes" else 0
        #Calculating number of major electric loads
        load_vars = [has_elec_heating_primary,
                     has_elec_water_heater,
                     has_elec_drying,
                     has_elec_cooking,
                     has_cooling,
                     has_ev_charging,
                     has_pv_int,
                     has_elec_hot_tub_spa,
                     has_elec_pool_heater,
                     has_elec_pool_pump,
                     has_elec_well_pump
                     ]
        load_count = sum(load_vars)


        ### Dealing with potential double counting ###
        #Count heating and cooling as one
        if has_elec_heating_primary == 1 and has_cooling == 1:
            load_count = load_count - 1 

        return load_count




