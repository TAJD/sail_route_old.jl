using Distributed, SharedArrays

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


function route_solve_upolu_to_atiu!(results, t_range, p_range, sim_times, perfs)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    for t in t_range, p in p_range
        output = route_solve(sample_route, perfs[p], sim_times[t], wisp, widi, wadi, wahi)
        @show results[t, p] = output[1]
        Base.GC.gc()
    end
    results
end


function route_solve_upolu_to_moorea!(results, t_range, p_range, sim_times, perfs)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -149.83
    lat2 = -17.53
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    for t in t_range, p in p_range
        output = route_solve(sample_route, perfs[p], sim_times[t], wisp, widi, wadi, wahi)
        @show results[t, p] = output[1]
        Base.GC.gc()
    end
    results
end


function route_solve_tongatapu_to_moorea!(results, t_range, p_range, sim_times, perfs)
    lon1 = -171.15
    lat1 = -21.21
    lon2 = -149.83
    lat2 = -17.53
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    for t in t_range, p in p_range
        output = route_solve(sample_route, perfs[p], sim_times[t], wisp, widi, wadi, wahi)
        @show results[t, p] = output[1]
        Base.GC.gc()
    end
    results
end



function route_solve_tongatapu_to_atiu!(results, t_range, p_range, sim_times, perfs)
    lon1 = -171.15
    lat1 = -21.21
    lon2 = -158.07
    lat2 = -19.59
    n = calc_nodes(lon1, lon2, lat1, lat2, min_dist)
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    for t in t_range, p in p_range
        output = route_solve(sample_route, perfs[p], sim_times[t], wisp, widi, wadi, wahi)
        @show results[t, p] = output[1]
        Base.GC.gc()
    end
    results
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


"""Generate range of modified polars for performance uncertainty simulation."""
function generate_performance_uncertainty_samples(polar, params)
    unc_perf = [Performance(polar, i, 1.0) for i in params]
end


"""Run discretization error calculation for time dependent weather data."""
function disc_routing_analysis(lon2, lon1, lat2, lat1, perf, time,
                               wisp, widi, wadi, wahi)
    route_nodes = Array([calc_nodes(lon1, lon2, lat1, lat2, i) for i in Array([5.0, 10.0, 20.0])])
    results = zeros(length(route_nodes))
    routes = [Route(lon2, lon1, lat2, lat1, i, i) for i in route_nodes]
    locs = []
    for i in eachindex(routes)
        @show results[i], sp = route_solve(routes[i], perf, time, wisp, widi, wadi , wahi)
    end
    gci_fine = GCI_calc(results[1], results[2], results[3],
                        route_nodes[1], route_nodes[2], route_nodes[3])
    return Array([results[1], results[1]*gci_fine])
end