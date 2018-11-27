"""Uncertainty analysis of routing simulations

Thomas Dickson
thomas.dickson@soton.ac.uk
14/09/2018
"""

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
# plt.rcParams["font.family"] = "Times New Roman"  
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


def plot_varied_grid(lon1, lat1, lon2, lat2, r1, r2, r3, r4, r5, 
                     t1, t2, t3, t4, t5, fname, fill=1.0):
    """Plot routes generated as a function of different grid sizes."""
    add_param = fill
    res = 'l'
    # plt.figure(figsize=(6, 10))
    f = plt.figure()
    ax = f.add_subplot(111)
    ax.yaxis.tick_right()
    ax.yaxis.set_ticks_position('both')
    ax.yaxis.tick_right()
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
    map.scatter(r_s_x, r_s_y, marker="<", color='red', label='Start')
    r_f_x, r_f_y = map(lon1, lat1)
    parallels = np.arange(-90.0, 90.0, 5.)
    map.drawparallels(parallels, labels=[1, 0, 0, 0])
    meridians = np.arange(180., 360., 5.)
    map.drawmeridians(meridians, labels=[0, 0, 0, 1])
    map.scatter(r_f_x, r_f_y, marker=">", color='blue', label='Finish')
    x_r1, y_r1 = map(r1["x1"].values, r1["x2"].values)
    map.plot(np.concatenate(([r_s_x], x_r1, [r_f_x])), np.concatenate(([r_s_y], y_r1, [r_f_y])), '--', label="2.5 nm, {0:.2f} hrs".format(t1.values[0][0]))
    x_r2, y_r2 = map(r2["x1"].values, r2["x2"].values)
    map.plot(np.concatenate(([r_s_x], x_r2, [r_f_x])), np.concatenate(([r_s_y], y_r2, [r_f_y])), '-.', label="5.0 nm, {0:.2f} hrs".format(t2.values[0][0]))
    x_r3, y_r3 = map(r3["x1"].values, r3["x2"].values)
    map.plot(np.concatenate(([r_s_x], x_r3, [r_f_x])), np.concatenate(([r_s_y], y_r3, [r_f_y])), '_', label="10.0 nm, {0:.2f} hrs".format(t3.values[0][0]))
    x_r4, y_r4 = map(r4["x1"].values, r4["x2"].values)
    map.plot(np.concatenate(([r_s_x], x_r4, [r_f_x])), np.concatenate(([r_s_y], y_r4, [r_f_y])), ':', label="20.0 nm, {0:.2f} hrs".format(t4.values[0][0]))
    x_r5, y_r5 = map(r5["x1"].values, r5["x2"].values)
    map.plot(np.concatenate(([r_s_x], x_r5, [r_f_x])), np.concatenate(([r_s_y], y_r5, [r_f_y])), '.', label="40.0 nm, {0:.2f} hrs".format(t5.values[0][0]))
    plt.legend(bbox_to_anchor=(0.6, -0.2), fancybox=True, framealpha=0.5)
    plt.tight_layout()
    plt.savefig(fname,bbox_inches='tight')
    plt.show()


def plot_convergence_results(x, y, fname):
    """Plot the convergence results, x is the grid widths and y is the voyaging times."""
    fig, ax = plt.subplots()
    ax.set_xscale('log')
    ax.plot(x, y, 'o')
    ax.set_xlabel("Grid width (nm)")
    ax.set_xlim([1.0, 45.0])
    ax.set_ylabel("Voyaging time (hrs)")
    plt.savefig(fname, bbox_inches='tight')
    plt.show()


def plot_varied_grid_results():
    dir_path = os.path.dirname(os.path.realpath(__file__))+"/discretization/"
    save_path = "/Users/thomasdickson/Documents/PhD/papers/SA_weather_routing/figures/"
    fname = save_path+"poly_discretized_routing.png"
    fname_convergence = save_path+"convergence_plot.png"
    # tongatapu to moorea
    lon1 = -171.75
    lat1 = -21.21
    lon2 = -158.07
    lat2 = -19.59
    time = "1982-01-01T00:00:00_"
    width_1 = "_2.5_nm_"
    width_2 = "_5.0_nm_"
    width_3 = "_10.0_nm_"
    width_4 = "_20.0_nm_"
    width_5 = "_40.0_nm_"
    t1 = pd.read_csv(dir_path+width_1+time+"time")
    t2 = pd.read_csv(dir_path+width_2+time+"time")
    t3 = pd.read_csv(dir_path+width_3+time+"time")
    t4 = pd.read_csv(dir_path+width_4+time+"time")
    t5 = pd.read_csv(dir_path+width_5+time+"time")
    r1 = pd.read_csv(dir_path+width_1+time+"route")
    r2 = pd.read_csv(dir_path+width_2+time+"route")
    r3 = pd.read_csv(dir_path+width_3+time+"route")
    r4 = pd.read_csv(dir_path+width_4+time+"route")
    r5 = pd.read_csv(dir_path+width_5+time+"route")
    x = np.array([2.5, 5.0, 10.0, 20.0, 40.0])
    y = np.array([t1.values[0][0],t2.values[0][0],t3.values[0][0],t4.values[0][0],t5.values[0][0]])
    plot_convergence_results(x, y, fname_convergence)
    plot_varied_grid(lon1, lat1, lon2, lat2, r1, r2, r3, r4, r5,
                     t1, t2, t3, t4, t5, fname)


def plot_ensemble_results(lon1, lat1, lon2, lat2, df_paths, df_results,
                          fname, fill=1.0):
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
        if df_results[counter] > 1500.0:
            pass
        else:
            x, y = map(value["x1"].values, value["x2"].values)
            map.plot(x, y, label="Ensemble {:d}, {:.2f} hrs".format(counter, df_results[counter]))
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
    times = pd.read_csv(dir_path+"/route_transat_ens_number_results").values
    fname = dir_path+"/ensemble_routes_plot.png"
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    plot_ensemble_results(lon1, lat1, lon2, lat2, df_list, times[:, 1], fname, fill=0.5)

    # create list of the dataframes
    # load the routing results
    # plot each route with the associated ensemble weather scenario and the label


def plot_discretization_scatter():
    dir_path = os.path.dirname(os.path.realpath(__file__))
    df = pd.read_csv(dir_path+"/constant_upwind_discretization.txt")
    times = np.array(df['times'].values)
    heights = np.array(df['heights'].values)
    nd_times = np.array([(times[i] - times[0])/times[0] for i in range(len(times))])
    # print(nd_times[1:5])
    # f, (ax1, ax2) = plt.subplots(1, 2, sharey=True)
    # ax1.scatter(nd_times, heights)
    # ax1.set_title('$V_t = f(d_n)$')
    # ax2.scatter(nd_times, heights)
    # ax2.set_xscale('log')
    plt.figure()
    # plt.yscale('log')
    # plt.xscale('log')
    h = 5.0
    plt.plot(heights[heights<h], nd_times[heights<h])
    plt.xlabel("Height of grid as $\%$ voyage length")
    plt.ylabel(r"$\frac{V_{t, i} - V_{t, min}}{V_{t, min}}$")
    plt.savefig("discretization.png")


if __name__ == "__main__":
    plot_varied_grid_results()
    # plot_ensemble_weather_simulations_results()
    # plot_discretization_scatter()
