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
                                   wisp, widi, wadi, wahi, ens_number)
        route_nodes = Array([20*i^2 for i in range(4; length=3, stop=2)])
        results = zeros(length(route_nodes))
        routes = [Route(lon2, lon1, lat2, lat1, i, i) for i in route_nodes]
        locs = []
        for i in eachindex(routes)
            results[i], sp = route_solve(routes[i], perf, time, wisp, widi, wadi , wahi, ens_number)
        end
        gci_fine = GCI_calc(results[1], results[2], results[3],
                            route_nodes[1], route_nodes[2], route_nodes[3])
        return Array([results[1], results[1]*gci_fine])
    end
end


# function single_weather_route()
#     boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
#     weather_data = ENV["HOME"]*"/weather_data/transat_weather/2016_june.nc"
# end


function run_discretized_routes()
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/1982/1982_polynesia.nc"
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    lon1 = -171.75
    lat1 = -13.917
    lon2 = -158.07
    lat2 = -19.59
    n = 80 # won't interpolate well below 20 nodes
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    start_time = Dates.DateTime(1982, 1, 1, 0, 0, 0)
    wisp, widi, wahi, wadi, wapr = load_era20_weather(weather_data)
    results = route_solve(sample_route, sample_perf, start_time,
                          wisp, widi, wadi, wahi)
    @show results
    name = ENV["HOME"]*"/sail_route.jl/development/polynesian/_80_nodes"
    CSV.write(name, DataFrame(results[2]))
end

run_discretized_routes()


function run_ensemble_weather_scenarios()
    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    weather_data = ENV["HOME"]*"/weather_data/polynesia_weather/1982/1982_era20_jan_march.nc"
    twa, tws, perf = load_file(boat_performance)
    polar = setup_interpolation(tws, twa, perf)
    sample_perf = Performance(polar, 1.0, 1.0)
    lon1 = -11.5
    lat1 = 47.67
    lon2 = -77.67
    lat2 = 25.7
    n = 80 # won't interpolate well below 20 nodes
    sample_route = Route(lon1, lon2, lat1, lat2, n, n)
    start_time = Dates.DateTime(2016, 6, 1, 0, 0, 0)
    
    times = SharedArray{Float64}(10, 2)
    @sync @distributed for i = 1:10
    # for i = 1
        wisp, widi, wahi, wadi, wapr = load_era5_weather(weather_data)
        results = route_solve(sample_route, sample_perf, start_time,
                              wisp, widi, wadi, wahi)
        @show arrival_time = results[1]
        route = results[2]
        name = ENV["HOME"]*"/sail_route.jl/development/polynesian/_route_1982_ens_"*repr(Int(i))*"_nodes_"*repr(n)
        CSV.write(name, DataFrame(results[2]))
        times[i, :] = Array([Float64(i), results[1]])
    end
    @show df_res = DataFrame(times)
    name1 = ENV["HOME"]*"/sail_route.jl/development/polynesian/_route_1982_ens_results"
    CSV.write(name1, df_res)
end