# import packages
from pathlib import Path
import sys
import numpy as np
import pandas as pd
import csv
import re
import networkx as nx
import logging

from utils.sampling_probability import level_calc

def downselect_buildstock(bst_to_match, bst_to_search, HC_list, HC_fallback=None, n=1000, n_represented=1000, method=1):
    """ downselect buildings in bst_to_search based on bst_to_match 
    by matching the marginal for HC_to_match as much as possible

    If multiple matches are possible, a random draw takes place

    Args :
        bst_to_match : pd.DataFrame
            builstock to match to
        bst_to_search : pd.DataFrame
            buildstock or simulated results to search from
        HC_list : list(str)
            list of housing characteristics to match to (buildstock format), order-dependent
            formatted items in the list need to match columns in bst_to_match or bst_to_search
        HC_fallback : list(str) | None
            exclusive from HC_list, list of housing characteristics, usually geography, to coarsen
        n : int
            minimum size of weight_map to output
        method : int
            weight recalculation method to use: [1,2,3]
            

    Returns : 
        weight_map : a subset of bst_to_search based on matching criteria
    """
    ### Input processing 
    HC_check_additional = ["Vacancy Status", "Tenure", "Federal Poverty Level"]
    HC_check_additional_results = [f"build_existing_model.{x.lower().replace(' ','_')}" for x in HC_check_additional]
    HCM_all, HCMF, bst_to_match_type, _, bst_to_match = process_input(bst_to_match, HC_list+HC_check_additional, HC_fallback=HC_fallback)
    HCS_all, HCSF, bst_to_search_type, bldg_col_name, bst_to_search = process_input(bst_to_search, HC_list+HC_check_additional, HC_fallback=HC_fallback)

    HCM, HCS = HCM_all[:len(HC_list)], HCS_all[:len(HC_list)]

    if len(bst_to_match) >= n:
        logger.info(f"bst_to_match has {len(bst_to_match)} samples and over threshold n={n}, returning building_id and weight directly.")
        weight_map = _aggregate_weight(bst_to_match, [bldg_col_name], value_name="sample_weight", normalize=True)
        if n_represented is None:
            n_represented = len(weight_map)
        weight_map *= n_represented

        check_results(bst_to_match)
        for hc in HC_check_additional_results:
            check_results(bst_to_match, groupby_truth=hc)
        return weight_map.to_frame().reset_index()

    # QC
    assert len(bst_to_match) > 0, "bst_to_match is empty!"

    for hcm, hcs in zip([HCM, HCMF], [HCS, HCSF]):
        assert len(set(hcm)) == len(set(hcs)), f"Mismatch in length between HC(s) to match and to search\n{hcm} vs {hcs}"

        diff = set(hcm)-set(bst_to_match.columns)
        assert diff == set(), f"Unknown {len(diff)} HC(s) to match(s) found: {diff}"

        diff = set(hcs)-set(bst_to_search.columns)
        assert diff == set(), f"Unknown {len(diff)} HC(s) to search found: {diff}"


    logger.info(
        f"Creating n>={n} buildlstock by downsampling from: bst_to_search ({len(bst_to_search)} samples) \n"
        f"while matching the marginal distribution of {len(HC_list)} key HCs from: bst_to_match ({len(bst_to_match)} samples), \n"
        f"{HC_list}"
    )
    if HC_fallback is not None:
        logger.info(f"** Additionally, one HC from this fallback ordering will be used: \n{HC_fallback}")

    ## Process downsampling
    if HC_fallback is None:
        HC_to_match, HC_to_search = HCM, HCS
        n_valid, weight, bst_to_search, HC_to_search = apply_downsampling(bst_to_match, bst_to_search, HC_to_match, HC_to_search, n=n, method=method, 
            tree_search=True)
    else:
        N_valid, additional_tree_search = [], True
        i = 1
        for hcmf, hcsf, hcf in zip(HCMF, HCSF, HC_fallback):
            HC_to_match = [hcmf] + HCM
            HC_to_search = [hcsf] + HCS
            logger.info(f"For fallback HC {i}: {hcf}")
            n_valid, weight, bst_to_search_fb, _ = apply_downsampling(bst_to_match, bst_to_search, HC_to_match, HC_to_search, n=n, method=method, 
                tree_search=False)
            N_valid.append(n_valid)
            if n_valid >= n:
                logger.info(f"** Valid fallback HC: {HC_fallback[i-1]} **")
                bst_to_search = bst_to_search_fb # override
                del bst_to_search_fb
                additional_tree_search = False
                break
            i += 1

        if additional_tree_search:
            idxmax = np.argmax(N_valid)
            logger.info(f"** Best fallback HC: {HC_fallback[idxmax]}, relax HC_to_search by removing: {HCS[-1]} **")
            HC_to_match = [HCMF[idxmax]] + HCM[:-1] # proactively remove one
            HC_to_search = [HCSF[idxmax]] + HCS[:-1]
            n_valid, weight, bst_to_search, HC_to_search = apply_downsampling(bst_to_match, bst_to_search, HC_to_match, HC_to_search, n=n, method=method, 
                tree_search=True)

    ## Finalize weights and QC
    if n_represented is None:
        n_represented = len(weight)
    weight_map = step3_postprocess_weight(weight, bst_to_search, bldg_col_name, n_represented=n_represented)

    HC_to_match = HC_to_match[:len(HC_to_search)]
    check_marginals(bst_to_match, bst_to_search, weight_map, HC_to_match, HC_to_search, bldg_col_name)

    HC_search_unmatched = [x for x in HCS_all if x not in HC_to_search]
    if HC_search_unmatched:
        HC_match_unmatched = [x for x in HCM_all if x not in HC_to_match]
        logger.info("For unmatched HC:")
        check_marginals(bst_to_match, bst_to_search, weight_map, HC_match_unmatched, HC_search_unmatched, bldg_col_name)
    else:
        logger.info("No unmatched HC")

    if bst_to_match_type == "result" and bst_to_search_type == "result":
        bst_to_search = bst_to_search.join(weight_map.set_index(bldg_col_name), on=bldg_col_name, how="right")
        check_results(bst_to_match, df_matched=bst_to_search)

        for hc in HC_check_additional_results:
            check_results(bst_to_match, df_matched=bst_to_search, groupby_truth=hc, groupby_matched=hc)

    
    return weight_map.sort_values(by=bldg_col_name)


def process_input(bst, HC_list, HC_fallback=None):
    """ Format HC to match or search """
    global cols_to_check

    HC = []
    [HC.append(x) for x in HC_list if x not in HC] # remove dups
    HC_list = HC

    bst_type = "buildstock"
    bldg_col_name = "Building"
    if HC_fallback is None:
        HCF = []
    else:
        HCF = HC_fallback

    meta_cols = [col for col in bst.columns if col.startswith("build_existing_model.")]
    if len(meta_cols) > 0:
        HC = [f"build_existing_model.{x.lower().replace(' ', '_')}" for x in HC_list]
        bst_type = "result"
        bldg_col_name = "building_id"
        if HC_fallback is None:
            HCF = []
        else:
            HCF = [f"build_existing_model.{x.lower().replace(' ', '_')}" for x in HC_fallback]

        cols_to_check = [
            "report_simulation_output.energy_use_total_m_btu",
            "report_simulation_output.fuel_use_electricity_total_m_btu",
            "report_simulation_output.fuel_use_natural_gas_total_m_btu",
            "report_simulation_output.fuel_use_propane_total_m_btu",
            "report_simulation_output.fuel_use_fuel_oil_total_m_btu",
            # "report_simulation_output.fuel_use_coal_total_m_btu",
            # "report_simulation_output.fuel_use_wood_cord_total_m_btu",
            # "report_simulation_output.fuel_use_wood_pellets_total_m_btu",
        ]

    # bst = bst[[bldg_col_name]+meta_cols+cols_to_check]
    bst = bst[[bldg_col_name]+HC+HCF+cols_to_check]

    return HC, HCF, bst_type, bldg_col_name, bst


def step1_prefilter(bst_to_match, bst_to_search, HC_to_match, HC_to_search):
    cond = pd.Series(True, bst_to_search.index)
    for hcm, hcs in zip(HC_to_match, HC_to_search):
        cond &= bst_to_search[hcs].isin(bst_to_match[hcm].unique())

    bst_to_search = bst_to_search.loc[cond]
    n_valid = len(bst_to_search)
    return bst_to_search, n_valid

def step2_method3_downselection(bst_to_match, bst_to_search, HC_to_match, HC_to_search):
        ## Step 1: prefiltering - assign weights and downselect by removing weight=0 rows
        logger.info(f"\n -> Step 1 : Pre-filtering")
        weight_init = pd.Series(1, index=bst_to_search.index)
        for hcm, hcs in zip(HC_to_match, HC_to_search):
            weight_init *= modulate_weight(bst_to_match, bst_to_search, hcm, hcs)

        cond = weight_init>0
        # if cond.sum() == 0:
        #     logger.info("   Pre-filtering FAILED: Cannot downselect bst_to_search with positive weight")
        #     wt_matrix = []
        #     for hcm, hcs in zip(HC_to_match, HC_to_search):
        #         wt_matrix.append(modulate_weight(bst_to_match, bst_to_search, hcm, hcs).rename(hcm))
        #     wt_matrix = pd.concat(wt_matrix, axis=1)
        #     n_zero = wt_matrix[wt_matrix==0].replace(0,1).sum(axis=1)
        #     n_zero.value_counts()
        #     wt_matrix.loc[n_zero==1]
        #     wt_matrix.loc[666][wt_matrix.loc[666]==0]
        #     # idx = n_zero==0
        #     # wt_matrix.loc[idx].sum(axis=0)
        #     # (wt_matrix.loc[idx].div(wt_matrix.loc[idx].sum(axis=0), axis=1)).product(axis=1)
        #     logger.info("")
        #     breakpoint()
        bst_to_search = bst_to_search.loc[cond]
        n_valid = len(bst_to_search)
        return bst_to_search, n_valid

def step2_recalculate_weight(bst_to_match, bst_to_search, HC_to_match, HC_to_search, method=1):
    """ return weight as pd.Series, indexed by bst_to_search, may contain 0 or NA values """
    ## Step 2: weight recalculation - recalculate weight for downselection
    if method == 1:
        logger.info("\n -> Step 2 : Weight Recalculation\nMethod 1A - normalizing to exact joint-prob from bst_to_match ...")
        weight = calculate_weight_by_joint_probability(bst_to_match, bst_to_search, HC_to_match, HC_to_search, joint_prob_type="exact")

    if method == 2:
        logger.info("\n -> Step 2 : Weight Recalculation\nMethod 2 - normalizing to joint-prob based on product of individual marginals ...")
        weight = calculate_weight_by_joint_probability(bst_to_match, bst_to_search, HC_to_match, HC_to_search, joint_prob_type="product")

    if method == 3:
        logger.info("\n -> Step 2 : Weight Recalculation\nMethod 3 - normalizing to individual marginals one by one (not very good!) ... ")
        # weight = pd.Series(1, index=cond[cond].index)
        # for hcm, hcs in zip(HC_to_match, HC_to_search):
        #   weight *= modulate_weight(bst_to_match, bst_to_search.loc[cond], hcm, hcs)

        # bst_to_search, n_valid = step2_method3_downselection(bst_to_match, bst_to_search, HC_to_match, HC_to_search)

        wt_matrix = []
        for hcm, hcs in zip(HC_to_match, HC_to_search):
            wt_matrix.append(modulate_weight(bst_to_match, bst_to_search, hcm, hcs).rename(hcs+" wt"))

        wt = pd.concat([bst_to_search[bldg_col_name]+HC_to_search]+wt_matrix, axis=1).assign(sample_weight=1.0).set_index(HC_to_search)

        for hcs in HC_to_search:
            hcs_wt = hcs+" wt"
            wt["sample_weight"] *= wt[hcs_wt] / wt.groupby(hcs)["sample_weight"].sum()

        for hcm in HC_to_match:
            truth = bst_to_match[hcm].value_counts()
            _check_marginal(truth, wt.groupby(hcm)[hcm+" wt"].sum(), hcm)
            _check_marginal(truth, wt.groupby(hcm)["sample_weight"].sum(), hcm)

        weight = wt.reset_index()["sample_weight"]

    n_valid = (weight>0).sum()
    return n_valid, weight

def step3_postprocess_weight(weight, bst_to_search, bldg_col_name, n_represented=None):
    """ return pd.DataFrame contain building id col and sample_weight col """
    # Step 3: Finalize weight map by pairing them back to building_id and remove 0 or NA weighted rows
    if n_represented is None:
        n_represented = len(weight)
    logger.info(f"\n -> Step 3 : Weight Normalization")
    weight_map = pd.concat([bst_to_search[bldg_col_name], weight], axis=1).dropna()
    weight_map["sample_weight"] *= n_represented/weight_map["sample_weight"].sum() # normalize to n_rep
    return weight_map

def apply_downsampling(bst_to_match, bst_to_search, HC_to_match, HC_to_search, n=1000, method=1, tree_search=False):
    """ Process downsampling, return weight_map """
    n_valid, weight = 0, pd.Series(dtype=int)

    logger.info("")
    if not tree_search:
        # no while loop
        bst_to_search, n_valid = step1_prefilter(bst_to_match, bst_to_search, HC_to_match, HC_to_search)
        if n_valid < n:
            logger.INFO("   Pre-filtering FAILED with insufficient rows: "
                f"Located {n_valid} positively weighted rows in bst_to_search")
        else:
            logger.info(f"   Located {n_valid} positively weighted rows in bst_to_search")

        n_valid, weight = step2_recalculate_weight(bst_to_match, bst_to_search, HC_to_match, HC_to_search, method=method)
        if n_valid < n:
            logger.info(f"   Downsampling FAILED with insufficient rows: "
                    f"Recalculation leads to {n_valid} positively weighted samples")
        else:
            logger.info(f"\n\n** Downsampled to: {n_valid} samples")
            
        return n_valid, weight, bst_to_search, HC_to_search

    ## with tree_search : in a while-loop, remove one HC from HC_list until threshold n buildstock is achieved
    
    i = 1
    while n_valid < n:
        logger.info(f"\n---- Attempt {i}: downsample using {len(HC_to_search)} key HCs: ----")
        if not HC_to_search:
            logger.info("   Downsampling exhausted with empty HC_to_search")
            return n_valid, weight, bst_to_search, HC_to_search

        bst_to_search, n_valid = step1_prefilter(bst_to_match, bst_to_search, HC_to_match, HC_to_search)
        if n_valid < n:
            logger.info("   Pre-filtering FAILED with insufficient rows: "
                f"Located {n_valid} positively weighted rows in bst_to_search \n"
                f"retry by relaxing HC_to_search by removing: {HC_to_search[-i]}...")
            # update
            HC_to_search, HC_to_match = HC_to_search[:-1], HC_to_match[:-1]
            i += 1

        else:
            logger.info(f"   Located {n_valid} positively weighted rows in bst_to_search")
            n_valid, weight = step2_recalculate_weight(bst_to_match, bst_to_search, HC_to_match, HC_to_search, method=method)
            if n_valid >= n:
                logger.info(f"\n\n** Downsampled to: {n_valid} samples, by matching to: {HC_to_search}")
                return n_valid, weight, bst_to_search, HC_to_search
            logger.info(f"   Downsampling FAILED with insufficient rows: "
                f"Recalculation leads to {n_valid} positively weighted samples \n"
                f"retry by relaxing HC_to_search by removing: {HC_to_search[-1]}...")
            # update
            HC_to_search, HC_to_match = HC_to_search[:-1], HC_to_match[:-1]
            i += 1


def check_marginals(dfm, dfs, weight_map, HCM, HCS, bldg_col_name):
    """ Join by building_id """
    logger.info(f"Checking marginals from weight_map of n={len(weight_map)}...")
    df = dfs.set_index(bldg_col_name)
    for hcm, hcs in zip(HCM, HCS):
        truth = dfm[hcm].value_counts()
        matched = df[[hcs]].join(weight_map.set_index(bldg_col_name), how="right").groupby(hcs)["sample_weight"].sum()

        _check_marginal(truth, matched, hcm)
        

def check_results(df_truth, df_matched=None, groupby_truth=None, groupby_matched=None):
    cols_to_check_renamed = [x.split(".")[1] for x in cols_to_check]
    dft = df_truth.rename(columns=dict(zip(cols_to_check, cols_to_check_renamed)))

    if groupby_truth is not None:
        dft = dft.groupby(groupby_truth)
    truth = dft[cols_to_check_renamed].mean().sort_index()
    if groupby_truth is not None:
        truth = truth.unstack().swaplevel().sort_index()

    if df_matched is None:
        logger.info("truth = matched - per dwelling unit energy:" )
        logger.info(f"\n{truth} \n")
        return

    # if df_matched is not None
    df = df_matched.rename(columns=dict(zip(cols_to_check, cols_to_check_renamed)))
    df[cols_to_check_renamed] = df[cols_to_check_renamed].mul(df["sample_weight"], axis=0)
    if groupby_matched is not None:
        df = df.groupby(groupby_matched)
    matched = (df[cols_to_check_renamed].sum().div(df["sample_weight"].sum(), axis=0)).sort_index()
    if groupby_matched is not None:
        matched = matched.unstack().swaplevel().sort_index()

    pct_diff = round(((matched - truth) / truth)*100, 6)

    summary = pd.concat([matched.rename("matched"), truth.rename("truth"), pct_diff.rename("pct_diff")], axis=1)
    logger.info("truth vs. matched - per dwelling unit energy:" )
    logger.info(f"\n{summary}\n")


def _check_marginal(truth, matched, hc):
    """ 
    Args:
        truth: pd.Series
        matched: pd.Series
        hc: str
    """
    truth = (truth / truth.sum()).sort_index()
    matched = (matched / matched.sum()).sort_index()
    pct_diff = round(((matched - truth) / truth)*100, 6)

    summary = pd.concat([matched.rename("matched"), truth.rename("truth"), pct_diff.rename("pct_diff")], axis=1)
    logger.info(f" [[ {hc} ]] ")
    logger.info(f"\n{summary}\n")

def calculate_weight_by_joint_probability(dfm, dfs, HCM: list, HCS: list, joint_prob_type="exact"):
    """ Normalize the joint probability of housing characteristics (HC) list in df_to_search 
        based on prevalence of the equivalent HC list in df_to_match

    Args:
        dfm : pd.DataFrame
            dataframe to match to
        dfs : pd.DataFrame
            dataframe to search and calculate weight for
        HCM : list of str
            list of housing characteristics in dfm
        HCS : list of str
            list of housing characteristics in dfs
        joint_prob_type : str
            "exact" or "product"

    Returns:
        weight : pd.Series
        normalized weight of housing characteristic such that it sums to len(dfs), indexed to dfs
    """

    if joint_prob_type == "exact":
        wt_m = get_joint_probability_exact(dfm, HCM)
    elif joint_prob_type == "product":
        wt_m = get_joint_probability_as_product_of_marginals(dfm, HCM, dfs)
    else:
        raise ValueError(f"Unknown joint_prob_type={joint_prob_type}, valid: ['exact', 'product']")

    wt_s = get_joint_probability_exact(dfs, HCS)
    weight = renormalize_joint_probability(dfs, wt_s, wt_m)
    return weight

def get_joint_probability_as_product_of_marginals(df, HC: list, df_reference):
    """ Get joint probability of housing characteristics (HC) list as the product of marginal of each hc from dfm, 
    availability of hc combo informed by dfs

    Using downscaling

    returns:
        p_ref: pd.Series 
            joint prob normalized to 1
    """

    p_ref = df_reference[HC].drop_duplicates().assign(sample_weight=1.0).set_index(HC)["sample_weight"]

    PHC = []
    CHC = []
    for hc in HC:
        hc_weight = _aggregate_weight(df, hc, normalize=True)
        norm_weight = p_ref.groupby(hc).sum()

        # update
        p_ref *= hc_weight / norm_weight

    return p_ref


def get_joint_probability_exact(df, HC: list, normalize=True):
    return _aggregate_weight(df, HC, normalize=normalize)

def _aggregate_weight(df, groupby_columns, value_name="sample_weight", normalize=False):
    weight_col = [col for col in df.columns if "weight" in col]
    if len(weight_col) == 1:
        df = df.rename(columns=dict(zip(weight_col, ["sample_weight"])))
        df["sample_weight"] = df["sample_weight"].astype(float)
    elif len(weight_col) == 0:
        df = df.assign(sample_weight=1.0)
    else:
        raise keyError(f"df has more than one 'weight' columns: {weight_col}")
    df = df.groupby(groupby_columns)["sample_weight"].sum().rename(value_name)

    if normalize:
        return df / df.sum()

    return df

def renormalize_joint_probability(dfs, wt_s, wt_m):
    """ Utility function for normalizing dfs from the joint probability of wt_s to wt_m

    Args:
        dfs : pd.DataFrame
            dataframe to search and calculate weight for
        wt_s : pd.Series
            joint probability for dfs, index = HCS
        wt_m : pd.Series
            joint probability to normalize to

    Returns:
        weight : pd.Series
        normalized weight of housing characteristic such that it sums to len(dfs), indexed to dfs
    """

    # Validate and unify inputs
    assert set(wt_s.index.names) - set(dfs.columns) == set(), "wt_s has foreign keys not in dfs"
    assert len(wt_s.index.names) == len(wt_m.index.names), "wt_s does not have the same number of keys as wt_m"
    HC = wt_s.index.names
    wt_m.index.names = HC

    idx = wt_m.index
    if len(wt_m) > 0 and len(wt_s) > 0:
        if diff := list(set(wt_m.index)-set(wt_s.index)):
            logger.info(f"- WARNING: wt_m has {len(diff)} foreign keys not in wt_s for HC={HC}, removing those keys...")
            logger.info(f"    E.g., {diff[:min(5, len(diff))]}")
            idx = [x for x in idx if x not in diff]

    if len(idx) == 0:
        logger.info(f"No overlap in keys between wt_s and wt_m for HC={HC}")
        breakpoint()
        # raise KeyError(f"No overlap in keys between wt_s and wt_m for HC={HC}")


    # Normalize
    wt_new = wt_m.loc[idx] / wt_m.loc[idx].sum()
    wt_ori = wt_s.loc[idx] / wt_s.loc[idx].sum()

    wt_map = (wt_new / wt_ori).rename("sample_weight")
    
    weight = dfs.drop(columns=["sample_weight"]).join(wt_map, on=HC)["sample_weight"]
    weight = weight / weight.sum() * len(dfs) # normalize s.t. sum of weight = len(dfs)
    
    return weight


def modulate_weight(dfm, dfs, hcm: str, hcs: str, n_represented=None):
    """ Normalize housing characteristic (HC) in df_to_search based on prevalence of the HC in df_to_match

    Args:
        dfm : pd.DataFrame
            dataframe to match to
        dfs : pd.DataFrame
            dataframe to search and calculate weight for
        hcm : str
            name of housing characteristic in dfm
        hcs : str
            name of housing characteristic in dfs

    Returns:
        weight : pd.Series
        normalized weight of housing characteristic such that it sums to len(dfs), indexed to dfs
    """
    if n_represented is None:
        n_represented = len(dfs)
    df = dfm.copy()
    if diff := list(set(df[hcm].unique()) - set(dfs[hcs].unique())):
        logger.info(f"- WARNING: For hc={hcm}, dfm has {len(diff)} extra keys not in dfs, removing those keys...")
        logger.info(f"    E.g., {diff[:min(3, len(diff))]}")

        df = df.loc[~df[hcm].isin(diff)]
        logger.info(f"  Remaining {df[hcm].nunique()} keys: ")
        logger.info(f"    E.g., {df[hcm].unique()[:min(3, df[hcm].nunique())]}")

    wt_map = _aggregate_weight(df, hcm, normalize=True)
    denom = _aggregate_weight(dfs, hcs, normalize=False)

    denom = denom[wt_map.index]
    if len(denom[wt_map.index]) == 0:
        logger.info(f"No overlap in hc={hcm} keys between dfm and dfs: {wt_map.index} vs. {denom.index}")
        breakpoint()
        # raise KeyError(f"No overlap in hc={hcm} keys between dfm and dfs: {wt_map.index} vs. {denom.index}")
    
    weight = dfs[hcs].map(wt_map / denom).fillna(0)
    weight = (weight / weight.sum()) * n_represented # normalize such that after mapping, sum of weight = len(dfs)

    return weight


def modulate_weight_2(dfm, dfs, hcm: str, hcs: str):
    """ Normalize housing characteristic (HC) in df_to_search based on prevalence of the HC in df_to_match
    unused

    Args:
        dfm : pd.DataFrame
            dataframe to match to
        dfs : pd.DataFrame
            dataframe to search and calculate weight for
        hcm : str
            name of housing characteristic in dfm
        hcs : str
            name of housing characteristic in dfs

    Returns:
        weight : pd.Series
        normalized weight of housing characteristic such that it sums to len(dfs), indexed to dfs
    """
    if n_represented is None:
        n_represented = len(dfs)
    df = dfm.copy()
    if diff := list(set(df[hcm].unique()) - set(dfs[hcs].unique())):
        logger.info(f"- WARNING: For hc={hcm}, dfm has {len(diff)} extra keys not in dfs, removing those keys...")
        logger.info(f"    E.g., {diff[:min(3, len(diff))]}")

        df = df.loc[~df[hcm].isin(diff)]
        logger.info(f"  Remaining {df[hcm].nunique()} keys: ")
        logger.info(f"    E.g., {df[hcm].unique()[:min(3, df[hcm].nunique())]}")

    wt_map = df[hcm].value_counts().sort_index() / df[hcm].value_counts().sum() # normalized to 1
    denom = dfs[hcs].value_counts().sort_index()

    denom = denom[wt_map.index]
    if len(denom[wt_map.index]) == 0:
        logger.info(f"No overlap in hc={hcm} keys between dfm and dfs: {wt_map.index} vs. {denom.index}")
        breakpoint()
        # raise KeyError(f"No overlap in hc={hcm} keys between dfm and dfs: {wt_map.index} vs. {denom.index}")
    
    wt_map = wt_map / denom * n_represented # weight such that after mapping, sum of weight = n_rep
    weight = dfs[hcs].map(wt_map).fillna(0)

    assert round(weight.sum()) == n_represented, "sum of weight != n_rep"

    return weight

def setup_logging(
        name, filename, file_level=logging.INFO, console_level=logging.INFO
        ):
    global logger
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    fh = logging.FileHandler(filename, mode="w")
    fh.setLevel(file_level)
    ch = logging.StreamHandler()
    ch.setLevel(console_level)
    formatter = logging.Formatter(
        "%(asctime)s - %(levelname)s - %(message)s"
    )
    fh.setFormatter(formatter)
    ch.setFormatter(formatter)
    # add the handlers to the logger
    logger.addHandler(fh)
    logger.addHandler(ch)


# --- Main ---
datadir = Path(".").resolve() / "data_" / "downsampled_buildings_id"

"""
    "AHS Region", # CBSA
    "ASHRAE IECC Climate Zone 2004 - 2A Split",
    "ASHRAE IECC Climate Zone 2004", # 1A
    "Building America Climate Zone", # Hot-Humid 
    "CEC Climate Zone", # 1-16
    "Census Division RECS",
    "Census Division",
    "Census Region",
    "City",
    "County and PUMA",
    "County",
    "Generation And Emissions Assessment Region",
    "PUMA Metro Status",
    "PUMA",
    "State",
"""

ordered_geography = [
    # "County and PUMA",
    # "PUMA",
    # "County",
    "State",
    "Census Division RECS",
    "Census Division",
    "Census Region",
]
HC_fallback = None

key_HC = [
    "Income", #RECS 2020",
    "ASHRAE IECC Climate Zone 2004",
    "State",
    "Geometry Building Type RECS",
    "Heating Fuel",
    "HVAC Cooling Type",
    "Tenure",
     
    "Water Heater Fuel",
    "Vintage ACS", # ACS,
    "Geometry Floor Area Bin", # Bin
    "HVAC Heating Type",
    "Federal Poverty Level",
    "Vacancy Status",
]

## [0] setup input
communities = ["louisville", "san_jose", "columbia", "north_birmingham", "jackson_county", "duluth", "lawrence",] 
# excluding: "hill_district" as it has its own run
method = 1 # <--- TODO
n = 1000 # <----
# community = "hill_district" # <--- # 



## [1] define buildstock to search:
# EUSS buildstock
# buildstock_database = Path("/Users/lliu2/Documents/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_buildstock.csv")
# df_main = pd.read_csv(buildstock_database, dtype=str)
buildstock_database = Path("/Users/lliu2/Documents/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_2018_results_up00.parquet")
#buildstock_database = Path("data_/euss_res_final_2018_550k_20220901/results_up00.parquet")
df_main = pd.read_parquet(buildstock_database)

    ## [2] define buildstock to match:
    # 2.1. new buildstock
    # buildstock_to_match = Path("/Users/lliu2/Documents/GitHub/ResStock/euss_cleap/data/buildstock-duluth.csv")  # <---
    # df_match = pd.read_csv(buildstock_to_match, dtype=str)
    # buildstock_to_match = Path("/Users/lliu2/Documents/GitHub/ResStock/euss_cleap/data/results_up00-duluth-county.csv")  # <---
    # df_match = pd.read_csv(buildstock_to_match, low_memory=False)

for community in communities:
    # 2.1. hard down-selected EUSS buildstock
    # set up logger
    setup_logging(community, datadir / f"output__method{method}__{community}.log")

    if community == "duluth":
        df_match = df_main.loc[df_main["build_existing_model.puma"]=="MN, 00500"].reset_index(drop=True)
        n_represented = 39762 # TODO source?
    elif community == "hill_district":
        # Will have its own simulations
        df_match = df_main.loc[df_main["build_existing_model.puma"]=="PA, 01701"].reset_index(drop=True)
        n_represented = 100324 # 2020 count of PUMA
    elif community == "san_jose":
        # Use primary
        puma_dict = {
            "CA, 08510": 56747,
            "CA, 08514": 26404,

            # "CA, 08505": 0, # TODO secondary
            # "CA, 08506": 0, # TODO secondary
            # "CA, 08507": 0, # TODO secondary
            # "CA, 08508": 0, # TODO secondary
            # "CA, 08511": 0, # TODO secondary
            # "CA, 08512": 0, # TODO secondary
            # "CA, 08515": 0, # TODO secondary
            # "CA, 08516": 0, # TODO secondary
            # "CA, 08517": 0, # TODO secondary
            # "CA, 08518": 0, # TODO secondary
            # "CA, 08519": 0, # TODO secondary
            # "CA, 08520": 0, # TODO secondary
            # "CA, 08521": 0, # TODO secondary
            # "CA, 08522": 0, # TODO secondary
        }
        df_match = df_main.loc[df_main["build_existing_model.puma"].isin(puma_dict.keys())].reset_index(drop=True)
        n_represented = sum(puma_dict.values())
    elif community == "columbia":
        # Use primary PUMA
        # df_match = df_main.loc[df_main["build_existing_model.city"]=="SC, Columbia"].reset_index(drop=True)
        puma_dict = {
            "SC, 00604": 93698,

            # "SC, 00602": 61021, # secondary
            # "SC, 00603": 80063, # secondary
            # "SC, 00605": 50306, # secondary
        }
        df_match = df_main.loc[df_main["build_existing_model.puma"].isin(puma_dict.keys())].reset_index(drop=True)
        n_represented = sum(puma_dict.values())
    elif community == "north_birmingham":
        # TBD
        puma_dict = {
            "AL, 01302": 5154,
            "AL, 01304": 7291,
        }
        # df_match = df_main.loc[df_main["build_existing_model.county"]=="AL, Jefferson County"].reset_index(drop=True)
        # df_match = df_main.loc[df_main["build_existing_model.city"]=="AL, Birmingham"].reset_index(drop=True)
        df_match = df_main.loc[df_main["build_existing_model.puma"].isin(puma_dict.keys())].reset_index(drop=True)
        n_represented = sum(puma_dict.values()) # TODO (n_households: https://www.point2homes.com/US/Neighborhood/AL/Birmingham/North-Birmingham-Demographics.html)
    elif community == "louisville":
        # Use county
        # df_match = df_main.loc[df_main["build_existing_model.city"]=="KY, Louisville Jefferson County Metro Government Balance"].reset_index(drop=True)
        df_match = df_main.loc[df_main["build_existing_model.county"]=="KY, Jefferson County"].reset_index(drop=True)
        n_represented = 357900
    elif community == "jackson_county":
        df_match = df_main.loc[df_main["build_existing_model.county"]=="IL, Jackson County"].reset_index(drop=True)
        n_represented = 27723 # https://www.census.gov/quickfacts/jacksoncountyillinois
    elif community == "lawrence":
        df_match = df_main.loc[df_main["build_existing_model.county"]=="MA, Essex County"].reset_index(drop=True)
        n_represented = 31378 
    else:
        raise ValueError(f"unsupported community = {community}, "
            "valid: [duluth, san_jose, columbia, north_birmingham, louisville, jackson_county, lawrence]")

    if len(df_match) == 0:
        logger.info("df_match is empty!")
        breakpoint()

    logger.info("---------------------------------------------------------")
    logger.info(f"Downsampling buildstock for  {community}  using method {method}")
    logger.info("---------------------------------------------------------")
        

    # # Using HC graph
    # hc = "PUMA"
    # project_national_path = Path("/Users/lliu2/Documents/GitHub/ResStock/project_national/housing_characteristics")
    # graph = level_calc(project_national_path)
    # # HC = [hc] + sorted(nx.descendants(graph, hc))
    # HC = [hc] + list(graph.successors(hc))

    ## [3] downselect EUSS results
    dfd = downselect_buildstock(df_match, df_main, key_HC, HC_fallback=HC_fallback, n=n, n_represented=n_represented, method=method)

    ## [4] save to file
    output_file = datadir / ( # buildstock_database.parent
        buildstock_database.stem + f"__downsampled_method{method}__{community}" + ".csv"
    )
    dfd.to_csv(output_file, index=False)
    logger.info(f">> Database down-selected to {len(dfd)} buildings, based on input data of {len(df_match)} buildings, "
        f"result outputs to: \n{output_file}\n")


