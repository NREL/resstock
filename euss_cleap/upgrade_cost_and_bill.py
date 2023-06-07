"""
Upgrade and volumetric bill recalculation - 

C-LEAP Implementation of Community Cost Information into 
EUSS Round 1 Results

by: Yingli.Lou@nrel.gov
06-05-2023
"""

import pandas as pd
from pathlib import Path
import numpy as np
import argparse


datadir = Path(__file__).resolve().parent / "data_"
outdir = Path(__file__).resolve().parent / "results"
outdir.mkdir(parents=True, exist_ok=True)

# conversion
NG_HEAT_CONTENT = (
    1034.0  # BTU/ft3 - https://www.eia.gov/dnav/ng/ng_cons_heat_a_EPG0_VGTH_btucf_a.htm
)
PROPANE_HEAT_CONTENT = (
    91452  # BTU/gal - https://www.eia.gov/energyexplained/units-and-calculators/
)
FUEL_OIL_HEAT_CONTENT = (
    6287000 / 42
)  # BTU/gal - https://www.eia.gov/energyexplained/units-and-calculators/
MBTU_TO_THERM = 10
KBTU_TO_THERM = 1e-2
MBTU_TO_KWH = 293.07107
KBTU_TO_KWH = 0.29307107
KBTU_TO_MBTU = 1e-3
MBTU_TO_TBTU = 1e-6
MBTU_TO_BTU = 1e6
KWH_TO_MWH = 1e-3
KWH_TO_GWH = 1e-6
CENTS_TO_DOLLARS = 1e-2

# local cost for cummunity
def process_euss_upgrade_files(
    cost_file, community_name=None, use_multipliers_only=False
):
    """main call function for processing EUSS Round 1 annual files for CLEAP communities
    Args:
        cost_file : Path or str
            name of cost template file
        community_name : str
            name of community, used to add extension to output filename
        use_multiplers_only : bool
            whether to update upgrade costs by only adjusting EUSS default costs with local/inflation multipliers
    """

    # -- [1] Cost specs --
    cost = pd.read_csv(Path(cost_file))
    # Method 1 cost updates - community inputs
    # where not available, costs in template are derived from EUSS default costs adjusted with local/inflation multipliers
    r30_cost1 = cost.iat[0, 1]
    r30_cost2 = cost.iat[0, 3]
    r49_cost1 = cost.iat[1, 1]
    r49_cost2 = cost.iat[1, 3]
    r60_cost1 = cost.iat[2, 1]
    r60_cost2 = cost.iat[2, 3]
    reduce_infil_30_cost = cost.iat[3, 1]
    ducts1 = cost.iat[4, 1]
    ducts2 = cost.iat[5, 1]
    ducts3 = cost.iat[6, 1]
    ducts4 = cost.iat[7, 1]
    ducts5 = cost.iat[8, 1]
    wall_r13 = cost.iat[9, 1]

    wall_foundation = cost.iat[10, 1]
    wall_basement = cost.iat[11, 1]
    rim = cost.iat[12, 1]
    crawlspaces = cost.iat[13, 1]
    roof = cost.iat[14, 1]

    ASHP_cost1 = cost.iat[15, 1]
    ASHP_cost2 = cost.iat[15, 3]
    MSHP_max_9_cost1 = cost.iat[16, 1]
    MSHP_max_9_cost2 = cost.iat[16, 3]
    ducted_MSHP_cost1 = cost.iat[17, 1]
    ducted_MSHP_cost2 = cost.iat[17, 3]
    ducted_HP_cost1 = cost.iat[18, 1]
    ducted_HP_cost2 = cost.iat[18, 3]
    MSHP_max_14_cost1 = cost.iat[19, 1]
    MSHP_max_14_cost2 = cost.iat[19, 3]
    MSHP_ele_baseboard_cost1 = cost.iat[20, 1]
    MSHP_ele_baseboard_cost2 = cost.iat[20, 3]
    MSHP_ele_boiler_cost1 = cost.iat[21, 1]
    MSHP_ele_boiler_cost2 = cost.iat[21, 3]
    MSHP_furnace_cost1 = cost.iat[22, 1]
    MSHP_furnace_cost2 = cost.iat[22, 3]
    MSHP_upgrade_cost1 = cost.iat[23, 1]
    MSHP_upgrade_cost2 = cost.iat[23, 3]
    furnace_cost1 = cost.iat[24, 1]
    furnace_cost2 = cost.iat[24, 3]
    ASHP_fossil_cost1 = cost.iat[25, 1]
    ASHP_fossil_cost2 = cost.iat[25, 3]

    WH_50 = cost.iat[26, 1]
    WH_66 = cost.iat[27, 1]
    WH_80 = cost.iat[28, 1]

    HPWH_50 = cost.iat[29, 1]
    HPWH_66 = cost.iat[30, 1]
    HPWH_80 = cost.iat[31, 1]

    dryer = cost.iat[32, 1]
    ele_range = cost.iat[33, 1]

    high_ducted_HP_cost1 = cost.iat[34, 1]
    high_ducted_HP_cost2 = cost.iat[34, 3]
    high_ductless_HP_cost1 = cost.iat[35, 1]
    high_ductless_HP_cost2 = cost.iat[35, 3]
    dryer_HP = cost.iat[36, 1]
    induction_range = cost.iat[37, 1]

    ele_price = cost.iat[38, 1] * CENTS_TO_DOLLARS  # c/kwh -> $/kwh
    ele_month_fix = cost.iat[38, 3]  # $/month
    gas_price = cost.iat[39, 1]  # $/therm
    gas_month_fix = cost.iat[39, 3]  # $/month
    propane_price = cost.iat[40, 1]  # $/gal
    propane_month_fix = cost.iat[40, 3]  # $/month
    oil_price = cost.iat[41, 1]  # $/gal
    oil_month_fix = cost.iat[41, 3]  # $/month

    # Method 2 cost updates - EUSS default costs x local/inflation multipliers
    local_multiplier = cost.iat[42, 1]  # local cost multiplier
    inflation_multiplier = cost.iat[43, 1]  # inflation multiplier

    ## -- [2] Helper functions --
    def process_upgrade_file(
        input_filename, output_filename, upgrade_number="00", use_multipliers_only=False
    ):

        # load
        df = (
            pd.read_csv(input_filename)
            .sort_values(by=["building_id"])
            .reset_index(drop=True)
        )

        # recalculate upgrade costs
        if upgrade_number > 0:
            if use_multipliers_only:
                df = update_costs_with_multipliers_only(df)
            else:
                df = process_upgrade_costs(df, upgrade_number=upgrade_number)

        # calculate bills
        df = calculate_bills(df)

        # save
        df.to_csv(output_filename, index=False)

    def update_costs_with_multipliers_only(df):
        cost_cols = [
            col
            for col in df.columns
            if col.startswith("upgrade_costs.option_") and col.endswith("_cost_usd")
        ]
        cost_cols.append("upgrade_costs.upgrade_cost_usd")
        df[cost_cols] *= local_multiplier * inflation_multiplier
        return df

    def process_upgrade_costs(df, upgrade_number=0):
        """assign process_upgrade_XX_costs function according to upgrade_number"""
        upgrade_number = int(upgrade_number)

        if upgrade_number == 0:
            return df
        if upgrade_number == 1:
            return process_upgrade_01_costs(df)
        if upgrade_number == 2:
            return process_upgrade_02_costs(df)
        if upgrade_number == 3:
            return process_upgrade_03_costs(df)
        if upgrade_number == 4:
            return process_upgrade_04_costs(df)
        if upgrade_number == 5:
            return process_upgrade_05_costs(df)
        if upgrade_number == 6:
            return process_upgrade_06_costs(df)
        if upgrade_number == 7:
            return process_upgrade_07_costs(df)
        if upgrade_number == 8:
            return process_upgrade_08_costs(df)
        if upgrade_number == 9:
            return process_upgrade_09_costs(df)
        if upgrade_number == 10:
            return process_upgrade_10_costs(df)

        raise ValueError(f"Unknown upgrade_number={upgrade_number}, valid: 0-10")

    def calculate_bills(dfi):
        df = dfi.copy()
        bill_cols = []
        for fuel, month_cost, var_cost, conversion in zip(
            ["electricity", "natural_gas", "propane", "fuel_oil"],
            [ele_month_fix, gas_month_fix, propane_month_fix, oil_month_fix],
            [ele_price, gas_price, propane_price, oil_price],
            [
                MBTU_TO_KWH,
                MBTU_TO_THERM,
                MBTU_TO_BTU / PROPANE_HEAT_CONTENT,
                MBTU_TO_BTU / FUEL_OIL_HEAT_CONTENT,
            ],  # for variable costs
        ):

            if fuel == "electricity":
                energy_col = "report_simulation_output.fuel_use_electricity_net_m_btu"
            else:
                energy_col = f"report_simulation_output.fuel_use_{fuel}_total_m_btu"
            bill_col = f"report_utility_bills.bills_{fuel}_total_usd"
            bill_cols.append(bill_col)

            df[bill_col] = np.where(
                df[energy_col] > 0,
                df[energy_col] * conversion * var_cost + month_cost * 12,
                np.where(
                    df[energy_col] <= 0,  # assume 0 bill if net is negative
                    0,
                    np.nan,
                ),
            )
        cond = df["completed_status"] == "Success"
        df.loc[cond, "report_utility_bills.bills_total_usd"] = df.loc[
            cond, bill_cols
        ].sum(axis=1)

        return df

    def _update_total_upgrade_cost(df):
        cost_cols = [
            col
            for col in df.columns
            if col.startswith("upgrade_costs.option_") and col.endswith("_cost_usd")
        ]
        df["upgrade_costs.upgrade_cost_usd"] = df[cost_cols].sum(axis=1)

        return df

    ## -- data processing for up01 --
    def process_upgrade_01_costs(up01):
        # Insulate ceiling to R-30
        up01.loc[
            up01["upgrade_costs.option_01_cost_usd"] > 0,
            "upgrade_costs.option_01_cost_usd",
        ] = (
            r30_cost1
            * up01[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r30_cost2 * up01["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Insulate ceiling to R-49
        up01.loc[
            up01["upgrade_costs.option_02_cost_usd"] > 0,
            "upgrade_costs.option_02_cost_usd",
        ] = (
            r49_cost1
            * up01[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r49_cost2 * up01["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Insulate ceiling to R-60
        up01.loc[
            up01["upgrade_costs.option_03_cost_usd"] > 0,
            "upgrade_costs.option_03_cost_usd",
        ] = (
            r60_cost1
            * up01[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r60_cost2 * up01["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Reduce infiltration by 30%
        up01.loc[
            up01["upgrade_costs.option_04_cost_usd"] > 0,
            "upgrade_costs.option_04_cost_usd",
        ] = (
            reduce_infil_30_cost * up01["upgrade_costs.floor_area_conditioned_ft_2"]
        )
        # Insulate and seal ducts a lot to have 10% leakage and R-8 ducts
        up01.loc[
            up01["upgrade_costs.option_05_cost_usd"] > 0,
            "upgrade_costs.option_05_cost_usd",
        ] = (
            ducts1 * up01["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Seal ducts a lot to have 10% leakage, already has R-8 insulation
        up01.loc[
            up01["upgrade_costs.option_06_cost_usd"] > 0,
            "upgrade_costs.option_06_cost_usd",
        ] = (
            ducts2 * up01["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Insulate and seal ducts some to have 10% leakage and R-8 ducts
        up01.loc[
            up01["upgrade_costs.option_07_cost_usd"] > 0,
            "upgrade_costs.option_07_cost_usd",
        ] = (
            ducts3 * up01["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Seal ducts some to have 10% leakage, already has R-8 insulation
        up01.loc[
            up01["upgrade_costs.option_08_cost_usd"] > 0,
            "upgrade_costs.option_08_cost_usd",
        ] = (
            ducts4 * up01["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Only insulate ducts to R-8, no sealing
        up01.loc[
            up01["upgrade_costs.option_09_cost_usd"] > 0,
            "upgrade_costs.option_09_cost_usd",
        ] = (
            ducts5 * up01["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Insulation Wall|Wood Stud, R-13
        up01.loc[
            up01["upgrade_costs.option_10_cost_usd"] > 0,
            "upgrade_costs.option_10_cost_usd",
        ] = (
            wall_r13 * up01["upgrade_costs.wall_area_above_grade_conditioned_ft_2"]
        )

        # update total cost
        up01 = _update_total_upgrade_cost(up01)
        return up01

    ## -- data processing for up02 --
    def process_upgrade_02_costs(up02):
        # Insulate ceiling to R-30
        up02.loc[
            up02["upgrade_costs.option_01_cost_usd"] > 0,
            "upgrade_costs.option_01_cost_usd",
        ] = (
            r30_cost1
            * up02[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r30_cost2 * up02["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Insulate ceiling to R-49
        up02.loc[
            up02["upgrade_costs.option_02_cost_usd"] > 0,
            "upgrade_costs.option_02_cost_usd",
        ] = (
            r49_cost1
            * up02[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r49_cost2 * up02["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Insulate ceiling to R-60
        up02.loc[
            up02["upgrade_costs.option_03_cost_usd"] > 0,
            "upgrade_costs.option_03_cost_usd",
        ] = (
            r60_cost1
            * up02[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r60_cost2 * up02["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Reduce infiltration by 30%
        up02.loc[
            up02["upgrade_costs.option_04_cost_usd"] > 0,
            "upgrade_costs.option_04_cost_usd",
        ] = (
            reduce_infil_30_cost * up02["upgrade_costs.floor_area_conditioned_ft_2"]
        )
        # Insulate and seal ducts a lot to have 10% leakage and R-8 ducts
        up02.loc[
            up02["upgrade_costs.option_05_cost_usd"] > 0,
            "upgrade_costs.option_05_cost_usd",
        ] = (
            ducts1 * up02["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Seal ducts a lot to have 10% leakage, already has R-8 insulation
        up02.loc[
            up02["upgrade_costs.option_06_cost_usd"] > 0,
            "upgrade_costs.option_06_cost_usd",
        ] = (
            ducts2 * up02["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Insulate and seal ducts some to have 10% leakage and R-8 ducts
        up02.loc[
            up02["upgrade_costs.option_07_cost_usd"] > 0,
            "upgrade_costs.option_07_cost_usd",
        ] = (
            ducts3 * up02["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Seal ducts some to have 10% leakage, already has R-8 insulation
        up02.loc[
            up02["upgrade_costs.option_08_cost_usd"] > 0,
            "upgrade_costs.option_08_cost_usd",
        ] = (
            ducts4 * up02["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Only insulate ducts to R-8, no sealing
        up02.loc[
            up02["upgrade_costs.option_09_cost_usd"] > 0,
            "upgrade_costs.option_09_cost_usd",
        ] = (
            ducts5 * up02["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Insulation Wall|Wood Stud, R-13
        up02.loc[
            up02["upgrade_costs.option_10_cost_usd"] > 0,
            "upgrade_costs.option_10_cost_usd",
        ] = (
            wall_r13 * up02["upgrade_costs.wall_area_above_grade_conditioned_ft_2"]
        )

        # Insulate interior foundation wall to R-10
        up02.loc[
            up02["upgrade_costs.option_11_cost_usd"] > 0,
            "upgrade_costs.option_11_cost_usd",
        ] = (
            wall_foundation * up02["upgrade_costs.wall_area_below_grade_ft_2"]
        )
        # Insulate interior finished basement wall to R-10
        up02.loc[
            up02["upgrade_costs.option_12_cost_usd"] > 0,
            "upgrade_costs.option_12_cost_usd",
        ] = (
            wall_basement * up02["upgrade_costs.wall_area_below_grade_ft_2"]
        )
        # Insulation Rim Joist|R-10, Exterior
        up02.loc[
            up02["upgrade_costs.option_13_cost_usd"] > 0,
            "upgrade_costs.option_13_cost_usd",
        ] = (
            rim * up02["upgrade_costs.rim_joist_area_above_grade_exterior_ft_2"]
        )
        # Geometry Foundation Type|Unvented Crawlspace
        up02.loc[
            up02["upgrade_costs.option_14_cost_usd"] > 0,
            "upgrade_costs.option_14_cost_usd",
        ] = (
            crawlspaces * up02["upgrade_costs.floor_area_foundation_ft_2"]
        )
        # Insulation Roof|Finished, R-30
        up02.loc[
            up02["upgrade_costs.option_15_cost_usd"] > 0,
            "upgrade_costs.option_15_cost_usd",
        ] = (
            roof * up02["upgrade_costs.roof_area_ft_2"]
        )

        # update total cost
        up02 = _update_total_upgrade_cost(up02)
        return up02

    ## -- data processing for up03 --
    def process_upgrade_03_costs(up03):
        # HVAC Heating Efficiency|ASHP, SEER 15, 9.0 HSPF
        up03.loc[
            up03["upgrade_costs.option_01_cost_usd"] > 0,
            "upgrade_costs.option_01_cost_usd",
        ] = (
            ASHP_cost1
            + ASHP_cost2 * up03["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|MSHP, SEER 15, 9.0 HSPF, Max Load
        up03.loc[
            up03["upgrade_costs.option_02_cost_usd"] > 0,
            "upgrade_costs.option_02_cost_usd",
        ] = (
            MSHP_max_9_cost1
            + MSHP_max_9_cost2
            * up03["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )

        # update total cost
        up03 = _update_total_upgrade_cost(up03)
        return up03

    ## -- data processing for up04 --
    def process_upgrade_04_costs(up04):
        # HVAC Heating Efficiency|MSHP, SEER 24, 13 HSPF
        up04.loc[
            up04["upgrade_costs.option_01_cost_usd"] > 0,
            "upgrade_costs.option_01_cost_usd",
        ] = (
            ducted_MSHP_cost1
            + ducted_MSHP_cost2
            * up04["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|MSHP, SEER 29.3, 14 HSPF, Max Load
        up04.loc[
            up04["upgrade_costs.option_03_cost_usd"] > 0,
            "upgrade_costs.option_03_cost_usd",
        ] = (
            MSHP_max_14_cost1
            + MSHP_max_14_cost2
            * up04["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )

        # update total cost
        up04 = _update_total_upgrade_cost(up04)
        return up04

    ## -- data processing for up05 --
    def process_upgrade_05_costs(up05):
        # HVAC Heating Efficiency|Dual-System MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup
        up05.loc[
            up05["upgrade_costs.option_01_cost_usd"] > 0,
            "upgrade_costs.option_01_cost_usd",
        ] = (
            MSHP_ele_baseboard_cost1
            + MSHP_ele_baseboard_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|Dual-System MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup
        up05.loc[
            up05["upgrade_costs.option_04_cost_usd"] > 0,
            "upgrade_costs.option_04_cost_usd",
        ] = (
            MSHP_ele_boiler_cost1
            + MSHP_ele_boiler_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|Dual-System MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup
        up05.loc[
            up05["upgrade_costs.option_07_cost_usd"] > 0,
            "upgrade_costs.option_07_cost_usd",
        ] = (
            MSHP_furnace_cost1
            + MSHP_furnace_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|ASHP, SEER 15, 9.0 HSPF
        up05.loc[
            up05["upgrade_costs.option_10_cost_usd"] > 0,
            "upgrade_costs.option_10_cost_usd",
        ] = (
            ASHP_cost1
            + ASHP_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|MSHP, SEER 15, 9.0 HSPF, Max Load
        up05.loc[
            up05["upgrade_costs.option_11_cost_usd"] > 0,
            "upgrade_costs.option_11_cost_usd",
        ] = (
            MSHP_upgrade_cost1
            + MSHP_upgrade_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|Dual-Fuel ASHP, SEER 15, 9.0 HSPF, Separate Backup
        up05.loc[
            up05["upgrade_costs.option_12_cost_usd"] > 0,
            "upgrade_costs.option_12_cost_usd",
        ] = (
            ASHP_cost1
            + ASHP_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|Dual-Fuel MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup
        up05.loc[
            up05["upgrade_costs.option_13_cost_usd"] > 0,
            "upgrade_costs.option_13_cost_usd",
        ] = (
            MSHP_max_9_cost1
            + MSHP_max_9_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )

        # ducted furnace
        up05.loc[
            up05["upgrade_costs.option_30_cost_usd"] > 0,
            "upgrade_costs.option_30_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_33_cost_usd"] > 0,
            "upgrade_costs.option_33_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_34_cost_usd"] > 0,
            "upgrade_costs.option_34_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_37_cost_usd"] > 0,
            "upgrade_costs.option_37_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_39_cost_usd"] > 0,
            "upgrade_costs.option_39_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_42_cost_usd"] > 0,
            "upgrade_costs.option_42_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_43_cost_usd"] > 0,
            "upgrade_costs.option_43_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_46_cost_usd"] > 0,
            "upgrade_costs.option_46_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_51_cost_usd"] > 0,
            "upgrade_costs.option_51_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_52_cost_usd"] > 0,
            "upgrade_costs.option_52_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_55_cost_usd"] > 0,
            "upgrade_costs.option_55_cost_usd",
        ] = (
            furnace_cost1
            + furnace_cost2 * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )

        # shared heating
        up05.loc[
            up05["upgrade_costs.option_57_cost_usd"] > 0,
            "upgrade_costs.option_57_cost_usd",
        ] = (
            ASHP_fossil_cost1
            + ASHP_fossil_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_58_cost_usd"] > 0,
            "upgrade_costs.option_58_cost_usd",
        ] = (
            ASHP_fossil_cost1
            + ASHP_fossil_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_59_cost_usd"] > 0,
            "upgrade_costs.option_59_cost_usd",
        ] = (
            ASHP_fossil_cost1
            + ASHP_fossil_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        up05.loc[
            up05["upgrade_costs.option_60_cost_usd"] > 0,
            "upgrade_costs.option_60_cost_usd",
        ] = (
            ASHP_fossil_cost1
            + ASHP_fossil_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )

        # HVAC Heating Efficiency|Dual-Fuel MSHP, SEER 15, 9.0 HSPF, Max Load, Separate Backup
        up05.loc[
            up05["upgrade_costs.option_61_cost_usd"] > 0,
            "upgrade_costs.option_61_cost_usd",
        ] = (
            MSHP_max_9_cost1
            + MSHP_max_9_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|MSHP, SEER 15, 9.0 HSPF, Max Load
        up05.loc[
            up05["upgrade_costs.option_62_cost_usd"] > 0,
            "upgrade_costs.option_62_cost_usd",
        ] = (
            MSHP_max_9_cost1
            + MSHP_max_9_cost2
            * up05["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )

        # update total cost
        up05 = _update_total_upgrade_cost(up05)

        return up05

    ## -- data processing for up06 --
    def process_upgrade_06_costs(up06):
        # Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF
        up06.loc[
            up06["upgrade_costs.option_01_cost_usd"] > 0,
            "upgrade_costs.option_01_cost_usd",
        ] = HPWH_50
        # Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF
        up06.loc[
            up06["upgrade_costs.option_02_cost_usd"] > 0,
            "upgrade_costs.option_02_cost_usd",
        ] = HPWH_66
        # Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF
        up06.loc[
            up06["upgrade_costs.option_03_cost_usd"] > 0,
            "upgrade_costs.option_03_cost_usd",
        ] = HPWH_80

        # update total cost
        up06 = _update_total_upgrade_cost(up06)

        return up06

    ## -- data processing for up07 --
    def process_upgrade_07_costs(up07):
        # HVAC Heating Efficiency|ASHP, SEER 15, 9.0 HSPF
        up07.loc[
            up07["upgrade_costs.option_01_cost_usd"] > 0,
            "upgrade_costs.option_01_cost_usd",
        ] = (
            ASHP_cost1
            + ASHP_cost2 * up07["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|MSHP, SEER 15, 9.0 HSPF, Max Load
        up07.loc[
            up07["upgrade_costs.option_02_cost_usd"] > 0,
            "upgrade_costs.option_02_cost_usd",
        ] = (
            MSHP_max_9_cost1
            + MSHP_max_9_cost2
            * up07["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF
        up07.loc[
            up07["upgrade_costs.option_04_cost_usd"] > 0,
            "upgrade_costs.option_04_cost_usd",
        ] = WH_50
        # Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF
        up07.loc[
            up07["upgrade_costs.option_05_cost_usd"] > 0,
            "upgrade_costs.option_05_cost_usd",
        ] = WH_66
        # Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF
        up07.loc[
            up07["upgrade_costs.option_06_cost_usd"] > 0,
            "upgrade_costs.option_06_cost_usd",
        ] = WH_80

        # Clothes Dryer|Electric, 80% Usage
        up07.loc[
            up07["upgrade_costs.option_07_cost_usd"] > 0,
            "upgrade_costs.option_07_cost_usd",
        ] = dryer
        # Clothes Dryer|Electric, 100% Usage
        up07.loc[
            up07["upgrade_costs.option_08_cost_usd"] > 0,
            "upgrade_costs.option_08_cost_usd",
        ] = dryer
        # Clothes Dryer|Electric, 120% Usage
        up07.loc[
            up07["upgrade_costs.option_09_cost_usd"] > 0,
            "upgrade_costs.option_09_cost_usd",
        ] = dryer

        # Cooking Range|Electric, 80% Usage
        up07.loc[
            up07["upgrade_costs.option_10_cost_usd"] > 0,
            "upgrade_costs.option_10_cost_usd",
        ] = ele_range
        # Cooking Range|Electric, 100% Usage
        up07.loc[
            up07["upgrade_costs.option_11_cost_usd"] > 0,
            "upgrade_costs.option_11_cost_usd",
        ] = ele_range
        # Cooking Range|Electric, 120% Usage
        up07.loc[
            up07["upgrade_costs.option_12_cost_usd"] > 0,
            "upgrade_costs.option_12_cost_usd",
        ] = ele_range

        # update total cost
        up07 = _update_total_upgrade_cost(up07)
        return up07

    ## -- data processing for up08 --
    def process_upgrade_08_costs(up08):
        # HVAC Heating Efficiency|MSHP, SEER 24, 13 HSPF
        up08.loc[
            up08["upgrade_costs.option_01_cost_usd"] > 0,
            "upgrade_costs.option_01_cost_usd",
        ] = (
            ducted_MSHP_cost1
            + ducted_MSHP_cost2
            * up08["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|MSHP, SEER 29.3, 14 HSPF, Max Load
        up08.loc[
            up08["upgrade_costs.option_03_cost_usd"] > 0,
            "upgrade_costs.option_03_cost_usd",
        ] = (
            MSHP_max_14_cost1
            + MSHP_max_14_cost2
            * up08["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )

        # Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF
        up08.loc[
            up08["upgrade_costs.option_05_cost_usd"] > 0,
            "upgrade_costs.option_05_cost_usd",
        ] = HPWH_50
        # Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF
        up08.loc[
            up08["upgrade_costs.option_06_cost_usd"] > 0,
            "upgrade_costs.option_06_cost_usd",
        ] = HPWH_66
        # Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF
        up08.loc[
            up08["upgrade_costs.option_07_cost_usd"] > 0,
            "upgrade_costs.option_07_cost_usd",
        ] = HPWH_80

        # Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 80% Usage
        up08.loc[
            up08["upgrade_costs.option_08_cost_usd"] > 0,
            "upgrade_costs.option_08_cost_usd",
        ] = dryer_HP
        # Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 100% Usage
        up08.loc[
            up08["upgrade_costs.option_09_cost_usd"] > 0,
            "upgrade_costs.option_09_cost_usd",
        ] = dryer_HP
        # Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 120% Usage
        up08.loc[
            up08["upgrade_costs.option_10_cost_usd"] > 0,
            "upgrade_costs.option_10_cost_usd",
        ] = dryer_HP

        # Cooking Range|Electric, Induction, 80% Usage
        up08.loc[
            up08["upgrade_costs.option_11_cost_usd"] > 0,
            "upgrade_costs.option_11_cost_usd",
        ] = induction_range
        # Cooking Range|Electric, Induction, 100% Usage
        up08.loc[
            up08["upgrade_costs.option_12_cost_usd"] > 0,
            "upgrade_costs.option_12_cost_usd",
        ] = induction_range
        # Cooking Range|Electric, Induction, 120% Usage
        up08.loc[
            up08["upgrade_costs.option_13_cost_usd"] > 0,
            "upgrade_costs.option_13_cost_usd",
        ] = induction_range

        # update total cost
        up08 = _update_total_upgrade_cost(up08)
        return up08

    ## -- data processing for up09 --
    def process_upgrade_09_costs(up09):
        # Insulate ceiling to R-30
        up09.loc[
            up09["upgrade_costs.option_01_cost_usd"] > 0,
            "upgrade_costs.option_01_cost_usd",
        ] = (
            r30_cost1
            * up09[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r30_cost2 * up09["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Insulate ceiling to R-49
        up09.loc[
            up09["upgrade_costs.option_02_cost_usd"] > 0,
            "upgrade_costs.option_02_cost_usd",
        ] = (
            r49_cost1
            * up09[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r49_cost2 * up09["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Insulate ceiling to R-60
        up09.loc[
            up09["upgrade_costs.option_03_cost_usd"] > 0,
            "upgrade_costs.option_03_cost_usd",
        ] = (
            r60_cost1
            * up09[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r60_cost2 * up09["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Reduce infiltration by 30%
        up09.loc[
            up09["upgrade_costs.option_04_cost_usd"] > 0,
            "upgrade_costs.option_04_cost_usd",
        ] = (
            reduce_infil_30_cost * up09["upgrade_costs.floor_area_conditioned_ft_2"]
        )
        # Insulate and seal ducts a lot to have 10% leakage and R-8 ducts
        up09.loc[
            up09["upgrade_costs.option_05_cost_usd"] > 0,
            "upgrade_costs.option_05_cost_usd",
        ] = (
            ducts1 * up09["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Seal ducts a lot to have 10% leakage, already has R-8 insulation
        up09.loc[
            up09["upgrade_costs.option_06_cost_usd"] > 0,
            "upgrade_costs.option_06_cost_usd",
        ] = (
            ducts2 * up09["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Insulate and seal ducts some to have 10% leakage and R-8 ducts
        up09.loc[
            up09["upgrade_costs.option_07_cost_usd"] > 0,
            "upgrade_costs.option_07_cost_usd",
        ] = (
            ducts3 * up09["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Seal ducts some to have 10% leakage, already has R-8 insulation
        up09.loc[
            up09["upgrade_costs.option_08_cost_usd"] > 0,
            "upgrade_costs.option_08_cost_usd",
        ] = (
            ducts4 * up09["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Only insulate ducts to R-8, no sealing
        up09.loc[
            up09["upgrade_costs.option_09_cost_usd"] > 0,
            "upgrade_costs.option_09_cost_usd",
        ] = (
            ducts5 * up09["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Insulation Wall|Wood Stud, R-13
        up09.loc[
            up09["upgrade_costs.option_10_cost_usd"] > 0,
            "upgrade_costs.option_10_cost_usd",
        ] = (
            wall_r13 * up09["upgrade_costs.wall_area_above_grade_conditioned_ft_2"]
        )

        # HVAC Heating Efficiency|MSHP, SEER 24, 13 HSPF
        up09.loc[
            up09["upgrade_costs.option_11_cost_usd"] > 0,
            "upgrade_costs.option_11_cost_usd",
        ] = (
            ducted_MSHP_cost1
            + ducted_MSHP_cost2
            * up09["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|MSHP, SEER 29.3, 14 HSPF, Max Load
        up09.loc[
            up09["upgrade_costs.option_13_cost_usd"] > 0,
            "upgrade_costs.option_13_cost_usd",
        ] = (
            MSHP_max_14_cost1
            + MSHP_max_14_cost2
            * up09["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )

        # Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF
        up09.loc[
            up09["upgrade_costs.option_15_cost_usd"] > 0,
            "upgrade_costs.option_15_cost_usd",
        ] = HPWH_50
        # Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF
        up09.loc[
            up09["upgrade_costs.option_16_cost_usd"] > 0,
            "upgrade_costs.option_16_cost_usd",
        ] = HPWH_66
        # Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF
        up09.loc[
            up09["upgrade_costs.option_17_cost_usd"] > 0,
            "upgrade_costs.option_17_cost_usd",
        ] = HPWH_80

        # Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 80% Usage
        up09.loc[
            up09["upgrade_costs.option_18_cost_usd"] > 0,
            "upgrade_costs.option_18_cost_usd",
        ] = dryer_HP
        # Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 100% Usage
        up09.loc[
            up09["upgrade_costs.option_19_cost_usd"] > 0,
            "upgrade_costs.option_19_cost_usd",
        ] = dryer_HP
        # Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 120% Usage
        up09.loc[
            up09["upgrade_costs.option_20_cost_usd"] > 0,
            "upgrade_costs.option_20_cost_usd",
        ] = dryer_HP

        # Cooking Range|Electric, Induction, 80% Usage
        up09.loc[
            up09["upgrade_costs.option_21_cost_usd"] > 0,
            "upgrade_costs.option_21_cost_usd",
        ] = induction_range
        # Cooking Range|Electric, Induction, 100% Usage
        up09.loc[
            up09["upgrade_costs.option_22_cost_usd"] > 0,
            "upgrade_costs.option_22_cost_usd",
        ] = induction_range
        # Cooking Range|Electric, Induction, 120% Usage
        up09.loc[
            up09["upgrade_costs.option_23_cost_usd"] > 0,
            "upgrade_costs.option_23_cost_usd",
        ] = induction_range

        # update total cost
        up09 = _update_total_upgrade_cost(up09)
        return up09

    ## -- data processing for up10 --
    def process_upgrade_10_costs(up10):
        # Insulate ceiling to R-30
        up10.loc[
            up10["upgrade_costs.option_01_cost_usd"] > 0,
            "upgrade_costs.option_01_cost_usd",
        ] = (
            r30_cost1
            * up10[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r30_cost2 * up10["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Insulate ceiling to R-49
        up10.loc[
            up10["upgrade_costs.option_02_cost_usd"] > 0,
            "upgrade_costs.option_02_cost_usd",
        ] = (
            r49_cost1
            * up10[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r49_cost2 * up10["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Insulate ceiling to R-60
        up10.loc[
            up10["upgrade_costs.option_03_cost_usd"] > 0,
            "upgrade_costs.option_03_cost_usd",
        ] = (
            r60_cost1
            * up10[
                "upgrade_costs.floor_area_attic_insulation_increase_ft_2_delta_r_value"
            ]
            + r60_cost2 * up10["upgrade_costs.floor_area_attic_ft_2"]
        )
        # Reduce infiltration by 30%
        up10.loc[
            up10["upgrade_costs.option_04_cost_usd"] > 0,
            "upgrade_costs.option_04_cost_usd",
        ] = (
            reduce_infil_30_cost * up10["upgrade_costs.floor_area_conditioned_ft_2"]
        )
        # Insulate and seal ducts a lot to have 10% leakage and R-8 ducts
        up10.loc[
            up10["upgrade_costs.option_05_cost_usd"] > 0,
            "upgrade_costs.option_05_cost_usd",
        ] = (
            ducts1 * up10["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Seal ducts a lot to have 10% leakage, already has R-8 insulation
        up10.loc[
            up10["upgrade_costs.option_06_cost_usd"] > 0,
            "upgrade_costs.option_06_cost_usd",
        ] = (
            ducts2 * up10["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Insulate and seal ducts some to have 10% leakage and R-8 ducts
        up10.loc[
            up10["upgrade_costs.option_07_cost_usd"] > 0,
            "upgrade_costs.option_07_cost_usd",
        ] = (
            ducts3 * up10["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Seal ducts some to have 10% leakage, already has R-8 insulation
        up10.loc[
            up10["upgrade_costs.option_08_cost_usd"] > 0,
            "upgrade_costs.option_08_cost_usd",
        ] = (
            ducts4 * up10["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Only insulate ducts to R-8, no sealing
        up10.loc[
            up10["upgrade_costs.option_09_cost_usd"] > 0,
            "upgrade_costs.option_09_cost_usd",
        ] = (
            ducts5 * up10["upgrade_costs.duct_unconditioned_surface_area_ft_2"]
        )
        # Insulation Wall|Wood Stud, R-13
        up10.loc[
            up10["upgrade_costs.option_10_cost_usd"] > 0,
            "upgrade_costs.option_10_cost_usd",
        ] = (
            wall_r13 * up10["upgrade_costs.wall_area_above_grade_conditioned_ft_2"]
        )

        # Insulate interior foundation wall to R-10
        up10.loc[
            up10["upgrade_costs.option_11_cost_usd"] > 0,
            "upgrade_costs.option_11_cost_usd",
        ] = (
            wall_foundation * up10["upgrade_costs.wall_area_below_grade_ft_2"]
        )
        # Geometry Foundation Type|Unvented Crawlspace
        up10.loc[
            up10["upgrade_costs.option_12_cost_usd"] > 0,
            "upgrade_costs.option_12_cost_usd",
        ] = (
            crawlspaces * up10["upgrade_costs.floor_area_foundation_ft_2"]
        )
        # Insulation Roof|Finished, R-30
        up10.loc[
            up10["upgrade_costs.option_13_cost_usd"] > 0,
            "upgrade_costs.option_13_cost_usd",
        ] = (
            roof * up10["upgrade_costs.roof_area_ft_2"]
        )

        # HVAC Heating Efficiency|MSHP, SEER 24, 13 HSPF
        up10.loc[
            up10["upgrade_costs.option_14_cost_usd"] > 0,
            "upgrade_costs.option_14_cost_usd",
        ] = (
            ducted_MSHP_cost1
            + ducted_MSHP_cost2
            * up10["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )
        # HVAC Heating Efficiency|MSHP, SEER 29.3, 14 HSPF, Max Load
        up10.loc[
            up10["upgrade_costs.option_16_cost_usd"] > 0,
            "upgrade_costs.option_16_cost_usd",
        ] = (
            MSHP_max_14_cost1
            + MSHP_max_14_cost2
            * up10["upgrade_costs.size_heating_system_primary_k_btu_h"]
        )

        # Water Heater Efficiency|Electric Heat Pump, 50 gal, 3.45 UEF
        up10.loc[
            up10["upgrade_costs.option_18_cost_usd"] > 0,
            "upgrade_costs.option_18_cost_usd",
        ] = HPWH_50
        # Water Heater Efficiency|Electric Heat Pump, 66 gal, 3.35 UEF
        up10.loc[
            up10["upgrade_costs.option_19_cost_usd"] > 0,
            "upgrade_costs.option_19_cost_usd",
        ] = HPWH_66
        # Water Heater Efficiency|Electric Heat Pump, 80 gal, 3.45 UEF
        up10.loc[
            up10["upgrade_costs.option_20_cost_usd"] > 0,
            "upgrade_costs.option_20_cost_usd",
        ] = HPWH_80

        # Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 80% Usage
        up10.loc[
            up10["upgrade_costs.option_21_cost_usd"] > 0,
            "upgrade_costs.option_21_cost_usd",
        ] = dryer_HP
        # Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 100% Usage
        up10.loc[
            up10["upgrade_costs.option_22_cost_usd"] > 0,
            "upgrade_costs.option_22_cost_usd",
        ] = dryer_HP
        # Clothes Dryer|Electric, Premium, Heat Pump, Ventless, 120% Usage
        up10.loc[
            up10["upgrade_costs.option_23_cost_usd"] > 0,
            "upgrade_costs.option_23_cost_usd",
        ] = dryer_HP

        # Cooking Range|Electric, Induction, 80% Usage
        up10.loc[
            up10["upgrade_costs.option_24_cost_usd"] > 0,
            "upgrade_costs.option_24_cost_usd",
        ] = induction_range
        # Cooking Range|Electric, Induction, 100% Usage
        up10.loc[
            up10["upgrade_costs.option_25_cost_usd"] > 0,
            "upgrade_costs.option_25_cost_usd",
        ] = induction_range
        # Cooking Range|Electric, Induction, 120% Usage
        up10.loc[
            up10["upgrade_costs.option_26_cost_usd"] > 0,
            "upgrade_costs.option_26_cost_usd",
        ] = induction_range

        # update total cost
        up10 = _update_total_upgrade_cost(up10)
        return up10

    ## -- [3] Apply processing --
    ext = ""
    if community_name is not None:
        ext = "__" + community_name.lower().replace(" ", "_")
        print(f"Processing data for [[ {community_name} ]] ...")

    for upn in range(11):
        process_upgrade_file(
            datadir / f"up{upn:02d}_sample.csv",
            outdir / f"up{upn:02d}{ext}.csv",
            upgrade_number=upn,
            use_multipliers_only=use_multipliers_only,
        )
    print(f"Output files exported to: {outdir}")


if __name__ == "__main__":
    default_cost_file = datadir / "cost_Sanjose.csv"

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "cost_file",
        nargs="?",
        default=default_cost_file,
        help=f"path of input cost file, defaults to {default_cost_file}",
    )
    parser.add_argument(
        "-c",
        "--community_name",
        action="store",
        default="San Jose",
        help="name of community, for adding extension to output file",
    )
    parser.add_argument(
        "-m",
        "--use_multipliers_only",
        action="store_true",
        help="whether to update upgrade costs by only adjusting EUSS default costs with local/inflation multipliers",
    )
    parser.add_argument(
        "-t",
        "--test",
        action="store_true",
        help="whether to use EUSS default costs (cost_test.csv) as input file for testing",
    )

    args = parser.parse_args()
    if args.test:
        cost_file = datadir / "cost_test.csv"
        community_name = "Test"
    else:
        cost_file = args.cost_file
        community_name = args.community_name

    process_euss_upgrade_files(
        cost_file,
        community_name=community_name,
        use_multipliers_only=args.use_multipliers_only,
    )
