import os
import matplotlib.pyplot as plt
import sys
import numpy as np
import itertools
import pandas as pd
pd.options.mode.chained_assignment = None
import matplotlib as mpl
from PIL import Image
import zipfile
import argparse

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
        elif 'other' in cols[0].lower():
          marker_color_all = 'c'
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

def expand(predicted, tsv_file):
  tsv = pd.read_csv(tsv_file, sep='\t')
  on = []
  for col in tsv.columns:
    if 'Dependency=' in col:
      tsv = tsv.rename(columns={col: col.replace('Dependency=', 'building_characteristics_report.').lower().replace(' ', '_')})
      on.append(col.replace('Dependency=', 'building_characteristics_report.').lower().replace(' ', '_'))

  try:
    predicted = predicted.reset_index()
    predicted = predicted.merge(tsv, on=on, how='left')
  except KeyError as ke:
    sys.exit('Column {} does not exist.'.format(ke))
    
  id_vars = []
  value_vars = []
  for col in predicted.columns:
    if 'Option=' in col:
      value_vars.append(col)
    else:
      id_vars.append(col)
    
  melted = pd.melt(predicted, id_vars=id_vars, value_vars=value_vars, var_name='building_characteristics_report.{}'.format(os.path.basename(tsv_file).replace('.tsv', '').lower().replace(' ', '_')), value_name='frac')
  melted = melted.set_index('_id')
  melted['building_characteristics_report.{}'.format(os.path.basename(tsv_file).replace('.tsv', '').lower().replace(' ', '_'))] = melted['building_characteristics_report.{}'.format(os.path.basename(tsv_file).replace('.tsv', '').lower().replace(' ', '_'))].str.replace('Option=', '')
    
  return melted
    
def do_plot(zip_or_dir, datafiles_dir, slices, fields, size='medium', weighted_area=True, save=False, setlims=None, marker_color=False, marker_shape=False, version=None, marker_color_all=None, show_labels=True, leg_label=None, num_slices=1, tsv_file=None):

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
    
      if zip_or_dir.endswith('.zip'):
        dir = os.path.dirname(zip_or_dir)
        folder_zf = zipfile.ZipFile(zip_or_dir)
        folder = folder_zf.namelist()
      else:
        dir = zip_or_dir
        folder = os.listdir(zip_or_dir)

      full = None
      for item in folder:
      
        if not item.endswith('results.csv') and not item.endswith('results_combined.csv'):
          continue

        if zip_or_dir.endswith('.zip'):
          extracted_folder = folder_zf.extract(item, dir)
          
        predicted = pd.read_csv(os.path.join(dir, item), index_col=['_id'])
        predicted = remove_upgrades(predicted)
          
        if tsv_file:
          predicted = expand(predicted, tsv_file)
    
        plt.subplot(1, len(slices), i+1)
        marker_colors = None
        marker_shapes = None
        marker_labels = None
        if fields == 'weights':
            continue # TODO
        elif num_slices == 1:
          if 'electricity_and_gas' in fields:
              measured_elec = pd.read_csv(os.path.join(datafiles_dir, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['kwhel_nrm_per_home']]
              measured_gas = pd.read_csv(os.path.join(datafiles_dir, 'Natural Gas Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['thmng_nrm_per_home']]
              measured = measured_elec.join(measured_gas)
              measured['Measured Per House Site Electricity+Gas MBtu'] = units_kWh2MBtu(measured['kwhel_nrm_per_home']) + units_Therm2MBtu(measured['thmng_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(datafiles_dir, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted['Weight'] = house_count / len(predicted.index.unique())
              predicted['Predicted Total Site Electricity+Gas MBtu'] = (units_kWh2MBtu(predicted['simulation_output_report.total_site_electricity_kwh']) + units_Therm2MBtu(predicted['simulation_output_report.total_site_natural_gas_therm'])) * predicted['Weight']
              if 'frac' in predicted.columns:
                predicted['Weight'] = predicted['Weight'] * predicted['frac']
                predicted['Predicted Total Site Electricity+Gas MBtu'] = predicted['Predicted Total Site Electricity+Gas MBtu'] * predicted['frac']
              predicted = predicted.groupby('building_characteristics_report.{}'.format(slicer.lower().replace(' ', '_'))).sum()
              predicted['Predicted Per House Site Electricity+Gas MBtu'] = predicted['Predicted Total Site Electricity+Gas MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Electricity+Gas MBtu', 'Predicted Per House Site Electricity+Gas MBtu', 'Weight']
          elif 'electricity' in fields:
              measured = pd.read_csv(os.path.join(datafiles_dir, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['kwhel_nrm_per_home']]
              measured['Measured Per House Site Electricity MBtu'] = units_kWh2MBtu(measured['kwhel_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(datafiles_dir, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted['Weight'] = house_count / len(predicted.index.unique())
              predicted['Predicted Total Site Electricity MBtu'] = units_kWh2MBtu(predicted['simulation_output_report.total_site_electricity_kwh']) * predicted['Weight']
              if 'frac' in predicted.columns:
                predicted['Weight'] = predicted['Weight'] * predicted['frac']
                predicted['Predicted Total Site Electricity MBtu'] = predicted['Predicted Total Site Electricity MBtu'] * predicted['frac']
              predicted = predicted.groupby('building_characteristics_report.{}'.format(slicer.lower().replace(' ', '_'))).sum()
              predicted['Predicted Per House Site Electricity MBtu'] = predicted['Predicted Total Site Electricity MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Electricity MBtu', 'Predicted Per House Site Electricity MBtu', 'Weight']
          elif 'gas' in fields:
              measured = pd.read_csv(os.path.join(datafiles_dir, 'Natural Gas Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['thmng_nrm_per_home']]
              measured['Measured Per House Site Gas MBtu'] = units_Therm2MBtu(measured['thmng_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(datafiles_dir, 'Natural Gas Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted['Weight'] = house_count / len(predicted.index.unique())
              predicted['Predicted Total Site Gas MBtu'] = units_Therm2MBtu(predicted['simulation_output_report.total_site_natural_gas_therm'] * predicted['Weight'])
              if 'frac' in predicted.columns:
                predicted['Weight'] = predicted['Weight'] * predicted['frac']
                predicted['Predicted Total Site Gas MBtu'] = predicted['Predicted Total Site Gas MBtu'] * predicted['frac']
              predicted = predicted.groupby('building_characteristics_report.{}'.format(slicer.lower().replace(' ', '_'))).sum()
              predicted['Predicted Per House Site Gas MBtu'] = predicted['Predicted Total Site Gas MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Gas MBtu', 'Predicted Per House Site Gas MBtu', 'Weight']
          elif 'other' in fields:
              measured = pd.read_csv(os.path.join(datafiles_dir, 'Other Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['thmoth_nrm_per_home']]
              measured['Measured Per House Site Other MBtu'] = units_Therm2MBtu(measured['thmoth_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(datafiles_dir, 'Other Consumption {}.tsv'.format(slicer)), index_col=['Dependency={}'.format(slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted['Weight'] = house_count / len(predicted.index.unique())
              predicted['Predicted Total Site Other MBtu'] = predicted['simulation_output_report.total_site_other_fuel_mbtu'] * predicted['Weight']
              if 'frac' in predicted.columns:
                predicted['Weight'] = predicted['Weight'] * predicted['frac']
                predicted['Predicted Total Site Other MBtu'] = predicted['Predicted Total Site Other MBtu'] * predicted['frac']
              predicted = predicted.groupby('building_characteristics_report.{}'.format(slicer.lower().replace(' ', '_'))).sum()
              predicted['Predicted Per House Site Other MBtu'] = predicted['Predicted Total Site Other MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Other MBtu', 'Predicted Per House Site Other MBtu', 'Weight']              
        elif num_slices == 2:
          sub_slicer = slicer.replace("Location Region ","") # Assumes first slice is Location Region; will error out if not
          if sub_slicer == slicer:
            sys.exit("Unexpected slicer: %s" % slicer)
          if 'electricity' in fields:
              measured = pd.read_csv(os.path.join(datafiles_dir, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency=Location Region', 'Dependency={}'.format(sub_slicer)], sep='\t')[['kwhel_nrm_per_home']]
              measured['Measured Per House Site Electricity MBtu'] = units_kWh2MBtu(measured['kwhel_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(datafiles_dir, 'Electricity Consumption {}.tsv'.format(slicer)), index_col=['Dependency=Location Region', 'Dependency={}'.format(sub_slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted['Weight'] = house_count / len(predicted.index.unique())
              predicted['Predicted Total Site Electricity MBtu'] = units_kWh2MBtu(predicted['simulation_output_report.total_site_electricity_kwh']) * predicted['Weight']
              predicted = predicted.rename(columns={"building_characteristics_report.Location Region": "Dependency=Location Region", "building_characteristics_report.{}".format(sub_slicer.lower().replace(' ', '_')): "Dependency={}".format(sub_slicer.lower().replace(' ', '_'))})
              if 'frac' in predicted.columns:
                predicted['Weight'] = predicted['Weight'] * predicted['frac']
                predicted['Predicted Total Site Electricity MBtu'] = predicted['Predicted Total Site Electricity MBtu'] * predicted['frac']
              predicted = predicted.groupby(['Dependency=Location Region', 'Dependency={}'.format(sub_slicer)]).sum()
              predicted['Predicted Per House Site Electricity MBtu'] = predicted['Predicted Total Site Electricity MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Electricity MBtu', 'Predicted Per House Site Electricity MBtu', 'Weight']
          elif 'gas' in fields:
              measured = pd.read_csv(os.path.join(datafiles_dir, 'Natural Gas Consumption {}.tsv'.format(slicer)), index_col=['Dependency=Location Region', 'Dependency={}'.format(sub_slicer)], sep='\t')[['thmng_nrm_per_home']]
              measured['Measured Per House Site Gas MBtu'] = units_Therm2MBtu(measured['thmng_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(datafiles_dir, 'Natural Gas Consumption {}.tsv'.format(slicer)), index_col=['Dependency=Location Region', 'Dependency={}'.format(sub_slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted['Weight'] = house_count / len(predicted.index.unique())
              predicted['Predicted Total Site Gas MBtu'] = units_Therm2MBtu(predicted['simulation_output_report.total_site_natural_gas_therm']) * predicted['Weight']
              predicted = predicted.rename(columns={"building_characteristics_report.Location Region": "Dependency=Location Region", "building_characteristics_report.{}".format(sub_slicer.lower().replace(' ', '_')): "Dependency={}".format(sub_slicer.lower().replace(' ', '_'))})
              if 'frac' in predicted.columns:
                predicted['Weight'] = predicted['Weight'] * predicted['frac']
                predicted['Predicted Total Site Gas MBtu'] = predicted['Predicted Total Site Gas MBtu'] * predicted['frac']
              predicted = predicted.groupby(['Dependency=Location Region', 'Dependency={}'.format(sub_slicer)]).sum()
              predicted['Predicted Per House Site Gas MBtu'] = predicted['Predicted Total Site Gas MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Gas MBtu', 'Predicted Per House Site Gas MBtu', 'Weight']
          elif 'other' in fields:
              measured = pd.read_csv(os.path.join(datafiles_dir, 'Other Consumption {}.tsv'.format(slicer)), index_col=['Dependency=Location Region', 'Dependency={}'.format(sub_slicer)], sep='\t')[['thmoth_nrm_per_home']]
              measured['Measured Per House Site Other MBtu'] = units_Therm2MBtu(measured['thmoth_nrm_per_home'])
              house_count = pd.read_csv(os.path.join(datafiles_dir, 'Other Consumption {}.tsv'.format(slicer)), index_col=['Dependency=Location Region', 'Dependency={}'.format(sub_slicer)], sep='\t')[['Weight']].sum().values[0]
              predicted['Weight'] = house_count / len(predicted.index.unique())
              predicted['Predicted Total Site Other MBtu'] = predicted['simulation_output_report.total_site_other_fuel_mbtu'] * predicted['Weight']
              predicted = predicted.rename(columns={"building_characteristics_report.Location Region": "Dependency=Location Region", "building_characteristics_report.{}".format(sub_slicer.lower().replace(' ', '_')): "Dependency={}".format(sub_slicer.lower().replace(' ', '_'))})
              if 'frac' in predicted.columns:
                predicted['Weight'] = predicted['Weight'] * predicted['frac']
                predicted['Predicted Total Site Other MBtu'] = predicted['Predicted Total Site Other MBtu'] * predicted['frac']
              predicted = predicted.groupby(['Dependency=Location Region', 'Dependency={}'.format(sub_slicer)]).sum()
              predicted['Predicted Per House Site Other MBtu'] = predicted['Predicted Total Site Other MBtu'] / predicted['Weight']
              cols = ['Measured Per House Site Other MBtu', 'Predicted Per House Site Other MBtu', 'Weight']              
        else:
            sys.exit("Unexpected num_slices: %s" % num_slices)
           
        df = measured.join(predicted)[cols]
        df = df.reset_index()
        marker_labels = df.ix[:,0]
        if marker_color:
            marker_colors = df['Dependency=Location Region']
            marker_colors = [list(set(marker_colors)).index(i) for i in marker_colors.tolist()]          
            marker_labels = zip(df['Dependency=Location Region'], df['Dependency={}'.format(sub_slicer)])

        draw_scatter_plot(df, cols, marker_labels, slicer, weighted_area=weighted_area, setlims=setlims,
                          marker_colors=marker_colors, marker_shapes=marker_shapes, size=size,
                          marker_color_all=marker_color_all, show_labels=show_labels, leg_label=leg_label,
                          max_marker_size=max_marker_size)
    if save:
        filename = os.path.join(datafiles_dir, 'Scatter_{}slice_{}.png'.format(num_slices, fields))
        plt.savefig(filename, bbox_inches='tight', dpi=200)
        trim_white(filename)
        plt.close()

def remove_upgrades(df):
    if 'simulation_output_report.upgrade_name' in df.columns:
      df = df[pd.isnull(df['simulation_output_report.upgrade_name'])]
    else:
      for col in df.columns:
          if col.endswith('.run_measure'):
              df = df[df[col]==0]
    return df
        
class TSV():
    
    def __init__(self, file):
        self.session = pd.read_csv(file)
        self.session = self.weather_normalize(self.session)
        self.recs_to_resstock_enum_map = {
                                          'Dependency=Location Region': {1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'},
                                          'Dependency=Federal Poverty Level': {'0-50': '0-50', '50-100': '50-100', '100-150': '100-150', '150-200': '150-200', '200-250': '200-250', '250-300': '250-300', '300+': '300+'},
                                          'Dependency=Vintage': {'1950-pre': '<1950', '1950s': '1950s', '1960s': '1960s', '1970s': '1970s', '1980s': '1980s', '1990s': '1990s', '2000s': '2000s'},
                                          'Dependency=Heating Fuel': {'Electricity': 'Electricity', 'Natural Gas': 'Natural Gas', 'Propane/LPG': 'Propane/LPG', 'Fuel Oil': 'Fuel Oil', 'Other Fuel': 'Other Fuel', 'None': 'None'},
                                          'Dependency=Geometry House Size': {'0-1499': '0-1499', '1500-2499': '1500-2499', '2500-3499': '2500-3499', '3500+': '3500+'}
                                          }
        self.recs_to_resstock_cols_map = {
                                          'Size': 'Dependency=Geometry House Size', 
                                          'yearmaderange': 'Dependency=Vintage', 
                                          'fuelheat': 'Dependency=Heating Fuel', 
                                          'CR': 'Dependency=Location Region', 
                                          'FPL_BINS': 'Dependency=Federal Poverty Level', 
                                          'nweight': 'Weight'
                                          }
        
    def weather_normalize(self, df):
    
        df = df[df['hdd65']>0]
        df = df[df['cdd65']>0]

        # electricity
        df['kwhsph_nrm'] = df['kwhsph'] * ( df['hdd30yr'] / df['hdd65'] )
        df['kwhcol_nrm'] = df['kwhcol'] * ( df['cdd30yr'] / df['cdd65'] )
        df['kwhel_nrm'] = df['kwhsph_nrm'] + df['kwhcol_nrm'] + df['kwhwth'] + df['kwhrfg'] + df['kwhoth']
        
        # natural gas
        df['btungsph_nrm'] = df['btungsph'] * ( df['hdd30yr'] / df['hdd65'] )
        df['btung_nrm'] = df['btungsph_nrm'] + df['btungwth'] + df['btungoth']
        
        # propane
        df['btulpsph_nrm'] = df['btulpsph'] * ( df['hdd30yr'] / df['hdd65'] )
        df['btulp_nrm'] = df['btulpsph_nrm'] + df['btulpwth'] + df['btulpoth']
        
        # fuel oil
        df['btufosph_nrm'] = df['btufosph'] * ( df['hdd30yr'] / df['hdd65'] )
        df['btufo_nrm'] = df['btufosph_nrm'] + df['btufowth'] + df['btufooth']
        
        df['btuoth_nrm'] = df['btulp_nrm'] + df['btufo_nrm']
    
        return df
        
    def create_consumption_tsv(self, cols, nrm, groups):
      '''Creates tsv files with actual recs consumption (weather-normalized), sliced by various meta parameters.
      
      Args:
        cols (list): Meta parameters + weight columns. Must be found in keys of self.recs_to_resstock_cols_map.
        nrm (str): Normalized fuel column. These are calculated in the weather_normalize method.
        groups (list): Enumerations corresponding to meta parameters. Must be found in keys of self.recs_to_resstock_enum_map.
        
      Returns:
        A pandas dataframe that is eventually written to csv, in the data/recs/outputs folder.
      
      '''
      df = self.session
      df = df[cols + [nrm]]
      if 'btu' in nrm:
        nrm = nrm.replace('btu', 'thm')
        df[nrm] = df.apply(lambda x: units_Btu2Therm(x[nrm.replace('thm', 'btu')]), axis=1)
      df = df.rename(columns=self.recs_to_resstock_cols_map)
      for group in groups:
        df[group] = df[group].replace(self.recs_to_resstock_enum_map[group])
      df = df.groupby(groups)
      count = df.agg(['count']).ix[:, 0]
      weight = df.agg(['sum'])['Weight']
      df = df[[nrm]].sum()
      df['Count'] = count
      df['Weight'] = weight
      df['{}_per_home'.format(nrm)] = df[nrm] / df['Count']
      df['{}_total'.format(nrm)] = df['{}_per_home'.format(nrm)] * df['Weight']
      df = df.reset_index()
      for group in groups:
        df[group] = pd.Categorical(df[group], self.recs_to_resstock_enum_map[group].values())
      df = df.sort_values(by=groups).set_index(groups)
      return df
      
if __name__ == '__main__':
    
  parser = argparse.ArgumentParser()
    
  parser.add_argument('--zip_or_dir', default='../../../../buildstockdb/data/analysis_results/resstock_national_results.zip', help='Relative path containing the data_point files (zip or dir).')
  parser.add_argument('--source', default='./MLR/recs.csv', help='Source of actual energy usage.')
  parser.add_argument('--tsv_file', default='../../../../buildstockdb/data/housing_characteristics/Federal Poverty Level.tsv', help='File with fractions.')
  args = parser.parse_args()
    
  datafiles_dir = './outputs'
  if not os.path.exists(datafiles_dir):
    os.makedirs(datafiles_dir)
  tsv = TSV(args.source)
  
  categories = {
               'Electricity Consumption Location Region.tsv': {'cols': ['CR', 'nweight'], 'nrm': 'kwhel_nrm', 'groups': ['Dependency=Location Region']},
               'Electricity Consumption Vintage.tsv': {'cols': ['yearmaderange', 'nweight'], 'nrm': 'kwhel_nrm', 'groups': ['Dependency=Vintage']}, 
               'Electricity Consumption Heating Fuel.tsv': {'cols': ['fuelheat', 'nweight'], 'nrm': 'kwhel_nrm', 'groups': ['Dependency=Heating Fuel']},
               'Electricity Consumption Geometry House Size.tsv': {'cols': ['Size', 'nweight'], 'nrm': 'kwhel_nrm', 'groups': ['Dependency=Geometry House Size']}, 
               'Electricity Consumption Location Region Vintage.tsv': {'cols': ['CR', 'yearmaderange', 'nweight'], 'nrm': 'kwhel_nrm', 'groups': ['Dependency=Location Region', 'Dependency=Vintage']}, 
               'Electricity Consumption Location Region Heating Fuel.tsv': {'cols': ['CR', 'fuelheat', 'nweight'], 'nrm': 'kwhel_nrm', 'groups': ['Dependency=Location Region', 'Dependency=Heating Fuel']},
               'Natural Gas Consumption Location Region.tsv': {'cols': ['CR', 'nweight'], 'nrm': 'btung_nrm', 'groups': ['Dependency=Location Region']},
               'Natural Gas Consumption Vintage.tsv': {'cols': ['yearmaderange', 'nweight'], 'nrm': 'btung_nrm', 'groups': ['Dependency=Vintage']}, 
               'Natural Gas Consumption Heating Fuel.tsv': {'cols': ['fuelheat', 'nweight'], 'nrm': 'btung_nrm', 'groups': ['Dependency=Heating Fuel']},
               'Natural Gas Consumption Geometry House Size.tsv': {'cols': ['Size', 'nweight'], 'nrm': 'btung_nrm', 'groups': ['Dependency=Geometry House Size']},
               'Natural Gas Consumption Location Region Vintage.tsv': {'cols': ['CR', 'yearmaderange', 'nweight'], 'nrm': 'btung_nrm', 'groups': ['Dependency=Location Region', 'Dependency=Vintage']},
               'Natural Gas Consumption Location Region Heating Fuel.tsv': {'cols': ['CR', 'fuelheat', 'nweight'], 'nrm': 'btung_nrm', 'groups': ['Dependency=Location Region', 'Dependency=Heating Fuel']},
               'Other Consumption Location Region.tsv': {'cols': ['CR', 'nweight'], 'nrm': 'btuoth_nrm', 'groups': ['Dependency=Location Region']},
               'Other Consumption Vintage.tsv': {'cols': ['yearmaderange', 'nweight'], 'nrm': 'btuoth_nrm', 'groups': ['Dependency=Vintage']},
               'Other Consumption Heating Fuel.tsv': {'cols': ['fuelheat', 'nweight'], 'nrm': 'btuoth_nrm', 'groups': ['Dependency=Heating Fuel']},
               'Other Consumption Geometry House Size.tsv': {'cols': ['Size', 'nweight'], 'nrm': 'btuoth_nrm', 'groups': ['Dependency=Geometry House Size']},
               'Other Consumption Location Region Vintage.tsv': {'cols': ['CR', 'yearmaderange', 'nweight'], 'nrm': 'btuoth_nrm', 'groups': ['Dependency=Location Region', 'Dependency=Vintage']},
               'Other Consumption Location Region Heating Fuel.tsv': {'cols': ['CR', 'fuelheat', 'nweight'], 'nrm': 'btuoth_nrm', 'groups': ['Dependency=Location Region', 'Dependency=Heating Fuel']}
               }
  
  if args.tsv_file:
  
    tsv_to_recs_enum_map = {
                            'Federal Poverty Level': 'FPL_BINS'
                            }  
  
    categories['Electricity Consumption {}'.format(os.path.basename(args.tsv_file))] = {'cols': [tsv_to_recs_enum_map[os.path.basename(args.tsv_file).replace('.tsv', '')], 'nweight'], 'nrm': 'kwhel_nrm', 'groups': ['Dependency={}'.format(os.path.basename(args.tsv_file).replace('.tsv', ''))]}
    categories['Natural Gas Consumption {}'.format(os.path.basename(args.tsv_file))] = {'cols': [tsv_to_recs_enum_map[os.path.basename(args.tsv_file).replace('.tsv', '')], 'nweight'], 'nrm': 'btung_nrm', 'groups': ['Dependency={}'.format(os.path.basename(args.tsv_file).replace('.tsv', ''))]}
    categories['Other Consumption {}'.format(os.path.basename(args.tsv_file))] = {'cols': [tsv_to_recs_enum_map[os.path.basename(args.tsv_file).replace('.tsv', '')], 'nweight'], 'nrm': 'btuoth_nrm', 'groups': ['Dependency={}'.format(os.path.basename(args.tsv_file).replace('.tsv', ''))]}
    categories['Electricity Consumption Location Region {}'.format(os.path.basename(args.tsv_file))] = {'cols': ['CR', tsv_to_recs_enum_map[os.path.basename(args.tsv_file).replace('.tsv', '')], 'nweight'], 'nrm': 'kwhel_nrm', 'groups': ['Dependency=Location Region', 'Dependency={}'.format(os.path.basename(args.tsv_file).replace('.tsv', ''))]}
    categories['Natural Gas Consumption Location Region {}'.format(os.path.basename(args.tsv_file))] = {'cols': ['CR', tsv_to_recs_enum_map[os.path.basename(args.tsv_file).replace('.tsv', '')], 'nweight'], 'nrm': 'btung_nrm', 'groups': ['Dependency=Location Region', 'Dependency={}'.format(os.path.basename(args.tsv_file).replace('.tsv', ''))]}
    categories['Other Consumption Location Region {}'.format(os.path.basename(args.tsv_file))] = {'cols': ['CR', tsv_to_recs_enum_map[os.path.basename(args.tsv_file).replace('.tsv', '')], 'nweight'], 'nrm': 'btuoth_nrm', 'groups': ['Dependency=Location Region', 'Dependency={}'.format(os.path.basename(args.tsv_file).replace('.tsv', ''))]}

  for tsv_file, arguments in categories.items():
                   
      print tsv_file
      df = tsv.create_consumption_tsv(arguments['cols'], arguments['nrm'], arguments['groups'])
      df.to_csv(os.path.join(datafiles_dir, tsv_file), sep='\t')

  slices = [
            'Vintage',
            'Heating Fuel',
            'Geometry House Size',
            ]
  slices += [os.path.basename(args.tsv_file).replace('.tsv', '')]

  do_plot(args.zip_or_dir, datafiles_dir, slices=slices, fields='electricity_and_gas_perhouse', save=True, setlims=[0,None], num_slices=1, tsv_file=args.tsv_file)
  do_plot(args.zip_or_dir, datafiles_dir, slices=slices, fields='electricity_perhouse', save=True, setlims=[0,None], num_slices=1, tsv_file=args.tsv_file)
  do_plot(args.zip_or_dir, datafiles_dir, slices=slices, fields='gas_perhouse', save=True, setlims=[0,None], num_slices=1, tsv_file=args.tsv_file)
  do_plot(args.zip_or_dir, datafiles_dir, slices=slices, fields='other_perhouse', save=True, setlims=[0,None], num_slices=1, tsv_file=args.tsv_file)

  slices = [
            'Location Region Vintage',
            'Location Region Heating Fuel',
            'Location Region Geometry House Size',
            'Location Region Federal Poverty Level'
            ]

  # do_plot(args.zip_or_dir, datafiles_dir, slices=slices, fields='electricity_perhouse', save=True, size='medium', marker_color=True, setlims=[0,None], num_slices=2)
  # do_plot(args.zip_or_dir, datafiles_dir, slices=slices, fields='gas_perhouse', save=True, size='medium', marker_color=True, setlims=[0,None], num_slices=2)
