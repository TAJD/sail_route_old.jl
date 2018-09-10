include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")

using PyCall
@pyimport xarray as xr

function run_routes_time_dependent()
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    twa, tws, perf = load_file(boat_performance);
    polar = setup_interpolation(tws, twa, perf);
    sample_perf = Performance(polar, 1.0, 1.0);
    weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_april.nc"
    start_time = Dates.DateTime(2016, 4, 1, 0, 0, 0)
    wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data)
    println("Single scenario weather routing")
    println("Does this scenario solve?")
    nodes = 20
    east_to_west = Route(lon2, lon1, lat2, lat1, nodes, nodes)
    # west_to_east = Route(lon1, lon2,  lat1, lat2, nodes, nodes)
    t1 = route_solve(east_to_west, sample_perf, start_time, wisp, widi, wadi, wahi)
    print(t1[1])
end

# run_routes_time_dependent()


function run_routes_average_conditions()
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    twa, tws, perf = load_file(boat_performance);
    polar = setup_interpolation(tws, twa, perf);
    sample_perf = Performance(polar, 1.0, 1.0);
    cluster1_wisp = ENV["HOME"]*"/weather_cluster/test1_wisp.nc"
    cluster1_widi = ENV["HOME"]*"/weather_cluster/test1_widi.nc"
    nodes = 20
    east_to_west = Route(lon2, lon1, lat2, lat1, nodes, nodes)
    sp = route_solve(east_to_west, sample_perf, cluster1_wisp, cluster1_widi)
    println(sp)
    # east_to_west = Route(lon2, lon1, lat2, lat1, nodes, nodes)
end

run_routes_average_conditions()