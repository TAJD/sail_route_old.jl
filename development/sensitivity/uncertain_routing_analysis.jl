using Distributed
@everywhere begin 
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
    include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")
    include(ENV["HOME"]*"/sail_route.jl/development/sensitivity/discretization_error.jl")


    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_april.nc"

    using BenchmarkTools
    using Printf
    using Dates
    using Distributed
    using DistributedArrays
    using SharedArrays


    """Run discretization analysis routing for an average weather and performance scenario."""
    function disc_routing_analysis(lon2, lon1, lat2, lat1, perf, cluster_wisp, cluster_widi)
        route_nodes = Array([20*i^2 for i in range(4; length=3, stop=2)])
        results = zeros(length(route_nodes))
        routes = [Route(lon2, lon1, lat2, lat1, i, i) for i in route_nodes]
        locs = []
        for i in eachindex(routes)
            results[i], sp = route_solve(routes[i], perf, cluster_wisp, cluster_widi)
        end
        gci_fine = GCI_calc(results[1], results[2], results[3], route_nodes[1], route_nodes[2], route_nodes[3])
        return Array([results[1], results[1]*gci_fine])
    end

    """Run discretization error calculation for time dependent weather data."""
    function disc_routing_analysis(lon2, lon1, lat2, lat1, perf, time, wisp, widi, wadi, wahi, ens_number)
        route_nodes = Array([20*i^2 for i in range(4; length=3, stop=2)])
        results = zeros(length(route_nodes))
        routes = [Route(lon2, lon1, lat2, lat1, i, i) for i in route_nodes]
        locs = []
        for i in eachindex(routes)
            results[i], sp = route_solve(routes[i], perf, time, wisp, widi, wadi, wahi, ens_number)
            # df = DataFrame(sp)
            # name = ENV["HOME"]*"/sail_route.jl/development/sensitivity/_route_transat_nodes_"*repr(i)*"_ens_number_"*repr(ens_number)
            # CSV.write(name, df)
        end
        gci_fine = GCI_calc(results[1], results[2], results[3], route_nodes[1], route_nodes[2], 
                            route_nodes[3])
        return Array([results[1], results[1]*gci_fine])
    end


    """Generate range of modified polars for performance uncertainty simulation."""
    function generate_performance_uncertainty_samples(polar, params)
        unc_perf = [Performance(polar, i, 1.0) for i in params]
    end
end

function save_discretized_paths()
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    start_time = Dates.DateTime(2016, 4, 1, 0, 0, 0)
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data)
    ens_number=0
    route_nodes = Array([10*i^2 for i in range(4; length=3, stop=2)])
    results = zeros(length(route_nodes))
    routes = [Route(lon2, lon1, lat2, lat1, i, i) for i in route_nodes]
    results = [route_solve(i, sample_perf, start_time, wisp, widi, wadi, wahi, ens_number) for i in routes]
    paths = [i[2] for i in results]
end



function test_discretized_analysis_cluster()
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    cluster1_wisp = ENV["HOME"]*"/weather_cluster/test1_wisp.nc"
    cluster1_widi = ENV["HOME"]*"/weather_cluster/test1_widi.nc"
    results = disc_routing_analysis(lon2, lon1, lat2, lat1, sample_perf, cluster1_wisp, cluster1_widi)
    println(results)
end


function test_performance_unc_analysis_cluster()
    # addprocs(20)
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    cluster1_wisp = ENV["HOME"]*"/weather_cluster/test1_wisp.nc"
    cluster1_widi = ENV["HOME"]*"/weather_cluster/test1_widi.nc"
    n = 10
    params = [i for i in LinRange(0.9, 1.1, n)]
    perfs = generate_performance_uncertainty_samples(polar, params)
    results = SharedArray{Float64}(length(perfs), 2)
    @sync @distributed for i in eachindex(perfs)
        @show results[i, :] = disc_routing_analysis(lon2, lon1, lat2, lat1, perfs[i],
                                                    cluster1_wisp, cluster1_widi)
    end
    times = results[:, 1]
    unc = results[:, 2]
    df = DataFrame(perf=params, t=times, u=unc)
    time = Dates.format(Dates.now(), "HH:MM:SS")
    save_path = ENV["HOME"]*"/sail_route.jl/development/sensitivity/results_"*time
    CSV.write(save_path, df)
end

# test_performance_unc_analysis_cluster()

function test_ens_analysis_time_dependent()
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    start_time = Dates.DateTime(2016, 4, 1, 2, 0, 0)
    wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data)
    results = SharedArray{Float64}(10, 2)
    @sync @distributed for i in 0:9
        @show results[i+1, :] = disc_routing_analysis(lon2, lon1, lat2, lat1, sample_perf, start_time,                                               wisp, widi, wadi, wahi, i)
    end
    times = results[:, 1]
    unc = results[:, 2]
    df = DataFrame(perf=params, t=times, u=unc)
    time = Dates.format(Dates.now(), "HH:MM:SS")
    save_path = ENV["HOME"]*"/sail_route.jl/development/sensitivity/ens_results_"*time
    CSV.write(save_path, df)
end

# test_ens_analysis_time_dependent()