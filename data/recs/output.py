import os
#import matplotlib as mpl
#mpl.use('Agg') # Turn interactive plotting off
#mpl.use('qt4agg')
import matplotlib.pyplot as plt
import seaborn as sns
import sys
import numpy as np
import itertools
import pandas as pd
import matplotlib as mpl
from PIL import Image

def trim_white(filename):
    im = Image.open(filename)
    pix = np.asarray(im)

    pix = pix[:,:,0:3] # Drop the alpha channel
    idx = np.where(pix-255)[0:2] # Drop the color when finding edges
    box = map(min,idx)[::-1] + map(max,idx)[::-1]

    region = im.crop(box)
    region_pix = np.asarray(region)
    region.save(filename)

def draw_scatter_plot(df, cols, marker_labels, slicer, weighted_area=True, setlims=None, marker_colors=None,
                      marker_shapes=None, size='medium', axis_titles=None, marker_color_all=None, show_labels=True,
                      leg_label=None, max_marker_size=None):
    def get_marker(i):
        return mpl.markers.MarkerStyle.filled_markers[i]

    def add_labels(marker_labels, x, y):
        if not show_labels:
            return
        for label, x, y in zip(marker_labels, x, y):
            if y > x:
                ha = 'right'
                va = 'bottom'
                xytext = (-5, 5)
            else:
                ha = 'left'
                va = 'top'
                xytext = (5, -5)
            plt.annotate(label, xy =(x, y), xytext=xytext,
                textcoords='offset points', ha=ha, va=va, alpha=0.8)

    if marker_color_all is None:
        if 'electricity' in cols[0].lower():
            marker_color_all = 'r'
        elif 'gas' in cols[0].lower():
            marker_color_all = 'b'
        else:
            marker_color_all = 'k'

    title = slicer
    x = df[cols[0]]
    y = df[cols[1]]

    if weighted_area:
        area_weights = (df['Weight'] / df['Weight'].max()) * max_marker_size
    else:
        area_weights = 100

    if marker_colors is None:
        if weighted_area:
            # plt.scatter(x, y, s=area_weights, c='k', alpha=1.0) # solid black for superimposed shadows for previous calibration iteration
            plt.scatter(x, y, s=area_weights, c=marker_color_all, alpha=0.5, label=leg_label)
            # pd.concat([x, y, marker_labels], axis=1).to_csv(os.path.join('../../analysis_results/outputs/national', 'values.tsv'), sep='\t', index=False, mode='a', header=True)
        else:
            plt.scatter(x, y, c=marker_color_all, alpha=0.5, label=leg_label)
        add_labels(marker_labels, x, y)
    else:
        colormap = plt.cm.autumn
        if marker_shapes is None:
            plt.scatter(x, y, c=marker_colors, cmap=colormap, s=area_weights, alpha=0.7, label=leg_label)
            # pd.concat([x, y, pd.DataFrame(marker_labels)], axis=1).to_csv(os.path.join('../../analysis_results/outputs/national', 'values.tsv'), sep='\t', index=False, mode='a', header=True)
            add_labels(marker_labels, x, y)
        else:
            for i, shape in enumerate(set(marker_shapes)):
                this_marker = df.loc[df['level_0'] == shape, :]
                x = this_marker[cols[0]]
                y = this_marker[cols[1]]
                marker_colors = this_marker['level_1']
                marker_colors = [list(set(marker_colors)).index(j) for j in marker_colors.tolist()]
                marker_labels = zip(this_marker['level_0'], this_marker['level_1'])
                plt.scatter(x, y, c=marker_colors, cmap=colormap, marker='${}$'.format(shape[2:]), s=area_weights,
                            alpha=0.7, label=leg_label)
                add_labels(marker_labels, x, y)

    # y=x line
    ax = plt.gca()
    lims = [
        np.min([ax.get_xlim(), ax.get_ylim()]),  # min of both axes
        np.max([ax.get_xlim(), ax.get_ylim()]),  # max of both axes
    ]

    if not setlims is None:
        print "Overwriting calculated scale limits ({}) with user-specified limits ({})".format(lims, setlims)
        for i, setlim in enumerate(setlims):
            if not setlim is None:
                lims[i] = setlim

    # now plot both limits against eachother
    ax.plot(lims, lims, 'k-', alpha=0.75, zorder=0)

    # +20% line
    ax.plot(lims, [lims[0], lims[1]*1.2], 'k-', alpha=0.1, zorder=0)

    # +20% line
    ax.plot(lims, [lims[0], lims[1]*0.8], 'k-', alpha=0.1, zorder=0)
    
    ax.set_aspect('equal')
    ax.set_xlim(lims)
    ax.set_ylim(lims)
    
    if size == 'large':
        title_size = 20
        axis_label_size = 24
        tick_size = 16
    elif size == 'medium':
        title_size = 16
        axis_label_size = 20
        tick_size = 12
    elif size == 'small':
        title_size = 16
        axis_label_size = 16
        tick_size = 12

    if axis_titles is None:
        ax.set_xlabel('Measured (RECS)', fontsize=axis_label_size)
        ax.set_ylabel('Modeled (ResStock-National)', fontsize=axis_label_size)
    else:
        ax.set_xlabel(axis_titles[0], fontsize=axis_label_size)
        ax.set_ylabel(axis_titles[1], fontsize=axis_label_size)
    plt.tick_params(axis='both', which='major', labelsize=tick_size)
    plt.title(title, fontsize=title_size)


def units_kWh2MBtu(x):
    return 3412.0 * 0.000001 * x


def units_Therm2MBtu(x):
    return 0.1 * x
    
    
def units_Btu2kWh(x):
    return (1/units_kWh2MBtu(1))*x/1000.0

def units_Btu2Therm(x):
    return (1/units_Therm2MBtu(1))*x/1000.0


def do_plot(slices, fields, size='medium', weighted_area=True, save=False, setlims=None, marker_color=False, marker_shape=False, version=None, marker_color_all=None, show_labels=True, leg_label=None, num_slices=1, screen_scen='no screens', predicted_file_name='resstock_national'):
    consumption_folder = '../../analysis_results/outputs/national/screens/{}'.format(screen_scen)
    
    if size == 'large':
        plt.rcParams['figure.figsize'] = 20, 20 # 20, 20 # set image size
        max_marker_size = 800
    elif size == 'medium':
        plt.rcParams['figure.figsize'] = 20, 10  # set image size
        max_marker_size = 400
    elif size == 'small':
        plt.rcParams['figure.figsize'] = 10, 5  # set image size
        max_marker_size = 400
    
    for i, slicer in enumerate(slices):
        plt.subplot(1, len(slices), i+1)
        marker_colors = None
        marker_shapes = None
        marker_labels = None
        if fields == 'weights':
            continue # TODO
        elif num_slices == 1:
          if 'electricity_and_gas' in fields:
              measured_elec = pd.read_csv(os.path.join(consumption_folder, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['kwh_nrm_per_home']]
              measured_gas = pd.read_csv(os.path.join(consumption_folder, 'Natural Gas Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['thm_nrm_per_home']]
              measured = measured_elec.join(measured_gas)
              measured['Measured Per House Site Electricity+Gas MBtu'] = units_kWh2MBtu(measured['kwh_nrm_per_home']) + units_Therm2MBtu(measured['thm_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(consumption_folder, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted = pd.read_csv('../../analysis_results/{}.csv'.format(predicted_file_name), index_col=['name'])
              predicted = remove_upgrades(predicted)
              predicted['Weight'] = house_count / len(predicted.index)
              predicted['Predicted Total Site Electricity+Gas MBtu'] = (units_kWh2MBtu(predicted['simulation_output_report.Total Site Electricity kWh']) + units_Therm2MBtu(predicted['simulation_output_report.Total Site Natural Gas therm'])) * predicted['Weight']
              predicted = predicted.groupby('building_characteristics_report.{}'.format(slicer)).sum()
              predicted['Predicted Per House Site Electricity+Gas MBtu'] = predicted['Predicted Total Site Electricity+Gas MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Electricity+Gas MBtu', 'Predicted Per House Site Electricity+Gas MBtu', 'Weight']
          elif 'electricity' in fields:
              measured = pd.read_csv(os.path.join(consumption_folder, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['kwh_nrm_per_home']]
              measured['Measured Per House Site Electricity MBtu'] = units_kWh2MBtu(measured['kwh_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(consumption_folder, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted = pd.read_csv('../../analysis_results/{}.csv'.format(predicted_file_name), index_col=['name'])
              predicted = remove_upgrades(predicted)
              predicted['Weight'] = house_count / len(predicted.index)
              predicted['Predicted Total Site Electricity MBtu'] = units_kWh2MBtu(predicted['simulation_output_report.Total Site Electricity kWh']) * predicted['Weight']
              predicted = predicted.groupby('building_characteristics_report.{}'.format(slicer)).sum()
              predicted['Predicted Per House Site Electricity MBtu'] = predicted['Predicted Total Site Electricity MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Electricity MBtu', 'Predicted Per House Site Electricity MBtu', 'Weight']
          elif 'gas' in fields:
              measured = pd.read_csv(os.path.join(consumption_folder, 'Natural Gas Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['thm_nrm_per_home']]
              measured['Measured Per House Site Gas MBtu'] = units_Therm2MBtu(measured['thm_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(consumption_folder, 'Natural Gas Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted = pd.read_csv('../../analysis_results/{}.csv'.format(predicted_file_name), index_col=['name'])
              predicted = remove_upgrades(predicted)
              predicted['Weight'] = house_count / len(predicted.index)
              predicted['Predicted Total Site Gas MBtu'] = units_Therm2MBtu(predicted['simulation_output_report.Total Site Natural Gas therm'] * predicted['Weight'])
              predicted = predicted.groupby('building_characteristics_report.{}'.format(slicer)).sum()
              predicted['Predicted Per House Site Gas MBtu'] = predicted['Predicted Total Site Gas MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Gas MBtu', 'Predicted Per House Site Gas MBtu', 'Weight']
        elif num_slices == 2:
          sub_slicer = slicer.replace("Location Heating Region ","") # Assumes first slice is Location Heating Region; will error out if not
          if sub_slicer == slicer:
            sys.exit("Unexpected slicer: %s" % slicer)
          if 'electricity' in fields:
              measured = pd.read_csv(os.path.join(consumption_folder, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency=Location Heating Region', 'Dependency={}'.format(sub_slicer)], sep='\t')[['kwh_nrm_per_home']]
              measured['Measured Per House Site Electricity MBtu'] = units_kWh2MBtu(measured['kwh_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(consumption_folder, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency=Location Heating Region', 'Dependency={}'.format(sub_slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted = pd.read_csv('../../analysis_results/{}.csv'.format(predicted_file_name), index_col=['name'])
              predicted = remove_upgrades(predicted)
              predicted['Weight'] = house_count / len(predicted.index)
              predicted['Predicted Total Site Electricity MBtu'] = units_kWh2MBtu(predicted['simulation_output_report.Total Site Electricity kWh']) * predicted['Weight']
              predicted = predicted.rename(columns={"building_characteristics_report.Location Heating Region": "Dependency=Location Heating Region", "building_characteristics_report.{}".format(sub_slicer): "Dependency={}".format(sub_slicer)})
              predicted = predicted.groupby(['Dependency=Location Heating Region', 'Dependency={}'.format(sub_slicer)]).sum()
              predicted['Predicted Per House Site Electricity MBtu'] = predicted['Predicted Total Site Electricity MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Electricity MBtu', 'Predicted Per House Site Electricity MBtu', 'Weight']
          elif 'gas' in fields:
              measured = pd.read_csv(os.path.join(consumption_folder, 'Natural Gas Consumption {}.tsv'.format(slicer)), index_col=['Dependency=Location Heating Region', 'Dependency={}'.format(sub_slicer)], sep='\t')[['thm_nrm_per_home']]
              measured['Measured Per House Site Gas MBtu'] = units_Therm2MBtu(measured['thm_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(consumption_folder, 'Natural Gas Consumption {}.tsv'.format(slicer)), index_col=['Dependency=Location Heating Region', 'Dependency={}'.format(sub_slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted = pd.read_csv('../../analysis_results/{}.csv'.format(predicted_file_name), index_col=['name'])
              predicted = remove_upgrades(predicted)
              predicted['Weight'] = house_count / len(predicted.index)
              predicted['Predicted Total Site Gas MBtu'] = units_Therm2MBtu(predicted['simulation_output_report.Total Site Natural Gas therm']) * predicted['Weight']
              predicted = predicted.rename(columns={"building_characteristics_report.Location Heating Region": "Dependency=Location Heating Region", "building_characteristics_report.{}".format(sub_slicer): "Dependency={}".format(sub_slicer)})
              predicted = predicted.groupby(['Dependency=Location Heating Region', 'Dependency={}'.format(sub_slicer)]).sum()
              predicted['Predicted Per House Site Gas MBtu'] = predicted['Predicted Total Site Gas MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Gas MBtu', 'Predicted Per House Site Gas MBtu', 'Weight']
        else:
            sys.exit("Unexpected num_slices: %s" % num_slices)
           
        df = measured.join(predicted)[cols]
        df = df.reset_index()
        marker_labels = df.ix[:,0]
        if marker_color:
            marker_colors = df['Dependency=Location Heating Region']
            marker_colors = [list(set(marker_colors)).index(i) for i in marker_colors.tolist()]          
            marker_labels = zip(df['Dependency=Location Heating Region'], df['Dependency={}'.format(sub_slicer)])

        draw_scatter_plot(df, cols, marker_labels, slicer, weighted_area=weighted_area, setlims=setlims,
                          marker_colors=marker_colors, marker_shapes=marker_shapes, size=size,
                          marker_color_all=marker_color_all, show_labels=show_labels, leg_label=leg_label,
                          max_marker_size=max_marker_size)
    if save:
        filename = os.path.join('..', '..', 'analysis_results', 'outputs', 'national', 'saved images', screen_scen, 'Scatter_{}slice_{}.png'.format(num_slices, fields))
        plt.savefig(filename, bbox_inches='tight', dpi=200)
        trim_white(filename)
        plt.close()

class Create_DFs():
    
    def __init__(self, file):
        self.session = pd.read_csv(file)

    def electricity_consumption_vintage(self, screen_scen):
        df = self.session
        df = df[['yearmaderange', 'btuel', 'nweight']]
        df['kwh_nrm'] = df.apply(lambda x: units_Btu2kWh(x.btuel), axis=1)
        df = df.rename(columns={'yearmaderange': 'Dependency=Vintage', 'nweight': 'Weight'})
        df['Dependency=Vintage'] = df['Dependency=Vintage'].replace({'1950-pre': '<1950'})
        df = df.groupby(['Dependency=Vintage'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwh_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwh_nrm_per_home'] = df['kwh_nrm'] / df['Count']
        df['kwh_nrm_total'] = df['kwh_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Vintage']).set_index(['Dependency=Vintage'])             
        return df

    def electricity_consumption_heating_fuel(self, screen_scen):
        df = self.session
        df = df[['fuelheat', 'btuel', 'nweight']]
        df['kwh_nrm'] = df.apply(lambda x: units_Btu2kWh(x.btuel), axis=1)
        df = df.rename(columns={'fuelheat': 'Dependency=Heating Fuel', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwh_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwh_nrm_per_home'] = df['kwh_nrm'] / df['Count']
        df['kwh_nrm_total'] = df['kwh_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df = df.sort_values(by=['Dependency=Heating Fuel']).set_index(['Dependency=Heating Fuel'])             
        return df
        
    def electricity_consumption_geometry_house_size(self, screen_scen):
        df = self.session
        df = df[['Size', 'btuel', 'nweight']]
        df['kwh_nrm'] = df.apply(lambda x: units_Btu2kWh(x.btuel), axis=1)
        df = df.rename(columns={'Size': 'Dependency=Geometry House Size', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Geometry House Size'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwh_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwh_nrm_per_home'] = df['kwh_nrm'] / df['Count']
        df['kwh_nrm_total'] = df['kwh_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df = df.sort_values(by=['Dependency=Geometry House Size']).set_index(['Dependency=Geometry House Size'])             
        return df
        
    def electricity_consumption_federal_poverty_level(self, screen_scen):
        df = self.session
        df = df[['FPL_BINS', 'btuel', 'nweight']]
        df['kwh_nrm'] = df.apply(lambda x: units_Btu2kWh(x.btuel), axis=1)
        df = df.rename(columns={'FPL_BINS': 'Dependency=Federal Poverty Level', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Federal Poverty Level'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwh_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwh_nrm_per_home'] = df['kwh_nrm'] / df['Count']
        df['kwh_nrm_total'] = df['kwh_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Federal Poverty Level'] = pd.Categorical(df['Dependency=Federal Poverty Level'], ['0-50', '50-100', '100-150', '150-200', '200-250', '250-300', '300+'])
        df = df.sort_values(by=['Dependency=Federal Poverty Level']).set_index(['Dependency=Federal Poverty Level'])
        return df
        
    def natural_gas_consumption_vintage(self, screen_scen):
        df = self.session
        df = df[['yearmaderange', 'btung', 'nweight']]
        df['thm_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung), axis=1)
        df = df.rename(columns={'yearmaderange': 'Dependency=Vintage', 'nweight': 'Weight'})
        df['Dependency=Vintage'] = df['Dependency=Vintage'].replace({'1950-pre': '<1950'})
        df = df.groupby(['Dependency=Vintage'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thm_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thm_nrm_per_home'] = df['thm_nrm'] / df['Count']
        df['thm_nrm_total'] = df['thm_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Vintage']).set_index(['Dependency=Vintage'])             
        return df

    def natural_gas_consumption_heating_fuel(self, screen_scen):
        df = self.session
        df = df[['fuelheat', 'btung', 'nweight']]
        df['thm_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung), axis=1)
        df = df.rename(columns={'fuelheat': 'Dependency=Heating Fuel', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thm_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thm_nrm_per_home'] = df['thm_nrm'] / df['Count']
        df['thm_nrm_total'] = df['thm_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df = df.sort_values(by=['Dependency=Heating Fuel']).set_index(['Dependency=Heating Fuel'])             
        return df
        
    def natural_gas_consumption_geometry_house_size(self, screen_scen):
        df = self.session
        df = df[['Size', 'btung', 'nweight']]
        df['thm_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung), axis=1)
        df = df.rename(columns={'Size': 'Dependency=Geometry House Size', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Geometry House Size'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thm_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thm_nrm_per_home'] = df['thm_nrm'] / df['Count']
        df['thm_nrm_total'] = df['thm_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df = df.sort_values(by=['Dependency=Geometry House Size']).set_index(['Dependency=Geometry House Size'])             
        return df
        
    def natural_gas_consumption_federal_poverty_level(self, screen_scen):
        df = self.session
        df = df[['FPL_BINS', 'btung', 'nweight']]
        df['thm_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung), axis=1)
        df = df.rename(columns={'FPL_BINS': 'Dependency=Federal Poverty Level', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Federal Poverty Level'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thm_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thm_nrm_per_home'] = df['thm_nrm'] / df['Count']
        df['thm_nrm_total'] = df['thm_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Federal Poverty Level'] = pd.Categorical(df['Dependency=Federal Poverty Level'], ['0-50', '50-100', '100-150', '150-200', '200-250', '250-300', '300+'])
        df = df.sort_values(by=['Dependency=Federal Poverty Level']).set_index(['Dependency=Federal Poverty Level'])             
        return df
        
def to_figure(df, file):
    
    sns.set(font_scale=1)
    f, ax = plt.subplots(figsize=(10, 10))
    ax = sns.heatmap(df, annot=True, annot_kws={'size': 10}, fmt='.2f')
    plt.savefig(file)
    plt.close()
    
def remove_upgrades(df):
    for col in df.columns:
        if col.endswith('.run_measure'):
            df = df[df[col]==0]
    return df
    
def update_predicted_with_fpl(predicted_file_name='resstock_national'):

    os.system('ruby ../../worker_initialize/run_sampling.rb')
    # os.system('ruby ./run_sampling.rb')

    fpl = pd.read_csv('../../resources/inputs/national/Federal Poverty Level.tsv', index_col=[('Dependency=Vintage', 'Dependency=HVAC System Cooling Type')])
    print fpl
    
    predicted = pd.read_csv('../../analysis_results/{}.csv'.format(predicted_file_name), index_col=['name'])
    predicted['building_characteristics_report.Federal Poverty Level'] = '0-50'
    predicted.to_csv('../../analysis_results/{}_fpl.csv'.format(predicted_file_name))
   
if __name__ == '__main__':
    
    datafiles_dir = '../../analysis_results/outputs/national/screens'
    heatmaps_dir = 'heatmaps'

    dfs = Create_DFs('MLR/recs.csv')
    
    for screening_scenario in [
                               'No Screens'
                               ]:
    
        for category in [
                         # 'Electricity Consumption Location Heating Region', 
                         # 'Electricity Consumption Location Cooling Region', 
                         # 'Electricity Consumption Vintage', 
                         # 'Electricity Consumption Heating Fuel',
                         # 'Electricity Consumption Geometry House Size', 
                         # 'Electricity Consumption Geometry Foundation Type', 
                         # 'Electricity Consumption Geometry Stories', 
                         # 'Electricity Consumption Heating Setpoint', 
                         # 'Electricity Consumption Location Heating Region Vintage', 
                         # 'Electricity Consumption Location Heating Region Heating Fuel', 
                         # 'Electricity Consumption Location Heating Region Geometry Foundation Type', 
                         # 'Electricity Consumption Location Heating Region Geometry House Size',
                         # 'Electricity Consumption Federal Poverty Level',
                         # 'Natural Gas Consumption Location Heating Region',
                         # 'Natural Gas Consumption Location Cooling Region',
                         # 'Natural Gas Consumption Vintage', 
                         # 'Natural Gas Consumption Heating Fuel',
                         # 'Natural Gas Consumption Geometry House Size',
                         # 'Natural Gas Consumption Geometry Foundation Type',
                         # 'Natural Gas Consumption Geometry Stories',
                         # 'Natural Gas Consumption Heating Setpoint',
                         # 'Natural Gas Consumption Location Heating Region Vintage',
                         # 'Natural Gas Consumption Location Heating Region Heating Fuel',
                         # 'Natural Gas Consumption Location Heating Region Geometry Foundation Type',
                         # 'Natural Gas Consumption Location Heating Region Geometry House Size',
                         # 'Natural Gas Consumption Federal Poverty Level'
                         ]:
            print "{} - {}".format(screening_scenario, category)
            method = getattr(dfs, category.lower().replace(' ', '_'))
            df = method(screening_scenario)
            df.to_csv(os.path.join(datafiles_dir, screening_scenario, '{}.tsv'.format(category)), sep='\t')

            for col in ['Count', 'Weight']:
                if col in df.columns:
                    del df[col]
            to_figure(df, os.path.join(heatmaps_dir, screening_scenario, '{}.png'.format(category)))
        
        slices = [
                  #'Location Heating Region',
                  #'Location Cooling Region',
                  'Vintage',
                  'Heating Fuel',
                  'Geometry House Size',
                  'Federal Poverty Level',
                  #'Geometry Foundation Type', 
                  #'Geometry Stories', 
                  #'Heating Setpoint'
                  ]
        if 'Federal Poverty Level' in slices:
          update_predicted_with_fpl()
          do_plot(slices=slices, fields='electricity_and_gas_perhouse', save=True, setlims=[0,None], num_slices=1, screen_scen=screening_scenario, predicted_file_name='resstock_national_fpl')
          do_plot(slices=slices, fields='electricity_perhouse', save=True, setlims=[0,None], num_slices=1, screen_scen=screening_scenario, predicted_file_name='resstock_national_fpl')
          do_plot(slices=slices, fields='gas_perhouse', save=True, setlims=[0,None], num_slices=1, screen_scen=screening_scenario, predicted_file_name='resstock_national_fpl')
        else:
          do_plot(slices=slices, fields='electricity_and_gas_perhouse', save=True, setlims=[0,None], num_slices=1, screen_scen=screening_scenario)
          do_plot(slices=slices, fields='electricity_perhouse', save=True, setlims=[0,None], num_slices=1, screen_scen=screening_scenario)
          do_plot(slices=slices, fields='gas_perhouse', save=True, setlims=[0,None], num_slices=1, screen_scen=screening_scenario)

        slices = [
                  #'Location Heating Region Vintage',
                  #'Location Heating Region Heating Fuel',
                  #'Location Heating Region Geometry Foundation Type',
                  #'Location Heating Region Geometry House Size',
                  ]
        # do_plot(slices=slices, fields='electricity_perhouse', save=True, size='medium', marker_color=True, setlims=[0,None], num_slices=2, screen_scen=screening_scenario)
        # do_plot(slices=slices, fields='gas_perhouse', save=True, size='medium', marker_color=True, setlims=[0,None], num_slices=2, screen_scen=screening_scenario)
