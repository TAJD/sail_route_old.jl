include(ENV["HOME"]*"/sail_route_old/src/sail_route.jl")
include(ENV["HOME"]*"/sail_route_old/development/sensitivity/discretization_error.jl")
include(ENV["HOME"]*"/sail_route_old/development/polynesian/polynesian_sims_utils.jl")

using BenchmarkTools, Revise, DataFrames, Test, Printf
using Plots
unicodeplots()


"""Code plan.

1. Code to generate the routes for different discretization amounts.
2. Save the results to allow a convergence plot to be plotted
"""


"""Solve a predefined route for varied min_dist numbers."""
function solve_example_route(min_dist)
    lon1 = -171.15
    lat1 = -21.21
    lon2 = -158.07
    lat2 = -19.59
    route = sail_route.Route(lon1, lon2, lat1, lat2, 1, 1)
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    wisp, widi, wahi, wadi, wapr, time_indexes = sail_route.load_era20_weather(weather_data)
    n = sail_route.calc_nodes(route.lon1, route.lon2, route.lat1, route.lat2, min_dist)
    sim_route = sail_route.Route(route.lon1, route.lon2, route.lat1, route.lat2, n, n)
    x, y, wisp_i, widi_i, wadi_i, wahi_i= sail_route.generate_inputs(sim_route, wisp, widi,
                                                          wadi, wahi)
    dims = size(wisp_i)
    cusp_i, cudi_i = sail_route.return_current_vectors(y, dims[1])
    start_time = Dates.DateTime(1982, 1, 1, 0, 0, 0)
    times = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(12):Dates.DateTime(1982, 11, 30, 0, 0, 0)
    twa, tws, speeds = load_tong()
    polar = sail_route.setup_perf_interpolation(tws, twa, speeds)
    perf = sail_route.Performance(polar, 1.0, 1.0, nothing)
    results = sail_route.route_solve(sim_route, perf, start_time, times, x, y, wisp_i, widi_i, wadi_i, wahi_i, cusp_i, cudi_i)
    println(results[1])
    name = ENV["HOME"]*"/sail_route_old/development/discretization/_"*repr(min_dist)*"_nm_"*repr(start_time)*"_"
    CSV.write(name*"route", DataFrame(results[2]))
    CSV.write(name*"time", DataFrame([[results[1]]]))
    CSV.write(name*"earliest_times", DataFrame(results[3]))
    CSV.write(name*"x_locs", DataFrame(results[4]))
    CSV.write(name*"y_locs", DataFrame(results[5]))
end

for i in [40.0, 20.0, 10.0, 5.0, 2.5]
    solve_example_route(i)
end