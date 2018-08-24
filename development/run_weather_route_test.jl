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


function solve_route()
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_april.nc"
    twa, tws, perf = load_file(boat_performance);
    polar = setup_interpolation(tws, twa, perf);
    sample_perf = Performance(polar, 1.0, 1.0);
    nodes = 160
    sample_route = Route(-12.0, -60.0, 48.0, 17.5, nodes, nodes)
    start_time = Dates.DateTime(2016, 4, 1, 0, 0, 0)
    wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data);
    println("Single scenario weather routing")
    println("Does this scenario solve?")
    t = route_solve(sample_route, sample_perf, start_time, wisp, widi, wadi, wahi)
    print(sample_route)
    print(t)
end

solve_route()
