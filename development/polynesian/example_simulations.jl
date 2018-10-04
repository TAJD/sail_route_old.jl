using Distributed
@everywhere begin
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")
    include(ENV["HOME"]*"/sail_route.jl/development/sensitivity/discretization_error.jl")

    using BenchmarkTools
    using Printf
    using Dates
    using CSV
    using DataFrames
    using SharedArrays

    """Generate range of modified polars for performance uncertainty simulation."""
    function generate_performance_uncertainty_samples(polar, params)
        unc_perf = [Performance(polar, i, 1.0) for i in params]
    end

    # """Run discretization error calculation for time dependent weather data."""
    function disc_routing_analysis(lon2, lon1, lat2, lat1, perf, time,
                                   wisp, widi, wadi, wahi)
        route_nodes = Array([20*i^2 for i in range(4; length=3, stop=2)])
        results = zeros(length(route_nodes))
        routes = [Route(lon2, lon1, lat2, lat1, i, i) for i in route_nodes]
        locs = []
        for i in eachindex(routes)
            results[i], sp = route_solve(routes[i], perf, time, wisp, widi, wadi , wahi)
        end
        gci_fine = GCI_calc(results[1], results[2], results[3],
                            route_nodes[1], route_nodes[2], route_nodes[3])
        return Array([results[1], results[1]*gci_fine])
    end


    function load_tong()
        path = ENV["HOME"]*"/sail_route.jl/development/polynesian/performance/tongiaki_vpp.csv"
        df = CSV.read(path, delim=',', datarow=1)
        perf = convert(Array{Float64}, df)
        tws = Array{Float64}([0.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0, 14.0, 16.0, 20.0])
        twa = Array{Float64}([0.0, 60.0, 70.0, 80.0, 90.0, 100.0, 110.0, 120.0])
        return twa, tws, perf
    end


    function load_boeckv2()
        path = ENV["HOME"]*"/sail_route.jl/development/polynesian/performance/boeck_v2.csv"
        df = CSV.read(path, delim=',', datarow=1)
        perf = convert(Array{Float64}, df)
        tws = Array{Float64}([0.0,5.832037,7.77605,9.720062,11.66407,13.60809,15.5521,17.49611])
        twa = Array{Float64}([0.0, 60.0, 75.0, 90.0, 110.0, 120.0, 150.0, 170.0])
        return twa, tws, perf

    end


    """Create a custom iterator which breaks up a range based on the processor number"""
    function myrange(q::SharedArray) 
        @show idx = indexpids(q)
        if idx == 0 # This worker is not assigned a piece
            return 1:0, 1:0
        end
        nchunks = length(procs(q))
        splits = [round(Int, s) for s in range(0, stop=size(q,2), length=nchunks+1)]
        1:size(q,1), splits[idx]+1:splits[idx+1]
    end


    function route_solve_chunk!(results, t_range, p_range, times, perfs)
        lon1 = -171.75
        lat1 = -13.917
        lon2 = -158.07
        lat2 = -19.59
        min_dist = 10.0  # nm
        n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
        sample_route = Route(lon1, lon2, lat1, lat2, n, n)
        weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
        wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
        for t in t_range, p in p_range
            output = route_solve(sample_route, perfs[p], times[t], wisp, widi, wadi, wahi)
            @show results[t, p] = output[1]
        end
        results
    end


    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"

    function route_solve_upolu_to_atiu!(results, t_range, p_range, times, perfs)
        lon1 = -171.75
        lat1 = -13.917
        lon2 = -158.07
        lat2 = -19.59
        min_dist = 20.0  # nm
        n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
        sample_route = Route(lon1, lon2, lat1, lat2, n, n)
        weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
        wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
        for t in t_range, p in p_range
            output = route_solve(sample_route, perfs[p], times[t], wisp, widi, wadi, wahi)
            @show results[t, p] = output[1]
        end
        results
    end


    function route_solve_upolu_to_moorea!(results, t_range, p_range, times, perfs)
        lon1 = -171.75
        lat1 = -13.917
        lon2 = -149.83
        lat2 = -17.53
        min_dist = 5.0  # nm
        n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
        sample_route = Route(lon1, lon2, lat1, lat2, n, n)
        weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
        wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
        for t in t_range, p in p_range
            output = route_solve(sample_route, perfs[p], times[t], wisp, widi, wadi, wahi)
            @show results[t, p] = output[1]
        end
        results
    end


    function route_solve_tongatapu_to_moorea!(results, t_range, p_range, times, perfs)
        lon1 = -171.15
        lat1 = -17.53
        lon2 = -149.83
        lat2 = -17.53
        min_dist = 5.0  # nm
        n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
        sample_route = Route(lon1, lon2, lat1, lat2, n, n)
        weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
        wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
        for t in t_range, p in p_range
            output = route_solve(sample_route, perfs[p], times[t], wisp, widi, wadi, wahi)
            @show results[t, p] = output[1]
        end
        results
    end


    function route_solve_tongatapu_to_atiu!(results, t_range, p_range, times, perfs)
        lon1 = -171.15
        lat1 = -17.53
        lon2 = -158.07
        lat2 = -19.59
        min_dist = 5.0  # nm
        n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
        sample_route = Route(lon1, lon2, lat1, lat2, n, n)
        weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc" 
        wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
        for t in t_range, p in p_range
            output = route_solve(sample_route, perfs[p], times[t], wisp, widi, wadi, wahi)
            @show results[t, p] = output[1]
        end
        results
    end

    route_solve_shared_chunk!(results, times, perfs) = route_solve_upolu_to_atiu!(results, myrange(results)..., times, perfs)
end


function parallize_uncertain_routing()
    times = Dates.Date(1982, 8, 1):Dates.Day(1):Dates.Date(1982, 8, 31)
    times = [DateTime(t) for t in times]
    params = [i for i in LinRange(0.9, 1.1, 10)]
    # twa, tws, perf = load_tong()
    twa, tws, perf = load_boeckv2()
    polar = setup_interpolation(tws, twa, perf)
    perfs = generate_performance_uncertainty_samples(polar, params)
    results = SharedArray{Float64, 2}(length(times), length(perfs))
    @show size(results)
    @sync begin
        for p in procs(results)
            @async remotecall_wait(route_solve_shared_chunk!, p, results, times, perfs)
        end
    end
    @show results
    route_name = "upolu_to_atiu"
    # boat = "/boeckv2/"
    boat = "/tongiaki/"
    save_path = ENV["HOME"]*"/sail_route.jl/development/polynesian"*boat*"_routing"*route_name*"_"*repr(times[1])*"finish_"*repr(times[end])
    CSV.write(save_path, DataFrame(results))
end

# parallize_uncertain_routing()


function run_single_route()
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/low/1976/1976_era20_jul_sep.nc"
    start_time = Dates.DateTime(1976, 7, 1, 0, 0, 0)
    # weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    # start_time = Dates.DateTime(1982, 7, 1, 0, 0, 0)
    # twa, tws, perf = load_tong()
    twa, tws, perf = load_boeckv2()
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    min_dist = 5.0 # nm
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

run_single_route()


function run_varied_performance()
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
    twa, tws, perf = load_tong()
    polar = setup_interpolation(tws, twa, perf)
    start_time = Dates.DateTime(1982, 7, 1, 0, 0, 0)
    n_perfs = 10
    params = [i for i in LinRange(0.9, 1.1, n_perfs)]
    perfs = generate_performance_uncertainty_samples(polar, params)
    results = SharedArray{Float64}(length(perfs), 2)
    @sync @distributed for i in eachindex(perfs)
        wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
        results = route_solve(sample_route, perfs[i], start_time,
                              wisp, widi, wadi, wahi)
        @show arrival_time = results[1]
        route = results[2]
        name = ENV["HOME"]*"/sail_route.jl/development/polynesian/_route_nodes_"*repr(n)*"_date_"*repr(start_time)
        CSV.write(name, DataFrame(results[2]))
    end
    times = results[:, 1]
    unc = results[:, 2]
    @show df = DataFrame(perf=params, t=times, u=unc)
    time = Dates.format(Dates.now(), "HH:MM:SS")
    save_path = ENV["HOME"]*"/sail_route.jl/development/polynesian/results_"*repr(start_time)
    CSV.write(save_path, df)
end

# run_varied_performance()
