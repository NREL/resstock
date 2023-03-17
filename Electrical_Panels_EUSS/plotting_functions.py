import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import gaussian_kde


def plot_output(df, output_dir=None):
    print(f"Plots output to: {output_dir}")
    metric = "std_m_nec_electrical_panel_amp"
    title = "NEC panel amperage - standard method"
    _plot_amperage_histogram(df, metric, title=title, output_dir=output_dir)

    metric = "opt_m_nec_electrical_panel_amp"
    title = "NEC panel amperage - optional method"
    _plot_amperage_histogram(df, metric, title=title, output_dir=output_dir)

    x_metric = "std_m_nec_electrical_panel_amp"
    y_metric = "opt_m_nec_electrical_panel_amp"
    title = "Standard vs. optional method"
    _plot_scatter(df, x_metric, y_metric, title=title, output_dir=output_dir)

    x_metric = "std_m_nec_electrical_panel_amp"
    y_metric = "peak_amp"
    title = "Standard method vs. simulated peak"
    _plot_scatter(df, x_metric, y_metric, title=title, output_dir=output_dir)

    x_metric = "opt_m_nec_electrical_panel_amp"
    y_metric = "peak_amp"
    title = "Optional method vs. simulated peak"
    _plot_scatter(df, x_metric, y_metric, title=title, output_dir=output_dir)

def _plot_amperage_histogram(df, metric, title=None, output_dir=None):
    fig, ax = plt.subplots()
    panel_sizes = df[metric].to_list()
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

def _plot_scatter(df, x_metric, y_metric, title=None, output_dir=None):
    fig, ax = plt.subplots()
    df = df[[x_metric, y_metric]].dropna(how="any")
    x, y = df[x_metric], df[y_metric]

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
        