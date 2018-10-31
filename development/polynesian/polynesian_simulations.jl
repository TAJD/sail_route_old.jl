using Distributed
@everywhere begin
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")
    include(ENV["HOME"]*"/sail_route.jl/development/sensitivity/discretization_error.jl")
    include(ENV["HOME"]*"/sail_route.jl/development/polynesian/polynesian_sims_utils.jl")

    using BenchmarkTools
    using Printf
    using Dates
    using CSV
    using DataFrames
    using SharedArrays

    # global weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    # global weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/1976_polynesia.nc"
    route_solve_shared_chunk!(results, times, perfs, route, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi) = route_solve_chunk!(results, myrange(results)..., times, perfs, route, time_indexes, x, y, wisp, widi, wadi, wahi, cusp, cudi)
end


"""parallized_uncertain_routing(min_dist)

This file contains the scripts which provide the essential results quantifying the performance of Polynesian seafaring technology.

Inputs need to be;

1. Path name for saving files
2. Start/finish locations
3. Location of weather data 
4. Start times requiring simulation
5. Performance of sailing craft
6. Minimum distance 
"""
function parallized_uncertain_routing(save_path, lon1, lat1, lon2, lat2, weather, times, perf, min_dist)
    sim_times = [DateTime(t) for t in times]
    @everywhere twa, tws, perf = perf
    params = [i for i in LinRange(0.85, 1.15, 20)]
    polar = setup_perf_interpolation(tws, twa, perf)
    wave_resistance_model = typical_aerrtsen()
    perfs = generate_performance_uncertainty_samples(polar, params, wave_resistance_model)
    results = SharedArray{Float64, 2}(length(sim_times), length(perfs))
    path_name = boat*"_routing_"*route_name*"_"*wave_model*repr(times[1])*"_to_"*repr(times[end])*"_"*repr(min_dist)*"_nm.txt"
    save_path = ENV["HOME"]*"/sail_route.jl/development/polynesian"*path_name
    println(save_path)
    @everywhere n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    @everywhere route = Route(lon1, lon2, lat1, lat2, n, n)
    @everywhere wisp, widi, wahi, wadi, wapr, time_indexes = load_era20_weather(weather_data)
    @everywhere x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    @everywhere dims = size(wisp)
    @everywhere cusp, cudi = return_current_vectors(y, dims[1])
    @sync begin
        for p in procs(results)
            @async remotecall_wait(route_solve_shared_chunk!, p, results, times, perfs, route,
                                   time_indexes, x, y,
                                   wisp, widi, wadi, wahi, cusp, cudi)
        end
    end
    _results = DataFrame(results)
    names!(_results, [Symbol(i) for i in params])
    insert!(_results, 1, times, :start_time)
    # CSV.write(save_path, _results)
    return _results
end


function test_single_instance()
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    times = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(12):Dates.DateTime(1982, 2, 1, 0, 0, 0)
    boat = "/tongiaki/"
    route_name = "tongatapu_to_atiu"
    wave_model = "resistance_direction_"
    save_path = boat*"_routing_"*route_name*"_"*wave_model*repr(times[1])*"_to_"*repr(times[end])*"_"*repr(min_dist)*"_nm.txt"
    min_dist = 30.0
    perf = load_tong()

    results = parallized_uncertain_routing(save_path, lon1, lat1, lon2, lat2, weather, times, perf, min_dist)
    println(results[1, 1])
end


"""Generate the parameters to simulate for all cases of the Polynesian routing simulation."""
function generate_for_loop()
    start_locations_lat = [-13.917, -21.21]
    start_locations_lon = [-171.75, -175.15]
    finish_locations_lat = [-19.59, -17.53]
    finish_locations_lon = [-158.07, -149.83]
    start_location_names = ["upolu", "tongatapu"]
    finish_location_names = ["atiu", "moorea"]
    boat_performance = [load_tong(), load_boeckv2()]
    boat_performance_names = ["tongiaki", "boeckv2"]
    t_inc = 12
    t_low = Dates.DateTime(1976, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1976, 2, 1, 0, 0, 0)
    t_high = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(t_inc):Dates.DateTime(1982, 2, 1, 0, 0, 0)
    weather_times = [t_low, t_high]
    weather_names = ["low", "high"]
    node_spacing = [20.0, 15.0, 10.0]
end


generate_for_loop()

# three for loops;
# #1 for boat type 
# #2 for start/finish locations
# #3 for weather conditions 

# create lists of strings which allow the generation of file names associated with each simulation

# function route_solve_upolu_to_atiu!(results, t_range, p_range, sim_times, perfs)
#     lon1 = -171.75
#     lat1 = -13.917
#     lon2 = -158.07
#     lat2 = -19.59
#     n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
#     sample_route = Route(lon1, lon2, lat1, lat2, n, n)
#     wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
#     for t in t_range, p in p_range
#         output = route_solve(sample_route, perfs[p], sim_times[t], wisp, widi, wadi, wahi)
#         @show results[t, p] = output[1]
#         output = nothing
#     end
#     results
# end


"""parallized_uncertain_routing(min_dist)

This file contains the scripts which provide the essential results quantifying the performance of Polynesian seafaring technology.
"""
function upolu_to_atiu!(min_dist)
    # variables
    boat = "/tongiaki/"
    route_name = "tongatapu_to_atiu"
    wave_model = "resistance_direction_"
    @everywhere lon1 = -171.15
    @everywhere lat1 = -21.21
    @everywhere lon2 = -158.07
    @everywhere lat2 = -19.59
    @everywhere weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    @everywhere times = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(12):Dates.DateTime(1982, 10, 1, 0, 0, 0)
    sim_times = [DateTime(t) for t in times]
    @everywhere twa, tws, perf = load_tong()
    params = [i for i in LinRange(0.85, 1.15, 20)]
    polar = setup_perf_interpolation(tws, twa, perf)
    wave_resistance_model = typical_aerrtsen()
    perfs = generate_performance_uncertainty_samples(polar, params, wave_resistance_model)
    results = SharedArray{Float64, 2}(length(sim_times), length(perfs))
    path_name = boat*"_routing_"*route_name*"_"*wave_model*repr(times[1])*"_to_"*repr(times[end])*"_"*repr(min_dist)*"_nm.txt"
    save_path = ENV["HOME"]*"/sail_route.jl/development/polynesian"*path_name
    println(save_path)
    @everywhere n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    @everywhere route = Route(lon1, lon2, lat1, lat2, n, n)
    @everywhere wisp, widi, wahi, wadi, wapr, time_indexes = load_era20_weather(weather_data)
    @everywhere x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    @everywhere dims = size(wisp)
    @everywhere cusp, cudi = return_current_vectors(y, dims[1])
    @sync begin
        for p in procs(results)
            @async remotecall_wait(route_solve_shared_chunk!, p, results, times, perfs, route,
                                   time_indexes, x, y,
                                   wisp, widi, wadi, wahi, cusp, cudi)
        end
    end
    _results = DataFrame(results)
    names!(_results, [Symbol(i) for i in params])
    insert!(_results, 1, times, :start_time)
    CSV.write(save_path, _results)
    return _results
end