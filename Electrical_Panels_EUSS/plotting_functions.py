import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import gaussian_kde


def plot_output(df, output_dir=None, sfd_only=False):
    print(f"Plots output to: {output_dir}")

    cond = df["completed_status"] == "Success"
    if sfd_only:
        cond &= df["build_existing_model.geometry_building_type_recs"]=="Single-Family Detached"
        print(f"Plotting applies to {len(df.loc[cond])} valid Single-Family Detached samples only")
    else:
        print(f"Plotting applies to {len(df.loc[cond])} valid samples only")

    metric = "std_m_nec_electrical_panel_amp"
    title = "NEC panel amperage - standard method"
    _plot_amperage_histogram(df, metric, title=title, output_dir=output_dir, sfd_only=sfd_only)

    metric = "opt_m_nec_electrical_panel_amp"
    title = "NEC panel amperage - optional method"
    _plot_amperage_histogram(df, metric, title=title, output_dir=output_dir, sfd_only=sfd_only)

    x_metric = "std_m_nec_electrical_panel_amp"
    y_metric = "opt_m_nec_electrical_panel_amp"
    title = "Standard vs. optional method"
    _plot_scatter(df, x_metric, y_metric, title=title, output_dir=output_dir, sfd_only=sfd_only)

    x_metric = "std_m_nec_electrical_panel_amp"
    y_metric = "peak_amp"
    title = "Standard method vs. simulated peak"
    _plot_scatter(df, x_metric, y_metric, title=title, output_dir=output_dir, sfd_only=sfd_only)

    x_metric = "opt_m_nec_electrical_panel_amp"
    y_metric = "peak_amp"
    title = "Optional method vs. simulated peak"
    _plot_scatter(df, x_metric, y_metric, title=title, output_dir=output_dir, sfd_only=sfd_only)


def plot_output_saturation(df, panel_metric, output_dir, sfd_only=False):
    print(f"Plots output to: {output_dir}")

    cond = df["completed_status"] == "Success"
    if sfd_only:
        cond &= df["build_existing_model.geometry_building_type_recs"]=="Single-Family Detached"
        print(f"Plotting applies to {len(df.loc[cond])} valid Single-Family Detached samples only")
    else:
        print(f"Plotting applies to {len(df.loc[cond])} valid samples only")

    _plot_bar(df, ["build_existing_model.census_region", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar(df, ["build_existing_model.federal_poverty_level", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar(df, ["build_existing_model.tenure", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar(df, ["build_existing_model.geometry_floor_area_bin", panel_metric], output_dir=output_dir, sfd_only=sfd_only)

    _plot_bar_stacked(df, ["build_existing_model.census_region", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.census_division", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.ashrae_iecc_climate_zone_2004", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.geometry_building_type_recs", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.vintage", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.federal_poverty_level", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.tenure", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.geometry_floor_area_bin", panel_metric], output_dir=output_dir, sfd_only=sfd_only)
    _plot_bar_stacked(df, ["build_existing_model.geometry_floor_area", panel_metric], output_dir=output_dir, sfd_only=sfd_only)


def _plot_amperage_histogram(df, metric, title=None, output_dir=None, sfd_only=False):
    if sfd_only:
        cond = df["build_existing_model.geometry_building_type_recs"]=="Single-Family Detached"
        panel_sizes = df.loc[cond, metric].to_list()
    else:
        panel_sizes = df[metric].to_list()

    fig, ax = plt.subplots()
    bars = ax.bar(*np.unique(panel_sizes, return_counts = True), width = 10)
    ax.set_xlabel('Capacity of Panel (A)')
    ax.set_ylabel('Count of Panels')

    for bar in bars:
        h = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2.0, h,
                f"{h:.0f}", ha="center", va="bottom")

    if title is not None:
        ax.set_title(title)
    if output_dir is not None:
        fig.savefig(output_dir / f"histogram_{metric}.png", dpi=400, bbox_inches="tight")

def _plot_scatter(df, x_metric, y_metric, title=None, output_dir=None, sfd_only=False):
    if sfd_only:
        cond = df["build_existing_model.geometry_building_type_recs"]=="Single-Family Detached"
        df = df.loc[cond, [x_metric, y_metric]].dropna(how="any")
    else:
        df = df[[x_metric, y_metric]].dropna(how="any")

    x, y = df[x_metric], df[y_metric]

    fig, ax = plt.subplots()
    # point density (can be very time intensive)
    if len(x)<= 100000:
        xy = np.vstack([x,y])
        z = gaussian_kde(xy)(xy)
        ax.scatter(x, y, c=z)
    else:
        ax.scatter(x, y)
    ax.set_xlabel(x_metric)
    ax.set_ylabel(y_metric)

    # y=x line
    lxy = np.array([
        min(x.min(), y.min()), 
        max(x.max(), y.max())
        ])
    ax.plot(lxy, lxy, ls="-", c="gray")

    # calculate % above and at or below x=y
    frac = y/x
    frac_above = len(frac[frac>1]) / len(frac)
    frac_at_below = 1-frac_above
    ax.text(0.05, 0.95, f"above line:\n{frac_above*100:.1f}%", ha="left", va="top", transform = ax.transAxes)
    ax.text(0.95, 0.05, f"at/below line:\n{frac_at_below*100:.1f}%", ha="right", va="bottom", transform = ax.transAxes)

    title_ext = f"(n = {len(x)})"
    if title is not None:
        title += f" {title_ext}"
    else:
        title = title_ext
    ax.set_title(title)
    if output_dir is not None:
        fig.savefig(output_dir / f"scatter_{y_metric}_by_{x_metric}.png", dpi=400, bbox_inches="tight")


def _plot_bar(df, groupby_cols, output_dir=None, sfd_only=False):
    if sfd_only:
        cond = df["build_existing_model.geometry_building_type_recs"]=="Single-Family Detached"
        dfi = df.loc[cond, groupby_cols+["building_id"]]
    else:
         dfi = df[groupby_cols+["building_id"]]
    dfi = dfi.groupby(groupby_cols)["building_id"].count().unstack()

    fig, ax = plt.subplots()
    sort_index(dfi, axis=0).plot(kind="bar", ax=ax)
    if output_dir is not None:
        metric = "__by__".join(groupby_cols)
        fig.savefig(output_dir / f"bar_{metric}.png", dpi=400, bbox_inches="tight")

def _plot_bar_stacked(df, groupby_cols, output_dir=None, sfd_only=False):
    if sfd_only:
        cond = df["build_existing_model.geometry_building_type_recs"]=="Single-Family Detached"
        dfi = df.loc[cond, groupby_cols+["building_id"]]
    else:
         dfi = df[groupby_cols+["building_id"]]
    dfi = dfi.groupby(groupby_cols)["building_id"].count().unstack()
    dfi = dfi.divide(dfi.sum(axis=1), axis=0)

    fig, ax = plt.subplots()
    sort_index(dfi, axis=0).plot(kind="bar", stacked=True, ax=ax)
    ax.legend(loc='center left', bbox_to_anchor=(1, 0.5))
    ax.set_title(f"Saturation of {groupby_cols[-1]}")
    if output_dir is not None:
        metric = "__by__".join(groupby_cols)
        fig.savefig(output_dir / f"stacked_bar_{metric}.png", dpi=400, bbox_inches="tight")

def extract_left_edge(val):
    # for sorting things like AMI
    if val is None:
        return np.nan
    if not isinstance(val, str):
        return val
    first = val[0]
    if re.search(r"\d", val) or first in ["<", ">"] or first.isdigit():
        vals = [int(x) for x in re.split("\-|\%|\<|\+|\>|s|th|p|A|B|C| ACH50", val) if re.match("\d", x)]
        if len(vals) > 0:
            num = vals[0]
            if "<" in val:
                num -= 1
            if ">" in val:
                num += 1
            return num
    return val

def sort_index(df, axis="index", **kwargs):
    """ axis: ['index', 'columns'] """
    if axis in [0, "index"]:
        return df.reindex(sorted(df.index, key=extract_left_edge, **kwargs))
    if axis in [1, "columns"]:
        col_index_name = df.columns.name
        cols = sorted(df.columns, key=extract_left_edge, **kwargs)
        df = df[cols]
        df.columns.name = col_index_name
        return df
    raise ValueError(f"axis={axis} is invalid")
        