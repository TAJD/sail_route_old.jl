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
using CSV
using DataFrames

twa, tws, perf = load_file(boat_performance)
polar = setup_interpolation(tws, twa, perf)
sample_perf = Performance(polar, 1.0, 1.0)
lon1 = -11.5
lat1 = 47.67
lon2 = -77.67
lat2 = 25.7
n = 360 # won't interpolate well below this value
sample_route = Route(lon1, lon2, lat1, lat2, n, n)
start_time = Dates.DateTime(2016, 4, 1, 2, 0, 0)
wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data)
times = zeros(10, 2)
for i = LinRange(0, 9, 10)
    results = route_solve(sample_route, sample_perf, start_time, wisp, widi, wadi, wahi, Int(i))
    @show arrival_time = results[1]
    results[i] = arrival_time
    @show route = results[2]
    name = ENV["HOME"]*"/sail_route.jl/development/sensitivity/_route_transat_ens_number_"*repr(Int(i))
    df = DataFrame(results[2])
    CSV.write(name, df)
    times[i, :] = Array([i, results[1]])
end
df_res = DataFrame(times)
name1 = ENV["HOME"]*"/sail_route.jl/development/sensitivity/_route_transat_ens_number_results"
CSV.write(name1, df_res)
