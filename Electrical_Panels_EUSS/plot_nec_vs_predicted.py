import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import gaussian_kde
import re
from pathlib import Path
import pandas as pd

from plotting_functions import _plot_bar

nec_file = Path("/Users/lliu2/Documents/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_2018_results_up00_clean__nec_panels.csv")
pd_file = Path("/Users/lliu2/Documents/Lab Call 5A - electrical panel constraints/FY23/Panels Estimation/euss1_2018_results_up00_clean__predicted_panels_probablistically_assigned.csv")

df = pd.read_csv(nec_file, low_memory=False)
dfp = pd.read_csv(pd_file, low_memory=False)
df = df.join(dfp.set_index(["building_id"])["predicted_panel_amp"], on="building_id")
del dfp

### plotting
sfd_only = False
plot_dir_name = "plots_sfd" if sfd_only else "plots"
output_dir = nec_file.parent / plot_dir_name
output_dir.mkdir(parents=True, exist_ok=True) 
print(f"Plots are outputing to: {output_dir}")

panel_metric = "std_m_nec_electrical_panel_amp"
_plot_bar(df, ["predicted_panel_amp", panel_metric], output_dir=output_dir, sfd_only=sfd_only)

panel_metric = "opt_m_nec_electrical_panel_amp"
_plot_bar(df, ["predicted_panel_amp", panel_metric], output_dir=output_dir, sfd_only=sfd_only)

# flipped axes
panel_metric = "std_m_nec_electrical_panel_amp"
_plot_bar(df, [panel_metric, "predicted_panel_amp"], output_dir=output_dir, sfd_only=sfd_only)

panel_metric = "opt_m_nec_electrical_panel_amp"
_plot_bar(df, [panel_metric, "predicted_panel_amp"], output_dir=output_dir, sfd_only=sfd_only)

print("Plotting completed")
