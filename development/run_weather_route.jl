"""Running a single weather scenario.

1. Load weather data
2. Specify performance
3. Specify route parameters
4. Set off simulation.
5. Save results of simulation.
"""

include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")

boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_april.nc"

using BenchmarkTools
using Printf
using Dates

__precompile__()

twa, tws, perf = load_file(boat_performance);
polar = setup_interpolation(tws, twa, perf);
sample_perf = Performance(polar, 0.0, 1.0, 0.0);
nodes = 1240
sample_route = Route(-6.486, -59.883, 61.48, -1.76, nodes, nodes)
start_time = Dates.DateTime(2016, 4, 1, 4, 0, 0)
wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data);
# y_dist = haversine(sample_route.lon1, sample_route.lon2, sample_route.lat1, sample_route.lat2)[1]/(sample_route.y_nodes+1);
# x, y, land = co_ordinates(sample_route.lon1, sample_route.lon2, sample_route.lat1, sample_route.lat2,
#                           sample_route.x_nodes, sample_route.y_nodes, y_dist);
# wisp_int = regrid_data(wisp, x[:, 1], y[:, 1])
# @benchmark wisp_int[:sel](time=start_time, lon_b=x[1, 1], lat_b=y[1, 1], number=0, method="nearest")[:data][1]
# @benchmark wisp[:interp](time=start_time, longitude=x[1, 1], latitude=y[1, 1], number=1, method="nearest")[:data][1]
# w = wisp_int[:sel](time=start_time, lon_b=x[1, 1], lat_b=y[1, 1], number=0, method="nearest")[:data][1]
# println(w)
# println(wisp_int[:data][1])
t = @benchmark route_solve(sample_route, sample_perf, start_time, wisp, widi, wadi, wahi)
println("Single weather routing")
println("Experiments with varying numbers of nodes")
dump(t)
