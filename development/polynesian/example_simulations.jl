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

    global weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    # global weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/1976_polynesia.nc"
    global times = Dates.Date(1982, 1, 1):Dates.Day(1):Dates.Date(1982, 1, 10)
    # global times = Dates.Date(1982, 7, 11):Dates.Day(1):Dates.Date(1982, 7, 20)
    # global times = Dates.Date(1976, 6, 11):Dates.Day(1):Dates.Date(1976, 6, 21)
    global min_dist = 20.0 # 50 solves for 20 days? 20 for 10 days
    route_solve_shared_chunk!(results, times, perfs) = route_solve_tongatapu_to_atiu!(results, myrange(results)..., times, perfs)
end


function parallized_v2_uncertain_routing!()
    sim_times = [DateTime(t) for t in times]
    params = [i for i in LinRange(0.9, 1.1, 11)]
    # route_name = "upolu_to_atiu"
    # route_name = "upolu_to_moorea"
    # route_name = "tongatapu_to_moorea"
    route_name = "tongatapu_to_atiu"
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    # boat = "/boeckv2/"
    # twa, tws, perf = load_boeckv2()
    boat = "/tongiaki/"
    twa, tws, perf = load_tong()
    polar = setup_interpolation(tws, twa, perf)
    perfs = generate_performance_uncertainty_samples(polar, params)
    results = SharedArray{Float64, 2}(length(sim_times), length(perfs))
    save_path = ENV["HOME"]*"/sail_route.jl/development/polynesian"*boat*"_routing_"*route_name*"_"*repr(times[1])*"_to_"*repr(times[end])*"_"*repr(min_dist)*"_nm"
    println(save_path)
    @sync begin
        for p in procs(results)
            @async remotecall_wait(route_solve_shared_chunk!, p, results, sim_times, perfs)
        end
    end
    @show results
    CSV.write(save_path, DataFrame(results))
end

# parallized_v2_uncertain_routing!()


"""Running a routing simulation for a single set of initial conditions."""
function run_single_route()
    # weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/1976_era20_jul_sep.nc"
    # start_time = Dates.DateTime(1976, 7, 1, 0, 0, 0)
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
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    results = route_solve(sample_route, sample_perf, start_time,
                          wisp, widi, wadi, wahi)
    name = ENV["HOME"]*"/sail_route.jl/development/polynesian/boeckv2/_"*repr(min_dist)*"_nm_"*repr(start_time)*"_"
    CSV.write(name*"route", DataFrame(results[2]))
    CSV.write(name*"time", DataFrame([[results[1]]]))
    CSV.write(name*"earliest_times", DataFrame(results[3]))
    CSV.write(name*"x_locs", DataFrame(results[4]))
    CSV.write(name*"y_locs", DataFrame(results[5]))
end

# run_single_route()

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
