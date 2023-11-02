import plotly.express as px
from InquirerPy import inquirer
import plotly.subplots as sp
import plotly.graph_objects as go
import polars as pl
import pandas as pd
import yaml
import os

with open("config.yaml") as f:
    config = yaml.safe_load(f)

os.makedirs(f"{config['output_folder']}/quick_plots", exist_ok=True)

def get_plot(report_df, column):
    fig = sp.make_subplots(rows=len(report_df['upgrade'].unique()), cols=1,
                           subplot_titles=report_df['full_name'].unique(), vertical_spacing=0.002)

    for i, upgrade in enumerate(report_df['upgrade'].unique()):
        for j, report_name in enumerate(report_df['report_name'].unique()):
            trace = go.Bar(
                x=report_df[(report_df['upgrade'] == upgrade) &
                            (report_df['report_name'] == report_name)]['state'],
                y=report_df[(report_df['upgrade'] == upgrade) &
                            (report_df['report_name'] == report_name)][column],
                name=f'{report_name}',
                legendgroup=report_name,
                showlegend=True if i == 0 else False,
            )
            fig.append_trace(trace, row=i+1, col=1)
    fig.update_layout(height=100*len(report_df['upgrade'].unique()), title=f'Avg {column} per dwelling unit')
    return fig


def produce_plot(report_df):
    plotting_cols = [col for col in report_df.columns if col.endswith(('_lb', '_m_btu', '_usd'))]
    for col_name in plotting_cols:
        get_plot(report_df, col_name).write_html(
            f"{config['output_folder']}/quick_plots/{config['file_prefix']}{col_name}.html",
            include_plotlyjs='cdn')
        print(f"{config['output_folder']}/quick_plots/{config['file_prefix']}{col_name}.html saved.")


def main():
    print("This script will plot the results from quick_look.csv generated using get_quick_look_report.py script")
    report_paths = inquirer.text(message="Enter the path to quick_look_report. If you want to plot multiple reports "
                                         "side by side, enter multiple paths separated by comma.",
                                 default="").execute()
    report_name = inquirer.text(message="Just give a name to the set of reports you are plotting. Separate by comma if using"
                                "multiple reports. For example: 'before,after'.",
                                default="").execute()
    report_paths = report_paths.split(',')
    report_name = report_name.split(',')
    if len(report_paths) != len(report_name):
        print("Number of reports and names do not match. Please try again.")
        main()
        return
    all_report_dfs = []
    for report_name, report_path in zip(report_name, report_paths):
        report_df = pd.read_csv(report_path)
        report_df["report_name"] = report_name
        all_report_dfs.append(report_df)
    all_report_df = pd.concat(all_report_dfs)
    produce_plot(all_report_df)


if __name__ == "__main__":
    main()
