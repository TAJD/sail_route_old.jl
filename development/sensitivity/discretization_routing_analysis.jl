@everywhere include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
@everywhere include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
@everywhere include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
@everywhere include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")
@everywhere include(ENV["HOME"]*"/sail_route.jl/development/sensitivity/discretization_error.jl")


@everywhere boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
@everywhere weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_april.nc"

@everywhere using BenchmarkTools
@everywhere using Printf
@everywhere using Dates
@everywhere using Distributed
@everywhere using DistributedArrays
@everywhere using SharedArrays


# """Run discretization analysis routing for a single weather and performance scenario."""

@everywhere function disc_routing_analysis(lon2, lon1, lat2, lat1, perf, cluster_wisp, cluster_widi)
    route_nodes = Array([20*i^2 for i in range(4; length=3, stop=2)])
    results = SharedArray{Float64}(length(route_nodes))
    routes = [Route(lon2, lon1, lat2, lat1, i, i) for i in route_nodes]
    @sync @distributed for i in eachindex(routes)
        results[i] = route_solve(routes[i], perf, cluster_wisp, cluster_widi)
    end
    gci_fine = GCI_calc(results[1], results[2], results[3], route_nodes[1], route_nodes[2], route_nodes[3])
    return Array([results[1], results[1]*gci_fine])
end


@everywhere function generate_performance_uncertainty_samples(polar, params)
    unc_perf = [Performance(polar, i, 1.0) for i in params]
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
    addprocs(20)
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    cluster1_wisp = ENV["HOME"]*"/weather_cluster/test1_wisp.nc"
    cluster1_widi = ENV["HOME"]*"/weather_cluster/test1_widi.nc"
    n = 100
    params = [i for i in LinRange(0.9, 1.1, n)]
    perfs = generate_performance_uncertainty_samples(polar, params)
    results = SharedArray{Float64}(length(perfs), 2)
    @sync @distributed for i in eachindex(perfs)
        @show results[i, :] = disc_routing_analysis(lon2, lon1, lat2, lat1, perfs[i], cluster1_wisp, cluster1_widi)
    end
    times = results[:, 1]
    unc = results[:, 2]
    df = DataFrame(perf=params, t=times, u=unc)
    time = Dates.format(Dates.now(), "HH:MM:SS")
    save_path = ENV["HOME"]*"/sail_route.jl/development/sensitivity/results_"*time
    CSV.write(save_path, df)
end

test_performance_unc_analysis_cluster()