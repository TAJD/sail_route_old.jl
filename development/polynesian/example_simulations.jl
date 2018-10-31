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


function parallized_uncertain_routing()
    # variables
    # boat = "/tongiaki/"
    boat = "/boeckv2/"
    route_name = "tongatapu_to_atiu"
    wave_model = "resistance_direction_"
    @everywhere lon1 = -171.15
    @everywhere lat1 = -21.21
    @everywhere lon2 = -158.07
    @everywhere lat2 = -19.59
    @everywhere min_dist = 20.0
    @everywhere weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/1976_polynesia.nc"
    @everywhere times = Dates.DateTime(1976, 7, 1, 0, 0, 0):Dates.Hour(12):Dates.DateTime(1976, 11, 1, 0, 0, 0)
    # @everywhere weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    # @everywhere times = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(12):Dates.DateTime(1982, 11, 1, 0, 0, 0)
    # @everywhere twa, tws, perf = load_tong()
    @everywhere twa, tws, perf = load_boeckv2()
    sim_times = [DateTime(t) for t in times]
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

# parallized_uncertain_routing()


function check_current_works(d)
    # variables
    boat = "/tongiaki/"
    route_name = "tongatapu_to_atiu"
    wave_model = "resistance_direction_"
    lon1 = -171.15
    lat1 = -21.21
    lon2 = -158.07
    lat2 = -19.59
    min_dist = d
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    times = Dates.DateTime(1982, 1, 1, 0, 0, 0):Dates.Hour(12):Dates.DateTime(1982, 11, 30, 0, 0, 0)
    twa, tws, perf = load_tong()
    sim_times = [DateTime(t) for t in times]
    params = [i for i in LinRange(0.85, 1.15, 20)]
    polar = setup_perf_interpolation(tws, twa, perf)
    wave_resistance_model = typical_aerrtsen()
    perfs = generate_performance_uncertainty_samples(polar,
                                                     params,
                                                     wave_resistance_model)
    results = SharedArray{Float64, 2}(length(sim_times), length(perfs))
    path_name = boat*"_routing_"*route_name*"_"*wave_model*repr(times[1])*"_to_"*repr(times[end])*"_"*repr(min_dist)*"_nm.txt"
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr, time_indexes = load_era20_weather(weather_data)
    x, y, wisp, widi, wadi, wahi = generate_inputs(route, wisp, widi, wadi, wahi)
    dims = size(wisp)
    cusp, cudi = return_current_vectors(y, dims[1])
    results = route_solve(route, perfs[1], sim_times[1], times, x, y,
                          wisp, widi,
                          cusp, cudi,
                          wadi, wahi)
    println(results[1])
end


# check_current_works(20)
# parallized_uncertain_routing()


"""Running a routing simulation for a single set of initial conditions."""
function run_single_route()
    # weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/1976_era20_jul_sep.nc"
    # start_time = Dates.DateTime(1976, 7, 1, 0, 0, 0)
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    start_time = Dates.DateTime(1982, 1, 1, 0, 0, 0)
    # twa, tws, perf = load_tong()
    twa, tws, perf = load_boeckv2()
    polar = setup_perf_interpolation(tws, twa, perf)
    wave_resistance_model = typical_aerrtsen()
    sample_perf = Performance(polar, 1.0, 1.0, wave_resistance_model)
    # sample_perf = Performance(polar, 1.0, 1.0, nothing)
    lon1 = -171.15
    lat1 = -21.21
    lon2 = -158.07
    lat2 = -19.59
    min_dist = 175.0 # nm
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr, times = load_era20_weather(weather_data)
    x, y, wisp, widi, wadi, wahi = generate_inputs(sample_route, wisp, widi, wadi, wahi)
    results = route_solve(sample_route, sample_perf, start_time, times, x, y,
                           wisp, widi, wadi, wahi)
    println(results[1])
    name = ENV["HOME"]*"/sail_route.jl/development/polynesian/boeckv2/_"*repr(min_dist)*"_nm_"*repr(start_time)
    CSV.write(name*"route", DataFrame(results[2]))
    CSV.write(name*"time", DataFrame([[results[1]]]))
    CSV.write(name*"earliest_times", DataFrame(results[3]))
    CSV.write(name*"x_locs", DataFrame(results[4]))
    CSV.write(name*"y_locs", DataFrame(results[5]))
end


function check_indexing() # won't work now as the method of loading datasets has changed, change line 33 in load_weather.jl to check
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    start_time = Dates.DateTime(1982, 1, 1, 0, 0, 0)
    # twa, tws, perf = load_tong()
    twa, tws, perf = load_boeckv2()
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    lon1 = -171.15
    lat1 = -21.21
    lon2 = -158.07
    lat2 = -19.59
    min_dist = 20.0 # nm
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr, time = load_era20_weather(weather_data)
    time_idx = convert_start_time(start_time, time)
    x, y, wisp, widi, wadi, wahi = generate_inputs(sample_route, wisp, widi, wadi, wahi)
    idx_y_1 = 1
    idx_x_1 = 1
    wisp_vals = Array{Float64}(wisp[:values])
    m_index_1 = wisp_vals[time_idx, idx_x_1, idx_y_1]
    lat_test_1 = -3.13
    lon_test_1 = -171.0
    m_interp_1 = wisp[:sel](time=start_time, lon_b=lon_test_1, lat_b=lat_test_1,
                        method="nearest")[:data][1]
    println("Method test 1 ", isapprox(m_index_1, m_interp_1, atol = 0.0001))
    idx_y_2 = 2
    idx_x_2 = 1
    m_index_2 = wisp_vals[time_idx, idx_y_2, idx_x_2]
    lat_test_2 = -3.115
    m_interp_2 = wisp[:sel](time=start_time, lon_b=lon_test_1, lat_b=lat_test_2,
                            method="nearest")[:data][1]
    println("Method test 2 ", isapprox(m_index_2, m_interp_2, atol = 0.0001))
end


"""Simulation demonstrating the calculation of uncertainty for a single set of initial conditions. Being tested."""
function run_algorithm_uncertainty_route()
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    start_time = Dates.DateTime(1982, 1, 1, 0, 0, 0)
    twa, tws, perf = load_boeckv2()
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    results = disc_routing_analysis(lon2, lon1, lat2, lat1, sample_perf,
                                    start_time, wisp, widi, wadi, wahi)
    @show results
end


"""Simulation varying performance for a single starting time. Not tested yet."""
function run_varied_performance()
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    n = calc_nodes(lon1, lon2, lat1, lat2, 50.0)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    twa, tws, perf = load_tong()
    polar = setup_interpolation(tws, twa, perf)
    start_time = Dates.DateTime(1982, 7, 1, 0, 0, 0)
    params = [i for i in LinRange(0.9, 1.1, 3)]
    perfs = generate_performance_uncertainty_samples(polar, params)
    results = SharedArray{Float64}(length(perfs), 2)
    @sync @distributed for i in eachindex(perfs)
        wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
        results[i, :] = disc_routing_analysis(lon2, lon1, lat2, lat1, perf, time,
                                              wisp, widi, wadi, wahi)
        fine_routing = route_solve(sample_route, sample_perf, start_time,
                                   wisp, widi, wadi, wahi)
        name = ENV["HOME"]*"/sail_route.jl/development/polynesian/_route_nodes_"*repr(n)*"_date_"*repr(start_time)
        CSV.write(name, DataFrame(fine_routing[2]))
    end
    times = results[:, 1]
    unc = results[:, 2]
    @show df = DataFrame(perf=params, t=times, u=unc)
    time = Dates.format(Dates.now(), "HH:MM:SS")
    save_path = ENV["HOME"]*"/sail_route.jl/development/polynesian/results_"*repr(start_time)
    CSV.write(save_path, df)
end
