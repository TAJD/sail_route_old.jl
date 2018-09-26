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


def plot_isochrones(x, y, et, jt, fname):
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
    map.scatter(x_map, y_map, color='red', s=10, label='Locations')
    plt.legend(loc='lower right', fancybox=True, framealpha=0.5)
    plt.title("Journey time {0:.2f} hrs".format(jt))
    plt.savefig(fname)
    # plt.show()
    plt.clf()


def inspect_route():
    """Script to inspect route."""
    path = os.path.dirname(os.path.realpath(__file__))+"/"
    x = pd.read_csv(path+"x_locs").values
    y = pd.read_csv(path+"y_locs").values
    et = pd.read_csv(path+"earliest_times").values
    jt = 308.875
    fname = path + "route_plot.png"
    plot_isochrones(x, y, et, jt, fname)

if __name__ == "__main__":
    inspect_route()