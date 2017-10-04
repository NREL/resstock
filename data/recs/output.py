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
        
class Create_DFs():
    
    def __init__(self, file):
        self.session = pd.read_csv(file)
        self.session = self.weather_normalize(self.session)
        
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
        
    def electricity_consumption_location_region(self):
        df = self.session
        df = df[['CR', 'kwhel_nrm', 'nweight']]
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df = df.groupby(['Dependency=Location Region'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwhel_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwhel_nrm_per_home'] = df['kwhel_nrm'] / df['Count']
        df['kwhel_nrm_total'] = df['kwhel_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df = df.sort_values(by=['Dependency=Location Region']).set_index(['Dependency=Location Region'])             
        return df
        
    def electricity_consumption_vintage(self):
        df = self.session
        df = df[['yearmaderange', 'kwhel_nrm', 'nweight']]
        df = df.rename(columns={'yearmaderange': 'Dependency=Vintage', 'nweight': 'Weight'})
        df['Dependency=Vintage'] = df['Dependency=Vintage'].replace({'1950-pre': '<1950'})
        df = df.groupby(['Dependency=Vintage'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwhel_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwhel_nrm_per_home'] = df['kwhel_nrm'] / df['Count']
        df['kwhel_nrm_total'] = df['kwhel_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Vintage']).set_index(['Dependency=Vintage'])             
        return df

    def electricity_consumption_heating_fuel(self):
        df = self.session
        df = df[['fuelheat', 'kwhel_nrm', 'nweight']]
        df = df.rename(columns={'fuelheat': 'Dependency=Heating Fuel', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwhel_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwhel_nrm_per_home'] = df['kwhel_nrm'] / df['Count']
        df['kwhrl_nrm_total'] = df['kwhel_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df = df.sort_values(by=['Dependency=Heating Fuel']).set_index(['Dependency=Heating Fuel'])             
        return df
        
    def electricity_consumption_geometry_house_size(self):
        df = self.session
        df = df[['Size', 'kwhel_nrm', 'nweight']]
        df = df.rename(columns={'Size': 'Dependency=Geometry House Size', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Geometry House Size'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwhel_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwhel_nrm_per_home'] = df['kwhel_nrm'] / df['Count']
        df['kwhrl_nrm_total'] = df['kwhel_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df = df.sort_values(by=['Dependency=Geometry House Size']).set_index(['Dependency=Geometry House Size'])             
        return df
        
    def electricity_consumption_federal_poverty_level(self):
        df = self.session
        df = df[['FPL_BINS', 'kwhel_nrm', 'nweight']]
        df = df.rename(columns={'FPL_BINS': 'Dependency=Federal Poverty Level', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Federal Poverty Level'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwhel_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwhel_nrm_per_home'] = df['kwhel_nrm'] / df['Count']
        df['kwhrl_nrm_total'] = df['kwhel_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Federal Poverty Level'] = pd.Categorical(df['Dependency=Federal Poverty Level'], ['0-50', '50-100', '100-150', '150-200', '200-250', '250-300', '300+'])
        df = df.sort_values(by=['Dependency=Federal Poverty Level']).set_index(['Dependency=Federal Poverty Level'])
        return df
        
    def electricity_consumption_location_region_vintage(self):
        df = self.session
        df = df[['CR', 'yearmaderange', 'kwhel_nrm', 'nweight']]
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'yearmaderange': 'Dependency=Vintage', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df['Dependency=Vintage'] = df['Dependency=Vintage'].replace({'1950-pre': '<1950'})
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwhel_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwhel_nrm_per_home'] = df['kwhel_nrm'] / df['Count']
        df['kwhrl_nrm_total'] = df['kwhel_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Vintage'])
        return df
        
    def electricity_consumption_location_region_heating_fuel(self):
        df = self.session
        df = df[['CR', 'fuelheat', 'kwhel_nrm', 'nweight']]
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'fuelheat': 'Dependency=Heating Fuel', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df = df.groupby(['Dependency=Location Region', 'Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwhel_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwhel_nrm_per_home'] = df['kwhel_nrm'] / df['Count']
        df['kwhrl_nrm_total'] = df['kwhel_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Heating Fuel']).set_index(['Dependency=Location Region', 'Dependency=Heating Fuel'])
        return df
        
    def electricity_consumption_location_region_federal_poverty_level(self):
        df = self.session
        df = df[['CR', 'FPL_BINS', 'kwhel_nrm', 'nweight']]
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'FPL_BINS': 'Dependency=Federal Poverty Level', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df = df.groupby(['Dependency=Location Region', 'Dependency=Federal Poverty Level'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['kwhel_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['kwhel_nrm_per_home'] = df['kwhel_nrm'] / df['Count']
        df['kwhrl_nrm_total'] = df['kwhel_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df['Dependency=Federal Poverty Level'] = pd.Categorical(df['Dependency=Federal Poverty Level'], ['0-50', '50-100', '100-150', '150-200', '200-250', '250-300', '300+'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Federal Poverty Level']).set_index(['Dependency=Location Region', 'Dependency=Federal Poverty Level'])
        return df
        
    def natural_gas_consumption_location_region(self):
        df = self.session
        df = df[['CR', 'btung_nrm', 'nweight']]
        df['thmng_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung_nrm), axis=1)
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df = df.groupby(['Dependency=Location Region'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmng_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmng_nrm_per_home'] = df['thmng_nrm'] / df['Count']
        df['thmng_nrm_total'] = df['thmng_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df = df.sort_values(by=['Dependency=Location Region']).set_index(['Dependency=Location Region'])             
        return df
        
    def natural_gas_consumption_vintage(self):
        df = self.session
        df = df[['yearmaderange', 'btung_nrm', 'nweight']]
        df['thmng_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung_nrm), axis=1)
        df = df.rename(columns={'yearmaderange': 'Dependency=Vintage', 'nweight': 'Weight'})
        df['Dependency=Vintage'] = df['Dependency=Vintage'].replace({'1950-pre': '<1950'})
        df = df.groupby(['Dependency=Vintage'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmng_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmng_nrm_per_home'] = df['thmng_nrm'] / df['Count']
        df['thmng_nrm_total'] = df['thmng_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Vintage']).set_index(['Dependency=Vintage'])
        return df

    def natural_gas_consumption_heating_fuel(self):
        df = self.session
        df = df[['fuelheat', 'btung_nrm', 'nweight']]
        df['thmng_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung_nrm), axis=1)
        df = df.rename(columns={'fuelheat': 'Dependency=Heating Fuel', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmng_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmng_nrm_per_home'] = df['thmng_nrm'] / df['Count']
        df['thmng_nrm_total'] = df['thmng_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df = df.sort_values(by=['Dependency=Heating Fuel']).set_index(['Dependency=Heating Fuel'])             
        return df
        
    def natural_gas_consumption_geometry_house_size(self):
        df = self.session
        df = df[['Size', 'btung_nrm', 'nweight']]
        df['thmng_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung_nrm), axis=1)
        df = df.rename(columns={'Size': 'Dependency=Geometry House Size', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Geometry House Size'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmng_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmng_nrm_per_home'] = df['thmng_nrm'] / df['Count']
        df['thmng_nrm_total'] = df['thmng_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df = df.sort_values(by=['Dependency=Geometry House Size']).set_index(['Dependency=Geometry House Size'])             
        return df
        
    def natural_gas_consumption_federal_poverty_level(self):
        df = self.session
        df = df[['FPL_BINS', 'btung_nrm', 'nweight']]
        df['thmng_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung_nrm), axis=1)
        df = df.rename(columns={'FPL_BINS': 'Dependency=Federal Poverty Level', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Federal Poverty Level'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmng_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmng_nrm_per_home'] = df['thmng_nrm'] / df['Count']
        df['thmng_nrm_total'] = df['thmng_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Federal Poverty Level'] = pd.Categorical(df['Dependency=Federal Poverty Level'], ['0-50', '50-100', '100-150', '150-200', '200-250', '250-300', '300+'])
        df = df.sort_values(by=['Dependency=Federal Poverty Level']).set_index(['Dependency=Federal Poverty Level'])             
        return df
        
    def natural_gas_consumption_location_region_vintage(self):
        df = self.session
        df = df[['CR', 'yearmaderange', 'btung_nrm', 'nweight']]
        df['thmng_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung_nrm), axis=1)
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'yearmaderange': 'Dependency=Vintage', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df['Dependency=Vintage'] = df['Dependency=Vintage'].replace({'1950-pre': '<1950'})
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmng_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmng_nrm_per_home'] = df['thmng_nrm'] / df['Count']
        df['thmng_nrm_total'] = df['thmng_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Vintage'])             
        return df
        
    def natural_gas_consumption_location_region_heating_fuel(self):
        df = self.session
        df = df[['CR', 'fuelheat', 'btung_nrm', 'nweight']]
        df['thmng_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung_nrm), axis=1)
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'fuelheat': 'Dependency=Heating Fuel', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df = df.groupby(['Dependency=Location Region', 'Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmng_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmng_nrm_per_home'] = df['thmng_nrm'] / df['Count']
        df['thmng_nrm_total'] = df['thmng_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Heating Fuel']).set_index(['Dependency=Location Region', 'Dependency=Heating Fuel'])             
        return df
        
    def natural_gas_consumption_location_region_federal_poverty_level(self):
        df = self.session
        df = df[['CR', 'FPL_BINS', 'btung_nrm', 'nweight']]
        df['thmng_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btung_nrm), axis=1)
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'FPL_BINS': 'Dependency=Federal Poverty Level', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df = df.groupby(['Dependency=Location Region', 'Dependency=Federal Poverty Level'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmng_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmng_nrm_per_home'] = df['thmng_nrm'] / df['Count']
        df['thmng_nrm_total'] = df['thmng_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df['Dependency=Federal Poverty Level'] = pd.Categorical(df['Dependency=Federal Poverty Level'], ['0-50', '50-100', '100-150', '150-200', '200-250', '250-300', '300+'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Federal Poverty Level']).set_index(['Dependency=Location Region', 'Dependency=Federal Poverty Level'])             
        return df
        
    def other_consumption_location_region(self):
        df = self.session
        df = df[['CR', 'btuoth_nrm', 'nweight']]
        df['thmoth_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btuoth_nrm), axis=1)
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df = df.groupby(['Dependency=Location Region'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmoth_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmoth_nrm_per_home'] = df['thmoth_nrm'] / df['Count']
        df['thmoth_nrm_total'] = df['thmoth_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df = df.sort_values(by=['Dependency=Location Region']).set_index(['Dependency=Location Region'])             
        return df
        
    def other_consumption_vintage(self):
        df = self.session
        df = df[['yearmaderange', 'btuoth_nrm', 'nweight']]
        df['thmoth_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btuoth_nrm), axis=1)
        df = df.rename(columns={'yearmaderange': 'Dependency=Vintage', 'nweight': 'Weight'})
        df['Dependency=Vintage'] = df['Dependency=Vintage'].replace({'1950-pre': '<1950'})
        df = df.groupby(['Dependency=Vintage'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmoth_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmoth_nrm_per_home'] = df['thmoth_nrm'] / df['Count']
        df['thmoth_nrm_total'] = df['thmoth_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Vintage']).set_index(['Dependency=Vintage'])
        return df

    def other_consumption_heating_fuel(self):
        df = self.session
        df = df[['fuelheat', 'btuoth_nrm', 'nweight']]
        df['thmoth_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btuoth_nrm), axis=1)
        df = df.rename(columns={'fuelheat': 'Dependency=Heating Fuel', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmoth_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmoth_nrm_per_home'] = df['thmoth_nrm'] / df['Count']
        df['thmoth_nrm_total'] = df['thmoth_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df = df.sort_values(by=['Dependency=Heating Fuel']).set_index(['Dependency=Heating Fuel'])             
        return df
        
    def other_consumption_geometry_house_size(self):
        df = self.session
        df = df[['Size', 'btuoth_nrm', 'nweight']]
        df['thmoth_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btuoth_nrm), axis=1)
        df = df.rename(columns={'Size': 'Dependency=Geometry House Size', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Geometry House Size'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmoth_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmoth_nrm_per_home'] = df['thmoth_nrm'] / df['Count']
        df['thmoth_nrm_total'] = df['thmoth_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df = df.sort_values(by=['Dependency=Geometry House Size']).set_index(['Dependency=Geometry House Size'])             
        return df
        
    def other_consumption_federal_poverty_level(self):
        df = self.session
        df = df[['FPL_BINS', 'btuoth_nrm', 'nweight']]
        df['thmoth_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btuoth_nrm), axis=1)
        df = df.rename(columns={'FPL_BINS': 'Dependency=Federal Poverty Level', 'nweight': 'Weight'})
        df = df.groupby(['Dependency=Federal Poverty Level'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmoth_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmoth_nrm_per_home'] = df['thmoth_nrm'] / df['Count']
        df['thmoth_nrm_total'] = df['thmoth_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Federal Poverty Level'] = pd.Categorical(df['Dependency=Federal Poverty Level'], ['0-50', '50-100', '100-150', '150-200', '200-250', '250-300', '300+'])
        df = df.sort_values(by=['Dependency=Federal Poverty Level']).set_index(['Dependency=Federal Poverty Level'])             
        return df
        
    def other_consumption_location_region_vintage(self):
        df = self.session
        df = df[['CR', 'yearmaderange', 'btuoth_nrm', 'nweight']]
        df['thmoth_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btuoth_nrm), axis=1)
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'yearmaderange': 'Dependency=Vintage', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df['Dependency=Vintage'] = df['Dependency=Vintage'].replace({'1950-pre': '<1950'})
        df = df.groupby(['Dependency=Location Region', 'Dependency=Vintage'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmoth_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmoth_nrm_per_home'] = df['thmoth_nrm'] / df['Count']
        df['thmoth_nrm_total'] = df['thmoth_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df['Dependency=Vintage'] = pd.Categorical(df['Dependency=Vintage'], ['<1950', '1950s', '1960s', '1970s', '1980s', '1990s', '2000s'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Vintage']).set_index(['Dependency=Location Region', 'Dependency=Vintage'])             
        return df
        
    def other_consumption_location_region_heating_fuel(self):
        df = self.session
        df = df[['CR', 'fuelheat', 'btuoth_nrm', 'nweight']]
        df['thmoth_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btuoth_nrm), axis=1)
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'fuelheat': 'Dependency=Heating Fuel', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df = df.groupby(['Dependency=Location Region', 'Dependency=Heating Fuel'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmoth_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmoth_nrm_per_home'] = df['thmoth_nrm'] / df['Count']
        df['thmoth_nrm_total'] = df['thmoth_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Heating Fuel']).set_index(['Dependency=Location Region', 'Dependency=Heating Fuel'])             
        return df
        
    def other_consumption_location_region_federal_poverty_level(self):
        df = self.session
        df = df[['CR', 'FPL_BINS', 'btuoth_nrm', 'nweight']]
        df['thmoth_nrm'] = df.apply(lambda x: units_Btu2Therm(x.btuoth_nrm), axis=1)
        df = df.rename(columns={'CR': 'Dependency=Location Region', 'FPL_BINS': 'Dependency=Federal Poverty Level', 'nweight': 'Weight'})
        df['Dependency=Location Region'] = df['Dependency=Location Region'].replace({1: 'CR01', 2: 'CR02', 3: 'CR03', 4: 'CR04', 5: 'CR05', 6: 'CR06', 7: 'CR07', 8: 'CR08', 9: 'CR09', 10: 'CR10', 11: 'CR11', 12: 'CR12'})
        df = df.groupby(['Dependency=Location Region', 'Dependency=Federal Poverty Level'])
        count = df.agg(['count']).ix[:, 0]
        weight = df.agg(['sum'])['Weight']
        df = df[['thmoth_nrm']].sum()
        df['Count'] = count
        df['Weight'] = weight
        df['thmoth_nrm_per_home'] = df['thmoth_nrm'] / df['Count']
        df['thmoth_nrm_total'] = df['thmoth_nrm_per_home'] * df['Weight']
        df = df.reset_index()
        df['Dependency=Location Region'] = pd.Categorical(df['Dependency=Location Region'], ['CR01', 'CR02', 'CR03', 'CR04', 'CR05', 'CR06', 'CR07', 'CR08', 'CR09', 'CR10', 'CR11', 'CR12'])
        df['Dependency=Federal Poverty Level'] = pd.Categorical(df['Dependency=Federal Poverty Level'], ['0-50', '50-100', '100-150', '150-200', '200-250', '250-300', '300+'])
        df = df.sort_values(by=['Dependency=Location Region', 'Dependency=Federal Poverty Level']).set_index(['Dependency=Location Region', 'Dependency=Federal Poverty Level'])             
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
  dfs = Create_DFs(args.source)
  
  categories = [
               'Electricity Consumption Location Region',
               'Electricity Consumption Vintage', 
               'Electricity Consumption Heating Fuel',
               'Electricity Consumption Geometry House Size', 
               'Electricity Consumption Location Region Vintage', 
               'Electricity Consumption Location Region Heating Fuel', 
               'Natural Gas Consumption Location Region',
               'Natural Gas Consumption Vintage', 
               'Natural Gas Consumption Heating Fuel',
               'Natural Gas Consumption Geometry House Size',
               'Natural Gas Consumption Location Region Vintage',
               'Natural Gas Consumption Location Region Heating Fuel',
               'Other Consumption Location Region',
               'Other Consumption Vintage', 
               'Other Consumption Heating Fuel',
               'Other Consumption Geometry House Size',
               'Other Consumption Location Region Vintage',
               'Other Consumption Location Region Heating Fuel'               
               ]

  categories += ['Electricity Consumption {}'.format(os.path.basename(args.tsv_file).replace('.tsv', '')), 'Natural Gas Consumption {}'.format(os.path.basename(args.tsv_file).replace('.tsv', '')), 'Other Consumption {}'.format(os.path.basename(args.tsv_file).replace('.tsv', ''))]
  categories += ['Electricity Consumption Location Region {}'.format(os.path.basename(args.tsv_file).replace('.tsv', '')), 'Natural Gas Consumption Location Region {}'.format(os.path.basename(args.tsv_file).replace('.tsv', '')), 'Other Consumption Location Region {}'.format(os.path.basename(args.tsv_file).replace('.tsv', ''))]
    
  for category in categories:
                   
      print category
      method = getattr(dfs, category.lower().replace(' ', '_'))
      df = method()
      df.to_csv(os.path.join(datafiles_dir, '{}.tsv'.format(category)), sep='\t')
      
  slices = [
            # 'Location Region',
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
