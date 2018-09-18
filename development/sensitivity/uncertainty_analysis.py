"""Uncertainty analysis of routing simulations

Thomas Dickson
thomas.dickson@soton.ac.uk
14/09/2018
"""

import os, sys, glob, re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap

plt.rcParams['savefig.dpi'] = 400
plt.rcParams['figure.autolayout'] = True
plt.rcParams['figure.figsize'] = 10, 6
plt.rcParams['axes.labelsize'] = 14
plt.rcParams['axes.titlesize'] = 20
plt.rcParams['font.size'] = 16
plt.rcParams['lines.linewidth'] = 2.0
plt.rcParams['lines.markersize'] = 8
plt.rcParams['legend.fontsize'] = 12
plt.rcParams['text.usetex'] = True
plt.rcParams['font.serif'] = "cm"
plt.rcParams['text.latex.preamble'] = """\\usepackage{subdepth},
                                         \\usepackage{type1cm}"""


def plot_scatter_error(df):
    plt.figure()
    plt.errorbar(df["perf"], df["t"], yerr=df["u"])
    plt.xlabel(r"Performance uncertainty \%")
    plt.ylabel("Voyaging time (hrs)")
    plt.show()


def atoi(text):
    return int(text) if text.isdigit() else text


def natural_keys(text):
    '''
    alist.sort(key=natural_keys) sorts in human order
    http://nedbatchelder.com/blog/200712/human_sorting.html
    (See Toothy's implementation in the comments)
    '''
    return [ atoi(c) for c in re.split('(\d+)', text) ]


def plot_varied_grid(lon1, lat1, lon2, lat2, r1, r2, r3, fname, fill=1.0):
    """Plot routes generated as a function of different grid sizes."""
    add_param = fill
    res = 'i'
    plt.figure(figsize=(6, 10))
    map = Basemap(projection='merc',
                  ellps='WGS84',
                  lat_0=(r1["x2"].min() + r1["x2"].max())/2,
                  lon_0=(r1["x1"].min() + r1["x1"].max())/2,
                  llcrnrlon=r1["x1"].min()-add_param,
                  llcrnrlat=r1["x2"].min()-add_param,
                  urcrnrlon=r1["x1"].max()+add_param,
                  urcrnrlat=r1["x2"].max()+add_param,
                  resolution=res)  # f = fine resolution
    map.drawcoastlines()
    r_s_x, r_s_y = map(lon2, lat2)
    map.scatter(r_s_x, r_s_y, color='red', s=50, label='Start')
    r_f_x, r_f_y = map(lon1, lat1)
    parallels = np.arange(-90.0, 90.0, 20.)
    map.drawparallels(parallels, labels=[1, 0, 0, 0])
    meridians = np.arange(180., 360., 20.)
    map.drawmeridians(meridians, labels=[0, 0, 0, 1])
    map.scatter(r_f_x, r_f_y, color='blue', s=50, label='Finish')

    x_r1, y_r1 = map(r1["x1"].values, r1["x2"].values)
    map.plot(x_r1, y_r1, label="320 nodes")
    x_r2, y_r2 = map(r2["x1"].values, r2["x2"].values)
    map.plot(x_r1, y_r1, label="160 nodes")
    x_r3, y_r3 = map(r3["x1"].values, r3["x2"].values)
    map.plot(x_r1, y_r1, label="80 nodes")
    plt.legend(loc='lower right', fancybox=True, framealpha=0.5)
    plt.savefig(fname)
    plt.show()
    plt.clf()


def plot_varied_grid_results():
    dir_path = os.path.dirname(os.path.realpath(__file__))+"/"
    fname = dir_path+"discretized_routing.png"
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    r1 = pd.read_csv(dir_path+"disc_routesp1")
    r2 = pd.read_csv(dir_path+"disc_routesp2")
    r3 = pd.read_csv(dir_path+"disc_routesp3")
    plot_varied_grid(lon1, lat1, lon2, lat2, r1, r2, r3, fname)


def plot_ensemble_results(lon1, lat1, lon2, lat2, df_paths, df_results, fname, fill=1.0):
    add_param = fill
    res = 'i'
    plt.figure(figsize=(10, 6))
    map = Basemap(projection='merc',
                  ellps='WGS84',
                  lat_0=(lat1+lat2)/2,
                  lon_0=(lon1+lon2)/2,
                  llcrnrlon=df_paths[0]["x1"].min()-add_param,
                  llcrnrlat=df_paths[0]["x2"].min()-add_param,
                  urcrnrlon=df_paths[0]["x1"].max()+add_param,
                  urcrnrlat=df_paths[0]["x2"].max()+add_param,
                  resolution=res)  # f = fine resolution
    map.drawcoastlines()
    r_s_x, r_s_y = map(lon2, lat2)
    map.scatter(r_s_x, r_s_y, color='red', s=50, label='Start')
    r_f_x, r_f_y = map(lon1, lat1)
    parallels = np.arange(-90.0, 90.0, 20.)
    map.drawparallels(parallels, labels=[1, 0, 0, 0])
    meridians = np.arange(180., 360., 20.)
    map.drawmeridians(meridians, labels=[0, 0, 0, 1])
    map.scatter(r_f_x, r_f_y, color='blue', s=50, label='Finish')
    for counter, value in enumerate(df_paths):
        x, y = map(value["x1"].values, value["x2"].values)
        map.plot(x, y, label="Ensemble {}, {:f} hrs".format(counter, df_results[counter]))
    plt.legend(loc='upper center', bbox_to_anchor=(0.5, 1.05),
               ncol=5, fancybox=True, shadow=True, prop={'size': 6})
    plt.savefig(fname)
    plt.show()
    plt.clf()


def plot_ensemble_weather_simulations_results():
    """Plotting the results from 10 ensemble weather scenario simulations."""
    # load the dataframes containing the different routing results
    dir_path = os.path.dirname(os.path.realpath(__file__))
    alist = glob.glob(dir_path+"/_route*")
    alist.sort(key=natural_keys)
    df_list = [pd.read_csv(i) for i in alist]
    times = [417.6349510836086, 411.1519616538428, 416.7225335095536, 415.43665504229637, 410.02199303056454, 412.7209783033134, 416.16703271050164, 417.204454754556, 417.71980730920177, 426.33400184536436]
    fname = dir_path+"/ensemble_routes_plot.png"
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    plot_ensemble_results(lon1, lat1, lon2, lat2, df_list, times, fname, fill=0.2)

    # create list of the dataframes
    # load the routing results
    # plot each route with the associated ensemble weather scenario and the label

if __name__ == "__main__":
    plot_ensemble_weather_simulations_results()
