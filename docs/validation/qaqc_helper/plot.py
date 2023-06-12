import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from itertools import cycle, product

from . import utils
from .utils import (
    MBTU_TO_THERM,
    KBTU_TO_THERM,
    MBTU_TO_KWH,
    KBTU_TO_KWH,
    KBTU_TO_MBTU,
    MBTU_TO_TBTU,
    KWH_TO_MWH,
    KWH_TO_GWH,
)

enduse_category_dict = utils.end_use_category_dictionary()

### [5] plot funcs
# [5.1]
def plot_histogram_total(
    dfb, DFU, metric, hc, nbins, xmax="best", dashline_bounds="p95"
):
    """
    For plotting histogram with hard coded logic for dfb and DFU
    subplot based on:
    - column given by unique field of hc
    - row given by baseline (dfb) + upgrade (DFU)
    """
    if dashline_bounds not in ["95%CI", "IQR", "p95", None]:
        raise ValueError(
            f'Unsupported dashline_bounds={dashline_bounds}, valid options: ["95%CI", "IQR", "p95", None]'
        )
    try:
        hc_values = sorted(dfb[hc].unique(), key=utils.extract_left_edge)
    except TypeError:
        hc_values = sorted(dfb[hc].unique())
    ncols = dfb[hc].nunique()
    nrows = len(DFU) + 1
    fig, axes = plt.subplots(
        nrows, ncols, sharex=True, sharey=True, figsize=(ncols * 2, nrows * 1.25)
    )

    upgs = list(DFU.keys())
    dfs = list(DFU.values())

    factor, new_metric = utils.get_conversion_factor(metric)
    new_hc = hc
    if "." in hc:
        new_hc = hc.split(".")[-1]

    prop_cycle = plt.rcParams["axes.prop_cycle"]
    colors = cycle(prop_cycle.by_key()["color"])
    avg_vals, lb_vals, ub_vals = [], [], []
    for i in range(ncols):
        cond = dfb[hc] == hc_values[i]
        ax = axes[0, i]
        data = dfb.loc[cond, metric].dropna() * factor

        ndata = len(data)
        data = data.replace([np.inf, -np.inf], np.nan).dropna()
        if ndata > len(data):
            print(f"{ndata-len(data)} infinite value(s) found for {hc}=={hc_values[i]}")

        ax.hist(data, bins=nbins, color=next(colors))

        avg_vals.append(data.mean())
        if dashline_bounds == "IQR":
            lb_vals.append(data.quantile(0.25))
            ub_vals.append(data.quantile(0.75))
        elif dashline_bounds == "p95":
            lb_vals.append(data.quantile(0.05))
            ub_vals.append(data.quantile(0.95))
        elif dashline_bounds == "95%CI":
            lb, ub = utils.get_95_confidence_interval(data)
            lb_vals.append(lb)
            ub_vals.append(ub)

        ax.set_title(hc_values[i])
        if i == ncols - 1:
            ax.legend(["baseline"], loc="center left", bbox_to_anchor=(1, 0.5))

        for j in range(1, nrows):
            ax = axes[j, i]
            data = dfs[j - 1].loc[cond, metric] * factor
            data = data.replace([np.inf, -np.inf], np.nan).dropna()
            ax.hist(data, bins=nbins, color=next(colors))
            avg_vals.append(data.mean())
            if dashline_bounds == "IQR":
                lb_vals.append(data.quantile(0.25))
                ub_vals.append(data.quantile(0.75))
            elif dashline_bounds == "p95":
                lb_vals.append(data.quantile(0.05))
                ub_vals.append(data.quantile(0.95))
            elif dashline_bounds == "95%CI":
                lb, ub = utils.get_95_confidence_interval(data)
                lb_vals.append(lb)
                ub_vals.append(ub)

            if i == ncols - 1:
                ax.legend([upgs[j - 1]], loc="center left", bbox_to_anchor=(1, 0.5))

    if xmax == "best":
        # set xmax based on smaller of max or upper bound of 1.5*IQR of baseline, and larger of that or P95
        p75 = dfb[metric].quantile(0.75)
        p25 = dfb[metric].quantile(0.25)
        p95 = dfb[metric].quantile(0.95)
        p100 = dfb[metric].max()
        iqr150 = p75 + (p75 - p25) * 1.5
        xmax = max(min(iqr150, p100), p95) * factor
        ax.set_xlim(xmax=xmax)

    xmax = ax.get_xlim()[1]
    ymax = ax.get_ylim()[1]

    k = 0
    for i in range(ncols):
        for j in range(nrows):
            avg = avg_vals[k]
            ax = axes[j, i]
            if avg is not np.nan:
                ax.axvline(avg, color="k")
                ax.text(avg + xmax * 0.05, ymax * 0.7, f"{avg:.1f}")

            if dashline_bounds is not None and lb_vals[k] is not np.nan:
                ax.axvline(lb_vals[k], color="gray", ls="--")
                ax.axvline(ub_vals[k], color="gray", ls="--")

            k += 1

    fig.suptitle(f"{new_metric} by {new_hc}", fontsize=18, y=0.95)


# [5.2]
def plot_histogram_saving(
    df,
    value_col: str,
    by_cols: list,
    non_zero=False,
    title_prefix=None,
    xlim="best",
    dashline_bounds="p95",
    **kwargs,
):
    """Specifically for histogram of upgrade savings (i.e., without baseline) or histogram for a dataframe's metric
    subplot based on:
    - column given by by_cols
    - row given by upgrade package in df

    xlim : "best" | None | tuple
    """
    if title_prefix is None:
        title_prefix = ""
    else:
        title_prefix = f"{title_prefix.title()} "

    if len(by_cols) not in [1, 2]:
        raise ValueError(
            f"Invalid number of by_cols={by_cols}, can only support up to 2"
        )

    if dashline_bounds not in ["95%CI", "IQR", "p95", None]:
        raise ValueError(
            f'Unsupported dashline_bounds={dashline_bounds}, valid options: ["95%CI", "IQR", "p95", None]'
        )

    factor, new_value_col = utils.get_conversion_factor(value_col)
    df[value_col] *= factor

    if xlim == "best":
        # set xmax based on smaller of max or upper bound of 1.5*IQR of baseline, and larger of that or P95
        # equivalent for xmin
        p0 = df[value_col].min()
        p5 = df[value_col].quantile(0.05)
        p25 = df[value_col].quantile(0.25)
        p75 = df[value_col].quantile(0.75)
        p95 = df[value_col].quantile(0.95)
        p100 = df[value_col].max()
        xmin = min(max((p25 - (p75 - p25) * 1.5), p0), p5)
        xmax = max(min((p75 + (p75 - p25) * 1.5), p100), p95)
    elif xlim is not None:
        (xmin, xmax) = xlim

    ext = ""
    if non_zero:
        df = df[df[value_col] > 0].reset_index()
        ext = " (non-zero)"

    title = f"{title_prefix}{new_value_col}{ext}"
    if len(by_cols) == 1:
        nrows = df[by_cols[0]].nunique()
        ncols = 1
    elif len(by_cols) == 2:
        ncols = 1
        for i, col in enumerate(by_cols):
            if i == 0:
                nrows = df[col].nunique()
            else:
                ncols *= df[col].nunique()

    df = (
        (df.set_index([df.index] + by_cols)[value_col])
        .unstack(level=by_cols)
        .dropna(how="all", axis=0)
    )
    try:
        cols = sorted(df.columns, key=utils.extract_left_edge)
    except TypeError:
        cols = sorted(df.columns)
    axes = df[cols].plot(
        kind="hist",
        subplots=True,
        sharex=True,
        sharey=True,
        legend=False,
        layout=(nrows, ncols),
        figsize=(min(ncols * 1.5 + 2, 12), min(nrows + 1, 18)),
        **kwargs,
    )

    axes = axes.flat
    if xlim is not None:
        axes[0].set_xlim(xmin=xmin, xmax=xmax)
    xmax = axes[0].get_xlim()[1]
    ymax = axes[0].get_ylim()[1]
    if len(by_cols) == 2:
        for i, ax in enumerate(axes):
            data = df[cols[i]].dropna()
            ndata = len(data)
            data = data.replace([np.inf, -np.inf], np.nan).dropna()
            if ndata > len(data):
                print(f"{ndata-len(data)} infinite value(s) found for {cols[i]}")

            # draw average line
            avg = data.mean()
            if avg is not np.nan:
                ax.axvline(avg, color="k")
                ax.text(avg + xmax * 0.05, ymax * 0.7, f"{avg:.1f}")

            # draw dashline for bounds
            if data.quantile(0.25) is not np.nan:
                if dashline_bounds == "IQR":
                    ax.axvline(data.quantile(0.25), color="gray", ls="--")
                    ax.axvline(data.quantile(0.75), color="gray", ls="--")
                elif dashline_bounds == "p95":
                    ax.axvline(data.quantile(0.05), color="gray", ls="--")
                    ax.axvline(data.quantile(0.95), color="gray", ls="--")
                elif dashline_bounds == "95%CI":
                    lb, ub = utils.get_95_confidence_interval(data)
                    ax.axvline(lb, color="gray", ls="--")
                    ax.axvline(ub, color="gray", ls="--")

            row_index = i // ncols
            col_index = i % ncols
            if row_index == 0:
                ax.set_title(cols[i][1:])
            if col_index == ncols - 1:
                h, _ = ax.get_legend_handles_labels()
                ax.legend(
                    h,
                    [cols[i][0]],
                    loc="center left",
                    bbox_to_anchor=(1.01, 0.5),
                    frameon=False,
                )

    fig = axes[0].get_figure()
    fig.suptitle(title, fontsize=18, y=0.95)
    # fig.tight_layout()


# [5.3]
def plot_aggregated_metric(
    df2,
    groupby_cols: list,
    value_col: str,
    operation="mean",
    weight_col=None,
    non_zero=False,
    unstack_level=0,
    title_suffix=None,
    **kwargs,
):
    """
    Bar plot of metric by groupby_cols, no subplot
    non_zero: if True, only non-zero values are aggregated
    """

    n_combo = len(df2[groupby_cols].drop_duplicates())

    if non_zero:
        df = df2.loc[df2[value_col] > 0]
        ext = " (non-zero)"
    else:
        df = df2.copy()
        ext = ""

    if title_suffix is None:
        ext += ""
    else:
        ext += f" {title_suffix}"

    if weight_col is not None:
        df[value_col] *= df[weight_col]

    if operation == "mean":
        df = df.groupby(groupby_cols)[value_col].mean()
        btype = "avg customer"
    elif operation == "sum":
        df = df.groupby(groupby_cols)[value_col].sum()
        btype = "all customer (unweighted)"
        if weight_col is not None:
            btype = "all customer"
    elif operation == "min":
        df = df.groupby(groupby_cols)[value_col].min()
        btype = "smallest consumer"
    elif operation == "max":
        df = df.groupby(groupby_cols)[value_col].max()
        btype = "largest consumer"
    elif operation == "count":
        df = df.groupby(groupby_cols)[value_col].count()
        btype = "count of samples"
    else:
        raise ValueError(f"operation={operation} not supported")

    df = df.unstack(level=unstack_level)
    cols = df.columns
    try:
        cols = sorted(cols, key=utils.extract_left_edge)
    except TypeError:
        cols = sorted(cols)
    cols_name = df.columns.name
    df = utils.sort_index(df[cols])

    f = plt.figure(figsize=(n_combo * 0.13 + 1.5, 4))
    df.plot(kind="bar", title=f"{value_col} - \n{btype}{ext}", ax=f.gca(), **kwargs)
    plt.legend(loc="center left", title=cols_name, bbox_to_anchor=(1.0, 0.5))


# [5.4]
def plot_scatter(
    dfs, xmetric, ymetric, plot_row_by: str, plot_column_by: str, groupby_cols: list
):
    """scatter plot with xmetric and ymetric, subplot based on plot_row_by and plot_column_by"""

    xlabel = xmetric.split(".")[-1] if "." in xmetric else xmetric
    ylabel = ymetric.split(".")[-1] if "." in ymetric else ymetric

    try:
        groupby_vals = [
            sorted(dfs[col].unique(), key=utils.extract_left_edge)
            for col in groupby_cols
        ]
    except TypeError:
        groupby_vals = [sorted(dfs[col].unique()) for col in groupby_cols]

    groupby_combos = [vals for vals in product(*groupby_vals)]
    nrows, ncols = dfs[plot_row_by].nunique(), dfs[plot_column_by].nunique()

    prop_cycle = plt.rcParams["axes.prop_cycle"]

    fig, axes = plt.subplots(
        nrows, ncols, sharex=True, sharey=True, figsize=(ncols * 3 + 2, nrows * 3)
    )
    for i, upg in enumerate(dfs[plot_row_by].unique()):
        for j, dac in enumerate(dfs[plot_column_by].unique()):
            ax = axes[i, j]
            colors = cycle(prop_cycle.by_key()["color"])
            for vals in groupby_combos:
                dfi = dfs.loc[(dfs[plot_row_by] == upg) & (dfs[plot_column_by] == dac)]
                for k in range(len(groupby_cols)):
                    dfi = dfi.loc[dfi[groupby_cols[k]] == vals[k]]
                label = vals[0] if len(vals) == 1 else vals
                ax.scatter(
                    x=dfi[xmetric],
                    y=dfi[ymetric],
                    c=next(colors),
                    alpha=0.25,
                    label=label,
                )
            ax.axhline(0, color="k", ls="--")
            ax.axvline(0, color="k", ls="--")
            if i == nrows - 1:
                ax.set_xlabel(xlabel)
            if j == 0:
                ax.set_ylabel(ylabel)
            if j == ncols - 1:
                ax.legend(title=upg, loc="center left", bbox_to_anchor=(1, 0.5))
            ax.set_title(dac)


### [6] Stacked end use plots
# [6.1] - normalized
def plot_normalized_stacked_end_uses(dfb, fuel="all fuels"):
    """Single column stacked bar plot, stacking by the end use of a given fuel"""
    fuels = [fuel]
    if fuel == "all fuels":
        fuels = [
            "electricity",
            "natural_gas",
            "propane",
            "fuel_oil",
            "wood_cord",
            "wood_pellets",
            "coal",
        ]
    enduse_cols, mapped_cols = [], []
    for fu in fuels:
        eu_cols = [col for col in dfb.columns if f"end_use_{fu}" in col]
        enduse_cols += eu_cols
        mapped_cols += [
            enduse_category_dict[
                col.removeprefix(
                    f"report_simulation_output.end_use_{fu}_"
                ).removesuffix("_m_btu")
            ]
            for col in eu_cols
        ]

    df = (
        dfb[enduse_cols]
        .rename(columns=dict(zip(enduse_cols, mapped_cols)))
        .groupby(level=0, axis=1)
        .sum()
    )

    cols = sorted(set(mapped_cols))
    data = df[cols].sum(axis=0)
    data = (data / data.sum()).rename(fuel)  # normalize

    ax = data.to_frame().stack().unstack(level=0).plot(kind="bar", stacked=True)
    h, l = ax.get_legend_handles_labels()
    labels = [f"{k} ({v*100:.01f}%)" for k, v in data.to_dict().items()]
    ax.legend(
        h[::-1],
        labels[::-1],
        loc="center left",
        bbox_to_anchor=(1, 0.5),
        title="End uses: ",
    )


# [6.2] - normalized
def plot_normalized_stacked_end_uses_by_fuel(dfb):
    """Multiple column stacked bar plot, stacking by end use, column by fuel"""
    DF = []
    fuels = [
        "coal",
        "electricity",
        "fuel_oil",
        "natural_gas",
        "propane",
        "wood_cord",
        "wood_pellets",
    ]
    for fuel in fuels:
        enduse_cols = [col for col in dfb.columns if f"end_use_{fuel}" in col]
        mapped_cols = [
            enduse_category_dict[
                col.removeprefix(
                    f"report_simulation_output.end_use_{fuel}_"
                ).removesuffix("_m_btu")
            ]
            for col in enduse_cols
        ]

        df = (
            dfb[enduse_cols]
            .rename(columns=dict(zip(enduse_cols, mapped_cols)))
            .groupby(level=0, axis=1)
            .sum()
        )

        cols = sorted(set(mapped_cols))
        data = df[cols].sum(axis=0)
        data = data.rename(fuel)
        DF.append(data)

    DF = pd.concat(DF, axis=1).sort_index(axis=0)
    DF["total"] = DF[DF.columns].fillna(0).sum(axis=1)
    DF /= DF.sum(axis=0)  # normalize

    # plot
    ax = DF.transpose().dropna(how="all", axis=0).plot(kind="bar", stacked=True)

    h, l = ax.get_legend_handles_labels()
    labels = [f"{k} ({v*100:.01f}%)" for k, v in DF["total"].to_dict().items()]
    ax.legend(
        h[::-1],
        labels[::-1],
        loc="center left",
        bbox_to_anchor=(1, 0.5),
        title="End uses (total fuel saturation)",
    )


# [6.3] - normalized
def plot_normalized_stacked_fuel_uses(dfb, n_represented="auto"):
    """Single column stacked bar plot, stacking by fuel use"""
    fuels = [
        "electricity",
        "natural_gas",
        "propane",
        "fuel_oil",
        "wood_cord",
        "wood_pellets",
        "coal",
    ]

    fuel_cols = sorted(
        [f"report_simulation_output.fuel_use_{fuel}_total_m_btu" for fuel in fuels]
    )

    n_customers = dfb["build_existing_model.sample_weight"].sum()
    data = (dfb[fuel_cols].mul(dfb["build_existing_model.sample_weight"], axis=0)).sum(
        axis=0
    )

    if n_represented != "auto":
        data *= n_represented / n_customers
        n_customers = n_represented

    data = data.rename(
        lambda x: x.removeprefix("report_simulation_output.fuel_use_").removesuffix(
            "_total_m_btu"
        ),
        axis=0,
    ).rename("Fuel Use")

    # to Trillion Btu
    data *= MBTU_TO_TBTU
    data_frac = data / data.sum()  # normalize

    ax = data.to_frame().stack().unstack(level=0).plot(kind="bar", stacked=True)
    h, l = ax.get_legend_handles_labels()
    labels = [f"{k} ({v*100:.01f}%)" for k, v in data_frac.to_dict().items()]
    ax.legend(
        h[::-1],
        labels[::-1],
        loc="center left",
        bbox_to_anchor=(1, 0.5),
        title="End uses: ",
    )
    ax.set_ylabel("trillion Btu")
    ax.set_title(
        f"Total fuel: {data.sum():.0f} trillion btu from {round(n_customers, 0):.0f} customers"
    )


# [6.4] - total stock monthly stacked end use plot
def plot_monthly_total_stacked_end_uses(df_monthly, fuel, n_represented="auto"):
    """Multiple column stacked bar plot, stacking by end use, column by month, down-selected to fuel"""
    end_uses = sorted([col for col in df_monthly.columns if fuel in col])
    data = df_monthly.set_index("month")[end_uses]

    if n_represented == "auto":
        n = df_monthly["n_represented"].apply(round).unique()
        assert len(n) == 1, n
        n_represented = n[0]
    else:
        data = (
            data.div(df_monthly.set_index("month")["n_represented"], axis=0)
            * n_represented
        )

    ax = data.plot(kind="bar", stacked=True)
    h, l = ax.get_legend_handles_labels()
    labels = [eu.split("__")[1] for eu in l]
    unit = end_uses[0].split("__")[-1]
    ax.legend(h[::-1], labels[::-1], loc="center left", bbox_to_anchor=(1, 0.5))
    ax.set_ylabel(unit)
    ax.set_title(f"Total Stock {fuel.title()} (n={n_represented})")


# [6.5] - total stock or per unit diurnal stacked end use plot
def plot_seasonal_diurnal_end_uses(
    df_ts, fuel, stock_total=False, n_represented="auto"
):
    """Subplots of multiple column stacked bar plot, stacking by end use, column by hour,
    subplot by season and week day type, down-selected to fuel
    """
    end_uses = sorted([col for col in df_ts.columns if fuel in col])
    unit = end_uses[0].split("__")[-1]

    fig, axes = plt.subplots(nrows=3, ncols=2, sharex=True, sharey=True)
    for j, season in enumerate(["summer", "winter", "shoulder"]):
        for i, day_type in enumerate(["weekday", "weekend"]):
            cond = df_ts["season"] == season
            cond &= df_ts["day_type"] == day_type
            data = df_ts.loc[cond].groupby(["hour"])

            # auto-stock total
            data_plot = data[end_uses].sum().div(data["n_hours"].sum(), axis=0)
            n_customers = data["n_represented"].mean().apply(round).unique()
            assert len(n_customers) == 1, n_customers
            n_customers = n_customers[0]

            if stock_total and n_represented != "auto":
                # renormalized to input n_represented
                data_plot = (
                    data_plot.div(data["n_represented"].mean(), axis=0) * n_represented
                )
                n_customers = n_represented
            elif not stock_total:
                # per dwelling unit
                data_plot = data_plot.div(data["n_represented"].mean(), axis=0)

            ax = axes[j, i]
            data_plot.plot(
                ax=ax, kind="area", stacked=True, legend=False, figsize=(8, 8)
            )
            ax.margins(x=0)
            ax.set_ylabel(unit)
            ax.set_title(f"{season} - {day_type}")

    h, l = ax.get_legend_handles_labels()
    h, l = ax.get_legend_handles_labels()
    labels = [eu.split("__")[1] for eu in l]

    fig.legend(h[::-1], labels[::-1], loc="center left", bbox_to_anchor=(1, 0.5))
    if not stock_total:
        title = f"Per Dwelling Unit {fuel.title()}"
    else:
        title = f"Total Stock {fuel.title()} (n={n_customers})"

    fig.suptitle(title)
    fig.tight_layout()
