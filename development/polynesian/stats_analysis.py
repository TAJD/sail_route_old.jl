import os, sys, glob, re
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('agg')
import scipy.stats as scis
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
from matplotlib.patches import Polygon

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


def compare_scenarios():
    """Compare uncertainty simulations for two sets of simulations."""
    boat1 = "/boeckv2/"
    name1 = "_routing1982-01-01T00:00:00finish_1982-01-01T00:00:00"
    # name2 = "/tongiaki/"
    path = os.path.dirname(os.path.realpath(__file__))
    path1 = path + boat1 + name1
    l1 = "Boeck V2"
    l2 = "Tongiaki"
    df1 = pd.read_csv(path1)
    perf = np.linspace(0.9, 1.1, 10)
    data = np.array(df1.values).T
    data = np.hstack((data, data))
    fig, ax1 = plt.subplots(figsize=(10, 6))
    fig.canvas.set_window_title('Voyaging time comparison')
    plt.subplots_adjust(left=0.075, right=0.95, top=0.9, bottom=0.25)
    bp = plt.boxplot(data, notch=0, sym='+', vert=1, whis=1.5)
    plt.setp(bp['boxes'], color='black')
    plt.setp(bp['whiskers'], color='black')
    plt.setp(bp['fliers'], color='red', marker='+')

    ax1.yaxis.grid(True, linestyle='-', which='major', color='lightgrey',
               alpha=0.5)

    # Hide these grid behind plot objects
    ax1.set_axisbelow(True)
    ax1.set_xlabel('Day/Vessel type')
    ax1.set_ylabel('Time (hrs)')
    # Now fill the boxes with desired colors
    boxColors = ['darkkhaki', 'royalblue']
    numBoxes = data.shape[1]
    medians = list(range(numBoxes))
    for i in range(numBoxes):
        box = bp['boxes'][i]
        boxX = []
        boxY = []
        for j in range(5):
            boxX.append(box.get_xdata()[j])
            boxY.append(box.get_ydata()[j])
        boxCoords = list(zip(boxX, boxY))
        # Alternate between Dark Khaki and Royal Blue
        k = i % 2
        boxPolygon = Polygon(boxCoords, facecolor=boxColors[k])
        ax1.add_patch(boxPolygon)
        # Now draw the median lines back over what we just filled in
        med = bp['medians'][i]
        medianX = []
        medianY = []
        for j in range(2):
            medianX.append(med.get_xdata()[j])
            medianY.append(med.get_ydata()[j])
            plt.plot(medianX, medianY, 'k')
            medians[i] = medianY[0]
        # Finally, overplot the sample averages, with horizontal alignment
        # in the center of each box
        plt.plot([np.average(med.get_xdata())], [np.average(data[i])],
                color='w', marker='*', markeredgecolor='k')

    # Set the axes ranges and axes labels
    ax1.set_xlim(0.5, numBoxes + 0.5)
    top = np.max(data) + 10.0
    bottom = np.min(data) - 10.0
    ax1.set_ylim(bottom, top)
    names = ['Tongiaki', 'Boeck V2']
    xtickNames = plt.setp(ax1, xticklabels=np.repeat(names, 1))
    plt.setp(xtickNames, rotation=45, fontsize=8)

    # Due to the Y-axis scale being different across samples, it can be
    # hard to compare differences in medians across the samples. Add upper
    # X-axis tick labels with the sample medians to aid in comparison
    # (just use two decimal places of precision)
    pos = np.arange(numBoxes) + 1
    upperLabels = [str(np.round(s, 2)) for s in medians]
    weights = ['bold', 'semibold']
    for tick, label in zip(range(numBoxes), ax1.get_xticklabels()):
        k = tick % 2
        ax1.text(pos[tick], top - (top*0.05), upperLabels[tick],
                horizontalalignment='center', size='x-small', weight=weights[k],
                color=boxColors[k])
    plt.savefig(path+"/compare_two_datasets.png")




def plot_date_range_results():
    """Plot routing results over a range of days."""
    name1 = "/uncertainty_routing1982-07-01T00:00:00finish_1982-07-10T00:00:00"
    # name2 = "/tongiaki/"
    path = os.path.dirname(os.path.realpath(__file__))
    path1 = path + name1
    df1 = pd.read_csv(path1)
    # perf = np.linspace(0.9, 1.1, 10)
    data = np.array(df1.values).T
    dates = pd.date_range('1982-07-01', periods=10, freq='D')
    print(dates)
    fig, ax1 = plt.subplots(figsize=(10, 6))
    fig.canvas.set_window_title('Voyaging time comparison')
    plt.subplots_adjust(left=0.075, right=0.95, top=0.9, bottom=0.25)
    bp = plt.boxplot(data, notch=0, sym='+', vert=1, whis=1.5)
    plt.setp(bp['boxes'], color='black')
    plt.setp(bp['whiskers'], color='black')
    plt.setp(bp['fliers'], color='red', marker='+')

    ax1.yaxis.grid(True, linestyle='-', which='major', color='lightgrey',
               alpha=0.5)

    # Hide these grid behind plot objects
    ax1.set_axisbelow(True)
    ax1.set_xlabel('Day')
    ax1.set_ylabel('Voyaging time (hrs)')
    # Now fill the boxes with desired colors
    boxColors = ['darkkhaki', 'royalblue']
    numBoxes = data.shape[1]
    medians = list(range(numBoxes))
    for i in range(numBoxes):
        box = bp['boxes'][i]
        boxX = []
        boxY = []
        for j in range(5):
            boxX.append(box.get_xdata()[j])
            boxY.append(box.get_ydata()[j])
        boxCoords = list(zip(boxX, boxY))
        # Alternate between Dark Khaki and Royal Blue
        k = i % 2
        boxPolygon = Polygon(boxCoords, facecolor=boxColors[k])
        ax1.add_patch(boxPolygon)
        # Now draw the median lines back over what we just filled in
        med = bp['medians'][i]
        medianX = []
        medianY = []
        for j in range(2):
            medianX.append(med.get_xdata()[j])
            medianY.append(med.get_ydata()[j])
            plt.plot(medianX, medianY, 'k')
            medians[i] = medianY[0]
        # Finally, overplot the sample averages, with horizontal alignment
        # in the center of each box
        plt.plot([np.average(med.get_xdata())], [np.average(data[i])],
                color='w', marker='*', markeredgecolor='k')

    # Set the axes ranges and axes labels
    ax1.set_xlim(0.5, numBoxes + 0.5)
    top = np.max(data) + 10.0
    bottom = np.min(data) - 10.0
    ax1.set_ylim(bottom, top)
    # xtickNames = plt.setp(dates, xticklabels=np.repeat(dates, 1))
    ax1.set_xticklabels(dates, rotation=45, fontsize=8)
    # plt.setp(dates.strftime('%Y-%m-%d'), rotation=45, fontsize=8)

    # Due to the Y-axis scale being different across samples, it can be
    # hard to compare differences in medians across the samples. Add upper
    # X-axis tick labels with the sample medians to aid in comparison
    # (just use two decimal places of precision)
    pos = np.arange(numBoxes) + 1
    upperLabels = [str(np.round(s, 2)) for s in medians]
    weights = ['bold', 'semibold']
    for tick, label in zip(range(numBoxes), ax1.get_xticklabels()):
        k = tick % 2
        ax1.text(pos[tick], top - (top*0.05), upperLabels[tick],
                horizontalalignment='center', size='x-small', weight=weights[k],
                color=boxColors[k])
    plt.savefig(path+"/daily_variability.png")



def pc_difference(df):
    """Calculate the pc difference between voyage results and mean voyaging time."""
    means = df.mean(axis=1)
    df = df.sub(means, axis=0)
    df = df.div(means, axis=0)
    return df


def plot_scatter(df):
    plt.figure()
    perf_variation = np.array([float(x) for x in df.columns.values])
    response = df.mean(axis=0).values
    plt.scatter(perf_variation, response, label="Performance mean pc variation")
    slope, intercept, r_value, p_value, std_err = scis.linregress(perf_variation, response)
    f = lambda x: slope*x + intercept
    x = np.array([0.85,1.15])
    plt.plot(x, f(x), label=r"Fitted line, r$^2$ = {:03.2f}".format(r_value))
    plt.legend()
    plt.savefig("nd_performance_scatter.png")


def identify_linear_relationships(df):
    """For each row of performance results identify whether there is a linear correlation. Save the linear correlation as an extra column."""
    print(df.describe())
    perf_variation = np.array([float(x) for x in df.columns.values])
    # for each row in dataframe calculate the correlation between it's results and the performance variation results
    # save result in additional column`


def apply_performance_difference_analysis():
    """Apply performance difference analysis."""
    pwd = "/Users/thomasdickson/sail_route.jl/development"
    path = "/polynesian/boeckv2/_routing_upolu_to_moorea_1982-01-01T00:00:00_to_1982-11-01T00:00:00_10.0_nm.txt"
    df = pd.read_csv(pwd+path, index_col=0)
    df = pc_difference(df)
    identify_linear_relationships(df)


if __name__ == "__main__":
    # compare_scenarios()
    # plot_date_range_results()
    apply_performance_difference_analysis()