import os, sys, glob, re
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('agg')
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
# plt.rcParams['text.usetex'] = True
plt.rcParams['font.serif'] = "cm"
plt.rcParams['text.latex.preamble'] = """\\usepackage{subdepth},
                                         \\usepackage{type1cm}"""


def plot_isochrones(x, y, et, jt, r, fname):
    """Plot the isochrones calculated as a consequence of a voyage being modelled."""
    add_param = 0.2
    plt.figure(figsize=(6, 10))
    map = Basemap(projection='merc',
                  ellps='WGS84',
                  lat_0=(y.min() + y.max())/2,
                  lon_0=(x.min() + x.max())/2,
                  llcrnrlon=x.min()-add_param,
                  llcrnrlat=y.min()-add_param,
                  urcrnrlon=x.max()+add_param,
                  urcrnrlat=y.max()+add_param,
                  resolution='i')  # f = fine resolution
    map.drawcoastlines()
    # r_s_x, r_s_y = map(lon2, lat2)
    # map.scatter(r_s_x, r_s_y, color='red', s=50, label='Start')
    # r_f_x, r_f_y = map(lon1, lat1)
    parallels = np.arange(-90.0, 90.0, 20.)
    map.drawparallels(parallels, labels=[1, 0, 0, 0])
    meridians = np.arange(180., 360., 20.)
    map.drawmeridians(meridians, labels=[0, 0, 0, 1])
    x_map, y_map = map(x, y)
    map.contourf(x_map, y_map, et)
    x_r1, y_r1 = map(r["x1"].values, r["x2"].values)
    map.plot(x_r1, y_r1, label="Shortest path", color='black')
    plt.legend(loc='lower right', fancybox=True, framealpha=0.5)
    plt.title("Journey time {0:.2f} hrs".format(jt))
    plt.tight_layout()
    plt.savefig(fname)
    # plt.show()
    plt.clf()


def inspect_route():
    """Script to inspect route."""
    name = "/boeckv2/"
    # name = "/tongiaki/"
    nodes = name + "_5.0_nm_"
    path = os.path.dirname(os.path.realpath(__file__)) + nodes
    x = pd.read_csv(path+"x_locs").values
    y = pd.read_csv(path+"y_locs").values
    et = pd.read_csv(path+"earliest_times").values
    jt = pd.read_csv(path+"time").values
    r = pd.read_csv(path+"route")
    fname = path + "route_plot.png"
    plot_isochrones(x, y, et, jt[0][0], r, fname)


def plot_varied_grid(lon1, lat1, lon2, lat2, r1, r2, r3, t1, t2, t3, fname, fill=1.0):
    """Plot routes generated as a function of different grid sizes."""
    add_param = fill
    res = 'i'
    plt.figure(figsize=(10, 6))
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
    map.plot(x_r1, y_r1, label="5.0 nm, {0:.2f}".format(t1))
    x_r2, y_r2 = map(r2["x1"].values, r2["x2"].values)
    map.plot(x_r2, y_r2, label="10.0 nm, {0:.2f}".format(t2))
    x_r3, y_r3 = map(r3["x1"].values, r3["x2"].values)
    map.plot(x_r3, y_r3, label="15.0 nm, {0:.2f}".format(t3))
    plt.legend(bbox_to_anchor=(1.1, 1.05), fancybox=True, framealpha=0.5)
    plt.savefig(fname)
    plt.show()
    plt.clf()


def plot_varied_grid_results():
    dir_path = os.path.dirname(os.path.realpath(__file__)) + "/boeckv2/" 
    fname = dir_path+"boeck_july_1976_discretized_routing.png"
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    t1 = pd.read_csv(dir_path+"_5.0_nm_time").values[0][0]
    t2 = pd.read_csv(dir_path+"_10.0_nm_time").values[0][0]
    t3 = pd.read_csv(dir_path+"_15.0_nm_time").values[0][0]
    r1 = pd.read_csv(dir_path+"_5.0_nm_route")
    r2 = pd.read_csv(dir_path+"_10.0_nm_route")
    r3 = pd.read_csv(dir_path+"_15.0_nm_route")
    plot_varied_grid(lon1, lat1, lon2, lat2, r1, r2, r3, t1, t2, t3, fname, fill=2.5)

if __name__ == "__main__":
    # inspect_route()
    plot_varied_grid_results()