import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import gaussian_kde
import re
from pathlib import Path
import pandas as pd

from plotting_functions import _plot_bar

def bin_panel_sizes_every_50_amp(df_column):
    # left inclusive and right exclusive

    try:
        df_column = df_column.astype(float)
    except ValueError as e:
        df_column = df_column.replace('', np.nan).astype(float)

    df_out = pd.Series(np.nan, index=df_column.index)
    df_out.loc[df_column<50] = "<50"
    df_out.loc[(df_column>=50) & (df_column<100)] = "50-99"
    df_out.loc[(df_column>=100) & (df_column<150)] = "100-149"
    df_out.loc[(df_column>=150) & (df_column<200)] = "150-199"
    df_out.loc[(df_column>=200)] = "200+"

    categories = ["<50", "50-99", "100-149", "150-199", "200+"]
    df_out = pd.Categorical(df_out, ordered=True, categories=categories)

    return df_out

def box_plot_by(df, panel_metric, by_var, output_dir=None):
    ax = df[[by_var, panel_metric]].boxplot(by=by_var)

    fig_file = f"box_{panel_metric}_by_{by_var}.png"
    if output_dir is not None:
        fig_file = output_dir / fig_file
    ax.set_xlabel("Predicted Panel Amperage (Amp)")
    ax.set_ylabel("Existing Load (Amp)")
    plt.suptitle(None)
    if "83" in panel_metric:
        ax.set_title("Existing Load per NEC 220.83")
    else:
        ax.set_title("Existing Load per NEC 220.87 (Occupied Units Only)")
    ax.get_figure().savefig(fig_file, dpi=400, bbox_inches="tight")
    plt.close()

### ----- start script -----

nec_file = Path("/Users/lliu2/Documents/Documents_Files/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_2018_results_up00_clean__existing_load.csv")
pd_file = Path("/Users/lliu2/Documents/Documents_Files/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_2018_results_up00_clean__model_162__tsv_based__predicted_panels_probablistically_assigned.csv")

df = pd.read_csv(nec_file, low_memory=False, keep_default_na=False)
for col in ["existing_amp_220_83", "existing_amp_220_87"]:
    df[col] = df[col].replace('', np.nan).astype(float)

dfp = pd.read_csv(pd_file, low_memory=False, keep_default_na=False)
categories = ["<100", "100", "101-199", "200", "201+"]
dfp["predicted_panel_amp"] = pd.Categorical(dfp["predicted_panel_amp"], ordered=True, categories=categories)

df = df.join(dfp.set_index(["building_id"])["predicted_panel_amp"], on="building_id")
del dfp

### plotting
sfd_only = False
plot_dir_name = "plots_sfd" if sfd_only else "plots"
output_dir = nec_file.parent / f"{plot_dir_name}__existing_load"
output_dir.mkdir(parents=True, exist_ok=True) 
print(f"Plots are outputing to: {output_dir}")


### [1] box plots
panel_metric = "existing_amp_220_83"
by_var = "predicted_panel_amp"
box_plot_by(df, panel_metric, by_var, output_dir=output_dir)

panel_metric = "existing_amp_220_87"
by_var = "predicted_panel_amp"
box_plot_by(df, panel_metric, by_var, output_dir=output_dir)

### [2] binned historgrams
### bin panels
df["binned_existing_amp_220_83"]= bin_panel_sizes_every_50_amp(df["existing_amp_220_83"])
df["binned_existing_amp_220_87"]= bin_panel_sizes_every_50_amp(df["existing_amp_220_87"])
df.to_csv(output_dir / "euss1_2018_results_up00_clean__model_162__tsv_based__vs__existing_load.csv", index=False)

print("Binned existing amps")

panel_metric = "binned_existing_amp_220_83"
_plot_bar(df, ["predicted_panel_amp", panel_metric], output_dir=output_dir, sfd_only=sfd_only)

panel_metric = "binned_existing_amp_220_87"
_plot_bar(df, ["predicted_panel_amp", panel_metric], output_dir=output_dir, sfd_only=sfd_only)


print("Plotting completed")
