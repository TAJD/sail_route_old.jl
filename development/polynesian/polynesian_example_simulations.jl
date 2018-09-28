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
        tws = Array{Float64}([0, 4, 5, 6, 7, 8, 9, 10, 12, 14, 16, 20])
        twa = Array{Float64}([0, 60, 70, 80, 90, 100, 110, 120])
        return twa, tws, perf
    end

    function myrange(q::SharedArray) # create a custom iterator which breaks up a range based on the processor number
        @show idx = indexpids(q)
        if idx == 0 # This worker is not assigned a piece
            return 1:0, 1:0
        end
        nchunks = length(procs(q))
        splits = [round(Int, s) for s in range(0, stop=size(q,2), length=nchunks+1)]
        1:size(q,1), splits[idx]+1:splits[idx+1]
    end


    function route_solve_chunk!(results, t_range, p_range, times, perfs)
        for t in t_range, p in p_range
            # this is where the action happens - have to reload everything here
            lon1 = -171.75
            lat1 = -13.917
            lon2 = -158.07
            lat2 = -19.59
            n = 180
            sample_route = Route(lon1, lon2, lat1, lat2, n, n)
            weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/high/1982/1982_polynesia.nc"
            twa, tws, perf = load_tong()
            polar = setup_interpolation(tws, twa, perf)
            print(times[t], " ", perfs[p])
        end
        results
    end


    route_solve_shared_chunk!(results, times, perfs) = route_solve_chunk!(results, myrange(results)..., times, perfs)

end


function parallize_uncertain_routing()

    start_time = Dates.DateTime(1982, 7, 1, 0, 0, 0)
    times = Dates.Date(1982, 7, 1, 0, 0, 0):Dates.Day(1):Dates.Date(1982, 7, 10, 0, 0)
    n_perfs = 10
    params = [i for i in LinRange(0.9, 1.1, n_perfs)]
    perfs = generate_performance_uncertainty_samples(polar, params)
    results = SharedArray{Float64, 2}(10, 10)
    @sync begin
        for p in procs(results)
            @async remotecall_wait(route_solve_shared_chunk!, p, results, times, perfs)
        end
    end
    @show results
    return results
end

parallize_uncertain_routing()


function run_single_route()
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/1982/1982_polynesia.nc"
    twa, tws, perf = load_tong()
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    n = 180
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    start_time = Dates.DateTime(1982, 7, 1, 0, 0, 0)
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    results = route_solve(sample_route, sample_perf, start_time,
                          wisp, widi, wadi, wahi)
    @show results[1]
    name = ENV["HOME"]*"/sail_route.jl/development/polynesian/_"*repr(n)*"_nodes_"
    CSV.write(name*"route", DataFrame(results[2]))
    CSV.write(name*"time", DataFrame(Array{Float64}([results[1]])))
    CSV.write(name*"earliest_times", DataFrame(results[3]))
    CSV.write(name*"x_locs", DataFrame(results[4]))
    CSV.write(name*"y_locs", DataFrame(results[5]))
end

# run_single_route()


function run_varied_performance()
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    n = 180
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


function run_varied_performance_plots()
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_june.nc"
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    n = 140 # won't interpolate well below 20 nodes
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
    
    times = SharedArray{Float64}(10, 2)
    # @sync @distributed for i = 1:10
    for i = 1
        wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data)
        results = route_solve(sample_route, sample_perf, start_time,
                              wisp, widi, wadi, wahi, Int(i-1))
        @show arrival_time = results[1]
        route = results[2]
        name = ENV["HOME"]*"/sail_route.jl/development/sensitivity/_route_transat_ens_number_"*repr(Int(i))*"_nodes_"*repr(n)*"_date_"*repr(start_time)
        CSV.write(name, DataFrame(results[2]))
        times[i, :] = Array([Float64(i), results[1]])
    end
    @show df_res = DataFrame(times)
    name1 = ENV["HOME"]*"/sail_route.jl/development/sensitivity/route_ens_results_nodes_"*repr(n)*"_date_"*repr(start_time)
    CSV.write(name1, df_res)
end